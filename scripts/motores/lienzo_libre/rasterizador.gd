extends RefCounted

## Rasterizado en CPU para el motor `lienzo_libre` (docs/fichas/motor-lienzo-libre.md §4).
##
## Todo lo que el nino pinta vive en una `Image` (no en miles de nodos): cada trazo estampa una
## brocha con `Image.blend_rect`, que es codigo nativo y rinde bien en tablet. Aca estan las piezas
## que no trae Godot: rellenar un poligono (barrido por filas), trazar un contorno y fabricar
## brochas y calcomanias. Como no dependen del renderer, el dibujo se puede componer y guardar como
## PNG igual en la tablet que en un arnes QA headless.
##
## Uso: `const Raster := preload("res://scripts/motores/lienzo_libre/rasterizador.gd")`.

const COLOR_CONTORNO := Color("#2B3350")


## Rellena un poligono (regla par-impar) con `color`. Con `mezclar`, respeta la transparencia del
## color sobre lo que ya habia; si no, reemplaza los pixeles (mas rapido).
static func rellenar_poligono(imagen: Image, puntos: PackedVector2Array, color: Color, mezclar := false) -> void:
	var n := puntos.size()
	if n < 3:
		return
	var alto := imagen.get_height()
	var ancho := imagen.get_width()
	var y_min := INF
	var y_max := -INF
	for p in puntos:
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
	var fila: Image = null
	if mezclar:
		fila = Image.create(ancho, 1, false, Image.FORMAT_RGBA8)
		fila.fill(color)
	var desde := clampi(floori(y_min), 0, alto - 1)
	var hasta := clampi(ceili(y_max), 0, alto - 1)
	var cortes: Array[float] = []
	for y in range(desde, hasta + 1):
		var sy := y + 0.5
		cortes.clear()
		for i in n:
			var a := puntos[i]
			var b := puntos[(i + 1) % n]
			if (a.y <= sy) != (b.y <= sy):
				cortes.append(a.x + (sy - a.y) * (b.x - a.x) / (b.y - a.y))
		cortes.sort()
		var j := 0
		while j + 1 < cortes.size():
			var x0 := clampi(ceili(cortes[j] - 0.5), 0, ancho)
			var x1 := clampi(floori(cortes[j + 1] - 0.5), -1, ancho - 1)
			if x1 >= x0:
				if mezclar:
					imagen.blend_rect(fila, Rect2i(0, 0, x1 - x0 + 1, 1), Vector2i(x0, y))
				else:
					imagen.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), color)
			j += 2


## Brocha redonda con borde suavizado: `dureza` 1 = borde nitido (1 px de suavizado), 0 = difusa.
static func brocha(color: Color, radio: float, dureza := 1.0) -> Image:
	var lado := int(ceil(radio * 2.0)) + 2
	var imagen := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(lado, lado) / 2.0
	var borde := lerpf(radio * 0.6, 1.0, dureza)
	for y in lado:
		for x in lado:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(centro)
			var alfa := clampf((radio - d) / borde + 0.5, 0.0, 1.0)
			if alfa > 0.0:
				imagen.set_pixel(x, y, Color(color, color.a * alfa))
	return imagen


## Estampa `sello` centrado en `centro` (mezcla alfa).
static func estampar(imagen: Image, sello: Image, centro: Vector2) -> void:
	var tam := sello.get_size()
	var destino := Vector2i(roundi(centro.x - tam.x / 2.0), roundi(centro.y - tam.y / 2.0))
	imagen.blend_rect(sello, Rect2i(Vector2i.ZERO, tam), destino)


## Traza una linea gruesa estampando una brocha a lo largo de los puntos.
static func trazar(imagen: Image, puntos: PackedVector2Array, grosor: float, color: Color, cerrado := false) -> void:
	if puntos.size() < 2:
		return
	var pincel := brocha(color, grosor / 2.0)
	var paso := maxf(1.0, grosor * 0.3)
	var total := puntos.size() if cerrado else puntos.size() - 1
	for i in total:
		var a := puntos[i]
		var b := puntos[(i + 1) % puntos.size()]
		var largo := a.distance_to(b)
		var pasos := maxi(1, ceili(largo / paso))
		for k in pasos:
			estampar(imagen, pincel, a.lerp(b, float(k) / pasos))


## Calcomania (sello de dinosaurio, auto, corazon...) a partir de partes vectoriales, con
## supermuestreo x3 para que salga suavizada. Cada parte: {"poligono": PackedVector2Array en
## coordenadas -1..1, "color": Color, "contorno": bool}. `tamano` en pixeles del lienzo.
static func calcomania(partes: Array, tamano: int, grosor_contorno := 4.0) -> Image:
	var escala := 3
	var lado := tamano * escala
	var imagen := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var radio := lado / 2.0 * 0.92
	var centro := Vector2(lado, lado) / 2.0
	for parte: Dictionary in partes:
		var puntos := PackedVector2Array()
		for p: Vector2 in parte["poligono"]:
			puntos.append(centro + p * radio)
		if parte.has("color"):
			rellenar_poligono(imagen, puntos, parte["color"], (parte["color"] as Color).a < 1.0)
		if parte.get("contorno", true):
			trazar(imagen, puntos, grosor_contorno * escala, COLOR_CONTORNO, true)
		if parte.has("linea"):
			var linea := PackedVector2Array()
			for p: Vector2 in parte["linea"]:
				linea.append(centro + p * radio)
			trazar(imagen, linea, grosor_contorno * escala, COLOR_CONTORNO, false)
	imagen.resize(tamano, tamano, Image.INTERPOLATE_BILINEAR)
	return imagen
