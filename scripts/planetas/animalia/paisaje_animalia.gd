extends Control

## Paisaje del mapa del Planeta Animalia visto desde el suelo (HE-120, 05-Nov-2026).
##
## Pedido del PO (05-Nov-2026): "El mapa de animalia debe ser similar al que hicimos en planeta
## arcoiris con las tematicas de animalia". Mismo contrato y lenguaje visual que
## `scripts/planetas/arcoiris/paisaje_arcoiris.gd` (maqueta aprobada el 17-Oct-2026) con el hilo de
## Animalia (docs/fichas/planeta-animalia-zonas.md §1-§2 y §6-§7): **el planeta duerme la siesta** y
## cada zona completada despierta un rincón, cuyos animales se suman al desfile del sendero.
##
## Arte: lo quieto es SVG generado por `herramientas/generar_mapa_animalia.py`
## (`assets/sprites/planetas/animalia/mapa/`); lo vivo (animales, humito, neblina, desfile, Dinito,
## hito de la batalla) se dibuja en código (`animalitos.gd`) hasta que llegue el arte de HE-114.
## Capas, de atrás hacia adelante: cielo, aurora (premio de Sofía), nubes y pájaros, tierra, vida
## (hojas que caen; sin mariposas, §2.0), hito de la batalla. Cada zona es un hito con carita:
##   1 Campamento de Toby ....... la carpa redonda con antenita; corralito, nidito de Dinito
##   2 Laguna de los Nenúfares ... nenúfar gigante con una flor que se abre y se cierra
##   3 Pradera de las Jirafas .... acacia con una jirafa que asoma la cabeza por encima
##   4 Árbol de los Nidos ........ árbol enorme con nidos, tucán en la punta, monito en una rama
##   5 Valle de los Dinosaurios .. volcán dormilón con humito; neblina tibia hasta revelarse
##
## Estados de cada rincón (§2.0): dormido (medio tono, vecinos acurrucados con "zzz", quieto),
## abierto (bostezan y se estiran de vez en cuando), completado (bailan y su grupo camina en el desfile).
## Al completar el planeta llega el Gran Desfile (§6.1, ~12 s, se salta con un toque) y Dinito queda
## viviendo junto a la carpa.
##
## Contrato con `mapa_planeta.gd` (que no conoce este planeta; solo lee la ruta en el JSON):
##   actualizar(zonas)                              estado de cada zona
##   dibujar_camino(lienzo, zonas, centros)         sendero de huellitas (y el desfile que camina en él)
##   dibujar_hito(lienzo, i, zona, centro, tiempo)  hito de la zona; devuelve dónde va su carita
## No define `capa_arcoiris()`: Animalia no tiene arcoíris en el cielo (ficha §12.4).
##
## Lo que este paisaje sabe de su propio planeta lo lee de su `mapa.json` (batalla, pieza). Lo que
## guarda va por la API existente de `Progreso`, sin campos nuevos:
##   - `desbloquear_pieza_nave(hermano, "animalia")` al completar la zona 3 (ala derecha, §2.2);
##   - `marcar_especial_conocido(hermano, "animalia_gran_desfile")` al terminar (o saltar) el Gran Desfile;
##   - lee `especial_conocido(hermano, "animalia_huevo_z<n>")` (lo marcará el Escondite al tocar el
##     huevito de Dinito, §7); mientras tanto, cada zona completada también pone su huevo en el nidito.

const Animalitos := preload("res://scripts/planetas/animalia/animalitos.gd")
const RUTA_MAPA := "res://datos/planetas/animalia/mapa.json"
const CARPETA := "res://assets/sprites/planetas/animalia/mapa/"
const SHADER_VIVEZA := "res://assets/shaders/viveza.gdshader"
const RUTA_TOBY := "res://assets/sprites/personajes/toby_provisional.png"
const PREFIJO_AUDIO := "res://assets/audio/"
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_FIESTA := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_PASO := "res://assets/audio/sfx/ui/blup.ogg"
const SFX_PUF := "res://assets/audio/sfx/ui/puf.ogg"
const PLANETA := "animalia"
const PERFILES := ["maxi", "nicole", "sofia"]
const ESPECIAL_DESFILE := "animalia_gran_desfile"
const ESPECIAL_HUEVO := "animalia_huevo_z%d"
const DURACION_DESFILE := 12.0

const LADO_HITO := 180.0
const CONTORNO := Color("#3a3550")
const ORO := Color("#FFD23F")
const ORO_BORDE := Color("#C98A1A")
const TIERRA_SENDERO := Color("#ecd3a0")
const TIERRA_BORDE := Color("#c99a62")
const TENUE := Color(1, 1, 1, 0.55)
## Carita de cada hito (centro en la caja de 180x180 y ancho; el núcleo la dibuja despierta o dormida).
const CARAS := [[Vector2(90, 101), 36.0], [Vector2(90, 80), 28.0], [Vector2(62, 62), 32.0], [Vector2(91, 116), 28.0], [Vector2(90, 102), 38.0]]
## Desfase del vaivén de cada hito (s).
const DESFASES := [0.0, 1.3, 0.6, 2.0, 1.0]
## Donde toca el suelo el sendero en cada zona, desde el centro de su caja.
const PIES := [Vector2(56, 52), Vector2(-20, 104), Vector2(-46, 54), Vector2(-12, 66), Vector2(-70, 52)]
## Puntos de control de cada tramo del sendero (bezier cúbica): salida desde el pie de la zona
## anterior y llegada al de la siguiente.
const SALIDAS := [Vector2(70, -6), Vector2(90, 10), Vector2(110, -20), Vector2(60, -10)]
const LLEGADAS := [Vector2(-80, 10), Vector2(-90, 0), Vector2(30, 90), Vector2(-60, 40)]
## Riachuelo del SVG (`generar_mapa_animalia.py`, capa_tierra): el puente de troncos va donde lo cruza el sendero.
const RIO := [Vector2(452, 504), Vector2(430, 540), Vector2(432, 570), Vector2(470, 600), Vector2(510, 632), Vector2(520, 670), Vector2(506, 740)]

## Vecinos de cada hito: [especie, lugar desde el centro de la caja, alto, mirada, ¿detrás del hito?].
const VECINOS := [
	[["perro", Vector2(-40, 66), 36.0, 1.0, false], ["vaca", Vector2(68, 50), 38.0, -1.0, false]],
	[["pato", Vector2(-70, 42), 30.0, 1.0, false], ["pato", Vector2(-50, 46), 24.0, 1.0, false], ["flamenco", Vector2(70, 40), 44.0, -1.0, false]],
	[["jirafa", Vector2(14, 44), 64.0, 1.0, true], ["cebra", Vector2(-66, 56), 34.0, 1.0, false]],
	[["tucan", Vector2(14, -86), 30.0, -1.0, false], ["mono", Vector2(-52, -2), 30.0, 1.0, false]],
	[["braquiosaurio", Vector2(-58, 40), 54.0, 1.0, true], ["triceratops", Vector2(66, 58), 34.0, -1.0, false]],
]
## Notas del Gran Desfile: escalera afinada (do re mi fa sol la), un grupo por nota (§6.1, coro de topos §7.5).
const ESCALERA := [1.0, 1.122, 1.26, 1.335, 1.498, 1.682]

var _zonas: Array = []
var _tiempo := 0.0
var _material: ShaderMaterial
var _nubes: Control
var _cielo_vivo: Control
var _vida: Control
var _hito_batalla: Control
var _texturas := {}
var _mapa := {}
var _perfil := ""
var _equipo := false
var _puntos_ruta: Array = []
var _muestras_ruta: Array = []
var _centros_ruta: Array = []
var _puente := {}
var _lienzo_camino: CanvasItem
## Lo que se deriva del progreso en cada `actualizar`.
var _huevos := 0
var _dinito_vive := false
var _gemas: Array = []
var _aurora := false
var _huellita_dorada := false
var _batalla_visible := false
var _batalla_estado := "mochila"
var _burbujas_batalla := 4
var _menear_batalla := 0.0
var _voz_batalla_previa := ""
## Gran Desfile.
var _desfile_capa: CanvasLayer
var _desfile_lienzo: Control
var _desfile_t := -1.0
var _desfile_notas := 0
var _desfile_puf := false
var _marcha: Array = []
var _textura_toby: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if FileAccess.file_exists(RUTA_MAPA):
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_MAPA))
		if datos is Dictionary:
			_mapa = datos
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_VIVEZA)
	_capa("cielo", "cielo")
	_cielo_vivo = _capa("cielo_vivo", "")
	_cielo_vivo.draw.connect(_dibujar_cielo_vivo)
	_nubes = _capa("nubes", "nubes")
	_capa("tierra", "tierra")
	_vida = _capa("vida", "")
	_vida.draw.connect(_dibujar_vida)
	_construir_hito_batalla()
	if ResourceLoader.exists(RUTA_TOBY):
		_textura_toby = load(RUTA_TOBY)
	_actualizar_viveza()


func _process(delta: float) -> void:
	_tiempo += delta
	_nubes.position = Vector2(sin(_tiempo * TAU / 24.0) * 16.0, sin(_tiempo * TAU / 6.0) * 2.5)
	_cielo_vivo.queue_redraw()
	_vida.queue_redraw()
	if _hito_batalla != null and _hito_batalla.visible:
		_menear_batalla = maxf(0.0, _menear_batalla - delta)
		_hito_batalla.queue_redraw()
	# El desfile del sendero camina siempre: el lienzo del camino se redibuja cada cuadro.
	if _lienzo_camino != null and is_instance_valid(_lienzo_camino) and _hay_desfile_sendero():
		_lienzo_camino.queue_redraw()
	if _desfile_t >= 0.0:
		_avanzar_desfile(delta)


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
			push_warning("paisaje_animalia: falta %s (python herramientas/generar_mapa_animalia.py)" % ruta)
	return _texturas[nombre]


# ---------------------------------------------------------------------------
# Estado (derivado del progreso; el núcleo pasa las zonas del hermano o del equipo)
# ---------------------------------------------------------------------------

func actualizar(zonas: Array) -> void:
	_zonas = zonas
	var progreso := get_node_or_null("/root/Progreso")
	_perfil = ""
	_equipo = false
	if progreso != null:
		_perfil = str(progreso.perfil_seleccionado)
		_equipo = progreso.equipo_activo.size() >= 2
	_actualizar_viveza()
	_huevos = 0
	_dinito_vive = false
	_gemas = []
	_aurora = false
	_huellita_dorada = false
	if progreso != null and not _equipo and _perfil != "":
		_dinito_vive = progreso.especial_conocido(_perfil, ESPECIAL_DESFILE)
		for i in zonas.size():
			var encontrado: bool = progreso.especial_conocido(_perfil, ESPECIAL_HUEVO % (i + 1))
			_huevos += 1 if encontrado or zonas[i]["completa"] else 0
			if _zona_perfecta(zonas[i]):
				_gemas.append(i)
		if zonas.size() >= 5:
			var valle: Array = zonas[4]["estaciones"]
			_aurora = valle.size() > 3 and bool(valle[3].get("dorado_completado", false))
			_huellita_dorada = valle.size() > 1 and bool(valle[1].get("dorado_completado", false))
		# Ala derecha (§2.2): llega al completar la zona 3. Idempotente: solo guarda la primera vez.
		if zonas.size() >= 3 and zonas[2]["completa"] and not progreso.tiene_pieza_nave(_perfil, PLANETA):
			progreso.desbloquear_pieza_nave(_perfil, PLANETA)
	elif progreso != null and _equipo:
		# El mapa del equipo está todo a color; Dinito vive si algún hermano ya vio su Gran Desfile.
		for id in PERFILES:
			_dinito_vive = _dinito_vive or progreso.especial_conocido(id, ESPECIAL_DESFILE)
	_actualizar_batalla()
	if _debe_haber_desfile():
		_preparar_desfile()


## Zona perfecta (§6.3, igual para Nicole y Sofía): 3 estrellitas en todas las estaciones que puntúan.
func _zona_perfecta(zona: Dictionary) -> bool:
	if not zona["completa"]:
		return false
	var con_puntaje: Array = (zona["estaciones"] as Array).filter(func(e: Dictionary) -> bool: return e["jugable"] and e["puntua"])
	if con_puntaje.is_empty():
		return false
	return con_puntaje.all(func(e: Dictionary) -> bool:
		return str(e["perfil_nivel"]) in ["brote", "estrella"] and int(e["estrellitas"]) >= 3)


## Los rincones despiertan de a poco: con el planeta dormido el paisaje queda a 70 % de color.
func _actualizar_viveza() -> void:
	if _material == null:
		return
	var completas := 0
	for zona: Dictionary in _zonas:
		completas += 1 if zona["completa"] else 0
	var total := maxi(1, _zonas.size())
	_material.set_shader_parameter("viveza", 0.7 + 0.3 * completas / float(total))


func todas_completas() -> bool:
	if _zonas.is_empty():
		return false
	for zona: Dictionary in _zonas:
		if not zona["completa"]:
			return false
	return true


func _debe_haber_desfile() -> bool:
	return not _equipo and _perfil != "" and not _dinito_vive and _desfile_t < 0.0 and todas_completas()


# ---------------------------------------------------------------------------
# Hito de la batalla (docs/fichas/batalla-animalia.md §3.2 y §8.4)
# ---------------------------------------------------------------------------

## Aparece tras la zona 3 del PRIMER hermano que la complete ("condicion": "primer_hermano").
func _actualizar_batalla() -> void:
	var batalla: Dictionary = _mapa.get("batalla", {})
	_batalla_visible = false
	if batalla.is_empty() or _hito_batalla == null:
		return
	var numero := int(batalla.get("aparece_tras_zona", 3))
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and numero >= 1 and numero <= (_mapa.get("zonas", []) as Array).size():
		var datos_zona: Dictionary = _mapa["zonas"][numero - 1]
		for id in PERFILES:
			if _zona_completa_de(progreso, id, datos_zona):
				_batalla_visible = true
				break
	_hito_batalla.visible = _batalla_visible
	if not _batalla_visible or progreso == null:
		return
	var id_batalla := str(batalla.get("id", ""))
	_burbujas_batalla = maxi(0, 4 - (progreso.obtener_rondas_batalla(id_batalla) as Array).size())
	_batalla_estado = "mochila"
	if progreso.batalla_ganada(id_batalla):
		_batalla_estado = "partida"
		if progreso.has_method("partida_hecha") and progreso.call("partida_hecha", PLANETA):
			_batalla_estado = "revancha"


func hito_batalla_visible() -> bool:
	return _batalla_visible


func estado_hito_batalla() -> String:
	return _batalla_estado


## Completa = todas las estaciones jugables de ese hermano completadas (misma regla que el núcleo).
func _zona_completa_de(progreso: Node, id_perfil: String, datos_zona: Dictionary) -> bool:
	var jugables := 0
	for estacion: Dictionary in datos_zona.get("estaciones", []):
		var ruta := str(estacion.get("niveles", {}).get(id_perfil, ""))
		var escena := str(estacion.get("escenas", {}).get(id_perfil, estacion.get("escena", "")))
		if ruta == "" or escena == "" or not ResourceLoader.exists(escena) or not FileAccess.file_exists(ruta):
			continue
		jugables += 1
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		var id_nivel := ruta.get_file().get_basename()
		if datos is Dictionary:
			id_nivel = str(datos.get("id_nivel", id_nivel))
		if not progreso.esta_nivel_completado(id_perfil, PLANETA, id_nivel):
			return false
	return jugables > 0


func _construir_hito_batalla() -> void:
	var batalla: Dictionary = _mapa.get("batalla", {})
	if batalla.is_empty():
		return
	var pos: Array = batalla.get("posicion", [600, 630])
	_hito_batalla = Control.new()
	_hito_batalla.name = "hito_batalla"
	_hito_batalla.size = Vector2(128, 128)
	_hito_batalla.position = Vector2(float(pos[0]), float(pos[1])) - _hito_batalla.size / 2.0
	_hito_batalla.pivot_offset = _hito_batalla.size / 2.0
	_hito_batalla.mouse_filter = Control.MOUSE_FILTER_STOP
	_hito_batalla.tooltip_text = "La batalla del Coleccionauta"
	_hito_batalla.visible = false
	_hito_batalla.draw.connect(_dibujar_hito_batalla)
	_hito_batalla.gui_input.connect(func(evento: InputEvent) -> void:
		if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			tocar_hito_batalla())
	add_child(_hito_batalla)


## Responde en < 100 ms (late y suena). La escena de la batalla se conecta en HE-121; mientras tanto
## suena una de las voces del hito (sin repetir la anterior).
func tocar_hito_batalla() -> void:
	_menear_batalla = 0.45
	_sonar(SFX_TOQUE)
	var tween := _hito_batalla.create_tween()
	tween.tween_property(_hito_batalla, "scale", Vector2.ONE * 1.08, 0.12)
	tween.tween_property(_hito_batalla, "scale", Vector2.ONE, 0.13)
	var voces: Array = (_mapa.get("batalla", {}) as Dictionary).get("voz_hito", [])
	var opciones := voces.filter(func(v) -> bool: return str(v) != _voz_batalla_previa)
	if not opciones.is_empty():
		_voz_batalla_previa = str(opciones.pick_random())
		_decir(_voz_batalla_previa)


func _dibujar_hito_batalla() -> void:
	var c := _hito_batalla.size / 2.0 + Vector2(0, 14)
	var meneo := sin(_tiempo * 30.0) * 0.12 * (_menear_batalla / 0.45)
	var lienzo := _hito_batalla
	lienzo.draw_set_transform(c, meneo, Vector2.ONE)
	lienzo.draw_circle(Vector2(0, 40), 34.0, Color(0.18, 0.3, 0.14, 0.25))
	match _batalla_estado:
		"partida":
			_dibujar_nave_partida(lienzo)
		"revancha":
			_dibujar_mochila(lienzo, 0)
			for k in 5:
				var t := fposmod(_tiempo * 0.5 + k / 5.0, 1.0)
				var p := Vector2(-30 + k * 16.0 + sin(_tiempo * 2.0 + k) * 6.0, -40.0 - t * 50.0)
				_burbuja(lienzo, p, 8.0, Color.from_hsv(k / 5.0, 0.4, 1.0), 1.0 - t)
		_:
			_dibujar_mochila(lienzo, _burbujas_batalla)
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## La mochila-torre del Coleccionauta con las burbujas de las carrozas atadas (§8.4).
func _dibujar_mochila(lienzo: CanvasItem, burbujas: int) -> void:
	var colores := [Color("#ff9f4a"), Color("#4a8be0"), Color("#ffcb3d"), Color("#7dd87a")]
	for k in burbujas:
		var x := -36.0 + k * 24.0
		var p := Vector2(x + sin(_tiempo * 1.6 + k) * 4.0, -66.0 - (k % 2) * 12.0 + sin(_tiempo * 2.1 + k * 1.3) * 3.0)
		lienzo.draw_line(Vector2(x * 0.3, -20), p + Vector2(0, 14), Color(1, 1, 1, 0.7), 1.5, true)
		_burbuja(lienzo, p, 14.0, Color(1, 1, 1), 1.0)
		# La carroza adentro, con su animalito que saluda.
		lienzo.draw_rect(Rect2(p + Vector2(-7, -2), Vector2(14, 8)), colores[k])
		lienzo.draw_circle(p + Vector2(-4, 7), 2.5, CONTORNO)
		lienzo.draw_circle(p + Vector2(4, 7), 2.5, CONTORNO)
		lienzo.draw_circle(p + Vector2(0, -5), 4.0, Color("#e0aa6e"))
	var cuerpo := PackedVector2Array([Vector2(-26, 34), Vector2(-24, -18), Vector2(-14, -30), Vector2(14, -30), Vector2(24, -18), Vector2(26, 34)])
	var cerrado := cuerpo.duplicate()
	cerrado.append(cuerpo[0])
	lienzo.draw_polyline(cerrado, CONTORNO, 5.0, true)
	lienzo.draw_colored_polygon(cuerpo, Color("#b48ce8"))
	lienzo.draw_rect(Rect2(-18, -8, 36, 22), Color("#9a72d4"))
	lienzo.draw_rect(Rect2(-18, -8, 36, 22), CONTORNO, false, 2.5)
	for k in 3:
		lienzo.draw_circle(Vector2(-10 + k * 10, -20), 3.0, Color("#ffe066"))
	lienzo.draw_line(Vector2(-12, 34), Vector2(-12, -28), Color("#7a52b4"), 4.0)
	lienzo.draw_line(Vector2(12, 34), Vector2(12, -28), Color("#7a52b4"), 4.0)
	# Varita de burbujas.
	lienzo.draw_line(Vector2(26, 10), Vector2(42, -22), Color("#8a5a36"), 4.0, true)
	lienzo.draw_arc(Vector2(45, -28), 7.0, 0.0, TAU, 20, Color("#ff8fae"), 3.0, true)


## Ganada la batalla: la nave estacionada brillando, con la manguera enrollada al lado (§8.4).
func _dibujar_nave_partida(lienzo: CanvasItem) -> void:
	var brillo := 0.5 + 0.5 * sin(_tiempo * 2.4)
	for k in 3:
		lienzo.draw_circle(Vector2(0, -6), 44.0 - k * 10.0 + brillo * 4.0, Color(1, 0.92, 0.55, 0.12))
	var estrella := _estrella(Vector2(0, -6), 34.0)
	var cerrada := estrella.duplicate()
	cerrada.append(estrella[0])
	lienzo.draw_polyline(cerrada, CONTORNO, 5.0, true)
	lienzo.draw_colored_polygon(estrella, ORO)
	lienzo.draw_circle(Vector2(0, -10), 11.0, Color("#bfeaf5"))
	lienzo.draw_arc(Vector2(0, -10), 11.0, 0.0, TAU, 24, CONTORNO, 2.5, true)
	for k in 3:
		lienzo.draw_arc(Vector2(40, 30), 6.0 + k * 4.0, 0.0, TAU, 20, Color("#ff4a4a"), 3.0, true)


func _burbuja(lienzo: CanvasItem, p: Vector2, r: float, tinte: Color, alfa: float) -> void:
	lienzo.draw_circle(p, r, Color(tinte.lerp(Color("#cfefff"), 0.5), 0.35 * alfa))
	lienzo.draw_arc(p, r, 0.0, TAU, 28, Color(1, 1, 1, 0.85 * alfa), 2.0, true)
	lienzo.draw_circle(p + Vector2(-r * 0.4, -r * 0.4), r * 0.22, Color(1, 1, 1, 0.8 * alfa))


# ---------------------------------------------------------------------------
# Cielo vivo (aurora de Sofía, pájaros) y vida (hojas que caen)
# ---------------------------------------------------------------------------

func _dibujar_cielo_vivo() -> void:
	if _aurora:
		# Aurora austral (premio de "Sendero sin fin", §6.2): cintas suaves que ondulan.
		for banda in 3:
			var color: Color = [Color("#7dffb8"), Color("#8fd8ff"), Color("#d6a8ff")][banda]
			var puntos := PackedVector2Array()
			for k in 33:
				var x := 120.0 + k * 33.0
				puntos.append(Vector2(x, 70.0 + banda * 16.0 + sin(x * 0.012 + _tiempo * 0.7 + banda) * 18.0))
			_cielo_vivo.draw_polyline(puntos, Color(color, 0.32), 16.0 - banda * 3.0, true)
	# Pájaros en V que cruzan despacio (reemplazan a las mariposas del ambiente, §2.0).
	for k in 3:
		var avance := fposmod(_tiempo * (18.0 + k * 5.0) + k * 420.0, 1500.0) - 110.0
		var p := Vector2(avance, 92.0 + k * 34.0 + sin(_tiempo * 1.3 + k) * 8.0)
		var ala := 6.0 + 3.0 * sin(_tiempo * 8.0 + k)
		_cielo_vivo.draw_polyline(PackedVector2Array([p + Vector2(-9, -ala), p, p + Vector2(9, -ala)]), Color("#5a6a7a", 0.7), 2.4, true)


func _dibujar_vida() -> void:
	# Hojas que caen de las copas de la selva, en bucle y meciéndose.
	for k in 7:
		var semilla := k * 137.0
		var t := fposmod(_tiempo * (0.07 + 0.012 * (k % 3)) + k / 7.0, 1.0)
		var x := fposmod(semilla * 3.1, 900.0) + 30.0 + sin(_tiempo * 1.4 + k) * 22.0
		var y := 330.0 + t * 330.0
		var giro := sin(_tiempo * 1.8 + k) * 1.2
		var alfa := minf(1.0, (1.0 - t) * 4.0) * minf(1.0, t * 6.0)
		var hoja := PackedVector2Array()
		for a in 10:
			var ang := TAU * a / 10.0
			hoja.append(Vector2(x, y) + Vector2(cos(ang) * 7.0, sin(ang) * 3.2).rotated(giro))
		_vida.draw_colored_polygon(hoja, Color([Color("#7fcf6a"), Color("#c9d85a"), Color("#ffb86b")][k % 3], 0.85 * alfa))


# ---------------------------------------------------------------------------
# Sendero de huellitas (dorado lo abierto, blanquito lo que duerme) + el desfile que camina en él
# ---------------------------------------------------------------------------

func dibujar_camino(lienzo: CanvasItem, zonas: Array, centros: Array) -> void:
	_lienzo_camino = lienzo
	if _centros_ruta != centros:
		_calcular_ruta(centros)
	# Tierra del sendero bajo las huellas.
	for tramo: Dictionary in _muestras_ruta:
		var destino: int = tramo["hasta"]
		var abierto: bool = destino < zonas.size() and zonas[destino]["abierta"]
		var puntos: PackedVector2Array = tramo["puntos"]
		if puntos.size() > 1:
			lienzo.draw_polyline(puntos, Color(TIERRA_BORDE, 0.55 if abierto else 0.25), 26.0, true)
			lienzo.draw_polyline(puntos, Color(TIERRA_SENDERO, 0.95 if abierto else 0.4), 20.0, true)
	if not _puente.is_empty():
		_dibujar_puente(lienzo)
	for tramo: Dictionary in _puntos_ruta:
		var destino: int = tramo["hasta"]
		var encendido: bool = destino < zonas.size() and zonas[destino]["abierta"]
		var k := 0
		for huella: Dictionary in tramo["huellas"]:
			var punto: Vector2 = huella["p"]
			var escala := 0.75 + clampf((punto.y - 260.0) / 360.0, 0.0, 1.0) * 0.45
			if encendido:
				_huellita(lienzo, punto, huella["a"], escala, ORO, ORO_BORDE)
			else:
				_huellita(lienzo, punto, huella["a"], escala * 0.9, TENUE, Color(0, 0, 0, 0))
			k += 1
	if _huellita_dorada and not _muestras_ruta.is_empty():
		# Premio de "El gran tablero de Toby" (§6.2): una huellita dorada grande al empezar el sendero.
		var inicio: PackedVector2Array = _muestras_ruta[0]["puntos"]
		if inicio.size() > 8:
			_huellita(lienzo, inicio[8] + Vector2(0, -22), 0.0, 2.0 + 0.15 * sin(_tiempo * 3.0), Color("#ffe066"), ORO_BORDE)
	_dibujar_desfile_sendero(lienzo, zonas)


## Una pata: almohadilla y cuatro deditos, girada según el sentido del sendero.
func _huellita(lienzo: CanvasItem, centro: Vector2, angulo: float, escala: float, relleno: Color, borde: Color) -> void:
	var giro := Transform2D(angulo + PI / 2.0, centro)
	var partes := [[Vector2(0, 2.5), 4.4, 3.6], [Vector2(-4.6, -3.2), 1.9, 1.9], [Vector2(-1.6, -5.6), 1.9, 1.9], [Vector2(1.6, -5.6), 1.9, 1.9], [Vector2(4.6, -3.2), 1.9, 1.9]]
	for pasada in 2:
		if pasada == 0 and borde.a <= 0.0:
			continue
		for parte: Array in partes:
			var c: Vector2 = giro * (parte[0] * escala)
			var extra := 1.2 if pasada == 0 else 0.0
			var forma := PackedVector2Array()
			for a in 12:
				var ang := TAU * a / 12.0
				forma.append(c + Vector2(cos(ang) * (parte[1] * escala + extra), sin(ang) * (parte[2] * escala + extra)).rotated(angulo + PI / 2.0))
			lienzo.draw_colored_polygon(forma, borde if pasada == 0 else relleno)


## Sendero: muestras densas para la tierra y el desfile; una huellita cada ~22 px (alternando izquierda
## y derecha), salvo cerca del pie de cada zona (ahí está su hito) y sobre el puente.
func _calcular_ruta(centros: Array) -> void:
	_centros_ruta = centros.duplicate()
	_puntos_ruta.clear()
	_muestras_ruta.clear()
	_puente = {}
	var pies: Array = []
	for i in centros.size():
		pies.append(centros[i] + (PIES[i] if i < PIES.size() else Vector2(0, 50)))
	for k in mini(pies.size() - 1, SALIDAS.size()):
		var a: Vector2 = pies[k]
		var b: Vector2 = pies[k + 1]
		var c1: Vector2 = a + SALIDAS[k]
		var c2: Vector2 = b + LLEGADAS[k]
		var muestras := PackedVector2Array()
		for paso in range(0, 161):
			muestras.append(a.bezier_interpolate(c1, c2, b, paso / 160.0))
		_muestras_ruta.append({"hasta": k + 1, "puntos": muestras})
	_ubicar_puente()
	for tramo: Dictionary in _muestras_ruta:
		var muestras: PackedVector2Array = tramo["puntos"]
		var huellas: Array = []
		var recorrido := 0.0
		var lado := 1.0
		for m in range(1, muestras.size()):
			recorrido += muestras[m].distance_to(muestras[m - 1])
			if recorrido < 22.0:
				continue
			recorrido = 0.0
			var direccion := (muestras[m] - muestras[m - 1]).normalized()
			var punto := muestras[m] + direccion.orthogonal() * 5.0 * lado
			lado = -lado
			var libre := true
			for pie: Vector2 in pies:
				libre = libre and ((punto - pie) / Vector2(70, 40)).length_squared() > 1.0
			if not _puente.is_empty():
				libre = libre and punto.distance_to(_puente["p"]) > 30.0
			if libre:
				huellas.append({"p": punto, "a": direccion.angle()})
		_puntos_ruta.append({"hasta": tramo["hasta"], "huellas": huellas})


## El puente de troncos va donde el primer tramo cruza el riachuelo del SVG.
func _ubicar_puente() -> void:
	if _muestras_ruta.is_empty():
		return
	var rio := PackedVector2Array()
	for s in (RIO.size() - 1) / 3:
		var base := s * 3
		for paso in 21:
			rio.append((RIO[base] as Vector2).bezier_interpolate(RIO[base + 1], RIO[base + 2], RIO[base + 3], paso / 20.0))
	var tramo: PackedVector2Array = _muestras_ruta[0]["puntos"]
	var mejor := INF
	for m in range(1, tramo.size()):
		for r in rio:
			var d := tramo[m].distance_squared_to(r)
			if d < mejor:
				mejor = d
				_puente = {"p": tramo[m], "a": (tramo[m] - tramo[m - 1]).angle()}
	if mejor > 30.0 * 30.0:
		_puente = {}


func _dibujar_puente(lienzo: CanvasItem) -> void:
	var c: Vector2 = _puente["p"]
	var eje := Vector2.from_angle(_puente["a"])
	var lado := eje.orthogonal()
	for k in range(-2, 3):
		var centro := c + eje * k * 9.0
		lienzo.draw_line(centro - lado * 20.0, centro + lado * 20.0, CONTORNO, 10.0, true)
		lienzo.draw_line(centro - lado * 19.0, centro + lado * 19.0, Color("#c08a5a"), 7.0, true)
		lienzo.draw_circle(centro - lado * 19.0, 3.4, Color("#e8c08a"))
	for s in [-1.0, 1.0]:
		lienzo.draw_line(c - eje * 24.0 + lado * 22.0 * s, c + eje * 24.0 + lado * 22.0 * s, Color("#8a5a36"), 4.0, true)


func _hay_desfile_sendero() -> bool:
	for zona: Dictionary in _zonas:
		if zona["completa"]:
			return true
	return false


## Los animales de las zonas completadas caminan por el sendero hacia el campamento, en bucle:
## adelante los de la zona más lejana (con las 5, lo encabezan los dinos). Hasta 3 por zona.
func _dibujar_desfile_sendero(lienzo: CanvasItem, zonas: Array) -> void:
	var lejana := -1
	for i in zonas.size():
		if zonas[i]["completa"]:
			lejana = i
	if lejana < 1 or _desfile_t >= 0.0:
		# Con una sola zona (el campamento) todavía no hay por dónde desfilar; su gente baila en su hito.
		return
	var camino := PackedVector2Array()
	for k in range(lejana - 1, -1, -1):
		if k >= _muestras_ruta.size():
			continue
		var muestras: PackedVector2Array = _muestras_ruta[k]["puntos"]
		for m in range(muestras.size() - 1, -1, -1):
			camino.append(muestras[m])
	if camino.size() < 2:
		return
	var largos := PackedFloat32Array([0.0])
	for m in range(1, camino.size()):
		largos.append(largos[m - 1] + camino[m].distance_to(camino[m - 1]))
	var largo_total: float = largos[largos.size() - 1]
	var marcha: Array = []
	for i in range(lejana, -1, -1):
		if not zonas[i]["completa"]:
			continue
		var lista: Array = zonas[i]["datos"].get("desfile", [])
		for especie in lista.slice(0, 3):
			marcha.append(str(especie))
		marcha.append("")
	var separacion := 40.0
	var ciclo := largo_total + marcha.size() * separacion + 120.0
	var avance := fposmod(_tiempo * 34.0, ciclo)
	for n in marcha.size():
		if marcha[n] == "":
			continue
		var s := avance - n * separacion
		if s < 0.0 or s > largo_total:
			continue
		var m := largos.bsearch(s)
		m = clampi(m, 1, camino.size() - 1)
		var t := (s - largos[m - 1]) / maxf(0.001, largos[m] - largos[m - 1])
		var punto := camino[m - 1].lerp(camino[m], t)
		var mira := 1.0 if camino[m].x >= camino[m - 1].x else -1.0
		var alfa := minf(1.0, s / 30.0) * minf(1.0, (largo_total - s) / 30.0)
		lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var paso := _tiempo * 9.0 + n
		Animalitos.dibujar(lienzo, marcha[n], punto + Vector2(0, 6), 30.0 * (0.85 + clampf((punto.y - 260.0) / 360.0, 0.0, 1.0) * 0.3),
			{"dir": mira, "paso": paso, "salto": absf(sin(paso)) * 2.0 * alfa})


# ---------------------------------------------------------------------------
# Hitos de las zonas y sus vecinos
# ---------------------------------------------------------------------------

## Dibuja el hito de la zona `i` con sus vecinos (dormidos, despiertos o de fiesta) y devuelve dónde
## va su carita.
func dibujar_hito(lienzo: CanvasItem, i: int, zona: Dictionary, centro: Vector2, tiempo: float) -> Dictionary:
	if i >= CARAS.size():
		return {}
	var despierta: bool = zona["abierta"]
	var sufijo := "" if despierta else "_gris"
	var origen := centro - Vector2.ONE * LADO_HITO / 2.0
	var vaiven := -3.0 * (1.0 - cos((tiempo + DESFASES[i]) * TAU / 3.6)) if despierta else 0.0
	var caja := Vector2.ONE * LADO_HITO
	var suelo := _textura("zona%d_suelo%s" % [i + 1, sufijo])
	var hito := _textura("zona%d_hito%s" % [i + 1, sufijo])
	if suelo != null:
		lienzo.draw_texture_rect(suelo, Rect2(origen, caja), false)
	_dibujar_vecinos(lienzo, i, zona, centro, tiempo, true)
	if i == 4:
		_dibujar_humito(lienzo, centro, tiempo, despierta)
	if hito != null:
		lienzo.draw_texture_rect(hito, Rect2(origen + Vector2(0, vaiven), caja), false)
	var cara: Vector2 = origen + CARAS[i][0] + Vector2(0, vaiven)
	if i == 1:
		cara = _dibujar_flor_nenufar(lienzo, centro + Vector2(0, vaiven - 10.0), tiempo, zona)
	_dibujar_vecinos(lienzo, i, zona, centro, tiempo, false)
	if i == 0:
		_dibujar_campamento(lienzo, centro, tiempo, zona)
	if i == 4 and not despierta:
		_dibujar_neblina(lienzo, centro, tiempo)
	return {"cara": cara, "escala": CARAS[i][1]}


func _dibujar_vecinos(lienzo: CanvasItem, i: int, zona: Dictionary, centro: Vector2, tiempo: float, detras: bool) -> void:
	if i >= VECINOS.size():
		return
	var despierta: bool = zona["abierta"]
	var fiesta: bool = zona["completa"]
	# En la zona secreta dormida los vecinos están escondidos en la neblina.
	if i == 4 and not despierta:
		return
	var lista: Array = VECINOS[i]
	for k in lista.size():
		var vecino: Array = lista[k]
		if bool(vecino[4]) != detras:
			continue
		var especie := str(vecino[0])
		var pie: Vector2 = centro + (vecino[1] as Vector2)
		var alto: float = vecino[2]
		var estado := {"dir": vecino[3], "dormido": not despierta, "medio": not despierta}
		var fase := tiempo + k * 1.7 + i * 0.9
		if fiesta:
			# Despiertos y de fiesta: saltitos y vueltas al ritmo.
			estado["salto"] = absf(sin(fase * 5.0)) * 7.0
			estado["estirar"] = sin(fase * 10.0) * 0.4
			if fmod(fase, 6.0) < 1.5:
				estado["dir"] = -float(vecino[3])
		elif despierta:
			# Abierta: bostezan y se estiran de vez en cuando (invita a entrar).
			var ciclo := fmod(fase, 5.5)
			if ciclo < 1.2:
				estado["bostezo"] = sin(ciclo / 1.2 * PI)
				estado["estirar"] = -sin(ciclo / 1.2 * PI) * 0.6
		if especie == "jirafa" and despierta:
			# La jirafa asoma la cabeza por encima de la copa y se vuelve a esconder.
			estado["salto"] = float(estado.get("salto", 0.0)) + 8.0 + 8.0 * sin(fase * 0.9)
		Animalitos.dibujar(lienzo, especie, pie, alto, estado)
		if not despierta:
			_zzz(lienzo, pie + Vector2(10.0 * float(vecino[3]), -Animalitos.alto_de(especie, alto) * 0.5 - 6.0), tiempo + k)


func _zzz(lienzo: CanvasItem, base: Vector2, tiempo: float) -> void:
	for k in 2:
		var t := fposmod(tiempo * 0.45 + k * 0.5, 1.0)
		var s := 4.0 + t * 3.0
		var o := base + Vector2(t * 10.0 + k * 3.0, -t * 22.0)
		var color := Color(1, 1, 1, 0.9 * (1.0 - t))
		lienzo.draw_polyline(PackedVector2Array([o + Vector2(-s, -s), o + Vector2(s, -s), o + Vector2(-s, s), o + Vector2(s, s)]), color, 2.4, true)


## La flor rosada del nenúfar gigante: se abre y se cierra despacio; dormida, es un capullo.
func _dibujar_flor_nenufar(lienzo: CanvasItem, centro: Vector2, tiempo: float, zona: Dictionary) -> Vector2:
	var abierta: bool = zona["abierta"]
	var apertura := 0.25 if not abierta else 0.75 + 0.25 * sin(tiempo * TAU / 4.0)
	if zona["completa"]:
		apertura = 0.95 + 0.05 * sin(tiempo * 4.0)
	var rosa := Color("#ff9ec4") if abierta else Color("#e6d2da")
	var claro := Color("#ffd6e8") if abierta else Color("#f2e8ec")
	var c := centro + Vector2(0, -6)
	for capa in 2:
		var petalos := 7 if capa == 0 else 5
		for k in petalos:
			var ang := -PI / 2.0 + (k - (petalos - 1) / 2.0) * (0.42 if capa == 0 else 0.5) * (0.4 + apertura)
			var largo := 26.0 if capa == 0 else 20.0
			var punta := c + Vector2.from_angle(ang) * largo
			var lado := Vector2.from_angle(ang).orthogonal() * (8.0 if capa == 0 else 7.0)
			var petalo := PackedVector2Array([c - lado * 0.3, c + (punta - c) * 0.5 - lado, punta, c + (punta - c) * 0.5 + lado, c + lado * 0.3])
			var cerrado := petalo.duplicate()
			cerrado.append(petalo[0])
			lienzo.draw_polyline(cerrado, Color(CONTORNO, 0.8), 3.0, true)
			lienzo.draw_colored_polygon(petalo, rosa if capa == 0 else claro)
	lienzo.draw_circle(c + Vector2(0, 2), 15.0, Color(CONTORNO, 0.8))
	lienzo.draw_circle(c + Vector2(0, 2), 13.5, Color("#ffe58a") if abierta else Color("#ece6cc"))
	return c + Vector2(0, 2)


## El volcán dormilón echa nubecitas de humo (más lentas y grises mientras duerme).
func _dibujar_humito(lienzo: CanvasItem, centro: Vector2, tiempo: float, despierta: bool) -> void:
	var boca := centro + Vector2(0, -38)
	for k in 4:
		var t := fposmod(tiempo * (0.22 if despierta else 0.1) + k / 4.0, 1.0)
		var p := boca + Vector2(sin(t * 5.0 + k) * 8.0 + t * 16.0, -t * 70.0)
		var r := 7.0 + t * 12.0
		var color := Color(1, 1, 1, 0.75 * (1.0 - t)) if despierta else Color(0.92, 0.9, 0.88, 0.5 * (1.0 - t))
		lienzo.draw_circle(p, r, color)
		lienzo.draw_circle(p + Vector2(r * 0.7, r * 0.2), r * 0.7, color)


## Neblina tibia sobre el valle antes de revelarse (nunca candado): bancos que se mecen y un brillo.
func _dibujar_neblina(lienzo: CanvasItem, centro: Vector2, tiempo: float) -> void:
	for k in 6:
		var p := centro + Vector2(-70.0 + k * 28.0 + sin(tiempo * 0.5 + k) * 10.0, -20.0 + (k % 3) * 26.0)
		var r := 46.0 + (k % 2) * 14.0
		for a in 4:
			lienzo.draw_circle(p, r * (1.0 - a * 0.22), Color(1.0, 0.98, 0.94, 0.16))
	var pulso := 0.5 + 0.5 * sin(tiempo * 2.0)
	lienzo.draw_circle(centro + Vector2(0, -6), 12.0 + pulso * 4.0, Color(1.0, 0.9, 0.6, 0.25))


## Campamento: el nidito de Dinito con sus huevos (o Dinito, ya nacido) y las gemas del collar.
func _dibujar_campamento(lienzo: CanvasItem, centro: Vector2, tiempo: float, zona: Dictionary) -> void:
	var nido := centro + Vector2(-80, 60)
	if _dinito_vive:
		Animalitos.dibujar(lienzo, "dinito", nido + Vector2(0, 2), 44.0,
			{"dir": 1.0, "salto": absf(sin(tiempo * 3.2)) * 4.0, "estirar": sin(tiempo * 6.4) * 0.3})
	elif _huevos > 0 and not _equipo:
		lienzo.draw_circle(nido + Vector2(0, -2), 17.0, CONTORNO)
		lienzo.draw_colored_polygon(_elipse(nido + Vector2(0, -3), 16.0, 7.0), Color("#b98a52"))
		for k in _huevos:
			var p := nido + Vector2(-10.0 + k * 5.0, -10.0 - (k % 2) * 3.0)
			var meneo := sin(tiempo * 3.0 + k) * 0.15
			var huevo := _elipse(p, 5.0, 6.5, meneo)
			lienzo.draw_colored_polygon(_elipse(p, 6.2, 7.7, meneo), CONTORNO)
			lienzo.draw_colored_polygon(huevo, Color("#fff6e6") if zona["abierta"] else Color("#ece8de"))
			lienzo.draw_circle(p + Vector2(1.5, -1.5), 1.4, Color("#86d07e"))
			lienzo.draw_circle(p + Vector2(-1.5, 2.0), 1.1, Color("#86d07e"))
	if not _gemas.is_empty():
		# Collar de explorador (§6.3): la guirnalda de la carpa luce las gemas de las zonas perfectas.
		var izquierda := centro + Vector2(-50, -18)
		var derecha := centro + Vector2(50, -18)
		var guirnalda := PackedVector2Array()
		for k in 11:
			var t := k / 10.0
			guirnalda.append(izquierda.lerp(derecha, t) + Vector2(0, sin(t * PI) * 10.0))
		lienzo.draw_polyline(guirnalda, Color("#fff6e6"), 2.0, true)
		var colores := [Color("#ff6b6b"), Color("#4a8be0"), Color("#ffcb3d"), Color("#7dd87a"), Color("#b48ce8")]
		for k in _gemas.size():
			var t := (k + 1.0) / (_gemas.size() + 1.0)
			var p := izquierda.lerp(derecha, t) + Vector2(0, sin(t * PI) * 10.0 + 6.0)
			var gema := PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 7), p + Vector2(-5, 0)])
			lienzo.draw_colored_polygon(Geometry2D.offset_polygon(gema, 1.6)[0], CONTORNO)
			lienzo.draw_colored_polygon(gema, colores[int(_gemas[k]) % colores.size()])
			lienzo.draw_circle(p + Vector2(-1.5, -2), 1.3 + 0.5 * sin(tiempo * 4.0 + k), Color.WHITE)


func _elipse(c: Vector2, rx: float, ry: float, giro := 0.0) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for k in 18:
		var a := TAU * k / 18.0
		puntos.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(giro))
	return puntos


func _estrella(c: Vector2, r: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for k in 10:
		puntos.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * (r if k % 2 == 0 else r * 0.48))
	return puntos


# ---------------------------------------------------------------------------
# Gran Desfile (§6.1): ~12 s, se salta con un toque; al final Dinito queda viviendo en el campamento
# ---------------------------------------------------------------------------

func desfile_activo() -> bool:
	return _desfile_t >= 0.0


## Arma la fila (dinos adelante, hasta 4 animales por zona, Toby al final) y lo lanza tras la fiesta
## de la zona que pone el núcleo.
func _preparar_desfile() -> void:
	_desfile_t = 0.0
	_desfile_notas = 0
	_desfile_puf = false
	_marcha.clear()
	var x := 1360.0
	var grupo := 0
	for i in range(_zonas.size() - 1, -1, -1):
		var lista: Array = (_zonas[i]["datos"].get("desfile", []) as Array).filter(func(e) -> bool: return str(e) != "dinito").slice(0, 4)
		var primero := true
		for especie in lista:
			_marcha.append({"especie": str(especie), "x0": x, "grupo": grupo, "primero": primero})
			primero = false
			x += 62.0
		x += 34.0
		grupo += 1
	_marcha.append({"especie": "toby", "x0": x + 30.0, "grupo": grupo, "primero": true})
	_desfile_capa = CanvasLayer.new()
	_desfile_capa.name = "gran_desfile"
	_desfile_capa.layer = 30
	add_child(_desfile_capa)
	_desfile_lienzo = Control.new()
	_desfile_lienzo.mouse_filter = Control.MOUSE_FILTER_STOP
	_desfile_capa.add_child(_desfile_lienzo)
	_desfile_lienzo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_desfile_lienzo.draw.connect(_dibujar_desfile)
	_desfile_lienzo.gui_input.connect(func(evento: InputEvent) -> void:
		if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			terminar_desfile())
	print("[paisaje_animalia] Gran Desfile: %d en la fila" % _marcha.size())


func _avanzar_desfile(delta: float) -> void:
	_desfile_t += delta
	if _desfile_t >= 0.5 and _desfile_notas == 0:
		_sonar(SFX_FIESTA)
		_desfile_notas = 1
	# Cada grupo hace su nota al pasar por el medio de la pantalla (escalera afinada).
	for fila: Dictionary in _marcha:
		if fila["primero"] and not fila.get("sono", false) and _x_desfile(fila) < 900.0:
			fila["sono"] = true
			var grupo := int(fila["grupo"])
			_sonar(SFX_PASO, ESCALERA[mini(grupo, ESCALERA.size() - 1)])
	if not _desfile_puf and _desfile_t >= 9.4:
		_desfile_puf = true
		_sonar(SFX_PUF)
	if _desfile_lienzo != null:
		_desfile_lienzo.queue_redraw()
	if _desfile_t >= DURACION_DESFILE:
		terminar_desfile()


func _x_desfile(fila: Dictionary) -> float:
	var x := float(fila["x0"]) - maxf(0.0, _desfile_t - 0.6) * 250.0
	if fila["especie"] == "toby":
		# Toby se queda al medio con su pose orgullosa.
		x = maxf(x, 640.0)
	return x


## Termina (o se salta) el Gran Desfile: Dinito nace y queda viviendo en el campamento. Se marca al terminar.
func terminar_desfile() -> void:
	if _desfile_t < 0.0:
		return
	_desfile_t = -1.0
	if _desfile_capa != null:
		_desfile_capa.queue_free()
	_desfile_capa = null
	_desfile_lienzo = null
	_dinito_vive = true
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and _perfil != "":
		progreso.marcar_especial_conocido(_perfil, ESPECIAL_DESFILE)


func _dibujar_desfile() -> void:
	var lienzo := _desfile_lienzo
	var t := _desfile_t
	var entrada := clampf(t / 0.8, 0.0, 1.0) * clampf((DURACION_DESFILE - t) / 0.6, 0.0, 1.0)
	lienzo.draw_rect(Rect2(0, 0, 1280, 720), Color(0.12, 0.2, 0.08, 0.32 * entrada))
	# Confeti del volcán (zona 5).
	if not _zonas.is_empty():
		var volcan: Vector2 = Vector2((_zonas[_zonas.size() - 1]["datos"].get("posicion", [1160, 236]) as Array)[0], (_zonas[_zonas.size() - 1]["datos"].get("posicion", [1160, 236]) as Array)[1]) + Vector2(0, -40)
		for k in 36:
			var vida := fposmod(t * 0.6 + k / 36.0, 1.0)
			var ang := -PI / 2.0 + (k % 9 - 4) * 0.22
			var p := volcan + Vector2.from_angle(ang) * vida * 180.0 + Vector2(0, vida * vida * 220.0)
			var color: Color = [Color("#ff6b6b"), Color("#ffcb3d"), Color("#7dd87a"), Color("#4a8be0"), Color("#b48ce8"), Color("#ff9ec4")][k % 6]
			lienzo.draw_rect(Rect2(p, Vector2(6, 9)).abs(), Color(color, (1.0 - vida) * entrada))
	# Suelo del desfile: una alfombra de pasto con huellitas doradas.
	lienzo.draw_rect(Rect2(0, 632, 1280, 88), Color(0.5, 0.78, 0.38, 0.85 * entrada))
	for k in 20:
		_huellita(lienzo, Vector2(fposmod(k * 70.0 - t * 40.0, 1400.0) - 60.0, 700.0), PI, 1.3, Color(ORO, entrada), Color(ORO_BORDE, entrada))
	# La fila.
	for n in range(_marcha.size() - 1, -1, -1):
		var fila: Dictionary = _marcha[n]
		var x := _x_desfile(fila)
		if x < -90.0 or x > 1380.0:
			continue
		var paso := t * 10.0 + n
		if fila["especie"] == "toby":
			if _textura_toby != null:
				var quieto := x <= 640.5
				var salto := absf(sin(t * (6.0 if quieto else 10.0))) * (18.0 if quieto else 6.0)
				var tam := Vector2(80, 145)
				lienzo.draw_texture_rect(_textura_toby, Rect2(Vector2(x, 676.0 - salto) - Vector2(tam.x / 2.0, tam.y), tam), false)
			continue
		Animalitos.dibujar(lienzo, str(fila["especie"]), Vector2(x, 676), 58.0, {"dir": -1.0, "paso": paso, "salto": absf(sin(paso)) * 5.0})
	# Dinito nace junto a la carpa (zona 1) al final.
	if not _zonas.is_empty():
		var posicion: Array = _zonas[0]["datos"].get("posicion", [330, 556])
		var nido := Vector2(float(posicion[0]), float(posicion[1])) + Vector2(-80, 60)
		if t >= 7.6 and t < 9.4:
			var meneo := sin(t * 18.0) * 0.25 * clampf((t - 7.6) / 1.0, 0.0, 1.0)
			lienzo.draw_colored_polygon(_elipse(nido + Vector2(0, -18), 16.0, 21.0, meneo), CONTORNO)
			lienzo.draw_colored_polygon(_elipse(nido + Vector2(0, -18), 14.0, 19.0, meneo), Color("#fff6e6"))
			lienzo.draw_circle(nido + Vector2(4, -24), 3.0, Color("#86d07e"))
			lienzo.draw_circle(nido + Vector2(-5, -12), 2.5, Color("#86d07e"))
		elif t >= 9.4:
			var nacer := clampf((t - 9.4) / 0.5, 0.0, 1.0)
			for k in 10:
				var chispa := nido + Vector2(0, -20) + Vector2.from_angle(TAU * k / 10.0) * (20.0 + nacer * 40.0)
				lienzo.draw_colored_polygon(_estrella(chispa, 6.0 * (1.0 - nacer * 0.6)), Color(ORO, 1.0 - nacer * 0.5))
			Animalitos.dibujar(lienzo, "dinito", nido, 52.0 * (0.4 + 0.6 * nacer), {"dir": 1.0, "salto": absf(sin(t * 7.0)) * 8.0})


# ---------------------------------------------------------------------------
# Sonido
# ---------------------------------------------------------------------------

func _sonar(ruta: String, tono := 1.0) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta, tono)


func _decir(ruta: String) -> void:
	if ruta == "":
		return
	print("[voz:mapa] %s" % ruta)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta if ruta.begins_with("res://") else PREFIJO_AUDIO + ruta)
