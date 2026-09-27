extends SceneTree

## Captura el mapa ilustrado del Planeta Arcoíris en tres momentos del avance (sin tocar el
## guardado: el estado de las zonas se fuerza en memoria): al llegar, a mitad de camino y con
## todo el arcoíris de vuelta. Guarda PNG a tamaño real en la carpeta indicada.
##
## Uso: godot --path . --script herramientas/capturar_mapa_arcoiris.gd -- salida=<carpeta> [perfil=sofia]

const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=", true, 1)
		if partes.size() == 2:
			args[partes[0]] = partes[1]
	var salida := str(args.get("salida", OS.get_user_data_dir()))
	var progreso := get_root().get_node("Progreso")
	progreso.perfil_seleccionado = str(args.get("perfil", "sofia"))
	change_scene_to_file(ARCOIRIS)
	await _esperar(0.5)
	var mapa := current_scene
	for momento in [["1_inicio", 1, 0], ["2_mitad", 4, 3], ["3_todo", 5, 5]]:
		var abiertas: int = momento[1]
		var completas: int = momento[2]
		for i in mapa.zonas.size():
			mapa.zonas[i]["abierta"] = i < abiertas
			mapa.zonas[i]["completa"] = i < completas
		mapa.seleccion = mini(completas, mapa.zonas.size() - 1)
		mapa._paisaje.actualizar(mapa.zonas)
		mapa._refrescar()
		await _esperar(1.2)
		await RenderingServer.frame_post_draw
		var ruta := salida.path_join("mapa_arcoiris_%s.png" % momento[0])
		get_root().get_texture().get_image().save_png(ruta)
		print("captura -> %s" % ruta)
	quit()


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame
