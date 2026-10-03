extends RefCounted

## Dibujos por codigo de las cartas de "Parejas de Coco" con los gustos de cada hermano
## (docs/perfil-jugadores.md): dinos y autos para Maxi; jirafas, ponies, gatitos y ropa para
## Nicole; y banderas de paises (pedido del PO, 27-Sep-2026) para que aprendan paises.
##
## Mismo estilo "peluche pintado" que `scripts/ui/figura_vectorial.gd` (contorno azul noche,
## sombra, volumen y carita kawaii) mientras no existan los sprites finales de HE-13. Las
## banderas NO llevan carita: se dibujan con sus colores y proporciones oficiales y emblemas
## simplificados con respeto (sin texto ni escudos detallados).
##
## Uso: `Dibujos.dibujar(lienzo, "trex", color, centro, radio, cara, feliz)`; `Dibujos.tiene(nombre)`.
## Las coordenadas de cada dibujo van en unidades del radio (caben en un circulo de radio ~1).

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const BLANCO := Color("#FFFFFF")
const CELESTE_VIDRIO := Color("#CFF5F1")
const RUEDA := Color("#3A3F55")
const LLANTA := Color("#C9D0E0")

## Color por defecto de cada dibujo (el nivel puede traer otro en `color`).
const COLORES := {
	"trex": "#7DD87A", "spinosaurio": "#45C6C0", "carnotauro": "#FF6B6B", "huevo": "#FFF1C9",
	"auto": "#FF6B6B", "bus": "#4A8BE0", "bomberos": "#E8423F", "cohete": "#EEF2FA",
	"jirafa": "#FFCB3D", "pony": "#F7A8D0", "gatito": "#FF9F4A", "perrito": "#E0A86A", "gerbo": "#F2C98E",
	"vestido": "#F26CA8", "zapato": "#B48CE8", "corona": "#FFCB3D", "mono": "#F26CA8",
	"sol": "#FFCB3D", "hoja": "#7DD87A", "mancha": "#FF6B6B",
}

## Proporcion oficial ancho/alto de cada bandera.
const PAISES := {
	"chile": 1.5, "argentina": 14.0 / 9.0, "peru": 1.5, "brasil": 10.0 / 7.0, "colombia": 1.5,
	"japon": 1.5, "china": 1.5, "corea_sur": 1.5, "eeuu": 1.9, "alemania": 5.0 / 3.0,
	"francia": 1.5, "italia": 1.5, "espana": 1.5, "suecia": 1.6,
}


static func tiene(nombre: String) -> bool:
	return COLORES.has(nombre) or es_bandera(nombre)


static func es_bandera(nombre: String) -> bool:
	return nombre.begins_with("bandera_") and PAISES.has(nombre.trim_prefix("bandera_"))


static func color_por_defecto(nombre: String) -> Color:
	return Color(COLORES.get(nombre, "#FFCB3D"))


static func dibujar(l, nombre: String, color: Color, c: Vector2, r: float, cara := true, feliz := false) -> void:
	if es_bandera(nombre):
		bandera(l, nombre.trim_prefix("bandera_"), c, r)
		return
	var trazo := maxf(2.5, r * 0.075)
	match nombre:
		"trex", "spinosaurio", "carnotauro":
			_dino(l, nombre, color, c, r, trazo, cara, feliz)
		"huevo":
			_huevo(l, color, c, r, trazo, cara, feliz)
		"auto":
			_auto(l, color, c, r, trazo, cara, feliz)
		"bus":
			_bus(l, color, c, r, trazo, cara, feliz)
		"bomberos":
			_bomberos(l, color, c, r, trazo, cara, feliz)
		"cohete":
			_cohete(l, color, c, r, trazo, cara, feliz)
		"jirafa":
			_jirafa(l, color, c, r, trazo, cara, feliz)
		"pony":
			_pony(l, color, c, r, trazo, cara, feliz)
		"gatito":
			_gatito(l, color, c, r, trazo, cara, feliz)
		"perrito":
			_perrito(l, color, c, r, trazo, cara, feliz)
		"gerbo":
			_gerbo(l, color, c, r, trazo, cara, feliz)
		"vestido":
			_vestido(l, color, c, r, trazo)
		"zapato":
			_zapato(l, color, c, r, trazo)
		"corona":
			_corona(l, color, c, r, trazo)
		"mono":
			_mono(l, color, c, r, trazo)
		"sol":
			_sol(l, color, c, r, trazo, cara, feliz)
		"hoja":
			_hoja(l, color, c, r, trazo, cara, feliz)
		"mancha":
			_mancha(l, color, c, r, trazo)


# --- Maxi: dinosaurios y vehiculos -----------------------------------------------------------

static func _dino(l, tipo: String, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var cabeza := _el(c, r, Vector2(0.55, -0.52), 0.4, 0.28)
	if tipo == "spinosaurio":
		cabeza = _el(c, r, Vector2(0.6, -0.48), 0.46, 0.22)
		# Vela de la espalda, detras del cuerpo.
		var vela := _unir([_el(c, r, Vector2(-0.42, -0.1), 0.2, 0.2), _el(c, r, Vector2(-0.18, -0.24), 0.27, 0.27),
			_el(c, r, Vector2(0.08, -0.22), 0.25, 0.25), _el(c, r, Vector2(0.28, -0.1), 0.18, 0.18)])
		_pintar(l, vela, Color("#FF9F4A"), r, trazo)
		for x in [-0.36, -0.14, 0.08]:
			l.draw_line(c + Vector2(x, -0.05) * r, c + Vector2(x - 0.02, -0.34) * r, Color("#E0782A"), trazo * 0.7, true)
	var partes := [
		_el(c, r, Vector2(-0.12, 0.18), 0.5, 0.34),
		_poli(c, r, [Vector2(-0.5, 0.02), Vector2(-1.0, 0.32), Vector2(-0.45, 0.42)]),
		_poli(c, r, [Vector2(0.1, -0.05), Vector2(0.38, -0.5), Vector2(0.62, -0.34), Vector2(0.32, 0.22)]),
		cabeza,
		_caja(c, r, -0.38, 0.3, -0.12, 0.9, 0.08),
		_caja(c, r, 0.04, 0.3, 0.3, 0.9, 0.08),
		_el(c, r, Vector2(0.42, 0.12), 0.15, 0.07),
	]
	if tipo == "carnotauro":
		partes.append(_poli(c, r, [Vector2(0.3, -0.64), Vector2(0.26, -0.98), Vector2(0.46, -0.74)]))
		partes.append(_poli(c, r, [Vector2(0.62, -0.74), Vector2(0.74, -1.0), Vector2(0.82, -0.68)]))
	var silueta := _unir(partes)
	_pintar(l, silueta, color, r, trazo)
	_dentro(l, _el(c, r, Vector2(-0.02, 0.32), 0.34, 0.15), silueta, color.lightened(0.35))
	for punto in [Vector3(-0.38, 0.06, 0.07), Vector3(-0.16, -0.02, 0.08), Vector3(0.06, 0.04, 0.06)]:
		_dentro(l, _el(c, r, Vector2(punto.x, punto.y), punto.z, punto.z), silueta, color.darkened(0.2))
	l.draw_circle(c + Vector2(0.9, -0.58) * r, r * 0.035, COLOR_CONTORNO)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0.58, -0.5) * r, r * 0.42, feliz)


static func _huevo(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var huevo := _el(c, r, Vector2(0, 0.06), 0.64, 0.86, 40)
	_pintar(l, huevo, color, r, trazo)
	for punto in [Vector3(-0.3, -0.42, 0.12), Vector3(0.28, -0.3, 0.09), Vector3(-0.36, 0.5, 0.1), Vector3(0.34, 0.56, 0.13)]:
		_dentro(l, _el(c, r, Vector2(punto.x, punto.y), punto.z, punto.z), huevo, Color("#7DD87A"))
	var grieta := PackedVector2Array()
	for p in [Vector2(-0.62, -0.02), Vector2(-0.4, -0.16), Vector2(-0.2, 0.0), Vector2(0.0, -0.16), Vector2(0.2, 0.0), Vector2(0.4, -0.16), Vector2(0.62, -0.02)]:
		grieta.append(c + p * r)
	l.draw_polyline(grieta, COLOR_CONTORNO, trazo * 0.8, true)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0, 0.26) * r, r * 0.6, feliz)


static func _auto(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var cabina := _redondear(_poli(c, r, [Vector2(-0.55, -0.02), Vector2(-0.32, -0.52), Vector2(0.3, -0.52), Vector2(0.6, -0.02)]), r * 0.1)
	var silueta := _unir([_caja(c, r, -0.95, -0.08, 0.95, 0.42, 0.16), cabina])
	_pintar(l, silueta, color, r, trazo)
	_detalle(l, _poli(c, r, [Vector2(-0.44, -0.08), Vector2(-0.27, -0.42), Vector2(-0.04, -0.42), Vector2(-0.04, -0.08)]), CELESTE_VIDRIO, trazo * 0.8)
	_detalle(l, _poli(c, r, [Vector2(0.04, -0.08), Vector2(0.04, -0.42), Vector2(0.25, -0.42), Vector2(0.46, -0.08)]), CELESTE_VIDRIO, trazo * 0.8)
	_detalle(l, _el(c, r, Vector2(0.86, 0.08), 0.07, 0.07), Color("#FFE38A"), trazo * 0.6)
	_ruedas(l, c, r, trazo, [Vector2(-0.52, 0.44), Vector2(0.52, 0.44)], 0.24)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0.18, 0.16) * r, r * 0.42, feliz)


static func _bus(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var silueta := _caja(c, r, -0.95, -0.62, 0.95, 0.42, 0.16)
	_pintar(l, silueta, color, r, trazo)
	for x in [-0.82, -0.46, -0.1]:
		_detalle(l, _caja(c, r, x, -0.5, x + 0.28, -0.2, 0.05), CELESTE_VIDRIO, trazo * 0.8)
	_detalle(l, _caja(c, r, 0.36, -0.5, 0.84, -0.06, 0.06), CELESTE_VIDRIO, trazo * 0.8)
	_dentro(l, _caja(c, r, -1.0, 0.24, 1.0, 0.3), silueta, Color("#FFE38A"))
	_detalle(l, _el(c, r, Vector2(0.86, 0.14), 0.06, 0.06), Color("#FFE38A"), trazo * 0.6)
	_ruedas(l, c, r, trazo, [Vector2(-0.55, 0.44), Vector2(0.55, 0.44)], 0.22)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(-0.28, 0.03) * r, r * 0.4, feliz)


static func _bomberos(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	# Escalera sobre la carroceria (detras).
	_detalle(l, _caja(c, r, -0.9, -0.44, 0.22, -0.3, 0.03), LLANTA, trazo * 0.7)
	for x in [-0.72, -0.5, -0.28, -0.06, 0.14]:
		l.draw_line(c + Vector2(x, -0.44) * r, c + Vector2(x, -0.3) * r, COLOR_CONTORNO, trazo * 0.6, true)
	for x in [-0.7, 0.1]:
		_detalle(l, _caja(c, r, x, -0.32, x + 0.08, -0.18), LLANTA, trazo * 0.6)
	var silueta := _unir([_caja(c, r, -0.95, -0.2, 0.95, 0.42, 0.12), _caja(c, r, 0.3, -0.62, 0.95, 0.0, 0.12)])
	_pintar(l, silueta, color, r, trazo)
	_detalle(l, _caja(c, r, 0.45, -0.52, 0.85, -0.22, 0.05), CELESTE_VIDRIO, trazo * 0.8)
	_dentro(l, _caja(c, r, -1.0, 0.27, 1.0, 0.34), silueta, BLANCO)
	_detalle(l, _el(c, r, Vector2(0.62, -0.68), 0.12, 0.08), Color("#4A8BE0"), trazo * 0.7)
	_ruedas(l, c, r, trazo, [Vector2(-0.55, 0.44), Vector2(0.55, 0.44)], 0.22)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(-0.28, 0.04) * r, r * 0.4, feliz)


static func _cohete(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var rojo := Color("#FF6B6B")
	_detalle(l, _poli(c, r, [Vector2(-0.12, 0.66), Vector2(0.12, 0.66), Vector2(0.0, 0.98)]), Color("#FF9F4A"), trazo * 0.7)
	for lado in [-1.0, 1.0]:
		_pintar(l, _redondear(_poli(c, r, [Vector2(0.22 * lado, 0.12), Vector2(0.62 * lado, 0.7), Vector2(0.2 * lado, 0.58)]), r * 0.06), rojo, r, trazo)
	var cuerpo := _el(c, r, Vector2(0, -0.04), 0.36, 0.8, 40)
	_pintar(l, cuerpo, color, r, trazo)
	_dentro(l, _caja(c, r, -1.0, -1.0, 1.0, -0.5), cuerpo, rojo)
	_detalle(l, _el(c, r, Vector2(0, -0.08), 0.21, 0.21), CELESTE_VIDRIO, trazo)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0, -0.06) * r, r * 0.34, feliz)


# --- Nicole: animales y ropa ----------------------------------------------------------------

static func _jirafa(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var partes := [
		_el(c, r, Vector2(-0.25, 0.16), 0.46, 0.25),
		_poli(c, r, [Vector2(0.0, 0.1), Vector2(0.32, -0.64), Vector2(0.56, -0.56), Vector2(0.3, 0.18)]),
		_el(c, r, Vector2(0.56, -0.66), 0.3, 0.19),
		_el(c, r, Vector2(0.8, -0.6), 0.15, 0.13),
		_el(c, r, Vector2(0.3, -0.8), 0.11, 0.06),
		_caja(c, r, 0.42, -0.98, 0.48, -0.78),
		_caja(c, r, 0.56, -0.98, 0.62, -0.78),
		_poli(c, r, [Vector2(-0.68, 0.08), Vector2(-0.9, 0.44), Vector2(-0.82, 0.47), Vector2(-0.64, 0.18)]),
	]
	for x in [-0.64, -0.44, -0.1, 0.08]:
		partes.append(_caja(c, r, x, 0.28, x + 0.15, 0.95, 0.05))
	var silueta := _unir(partes)
	_pintar(l, silueta, color, r, trazo)
	var cafe := Color("#C8793A")
	for punto in [Vector3(-0.46, 0.1, 0.09), Vector3(-0.22, 0.26, 0.08), Vector3(-0.04, 0.06, 0.07), Vector3(-0.3, -0.02, 0.06),
			Vector3(0.18, -0.18, 0.07), Vector3(0.32, -0.44, 0.06), Vector3(-0.58, 0.3, 0.06)]:
		_dentro(l, _el(c, r, Vector2(punto.x, punto.y), punto.z, punto.z), silueta, cafe)
	for x in [0.45, 0.59]:
		_detalle(l, _el(c, r, Vector2(x, -0.98), 0.06, 0.06), cafe, trazo * 0.6)
	l.draw_circle(c + Vector2(0.9, -0.62) * r, r * 0.03, COLOR_CONTORNO)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0.58, -0.66) * r, r * 0.36, feliz)


## Siluetas de una sola pieza para el estilo "sombra" de las cartas (pony especial del reto dorado de
## Sofia, disenador-niveles HE-40 §7.5). Vacio si el dibujo no tiene silueta.
static func silueta(nombre: String, c: Vector2, r: float) -> Array[PackedVector2Array]:
	var salida: Array[PackedVector2Array] = []
	if nombre == "pony":
		salida.append(_pony_cola(c, r))
		salida.append(_unir(_pony_partes(c, r)))
		salida.append(_pony_melena(c, r))
	return salida


static func _pony_cola(c: Vector2, r: float) -> PackedVector2Array:
	return _unir([_el(c, r, Vector2(-0.66, 0.06), 0.14, 0.14), _el(c, r, Vector2(-0.8, 0.26), 0.15, 0.15), _el(c, r, Vector2(-0.78, 0.48), 0.12, 0.12)])


static func _pony_melena(c: Vector2, r: float) -> PackedVector2Array:
	return _unir([_el(c, r, Vector2(0.36, -0.7), 0.14, 0.14), _el(c, r, Vector2(0.24, -0.5), 0.15, 0.15),
		_el(c, r, Vector2(0.16, -0.28), 0.14, 0.14), _el(c, r, Vector2(0.1, -0.06), 0.12, 0.12)])


static func _pony_partes(c: Vector2, r: float) -> Array:
	var partes := [
		_el(c, r, Vector2(-0.15, 0.2), 0.5, 0.28),
		_poli(c, r, [Vector2(0.1, 0.05), Vector2(0.3, -0.45), Vector2(0.58, -0.4), Vector2(0.4, 0.15)]),
		_el(c, r, Vector2(0.52, -0.5), 0.3, 0.24),
		_el(c, r, Vector2(0.76, -0.38), 0.2, 0.16),
		_poli(c, r, [Vector2(0.36, -0.66), Vector2(0.42, -0.95), Vector2(0.54, -0.7)]),
	]
	for x in [-0.58, -0.38, 0.02, 0.2]:
		partes.append(_caja(c, r, x, 0.3, x + 0.16, 0.92, 0.05))
	return partes


static func _pony(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var melena_color := Color("#B48CE8") if color.h < 0.7 or color.h > 0.95 else Color("#F26CA8")
	_pintar(l, _pony_cola(c, r), melena_color, r, trazo)
	var partes := [
		_el(c, r, Vector2(-0.15, 0.2), 0.5, 0.28),
		_poli(c, r, [Vector2(0.1, 0.05), Vector2(0.3, -0.45), Vector2(0.58, -0.4), Vector2(0.4, 0.15)]),
		_el(c, r, Vector2(0.52, -0.5), 0.3, 0.24),
		_el(c, r, Vector2(0.76, -0.38), 0.2, 0.16),
		_poli(c, r, [Vector2(0.36, -0.66), Vector2(0.42, -0.95), Vector2(0.54, -0.7)]),
	]
	for x in [-0.58, -0.38, 0.02, 0.2]:
		partes.append(_caja(c, r, x, 0.3, x + 0.16, 0.92, 0.05))
	var silueta := _unir(partes)
	_pintar(l, silueta, color, r, trazo)
	for x in [-0.58, -0.38, 0.02, 0.2]:
		_dentro(l, _caja(c, r, x - 0.02, 0.8, x + 0.18, 1.0), silueta, color.darkened(0.3))
	var melena := _unir([_el(c, r, Vector2(0.36, -0.7), 0.14, 0.14), _el(c, r, Vector2(0.24, -0.5), 0.15, 0.15),
		_el(c, r, Vector2(0.16, -0.28), 0.14, 0.14), _el(c, r, Vector2(0.1, -0.06), 0.12, 0.12)])
	_pintar(l, melena, melena_color, r, trazo)
	var corazon := Figura.poligono("corazon", c + Vector2(-0.26, 0.18) * r, r * 0.12)
	l.draw_colored_polygon(corazon, Color("#FFF8EE"))
	Figura.contornear(l, corazon, trazo * 0.5)
	l.draw_circle(c + Vector2(0.88, -0.36) * r, r * 0.03, COLOR_CONTORNO)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0.55, -0.48) * r, r * 0.36, feliz)


static func _gatito(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var cola := PackedVector2Array()
	for i in 12:
		var t := i / 11.0
		cola.append(c + Vector2(0.3 + 0.5 * t, 0.72 - 0.2 * t - 0.5 * t * t) * r)
	l.draw_polyline(cola, COLOR_CONTORNO, maxf(2.0, r * 0.2), true)
	l.draw_polyline(cola, color, maxf(1.0, r * 0.2 - trazo * 2.0), true)
	var silueta := _unir([
		_el(c, r, Vector2(0, -0.18), 0.58, 0.5),
		_poli(c, r, [Vector2(-0.52, -0.36), Vector2(-0.46, -0.98), Vector2(-0.1, -0.62)]),
		_poli(c, r, [Vector2(0.52, -0.36), Vector2(0.1, -0.62), Vector2(0.46, -0.98)]),
		_el(c, r, Vector2(0, 0.52), 0.4, 0.36),
	])
	_pintar(l, silueta, color, r, trazo)
	var rosa := Color("#F7A8D0")
	l.draw_colored_polygon(_poli(c, r, [Vector2(-0.44, -0.46), Vector2(-0.42, -0.82), Vector2(-0.2, -0.62)]), rosa)
	l.draw_colored_polygon(_poli(c, r, [Vector2(0.44, -0.46), Vector2(0.2, -0.62), Vector2(0.42, -0.82)]), rosa)
	for x in [-0.12, 0.0, 0.12]:
		l.draw_line(c + Vector2(x, -0.66) * r, c + Vector2(x, -0.5) * r, color.darkened(0.25), trazo, true)
	for lado in [-1.0, 1.0]:
		_detalle(l, _el(c, r, Vector2(0.18 * lado, 0.84), 0.13, 0.08), Color("#FFF8EE"), trazo * 0.6)
		for dy in [-0.06, 0.08]:
			l.draw_line(c + Vector2(0.32 * lado, -0.02) * r, c + Vector2(0.74 * lado, -0.02 + dy) * r, COLOR_CONTORNO, trazo * 0.5, true)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0, -0.14) * r, r * 0.72, feliz)
	l.draw_colored_polygon(_poli(c, r, [Vector2(-0.06, -0.08), Vector2(0.06, -0.08), Vector2(0.0, -0.01)]), rosa.darkened(0.15))


# --- Sofia: sus mascotas favoritas (HE-40 niveles §7.5, guinos en Parejas z1) ---------------------

static func _perrito(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	# Colita parada que asoma detras del cuerpo.
	_pintar(l, _redondear(_poli(c, r, [Vector2(0.42, 0.34), Vector2(0.86, -0.06), Vector2(0.94, 0.04), Vector2(0.52, 0.5)]), r * 0.06), color, r, trazo)
	var silueta := _unir([
		_el(c, r, Vector2(0, -0.2), 0.54, 0.46),
		_el(c, r, Vector2(0, 0.5), 0.46, 0.38),
	])
	_pintar(l, silueta, color, r, trazo)
	_dentro(l, _el(c, r, Vector2(0.0, 0.0), 0.3, 0.2), silueta, Color("#FFF8EE"))
	# Orejas caidas, mas oscuras, por delante de la cabeza.
	var oreja := color.darkened(0.3)
	for lado in [-1.0, 1.0]:
		_pintar(l, _el(c, r, Vector2(0.5 * lado, -0.18), 0.17, 0.32, 24), oreja, r, trazo)
		_detalle(l, _el(c, r, Vector2(0.22 * lado, 0.86), 0.15, 0.09), Color("#FFF8EE"), trazo * 0.6)
	_detalle(l, _el(c, r, Vector2(0, 0.42), 0.36, 0.08), Color("#FF6B6B"), trazo * 0.6)
	_detalle(l, _el(c, r, Vector2(0, 0.54), 0.08, 0.08), Color("#FFCB3D"), trazo * 0.5)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0, -0.18) * r, r * 0.66, feliz)
	l.draw_colored_polygon(_el(c, r, Vector2(0.0, -0.04), 0.08, 0.055), COLOR_CONTORNO)


static func _gerbo(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	# Cola larga y finita con su pompon en la punta.
	var cola := PackedVector2Array()
	for i in 12:
		var t := i / 11.0
		cola.append(c + Vector2(-0.5 - 0.42 * t, 0.5 - 0.9 * t + 0.5 * t * t) * r)
	l.draw_polyline(cola, COLOR_CONTORNO, maxf(2.0, r * 0.1), true)
	l.draw_polyline(cola, color.darkened(0.15), maxf(1.0, r * 0.1 - trazo * 1.4), true)
	_pintar(l, _el(c, r, Vector2(-0.9, 0.1), 0.1, 0.13), color.darkened(0.3), r, trazo * 0.8)
	var silueta := _unir([
		_el(c, r, Vector2(-0.08, 0.3), 0.56, 0.44),
		_el(c, r, Vector2(0.34, -0.22), 0.42, 0.38),
		_el(c, r, Vector2(0.12, -0.62), 0.16, 0.18),
		_el(c, r, Vector2(0.58, -0.6), 0.16, 0.18),
	])
	_pintar(l, silueta, color, r, trazo)
	var rosa := Color("#F7A8D0")
	for x in [0.12, 0.58]:
		_dentro(l, _el(c, r, Vector2(x, -0.62), 0.09, 0.11), silueta, rosa)
	_dentro(l, _el(c, r, Vector2(0.0, 0.46), 0.34, 0.24), silueta, Color("#FFF8EE"))
	for x in [-0.36, 0.2]:
		_detalle(l, _el(c, r, Vector2(x, 0.74), 0.12, 0.07), rosa, trazo * 0.5)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0.36, -0.2) * r, r * 0.5, feliz)
	for dy in [-0.05, 0.06]:
		l.draw_line(c + Vector2(0.62, -0.1) * r, c + Vector2(0.92, -0.12 + dy) * r, COLOR_CONTORNO, trazo * 0.5, true)


static func _vestido(l, color: Color, c: Vector2, r: float, trazo: float) -> void:
	var silueta := _unir([
		_poli(c, r, [Vector2(-0.28, -0.62), Vector2(0.28, -0.62), Vector2(0.22, -0.06), Vector2(-0.22, -0.06)]),
		_redondear(_poli(c, r, [Vector2(-0.24, -0.12), Vector2(0.24, -0.12), Vector2(0.8, 0.84), Vector2(-0.8, 0.84)]), r * 0.08),
		_caja(c, r, -0.27, -0.9, -0.17, -0.58),
		_caja(c, r, 0.17, -0.9, 0.27, -0.58),
	])
	_pintar(l, silueta, color, r, trazo)
	for punto in [Vector2(-0.38, 0.5), Vector2(0.0, 0.24), Vector2(0.38, 0.5), Vector2(0.0, 0.64), Vector2(-0.2, 0.36), Vector2(0.2, 0.36)]:
		_dentro(l, _el(c, r, punto, 0.06, 0.06), silueta, Color(1, 1, 1, 0.85))
	_lazo(l, c + Vector2(0, -0.1) * r, r * 0.34, Color("#FFCB3D"), trazo * 0.7)


static func _zapato(l, color: Color, c: Vector2, r: float, trazo: float) -> void:
	_detalle(l, _caja(c, r, -0.9, 0.26, 0.92, 0.46, 0.08), color.darkened(0.35), trazo)
	var cuerpo := _redondear(_poli(c, r, [Vector2(-0.88, -0.02), Vector2(-0.72, -0.26), Vector2(-0.2, -0.22), Vector2(0.35, -0.08),
		Vector2(0.82, 0.1), Vector2(0.9, 0.36), Vector2(-0.88, 0.36)]), r * 0.1)
	_pintar(l, cuerpo, color, r, trazo)
	_detalle(l, _el(c, r, Vector2(-0.4, -0.16), 0.3, 0.09), color.darkened(0.45), trazo * 0.7)
	_detalle(l, _poli(c, r, [Vector2(-0.14, -0.22), Vector2(0.0, -0.18), Vector2(0.14, 0.28), Vector2(0.0, 0.28)]), color.darkened(0.2), trazo * 0.6)
	_detalle(l, _el(c, r, Vector2(0.06, 0.12), 0.05, 0.05), Color("#FFF8EE"), trazo * 0.5)
	_lazo(l, c + Vector2(0.56, 0.04) * r, r * 0.28, Color("#F26CA8"), trazo * 0.6)


static func _corona(l, color: Color, c: Vector2, r: float, trazo: float) -> void:
	var corona := _redondear(_poli(c, r, [Vector2(-0.82, 0.5), Vector2(-0.88, -0.42), Vector2(-0.44, -0.02), Vector2(0.0, -0.66),
		Vector2(0.44, -0.02), Vector2(0.88, -0.42), Vector2(0.82, 0.5)]), r * 0.06)
	_pintar(l, corona, color, r, trazo)
	_dentro(l, _caja(c, r, -1.0, 0.2, 1.0, 0.24), corona, color.darkened(0.25))
	_detalle(l, _el(c, r, Vector2(0, 0.36), 0.1, 0.1), Color("#F26CA8"), trazo * 0.6)
	for x in [-0.5, 0.5]:
		_detalle(l, _el(c, r, Vector2(x, 0.36), 0.08, 0.08), Color("#45C6C0"), trazo * 0.6)
	for punta in [Vector3(-0.88, -0.48, 0.09), Vector3(0.0, -0.72, 0.1), Vector3(0.88, -0.48, 0.09)]:
		_detalle(l, _el(c, r, Vector2(punta.x, punta.y), punta.z, punta.z), Color("#FFF8EE"), trazo * 0.6)


static func _mono(l, color: Color, c: Vector2, r: float, trazo: float) -> void:
	_lazo(l, c, r, color, trazo)


## Lazo (moño) de dos alas con nudo y cintitas. `r` es el medio ancho.
static func _lazo(l, c: Vector2, r: float, color: Color, trazo: float) -> void:
	var silueta := _unir([
		_el(c, r, Vector2.ZERO, 0.2, 0.24),
		_redondear(_poli(c, r, [Vector2(0.14, 0.0), Vector2(-0.88, -0.52), Vector2(-0.88, 0.52)]), r * 0.14),
		_redondear(_poli(c, r, [Vector2(-0.14, 0.0), Vector2(0.88, 0.52), Vector2(0.88, -0.52)]), r * 0.14),
		_poli(c, r, [Vector2(-0.12, 0.1), Vector2(-0.42, 0.82), Vector2(-0.16, 0.74), Vector2(0.0, 0.16)]),
		_poli(c, r, [Vector2(0.12, 0.1), Vector2(0.0, 0.16), Vector2(0.16, 0.74), Vector2(0.42, 0.82)]),
	])
	_pintar(l, silueta, color, r, trazo)
	for lado in [-1.0, 1.0]:
		l.draw_line(c + Vector2(0.2 * lado, -0.04) * r, c + Vector2(0.6 * lado, -0.24) * r, color.darkened(0.25), trazo * 0.8, true)
	_detalle(l, _el(c, r, Vector2.ZERO, 0.2, 0.24), color.darkened(0.12), trazo)


static func _sol(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var partes := [_el(c, r, Vector2.ZERO, 0.6, 0.6, 40)]
	for i in 12:
		var a := TAU * i / 12.0
		partes.append(_poli(c, r, [Vector2.from_angle(a - 0.17) * 0.52, Vector2.from_angle(a) * 0.98, Vector2.from_angle(a + 0.17) * 0.52]))
	_pintar(l, _unir(partes), Color("#FF9F4A"), r, trazo)
	var disco := _el(c, r, Vector2.ZERO, 0.6, 0.6, 40)
	_pintar(l, disco, color, r, trazo)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0, 0.04) * r, r * 0.8, feliz)


static func _hoja(l, color: Color, c: Vector2, r: float, trazo: float, cara: bool, feliz: bool) -> void:
	var eje := Vector2(-0.75, 0.65).normalized()
	var normal := Vector2(-eje.y, eje.x)
	var hoja := _mayor(Geometry2D.intersect_polygons(_el(c, r, normal * 0.85, 1.2, 1.2, 64), _el(c, r, -normal * 0.85, 1.2, 1.2, 64)))
	l.draw_line(c + eje * 0.8 * r, c + eje * 1.02 * r, COLOR_CONTORNO, trazo * 2.2, true)
	l.draw_line(c + eje * 0.8 * r, c + eje * 1.02 * r, color.darkened(0.2), trazo * 1.0, true)
	_pintar(l, hoja, color, r, trazo)
	l.draw_line(c + eje * 0.78 * r, c - eje * 0.7 * r, color.darkened(0.25), trazo * 0.7, true)
	if cara:
		Figura.dibujar_cara(l, c + Vector2(0.06, 0.04) * r, r * 0.5, feliz)


## Mancha de pintura: gotas pegadas a un charco central (sin carita: es pintura).
static func _mancha(l, color: Color, c: Vector2, r: float, trazo: float) -> void:
	var partes := [_el(c, r, Vector2.ZERO, 0.56, 0.52, 40)]
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		partes.append(_el(c, r, Vector2.from_angle(a) * 0.6, 0.2 if i % 2 == 0 else 0.15, 0.2 if i % 2 == 0 else 0.15))
	_pintar(l, _unir(partes), color, r, trazo)
	for i in 3:
		var a := TAU * i / 3.0 + 0.9
		_pintar(l, _el(c, r, Vector2.from_angle(a) * 0.9, 0.08, 0.08), color, r * 0.4, trazo * 0.7)
	l.draw_colored_polygon(_el(c, r, Vector2(-0.2, -0.2), 0.16, 0.09), Color(1, 1, 1, 0.55))


# --- Banderas -------------------------------------------------------------------------------

## Bandera plana con sus colores y proporcion oficiales, del ancho de la carta. Sin carita.
static func bandera(l, pais: String, c: Vector2, r: float) -> void:
	var proporcion: float = PAISES.get(pais, 1.5)
	var ancho := r * 2.0
	var alto := ancho / proporcion
	if alto > r * 1.5:
		alto = r * 1.5
		ancho = alto * proporcion
	var rect := Rect2(c - Vector2(ancho, alto) / 2.0, Vector2(ancho, alto))
	var trazo := maxf(2.0, r * 0.05)
	l.draw_rect(Rect2(rect.position + Vector2(0, r * 0.07), rect.size), Color(COLOR_CONTORNO, 0.22))
	match pais:
		"chile":
			_franjas_h(l, rect, [Color.WHITE, Color("#D52B1E")])
			var lado := alto / 2.0
			l.draw_rect(Rect2(rect.position, Vector2(lado, lado)), Color("#0039A6"))
			l.draw_colored_polygon(_estrella(rect.position + Vector2(lado, lado) / 2.0, lado / 4.0, -PI / 2.0), Color.WHITE)
		"argentina":
			_franjas_h(l, rect, [Color("#74ACDF"), Color.WHITE, Color("#74ACDF")])
			_sol_de_mayo(l, rect.get_center(), alto)
		"peru":
			_franjas_v(l, rect, [Color("#D91023"), Color.WHITE, Color("#D91023")])
		"brasil":
			_brasil(l, rect)
		"colombia":
			l.draw_rect(rect, Color("#CE1126"))
			l.draw_rect(Rect2(rect.position, Vector2(ancho, alto * 0.75)), Color("#003893"))
			l.draw_rect(Rect2(rect.position, Vector2(ancho, alto * 0.5)), Color("#FCD116"))
		"japon":
			l.draw_rect(rect, Color.WHITE)
			l.draw_circle(rect.get_center(), alto * 0.3, Color("#BC002D"))
		"china":
			_china(l, rect)
		"corea_sur":
			_corea_sur(l, rect)
		"eeuu":
			_eeuu(l, rect)
		"alemania":
			_franjas_h(l, rect, [Color("#000000"), Color("#DD0000"), Color("#FFCE00")])
		"francia":
			_franjas_v(l, rect, [Color("#0055A4"), Color.WHITE, Color("#EF4135")])
		"italia":
			_franjas_v(l, rect, [Color("#009246"), Color.WHITE, Color("#CE2B37")])
		"espana":
			l.draw_rect(rect, Color("#AA151B"))
			l.draw_rect(Rect2(rect.position + Vector2(0, alto * 0.25), Vector2(ancho, alto * 0.5)), Color("#F1BF00"))
		"suecia":
			l.draw_rect(rect, Color("#006AA7"))
			l.draw_rect(Rect2(rect.position + Vector2(ancho * 5.0 / 16.0, 0), Vector2(ancho * 2.0 / 16.0, alto)), Color("#FECC02"))
			l.draw_rect(Rect2(rect.position + Vector2(0, alto * 0.4), Vector2(ancho, alto * 0.2)), Color("#FECC02"))
	l.draw_rect(rect, COLOR_CONTORNO, false, trazo)


static func _franjas_h(l, rect: Rect2, colores: Array) -> void:
	var alto := rect.size.y / colores.size()
	for i in colores.size():
		l.draw_rect(Rect2(rect.position + Vector2(0, alto * i), Vector2(rect.size.x, alto + 0.5)), colores[i])


static func _franjas_v(l, rect: Rect2, colores: Array) -> void:
	var ancho := rect.size.x / colores.size()
	for i in colores.size():
		l.draw_rect(Rect2(rect.position + Vector2(ancho * i, 0), Vector2(ancho + 0.5, rect.size.y)), colores[i])


## Sol de Mayo simplificado: disco dorado con rayos rectos y ondulados alternados y su carita.
static func _sol_de_mayo(l, centro: Vector2, alto: float) -> void:
	var oro := Color("#F6B40E")
	var borde := Color("#85340A")
	var radio := alto * 0.075
	for i in 16:
		var a := TAU * i / 16.0 - PI / 2.0
		var largo := radio * (2.0 if i % 2 == 0 else 1.7)
		var rayo := PackedVector2Array([centro + Vector2.from_angle(a - 0.16) * radio * 0.9,
			centro + Vector2.from_angle(a) * largo, centro + Vector2.from_angle(a + 0.16) * radio * 0.9])
		l.draw_colored_polygon(rayo, oro)
	l.draw_circle(centro, radio, oro)
	l.draw_arc(centro, radio, 0.0, TAU, 24, borde, maxf(1.0, radio * 0.12), true)
	if radio >= 5.0:
		for lado in [-1.0, 1.0]:
			l.draw_circle(centro + Vector2(lado * radio * 0.35, -radio * 0.15), radio * 0.1, borde)
		l.draw_arc(centro + Vector2(0, radio * 0.15), radio * 0.3, PI * 0.2, PI * 0.8, 8, borde, maxf(1.0, radio * 0.1), true)


## Brasil (ley 8.421): 20x14 modulos, rombo a 1,7 del borde, esfera de radio 3,5 y banda blanca
## de arcos con centro 2 modulos a la izquierda del pie del diametro vertical (radios 8 y 8,5).
## Simplificado: sin lema ni estrellas exactas (un punado de estrellitas blancas).
static func _brasil(l, rect: Rect2) -> void:
	var m := rect.size.x / 20.0
	var o := rect.position
	l.draw_rect(rect, Color("#009C3B"))
	l.draw_colored_polygon(PackedVector2Array([o + Vector2(1.7, 7) * m, o + Vector2(10, 1.7) * m, o + Vector2(18.3, 7) * m, o + Vector2(10, 12.3) * m]), Color("#FFDF00"))
	var centro := o + Vector2(10, 7) * m
	var esfera := _circulo(centro, 3.5 * m, 48)
	l.draw_colored_polygon(esfera, Color("#002776"))
	var centro_arco := o + Vector2(8, 14) * m
	for dentro_del_arco in Geometry2D.intersect_polygons(esfera, _circulo(centro_arco, 8.5 * m, 160)):
		for trozo in Geometry2D.clip_polygons(dentro_del_arco, _circulo(centro_arco, 8.0 * m, 160)):
			_rellenar(l, trozo, Color.WHITE)
	for p in [Vector2(9, 8.6), Vector2(11, 9.2), Vector2(10, 10), Vector2(8.2, 9.6), Vector2(11.8, 8.3), Vector2(12.3, 6.2)]:
		l.draw_circle(o + p * m, maxf(0.8, m * 0.22), Color.WHITE)


## China: 30x20; estrella grande en (5,5) radio 3; cuatro chicas de radio 1 apuntando a la grande.
static func _china(l, rect: Rect2) -> void:
	var m := rect.size.x / 30.0
	var o := rect.position
	l.draw_rect(rect, Color("#EE1C25"))
	var amarillo := Color("#FFFF00")
	var grande := o + Vector2(5, 5) * m
	l.draw_colored_polygon(_estrella(grande, 3.0 * m, -PI / 2.0), amarillo)
	for p in [Vector2(10, 2), Vector2(12, 4), Vector2(12, 7), Vector2(10, 9)]:
		var centro: Vector2 = o + p * m
		l.draw_colored_polygon(_estrella(centro, 1.0 * m, (grande - centro).angle()), amarillo)


## Corea del Sur: taegeuk de diametro alto/2 (rojo arriba, azul abajo, alineado con la diagonal
## geon-gon) y los cuatro trigramas a medio radio del circulo, de largo igual al radio.
static func _corea_sur(l, rect: Rect2) -> void:
	var alto := rect.size.y
	var centro := rect.get_center()
	var radio := alto / 4.0
	l.draw_rect(rect, Color.WHITE)
	var rojo := Color("#CD2E3A")
	var azul := Color("#0047A0")
	var diagonal := Vector2(rect.size.x, rect.size.y).normalized()  # de arriba-izquierda a abajo-derecha
	var angulo := diagonal.angle()
	l.draw_circle(centro, radio, azul)
	var mitad := PackedVector2Array()
	for i in 33:
		mitad.append(centro + Vector2.from_angle(angulo + PI + PI * i / 32.0) * radio)
	l.draw_colored_polygon(mitad, rojo)
	l.draw_circle(centro - diagonal * radio / 2.0, radio / 2.0, rojo)
	l.draw_circle(centro + diagonal * radio / 2.0, radio / 2.0, azul)
	# Trigramas: geon (3 enteras) arriba-izq, gam arriba-der, ri abajo-izq, gon (3 partidas) abajo-der.
	var grosor := alto / 24.0
	var distancia := radio * 1.5 + alto / 12.0
	var trigramas := [
		[Vector2(-diagonal.x, -diagonal.y), [false, false, false]],
		[Vector2(diagonal.x, -diagonal.y), [true, false, true]],
		[Vector2(-diagonal.x, diagonal.y), [false, true, false]],
		[Vector2(diagonal.x, diagonal.y), [true, true, true]],
	]
	for trigrama in trigramas:
		var direccion: Vector2 = trigrama[0]
		var partidas: Array = trigrama[1]
		var a_lo_largo := Vector2(-direccion.y, direccion.x)
		for k in 3:
			var medio := centro + direccion * (distancia + (k - 1) * (grosor + alto / 48.0))
			if partidas[k]:
				var hueco := alto / 48.0
				var tramo := (radio - hueco) / 2.0
				for lado in [-1.0, 1.0]:
					_barra(l, medio + a_lo_largo * lado * (hueco + tramo) / 2.0, a_lo_largo, tramo, grosor)
			else:
				_barra(l, medio, a_lo_largo, radio, grosor)


static func _barra(l, medio: Vector2, a_lo_largo: Vector2, largo: float, grosor: float) -> void:
	var ancho := Vector2(-a_lo_largo.y, a_lo_largo.x) * grosor / 2.0
	var mitad := a_lo_largo * largo / 2.0
	l.draw_colored_polygon(PackedVector2Array([medio - mitad - ancho, medio + mitad - ancho, medio + mitad + ancho, medio - mitad + ancho]), Color.BLACK)


## EE.UU.: 13 franjas, canton de 7/13 del alto y 2/5 del ancho con 50 estrellas en 9 filas (6 y 5).
static func _eeuu(l, rect: Rect2) -> void:
	var rojo := Color("#B22234")
	var alto_franja := rect.size.y / 13.0
	l.draw_rect(rect, Color.WHITE)
	for i in range(0, 13, 2):
		l.draw_rect(Rect2(rect.position + Vector2(0, alto_franja * i), Vector2(rect.size.x, alto_franja)), rojo)
	var canton := Rect2(rect.position, Vector2(rect.size.x * 0.4, alto_franja * 7.0))
	l.draw_rect(canton, Color("#3C3B6E"))
	var radio := rect.size.y * 0.0308
	for fila in 9:
		var cantidad := 6 if fila % 2 == 0 else 5
		for j in cantidad:
			var x := canton.size.x * ((2 * j + 1) if fila % 2 == 0 else (2 * j + 2)) / 12.0
			var punto := canton.position + Vector2(x, canton.size.y * (fila + 1) / 10.0)
			if radio >= 1.6:
				l.draw_colored_polygon(_estrella(punto, radio, -PI / 2.0), Color.WHITE)
			else:
				l.draw_circle(punto, maxf(0.7, radio * 0.8), Color.WHITE)


# --- Utilidades de geometria ------------------------------------------------------------------

## Estrella de 5 puntas con una punta hacia `angulo`.
static func _estrella(centro: Vector2, radio: float, angulo: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 10:
		var a := angulo + i * PI / 5.0
		puntos.append(centro + Vector2.from_angle(a) * (radio if i % 2 == 0 else radio * 0.382))
	return puntos


static func _pintar(l, forma: PackedVector2Array, relleno: Color, r: float, trazo: float) -> void:
	if forma.size() < 3:
		return
	_rellenar(l, _mover(forma, Vector2(0, r * 0.07)), Color(COLOR_CONTORNO, 0.22))
	_rellenar(l, forma, relleno)
	for trozo in Geometry2D.clip_polygons(forma, _mover(forma, Vector2(-r * 0.05, -r * 0.09))):
		_rellenar(l, trozo, relleno.darkened(0.14))
	Figura.contornear(l, forma, trazo)


## Pieza de detalle encima (ventana, gema...): relleno y contorno, sin sombra.
static func _detalle(l, forma: PackedVector2Array, relleno: Color, trazo: float) -> void:
	if forma.size() < 3:
		return
	l.draw_colored_polygon(forma, relleno)
	Figura.contornear(l, forma, trazo)


## Pinta `pieza` recortada a `silueta` (manchas, pancita, franjas).
static func _dentro(l, pieza: PackedVector2Array, silueta: PackedVector2Array, relleno: Color) -> void:
	for trozo in Geometry2D.intersect_polygons(pieza, silueta):
		_rellenar(l, trozo, relleno)


## Relleno a prueba de recortes degenerados (astillas que no se pueden triangular) y de huecos.
static func _rellenar(l, forma: PackedVector2Array, relleno: Color) -> void:
	if forma.size() < 3 or absf(_area(forma)) < 0.5:
		return
	if Geometry2D.triangulate_polygon(forma).is_empty():
		return
	l.draw_colored_polygon(forma, relleno)


static func _ruedas(l, c: Vector2, r: float, trazo: float, centros: Array, radio: float) -> void:
	for p: Vector2 in centros:
		l.draw_circle(c + p * r, radio * r, RUEDA)
		l.draw_arc(c + p * r, radio * r, 0.0, TAU, 28, COLOR_CONTORNO, trazo, true)
		l.draw_circle(c + p * r, radio * r * 0.42, LLANTA)


static func _poli(c: Vector2, r: float, puntos: Array) -> PackedVector2Array:
	var salida := PackedVector2Array()
	for p: Vector2 in puntos:
		salida.append(c + p * r)
	return salida


static func _el(c: Vector2, r: float, centro: Vector2, rx: float, ry: float, lados := 32) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		var a := TAU * i / lados
		puntos.append(c + (centro + Vector2(cos(a) * rx, sin(a) * ry)) * r)
	return puntos


static func _circulo(centro: Vector2, radio: float, lados: int) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		puntos.append(centro + Vector2.from_angle(TAU * i / lados) * radio)
	return puntos


static func _caja(c: Vector2, r: float, x0: float, y0: float, x1: float, y1: float, redondeo := 0.0) -> PackedVector2Array:
	var puntos := _poli(c, r, [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])
	return _redondear(puntos, redondeo * r) if redondeo > 0.0 else puntos


static func _redondear(forma: PackedVector2Array, radio: float) -> PackedVector2Array:
	var adentro := Geometry2D.offset_polygon(forma, -radio, Geometry2D.JOIN_MITER)
	if adentro.is_empty():
		return forma
	var afuera := Geometry2D.offset_polygon(_mayor(adentro), radio, Geometry2D.JOIN_ROUND)
	return forma if afuera.is_empty() else _mayor(afuera)


static func _unir(partes: Array) -> PackedVector2Array:
	var forma: PackedVector2Array = partes[0]
	for i in range(1, partes.size()):
		forma = _mayor(Geometry2D.merge_polygons(forma, partes[i]))
	return forma


static func _mayor(poligonos: Array) -> PackedVector2Array:
	var mejor := PackedVector2Array()
	var mejor_area := -1.0
	for p: PackedVector2Array in poligonos:
		var area := absf(_area(p))
		if area > mejor_area:
			mejor_area = area
			mejor = p
	return mejor


static func _area(forma: PackedVector2Array) -> float:
	var suma := 0.0
	for i in forma.size():
		var a := forma[i]
		var b := forma[(i + 1) % forma.size()]
		suma += a.x * b.y - b.x * a.y
	return suma * 0.5


static func _mover(forma: PackedVector2Array, desfase: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for p in forma:
		puntos.append(p + desfase)
	return puntos
