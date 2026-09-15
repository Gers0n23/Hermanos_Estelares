extends Control

## Capa de dibujo del motor "encajar": escenario opcional (jardin de Nicole), siluetas de los huecos
## y resaltados (objetivo actual de Brote, pista de Maxi, hueco sobre el que se arrastra).
## Retos de Sofia (v3): modelo a color de la copia de memoria, cortina con que Coco lo tapa y el
## tablero de cuadraditos del marco de pentominos.
## No recibe toques. Lee el estado que le deja el motor en cada `queue_redraw()`.

const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_HUECO := Color(0.17, 0.2, 0.36, 0.42)
const COLOR_BORDE := Color(1, 1, 1, 0.9)
const DORADO := Color("#FFCB3D")

## Array de figuras (Dictionary con "huecos", "silueta_unida", "union") que arma el motor.
var figuras: Array = []
var guia_color := false
## Rect de la escena en pantalla y su descripcion ({} = sin escenario, solo la mesa).
var zona := Rect2()
var escena: Dictionary = {}
var hueco_objetivo = null
var hueco_pista = null
var hueco_cercano = null
## Copia de memoria: mientras es true se ve el modelo armado a color, con sus lineas por dentro.
var modelo_visible := false
## 0 = sin cortina, 1 = la cortina tapa toda la figura (animacion de Coco tapando el modelo).
var cortina := 0.0
## Marco de pentominos: {"origen": Vector2, "lado": float, "celdas": Array[Vector2i]} o {}.
var marco: Dictionary = {}

var _tiempo := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_tiempo += delta
	if hueco_objetivo != null or hueco_pista != null or cortina > 0.0:
		queue_redraw()


func _draw() -> void:
	if not escena.is_empty():
		_dibujar_escena()
	elif zona.size != Vector2.ZERO:
		# Mesa translucida: separa las siluetas de las islas con forma del fondo del planeta.
		var mesa := Geo.redondeado("rectangulo", Geo.contorno("rectangulo", zona.size.x, zona.size.y), 90.0, 90.0)
		mesa = Geo.desplazado(mesa, zona.get_center())
		draw_colored_polygon(mesa, Color(1.0, 0.97, 0.93, 0.26))
		var cerrada := mesa.duplicate()
		cerrada.append(mesa[0])
		draw_polyline(cerrada, Color(1, 1, 1, 0.55), 4.0, true)
	if not marco.is_empty():
		_dibujar_marco()
	for figura in figuras:
		if modelo_visible:
			_dibujar_modelo(figura)
		elif figura.get("silueta_unida", false):
			for contorno in figura.get("union", []):
				draw_colored_polygon(contorno, COLOR_HUECO)
				Geo.contorno_punteado(self, contorno, COLOR_BORDE, 5.0)
		else:
			for hueco in figura["huecos"]:
				_dibujar_hueco(hueco)
	for hueco in [hueco_cercano, hueco_pista, hueco_objetivo]:
		if hueco != null and hueco["pieza"] == null:
			_resaltar(hueco, hueco == hueco_cercano)
	if cortina > 0.0:
		_dibujar_cortina()


func _dibujar_hueco(hueco: Dictionary) -> void:
	var dibujo: PackedVector2Array = hueco["dibujo"]
	if hueco.get("opcional", false):
		# El tesoro escondido apenas se insinua: dorado muy suave, sin exigir nada.
		draw_colored_polygon(dibujo, Color(DORADO, 0.22))
		Geo.contorno_punteado(self, dibujo, Color(DORADO, 0.85), 4.0, 10.0, 9.0)
		return
	var relleno := Color(hueco["color"], 0.42) if guia_color else COLOR_HUECO
	draw_colored_polygon(dibujo, relleno)
	Geo.contorno_punteado(self, dibujo, COLOR_BORDE, 5.0)


## Modelo de la copia de memoria: cada pieza pintada en su color y en su lugar.
func _dibujar_modelo(figura: Dictionary) -> void:
	for hueco in figura["huecos"]:
		if hueco["pieza"] != null:
			continue
		Geo.pintar(self, hueco["dibujo"], hueco["color"], 40.0)


func _resaltar(hueco: Dictionary, suave: bool) -> void:
	var intensidad := 0.45 if suave else 0.4 + 0.35 * absf(sin(_tiempo * 4.0))
	for aura in Geometry2D.offset_polygon(hueco["dibujo"], 10.0, Geometry2D.JOIN_ROUND):
		Geo.contorno_punteado(self, aura, Color(DORADO, intensidad + 0.2), 7.0, 22.0, 6.0)
	draw_colored_polygon(hueco["dibujo"], Color(DORADO, intensidad * 0.45))


## Tablero del marco: cuadraditos claros con su cuadricula y el borde del marco bien marcado.
func _dibujar_marco() -> void:
	var origen: Vector2 = marco["origen"]
	var lado: float = marco["lado"]
	var cuadros: Array = []
	for celda: Vector2i in marco["celdas"]:
		var rect := Rect2(origen + Vector2(celda) * lado, Vector2.ONE * lado)
		draw_rect(rect, Color(0.17, 0.2, 0.36, 0.45))
		draw_rect(rect.grow(-1.5), Color(1, 1, 1, 0.35), false, 2.0)
		cuadros.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	for contorno in Geo.unir(cuadros):
		Geo.contorno_punteado(self, contorno, COLOR_BORDE, 5.0)


## Cortina de Coco: franjas arcoiris que bajan sobre la figura (tapa el modelo sin asustar).
func _dibujar_cortina() -> void:
	var alto := zona.size.y * cortina
	var franja := zona.size.y / Figura.COLORES_ARCOIRIS.size()
	for i in Figura.COLORES_ARCOIRIS.size():
		var y0 := zona.position.y + i * franja
		if y0 > zona.position.y + alto:
			break
		var y1 := minf(y0 + franja, zona.position.y + alto)
		var puntos := PackedVector2Array()
		for k in 25:
			var x := zona.position.x + zona.size.x * k / 24.0
			puntos.append(Vector2(x, y0 + sin(k * 0.8 + _tiempo * 3.0) * 4.0))
		for k in range(24, -1, -1):
			var x := zona.position.x + zona.size.x * k / 24.0
			puntos.append(Vector2(x, y1 + sin(k * 0.8 + _tiempo * 3.0) * 4.0))
		draw_colored_polygon(puntos, Color(Figura.COLORES_ARCOIRIS[i], 0.96))


## Jardin de "Completa una escena" (Nicole, zona 5): cielo, loma, flores y decorados fijos.
func _dibujar_escena() -> void:
	var cielo := Geo.redondeado("rectangulo", Geo.contorno("rectangulo", zona.size.x, zona.size.y), 80.0, 80.0)
	cielo = Geo.desplazado(cielo, zona.get_center())
	draw_colored_polygon(cielo, Color("#BDEBFA"))
	var suelo_y := zona.position.y + float(escena.get("suelo_y", zona.size.y * 0.72))
	var loma := PackedVector2Array()
	for i in 21:
		var x := zona.position.x + zona.size.x * i / 20.0
		loma.append(Vector2(x, suelo_y + sin(i / 20.0 * PI * 2.0) * 10.0))
	loma.append(zona.end)
	loma.append(Vector2(zona.position.x, zona.end.y))
	for trozo in Geometry2D.intersect_polygons(loma, cielo):
		draw_colored_polygon(trozo, Color("#8FD989"))
	for nube in [Vector2(0.18, 0.12), Vector2(0.52, 0.2)]:
		var c: Vector2 = zona.position + zona.size * nube
		for desfase in [Vector2(-34, 6), Vector2(0, -8), Vector2(36, 6)]:
			draw_circle(c + desfase, 30.0, Color(1, 1, 1, 0.9))
	for decorado in escena.get("decorados", []):
		var base := Geo.contorno(str(decorado.get("forma", "rectangulo")), float(decorado.get("ancho", 20)), float(decorado.get("alto", 20)))
		var centro := zona.position + Vector2(float(decorado.get("x", 0)), float(decorado.get("y", 0)))
		var dibujo := Geo.transformado(base, float(decorado.get("rotacion", 0)), centro)
		Geo.pintar(self, dibujo, Color(str(decorado.get("color", "#FFFFFF"))), 30.0)
	for i in 7:
		var c := Vector2(zona.position.x + 40.0 + i * (zona.size.x - 80.0) / 6.0, suelo_y + 60.0 + (i % 2) * 70.0)
		Figura.dibujar(self, "flor", Figura.COLORES_ARCOIRIS[i % Figura.COLORES_ARCOIRIS.size()], c, 16.0, false)
	Figura.contornear(self, cielo, 5.0)
