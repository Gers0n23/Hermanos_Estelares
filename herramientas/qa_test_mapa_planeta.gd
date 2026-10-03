extends SceneTree

## Arnes QA del flujo Mapa Estelar -> mapa del Planeta Arcoiris (zonas y estaciones) -> minijuego.
## Verifica: la nave empieza en la Tierra y tocar Arcoiris lanza el viaje estelar, que al
## aterrizar abre su mapa (y luego se entra directo); zona 1 abierta y el resto dormidas; estaciones jugables
## segun el hermano; lanzar una estacion entrega el contrato al motor; "salir" y "completado"
## vuelven al mapa del planeta; completar TODAS las estaciones jugables abre la zona siguiente
## (decision del PO 27-Sep-2026) y devuelve el color; el mapa se dibuja con el paisaje de dulces; la zona secreta se revela; Cometa lleva a la siguiente
## estacion pendiente; F4 abre todo; la flecha vuelve al Mapa Estelar.
## Respalda y restaura `user://progreso.json` para no pisar el progreso real de los ninos.
##
## Uso: godot --headless --path . --script herramientas/qa_test_mapa_planeta.gd

const MAPA := "res://escenas/nucleo/mapa_estelar.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const VIAJE := "res://escenas/nucleo/viaje_estelar.tscn"
const GUARDADO := "user://progreso.json"

var _fallos := 0
var _respaldo = null
var _progreso: Node


func _initialize() -> void:
	print("=== QA mapa estelar -> mapa del Planeta Arcoiris -> estacion ===")
	_progreso = get_root().get_node("Progreso")
	if FileAccess.file_exists(GUARDADO):
		_respaldo = FileAccess.get_file_as_string(GUARDADO)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	_progreso.perfil_seleccionado = "maxi"

	await _probar_entrada_desde_mapa_estelar()
	await _probar_estado_inicial()
	await _probar_lanzar_y_volver("salir")
	await _probar_lanzar_y_volver("completado")
	await _probar_apertura_con_dos_estaciones()
	await _probar_zona_secreta_sofia()
	await _probar_cometa()
	await _probar_f4_y_salida()
	await _probar_marco_dorado_y_destellos()

	if _respaldo != null:
		var archivo := FileAccess.open(GUARDADO, FileAccess.WRITE)
		archivo.store_string(_respaldo)
		archivo.close()
		_progreso.cargar()
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


func _abrir_arcoiris() -> Node:
	change_scene_to_file(ARCOIRIS)
	await _esperar(0.3)
	return current_scene


func _probar_entrada_desde_mapa_estelar() -> void:
	print("-- tocar Arcoiris en el Mapa Estelar --")
	change_scene_to_file(MAPA)
	await _esperar(0.2)
	var mapa := current_scene
	_check(mapa != null and mapa.scene_file_path == MAPA, "mapa estelar cargado")
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = Vector2(300, 545)
	# Directo al handler (como qa_test_titulo): en headless push_input re-escala las coordenadas.
	_check(_progreso.obtener_ubicacion_nave("maxi") == "tierra", "la nave empieza posada en la Tierra")
	mapa._input(toque)
	await _esperar(0.9)
	# la nave esta en la Tierra: primero se juega el viaje estelar Tierra -> Arcoiris
	var viaje := current_scene
	_check(viaje != null and viaje.scene_file_path == VIAJE, "tocar Arcoiris lanza el viaje estelar (%s)" % str(viaje.scene_file_path if viaje else "nada"))
	if viaje == null or viaje.scene_file_path != VIAJE:
		return
	_check(viaje.planeta_origen == "tierra" and viaje.planeta_destino == "arcoiris", "el viaje va de la Tierra a Arcoiris")
	var destellos_antes: int = _progreso.obtener_destellos_planeta("maxi", "arcoiris")
	viaje.completado.emit(3)
	await _esperar(0.3)
	_check(current_scene != null and current_scene.scene_file_path == ARCOIRIS, "al aterrizar se abre el mapa del planeta (%s)" % str(current_scene.scene_file_path if current_scene else "nada"))
	_check(_progreso.obtener_ubicacion_nave("maxi") == "arcoiris", "la nave queda estacionada en Arcoiris")
	_check(_progreso.obtener_destellos_planeta("maxi", "arcoiris") == destellos_antes + 3, "los destellos del viaje cuentan para Arcoiris")
	# con la nave ya en Arcoiris, tocarlo entra directo (sin volver a viajar)
	change_scene_to_file(MAPA)
	await _esperar(0.2)
	current_scene._input(toque)
	await _esperar(0.3)
	_check(current_scene != null and current_scene.scene_file_path == ARCOIRIS, "con la nave ahi, tocar Arcoiris entra directo al mapa del planeta")


func _probar_estado_inicial() -> void:
	print("-- estado inicial (Maxi) --")
	var mapa := await _abrir_arcoiris()
	_check(mapa.planeta_id == "arcoiris" and mapa.zonas.size() == 5, "5 zonas del Planeta Arcoiris")
	_check(mapa._paisaje != null and mapa._paisaje.has_method("dibujar_hito"), "el planeta se dibuja como mapa ilustrado de dulces (paisaje)")
	_check(mapa.zonas[0]["abierta"], "zona 1 abierta al llegar")
	var dormidas := true
	for i in range(1, 5):
		dormidas = dormidas and not mapa.zonas[i]["abierta"]
	_check(dormidas, "zonas 2-5 dormidas")
	var estaciones: Array = mapa.zonas[0]["estaciones"]
	_check(estaciones.size() == 4, "4 estaciones por zona")
	_check(estaciones[1]["juego"] == "formas" and estaciones[1]["jugable"], "Formas traviesas jugable en la zona 1")
	var coherentes := true
	for estacion: Dictionary in estaciones:
		var tiene_nivel: bool = estacion["datos"].get("niveles", {}).has("maxi") and str(estacion["escena"]) != ""
		coherentes = coherentes and estacion["jugable"] == tiene_nivel
	_check(coherentes, "cada estacion es jugable solo si el mapa trae escena y nivel de Maxi (las demas se ven 'pintandose')")
	_check(mapa.zonas[1]["estaciones"][2]["jugable"], "Parejas de Coco de Maxi vive en la zona 2")
	_check(mapa.seleccion == 0, "zona elegida: la 1")
	var tamanos := true
	for tarjeta in mapa._tarjetas:
		tamanos = tamanos and tarjeta.size.x >= 96.0 and tarjeta.size.y >= 96.0
	for nodo in mapa._nodos_zona:
		tamanos = tamanos and nodo.size.x >= 96.0
	_check(tamanos, "zonas y estaciones tocables >= 96 px (GDD §6.1)")
	var pantalla := Rect2(0, 0, 1280, 720)
	var dentro := true
	for control in mapa._tarjetas + mapa._nodos_zona + [mapa._boton_cometa, mapa._boton_salir, mapa._anfitriona]:
		dentro = dentro and pantalla.encloses(control.get_global_rect())
	_check(dentro, "todo dentro de la pantalla 1280x720")
	var choque := false
	for tarjeta in mapa._tarjetas:
		for otro in [mapa._boton_cometa, mapa._anfitriona]:
			choque = choque or tarjeta.get_global_rect().intersects(otro.get_global_rect())
	_check(not choque, "estaciones no chocan con Coco ni Cometa")
	mapa._tocar_zona(1)
	_check(mapa.seleccion == 0, "tocar una zona dormida no la abre (solo menea y Coco explica)")
	_check(str(mapa.SFX_NO).ends_with("zona_dormida.ogg") and ResourceLoader.exists(mapa.SFX_NO), "UX R16: la zona dormida suena con campanitas de sueño (no el error de Kenney)")
	var sin_nivel := -1
	for j in estaciones.size():
		if not estaciones[j]["jugable"]:
			sin_nivel = j
			break
	if sin_nivel >= 0:
		mapa._tocar_estacion(sin_nivel)
		_check(not mapa._lanzando, "tocar una estacion sin nivel no lanza nada")
	else:
		print("  --    (las 4 estaciones de la zona 1 ya tienen nivel: no hay estacion 'pintandose' que tocar)")


func _probar_lanzar_y_volver(forma: String) -> void:
	print("-- lanzar Formas traviesas (zona 1) y volver por '%s' --" % forma)
	var mapa := await _abrir_arcoiris()
	if forma == "completado":
		# Formas es la ultima estacion pendiente de la zona 1: las demas jugables ya estan hechas.
		_completar_estaciones(mapa, "maxi", 0, 0, 1)
		mapa = await _abrir_arcoiris()
	mapa._tocar_estacion(1)
	await _esperar(1.3)
	var motor := current_scene
	_check(motor is MinijuegoBase, "la estacion abre un motor de minijuego (%s)" % str(motor))
	if not motor is MinijuegoBase:
		return
	_check(motor.ruta_nivel.ends_with("zona1_claro/formas_semilla.json"), "Maxi recibe su nivel de la zona 1 (%s)" % motor.ruta_nivel)
	_check(motor.planeta_id == "arcoiris" and motor.id_perfil == "maxi", "contrato: planeta y hermano")
	if forma == "salir":
		motor.salir_solicitado.emit()
	else:
		motor.emitir_completado(30, 0)
	await _esperar(0.4)
	_check(current_scene != null and current_scene.scene_file_path == ARCOIRIS, "vuelve al mapa del planeta tras '%s'" % forma)
	if forma == "completado":
		var vuelta := current_scene
		_check(vuelta.zonas[0]["estaciones"][1]["completada"], "la estacion quedo completada")
		_check(vuelta.zonas[0]["completa"], "zona 1 completa (todas sus estaciones jugables): vuelve el rojo")
		_check(vuelta._avance_bandas.has("rojo"), "la banda roja del arcoiris se pinta con animacion")
		_check(vuelta.zonas[1]["abierta"], "se despierta la zona 2 (todas las estaciones jugables de la zona 1 estan hechas)")
		_check(vuelta.seleccion == 1, "el mapa lleva la seleccion a la zona recien abierta")


func _completar_estaciones(mapa: Node, hermano: String, zona: int, estrellitas: int, excepto: int = -1) -> int:
	## Marca completadas las estaciones jugables de una zona (salvo `excepto`) usando el mismo id de
	## nivel que calcula el mapa. Devuelve cuantas marco. Asi el arnes no depende de que juegos existen.
	var marcadas := 0
	var estaciones: Array = mapa.zonas[zona]["estaciones"]
	for j in estaciones.size():
		if j == excepto or not estaciones[j]["jugable"]:
			continue
		_progreso.marcar_nivel_completado(hermano, "arcoiris", mapa._id_nivel(estaciones[j]["ruta_nivel"]), 50, estrellitas)
		marcadas += 1
	return marcadas


func _probar_apertura_con_dos_estaciones() -> void:
	print("-- zona 2 de Maxi: pide TODAS sus estaciones jugables --")
	var mapa := await _abrir_arcoiris()
	var jugables: int = mapa.zonas[1]["jugables"]
	_check(jugables >= 2, "zona 2 de Maxi tiene varias estaciones jugables (%d)" % jugables)
	# todas menos Parejas (estacion 2)
	_completar_estaciones(mapa, "maxi", 1, 0, 2)
	mapa = await _abrir_arcoiris()
	_check(mapa.zonas[1]["completadas"] == jugables - 1, "zona 2: %d de %d estaciones" % [mapa.zonas[1]["completadas"], jugables])
	_check(not mapa.zonas[2]["abierta"], "con una estacion pendiente, la zona 3 sigue dormida")
	_progreso.marcar_nivel_completado("maxi", "arcoiris", mapa._id_nivel(mapa.zonas[1]["estaciones"][2]["ruta_nivel"]), 40, 0)
	mapa = await _abrir_arcoiris()
	_check(mapa.zonas[2]["abierta"], "con todas hechas, se despierta la zona 3")


func _probar_zona_secreta_sofia() -> void:
	print("-- Sofia: zona secreta y estrellitas --")
	_progreso.perfil_seleccionado = "sofia"
	# Regla del PO 27-Sep-2026: con solo UNA estacion de la zona 1, la zona 2 sigue dormida.
	_progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_z1_formas_estrella", 50, 3)
	var parcial := await _abrir_arcoiris()
	_check(parcial.zonas[0]["completadas"] == 1 and parcial.zonas[0]["jugables"] >= 2, "Sofia: zona 1 con 1 de %d estaciones" % parcial.zonas[0]["jugables"])
	_check(not parcial.zonas[1]["abierta"], "con 1 estacion NO se salta a la zona 2 (hay que completarlas todas)")
	for n in [0, 1, 2]:
		_completar_estaciones(parcial, "sofia", n, 2, 1 if n == 0 else -1)
	var mapa := await _abrir_arcoiris()
	_check(mapa.zonas[1]["abierta"] and mapa.zonas[2]["abierta"], "con todas las estaciones hechas, las zonas 2 y 3 despiertan")
	_check(mapa.zonas[3]["abierta"] and not mapa.zonas[4]["abierta"], "zona 4 abierta, la Cima sigue secreta")
	_check(mapa.zonas[0]["estaciones"][1]["estrellitas"] == 3, "la estacion muestra las mejores estrellitas (3)")
	_check(mapa.zonas[0]["estaciones"][1]["dorado_ruta"] == "", "sin reto dorado fuera de la Cima")
	_completar_estaciones(mapa, "sofia", 3, 1)
	mapa = await _abrir_arcoiris()
	_check(mapa.zonas[4]["abierta"], "completar la zona 4 revela la Cima del Arcoiris")
	_check(mapa.seleccion == 4, "el mapa lleva a la zona secreta recien revelada")


func _probar_cometa() -> void:
	print("-- Cometa lleva a la siguiente estacion pendiente --")
	var mapa := await _abrir_arcoiris()
	var esperada := -1
	var estaciones: Array = mapa.zonas[4]["estaciones"]
	for j in estaciones.size():
		if estaciones[j]["jugable"]:
			esperada = j
			break
	var destino: Array = mapa.siguiente_estacion()
	_check(destino[0] == 4 and destino[1] == esperada, "siguiente pendiente de Sofia: la primera estacion jugable de la Cima (%s)" % str(destino))
	var ruta: String = estaciones[esperada]["ruta_nivel"] if esperada >= 0 else "?"
	mapa._tocar_cometa()
	await _esperar(1.9)
	var motor := current_scene
	_check(motor is MinijuegoBase and motor.ruta_nivel == ruta, "Cometa abre esa estacion (%s)" % ruta.get_file())
	if motor is MinijuegoBase:
		motor.salir_solicitado.emit()
		await _esperar(0.4)


func _probar_f4_y_salida() -> void:
	print("-- F4 (PO) y flecha de salida --")
	_progreso.perfil_seleccionado = "nicole"
	var mapa := await _abrir_arcoiris()
	_check(mapa.zonas[0]["abierta"] and not mapa.zonas[1]["abierta"], "Nicole empieza con su propio avance (zona 1)")
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_F4
	tecla.pressed = true
	mapa._unhandled_key_input(tecla)
	var todas := true
	for zona in mapa.zonas:
		todas = todas and zona["abierta"]
	_check(todas, "F4 abre todas las zonas para revisar variantes")
	_check(mapa.zonas[2]["estaciones"][2]["jugable"], "Parejas de Nicole vive en la zona 3")
	mapa._unhandled_key_input(tecla)
	_check(not mapa.zonas[1]["abierta"], "F4 otra vez vuelve a las reglas normales")
	mapa._volver_al_mapa_estelar()
	await _esperar(0.3)
	_check(current_scene != null and current_scene.scene_file_path == MAPA, "la flecha vuelve al Mapa Estelar")


## HE-40 / HE-44 (28-Sep-2026): la zona "perfecta" (marco dorado de Sofia) no cuenta Pinta, que no
## puntua; el mapa pasa a cada motor el monto fijo de destellos (100 por estacion, 0 en reto dorado).
func _probar_marco_dorado_y_destellos() -> void:
	print("-- HE-40/HE-44: marco dorado alcanzable y destellos fijos por estacion --")
	_progreso.perfil_seleccionado = "sofia"
	var mapa := await _abrir_arcoiris()
	var pinta: Dictionary = mapa.zonas[0]["estaciones"][3]
	_check(pinta["juego"] == "pinta" and not pinta["puntua"], "Pinta con Coco no puntua estrellitas")
	_check(mapa.zonas[0]["estaciones"][1]["puntua"], "Formas si puntua")
	# Zona 1 de Sofia con 2 estrellitas en alguna estacion con puntaje: no es perfecta.
	_check(not mapa.evento_zona(0)["perfecta"], "zona con una estacion de 2 estrellitas: sin marco dorado")
	_completar_estaciones(mapa, "sofia", 0, 3, 3)
	_progreso.marcar_nivel_completado("sofia", "arcoiris", mapa._id_nivel(pinta["ruta_nivel"]), 50, 0)
	mapa = await _abrir_arcoiris()
	_check(mapa.evento_zona(0)["perfecta"], "3 estrellitas en Lluvia/Taller, Formas y Parejas (Pinta con 0): marco dorado alcanzable")
	# HE-40 mecanicas #3: la silueta del ala existe y ya tiene pintado el tramo de la zona 1
	# (_probar_zona_secreta_sofia ya completo otras zonas de Sofia; aqui solo importa la 1).
	_check(mapa._pieza != null and mapa._pieza.visible and mapa.zonas[0]["completa"],
		"silueta del ala en el mapa con el tramo de la zona 1 pintado")
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://datos/planetas/arcoiris/mapa.json"))
	_check(int(datos.get("destellos_por_estacion", -1)) == 100 and int(datos.get("destellos_reto_dorado", -1)) == 0, "mapa.json: 100 destellos por estacion, 0 en retos dorados")
	# Nicole juega una estacion nueva: celebra y guarda 100, no el calculo del motor.
	_progreso.perfil_seleccionado = "nicole"
	mapa = await _abrir_arcoiris()
	var antes: int = _progreso.obtener_destellos_planeta("nicole", "arcoiris")
	mapa._tocar_estacion(1)
	await _esperar(1.3)
	var motor := current_scene
	_check(motor is MinijuegoBase and motor.destellos_fijos == 100, "el mapa fija 100 destellos en el motor (%s)" % str(motor.get("destellos_fijos") if motor else "?"))
	if motor is MinijuegoBase:
		motor.emitir_completado(37, 0)
		await _esperar(0.4)
	_check(_progreso.obtener_destellos_planeta("nicole", "arcoiris") == antes + 100, "se guardan 100 destellos, iguales para todos (antes %d)" % antes)
	# Reto dorado: 0 destellos (su premio es cosmetico).
	_progreso.perfil_seleccionado = "sofia"
	mapa = await _abrir_arcoiris()
	mapa.todo_abierto = true
	mapa.calcular_estado()
	var cima: Array = mapa.zonas[4]["estaciones"]
	var j_dorado := -1
	for j in cima.size():
		if cima[j]["dorado_ruta"] != "":
			j_dorado = j
			break
	_check(j_dorado >= 0, "hay un reto dorado en la Cima")
	if j_dorado >= 0:
		mapa.lanzar_estacion(4, j_dorado, 0.0, true)
		await _esperar(1.3)
		_check(current_scene is MinijuegoBase and current_scene.destellos_fijos == 0, "el reto dorado no da destellos (destellos_fijos = 0)")
		if current_scene is MinijuegoBase:
			current_scene.salir_solicitado.emit()
			await _esperar(0.4)
	current_scene.todo_abierto = false
