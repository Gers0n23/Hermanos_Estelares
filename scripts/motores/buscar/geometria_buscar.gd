class_name GeometriaBuscar
extends RefCounted

## Geometria del «Escondite animal» (motor buscar, docs/fichas/motor-buscar.md §6, §11.2 y §15.9).
##
## Una sola fuente de verdad para TRES cosas: lo que se dibuja, lo que tapa y lo que se toca.
## - Cada pieza de la escena (arbusto, roca, carpa...) es una union de primitivas (elipses, rectangulos y
##   poligonos) en coordenadas locales: origen en el pie de la pieza, y hacia arriba negativa, a escala 1.
##   `DibujosBuscar` pinta exactamente esa union como masa (contorno + relleno) y agrega detalles adentro.
## - Cada animal es tambien una union de primitivas en una caja unitaria (alto 1, pie en y = 0), que se
##   escala por su tamano en pantalla. Asi la parte visible se MIDE (muestreo en grilla), no se declara.
## - La zona de toque es la caja de la parte visible + margen, con un minimo por perfil.
##
## Primitiva: {"t": ELIPSE|RECT|POLI, "c": Vector2, "r": Vector2, "p": PackedVector2Array, "rol": String}.
## En ELIPSE "r" son los radios; en RECT, la mitad del ancho y del alto; en POLI vale "p".
## Es generica: no sabe de zonas ni de hermanos (el nivel trae tipo, posicion y escala de todo).

const ELIPSE := 0
const RECT := 1
const POLI := 2
## Muestras por lado de la grilla con que se mide la parte visible de un animal.
const MUESTRAS := 18

static var _cache_animal := {}


# ---------------------------------------------------------------------------
# Primitivas
# ---------------------------------------------------------------------------

static func e(cx: float, cy: float, rx: float, ry: float, rol := "masa") -> Dictionary:
	return {"t": ELIPSE, "c": Vector2(cx, cy), "r": Vector2(rx, ry), "rol": rol}


static func r(cx: float, cy: float, mx: float, my: float, rol := "masa") -> Dictionary:
	return {"t": RECT, "c": Vector2(cx, cy), "r": Vector2(mx, my), "rol": rol}


static func p(puntos: Array, rol := "masa") -> Dictionary:
	var poli := PackedVector2Array()
	for q in puntos:
		poli.append(q)
	return {"t": POLI, "p": poli, "rol": rol}


static func contiene(prim: Dictionary, punto: Vector2) -> bool:
	match int(prim["t"]):
		ELIPSE:
			var d: Vector2 = (punto - prim["c"]) / prim["r"]
			return d.length_squared() <= 1.0
		RECT:
			var d2: Vector2 = (punto - prim["c"]).abs()
			return d2.x <= prim["r"].x and d2.y <= prim["r"].y
		_:
			return Geometry2D.is_point_in_polygon(punto, prim["p"])


static func caja(prim: Dictionary) -> Rect2:
	if int(prim["t"]) == POLI:
		var poli: PackedVector2Array = prim["p"]
		var rect := Rect2(poli[0], Vector2.ZERO)
		for q in poli:
			rect = rect.expand(q)
		return rect
	return Rect2(prim["c"] - prim["r"], prim["r"] * 2.0)


## La primitiva llevada al mundo: `local * escala` (x espejada si `espejo`) + `origen`.
static func transformar(prim: Dictionary, origen: Vector2, escala: float, espejo := false) -> Dictionary:
	var sx := -escala if espejo else escala
	var copia := prim.duplicate()
	if int(prim["t"]) == POLI:
		var poli := PackedVector2Array()
		for q in prim["p"]:
			poli.append(origen + Vector2(q.x * sx, q.y * escala))
		copia["p"] = poli
	else:
		var c: Vector2 = prim["c"]
		copia["c"] = origen + Vector2(c.x * sx, c.y * escala)
		copia["r"] = prim["r"] * escala
	return copia


static func caja_de(prims: Array) -> Rect2:
	var rect := Rect2()
	var primera := true
	for prim in prims:
		var c := caja(prim)
		rect = c if primera else rect.merge(c)
		primera = false
	return rect


static func union_contiene(prims: Array, punto: Vector2) -> bool:
	for prim in prims:
		if contiene(prim, punto):
			return true
	return false


# ---------------------------------------------------------------------------
# Piezas de la escena (locales, escala 1). `abierto` 0-1: escondites que se abren.
# ---------------------------------------------------------------------------

## Tipos que pueden guardar a un animal ADENTRO (se abren con 1 o 2 toques).
const ABRIBLES := ["carpa", "fardo", "flor_gigante", "cueva", "cesto", "tronco_hueco"]
## Tipos de cielo o de fondo que nunca tapan a nadie desde adelante del suelo (solo a quien esta detras).
const TAMANO_NOMINAL := {
	"arbusto": Vector2(220, 160), "roca": Vector2(200, 130), "arbol": Vector2(260, 390),
	"acacia": Vector2(360, 320), "helecho": Vector2(200, 150), "pasto_alto": Vector2(240, 140),
	"juncos": Vector2(150, 190), "nenufar": Vector2(200, 64), "nido": Vector2(150, 60),
	"tronco": Vector2(300, 100), "hongo": Vector2(150, 150), "flor_gigante": Vector2(190, 260),
	"carpa": Vector2(300, 230), "fardo": Vector2(210, 130), "balde": Vector2(100, 84),
	"regadera": Vector2(130, 90), "carretilla": Vector2(230, 120), "gallinero": Vector2(240, 220),
	"cerca": Vector2(270, 100), "bote": Vector2(270, 70), "manguera": Vector2(140, 120),
	"camion": Vector2(240, 140), "cueva": Vector2(360, 260), "volcan": Vector2(540, 340),
	"geiser": Vector2(120, 30), "huesos": Vector2(260, 120), "nube": Vector2(240, 120),
	"cesto": Vector2(150, 110), "tronco_hueco": Vector2(280, 150), "cristales": Vector2(160, 120),
}


static func cobertura_local(tipo: String, abierto := 0.0) -> Array:
	var abre := abierto >= 0.999
	match tipo:
		"arbusto":
			return [e(0, -42, 108, 42), e(-58, -70, 62, 54), e(52, -76, 66, 58), e(0, -106, 66, 54)]
		"roca":
			return [e(0, -54, 100, 54), e(-24, -84, 60, 44), e(36, -74, 46, 40)]
		"arbol":
			return [r(0, -100, 26, 100), e(0, -262, 118, 94), e(-84, -222, 66, 58), e(84, -222, 66, 58), e(0, -330, 78, 58)]
		"acacia":
			return [r(0, -120, 14, 120), e(0, -262, 178, 42), e(-64, -290, 92, 32), e(72, -286, 94, 32)]
		"helecho":
			return [e(0, -46, 96, 46), e(-58, -84, 44, 52), e(58, -84, 44, 52), e(0, -104, 40, 46)]
		"pasto_alto":
			return [r(0, -48, 118, 48), e(0, -96, 112, 36)]
		"juncos":
			return [r(0, -80, 70, 80), e(-34, -170, 12, 22), e(10, -178, 12, 22), e(46, -160, 12, 22)]
		"nenufar":
			return [e(0, -16, 100, 22), e(26, -40, 26, 22)]
		"nido":
			return [e(0, -26, 76, 28)]
		"tronco":
			return [r(0, -50, 128, 50), e(-128, -50, 22, 50), e(128, -50, 22, 50)]
		"tronco_hueco":
			if abre:
				return [r(-110, -70, 28, 70), r(110, -70, 28, 70), r(0, -132, 138, 14)]
			return [r(0, -72, 120, 72), e(-120, -72, 26, 72), e(120, -72, 26, 72)]
		"hongo":
			return [r(0, -46, 24, 46), e(0, -104, 76, 46)]
		"flor_gigante":
			if abre:
				return [r(0, -80, 10, 80), e(-82, -168, 40, 56), e(82, -168, 40, 56), e(0, -110, 62, 22)]
			return [r(0, -80, 10, 80), e(0, -176, 62, 86)]
		"carpa":
			if abre:
				return [e(-118, -88, 40, 88), e(118, -88, 40, 88), e(0, -196, 96, 30)]
			return [e(0, -112, 150, 112), r(0, -56, 150, 56)]
		"fardo":
			if abre:
				return [r(-86, -56, 26, 56), r(86, -56, 26, 56)]
			return [r(0, -64, 92, 64), e(-92, -64, 18, 64), e(92, -64, 18, 64)]
		"cesto":
			if abre:
				return [p([Vector2(-72, 0), Vector2(72, 0), Vector2(76, -40), Vector2(-76, -40)])]
			return [p([Vector2(-62, 0), Vector2(62, 0), Vector2(76, -86), Vector2(-76, -86)]), e(0, -86, 76, 22)]
		"cueva":
			if abre:
				return [e(-132, -112, 56, 112), e(132, -112, 56, 112), e(0, -226, 150, 36)]
			return [e(0, -128, 180, 128), r(0, -60, 180, 60)]
		"balde":
			return [p([Vector2(-40, 0), Vector2(40, 0), Vector2(50, -84), Vector2(-50, -84)])]
		"regadera":
			return [e(-6, -42, 50, 42), p([Vector2(30, -30), Vector2(66, -82), Vector2(74, -74), Vector2(42, -18)])]
		"carretilla":
			return [p([Vector2(-108, -52), Vector2(84, -52), Vector2(106, -116), Vector2(-114, -116)]), e(62, -26, 26, 26)]
		"gallinero":
			return [r(0, -70, 100, 70), p([Vector2(-122, -136), Vector2(0, -220), Vector2(122, -136)])]
		"cerca":
			return [r(0, -40, 132, 9), r(0, -76, 132, 9), r(-118, -50, 11, 50), r(0, -50, 11, 50), r(118, -50, 11, 50)]
		"bote":
			return [p([Vector2(-134, -62), Vector2(134, -62), Vector2(102, 0), Vector2(-102, 0)])]
		"manguera":
			return [e(0, -66, 58, 54), r(0, -10, 54, 10)]
		"camion":
			return [r(-20, -62, 96, 36), r(74, -96, 40, 34), e(-60, -24, 24, 24), e(60, -24, 24, 24)]
		"volcan":
			return [p([Vector2(-270, 0), Vector2(-74, -340), Vector2(74, -340), Vector2(270, 0)])]
		"geiser":
			return [e(0, -14, 60, 14)]
		"huesos":
			return [p([Vector2(-130, -30), Vector2(-120, -52), Vector2(120, -98), Vector2(130, -76)]),
				p([Vector2(-130, -96), Vector2(-120, -74), Vector2(120, -28), Vector2(130, -50)])]
		"nube":
			return [e(0, -48, 96, 40), e(-64, -46, 56, 36), e(64, -46, 56, 36), e(0, -78, 58, 42)]
		"cristales":
			return [p([Vector2(-70, 0), Vector2(-50, -90), Vector2(-20, -10), Vector2(0, -120), Vector2(24, -10), Vector2(52, -84), Vector2(72, 0)])]
	return [e(0, -50, 80, 50)]


## Cobertura de una pieza del nivel en el mundo (con su abierto actual).
static func cobertura(obj: Dictionary, abierto := 0.0) -> Array:
	var origen := vec(obj.get("pos", [0, 0]))
	var escala := float(obj.get("escala", 1.0))
	var espejo := bool(obj.get("espejo", false))
	var salida: Array = []
	for prim in cobertura_local(str(obj.get("tipo", "arbusto")), abierto):
		salida.append(transformar(prim, origen, escala, espejo))
	return salida


static func es_abrible(tipo: String) -> bool:
	return tipo in ABRIBLES


# ---------------------------------------------------------------------------
# Animales (caja unitaria: alto 1, pie en y = 0, mirando a la derecha)
# ---------------------------------------------------------------------------

## Partes del animal normalizadas: {"partes": Array, "cabeza": Vector2, "radio_cabeza": float,
## "hocico": Vector2, "frente": bool}. `aspecto` es el bloque del nivel (forma, cuello, orejas...).
static func animal_local(aspecto: Dictionary) -> Dictionary:
	var clave := JSON.stringify(aspecto)
	if _cache_animal.has(clave):
		return _cache_animal[clave]
	var crudo := _animal_crudo(aspecto)
	var partes: Array = crudo["partes"]
	var rect := caja_de(partes)
	var lado := maxf(rect.size.y, rect.size.x * 0.85)
	var k := 1.0 / maxf(0.001, lado)
	var origen := Vector2(-(rect.position.x + rect.size.x / 2.0), -(rect.position.y + rect.size.y))
	var normal: Array = []
	for prim in partes:
		var movido := transformar(prim, Vector2.ZERO, 1.0)
		movido = _mover(movido, origen)
		normal.append(transformar(movido, Vector2.ZERO, k))
	var salida := {
		"partes": normal,
		"cabeza": (crudo["cabeza"] + origen) * k,
		"radio_cabeza": float(crudo["radio_cabeza"]) * k,
		"hocico": (crudo["hocico"] + origen) * k,
		"frente": bool(crudo.get("frente", false)),
	}
	_cache_animal[clave] = salida
	return salida


static func _mover(prim: Dictionary, d: Vector2) -> Dictionary:
	if int(prim["t"]) == POLI:
		var poli := PackedVector2Array()
		for q in prim["p"]:
			poli.append(q + d)
		prim["p"] = poli
	else:
		prim["c"] = prim["c"] + d
	return prim


static func _animal_crudo(a: Dictionary) -> Dictionary:
	var forma := str(a.get("forma", "sentado"))
	var partes: Array = []
	var cabeza := Vector2.ZERO
	var rc := 0.2
	var hocico := Vector2.ZERO
	var frente := false
	match forma:
		"cuadrupedo", "dino_cuernos":
			var c := float(a.get("cuello", 0.0))
			var gruesas := bool(a.get("patas_gruesas", false))
			var largo := float(a.get("largo", 1.0))
			var mp := 0.075 if gruesas else 0.05
			var alto_pata := float(a.get("alto_patas", 1.0)) * 0.13
			var cy := -alto_pata * 2.0 - 0.17
			partes.append(e(-0.04, cy, 0.34 * largo, 0.2, "cuerpo"))
			for x in [-0.27, -0.12, 0.07, 0.21]:
				partes.append(r(x * largo, -alto_pata, mp, alto_pata + 0.02, "pata"))
			cabeza = Vector2(0.3 * largo + 0.04 * c, cy - 0.2 - 0.34 * c)
			if c > 0.05:
				partes.append(p([Vector2(0.1 * largo, cy - 0.12), Vector2(0.27 * largo, cy - 0.16),
					cabeza + Vector2(0.06, 0.06), cabeza + Vector2(-0.09, 0.02)], "cuerpo"))
			rc = 0.15 if not gruesas else 0.17
			partes.append(e(cabeza.x, cabeza.y, rc, rc * 0.92, "cabeza"))
			var hoc := str(a.get("hocico", "normal"))
			match hoc:
				"largo":
					hocico = cabeza + Vector2(rc * 1.05, rc * 0.45)
					partes.append(e(hocico.x, hocico.y, rc * 0.62, rc * 0.5, "hocico"))
				"trompa":
					hocico = cabeza + Vector2(rc * 1.0, rc * 0.9)
					partes.append(p([cabeza + Vector2(rc * 0.6, 0.0), cabeza + Vector2(rc * 1.25, rc * 0.4),
						cabeza + Vector2(rc * 1.3, rc * 2.0), cabeza + Vector2(rc * 1.0, rc * 2.0), cabeza + Vector2(rc * 0.8, rc * 0.7)], "cabeza"))
				"chato":
					hocico = cabeza + Vector2(rc * 0.7, rc * 0.35)
					partes.append(e(hocico.x, hocico.y, rc * 0.55, rc * 0.45, "hocico"))
				_:
					hocico = cabeza + Vector2(rc * 0.85, rc * 0.35)
					partes.append(e(hocico.x, hocico.y, rc * 0.5, rc * 0.4, "hocico"))
			# Cola.
			partes.append(e(-0.38 * largo, cy - 0.04, 0.07, 0.05, "cuerpo"))
			if forma == "dino_cuernos":
				partes.append(e(cabeza.x - rc * 0.7, cabeza.y - rc * 0.3, rc * 0.75, rc * 1.05, "volante"))
		"sentado":
			partes.append(e(0, -0.3, 0.3, 0.3, "cuerpo"))
			cabeza = Vector2(0, -0.7)
			rc = 0.28
			partes.append(e(0, -0.7, 0.3, 0.26, "cabeza"))
			partes.append(e(-0.15, -0.04, 0.11, 0.05, "pata"))
			partes.append(e(0.15, -0.04, 0.11, 0.05, "pata"))
			hocico = Vector2(0, -0.64)
			frente = true
			if str(a.get("cola", "")) == "larga":
				partes.append(e(0.36, -0.2, 0.14, 0.05, "cuerpo"))
			elif str(a.get("cola", "")) == "pompon":
				partes.append(e(0.27, -0.12, 0.08, 0.08, "panza"))
			elif str(a.get("cola", "")) == "esponjosa":
				partes.append(e(0.32, -0.32, 0.12, 0.2, "cuerpo"))
		"ave", "nadador":
			var acuatica := forma == "nadador"
			var cu := float(a.get("cuello", 0.0))
			if acuatica:
				partes.append(e(-0.04, -0.2, 0.4, 0.2, "cuerpo"))
				partes.append(p([Vector2(-0.42, -0.24), Vector2(-0.56, -0.42), Vector2(-0.3, -0.34)], "cuerpo"))
				cabeza = Vector2(0.24, -0.48 - 0.36 * cu)
				if cu > 0.05:
					partes.append(p([Vector2(0.12, -0.3), Vector2(0.3, -0.3), cabeza + Vector2(0.06, 0.04), cabeza + Vector2(-0.07, 0.0)], "cuerpo"))
			else:
				partes.append(e(-0.02, -0.36, 0.3, 0.25, "cuerpo"))
				partes.append(p([Vector2(-0.26, -0.34), Vector2(-0.52, -0.22 - 0.2 * float(a.get("cola_larga", 0.0))), Vector2(-0.3, -0.5)], "cuerpo"))
				partes.append(r(-0.07, -0.05, 0.022, 0.07, "pico"))
				partes.append(r(0.07, -0.05, 0.022, 0.07, "pico"))
				cabeza = Vector2(0.16, -0.7)
			rc = 0.17
			partes.append(e(cabeza.x, cabeza.y, rc, rc, "cabeza"))
			var pico := str(a.get("pico", "corto"))
			match pico:
				"pato":
					hocico = cabeza + Vector2(rc * 1.2, rc * 0.3)
					partes.append(e(hocico.x, hocico.y, rc * 0.6, rc * 0.3, "pico"))
				"grande":
					hocico = cabeza + Vector2(rc * 1.6, rc * 0.25)
					partes.append(p([cabeza + Vector2(rc * 0.6, -rc * 0.5), cabeza + Vector2(rc * 2.6, rc * 0.1),
						cabeza + Vector2(rc * 0.7, rc * 0.7)], "pico"))
				"largo":
					hocico = cabeza + Vector2(rc * 1.6, rc * 0.3)
					partes.append(p([cabeza + Vector2(rc * 0.8, 0.0), cabeza + Vector2(rc * 2.4, rc * 0.4), cabeza + Vector2(rc * 0.8, rc * 0.5)], "pico"))
				"curvo":
					hocico = cabeza + Vector2(rc * 1.1, rc * 0.4)
					partes.append(p([cabeza + Vector2(rc * 0.7, -rc * 0.2), cabeza + Vector2(rc * 1.5, rc * 0.2), cabeza + Vector2(rc * 1.1, rc * 0.9), cabeza + Vector2(rc * 0.7, rc * 0.5)], "pico"))
				_:
					hocico = cabeza + Vector2(rc * 1.1, rc * 0.25)
					partes.append(p([cabeza + Vector2(rc * 0.8, -rc * 0.15), cabeza + Vector2(rc * 1.5, rc * 0.25), cabeza + Vector2(rc * 0.8, rc * 0.6)], "pico"))
			if bool(a.get("cresta", false)):
				partes.append(e(cabeza.x - rc * 0.1, cabeza.y - rc * 1.05, rc * 0.4, rc * 0.35, "detalle"))
		"zancuda":
			var alto := float(a.get("alto_patas", 1.0))
			partes.append(r(-0.04, -0.22 * alto, 0.018, 0.22 * alto, "pico"))
			partes.append(r(0.05, -0.22 * alto, 0.018, 0.22 * alto, "pico"))
			var yb := -0.44 * alto - 0.12
			partes.append(e(0.0, yb, 0.26, 0.15, "cuerpo"))
			partes.append(p([Vector2(-0.22, yb), Vector2(-0.42, yb + 0.06), Vector2(-0.24, yb - 0.1)], "cuerpo"))
			cabeza = Vector2(0.2, yb - 0.38)
			partes.append(p([Vector2(0.12, yb - 0.08), Vector2(0.22, yb - 0.06), cabeza + Vector2(0.05, 0.05), cabeza + Vector2(-0.04, 0.05)], "cuerpo"))
			rc = 0.11
			partes.append(e(cabeza.x, cabeza.y, rc, rc, "cabeza"))
			hocico = cabeza + Vector2(rc * 1.4, rc * 0.5)
			partes.append(p([cabeza + Vector2(rc * 0.7, -rc * 0.1), cabeza + Vector2(rc * 2.2, rc * 0.9), cabeza + Vector2(rc * 0.7, rc * 0.7)], "pico"))
		"pinguino":
			partes.append(e(0, -0.42, 0.27, 0.4, "cuerpo"))
			partes.append(e(-0.27, -0.42, 0.07, 0.17, "cuerpo"))
			partes.append(e(0.27, -0.42, 0.07, 0.17, "cuerpo"))
			cabeza = Vector2(0, -0.78)
			rc = 0.2
			partes.append(e(0, -0.78, 0.21, 0.19, "cabeza"))
			partes.append(e(-0.1, -0.02, 0.09, 0.04, "pico"))
			partes.append(e(0.1, -0.02, 0.09, 0.04, "pico"))
			hocico = Vector2(0, -0.72)
			partes.append(p([Vector2(-0.06, -0.74), Vector2(0.06, -0.74), Vector2(0.0, -0.64)], "pico"))
			frente = true
		"pez":
			partes.append(e(0.04, -0.42, 0.4, 0.26, "cuerpo"))
			partes.append(p([Vector2(-0.3, -0.42), Vector2(-0.56, -0.66), Vector2(-0.5, -0.42), Vector2(-0.56, -0.18)], "cuerpo"))
			partes.append(p([Vector2(-0.05, -0.64), Vector2(0.12, -0.84), Vector2(0.2, -0.64)], "detalle"))
			cabeza = Vector2(0.22, -0.46)
			rc = 0.2
			hocico = Vector2(0.4, -0.4)
		"tortuga":
			partes.append(r(-0.04, -0.08, 0.36, 0.08, "pata"))
			partes.append(e(-0.04, -0.16, 0.38, 0.3, "caparazon"))
			cabeza = Vector2(0.4, -0.22)
			rc = 0.13
			partes.append(e(0.4, -0.22, 0.14, 0.12, "cabeza"))
			hocico = cabeza + Vector2(rc * 0.8, rc * 0.3)
		"foca":
			partes.append(e(0, -0.36, 0.25, 0.34, "cuerpo"))
			partes.append(e(-0.18, -0.06, 0.16, 0.06, "pata"))
			partes.append(e(0.2, -0.06, 0.16, 0.06, "pata"))
			cabeza = Vector2(0.06, -0.78)
			rc = 0.2
			partes.append(e(0.06, -0.78, 0.2, 0.18, "cabeza"))
			hocico = cabeza + Vector2(rc * 0.8, rc * 0.4)
			partes.append(e(hocico.x, hocico.y, rc * 0.5, rc * 0.36, "hocico"))
		"dino_bipedo":
			partes.append(e(-0.06, -0.42, 0.26, 0.24, "cuerpo"))
			partes.append(p([Vector2(-0.24, -0.5), Vector2(-0.62, -0.18), Vector2(-0.2, -0.3)], "cuerpo"))
			partes.append(r(-0.14, -0.12, 0.07, 0.12, "pata"))
			partes.append(r(0.06, -0.12, 0.07, 0.12, "pata"))
			partes.append(e(0.08, -0.03, 0.1, 0.035, "pata"))
			partes.append(e(-0.12, -0.03, 0.1, 0.035, "pata"))
			cabeza = Vector2(0.22, -0.78)
			rc = 0.21
			partes.append(e(0.22, -0.78, 0.24, 0.18, "cabeza"))
			hocico = cabeza + Vector2(rc * 0.8, rc * 0.25)
			partes.append(e(0.18, -0.48, 0.05, 0.03, "cuerpo"))
			if bool(a.get("vela", false)):
				partes.append(p([Vector2(-0.3, -0.58), Vector2(-0.16, -0.92), Vector2(0.02, -0.98), Vector2(0.14, -0.62)], "detalle"))
		"huevo":
			partes.append(e(0, -0.42, 0.31, 0.42, "cuerpo"))
			cabeza = Vector2(0, -0.48)
			rc = 0.26
			hocico = Vector2(0, -0.42)
			frente = true
		"ballena":
			partes.append(e(0.04, -0.3, 0.5, 0.3, "cuerpo"))
			partes.append(p([Vector2(-0.4, -0.34), Vector2(-0.66, -0.66), Vector2(-0.56, -0.36), Vector2(-0.7, -0.24)], "cuerpo"))
			cabeza = Vector2(0.3, -0.36)
			rc = 0.22
			hocico = Vector2(0.5, -0.24)
		_:
			partes.append(e(0, -0.42, 0.32, 0.42, "cuerpo"))
			cabeza = Vector2(0, -0.6)
			rc = 0.25
			hocico = cabeza
	_agregar_orejas(a, partes, cabeza, rc, forma)
	_agregar_cuernos(a, partes, cabeza, rc)
	return {"partes": partes, "cabeza": cabeza, "radio_cabeza": rc, "hocico": hocico, "frente": frente}


static func _agregar_orejas(a: Dictionary, partes: Array, c: Vector2, rc: float, forma: String) -> void:
	var tipo := str(a.get("orejas", "ninguna"))
	var frente := forma == "sentado"
	var lados := [-1.0, 1.0] if frente else [-1.0]
	for s in lados:
		var base := c + Vector2(s * rc * 0.62, -rc * 0.62) if frente else c + Vector2(-rc * 0.35, -rc * 0.75)
		match tipo:
			"punta":
				partes.append(p([base + Vector2(-rc * 0.32, rc * 0.2), base + Vector2(s * rc * 0.12, -rc * 0.62), base + Vector2(rc * 0.34, rc * 0.18)], "oreja"))
			"caidas":
				var pos := c + Vector2(s * rc * 1.0, -rc * 0.15) if frente else c + Vector2(-rc * 0.55, rc * 0.05)
				partes.append(e(pos.x, pos.y, rc * 0.3, rc * 0.62, "oreja"))
			"largas":
				var pos2 := c + Vector2(s * rc * 0.36, -rc * 1.45) if frente else c + Vector2(-rc * 0.2, -rc * 1.5)
				partes.append(e(pos2.x, pos2.y, rc * 0.2, rc * 0.72, "oreja"))
			"redondas":
				partes.append(e(base.x + s * rc * 0.12, base.y, rc * 0.32, rc * 0.32, "oreja"))
			"grandes":
				partes.append(e(base.x + s * rc * 0.3, base.y + rc * 0.1, rc * 0.52, rc * 0.48, "oreja"))
			"caballo":
				partes.append(p([base + Vector2(-rc * 0.2, rc * 0.2), base + Vector2(-rc * 0.05, -rc * 0.55), base + Vector2(rc * 0.22, rc * 0.15)], "oreja"))
			"elefante":
				partes.append(e(c.x - rc * 0.55, c.y + rc * 0.1, rc * 0.62, rc * 0.82, "oreja"))
			"chicas":
				partes.append(e(base.x, base.y + rc * 0.1, rc * 0.16, rc * 0.2, "oreja"))


static func _agregar_cuernos(a: Dictionary, partes: Array, c: Vector2, rc: float) -> void:
	match str(a.get("cuernos", "")):
		"chicos":
			partes.append(p([c + Vector2(-rc * 0.2, -rc * 0.7), c + Vector2(-rc * 0.05, -rc * 1.35), c + Vector2(rc * 0.12, -rc * 0.75)], "cuerno"))
		"jirafa":
			partes.append(r(c.x - rc * 0.15, c.y - rc * 1.0, rc * 0.08, rc * 0.3, "cuerno"))
			partes.append(e(c.x - rc * 0.15, c.y - rc * 1.32, rc * 0.14, rc * 0.14, "cuerno"))
		"ciervo":
			partes.append(p([c + Vector2(-rc * 0.1, -rc * 0.7), c + Vector2(-rc * 0.3, -rc * 1.6), c + Vector2(-rc * 0.75, -rc * 1.85),
				c + Vector2(-rc * 0.25, -rc * 1.9), c + Vector2(rc * 0.05, -rc * 2.2), c + Vector2(rc * 0.1, -rc * 0.75)], "cuerno"))
		"tri":
			partes.append(p([c + Vector2(rc * 0.1, -rc * 0.6), c + Vector2(rc * 0.9, -rc * 1.3), c + Vector2(rc * 0.4, -rc * 0.4)], "cuerno"))
			partes.append(p([c + Vector2(rc * 0.7, rc * 0.0), c + Vector2(rc * 1.3, -rc * 0.4), c + Vector2(rc * 0.95, rc * 0.25)], "cuerno"))
		"carno":
			partes.append(p([c + Vector2(-rc * 0.4, -rc * 0.6), c + Vector2(-rc * 0.55, -rc * 1.2), c + Vector2(-rc * 0.1, -rc * 0.75)], "cuerno"))


## Partes de un animal en el mundo: pie en `pos`, alto `tamano` px, espejado si `espejo`.
static func animal_mundo(aspecto: Dictionary, pos: Vector2, tamano: float, espejo := false) -> Array:
	var loc := animal_local(aspecto)
	var salida: Array = []
	for prim in loc["partes"]:
		salida.append(transformar(prim, pos, tamano, espejo))
	return salida


# ---------------------------------------------------------------------------
# Visibilidad y zona de toque
# ---------------------------------------------------------------------------

## Mide la parte visible del animal (partes en el mundo) frente a las coberturas que tiene delante.
## Devuelve {"fraccion": 0-1, "caja": Rect2 de lo visible, "centro": Vector2 promedio de lo visible,
## "total": muestras dentro del animal}.
static func medir_visible(partes: Array, coberturas: Array) -> Dictionary:
	var rect := caja_de(partes)
	var cercanas: Array = []
	for cob in coberturas:
		if caja(cob).intersects(rect):
			cercanas.append(cob)
	var total := 0
	var vistas := 0
	var suma := Vector2.ZERO
	var caja_vista := Rect2()
	var hay := false
	for iy in MUESTRAS:
		for ix in MUESTRAS:
			var q := rect.position + Vector2((ix + 0.5) / MUESTRAS * rect.size.x, (iy + 0.5) / MUESTRAS * rect.size.y)
			if not union_contiene(partes, q):
				continue
			total += 1
			if union_contiene(cercanas, q):
				continue
			vistas += 1
			suma += q
			if hay:
				caja_vista = caja_vista.expand(q)
			else:
				caja_vista = Rect2(q, Vector2.ZERO)
				hay = true
	var fraccion := float(vistas) / maxf(1.0, float(total))
	var paso := rect.size / MUESTRAS
	if hay:
		caja_vista = caja_vista.grow_individual(paso.x / 2.0, paso.y / 2.0, paso.x / 2.0, paso.y / 2.0)
	return {"fraccion": fraccion, "caja": caja_vista, "centro": suma / maxf(1.0, float(vistas)) if hay else rect.get_center(),
		"total": total, "hay": hay}


## Zona de toque (ficha §6): caja de lo visible + margen, con un lado minimo. Sin parte visible, la caja
## del animal entero (solo pasa con un escondite cerrado, que se toca por la pieza).
static func zona_toque(medida: Dictionary, partes: Array, margen: float, minimo: float) -> Rect2:
	var base: Rect2 = medida["caja"] if bool(medida.get("hay", false)) else caja_de(partes)
	var zona := base.grow(margen)
	if zona.size.x < minimo:
		zona = zona.grow_individual((minimo - zona.size.x) / 2.0, 0, (minimo - zona.size.x) / 2.0, 0)
	if zona.size.y < minimo:
		zona = zona.grow_individual(0, (minimo - zona.size.y) / 2.0, 0, (minimo - zona.size.y) / 2.0)
	return zona


static func vec(valor) -> Vector2:
	if valor is Vector2:
		return valor
	if valor is Array and valor.size() >= 2:
		return Vector2(float(valor[0]), float(valor[1]))
	return Vector2.ZERO
