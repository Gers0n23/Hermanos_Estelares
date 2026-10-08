extends Control

## Vela de cumpleanos sobre un cupcake: el "tiempo par" que se consume sin castigo (ficha motor-emparejar
## §10.1 y UX M7). Reglas de M7: menos de 80 px de alto, fuera del area de juego, SIN tic-tac, no
## parpadea, no cambia de color y no acelera al final. Si se acaba, la llama hace un "puf" suave (humito)
## y nada mas. Si se termina antes, sigue encendida y el motor convierte lo que queda en puntos.
## Generica: el motor decide cuanto dura y cuando corre; aqui solo se dibuja `fraccion` (1 -> 0).
## UX HE-60 m3: con `cera_larga` (Sofia, para quien la vela es parte del reto) la cera recorre ~28 px en vez
## de 14, sobre un cupcake mas chico: se lee de un vistazo y el total sigue bajo los 80 px.
## UX HE-60 m4: tocarla la menea y emite `tocada` (el motor pone un "ding" suave); no cambia el juego. El
## area tocable es solo su rectangulo (no crece hacia el boton de salir, que esta 16 px arriba).

signal tocada

const Cupcake := preload("res://scripts/ui/dibujo_cupcake.gd")
const COLOR_CONTORNO := Color("#2B3350")
const CERA := Color("#9FE5E2")
const LLAMA := Color("#FFB238")
const LLAMA_CENTRO := Color("#FFF3B0")
const ALTO := 78.0
const ENFRIAMIENTO_TOQUE_MS := 1000

var fraccion := 1.0:
	set(valor):
		fraccion = clampf(valor, 0.0, 1.0)
		queue_redraw()
var encendida := true
var cera_larga := false:
	set(valor):
		cera_larga = valor
		queue_redraw()
var _humo := 0.0  ## 0-1: humito del "puf"
var _meneo := 0.0
var _ultimo_toque_ms := -ENFRIAMIENTO_TOQUE_MS


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(80, ALTO)
	size = Vector2(80, ALTO)


func _gui_input(evento: InputEvent) -> void:
	var toque: bool = (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT) 		or (evento is InputEventScreenTouch and evento.pressed)
	if not toque:
		return
	accept_event()
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_toque_ms < ENFRIAMIENTO_TOQUE_MS:
		return
	_ultimo_toque_ms = ahora
	create_tween().tween_method(_fijar_meneo, 0.0, 1.0, 0.2)
	tocada.emit()


func _fijar_meneo(valor: float) -> void:
	_meneo = sin(valor * PI * 3.0) * (1.0 - valor)
	queue_redraw()


## La llama se va a dormir: "puf" suave, sin sonido de error (el motor elige el sonido amable).
func dormir() -> void:
	if not encendida:
		return
	encendida = false
	var t := create_tween()
	t.tween_method(_fijar_humo, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _fijar_humo(valor: float) -> void:
	_humo = valor
	queue_redraw()


func _draw() -> void:
	var base := Vector2(size.x / 2.0, ALTO - (1.0 if cera_larga else 2.0))
	# Meneo al tocar: se balancea sobre su base (no sale de su rectangulo).
	draw_set_transform(base, _meneo * 0.18, Vector2.ONE)
	base = Vector2.ZERO
	var ancho := 28.0 if cera_larga else 40.0
	var llama_k := 0.75 if cera_larga else 1.0
	Cupcake.cupcake(self, base, ancho)
	# La vela se acorta con el tiempo (sin cambiar de color ni parpadear).
	var tope_cupcake := base.y - ancho * 0.5 - ancho * 0.36
	var alto_vela := (6.0 + 28.0 * fraccion) if cera_larga else (4.0 + 14.0 * fraccion)
	var vela := Rect2(base.x - 5.0, tope_cupcake - alto_vela, 10.0, alto_vela)
	draw_rect(vela, CERA)
	for i in int(alto_vela / 7.0):
		draw_line(Vector2(vela.position.x, vela.end.y - 4 - i * 7), Vector2(vela.end.x, vela.end.y - 7 - i * 7), Color.WHITE, 2.0, true)
	draw_rect(vela, COLOR_CONTORNO, false, 2.5)
	var mecha := Vector2(base.x, vela.position.y)
	draw_line(mecha, mecha + Vector2(0, -4), COLOR_CONTORNO, 2.0, true)
	var punta := mecha + Vector2(0, -5)
	if encendida:
		var llama := PackedVector2Array()
		for p in [Vector2(0, -18), Vector2(4, -11), Vector2(6, -5), Vector2(4, -1), Vector2(0, 0), Vector2(-4, -1), Vector2(-6, -5), Vector2(-4, -11)]:
			llama.append(punta + p * llama_k)
		draw_colored_polygon(llama, LLAMA)
		var cerrado := llama.duplicate()
		cerrado.append(llama[0])
		draw_polyline(cerrado, COLOR_CONTORNO, 2.0, true)
		draw_circle(punta + Vector2(0, -5) * llama_k, 3.0 * llama_k, LLAMA_CENTRO)
	elif _humo > 0.0 and _humo < 1.0:
		for i in 3:
			var p := punta + Vector2(sin(_humo * 6.0 + i) * 5.0, -8.0 - _humo * 26.0 - i * 7.0)
			draw_circle(p, 3.5 + i * 1.5, Color(0.85, 0.85, 0.92, 0.7 * (1.0 - _humo)))
