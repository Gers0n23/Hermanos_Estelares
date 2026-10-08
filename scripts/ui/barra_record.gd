extends Control

## Barra vertical de puntaje con la banderita-cupcake del record (ficha motor-emparejar §10.1): el record
## se lee sin numeros. La barra sube con cada punto; la banderita esta a la altura del record de ESTE
## hermano (nunca el de otro). Cuando la barra la pasa, la banderita salta y se emite `record_pasado`
## (el motor pone confeti chico y la palabra "¡record!"; el juego no se pausa).
## Sin record previo (m6) no hay banderita: al final se clava con `plantar_banderita()` ("¡tu primer
## record!"). Generica: sirve a cualquier motor con puntaje.
##
## UX HE-60 M1: el alto (`tope`) se fija UNA vez en `preparar()` y no cambia en toda la partida: la
## banderita nunca se mueve y el relleno nunca "baja" tras un acierto. Si el puntaje supera el tope, la
## barra rebalsa: queda llena y del borde de arriba salen burbujas arcoiris (`fijar_puntaje` devuelve true
## para que el motor ponga su "blup").
## UX HE-60 m4: tocarla la menea y emite `tocada` (el motor pone un "ding" suave). No cambia el juego.

signal record_pasado
signal tocada

const Cupcake := preload("res://scripts/ui/dibujo_cupcake.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const ANCHO_TUBO := 34.0
const ALTO_BANDERITA := 46.0
const SEGUNDOS_BURBUJA := 0.9
const ENFRIAMIENTO_TOQUE_MS := 1000

var record := 0
var tope := 1000.0
var _mostrado := 0.0  ## puntaje dibujado (sube suave)
var _puntaje := 0
var _pasado := false
var _salto := 0.0
var _plantada := false
var _tween: Tween
## Burbujas del rebalse: {x, t (0-1), radio, color}.
var _burbujas: Array[Dictionary] = []
var _meneo := 0.0
var _ultimo_toque_ms := -ENFRIAMIENTO_TOQUE_MS


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)


## Solo el tubo es tocable (no el margen del Control), para no robarle toques a nada vecino.
func _has_point(punto: Vector2) -> bool:
	return absf(punto.x - size.x / 2.0) <= ANCHO_TUBO / 2.0 + 14.0 and punto.y >= 0.0 and punto.y <= size.y


func _gui_input(evento: InputEvent) -> void:
	var toque: bool = (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT) 		or (evento is InputEventScreenTouch and evento.pressed)
	if not toque:
		return
	accept_event()
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_toque_ms < ENFRIAMIENTO_TOQUE_MS:
		return
	_ultimo_toque_ms = ahora
	var t := create_tween()
	t.tween_method(_fijar_meneo, 0.0, 1.0, 0.2)
	tocada.emit()


## `record` 0 = sin banderita. `tope_sugerido` = alto de la barra si no hay record (p. ej. el umbral de
## 3 estrellitas o una estimacion del nivel).
func preparar(record_previo: int, tope_sugerido: float) -> void:
	record = maxi(0, record_previo)
	tope = maxf(record * 1.3, tope_sugerido) if record > 0 else maxf(100.0, tope_sugerido)
	_pasado = false
	_plantada = false
	queue_redraw()


func puntaje() -> int:
	return _puntaje


func paso_el_record() -> bool:
	return _pasado


## Devuelve true si el puntaje rebalsa la barra (paso el tope): salieron burbujas.
func fijar_puntaje(valor: int) -> bool:
	var subio := valor > _puntaje
	_puntaje = valor
	var rebalsa := subio and valor > tope
	if rebalsa:
		_soltar_burbujas()
	if record > 0 and not _pasado and valor > record:
		_pasado = true
		_saltar()
		record_pasado.emit()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_fijar_mostrado, _mostrado, float(valor), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return rebalsa


## Primer record: la banderita se clava a la altura del puntaje final.
func plantar_banderita() -> void:
	record = _puntaje
	_plantada = true
	_saltar()


## Punto (global) donde esta la banderita, para el confeti del motor.
func punto_banderita() -> Vector2:
	return global_position + Vector2(size.x / 2.0, _altura(record))


func _saltar() -> void:
	var t := create_tween()
	t.tween_method(_fijar_salto, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_method(_fijar_salto, 1.0, 0.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _fijar_mostrado(valor: float) -> void:
	_mostrado = valor
	queue_redraw()


func _fijar_salto(valor: float) -> void:
	_salto = valor
	queue_redraw()


func _fijar_meneo(valor: float) -> void:
	_meneo = sin(valor * PI * 3.0) * (1.0 - valor)
	queue_redraw()


func _soltar_burbujas() -> void:
	var colores: Array = Figura.COLORES_ARCOIRIS
	for i in 4:
		_burbujas.append({"x": randf_range(-12.0, 12.0), "t": -i * 0.12, "radio": randf_range(5.0, 9.0),
			"color": colores[randi() % colores.size()], "deriva": randf_range(-18.0, 18.0)})
	set_process(true)


func _process(delta: float) -> void:
	for burbuja in _burbujas:
		burbuja["t"] += delta / SEGUNDOS_BURBUJA
	_burbujas = _burbujas.filter(func(b: Dictionary) -> bool: return b["t"] < 1.0)
	if _burbujas.is_empty():
		set_process(false)
	queue_redraw()


func _altura(valor: float) -> float:
	var util := size.y - 24.0
	return size.y - 12.0 - util * clampf(valor / maxf(1.0, tope), 0.0, 1.0)


func _draw() -> void:
	var x := size.x / 2.0 + _meneo * 6.0
	var tubo := Rect2(x - ANCHO_TUBO / 2.0, 0, ANCHO_TUBO, size.y)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.28)
	fondo.border_color = COLOR_CONTORNO
	fondo.set_border_width_all(4)
	fondo.set_corner_radius_all(int(ANCHO_TUBO / 2.0))
	draw_style_box(fondo, tubo)
	var y := _altura(_mostrado)
	if _mostrado > 0.0:
		# Relleno en franjas de arcoiris (de abajo hacia arriba), sin numeros.
		var colores: Array = Figura.COLORES_ARCOIRIS
		var abajo := size.y - 6.0
		var alto_total := abajo - y
		for i in colores.size():
			var desde := abajo - alto_total * (i + 1) / colores.size()
			var hasta := abajo - alto_total * i / colores.size()
			draw_rect(Rect2(x - ANCHO_TUBO / 2.0 + 6, desde, ANCHO_TUBO - 12, hasta - desde), colores[i])
		draw_circle(Vector2(x, y), ANCHO_TUBO / 2.0 - 5.0, colores[colores.size() - 1])
		draw_arc(Vector2(x, y), ANCHO_TUBO / 2.0 - 5.0, 0, TAU, 24, COLOR_CONTORNO, 3.0, true)
	if record > 0:
		var pie := Vector2(x - ANCHO_TUBO / 2.0 - 4.0, _altura(record) - _salto * 18.0)
		draw_line(pie + Vector2(0, 0), pie + Vector2(ANCHO_TUBO + 8.0, 0), COLOR_CONTORNO, 3.0, true)
		Cupcake.banderita(self, pie + Vector2(-2, 0), ALTO_BANDERITA * (1.0 + 0.25 * _salto))
	# Rebalse: burbujas arcoiris que suben desde el borde de arriba del tubo.
	for burbuja in _burbujas:
		var t: float = burbuja["t"]
		if t < 0.0:
			continue
		var p := Vector2(x + burbuja["x"] + burbuja["deriva"] * t, 8.0 - t * 70.0)
		var r: float = burbuja["radio"] * (0.6 + 0.6 * t)
		var alfa := 1.0 - t
		draw_circle(p, r, Color(burbuja["color"], 0.55 * alfa))
		draw_arc(p, r, 0, TAU, 20, Color(1, 1, 1, 0.9 * alfa), 2.0, true)
		draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.25, Color(1, 1, 1, 0.8 * alfa))
