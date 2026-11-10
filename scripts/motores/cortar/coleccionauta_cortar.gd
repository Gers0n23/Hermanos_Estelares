class_name ColeccionautaCortar
extends Node2D

## El Coleccionauta de la Gran Burbujeada, PROVISIONAL por codigo (HE-114 trae el arte; la ficha §5.9 pide reusar
## el de la Torre con la varita y la mochila de 3 pisos: ese rival hoy es un retrato provisional sin rig, asi que
## aqui se dibuja con vectores para tener las poses del jefe). Canon: redondo, torpe y sonriente; gafas-lupa,
## mochila-torre con 3 pisos de ventanitas (O1 abajo, O3 arriba) llenas de animales que saludan, varita de
## burbujas con manguera en espiral y los frascos de jabon en el cinturon. Solo dibujo: las reglas son del motor.
## Coordenadas globales de la escena (el nodo vive en el origen) para respetar el rect del §5.2.

const CONTORNO := Color("#2B3350")
const MORADO := Color("#8E5BD6")
const PIEL := Color("#B7E07A")
const BOCA := Vector2(1160, 300)
const RECT := Rect2(1150, 170, 130, 430)
## Rect de cada piso de la mochila (indice 0 = piso de la oleada 1, abajo).
const PISOS := [Rect2(1214, 400, 62, 98), Rect2(1214, 296, 62, 98), Rect2(1214, 192, 62, 98)]

var pisos_vacios := 0                 # oleadas ganadas: esos pisos se ven transparentes
var ventanas: Array = [[], [], []]    # ids de animales que saludan en cada piso
var frascos := 9
var infla := 0.0                      # cachetes inflados antes de soplar (0..1)
var sentado := 0.0                    # 0 de pie, 1 sentado en el pasto
var flota := 0.0                      # px hacia arriba (burbuja-gorro, gran estornudo)
var burbuja_gorro := 0.0              # alfa de la burbuja que lo envuelve
var empanado := 0.0                   # gafas empanadas (estornudo de jabon)
var calcetin_cara := false
var balanceo := 0.0
var temblor := 0.0                    # la mochila tiembla (gran estornudo)
var al_final_de_la_fila := false
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func contiene(punto: Vector2) -> bool:
	return RECT.has_point(punto)


func _draw() -> void:
	var dy := -flota + sentado * 40.0
	var tiembla := Vector2(sin(_t * 40.0) * 3.0 * temblor, 0)
	var pivote := Vector2(1200, 600)
	draw_set_transform(pivote + Vector2(0, dy), balanceo, Vector2.ONE)
	var o := -pivote
	_dibujar_mochila(o + tiembla)
	_dibujar_cuerpo(o)
	_dibujar_varita(o)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if burbuja_gorro > 0.01:
		DibujoCortar.dibujar_burbuja(self, Vector2(1205, 470 + dy), 120.0, false, burbuja_gorro)


func _dibujar_mochila(o: Vector2) -> void:
	var marco := Rect2(o + Vector2(1210, 186), Vector2(70, 318))
	draw_rect(marco, Color("#6B7FA8"))
	draw_rect(marco, CONTORNO, false, 4.0)
	for i in 3:
		var p: Rect2 = PISOS[i]
		var r := Rect2(o + p.position, p.size)
		var vacio := i < pisos_vacios
		draw_rect(r, Color(0.85, 0.95, 1.0, 0.25) if vacio else Color("#FFF4D6"))
		draw_rect(r, CONTORNO, false, 3.0)
		if vacio:
			continue
		var ids: Array = ventanas[i] if i < ventanas.size() else []
		for k in 2:
			var c := r.position + Vector2(17 + k * 28, 30 + (k % 2) * 36)
			draw_circle(c, 15, Color("#8EE9FF"))
			if k < ids.size():
				DibujoCortar.dibujar_animal(self, str(ids[k]), c + Vector2(0, sin(_t * 3.0 + k + i) * 2.0), 11.0)
			draw_arc(c, 15, 0, TAU, 16, CONTORNO, 2.5, true)
	# Sellito de lupa de la coleccion en la tapa.
	draw_circle(o + Vector2(1245, 182), 10, Color("#FFD23F"))
	draw_arc(o + Vector2(1245, 182), 10, 0, TAU, 14, CONTORNO, 3.0, true)


func _dibujar_cuerpo(o: Vector2) -> void:
	# Piernas cortitas y zapatos.
	for s in [-1.0, 1.0]:
		draw_line(o + Vector2(1195 + s * 18, 560), o + Vector2(1195 + s * 22, 592), CONTORNO, 10.0, true)
		draw_circle(o + Vector2(1195 + s * 26, 594), 9, Color("#F0453A"))
	# Cuerpo redondo con traje.
	draw_circle(o + Vector2(1195, 528), 50, CONTORNO)
	draw_circle(o + Vector2(1195, 528), 46, MORADO)
	# Cinturon con los frascos de jabon (§3.3): cada tanda gasta uno.
	draw_rect(Rect2(o + Vector2(1150, 538), Vector2(90, 14)), Color("#5A3E8A"))
	for k in mini(frascos, 13):
		var fila := k / 7
		var col := k % 7
		var p := o + Vector2(1156 + col * 12.5, 532 + fila * 18)
		draw_rect(Rect2(p, Vector2(9, 13)), Color("#9FE3FF"))
		draw_rect(Rect2(p + Vector2(2, -3), Vector2(5, 3)), Color("#FF9ED6"))
		draw_rect(Rect2(p, Vector2(9, 13)), CONTORNO, false, 1.5)
	# Cabeza.
	var cab := o + Vector2(1190, 458)
	draw_circle(cab, 36, CONTORNO)
	draw_circle(cab, 32, PIEL)
	# Antenitas.
	for s in [-1.0, 1.0]:
		draw_line(cab + Vector2(s * 12, -28), cab + Vector2(s * 20, -50), CONTORNO, 3.0, true)
		draw_circle(cab + Vector2(s * 20, -52), 5, Color("#FFD23F"))
	# Cachetes (se inflan antes de cada soplido).
	for s in [-1.0, 1.0]:
		draw_circle(cab + Vector2(s * 20, 12), 8 + infla * 9, Color(1.0, 0.55, 0.65, 0.7))
	# Gafas-lupa (un lente grande, con mango).
	var lente := cab + Vector2(-10, -4)
	draw_circle(lente, 15, Color(0.85, 0.95, 1.0, 0.5 + empanado * 0.45))
	draw_arc(lente, 15, 0, TAU, 20, CONTORNO, 4.0, true)
	draw_circle(cab + Vector2(16, -4), 9, Color(0.85, 0.95, 1.0, 0.5 + empanado * 0.45))
	draw_arc(cab + Vector2(16, -4), 9, 0, TAU, 14, CONTORNO, 3.0, true)
	if empanado < 0.5:
		draw_circle(lente, 4.5, CONTORNO)
		draw_circle(cab + Vector2(16, -4), 3.5, CONTORNO)
	# Boca: sonrisa, o "o" de soplar con los cachetes llenos.
	if infla > 0.4:
		draw_circle(cab + Vector2(-4, 18), 5, CONTORNO)
	else:
		draw_arc(cab + Vector2(0, 14), 10, PI * 0.15, PI * 0.85, 10, CONTORNO, 3.0, true)
	if calcetin_cara:
		DibujoCortar.dibujar_calcetin(self, cab + Vector2(0, -2), 40.0, 0.4)


func _dibujar_varita(o: Vector2) -> void:
	# Brazo que sostiene la varita hasta la boca del burbujeador.
	var boca := o + BOCA + Vector2(0, -flota + sentado * 40.0) * 0.0
	draw_line(o + Vector2(1160, 510), boca + Vector2(4, 30), MORADO, 12.0, true)
	draw_line(boca + Vector2(4, 30), boca + Vector2(0, 12), CONTORNO, 5.0, true)
	draw_arc(boca, 14, 0, TAU, 18, Color("#FF9ED6"), 5.0, true)
	# Manguera en espiral desde la tapa de la mochila.
	var pts := PackedVector2Array()
	var desde := o + Vector2(1245, 186)
	for i in 25:
		var u := float(i) / 24.0
		var p := desde.lerp(boca + Vector2(12, -6), u)
		p += Vector2(cos(u * 18.0), sin(u * 18.0)) * 6.0 * sin(u * PI)
		p.y -= sin(u * PI) * 40.0
		pts.append(p)
	draw_polyline(pts, Color("#4FD8E0"), 4.0, true)
