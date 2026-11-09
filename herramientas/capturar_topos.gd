extends SceneTree

## Pantallazos de «¿Quién habla?» (motor topos) en ventana real (no headless) para revisión visual del PO y de
## experto-ux-parvulo: un nivel por hermano en zonas representativas jugando, el acierto, la derrota-gag con su
## cartel y el modo equipo. Sin `planeta_id`: no escribe en ningún guardado.
##
## Uso: xvfb-run -a godot --path . --rendering-driver opengl3 --script herramientas/capturar_topos.gd -- <carpeta>

const MOTOR := "res://escenas/minijuegos/topos/motor_topos.tscn"
const NIVELES := {
	"maxi_z1": "res://datos/niveles/animalia/zona1_campamento/topos_semilla.json",
	"maxi_z5": "res://datos/niveles/animalia/zona5_valle/topos_semilla.json",
	"nicole_z3": "res://datos/niveles/animalia/zona3_pradera/topos_brote.json",
	"nicole_z5": "res://datos/niveles/animalia/zona5_valle/topos_brote.json",
	"sofia_z2": "res://datos/niveles/animalia/zona2_laguna/topos_estrella.json",
	"sofia_z5": "res://datos/niveles/animalia/zona5_valle/topos_estrella.json",
}

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_topos"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for clave in NIVELES:
		await _partida(clave)
	await _equipo()
	quit()


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var ruta := _carpeta.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("captura: ", ruta)


func _partida(clave: String) -> void:
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = NIVELES[clave]
	motor.fijar_semilla(5)
	root.add_child(motor)
	await create_timer(2.6).timeout
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 6000 and motor.logica.activos() < 2:
		await process_frame
	await create_timer(0.3).timeout
	await _foto("%s_1_jugando" % clave)
	var id: int = motor.logica.id_pedido()
	if id >= 0:
		motor.presionar(motor.punto_madriguera(id))
		await create_timer(0.12).timeout
		await _foto("%s_2_acierto" % clave)
	# Derrota: se acaba el sol sin la meta.
	motor.logica.tiempo = motor.logica.duracion - 0.05
	await create_timer(0.9).timeout
	await _foto("%s_3_gag" % clave)
	await create_timer(2.2).timeout
	await _foto("%s_4_cartel" % clave)
	motor.queue_free()
	await process_frame


func _equipo() -> void:
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/animalia/zona1_campamento/topos_equipo.json"
	var ids: Array[String] = ["maxi", "nicole", "sofia"]
	motor.equipo = ids
	motor.fijar_semilla(5)
	root.add_child(motor)
	await create_timer(1.5).timeout
	if motor.turnos.en_puerta():
		motor.turnos.abrir_puerta()
	await create_timer(2.5).timeout
	await _foto("equipo_1_turno")
	motor.queue_free()
	await process_frame
