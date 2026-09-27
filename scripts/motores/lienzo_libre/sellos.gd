extends RefCounted

## Sellos y calcomanias del motor `lienzo_libre`, dibujados en codigo con el estilo "peluche
## pintado" (contorno azul noche, formas redondas). Cada sello es una lista de partes vectoriales
## en coordenadas -1..1 que `rasterizador.gd` convierte en `Image` (se estampa en el dibujo y
## tambien sirve de icono de su boton). Mientras no existan los sprites finales de HE-13.
##
## Sellos: dino (Maxi), auto (Maxi), estrella, corazon, flor, luna, destello (brillo de Sofia) y
## pony (insignia de Sofia). El color principal lo elige el nino.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const Raster := preload("res://scripts/motores/lienzo_libre/rasterizador.gd")
const COLOR_CONTORNO := Color("#2B3350")
const TIPOS := ["dino", "auto", "estrella", "corazon", "flor", "luna", "destello", "pony"]


static func imagen(tipo: String, color: Color, tamano: int) -> Image:
	return Raster.calcomania(partes(tipo, color), tamano, maxf(2.0, tamano / 34.0))


static func partes(tipo: String, color: Color) -> Array:
	match tipo:
		"dino":
			return _dino(color)
		"auto":
			return _auto(color)
		"pony":
			return _pony(color)
		"destello":
			return [{"poligono": _destello(Vector2.ZERO, 1.0), "color": color}]
		_:
			var forma := Figura.poligono(tipo, Vector2.ZERO, 1.0)
			var lista: Array = [{"poligono": forma, "color": color}]
			var brillo := _elipse(Vector2(-0.32, -0.4), 0.18, 0.1)
			var dentro := Geometry2D.intersect_polygons(brillo, forma)
			if not dentro.is_empty():
				lista.append({"poligono": dentro[0], "color": Color(1, 1, 1, 0.55), "contorno": false})
			return lista


static func _dino(color: Color) -> Array:
	var cuerpo := _elipse(Vector2(-0.12, 0.12), 0.52, 0.38)
	var cabeza := _elipse(Vector2(0.52, -0.38), 0.36, 0.28)
	var cuello := PackedVector2Array([Vector2(0.05, -0.1), Vector2(0.32, -0.52), Vector2(0.62, -0.3), Vector2(0.38, 0.12)])
	var cola := _suave(PackedVector2Array([Vector2(-0.5, -0.05), Vector2(-0.8, 0.02), Vector2(-1.0, 0.3), Vector2(-0.72, 0.3), Vector2(-0.5, 0.36)]))
	var silueta := cuerpo
	for extra in [cabeza, cuello, cola]:
		silueta = _mayor(Geometry2D.merge_polygons(silueta, extra))
	var lista: Array = []
	for x in [-0.42, -0.18, 0.06]:
		lista.append({"poligono": PackedVector2Array([Vector2(x - 0.13, -0.12), Vector2(x, -0.42), Vector2(x + 0.13, -0.14)]), "color": color.darkened(0.25)})
	for x in [-0.36, 0.1]:
		lista.append({"poligono": _rect(Rect2(x - 0.11, 0.3, 0.22, 0.52), 0.08), "color": color.darkened(0.12)})
	lista.append({"poligono": silueta, "color": color})
	lista.append({"poligono": _elipse(Vector2(-0.05, 0.22), 0.3, 0.2), "color": color.lightened(0.45), "contorno": false})
	lista.append({"poligono": _elipse(Vector2(0.6, -0.46), 0.075, 0.09), "color": COLOR_CONTORNO, "contorno": false})
	lista.append({"poligono": _elipse(Vector2(0.58, -0.49), 0.025, 0.025), "color": Color.WHITE, "contorno": false})
	lista.append({"poligono": _elipse(Vector2(0.7, -0.3), 0.07, 0.045), "color": Color(1.0, 0.45, 0.6, 0.6), "contorno": false})
	lista.append({"poligono": PackedVector2Array(), "linea": PackedVector2Array([Vector2(0.62, -0.22), Vector2(0.72, -0.18), Vector2(0.84, -0.24)]), "contorno": false})
	return lista


static func _auto(color: Color) -> Array:
	var lista: Array = []
	lista.append({"poligono": _suave(PackedVector2Array([Vector2(-0.52, -0.08), Vector2(-0.3, -0.56), Vector2(0.34, -0.56), Vector2(0.58, -0.08)])), "color": color.lightened(0.15)})
	lista.append({"poligono": _rect(Rect2(-0.96, -0.12, 1.92, 0.56), 0.2), "color": color})
	lista.append({"poligono": _rect(Rect2(-0.4, -0.46, 0.32, 0.32), 0.06), "color": Color("#CFF1FF")})
	lista.append({"poligono": _rect(Rect2(0.0, -0.46, 0.4, 0.32), 0.06), "color": Color("#CFF1FF")})
	lista.append({"poligono": _elipse(Vector2(0.84, 0.06), 0.09, 0.09), "color": Color("#FFE38A")})
	for x in [-0.52, 0.52]:
		lista.append({"poligono": _elipse(Vector2(x, 0.48), 0.26, 0.26), "color": Color("#3A3F58")})
		lista.append({"poligono": _elipse(Vector2(x, 0.48), 0.11, 0.11), "color": Color("#D7DCEA")})
	lista.append({"poligono": PackedVector2Array(), "linea": PackedVector2Array([Vector2(0.62, 0.22), Vector2(0.72, 0.28), Vector2(0.84, 0.22)]), "contorno": false})
	return lista


static func _pony(color: Color) -> Array:
	var lista: Array = []
	lista.append({"poligono": _elipse(Vector2.ZERO, 1.0, 1.0), "color": color})
	lista.append({"poligono": _elipse(Vector2.ZERO, 0.84, 0.84), "color": color.lightened(0.55), "contorno": false})
	var cabeza := _suave(PackedVector2Array([
		Vector2(-0.2, -0.52), Vector2(0.12, -0.5), Vector2(0.45, -0.18), Vector2(0.66, 0.12),
		Vector2(0.62, 0.34), Vector2(0.3, 0.38), Vector2(0.02, 0.2), Vector2(-0.08, 0.7),
		Vector2(-0.5, 0.7), Vector2(-0.44, 0.0), Vector2(-0.38, -0.36)]))
	var oreja := PackedVector2Array([Vector2(-0.18, -0.44), Vector2(-0.06, -0.8), Vector2(0.1, -0.44)])
	var crin := _suave(PackedVector2Array([
		Vector2(-0.32, -0.58), Vector2(0.02, -0.64), Vector2(-0.1, -0.4), Vector2(-0.4, -0.3),
		Vector2(-0.52, 0.1), Vector2(-0.46, 0.66), Vector2(-0.72, 0.5), Vector2(-0.78, 0.0), Vector2(-0.6, -0.42)]))
	lista.append({"poligono": oreja, "color": Color.WHITE})
	lista.append({"poligono": cabeza, "color": Color.WHITE})
	lista.append({"poligono": crin, "color": Color("#FF7EB6")})
	lista.append({"poligono": _elipse(Vector2(0.18, -0.12), 0.07, 0.09), "color": COLOR_CONTORNO, "contorno": false})
	lista.append({"poligono": _elipse(Vector2(0.16, -0.15), 0.025, 0.025), "color": Color.WHITE, "contorno": false})
	lista.append({"poligono": _elipse(Vector2(0.5, 0.22), 0.035, 0.035), "color": COLOR_CONTORNO, "contorno": false})
	lista.append({"poligono": _elipse(Vector2(0.28, 0.1), 0.08, 0.05), "color": Color(1.0, 0.45, 0.6, 0.6), "contorno": false})
	return lista


static func _destello(centro: Vector2, radio: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 8:
		var a := -PI / 2.0 + i * PI / 4.0
		puntos.append(centro + Vector2.from_angle(a) * radio * (0.98 if i % 2 == 0 else 0.26))
	return puntos


static func _elipse(centro: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		puntos.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	return puntos


static func _rect(rect: Rect2, r: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var esquinas := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI / 2.0],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI / 2.0],
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
	]
	for esquina in esquinas:
		for k in 5:
			var a: float = esquina[1] + PI / 2.0 * k / 4.0
			puntos.append(esquina[0] + Vector2(cos(a), sin(a)) * r)
	return puntos


## Dos pasadas de Chaikin: curvas suaves desde pocos puntos de control.
static func _suave(puntos: PackedVector2Array) -> PackedVector2Array:
	for pasada in 2:
		var salida := PackedVector2Array()
		for i in puntos.size():
			var a := puntos[i]
			var b := puntos[(i + 1) % puntos.size()]
			salida.append(a.lerp(b, 0.25))
			salida.append(a.lerp(b, 0.75))
		puntos = salida
	return puntos


static func _mayor(poligonos: Array) -> PackedVector2Array:
	var mejor := PackedVector2Array()
	var mejor_area := -1.0
	for p: PackedVector2Array in poligonos:
		var caja := Rect2(p[0], Vector2.ZERO)
		for q in p:
			caja = caja.expand(q)
		if caja.get_area() > mejor_area:
			mejor_area = caja.get_area()
			mejor = p
	return mejor
