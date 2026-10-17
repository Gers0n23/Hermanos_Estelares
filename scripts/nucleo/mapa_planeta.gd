extends Node2D

## Mapa interno de un planeta: zonas y estaciones (GDD §3 "Mapa de cada planeta", HE-41,
## docs/fichas/planeta-arcoiris-zonas.md). Es el "menu secundario" entre el Mapa Estelar y los
## minijuegos.
##
## Data-driven desde `ruta_mapa` (p. ej. `datos/planetas/arcoiris/mapa.json`): zonas, sus 4
## estaciones, escena del motor y nivel de cada hermano. Regla de oro 3: este nucleo NUNCA conoce
## minijuegos concretos; solo instancia la escena que dice el JSON con el contrato de
## `minijuego_base.gd` (ruta_nivel, planeta_id, id_perfil, completado, salir_solicitado).
##
## Progreso: no guarda nada propio. El estado de estaciones y zonas se DERIVA de los niveles que
## `Progreso` ya registra por hermano (id_nivel completado + mejores estrellitas), asi que no hizo
## falta migrar la version del guardado (HE-41 la preveia; queda para cuando se guarden datos nuevos).
##
## Reglas (ficha de zonas §2.1, decision del PO 27-Sep-2026): zona 1 abierta; la siguiente se abre
## al completar TODAS las estaciones jugables de la actual (las que aun no tienen minijuego no
## cuentan, para que nadie quede trabado). La zona secreta sigue la misma regla. Los retos dorados
## son opcionales y no cuentan. Zonas no abiertas: dormidas y descoloridas, nunca con candado (GDD §3).
##
## Paisaje: si el JSON trae `paisaje` (script de un Control), el planeta se dibuja como un mapa
## ilustrado y cada zona como su hito (ver `scripts/planetas/arcoiris/paisaje_arcoiris.gd`); si no,
## se usa la imagen `fondo` con zonas redondas.
##
## Estaciones (PO 17-Oct-2026, maqueta aprobada): ya no hay un panel fijo abajo que tape el mundo.
## Al tocar una zona, el mundo se oscurece y de la zona nace una burbuja con sus juegos como esferas
## (lenguaje del menu de planetas); se cierra tocando afuera o la X. La zona que toca jugar late con
## un halo dorado.
##
## UX (GDD §6): todo narrado por voz, objetivos >=96 px, sin texto obligatorio (los nombres son un
## extra para Sofia). Tocar a Cometa lleva directo a la siguiente estacion pendiente (riesgo 5 de la
## ficha: Maxi no tiene que navegar). F4 (solo builds de depuracion del PO) abre todas las zonas.
##
## HE-40/HE-44 (28-Sep-2026, PROVISIONAL): el mapa pasa a cada motor `destellos_fijos` (100 por estacion y
## 0 en retos dorados, `mapa.json`), la zona "perfecta" (marco dorado) solo mira las estaciones cuyo nivel
## puntua estrellitas (Pinta no), y la entrega del album espera la senal `celebracion_zona_terminada`.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const RUTA_MAPA_ESTELAR := "res://escenas/nucleo/mapa_estelar.tscn"
const PREFIJO_AUDIO := "res://assets/audio/"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const RUTA_COMETA := "res://assets/sprites/personajes/cometa_base.png"
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_ELEGIR := "res://assets/audio/sfx/ui/seleccionar.ogg"
## "Todavia no" (zona dormida, estacion que llega pronto): campanitas de sueño, no el `error` de
## Kenney (UX HE-40 R16, 03-Oct-2026; herramientas/componer_sfx_ui.py).
const SFX_NO := "res://assets/audio/sfx/ui/zona_dormida.ogg"
const SFX_FIESTA := "res://assets/audio/sfx/ui/confirmar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const RADIO_ZONA := 62.0
const LADO_ZONA := 180.0
## Cada juego es una esfera de 132 px (GDD §6.1: >= 96 px) con sus estrellitas debajo.
const LADO_ORBE := 132.0
const PASO_ORBES := 145.0
const RUTA_ICONOS := "res://assets/sprites/ui/iconos_juegos/%s.svg"
## Burbuja de estaciones: nace de la zona tocada, debajo de ella o (si no cabe) encima.
const TAMANO_BURBUJA := Vector2(620, 272)
const COLOR_BURBUJA := Color("#3A2178")
## Pildoras oscuras translucidas del menu de planetas (nombres, HUD).
const COLOR_PILDORA := Color(0.17, 0.09, 0.36, 0.64)
const COLOR_DORMIDA := Color("#B9B4C9")
const BANDAS := ["rojo", "naranja", "amarillo", "verde", "azul", "violeta"]
const COLOR_BANDA := {
	"rojo": Color("#FF6B6B"), "naranja": Color("#FF9F4A"), "amarillo": Color("#FFCB3D"),
	"verde": Color("#7DD87A"), "azul": Color("#4A8BE0"), "violeta": Color("#B48CE8"), "brillo": Color("#FFE38A"),
}
const COLORES_HERMANO := {"maxi": Color("4aa8ff"), "nicole": Color("ff5fae"), "sofia": Color("4fd8e0")}
const RETRATOS_HERMANO := {
	"maxi": "res://assets/sprites/personajes/maxi_base.png",
	"nicole": "res://assets/sprites/personajes/nicole_base.png",
	"sofia": "res://assets/sprites/personajes/sofia_base.png",
}

## Lo que cada hermano ya vio de cada planeta en esta sesion: al volver de un juego se celebra lo
## que cambio (el color que vuelve, la zona que despierta). Se deriva del progreso; no se persiste.
static var _visto := {}
static var _zona_elegida := {}
static var _ruta_por_defecto := ""
## F4: el PO puede abrir todas las zonas para revisar variantes sin jugar las anteriores.
static var todo_abierto := false

## Termino la secuencia de voces que celebra lo que cambio al volver (zona completa, regalo, zona que
## despierta). La entrega del album la espera para no cortar a Coco (HE-44 mecanicas #10, UX R11).
signal celebracion_zona_terminada

@export_file("*.json") var ruta_mapa: String = ""

var mapa: Dictionary = {}
var planeta_id := ""
var zonas: Array = []
var seleccion := 0
var id_perfil := "maxi"

var _ui: Control
var _efectos: Control
var _camino: Control
var _arcoiris: Control
## Silueta de la pieza de la nave que se pinta por zona completada (`pieza_nave` en el mapa).
var _pieza: Control
var _nodos_zona: Array = []
## Esferas de las estaciones de la zona elegida (dentro de la burbuja).
var _tarjetas: Array = []
var _titulo_zona: Label
var _modal: Control
var _velo: ColorRect
var _burbuja: Control
var _boton_cerrar: Button
var _modal_abierto := false
## Hacia donde apunta la cola de la burbuja: x en la burbuja y si la burbuja esta debajo de la zona.
var _cola := Vector2.ZERO
var _cola_arriba := true
var _base_cometa := Vector2.ZERO
var _anfitriona: TextureRect
var _boton_cometa: Button
var _boton_salir: Button
var _cache_ids := {}
var _texturas_icono := {}
var _tiempo := 0.0
var _lanzando := false
var _siguiente: Array = [-1, -1]
var _avance_bandas := {}
var _salto_coco := 0.0
var _base_coco := Vector2.ZERO
var _id_voces := 0
var _paisaje: Control
## true mientras suena la secuencia de celebracion de `_celebrar_cambios`.
var _celebrando := false
var _entrega: Node


func _ready() -> void:
	if ruta_mapa == "":
		ruta_mapa = _ruta_por_defecto
	_ruta_por_defecto = ruta_mapa
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.perfil_seleccionado != "":
		id_perfil = progreso.perfil_seleccionado
	if not FileAccess.file_exists(ruta_mapa):
		push_error("mapa_planeta: no existe el mapa %s" % ruta_mapa)
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta_mapa))
	if not datos is Dictionary:
		push_error("mapa_planeta: JSON invalido en %s" % ruta_mapa)
		return
	mapa = datos
	planeta_id = str(mapa.get("planeta_id", ""))
	calcular_estado()
	_construir_ui()
	var clave := _clave()
	var elegida: int = _zona_elegida.get(clave, -1)
	seleccion = elegida if elegida >= 0 and elegida < zonas.size() and zonas[elegida]["abierta"] else zona_sugerida()
	_celebrar_cambios()
	_mostrar_estaciones()
	_entregar_recuerdos_zonas()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	if _anfitriona != null:
		_anfitriona.position.y = _base_coco.y - _salto_coco - (absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0)
	if _boton_cometa != null:
		_boton_cometa.position.y = _base_cometa.y - 3.5 * (1.0 - cos(_tiempo * TAU / 3.0))
	for nodo in _nodos_zona:
		nodo.queue_redraw()
	for tarjeta in _tarjetas:
		tarjeta.queue_redraw()
		var dorado: Button = tarjeta.get_meta("dorado", null)
		if dorado != null and dorado.visible:
			dorado.rotation = sin(_tiempo * 3.0) * 0.1
	if not _avance_bandas.is_empty():
		_arcoiris.queue_redraw()


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_F4 and OS.is_debug_build():
		todo_abierto = not todo_abierto
		print("[mapa_planeta] F4 todas las zonas abiertas: %s" % todo_abierto)
		calcular_estado()
		_marcar_visto()
		_reproducir_sfx(SFX_ELEGIR)
		_refrescar()


func _clave() -> String:
	return "%s|%s" % [id_perfil, planeta_id]


# ---------------------------------------------------------------------------
# Estado (derivado de Progreso)
# ---------------------------------------------------------------------------

func calcular_estado() -> void:
	zonas.clear()
	var progreso := get_node_or_null("/root/Progreso")
	for datos_zona: Dictionary in mapa.get("zonas", []):
		var estaciones: Array = []
		var jugables := 0
		var completadas := 0
		for datos_estacion: Dictionary in datos_zona.get("estaciones", []):
			var ruta_nivel := str(datos_estacion.get("niveles", {}).get(id_perfil, ""))
			# Una estacion puede abrir otro motor para un hermano (`escenas`: {id_perfil: ruta}); p. ej.
			# la Lluvia de colores de Sofia abre el taller de mezclas. El mapa no sabe que motor es.
			var escena := str(datos_estacion.get("escenas", {}).get(id_perfil, datos_estacion.get("escena", "")))
			var jugable := ruta_nivel != "" and escena != "" and ResourceLoader.exists(escena) and FileAccess.file_exists(ruta_nivel)
			var id_nivel := _id_nivel(ruta_nivel) if jugable else ""
			var completada := false
			var estrellitas := 0
			if jugable and progreso != null:
				completada = progreso.esta_nivel_completado(id_perfil, planeta_id, id_nivel)
				estrellitas = progreso.obtener_estrellitas_nivel(id_perfil, planeta_id, id_nivel)
			# Reto dorado (opcional, Sofia v3): aparece al lograr 3 estrellitas en la estacion. No cuenta
			# para abrir zonas: el planeta siempre se puede completar sin el.
			var ruta_dorado := str(datos_estacion.get("niveles_dorados", {}).get(id_perfil, ""))
			var hay_dorado := jugable and ruta_dorado != "" and FileAccess.file_exists(ruta_dorado)
			var dorado_completado := false
			if hay_dorado and progreso != null:
				dorado_completado = progreso.esta_nivel_completado(id_perfil, planeta_id, _id_nivel(ruta_dorado))
			jugables += 1 if jugable else 0
			completadas += 1 if completada else 0
			estaciones.append({"datos": datos_estacion, "juego": str(datos_estacion.get("juego", "")), "jugable": jugable,
				"completada": completada, "estrellitas": estrellitas, "ruta_nivel": ruta_nivel, "escena": escena,
				"perfil_nivel": _perfil_nivel(ruta_nivel) if jugable else "",
				"puntua": _puntua_nivel(ruta_nivel) if jugable else false,
				"dorado_ruta": ruta_dorado if hay_dorado else "", "dorado_completado": dorado_completado,
				"dorado_disponible": hay_dorado and (estrellitas >= 3 or dorado_completado or todo_abierto)})
		zonas.append({"datos": datos_zona, "estaciones": estaciones, "jugables": jugables, "completadas": completadas,
			"completa": jugables > 0 and completadas == jugables, "abierta": false,
			"secreta": bool(datos_zona.get("secreta", false))})
	for i in zonas.size():
		var zona: Dictionary = zonas[i]
		if i == 0 or todo_abierto:
			zona["abierta"] = true
			continue
		var anterior: Dictionary = zonas[i - 1]
		zona["abierta"] = anterior["abierta"] and anterior["completadas"] >= anterior["jugables"]
	if _paisaje != null:
		_paisaje.actualizar(zonas)


func _id_nivel(ruta: String) -> String:
	if _cache_ids.has(ruta):
		return _cache_ids[ruta]["id"]
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var id := ruta.get_file().get_basename()
	var perfil := ""
	var puntua := true
	if datos is Dictionary:
		id = str(datos.get("id_nivel", id))
		perfil = str(datos.get("perfil", ""))
		puntua = bool(datos.get("puntua_estrellitas", true))
	_cache_ids[ruta] = {"id": id, "perfil": perfil, "puntua": puntua}
	return id


func _perfil_nivel(ruta: String) -> String:
	_id_nivel(ruta)
	return _cache_ids[ruta]["perfil"]


## Un nivel puntua estrellitas salvo que declare `"puntua_estrellitas": false` (Pinta con Coco).
func _puntua_nivel(ruta: String) -> bool:
	_id_nivel(ruta)
	return bool(_cache_ids[ruta]["puntua"])


## Primera zona abierta con algo pendiente; si todo esta hecho, la ultima abierta.
func zona_sugerida() -> int:
	var ultima := 0
	for i in zonas.size():
		if not zonas[i]["abierta"]:
			continue
		ultima = i
		for estacion in zonas[i]["estaciones"]:
			if estacion["jugable"] and not estacion["completada"]:
				return i
	return ultima


## [zona, estacion] de la siguiente estacion pendiente (primero en la zona elegida) o [-1, -1].
func siguiente_estacion() -> Array:
	var orden: Array = [seleccion]
	for i in zonas.size():
		if i != seleccion:
			orden.append(i)
	for i in orden:
		if not zonas[i]["abierta"]:
			continue
		var estaciones: Array = zonas[i]["estaciones"]
		for j in estaciones.size():
			if estaciones[j]["jugable"] and not estaciones[j]["completada"]:
				return [i, j]
	return [-1, -1]


func _marcar_visto() -> void:
	var abiertas: Array = []
	var completas: Array = []
	_visto[_clave()] = {"abiertas": abiertas, "completas": completas, "dorados": _dorados_disponibles()}
	for zona in zonas:
		abiertas.append(zona["abierta"])
		completas.append(zona["completa"])


func _dorados_disponibles() -> Array:
	var lista: Array = []
	for i in zonas.size():
		for j in zonas[i]["estaciones"].size():
			if zonas[i]["abierta"] and zonas[i]["estaciones"][j]["dorado_disponible"]:
				lista.append("%d_%d" % [i, j])
	return lista


## Compara con lo ultimo que este hermano vio: el color que vuelve y la zona que despierta se
## celebran con animacion y voz. La primera visita da la bienvenida.
func _celebrar_cambios() -> void:
	var previo: Variant = _visto.get(_clave(), null)
	_marcar_visto()
	var voces: Dictionary = mapa.get("voces", {})
	if previo == null:
		_decir_en_orden([_voz_de(voces.get("bienvenida", ""))], 0.5)
		return
	var lista: Array = []
	var todas_completas := true
	var alguna_nueva := false
	for i in zonas.size():
		todas_completas = todas_completas and zonas[i]["completa"]
		if zonas[i]["completa"] and not previo["completas"][i]:
			alguna_nueva = true
			for banda in zonas[i]["datos"].get("bandas", []):
				_avance_bandas[banda] = 0.0
			# Orden del guion (zonas_arcoiris.md §1): completada (Coco) -> regalo (Coco).
			lista.append(_voz_de(zonas[i]["datos"].get("voz_completada", "")))
			lista.append(_voz_de(zonas[i]["datos"].get("voz_regalo", "")))
			_despues(0.6, _fiesta_zona.bind(i))
	for i in zonas.size():
		if zonas[i]["abierta"] and not previo["abiertas"][i]:
			seleccion = i
			var abierta := _voz_de(zonas[i]["datos"].get("voz_abierta", ""))
			if zonas[i]["secreta"] or abierta == "":
				abierta = _voz_de(voces.get("secreta_revelada" if zonas[i]["secreta"] else "zona_abierta", ""))
			lista.append(abierta)
			_despues(0.9, _fiesta_zona.bind(i))
	if todas_completas and alguna_nueva:
		lista.append(_voz_de(voces.get("planeta_completo", "")))
	for clave in _visto[_clave()].get("dorados", []):
		if not previo.get("dorados", []).has(clave):
			seleccion = int(str(clave).get_slice("_", 0))
			lista.append(str(voces.get("dorado_disponible", "")))
			break
	lista = lista.filter(func(r) -> bool: return str(r) != "")
	if not lista.is_empty():
		_reproducir_sfx(SFX_FIESTA)
		_celebrando = true
		await _decir_en_orden(lista, 0.6)
		_celebrando = false
	celebracion_zona_terminada.emit()


## Una clave de voz del mapa puede ser una ruta o una lista de variantes (se elige una al azar).
func _voz_de(valor) -> String:
	if valor is Array:
		return str(valor.pick_random()) if not valor.is_empty() else ""
	return str(valor)


func celebrando() -> bool:
	return _celebrando


# ---------------------------------------------------------------------------
# Recuerdos del album "Las migas de papa" (docs/fichas/album-recuerdos.md §4)
# ---------------------------------------------------------------------------

## Evento GENERICO de zona completa: el catalogo de recuerdos decide si toca una foto (este mapa
## no sabe cuales zonas dan foto ni de quien). `perfecta` = estrellitas maximas en todas las
## estaciones de nivel Estrella QUE PUNTUAN (marco dorado de Sofia). Pinta no tiene puntaje y no cuenta
## (disenador-niveles HE-40 §2.4, auditoria UX HE-44 R4): antes el marco era inalcanzable.
func evento_zona(i: int) -> Dictionary:
	var zona: Dictionary = zonas[i]
	var perfecta := false
	var con_puntaje: Array = zona["estaciones"].filter(func(e: Dictionary) -> bool: return e["jugable"] and e["puntua"])
	if not con_puntaje.is_empty():
		perfecta = con_puntaje.all(func(e: Dictionary) -> bool: return e["perfil_nivel"] == "estrella" and int(e["estrellitas"]) >= 3)
	return {"tipo": "zona_completa", "planeta": planeta_id, "zona": str(zona["datos"].get("id", "")),
		"numero": int(zona["datos"].get("numero", i + 1)), "perfecta": perfecta}


## Cada vez que se entra al mapa se avisan las zonas completas; `Recuerdos.desbloquear` es
## idempotente, asi que solo lo nuevo se entrega (tambien lo completado antes de existir el album:
## nada se pierde). La entrega espera a que termine la celebracion de la zona y recien ahi guarda.
func _entregar_recuerdos_zonas() -> void:
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null or id_perfil == "":
		return
	var eventos: Array = []
	var hay_algo := false
	for i in zonas.size():
		if zonas[i]["completa"]:
			var evento := evento_zona(i)
			eventos.append(evento)
			hay_algo = hay_algo or evento["perfecta"] or not recuerdos.pendientes(evento, id_perfil).is_empty()
	if not hay_algo:
		return
	# Espera la celebracion COMPLETA de la zona (completada -> regalo -> zona que despierta), no solo el
	# clip que suena, con tope de 15 s (HE-44 mecanicas #10, UX R11). Despues, una pausa corta.
	await get_tree().create_timer(1.2).timeout
	var espera := 0.0
	var audio := get_node_or_null("/root/Audio")
	while is_inside_tree() and espera < 15.0 and (_celebrando or (audio != null and audio.esta_hablando())):
		await get_tree().create_timer(0.25).timeout
		espera += 0.25
	if not is_inside_tree() or _lanzando:
		# UX R3: si el nino ya lanzo un juego, la foto NO se desbloquea ahora (se perderia el momento con
		# el cambio de escena): llega la proxima vez que entre al mapa. Nada se pierde.
		return
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree() or _lanzando:
		return
	# Se guarda recien ahora, al mostrarse: si el nino salio antes, la foto llega la proxima vez.
	# Tope de sobres por entrega (HE-44 #7): el resto llega la proxima vez que entre al mapa.
	var nuevos: Array = []
	var tope: int = load("res://scripts/ui/entrega_recuerdo.gd").TOPE_SOBRES
	for evento in eventos:
		if nuevos.size() >= tope:
			break
		nuevos.append_array(recuerdos.desbloquear(evento, id_perfil, tope - nuevos.size()))
	if nuevos.is_empty():
		return
	var entrega: Node = load("res://scripts/ui/entrega_recuerdo.gd").crear(nuevos)
	entrega.name = "entrega_recuerdo"
	# Al completar una zona, la foto llega "con el viento" tras el regalo de Coco (guion recuerdos §1.2b).
	var linea_zona: String = recuerdos.elegir_linea("entrega_zona")
	if linea_zona != "":
		entrega.voz_sobre = linea_zona
	_entrega = entrega
	add_child(entrega)


## Mientras la entrega del album esta en pantalla, el mapa no lanza juegos ni navega (UX HE-44 R3).
func _entrega_activa() -> bool:
	return _entrega != null and is_instance_valid(_entrega) and _entrega.esta_activa()


# ---------------------------------------------------------------------------
# Construccion de la pantalla
# ---------------------------------------------------------------------------

func _construir_ui() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ruta_paisaje := str(mapa.get("paisaje", ""))
	if ruta_paisaje != "" and ResourceLoader.exists(ruta_paisaje):
		_paisaje = (load(ruta_paisaje) as Script).new()
		_paisaje.name = "paisaje"
		_ui.add_child(_paisaje)
		_paisaje.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_paisaje.actualizar(zonas)
	else:
		_construir_fondo()

	_camino = _control_dibujo(Rect2(0, 0, 1280, 720), _dibujar_camino)
	if _paisaje != null and _paisaje.has_method("capa_arcoiris"):
		# El arcoiris grande va en el cielo del paisaje, detras de las nubes y las colinas.
		_arcoiris = _control_dibujo(Rect2(0, 0, 1280, 720), _dibujar_arcoiris)
		_arcoiris.reparent(_paisaje.capa_arcoiris(), false)
	else:
		_arcoiris = _control_dibujo(Rect2(440, 6, 400, 160), _dibujar_arcoiris)

	for i in zonas.size():
		var centro := _centro_zona(i)
		var nodo := _control_dibujo(Rect2(centro - Vector2.ONE * LADO_ZONA / 2.0, Vector2.ONE * LADO_ZONA), _dibujar_zona.bind(i))
		nodo.mouse_filter = Control.MOUSE_FILTER_STOP
		nodo.pivot_offset = nodo.size / 2.0
		nodo.gui_input.connect(_al_tocar.bind(_tocar_zona.bind(i)))
		nodo.tooltip_text = str(zonas[i]["datos"].get("nombre", ""))
		_nodos_zona.append(nodo)
		var etiqueta := _pildora(str(zonas[i]["datos"].get("nombre", "")), 22)
		etiqueta.name = "etiqueta_zona_%d" % i
		etiqueta.set_meta("pie", centro + Vector2(0, LADO_ZONA / 2.0 + 6.0))
		nodo.set_meta("etiqueta", etiqueta)

	var ruta_coco := str(mapa.get("anfitrion", ""))
	_anfitriona = TextureRect.new()
	if ResourceLoader.exists(ruta_coco):
		_anfitriona.texture = load(ruta_coco)
	_anfitriona.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_anfitriona.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anfitriona.position = Vector2(34, 452)
	_anfitriona.size = Vector2(172, 256)
	_anfitriona.pivot_offset = Vector2(86, 256)
	_anfitriona.tooltip_text = "Coco: toca para escuchar de nuevo"
	_anfitriona.gui_input.connect(_al_tocar.bind(_tocar_coco))
	_ui.add_child(_anfitriona)
	_base_coco = _anfitriona.position

	_boton_salir = _boton(Rect2(20, 16, 96, 96), COLOR_PILDORA, "Volver al mapa estelar")
	var flecha := Control.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_salir.add_child(flecha)
	flecha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flecha.draw.connect(_dibujar_flecha.bind(flecha))
	_boton_salir.pressed.connect(_volver_al_mapa_estelar)
	_construir_retrato_hermano()
	var pieza: Dictionary = mapa.get("pieza_nave", {})
	if not (pieza.get("zonas", []) as Array).is_empty():
		var pos: Array = pieza.get("posicion", [430, 105])
		_pieza = _control_dibujo(Rect2(Vector2(float(pos[0]), float(pos[1])) - Vector2(80, 50), Vector2(160, 100)), _dibujar_pieza)
		_pieza.pivot_offset = _pieza.size / 2.0

	# Cometa flota sin disco, como en el menu de planetas.
	_boton_cometa = _boton(Rect2(1110, 556, 150, 160), Color.TRANSPARENT, "Cometa: vamos al siguiente juego")
	for estado in ["normal", "hover", "pressed", "disabled"]:
		_boton_cometa.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	var retrato_cometa := TextureRect.new()
	if ResourceLoader.exists(RUTA_COMETA):
		retrato_cometa.texture = load(RUTA_COMETA)
	retrato_cometa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato_cometa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato_cometa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_cometa.add_child(retrato_cometa)
	retrato_cometa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boton_cometa.pressed.connect(_tocar_cometa)
	_base_cometa = _boton_cometa.position

	_construir_burbuja()
	_efectos = Control.new()
	_efectos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_efectos)
	_efectos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Capa modal de las estaciones: velo que oscurece el mundo (tocarlo cierra), la burbuja con su
## cola hacia la zona, el nombre de la zona, la X (96 px) y una esfera por estacion.
func _construir_burbuja() -> void:
	_modal = Control.new()
	_modal.name = "burbuja_estaciones"
	_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_modal)
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.hide()
	_velo = ColorRect.new()
	_velo.color = Color(0.16, 0.07, 0.32, 0.5)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(_velo)
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.gui_input.connect(_al_tocar.bind(_cerrar_burbuja))
	_burbuja = Control.new()
	_burbuja.mouse_filter = Control.MOUSE_FILTER_STOP
	_burbuja.size = TAMANO_BURBUJA
	_burbuja.draw.connect(_dibujar_burbuja)
	_modal.add_child(_burbuja)
	_titulo_zona = Label.new()
	_titulo_zona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(RUTA_FUENTE):
		_titulo_zona.add_theme_font_override("font", load(RUTA_FUENTE))
	_titulo_zona.add_theme_font_size_override("font_size", 30)
	_titulo_zona.add_theme_color_override("font_color", Color.WHITE)
	_titulo_zona.add_theme_color_override("font_shadow_color", Color(0.12, 0.03, 0.24, 0.45))
	_titulo_zona.add_theme_constant_override("shadow_offset_y", 3)
	_titulo_zona.position = Vector2(32, 12)
	_titulo_zona.size = Vector2(470, 44)
	_burbuja.add_child(_titulo_zona)
	_boton_cerrar = Button.new()
	_boton_cerrar.focus_mode = Control.FOCUS_NONE
	_boton_cerrar.tooltip_text = "Cerrar"
	_boton_cerrar.position = Vector2(TAMANO_BURBUJA.x - 100, -4)
	_boton_cerrar.size = Vector2(96, 96)
	for estado in ["normal", "hover", "pressed"]:
		_boton_cerrar.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	_boton_cerrar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_boton_cerrar.draw.connect(func() -> void:
		var c := _boton_cerrar.size / 2.0
		_boton_cerrar.draw_circle(c, 29.0, Color(1, 1, 1, 0.16))
		_boton_cerrar.draw_arc(c, 29.0, 0.0, TAU, 40, Color(1, 1, 1, 0.45), 2.5, true)
		for lado in [-1.0, 1.0]:
			_boton_cerrar.draw_line(c + Vector2(-8, -8 * lado), c + Vector2(8, 8 * lado), Color.WHITE, 5.0, true))
	_boton_cerrar.pressed.connect(_cerrar_burbuja)
	_burbuja.add_child(_boton_cerrar)

	for j in 4:
		var tarjeta := Control.new()
		tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
		tarjeta.size = Vector2.ONE * LADO_ORBE
		tarjeta.pivot_offset = tarjeta.size / 2.0
		tarjeta.draw.connect(_dibujar_tarjeta.bind(tarjeta, j))
		tarjeta.gui_input.connect(_al_tocar.bind(_tocar_estacion.bind(j)))
		_modal.add_child(tarjeta)
		_tarjetas.append(tarjeta)
		# Boton del reto dorado: corona sobre la esfera (>= 96 px, GDD §6.1).
		var dorado := Button.new()
		dorado.focus_mode = Control.FOCUS_NONE
		dorado.tooltip_text = "Reto dorado"
		dorado.custom_minimum_size = Vector2(96, 96)
		tarjeta.add_child(dorado)
		dorado.position = Vector2(LADO_ORBE / 2.0 - 48.0, -74.0)
		dorado.size = Vector2(96, 96)
		dorado.pivot_offset = dorado.size / 2.0
		for estado in ["normal", "hover", "pressed"]:
			var caja := StyleBoxFlat.new()
			caja.bg_color = DORADO.darkened(0.1) if estado == "pressed" else DORADO
			caja.border_color = COLOR_CONTORNO
			caja.set_border_width_all(5)
			caja.set_corner_radius_all(48)
			caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
			caja.shadow_offset = Vector2(0, 5)
			caja.shadow_size = 2
			dorado.add_theme_stylebox_override(estado, caja)
		dorado.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var icono := Control.new()
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dorado.add_child(icono)
		icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icono.draw.connect(func() -> void:
			var c := icono.size / 2.0
			Figura.dibujar(icono, "estrella", Color("#FFF3B0"), c + Vector2(0, 4), 30.0, true, true)
			for p in [Vector2(-32, -28), Vector2(32, -24)]:
				var chispa := Figura.poligono("estrella", c + p, 9.0)
				icono.draw_colored_polygon(chispa, Color.WHITE)
				Figura.contornear(icono, chispa, 2.0))
		dorado.pressed.connect(_tocar_dorado.bind(j))
		# UX R9: respuesta inmediata al presionar (aplastado + sonido), como los demas botones.
		dorado.button_down.connect(func() -> void:
			_reproducir_sfx(SFX_TOQUE)
			dorado.scale = Vector2(0.9, 0.9)
			dorado.create_tween().tween_property(dorado, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
		dorado.hide()
		tarjeta.set_meta("dorado", dorado)


func _construir_fondo() -> void:
	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -1
	add_child(capa_fondo)
	var fondo := TextureRect.new()
	var ruta_fondo := str(mapa.get("fondo", ""))
	if ResourceLoader.exists(ruta_fondo):
		fondo.texture = load(ruta_fondo)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var velo := ColorRect.new()
	velo.color = Color(0.23, 0.16, 0.42, 0.38)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _control_dibujo(rect: Rect2, dibujo: Callable) -> Control:
	var control := Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.position = rect.position
	control.size = rect.size
	control.draw.connect(func() -> void: dibujo.call(control))
	_ui.add_child(control)
	return control


## Nombre en una pildora oscura translucida, como los planetas del Mapa Estelar (Sofia lee; los
## chicos se guian por la voz).
func _pildora(texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(RUTA_FUENTE):
		etiqueta.add_theme_font_override("font", load(RUTA_FUENTE))
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", Color.WHITE)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = COLOR_PILDORA
	fondo.border_color = Color(1, 1, 1, 0.2)
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(22)
	fondo.content_margin_left = 18
	fondo.content_margin_right = 18
	fondo.content_margin_top = 1
	fondo.content_margin_bottom = 3
	fondo.shadow_color = Color(0.24, 0.08, 0.35, 0.2)
	fondo.shadow_size = 6
	fondo.shadow_offset = Vector2(0, 4)
	etiqueta.add_theme_stylebox_override("normal", fondo)
	_ui.add_child(etiqueta)
	return etiqueta


## Ubica la pildora centrada bajo `pie` (su ancho cambia con el texto).
func _centrar_pildora(etiqueta: Label) -> void:
	etiqueta.reset_size()
	var pie: Vector2 = etiqueta.get_meta("pie", etiqueta.position)
	etiqueta.position = pie - Vector2(etiqueta.size.x / 2.0, 0)


## Boton redondo. Con fondo translucido toma el estilo del HUD del menu de planetas (borde blanco
## suave); con fondo opaco, el del juego (contorno azul noche).
func _boton(rect: Rect2, fondo: Color, ayuda: String) -> Button:
	var boton := Button.new()
	boton.position = rect.position
	boton.size = rect.size
	boton.custom_minimum_size = rect.size
	boton.focus_mode = Control.FOCUS_NONE
	boton.tooltip_text = ayuda
	var translucido := fondo.a < 1.0
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = fondo.darkened(0.12) if estado == "pressed" else fondo
		caja.border_color = Color(1, 1, 1, 0.3) if translucido else COLOR_CONTORNO
		caja.set_border_width_all(3 if translucido else 5)
		caja.set_corner_radius_all(64)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.18 if translucido else 0.3)
		caja.shadow_offset = Vector2(0, 5)
		caja.shadow_size = 2
		boton.add_theme_stylebox_override(estado, caja)
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	boton.button_down.connect(func() -> void:
		boton.pivot_offset = boton.size / 2.0
		boton.scale = Vector2(0.9, 0.9)
		boton.create_tween().tween_property(boton, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_ui.add_child(boton)
	return boton


## Quien juega, arriba a la izquierda, como en el menu de planetas: pildora con el retrato del
## hermano en un disco de su color, su nombre y sus destellos.
func _construir_retrato_hermano() -> void:
	var color: Color = COLORES_HERMANO.get(id_perfil, Color.WHITE)
	var progreso := get_node_or_null("/root/Progreso")
	var nombre := id_perfil.capitalize()
	var destellos := ""
	if progreso != null:
		nombre = str(progreso.obtener_perfil(id_perfil).get("nombre", nombre))
		destellos = str(progreso.obtener_destellos_totales(id_perfil))
	var pildora := Panel.new()
	pildora.name = "hud_hermano"
	pildora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = COLOR_PILDORA
	fondo.border_color = Color(1, 1, 1, 0.24)
	fondo.set_border_width_all(3)
	fondo.set_corner_radius_all(40)
	pildora.add_theme_stylebox_override("panel", fondo)
	pildora.position = Vector2(132, 24)
	_ui.add_child(pildora)
	var disco := Control.new()
	disco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disco.position = Vector2(8, 8)
	disco.size = Vector2(64, 64)
	disco.draw.connect(func() -> void:
		disco.draw_circle(disco.size / 2.0, 32.0, Color("#FFF8EE"))
		disco.draw_arc(disco.size / 2.0, 30.0, 0.0, TAU, 40, color, 5.0, true))
	pildora.add_child(disco)
	var retrato := TextureRect.new()
	var ruta: String = RETRATOS_HERMANO.get(id_perfil, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		# solo la cara del retrato oficial (512x768, mismo recorte que el mapa estelar)
		# (imagen recortada, no AtlasTexture: la mascara circular usa las UV de la textura)
		var imagen: Image = (load(ruta) as Texture2D).get_image()
		retrato.texture = ImageTexture.create_from_image(imagen.get_region(Rect2i(146, 62, 220, 220)))
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retrato.position = Vector2(6, 6)
	retrato.size = Vector2(52, 52)
	var mascara := ShaderMaterial.new()
	mascara.shader = load("res://assets/shaders/disco_circular.gdshader")
	retrato.material = mascara
	retrato.clip_contents = true
	disco.add_child(retrato)
	var x := 86.0
	var texto_nombre := _texto_hud(nombre, 32, Color.WHITE)
	pildora.add_child(texto_nombre)
	texto_nombre.position = Vector2(x, 10)
	x += texto_nombre.size.x + 22.0
	if destellos != "":
		var estrella := Control.new()
		estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
		estrella.position = Vector2(x, 22)
		estrella.size = Vector2(34, 34)
		estrella.draw.connect(func() -> void:
			estrella.draw_colored_polygon(Figura.poligono("estrella", estrella.size / 2.0, 16.0), DORADO))
		pildora.add_child(estrella)
		var texto_destellos := _texto_hud(destellos, 30, DORADO)
		pildora.add_child(texto_destellos)
		texto_destellos.position = Vector2(x + 42.0, 11)
		x += 42.0 + texto_destellos.size.x
	pildora.size = Vector2(x + 24.0, 80)


func _texto_hud(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(RUTA_FUENTE):
		etiqueta.add_theme_font_override("font", load(RUTA_FUENTE))
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.reset_size()
	return etiqueta


func _refrescar() -> void:
	for nodo in _nodos_zona:
		nodo.queue_redraw()
	_camino.queue_redraw()
	_arcoiris.queue_redraw()
	if _pieza != null:
		_pieza.queue_redraw()
	_mostrar_estaciones()


func _mostrar_estaciones() -> void:
	_zona_elegida[_clave()] = seleccion
	_siguiente = siguiente_estacion()
	var estaciones: Array = zonas[seleccion]["estaciones"]
	_ubicar_burbuja()
	for j in _tarjetas.size():
		_tarjetas[j].visible = j < estaciones.size()
		_tarjetas[j].queue_redraw()
		var dorado: Button = _tarjetas[j].get_meta("dorado")
		dorado.visible = j < estaciones.size() and zonas[seleccion]["abierta"] and estaciones[j]["dorado_disponible"]
	for i in _nodos_zona.size():
		var etiqueta: Label = _nodos_zona[i].get_meta("etiqueta")
		var escondida: bool = zonas[i]["secreta"] and not zonas[i]["abierta"]
		if _paisaje != null:
			# La Cima se ve dormida a lo lejos, sin decir su nombre: un adelanto, nunca un muro.
			etiqueta.text = "???" if escondida else str(zonas[i]["datos"].get("nombre", ""))
			etiqueta.visible = true
		else:
			etiqueta.visible = not escondida
		etiqueta.modulate.a = 1.0 if zonas[i]["abierta"] else 0.6
		_centrar_pildora(etiqueta)


# ---------------------------------------------------------------------------
# Burbuja de estaciones (nace de la zona tocada)
# ---------------------------------------------------------------------------

## Posicion de la burbuja y de las esferas para la zona elegida: debajo de la zona si cabe, si no
## encima; la cola apunta a la zona. Las esferas quedan en su lugar aunque la burbuja este cerrada.
func _ubicar_burbuja() -> void:
	var centro := _centro_zona(seleccion)
	var izquierda := clampf(centro.x - TAMANO_BURBUJA.x / 2.0, 24.0, 1280.0 - 24.0 - TAMANO_BURBUJA.x)
	_cola_arriba = centro.y + LADO_ZONA / 2.0 + 4.0 + TAMANO_BURBUJA.y <= 716.0
	var arriba := centro.y + LADO_ZONA / 2.0 + 4.0 if _cola_arriba else centro.y - LADO_ZONA / 2.0 - 22.0 - TAMANO_BURBUJA.y
	arriba = clampf(arriba, 16.0, 720.0 - 16.0 - TAMANO_BURBUJA.y)
	_burbuja.position = Vector2(izquierda, arriba)
	_cola = Vector2(clampf(centro.x - izquierda, 60.0, TAMANO_BURBUJA.x - 60.0), 0.0 if _cola_arriba else TAMANO_BURBUJA.y)
	_burbuja.pivot_offset = _cola
	_titulo_zona.text = str(zonas[seleccion]["datos"].get("nombre", ""))
	var cantidad := mini(_tarjetas.size(), (zonas[seleccion]["estaciones"] as Array).size())
	var primera := izquierda + TAMANO_BURBUJA.x / 2.0 - (cantidad - 1) * PASO_ORBES / 2.0
	for j in _tarjetas.size():
		var tarjeta: Control = _tarjetas[j]
		var lugar := Vector2(primera + j * PASO_ORBES, arriba + 130.0) - tarjeta.size / 2.0
		tarjeta.set_meta("lugar", lugar)
		if not _modal_abierto:
			tarjeta.position = lugar
	_burbuja.queue_redraw()


func _abrir_burbuja(i: int) -> void:
	_cerrar_burbuja(false)
	seleccion = i
	_mostrar_estaciones()
	_modal_abierto = true
	_modal.show()
	_modal.modulate.a = 1.0
	_velo.modulate.a = 0.0
	_velo.create_tween().tween_property(_velo, "modulate:a", 1.0, 0.25)
	# La zona elegida queda sobre el velo, un poco mas grande.
	var nodo: Control = _nodos_zona[i]
	nodo.z_index = 1
	nodo.create_tween().tween_property(nodo, "scale", Vector2.ONE * 1.12, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burbuja.scale = Vector2.ONE * 0.15
	_burbuja.modulate.a = 0.0
	var pop := _burbuja.create_tween().set_parallel(true)
	pop.tween_property(_burbuja, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_burbuja, "modulate:a", 1.0, 0.2)
	# Las esferas salen de la zona, una tras otra.
	var origen := _centro_zona(i) - Vector2.ONE * LADO_ORBE / 2.0
	for j in _tarjetas.size():
		var tarjeta: Control = _tarjetas[j]
		var lugar: Vector2 = tarjeta.get_meta("lugar", tarjeta.position)
		tarjeta.position = origen
		tarjeta.scale = Vector2.ONE * 0.15
		tarjeta.modulate.a = 0.0
		var sale := tarjeta.create_tween().set_parallel(true)
		var espera := 0.12 + j * 0.07
		sale.tween_property(tarjeta, "position", lugar, 0.5).set_delay(espera).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sale.tween_property(tarjeta, "scale", Vector2.ONE, 0.5).set_delay(espera).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sale.tween_property(tarjeta, "modulate:a", 1.0, 0.2).set_delay(espera)


func _cerrar_burbuja(con_sonido := true) -> void:
	if not _modal_abierto:
		return
	_modal_abierto = false
	if con_sonido:
		_reproducir_sfx(SFX_TOQUE)
	for nodo: Control in _nodos_zona:
		if nodo.z_index != 0:
			nodo.z_index = 0
			nodo.create_tween().tween_property(nodo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for tarjeta: Control in _tarjetas:
		tarjeta.position = tarjeta.get_meta("lugar", tarjeta.position)
		tarjeta.scale = Vector2.ONE
		tarjeta.modulate.a = 1.0
	if con_sonido:
		var tween := _modal.create_tween()
		tween.tween_property(_modal, "modulate:a", 0.0, 0.18)
		tween.tween_callback(func() -> void:
			if not _modal_abierto:
				_modal.hide())
	else:
		_modal.hide()
	for nodo in _nodos_zona:
		nodo.queue_redraw()


## Burbuja oscura con borde suave (como las pildoras del menu) y una cola que apunta a la zona.
func _dibujar_burbuja() -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = COLOR_BURBUJA
	caja.border_color = Color(1, 1, 1, 0.3)
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(46)
	caja.anti_aliasing = true
	caja.shadow_color = Color(0.12, 0.02, 0.24, 0.4)
	caja.shadow_size = 24
	caja.shadow_offset = Vector2(0, 14)
	_burbuja.draw_style_box(caja, Rect2(Vector2.ZERO, TAMANO_BURBUJA))
	var sentido := -1.0 if _cola_arriba else 1.0
	var borde := Vector2(_cola.x, _cola.y)
	var punta := borde + Vector2(0, 24.0 * sentido)
	var izquierda := borde + Vector2(-26, -1.5 * sentido)
	var derecha := borde + Vector2(26, -1.5 * sentido)
	_burbuja.draw_colored_polygon(PackedVector2Array([izquierda, punta, derecha]), COLOR_BURBUJA)
	_burbuja.draw_polyline(PackedVector2Array([izquierda + Vector2(0, 1.5 * sentido), punta, derecha + Vector2(0, 1.5 * sentido)]), Color(1, 1, 1, 0.3), 3.0, true)
	# Halo suave alrededor, como el anillo de la burbuja de la maqueta.
	var halo := StyleBoxFlat.new()
	halo.draw_center = false
	halo.border_color = Color(1, 0.84, 0.94, 0.08)
	halo.set_border_width_all(10)
	halo.set_corner_radius_all(56)
	halo.expand_margin_left = 10
	halo.expand_margin_right = 10
	halo.expand_margin_top = 10
	halo.expand_margin_bottom = 10
	_burbuja.draw_style_box(halo, Rect2(Vector2.ZERO, TAMANO_BURBUJA))


# ---------------------------------------------------------------------------
# Interaccion
# ---------------------------------------------------------------------------

func _al_tocar(evento: InputEvent, accion: Callable) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		accion.call()


func _tocar_zona(i: int) -> void:
	if _lanzando or _entrega_activa():
		return
	var nodo: Control = _nodos_zona[i]
	var voces: Dictionary = mapa.get("voces", {})
	if not zonas[i]["abierta"]:
		_reproducir_sfx(SFX_NO)
		_menear(nodo)
		_decir(_voz_de(voces.get("secreta_lejana" if zonas[i]["secreta"] else "zona_dormida", "")))
		return
	_reproducir_sfx(SFX_ELEGIR)
	_abrir_burbuja(i)
	_decir(str(zonas[i]["datos"].get("voz_llegada", "")))


func _tocar_estacion(j: int) -> void:
	if _lanzando or _entrega_activa() or j >= zonas[seleccion]["estaciones"].size():
		return
	var estacion: Dictionary = zonas[seleccion]["estaciones"][j]
	var tarjeta: Control = _tarjetas[j]
	if not estacion["jugable"]:
		_reproducir_sfx(SFX_NO)
		_menear(tarjeta)
		_decir(str(mapa.get("voces", {}).get("estacion_pronto", "")))
		return
	lanzar_estacion(seleccion, j)


func _tocar_coco() -> void:
	_reproducir_sfx(SFX_TOQUE)
	var tween := create_tween()
	tween.tween_property(self, "_salto_coco", 40.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_salto_coco", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_decir(str(zonas[seleccion]["datos"].get("voz_llegada", "")))


## Cometa lleva directo a la siguiente estacion pendiente (un toque, sin navegar).
func _tocar_cometa() -> void:
	if _lanzando or _entrega_activa():
		return
	_reproducir_sfx(SFX_TOQUE)
	var voces: Dictionary = mapa.get("voces", {})
	var destino := siguiente_estacion()
	if destino[0] < 0:
		_decir(str(voces.get("todo_listo", "")))
		return
	# La burbuja de esa zona se abre y la esfera que sigue late antes de lanzarse.
	_abrir_burbuja(destino[0])
	_decir(str(voces.get("cometa_vamos", "")))
	lanzar_estacion(destino[0], destino[1], 1.4)


func _tocar_dorado(j: int) -> void:
	if _lanzando or _entrega_activa() or j >= zonas[seleccion]["estaciones"].size():
		return
	lanzar_estacion(seleccion, j, 0.0, true)


## Abre el motor de una estacion con el contrato de minijuego_base. Al terminar o salir se vuelve a
## este mapa (la escena se recarga y celebra lo que cambio). `dorado` abre su reto dorado.
func lanzar_estacion(i: int, j: int, espera := 0.0, dorado := false) -> void:
	var estacion: Dictionary = zonas[i]["estaciones"][j]
	if not estacion["jugable"] or (dorado and estacion["dorado_ruta"] == ""):
		return
	_lanzando = true
	_zona_elegida[_clave()] = i
	var tarjeta: Control = _tarjetas[j]
	_reproducir_sfx(SFX_ELEGIR)
	var tween := tarjeta.create_tween()
	tween.tween_property(tarjeta, "scale", Vector2(1.12, 0.9), 0.1)
	tween.tween_property(tarjeta, "scale", Vector2.ONE * 1.06, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if espera <= 0.0:
		var juego: Dictionary = mapa.get("juegos", {}).get(estacion["juego"], {})
		var voces: Dictionary = mapa.get("voces", {})
		# La voz dice lo que el nino va a ver: el taller de Sofia no es "Lluvia de colores" (guion §1.6).
		var voz := _voz_de(juego.get("voces_perfil", {}).get(id_perfil, juego.get("voz", "")))
		if dorado and voces.has("dorado_entrar"):
			voz = _voz_de(voces["dorado_entrar"])
		elif estacion["completada"] and voces.has("estacion_repetida"):
			voz = _voz_de(voces["estacion_repetida"])
		_decir(voz)
		espera = 0.9
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree():
		return
	var escena: PackedScene = load(estacion["escena"])
	var motor: Node = escena.instantiate()
	motor.ruta_nivel = estacion["dorado_ruta"] if dorado else estacion["ruta_nivel"]
	motor.planeta_id = planeta_id
	motor.id_perfil = id_perfil
	# Economia (HE-40 §2.3): monto fijo e igual para los tres; los retos dorados no dan destellos.
	var clave_destellos := "destellos_reto_dorado" if dorado else "destellos_por_estacion"
	if mapa.has(clave_destellos) and "destellos_fijos" in motor:
		motor.destellos_fijos = int(mapa[clave_destellos])
	var arbol := get_tree()
	var volver := Callable(arbol, "change_scene_to_file").bind(scene_file_path if scene_file_path != "" else "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn")
	motor.completado.connect(volver.unbind(1), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	motor.salir_solicitado.connect(volver, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()
	arbol.root.add_child(motor)
	arbol.current_scene = motor
	queue_free()


func _volver_al_mapa_estelar() -> void:
	if _entrega_activa():
		return
	# UX R15: F4 nunca queda activo al salir del planeta.
	todo_abierto = false
	_reproducir_sfx(SFX_TOQUE)
	get_tree().change_scene_to_file(RUTA_MAPA_ESTELAR)


# ---------------------------------------------------------------------------
# Voz, sonido y animaciones
# ---------------------------------------------------------------------------

func _decir(ruta: String) -> void:
	_id_voces += 1
	_reproducir_voz(ruta)


func _reproducir_voz(ruta: String) -> void:
	if ruta == "":
		return
	print("[voz:mapa] %s" % ruta)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta if ruta.begins_with("res://") else PREFIJO_AUDIO + ruta)


func _reproducir_sfx(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)


## Varias lineas seguidas (una espera a la otra). Un toque nuevo del nino corta la secuencia.
func _decir_en_orden(rutas: Array, retraso: float) -> void:
	_id_voces += 1
	var id := _id_voces
	await get_tree().create_timer(retraso).timeout
	for ruta in rutas:
		if id != _id_voces or not is_inside_tree():
			return
		_reproducir_voz(str(ruta))
		await get_tree().create_timer(_duracion(str(ruta)) + 0.35).timeout


func _duracion(ruta: String) -> float:
	var final := ruta if ruta.begins_with("res://") else PREFIJO_AUDIO + ruta
	if ruta == "" or not ResourceLoader.exists(final):
		return 0.5
	var stream := load(final) as AudioStream
	return stream.get_length() if stream != null else 0.5


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()


func _rebotar(nodo: Control) -> void:
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "scale", Vector2(1.14, 0.9), 0.08)
	tween.tween_property(nodo, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _menear(nodo: Control) -> void:
	var tween := nodo.create_tween()
	for angulo in [-7.0, 7.0, -4.0, 0.0]:
		tween.tween_property(nodo, "rotation", deg_to_rad(angulo), 0.08)


func _fiesta_zona(i: int) -> void:
	if _pieza != null and (mapa.get("pieza_nave", {}).get("zonas", []) as Array).has(float(i + 1)):
		# Se pinta otro pedacito del ala: late para que Maxi vea que se acerca (HE-40 mecanicas #3).
		_pieza.scale = Vector2.ONE * 0.7
		_pieza.create_tween().tween_property(_pieza, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var nodo: Control = _nodos_zona[i]
	nodo.scale = Vector2.ONE * 0.6
	nodo.create_tween().tween_property(nodo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var centro := nodo.position + nodo.size / 2.0
	for k in 12:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = Figura.COLORES_ARCOIRIS[k % Figura.COLORES_ARCOIRIS.size()]
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(22.0, 36.0)
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.position = centro - chispa.size / 2.0
		var destino := chispa.position + Vector2.from_angle(TAU * k / 12.0) * randf_range(90.0, 140.0)
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _centro_zona(i: int) -> Vector2:
	var posicion: Array = zonas[i]["datos"].get("posicion", [0, 0])
	return Vector2(float(posicion[0]), float(posicion[1]))


func _dibujar_camino(control: Control) -> void:
	if _paisaje != null:
		var centros: Array = []
		for i in zonas.size():
			centros.append(_centro_zona(i))
		_paisaje.dibujar_camino(control, zonas, centros)
		return
	for i in range(1, zonas.size()):
		if zonas[i]["secreta"] and not zonas[i]["abierta"]:
			continue
		var a := _centro_zona(i - 1)
		var b := _centro_zona(i)
		var control_medio := (a + b) / 2.0 + Vector2(0, 70.0 if i % 2 == 1 else -70.0)
		var color := Color(1, 1, 1, 0.9) if zonas[i]["abierta"] else Color(1, 1, 1, 0.32)
		var pasos := 16
		for k in range(2, pasos - 1):
			var t := k / float(pasos)
			var punto := a.lerp(control_medio, t).lerp(control_medio.lerp(b, t), t)
			control.draw_circle(punto, 7.0, color)


func _dibujar_arcoiris(control: Control) -> void:
	var base := Vector2(200, 150)
	var ancho := 17.0
	var exterior := 136.0
	var apagada := Color(1, 1, 1, 0.22)
	var con_nubes := true
	if _paisaje != null and _paisaje.has_method("geometria_arcoiris"):
		# Arcoiris grande del cielo del paisaje: sin contorno ni nubes con carita.
		var geometria: Dictionary = _paisaje.geometria_arcoiris()
		base = geometria.get("centro", base)
		ancho = float(geometria.get("ancho", ancho))
		exterior = float(geometria.get("radio", exterior))
		apagada = geometria.get("apagada", apagada)
		con_nubes = false
	var encendidas := {}
	for zona in zonas:
		if zona["completa"]:
			for banda in zona["datos"].get("bandas", []):
				encendidas[banda] = true
	for k in BANDAS.size():
		var banda: String = BANDAS[k]
		var radio := exterior - ancho * (k + 0.5)
		control.draw_arc(base, radio, PI, TAU, 96, apagada, ancho, true)
		if encendidas.has(banda):
			var avance := 1.0
			if _avance_bandas.has(banda):
				_avance_bandas[banda] = minf(1.0, _avance_bandas[banda] + get_process_delta_time() / 1.2)
				avance = _avance_bandas[banda]
				if avance >= 1.0:
					_avance_bandas.erase(banda)
			control.draw_arc(base, radio, PI, PI + PI * avance, 96, COLOR_BANDA[banda], ancho + 1.0, true)
	if con_nubes:
		control.draw_arc(base, exterior, PI, TAU, 48, COLOR_CONTORNO, 4.0, true)
		control.draw_arc(base, exterior - ancho * BANDAS.size(), PI, TAU, 48, COLOR_CONTORNO, 4.0, true)
		var medio := exterior - ancho * BANDAS.size() * 0.5
		for lado in [-1.0, 1.0]:
			var c := base + Vector2(lado * medio, -4.0)
			for desfase in [Vector2(-26, 4), Vector2(0, -8), Vector2(26, 4)]:
				control.draw_circle(c + desfase, 22.0, Color.WHITE)
			Figura.dibujar_cara(control, c + Vector2(0, -2), 34.0, encendidas.size() >= BANDAS.size())
	if encendidas.has("brillo"):
		if not con_nubes:
			# Arcoiris del cielo completo: chispitas blancas que titilan sobre las bandas.
			for k in 9:
				var angulo := PI + PI * (k + 0.5) / 9.0
				var punto := base + Vector2.from_angle(angulo) * (exterior - ancho * (1.0 + (k % 3) * 2.0))
				var luz := 0.5 + 0.5 * sin(_tiempo * 3.0 + k * 1.7)
				control.draw_colored_polygon(Figura.poligono("estrella", punto, 5.0 + 4.0 * luz), Color(1, 1, 1, 0.4 + 0.6 * luz))
			return
		for k in 5:
			var angulo := PI + PI * (k + 0.5) / 5.0
			var punto := base + Vector2.from_angle(angulo) * (exterior + 12.0 + sin(_tiempo * 4.0 + k) * 4.0)
			Figura.dibujar(control, "estrella", COLOR_BANDA["brillo"], punto, 11.0, false)


## Pieza de la nave (disenador-mecanicas HE-40 #3): silueta que se pinta un tramo por cada zona de
## `pieza_nave.zonas` completada, con el color de esa zona. Solo visual: no cambia ninguna regla.
## Va en una pildora del HUD, como en el menu de planetas.
func _dibujar_pieza(control: Control) -> void:
	var numeros: Array = mapa.get("pieza_nave", {}).get("zonas", [])
	var c := control.size / 2.0
	var ala := PackedVector2Array()
	# La misma ala que Maxi decora en Pinta z5 (`generar_pinta.py` ala(), escalada), para que la reconozca.
	for p in [Vector2(-70, 28), Vector2(-43, -15), Vector2(70, -24), Vector2(56, 18)]:
		ala.append(c + p * 0.82)
	ala = Geometry2D.offset_polygon(ala, 5.0, Geometry2D.JOIN_ROUND)[0]
	var listas := 0
	var placa := StyleBoxFlat.new()
	placa.bg_color = COLOR_PILDORA
	placa.set_corner_radius_all(40)
	placa.border_color = Color(1, 1, 1, 0.24)
	placa.set_border_width_all(3)
	control.draw_style_box(placa, Rect2(Vector2(0, 10), Vector2(control.size.x, 80)))
	control.draw_colored_polygon(ala, Color("#E4E0EE"))
	for k in numeros.size():
		var i := int(numeros[k]) - 1
		if i < 0 or i >= zonas.size() or not zonas[i]["completa"]:
			continue
		listas += 1
		var x0 := c.x - 60.0 + 120.0 * k / numeros.size()
		var franja := PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 120.0 / numeros.size(), 0),
			Vector2(x0 + 120.0 / numeros.size(), control.size.y), Vector2(x0, control.size.y)])
		for parte in Geometry2D.intersect_polygons(ala, franja):
			control.draw_colored_polygon(parte, _color_zona(i))
	var cerrada := ala.duplicate()
	cerrada.append(ala[0])
	control.draw_polyline(cerrada, Color.WHITE, 3.0, true)
	# Tramos que faltan: lineas punteadas, como un "para pintar".
	for k in range(1, numeros.size()):
		var x := c.x - 60.0 + 120.0 * k / numeros.size()
		control.draw_dashed_line(Vector2(x, c.y - 26), Vector2(x, c.y + 24), Color(COLOR_CONTORNO, 0.45), 2.0, 6.0)
	if listas == numeros.size():
		# Ala lista: la estrella de la pieza de Pinta, blanca para que se vea sobre cualquier color.
		control.draw_colored_polygon(Figura.poligono("estrella", c + Vector2(4, 0), 17.0), Color.WHITE)


func _color_zona(i: int) -> Color:
	var bandas: Array = zonas[i]["datos"].get("bandas", ["amarillo"])
	return COLOR_BANDA.get(bandas[0], DORADO)


func _dibujar_zona(control: Control, i: int) -> void:
	var zona: Dictionary = zonas[i]
	var centro := control.size / 2.0
	if _paisaje != null:
		# La zona que toca jugar late con un halo dorado (como el planeta actual del menu).
		if not _modal_abierto and i == _siguiente[0]:
			var pulso := 0.5 + 0.5 * sin(_tiempo * TAU / 1.8)
			var radio := 118.0 * (0.9 + 0.18 * pulso)
			for k in 8:
				var t := k / 8.0
				control.draw_circle(centro, radio * (1.0 - t * 0.85), Color(1.0, 0.92, 0.6, (0.08 + 0.06 * pulso) * (0.6 + t)))
		var cara: Dictionary = _paisaje.dibujar_hito(control, i, zona, centro, _tiempo)
		if cara.has("cara"):
			if zona["abierta"]:
				Figura.dibujar_cara(control, cara["cara"], cara["escala"], zona["completa"])
			else:
				_dibujar_cara_dormida(control, cara["cara"], cara["escala"])
		_dibujar_marcas_zona(control, zona, centro)
		return
	if zona["secreta"] and not zona["abierta"]:
		# Resplandor lejano en la cima: una promesa, nunca un candado.
		var pulso := 0.5 + 0.5 * sin(_tiempo * 2.2)
		for k in 3:
			control.draw_circle(centro, 30.0 + k * 14.0 + pulso * 6.0, Color(1.0, 0.9, 0.55, 0.16 - k * 0.04))
		Figura.dibujar(control, "estrella", Color("#FFE38A"), centro, 22.0 + pulso * 3.0, false)
		return
	if i == seleccion:
		var color_hermano: Color = COLORES_HERMANO.get(id_perfil, Color.WHITE)
		control.draw_circle(centro, RADIO_ZONA + 13.0, Color(color_hermano, 0.28 + 0.14 * sin(_tiempo * 3.0)))
		control.draw_arc(centro, RADIO_ZONA + 10.0, 0.0, TAU, 48, color_hermano, 6.0, true)
	var color := COLOR_DORMIDA
	if zona["completa"]:
		color = _color_zona(i)
	elif zona["abierta"]:
		color = _color_zona(i).lerp(Color.WHITE, 0.45)
	Figura.dibujar(control, "circulo", color, centro, RADIO_ZONA / 0.9, false)
	var bandas: Array = zona["datos"].get("bandas", [])
	if bandas.size() > 1 and zona["abierta"]:
		var segundo: Color = COLOR_BANDA.get(bandas[1], DORADO)
		control.draw_arc(centro, RADIO_ZONA * 0.72, 0.0, TAU, 40, Color(segundo, 0.9 if zona["completa"] else 0.5), 9.0, true)
	if zona["abierta"]:
		Figura.dibujar_cara(control, centro + Vector2(0, 6), RADIO_ZONA * 0.95, zona["completa"])
	else:
		_dibujar_cara_dormida(control, centro + Vector2(0, 6), RADIO_ZONA * 0.95)
	_dibujar_marcas_zona(control, zona, centro)


## Estrellitas de zona completa. Sin paisaje, ademas un puntito por estacion (estrella si ya se
## jugo); con paisaje ese detalle vive en la burbuja de la zona.
func _dibujar_marcas_zona(control: Control, zona: Dictionary, centro: Vector2) -> void:
	if zona["completa"]:
		if _paisaje != null:
			for k in 3:
				var punto := centro + Vector2((k - 1) * 38.0, -90.0 + absf(k - 1) * 14.0)
				Figura.dibujar(control, "estrella", DORADO, punto, (15.0 if k == 1 else 12.0) + 1.5 * sin(_tiempo * 3.0 + k), true, true)
			return
		for k in 3:
			var punto := centro + Vector2.from_angle(-PI * 0.8 + k * PI * 0.3) * (RADIO_ZONA + 4.0)
			Figura.dibujar(control, "estrella", DORADO, punto, 12.0 + 2.0 * sin(_tiempo * 3.0 + k), false)
	if zona["abierta"] and _paisaje == null:
		var estaciones: Array = zona["estaciones"]
		for j in estaciones.size():
			var punto := centro + Vector2.from_angle(PI / 2.0 + (j - (estaciones.size() - 1) / 2.0) * 0.42) * (RADIO_ZONA - 2.0)
			var estacion: Dictionary = estaciones[j]
			if estacion["completada"]:
				Figura.dibujar(control, "estrella", DORADO, punto, 13.0, false)
			elif estacion["jugable"]:
				control.draw_circle(punto, 8.0, Color("#FFF8EE"))
				control.draw_arc(punto, 8.0, 0.0, TAU, 20, COLOR_CONTORNO, 3.0, true)
			else:
				control.draw_circle(punto, 6.0, Color(1, 1, 1, 0.35))


func _dibujar_cara_dormida(lienzo: CanvasItem, centro: Vector2, escala: float) -> void:
	var grosor := maxf(2.0, escala * 0.055)
	for lado in [-1.0, 1.0]:
		var ojo := centro + Vector2(lado * escala * 0.3, -escala * 0.02)
		lienzo.draw_arc(ojo, escala * 0.1, PI * 0.15, PI * 0.85, 10, COLOR_CONTORNO, grosor, true)
	lienzo.draw_circle(centro + Vector2(0, escala * 0.16), escala * 0.06, COLOR_CONTORNO)
	var z := centro + Vector2(escala * 0.52, -escala * 0.55) + Vector2(0, sin(_tiempo * 2.0) * 4.0)
	for k in 2:
		var s := escala * (0.14 - k * 0.04)
		var o := z + Vector2(k * escala * 0.2, -k * escala * 0.22)
		lienzo.draw_polyline(PackedVector2Array([o + Vector2(-s, -s), o + Vector2(s, -s), o + Vector2(-s, s), o + Vector2(s, s)]), Color("#FFF8EE"), grosor * 1.2, true)


## Esfera de una estacion: el icono del juego (esfera de color con su dibujo), un anillo dorado que
## late si es el juego que sigue, y debajo sus estrellitas o el boton de jugar.
func _dibujar_tarjeta(control: Control, j: int) -> void:
	var estaciones: Array = zonas[seleccion]["estaciones"]
	if j >= estaciones.size():
		return
	var estacion: Dictionary = estaciones[j]
	var lado := control.size
	var centro := lado / 2.0
	var radio := lado.x / 2.0
	var es_siguiente: bool = _siguiente[0] == seleccion and _siguiente[1] == j
	control.draw_circle(centro + Vector2(0, 10), radio * 0.96, Color(0.1, 0.02, 0.22, 0.35))
	if es_siguiente:
		var pulso := 0.5 + 0.5 * sin(_tiempo * TAU / 1.4)
		for k in 4:
			control.draw_circle(centro, radio + 8.0 + pulso * 16.0 - k * 5.0, Color(DORADO, 0.06 + k * 0.03))
		control.draw_arc(centro, radio + 3.0 + pulso * 3.5, 0.0, TAU, 64, Color(DORADO, 0.75 + 0.15 * pulso), 6.0 + pulso * 3.0, true)
	# Icono por hermano opcional (`iconos`: {id_perfil: icono}), como `escenas`.
	var icono := str(estacion["datos"].get("iconos", {}).get(id_perfil, estacion["juego"]))
	_dibujar_icono(control, icono, centro, radio, estacion["jugable"])
	var abajo := Vector2(centro.x, lado.y + 26.0)
	if estacion["completada"]:
		if estacion["perfil_nivel"] == "estrella":
			for k in 3:
				var color := DORADO if k < int(estacion["estrellitas"]) else Color(1, 1, 1, 0.22)
				Figura.dibujar(control, "estrella", color, abajo + Vector2((k - 1) * 34.0, 0), 15.0, false)
		elif estacion["perfil_nivel"] == "brote" and int(estacion["estrellitas"]) > 0:
			# Nicole (HE-60, ficha motor-emparejar §10.1.1): solo las estrellitas ganadas, sin huecos vacios.
			var ganadas := int(estacion["estrellitas"])
			for k in ganadas:
				Figura.dibujar(control, "estrella", DORADO, abajo + Vector2((k - (ganadas - 1) / 2.0) * 34.0, 0), 15.0, false)
		else:
			# Maxi (y Pinta): una estrella de "ya lo jugaste".
			Figura.dibujar(control, "estrella", DORADO, abajo, 16.0, false)
	elif estacion["jugable"]:
		_dibujar_triangulo_jugar(control, abajo, 16.0)
	else:
		for k in 3:
			control.draw_circle(abajo + Vector2((k - 1) * 22.0, 0), 6.0, Color(1, 1, 1, 0.6))


## Boton de jugar: pildora turquesa con triangulo blanco.
func _dibujar_triangulo_jugar(control: Control, centro: Vector2, radio: float) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = TURQUESA
	caja.set_corner_radius_all(int(radio))
	caja.shadow_color = Color("#2B8F8A")
	caja.shadow_offset = Vector2(0, 3)
	caja.shadow_size = 1
	control.draw_style_box(caja, Rect2(centro - Vector2(radio * 1.45, radio), Vector2(radio * 2.9, radio * 2.0)))
	var puntos := PackedVector2Array([centro + Vector2(-radio * 0.4, -radio * 0.55), centro + Vector2(radio * 0.6, 0), centro + Vector2(-radio * 0.4, radio * 0.55)])
	control.draw_colored_polygon(puntos, Color.WHITE)


## Iconos universales de cada minijuego (sin texto, GDD §6 regla 3): esferas de color con el dibujo
## del juego (assets/sprites/ui/iconos_juegos/<icono>.svg, herramientas/generar_iconos_juegos.py).
## Si falta el arte, un dibujo por codigo de respaldo. `radio` es el de la esfera.
func _dibujar_icono(control: Control, juego: String, centro: Vector2, radio: float, activo: bool) -> void:
	if not _texturas_icono.has(juego):
		var ruta := RUTA_ICONOS % juego
		_texturas_icono[juego] = load(ruta) if ResourceLoader.exists(ruta) else null
	var textura: Texture2D = _texturas_icono[juego]
	if textura != null:
		var modulado := Color.WHITE if activo else Color(0.72, 0.7, 0.82, 0.55)
		control.draw_texture_rect(textura, Rect2(centro - Vector2.ONE * radio, Vector2.ONE * radio * 2.0), false, modulado)
		return
	control.draw_circle(centro, radio, Color("#FFF8EE") if activo else Color(1, 1, 1, 0.3))
	radio *= 0.62
	var tono := func(color: Color) -> Color: return color if activo else Color(color.lerp(Color("#9A96AD"), 0.75), 0.7)
	match juego:
		"lluvia":
			Figura.dibujar(control, "gota", tono.call(Color("#6FD6E8")), centro + Vector2(0, 6), radio * 0.9, activo)
			Figura.dibujar(control, "gota", tono.call(Color("#FF6B6B")), centro + Vector2(-radio * 0.95, -radio * 0.5), radio * 0.35, false)
			Figura.dibujar(control, "gota", tono.call(Color("#FFCB3D")), centro + Vector2(radio * 0.95, -radio * 0.35), radio * 0.3, false)
		"formas":
			Figura.dibujar(control, "triangulo", tono.call(Color("#7DD87A")), centro + Vector2(-radio * 0.5, -radio * 0.35), radio * 0.62, activo)
			Figura.dibujar(control, "cuadrado", tono.call(Color("#4A8BE0")), centro + Vector2(radio * 0.55, -radio * 0.2), radio * 0.52, false)
			Figura.dibujar(control, "circulo", tono.call(Color("#FF6B6B")), centro + Vector2(0, radio * 0.6), radio * 0.46, false)
		"parejas":
			for k in 2:
				var desfase := Vector2((k - 0.5) * radio * 0.8, (0.5 - k) * radio * 0.1)
				var carta := PackedVector2Array()
				var angulo := deg_to_rad(-12.0 if k == 0 else 10.0)
				for p in [Vector2(-0.55, -0.75), Vector2(0.55, -0.75), Vector2(0.55, 0.75), Vector2(-0.55, 0.75)]:
					carta.append(centro + desfase + (p * radio).rotated(angulo))
				control.draw_colored_polygon(carta, tono.call(Color("#B48CE8") if k == 0 else Color("#FFF8EE")))
				Figura.contornear(control, carta, 4.0)
				Figura.dibujar(control, "corazon" if k == 0 else "estrella", tono.call(Color("#F26CA8") if k == 0 else Color("#FFCB3D")), centro + desfase, radio * 0.3, false)
		"pinta":
			var paleta := PackedVector2Array()
			for k in 32:
				var a := TAU * k / 32.0
				paleta.append(centro + Vector2(cos(a) * radio * 1.0, sin(a) * radio * 0.72))
			control.draw_colored_polygon(paleta, tono.call(Color("#F2D3A6")))
			Figura.contornear(control, paleta, 4.0)
			var colores := [Color("#FF6B6B"), Color("#FFCB3D"), Color("#7DD87A"), Color("#4A8BE0")]
			for k in colores.size():
				control.draw_circle(centro + Vector2(-radio * 0.5 + k * radio * 0.33, -radio * 0.2 + (k % 2) * radio * 0.3), radio * 0.15, tono.call(colores[k]))
			control.draw_line(centro + Vector2(radio * 0.3, radio * 0.75), centro + Vector2(radio * 1.0, -radio * 0.45), tono.call(Color("#B07A4F")), 9.0, true)
		_:
			Figura.dibujar(control, "estrella", tono.call(DORADO), centro, radio * 0.8, activo)


## Flecha de volver: chevron blanco, como el boton atras del menu de planetas.
func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array([c + Vector2(6, -16) * k, c + Vector2(-10, 0) * k, c + Vector2(6, 16) * k])
	icono.draw_polyline(puntos, Color.WHITE, 7.0 * k, true)
	for p in puntos:
		icono.draw_circle(p, 3.5 * k, Color.WHITE)
