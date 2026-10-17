extends Node2D
## PRUEBA DE CONCEPTO (no es una tarjeta del tablero): el plano 04 de la intro,
## "Choque de Cometa", animado 100 % por código sobre arte pintado ya aprobado,
## sin rig y sin video.
##
## Técnicas que muestra:
##   - Motion comic vivo: fondo pintado + luces aditivas + motas de polvo (partículas).
##   - Trayectoria con loop (Curve2D) y rotación que sigue la tangente.
##   - Squash & stretch, sacudida de cámara por "trauma", golpe de zoom.
##   - Efectos dibujados por código: estallido de estrella, nubes de "puf", estrellitas de mareo.
##   - Arte plano que "respira" con el shader de gelatina y parpadea con párpados por código.
##   - Personaje que "habla" siguiendo el volumen real de la voz (pico del bus de audio).
##   - Cambio de pose escondido tras un "puf" (truco clásico de dibujo animado).
##   - Saltar al estado final (regla §0.6 de los storyboards) y cortina de iris.
##
## Controles: tocar/clic = chispita la primera vez, saltar desde la segunda;
## al terminar, tocar = repetir. Tecla R = repetir.

const TEX_LIVING := preload("res://poc/cinematica_codigo/arte/living.png")
const TEX_NAVE_VUELO := preload("res://poc/cinematica_codigo/arte/navecita_vuelo.png")
const TEX_NAVE_COMETA := preload("res://poc/cinematica_codigo/arte/navecita_cometa.png")
const TEX_COMETA := preload("res://assets/sprites/personajes/cometa_base.png")
const TEX_COMETA_SALUDO := preload("res://assets/sprites/personajes/cometa_saludo.png")
const SHADER_GELATINA := preload("res://poc/cinematica_codigo/gelatina.gdshader")
const SHADER_IRIS := preload("res://poc/cinematica_codigo/iris.gdshader")

const VOZ_COMETA := "res://assets/audio/voces/arcoiris/mapa/bienvenida.wav"  # placeholder
const SFX_TILIN := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_FIUU := "res://assets/audio/sfx/ui/fiuu.ogg"
const SFX_GOLPE := "res://assets/audio/sfx/viaje/golpe.ogg"
const SFX_BOTE := "res://assets/audio/sfx/ui/blup.ogg"
const SFX_PUF := "res://assets/audio/sfx/ui/puf.ogg"
const SFX_POP := "res://assets/audio/sfx/ui/abrir.ogg"

# Puntos clave en coordenadas de pantalla (el fondo 1376x768 queda centrado: pantalla = imagen - (48, 24)).
const VENTANA := Vector2(852, 270)
const COJIN := Vector2(175, 350)
const ALFOMBRA := Vector2(610, 590)
const COMETA_PIE := Vector2(860, 640)

# Rumbo "hacia adelante" de la navecita dentro de su PNG (la nariz apunta a la izquierda y un poco abajo).
const ANGULO_NARIZ := PI - 0.34

var _generacion := 0
var _tweens: Array[Tween] = []
var _vista_antes := false
var _terminada := false
var _trauma := 0.0
var _hablando := false
var _cometa_animandose := false
var _bus_voz := -1
var _curva := Curve2D.new()

var camara: Camera2D
var nave: Node2D
var nave_vuelo: Sprite2D
var nave_cometa: Sprite2D
var nave_vacia: Sprite2D
var estela: CPUParticles2D
var humo: CPUParticles2D
var cometa: Sprite2D
var mat_cometa: ShaderMaterial
var parpados: Array[Parpado] = []
var mareo: Node2D
var luz_ventana: Polygon2D
var brillos: Array[Sprite2D] = []
var iris: ColorRect
var voz: AudioStreamPlayer


# ---------------------------------------------------------------- efectos dibujados por código

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


class Parpado extends Node2D:
	var radio := Vector2(33, 36)
	var piel := Color(0.6, 0.91, 0.81)
	var cierre := 0.0:
		set(v):
			cierre = v
			queue_redraw()

	func _draw() -> void:
		if cierre <= 0.02:
			return
		# Casquete superior de la elipse hasta la línea de corte (sin puntos repetidos).
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
		draw_line(Vector2(-w, y), Vector2(w, y), Color(0.2, 0.32, 0.32), 4.0, true)


# ---------------------------------------------------------------- armado de la escena

func _ready() -> void:
	_armar_escena()
	_preparar_bus_voz()
	reproducir()


func _armar_escena() -> void:
	camara = Camera2D.new()
	camara.position = Vector2(640, 360)
	add_child(camara)
	camara.make_current()

	var fondo := Sprite2D.new()
	fondo.texture = TEX_LIVING
	fondo.position = Vector2(640, 360)
	add_child(fondo)

	# Haz de luz cálida de la ventana (aditivo) y brillo de las lámparas.
	luz_ventana = Polygon2D.new()
	luz_ventana.polygon = PackedVector2Array([Vector2(800, 100), Vector2(915, 100),
		Vector2(1010, 640), Vector2(560, 640)])
	# Se desvanece hacia el piso (colores por vértice): sin bordes duros sobre la alfombra.
	var calido := Color(1.0, 0.82, 0.55, 0.13)
	luz_ventana.vertex_colors = PackedColorArray([calido, calido, Color(calido, 0.0), Color(calido, 0.0)])
	luz_ventana.material = _material_aditivo()
	add_child(luz_ventana)
	for datos in [[Vector2(-25, 110), 3.2], [Vector2(607, 312), 1.6]]:
		var b := Sprite2D.new()
		b.texture = _textura_radial(Color(1.0, 0.85, 0.55))
		b.position = datos[0]
		b.scale = Vector2.ONE * datos[1]
		b.modulate.a = 0.35
		b.material = _material_aditivo()
		add_child(b)
		brillos.append(b)

	var motas := _particulas(Color(1, 0.93, 0.75, 0.7), 40, 7.0)
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motas.position = Vector2(800, 380)
	motas.emission_rect_extents = Vector2(170, 250)
	motas.gravity = Vector2(0, -4)
	motas.initial_velocity_min = 2.0
	motas.initial_velocity_max = 8.0
	motas.scale_amount_min = 0.03
	motas.scale_amount_max = 0.07
	motas.preprocess = 7.0
	add_child(motas)

	# La navecita: tres poses que se alternan (volando, con Cometa adentro, vacía).
	nave = Node2D.new()
	add_child(nave)
	estela = _particulas(Color(1.0, 0.85, 0.35), 90, 0.9)
	estela.local_coords = false
	estela.position = Vector2(250, -10)
	estela.spread = 30.0
	estela.initial_velocity_min = 20.0
	estela.initial_velocity_max = 60.0
	estela.scale_amount_min = 0.06
	estela.scale_amount_max = 0.16
	estela.emitting = false
	nave.add_child(estela)
	nave_vuelo = _sprite(TEX_NAVE_VUELO)
	nave.add_child(nave_vuelo)
	nave_cometa = _sprite(TEX_NAVE_COMETA)
	nave.add_child(nave_cometa)
	nave_vacia = _sprite(TEX_NAVE_VUELO)
	nave_vacia.region_enabled = true
	nave_vacia.region_rect = Rect2(0, 0, 468, 514)  # sin las llamas: el motor quedó "apagado"
	nave_vacia.flip_h = true
	nave.add_child(nave_vacia)
	humo = _particulas(Color(0.85, 0.82, 0.88, 0.8), 14, 1.6)
	humo.position = Vector2(-60, -30)
	humo.gravity = Vector2(0, -40)
	humo.scale_amount_min = 0.25
	humo.scale_amount_max = 0.45
	humo.emitting = false
	humo.material = null
	nave.add_child(humo)

	mareo = Node2D.new()
	for i in 3:
		var e := Estrella.new()
		e.radio_ext = 14.0
		e.radio_int = 6.0
		e.position = Vector2.RIGHT.rotated(TAU * i / 3.0) * Vector2(70, 22)
		mareo.add_child(e)
	add_child(mareo)

	# Cometa: PNG plano + shader de gelatina + párpados dibujados por código.
	cometa = Sprite2D.new()
	cometa.texture = TEX_COMETA
	cometa.centered = false
	cometa.offset = Vector2(-240, -500)  # el origen queda en los pies
	mat_cometa = ShaderMaterial.new()
	mat_cometa.shader = SHADER_GELATINA
	cometa.material = mat_cometa
	add_child(cometa)
	for centro in [Vector2(182 - 240, 214 - 500), Vector2(296 - 240, 214 - 500)]:
		var p := Parpado.new()
		p.position = centro
		cometa.add_child(p)
		parpados.append(p)

	var capa := CanvasLayer.new()
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


func _preparar_bus_voz() -> void:
	# Bus propio para medir el volumen de la voz y sincronizar el "habla" de Cometa.
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

	# 1. El living tranquilo (Ken Burns muy lento).
	_tw().tween_property(camara, "zoom", Vector2.ONE * 1.03, 2.6).set_trans(Tween.TRANS_SINE)
	if await _esperar(2.0, gen): return

	# 2. Un destello en la ventana: algo viene.
	_destello(VENTANA, 1.0)
	_sfx(SFX_TILIN)
	if await _esperar(0.8, gen): return

	# 3. La navecita entra por la ventana, descontrolada, con un loop.
	_flash_ventana()
	_sfx(SFX_FIUU)
	nave.visible = true
	nave_vuelo.visible = true
	estela.emitting = true
	_tw().tween_property(camara, "zoom", Vector2.ONE, 0.6)
	_tw().tween_method(_mover_nave, 0.0, 1.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if await _esperar(2.4, gen): return

	# 4. ¡Boing! contra el cojín.
	_choque()
	if await _esperar(0.7, gen): return

	# 5. Rebota hasta la alfombra.
	_rebotes()
	if await _esperar(1.5, gen): return

	# 6. Puf: la nave queda quieta y Cometa aparece adentro, mareado.
	_puf(nave.position + Vector2(0, -40), 1.4)
	nave_vuelo.visible = false
	nave_cometa.visible = true
	nave.rotation = 0.0
	nave.scale = Vector2.ONE * 0.5
	_mostrar_mareo(nave.position + Vector2(40, -170), 1.6)
	if await _esperar(1.8, gen): return

	# 7. Cometa salta afuera.
	_cometa_salta()
	if await _esperar(1.2, gen): return

	# 8. Cometa habla (el cuerpo sigue el volumen de la voz).
	_hablar()
	if await _esperar(0.3, gen): return
	while voz.playing:
		if await _esperar(0.1, gen): return
	_hablando = false

	# 9. Saluda (cambio de pose) y cierre en iris sobre su carita.
	_saludar()
	if await _esperar(1.6, gen): return
	_iris_cerrar()
	if await _esperar(1.0, gen): return
	_terminar()


func saltar() -> void:
	# Regla de los storyboards: desde la 2.ª vez, un toque deja el ESTADO FINAL del plano.
	_generacion += 1
	_matar_tweens()
	voz.stop()
	_hablando = false
	_estado_final()
	_terminar()


func _estado_inicial() -> void:
	_terminada = false
	_cometa_animandose = false
	_trauma = 0.0
	camara.zoom = Vector2.ONE
	camara.offset = Vector2.ZERO
	nave.visible = false
	nave.position = VENTANA
	nave.rotation = 0.0
	nave.scale = Vector2.ONE * 0.1
	nave_vuelo.visible = false
	nave_cometa.visible = false
	nave_vacia.visible = false
	estela.emitting = false
	humo.emitting = false
	mareo.visible = false
	cometa.visible = false
	cometa.texture = TEX_COMETA
	for p in parpados:
		p.visible = true
		p.cierre = 0.0
	(iris.material as ShaderMaterial).set_shader_parameter("radio", 1.5)
	luz_ventana.modulate = Color.WHITE
	_armar_curva()


func _estado_final() -> void:
	_estado_inicial()
	nave.visible = true
	nave.position = ALFOMBRA
	nave.scale = Vector2.ONE * 0.44
	nave.rotation = -0.3
	nave_vacia.visible = true
	humo.emitting = true
	cometa.visible = true
	cometa.position = COMETA_PIE
	cometa.scale = Vector2.ONE * 0.5
	mat_cometa.set_shader_parameter("intensidad", 0.15)


func _terminar() -> void:
	_terminada = true
	_vista_antes = true
	_parpadeo_en_bucle(_generacion)


# ---------------------------------------------------------------- piezas de la coreografía

func _armar_curva() -> void:
	_curva.clear_points()
	var pts := [VENTANA, Vector2(690, 160), Vector2(470, 190), Vector2(350, 330),
		Vector2(470, 430), Vector2(590, 320), Vector2(480, 190), Vector2(320, 240), COJIN]
	for i in pts.size():
		var previo: Vector2 = pts[maxi(i - 1, 0)]
		var siguiente: Vector2 = pts[mini(i + 1, pts.size() - 1)]
		var mango: Vector2 = (siguiente - previo) * 0.22
		_curva.add_point(pts[i], -mango, mango)


func _mover_nave(t: float) -> void:
	var largo := _curva.get_baked_length()
	var pos := _curva.sample_baked(t * largo)
	var adelante := _curva.sample_baked(minf(t * largo + 6.0, largo))
	var dir := adelante - pos
	nave.position = pos
	if dir.length() > 0.5:
		var objetivo := dir.angle() - ANGULO_NARIZ + sin(t * 40.0) * 0.07  # tambaleo de descontrol
		nave.rotation = lerp_angle(nave.rotation, objetivo, 0.35)
	nave.scale = Vector2.ONE * lerpf(0.16, 0.42, ease(t, 1.4))


func _choque() -> void:
	estela.emitting = false
	_sfx(SFX_GOLPE)
	_trauma = 0.9
	_destello(nave.position + Vector2(-50, 0), 1.2)
	var esc := nave.scale
	var tw := _tw()
	tw.tween_property(nave, "scale", Vector2(esc.x * 0.6, esc.y * 1.35), 0.07)
	tw.tween_property(nave, "scale", esc, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tz := _tw()
	tz.tween_property(camara, "zoom", Vector2.ONE * 1.07, 0.06)
	tz.tween_property(camara, "zoom", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_mostrar_mareo(COJIN + Vector2(10, -80), 0.9)


func _rebotes() -> void:
	var tw := _tw()
	var saltos := [[COJIN, Vector2(390, 560), 150.0, 0.6], [Vector2(390, 560), Vector2(540, 584), 60.0, 0.4],
		[Vector2(540, 584), ALFOMBRA, 18.0, 0.25]]
	var giro_inicial := nave.rotation
	for i in saltos.size():
		var s: Array = saltos[i]
		tw.tween_method(func(t: float) -> void:
			nave.position = (s[0] as Vector2).lerp(s[1], t) + Vector2(0, -4.0 * s[2] * t * (1.0 - t))
			nave.rotation = lerp_angle(giro_inicial, 0.0, (i + t) / saltos.size()),
			0.0, 1.0, s[3])
		tw.tween_callback(_aterriza.bind(1.0 - i * 0.3))
	_tw().tween_property(nave, "scale", Vector2.ONE * 0.46, 1.25)


func _aterriza(fuerza: float) -> void:
	_sfx(SFX_BOTE, 0.9 + randf() * 0.2)
	_trauma = maxf(_trauma, 0.3 * fuerza)
	var esc := nave.scale
	var tw := _tw()
	tw.tween_property(nave, "scale", Vector2(esc.x * (1.0 + 0.25 * fuerza), esc.y * (1.0 - 0.25 * fuerza)), 0.06)
	tw.tween_property(nave, "scale", esc, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _cometa_salta() -> void:
	_sfx(SFX_POP)
	nave_cometa.visible = false
	nave_vacia.visible = true
	nave.rotation = -0.3
	nave.scale = Vector2.ONE * 0.44
	humo.emitting = true
	var desde := nave.position + Vector2(50, -60)
	cometa.visible = true
	cometa.position = desde
	cometa.scale = Vector2.ONE * 0.15
	_cometa_animandose = true
	var tw := _tw()
	tw.tween_method(func(t: float) -> void:
		cometa.position = desde.lerp(COMETA_PIE, t) + Vector2(0, -4.0 * 170.0 * t * (1.0 - t))
		cometa.scale = Vector2.ONE * lerpf(0.15, 0.5, t)
		cometa.rotation = sin(t * PI) * 0.25,
		0.0, 1.0, 0.7)
	tw.tween_callback(func() -> void:
		_sfx(SFX_BOTE, 1.2)
		mat_cometa.set_shader_parameter("intensidad", 0.9))
	tw.tween_property(cometa, "scale", Vector2(0.62, 0.38), 0.07)
	tw.tween_property(cometa, "scale", Vector2.ONE * 0.5, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float) -> void: mat_cometa.set_shader_parameter("intensidad", v),
		0.9, 0.15, 1.0)
	tw.tween_callback(func() -> void: _cometa_animandose = false)
	_parpadeo_en_bucle(_generacion)


func _hablar() -> void:
	voz.stream = load(VOZ_COMETA)
	voz.play()
	_hablando = true


func _saludar() -> void:
	# Cambio de pose con un saltito que lo disimula.
	_cometa_animandose = true
	var tw := _tw()
	tw.tween_property(cometa, "position:y", COMETA_PIE.y - 40.0, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		cometa.texture = TEX_COMETA_SALUDO
		for p in parpados:
			p.visible = false)
	tw.tween_property(cometa, "position:y", COMETA_PIE.y, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_property(cometa, "scale", Vector2(0.56, 0.45), 0.06)
	tw.tween_property(cometa, "scale", Vector2.ONE * 0.5, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _cometa_animandose = false)


func _iris_cerrar() -> void:
	var mat := iris.material as ShaderMaterial
	var cara := cometa.get_global_transform_with_canvas() * Vector2(0, -280)
	mat.set_shader_parameter("centro", cara / Vector2(1280, 720))
	var tw := _tw()
	tw.tween_method(func(r: float) -> void: mat.set_shader_parameter("radio", r), 1.5, 0.16, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.25)
	tw.tween_method(func(r: float) -> void: mat.set_shader_parameter("radio", r), 0.16, 0.0, 0.2)


func _parpadeo_en_bucle(gen: int) -> void:
	while gen == _generacion and cometa.visible:
		if await _esperar(randf_range(2.2, 3.8), gen): return
		for p in parpados:
			var tw := _tw()
			tw.tween_property(p, "cierre", 1.0, 0.07)
			tw.tween_interval(0.06)
			tw.tween_property(p, "cierre", 0.0, 0.1)


func _destello(pos: Vector2, tamano: float) -> void:
	var e := Estrella.new()
	e.puntas = 8
	e.radio_ext = 60.0
	e.radio_int = 24.0
	e.relleno = Color(1, 0.97, 0.75)
	e.position = pos
	e.scale = Vector2.ZERO
	add_child(e)
	var tw := _tw()
	tw.tween_property(e, "scale", Vector2.ONE * tamano, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(e, "rotation", 0.6, 0.5)
	tw.tween_property(e, "modulate:a", 0.0, 0.3)
	tw.tween_callback(e.queue_free)


func _flash_ventana() -> void:
	var tw := _tw()
	tw.tween_property(luz_ventana, "modulate", Color(4, 4, 4), 0.08)
	tw.tween_property(luz_ventana, "modulate", Color.WHITE, 0.6)


func _puf(pos: Vector2, tamano: float) -> void:
	_sfx(SFX_PUF)
	var n := Nube.new()
	n.position = pos
	n.scale = Vector2.ONE * 0.3
	add_child(n)
	var tw := _tw()
	tw.tween_property(n, "scale", Vector2.ONE * tamano * 1.5, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE * tamano * 1.8, 0.35)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.35)
	tw.tween_callback(n.queue_free)


func _mostrar_mareo(pos: Vector2, segundos: float) -> void:
	mareo.position = pos
	mareo.visible = true
	mareo.rotation = 0.0
	var tw := _tw()
	tw.tween_property(mareo, "rotation", TAU * segundos * 1.2, segundos)
	tw.tween_callback(func() -> void: mareo.visible = false)


# ---------------------------------------------------------------- cada cuadro

func _process(delta: float) -> void:
	# Sacudida de cámara por "trauma" (cuadrática: los golpes chicos casi no mueven).
	if _trauma > 0.0:
		_trauma = maxf(_trauma - delta * 1.8, 0.0)
		var s := _trauma * _trauma
		camara.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 22.0 * s
		camara.rotation = randf_range(-1, 1) * 0.02 * s
	else:
		camara.offset = Vector2.ZERO
		camara.rotation = 0.0

	# Las lámparas titilan muy suave: el living "vive" aunque nada pase.
	var t := Time.get_ticks_msec() / 1000.0
	for i in brillos.size():
		brillos[i].modulate.a = 0.32 + 0.05 * sin(t * (1.7 + i)) + 0.02 * sin(t * 7.3 + i)

	# Cometa respira; al hablar, el cuerpo sigue el volumen real de la voz.
	# Mientras corre el salto o el saludo, manda el tween y no la respiración.
	if cometa.visible and not _cometa_animandose:
		var base := 0.5
		var amp := 0.0
		if _hablando:
			var pico := AudioServer.get_bus_peak_volume_left_db(_bus_voz, 0)
			amp = clampf((pico + 36.0) / 30.0, 0.0, 1.0)
		var respira := sin(t * 2.4) * 0.012
		cometa.scale = cometa.scale.lerp(Vector2(base * (1.0 - 0.04 * amp - respira * 0.5),
			base * (1.0 + 0.08 * amp + respira)), 0.35)
		mat_cometa.set_shader_parameter("intensidad", lerpf(
			mat_cometa.get_shader_parameter("intensidad"), 0.15 + 0.6 * amp, 0.3))


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
		_destello(get_global_mouse_position(), 0.35)  # 1.ª vez: solo una chispita en el dedo


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



## Espera `segundos`; devuelve true si en el intertanto se saltó o se reinició la secuencia.
func _esperar(segundos: float, gen: int) -> bool:
	# Mismo reloj que los tweens (delta de proceso), así las esperas y las animaciones no se desfasan
	# aunque un cuadro se demore (compilación de shaders, carga de audio).
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
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _sprite(tex: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.visible = false
	return s


func _material_aditivo() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _textura_radial(color: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


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
