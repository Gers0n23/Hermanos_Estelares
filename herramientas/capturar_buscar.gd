extends SceneTree

## Pantallazos del «Escondite animal» en ventana real (no headless), para revision visual del PO, de
## experto-ux-parvulo y de disenador-personajes: una escena por perfil y zona, un encontrado volando a la
## tarjeta, la derrota-gag con su cartel y la foto de grupo. Sin `planeta_id`: no escribe ningun guardado.
##
## Uso: godot --path . --script herramientas/capturar_buscar.gd -- <carpeta_salida> [zona1..5]
## (en Linux sin pantalla: xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 ...)

const MOTOR := "res://escenas/minijuegos/buscar/motor_buscar.tscn"
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_buscar"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	var zonas: Array = ZONAS
	if args.size() > 1:
		zonas = ZONAS.filter(func(z: String) -> bool: return z.begins_with(args[1]))
	for zona in zonas:
		for perfil in ["semilla", "brote", "estrella"]:
			await _partida(zona, perfil)
	quit()


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var ruta := _carpeta.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("captura: ", ruta)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _partida(zona: String, perfil: String) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/animalia/%s/buscar_%s.json" % [zona, perfil]
	motor.fijar_semilla(3)
	get_root().add_child(motor)
	var base := "%s_%s" % [zona.substr(0, 5), perfil]
	await _esperar(0.9)
	await _foto(base + "_0_intro")
	motor.tocar_pantalla(Vector2(640, 300))
	await _esperar(0.3)
	await _foto(base + "_1_escena")
	var l: LogicaBuscar = motor.logica
	var id: String = l.activos()[0]
	if l.revelado(id):
		motor.mover_vista_a(l.medida(id)["centro"], 0.0)
		await _esperar(0.2)
		await _foto(base + "_2_buscando")
		motor.tocar_mundo(l.medida(id)["centro"])
		await _esperar(0.45)
		await _foto(base + "_3_encontrado")
	if perfil != "semilla":
		l.t_intento = l.limite * 0.8
		await _esperar(0.2)
		await _foto(base + "_4_atardecer")
	l.t_intento = l.limite
	await _esperar(1.0)
	await _foto(base + "_5_gag")
	await _esperar(2.2)
	await _foto(base + "_6_cartel")
	motor.queue_free()
	await process_frame
