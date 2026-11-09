class_name DibujoCortar
extends RefCounted

## Arte vectorial PROVISIONAL por codigo del motor `cortar` (HE-114 trae el arte final del catalogo de Animalia).
## Caritas redondas y sonrientes de los animales del desfile, el calcetin a rayas, la almohadita de la siesta, la
## trompeta, el paraguas de hoja y la burbuja tornasol con su sellito de lupa. Siempre contentos (riesgo R7).

const CONTORNO := Color("#2B3350")

## id -> [color de la cara, color del detalle, orejas, rasgo]
## orejas: redondas | puntiagudas | caidas | largas | ninguna | cuernitos
## rasgo: hocico | pico | trompa | cuerno | manchas | rayas | melena | casco | antifaz | ninguno
const ANIMALES := {
	"vaca": ["#FFFFFF", "#3A3A3A", "cuernitos", "manchas"],
	"perro": ["#C98A4B", "#7A4A22", "caidas", "hocico"],
	"perrito": ["#E3B57A", "#8A5A2B", "caidas", "hocico"],
	"perrito_bombero": ["#E3B57A", "#E23B2E", "caidas", "casco"],
	"gato": ["#F2A541", "#B86A12", "puntiagudas", "rayas"],
	"gatito": ["#F7F2EA", "#F3A6C0", "puntiagudas", "ninguno"],
	"pato": ["#FFE04A", "#FF9A1F", "ninguna", "pico"],
	"caballo": ["#9C6B3E", "#4A2E16", "puntiagudas", "melena"],
	"pony": ["#F6B7D8", "#9B6BD6", "puntiagudas", "melena"],
	"gallina": ["#FFFFFF", "#E23B2E", "ninguna", "pico"],
	"flamenco": ["#FF8FB8", "#2B3350", "ninguna", "pico"],
	"pinguino": ["#3A4660", "#FF9A1F", "ninguna", "pico"],
	"jirafa": ["#FFC94A", "#B8742A", "cuernitos", "manchas"],
	"jirafita": ["#FFDA7A", "#C98A3A", "cuernitos", "manchas"],
	"cebra": ["#FFFFFF", "#2B3350", "puntiagudas", "rayas"],
	"elefante": ["#A9B6C8", "#7D8AA0", "redondas", "trompa"],
	"alpaca": ["#F4E6CF", "#C9A77C", "largas", "melena"],
	"huemul": ["#B58A5A", "#6E4A28", "puntiagudas", "cuerno"],
	"triceratops": ["#7ED07A", "#3D8C3A", "ninguna", "cuerno"],
	"braquiosaurio": ["#86C6E8", "#3F86B8", "ninguna", "manchas"],
	"hipopotamo": ["#B9A2D6", "#7E66A8", "redondas", "hocico"],
	"lobo_marino": ["#8C7A6A", "#4A3E34", "ninguna", "hocico"],
	"mono": ["#B07A4A", "#F2D2A8", "redondas", "antifaz"],
	"tucan": ["#2B3350", "#FF9A1F", "ninguna", "pico"],
	"loro": ["#3FCB5A", "#FFD23F", "ninguna", "pico"],
	"buho": ["#A67B52", "#F2D2A8", "puntiagudas", "antifaz"],
	"perezoso": ["#B8A48A", "#6E5A44", "ninguna", "antifaz"],
}


## Carita de `id` centrada en `c` con radio `r` (la cara entera mide 2r).
static func dibujar_animal(ci: CanvasItem, id: String, c: Vector2, r: float, ojos_cerrados := false) -> void:
	var datos: Array = ANIMALES.get(id, ["#E8C9A0", "#9A7A55", "redondas", "hocico"])
	var cara := Color(datos[0])
	var detalle := Color(datos[1])
	var orejas := str(datos[2])
	var rasgo := str(datos[3])
	var borde := maxf(1.5, r * 0.07)
	# Orejas (detras de la cara).
	match orejas:
		"redondas":
			for s in [-1.0, 1.0]:
				var p := c + Vector2(s * r * 0.72, -r * 0.7)
				ci.draw_circle(p, r * 0.36, CONTORNO)
				ci.draw_circle(p, r * 0.36 - borde, cara)
				ci.draw_circle(p, r * 0.18, detalle)
		"puntiagudas":
			for s in [-1.0, 1.0]:
				var tri := PackedVector2Array([c + Vector2(s * r * 0.25, -r * 0.8), c + Vector2(s * r * 0.85, -r * 1.15), c + Vector2(s * r * 0.85, -r * 0.35)])
				ci.draw_colored_polygon(tri, CONTORNO)
				ci.draw_colored_polygon(_achicar(tri, borde * 1.2), cara)
		"caidas", "largas":
			var largo := 0.9 if orejas == "caidas" else 1.2
			for s in [-1.0, 1.0]:
				var p := c + Vector2(s * r * 0.85, -r * 0.1)
				_elipse(ci, p, Vector2(r * 0.3, r * 0.55 * largo), CONTORNO)
				_elipse(ci, p, Vector2(r * 0.3 - borde, r * 0.55 * largo - borde), detalle)
		"cuernitos":
			for s in [-1.0, 1.0]:
				var base := c + Vector2(s * r * 0.45, -r * 0.8)
				ci.draw_line(base, base + Vector2(s * r * 0.12, -r * 0.35), CONTORNO, r * 0.16, true)
				ci.draw_circle(base + Vector2(s * r * 0.12, -r * 0.38), r * 0.13, detalle)
	# Cara.
	ci.draw_circle(c, r, CONTORNO)
	ci.draw_circle(c, r - borde, cara)
	match rasgo:
		"manchas":
			for k in 3:
				var ang := 0.9 + k * 2.1
				ci.draw_circle(c + Vector2(cos(ang), sin(ang)) * r * 0.55, r * (0.2 - k * 0.03), detalle)
		"rayas":
			for s in [-1.0, 1.0]:
				for k in 2:
					var a := c + Vector2(s * r * (0.95 - k * 0.12), -r * 0.2 + k * r * 0.3)
					ci.draw_line(a, a + Vector2(-s * r * 0.3, 0), detalle, r * 0.1, true)
			ci.draw_line(c + Vector2(0, -r * 0.95), c + Vector2(0, -r * 0.6), detalle, r * 0.12, true)
		"melena":
			for k in 5:
				ci.draw_circle(c + Vector2(-r * 0.4 + k * r * 0.2, -r * 0.9), r * 0.2, detalle)
		"antifaz":
			_elipse(ci, c + Vector2(0, -r * 0.05), Vector2(r * 0.7, r * 0.4), detalle)
		"casco":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.95, -r * 0.35), c + Vector2(-r * 0.6, -r * 1.05),
				c + Vector2(r * 0.6, -r * 1.05), c + Vector2(r * 0.95, -r * 0.35)]), detalle)
			ci.draw_circle(c + Vector2(0, -r * 0.72), r * 0.16, Color("#FFD23F"))
		"cuerno":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.12, -r * 0.55), c + Vector2(0, -r * 1.2), c + Vector2(r * 0.12, -r * 0.55)]), Color("#FFF4D6"))
	# Ojos.
	for s in [-1.0, 1.0]:
		var o := c + Vector2(s * r * 0.33, -r * 0.12)
		if ojos_cerrados:
			ci.draw_arc(o, r * 0.12, PI * 0.1, PI * 0.9, 8, CONTORNO, r * 0.07, true)
		else:
			ci.draw_circle(o, r * 0.13, CONTORNO)
			ci.draw_circle(o + Vector2(-r * 0.04, -r * 0.05), r * 0.045, Color.WHITE)
	# Mejillas.
	for s in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(s * r * 0.58, r * 0.2), r * 0.12, Color(1.0, 0.55, 0.65, 0.55))
	# Hocico, pico o trompa y la sonrisa.
	match rasgo:
		"pico":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.25, r * 0.12), c + Vector2(r * 0.25, r * 0.12), c + Vector2(0, r * 0.5)]), detalle)
		"trompa":
			ci.draw_line(c + Vector2(0, r * 0.1), c + Vector2(0, r * 0.7), detalle, r * 0.28, true)
			ci.draw_arc(c + Vector2(r * 0.15, r * 0.7), r * 0.15, 0.0, PI, 8, detalle, r * 0.22, true)
		_:
			if rasgo == "hocico" or orejas == "puntiagudas":
				_elipse(ci, c + Vector2(0, r * 0.32), Vector2(r * 0.38, r * 0.26), cara.lerp(Color.WHITE, 0.45))
			ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.09, CONTORNO)
	if rasgo != "trompa":
		ci.draw_arc(c + Vector2(0, r * 0.3), r * 0.22, PI * 0.15, PI * 0.85, 10, CONTORNO, r * 0.07, true)


## Burbuja tornasol (§11): relleno translucido, borde con colores de arcoiris, brillo y sellito de lupa.
static func dibujar_burbuja(ci: CanvasItem, c: Vector2, r: float, gris := false, alfa := 1.0) -> void:
	var relleno := Color(0.75, 0.92, 1.0, 0.22 * alfa) if not gris else Color(0.6, 0.62, 0.68, 0.45 * alfa)
	ci.draw_circle(c, r, relleno)
	if gris:
		# Rayas del calcetin (la burbuja "pesa": se lee distinta).
		for k in 5:
			var y := -r * 0.7 + k * r * 0.35
			var ancho := sqrt(maxf(0.0, r * r - y * y)) * 0.95
			ci.draw_line(c + Vector2(-ancho, y), c + Vector2(ancho, y), Color(0.35, 0.36, 0.42, 0.35 * alfa), r * 0.09, true)
		ci.draw_arc(c, r, 0.0, TAU, 40, Color(0.4, 0.4, 0.46, 0.9 * alfa), maxf(3.0, r * 0.06), true)
	else:
		var colores := [Color("#FF9ED6"), Color("#FFE38A"), Color("#8EE9FF"), Color("#B9A2FF")]
		for k in 4:
			ci.draw_arc(c, r - k * 1.5, TAU * k / 4.0, TAU * (k + 1) / 4.0 + 0.3, 14, Color(colores[k], 0.9 * alfa), maxf(3.0, r * 0.05), true)
	ci.draw_arc(c, r * 0.72, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.85 * alfa), maxf(3.0, r * 0.08), true)
	ci.draw_circle(c + Vector2(-r * 0.42, -r * 0.5), r * 0.07, Color(1, 1, 1, 0.9 * alfa))
	# Sellito de lupa (la "etiqueta de coleccion").
	var s := c + Vector2(r * 0.62, r * 0.6)
	ci.draw_circle(s, r * 0.13, Color(1, 1, 1, 0.8 * alfa))
	ci.draw_arc(s, r * 0.1, 0.0, TAU, 12, Color(CONTORNO, 0.8 * alfa), maxf(1.5, r * 0.03), true)
	ci.draw_line(s + Vector2(r * 0.07, r * 0.07), s + Vector2(r * 0.15, r * 0.15), Color(CONTORNO, 0.8 * alfa), maxf(1.5, r * 0.035), true)


## Calcetin a rayas del Coleccionauta.
static func dibujar_calcetin(ci: CanvasItem, c: Vector2, r: float, angulo := 0.0) -> void:
	var t := Transform2D(angulo, c)
	var forma := PackedVector2Array([Vector2(-r * 0.25, -r * 0.75), Vector2(r * 0.25, -r * 0.75), Vector2(r * 0.25, r * 0.2),
		Vector2(r * 0.7, r * 0.35), Vector2(r * 0.7, r * 0.7), Vector2(-r * 0.25, r * 0.7)])
	var pts := PackedVector2Array()
	for p in forma:
		pts.append(t * p)
	ci.draw_colored_polygon(pts, Color("#F4F0E8"))
	for k in 4:
		var y := -r * 0.6 + k * r * 0.32
		ci.draw_line(t * Vector2(-r * 0.25, y), t * Vector2(r * 0.25 if y < r * 0.2 else r * 0.7, y), Color("#E23B2E"), r * 0.12)
	pts.append(pts[0])
	ci.draw_polyline(pts, CONTORNO, maxf(2.0, r * 0.06), true)


## Almohadita de la siesta con tres "zzz" dibujadas (sin texto).
static func dibujar_almohada(ci: CanvasItem, c: Vector2, r: float) -> void:
	var rect := Rect2(c - Vector2(r * 0.6, r * 0.35), Vector2(r * 1.2, r * 0.7))
	ci.draw_rect(rect, Color("#B9A2FF"))
	ci.draw_rect(rect, CONTORNO, false, maxf(2.0, r * 0.05))
	for k in 3:
		var o := c + Vector2(r * (0.1 + k * 0.22), -r * (0.5 + k * 0.2))
		var e := r * (0.1 + k * 0.03)
		ci.draw_polyline(PackedVector2Array([o + Vector2(-e, -e), o + Vector2(e, -e), o + Vector2(-e, e), o + Vector2(e, e)]), CONTORNO, maxf(2.0, r * 0.05), true)


## Trompeta dorada.
static func dibujar_trompeta(ci: CanvasItem, c: Vector2, r: float) -> void:
	var oro := Color("#FFC94A")
	ci.draw_line(c + Vector2(-r * 0.6, 0), c + Vector2(r * 0.2, 0), oro, r * 0.18, true)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.15, -r * 0.12), c + Vector2(r * 0.65, -r * 0.45),
		c + Vector2(r * 0.65, r * 0.45), c + Vector2(r * 0.15, r * 0.12)]), oro)
	ci.draw_line(c + Vector2(r * 0.65, -r * 0.45), c + Vector2(r * 0.65, r * 0.45), CONTORNO, maxf(2.0, r * 0.05))
	for k in 3:
		ci.draw_circle(c + Vector2(-r * 0.3 + k * r * 0.18, -r * 0.18), r * 0.07, CONTORNO)


## Paraguas de hoja de los liberados.
static func dibujar_paraguas_hoja(ci: CanvasItem, c: Vector2, r: float) -> void:
	var hoja := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		hoja.append(c + Vector2(cos(a) * r, sin(a) * r * 0.6))
	ci.draw_colored_polygon(hoja, Color("#5BC45A"))
	ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.4), Color("#3D8C3A"), maxf(2.0, r * 0.08), true)


static func _elipse(ci: CanvasItem, c: Vector2, radios: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(c + Vector2(cos(a) * radios.x, sin(a) * radios.y))
	ci.draw_colored_polygon(pts, color)


static func _achicar(tri: PackedVector2Array, d: float) -> PackedVector2Array:
	var centro := (tri[0] + tri[1] + tri[2]) / 3.0
	var r := PackedVector2Array()
	for p in tri:
		r.append(p + (centro - p).normalized() * d)
	return r
