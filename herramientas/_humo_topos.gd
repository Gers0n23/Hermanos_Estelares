extends SceneTree
func _initialize() -> void:
	for perfil in ["semilla", "brote", "estrella"]:
		var m = load("res://escenas/minijuegos/topos/motor_topos.tscn").instantiate()
		m.ruta_nivel = "res://datos/niveles/animalia/zona5_valle/topos_%s.json" % perfil
		m.fijar_semilla(3)
		get_root().add_child(m)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 3000:
			await process_frame
			var id: int = m.logica.id_pedido()
			if id >= 0:
				m.presionar(m.punto_madriguera(id))
		print(perfil, " fase=", m.fase(), " aciertos=", m.logica.aciertos, " puntaje=", m.logica.puntaje)
		m.queue_free()
		await process_frame
	quit()
