extends Control

## Un sticker puesto en el lienzo con tema (docs/fichas/motor-lienzo-libre.md §8). Es un nodo vivo:
## se arrastra, salta al tocarlo, cambia de color con el balde y (Nicole y Sofia) se agranda, se
## gira, se espeja o se borra. Se dibuja como vector (nitido a cualquier tamano); para el PNG,
## `lienzo.gd` lo rasteriza con `Stickers.imagen` usando los mismos datos.
##
## Tambien sirve de VIAJERO: el auto, el tren o el pony que recorre un camino dibujado.

const Stickers := preload("res://scripts/motores/lienzo_libre/stickers.gd")
const COLOR_CONTORNO := Color("#2B3350")

var id := "estrella"
var color := Color.WHITE:
	set(valor):
		color = valor
		queue_redraw()
## Lado base en px del lienzo (el dibujo ocupa el 90 %). El tamano real es `lado * escala`.
var lado := 96.0
var escala := 1.0:
	set(valor):
		escala = valor
		scale = Vector2(valor, valor)
var espejo := false:
	set(valor):
		espejo = valor
		queue_redraw()
var seleccionado := false:
	set(valor):
		seleccionado = valor
		queue_redraw()
## Desfase vertical del dibujo (saltitos y andar), sin mover el nodo.
var rebote := 0.0:
	set(valor):
		rebote = valor
		queue_redraw()

var _tween: Tween


func preparar(nuevo_id: String, nuevo_color: Color, nuevo_lado: float) -> void:
	id = nuevo_id
	color = nuevo_color
	lado = nuevo_lado
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(lado, lado)
	pivot_offset = size / 2.0
	set_meta("tipo", id)


func centro() -> Vector2:
	return position + size / 2.0


func poner_en(punto: Vector2) -> void:
	position = punto - size / 2.0


## Radio tocable en px del lienzo (un poco mas generoso que el dibujo: dedos de 2-8 anos).
func radio_toque() -> float:
	return maxf(36.0, lado * 0.5 * escala)


func _draw() -> void:
	var c := size / 2.0 + Vector2(0, -rebote)
	if seleccionado:
		var r := lado * 0.52
		for i in 16:
			var a := TAU * i / 16.0
			draw_arc(size / 2.0, r, a, a + TAU / 32.0, 4, Color("#FFCB3D"), 5.0 / maxf(0.3, escala), true)
	if espejo:
		draw_set_transform(c, 0.0, Vector2(-1, 1))
		Stickers.dibujar(self, id, color, Vector2.ZERO, lado * 0.45)
		draw_set_transform(Vector2.ZERO)
	else:
		Stickers.dibujar(self, id, color, c, lado * 0.45)


## Saltito con estiramiento (respuesta inmediata al toque, GDD §6.5).
func saltar() -> void:
	_reiniciar_tween()
	_tween.tween_property(self, "rebote", lado * 0.28, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rebote", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Los que caminan o ruedan dan unos pasitos hacia donde miran y vuelven.
func andar() -> void:
	_reiniciar_tween()
	var paso := lado * 0.3 * escala * (-1.0 if espejo else 1.0)
	var inicio := position
	for i in 2:
		_tween.tween_property(self, "rebote", lado * 0.12, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(self, "position", inicio + Vector2(paso * (i + 1), 0), 0.24)
		_tween.tween_property(self, "rebote", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_interval(0.15)
	_tween.tween_property(self, "position", inicio, 0.35).set_trans(Tween.TRANS_SINE)


## Aparece con un "pop".
func aparecer() -> void:
	_reiniciar_tween()
	scale = Vector2(escala, escala) * 0.3
	_tween.tween_property(self, "scale", Vector2(escala, escala), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reiniciar_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Si se corto el "pop" de aparecer, el sticker vuelve a su tamano real.
	scale = Vector2(escala, escala)
	rebote = 0.0
	_tween = create_tween()
