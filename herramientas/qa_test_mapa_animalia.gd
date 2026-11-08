extends SceneTree

## Arnés QA del mapa del Planeta Animalia (HE-120).
## Verifica: el mapa carga para los tres hermanos con el paisaje de la selva (sin arcoíris), 5 zonas × 4
## estaciones con las escenas y niveles de la convención de la ficha (§9); sin motores o sin niveles el
## mapa no se cae (la estación dice "pronto"); aperturas de zonas iguales a Arcoíris; zona secreta;
## hito de la batalla tras la zona 3 del primer hermano (y sus estados); pieza del ala al completar la
## zona 3; Gran Desfile (se lanza al completar el planeta, se salta con un toque, no se repite y deja a
## Dinito); mapa del equipo sin desfile; y la entrada desde el Mapa Estelar (cerrada sin la partida de
## Arcoíris, abierta con el modo de desarrollo y con el viaje Arcoíris -> Animalia).
##
## Para probar aperturas sin depender de los 4 motores (los hacen otras tarjetas), las estaciones del
## mapa cargado se apuntan EN MEMORIA a niveles de prueba en `user://qa_mapa_animalia/` y a una escena
## de motor existente. Guardado aislado: respalda y restaura `user://progreso_pruebas.json` y comprueba
## que el guardado real (`user://progreso.json`) no cambia.
##
## Uso: godot --headless --path . --script herramientas/qa_test_mapa_animalia.gd

const ANIMALIA := "res://escenas/planetas/animalia/mapa_animalia.tscn"
const MAPA_ESTELAR := "res://escenas/nucleo/mapa_estelar.tscn"
const VIAJE := "res://escenas/nucleo/viaje_estelar.tscn"
const GUARDADO := "user://progreso_pruebas.json"
const REAL := "user://progreso.json"
const CARPETA_NIVELES := "user://qa_mapa_animalia/"
const ESCENA_SUSTITUTA := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const MOTORES := {"quien_habla": "topos", "casa": "caminos", "escondite": "buscar", "carrera": "runner"}
const PERFILES := {"maxi": "semilla", "nicole": "brote", "sofia": "estrella"}

var _fallos := 0
var _oks := 0
var _respaldo = null
var _progreso: Node
var _md5_real := ""


func _initialize() -> void:
	print("=== QA mapa del Planeta Animalia (HE-120) ===")
	_progreso = get_root().get_node("Progreso")
	_md5_real = FileAccess.get_md5(REAL) if FileAccess.file_exists(REAL) else "(no existe)"
	_check(_progreso.ruta_guardado == GUARDADO, "Progreso usa el guardado de pruebas (%s)" % _progreso.ruta_guardado)
	if FileAccess.file_exists(GUARDADO):
		_respaldo = FileAccess.get_file_as_string(GUARDADO)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	_crear_niveles_de_prueba()

	await _probar_datos()
	await _probar_carga_por_perfil()
	await _probar_sin_motores()
	await _probar_aperturas_y_secreta()
	await _probar_batalla_y_pieza()
	await _probar_gran_desfile()
	await _probar_equipo()
	await _probar_mapa_estelar()

	change_scene_to_file(MAPA_ESTELAR)
	await _esperar(0.2)
	_borrar_niveles_de_prueba()
	if _respaldo != null:
		var archivo := FileAccess.open(GUARDADO, FileAccess.WRITE)
		archivo.store_string(_respaldo)
		archivo.close()
		_progreso.cargar()
	var md5_final := FileAccess.get_md5(REAL) if FileAccess.file_exists(REAL) else "(no existe)"
	_check(md5_final == _md5_real, "el guardado real de los niños queda intacto (md5 %s)" % md5_final)
	print("=== RESULTADO: %s (%d OK, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


# ---------------------------------------------------------------------------
# Niveles de prueba (en user://, nunca en datos/)
# ---------------------------------------------------------------------------

func _ruta_prueba(zona: int, juego: String, perfil: String) -> String:
	return CARPETA_NIVELES + "z%d_%s_%s.json" % [zona, MOTORES[juego], PERFILES[perfil]]


func _id_prueba(zona: int, juego: String, perfil: String) -> String:
	return "animalia_z%d_%s_%s" % [zona, MOTORES[juego], PERFILES[perfil]]


func _crear_niveles_de_prueba() -> void:
	DirAccess.make_dir_recursive_absolute(CARPETA_NIVELES)
	for zona in range(1, 6):
		for juego in MOTORES:
			for perfil in PERFILES:
				var archivo := FileAccess.open(_ruta_prueba(zona, juego, perfil), FileAccess.WRITE)
				archivo.store_string(JSON.stringify({"id_nivel": _id_prueba(zona, juego, perfil), "perfil": PERFILES[perfil]}))
				archivo.close()


func _borrar_niveles_de_prueba() -> void:
	for archivo in DirAccess.get_files_at(CARPETA_NIVELES):
		DirAccess.remove_absolute(CARPETA_NIVELES + archivo)
	DirAccess.remove_absolute(CARPETA_NIVELES)


## Abre el mapa y apunta sus estaciones (en memoria) a los niveles de prueba y a una escena existente.
func _abrir(perfil: String, con_prueba := true) -> Node:
	_progreso.perfil_seleccionado = perfil
	change_scene_to_file(ANIMALIA)
	await _esperar(0.3)
	var mapa := current_scene
	if con_prueba and mapa != null:
		_parchar(mapa.mapa)
		mapa._paisaje._mapa = mapa.mapa
		mapa.calcular_estado()
		mapa._refrescar()
	return mapa


func _parchar(datos: Dictionary) -> void:
	for zona: Dictionary in datos.get("zonas", []):
		var numero := int(zona["numero"])
		for estacion: Dictionary in zona["estaciones"]:
			estacion["escena"] = ESCENA_SUSTITUTA
			var niveles := {}
			for perfil in PERFILES:
				niveles[perfil] = _ruta_prueba(numero, str(estacion["juego"]), perfil)
			estacion["niveles"] = niveles
			if estacion.has("niveles_dorados"):
				estacion.erase("niveles_dorados")


func _completar_zona(perfil: String, zona: int) -> void:
	for juego in MOTORES:
		_progreso.marcar_nivel_completado(perfil, "animalia", _id_prueba(zona, juego, perfil), 100, 3)


# ---------------------------------------------------------------------------
# Pruebas
# ---------------------------------------------------------------------------

func _probar_datos() -> void:
	print("-- datos/planetas/animalia/mapa.json --")
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/planetas/animalia/mapa.json"))
	_check(datos is Dictionary, "mapa.json es JSON válido")
	if not datos is Dictionary:
		return
	_check(datos["planeta_id"] == "animalia" and datos["destellos_por_estacion"] == 100.0 and datos["destellos_reto_dorado"] == 0.0, "planeta animalia, 100 destellos por estación y 0 en retos dorados")
	var zonas: Array = datos["zonas"]
	_check(zonas.size() == 5, "5 zonas")
	var ids := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
	var convencion := true
	var equipo := 0
	for i in zonas.size():
		var zona: Dictionary = zonas[i]
		convencion = convencion and zona["id"] == ids[i] and (zona["estaciones"] as Array).size() == 4
		for estacion: Dictionary in zona["estaciones"]:
			var motor: String = MOTORES.get(estacion["juego"], "?")
			convencion = convencion and estacion["escena"] == "res://escenas/minijuegos/%s/motor_%s.tscn" % [motor, motor]
			for perfil in PERFILES:
				convencion = convencion and estacion["niveles"][perfil] == "res://datos/niveles/animalia/%s/%s_%s.json" % [ids[i], motor, PERFILES[perfil]]
			equipo += 1 if estacion.has("nivel_equipo") else 0
	_check(convencion, "4 estaciones por zona con escenas motor_<juego>.tscn y niveles <zona>/<motor>_<perfil>.json (§9)")
	_check(equipo == 5, "nivel_equipo en las 5 estaciones de ¿Quién habla? (v1 de equipo)")
	_check(zonas[4]["secreta"] and not zonas[3]["secreta"], "la zona 5 (Valle de los Dinosaurios) es la secreta")
	var dorados: Array = []
	for estacion: Dictionary in zonas[4]["estaciones"]:
		if estacion.has("niveles_dorados"):
			dorados.append(estacion["juego"])
	_check(dorados == ["casa", "carrera"], "retos dorados de Sofía en Cada quien a su casa y Carrera de la zona 5")
	var batalla: Dictionary = datos["batalla"]
	_check(batalla["id"] == "animalia_batalla_final" and batalla["datos"] == "res://datos/batallas/animalia_final.json" and int(batalla["aparece_tras_zona"]) == 3 and batalla["condicion"] == "primer_hermano", "hito de batalla: animalia_batalla_final tras la zona 3 del primer hermano")
	_check(batalla.has("tras_ganar") and datos.get("viaje_siguiente_requiere", {}).get("partida", "") == "animalia", "bloques de batalla-animalia.md §8.4 (tras_ganar y viaje_siguiente_requiere)")
	_check(datos["pieza_nave"]["id"] == "ala_derecha" and datos["pieza_nave"]["zonas"] == [1.0, 2.0, 3.0], "pieza de la nave: ala derecha en las zonas 1-3")
	_check(ResourceLoader.exists(str(datos["anfitrion"])), "el anfitrión (Toby) existe")


func _probar_carga_por_perfil() -> void:
	for perfil in PERFILES:
		print("-- carga del mapa: %s --" % perfil)
		var mapa := await _abrir(perfil, false)
		_check(mapa != null and mapa.planeta_id == "animalia" and mapa.zonas.size() == 5, "%s: mapa de Animalia con 5 zonas" % perfil)
		if mapa == null:
			continue
		var paisaje: Control = mapa._paisaje
		_check(paisaje != null and paisaje.has_method("dibujar_hito") and paisaje.has_method("dibujar_camino"), "%s: se dibuja con el paisaje de la selva" % perfil)
		_check(not mapa._arcoiris.visible, "%s: sin arcoíris en el cielo" % perfil)
		_check(mapa.zonas[0]["abierta"], "%s: zona 1 abierta al llegar" % perfil)
		_check(mapa._anfitriona.texture != null, "%s: Toby es el anfitrión" % perfil)
		var iconos := true
		for juego in MOTORES:
			iconos = iconos and ResourceLoader.exists("res://assets/sprites/ui/iconos_juegos/animalia_%s.svg" % juego)
		_check(iconos, "%s: iconos de las 4 estaciones" % perfil)
		await _esperar(0.4)
		_check(current_scene == mapa, "%s: el mapa sigue en pantalla tras dibujarse unos cuadros" % perfil)


func _probar_sin_motores() -> void:
	print("-- estaciones sin motor o sin nivel (no se cae) --")
	var mapa := await _abrir("maxi", false)
	var reales := true
	for estacion: Dictionary in mapa.zonas[0]["estaciones"]:
		var existe: bool = ResourceLoader.exists(estacion["escena"]) and FileAccess.file_exists(estacion["ruta_nivel"])
		reales = reales and estacion["jugable"] == existe
	_check(reales, "cada estación es jugable solo si existen su motor y su nivel")
	# Forzar estaciones sin motor: tocar una dice "pronto" y no navega.
	for estacion: Dictionary in mapa.mapa["zonas"][0]["estaciones"]:
		estacion["escena"] = "res://escenas/minijuegos/no_existe/motor_no_existe.tscn"
	mapa.calcular_estado()
	mapa._abrir_burbuja(0)
	mapa._tocar_estacion(0)
	mapa.lanzar_estacion(0, 1)
	await _esperar(1.2)
	_check(current_scene == mapa and not mapa._lanzando, "tocar una estación sin motor no se cae ni sale del mapa")
	mapa._tocar_cometa()
	await _esperar(0.3)
	_check(current_scene == mapa, "Cometa sin estaciones jugables tampoco se cae")


func _probar_aperturas_y_secreta() -> void:
	print("-- aperturas y zona secreta (Nicole) --")
	var mapa := await _abrir("nicole")
	_check(mapa.zonas[0]["jugables"] == 4, "con niveles, las 4 estaciones de la zona 1 son jugables")
	var dormidas := true
	for i in range(1, 5):
		dormidas = dormidas and not mapa.zonas[i]["abierta"]
	_check(dormidas, "zonas 2-5 durmiendo la siesta")
	_check(mapa._nodos_zona[4].get_meta("etiqueta").text == "???", "la zona secreta se ve a lo lejos sin nombre")
	for juego in ["quien_habla", "casa", "escondite"]:
		_progreso.marcar_nivel_completado("nicole", "animalia", _id_prueba(1, juego, "nicole"), 100, 2)
	mapa.calcular_estado()
	_check(not mapa.zonas[1]["abierta"], "3 de 4 estaciones no abren la zona 2")
	_completar_zona("nicole", 1)
	mapa.calcular_estado()
	_check(mapa.zonas[1]["abierta"] and not mapa.zonas[2]["abierta"], "las 4 estaciones de la zona 1 abren la zona 2 (y solo esa)")
	_completar_zona("nicole", 2)
	_completar_zona("nicole", 3)
	mapa.calcular_estado()
	_check(mapa.zonas[3]["abierta"] and not mapa.zonas[4]["abierta"], "zonas 1-3 completas abren la 4; la secreta sigue escondida")
	_completar_zona("nicole", 4)
	mapa = await _abrir("nicole")
	_check(mapa.zonas[4]["abierta"], "completar la zona 4 revela el Valle de los Dinosaurios")
	_check(mapa._nodos_zona[4].get_meta("etiqueta").text == "El Valle de los Dinosaurios", "la zona secreta revelada dice su nombre")
	var siguiente: Array = mapa.siguiente_estacion()
	_check(siguiente[0] == 4, "Cometa lleva al valle (siguiente estación pendiente)")


func _probar_batalla_y_pieza() -> void:
	print("-- hito de la batalla y pieza del ala --")
	var mapa := await _abrir("maxi")
	var paisaje: Control = mapa._paisaje
	_check(paisaje.hito_batalla_visible(), "Nicole ya completó la zona 3: el hito aparece también en el mapa de Maxi (primer hermano)")
	_check(not _progreso.tiene_pieza_nave("maxi", "animalia"), "Maxi todavía no tiene el ala derecha")
	_check(_progreso.tiene_pieza_nave("nicole", "animalia"), "Nicole recibió el ala derecha al ver su zona 3 completa")
	_check(paisaje.estado_hito_batalla() == "mochila" and paisaje._burbujas_batalla == 4, "batalla sin jugar: la mochila-torre con las 4 burbujas")
	paisaje.tocar_hito_batalla()
	await _esperar(0.2)
	_check(current_scene == mapa and paisaje._menear_batalla > 0.0, "tocar el hito responde (late) y no se cae")
	_progreso.registrar_ronda_batalla("animalia_batalla_final", "quien_habla")
	paisaje.actualizar(mapa.zonas)
	_check(paisaje._burbujas_batalla == 3, "cada ronda ganada revienta una burbuja")
	_progreso.registrar_batalla_ganada("animalia_batalla_final", "animalia", ["maxi", "nicole", "sofia"] as Array[String], 0)
	paisaje.actualizar(mapa.zonas)
	_check(paisaje.estado_hito_batalla() == "partida", "batalla ganada: hito de partida (la nave brillando)")
	# Un guardado sin nadie con la zona 3: el hito no está.
	var datos_previos: Dictionary = _progreso._datos.duplicate(true)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_completar_zona("sofia", 1)
	_completar_zona("sofia", 2)
	mapa = await _abrir("sofia")
	_check(not mapa._paisaje.hito_batalla_visible(), "sin nadie con la zona 3 no hay hito de batalla")
	_check(not _progreso.tiene_pieza_nave("sofia", "animalia"), "con 2 zonas todavía no llega el ala")
	_completar_zona("sofia", 3)
	mapa = await _abrir("sofia")
	_check(mapa._paisaje.hito_batalla_visible() and _progreso.tiene_pieza_nave("sofia", "animalia"), "al completar la zona 3 llegan el ala y el hito de la batalla")
	_progreso._datos = datos_previos


func _probar_gran_desfile() -> void:
	print("-- Gran Desfile --")
	_completar_zona("nicole", 5)
	var mapa := await _abrir("nicole")
	var paisaje: Control = mapa._paisaje
	_check(paisaje.desfile_activo(), "con el planeta completo arranca el Gran Desfile")
	_check(paisaje._marcha.size() >= 15 and paisaje._marcha[0]["especie"] in ["trex", "spinosaurio", "carnotauro"] and paisaje._marcha[paisaje._marcha.size() - 1]["especie"] == "toby", "lo encabezan los dinos y Toby va al final")
	await _esperar(0.6)
	_check(paisaje._desfile_lienzo != null and paisaje._desfile_lienzo.mouse_filter == Control.MOUSE_FILTER_STOP, "el desfile tapa el mapa mientras dura (un toque lo salta)")
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	paisaje._desfile_lienzo.gui_input.emit(toque)
	_check(not paisaje.desfile_activo() and paisaje._dinito_vive, "un toque salta el desfile y Dinito queda en el campamento")
	_check(_progreso.especial_conocido("nicole", "animalia_gran_desfile"), "el desfile queda marcado como visto para Nicole")
	mapa = await _abrir("nicole")
	_check(not mapa._paisaje.desfile_activo() and mapa._paisaje._dinito_vive, "volver al mapa no repite el desfile; Dinito sigue ahí")
	# Sofía lo ve entero (~12 s): se avanza el reloj.
	for zona in range(1, 6):
		_completar_zona("sofia", zona)
	mapa = await _abrir("sofia")
	paisaje = mapa._paisaje
	_check(paisaje.desfile_activo(), "Sofía tiene su propio Gran Desfile")
	paisaje._avanzar_desfile(paisaje.DURACION_DESFILE + 0.1)
	_check(not paisaje.desfile_activo() and _progreso.especial_conocido("sofia", "animalia_gran_desfile"), "a los ~12 s el desfile termina solo y se marca")
	_check(not _progreso.especial_conocido("maxi", "animalia_gran_desfile"), "el desfile es de cada hermano (Maxi no lo vio)")
	_check(paisaje._gemas.size() == 5, "Sofía con 3 estrellitas en todo: 5 gemas en el collar")


func _probar_equipo() -> void:
	print("-- mapa del equipo --")
	_progreso.equipo_activo = ["maxi", "nicole"] as Array[String]
	var mapa := await _abrir("maxi", false)
	var abiertas := true
	for zona: Dictionary in mapa.zonas:
		abiertas = abiertas and zona["abierta"]
	_check(mapa.modo_equipo and abiertas, "en equipo todas las zonas están abiertas")
	_check(not mapa._paisaje.desfile_activo(), "en equipo no hay Gran Desfile")
	_check(mapa._paisaje._dinito_vive, "en equipo Dinito vive porque un hermano ya vio su desfile")
	_progreso.equipo_activo = [] as Array[String]


func _probar_mapa_estelar() -> void:
	print("-- entrada desde el Mapa Estelar --")
	_progreso.perfil_seleccionado = "maxi"
	var Estelar: Script = load("res://scripts/nucleo/mapa_estelar.gd")
	Estelar.abrir_planetas_dev = false
	change_scene_to_file(MAPA_ESTELAR)
	await _esperar(0.3)
	var estelar := current_scene
	_check(estelar.planetas_desbloqueados() == 1, "sin la partida de Arcoíris (HE-81/82) Animalia sigue lejana")
	var animalia: Dictionary = estelar.PLANETAS[1]
	# HE-82 (M9 de motor-lanzar §13.4): Animalia cerrada SI responde al toque (latido, voz, flechita), pero
	# nunca abre nada ni lanza el viaje. El detalle lo cubre qa_test_partida_viaje.gd.
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = animalia["pos"]
	estelar._input(toque)
	await _esperar(0.9)
	_check(current_scene == estelar, "tocar Animalia cerrada solo late: no viaja ni abre nada")
	Estelar.abrir_planetas_dev = true
	change_scene_to_file(MAPA_ESTELAR)
	await _esperar(0.3)
	estelar = current_scene
	_check(estelar.planetas_desbloqueados() == 2, "modo de desarrollo (F6 / abrir_planetas): Animalia abierta")
	_progreso.fijar_ubicacion_nave("maxi", "arcoiris")
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = animalia["pos"]
	estelar._input(toque)
	await _esperar(0.9)
	var viaje := current_scene
	_check(viaje != null and viaje.scene_file_path == VIAJE and viaje.planeta_origen == "arcoiris" and viaje.planeta_destino == "animalia", "tocar Animalia lanza el viaje Arcoíris -> Animalia")
	if viaje != null and viaje.scene_file_path == VIAJE:
		viaje.completado.emit(2)
		await _esperar(0.4)
		_check(current_scene != null and current_scene.scene_file_path == ANIMALIA, "al aterrizar se abre el mapa de Animalia")
		_check(_progreso.obtener_ubicacion_nave("maxi") == "animalia", "la nave queda estacionada en Animalia")
	Estelar.abrir_planetas_dev = false
