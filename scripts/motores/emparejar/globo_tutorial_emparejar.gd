extends Control

## Globito del tutorial de "Parejas de Coco" (pedido del PO 17-Oct-2026): la PRIMERA vez que un hermano
## juega, el juego se pausa, el tablero se oscurece y sale un globito de Coco con un pictograma sin texto
## (dos cartas tapadas -> un dedito -> dos cartas iguales con estrella) mientras Coco explica por voz.
## Cuando Coco calla aparece un boton grande de "jugar" que late; tocarlo (o tocar el globito) cierra el
## tutorial. Las veces siguientes no hay explicacion: se reparte y se juega (tocar a Coco la repite).

signal cerrado()

const COLOR_CONTORNO := Color("#2B3350")
const COLOR_GLOBO := Color("#FFF8EE")
const COLOR_DORSO := Color("#6A4CC7")
const COLOR_DORSO_LUZ := Color("#9D82F2")
const COLOR_CARA := Color("#FFFFFF")
const DORADO := Color("#FFCB3D")
const VERDE := Color("#5BC96B")
const ROSA := Color("#F26CA8")
## Globo sobre el tablero (1280x720) con la colita apuntando a Coco (abajo a la izquierda).
const RECT_GLOBO := Rect2(300, 150, 700, 330)
const PUNTA_COLA := Vector2(205, 452)
## Boton de jugar: grande (GDD §6, >= 96 px para Maxi), centrado bajo el pictograma.
const RADIO_BOTON := 62.0

var _tiempo := 0.0
var _listo := false  ## Coco ya termino de explicar: se puede cerrar
var _aparicion := 0.0
var _boton_centro := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# El velo no atrapa toques: el boton de salir y Coco siguen respondiendo (GDD §6); las cartas las
	# ignora el motor mientras dura el tutorial.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_centro = Vector2(RECT_GLOBO.get_center().x, RECT_GLOBO.end.y - 4.0)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_aparicion = v
		queue_redraw(), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## El motor lo llama cuando Coco termina la explicacion: aparece el boton de jugar.
func habilitar_cierre() -> void:
	_listo = true
	queue_redraw()


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	# Mientras Coco explica, los toques no cierran nada (la pausa es la regla).
	if not toque or not _listo:
		return
	var pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	if RECT_GLOBO.grow(20.0).has_point(pos) or pos.distance_to(_boton_centro) <= RADIO_BOTON + 20.0:
		get_viewport().set_input_as_handled()
		cerrar()


func cerrar() -> void:
	if not _listo:
		return
	_listo = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_aparicion = v
		queue_redraw(), 1.0, 0.0, 0.22)
	tween.tween_callback(func() -> void:
		cerrado.emit()
		queue_free())


func _draw() -> void:
	# Velo sobre el tablero: el juego esta en pausa.
	draw_rect(Rect2(Vector2.ZERO, size), Color(COLOR_CONTORNO, 0.45 * _aparicion))
	if _aparicion <= 0.01:
		return
	var centro := RECT_GLOBO.get_center()
	var meneo := sin(_tiempo * 2.2) * 3.0
	draw_set_transform(centro + Vector2(0, meneo), 0.0, Vector2.ONE * _aparicion)
	var r := Rect2(RECT_GLOBO.position - centro, RECT_GLOBO.size)
	# Colita hacia Coco.
	var cola := PackedVector2Array([
		Vector2(r.position.x + 4, r.end.y - 130), Vector2(r.position.x + 4, r.end.y - 62),
		PUNTA_COLA - centro])
	draw_colored_polygon(cola, COLOR_GLOBO)
	draw_polyline(PackedVector2Array([cola[0], cola[2], cola[1]]), COLOR_CONTORNO, 6.0, true)
	var caja := StyleBoxFlat.new()
	caja.bg_color = COLOR_GLOBO
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(6)
	caja.set_corner_radius_all(60)
	caja.anti_aliasing = true
	draw_style_box(caja, r)
	# Tapa la union de la colita con el borde.
	draw_colored_polygon(PackedVector2Array([cola[0] + Vector2(-2, 7), cola[1] + Vector2(-2, -7),
		(cola[0] + cola[1]) / 2.0 + Vector2(12, 0)]), COLOR_GLOBO)
	# Pictograma: dos tapadas -> dedito -> dos iguales con estrella.
	var y := -30.0
	_dibujar_carta(Vector2(-250, y), false, 0.0)
	_dibujar_carta(Vector2(-165, y), false, 0.0)
	_dibujar_flecha(Vector2(-95, y), Vector2(-35, y))
	_dibujar_dedito(Vector2(0, y + 8), sin(_tiempo * 5.0) * 6.0)
	_dibujar_flecha(Vector2(40, y), Vector2(100, y))
	var giro := clampf(sin(_tiempo * 1.6) * 1.4, -1.0, 1.0)
	_dibujar_carta(Vector2(165, y), true, giro)
	_dibujar_carta(Vector2(250, y), true, giro)
	_dibujar_estrella(Vector2(207, y - 78), 26.0 + sin(_tiempo * 4.0) * 3.0, DORADO)
	# Boton de jugar (solo cuando Coco ya explico).
	if _listo:
		var latido := 1.0 + sin(_tiempo * 5.0) * 0.07
		var b := _boton_centro - centro
		draw_circle(b + Vector2(0, 6), RADIO_BOTON * latido, Color(COLOR_CONTORNO, 0.35))
		draw_circle(b, RADIO_BOTON * latido, VERDE)
		draw_arc(b, RADIO_BOTON * latido, 0, TAU, 48, COLOR_CONTORNO, 6.0, true)
		var t := RADIO_BOTON * 0.42 * latido
		draw_colored_polygon(PackedVector2Array([b + Vector2(-t * 0.7, -t), b + Vector2(t * 1.1, 0),
			b + Vector2(-t * 0.7, t)]), Color.WHITE)
	draw_set_transform(Vector2.ZERO)


## `giro` 0 = de frente; las cartas destapadas "respiran" un poquito para que se note que se dieron vuelta.
func _dibujar_carta(c: Vector2, cara: bool, giro: float) -> void:
	var ancho := 70.0 * (0.85 + 0.15 * absf(giro) if cara else 1.0)
	var rect := Rect2(c - Vector2(ancho, 96.0) / 2.0, Vector2(ancho, 96.0))
	var caja := StyleBoxFlat.new()
	caja.bg_color = COLOR_CARA if cara else COLOR_DORSO
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(5)
	caja.set_corner_radius_all(14)
	caja.anti_aliasing = true
	draw_style_box(caja, rect)
	if cara:
		# Corazon rosado igual en las dos: "iguales".
		var s := ancho / 70.0
		draw_circle(c + Vector2(-11, -6) * s, 13.0 * s, ROSA)
		draw_circle(c + Vector2(11, -6) * s, 13.0 * s, ROSA)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-23, -1) * s, c + Vector2(23, -1) * s,
			c + Vector2(0, 26) * s]), ROSA)
	else:
		_dibujar_estrella(c, 16.0, COLOR_DORSO_LUZ)


func _dibujar_flecha(desde: Vector2, hasta: Vector2) -> void:
	draw_line(desde, hasta, COLOR_CONTORNO, 7.0, true)
	var dir := (hasta - desde).normalized()
	var lado := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([hasta + dir * 10.0, hasta - dir * 12.0 + lado * 13.0,
		hasta - dir * 12.0 - lado * 13.0]), COLOR_CONTORNO)


## Dedito que toca (sube y baja).
func _dibujar_dedito(c: Vector2, bote: float) -> void:
	var p := c + Vector2(0, bote)
	var piel := Color("#FFD2B0")
	draw_circle(p + Vector2(0, 26), 24.0, piel)
	draw_arc(p + Vector2(0, 26), 24.0, 0, TAU, 32, COLOR_CONTORNO, 4.0, true)
	var dedo := Rect2(p + Vector2(-9, -26), Vector2(18, 46))
	var caja := StyleBoxFlat.new()
	caja.bg_color = piel
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(9)
	caja.anti_aliasing = true
	draw_style_box(caja, dedo)
	# Ondita del toque.
	var onda := fmod(_tiempo * 1.5, 1.0)
	draw_arc(p + Vector2(0, -30), 10.0 + onda * 18.0, PI * 1.1, PI * 1.9, 16, Color(DORADO, 1.0 - onda), 4.0, true)


func _dibujar_estrella(c: Vector2, radio: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rr := radio if i % 2 == 0 else radio * 0.45
		puntos.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(puntos, color)
	puntos.append(puntos[0])
	draw_polyline(puntos, COLOR_CONTORNO, 3.0, true)
