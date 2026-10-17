extends SceneTree

## Pantallazos EN VENTANA del lienzo v2 (ficha motor-lienzo-libre.md §9): la escena piloto de cada
## hermano (parque de dinos, granja de ponys, ciudad de los ponys) con la inspiracion abierta, la
## escena armada con objetivos, un popup del dock, la pista fantasma y (Nicole y Sofia) el zoom.
## No toca progreso.json (corre con --script; el motor no usa Progreso sin `planeta_id`).
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


func _poner(motor, id: String, p: Vector2):
	motor._elegir_herramienta("sello_" + id, false)
	motor.lienzo.empezar_trazo(p)
	motor.lienzo.terminar_trazo()
	return motor.lienzo.stickers().back()


func _arrastrar(lienzo, sticker, destino: Vector2) -> void:
	var desde: Vector2 = sticker.centro()
	lienzo.empezar_trazo(desde)
	for k in range(1, 13):
		lienzo.continuar_trazo(desde.lerp(destino, k / 12.0))
	lienzo.terminar_trazo()


func _trazar(motor, tipo: String, puntos: Array) -> void:
	motor._elegir_herramienta("camino_" + tipo, false)
	var lienzo = motor.lienzo
	lienzo.empezar_trazo(puntos[0])
	for i in range(1, puntos.size()):
		for k in range(1, 9):
			lienzo.continuar_trazo(puntos[i - 1].lerp(puntos[i], k / 8.0))
	lienzo.terminar_trazo()


func _capturar(perfil: String) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/arcoiris/zona1_claro/pinta_%s.json" % perfil
	motor.id_perfil = HERMANOS[perfil]
	motor.carpeta_dibujos = "user://qa_dibujos"
	get_root().add_child(motor)
	await _esperar(1.2)
	await _foto("%s_1_inspiracion" % perfil)
	motor._cerrar_inspiracion()
	var lienzo = motor.lienzo
	match perfil:
		"semilla":
			_poner(motor, "trex", Vector2(560, 470))
			_poner(motor, "trex", Vector2(720, 500))
			await _esperar(1.0)
			_trazar(motor, "sendero", [Vector2(1010, 470), Vector2(700, 600), Vector2(480, 610)])
			_poner(motor, "spinosaurio", Vector2(420, 380))
			await _esperar(2.5)
		"brote":
			var granero = lienzo.lugar_por_id("granero")
			_poner(motor, "pony_amigo", Vector2(520, 640))
			_trazar(motor, "sendero", [granero.centro() + Vector2(40, 30), Vector2(600, 500), Vector2(960, 520)])
			_arrastrar(lienzo, _poner(motor, "pony_amigo", Vector2(80, 650)), granero.centro())
			_poner(motor, "sol", Vector2(700, 140))
			_arrastrar(lienzo, _poner(motor, "nube_lluvia", Vector2(900, 150)), Vector2(745, 150))
			_poner(motor, "flor", Vector2(160, 660))
			_poner(motor, "arbol", Vector2(560, 300))
			await _esperar(2.5)
		"estrella":
			var casas: Array = []
			for x in [180, 300, 420]:
				casas.append(_poner(motor, "casa", Vector2(x, 300)))
			var castillo = _poner(motor, "castillo", Vector2(980, 260))
			_trazar(motor, "sendero", [casas[2].centro(), Vector2(700, 330), castillo.centro()])
			_arrastrar(lienzo, _poner(motor, "pony_amigo", Vector2(560, 450)), casas[2].centro())
			_poner(motor, "pony_amigo", Vector2(240, 680))
			_poner(motor, "nube", Vector2(400, 120))
			_arrastrar(lienzo, _poner(motor, "nube", Vector2(600, 120)), Vector2(440, 125))
			var loop: Array = []
			for k in 25:
				loop.append(Vector2(1000, 480) + Vector2.from_angle(TAU * k / 24.0) * Vector2(130, 55))
			_trazar(motor, "arcoiris", loop)
			await _esperar(2.5)
	await _foto("%s_2_escena" % perfil)
	motor.abrir_popup("cosas")
	await _esperar(0.4)
	await _foto("%s_3_popup_cosas" % perfil)
	motor._cerrar_popup()
	motor.pista_fantasma()
	await _esperar(0.6)
	await _foto("%s_4_pista_fantasma" % perfil)
	if perfil != "semilla":
		motor.abrir_popup("colores")
		await _esperar(0.3)
		await _foto("%s_5_popup_colores" % perfil)
		motor._cerrar_popup()
		motor.usar_lupa()
		lienzo.usar_lupa_en(Vector2(420, 330))
		await _esperar(0.5)
		await _foto("%s_6_zoom" % perfil)
		lienzo.ver_todo()
	lienzo.componer().save_png(_carpeta.path_join("%s_7_png_guardado.png" % perfil))
	motor.queue_free()
	await _esperar(0.3)
