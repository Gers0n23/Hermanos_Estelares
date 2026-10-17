extends Control

## Barra del equipo (docs/fichas/modo-equipo.md §4.1 y §4.3; HE-59): la nave de juguete del living, de
## perfil, con un retrato por hermano en sus ventanitas, en el orden de los turnos. La maneja el
## `GestorTurnos`: no sabe de cartas ni de ningun juego.
##
## - Quien juega: retrato al 130 %, aura de su color, foco suave y respiracion lenta.
## - Quienes miran: retrato al 100 %, despiertos. Tocarlos es la "ventanita de porra" (M3.1): aplauden o
##   hacen su gesto corto (0,6 s) con un sonido suave; no tocan el tablero; enfriamiento de 1 s.
## - El pase: el retrato de quien sigue vuela de su ventanita al centro (~260 px) y espera la puerta.
## - Nunca hay numeros, gotitas ni marcadores bajo los retratos (R2), y nadie pone cara de decepcion (B2).
##
## Arte provisional dibujado por codigo (nave, ventanitas, aura) hasta que `disenador-personajes` entregue
## la nave de juguete y los gestos cortos (§10). Las caras salen de los retratos oficiales.

const RECT_BARRA := Rect2(0, 610, 1280, 110)
const LADO_VENTANITA := 96.0
## Centro y de las ventanitas: el area tocable empieza en y >= 614 (N12) y mide >= 96 px.
const Y_VENTANITA := 662.0
const PASO_VENTANITAS := 168.0
const LADO_CENTRO := 260.0
const CENTRO_PUERTA := Vector2(640, 364)
const MARGEN_PUERTA := 20.0
const IMAN_VENTANITA := 80.0
## Al 130 % el retrato de quien juega sube un poco para no cortarse con el borde inferior de la pantalla.
const ALZA_ACTIVO := 12.0
const ENFRIAMIENTO_PORRA_MS := 1000
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const RETRATOS := {
	"maxi": "res://assets/sprites/personajes/maxi_base.png",
	"nicole": "res://assets/sprites/personajes/nicole_base.png",
	"sofia": "res://assets/sprites/personajes/sofia_base.png",
}
const SHADER_DISCO := "res://assets/shaders/disco_circular.gdshader"

static var _caras := {}

## Ids en el orden de las ventanitas (orden de los turnos, sin repetir).
var ids: Array[String] = []
## id -> Color del turno (m1).
var colores: Dictionary = {}

var _ventanitas := {}
var _actual := ""
var _en_centro := ""
var _tiempo := 0.0
var _ultimo_porra := {}
var _flechita := false
var _destello := {}


## Cara recortada del retrato oficial (512x768, mismo recorte que el mapa), en cache.
static func cara(id: String) -> Texture2D:
	if _caras.has(id):
		return _caras[id]
	var ruta: String = RETRATOS.get(id, "")
	var textura: Texture2D = null
	if ruta != "" and ResourceLoader.exists(ruta):
		var imagen: Image = (load(ruta) as Texture2D).get_image()
		if imagen != null and imagen.get_width() >= 366 and imagen.get_height() >= 282:
			textura = ImageTexture.create_from_image(imagen.get_region(Rect2i(146, 62, 220, 220)))
		else:
			textura = load(ruta)
	_caras[id] = textura
	return textura


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(1280, 720)


func preparar(lista: Array[String], colores_turno: Dictionary) -> void:
	ids = lista
	colores = colores_turno
	for hijo in get_children():
		hijo.queue_free()
	_ventanitas.clear()
	var inicio := 640.0 - (ids.size() - 1) * PASO_VENTANITAS / 2.0
	for i in ids.size():
		var id := ids[i]
		var v := _crear_retrato(id, LADO_VENTANITA)
		v.set_meta("base", Vector2(inicio + i * PASO_VENTANITAS, Y_VENTANITA))
		_ventanitas[id] = v
		add_child(v)
		_ubicar(v, v.get_meta("base"), 1.0)
	queue_redraw()


func _crear_retrato(id: String, lado: float) -> Control:
	var raiz := Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.size = Vector2.ONE * lado
	raiz.pivot_offset = raiz.size / 2.0
	raiz.set_meta("id", id)
	raiz.draw.connect(_dibujar_marco.bind(raiz))
	var foto := TextureRect.new()
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foto.texture = cara(id)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foto.position = Vector2.ONE * 7.0
	foto.size = raiz.size - Vector2.ONE * 14.0
	if ResourceLoader.exists(SHADER_DISCO):
		var mascara := ShaderMaterial.new()
		mascara.shader = load(SHADER_DISCO)
		foto.material = mascara
	raiz.add_child(foto)
	return raiz


func _ubicar(nodo: Control, centro: Vector2, escala: float) -> void:
	nodo.position = centro - nodo.size / 2.0
	nodo.scale = Vector2.ONE * escala


func _process(delta: float) -> void:
	_tiempo += delta
	for id in _ventanitas:
		var v: Control = _ventanitas[id]
		if id == _actual and _en_centro == "":
			# Respiracion lenta de quien juega. Al 130 % el dibujo sube 12 px para no cortarse contra el borde de
			# abajo (solo visual: el retrato de quien juega no es tocable).
			v.scale = Vector2.ONE * (1.3 + 0.03 * sin(_tiempo * TAU / 2.4))
		v.queue_redraw()
	queue_redraw()


func _draw() -> void:
	# Nave de juguete de perfil (provisional): casco redondo, punta a la derecha, aletas y fuego dormido.
	var casco := Rect2(150, 620, 980, 96)
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#E9EEF8")
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(5)
	caja.set_corner_radius_all(48)
	caja.corner_radius_top_right = 90
	caja.corner_radius_bottom_right = 90
	caja.anti_aliasing = true
	caja.shadow_color = Color(COLOR_CONTORNO, 0.25)
	caja.shadow_size = 6
	caja.shadow_offset = Vector2(0, 4)
	draw_style_box(caja, casco)
	var franja := PackedVector2Array([Vector2(190, 700), Vector2(1080, 700), Vector2(1060, 710), Vector2(200, 710)])
	draw_colored_polygon(franja, Color("#F26CA8"))
	for k in 2:
		var y := 628.0 if k == 0 else 708.0
		var aleta := PackedVector2Array([Vector2(170, y), Vector2(120, y + (-26 if k == 0 else 26)), Vector2(230, y)])
		draw_colored_polygon(aleta, Color("#45C6C0"))
		draw_polyline(aleta + PackedVector2Array([aleta[0]]), COLOR_CONTORNO, 4.0, true)
	# Flechita de estrellitas (puerta de arrastre): del retrato del centro a su ventanita vacia.
	if _flechita and _en_centro != "" and _ventanitas.has(_en_centro):
		var desde := CENTRO_PUERTA + Vector2(0, LADO_CENTRO * 0.45)
		var hasta: Vector2 = _ventanitas[_en_centro].get_meta("base")
		var pasos := 6
		for i in pasos:
			var t := fmod(i / float(pasos) + _tiempo * 0.6, 1.0)
			var punto := desde.lerp(hasta, t)
			var r := 7.0 + 4.0 * sin(t * PI)
			_estrella(punto, r, Color(DORADO, 0.4 + 0.6 * sin(t * PI)))
		# La ventanita vacia brilla.
		draw_circle(hasta, LADO_VENTANITA * 0.55 + 4.0 * sin(_tiempo * 5.0), Color(DORADO, 0.35))


func _dibujar_marco(nodo: Control) -> void:
	var id: String = nodo.get_meta("id")
	var color: Color = colores.get(id, Color.WHITE)
	var centro := nodo.size / 2.0
	var radio := nodo.size.x / 2.0
	var juega := id == _actual
	if juega:
		# Aura de su color y foco suave encima (m1: el aura de Sofia nunca es rosa).
		for k in 4:
			nodo.draw_circle(centro, radio + 12.0 - k * 3.0, Color(color, 0.12 + k * 0.05))
	if _destello.has(id):
		nodo.draw_circle(centro, radio + 8.0, Color(DORADO, 0.55))
	nodo.draw_circle(centro, radio - 2.0, Color("#FFF8EE"))
	nodo.draw_arc(centro, radio - 4.0, 0.0, TAU, 48, color, 6.0 if juega else 4.0, true)
	nodo.draw_arc(centro, radio - 1.0, 0.0, TAU, 48, COLOR_CONTORNO, 2.5, true)


func _estrella(centro: Vector2, radio: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 10:
		var r := radio if i % 2 == 0 else radio * 0.5
		puntos.append(centro + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * r)
	draw_colored_polygon(puntos, color)


# ---------------------------------------------------------------------------
# Lo que pide el gestor
# ---------------------------------------------------------------------------

## Quien juega ahora (o "" en el pase).
func fijar_actual(id: String) -> void:
	_actual = id
	for otro in _ventanitas:
		if otro != id and otro != _en_centro:
			var v: Control = _ventanitas[otro]
			v.create_tween().tween_property(v, "scale", Vector2.ONE, 0.25)


## Paso 2 del pase: el retrato vuela de su ventanita al centro, grande, con un "fiuu".
func volar_al_centro(id: String, segundos := 0.6) -> void:
	if not _ventanitas.has(id):
		return
	_en_centro = id
	_actual = ""
	# Quien jugo antes vuelve a su tamano de "mira" (100 %) y a su ventanita.
	for otro in _ventanitas:
		if otro != id:
			var w: Control = _ventanitas[otro]
			var t := w.create_tween().set_parallel(true)
			t.tween_property(w, "scale", Vector2.ONE, 0.25)
			t.tween_property(w, "position", w.get_meta("base") - w.size / 2.0, 0.25)
	var v: Control = _ventanitas[id]
	move_child(v, -1)
	var escala := LADO_CENTRO / LADO_VENTANITA
	var destino := CENTRO_PUERTA - v.size / 2.0
	var tween := v.create_tween().set_parallel(true)
	tween.tween_property(v, "position", destino, segundos).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(v, "scale", Vector2.ONE * escala, segundos).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Paso 4: el retrato vuelve blandito a su ventanita (que destella) y empieza el turno.
func volver_a_ventanita(id: String, segundos := 0.4) -> void:
	if not _ventanitas.has(id):
		return
	_en_centro = ""
	_flechita = false
	_actual = id
	var v: Control = _ventanitas[id]
	var base: Vector2 = v.get_meta("base")
	var tween := v.create_tween().set_parallel(true)
	tween.tween_property(v, "position", base - v.size / 2.0 - Vector2(0, ALZA_ACTIVO), segundos).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(v, "scale", Vector2.ONE * 1.3, segundos).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	destellar(id)


## Derrota-gag: el retrato del centro se achica (~210 px) y sube para dejar ver el gag (storyboard §11).
func achicar_centro() -> void:
	if _en_centro == "":
		return
	var v: Control = _ventanitas[_en_centro]
	var escala := 210.0 / LADO_VENTANITA
	var tween := v.create_tween().set_parallel(true)
	tween.tween_property(v, "position", Vector2(640, 250) - v.size / 2.0, 0.4)
	tween.tween_property(v, "scale", Vector2.ONE * escala, 0.4)


## Tras "¡otra vez!": el retrato vuelve al centro de la puerta.
func centrar_de_nuevo() -> void:
	if _en_centro == "":
		return
	var v: Control = _ventanitas[_en_centro]
	var tween := v.create_tween().set_parallel(true)
	tween.tween_property(v, "position", CENTRO_PUERTA - v.size / 2.0, 0.3)
	tween.tween_property(v, "scale", Vector2.ONE * LADO_CENTRO / LADO_VENTANITA, 0.3)


func mostrar_flechita(valor: bool) -> void:
	_flechita = valor


## Un toque fuera del retrato de la puerta: el retrato salta (y el gestor repite "¡le toca a…!").
func saltar_centro() -> void:
	if _en_centro == "":
		return
	var v: Control = _ventanitas[_en_centro]
	var base := v.position
	var tween := v.create_tween()
	tween.tween_property(v, "position:y", base.y - 26.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(v, "position:y", base.y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Arrastre del retrato de la puerta (B1.2): sigue al dedo.
func mover_centro_a(punto: Vector2) -> void:
	if _en_centro == "":
		return
	var v: Control = _ventanitas[_en_centro]
	v.position = punto - v.size / 2.0


## Si el dedo se suelta lejos de la ventanita, el retrato vuelve blandito al centro (sin sonido de error).
func soltar_centro_lejos() -> void:
	centrar_de_nuevo()


func distancia_a_ventanita(id: String, punto: Vector2) -> float:
	if not _ventanitas.has(id):
		return INF
	return punto.distance_to(_ventanitas[id].get_meta("base"))


## Hitbox de la puerta: el dibujo de 260 px + 20 px de margen por lado (B1.1).
func rect_puerta() -> Rect2:
	var lado := LADO_CENTRO + MARGEN_PUERTA * 2.0
	return Rect2(CENTRO_PUERTA - Vector2.ONE * lado / 2.0, Vector2.ONE * lado)


## Area tocable de la ventanita de un hermano: >= 96 x 96 px y desde y >= 614 (N12).
func rect_ventanita(id: String) -> Rect2:
	if not _ventanitas.has(id):
		return Rect2()
	var base: Vector2 = _ventanitas[id].get_meta("base")
	return Rect2(base - Vector2.ONE * LADO_VENTANITA / 2.0, Vector2.ONE * LADO_VENTANITA)


func destellar(id: String) -> void:
	_destello[id] = true
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(func() -> void: _destello.erase(id))


## Gesto corto (0,6 s) de un hermano: saltito con giro suave. Arte final: `disenador-personajes`.
func gesto(id: String) -> void:
	if not _ventanitas.has(id):
		return
	var v: Control = _ventanitas[id]
	var base_y: float = v.position.y if id == _en_centro else (v.get_meta("base") - v.size / 2.0).y - (ALZA_ACTIVO if id == _actual else 0.0)
	var tween := v.create_tween()
	tween.tween_property(v, "rotation", deg_to_rad(-10.0), 0.15)
	tween.parallel().tween_property(v, "position:y", base_y - 18.0, 0.15)
	tween.tween_property(v, "rotation", deg_to_rad(10.0), 0.15)
	tween.tween_property(v, "rotation", 0.0, 0.15)
	tween.parallel().tween_property(v, "position:y", base_y, 0.15).set_trans(Tween.TRANS_BOUNCE)


## Con cada acierto, quienes miran aplauden (saltitos) y quien juega hace su gesto.
func aplaudir(excepto: String) -> void:
	for id in _ventanitas:
		if id == excepto or id == _en_centro:
			continue
		var v: Control = _ventanitas[id]
		var base: Vector2 = v.get_meta("base") - v.size / 2.0
		var tween := v.create_tween()
		for k in 2:
			tween.tween_property(v, "position:y", base.y - 10.0, 0.1)
			tween.tween_property(v, "position:y", base.y, 0.1)


## Con cada "no es este", SOLO animo (B2): se mecen suave, como cruzando los dedos. Nunca decepcion.
func animar_animo(excepto: String) -> void:
	for id in _ventanitas:
		if id == excepto or id == _en_centro:
			continue
		var v: Control = _ventanitas[id]
		var tween := v.create_tween()
		for angulo in [6.0, -6.0, 3.0, 0.0]:
			tween.tween_property(v, "rotation", deg_to_rad(angulo), 0.12)


## Ventanita de porra (M3.1): devuelve true si el toque fue en el retrato de alguien que mira y no esta
## enfriandose. El retrato de quien juega no es tocable.
func tocar_porra(punto: Vector2) -> String:
	for id in _ventanitas:
		if id == _actual or id == _en_centro:
			continue
		if rect_ventanita(id).has_point(punto):
			var ahora := Time.get_ticks_msec()
			if ahora - int(_ultimo_porra.get(id, -ENFRIAMIENTO_PORRA_MS)) < ENFRIAMIENTO_PORRA_MS:
				return ""
			_ultimo_porra[id] = ahora
			gesto(id)
			return id
	return ""


## Ritual de fin de turno de Maxi (paso 0, M3.3): su ventanita destella y el retrato rebota.
func ritual_fin_semilla(id: String) -> void:
	destellar(id)
	gesto(id)
