extends SceneTree

## Pantallazos de «La Gran Burbujeada» (motor cortar) en ventana real, para revision visual del PO y de
## experto-ux-parvulo: la burbuja flotante de Maxi, una tanda de Sofia con su trazo, el calcetin y la mochila con un
## piso vacio. Usa el guardado de pruebas (Progreso lo elige solo al correr desde una herramienta).
## Uso: godot --path . --script herramientas/capturar_cortar.gd -- <carpeta_salida>

const ESCENA := "res://escenas/minijuegos/cortar/motor_cortar.tscn"
const TRES: Array[String] = ["maxi", "nicole", "sofia"]

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_cortar"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	var motor: Node = load(ESCENA).instantiate()
	motor.ruta_nivel = "res://datos/niveles/animalia/batalla/burbujeada_equipo.json"
	motor.equipo = TRES
	motor.en_batalla = true
	motor.escala_tiempo = 0.05
	motor.acelerar_qa = 4.0
	motor.momento_saltable_iniciado.connect(func(id: String) -> void: motor.saltar_momento.call_deferred(id))
	root.add_child(motor)
	await process_frame
	await process_frame
	if motor.turnos != null:
		motor.turnos.escala_tiempo = 0.05
	# 1. Maxi: su burbuja flotando.
	await _hasta(motor, func() -> bool: return motor.perfil_turno() == "semilla" and not motor.burbujas_en_vuelo().is_empty() \
		and (motor.burbujas_en_vuelo()[0] as BurbujaCortar).t > 1.3)
	await _foto("1_maxi_flota")
	motor.procesar_toque(Vector2(300, 400), true, 0)
	motor.procesar_toque(Vector2(300, 400), false, 0)
	# 2. Sofia a mitad de tanda, con un trazo dibujandose.
	await _hasta(motor, func() -> bool: return motor.perfil_turno() == "estrella" and motor.burbujas_en_vuelo().size() >= 4)
	motor.procesar_toque(Vector2(200, 250), true, 0)
	for k in 8:
		motor.procesar_arrastre(Vector2(200 + k * 60, 250 + k * 12), 0)
		await process_frame
	await _foto("2_sofia_trazo")
	motor.procesar_toque(Vector2(700, 340), false, 0)
	# 3. Fin de la oleada 1: piso vacio (se fuerza el pool para no jugar la oleada entera).
	motor._liberados.resize(motor.meta_actual() - 1)
	motor._liberados.fill("pato")
	await _hasta(motor, func() -> bool: return motor.fase() == "tanda" and not motor.burbujas_en_vuelo().is_empty())
	for b in motor.burbujas_en_vuelo():
		if (b as BurbujaCortar).tipo == "animal":
			motor.qa_reventar(b)
			break
	await _hasta(motor, func() -> bool: return motor.oleada_actual() == 2)
	await _foto("3_piso_vacio")
	quit()


func _hasta(motor: Node, cond: Callable, maximo := 40.0) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0 and not cond.call():
		if motor.turnos != null and motor.turnos.en_puerta():
			motor.turnos.abrir_puerta()
		await process_frame


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var ruta := _carpeta.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("captura: ", ruta)
