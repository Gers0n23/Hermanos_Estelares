class_name PiezaEncajar
extends Control

## Pieza arrastrable del motor "encajar" (docs/fichas/motor-encajar.md §4).
##
## No sabe nada de huecos ni de reglas: se dibuja, avisa cuando la toman, la mueven, la sueltan o
## solo la tocan, y sabe animarse. El motor decide que pasa. Entrada unificada tactil + mouse: en
## tablet Godot convierte el dedo en mouse (emulate_mouse_from_touch), asi que un solo camino.
##
## Un "toque" es presionar y soltar casi sin moverse: sirve para girar la pieza (Sofia, zona 3+) o
## para mandarla sola a su casita (Maxi). Todo lo demas es arrastrar (GDD §6 regla 4).

signal tomada(pieza: PiezaEncajar)
signal movida(pieza: PiezaEncajar, punto: Vector2)
signal soltada(pieza: PiezaEncajar, punto: Vector2)
signal tocada(pieza: PiezaEncajar)

const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const UMBRAL_TOQUE_PX := 18.0
## Radio minimo tocable en pantalla (96 px de diametro, GDD §6.1) aunque la pieza sea delgada.
const RADIO_TOQUE_MINIMO := 48.0
const MARGEN_TOQUE := 14.0

var id := ""
var forma := "circulo"
var ancho := 100.0
var alto := 100.0
var color := Color.WHITE
var decoracion := ""
## Carita siempre visible (Maxi/Nicole) o solo al completar su figura (`cara_al_completar`).
var cara_siempre := true
var cara_al_completar := false
var especial := false
var alegre := false:
	set(valor):
		alegre = valor
		queue_redraw()

## Estado que maneja el motor.
var rotacion_grados := 0.0
var casa := Vector2.ZERO
var escala_bandeja := 1.0
var colocada := false
var bloqueada := false
var hueco = null

var _base := PackedVector2Array()
var _dibujo := PackedVector2Array()
var _toque := PackedVector2Array()
var _presionada := false
var _se_movio := false
var _inicio := Vector2.ZERO
var _brillo := 0.0


func configurar(datos: Dictionary) -> void:
	id = str(datos.get("id", ""))
	forma = str(datos.get("forma", "circulo"))
	ancho = float(datos.get("ancho", 100.0))
	alto = float(datos.get("alto", ancho))
	color = Color(str(datos.get("color", "#FFCB3D")))
	decoracion = str(datos.get("decoracion", ""))
	especial = bool(datos.get("especial", false))
	_base = Geo.contorno(forma, ancho, alto)
	_dibujo = Geo.redondeado(forma, _base, ancho, alto)
	var crecido := Geometry2D.offset_polygon(_base, MARGEN_TOQUE, Geometry2D.JOIN_ROUND)
	_toque = Geo.mayor(crecido) if not crecido.is_empty() else _base
	var lado := maxf(ancho, alto) * 1.25 + 30.0
	size = Vector2(lado, lado)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


## Poligono sin redondear, girado segun su rotacion logica y centrado en el origen (para calzar).
func poligono(grados := NAN) -> PackedVector2Array:
	return Geo.transformado(_base, rotacion_grados if is_nan(grados) else grados)


## OJO: se usa `position` y no `global_position`. En un Control girado, `global_position` es el
## origen YA girado (una pieza a 180° quedaba corrida un tamano entero). `position` es la esquina
## sin girar, y el tablero que contiene las piezas esta en el origen de la pantalla.
func centro_global() -> Vector2:
	return position + size / 2.0


func fijar_centro(punto: Vector2) -> void:
	position = punto - size / 2.0


func radio_visual() -> float:
	return maxf(ancho, alto) / 2.0


func _has_point(punto: Vector2) -> bool:
	var local := punto - size / 2.0
	if Geometry2D.is_point_in_polygon(local, _toque):
		return true
	return local.length() * maxf(scale.x, 0.01) <= RADIO_TOQUE_MINIMO


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			if bloqueada:
				return
			_presionada = true
			_se_movio = false
			_inicio = evento.global_position
			accept_event()
			tomada.emit(self)
		elif _presionada:
			_presionada = false
			accept_event()
			if _se_movio:
				soltada.emit(self, evento.global_position)
			else:
				tocada.emit(self)
	elif evento is InputEventMouseMotion and _presionada:
		accept_event()
		if not _se_movio and evento.global_position.distance_to(_inicio) > UMBRAL_TOQUE_PX:
			_se_movio = true
		if _se_movio:
			movida.emit(self, evento.global_position)


## El motor cancela un arrastre en curso (derrota-gag, reintento): la pieza deja de seguir el dedo.
func cancelar_arrastre() -> void:
	_presionada = false
	_se_movio = false


func esta_arrastrando() -> bool:
	return _presionada and _se_movio


# ---------------------------------------------------------------------------
# Animaciones
# ---------------------------------------------------------------------------

## Un solo tween de posicion/escala a la vez (y otro de giro): una animacion nueva corta la anterior
## y parte desde donde quedo, asi un toque rapido nunca deja la pieza con una escala equivocada.
var _tween: Tween
var _tween_giro: Tween


func nuevo_tween() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


func nuevo_tween_giro() -> Tween:
	if _tween_giro != null and _tween_giro.is_valid():
		_tween_giro.kill()
	_tween_giro = create_tween()
	return _tween_giro


func aparecer(retraso: float) -> void:
	scale = Vector2.ZERO
	var tween := nuevo_tween()
	tween.tween_interval(retraso)
	tween.tween_property(self, "scale", Vector2.ONE * escala_bandeja, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func pulso() -> void:
	var tween := nuevo_tween()
	var base := Vector2.ONE * escala_bandeja
	tween.tween_property(self, "scale", base * 1.12, 0.06)
	tween.tween_property(self, "scale", base, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func agrandar(escala: float, duracion := 0.12) -> void:
	nuevo_tween().tween_property(self, "scale", Vector2.ONE * escala, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func girar_a(grados: float, duracion := 0.2) -> void:
	rotacion_grados = wrapf(grados, 0.0, 360.0)
	var destino := deg_to_rad(rotacion_grados)
	# Gira por el camino corto para que un paso de 270° a 0° no de la vuelta entera.
	destino = rotation + wrapf(destino - rotation, -PI, PI)
	nuevo_tween_giro().tween_property(self, "rotation", destino, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Vuelve a su lugar en la bandeja con un rebote. `sacudir` agrega el meneo del "no es este".
func volver_a_casa(sacudir := false) -> void:
	var tween := nuevo_tween()
	if sacudir:
		var origen := position
		for desfase in [-14.0, 14.0, -8.0, 0.0]:
			tween.tween_property(self, "position", origen + Vector2(desfase, 0), 0.06)
	tween.tween_property(self, "position", casa - size / 2.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * escala_bandeja, 0.3)


func encajar_en(centro: Vector2, grados: float) -> void:
	colocada = true
	bloqueada = true
	cancelar_arrastre()
	rotacion_grados = wrapf(grados, 0.0, 360.0)
	var destino := deg_to_rad(rotacion_grados)
	destino = rotation + wrapf(destino - rotation, -PI, PI)
	if _tween_giro != null and _tween_giro.is_valid():
		_tween_giro.kill()
	var tween := nuevo_tween()
	tween.tween_property(self, "position", centro - size / 2.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", destino, 0.22)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.12, 0.22)
	tween.tween_property(self, "scale", Vector2(1.08, 0.9), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Saltito en su lugar. Si la pieza estaba en camino a otro lado, el salto parte desde su destino.
func saltito(altura := 26.0, retraso := 0.0) -> void:
	var origen := position
	if colocada and hueco != null:
		origen = (hueco["centro"] as Vector2) - size / 2.0
	elif not colocada:
		origen = casa - size / 2.0
	var tween := nuevo_tween()
	tween.tween_interval(retraso)
	tween.tween_property(self, "position", origen - Vector2(0, altura), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origen, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if colocada:
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)


## Risa de Maxi (zona 2): la pieza se sacude de cosquillas.
func reir() -> void:
	alegre = true
	var tween := nuevo_tween_giro()
	for i in 6:
		tween.tween_property(self, "rotation", deg_to_rad(rotacion_grados + (8.0 if i % 2 == 0 else -8.0)), 0.07)
	tween.tween_property(self, "rotation", deg_to_rad(rotacion_grados), 0.08)


func brillar(segundos: float) -> void:
	_brillo = segundos
	set_process(true)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_brillo -= delta
	if _brillo <= 0.0:
		_brillo = 0.0
		set_process(false)
	queue_redraw()


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _draw() -> void:
	var centro := size / 2.0
	var forma_dibujo := Geo.desplazado(_dibujo, centro)
	var referencia := radio_visual()
	if _brillo > 0.0:
		var intensidad := 0.35 + 0.35 * absf(sin(_brillo * 7.0))
		var aura := Geometry2D.offset_polygon(forma_dibujo, 12.0, Geometry2D.JOIN_ROUND)
		for trozo in aura:
			draw_colored_polygon(trozo, Color(1.0, 0.85, 0.3, intensidad))
	match decoracion:
		"rueda":
			_dibujar_rueda(centro, referencia)
		_:
			Geo.pintar(self, forma_dibujo, color, referencia)
	match decoracion:
		"aleta":
			_dibujar_aleta(forma_dibujo, referencia)
		"manchas":
			_dibujar_manchas(forma_dibujo, centro, referencia)
		"ventanas":
			_dibujar_ventanas(centro)
	if especial:
		_dibujar_destellos(centro, referencia)
	if cara_siempre or (cara_al_completar and alegre):
		var c := Geo.centroide(forma_dibujo)
		var escala_cara := clampf(minf(ancho, alto) * 0.55, 22.0, 90.0)
		if decoracion == "rueda":
			return
		Figura.dibujar_cara(self, c + Vector2(0, escala_cara * 0.05), escala_cara, alegre)


func _dibujar_rueda(centro: Vector2, radio: float) -> void:
	var neumatico := Geo.elipse(centro, radio, radio, 40)
	Geo.pintar(self, neumatico, Color("#3A3F55"), radio)
	var llanta := Geo.elipse(centro, radio * 0.58, radio * 0.58, 32)
	draw_colored_polygon(llanta, Color("#CFD8E6"))
	Figura.contornear(self, llanta, maxf(2.5, radio * 0.06))
	for i in 5:
		var direccion := Vector2.from_angle(TAU * i / 5.0 - PI / 2.0)
		draw_line(centro + direccion * radio * 0.14, centro + direccion * radio * 0.5, Geo.COLOR_CONTORNO, maxf(3.0, radio * 0.07), true)
	draw_circle(centro, radio * 0.16, color)
	draw_arc(centro, radio * 0.16, 0.0, TAU, 20, Geo.COLOR_CONTORNO, maxf(2.0, radio * 0.05), true)
	if alegre:
		Figura.dibujar_cara(self, centro + Vector2(0, radio * 0.02), radio * 0.34, true)


## Espalda de dinosaurio: puas a lo largo de los lados inclinados del triangulo.
func _dibujar_aleta(forma_dibujo: PackedVector2Array, referencia: float) -> void:
	var c := Geo.centroide(forma_dibujo)
	var tono := color.darkened(0.3)
	for p in forma_dibujo.size():
		if p % 3 != 0:
			continue
		var punto := forma_dibujo[p]
		var hacia_afuera := (punto - c).normalized()
		if hacia_afuera.y > 0.55:
			continue
		var base := punto - hacia_afuera * referencia * 0.05
		var lado := hacia_afuera.orthogonal() * referencia * 0.09
		var pua := PackedVector2Array([base - lado, base + hacia_afuera * referencia * 0.16, base + lado])
		draw_colored_polygon(pua, tono)
	for desfase in [Vector2(-0.3, 0.35), Vector2(0.28, 0.42), Vector2(0.0, 0.1)]:
		draw_colored_polygon(Geo.elipse(c + desfase * referencia, referencia * 0.09, referencia * 0.06), Color(tono, 0.6))


func _dibujar_manchas(forma_dibujo: PackedVector2Array, centro: Vector2, referencia: float) -> void:
	for desfase in [Vector2(-0.45, -0.15), Vector2(0.1, -0.3), Vector2(0.42, 0.12), Vector2(-0.12, 0.28)]:
		var mancha := Geo.elipse(centro + desfase * referencia, referencia * 0.13, referencia * 0.09)
		for trozo in Geometry2D.intersect_polygons(mancha, forma_dibujo):
			draw_colored_polygon(trozo, Color(color.darkened(0.28), 0.7))


func _dibujar_ventanas(centro: Vector2) -> void:
	for lado in [-1.0, 1.0]:
		var rect := Rect2(centro + Vector2(lado * ancho * 0.22 - ancho * 0.15, -alto * 0.36), Vector2(ancho * 0.3, alto * 0.34))
		var ventana := Geo.redondeado("rectangulo", Geo.contorno("rectangulo", rect.size.x, rect.size.y), rect.size.x, rect.size.y)
		ventana = Geo.desplazado(ventana, rect.get_center())
		draw_colored_polygon(ventana, Color("#CFF5F1"))
		Figura.contornear(self, ventana, 3.5)
	draw_circle(centro + Vector2(ancho * 0.44, alto * 0.12), alto * 0.09, Color("#FFE38A"))
	draw_arc(centro + Vector2(ancho * 0.44, alto * 0.12), alto * 0.09, 0.0, TAU, 20, Geo.COLOR_CONTORNO, 3.0, true)


func _dibujar_destellos(centro: Vector2, referencia: float) -> void:
	for desfase in [Vector2(-0.8, -0.75), Vector2(0.85, -0.55), Vector2(0.7, 0.8)]:
		var chispa := Figura.poligono("estrella", centro + desfase * referencia, referencia * 0.16)
		draw_colored_polygon(chispa, Color("#FFE38A"))
		Figura.contornear(self, chispa, 2.5)
