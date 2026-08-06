extends Node2D
## Pantalla de titulo (HE-05): la primera pantalla que ve el jugador.
##
## Cielo estrellado animado (`capa_estrellas.gd`) + una gran estrella que "respira"
## invitando a tocar, sin depender de saber leer (GDD §6 reglas 1-3): el gesto es
## "toca donde brilla", reforzado con voz repetida y, de forma decorativa/no
## obligatoria, con texto. Toda la pantalla es el objetivo tactil (regla 1, mucho
## mas grande que el minimo de 96 px) y responde en <100 ms a cualquier toque
## (regla 5).
##
## No conoce ninguna escena futura (regla de oro 3, nucleo desacoplado de
## contenido/pantallas concretas): se limita a emitir `toque_para_empezar`. HE-06
## (seleccion de personaje) y HE-09 (autoload Navegacion) se conectaran a esta
## senal cuando existan.

signal toque_para_empezar

const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/confirmar.ogg"
const RUTA_VOZ_INVITACION := "res://assets/audio/voces/nucleo/titulo_bienvenida_01.ogg"
const SEGUNDOS_ENTRE_RECORDATORIOS := 12.0

@onready var _estrella_toque: Polygon2D = $invitacion/estrella_toque
@onready var _temporizador_recordatorio: Timer = $temporizador_recordatorio

var _tween_pulso: Tween


func _ready() -> void:
	_reproducir_invitacion()
	_iniciar_pulso()
	_temporizador_recordatorio.wait_time = SEGUNDOS_ENTRE_RECORDATORIOS
	_temporizador_recordatorio.timeout.connect(_reproducir_invitacion)
	_temporizador_recordatorio.start()


## Repite la invitacion a tocar cada tantos segundos: ningun nino debe depender de
## leer "Toca para comenzar" para saber que hacer (GDD §6 regla 2). El archivo de
## voz real todavia no esta grabado (P2, TTS de relleno pendiente) — `Audio` avisa
## por consola y no rompe la pantalla si falta.
func _reproducir_invitacion() -> void:
	Audio.reproducir_voz(RUTA_VOZ_INVITACION)


func _iniciar_pulso() -> void:
	_tween_pulso = create_tween()
	_tween_pulso.set_loops()
	_tween_pulso.tween_property(_estrella_toque, "scale", Vector2(1.15, 1.15), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_pulso.tween_property(_estrella_toque, "scale", Vector2(1.0, 1.0), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		_al_tocar_pantalla((evento as InputEventScreenTouch).position)
	elif evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_al_tocar_pantalla((evento as InputEventMouseButton).position)


## Respuesta inmediata a CUALQUIER toque en toda la pantalla (GDD §6 regla 5,
## <100 ms): el objetivo tactil es la pantalla entera, no solo el icono de la
## estrella — apto para Maxi (2 anios) sin puntera fina.
func _al_tocar_pantalla(posicion: Vector2) -> void:
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	_destello_estrella()
	_lanzar_chispas(posicion)
	toque_para_empezar.emit()


func _destello_estrella() -> void:
	if _tween_pulso:
		_tween_pulso.kill()
	var tween := create_tween()
	tween.tween_property(_estrella_toque, "scale", Vector2(1.4, 1.4), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_estrella_toque, "scale", Vector2(1.0, 1.0), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_iniciar_pulso)


## Rafaga de chispas doradas en el punto tocado: mismo lenguaje visual que los
## "destellos" que se ganan al completar un nivel (GDD §6 regla 9, celebracion
## generosa incluso en la pantalla de titulo).
func _lanzar_chispas(posicion: Vector2) -> void:
	var chispas := CPUParticles2D.new()
	add_child(chispas)
	chispas.position = posicion
	chispas.one_shot = true
	chispas.amount = 14
	chispas.lifetime = 0.6
	chispas.explosiveness = 1.0
	chispas.direction = Vector2.UP
	chispas.spread = 180.0
	chispas.gravity = Vector2(0.0, 60.0)
	chispas.initial_velocity_min = 80.0
	chispas.initial_velocity_max = 180.0
	chispas.scale_amount_min = 2.0
	chispas.scale_amount_max = 4.0
	chispas.color = Color(1.0, 0.85, 0.3, 1.0)
	chispas.emitting = true
	chispas.finished.connect(chispas.queue_free)
