extends Node2D
## Pantalla de carga (UI ad-hoc — mockup del PO "UI Sistema", Claude Design).
##
## Primera pantalla del juego: un anillo de progreso decorativo avanza solo de 0 a
## 100% y pasa automaticamente al titulo. No hay nada que el nino deba tocar, por eso
## no lleva voz de instruccion (GDD §6 regla 2 aplica a acciones pedidas; aqui no se
## pide ninguna). El logo, el anillo conic-gradient con el slideshow de portadas
## flotando adentro (`vista_portadas.gd`) y la navecita orbitando reproducen el diseno
## del mockup con nodos 2D nativos de Godot.
##
## No conoce ninguna pantalla salvo la siguiente en la cadena fija carga→titulo (igual
## de simple que `Navegacion`, que todavia no existe — HE-09).

const RUTA_SIGUIENTE := "res://escenas/nucleo/titulo.tscn"
const DURACION_CARGA := 2.7
const ESPERA_FINAL := 0.7
const NAVE_DERECHA := preload("res://assets/sprites/nave/nave_estrella.png")
const NAVE_IZQUIERDA := preload("res://assets/sprites/nave/nave_estrella_izquierda.png")

@onready var _texto_porcentaje: Label = $texto_porcentaje
@onready var _anillo: Node2D = $anillo_progreso
@onready var _vista_portadas: Node2D = $anillo_progreso/vista_portadas
@onready var _navecita_pivote: Node2D = $anillo_progreso/navecita_pivote
@onready var _navecita: Sprite2D = $anillo_progreso/navecita_pivote/navecita


func _ready() -> void:
	_iniciar_progreso()
	_iniciar_flotacion_portadas()
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


## Flotacion suave del slideshow de portadas dentro del anillo (equivalente a
## `he-float` del mockup; antes animaba a Cometa, que ahora solo vive en otras
## pantallas del juego).
func _iniciar_flotacion_portadas() -> void:
	var origen_y: float = _vista_portadas.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(_vista_portadas, "position:y", origen_y - 14.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_vista_portadas, "position:y", origen_y, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## La navecita da una vuelta completa alrededor del anillo cada 9s (equivalente a
## `he-spin 9s linear infinite` del mockup).
func _iniciar_orbita_navecita() -> void:
	_navecita_pivote.rotation = 0.0
	var tween := create_tween().set_loops()
	tween.tween_property(_navecita_pivote, "rotation", TAU, 9.0) \
		.set_trans(Tween.TRANS_LINEAR)


## La nave-estrella (diseño final) no da vueltas de cabeza: se mantiene derecha, se
## inclina hacia donde avanza y, en la mitad de abajo del anillo, usa la version que mira
## a la izquierda (la placa "Hermanos Estelares" siempre se lee al derecho).
## El cambio de lado es un giro continuo: al pasar por los costados del anillo (donde
## avanza en vertical) la nave se angosta como si rotara sobre si misma, cambia de
## version cuando esta casi de canto y vuelve a ensancharse; la inclinacion pasa por
## cero en ese momento, asi nada salta de golpe.
const INCLINACION_MAX := 0.35
const ANCHO_GIRO := 0.4      # |cos(rumbo)| bajo el cual la nave va girando
const ANCHO_MINIMO := 0.12   # fraccion del ancho cuando esta de canto

var _escala_nave := Vector2.ONE


func _process(_delta: float) -> void:
	if _escala_nave == Vector2.ONE:
		_escala_nave = _navecita.scale
	var rumbo := _navecita_pivote.rotation
	var avance_x := cos(rumbo)   # >0 avanza hacia la derecha
	var avance_y := sin(rumbo)   # >0 avanza hacia abajo
	var giro := smoothstep(0.0, ANCHO_GIRO, absf(avance_x))
	var lado := 1.0 if avance_x >= 0.0 else -1.0
	_navecita.texture = NAVE_DERECHA if lado > 0.0 else NAVE_IZQUIERDA
	_navecita.scale = Vector2(_escala_nave.x * lerpf(ANCHO_MINIMO, 1.0, giro), _escala_nave.y)
	# Nariz hacia abajo al bajar y hacia arriba al subir, para ambos lados.
	_navecita.global_rotation = avance_y * INCLINACION_MAX * lado * giro
