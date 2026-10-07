extends SceneTree

## Pantallazos del «Río de pintura» en ventana real (no headless), para revisión visual del PO y de
## experto-ux-parvulo: los 3 hermanos con el río entrando, apuntando, un reventón, el peligro cerca del
## remolino, el cartel de "¡Glu glu glu!", el "¡Río limpio!" y la estación en el mapa del planeta.
## Usa el guardado de pruebas (Progreso lo elige solo al correr desde una herramienta).
##
## Uso: godot --path . --script herramientas/capturar_rio.gd -- <carpeta_salida>

const MOTOR := "res://escenas/minijuegos/rio/motor_rio.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const NIVELES := {
	"maxi": "res://datos/niveles/arcoiris/zona1_claro/rio_semilla.json",
	"nicole": "res://datos/niveles/arcoiris/zona1_claro/rio_brote.json",
	"sofia": "res://datos/niveles/arcoiris/zona1_claro/rio_estrella.json",
}

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_rio"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for hermano in NIVELES:
		await _partida(hermano)
	await _mapa()
	quit()


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var ruta := _carpeta.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("captura: ", ruta)


func _clic(motor, posicion: Vector2, presionado: bool) -> void:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = presionado
	evento.position = posicion
	motor._al_input_juego(evento)


func _partida(hermano: String) -> void:
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = NIVELES[hermano]
	motor.id_perfil = hermano
	motor.fijar_semilla(5)
	root.add_child(motor)
	await create_timer(4.5).timeout
	# Apuntando (con el dedo apretado: se ve la guía de Nicole y Maxi).
	_clic(motor, Vector2(980, 160), true)
	motor.apuntar_a(Vector2(980, 160))
	await _foto("%s_1_apuntando" % hermano)
	_clic(motor, Vector2(980, 160), false)
	await create_timer(0.25).timeout
	await _foto("%s_2_disparo" % hermano)
	# Peligro: el río entero cerca del remolino.
	var adelanto: float = motor.recorrido.largo * 0.86 - motor.logica.gotas[0]["s"]
	for g in motor.logica.gotas:
		g["s"] += adelanto
	await create_timer(0.6).timeout
	await _foto("%s_3_peligro" % hermano)
	# Perder.
	adelanto = motor.recorrido.largo + 1.0 - motor.logica.gotas[0]["s"]
	for g in motor.logica.gotas:
		g["s"] += adelanto
	await create_timer(0.6).timeout
	await _foto("%s_4_tragando" % hermano)
	var t := 0.0
	while motor.fase() != "perdio" and t < 6.0:
		await create_timer(0.2).timeout
		t += 0.2
	await create_timer(0.4).timeout
	await _foto("%s_5_glu_glu" % hermano)
	# Ganar.
	motor.reintentar()
	await create_timer(2.0).timeout
	motor.logica.gotas.clear()
	await create_timer(0.8).timeout
	await _foto("%s_6_rio_limpio" % hermano)
	motor.queue_free()
	await create_timer(0.2).timeout


func _mapa() -> void:
	var progreso := root.get_node("Progreso")
	progreso.seleccionar_perfil("nicole")
	var mapa = load(ARCOIRIS).instantiate()
	root.add_child(mapa)
	await create_timer(2.5).timeout
	await _foto("mapa_arcoiris_nicole")
	mapa.queue_free()
	await create_timer(0.2).timeout
