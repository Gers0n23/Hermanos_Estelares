extends Node2D

## Mini demo PIXEL ART (prueba de estilo pedida por el PO, fuera del tablero).
## La nave-estrella vuela por el espacio junto a Cometa; el niño toca o arrastra para
## subir/bajar la nave y recoge destellos (tocándolos o pasando cerca). Sin texto:
## el contador son estrellitas arriba a la izquierda.
##
## Todo el arte (scripts/nucleo/arte_pixel.gd) se construye en código a resolución de 320x180 y se escala x4 con
## filtro "nearest" (píxeles nítidos): Cometa dibujado a mano píxel a píxel; la nave,
## el planeta y los destellos con formas a resolución de píxel + contorno automático.
##
## Ver en movimiento:
##   bash herramientas/ojos.sh escena=res://poc/pixel_demo/demo_pixel.tscn tiempos=0.5,2,3.5 \
##        toques=900,200@1.0;900,560@2.5

const ESCALA := 4
const ANCHO := 320
const ALTO := 180
const RADIO_RECOGER := 16.0  # generoso: a Maxi le basta con pasar cerca

const Arte := preload("res://scripts/nucleo/arte_pixel.gd")  # nave, Cometa, destello, planeta

var _tex_cometa: Texture2D
var _tex_nave: Texture2D
var _tex_destello: Texture2D
var _tex_planeta: Texture2D

var _t := 0.0
var _nave := Vector2(70, 90)
var _objetivo_y := 90.0
var _estrellas_fondo: Array = []   # [pos, capa]
var _destellos: Array = []         # {pos, fase}
var _chispas: Array = []           # {pos, vel, vida, color}
var _aros: Array = []              # {pos, radio}: aro que se expande al recoger
var _salto_cometa := 0.0           # Cometa da un saltito de alegría
var _recogidos := 0
var _proximo_destello := 0.6
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	scale = Vector2(ESCALA, ESCALA)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex_cometa = Arte.desde_grilla(Arte.COMETA)
	_tex_destello = Arte.desde_grilla(Arte.DESTELLO)
	_tex_nave = Arte.construir_nave()
	_tex_planeta = Arte.construir_planeta()
	for i in 90:
		_estrellas_fondo.append([Vector2(_rng.randf() * ANCHO, _rng.randf() * ALTO), i % 3])


func _process(delta: float) -> void:
	_t += delta
	_nave.y = lerpf(_nave.y, _objetivo_y, 1.0 - exp(-4.0 * delta))
	_nave.y = clampf(_nave.y, 20, ALTO - 20)

	for e in _estrellas_fondo:
		e[0].x -= [6.0, 14.0, 30.0][e[1]] * delta
		if e[0].x < -2:
			e[0] = Vector2(ANCHO + 2, _rng.randf() * ALTO)

	_proximo_destello -= delta
	if _proximo_destello <= 0:
		_proximo_destello = _rng.randf_range(0.9, 1.6)
		_destellos.append({"pos": Vector2(ANCHO + 8, _rng.randf_range(30, ALTO - 30)), "fase": _rng.randf() * TAU})
	var centro_nave := _nave + Vector2(4, 0)
	for d in _destellos.duplicate():
		d["pos"].x -= 34.0 * delta
		d["pos"].y += sin(_t * 2.0 + d["fase"]) * 8.0 * delta
		if d["pos"].distance_to(centro_nave) < RADIO_RECOGER + 10:
			_recoger(d)
		elif d["pos"].x < -10:
			_destellos.erase(d)

	for a in _aros.duplicate():
		a["radio"] += 70.0 * delta
		if a["radio"] > 34:
			_aros.erase(a)
	_salto_cometa = maxf(0.0, _salto_cometa - delta * 2.0)
	for c in _chispas.duplicate():
		c["pos"] += c["vel"] * delta
		c["vel"] *= 0.94
		c["vida"] -= delta
		if c["vida"] <= 0:
			_chispas.erase(c)
	queue_redraw()


func _recoger(destello: Dictionary) -> void:
	_destellos.erase(destello)
	_recogidos += 1
	_aros.append({"pos": destello["pos"], "radio": 4.0})
	_salto_cometa = 1.0
	for i in 24:
		var ang := TAU * i / 24.0
		_chispas.append({
			"pos": destello["pos"], "vel": Vector2.from_angle(ang) * _rng.randf_range(45, 95),
			"vida": _rng.randf_range(0.6, 1.1),
			"color": [Color("#ffd23f"), Color.WHITE, Color("#ff9ed6"), Color("#4fd8e0")][i % 4],
		})


func _unhandled_input(evento: InputEvent) -> void:
	var pos := Vector2.INF
	if evento is InputEventMouseButton and evento.pressed:
		pos = evento.position
	elif evento is InputEventMouseMotion and evento.button_mask & MOUSE_BUTTON_MASK_LEFT:
		pos = evento.position
	elif evento is InputEventScreenTouch and evento.pressed or evento is InputEventScreenDrag:
		pos = evento.position
	if pos == Vector2.INF:
		return
	var p := pos / ESCALA
	# tocar un destello lo recoge directo; tocar el cielo lleva la nave a esa altura
	for d in _destellos:
		if d["pos"].distance_to(p) < RADIO_RECOGER:
			_recoger(d)
			return
	_objetivo_y = p.y


func _dibujar_anillo(adelante: bool) -> void:
	var centro := Vector2(267, 49)
	for i in 160:
		var ang := TAU * i / 160.0
		var p := centro + Vector2(cos(ang) * 46, sin(ang) * 8)
		if (sin(ang) > 0) != adelante:
			continue
		draw_rect(Rect2(p.floor(), Vector2(2, 1)), Color("#ffe66b"))
		draw_rect(Rect2((p + Vector2(0, 1)).floor(), Vector2(2, 1)), Color("#ff9ed6"))


func _draw() -> void:
	draw_rect(Rect2(0, 0, ANCHO, ALTO), Color("#120a2c"))
	for i in 6:  # bandas de nebulosa pixeladas
		draw_rect(Rect2(0, 20 + i * 26, ANCHO, 13), Color(0.35, 0.18, 0.55, 0.06 + 0.02 * (i % 2)))
	for e in _estrellas_fondo:
		var brillo: float = 0.35 + 0.3 * e[1] + 0.2 * sin(_t * 3.0 + e[0].y)
		draw_rect(Rect2(e[0].floor(), Vector2.ONE * (1 + int(e[1] == 2))), Color(1, 1, 1, brillo))
	_dibujar_anillo(false)  # mitad de atrás del anillo, detrás del planeta
	draw_texture(_tex_planeta, Vector2(236, 18))
	_dibujar_anillo(true)   # mitad de adelante, encima

	for d in _destellos:
		var pulso := 1.0 + 0.15 * sin(_t * 8.0 + d["fase"])
		draw_texture(_tex_destello, (d["pos"] - Vector2(6, 6) * pulso).floor())

	# llamas de los propulsores (parpadeo pixelado)
	var base_nave := (_nave - Vector2(25, 16)).floor()
	for i in 3:
		var centro: Vector2 = base_nave + Arte.PROPULSORES[i]
		var largo := 5 + int(3 * abs(sin(_t * 18.0 + i * 1.7)))
		draw_rect(Rect2(centro + Vector2(-3 - largo, -1), Vector2(largo, 3)), Color("#ffab3d"))
		draw_rect(Rect2(centro + Vector2(-3 - largo / 2, 0), Vector2(largo / 2, 1)), Color("#fff27a"))
	var inclinacion := clampf((_objetivo_y - _nave.y) * 0.01, -0.25, 0.25)
	draw_set_transform(_nave.floor(), inclinacion)
	draw_texture(_tex_nave, Vector2(-25, -16))
	draw_set_transform(Vector2.ZERO)

	var pos_cometa := (_nave + Vector2(34, -22 + 3 * sin(_t * 2.5) - 10 * sin(_salto_cometa * PI))).floor()
	draw_texture(_tex_cometa, pos_cometa)

	for c in _chispas:
		draw_rect(Rect2(c["pos"].floor(), Vector2.ONE * 3), c["color"])
	for a in _aros:
		draw_arc(a["pos"], a["radio"], 0, TAU, 24, Color(1, 0.9, 0.4, 1.0 - a["radio"] / 34.0), 2.0)

	for i in mini(_recogidos, 12):  # contador sin texto: una estrellita por destello
		draw_texture(_tex_destello, Vector2(4 + i * 15, 4))
