extends RefCounted

## Laminas vectoriales del motor `lienzo_libre` (docs/fichas/motor-lienzo-libre.md §3).
##
## Una lamina (pony, bandera, Torres del Paine, el ala de la nave...) llega en el JSON del nivel
## como una lista de REGIONES rellenables y DETALLES fijos, en coordenadas del lienzo (824x530):
##
##   {"id": "pony", "voz": "voces/...", "regiones": [...], "detalles": [...]}
##
## Region: {"id", "forma", ..., "sugerido": "#hex" (color de la tarjeta modelo), "inicial": "#hex"
## (color con que parte; por defecto blanco), "fija": true (no se rellena: fondo o decorado),
## "sin_contorno": true}. Formas:
## - "poligono": "puntos": [[x, y], ...] y opcional "suave": n (pasadas de Chaikin: curvas
##   organicas a partir de pocos puntos de control).
## - "elipse": "centro", "radios": [rx, ry], opcional "giro" (grados).
## - "circulo": "centro", "radio".
## - "rect": "rect": [x, y, ancho, alto], opcional "redondeo".
## - "estrella" / "corazon" / "gota" / "flor": "centro", "radio", opcional "giro".
## Detalle: {"tipo": "linea", "puntos", "grosor", "suave"} | {"tipo": "punto", "centro", "radio",
## "color"} | {"tipo": "ojo", "centro", "radio"} | {"tipo": "sonrisa", "centro", "radio"} |
## {"tipo": "rubor", "centro", "radio"}.
##
## Las mismas funciones dibujan la lamina en pantalla (vectorial, suavizada) y la rasterizan en una
## `Image` para guardar el PNG.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const Raster := preload("res://scripts/motores/lienzo_libre/rasterizador.gd")
const COLOR_CONTORNO := Color("#2B3350")
const COLOR_RUBOR := Color(1.0, 0.45, 0.6, 0.5)
const GROSOR_CONTORNO := 4.0


static func vec(valor, por_defecto := Vector2.ZERO) -> Vector2:
	if valor is Array and valor.size() >= 2:
		return Vector2(float(valor[0]), float(valor[1]))
	return por_defecto


## Contorno de una region en coordenadas del lienzo.
static func poligono(region: Dictionary) -> PackedVector2Array:
	var forma := str(region.get("forma", "poligono"))
	var centro := vec(region.get("centro", null))
	var giro := deg_to_rad(float(region.get("giro", 0.0)))
	var puntos := PackedVector2Array()
	match forma:
		"elipse":
			var radios := vec(region.get("radios", null), Vector2(50, 50))
			puntos = elipse(centro, radios.x, radios.y, 48)
		"circulo":
			var r := float(region.get("radio", 50.0))
			puntos = elipse(centro, r, r, 48)
		"rect":
			var datos: Array = region.get("rect", [0, 0, 100, 100])
			var rect := Rect2(float(datos[0]), float(datos[1]), float(datos[2]), float(datos[3]))
			puntos = rectangulo(rect, float(region.get("redondeo", 0.0)))
			centro = rect.get_center()
		"estrella", "corazon", "gota", "flor":
			puntos = Figura.poligono(forma, centro, float(region.get("radio", 50.0)))
		_:
			for p in region.get("puntos", []):
				puntos.append(vec(p))
			var pasadas := int(region.get("suave", 0))
			for i in pasadas:
				puntos = chaikin(puntos, true)
	if giro != 0.0:
		var girados := PackedVector2Array()
		for p in puntos:
			girados.append(centro + (p - centro).rotated(giro))
		puntos = girados
	return puntos


static func elipse(centro: Vector2, rx: float, ry: float, lados := 40) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		var a := TAU * i / lados
		puntos.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	return puntos


static func rectangulo(rect: Rect2, redondeo: float) -> PackedVector2Array:
	if redondeo <= 0.0:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var r := minf(redondeo, minf(rect.size.x, rect.size.y) / 2.0)
	var puntos := PackedVector2Array()
	var esquinas := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI / 2.0],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI / 2.0],
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
	]
	for esquina in esquinas:
		for k in 7:
			var a: float = esquina[1] + PI / 2.0 * k / 6.0
			puntos.append(esquina[0] + Vector2(cos(a), sin(a)) * r)
	return puntos


static func chaikin(puntos: PackedVector2Array, cerrado: bool) -> PackedVector2Array:
	var n := puntos.size()
	if n < 3:
		return puntos
	var salida := PackedVector2Array()
	var total := n if cerrado else n - 1
	if not cerrado:
		salida.append(puntos[0])
	for i in total:
		var a := puntos[i]
		var b := puntos[(i + 1) % n]
		salida.append(a.lerp(b, 0.25))
		salida.append(a.lerp(b, 0.75))
	if not cerrado:
		salida.append(puntos[n - 1])
	return salida


static func puntos_linea(detalle: Dictionary) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for p in detalle.get("puntos", []):
		puntos.append(vec(p))
	for i in int(detalle.get("suave", 0)):
		puntos = chaikin(puntos, false)
	return puntos


## Prepara una lamina del JSON: poligonos calculados una vez y colores iniciales.
static func preparar(datos: Dictionary) -> Dictionary:
	var lamina := datos.duplicate(true)
	var regiones: Array = []
	for region: Dictionary in datos.get("regiones", []):
		var r := region.duplicate(true)
		r["poligono"] = poligono(region)
		r["color"] = Color(str(region.get("inicial", "#FFFFFF")))
		regiones.append(r)
	lamina["regiones"] = regiones
	return lamina


## Region rellenable que esta bajo `punto` (la de mas arriba), o -1.
static func region_en(lamina: Dictionary, punto: Vector2) -> int:
	var regiones: Array = lamina.get("regiones", [])
	for i in range(regiones.size() - 1, -1, -1):
		var region: Dictionary = regiones[i]
		if Geometry2D.is_point_in_polygon(punto, region["poligono"]):
			if bool(region.get("fija", false)):
				if bool(region.get("tapa", false)):
					return -1
				continue
			return i
	return -1


# ---------------------------------------------------------------------------
# Dibujo en pantalla (vectorial)
# ---------------------------------------------------------------------------

static func dibujar(lienzo: CanvasItem, lamina: Dictionary, desfase := Vector2.ZERO, escala := 1.0, alfa := 1.0) -> void:
	for region: Dictionary in lamina.get("regiones", []):
		var puntos := _transformar(region["poligono"], desfase, escala)
		if puntos.size() < 3:
			continue
		var color: Color = region["color"]
		lienzo.draw_colored_polygon(puntos, Color(color, color.a * alfa))
		if not bool(region.get("sin_contorno", false)):
			var cerrado := puntos.duplicate()
			cerrado.append(puntos[0])
			lienzo.draw_polyline(cerrado, Color(COLOR_CONTORNO, alfa), maxf(1.5, GROSOR_CONTORNO * escala), true)
	dibujar_detalles(lienzo, lamina, desfase, escala, alfa)


static func dibujar_detalles(lienzo: CanvasItem, lamina: Dictionary, desfase := Vector2.ZERO, escala := 1.0, alfa := 1.0) -> void:
	for detalle: Dictionary in lamina.get("detalles", []):
		var tipo := str(detalle.get("tipo", "linea"))
		var centro := desfase + vec(detalle.get("centro", null)) * escala
		var radio := float(detalle.get("radio", 10.0)) * escala
		var color := Color(str(detalle.get("color", "#2B3350")))
		color.a *= alfa
		match tipo:
			"linea":
				var puntos := _transformar(puntos_linea(detalle), desfase, escala)
				if puntos.size() >= 2:
					lienzo.draw_polyline(puntos, color, maxf(1.5, float(detalle.get("grosor", GROSOR_CONTORNO)) * escala), true)
			"punto":
				lienzo.draw_circle(centro, radio, color)
			"ojo":
				lienzo.draw_colored_polygon(elipse(centro, radio * 0.75, radio), Color(COLOR_CONTORNO, alfa))
				lienzo.draw_circle(centro + Vector2(-radio * 0.25, -radio * 0.4), radio * 0.3, Color(1, 1, 1, alfa))
			"sonrisa":
				lienzo.draw_arc(centro, radio, PI * 0.15, PI * 0.85, 16, Color(COLOR_CONTORNO, alfa), maxf(1.5, 4.0 * escala), true)
			"rubor":
				lienzo.draw_colored_polygon(elipse(centro, radio, radio * 0.6), Color(COLOR_RUBOR, COLOR_RUBOR.a * alfa))


static func _transformar(puntos: PackedVector2Array, desfase: Vector2, escala: float) -> PackedVector2Array:
	if desfase == Vector2.ZERO and escala == 1.0:
		return puntos
	var salida := PackedVector2Array()
	for p in puntos:
		salida.append(desfase + p * escala)
	return salida


# ---------------------------------------------------------------------------
# Rasterizado (para guardar el PNG)
# ---------------------------------------------------------------------------

static func rasterizar(imagen: Image, lamina: Dictionary) -> void:
	for region: Dictionary in lamina.get("regiones", []):
		var puntos: PackedVector2Array = region["poligono"]
		var color: Color = region["color"]
		Raster.rellenar_poligono(imagen, puntos, color, color.a < 1.0)
		if not bool(region.get("sin_contorno", false)):
			Raster.trazar(imagen, puntos, GROSOR_CONTORNO, COLOR_CONTORNO, true)
	for detalle: Dictionary in lamina.get("detalles", []):
		var tipo := str(detalle.get("tipo", "linea"))
		var centro := vec(detalle.get("centro", null))
		var radio := float(detalle.get("radio", 10.0))
		match tipo:
			"linea":
				Raster.trazar(imagen, puntos_linea(detalle), float(detalle.get("grosor", GROSOR_CONTORNO)), Color(str(detalle.get("color", "#2B3350"))))
			"punto":
				Raster.rellenar_poligono(imagen, elipse(centro, radio, radio), Color(str(detalle.get("color", "#2B3350"))))
			"ojo":
				Raster.rellenar_poligono(imagen, elipse(centro, radio * 0.75, radio), COLOR_CONTORNO)
				Raster.rellenar_poligono(imagen, elipse(centro + Vector2(-radio * 0.25, -radio * 0.4), radio * 0.3, radio * 0.3), Color.WHITE)
			"sonrisa":
				var arco := PackedVector2Array()
				for k in 13:
					var a := lerpf(PI * 0.15, PI * 0.85, k / 12.0)
					arco.append(centro + Vector2(cos(a), sin(a)) * radio)
				Raster.trazar(imagen, arco, 4.0, COLOR_CONTORNO)
			"rubor":
				Raster.rellenar_poligono(imagen, elipse(centro, radio, radio * 0.6), COLOR_RUBOR, true)
