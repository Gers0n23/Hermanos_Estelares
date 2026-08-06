extends SceneTree

## Arnes de QA headless para el autoload `Progreso` (HE-07, mismo patron que
## `qa_test_titulo.gd`/`qa_test_emparejar.gd`). Corre contra el autoload real (ya
## cargado por el motor via `project.godot` al arrancar el SceneTree), y contra
## `user://progreso.json` real de este proyecto — hace backup del archivo si ya
## existia y lo restaura al final para no pisar progreso real de otra sesion.
##
## Cubre: (1) creacion de los 3 perfiles por defecto en el primer arranque, (2)
## mutaciones (destellos, nivel completado, pieza de nave, volumen) + guardado
## automatico verificado releyendo el archivo, (3) JSON corrupto cae a defaults sin
## explotar, (4) migracion: un JSON "viejo" sin campo `version` se migra a
## VERSION_ACTUAL al cargar sin perder sus datos.
##
## Uso: godot --headless --path . --script herramientas/qa_test_progreso.gd

const RUTA := "user://progreso.json"
const RUTA_BACKUP := "user://progreso_backup_qa.json"

var _fallas := 0

## Referencia al autoload real, obtenida via /root en vez del identificador global
## `Progreso` (los scripts en `herramientas/` estan `.gdignore`d, asi que el
## identificador global del autoload no queda resuelto en tiempo de parseo aqui —
## mismo motivo por el que `qa_test_titulo.gd` carga la escena con `load()` en vez
## de referenciarla como constante precargada).
var _progreso: Node


func _initialize() -> void:
	print("=== QA Progreso: iniciando (user_dir=%s) ===" % OS.get_user_data_dir())

	# Los autoloads (Progreso, Audio) ya corrieron su _ready() antes de _initialize()
	# de este SceneTree script (mismo orden documentado para Audio en qa_test_titulo.gd).
	_progreso = get_root().get_node("Progreso")
	_hacer_backup_si_existe()

	_probar_defaults_primer_arranque()
	_probar_mutaciones_y_persistencia()
	_probar_json_corrupto()
	_probar_migracion()

	_restaurar_backup()

	print("=== FIN qa_test_progreso (%s, fallas=%d) ===" % ["OK" if _fallas == 0 else "FALLO", _fallas])
	quit(0 if _fallas == 0 else 1)


func _assert(cond: bool, mensaje: String) -> void:
	if cond:
		print("  OK: %s" % mensaje)
	else:
		_fallas += 1
		print("  FALLA: %s" % mensaje)


func _hacer_backup_si_existe() -> void:
	if FileAccess.file_exists(RUTA):
		var origen := FileAccess.open(RUTA, FileAccess.READ)
		var texto := origen.get_as_text()
		origen.close()
		var destino := FileAccess.open(RUTA_BACKUP, FileAccess.WRITE)
		destino.store_string(texto)
		destino.close()
		print("-- Backup de progreso.json existente guardado en progreso_backup_qa.json --")
	else:
		print("-- No habia progreso.json previo, no hace falta backup --")


func _restaurar_backup() -> void:
	if FileAccess.file_exists(RUTA_BACKUP):
		var origen := FileAccess.open(RUTA_BACKUP, FileAccess.READ)
		var texto := origen.get_as_text()
		origen.close()
		var destino := FileAccess.open(RUTA, FileAccess.WRITE)
		destino.store_string(texto)
		destino.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_BACKUP))
		print("-- progreso.json original restaurado, backup eliminado --")
	else:
		# No habia archivo original: se borra el que genero el test para dejar
		# el user:// limpio como estaba.
		if FileAccess.file_exists(RUTA):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
		print("-- No habia backup (no existia archivo original), progreso.json de prueba eliminado --")


## --- 1) Sin archivo -> se crean los 3 perfiles por defecto (semilla/brote/estrella). ---
func _probar_defaults_primer_arranque() -> void:
	print("-- Prueba 1: defaults en primer arranque --")
	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	_progreso.cargar()

	var ids: Array = _progreso.obtener_ids_perfiles()
	_assert(ids.size() == 3, "hay 3 perfiles (encontrados: %s)" % [ids])
	_assert("maxi" in ids and "nicole" in ids and "sofia" in ids, "perfiles esperados presentes: %s" % [ids])
	_assert(_progreso.obtener_perfil_dificultad("maxi") == "semilla", "Maxi es perfil semilla")
	_assert(_progreso.obtener_perfil_dificultad("nicole") == "brote", "Nicole es perfil brote")
	_assert(_progreso.obtener_perfil_dificultad("sofia") == "estrella", "Sofia es perfil estrella")
	_assert(_progreso.obtener_destellos_totales("maxi") == 0, "Maxi arranca con 0 destellos")
	_assert(FileAccess.file_exists(RUTA), "el archivo user://progreso.json quedo creado en disco")


## --- 2) Mutaciones + guardado automatico, verificado releyendo el archivo. ---
func _probar_mutaciones_y_persistencia() -> void:
	print("-- Prueba 2: mutaciones y guardado automatico --")

	_progreso.seleccionar_perfil("sofia")
	_assert(_progreso.perfil_seleccionado == "sofia", "seleccionar_perfil fija el perfil activo")

	_progreso.agregar_destellos("sofia", "arcoiris", 3)
	_assert(_progreso.obtener_destellos_planeta("sofia", "arcoiris") == 3, "destellos del planeta arcoiris = 3")
	_assert(_progreso.obtener_destellos_totales("sofia") == 3, "destellos_totales de Sofia = 3")

	_progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_lluvia_estrella_01", 1, 3)
	_assert(_progreso.esta_nivel_completado("sofia", "arcoiris", "arcoiris_lluvia_estrella_01"), "nivel de lluvia de colores queda marcado completado")
	_assert(_progreso.obtener_destellos_totales("sofia") == 4, "destellos_totales sube a 4 tras marcar el nivel (3+1)")

	# Reintentar el mismo nivel con MENOS estrellitas no debe bajar el puntaje guardado
	# (GDD §6: el fracaso nunca castiga, y un reintento tampoco debe hacerlo).
	_progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_lluvia_estrella_01", 1, 1)
	var perfil_sofia: Dictionary = _progreso.obtener_perfil("sofia")
	var estrellitas: int = perfil_sofia["planetas"]["arcoiris"]["niveles"]["arcoiris_lluvia_estrella_01"]["estrellitas"]
	_assert(estrellitas == 3, "reintentar con menos estrellitas (1) no baja el mejor puntaje guardado (sigue 3), fue: %d" % estrellitas)

	_progreso.desbloquear_pieza_nave("sofia", "arcoiris")
	_assert(_progreso.tiene_pieza_nave("sofia", "arcoiris"), "pieza de nave de arcoiris desbloqueada para Sofia")
	# Llamarlo dos veces no debe duplicar la pieza en el array.
	_progreso.desbloquear_pieza_nave("sofia", "arcoiris")
	var piezas: Array = _progreso.obtener_perfil("sofia")["piezas_nave"]
	_assert(piezas.count("arcoiris") == 1, "desbloquear_pieza_nave es idempotente (no duplica), count=%d" % piezas.count("arcoiris"))

	_progreso.fijar_volumen("nicole", "Musica", 0.4)
	_assert(is_equal_approx(_progreso.obtener_volumen("nicole", "Musica"), 0.4), "volumen de Musica de Nicole persistido en 0.4")

	# Ahora releemos el archivo desde disco (fuerza _ready-like `cargar()` de nuevo)
	# para confirmar que el guardado automatico si escribio a user://, no solo en RAM.
	_progreso.cargar()
	_assert(_progreso.obtener_destellos_totales("sofia") == 4, "tras recargar desde disco, destellos_totales de Sofia sigue en 4")
	_assert(_progreso.tiene_pieza_nave("sofia", "arcoiris"), "tras recargar desde disco, Sofia sigue con la pieza de arcoiris")
	_assert(is_equal_approx(_progreso.obtener_volumen("nicole", "Musica"), 0.4), "tras recargar desde disco, volumen de Nicole sigue en 0.4")
	# perfil_seleccionado es estado en RAM, no persistido (el flujo siempre repasa la
	# pantalla de seleccion) — tras `cargar()` de nuevo deberia seguir igual porque
	# `cargar()` no lo toca.
	_assert(_progreso.perfil_seleccionado == "sofia", "perfil_seleccionado (estado en RAM) no se pierde con un recargo de datos")


## --- 3) JSON corrupto en disco -> no truena, cae a defaults y reescribe el archivo. ---
func _probar_json_corrupto() -> void:
	print("-- Prueba 3: JSON corrupto cae a defaults sin explotar --")
	var archivo := FileAccess.open(RUTA, FileAccess.WRITE)
	archivo.store_string("{ esto no es json valido ,,, ")
	archivo.close()

	_progreso.cargar()
	var ids: Array = _progreso.obtener_ids_perfiles()
	_assert(ids.size() == 3, "JSON corrupto: se recupera con 3 perfiles por defecto")
	_assert(_progreso.obtener_destellos_totales("sofia") == 0, "JSON corrupto: destellos de Sofia vuelven a 0 (defaults nuevos)")


## --- 4) Migracion: JSON "viejo" sin campo version se migra a VERSION_ACTUAL al cargar,
## sin perder los datos que ya traia (mecanismo pedido por stack §7, aunque hoy solo
## exista v1 real). ---
func _probar_migracion() -> void:
	print("-- Prueba 4: migracion de un guardado sin campo 'version' --")
	var datos_viejos := {
		"perfiles": {
			"maxi": {
				"id": "maxi", "nombre": "Maxi", "perfil_dificultad": "semilla",
				"destellos_totales": 7, "piezas_nave": ["arcoiris"],
				"planetas": {}, "volumenes": {"Musica": 1.0, "SFX": 1.0, "Voz": 1.0},
			},
			"nicole": {
				"id": "nicole", "nombre": "Nicole", "perfil_dificultad": "brote",
				"destellos_totales": 0, "piezas_nave": [],
				"planetas": {}, "volumenes": {"Musica": 1.0, "SFX": 1.0, "Voz": 1.0},
			},
			"sofia": {
				"id": "sofia", "nombre": "Sofia", "perfil_dificultad": "estrella",
				"destellos_totales": 0, "piezas_nave": [],
				"planetas": {}, "volumenes": {"Musica": 1.0, "SFX": 1.0, "Voz": 1.0},
			},
		},
		# deliberadamente SIN "version", simulando un guardado anterior al mecanismo
	}
	var archivo := FileAccess.open(RUTA, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(datos_viejos))
	archivo.close()

	_progreso.cargar()
	_assert(_progreso.obtener_destellos_totales("maxi") == 7, "datos viejos (7 destellos de Maxi) sobreviven a la migracion")
	_assert(_progreso.tiene_pieza_nave("maxi", "arcoiris"), "pieza de nave de Maxi sobrevive a la migracion")

	# Releer el archivo crudo para confirmar que `version` quedo escrito tras guardar.
	var leido := FileAccess.open(RUTA, FileAccess.READ)
	var texto := leido.get_as_text()
	leido.close()
	var json: Dictionary = JSON.parse_string(texto)
	_assert(json.get("version", -1) == _progreso.VERSION_ACTUAL, "el archivo en disco quedo con version=%d tras migrar/guardar (leido: %s)" % [_progreso.VERSION_ACTUAL, json.get("version", -1)])
