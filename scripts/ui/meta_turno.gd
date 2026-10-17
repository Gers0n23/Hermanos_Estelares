extends Control

## La guirnalda de lucecitas: la meta del turno (docs/fichas/modo-equipo.md §4.1, v6.1 UX N9; HE-59).
##
## Regleta vertical del color de quien juega, pegada 16 px a la izquierda de la mesa del motor, con tantas
## lucecitas de 48 px como el tope del turno (2 Nicole, 3 Sofia). Se llenan de abajo hacia arriba en los
## colores del arcoiris en orden (nunca del color de quien juega); con una menos que el tope la ultima
## respira; al llegar al tope destella y suelta una chispa a los pies del rival. Apagadas se ven "por
## prender" (vidrio blanco translucido), nunca negras, grises ni con candado. La maneja el gestor.

const ANCHO := 64.0
const LUZ := 48.0
const SEPARACION := 16.0
const COLOR_CONTORNO := Color("#2B3350")
const ARCOIRIS := [Color("#FF6B6B"), Color("#FFCB3D"), Color("#4A8BE0")]

var tope := 0
var color_marco := Color.WHITE
var encendidas := 0

var _tiempo := 0.0
var _pop := {}
var _destello := 0.0
var _apagando := 1.0
var _titila := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func alto_para(n: int) -> float:
	return n * LUZ + (n + 1) * SEPARACION


## Aparece en el paso 4 con un pop blandito (0,3 s), con `n` lucecitas apagadas. `ancla` = punto global
## donde va su borde DERECHO-centro (lo da el motor con `ancla_meta_turno()`).
func mostrar(n: int, color: Color, ancla: Vector2) -> void:
	tope = n
	color_marco = color
	encendidas = 0
	_pop.clear()
	_apagando = 1.0
	size = Vector2(ANCHO, alto_para(n))
	if ancla == Vector2.INF:
		ancla = Vector2(40.0 + ANCHO, 364.0)
	# Nunca a menos de 40 px del borde izquierdo de la pantalla.
	var izquierda := maxf(40.0, ancla.x - ANCHO)
	global_position = Vector2(izquierda, ancla.y - size.y / 2.0)
	pivot_offset = size / 2.0
	visible = true
	scale = Vector2(1.15, 1.15)
	modulate.a = 1.0
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


## Con cada acierto se enciende la siguiente, de abajo hacia arriba, con un pop 1,0 -> 1,3 -> 1,0.
func encender() -> int:
	if not visible or encendidas >= tope:
		return encendidas
	encendidas += 1
	_pop[encendidas - 1] = 0.0
	queue_redraw()
	return encendidas


## Al llegar al tope: destella en arcoiris 2 veces (0,5 s).
func destellar() -> void:
	_destello = 0.5


## Si el turno termina con fallo: las encendidas se apagan despacito (0,3 s), sin sonido ni rojo.
func apagar_despacio() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "_apagando", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		encendidas = 0
		_apagando = 1.0)


## Se retira dentro del marco en el paso 2 del pase siguiente (0,2 s).
func retirar() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.2, 1.0), 0.2)
	tween.tween_callback(func() -> void:
		visible = false
		scale = Vector2.ONE)


## Un toque encima solo hace titilar las encendidas (0,2 s, sin sonido).
func titilar() -> void:
	_titila = 0.2


## Centro global de la lucecita mas alta encendida (de ahi sale la chispa hacia el rival).
func punto_salida() -> Vector2:
	var i := maxi(0, encendidas - 1)
	return global_position + _centro_luz(i)


func _centro_luz(i: int) -> Vector2:
	# Indice 0 = la de abajo.
	var y := size.y - SEPARACION - LUZ / 2.0 - i * (LUZ + SEPARACION)
	return Vector2(ANCHO / 2.0, y)


func _process(delta: float) -> void:
	if not visible:
		return
	_tiempo += delta
	for i in _pop.keys():
		_pop[i] += delta
		if _pop[i] > 0.25:
			_pop.erase(i)
	_destello = maxf(0.0, _destello - delta)
	_titila = maxf(0.0, _titila - delta)
	queue_redraw()


func _draw() -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color_marco
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(26)
	caja.anti_aliasing = true
	draw_style_box(caja, Rect2(Vector2.ZERO, size))
	for i in tope:
		var centro := _centro_luz(i)
		var radio := LUZ / 2.0
		var encendida := i < encendidas
		var escala := 1.0
		if _pop.has(i):
			escala = 1.0 + 0.3 * sin(_pop[i] / 0.25 * PI)
		# Con una menos que el tope, la ultima respira (sin sonido ni voz).
		if i == tope - 1 and encendidas == tope - 1 and tope > 1:
			escala *= 1.0 + 0.12 * (0.5 + 0.5 * sin(_tiempo * TAU / 1.2))
		radio *= escala
		if encendida:
			var color: Color = ARCOIRIS[i % ARCOIRIS.size()]
			if _destello > 0.0:
				color = Color.from_hsv(fmod(_tiempo * 4.0 + i * 0.2, 1.0), 0.6, 1.0)
			color.a = _apagando * (0.6 if _titila > 0.0 and int(_titila * 40.0) % 2 == 0 else 1.0)
			draw_circle(centro, radio + 6.0, Color(color, 0.3 * _apagando))
			draw_circle(centro, radio, color)
			draw_circle(centro + Vector2(-radio * 0.3, -radio * 0.35), radio * 0.22, Color(1, 1, 1, 0.75 * _apagando))
		else:
			# "Por prender": vidrio blanco translucido con brillo suave.
			draw_circle(centro, radio, Color(1, 1, 1, 0.42))
			draw_circle(centro + Vector2(-radio * 0.3, -radio * 0.35), radio * 0.2, Color(1, 1, 1, 0.8))
		draw_arc(centro, radio, 0.0, TAU, 32, COLOR_CONTORNO, 3.0, true)
