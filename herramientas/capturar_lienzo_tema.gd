extends SceneTree

## Pantallazos del lienzo CON TEMA (zona 1, ficha motor-lienzo-libre.md §8), en ventana: el
## selector de tema, la bolsa de stickers, la barra de edicion y una escena armada con stickers,
## conectores y viajeros, para Maxi, Nicole y Sofia.
##
## Uso: godot --path . --script herramientas/capturar_lienzo_tema.gd -- <carpeta>

const MOTOR := "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn"
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_tema"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for perfil in HERMANOS:
		await _capturar(perfil)
	quit(0)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := get_root().get_texture().get_image()
	imagen.save_png(_carpeta.path_join(nombre + ".png"))
	print("captura: ", nombre)


func _capturar(perfil: String) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/arcoiris/zona1_claro/pinta_%s.json" % perfil
	motor.id_perfil = HERMANOS[perfil]
	motor.carpeta_dibujos = "user://qa_dibujos"
	get_root().add_child(motor)
	await _esperar(1.0)
	if motor.eligiendo_tema:
		await _foto("%s_1_selector" % perfil)
		motor.elegir_tema(motor._hojas[0]["opciones"].size() - 1)
		await _esperar(0.6)
	var lienzo = motor.lienzo
	var ids: Array = motor._cfg.get("stickers", [])
	var lugares := [Vector2(150, 330), Vector2(420, 250), Vector2(680, 330), Vector2(260, 450), Vector2(560, 440),
		Vector2(700, 160), Vector2(130, 170), Vector2(420, 420), Vector2(300, 120), Vector2(540, 120)]
	var cuantos := mini(lugares.size(), maxi(ids.size(), 5))
	for i in cuantos:
		motor._elegir_herramienta("sello_" + str(ids[i % ids.size()]), false)
		lienzo.empezar_trazo(lugares[i])
		lienzo.terminar_trazo()
	motor._elegir_herramienta("pincel", false)
	lienzo.empezar_trazo(Vector2(60, 500))
	for k in 20:
		lienzo.continuar_trazo(Vector2(60 + k * 12, 500 - sin(k * 0.5) * 20))
	lienzo.terminar_trazo()
	motor._elegir_herramienta("conector", false)
	var puntos := [lugares[0], (lugares[0] + lugares[1]) / 2.0 + Vector2(0, 70), lugares[1], lugares[2]]
	lienzo.empezar_trazo(puntos[0])
	for i in range(1, puntos.size()):
		for k in range(1, 10):
			lienzo.continuar_trazo(puntos[i - 1].lerp(puntos[i], k / 9.0))
	lienzo.terminar_trazo()
	lienzo.empezar_trazo(lugares[3])
	for k in range(1, 12):
		lienzo.continuar_trazo(lugares[3].lerp(lugares[4], k / 11.0) + Vector2(0, sin(k * 0.6) * 25))
	lienzo.terminar_trazo()
	await _esperar(1.6)
	await _foto("%s_2_escena" % perfil)
	if (motor._cfg.get("herramientas", []) as Array).has("bolsa"):
		motor._abrir_bandeja()
		await _esperar(0.4)
		await _foto("%s_3_bolsa" % perfil)
		motor._cerrar_bandeja()
		motor._elegir_herramienta("sello_" + str(ids[0]), false)
		lienzo.empezar_trazo(lugares[1])
		lienzo.terminar_trazo()
		await _esperar(0.5)
		await _foto("%s_4_edicion" % perfil)
	lienzo.componer().save_png(_carpeta.path_join("%s_5_png_guardado.png" % perfil))
	motor.queue_free()
	await _esperar(0.3)
