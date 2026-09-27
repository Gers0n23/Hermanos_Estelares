class_name CharcoClasificar
extends Control

## Charco de pintura del motor "clasificar" (docs/fichas/motor-clasificar.md §3): el OBJETIVO al que
## se llevan las gotas. Se dibuja por codigo ("peluche pintado") y avisa cuando lo tocan. Tres usos:
## - Charco de un color (libre/directo): acepta `color_id`. Decoracion opcional (flor, jirafa).
## - Charco de contorno (Nicole z5, `solo_contorno`): sin color hasta que recibe la gota pedida.
## - Charco de mezcla (Sofia): pide `resultado`, que sale de `receta` (2-3 componentes). Arriba
##   muestra un globito con el pedido (y la receta si `mostrar_receta`) y, opcional, el reloj amable.

signal tocado(charco: CharcoClasificar)

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const CREMA := Color("#F6EEE2")
const ALTO_GLOBO := 104.0

var id := ""
var color_id := ""
var color := Color.WHITE
var decoracion := ""
var solo_contorno := false
## Mezcla (Sofia)
var es_mezcla := false
var resultado := ""
var color_resultado := Color.WHITE
var receta: Array = []
var colores_receta: Dictionary = {}
var recibidos: Array = []
var mostrar_receta := false
var resuelto := false
## Reloj amable (Sofia z5): -1 = sin reloj; 0..1 = avance. Solo da estrellitas, nunca termina nada.
var reloj := -1.0
var reloj_a_tiempo := false
## Brillo que "llama" (Maxi z3, objetivo de Nicole z5, pista): continuo mientras sea true.
var llamando := false
## Pista de Sofia: muestra la receta un momento aunque este oculta.
var receta_visible_hasta := 0.0

var _tiempo := 0.0
var _brillo := 0.0
var _flash := 0.0
var _color_flash := Color.WHITE
var _ondas: Array = []
var _meneo := 0.0


func configurar(datos: Dictionary, tamano: Vector2) -> void:
	id = str(datos.get("id", ""))
	color_id = str(datos.get("color_id", ""))
	color = datos.get("color", Color.WHITE)
	decoracion = str(datos.get("decoracion", ""))
	solo_contorno = bool(datos.get("solo_contorno", false))
	es_mezcla = bool(datos.get("es_mezcla", false))
	resultado = str(datos.get("resultado", ""))
	color_resultado = datos.get("color_resultado", Color.WHITE)
	receta = datos.get("receta", [])
	colores_receta = datos.get("colores_receta", {})
	mostrar_receta = bool(datos.get("mostrar_receta", false))
	reloj = float(datos.get("reloj", -1.0))
	size = tamano
	pivot_offset = Vector2(size.x / 2.0, size.y)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tiempo = randf() * 10.0


## Centro de la pintura (no del globo) en coordenadas globales.
func centro_charco() -> Vector2:
	return global_position + _centro_local()


func radio_charco() -> Vector2:
	var alto_charco := size.y - (ALTO_GLOBO if es_mezcla else 0.0)
	return Vector2(size.x * 0.46, minf(alto_charco * 0.36, size.x * 0.24))


func _centro_local() -> Vector2:
	var radios := radio_charco()
	return Vector2(size.x / 2.0, size.y - radios.y - 14.0)


func faltantes() -> Array:
	var lista: Array = []
	for componente in receta:
		if not recibidos.has(componente):
			lista.append(componente)
	return lista


func _gui_input(evento: InputEvent) -> void:
	# Responde al presionar (no al soltar): feedback en menos de 100 ms (GDD §6 regla 5).
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		accept_event()
		tocado.emit(self)


func _process(delta: float) -> void:
	_tiempo += delta
	_brillo = maxf(0.0, _brillo - delta)
	_flash = maxf(0.0, _flash - delta * 1.4)
	_meneo = maxf(0.0, _meneo - delta * 3.0)
	for onda in _ondas:
		onda["t"] += delta
	_ondas = _ondas.filter(func(o: Dictionary) -> bool: return o["t"] < 0.9)
	queue_redraw()


# ---------------------------------------------------------------------------
# Reacciones
# ---------------------------------------------------------------------------

func brillar(segundos: float) -> void:
	_brillo = segundos


func salpicar(con_color: Color) -> void:
	_color_flash = con_color
	_flash = 1.0
	_ondas.append({"t": 0.0, "color": con_color})
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 0.86), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## "Todavia no": se menea un poquito, sin sonido feo (el motor pone la voz amable).
func menear() -> void:
	_meneo = 1.0


func pulso() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 0.94), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _draw() -> void:
	var centro := _centro_local() + Vector2(sin(_tiempo * 40.0) * 6.0 * _meneo, 0)
	var radios := radio_charco()
	var brillo := _brillo > 0.0 or llamando
	if brillo:
		var pulso_halo := 1.0 + sin(_tiempo * 6.0) * 0.06
		var halo := _elipse(centro, radios * 1.22 * pulso_halo, 40)
		draw_colored_polygon(halo, Color(DORADO, 0.42))
		_contorno(halo, Color(DORADO, 0.95), 5.0)
	draw_colored_polygon(_elipse(centro + Vector2(0, radios.y * 0.22), radios * 1.02, 36), Color(COLOR_CONTORNO, 0.2))

	var relleno := color
	var vacio := false
	if es_mezcla:
		relleno = color_resultado if resuelto else CREMA
		vacio = not resuelto
	elif solo_contorno:
		vacio = true
	if decoracion == "flor":
		_dibujar_petalos(centro, radios)
	if decoracion == "jirafa":
		_dibujar_orejas_jirafa(centro, radios)

	var forma := _blob(centro, radios)
	if solo_contorno:
		draw_colored_polygon(forma, Color(1, 1, 1, 0.22))
		_contorno_punteado(forma)
	else:
		var borde := _blob(centro, radios * 1.1)
		draw_colored_polygon(borde, relleno.darkened(0.28) if not vacio else Color("#D9CBB8"))
		_contorno(borde, COLOR_CONTORNO, 4.0)
		draw_colored_polygon(forma, relleno)
		if es_mezcla and not resuelto:
			_dibujar_mezcla_a_medias(centro, radios)
		var brillo_forma := _elipse(centro + Vector2(-radios.x * 0.38, -radios.y * 0.34), Vector2(radios.x * 0.2, radios.y * 0.16), 18)
		draw_colored_polygon(brillo_forma, Color(1, 1, 1, 0.5))
		draw_circle(centro + Vector2(radios.x * 0.4, -radios.y * 0.2), radios.y * 0.08, Color(1, 1, 1, 0.55))
		if decoracion == "jirafa":
			for mancha in [Vector2(-0.55, 0.1), Vector2(0.5, 0.35), Vector2(0.15, 0.55)]:
				draw_circle(centro + Vector2(mancha.x * radios.x, mancha.y * radios.y), radios.y * 0.14, Color("#B8762F", 0.55))
		if resuelto or (not es_mezcla):
			Figura.dibujar_cara(self, centro + Vector2(0, radios.y * 0.1), minf(radios.y * 1.2, radios.x * 0.6), resuelto or _flash > 0.2)
	if _flash > 0.0:
		draw_colored_polygon(forma, Color(_color_flash, _flash * 0.7))
	for onda in _ondas:
		var t: float = onda["t"] / 0.9
		var anillo := _elipse(centro, radios * (1.0 + t * 0.7), 36)
		_contorno(anillo, Color(onda["color"], 1.0 - t), 6.0 * (1.0 - t) + 1.0)
	if es_mezcla:
		_dibujar_globo(Vector2(size.x / 2.0, ALTO_GLOBO / 2.0 + 2.0))


func _dibujar_petalos(centro: Vector2, radios: Vector2) -> void:
	for i in 10:
		var angulo := TAU * i / 10.0
		var punto := centro + Vector2(cos(angulo) * radios.x * 1.12, sin(angulo) * radios.y * 1.2)
		var petalo := _elipse(punto, Vector2(radios.y * 0.36, radios.y * 0.3), 16)
		draw_colored_polygon(petalo, Color("#FFD0E6"))
		_contorno(petalo, COLOR_CONTORNO, 2.5)


func _dibujar_orejas_jirafa(centro: Vector2, radios: Vector2) -> void:
	for lado in [-1.0, 1.0]:
		var base := centro + Vector2(lado * radios.x * 0.45, -radios.y * 0.9)
		var punta := base + Vector2(lado * 8.0, -radios.y * 0.95)
		draw_line(base, punta, COLOR_CONTORNO, 13.0, true)
		draw_line(base, punta, Color("#F2C04A"), 8.0, true)
		draw_circle(punta, 10.0, Color("#B8762F"))
		draw_arc(punta, 10.0, 0.0, TAU, 16, COLOR_CONTORNO, 2.5, true)
		var oreja := _elipse(centro + Vector2(lado * radios.x * 0.82, -radios.y * 0.78), Vector2(18, 10), 14)
		draw_colored_polygon(oreja, Color("#F2C04A"))
		_contorno(oreja, COLOR_CONTORNO, 2.5)


## "Tine a medias": cada componente recibido es un remolino de su color dentro del charco crema.
func _dibujar_mezcla_a_medias(centro: Vector2, radios: Vector2) -> void:
	var n := recibidos.size()
	for i in n:
		var angulo := TAU * i / maxf(1.0, float(receta.size())) + _tiempo * 0.6
		var punto := centro + Vector2(cos(angulo) * radios.x * 0.34, sin(angulo) * radios.y * 0.3)
		var mancha := _blob(punto, radios * 0.52)
		draw_colored_polygon(mancha, colores_receta.get(recibidos[i], Color.WHITE))
		_contorno(mancha, Color(COLOR_CONTORNO, 0.35), 2.0)


## Globito del pedido: el color que Coco quiere y, si corresponde, su receta (gota + gota = gota).
func _dibujar_globo(centro: Vector2) -> void:
	var receta_a_la_vista := mostrar_receta or Time.get_ticks_msec() / 1000.0 < receta_visible_hasta
	var ancho := size.x * 0.96 if receta_a_la_vista else minf(size.x * 0.7, 150.0)
	var caja := Rect2(centro - Vector2(ancho, ALTO_GLOBO - 12.0) / 2.0, Vector2(ancho, ALTO_GLOBO - 12.0))
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFF8EE") if not resuelto else Color("#FFF3B0")
	estilo.border_color = DORADO if (receta_a_la_vista and not mostrar_receta) else COLOR_CONTORNO
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(30)
	estilo.anti_aliasing = true
	draw_style_box(estilo, caja)
	var cola := PackedVector2Array([centro + Vector2(-12, caja.size.y / 2.0 - 2), centro + Vector2(12, caja.size.y / 2.0 - 2), centro + Vector2(0, caja.size.y / 2.0 + 16)])
	draw_colored_polygon(cola, estilo.bg_color)
	draw_polyline(PackedVector2Array([cola[0], cola[2], cola[1]]), COLOR_CONTORNO, 4.0, true)
	var radio_objetivo := 30.0
	if receta_a_la_vista:
		var n := receta.size()
		var paso := (ancho - 40.0) / float(n + 1)
		var x0 := caja.position.x + 20.0 + paso * 0.5
		for i in n:
			var p := Vector2(x0 + i * paso, centro.y + 4)
			var componente: String = receta[i]
			var tiene := recibidos.has(componente) or resuelto
			var c: Color = colores_receta.get(componente, Color.WHITE)
			Figura.dibujar(self, "gota", c, p, 20.0, false)
			if tiene:
				draw_circle(p + Vector2(14, 14), 9.0, Color("#7DD87A"))
				draw_arc(p + Vector2(14, 14), 9.0, 0.0, TAU, 14, COLOR_CONTORNO, 2.0, true)
			_signo(p + Vector2(paso * 0.5, 0), "+" if i < n - 1 else "=")
		Figura.dibujar(self, "gota", color_resultado, Vector2(x0 + n * paso, centro.y + 2), 26.0, true, resuelto)
	else:
		Figura.dibujar(self, "gota", color_resultado, centro + Vector2(0, 2), radio_objetivo, true, resuelto)
		# Lo que ya echo Sofia: puntitos de color bajo el pedido (la receta sigue oculta).
		for i in recibidos.size():
			var p := centro + Vector2(-ancho * 0.36 + i * 18.0, caja.size.y * 0.3)
			draw_circle(p, 7.0, colores_receta.get(recibidos[i], Color.WHITE))
			draw_arc(p, 7.0, 0.0, TAU, 12, COLOR_CONTORNO, 2.0, true)
	if reloj >= 0.0 and not resuelto:
		_dibujar_reloj(Vector2(caja.end.x - 6.0, caja.position.y + 6.0))
	elif reloj_a_tiempo:
		var estrella := Figura.poligono("estrella", Vector2(caja.end.x - 6.0, caja.position.y + 6.0), 20.0)
		draw_colored_polygon(estrella, DORADO)
		Figura.contornear(self, estrella, 3.0)


## Solcito que se va poniendo: mientras brille, el pedido va "a tiempo". Al dormirse solo cambia de
## cara; no pasa nada mas (nunca apura ni termina el nivel).
func _dibujar_reloj(centro: Vector2) -> void:
	var radio := 20.0
	if reloj >= 1.0:
		draw_circle(centro, radio, Color("#C9C6E0"))
		draw_arc(centro, radio, 0.0, TAU, 24, COLOR_CONTORNO, 3.0, true)
		for lado in [-1.0, 1.0]:
			draw_line(centro + Vector2(lado * 7 - 4, -2), centro + Vector2(lado * 7 + 4, -2), COLOR_CONTORNO, 2.5, true)
		return
	draw_circle(centro, radio, Color("#FFF3B0"))
	var restante := 1.0 - reloj
	var puntos := PackedVector2Array([centro])
	for i in 25:
		puntos.append(centro + Vector2.from_angle(-PI / 2.0 + TAU * restante * i / 24.0) * radio)
	if restante > 0.02:
		draw_colored_polygon(puntos, DORADO)
	draw_arc(centro, radio, 0.0, TAU, 24, COLOR_CONTORNO, 3.0, true)
	Figura.dibujar_cara(self, centro + Vector2(0, 3), radio * 1.1, true)


func _signo(p: Vector2, signo: String) -> void:
	if signo == "+":
		draw_line(p - Vector2(7, 0), p + Vector2(7, 0), COLOR_CONTORNO, 4.0, true)
		draw_line(p - Vector2(0, 7), p + Vector2(0, 7), COLOR_CONTORNO, 4.0, true)
	else:
		for dy in [-4.0, 4.0]:
			draw_line(p + Vector2(-7, dy), p + Vector2(7, dy), COLOR_CONTORNO, 4.0, true)


func _blob(centro: Vector2, radios: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 40:
		var angulo := TAU * i / 40.0
		var ola := 1.0 + sin(angulo * 5.0 + _tiempo * 1.6) * 0.035
		puntos.append(centro + Vector2(cos(angulo) * radios.x, sin(angulo) * radios.y) * ola)
	return puntos


func _elipse(centro: Vector2, radios: Vector2, lados: int) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		var angulo := TAU * i / lados
		puntos.append(centro + Vector2(cos(angulo) * radios.x, sin(angulo) * radios.y))
	return puntos


func _contorno(forma: PackedVector2Array, tinta: Color, grosor: float) -> void:
	var cerrado := forma.duplicate()
	cerrado.append(forma[0])
	draw_polyline(cerrado, tinta, grosor, true)


func _contorno_punteado(forma: PackedVector2Array) -> void:
	for i in forma.size():
		if i % 2 == 0:
			draw_line(forma[i], forma[(i + 1) % forma.size()], Color.WHITE, 6.0, true)
	_contorno(forma, Color(COLOR_CONTORNO, 0.5), 2.0)
