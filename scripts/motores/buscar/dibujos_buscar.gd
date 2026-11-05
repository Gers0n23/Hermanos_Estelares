extends RefCounted

## Arte PROVISIONAL del «Escondite animal», dibujado por codigo (ficha motor-buscar.md §11.3, decision del
## PO 05-Nov-2026: escenas compuestas con piezas reutilizables). Cartoon y tierno: contorno azul noche,
## volumen con sombra interna y brillo, caritas kawaii. Sin mariposas ni bichos (ficha §2 regla 8).
##
## La MASA de cada pieza y de cada animal es exactamente la union de primitivas de `GeometriaBuscar`
## (lo que tapa y lo que se toca); los detalles (hojas, vetas, rayas, ojos) van por dentro. Asi lo que el
## arnes mide como "parte visible" es lo que el nino ve.
## Funciones estaticas: pintan sobre cualquier CanvasItem ya transformado por la camara del motor.

const G := preload("res://scripts/motores/buscar/geometria_buscar.gd")
const CONTORNO := Color("#2B3350")
const RUBOR := Color(1.0, 0.5, 0.6, 0.55)
const LADOS := 26

## Colores por tipo de pieza: uno por primitiva (el ultimo se repite). `color` del nivel reemplaza al 2.o.
const COLORES_PIEZA := {
	"arbusto": ["#4FAE5C", "#5DBB63", "#58B55F", "#66C46B"],
	"roca": ["#A39DB5", "#B3ADC4", "#9C96AE"],
	"arbol": ["#9C6B43", "#58B55F", "#4FAE5C", "#4FAE5C", "#66C46B"],
	"acacia": ["#8E6140", "#7DBE55", "#86C65C", "#86C65C"],
	"helecho": ["#3FA35F", "#4CB06A", "#4CB06A", "#56BA72"],
	"pasto_alto": ["#B9D45A", "#C8DE6A"],
	"juncos": ["#6FAE4F", "#9C6B43", "#9C6B43", "#9C6B43"],
	"nenufar": ["#49B56A", "#FF8FB8"],
	"nido": ["#B07A4A"],
	"tronco": ["#A8744A", "#C9925E", "#C9925E"],
	"tronco_hueco": ["#A8744A", "#C9925E", "#C9925E"],
	"hongo": ["#FFF1DC", "#E8434B"],
	"flor_gigante": ["#4FAE5C", "#FF7EB6", "#FF7EB6", "#FF9EC7"],
	"carpa": ["#FF9F43", "#FF9F43", "#FFB45C"],
	"fardo": ["#F2C14E", "#E8B440", "#E8B440"],
	"cesto": ["#C98B4E", "#D9A066"],
	"balde": ["#3D7BE0"],
	"regadera": ["#36B866", "#36B866"],
	"carretilla": ["#E8434B", "#5A5F73"],
	"gallinero": ["#F4D9A8", "#C0503E"],
	"cerca": ["#D8A46E"],
	"bote": ["#FFB347"],
	"manguera": ["#E8434B", "#9AA0B5"],
	"camion": ["#E8434B", "#F05A5A", "#3B3F55", "#3B3F55"],
	"cueva": ["#8C7A6B", "#97857A", "#7E6E61"],
	"volcan": ["#A8786A"],
	"geiser": ["#7FC6E8"],
	"huesos": ["#FFF4DC", "#FFF4DC"],
	"nube": ["#FFFFFF"],
	"cristales": ["#9EE6FF"],
}


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

static func poligono_de(prim: Dictionary) -> PackedVector2Array:
	match int(prim["t"]):
		G.ELIPSE:
			var c: Vector2 = prim["c"]
			var rr: Vector2 = prim["r"]
			var pts := PackedVector2Array()
			for i in LADOS:
				var a := TAU * i / LADOS
				pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y))
			return pts
		G.RECT:
			var c2: Vector2 = prim["c"]
			var m: Vector2 = prim["r"]
			# Esquinas apenas redondeadas (cartoon).
			var k := minf(minf(m.x, m.y) * 0.35, 14.0)
			return PackedVector2Array([
				c2 + Vector2(-m.x + k, -m.y), c2 + Vector2(m.x - k, -m.y), c2 + Vector2(m.x, -m.y + k),
				c2 + Vector2(m.x, m.y - k * 0.3), c2 + Vector2(m.x - k * 0.3, m.y), c2 + Vector2(-m.x + k * 0.3, m.y),
				c2 + Vector2(-m.x, m.y - k * 0.3), c2 + Vector2(-m.x, -m.y + k)])
	return prim["p"]


static func elipse(c: Vector2, rr: Vector2, lados := LADOS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in lados:
		var a := TAU * i / lados
		pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y))
	return pts


static func xf_poli(xf: Transform2D, poli: PackedVector2Array) -> PackedVector2Array:
	return xf * poli


static func trazar(lienzo, poli: PackedVector2Array, ancho: float, color := CONTORNO) -> void:
	if poli.size() < 2:
		return
	var cerrado := poli.duplicate()
	cerrado.append(poli[0])
	lienzo.draw_polyline(cerrado, color, ancho, true)


static func rellenar(lienzo, poli: PackedVector2Array, color: Color) -> void:
	if poli.size() >= 3:
		lienzo.draw_colored_polygon(poli, color)


## Union de poligonos con un solo contorno exterior: primero todos los contornos, despues los rellenos.
static func masa(lienzo, polis: Array, colores: Array, trazo: float, alfa := 1.0) -> void:
	for poli in polis:
		trazar(lienzo, poli, trazo * 2.0, Color(CONTORNO, alfa))
	for i in polis.size():
		var color: Color = colores[mini(i, colores.size() - 1)]
		color.a *= alfa
		rellenar(lienzo, polis[i], color)


## Sombra interna abajo a la derecha y brillo arriba a la izquierda dentro de un poligono (volumen).
static func volumen(lienzo, poli: PackedVector2Array, color: Color, desplazo: Vector2, alfa := 1.0) -> void:
	var movido := PackedVector2Array()
	for q in poli:
		movido.append(q + desplazo)
	for trozo in Geometry2D.clip_polygons(poli, movido):
		if trozo.size() >= 3:
			lienzo.draw_colored_polygon(trozo, Color(color.darkened(0.14), alfa))


static func col(valor, defecto: Color) -> Color:
	if valor is Color:
		return valor
	if valor is String and valor != "":
		return Color(valor)
	return defecto


# ---------------------------------------------------------------------------
# Fondo de la escena
# ---------------------------------------------------------------------------

static func dibujar_fondo(lienzo, fondo: Dictionary, tamano: Vector2, t: float, tarde := 0.0) -> void:
	var cielo: Array = fondo.get("cielo", ["#9ED8F5", "#E8F7FF"])
	var arriba := col(cielo[0], Color("#9ED8F5"))
	var abajo := col(cielo[1] if cielo.size() > 1 else cielo[0], Color("#E8F7FF"))
	if tarde > 0.0:
		arriba = arriba.lerp(Color("#F39A6B"), tarde * 0.55)
		abajo = abajo.lerp(Color("#FFD38A"), tarde * 0.6)
	var franjas := 8
	for i in franjas:
		var y0 := tamano.y * i / franjas
		lienzo.draw_rect(Rect2(0, y0, tamano.x, tamano.y / franjas + 1), arriba.lerp(abajo, float(i) / (franjas - 1)))
	if bool(fondo.get("estrellas", false)):
		for i in 40:
			var q := Vector2(fmod(i * 397.0, tamano.x), fmod(i * 131.0, tamano.y * 0.4))
			lienzo.draw_circle(q, 2.0 + (i % 3), Color(1, 1, 1, 0.5 + 0.3 * sin(t * 2.0 + i)))
	for colina in fondo.get("lejos", []):
		var y := float(colina.get("y", tamano.y * 0.45))
		var amp := float(colina.get("amp", 40))
		var ondas := float(colina.get("ondas", 3))
		var fase := float(colina.get("fase", 0))
		var c := col(colina.get("color", "#A8D99A"), Color("#A8D99A"))
		var pts := PackedVector2Array()
		pts.append(Vector2(0, tamano.y))
		var pasos := 48
		for i in pasos + 1:
			var x := tamano.x * i / pasos
			pts.append(Vector2(x, y - amp * (0.5 + 0.5 * sin(x / tamano.x * TAU * ondas + fase))))
		pts.append(Vector2(tamano.x, tamano.y))
		lienzo.draw_colored_polygon(pts, c)
	var suelo: Dictionary = fondo.get("suelo", {})
	if not suelo.is_empty():
		var ys := float(suelo.get("y", tamano.y * 0.55))
		var cs := col(suelo.get("color", "#8CCB6A"), Color("#8CCB6A"))
		var pts2 := PackedVector2Array()
		pts2.append(Vector2(0, tamano.y))
		for i in 49:
			var x2 := tamano.x * i / 48.0
			pts2.append(Vector2(x2, ys - 10.0 * sin(x2 / 260.0)))
		pts2.append(Vector2(tamano.x, tamano.y))
		lienzo.draw_colored_polygon(pts2, cs)
		var cs2 := col(suelo.get("color2", ""), cs.darkened(0.08))
		# Matitas de pasto y florcitas sueltas (deterministas por posicion: no tiemblan).
		var n := int(tamano.x * (tamano.y - ys) / 9000.0)
		for i in n:
			var hx := fmod(i * 233.7 + 41.0, tamano.x)
			var hy := ys + 20.0 + fmod(i * 97.3, maxf(10.0, tamano.y - ys - 30.0))
			if i % 4 == 0:
				var fc: Color = [Color("#FFFFFF"), Color("#FFD93D"), Color("#FF9EC7")][i % 3]
				for k in 5:
					lienzo.draw_circle(Vector2(hx, hy) + Vector2.from_angle(TAU * k / 5.0) * 5.0, 4.0, fc)
				lienzo.draw_circle(Vector2(hx, hy), 3.0, Color("#FFB347"))
			else:
				lienzo.draw_line(Vector2(hx, hy), Vector2(hx - 5, hy - 12), cs2, 3.0, true)
				lienzo.draw_line(Vector2(hx, hy), Vector2(hx + 1, hy - 14), cs2, 3.0, true)
				lienzo.draw_line(Vector2(hx, hy), Vector2(hx + 6, hy - 11), cs2, 3.0, true)
	var camino: Dictionary = fondo.get("camino", {})
	if not camino.is_empty():
		var pts3 := PackedVector2Array()
		for q in camino.get("puntos", []):
			pts3.append(G.vec(q))
		if pts3.size() >= 2:
			var ancho := float(camino.get("ancho", 60))
			lienzo.draw_polyline(pts3, col(camino.get("color", "#E8C99A"), Color("#E8C99A")).darkened(0.1), ancho + 8, true)
			lienzo.draw_polyline(pts3, col(camino.get("color", "#E8C99A"), Color("#E8C99A")), ancho, true)
	for agua in fondo.get("agua", []):
		var rr: Array = agua.get("rect", [0, 0, 100, 100])
		var rect := Rect2(float(rr[0]), float(rr[1]), float(rr[2]), float(rr[3]))
		var ca := col(agua.get("color", "#5CC8F0"), Color("#5CC8F0"))
		var forma := elipse(rect.get_center(), rect.size / 2.0, 40)
		trazar(lienzo, forma, 10.0, ca.darkened(0.25))
		rellenar(lienzo, forma, ca)
		rellenar(lienzo, elipse(rect.get_center() + Vector2(0, rect.size.y * 0.08), rect.size * Vector2(0.42, 0.34), 32), ca.lightened(0.12))
		for k in 6:
			var ox := rect.position.x + rect.size.x * (0.2 + 0.12 * k)
			var oy := rect.position.y + rect.size.y * (0.35 + 0.08 * (k % 3)) + 4.0 * sin(t * 1.5 + k)
			lienzo.draw_arc(Vector2(ox, oy), 18.0, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.6), 3.0, true)
	if bool(fondo.get("niebla", false)):
		for k in 5:
			var nx := fmod(k * 700.0 + t * 12.0, tamano.x + 400.0) - 200.0
			lienzo.draw_colored_polygon(elipse(Vector2(nx, tamano.y * 0.42), Vector2(260, 40), 24), Color(1, 1, 1, 0.22))


# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

## `anim`: {"sacudir": 0-1, "rebote": 0-1, "fase": float}. `abierto` 0-1. `huellita`: el escondite ya se
## uso (marca dorada para no volver a buscar ahi, ficha §7.2).
static func dibujar_pieza(lienzo, obj: Dictionary, abierto: float, anim: Dictionary, t: float, huellita := false) -> void:
	var tipo := str(obj.get("tipo", "arbusto"))
	var pos := G.vec(obj.get("pos", [0, 0]))
	var escala := float(obj.get("escala", 1.0))
	var espejo := bool(obj.get("espejo", false))
	var sacudir := float(anim.get("sacudir", 0.0))
	var rebote := float(anim.get("rebote", 0.0))
	var rot := sin(t * 28.0) * 0.07 * sacudir
	var sq := 1.0 - 0.12 * sin(rebote * PI)
	if tipo in ["nube"]:
		rot = 0.0
		sq = 1.0 + 0.1 * sin(rebote * PI)
	# Escondite de 2 pasos a medio abrir: tiembla un poquito y queda entreabierto (pista visual).
	var medio := abierto > 0.0 and abierto < 1.0
	if medio:
		rot += sin(t * 9.0) * 0.02
	var xf := Transform2D(rot, Vector2(escala * (-1.0 if espejo else 1.0), escala * sq), 0.0, pos)
	var prims := G.cobertura_local(tipo, abierto)
	var polis: Array = []
	for prim in prims:
		polis.append(xf * poligono_de(prim))
	var colores: Array = []
	for c in COLORES_PIEZA.get(tipo, ["#7FBF6A"]):
		colores.append(Color(c))
	if obj.has("color") and colores.size() > 1:
		for i in range(1, colores.size()):
			colores[i] = Color(str(obj["color"])).lerp(colores[i], 0.25 * (i % 2))
	elif obj.has("color"):
		colores[0] = Color(str(obj["color"]))
	var trazo := clampf(3.2 * escala, 2.2, 5.0)
	# Sombra en el suelo (no tapa: es mas clara que el fondo y va debajo).
	if not tipo in ["nube", "nido", "nenufar", "volcan"]:
		var ancho := G.TAMANO_NOMINAL.get(tipo, Vector2(160, 100)).x * escala * 0.5
		lienzo.draw_colored_polygon(elipse(pos + Vector2(0, 2), Vector2(ancho, ancho * 0.16), 20), Color(CONTORNO, 0.16))
	_detalles_atras(lienzo, tipo, xf, abierto, t)
	masa(lienzo, polis, colores, trazo)
	for i in polis.size():
		var cc: Color = colores[mini(i, colores.size() - 1)]
		volumen(lienzo, polis[i], cc, xf.basis_xform(Vector2(-6, -9)))
	_detalles(lienzo, tipo, xf, abierto, t, escala, trazo, obj)
	if huellita:
		var arriba := G.caja_de(G.cobertura(obj, abierto))
		_huellita(lienzo, Vector2(arriba.get_center().x, arriba.position.y + 14.0), 16.0)


static func _huellita(lienzo, c: Vector2, rad: float) -> void:
	var oro := Color("#FFCB3D")
	lienzo.draw_colored_polygon(elipse(c + Vector2(0, rad * 0.35), Vector2(rad * 0.62, rad * 0.5), 16), oro)
	for k in 4:
		var a := PI * (1.15 + 0.23 * k)
		lienzo.draw_colored_polygon(elipse(c + Vector2.from_angle(a) * rad * 0.95, Vector2(rad * 0.24, rad * 0.3), 12), oro)


static func _detalles_atras(lienzo, tipo: String, xf: Transform2D, abierto: float, t: float) -> void:
	match tipo:
		"carpa":
			# Antenita de Toby con su estrellita dorada.
			var base := xf * Vector2(0, -222)
			var punta := xf * Vector2(10, -282)
			lienzo.draw_line(base, punta, CONTORNO, 5.0, true)
			lienzo.draw_circle(punta, 12.0, CONTORNO)
			lienzo.draw_circle(punta, 8.5, Color("#FFCB3D"))
			if abierto >= 1.0:
				# Interior en sombra (el animal queda delante del fondo de la carpa).
				lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -100), Vector2(90, 96)), Color("#7A4A2A"))
		"cueva":
			if abierto >= 1.0:
				lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -110), Vector2(110, 100)), Color("#4B3F5C"))
				for k in 5:
					var q := xf * Vector2(-70 + 35 * k, -40 - 20 * (k % 2))
					lienzo.draw_colored_polygon(PackedVector2Array([q + Vector2(-10, 0), q + Vector2(0, -34), q + Vector2(10, 0)]),
						Color("#9EE6FF").lerp(Color("#E6B3FF"), (k % 2) * 0.6))
		"flor_gigante", "fardo", "tronco_hueco", "cesto":
			if abierto >= 1.0 and tipo == "flor_gigante":
				lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -140), Vector2(60, 46)), Color("#FFE38A"))


static func _detalles(lienzo, tipo: String, xf: Transform2D, abierto: float, t: float, escala: float, trazo: float, obj: Dictionary) -> void:
	var fino := maxf(2.0, trazo * 0.7)
	match tipo:
		"arbusto":
			for q in [Vector2(-60, -80), Vector2(40, -96), Vector2(-10, -126), Vector2(70, -60), Vector2(-80, -40)]:
				lienzo.draw_arc(xf * q, 16.0 * escala, PI * 0.9, PI * 1.6, 8, Color("#3E8F4B"), fino, true)
			if bool(obj.get("flores", false)) or str(obj.get("variante", "")) == "flores":
				for q in [Vector2(-50, -60), Vector2(30, -110), Vector2(70, -70), Vector2(-20, -40)]:
					_florcita(lienzo, xf * q, 8.0 * escala, Color("#FF9EC7"))
			else:
				for q in [Vector2(-40, -70), Vector2(50, -60), Vector2(10, -110)]:
					lienzo.draw_circle(xf * q, 6.0 * escala, Color("#E8434B"))
					lienzo.draw_circle(xf * q + Vector2(-2, -2) * escala, 2.0 * escala, Color(1, 1, 1, 0.7))
		"roca":
			lienzo.draw_arc(xf * Vector2(-30, -60), 22.0 * escala, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.45), fino * 1.4, true)
			lienzo.draw_line(xf * Vector2(20, -40), xf * Vector2(44, -60), Color("#7E7891"), fino, true)
		"arbol":
			lienzo.draw_line(xf * Vector2(-6, -40), xf * Vector2(-8, -110), Color("#7A5032"), fino, true)
			lienzo.draw_line(xf * Vector2(10, -70), xf * Vector2(12, -150), Color("#7A5032"), fino, true)
			for q in [Vector2(-60, -250), Vector2(40, -300), Vector2(70, -230), Vector2(-20, -340), Vector2(-90, -210)]:
				lienzo.draw_arc(xf * q, 18.0 * escala, PI * 0.9, PI * 1.6, 8, Color("#3E8F4B"), fino, true)
			for q in [Vector2(-40, -220), Vector2(60, -270)]:
				lienzo.draw_circle(xf * q, 8.0 * escala, Color("#FF8A3D"))
		"acacia":
			lienzo.draw_line(xf * Vector2(0, -200), xf * Vector2(-70, -250), Color("#8E6140"), 8.0 * escala, true)
			lienzo.draw_line(xf * Vector2(0, -200), xf * Vector2(80, -250), Color("#8E6140"), 8.0 * escala, true)
			for q in [Vector2(-120, -262), Vector2(-20, -290), Vector2(100, -270)]:
				lienzo.draw_arc(xf * q, 20.0 * escala, PI * 0.9, PI * 1.6, 8, Color("#5E9E3E"), fino, true)
		"helecho":
			for k in 7:
				var a := PI * (1.08 + 0.12 * k)
				lienzo.draw_line(xf * Vector2(0, -6), xf * (Vector2(0, -6) + Vector2.from_angle(a) * 100.0), Color("#2E8A4E"), fino, true)
		"pasto_alto":
			for k in 13:
				var x := -110.0 + 18.0 * k
				var punta := Vector2(x + 8.0 * sin(t * 1.4 + k), -120.0 + 18.0 * (k % 3))
				lienzo.draw_line(xf * Vector2(x, -4), xf * punta, Color("#94B442"), fino, true)
		"juncos":
			for k in 6:
				var x2 := -55.0 + 22.0 * k
				lienzo.draw_line(xf * Vector2(x2, -4), xf * Vector2(x2 + 4, -150), Color("#5A9A40"), fino, true)
		"nenufar":
			lienzo.draw_line(xf * Vector2(0, -16), xf * Vector2(-70, -26), Color("#2F8A4E"), fino, true)
			_florcita(lienzo, xf * Vector2(26, -44), 13.0 * escala, Color("#FF8FB8"))
		"nido":
			for k in 5:
				lienzo.draw_line(xf * Vector2(-64 + 28 * k, -10), xf * Vector2(-44 + 28 * k, -42), Color("#8A5A32"), fino, true)
		"tronco", "tronco_hueco":
			for lado in [-1.0, 1.0]:
				var c := xf * Vector2(128.0 * lado, -50.0 if tipo == "tronco" else -72.0)
				lienzo.draw_arc(c, 24.0 * escala, 0, TAU, 14, Color("#E8C08A"), fino * 1.6, true)
				lienzo.draw_arc(c, 11.0 * escala, 0, TAU, 10, Color("#8A5A32"), fino, true)
			if tipo == "tronco_hueco" and abierto < 1.0:
				lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -72), Vector2(40, 34)), Color("#4B3424"))
		"hongo":
			for q in [Vector2(-40, -108), Vector2(10, -126), Vector2(46, -96), Vector2(-6, -92)]:
				lienzo.draw_circle(xf * q, 10.0 * escala, Color("#FFF8EE"))
		"flor_gigante":
			lienzo.draw_colored_polygon(xf * elipse(Vector2(-30, -60), Vector2(30, 12)), Color("#4FAE5C"))
			if abierto < 1.0:
				lienzo.draw_line(xf * Vector2(0, -100), xf * Vector2(0, -250), Color("#E85C9A"), fino, true)
				lienzo.draw_line(xf * Vector2(-30, -120), xf * Vector2(-20, -230), Color("#E85C9A"), fino, true)
				lienzo.draw_line(xf * Vector2(30, -120), xf * Vector2(20, -230), Color("#E85C9A"), fino, true)
		"carpa":
			if abierto < 1.0:
				lienzo.draw_line(xf * Vector2(0, -6), xf * Vector2(0, -200), Color("#C9701E"), fino * 1.3, true)
				for k in 3:
					lienzo.draw_line(xf * Vector2(-120 + 120 * k, -30), xf * Vector2(-60 + 60 * k, -200), Color("#FFD166"), fino * 2.0, true)
				# Huellita de Toby pintada en la puerta.
				_huellita(lienzo, xf * Vector2(-50, -90), 14.0 * escala)
			else:
				for lado in [-1.0, 1.0]:
					lienzo.draw_line(xf * Vector2(80.0 * lado, -170), xf * Vector2(120.0 * lado, -20), Color("#C9701E"), fino, true)
		"fardo":
			if abierto < 1.0:
				for k in 5:
					lienzo.draw_line(xf * Vector2(-80 + 40 * k, -12), xf * Vector2(-70 + 40 * k, -118), Color("#C99A30"), fino, true)
				lienzo.draw_line(xf * Vector2(-100, -64), xf * Vector2(100, -64), Color("#B0482E"), fino * 1.6, true)
		"cesto":
			for k in 4:
				lienzo.draw_line(xf * Vector2(-60, -14 - 18 * k), xf * Vector2(60, -14 - 18 * k), Color("#A8703A"), fino, true)
		"balde":
			lienzo.draw_arc(xf * Vector2(0, -84), 46.0 * escala, PI, TAU, 14, CONTORNO, fino, true)
		"regadera":
			for k in 3:
				lienzo.draw_circle(xf * Vector2(80 + 6 * k, -90 - 4 * k), 3.0, Color("#9EE6FF"))
		"carretilla":
			lienzo.draw_circle(xf * Vector2(62, -26), 9.0 * escala, Color("#C9CDD8"))
			lienzo.draw_line(xf * Vector2(-108, -60), xf * Vector2(-160, -40), CONTORNO, fino * 1.5, true)
		"gallinero":
			lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -60), Vector2(30, 34)), Color("#5A3A2A"))
			lienzo.draw_rect(Rect2(xf * Vector2(46, -110), Vector2(30, 26) * escala), Color("#FFE38A"))
		"bote":
			lienzo.draw_line(xf * Vector2(-120, -44), xf * Vector2(120, -44), Color("#FFFFFF"), fino * 1.6, true)
		"manguera":
			for k in 3:
				lienzo.draw_arc(xf * Vector2(0, -66), (18.0 + 13.0 * k) * escala, 0, TAU, 18, Color("#C0303A"), fino, true)
		"camion":
			lienzo.draw_rect(Rect2(xf * Vector2(56, -120), Vector2(30, 18) * escala), Color("#BFE8FF"))
			lienzo.draw_circle(xf * Vector2(80, -136), 7.0 * escala, Color("#3D7BE0") if fmod(t, 1.0) < 0.5 else Color("#E8434B"))
			lienzo.draw_line(xf * Vector2(-100, -90), xf * Vector2(40, -110), Color("#D8DCE6"), fino * 2.0, true)
			for c2 in [Vector2(-60, -24), Vector2(60, -24)]:
				lienzo.draw_circle(xf * c2, 10.0 * escala, Color("#C9CDD8"))
		"cueva":
			if abierto < 1.0:
				lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -70), Vector2(90, 70)), Color("#3E3450"))
				for k in 3:
					lienzo.draw_circle(xf * Vector2(-40 + 40 * k, -80), 5.0, Color("#9EE6FF", 0.6 + 0.4 * sin(t * 3.0 + k)))
		"volcan":
			lienzo.draw_colored_polygon(xf * PackedVector2Array([Vector2(-74, -340), Vector2(74, -340), Vector2(50, -300), Vector2(20, -320), Vector2(-10, -290), Vector2(-40, -320)]), Color("#FF8A3D"))
			for k in 3:
				var ph := fmod(t * 0.3 + k / 3.0, 1.0)
				lienzo.draw_colored_polygon(xf * elipse(Vector2(10 * sin(k), -360 - 180 * ph), Vector2(40, 30) * (0.6 + ph)), Color(1, 1, 1, 0.5 * (1.0 - ph)))
		"huesos":
			for q in [Vector2(-130, -41), Vector2(130, -87), Vector2(-130, -85), Vector2(130, -39)]:
				lienzo.draw_circle(xf * q, 16.0 * escala, Color("#FFF4DC"))
				lienzo.draw_arc(xf * q, 16.0 * escala, 0, TAU, 12, CONTORNO, fino, true)
		"geiser":
			lienzo.draw_colored_polygon(xf * elipse(Vector2(0, -14), Vector2(36, 8)), Color("#BDEBFF"))
		"nube":
			lienzo.draw_arc(xf * Vector2(-30, -70), 24.0 * escala, PI * 1.1, PI * 1.6, 8, Color("#DDEBFA"), fino, true)


static func _florcita(lienzo, c: Vector2, rad: float, color: Color) -> void:
	for k in 5:
		lienzo.draw_circle(c + Vector2.from_angle(TAU * k / 5.0 - PI / 2.0) * rad * 0.7, rad * 0.55, color)
	lienzo.draw_circle(c, rad * 0.45, Color("#FFD93D"))


# ---------------------------------------------------------------------------
# Animales
# ---------------------------------------------------------------------------

## `op`: {"feliz", "alfa", "tinte" (Color, camuflaje), "mezcla" (0-1), "squash" (0-1), "rot", "ojos_cerrados",
## "silueta" (Color: todo de un color, para las tarjetas)}.
static func dibujar_animal(lienzo, aspecto: Dictionary, pie: Vector2, tamano: float, espejo: bool, op := {}) -> void:
	var loc := G.animal_local(aspecto)
	var squash := float(op.get("squash", 0.0))
	var sx := tamano * (1.0 + 0.12 * squash) * (-1.0 if espejo else 1.0)
	var sy := tamano * (1.0 - 0.14 * squash)
	var xf := Transform2D(float(op.get("rot", 0.0)), Vector2(sx, sy), 0.0, pie)
	var alfa := float(op.get("alfa", 1.0))
	var silueta = op.get("silueta", null)
	var color := col(aspecto.get("color", "#E8A86B"), Color("#E8A86B"))
	var color2 := col(aspecto.get("color2", ""), color.lightened(0.45))
	var color3 := col(aspecto.get("color3", ""), Color("#FFB347"))
	if op.has("tinte"):
		var mezcla := float(op.get("mezcla", 0.35))
		color = color.lerp(op["tinte"], mezcla)
		color2 = color2.lerp(op["tinte"], mezcla)
	var trazo := clampf(tamano * 0.022, 1.6, 4.0)
	var polis: Array = []
	var colores: Array = []
	for prim in loc["partes"]:
		polis.append(xf * poligono_de(prim))
		var c := color
		match str(prim.get("rol", "cuerpo")):
			"pata":
				c = color.darkened(0.12)
			"hocico", "panza":
				c = color2
			"oreja":
				c = color.darkened(0.06)
			"pico", "detalle":
				c = color3
			"cuerno":
				c = col(aspecto.get("color_cuerno", ""), Color("#F3E3C3"))
			"caparazon", "volante":
				c = color2
		if silueta != null:
			c = silueta
		colores.append(c)
	masa(lienzo, polis, colores, trazo, alfa)
	if silueta != null:
		return
	# Volumen solo en cuerpo y cabeza.
	for i in polis.size():
		var rol := str(loc["partes"][i].get("rol", ""))
		if rol in ["cuerpo", "cabeza", "caparazon"]:
			volumen(lienzo, polis[i], colores[i], Vector2(-0.025 * absf(sx), -0.04 * sy), alfa)
	var cuerpo: Dictionary = loc["partes"][0]
	for prim in loc["partes"]:
		if str(prim.get("rol", "")) in ["cuerpo", "caparazon"]:
			cuerpo = prim
			break
	_patron(lienzo, aspecto, cuerpo, xf, color, color2, alfa, trazo)
	_accesorios_atras(lienzo, aspecto, loc, xf, alfa, trazo)
	_cara(lienzo, aspecto, loc, xf, tamano, alfa, bool(op.get("feliz", false)), bool(op.get("ojos_cerrados", false)))
	_accesorios(lienzo, aspecto, loc, xf, alfa, trazo, color3)


static func _patron(lienzo, aspecto: Dictionary, cuerpo: Dictionary, xf: Transform2D, color: Color, color2: Color, alfa: float, trazo: float) -> void:
	if int(cuerpo["t"]) != G.ELIPSE:
		return
	var c: Vector2 = cuerpo["c"]
	var rr: Vector2 = cuerpo["r"]
	var oscuro := col(aspecto.get("color_patron", ""), color.darkened(0.45))
	match str(aspecto.get("patron", "")):
		"panza":
			rellenar(lienzo, xf * elipse(c + Vector2(rr.x * 0.1, rr.y * 0.3), rr * Vector2(0.62, 0.55)), Color(color2, alfa))
		"rayas":
			for k in 5:
				var x := c.x - rr.x * 0.6 + rr.x * 0.3 * k
				lienzo.draw_line(xf * Vector2(x, c.y - rr.y * 0.75), xf * Vector2(x + rr.x * 0.06, c.y + rr.y * 0.3), Color(oscuro, alfa), trazo * 2.4, true)
		"manchas":
			for q in [Vector2(-0.45, -0.2), Vector2(0.1, -0.35), Vector2(0.4, 0.1), Vector2(-0.15, 0.25), Vector2(0.15, 0.0)]:
				rellenar(lienzo, xf * elipse(c + q * rr, rr * Vector2(0.16, 0.2), 12), Color(oscuro, alfa))
		"manchas_claras":
			for q in [Vector2(-0.45, -0.2), Vector2(0.1, -0.35), Vector2(0.4, 0.1), Vector2(-0.15, 0.25)]:
				rellenar(lienzo, xf * elipse(c + q * rr, rr * Vector2(0.16, 0.18), 12), Color(1, 1, 1, 0.85 * alfa))
		"caparazon":
			for q in [Vector2(-0.4, -0.2), Vector2(0.1, -0.45), Vector2(0.45, -0.1), Vector2(-0.05, 0.0)]:
				trazar(lienzo, xf * elipse(c + q * rr, rr * Vector2(0.2, 0.2), 6), trazo, Color(oscuro, alfa))
		"plumas":
			for k in 3:
				lienzo.draw_arc(xf * (c + Vector2(-0.2 + 0.25 * k, 0.1) * rr), rr.x * absf(xf.x.x) * 0.25, PI * 0.1, PI * 0.9, 8, Color(oscuro, alfa * 0.7), trazo, true)
		"pijama":
			for k in 5:
				var x2 := c.x - rr.x * 0.6 + rr.x * 0.3 * k
				lienzo.draw_line(xf * Vector2(x2, c.y - rr.y * 0.8), xf * Vector2(x2, c.y + rr.y * 0.6), Color(col(aspecto.get("color_patron", "#7FB2FF"), Color("#7FB2FF")), alfa), trazo * 2.6, true)


static func _accesorios_atras(lienzo, aspecto: Dictionary, loc: Dictionary, xf: Transform2D, alfa: float, trazo: float) -> void:
	var cab: Vector2 = loc["cabeza"]
	var rc: float = loc["radio_cabeza"]
	if bool(aspecto.get("crin", false)):
		var cc := col(aspecto.get("color_crin", ""), col(aspecto.get("color", "#E8A86B"), Color.BROWN).darkened(0.35))
		for k in 4:
			var q := cab + Vector2(-rc * (0.5 + 0.35 * k), -rc * (0.7 - 0.3 * k))
			rellenar(lienzo, xf * elipse(q, Vector2(rc * 0.32, rc * 0.42), 12), Color(cc, alfa))
	if str(aspecto.get("forma", "")) == "dino_bipedo" and bool(aspecto.get("puas", true)):
		for k in 3:
			var q2 := cab + Vector2(-rc * (1.2 + 0.5 * k), rc * (0.6 + 0.4 * k))
			rellenar(lienzo, xf * PackedVector2Array([q2 + Vector2(-rc * 0.2, 0), q2 + Vector2(0, -rc * 0.35), q2 + Vector2(rc * 0.2, 0)]), Color(col(aspecto.get("color3", "#FFB347"), Color.ORANGE), alfa))


static func _cara(lienzo, aspecto: Dictionary, loc: Dictionary, xf: Transform2D, tamano: float, alfa: float, feliz: bool, cerrados: bool) -> void:
	var cab: Vector2 = loc["cabeza"]
	var rc: float = loc["radio_cabeza"]
	var frente: bool = loc["frente"]
	var esc := rc * 2.0
	var tinta := Color(CONTORNO, alfa)
	var grosor := maxf(1.6, tamano * esc * 0.06)
	var ojos: Array = []
	if frente:
		ojos = [cab + Vector2(-esc * 0.24, -esc * 0.02), cab + Vector2(esc * 0.24, -esc * 0.02)]
	else:
		ojos = [cab + Vector2(esc * 0.18, -esc * 0.1)]
	if str(aspecto.get("forma", "")) == "huevo":
		ojos = [cab + Vector2(-esc * 0.2, 0), cab + Vector2(esc * 0.2, 0)]
	for ojo in ojos:
		var o: Vector2 = xf * ojo
		var ro := tamano * esc * 0.095
		if feliz or cerrados:
			lienzo.draw_arc(o + Vector2(0, ro * 0.4), ro, PI * 1.15, PI * 1.85, 10, tinta, grosor, true)
		else:
			lienzo.draw_colored_polygon(elipse(o, Vector2(ro * 0.85, ro * 1.1), 14), tinta)
			lienzo.draw_circle(o + Vector2(-ro * 0.3, -ro * 0.4), ro * 0.36, Color(1, 1, 1, alfa))
	# Mejillas.
	for ojo in ojos:
		var m: Vector2 = xf * (ojo + Vector2(0, esc * 0.2))
		lienzo.draw_colored_polygon(elipse(m, Vector2(tamano * esc * 0.09, tamano * esc * 0.055), 12), Color(RUBOR, RUBOR.a * alfa))
	# Nariz y sonrisa en el hocico.
	var h: Vector2 = loc["hocico"]
	var forma := str(aspecto.get("forma", ""))
	if forma in ["ave", "nadador", "zancuda", "pinguino"]:
		return
	var hn: Vector2 = xf * h
	if forma != "huevo" and forma != "pez" and forma != "ballena" and forma != "dino_bipedo":
		lienzo.draw_colored_polygon(elipse(hn + xf.basis_xform(Vector2(rc * 0.25 if not frente else 0.0, -rc * 0.1)), Vector2(tamano * rc * 0.13, tamano * rc * 0.09), 10), tinta)
	var boca: Vector2 = xf * (h + Vector2(0, rc * 0.28))
	lienzo.draw_arc(boca, tamano * rc * 0.2, PI * 0.15, PI * 0.85, 10, tinta, grosor, true)


static func _accesorios(lienzo, aspecto: Dictionary, loc: Dictionary, xf: Transform2D, alfa: float, trazo: float, color3: Color) -> void:
	var cab: Vector2 = loc["cabeza"]
	var rc: float = loc["radio_cabeza"]
	match str(aspecto.get("accesorio", "")):
		"casco_bombero":
			var casco := xf * elipse(cab + Vector2(0, -rc * 0.75), Vector2(rc * 1.0, rc * 0.5), 18)
			trazar(lienzo, casco, trazo * 2.0, Color(CONTORNO, alfa))
			rellenar(lienzo, casco, Color(Color("#E8434B"), alfa))
			rellenar(lienzo, xf * elipse(cab + Vector2(0, -rc * 0.75), Vector2(rc * 0.22, rc * 0.28), 10), Color(Color("#FFCB3D"), alfa))
		"gorro_pijama":
			var gorro := xf * PackedVector2Array([cab + Vector2(-rc * 0.8, -rc * 0.55), cab + Vector2(rc * 0.8, -rc * 0.6), cab + Vector2(-rc * 0.6, -rc * 1.8)])
			trazar(lienzo, gorro, trazo * 2.0, Color(CONTORNO, alfa))
			rellenar(lienzo, gorro, Color(Color("#7FB2FF"), alfa))
			lienzo.draw_circle(xf * (cab + Vector2(-rc * 0.6, -rc * 1.8)), rc * 0.22 * absf(xf.x.x), Color(1, 1, 1, alfa))
		"costuras":
			lienzo.draw_line(xf * (cab + Vector2(0, -rc * 0.9)), xf * (cab + Vector2(0, -rc * 0.3)), Color(Color("#FFFFFF"), alfa), trazo, true)
			lienzo.draw_circle(xf * (cab + Vector2(0, rc * 1.3)), rc * 0.12 * absf(xf.x.x), Color(Color("#FFCB3D"), alfa))
		"estrellas":
			for k in 4:
				var q := xf * (cab + Vector2(-rc * (0.6 + 0.4 * k), -rc * (0.6 - 0.35 * k)))
				_estrellita(lienzo, q, rc * 0.28 * absf(xf.y.y), Color(Color("#FFE38A"), alfa))
		"cuerno_unicornio":
			pass
		"manchas_huevo":
			pass
	if str(aspecto.get("forma", "")) == "huevo":
		for q in [Vector2(-0.12, -0.75), Vector2(0.14, -0.62), Vector2(-0.16, -0.3), Vector2(0.15, -0.2)]:
			rellenar(lienzo, xf * elipse(q, Vector2(0.06, 0.05), 10), Color(color3, alfa))


static func _estrellita(lienzo, c: Vector2, rad: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var rr := rad if k % 2 == 0 else rad * 0.45
		pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * rr)
	lienzo.draw_colored_polygon(pts, color)


## Toby provisional dibujado (si no hay sprite): perrito beagle con casco y antena (HE-A4b).
static func estrella(lienzo, c: Vector2, rad: float, color: Color) -> void:
	_estrellita(lienzo, c, rad, color)
