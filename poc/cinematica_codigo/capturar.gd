extends SceneTree

## Captura cuadros de la prueba de concepto en instantes fijos (con GPU, NO headless).
## Uso: godot --path . --script res://poc/cinematica_codigo/capturar.gd -- <carpeta_salida>

const INSTANTES := [2.4, 3.6, 4.4, 5.0, 5.4, 6.2, 7.4, 8.6, 9.4, 10.4, 12.0, 14.0]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var carpeta: String = args[0] if args.size() > 0 else "user://capturas_poc"
	DirAccess.make_dir_recursive_absolute(carpeta)
	var escena: Node = load("res://poc/cinematica_codigo/cinematica_choque_cometa.tscn").instantiate()
	get_root().add_child(escena)
	var t0 := Time.get_ticks_msec()
	for i in INSTANTES.size():
		while Time.get_ticks_msec() - t0 < INSTANTES[i] * 1000.0:
			await process_frame
		await RenderingServer.frame_post_draw
		var ruta := carpeta.path_join("cuadro_%02d_%05.1fs.png" % [i, INSTANTES[i]])
		get_root().get_texture().get_image().save_png(ruta)
		print("captura: %s" % ruta)
	# Párpado a medio cerrar, para revisar que calce con el ojo pintado.
	for p in escena.parpados:
		p.cierre = 0.6
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(carpeta.path_join("parpado.png"))
	# Al terminar la voz: saludo e iris.
	while not escena._terminada and Time.get_ticks_msec() - t0 < 40000:
		await process_frame
		if escena._cometa_animandose == false and escena.cometa.texture == escena.TEX_COMETA_SALUDO and not escena.has_meta("cap"):
			escena.set_meta("cap", true)
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png(carpeta.path_join("saludo.png"))
		var mat: ShaderMaterial = escena.iris.material
		if float(mat.get_shader_parameter("radio")) < 0.5 and not escena.has_meta("cap_iris"):
			escena.set_meta("cap_iris", true)
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png(carpeta.path_join("iris.png"))
	print("terminada a los %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(0)
