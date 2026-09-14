class_name Celebracion
extends CanvasLayer

## Escena de celebracion reutilizable (HE-10, GDD §6 regla 9: "confeti, estrellas, bailecito
## del personaje y frase de animo al completar cualquier cosa").
##
## La monta `MinijuegoBase.celebrar()`; cualquier pantalla puede instanciarla igual. No conoce
## motores ni niveles: recibe quien celebra, cuantos destellos gano y (solo Estrella) cuantas
## estrellitas. La voz de cierre la reproduce quien la monta.
##
## Todo se dibuja con nodos nativos (particulas + poligonos), sin assets nuevos (stack §5),
## con la paleta maestra de docs/guia-estilo-generacion.md §6.
##
## Gesto real de cada hermano (docs/perfil-jugadores.md, GDD §2 "gesto de celebracion canon"):
## - Maxi: 3 saltitos con el puno arriba ("¡siiii!").
## - Nicole: corazon coreano con expresion tierna -> balanceo suave + corazones flotando.
## - Sofia: pose con mano en cintura, signo de la paz y guino -> "pose" ladeada + destello de guino.
## Los sprites `<hermano>_celebracion.png` ya dibujan la pose; aqui se les da vida.
##
## UX (GDD §6): nada apura. El boton "seguir" (140 px, flecha universal, sin texto) aparece
## recien a los ~2 s para que un toque que venia del juego no se salte la fiesta; si nadie lo
## toca, continua sola tras `segundos_auto_continuar`. Mientras dura, bloquea toques al juego.

signal terminada()

const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const DORADO_BRILLO := Color("#FFE38A")
const PALETA_CONFETI := [
	Color("#FFCB3D"), Color("#F26CA8"), Color("#45C6C0"), Color("#3E77CC"),
	Color("#FFE38A"), Color("#9FE5E2"), Color("#F0A8C8"), Color("#6FD6E8"),
]
const PALETA_POR_PERSONAJE := {
	"maxi": [Color("#3E77CC"), Color("#6FD6E8"), Color("#FFCB3D")],
	"nicole": [Color("#F26CA8"), Color("#F0A8C8"), Color("#FFD9EA")],
	"sofia": [Color("#45C6C0"), Color("#9FE5E2"), Color("#FFCB3D")],
}
const RUTA_SPRITE := "res://assets/sprites/personajes/%s_%s.png"
const SFX_INICIO := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_TINTINEO := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_ESTRELLITA := "res://assets/audio/sfx/ui/seleccionar.ogg"
const TAMANO_BOTON := 140.0
## Opacidad del velo: suficiente para que el HUD del juego de abajo no parezca tocable (R3).
const OPACIDAD_FONDO := 0.7

## "maxi" | "nicole" | "sofia" (otro id -> rebote generico con su sprite o el de Cometa).
@export var id_personaje: String = "sofia"
@export var destellos: int = 0
## 0 = no se muestran estrellitas (Semilla/Brote o motor sin puntaje).
@export_range(0, 3) var estrellitas: int = 0
@export var segundos_boton_continuar: float = 2.2
## 0 = espera siempre el toque del boton.
@export var segundos_auto_continuar: float = 8.0

var _tamano := Vector2(1280, 720)
var _alto := 420.0
var _centro_personaje := Vector2.ZERO
var _pos_pies := Vector2.ZERO
var _centro_conteo := Vector2.ZERO
var _escala_personaje := 1.0

var _raiz: Control
var _fondo: ColorRect
var _halo: Halo
var _personaje: Sprite2D
var _explosion: CPUParticles2D
var _lluvia: CPUParticles2D
var _estrella_conteo: Figura
var _etiqueta_conteo: Label
var _slots_estrellitas: Array[Figura] = []
var _boton_continuar: Button

var _tiempo := 0.0
var _gesto_activo := false
var _t_gesto := 0.0
var _ultimo_salto := -1
var _ultimo_ciclo_pose := -1
var _proximo_corazon := 0.0
var _ultimo_conteo := -1
var _ms_ultimo_tintineo := 0
var _boton_mostrado := false
var _terminada := false
var _tween_pulso: Tween
## Altura extra (px) de un saltito por mimo: se suma encima del gesto del hermano.
var _salto_mimo := 0.0
var _corazones_creados := 0


func _ready() -> void:
	layer = 50
	_tamano = get_viewport().get_visible_rect().size
	_alto = minf(440.0, _tamano.y * 0.62)
	_centro_personaje = Vector2(_tamano.x * 0.33, _tamano.y * 0.50)
	_pos_pies = _centro_personaje + Vector2(0, _alto / 2.0)
	_centro_conteo = Vector2(_tamano.x * 0.70, _tamano.y * 0.30)
	_construir()
	_iniciar()


func _process(delta: float) -> void:
	if _terminada:
		return
	_tiempo += delta
	if _gesto_activo:
		_t_gesto += delta
		_aplicar_gesto()
		_personaje.position.y -= _salto_mimo
	if not _boton_mostrado and _tiempo >= segundos_boton_continuar:
		_mostrar_boton_continuar()
	if segundos_auto_continuar > 0.0 and _tiempo >= segundos_auto_continuar:
		terminar()


## Cierra la celebracion (fundido corto) y emite `terminada`. Idempotente.
func terminar() -> void:
	if _terminada:
		return
	_terminada = true
	_gesto_activo = false
	if _boton_continuar != null:
		_boton_continuar.disabled = true
	if _tween_pulso != null:
		_tween_pulso.kill()
	var t := create_tween()
	t.tween_property(_raiz, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: terminada.emit())


# --- Construccion --------------------------------------------------------------------------

func _construir() -> void:
	_raiz = Control.new()
	_raiz.name = "raiz"
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Bloquea toques al juego de abajo mientras se celebra.
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	# ...pero ningun toque queda sin respuesta (GDD §6 regla 5, auditoria UX R3).
	_raiz.gui_input.connect(_al_tocar_fondo)
	add_child(_raiz)

	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(COLOR_CONTORNO, 0.0)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_fondo)

	_halo = Halo.new()
	_halo.radio = _tamano.y * 0.55
	_halo.position = _centro_personaje
	_halo.scale = Vector2.ZERO
	_raiz.add_child(_halo)

	_explosion = _crear_confeti(true)
	_raiz.add_child(_explosion)

	_personaje = Sprite2D.new()
	_personaje.name = "personaje"
	var textura := _cargar_textura_personaje()
	_personaje.texture = textura
	if textura != null:
		# Origen en los pies: los saltos y el "squash" se apoyan en el piso.
		_personaje.offset = Vector2(0, -textura.get_height() / 2.0)
		_escala_personaje = _alto / textura.get_height()
	_personaje.position = _pos_pies
	_personaje.scale = Vector2.ZERO
	_raiz.add_child(_personaje)

	_lluvia = _crear_confeti(false)
	_raiz.add_child(_lluvia)

	_estrella_conteo = Figura.new()
	_estrella_conteo.radio = 58.0
	_estrella_conteo.color = DORADO
	_estrella_conteo.grosor_contorno = 7.0
	_estrella_conteo.position = _centro_conteo + Vector2(-120, 0)
	_estrella_conteo.scale = Vector2.ZERO
	_raiz.add_child(_estrella_conteo)

	_etiqueta_conteo = Label.new()
	_etiqueta_conteo.name = "conteo"
	_etiqueta_conteo.text = "0"
	_etiqueta_conteo.add_theme_font_size_override("font_size", 110)
	_etiqueta_conteo.add_theme_color_override("font_color", Color.WHITE)
	_etiqueta_conteo.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
	_etiqueta_conteo.add_theme_constant_override("outline_size", 24)
	_etiqueta_conteo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_etiqueta_conteo.size = Vector2(320, 150)
	_etiqueta_conteo.position = _centro_conteo + Vector2(-44, -75)
	_etiqueta_conteo.pivot_offset = Vector2(70, 75)
	_etiqueta_conteo.modulate.a = 0.0
	_raiz.add_child(_etiqueta_conteo)

	if estrellitas > 0:
		for i in 3:
			var slot := Figura.new()
			slot.radio = 44.0
			# Hueco "por llenar": blanco suave con contorno dorado, no gris ni oliva (M2), para
			# que no se lea como castigo.
			slot.color = Color(1, 1, 1, 0.16)
			slot.color_contorno = DORADO
			slot.grosor_contorno = 6.0
			slot.position = _centro_conteo + Vector2(-110 + i * 110, 160)
			slot.scale = Vector2.ZERO
			_raiz.add_child(slot)
			_slots_estrellitas.append(slot)

	_boton_continuar = Button.new()
	_boton_continuar.name = "boton_continuar"
	_boton_continuar.custom_minimum_size = Vector2(TAMANO_BOTON, TAMANO_BOTON)
	_boton_continuar.size = Vector2(TAMANO_BOTON, TAMANO_BOTON)
	_boton_continuar.position = Vector2(_tamano.x * 0.70, _tamano.y * 0.80) - _boton_continuar.size / 2.0
	_boton_continuar.pivot_offset = _boton_continuar.size / 2.0
	_boton_continuar.focus_mode = Control.FOCUS_NONE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = DORADO
	estilo.set_corner_radius_all(int(TAMANO_BOTON / 2.0))
	estilo.set_border_width_all(7)
	estilo.border_color = COLOR_CONTORNO
	for nombre_estilo in ["normal", "hover", "pressed", "focus", "disabled"]:
		_boton_continuar.add_theme_stylebox_override(nombre_estilo, estilo)
	var flecha := Figura.new()
	flecha.tipo = "flecha"
	flecha.radio = 40.0
	flecha.color = Color.WHITE
	flecha.grosor_contorno = 6.0
	flecha.position = _boton_continuar.size / 2.0 + Vector2(6, 0)
	_boton_continuar.add_child(flecha)
	_boton_continuar.visible = false
	# Responde al APOYAR el dedo (R1): si el dedo de Maxi resbala al soltar, igual avanza.
	# El boton aparece recien a los ~2 s, asi que un toque que venia del juego no lo dispara.
	_boton_continuar.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_boton_continuar.button_down.connect(_al_apretar_boton)
	_boton_continuar.pressed.connect(terminar)
	_raiz.add_child(_boton_continuar)


func _cargar_textura_personaje() -> Texture2D:
	for variante in ["celebracion", "base"]:
		var ruta := RUTA_SPRITE % [id_personaje, variante]
		if ResourceLoader.exists(ruta):
			return load(ruta)
	var ruta_cometa := RUTA_SPRITE % ["cometa", "base"]
	if ResourceLoader.exists(ruta_cometa):
		return load(ruta_cometa)
	return null


func _crear_confeti(es_explosion: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var gradiente := Gradient.new()
	gradiente.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colores := PackedColorArray()
	for i in PALETA_CONFETI.size():
		offsets.append(float(i) / PALETA_CONFETI.size())
		colores.append(PALETA_CONFETI[i])
	gradiente.offsets = offsets
	gradiente.colors = colores
	p.color_initial_ramp = gradiente
	p.emitting = false
	p.scale_amount_min = 8.0
	p.scale_amount_max = 14.0
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	if es_explosion:
		p.position = _centro_personaje
		p.amount = 120
		p.lifetime = 2.2
		p.one_shot = true
		p.explosiveness = 1.0
		p.direction = Vector2.UP
		p.spread = 180.0
		p.initial_velocity_min = 320.0
		p.initial_velocity_max = 760.0
		p.damping_min = 60.0
		p.damping_max = 120.0
		p.gravity = Vector2(0, 650)
	else:
		p.position = Vector2(_tamano.x / 2.0, -30)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(_tamano.x / 2.0, 10)
		p.amount = 200
		p.lifetime = 4.0
		p.direction = Vector2.DOWN
		p.spread = 20.0
		p.initial_velocity_min = 90.0
		p.initial_velocity_max = 260.0
		p.gravity = Vector2(0, 160)
	return p


# --- Secuencia -----------------------------------------------------------------------------

func _iniciar() -> void:
	_sfx(SFX_INICIO)
	var t := create_tween().set_parallel(true)
	t.tween_property(_fondo, "color:a", OPACIDAD_FONDO, 0.35)
	t.tween_property(_halo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_personaje, "scale", Vector2.ONE * _escala_personaje, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	_explosion.emitting = true
	_lluvia.emitting = true
	_estallido_estrellitas(_centro_personaje, 12, [])
	_despues(0.6, func() -> void: _gesto_activo = true)
	_despues(0.7, _iniciar_conteo)
	_despues(3.0, func() -> void: _lluvia.emitting = false)


func _iniciar_conteo() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_estrella_conteo, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_etiqueta_conteo, "modulate:a", 1.0, 0.2)
	for slot in _slots_estrellitas:
		t.tween_property(slot, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var duracion := clampf(0.6 + destellos * 0.012, 0.8, 1.8)
	var t2 := create_tween()
	t2.tween_interval(0.25)
	t2.tween_method(_fijar_conteo, 0.0, float(destellos), duracion).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t2.tween_callback(_al_terminar_conteo)


func _fijar_conteo(valor: float) -> void:
	var entero := roundi(valor)
	if entero == _ultimo_conteo:
		return
	_ultimo_conteo = entero
	_etiqueta_conteo.text = str(entero)
	var ahora := Time.get_ticks_msec()
	if ahora - _ms_ultimo_tintineo > 90:
		_ms_ultimo_tintineo = ahora
		_sfx(SFX_TINTINEO)


func _al_terminar_conteo() -> void:
	_etiqueta_conteo.text = str(destellos)
	var t := create_tween().set_parallel(true)
	t.tween_property(_etiqueta_conteo, "scale", Vector2.ONE * 1.25, 0.12)
	t.tween_property(_estrella_conteo, "rotation", TAU, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(_etiqueta_conteo, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_estallido_estrellitas(_estrella_conteo.position, 8, [])
	for i in mini(estrellitas, _slots_estrellitas.size()):
		_despues(0.4 * (i + 1), _llenar_estrellita.bind(i))


func _llenar_estrellita(indice: int) -> void:
	var slot := _slots_estrellitas[indice]
	slot.color = DORADO
	slot.color_contorno = COLOR_CONTORNO
	slot.queue_redraw()
	slot.scale = Vector2.ONE * 1.4
	var t := slot.create_tween()
	t.tween_property(slot, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_estallido_estrellitas(slot.position, 6, [])
	_sfx(SFX_ESTRELLITA)


func _mostrar_boton_continuar() -> void:
	_boton_mostrado = true
	_boton_continuar.visible = true
	_boton_continuar.scale = Vector2.ZERO
	var t := _boton_continuar.create_tween()
	t.tween_property(_boton_continuar, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(_pulsar_boton)


func _pulsar_boton() -> void:
	if _terminada:
		return
	_tween_pulso = _boton_continuar.create_tween().set_loops()
	_tween_pulso.tween_property(_boton_continuar, "scale", Vector2.ONE * 1.08, 0.5).set_trans(Tween.TRANS_SINE)
	_tween_pulso.tween_property(_boton_continuar, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


## Respuesta visual + sonora inmediata al apoyar el dedo (R2, GDD §6 regla 5).
func _al_apretar_boton() -> void:
	_sfx(SFX_TINTINEO)
	if _tween_pulso != null:
		_tween_pulso.kill()
	var t := _boton_continuar.create_tween()
	t.tween_property(_boton_continuar, "scale", Vector2.ONE * 0.88, 0.08)
	_estallido_estrellitas(_boton_continuar.position + _boton_continuar.size / 2.0, 6, [])


## Toques fuera del boton: mimar al personaje le arranca un saltito extra; cualquier otro
## punto suelta unas estrellitas donde toco el dedo. Nunca avanza ni cierra (eso es del boton).
func _al_tocar_fondo(evento: InputEvent) -> void:
	if _terminada:
		return
	var posicion := Vector2.ZERO
	if evento is InputEventScreenTouch and evento.pressed:
		posicion = evento.position
	elif evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		posicion = evento.position
	else:
		return
	_raiz.accept_event()
	if _toca_personaje(posicion):
		_mimo_personaje()
	else:
		_estallido_estrellitas(posicion, 5, [])
		_sfx(SFX_TINTINEO)


func _toca_personaje(posicion: Vector2) -> bool:
	var ancho := _alto * 0.45
	var rect := Rect2(_pos_pies.x - ancho / 2.0, _pos_pies.y - _alto, ancho, _alto)
	return rect.grow(40.0).has_point(posicion)


func _mimo_personaje() -> void:
	_sfx(SFX_ESTRELLITA)
	_estallido_estrellitas(_pos_pies - Vector2(0, _alto * 0.6), 8, PALETA_POR_PERSONAJE.get(id_personaje, []))
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _salto_mimo = v, 0.0, _alto * 0.12, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_method(func(v: float) -> void: _salto_mimo = v, _alto * 0.12, 0.0, 0.24) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# --- Gestos por hermano -------------------------------------------------------------------

func _aplicar_gesto() -> void:
	match id_personaje:
		"maxi":
			_gesto_maxi()
		"nicole":
			_gesto_nicole()
		"sofia":
			_gesto_sofia()
		_:
			_gesto_rebote()


## 3 saltitos seguidos con squash & stretch, pausa, y otra vez.
func _gesto_maxi() -> void:
	const DURACION_SALTO := 0.42
	const CICLO := 2.2
	var e := _escala_personaje
	var fase := fmod(_t_gesto, CICLO)
	var salto := int(fase / DURACION_SALTO)
	if salto < 3:
		var u := fmod(fase, DURACION_SALTO) / DURACION_SALTO
		var k := sin(PI * u)
		_personaje.position = _pos_pies - Vector2(0, k * _alto * 0.2)
		_personaje.scale = Vector2(e * (1.08 - 0.13 * k), e * (0.9 + 0.16 * k))
		var id_salto := int(_t_gesto / CICLO) * 3 + salto
		if u > 0.45 and id_salto != _ultimo_salto:
			_ultimo_salto = id_salto
			_estallido_estrellitas(_personaje.position - Vector2(0, _alto * 0.85), 4, PALETA_POR_PERSONAJE["maxi"])
	else:
		_personaje.position = _pos_pies
		_personaje.scale = Vector2(e, e * (1.0 + 0.02 * sin(_t_gesto * 6.0)))


## Balanceo tierno + corazones que flotan desde las manos.
func _gesto_nicole() -> void:
	var e := _escala_personaje
	_personaje.rotation = deg_to_rad(5.0) * sin(_t_gesto * 2.6)
	_personaje.scale = Vector2.ONE * e * (1.0 + 0.025 * sin(_t_gesto * 5.2))
	if _t_gesto >= _proximo_corazon:
		_proximo_corazon = _t_gesto + 0.3
		_corazon_flotante()


func _corazon_flotante() -> void:
	var paleta: Array = PALETA_POR_PERSONAJE["nicole"]
	var c := Figura.new()
	c.tipo = "corazon"
	c.radio = randf_range(22.0, 38.0)
	c.color = paleta[randi() % paleta.size()]
	c.grosor_contorno = 4.0
	# Nacen a los costados, a la altura del pecho, y suben hacia afuera: nunca tapan la
	# carita tierna de Nicole (auditoria UX R4).
	var lado := -1.0 if _corazones_creados % 2 == 0 else 1.0
	_corazones_creados += 1
	c.position = _pos_pies + Vector2(lado * randf_range(_alto * 0.26, _alto * 0.36), -_alto * 0.45)
	c.scale = Vector2.ZERO
	_raiz.add_child(c)
	var destino := c.position + Vector2(lado * randf_range(40.0, 110.0), -randf_range(160.0, 280.0))
	# M3: un sonido suave cada 3 corazones, equivalente al del guino de Sofia.
	if _corazones_creados % 3 == 1:
		_sfx(SFX_ESTRELLITA)
	var t := c.create_tween().set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "position", destino, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "rotation", randf_range(-0.4, 0.4), 1.4)
	t.tween_property(c, "modulate:a", 0.0, 0.5).set_delay(0.9)
	t.chain().tween_callback(c.queue_free)


## "Pose": se ladea con rebote, se queda posando, destello de guino, y vuelve a posar.
func _gesto_sofia() -> void:
	const CICLO := 2.4
	var e := _escala_personaje
	var ciclo := int(_t_gesto / CICLO)
	var fase := fmod(_t_gesto, CICLO)
	var k := 0.0
	if fase < 0.3:
		k = _ease_out_back(fase / 0.3)
	elif fase < 1.9:
		k = 1.0
	else:
		k = 1.0 - (fase - 1.9) / 0.5
	_personaje.rotation = deg_to_rad(-7.0) * k
	_personaje.position = _pos_pies + Vector2(14.0 * k, 0)
	_personaje.scale = Vector2.ONE * e * (1.0 + 0.04 * k)
	if fase >= 0.3 and ciclo != _ultimo_ciclo_pose:
		_ultimo_ciclo_pose = ciclo
		_destello_guino()


func _destello_guino() -> void:
	var paleta: Array = PALETA_POR_PERSONAJE["sofia"]
	var d := Figura.new()
	d.radio = 34.0
	d.color = DORADO_BRILLO
	d.grosor_contorno = 4.0
	d.position = _pos_pies + Vector2(_alto * 0.2, -_alto * 0.86)
	d.scale = Vector2.ZERO
	_raiz.add_child(d)
	var t := d.create_tween()
	t.set_parallel(true)
	t.tween_property(d, "scale", Vector2.ONE * 1.3, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(d, "rotation", PI, 0.6)
	t.chain().tween_property(d, "scale", Vector2.ZERO, 0.3)
	t.chain().tween_callback(d.queue_free)
	_estallido_estrellitas(d.position, 5, paleta)
	_sfx(SFX_ESTRELLITA)


func _gesto_rebote() -> void:
	var e := _escala_personaje
	_personaje.position = _pos_pies - Vector2(0, absf(sin(_t_gesto * 3.2)) * _alto * 0.1)
	_personaje.scale = Vector2.ONE * e


# --- Utilidades ---------------------------------------------------------------------------

func _estallido_estrellitas(centro: Vector2, cantidad: int, paleta: Array) -> void:
	for i in cantidad:
		var f := Figura.new()
		f.radio = randf_range(14.0, 26.0)
		f.color = DORADO if paleta.is_empty() else paleta[i % paleta.size()]
		f.grosor_contorno = 3.0
		f.position = centro
		f.scale = Vector2.ZERO
		_raiz.add_child(f)
		var angulo := TAU * i / cantidad + randf_range(-0.25, 0.25)
		var destino := centro + Vector2.from_angle(angulo) * randf_range(_alto * 0.35, _alto * 0.7)
		var t := f.create_tween().set_parallel(true)
		t.tween_property(f, "position", destino, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(f, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(f, "rotation", randf_range(-PI, PI), 0.9)
		# Se apagan achicandose, no con transparencia: el dorado semitransparente sobre el velo
		# oscuro se veia cafe (M1).
		t.tween_property(f, "scale", Vector2.ZERO, 0.3).set_delay(0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(f.queue_free)


func _despues(segundos: float, accion: Callable) -> void:
	# Tween (atado a este nodo) en vez de SceneTreeTimer: si la celebracion se libera antes,
	# la accion muere con ella en vez de llamar a un nodo liberado.
	var t := create_tween()
	t.tween_interval(segundos)
	t.tween_callback(accion)


func _sfx(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)


static func _ease_out_back(x: float) -> float:
	const C1 := 1.70158
	const C3 := C1 + 1.0
	return 1.0 + C3 * pow(x - 1.0, 3.0) + C1 * pow(x - 1.0, 2.0)


## Estrella, corazon o flecha vectorial con el contorno universal del elenco.
class Figura extends Node2D:
	var tipo := "estrella"
	var radio := 30.0
	var color := Color.WHITE
	var grosor_contorno := 5.0
	var color_contorno := Color("#2B3350")

	func _draw() -> void:
		var puntos: PackedVector2Array
		match tipo:
			"corazon":
				puntos = _puntos_corazon()
			"flecha":
				puntos = PackedVector2Array([
					Vector2(-radio * 0.55, -radio * 0.75), Vector2(radio * 0.8, 0), Vector2(-radio * 0.55, radio * 0.75),
				])
			_:
				puntos = _puntos_estrella()
		draw_colored_polygon(puntos, color)
		if grosor_contorno > 0.0:
			var cerrado := puntos.duplicate()
			cerrado.append(puntos[0])
			draw_polyline(cerrado, color_contorno, grosor_contorno, true)

	func _puntos_estrella() -> PackedVector2Array:
		var puntos := PackedVector2Array()
		for i in 10:
			var r := radio if i % 2 == 0 else radio * 0.5
			puntos.append(Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * r)
		return puntos

	func _puntos_corazon() -> PackedVector2Array:
		var puntos := PackedVector2Array()
		for i in 36:
			var a := TAU * i / 36.0
			var x := 16.0 * pow(sin(a), 3.0)
			var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
			puntos.append(Vector2(x, y) * radio / 16.0)
		return puntos


## Rayos de sol pastel girando detras del personaje.
class Halo extends Node2D:
	var radio := 380.0
	var rayos := 16

	func _process(delta: float) -> void:
		rotation += delta * 0.35

	func _draw() -> void:
		var paso := TAU / rayos
		for i in rayos:
			var color: Color = Color(1.0, 0.9, 0.55, 0.62) if i % 2 == 0 else Color(0.62, 0.92, 0.9, 0.34)
			draw_colored_polygon(PackedVector2Array([
				Vector2.ZERO, Vector2.from_angle(paso * i) * radio, Vector2.from_angle(paso * (i + 1)) * radio,
			]), color)
		draw_circle(Vector2.ZERO, radio * 0.42, Color(1.0, 0.97, 0.82, 0.6))
