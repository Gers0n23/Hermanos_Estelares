extends SceneTree

## Arnes QA de los pares favoritos de Parejas (PO 17-Oct-2026): catalogo por hermano, que todas las
## imagenes carguen como textura, la mezcla (mismo tamano de grupo, sin tocar el par especial, solo en
## modos identicos, apagable por nivel) y un tablero real con un par favorito.
##
## Uso: godot --headless --path . --script herramientas/qa_test_favoritos.gd

const Favoritos := preload("res://scripts/motores/emparejar/favoritos_emparejar.gd")
const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const NIVEL := "res://datos/niveles/arcoiris/zona1_claro/parejas_estrella.json"

var _ok := 0
var _fallos := 0


func _check(condicion: bool, texto: String) -> void:
	if condicion:
		_ok += 1
	else:
		_fallos += 1
		print("FALLO: ", texto)


func _initialize() -> void:
	_probar.call_deferred()


func _grupos(cantidad: int, tamano := 2) -> Array:
	var grupos: Array = []
	for i in cantidad:
		var elementos: Array = []
		for j in tamano:
			elementos.append({"id": "e%d_%d" % [i, j], "figura": "estrella"})
		grupos.append({"id_grupo": "g%d" % i, "especial": i == 0, "fijo": i == 1, "voz": "pais.wav" if i == 2 else "",
			"elementos": elementos})
	return grupos


func _probar() -> void:
	var maxi := Favoritos.imagenes_para(["maxi"])
	var ninas := Favoritos.imagenes_para(["nicole"])
	var temas_maxi := {}
	for imagen in maxi:
		temas_maxi[imagen["tema"]] = true
	_check(maxi.size() >= 80, "Maxi tiene %d imagenes" % maxi.size())
	_check(ninas.size() >= 120, "Nicole tiene %d imagenes" % ninas.size())
	_check(temas_maxi.has("sonic") and temas_maxi.has("tayo") and not temas_maxi.has("katseye"),
		"temas de Maxi: %s" % str(temas_maxi.keys()))
	_check(Favoritos.imagenes_para(["sofia"]).size() == ninas.size(), "Sofia y Nicole comparten temas")
	_check(Favoritos.imagenes_para(["maxi", "sofia"]).size() == maxi.size() + ninas.size(), "equipo suma temas")

	var malas := 0
	for imagen in maxi + ninas:
		var textura: Texture2D = load("res://assets/" + imagen["archivo"])
		if textura == null or textura.get_width() < 128:
			malas += 1
			print("  textura mala: ", imagen["archivo"])
	_check(malas == 0, "%d texturas no cargan" % malas)

	# Mezcla forzada: siempre cambia, respeta el especial y el tamano de grupo.
	for vuelta in 30:
		var grupos := _grupos(6, 3)
		var mezcla := Favoritos.mezclar(grupos, {"modo": "trios", "favoritos": {"probabilidad": 1.0, "maximo": 2}}, ["maxi"])
		var favoritos := mezcla.filter(func(g: Dictionary) -> bool: return g.get("favorito", false))
		_check(favoritos.size() == 2, "vuelta %d: %d favoritos" % [vuelta, favoritos.size()])
		_check(not mezcla[0].get("favorito", false), "el par especial no se toca")
		_check(not mezcla[1].get("favorito", false) and not mezcla[2].get("favorito", false), "ni el fijo ni el que tiene voz")
		for g: Dictionary in favoritos:
			_check(g["elementos"].size() == 3 and str(g["voz"]) == "", "grupo favorito de 3 sin voz")
			_check(str(g["elementos"][0]["sprite"]).contains("favoritos/") , "sprite de favoritos")
		_check(favoritos[0]["id_grupo"] != favoritos[1]["id_grupo"], "dos favoritos distintos")
	_check(not Favoritos.mezclar(_grupos(6), {"modo": "sombras"}, ["maxi"]).any(
		func(g: Dictionary) -> bool: return g.get("favorito", false)), "sombras: sin favoritos")
	_check(not Favoritos.mezclar(_grupos(6), {"modo": "identico", "favoritos": false}, ["maxi"]).any(
		func(g: Dictionary) -> bool: return g.get("favorito", false)), "apagado por nivel")
	var con := 0
	for vuelta in 400:
		if Favoritos.mezclar(_grupos(5), {"modo": "identico"}, ["sofia"]).any(
				func(g: Dictionary) -> bool: return g.get("favorito", false)):
			con += 1
	_check(con > 150 and con < 250, "probabilidad por defecto ~50%%: %d/400" % con)

	# Tablero real: el nivel con favoritos forzados muestra cartas con foto y marco.
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = NIVEL
	motor.id_perfil = "sofia"
	var texto := FileAccess.get_file_as_string(NIVEL)
	root.add_child(motor)
	await process_frame
	await process_frame
	motor._conf["favoritos"] = {"probabilidad": 1.0, "maximo": 1}
	for carta in motor._cartas:
		carta.queue_free()
	motor._cartas.clear()
	motor._construir_tablero()
	await process_frame
	var fotos: Array = motor._cartas.filter(func(c) -> bool: return c.favorito)
	_check(fotos.size() >= 2, "tablero real con %d cartas favoritas" % fotos.size())
	_check(fotos.all(func(c) -> bool: return c.textura() != null), "las cartas favoritas tienen foto")
	if fotos.size() >= 2:
		_check(fotos[0].id_pareja == fotos[1].id_pareja, "la foto forma par")
	_check(texto != "", "nivel leido")
	motor.queue_free()

	print("qa_test_favoritos: %d OK / %d fallos" % [_ok, _fallos])
	quit(1 if _fallos > 0 else 0)
