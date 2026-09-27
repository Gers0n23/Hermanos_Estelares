extends SceneTree

## Arnes QA de "Pinta con Coco" (motor lienzo_libre): juega los 15 niveles (5 zonas x 3 rutas).
## Por nivel verifica: carga y hojas armadas, voces referenciadas existentes (incluidas las de los
## patrones de colores, pedidos y mezclas), tamanos tactiles (paleta, herramientas y "mostrar a Coco"
## >= 64 px; >= 96 px en Semilla), que toda region rellenable se pueda tocar, que un trazo simulado
## deje pintura, que el mosaico se complete y avise, pedidos de Coco y mezclas cumplidos, trajes de
## Coco, y que "mostrar a Coco" guarde un PNG valido por hoja y al final llegue `completado(destellos)`.
## Los dibujos van a user://qa_dibujos (nunca pisa los dibujos reales de los ninos) y se borran al final.
##
## Uso: godot --headless --path . --script herramientas/qa_test_lienzo.gd [-- <filtro>]

const MOTOR := "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn"
const Laminas := preload("res://scripts/motores/lienzo_libre/laminas.gd")
const Colores := preload("res://scripts/motores/lienzo_libre/colores_lienzo.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const CARPETA_QA := "user://qa_dibujos"

var _fallos := 0


func _initialize() -> void:
	print("=== QA lienzo_libre: Pinta con Coco, 5 zonas x rutas de Maxi, Nicole y Sofia ===")
	var filtro := ""
	if OS.get_cmdline_user_args().size() > 0:
		filtro = OS.get_cmdline_user_args()[0]
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/pinta_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			await _probar_nivel(ruta, HERMANOS[perfil])
	await _probar_mezclas()
	_borrar(CARPETA_QA)
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _existe_voz(ruta: String) -> bool:
	return ResourceLoader.exists("res://assets/audio/" + ruta)


func _probar_nivel(ruta: String, hermano: String) -> void:
	print("-- %s (%s) --" % [ruta.trim_prefix("res://datos/niveles/arcoiris/"), hermano])
	_check(FileAccess.file_exists(ruta), "existe el nivel")
	var motor: Node = load(MOTOR).instantiate()
	if not motor is MinijuegoBase:
		_check(false, "el motor carga su script (revisa errores de parseo arriba)")
		return
	motor.ruta_nivel = ruta
	motor.id_perfil = hermano
	motor.segundos_auto_continuar = 0.4
	motor.carpeta_dibujos = CARPETA_QA
	var resultado := {"destellos": -1}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	var mostradas: Array = []
	motor.hoja_mostrada.connect(func(i: int, png: String) -> void: mostradas.append(png))
	get_root().add_child(motor)
	await _esperar(0.5)

	var nivel: Dictionary = motor.nivel
	var perfil := str(nivel.get("perfil", ""))
	_check(str(nivel.get("motor", "")) == "lienzo_libre", "motor lienzo_libre, encargo %s" % nivel.get("encargo", "?"))
	var hojas: int = motor._hojas.size()
	_check(hojas >= 1, "%d hojas en la partida" % hojas)
	_revisar_voces(nivel)

	for h in hojas:
		while motor._indice_hoja != h and is_instance_valid(motor):
			await process_frame
		await _esperar(0.35)
		var hoja: Dictionary = motor._hojas[h]
		var lamina: Dictionary = hoja["lamina"]
		var encargo: String = motor._encargo
		print("   hoja %d/%d: %s · %s" % [h + 1, hojas, encargo, lamina.get("id", "papel en blanco")])
		_revisar_tactil(motor, perfil)
		var lienzo = motor.lienzo
		if not lienzo.mosaico.is_empty():
			await _jugar_mosaico(motor)
		elif encargo == "mezcla_paleta":
			await _jugar_mezcla(motor)
		elif not lienzo.lamina.is_empty() and not lienzo.regiones_rellenables().is_empty():
			if lamina.has("trajes"):
				await _jugar_trajes(motor, lamina)
			await _jugar_zonas(motor, encargo == "coco_pide")
		else:
			_jugar_trazo(motor)
		if not motor.boton_mostrar.visible:
			motor._al_tocar_anfitriona(_toque())
		_check(motor.boton_mostrar.visible, "boton 'mostrar a Coco' visible (Semilla: al tocar a Coco o tras un momento)")
		var png: String = motor.mostrar_a_coco()
		_revisar_png(png, motor.lienzo.tamano)
		if bool(hoja["cfg"].get("guardar_como", "") != ""):
			var fijo := "%s/%s/%s.png" % [CARPETA_QA, hermano, hoja["cfg"]["guardar_como"]]
			_check(FileAccess.file_exists(fijo), "copia fija para el hangar: %s" % fijo.get_file())
	var t0 := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	_check(mostradas.size() == hojas, "%d hojas mostradas a Coco" % mostradas.size())
	_check(resultado["destellos"] > 0, "completado(destellos) recibido: %d" % resultado["destellos"])
	motor.queue_free()
	await process_frame


func _toque() -> InputEventMouseButton:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = true
	return evento


## Toda ruta de voz del nivel (y las de los patrones) debe existir.
func _revisar_voces(nivel: Dictionary) -> void:
	var rutas: Array = []
	_juntar_rutas(nivel, rutas)
	var faltan: Array = []
	for r in rutas:
		if not _existe_voz(r):
			faltan.append(r)
	var ids: Array = nivel.get("paleta", []).duplicate()
	if str(nivel.get("encargo", "")) == "mezcla_paleta":
		ids = Colores.COLORES.keys()
	for id in ids:
		for clave in ["voces_colores"]:
			if nivel.has(clave) and not _existe_voz(str(nivel[clave]) % id):
				faltan.append(str(nivel[clave]) % id)
	for pedido in nivel.get("pedidos", []):
		for clave in ["voces_pedidos", "voces_logrado"]:
			if nivel.has(clave) and not _existe_voz(str(nivel[clave]) % pedido):
				faltan.append(str(nivel[clave]) % pedido)
	_check(faltan.is_empty(), "%d voces referenciadas existen%s" % [rutas.size(), "" if faltan.is_empty() else " — faltan: %s" % str(faltan)])


func _juntar_rutas(valor, rutas: Array) -> void:
	if valor is Dictionary:
		for v in valor.values():
			_juntar_rutas(v, rutas)
	elif valor is Array:
		for v in valor:
			_juntar_rutas(v, rutas)
	elif valor is String and valor.begins_with("voces/") and not valor.contains("%s"):
		if not rutas.has(valor):
			rutas.append(valor)


func _revisar_tactil(motor, perfil: String) -> void:
	var minimo := 96.0 if perfil == "semilla" else 64.0
	var chicos: Array = []
	for entrada: Dictionary in motor._botones_color:
		var tam: Vector2 = entrada["boton"].size
		if minf(tam.x, tam.y) < minimo:
			chicos.append("color %s" % tam)
	for entrada: Dictionary in motor._botones_herramienta:
		var tam: Vector2 = entrada["boton"].size
		if minf(tam.x, tam.y) < minimo:
			chicos.append("%s %s" % [entrada["id"], tam])
	if minf(motor.boton_mostrar.size.x, motor.boton_mostrar.size.y) < 96.0:
		chicos.append("mostrar %s" % motor.boton_mostrar.size)
	_check(chicos.is_empty(), "tactiles >= %d px (%d colores, %d herramientas, mostrar %s)%s" % [minimo, motor._botones_color.size(), motor._botones_herramienta.size(), motor.boton_mostrar.size, "" if chicos.is_empty() else " — chicos: %s" % str(chicos)])


## Un trazo en diagonal con la herramienta activa debe dejar pintura (o un sello).
func _jugar_trazo(motor) -> void:
	var lienzo = motor.lienzo
	var antes: int = lienzo.pixeles_pintados() + lienzo.cantidad_sellos_vivos()
	lienzo.empezar_trazo(Vector2(150, 150))
	for i in range(1, 21):
		lienzo.continuar_trazo(Vector2(150, 150).lerp(Vector2(650, 400), i / 20.0))
	lienzo.terminar_trazo()
	lienzo._process(0.016)
	var despues: int = lienzo.pixeles_pintados() + lienzo.cantidad_sellos_vivos()
	_check(despues > antes, "trazo con '%s' deja huella (%d -> %d)" % [lienzo.herramienta, antes, despues])
	if lienzo.simetria != "":
		var espejo: Vector2 = lienzo.puntos_simetricos(Vector2(150, 150))[1]
		var imagen: Image = lienzo._pintura
		_check(imagen.get_pixelv(Vector2i(espejo)).a > 0.1, "simetria '%s': el reflejo tambien se pinto" % lienzo.simetria)


## Toca cada region rellenable en un punto donde sea la de mas arriba; al final debe avisar completa.
func _jugar_zonas(motor, con_pedidos: bool) -> void:
	var lienzo = motor.lienzo
	lienzo.herramienta = "balde"
	var completa := {"si": false}
	lienzo.lamina_completa.connect(func() -> void: completa["si"] = true, CONNECT_ONE_SHOT)
	var inalcanzables: Array = []
	var pedidos_cumplidos := {"n": 0}
	if con_pedidos:
		motor.pedido_cumplido.connect(func(_id: String) -> void: pedidos_cumplidos["n"] += 1)
	var regiones: Array = lienzo.regiones_rellenables()
	for i in regiones:
		var punto = _punto_de(lienzo.lamina, i)
		if punto == null:
			inalcanzables.append(str(lienzo.lamina["regiones"][i].get("id", i)))
			continue
		if con_pedidos and motor._pedido_actual >= 0:
			for entrada: Dictionary in motor._botones_color:
				if entrada["id"] == str(motor._pedidos[motor._pedido_actual]):
					motor._seleccionar_color(entrada, false)
		else:
			var entradas: Array = motor._botones_color
			if not entradas.is_empty():
				motor._seleccionar_color(entradas[randi() % entradas.size()], false)
		lienzo.empezar_trazo(punto)
		lienzo.terminar_trazo()
	_check(inalcanzables.is_empty(), "%d regiones rellenables, todas tocables%s" % [regiones.size(), "" if inalcanzables.is_empty() else " — tapadas: %s" % str(inalcanzables)])
	_check(lienzo.regiones_pintadas() == regiones.size() - inalcanzables.size(), "%d regiones pintadas" % lienzo.regiones_pintadas())
	_check(completa["si"], "la lamina avisa que quedo completa")
	if con_pedidos:
		_check(pedidos_cumplidos["n"] >= motor._pedidos.size() or motor._pedido_actual < 0, "Coco pide: %d pedidos cumplidos" % pedidos_cumplidos["n"])
	await _esperar(0.2)


func _punto_de(lamina: Dictionary, indice: int):
	var poligono: PackedVector2Array = lamina["regiones"][indice]["poligono"]
	var caja := Rect2(poligono[0], Vector2.ZERO)
	for p in poligono:
		caja = caja.expand(p)
	var centro := caja.get_center()
	if Laminas.region_en(lamina, centro) == indice:
		return centro
	var paso := maxf(2.0, minf(caja.size.x, caja.size.y) / 12.0)
	var y := caja.position.y + paso / 2.0
	while y < caja.end.y:
		var x := caja.position.x + paso / 2.0
		while x < caja.end.x:
			if Laminas.region_en(lamina, Vector2(x, y)) == indice:
				return Vector2(x, y)
			x += paso
		y += paso
	return null


## Colorear por codigo: pinta cada celda con su color de la leyenda arrastrando por filas.
func _jugar_mosaico(motor) -> void:
	var lienzo = motor.lienzo
	var completa := {"si": false}
	lienzo.lamina_completa.connect(func() -> void: completa["si"] = true, CONNECT_ONE_SHOT)
	var total: int = lienzo.total_celdas()
	_check(lienzo._lado_celda >= 40.0, "celdas de %d px (%dx%d)" % [lienzo._lado_celda, str(lienzo.mosaico["celdas"][0]).length(), lienzo.mosaico["celdas"].size()])
	_check(motor._botones_color.size() == lienzo.mosaico.get("colores", {}).size(), "leyenda con %d colores numerados" % motor._botones_color.size())
	for entrada: Dictionary in motor._botones_color:
		motor._seleccionar_color(entrada, false)
		var filas: Array = lienzo.mosaico["celdas"]
		for y in filas.size():
			for x in str(filas[y]).length():
				if lienzo.color_esperado(Vector2i(x, y)).is_equal_approx(entrada["color"]):
					lienzo.empezar_trazo(lienzo.centro_celda(Vector2i(x, y)))
					lienzo.terminar_trazo()
	_check(lienzo.celdas_correctas() == total, "%d de %d celdas con su color" % [lienzo.celdas_correctas(), total])
	_check(completa["si"], "el mosaico avisa completo (Coco dice cual es)")
	await _esperar(2.0)
	_check(motor._lamina_nombrada, "Coco nombro el dibujo secreto")


## Mezcla: echa gotas para cumplir cada pedido de Coco y pinta con la mezcla.
func _jugar_mezcla(motor) -> void:
	var recetas := {"verde": {"azul": 1, "amarillo": 1}, "naranja": {"rojo": 1, "amarillo": 1}, "violeta": {"rojo": 1, "azul": 1},
		"rosado": {"rojo": 1, "blanco": 1}, "celeste": {"azul": 1, "blanco": 1}, "cafe": {"rojo": 1, "amarillo": 1, "azul": 1},
		"lila": {"rojo": 1, "azul": 1, "blanco": 1}}
	var cumplidos := {"n": 0}
	motor.pedido_cumplido.connect(func(_id: String) -> void: cumplidos["n"] += 1)
	var total: int = motor._pedidos.size()
	for i in total:
		var pedido := str(motor._pedidos[motor._pedido_actual])
		motor._gotas = {}
		var receta: Dictionary = recetas.get(pedido, {})
		var orden: Array = receta.keys()
		for id in orden:
			for k in int(receta[id]):
				motor._agregar_gota(id)
		await _esperar(0.05)
	_check(cumplidos["n"] == total, "mezcla: %d de %d pedidos cumplidos mezclando" % [cumplidos["n"], total])
	_check(motor._mis_colores.size() > 0, "las mezclas quedan en 'mis colores' (%d)" % motor._mis_colores.size())
	await _jugar_zonas(motor, false)


func _jugar_trajes(motor, lamina: Dictionary) -> void:
	for id in lamina.get("orden_trajes", []):
		motor._elegir_traje(str(id), false)
		_check(motor._traje == str(id), "traje de Coco: %s" % id)
	await _esperar(0.1)


func _revisar_png(ruta: String, tamano: Vector2i) -> void:
	if ruta == "":
		_check(false, "se guardo el PNG del dibujo")
		return
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
	_check(imagen != null and imagen.get_size() == tamano, "PNG guardado %s (%s)" % [ruta.get_file(), imagen.get_size() if imagen != null else "ilegible"])
	if imagen != null:
		var colores := {}
		for y in range(0, tamano.y, 23):
			for x in range(0, tamano.x, 23):
				colores[imagen.get_pixel(x, y).to_html(false)] = true
		_check(colores.size() >= 3, "el PNG tiene dibujo (%d colores distintos)" % colores.size())


## Tabla de mezclas del modelo RYB: lo que ensena el colegio.
func _probar_mezclas() -> void:
	print("-- mezclas de colores (RYB) --")
	var casos := [[{"azul": 1, "amarillo": 1}, "verde"], [{"rojo": 1, "amarillo": 1}, "naranja"], [{"rojo": 1, "azul": 1}, "violeta"],
		[{"rojo": 1, "amarillo": 1, "azul": 1}, "cafe"], [{"rojo": 1, "blanco": 1}, "rosado"], [{"azul": 2, "blanco": 1}, "celeste"],
		[{"rojo": 1, "azul": 1, "blanco": 1}, "lila"], [{"rojo": 3}, "rojo"]]
	for caso in casos:
		var nombre := Colores.nombre_mezcla(caso[0])
		var color := Colores.mezclar(caso[0])
		_check(nombre == caso[1], "%s -> %s (#%s)" % [str(caso[0]), nombre, color.to_html(false)])
	var verde := Colores.mezclar({"azul": 1, "amarillo": 1})
	_check(verde.g > verde.r and verde.g > verde.b, "azul + amarillo se ve verde")
	var cafe := Colores.mezclar({"rojo": 1, "amarillo": 1, "azul": 1})
	_check(cafe.r > cafe.b and cafe.get_luminance() > 0.15, "los tres primarios dan cafe, no negro")
	await process_frame


func _borrar(carpeta: String) -> void:
	var dir := DirAccess.open(carpeta)
	if dir == null:
		return
	for sub in dir.get_directories():
		_borrar(carpeta.path_join(sub))
	for archivo in dir.get_files():
		dir.remove(archivo)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(carpeta))
