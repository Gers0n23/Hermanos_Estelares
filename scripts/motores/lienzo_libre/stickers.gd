extends RefCounted

## Catalogo de STICKERS de los lienzos con tema (docs/fichas/motor-lienzo-libre.md §8): objetos
## prediseñados que el nino pone, mueve, agranda, gira, recolorea y conecta sobre su dibujo.
##
## Reune tres fuentes con el mismo estilo "peluche pintado" (contorno azul noche, sombra, volumen y
## carita kawaii), mientras no existan los sprites finales de HE-13:
## - los dibujos de las cartas de "Parejas de Coco" (`dibujos_emparejar.gd`: dinos, vehiculos,
##   jirafa, pony, gatito, ropa, sol, banderas);
## - las figuras de `figura_vectorial.gd` (estrella, corazon, luna, flor, arcoiris);
## - los dibujos propios de este archivo, por tema (palmera, volcan, castillo, lechuza, tren...).
##
## Todos miran hacia la DERECHA: el viajero que recorre un camino se espeja al ir a la izquierda.
## El color principal lo elige el nino (balde sobre el sticker, o el color actual en Semilla).
## Se dibujan en pantalla como vectores y, para el PNG, se rasterizan con `grabador.gd`.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const D := preload("res://scripts/motores/emparejar/dibujos_emparejar.gd")
const Grabador := preload("res://scripts/motores/lienzo_libre/grabador.gd")
const COLOR_CONTORNO := Color("#2B3350")
const BLANCO := Color("#FFFFFF")
const CREMA := Color("#FFF8EE")
const VIDRIO := Color("#CFF5F1")
const DORADO := Color("#FFCB3D")
const MADERA := Color("#B07A55")
const OSCURO := Color("#3A3F55")
const METAL := Color("#C9D0E0")

## id -> [fuente, color por defecto]. Fuentes: "d" dibujos_emparejar, "f" figura_vectorial,
## "p" propio. `ALIAS` renombra los que chocan con los sellos antiguos (`auto`, `pony`).
const CATALOGO := {
	# Maxi: dinosaurios, vehiculos, bomberos y espacio
	"trex": ["d", "#7DD87A"], "spinosaurio": ["d", "#45C6C0"], "carnotauro": ["d", "#FF6B6B"], "huevo": ["d", "#FFF1C9"],
	"carrito": ["d", "#FF6B6B"], "bus": ["d", "#4A8BE0"], "bomberos": ["d", "#E8423F"], "cohete": ["d", "#EEF2FA"],
	"palmera": ["p", "#4CBF56"], "volcan": ["p", "#B07A55"], "bandera_meta": ["p", "#2B2E3F"], "cono": ["p", "#FF9A2E"],
	"casa": ["p", "#FFD9A0"], "fuego": ["p", "#FF9A2E"], "arbol": ["p", "#4CBF56"], "planeta": ["p", "#B48CE8"],
	# Nicole: granja, sabana, castillo, gatitos y k-pop
	"pony_amigo": ["d", "#F7A8D0"], "jirafa": ["d", "#FFCB3D"], "gatito": ["d", "#FF9F4A"], "sol": ["d", "#FFCB3D"],
	"corona": ["d", "#FFCB3D"], "vestido": ["d", "#F26CA8"], "zapato": ["d", "#B48CE8"],
	"granero": ["p", "#E8423F"], "manzana": ["p", "#EE4035"], "nube": ["p", "#FFFFFF"], "roca": ["p", "#9AA0B0"],
	"castillo": ["p", "#F7A8D0"], "carroza": ["p", "#F7A8D0"], "ovillo": ["p", "#B48CE8"], "pastel": ["p", "#FF9FC8"],
	"globo": ["p", "#FF6B6B"], "regalo": ["p", "#45C6C0"], "microfono": ["p", "#45C6C0"], "nota": ["p", "#9357D6"],
	"foco": ["p", "#FFE38A"],
	# Sofia: escuela de magia, ponys, concierto, tren por Chile, mascotas y espacio
	"sombrero_mago": ["p", "#9357D6"], "varita": ["p", "#FFCB3D"], "lechuza": ["p", "#B07A55"], "caldero": ["p", "#4A4F66"],
	"libro": ["p", "#EE4035"], "escoba": ["p", "#FFCB3D"], "unicornio": ["p", "#F4EEFF"], "parlante": ["p", "#3A3F55"],
	"montana": ["p", "#9AA0B0"], "casa_valpo": ["p", "#FFD23F"], "moai": ["p", "#8C7B6B"], "pinguino": ["p", "#2B2E3F"],
	"cactus": ["p", "#4CBF56"], "copihue": ["p", "#D7263D"], "tren": ["p", "#EE4035"], "perrito": ["p", "#E7B98A"],
	"gerbo": ["p", "#F2C894"], "hueso": ["p", "#FFF8EE"], "pelota": ["p", "#FF6B6B"], "bandera_chile": ["p", "#FFFFFF"],
	# Figuras de todos
	"estrella": ["f", "#FFCB3D"], "corazon": ["f", "#FF7EB6"], "luna": ["f", "#FFE38A"], "flor": ["f", "#FF7EB6"],
	"arcoiris": ["f", "#FFFFFF"], "destello": ["p", "#FFCB3D"],
}
const ALIAS := {"carrito": "auto", "pony_amigo": "pony"}
## Stickers que caminan o ruedan: al tocarlos avanzan un poco en vez de solo saltar.
const ANDAN := ["trex", "spinosaurio", "carnotauro", "carrito", "bus", "bomberos", "tren", "pony_amigo", "unicornio",
	"jirafa", "gatito", "perrito", "gerbo", "pinguino", "carroza"]
## Hacia donde "avanza" cada dibujo, en radianes (0 = derecha). El cohete apunta hacia arriba y
## la escoba vuela en diagonal: el viajero se gira para avanzar en la direccion del camino.
const DIRECCION := {"cohete": -PI / 2.0, "escoba": -0.8}
## Viajeros que siguen la curva del camino girando entero (vehiculos y voladores). Los animales
## solo se inclinan un poco, para no caminar de costado.
const ROTAN := ["carrito", "bus", "bomberos", "tren", "carroza", "cohete", "escoba"]


static func tiene(id: String) -> bool:
	return CATALOGO.has(id)


static func color_por_defecto(id: String) -> Color:
	return Color(str(CATALOGO.get(id, ["", "#FFCB3D"])[1]))


static func es_dino(id: String) -> bool:
	return id in ["trex", "spinosaurio", "carnotauro"]


## Dibuja el sticker `id` centrado en `c` con radio `r` sobre cualquier CanvasItem (o un Grabador).
static func dibujar(l, id: String, color: Color, c: Vector2, r: float) -> void:
	if not CATALOGO.has(id):
		return
	var t := maxf(2.5, r * 0.075)
	match str(CATALOGO[id][0]):
		"d":
			D.dibujar(l, ALIAS.get(id, id), color, c, r, true, false)
		"f":
			Figura.dibujar(l, id, color, c, r * (1.0 if id == "arcoiris" else 0.92), true, false)
		_:
			var metodo := "_" + id
			match id:
				"palmera": _palmera(l, color, c, r, t)
				"volcan": _volcan(l, color, c, r, t)
				"bandera_meta": _bandera_meta(l, color, c, r, t)
				"cono": _cono(l, color, c, r, t)
				"casa": _casa(l, color, c, r, t)
				"fuego": _fuego(l, color, c, r, t)
				"arbol": _arbol(l, color, c, r, t)
				"planeta": _planeta(l, color, c, r, t)
				"granero": _granero(l, color, c, r, t)
				"manzana": _manzana(l, color, c, r, t)
				"nube": _nube(l, color, c, r, t)
				"roca": _roca(l, color, c, r, t)
				"castillo": _castillo(l, color, c, r, t)
				"carroza": _carroza(l, color, c, r, t)
				"ovillo": _ovillo(l, color, c, r, t)
				"pastel": _pastel(l, color, c, r, t)
				"globo": _globo(l, color, c, r, t)
				"regalo": _regalo(l, color, c, r, t)
				"microfono": _microfono(l, color, c, r, t)
				"nota": _nota(l, color, c, r, t)
				"foco": _foco(l, color, c, r, t)
				"sombrero_mago": _sombrero_mago(l, color, c, r, t)
				"varita": _varita(l, color, c, r, t)
				"lechuza": _lechuza(l, color, c, r, t)
				"caldero": _caldero(l, color, c, r, t)
				"libro": _libro(l, color, c, r, t)
				"escoba": _escoba(l, color, c, r, t)
				"unicornio": _unicornio(l, color, c, r, t)
				"parlante": _parlante(l, color, c, r, t)
				"montana": _montana(l, color, c, r, t)
				"casa_valpo": _casa_valpo(l, color, c, r, t)
				"moai": _moai(l, color, c, r, t)
				"pinguino": _pinguino(l, color, c, r, t)
				"cactus": _cactus(l, color, c, r, t)
				"copihue": _copihue(l, color, c, r, t)
				"tren": _tren(l, color, c, r, t)
				"perrito": _perrito(l, color, c, r, t)
				"gerbo": _gerbo(l, color, c, r, t)
				"hueso": _hueso(l, color, c, r, t)
				"pelota": _pelota(l, color, c, r, t)
				"bandera_chile": _bandera_chile(l, color, c, r, t)
				"destello": _destello(l, color, c, r, t)
				_: push_warning("stickers: falta el dibujo %s" % metodo)


## Imagen del sticker (para el PNG): `lado` px, girado `giro` radianes y espejado si `espejo`.
static func imagen(id: String, color: Color, lado: int, giro := 0.0, espejo := false) -> Image:
	var g := Grabador.new()
	dibujar(g, id, color, Vector2.ZERO, Grabador.RADIO)
	return g.rasterizar(maxi(8, lado), giro, espejo)


# --- Ayudas ----------------------------------------------------------------------------------

## Elipse girada `angulo` radianes (hojas, alas, orejas).
static func _elr(c: Vector2, r: float, centro: Vector2, rx: float, ry: float, angulo: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		puntos.append(c + (centro + Vector2(cos(a) * rx, sin(a) * ry).rotated(angulo)) * r)
	return puntos


static func _figura(nombre: String, c: Vector2, r: float, centro: Vector2, radio: float) -> PackedVector2Array:
	return Figura.poligono(nombre, c + centro * r, radio * r)


static func _linea(l, c: Vector2, r: float, puntos: Array, color: Color, ancho: float) -> void:
	l.draw_polyline(D._poli(c, r, puntos), color, ancho, true)


# --- Maxi --------------------------------------------------------------------------------------

static func _palmera(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var tronco := D._redondear(D._poli(c, r, [Vector2(-0.16, 0.95), Vector2(0.12, 0.95), Vector2(0.1, 0.3), Vector2(0.08, -0.32),
		Vector2(-0.08, -0.32), Vector2(-0.1, 0.3)]), r * 0.04)
	D._pintar(l, tronco, MADERA, r, t)
	for y in [0.0, 0.3, 0.6]:
		l.draw_line(c + Vector2(-0.1, y) * r, c + Vector2(0.1, y + 0.06) * r, MADERA.darkened(0.3), t * 0.7, true)
	for angulo in [-2.9, -2.25, -1.57, -0.9, -0.25]:
		D._pintar(l, _elr(c, r, Vector2(0, -0.36) + Vector2.from_angle(angulo) * 0.44, 0.48, 0.15, angulo), color, r, t)
	for x in [-0.09, 0.09]:
		D._detalle(l, D._el(c, r, Vector2(x, -0.26), 0.1, 0.1), Color("#8A5A35"), t * 0.7)


static func _volcan(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._unir([D._el(c, r, Vector2(-0.1, -0.64), 0.17, 0.15), D._el(c, r, Vector2(0.12, -0.74), 0.19, 0.16),
		D._el(c, r, Vector2(0.0, -0.9), 0.12, 0.1)]), Color("#EDEAF5"), r, t)
	var cono := D._redondear(D._poli(c, r, [Vector2(-0.95, 0.9), Vector2(-0.28, -0.4), Vector2(0.28, -0.4), Vector2(0.95, 0.9)]), r * 0.08)
	D._pintar(l, cono, color, r, t)
	var lava := D._poli(c, r, [Vector2(-0.4, -0.45), Vector2(0.4, -0.45), Vector2(0.24, -0.16), Vector2(0.14, -0.3), Vector2(0.06, 0.04),
		Vector2(-0.04, -0.24), Vector2(-0.14, -0.06), Vector2(-0.22, -0.28)])
	D._dentro(l, lava, cono, Color("#FF6B3D"))
	D._detalle(l, D._el(c, r, Vector2(0, -0.4), 0.27, 0.07), Color("#FF9F4A"), t * 0.7)
	Figura.dibujar_cara(l, c + Vector2(0, 0.38) * r, r * 0.55)


static func _bandera_meta(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.66, -0.92, -0.54, 0.95, 0.05), METAL, r, t)
	var paño := D._caja(c, r, -0.54, -0.88, 0.86, -0.12)
	D._pintar(l, paño, BLANCO, r, t)
	var lado := 1.4 / 5.0
	for i in 5:
		for j in 3:
			if (i + j) % 2 == 0:
				l.draw_colored_polygon(D._caja(c, r, -0.54 + i * lado, -0.88 + j * 0.2533, -0.54 + (i + 1) * lado, -0.88 + (j + 1) * 0.2533), color)
	Figura.contornear(l, paño, t)
	D._detalle(l, D._caja(c, r, -0.82, 0.82, -0.38, 0.98, 0.05), OSCURO, t * 0.7)


static func _cono(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.62, 0.66, 0.62, 0.88, 0.06), color.darkened(0.15), r, t)
	var cuerpo := D._redondear(D._poli(c, r, [Vector2(-0.38, 0.72), Vector2(-0.1, -0.86), Vector2(0.1, -0.86), Vector2(0.38, 0.72)]), r * 0.05)
	D._pintar(l, cuerpo, color, r, t)
	for franja in [[-0.3, -0.12], [0.2, 0.38]]:
		D._dentro(l, D._caja(c, r, -1.0, franja[0], 1.0, franja[1]), cuerpo, BLANCO)


static func _casa(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, 0.34, -0.72, 0.52, -0.3), Color("#9A6238"), r, t)
	D._pintar(l, D._caja(c, r, -0.62, -0.14, 0.62, 0.9, 0.04), color, r, t)
	D._pintar(l, D._redondear(D._poli(c, r, [Vector2(-0.84, -0.02), Vector2(0.0, -0.82), Vector2(0.84, -0.02)]), r * 0.06), Color("#EE4035"), r, t)
	D._detalle(l, D._caja(c, r, -0.16, 0.36, 0.16, 0.9, 0.1), Color("#9A6238"), t * 0.8)
	l.draw_circle(c + Vector2(0.08, 0.64) * r, r * 0.03, DORADO)
	for x in [-0.5, 0.24]:
		D._detalle(l, D._caja(c, r, x, 0.06, x + 0.26, 0.32, 0.04), VIDRIO, t * 0.8)
		l.draw_line(c + Vector2(x + 0.13, 0.06) * r, c + Vector2(x + 0.13, 0.32) * r, COLOR_CONTORNO, t * 0.5, true)
		l.draw_line(c + Vector2(x, 0.19) * r, c + Vector2(x + 0.26, 0.19) * r, COLOR_CONTORNO, t * 0.5, true)


static func _fuego(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var llama := D._unir([_figura("gota", c, r, Vector2(0, 0.06), 0.92), _figura("gota", c, r, Vector2(-0.4, 0.38), 0.5),
		_figura("gota", c, r, Vector2(0.4, 0.38), 0.5)])
	D._pintar(l, llama, color, r, t)
	D._rellenar(l, _figura("gota", c, r, Vector2(0, 0.4), 0.52), Color("#FFD23F"))
	D._rellenar(l, _figura("gota", c, r, Vector2(0, 0.6), 0.26), Color("#FFF3B0"))


static func _arbol(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.14, 0.2, 0.14, 0.95, 0.05), Color("#9A6238"), r, t)
	var copa := D._unir([D._el(c, r, Vector2(0, -0.36), 0.45, 0.45), D._el(c, r, Vector2(-0.42, -0.08), 0.36, 0.36),
		D._el(c, r, Vector2(0.42, -0.08), 0.36, 0.36), D._el(c, r, Vector2(-0.22, -0.64), 0.3, 0.3),
		D._el(c, r, Vector2(0.22, -0.64), 0.3, 0.3), D._el(c, r, Vector2(0, 0.06), 0.36, 0.3)])
	D._pintar(l, copa, color, r, t)
	for p in [Vector2(-0.5, -0.2), Vector2(0.46, 0.0), Vector2(0.2, -0.7)]:
		D._dentro(l, D._el(c, r, p, 0.07, 0.07), copa, color.lightened(0.35))
	Figura.dibujar_cara(l, c + Vector2(0, -0.2) * r, r * 0.52)


static func _planeta(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var anillo := PackedVector2Array()
	for i in 49:
		var a := TAU * i / 48.0
		anillo.append(c + Vector2(cos(a) * 0.98, sin(a) * 0.26).rotated(-0.3) * r)
	l.draw_polyline(anillo, COLOR_CONTORNO, t * 3.6, true)
	l.draw_polyline(anillo, DORADO, t * 1.8, true)
	var disco := D._el(c, r, Vector2.ZERO, 0.62, 0.62, 40)
	D._pintar(l, disco, color, r, t)
	for p in [Vector3(-0.28, -0.3, 0.1), Vector3(0.3, 0.3, 0.08), Vector3(0.34, -0.2, 0.06)]:
		D._dentro(l, D._el(c, r, Vector2(p.x, p.y), p.z, p.z), disco, color.darkened(0.18))
	var frente := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		frente.append(c + Vector2(cos(a) * 0.98, sin(a) * 0.26).rotated(-0.3) * r)
	l.draw_polyline(frente, COLOR_CONTORNO, t * 3.6, true)
	l.draw_polyline(frente, DORADO, t * 1.8, true)
	Figura.dibujar_cara(l, c + Vector2(0, -0.12) * r, r * 0.6)


# --- Nicole -----------------------------------------------------------------------------------

static func _granero(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var granero := D._redondear(D._poli(c, r, [Vector2(-0.76, 0.9), Vector2(-0.76, -0.2), Vector2(-0.46, -0.62), Vector2(0.0, -0.86),
		Vector2(0.46, -0.62), Vector2(0.76, -0.2), Vector2(0.76, 0.9)]), r * 0.04)
	D._pintar(l, granero, color, r, t)
	_linea(l, c, r, [Vector2(-0.76, -0.2), Vector2(-0.46, -0.62), Vector2(0.0, -0.86), Vector2(0.46, -0.62), Vector2(0.76, -0.2)], CREMA, t * 1.6)
	D._detalle(l, D._caja(c, r, -0.2, -0.46, 0.2, -0.14), CREMA, t * 0.8)
	var puerta := D._caja(c, r, -0.36, 0.2, 0.36, 0.9)
	D._detalle(l, puerta, CREMA, t * 0.8)
	D._detalle(l, D._caja(c, r, -0.28, 0.28, 0.28, 0.9), color.darkened(0.15), t * 0.6)
	_linea(l, c, r, [Vector2(-0.28, 0.28), Vector2(0.28, 0.9)], CREMA, t * 1.2)
	_linea(l, c, r, [Vector2(0.28, 0.28), Vector2(-0.28, 0.9)], CREMA, t * 1.2)


static func _manzana(l, color: Color, c: Vector2, r: float, t: float) -> void:
	_linea(l, c, r, [Vector2(0.0, -0.4), Vector2(0.04, -0.62), Vector2(0.1, -0.82)], Color("#8A5A35"), t * 1.8)
	D._pintar(l, _elr(c, r, Vector2(0.32, -0.66), 0.24, 0.11, -0.5), Color("#4CBF56"), r, t * 0.8)
	var cuerpo := D._unir([D._el(c, r, Vector2(-0.24, 0.12), 0.5, 0.62), D._el(c, r, Vector2(0.24, 0.12), 0.5, 0.62)])
	D._pintar(l, cuerpo, color, r, t)
	D._dentro(l, D._el(c, r, Vector2(-0.38, -0.18), 0.12, 0.08), cuerpo, Color(1, 1, 1, 0.55))
	Figura.dibujar_cara(l, c + Vector2(0, 0.16) * r, r * 0.62)


static func _nube(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var nube := D._unir([D._el(c, r, Vector2(-0.48, 0.12), 0.36, 0.32), D._el(c, r, Vector2(0.0, -0.12), 0.46, 0.44),
		D._el(c, r, Vector2(0.48, 0.1), 0.38, 0.34), D._caja(c, r, -0.62, 0.1, 0.62, 0.44, 0.16)])
	D._pintar(l, nube, color, r, t)
	Figura.dibujar_cara(l, c + Vector2(0, 0.08) * r, r * 0.58)


static func _roca(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var roca := D._redondear(D._poli(c, r, [Vector2(-0.84, 0.62), Vector2(-0.62, -0.18), Vector2(-0.12, -0.52), Vector2(0.5, -0.36),
		Vector2(0.86, 0.2), Vector2(0.72, 0.62)]), r * 0.18)
	D._pintar(l, roca, color, r, t)
	for p in [Vector3(-0.36, 0.2, 0.08), Vector3(0.3, -0.1, 0.06), Vector3(0.2, 0.36, 0.07)]:
		D._dentro(l, D._el(c, r, Vector2(p.x, p.y), p.z, p.z), roca, color.darkened(0.2))


static func _castillo(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.22, -0.5, 0.22, 0.2), color.lightened(0.15), r, t)
	D._pintar(l, D._redondear(D._poli(c, r, [Vector2(-0.32, -0.46), Vector2(0.0, -1.0), Vector2(0.32, -0.46)]), r * 0.04), Color("#9357D6"), r, t)
	var partes := [D._caja(c, r, -0.6, -0.1, 0.6, 0.9), D._caja(c, r, -0.92, -0.34, -0.52, 0.9), D._caja(c, r, 0.52, -0.34, 0.92, 0.9)]
	for x in [-0.46, -0.1, 0.26]:
		partes.append(D._caja(c, r, x, -0.24, x + 0.2, -0.06))
	D._pintar(l, D._unir(partes), color, r, t)
	for x in [-0.72, 0.72]:
		D._pintar(l, D._redondear(D._poli(c, r, [Vector2(x - 0.28, -0.32), Vector2(x, -0.9), Vector2(x + 0.28, -0.32)]), r * 0.04), Color("#B48CE8"), r, t)
		D._detalle(l, D._unir([D._caja(c, r, x - 0.09, 0.04, x + 0.09, 0.3), D._el(c, r, Vector2(x, 0.04), 0.09, 0.09)]), VIDRIO, t * 0.7)
	D._detalle(l, D._unir([D._caja(c, r, -0.2, 0.46, 0.2, 0.9), D._el(c, r, Vector2(0, 0.46), 0.2, 0.2)]), Color("#9A6238"), t * 0.8)
	D._detalle(l, _figura("corazon", c, r, Vector2(0, -0.24), 0.14), Color("#FF7EB6"), t * 0.6)


static func _carroza(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._detalle(l, D._caja(c, r, -0.78, 0.28, 0.78, 0.4, 0.05), DORADO, t * 0.8)
	var cuerpo := D._el(c, r, Vector2(0, -0.08), 0.72, 0.52, 40)
	D._pintar(l, cuerpo, color, r, t)
	for x in [-0.36, 0.36]:
		_linea(l, c, r, [Vector2(x, -0.56), Vector2(x * 1.25, -0.08), Vector2(x, 0.4)], color.darkened(0.2), t * 0.8)
	D._detalle(l, D._el(c, r, Vector2(0, -0.1), 0.24, 0.22), VIDRIO, t * 0.8)
	D._detalle(l, D._redondear(D._poli(c, r, [Vector2(-0.2, -0.6), Vector2(-0.22, -0.84), Vector2(-0.08, -0.7), Vector2(0.0, -0.9),
		Vector2(0.08, -0.7), Vector2(0.22, -0.84), Vector2(0.2, -0.6)]), r * 0.02), DORADO, t * 0.7)
	D._ruedas(l, c, r, t, [Vector2(-0.5, 0.56), Vector2(0.5, 0.56)], 0.26)


static func _ovillo(l, color: Color, c: Vector2, r: float, t: float) -> void:
	_linea(l, c, r, [Vector2(0.5, 0.46), Vector2(0.7, 0.7), Vector2(0.62, 0.86), Vector2(0.9, 0.92)], color.darkened(0.2), t * 1.2)
	D._pintar(l, D._el(c, r, Vector2.ZERO, 0.7, 0.7, 40), color, r, t)
	var hebra := color.darkened(0.25)
	l.draw_arc(c + Vector2(-0.7, 0.0) * r, r * 0.8, -0.7, 0.7, 16, hebra, t * 0.8, true)
	l.draw_arc(c + Vector2(0.7, 0.0) * r, r * 0.8, PI - 0.7, PI + 0.7, 16, hebra, t * 0.8, true)
	l.draw_arc(c + Vector2(0.0, -0.7) * r, r * 0.8, PI / 2.0 - 0.7, PI / 2.0 + 0.7, 16, hebra, t * 0.8, true)
	l.draw_arc(c + Vector2(0.0, 0.1) * r, r * 0.34, -2.6, -0.5, 12, hebra, t * 0.8, true)


static func _pastel(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._detalle(l, D._caja(c, r, -0.9, 0.78, 0.9, 0.92, 0.05), METAL, t * 0.7)
	D._detalle(l, D._caja(c, r, -0.05, -0.66, 0.05, -0.3), Color("#8ED3FF"), t * 0.5)
	D._detalle(l, _figura("gota", c, r, Vector2(0, -0.8), 0.14), DORADO, t * 0.5)
	for piso in [[-0.76, 0.2, 0.76, 0.8, color], [-0.5, -0.32, 0.5, 0.22, color.lightened(0.2)]]:
		var caja := D._caja(c, r, piso[0], piso[1], piso[2], piso[3], 0.08)
		D._pintar(l, caja, piso[4], r, t)
		var glaseado := [D._caja(c, r, piso[0], piso[1], piso[2], piso[1] + 0.08)]
		var x: float = piso[0]
		while x <= piso[2]:
			glaseado.append(D._el(c, r, Vector2(x, piso[1] + 0.1), 0.1, 0.1))
			x += 0.25
		for trozo in [D._unir(glaseado)]:
			D._dentro(l, trozo, caja, BLANCO)
	for x in [-0.5, 0.0, 0.5]:
		D._detalle(l, D._el(c, r, Vector2(x, 0.52), 0.07, 0.07), Color("#EE4035"), t * 0.5)


static func _globo(l, color: Color, c: Vector2, r: float, t: float) -> void:
	_linea(l, c, r, [Vector2(0.0, 0.5), Vector2(0.08, 0.64), Vector2(-0.06, 0.8), Vector2(0.04, 0.98)], COLOR_CONTORNO, t * 0.8)
	D._detalle(l, D._poli(c, r, [Vector2(-0.08, 0.56), Vector2(0.0, 0.44), Vector2(0.08, 0.56)]), color.darkened(0.15), t * 0.6)
	var globo := D._el(c, r, Vector2(0, -0.2), 0.52, 0.66, 40)
	D._pintar(l, globo, color, r, t)
	D._dentro(l, _elr(c, r, Vector2(-0.24, -0.5), 0.1, 0.18, 0.4), globo, Color(1, 1, 1, 0.6))


static func _regalo(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var caja := D._caja(c, r, -0.7, -0.18, 0.7, 0.86, 0.05)
	D._pintar(l, caja, color, r, t)
	var tapa := D._caja(c, r, -0.8, -0.38, 0.8, -0.14, 0.05)
	D._pintar(l, tapa, color.lightened(0.12), r, t)
	for forma in [caja, tapa]:
		D._dentro(l, D._caja(c, r, -0.1, -1.0, 0.1, 1.0), forma, Color("#FF7EB6"))
	D._lazo(l, c + Vector2(0, -0.5) * r, r * 0.42, Color("#FF7EB6"), t * 0.8)


static func _microfono(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._redondear(D._poli(c, r, [Vector2(-0.15, -0.06), Vector2(0.15, -0.06), Vector2(0.08, 0.94), Vector2(-0.08, 0.94)]), r * 0.05), color, r, t)
	D._detalle(l, _figura("corazon", c, r, Vector2(0, 0.36), 0.12), Color("#FF7EB6"), t * 0.5)
	D._detalle(l, D._caja(c, r, -0.22, -0.14, 0.22, 0.04, 0.04), METAL, t * 0.7)
	var cabeza := D._el(c, r, Vector2(0, -0.46), 0.4, 0.4, 40)
	D._pintar(l, cabeza, METAL, r, t)
	for k in [-0.2, 0.0, 0.2]:
		D._dentro(l, D._caja(c, r, -1.0, -0.47 + k, 1.0, -0.45 + k), cabeza, Color(COLOR_CONTORNO, 0.5))
		D._dentro(l, D._caja(c, r, k - 0.01, -1.0, k + 0.01, 1.0), cabeza, Color(COLOR_CONTORNO, 0.5))


static func _nota(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var nota := D._unir([_elr(c, r, Vector2(-0.36, 0.56), 0.28, 0.2, -0.4), _elr(c, r, Vector2(0.5, 0.38), 0.28, 0.2, -0.4),
		D._caja(c, r, -0.18, -0.56, -0.08, 0.54), D._caja(c, r, 0.68, -0.74, 0.78, 0.36),
		D._poli(c, r, [Vector2(-0.18, -0.6), Vector2(0.78, -0.8), Vector2(0.78, -0.54), Vector2(-0.18, -0.34)])])
	D._pintar(l, nota, color, r, t)
	D._dentro(l, _elr(c, r, Vector2(-0.44, 0.5), 0.08, 0.05, -0.4), nota, Color(1, 1, 1, 0.55))


static func _foco(l, color: Color, c: Vector2, r: float, t: float) -> void:
	l.draw_colored_polygon(D._poli(c, r, [Vector2(-0.16, -0.3), Vector2(0.16, -0.3), Vector2(0.86, 0.96), Vector2(-0.86, 0.96)]), Color(color, 0.4))
	_linea(l, c, r, [Vector2(-0.5, -0.56), Vector2(-0.5, -0.9), Vector2(0.5, -0.9), Vector2(0.5, -0.56)], OSCURO, t * 1.2)
	D._pintar(l, D._caja(c, r, -0.36, -0.8, 0.36, -0.3, 0.12), OSCURO, r, t)
	D._detalle(l, D._el(c, r, Vector2(0, -0.32), 0.3, 0.1), color, t * 0.7)


# --- Sofia ------------------------------------------------------------------------------------

static func _sombrero_mago(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._el(c, r, Vector2(0, 0.64), 0.92, 0.22, 40), color.darkened(0.12), r, t)
	var cono := D._redondear(D._poli(c, r, [Vector2(-0.56, 0.62), Vector2(-0.12, -0.36), Vector2(0.34, -0.96), Vector2(0.18, -0.36), Vector2(0.56, 0.62)]), r * 0.05)
	D._pintar(l, cono, color, r, t)
	D._dentro(l, D._caja(c, r, -1.0, 0.36, 1.0, 0.52), cono, DORADO)
	D._detalle(l, _figura("estrella", c, r, Vector2(-0.08, 0.02), 0.16), DORADO, t * 0.6)
	D._detalle(l, _figura("estrella", c, r, Vector2(0.16, -0.36), 0.1), DORADO, t * 0.5)


static func _varita(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._redondear(D._poli(c, r, [Vector2(-0.74, 0.86), Vector2(-0.62, 0.96), Vector2(0.16, -0.12), Vector2(0.04, -0.22)]), r * 0.04), OSCURO, r, t)
	D._dentro(l, D._el(c, r, Vector2(-0.68, 0.9), 0.14, 0.14), D._poli(c, r, [Vector2(-0.74, 0.86), Vector2(-0.62, 0.96), Vector2(0.16, -0.12), Vector2(0.04, -0.22)]), BLANCO)
	Figura.dibujar(l, "estrella", color, c + Vector2(0.3, -0.42) * r, r * 0.48, true, true)
	for p in [Vector3(-0.44, -0.5, 0.14), Vector3(0.8, 0.14, 0.12), Vector3(0.78, -0.86, 0.1)]:
		D._detalle(l, _destello_forma(c + Vector2(p.x, p.y) * r, r * p.z), BLANCO, t * 0.5)


static func _lechuza(l, color: Color, c: Vector2, r: float, t: float) -> void:
	for x in [-0.2, 0.2]:
		D._detalle(l, D._el(c, r, Vector2(x, 0.9), 0.12, 0.07), Color("#FF9F4A"), t * 0.6)
	var cuerpo := D._unir([D._el(c, r, Vector2(0, 0.14), 0.6, 0.76, 40),
		D._poli(c, r, [Vector2(-0.56, -0.36), Vector2(-0.5, -0.86), Vector2(-0.2, -0.56)]),
		D._poli(c, r, [Vector2(0.56, -0.36), Vector2(0.2, -0.56), Vector2(0.5, -0.86)])])
	D._pintar(l, cuerpo, color, r, t)
	D._dentro(l, D._el(c, r, Vector2(0, 0.42), 0.36, 0.4), cuerpo, color.lightened(0.45))
	for x in [-0.6, 0.6]:
		D._pintar(l, _elr(c, r, Vector2(x, 0.24), 0.16, 0.4, 0.2 * signf(x)), color.darkened(0.15), r, t * 0.8)
	for x in [-0.24, 0.24]:
		D._detalle(l, D._el(c, r, Vector2(x, -0.24), 0.22, 0.22), BLANCO, t * 0.8)
		l.draw_circle(c + Vector2(x, -0.22) * r, r * 0.11, COLOR_CONTORNO)
		l.draw_circle(c + Vector2(x - 0.04, -0.27) * r, r * 0.04, BLANCO)
	D._detalle(l, D._poli(c, r, [Vector2(-0.08, -0.06), Vector2(0.08, -0.06), Vector2(0.0, 0.08)]), DORADO, t * 0.6)


static func _caldero(l, color: Color, c: Vector2, r: float, t: float) -> void:
	for x in [-0.4, 0.4]:
		D._detalle(l, D._caja(c, r, x - 0.08, 0.6, x + 0.08, 0.92, 0.04), OSCURO, t * 0.6)
	var olla := D._el(c, r, Vector2(0, 0.24), 0.76, 0.58, 40)
	D._pintar(l, olla, color, r, t)
	D._pintar(l, D._caja(c, r, -0.84, -0.36, 0.84, -0.16, 0.1), color.lightened(0.18), r, t)
	D._detalle(l, D._el(c, r, Vector2(0, -0.3), 0.7, 0.1), Color("#7DD87A"), t * 0.7)
	for p in [Vector3(-0.22, -0.5, 0.1), Vector3(0.14, -0.64, 0.13), Vector3(0.38, -0.46, 0.07)]:
		D._detalle(l, D._el(c, r, Vector2(p.x, p.y), p.z, p.z), Color("#A8EBA4"), t * 0.5)
	Figura.dibujar_cara(l, c + Vector2(0, 0.28) * r, r * 0.62)


static func _libro(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._detalle(l, D._caja(c, r, -0.54, -0.68, 0.72, 0.82, 0.04), CREMA, t * 0.8)
	for y in [-0.4, -0.1, 0.2, 0.5]:
		l.draw_line(c + Vector2(0.58, y) * r, c + Vector2(0.7, y) * r, Color(COLOR_CONTORNO, 0.5), t * 0.4, true)
	var tapa := D._caja(c, r, -0.72, -0.82, 0.56, 0.7, 0.06)
	D._pintar(l, tapa, color, r, t)
	D._dentro(l, D._caja(c, r, -1.0, -1.0, -0.52, 1.0), tapa, color.darkened(0.22))
	D._detalle(l, _figura("estrella", c, r, Vector2(0.04, -0.08), 0.28), DORADO, t * 0.7)


static func _escoba(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._redondear(D._poli(c, r, [Vector2(0.8, -0.96), Vector2(0.92, -0.86), Vector2(-0.18, 0.26), Vector2(-0.3, 0.16)]), r * 0.04), MADERA, r, t)
	var paja := D._redondear(D._poli(c, r, [Vector2(-0.36, 0.04), Vector2(-0.1, 0.3), Vector2(-0.5, 0.96), Vector2(-0.98, 0.56)]), r * 0.08)
	D._pintar(l, paja, color, r, t)
	for k in [0.3, 0.5, 0.7]:
		_linea(l, c, r, [Vector2(-0.3, 0.14).lerp(Vector2(-0.18, 0.26), k), Vector2(-0.98, 0.56).lerp(Vector2(-0.5, 0.96), k)], color.darkened(0.25), t * 0.6)
	_linea(l, c, r, [Vector2(-0.38, 0.08), Vector2(-0.12, 0.34)], Color("#9357D6"), t * 2.4)


static func _unicornio(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pony(l, color, c, r, t, true, false)
	var cuerno := D._poli(c, r, [Vector2(0.46, -0.7), Vector2(0.62, -0.7), Vector2(0.68, -1.04)])
	D._pintar(l, cuerno, DORADO, r, t * 0.8)
	for k in [0.35, 0.65]:
		l.draw_line(c + Vector2(0.46, -0.7).lerp(Vector2(0.68, -1.04), k) * r, c + Vector2(0.62, -0.7).lerp(Vector2(0.68, -1.04), k) * r, COLOR_CONTORNO, t * 0.5, true)


static func _parlante(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.56, -0.86, 0.56, 0.9, 0.1), color, r, t)
	D._detalle(l, D._el(c, r, Vector2(0, 0.34), 0.38, 0.38), Color("#45C6C0"), t * 0.8)
	D._detalle(l, D._el(c, r, Vector2(0, 0.34), 0.28, 0.28), Color("#9AA0B0"), t * 0.6)
	D._detalle(l, D._el(c, r, Vector2(0, 0.34), 0.1, 0.1), OSCURO, t * 0.5)
	D._detalle(l, D._el(c, r, Vector2(0, -0.42), 0.2, 0.2), Color("#9AA0B0"), t * 0.6)
	for x in [-0.36, 0.36]:
		l.draw_circle(c + Vector2(x, -0.7) * r, r * 0.05, Color("#FF7EB6"))


static func _montana(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var base := D._redondear(D._poli(c, r, [Vector2(-0.98, 0.9), Vector2(-0.56, 0.12), Vector2(0.0, 0.28), Vector2(0.52, 0.06), Vector2(0.98, 0.9)]), r * 0.05)
	D._pintar(l, base, Color("#7E8AA6"), r, t)
	D._dentro(l, D._caja(c, r, -1.0, 0.7, 1.0, 1.0), base, Color("#45C6C0"))
	for torre in [[Vector2(-0.56, 0.24), Vector2(-0.5, -0.5), Vector2(-0.38, -0.68), Vector2(-0.26, -0.48), Vector2(-0.22, 0.24)],
			[Vector2(-0.16, 0.3), Vector2(-0.1, -0.78), Vector2(0.02, -0.98), Vector2(0.14, -0.76), Vector2(0.18, 0.3)],
			[Vector2(0.24, 0.24), Vector2(0.3, -0.56), Vector2(0.42, -0.72), Vector2(0.54, -0.5), Vector2(0.58, 0.24)]]:
		var forma := D._redondear(D._poli(c, r, torre), r * 0.03)
		D._pintar(l, forma, color, r, t)
		D._dentro(l, D._caja(c, r, -1.0, -1.0, 1.0, -0.5), forma, BLANCO)


static func _casa_valpo(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.44, -0.54, 0.44, 0.9, 0.03), color, r, t)
	D._pintar(l, D._caja(c, r, -0.54, -0.7, 0.54, -0.5, 0.04), Color("#9A6238"), r, t)
	for y in [-0.34, 0.12]:
		for x in [-0.3, 0.08]:
			D._detalle(l, D._caja(c, r, x, y, x + 0.22, y + 0.28, 0.03), VIDRIO, t * 0.7)
	_linea(l, c, r, [Vector2(-0.44, 0.06), Vector2(0.44, 0.06)], BLANCO, t * 1.4)
	D._detalle(l, D._caja(c, r, -0.12, 0.54, 0.14, 0.9, 0.06), Color("#45C6C0"), t * 0.7)


static func _moai(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var cabeza := D._redondear(D._poli(c, r, [Vector2(-0.4, 0.96), Vector2(-0.48, -0.2), Vector2(-0.4, -0.78), Vector2(0.34, -0.82),
		Vector2(0.44, -0.2), Vector2(0.4, 0.96)]), r * 0.1)
	D._pintar(l, D._el(c, r, Vector2(-0.02, -0.84), 0.36, 0.14), Color("#B5543C"), r, t)
	D._pintar(l, cabeza, color, r, t)
	D._dentro(l, D._caja(c, r, -0.5, -0.42, 0.5, -0.3), cabeza, color.darkened(0.25))
	for x in [-0.22, 0.2]:
		D._dentro(l, D._el(c, r, Vector2(x, -0.2), 0.12, 0.06), cabeza, color.darkened(0.35))
	D._detalle(l, D._poli(c, r, [Vector2(-0.02, -0.34), Vector2(0.14, 0.22), Vector2(-0.12, 0.24)]), color.lightened(0.12), t * 0.7)
	_linea(l, c, r, [Vector2(-0.2, 0.46), Vector2(0.2, 0.46)], COLOR_CONTORNO, t * 1.0)


static func _pinguino(l, color: Color, c: Vector2, r: float, t: float) -> void:
	for x in [-0.2, 0.2]:
		D._detalle(l, D._el(c, r, Vector2(x, 0.9), 0.18, 0.08), Color("#FF9F4A"), t * 0.6)
	for x in [-0.54, 0.54]:
		D._pintar(l, _elr(c, r, Vector2(x, 0.16), 0.14, 0.4, -0.35 * signf(x)), color, r, t)
	var cuerpo := D._el(c, r, Vector2(0, 0.1), 0.52, 0.82, 40)
	D._pintar(l, cuerpo, color, r, t)
	D._dentro(l, D._unir([D._el(c, r, Vector2(0, 0.28), 0.38, 0.58), D._el(c, r, Vector2(0, -0.34), 0.32, 0.26)]), cuerpo, BLANCO)
	Figura.dibujar_cara(l, c + Vector2(0, -0.36) * r, r * 0.5)
	D._detalle(l, D._poli(c, r, [Vector2(-0.08, -0.3), Vector2(0.08, -0.3), Vector2(0.0, -0.18)]), Color("#FF9F4A"), t * 0.5)


static func _cactus(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var cactus := D._unir([D._caja(c, r, -0.22, -0.78, 0.22, 0.95, 0.2), D._caja(c, r, -0.64, -0.24, -0.42, 0.34, 0.11),
		D._caja(c, r, -0.64, 0.16, -0.1, 0.36, 0.1), D._caja(c, r, 0.42, -0.46, 0.64, 0.12, 0.11), D._caja(c, r, 0.1, -0.06, 0.64, 0.14, 0.1)])
	D._pintar(l, cactus, color, r, t)
	for x in [-0.08, 0.08]:
		D._dentro(l, D._caja(c, r, x - 0.012, -0.7, x + 0.012, 0.9), cactus, color.darkened(0.22))
	Figura.dibujar_cara(l, c + Vector2(0, -0.3) * r, r * 0.36)
	D._detalle(l, _figura("flor", c, r, Vector2(0, -0.84), 0.2), Color("#FF7EB6"), t * 0.6)


static func _copihue(l, color: Color, c: Vector2, r: float, t: float) -> void:
	_linea(l, c, r, [Vector2(-0.94, -0.9), Vector2(-0.5, -0.66), Vector2(0.0, -0.64), Vector2(0.04, -0.46)], Color("#2E8B57"), t * 1.8)
	for hoja in [[Vector2(-0.6, -0.86), -0.6], [Vector2(-0.2, -0.82), 0.4], [Vector2(0.36, -0.7), -0.3]]:
		D._pintar(l, _elr(c, r, hoja[0], 0.24, 0.1, hoja[1]), Color("#4CBF56"), r, t * 0.8)
	var campana := D._redondear(D._poli(c, r, [Vector2(-0.12, -0.48), Vector2(0.14, -0.48), Vector2(0.46, 0.58), Vector2(0.24, 0.76),
		Vector2(0.0, 0.62), Vector2(-0.24, 0.76), Vector2(-0.46, 0.58)]), r * 0.06)
	D._pintar(l, campana, color, r, t)
	for p in [Vector2(-0.1, 0.0), Vector2(0.12, 0.2), Vector2(-0.16, 0.36), Vector2(0.06, -0.2)]:
		D._dentro(l, D._el(c, r, p, 0.035, 0.035), campana, Color(1, 1, 1, 0.7))
	_linea(l, c, r, [Vector2(0.0, 0.62), Vector2(0.0, 0.92)], DORADO, t * 1.0)
	l.draw_circle(c + Vector2(0, 0.94) * r, r * 0.05, DORADO)


static func _tren(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._el(c, r, Vector2(0.44, -0.9), 0.16, 0.1), Color("#EDEAF5"), r, t * 0.7)
	D._pintar(l, D._caja(c, r, 0.34, -0.74, 0.58, -0.26, 0.05), OSCURO, r, t)
	D._pintar(l, D._caja(c, r, -0.9, -0.84, -0.02, -0.64, 0.05), OSCURO, r, t)
	D._pintar(l, D._caja(c, r, -0.84, -0.7, -0.08, 0.36, 0.06), color, r, t)
	D._pintar(l, D._caja(c, r, -0.2, -0.32, 0.86, 0.36, 0.3), color, r, t)
	D._detalle(l, D._caja(c, r, -0.66, -0.56, -0.26, -0.2, 0.05), VIDRIO, t * 0.8)
	D._detalle(l, D._poli(c, r, [Vector2(0.84, 0.12), Vector2(0.98, 0.46), Vector2(0.7, 0.46)]), DORADO, t * 0.7)
	D._ruedas(l, c, r, t, [Vector2(-0.52, 0.46), Vector2(0.12, 0.5), Vector2(0.56, 0.5)], 0.2)
	Figura.dibujar_cara(l, c + Vector2(0.4, 0.02) * r, r * 0.44)


static func _perrito(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var partes := [D._el(c, r, Vector2(-0.14, 0.3), 0.54, 0.32), D._el(c, r, Vector2(0.4, -0.2), 0.38, 0.34),
		D._poli(c, r, [Vector2(0.1, 0.1), Vector2(0.3, -0.1), Vector2(0.5, 0.1), Vector2(0.3, 0.4)]),
		D._poli(c, r, [Vector2(-0.6, 0.16), Vector2(-0.9, -0.22), Vector2(-0.78, -0.28), Vector2(-0.5, 0.06)])]
	for x in [-0.54, -0.3, 0.04, 0.26]:
		partes.append(D._caja(c, r, x, 0.4, x + 0.16, 0.92, 0.06))
	var silueta := D._unir(partes)
	D._pintar(l, silueta, color, r, t)
	D._dentro(l, D._el(c, r, Vector2(-0.28, 0.22), 0.16, 0.12), silueta, color.darkened(0.2))
	for oreja in [[Vector2(0.06, -0.18), 0.3], [Vector2(0.74, -0.2), -0.3]]:
		D._pintar(l, _elr(c, r, oreja[0], 0.12, 0.28, oreja[1]), color.darkened(0.3), r, t * 0.8)
	D._detalle(l, D._el(c, r, Vector2(0.52, -0.02), 0.17, 0.12), color.lightened(0.35), t * 0.6)
	l.draw_circle(c + Vector2(0.62, -0.08) * r, r * 0.05, COLOR_CONTORNO)
	Figura.dibujar_cara(l, c + Vector2(0.38, -0.24) * r, r * 0.46)


static func _gerbo(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var cola := D._poli(c, r, [Vector2(-0.56, 0.36), Vector2(-0.82, 0.2), Vector2(-0.92, -0.1), Vector2(-0.86, -0.38)])
	l.draw_polyline(cola, COLOR_CONTORNO, t * 2.6, true)
	l.draw_polyline(cola, color.darkened(0.1), t * 1.2, true)
	D._pintar(l, D._el(c, r, Vector2(-0.86, -0.44), 0.1, 0.12), color.darkened(0.3), r, t * 0.7)
	for x in [0.2, 0.52]:
		D._pintar(l, D._el(c, r, Vector2(x, -0.46), 0.13, 0.16), Color("#F7A8D0"), r, t * 0.8)
	var cuerpo := D._unir([D._el(c, r, Vector2(-0.1, 0.24), 0.54, 0.44), D._el(c, r, Vector2(0.38, -0.1), 0.34, 0.3)])
	D._pintar(l, cuerpo, color, r, t)
	D._dentro(l, D._el(c, r, Vector2(0.0, 0.46), 0.36, 0.2), cuerpo, color.lightened(0.45))
	for x in [-0.2, 0.2]:
		D._detalle(l, D._el(c, r, Vector2(x, 0.66), 0.1, 0.06), Color("#F7A8D0"), t * 0.5)
	Figura.dibujar_cara(l, c + Vector2(0.4, -0.1) * r, r * 0.42)
	l.draw_circle(c + Vector2(0.7, -0.04) * r, r * 0.04, Color("#FF7EB6"))


static func _hueso(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var hueso := D._unir([D._caja(c, r, -0.56, -0.14, 0.56, 0.14), D._el(c, r, Vector2(-0.62, -0.18), 0.2, 0.2), D._el(c, r, Vector2(-0.62, 0.18), 0.2, 0.2),
		D._el(c, r, Vector2(0.62, -0.18), 0.2, 0.2), D._el(c, r, Vector2(0.62, 0.18), 0.2, 0.2)])
	D._pintar(l, hueso, color, r, t)


static func _pelota(l, color: Color, c: Vector2, r: float, t: float) -> void:
	var pelota := D._el(c, r, Vector2.ZERO, 0.7, 0.7, 40)
	D._pintar(l, pelota, color, r, t)
	D._dentro(l, D._caja(c, r, -1.0, -0.12, 1.0, 0.12), pelota, BLANCO)
	D._dentro(l, D._el(c, r, Vector2(0, 0), 0.16, 0.16), pelota, DORADO)
	D._dentro(l, D._el(c, r, Vector2(-0.3, -0.4), 0.14, 0.08), pelota, Color(1, 1, 1, 0.55))


static func _bandera_chile(l, _color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, D._caja(c, r, -0.82, -0.92, -0.7, 0.95, 0.05), METAL, r, t)
	var paño := D._caja(c, r, -0.7, -0.88, 0.9, -0.06)
	l.draw_colored_polygon(paño, Color("#D52B1E"))
	l.draw_colored_polygon(D._caja(c, r, -0.7, -0.88, 0.9, -0.47), BLANCO)
	l.draw_colored_polygon(D._caja(c, r, -0.7, -0.88, -0.15, -0.47), Color("#0039A6"))
	l.draw_colored_polygon(Figura.poligono("estrella", c + Vector2(-0.425, -0.675) * r, r * 0.14), BLANCO)
	Figura.contornear(l, paño, t)
	D._detalle(l, D._caja(c, r, -0.98, 0.82, -0.54, 0.98, 0.05), OSCURO, t * 0.7)


static func _destello(l, color: Color, c: Vector2, r: float, t: float) -> void:
	D._pintar(l, _destello_forma(c, r * 0.95), color, r, t)
	D._detalle(l, _destello_forma(c + Vector2(0.62, -0.6) * r, r * 0.28), BLANCO, t * 0.6)


static func _destello_forma(centro: Vector2, radio: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 16:
		var a := -PI / 2.0 + i * PI / 8.0
		var k := 1.0 if i % 4 == 0 else (0.22 if i % 2 == 1 else 0.42)
		puntos.append(centro + Vector2.from_angle(a) * radio * k)
	return puntos
