class_name CartaEmparejar
extends Control

## Una carta del motor "emparejar" (docs/fichas/motor-emparejar.md).
##
## Demo jugable del Planeta Arcoiris (13-Sep-2026, pedido del PO): la carta se dibuja con el
## estilo del juego — cara crema con la figura "peluche pintado" (`scripts/ui/figura_vectorial.gd`)
## y dorso violeta con arcoiris y estrella dorada — mientras no existan los sprites finales de
## HE-13. Si el nivel trae un `sprite` que existe, se usa ese en vez de la figura dibujada.
##
## Entrada (hallazgo B1, auditoria UX 18-Jul-2026): no extiende `Button`. Rastrea press/release
## por posicion global con tolerancia de arrastre corto, sin depender del ruteo de los Control.
##
## El estado LOGICO (`mostrando`, `esta_acertada`) cambia al instante; el giro de la carta es
## solo visual, asi que el motor y los arneses QA nunca dependen de las animaciones.

signal tocada(carta: CartaEmparejar)

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
## Formas geometricas asimetricas (paralelogramo, triangulo rectangulo...) para las sombras con trampa.
const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const TOLERANCIA_TOQUE_PX := 56.0  ## radio de tolerancia de arrastre corto (B1)
const COLOR_SOMBRA := Color(0.17, 0.2, 0.31, 0.92)
const PROPORCIONES_FORMA := {"triangulo_rect": Vector2(1.0, 1.0), "paralelogramo": Vector2(1.3, 0.72),
	"semicirculo": Vector2(1.2, 0.6), "trapecio": Vector2(1.25, 0.72)}
const SEGUNDOS_MEDIO_GIRO := 0.13
const COLOR_CONTORNO := Color("#2B3350")
const COLOR_CARA := Color("#FFF8EE")
const COLOR_DORSO := Color("#6A4CC7")
const COLOR_DORSO_LUZ := Color("#9D82F2")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const ROSA := Color("#F26CA8")

var id_elemento := ""
var id_pareja := ""
var figura := ""
var color_figura := DORADO
## Par "momento memorable" del nivel (ficha de nivel §7): brilla con halo arcoiris al verse.
var especial := false
var esta_acertada := false
var disabled := false
## Si el nino la ve (estado logico). La cara se dibuja recien a mitad del giro.
var mostrando := false
## Semilla: halo dorado que respira en las cartas pendientes (ficha de motor §5, ayudas Semilla).
var halo_idle := false
## Retos de Sofia (v3): "" normal | "sombra" (silueta oscura) | "receta" (colores que se mezclan).
var estilo := ""
var receta: Array = []
## Forma de geometria_formas.gd en vez de una figura con carita ("" = usar `figura`).
var forma := ""
var rotacion_figura := 0.0
var espejo := false

var _oculto := false
var _estado := "normal"  ## normal | seleccionada | acertada | no_es_este | ayuda
var _cara_visible := false
var _textura: Texture2D = null
var _tiempo := 0.0
var _id_ayuda := 0

var _rastreando := false
var _indice_toque := -2  ## -1 = mouse, >=0 = indice de InputEventScreenTouch
var _punto_inicio := Vector2.ZERO

var _cuerpo: Control
var _tween_giro: Tween
var _tween_cuerpo: Tween
var _tween_escala: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_asegurar_cuerpo()
	resized.connect(_acomodar)
	_acomodar()


func _asegurar_cuerpo() -> void:
	if _cuerpo != null:
		return
	_cuerpo = Control.new()
	_cuerpo.name = "cuerpo"
	_cuerpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cuerpo)
	_cuerpo.draw.connect(_dibujar)


func _acomodar() -> void:
	_cuerpo.size = size
	_cuerpo.pivot_offset = size / 2.0
	pivot_offset = size / 2.0
	_cuerpo.queue_redraw()


## Prepara la carta con un elemento del nivel: {id_pareja, id, figura, color, sprite, especial}.
func configurar(datos: Dictionary, oculto: bool) -> void:
	_asegurar_cuerpo()
	id_pareja = str(datos.get("id_pareja", ""))
	id_elemento = str(datos.get("id", ""))
	figura = str(datos.get("figura", ""))
	color_figura = Color.from_string(str(datos.get("color", "")), Color.from_hsv(float(hash(id_pareja) % 360) / 360.0, 0.5, 0.95))
	especial = bool(datos.get("especial", false))
	estilo = str(datos.get("estilo", ""))
	receta = datos.get("receta", [])
	forma = str(datos.get("forma", ""))
	rotacion_figura = float(datos.get("rotacion", 0.0))
	espejo = bool(datos.get("espejo", false))
	if estilo == "receta" and not receta.is_empty():
		color_figura = Color.from_string(str(receta[0]), color_figura)
	var ruta_sprite := str(datos.get("sprite", ""))
	if ruta_sprite != "" and not ruta_sprite.begins_with("res://"):
		ruta_sprite = "res://assets/" + ruta_sprite
	_textura = load(ruta_sprite) if ruta_sprite != "" and ResourceLoader.exists(ruta_sprite) else null
	if figura == "" and _textura == null and forma == "" and estilo != "receta":
		figura = "circulo"
	reiniciar(oculto)


func es_sombra() -> bool:
	return estilo == "sombra"


func _process(delta: float) -> void:
	_tiempo += delta
	if _estado in ["acertada", "ayuda"] or (halo_idle and not esta_acertada) or (especial and _cara_visible):
		_cuerpo.queue_redraw()


func _input(event: InputEvent) -> void:
	if disabled or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_procesar_evento(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_procesar_evento(-1, event.position, event.pressed)


## Rastrea press/release por posicion global, sin exigir que el release ocurra dentro del
## rect (a diferencia de BaseButton). Si el release cae dentro de TOLERANCIA_TOQUE_PX del
## punto de origen, se considera un toque valido (B1).
func _procesar_evento(indice: int, posicion_global: Vector2, presionado: bool) -> void:
	if presionado:
		if _rastreando or not get_global_rect().has_point(posicion_global):
			return
		_rastreando = true
		_indice_toque = indice
		_punto_inicio = posicion_global
	else:
		if not _rastreando or _indice_toque != indice:
			return
		_rastreando = false
		if posicion_global.distance_to(_punto_inicio) <= TOLERANCIA_TOQUE_PX:
			tocada.emit(self)


## Toque 1: seleccionar (voltea si estaba tapada). Feedback <100 ms (GDD §6.4).
func seleccionar() -> void:
	_estado = "seleccionada"
	_mostrar(true)
	_reventar_pulso()
	_cuerpo.queue_redraw()


## Deselecciona (voluntaria o tras "no es este"). Se vuelve a tapar si el modo es oculto.
func deseleccionar(oculto: bool) -> void:
	if esta_acertada:
		return
	_estado = "normal"
	_mostrar(not oculto)
	_cuerpo.queue_redraw()


## Par acertado: queda visible con cara feliz, halo turquesa y estrellita (§3/§7 ficha de motor).
func marcar_acertada() -> void:
	esta_acertada = true
	disabled = true
	_estado = "acertada"
	_mostrar(true)
	_cortar(_tween_escala)
	_tween_escala = create_tween()
	_tween_escala.tween_property(self, "scale", Vector2(1.16, 1.16), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_escala.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Micro-celebracion de par: la carta da un saltito hacia su pareja y vuelve.
func saltar_hacia(punto_global: Vector2) -> void:
	var direccion := (punto_global - (global_position + size / 2.0)).limit_length(size.x * 0.18)
	_cortar(_tween_cuerpo)
	_tween_cuerpo = create_tween()
	_tween_cuerpo.tween_property(_cuerpo, "position", direccion + Vector2(0, -size.y * 0.1), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_cuerpo.tween_property(_cuerpo, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## "No es este" (§3 fila 2b): halo rosado y meneo amistoso, nunca temblor de error.
func animar_no_es_este() -> void:
	_estado = "no_es_este"
	_cuerpo.queue_redraw()
	_cortar(_tween_cuerpo)
	_tween_cuerpo = create_tween()
	for angulo in [-7.0, 7.0, -4.0, 0.0]:
		_tween_cuerpo.tween_property(_cuerpo, "rotation", deg_to_rad(angulo), 0.08)


## Ayuda de Brote: se muestra un momento con halo dorado y se vuelve a tapar sola.
func revelar_momento(segundos: float) -> void:
	if esta_acertada or _estado == "seleccionada":
		return
	_id_ayuda += 1
	var id := _id_ayuda
	_estado = "ayuda"
	_mostrar(true)
	await get_tree().create_timer(segundos).timeout
	if id != _id_ayuda or esta_acertada or _estado != "ayuda":
		return
	_estado = "normal"
	_mostrar(not _oculto)


## Entrada escalonada al armar el tablero (solo visual).
func aparecer(retraso: float) -> void:
	modulate.a = 0.0
	_cuerpo.position = Vector2(0, -size.y * 0.3)
	_cortar(_tween_cuerpo)
	_tween_cuerpo = create_tween().set_parallel(true)
	_tween_cuerpo.tween_property(self, "modulate:a", 1.0, 0.2).set_delay(retraso)
	_tween_cuerpo.tween_property(_cuerpo, "position", Vector2.ZERO, 0.45).set_delay(retraso).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Derrota-gag: se tapa, da dos saltos con voltereta y cae en su nuevo lugar.
func bailar_gag(retraso: float) -> void:
	_estado = "normal"
	if _oculto:
		_mostrar(false)
	_cortar(_tween_cuerpo)
	_tween_cuerpo = create_tween()
	_tween_cuerpo.tween_interval(retraso)
	for i in 2:
		_tween_cuerpo.tween_property(_cuerpo, "position:y", -size.y * 0.25, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_cuerpo.parallel().tween_property(_cuerpo, "rotation", (i + 0.5) * PI, 0.18)
		_tween_cuerpo.tween_property(_cuerpo, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween_cuerpo.parallel().tween_property(_cuerpo, "rotation", (i + 1.0) * PI, 0.18)
	_tween_cuerpo.tween_callback(func() -> void: _cuerpo.rotation = 0.0)


## Reinicio tras derrota-gag o al configurar: solo se llama sobre cartas no acertadas (§6).
func reiniciar(oculto: bool) -> void:
	_oculto = oculto
	esta_acertada = false
	disabled = false
	_estado = "normal"
	_id_ayuda += 1
	_rastreando = false
	for tween in [_tween_cuerpo, _tween_escala]:
		_cortar(tween)
	rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 1.0
	_cuerpo.rotation = 0.0
	_cuerpo.position = Vector2.ZERO
	_mostrar(not oculto, false)


## B2 (auditoria UX 18-Jul-2026): feedback minimo a un toque que todavia no puede sumar.
func pulso_espera() -> void:
	_reventar_pulso()


func _reventar_pulso() -> void:
	_cortar(_tween_escala)
	scale = Vector2(0.92, 0.92)
	_tween_escala = create_tween()
	_tween_escala.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _mostrar(valor: bool, animado := true) -> void:
	mostrando = valor
	if not animado or not is_inside_tree():
		_cortar(_tween_giro)
		_cara_visible = valor
		_cuerpo.scale.x = 1.0
		_cuerpo.queue_redraw()
		return
	var girando := _tween_giro != null and _tween_giro.is_valid() and _tween_giro.is_running()
	if _cara_visible == valor and not girando:
		return
	_cortar(_tween_giro)
	_tween_giro = create_tween()
	_tween_giro.tween_property(_cuerpo, "scale:x", 0.0, SEGUNDOS_MEDIO_GIRO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween_giro.tween_callback(func() -> void:
		_cara_visible = mostrando
		_cuerpo.queue_redraw()
	)
	_tween_giro.tween_property(_cuerpo, "scale:x", 1.0, SEGUNDOS_MEDIO_GIRO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _cortar(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _dibujar() -> void:
	var s := _cuerpo.size
	if s.x <= 1.0:
		return
	var rect := Rect2(Vector2.ZERO, s)
	var borde := maxf(4.0, s.x * 0.035)
	var radio := s.x * 0.16
	var halo := _color_halo()
	if halo.a > 0.0:
		var anillo := _caja(Color(0, 0, 0, 0), halo, borde * 1.7, radio + borde * 2.0)
		anillo.draw_center = false
		_cuerpo.draw_style_box(anillo, rect.grow(borde * 2.0))
	var caja := _caja(COLOR_CARA if _cara_visible else COLOR_DORSO, COLOR_CONTORNO, borde, radio)
	caja.shadow_color = Color(COLOR_CONTORNO, 0.32)
	caja.shadow_size = int(borde)
	caja.shadow_offset = Vector2(0, borde * 1.3)
	_cuerpo.draw_style_box(caja, rect)
	var centro := s / 2.0
	if _cara_visible:
		_dibujar_cara(centro, s)
	else:
		_dibujar_dorso(centro, s)


func _dibujar_cara(centro: Vector2, s: Vector2) -> void:
	if not es_sombra():
		_cuerpo.draw_circle(centro, s.x * 0.37, Color(color_figura, 0.2))
	if estilo == "receta":
		_dibujar_receta(centro, s)
	elif _textura != null:
		_cuerpo.draw_texture_rect(_textura, Rect2(centro - s * 0.36, s * 0.72), false)
	elif forma != "":
		_dibujar_forma(centro, s)
	else:
		_dibujar_figura(centro, s)
	_dibujar_marcas(centro, s)


## Receta de color: gotas de cada color con un "+" entre ellas (verde = azul + amarillo).
func _dibujar_receta(centro: Vector2, s: Vector2) -> void:
	var n := receta.size()
	var radio := s.x * (0.15 if n <= 2 else 0.115)
	var paso := s.x * (0.42 if n <= 2 else 0.3)
	var inicio := centro.x - paso * (n - 1) / 2.0
	for i in n:
		var punto := Vector2(inicio + paso * i, centro.y)
		Figura.dibujar(_cuerpo, "gota", Color.from_string(str(receta[i]), Color.WHITE), punto, radio, false)
		if i < n - 1:
			var mas := Vector2(punto.x + paso / 2.0, centro.y + radio * 0.2)
			var brazo := radio * 0.36
			_cuerpo.draw_line(mas - Vector2(brazo, 0), mas + Vector2(brazo, 0), COLOR_CONTORNO, maxf(3.0, s.x * 0.025), true)
			_cuerpo.draw_line(mas - Vector2(0, brazo), mas + Vector2(0, brazo), COLOR_CONTORNO, maxf(3.0, s.x * 0.025), true)


## Forma geometrica girada o en espejo: a color o como sombra oscura.
func _dibujar_forma(centro: Vector2, s: Vector2) -> void:
	var proporcion: Vector2 = PROPORCIONES_FORMA.get(forma, Vector2.ONE)
	var medida := proporcion / maxf(proporcion.x, proporcion.y) * s.x * 0.6
	var base := Geo.contorno(forma, medida.x, medida.y)
	if espejo:
		base = Geo.espejado(base)
	var poligono := Geo.transformado(base, rotacion_figura, centro)
	if es_sombra():
		_cuerpo.draw_colored_polygon(poligono, COLOR_SOMBRA)
	else:
		Geo.pintar(_cuerpo, poligono, color_figura, s.x * 0.3)


## Figura con carita (o su sombra), con giro y espejo aplicados como transformacion de dibujo.
func _dibujar_figura(centro: Vector2, s: Vector2) -> void:
	var transformar := not is_zero_approx(rotacion_figura) or espejo
	var c := centro
	if transformar:
		_cuerpo.draw_set_transform(centro, deg_to_rad(rotacion_figura), Vector2(-1.0 if espejo else 1.0, 1.0))
		c = Vector2.ZERO
	var radio := s.x * 0.33
	if not es_sombra():
		Figura.dibujar(_cuerpo, figura, color_figura, c, radio, true, esta_acertada)
	elif figura == "arcoiris":
		var base := c + Vector2(0, radio * 0.4)
		_cuerpo.draw_arc(base, radio * 0.56, PI, TAU, 40, COLOR_SOMBRA, radio * 0.72, true)
	else:
		_cuerpo.draw_colored_polygon(Figura.poligono(figura, c, radio), COLOR_SOMBRA)
	if transformar:
		_cuerpo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dibujar_marcas(centro: Vector2, s: Vector2) -> void:
	if esta_acertada:
		var punto := Vector2(s.x * 0.83, s.y * 0.17)
		var estrellita := Figura.poligono("estrella", punto, s.x * 0.1)
		_cuerpo.draw_colored_polygon(estrellita, DORADO)
		Figura.contornear(_cuerpo, estrellita, maxf(2.0, s.x * 0.014))
	if especial:
		for i in 3:
			var angulo := _tiempo * 1.6 + i * TAU / 3.0
			var chispa := Figura.poligono("estrella", centro + Vector2.from_angle(angulo) * s.x * 0.4, s.x * 0.045)
			_cuerpo.draw_colored_polygon(chispa, Color.from_hsv(fmod(_tiempo * 0.4 + i / 3.0, 1.0), 0.55, 1.0))


func _dibujar_dorso(centro: Vector2, s: Vector2) -> void:
	_cuerpo.draw_circle(centro, s.x * 0.34, Color(COLOR_DORSO_LUZ, 0.55))
	var base := centro + Vector2(0, s.y * 0.16)
	for i in Figura.COLORES_ARCOIRIS.size():
		_cuerpo.draw_arc(base, s.x * (0.33 - i * 0.042), PI, TAU, 28, Figura.COLORES_ARCOIRIS[i], s.x * 0.045, true)
	Figura.dibujar(_cuerpo, "estrella", DORADO, centro + Vector2(0, s.y * 0.1), s.x * 0.2, false)
	for p in [Vector2(0.2, 0.22), Vector2(0.8, 0.3), Vector2(0.24, 0.8), Vector2(0.78, 0.8)]:
		_cuerpo.draw_circle(p * s, s.x * 0.018, Color(1, 1, 1, 0.75))


func _color_halo() -> Color:
	match _estado:
		"seleccionada":
			return DORADO
		"ayuda":
			return Color(DORADO, 0.55 + 0.45 * sin(_tiempo * 10.0))
		"no_es_este":
			return ROSA
		"acertada":
			return Color(TURQUESA, 0.55 + 0.25 * sin(_tiempo * 3.0))
	if especial and _cara_visible:
		return Color.from_hsv(fmod(_tiempo * 0.5, 1.0), 0.6, 1.0)
	if halo_idle and not esta_acertada:
		return Color(DORADO, 0.3 + 0.3 * sin(_tiempo * 3.0))
	return Color(0, 0, 0, 0)


func _caja(fondo: Color, borde_color: Color, ancho: float, radio: float) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde_color
	caja.set_border_width_all(int(ancho))
	caja.set_corner_radius_all(int(radio))
	caja.anti_aliasing = true
	return caja
