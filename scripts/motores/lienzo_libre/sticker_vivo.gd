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
## Lienzo v2: "vivo" (anda por los caminos), "lugar" (destino de caminos y viajeros) o "decorado".
var clase := "decorado"
## Lugar fijo del fondo (el rio, el lago): invisible, no se mueve ni se borra; solo es destino.
var fijo := false
var radio_fijo := 0.0
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
## Fisica del lienzo (ficha §10): SQUASH & STRETCH del dibujo con pivote en la BASE (al caer se
## estira, al aterrizar se aplasta), sin tocar `scale` (que es el tamano elegido por el nino).
var deformar := Vector2.ONE:
	set(valor):
		deformar = valor
		queue_redraw()
## Desfase horizontal del dibujo: el temblorcito del tiznado y la sacudida al limpiarse.
var temblor := 0.0:
	set(valor):
		temblor = valor
		queue_redraw()
## Jinete (ficha §11.9): va SENTADO sobre un montable (de la cintura para arriba) y mas chico.
var sentado := false:
	set(valor):
		sentado = valor
		queue_redraw()
var achique := 1.0:
	set(valor):
		achique = valor
		queue_redraw()
## Cara especial encima del dibujo: "" (la normal) o "ups" (el sol que se quemo las manos).
var expresion := "":
	set(valor):
		expresion = valor
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


## Radio tocable en px del lienzo (un poco mas generoso que el dibujo: dedos de 2-8 anos). Con zoom,
## el minimo de 36 px es de PANTALLA: en el mundo se divide por el zoom.
func radio_toque(zoom := 1.0) -> float:
	if fijo:
		return radio_fijo
	return maxf(36.0 / maxf(zoom, 0.01), lado * 0.5 * escala)


func _draw() -> void:
	if fijo:
		return
	var c := size / 2.0 + Vector2(temblor, -rebote)
	if seleccionado:
		var r := lado * 0.52
		for i in 16:
			var a := TAU * i / 16.0
			draw_arc(size / 2.0, r, a, a + TAU / 32.0, 4, Color("#FFCB3D"), 5.0 / maxf(0.3, escala), true)
	# Escala alrededor de la base (x' = b + S * (c + M * x - b)), con M el espejo.
	var base := Vector2(size.x / 2.0 + temblor, size.y / 2.0 + lado * 0.43)
	var espejo_v := Vector2(-1, 1) if espejo else Vector2.ONE
	var escala_dibujo := deformar * achique
	draw_set_transform(base + escala_dibujo * (c - base), 0.0, escala_dibujo * espejo_v)
	if sentado and Stickers.es_personaje(id):
		Stickers.dibujar_sentado(self, id, Vector2.ZERO, lado * 0.45)
	else:
		Stickers.dibujar(self, id, color, Vector2.ZERO, lado * 0.45)
	if expresion == "ups":
		_cara_ups(lado * 0.45)
	draw_set_transform(Vector2.ZERO)


## "¡Ups!": tapa la carita normal (el disco del sol) y dibuja ojos redondos, boca en "o" y una gotita.
func _cara_ups(r: float) -> void:
	draw_circle(Vector2(0, 0.02 * r), r * 0.5, color)
	for lado_ojo in [-1.0, 1.0]:
		var ojo := Vector2(lado_ojo * r * 0.22, -r * 0.1)
		draw_circle(ojo, r * 0.11, Color.WHITE)
		draw_arc(ojo, r * 0.11, 0.0, TAU, 16, COLOR_CONTORNO, maxf(1.5, r * 0.035), true)
		draw_circle(ojo + Vector2(0, r * 0.02), r * 0.05, COLOR_CONTORNO)
	draw_circle(Vector2(0, r * 0.2), r * 0.09, COLOR_CONTORNO)
	draw_circle(Vector2(0, r * 0.22), r * 0.05, Color("#FF7E8A"))
	var gota := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		var k := 1.0 + 0.6 * maxf(0.0, -sin(a))
		gota.append(Vector2(r * 0.42, -r * 0.3) + Vector2(cos(a) * 0.06, sin(a) * 0.08 * k) * r)
	draw_colored_polygon(gota, Color("#8ED3FF"))


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


## Corta el saltito o los pasitos en curso (deshacer: el sticker vuelve exacto a su lugar).
func detener() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = Vector2(escala, escala)
	rebote = 0.0


func _reiniciar_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Si se corto el "pop" de aparecer, el sticker vuelve a su tamano real.
	scale = Vector2(escala, escala)
	rebote = 0.0
	_tween = create_tween()
