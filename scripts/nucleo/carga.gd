extends Node2D
## Pantalla de carga (UI ad-hoc — mockup del PO "UI Sistema", Claude Design).
##
## Primera pantalla del juego: un anillo de progreso decorativo avanza solo de 0 a
## 100% y pasa automaticamente al titulo. No hay nada que el nino deba tocar, por eso
## no lleva voz de instruccion (GDD §6 regla 2 aplica a acciones pedidas; aqui no se
## pide ninguna). El logo, el anillo conic-gradient con Cometa flotando adentro y la
## navecita orbitando reproducen el diseno del mockup con nodos 2D nativos de Godot.
##
## No conoce ninguna pantalla salvo la siguiente en la cadena fija carga→titulo (igual
## de simple que `Navegacion`, que todavia no existe — HE-09).

const RUTA_SIGUIENTE := "res://escenas/nucleo/titulo.tscn"
const DURACION_CARGA := 2.7
const ESPERA_FINAL := 0.7

@onready var _texto_porcentaje: Label = $texto_porcentaje
@onready var _anillo: Node2D = $anillo_progreso
@onready var _cometa: TextureRect = $anillo_progreso/cometa_flotante
@onready var _navecita_pivote: Node2D = $anillo_progreso/navecita_pivote


func _ready() -> void:
	_iniciar_progreso()
	_iniciar_flotacion_cometa()
	_iniciar_orbita_navecita()


func _iniciar_progreso() -> void:
	var tween := create_tween()
	tween.tween_method(_actualizar_progreso, 0.0, 100.0, DURACION_CARGA)
	tween.tween_interval(ESPERA_FINAL)
	tween.tween_callback(_ir_a_titulo)


func _actualizar_progreso(valor: float) -> void:
	_texto_porcentaje.text = "%d%%" % int(round(valor))
	_anillo.set("progreso", valor)


func _ir_a_titulo() -> void:
	get_tree().change_scene_to_file(RUTA_SIGUIENTE)


## Flotacion suave de Cometa dentro del anillo (equivalente a `he-float` del mockup).
func _iniciar_flotacion_cometa() -> void:
	var origen_y: float = _cometa.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(_cometa, "position:y", origen_y - 14.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_cometa, "position:y", origen_y, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## La navecita da una vuelta completa alrededor del anillo cada 9s (equivalente a
## `he-spin 9s linear infinite` del mockup).
func _iniciar_orbita_navecita() -> void:
	_navecita_pivote.rotation = 0.0
	var tween := create_tween().set_loops()
	tween.tween_property(_navecita_pivote, "rotation", TAU, 9.0) \
		.set_trans(Tween.TRANS_LINEAR)
