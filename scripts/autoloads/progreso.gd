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
## los ninos. v2 (27-Sep-2026, album "Las migas de papa") suma `recuerdos_encontrados` GLOBAL
## (no por perfil: el album familiar es de los tres) con `_migrar_v1_a_v2`.
## v3 (17-Oct-2026, HE-59, docs/fichas/modo-equipo.md §11.5 y §14.9) suma el bloque GLOBAL `equipo`
## (presentacion del boton "¡Juntos!", intros de trucos, cinematicas vistas por familia, niveles de equipo
## ganados, records de equipo y batallas) y, por hermano, `equipo_premiado` en cada planeta. Nunca guarda
## pares, aciertos ni fallos por hermano en equipo (R2 de la ficha).
## HE-81 (07-Nov-2026, motor-lanzar.md §13.4, batalla-animalia.md §8.3) suma dentro de `equipo` el estado
## FAMILIAR de la ceremonia de partida de cada planeta (`partidas.<planeta>` = pasos, hecha, ceremonia,
## forzada) y los caminos encendidos del Mapa Estelar (`rumbos`). Sin subir version (lo pide la ficha):
## `_completar_v3()` los agrega en cada carga a los guardados v3 que no los traen, y se reescribe el archivo
## una sola vez. Nada de esto es por hermano.

signal progreso_actualizado(id_perfil: String)
## Cambio en los recuerdos encontrados/vistos (el boton del album se re-dibuja con esto).
signal recuerdos_actualizados
## Cambio en el estado familiar de la partida de un planeta (paso hecho, partida completada o forzada).
signal partida_actualizada(planeta_id: String)

const RUTA_GUARDADO := "user://progreso.json"
## Guardado aparte para los arneses y capturas de `herramientas/` (decision del PO, 03-Oct-2026):
## asi una prueba nunca pisa el progreso real de los ninos, aunque el juego este abierto.
const RUTA_GUARDADO_PRUEBAS := "user://progreso_pruebas.json"

## Version actual del formato de guardado. Subir este numero + agregar una funcion
## `_migrar_v<N>_a_v<N+1>(datos: Dictionary) -> Dictionary` es todo lo que hace falta
## para introducir un cambio de esquema sin romper partidas viejas.
const VERSION_ACTUAL := 3

## Ids validos para armar un equipo (modo-equipo.md §11.5): los tres hermanos.
const IDS_HERMANOS := ["maxi", "nicole", "sofia"]

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

## Archivo que se lee y escribe: el real en el juego, el de pruebas al correr con `--script`.
var ruta_guardado: String = RUTA_GUARDADO

## Hermanos que juegan juntos ahora (modo-equipo.md §11.5). Vive en memoria, nunca en disco: la seleccion
## lo vacia al abrirse y lo fija al tocar "¡Despegar!". Vacio = juego en solitario.
var equipo_activo: Array[String] = []
## Solo builds de depuracion (F5 en la seleccion): muestra "¡Juntos!" sin haber ganado la batalla, para
## que el PO pueda revisar el modo equipo antes de que exista la batalla (HE-69). Nunca se guarda.
var forzar_modo_equipo_depuracion := false


## En `_init` y no en `_ready` (06-Oct-2026): con `--script`, el `_initialize()` del arnés corre ANTES
## del `_ready()` de los autoloads, y alcanzaba a guardar con la ruta por defecto (la real).
func _init() -> void:
	if _corre_desde_herramienta():
		ruta_guardado = RUTA_GUARDADO_PRUEBAS
	cargar()


## Con `godot --script herramientas/...gd` el MainLoop es un SceneTree con script propio;
## el juego normal nunca le pone script. Asi se reconoce un arnes sin que tenga que avisar.
##
## Ojo (06-Oct-2026): al crear los autoloads, Godot 4.7 todavía no le asignó el script al SceneTree,
## así que esa revisión sola daba false y los arneses escribían el guardado REAL. Por eso primero se
## mira la línea de comandos (`--script` / `-s`), que existe desde el arranque.
func _corre_desde_herramienta() -> bool:
	for arg in OS.get_cmdline_args():
		if arg == "--script" or arg == "-s":
			return true
	var bucle := Engine.get_main_loop()
	return bucle != null and bucle.get_script() != null


## Carga `user://progreso.json`. Si no existe (primer arranque) o esta corrupto,
## crea los 3 perfiles por defecto y guarda de inmediato para dejar el archivo listo.
func cargar() -> void:
	if not FileAccess.file_exists(ruta_guardado):
		_datos = _crear_datos_por_defecto()
		guardar()
		return

	var archivo := FileAccess.open(ruta_guardado, FileAccess.READ)
	if archivo == null:
		push_warning("Progreso.cargar: no se pudo abrir %s, uso datos por defecto" % ruta_guardado)
		_datos = _crear_datos_por_defecto()
		guardar()
		return

	var texto := archivo.get_as_text()
	archivo.close()

	var resultado: Variant = JSON.parse_string(texto)
	if typeof(resultado) != TYPE_DICTIONARY:
		push_warning("Progreso.cargar: JSON invalido en %s, uso datos por defecto" % ruta_guardado)
		_datos = _crear_datos_por_defecto()
		guardar()
		return

	# Un archivo sin campo "version" tambien cuenta como "necesita resave": puede
	# ser un guardado hecho a mano o de un formato anterior a este mecanismo (stack
	# §7) — nunca debe quedar en disco sin el campo que hace posible migrar despues.
	var tenia_version: bool = resultado.has("version")
	var version_en_disco: int = int(resultado.get("version", 1))
	_datos = _migrar_datos(resultado)
	var completado_v3 := _completar_v3(_datos)
	# Un guardado de una version FUTURA no se reescribe al cargar (se perderia su marca de version).
	if version_en_disco <= VERSION_ACTUAL and (not tenia_version or version_en_disco != VERSION_ACTUAL or completado_v3):
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
	var archivo := FileAccess.open(ruta_guardado, FileAccess.WRITE)
	if archivo == null:
		push_error("Progreso.guardar: no se pudo escribir %s" % ruta_guardado)
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
		"recuerdos_encontrados": {},
		"equipo": _crear_equipo_por_defecto(),
	}


## Bloque global del modo equipo (modo-equipo.md §11.5 y §14.9). Es de la familia, no de un perfil.
func _crear_equipo_por_defecto() -> Dictionary:
	return {
		"presentado": false,
		"trucos_presentados": [],
		"cinematicas_vistas": [],
		"planetas": {},
		"batallas": {},
		"partidas": {},
		"rumbos": [],
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


## Aplica migraciones de esquema en cadena hasta `VERSION_ACTUAL` (stack §7, decision del
## 18-Jul-2026). Primera migracion real: v1 -> v2 (album de recuerdos, 27-Sep-2026).
func _migrar_datos(datos: Dictionary) -> Dictionary:
	var version_datos: int = int(datos.get("version", 1))

	if version_datos > VERSION_ACTUAL:
		# Guardado de una version futura (p. ej. se abrio con un build viejo por
		# error): no se puede migrar hacia atras, se usa tal cual y se avisa.
		push_warning("Progreso._migrar_datos: version %d es mas nueva que la soportada (%d)" % [version_datos, VERSION_ACTUAL])
		return datos

	if version_datos == 1:
		datos = _migrar_v1_a_v2(datos)
		version_datos = 2

	if version_datos == 2:
		datos = _migrar_v2_a_v3(datos)
		version_datos = 3

	datos["version"] = VERSION_ACTUAL
	return datos


## v1 -> v2: album de recuerdos (docs/fichas/album-recuerdos.md §8). Solo AGREGA el diccionario
## global vacio; perfiles, destellos, niveles y parciales quedan intactos.
func _migrar_v1_a_v2(datos: Dictionary) -> Dictionary:
	if not datos.get("recuerdos_encontrados", null) is Dictionary:
		datos["recuerdos_encontrados"] = {}
	datos["version"] = 2
	return datos


## v2 -> v3: modo equipo (docs/fichas/modo-equipo.md §11.5). Solo AGREGA estructuras vacias: el bloque
## global `equipo`, `especiales_conocidos` por perfil y `coleccion` / `equipo_premiado` en cada planeta ya
## visitado. Destellos, niveles, parciales, records y recuerdos quedan intactos.
func _migrar_v2_a_v3(datos: Dictionary) -> Dictionary:
	if not datos.get("equipo", null) is Dictionary:
		datos["equipo"] = _crear_equipo_por_defecto()
	var perfiles = datos.get("perfiles", {})
	if perfiles is Dictionary:
		for perfil in perfiles.values():
			if not perfil is Dictionary:
				continue
			if not perfil.get("especiales_conocidos", null) is Array:
				perfil["especiales_conocidos"] = []
			var planetas = perfil.get("planetas", {})
			if planetas is Dictionary:
				for planeta in planetas.values():
					if planeta is Dictionary:
						if not planeta.get("coleccion", null) is Array:
							planeta["coleccion"] = []
						if not planeta.get("equipo_premiado", null) is Array:
							planeta["equipo_premiado"] = []
	datos["version"] = 3
	return datos


## Completa un guardado v3 hecho antes de que existieran claves que la ficha agrego "sin subir version"
## (HE-81: `equipo.partidas` y `equipo.rumbos`). Idempotente: solo AGREGA lo que falta o repara un tipo
## invalido (sin borrar partidas ya guardadas). Devuelve true si cambio algo (y entonces `cargar()` reescribe
## el archivo una vez). Una version futura se deja tal cual.
func _completar_v3(datos: Dictionary) -> bool:
	if int(datos.get("version", VERSION_ACTUAL)) > VERSION_ACTUAL:
		return false
	var cambio := false
	if not datos.get("equipo", null) is Dictionary:
		datos["equipo"] = _crear_equipo_por_defecto()
		return true
	var equipo: Dictionary = datos["equipo"]
	if not equipo.get("partidas", null) is Dictionary:
		equipo["partidas"] = {}
		cambio = true
	if not equipo.get("rumbos", null) is Array:
		equipo["rumbos"] = []
		cambio = true
	for planeta_id in (equipo["partidas"] as Dictionary).keys():
		if _normalizar_partida(equipo["partidas"], str(planeta_id)):
			cambio = true
	return cambio


## Deja `partidas[planeta_id]` con sus 4 claves y tipos validos, conservando lo que ya traia. True si cambio.
func _normalizar_partida(partidas: Dictionary, planeta_id: String) -> bool:
	var cambio := false
	if not partidas.get(planeta_id, null) is Dictionary:
		partidas[planeta_id] = {}
		cambio = true
	var partida: Dictionary = partidas[planeta_id]
	if not partida.get("pasos", null) is Array:
		partida["pasos"] = []
		cambio = true
	for clave in ["hecha", "ceremonia", "forzada"]:
		if not partida.get(clave, null) is bool:
			var valor = partida.get(clave, null)
			partida[clave] = (valor is int or valor is float) and valor != 0
			cambio = true
	return cambio


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


## Estado a medio jugar de un nivel largo (p. ej. el reto dorado de Sofia, que se arma en varias
## tardes). El minijuego decide que guarda; aqui solo se persiste por hermano, planeta y nivel.
## Es un campo opcional del planeta ("parciales"): guardados viejos no lo traen y no hace falta migrar.
func guardar_estado_parcial(id_perfil: String, planeta_id: String, id_nivel: String, estado: Dictionary) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.guardar_estado_parcial: id_perfil desconocido '%s'" % id_perfil)
		return
	var datos_planeta := _datos_planeta(id_perfil, planeta_id)
	if not datos_planeta.has("parciales"):
		datos_planeta["parciales"] = {}
	datos_planeta["parciales"][id_nivel] = estado
	guardar()


func obtener_estado_parcial(id_perfil: String, planeta_id: String, id_nivel: String) -> Dictionary:
	if not _datos.get("perfiles", {}).has(id_perfil):
		return {}
	return _datos_planeta(id_perfil, planeta_id).get("parciales", {}).get(id_nivel, {})


func borrar_estado_parcial(id_perfil: String, planeta_id: String, id_nivel: String) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		return
	var parciales: Dictionary = _datos_planeta(id_perfil, planeta_id).get("parciales", {})
	if parciales.has(id_nivel):
		parciales.erase(id_nivel)
		guardar()


## Récord (mejor puntaje) de un nivel con puntaje, p. ej. el Río de pintura (docs/roadmap-rio-de-pintura.md
## §9). Cuenta cualquier intento, ganado o no: el récord es del hermano, nunca se compara con otro. Es un
## campo opcional del planeta ("records"): guardados viejos no lo traen y no hace falta migrar.
func obtener_record_nivel(id_perfil: String, planeta_id: String, id_nivel: String) -> int:
	if not _datos.get("perfiles", {}).has(id_perfil):
		return 0
	return int(_datos_planeta(id_perfil, planeta_id).get("records", {}).get(id_nivel, 0))


## Guarda `puntaje` si supera el récord. Devuelve true si es récord nuevo.
func registrar_puntaje_nivel(id_perfil: String, planeta_id: String, id_nivel: String, puntaje: int) -> bool:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.registrar_puntaje_nivel: id_perfil desconocido '%s'" % id_perfil)
		return false
	if puntaje <= obtener_record_nivel(id_perfil, planeta_id, id_nivel):
		return false
	var datos_planeta := _datos_planeta(id_perfil, planeta_id)
	if not datos_planeta.has("records"):
		datos_planeta["records"] = {}
	datos_planeta["records"][id_nivel] = puntaje
	guardar()
	return true


## Mejor puntaje de estrellitas logrado en un nivel (0 si nunca se completo o no puntua). Lo usa el
## mapa del planeta para mostrarlo en cada estacion.
func obtener_estrellitas_nivel(id_perfil: String, planeta_id: String, id_nivel: String) -> int:
	var niveles: Dictionary = _datos_planeta(id_perfil, planeta_id).get("niveles", {})
	return int(niveles.get(id_nivel, {}).get("estrellitas", 0))


## Presentaciones de una sola vez por hermano: cartas especiales, vistazo, vela... (ficha motor-emparejar
## §10.3, firmas de docs/fichas/modo-equipo.md §11.5). Campo opcional del perfil ("especiales_conocidos"):
## se crea al primer uso y guardados viejos no lo necesitan, asi que no sube la version (HE-60). La
## migracion v3 de HE-59 solo lo agrega vacio donde falte.
func especial_conocido(id_perfil: String, tipo: String) -> bool:
	if not _datos.get("perfiles", {}).has(id_perfil):
		return false
	return tipo in _datos["perfiles"][id_perfil].get("especiales_conocidos", [])


func marcar_especial_conocido(id_perfil: String, tipo: String) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.marcar_especial_conocido: id_perfil desconocido '%s'" % id_perfil)
		return
	var perfil: Dictionary = _datos["perfiles"][id_perfil]
	if not perfil.get("especiales_conocidos", null) is Array:
		perfil["especiales_conocidos"] = []
	if tipo in perfil["especiales_conocidos"]:
		return
	perfil["especiales_conocidos"].append(tipo)
	guardar()


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


## Planeta donde quedó estacionada la nave de ese hermano (el mapa estelar la dibuja ahí
## y el viaje estelar despega desde ahí). Toda aventura empieza en la Tierra.
func obtener_ubicacion_nave(id_perfil: String) -> String:
	return str(obtener_perfil(id_perfil).get("ubicacion_nave", "tierra"))


func fijar_ubicacion_nave(id_perfil: String, planeta_id: String) -> void:
	if not _datos.get("perfiles", {}).has(id_perfil):
		push_warning("Progreso.fijar_ubicacion_nave: id_perfil desconocido '%s'" % id_perfil)
		return
	_datos["perfiles"][id_perfil]["ubicacion_nave"] = planeta_id
	guardar()
	progreso_actualizado.emit(id_perfil)


## Cierre del viaje estelar (se conecta a su señal `completado(destellos)`): los destellos
## del camino cuentan para el planeta de destino y la nave queda estacionada ahí.
func registrar_viaje(destellos: int, id_perfil: String, planeta_destino: String) -> void:
	agregar_destellos(id_perfil, planeta_destino, destellos)
	fijar_ubicacion_nave(id_perfil, planeta_destino)


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


# ---------------------------------------------------------------------------
# Recuerdos del album "Las migas de papa" (global, no por perfil — ficha §8)
# ---------------------------------------------------------------------------
# `Progreso` solo guarda ids; que recuerdo existe, a que album pertenece y cuando se entrega lo
# decide el autoload `Recuerdos` leyendo `datos/recuerdos/catalogo.json`.

func _recuerdos() -> Dictionary:
	if not _datos.get("recuerdos_encontrados", null) is Dictionary:
		_datos["recuerdos_encontrados"] = {}
	return _datos["recuerdos_encontrados"]


## Copia de {id: {fecha, visto, dorado, quien}}.
func obtener_recuerdos_encontrados() -> Dictionary:
	return _recuerdos().duplicate(true)


func tiene_recuerdo(id_recuerdo: String) -> bool:
	return _recuerdos().has(id_recuerdo)


## Registra un recuerdo encontrado. Idempotente: si ya estaba, no cambia nada y devuelve false
## (nunca se "pierde" ni se re-entrega una foto). `quien` = hermano que lo encontro ("" si nadie).
func registrar_recuerdo(id_recuerdo: String, quien: String = "") -> bool:
	if id_recuerdo == "" or _recuerdos().has(id_recuerdo):
		return false
	_recuerdos()[id_recuerdo] = {
		"fecha": Time.get_datetime_string_from_system(false, true),
		"visto": false,
		"dorado": false,
		"quien": quien,
	}
	guardar()
	recuerdos_actualizados.emit()
	return true


func marcar_recuerdo_visto(id_recuerdo: String) -> void:
	var entrada: Dictionary = _recuerdos().get(id_recuerdo, {})
	if entrada.is_empty() or entrada.get("visto", false):
		return
	entrada["visto"] = true
	guardar()
	recuerdos_actualizados.emit()


## Marco dorado (estrellitas maximas de Sofia en la zona, ficha §4). Devuelve true si cambio.
func marcar_recuerdo_dorado(id_recuerdo: String) -> bool:
	var entrada: Dictionary = _recuerdos().get(id_recuerdo, {})
	if entrada.is_empty() or entrada.get("dorado", false):
		return false
	entrada["dorado"] = true
	guardar()
	recuerdos_actualizados.emit()
	return true


func hay_recuerdos_sin_ver() -> bool:
	for entrada in _recuerdos().values():
		if not (entrada as Dictionary).get("visto", false):
			return true
	return false


# ---------------------------------------------------------------------------
# Modo equipo (docs/fichas/modo-equipo.md §7, §11.5 y §14.9; HE-59)
# ---------------------------------------------------------------------------
# Todo es de la FAMILIA salvo `equipo_premiado`, que es por hermano (quien ya cobro sus destellos de un
# nivel de equipo). Ningun dato de pares, aciertos o fallos por hermano se guarda (R2).

func _equipo() -> Dictionary:
	if not _datos.get("equipo", null) is Dictionary:
		_datos["equipo"] = _crear_equipo_por_defecto()
	var equipo: Dictionary = _datos["equipo"]
	# Un guardado v3 hecho antes de que existiera una clave la crea al leer (§11.5).
	for clave in ["trucos_presentados", "cinematicas_vistas"]:
		if not equipo.get(clave, null) is Array:
			equipo[clave] = []
	for clave in ["planetas", "batallas", "partidas"]:
		if not equipo.get(clave, null) is Dictionary:
			equipo[clave] = {}
	if not equipo.get("rumbos", null) is Array:
		equipo["rumbos"] = []
	return equipo


func _equipo_planeta(planeta_id: String) -> Dictionary:
	var planetas: Dictionary = _equipo()["planetas"]
	if not planetas.get(planeta_id, null) is Dictionary:
		planetas[planeta_id] = {"ganados": [], "records": {}}
	var planeta: Dictionary = planetas[planeta_id]
	if not planeta.get("ganados", null) is Array:
		planeta["ganados"] = []
	if not planeta.get("records", null) is Dictionary:
		planeta["records"] = {}
	return planeta


## Fija quienes juegan juntos (2 o 3 ids validos, sin repetir). Si no es valido, no cambia nada.
func fijar_equipo(ids: Array[String]) -> void:
	var limpios: Array[String] = []
	for id in ids:
		if id in IDS_HERMANOS and id not in limpios:
			limpios.append(id)
	if limpios.size() < 2 or limpios.size() != ids.size():
		push_warning("Progreso.fijar_equipo: equipo invalido %s (2-3 hermanos, sin repetir)" % [ids])
		return
	limpios.sort()
	equipo_activo = limpios
	# Lo que el mapa ya usa de un perfil (volumen, musica) toma al menor del equipo (§11.5).
	perfil_seleccionado = limpios[0]


func limpiar_equipo() -> void:
	equipo_activo = []


## Ids ordenados alfabeticamente (coincide con el orden de edad) unidos con "+": "maxi+nicole+sofia".
func clave_equipo(ids: Array) -> String:
	var copia: Array = ids.duplicate()
	copia.sort()
	return "+".join(PackedStringArray(copia))


## Una llamada al ganar un nivel de equipo (§7.1 y §11.5). Paga `destellos_por_hermano` a cada id que aun
## no lo cobro en ese nivel (sin marcar ninguna estacion individual), agrega el nivel a "ganados" y guarda
## el record de pasos si es menor (menos es mejor). Guarda una sola vez.
func registrar_victoria_equipo(planeta_id: String, id_nivel: String, ids: Array[String], destellos_por_hermano: int, pasos_usados: int) -> Dictionary:
	var premiados: Array[String] = []
	for id in ids:
		if not _datos.get("perfiles", {}).has(id):
			push_warning("Progreso.registrar_victoria_equipo: id_perfil desconocido '%s'" % id)
			continue
		var datos_planeta := _datos_planeta(id, planeta_id)
		if not datos_planeta.get("equipo_premiado", null) is Array:
			datos_planeta["equipo_premiado"] = []
		if id_nivel in datos_planeta["equipo_premiado"]:
			continue
		datos_planeta["equipo_premiado"].append(id_nivel)
		premiados.append(id)
		if destellos_por_hermano > 0:
			datos_planeta["destellos"] = int(datos_planeta.get("destellos", 0)) + destellos_por_hermano
			var perfil: Dictionary = _datos["perfiles"][id]
			perfil["destellos_totales"] = int(perfil.get("destellos_totales", 0)) + destellos_por_hermano
	var planeta := _equipo_planeta(planeta_id)
	var primera_victoria_nivel: bool = id_nivel not in planeta["ganados"]
	if primera_victoria_nivel:
		planeta["ganados"].append(id_nivel)
	var clave := clave_equipo(ids)
	var records: Dictionary = planeta["records"]
	if not records.get(id_nivel, null) is Dictionary:
		records[id_nivel] = {}
	var previo := int(records[id_nivel].get(clave, -1))
	var primer_record := previo < 0
	var record_nuevo := primer_record or pasos_usados < previo
	if record_nuevo:
		records[id_nivel][clave] = maxi(0, pasos_usados)
	guardar()
	for id in premiados:
		progreso_actualizado.emit(id)
	return {"premiados": premiados, "record_nuevo": record_nuevo, "primer_record": primer_record,
		"primera_victoria_nivel": primera_victoria_nivel}


## Pasos del rival en el mejor triunfo de esa combinacion en ese nivel. -1 = sin record.
func obtener_record_equipo(planeta_id: String, id_nivel: String, clave: String) -> int:
	var records: Dictionary = _equipo_planeta(planeta_id)["records"]
	var por_nivel = records.get(id_nivel, {})
	if not por_nivel is Dictionary:
		return -1
	return int(por_nivel.get(clave, -1))


## Niveles de equipo ganados por cualquier combinacion (0-5 en Arcoiris): estrellitas del boton "¡Juntos!".
func contar_niveles_equipo_ganados(planeta_id: String) -> int:
	return (_equipo_planeta(planeta_id)["ganados"] as Array).size()


func nivel_equipo_ganado(planeta_id: String, id_nivel: String) -> bool:
	return id_nivel in _equipo_planeta(planeta_id)["ganados"]


func modo_equipo_presentado() -> bool:
	return bool(_equipo().get("presentado", false))


func marcar_modo_equipo_presentado() -> void:
	if modo_equipo_presentado():
		return
	_equipo()["presentado"] = true
	guardar()


func trucos_presentados(clave: String) -> bool:
	return clave in _equipo()["trucos_presentados"]


func marcar_trucos_presentados(clave: String) -> void:
	if trucos_presentados(clave):
		return
	_equipo()["trucos_presentados"].append(clave)
	guardar()


## "Ya vista" es de la FAMILIA (storyboard HE-68): id = "<id_batalla>:<id_animacion>" o "nucleo:<id>".
## Se marca al TERMINAR la cinematica o la presentacion, no al empezarla.
func cinematica_vista(id: String) -> bool:
	return id in _equipo()["cinematicas_vistas"]


func marcar_cinematica_vista(id: String) -> void:
	if id == "" or cinematica_vista(id):
		return
	_equipo()["cinematicas_vistas"].append(id)
	guardar()


# --- Batallas (§14.9). La escena de batalla es de HE-69; aqui solo viven sus marcas. ---

func _batalla(id_batalla: String) -> Dictionary:
	var batallas: Dictionary = _equipo()["batallas"]
	if not batallas.get(id_batalla, null) is Dictionary:
		batallas[id_batalla] = {"rondas_ganadas": [], "epilogo": false, "ganada": false, "premiados": [], "parcial": {}}
	return batallas[id_batalla]


func registrar_ronda_batalla(id_batalla: String, id_ronda: String) -> void:
	var batalla := _batalla(id_batalla)
	if id_ronda in batalla["rondas_ganadas"]:
		return
	batalla["rondas_ganadas"].append(id_ronda)
	guardar()


func obtener_rondas_batalla(id_batalla: String) -> Array:
	return (_batalla(id_batalla)["rondas_ganadas"] as Array).duplicate()


## Marca la batalla ganada, paga `destellos_por_hermano` a quien aun no cobro y devuelve los premiados.
func registrar_batalla_ganada(id_batalla: String, planeta_id: String, ids: Array[String], destellos_por_hermano: int) -> Array[String]:
	var batalla := _batalla(id_batalla)
	batalla["ganada"] = true
	batalla["parcial"] = {}
	var premiados: Array[String] = []
	for id in ids:
		if id in batalla["premiados"] or not _datos.get("perfiles", {}).has(id):
			continue
		batalla["premiados"].append(id)
		premiados.append(id)
		if destellos_por_hermano > 0:
			var datos_planeta := _datos_planeta(id, planeta_id)
			datos_planeta["destellos"] = int(datos_planeta.get("destellos", 0)) + destellos_por_hermano
			var perfil: Dictionary = _datos["perfiles"][id]
			perfil["destellos_totales"] = int(perfil.get("destellos_totales", 0)) + destellos_por_hermano
	guardar()
	for id in premiados:
		progreso_actualizado.emit(id)
	return premiados


func batalla_ganada(id_batalla: String) -> bool:
	var batalla = _equipo()["batallas"].get(id_batalla, {})
	return batalla is Dictionary and bool(batalla.get("ganada", false))


## M4 (§14.6): el parcial de la ronda en curso; `estado` es del motor y el nucleo no lo interpreta, salvo una
## clave generica opcional: `"etapa"` (int >= 1) para rondas de varias etapas (la Torre, motor-lanzar §12 y §25;
## PO 05-Nov-2026, R17 = A: guardado entre etapas). Se copia a `parcial.etapa` y protege la regla "al retomar
## se vuelve a la etapa guardada, nunca a una ganada": un parcial de la MISMA ronda con una etapa menor que la
## ya guardada se rechaza (devuelve false, sin tocar el archivo). Sin etapa en el estado, `parcial.etapa` = 0.
func guardar_parcial_batalla(id_batalla: String, id_ronda: String, estado: Dictionary) -> bool:
	var batalla := _batalla(id_batalla)
	var etapa := maxi(0, int(estado.get("etapa", 0)))
	var anterior = batalla.get("parcial", {})
	if anterior is Dictionary and str(anterior.get("ronda", "")) == id_ronda and etapa < int(anterior.get("etapa", 0)):
		push_warning("Progreso.guardar_parcial_batalla: etapa %d < %d ya guardada en '%s'; se ignora" % [etapa, int(anterior.get("etapa", 0)), id_ronda])
		return false
	batalla["parcial"] = {"ronda": id_ronda, "etapa": etapa, "estado": estado}
	guardar()
	return true


func obtener_parcial_batalla(id_batalla: String) -> Dictionary:
	var parcial = _batalla(id_batalla).get("parcial", {})
	return parcial if parcial is Dictionary else {}


## Etapa guardada de la ronda en curso (0 = sin parcial, otra ronda o una ronda sin etapas). Sirve, p. ej., para
## que el hito del mapa de batalla muestre cuanto falta sin numeros. Guardados viejos sin `etapa`: la lee del estado.
func obtener_etapa_parcial_batalla(id_batalla: String, id_ronda: String) -> int:
	var parcial := obtener_parcial_batalla(id_batalla)
	if str(parcial.get("ronda", "")) != id_ronda:
		return 0
	var estado = parcial.get("estado", {})
	var del_estado := int(estado.get("etapa", 0)) if estado is Dictionary else 0
	return maxi(0, int(parcial.get("etapa", del_estado)))


## Revancha (motor-lanzar §11 y §13.3): `equipo.batallas.<id>.revanchas.<id_ronda>` = {estrellitas, record}.
## Sin subir version: se crea al escribir. Guarda el maximo de estrellitas y el record si mejora (menor y >= 0;
## record = recursos usados, -1 = sin record). Guarda una sola vez.
func registrar_revancha_batalla(id_batalla: String, id_ronda: String, estrellitas: int, record: int) -> Dictionary:
	var batalla := _batalla(id_batalla)
	if not batalla.get("revanchas", null) is Dictionary:
		batalla["revanchas"] = {}
	var previa := obtener_revancha_batalla(id_batalla, id_ronda)
	var record_previo := int(previa["record"])
	var resultado := {"estrellitas_nuevas": estrellitas > int(previa["estrellitas"]),
		"record_nuevo": record >= 0 and (record_previo < 0 or record < record_previo),
		"primer_record": record >= 0 and record_previo < 0}
	batalla["revanchas"][id_ronda] = {
		"estrellitas": maxi(int(previa["estrellitas"]), clampi(estrellitas, 0, 3)),
		"record": record if resultado["record_nuevo"] else record_previo}
	guardar()
	return resultado


## {"estrellitas": int, "record": int} (0 y -1 si nunca se jugo).
func obtener_revancha_batalla(id_batalla: String, id_ronda: String) -> Dictionary:
	var revanchas = _batalla(id_batalla).get("revanchas", {})
	var r = revanchas.get(id_ronda, {}) if revanchas is Dictionary else {}
	if not r is Dictionary:
		r = {}
	return {"estrellitas": int(r.get("estrellitas", 0)), "record": int(r.get("record", -1))}


func borrar_parcial_batalla(id_batalla: String) -> void:
	var batalla := _batalla(id_batalla)
	if not (batalla.get("parcial", {}) as Dictionary).is_empty():
		batalla["parcial"] = {}
		guardar()


## true si hay al menos una batalla ganada: la seleccion muestra "¡Juntos!" (§3.1). En builds de
## depuracion, F5 en la seleccion lo fuerza en memoria (`forzar_modo_equipo_depuracion`).
func modo_equipo_desbloqueado() -> bool:
	if forzar_modo_equipo_depuracion:
		return true
	for batalla in _equipo()["batallas"].values():
		if batalla is Dictionary and bool(batalla.get("ganada", false)):
			return true
	return false


# ---------------------------------------------------------------------------
# Partida de cada planeta y rumbos del Mapa Estelar (HE-81; motor-lanzar.md §13.4, batalla-animalia.md §8)
# ---------------------------------------------------------------------------
# Estado de la FAMILIA, generico por id de planeta: el nucleo nunca sabe de Arcoiris ni de Animalia. Con un
# hermano con la pieza (su zona 3) y la batalla ganada, la ceremonia instala la pieza y la nave queda lista
# PARA TODOS; la llave de la zona de padres (`forzar_partida`) hace lo mismo sin batalla ni ceremonia. Un
# rumbo es "<origen>>destino" (p. ej. "arcoiris>animalia"). Leer nunca crea entradas en el guardado.

const PARTIDA_VACIA := {"pasos": [], "hecha": false, "ceremonia": false, "forzada": false}


## Entrada de escritura (la crea si falta).
func _partida(planeta_id: String) -> Dictionary:
	var partidas: Dictionary = _equipo()["partidas"]
	_normalizar_partida(partidas, planeta_id)
	return partidas[planeta_id]


## Entrada de lectura: la guardada o una vacia, sin tocar `_datos`.
func _leer_partida(planeta_id: String) -> Dictionary:
	var partida = _equipo()["partidas"].get(planeta_id, null)
	return partida if partida is Dictionary else PARTIDA_VACIA


## Copia de {pasos, hecha, ceremonia, forzada} (valores vacios si nunca se empezo).
func obtener_partida(planeta_id: String) -> Dictionary:
	var partida := _leer_partida(planeta_id)
	return {"pasos": (partida.get("pasos", []) as Array).duplicate() if partida.get("pasos", null) is Array else [],
		"hecha": bool(partida.get("hecha", false)), "ceremonia": bool(partida.get("ceremonia", false)),
		"forzada": bool(partida.get("forzada", false))}


## Pasos de la ceremonia ya hechos, en el orden en que se hicieron ("tanque", "ala", "ruta", "despedida",
## "llamada"; los ids los decide la escena de partida, no `Progreso`).
func pasos_partida(planeta_id: String) -> Array:
	return obtener_partida(planeta_id)["pasos"]


func paso_partida_hecho(planeta_id: String, paso: String) -> bool:
	return paso in pasos_partida(planeta_id)


## Guarda al terminar cada paso (cierre_arcoiris.md §16.3). Idempotente: un paso repetido no se duplica.
func marcar_paso_partida(planeta_id: String, paso: String) -> void:
	if planeta_id == "" or paso == "":
		push_warning("Progreso.marcar_paso_partida: planeta '%s' o paso '%s' vacio" % [planeta_id, paso])
		return
	var partida := _partida(planeta_id)
	if paso in partida["pasos"]:
		return
	partida["pasos"].append(paso)
	guardar()
	partida_actualizada.emit(planeta_id)


## Retomar (cierre_arcoiris.md §16.3): el primer id de `orden` que todavia no se hizo; "" si estan todos.
## `orden` es la lista de pasos de la escena (p. ej. `datos/partidas/<planeta>.json` -> "pasos").
func primer_paso_pendiente(planeta_id: String, orden: Array) -> String:
	var hechos := pasos_partida(planeta_id)
	for paso in orden:
		if str(paso) not in hechos:
			return str(paso)
	return ""


## true = la pieza esta instalada y la nave lista para TODOS (por la ceremonia o por la llave de padres).
## Con esto el Mapa Estelar abre el planeta siguiente (`viaje_siguiente_requiere`) y dibuja la pieza.
func partida_hecha(planeta_id: String) -> bool:
	return bool(_leer_partida(planeta_id).get("hecha", false))


## true = la ceremonia se vio completa (la llave de padres no la consume).
func ceremonia_hecha(planeta_id: String) -> bool:
	return bool(_leer_partida(planeta_id).get("ceremonia", false))


## true = la llave de padres la marco hecha sin batalla.
func partida_forzada(planeta_id: String) -> bool:
	return bool(_leer_partida(planeta_id).get("forzada", false))


## Al terminar la ceremonia: hecha = true, ceremonia = true y enciende `rumbo` ("" = sin rumbo, p. ej. el
## ultimo planeta). Idempotente; guarda una sola vez. Para saber si hay "¡rumbo nuevo!", la escena consulta
## `rumbo_encendido(rumbo)` ANTES de llamar (despues de la llave ya estaba encendido: sin rama del Mapa).
func completar_partida(planeta_id: String, rumbo: String) -> void:
	if planeta_id == "":
		push_warning("Progreso.completar_partida: planeta vacio")
		return
	var partida := _partida(planeta_id)
	var cambio := not bool(partida["hecha"]) or not bool(partida["ceremonia"])
	partida["hecha"] = true
	partida["ceremonia"] = true
	cambio = _encender_rumbo(rumbo) or cambio
	if cambio:
		guardar()
		partida_actualizada.emit(planeta_id)


## Llave de la zona de padres ("Instalar el ala sin la batalla", detras del candado adulto, GDD §6.7):
## hecha = true, forzada = true y enciende `rumbo`, SIN batalla ni ceremonia (`ceremonia` sigue en false: si
## despues ganan la batalla, la ceremonia se juega una vez). Si la partida ya estaba hecha no cambia nada
## (no hay nada que forzar). Guarda una sola vez.
func forzar_partida(planeta_id: String, rumbo: String) -> void:
	if planeta_id == "":
		push_warning("Progreso.forzar_partida: planeta vacio")
		return
	if partida_hecha(planeta_id):
		if _encender_rumbo(rumbo):
			guardar()
			partida_actualizada.emit(planeta_id)
		return
	var partida := _partida(planeta_id)
	partida["hecha"] = true
	partida["forzada"] = true
	_encender_rumbo(rumbo)
	guardar()
	partida_actualizada.emit(planeta_id)


## Caminos encendidos del Mapa Estelar, en el orden en que se encendieron (copia).
func rumbos() -> Array:
	return (_equipo()["rumbos"] as Array).duplicate()


func rumbo_encendido(rumbo: String) -> bool:
	return rumbo != "" and rumbo in _equipo()["rumbos"]


## Agrega el rumbo sin guardar. True si era nuevo.
func _encender_rumbo(rumbo: String) -> bool:
	if rumbo == "" or rumbo_encendido(rumbo):
		return false
	if not ">" in rumbo:
		push_warning("Progreso: rumbo '%s' sin el formato origen>destino" % rumbo)
	_equipo()["rumbos"].append(rumbo)
	return true


## true si algun hermano ya gano la pieza de nave de ese planeta (su zona 3).
func alguien_tiene_pieza_nave(planeta_id: String) -> bool:
	for id in obtener_ids_perfiles():
		if tiene_pieza_nave(str(id), planeta_id):
			return true
	return false


## La ceremonia esta para jugarse: un hermano con la pieza + la batalla ganada + la ceremonia sin ver (la
## llave de padres no la consume, asi que despues de `forzar_partida` sigue disponible una vez).
func partida_disponible(planeta_id: String, id_batalla: String) -> bool:
	return batalla_ganada(id_batalla) and alguien_tiene_pieza_nave(planeta_id) and not ceremonia_hecha(planeta_id)


## Estado del hito de la batalla del mapa del planeta (el Claro de Arcoiris, el Campamento de Animalia),
## los 3 estados de motor-lanzar §13.4: "mochila" (batalla sin ganar) -> "partida" (`partida_disponible`)
## -> "revancha" (ganada y ceremonia vista). La batalla solo existe tras la primera pieza (zona 3), asi que
## ganada implica un hermano con la pieza. Tras la llave de padres, si ganan la batalla el hito ofrece la
## ceremonia una vez antes de la revancha (m8).
func estado_hito_batalla(id_batalla: String, planeta_id: String) -> String:
	if not batalla_ganada(id_batalla):
		return "mochila"
	return "revancha" if ceremonia_hecha(planeta_id) else "partida"
