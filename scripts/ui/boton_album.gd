extends Control

## Boton grande del album de recuerdos (ficha §7): un libro-album con estrellas, dibujado en
## codigo. Late con un brillo dorado cuando hay fotos nuevas sin ver (`Recuerdos.hay_nuevos()`).
## La pantalla que lo usa decide que pasa al tocarlo (señal `tocado`); aqui solo se da la
## respuesta inmediata (rebote, GDD §6 regla 5). `dibujar_libro` lo reutiliza la entrega del
## sobre-estrella para el icono al que vuela la foto.

signal tocado

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TAPA := Color("#8A5CD6")

var nuevos := false
## Si es false, solo se dibuja (icono de destino de la entrega): no captura toques.
var interactivo := true
var _tiempo := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactivo else Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0
	tooltip_text = "Álbum de recuerdos" if interactivo else ""
	var recuerdos := get_node_or_null("/root/Recuerdos")
	var progreso := get_node_or_null("/root/Progreso")
	if recuerdos != null and interactivo:
		nuevos = recuerdos.hay_nuevos()
	if progreso != null and interactivo:
		progreso.recuerdos_actualizados.connect(_al_cambiar_recuerdos)


func _al_cambiar_recuerdos() -> void:
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos != null:
		nuevos = recuerdos.hay_nuevos()


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if not interactivo:
		return
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		rebotar()
		tocado.emit()


func rebotar() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 0.86), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var centro := size / 2.0
	var tam := minf(size.x, size.y)
	if nuevos:
		# Halo dorado claro que late (antes oscuro y marron, y se cortaba abajo).
		var pulso := 0.5 + 0.5 * sin(_tiempo * 4.0)
		for k in 3:
			draw_circle(centro, tam * (0.40 + k * 0.05 + pulso * 0.03), Color("#FFF3B0", 0.42 - k * 0.12))
	dibujar_libro(self, centro, tam * 0.8, _tiempo)
	if nuevos:
		# Destello DENTRO de la tapa, arriba a la izquierda: nada pegado fuera del libro.
		var p := centro + Vector2(-tam * 0.27, -tam * 0.19)
		Figura.dibujar(self, "estrella", DORADO, p, tam * (0.09 + 0.012 * sin(_tiempo * 6.0)), false)


## Libro-album cerrado (icono): tapa morada con lomo y anillas metalicas, etiqueta crema con una
## foto y un corazon, y hojas asomando por la derecha. Todo queda dentro de su caja: los destellos
## van dentro de la tapa, no sueltos alrededor. `tam` ~ ancho del libro.
static func dibujar_libro(lienzo: CanvasItem, centro: Vector2, tam: float, tiempo := 0.0) -> void:
	var ancho := tam
	var alto := tam * 0.78
	var r := Rect2(centro - Vector2(ancho, alto) / 2.0, Vector2(ancho, alto))
	var sombra := StyleBoxFlat.new()
	sombra.bg_color = Color(COLOR_CONTORNO, 0.3)
	sombra.set_corner_radius_all(int(tam * 0.1))
	lienzo.draw_style_box(sombra, Rect2(r.position + Vector2(0, tam * 0.05), r.size))
	# hojas asomando por la derecha (bloque de paginas)
	var hojas := StyleBoxFlat.new()
	hojas.bg_color = Color("#FFF8EE")
	hojas.set_corner_radius_all(int(tam * 0.08))
	hojas.border_color = COLOR_CONTORNO
	hojas.set_border_width_all(int(maxf(3.0, tam * 0.03)))
	lienzo.draw_style_box(hojas, Rect2(r.position + Vector2(tam * 0.05, tam * 0.02), r.size))
	# tapa
	var tapa := StyleBoxFlat.new()
	tapa.bg_color = TAPA
	tapa.set_corner_radius_all(int(tam * 0.08))
	tapa.border_color = COLOR_CONTORNO
	tapa.set_border_width_all(int(maxf(3.0, tam * 0.035)))
	lienzo.draw_style_box(tapa, r)
	# lomo con anillas metalicas
	lienzo.draw_rect(Rect2(r.position + Vector2(tam * 0.035, tam * 0.06), Vector2(tam * 0.09, alto - tam * 0.12)), TAPA.darkened(0.3))
	for k in 3:
		var p := r.position + Vector2(tam * 0.04, alto * (0.28 + 0.22 * k))
		lienzo.draw_circle(p, tam * 0.05, COLOR_CONTORNO)
		lienzo.draw_circle(p, tam * 0.035, Color("#D9DEE8"))
	# etiqueta crema con foto y corazon
	var etiqueta := Rect2(r.position + Vector2(tam * 0.2, alto * 0.14), Vector2(tam * 0.6, alto * 0.72))
	var cartel := StyleBoxFlat.new()
	cartel.bg_color = Color("#FFF8EE")
	cartel.set_corner_radius_all(int(tam * 0.06))
	cartel.border_color = COLOR_CONTORNO
	cartel.set_border_width_all(int(maxf(2.0, tam * 0.025)))
	lienzo.draw_style_box(cartel, etiqueta)
	var foto := Rect2(etiqueta.position + Vector2.ONE * tam * 0.06, etiqueta.size - Vector2.ONE * tam * 0.12)
	lienzo.draw_rect(foto, Color("#6FD6E8"))
	Figura.dibujar(lienzo, "corazon", Color("#F26CA8"), foto.get_center(), tam * 0.14, false)
	# destello dentro de la tapa, arriba a la derecha
	Figura.dibujar(lienzo, "estrella", DORADO, r.position + Vector2(ancho * 0.88, alto * 0.16), tam * (0.07 + 0.012 * sin(tiempo * 3.0)), false)
