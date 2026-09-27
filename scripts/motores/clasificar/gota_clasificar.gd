class_name GotaClasificar
extends Control

## Gota de pintura del motor "clasificar" (docs/fichas/motor-clasificar.md §3).
##
## No conoce charcos ni reglas: se dibuja, cae si el motor se lo pide, avisa cuando la toman, la
## mueven, la sueltan o solo la tocan, y sabe animarse. El motor decide que pasa. Entrada unificada
## tactil + mouse: en tablet Godot convierte el dedo en mouse (emulate_mouse_from_touch).
##
## Un "toque" es presionar y soltar casi sin moverse. Todo lo demas es arrastrar (GDD §6 regla 4).

signal tomada(gota: GotaClasificar)
signal movida(gota: GotaClasificar, punto: Vector2)
signal soltada(gota: GotaClasificar, punto: Vector2)
signal tocada(gota: GotaClasificar)

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const UMBRAL_TOQUE_PX := 18.0
## Radio tocable minimo (96 px de diametro, GDD §6.1), aunque la gota se vea mas chica.
const RADIO_TOQUE_MINIMO := 48.0
const MARGEN_TOQUE := 16.0
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const MANCHA_JIRAFA := Color("#B8762F")

var color_id := "rojo"
var color := Color("#FF5A5A")
## normal | gris (sin color, Sofia z3) | jirafa (bonus de Nicole) | gigante (se divide, Maxi z4)
var tipo := "normal"
var velocidad := 0.0
var cayendo := false
var bloqueada := false
## La gota esta volando hacia un charco o rebotando: no acepta toques.
var en_vuelo := false
var alegre := false:
	set(valor):
		alegre = valor
		queue_redraw()
var elegida := false:
	set(valor):
		elegida = valor
		queue_redraw()
## Posicion de reposo (centro global) a la que vuelve si se suelta lejos de todo charco.
var casa := Vector2.ZERO

var _presionada := false
var _se_movio := false
var _inicio := Vector2.ZERO
var _tiempo := 0.0
var _brillo := 0.0
var _tween: Tween


func configurar(id_color: String, relleno: Color, lado: float, tipo_gota := "normal") -> void:
	color_id = id_color
	color = relleno
	tipo = tipo_gota
	size = Vector2.ONE * lado
	custom_minimum_size = size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tiempo = randf() * 10.0
	queue_redraw()


func centro_global() -> Vector2:
	return global_position + size / 2.0


func fijar_centro(punto: Vector2) -> void:
	global_position = punto - size / 2.0


func esta_libre() -> bool:
	return not bloqueada and not en_vuelo and is_instance_valid(self)


func esta_presionada() -> bool:
	return _presionada


func _has_point(punto: Vector2) -> bool:
	var radio := maxf(size.x * 0.5 + MARGEN_TOQUE, RADIO_TOQUE_MINIMO)
	return (punto - size / 2.0).length() <= radio


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			if bloqueada or en_vuelo:
				return
			_presionada = true
			_se_movio = false
			_inicio = evento.global_position
			accept_event()
			tomada.emit(self)
		elif _presionada:
			_presionada = false
			accept_event()
			if _se_movio:
				soltada.emit(self, evento.global_position)
			else:
				tocada.emit(self)
	elif evento is InputEventMouseMotion and _presionada:
		accept_event()
		if not _se_movio and evento.global_position.distance_to(_inicio) > UMBRAL_TOQUE_PX:
			_se_movio = true
		if _se_movio:
			movida.emit(self, evento.global_position)


## El motor cancela un arrastre en curso (derrota-gag, fin de tanda).
func cancelar_arrastre() -> void:
	_presionada = false
	_se_movio = false


func _process(delta: float) -> void:
	_tiempo += delta
	_brillo = maxf(0.0, _brillo - delta)
	if cayendo and not _presionada and not bloqueada and not en_vuelo and not elegida:
		position.y += velocidad * delta
	queue_redraw()


# ---------------------------------------------------------------------------
# Animaciones (un solo tween a la vez: una animacion nueva corta la anterior)
# ---------------------------------------------------------------------------

func nuevo_tween() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


func aparecer(retraso := 0.0) -> void:
	scale = Vector2.ZERO
	var tween := nuevo_tween()
	tween.tween_interval(retraso)
	tween.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Respuesta inmediata al toque (<100 ms, GDD §6 regla 5).
func pulso() -> void:
	var tween := nuevo_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 0.86), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE * 1.06, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func agrandar(escala: float) -> void:
	var tween := nuevo_tween()
	tween.tween_property(self, "scale", Vector2.ONE * escala, 0.1)


## Vuelve a su lugar de reposo con un saltito (soltada lejos o "todavia no").
func volver_a_casa(sacudir := false) -> void:
	en_vuelo = true
	var tween := nuevo_tween()
	if sacudir:
		for dx in [-12.0, 12.0, -7.0, 0.0]:
			tween.tween_property(self, "position:x", position.x + dx, 0.06)
	tween.tween_property(self, "global_position", casa - size / 2.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(func() -> void: en_vuelo = false)


## Salta dentro de un charco y desaparece. `al_llegar` se llama al tocar la pintura.
func saltar_a(destino: Vector2, al_llegar: Callable, altura := 120.0) -> void:
	en_vuelo = true
	cancelar_arrastre()
	var desde := centro_global()
	var tween := nuevo_tween()
	tween.tween_method(func(t: float) -> void:
		var punto := desde.lerp(destino, t) + Vector2(0, -altura * 4.0 * t * (1.0 - t))
		fijar_centro(punto)
	, 0.0, 1.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.35, 0.35), 0.08)
	tween.tween_callback(al_llegar)
	tween.tween_callback(queue_free)


func saltito(altura := 30.0) -> void:
	var y := position.y
	var tween := nuevo_tween()
	tween.tween_property(self, "position:y", y - altura, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", y, 0.26).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func brillar(segundos: float) -> void:
	_brillo = segundos


## Se va flotando hacia arriba (fin de tanda) o se aplasta en el suelo (gota que paso de largo).
func irse(flotando := true) -> void:
	en_vuelo = true
	bloqueada = true
	cancelar_arrastre()
	var tween := nuevo_tween()
	if flotando:
		tween.tween_property(self, "position:y", position.y - 160.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	else:
		tween.tween_property(self, "scale", Vector2(1.5, 0.3), 0.12)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


# ---------------------------------------------------------------------------
# Dibujo "peluche pintado"
# ---------------------------------------------------------------------------

func _draw() -> void:
	var bamboleo := 0.0 if _presionada else sin(_tiempo * 3.0) * 3.0
	var centro := size / 2.0 + Vector2(0, bamboleo + size.y * 0.02)
	var radio := size.x * 0.47
	if elegida or _brillo > 0.0:
		var intensidad := 0.45 if elegida else clampf(_brillo, 0.0, 1.0) * 0.55
		var pulso_halo := 1.0 + sin(_tiempo * 7.0) * 0.05
		draw_circle(centro, radio * 1.08 * pulso_halo, Color(DORADO, intensidad))
		draw_arc(centro, radio * 1.08 * pulso_halo, 0.0, TAU, 40, Color(DORADO, minf(1.0, intensidad * 2.0)), 5.0, true)
	match tipo:
		"gris":
			_dibujar_gris(centro, radio)
		"jirafa":
			_dibujar_jirafa(centro, radio)
		_:
			Figura.dibujar(self, "gota", color, centro, radio, true, alegre)
			if tipo == "gigante":
				for i in 3:
					var angulo := _tiempo * 1.5 + TAU * i / 3.0
					var chispa := Figura.poligono("estrella", centro + Vector2.from_angle(angulo) * radio * 0.95, radio * 0.13)
					draw_colored_polygon(chispa, Color.WHITE)
					Figura.contornear(self, chispa, 2.0)


## Gota gris "sin color" (distractora de Sofia): carita dormida, sin brillo alegre.
func _dibujar_gris(centro: Vector2, radio: float) -> void:
	Figura.dibujar(self, "gota", color, centro, radio, false)
	var cara := centro + Vector2(0, radio * 0.34)
	var escala := radio * 0.7
	var grosor := maxf(2.0, escala * 0.06)
	for lado in [-1.0, 1.0]:
		var ojo := cara + Vector2(lado * escala * 0.3, -escala * 0.02)
		draw_line(ojo - Vector2(escala * 0.1, 0), ojo + Vector2(escala * 0.1, 0), COLOR_CONTORNO, grosor, true)
	draw_line(cara + Vector2(-escala * 0.08, escala * 0.18), cara + Vector2(escala * 0.08, escala * 0.18), COLOR_CONTORNO, grosor, true)
	# Zzz chiquito: esta gota no tiene color ni ganas de pintar.
	var z := centro + Vector2(radio * 0.55, -radio * 0.75)
	for k in 2:
		var p := z + Vector2(k * radio * 0.22, -k * radio * 0.24)
		var lado_z := radio * (0.14 - k * 0.03)
		draw_polyline(PackedVector2Array([p, p + Vector2(lado_z, 0), p + Vector2(0, lado_z), p + Vector2(lado_z, lado_z)]), COLOR_CONTORNO, 2.5, true)


## Gota-jirafa (momento memorable de Nicole): cuernitos, orejitas y manchas.
func _dibujar_jirafa(centro: Vector2, radio: float) -> void:
	for lado in [-1.0, 1.0]:
		var base := centro + Vector2(lado * radio * 0.2, -radio * 0.72)
		var punta := base + Vector2(lado * radio * 0.12, -radio * 0.42)
		draw_line(base, punta, COLOR_CONTORNO, radio * 0.13, true)
		draw_line(base, punta, color.darkened(0.1), radio * 0.08, true)
		draw_circle(punta, radio * 0.1, MANCHA_JIRAFA)
		draw_arc(punta, radio * 0.1, 0.0, TAU, 16, COLOR_CONTORNO, 2.5, true)
		var oreja := Figura.poligono("gota", centro + Vector2(lado * radio * 0.52, -radio * 0.4), radio * 0.2)
		var girada := PackedVector2Array()
		var pivote := centro + Vector2(lado * radio * 0.52, -radio * 0.4)
		for p in oreja:
			girada.append(pivote + (p - pivote).rotated(lado * 1.1))
		draw_colored_polygon(girada, color)
		Figura.contornear(self, girada, 2.5)
	Figura.dibujar(self, "gota", color, centro, radio, false)
	for mancha in [Vector2(-0.3, 0.05), Vector2(0.32, 0.18), Vector2(-0.08, 0.66), Vector2(0.36, 0.62), Vector2(-0.4, 0.5)]:
		draw_circle(centro + mancha * radio, radio * 0.1, Color(MANCHA_JIRAFA, 0.85))
	Figura.dibujar_cara(self, centro + Vector2(0, radio * 0.3), radio * 0.62, true)
