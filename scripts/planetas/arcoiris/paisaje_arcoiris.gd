extends Control

## Paisaje del mapa del Planeta Arcoíris visto desde el suelo (maqueta aprobada por el PO el
## 17-Oct-2026). Reemplaza a la isla-galleta vista desde arriba (27-Sep-2026): el PO pidió que el
## mapa se parezca al planeta de los conceptos (`assets/generadas/conceptos_planeta1/`: colinas
## pastel, árboles-chupetín, islotes-trébol con tierra de chocolate, cielo lila con nubes) y que use
## el lenguaje visual del menú de planetas (volumen con brillo, píldoras, ruta de puntitos dorados,
## lo dormido en gris).
##
## El arte es SVG generado por `herramientas/generar_mapa_arcoiris.py` (`assets/sprites/planetas/
## arcoiris/mapa/`). Capas, de atrás hacia adelante: cielo, arcoíris (lo pinta el núcleo en
## `capa_arcoiris()`), nubes que se mecen, tierra. Cada zona es un lugar del paisaje:
##   1 Claro del Trébol ....... frutilla sobre un trébol gigante en la pradera (rojo)
##   2 Charcos Saltarines ..... gelatina en un charco rosado, en la cima de la colina amarilla (amarillo)
##   3 Bosque de Chupetines ... chupetines de espiral en la pradera (azul)
##   4 Islotes Flotantes ...... malvavisco sobre un islote-trébol que flota (verde y naranja)
##   5 Cima del Arcoíris ...... torta de tres pisos en el cerro del fondo, entre neblina (violeta y brillo)
##
## El planeta "perdió sus colores" (ficha de zonas §1): el paisaje gana color con cada banda que
## vuelve (shader `viveza`), y las zonas dormidas se dibujan en su versión gris.
##
## Contrato con `mapa_planeta.gd` (que no conoce este planeta; solo lee la ruta en el JSON):
##   actualizar(zonas)                              estado de cada zona (color del paisaje)
##   dibujar_camino(lienzo, zonas, centros)         ruta de puntitos dorados entre zonas
##   dibujar_hito(lienzo, i, zona, centro, tiempo)  hito de la zona; devuelve dónde va su carita
##   capa_arcoiris() / geometria_arcoiris()         dónde y cómo pinta el núcleo el arcoíris del cielo

const CARPETA := "res://assets/sprites/planetas/arcoiris/mapa/"
const SHADER_VIVEZA := "res://assets/shaders/viveza.gdshader"
const LADO_HITO := 180.0
## Carita de cada hito (centro y ancho en la caja de 180x180; el núcleo la dibuja despierta o dormida).
const CARAS := [[Vector2(90, 86), 44.0], [Vector2(90, 86), 44.0], [Vector2(90, 66), 36.0], [Vector2(90, 121), 40.0], [Vector2(90, 112), 38.0]]
## Desfase del vaivén de cada hito (s). El islote de la zona 4 además flota entero, con su suelo.
const DESFASES := [0.0, 1.7, 0.6, 0.0, 2.2]
const ZONA_FLOTANTE := 3
## Donde toca el suelo la ruta en cada zona, desde el centro de su caja.
const PIES := [Vector2(0, 34), Vector2(0, 34), Vector2(0, 34), Vector2(0, 92), Vector2(0, 34)]
## Puntos de control de cada tramo de la ruta (bezier cúbica): salida desde el pie de la zona
## anterior y llegada al de la siguiente. Copiados de la maqueta.
const SALIDAS := [Vector2(90, 14), Vector2(80, 10), Vector2(120, 30), Vector2(80, 38)]
const LLEGADAS := [Vector2(-50, 58), Vector2(-100, 10), Vector2(-50, 88), Vector2(-70, 36)]
const ORO := Color("#FFD23F")
const ORO_BORDE := Color("#E0A21A")
const TENUE := Color(1, 1, 1, 0.6)

var _zonas: Array = []
var _tiempo := 0.0
var _material: ShaderMaterial
var _arcoiris: Control
var _nubes: Control
var _texturas := {}
var _puntos_ruta: Array = []
var _centros_ruta: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_VIVEZA)
	_capa("cielo", "cielo")
	_arcoiris = _capa("arcoiris", "")
	_nubes = _capa("nubes", "nubes")
	_capa("tierra", "tierra")
	_actualizar_viveza()


func _process(delta: float) -> void:
	_tiempo += delta
	# Las nubes y los islotes de adorno se mecen despacio.
	_nubes.position = Vector2(sin(_tiempo * TAU / 22.0) * 18.0, sin(_tiempo * TAU / 5.0) * 3.0)


func _capa(nombre: String, archivo: String) -> Control:
	var capa := Control.new()
	capa.name = nombre
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa)
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if archivo != "":
		var textura := _textura(archivo)
		capa.material = _material
		capa.draw.connect(func() -> void:
			if textura != null:
				capa.draw_texture_rect(textura, Rect2(Vector2.ZERO, Vector2(1280, 720)), false))
	return capa


func _textura(nombre: String) -> Texture2D:
	if not _texturas.has(nombre):
		var ruta := CARPETA + nombre + ".svg"
		_texturas[nombre] = load(ruta) if ResourceLoader.exists(ruta) else null
		if _texturas[nombre] == null:
			push_warning("paisaje_arcoiris: falta %s (python herramientas/generar_mapa_arcoiris.py)" % ruta)
	return _texturas[nombre]


## Guarda el estado de las zonas y ajusta cuánto color tiene el paisaje.
func actualizar(zonas: Array) -> void:
	_zonas = zonas
	_actualizar_viveza()


## Con el planeta gris el paisaje queda a 45 % de color; cada banda que vuelve le devuelve un poco.
func _actualizar_viveza() -> void:
	if _material == null:
		return
	var bandas := {}
	for zona: Dictionary in _zonas:
		if zona["completa"]:
			for banda in zona["datos"].get("bandas", []):
				bandas[banda] = true
	_material.set_shader_parameter("viveza", 0.45 + 0.55 * bandas.size() / 7.0)


func capa_arcoiris() -> Control:
	return _arcoiris


## Arcoíris grande detrás de las colinas: semicírculo de 6 bandas de 15 px (la de afuera en r 450).
func geometria_arcoiris() -> Dictionary:
	return {"centro": Vector2(640, 470), "radio": 457.5, "ancho": 15.0, "apagada": Color("#C7B8D6", 0.55)}


# ---------------------------------------------------------------------------
# Ruta de puntitos dorados (como el camino del Mapa Estelar), más grandes adelante
# ---------------------------------------------------------------------------

func dibujar_camino(lienzo: CanvasItem, zonas: Array, centros: Array) -> void:
	if _centros_ruta != centros:
		_calcular_ruta(centros)
	for tramo: Dictionary in _puntos_ruta:
		var destino: int = tramo["hasta"]
		var encendido: bool = destino < zonas.size() and zonas[destino]["abierta"]
		for punto: Vector2 in tramo["puntos"]:
			if encendido:
				var radio := 3.5 + clampf((punto.y - 260.0) / 340.0, 0.0, 1.0) * 4.0
				lienzo.draw_circle(punto, radio + 1.2, ORO_BORDE)
				lienzo.draw_circle(punto, radio, ORO)
			else:
				lienzo.draw_circle(punto, 4.0, TENUE)


## Un puntito cada ~19 px por tramo, salvo cerca del pie de una zona (ahí está su hito).
func _calcular_ruta(centros: Array) -> void:
	_centros_ruta = centros.duplicate()
	_puntos_ruta.clear()
	var pies: Array = []
	for i in centros.size():
		pies.append(centros[i] + (PIES[i] if i < PIES.size() else Vector2(0, 34)))
	for k in mini(pies.size() - 1, SALIDAS.size()):
		var a: Vector2 = pies[k]
		var b: Vector2 = pies[k + 1]
		var c1: Vector2 = a + SALIDAS[k]
		var c2: Vector2 = b + LLEGADAS[k]
		var puntos: Array = []
		var anterior := a
		var recorrido := 0.0
		for paso in range(1, 401):
			var punto := a.bezier_interpolate(c1, c2, b, paso / 400.0)
			recorrido += punto.distance_to(anterior)
			anterior = punto
			if recorrido < 19.0:
				continue
			recorrido = 0.0
			var libre := true
			for pie: Vector2 in pies:
				libre = libre and ((punto - pie) / Vector2(78, 46)).length_squared() > 1.0
			if libre:
				puntos.append(punto)
		_puntos_ruta.append({"hasta": k + 1, "puntos": puntos})


# ---------------------------------------------------------------------------
# Hitos de las zonas
# ---------------------------------------------------------------------------

## Dibuja el hito de la zona `i` (despierto o dormido, en gris) y devuelve dónde va su carita.
func dibujar_hito(lienzo: CanvasItem, i: int, zona: Dictionary, centro: Vector2, tiempo: float) -> Dictionary:
	if i >= CARAS.size():
		return {}
	var sufijo := "" if zona["abierta"] else "_gris"
	var origen := centro - Vector2.ONE * LADO_HITO / 2.0
	var vaiven := -3.5 * (1.0 - cos((tiempo + DESFASES[i]) * TAU / 3.4))
	if i == ZONA_FLOTANTE:
		origen.y += -4.0 * (1.0 - cos(tiempo * TAU / 5.0))
	var caja := Vector2.ONE * LADO_HITO
	var suelo := _textura("zona%d_suelo%s" % [i + 1, sufijo])
	var hito := _textura("zona%d_hito%s" % [i + 1, sufijo])
	if suelo != null:
		lienzo.draw_texture_rect(suelo, Rect2(origen, caja), false)
	if hito != null:
		lienzo.draw_texture_rect(hito, Rect2(origen + Vector2(0, vaiven), caja), false)
	return {"cara": origen + CARAS[i][0] + Vector2(0, vaiven), "escala": CARAS[i][1]}
