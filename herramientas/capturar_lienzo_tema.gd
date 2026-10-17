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
	lienzo.mostrar_fantasma({}, 0.0)
	await _capturar_fisica(motor, perfil)
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


## Ficha §10: caida con "¡puff!", sol fuera del cielo (tiznado y vuelta), botones deshacer/reiniciar.
func _capturar_fisica(motor, perfil: String) -> void:
	var lienzo = motor.lienzo
	# Ficha §11: amigos, borrar un camino con el dedo quieto y Coco en su burbujita.
	motor.abrir_popup("cosas" if perfil == "semilla" else "amigos")
	await _esperar(0.4)
	await _foto("%s_16_popup_amigos" % perfil)
	motor._cerrar_popup()
	_poner(motor, motor.obtener_id_personaje(), Vector2(560, 680))
	_poner(motor, "papa", Vector2(470, 690))
	_poner(motor, "cometa", Vector2(820, 110))
	_poner(motor, "coleccionauta", Vector2(1000, 120))
	await _esperar(1.2)
	await _foto("%s_17_amigos_en_escena" % perfil)
	# §11.9 jinetes: un hermano sobre un pony, un dino, un auto y un bus (dos asientos).
	var hermano: String = motor.obtener_id_personaje()
	var monturas: Array = []
	for dato in [["pony_amigo", 560.0], ["trex", 720.0], ["carrito", 880.0], ["bus", 1040.0]]:
		var montura = lienzo.poner_sticker(dato[0], Vector2(dato[1], 650))
		monturas.append(montura)
		var jinete = lienzo.poner_sticker(hermano, Vector2(dato[1], 470))
		_arrastrar(lienzo, jinete, montura.centro() + Vector2(0, -20))
	_arrastrar(lienzo, lienzo.poner_sticker("papa", Vector2(1100, 470)), monturas[3].centro() + Vector2(20, -20))
	await _esperar(0.8)
	await _foto("%s_22_jinetes" % perfil)
	_arrastrar(lienzo, monturas[0], Vector2(420, 420))
	await _esperar(0.5)
	await _foto("%s_23_jinete_se_mueve" % perfil)
	_trazar(motor, "sendero", [Vector2(100, 700), Vector2(265, 704), Vector2(430, 700)])
	await _esperar(0.3)
	motor._elegir_herramienta("camino_sendero", false)
	lienzo.empezar_trazo(Vector2(265, 704))
	await _esperar(lienzo.segundos_borrar_camino * 0.8)
	await _foto("%s_18_borrar_camino_aviso" % perfil)
	await _esperar(lienzo.segundos_borrar_camino * 0.3)
	await _esperar(0.05)
	await _foto("%s_19_camino_borrado" % perfil)
	lienzo.terminar_trazo()
	motor._voz_diferida_id += 1
	motor._pausa_pista = 60.0
	var audio := get_root().get_node_or_null("Audio")
	if audio != null:
		audio.detener_voz()
	motor._coco_hasta = 0.0
	while motor._burbuja_coco.visible:
		await process_frame
	await _foto("%s_20_coco_oculto" % perfil)
	motor.tocar_objetivo(motor._indices_activos()[0] if not motor._indices_activos().is_empty() else 0)
	await _esperar(0.4)
	await _foto("%s_21_coco_habla" % perfil)
	var id: String = {"semilla": "huevo", "brote": "pony_amigo", "estrella": "casa"}[perfil]
	var cosa = _poner(motor, id, Vector2(640, lienzo.cielo.position.y + 50.0))
	await _esperar(0.12 if perfil == "estrella" else 0.22)
	await _foto("%s_8_cae" % perfil)
	while lienzo.esta_cayendo(cosa):
		await process_frame
	await _esperar(0.06)
	await _foto("%s_9_puff" % perfil)
	await _esperar(0.8)
	if perfil != "semilla":
		var centro := Vector2(760, 630)
		_poner(motor, "arbol", centro + Vector2(-95, 0))
		_poner(motor, "flor", centro + Vector2(95, 20))
		_poner(motor, "sol", centro)
		await _esperar(0.3)
		await _foto("%s_10_tiznado" % perfil)
		await _esperar(0.55)
		await _foto("%s_11_sol_vuelve" % perfil)
		await _esperar(3.4)
		await _foto("%s_12_limpios" % perfil)
	motor._empezar_a_mantener()
	await _esperar(0.7)
	await _foto("%s_13_escoba_anillo" % perfil)
	while not motor._barriendo:
		await process_frame
	await _esperar(0.25)
	await _foto("%s_14_fuuush" % perfil)
	motor._soltar_reiniciar()
	while motor._barriendo:
		await process_frame
	await _esperar(0.3)
	await _foto("%s_15_hoja_reiniciada" % perfil)
