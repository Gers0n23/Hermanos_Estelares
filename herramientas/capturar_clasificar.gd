extends SceneTree

## Juega "Lluvia de colores" con CLICS Y ARRASTRES REALES en ventana (no headless) y saca
## pantallazos de las 15 variantes para revision visual del PO / experto-ux-parvulo. La entrada pasa
## por `push_input`, igual que un dedo o el mouse, asi que tambien prueba la entrada de verdad.
##
## Uso: godot --path . --script herramientas/capturar_clasificar.gd -- <carpeta_salida> [filtro]

const MOTOR := "res://escenas/minijuegos/clasificar/motor_clasificar.tscn"
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_clasificar"
	var filtro: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/lluvia_%s.json" % [zona, perfil]
			if filtro == "" or ruta.contains(filtro):
				await _jugar(ruta, zona, perfil)
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


func _boton(punto: Vector2, presionado: bool) -> void:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = presionado
	evento.button_mask = MOUSE_BUTTON_MASK_LEFT if presionado else 0
	evento.position = punto
	evento.global_position = punto
	get_root().push_input(evento, true)


func _clic(punto: Vector2) -> void:
	_boton(punto, true)
	await process_frame
	_boton(punto, false)
	await process_frame


## Arrastre real: presiona, mueve en pasos (como un dedo) y suelta.
func _arrastrar(desde: Vector2, hasta: Vector2, capturar_en_medio := "") -> void:
	_boton(desde, true)
	await process_frame
	for i in range(1, 13):
		var punto := desde.lerp(hasta, i / 12.0)
		var movimiento := InputEventMouseMotion.new()
		movimiento.button_mask = MOUSE_BUTTON_MASK_LEFT
		movimiento.position = punto
		movimiento.global_position = punto
		movimiento.relative = (hasta - desde) / 12.0
		get_root().push_input(movimiento, true)
		await process_frame
		if i == 10 and capturar_en_medio != "":
			await _capturar(capturar_en_medio)
	_boton(hasta, false)
	await process_frame


func _jugar(ruta: String, zona: String, perfil: String) -> void:
	var nombre := "%s_%s" % [zona.substr(0, 5), perfil]
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = HERMANOS[perfil]
	motor.segundos_auto_continuar = 0.0
	get_root().add_child(motor)
	await _esperar(1.8)
	await _capturar(nombre + "_1_inicio")

	var gotas: Array = motor.gotas_activas()
	if gotas.is_empty():
		await _esperar(1.0)
		gotas = motor.gotas_activas()
	var gota = null
	for g in gotas:
		if g.tipo != "gris" and (motor._modo == "libre" or motor.charco_correcto_para(g) != null):
			gota = g
	if gota != null:
		if motor._modo == "libre" or motor._arcoiris_cielo:
			var color_tocado: String = gota.color_id
			await _clic(gota.centro_global())
			print("[%s] clic real en gota %s" % [nombre, color_tocado])
			await _esperar(0.35)
			await _capturar(nombre + "_2_magia")
		else:
			var charco = motor.charco_correcto_para(gota)
			var antes: int = motor._logrados_ronda
			await _arrastrar(gota.centro_global(), charco.centro_charco(), nombre + "_2_arrastre")
			await _esperar(0.3)
			print("[%s] arrastre real de %s -> logrados %d -> %d, recibidos=%s" % [nombre, gota.color_id, antes, motor._logrados_ronda, charco.recibidos])
			await _capturar(nombre + "_3_acierto")
	await _esperar(1.2)

	# Momentos memorables por ruta (se fuerzan para poder verlos en la captura).
	if perfil == "semilla" and zona == "zona3_chupetines":
		motor._dino_de_pintura(Vector2(700, 470), Color("#5CCB5F"))
		await _esperar(0.5)
		await _capturar(nombre + "_4_dino")
	if perfil == "semilla" and zona == "zona5_cima":
		for i in 3:
			await _esperar_gota(motor)
			var siguiente: Array = motor.gotas_activas()
			if not siguiente.is_empty():
				await _clic(siguiente[0].centro_global())
			await _esperar(1.0)
		await _capturar(nombre + "_4_arcoiris")
	if perfil == "estrella":
		motor._mural_arcoiris()
		await _esperar(1.6)
		await _capturar(nombre + "_4_mural")
		await _esperar(1.0)
	if perfil == "brote" and zona == "zona3_chupetines":
		motor._arcoiris_especial()
		var jirafa = motor._crear_gota("amarillo", "jirafa")
		jirafa.fijar_centro(Vector2(560, 300))
		jirafa.cayendo = false
		await _esperar(0.6)
		await _capturar(nombre + "_4_jirafa")

	if motor._limite != null:
		await _esperar_gota(motor)
		motor._fallos_ronda = int(motor._limite) - 1
		var mala = null
		var destino = null
		for g in motor.gotas_activas():
			for c in motor.charcos_activos():
				if motor._nombrar:
					if g.color_id != motor._color_pedido:
						mala = g
						destino = motor._charco_objetivo
				elif c != motor.charco_correcto_para(g) and not (c.es_mezcla and c.faltantes().has(g.color_id)) and not c.resuelto:
					mala = g
					destino = c
		if mala != null:
			await _arrastrar(mala.centro_global(), destino.centro_charco())
			await _esperar(1.0)
			await _capturar(nombre + "_5_derrota_gag")
			await _esperar(1.0)
			print("[%s] derrota-gag -> boton_otra_vez visible=%s" % [nombre, motor._boton_otra_vez.visible])
			await _capturar(nombre + "_6_otra_vez")
			await _clic(motor._boton_otra_vez.get_global_rect().get_center())
			await _esperar(0.5)
			print("[%s] clic real en otra vez -> en_gag=%s" % [nombre, motor._en_gag])
	motor.queue_free()
	await _esperar(0.3)


func _esperar_gota(motor) -> void:
	var t := 0.0
	while (motor.gotas_activas().is_empty() or motor.esta_esperando()) and t < 6.0:
		await _esperar(0.1)
		t += 0.1
