extends SceneTree

## Pantallazos de "Formas traviesas" y del mapa del Planeta Arcoiris en ventana real (no headless),
## para revision visual del PO / experto-ux-parvulo. Incluye un ARRASTRE REAL con `push_input`
## (presionar, mover, soltar), igual que un dedo o el mouse.
## Respalda y restaura `user://progreso.json`.
##
## Uso: godot --path . --script herramientas/capturar_encajar.gd -- <carpeta_salida>

const MOTOR := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const GUARDADO := "user://progreso.json"

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_encajar"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	var progreso := get_root().get_node("Progreso")
	var respaldo = FileAccess.get_file_as_string(GUARDADO) if FileAccess.file_exists(GUARDADO) else null

	await _arrastre_real()
	for zona in ZONAS:
		for perfil in HERMANOS:
			await _nivel(zona, perfil)
	await _derrota("zona4_islotes", "brote")
	await _mapas(progreso)

	if respaldo != null:
		var archivo := FileAccess.open(GUARDADO, FileAccess.WRITE)
		archivo.store_string(respaldo)
		archivo.close()
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


func _abrir(zona: String, perfil: String) -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/arcoiris/%s/formas_%s.json" % [zona, perfil]
	motor.id_perfil = HERMANOS[perfil]
	motor.segundos_auto_continuar = 0.0
	get_root().add_child(motor)
	await _esperar(1.2)
	return motor


func _mouse(tipo: String, punto: Vector2) -> void:
	var evento: InputEvent
	if tipo == "mover":
		evento = InputEventMouseMotion.new()
		evento.button_mask = MOUSE_BUTTON_MASK_LEFT
	else:
		evento = InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.pressed = tipo == "presionar"
	evento.position = punto
	evento.global_position = punto
	get_root().push_input(evento, true)
	await process_frame


## Maxi, zona 1: arrastra de verdad una pieza hasta su silueta.
func _arrastre_real() -> void:
	var motor := await _abrir("zona1_claro", "semilla")
	var pieza: PiezaEncajar = motor._piezas[0]
	var hueco: Dictionary = motor._hueco_para(pieza)
	var desde := pieza.centro_global()
	var hasta: Vector2 = hueco["centro"] + Vector2(40, 30)
	await _mouse("presionar", desde)
	for k in range(1, 13):
		await _mouse("mover", desde.lerp(hasta, k / 12.0))
		if k == 7:
			await _capturar("00_maxi_arrastrando")
	await _mouse("soltar", hasta)
	await _esperar(0.6)
	print("[arrastre real] pieza %s encajada=%s" % [pieza.id, pieza.colocada])
	await _capturar("01_maxi_encajo_arrastrando")
	motor.queue_free()
	await _esperar(0.2)


func _nivel(zona: String, perfil: String) -> void:
	var motor := await _abrir(zona, perfil)
	var nombre := "%s_%s" % [zona.substr(0, 5), perfil]
	await _capturar(nombre + "_1_inicio")
	# Deja todo resuelto menos una pieza para ver las figuras armadas.
	var pendientes: Array = []
	for hueco in motor._huecos:
		if not hueco["opcional"]:
			pendientes.append(hueco)
	for i in pendientes.size() - 1:
		var hueco: Dictionary = pendientes[i]
		var pieza := _pieza_para(motor, hueco)
		if pieza == null:
			continue
		pieza.girar_a(hueco["rotacion"], 0.0)
		for k in 8:
			if motor._calza(pieza, hueco):
				break
			pieza.girar_a(pieza.rotacion_grados + motor._paso_rotacion, 0.0)
		motor.soltar_pieza(pieza, hueco["centro"])
		await _esperar(0.08)
	for hueco in motor._huecos:
		if hueco["opcional"]:
			var tesoro := _pieza_para(motor, hueco)
			if tesoro != null:
				motor.soltar_pieza(tesoro, hueco["centro"])
	await _esperar(1.4)
	await _capturar(nombre + "_2_casi")
	motor.queue_free()
	await _esperar(0.2)


func _pieza_para(motor: Node, hueco: Dictionary) -> PiezaEncajar:
	for pieza in motor._piezas:
		if pieza.colocada:
			continue
		for k in 8:
			if Geo.calzan(pieza.poligono(k * 45.0), hueco["forma_centrada"]):
				return pieza
	return null


func _derrota(zona: String, perfil: String) -> void:
	var motor := await _abrir(zona, perfil)
	motor._intentos_usados = int(motor._limite_intentos) - 1
	var pieza: PiezaEncajar = null
	var destino = null
	for p in motor._piezas:
		for hueco in motor._huecos:
			if not Geo.calzan(p.poligono(hueco["rotacion"]), hueco["forma_centrada"]):
				pieza = p
				destino = hueco
				break
		if pieza != null:
			break
	motor.soltar_pieza(pieza, destino["centro"])
	await _esperar(0.9)
	await _capturar("%s_%s_3_derrota_gag" % [zona.substr(0, 5), perfil])
	await _esperar(1.0)
	await _capturar("%s_%s_4_otra_vez" % [zona.substr(0, 5), perfil])
	motor.queue_free()
	await _esperar(0.2)


func _mapas(progreso: Node) -> void:
	progreso._datos = progreso._crear_datos_por_defecto()
	progreso.perfil_seleccionado = "maxi"
	change_scene_to_file(ARCOIRIS)
	await _esperar(1.5)
	await _capturar("mapa_1_maxi_inicio")
	for n in [1, 2, 3]:
		progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_z%d_formas_estrella" % n, 50, n)
	progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_emparejar_estrella_01", 50, 2)
	progreso.perfil_seleccionado = "sofia"
	change_scene_to_file(ARCOIRIS)
	await _esperar(0.3)
	var mapa := current_scene
	mapa._tocar_zona(1)
	await _esperar(1.8)
	await _capturar("mapa_2_sofia_zona2")
	progreso.marcar_nivel_completado("sofia", "arcoiris", "arcoiris_z4_formas_estrella", 50, 3)
	change_scene_to_file(ARCOIRIS)
	await _esperar(2.4)
	await _capturar("mapa_3_sofia_cima_revelada")
