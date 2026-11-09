extends RefCounted

## Animales de Animalia dibujados por código (motor `topos`, «¿Quién habla?»). Arte PROVISIONAL hasta el
## catálogo de `disenador-personajes` (HE-114): cartoon redondo y tierno, contorno azul tinta como el resto
## del juego, ojos grandes con brillo, cachetes rosados y nada que asuste (los dinos carnívoros de Maxi son
## redondos, sonrientes y torpes; planeta-animalia-zonas.md §3).
##
## Todo se dibuja "asomado": desde la línea del hoyo (origen, y = 0) hacia arriba, en un alto nominal de 200
## unidades que se escala a `alto`. El motor pone la transformación (subir, respirar, aplastar) con
## `draw_set_transform` antes de llamar a `dibujar()`.
##
## Cada animal es una ficha de datos en `CATALOGO` (forma, colores, orejas, hocico y extras): agregar uno
## nuevo no pide código. Un id que no está en el catálogo se dibuja como un perrito genérico y avisa.

const CONTORNO := Color("#2B3350")
const CACHETE := Color(1.0, 0.55, 0.62, 0.45)
const BLANCO := Color("#FFFFFF")
const NEGRO := Color("#26213A")
const LENGUA := Color("#FF7F9B")
const DORADO := Color("#FFCB3D")

## forma: normal | cuello | ave | redondo | agua | dino
## orejas: caidas | punta | redondas | largas | vaca | caballo | elefante | ciervo | penachos | ninguna
## hocico: perro | gato | vaca | largo | chancho | hipo | trompa | pico | pico_pato | pico_grande | pico_curvo | dino | nutria | ninguno
const CATALOGO := {
	# --- Granja y casa ---
	"perro": {"forma": "normal", "color": "#C98A4B", "panza": "#F6E7D2", "oreja": "#7E4E24", "orejas": "caidas", "hocico": "perro"},
	"perrito": {"forma": "normal", "color": "#E3A764", "panza": "#FFF1DF", "oreja": "#8A5A2B", "orejas": "caidas", "hocico": "perro", "cabeza": 1.12, "extras": ["lengua"]},
	"perrito_bombero": {"forma": "normal", "color": "#FFFFFF", "panza": "#FFFFFF", "oreja": "#2E2E38", "orejas": "caidas", "hocico": "perro", "manchas": "#2E2E38", "extras": ["manchas", "casco_bombero"]},
	"gato": {"forma": "normal", "color": "#F2A65A", "panza": "#FFE9D1", "oreja": "#FFB3C6", "orejas": "punta", "hocico": "gato", "extras": ["rayitas", "bigotes"], "manchas": "#D9822B"},
	"gatito": {"forma": "normal", "color": "#C9C3D9", "panza": "#FFFFFF", "oreja": "#FFB3C6", "orejas": "punta", "hocico": "gato", "cabeza": 1.15, "extras": ["bigotes", "pestanas"]},
	"vaca": {"forma": "normal", "color": "#FFFFFF", "panza": "#FFFFFF", "oreja": "#F7B6C2", "orejas": "vaca", "hocico": "vaca", "acento": "#F7B6C2", "manchas": "#33303F", "extras": ["manchas", "cuernos", "pestanas"]},
	"pato": {"forma": "ave", "color": "#FFD84D", "panza": "#FFF2A8", "orejas": "ninguna", "hocico": "pico_pato", "acento": "#FF9F1C"},
	"ganso": {"forma": "ave", "color": "#F7F7F2", "panza": "#FFFFFF", "orejas": "ninguna", "hocico": "pico_pato", "acento": "#FF8A00", "extras": ["perilla"]},
	"gallo": {"forma": "ave", "color": "#FFFFFF", "panza": "#FFF6E8", "orejas": "ninguna", "hocico": "pico", "acento": "#FFC23D", "extras": ["cresta"]},
	"pollito": {"forma": "redondo", "color": "#FFE066", "panza": "#FFF3B0", "orejas": "ninguna", "hocico": "pico", "acento": "#FF9F1C", "cabeza": 0.9, "extras": ["copete"]},
	"caballo": {"forma": "normal", "color": "#9C5B2E", "panza": "#C98B5A", "oreja": "#6E3D1B", "orejas": "caballo", "hocico": "largo", "acento": "#4A2A12", "extras": ["crin", "lucero"]},
	"pony": {"forma": "normal", "color": "#F8C4DA", "panza": "#FFE3EE", "oreja": "#F09ABF", "orejas": "caballo", "hocico": "largo", "acento": "#A45BD0", "cabeza": 1.1, "extras": ["crin", "pestanas"]},
	"pony_estelar": {"forma": "normal", "color": "#E6DCFF", "panza": "#FFFFFF", "oreja": "#C9B6FF", "orejas": "caballo", "hocico": "largo", "acento": "#6FD6E8", "cabeza": 1.1, "extras": ["crin_estrellas", "estrella_frente", "pestanas"]},
	"burro": {"forma": "normal", "color": "#9C9AA8", "panza": "#E2E1E8", "oreja": "#6D6B78", "orejas": "largas", "hocico": "largo", "acento": "#55535F", "extras": ["crin_corta"]},
	"oveja": {"forma": "normal", "color": "#5B5566", "panza": "#FBE9D7", "oreja": "#5B5566", "orejas": "ciervo", "hocico": "ninguno", "cara": "#FBE9D7", "acento": "#FFFFFF", "extras": ["lana"]},
	"cabra": {"forma": "normal", "color": "#E9DFCF", "panza": "#FFFFFF", "oreja": "#C9B79C", "orejas": "ciervo", "hocico": "largo", "acento": "#9B8B74", "extras": ["cuernos_cabra", "barba"]},
	"cabrita": {"forma": "normal", "color": "#D7B58E", "panza": "#FFF4E4", "oreja": "#B48A60", "orejas": "ciervo", "hocico": "largo", "acento": "#8C6A48", "cabeza": 1.12, "extras": ["cuernitos", "pestanas"]},
	"chancho": {"forma": "normal", "color": "#F9AFC0", "panza": "#FFD2DD", "oreja": "#F48AA5", "orejas": "punta", "hocico": "chancho"},
	"gerbo": {"forma": "redondo", "color": "#E4B97E", "panza": "#FFF1DC", "oreja": "#F4A8B8", "orejas": "redondas", "hocico": "gato", "cabeza": 1.05, "extras": ["bigotes"]},
	"cuy": {"forma": "redondo", "color": "#FFFFFF", "panza": "#FFFFFF", "oreja": "#E0A0A0", "orejas": "redondas", "hocico": "gato", "manchas": "#B5652E", "extras": ["parches"]},
	# --- Laguna y costa ---
	"lobo_marino": {"forma": "redondo", "color": "#8B6B4E", "panza": "#C9A882", "orejas": "ninguna", "hocico": "nutria", "extras": ["bigotes"]},
	"huillin": {"forma": "normal", "color": "#7A5230", "panza": "#D8B48A", "oreja": "#5E3D22", "orejas": "redondas", "hocico": "nutria", "extras": ["bigotes"]},
	"hipopotamo": {"forma": "normal", "color": "#A890C2", "panza": "#D6C4E6", "oreja": "#8C72A8", "orejas": "redondas", "hocico": "hipo"},
	"elefante": {"forma": "normal", "color": "#A9B0C3", "panza": "#D4D9E6", "oreja": "#F4C3D2", "orejas": "elefante", "hocico": "trompa"},
	"pinguino": {"forma": "redondo", "color": "#2E3148", "panza": "#FFFFFF", "orejas": "ninguna", "hocico": "pico", "acento": "#F28C28", "cara": "#FFFFFF", "extras": ["banda_humboldt"]},
	"flamenco": {"forma": "cuello", "color": "#FF8FB1", "panza": "#FFC2D4", "orejas": "ninguna", "hocico": "pico_curvo", "acento": "#33303F", "cabeza": 0.85},
	"ballena": {"forma": "agua", "color": "#4D7CC7", "panza": "#CFE3FF", "orejas": "ninguna", "hocico": "ninguno", "extras": ["chorro"]},
	# --- Pradera y altiplano ---
	"jirafa": {"forma": "cuello", "color": "#F7C843", "panza": "#FFF0B8", "oreja": "#E2A92A", "orejas": "ciervo", "hocico": "largo", "manchas": "#B86A28", "acento": "#B86A28", "extras": ["manchas", "osiconos", "pestanas"]},
	"cebra": {"forma": "normal", "color": "#FFFFFF", "panza": "#FFFFFF", "oreja": "#E8E8E8", "orejas": "caballo", "hocico": "largo", "manchas": "#2E2E38", "acento": "#2E2E38", "extras": ["rayas", "crin"], "hocico_color": "#5A5A66"},
	"alpaca": {"forma": "cuello", "color": "#F4E4C4", "panza": "#FFF8EA", "oreja": "#E2CBA2", "orejas": "ciervo", "hocico": "largo", "acento": "#FFFFFF", "extras": ["lana"]},
	"guanaco": {"forma": "cuello", "color": "#C68A4E", "panza": "#FFF4E6", "oreja": "#A86D36", "orejas": "ciervo", "hocico": "largo", "hocico_color": "#8C6A4A"},
	"huemul": {"forma": "normal", "color": "#8D6B4B", "panza": "#E9D7BF", "oreja": "#6E5034", "orejas": "ciervo", "hocico": "largo", "acento": "#6A4A2A", "hocico_color": "#C9A884", "extras": ["astas"]},
	"pudu": {"forma": "normal", "color": "#A35A31", "panza": "#E9C6A4", "oreja": "#7E4222", "orejas": "ciervo", "hocico": "largo", "acento": "#6A3A1A", "cabeza": 1.15, "hocico_color": "#D9B08C", "extras": ["astas_cortas"]},
	"nandu": {"forma": "cuello", "color": "#A79C8B", "panza": "#E2DBCF", "orejas": "ninguna", "hocico": "pico", "acento": "#6B6358", "cabeza": 0.85},
	# --- Árbol y selva ---
	"mono": {"forma": "normal", "color": "#8B5A2B", "panza": "#F2D2A9", "oreja": "#F2D2A9", "orejas": "redondas", "hocico": "ninguno", "cara": "#F2D2A9"},
	"mono_aullador": {"forma": "normal", "color": "#4A3326", "panza": "#7A5A46", "oreja": "#7A5A46", "orejas": "redondas", "hocico": "ninguno", "cara": "#8E6B55", "extras": ["boca_aullido"]},
	"perezoso": {"forma": "normal", "color": "#C9B38D", "panza": "#EADBC0", "oreja": "#C9B38D", "orejas": "ninguna", "hocico": "ninguno", "cara": "#F2E6CF", "extras": ["antifaz"]},
	"loro": {"forma": "ave", "color": "#3CB44B", "panza": "#8EDB86", "orejas": "ninguna", "hocico": "pico_curvo", "acento": "#F6D365", "extras": ["mejilla_roja", "frente_amarilla"]},
	"tucan": {"forma": "ave", "color": "#26232F", "panza": "#FFF3B0", "orejas": "ninguna", "hocico": "pico_grande", "acento": "#FF9F1C", "cara": "#FFF3B0"},
	"buho": {"forma": "redondo", "color": "#8B6B4A", "panza": "#D9C2A0", "orejas": "penachos", "hocico": "pico", "acento": "#F2B33D", "cara": "#EAD7B7", "extras": ["disco"]},
	"lechuza": {"forma": "redondo", "color": "#E2B983", "panza": "#FFF6E8", "orejas": "ninguna", "hocico": "pico", "acento": "#E8A0A0", "cara": "#FFFFFF", "extras": ["corazon"]},
	"tricahue": {"forma": "ave", "color": "#7D9B3C", "panza": "#F4D03F", "orejas": "ninguna", "hocico": "pico_curvo", "acento": "#6B6B78", "extras": ["mancha_roja"]},
	"choroy": {"forma": "ave", "color": "#4CAF50", "panza": "#9AD38B", "orejas": "ninguna", "hocico": "pico_curvo", "acento": "#55535F", "extras": ["frente_roja"]},
	"carpintero": {"forma": "ave", "color": "#25222E", "panza": "#3A3645", "orejas": "ninguna", "hocico": "pico", "acento": "#C8C2B4", "extras": ["copete_rojo"]},
	"chucao": {"forma": "redondo", "color": "#6D4C3D", "panza": "#E86F2C", "orejas": "ninguna", "hocico": "pico", "acento": "#3A3040", "cabeza": 0.9},
	"condor": {"forma": "ave", "color": "#2A2833", "panza": "#3B3846", "orejas": "ninguna", "hocico": "pico_curvo", "acento": "#E8D9B0", "cara": "#D98C7A", "extras": ["collar_blanco"]},
	"milodon": {"forma": "normal", "color": "#8B6A4F", "panza": "#B89878", "oreja": "#6D5039", "orejas": "redondas", "hocico": "ninguno", "cara": "#C7A887", "acento": "#6D5039", "extras": ["pelaje"]},
	# --- Dinos de Maxi (redondos, sonrientes y torpes) ---
	"trex": {"forma": "dino", "color": "#6BBF59", "panza": "#D6F0B8", "orejas": "ninguna", "hocico": "dino", "extras": ["dientes", "brazitos"]},
	"spinosaurio": {"forma": "dino", "color": "#3FA7A3", "panza": "#C9F0E8", "orejas": "ninguna", "hocico": "dino", "acento": "#FF8A3D", "extras": ["aleta"]},
	"carnotauro": {"forma": "dino", "color": "#E2603F", "panza": "#FFD2BF", "orejas": "ninguna", "hocico": "dino", "acento": "#FFF0D0", "extras": ["cuernitos_dino", "brazitos"]},
	"triceratops": {"forma": "dino", "color": "#F2A33A", "panza": "#FFE2B0", "orejas": "ninguna", "hocico": "pico", "acento": "#FFF4D6", "extras": ["gola"]},
	"braquiosaurio": {"forma": "cuello", "color": "#7CB7D8", "panza": "#D3ECF8", "orejas": "ninguna", "hocico": "ninguno", "cabeza": 0.9, "extras": ["manchitas"], "manchas": "#5B98BC"},
	"dinito": {"forma": "redondo", "color": "#9BE07A", "panza": "#E2F8D2", "orejas": "ninguna", "hocico": "dino", "cabeza": 1.05, "extras": ["cascara"]},
}


static func existe(id: String) -> bool:
	return CATALOGO.has(id)


## Color principal del animal (el "+100" flota de este color, §7.2).
static func color_de(id: String) -> Color:
	var f: Dictionary = CATALOGO.get(id, CATALOGO["perro"])
	var c := Color(str(f.get("color", "#C98A4B")))
	# El blanco no se lee sobre el pasto: se usa el de sus manchas o el contorno.
	if c.get_luminance() > 0.9:
		return Color(str(f.get("manchas", "#5A5A70")))
	return c


## `cara`: {"boca": 0-1, "ojos": normal|grandes|cerrados|estrella|guino|risa, "mirar": Vector2(-1..1)}.
static func dibujar(c: CanvasItem, id: String, alto: float, cara: Dictionary = {}) -> void:
	var f: Dictionary = CATALOGO.get(id, {})
	if f.is_empty():
		f = CATALOGO["perro"]
	var u := alto / 200.0
	var forma := str(f.get("forma", "normal"))
	var col := Color(str(f.get("color", "#C98A4B")))
	var panza := Color(str(f.get("panza", "#F6E7D2")))
	var oreja := Color(str(f.get("oreja", f.get("color", "#C98A4B"))))
	var acento := Color(str(f.get("acento", "#33303F")))
	var manchas := Color(str(f.get("manchas", "#33303F")))
	var extras: Array = f.get("extras", [])
	var k_cab := float(f.get("cabeza", 1.0))
	var t := u * 3.4  # trazo del contorno
	# Geometría por forma: centro y radio de la cabeza, y el cuerpo.
	var h := Vector2(0, -128) * u
	var r := 58.0 * u * k_cab
	match forma:
		"cuello":
			h = Vector2(0, -170) * u
			r = 40.0 * u * k_cab
		"ave":
			h = Vector2(0, -122) * u
			r = 52.0 * u * k_cab
		"redondo":
			h = Vector2(0, -110) * u
			r = 64.0 * u * k_cab
		"agua":
			h = Vector2(0, -78) * u
			r = 78.0 * u
		"dino":
			h = Vector2(0, -126) * u
			r = 62.0 * u * k_cab
	# 1. Detrás de todo.
	if "aleta" in extras:
		var vela := PackedVector2Array()
		for i in 7:
			var a := PI + PI * i / 6.0
			var rad := 70.0 * u * (1.0 + 0.18 * float(i % 2))
			vela.append(h + Vector2(cos(a) * rad * 0.9, sin(a) * rad * 1.15 - 10.0 * u))
		_poligono(c, vela, acento, t)
	if "gola" in extras:
		_elipse(c, h + Vector2(0, -18) * u, Vector2(r * 1.55, r * 1.3), 0.0, acento.darkened(0.08), t)
		for i in 7:
			var a := PI + PI * (i + 0.5) / 7.0
			c.draw_circle(h + Vector2(0, -18) * u + Vector2(cos(a) * r * 1.45, sin(a) * r * 1.2), 7.0 * u, col)
	if "chorro" in extras:
		for i in 5:
			var a := -PI / 2.0 + (i - 2) * 0.35
			c.draw_line(h + Vector2(0, -r * 0.95), h + Vector2(0, -r * 0.95) + Vector2.from_angle(a) * 38.0 * u, Color("#8FD3FF"), 7.0 * u, true)
			c.draw_circle(h + Vector2(0, -r * 0.95) + Vector2.from_angle(a) * 42.0 * u, 6.0 * u, Color("#BFE8FF"))
	if f.get("orejas", "") == "elefante":
		for s in [-1.0, 1.0]:
			_elipse(c, h + Vector2(s * r * 1.05, r * 0.05), Vector2(r * 0.72, r * 0.85), s * 0.2, col, t)
			_elipse(c, h + Vector2(s * r * 1.08, r * 0.08), Vector2(r * 0.5, r * 0.62), s * 0.2, oreja, 0.0)
	# 2. Cuerpo.
	_cuerpo(c, forma, u, h, r, col, panza, t, extras, manchas, acento)
	# 3. Orejas de atrás.
	_orejas_atras(c, str(f.get("orejas", "ninguna")), h, r, u, col, oreja, t)
	if "lana" in extras:
		for i in 7:
			var a := PI + PI * i / 6.0
			c.draw_circle(h + Vector2(cos(a) * r * 0.95, sin(a) * r * 0.82 - r * 0.15), r * 0.36, acento)
	# 4. Cabeza.
	if forma != "agua":
		_elipse(c, h, Vector2(r, r * 0.96), 0.0, col, t)
	var cara_color = f.get("cara", null)
	if cara_color != null:
		if "corazon" in extras:
			_corazon(c, h + Vector2(0, r * 0.02), r * 0.86, Color(str(cara_color)))
		elif "disco" in extras:
			for s in [-1.0, 1.0]:
				c.draw_circle(h + Vector2(s * r * 0.38, -r * 0.05), r * 0.42, Color(str(cara_color)))
		else:
			_elipse(c, h + Vector2(0, r * 0.18), Vector2(r * 0.78, r * 0.7), 0.0, Color(str(cara_color)), 0.0)
	if "lana" in extras:
		for i in 5:
			c.draw_circle(h + Vector2((i - 2) * r * 0.3, -r * 0.78 + absf(i - 2) * r * 0.1), r * 0.28, acento)
	_extras_cabeza(c, extras, h, r, u, col, manchas, acento, t)
	# 5. Ojos y hocico.
	var ojos_y := -0.08
	var hocico := str(f.get("hocico", "ninguno"))
	if hocico in ["largo", "vaca", "hipo", "chancho"]:
		ojos_y = -0.2
	_ojos(c, h + Vector2(0, r * ojos_y), r, u, cara, "pestanas" in extras)
	var color_hocico := Color(str(f.get("hocico_color", "#00000000")))
	_hocico(c, hocico, h, r, u, col, panza, acento, oreja, color_hocico, t, cara)
	# 6. Delante.
	if f.get("orejas", "") == "caidas":
		for s in [-1.0, 1.0]:
			var p := PackedVector2Array()
			var o := h + Vector2(s * r * 0.78, -r * 0.55)
			p.append(o)
			p.append(o + Vector2(s * r * 0.42, r * 0.25))
			p.append(o + Vector2(s * r * 0.36, r * 1.0))
			p.append(o + Vector2(s * r * 0.05, r * 1.08))
			p.append(o + Vector2(-s * r * 0.12, r * 0.45))
			_poligono(c, _suavizar(p), oreja, t)
	_extras_delante(c, extras, h, r, u, col, panza, acento, t)
	# Cachetes.
	if forma != "agua" and not "antifaz" in extras:
		for s in [-1.0, 1.0]:
			_elipse(c, h + Vector2(s * r * 0.6, r * 0.3), Vector2(r * 0.17, r * 0.11), 0.0, CACHETE, 0.0)


static func _cuerpo(c: CanvasItem, forma: String, u: float, h: Vector2, r: float, col: Color, panza: Color, t: float, extras: Array, manchas: Color, acento: Color) -> void:
	match forma:
		"cuello":
			var base := PackedVector2Array([Vector2(-62, 10) * u, Vector2(-58, -48) * u, Vector2(-30, -70) * u, Vector2(30, -70) * u, Vector2(58, -48) * u, Vector2(62, 10) * u])
			_poligono(c, _suavizar(base), col, t)
			var cuello := PackedVector2Array([Vector2(-20, -60) * u, h + Vector2(-r * 0.55, r * 0.4), h + Vector2(r * 0.55, r * 0.4), Vector2(22, -60) * u])
			_poligono(c, cuello, col, t)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-10, -60) * u, h + Vector2(-r * 0.22, r * 0.6), h + Vector2(r * 0.22, r * 0.6), Vector2(12, -60) * u]), panza)
			if "manchas" in extras:
				for p in [Vector2(-8, -95), Vector2(10, -122), Vector2(-6, -140), Vector2(-36, -30), Vector2(30, -38), Vector2(4, -20)]:
					_elipse(c, p * u, Vector2(8, 6) * u, 0.4, manchas, 0.0)
			if "manchitas" in extras:
				for p in [Vector2(-30, -30), Vector2(25, -45), Vector2(4, -100), Vector2(-2, -128)]:
					c.draw_circle(p * u, 6.0 * u, manchas)
			if "lana" in extras:
				for i in 6:
					c.draw_circle(Vector2(-48 + i * 19, -52 + (i % 2) * 8) * u, 17.0 * u, acento)
				for i in 4:
					c.draw_circle(Vector2(-12 + (i % 2) * 18, -78 - i * 18) * u, 15.0 * u, acento)
		"agua":
			var cuerpo := PackedVector2Array()
			for i in 25:
				var a := PI + PI * i / 24.0
				cuerpo.append(Vector2(cos(a) * 92.0, sin(a) * 120.0 + 12.0) * u)
			_poligono(c, cuerpo, col, t)
			_elipse(c, Vector2(0, -8) * u, Vector2(70, 34) * u, 0.0, panza, 0.0)
			for i in 4:
				c.draw_line(Vector2(-40 + i * 26, -22) * u, Vector2(-40 + i * 26, 6) * u, col.lightened(0.2), 3.0 * u, true)
			# Aleta saludando.
			_elipse(c, Vector2(86, -30) * u, Vector2(26, 12) * u, -0.7, col, t)
		_:
			var ancho := 64.0 if forma != "redondo" else 72.0
			var alto_c := 92.0 if forma != "redondo" else 86.0
			var cuerpo := PackedVector2Array()
			for i in 25:
				var a := PI + PI * i / 24.0
				cuerpo.append(Vector2(cos(a) * ancho, sin(a) * alto_c + 10.0) * u)
			_poligono(c, cuerpo, col, t)
			_elipse(c, Vector2(0, -24) * u, Vector2(ancho * 0.55, alto_c * 0.42) * u, 0.0, panza, 0.0)
			if forma == "ave" or forma == "redondo" and not "pelaje" in extras:
				for s in [-1.0, 1.0]:
					_elipse(c, Vector2(s * (ancho - 10.0), -30) * u, Vector2(16, 36) * u, s * 0.25, col.darkened(0.08), t * 0.8)
			if "manchas" in extras:
				for p in [Vector2(-40, -48), Vector2(34, -26), Vector2(-14, -70)]:
					_elipse(c, p * u, Vector2(15, 11) * u, 0.5, manchas, 0.0)
			if "parches" in extras:
				_elipse(c, Vector2(-34, -40) * u, Vector2(30, 26) * u, 0.3, manchas, 0.0)
				_elipse(c, Vector2(40, -30) * u, Vector2(22, 26) * u, -0.2, NEGRO, 0.0)
			if "rayas" in extras:
				for i in 4:
					var x := -48.0 + i * 30.0
					c.draw_line(Vector2(x, -70) * u, Vector2(x + 10, -10) * u, manchas, 9.0 * u, true)
			if "pelaje" in extras:
				for i in 9:
					var x := -60.0 + i * 15.0
					c.draw_line(Vector2(x, -60 - (i % 3) * 8) * u, Vector2(x + 4, -40 - (i % 3) * 8) * u, acento, 4.0 * u, true)
			if "cascara" in extras:
				var cascara := PackedVector2Array([Vector2(-80, 12) * u, Vector2(-82, -36) * u, Vector2(-60, -22) * u, Vector2(-40, -48) * u, Vector2(-18, -24) * u, Vector2(4, -50) * u, Vector2(26, -24) * u, Vector2(48, -48) * u, Vector2(66, -22) * u, Vector2(84, -38) * u, Vector2(82, 12) * u])
				_poligono(c, cascara, Color("#FFF6E0"), t)
				for p in [Vector2(-50, -6), Vector2(30, -12), Vector2(60, 0)]:
					c.draw_circle(p * u, 7.0 * u, Color("#B4E39A"))
			if forma == "dino":
				# Pancita a rayas y patitas.
				for i in 3:
					c.draw_line(Vector2(-26, -50 + i * 16) * u, Vector2(26, -50 + i * 16) * u, panza.darkened(0.12), 3.0 * u, true)


static func _orejas_atras(c: CanvasItem, tipo: String, h: Vector2, r: float, u: float, col: Color, oreja: Color, t: float) -> void:
	match tipo:
		"punta":
			for s in [-1.0, 1.0]:
				var p := PackedVector2Array([h + Vector2(s * r * 0.25, -r * 0.8), h + Vector2(s * r * 0.92, -r * 1.28), h + Vector2(s * r * 0.92, -r * 0.35)])
				_poligono(c, p, col, t)
				c.draw_colored_polygon(PackedVector2Array([h + Vector2(s * r * 0.4, -r * 0.75), h + Vector2(s * r * 0.84, -r * 1.08), h + Vector2(s * r * 0.82, -r * 0.5)]), oreja)
		"redondas":
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * r * 0.82, -r * 0.62), Vector2(r * 0.36, r * 0.36), 0.0, col, t)
				c.draw_circle(h + Vector2(s * r * 0.82, -r * 0.62), r * 0.2, oreja)
		"largas":
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * r * 0.48, -r * 1.25), Vector2(r * 0.22, r * 0.62), s * 0.22, col, t)
				_elipse(c, h + Vector2(s * r * 0.48, -r * 1.2), Vector2(r * 0.11, r * 0.45), s * 0.22, oreja.lightened(0.35), 0.0)
		"caballo":
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * r * 0.52, -r * 0.98), Vector2(r * 0.16, r * 0.34), s * 0.3, col, t)
				_elipse(c, h + Vector2(s * r * 0.52, -r * 0.96), Vector2(r * 0.08, r * 0.22), s * 0.3, oreja, 0.0)
		"vaca":
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * r * 1.02, -r * 0.3), Vector2(r * 0.36, r * 0.17), s * -0.25, col, t)
				_elipse(c, h + Vector2(s * r * 1.02, -r * 0.3), Vector2(r * 0.22, r * 0.09), s * -0.25, oreja, 0.0)
		"ciervo":
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * r * 0.98, -r * 0.48), Vector2(r * 0.4, r * 0.18), s * -0.45, col, t)
				_elipse(c, h + Vector2(s * r * 0.98, -r * 0.48), Vector2(r * 0.26, r * 0.09), s * -0.45, oreja.lightened(0.3), 0.0)
		"penachos":
			for s in [-1.0, 1.0]:
				var p := PackedVector2Array([h + Vector2(s * r * 0.3, -r * 0.82), h + Vector2(s * r * 0.85, -r * 1.25), h + Vector2(s * r * 0.8, -r * 0.5)])
				_poligono(c, p, col.darkened(0.15), t)


static func _extras_cabeza(c: CanvasItem, extras: Array, h: Vector2, r: float, u: float, col: Color, manchas: Color, acento: Color, t: float) -> void:
	if "manchas" in extras:
		_elipse(c, h + Vector2(r * 0.45, -r * 0.45), Vector2(r * 0.28, r * 0.22), 0.4, manchas, 0.0)
		_elipse(c, h + Vector2(-r * 0.55, -r * 0.1), Vector2(r * 0.16, r * 0.2), -0.3, manchas, 0.0)
	if "rayitas" in extras:
		for i in 3:
			c.draw_line(h + Vector2((i - 1) * r * 0.22, -r * 0.92), h + Vector2((i - 1) * r * 0.18, -r * 0.62), manchas, 5.0 * u, true)
	if "rayas" in extras:
		for s in [-1.0, 1.0]:
			for i in 2:
				c.draw_line(h + Vector2(s * r * 0.95, -r * 0.2 + i * r * 0.32), h + Vector2(s * r * 0.55, -r * 0.1 + i * r * 0.32), manchas, 7.0 * u, true)
		c.draw_line(h + Vector2(0, -r * 0.95), h + Vector2(0, -r * 0.55), manchas, 7.0 * u, true)
	if "antifaz" in extras:
		for s in [-1.0, 1.0]:
			_elipse(c, h + Vector2(s * r * 0.36, -r * 0.02), Vector2(r * 0.3, r * 0.2), s * -0.35, Color("#5A4632"), 0.0)
	if "parches" in extras:
		_elipse(c, h + Vector2(-r * 0.45, -r * 0.35), Vector2(r * 0.42, r * 0.5), 0.2, manchas, 0.0)
	if "banda_humboldt" in extras:
		_elipse(c, h + Vector2(0, r * 0.05), Vector2(r * 0.72, r * 0.72), 0.0, BLANCO, 0.0)
		c.draw_arc(h + Vector2(0, r * 0.1), r * 0.74, PI * 0.15, PI * 0.85, 18, col, 8.0 * u, true)
	if "frente_amarilla" in extras:
		_elipse(c, h + Vector2(0, -r * 0.62), Vector2(r * 0.42, r * 0.22), 0.0, acento, 0.0)
	if "mejilla_roja" in extras:
		for s in [-1.0, 1.0]:
			c.draw_circle(h + Vector2(s * r * 0.62, r * 0.18), r * 0.16, Color("#FF5A4E"))
	if "mancha_roja" in extras:
		_elipse(c, h + Vector2(0, r * 0.75), Vector2(r * 0.4, r * 0.15), 0.0, Color("#E8434B"), 0.0)
	if "frente_roja" in extras:
		_elipse(c, h + Vector2(0, -r * 0.5), Vector2(r * 0.36, r * 0.2), 0.0, Color("#E8434B"), 0.0)
	if "estrella_frente" in extras:
		_estrella(c, h + Vector2(0, -r * 0.58), r * 0.2, DORADO)


static func _extras_delante(c: CanvasItem, extras: Array, h: Vector2, r: float, u: float, col: Color, panza: Color, acento: Color, t: float) -> void:
	if "cuernos" in extras:
		for s in [-1.0, 1.0]:
			var p := PackedVector2Array([h + Vector2(s * r * 0.35, -r * 0.85), h + Vector2(s * r * 0.62, -r * 1.22), h + Vector2(s * r * 0.58, -r * 0.8)])
			_poligono(c, p, Color("#FFF4D6"), t * 0.8)
	if "cuernitos" in extras:
		for s in [-1.0, 1.0]:
			_poligono(c, PackedVector2Array([h + Vector2(s * r * 0.22, -r * 0.88), h + Vector2(s * r * 0.34, -r * 1.18), h + Vector2(s * r * 0.42, -r * 0.84)]), acento, t * 0.8)
	if "cuernos_cabra" in extras:
		for s in [-1.0, 1.0]:
			c.draw_arc(h + Vector2(s * r * 0.55, -r * 0.95), r * 0.32, PI if s > 0 else 0.0, PI * 1.5 if s > 0 else -PI * 0.5, 10, CONTORNO, 15.0 * u, true)
			c.draw_arc(h + Vector2(s * r * 0.55, -r * 0.95), r * 0.32, PI if s > 0 else 0.0, PI * 1.5 if s > 0 else -PI * 0.5, 10, acento, 9.0 * u, true)
	if "osiconos" in extras:
		for s in [-1.0, 1.0]:
			c.draw_line(h + Vector2(s * r * 0.3, -r * 0.8), h + Vector2(s * r * 0.38, -r * 1.3), CONTORNO, 10.0 * u, true)
			c.draw_line(h + Vector2(s * r * 0.3, -r * 0.8), h + Vector2(s * r * 0.38, -r * 1.3), col, 6.0 * u, true)
			c.draw_circle(h + Vector2(s * r * 0.38, -r * 1.34), r * 0.14, acento)
	if "astas" in extras:
		for s in [-1.0, 1.0]:
			var b := h + Vector2(s * r * 0.35, -r * 0.82)
			var p1 := b + Vector2(s * r * 0.2, -r * 0.6)
			for seg in [[b, p1], [p1, p1 + Vector2(s * r * 0.35, -r * 0.2)], [b + Vector2(s * r * 0.1, -r * 0.3), b + Vector2(s * r * 0.45, -r * 0.4)], [p1, p1 + Vector2(-s * r * 0.05, -r * 0.3)]]:
				c.draw_line(seg[0], seg[1], CONTORNO, 11.0 * u, true)
				c.draw_line(seg[0], seg[1], Color("#E9D6B0"), 6.0 * u, true)
	if "astas_cortas" in extras:
		for s in [-1.0, 1.0]:
			c.draw_line(h + Vector2(s * r * 0.3, -r * 0.82), h + Vector2(s * r * 0.36, -r * 1.15), CONTORNO, 10.0 * u, true)
			c.draw_line(h + Vector2(s * r * 0.3, -r * 0.82), h + Vector2(s * r * 0.36, -r * 1.15), Color("#E9D6B0"), 5.0 * u, true)
	if "crin" in extras or "crin_corta" in extras or "crin_estrellas" in extras:
		var largo := 1.0 if not "crin_corta" in extras else 0.6
		for i in 5:
			var a := -PI / 2.0 - 0.6 + i * 0.3
			var col_crin := acento
			if "crin_estrellas" in extras:
				col_crin = [Color("#FF8FB1"), Color("#FFCB3D"), Color("#6FD6E8"), Color("#B48CE8"), Color("#7DD87A")][i]
			_elipse(c, h + Vector2.from_angle(a) * r * 0.86, Vector2(r * 0.17, r * 0.32 * largo), a + PI / 2.0, col_crin, t * 0.6)
		if "crin_estrellas" in extras:
			for i in 3:
				_estrella(c, h + Vector2(-r * 0.7 + i * r * 0.6, -r * 1.18), r * 0.11, DORADO)
	if "lucero" in extras:
		_elipse(c, h + Vector2(0, -r * 0.55), Vector2(r * 0.1, r * 0.2), 0.0, BLANCO, 0.0)
	if "cresta" in extras:
		for i in 3:
			c.draw_circle(h + Vector2((i - 1) * r * 0.24, -r * 0.98 - (1 - absi(i - 1)) * r * 0.12), r * 0.2, Color("#E8434B"))
		_elipse(c, h + Vector2(r * 0.05, r * 0.72), Vector2(r * 0.12, r * 0.2), 0.0, Color("#E8434B"), 0.0)
	if "copete" in extras:
		for i in 3:
			c.draw_line(h + Vector2(0, -r * 0.9), h + Vector2((i - 1) * r * 0.2, -r * 1.25), col.darkened(0.15), 5.0 * u, true)
	if "copete_rojo" in extras:
		var p := PackedVector2Array([h + Vector2(-r * 0.5, -r * 0.75), h + Vector2(r * 0.1, -r * 1.35), h + Vector2(r * 0.55, -r * 0.72)])
		_poligono(c, p, Color("#E8434B"), t * 0.8)
	if "casco_bombero" in extras:
		var casco := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			casco.append(h + Vector2(cos(a) * r * 0.92, sin(a) * r * 0.75 - r * 0.45))
		_poligono(c, casco, Color("#E8434B"), t)
		_elipse(c, h + Vector2(0, -r * 0.45), Vector2(r * 1.1, r * 0.14), 0.0, Color("#C8303A"), t * 0.7)
		_estrella(c, h + Vector2(0, -r * 0.82), r * 0.18, DORADO)
	if "barba" in extras:
		_poligono(c, PackedVector2Array([h + Vector2(-r * 0.12, r * 0.95), h + Vector2(r * 0.12, r * 0.95), h + Vector2(0, r * 1.3)]), acento, t * 0.6)
	if "perilla" in extras:
		c.draw_circle(h + Vector2(0, r * 0.1), r * 0.12, Color("#33303F"))
	if "collar_blanco" in extras:
		for i in 9:
			c.draw_circle(h + Vector2((i - 4) * r * 0.22, r * 0.95), r * 0.17, Color("#F4F1EA"))
	if "brazitos" in extras:
		for s in [-1.0, 1.0]:
			_elipse(c, Vector2(s * 34, -54) * u, Vector2(8, 15) * u, s * -0.8, col, t * 0.7)
	if "cuernitos_dino" in extras:
		for s in [-1.0, 1.0]:
			_poligono(c, PackedVector2Array([h + Vector2(s * r * 0.45, -r * 0.7), h + Vector2(s * r * 0.75, -r * 1.05), h + Vector2(s * r * 0.72, -r * 0.6)]), acento, t * 0.8)
	if "gola" in extras:
		_poligono(c, PackedVector2Array([h + Vector2(-r * 0.08, -r * 0.6), h + Vector2(0, -r * 1.0), h + Vector2(r * 0.08, -r * 0.6)]), acento, t * 0.7)
		for s in [-1.0, 1.0]:
			_poligono(c, PackedVector2Array([h + Vector2(s * r * 0.4, -r * 0.75), h + Vector2(s * r * 0.62, -r * 1.35), h + Vector2(s * r * 0.58, -r * 0.7)]), acento, t * 0.7)
	if "manchitas" in extras:
		c.draw_circle(h + Vector2(r * 0.4, -r * 0.5), r * 0.13, Color("#5B98BC"))


static func _ojos(c: CanvasItem, centro: Vector2, r: float, u: float, cara: Dictionary, pestanas: bool) -> void:
	var tipo := str(cara.get("ojos", "normal"))
	var mirar: Vector2 = cara.get("mirar", Vector2.ZERO)
	var sep := r * 0.38
	var radio := r * 0.21 if tipo != "grandes" else r * 0.28
	for s in [-1.0, 1.0]:
		var o := centro + Vector2(s * sep, 0)
		var cerrado: bool = tipo in ["cerrados", "risa"] or (tipo == "guino" and s > 0)
		if cerrado:
			c.draw_arc(o + Vector2(0, radio * 0.3), radio * 0.8, PI * 1.1, PI * 1.9, 10, CONTORNO, 4.5 * u, true)
			continue
		if tipo == "estrella":
			_estrella(c, o, radio * 1.15, DORADO)
			continue
		c.draw_circle(o, radio + 1.6 * u, CONTORNO)
		c.draw_circle(o, radio, BLANCO)
		var pupila := o + mirar * radio * 0.35
		c.draw_circle(pupila, radio * 0.66, NEGRO)
		c.draw_circle(pupila + Vector2(-radio * 0.22, -radio * 0.26), radio * 0.24, BLANCO)
		c.draw_circle(pupila + Vector2(radio * 0.2, radio * 0.2), radio * 0.1, BLANCO)
		if pestanas:
			for k in 3:
				var a: float = -PI / 2.0 + s * (0.5 + k * 0.32)
				c.draw_line(o + Vector2.from_angle(a) * radio, o + Vector2.from_angle(a) * radio * 1.45, CONTORNO, 3.0 * u, true)


static func _boca(c: CanvasItem, centro: Vector2, ancho: float, u: float, cara: Dictionary) -> void:
	var abre := clampf(float(cara.get("boca", 0.0)), 0.0, 1.0)
	if str(cara.get("ojos", "")) == "risa":
		abre = maxf(abre, 0.7)
	if abre < 0.08:
		c.draw_arc(centro + Vector2(0, -ancho * 0.25), ancho * 0.5, PI * 0.15, PI * 0.85, 12, CONTORNO, 4.0 * u, true)
		return
	var boca := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		boca.append(centro + Vector2(-cos(a) * ancho * 0.5, sin(a) * ancho * (0.25 + 0.55 * abre)))
	_poligono(c, boca, Color("#7A2E45"), 3.5 * u)
	_elipse(c, centro + Vector2(0, ancho * (0.15 + 0.4 * abre)), Vector2(ancho * 0.26, ancho * 0.14 * (0.6 + abre)), 0.0, LENGUA, 0.0)


static func _hocico(c: CanvasItem, tipo: String, h: Vector2, r: float, u: float, col: Color, panza: Color, acento: Color, oreja: Color, color_hocico: Color, t: float, cara: Dictionary) -> void:
	match tipo:
		"perro":
			_elipse(c, h + Vector2(0, r * 0.36), Vector2(r * 0.46, r * 0.34), 0.0, panza, t * 0.7)
			_elipse(c, h + Vector2(0, r * 0.2), Vector2(r * 0.16, r * 0.11), 0.0, NEGRO, 0.0)
			c.draw_circle(h + Vector2(-r * 0.05, r * 0.16), r * 0.04, BLANCO)
			_boca(c, h + Vector2(0, r * 0.45), r * 0.4, u, cara)
		"gato":
			_poligono(c, PackedVector2Array([h + Vector2(-r * 0.09, r * 0.2), h + Vector2(r * 0.09, r * 0.2), h + Vector2(0, r * 0.3)]), Color("#FF8FB1"), t * 0.5)
			_boca(c, h + Vector2(0, r * 0.4), r * 0.3, u, cara)
		"vaca", "hipo", "chancho":
			var color := acento if tipo == "vaca" else (panza if tipo == "hipo" else oreja)
			var tam := Vector2(r * 0.62, r * 0.36) if tipo != "chancho" else Vector2(r * 0.34, r * 0.24)
			_elipse(c, h + Vector2(0, r * 0.42), tam, 0.0, color, t * 0.7)
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * tam.x * 0.42, r * 0.38), Vector2(r * 0.07, r * 0.09), 0.0, color.darkened(0.4), 0.0)
			_boca(c, h + Vector2(0, r * 0.68), r * 0.36, u, cara)
		"largo":
			var color2 := panza if color_hocico.a == 0.0 else color_hocico
			_elipse(c, h + Vector2(0, r * 0.45), Vector2(r * 0.5, r * 0.42), 0.0, color2, t * 0.7)
			for s in [-1.0, 1.0]:
				_elipse(c, h + Vector2(s * r * 0.2, r * 0.42), Vector2(r * 0.06, r * 0.08), 0.0, color2.darkened(0.45), 0.0)
			_boca(c, h + Vector2(0, r * 0.66), r * 0.34, u, cara)
		"nutria":
			for s in [-1.0, 1.0]:
				c.draw_circle(h + Vector2(s * r * 0.17, r * 0.38), r * 0.22, panza)
			_elipse(c, h + Vector2(0, r * 0.22), Vector2(r * 0.14, r * 0.1), 0.0, NEGRO, 0.0)
			_boca(c, h + Vector2(0, r * 0.52), r * 0.26, u, cara)
		"trompa":
			var trompa := PackedVector2Array()
			for i in 9:
				var k := i / 8.0
				trompa.append(h + Vector2(sin(k * 2.2) * r * 0.25 - r * 0.14, r * 0.15 + k * r * 0.95))
			for i in 9:
				var k := 1.0 - i / 8.0
				trompa.append(h + Vector2(sin(k * 2.2) * r * 0.25 + r * 0.14, r * 0.15 + k * r * 0.95))
			_poligono(c, trompa, col, t * 0.8)
			_boca(c, h + Vector2(r * 0.35, r * 0.48), r * 0.24, u, cara)
		"pico":
			var abre := clampf(float(cara.get("boca", 0.0)), 0.0, 1.0)
			_poligono(c, PackedVector2Array([h + Vector2(-r * 0.2, r * 0.18), h + Vector2(r * 0.2, r * 0.18), h + Vector2(0, r * 0.42)]), acento, t * 0.7)
			if abre > 0.1:
				_poligono(c, PackedVector2Array([h + Vector2(-r * 0.16, r * 0.32), h + Vector2(r * 0.16, r * 0.32), h + Vector2(0, r * (0.42 + abre * 0.25))]), acento.darkened(0.15), t * 0.6)
		"pico_pato":
			var abre2 := clampf(float(cara.get("boca", 0.0)), 0.0, 1.0)
			_elipse(c, h + Vector2(0, r * 0.32), Vector2(r * 0.5, r * 0.2), 0.0, acento, t * 0.7)
			_elipse(c, h + Vector2(0, r * (0.48 + abre2 * 0.15)), Vector2(r * 0.42, r * 0.15), 0.0, acento.darkened(0.12), t * 0.6)
			for s in [-1.0, 1.0]:
				c.draw_circle(h + Vector2(s * r * 0.14, r * 0.26), r * 0.035, NEGRO)
		"pico_grande":
			var pico := PackedVector2Array([h + Vector2(-r * 0.15, r * 0.05), h + Vector2(r * 0.25, -r * 0.05), h + Vector2(r * 1.25, r * 0.35), h + Vector2(r * 1.2, r * 0.55), h + Vector2(r * 0.2, r * 0.48)])
			_poligono(c, _suavizar(pico), acento, t * 0.8)
			_elipse(c, h + Vector2(r * 1.05, r * 0.38), Vector2(r * 0.18, r * 0.14), 0.0, Color("#E8434B"), 0.0)
		"pico_curvo":
			var p := PackedVector2Array([h + Vector2(-r * 0.2, r * 0.12), h + Vector2(r * 0.22, r * 0.1), h + Vector2(r * 0.25, r * 0.4), h + Vector2(r * 0.05, r * 0.62), h + Vector2(-r * 0.05, r * 0.42)])
			_poligono(c, _suavizar(p), acento, t * 0.7)
		"dino":
			for s in [-1.0, 1.0]:
				c.draw_circle(h + Vector2(s * r * 0.15, r * 0.12), r * 0.05, col.darkened(0.45))
			_boca(c, h + Vector2(0, r * 0.42), r * 0.62, u, cara)
		_:
			_boca(c, h + Vector2(0, r * 0.4), r * 0.34, u, cara)


## Dientes del T-rex (redondeados) y bigotes: van encima del hocico.
static func detalles(c: CanvasItem, id: String, alto: float, cara: Dictionary = {}) -> void:
	var f: Dictionary = CATALOGO.get(id, {})
	var extras: Array = f.get("extras", [])
	var u := alto / 200.0
	var k_cab := float(f.get("cabeza", 1.0))
	var r := 58.0 * u * k_cab
	var h := Vector2(0, -128) * u
	match str(f.get("forma", "")):
		"redondo":
			h = Vector2(0, -110) * u
			r = 64.0 * u * k_cab
		"dino":
			h = Vector2(0, -126) * u
			r = 62.0 * u * k_cab
	if "bigotes" in extras:
		for s in [-1.0, 1.0]:
			for k in 2:
				var o := h + Vector2(s * r * 0.22, r * (0.3 + k * 0.1))
				c.draw_line(o, o + Vector2(s * r * 0.55, r * (-0.06 + k * 0.12)), CONTORNO, 2.6 * u, true)
	if "dientes" in extras:
		var abre := clampf(float(cara.get("boca", 0.0)), 0.0, 1.0)
		var y := r * 0.42 + r * 0.1
		for i in 4:
			var x := (i - 1.5) * r * 0.16
			c.draw_colored_polygon(PackedVector2Array([h + Vector2(x - r * 0.05, y - r * 0.02), h + Vector2(x + r * 0.05, y - r * 0.02), h + Vector2(x, y + r * (0.1 + abre * 0.05))]), BLANCO)
	if "lengua" in extras and float(cara.get("boca", 0.0)) < 0.1:
		_elipse(c, h + Vector2(r * 0.08, r * 0.62), Vector2(r * 0.1, r * 0.14), 0.0, LENGUA, 1.5 * u)
	if "boca_aullido" in extras and float(cara.get("boca", 0.0)) < 0.1:
		_elipse(c, h + Vector2(0, r * 0.45), Vector2(r * 0.14, r * 0.12), 0.0, Color("#3A1F2A"), 0.0)


## Punto (relativo a la base) donde está la cabeza: de ahí salen las ondas de sonido y las estrellitas.
static func punto_cabeza(id: String, alto: float) -> Vector2:
	var f: Dictionary = CATALOGO.get(id, {})
	var u := alto / 200.0
	match str(f.get("forma", "normal")):
		"cuello":
			return Vector2(0, -170) * u
		"redondo":
			return Vector2(0, -110) * u
		"agua":
			return Vector2(0, -90) * u
	return Vector2(0, -126) * u


# ---------------------------------------------------------------------------
# Primitivas
# ---------------------------------------------------------------------------

static func elipse_puntos(centro: Vector2, radios: Vector2, rot: float, n: int = 28) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(centro + Vector2(cos(a) * radios.x, sin(a) * radios.y).rotated(rot))
	return p


static func _elipse(c: CanvasItem, centro: Vector2, radios: Vector2, rot: float, color: Color, trazo: float) -> void:
	var p := elipse_puntos(centro, radios, rot)
	if trazo > 0.0:
		var cerrado := p.duplicate()
		cerrado.append(p[0])
		c.draw_polyline(cerrado, CONTORNO, trazo * 2.0, true)
	c.draw_colored_polygon(p, color)


static func _poligono(c: CanvasItem, p: PackedVector2Array, color: Color, trazo: float) -> void:
	if p.size() < 3:
		return
	if trazo > 0.0:
		var cerrado := p.duplicate()
		cerrado.append(p[0])
		c.draw_polyline(cerrado, CONTORNO, trazo * 2.0, true)
	if Geometry2D.triangulate_polygon(p).is_empty():
		return
	c.draw_colored_polygon(p, color)


## Chaikin de dos pasadas: esquinas redondas sin bezier.
static func _suavizar(p: PackedVector2Array) -> PackedVector2Array:
	var actual := p
	for paso in 2:
		var nuevo := PackedVector2Array()
		for i in actual.size():
			var a := actual[i]
			var b := actual[(i + 1) % actual.size()]
			nuevo.append(a.lerp(b, 0.25))
			nuevo.append(a.lerp(b, 0.75))
		actual = nuevo
	return actual


static func _estrella(c: CanvasItem, centro: Vector2, radio: float, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 10:
		var rad := radio if i % 2 == 0 else radio * 0.45
		p.append(centro + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * rad)
	var cerrado := p.duplicate()
	cerrado.append(p[0])
	c.draw_polyline(cerrado, CONTORNO, maxf(2.0, radio * 0.18), true)
	c.draw_colored_polygon(p, color)


static func estrella(c: CanvasItem, centro: Vector2, radio: float, color: Color) -> void:
	_estrella(c, centro, radio, color)


static func _corazon(c: CanvasItem, centro: Vector2, tam: float, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		p.append(centro + Vector2(x, y) * tam / 17.0)
	c.draw_colored_polygon(p, color)
