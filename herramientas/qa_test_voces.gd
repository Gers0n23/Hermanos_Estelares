extends SceneTree
## QA de voces: recorre todos los `lineas_tts.tsv` de `assets/audio/voces/` y verifica que cada
## línea exista como recurso importado, cargue como AudioStream y dure algo razonable.
## Uso: godot --headless --path . --script res://herramientas/qa_test_voces.gd

const RAIZ_VOCES := "res://assets/audio/voces/"
const DURACION_MIN := 0.3
const DURACION_MAX := 20.0

var _ok := 0
var _fallas := 0


func _initialize() -> void:
	for tsv in _buscar_listas(RAIZ_VOCES):
		_revisar_lista(tsv)
	print("qa_test_voces: %d OK / %d fallas" % [_ok, _fallas])
	quit(1 if _fallas > 0 else 0)


func _buscar_listas(carpeta: String) -> Array[String]:
	var listas: Array[String] = []
	for archivo in DirAccess.get_files_at(carpeta):
		if archivo == "lineas_tts.tsv":
			listas.append(carpeta.path_join(archivo))
	for sub in DirAccess.get_directories_at(carpeta):
		listas.append_array(_buscar_listas(carpeta.path_join(sub)))
	return listas


func _revisar_lista(tsv: String) -> void:
	var texto := FileAccess.get_file_as_string(tsv)
	var personaje := "windows"
	for cruda in texto.split("\n"):
		var linea := cruda.strip_edges()
		if linea == "":
			continue
		if linea.begins_with("#"):
			var cuerpo := linea.trim_prefix("#").strip_edges()
			if cuerpo.to_lower().begins_with("personaje:"):
				var nombre := cuerpo.get_slice(":", 1).strip_edges()
				personaje = nombre if nombre != "" else "windows"
			continue
		var ruta := "res://assets/audio/" + linea.get_slice("\t", 0).strip_edges()
		if not ResourceLoader.exists(ruta):
			_falla("no existe (o no está importada): %s" % ruta)
			continue
		var stream := load(ruta) as AudioStream
		if stream == null:
			_falla("no carga como AudioStream: %s" % ruta)
			continue
		var duracion := stream.get_length()
		if duracion < DURACION_MIN or duracion > DURACION_MAX:
			_falla("duración fuera de rango (%.2f s): %s" % [duracion, ruta])
			continue
		_ok += 1
		if personaje != "windows":
			print("  [%s] %.1f s  %s" % [personaje, duracion, ruta])


func _falla(mensaje: String) -> void:
	_fallas += 1
	push_error("qa_test_voces: " + mensaje)
