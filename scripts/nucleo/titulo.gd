extends Node2D
## Pantalla de titulo (HE-05, rediseñada — UI ad-hoc con el mockup del PO "UI Sistema").
##
## Logo + boton "toca para empezar" + ilustracion de portada decorativa, pero el
## comportamiento validado de la version anterior se preserva integro (GDD §6 reglas
## 1-3-5): TODA la pantalla sigue siendo el objetivo tactil (no solo el boton), la
## invitacion de voz se sigue repitiendo cada `SEGUNDOS_ENTRE_RECORDATORIOS`, y cualquier
## toque responde en <100 ms con sfx + chispas antes de navegar.
##
## No conoce ninguna escena futura mas alla de la siguiente en la cadena fija de este
## paquete de UI (titulo→seleccion): sigue emitiendo `toque_para_empezar` para cuando
## exista `Navegacion` (HE-09) y quiera engancharse aqui en vez de leer esta escena.

signal toque_para_empezar

const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/confirmar.ogg"
const RUTA_VOZ_INVITACION := "res://assets/audio/voces/nucleo/titulo_bienvenida_01.ogg"
const SEGUNDOS_ENTRE_RECORDATORIOS := 12.0
const RUTA_SIGUIENTE := "res://escenas/nucleo/seleccion_personaje.tscn"

@onready var _boton_jugar: Node2D = $boton_jugar
@onready var _temporizador_recordatorio: Timer = $temporizador_recordatorio
@onready var _anillos_fondo: Node2D = $ilustracion/anillos_fondo

var _tween_pulso: Tween
var _ya_toco := false


func _ready() -> void:
	_reproducir_invitacion()
	_iniciar_pulso()
	_iniciar_giro_anillos()
	_temporizador_recordatorio.wait_time = SEGUNDOS_ENTRE_RECORDATORIOS
	_temporizador_recordatorio.timeout.connect(_reproducir_invitacion)
	_temporizador_recordatorio.start()


func _reproducir_invitacion() -> void:
	Audio.reproducir_voz(RUTA_VOZ_INVITACION)


func _iniciar_pulso() -> void:
	_tween_pulso = create_tween()
	_tween_pulso.set_loops()
	_tween_pulso.tween_property(_boton_jugar, "scale", Vector2(1.07, 1.07), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_pulso.tween_property(_boton_jugar, "scale", Vector2(1.0, 1.0), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Anillos decorativos girando lentamente detras del marco de portada (equivalente al
## `repeating-conic-gradient` + `he-spin 60s` del mockup).
func _iniciar_giro_anillos() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_anillos_fondo, "rotation", TAU, 60.0) \
		.set_trans(Tween.TRANS_LINEAR)


func _unhandled_input(evento: InputEvent) -> void:
	if _ya_toco:
		return
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		_al_tocar_pantalla((evento as InputEventScreenTouch).position)
	elif evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_al_tocar_pantalla((evento as InputEventMouseButton).position)


## Respuesta inmediata a CUALQUIER toque en toda la pantalla (GDD §6 regla 5, <100 ms):
## el objetivo tactil es la pantalla entera, no solo el boton dorado.
func _al_tocar_pantalla(posicion: Vector2) -> void:
	_ya_toco = true
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	_lanzar_chispas(posicion)
	toque_para_empezar.emit()
	get_tree().change_scene_to_file(RUTA_SIGUIENTE)


## Rafaga de chispas doradas en el punto tocado (mismo lenguaje visual de "destellos").
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
