extends SceneTree

## Arnes QA del flujo Mapa Estelar -> mapa del Planeta Arcoiris (zonas y estaciones) -> minijuego.
## Verifica: tocar Arcoiris abre su mapa; zona 1 abierta y el resto dormidas; estaciones jugables
## segun el hermano; lanzar una estacion entrega el contrato al motor; "salir" y "completado"
## vuelven al mapa del planeta; completar estaciones abre la zona siguiente (con la regla
## min(2, jugables)) y devuelve el color; la zona secreta se revela; Cometa lleva a la siguiente
## estacion pendiente; F4 abre todo; la flecha vuelve al Mapa Estelar.
## Respalda y restaura `user://progreso.json` para no pisar el progreso real de los ninos.
##
## Uso: godot --headless --path . --script herramientas/qa_test_mapa_planeta.gd

const MAPA := "res://escenas/nucleo/mapa_estelar.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
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
	mapa._input(toque)
	await _esperar(0.3)
	_check(current_scene != null and current_scene.scene_file_path == ARCOIRIS, "tocar Arcoiris abre el mapa del planeta (%s)" % str(current_scene.scene_file_path if current_scene else "nada"))


func _probar_estado_inicial() -> void:
	print("-- estado inicial (Maxi) --")
	var mapa := await _abrir_arcoiris()
	_check(mapa.planeta_id == "arcoiris" and mapa.zonas.size() == 5, "5 zonas del Planeta Arcoiris")
	_check(mapa.zonas[0]["abierta"], "zona 1 abierta al llegar")
	var dormidas := true
	for i in range(1, 5):
		dormidas = dormidas and not mapa.zonas[i]["abierta"]
	_check(dormidas, "zonas 2-5 dormidas")
	var estaciones: Array = mapa.zonas[0]["estaciones"]
	_check(estaciones.size() == 4, "4 estaciones por zona")
	_check(estaciones[1]["juego"] == "formas" and estaciones[1]["jugable"], "Formas traviesas jugable en la zona 1")
	_check(not estaciones[0]["jugable"] and not estaciones[3]["jugable"], "Lluvia y Pinta aun sin nivel (se ven 'pintandose')")
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
	mapa._tocar_estacion(0)
	_check(not mapa._lanzando, "tocar una estacion sin nivel no lanza nada")


func _probar_lanzar_y_volver(forma: String) -> void:
	print("-- lanzar Formas traviesas (zona 1) y volver por '%s' --" % forma)
	var mapa := await _abrir_arcoiris()
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
		_check(vuelta.zonas[1]["abierta"], "se despierta la zona 2 (min(2, 1 jugable) = 1)")
		_check(vuelta.seleccion == 1, "el mapa lleva la seleccion a la zona recien abierta")


func _probar_apertura_con_dos_estaciones() -> void:
	print("-- zona 2 de Maxi tiene 2 estaciones jugables: pide las 2 --")
	_progreso.marcar_nivel_completado("maxi", "arcoiris", "arcoiris_z2_formas_semilla", 30, 0)
	var mapa := await _abrir_arcoiris()
	_check(mapa.zonas[1]["jugables"] == 2 and mapa.zonas[1]["completadas"] == 1, "zona 2: 1 de 2 estaciones")
	_check(not mapa.zonas[2]["abierta"], "con 1 de 2, la zona 3 sigue dormida")
	_progreso.marcar_nivel_completado("maxi", "arcoiris", "arcoiris_emparejar_semilla_01", 40, 0)
	mapa = await _abrir_arcoiris()
	_check(mapa.zonas[2]["abierta"], "con 2 de 2, se despierta la zona 3")


func _probar_zona_secreta_sofia() -> void:
	print("-- Sofia: zona secreta y estrellitas --")
	_progreso.perfil_seleccionado = "sofia"
	for n in [1, 2, 3]:
		_progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_z%d_formas_estrella" % n, 50, 3 if n == 1 else 2)
	_progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_emparejar_estrella_01", 50, 2)
	var mapa := await _abrir_arcoiris()
	_check(mapa.zonas[3]["abierta"] and not mapa.zonas[4]["abierta"], "zona 4 abierta, la Cima sigue secreta")
	_check(mapa.zonas[0]["estaciones"][1]["estrellitas"] == 3, "la estacion muestra las mejores estrellitas (3)")
	_progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_z4_formas_estrella", 50, 1)
	mapa = await _abrir_arcoiris()
	_check(mapa.zonas[4]["abierta"], "completar la zona 4 revela la Cima del Arcoiris")
	_check(mapa.seleccion == 4, "el mapa lleva a la zona secreta recien revelada")


func _probar_cometa() -> void:
	print("-- Cometa lleva a la siguiente estacion pendiente --")
	var mapa := await _abrir_arcoiris()
	var destino: Array = mapa.siguiente_estacion()
	_check(destino[0] == 4 and destino[1] == 1, "siguiente pendiente de Sofia: Formas en la Cima (%s)" % str(destino))
	mapa._tocar_cometa()
	await _esperar(1.9)
	var motor := current_scene
	_check(motor is MinijuegoBase and motor.ruta_nivel.ends_with("zona5_cima/formas_estrella.json"), "Cometa abre esa estacion")
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
