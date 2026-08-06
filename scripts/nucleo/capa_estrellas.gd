extends Node2D
## Cielo estrellado animado de la pantalla de titulo (HE-05).
##
## Dibuja el campo de estrellas por codigo (`_draw`, sin SVG/PNG nuevos) y las hace
## titilar; de tanto en tanto cruza una estrella fugaz. Puramente ambientacion —
## no depende de ningun asset de personaje (evita tocar
## `assets/fuentes_svg/personajes/`, en curso por HE-02 en paralelo).

const CANTIDAD_ESTRELLAS := 70
const ANCHO_PANTALLA := 1280.0
const ALTO_PANTALLA := 720.0
const SEGUNDOS_ENTRE_FUGACES := 6.0
const DURACION_FUGAZ := 1.1

@onready var _temporizador_fugaz: Timer = $temporizador_fugaz

var _estrellas: Array[Dictionary] = []
var _tiempo := 0.0

var _fugaz_activa := false
var _fugaz_inicio := Vector2.ZERO
var _fugaz_fin := Vector2.ZERO
var _fugaz_progreso := 0.0


func _ready() -> void:
	randomize()
	_generar_estrellas()
	_temporizador_fugaz.wait_time = SEGUNDOS_ENTRE_FUGACES
	_temporizador_fugaz.timeout.connect(_lanzar_fugaz)
	_temporizador_fugaz.start()


func _generar_estrellas() -> void:
	for i in CANTIDAD_ESTRELLAS:
		_estrellas.append({
			"posicion": Vector2(randf_range(0.0, ANCHO_PANTALLA), randf_range(0.0, ALTO_PANTALLA)),
			"radio": randf_range(1.2, 3.2),
			"fase": randf_range(0.0, TAU),
			"velocidad": randf_range(0.8, 1.6),
		})


func _process(delta: float) -> void:
	_tiempo += delta
	if _fugaz_activa:
		_fugaz_progreso += delta / DURACION_FUGAZ
		if _fugaz_progreso >= 1.0:
			_fugaz_activa = false
	queue_redraw()


func _lanzar_fugaz() -> void:
	if _fugaz_activa:
		return
	_fugaz_inicio = Vector2(randf_range(0.0, ANCHO_PANTALLA * 0.4), randf_range(0.0, ALTO_PANTALLA * 0.35))
	_fugaz_fin = _fugaz_inicio + Vector2(randf_range(260.0, 420.0), randf_range(140.0, 220.0))
	_fugaz_progreso = 0.0
	_fugaz_activa = true


func _draw() -> void:
	for estrella in _estrellas:
		var brillo: float = 0.55 + 0.45 * sin(_tiempo * estrella["velocidad"] + estrella["fase"])
		draw_circle(estrella["posicion"], estrella["radio"], Color(1.0, 1.0, 0.96, brillo))
	if _fugaz_activa:
		var punta: Vector2 = _fugaz_inicio.lerp(_fugaz_fin, _fugaz_progreso)
		var cola: Vector2 = _fugaz_inicio.lerp(_fugaz_fin, maxf(_fugaz_progreso - 0.18, 0.0))
		var alfa := 1.0 - _fugaz_progreso
		draw_line(cola, punta, Color(1.0, 0.95, 0.6, alfa * 0.8), 3.0, true)
		draw_circle(punta, 4.0, Color(1.0, 1.0, 0.85, alfa))
