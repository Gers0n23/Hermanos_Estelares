extends Control

## Nuditos de la cresta de Coco y ojos de estrella: la racha que se ve sin leer (ficha motor-emparejar
## §10.1, lenguaje del Rio de pintura, roadmap §3.3). Se cuelga a pantalla completa del `TextureRect` de
## Coco (`coco_base.png`, 293x459, stretch "keep aspect centered") y dibuja encima:
## - una tiara de `tope` nuditos sobre la cresta: cada eslabon de la racha enciende uno (pop + color del
##   arcoiris); al cortarse se apagan de a uno, sin sonido de error (el "fiuu" lo pone el motor);
## - con racha >= 3, ojos de estrella sobre los ojos de Coco.
## Generico: no sabe de cartas ni de puntos, solo de "cuantos eslabones hay".
## UX HE-60 m7: con `mostrar_apagados = false` (Maxi) los huecos grises no se dibujan: solo aparecen los
## nuditos encendidos, asi no hay "lo que falta".

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TAMANO_SPRITE := Vector2(293, 459)
## Arco de la tiara y ojos, en pixeles del sprite.
const CENTRO_ARCO := Vector2(158, 64)
const RADIO_ARCO := 66.0
const OJOS := [Vector2(116, 160), Vector2(197, 160)]
const RADIO_NUDITO := 10.0
const SEGUNDOS_APAGAR := 0.09

var tope := 5
var mostrar_apagados := true
var encendidos := 0
var _pop: Array[float] = []
var _ojos := 0.0  ## 0-1: aparicion de los ojos de estrella
var _t := 0.0
var _apagando := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pop.resize(tope)
	_pop.fill(0.0)


func _process(delta: float) -> void:
	_t += delta
	for i in _pop.size():
		_pop[i] = maxf(0.0, _pop[i] - delta * 3.5)
	var objetivo := 1.0 if encendidos >= 3 else 0.0
	_ojos = move_toward(_ojos, objetivo, delta * 5.0)
	queue_redraw()


## Enciende la racha hasta `n` eslabones (tope incluido); el nudito nuevo hace pop.
func fijar(n: int) -> void:
	_apagando += 1
	var nuevo := clampi(n, 0, tope)
	if nuevo > encendidos:
		for i in range(encendidos, nuevo):
			_pop[i] = 1.0
	elif nuevo == encendidos and nuevo > 0:
		_pop[nuevo - 1] = 1.0
	encendidos = nuevo


## Se corta la racha: los nuditos se apagan de a uno, del ultimo al primero.
func apagar_de_a_uno() -> void:
	_apagando += 1
	var id := _apagando
	while encendidos > 0:
		encendidos -= 1
		await get_tree().create_timer(SEGUNDOS_APAGAR).timeout
		if id != _apagando or not is_inside_tree():
			return


func _draw() -> void:
	var escala := minf(size.x / TAMANO_SPRITE.x, size.y / TAMANO_SPRITE.y)
	var desfase := (size - TAMANO_SPRITE * escala) / 2.0
	for i in tope:
		var a := deg_to_rad(205.0 + 130.0 * i / maxf(1.0, tope - 1))
		var p := desfase + (CENTRO_ARCO + Vector2.from_angle(a) * RADIO_ARCO) * escala
		var r := RADIO_NUDITO * (1.0 + 0.6 * _pop[i])
		if i < encendidos:
			var color: Color = Figura.COLORES_ARCOIRIS[i % Figura.COLORES_ARCOIRIS.size()]
			draw_circle(p, r * 1.6, Color(color, 0.28))
			draw_circle(p, r + 2.5, COLOR_CONTORNO)
			draw_circle(p, r, color)
			draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.28, Color(1, 1, 1, 0.8))
		elif mostrar_apagados:
			draw_circle(p, r + 2.0, Color(COLOR_CONTORNO, 0.45))
			draw_circle(p, r, Color(1, 1, 1, 0.35))
	if _ojos > 0.01:
		for ojo: Vector2 in OJOS:
			var c := desfase + ojo * escala
			var estrella := Figura.poligono("estrella", c, 15.0 * _ojos * (1.0 + 0.08 * sin(_t * 6.0)))
			draw_colored_polygon(estrella, DORADO)
			Figura.contornear(self, estrella, 2.5)
