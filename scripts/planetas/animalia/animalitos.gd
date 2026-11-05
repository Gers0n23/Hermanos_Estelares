extends RefCounted

## Animalitos del mapa del Planeta Animalia dibujados en código (HE-120; el arte final es de HE-114).
##
## Los usa `paisaje_animalia.gd` para los vecinos de cada hito (duermen la siesta, bostezan, bailan),
## el desfile del sendero y el Gran Desfile. Estilo "sticker": formas redondas con un solo contorno
## suave alrededor de toda la silueta, ojos con brillito y cachetes. Sin bichos ni depredadores que
## asusten (ficha de zonas §3): los dinos carnívoros de Maxi van redondos y sonrientes.
##
## Uso: Animalitos.dibujar(lienzo, "jirafa", pie, alto, {"dir": -1, "paso": t * 9.0})
##   pie    punto donde apoya los pies (abajo al centro)
##   alto   alto en px de un animal de escala 1 (cada especie tiene su propia `escala`)
##   estado dir (1 mira a la derecha, -1 a la izquierda), dormido, paso (fase de caminar o -1 quieto),
##          bostezo (0..1), salto (px hacia arriba), estirar (0..1 aplasta/estira), medio (siesta: medio tono)

const CONTORNO := Color("#3a3550")
const CACHETE := Color("#ff8fae")

## Especies: plan del cuerpo, colores y rasgos. Los nombres son los de `zonas[].desfile` en mapa.json.
const ESPECIES := {
	"vaca": {"plan": "cuad", "cuerpo": "#ffffff", "hocico": "#ffc6cc", "rasgos": ["manchas", "cuernos", "orejas_lado"], "mancha": "#4a4458"},
	"perro": {"plan": "cuad", "cuerpo": "#e0aa6e", "hocico": "#fff1dc", "rasgos": ["orejas_caidas", "cola_arriba"], "oreja": "#9a6236", "escala": 0.8},
	"gato": {"plan": "cuad", "cuerpo": "#ffb066", "hocico": "#fff1dc", "rasgos": ["orejas_punta", "cola_arriba", "rayitas"], "mancha": "#e0823a", "escala": 0.7},
	"pato": {"plan": "ave", "cuerpo": "#ffe14d", "pico": "#ff9f3a", "escala": 0.6},
	"caballo": {"plan": "cuad", "cuerpo": "#c07a42", "hocico": "#e8b088", "rasgos": ["melena", "orejas_punta", "cabeza_larga", "cola_crin"], "melena": "#5a3a24", "escala": 1.1},
	"pony": {"plan": "cuad", "cuerpo": "#ffb8da", "hocico": "#ffe0ee", "rasgos": ["melena", "orejas_punta", "cabeza_larga", "cola_crin"], "melena": "#b48ce8", "escala": 0.85},
	"flamenco": {"plan": "ave", "cuerpo": "#ff8fb8", "pico": "#3a3550", "rasgos": ["patas_largas", "cuello_largo"], "escala": 1.05},
	"hipopotamo": {"plan": "cuad", "cuerpo": "#b3a6dc", "hocico": "#d8ccf4", "rasgos": ["orejitas", "ancho", "patas_cortas"], "escala": 0.95},
	"lobo_marino": {"plan": "foca", "cuerpo": "#9aa0b8", "escala": 0.8},
	"pinguino": {"plan": "pinguino", "cuerpo": "#3a4060", "panza": "#ffffff", "pico": "#ff9f3a", "escala": 0.72},
	"perrito_bombero": {"plan": "cuad", "cuerpo": "#ffffff", "hocico": "#ffffff", "rasgos": ["orejas_caidas", "manchas", "casco_bombero", "cola_arriba"], "oreja": "#3a3550", "mancha": "#3a3550", "escala": 0.82},
	"jirafa": {"plan": "cuad", "cuerpo": "#ffd36b", "hocico": "#f2b866", "rasgos": ["cuello_largo", "manchas", "osiconos", "orejas_punta"], "mancha": "#d08a40", "escala": 1.25},
	"jirafita": {"plan": "cuad", "cuerpo": "#ffdc80", "hocico": "#f2b866", "rasgos": ["cuello_largo", "manchas", "osiconos", "orejas_punta"], "mancha": "#d89a50", "escala": 0.8},
	"cebra": {"plan": "cuad", "cuerpo": "#ffffff", "hocico": "#d6d6e6", "rasgos": ["rayas", "melena", "orejas_punta", "cabeza_larga", "cola_crin"], "melena": "#3a3550", "mancha": "#3a3550", "escala": 1.0},
	"elefante": {"plan": "cuad", "cuerpo": "#aeb8cc", "rasgos": ["trompa", "orejas_grandes", "ancho"], "escala": 1.15},
	"alpaca": {"plan": "cuad", "cuerpo": "#fff1d6", "hocico": "#f2dcb6", "rasgos": ["cuello_medio", "lanudo", "orejas_punta"], "escala": 1.0},
	"huemul": {"plan": "cuad", "cuerpo": "#b07c4e", "hocico": "#e8c9a0", "rasgos": ["astas", "orejas_punta"], "escala": 1.0},
	"triceratops": {"plan": "dino", "cuerpo": "#86d07e", "rasgos": ["frill", "cuernos_tri", "cuatro_patas"], "frill": "#ffb36b", "escala": 1.0},
	"mono": {"plan": "mono", "cuerpo": "#a8754a", "cara": "#f2d3a6", "escala": 0.75},
	"tucan": {"plan": "ave", "cuerpo": "#3a4060", "pecho": "#fff2a0", "pico": "#ff9f3a", "rasgos": ["pico_grande"], "escala": 0.72},
	"loro": {"plan": "ave", "cuerpo": "#5fcf6a", "cabeza": "#ff5a5a", "pico": "#ffe066", "rasgos": ["cola_larga"], "escala": 0.78},
	"buho": {"plan": "buho", "cuerpo": "#b08860", "panza": "#f2dcb6", "escala": 0.72},
	"perezoso": {"plan": "mono", "cuerpo": "#c9a77c", "cara": "#f2e2c6", "rasgos": ["antifaz"], "escala": 0.8},
	"condor": {"plan": "ave", "cuerpo": "#3a3550", "cabeza": "#ffb3a0", "pico": "#f2e2c6", "rasgos": ["collar_blanco"], "escala": 0.95},
	"braquiosaurio": {"plan": "dino", "cuerpo": "#8fc7e8", "rasgos": ["cuello_dino", "cuatro_patas"], "escala": 1.35},
	"trex": {"plan": "dino", "cuerpo": "#6fcf7a", "rasgos": ["cabezon", "bracitos"], "escala": 1.15},
	"spinosaurio": {"plan": "dino", "cuerpo": "#5fb8c8", "rasgos": ["vela", "hocico_largo", "bracitos"], "vela": "#ff9f6a", "escala": 1.15},
	"carnotauro": {"plan": "dino", "cuerpo": "#ff8a6a", "rasgos": ["cuernitos", "cabezon", "bracitos"], "escala": 1.1},
	"dinito": {"plan": "dino", "cuerpo": "#a6e68e", "rasgos": ["cabezon", "cascaron"], "escala": 0.55},
	"pony_estelar": {"plan": "cuad", "cuerpo": "#f3ecff", "hocico": "#ffe6f4", "rasgos": ["melena", "orejas_punta", "cabeza_larga", "cola_crin", "estrellas"], "melena": "#ffd23f", "escala": 0.9},
}


## Dibuja un animal. Las especies desconocidas se dibujan como un perrito (nunca rompe el mapa).
static func dibujar(lienzo: CanvasItem, especie: String, pie: Vector2, alto: float, estado := {}) -> void:
	var datos: Dictionary = ESPECIES.get(especie, ESPECIES["perro"])
	var d := Dibujante.new(lienzo, datos, pie, alto * float(datos.get("escala", 1.0)) / 60.0, estado)
	d.dibujar()


## Alto aproximado en px de una especie dibujada con `alto` (para ubicar zzz o globitos encima).
static func alto_de(especie: String, alto: float) -> float:
	var datos: Dictionary = ESPECIES.get(especie, ESPECIES["perro"])
	var base := 46.0
	var rasgos: Array = datos.get("rasgos", [])
	if "cuello_largo" in rasgos or "cuello_dino" in rasgos:
		base = 74.0
	elif "patas_largas" in rasgos:
		base = 64.0
	return base * alto * float(datos.get("escala", 1.0)) / 60.0


class Dibujante:
	var lienzo: CanvasItem
	var datos: Dictionary
	var rasgos: Array
	var pie: Vector2
	var u: float
	var dir := 1.0
	var dormido := false
	var paso := -1.0
	var bostezo := 0.0
	var estirar := 0.0
	var medio := false
	## Formas con contorno común (se pintan todos los contornos y después todos los rellenos).
	var _formas: Array = []
	## Detalles sin contorno, encima (ojos, manchas, brillos).
	var _detalles: Array = []

	func _init(p_lienzo: CanvasItem, p_datos: Dictionary, p_pie: Vector2, p_u: float, estado: Dictionary) -> void:
		lienzo = p_lienzo
		datos = p_datos
		rasgos = p_datos.get("rasgos", [])
		u = p_u
		dir = -1.0 if float(estado.get("dir", 1.0)) < 0.0 else 1.0
		dormido = bool(estado.get("dormido", false))
		paso = float(estado.get("paso", -1.0))
		bostezo = clampf(float(estado.get("bostezo", 0.0)), 0.0, 1.0)
		estirar = float(estado.get("estirar", 0.0))
		medio = bool(estado.get("medio", false))
		pie = p_pie - Vector2(0, float(estado.get("salto", 0.0)))

	# --- colores y coordenadas ---------------------------------------------------------------

	func col(clave: String, respaldo := "#ffffff") -> Color:
		return tono(Color(str(datos.get(clave, respaldo))))

	## Siesta: colores a medio tono (como los hitos `_gris`).
	func tono(c: Color) -> Color:
		if not medio:
			return c
		var luz := c.get_luminance()
		return c.lerp(Color(luz, luz, luz * 1.02), 0.6).lerp(Color("#f4efe4"), 0.25)

	## Punto local (x hacia donde mira, y hacia arriba negativo) a pantalla, con aplastado.
	func p(x: float, y: float) -> Vector2:
		var sx := 1.0 + estirar * 0.12
		var sy := 1.0 - estirar * 0.12
		return pie + Vector2(x * dir * sx, y * sy) * u

	# --- primitivas ----------------------------------------------------------------------------

	func elipse(c: Vector2, rx: float, ry: float, color: Color, angulo := 0.0, contorno := true) -> void:
		var forma := {"t": "e", "c": c, "rx": rx, "ry": ry, "a": angulo * dir, "col": color}
		(_formas if contorno else _detalles).append(forma)

	func circulo(c: Vector2, r: float, color: Color, contorno := true) -> void:
		elipse(c, r, r, color, 0.0, contorno)

	func poligono(puntos: Array, color: Color, contorno := true) -> void:
		var forma := {"t": "p", "puntos": PackedVector2Array(puntos), "col": color}
		(_formas if contorno else _detalles).append(forma)

	func linea(a: Vector2, b: Vector2, ancho: float, color: Color, contorno := true) -> void:
		var forma := {"t": "l", "a": a, "b": b, "w": ancho, "col": color}
		(_formas if contorno else _detalles).append(forma)

	func _puntos_elipse(f: Dictionary, extra: float) -> PackedVector2Array:
		var puntos := PackedVector2Array()
		var lados := 20
		var rx: float = f["rx"] * u + extra
		var ry: float = f["ry"] * u + extra
		for k in lados:
			var a := TAU * k / lados
			puntos.append(f["c"] + Vector2(cos(a) * rx, sin(a) * ry).rotated(f["a"]))
		return puntos

	func _pintar(f: Dictionary, extra: float, color: Color) -> void:
		match str(f["t"]):
			"e":
				if is_equal_approx(f["rx"], f["ry"]):
					lienzo.draw_circle(f["c"], f["rx"] * u + extra, color)
				else:
					lienzo.draw_colored_polygon(_puntos_elipse(f, extra), color)
			"p":
				var puntos: PackedVector2Array = f["puntos"]
				if extra > 0.0:
					var cerrado := puntos.duplicate()
					cerrado.append(puntos[0])
					lienzo.draw_polyline(cerrado, color, extra * 2.0, true)
				lienzo.draw_colored_polygon(puntos, color)
			"l":
				var ancho: float = f["w"] * u + extra * 2.0
				lienzo.draw_line(f["a"], f["b"], color, ancho, true)
				lienzo.draw_circle(f["a"], ancho / 2.0, color)
				lienzo.draw_circle(f["b"], ancho / 2.0, color)

	func _volcar() -> void:
		var grosor := maxf(1.2, 1.9 * u)
		var trazo := tono(CONTORNO)
		for f in _formas:
			_pintar(f, grosor, trazo)
		for f in _formas:
			_pintar(f, 0.0, f["col"])
		for f in _detalles:
			_pintar(f, 0.0, f["col"])

	# --- cara ---------------------------------------------------------------------------------

	func ojo(c: Vector2, r := 2.3) -> void:
		var tinta := tono(CONTORNO)
		if dormido:
			var a := c + Vector2(-r * 1.1, 0) * u
			var b := c + Vector2(r * 1.1, 0) * u
			lienzo.draw_polyline(PackedVector2Array([a, c + Vector2(0, r * 0.9) * u, b]), tinta, maxf(1.2, 1.1 * u), true)
			return
		lienzo.draw_circle(c, r * u, tinta)
		lienzo.draw_circle(c + Vector2(-0.7 * dir, -0.8) * u, r * 0.38 * u, Color.WHITE)

	func cachete(c: Vector2) -> void:
		var forma := {"t": "e", "c": c, "rx": 2.6, "ry": 1.6, "a": 0.0, "col": Color(tono(CACHETE), 0.75)}
		_pintar(forma, 0.0, forma["col"])

	func boca(c: Vector2, ancho := 2.4) -> void:
		var tinta := tono(CONTORNO)
		if bostezo > 0.05:
			var forma := {"t": "e", "c": c + Vector2(0, 1.2 * bostezo) * u, "rx": 1.6 + bostezo * 1.2, "ry": 1.2 + bostezo * 2.2, "a": 0.0, "col": Color("#7a3a4a")}
			_pintar(forma, 0.0, forma["col"])
			return
		if dormido:
			return
		var a := c + Vector2(-ancho, -0.4) * u
		var b := c + Vector2(ancho, -0.4) * u
		lienzo.draw_polyline(PackedVector2Array([a, c + Vector2(0, 1.4) * u, b]), tinta, maxf(1.0, 0.9 * u), true)

	## Cara de perfil a 3/4: un ojo, cachete y boquita, en la cabeza `c` de radio `r`.
	func cara(c: Vector2, r: float, ojo_x := 0.25, boca_x := 0.55) -> void:
		ojo(c + Vector2(r * ojo_x * dir, -r * 0.18) * u)
		cachete(c + Vector2(r * (ojo_x + 0.05) * dir, r * 0.32) * u)
		boca(c + Vector2(r * boca_x * dir, r * 0.42) * u)

	# --- planes de cuerpo -----------------------------------------------------------------------

	func dibujar() -> void:
		match str(datos.get("plan", "cuad")):
			"ave":
				_ave()
			"pinguino":
				_pinguino()
			"buho":
				_buho()
			"foca":
				_foca()
			"mono":
				_mono()
			"dino":
				_dino()
			_:
				_cuadrupedo()
		_volcar()
		_extras()

	func _pata(x: float, arriba: float, largo: float, ancho: float, color: Color, fase: float) -> void:
		var dx := 0.0
		var alza := 0.0
		if paso >= 0.0:
			dx = sin(paso + fase) * 3.0
			alza = maxf(0.0, cos(paso + fase)) * 2.5
		linea(p(x + dx * 0.3, -arriba), p(x + dx, -alza - ancho * 0.5), ancho, color)

	func _cuadrupedo() -> void:
		var cuerpo := col("cuerpo")
		var oscuro := cuerpo.darkened(0.12)
		var ancho := "ancho" in rasgos
		var cortas := "patas_cortas" in rasgos
		var largo_pata := 9.0 if cortas else 14.0
		var cy := -largo_pata - 9.0
		var rx := 22.0 if ancho else 18.0
		var ry := 13.0 if ancho else 11.0
		if dormido:
			cy = -ry + 1.0
		# Patas (las de atrás un poco más oscuras).
		if not dormido:
			var grosor := 7.0 if ancho else 5.5
			for k in 4:
				var x: float = [-rx * 0.62, -rx * 0.3, rx * 0.36, rx * 0.66][k]
				_pata(x, -cy - ry * 0.4, largo_pata, grosor, oscuro if k % 2 == 1 else cuerpo, k * PI * 0.5 + (PI if k > 1 else 0.0))
		# Cola.
		if "cola_crin" in rasgos:
			var m := col("melena", "#5a3a24")
			poligono([p(-rx + 2, cy - 4), p(-rx - 12, cy + 2 + sin(paso) * 2.0), p(-rx - 8, cy + 12), p(-rx + 1, cy + 2)], m)
		elif "cola_arriba" in rasgos:
			linea(p(-rx + 2, cy - 2), p(-rx - 6, cy - 12 + (sin(paso * 2.0) * 2.0 if paso >= 0.0 else 0.0)), 3.2, cuerpo)
		elif "trompa" in rasgos or "ancho" in rasgos:
			linea(p(-rx + 1, cy - 2), p(-rx - 5, cy + 4), 2.4, oscuro)
		else:
			elipse(p(-rx - 1, cy - 3), 4.0, 3.0, oscuro, -0.5)
		# Cuerpo.
		elipse(p(0, cy), rx, ry, cuerpo)
		if "lanudo" in rasgos:
			for k in 5:
				circulo(p(-rx * 0.7 + k * rx * 0.35, cy - ry * 0.75), 5.0, cuerpo)
		# Cuello y cabeza.
		var cabeza := p(rx * 0.95, cy - ry * 0.9)
		var radio := 10.0
		if "cuello_largo" in rasgos:
			var alto_cuello := 22.0 if dormido else 34.0
			cabeza = p(rx * 1.05 + 4.0, cy - ry - alto_cuello)
			poligono([p(rx * 0.4, cy - 4), p(rx * 0.95, cy - 6), p(rx * 1.05 + 9.0, cy - ry - alto_cuello + 4), p(rx * 1.05, cy - ry - alto_cuello + 2)], cuerpo)
			radio = 8.5
		elif "cuello_medio" in rasgos:
			cabeza = p(rx * 1.0 + 2.0, cy - ry - 16.0)
			poligono([p(rx * 0.45, cy - 5), p(rx * 0.95, cy - 6), p(rx * 1.0 + 7.0, cy - ry - 14), p(rx * 1.0 - 3.0, cy - ry - 13)], cuerpo)
			radio = 8.5
		if dormido and not "cuello_largo" in rasgos:
			cabeza = p(rx * 0.85, cy + 1.0)
		# Orejas detrás de la cabeza.
		if "orejas_grandes" in rasgos:
			elipse(cabeza + Vector2(-6.0 * dir, 1.0) * u, 9.0, 11.0, oscuro, 0.2)
		if "orejas_punta" in rasgos:
			for lado in [-1.0, 1.0]:
				var base := cabeza + Vector2((lado * 4.0 - 2.0) * dir, -radio * 0.75) * u
				poligono([base + Vector2(-3.0, 0) * u, base + Vector2((lado * 1.5) * dir, -8.0) * u, base + Vector2(3.0, 0) * u], cuerpo)
		if "orejas_lado" in rasgos:
			elipse(cabeza + Vector2(-radio * 0.9 * dir, -radio * 0.4) * u, 5.0, 2.6, cuerpo, -0.3)
		if "orejitas" in rasgos:
			circulo(cabeza + Vector2(-3.0 * dir, -radio * 0.95) * u, 3.0, oscuro)
		if "astas" in rasgos:
			var asta := col("asta", "#e8d2a6")
			for lado in [-1.0, 1.0]:
				var base := cabeza + Vector2((lado * 3.0 - 1.0) * dir, -radio * 0.8) * u
				linea(base, base + Vector2(lado * 4.0 * dir, -10.0) * u, 2.2, asta)
				linea(base + Vector2(lado * 2.0 * dir, -5.0) * u, base + Vector2(lado * 7.0 * dir, -7.0) * u, 2.0, asta)
		if "osiconos" in rasgos:
			for lado in [-1.0, 1.0]:
				var base := cabeza + Vector2((lado * 2.6) * dir, -radio * 0.8) * u
				linea(base, base + Vector2(0, -5.0) * u, 2.0, col("mancha", "#d08a40"))
		if "cuernos" in rasgos:
			for lado in [-1.0, 1.0]:
				var base := cabeza + Vector2((lado * 4.0) * dir, -radio * 0.8) * u
				poligono([base + Vector2(-1.8, 0) * u, base + Vector2(lado * 3.0 * dir, -5.0) * u, base + Vector2(1.8, 0) * u], Color("#f5e6b8"))
		# Cabeza (larga en caballos y cebras).
		if "cabeza_larga" in rasgos:
			elipse(cabeza + Vector2(3.0 * dir, 2.0) * u, radio * 1.15, radio * 0.85, cuerpo, 0.45)
		else:
			circulo(cabeza, radio, cuerpo)
		if "melena" in rasgos:
			var m := col("melena", "#5a3a24")
			for k in 4:
				circulo(cabeza + Vector2((-radio * 0.5 - k * 3.0) * dir, -radio * 0.6 + k * 4.0) * u, 4.2, m)
		# Hocico, trompa y orejas caídas por delante.
		var hocico := cabeza + Vector2(radio * 0.75 * dir, radio * 0.35) * u
		if "trompa" in rasgos:
			var punta := cabeza + Vector2((radio + 6.0) * dir, radio + (2.0 if dormido else 8.0)) * u
			linea(cabeza + Vector2(radio * 0.6 * dir, radio * 0.3) * u, punta, 5.0, cuerpo)
			linea(punta, punta + Vector2(3.0 * dir, -3.0) * u, 4.0, cuerpo)
		elif "cabeza_larga" in rasgos:
			elipse(cabeza + Vector2(radio * 0.95 * dir, radio * 0.55) * u, 5.5, 4.2, col("hocico", "#e8b088"))
		elif datos.has("hocico"):
			elipse(hocico, 5.5, 4.0, col("hocico"))
		if "orejas_caidas" in rasgos:
			elipse(cabeza + Vector2(-radio * 0.55 * dir, radio * 0.1) * u, 3.6, 6.5, col("oreja", "#9a6236"), 0.25)
		if "casco_bombero" in rasgos:
			poligono([cabeza + Vector2(-radio - 2.0, -radio * 0.35) * u, cabeza + Vector2(-radio * 0.6, -radio * 1.25) * u,
				cabeza + Vector2(radio * 0.6, -radio * 1.25) * u, cabeza + Vector2(radio + 2.0, -radio * 0.35) * u], tono(Color("#ff4a4a")))
		# Detalles del pelaje.
		var mancha := col("mancha", "#4a4458")
		if "manchas" in rasgos:
			for v in [Vector2(-0.4, -0.2), Vector2(0.15, 0.25), Vector2(0.45, -0.35), Vector2(-0.05, -0.55)]:
				elipse(p(rx * v.x, cy + ry * v.y), 3.6, 2.8, mancha, 0.3, false)
			if "cuello_largo" in rasgos:
				for k in 3:
					elipse(p(rx * 0.95 + 3.0 + k * 1.0, cy - ry - 6.0 - k * 9.0), 2.2, 1.8, mancha, 0.0, false)
		if "rayas" in rasgos or "rayitas" in rasgos:
			for k in 4:
				var x := -rx * 0.55 + k * rx * 0.36
				linea(p(x, cy - ry * 0.85), p(x + 2.0, cy + ry * 0.2), 2.2 if "rayas" in rasgos else 1.6, mancha, false)
		if "estrellas" in rasgos:
			for k in 3:
				var c := p(-rx * 0.5 + k * rx * 0.45, cy - ry * 0.1 + (k % 2) * 4.0)
				lienzo.draw_colored_polygon(_estrella(c, 2.6 * u), tono(Color("#ffd23f")))
		_cara_en = cabeza
		_radio_cara = radio

	var _cara_en := Vector2.ZERO
	var _radio_cara := 0.0

	func _extras() -> void:
		if _es_ave:
			# Las aves: ojo y cachete, sin boquita (el pico ya sonríe).
			ojo(_cara_en + Vector2(_radio_cara * 0.15 * dir, -_radio_cara * 0.2) * u, 1.9)
			cachete(_cara_en + Vector2(_radio_cara * 0.1 * dir, _radio_cara * 0.4) * u)
		elif _radio_cara < 0.0:
			# Búho: dos ojos grandes de frente.
			for lado in [-1.0, 1.0]:
				ojo(_cara_en + Vector2(lado * 5.5, 0) * u, 2.6)
		elif _radio_cara > 0.0:
			cara(_cara_en, _radio_cara)
		if "estrellas" in rasgos and not dormido:
			# Brillitos que salen de la crin del pony estelar.
			for k in 3:
				var c := _cara_en + Vector2((-14.0 - k * 6.0) * dir, -6.0 + k * 5.0) * u
				lienzo.draw_colored_polygon(_estrella(c, (1.6 + k * 0.4) * u), Color(tono(Color("#ffe066")), 0.85))

	func _estrella(c: Vector2, r: float) -> PackedVector2Array:
		var puntos := PackedVector2Array()
		for k in 10:
			var radio := r if k % 2 == 0 else r * 0.45
			puntos.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * radio)
		return puntos

	func _ave() -> void:
		var cuerpo := col("cuerpo")
		var largas := "patas_largas" in rasgos
		var cy := -34.0 if largas else -12.0
		if dormido:
			cy = -10.0
		var patas := tono(Color("#ff9f3a")) if not largas else col("cuerpo").darkened(0.15)
		if not dormido:
			_pata(-3.0, -cy - 6.0, 0.0, 2.4, patas, 0.0)
			_pata(3.0, -cy - 6.0, 0.0, 2.4, patas, PI)
		# Cola.
		if "cola_larga" in rasgos:
			poligono([p(-10, cy - 2), p(-26, cy + 10), p(-20, cy + 12), p(-8, cy + 4)], tono(Color("#4a8be0")))
		else:
			poligono([p(-10, cy - 4), p(-19, cy - 9), p(-11, cy + 3)], cuerpo.darkened(0.08))
		elipse(p(0, cy), 13.0, 10.5, cuerpo)
		if datos.has("pecho"):
			elipse(p(5, cy + 1), 7.0, 7.0, col("pecho"))
		if "collar_blanco" in rasgos:
			elipse(p(7, cy - 9), 7.0, 3.5, tono(Color.WHITE))
		# Cabeza (con cuello largo en el flamenco).
		var cabeza := p(9, cy - 13)
		if "cuello_largo" in rasgos:
			var alto_cuello := 10.0 if dormido else 22.0
			linea(p(7, cy - 6), p(4, cy - 6 - alto_cuello * 0.6), 4.2, cuerpo)
			linea(p(4, cy - 6 - alto_cuello * 0.6), p(9, cy - 8 - alto_cuello), 4.2, cuerpo)
			cabeza = p(10, cy - 10 - alto_cuello)
		if dormido and not "cuello_largo" in rasgos:
			cabeza = p(8, cy - 7)
		var radio := 7.5
		circulo(cabeza, radio, col("cabeza", str(datos.get("cuerpo", "#ffffff"))))
		# Pico (grande y de banana en el tucán).
		var pico := col("pico", "#ff9f3a")
		var base := cabeza + Vector2(radio * 0.8 * dir, 0.5) * u
		if "pico_grande" in rasgos:
			poligono([base + Vector2(0, -3.5) * u, base + Vector2(15.0 * dir, -1.0) * u, base + Vector2(13.0 * dir, 2.0) * u, base + Vector2(0, 3.5) * u], pico)
		else:
			poligono([base + Vector2(0, -2.6) * u, base + Vector2(7.0 * dir, 0.6) * u, base + Vector2(0, 2.8) * u], pico)
		# Ala.
		var aleteo := sin(paso * 2.0) * 0.35 if paso >= 0.0 else 0.0
		elipse(p(-2, cy), 8.0, 5.5, cuerpo.darkened(0.12), -0.3 + aleteo)
		_cara_en = cabeza
		_radio_cara = radio
		_es_ave = true

	var _es_ave := false

	func _pinguino() -> void:
		var cuerpo := col("cuerpo")
		var cy := -17.0
		var bamboleo := sin(paso) * 0.12 if paso >= 0.0 else 0.0
		if not dormido:
			elipse(p(-4, -1.5), 4.0, 2.0, tono(Color("#ff9f3a")))
			elipse(p(4, -1.5), 4.0, 2.0, tono(Color("#ff9f3a")))
		elipse(p(0, cy), 11.0, 17.0, cuerpo, bamboleo)
		elipse(p(-10, cy + 1), 3.0, 8.0, cuerpo.darkened(0.1), 0.4 + bamboleo)
		poligono([p(9, cy - 9), p(17, cy - 7), p(9, cy - 5)], col("pico"))
		elipse(p(2, cy + 4), 7.5, 11.0, col("panza"), 0.0, false)
		_cara_en = p(3, cy - 8)
		_radio_cara = 7.0

	func _buho() -> void:
		var cuerpo := col("cuerpo")
		var cy := -15.0
		poligono([p(-9, cy - 10), p(-11, cy - 21), p(-3, cy - 13)], cuerpo)
		poligono([p(9, cy - 10), p(11, cy - 21), p(3, cy - 13)], cuerpo)
		circulo(p(0, cy), 15.0, cuerpo)
		elipse(p(0, cy + 5), 9.0, 8.0, col("panza"), 0.0, false)
		for lado in [-1.0, 1.0]:
			circulo(p(lado * 5.5, cy - 4), 5.2, tono(Color("#fff6e6")), false)
		poligono([p(-1.8, cy - 1), p(1.8, cy - 1), p(0, cy + 3)], tono(Color("#ff9f3a")), false)
		_cara_en = p(0, cy - 4)
		_radio_cara = -1.0

	func _foca() -> void:
		var cuerpo := col("cuerpo")
		var ondula := sin(paso * 1.5) * 2.0 if paso >= 0.0 else 0.0
		poligono([p(-16, -6), p(-26, -2 + ondula), p(-24, -10 + ondula)], cuerpo.darkened(0.1))
		elipse(p(-3, -9), 18.0, 8.5, cuerpo, -0.1)
		elipse(p(6, -4), 5.0, 2.4, cuerpo.darkened(0.1), 0.6)
		var cabeza := p(13, -19 if not dormido else -11)
		circulo(cabeza, 8.0, cuerpo)
		elipse(cabeza + Vector2(6.0 * dir, 2.5) * u, 4.0, 3.0, cuerpo.lightened(0.2))
		_cara_en = cabeza
		_radio_cara = 8.0

	func _mono() -> void:
		var cuerpo := col("cuerpo")
		var cy := -13.0
		var cola := sin(paso) * 2.0 if paso >= 0.0 else 0.0
		linea(p(-8, cy + 6), p(-17, cy - 4 + cola), 2.6, cuerpo)
		circulo(p(-17, cy - 7 + cola), 3.2, cuerpo)
		elipse(p(0, cy), 10.0, 12.0, cuerpo)
		if not dormido:
			linea(p(6, cy - 3), p(12, cy + 6 + cola), 3.2, cuerpo)
		var cabeza := p(2, cy - 18 if not dormido else cy - 12)
		for lado in [-1.0, 1.0]:
			circulo(cabeza + Vector2(lado * 9.5, 0) * u, 3.4, cuerpo)
		circulo(cabeza, 9.5, cuerpo)
		elipse(cabeza + Vector2(1.0 * dir, 2.0) * u, 6.5, 6.0, col("cara"), 0.0, false)
		if "antifaz" in rasgos:
			elipse(cabeza + Vector2(-2.0 * dir, -1.0) * u, 3.4, 2.2, tono(Color("#6a4a2a")), 0.0, false)
			elipse(cabeza + Vector2(4.0 * dir, -1.0) * u, 3.4, 2.2, tono(Color("#6a4a2a")), 0.0, false)
		_cara_en = cabeza
		_radio_cara = 9.5

	func _dino() -> void:
		var cuerpo := col("cuerpo")
		var oscuro := cuerpo.darkened(0.14)
		var cuatro := "cuatro_patas" in rasgos
		var cy := -24.0 if not dormido else -11.0
		# Patas gorditas.
		if not dormido:
			if cuatro:
				for k in 4:
					var x: float = [-13.0, -6.0, 8.0, 14.0][k]
					_pata(x, -cy - 6.0, 0.0, 7.0, oscuro if k % 2 == 1 else cuerpo, k * PI * 0.5)
			else:
				_pata(-5.0, -cy - 6.0, 0.0, 8.0, oscuro, PI)
				_pata(6.0, -cy - 6.0, 0.0, 8.0, cuerpo, 0.0)
		# Vela del spinosaurio y cola.
		if "vela" in rasgos:
			var vela := col("vela", "#ff9f6a")
			poligono([p(-14, cy - 6), p(-8, cy - 22), p(0, cy - 26), p(8, cy - 20), p(12, cy - 6)], vela)
		var cola := sin(paso) * 2.5 if paso >= 0.0 else 0.0
		poligono([p(-12, cy - 8), p(-38, cy + 8 + cola), p(-12, cy + 8)], cuerpo)
		elipse(p(-1, cy), 19.0, 13.0, cuerpo)
		elipse(p(4, cy + 5), 10.0, 6.0, cuerpo.lightened(0.25), 0.0, false)
		# Cuello largo del braquiosaurio.
		var cabeza := p(19, cy - 15)
		var radio := 10.0
		if "cuello_dino" in rasgos:
			var alto_cuello := 22.0 if dormido else 46.0
			poligono([p(8, cy - 10), p(16, cy - 4), p(30, cy - alto_cuello), p(22, cy - alto_cuello - 2)], cuerpo)
			cabeza = p(29, cy - alto_cuello - 3)
			radio = 7.0
		elif "cabezon" in rasgos:
			cabeza = p(19, cy - 14 if not dormido else cy - 4)
			radio = 12.0
		elif dormido:
			cabeza = p(18, cy - 4)
		if "frill" in rasgos:
			circulo(cabeza + Vector2(-6.0 * dir, -4.0) * u, 12.0, col("frill"))
			for k in 5:
				circulo(cabeza + (Vector2(-6.0 * dir, -4.0) + Vector2.from_angle(-PI * 0.9 + k * PI * 0.32) * 11.5) * u, 2.0, col("frill").lightened(0.3))
		if "bracitos" in rasgos and not dormido:
			linea(p(14, cy + 2), p(19, cy + 6 + cola * 0.3), 3.0, oscuro)
		if "hocico_largo" in rasgos:
			elipse(cabeza + Vector2(8.0 * dir, 3.0) * u, 9.0, 4.5, cuerpo, 0.0)
		circulo(cabeza, radio, cuerpo)
		if "cabezon" in rasgos:
			elipse(cabeza + Vector2(5.0 * dir, 5.0) * u, 8.0, 5.0, cuerpo)
		if "cuernos_tri" in rasgos:
			for v in [Vector2(-2, -9), Vector2(4, -9), Vector2(10, -2)]:
				var base := cabeza + Vector2(v.x * dir, v.y) * u
				poligono([base + Vector2(-1.8, 0) * u, base + Vector2(4.0 * dir, -6.0) * u, base + Vector2(1.8, 1.0) * u], tono(Color("#fff3d6")))
		if "cuernitos" in rasgos:
			for lado in [-1.0, 1.0]:
				var base := cabeza + Vector2((lado * 3.5 - 1.0) * dir, -radio * 0.85) * u
				poligono([base + Vector2(-1.8, 0) * u, base + Vector2(lado * 2.5 * dir, -5.0) * u, base + Vector2(1.8, 0) * u], tono(Color("#fff3d6")))
		# Lomo con escamitas redondas.
		if not "vela" in rasgos and not "cuello_dino" in rasgos:
			for k in 3:
				circulo(p(-9 + k * 7, cy - 12.5), 2.8, oscuro)
		if "cascaron" in rasgos:
			# Sombrerito de cáscara de huevo: recién nacido.
			var puntos: Array = []
			for v in [Vector2(-10, 0), Vector2(-8, -6), Vector2(-4, -3), Vector2(0, -8), Vector2(4, -3), Vector2(8, -6), Vector2(10, 0)]:
				puntos.append(cabeza + Vector2(v.x * dir, v.y - radio * 0.6) * u)
			poligono(puntos, tono(Color("#fff6e6")))
		_cara_en = cabeza
		_radio_cara = radio
