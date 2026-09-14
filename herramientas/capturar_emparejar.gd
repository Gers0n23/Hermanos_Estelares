extends SceneTree

## Juega la demo de "emparejar" con CLICS REALES en ventana (no headless) y saca pantallazos
## de cada ruta para revision visual del PO / experto-ux-parvulo. Los clics pasan por
## `push_input`, igual que un dedo o el mouse, asi que tambien prueba la entrada de verdad.
##
## Uso: godot --path . --script herramientas/capturar_emparejar.gd -- <carpeta_salida>

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const RUTAS := [
	["maxi", "res://datos/niveles/arcoiris_emparejar_semilla_01.json"],
	["nicole", "res://datos/niveles/arcoiris_emparejar_brote_01.json"],
	["sofia", "res://datos/niveles/arcoiris_emparejar_estrella_01.json"],
]

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_emparejar"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for ruta in RUTAS:
		await _jugar(ruta[0], ruta[1])
	quit(0)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := _carpeta.path_join(nombre + ".png")
	get_root().get_texture().get_image().save_png(ruta)
	print("captura: %s" % ruta)


func _clic(carta: Control) -> void:
	var punto := carta.get_global_rect().get_center()
	for presionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.pressed = presionado
		evento.position = punto
		evento.global_position = punto
		get_root().push_input(evento, true)
		await process_frame


func _jugar(perfil: String, nivel: String) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = nivel
	motor.id_perfil = perfil
	motor.segundos_auto_continuar = 0.0
	get_root().add_child(motor)
	await _esperar(1.3)
	await _capturar("%s_1_inicio" % perfil)

	var por_pareja := {}
	for carta in motor._cartas:
		if not por_pareja.has(carta.id_pareja):
			por_pareja[carta.id_pareja] = []
		por_pareja[carta.id_pareja].append(carta)
	var claves: Array = por_pareja.keys()
	var a: Control = por_pareja[claves[0]][0]
	var b: Control = por_pareja[claves[1]][0]

	await _clic(a)
	await _esperar(0.4)
	print("[%s] clic real en carta 1 -> seleccionadas=%d mostrando=%s" % [perfil, motor._seleccionadas.size(), a.mostrando])
	await _clic(b)
	await _esperar(0.35)
	print("[%s] clic real en carta 2 (otra pareja) -> no_es_este=%s" % [perfil, motor._procesando])
	await _capturar("%s_2_no_es_este" % perfil)
	await _esperar(1.6)

	var elegida: String = claves[2]
	for clave in claves:
		if por_pareja[clave][0].especial:
			elegida = clave
	await _clic(por_pareja[elegida][0])
	await _esperar(0.3)
	await _clic(por_pareja[elegida][1])
	await _esperar(0.3)
	print("[%s] clic real en par '%s' -> acertado=%s" % [perfil, elegida, por_pareja[elegida][0].esta_acertada])
	await _capturar("%s_3_par" % perfil)
	await _esperar(1.4)
	await _capturar("%s_4_progreso" % perfil)

	if motor._limite_intentos != null:
		motor._intentos_usados = motor._limite_intentos - 1
		var libres: Array = []
		for clave in claves:
			if not por_pareja[clave][0].esta_acertada:
				libres.append(por_pareja[clave][0])
		await _clic(libres[0])
		await _clic(libres[1])
		await _esperar(motor._tiempo_volteo_ms / 1000.0 + 1.0)
		print("[%s] derrota-gag -> boton_otra_vez visible=%s" % [perfil, motor._boton_otra_vez.visible])
		await _capturar("%s_5_derrota_gag" % perfil)
		motor._boton_otra_vez.pressed.emit()
		await _esperar(0.4)

	for clave in claves:
		var par: Array = por_pareja[clave]
		if not par[0].esta_acertada:
			par[0].tocada.emit(par[0])
			par[1].tocada.emit(par[1])
			await _esperar(0.05)
	await _esperar(3.2)
	await _capturar("%s_6_celebracion" % perfil)
	motor.queue_free()
	await _esperar(0.2)
