extends SceneTree

## Captura pantallazos reales (con GPU, NO headless) de la celebracion de cada hermano
## sobre el motor "emparejar", para revision visual del PO / experto-ux-parvulo (HE-10).
##
## Uso: godot --path . --script herramientas/capturar_celebracion.gd -- <carpeta_salida> [segundos]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var carpeta: String = args[0] if args.size() > 0 else "user://capturas_celebracion"
	var segundos: float = float(args[1]) if args.size() > 1 else 3.0
	DirAccess.make_dir_recursive_absolute(carpeta)
	for datos in [["maxi", 0], ["nicole", 0], ["sofia", 2]]:
		await _capturar(datos[0], datos[1], carpeta, segundos)
	quit(0)


func _capturar(id: String, estrellitas: int, carpeta: String, segundos: float) -> void:
	var motor: Node = load("res://escenas/minijuegos/emparejar/motor_emparejar.tscn").instantiate()
	get_root().add_child(motor)
	var celebracion: Node = load("res://escenas/ui/celebracion.tscn").instantiate()
	celebracion.id_personaje = id
	celebracion.destellos = 96
	celebracion.estrellitas = estrellitas
	celebracion.segundos_auto_continuar = 0.0
	get_root().add_child(celebracion)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000:
		await process_frame
	await RenderingServer.frame_post_draw
	var ruta := carpeta.path_join("celebracion_%s.png" % id)
	get_root().get_texture().get_image().save_png(ruta)
	print("captura: %s" % ruta)
	celebracion.queue_free()
	motor.queue_free()
	await process_frame
