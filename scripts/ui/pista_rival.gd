extends Control

## Pista del rival (docs/fichas/modo-equipo.md §4.1, §4.3 y §5.3; HE-59): franja de arriba, `Rect2(0, 0,
## 1280, 100)`. A la izquierda Cometa (tocable, lo resuelve el gestor); despues el camino de galletas
## (x 130-930) con el Coleccionauta a pie y su mochila-torre en la espalda; a la derecha la mesa del
## equipo con la cinta arcoiris (x 940-1150) que se llena con cada acierto del equipo, sin numeros.
##
## Solo dibuja y anima lo que el `GestorTurnos` le dice; no sabe de cartas. Canon del Coleccionauta
## (guionista, 06-Oct-2026): gafas-lupa y mochila-torre; nunca da miedo, nunca se hace dano. El dibujo es
## PROVISIONAL (vectorial por codigo) hasta las poses de `disenador-personajes` (§10): saltar, tropezar
## hacia atras y de pie, resbalar y quedar sentado, embobado, aplaudir, aspirar, estornudar, sentarse.

const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const ARCOIRIS := [Color("#FF6B6B"), Color("#FF9F4A"), Color("#FFCB3D"), Color("#7DD87A"), Color("#4A8BE0"), Color("#B48CE8")]
const RECT_COMETA := Rect2(8, 4, 110, 96)
const RUTA_COMETA := "res://assets/sprites/personajes/cometa_base.png"
const X_INICIO := 160.0
const X_MESA := 968.0
const Y_PISO := 90.0

var pasos := 5
var record := -1
var fraccion_cinta := 0.0

var _x := X_INICIO
var _salto := 0.0
var _escala := Vector2.ONE
var _giro := 0.0
var _sentado := false
var _gafas := 0.0
var _mochila := 1.0
var _cara := "normal"
var _estrellitas := 0.0
var _tiempo := 0.0
var _tween: Tween
var _textura_cometa: Texture2D
var _salto_bandera := 0.0
var _salto_cometa := 0.0
## true mientras dura la animacion del resbalon: el "plof" nunca se corta (QA §14.9).
var resbalando := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(1280, 100)
	if ResourceLoader.exists(RUTA_COMETA):
		_textura_cometa = load(RUTA_COMETA)


func configurar(pasos_rival: int, record_pasos: int) -> void:
	pasos = maxi(1, pasos_rival)
	record = record_pasos
	_x = x_galleta(0)
	queue_redraw()


func x_galleta(i: float) -> float:
	return lerpf(X_INICIO, X_MESA, clampf(i / float(pasos), 0.0, 1.0))


func _process(delta: float) -> void:
	_tiempo += delta
	if _estrellitas > 0.0:
		_estrellitas = maxf(0.0, _estrellitas - delta)
	queue_redraw()


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Franja suave de fondo para separar la pista del tablero.
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.17, 0.09, 0.36, 0.45)
	fondo.set_corner_radius_all(30)
	draw_style_box(fondo, Rect2(122, 6, 1036, 90))
	_dibujar_cometa()
	for i in pasos:
		_dibujar_galleta(Vector2(x_galleta(i), Y_PISO - 6.0), i)
	if record >= 0 and record < pasos:
		_dibujar_banderita(Vector2(x_galleta(record) + 18.0, Y_PISO - 10.0 - _salto_bandera))
	_dibujar_mesa()
	_dibujar_coleccionauta()


func _dibujar_cometa() -> void:
	if _textura_cometa == null:
		draw_circle(RECT_COMETA.get_center(), 44.0, Color("#CFF5F1"))
		return
	var lado := 92.0
	var tam := Vector2(lado * _textura_cometa.get_width() / float(_textura_cometa.get_height()), lado)
	var centro := RECT_COMETA.get_center() + Vector2(0, -_salto_cometa - 2.5 * (1.0 - cos(_tiempo * TAU / 3.0)))
	draw_texture_rect(_textura_cometa, Rect2(centro - tam / 2.0, tam), false)


func _dibujar_galleta(centro: Vector2, i: int) -> void:
	draw_circle(centro + Vector2(0, 3), 17.0, Color(COLOR_CONTORNO, 0.25))
	draw_circle(centro, 17.0, Color("#E7B472"))
	draw_arc(centro, 17.0, 0.0, TAU, 28, COLOR_CONTORNO, 3.0, true)
	# Glaseado de colores (resbaloso, para el gag del resbalon).
	draw_circle(centro + Vector2(0, -2), 11.0, ARCOIRIS[i % ARCOIRIS.size()].lerp(Color.WHITE, 0.35))
	for k in 3:
		draw_circle(centro + Vector2.from_angle(k * 2.1 + i) * 7.0, 2.0, COLOR_CONTORNO)


func _dibujar_banderita(base: Vector2) -> void:
	draw_line(base, base + Vector2(0, -40), COLOR_CONTORNO, 3.0, true)
	var tela := PackedVector2Array([base + Vector2(0, -40), base + Vector2(26, -33), base + Vector2(0, -24)])
	draw_colored_polygon(tela, Color("#45C6C0"))
	draw_polyline(tela + PackedVector2Array([tela[0]]), COLOR_CONTORNO, 2.5, true)


func _dibujar_mesa() -> void:
	var tabla := Rect2(946, 64, 200, 16)
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#C98B5A")
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(6)
	draw_style_box(caja, tabla)
	for x in [962.0, 1130.0]:
		draw_line(Vector2(x, 80), Vector2(x, 96), COLOR_CONTORNO, 5.0, true)
	# Cinta arcoiris: se llena de izquierda a derecha con cada acierto. Lo que falta se ve "por llenar"
	# (contorno punteado), nunca gris ni tachado.
	var izquierda := 966.0
	var ancho := 170.0
	var lleno := ancho * clampf(fraccion_cinta, 0.0, 1.0)
	for b in ARCOIRIS.size():
		var y := 22.0 + b * 6.0
		if lleno > 0.0:
			draw_rect(Rect2(izquierda, y, lleno, 6.0), ARCOIRIS[b])
	var x := izquierda
	while x < izquierda + ancho:
		draw_line(Vector2(x, 20), Vector2(minf(x + 8.0, izquierda + ancho), 20), Color(1, 1, 1, 0.7), 2.0)
		draw_line(Vector2(x, 60), Vector2(minf(x + 8.0, izquierda + ancho), 60), Color(1, 1, 1, 0.7), 2.0)
		x += 14.0


func _dibujar_coleccionauta() -> void:
	var pies := Vector2(_x, Y_PISO - _salto)
	draw_set_transform(pies, _giro, _escala)
	var alto := 30.0 if _sentado else 46.0
	# Mochila-torre en la espalda: tres cajitas apiladas (la que aspira y estornuda).
	for k in 3:
		var lado := (20.0 - k * 3.0) * _mochila
		var caja := Rect2(Vector2(-30.0 - lado / 2.0, -alto - 8.0 - k * 17.0 * _mochila), Vector2(lado, 16.0 * _mochila))
		draw_rect(caja, ARCOIRIS[(k * 2) % ARCOIRIS.size()].lerp(Color("#B9B4C9"), 0.35))
		draw_rect(caja, COLOR_CONTORNO, false, 2.5)
	# Cuerpo redondo y pancita.
	var cuerpo := Rect2(Vector2(-22, -alto), Vector2(44, alto))
	var piel := StyleBoxFlat.new()
	piel.bg_color = Color("#9B7BD8")
	piel.border_color = COLOR_CONTORNO
	piel.set_border_width_all(3)
	piel.set_corner_radius_all(22)
	draw_style_box(piel, cuerpo)
	# Cabeza.
	var cabeza := Vector2(0, -alto - 16.0)
	draw_circle(cabeza, 20.0, Color("#B39AE6"))
	draw_arc(cabeza, 20.0, 0.0, TAU, 32, COLOR_CONTORNO, 3.0, true)
	# Gafas-lupa (se le resbalan a la punta de la nariz con cada acierto del equipo).
	var gafas := cabeza + Vector2(0, -2.0 + _gafas)
	for lado in [-1.0, 1.0]:
		var lente := gafas + Vector2(lado * 9.0, 0)
		draw_circle(lente, 8.0, Color(0.85, 0.97, 1.0, 0.9))
		draw_arc(lente, 8.0, 0.0, TAU, 20, COLOR_CONTORNO, 2.5, true)
		_dibujar_ojo(lente)
	draw_line(gafas + Vector2(-1, 0), gafas + Vector2(1, 0), COLOR_CONTORNO, 2.0)
	# Boca segun la cara.
	var boca := cabeza + Vector2(0, 10)
	match _cara:
		"ay_no":
			draw_circle(boca, 3.5, COLOR_CONTORNO)
		"risa", "embobado":
			draw_arc(boca + Vector2(0, -2), 6.0, 0.2, PI - 0.2, 12, COLOR_CONTORNO, 2.5, true)
		_:
			draw_arc(boca + Vector2(0, -3), 5.0, 0.4, PI - 0.4, 10, COLOR_CONTORNO, 2.5, true)
	# Piecitos.
	for lado in [-1.0, 1.0]:
		draw_circle(Vector2(lado * 11.0, -2.0), 6.0, Color("#6A4CC7"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Estrellitas que giran sobre la cabeza (resbalon, gag): risa avergonzada, nunca dolor.
	if _estrellitas > 0.0 or _sentado:
		var centro := pies + Vector2(0, -alto - 46.0)
		for k in 3:
			var p := centro + Vector2.from_angle(_tiempo * 4.0 + k * TAU / 3.0) * Vector2(20.0, 6.0)
			_estrellita(p, 5.0, DORADO)


func _dibujar_ojo(lente: Vector2) -> void:
	if _cara == "embobado":
		_estrellita(lente, 4.0, Color("#F26CA8"))
	else:
		draw_circle(lente + Vector2(0, 1), 2.5, COLOR_CONTORNO)


func _estrellita(centro: Vector2, radio: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 10:
		var r := radio if i % 2 == 0 else radio * 0.5
		puntos.append(centro + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * r)
	draw_colored_polygon(puntos, color)


# ---------------------------------------------------------------------------
# Animaciones (las pide el gestor)
# ---------------------------------------------------------------------------

func _nuevo_tween() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_salto = 0.0
	_giro = 0.0
	_escala = Vector2.ONE
	_tween = create_tween()
	return _tween


func fijar_posicion(i: int) -> void:
	_x = x_galleta(i)


## Paso 2: salta una galleta con un "boing" (B3).
func saltar_a(i: int) -> void:
	var tween := _nuevo_tween()
	_cara = "risa"
	tween.tween_property(self, "_escala", Vector2(1.15, 0.85), 0.08)
	tween.tween_property(self, "_escala", Vector2(0.9, 1.12), 0.1)
	tween.parallel().tween_property(self, "_x", x_galleta(i), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(func(t: float) -> void: _salto = sin(t * PI) * 26.0, 0.0, 1.0, 0.42)
	tween.tween_property(self, "_escala", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _cara = "normal")


## Paso 0b (turno perfecto) o racha de 3: tropieza HACIA ATRAS braceando y queda DE PIE.
func tropezar_atras(i: int) -> void:
	var tween := _nuevo_tween()
	_cara = "ay_no"
	tween.tween_property(self, "_x", x_galleta(i), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(t: float) -> void: _giro = sin(t * TAU * 2.0) * 0.3, 0.0, 1.0, 0.55)
	tween.tween_property(self, "_giro", 0.0, 0.1)
	tween.tween_callback(func() -> void: _cara = "normal")


## Paso 2 tras un turno perfecto (PO 07-Oct-2026, UX N10): intenta saltar, se resbala en SU galleta y
## queda sentado (1,1 s). No cambia de galleta. Se para recien con `pararse()` (al empezar el turno).
func resbalar() -> void:
	var tween := _nuevo_tween()
	resbalando = true
	_cara = "normal"
	# 1. Impulso (0-0,15): se agacha para saltar.
	tween.tween_property(self, "_escala", Vector2(1.1, 0.85), 0.15)
	# 2. Saltito corto (0,15-0,35).
	tween.tween_property(self, "_salto", 9.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_escala", Vector2.ONE, 0.2)
	# 3. Patina (0,35-0,7): pies en ruedita y gafas a la punta de la nariz.
	tween.tween_method(func(t: float) -> void:
		_giro = sin(t * TAU * 3.0) * 0.18
		_gafas = t * 5.0, 0.0, 1.0, 0.35)
	tween.parallel().tween_property(self, "_salto", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 4. Plof (0,7-0,9): cae sentado, aplastado a lo ancho; la mochila rebota.
	tween.tween_callback(func() -> void:
		_sentado = true
		_giro = 0.0)
	tween.tween_property(self, "_escala", Vector2(1.2, 0.82), 0.08)
	tween.tween_property(self, "_escala", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_mochila", 1.15, 0.06)
	tween.tween_property(self, "_mochila", 1.0, 0.06)
	# 5. Sentado (0,9-1,1): estrellitas y cara de risa avergonzada ("je").
	tween.tween_callback(func() -> void:
		_cara = "risa"
		_estrellitas = 1.2)
	tween.tween_interval(0.2)
	tween.tween_callback(func() -> void: resbalando = false)


## Al empezar el turno: se para, se sacude y se acomoda las gafas (0,4 s, sin sonido). Si el resbalon
## todavia no termino, espera al "plof" (nunca se corta).
func pararse() -> void:
	if not _sentado:
		return
	if resbalando:
		await get_tree().create_timer(0.25).timeout
		if resbalando:
			_tween.finished.connect(pararse, CONNECT_ONE_SHOT)
			return
	var tween := _nuevo_tween()
	tween.tween_callback(func() -> void: _sentado = false)
	tween.tween_method(func(t: float) -> void: _giro = sin(t * TAU * 2.0) * 0.12, 0.0, 1.0, 0.3)
	tween.tween_property(self, "_gafas", 0.0, 0.1)
	tween.tween_callback(func() -> void: _cara = "normal")


## Turno de Maxi: se queda embobado mirandolo y aplaude su fiesta (no avanza).
func embobado() -> void:
	var tween := _nuevo_tween()
	_cara = "embobado"
	tween.tween_method(func(t: float) -> void: _giro = sin(t * TAU * 2.0) * 0.08, 0.0, 1.0, 1.2)
	tween.tween_callback(func() -> void: _cara = "normal")


## Con cada acierto del equipo: cara de "¡ay, no!" y se le resbalan las gafas-lupa.
func cara_ay_no() -> void:
	if _sentado or resbalando:
		return
	_cara = "ay_no"
	var tween := create_tween()
	tween.tween_property(self, "_gafas", 5.0, 0.12)
	tween.tween_interval(0.4)
	tween.tween_property(self, "_gafas", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		if _cara == "ay_no":
			_cara = "normal")


## Victoria del equipo: frena y aplaude tambien.
func aplaudir() -> void:
	var tween := _nuevo_tween()
	_sentado = false
	_cara = "risa"
	for k in 5:
		tween.tween_property(self, "_salto", 10.0, 0.12)
		tween.tween_property(self, "_salto", 0.0, 0.12)


## Derrota-gag 1: la mochila-torre aspira (se estira). Devuelve la duracion.
func aspirar() -> float:
	var tween := _nuevo_tween()
	_sentado = false
	_cara = "risa"
	tween.tween_property(self, "_mochila", 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	return 0.8


## Derrota-gag 2: la mochila se infla y estornuda.
func estornudar() -> float:
	var tween := _nuevo_tween()
	tween.tween_property(self, "_mochila", 1.9, 0.25)
	tween.tween_property(self, "_mochila", 0.9, 0.12)
	tween.tween_property(self, "_mochila", 1.0, 0.2)
	return 0.6


## Derrota-gag 3: cae sentado con las estrellitas en la cabeza (risa, nunca dolor).
func sentarse() -> void:
	var tween := _nuevo_tween()
	tween.tween_callback(func() -> void:
		_sentado = true
		_cara = "risa"
		_estrellitas = 2.0)
	tween.tween_property(self, "_escala", Vector2(1.2, 0.85), 0.1)
	tween.tween_property(self, "_escala", Vector2.ONE, 0.15)


## Tras "¡otra vez!": vuelve caminando a la galleta 0, silbando.
func volver_a_cero() -> void:
	var tween := _nuevo_tween()
	_sentado = false
	_mochila = 1.0
	_cara = "normal"
	tween.tween_property(self, "_x", x_galleta(0), 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_method(func(t: float) -> void: _salto = absf(sin(t * TAU * 3.0)) * 5.0, 0.0, 1.0, 0.8)


## Nuevo record del equipo: la banderita salta.
func saltar_banderita() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_salto_bandera", 22.0, 0.15)
	tween.tween_property(self, "_salto_bandera", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE)


func tocar_cometa() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_salto_cometa", 14.0, 0.12)
	tween.tween_property(self, "_salto_cometa", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE)


## Boca de la mochila-torre (coordenadas globales): hacia aqui vuela lo que se aspira.
func boca_global() -> Vector2:
	return get_global_transform() * Vector2(_x - 30.0, Y_PISO - 46.0 - 55.0 * _mochila)


func pies_global() -> Vector2:
	return get_global_transform() * Vector2(_x, Y_PISO)


func punto_cinta_global() -> Vector2:
	return get_global_transform() * Vector2(966.0 + 170.0 * clampf(fraccion_cinta, 0.0, 1.0), 40.0)
