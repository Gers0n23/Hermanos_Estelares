extends Control

## Pista que cuesta una estrellita (retos de Sofia), comun a los motores con puntaje
## (disenador-mecanicas HE-40 #4, auditoria UX R12; 28-Sep-2026, PROVISIONAL).
##
## - MEDIDOR: 3 estrellitas de 34 px bajo el boton de pista que muestran en vivo cuantas lleva la
##   partida (`estrellitas_fn`). Al gastar una, esa es la que cae.
## - CONFIRMACION con dos objetivos distintos (no es doble toque, GDD §6.4): el 1.er toque en el
##   boton no cobra; se abre un globo de 150x150 bajo el boton con la estrellita y la mano de Coco y
##   suena "¿Te ayudo? Me das una estrellita". Tocar el globo confirma; tocar fuera o esperar 4 s lo
##   cierra sin costo.
## - PISO: con 1 sola estrellita no hay globo ni estrellita que cae: la pista es directa y suena
##   "¡Esta va de regalo!".
##
## El motor la crea con `crear(padre, boton, estrellitas_fn)` y llama `pedir(accion)`
## al tocar su boton. `accion(gratis: bool) -> bool` hace la ayuda y devuelve si hizo algo; si no es
## gratis y se hizo, el motor suma su pista (como siempre) y aqui cae la estrellita del medidor.
## No conoce a ningun motor. Toda respuesta a un toque es inmediata (<100 ms: sonido + rebote).

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const LADO_ESTRELLA := 34.0
const LADO_GLOBO := 150.0
const SEGUNDOS_GLOBO := 4.0
const VOZ_CONFIRMAR := "res://assets/audio/voces/nucleo/pista_confirmar.wav"
const VOZ_GRATIS := "res://assets/audio/voces/nucleo/pista_gratis.wav"
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_ABRIR := "res://assets/audio/sfx/ui/seleccionar.ogg"
const SFX_CERRAR := "res://assets/audio/sfx/ui/cerrar.ogg"

var boton: Control
var estrellitas_fn: Callable
var _medidor: Control
var _capa: Control
var _globo: Control
var _accion: Callable
var _id_globo := 0
var _cayendo := -1
var _tiempo := 0.0


static func crear(padre: Control, boton_pista: Control, fn_estrellitas: Callable) -> Control:
	var pista: Control = load("res://scripts/ui/pista_con_costo.gd").new()
	pista.boton = boton_pista
	pista.estrellitas_fn = fn_estrellitas
	pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pista.z_index = 40
	padre.add_child(pista)
	pista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return pista


func _ready() -> void:
	_medidor = Control.new()
	_medidor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_medidor.size = Vector2(LADO_ESTRELLA * 3.0 + 12.0, LADO_ESTRELLA + 8.0)
	_medidor.draw.connect(_dibujar_medidor)
	add_child(_medidor)
	_capa = Control.new()
	_capa.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa.size = Vector2(1280, 720)
	_capa.gui_input.connect(_al_tocar_fuera)
	_capa.hide()
	add_child(_capa)
	_globo = Control.new()
	_globo.mouse_filter = Control.MOUSE_FILTER_STOP
	_globo.size = Vector2.ONE * LADO_GLOBO
	_globo.pivot_offset = _globo.size / 2.0
	_globo.draw.connect(_dibujar_globo)
	_globo.gui_input.connect(_al_tocar_globo)
	_capa.add_child(_globo)


func _process(delta: float) -> void:
	_tiempo += delta
	visible = boton != null and is_instance_valid(boton) and boton.visible
	if not visible:
		return
	var centro := boton.global_position + boton.size / 2.0
	_medidor.position = Vector2(centro.x - _medidor.size.x / 2.0, boton.global_position.y + boton.size.y + 6.0)
	_medidor.queue_redraw()
	if _capa.visible:
		_globo.position = Vector2(clampf(centro.x - LADO_GLOBO / 2.0, 8.0, 1280.0 - LADO_GLOBO - 8.0), _medidor.position.y + _medidor.size.y + 6.0)
		_globo.queue_redraw()


func globo_abierto() -> bool:
	return _capa.visible


## El nino toco el boton de pista. En el piso (1 estrellita) la pista es directa y gratis.
func pedir(accion: Callable) -> void:
	_sonar(SFX_TOQUE)
	_rebotar(boton)
	if _capa.visible:
		# Segundo toque al boton con el globo abierto: el globo late para mostrar donde confirmar.
		_rebotar(_globo)
		return
	if int(estrellitas_fn.call()) <= 1:
		if accion.call(true):
			_voz(VOZ_GRATIS)
		return
	_accion = accion
	_abrir_globo()


## Equivale a tocar el globo (lo usan los arneses QA).
func confirmar() -> void:
	if not _capa.visible:
		return
	var accion := _accion
	_cerrar_globo(false)
	_sonar(SFX_ABRIR)
	if accion.is_valid() and accion.call(false):
		estrellita_gastada()


## Anima la estrellita que se pierde (la del medidor que se apaga cae girando).
func estrellita_gastada() -> void:
	var antes := clampi(int(estrellitas_fn.call()) + 1, 1, 3)
	_cayendo = antes - 1
	var estrella := Figura.new()
	estrella.figura = "estrella"
	estrella.con_cara = false
	estrella.color = DORADO
	estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estrella.size = Vector2.ONE * LADO_ESTRELLA
	estrella.pivot_offset = estrella.size / 2.0
	add_child(estrella)
	estrella.global_position = _medidor.global_position + _centro_estrella(_cayendo) - estrella.size / 2.0
	var tween := estrella.create_tween().set_parallel(true)
	tween.tween_property(estrella, "position:y", estrella.position.y + 90.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(estrella, "rotation", 1.6, 0.9)
	tween.tween_property(estrella, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(func() -> void:
		estrella.queue_free()
		_cayendo = -1)


func _abrir_globo() -> void:
	_id_globo += 1
	var id := _id_globo
	_capa.show()
	_process(0.0)
	_globo.scale = Vector2(0.2, 0.2)
	_globo.create_tween().tween_property(_globo, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sonar(SFX_ABRIR)
	_voz(VOZ_CONFIRMAR)
	await get_tree().create_timer(SEGUNDOS_GLOBO).timeout
	if is_inside_tree() and id == _id_globo and _capa.visible:
		_cerrar_globo(true)


func _cerrar_globo(con_rebote: bool) -> void:
	_id_globo += 1
	_accion = Callable()
	if not con_rebote:
		_capa.hide()
		return
	_sonar(SFX_CERRAR)
	var tween := _globo.create_tween()
	tween.tween_property(_globo, "scale", Vector2(1.08, 0.92), 0.08)
	tween.tween_property(_globo, "scale", Vector2(0.2, 0.2), 0.12)
	tween.tween_callback(_capa.hide)


func _al_tocar_globo(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_globo.accept_event()
		confirmar()


func _al_tocar_fuera(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_capa.accept_event()
		# La capa tapa el boton de pista: si el toque cae sobre el, es un 2.º toque y el globo late
		# en vez de cerrarse (UX N5, 02-Oct-2026).
		if is_instance_valid(boton) and boton.get_global_rect().has_point(_capa.get_global_transform() * evento.position):
			pedir(_accion)
			return
		_sonar(SFX_TOQUE)
		_cerrar_globo(true)


func _centro_estrella(i: int) -> Vector2:
	return Vector2(6.0 + LADO_ESTRELLA * (i + 0.5), _medidor.size.y / 2.0)


func _dibujar_medidor() -> void:
	var llenas := clampi(int(estrellitas_fn.call()), 0, 3)
	for i in 3:
		var c := _centro_estrella(i)
		if i < llenas and i != _cayendo:
			Figura.dibujar(_medidor, "estrella", DORADO, c, LADO_ESTRELLA * 0.5, false)
		else:
			var hueco := Figura.poligono("estrella", c, LADO_ESTRELLA * 0.44)
			hueco.append(hueco[0])
			_medidor.draw_colored_polygon(Figura.poligono("estrella", c, LADO_ESTRELLA * 0.44), Color(1, 1, 1, 0.25))
			_medidor.draw_polyline(hueco, Color(1, 1, 1, 0.85), 2.5, true)


## Globo redondo con la estrellita que se ofrece y la manito de Coco que la pide.
func _dibujar_globo() -> void:
	var s := _globo.size
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#FFF8EE")
	caja.set_corner_radius_all(int(s.x / 2.0))
	caja.border_color = DORADO
	caja.set_border_width_all(6)
	caja.shadow_color = Color(0, 0, 0, 0.25)
	caja.shadow_size = 6
	_globo.draw_style_box(caja, Rect2(Vector2.ZERO, s))
	var pulso := 1.0 + 0.08 * sin(_tiempo * 6.0)
	Figura.dibujar(_globo, "estrella", DORADO, Vector2(s.x * 0.44, s.y * 0.42), 38.0 * pulso, true, true)
	# Manito abierta (palma + dedos) abajo a la derecha, pidiendo la estrellita.
	var palma := Vector2(s.x * 0.7, s.y * 0.74)
	var verde := Color("#7DD87A")
	for k in 4:
		var punta := palma + Vector2.from_angle(-PI * 0.95 + k * 0.32) * 26.0
		_globo.draw_line(palma, punta, COLOR_CONTORNO, 13.0, true)
		_globo.draw_line(palma, punta, verde, 8.0, true)
	_globo.draw_circle(palma, 16.0, COLOR_CONTORNO)
	_globo.draw_circle(palma, 13.0, verde)


func _rebotar(nodo: Control) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	nodo.pivot_offset = nodo.size / 2.0
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "scale", Vector2(1.1, 0.9), 0.06)
	tween.tween_property(nodo, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _voz(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta)


func _sonar(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)
