extends RefCounted

## Arte PIXEL compartido por los pixel (poc/pixel_demo y el viaje estelar): todo se
## construye en código a resolución de píxel y se escala x4 con filtro "nearest".
## Grillas dibujadas a mano (una letra = un color de PALETA, "." = transparente) y
## figuras con forma + contorno automático de 1 px.
##
## Uso:  const Arte := preload("res://scripts/nucleo/arte_pixel.gd")
##       var tex := Arte.desde_grilla(Arte.COMETA)

const CONTORNO := Color("#2b1a2e")

const PALETA := {
	"K": Color("#2b1a2e"), "W": Color("#ffffff"),
	"T": Color("#5ccbbd"), "t": Color("#3a9e95"), "L": Color("#a6eee2"), "B": Color("#dcf7e6"),
	"E": Color("#4a2812"), "P": Color("#f09a93"), "Y": Color("#ffd23f"), "y": Color("#c98a12"),
	# rocas espaciales
	"R": Color("#9b8579"), "r": Color("#6f5b53"), "l": Color("#c9b3a2"), "c": Color("#54433d"),
	# satélite
	"G": Color("#ffcd3c"), "g": Color("#c98a12"), "S": Color("#4aa8ff"), "s": Color("#2a6fc4"),
	"D": Color("#d6d6e6"), "d": Color("#9a9ab4"), "O": Color("#ff5f7a"),
	# animalitos de Animalia (perrito, gatito, conejito)
	"A": Color("#c98a52"), "a": Color("#8a5a32"), "F": Color("#ffab3d"), "H": Color("#f7f4ff"),
}

# Cometa, 18x21, dibujado a mano desde assets/anclas/cometa_referencia.png (vista frontal).
const COMETA := [
	"...........YY.....",
	"..........YWYY....",
	"...........YY.....",
	"..........tK......",
	"........KKtK......",
	".......KTTTK......",
	"......KLLTTTK.....",
	".....KTLTTTTTK....",
	"....KTLTTTTTTTK...",
	"...KTTTTTTTTTTTK..",
	"..KTTEETTTTTEETTK.",
	"..KTEWETTTTTEWETK.",
	"..KTEEETTTTTEEETK.",
	"..KTPTTTTKTTTTPTK.",
	"...KTTTTTTTTTTTK..",
	"....KKTBBBBBTKK...",
	"..KTKTBBBBBBBTKTK.",
	"..KKKTTBBBBBTTKKK.",
	"....KTTTTTTTTTK...",
	"....KTTTKKKTTTK...",
	".....KKK...KKK....",
]

const DESTELLO := [
	"......K......",
	".....KYK.....",
	".....KYK.....",
	"....KYYYK....",
	"KKKKYYWYYKKKK",
	"KYYYYWWWYYYYK",
	".KYYYYWYYYYK.",
	"..KYYYYYYYK..",
	"...KYYYYYK...",
	"..KYYYKYYYK..",
	"..KYYK.KYYK..",
	".KYK.....KYK.",
	".KK.......KK.",
]

# Roca espacial con carita dormilona (obstáculo amable, no amenazante), 16x14.
const ROCA := [
	".....KKKKK......",
	"...KKlllRRKK....",
	"..KllRRRRRRRK...",
	".KlRRRcRRRRRRK..",
	".KlRRccRRRRRRRK.",
	"KlRRRRRRRRRcRRK.",
	"KRRRKRRRRKRRRRRK",
	"KRRRKRRRRKRRRRrK",
	"KRRRRRRRRRRRRrrK",
	".KRRRRRKKRRRRrK.",
	".KrRRRRRRRRcrrK.",
	"..KrrRRRRRrrrK..",
	"...KKrrrrrrKK...",
	".....KKKKKK.....",
]

# Roca chica (la que viene en "lluvia de meteoritos"), 10x9.
const ROCA_CHICA := [
	"...KKKK...",
	"..KllRRK..",
	".KlRRRRRK.",
	"KlRKRRKRRK",
	"KRRRRRRRrK",
	"KRRRKKRrrK",
	".KRRRRrrK.",
	"..KrrrrK..",
	"...KKKK...",
]

# Satélite con paneles solares, antena y luz roja, 28x13.
const SATELITE := [
	"..............O.............",
	"..............d.............",
	".............KdK............",
	"KKKKKKKKKK..KGGGK..KKKKKKKKKK",
	"KSsSsSsSsK..KGWGGK.KSsSsSsSsK",
	"KsSsSsSsSKddKGGGgKdKsSsSsSsSK",
	"KSsSsSsSsKddKGGggKdKSsSsSsSsK",
	"KsSsSsSsSK..KgggK..KsSsSsSsSK",
	"KKKKKKKKKK...KDK...KKKKKKKKKK",
	"............KDDDK...........",
	"...........KDDDDDK..........",
	"............KKKKK...........",
	"............................",
]


static func desde_grilla(filas: Array) -> ImageTexture:
	var ancho := 0
	for fila in filas:
		ancho = maxi(ancho, (fila as String).length())
	var img := Image.create(ancho, filas.size(), false, Image.FORMAT_RGBA8)
	for y in filas.size():
		var fila: String = filas[y]
		for x in fila.length():
			var c: String = fila[x]
			if c != ".":
				img.set_pixel(x, y, PALETA[c])
	return ImageTexture.create_from_image(img)


static func _dentro_elipse(x: float, y: float, cx: float, cy: float, rx: float, ry: float) -> bool:
	return pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2) <= 1.0


static func contornear(img: Image) -> void:
	var copia := img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if copia.get_pixel(x, y).a > 0:
				continue
			for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + v
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and copia.get_pixelv(q).a > 0:
					img.set_pixel(x, y, CONTORNO)
					break


## Nave-estrella de perfil mirando a la derecha (assets/anclas/nave_estrella_completa_referencia.png):
## cápsula menta, cúpula de vidrio con corazón, anillo de luces doradas, placa dorada,
## ala a rayas blanco/azul/rosa, cola plateada con franja rosada y 3 propulsores.
## Centro de la nave = (25, 16) de la textura; los propulsores salen en PROPULSORES.
const PROPULSORES := [Vector2(9, 12), Vector2(7, 18), Vector2(10, 24)]

static func construir_nave() -> ImageTexture:
	var img := Image.create(50, 32, false, Image.FORMAT_RGBA8)
	var menta := Color("#8fdcc0"); var menta_osc := Color("#5fb89c"); var menta_luz := Color("#c6f2df")
	var vidrio := Color("#bfe8f5"); var vidrio_osc := Color("#7fc3dc")
	var rosa := Color("#ff7fbf"); var rosa_luz := Color("#ffc4e0")
	var oro := Color("#ffcd3c"); var oro_osc := Color("#c98a12")
	var plata := Color("#d6d6e6"); var plata_osc := Color("#9a9ab4")
	var azul := Color("#4aa8ff"); var nucleo := Color("#fff27a")
	for centro in PROPULSORES:
		for y in 32:
			for x in 50:
				var d := Vector2(x, y).distance_to(centro)
				if d <= 1.6:
					img.set_pixel(x, y, nucleo)
				elif d <= 3.4:
					img.set_pixel(x, y, plata if x > centro.x - 1 else plata_osc)
	for y in 32:
		for x in 50:
			if _dentro_elipse(x, y, 29, 18, 18, 10):
				var c := menta
				if y > 22 or x > 43:
					c = menta_osc
				elif _dentro_elipse(x, y, 25, 13, 12, 3.2) and not _dentro_elipse(x, y, 25, 14.5, 11, 3):
					c = menta_luz
				if x >= 11 and x <= 16:
					c = plata if y < 22 else plata_osc
					if x >= 14 and x <= 15:
						c = rosa
				img.set_pixel(x, y, c)
	for y in 32:
		for x in 50:
			if y <= 10 and _dentro_elipse(x, y, 29, 9, 7, 7.5):
				img.set_pixel(x, y, vidrio_osc if x >= 33 else vidrio)
	for p in [Vector2(25, 4), Vector2(26, 3), Vector2(25, 5)]:
		img.set_pixelv(p, Color.WHITE)
	var corazon := ["RR.RR", "RrRRR", "RRRRR", ".RRR.", "..R.."]
	for fy in corazon.size():
		for fx in corazon[fy].length():
			var ch: String = corazon[fy][fx]
			if ch != ".":
				img.set_pixel(27 + fx, 4 + fy, rosa_luz if ch == "r" else rosa)
	for x in range(21, 38):
		img.set_pixel(x, 10, oro_osc)
		img.set_pixel(x, 11, oro if x % 3 == 0 else oro_osc)
	for y in range(14, 17):
		for x in range(30, 39):
			img.set_pixel(x, y, oro if y < 16 else oro_osc)
	img.set_pixel(31, 15, Color.WHITE); img.set_pixel(33, 15, Color.WHITE); img.set_pixel(35, 15, Color.WHITE)
	for y in range(22, 30):
		var inicio := 17 - (y - 22)
		for x in range(inicio, inicio + 17):
			var u := x - inicio
			var c := Color.WHITE
			if u < 5:
				c = azul
			elif u > 11:
				c = rosa_luz
			img.set_pixel(x, y, c)
	for p in [Vector2(10, 25), Vector2(9, 26), Vector2(10, 26), Vector2(11, 26), Vector2(10, 27)]:
		img.set_pixelv(p, Color.WHITE)
	contornear(img)
	return ImageTexture.create_from_image(img)


## Planeta a franjas con sombreado de esfera en 3 tonos (el Arcoíris por defecto).
static func construir_planeta(r: int = 30, colores: Array = [Color("#ff7f9f"), Color("#ffb86b"), Color("#ffe66b"), Color("#8fe39a"), Color("#6bc7ff"), Color("#b69bff")]) -> ImageTexture:
	var img := Image.create(r * 2 + 2, r * 2 + 2, false, Image.FORMAT_RGBA8)
	var alto_banda := maxf(2.0, r / 3.0)
	for y in r * 2 + 2:
		for x in r * 2 + 2:
			var d := Vector2(x - r, y - r)
			if d.length() > r:
				continue
			var banda := int(floor((y + 0.25 * sin(x * 0.2) * 6) / alto_banda)) % colores.size()
			var c: Color = colores[banda]
			var luz := d.normalized().dot(Vector2(-0.6, -0.8)) * (d.length() / r)
			if d.length() > r - 1.5:
				c = CONTORNO
			elif luz < -0.35:
				c = c.darkened(0.35)
			elif luz > 0.45:
				c = c.lightened(0.35)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# --- mundos del viaje estelar (27-Sep-2026) ----------------------------------------
# Cada planeta tiene su bolita (barra de trayecto y llegada), su horizonte curvo (se ve
# al despegar/aterrizar) y su paisaje de superficie (cielo + suelo con sus cosas), para
# que despegar de la Tierra no se vea igual que despegar de Animalia ni aterrizar en
# Melodía igual que en Corazón.

## Cielo de cada planeta: [arriba, horizonte].
const CIELOS := {
	"tierra": [Color("#6bb8ff"), Color("#c9ecff")],
	"arcoiris": [Color("#ff9ed6"), Color("#ffe3b0")],
	"animalia": [Color("#8fe0c8"), Color("#f4ffc0")],
	"melodia": [Color("#8f6fe8"), Color("#e6c9ff")],
	"cuenta_cuentas": [Color("#1c1f5a"), Color("#4a3f9e")],
	"letralandia": [Color("#ffb86b"), Color("#fff1b0")],
	"corazon": [Color("#ff7fbf"), Color("#ffd6ea")],
}

const PERRITO := [
	"..KKKKKKKK..",
	".KAAAAAAAAK.",
	"KaKAAAAAAKaK",
	"KaKAKAAKAKaK",
	"KaKAAAAAAKaK",
	"KaKPWWWWPKaK",
	".K.KWKKWK.K.",
	"...KWWWWK...",
	"....KKKK....",
]

const GATITO := [
	"K........K",
	"KK......KK",
	"KPK....KPK",
	"KFFKKKKFFK",
	"KFFFFFFFFK",
	"KFKFFFFKFK",
	"KFFFFFFFFK",
	"KPFFKKFFPK",
	".KFFWWFFK.",
	"..KKKKKK..",
]

const CONEJITO := [
	"..KK...KK.",
	".KHPK.KPHK",
	".KHPK.KPHK",
	".KHPK.KPHK",
	".KKHKKKHKK",
	"KHHHHHHHHK",
	"KHKHHHHKHK",
	"KHHHHHHHHK",
	"KPHHKKHHPK",
	".KHHHHHHK.",
	"..KKKKKK..",
]

const CORAZON := [
	".KK.KK.",
	"KOOKOOK",
	"KOWOOOK",
	".KOOOK.",
	"..KOK..",
	"...K...",
]

const NOTA := [
	"...KKK",
	"...KYK",
	"...K.K",
	"...K..",
	".KKK..",
	"KYYK..",
	"KYYK..",
	".KK...",
]

## Letras y números de 3x5 para los bloques de Letralandia y las estrellas de Cuenta-Cuentas.
const GLIFOS := {
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"],
	"3": ["##.", "..#", ".#.", "..#", "##."],
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
}


static func _hash(x: float, y: float, s: float) -> float:
	return fposmod(sin(x * 127.1 + y * 311.7 + s * 74.7) * 43758.5453, 1.0)


static func _ruido(x: float, y: float, s: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_hash(ix, iy, s), _hash(ix + 1, iy, s), fx),
		lerpf(_hash(ix, iy + 1, s), _hash(ix + 1, iy + 1, s), fx), fy)


## Color de la superficie del planeta `id` en (u, v) normalizados (0..1 sobre el disco).
static func _color_mundo(id: String, u: float, v: float, r: float) -> Color:
	var k := r / 30.0  # el patrón conserva su tamaño en píxeles aunque el disco sea enorme
	match id:
		"tierra":
			if r <= 60 and (v < 0.07 or v > 0.93):  # polos solo en la bolita, no en el horizonte
				return Color("#f4fbff")
			if _ruido(u * 6.0 * k, v * 5.0 * k, 3.0) > 0.72:
				return Color.WHITE
			return Color("#6cc24a") if _ruido(u * 4.0 * k, v * 4.0 * k, 1.0) > 0.5 else Color("#4a9bea")
		"animalia":
			if _ruido(u * 4.0 * k, v * 4.0 * k, 5.0) > 0.62:
				return Color("#2f8a3e")
			return Color("#c9dc6a") if _ruido(u * 5.0 * k, v * 5.0 * k, 8.0) > 0.58 else Color("#6fc24a")
		"melodia":
			var t := v * 6.0 * k + 0.5 * sin(u * 14.0 * k)
			if fposmod(t, 1.0) < 0.14:
				return Color("#ffe66b")
			return Color("#b69bff") if posmod(int(floor(t)), 2) == 0 else Color("#8f6fe8")
		"cuenta_cuentas":
			if _hash(floor(u * 60.0 * k), floor(v * 60.0 * k), 2.0) > 0.975:
				return Color("#ffe66b")
			if _ruido(u * 5.0 * k, v * 5.0 * k, 4.0) > 0.64:
				return Color("#5a5fb8")
			return Color("#3a3f8e") if v < 0.5 else Color("#2a2f6e")
		"letralandia":
			if _ruido(u * 5.0 * k, v * 5.0 * k, 9.0) > 0.72:
				return Color("#4fd8e0")
			var t := v * 5.0 * k + 0.35 * sin(u * 10.0 * k)
			return Color("#ffd08a") if posmod(int(floor(t)), 2) == 0 else Color("#f0a860")
		"corazon":
			var cx := int(floor(u * 8.0 * k))
			var cy := int(floor(v * 8.0 * k))
			var fx := int(fposmod(u * 8.0 * k, 1.0) * 7.0)
			var fy := int(fposmod(v * 8.0 * k, 1.0) * 7.0)
			if (cx + cy) % 2 == 0 and fy < CORAZON.size() and fx < 7 and CORAZON[fy][fx] != ".":
				return Color.WHITE if CORAZON[fy][fx] != "K" else Color("#ff3f8f")
			return Color("#ff9ed6") if v < 0.5 else Color("#ff6fae")
	# arcoiris (y por defecto): franjas onduladas
	var colores := [Color("#ff7f9f"), Color("#ffb86b"), Color("#ffe66b"), Color("#8fe39a"), Color("#6bc7ff"), Color("#b69bff")]
	var banda := int(floor((v * 2.0 * r + 1.5 * sin(u * 2.0 * r * 0.2)) / maxf(2.0, r / 3.0)))
	return colores[posmod(banda, colores.size())]


## Disco del planeta `id` en pixel art (radio r). Con `alto` > 0 devuelve solo la franja
## superior del disco (el "horizonte curvo" de un planeta gigante, barato de construir).
static func construir_mundo(id: String, r: int = 30, alto: int = 0) -> ImageTexture:
	var lado := r * 2 + 2
	var img := Image.create(lado, alto if alto > 0 else lado, false, Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in lado:
			var d := Vector2(x - r, y - r)
			var largo := d.length()
			if largo > r:
				continue
			var c := _color_mundo(id, float(x) / (r * 2), float(y) / (r * 2), r)
			var luz := d.normalized().dot(Vector2(-0.6, -0.8)) * (largo / r)
			if largo > r - 1.5:
				c = CONTORNO
			elif largo > r - 4.0 and alto > 0:
				c = c.lerp(Color.WHITE, 0.45)  # atmósfera en el borde del horizonte
			elif luz < -0.35 and alto == 0:
				c = c.darkened(0.3)
			elif luz > 0.45 and alto == 0:
				c = c.lightened(0.3)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Cielo del planeta en franjas (degradado escalonado, bien pixel) con sus adornos fijos.
static func construir_cielo(id: String, ancho: int = 320, alto: int = 180) -> ImageTexture:
	var img := Image.create(ancho, alto, false, Image.FORMAT_RGBA8)
	var colores: Array = CIELOS.get(id, CIELOS["arcoiris"])
	for y in alto:
		var paso := floorf(float(y) / alto * 9.0) / 8.0
		img.fill_rect(Rect2i(0, y, ancho, 1), (colores[0] as Color).lerp(colores[1], paso))
	match id:
		"tierra":
			_disco(img, Vector2(262, 34), 13, Color("#ffe66b"))
			for nube in [Vector2(60, 40), Vector2(170, 26), Vector2(230, 70)]:
				_nube(img, nube)
		"arcoiris":
			var arco := [Color("#ff7f9f"), Color("#ffb86b"), Color("#ffe66b"), Color("#8fe39a"), Color("#6bc7ff"), Color("#b69bff")]
			for i in arco.size():
				_anillo(img, Vector2(220, 150), 92 - i * 4, 4, arco[i])
			_nube(img, Vector2(142, 128))
			_nube(img, Vector2(298, 126))
		"animalia":
			_disco(img, Vector2(56, 34), 12, Color("#fff27a"))
			_nube(img, Vector2(190, 40))
			_nube(img, Vector2(280, 64))
		"melodia":
			for i in 3:
				for x in ancho:
					var y := int(50 + i * 22 + 5 * sin(x * 0.06 + i))
					img.set_pixel(x, clampi(y, 0, alto - 1), Color(1, 1, 1, 0.5))
		"cuenta_cuentas":
			var rng := RandomNumberGenerator.new()
			rng.seed = 21
			for i in 70:
				img.set_pixel(rng.randi_range(0, ancho - 1), rng.randi_range(0, 120), Color(1, 1, 0.8, rng.randf_range(0.5, 1.0)))
			_disco(img, Vector2(250, 38), 15, Color("#fff4c2"))
			_disco(img, Vector2(257, 33), 12, colores[0])  # luna creciente
		"letralandia":
			_disco(img, Vector2(70, 46), 16, Color("#fff27a"))
			_disco(img, Vector2(70, 46), 11, Color("#ffd23f"))
		"corazon":
			for p in [Vector2(40, 30), Vector2(120, 60), Vector2(210, 24), Vector2(280, 70)]:
				_grilla(img, CORAZON, p, {"O": Color("#ffb0d8"), "W": Color.WHITE, "K": Color("#ff6fae")})
	return ImageTexture.create_from_image(img)


## Altura de la superficie (en px desde arriba de la textura de suelo) según el planeta.
static func altura_suelo(id: String, x: float) -> int:
	match id:
		"tierra": return int(50 + 3.0 * sin(x * 0.03))
		"arcoiris": return int(50 + 4.0 * sin(x * 0.045 + 1.0))
		"animalia": return int(50 + 2.0 * sin(x * 0.08))
		"melodia": return 50
		"cuenta_cuentas": return int(50 + 2.0 * sin(x * 0.11) + 1.5 * sin(x * 0.37))
		"letralandia": return int(50 + 6.0 * sin(x * 0.028 + 2.0))
		"corazon": return int(50 + 3.0 * sin(x * 0.05))
	return 50


## Superficie efectiva: plana alrededor de la plataforma de la nave.
static func altura_con_plataforma(id: String, x: float, x_plataforma: int) -> int:
	if absf(x - x_plataforma) < 24:
		return altura_suelo(id, x_plataforma)
	return altura_suelo(id, x)


## Suelo del planeta (320x90, superficie ~50 px abajo) con sus cosas fijas: la casa de los niños en la Tierra,
## chupetines en Arcoíris, palmeras en Animalia, teclas en Melodía, cráteres en
## Cuenta-Cuentas, dunas con cactus en Letralandia y arbolitos-corazón en Corazón.
## Alrededor de la plataforma de la nave (`x_plataforma` ± 24) el suelo queda plano.
static func construir_suelo(id: String, x_plataforma: int) -> ImageTexture:
	var ancho := 320
	var alto := 90
	var img := Image.create(ancho, alto, false, Image.FORMAT_RGBA8)
	var capas: Array = {
		"tierra": [Color("#6cc24a"), Color("#4fa53a"), Color("#a0673a"), Color("#7d4f2c")],
		"arcoiris": [Color("#ff7f9f"), Color("#ffb86b"), Color("#ffe66b"), Color("#8fe39a"), Color("#6bc7ff"), Color("#b69bff")],
		"animalia": [Color("#8fd65a"), Color("#6fc24a"), Color("#4f9e3a"), Color("#3a7a2e")],
		"melodia": [Color("#6a4fc8"), Color("#5a3fb0"), Color("#4a3398")],
		"cuenta_cuentas": [Color("#5a4f9e"), Color("#473d86"), Color("#372f6e")],
		"letralandia": [Color("#ffd08a"), Color("#f7bd72"), Color("#f0a860")],
		"corazon": [Color("#ff9ed6"), Color("#ff85c4"), Color("#ff6fae")],
	}.get(id, [Color("#8fe39a"), Color("#6bc7ff")])
	for x in ancho:
		var h := altura_con_plataforma(id, x, x_plataforma)
		for y in range(h, alto):
			var capa := mini(int((y - h) / 5), capas.size() - 1)
			if id == "arcoiris":
				capa = int((y - h) / 4) % capas.size()
			img.set_pixel(x, y, capas[capa])
		img.set_pixel(x, h, CONTORNO)
		if id in ["tierra", "animalia"] and posmod(x * 7, 5) == 0:
			img.set_pixel(x, h - 1, (capas[1] as Color))  # pastito
	match id:
		"tierra":
			_casa(img, Vector2i(236, altura_suelo(id, 236)))
			_arbol(img, Vector2i(30, altura_suelo(id, 30)), Color("#4fa53a"))
			_arbol(img, Vector2i(296, altura_suelo(id, 296)), Color("#6cc24a"))
			for x in range(172, 214, 4):  # rejita del jardín
				img.fill_rect(Rect2i(x, altura_suelo(id, x) - 6, 1, 6), Color.WHITE)
				img.fill_rect(Rect2i(x, altura_suelo(id, x) - 4, 4, 1), Color.WHITE)
		"arcoiris":
			for p in [30, 214, 288]:
				_chupetin(img, Vector2i(p, altura_suelo(id, p)))
		"animalia":
			for p in [24, 212, 302]:
				_palmera(img, Vector2i(p, altura_suelo(id, p)))
		"melodia":
			for x in ancho:
				if absi(x - x_plataforma) < 24:
					continue
				var tecla := Color.WHITE if posmod(x, 8) != 0 else CONTORNO
				img.fill_rect(Rect2i(x, 51, 1, 9), tecla)
				if posmod(x, 8) in [5, 6] and posmod(x / 8, 7) not in [2, 6]:
					img.fill_rect(Rect2i(x, 51, 1, 5), CONTORNO)
			img.fill_rect(Rect2i(0, 60, ancho, 1), CONTORNO)
		"cuenta_cuentas":
			for p in [40, 214, 280]:
				_anillo(img, Vector2(p, altura_suelo(id, p) + 7), 6, 2, Color("#372f6e"))
		"letralandia":
			for p in [30, 292]:
				_cactus(img, Vector2i(p, altura_suelo(id, p)))
		"corazon":
			for p in [30, 214, 292]:
				var base := altura_suelo(id, p)
				img.fill_rect(Rect2i(p - 1, base - 10, 2, 10), Color("#a0673a"))
				_grilla(img, CORAZON, Vector2(p - 3, base - 16), {"O": Color("#ff3f8f"), "W": Color("#ffc4e0"), "K": CONTORNO})
	return ImageTexture.create_from_image(img)


static func _disco(img: Image, centro: Vector2, r: float, color: Color) -> void:
	for y in range(int(centro.y - r), int(centro.y + r) + 1):
		for x in range(int(centro.x - r), int(centro.x + r) + 1):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and Vector2(x, y).distance_to(centro) <= r:
				img.set_pixel(x, y, color)


static func _anillo(img: Image, centro: Vector2, r: float, grosor: float, color: Color) -> void:
	for y in range(int(centro.y - r), int(centro.y + r) + 1):
		for x in range(int(centro.x - r), int(centro.x + r) + 1):
			var d := Vector2(x, y).distance_to(centro)
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and d <= r and d > r - grosor:
				img.set_pixel(x, y, color)


static func _nube(img: Image, p: Vector2) -> void:
	for c in [Vector2(-7, 2), Vector2(0, 0), Vector2(7, 2)]:
		_disco(img, p + c, 5 if c.x == 0 else 4, Color.WHITE)
	img.fill_rect(Rect2i(int(p.x) - 10, int(p.y) + 5, 21, 2), Color(0.85, 0.9, 1.0))


static func _grilla(img: Image, filas: Array, p: Vector2, colores: Dictionary = {}) -> void:
	for fy in filas.size():
		for fx in (filas[fy] as String).length():
			var ch: String = filas[fy][fx]
			var x := int(p.x) + fx
			var y := int(p.y) + fy
			if ch != "." and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, colores.get(ch, PALETA.get(ch, CONTORNO)))


static func _casa(img: Image, base: Vector2i) -> void:
	# la casa de los niños: ahí empieza la aventura (el living de su casa)
	img.fill_rect(Rect2i(base.x - 16, base.y - 20, 32, 20), CONTORNO)
	img.fill_rect(Rect2i(base.x - 15, base.y - 19, 30, 19), Color("#ffe3b0"))
	img.fill_rect(Rect2i(base.x + 8, base.y - 34, 4, 10), CONTORNO)
	img.fill_rect(Rect2i(base.x + 9, base.y - 33, 2, 9), Color("#c98a52"))
	for i in 13:
		img.fill_rect(Rect2i(base.x - 20 + i, base.y - 20 - i, 40 - i * 2, 1), CONTORNO if i == 12 else Color("#ff6b6b"))
		img.set_pixel(base.x - 20 + i, base.y - 20 - i, CONTORNO)
		img.set_pixel(base.x + 19 - i, base.y - 20 - i, CONTORNO)
	img.fill_rect(Rect2i(base.x - 20, base.y - 20, 40, 1), CONTORNO)
	img.fill_rect(Rect2i(base.x - 11, base.y - 15, 8, 7), CONTORNO)
	img.fill_rect(Rect2i(base.x - 10, base.y - 14, 6, 5), Color("#fff27a"))
	img.fill_rect(Rect2i(base.x - 7, base.y - 14, 1, 5), CONTORNO)
	img.fill_rect(Rect2i(base.x + 3, base.y - 12, 7, 12), CONTORNO)
	img.fill_rect(Rect2i(base.x + 4, base.y - 11, 5, 11), Color("#4aa8ff"))
	img.set_pixel(base.x + 8, base.y - 6, Color("#ffd23f"))


static func _arbol(img: Image, base: Vector2i, hojas: Color) -> void:
	img.fill_rect(Rect2i(base.x - 2, base.y - 12, 4, 12), CONTORNO)
	img.fill_rect(Rect2i(base.x - 1, base.y - 12, 2, 12), Color("#a0673a"))
	_disco(img, Vector2(base.x, base.y - 18), 9, CONTORNO)
	_disco(img, Vector2(base.x, base.y - 18), 8, hojas)
	_disco(img, Vector2(base.x - 3, base.y - 21), 3, hojas.lightened(0.25))


static func _chupetin(img: Image, base: Vector2i) -> void:
	img.fill_rect(Rect2i(base.x, base.y - 16, 2, 16), Color.WHITE)
	_disco(img, Vector2(base.x + 1, base.y - 22), 8, CONTORNO)
	for i in 4:
		_disco(img, Vector2(base.x + 1, base.y - 22), 7 - i * 2, [Color("#ff7fbf"), Color.WHITE, Color("#6bc7ff"), Color("#ffe66b")][i])


static func _palmera(img: Image, base: Vector2i) -> void:
	for y in 18:
		var x := base.x + int(y * y / 90.0)
		img.fill_rect(Rect2i(x - 1, base.y - y - 1, 3, 1), CONTORNO if y % 3 == 0 else Color("#a0673a"))
	var copa := Vector2(base.x + 3, base.y - 19)
	for hoja in [Vector2(-9, 3), Vector2(9, 3), Vector2(-6, -3), Vector2(6, -3), Vector2(0, -5)]:
		for i in 8:
			var p: Vector2 = copa + hoja * i / 8.0 + Vector2(0, (i * i) / 14.0)
			img.fill_rect(Rect2i(int(p.x) - 1, int(p.y), 3, 2), Color("#3a8a3e"))
	_disco(img, copa + Vector2(0, 2), 2, Color("#7d4f2c"))


static func _cactus(img: Image, base: Vector2i) -> void:
	img.fill_rect(Rect2i(base.x - 3, base.y - 18, 6, 18), CONTORNO)
	img.fill_rect(Rect2i(base.x - 2, base.y - 17, 4, 17), Color("#5fb85a"))
	img.fill_rect(Rect2i(base.x - 8, base.y - 12, 5, 3), CONTORNO)
	img.fill_rect(Rect2i(base.x - 8, base.y - 16, 3, 5), CONTORNO)
	img.fill_rect(Rect2i(base.x - 7, base.y - 15, 1, 4), Color("#5fb85a"))
	img.fill_rect(Rect2i(base.x + 3, base.y - 9, 5, 3), CONTORNO)
	img.fill_rect(Rect2i(base.x + 5, base.y - 13, 3, 5), CONTORNO)
	img.fill_rect(Rect2i(base.x + 6, base.y - 12, 1, 4), Color("#5fb85a"))
	img.set_pixel(base.x, base.y - 19, Color("#ff7fbf"))
