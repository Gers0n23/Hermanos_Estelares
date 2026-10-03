extends Node

## Autoload `Recuerdos`: el album "Las migas de papa" (docs/fichas/album-recuerdos.md, HE-45).
##
## Lee `datos/recuerdos/catalogo.json` (data-driven) y resuelve, para cada recuerdo:
## - si ya se encontro (lo guarda `Progreso`, global, en `recuerdos_encontrados`);
## - si su momento ya existe en el juego (si no, no aparece como hueco — ficha §5);
## - su foto y su voz REALES si el PO ya las copio a `assets/recuerdos/fotos|voces/<id>.*`
##   (carpetas en .gitignore: se comprueban en runtime), o nada, y la UI dibuja el placeholder.
##
## Regla de oro 3: no conoce minijuegos ni planetas concretos. Las pantallas le avisan con
## EVENTOS GENERICOS y el catalogo dice que recuerdo corresponde a cada uno:
##   {"tipo": "primera_apertura"}
##   {"tipo": "viaje", "origen": "tierra", "destino": "arcoiris"}
##   {"tipo": "zona_completa", "planeta": "arcoiris", "zona": "zona2_charcos", "numero": 2, "perfecta": false}
##   {"tipo": "pieza_nave", "planeta": "arcoiris"}
##   {"tipo": "rescate_final"}
## `desbloquear(evento, id_perfil)` es idempotente: la misma foto nunca se entrega dos veces.

signal recuerdos_desbloqueados(lista: Array)

const RUTA_CATALOGO := "res://datos/recuerdos/catalogo.json"
const CARPETA_FOTOS := "res://assets/recuerdos/fotos/"
const CARPETA_VOCES := "res://assets/recuerdos/voces/"
const EXTENSIONES_FOTO := ["jpg", "jpeg", "png", "webp"]
const EXTENSIONES_VOZ := ["ogg", "wav", "mp3"]
const ALBUMES := ["maxi", "nicole", "sofia", "familia"]

var catalogo: Dictionary = {}
var recuerdos: Array = []
var _por_id: Dictionary = {}
var _cache_texturas: Dictionary = {}
var _cache_disponible: Dictionary = {}


## En `_init` y no en `_ready`: el catalogo no depende del arbol y asi esta listo aunque alguien
## lo consulte antes del primer frame (arneses headless).
func _init() -> void:
	cargar_catalogo()


func cargar_catalogo(ruta: String = RUTA_CATALOGO) -> void:
	catalogo = {}
	recuerdos = []
	_por_id = {}
	_cache_disponible = {}
	if not FileAccess.file_exists(ruta):
		push_warning("Recuerdos: no existe el catalogo %s" % ruta)
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		push_warning("Recuerdos: catalogo invalido %s" % ruta)
		return
	catalogo = datos
	for rec in catalogo.get("recuerdos", []):
		if rec is Dictionary and str(rec.get("id", "")) != "":
			recuerdos.append(rec)
			_por_id[str(rec["id"])] = rec
	recuerdos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var oa := ALBUMES.find(str(a.get("album", "")))
		var ob := ALBUMES.find(str(b.get("album", "")))
		if oa != ob:
			return oa < ob
		return int(a.get("orden", 0)) < int(b.get("orden", 0)))


func _progreso() -> Node:
	# ruta relativa a la raiz: funciona aunque se llame antes del primer frame (tests headless)
	var arbol := Engine.get_main_loop() as SceneTree
	return arbol.root.get_node_or_null("Progreso") if arbol != null else null


func obtener(id_recuerdo: String) -> Dictionary:
	return _por_id.get(id_recuerdo, {})


func datos_album(album: String) -> Dictionary:
	return catalogo.get("albumes", {}).get(album, {})


# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

func esta_encontrado(id_recuerdo: String) -> bool:
	var progreso := _progreso()
	return progreso != null and progreso.tiene_recuerdo(id_recuerdo)


func info_encontrado(id_recuerdo: String) -> Dictionary:
	var progreso := _progreso()
	if progreso == null:
		return {}
	return progreso.obtener_recuerdos_encontrados().get(id_recuerdo, {})


## El momento de entrega ya existe en el juego. Si no, el recuerdo queda en el catalogo pero no se
## muestra como hueco (ficha §5). `requiere` (ruta res://) manda; si no, se deduce por tipo.
func esta_disponible(rec: Dictionary) -> bool:
	var id := str(rec.get("id", ""))
	if _cache_disponible.has(id):
		return _cache_disponible[id]
	var momento: Dictionary = rec.get("momento", {})
	var disponible := false
	var requiere := str(momento.get("requiere", ""))
	if requiere != "":
		disponible = ResourceLoader.exists(requiere) or FileAccess.file_exists(requiere)
	else:
		match str(momento.get("tipo", "")):
			"primera_apertura":
				disponible = true
			"zona_completa":
				disponible = _planeta_tiene_zona(str(momento.get("planeta", "")), momento)
			_:
				disponible = false
	_cache_disponible[id] = disponible
	return disponible


func _planeta_tiene_zona(planeta: String, momento: Dictionary) -> bool:
	var ruta := "res://datos/planetas/%s/mapa.json" % planeta
	if planeta == "" or not FileAccess.file_exists(ruta):
		return false
	var mapa: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not mapa is Dictionary:
		return false
	for zona in mapa.get("zonas", []):
		if momento.has("zona") and str(zona.get("id", "")) == str(momento["zona"]):
			return true
		if momento.has("numero") and int(zona.get("numero", -1)) == int(momento["numero"]):
			return true
	return false


## Lo que se ve en el album: encontrados + huecos cuyo momento ya existe, en orden de edad.
func recuerdos_album(album: String) -> Array:
	var lista: Array = []
	for rec in recuerdos:
		if str(rec.get("album", "")) == album and (esta_encontrado(str(rec["id"])) or esta_disponible(rec)):
			lista.append(rec)
	return lista


## [encontrados, visibles] de un album.
func contar(album: String) -> Array:
	var visibles := recuerdos_album(album)
	var encontrados := 0
	for rec in visibles:
		if esta_encontrado(str(rec["id"])):
			encontrados += 1
	return [encontrados, visibles.size()]


func album_tiene_nuevos(album: String) -> bool:
	for rec in recuerdos_album(album):
		var info := info_encontrado(str(rec["id"]))
		if not info.is_empty() and not info.get("visto", false):
			return true
	return false


func hay_nuevos() -> bool:
	var progreso := _progreso()
	return progreso != null and progreso.hay_recuerdos_sin_ver()


func marcar_visto(id_recuerdo: String) -> void:
	var progreso := _progreso()
	if progreso != null:
		progreso.marcar_recuerdo_visto(id_recuerdo)


# ---------------------------------------------------------------------------
# Eventos genericos -> desbloqueo
# ---------------------------------------------------------------------------

func coincide(rec: Dictionary, evento: Dictionary, id_perfil: String) -> bool:
	var momento: Dictionary = rec.get("momento", {})
	if str(momento.get("tipo", "")) != str(evento.get("tipo", "-")):
		return false
	var album := str(rec.get("album", ""))
	# Los personales solo los encuentra su dueño; los familiares, cualquiera (ficha §3).
	if album != "familia" and album != id_perfil:
		return false
	match str(momento["tipo"]):
		"viaje":
			if momento.has("destino") and str(momento["destino"]) != str(evento.get("destino", "")):
				return false
		"zona_completa":
			if str(momento.get("planeta", "")) != str(evento.get("planeta", "")):
				return false
			if momento.has("zona"):
				return str(momento["zona"]) == str(evento.get("zona", ""))
			if momento.has("numero"):
				return int(momento["numero"]) == int(evento.get("numero", -1))
		"pieza_nave":
			return str(momento.get("planeta", "")) == str(evento.get("planeta", ""))
	return true


## Recuerdos que este evento entregaria y aun no se encontraron (sin guardar nada). El viaje
## estelar lo usa para decidir si lanza la burbuja-recuerdo.
func pendientes(evento: Dictionary, id_perfil: String) -> Array:
	var lista: Array = []
	for rec in recuerdos:
		if not esta_encontrado(str(rec["id"])) and coincide(rec, evento, id_perfil):
			lista.append(rec)
	return lista


## Entrega (y guarda de inmediato) lo que corresponde a este evento. Devuelve copias de los
## recuerdos NUEVOS, con `_quien` (hermano) y `_dorado`. Si el evento trae `perfecta` (estrellitas
## maximas de Sofia) y la foto de esa zona ya estaba, se devuelve con `_solo_dorado` = true: la
## foto no se repite, solo gana su marco dorado.
## `maximo` >= 0 corta la entrega (HE-44 #7, tope de sobres): los que no caben NO se guardan y llegan
## la proxima vez.
func desbloquear(evento: Dictionary, id_perfil: String, maximo: int = -1) -> Array:
	var progreso := _progreso()
	var entregados: Array = []
	if progreso == null:
		return entregados
	var perfecta := bool(evento.get("perfecta", false))
	for rec in recuerdos:
		if maximo >= 0 and entregados.size() >= maximo:
			break
		if not coincide(rec, evento, id_perfil):
			continue
		var id := str(rec["id"])
		var nuevo: bool = progreso.registrar_recuerdo(id, id_perfil)
		var dorado_nuevo := false
		if perfecta and str(rec.get("album", "")) != "familia":
			dorado_nuevo = progreso.marcar_recuerdo_dorado(id)
		if nuevo or dorado_nuevo:
			var copia: Dictionary = rec.duplicate(true)
			copia["_quien"] = id_perfil
			copia["_dorado"] = bool(info_encontrado(id).get("dorado", false))
			copia["_solo_dorado"] = not nuevo
			entregados.append(copia)
	if not entregados.is_empty():
		recuerdos_desbloqueados.emit(entregados)
	return entregados


# ---------------------------------------------------------------------------
# Foto y voz reales (o nada: la UI usa el placeholder)
# ---------------------------------------------------------------------------

func _buscar_archivo(rec: Dictionary, campo: String, carpeta: String, extensiones: Array) -> String:
	var candidatos: Array = []
	var explicito := str(rec.get(campo, ""))
	if explicito != "":
		candidatos.append(explicito)
		for ext in extensiones:
			candidatos.append(explicito.get_basename() + "." + ext)
	for ext in extensiones:
		candidatos.append(carpeta + str(rec.get("id", "")) + "." + ext)
	for ruta in candidatos:
		if ResourceLoader.exists(ruta) or FileAccess.file_exists(ruta):
			return ruta
	return ""


func ruta_foto_real(rec: Dictionary) -> String:
	return _buscar_archivo(rec, "foto", CARPETA_FOTOS, EXTENSIONES_FOTO)


func ruta_voz_real(rec: Dictionary) -> String:
	return _buscar_archivo(rec, "voz", CARPETA_VOCES, EXTENSIONES_VOZ)


func tiene_foto_real(rec: Dictionary) -> bool:
	return ruta_foto_real(rec) != ""


## Foto real del recuerdo o null (=> placeholder). Si el archivo se copio sin abrir el editor (no
## esta importado), se lee directo desde disco.
func textura_foto(rec: Dictionary) -> Texture2D:
	var ruta := ruta_foto_real(rec)
	return cargar_textura(ruta) if ruta != "" else null


func cargar_textura(ruta: String) -> Texture2D:
	if ruta == "":
		return null
	if _cache_texturas.has(ruta):
		return _cache_texturas[ruta]
	var textura: Texture2D = null
	if ResourceLoader.exists(ruta):
		textura = load(ruta) as Texture2D
	elif FileAccess.file_exists(ruta):
		var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
		if imagen != null and not imagen.is_empty():
			textura = ImageTexture.create_from_image(imagen)
	_cache_texturas[ruta] = textura
	return textura


## Audio real de la familia para la foto, o null.
func stream_voz(rec: Dictionary) -> AudioStream:
	return cargar_audio(ruta_voz_real(rec))


func cargar_audio(ruta: String) -> AudioStream:
	if ruta == "":
		return null
	if ResourceLoader.exists(ruta):
		return load(ruta) as AudioStream
	if not FileAccess.file_exists(ruta):
		return null
	match ruta.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(ruta)
		"wav":
			return AudioStreamWAV.load_from_file(ruta)
		"mp3":
			return AudioStreamMP3.load_from_file(ruta)
	return null


## Imagen del placeholder de un album (personaje del album) o del hueco: {textura, region, ajuste}.
func imagen_placeholder(album: String) -> Dictionary:
	var datos := datos_album(album)
	return _imagen(str(datos.get("placeholder", "")), datos.get("recorte_placeholder", []), str(datos.get("ajuste", "cubrir")))


func imagen_hueco() -> Dictionary:
	var datos: Dictionary = catalogo.get("hueco", {})
	return _imagen(str(datos.get("imagen", "")), datos.get("recorte", []), str(datos.get("ajuste", "contener")))


func _imagen(ruta: String, recorte: Array, ajuste: String) -> Dictionary:
	var textura := cargar_textura(ruta)
	if textura == null:
		return {}
	var region := Rect2(Vector2.ZERO, textura.get_size())
	if recorte.size() == 4:
		region = Rect2(float(recorte[0]), float(recorte[1]), float(recorte[2]), float(recorte[3]))
	return {"textura": textura, "region": region, "ajuste": ajuste}


func color_album(album: String) -> Color:
	return Color(str(datos_album(album).get("color", "#FFCB3D")))


# ---------------------------------------------------------------------------
# Lineas de Cometa (docs/guiones/recuerdos.md). Todas pendientes de audio: si el archivo no
# existe, devuelven "" y la pantalla sigue en silencio con su animacion (no se inventa audio).
# ---------------------------------------------------------------------------

func ruta_linea(id_linea: String) -> String:
	if id_linea == "":
		return ""
	var carpeta := str(catalogo.get("voces", {}).get("carpeta", "res://assets/audio/voces/recuerdos/"))
	var base := carpeta + id_linea.trim_prefix("recuerdos_")
	for ext in ["ogg", "wav"]:
		if ResourceLoader.exists(base + "." + ext):
			return base + "." + ext
	return ""


## Una linea existente de la lista `clave` de `voces` (al azar entre las grabadas) o "".
func elegir_linea(clave: String, subclave: String = "") -> String:
	var valor: Variant = catalogo.get("voces", {}).get(clave, [])
	if valor is Dictionary:
		valor = [valor.get(subclave, "")]
	var existentes: Array = []
	for id_linea in valor:
		var ruta := ruta_linea(str(id_linea))
		if ruta != "":
			existentes.append(ruta)
	return existentes.pick_random() if not existentes.is_empty() else ""


## Pista hablada de un hueco: su linea del guion o, mientras no exista, una linea de Cometa ya
## grabada que sirva (p. ej. "¡Vamos al Planeta Arcoiris!"), o "".
func ruta_pista(rec: Dictionary) -> String:
	var ruta := ruta_linea(str(rec.get("pista", "")))
	if ruta != "":
		return ruta
	var respaldo := str(rec.get("pista_respaldo", ""))
	return respaldo if respaldo != "" and ResourceLoader.exists(respaldo) else ""
