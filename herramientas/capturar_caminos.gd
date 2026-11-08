extends SceneTree

## Pantallazos de «Cada quien a su casa» (motor caminos) en ventana real, para revisión visual del PO y de
## experto-ux-parvulo: Maxi, Nicole y Sofía (z1, z3 y z5) con caminos a medias, un tablero lleno y la tormenta.
## Usa el guardado de pruebas (Progreso lo elige solo al correr desde una herramienta).
##
## Uso: godot --path . --rendering-driver opengl3 --script herramientas/capturar_caminos.gd -- <carpeta_salida>
## (sin pantalla: xvfb-run -a godot ...)

const MOTOR := "res://escenas/minijuegos/caminos/motor_caminos.tscn"
const CASOS := [
	["maxi_z1", "res://datos/niveles/animalia/zona1_campamento/caminos_semilla.json"],
	["maxi_z5", "res://datos/niveles/animalia/zona5_valle/caminos_semilla.json"],
	["nicole_z1", "res://datos/niveles/animalia/zona1_campamento/caminos_brote.json"],
	["nicole_z3", "res://datos/niveles/animalia/zona3_pradera/caminos_brote.json"],
	["sofia_z2", "res://datos/niveles/animalia/zona2_laguna/caminos_estrella.json"],
	["sofia_z5", "res://datos/niveles/animalia/zona5_valle/caminos_estrella.json"],
]

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_caminos"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for caso in CASOS:
		await _partida(caso[0], caso[1])
	quit()


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var ruta := _carpeta.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("captura: ", ruta)


func _esperar(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await process_frame


func _partida(nombre: String, ruta: String) -> void:
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.transformacion_forzada = 0
	root.add_child(motor)
	await _esperar(1.2)
	var logica: LogicaCaminos = motor.logica
	# La mitad de los pares resueltos con la solución, uno a medias.
	var pares := logica.pares
	for k in pares.size():
		var sol: Array = logica.solucion[pares[k]]
		if k < pares.size() / 2:
			motor.trazar_celdas(sol)
		elif k == pares.size() / 2:
			motor.presionar(motor.centro_celda(sol[0]))
			for j in range(1, maxi(2, sol.size() / 2)):
				motor.arrastrar(motor.centro_celda(sol[j]))
	await _esperar(1.5)
	await _foto(nombre + "_jugando")
	motor.soltar()
	motor.avanzar_reloj(motor.limite_tormenta() + 1.0)
	await _esperar(0.8)
	await _foto(nombre + "_tormenta")
	await _esperar(2.5)
	await _foto(nombre + "_otra_vez")
	motor.queue_free()
	await process_frame
