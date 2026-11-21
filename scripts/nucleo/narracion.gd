class_name Narracion
extends RefCounted
## Catalogo de lo que narra Cometa en cada momento de la historia (`datos/historia/narracion.json`, guion
## `docs/guiones/narracion-cometa.md`). Las escenas piden las lineas de un momento por su id y las pasan a
## `Audio.reproducir_voces` / `Audio.encolar_voces`; asi el texto y el orden viven en datos, no en codigo.

const RUTA := "res://datos/historia/narracion.json"
const PREFIJO_AUDIO := "res://assets/audio/"

static var _momentos: Dictionary = {}


## Rutas res:// de las lineas del momento (vacio si no existe el momento).
static func lineas(momento: String) -> Array:
	if _momentos.is_empty():
		var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
		if datos is Dictionary:
			_momentos = datos.get("momentos", {})
	var salida: Array = []
	for ruta in _momentos.get(momento, {}).get("lineas", []):
		salida.append(str(ruta) if str(ruta).begins_with("res://") else PREFIJO_AUDIO + str(ruta))
	return salida
