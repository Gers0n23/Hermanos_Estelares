class_name DibujoCaminos
extends RefCounted

## Dibujo vectorial procedural de «Cada quien a su casa» (arte PROVISIONAL hasta HE-114, hecho por código con
## `draw_*`; no usa imágenes). Todo se dibuja desde los parámetros del catálogo del nivel (`catalogo.<id>.dibujo`):
## el motor no conoce especies ni hábitats concretos (regla 7 de la ficha).
##
## - Animales: cabeza cartoon de frente (cabeza, orejas, hocico y extras), con ojos que miran, parpadeo, boca
##   feliz / "¡ey!" y saltito. Estilo del juego: contorno azul tinta grueso, colores planos, mejillas.
## - Casas y hábitats: casita, granero, establo, agua, árbol, montaña, cueva, nido, pasto, nube...
## - Huellas por animal: pata, pezuña, dino, pato, ave, plumita, burbuja, aleta.

const TINTA := Color("#2B3350")
const BLANCO := Color("#FFFFFF")
const MEJILLA := Color(1.0, 0.45, 0.55, 0.45)
const CONTORNO := 0.075  ## grosor del contorno, en fracción del radio


static func col(valor, defecto := Color.WHITE) -> Color:
	if valor is Color:
		return valor
	var s := str(valor)
	if s == "" or s == "<null>":
		return defecto
	return Color(s)


static func elipse_puntos(c: Vector2, rx: float, ry: float, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func elipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, rot := 0.0) -> void:
	ci.draw_colored_polygon(elipse_puntos(c, rx, ry, rot), color)


## Elipse con contorno de tinta (grosor `g`).
static func elipse_c(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, g: float, rot := 0.0) -> void:
	elipse(ci, c, rx + g, ry + g, TINTA, rot)
	elipse(ci, c, rx, ry, color, rot)


static func circulo_c(ci: CanvasItem, c: Vector2, r: float, color: Color, g: float) -> void:
	ci.draw_circle(c, r + g, TINTA)
	ci.draw_circle(c, r, color)


static func poligono_c(ci: CanvasItem, pts: PackedVector2Array, color: Color, g: float) -> void:
	ci.draw_colored_polygon(pts, color)
	var cerrado := pts.duplicate()
	cerrado.append(pts[0])
	ci.draw_polyline(cerrado, TINTA, g, true)


static func rect_redondo(ci: CanvasItem, r: Rect2, radio: float, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radio))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func rect_redondo_c(ci: CanvasItem, r: Rect2, radio: float, color: Color, borde: Color, g: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = borde
	sb.set_border_width_all(int(maxf(1.0, g)))
	sb.set_corner_radius_all(int(radio))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func estrella_puntos(c: Vector2, r: float, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var rr := r if k % 2 == 0 else r * 0.45
		var a := rot + PI * k / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts


# ---------------------------------------------------------------------------
# Animales
# ---------------------------------------------------------------------------

## Cabeza cartoon del animal centrada en `c`, cabe en un círculo de radio `r`.
## estado: {"t": s, "mira": Vector2 (-1..1), "boca": "feliz"|"ey"|"o"|"dormido", "orejas": 0..1 (paradas),
## "salto": 0..1, "mojado": bool}
static func animal(ci: CanvasItem, c: Vector2, r: float, d: Dictionary, estado := {}) -> void:
	var cuerpo := col(d.get("cuerpo", "#C98A4B"))
	var detalle := col(d.get("detalle", "#F6E3C6"))
	var oscuro := col(d.get("oscuro", "#7A4A26"))
	var forma := str(d.get("cabeza", "redonda"))
	var orejas := str(d.get("orejas", "ninguna"))
	var hocico := str(d.get("hocico", "nariz"))
	var extras: Array = d.get("extras", [])
	var t := float(estado.get("t", 0.0))
	var mira: Vector2 = estado.get("mira", Vector2.ZERO)
	var boca := str(estado.get("boca", "feliz"))
	var paradas := float(estado.get("orejas", 0.0))
	var g := r * CONTORNO
	c += Vector2(0, -r * 0.18 * float(estado.get("salto", 0.0)))
	# Medidas de la cabeza.
	var rx := r * 0.78
	var ry := r * 0.74
	match forma:
		"ancha":
			rx = r * 0.88
			ry = r * 0.7
		"alargada":
			rx = r * 0.6
			ry = r * 0.82
		"dino":
			rx = r * 0.84
			ry = r * 0.72
		"huevo":
			rx = r * 0.64
			ry = r * 0.84
	var cc := c + Vector2(0, r * 0.06)
	# --- detrás de la cabeza ---
	if "volante" in extras:
		var pts := PackedVector2Array()
		for k in 13:
			var a := PI + PI * k / 12.0
			var rr := r * (1.02 if k % 2 == 0 else 0.92)
			pts.append(cc + Vector2(cos(a) * rr * 1.05, sin(a) * rr * 0.95 - r * 0.05))
		pts.append(cc + Vector2(r * 0.9, r * 0.1))
		pts.append(cc + Vector2(-r * 0.9, r * 0.1))
		poligono_c(ci, pts, oscuro.lerp(cuerpo, 0.4), g)
		for k in 5:
			var a := PI + PI * (k + 0.5) / 5.0
			ci.draw_circle(cc + Vector2(cos(a), sin(a)) * r * 0.82, r * 0.07, detalle)
	if "vela" in extras:
		var pts := PackedVector2Array()
		for k in 9:
			var a := PI + PI * k / 8.0
			pts.append(cc + Vector2(cos(a) * r * 0.55, -r * 0.45 + sin(a) * r * 0.62))
		poligono_c(ci, pts, oscuro, g)
		for k in 3:
			ci.draw_line(cc + Vector2(-r * 0.3 + k * r * 0.3, -r * 0.5), cc + Vector2(-r * 0.3 + k * r * 0.3, -r * 0.95), detalle, g)
	if "melena" in extras:
		for k in 6:
			var a := -PI * 0.95 + k * PI * 0.19
			elipse_c(ci, cc + Vector2(cos(a) * rx * 0.75, sin(a) * ry * 0.95 - r * 0.05), r * 0.2, r * 0.26, oscuro, g, a)
	if "pelaje" in extras:
		for k in 12:
			var a := TAU * k / 12.0
			ci.draw_circle(cc + Vector2(cos(a) * rx, sin(a) * ry), r * 0.16 + g, TINTA)
		for k in 12:
			var a := TAU * k / 12.0
			ci.draw_circle(cc + Vector2(cos(a) * rx, sin(a) * ry), r * 0.16, cuerpo.darkened(0.12))
	if "caparazon" in extras:
		elipse_c(ci, cc + Vector2(0, r * 0.35), r * 0.95, r * 0.55, oscuro, g)
		for k in 3:
			elipse(ci, cc + Vector2(-r * 0.5 + k * r * 0.5, r * 0.5), r * 0.18, r * 0.12, oscuro.lightened(0.25))
	if "golilla" in extras:
		elipse_c(ci, cc + Vector2(0, r * 0.62), r * 0.92, r * 0.38, Color("#2B2B2B"), g)
	if "chorro" in extras:
		var bal := sin(t * 3.0) * r * 0.05
		for k in 3:
			var a := -PI / 2 + (k - 1) * 0.5
			ci.draw_line(cc + Vector2(0, -ry), cc + Vector2(0, -ry) + Vector2(cos(a), sin(a)) * r * 0.5 + Vector2(bal, 0), Color("#8FD0FF"), g * 1.6)
			ci.draw_circle(cc + Vector2(0, -ry) + Vector2(cos(a), sin(a)) * r * 0.55 + Vector2(bal, 0), r * 0.08, Color("#8FD0FF"))
	_orejas(ci, cc, rx, ry, r, orejas, cuerpo, detalle, oscuro, paradas, g, t)
	if "casco_bombero" in extras:
		pass
	# --- cabeza ---
	if forma == "huevo":
		var pts := PackedVector2Array()
		for k in 32:
			var a := TAU * k / 32.0
			var s := sin(a)
			pts.append(cc + Vector2(cos(a) * rx * (1.0 - 0.12 * s), s * ry))
		ci.draw_colored_polygon(_inflar(pts, cc, g), TINTA)
		ci.draw_colored_polygon(pts, cuerpo)
	else:
		elipse_c(ci, cc, rx, ry, cuerpo, g)
	# --- marcas en la cara ---
	if "manchas" in extras:
		var pos := [Vector2(-0.45, -0.35), Vector2(0.5, -0.15), Vector2(-0.2, 0.42), Vector2(0.35, 0.45)]
		for k in pos.size():
			var p: Vector2 = pos[k]
			elipse(ci, cc + Vector2(p.x * rx, p.y * ry), r * 0.13, r * 0.1, oscuro, k * 0.7)
	if "rayas" in extras:
		for k in 3:
			var x := (k - 1) * rx * 0.28
			ci.draw_line(cc + Vector2(x, -ry * 0.98), cc + Vector2(x * 0.8, -ry * 0.62), oscuro, g * 1.4)
		for s in [-1.0, 1.0]:
			ci.draw_line(cc + Vector2(s * rx * 0.98, -r * 0.05), cc + Vector2(s * rx * 0.7, 0), oscuro, g * 1.4)
			ci.draw_line(cc + Vector2(s * rx * 0.95, r * 0.15), cc + Vector2(s * rx * 0.7, r * 0.15), oscuro, g * 1.4)
	if "cara_blanca" in extras:
		elipse(ci, cc + Vector2(-rx * 0.3, -r * 0.02), r * 0.32, r * 0.4, detalle)
		elipse(ci, cc + Vector2(rx * 0.3, -r * 0.02), r * 0.32, r * 0.4, detalle)
		elipse(ci, cc + Vector2(0, r * 0.3), r * 0.48, r * 0.3, detalle)
	if "cara_mono" in extras:
		ci.draw_circle(cc + Vector2(-r * 0.22, -r * 0.08), r * 0.28, detalle)
		ci.draw_circle(cc + Vector2(r * 0.22, -r * 0.08), r * 0.28, detalle)
		elipse(ci, cc + Vector2(0, r * 0.25), r * 0.45, r * 0.3, detalle)
	if "mejilla_blanca" in extras:
		elipse(ci, cc + Vector2(-rx * 0.45, r * 0.12), r * 0.24, r * 0.3, BLANCO)
		elipse(ci, cc + Vector2(rx * 0.45, r * 0.12), r * 0.24, r * 0.3, BLANCO)
	if "mancha_blanca" in extras:
		elipse(ci, cc + Vector2(0, r * 0.15), r * 0.3, ry * 0.85, detalle)
	if "cara_gris" in extras:
		elipse(ci, cc + Vector2(0, r * 0.25), rx * 0.75, ry * 0.65, oscuro.lightened(0.35))
	if "mancha_ojo" in extras:
		elipse(ci, cc + Vector2(rx * 0.32, -r * 0.1), r * 0.24, r * 0.22, oscuro)
	if "antifaz" in extras:
		elipse(ci, cc + Vector2(-rx * 0.34, -r * 0.08), r * 0.22, r * 0.18, oscuro, 0.3)
		elipse(ci, cc + Vector2(rx * 0.34, -r * 0.08), r * 0.22, r * 0.18, oscuro, -0.3)
	if "antifaz_panda" in extras:
		elipse(ci, cc + Vector2(-rx * 0.34, -r * 0.05), r * 0.17, r * 0.24, oscuro, 0.5)
		elipse(ci, cc + Vector2(rx * 0.34, -r * 0.05), r * 0.17, r * 0.24, oscuro, -0.5)
	if "grieta" in extras:
		var pts := PackedVector2Array([cc + Vector2(-rx * 0.8, -r * 0.3), cc + Vector2(-rx * 0.4, -r * 0.45), cc + Vector2(-rx * 0.1, -r * 0.28),
			cc + Vector2(rx * 0.25, -r * 0.48), cc + Vector2(rx * 0.55, -r * 0.3), cc + Vector2(rx * 0.85, -r * 0.42)])
		ci.draw_polyline(pts, TINTA, g, true)
	# --- arriba de la cabeza ---
	if "cuernos" in extras:
		for s in [-1.0, 1.0]:
			var base := cc + Vector2(s * rx * 0.5, -ry * 0.85)
			var pts := PackedVector2Array([base + Vector2(-r * 0.08, 0), base + Vector2(s * r * 0.2, -r * 0.28), base + Vector2(r * 0.08, 0)])
			poligono_c(ci, pts, Color("#F2E6C8"), g * 0.8)
	if "cuernitos" in extras:
		for s in [-1.0, 1.0]:
			var base := cc + Vector2(s * rx * 0.35, -ry * 0.9)
			poligono_c(ci, PackedVector2Array([base + Vector2(-r * 0.07, r * 0.04), base + Vector2(0, -r * 0.2), base + Vector2(r * 0.07, r * 0.04)]), oscuro.lightened(0.3), g * 0.7)
	if "astas" in extras:
		for s in [-1.0, 1.0]:
			var base := cc + Vector2(s * rx * 0.4, -ry * 0.85)
			var punta := base + Vector2(s * r * 0.35, -r * 0.45)
			ci.draw_line(base, punta, TINTA, g * 3.2)
			ci.draw_line(base, punta, oscuro.lightened(0.45), g * 1.8)
			var rama := base.lerp(punta, 0.5)
			ci.draw_line(rama, rama + Vector2(-s * r * 0.1, -r * 0.25), TINTA, g * 3.0)
			ci.draw_line(rama, rama + Vector2(-s * r * 0.1, -r * 0.25), oscuro.lightened(0.45), g * 1.6)
	if "osiconos" in extras:
		for s in [-1.0, 1.0]:
			var base := cc + Vector2(s * rx * 0.3, -ry * 0.85)
			var punta := base + Vector2(s * r * 0.05, -r * 0.3)
			ci.draw_line(base, punta, TINTA, g * 3.0)
			ci.draw_line(base, punta, cuerpo, g * 1.6)
			circulo_c(ci, punta, r * 0.08, oscuro, g * 0.7)
	if "cresta" in extras:
		for k in 3:
			circulo_c(ci, cc + Vector2((k - 1) * r * 0.16, -ry - r * 0.06 - (0.06 if k == 1 else 0.0) * r), r * 0.11, oscuro, g * 0.7)
	if "penacho" in extras:
		for k in 3:
			var a := -PI / 2 + (k - 1) * 0.45
			var b := cc + Vector2(0, -ry * 0.9)
			ci.draw_line(b, b + Vector2(cos(a), sin(a)) * r * 0.24, TINTA, g * 1.2)
	if "copete" in extras:
		for k in 5:
			circulo_c(ci, cc + Vector2((k - 2) * r * 0.14, -ry * 0.95 - absf(k - 2) * -r * 0.03), r * 0.13, detalle, g * 0.6)
	if "flequillo" in extras:
		var pts := PackedVector2Array([cc + Vector2(-r * 0.22, -ry * 0.95), cc + Vector2(r * 0.18, -ry * 1.05), cc + Vector2(r * 0.05, -ry * 0.55), cc + Vector2(-r * 0.12, -ry * 0.62)])
		poligono_c(ci, pts, oscuro, g * 0.7)
	if "cuernos_tri" in extras:
		for s in [-1.0, 1.0]:
			var base := cc + Vector2(s * rx * 0.38, -ry * 0.6)
			poligono_c(ci, PackedVector2Array([base + Vector2(-r * 0.07, 0), base + Vector2(s * r * 0.06, -r * 0.42), base + Vector2(r * 0.07, 0)]), Color("#FFF4DE"), g * 0.7)
	if "casco_bombero" in extras:
		var top := cc + Vector2(0, -ry * 0.62)
		var pts := PackedVector2Array()
		for k in 15:
			var a := PI + PI * k / 14.0
			pts.append(top + Vector2(cos(a) * rx * 0.85, sin(a) * r * 0.5))
		poligono_c(ci, pts, Color("#E8434B"), g)
		elipse_c(ci, top + Vector2(0, 0), rx * 1.05, r * 0.1, Color("#E8434B"), g * 0.7)
		poligono_c(ci, estrella_puntos(top + Vector2(0, -r * 0.24), r * 0.14), Color("#FFD84A"), g * 0.5)
	if "lazo" in extras:
		var b := cc + Vector2(rx * 0.55, -ry * 0.75)
		poligono_c(ci, PackedVector2Array([b, b + Vector2(-r * 0.22, -r * 0.12), b + Vector2(-r * 0.22, r * 0.12)]), Color("#FF7EB6"), g * 0.6)
		poligono_c(ci, PackedVector2Array([b, b + Vector2(r * 0.22, -r * 0.12), b + Vector2(r * 0.22, r * 0.12)]), Color("#FF7EB6"), g * 0.6)
		circulo_c(ci, b, r * 0.06, Color("#FF7EB6"), g * 0.5)
	if "estrellas" in extras:
		for k in 3:
			var p := cc + Vector2((k - 1) * r * 0.5, -ry * 0.9 + sin(t * 4.0 + k) * r * 0.05)
			poligono_c(ci, estrella_puntos(p, r * 0.12, t + k), Color("#FFD84A"), g * 0.4)
	# --- ojos ---
	var ojo_y := -r * 0.1
	var sep := rx * 0.36
	if forma == "alargada":
		ojo_y = -r * 0.24
		sep = rx * 0.48
	if forma == "dino":
		ojo_y = -r * 0.22
	var tam_ojo := r * 0.12
	if "ojos_grandes" in extras:
		tam_ojo = r * 0.16
		for s in [-1.0, 1.0]:
			circulo_c(ci, cc + Vector2(s * sep, ojo_y), r * 0.24, detalle, g * 0.6)
	var parpadeo := fmod(t + float(hash(str(d.get("cuerpo", "")))) * 0.001, 3.7) < 0.12
	for s in [-1.0, 1.0]:
		var p := cc + Vector2(s * sep, ojo_y)
		if boca == "dormido" or parpadeo:
			ci.draw_arc(p + Vector2(0, -tam_ojo * 0.2), tam_ojo, 0.2, PI - 0.2, 10, TINTA, g * 1.1, true)
		else:
			ci.draw_circle(p, tam_ojo * 1.12, TINTA)
			var brillo := p + mira * tam_ojo * 0.3 + Vector2(-tam_ojo * 0.32, -tam_ojo * 0.38)
			ci.draw_circle(brillo, tam_ojo * 0.38, BLANCO)
	# --- hocico y boca ---
	var boca_c := cc + Vector2(0, r * 0.3)
	match hocico:
		"nariz":
			elipse(ci, cc + Vector2(0, r * 0.26), r * 0.32, r * 0.22, detalle)
			elipse(ci, cc + Vector2(0, r * 0.15), r * 0.11, r * 0.08, TINTA)
			boca_c = cc + Vector2(0, r * 0.32)
		"nariz_grande":
			elipse(ci, cc + Vector2(0, r * 0.12), r * 0.17, r * 0.22, TINTA)
			boca_c = cc + Vector2(0, r * 0.42)
		"morro":
			elipse_c(ci, cc + Vector2(0, ry * 0.52), rx * 0.78, r * 0.3, detalle, g * 0.6)
			ci.draw_circle(cc + Vector2(-rx * 0.28, ry * 0.45), r * 0.055, TINTA)
			ci.draw_circle(cc + Vector2(rx * 0.28, ry * 0.45), r * 0.055, TINTA)
			boca_c = cc + Vector2(0, ry * 0.66)
		"pico":
			poligono_c(ci, PackedVector2Array([cc + Vector2(-r * 0.16, r * 0.08), cc + Vector2(r * 0.16, r * 0.08), cc + Vector2(0, r * 0.36)]), detalle, g * 0.7)
			boca_c = Vector2.INF
		"pico_pato":
			elipse_c(ci, cc + Vector2(0, r * 0.3), r * 0.34, r * 0.16, detalle, g * 0.7)
			ci.draw_line(cc + Vector2(-r * 0.22, r * 0.3), cc + Vector2(r * 0.22, r * 0.3), TINTA, g * 0.6)
			boca_c = Vector2.INF
		"pico_curvo":
			var pts := PackedVector2Array([cc + Vector2(-r * 0.16, r * 0.04), cc + Vector2(r * 0.18, r * 0.04), cc + Vector2(r * 0.16, r * 0.28), cc + Vector2(r * 0.02, r * 0.42), cc + Vector2(-r * 0.04, r * 0.3)])
			poligono_c(ci, pts, detalle, g * 0.7)
			ci.draw_circle(cc + Vector2(r * 0.03, r * 0.38), r * 0.05, oscuro)
			boca_c = Vector2.INF
		"pico_tucan":
			var pts := PackedVector2Array([cc + Vector2(-r * 0.1, r * 0.0), cc + Vector2(r * 0.15, -r * 0.02), cc + Vector2(r * 0.95, r * 0.25), cc + Vector2(r * 0.85, r * 0.42), cc + Vector2(-r * 0.05, r * 0.3)])
			poligono_c(ci, pts, oscuro, g * 0.7)
			ci.draw_circle(cc + Vector2(r * 0.85, r * 0.33), r * 0.07, Color("#2B2B2B"))
			boca_c = Vector2.INF
		"trompa":
			var pts := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				pts.append(cc + Vector2(sin(u * 2.4 + t * 1.5) * r * 0.12 * u, r * 0.05 + u * r * 0.75))
			ci.draw_polyline(pts, TINTA, r * 0.32, true)
			ci.draw_polyline(pts, cuerpo, r * 0.22, true)
			boca_c = cc + Vector2(-r * 0.3, r * 0.42)
		"dino":
			ci.draw_circle(cc + Vector2(-r * 0.12, r * 0.08), r * 0.045, TINTA)
			ci.draw_circle(cc + Vector2(r * 0.12, r * 0.08), r * 0.045, TINTA)
			boca_c = cc + Vector2(0, r * 0.3)
		"pico_dino":
			poligono_c(ci, PackedVector2Array([cc + Vector2(-r * 0.2, r * 0.18), cc + Vector2(r * 0.2, r * 0.18), cc + Vector2(0, r * 0.48)]), detalle, g * 0.7)
			poligono_c(ci, PackedVector2Array([cc + Vector2(-r * 0.06, r * 0.06), cc + Vector2(r * 0.06, r * 0.06), cc + Vector2(0, -r * 0.22)]), Color("#FFF4DE"), g * 0.6)
			boca_c = Vector2.INF
		"sonrisa":
			boca_c = cc + Vector2(0, r * 0.25)
		"ninguna":
			boca_c = cc + Vector2(0, r * 0.25)
	if "carúncula" in extras:
		ci.draw_circle(cc + Vector2(0, r * 0.06), r * 0.08, oscuro)
	if "antifaz_pico" in extras:
		elipse(ci, cc + Vector2(0, r * 0.05), r * 0.2, r * 0.07, TINTA)
	if boca_c != Vector2.INF:
		var ancho_boca := r * (0.3 if hocico in ["dino", "sonrisa"] else 0.16)
		match boca:
			"ey", "o":
				circulo_c(ci, boca_c + Vector2(0, r * 0.04), r * 0.08, Color("#C2394A"), g * 0.6)
			"dormido":
				ci.draw_line(boca_c + Vector2(-ancho_boca * 0.5, 0), boca_c + Vector2(ancho_boca * 0.5, 0), TINTA, g)
			_:
				ci.draw_arc(boca_c + Vector2(0, -ancho_boca * 0.45), ancho_boca, 0.35, PI - 0.35, 12, TINTA, g * 1.1, true)
		if "dientes" in extras:
			ci.draw_rect(Rect2(boca_c + Vector2(-r * 0.08, r * 0.04), Vector2(r * 0.16, r * 0.12)), BLANCO)
			ci.draw_rect(Rect2(boca_c + Vector2(-r * 0.08, r * 0.04), Vector2(r * 0.16, r * 0.12)), TINTA, false, g * 0.5)
		if "dientes_dino" in extras:
			for k in 4:
				var x := -ancho_boca * 0.6 + k * ancho_boca * 0.4
				ci.draw_colored_polygon(PackedVector2Array([boca_c + Vector2(x - r * 0.04, r * 0.02), boca_c + Vector2(x + r * 0.04, r * 0.02), boca_c + Vector2(x, r * 0.1)]), BLANCO)
	if "bigotes" in extras:
		for s in [-1.0, 1.0]:
			for k in 2:
				var a := cc + Vector2(s * r * 0.3, r * 0.22 + k * r * 0.08)
				ci.draw_line(a, a + Vector2(s * r * 0.36, -r * 0.05 + k * r * 0.1), TINTA, g * 0.5)
	if "mejillas" in extras or forma == "huevo":
		ci.draw_circle(cc + Vector2(-rx * 0.62, r * 0.14), r * 0.11, MEJILLA)
		ci.draw_circle(cc + Vector2(rx * 0.62, r * 0.14), r * 0.11, MEJILLA)
	if "pecho_rojo" in extras:
		elipse(ci, cc + Vector2(0, ry * 0.8), r * 0.3, r * 0.12, oscuro)
	if bool(estado.get("mojado", false)):
		for k in 4:
			var p := cc + Vector2(-rx * 0.6 + k * rx * 0.4, -ry * 0.3 + fmod(t * 0.7 + k * 0.3, 1.0) * ry)
			elipse(ci, p, r * 0.05, r * 0.08, Color(0.55, 0.8, 1.0, 0.85))


static func _inflar(pts: PackedVector2Array, c: Vector2, g: float) -> PackedVector2Array:
	var r := PackedVector2Array()
	for p in pts:
		r.append(p + (p - c).normalized() * g)
	return r


static func _orejas(ci: CanvasItem, cc: Vector2, rx: float, ry: float, r: float, tipo: String, cuerpo: Color,
		detalle: Color, oscuro: Color, paradas: float, g: float, t: float) -> void:
	var levanta := -r * 0.08 * paradas
	match tipo:
		"punta":
			for s in [-1.0, 1.0]:
				var b := cc + Vector2(s * rx * 0.55, -ry * 0.55 + levanta)
				var pts := PackedVector2Array([b + Vector2(-s * r * 0.2, r * 0.05), b + Vector2(s * r * 0.12, -r * 0.48), b + Vector2(s * r * 0.3, r * 0.1)])
				poligono_c(ci, pts, cuerpo, g)
				var inner := PackedVector2Array([b + Vector2(-s * r * 0.06, 0), b + Vector2(s * r * 0.1, -r * 0.3), b + Vector2(s * r * 0.18, r * 0.04)])
				ci.draw_colored_polygon(inner, detalle)
		"caballo":
			for s in [-1.0, 1.0]:
				var b := cc + Vector2(s * rx * 0.45, -ry * 0.75 + levanta)
				var pts := PackedVector2Array([b + Vector2(-r * 0.1, r * 0.05), b + Vector2(s * r * 0.08, -r * 0.4), b + Vector2(r * 0.12, r * 0.05)])
				poligono_c(ci, pts, cuerpo, g)
		"redondas", "redondas_oscuras":
			var color := oscuro if tipo == "redondas_oscuras" else cuerpo
			for s in [-1.0, 1.0]:
				var p := cc + Vector2(s * rx * 0.72, -ry * 0.72 + levanta)
				circulo_c(ci, p, r * 0.24, color, g)
				if tipo == "redondas":
					ci.draw_circle(p, r * 0.13, detalle)
		"pequenas":
			for s in [-1.0, 1.0]:
				circulo_c(ci, cc + Vector2(s * rx * 0.7, -ry * 0.68 + levanta), r * 0.13, cuerpo, g)
		"grandes":
			for s in [-1.0, 1.0]:
				var p := cc + Vector2(s * rx * 0.95, -ry * 0.25 + levanta)
				circulo_c(ci, p, r * 0.38, cuerpo, g)
				ci.draw_circle(p, r * 0.24, detalle)
		"caidas":
			for s in [-1.0, 1.0]:
				var balanceo := sin(t * 2.2 + s) * 0.08
				elipse_c(ci, cc + Vector2(s * rx * 0.92, -ry * 0.05 + levanta), r * 0.2, r * 0.42, oscuro, g, s * (0.35 + balanceo) - s * paradas * 0.4)
		"largas":
			for s in [-1.0, 1.0]:
				var p := cc + Vector2(s * rx * 0.38, -ry * 1.1 + levanta)
				elipse_c(ci, p, r * 0.15, r * 0.45, cuerpo, g, s * 0.15)
				elipse(ci, p, r * 0.07, r * 0.32, detalle, s * 0.15)
		"laterales":
			for s in [-1.0, 1.0]:
				var p := cc + Vector2(s * rx * 1.05, -ry * 0.35 + levanta)
				elipse_c(ci, p, r * 0.26, r * 0.12, cuerpo, g, s * -0.3)
				elipse(ci, p, r * 0.15, r * 0.06, detalle, s * -0.3)


## Un "cojincito" redondo del color del par bajo el animal (el color une al animal con su camino).
static func base_animal(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.08), r * 0.98, Color(0, 0, 0, 0.12))
	circulo_c(ci, c, r * 0.94, color.lightened(0.55), r * 0.06)
	ci.draw_arc(c, r * 0.8, 0, TAU, 40, color, r * 0.12, true)


# ---------------------------------------------------------------------------
# Casas y hábitats
# ---------------------------------------------------------------------------

## Casa centrada en `c` (cabe en un cuadrado de lado ~2r). `color_par`: Color del par (casas de color) o
## Color(0,0,0,0) (casas neutras de hábitat). `abierta` 0-1: la puertita se entreabre / el hábitat "llama".
static func casa(ci: CanvasItem, c: Vector2, r: float, d: Dictionary, color_par: Color, abierta := 0.0, t := 0.0) -> void:
	var g := r * CONTORNO
	var tipo := str(d.get("tipo", "casita"))
	var color := col(d.get("color", "#E8434B"))
	var color2 := col(d.get("color2", "#F6E3C6"))
	var variante := str(d.get("variante", ""))
	var con_color := color_par.a > 0.0
	# Placa: del color del par (casas de color) o crema (hábitats).
	var placa := Rect2(c - Vector2(r, r) * 0.98, Vector2(r, r) * 1.96)
	if con_color:
		rect_redondo_c(ci, placa, r * 0.3, color_par.lightened(0.6), color_par, r * 0.12)
	else:
		rect_redondo_c(ci, placa, r * 0.3, Color("#FFF8EE"), Color("#C9B79A"), r * 0.06)
	if abierta > 0.0:
		ci.draw_circle(c, r * (0.95 + 0.08 * abierta), Color(1.0, 0.95, 0.6, 0.35 * abierta))
	var techo := color_par if con_color and tipo in ["casita", "granero", "establo", "gallinero", "castillito", "carpa", "cuartel"] else color
	match tipo:
		"casita", "establo", "gallinero", "cuartel", "granero":
			var ancho := r * (1.2 if tipo != "granero" else 1.3)
			var alto := r * 0.75
			var base := c + Vector2(0, r * 0.62)
			var cuerpo := Rect2(base - Vector2(ancho / 2.0, alto), Vector2(ancho, alto))
			var pared := color2 if tipo != "granero" else color
			if tipo == "cuartel":
				pared = color
			ci.draw_rect(cuerpo.grow(g), TINTA)
			ci.draw_rect(cuerpo, pared)
			if variante == "heno":
				for k in 4:
					ci.draw_line(cuerpo.position + Vector2(0, k * alto / 4.0 + 4), cuerpo.position + Vector2(ancho, k * alto / 4.0 + 4), color.darkened(0.15), g * 0.6)
			var techo_pts := PackedVector2Array([cuerpo.position + Vector2(-r * 0.18, 0), cuerpo.position + Vector2(ancho / 2.0, -r * 0.6), cuerpo.position + Vector2(ancho + r * 0.18, 0)])
			if tipo == "granero":
				techo_pts = PackedVector2Array([cuerpo.position + Vector2(-r * 0.12, 0), cuerpo.position + Vector2(ancho * 0.2, -r * 0.42), cuerpo.position + Vector2(ancho * 0.8, -r * 0.42), cuerpo.position + Vector2(ancho + r * 0.12, 0)])
			poligono_c(ci, techo_pts, techo.darkened(0.05) if tipo != "granero" else Color("#6E4A3A"), g)
			# puerta
			var pw := ancho * 0.36
			var ph := alto * 0.68
			var puerta := Rect2(base - Vector2(pw / 2.0, ph), Vector2(pw, ph))
			match tipo:
				"granero":
					ci.draw_rect(puerta, BLANCO)
					ci.draw_line(puerta.position, puerta.end, color, g)
					ci.draw_line(puerta.position + Vector2(pw, 0), puerta.position + Vector2(0, ph), color, g)
				"cuartel":
					ci.draw_rect(puerta.grow_individual(pw * 0.3, 0, pw * 0.3, 0), color2)
					for k in 3:
						ci.draw_line(puerta.position + Vector2(-pw * 0.3, ph * (k + 1) / 4.0), puerta.position + Vector2(pw * 1.3, ph * (k + 1) / 4.0), color2.darkened(0.25), g * 0.5)
					circulo_c(ci, cuerpo.position + Vector2(ancho / 2.0, -r * 0.2), r * 0.11, Color("#FFD84A"), g * 0.5)
				"establo":
					ci.draw_rect(puerta, color.darkened(0.2))
					ci.draw_line(puerta.position + Vector2(0, ph / 2.0), puerta.position + Vector2(pw, ph / 2.0), color2, g)
				_:
					ci.draw_circle(puerta.position + Vector2(pw / 2.0, pw / 2.0), pw / 2.0, TINTA)
					ci.draw_rect(Rect2(puerta.position + Vector2(0, pw / 2.0), Vector2(pw, ph - pw / 2.0)), TINTA)
			if abierta > 0.0:
				ci.draw_rect(Rect2(puerta.position, Vector2(pw * 0.5 * abierta, ph)), Color(1, 0.9, 0.5, 0.6))
			if tipo == "gallinero":
				ci.draw_line(base + Vector2(ancho * 0.3, 0), base + Vector2(ancho * 0.7, r * 0.3), color.darkened(0.3), g * 1.5)
		"carpa":
			var pts := PackedVector2Array([c + Vector2(-r * 0.8, r * 0.62), c + Vector2(0, -r * 0.62), c + Vector2(r * 0.8, r * 0.62)])
			poligono_c(ci, pts, techo, g)
			ci.draw_line(c + Vector2(-r * 0.4, r * 0.62), c + Vector2(0, -r * 0.62), color2, g * 1.6)
			ci.draw_line(c + Vector2(r * 0.4, r * 0.62), c + Vector2(0, -r * 0.62), color2, g * 1.6)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.2, r * 0.62), c + Vector2(0, r * 0.05), c + Vector2(r * 0.2, r * 0.62)]), TINTA)
			ci.draw_line(c + Vector2(0, -r * 0.62), c + Vector2(0, -r * 0.88), TINTA, g)
			poligono_c(ci, estrella_puntos(c + Vector2(0, -r * 0.9), r * 0.13, t), Color("#FFD84A"), g * 0.5)
		"castillito":
			var cuerpo := Rect2(c + Vector2(-r * 0.62, -r * 0.3), Vector2(r * 1.24, r * 0.92))
			ci.draw_rect(cuerpo.grow(g), TINTA)
			ci.draw_rect(cuerpo, color)
			for k in 4:
				var almena := Rect2(cuerpo.position + Vector2(k * r * 0.34, -r * 0.2), Vector2(r * 0.2, r * 0.22))
				ci.draw_rect(almena.grow(g * 0.7), TINTA)
				ci.draw_rect(almena, color)
			ci.draw_circle(c + Vector2(0, r * 0.35), r * 0.22, TINTA)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.22, r * 0.35), Vector2(r * 0.44, r * 0.27)), TINTA)
			ci.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(0, -r * 0.85), TINTA, g)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.85), c + Vector2(r * 0.3, -r * 0.75), c + Vector2(0, -r * 0.65)]), techo)
		"agua":
			_agua(ci, c, r, color, color2, variante, g, t)
		"nenufar":
			elipse_c(ci, c + Vector2(0, r * 0.25), r * 0.85, r * 0.45, Color("#5CC8F0"), g)
			var pts := PackedVector2Array()
			for k in 25:
				var a := 0.35 + (TAU - 0.7) * k / 24.0
				pts.append(c + Vector2(0, r * 0.2) + Vector2(cos(a) * r * 0.62, sin(a) * r * 0.3))
			pts.append(c + Vector2(0, r * 0.2))
			poligono_c(ci, pts, color, g * 0.8)
			for k in 6:
				var a := -PI / 2 + TAU * k / 6.0 + sin(t) * 0.05
				elipse_c(ci, c + Vector2(0, -r * 0.1) + Vector2(cos(a), sin(a)) * r * 0.2, r * 0.12, r * 0.2, color2, g * 0.5, a + PI / 2)
			ci.draw_circle(c + Vector2(0, -r * 0.1), r * 0.1, Color("#FFD84A"))
		"canasto", "cojin":
			if variante == "colgante":
				ci.draw_line(c + Vector2(-r * 0.6, 0), c + Vector2(0, -r * 0.9), TINTA, g)
				ci.draw_line(c + Vector2(r * 0.6, 0), c + Vector2(0, -r * 0.9), TINTA, g)
			if tipo == "cojin":
				elipse_c(ci, c + Vector2(0, r * 0.2), r * 0.82, r * 0.5, color, g)
				for s in [-1.0, 1.0]:
					circulo_c(ci, c + Vector2(s * r * 0.8, r * 0.05), r * 0.1, color2, g * 0.5)
				ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.06, color.darkened(0.3))
			else:
				var pts := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.05), c + Vector2(r * 0.8, -r * 0.05), c + Vector2(r * 0.6, r * 0.62), c + Vector2(-r * 0.6, r * 0.62)])
				poligono_c(ci, pts, color, g)
				for k in 4:
					ci.draw_line(c + Vector2(-r * 0.7 + k * r * 0.45, -r * 0.05), c + Vector2(-r * 0.55 + k * r * 0.38, r * 0.62), color.darkened(0.25), g * 0.6)
				elipse_c(ci, c + Vector2(0, -r * 0.08), r * 0.72, r * 0.18, color2, g * 0.6)
		"arbol":
			_arbol(ci, c, r, color, color2, variante, g, t)
		"bambu":
			for k in 3:
				var x := (k - 1) * r * 0.42
				var alto := r * (1.3 - absf(k - 1) * 0.25)
				var base := c + Vector2(x, r * 0.75)
				ci.draw_line(base, base + Vector2(0, -alto), TINTA, r * 0.24)
				ci.draw_line(base, base + Vector2(0, -alto), color, r * 0.15)
				for n in 3:
					ci.draw_line(base + Vector2(-r * 0.09, -alto * (n + 1) / 4.0), base + Vector2(r * 0.09, -alto * (n + 1) / 4.0), color2, g * 0.7)
				elipse_c(ci, base + Vector2(r * 0.18, -alto * 0.8), r * 0.18, r * 0.07, color2, g * 0.4, -0.5)
		"montana":
			_montana(ci, c, r, color, color2, variante, g, t)
		"hielo":
			elipse(ci, c + Vector2(0, r * 0.5), r * 0.92, r * 0.3, color2)
			var pts := PackedVector2Array([c + Vector2(-r * 0.7, r * 0.45), c + Vector2(-r * 0.45, -r * 0.35), c + Vector2(-r * 0.1, -r * 0.2), c + Vector2(r * 0.2, -r * 0.6), c + Vector2(r * 0.65, r * 0.45)])
			poligono_c(ci, pts, color, g)
			ci.draw_line(c + Vector2(r * 0.2, -r * 0.6), c + Vector2(r * 0.05, r * 0.4), color2.lightened(0.4), g)
		"cueva":
			_cueva(ci, c, r, color, color2, variante, g, abierta)
		"nido":
			if variante == "mama" and d.has("animal"):
				animal(ci, c + Vector2(0, -r * 0.3), r * 0.6, d["animal"], {"t": t})
			elipse_c(ci, c + Vector2(0, r * 0.38), r * 0.82, r * 0.35, color, g)
			for k in 5:
				ci.draw_arc(c + Vector2(0, r * 0.38), r * (0.25 + k * 0.12), 0.2, PI - 0.2, 10, color.darkened(0.25), g * 0.5)
			if variante != "mama":
				for k in 3:
					elipse_c(ci, c + Vector2((k - 1) * r * 0.3, r * 0.1), r * 0.13, r * 0.17, Color("#FFF4DE"), g * 0.5)
			if variante == "musgo":
				for k in 6:
					ci.draw_circle(c + Vector2(-r * 0.7 + k * r * 0.28, r * 0.15), r * 0.1, color2)
		"pasto":
			_pasto(ci, c, r, color, color2, variante, g, t)
		"arena":
			elipse_c(ci, c + Vector2(0, r * 0.3), r * 0.9, r * 0.5, color, g)
			if variante == "desierto":
				ci.draw_arc(c + Vector2(-r * 0.3, r * 0.6), r * 0.5, PI + 0.4, TAU - 0.4, 12, color.darkened(0.2), g)
				var cx := c + Vector2(r * 0.35, r * 0.1)
				ci.draw_line(cx + Vector2(0, r * 0.35), cx + Vector2(0, -r * 0.5), TINTA, r * 0.22)
				ci.draw_line(cx + Vector2(0, r * 0.35), cx + Vector2(0, -r * 0.5), color2, r * 0.14)
				ci.draw_line(cx + Vector2(0, -r * 0.1), cx + Vector2(-r * 0.22, -r * 0.1), color2, r * 0.1)
				ci.draw_line(cx + Vector2(-r * 0.22, -r * 0.1), cx + Vector2(-r * 0.22, -r * 0.3), color2, r * 0.1)
				ci.draw_circle(c + Vector2(-r * 0.5, -r * 0.55), r * 0.16, Color("#FFC83A"))
			else:
				elipse(ci, c + Vector2(r * 0.55, -r * 0.35), r * 0.35, r * 0.18, color2)
				circulo_c(ci, c + Vector2(-r * 0.3, r * 0.15), r * 0.18, Color("#FF7EB6"), g * 0.6)
				ci.draw_arc(c + Vector2(r * 0.25, r * 0.35), r * 0.12, PI, TAU, 8, Color("#FF8A3D"), g)
		"nube":
			for p in [Vector2(-0.45, 0.1), Vector2(0, -0.1), Vector2(0.45, 0.1), Vector2(-0.2, 0.25), Vector2(0.2, 0.25)]:
				ci.draw_circle(c + p * r, r * 0.38 + g, TINTA)
			for p in [Vector2(-0.45, 0.1), Vector2(0, -0.1), Vector2(0.45, 0.1), Vector2(-0.2, 0.25), Vector2(0.2, 0.25)]:
				ci.draw_circle(c + p * r, r * 0.38, color)
			for k in 4:
				var p := c + Vector2(-r * 0.6 + k * r * 0.4, -r * 0.55 + sin(t * 3.0 + k) * r * 0.06)
				poligono_c(ci, estrella_puntos(p, r * 0.13, t + k), color2, g * 0.4)
		"mama":
			if d.has("animal"):
				animal(ci, c + Vector2(0, -r * 0.05), r * 0.85, d["animal"], {"t": t})
			var corazon := c + Vector2(r * 0.6, -r * 0.6 + sin(t * 3.0) * r * 0.04)
			ci.draw_circle(corazon + Vector2(-r * 0.07, 0), r * 0.1, color2)
			ci.draw_circle(corazon + Vector2(r * 0.07, 0), r * 0.1, color2)
			ci.draw_colored_polygon(PackedVector2Array([corazon + Vector2(-r * 0.17, r * 0.03), corazon + Vector2(r * 0.17, r * 0.03), corazon + Vector2(0, r * 0.2)]), color2)
		"liana":
			ci.draw_line(c + Vector2(-r * 0.9, -r * 0.8), c + Vector2(r * 0.9, -r * 0.8), Color("#8A5A36"), r * 0.18)
			var pts := PackedVector2Array()
			for k in 10:
				var u := k / 9.0
				pts.append(c + Vector2(-r * 0.3 + sin(u * 5.0 + t) * r * 0.2, -r * 0.8 + u * r * 1.5))
			ci.draw_polyline(pts, TINTA, r * 0.16, true)
			ci.draw_polyline(pts, color2, r * 0.1, true)
			for k in 4:
				elipse_c(ci, pts[2 + k * 2] + Vector2(r * 0.15, 0), r * 0.16, r * 0.08, color, g * 0.4, 0.5)
		"represa":
			elipse_c(ci, c + Vector2(0, r * 0.45), r * 0.92, r * 0.3, color2, g)
			for k in 4:
				var y := r * 0.35 - k * r * 0.22
				var w := r * (1.4 - k * 0.25)
				var tronco := Rect2(c + Vector2(-w / 2.0, y - r * 0.1), Vector2(w, r * 0.2))
				rect_redondo_c(ci, tronco, r * 0.1, color, TINTA, g * 0.7)
				ci.draw_circle(tronco.position + Vector2(r * 0.1, r * 0.1), r * 0.06, color.lightened(0.3))
		_:
			circulo_c(ci, c, r * 0.6, color, g)


static func _agua(ci: CanvasItem, c: Vector2, r: float, color: Color, color2: Color, variante: String, g: float, t: float) -> void:
	match variante:
		"mar":
			rect_redondo_c(ci, Rect2(c - Vector2(r * 0.85, r * 0.6), Vector2(r * 1.7, r * 1.25)), r * 0.25, color, TINTA, g)
			for k in 3:
				var y := -r * 0.3 + k * r * 0.32
				var pts := PackedVector2Array()
				for n in 9:
					var x := -r * 0.7 + n * r * 0.175
					pts.append(c + Vector2(x, y + sin(n * 1.6 + t * 2.0 + k) * r * 0.05))
				ci.draw_polyline(pts, color2, g, true)
		"rio", "rio_bosque":
			var pts := PackedVector2Array()
			var pts2 := PackedVector2Array()
			for n in 11:
				var u := n / 10.0
				var x := -r * 0.85 + u * r * 1.7
				var y := sin(u * 4.0) * r * 0.22
				pts.append(c + Vector2(x, y - r * 0.28))
				pts2.append(c + Vector2(x, y + r * 0.28))
			pts2.reverse()
			var poly := pts.duplicate()
			poly.append_array(pts2)
			poligono_c(ci, poly, color, g)
			for n in 3:
				var x := -r * 0.5 + n * r * 0.5 + fmod(t * r * 0.3, r * 0.5)
				ci.draw_line(c + Vector2(x, sin((x / r + 0.85) / 1.7 * 4.0) * r * 0.22), c + Vector2(x + r * 0.15, sin((x / r + 1.0) / 1.7 * 4.0) * r * 0.22), BLANCO, g * 0.8)
			if variante == "rio_bosque":
				for s in [-1.0, 1.0]:
					var p := c + Vector2(s * r * 0.55, -r * 0.55)
					poligono_c(ci, PackedVector2Array([p + Vector2(-r * 0.2, r * 0.3), p + Vector2(0, -r * 0.3), p + Vector2(r * 0.2, r * 0.3)]), color2, g * 0.6)
			else:
				for s in [-1.0, 1.0]:
					elipse(ci, c + Vector2(s * r * 0.5, s * r * 0.6), r * 0.3, r * 0.12, color2)
		_:
			var borde := color2
			elipse_c(ci, c + Vector2(0, r * 0.15), r * 0.9, r * 0.62, borde, g)
			elipse(ci, c + Vector2(0, r * 0.18), r * 0.74, r * 0.48, color)
			match variante:
				"barro":
					for k in 3:
						var p := c + Vector2(-r * 0.3 + k * r * 0.3, r * 0.15 - fmod(t * 0.5 + k * 0.3, 1.0) * r * 0.2)
						ci.draw_arc(p, r * 0.07, 0, TAU, 10, color.lightened(0.3), g * 0.6)
				"salar":
					for k in 5:
						elipse(ci, c + Vector2(-r * 0.5 + k * r * 0.25, r * (0.05 if k % 2 == 0 else 0.3)), r * 0.1, r * 0.05, color2)
				"humedal", "bofedal":
					for k in 5:
						var x := -r * 0.6 + k * r * 0.3
						ci.draw_line(c + Vector2(x, r * 0.3), c + Vector2(x + r * 0.05, -r * 0.35), TINTA, g * 1.2)
						ci.draw_line(c + Vector2(x, r * 0.3), c + Vector2(x + r * 0.05, -r * 0.35), color2.darkened(0.2), g * 0.7)
						if variante == "humedal" and k % 2 == 0:
							elipse(ci, c + Vector2(x + r * 0.05, -r * 0.35), r * 0.05, r * 0.12, Color("#8A5A36"))
				_:
					for k in 2:
						ci.draw_arc(c + Vector2(-r * 0.25 + k * r * 0.5, r * 0.2), r * 0.15, PI + 0.4, TAU - 0.4, 8, BLANCO, g * 0.8)
					if variante == "laguna":
						for s in [-1.0, 1.0]:
							elipse_c(ci, c + Vector2(s * r * 0.75, -r * 0.35), r * 0.12, r * 0.2, Color("#8CCB6A"), g * 0.4)


static func _arbol(ci: CanvasItem, c: Vector2, r: float, color: Color, color2: Color, variante: String, g: float, t: float) -> void:
	var tronco := Color("#8A5A36")
	match variante:
		"acacia":
			ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, -r * 0.1), TINTA, r * 0.26)
			ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, -r * 0.1), tronco, r * 0.17)
			elipse_c(ci, c + Vector2(0, -r * 0.35), r * 0.95, r * 0.32, color, g)
		"palmera":
			var pts := PackedVector2Array()
			for k in 8:
				var u := k / 7.0
				pts.append(c + Vector2(sin(u * 1.5) * r * 0.25, r * 0.8 - u * r * 1.3))
			ci.draw_polyline(pts, TINTA, r * 0.24, true)
			ci.draw_polyline(pts, color2, r * 0.15, true)
			var top := pts[pts.size() - 1]
			for k in 5:
				var a := PI + k * PI / 4.0 + sin(t * 1.5) * 0.06
				elipse_c(ci, top + Vector2(cos(a), sin(a) * 0.6 + 0.1) * r * 0.42, r * 0.42, r * 0.12, color, g * 0.6, a)
			for k in 2:
				circulo_c(ci, top + Vector2(-r * 0.08 + k * r * 0.16, r * 0.1), r * 0.08, Color("#8A5A36"), g * 0.4)
		"bananero":
			ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, -r * 0.2), TINTA, r * 0.24)
			ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, -r * 0.2), Color("#8AB04A"), r * 0.15)
			for k in 4:
				var a := PI * 1.1 + k * PI * 0.27
				elipse_c(ci, c + Vector2(0, -r * 0.2) + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.5, r * 0.18, color, g * 0.6, a)
			for k in 3:
				elipse_c(ci, c + Vector2(r * 0.18 + k * r * 0.1, r * 0.05 + k * r * 0.12), r * 0.1, r * 0.2, color2, g * 0.5, 0.6)
		"altos", "lluvioso", "bosque":
			var n := 3
			for k in n:
				var x := (k - 1) * r * 0.55
				var alto := r * (1.35 if k == 1 else 1.05)
				var base := c + Vector2(x, r * 0.85)
				ci.draw_line(base, base + Vector2(0, -alto * 0.4), TINTA, r * 0.18)
				ci.draw_line(base, base + Vector2(0, -alto * 0.4), tronco, r * 0.1)
				if variante == "altos":
					circulo_c(ci, base + Vector2(0, -alto * 0.75), r * 0.32, color, g * 0.8)
				else:
					var pts := PackedVector2Array([base + Vector2(-r * 0.32, -alto * 0.3), base + Vector2(0, -alto * 1.05), base + Vector2(r * 0.32, -alto * 0.3)])
					poligono_c(ci, pts, color, g * 0.8)
			if variante == "lluvioso":
				for k in 4:
					var p := c + Vector2(-r * 0.7 + k * r * 0.45, -r * 0.6 + fmod(t * 0.8 + k * 0.25, 1.0) * r * 1.2)
					elipse(ci, p, r * 0.04, r * 0.08, color2)
		"eucalipto":
			ci.draw_line(c + Vector2(0, r * 0.85), c + Vector2(0, -r * 0.6), TINTA, r * 0.24)
			ci.draw_line(c + Vector2(0, r * 0.85), c + Vector2(0, -r * 0.6), color2, r * 0.15)
			for k in 5:
				var p := c + Vector2((k % 2 * 2 - 1) * r * 0.35, -r * 0.65 + k * r * 0.28)
				elipse_c(ci, p, r * 0.3, r * 0.12, color, g * 0.5, 0.4 * (k % 2 * 2 - 1))
		"selva":
			ci.draw_line(c + Vector2(0, r * 0.85), c + Vector2(0, 0), TINTA, r * 0.24)
			ci.draw_line(c + Vector2(0, r * 0.85), c + Vector2(0, 0), tronco, r * 0.15)
			for p in [Vector2(-0.4, -0.2), Vector2(0.4, -0.2), Vector2(0, -0.55), Vector2(-0.2, 0.05), Vector2(0.25, 0.05)]:
				ci.draw_circle(c + p * r, r * 0.34 + g, TINTA)
			for p in [Vector2(-0.4, -0.2), Vector2(0.4, -0.2), Vector2(0, -0.55), Vector2(-0.2, 0.05), Vector2(0.25, 0.05)]:
				ci.draw_circle(c + p * r, r * 0.34, color)
			for k in 3:
				poligono_c(ci, estrella_puntos(c + Vector2(-r * 0.4 + k * r * 0.4, -r * 0.3 + (k % 2) * r * 0.25), r * 0.1), color2, g * 0.4)
		_:
			ci.draw_line(c + Vector2(0, r * 0.85), c + Vector2(0, 0), TINTA, r * 0.24)
			ci.draw_line(c + Vector2(0, r * 0.85), c + Vector2(0, 0), tronco, r * 0.15)
			circulo_c(ci, c + Vector2(0, -r * 0.3), r * 0.6, color, g)


static func _montana(ci: CanvasItem, c: Vector2, r: float, color: Color, color2: Color, variante: String, g: float, t: float) -> void:
	match variante:
		"volcan":
			var pts := PackedVector2Array([c + Vector2(-r * 0.9, r * 0.75), c + Vector2(-r * 0.25, -r * 0.4), c + Vector2(r * 0.25, -r * 0.4), c + Vector2(r * 0.9, r * 0.75)])
			poligono_c(ci, pts, color, g)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.4), c + Vector2(r * 0.25, -r * 0.4), c + Vector2(r * 0.12, -r * 0.1), c + Vector2(-r * 0.05, -r * 0.2), c + Vector2(-r * 0.15, -r * 0.05)]), color2)
			for k in 3:
				var u := fmod(t * 0.4 + k / 3.0, 1.0)
				ci.draw_circle(c + Vector2(sin(u * 6.0) * r * 0.1, -r * 0.5 - u * r * 0.45), r * (0.1 + u * 0.12), Color(0.85, 0.85, 0.9, 1.0 - u))
		"roquerio":
			elipse(ci, c + Vector2(0, r * 0.55), r * 0.95, r * 0.3, color2)
			for p in [Vector2(-0.4, 0.2), Vector2(0.3, 0.1), Vector2(0, -0.2)]:
				elipse_c(ci, c + p * r, r * 0.36, r * 0.3, color, g)
			for k in 2:
				ci.draw_arc(c + Vector2(-r * 0.5 + k * r * 0.8, r * 0.62), r * 0.14, PI + 0.4, TAU - 0.4, 8, BLANCO, g * 0.8)
		"barranco":
			var pts := PackedVector2Array([c + Vector2(-r * 0.9, r * 0.8), c + Vector2(-r * 0.9, -r * 0.6), c + Vector2(-r * 0.1, -r * 0.6), c + Vector2(r * 0.1, r * 0.1), c + Vector2(r * 0.9, r * 0.3), c + Vector2(r * 0.9, r * 0.8)])
			poligono_c(ci, pts, color, g)
			for k in 3:
				ci.draw_line(c + Vector2(-r * 0.9, -r * 0.3 + k * r * 0.35), c + Vector2(-r * 0.05 + k * r * 0.1, -r * 0.3 + k * r * 0.35), color2, g)
			for k in 3:
				ci.draw_circle(c + Vector2(-r * 0.65 + k * r * 0.22, -r * 0.1), r * 0.06, TINTA)
		_:
			var picos := [Vector2(-0.45, -0.3), Vector2(0.3, -0.62)] if variante != "cumbre" else [Vector2(0, -0.75)]
			for p in picos:
				var cima := c + Vector2(p.x * r, p.y * r)
				var ancho := r * (0.62 if variante != "cumbre" else 0.85)
				var pts := PackedVector2Array([Vector2(cima.x - ancho, c.y + r * 0.75), cima, Vector2(cima.x + ancho, c.y + r * 0.75)])
				poligono_c(ci, pts, color, g)
				var nieve := PackedVector2Array([cima, cima + Vector2(ancho * 0.3, r * 0.32), cima + Vector2(0, r * 0.22), cima + Vector2(-ancho * 0.3, r * 0.32)])
				ci.draw_colored_polygon(nieve, color2)
			if variante == "cumbre":
				var cima := c + Vector2(0, -r * 0.75)
				ci.draw_line(cima, cima + Vector2(0, -r * 0.25), TINTA, g)


static func _cueva(ci: CanvasItem, c: Vector2, r: float, color: Color, color2: Color, variante: String, g: float, abierta: float) -> void:
	match variante:
		"madriguera":
			var pts := PackedVector2Array()
			for k in 17:
				var a := PI + PI * k / 16.0
				pts.append(c + Vector2(cos(a) * r * 0.9, r * 0.6 + sin(a) * r * 0.9))
			poligono_c(ci, pts, color, g)
			elipse(ci, c + Vector2(0, r * 0.4), r * 0.32, r * 0.25, color2)
			for k in 3:
				ci.draw_line(c + Vector2(-r * 0.6 + k * r * 0.6, -r * 0.1), c + Vector2(-r * 0.55 + k * r * 0.6, -r * 0.35), Color("#4E8F3A"), g)
		"tronco", "roble":
			rect_redondo_c(ci, Rect2(c - Vector2(r * 0.55, r * 0.85), Vector2(r * 1.1, r * 1.65)), r * 0.25, color, TINTA, g)
			for k in 3:
				ci.draw_line(c + Vector2(-r * 0.35 + k * r * 0.35, -r * 0.7), c + Vector2(-r * 0.35 + k * r * 0.35, -r * 0.45), color.darkened(0.25), g * 0.7)
			elipse(ci, c + Vector2(0, -r * 0.05), r * 0.25, r * 0.32, color2)
			if variante == "tronco":
				elipse_c(ci, c + Vector2(r * 0.55, -r * 0.5), r * 0.22, r * 0.1, Color("#5FAE5A"), g * 0.4, -0.4)
		_:
			var pts := PackedVector2Array()
			for k in 17:
				var a := PI + PI * k / 16.0
				pts.append(c + Vector2(cos(a) * r * 0.92, r * 0.7 + sin(a) * r * 1.2))
			poligono_c(ci, pts, color, g)
			var boca := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				boca.append(c + Vector2(cos(a) * r * 0.42, r * 0.7 + sin(a) * r * (0.62 + 0.06 * abierta)))
			ci.draw_colored_polygon(boca, color2)
			if variante == "costa":
				elipse(ci, c + Vector2(r * 0.55, r * 0.75), r * 0.4, r * 0.1, Color("#5CC8F0"))
			if variante == "milodon":
				for k in 3:
					ci.draw_circle(c + Vector2(-r * 0.5 + k * r * 0.18, -r * 0.1 - k * r * 0.12), r * 0.05, color.darkened(0.35))
			for k in 3:
				ci.draw_circle(c + Vector2(-r * 0.55 + k * r * 0.5, -r * 0.2 + (k % 2) * r * 0.15), r * 0.05, color.darkened(0.2))


static func _pasto(ci: CanvasItem, c: Vector2, r: float, color: Color, color2: Color, variante: String, g: float, t: float) -> void:
	elipse_c(ci, c + Vector2(0, r * 0.45), r * 0.9, r * 0.35, color, g)
	var n := 7
	var alto := r * (0.95 if variante in ["alto", "juncos"] else 0.55)
	for k in n:
		var x := -r * 0.75 + k * r * 0.25
		var bal := sin(t * 1.8 + k) * r * 0.05
		var base := c + Vector2(x, r * 0.5)
		var punta := base + Vector2(bal, -alto * (0.8 + 0.2 * (k % 2)))
		var tono := color.darkened(0.15) if variante != "estepa" else color2
		ci.draw_line(base, punta, TINTA, g * 1.6)
		ci.draw_line(base, punta, tono, g * 0.9)
		if variante == "juncos" and k % 2 == 1:
			elipse(ci, punta + Vector2(0, r * 0.08), r * 0.05, r * 0.12, Color("#8A5A36"))
	match variante:
		"flores", "pradera":
			for k in 4:
				var p := c + Vector2(-r * 0.6 + k * r * 0.4, -r * 0.05 + (k % 2) * r * 0.25)
				flor(ci, p, r * 0.14, color2 if k % 2 == 0 else Color("#FFFFFF"), 1.0)
		"juncos":
			elipse(ci, c + Vector2(r * 0.4, r * 0.62), r * 0.35, r * 0.1, color2)


# ---------------------------------------------------------------------------
# Huellas, flores, rocas, puentes, nube y paraguas
# ---------------------------------------------------------------------------

## Una huella en `p`, apuntando en `ang` (radianes), de tamaño `s` (px).
static func huella(ci: CanvasItem, p: Vector2, ang: float, s: float, tipo: String, color: Color) -> void:
	var f := Vector2.from_angle(ang)
	var l := f.orthogonal()
	match tipo:
		"pezuna":
			elipse(ci, p + l * s * 0.18, s * 0.16, s * 0.3, color, ang + PI / 2)
			elipse(ci, p - l * s * 0.18, s * 0.16, s * 0.3, color, ang + PI / 2)
		"dino":
			ci.draw_circle(p - f * s * 0.15, s * 0.2, color)
			for k in 3:
				var a := ang + (k - 1) * 0.55
				var punta := p + Vector2.from_angle(a) * s * 0.5
				ci.draw_line(p - f * s * 0.1, punta, color, s * 0.14, true)
		"pato":
			ci.draw_colored_polygon(PackedVector2Array([p - f * s * 0.3, p + f * s * 0.3 + l * s * 0.3, p + f * s * 0.3 - l * s * 0.3]), color)
		"ave":
			for k in 3:
				var a := ang + (k - 1) * 0.6
				ci.draw_line(p - f * s * 0.2, p - f * s * 0.2 + Vector2.from_angle(a) * s * 0.5, color, s * 0.1, true)
			ci.draw_line(p - f * s * 0.2, p - f * s * 0.45, color, s * 0.1, true)
		"plumita":
			elipse(ci, p, s * 0.42, s * 0.14, color, ang)
			ci.draw_line(p - f * s * 0.5, p + f * s * 0.35, color.darkened(0.35), s * 0.06, true)
		"burbuja":
			ci.draw_arc(p, s * 0.26, 0, TAU, 14, color, s * 0.08, true)
			ci.draw_circle(p + Vector2(-s * 0.08, -s * 0.08), s * 0.06, color)
		"aleta":
			elipse(ci, p, s * 0.18, s * 0.36, color, ang + PI / 2 + 0.3)
		_:
			ci.draw_circle(p - f * s * 0.08, s * 0.22, color)
			for k in 3:
				var a := ang + (k - 1) * 0.65
				ci.draw_circle(p + Vector2.from_angle(a) * s * 0.33, s * 0.1, color)


## Florcita de 5 pétalos que "brota" (k 0-1).
static func flor(ci: CanvasItem, p: Vector2, r: float, color: Color, k := 1.0) -> void:
	if k <= 0.0:
		return
	var rr := r * k
	for n in 5:
		var a := TAU * n / 5.0
		ci.draw_circle(p + Vector2.from_angle(a) * rr * 0.55, rr * 0.45, color)
	ci.draw_circle(p, rr * 0.35, Color("#FFD84A"))


## Roca dormilona (bloquea siempre). `toc` desplaza un pixel cuando la tocan.
static func roca(ci: CanvasItem, c: Vector2, r: float, toc := 0.0) -> void:
	c += Vector2(sin(toc * 40.0) * 2.0 * toc, 0)
	var pts := PackedVector2Array()
	for k in 9:
		var a := PI + PI * k / 8.0
		pts.append(c + Vector2(cos(a) * r * 0.8, r * 0.45 + sin(a) * r * 0.85 * (0.85 + 0.15 * sin(k * 2.1))))
	poligono_c(ci, pts, Color("#A8ADB8"), r * 0.07)
	elipse(ci, c + Vector2(-r * 0.25, -r * 0.05), r * 0.18, r * 0.1, Color("#C8CCD6"))
	for s in [-1.0, 1.0]:
		ci.draw_arc(c + Vector2(s * r * 0.22, r * 0.12), r * 0.08, 0.2, PI - 0.2, 8, TINTA, r * 0.05, true)


## Puentecito de madera con baranda (cruza en recto en los dos ejes).
static func puente(ci: CanvasItem, c: Vector2, lado: float) -> void:
	var m := lado * 0.5
	var madera := Color("#C98A4B")
	for eje in 2:
		var largo := Vector2(m, lado * 0.2) if eje == 0 else Vector2(lado * 0.2, m)
		var r := Rect2(c - largo, largo * 2.0)
		ci.draw_rect(r.grow(2), TINTA)
		ci.draw_rect(r, madera if eje == 0 else madera.lightened(0.12))
	for k in 4:
		var x := -m + (k + 0.5) * lado / 4.0
		ci.draw_line(c + Vector2(x, -lado * 0.2), c + Vector2(x, lado * 0.2), madera.darkened(0.3), 2.0)
	for s in [-1.0, 1.0]:
		ci.draw_line(c + Vector2(-m, s * lado * 0.24), c + Vector2(m, s * lado * 0.24), Color("#7A4A26"), 3.0)


## Nubecita del relojito (0 blanca, 1 gris de tormenta).
static func nube(ci: CanvasItem, c: Vector2, s: float, gris: float, t: float) -> void:
	var color := Color("#FFFFFF").lerp(Color("#8C93A8"), gris)
	var puntos := [Vector2(-0.5, 0.1), Vector2(-0.15, -0.2), Vector2(0.25, -0.15), Vector2(0.55, 0.1), Vector2(0.0, 0.2)]
	for p in puntos:
		ci.draw_circle(c + p * s, s * 0.32 + 3.0, TINTA)
	for p in puntos:
		ci.draw_circle(c + p * s, s * 0.32, color)
	for k in 2:
		ci.draw_circle(c + Vector2((k * 2 - 1) * s * 0.18, s * 0.02), s * 0.05, TINTA)
	ci.draw_arc(c + Vector2(0, s * 0.08), s * 0.1, 0.3, PI - 0.3, 8, TINTA, 2.5, true)


## Paraguas de hoja sobre un animal sin casa (tormenta).
static func paraguas_hoja(ci: CanvasItem, c: Vector2, r: float, t: float) -> void:
	var bal := sin(t * 6.0) * 0.12
	var pts := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.6).rotated(bal))
	poligono_c(ci, pts, Color("#4FB86A"), r * 0.06)
	ci.draw_line(c, c + Vector2(0, -r * 0.6).rotated(bal), Color("#2E7A3A"), r * 0.05)
	ci.draw_line(c, c + Vector2(0, r * 0.9).rotated(bal), Color("#7A4A26"), r * 0.08)
