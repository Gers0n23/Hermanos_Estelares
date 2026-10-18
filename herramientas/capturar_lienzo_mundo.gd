extends SceneTree

## Pantallazos EN VENTANA del mundo grande del lienzo (ficha motor-lienzo-libre.md §12): por cada
## escena piloto (parque de dinos de Maxi, granja de Nicole, ciudad de Sofia) la tarjeta de
## inspiracion, el zoom de arranque con unos stickers puestos, "ver todo" (la hoja entera) y, en el
## mundo grande, la camara yendo sola a una pista fuera de la vista. No toca progreso.json.
##
## Uso: godot --path . --script herramientas/capturar_lienzo_mundo.gd -- <carpeta>

const MOTOR := "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn"
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_mundo"
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
	get_root().get_texture().get_image().save_png(_carpeta.path_join(nombre + ".png"))
	print("captura: ", nombre)


func _poner(motor, id: String, p: Vector2) -> void:
	motor._elegir_herramienta("sello_" + id, false)
	motor.lienzo.empezar_trazo(p)
	motor.lienzo.terminar_trazo()


func _capturar(perfil: String) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/arcoiris/zona1_claro/pinta_%s.json" % perfil
	motor.id_perfil = HERMANOS[perfil]
	motor.carpeta_dibujos = "user://qa_dibujos"
	get_root().add_child(motor)
	await _esperar(1.2)
	await _foto("%s_mundo_0_inspiracion" % perfil)
	motor._cerrar_inspiracion()
	var lienzo = motor.lienzo
	print("%s: mundo %s, zoom %.2f, vista %s" % [perfil, lienzo.tamano, lienzo.zoom, lienzo.vista_mundo()])
	# Unos stickers en lo que se ve al arrancar: miden en pantalla lo mismo que antes.
	var c: Vector2 = lienzo.centro_de_vista()
	var ids: Dictionary = {
		"semilla": [["trex", Vector2(-180, 140)], ["arbol", Vector2(120, 110)], ["huevo", Vector2(300, 220)]],
		"brote": [["pony_amigo", Vector2(-200, 180)], ["arbol", Vector2(60, 90)], ["flor", Vector2(240, 230)], ["nube", Vector2(150, -250)]],
		"estrella": [["casa", Vector2(-250, 60)], ["casa", Vector2(-120, 60)], ["pony_amigo", Vector2(60, 220)], ["arbol", Vector2(230, 90)], ["nube", Vector2(-50, -260)]],
	}
	for dato: Array in ids[perfil]:
		_poner(motor, dato[0], c + dato[1])
	motor._elegir_herramienta("pincel", false)
	lienzo.empezar_trazo(c + Vector2(-330, 260))
	for k in range(1, 21):
		lienzo.continuar_trazo(c + Vector2(-330 + k * 14, 260 + sin(k * 0.6) * 18))
	lienzo.terminar_trazo()
	await _esperar(1.5)
	await _foto("%s_mundo_1_zoom_inicial" % perfil)
	if motor._boton_ver_todo.visible:
		motor._boton_ver_todo.pressed.emit()
	else:
		lienzo.ver_todo()
	await _esperar(0.5)
	await _foto("%s_mundo_2_ver_todo" % perfil)
	if lienzo.escala_mundo > 1.0:
		lienzo.encuadre_inicial()
		await _esperar(0.3)
		lienzo.mostrar_fantasma({"tipo": "sticker", "id": "sol", "pos": Vector2(lienzo.tamano.x - 420.0, 200.0)}, 4.0)
		await _esperar(lienzo.SEGUNDOS_ENFOQUE + 0.3)
		await _foto("%s_mundo_3_pista_enfocada" % perfil)
	lienzo.componer().save_png(_carpeta.path_join("%s_mundo_4_png_guardado.png" % perfil))
	motor.queue_free()
	await _esperar(0.3)
