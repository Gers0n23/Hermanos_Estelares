extends RefCounted

## Dibujos vectoriales de la «Carrera de Toby» (motor runner), hechos por código: corredores (Toby, pony,
## pony estelar, jirafa, gatito y los dinos de Maxi), obstáculos blanditos, aéreos tiernos (sin bichos),
## coleccionables, metas y el fondo con parallax de cada zona de Animalia (con atardecer y noche).
##
## Arte PROVISIONAL de dev-godot (HE-119) hasta los corredores de disenador-personajes (HE-114). Estilo de la
## casa: contorno tinta #2B3350, colores planos con un brillo, ojos grandes con brillo y mejillas rosadas.
## Todo es estático: el motor pasa el lienzo (CanvasItem), la posición y la pose; aquí no hay estado.

const TINTA := Color("#2B3350")
const BLANCO := Color("#FFFFFF")
const RUBOR := Color(1.0, 0.45, 0.6, 0.45)
const CONTORNO := 3.5


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

static func elipse_pts(c: Vector2, r: Vector2, rot := 0.0, lados := 28) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in lados:
		var a := TAU * k / lados
		p.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	return p


static func elipse(l: CanvasItem, c: Vector2, r: Vector2, color: Color, rot := 0.0, borde := true) -> void:
	var p := elipse_pts(c, r, rot)
	if borde:
		var g := elipse_pts(c, r + Vector2(CONTORNO, CONTORNO) * 0.5, rot)
		l.draw_colored_polygon(g, TINTA)
	l.draw_colored_polygon(p, color)


static func circulo(l: CanvasItem, c: Vector2, r: float, color: Color, borde := true) -> void:
	if borde:
		l.draw_circle(c, r + CONTORNO * 0.5, TINTA)
	l.draw_circle(c, r, color)


static func poligono(l: CanvasItem, pts: PackedVector2Array, color: Color, borde := true) -> void:
	l.draw_colored_polygon(pts, color)
	if borde:
		var cerrado := pts.duplicate()
		cerrado.append(pts[0])
		l.draw_polyline(cerrado, TINTA, CONTORNO, true)


static func palo(l: CanvasItem, a: Vector2, b: Vector2, ancho: float, color: Color) -> void:
	l.draw_line(a, b, TINTA, ancho + CONTORNO, true)
	l.draw_circle(a, (ancho + CONTORNO) * 0.5, TINTA)
	l.draw_circle(b, (ancho + CONTORNO) * 0.5, TINTA)
	l.draw_line(a, b, color, ancho, true)
	l.draw_circle(a, ancho * 0.5, color)
	l.draw_circle(b, ancho * 0.5, color)


static func ojo(l: CanvasItem, c: Vector2, r: float, parpadeo: bool, mira := Vector2.ZERO) -> void:
	if parpadeo:
		l.draw_arc(c + Vector2(0, r * 0.2), r * 0.8, PI * 1.1, PI * 1.9, 8, TINTA, maxf(2.0, r * 0.35), true)
		return
	l.draw_circle(c, r + 1.5, TINTA)
	l.draw_circle(c, r, BLANCO)
	l.draw_circle(c + mira * r * 0.3 + Vector2(r * 0.15, 0), r * 0.68, TINTA)
	l.draw_circle(c + mira * r * 0.3 + Vector2(r * 0.35, -r * 0.3), r * 0.26, BLANCO)


static func sonrisa(l: CanvasItem, c: Vector2, r: float, abierta := false) -> void:
	if abierta:
		var p := PackedVector2Array()
		for k in 9:
			var a := lerpf(0.1, PI - 0.1, k / 8.0)
			p.append(c + Vector2(cos(a) * r, sin(a) * r))
		l.draw_colored_polygon(p, Color("#7A2E3E"))
		l.draw_circle(c + Vector2(0, r * 0.62), r * 0.38, Color("#FF8FA3"))
		var cerrado := p.duplicate()
		cerrado.append(p[0])
		l.draw_polyline(cerrado, TINTA, 2.5, true)
		return
	l.draw_arc(c, r, 0.2, PI - 0.2, 10, TINTA, 2.8, true)


static func estrella_pts(c: Vector2, r: float, rot := -PI / 2.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 10:
		var rr := r if k % 2 == 0 else r * 0.45
		p.append(c + Vector2.from_angle(rot + TAU * k / 10.0) * rr)
	return p


static func corazon_pts(c: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 32:
		var a := TAU * k / 32.0
		var x := 16.0 * pow(sin(a), 3)
		var yy := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		p.append(c + Vector2(x, yy) * r / 16.0)
	return p


# ---------------------------------------------------------------------------
# Corredores
# ---------------------------------------------------------------------------

## Todos miran a la derecha con los pies en `pies`. `pose`: fase (ciclo de carrera, rad), aire (bool),
## escala (Vector2, aplastar/estirar desde los pies), rot (rad, para rodar), parpadeo, boca ("feliz" |
## "abierta" | "oh"), cuello (0-1, la jirafa lo agacha), barro (0-1), t (s).
static func corredor(l: CanvasItem, id: String, pies: Vector2, alto: float, pose: Dictionary) -> void:
	var escala: Vector2 = pose.get("escala", Vector2.ONE)
	var rot: float = pose.get("rot", 0.0)
	var base := 150.0
	match id:
		"trex", "spino", "carno", "trex_bombero", "tres_dinos":
			base = 170.0
		"jirafa":
			base = 200.0
	var k := alto / base
	if rot != 0.0:
		# Rodar como pelota: gira alrededor del centro del cuerpo.
		var centro := pies + Vector2(0, -alto * 0.45)
		l.draw_set_transform(centro, rot, escala * k)
		l.draw_set_transform_matrix(Transform2D(rot, escala * k, 0.0, centro) * Transform2D(0.0, Vector2(0, base * 0.45)))
	else:
		l.draw_set_transform(pies, 0.0, escala * k)
	match id:
		"trex", "spino", "carno", "trex_bombero":
			_dino(l, id, pose)
		"tres_dinos":
			_dino(l, "trex", pose)
		"toby":
			_cuadrupedo(l, "toby", pose)
		"pony", "pony_estelar", "gatito", "jirafa":
			_cuadrupedo(l, id, pose)
		_:
			_cuadrupedo(l, "toby", pose)
	l.draw_set_transform_matrix(Transform2D.IDENTITY)


const CUADRUPEDOS := {
	"toby": {"cuerpo": "#F3E3C8", "mancha": "#C9813F", "oreja": "#B9692E", "panza": "#FFF6E6", "nariz": "#3A2A2A",
		"alto_patas": 34.0, "cuerpo_r": Vector2(46, 30), "cabeza_r": 31.0, "cuello": 0.0},
	"pony": {"cuerpo": "#FFB8D6", "mancha": "#FFB8D6", "oreja": "#FF8FBF", "panza": "#FFD6E8", "nariz": "#E06A9A",
		"crin": "#B66BE8", "alto_patas": 44.0, "cuerpo_r": Vector2(48, 28), "cabeza_r": 27.0, "cuello": 26.0},
	"pony_estelar": {"cuerpo": "#D9C8FF", "mancha": "#D9C8FF", "oreja": "#B9A2F2", "panza": "#EEE6FF", "nariz": "#8E6FD8",
		"crin": "#5B6CE0", "alto_patas": 44.0, "cuerpo_r": Vector2(48, 28), "cabeza_r": 27.0, "cuello": 26.0},
	"gatito": {"cuerpo": "#FFC27A", "mancha": "#F29A3E", "oreja": "#F29A3E", "panza": "#FFF1DE", "nariz": "#FF8FA3",
		"alto_patas": 30.0, "cuerpo_r": Vector2(44, 27), "cabeza_r": 31.0, "cuello": 0.0},
	"jirafa": {"cuerpo": "#FFD35C", "mancha": "#D9873A", "oreja": "#F2B84B", "panza": "#FFE9A8", "nariz": "#C77B3C",
		"alto_patas": 58.0, "cuerpo_r": Vector2(44, 26), "cabeza_r": 24.0, "cuello": 70.0},
}


static func _cuadrupedo(l: CanvasItem, id: String, pose: Dictionary) -> void:
	var cfg: Dictionary = CUADRUPEDOS[id]
	var cuerpo := Color(cfg["cuerpo"])
	var oscuro := cuerpo.darkened(0.18)
	var barro: float = pose.get("barro", 0.0)
	if barro > 0.0:
		cuerpo = cuerpo.lerp(Color("#9A6B45"), barro * 0.55)
		oscuro = oscuro.lerp(Color("#7A5232"), barro * 0.55)
	var fase: float = pose.get("fase", 0.0)
	var aire: bool = pose.get("aire", false)
	var t: float = pose.get("t", 0.0)
	var patas: float = cfg["alto_patas"]
	var cr: Vector2 = cfg["cuerpo_r"]
	var rebote := 0.0 if aire else absf(sin(fase)) * 4.0
	var cc := Vector2(0, -patas - cr.y + 4 - rebote)
	# Cola
	var cola_base := cc + Vector2(-cr.x + 4, -cr.y * 0.4)
	var meneo := sin(t * 14.0) * 0.5
	match id:
		"pony", "pony_estelar":
			var crin := Color(cfg["crin"])
			for q in 3:
				var a := PI * 0.85 + meneo * 0.3 + q * 0.18
				palo(l, cola_base, cola_base + Vector2.from_angle(a) * (30.0 + q * 4.0) + Vector2(0, 10), 9.0 - q * 2.0, crin.lightened(q * 0.12))
		"gatito":
			var p := PackedVector2Array()
			for q in 8:
				p.append(cola_base + Vector2(-q * 6.0, -q * 5.0 + sin(t * 6.0 + q * 0.6) * q * 1.2))
			l.draw_polyline(p, TINTA, 13.0, true)
			l.draw_polyline(p, oscuro, 9.0, true)
		"jirafa":
			palo(l, cola_base, cola_base + Vector2(-16, 26 + meneo * 6.0), 4.0, oscuro)
			circulo(l, cola_base + Vector2(-17, 30 + meneo * 6.0), 5.0, Color("#8A5A2B"))
		_:
			palo(l, cola_base, cola_base + Vector2(-20, -22).rotated(meneo), 8.0, Color(cfg["mancha"]))
			circulo(l, cola_base + Vector2(-20, -22).rotated(meneo), 5.0, BLANCO, false)
	# Patas de atrás (lejos) y adelante (cerca), con vaivén.
	var abiertas := 0.55 if aire else 1.0
	var piernas := [
		[Vector2(-cr.x * 0.55, cc.y + cr.y * 0.5), sin(fase + PI) * 0.6 * abiertas, true],
		[Vector2(cr.x * 0.55, cc.y + cr.y * 0.5), sin(fase) * 0.6 * abiertas, true],
		[Vector2(-cr.x * 0.4, cc.y + cr.y * 0.55), sin(fase) * 0.6 * abiertas, false],
		[Vector2(cr.x * 0.68, cc.y + cr.y * 0.55), sin(fase + PI) * 0.6 * abiertas, false],
	]
	if aire:
		piernas[0][1] = -0.7
		piernas[2][1] = -0.5
		piernas[1][1] = 0.7
		piernas[3][1] = 0.5
	for pierna in piernas:
		if not pierna[2]:
			continue
		var cadera: Vector2 = pierna[0]
		var largo := -cadera.y - rebote * 0.0
		var pie: Vector2 = cadera + Vector2(0, largo).rotated(-float(pierna[1]))
		palo(l, cadera, pie, 13.0, oscuro)
		circulo(l, pie + Vector2(2, -2), 7.5, oscuro.darkened(0.15))
	# Cuerpo
	elipse(l, cc, cr, cuerpo)
	elipse(l, cc + Vector2(4, cr.y * 0.4), Vector2(cr.x * 0.65, cr.y * 0.42), Color(cfg["panza"]), 0.0, false)
	match id:
		"toby":
			elipse(l, cc + Vector2(-cr.x * 0.35, -cr.y * 0.35), Vector2(cr.x * 0.5, cr.y * 0.55), Color(cfg["mancha"]), 0.2, false)
			# Chaleco verde de explorador con la estrellita dorada.
			var chaleco := elipse_pts(cc + Vector2(cr.x * 0.3, 0), Vector2(cr.x * 0.42, cr.y * 0.92))
			poligono(l, chaleco, Color("#7E9B53"))
			l.draw_colored_polygon(estrella_pts(cc + Vector2(cr.x * 0.32, -2), 9.0), Color("#FFCB3D"))
		"jirafa":
			for m in [Vector2(-20, -8), Vector2(6, -14), Vector2(26, 2), Vector2(-4, 8), Vector2(-30, 8)]:
				elipse(l, cc + m, Vector2(8, 6), Color(cfg["mancha"]), 0.4, false)
		"gatito":
			for q in 3:
				l.draw_line(cc + Vector2(-18 + q * 14, -cr.y + 2), cc + Vector2(-22 + q * 14, -cr.y + 14), oscuro.darkened(0.1), 5.0, true)
		"pony_estelar":
			for m in [Vector2(-18, -6), Vector2(14, -10), Vector2(-2, 6)]:
				l.draw_colored_polygon(estrella_pts(cc + m, 6.0), Color("#FFF3A8"))
	for pierna in piernas:
		if pierna[2]:
			continue
		var cadera: Vector2 = pierna[0]
		var pie: Vector2 = cadera + Vector2(0, -cadera.y).rotated(-float(pierna[1]))
		palo(l, cadera, pie, 14.0, cuerpo)
		circulo(l, pie + Vector2(2, -2), 8.0, cuerpo.darkened(0.25) if id != "toby" else Color("#FFF6E6"))
	# Cuello y cabeza
	var cuello_largo: float = cfg["cuello"]
	var agacha: float = pose.get("cuello", 0.0)
	var hombro := cc + Vector2(cr.x * 0.6, -cr.y * 0.4)
	var angulo_cuello := lerpf(-1.25, -0.25, agacha) if id == "jirafa" else -0.9
	var cabeza := hombro + Vector2.from_angle(angulo_cuello) * cuello_largo + Vector2(10, -10)
	if cuello_largo > 0.0:
		palo(l, hombro, cabeza, 20.0 if id == "jirafa" else 24.0, cuerpo)
		if id == "jirafa":
			for q in 3:
				elipse(l, hombro.lerp(cabeza, 0.25 + q * 0.25), Vector2(5, 4), Color(cfg["mancha"]), 0.0, false)
	_cabeza_cuadrupedo(l, id, cfg, cabeza, cuerpo, pose)


static func _cabeza_cuadrupedo(l: CanvasItem, id: String, cfg: Dictionary, c: Vector2, cuerpo: Color, pose: Dictionary) -> void:
	var r: float = cfg["cabeza_r"]
	var t: float = pose.get("t", 0.0)
	var oreja := Color(cfg["oreja"])
	var parpadeo: bool = pose.get("parpadeo", false)
	var boca: String = pose.get("boca", "feliz")
	match id:
		"toby":
			# Orejas largas de beagle que flamean al correr.
			var flamea := sin(t * 12.0) * 0.25 + (0.6 if pose.get("aire", false) else 0.0)
			elipse(l, c + Vector2(-r * 0.7, r * 0.3), Vector2(12, 26), oreja, 0.5 + flamea)
		"pony", "pony_estelar":
			poligono(l, PackedVector2Array([c + Vector2(-8, -r + 2), c + Vector2(-2, -r - 20), c + Vector2(6, -r + 4)]), cuerpo)
		"gatito":
			for lado in [-1.0, 1.0]:
				poligono(l, PackedVector2Array([c + Vector2(lado * 20 - 10, -r * 0.6), c + Vector2(lado * 22, -r - 14), c + Vector2(lado * 20 + 10, -r * 0.6)]), oreja)
		"jirafa":
			for lado in [-1.0, 1.0]:
				palo(l, c + Vector2(lado * 8, -r * 0.7), c + Vector2(lado * 10, -r - 12), 5.0, Color(cfg["mancha"]))
				circulo(l, c + Vector2(lado * 10, -r - 14), 5.0, Color("#8A5A2B"))
			elipse(l, c + Vector2(-r * 0.9, -r * 0.3), Vector2(12, 6), oreja, -0.4)
	# Cara: hocico alargado hacia la derecha.
	elipse(l, c, Vector2(r, r * 0.92), cuerpo)
	var hocico := c + Vector2(r * 0.65, r * 0.32)
	elipse(l, hocico, Vector2(r * 0.55, r * 0.42), Color(cfg["panza"]))
	if id == "toby":
		elipse(l, c + Vector2(-r * 0.1, -r * 0.45), Vector2(r * 0.45, r * 0.4), Color(cfg["mancha"]), 0.0, false)
	elipse(l, hocico + Vector2(r * 0.42, -r * 0.12), Vector2(r * 0.17, r * 0.13), Color(cfg["nariz"]), 0.0, false)
	ojo(l, c + Vector2(r * 0.22, -r * 0.12), r * 0.24, parpadeo)
	l.draw_circle(c + Vector2(r * 0.05, r * 0.38), r * 0.16, RUBOR)
	match boca:
		"abierta":
			sonrisa(l, hocico + Vector2(r * 0.05, r * 0.12), r * 0.24, true)
		"oh":
			circulo(l, hocico + Vector2(r * 0.1, r * 0.2), r * 0.12, Color("#7A2E3E"))
		_:
			sonrisa(l, hocico + Vector2(r * 0.05, r * 0.02), r * 0.2)
	match id:
		"toby":
			elipse(l, c + Vector2(r * 0.55, -r * 0.05), Vector2(10, 22), oreja.darkened(0.05), -0.2)
			# Casco de vidrio (el de la ficha: la burbuja es "el casco de Toby en grande").
			l.draw_arc(c + Vector2(r * 0.2, 0), r * 1.45, 0.0, TAU, 40, Color(0.85, 0.95, 1.0, 0.75), 3.0, true)
			l.draw_arc(c + Vector2(r * 0.2, 0), r * 1.3, PI * 1.15, PI * 1.45, 10, Color(1, 1, 1, 0.8), 4.0, true)
		"pony", "pony_estelar":
			var crin := Color(cfg["crin"])
			for q in 4:
				var p := c + Vector2(-r * 0.6 - q * 6.0, -r * 0.7 + q * 12.0)
				circulo(l, p, 11.0 - q, crin.lightened(q * 0.1))
			if id == "pony_estelar":
				l.draw_colored_polygon(estrella_pts(c + Vector2(-2, -r - 4), 9.0), Color("#FFE066"))
		"gatito":
			for lado in [-1.0, 1.0]:
				l.draw_line(hocico + Vector2(r * 0.3, 2), hocico + Vector2(r * 0.95, 2 + lado * 8.0), TINTA, 2.0, true)


static func _dino(l: CanvasItem, id: String, pose: Dictionary) -> void:
	var colores := {
		"trex": ["#7BC96F", "#C8EFA8"], "trex_bombero": ["#7BC96F", "#C8EFA8"],
		"spino": ["#5BB5C9", "#BFEAF2"], "carno": ["#F29A4A", "#FFE0B8"],
	}
	var cuerpo := Color(colores[id][0])
	var panza := Color(colores[id][1])
	var barro: float = pose.get("barro", 0.0)
	if barro > 0.0:
		cuerpo = cuerpo.lerp(Color("#9A6B45"), barro * 0.55)
	var oscuro := cuerpo.darkened(0.2)
	var fase: float = pose.get("fase", 0.0)
	var aire: bool = pose.get("aire", false)
	var t: float = pose.get("t", 0.0)
	var rebote := 0.0 if aire else absf(sin(fase)) * 5.0
	var cc := Vector2(-6, -82 - rebote)
	# Cola gordita
	var cola := PackedVector2Array([cc + Vector2(-30, -22), cc + Vector2(-92, 6 + sin(t * 8.0) * 6.0), cc + Vector2(-28, 22)])
	poligono(l, cola, cuerpo)
	# Vela del spinosaurio
	if id == "spino":
		var vela := PackedVector2Array()
		for q in 9:
			var a := lerpf(PI * 1.05, PI * 1.95, q / 8.0)
			vela.append(cc + Vector2(cos(a) * 46.0, sin(a) * 52.0 - 18.0))
		poligono(l, vela, Color("#FF9F4A"))
		for q in 4:
			l.draw_line(cc + Vector2(-24 + q * 16, -24), cc + Vector2(-30 + q * 18, -58 + absf(q - 1.5) * 8.0), Color("#E07A2E"), 3.0, true)
	# Piernas (lejos)
	var abiertas := 0.4 if aire else 1.0
	var p_lejos := Vector2(8, -38).rotated(sin(fase + PI) * 0.6 * abiertas)
	palo(l, cc + Vector2(-4, 26), cc + Vector2(-4, 26) + Vector2(0, 54 - rebote).rotated(-sin(fase + PI) * 0.6 * abiertas), 17.0, oscuro)
	# Cuerpo
	elipse(l, cc, Vector2(52, 44), cuerpo, -0.15)
	elipse(l, cc + Vector2(14, 12), Vector2(30, 26), panza, -0.15, false)
	for q in 3:
		elipse(l, cc + Vector2(-26 + q * 18, -30 + q * 2), Vector2(5, 4), panza.lightened(0.2), 0.0, false)
	# Pierna (cerca)
	var cadera := cc + Vector2(10, 28)
	var pie := cadera + Vector2(0, 54 - rebote).rotated(-sin(fase) * 0.6 * abiertas)
	palo(l, cadera, pie, 19.0, cuerpo)
	elipse(l, pie + Vector2(8, -2), Vector2(14, 7), cuerpo.darkened(0.1))
	# Bracitos cortitos
	var brazo := cc + Vector2(42, 4)
	palo(l, brazo, brazo + Vector2(14, 10 + sin(t * 10.0) * 3.0), 7.0, cuerpo)
	# Cabeza grande
	var cabeza := cc + Vector2(50, -46)
	var mandibula_abierta: bool = pose.get("boca", "feliz") == "abierta"
	elipse(l, cabeza + Vector2(10, 10 + (6 if mandibula_abierta else 0)), Vector2(34, 16), cuerpo.darkened(0.06), 0.1)
	elipse(l, cabeza, Vector2(40, 30), cuerpo, 0.05)
	if mandibula_abierta:
		elipse(l, cabeza + Vector2(16, 18), Vector2(20, 9), Color("#7A2E3E"), 0.1, false)
		for q in 3:
			poligono(l, PackedVector2Array([cabeza + Vector2(4 + q * 10, 12), cabeza + Vector2(9 + q * 10, 12), cabeza + Vector2(6.5 + q * 10, 18)]), BLANCO, false)
	else:
		l.draw_arc(cabeza + Vector2(16, 6), 18.0, 0.2, PI * 0.75, 10, TINTA, 2.8, true)
	l.draw_circle(cabeza + Vector2(30, -8), 3.0, TINTA)
	ojo(l, cabeza + Vector2(2, -10), 9.0, pose.get("parpadeo", false))
	l.draw_circle(cabeza + Vector2(6, 10), 6.0, RUBOR)
	if id == "carno":
		for lado in [-1.0, 1.0]:
			poligono(l, PackedVector2Array([cabeza + Vector2(-8 + lado * 6, -24), cabeza + Vector2(-4 + lado * 6, -40), cabeza + Vector2(2 + lado * 6, -24)]), Color("#FFE0B8"))
	if id == "trex_bombero":
		# Casco rojo de bombero con su escudito dorado.
		var casco := PackedVector2Array()
		for q in 13:
			var a := lerpf(PI, TAU, q / 12.0)
			casco.append(cabeza + Vector2(-4 + cos(a) * 30.0, -14 + sin(a) * 24.0))
		casco.append(cabeza + Vector2(34, -14))
		casco.append(cabeza + Vector2(-40, -14))
		poligono(l, casco, Color("#E8434B"))
		circulo(l, cabeza + Vector2(-4, -28), 8.0, Color("#FFCB3D"))


# ---------------------------------------------------------------------------
# Obstáculos (todos blanditos o de juguete) y aéreos (sin bichos)
# ---------------------------------------------------------------------------

## `r` = rectángulo de UNA pieza en pantalla (su borde de abajo apoya en el suelo, o en su altura si es aéreo).
static func obstaculo(l: CanvasItem, dibujo: String, r: Rect2, t: float, semilla_vis: int) -> void:
	var c := r.get_center()
	var w := r.size.x
	var h := r.size.y
	var abajo := r.position.y + h
	match dibujo:
		"hojas":
			var colores := [Color("#E8A33D"), Color("#D9693A"), Color("#F2C84B"), Color("#B9C94A")]
			for q in 7:
				var p := Vector2(r.position.x + w * (0.15 + 0.7 * fmod(q * 0.37 + semilla_vis * 0.13, 1.0)), abajo - h * (0.2 + 0.55 * fmod(q * 0.53, 1.0)))
				elipse(l, p, Vector2(w * 0.2, h * 0.22), colores[q % 4], q * 0.9)
		"arbusto", "arbusto_florido":
			for q in 4:
				circulo(l, Vector2(r.position.x + w * (0.2 + q * 0.2), abajo - h * (0.35 + 0.15 * (q % 2))), h * 0.38, Color("#5DBB63") if q % 2 == 0 else Color("#4FA857"))
			circulo(l, Vector2(c.x, abajo - h * 0.62), h * 0.36, Color("#6CCB6F"))
			if dibujo == "arbusto_florido":
				for q in 5:
					var p := Vector2(r.position.x + w * (0.18 + q * 0.16), abajo - h * (0.45 + 0.25 * (q % 2)))
					l.draw_colored_polygon(estrella_pts(p, 7.0), Color("#FF8FC4") if q % 2 == 0 else Color("#FFE066"))
					l.draw_circle(p, 2.5, Color("#FFF6E6"))
			l.draw_circle(c + Vector2(-8, -h * 0.05), 3.0, TINTA)
			l.draw_circle(c + Vector2(8, -h * 0.05), 3.0, TINTA)
			l.draw_arc(c + Vector2(0, h * 0.05), 6.0, 0.3, PI - 0.3, 8, TINTA, 2.2, true)
		"charquito", "charco":
			elipse(l, Vector2(c.x, abajo - h * 0.35), Vector2(w * 0.5, h * 0.4), Color("#7FC4F0"))
			elipse(l, Vector2(c.x - w * 0.12, abajo - h * 0.45), Vector2(w * 0.18, h * 0.12), Color(1, 1, 1, 0.6), 0.0, false)
			var ola := sin(t * 4.0 + semilla_vis) * 3.0
			l.draw_arc(Vector2(c.x + w * 0.2, abajo - h * 0.3), 8.0 + ola, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.7), 2.0, true)
		"tronco", "tronco_goma":
			var color := Color("#B9773F") if dibujo == "tronco" else Color("#E8954A")
			var cuerpo := Rect2(r.position.x + w * 0.1, abajo - h * 0.85, w * 0.8, h * 0.85)
			var caja := StyleBoxFlat.new()
			caja.bg_color = color
			caja.border_color = TINTA
			caja.set_border_width_all(3)
			caja.set_corner_radius_all(int(h * 0.4))
			caja.anti_aliasing = true
			l.draw_style_box(caja, cuerpo)
			elipse(l, Vector2(cuerpo.position.x + cuerpo.size.x, cuerpo.get_center().y), Vector2(h * 0.24, h * 0.42), Color("#F2C88F"))
			l.draw_arc(Vector2(cuerpo.position.x + cuerpo.size.x, cuerpo.get_center().y), h * 0.2, 0.0, TAU, 16, Color("#C9945A"), 2.0, true)
			l.draw_line(cuerpo.position + Vector2(10, h * 0.3), cuerpo.position + Vector2(w * 0.45, h * 0.3), color.darkened(0.25), 3.0, true)
			if dibujo == "tronco_goma":
				l.draw_circle(cuerpo.get_center() + Vector2(-10, -2), 2.5, TINTA)
				l.draw_circle(cuerpo.get_center() + Vector2(4, -2), 2.5, TINTA)
				l.draw_arc(cuerpo.get_center() + Vector2(-3, 4), 5.0, 0.3, PI - 0.3, 8, TINTA, 2.0, true)
		"piedra", "roca_esponja":
			var color := Color("#B8B4C8") if dibujo == "piedra" else Color("#FFD36B")
			elipse(l, Vector2(c.x, abajo - h * 0.45), Vector2(w * 0.48, h * 0.48), color)
			elipse(l, Vector2(c.x - w * 0.15, abajo - h * 0.7), Vector2(w * 0.14, h * 0.1), Color(1, 1, 1, 0.55), 0.0, false)
			if dibujo == "roca_esponja":
				for q in 5:
					l.draw_circle(Vector2(r.position.x + w * (0.2 + q * 0.15), abajo - h * (0.3 + 0.25 * (q % 2))), 4.0, color.darkened(0.2))
			else:
				l.draw_arc(Vector2(c.x + 6, abajo - h * 0.4), 6.0, 0.3, PI - 0.3, 8, TINTA, 2.0, true)
		"cerca_flores":
			for q in 3:
				var x := r.position.x + w * (0.15 + q * 0.35)
				poligono(l, PackedVector2Array([Vector2(x - 7, abajo), Vector2(x - 7, abajo - h * 0.8), Vector2(x, abajo - h), Vector2(x + 7, abajo - h * 0.8), Vector2(x + 7, abajo)]), Color("#FFF1DE"))
			l.draw_line(Vector2(r.position.x, abajo - h * 0.55), Vector2(r.position.x + w, abajo - h * 0.55), TINTA, 7.0)
			l.draw_line(Vector2(r.position.x, abajo - h * 0.55), Vector2(r.position.x + w, abajo - h * 0.55), Color("#FFF1DE"), 4.0)
			for q in 3:
				var p := Vector2(r.position.x + w * (0.3 + q * 0.3), abajo - h * 0.3)
				for k in 5:
					l.draw_circle(p + Vector2.from_angle(TAU * k / 5.0) * 5.0, 4.0, Color("#FF8FC4"))
				l.draw_circle(p, 3.0, Color("#FFE066"))
		"nenufar":
			elipse(l, Vector2(c.x, abajo - h * 0.25), Vector2(w * 0.5, h * 0.25), Color("#7FC4F0"), 0.0, false)
			var hoja := elipse_pts(Vector2(c.x, abajo - h * 0.45), Vector2(w * 0.42, h * 0.3))
			poligono(l, hoja, Color("#5DBB63"))
			for k in 6:
				var a := -PI / 2.0 + TAU * k / 6.0
				elipse(l, Vector2(c.x, abajo - h * 0.85) + Vector2.from_angle(a) * 8.0, Vector2(7, 4), Color("#FF9EC8"), a, false)
			l.draw_circle(Vector2(c.x, abajo - h * 0.85), 4.0, Color("#FFE066"))
		"fardo":
			var caja := StyleBoxFlat.new()
			caja.bg_color = Color("#F2CF6B")
			caja.border_color = TINTA
			caja.set_border_width_all(3)
			caja.set_corner_radius_all(14)
			caja.anti_aliasing = true
			l.draw_style_box(caja, Rect2(r.position.x + 4, abajo - h, w - 8, h))
			for q in 4:
				l.draw_line(Vector2(r.position.x + 12, abajo - h * (0.2 + q * 0.2)), Vector2(r.position.x + w - 12, abajo - h * (0.2 + q * 0.2)), Color("#D9A93E"), 2.0, true)
			l.draw_line(Vector2(c.x, abajo - h), Vector2(c.x, abajo), Color("#C9563B"), 4.0, true)
		"cono":
			poligono(l, PackedVector2Array([Vector2(c.x - w * 0.42, abajo - 6), Vector2(c.x - 6, abajo - h), Vector2(c.x + 6, abajo - h), Vector2(c.x + w * 0.42, abajo - 6)]), Color("#FF8A3D"))
			l.draw_line(Vector2(c.x - w * 0.25, abajo - h * 0.45), Vector2(c.x + w * 0.25, abajo - h * 0.45), BLANCO, 8.0, true)
			var base := StyleBoxFlat.new()
			base.bg_color = Color("#FF8A3D").darkened(0.15)
			base.border_color = TINTA
			base.set_border_width_all(3)
			base.set_corner_radius_all(4)
			l.draw_style_box(base, Rect2(r.position.x, abajo - 10, w, 10))
		"manguera":
			for q in 3:
				l.draw_arc(Vector2(c.x, abajo - h * 0.45), h * (0.45 - q * 0.13), 0.0, TAU, 24, TINTA, 10.0, true)
				l.draw_arc(Vector2(c.x, abajo - h * 0.45), h * (0.45 - q * 0.13), 0.0, TAU, 24, Color("#E8434B"), 6.0, true)
			circulo(l, Vector2(c.x + h * 0.5, abajo - h * 0.15), 7.0, Color("#FFCB3D"))
		"raiz":
			var p := PackedVector2Array([Vector2(r.position.x, abajo), Vector2(r.position.x + w * 0.2, abajo - h * 0.8), Vector2(c.x, abajo - h), Vector2(r.position.x + w * 0.8, abajo - h * 0.7), Vector2(r.position.x + w, abajo)])
			poligono(l, p, Color("#A0663A"))
			l.draw_arc(Vector2(c.x, abajo), w * 0.25, PI, TAU, 12, TINTA, 3.0, true)
			l.draw_arc(Vector2(c.x, abajo), w * 0.22, PI, TAU, 12, Color("#5E3A20"), 3.0, true)
		"hongo", "hongo_gigante":
			var pie := Rect2(c.x - w * 0.16, abajo - h * 0.55, w * 0.32, h * 0.55)
			var caja := StyleBoxFlat.new()
			caja.bg_color = Color("#FFF1DE")
			caja.border_color = TINTA
			caja.set_border_width_all(3)
			caja.set_corner_radius_all(10)
			l.draw_style_box(caja, pie)
			var sombrero := PackedVector2Array()
			for q in 15:
				var a := lerpf(PI, TAU, q / 14.0)
				sombrero.append(Vector2(c.x, abajo - h * 0.5) + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.5))
			poligono(l, sombrero, Color("#FF6B6B") if dibujo == "hongo" else Color("#B48CE8"))
			for m in [Vector2(-0.2, -0.75), Vector2(0.15, -0.85), Vector2(0.3, -0.6), Vector2(-0.32, -0.58)]:
				l.draw_circle(Vector2(c.x + m.x * w, abajo + m.y * h), w * 0.06, BLANCO)
			l.draw_circle(Vector2(c.x - 6, abajo - h * 0.32), 2.5, TINTA)
			l.draw_circle(Vector2(c.x + 6, abajo - h * 0.32), 2.5, TINTA)
		"caja":
			var caja := StyleBoxFlat.new()
			caja.bg_color = Color("#D9A066")
			caja.border_color = TINTA
			caja.set_border_width_all(3)
			caja.set_corner_radius_all(8)
			caja.anti_aliasing = true
			var rr := Rect2(r.position.x + 4, abajo - h, w - 8, h)
			l.draw_style_box(caja, rr)
			l.draw_line(rr.position + Vector2(0, h * 0.3), rr.position + Vector2(rr.size.x, h * 0.3), TINTA, 2.5, true)
			l.draw_colored_polygon(estrella_pts(rr.get_center() + Vector2(0, 8), 12.0), Color("#FFCB3D"))
		"hueso_juguete":
			var a := Vector2(r.position.x + w * 0.22, abajo - h * 0.45)
			var b := Vector2(r.position.x + w * 0.78, abajo - h * 0.45)
			for p in [a, b]:
				circulo(l, p + Vector2(0, -h * 0.2), h * 0.25, Color("#FFF6E6"))
				circulo(l, p + Vector2(0, h * 0.2), h * 0.25, Color("#FFF6E6"))
			palo(l, a, b, h * 0.42, Color("#FFF6E6"))
		_:
			elipse(l, Vector2(c.x, abajo - h * 0.45), Vector2(w * 0.48, h * 0.45), Color("#B8B4C8"))


## Aéreos animados. `r` = rectángulo del dibujo.
static func aereo(l: CanvasItem, dibujo: String, r: Rect2, t: float, semilla_vis: int) -> void:
	var c := r.get_center()
	var w := r.size.x
	var h := r.size.y
	var aleteo := sin(t * 14.0 + semilla_vis)
	match dibujo:
		"pajarito", "gaviota", "loro", "lechucita":
			var colores := {"pajarito": ["#6FB8FF", "#FFE066"], "gaviota": ["#F4F6FA", "#FFB347"], "loro": ["#5DBB63", "#FF6B6B"], "lechucita": ["#B89BE0", "#FFCB3D"]}
			var cuerpo := Color(colores[dibujo][0])
			var pico := Color(colores[dibujo][1])
			var ala := PackedVector2Array([c + Vector2(-4, -2), c + Vector2(-w * 0.35, -h * 0.45 * aleteo - 4), c + Vector2(w * 0.1, -4)])
			elipse(l, c, Vector2(w * 0.36, h * 0.32), cuerpo)
			poligono(l, ala, cuerpo.darkened(0.12))
			# Mira hacia la izquierda (hacia el corredor) y sonríe.
			var cabeza := c + Vector2(-w * 0.32, -h * 0.12)
			circulo(l, cabeza, h * 0.24, cuerpo)
			poligono(l, PackedVector2Array([cabeza + Vector2(-h * 0.2, -3), cabeza + Vector2(-h * 0.42, 2), cabeza + Vector2(-h * 0.2, 6)]), pico)
			ojo(l, cabeza + Vector2(-2, -3), 5.0, fmod(t + semilla_vis, 3.0) < 0.12)
			l.draw_circle(cabeza + Vector2(4, 6), 4.0, RUBOR)
			if dibujo == "loro":
				poligono(l, PackedVector2Array([c + Vector2(w * 0.3, 0), c + Vector2(w * 0.55, h * 0.3), c + Vector2(w * 0.3, h * 0.15)]), Color("#3D7BE0"))
			if dibujo == "lechucita":
				for lado in [-1.0, 1.0]:
					poligono(l, PackedVector2Array([cabeza + Vector2(lado * 6 - 4, -h * 0.18), cabeza + Vector2(lado * 8, -h * 0.36), cabeza + Vector2(lado * 6 + 4, -h * 0.18)]), cuerpo)
		"globo":
			var colores := [Color("#FF6B9A"), Color("#FFCB3D"), Color("#6FB8FF"), Color("#7DD87A")]
			var color: Color = colores[semilla_vis % colores.size()]
			var meneo := sin(t * 2.5 + semilla_vis) * 4.0
			var globo := c + Vector2(meneo, -h * 0.1)
			l.draw_line(globo + Vector2(0, h * 0.4), c + Vector2(meneo * 0.3, h * 0.5), TINTA, 2.0, true)
			elipse(l, globo, Vector2(w * 0.4, h * 0.42), color)
			elipse(l, globo + Vector2(-w * 0.14, -h * 0.16), Vector2(w * 0.08, h * 0.12), Color(1, 1, 1, 0.6), 0.0, false)
			l.draw_circle(globo + Vector2(-6, 0), 2.5, TINTA)
			l.draw_circle(globo + Vector2(6, 0), 2.5, TINTA)
			l.draw_arc(globo + Vector2(0, 5), 5.0, 0.3, PI - 0.3, 8, TINTA, 2.0, true)
		"cometa_papel":
			var p := PackedVector2Array([c + Vector2(0, -h * 0.45), c + Vector2(w * 0.35, 0), c + Vector2(0, h * 0.45), c + Vector2(-w * 0.35, 0)])
			poligono(l, p, Color("#FF8FC4"))
			l.draw_line(p[0], p[2], TINTA, 2.0)
			l.draw_line(p[1], p[3], TINTA, 2.0)
			var cola := PackedVector2Array()
			for q in 8:
				cola.append(p[2] + Vector2(q * 6.0, q * 4.0 + sin(t * 6.0 + q) * 4.0))
			l.draw_polyline(cola, TINTA, 2.0, true)
		"pez":
			var salto := sin(t * 5.0 + semilla_vis) * 4.0
			var cc := c + Vector2(0, salto)
			poligono(l, PackedVector2Array([cc + Vector2(w * 0.25, 0), cc + Vector2(w * 0.5, -h * 0.3), cc + Vector2(w * 0.5, h * 0.3)]), Color("#FFB347"))
			elipse(l, cc, Vector2(w * 0.33, h * 0.3), Color("#FF9F4A"), 0.15 * sin(t * 5.0))
			ojo(l, cc + Vector2(-w * 0.15, -3), 5.0, false)
			l.draw_arc(cc + Vector2(-w * 0.22, 6), 5.0, 0.2, PI - 0.4, 8, TINTA, 2.0, true)
			for q in 3:
				l.draw_circle(cc + Vector2(w * 0.2 - q * 14, h * 0.55 + q * 3), 3.0, Color(0.6, 0.85, 1.0, 0.8))
		"hoja":
			var giro := sin(t * 3.0 + semilla_vis) * 0.6
			var hoja := elipse_pts(c, Vector2(w * 0.4, h * 0.22), giro)
			poligono(l, hoja, Color("#7DD87A"))
			l.draw_line(c - Vector2(w * 0.35, 0).rotated(giro), c + Vector2(w * 0.35, 0).rotated(giro), Color("#4FA857"), 2.0, true)
			l.draw_circle(c + Vector2(-5, -2), 2.5, TINTA)
			l.draw_circle(c + Vector2(5, -2), 2.5, TINTA)
		"estrellita":
			var p := estrella_pts(c, h * 0.48, -PI / 2.0 + sin(t * 3.0) * 0.2)
			poligono(l, p, Color("#FFE066"))
			l.draw_circle(c + Vector2(-5, 0), 2.5, TINTA)
			l.draw_circle(c + Vector2(5, 0), 2.5, TINTA)
			l.draw_arc(c + Vector2(0, 5), 4.0, 0.3, PI - 0.3, 8, TINTA, 2.0, true)
		_:
			circulo(l, c, h * 0.4, Color("#6FB8FF"))


# ---------------------------------------------------------------------------
# Coleccionables, burbuja y metas
# ---------------------------------------------------------------------------

static func item(l: CanvasItem, id: String, c: Vector2, r: float, t: float) -> void:
	var flota := Vector2(0, sin(t * 4.0 + c.x * 0.01) * 4.0)
	c += flota
	l.draw_circle(c, r * 1.25, Color(1, 1, 0.8, 0.25 + 0.15 * sin(t * 6.0)))
	match id:
		"huevito":
			elipse(l, c, Vector2(r * 0.72, r * 0.95), Color("#FFF6E6"))
			for m in [Vector2(-0.3, -0.3), Vector2(0.25, 0.1), Vector2(-0.1, 0.45)]:
				l.draw_circle(c + m * r, r * 0.16, Color("#7BC96F"))
		"manzanita":
			circulo(l, c, r * 0.85, Color("#FF6B6B"))
			l.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(3, -r * 1.2), TINTA, 3.0, true)
			elipse(l, c + Vector2(8, -r), Vector2(8, 4), Color("#7DD87A"), -0.4)
			elipse(l, c + Vector2(-r * 0.3, -r * 0.3), Vector2(r * 0.18, r * 0.12), Color(1, 1, 1, 0.6), 0.0, false)
		"corazon":
			poligono(l, corazon_pts(c, r * 0.95), Color("#FF7EB6"))
			elipse(l, c + Vector2(-r * 0.35, -r * 0.3), Vector2(r * 0.16, r * 0.1), Color(1, 1, 1, 0.65), -0.5, false)
		"huesito":
			var a := c + Vector2(-r * 0.6, 0)
			var b := c + Vector2(r * 0.6, 0)
			for p in [a, b]:
				circulo(l, p + Vector2(0, -r * 0.25), r * 0.3, Color("#FFF6E6"))
				circulo(l, p + Vector2(0, r * 0.25), r * 0.3, Color("#FFF6E6"))
			palo(l, a, b, r * 0.45, Color("#FFF6E6"))
		"gotita":
			var p := PackedVector2Array()
			for k in 20:
				var ang := TAU * k / 20.0
				var rr := r * 0.8 * (1.0 - 0.35 * max(0.0, -sin(ang)))
				p.append(c + Vector2(cos(ang) * rr * 0.8, sin(ang) * rr) + Vector2(0, -r * 0.6 * max(0.0, -sin(ang)) * absf(cos(ang * 0.5))))
			poligono(l, elipse_pts(c + Vector2(0, 4), Vector2(r * 0.65, r * 0.75)), Color("#6FC8F5"))
			poligono(l, PackedVector2Array([c + Vector2(-r * 0.45, -2), c + Vector2(0, -r * 1.1), c + Vector2(r * 0.45, -2)]), Color("#6FC8F5"), false)
			l.draw_circle(c + Vector2(-5, 4), 2.5, TINTA)
			l.draw_circle(c + Vector2(5, 4), 2.5, TINTA)
		_:
			l.draw_colored_polygon(estrella_pts(c, r), Color("#FFE066"))


static func burbuja(l: CanvasItem, c: Vector2, r: float, t: float, alfa := 1.0) -> void:
	var b := 0.5 + 0.5 * sin(t * 4.0)
	l.draw_circle(c, r, Color(0.75, 0.92, 1.0, 0.18 * alfa))
	l.draw_arc(c, r, 0.0, TAU, 48, Color(0.55, 0.85, 1.0, (0.55 + 0.25 * b) * alfa), 4.0, true)
	l.draw_arc(c, r * 0.82, PI * 1.12, PI * 1.42, 12, Color(1, 1, 1, 0.85 * alfa), 5.0, true)
	l.draw_circle(c + Vector2(r * 0.45, -r * 0.5), r * 0.07, Color(1, 1, 1, 0.9 * alfa))
	# Brillos de colores que giran (el "casco de Toby en grande").
	for k in 3:
		var a := t * 1.5 + TAU * k / 3.0
		l.draw_arc(c, r * 0.96, a, a + 0.35, 6, Color.from_hsv(fmod(k / 3.0 + t * 0.1, 1.0), 0.4, 1.0, 0.5 * alfa), 3.0, true)


## La meta, apoyada en el suelo en `base`. `fiesta` 0-1: revienta en confeti y se mueve.
static func meta(l: CanvasItem, dibujo: String, base: Vector2, t: float, fiesta: float) -> void:
	var salto := sin(fiesta * PI) * 20.0
	base.y -= salto
	match dibujo:
		"carpa":
			var p := PackedVector2Array([base + Vector2(-110, 0), base + Vector2(0, -170), base + Vector2(110, 0)])
			poligono(l, p, Color("#FF9F4A"))
			for q in 3:
				l.draw_line(base + Vector2(0, -170), base + Vector2(-60 + q * 60, 0), Color("#E07A2E"), 4.0, true)
			poligono(l, PackedVector2Array([base + Vector2(-30, 0), base + Vector2(0, -70), base + Vector2(30, 0)]), Color("#5E3A20"))
			l.draw_line(base + Vector2(0, -170), base + Vector2(0, -215), TINTA, 4.0, true)
			l.draw_colored_polygon(estrella_pts(base + Vector2(0, -222), 14.0 + fiesta * 6.0, -PI / 2.0 + t), Color("#FFCB3D"))
		"establo":
			poligono(l, PackedVector2Array([base + Vector2(-100, 0), base + Vector2(-100, -110), base + Vector2(100, -110), base + Vector2(100, 0)]), Color("#E8656B"))
			poligono(l, PackedVector2Array([base + Vector2(-118, -106), base + Vector2(0, -180), base + Vector2(118, -106)]), Color("#B9474F"))
			poligono(l, PackedVector2Array([base + Vector2(-34, 0), base + Vector2(-34, -70), base + Vector2(34, -70), base + Vector2(34, 0)]), Color("#FFF1DE"))
			l.draw_line(base + Vector2(-34, -70), base + Vector2(34, 0), Color("#E8656B"), 5.0)
			l.draw_line(base + Vector2(34, -70), base + Vector2(-34, 0), Color("#E8656B"), 5.0)
			poligono(l, corazon_pts(base + Vector2(0, -132), 16.0), Color("#FF8FC4"))
		"muelle":
			for q in 4:
				palo(l, base + Vector2(-90 + q * 60, 0), base + Vector2(-90 + q * 60, -50), 10.0, Color("#A0663A"))
			var tabla := StyleBoxFlat.new()
			tabla.bg_color = Color("#D9A066")
			tabla.border_color = TINTA
			tabla.set_border_width_all(3)
			tabla.set_corner_radius_all(6)
			l.draw_style_box(tabla, Rect2(base + Vector2(-120, -64), Vector2(240, 18)))
			palo(l, base + Vector2(100, -64), base + Vector2(100, -170), 6.0, Color("#FFF1DE"))
			poligono(l, PackedVector2Array([base + Vector2(103, -170), base + Vector2(160, -150 + sin(t * 5.0) * 5.0), base + Vector2(103, -130)]), Color("#6FB8FF"))
		"acacia":
			palo(l, base, base + Vector2(0, -150), 22.0, Color("#A0663A"))
			palo(l, base + Vector2(0, -110), base + Vector2(-50, -160), 12.0, Color("#A0663A"))
			elipse(l, base + Vector2(-10, -175), Vector2(130, 34), Color("#7DBB52"))
			elipse(l, base + Vector2(-10, -185), Vector2(100, 22), Color("#93CC62"), 0.0, false)
			# Una jirafa asoma la cabeza por encima de la copa.
			palo(l, base + Vector2(70, -150), base + Vector2(80, -230), 12.0, Color("#FFD35C"))
			circulo(l, base + Vector2(86, -236), 16.0, Color("#FFD35C"))
			ojo(l, base + Vector2(90, -240), 4.5, false)
		"cuartel":
			poligono(l, PackedVector2Array([base + Vector2(-100, 0), base + Vector2(-100, -150), base + Vector2(100, -150), base + Vector2(100, 0)]), Color("#E8434B"))
			poligono(l, PackedVector2Array([base + Vector2(-60, 0), base + Vector2(-60, -90), base + Vector2(60, -90), base + Vector2(60, 0)]), Color("#FFF1DE"))
			for q in 3:
				l.draw_line(base + Vector2(-60, -70 + q * 24), base + Vector2(60, -70 + q * 24), Color("#D9CFC0"), 3.0)
			circulo(l, base + Vector2(0, -122), 18.0, Color("#FFCB3D"))
			if fiesta > 0.0:
				# El chorro arcoíris.
				for k in 6:
					var col := Color.from_hsv(k / 6.0, 0.6, 1.0)
					l.draw_arc(base + Vector2(130, -150), 90.0 + k * 9.0, PI * 1.05, PI * 1.05 + PI * 0.9 * fiesta, 24, col, 8.0, true)
		"arbol_nidos":
			palo(l, base, base + Vector2(0, -190), 40.0, Color("#8A5A2B"))
			for m in [Vector2(-60, -200), Vector2(50, -210), Vector2(0, -250)]:
				circulo(l, base + m, 60.0, Color("#5DBB63"))
			for m in [Vector2(-40, -150), Vector2(36, -175)]:
				elipse(l, base + m, Vector2(26, 12), Color("#C9945A"))
				l.draw_circle(base + m + Vector2(-6, -10), 6.0, Color("#6FB8FF"))
		"volcan":
			poligono(l, PackedVector2Array([base + Vector2(-150, 0), base + Vector2(-40, -160), base + Vector2(40, -160), base + Vector2(150, 0)]), Color("#B98A6A"))
			poligono(l, PackedVector2Array([base + Vector2(-40, -160), base + Vector2(-20, -140), base + Vector2(0, -158), base + Vector2(20, -138), base + Vector2(40, -160)]), Color("#FF9F4A"), false)
			for k in 4:
				var q := fmod(t * 0.4 + k * 0.25, 1.0)
				circulo(l, base + Vector2(sin(k * 2.0) * 20.0, -170 - q * 80.0), 14.0 + q * 18.0, Color(1, 1, 1, 0.8 * (1.0 - q)), false)
			if fiesta > 0.0:
				for k in 14:
					var a := -PI / 2.0 + (k - 7) * 0.13
					l.draw_circle(base + Vector2(0, -170) + Vector2.from_angle(a) * 160.0 * fiesta, 7.0, Color.from_hsv(k / 14.0, 0.6, 1.0))
		"arcoiris":
			for k in 6:
				var col := Color.from_hsv(k / 6.0, 0.55, 1.0)
				l.draw_arc(base, 150.0 - k * 14.0, PI, TAU, 40, col, 14.0, true)
			for lado in [-1.0, 1.0]:
				for q in 3:
					circulo(l, base + Vector2(lado * 130 + (q - 1) * 22, -6), 18.0, BLANCO)
		"aurora":
			pass
		_:
			palo(l, base, base + Vector2(0, -160), 6.0, Color("#FFF1DE"))
			poligono(l, PackedVector2Array([base + Vector2(3, -160), base + Vector2(70, -140), base + Vector2(3, -120)]), Color("#FF8FC4"))


## Banderita del récord clavada en el sendero, con la cara del hermano (sin números).
static func banderita_record(l: CanvasItem, base: Vector2, color: Color, retrato: Texture2D, salto: float, dorada := false) -> void:
	base.y -= salto * 30.0
	palo(l, base, base + Vector2(0, -150), 5.0, Color("#FFF1DE"))
	var tela := PackedVector2Array([base + Vector2(3, -150), base + Vector2(84, -128), base + Vector2(3, -100)])
	poligono(l, tela, Color("#FFCB3D") if dorada else color)
	if retrato != null:
		var lado := 40.0
		l.draw_circle(base + Vector2(30, -126), lado * 0.55, TINTA)
		l.draw_texture_rect(retrato, Rect2(base + Vector2(30 - lado * 0.5, -126 - lado * 0.5), Vector2(lado, lado)), false)


# ---------------------------------------------------------------------------
# Fondo con parallax (3 capas) y cielo que pasa al atardecer y a la noche
# ---------------------------------------------------------------------------

const ESCENARIOS := {
	"campamento": {"cielo": ["#8FD3FF", "#D8F1FF"], "lejos": "#A6D98B", "medio": "#6FBF5F", "suelo": "#E2B57A", "borde": "#7DBB52"},
	"laguna": {"cielo": ["#86CDF5", "#DDF4FF"], "lejos": "#9BD6C2", "medio": "#5FB58A", "suelo": "#E8C890", "borde": "#6FC8F5"},
	"pradera": {"cielo": ["#9CD8FF", "#FFF4D6"], "lejos": "#E8D07A", "medio": "#C9B95A", "suelo": "#E8C27A", "borde": "#B9C94A"},
	"nidos": {"cielo": ["#7FCBEF", "#D6F2E8"], "lejos": "#6FB87A", "medio": "#4E9E5E", "suelo": "#C99A64", "borde": "#4FA857"},
	"valle": {"cielo": ["#A9C8F5", "#F5E6FF"], "lejos": "#9AA8C9", "medio": "#7FAF6A", "suelo": "#C9A27A", "borde": "#6E9E5A"},
}
const CIELO_ATARDECER := ["#FF9F7A", "#FFD98A"]
const CIELO_NOCHE := ["#2E3B7A", "#6A5AA8"]


## `noche` 0 = día, 0,5 = atardecer dorado, 1 = noche estrellada (nunca oscura). `recorrido` = px del mundo.
static func fondo(l: CanvasItem, escenario: String, recorrido: float, noche: float, t: float, suelo_y: float, aurora := 0.0) -> void:
	var cfg: Dictionary = ESCENARIOS.get(escenario, ESCENARIOS["campamento"])
	var arriba := _cielo(cfg, noche, 0)
	var abajo := _cielo(cfg, noche, 1)
	l.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, suelo_y), Vector2(0, suelo_y)]),
		PackedColorArray([arriba, arriba, abajo, abajo]))
	var tinte := Color.WHITE.lerp(Color("#8C93D9"), clampf((noche - 0.5) * 2.0, 0.0, 1.0) * 0.6)
	if noche > 0.0 and noche < 1.0:
		tinte = tinte.lerp(Color("#FFC59A"), sin(clampf(noche, 0.0, 1.0) * PI) * 0.3)
	# Estrellas y estrellas fugaces (máximo 1 fugaz cada 3 s, sin destellos: R9).
	var estrellas := clampf((noche - 0.6) * 2.5, 0.0, 1.0)
	if estrellas > 0.0:
		for k in 60:
			var p := Vector2(fmod(k * 197.0 + recorrido * 0.02, 1280.0), fmod(k * 83.0, suelo_y * 0.7))
			var brillo := 0.6 + 0.4 * sin(t * 2.0 + k)
			l.draw_circle(p, 1.5 + (k % 3), Color(1, 1, 0.9, estrellas * brillo))
		var ciclo := fmod(t, 3.0) / 3.0
		if ciclo < 0.35:
			var k := floori(t / 3.0)
			var desde := Vector2(300.0 + fmod(k * 431.0, 800.0), 40.0 + fmod(k * 97.0, 120.0))
			var q := ciclo / 0.35
			var punta := desde + Vector2(220, 90) * q
			l.draw_line(punta - Vector2(110, 45) * minf(q * 3.0, 1.0), punta, Color(1, 1, 0.85, estrellas * (1.0 - q)), 3.0, true)
			l.draw_circle(punta, 3.5, Color(1, 1, 0.9, estrellas * (1.0 - q)))
	if aurora > 0.0:
		for k in 4:
			var col := [Color("#7DF2B8"), Color("#6FD6E8"), Color("#B48CE8"), Color("#7DF2B8")][k]
			var pts := PackedVector2Array()
			for q in 33:
				var x := q * 40.0
				pts.append(Vector2(x, 90.0 + k * 26.0 + sin(x * 0.008 + t * 0.6 + k) * 30.0))
			l.draw_polyline(pts, Color(col, 0.35 * aurora), 22.0, true)
	# Sol que baja y luna que sube.
	var sol_y := lerpf(110.0, suelo_y - 40.0, clampf(noche * 2.0, 0.0, 1.0))
	if noche < 0.75:
		var a := 1.0 - clampf((noche - 0.5) * 4.0, 0.0, 1.0)
		l.draw_circle(Vector2(1040, sol_y), 58.0, Color(1, 0.95, 0.6, 0.35 * a))
		l.draw_circle(Vector2(1040, sol_y), 44.0, Color(1, 0.86, 0.35, a).lerp(Color("#FF8A5A"), clampf(noche * 2.0, 0.0, 1.0) * 0.6))
	if noche > 0.6:
		var a := clampf((noche - 0.6) * 2.5, 0.0, 1.0)
		var luna := Vector2(220, lerpf(220.0, 110.0, a))
		l.draw_circle(luna, 40.0, Color(1, 0.97, 0.85, a))
		l.draw_circle(luna + Vector2(14, -8), 34.0, Color(_cielo(cfg, noche, 0), a))
	# Lejos (parallax 0,2)
	_capa_lejos(l, escenario, cfg, recorrido * 0.2, suelo_y, tinte)
	# Medio (parallax 0,5)
	_capa_medio(l, escenario, cfg, recorrido * 0.5, suelo_y, tinte, t)
	# Sendero (1,0)
	var suelo := Color(cfg["suelo"]) * tinte
	suelo.a = 1.0
	l.draw_rect(Rect2(0, suelo_y, 1280, 720 - suelo_y), suelo)
	var borde := Color(cfg["borde"]) * tinte
	borde.a = 1.0
	l.draw_rect(Rect2(0, suelo_y - 6, 1280, 14), borde)
	l.draw_line(Vector2(0, suelo_y + 8), Vector2(1280, suelo_y + 8), Color(TINTA, 0.25), 3.0)
	# Huellitas y piedritas del sendero (se mueven con el mundo).
	var paso := 140.0
	var x0 := -fmod(recorrido, paso)
	var k0 := floori(recorrido / paso)
	var x := x0
	var k := k0
	while x < 1300.0:
		var y := suelo_y + 34.0 + (k % 3) * 22.0
		var c := Color(suelo.darkened(0.18))
		if k % 2 == 0:
			l.draw_circle(Vector2(x, y), 7.0, c)
			for d in [Vector2(-8, -9), Vector2(0, -12), Vector2(8, -9)]:
				l.draw_circle(Vector2(x, y) + d, 3.2, c)
		else:
			elipse(l, Vector2(x + 30, y + 10), Vector2(9, 5), suelo.lightened(0.2), 0.0, false)
		x += paso
		k += 1


static func _cielo(cfg: Dictionary, noche: float, i: int) -> Color:
	var dia := Color(cfg["cielo"][i])
	if noche <= 0.5:
		return dia.lerp(Color(CIELO_ATARDECER[i]), noche * 2.0)
	return Color(CIELO_ATARDECER[i]).lerp(Color(CIELO_NOCHE[i]), (noche - 0.5) * 2.0)


static func _con_tinte(color: Color, tinte: Color) -> Color:
	var c := color * tinte
	c.a = color.a
	return c


static func _capa_lejos(l: CanvasItem, escenario: String, cfg: Dictionary, desplaz: float, suelo_y: float, tinte: Color) -> void:
	var color := _con_tinte(Color(cfg["lejos"]), tinte)
	var pts := PackedVector2Array()
	pts.append(Vector2(0, suelo_y))
	for q in 33:
		var x := q * 40.0
		var wx := x + desplaz
		pts.append(Vector2(x, suelo_y - 150.0 - sin(wx * 0.006) * 50.0 - sin(wx * 0.017) * 18.0))
	pts.append(Vector2(1280, suelo_y))
	l.draw_colored_polygon(pts, color)
	if escenario == "valle":
		# Volcán dormilón a lo lejos, con su humito de nubecitas.
		var vx := fmod(900.0 - desplaz * 0.5, 2200.0)
		if vx < -300.0:
			vx += 2200.0
		var base := Vector2(vx, suelo_y - 120.0)
		l.draw_colored_polygon(PackedVector2Array([base + Vector2(-220, 60), base + Vector2(-50, -170), base + Vector2(50, -170), base + Vector2(220, 60)]), _con_tinte(Color("#8C7AA0"), tinte))
		for k in 3:
			l.draw_circle(base + Vector2(k * 18 - 10, -190 - k * 26), 20.0 + k * 6.0, Color(1, 1, 1, 0.55))


static func _capa_medio(l: CanvasItem, escenario: String, cfg: Dictionary, desplaz: float, suelo_y: float, tinte: Color, t: float) -> void:
	var color := _con_tinte(Color(cfg["medio"]), tinte)
	var paso := 300.0
	var x := -fmod(desplaz, paso) - 60.0
	var k := floori(desplaz / paso)
	while x < 1380.0:
		var base := Vector2(x, suelo_y - 4)
		var v := posmod(k, 4)
		match escenario:
			"campamento":
				if v == 2:
					# Carpa chiquita de exploradores.
					l.draw_colored_polygon(PackedVector2Array([base + Vector2(-50, 0), base + Vector2(0, -70), base + Vector2(50, 0)]), _con_tinte(Color("#FFB86B"), tinte))
				else:
					l.draw_rect(Rect2(base + Vector2(-8, -60), Vector2(16, 60)), _con_tinte(Color("#8A5A2B"), tinte))
					for q in 3:
						l.draw_colored_polygon(PackedVector2Array([base + Vector2(-46 + q * 6, -40 - q * 34), base + Vector2(0, -100 - q * 34), base + Vector2(46 - q * 6, -40 - q * 34)]), color.darkened(q * 0.05))
			"laguna":
				l.draw_rect(Rect2(base + Vector2(-150, -26), Vector2(300, 26)), _con_tinte(Color("#7FC4F0"), tinte))
				for q in 4:
					l.draw_line(base + Vector2(-60 + q * 12, 0), base + Vector2(-64 + q * 12, -70 - (q % 2) * 20), color, 5.0, true)
					l.draw_circle(base + Vector2(-64 + q * 12, -72 - (q % 2) * 20), 5.0, _con_tinte(Color("#A0663A"), tinte))
				l.draw_colored_polygon(elipse_pts(base + Vector2(60, -10), Vector2(30, 8)), _con_tinte(Color("#5DBB63"), tinte))
			"pradera":
				if v == 1:
					l.draw_line(base, base + Vector2(0, -110), _con_tinte(Color("#A0663A"), tinte), 12.0)
					l.draw_colored_polygon(elipse_pts(base + Vector2(0, -118), Vector2(90, 22)), _con_tinte(Color("#93B85A"), tinte))
				for q in 6:
					var mece := sin(t * 1.5 + q + k) * 6.0
					l.draw_line(base + Vector2(-70 + q * 26, 0), base + Vector2(-70 + q * 26 + mece, -40 - (q % 3) * 10), color, 6.0, true)
			"nidos":
				l.draw_rect(Rect2(base + Vector2(-26, -230), Vector2(52, 230)), _con_tinte(Color("#7A4E2B"), tinte))
				l.draw_circle(base + Vector2(0, -250), 90.0, color)
				var liana := PackedVector2Array()
				for q in 8:
					liana.append(base + Vector2(60 + sin(q * 0.8 + t) * 6.0, -260 + q * 22))
				l.draw_polyline(liana, _con_tinte(Color("#4FA857"), tinte), 5.0, true)
			"valle":
				if v == 3:
					# Huella fósil gigante en el barro.
					l.draw_colored_polygon(elipse_pts(base + Vector2(0, -6), Vector2(40, 10)), _con_tinte(Color("#9A7A5A"), tinte))
				for q in 5:
					var a := -PI / 2.0 + (q - 2) * 0.45
					l.draw_line(base, base + Vector2.from_angle(a) * 70.0, color, 10.0, true)
				l.draw_circle(base + Vector2(0, -10), 12.0, color.darkened(0.1))
		x += paso
		k += 1
