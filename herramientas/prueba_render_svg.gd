extends SceneTree


func _init() -> void:
	var carpeta_ruta := ""
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--carpeta="):
			carpeta_ruta = argumento.get_slice("=", 1)
	var carpeta := DirAccess.open(carpeta_ruta)
	if carpeta == null:
		push_error("No se pudo abrir: " + carpeta_ruta)
		quit(1)
		return
	carpeta.list_dir_begin()
	var nombre := carpeta.get_next()
	var total := 0
	while nombre != "":
		if nombre.get_extension().to_lower() == "svg":
			var ruta_svg := carpeta_ruta.path_join(nombre)
			var ruta_png := carpeta_ruta.path_join(nombre.get_basename() + "_render.png")
			_exportar(ruta_svg, ruta_png)
			total += 1
		nombre = carpeta.get_next()
	carpeta.list_dir_end()
	print("Renderizadas %d piezas" % total)
	quit(0)


func _exportar(ruta_svg: String, ruta_png: String) -> void:
	var texto := FileAccess.get_file_as_string(ruta_svg)
	if texto.is_empty():
		push_error("No se pudo leer: " + ruta_svg)
		return
	var imagen := Image.new()
	var error := imagen.load_svg_from_string(texto, 1.0)
	if error != OK:
		push_error("SVG invalido (%s): %s" % [error_string(error), ruta_svg])
		return
	imagen.save_png(ruta_png)
