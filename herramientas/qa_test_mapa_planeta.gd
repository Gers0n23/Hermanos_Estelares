extends SceneTree

## Arnes QA: entrar a un planeta jugable desde el mapa estelar y volver (stub previo a HE-09).
## Simula el toque sobre el disco de Arcoiris, verifica que el motor recibe el contrato
## (nivel, planeta, hermano) y que "salir" y "completado" regresan al mapa.
##
## Uso: godot --headless --path . --script herramientas/qa_test_mapa_planeta.gd

const MAPA := "res://escenas/nucleo/mapa_estelar.tscn"

var _fallos := 0


func _initialize() -> void:
	print("=== QA mapa estelar -> planeta jugable ===")
	var progreso := get_root().get_node_or_null("Progreso")
	if progreso != null:
		progreso.perfil_seleccionado = "sofia"
	await _probar_ida_y_vuelta("salir")
	await _probar_ida_y_vuelta("completado")
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar_frames(n: int) -> void:
	for i in n:
		await process_frame


func _probar_ida_y_vuelta(forma_de_volver: String) -> void:
	print("-- entrar a Arcoiris y volver por '%s' --" % forma_de_volver)
	change_scene_to_file(MAPA)
	await _esperar_frames(3)
	var mapa := current_scene
	_check(mapa != null and mapa.scene_file_path == MAPA, "mapa estelar cargado")

	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = Vector2(300, 545)  # centro del disco de Arcoiris
	# Directo al handler (como qa_test_titulo): en headless la ventana mide casi nada y
	# push_input re-escala las coordenadas del toque fuera de la pantalla de 1280x720.
	mapa._input(toque)
	await _esperar_frames(3)

	var motor := current_scene
	_check(motor is MinijuegoBase, "tocar Arcoiris abre un motor de minijuego (%s)" % str(motor))
	if not motor is MinijuegoBase:
		return
	_check(motor.planeta_id == "arcoiris", "motor recibe planeta_id=arcoiris")
	_check(motor.id_perfil == "sofia", "motor recibe al hermano seleccionado (sofia)")
	_check(not motor.nivel.is_empty(), "motor cargo su nivel")
	_check(not is_instance_valid(mapa), "el mapa se libero")

	if forma_de_volver == "salir":
		motor.salir_solicitado.emit()
	else:
		motor.completado.emit(10)
	await _esperar_frames(4)
	_check(current_scene != null and current_scene.scene_file_path == MAPA, "vuelve al mapa tras '%s'" % forma_de_volver)
