extends RefCounted

## Geometria de las formas del motor "encajar" (docs/fichas/motor-encajar.md §3).
##
## Toda forma se define por su nombre y la caja que ocupa sin rotar (`ancho` x `alto`, en px de la
## pantalla base 1280x720), centrada en el origen. Con eso se construyen tanto la silueta (hueco)
## como la pieza, y se decide si una pieza calza en un hueco comparando AREAS de los dos poligonos
## ya rotados: asi cualquier simetria (un cuadrado girado 90°, un circulo girado lo que sea, un
## rectangulo de 90x150 girado que equivale a uno de 150x90) se resuelve sola, sin tablas por forma.
##
## Uso: `const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")`.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")

const COLOR_CONTORNO := Color("#2B3350")
## Formas que ya dibuja `figura_vectorial.gd` (con su propio redondeo): se reutilizan escaladas.
const FORMAS_FIGURA := ["estrella", "corazon", "gota", "luna", "flor"]
const FORMAS := ["circulo", "ovalo", "cuadrado", "rectangulo", "triangulo", "triangulo_rect", "rombo", "trapecio", "semicirculo", "paralelogramo", "estrella", "corazon", "gota", "luna", "flor"]
## Diferencia de area tolerada para decir que dos poligonos son "la misma forma en el mismo lugar".
const TOLERANCIA_CALCE := 0.1


## Contorno sin redondear, centrado en el origen y sin rotar.
static func contorno(forma: String, ancho: float, alto: float) -> PackedVector2Array:
	var mx := ancho / 2.0
	var my := alto / 2.0
	var puntos := PackedVector2Array()
	match forma:
		"cuadrado", "rectangulo":
			puntos = PackedVector2Array([Vector2(-mx, -my), Vector2(mx, -my), Vector2(mx, my), Vector2(-mx, my)])
		"triangulo":
			puntos = PackedVector2Array([Vector2(0, -my), Vector2(mx, my), Vector2(-mx, my)])
		"triangulo_rect":
			# Angulo recto abajo a la izquierda (◣). Girado 90° queda ◤, 180° ◥ y 270° ◢.
			puntos = PackedVector2Array([Vector2(-mx, -my), Vector2(mx, my), Vector2(-mx, my)])
		"rombo":
			puntos = PackedVector2Array([Vector2(0, -my), Vector2(mx, 0), Vector2(0, my), Vector2(-mx, 0)])
		"trapecio":
			puntos = PackedVector2Array([Vector2(-mx * 0.6, -my), Vector2(mx * 0.6, -my), Vector2(mx, my), Vector2(-mx, my)])
		"semicirculo":
			for i in 25:
				var angulo := PI + PI * i / 24.0
				puntos.append(Vector2(cos(angulo) * mx, my + sin(angulo) * alto))
		"paralelogramo":
			var inclinacion := minf(alto, mx)
			puntos = PackedVector2Array([Vector2(-mx + inclinacion, -my), Vector2(mx, -my), Vector2(mx - inclinacion, my), Vector2(-mx, my)])
		_:
			if forma in FORMAS_FIGURA:
				# figura_vectorial trabaja en radios; a escala 100 para que el recorte sea preciso.
				for p in Figura.poligono(forma, Vector2.ZERO, 100.0):
					puntos.append(Vector2(p.x / 100.0 * mx, p.y / 100.0 * my))
			else:
				for i in 48:
					var angulo := TAU * i / 48.0
					puntos.append(Vector2(cos(angulo) * mx, sin(angulo) * my))
	return puntos


## Contorno de un poliominó (pentominós de Sofía): `celdas` = [[columna, fila], ...] de lado `lado`.
## Se recorre el borde de las celdas (sin agujeros), centrado en el centro de su caja y sin rotar.
static func contorno_poliomino(celdas: Array, lado: float) -> PackedVector2Array:
	var aristas := {}
	var max_c := 0
	var max_f := 0
	for celda in celdas:
		var c := int(celda[0])
		var f := int(celda[1])
		max_c = maxi(max_c, c + 1)
		max_f = maxi(max_f, f + 1)
		for arista in [[Vector2i(c, f), Vector2i(c + 1, f)], [Vector2i(c + 1, f), Vector2i(c + 1, f + 1)],
				[Vector2i(c + 1, f + 1), Vector2i(c, f + 1)], [Vector2i(c, f + 1), Vector2i(c, f)]]:
			var inversa := [arista[1], arista[0]]
			if aristas.has(inversa):
				aristas.erase(inversa)
			else:
				aristas[arista] = true
	var siguiente := {}
	for arista in aristas:
		siguiente[arista[0]] = arista[1]
	if siguiente.is_empty():
		return PackedVector2Array()
	var inicio: Vector2i = siguiente.keys()[0]
	var recorrido: Array[Vector2i] = [inicio]
	var actual: Vector2i = siguiente[inicio]
	while actual != inicio and recorrido.size() <= siguiente.size():
		recorrido.append(actual)
		actual = siguiente[actual]
	var centro := Vector2(max_c, max_f) * lado / 2.0
	var puntos := PackedVector2Array()
	for i in recorrido.size():
		var previo := recorrido[i - 1]
		var punto := recorrido[i]
		var proximo := recorrido[(i + 1) % recorrido.size()]
		if (punto - previo) != (proximo - punto):
			puntos.append(Vector2(punto) * lado - centro)
	return puntos


## Espejo horizontal (x -> -x) conservando el sentido de giro del contorno.
static func espejado(base: PackedVector2Array) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in range(base.size() - 1, -1, -1):
		puntos.append(Vector2(-base[i].x, base[i].y))
	return puntos


## Contorno girado `grados` (sentido horario en pantalla) y trasladado a `centro`.
static func transformado(base: PackedVector2Array, grados: float, centro := Vector2.ZERO) -> PackedVector2Array:
	var angulo := deg_to_rad(grados)
	var puntos := PackedVector2Array()
	for p in base:
		puntos.append(p.rotated(angulo) + centro)
	return puntos


## Version "peluche" para dibujar: esquinas redondeadas proporcionales a la forma.
static func redondeado(forma: String, base: PackedVector2Array, ancho: float, alto: float) -> PackedVector2Array:
	if forma in FORMAS_FIGURA or forma in ["circulo", "ovalo"]:
		return base
	var radio := minf(ancho, alto) * (0.07 if forma in ["triangulo", "triangulo_rect", "trapecio", "paralelogramo"] else 0.12)
	var adentro := Geometry2D.offset_polygon(base, -radio, Geometry2D.JOIN_MITER)
	if adentro.is_empty():
		return base
	var afuera := Geometry2D.offset_polygon(mayor(adentro), radio, Geometry2D.JOIN_ROUND)
	return base if afuera.is_empty() else mayor(afuera)


## 0 = identicos, 1 = no se tocan. Compara area comun contra el mayor de los dos.
static func diferencia(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var area_mayor := maxf(absf(area(a)), absf(area(b)))
	if area_mayor <= 0.0:
		return 1.0
	var comun := 0.0
	for trozo in Geometry2D.intersect_polygons(a, b):
		comun += absf(area(trozo))
	return clampf(1.0 - comun / area_mayor, 0.0, 1.0)


static func calzan(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	return diferencia(a, b) <= TOLERANCIA_CALCE


static func area(forma: PackedVector2Array) -> float:
	var suma := 0.0
	for i in forma.size():
		var a := forma[i]
		var b := forma[(i + 1) % forma.size()]
		suma += a.x * b.y - b.x * a.y
	return suma * 0.5


static func centroide(forma: PackedVector2Array) -> Vector2:
	var area_total := area(forma)
	if absf(area_total) < 0.001:
		var suma := Vector2.ZERO
		for p in forma:
			suma += p
		return suma / maxf(1.0, forma.size())
	var c := Vector2.ZERO
	for i in forma.size():
		var a := forma[i]
		var b := forma[(i + 1) % forma.size()]
		var cruz := a.x * b.y - b.x * a.y
		c += (a + b) * cruz
	return c / (6.0 * area_total)


static func caja(forma: PackedVector2Array) -> Rect2:
	if forma.is_empty():
		return Rect2()
	var rect := Rect2(forma[0], Vector2.ZERO)
	for p in forma:
		rect = rect.expand(p)
	return rect


## Distancia de un punto al poligono (0 si esta adentro).
static func distancia(punto: Vector2, forma: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(punto, forma):
		return 0.0
	var minima := INF
	for i in forma.size():
		var cercano := Geometry2D.get_closest_point_to_segment(punto, forma[i], forma[(i + 1) % forma.size()])
		minima = minf(minima, punto.distance_to(cercano))
	return minima


static func mayor(poligonos: Array) -> PackedVector2Array:
	var mejor := PackedVector2Array()
	var mejor_area := -1.0
	for p in poligonos:
		var a := absf(area(p))
		if a > mejor_area:
			mejor_area = a
			mejor = p
	return mejor


## Une varios poligonos que se tocan en una sola silueta (figuras "sin lineas por dentro").
## Devuelve todos los contornos exteriores resultantes (normalmente uno).
static func unir(poligonos: Array) -> Array:
	var grupos: Array = []
	for p in poligonos:
		var crecido := Geometry2D.offset_polygon(p, 1.5, Geometry2D.JOIN_MITER)
		var actual: PackedVector2Array = mayor(crecido) if not crecido.is_empty() else p
		var restantes: Array = []
		for existente in grupos:
			var union := Geometry2D.merge_polygons(existente, actual)
			var exterior := mayor(union)
			var sentido := Geometry2D.is_polygon_clockwise(exterior)
			var exteriores := 0
			for trozo in union:
				if Geometry2D.is_polygon_clockwise(trozo) == sentido:
					exteriores += 1
			if exteriores == 1:
				actual = exterior  # se tocaban: quedan fundidos en uno (los agujeros se ignoran)
			else:
				restantes.append(existente)
		restantes.append(actual)
		grupos = restantes
	return grupos


static func elipse(centro: Vector2, radio_x: float, radio_y: float, lados := 24) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		var angulo := TAU * i / lados
		puntos.append(centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y))
	return puntos


static func desplazado(forma: PackedVector2Array, desfase: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for p in forma:
		puntos.append(p + desfase)
	return puntos


## Pinta un poligono con el estilo "peluche pintado" de figura_vectorial: sombra, volumen,
## brillo, contorno azul noche. `referencia` ~ radio visual de la forma (grosor del trazo).
static func pintar(lienzo: CanvasItem, forma: PackedVector2Array, relleno: Color, referencia: float) -> void:
	if forma.size() < 3:
		return
	var trazo := clampf(referencia * 0.075, 2.5, 6.0)
	var caja_forma := caja(forma)
	lienzo.draw_colored_polygon(desplazado(forma, Vector2(0, referencia * 0.08)), Color(COLOR_CONTORNO, 0.22))
	lienzo.draw_colored_polygon(forma, relleno)
	for trozo in Geometry2D.clip_polygons(forma, desplazado(forma, Vector2(-referencia * 0.07, -referencia * 0.13))):
		if trozo.size() >= 3:
			lienzo.draw_colored_polygon(trozo, relleno.darkened(0.16))
	var brillo := elipse(caja_forma.position + caja_forma.size * Vector2(0.3, 0.26), referencia * 0.2, referencia * 0.12)
	for trozo in Geometry2D.intersect_polygons(brillo, forma):
		if trozo.size() >= 3:
			lienzo.draw_colored_polygon(trozo, Color(1, 1, 1, 0.55))
	Figura.contornear(lienzo, forma, trazo)


## Linea punteada cerrada alrededor de un poligono (siluetas de los huecos).
static func contorno_punteado(lienzo: CanvasItem, forma: PackedVector2Array, color: Color, grosor: float, trazo := 16.0, espacio := 10.0) -> void:
	if forma.size() < 2:
		return
	var avance := 0.0
	var dibujando := true
	var limite := trazo
	for i in forma.size():
		var a := forma[i]
		var b := forma[(i + 1) % forma.size()]
		var largo := a.distance_to(b)
		var recorrido := 0.0
		while recorrido < largo:
			var paso := minf(limite - avance, largo - recorrido)
			var p0 := a.lerp(b, recorrido / largo)
			var p1 := a.lerp(b, (recorrido + paso) / largo)
			if dibujando:
				lienzo.draw_line(p0, p1, color, grosor, true)
			recorrido += paso
			avance += paso
			if avance >= limite - 0.001:
				avance = 0.0
				dibujando = not dibujando
				limite = trazo if dibujando else espacio
