extends Node

## Autoload `Progreso` (docs/stack-tecnico.md §2, tarjeta HE-07).
##
## Guarda el perfil de cada hermano (Maxi/Nicole/Sofia), sus destellos, piezas de
## nave y avance por nivel, en un JSON versionado en `user://` (guardado automatico,
## sin preguntar — GDD §3 "Progreso por perfil"). No conoce minijuegos concretos: solo
## guarda/lee datos por `id_perfil` + `planeta_id` + `id_nivel`, todos strings que le
## pasan las escenas de nucleo/minijuegos (contrato de `minijuego_base.gd`).
##
## Guardado versionado desde el dia uno (decision del PO, 18-Jul-2026, stack §7): el
## JSON lleva `version` y `_migrar_datos()` aplica migraciones antes de usar los datos,
## para que agregar planetas/capitulos por actualizacion nunca borre el progreso de
## los ninos. Hoy solo existe v1: el mecanismo queda listo para v2+ sin usarse todavia.

signal progreso_actualizado(id_perfil: String)

const RUTA_GUARDADO := "user://progreso.json"

## Version actual del formato de guardado. Subir este numero + agregar una funcion
## `_migrar_v<N>_a_v<N+1>(datos: Dictionary) -> Dictionary` es todo lo que hace falta
## para introducir un cambio de esquema sin romper partidas viejas.
const VERSION_ACTUAL := 1

const PERFILES_DIFICULTAD := ["semilla", "brote", "estrella"]

## Perfiles por defecto del primer arranque (GDD §2/§5 y docs/perfil-jugadores.md):
## Maxi/semilla (2 años), Nicole/brote (5 años), Sofia/estrella (8 años).
const PERFILES_POR_DEFECTO := [
	{"id": "maxi", "nombre": "Maxi", "perfil_dificultad": "semilla"},
	{"id": "nicole", "nombre": "Nicole", "perfil_dificultad": "brote"},
	{"id": "sofia", "nombre": "Sofia", "perfil_dificultad": "estrella"},
]

## Estado completo, tal cual se persiste (con "version" + "perfiles"). Se carga en
## `_ready()` y se reescribe entero en cada `guardar()` — el archivo es chico
## (3 perfiles, unos pocos niveles cada uno), no hace falta guardado incremental.
var _datos: Dictionary = {}

## Id del hermano que esta jugando ahora ("maxi"/"nicole"/"sofia"), lo fija la
## pantalla de seleccion de personaje (HE-06). No se persiste: el flujo del juego
## siempre pasa por la seleccion de personaje al iniciar (GDD §3), no hace falta
## recordarlo entre sesiones.
var perfil_seleccionado: String = ""


func _ready() -> void:
	cargar()


## Carga `user://progreso.json`. Si no existe (primer arranque) o esta corrupto,
## crea los 3 perfiles por defecto y guarda de inmediato para dejar el archivo listo.
func cargar() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		_datos = _crear_datos_por_defecto()
		guardar()
		return

	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		push_warning("Progreso.cargar: no se pudo abrir %s, uso datos por defecto" % RUTA_GUARDADO)
		_datos = _crear_datos_por_defecto()
		guardar()
		return

	var texto := archivo.get_as_text()
	archivo.close()

	var resultado: Variant = JSON.parse_string(texto)
	if typeof(resultado) != TYPE_DICTIONARY:
		push_warning("Progreso.cargar: JSON invalido en %s, uso datos por defecto" % RUTA_GUARDADO)
		_datos = _crear_datos_por_defecto()
		guardar()
		return

	# Un archivo sin campo "version" tambien cuenta como "necesita resave": puede
	# ser un guardado hecho a mano o de un formato anterior a este mecanismo (stack
	# §7) — nunca debe quedar en disco sin el campo que hace posible migrar despues.
	var tenia_version: bool = resultado.has("version")
	var version_en_disco: int = int(resultado.get("version", 1))
	_datos = _migrar_datos(resultado)
	if not tenia_version or version_en_disco != VERSION_ACTUAL:
		# El archivo en disco quedaba en un esquema viejo (o sin marcar version): se
		# reescribe de inmediato con los datos ya migrados para que la proxima carga
		# no tenga que volver a migrar nada (stack §7: la migracion pasa una sola vez
		# por archivo).
		guardar()
	# Si faltara algun perfil por defecto (p. ej. guardado a mano incompleto durante
	# pruebas), se completa sin pisar lo que ya exista.
	_asegurar_perfiles_por_defecto()


## Escribe `_datos` completo a `user://progreso.json`. Se llama automaticamente desde
## cada metodo que modifica el progreso (GDD §3: "se guarda automaticamente, sin
## preguntar") — no hace falta invocarlo a mano salvo en tests.
func guardar() -> void:
	_datos["version"] = VERSION_ACTUAL
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_error("Progreso.guardar: no se pudo escribir %s" % RUTA_GUARDADO)
		return
	archivo.store_string(JSON.stringify(_datos, "\t"))
	archivo.close()


func _crear_datos_por_defecto() -> Dictionary:
	var perfiles := {}
	for def in PERFILES_POR_DEFECTO:
		perfiles[def["id"]] = _crear_perfil_por_defecto(def["id"], def["nombre"], def["perfil_dificultad"])
	return {
		"version": VERSION_ACTUAL,
		"perfiles": perfiles,
	}


func _crear_perfil_por_defecto(id_perfil: String, nombre: String, perfil_dificultad: String) -> Dictionary:
	return {
		"id": id_perfil,
		"nombre": nombre,
		"perfil_dificultad": perfil_dificultad,
		"destellos_totales": 0,
		"piezas_nave": [],
		"planetas": {},
		# Volumen lineal 0.0-1.0 por bus, recordado por perfil (GDD §6 regla 10; ver
		# TODO en scripts/autoloads/audio.gd — la UI de zona de padres, HE-12, es
		# quien lo va a editar; aca solo vive el dato persistido).
		"volumenes": {"Musica": 1.0, "SFX": 1.0, "Voz": 1.0},
	}


## Si el JSON cargado no trae uno de los 3 perfiles esperados (guardado viejo/manual
## incompleto), lo crea con sus valores por defecto sin tocar los que si existen.
func _asegurar_perfiles_por_defecto() -> void:
	if not _datos.has("perfiles"):
		_datos["perfiles"] = {}
	var perfiles: Dictionary = _datos["perfiles"]
	var cambio := false
	for def in PERFILES_POR_DEFECTO:
		if not perfiles.has(def["id"]):
			perfiles[def["id"]] = _crear_perfil_por_defecto(def["id"], def["nombre"], def["perfil_dificultad"])
			cambio = true
	if cambio:
		guardar()


## Aplica migraciones de esquema en cadena hasta `VERSION_ACTUAL`. Hoy no hay ninguna
## migracion real (solo existe v1): esto documenta el mecanismo para cuando un capitulo
## futuro necesite cambiar el formato sin borrar el progreso ya guardado (stack §7,
## decision del 18-Jul-2026).
func _migrar_datos(datos: Dictionary) -> Dictionary:
	var version_datos: int = int(datos.get("version", 1))

	if version_datos > VERSION_ACTUAL:
		# Guardado de una version futura (p. ej. se abrio con un build viejo por
		# error): no se puede migrar hacia atras, se usa tal cual y se avisa.
		push_warning("Progreso._migrar_datos: version %d es mas nueva que la soportada (%d)" % [version_datos, VERSION_ACTUAL])
		return datos

	# Ejemplo de como se veria una migracion real (queda comentado a proposito):
	# if version_datos == 1:
	#     datos = _migrar_v1_a_v2(datos)
	#     version_datos = 2

	datos["version"] = VERSION_ACTUAL
	return datos


# ---------------------------------------------------------------------------
# Consultas y mutaciones de perfil
# ---------------------------------------------------------------------------

func obtener_ids_perfiles() -> Array:
	return _datos.get("perfiles", {}).keys()


## Copia del diccionario del perfil (id, nombre, perfil_dificultad, destellos, etc.),
## o un diccionario vacio si `id_perfil` no existe.
func obtener_perfil(id_perfil: String) -> Dictionary:
	var perfiles: Dictionary = _datos.get("perfiles", {})
	if not perfiles.has(id_perfil):
		push_warning("Progreso.obtener_perfil: id_perfil desconocido '%s'" % id_perfil)
		return {}
	return perfiles[id_perfil]


func obtener_perfil_dificultad(id_perfil: String) -> String:
	return obtener_perfil(id_perfil).get("perfil_dificultad", "")


## Usado por la zona de padres (HE-12) al reclasificar a un nino de nivel con el
## tiempo (GDD §5: "los ninos crecen, en un año Maxi puede pasar a Brote").
func fijar_perfil_dificultad(id_perfil: String, perfil_dificultad: String) -> void:
	if perfil_dificultad not in PERFILES_DIFICULTAD:
		push_warning("Progreso.fijar_perfil_dificultad: valor invalido '%s'" % perfil_dificultad)
		return
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.fijar_perfil_dificultad: id_perfil desconocido '%s'" % id_perfil)
		return
	_datos["perfiles"][id_perfil]["perfil_dificultad"] = perfil_dificultad
	guardar()
	progreso_actualizado.emit(id_perfil)


## Llamado por la pantalla de seleccion de personaje (HE-06) al tocar un retrato.
func seleccionar_perfil(id_perfil: String) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.seleccionar_perfil: id_perfil desconocido '%s'" % id_perfil)
		return
	perfil_seleccionado = id_perfil


func obtener_destellos_totales(id_perfil: String) -> int:
	return obtener_perfil(id_perfil).get("destellos_totales", 0)


func _datos_planeta(id_perfil: String, planeta_id: String) -> Dictionary:
	var perfil: Dictionary = _datos.get("perfiles", {}).get(id_perfil, {})
	if perfil.is_empty():
		return {}
	if not perfil.has("planetas"):
		perfil["planetas"] = {}
	if not perfil["planetas"].has(planeta_id):
		perfil["planetas"][planeta_id] = {"destellos": 0, "niveles": {}}
	return perfil["planetas"][planeta_id]


func obtener_destellos_planeta(id_perfil: String, planeta_id: String) -> int:
	return _datos_planeta(id_perfil, planeta_id).get("destellos", 0)


## Suma destellos al planeta (y al total del hermano) y guarda de inmediato. Los
## destellos nunca se quitan (GDD §1/§4: "en esta ficha cada minijuego otorga
## destellos de forma generosa y nunca los quita").
func agregar_destellos(id_perfil: String, planeta_id: String, cantidad: int) -> void:
	if cantidad <= 0:
		return
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.agregar_destellos: id_perfil desconocido '%s'" % id_perfil)
		return
	var datos_planeta := _datos_planeta(id_perfil, planeta_id)
	datos_planeta["destellos"] = int(datos_planeta.get("destellos", 0)) + cantidad
	var perfil: Dictionary = _datos["perfiles"][id_perfil]
	perfil["destellos_totales"] = int(perfil.get("destellos_totales", 0)) + cantidad
	guardar()
	progreso_actualizado.emit(id_perfil)


## Registra el resultado de un nivel (`minijuego_base.gd` emite `completado(destellos)`
## con esto ya resuelto por la escena del minijuego) y suma sus destellos. `estrellitas`
## solo aplica al perfil Estrella (0 si el minijuego no puntua, GDD §4/§5).
##
## El destello "garantizado" de un nivel se otorga una sola vez (primera vez que se
## completa): jugar de nuevo un nivel ya completado — GDD §5 "todo desbloqueado entre
## hermanos", cualquiera puede rejugar cualquier nivel sin penalidad — actualiza el
## mejor puntaje de estrellitas pero no vuelve a sumar destellos, para que los
## destellos no se puedan "farmear" repitiendo el mismo nivel (mismo criterio de
## "puntaje no explotable" ya validado en el motor `emparejar`).
func marcar_nivel_completado(id_perfil: String, planeta_id: String, id_nivel: String, destellos: int, estrellitas: int = 0) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.marcar_nivel_completado: id_perfil desconocido '%s'" % id_perfil)
		return
	var datos_planeta := _datos_planeta(id_perfil, planeta_id)
	if not datos_planeta.has("niveles"):
		datos_planeta["niveles"] = {}
	var nivel_previo: Dictionary = datos_planeta["niveles"].get(id_nivel, {})
	var ya_completado: bool = nivel_previo.get("completado", false)
	var estrellitas_previas: int = nivel_previo.get("estrellitas", 0)
	datos_planeta["niveles"][id_nivel] = {
		"completado": true,
		# Se conserva el mejor puntaje logrado, nunca se lo baja en un reintento
		# (GDD §6: "el fracaso nunca castiga").
		"estrellitas": max(estrellitas_previas, estrellitas),
	}
	if ya_completado:
		guardar()
		progreso_actualizado.emit(id_perfil)
	else:
		agregar_destellos(id_perfil, planeta_id, destellos)


func esta_nivel_completado(id_perfil: String, planeta_id: String, id_nivel: String) -> bool:
	var niveles: Dictionary = _datos_planeta(id_perfil, planeta_id).get("niveles", {})
	return niveles.get(id_nivel, {}).get("completado", false)


## Marca que el hermano ya recibio la pieza de nave de ese planeta (escena de
## historia tras juntar todos los destellos del planeta, GDD §3/§4).
func desbloquear_pieza_nave(id_perfil: String, planeta_id: String) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.desbloquear_pieza_nave: id_perfil desconocido '%s'" % id_perfil)
		return
	var perfil: Dictionary = _datos["perfiles"][id_perfil]
	var piezas: Array = perfil.get("piezas_nave", [])
	if planeta_id not in piezas:
		piezas.append(planeta_id)
		perfil["piezas_nave"] = piezas
		guardar()
		progreso_actualizado.emit(id_perfil)


func tiene_pieza_nave(id_perfil: String, planeta_id: String) -> bool:
	return planeta_id in obtener_perfil(id_perfil).get("piezas_nave", [])


# ---------------------------------------------------------------------------
# Volumen por perfil (GDD §6 regla 10; ver TODO en scripts/autoloads/audio.gd)
# ---------------------------------------------------------------------------

func obtener_volumen(id_perfil: String, bus: String) -> float:
	return obtener_perfil(id_perfil).get("volumenes", {}).get(bus, 1.0)


func fijar_volumen(id_perfil: String, bus: String, volumen_lineal: float) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.fijar_volumen: id_perfil desconocido '%s'" % id_perfil)
		return
	var perfil: Dictionary = _datos["perfiles"][id_perfil]
	if not perfil.has("volumenes"):
		perfil["volumenes"] = {}
	perfil["volumenes"][bus] = clampf(volumen_lineal, 0.0, 1.0)
	guardar()
