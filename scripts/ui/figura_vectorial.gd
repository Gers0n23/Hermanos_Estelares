extends Control

## Figura "peluche pintado" dibujada por codigo (estrella, corazon, circulo...) con el mismo
## contorno azul noche y carita kawaii del sprite de Cometa. La usan las cartas de "emparejar"
## y su barra de progreso, y sirve a cualquier motor del tema "Colores y formas" del Planeta
## Arcoiris mientras no existan los sprites finales de HE-13.
##
## Las funciones de dibujo son estaticas para poder pintar sobre cualquier CanvasItem:
## `Figura.dibujar(lienzo, "corazon", color, centro, radio)` (con `const Figura := preload(...)`).

const COLOR_CONTORNO := Color("#2B3350")
const COLOR_DISCO := Color("#FFF8EE")
const COLOR_RUBOR := Color(1.0, 0.45, 0.6, 0.45)
const COLORES_ARCOIRIS := [Color("#FF6B6B"), Color("#FF9F4A"), Color("#FFCB3D"), Color("#7DD87A"), Color("#6FD6E8"), Color("#B48CE8")]
const FIGURAS := ["circulo", "cuadrado", "triangulo", "rombo", "estrella", "corazon", "gota", "luna", "flor", "arcoiris"]

## Donde va la carita (en radios, desde el centro) y de que tamano, por figura.
const CARAS := {
	"circulo": [Vector2(0, 0.06), 0.9],
	"cuadrado": [Vector2(0, 0.06), 0.9],
	"triangulo": [Vector2(0, 0.34), 0.62],
	"rombo": [Vector2(0, 0.06), 0.7],
	"estrella": [Vector2(0, 0.1), 0.62],
	"corazon": [Vector2(0, -0.02), 0.8],
	"gota": [Vector2(0, 0.34), 0.7],
	"luna": [Vector2(-0.42, 0.18), 0.5],
	"flor": [Vector2(0, 0.0), 0.5],
}

var figura := "estrella":
	set(valor):
		figura = valor
		queue_redraw()
var color := Color("#FFCB3D"):
	set(valor):
		color = valor
		queue_redraw()
var con_cara := true
var alegre := false:
	set(valor):
		alegre = valor
		queue_redraw()
## Ranura de progreso: disco claro detras de la figura (vacio y translucido si figura == "").
var con_disco := false


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var centro := size / 2.0
	var radio := minf(size.x, size.y) * 0.5
	if con_disco:
		if figura == "":
			draw_circle(centro, radio * 0.9, Color(1, 1, 1, 0.22))
			draw_arc(centro, radio * 0.9, 0.0, TAU, 40, Color(1, 1, 1, 0.75), maxf(2.5, radio * 0.07), true)
			return
		draw_circle(centro, radio * 0.94, COLOR_DISCO)
		draw_arc(centro, radio * 0.94, 0.0, TAU, 40, COLOR_CONTORNO, maxf(2.5, radio * 0.08), true)
		radio *= 0.68
	if figura == "":
		return
	dibujar(self, figura, color, centro, radio, con_cara, alegre)


## Pinta la figura con sombra, volumen (sombra interna y brillo), contorno y carita.
static func dibujar(lienzo: CanvasItem, nombre: String, relleno: Color, centro: Vector2, radio: float, cara := true, feliz := false) -> void:
	var trazo := maxf(2.5, radio * 0.075)
	if nombre == "arcoiris":
		_dibujar_arcoiris(lienzo, centro, radio, trazo, cara, feliz)
		return
	var forma := poligono(nombre, centro, radio)
	if forma.size() < 3:
		return
	lienzo.draw_colored_polygon(_desplazar(forma, Vector2(0, radio * 0.08)), Color(COLOR_CONTORNO, 0.22))
	lienzo.draw_colored_polygon(forma, relleno)
	for trozo in Geometry2D.clip_polygons(forma, _desplazar(forma, Vector2(-radio * 0.07, -radio * 0.13))):
		if trozo.size() >= 3:
			lienzo.draw_colored_polygon(trozo, relleno.darkened(0.16))
	var brillo := _elipse(centro + Vector2(-radio * 0.34, -radio * 0.42), radio * 0.2, radio * 0.12)
	for trozo in Geometry2D.intersect_polygons(brillo, forma):
		if trozo.size() >= 3:
			lienzo.draw_colored_polygon(trozo, Color(1, 1, 1, 0.55))
	contornear(lienzo, forma, trazo)
	if nombre == "flor":
		var centro_flor := _circulo(centro, radio * 0.44, 28)
		lienzo.draw_colored_polygon(centro_flor, Color("#FFE38A"))
		contornear(lienzo, centro_flor, trazo * 0.8)
	if cara and CARAS.has(nombre):
		var datos: Array = CARAS[nombre]
		dibujar_cara(lienzo, centro + (datos[0] as Vector2) * radio, radio * float(datos[1]), feliz)


static func contornear(lienzo: CanvasItem, forma: PackedVector2Array, trazo: float) -> void:
	var cerrado := forma.duplicate()
	cerrado.append(forma[0])
	lienzo.draw_polyline(cerrado, COLOR_CONTORNO, trazo, true)


## Ojitos con brillo (o ^^ si esta feliz), mejillas y sonrisa. `escala` ~ ancho de la cara.
static func dibujar_cara(lienzo: CanvasItem, centro: Vector2, escala: float, feliz := false) -> void:
	var grosor := maxf(2.0, escala * 0.055)
	for lado in [-1.0, 1.0]:
		var ojo := centro + Vector2(lado * escala * 0.3, -escala * 0.05)
		if feliz:
			lienzo.draw_arc(ojo + Vector2(0, escala * 0.05), escala * 0.1, PI * 1.15, PI * 1.85, 10, COLOR_CONTORNO, grosor, true)
		else:
			lienzo.draw_colored_polygon(_elipse(ojo, escala * 0.085, escala * 0.115), COLOR_CONTORNO)
			lienzo.draw_circle(ojo + Vector2(-escala * 0.025, -escala * 0.045), escala * 0.034, Color.WHITE)
		lienzo.draw_colored_polygon(_elipse(centro + Vector2(lado * escala * 0.5, escala * 0.16), escala * 0.1, escala * 0.06), COLOR_RUBOR)
	lienzo.draw_arc(centro + Vector2(0, escala * 0.09), escala * 0.14, PI * 0.15, PI * 0.85, 12, COLOR_CONTORNO, grosor, true)


## Contorno de la figura en coordenadas de pantalla, con esquinas redondeadas.
static func poligono(nombre: String, centro: Vector2, radio: float) -> PackedVector2Array:
	var unitario := PackedVector2Array()
	var redondeo := 0.0
	match nombre:
		"cuadrado":
			unitario = PackedVector2Array([Vector2(-0.8, -0.8), Vector2(0.8, -0.8), Vector2(0.8, 0.8), Vector2(-0.8, 0.8)])
			redondeo = 0.26
		"triangulo":
			unitario = PackedVector2Array([Vector2(0, -0.92), Vector2(0.98, 0.74), Vector2(-0.98, 0.74)])
			redondeo = 0.22
		"rombo":
			unitario = PackedVector2Array([Vector2(0, -0.98), Vector2(0.8, 0), Vector2(0, 0.98), Vector2(-0.8, 0)])
			redondeo = 0.16
		"estrella":
			for i in 10:
				var angulo := -PI / 2.0 + i * PI / 5.0
				unitario.append(Vector2.from_angle(angulo) * (0.98 if i % 2 == 0 else 0.47))
			redondeo = 0.1
		"corazon":
			for i in 56:
				var t := TAU * i / 56.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				unitario.append(Vector2(x, y - 2.5) / 16.5)
		"gota":
			unitario.append(Vector2(0, -1.0))
			for i in 25:
				var angulo := deg_to_rad(-40.0 + 260.0 * i / 24.0)
				unitario.append(Vector2(0, 0.32) + Vector2.from_angle(angulo) * 0.64)
			redondeo = 0.06
		"luna":
			return _mayor(Geometry2D.clip_polygons(_circulo(centro, radio * 0.92, 40), _circulo(centro + Vector2(0.44, -0.3) * radio, radio * 0.74, 40)))
		"flor":
			var flor := _circulo(centro, radio * 0.5, 28)
			for i in 5:
				var petalo := _circulo(centro + Vector2.from_angle(-PI / 2.0 + i * TAU / 5.0) * radio * 0.52, radio * 0.44, 28)
				flor = _mayor(Geometry2D.merge_polygons(flor, petalo))
			return flor
		_:
			return _circulo(centro, radio * 0.9, 40)
	var puntos := PackedVector2Array()
	for p in unitario:
		puntos.append(centro + p * radio)
	if redondeo > 0.0:
		puntos = _redondear(puntos, redondeo * radio)
	return puntos


static func _dibujar_arcoiris(lienzo: CanvasItem, centro: Vector2, radio: float, trazo: float, cara: bool, feliz: bool) -> void:
	var base := centro + Vector2(0, radio * 0.4)
	var ancho := radio * 0.12
	var exterior := radio * 0.92
	for i in COLORES_ARCOIRIS.size():
		lienzo.draw_arc(base, exterior - ancho * (i + 0.5), PI, TAU, 40, COLORES_ARCOIRIS[i], ancho + 1.0, true)
	lienzo.draw_arc(base, exterior, PI, TAU, 40, COLOR_CONTORNO, trazo, true)
	lienzo.draw_arc(base, exterior - ancho * COLORES_ARCOIRIS.size(), PI, TAU, 40, COLOR_CONTORNO, trazo, true)
	var centro_nube := exterior - ancho * COLORES_ARCOIRIS.size() * 0.5
	for lado in [-1.0, 1.0]:
		var c := base + Vector2(lado * centro_nube, radio * 0.02)
		var nube := _circulo(c + Vector2(0, -radio * 0.08), radio * 0.24, 24)
		for desfase in [Vector2(-0.24, 0.04), Vector2(0.24, 0.04)]:
			nube = _mayor(Geometry2D.merge_polygons(nube, _circulo(c + desfase * radio, radio * 0.19, 24)))
		lienzo.draw_colored_polygon(nube, Color.WHITE)
		contornear(lienzo, nube, trazo)
		if cara:
			dibujar_cara(lienzo, c + Vector2(0, -radio * 0.02), radio * 0.32, feliz)
	var chispa := poligono("estrella", centro + Vector2(radio * 0.55, -radio * 0.62), radio * 0.2)
	lienzo.draw_colored_polygon(chispa, Color("#FFCB3D"))
	contornear(lienzo, chispa, trazo * 0.7)


static func _redondear(forma: PackedVector2Array, radio: float) -> PackedVector2Array:
	var adentro := Geometry2D.offset_polygon(forma, -radio, Geometry2D.JOIN_MITER)
	if adentro.is_empty():
		return forma
	var afuera := Geometry2D.offset_polygon(_mayor(adentro), radio, Geometry2D.JOIN_ROUND)
	return forma if afuera.is_empty() else _mayor(afuera)


static func _mayor(poligonos: Array) -> PackedVector2Array:
	var mejor := PackedVector2Array()
	var mejor_area := -1.0
	for p in poligonos:
		var area := absf(_area(p))
		if area > mejor_area:
			mejor_area = area
			mejor = p
	return mejor


static func _area(forma: PackedVector2Array) -> float:
	var suma := 0.0
	for i in forma.size():
		var a := forma[i]
		var b := forma[(i + 1) % forma.size()]
		suma += a.x * b.y - b.x * a.y
	return suma * 0.5


static func _circulo(centro: Vector2, radio: float, lados: int) -> PackedVector2Array:
	return _elipse(centro, radio, radio, lados)


static func _elipse(centro: Vector2, radio_x: float, radio_y: float, lados := 24) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		var angulo := TAU * i / lados
		puntos.append(centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y))
	return puntos


static func _desplazar(forma: PackedVector2Array, desfase: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for p in forma:
		puntos.append(p + desfase)
	return puntos
