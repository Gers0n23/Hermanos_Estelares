extends Control
## Intro, Beat 5 — "¡Los trajes estelares!" (pedido del PO 21-Nov-2026: mas enfasis en los trajes).
##
## Secuencia de transformacion, uno por uno, para que cada niño tenga SU momento:
##   1. Escenario de estrellas: los tres hermanos con ropa de casa sobre pedestales de luz; Cometa arriba.
##   2. De Cometa salen volando tres estrellas de poder, una sobre cada niño.
##   3. Por turno (Maxi, Nicole, Sofia): foco y rayos detras, la estrella se mete en el pecho, una banda
##      de luz dorada sube de los pies a la cabeza y a su paso la ropa de casa se vuelve traje (shader).
##      "¡Pop!", un gesto propio (Maxi salta, Nicole gira, Sofia guiña) y su linea de voz.
##   4. Los tres juntos con traje: fanfarria, salto en grupo y lluvia de chispas.
##
## La invoca CinematicaHistoria (plano "escena" en datos/historia/intro.json) y usa su voz y su
## toque-para-avanzar via `cine.ejecutar()` / `cine.esperar()`. Recortes casa/traje alineados por los
## pies: herramientas/recortar_trajes_intro.py. Sonidos: herramientas/componer_sfx_ui.py.

const CARPETA := "res://assets/cinematicas/intro/trajes/"
const SFX_VUELA := "res://assets/audio/sfx/ui/estrella_vuela.ogg"
const SFX_TRANSFORMA := "res://assets/audio/sfx/ui/transformacion.ogg"
const SFX_POP := "res://assets/audio/sfx/ui/blup.ogg"
const SFX_FANFARRIA := "res://assets/audio/sfx/ui/fanfarria_trajes.ogg"
const COMETA := "res://assets/sprites/personajes/cometa_saludo.png"
const PISO_Y := 650.0
const ESCALA_NINO := 0.74
const CENTRO := Vector2(640, 360)
const SEGUNDOS_BARRIDO := 1.7

## Orden: del mas chico a la mas grande (Maxi abre, Sofia cierra con su guiño).
const NINOS := [
	{"id": "maxi", "x": 350.0, "gesto": "salto", "color": Color("6fb7ff"),
		"voz": "intro_024", "quien": "Maxi", "texto": "¡¡Wiiii!!"},
	{"id": "nicole", "x": 640.0, "gesto": "giro", "color": Color("ff8fc8"),
		"voz": "intro_025", "quien": "Nicole", "texto": "¡Es rosado! ¡Es perfecto!"},
	{"id": "sofia", "x": 940.0, "gesto": "guino", "color": Color("5fe0d2"),
		"voz": "intro_026", "quien": "Sofía", "texto": "Turquesa y rosado... buen gusto, Cometa."},
]

const SHADER_TRANSFORMACION := """
shader_type canvas_item;
uniform sampler2D tex_traje : filter_linear;
uniform float progreso = 0.0;
uniform float ancho_banda = 0.07;
uniform vec4 color_banda : source_color = vec4(1.0, 0.88, 0.42, 1.0);

varying vec4 tinte;  // modulate del nodo (en fragment COLOR ya viene multiplicado por la textura)

float azar(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void vertex() {
	tinte = COLOR;
}

void fragment() {
	vec4 casa = texture(TEXTURE, UV);
	vec4 traje = texture(tex_traje, UV);
	// La linea sube de los pies (UV.y = 1) a la cabeza (UV.y = 0); debajo de ella ya es traje.
	float linea = 1.0 + ancho_banda - progreso * (1.0 + 2.0 * ancho_banda);
	vec4 base = mix(casa, traje, step(linea, UV.y));
	float brillo = 1.0 - smoothstep(0.0, ancho_banda, abs(UV.y - linea));
	float chispa = step(0.9, azar(floor(UV * vec2(48.0, 96.0)) + floor(TIME * 14.0)));
	float silueta = max(casa.a, traje.a);
	vec3 color = base.rgb + color_banda.rgb * brillo * (0.85 + 0.9 * chispa);
	COLOR = vec4(color, max(base.a, silueta * brillo)) * tinte;
}
"""

const SHADER_RAYOS := """
shader_type canvas_item;
uniform vec4 color : source_color = vec4(1.0, 0.86, 0.45, 0.5);
uniform float rayos = 12.0;
void fragment() {
	vec2 p = UV - vec2(0.5);
	float ang = atan(p.y, p.x);
	float r = length(p);
	float banda = smoothstep(0.35, 0.65, sin(ang * rayos + TIME * 0.7) * 0.5 + 0.5);
	float halo = smoothstep(0.5, 0.0, r);
	COLOR = vec4(color.rgb, color.a * halo * (0.35 + 0.65 * banda));
}
"""


## Estrella de poder dibujada (dorada, con halo y borde blanco).
class Estrella extends Node2D:
	var radio := 26.0
	var color := Color("ffd45c")

	func _draw() -> void:
		var puntos := PackedVector2Array()
		for i in 10:
			var r := radio if i % 2 == 0 else radio * 0.46
			var ang := -PI / 2.0 + i * PI / 5.0
			puntos.append(Vector2(cos(ang), sin(ang)) * r)
		draw_circle(Vector2.ZERO, radio * 1.7, Color(color, 0.18))
		draw_circle(Vector2.ZERO, radio * 1.15, Color(color, 0.3))
		draw_colored_polygon(puntos, color)
		var borde := puntos.duplicate()
		borde.append(puntos[0])
		draw_polyline(borde, Color.WHITE, 3.0, true)


## Cielo con estrellitas que titilan.
class Cielo extends Node2D:
	var _estrellas: Array[Vector4] = []  # x, y, radio, fase

	func _ready() -> void:
		var azar := RandomNumberGenerator.new()
		azar.seed = 5
		for i in 140:
			_estrellas.append(Vector4(azar.randf_range(0, 1280), azar.randf_range(0, 600),
				azar.randf_range(1.0, 2.8), azar.randf_range(0, TAU)))

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		for e in _estrellas:
			var alfa := 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 1.7 + e.w))
			draw_circle(Vector2(e.x, e.y), e.z, Color(1, 0.97, 0.85, alfa))


## Pedestal de luz bajo cada niño (elipse con anillo).
class Pedestal extends Node2D:
	var color := Color.WHITE

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, 150.0, Color(color, 0.16))
		draw_circle(Vector2.ZERO, 112.0, Color(color, 0.3))
		draw_arc(Vector2.ZERO, 112.0, 0, TAU, 64, Color(1, 1, 1, 0.75), 6.0, true)


var _escenario: Node2D
var _ninos: Array[Sprite2D] = []
var _pedestales: Array[Pedestal] = []
var _estrellas: Array[Estrella] = []
var _rayos: ColorRect
var _chispas: CPUParticles2D
var _confeti: CPUParticles2D
var _cometa: Sprite2D
var _textura_chispa: Texture2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_construir()


func _construir() -> void:
	var degrade := Gradient.new()
	degrade.set_color(0, Color("140a36"))
	degrade.set_color(1, Color("4a2378"))
	var textura_fondo := GradientTexture2D.new()
	textura_fondo.gradient = degrade
	textura_fondo.fill_from = Vector2(0.5, 0.0)
	textura_fondo.fill_to = Vector2(0.5, 1.0)
	var fondo := TextureRect.new()
	fondo.texture = textura_fondo
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	add_child(Cielo.new())

	_escenario = Node2D.new()
	add_child(_escenario)

	_rayos = ColorRect.new()
	_rayos.size = Vector2(1100, 1100)
	_rayos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat_rayos := ShaderMaterial.new()
	mat_rayos.shader = _shader(SHADER_RAYOS)
	_rayos.material = mat_rayos
	_rayos.modulate.a = 0.0
	_escenario.add_child(_rayos)

	var shader_trans := _shader(SHADER_TRANSFORMACION)
	for datos: Dictionary in NINOS:
		var pedestal := Pedestal.new()
		pedestal.color = datos["color"]
		pedestal.position = Vector2(datos["x"], PISO_Y)
		_escenario.add_child(pedestal)
		_pedestales.append(pedestal)

		var nino := Sprite2D.new()
		nino.texture = load(CARPETA + str(datos["id"]) + "_casa.png")
		var mat := ShaderMaterial.new()
		mat.shader = shader_trans
		mat.set_shader_parameter("tex_traje", load(CARPETA + str(datos["id"]) + "_traje.png"))
		mat.set_shader_parameter("progreso", 0.0)
		nino.material = mat
		nino.offset = Vector2(0, -nino.texture.get_height() / 2.0)  # el origen queda en los pies
		nino.position = Vector2(datos["x"], PISO_Y + 10.0)
		nino.scale = Vector2.ONE * ESCALA_NINO
		_escenario.add_child(nino)
		_ninos.append(nino)

	_cometa = Sprite2D.new()
	_cometa.texture = load(COMETA)
	var alto_cometa := float(_cometa.texture.get_height())
	_cometa.scale = Vector2.ONE * (170.0 / alto_cometa)
	_cometa.position = Vector2(120, 130)
	_escenario.add_child(_cometa)
	var flotar := create_tween().set_loops()
	flotar.tween_property(_cometa, "position:y", 112.0, 1.1).set_trans(Tween.TRANS_SINE)
	flotar.tween_property(_cometa, "position:y", 130.0, 1.1).set_trans(Tween.TRANS_SINE)

	_textura_chispa = _textura_redonda()
	_chispas = _particulas(60, 0.9, false)
	_confeti = _particulas(140, 2.2, true)


# --- Secuencia ---

func reproducir(cine: Node) -> void:
	await cine.esperar(0.5)
	await _volar_estrellas()
	for i in _ninos.size():
		if cine.termino():
			return
		await _transformar(cine, i)
	if cine.termino():
		return
	await _final(cine)


func _volar_estrellas() -> void:
	var tween := create_tween().set_parallel(true)
	for i in _ninos.size():
		var estrella := Estrella.new()
		estrella.position = _cometa.position
		estrella.scale = Vector2.ZERO
		_escenario.add_child(estrella)
		_estrellas.append(estrella)
		var destino := _cabeza(i) + Vector2(0, -34)
		var demora := 0.35 * i
		tween.tween_callback(Audio.reproducir_sfx.bind(SFX_VUELA)).set_delay(demora)
		tween.tween_property(estrella, "scale", Vector2.ONE, 0.3).set_delay(demora)
		# Vuelo en curva: sube primero y luego cae sobre su niño.
		tween.tween_method(_curva.bind(estrella, _cometa.position, destino), 0.0, 1.0, 0.9) \
			.set_delay(demora).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(estrella, "rotation", TAU, 0.9).set_delay(demora)
	await tween.finished
	for estrella in _estrellas:  # quedan flotando y girando suave
		var giro := create_tween().set_loops()
		giro.tween_property(estrella, "scale", Vector2.ONE * 1.15, 0.5).set_trans(Tween.TRANS_SINE)
		giro.tween_property(estrella, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _curva(t: float, estrella: Node2D, desde: Vector2, hasta: Vector2) -> void:
	var control := Vector2((desde.x + hasta.x) / 2.0, minf(desde.y, hasta.y) - 160.0)
	estrella.position = desde.lerp(control, t).lerp(control.lerp(hasta, t), t)


func _transformar(cine: Node, i: int) -> void:
	var nino := _ninos[i]
	var datos: Dictionary = NINOS[i]
	var pecho := _cabeza(i).lerp(nino.position, 0.42)
	var medio := _cabeza(i).lerp(nino.position, 0.5)
	# Foco: los otros se apagan, rayos detras del niño y la camara se acerca.
	var foco := create_tween().set_parallel(true)
	for j in _ninos.size():
		var apagado := Color(0.45, 0.45, 0.6) if j != i else Color.WHITE
		foco.tween_property(_ninos[j], "modulate", apagado, 0.4)
	_rayos.position = pecho - _rayos.size / 2.0
	(_rayos.material as ShaderMaterial).set_shader_parameter("color", Color(datos["color"], 0.55))
	foco.tween_property(_rayos, "modulate:a", 1.0, 0.5)
	_enfocar(foco, medio + Vector2(0, -25), 1.14, 0.7)
	await foco.finished

	# La estrella se mete en el pecho: chispazo y empieza la transformacion.
	var estrella := _estrellas[i]
	var entra := create_tween().set_parallel(true)
	entra.tween_property(estrella, "position", pecho, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	entra.tween_property(estrella, "scale", Vector2.ONE * 0.4, 0.35)
	await entra.finished
	estrella.visible = false
	Audio.reproducir_sfx(SFX_TRANSFORMA)
	_destello_en(pecho, datos["color"])

	var mat := nino.material as ShaderMaterial
	var alto := nino.texture.get_height() * ESCALA_NINO
	_chispas.global_position = nino.global_position
	_chispas.emission_rect_extents = Vector2(nino.texture.get_width() * ESCALA_NINO * 0.4, 6.0) * _escenario.scale.x
	_chispas.emitting = true
	var barrido := create_tween()
	barrido.tween_method(_barrer.bind(nino, mat, alto), 0.0, 1.0, SEGUNDOS_BARRIDO) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await barrido.finished
	_chispas.emitting = false

	# ¡Pop! brillo de cuerpo entero y gesto propio mientras dice su linea.
	Audio.reproducir_sfx(SFX_POP)
	var pop := create_tween()
	nino.modulate = Color(1.7, 1.6, 1.3)
	pop.tween_property(nino, "modulate", Color.WHITE, 0.5)
	pop.parallel().tween_property(nino, "scale", Vector2.ONE * ESCALA_NINO * 1.08, 0.12)
	pop.tween_property(nino, "scale", Vector2.ONE * ESCALA_NINO, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished
	_gesto(i, str(datos["gesto"]))
	await cine.ejecutar({"voz": datos["voz"], "quien": datos["quien"], "texto": datos["texto"]})

	var salir := create_tween().set_parallel(true)
	salir.tween_property(_rayos, "modulate:a", 0.0, 0.4)
	_enfocar(salir, CENTRO, 1.0, 0.6)
	await salir.finished


## La banda de luz sube (shader) y las chispas la siguen.
func _barrer(progreso: float, nino: Sprite2D, mat: ShaderMaterial, alto: float) -> void:
	mat.set_shader_parameter("progreso", progreso)
	_chispas.global_position = _escenario.to_global(nino.position - Vector2(0, alto * progreso))


func _gesto(i: int, gesto: String) -> void:
	var nino := _ninos[i]
	var tween := create_tween()
	match gesto:
		"salto":  # Maxi: dos saltitos de alegria
			for k in 2:
				tween.tween_property(nino, "position:y", PISO_Y + 10.0 - 70.0, 0.2) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(nino, "position:y", PISO_Y + 10.0, 0.32) \
					.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		"giro":  # Nicole: una vuelta sobre si misma, como modelando el traje
			tween.tween_property(nino, "scale:x", -ESCALA_NINO, 0.28).set_trans(Tween.TRANS_SINE)
			tween.tween_property(nino, "scale:x", ESCALA_NINO, 0.28).set_trans(Tween.TRANS_SINE)
		"guino":  # Sofia: se inclina con estilo y le brilla un destello junto al casco
			tween.tween_property(nino, "rotation", -0.09, 0.22).set_trans(Tween.TRANS_SINE)
			tween.tween_property(nino, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var brillo := Estrella.new()
			brillo.radio = 16.0
			brillo.color = Color.WHITE
			brillo.position = _cabeza(i) + Vector2(70, 40)
			brillo.scale = Vector2.ZERO
			_escenario.add_child(brillo)
			var chispazo := create_tween()
			chispazo.tween_property(brillo, "scale", Vector2.ONE * 1.3, 0.18).set_trans(Tween.TRANS_BACK)
			chispazo.parallel().tween_property(brillo, "rotation", PI / 2.0, 0.5)
			chispazo.tween_property(brillo, "scale", Vector2.ZERO, 0.3)
			chispazo.tween_callback(brillo.queue_free)


func _final(cine: Node) -> void:
	var todos := create_tween().set_parallel(true)
	for nino in _ninos:
		todos.tween_property(nino, "modulate", Color.WHITE, 0.3)
	_rayos.size = Vector2(1700, 1700)
	_rayos.position = Vector2(640, 420) - _rayos.size / 2.0
	(_rayos.material as ShaderMaterial).set_shader_parameter("color", Color(1.0, 0.86, 0.45, 0.55))
	todos.tween_property(_rayos, "modulate:a", 1.0, 0.5)
	await todos.finished
	Audio.reproducir_sfx(SFX_FANFARRIA)
	_confeti.global_position = Vector2(640, 260)
	_confeti.restart()
	_confeti.emitting = true
	var salto := create_tween().set_parallel(true)
	for i in _ninos.size():
		var nino := _ninos[i]
		var demora := 0.08 * i
		salto.tween_property(nino, "position:y", PISO_Y + 10.0 - 80.0, 0.22).set_delay(demora) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		salto.tween_property(nino, "position:y", PISO_Y + 10.0, 0.4).set_delay(demora + 0.22) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await cine.esperar(2.4)


# --- Utilidades ---

## Acerca la camara: `punto` (coords del escenario) queda en el centro de la pantalla con `zoom`.
func _enfocar(tween: Tween, punto: Vector2, zoom: float, segundos: float) -> void:
	tween.tween_property(_escenario, "scale", Vector2.ONE * zoom, segundos) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_escenario, "position", CENTRO - punto * zoom, segundos) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _cabeza(i: int) -> Vector2:
	var nino := _ninos[i]
	return nino.position - Vector2(0, nino.texture.get_height() * ESCALA_NINO * 0.88)


func _destello_en(punto: Vector2, color: Color) -> void:
	var anillo := Estrella.new()
	anillo.radio = 40.0
	anillo.color = color.lightened(0.4)
	anillo.position = punto
	anillo.scale = Vector2.ONE * 0.3
	_escenario.add_child(anillo)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(anillo, "scale", Vector2.ONE * 3.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(anillo, "modulate:a", 0.0, 0.45)
	tween.tween_property(anillo, "rotation", 0.8, 0.45)
	tween.chain().tween_callback(anillo.queue_free)


func _particulas(cantidad: int, vida: float, confeti: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = cantidad
	p.lifetime = vida
	p.texture = _textura_chispa
	p.emitting = false
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	if confeti:
		p.one_shot = true
		p.explosiveness = 0.9
		p.direction = Vector2.UP
		p.spread = 80.0
		p.initial_velocity_min = 350.0
		p.initial_velocity_max = 650.0
		p.gravity = Vector2(0, 520)
		p.scale_amount_min = 0.35
		p.scale_amount_max = 0.7
		var colores := Gradient.new()
		colores.set_color(0, Color("ffd45c"))
		colores.set_color(1, Color("ff8fc8"))
		colores.add_point(0.33, Color("6fb7ff"))
		colores.add_point(0.66, Color("5fe0d2"))
		p.color_initial_ramp = colores
	else:
		p.material = aditivo
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.direction = Vector2.UP
		p.spread = 60.0
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 140.0
		p.gravity = Vector2(0, -40)
		p.scale_amount_min = 0.2
		p.scale_amount_max = 0.5
		p.color = Color("ffe9a8")
	add_child(p)
	return p


func _textura_redonda() -> Texture2D:
	var degrade := Gradient.new()
	degrade.set_color(0, Color(1, 1, 1, 1))
	degrade.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = degrade
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 32
	textura.height = 32
	return textura


func _shader(codigo: String) -> Shader:
	var shader := Shader.new()
	shader.code = codigo
	return shader
