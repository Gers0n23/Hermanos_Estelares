extends SceneTree

## Captura pantallazos reales (con GPU, NO headless) del album de recuerdos, para revision visual
## del PO y de experto-ux-parvulo. Usa un guardado temporal: nunca toca el real.
##
## Uso: godot --path . --script herramientas/capturar_album.gd -- <carpeta_salida> <vacio|todo>
## Un proceso por estado (sin progreso / con todo encontrado). Genera: portada, pagina de cada
## album (y su segunda pagina) y una foto abierta.

const TMP := "user://capturas_album_tmp.json"
const ESCENA := "res://escenas/nucleo/album_recuerdos.tscn"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var carpeta: String = args[0] if args.size() > 0 else "user://capturas_album"
	var estado: String = args[1] if args.size() > 1 else "vacio"
	DirAccess.make_dir_recursive_absolute(carpeta)
	var progreso: Node = get_root().get_node("Progreso")
	var recuerdos: Node = get_root().get_node("Recuerdos")
	progreso.ruta_guardado = TMP
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	progreso.cargar()
	if estado == "todo":
		for rec in recuerdos.recuerdos:
			progreso.registrar_recuerdo(str(rec.get("id", "")), "captura")

	if estado == "seleccion":
		# El boton del album tal como lo ve el nino en la seleccion de personaje.
		for rec in recuerdos.recuerdos:
			progreso.registrar_recuerdo(str(rec.get("id", "")), "captura")
		var seleccion: Node = load("res://escenas/nucleo/seleccion_personaje.tscn").instantiate()
		get_root().add_child(seleccion)
		await _esperar(1.5)
		await _guardar(carpeta, "seleccion_pantalla")
		seleccion.queue_free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
		progreso.ruta_guardado = progreso.RUTA_GUARDADO
		quit(0)
		return

	var album: Node = load(ESCENA).instantiate()
	get_root().add_child(album)
	await _esperar(0.8)
	await _guardar(carpeta, "%s_1_portada" % estado)
	for nombre_album in ["maxi", "nicole", "sofia", "familia"]:
		album.abrir_album(nombre_album)
		await _esperar(0.6)
		await _guardar(carpeta, "%s_2_pagina_%s" % [estado, nombre_album])
		if album.paginas() > 1:
			album.pasar_pagina(1)
			await _esperar(0.6)
			await _guardar(carpeta, "%s_2_pagina_%s_p2" % [estado, nombre_album])
			album.pasar_pagina(-1)
			await _esperar(0.5)
		album.mostrar_portada()
		await _esperar(0.4)
	album.abrir_album("maxi")
	await _esperar(0.4)
	var lista: Array = get_root().get_node("Recuerdos").recuerdos_album("maxi")
	if not lista.is_empty():
		album.abrir_foto(lista[0])
		await _esperar(0.9)
		await _guardar(carpeta, "%s_3_foto_abierta" % estado)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	progreso.ruta_guardado = progreso.RUTA_GUARDADO
	quit(0)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _guardar(carpeta: String, nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(carpeta.path_join("%s.png" % nombre))
	print("captura: %s" % nombre)
