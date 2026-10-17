extends Node2D
## PRUEBA DE CONCEPTO (no es una tarjeta del tablero): los Hermanos Estelares llegan al
## Planeta Arcoíris y conocen a la Camaleona Coco. Coco les cuenta, en un recuerdo, qué hizo
## el Coleccionauta en su planeta, y les propone el trato: si la ayudan a encontrar los
## colores escondidos, pinta el ala que la nave necesita.
##
## Todo por código, sobre arte ya existente:
##   - Los tres hermanos usan sus rigs cutout reales (escenas/personajes/vista_previa_rig_*),
##     con poses (saludo, sorpresa, celebrar) mezcladas por código y saltitos con aplaste.
##   - Coco: PNG plano + shader `personaje` (gelatina, cambio de color SOLO de la piel, que es
##     su tic, y camuflaje para aparecer de la nada) + párpados dibujados.
##   - Cámara que encuadra a quien habla (suavizada y sin salirse del fondo).
##   - El recuerdo vive en un SubViewport y se ve dentro de una burbuja de pensamiento que sale
##     de la cabeza de Coco (shader `recuerdo`). Ahí el planeta tiene color, y una onda
##     (shader `saturacion`) se lo quita cuando los colores se escapan.
##   - Gotitas de color con carita, chupetines y el ala, dibujados por código.
##   - Música que baja sola cuando alguien habla (ducking).
##
## Voces: PROVISORIAS, TTS de Windows con el tono cambiado por personaje (gratis). El texto
## está en `guion_conocen_coco.md`; pasa por `guionista` antes de generar las oficiales.
##
## Controles: tocar/clic = chispita la primera vez, saltar desde la segunda;
## al terminar, tocar = repetir. Tecla R = repetir.

const TEX_CLARO := preload("res://poc/cinematica_codigo/arte/claro_trebol.png")
const TEX_COLEC := preload("res://poc/cinematica_codigo/arte/coleccionauta.png")
const TEX_COCO := preload("res://assets/sprites/personajes/coco_base.png")
const TEX_COMETA := preload("res://assets/sprites/personajes/cometa_base.png")
const TEX_NAVE := preload("res://assets/sprites/nave/nave_estrella.png")
const SHADER_PERSONAJE := preload("res://poc/cinematica_codigo/personaje.gdshader")
const SHADER_SATURACION := preload("res://poc/cinematica_codigo/saturacion.gdshader")
const SHADER_RECUERDO := preload("res://poc/cinematica_codigo/recuerdo.gdshader")
const SHADER_IRIS := preload("res://poc/cinematica_codigo/iris.gdshader")

const VOCES := "res://poc/cinematica_codigo/voces/"
const MUSICA := "res://assets/audio/musica/llegada_planeta.ogg"
const SFX_TILIN := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_FIUU := "res://assets/audio/sfx/ui/fiuu.ogg"
const SFX_BOTE := "res://assets/audio/sfx/ui/blup.ogg"
const SFX_PUF := "res://assets/audio/sfx/ui/puf.ogg"
const SFX_POP := "res://assets/audio/sfx/ui/abrir.ogg"
const SFX_MAGIA := "res://assets/audio/sfx/viaje/poder.ogg"
const SFX_REPARADA := "res://assets/audio/sfx/viaje/reparada.ogg"
const SFX_SELECCION := "res://assets/audio/sfx/ui/seleccionar.ogg"

# Presente (pantalla 1280x720; el fondo ocupa justo la pantalla).
const NAVE_POS := Vector2(195, 585)
const ESCOTILLA := Vector2(255, 540)
const POS_SOFIA := Vector2(350, 668)
const POS_NICOLE := Vector2(472, 664)
const POS_MAXI := Vector2(578, 660)
const POS_COMETA := Vector2(676, 612)
const POS_COCO := Vector2(910, 656)
const POS_CHUPETIN := Vector2(1150, 652)
const POS_ALA := Vector2(1060, 262)

# Recuerdo (mismas coordenadas, dentro del SubViewport).
const ARCO_CENTRO := Vector2(640, 428)
const ARCO_RADIOS := Vector2(319, 410)
const POS_CHUPETIN_GRANDE := Vector2(790, 650)
const POS_COLEC := Vector2(1000, 640)
const MOCHILA := Vector2(-130, -235)  # boca de la mochila, en píxeles del PNG desde los pies
const COLORES := [Color("#ff6b6b"), Color("#ffa94d"), Color("#ffe066"), Color("#69db7c"),
	Color("#4dabf7"), Color("#b197fc")]
const ESCONDITES := [Vector2(590, 566), Vector2(1019, 420), Vector2(790, 330), Vector2(120, 262),
	Vector2(933, 505), Vector2(870, 58)]

# Poses de los hermanos: [brazo_izq, brazo_der, antebrazo_izq, antebrazo_der] (radianes).
const POSES := {
	"reposo": [0.0, 0.0, 0.0, 0.0],
	"saludo": [0.05, -1.05, 0.0, -0.6],
	"sorpresa": [0.8, -0.8, 0.55, -0.55],
	"celebra": [2.45, -2.45, 0.35, -0.35],
}

var _generacion := 0
var _tweens: Array[Tween] = []
var _vista_antes := false
var _terminada := false
var _trauma := 0.0
var _hablante := ""
var _bus_voz := -1
var _cam_pos := Vector2(640, 360)
var _cam_zoom := 1.0

var camara: Camera2D
var mat_fondo: ShaderMaterial
var nave: Node2D
var estela: CPUParticles2D
var hermanos: Array[Hermano] = []
var sofia: Hermano
var nicole: Hermano
var maxi: Hermano
var coco: Actor
var cometa: Actor
var chupetin: Chupetin
var gotita_roja: Gotita
var ala: Ala
var burbujas: Array[Node2D] = []

var recuerdo_vp: SubViewport
var recuerdo_rect: TextureRect
var mat_recuerdo: ShaderMaterial
var mat_fondo_rec: ShaderMaterial
var cam_rec: Camera2D
var colec: Actor
var jet: CPUParticles2D
var chupetin_grande: Chupetin
var gotitas: Array[Gotita] = []
var capa_chorro: Node2D

var iris: ColorRect
var voz: AudioStreamPlayer
var musica: AudioStreamPlayer


# ---------------------------------------------------------------- piezas dibujadas por código

class Estrella extends Node2D:
	var puntas := 5
	var radio_ext := 40.0
	var radio_int := 18.0
	var relleno := Color(1.0, 0.86, 0.3)
	var borde := Color(0.6, 0.38, 0.12)

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in puntas * 2:
			var r := radio_ext if i % 2 == 0 else radio_int
			var a := -PI / 2.0 + i * PI / puntas
			pts.append(Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, relleno)
		pts.append(pts[0])
		draw_polyline(pts, borde, 3.0, true)


class Nube extends Node2D:
	const BOLAS := [[Vector2(0, 0), 40.0], [Vector2(-40, 10), 30.0], [Vector2(40, 10), 30.0],
		[Vector2(-20, -24), 28.0], [Vector2(22, -22), 31.0]]

	func _draw() -> void:
		for b in BOLAS:
			draw_circle(b[0], b[1] + 4.0, Color(0.62, 0.55, 0.66))
		for b in BOLAS:
			draw_circle(b[0], b[1], Color(1, 0.98, 0.95))


class Burbuja extends Node2D:
	var radio := 12.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radio + 3.0, Color(0.55, 0.5, 0.62))
		draw_circle(Vector2.ZERO, radio, Color(1, 0.99, 0.97))
		draw_circle(Vector2(-radio * 0.35, -radio * 0.35), radio * 0.25, Color(1, 1, 1))


class Parpado extends Node2D:
	var radio := Vector2(24, 25)
	var piel := Color(0.87, 0.65, 0.73)
	var cierre := 0.0:
		set(v):
			cierre = v
			queue_redraw()

	func _draw() -> void:
		if cierre <= 0.02:
			return
		var k := clampf(-1.0 + 2.0 * cierre, -1.0, 1.0)
		var a0 := PI - asin(k)
		var a1 := TAU + asin(k)
		var pts := PackedVector2Array()
		for i in 25:
			var a := lerpf(a0, a1, i / 24.0)
			pts.append(Vector2(cos(a) * radio.x, sin(a) * radio.y))
		draw_colored_polygon(pts, piel)
		var y := k * radio.y
		var w := radio.x * cos(asin(k))
		draw_line(Vector2(-w, y), Vector2(w, y), Color(0.25, 0.13, 0.15), 3.0, true)


## Chupetín de espiral (el hito de la zona 3). `gris` lo apaga para el planeta sin color.
class Chupetin extends Node2D:
	var alto := 240.0
	var radio := 64.0
	var color_a := Color("#ff8fab")
	var color_b := Color("#fff3b0")
	var gris := 0.0:
		set(v):
			gris = v
			queue_redraw()

	func _apagar(c: Color) -> Color:
		var g := (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) * 0.8
		return c.lerp(Color(g, g, g), gris)

	func _draw() -> void:
		var palo := Rect2(-7, -alto, 14, alto)
		draw_rect(palo.grow(3), _apagar(Color("#8a6a55")))
		draw_rect(palo, _apagar(Color("#fff8ec")))
		var c := Vector2(0, -alto)
		draw_circle(c, radio + 4.0, _apagar(Color("#8a5a6a")))
		draw_circle(c, radio, _apagar(color_a))
		var espiral := PackedVector2Array()
		for i in 90:
			var t := i / 89.0
			var a := t * TAU * 2.6
			espiral.append(c + Vector2(cos(a), sin(a)) * radio * 0.92 * t)
		draw_polyline(espiral, _apagar(color_b), radio * 0.2, true)
		draw_circle(c + Vector2(-radio * 0.4, -radio * 0.45), radio * 0.16, Color(1, 1, 1, 0.55))


## Gotita de color con carita: así se ven los colores escondidos (contentos, nunca robados).
class Gotita extends Node2D:
	var color := Color.RED
	var radio := 18.0
	var feliz := 0.0  # 0..1: de sonrisa a risita con los ojos cerrados

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var d := radio * 1.9
		var ang := acos(radio / d)
		var pts := PackedVector2Array([Vector2(0, -d)])
		for i in 23:
			var a := lerpf(-PI / 2.0 + ang, -PI / 2.0 - ang + TAU, i / 22.0)
			pts.append(Vector2(cos(a), sin(a)) * radio)
		var contorno := pts.duplicate()
		contorno.append(pts[0])
		draw_colored_polygon(pts, color)
		draw_polyline(contorno, color.darkened(0.45), 2.5, true)
		draw_circle(Vector2(-radio * 0.35, -radio * 0.75), radio * 0.18, Color(1, 1, 1, 0.7))
		var ojo := radio * 0.17
		for lado in [-1.0, 1.0]:
			var o := Vector2(lado * radio * 0.33, -radio * 0.05)
			if feliz > 0.5:
				draw_arc(o + Vector2(0, ojo * 0.4), ojo, PI, TAU, 8, Color(0.15, 0.1, 0.15), 2.0, true)
			else:
				draw_circle(o, ojo, Color(0.15, 0.1, 0.15))
				draw_circle(o + Vector2(-ojo * 0.3, -ojo * 0.35), ojo * 0.35, Color.WHITE)
		draw_arc(Vector2(0, radio * 0.28), radio * (0.25 + 0.12 * feliz), 0.15, PI - 0.15, 10,
			Color(0.15, 0.1, 0.15), 2.0, true)


## El ala de la nave: cuatro franjas que pasan de gris a su color (`pintado` 0..1 por franja).
## Ala en flecha: raíz ancha (A-D) y punta angosta (B-C).
class Ala extends Node2D:
	const A := Vector2(-150, -10)
	const B := Vector2(135, -78)
	const C := Vector2(158, -36)
	const D := Vector2(-128, 112)
	const COLORES_ALA := [Color("#ff8a8a"), Color("#ffe27a"), Color("#9be3b0"), Color("#8ec9ff")]
	var pintado: Array = [0.0, 0.0, 0.0, 0.0]

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var contorno := PackedVector2Array([A, B, C, D, A])
		draw_colored_polygon(PackedVector2Array([A + Vector2(4, 8), B + Vector2(4, 8),
			C + Vector2(4, 8), D + Vector2(4, 8)]), Color(0, 0, 0, 0.12))
		for i in 4:
			var t0 := i / 4.0
			var t1 := (i + 1) / 4.0
			var gris := Color(0.72, 0.72, 0.75).lerp(Color(0.62, 0.62, 0.66), float(i % 2))
			draw_colored_polygon(PackedVector2Array([A.lerp(D, t0), B.lerp(C, t0), B.lerp(C, t1),
				A.lerp(D, t1)]), gris.lerp(COLORES_ALA[i], pintado[i]))
		draw_polyline(contorno, Color(0.35, 0.33, 0.4), 5.0, true)
		var centro := (A + B + C + D) / 4.0
		var pts := PackedVector2Array()
		for i in 10:
			var r := 22.0 if i % 2 == 0 else 9.0
			var a := -PI / 2.0 + i * PI / 5.0
			pts.append(centro + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------- actores

## Personaje de arte plano: `raiz` lleva la posición (los pies), saltos y aplastes;
## `cuerpo` respira y "habla" con el volumen de la voz.
class Actor:
	var raiz: Node2D
	var cuerpo: Sprite2D
	var mat: ShaderMaterial
	var parpados: Array[Parpado] = []
	var flotar := 0.0


## Hermano con su rig cutout. `pivote` está en los pies; el rig cuelga de él.
class Hermano:
	var pivote: Node2D
	var cadera: Node2D
	var torso: Node2D
	var cabeza: Node2D
	var brazo_izq: Node2D
	var brazo_der: Node2D
	var ante_izq: Node2D
	var ante_der: Node2D
	var escala := 0.4
	var fase := 0.0
	var pose := "reposo"
	var mirar := 0.0
	var destino := Vector2.ZERO


# ---------------------------------------------------------------- armado

func _ready() -> void:
	_armar_presente()
	_armar_recuerdo()
	_armar_capas()
	_preparar_bus_voz()
	reproducir()


func _armar_presente() -> void:
	camara = Camera2D.new()
	camara.position = _cam_pos
	add_child(camara)
	camara.make_current()

	var fondo := Sprite2D.new()
	fondo.texture = TEX_CLARO
	fondo.position = Vector2(640, 360)
	mat_fondo = ShaderMaterial.new()
	mat_fondo.shader = SHADER_SATURACION
	fondo.material = mat_fondo
	add_child(fondo)

	# Motas grises que flotan: el planeta está "dormido", no muerto.
	var motas := _particulas(Color(1, 1, 1, 0.5), 30, 8.0)
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motas.position = Vector2(640, 420)
	motas.emission_rect_extents = Vector2(640, 260)
	motas.gravity = Vector2(0, -3)
	motas.initial_velocity_min = 2.0
	motas.initial_velocity_max = 6.0
	motas.scale_amount_min = 0.03
	motas.scale_amount_max = 0.06
	motas.preprocess = 8.0
	add_child(motas)

	chupetin = Chupetin.new()
	chupetin.position = POS_CHUPETIN
	chupetin.alto = 230.0
	chupetin.radio = 66.0
	chupetin.gris = 1.0
	add_child(chupetin)
	# La gotita roja se esconde DETRÁS del chupetín: va antes en el árbol.
	gotita_roja = Gotita.new()
	gotita_roja.color = COLORES[0]
	gotita_roja.radio = 26.0
	add_child(gotita_roja)
	move_child(gotita_roja, chupetin.get_index())

	nave = Node2D.new()
	add_child(nave)
	estela = _particulas(Color(1.0, 0.85, 0.4), 80, 0.9)
	estela.local_coords = false
	estela.position = Vector2(-150, 30)
	estela.spread = 25.0
	estela.initial_velocity_min = 20.0
	estela.initial_velocity_max = 50.0
	estela.scale_amount_min = 0.08
	estela.scale_amount_max = 0.18
	estela.emitting = false
	nave.add_child(estela)
	var nave_spr := Sprite2D.new()
	nave_spr.texture = TEX_NAVE
	nave.add_child(nave_spr)

	sofia = _crear_hermano("sofia", 0.47, 0.0)
	nicole = _crear_hermano("nicole", 0.40, 1.7)
	maxi = _crear_hermano("maxi", 0.33, 3.1)
	sofia.destino = POS_SOFIA
	nicole.destino = POS_NICOLE
	maxi.destino = POS_MAXI

	cometa = _crear_actor(TEX_COMETA, Vector2(-240, -500), self)
	cometa.flotar = 7.0
	for centro in [Vector2(182 - 240, 214 - 500), Vector2(296 - 240, 214 - 500)]:
		_agregar_parpado(cometa, centro, Vector2(33, 36), Color(0.6, 0.91, 0.81))

	coco = _crear_actor(TEX_COCO, Vector2(-146, -448), self)
	for centro in [Vector2(111 - 146, 157 - 448), Vector2(202 - 146, 157 - 448)]:
		_agregar_parpado(coco, centro, Vector2(25, 26), Color(0.87, 0.65, 0.73))

	ala = Ala.new()
	add_child(ala)

	for i in 3:
		var b := Burbuja.new()
		b.radio = 9.0 + i * 6.0
		add_child(b)
		burbujas.append(b)


func _armar_recuerdo() -> void:
	recuerdo_vp = SubViewport.new()
	recuerdo_vp.size = Vector2i(1280, 720)
	recuerdo_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(recuerdo_vp)

	cam_rec = Camera2D.new()
	cam_rec.position = Vector2(640, 360)
	recuerdo_vp.add_child(cam_rec)

	var fondo := Sprite2D.new()
	fondo.texture = TEX_CLARO
	fondo.position = Vector2(640, 360)
	mat_fondo_rec = ShaderMaterial.new()
	mat_fondo_rec.shader = SHADER_SATURACION
	fondo.material = mat_fondo_rec
	recuerdo_vp.add_child(fondo)

	var brillo := _particulas(Color(1, 0.95, 0.8, 0.8), 40, 4.0)
	brillo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	brillo.position = Vector2(640, 380)
	brillo.emission_rect_extents = Vector2(640, 300)
	brillo.gravity = Vector2(0, -6)
	brillo.scale_amount_min = 0.03
	brillo.scale_amount_max = 0.08
	brillo.preprocess = 4.0
	recuerdo_vp.add_child(brillo)

	chupetin_grande = Chupetin.new()
	chupetin_grande.alto = 230.0
	chupetin_grande.radio = 78.0
	chupetin_grande.color_a = Color("#c77dff")
	chupetin_grande.color_b = Color("#ffd6a5")
	recuerdo_vp.add_child(chupetin_grande)

	capa_chorro = Node2D.new()
	recuerdo_vp.add_child(capa_chorro)

	colec = _crear_actor(TEX_COLEC, Vector2(-200, -535), recuerdo_vp)
	jet = _particulas(Color(0.85, 0.85, 0.95, 0.9), 40, 0.7)
	jet.position = Vector2(-130, -110)
	jet.direction = Vector2(0, 1)
	jet.spread = 20.0
	jet.initial_velocity_min = 80.0
	jet.initial_velocity_max = 140.0
	jet.scale_amount_min = 0.2
	jet.scale_amount_max = 0.4
	jet.local_coords = false
	jet.emitting = false
	colec.cuerpo.add_child(jet)

	for i in COLORES.size():
		var g := Gotita.new()
		g.color = COLORES[i]
		g.radio = 20.0
		recuerdo_vp.add_child(g)
		gotitas.append(g)


func _armar_capas() -> void:
	var capa_rec := CanvasLayer.new()
	capa_rec.layer = 5
	add_child(capa_rec)
	recuerdo_rect = TextureRect.new()
	recuerdo_rect.texture = recuerdo_vp.get_texture()
	recuerdo_rect.size = Vector2(1280, 720)
	recuerdo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_recuerdo = ShaderMaterial.new()
	mat_recuerdo.shader = SHADER_RECUERDO
	recuerdo_rect.material = mat_recuerdo
	capa_rec.add_child(recuerdo_rect)

	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	iris = ColorRect.new()
	iris.color = Color(0.1, 0.08, 0.2)
	iris.size = Vector2(1280, 720)
	iris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat_iris := ShaderMaterial.new()
	mat_iris.shader = SHADER_IRIS
	iris.material = mat_iris
	capa.add_child(iris)

	voz = AudioStreamPlayer.new()
	add_child(voz)
	musica = AudioStreamPlayer.new()
	musica.stream = load(MUSICA)
	musica.volume_db = -15.0
	add_child(musica)


func _crear_hermano(nombre: String, escala: float, fase: float) -> Hermano:
	var h := Hermano.new()
	var rig: Node = load("res://escenas/personajes/vista_previa_rig_%s.tscn" % nombre).instantiate()
	var cadera: Node2D = rig.get_node("cadera")
	var animador := cadera.get_node_or_null("animador")
	if animador:
		cadera.remove_child(animador)
		animador.free()
	rig.remove_child(cadera)
	rig.free()
	h.pivote = Node2D.new()
	add_child(h.pivote)
	h.pivote.add_child(cadera)
	cadera.position = Vector2.ZERO
	h.cadera = cadera
	h.torso = cadera.get_node("torso")
	h.cabeza = h.torso.get_node("cabeza_casco")
	h.brazo_izq = h.torso.get_node("brazo_sup_izq")
	h.brazo_der = h.torso.get_node("brazo_sup_der")
	h.ante_izq = h.brazo_izq.get_node("antebrazo_mano_izq")
	h.ante_der = h.brazo_der.get_node("antebrazo_mano_der")
	# El pivote va en los pies: se mide el borde de abajo real (sin transparencia) de cada pie.
	var pies := 0.0
	for ruta in ["pierna_sup_izq/pierna_inf_pie_izq", "pierna_sup_der/pierna_inf_pie_der"]:
		var pie: Sprite2D = cadera.get_node(ruta)
		var usado := pie.texture.get_image().get_used_rect()
		var rect := pie.get_rect()
		var abajo := (pie.get_parent() as Node2D).position + pie.position \
			+ Vector2(0, rect.position.y + usado.end.y)
		pies = maxf(pies, abajo.y)
	cadera.position = Vector2(0, -pies)
	h.escala = escala
	h.fase = fase
	hermanos.append(h)
	return h


func _crear_actor(tex: Texture2D, desde_pies: Vector2, padre: Node) -> Actor:
	var a := Actor.new()
	a.raiz = Node2D.new()
	padre.add_child(a.raiz)
	a.cuerpo = Sprite2D.new()
	a.cuerpo.texture = tex
	a.cuerpo.centered = false
	a.cuerpo.offset = desde_pies
	a.mat = ShaderMaterial.new()
	a.mat.shader = SHADER_PERSONAJE
	# get_shader_parameter devuelve null hasta que el parámetro se fija una vez.
	a.mat.set_shader_parameter("intensidad", 0.15)
	a.mat.set_shader_parameter("tono", 0.0)
	a.cuerpo.material = a.mat
	a.raiz.add_child(a.cuerpo)
	return a


func _agregar_parpado(a: Actor, centro: Vector2, radio: Vector2, piel: Color) -> void:
	var p := Parpado.new()
	p.position = centro
	p.radio = radio
	p.piel = piel
	a.cuerpo.add_child(p)
	a.parpados.append(p)


func _preparar_bus_voz() -> void:
	_bus_voz = AudioServer.get_bus_index("PocVoz")
	if _bus_voz == -1:
		AudioServer.add_bus()
		_bus_voz = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_voz, "PocVoz")
		AudioServer.set_bus_send(_bus_voz, "Master")
	voz.bus = "PocVoz"


# ---------------------------------------------------------------- la secuencia

func reproducir() -> void:
	_generacion += 1
	var gen := _generacion
	_matar_tweens()
	_estado_inicial()
	musica.play()
	_parpadeo_en_bucle(gen)

	# 1. El planeta gris. Llega la nave dando tumbos suaves y aterriza.
	_encuadrar(Vector2(640, 360), 1.05)
	if await _esperar(1.2, gen): return
	_sfx(SFX_FIUU)
	nave.visible = true
	estela.emitting = true
	_tw().tween_method(_mover_nave, 0.0, 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if await _esperar(1.8, gen): return
	_aterriza_nave()
	if await _esperar(0.7, gen): return

	# 2. Salen los tres hermanos y Cometa, cada uno con su saltito.
	for h in [sofia, nicole, maxi]:
		_salir_de_la_nave(h)
		if await _esperar(0.35, gen): return
	_cometa_sale()
	if await _esperar(1.2, gen): return

	# 3. Cometa se extraña: ¿y los colores? Los hermanos miran alrededor.
	_encuadrar(Vector2(520, 470), 1.2)
	_hablar("cometa", "01_cometa")
	_mirar_alrededor(gen)
	if await _fin_voz(gen): return

	# 4. ¡Coco estaba ahí todo el rato, camuflada!
	_encuadrar(Vector2(820, 430), 1.25)
	if await _esperar(0.6, gen): return
	_aparece_coco()
	_hablar("coco", "02_coco")
	if await _esperar(0.35, gen): return
	for h in hermanos:
		_saltito(h, 40.0, "sorpresa")
	_saltito_actor(cometa, 50.0)
	if await _fin_voz(gen): return
	_poses("reposo")
	for h in hermanos:
		h.mirar = 0.07

	# 5. Coco se presenta, con su tic: "Ahora soy... ¡color sorpresa!"
	_encuadrar(Vector2(900, 440), 1.4)
	_hablar("coco", "03_coco")
	if await _esperar(voz.stream.get_length() * 0.72, gen): return
	_color_sorpresa()
	if await _fin_voz(gen): return

	# 6. Cometa los presenta; cada uno saluda cuando oye su nombre.
	_encuadrar(Vector2(560, 460), 1.3)
	_hablar("cometa", "04_cometa")
	var largo: float = voz.stream.get_length()
	if await _esperar(largo * 0.58, gen): return
	_saltito(maxi, 45.0, "saludo")
	if await _esperar(largo * 0.15, gen): return
	_saltito(nicole, 45.0, "saludo")
	if await _esperar(largo * 0.15, gen): return
	_saltito(sofia, 45.0, "saludo")
	if await _fin_voz(gen): return

	# 7. "¡Qué lindos trajes! ... les cuento lo que pasó." Salen burbujas de su cabeza.
	_encuadrar(Vector2(760, 420), 1.15)
	_hablar("coco", "05_coco")
	if await _esperar(0.6, gen): return
	_poses("reposo")
	if await _fin_voz(gen): return
	_burbujas_de_recuerdo()
	if await _esperar(1.0, gen): return

	# 8. EL RECUERDO: el planeta con color, y llega el Coleccionauta.
	_abrir_recuerdo()
	_hablar("", "06_coco")
	if await _esperar(voz.stream.get_length() * 0.45, gen): return
	_colec_llega()
	if await _fin_voz(gen): return

	_hablar("colec", "07_colec")
	if await _esperar(0.5, gen): return
	_saltito_actor(colec, 30.0)
	if await _esperar(1.3, gen): return
	_guarda_chupetin()
	if await _fin_voz(gen): return

	_hablar("colec", "08_colec")
	if await _esperar(1.2, gen): return
	_chorro_arcoiris(2.4)
	if await _fin_voz(gen): return
	if await _esperar(0.6, gen): return

	_hablar("", "09_coco")
	_cosquillas()
	if await _esperar(1.6, gen): return
	_estallan_colores()
	if await _fin_voz(gen): return

	_hablar("colec", "10_colec")
	_colec_busca()
	if await _esperar(voz.stream.get_length() * 0.62, gen): return
	_colec_se_va()
	if await _fin_voz(gen): return
	if await _esperar(0.6, gen): return
	_cerrar_recuerdo()
	if await _esperar(1.0, gen): return

	# 9. De vuelta: ¡es el mismo que se llevó a papá! Coco se suma al equipo.
	_encuadrar(Vector2(560, 450), 1.25)
	_hablar("cometa", "11_cometa")
	if await _esperar(voz.stream.get_length() * 0.5, gen): return
	for h in hermanos:
		_saltito(h, 25.0, "sorpresa")
	if await _fin_voz(gen): return

	_encuadrar(Vector2(780, 420), 1.15)
	_hablar("coco", "12_coco")
	_poses("reposo")
	if await _esperar(voz.stream.get_length() * 0.68, gen): return
	_somos_equipo()
	if await _fin_voz(gen): return
	_poses("reposo")

	_encuadrar(Vector2(600, 440), 1.2)
	_hablar("cometa", "13_cometa")
	if await _fin_voz(gen): return

	# 10. El trato: un ala gris que Coco promete pintar con los colores que encuentren.
	_encuadrar(Vector2(900, 380), 1.25)
	_hablar("coco", "14_coco")
	if await _esperar(voz.stream.get_length() * 0.38, gen): return
	_aparece_ala()
	if await _esperar(voz.stream.get_length() * 0.42, gen): return
	_ala_gris()
	if await _fin_voz(gen): return

	_hablar("coco", "15_coco")
	if await _esperar(voz.stream.get_length() * 0.5, gen): return
	_pintar_ala_promesa()
	if await _fin_voz(gen): return

	# 11. "¡Shhh! ¿Vieron eso?" El rojo se asoma detrás del chupetín... ¡y se escapa!
	_hablar("coco", "16_coco")
	_poses("reposo")
	_encuadrar(Vector2(1000, 420), 1.45)
	_ocultar_ala()
	if await _esperar(0.9, gen): return
	_asoma_gotita()
	if await _fin_voz(gen): return
	if await _esperar(0.4, gen): return
	_iris_cerrar(_a_pantalla(POS_CHUPETIN + Vector2(-20, -230)))
	if await _esperar(1.1, gen): return
	_terminar()


func saltar() -> void:
	_generacion += 1
	_matar_tweens()
	voz.stop()
	_hablante = ""
	_estado_final()
	_terminar()


func _estado_inicial() -> void:
	_terminada = false
	_trauma = 0.0
	_hablante = ""
	_cam_pos = Vector2(640, 360)
	_cam_zoom = 1.0
	camara.position = _cam_pos
	camara.zoom = Vector2.ONE
	musica.volume_db = -15.0
	mat_fondo.set_shader_parameter("saturacion", 0.12)
	mat_fondo.set_shader_parameter("aclarar", 0.06)
	nave.visible = false
	nave.position = Vector2(-260, 110)
	nave.rotation = 0.3
	nave.scale = Vector2.ONE * 0.45
	estela.emitting = false
	for h in hermanos:
		h.pivote.visible = false
		h.pivote.position = ESCOTILLA
		h.pivote.scale = Vector2.ONE * h.escala
		h.pose = "reposo"
		h.mirar = 0.0
	cometa.raiz.visible = false
	cometa.raiz.scale = Vector2.ONE * 0.36
	coco.raiz.position = POS_COCO
	coco.raiz.scale = Vector2.ONE * 0.62
	coco.raiz.rotation = 0.0
	coco.raiz.visible = true
	coco.mat.set_shader_parameter("camuflaje", 1.0)
	coco.mat.set_shader_parameter("tono", 0.0)
	for p in coco.parpados:
		p.visible = false
	chupetin.gris = 1.0
	gotita_roja.visible = false
	gotita_roja.position = POS_CHUPETIN + Vector2(0, -230)
	ala.visible = false
	ala.pintado = [0.0, 0.0, 0.0, 0.0]
	for b in burbujas:
		b.visible = false
	mat_recuerdo.set_shader_parameter("radio", 0.0)
	recuerdo_rect.visible = false
	_estado_recuerdo_inicial()
	(iris.material as ShaderMaterial).set_shader_parameter("radio", 1.5)


func _estado_recuerdo_inicial() -> void:
	mat_fondo_rec.set_shader_parameter("saturacion", 1.0)
	mat_fondo_rec.set_shader_parameter("saturacion_onda", 0.12)
	mat_fondo_rec.set_shader_parameter("radio_onda", 0.0)
	cam_rec.zoom = Vector2.ONE
	chupetin_grande.visible = true
	chupetin_grande.position = POS_CHUPETIN_GRANDE
	chupetin_grande.scale = Vector2.ONE
	chupetin_grande.rotation = 0.0
	colec.raiz.visible = false
	colec.raiz.position = Vector2(1500, 260)
	colec.raiz.scale = Vector2.ONE * 0.55
	colec.raiz.rotation = 0.0
	colec.cuerpo.flip_h = false
	colec.cuerpo.offset = Vector2(-200, -535)
	jet.emitting = false
	for g in gotitas:
		g.visible = false
	for n in capa_chorro.get_children():
		n.queue_free()


func _estado_final() -> void:
	_estado_inicial()
	nave.visible = true
	nave.position = NAVE_POS
	nave.rotation = 0.0
	nave.scale = Vector2.ONE * 0.62
	for h in hermanos:
		h.pivote.visible = true
		h.pivote.position = h.destino
		h.mirar = 0.07
	cometa.raiz.visible = true
	cometa.raiz.position = POS_COMETA
	coco.mat.set_shader_parameter("camuflaje", 0.0)
	for p in coco.parpados:
		p.visible = true
	_cam_pos = Vector2(640, 360)
	_cam_zoom = 1.0


func _terminar() -> void:
	_terminada = true
	_vista_antes = true
	_parpadeo_en_bucle(_generacion)


# ---------------------------------------------------------------- coreografía del presente

func _mover_nave(t: float) -> void:
	var a := Vector2(-260, 110)
	var control := Vector2(40, 470)
	nave.position = a.lerp(control, t).lerp(control.lerp(NAVE_POS, t), t) + Vector2(0, sin(t * 18.0) * 6.0 * (1.0 - t))
	nave.rotation = lerpf(0.3, 0.0, t) + sin(t * 14.0) * 0.05 * (1.0 - t)
	nave.scale = Vector2.ONE * lerpf(0.45, 0.62, t)


func _aterriza_nave() -> void:
	estela.emitting = false
	_sfx(SFX_BOTE, 0.8)
	_trauma = 0.35
	_puf(NAVE_POS + Vector2(-20, 70), 1.3)
	var tw := _tw()
	tw.tween_property(nave, "scale", Vector2(0.72, 0.52), 0.07)
	tw.tween_property(nave, "scale", Vector2.ONE * 0.62, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _salir_de_la_nave(h: Hermano) -> void:
	_sfx(SFX_POP, 0.9 + randf() * 0.3)
	h.pivote.visible = true
	var desde := ESCOTILLA
	var tw := _tw()
	tw.tween_method(func(t: float) -> void:
		h.pivote.position = desde.lerp(h.destino, t) + Vector2(0, -4.0 * 150.0 * t * (1.0 - t))
		h.pivote.scale = Vector2.ONE * h.escala * lerpf(0.35, 1.0, minf(t * 1.6, 1.0)),
		0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_sfx.bind(SFX_BOTE, 1.1 + randf() * 0.2))
	tw.tween_property(h.pivote, "scale", Vector2(h.escala * 1.15, h.escala * 0.85), 0.06)
	tw.tween_property(h.pivote, "scale", Vector2.ONE * h.escala, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _cometa_sale() -> void:
	_sfx(SFX_POP, 1.3)
	cometa.raiz.visible = true
	var desde := ESCOTILLA
	var tw := _tw()
	tw.tween_method(func(t: float) -> void:
		cometa.raiz.position = desde.lerp(POS_COMETA, t) + Vector2(0, -4.0 * 200.0 * t * (1.0 - t))
		cometa.raiz.rotation = sin(t * PI) * 0.4,
		0.0, 1.0, 0.75)
	tw.tween_callback(_sfx.bind(SFX_BOTE, 1.3))


func _mirar_alrededor(gen: int) -> void:
	for mirada in [-0.12, 0.12, 0.0]:
		for h in hermanos:
			h.mirar = mirada
		if await _esperar(1.1, gen): return


func _aparece_coco() -> void:
	_sfx(SFX_MAGIA, 1.2)
	var tw := _tw()
	tw.tween_method(func(v: float) -> void: coco.mat.set_shader_parameter("camuflaje", v), 1.0, 0.0, 0.9)
	tw.tween_callback(func() -> void:
		for p in coco.parpados:
			p.visible = true)
	_destello(POS_COCO + Vector2(0, -300), 0.8)
	_saltito_actor(coco, 35.0)


func _color_sorpresa() -> void:
	# El tic de Coco: la piel recorre todo el arcoíris y vuelve a su color.
	_sfx(SFX_MAGIA, 1.5)
	var tw := _tw()
	tw.tween_method(func(v: float) -> void: coco.mat.set_shader_parameter("tono", v), 0.0, 2.0, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: coco.mat.set_shader_parameter("tono", 0.0))
	for i in 5:
		var tw2 := _tw()
		tw2.tween_interval(i * 0.3)
		tw2.tween_callback(func() -> void:
			_destello(POS_COCO + Vector2(randf_range(-110, 110), randf_range(-330, -120)), 0.35))
	_saltito_actor(coco, 30.0)


func _burbujas_de_recuerdo() -> void:
	_sfx(SFX_SELECCION, 1.2)
	for i in burbujas.size():
		var b := burbujas[i]
		b.position = POS_COCO + Vector2(-70 - i * 55, -330 - i * 55)
		b.scale = Vector2.ZERO
		b.visible = true
		var tw := _tw()
		tw.tween_interval(i * 0.22)
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _abrir_recuerdo() -> void:
	_estado_recuerdo_inicial()
	recuerdo_rect.visible = true
	var desde := _a_pantalla(burbujas[2].position) / Vector2(1280, 720)
	mat_recuerdo.set_shader_parameter("centro", desde)
	_sfx(SFX_TILIN, 0.8)
	var tw := _tw()
	tw.tween_method(func(r: float) -> void: mat_recuerdo.set_shader_parameter("radio", r), 0.02, 1.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_method(func(c: Vector2) -> void: mat_recuerdo.set_shader_parameter("centro", c),
		desde, Vector2(0.5, 0.5), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		for b in burbujas:
			b.visible = false)
	_tw().tween_property(cam_rec, "zoom", Vector2.ONE * 1.06, 14.0)


func _cerrar_recuerdo() -> void:
	var hasta := _a_pantalla(POS_COCO + Vector2(-20, -300)) / Vector2(1280, 720)
	_sfx(SFX_TILIN, 0.7)
	var tw := _tw()
	tw.tween_method(func(r: float) -> void: mat_recuerdo.set_shader_parameter("radio", r), 1.0, 0.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(c: Vector2) -> void: mat_recuerdo.set_shader_parameter("centro", c),
		Vector2(0.5, 0.5), hasta, 0.8)
	tw.tween_callback(func() -> void: recuerdo_rect.visible = false)


func _somos_equipo() -> void:
	_sfx(SFX_TILIN, 1.1)
	_saltito_actor(coco, 40.0)
	var tw := _tw()
	tw.tween_method(func(v: float) -> void: coco.mat.set_shader_parameter("tono", v), 0.0, 0.08, 0.4)
	tw.tween_interval(1.2)
	tw.tween_method(func(v: float) -> void: coco.mat.set_shader_parameter("tono", v), 0.08, 0.0, 0.6)
	for i in hermanos.size():
		var h := hermanos[i]
		var tw2 := _tw()
		tw2.tween_interval(i * 0.12)
		tw2.tween_callback(_saltito.bind(h, 55.0, "celebra"))
	_saltito_actor(cometa, 60.0)


func _aparece_ala() -> void:
	_puf(POS_ALA, 1.5)
	ala.visible = true
	ala.position = POS_ALA
	ala.rotation = -0.05
	ala.scale = Vector2.ONE * 0.2
	var tw := _tw()
	tw.tween_property(ala, "scale", Vector2.ONE * 0.85, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ala_gris() -> void:
	# "Pero está gris...": el ala se desinfla un poquito, como con pena.
	var tw := _tw()
	tw.tween_property(ala, "rotation", 0.12, 0.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(ala, "position:y", POS_ALA.y + 25.0, 0.6).set_trans(Tween.TRANS_SINE)


func _pintar_ala_promesa() -> void:
	# Un adelanto: cada franja se pinta con su color... y vuelve a gris. Es una promesa.
	var tw := _tw()
	tw.tween_property(ala, "rotation", -0.08, 0.3).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(ala, "position:y", POS_ALA.y - 10.0, 0.3)
	for i in 4:
		tw.tween_callback(func() -> void:
			_sfx(SFX_TILIN, 1.0 + i * 0.15)
			_destello(ala.position + Vector2(lerpf(-110, 110, i / 3.0), lerpf(30, -20, i / 3.0)), 0.4))
		tw.tween_method(func(v: float) -> void: ala.pintado[i] = v, 0.0, 1.0, 0.22)
	tw.tween_callback(func() -> void:
		for j in hermanos.size():
			_saltito(hermanos[j], 50.0, "celebra")
		_saltito_actor(cometa, 50.0))
	tw.tween_interval(1.4)
	tw.tween_method(_pintar_ala_toda, 1.0, 0.0, 0.9)
	tw.tween_callback(_poses.bind("reposo"))


func _pintar_ala_toda(v: float) -> void:
	for i in 4:
		ala.pintado[i] = v


func _ocultar_ala() -> void:
	var tw := _tw()
	tw.tween_property(ala, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: ala.visible = false)


func _asoma_gotita() -> void:
	# La gotita roja se asoma por el borde del chupetín, se ríe y se esconde... y se escapa.
	var detras := POS_CHUPETIN + Vector2(0, -230)
	var asomada := detras + Vector2(-80, 6)
	gotita_roja.position = detras
	gotita_roja.visible = true
	gotita_roja.feliz = 0.0
	for h in hermanos:
		h.mirar = 0.12
	var tw := _tw()
	tw.tween_property(gotita_roja, "position", asomada, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		gotita_roja.feliz = 1.0
		_sfx(SFX_BOTE, 1.8))
	tw.tween_property(gotita_roja, "rotation", 0.25, 0.12)
	tw.tween_property(gotita_roja, "rotation", -0.25, 0.12)
	tw.tween_property(gotita_roja, "rotation", 0.0, 0.12)
	tw.tween_interval(0.3)
	tw.tween_property(gotita_roja, "position", detras, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.4)
	tw.tween_callback(func() -> void:
		gotita_roja.feliz = 0.0
		_sfx(SFX_FIUU, 1.4))
	tw.tween_method(func(t: float) -> void:
		gotita_roja.position = detras.lerp(detras + Vector2(220, -60), t) + Vector2(0, -4.0 * 90.0 * t * (1.0 - t))
		gotita_roja.scale = Vector2.ONE * lerpf(1.0, 0.35, t),
		0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_destello(gotita_roja.position, 0.3)
		gotita_roja.visible = false
		gotita_roja.scale = Vector2.ONE)


# ---------------------------------------------------------------- coreografía del recuerdo

func _colec_llega() -> void:
	colec.raiz.visible = true
	jet.emitting = true
	_sfx(SFX_FIUU, 0.8)
	var desde := colec.raiz.position
	var tw := _tw()
	tw.tween_method(func(t: float) -> void:
		colec.raiz.position = desde.lerp(POS_COLEC, t) + Vector2(0, sin(t * 9.0) * 18.0 * (1.0 - t))
		colec.raiz.rotation = sin(t * 7.0) * 0.12 * (1.0 - t),
		0.0, 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		jet.emitting = false
		_sfx(SFX_BOTE, 0.7)
		_puf_en(recuerdo_vp, POS_COLEC + Vector2(0, -10), 1.0))
	tw.tween_property(colec.raiz, "scale", Vector2(0.64, 0.46), 0.07)
	tw.tween_property(colec.raiz, "scale", Vector2.ONE * 0.55, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _guarda_chupetin() -> void:
	# ¡Para mi colección!: el chupetín vuela a la mochila y se encoge adentro.
	var boca := POS_COLEC + MOCHILA * 0.55
	var desde := chupetin_grande.position
	var tw := _tw()
	tw.tween_method(func(t: float) -> void:
		chupetin_grande.position = desde.lerp(boca + Vector2(0, 150), t) + Vector2(0, -4.0 * 160.0 * t * (1.0 - t))
		chupetin_grande.rotation = t * 4.0
		chupetin_grande.scale = Vector2.ONE * lerpf(1.0, 0.05, t * t),
		0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		chupetin_grande.visible = false
		_sfx(SFX_POP, 0.8)
		_saltito_actor(colec, 20.0))


func _chorro_arcoiris(duracion: float) -> void:
	# "Sluuurp": chorritos de color salen del arco y viajan a la mochila.
	_sfx(SFX_FIUU, 0.6)
	var boca := POS_COLEC + MOCHILA * 0.55
	var tex := _textura_radial(Color.WHITE)
	var tw := _tw()
	for i in 70:
		tw.tween_callback(func() -> void:
			var banda := randi() % COLORES.size()
			var r := lerpf(ARCO_RADIOS.y, ARCO_RADIOS.x, (banda + randf()) / COLORES.size())
			var a := randf_range(PI + 0.7, TAU - 0.7)
			var desde := ARCO_CENTRO + Vector2(cos(a), sin(a)) * r
			var punto := Sprite2D.new()
			punto.texture = tex
			punto.modulate = COLORES[banda]
			punto.scale = Vector2.ONE * randf_range(0.22, 0.34)
			capa_chorro.add_child(punto)
			var curva := desde.lerp(boca, 0.5) + Vector2(0, -120)
			var tp := _tw()
			tp.tween_method(_viajar_punto.bind(punto, desde, curva, boca), 0.0, 1.0, 0.75) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tp.tween_callback(punto.queue_free))
		tw.tween_interval(duracion / 70.0)
	# La mochila se va inflando (todo el cuerpo: la mochila no está separada en el arte).
	_tw().tween_property(colec.raiz, "scale", Vector2(0.6, 0.58), duracion).set_trans(Tween.TRANS_SINE)


## `t` va primero: tween_method pasa su valor antes de los argumentos ligados con bind.
func _viajar_punto(t: float, punto: Sprite2D, desde: Vector2, curva: Vector2, boca: Vector2) -> void:
	if is_instance_valid(punto):
		punto.position = desde.lerp(curva, t).lerp(curva.lerp(boca, t), t)


func _cosquillas() -> void:
	# Le dan cosquillas: tiembla cada vez más.
	var tw := _tw()
	for i in 12:
		var k := (i + 1) / 12.0
		tw.tween_property(colec.raiz, "rotation", 0.1 * k * (1 if i % 2 == 0 else -1), 0.065)
	tw.tween_property(colec.raiz, "rotation", 0.0, 0.08)


func _estallan_colores() -> void:
	# ¡Plop! Los colores salen disparados riéndose y se esconden por todo el planeta;
	# una onda le quita el color al mundo desde la mochila.
	var boca := POS_COLEC + MOCHILA * 0.55
	_sfx(SFX_PUF, 1.3)
	_puf_en(recuerdo_vp, boca, 1.6)
	var tw0 := _tw()
	tw0.tween_property(colec.raiz, "scale", Vector2(0.48, 0.66), 0.08)
	tw0.tween_property(colec.raiz, "scale", Vector2.ONE * 0.55, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	mat_fondo_rec.set_shader_parameter("centro_onda", boca / Vector2(1280, 720))
	_tw().tween_method(func(r: float) -> void: mat_fondo_rec.set_shader_parameter("radio_onda", r),
		0.0, 2.3, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for i in gotitas.size():
		var g := gotitas[i]
		var hasta: Vector2 = ESCONDITES[i]
		g.position = boca
		g.scale = Vector2.ONE * 0.3
		g.feliz = 1.0
		g.visible = true
		var alto := randf_range(160.0, 300.0)
		var dur := randf_range(0.9, 1.3)
		var tw := _tw()
		tw.tween_interval(i * 0.08)
		tw.tween_callback(_sfx.bind(SFX_BOTE, 1.5 + i * 0.12))
		tw.tween_method(func(t: float) -> void:
			g.position = boca.lerp(hasta, t) + Vector2(0, -4.0 * alto * t * (1.0 - t))
			g.rotation = sin(t * TAU * 2.0) * 0.4
			g.scale = Vector2.ONE * lerpf(0.3, 1.1, minf(t * 3.0, 1.0)),
			0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)
		tw.tween_property(g, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			_destello_en(recuerdo_vp, hasta, 0.3)
			g.visible = false)


func _colec_busca() -> void:
	# "¿Eh? ¿Dónde se fueron?": mira a un lado y al otro.
	var tw := _tw()
	for lado in [true, false, true, false]:
		tw.tween_callback(func() -> void:
			colec.cuerpo.flip_h = lado
			colec.cuerpo.offset = Vector2(-207, -535) if lado else Vector2(-200, -535))
		tw.tween_interval(0.45)


func _colec_se_va() -> void:
	# "¡Bueno, me llevo el chupetín!": despega dando una vuelta en el aire y se va.
	jet.emitting = true
	_sfx(SFX_FIUU, 0.9)
	var desde := colec.raiz.position
	var hasta := Vector2(-260, 90)
	var tw := _tw()
	tw.tween_method(func(t: float) -> void:
		colec.raiz.position = desde.lerp(hasta, t) + Vector2(0, -4.0 * 160.0 * t * (1.0 - t))
		colec.raiz.rotation = -TAU * ease(t, 2.0)
		colec.raiz.scale = Vector2.ONE * lerpf(0.55, 0.3, t),
		0.0, 1.0, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: jet.emitting = false)


# ---------------------------------------------------------------- piezas reutilizables

func _hablar(quien: String, archivo: String) -> void:
	voz.stream = load(VOCES + archivo + ".wav")
	voz.play()
	_hablante = quien


## Espera a que termine la voz (más una pausa corta); true si se saltó la secuencia.
func _fin_voz(gen: int) -> bool:
	while voz.playing:
		if await _esperar(0.05, gen): return true
	_hablante = ""
	return await _esperar(0.3, gen)


func _encuadrar(pos: Vector2, zoom: float) -> void:
	_cam_pos = pos
	_cam_zoom = zoom


func _poses(pose: String) -> void:
	for h in hermanos:
		h.pose = pose


func _saltito(h: Hermano, alto: float, pose := "") -> void:
	if pose != "":
		h.pose = pose
	var base := h.destino
	var e := h.escala
	var tw := _tw()
	tw.tween_property(h.pivote, "scale", Vector2(e * 1.1, e * 0.88), 0.07)
	tw.tween_property(h.pivote, "scale", Vector2(e * 0.94, e * 1.08), 0.07)
	tw.tween_method(func(t: float) -> void: h.pivote.position = base + Vector2(0, -4.0 * alto * t * (1.0 - t)),
		0.0, 1.0, 0.42)
	tw.parallel().tween_property(h.pivote, "scale", Vector2.ONE * e, 0.2)
	tw.tween_property(h.pivote, "scale", Vector2(e * 1.12, e * 0.88), 0.06)
	tw.tween_property(h.pivote, "scale", Vector2.ONE * e, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _saltito_actor(a: Actor, alto: float) -> void:
	var base := a.raiz.position
	var e := a.raiz.scale
	var tw := _tw()
	tw.tween_property(a.raiz, "scale", Vector2(e.x * 1.12, e.y * 0.86), 0.07)
	tw.tween_method(func(t: float) -> void: a.raiz.position = base + Vector2(0, -4.0 * alto * t * (1.0 - t)),
		0.0, 1.0, 0.4)
	tw.parallel().tween_property(a.raiz, "scale", e, 0.15)
	tw.tween_property(a.raiz, "scale", Vector2(e.x * 1.12, e.y * 0.88), 0.06)
	tw.tween_property(a.raiz, "scale", e, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _iris_cerrar(centro_px: Vector2) -> void:
	var mat := iris.material as ShaderMaterial
	mat.set_shader_parameter("centro", centro_px / Vector2(1280, 720))
	var tw := _tw()
	tw.tween_method(func(r: float) -> void: mat.set_shader_parameter("radio", r), 1.5, 0.14, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.3)
	tw.tween_method(func(r: float) -> void: mat.set_shader_parameter("radio", r), 0.14, 0.0, 0.2)
	_tw().tween_property(musica, "volume_db", -40.0, 1.0)


func _parpadeo_en_bucle(gen: int) -> void:
	while gen == _generacion:
		if await _esperar(randf_range(2.0, 3.6), gen): return
		for a in [coco, cometa]:
			for p in (a as Actor).parpados:
				var tw := _tw()
				tw.tween_interval(randf() * 0.15)
				tw.tween_property(p, "cierre", 1.0, 0.07)
				tw.tween_interval(0.06)
				tw.tween_property(p, "cierre", 0.0, 0.1)


func _destello(pos: Vector2, tamano: float) -> void:
	_destello_en(self, pos, tamano)


func _destello_en(padre: Node, pos: Vector2, tamano: float) -> void:
	var e := Estrella.new()
	e.puntas = 8
	e.radio_ext = 60.0
	e.radio_int = 24.0
	e.relleno = Color(1, 0.97, 0.75)
	e.position = pos
	e.scale = Vector2.ZERO
	padre.add_child(e)
	var tw := _tw()
	tw.tween_property(e, "scale", Vector2.ONE * tamano, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(e, "rotation", 0.6, 0.5)
	tw.tween_property(e, "modulate:a", 0.0, 0.3)
	tw.tween_callback(e.queue_free)


func _puf(pos: Vector2, tamano: float) -> void:
	_puf_en(self, pos, tamano)


func _puf_en(padre: Node, pos: Vector2, tamano: float) -> void:
	_sfx(SFX_PUF)
	var n := Nube.new()
	n.position = pos
	n.scale = Vector2.ONE * 0.3
	padre.add_child(n)
	var tw := _tw()
	tw.tween_property(n, "scale", Vector2.ONE * tamano * 1.5, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE * tamano * 1.8, 0.35)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.35)
	tw.tween_callback(n.queue_free)


## Posición en pantalla de un punto del mundo del presente (con la cámara actual).
func _a_pantalla(pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * pos


# ---------------------------------------------------------------- cada cuadro

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0

	# Cámara: va suave hacia el encuadre pedido, sin mostrar fuera del fondo.
	var k := 1.0 - exp(-delta * 2.4)
	var zoom := lerpf(camara.zoom.x, _cam_zoom, k)
	var mitad := Vector2(640, 360) / zoom
	var objetivo := Vector2(clampf(_cam_pos.x, mitad.x, 1280.0 - mitad.x), clampf(_cam_pos.y, mitad.y, 720.0 - mitad.y))
	camara.zoom = Vector2.ONE * zoom
	camara.position = camara.position.lerp(objetivo, k)
	camara.position = Vector2(clampf(camara.position.x, mitad.x, 1280.0 - mitad.x),
		clampf(camara.position.y, mitad.y, 720.0 - mitad.y))
	if _trauma > 0.0:
		_trauma = maxf(_trauma - delta * 1.8, 0.0)
		camara.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 18.0 * _trauma * _trauma
	else:
		camara.offset = Vector2.ZERO

	# Música: baja sola mientras alguien habla.
	if musica.volume_db > -39.0:
		var meta := -24.0 if voz.playing else -15.0
		musica.volume_db = lerpf(musica.volume_db, meta, 1.0 - exp(-delta * 4.0))

	var amp := 0.0
	if voz.playing:
		amp = clampf((AudioServer.get_bus_peak_volume_left_db(_bus_voz, 0) + 36.0) / 30.0, 0.0, 1.0)

	# Hermanos: poses mezcladas, respiración y mirada.
	var kp := 1.0 - exp(-delta * 10.0)
	for h in hermanos:
		if not h.pivote.visible:
			continue
		var obj: Array = POSES[h.pose]
		var vaiven := sin(t * 2.0 + h.fase) * 0.03
		var saludo := sin(t * 11.0 + h.fase) * 0.32 if h.pose == "saludo" else 0.0
		h.brazo_izq.rotation = lerpf(h.brazo_izq.rotation, obj[0] + vaiven, kp)
		h.brazo_der.rotation = lerpf(h.brazo_der.rotation, obj[1] - vaiven, kp)
		h.ante_izq.rotation = lerpf(h.ante_izq.rotation, obj[2], kp)
		h.ante_der.rotation = lerpf(h.ante_der.rotation, obj[3] + saludo, kp)
		h.torso.rotation = sin(t * 1.9 + h.fase) * 0.022
		h.cabeza.rotation = lerpf(h.cabeza.rotation, h.mirar + sin(t * 1.9 + h.fase + 0.8) * 0.035, kp * 0.4)

	# Actores de arte plano: respiran, flotan y, el que habla, se mueve con su voz.
	for nombre in ["coco", "cometa", "colec"]:
		var a: Actor = {"coco": coco, "cometa": cometa, "colec": colec}[nombre]
		if not a.raiz.visible:
			continue
		var habla := amp if _hablante == nombre else 0.0
		var respira := sin(t * 2.4 + nombre.length()) * 0.012
		a.cuerpo.scale = a.cuerpo.scale.lerp(Vector2(1.0 - 0.05 * habla - respira * 0.5,
			1.0 + 0.09 * habla + respira), 0.35)
		a.cuerpo.position.y = -absf(sin(t * 2.2)) * a.flotar if a.flotar > 0.0 else 0.0
		a.mat.set_shader_parameter("intensidad", lerpf(a.mat.get_shader_parameter("intensidad"),
			0.15 + 0.6 * habla, 0.3))

	# Los párpados de Coco siguen el color de su piel cuando cambia (su tic).
	var tono: float = coco.mat.get_shader_parameter("tono")
	var piel := Color(0.87, 0.65, 0.73)
	piel.h = fposmod(piel.h + tono, 1.0)
	for p in coco.parpados:
		p.piel = piel


func _unhandled_input(evento: InputEvent) -> void:
	var toque: bool = (evento is InputEventScreenTouch and evento.pressed) \
		or (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT)
	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_R:
		reproducir()
		return
	if not toque:
		return
	if _terminada:
		reproducir()
	elif _vista_antes:
		saltar()
	else:
		_destello(get_global_mouse_position(), 0.35)


# ---------------------------------------------------------------- utilidades

func _tw() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


func _matar_tweens() -> void:
	for tw in _tweens:
		if tw.is_valid():
			tw.kill()
	_tweens.clear()


## Espera `segundos` con el mismo reloj que los tweens; true si se saltó o reinició la secuencia.
func _esperar(segundos: float, gen: int) -> bool:
	var restante := segundos
	while restante > 0.0:
		await get_tree().process_frame
		if gen != _generacion:
			return true
		restante -= get_process_delta_time()
	return gen != _generacion


func _sfx(ruta: String, tono := 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load(ruta)
	p.pitch_scale = tono
	p.volume_db = -4.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _material_aditivo() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _textura_radial(color: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color, 0.0))
	var tx := GradientTexture2D.new()
	tx.gradient = g
	tx.fill = GradientTexture2D.FILL_RADIAL
	tx.fill_from = Vector2(0.5, 0.5)
	tx.fill_to = Vector2(1.0, 0.5)
	tx.width = 128
	tx.height = 128
	return tx


func _particulas(color: Color, cantidad: int, vida: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _textura_radial(Color.WHITE)
	p.color = color
	p.amount = cantidad
	p.lifetime = vida
	p.material = _material_aditivo()
	var rampa := Gradient.new()
	rampa.set_color(0, Color.WHITE)
	rampa.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = rampa
	return p
