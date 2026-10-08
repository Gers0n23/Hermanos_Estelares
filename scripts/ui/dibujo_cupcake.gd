extends RefCounted

## Dibujos por codigo del lenguaje visual del reto (docs/roadmap-rio-de-pintura.md §3.3 y ficha
## motor-emparejar §10.1): cupcake, banderita-cupcake del record, trofeo-cupcake y trebol de "¡a la
## primera!". Estilo "peluche pintado" con el contorno universal del elenco. Sin assets: cuando llegue el
## arte final (HE-13) se reemplazan aqui y los usan todos los motores con puntaje.

const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const MASA := Color("#E9A35B")
const GLASEADO := Color("#F7A8D0")
const CEREZA := Color("#FF6B6B")
const CREMA := Color("#FFF8EE")


## Cupcake de `ancho` px con la base apoyada en `base` (centro inferior).
static func cupcake(lienzo: CanvasItem, base: Vector2, ancho: float, glaseado := GLASEADO) -> void:
	var alto_pote := ancho * 0.5
	var pote := PackedVector2Array([
		base + Vector2(-ancho * 0.36, 0), base + Vector2(ancho * 0.36, 0),
		base + Vector2(ancho * 0.48, -alto_pote), base + Vector2(-ancho * 0.48, -alto_pote)])
	lienzo.draw_colored_polygon(pote, MASA)
	for i in range(1, 4):
		var x := -ancho * 0.36 + ancho * 0.18 * i
		lienzo.draw_line(base + Vector2(x, -2), base + Vector2(x * 1.3, -alto_pote + 2), Color(COLOR_CONTORNO, 0.35), maxf(1.5, ancho * 0.03), true)
	_contorno(lienzo, pote, maxf(2.0, ancho * 0.05))
	var centro := base + Vector2(0, -alto_pote - ancho * 0.12)
	var nube := PackedVector2Array()
	for i in 24:
		var a := PI + PI * i / 23.0
		var r := ancho * 0.5 + sin(a * 6.0) * ancho * 0.04
		nube.append(centro + Vector2(cos(a) * r, sin(a) * r * 0.62))
	nube.append(centro + Vector2(ancho * 0.5, ancho * 0.1))
	nube.append(centro + Vector2(-ancho * 0.5, ancho * 0.1))
	lienzo.draw_colored_polygon(nube, glaseado)
	_contorno(lienzo, nube, maxf(2.0, ancho * 0.05))
	for p in [Vector2(-0.22, -0.12), Vector2(0.14, -0.2), Vector2(0.28, -0.05)]:
		lienzo.draw_circle(centro + p * ancho, maxf(1.5, ancho * 0.035), Color.WHITE)


## Banderita-cupcake clavada en `punto` (pie del mastil): el record que hay que pasar.
static func banderita(lienzo: CanvasItem, punto: Vector2, alto: float) -> void:
	var cima := punto + Vector2(0, -alto)
	lienzo.draw_line(punto, cima, COLOR_CONTORNO, maxf(2.5, alto * 0.07), true)
	var tela := PackedVector2Array([cima, cima + Vector2(alto * 0.7, alto * 0.18), cima + Vector2(0, alto * 0.42)])
	lienzo.draw_colored_polygon(tela, GLASEADO)
	_contorno(lienzo, tela, maxf(2.0, alto * 0.05))
	cupcake(lienzo, cima + Vector2(alto * 0.26, alto * 0.3), alto * 0.24)
	lienzo.draw_circle(cima, maxf(2.5, alto * 0.07), DORADO)


## Trofeo-cupcake (mismo concepto que el del Rio de pintura): copa dorada con un cupcake encima.
static func trofeo(lienzo: CanvasItem, base: Vector2, ancho: float) -> void:
	var pie := Rect2(base + Vector2(-ancho * 0.3, -ancho * 0.16), Vector2(ancho * 0.6, ancho * 0.16))
	lienzo.draw_rect(pie, DORADO.darkened(0.15))
	lienzo.draw_rect(pie, COLOR_CONTORNO, false, maxf(2.0, ancho * 0.04))
	var boca := base + Vector2(0, -ancho * 0.95)
	var tallo := Rect2(base + Vector2(-ancho * 0.08, -ancho * 0.45), Vector2(ancho * 0.16, ancho * 0.3))
	lienzo.draw_rect(tallo, DORADO.darkened(0.08))
	lienzo.draw_rect(tallo, COLOR_CONTORNO, false, maxf(2.0, ancho * 0.04))
	var copa := PackedVector2Array()
	for i in 21:
		var a := PI * i / 20.0
		copa.append(boca + Vector2(-cos(a) * ancho * 0.42, sin(a) * ancho * 0.52))
	lienzo.draw_colored_polygon(copa, DORADO)
	_contorno(lienzo, copa, maxf(2.0, ancho * 0.05))
	for lado in [-1.0, 1.0]:
		lienzo.draw_arc(boca + Vector2(lado * ancho * 0.45, ancho * 0.2), ancho * 0.16, 0, TAU, 20, COLOR_CONTORNO, maxf(2.0, ancho * 0.05), true)
	cupcake(lienzo, boca + Vector2(0, ancho * 0.04), ancho * 0.62)


## Trebol de cuatro hojas dorado: el sello de "¡a la primera!".
static func trebol(lienzo: CanvasItem, centro: Vector2, radio: float) -> void:
	lienzo.draw_line(centro, centro + Vector2(radio * 0.5, radio * 1.1), COLOR_CONTORNO, maxf(2.0, radio * 0.14), true)
	for i in 4:
		var a := PI / 4.0 + TAU * i / 4.0
		var hoja := centro + Vector2.from_angle(a) * radio * 0.5
		lienzo.draw_circle(hoja, radio * 0.5, COLOR_CONTORNO)
		lienzo.draw_circle(hoja, radio * 0.42, DORADO)
	lienzo.draw_circle(centro, radio * 0.18, DORADO.lightened(0.4))


static func _contorno(lienzo: CanvasItem, forma: PackedVector2Array, grosor: float) -> void:
	var cerrado := forma.duplicate()
	cerrado.append(forma[0])
	lienzo.draw_polyline(cerrado, COLOR_CONTORNO, grosor, true)
