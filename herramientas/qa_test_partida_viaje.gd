extends SceneTree

## Arnes QA de HE-81 (estado familiar de la partida en `Progreso`) y HE-82 (viaje al planeta siguiente por
## datos en el Mapa Estelar). Fuentes: motor-lanzar.md §13.4 y §20, batalla-animalia.md §8.3, cierre_arcoiris.md
## §16.2-§16.3.
##
## Cubre: (1) migracion: guardados v3 sin `partidas`/`rumbos` (o con partidas a medio formar) y v2 se completan
## al cargar sin perder nada, una sola vez; una version futura no se toca. (2) API: pasos idempotentes y retomar
## en el primer pendiente, un ala + batalla ganada abre la partida, `completar_partida`, la llave de padres
## (`forzar_partida`) sin consumir la ceremonia, hito de 3 estados, partidas de otros planetas intactas y nada
## por hermano. (3) Mapa Estelar: sin partida, Animalia es el destino en espera (late en el mismo toque, voz una
## vez por visita alternada, flechita) y no se viaja; con la partida (ceremonia o llave) viaja CUALQUIER hermano;
## la nave dibuja el ala puesta o envuelta; Melodia espera la partida de Animalia.
##
## Guardado AISLADO (`user://progreso_pruebas_he81.json`): no toca el real ni el de los otros arneses.
## Uso: godot --headless --path . --script herramientas/qa_test_partida_viaje.gd

const RUTA := "user://progreso_pruebas_he81.json"
const MAPA := "res://escenas/nucleo/mapa_estelar.tscn"
const VIAJE := "res://escenas/nucleo/viaje_estelar.tscn"
const ORDEN_PASOS := ["tanque", "ala", "ruta", "despedida", "llamada"]
const BATALLA := "arcoiris_batalla_final"

var _fallos := 0
var _progreso: Node
var _ruta_previa := ""


func _initialize() -> void:
	print("=== QA HE-81/HE-82: partida familiar y viaje por datos ===")
	_progreso = get_root().get_node("Progreso")
	_ruta_previa = _progreso.ruta_guardado
	_progreso.ruta_guardado = RUTA

	_probar_migracion()
	_probar_api()
	await _probar_mapa_estelar()

	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	_progreso.ruta_guardado = _ruta_previa
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


func _escribir(datos: Dictionary) -> void:
	var archivo := FileAccess.open(RUTA, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()


func _leer_disco() -> Dictionary:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	return datos if datos is Dictionary else {}


func _perfil(id: String, destellos: int, piezas: Array) -> Dictionary:
	return {"id": id, "nombre": id.capitalize(), "perfil_dificultad": "semilla", "destellos_totales": destellos,
		"piezas_nave": piezas, "especiales_conocidos": [],
		"planetas": {"arcoiris": {"destellos": destellos, "niveles": {"n1": {"completado": true, "estrellitas": 2}},
			"coleccion": [], "equipo_premiado": []}},
		"volumenes": {"Musica": 1.0, "SFX": 1.0, "Voz": 1.0}}


func _guardado_v3_sin_partidas() -> Dictionary:
	return {"version": 3,
		"perfiles": {"maxi": _perfil("maxi", 300, ["arcoiris"]), "nicole": _perfil("nicole", 200, []),
			"sofia": _perfil("sofia", 100, [])},
		"recuerdos_encontrados": {"r1": {"fecha": "x", "visto": true, "dorado": false, "quien": "maxi"}},
		"equipo": {"presentado": true, "trucos_presentados": ["a"], "cinematicas_vistas": ["arcoiris_batalla_final:entrada"],
			"planetas": {"arcoiris": {"ganados": ["e1"], "records": {}}},
			"batallas": {BATALLA: {"rondas_ganadas": ["rojo"], "epilogo": false, "ganada": false, "premiados": [], "parcial": {}}}}}


# --- 1) Migracion ---------------------------------------------------------------------------------------

func _probar_migracion() -> void:
	print("-- 1) migracion de guardados existentes --")
	var viejo := _guardado_v3_sin_partidas()
	_escribir(viejo)
	_progreso.cargar()
	var disco := _leer_disco()
	_check(disco.get("version", -1) == 3, "sigue en version 3 (la ficha pide no subir version)")
	_check(disco["equipo"].get("partidas", null) is Dictionary and (disco["equipo"]["partidas"] as Dictionary).is_empty(),
		"v3 sin partidas: el archivo queda con equipo.partidas = {}")
	_check(disco["equipo"].get("rumbos", null) is Array and (disco["equipo"]["rumbos"] as Array).is_empty(),
		"v3 sin rumbos: el archivo queda con equipo.rumbos = []")
	_check(_progreso.obtener_destellos_totales("maxi") == 300 and _progreso.tiene_pieza_nave("maxi", "arcoiris"),
		"destellos y pieza de Maxi intactos")
	_check(_progreso.esta_nivel_completado("nicole", "arcoiris", "n1") and _progreso.tiene_recuerdo("r1"),
		"niveles y recuerdos intactos")
	_check(_progreso.obtener_rondas_batalla(BATALLA) == ["rojo"] and _progreso.cinematica_vista("arcoiris_batalla_final:entrada"),
		"rondas de batalla y cinematicas vistas intactas")
	_check(not _progreso.partida_hecha("arcoiris") and _progreso.rumbos().is_empty(), "sin partida ni rumbos tras migrar")
	# idempotente: una segunda carga no reescribe nada
	var texto_1 := FileAccess.get_file_as_string(RUTA)
	_progreso.cargar()
	_check(FileAccess.get_file_as_string(RUTA) == texto_1, "la segunda carga no cambia el archivo (la migracion pasa una vez)")

	# partidas a medio formar (guardado a mano o de una prueba): se completan sin perder lo guardado
	var medio := _guardado_v3_sin_partidas()
	medio["equipo"]["partidas"] = {"arcoiris": {"hecha": true, "pasos": ["tanque"]}, "animalia": "basura"}
	medio["equipo"]["rumbos"] = ["arcoiris>animalia"]
	_escribir(medio)
	_progreso.cargar()
	var partida: Dictionary = _leer_disco()["equipo"]["partidas"]["arcoiris"]
	_check(partida.get("hecha") == true and partida.get("pasos") == ["tanque"] and partida.get("ceremonia") == false
		and partida.get("forzada") == false, "partida incompleta: conserva hecha y pasos y suma ceremonia/forzada en false")
	_check(_leer_disco()["equipo"]["partidas"]["animalia"] is Dictionary and not _progreso.partida_hecha("animalia"),
		"partida con tipo invalido se repara a vacia")
	_check(_progreso.rumbo_encendido("arcoiris>animalia"), "rumbos guardados intactos")

	# v2 (sin bloque equipo): la cadena v2 -> v3 ya trae partidas y rumbos
	var v2 := _guardado_v3_sin_partidas()
	v2["version"] = 2
	v2.erase("equipo")
	_escribir(v2)
	_progreso.cargar()
	disco = _leer_disco()
	_check(disco.get("version") == 3 and disco["equipo"].get("partidas", null) is Dictionary and disco["equipo"].get("rumbos", null) is Array,
		"v2 migra a v3 con partidas y rumbos")
	_check(_progreso.obtener_destellos_totales("nicole") == 200, "v2: destellos de Nicole intactos")

	# version futura: no se completa ni se reescribe
	var futuro := _guardado_v3_sin_partidas()
	futuro["version"] = 99
	_escribir(futuro)
	var texto_futuro := FileAccess.get_file_as_string(RUTA)
	_progreso.cargar()
	_check(FileAccess.get_file_as_string(RUTA) == texto_futuro, "un guardado de version futura no se toca en disco")


# --- 2) API -----------------------------------------------------------------------------------------------

func _probar_api() -> void:
	print("-- 2) API de partidas y rumbos --")
	_escribir(_guardado_v3_sin_partidas())
	_progreso.cargar()
	var perfiles_antes := ""

	_check(_progreso.estado_hito_batalla(BATALLA, "arcoiris") == "mochila", "hito: batalla sin ganar -> mochila")
	_check(not _progreso.partida_disponible("arcoiris", BATALLA), "sin batalla ganada no hay partida")
	var ids: Array[String] = ["maxi", "nicole", "sofia"]
	_progreso.registrar_batalla_ganada(BATALLA, "arcoiris", ids, 0)
	_check(_progreso.alguien_tiene_pieza_nave("arcoiris"), "Maxi tiene el ala (el unico)")
	_check(_progreso.partida_disponible("arcoiris", BATALLA), "un ala + batalla ganada abre la partida")
	_check(_progreso.estado_hito_batalla(BATALLA, "arcoiris") == "partida", "hito: ganada sin ceremonia -> partida")

	var avisos := []
	_progreso.partida_actualizada.connect(func(p): avisos.append(p))
	_progreso.marcar_paso_partida("arcoiris", "tanque")
	_progreso.marcar_paso_partida("arcoiris", "tanque")
	_progreso.marcar_paso_partida("arcoiris", "ala")
	_check(_progreso.pasos_partida("arcoiris") == ["tanque", "ala"], "pasos guardados sin duplicar")
	_check(avisos.size() == 2, "partida_actualizada solo cuando cambia (%d)" % avisos.size())
	_check(_progreso.primer_paso_pendiente("arcoiris", ORDEN_PASOS) == "ruta", "retomar en el primer paso pendiente (ruta)")
	_check(_leer_disco()["equipo"]["partidas"]["arcoiris"]["pasos"] == ["tanque", "ala"], "cada paso queda en disco")
	_check(not _progreso.partida_hecha("arcoiris"), "con pasos a medias la partida no esta hecha")
	_check(not _progreso.partida_hecha("animalia") and not _leer_disco()["equipo"]["partidas"].has("animalia"),
		"consultar otro planeta no crea entradas en el guardado")

	for paso in ["ruta", "despedida", "llamada"]:
		_progreso.marcar_paso_partida("arcoiris", paso)
	_check(_progreso.primer_paso_pendiente("arcoiris", ORDEN_PASOS) == "", "todos los pasos hechos -> sin pendiente")
	_check(not _progreso.rumbo_encendido("arcoiris>animalia"), "antes de completar, el rumbo esta apagado")
	_progreso.completar_partida("arcoiris", "arcoiris>animalia")
	_check(_progreso.partida_hecha("arcoiris") and _progreso.ceremonia_hecha("arcoiris") and not _progreso.partida_forzada("arcoiris"),
		"completar_partida: hecha y ceremonia, sin forzada")
	_check(_progreso.rumbos() == ["arcoiris>animalia"], "completar_partida enciende el rumbo")
	_progreso.completar_partida("arcoiris", "arcoiris>animalia")
	_check(_progreso.rumbos().size() == 1, "completar dos veces no duplica el rumbo")
	_check(_progreso.estado_hito_batalla(BATALLA, "arcoiris") == "revancha", "hito: ceremonia vista -> revancha")
	_check(not _progreso.partida_disponible("arcoiris", BATALLA), "la ceremonia se ve una sola vez")
	_progreso.forzar_partida("arcoiris", "arcoiris>animalia")
	_check(not _progreso.partida_forzada("arcoiris"), "la llave sobre una partida ya hecha no cambia nada")

	# la llave en otro planeta: sin batalla ni ceremonia; Arcoiris queda intacto
	var arcoiris_antes: Dictionary = _progreso.obtener_partida("arcoiris")
	_progreso.forzar_partida("animalia", "animalia>melodia")
	_check(_progreso.partida_hecha("animalia") and _progreso.partida_forzada("animalia") and not _progreso.ceremonia_hecha("animalia"),
		"forzar_partida: hecha y forzada, ceremonia pendiente")
	_check(_progreso.rumbo_encendido("animalia>melodia"), "la llave enciende el rumbo")
	_check(_progreso.obtener_partida("arcoiris") == arcoiris_antes, "la partida de Arcoiris queda intacta")
	_check(_progreso.estado_hito_batalla("animalia_batalla_final", "animalia") == "mochila",
		"tras la llave, sin batalla ganada el hito sigue en mochila")
	_progreso.desbloquear_pieza_nave("sofia", "animalia")
	var dos: Array[String] = ["nicole", "sofia"]
	_progreso.registrar_batalla_ganada("animalia_batalla_final", "animalia", dos, 0)
	# desde aca solo se toca la partida: los perfiles no deben cambiar
	perfiles_antes = JSON.stringify(_leer_disco()["perfiles"])
	_check(_progreso.estado_hito_batalla("animalia_batalla_final", "animalia") == "partida",
		"tras la llave + batalla ganada (con dos), la ceremonia se ofrece una vez")
	_check(_progreso.partida_disponible("animalia", "animalia_batalla_final"), "partida disponible tras la llave")
	_check(not _progreso.rumbo_encendido("x>y") and _progreso.rumbos().size() == 2, "rumbos: 2 encendidos")
	_progreso.completar_partida("animalia", "animalia>melodia")
	_check(_progreso.ceremonia_hecha("animalia") and _progreso.partida_forzada("animalia") and _progreso.rumbos().size() == 2,
		"ceremonia despues de la llave: ceremonia true, forzada queda como historia, sin rumbo nuevo")
	_check(JSON.stringify(_leer_disco()["perfiles"]) == perfiles_antes, "nada por hermano: los perfiles no cambian con la partida")
	_progreso.cargar()
	_check(_progreso.partida_hecha("arcoiris") and _progreso.ceremonia_hecha("animalia") and _progreso.rumbos().size() == 2,
		"todo sobrevive a recargar desde disco")


# --- 3) Mapa Estelar --------------------------------------------------------------------------------------

func _toque(pos: Vector2) -> InputEventMouseButton:
	var t := InputEventMouseButton.new()
	t.button_index = MOUSE_BUTTON_LEFT
	t.pressed = true
	t.position = pos
	return t


func _abrir_mapa(perfil: String) -> Node:
	_progreso.perfil_seleccionado = perfil
	change_scene_to_file(MAPA)
	await _esperar(0.25)
	return current_scene


func _probar_mapa_estelar() -> void:
	print("-- 3) Mapa Estelar --")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	_progreso.desbloquear_pieza_nave("maxi", "arcoiris")
	var mapa := await _abrir_mapa("maxi")
	var pos_animalia: Vector2 = mapa.PLANETAS[1]["pos"]
	_check(mapa.planetas_desbloqueados() == 1, "sin partida solo Arcoiris esta abierto")
	_check(mapa.indice_destino_en_espera() == 1, "Animalia es el destino en espera (M9)")
	var piezas: Node = mapa.get_node_or_null("nave/forma_nave/piezas_nave")
	_check(piezas != null and piezas.get_meta("envueltas") == ["ala_izquierda"] and (piezas.get_meta("puestas") as Array).is_empty(),
		"Maxi (con el ala, sin partida) ve el ala envuelta junto a la nave")
	var nodo_animalia: Node2D = mapa._nodos_planeta["animalia"]
	mapa._input(_toque(pos_animalia))
	_check(nodo_animalia.scale.x > 1.07, "tocar Animalia late en el mismo frame (escala %.2f)" % nodo_animalia.scale.x)
	_check(mapa._voz_espera_dicha and mapa._indice_voz_espera == 1, "suena una voz de voz_destino_espera")
	_check(mapa._flechita != null and is_instance_valid(mapa._flechita), "aparece la flechita de luz hacia Arcoiris")
	await _esperar(0.35)
	mapa._input(_toque(pos_animalia))
	_check(mapa._indice_voz_espera == 1, "el segundo toque de la visita solo late (sin otra voz)")
	await _esperar(0.3)
	_check(current_scene == mapa, "tocar Animalia antes de la partida no viaja ni abre nada")
	# Melodia (lejana, sin destino en espera) tambien responde con el latido
	var nodo_melodia: Node2D = mapa._nodos_planeta["melodia"]
	mapa._input(_toque(mapa.PLANETAS[2]["pos"]))
	_check(nodo_melodia.scale.x > 1.07 and mapa._indice_voz_espera == 1, "un planeta lejano cualquiera late, sin voz")

	# otra visita: la voz alterna
	mapa = await _abrir_mapa("nicole")
	_check(mapa.get_node("nave/forma_nave/piezas_nave").get_meta("envueltas") == [], "Nicole (sin ala) no ve el ala envuelta")
	mapa._input(_toque(pos_animalia))
	_check(mapa._indice_voz_espera == 2, "en la visita siguiente suena la otra variante")

	# con la partida (ceremonia): viaja CUALQUIER hermano, tenga o no el ala
	_progreso.completar_partida("arcoiris", "arcoiris>animalia")
	for perfil in ["maxi", "nicole", "sofia"]:
		mapa = await _abrir_mapa(perfil)
		_check(mapa.planetas_desbloqueados() == 2 and mapa.indice_destino_en_espera() == 2,
			"%s: con la partida, Animalia abierta y Melodia en espera de la de Animalia" % perfil)
		_check(mapa.get_node("nave/forma_nave/piezas_nave").get_meta("puestas") == ["ala_izquierda"],
			"%s: la nave se dibuja con el ala puesta" % perfil)
		mapa._input(_toque(pos_animalia))
		await _esperar(0.9)
		var viaje := current_scene
		_check(viaje != null and viaje.scene_file_path == VIAJE and viaje.planeta_destino == "animalia",
			"%s: tocar Animalia lanza el viaje a Animalia" % perfil)

	# con la llave de padres (sin batalla ni ceremonia) tambien se viaja
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	_progreso.forzar_partida("arcoiris", "arcoiris>animalia")
	mapa = await _abrir_mapa("sofia")
	_check(mapa.planetas_desbloqueados() == 2, "con la llave de padres Animalia queda abierta")
	_check(_progreso.partida_disponible("arcoiris", BATALLA) == false and not _progreso.ceremonia_hecha("arcoiris"),
		"la llave no consume la ceremonia (sigue pendiente, sin batalla no se ofrece)")
	mapa._input(_toque(pos_animalia))
	await _esperar(0.9)
	_check(current_scene != null and current_scene.scene_file_path == VIAJE, "con la llave, Sofia viaja a Animalia")
	# la partida de Animalia (llave) no abre Melodia: todavia no tiene mapa
	_progreso.forzar_partida("animalia", "animalia>melodia")
	mapa = await _abrir_mapa("maxi")
	_check(mapa.planetas_desbloqueados() == 2 and mapa.indice_destino_en_espera() == -1,
		"Melodia sin contenido sigue lejana (sin destino en espera) aunque se cumpla la partida de Animalia")
	change_scene_to_file(MAPA)
	await _esperar(0.2)
