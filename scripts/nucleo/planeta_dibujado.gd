class_name PlanetaDibujado
extends Node2D
## Planeta redondo del mapa estelar: esfera con `planeta.gdshader` (superficie que gira,
## luz, contorno y atmosfera) mas los adornos que hacen especial a cada mundo (GDD §4),
## dibujados por codigo y animados: el arcoiris de Arcoiris, los arboles de Animalia, el
## anillo con notas de Melodia, la luna y los numeros de Cuenta-Cuentas, los bloques con
## letras de Letralandia y las nubes con corazones de Corazon.
##
## Uso: var p := PlanetaDibujado.new(); p.id_planeta = "melodia"; p.radio = 60; add_child(p)

const RUTA_SHADER := "res://assets/shaders/planeta.gdshader"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const RADIO_ESFERA := 0.8
const CONTORNO := Color("3b2140")

## patron + 6 colores + atmosfera + velocidad de giro, por planeta.
const ESTILOS := {
	"tierra": {"patron": 1, "colores": ["3f8fe0", "6fcf6a", "3f9e52", "ffffff", "ffffff", "ffffff"], "atmosfera": "a8e4ff", "velocidad": 0.012, "nivel_mar": 0.42},
	"arcoiris": {"patron": 0, "colores": ["ff9ec7", "ffb86b", "ffe66b", "8fe39a", "7fd3ff", "b69bff"], "atmosfera": "fff0fb", "velocidad": 0.01},
	"animalia": {"patron": 1, "colores": ["c9dc6a", "6fc24a", "2f8a3e", "f4ffe8", "ffffff", "ffffff"], "atmosfera": "d5ffb8", "velocidad": 0.012, "nivel_mar": 0.36},
	"melodia": {"patron": 2, "colores": ["a06bff", "ff6bd6", "fff2ff", "ffffff", "ffffff", "ffffff"], "atmosfera": "ff9ef0", "velocidad": 0.02},
	"cuenta_cuentas": {"patron": 3, "colores": ["26307a", "4a6ae0", "8fb0ff", "fff6b0", "ffffff", "ffffff"], "atmosfera": "8fb8ff", "velocidad": 0.01},
	"letralandia": {"patron": 4, "colores": ["ffb35c", "ff8a3d", "ffe0a0", "6fd6a0", "ffffff", "ffffff"], "atmosfera": "ffd9a0", "velocidad": 0.012},
	"corazon": {"patron": 5, "colores": ["ffb3d6", "9fdcff", "ff5f9e", "ffffff", "ffffff", "ffffff"], "atmosfera": "ffe0f0", "velocidad": 0.012},
}

const ARCOIRIS := ["ff6b6b", "ff9f4a", "ffcb3d", "7dd87a", "6fd6e8", "b48ce8"]

@export var id_planeta := "arcoiris"
@export var radio := 70.0
## Planeta todavia sin visitar: se ve lejano y tenue (GDD §3: nunca candado).
@export var apagado := false

var _tiempo := 0.0
var _atras: Node2D
var _adelante: Node2D
var _fuente: Font


func _ready() -> void:
	_fuente = load(RUTA_FUENTE)
	_atras = Node2D.new()
	add_child(_atras)
	_atras.draw.connect(_dibujar_atras)
	var esfera := ColorRect.new()
	var lado := radio * 2.0 / RADIO_ESFERA
	esfera.size = Vector2(lado, lado)
	esfera.position = -esfera.size / 2.0
	esfera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esfera.material = _material()
	add_child(esfera)
	_adelante = Node2D.new()
	add_child(_adelante)
	_adelante.draw.connect(_dibujar_adelante)
	if apagado:
		modulate = Color(0.86, 0.84, 0.95, 0.88)


func _material() -> ShaderMaterial:
	var estilo: Dictionary = ESTILOS.get(id_planeta, ESTILOS["arcoiris"])
	var material := ShaderMaterial.new()
	material.shader = load(RUTA_SHADER)
	material.set_shader_parameter("patron", estilo["patron"])
	for i in 6:
		material.set_shader_parameter("color_%d" % i, Color(estilo["colores"][i]))
	material.set_shader_parameter("atmosfera", Color(estilo["atmosfera"]))
	material.set_shader_parameter("contorno", CONTORNO)
	material.set_shader_parameter("velocidad", float(estilo["velocidad"]) * (0.5 if apagado else 1.0))
	material.set_shader_parameter("semilla", float(hash(id_planeta) % 97) / 9.7)
	material.set_shader_parameter("apagado", 0.35 if apagado else 0.0)
	material.set_shader_parameter("radio_esfera", RADIO_ESFERA)
	material.set_shader_parameter("nivel_mar", float(estilo.get("nivel_mar", 0.5)))
	return material


func _process(delta: float) -> void:
	# los lejanos tambien se mueven, pero mas lento (se ven dormiditos, no bloqueados)
	_tiempo += delta * (0.5 if apagado else 1.0)
	_atras.queue_redraw()
	_adelante.queue_redraw()


# --- adornos ---------------------------------------------------------------------------

func _dibujar_atras() -> void:
	match id_planeta:
		"arcoiris":
			_arcoiris()
		"animalia":
			_arboles()
			_animales()
		"melodia":
			_anillo(_atras, true)
			_notas(false)
		"cuenta_cuentas":
			_luna(false)
			_numeros(false)
		"letralandia":
			_letras(false)
		"corazon":
			_corazones_flotando(false)


func _dibujar_adelante() -> void:
	match id_planeta:
		"arcoiris":
			_nube(Vector2(-radio * 1.42, radio * 0.02), radio * 0.2)
			_nube(Vector2(radio * 1.42, radio * 0.02), radio * 0.2)
		"melodia":
			_anillo(_adelante, false)
			_notas(true)
		"cuenta_cuentas":
			_luna(true)
			_numeros(true)
		"letralandia":
			_letras(true)
		"corazon":
			for i in 5:
				var x := lerpf(-radio * 0.95, radio * 0.95, i / 4.0)
				var y := radio * (0.62 + 0.25 * (1.0 - absf(x / radio)))
				_nube(Vector2(x, y + sin(_tiempo * 1.2 + i) * 2.0), radio * (0.2 if i % 2 == 0 else 0.16))
			_corazones_flotando(true)


func _arcoiris() -> void:
	var ancho := radio * 0.075
	for i in ARCOIRIS.size():
		var r := radio * 1.42 - i * ancho
		_atras.draw_arc(Vector2.ZERO, r, PI, TAU, 48, Color(ARCOIRIS[i]), ancho + 1.0, true)
	_atras.draw_arc(Vector2.ZERO, radio * 1.42 + ancho * 0.5, PI, TAU, 48, Color(CONTORNO, 0.5), 2.0, true)


func _arboles() -> void:
	# dos arbolitos a los costados; el protagonismo es de los animales
	for ang in [-PI * 0.93, -PI * 0.07]:
		var dir := Vector2.from_angle(ang)
		var tam := radio * 0.14
		var copa := dir.rotated(sin(_tiempo * 1.5 + ang) * 0.04) * radio * 1.08
		_atras.draw_line(dir * radio * 0.9, copa, Color("7a4a2a"), tam * 0.35, true)
		_atras.draw_circle(copa, tam + 2.0, CONTORNO)
		_atras.draw_circle(copa, tam, Color("58b848"))
		_atras.draw_circle(copa + Vector2(-tam, -tam) * 0.3, tam * 0.35, Color(1, 1, 1, 0.3))


## Caritas de animales asomadas por el borde de Animalia (los favoritos de los hermanos,
## GDD §4: perrito Toby, gatito, dinosaurio, jirafa, conejito). Se dibujan DETRAS de la
## esfera, asi el planeta les tapa el cuello y parecen asomarse; se balancean un poco.
const ANIMALES := ["jirafa", "gato", "perro", "dino", "conejo"]


func _animales() -> void:
	for i in ANIMALES.size():
		var ang := lerpf(-PI * 0.8, -PI * 0.2, i / float(ANIMALES.size() - 1))
		var dir := Vector2.from_angle(ang)
		var tam := radio * (0.31 if ANIMALES[i] == "perro" else 0.27)
		var asomo := 0.5 + 0.5 * sin(_tiempo * 1.3 + i * 1.7)
		var centro := dir * (radio + tam * (0.35 + 0.25 * asomo))
		_cara_animal(_atras, centro, tam, ANIMALES[i], (ang + PI / 2.0) * 0.5)


func _cara_animal(lienzo: Node2D, p: Vector2, tam: float, tipo: String, giro: float) -> void:
	var colores := {
		"perro": [Color("c98a55"), Color("7a4a2a")], "gato": [Color("ffb35c"), Color("e07a2a")],
		"dino": [Color("7fd36a"), Color("3f9a4a")], "jirafa": [Color("ffd66b"), Color("c98a2a")],
		"conejo": [Color("f4eefa"), Color("ffb3d6")],
	}
	var base: Color = colores[tipo][0]
	var detalle: Color = colores[tipo][1]
	var linea := 2.0
	lienzo.draw_set_transform(p, giro, Vector2.ONE)
	# lo que va detras de la cabeza: orejas, cuernitos, puas
	match tipo:
		"perro":
			for s in [-1.0, 1.0]:
				_ovalo(lienzo, Vector2(s * tam * 0.95, tam * 0.05), Vector2(tam * 0.38, tam * 0.7), s * 0.35, detalle, linea)
		"gato":
			for s in [-1.0, 1.0]:
				var oreja := PackedVector2Array([Vector2(s * tam * 0.85, -tam * 0.3), Vector2(s * tam * 0.7, -tam * 1.25), Vector2(s * tam * 0.15, -tam * 0.8)])
				_poligono(lienzo, oreja, base, linea)
				_poligono(lienzo, PackedVector2Array([oreja[0].lerp(oreja[2], 0.2), oreja[1].lerp(oreja[0], 0.25) + Vector2(0, tam * 0.1), oreja[2].lerp(oreja[0], 0.25)]), Color("ffb3d6"), 0.0)
		"conejo":
			for s in [-1.0, 1.0]:
				_ovalo(lienzo, Vector2(s * tam * 0.4, -tam * 1.35), Vector2(tam * 0.28, tam * 0.75), s * 0.15, base, linea)
				_ovalo(lienzo, Vector2(s * tam * 0.4, -tam * 1.3), Vector2(tam * 0.13, tam * 0.55), s * 0.15, detalle, 0.0)
		"dino":
			for k in 3:
				var x := (k - 1) * tam * 0.5
				var alto := tam * (0.55 if k == 1 else 0.4)
				_poligono(lienzo, PackedVector2Array([Vector2(x - tam * 0.25, -tam * 0.75), Vector2(x, -tam * 0.8 - alto), Vector2(x + tam * 0.25, -tam * 0.75)]), Color("ff9ec7"), linea)
		"jirafa":
			for s in [-1.0, 1.0]:
				lienzo.draw_line(Vector2(s * tam * 0.3, -tam * 0.7), Vector2(s * tam * 0.35, -tam * 1.3), CONTORNO, tam * 0.2, true)
				lienzo.draw_line(Vector2(s * tam * 0.3, -tam * 0.7), Vector2(s * tam * 0.35, -tam * 1.3), detalle, tam * 0.12, true)
				lienzo.draw_circle(Vector2(s * tam * 0.35, -tam * 1.35), tam * 0.17 + linea, CONTORNO)
				lienzo.draw_circle(Vector2(s * tam * 0.35, -tam * 1.35), tam * 0.17, Color("a0522d"))
				_ovalo(lienzo, Vector2(s * tam * 0.95, -tam * 0.35), Vector2(tam * 0.32, tam * 0.16), s * 0.4, base, linea)
	# cabeza
	var ancho := 1.12 if tipo in ["gato", "dino"] else 1.0
	_ovalo(lienzo, Vector2.ZERO, Vector2(tam * ancho, tam), 0.0, base, linea)
	# marcas propias
	match tipo:
		"jirafa":
			for m in [Vector2(-0.45, -0.45), Vector2(0.5, -0.3), Vector2(-0.6, 0.15)]:
				lienzo.draw_circle(m * tam, tam * 0.14, detalle)
		"perro":
			_ovalo(lienzo, Vector2(tam * 0.38, -tam * 0.3), Vector2(tam * 0.3, tam * 0.26), 0.0, Color(detalle, 0.55), 0.0)
		"dino":
			for m in [Vector2(-0.55, -0.35), Vector2(0.6, -0.4)]:
				lienzo.draw_circle(m * tam, tam * 0.12, detalle)
	# hocico claro (perro, jirafa, conejo) para que se lea como animal
	if tipo in ["perro", "jirafa", "conejo"]:
		_ovalo(lienzo, Vector2(0, tam * 0.42), Vector2(tam * 0.5, tam * 0.34), 0.0, Color("fff3e6"), 0.0)
	# ojos brillantes, rubor, nariz y boquita
	for s in [-1.0, 1.0]:
		var ojo := Vector2(s * tam * 0.36, -tam * 0.05)
		lienzo.draw_circle(ojo, tam * 0.15, Color("2b1a1a"))
		lienzo.draw_circle(ojo + Vector2(tam * 0.05, -tam * 0.05), tam * 0.055, Color.WHITE)
		lienzo.draw_circle(Vector2(s * tam * 0.62, tam * 0.3), tam * 0.13, Color(1.0, 0.45, 0.6, 0.45))
	if tipo == "dino":
		lienzo.draw_circle(Vector2(-tam * 0.12, tam * 0.3), tam * 0.05, CONTORNO)
		lienzo.draw_circle(Vector2(tam * 0.12, tam * 0.3), tam * 0.05, CONTORNO)
	else:
		_ovalo(lienzo, Vector2(0, tam * 0.28), Vector2(tam * 0.13, tam * 0.09), 0.0, Color("5a2a2a") if tipo != "conejo" else Color("ff7fa8"), 0.0)
	lienzo.draw_arc(Vector2(-tam * 0.09, tam * 0.4), tam * 0.1, 0.2, PI - 0.2, 8, CONTORNO, 1.5, true)
	lienzo.draw_arc(Vector2(tam * 0.09, tam * 0.4), tam * 0.1, 0.2, PI - 0.2, 8, CONTORNO, 1.5, true)
	if tipo == "gato":
		for s in [-1.0, 1.0]:
			for k in 2:
				lienzo.draw_line(Vector2(s * tam * 0.45, tam * (0.3 + k * 0.12)), Vector2(s * tam * 0.95, tam * (0.22 + k * 0.2)), CONTORNO, 1.2, true)
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ovalo(lienzo: Node2D, c: Vector2, r: Vector2, giro: float, color: Color, linea: float) -> void:
	var puntos := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		puntos.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(giro))
	_poligono(lienzo, puntos, color, linea)


func _poligono(lienzo: Node2D, puntos: PackedVector2Array, color: Color, linea: float) -> void:
	lienzo.draw_colored_polygon(puntos, color)
	if linea > 0.0:
		lienzo.draw_polyline(puntos + PackedVector2Array([puntos[0]]), CONTORNO, linea, true)


func _punto_anillo(t: float) -> Vector2:
	return Vector2(cos(t) * radio * 1.55, sin(t) * radio * 0.36).rotated(-0.28)


func _anillo(lienzo: Node2D, detras: bool) -> void:
	var puntos := PackedVector2Array()
	var desde := PI if detras else 0.0
	for i in 33:
		puntos.append(_punto_anillo(desde + PI * i / 32.0))
	lienzo.draw_polyline(puntos, Color(CONTORNO, 0.8), radio * 0.16, true)
	lienzo.draw_polyline(puntos, Color("ff6bd6"), radio * 0.12, true)
	lienzo.draw_polyline(puntos, Color("ffd6f6"), radio * 0.03, true)


func _notas(adelante: bool) -> void:
	for k in 3:
		var t := _tiempo * 0.5 + k * TAU / 3.0
		if (sin(t) > 0.0) != adelante:
			continue
		var p := _punto_anillo(t) + Vector2(0, -radio * 0.22 + sin(_tiempo * 3.0 + k) * 3.0)
		_nota(_adelante if adelante else _atras, p, radio * 0.17, Color("fff27a") if k % 2 == 0 else Color("8ff0ff"))


func _nota(lienzo: Node2D, p: Vector2, tam: float, color: Color) -> void:
	var cabeza := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		cabeza.append(p + Vector2(cos(a) * tam, sin(a) * tam * 0.75).rotated(-0.35))
	lienzo.draw_colored_polygon(cabeza, color)
	lienzo.draw_polyline(cabeza + PackedVector2Array([cabeza[0]]), CONTORNO, 2.0, true)
	var tope := p + Vector2(tam * 0.9, -tam * 3.0)
	lienzo.draw_line(p + Vector2(tam * 0.9, 0), tope, CONTORNO, 3.0, true)
	lienzo.draw_line(tope, tope + Vector2(tam * 0.9, tam * 0.8), CONTORNO, 3.0, true)


func _luna(adelante: bool) -> void:
	var t := _tiempo * 0.35
	if (sin(t) > 0.0) != adelante:
		return
	var lienzo := _adelante if adelante else _atras
	var p := Vector2(cos(t) * radio * 1.5, sin(t) * radio * 0.45 - radio * 0.25)
	var r := radio * 0.24
	lienzo.draw_circle(p, r + 2.5, CONTORNO)
	lienzo.draw_circle(p, r, Color("f3ecd2"))
	lienzo.draw_circle(p + Vector2(r * 0.25, r * 0.2), r * 0.72, Color("e2d6b0"))
	lienzo.draw_circle(p + Vector2(-r * 0.3, -r * 0.25), r * 0.22, Color("cbbd92"))
	lienzo.draw_circle(p + Vector2(r * 0.35, r * 0.3), r * 0.15, Color("cbbd92"))


func _numeros(adelante: bool) -> void:
	_texto_orbitando(["1", "2", "3"], adelante, Color("ffd23f"), 0.4, false)


func _letras(adelante: bool) -> void:
	_texto_orbitando(["A", "B", "C"], adelante, Color("ffffff"), 0.35, true)


func _texto_orbitando(textos: Array, adelante: bool, color: Color, vel: float, en_bloque: bool) -> void:
	var lienzo := _adelante if adelante else _atras
	var tam := int(radio * 0.6)
	for k in textos.size():
		var t := _tiempo * vel + k * TAU / textos.size() + 0.6
		if (sin(t) > 0.0) != adelante:
			continue
		var p := Vector2(cos(t) * radio * 1.4, sin(t) * radio * 0.4 - radio * 0.1)
		var escala := 0.8 + 0.2 * sin(t)
		if en_bloque:
			var lado := radio * 0.62 * escala
			var caja := StyleBoxFlat.new()
			caja.bg_color = [Color("ff6b6b"), Color("4aa8ff"), Color("7dd87a")][k % 3]
			caja.set_corner_radius_all(int(lado * 0.25))
			caja.border_color = CONTORNO
			caja.set_border_width_all(2)
			lienzo.draw_style_box(caja, Rect2(p - Vector2(lado, lado) / 2.0, Vector2(lado, lado)))
		var fuente_tam := int(tam * escala * (0.85 if en_bloque else 1.0))
		var medida := _fuente.get_string_size(textos[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fuente_tam)
		var origen := p + Vector2(-medida.x / 2.0, fuente_tam * 0.36)
		if not en_bloque:
			lienzo.draw_string_outline(_fuente, origen, textos[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fuente_tam, 6, CONTORNO)
		lienzo.draw_string(_fuente, origen, textos[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fuente_tam, color)


func _corazones_flotando(adelante: bool) -> void:
	var lienzo := _adelante if adelante else _atras
	for k in 3:
		var t := _tiempo * 0.45 + k * TAU / 3.0
		if (sin(t) > 0.0) != adelante:
			continue
		var p := Vector2(cos(t) * radio * 1.35, sin(t) * radio * 0.35 - radio * 0.35 + sin(_tiempo * 2.0 + k) * 4.0)
		_corazon(lienzo, p, radio * 0.16, Color("ff5f9e") if k != 1 else Color("9fdcff"))


func _corazon(lienzo: Node2D, p: Vector2, tam: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		puntos.append(p + Vector2(x, y) * tam / 16.0)
	lienzo.draw_colored_polygon(puntos, color)
	lienzo.draw_polyline(puntos + PackedVector2Array([puntos[0]]), CONTORNO, 2.0, true)


func _nube(p: Vector2, tam: float) -> void:
	var bolitas := [Vector2(-1.0, 0.2), Vector2(0.0, -0.35), Vector2(1.0, 0.2), Vector2(0.0, 0.3)]
	for b in bolitas:
		_adelante.draw_circle(p + b * tam, tam * 0.85 + 2.5, Color(CONTORNO, 0.7))
	for b in bolitas:
		_adelante.draw_circle(p + b * tam, tam * 0.85, Color("ffffff"))
	_adelante.draw_circle(p + Vector2(-0.3, -0.5) * tam, tam * 0.35, Color("fff8ff"))

