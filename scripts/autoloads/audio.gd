extends Node

## Autoload `Audio` (docs/stack-tecnico.md §2, tarjeta HE-04).
##
## Centraliza los 3 buses de audio del proyecto (Musica, SFX, Voz, todos enviando a
## Master — ver `assets/audio/buses_audio.tres`) y la reproduccion de musica, efectos
## y narracion por voz. Los motores de mecanica llaman a `Audio.reproducir_voz(...)`
## / `Audio.reproducir_sfx(...)` en vez de instanciar `AudioStreamPlayer` por su cuenta
## (contrato ya asumido por `motor_emparejar.gd`, ver su TODO de voz).
##
## GDD §6 obligatorio: regla 5 (respuesta <100 ms a todo toque — el pool de SFX evita
## cortar sonidos superpuestos) y regla 10 (volumen de musica/efectos/voz ajustable por
## separado, recordado por perfil — aqui se aplica a `AudioServer`; la persistencia por
## perfil llega con `Progreso`, HE-07/HE-12).

const BUS_MUSICA := "Musica"
const BUS_SFX := "SFX"
const BUS_VOZ := "Voz"

const TAMANO_POOL_SFX := 6

## Volumen lineal (0.0-1.0) recordado por bus, para poder consultarlo desde la UI de
## zona de padres (HE-12) sin tener que revertir de dB.
var _volumenes: Dictionary = {
	BUS_MUSICA: 1.0,
	BUS_SFX: 1.0,
	BUS_VOZ: 1.0,
}

var _reproductor_musica: AudioStreamPlayer
var _reproductor_voz: AudioStreamPlayer
var _pool_sfx: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_reproductor_musica = _crear_reproductor(BUS_MUSICA)
	_reproductor_voz = _crear_reproductor(BUS_VOZ)
	for i in TAMANO_POOL_SFX:
		_pool_sfx.append(_crear_reproductor(BUS_SFX))


func _crear_reproductor(bus: String) -> AudioStreamPlayer:
	var reproductor := AudioStreamPlayer.new()
	reproductor.bus = bus
	add_child(reproductor)
	return reproductor


## Reproduce un efecto corto (toques, aciertos, transiciones de UI). Usa un pool de
## reproductores para que varios sfx puedan sonar superpuestos sin cortarse.
func reproducir_sfx(ruta: String) -> void:
	if ruta == "" or not ResourceLoader.exists(ruta):
		push_warning("Audio.reproducir_sfx: no existe el archivo %s" % ruta)
		return
	var reproductor := _siguiente_reproductor_sfx_libre()
	reproductor.stream = load(ruta)
	reproductor.play()


func _siguiente_reproductor_sfx_libre() -> AudioStreamPlayer:
	for reproductor in _pool_sfx:
		if not reproductor.playing:
			return reproductor
	# Si todos estan ocupados, se reutiliza el primero: nunca se deja a un nino sin
	# sonido de respuesta a su toque (GDD §6 regla 5).
	return _pool_sfx[0]


## Reproduce musica de fondo en loop. Si ya sonaba otra pista, la reemplaza.
func reproducir_musica(ruta: String, loop: bool = true) -> void:
	if ruta == "" or not ResourceLoader.exists(ruta):
		push_warning("Audio.reproducir_musica: no existe el archivo %s" % ruta)
		return
	var stream: AudioStream = load(ruta)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	_reproductor_musica.stream = stream
	_reproductor_musica.play()


func detener_musica() -> void:
	_reproductor_musica.stop()


## Reproduce una linea de narracion/voz (instrucciones, celebraciones, historia).
## Si ya habia una voz sonando, la interrumpe: tocar a Cometa para repetir una
## instruccion siempre debe volver a sonar de inmediato (GDD §6 regla 2).
func reproducir_voz(ruta: String) -> void:
	if ruta == "":
		return
	if not ResourceLoader.exists(ruta):
		# Linea aun no grabada (guion_voces.md la tiene pendiente): no truena el juego,
		# solo avisa en consola para que el equipo la complete.
		push_warning("Audio.reproducir_voz: linea pendiente de grabar: %s" % ruta)
		return
	_reproductor_voz.stream = load(ruta)
	_reproductor_voz.play()


func detener_voz() -> void:
	_reproductor_voz.stop()


func esta_hablando() -> bool:
	return _reproductor_voz.playing


## Volumen lineal 0.0-1.0 por bus (GDD §6 regla 10). `zona_padres` (HE-12) llamara esto
## y `Progreso` persistira el valor por perfil.
func set_volumen(bus: String, volumen_lineal: float) -> void:
	volumen_lineal = clampf(volumen_lineal, 0.0, 1.0)
	_volumenes[bus] = volumen_lineal
	var indice := AudioServer.get_bus_index(bus)
	if indice == -1:
		push_warning("Audio.set_volumen: bus desconocido %s" % bus)
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(volumen_lineal) if volumen_lineal > 0.0 else -80.0)


func obtener_volumen(bus: String) -> float:
	return _volumenes.get(bus, 1.0)
