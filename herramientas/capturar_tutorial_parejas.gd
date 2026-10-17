extends SceneTree

## Capturas del tutorial de una sola vez y del vistazo de TODAS las cartas de "Parejas de Coco"
## (PO 17-Oct-2026), en ventana (no headless), para revision visual del PO / experto-ux-parvulo.
## Sin `planeta_id` el motor no toca el guardado y el tutorial sale siempre.
##
## Uso: godot --path . --script herramientas/capturar_tutorial_parejas.gd -- <carpeta_salida>

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const CASOS := [
	["maxi", "res://datos/niveles/arcoiris/zona1_claro/parejas_semilla.json"],
	["nicole", "res://datos/niveles/arcoiris/zona2_charcos/parejas_brote.json"],
	["sofia", "res://datos/niveles/arcoiris/zona1_claro/parejas_estrella.json"],
]

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_tutorial_parejas"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for caso in CASOS:
		await _capturar(caso[0], caso[1])
	quit(0)


func _capturar(id: String, ruta: String) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = id
	motor.segundos_auto_continuar = 0.0
	get_root().add_child(motor)
	await _esperar(1.2)
	await _foto("%s_1_tutorial_hablando" % id)
	var t0 := Time.get_ticks_msec()
	while not _globo_listo(motor) and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	await _esperar(0.4)
	await _foto("%s_2_tutorial_boton_jugar" % id)
	for hijo in motor.get_node("capa_ui/ui").get_children():
		if hijo.get_script() == motor.GloboTutorial:
			hijo.cerrar()
	t0 = Time.get_ticks_msec()
	while not motor._cartas.any(func(c): return c.mostrando) and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	await _esperar(0.5)
	await _foto("%s_3_vistazo_todas" % id)
	motor.queue_free()
	await _esperar(0.2)


func _globo_listo(motor: Node) -> bool:
	for hijo in motor.get_node("capa_ui/ui").get_children():
		if hijo.get_script() == motor.GloboTutorial:
			return hijo._listo
	return false


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var imagen := get_root().get_texture().get_image()
	imagen.save_png("%s/%s.png" % [_carpeta, nombre])
	print("captura: %s" % nombre)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame
