extends Node2D
## Pantalla de seleccion de personaje (HE-06 en Backlog — implementada aqui como parte
## del paquete de UI ad-hoc del mockup del PO "UI Sistema").
##
## 3 tarjetas grandes (Maxi/Nicole/Sofia), cada una un objetivo tactil enorme (320x~400
## px, muy por encima del minimo de 96 px — GDD §6 regla 1). Al tocar una tarjeta se fija
## el perfil activo en `Progreso` (autoload real, HE-07) y se navega al mapa estelar. El
## boton "volver" hace lo opuesto: vuelve al titulo sin tocar el perfil.
##
## Entrada unificada tactil+mouse por region (mismo patron que `titulo.gd`, adaptado a
## multiples objetivos): en vez de "toda la pantalla es un boton", cada tarjeta/boton
## define su rectangulo y se resuelve cual se toco en `_input`.

const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/seleccionar.ogg"
const RUTA_SFX_VOLVER := "res://assets/audio/sfx/ui/cerrar.ogg"
const RUTA_VOZ_INVITACION := "res://assets/audio/voces/nucleo/seleccion_invitacion_01.ogg"
const SEGUNDOS_ENTRE_RECORDATORIOS := 12.0
const RUTA_MAPA := "res://escenas/nucleo/mapa_estelar.tscn"
const RUTA_TITULO := "res://escenas/nucleo/titulo.tscn"
const RUTA_ALBUM := "res://escenas/nucleo/album_recuerdos.tscn"
const BotonAlbum := preload("res://scripts/ui/boton_album.gd")
const EntregaRecuerdoScript := preload("res://scripts/ui/entrega_recuerdo.gd")
## Boton del album de recuerdos (ficha album-recuerdos §7). Va AQUI y no en el titulo: el titulo
## entero es un solo objetivo tactil ("toca para empezar") y un boton adentro competiria con el;
## la seleccion es donde se juntan los tres, sin perfil elegido, y el album es de todos.
const RECT_ALBUM := Rect2(930, 578, 150, 132)

@onready var _temporizador_recordatorio: Timer = $temporizador_recordatorio
@onready var _boton_volver: Control = $boton_volver

## Cada region tactil: rectangulo en coordenadas de pantalla + accion a ejecutar.
var _regiones: Array[Dictionary] = []
var _bloqueado := false
var _boton_album: Control
var _entrega: Node


func _ready() -> void:
	_registrar_regiones()
	_crear_boton_album()
	_temporizador_recordatorio.wait_time = SEGUNDOS_ENTRE_RECORDATORIOS
	_temporizador_recordatorio.timeout.connect(_reproducir_invitacion)
	if _entregar_primera_apertura():
		return
	_reproducir_invitacion()
	_temporizador_recordatorio.start()
	_avisar_foto_nueva()


func _crear_boton_album() -> void:
	_boton_album = BotonAlbum.new()
	_boton_album.name = "boton_album"
	_boton_album.position = RECT_ALBUM.position
	_boton_album.size = RECT_ALBUM.size
	add_child(_boton_album)
	_boton_album.tocado.connect(_abrir_album)


## Primera vez que se abre el juego (con el album): la foto familiar "antes del secuestro" llega
## en su sobre-estrella y vuela a este boton. Evento generico: el nucleo no sabe que foto es.
func _entregar_primera_apertura() -> bool:
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null:
		return false
	var nuevos: Array = recuerdos.desbloquear({"tipo": "primera_apertura"}, "")
	if nuevos.is_empty():
		return false
	_bloqueado = true
	_entrega = EntregaRecuerdoScript.crear(nuevos, RECT_ALBUM.get_center())
	# Guion §1.1 en orden fijo (UX N1, 02-Oct-2026): primero que paso ("¡pffft!, se le volaron las
	# fotos"), y al guardar la foto, que las demas andan flotando. La historia no se corta: el sobre
	# espera la frase completa.
	var lineas: Array = recuerdos.catalogo.get("voces", {}).get("primera", [])
	if not lineas.is_empty():
		_entrega.voz_sobre = recuerdos.ruta_linea(str(lineas[0]))
		_entrega.esperar_frase_completa = true
	if lineas.size() > 1:
		_entrega.voz_final = recuerdos.ruta_linea(str(lineas[1]))
	_entrega.rebote_album.connect(func() -> void: _boton_album.rebotar())
	_entrega.terminada.connect(_al_terminar_entrega)
	add_child(_entrega)
	return true


func _al_terminar_entrega() -> void:
	_entrega = null
	_bloqueado = false
	_temporizador_recordatorio.start()


## "¡Psst! Hay una foto nueva esperando en el album" (una vez al entrar, si esta grabada).
func _avisar_foto_nueva() -> void:
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null or not recuerdos.hay_nuevos():
		return
	var ruta: String = recuerdos.elegir_linea("album_nueva")
	if ruta == "":
		return
	await get_tree().create_timer(3.5).timeout
	if is_inside_tree() and not _bloqueado:
		Audio.reproducir_voz(ruta)


func _abrir_album() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	_temporizador_recordatorio.stop()
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	Audio.detener_voz()
	get_tree().change_scene_to_file(RUTA_ALBUM)


func _registrar_regiones() -> void:
	for id_perfil in ["maxi", "nicole", "sofia"]:
		var tarjeta: Control = get_node("tarjeta_%s" % id_perfil)
		_regiones.append({
			"rect": Rect2(tarjeta.global_position, tarjeta.size),
			"accion": func(): _elegir_perfil(id_perfil),
		})
	_regiones.append({
		"rect": Rect2(_boton_volver.global_position, _boton_volver.size),
		"accion": func(): _volver_a_titulo(),
	})


func _reproducir_invitacion() -> void:
	Audio.reproducir_voz(RUTA_VOZ_INVITACION)


## `_input` y no `_unhandled_input`: las tarjetas/botones son `Panel` (filtro STOP), que se
## quedan con el clic en la GUI y nunca llegaba a las regiones. Aqui se resuelve antes.
func _input(evento: InputEvent) -> void:
	if _bloqueado:
		return
	var posicion: Vector2
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		posicion = (evento as InputEventScreenTouch).position
	elif evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		posicion = (evento as InputEventMouseButton).position
	else:
		return
	for region in _regiones:
		if (region["rect"] as Rect2).has_point(posicion):
			get_viewport().set_input_as_handled()
			(region["accion"] as Callable).call()
			return


func _elegir_perfil(id_perfil: String) -> void:
	_bloqueado = true
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	Progreso.seleccionar_perfil(id_perfil)
	get_tree().change_scene_to_file(RUTA_MAPA)


func _volver_a_titulo() -> void:
	_bloqueado = true
	Audio.reproducir_sfx(RUTA_SFX_VOLVER)
	get_tree().change_scene_to_file(RUTA_TITULO)
