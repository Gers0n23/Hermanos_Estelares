# exportar_sprites.gd — Pipeline de assets (tarjeta HE-03)
# Convierte POR LOTE todos los SVG de assets/fuentes_svg/ a PNG en assets/sprites/,
# replicando la subestructura de carpetas (stack tecnico, seccion 5).
#
# Uso (desde la raiz del repo):
#   godot --headless --path . --script herramientas/exportar_sprites.gd
#   godot --headless --path . --script herramientas/exportar_sprites.gd -- --escala=2.0
#
# Notas:
# - Usa el rasterizador SVG interno de Godot (Image.load_svg_from_string),
#   ya validado archivo por archivo durante HE-D2. Cero dependencias externas.
# - La escala por defecto es 1.0 (los SVG fuente ya se dibujan a tamano final en px).
# - Esta carpeta tiene .gdignore: el script se invoca por ruta de archivo, no vive en res://.

extends SceneTree

const DIR_FUENTES := "res://assets/fuentes_svg"
const DIR_DESTINO := "res://assets/sprites"


func _init() -> void:
	var escala := _leer_escala()
	print("Exportando SVG -> PNG (escala %.2f)" % escala)
	var resultado := {"ok": 0, "error": 0}
	_procesar_carpeta(DIR_FUENTES, DIR_DESTINO, escala, resultado)
	print("Listo: %d PNG generados, %d errores." % [resultado.ok, resultado.error])
	quit(0 if resultado.error == 0 else 1)


func _leer_escala() -> float:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--escala="):
			return maxf(0.1, float(argumento.get_slice("=", 1)))
	return 1.0


func _procesar_carpeta(origen: String, destino: String, escala: float, resultado: Dictionary) -> void:
	var carpeta := DirAccess.open(origen)
	if carpeta == null:
		push_error("No se pudo abrir la carpeta: " + origen)
		resultado.error += 1
		return
	carpeta.list_dir_begin()
	var nombre := carpeta.get_next()
	while nombre != "":
		var ruta_origen := origen.path_join(nombre)
		if carpeta.current_is_dir():
			if not nombre.begins_with("."):
				_procesar_carpeta(ruta_origen, destino.path_join(nombre), escala, resultado)
		elif nombre.get_extension().to_lower() == "svg":
			if _exportar_svg(ruta_origen, destino.path_join(nombre.get_basename() + ".png"), escala):
				resultado.ok += 1
			else:
				resultado.error += 1
		nombre = carpeta.get_next()
	carpeta.list_dir_end()


func _exportar_svg(ruta_svg: String, ruta_png: String, escala: float) -> bool:
	var texto := FileAccess.get_file_as_string(ruta_svg)
	if texto.is_empty():
		push_error("No se pudo leer: " + ruta_svg)
		return false
	var imagen := Image.new()
	var error := imagen.load_svg_from_string(texto, escala)
	if error != OK:
		push_error("SVG invalido (%s): %s" % [error_string(error), ruta_svg])
		return false
	DirAccess.make_dir_recursive_absolute(ruta_png.get_base_dir())
	error = imagen.save_png(ruta_png)
	if error != OK:
		push_error("No se pudo guardar (%s): %s" % [error_string(error), ruta_png])
		return false
	print("  %s -> %s (%dx%d)" % [ruta_svg, ruta_png, imagen.get_width(), imagen.get_height()])
	return true
