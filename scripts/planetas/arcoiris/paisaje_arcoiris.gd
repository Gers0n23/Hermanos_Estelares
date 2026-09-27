extends Control

## Paisaje del mapa del Planeta Arcoíris: una isla de dulces vista desde arriba, como un mapa de
## verdad (pedido del PO 27-Sep-2026: "que se parezca más a un mapa real del planeta, con cosas
## relacionadas con dulces, memorable para los niños").
##
## La isla es una galleta gigante con glaseado de menta, en un mar de leche de frutilla. Un río de
## chocolate la cruza bajo un puente de bastón de caramelo, y el camino entre zonas es de chispitas
## de colores. Cada zona tiene un hito dulce que se reconoce de lejos:
##   1 Claro del Trébol ....... frutilla gigante sobre un trébol de gomita (rojo)
##   2 Charcos Saltarines ..... gelatina de limón que tiembla, con charcos de miel (amarillo)
##   3 Bosque de Chupetines ... tres chupetines de espiral (azul)
##   4 Islotes Flotantes ...... malvaviscos que flotan sobre una laguna de soda (verde y naranja)
##   5 Cima del Arcoíris ...... torta de tres pisos con cereza y arcoíris (violeta y brillo)
##
## El planeta "perdió sus colores" (ficha de zonas §1): las zonas dormidas se ven grises, las
## abiertas a medio color y las completadas con todo su color. El resto de la isla gana color a
## medida que vuelven las bandas del arcoíris.
##
## Contrato con `mapa_planeta.gd` (que no conoce este planeta; solo lee la ruta en el JSON):
##   actualizar(zonas)                              estado de cada zona (redibuja la isla)
##   dibujar_camino(lienzo, zonas, centros)         camino de chispitas entre zonas
##   dibujar_hito(lienzo, i, zona, centro, tiempo)  hito de la zona; devuelve dónde va su carita

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const RUTA_NAVE := "res://assets/sprites/nave/nave_estrella.png"
const CONTORNO := Color("#2B3350")
const GRIS := Color("#B9B4C9")
const CENTRO_ISLA := Vector2(640, 360)
const RADIOS_ISLA := Vector2(610, 300)
const MAR := Color("#F7B3CF")
const MAR_HONDO := Color("#EE93BA")
const GALLETA := Color("#E9B872")
const CHISPA_CHOCOLATE := Color("#7A4128")
const GLASEADO := Color("#CFF3C4")
const CHOCOLATE := Color("#8A4B2A")
const CHOCOLATE_CLARO := Color("#B26E43")
const CHISPITAS := [Color("#FF6B6B"), Color("#FF9F4A"), Color("#FFCB3D"), Color("#7DD87A"), Color("#4A8BE0"), Color("#B48CE8"), Color("#FFFFFF")]
## Río de chocolate: nace en una fuente arriba y baja al mar pasando entre la zona 2 y la 3
## (por el punto medio de su camino, donde está el puente de bastón de caramelo).
const PUNTOS_RIO := [Vector2(565, 96), Vector2(520, 185), Vector2(538, 290), Vector2(530, 380), Vector2(478, 500), Vector2(490, 700)]
const ZONA_DEL_PUENTE := 2
## Plataforma donde queda estacionada la nave de los hermanos (junto al Claro, la zona 1).
const PLATAFORMA_NAVE := Vector2(165, 158)
## Manchas de color del suelo de cada zona: [centro, radios, color].
const REGIONES := [
	[Vector2(185, 345), Vector2(150, 105), Color("#A6E394")],
	[Vector2(395, 250), Vector2(135, 92), Color("#FFE58A")],
	[Vector2(645, 350), Vector2(140, 100), Color("#B5CCFF")],
	[Vector2(870, 290), Vector2(118, 60), Color("#7FE3E0")],
	[Vector2(1085, 250), Vector2(150, 100), Color("#DCC6FF")],
]

var _zonas: Array = []
var _viveza := 0.7
var _tiempo := 0.0
var _isla := PackedVector2Array()
var _glaseado := PackedVector2Array()
var _rio := PackedVector2Array()
var _largo_rio := 0.0
var _chispitas: Array = []
var _animado: Control
var _nave: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_isla = _contorno_isla(1.0, 0.0)
	_glaseado = _contorno_isla(0.955, 0.011)
	_rio = _suavizar(PackedVector2Array(PUNTOS_RIO), 3)
	for k in range(1, _rio.size()):
		_largo_rio += _rio[k - 1].distance_to(_rio[k])
	_sembrar_chispitas()
	if ResourceLoader.exists(RUTA_NAVE):
		_nave = load(RUTA_NAVE)
	_animado = Control.new()
	_animado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_animado)
	_animado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_animado.draw.connect(_dibujar_animado)


func _process(delta: float) -> void:
	_tiempo += delta
	_animado.queue_redraw()


## Guarda el estado de las zonas (abierta/completa) y redibuja la isla con los colores recuperados.
func actualizar(zonas: Array) -> void:
	_zonas = zonas
	var bandas := {}
	for zona: Dictionary in zonas:
		if zona["completa"]:
			for banda in zona["datos"].get("bandas", []):
				bandas[banda] = true
	_viveza = 0.7 + 0.3 * bandas.size() / 7.0
	queue_redraw()


# ---------------------------------------------------------------------------
# Color: lo dormido es gris, lo abierto a medio color, lo completado con todo su color
# ---------------------------------------------------------------------------

func _tono(color: Color, intensidad: float) -> Color:
	var gris := GRIS.lerp(Color.WHITE, clampf(color.get_luminance() - 0.35, 0.0, 0.6))
	return Color(gris.lerp(color, intensidad), color.a)


func _intensidad_zona(i: int) -> float:
	if i >= _zonas.size():
		return _viveza
	var zona: Dictionary = _zonas[i]
	if zona["completa"]:
		return 1.0
	return 0.62 if zona["abierta"] else 0.1


# ---------------------------------------------------------------------------
# La isla (capa fija: solo se redibuja cuando cambia el estado)
# ---------------------------------------------------------------------------

func _draw() -> void:
	var v := _viveza
	draw_rect(Rect2(Vector2.ZERO, size), _tono(MAR, v))
	_dibujar_olas(v)
	# galleta con chispas de chocolate y glaseado de menta con borde festoneado
	draw_colored_polygon(_desplazar(_isla, Vector2(0, 10)), Color(_tono(MAR_HONDO, v), 0.9))
	draw_colored_polygon(_isla, _tono(GALLETA, v))
	Figura.contornear(self, _isla, 5.0)
	for k in 70:
		var angulo := TAU * k / 70.0 + 0.03 * sin(k * 7.0)
		var punto := _punto_isla(angulo, 0.978)
		draw_colored_polygon(_elipse(punto, 5.0, 3.5, angulo), _tono(CHISPA_CHOCOLATE, v))
	draw_colored_polygon(_glaseado, _tono(GLASEADO, v))
	draw_polyline(_cerrar(_glaseado), Color(_tono(Color("#8FCB86"), v), 0.9), 3.0, true)
	for i in REGIONES.size():
		_dibujar_region(i)
	_dibujar_rio(v)
	for chispita: Dictionary in _chispitas:
		_dibujar_chispita(self, chispita["pos"], chispita["angulo"], 11.0, 5.0, _tono(chispita["color"], v))
	_dibujar_decorados(v)


func _dibujar_olas(v: float) -> void:
	var ola := Color(_tono(Color("#FFE3EF"), v), 0.85)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 60:
		var punto := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if Geometry2D.is_point_in_polygon(punto, _contorno_isla(1.06, 0.0)):
			continue
		draw_arc(punto, 10.0, PI * 1.15, PI * 1.85, 8, ola, 3.0, true)
		draw_arc(punto + Vector2(18, 0), 10.0, PI * 1.15, PI * 1.85, 8, ola, 3.0, true)


func _dibujar_region(i: int) -> void:
	var datos: Array = REGIONES[i]
	var centro: Vector2 = datos[0]
	var radios: Vector2 = datos[1]
	var intensidad := _intensidad_zona(i)
	var color := _tono(datos[2], intensidad)
	match i:
		3:
			# laguna de soda con burbujitas en la orilla
			draw_colored_polygon(_elipse(centro, radios.x + 10.0, radios.y + 8.0), _tono(Color("#FFFFFF"), intensidad))
			draw_colored_polygon(_elipse(centro, radios.x, radios.y), color)
			draw_colored_polygon(_elipse(centro + Vector2(0, 8), radios.x * 0.7, radios.y * 0.55), _tono(Color("#5FCFD0"), intensidad))
			for k in 18:
				var angulo := TAU * k / 18.0
				draw_circle(centro + Vector2(cos(angulo) * (radios.x + 6.0), sin(angulo) * (radios.y + 5.0)), 4.0 + (k % 3), Color(1, 1, 1, 0.9))
		4:
			# la montaña de helado donde se apoya la torta de la cima
			draw_colored_polygon(_elipse(centro + Vector2(0, 30), radios.x, radios.y * 0.55), Color(color, 0.7))
			var ladera := PackedVector2Array()
			for p in [Vector2(-165, 92), Vector2(-110, 44), Vector2(-55, 10), Vector2(0, -2), Vector2(55, 10), Vector2(110, 44), Vector2(165, 92)]:
				ladera.append(centro + p)
			ladera = _suavizar(ladera, 3)
			draw_colored_polygon(ladera, _tono(Color("#C9A8F5"), intensidad))
			draw_polyline(ladera, CONTORNO, 4.0, true)
			# nieve de crema batida que chorrea por la cumbre
			var crema := PackedVector2Array()
			for p in ladera:
				if absf(p.x - centro.x) <= 84.0:
					crema.append(p)
			var borde := crema.size()
			for n in borde:
				var p: Vector2 = crema[borde - 1 - n]
				crema.append(p + Vector2(0, 12.0 + 9.0 * absf(sin(n * 0.55))))
			draw_colored_polygon(crema, _tono(Color("#FFF8EE"), maxf(intensidad, 0.5)))
		_:
			draw_colored_polygon(_elipse(centro, radios.x, radios.y), Color(color, 0.8))
			draw_colored_polygon(_elipse(centro + Vector2(0, 6), radios.x * 0.8, radios.y * 0.75), Color(color.darkened(0.04), 0.7))
	if i == 0:
		for p in [Vector2(80, 300), Vector2(290, 300), Vector2(110, 410)]:
			_trebol(self, p, 9.0, _tono(Color("#5BBF62"), intensidad))
	elif i == 1:
		for p in [Vector2(305, 300), Vector2(468, 180)]:
			_charco(self, p, Vector2(24, 9), _tono(Color("#FFB938"), intensidad))
	elif i == 2:
		for p in [Vector2(560, 300), Vector2(725, 300), Vector2(598, 262), Vector2(700, 262)]:
			_chupetin(self, p, 12.0, _tono(Color("#8FB4FF"), intensidad), 0.0, 30.0)


func _dibujar_rio(v: float) -> void:
	# fuente de chocolate donde nace el río
	draw_colored_polygon(_elipse(_rio[0] + Vector2(0, 4), 34, 18), _tono(CHOCOLATE, v).darkened(0.15))
	draw_polyline(_rio, _tono(CHOCOLATE, v).darkened(0.2), 40.0, true)
	draw_polyline(_rio, _tono(CHOCOLATE, v), 32.0, true)
	draw_polyline(_desplazar(_rio, Vector2(-6, 0)), Color(_tono(CHOCOLATE_CLARO, v), 0.8), 6.0, true)
	draw_colored_polygon(_elipse(_rio[0], 30, 15), _tono(CHOCOLATE, v))
	draw_arc(_rio[0], 16.0, PI * 1.1, PI * 1.9, 10, _tono(CHOCOLATE_CLARO, v), 4.0, true)


func _dibujar_decorados(v: float) -> void:
	for datos in [[Vector2(390, 140), Color("#FF6B6B")], [Vector2(335, 412), Color("#B48CE8")], [Vector2(762, 178), Color("#FFCB3D")],
			[Vector2(985, 375), Color("#FF9F4A")], [Vector2(1222, 300), Color("#7DD87A")], [Vector2(722, 440), Color("#FF6B6B")]]:
		_gomita(self, datos[0], 20.0, _tono(datos[1], v))
	for datos in [[Vector2(250, 205), 0.15], [Vector2(1000, 140), -0.2], [Vector2(420, 428), 0.1], [Vector2(1236, 405), -0.1]]:
		_baston(self, datos[0], 44.0, datos[1], v)
	_casita_cupcake(Vector2(300, 150), v)
	# la nave de los hermanos, estacionada en su plataforma junto al Claro
	var plataforma := PLATAFORMA_NAVE
	var pista := _elipse(plataforma + Vector2(0, 26), 58, 15)
	draw_colored_polygon(pista, _tono(Color("#FFF8EE"), v))
	draw_polyline(_cerrar(pista), CONTORNO, 3.0, true)
	for k in 5:
		draw_circle(plataforma + Vector2(-40 + k * 20, 26), 3.5, _tono(Color("#FFCB3D"), v))
	if _nave != null:
		draw_texture_rect(_nave, Rect2(plataforma + Vector2(-54, -44), Vector2(108, 72)), false)
	# en el mar: una dona salvavidas y un terrón de azúcar
	_dona(Vector2(1150, 60), 26.0, v)
	_terron(Vector2(1238, 170), v)
	_terron(Vector2(30, 150), v)


# ---------------------------------------------------------------------------
# Capa animada: nubes de algodón de azúcar, chocolate que corre y un gusanito de gomita
# ---------------------------------------------------------------------------

func _dibujar_animado() -> void:
	var lienzo := _animado
	var v := _viveza
	# el chocolate corre río abajo
	for k in 14:
		var punto := _punto_rio(fposmod(_tiempo * 26.0 + k * _largo_rio / 14.0, _largo_rio))
		lienzo.draw_colored_polygon(_elipse(punto, 7.0, 3.0), Color(_tono(CHOCOLATE_CLARO, v), 0.9))
	# gusanito de gomita nadando en el mar
	var cabeza := Vector2(180 + sin(_tiempo * 0.5) * 30.0, 38)
	for k in range(6, -1, -1):
		var p := cabeza + Vector2(-k * 13.0, sin(_tiempo * 4.0 - k * 0.9) * 6.0)
		lienzo.draw_circle(p, 9.0, _tono([Color("#FF6B6B"), Color("#FFCB3D"), Color("#7DD87A")][k % 3], v))
	Figura.dibujar_cara(lienzo, cabeza + Vector2(0, -1), 16.0, true)
	# nubes de algodón de azúcar que pasan despacito
	for datos in [[110.0, 0.0, Color("#FFD1E6")], [205.0, 520.0, Color("#D6E6FF")], [120.0, 980.0, Color("#E7D9FF")]]:
		var x := fposmod(float(datos[1]) + _tiempo * 9.0, size.x + 260.0) - 130.0
		_nube(lienzo, Vector2(x, float(datos[0])), Color(_tono(datos[2], v), 0.55))


# ---------------------------------------------------------------------------
# Camino de chispitas y puente de bastón de caramelo
# ---------------------------------------------------------------------------

func dibujar_camino(lienzo: Control, zonas: Array, centros: Array) -> void:
	for i in range(1, zonas.size()):
		if zonas[i]["secreta"] and not zonas[i]["abierta"]:
			continue
		var a: Vector2 = centros[i - 1]
		var b: Vector2 = centros[i]
		var medio := (a + b) / 2.0 + Vector2(0, 40.0 if i % 2 == 0 else -30.0)
		var abierta: bool = zonas[i]["abierta"]
		if i == ZONA_DEL_PUENTE:
			# el puente va justo donde el camino cruza el río de chocolate
			var cruce := 0.5
			for n in range(10, 91):
				if _distancia_al_rio(_bezier(a, medio, b, n / 100.0)) < _distancia_al_rio(_bezier(a, medio, b, cruce)):
					cruce = n / 100.0
			var sobre_rio := _bezier(a, medio, b, cruce)
			_puente(lienzo, sobre_rio, (_bezier(a, medio, b, cruce + 0.02) - sobre_rio).angle(), abierta)
		var pasos := int(a.distance_to(b) / 20.0)
		for k in range(4, pasos - 3):
			var t := k / float(pasos)
			var punto := _bezier(a, medio, b, t)
			var tangente := (_bezier(a, medio, b, t + 0.01) - punto).angle()
			var color: Color = CHISPITAS[(k + i * 2) % 6] if abierta else Color(1, 1, 1, 0.45)
			_dibujar_chispita(lienzo, punto, tangente + (0.5 if k % 2 == 0 else -0.5), 16.0, 8.0, color, abierta)


func _puente(lienzo: CanvasItem, centro: Vector2, angulo: float, abierto: bool) -> void:
	var largo := 62.0
	var eje := Vector2.from_angle(angulo)
	var normal := eje.orthogonal()
	var tablas := PackedVector2Array([centro - eje * largo - normal * 16, centro + eje * largo - normal * 16, centro + eje * largo + normal * 16, centro - eje * largo + normal * 16])
	lienzo.draw_colored_polygon(tablas, Color("#FFE9C9") if abierto else Color("#E6E1EC"))
	Figura.contornear(lienzo, tablas, 3.0)
	for lado in [-1.0, 1.0]:
		# barandas de bastón de caramelo a rayas
		var n := 10
		for k in n:
			var p1: Vector2 = centro + eje * lerpf(-largo, largo, k / float(n)) + normal * 18.0 * lado
			var p2: Vector2 = centro + eje * lerpf(-largo, largo, (k + 1) / float(n)) + normal * 18.0 * lado
			lienzo.draw_line(p1, p2, (Color("#FF5A6E") if k % 2 == 0 else Color.WHITE) if abierto else (GRIS if k % 2 == 0 else Color.WHITE), 8.0, true)
		for extremo in [-1.0, 1.0]:
			lienzo.draw_circle(centro + eje * largo * extremo + normal * 18.0 * lado, 7.0, Color("#FF5A6E") if abierto else GRIS)


# ---------------------------------------------------------------------------
# Hitos de cada zona
# ---------------------------------------------------------------------------

## Dibuja el hito de la zona `i` alrededor de `c` (centro del nodo tocable) y devuelve
## {"cara": posición, "escala": ancho} para que el mapa le ponga la carita (dormida o despierta).
func dibujar_hito(lienzo: Control, i: int, zona: Dictionary, c: Vector2, tiempo: float) -> Dictionary:
	var k := 1.0 if zona["completa"] else (0.62 if zona["abierta"] else 0.12)
	var despierta: bool = zona["abierta"]
	match i:
		0:
			return _hito_frutilla(lienzo, c, k, tiempo, despierta)
		1:
			return _hito_gelatina(lienzo, c, k, tiempo, despierta)
		2:
			return _hito_chupetines(lienzo, c, k, tiempo, despierta)
		3:
			return _hito_islotes(lienzo, c, k, tiempo, despierta)
		4:
			return _hito_torta(lienzo, c, k, tiempo, bool(zona["completa"]))
	return {}


func _hito_frutilla(lienzo: Control, c: Vector2, k: float, t: float, despierta: bool) -> Dictionary:
	var verde := _tono(Color("#5BBF62"), k)
	# trébol de gomita bajo la frutilla
	_trebol(lienzo, c + Vector2(0, 30), 30.0, verde)
	var salto := absf(sin(t * 2.4)) * 4.0 if despierta else 0.0
	var centro := c + Vector2(0, -6 - salto)
	var cuerpo := PackedVector2Array()
	for n in 40:
		var angulo := TAU * n / 40.0
		var p := Vector2(cos(angulo), sin(angulo))
		cuerpo.append(centro + Vector2(p.x * 42.0 * (1.0 - 0.42 * maxf(0.0, p.y)), p.y * 44.0 + (6.0 if p.y > 0 else 0.0)))
	lienzo.draw_colored_polygon(_desplazar(cuerpo, Vector2(4, 6)), Color(CONTORNO, 0.18))
	lienzo.draw_colored_polygon(cuerpo, _tono(Color("#FF5A6E"), k))
	Figura.contornear(lienzo, cuerpo, 4.0)
	for fila in 3:
		for col in 4 - fila:
			var semilla := centro + Vector2((col - (3 - fila) / 2.0) * 16.0, 24.0 + fila * 10.0 - 34.0 + fila * 6.0)
			if fila == 0 and col in [1, 2]:
				continue  # deja lugar a la carita
			lienzo.draw_colored_polygon(_elipse(semilla + Vector2(0, 26), 2.6, 4.0), _tono(Color("#FFE38A"), k))
	lienzo.draw_circle(centro + Vector2(-20, -20), 7.0, Color(1, 1, 1, 0.55))
	var hojas := PackedVector2Array()
	for n in 10:
		var angulo := PI + PI * n / 9.0
		var radio := 26.0 if n % 2 == 0 else 12.0
		hojas.append(centro + Vector2(0, -36) + Vector2(cos(angulo) * radio, sin(angulo) * radio * 0.55))
	lienzo.draw_colored_polygon(hojas, verde)
	Figura.contornear(lienzo, hojas, 3.0)
	lienzo.draw_line(centro + Vector2(0, -44), centro + Vector2(4, -58), verde.darkened(0.2), 6.0, true)
	for lado in [-1.0, 1.0]:
		_gomita(lienzo, c + Vector2(lado * 62.0, 34.0), 15.0, _tono(Color("#FF6B6B"), k))
	return {"cara": centro + Vector2(0, -6), "escala": 46.0}


func _hito_gelatina(lienzo: Control, c: Vector2, k: float, t: float, despierta: bool) -> Dictionary:
	_charco(lienzo, c + Vector2(-60, 42), Vector2(26, 10), _tono(Color("#FFB938"), k))
	_charco(lienzo, c + Vector2(62, 38), Vector2(22, 9), _tono(Color("#FFB938"), k))
	lienzo.draw_colored_polygon(_elipse(c + Vector2(0, 44), 60, 15), _tono(Color("#E8F4FF"), k))
	lienzo.draw_arc(c + Vector2(0, 44), 60.0, 0.0, PI, 20, CONTORNO, 3.0, true)
	# la gelatina tiembla (se estira desde la base, como si saltara)
	var temblor := sin(t * 7.0) * (0.05 if despierta else 0.0)
	var escala := Vector2(1.0 + temblor, 1.0 - temblor)
	var base := c + Vector2(0, 42)
	var perfil := PackedVector2Array()
	perfil.append(Vector2(-50, 0))
	perfil.append(Vector2(-44, -48))
	for bulto in 3:
		var x0 := -38.0 + bulto * 26.0
		for n in 9:
			var angulo := PI + PI * n / 8.0
			perfil.append(Vector2(x0 + 12.0 + cos(angulo) * 13.0, -62.0 + sin(angulo) * 13.0))
	perfil.append(Vector2(44, -48))
	perfil.append(Vector2(50, 0))
	var cuerpo := PackedVector2Array()
	for p in perfil:
		cuerpo.append(base + p * escala)
	var amarillo := _tono(Color("#FFD23D"), k)
	lienzo.draw_colored_polygon(cuerpo, amarillo)
	var banda := PackedVector2Array([base + Vector2(-50, 0) * escala, base + Vector2(-48, -16) * escala, base + Vector2(48, -16) * escala, base + Vector2(50, 0) * escala])
	lienzo.draw_colored_polygon(banda, amarillo.darkened(0.12))
	Figura.contornear(lienzo, cuerpo, 4.0)
	lienzo.draw_line(base + Vector2(-34, -40) * escala, base + Vector2(-30, -12) * escala, Color(1, 1, 1, 0.6), 7.0, true)
	lienzo.draw_circle(base + Vector2(-26, -60) * escala, 4.0, Color(1, 1, 1, 0.7))
	return {"cara": base + Vector2(4, -32) * escala, "escala": 44.0}


func _hito_chupetines(lienzo: Control, c: Vector2, k: float, t: float, despierta: bool) -> Dictionary:
	var vaiven := 3.0 if despierta else 0.0
	_chupetin(lienzo, c + Vector2(-52, 20), 24.0, _tono(Color("#6FD6E8"), k), sin(t * 1.6) * vaiven, 48.0)
	_chupetin(lienzo, c + Vector2(54, 22), 22.0, _tono(Color("#8E7CF0"), k), sin(t * 1.6 + 1.0) * vaiven, 46.0)
	# el chupetín grande del centro: anillos de color (sin espiral en el medio, ahí va su carita)
	var centro := c + Vector2(sin(t * 1.6 + 2.0) * vaiven, -14)
	lienzo.draw_line(centro + Vector2(0, 30), c + Vector2(0, 58), _tono(Color("#FFF8EE"), maxf(k, 0.6)), 9.0, true)
	lienzo.draw_line(centro + Vector2(0, 30), c + Vector2(0, 58), CONTORNO, 2.0, true)
	var azul := _tono(Color("#4A8BE0"), k)
	lienzo.draw_circle(centro + Vector2(4, 5), 40.0, Color(CONTORNO, 0.18))
	lienzo.draw_circle(centro, 40.0, azul)
	lienzo.draw_arc(centro, 31.0, 0.0, TAU, 40, _tono(Color("#FFFFFF"), k), 7.0, true)
	lienzo.draw_arc(centro, 20.0, 0.0, TAU, 40, azul.lightened(0.25), 4.0, true)
	lienzo.draw_arc(centro, 40.0, 0.0, TAU, 44, CONTORNO, 4.0, true)
	lienzo.draw_circle(centro + Vector2(-18, -20), 6.0, Color(1, 1, 1, 0.6))
	for p in [Vector2(-30, 56), Vector2(-14, 60), Vector2(18, 60), Vector2(32, 56)]:
		lienzo.draw_colored_polygon(PackedVector2Array([c + p + Vector2(-5, 0), c + p + Vector2(0, -14), c + p + Vector2(5, 0)]), _tono(Color("#7DD87A"), k))
	return {"cara": centro + Vector2(0, 2), "escala": 40.0}


func _hito_islotes(lienzo: Control, c: Vector2, k: float, t: float, despierta: bool) -> Dictionary:
	var flota := sin(t * 1.8) * (6.0 if despierta else 1.5)
	var flota_chico := sin(t * 1.8 + 1.7) * (6.0 if despierta else 1.5)
	# sombras sobre la laguna (más chicas cuando el islote sube)
	lienzo.draw_colored_polygon(_elipse(c + Vector2(-14, 52), 38.0 - flota, 8), Color(CONTORNO, 0.16))
	lienzo.draw_colored_polygon(_elipse(c + Vector2(50, 40), 20.0 - flota_chico * 0.5, 5), Color(CONTORNO, 0.14))
	# islote chico: rodaja de gomita de naranja sobre un malvavisco
	var chico := c + Vector2(50, -34 + flota_chico)
	_malvavisco(lienzo, chico, Vector2(30, 13), k)
	var rodaja := PackedVector2Array()
	for n in 13:
		var angulo := PI + PI * n / 12.0
		rodaja.append(chico + Vector2(0, -8) + Vector2(cos(angulo) * 22.0, sin(angulo) * 20.0))
	lienzo.draw_colored_polygon(rodaja, _tono(Color("#FF9F4A"), k))
	for n in 4:
		var angulo := PI + PI * (n + 0.5) / 4.0
		lienzo.draw_line(chico + Vector2(0, -10), chico + Vector2(0, -10) + Vector2.from_angle(angulo) * 16.0, _tono(Color("#FFD59E"), k), 3.0, true)
	Figura.contornear(lienzo, rodaja, 3.0)
	# islote grande: domo de gomita de menta sobre un malvavisco con cara
	var grande := c + Vector2(-14, 4 + flota)
	var domo := PackedVector2Array()
	for n in 17:
		var angulo := PI + PI * n / 16.0
		domo.append(grande + Vector2(0, -16) + Vector2(cos(angulo) * 44.0, sin(angulo) * 36.0))
	lienzo.draw_colored_polygon(domo, _tono(Color("#7DD87A"), k))
	Figura.contornear(lienzo, domo, 4.0)
	for p in [Vector2(-22, -30), Vector2(4, -42), Vector2(22, -26), Vector2(-4, -24)]:
		lienzo.draw_circle(grande + p, 3.0, Color(1, 1, 1, 0.8))
	_malvavisco(lienzo, grande + Vector2(0, 8), Vector2(52, 24), k)
	# gomita suelta que también flota
	_gomita(lienzo, c + Vector2(-66, -40 + flota_chico), 12.0, _tono(Color("#FF9F4A"), k))
	return {"cara": grande + Vector2(0, 10), "escala": 40.0}


func _hito_torta(lienzo: Control, c: Vector2, k: float, t: float, completa: bool) -> Dictionary:
	# arcoíris de la cima: vuelve entero cuando la zona está completa
	for n in 6:
		var color := _tono(Figura.COLORES_ARCOIRIS[n], k)
		lienzo.draw_arc(c + Vector2(0, 10), 76.0 - n * 7.0, PI, TAU, 36, Color(color, 0.95), 7.0, true)
	var pisos := [[Vector2(0, 40), Vector2(64, 18), Color("#B48CE8")], [Vector2(0, 8), Vector2(48, 16), Color("#F59AC4")], [Vector2(0, -20), Vector2(32, 14), Color("#B48CE8")]]
	for piso: Array in pisos:
		var centro: Vector2 = c + piso[0]
		var medio: Vector2 = piso[1]
		var caja := Rect2(centro - medio, medio * 2.0)
		lienzo.draw_rect(caja, _tono(piso[2], k))
		lienzo.draw_rect(caja, CONTORNO, false, 3.5)
		# glaseado que chorrea
		var glaseado := PackedVector2Array([centro + Vector2(-medio.x, -medio.y), centro + Vector2(medio.x, -medio.y)])
		var gotas := int(medio.x / 8.0)
		for n in gotas + 1:
			var x := medio.x - n * (medio.x * 2.0 / gotas)
			glaseado.append(centro + Vector2(x, -medio.y + (9.0 if n % 2 == 0 else 4.0)))
		lienzo.draw_colored_polygon(glaseado, _tono(Color("#FFF8EE"), maxf(k, 0.5)))
	for n in 5:
		lienzo.draw_circle(c + Vector2(-48 + n * 24, 50), 3.0, _tono(CHISPITAS[n], k))
	var cereza := c + Vector2(0, -44)
	lienzo.draw_line(cereza, cereza + Vector2(8, -16), _tono(Color("#5BBF62"), k), 3.0, true)
	lienzo.draw_circle(cereza, 10.0, _tono(Color("#FF3D5A"), k))
	lienzo.draw_arc(cereza, 10.0, 0.0, TAU, 20, CONTORNO, 3.0, true)
	lienzo.draw_circle(cereza + Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.8))
	if completa:
		for n in 4:
			var angulo := TAU * n / 4.0 + t * 0.8
			Figura.dibujar(lienzo, "estrella", Color("#FFE38A"), c + Vector2(0, -6) + Vector2.from_angle(angulo) * Vector2(86, 50), 9.0 + 2.0 * sin(t * 4.0 + n), false)
	return {"cara": c + Vector2(0, 40), "escala": 36.0}


# ---------------------------------------------------------------------------
# Dulces sueltos
# ---------------------------------------------------------------------------

func _gomita(lienzo: CanvasItem, base: Vector2, radio: float, color: Color) -> void:
	var domo := PackedVector2Array()
	for n in 15:
		var angulo := PI + PI * n / 14.0
		domo.append(base + Vector2(cos(angulo) * radio, sin(angulo) * radio * 1.15))
	lienzo.draw_colored_polygon(domo, color)
	Figura.contornear(lienzo, domo, 3.0)
	for p in [Vector2(-0.35, -0.5), Vector2(0.2, -0.75), Vector2(0.4, -0.3), Vector2(-0.1, -0.25)]:
		lienzo.draw_circle(base + p * radio, maxf(1.5, radio * 0.09), Color(1, 1, 1, 0.85))


func _baston(lienzo: CanvasItem, base: Vector2, alto: float, inclinacion: float, v: float) -> void:
	var eje := Vector2(0, -1).rotated(inclinacion)
	var puntos := PackedVector2Array()
	for n in 8:
		puntos.append(base + eje * alto * n / 7.0)
	var gancho := base + eje * alto + eje.orthogonal() * -10.0
	for n in 9:
		var angulo := eje.angle() + PI * n / 8.0 - PI
		puntos.append(gancho + Vector2.from_angle(angulo + PI) * 10.0)
	lienzo.draw_polyline(puntos, CONTORNO, 11.0, true)
	for n in puntos.size() - 1:
		lienzo.draw_line(puntos[n], puntos[n + 1], _tono(Color("#FF5A6E"), v) if n % 2 == 0 else Color.WHITE, 7.0, true)


func _chupetin(lienzo: CanvasItem, centro: Vector2, radio: float, color: Color, vaiven: float, palo: float) -> void:
	var disco := centro + Vector2(vaiven, -palo * 0.35)
	lienzo.draw_line(disco, centro + Vector2(0, palo * 0.6), Color("#FFF8EE"), maxf(4.0, radio * 0.22), true)
	lienzo.draw_circle(disco, radio, color)
	var espiral := PackedVector2Array()
	for n in 40:
		var angulo := n * 0.45
		espiral.append(disco + Vector2.from_angle(angulo) * radio * 0.92 * n / 40.0)
	lienzo.draw_polyline(espiral, Color(1, 1, 1, 0.9), maxf(2.0, radio * 0.16), true)
	lienzo.draw_arc(disco, radio, 0.0, TAU, 28, CONTORNO, maxf(2.0, radio * 0.12), true)


func _trebol(lienzo: CanvasItem, centro: Vector2, radio: float, color: Color) -> void:
	lienzo.draw_line(centro, centro + Vector2(radio * 0.5, radio * 1.1), color.darkened(0.2), maxf(2.0, radio * 0.18), true)
	for n in 3:
		var hoja := centro + Vector2.from_angle(-PI / 2.0 + TAU * n / 3.0) * radio * 0.62
		lienzo.draw_circle(hoja, radio * 0.62, color)
		lienzo.draw_arc(hoja, radio * 0.62, 0.0, TAU, 20, color.darkened(0.25), maxf(1.5, radio * 0.08), true)
	lienzo.draw_circle(centro, radio * 0.3, color.lightened(0.15))


func _charco(lienzo: CanvasItem, centro: Vector2, radios: Vector2, color: Color) -> void:
	lienzo.draw_colored_polygon(_elipse(centro, radios.x, radios.y), color)
	lienzo.draw_colored_polygon(_elipse(centro + Vector2(-radios.x * 0.3, -radios.y * 0.3), radios.x * 0.3, radios.y * 0.25), Color(1, 1, 1, 0.6))


func _malvavisco(lienzo: CanvasItem, centro: Vector2, medio: Vector2, k: float) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = _tono(Color("#FFF1F7"), maxf(k, 0.4))
	caja.border_color = CONTORNO
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(int(medio.y))
	caja.anti_aliasing = true
	lienzo.draw_style_box(caja, Rect2(centro - medio, medio * 2.0))
	lienzo.draw_line(centro + Vector2(-medio.x * 0.6, -medio.y * 0.5), centro + Vector2(medio.x * 0.2, -medio.y * 0.5), _tono(Color("#FFC3DC"), k), 3.0, true)


func _casita_cupcake(base: Vector2, v: float) -> void:
	# la casita de Coco: un cupcake con puerta y ventana
	var capacillo := PackedVector2Array([base + Vector2(-28, -34), base + Vector2(28, -34), base + Vector2(22, 0), base + Vector2(-22, 0)])
	draw_colored_polygon(_desplazar(capacillo, Vector2(4, 4)), Color(CONTORNO, 0.18))
	draw_colored_polygon(capacillo, _tono(Color("#4FC3F7"), v))
	for n in 5:
		var x := -20.0 + n * 10.0
		draw_line(base + Vector2(x * 1.25, -34), base + Vector2(x, 0), _tono(Color("#8ADCFB"), v), 3.0, true)
	Figura.contornear(self, capacillo, 3.0)
	var crema := PackedVector2Array()
	for n in 21:
		var angulo := PI + PI * n / 20.0
		var ondita := 1.0 + 0.08 * sin(n * 1.6)
		crema.append(base + Vector2(0, -34) + Vector2(cos(angulo) * 34.0, sin(angulo) * 34.0) * ondita)
	draw_colored_polygon(crema, _tono(Color("#FF9FC8"), v))
	Figura.contornear(self, crema, 3.0)
	for p in [Vector2(-16, -50), Vector2(6, -58), Vector2(18, -44), Vector2(-4, -42), Vector2(-22, -40)]:
		draw_line(base + p, base + p + Vector2(5, 2), _tono(CHISPITAS[int(p.x + 40) % 6], v), 3.0, true)
	draw_circle(base + Vector2(0, -70), 8.0, _tono(Color("#FF3D5A"), v))
	draw_arc(base + Vector2(0, -70), 8.0, 0.0, TAU, 16, CONTORNO, 2.5, true)
	var puerta := Rect2(base + Vector2(-7, -18), Vector2(14, 18))
	draw_rect(puerta, _tono(Color("#B26E43"), v))
	draw_rect(puerta, CONTORNO, false, 2.5)
	draw_circle(base + Vector2(-14, -48), 5.0, _tono(Color("#FFF3B0"), v))
	draw_arc(base + Vector2(-14, -48), 5.0, 0.0, TAU, 12, CONTORNO, 2.0, true)


func _dona(centro: Vector2, radio: float, v: float) -> void:
	draw_colored_polygon(_elipse(centro + Vector2(0, 5), radio, radio * 0.6), Color(_tono(MAR_HONDO, v), 0.9))
	draw_colored_polygon(_elipse(centro, radio, radio * 0.62), _tono(Color("#E9B872"), v))
	draw_colored_polygon(_elipse(centro + Vector2(0, -2), radio * 0.88, radio * 0.5), _tono(Color("#FF7FB6"), v))
	draw_colored_polygon(_elipse(centro + Vector2(0, -2), radio * 0.32, radio * 0.18), _tono(MAR, v))
	for n in 8:
		var angulo := TAU * n / 8.0
		var p := centro + Vector2(0, -2) + Vector2(cos(angulo) * radio * 0.6, sin(angulo) * radio * 0.34)
		_dibujar_chispita(self, p, angulo * 2.0, 6.0, 3.0, _tono(CHISPITAS[n % 6], v), false)
	draw_polyline(_cerrar(_elipse(centro, radio, radio * 0.62)), CONTORNO, 3.0, true)


func _terron(centro: Vector2, v: float) -> void:
	var cara_arriba := PackedVector2Array([centro + Vector2(-14, -10), centro + Vector2(4, -18), centro + Vector2(20, -10), centro + Vector2(2, -2)])
	var frente := PackedVector2Array([centro + Vector2(-14, -10), centro + Vector2(2, -2), centro + Vector2(2, 16), centro + Vector2(-14, 8)])
	var lado := PackedVector2Array([centro + Vector2(2, -2), centro + Vector2(20, -10), centro + Vector2(20, 8), centro + Vector2(2, 16)])
	draw_colored_polygon(cara_arriba, Color.WHITE)
	draw_colored_polygon(frente, _tono(Color("#F1ECFA"), v))
	draw_colored_polygon(lado, _tono(Color("#DCD3EE"), v))
	for forma in [cara_arriba, frente, lado]:
		Figura.contornear(self, forma, 2.5)


func _nube(lienzo: CanvasItem, centro: Vector2, color: Color) -> void:
	for p in [Vector2(-40, 6), Vector2(-16, -8), Vector2(12, -12), Vector2(38, 2), Vector2(0, 8)]:
		lienzo.draw_circle(centro + p, 24.0, color)


func _dibujar_chispita(lienzo: CanvasItem, centro: Vector2, angulo: float, largo: float, grosor: float, color: Color, contorno := false) -> void:
	var eje := Vector2.from_angle(angulo) * (largo - grosor) / 2.0
	if contorno:
		lienzo.draw_line(centro - eje, centro + eje, CONTORNO, grosor + 3.0, true)
		lienzo.draw_circle(centro - eje, (grosor + 3.0) / 2.0, CONTORNO)
		lienzo.draw_circle(centro + eje, (grosor + 3.0) / 2.0, CONTORNO)
	lienzo.draw_line(centro - eje, centro + eje, color, grosor, true)
	lienzo.draw_circle(centro - eje, grosor / 2.0, color)
	lienzo.draw_circle(centro + eje, grosor / 2.0, color)


# ---------------------------------------------------------------------------
# Geometría
# ---------------------------------------------------------------------------

func _radio_isla(angulo: float) -> float:
	return 1.0 + 0.05 * sin(3.0 * angulo + 1.0) + 0.035 * sin(5.0 * angulo + 2.0) + 0.02 * sin(9.0 * angulo + 0.5)


func _punto_isla(angulo: float, escala: float) -> Vector2:
	return CENTRO_ISLA + Vector2(cos(angulo) * RADIOS_ISLA.x, sin(angulo) * RADIOS_ISLA.y) * _radio_isla(angulo) * escala


func _contorno_isla(escala: float, feston: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for n in 240:
		var angulo := TAU * n / 240.0
		puntos.append(_punto_isla(angulo, escala + feston * sin(60.0 * angulo)))
	return puntos


func _sembrar_chispitas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 27
	var centros_libres: Array = []
	for region in REGIONES:
		centros_libres.append(region[0])
	centros_libres.append_array([PLATAFORMA_NAVE, Vector2(300, 130)])
	var intentos := 0
	while _chispitas.size() < 150 and intentos < 3000:
		intentos += 1
		var punto := Vector2(rng.randf_range(40, 1240), rng.randf_range(70, 660))
		if not Geometry2D.is_point_in_polygon(punto, _contorno_isla(0.93, 0.0)):
			continue
		var libre := true
		for centro: Vector2 in centros_libres:
			if punto.distance_to(centro) < 105.0:
				libre = false
				break
		if libre and _distancia_al_rio(punto) > 30.0:
			_chispitas.append({"pos": punto, "angulo": rng.randf_range(0, TAU), "color": CHISPITAS[rng.randi() % CHISPITAS.size()]})


func _distancia_al_rio(punto: Vector2) -> float:
	var minima := INF
	for n in range(1, _rio.size()):
		minima = minf(minima, punto.distance_to(Geometry2D.get_closest_point_to_segment(punto, _rio[n - 1], _rio[n])))
	return minima


func _punto_rio(distancia: float) -> Vector2:
	var recorrido := 0.0
	for n in range(1, _rio.size()):
		var tramo := _rio[n - 1].distance_to(_rio[n])
		if recorrido + tramo >= distancia:
			return _rio[n - 1].lerp(_rio[n], (distancia - recorrido) / maxf(tramo, 0.001))
		recorrido += tramo
	return _rio[_rio.size() - 1]


## Suavizado de Chaikin: esquinas redondeadas para el río.
func _suavizar(puntos: PackedVector2Array, pasadas: int) -> PackedVector2Array:
	var actual := puntos
	for _p in pasadas:
		var nuevo := PackedVector2Array([actual[0]])
		for n in actual.size() - 1:
			nuevo.append(actual[n].lerp(actual[n + 1], 0.25))
			nuevo.append(actual[n].lerp(actual[n + 1], 0.75))
		nuevo.append(actual[actual.size() - 1])
		actual = nuevo
	return actual


func _bezier(a: Vector2, control: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(control, t).lerp(control.lerp(b, t), t)


func _elipse(centro: Vector2, radio_x: float, radio_y: float, angulo := 0.0) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for n in 28:
		var a := TAU * n / 28.0
		puntos.append(centro + Vector2(cos(a) * radio_x, sin(a) * radio_y).rotated(angulo))
	return puntos


func _desplazar(forma: PackedVector2Array, desfase: Vector2) -> PackedVector2Array:
	var nueva := PackedVector2Array()
	for p in forma:
		nueva.append(p + desfase)
	return nueva


func _cerrar(forma: PackedVector2Array) -> PackedVector2Array:
	var cerrada := forma.duplicate()
	cerrada.append(forma[0])
	return cerrada
