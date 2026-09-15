extends SceneTree

## Pantallazos de los retos de Sofia (dificultad v3) en ventana real, para revision visual del PO y de
## experto-ux-parvulo: tangram libre (a medio armar), espejo, copia de memoria (modelo y tapada),
## marcos de pentominos, Desafio de la Cima, reto dorado, las 6 variantes de Parejas y el mapa con
## el boton del reto dorado. No toca el guardado (motores sin planeta_id, mapa sin completar nada).
##
## Uso: godot --path . --script herramientas/capturar_retos_sofia.gd -- <carpeta_salida>

const MOTOR_ENCAJAR := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const MOTOR_EMPAREJAR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const NIVELES := "res://datos/niveles/arcoiris/"

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_retos_sofia"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	await _formas("zona1_claro/formas_estrella.json", "formas_z1_tangram", 3)
	await _formas("zona2_charcos/formas_estrella.json", "formas_z2_espejo", 2)
	await _memoria("zona3_chupetines/formas_estrella.json", "formas_z3_memoria")
	await _formas("zona4_islotes/formas_estrella.json", "formas_z4_marco", 2)
	await _formas("zona5_cima/formas_estrella.json", "formas_z5_cima_tangram_doble", 5)
	await _formas("zona5_cima/formas_estrella_dorado.json", "formas_dorado_6x10", 4)
	for zona in ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]:
		await _parejas(zona + "/parejas_estrella.json", "parejas_" + zona)
	await _parejas("zona5_cima/parejas_estrella_dorado.json", "parejas_dorado")
	await _mapa()
	quit(0)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := get_root().get_texture().get_image()
	var ruta := _carpeta.path_join(nombre + ".png")
	imagen.save_png(ruta)
	print("captura: ", ruta)


func _motor(escena: String, ruta: String) -> Node:
	var motor: Node = load(escena).instantiate()
	motor.ruta_nivel = NIVELES + ruta
	motor.id_perfil = "sofia"
	get_root().add_child(motor)
	return motor


## Arma una parte con pistas (para ver piezas puestas junto a la silueta) y captura.
func _formas(ruta: String, nombre: String, pistas: int) -> void:
	var motor := _motor(MOTOR_ENCAJAR, ruta)
	await _esperar(1.4)
	await _capturar(nombre + "_inicio")
	for i in pistas:
		motor.colocar_pista()
		await _esperar(0.35)
	if motor._boton_espejo_activo and not motor._piezas.is_empty():
		for pieza in motor._piezas:
			if not pieza.colocada:
				motor._elegir(pieza)
				break
	await _esperar(0.8)
	await _capturar(nombre + "_armando")
	motor.queue_free()
	await _esperar(0.2)


func _memoria(ruta: String, nombre: String) -> void:
	var motor := _motor(MOTOR_ENCAJAR, ruta)
	await _esperar(1.5)
	await _capturar(nombre + "_modelo")
	var t0 := Time.get_ticks_msec()
	while motor._siluetas.cortina < 0.6 and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	await _capturar(nombre + "_cortina")
	while motor._en_modelo and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	await _esperar(0.5)
	motor.colocar_pista()
	await _esperar(0.6)
	await _capturar(nombre + "_tapada")
	motor.queue_free()
	await _esperar(0.2)


func _parejas(ruta: String, nombre: String) -> void:
	var motor := _motor(MOTOR_EMPAREJAR, ruta)
	await _esperar(1.6)
	# Se destapan algunas cartas para ver caras, sombras y recetas.
	var cartas: Array = motor._cartas
	for i in mini(cartas.size(), 10):
		cartas[i].seleccionar()
	await _esperar(0.6)
	await _capturar(nombre)
	motor.queue_free()
	await _esperar(0.2)


func _mapa() -> void:
	var progreso := get_root().get_node_or_null("Progreso")
	if progreso != null:
		progreso.perfil_seleccionado = "sofia"
	var Mapa = load("res://scripts/nucleo/mapa_planeta.gd")
	Mapa.todo_abierto = true
	var mapa: Node = load("res://escenas/planetas/arcoiris/mapa_arcoiris.tscn").instantiate()
	get_root().add_child(mapa)
	await _esperar(0.6)
	mapa.seleccion = 4
	mapa._mostrar_estaciones()
	await _esperar(0.6)
	await _capturar("mapa_cima_retos_dorados")
	Mapa.todo_abierto = false
	mapa.queue_free()
