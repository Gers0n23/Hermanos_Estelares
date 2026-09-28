extends SceneTree

## Captura el "Taller de pinturas de Coco" (motor mezclar) en sus momentos clave: receta a
## memorizar, atrapando gotas, gag de "puaj", agitando, latas en el pedido y mural pintado.
## Necesita ventana (no headless). Guarda PNG a tamano real en la carpeta indicada.
##
## Uso: godot --path . --script herramientas/capturar_mezclar.gd -- salida=<carpeta> [zona=zona2_charcos]

const MOTOR := "res://escenas/minijuegos/mezclar/motor_mezclar.tscn"

var _salida := ""


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=", true, 1)
		if partes.size() == 2:
			args[partes[0]] = partes[1]
	_salida = str(args.get("salida", OS.get_user_data_dir()))
	var zona := str(args.get("zona", "zona2_charcos"))
	var motor = (load(MOTOR) as PackedScene).instantiate()
	motor.ruta_nivel = "res://datos/niveles/arcoiris/%s/mezcla_estrella.json" % zona
	motor.id_perfil = "sofia"
	root.add_child(motor)
	await _hasta(motor, "receta", 20.0)
	await _esperar(0.8)
	await _capturar("1_receta")
	motor.confirmar_receta()
	await _hasta(motor, "atrapar", 5.0)
	var faltan: Dictionary = motor.faltantes()
	motor.atrapar_color(str(faltan.keys()[0]))
	await _esperar(2.2)
	await _capturar("2_atrapando")
	var malo := "gris"
	for pigmento in ["rojo", "amarillo", "azul"]:
		if not motor.faltantes().has(pigmento):
			malo = pigmento
			break
	motor.atrapar_color(malo)
	await _esperar(0.6)
	await _capturar("3_puaj")
	await _hasta(motor, "atrapar", 12.0)
	for i in 6:
		var f: Dictionary = motor.faltantes()
		if f.is_empty():
			break
		motor.atrapar_color(str(f.keys()[0]))
	await _esperar(0.5)
	motor.agitar(0.45)
	await _esperar(0.2)
	await _capturar("4_agitar")
	motor.agitar(0.6)
	await _hasta(motor, "receta", 12.0)
	motor.confirmar_receta()
	await _esperar(0.5)
	await _capturar("5_una_lata")
	for k in 2:
		await _hasta(motor, "atrapar", 12.0)
		for i in 6:
			var f: Dictionary = motor.faltantes()
			if f.is_empty():
				break
			motor.atrapar_color(str(f.keys()[0]))
		motor.agitar(1.0)
		if k == 0:
			await _hasta(motor, "receta", 12.0)
			motor.confirmar_receta()
	await _hasta(motor, "mural", 12.0)
	await _esperar(5.0)
	await _capturar("6_mural")
	quit()


func _hasta(motor, fase: String, maximo: float) -> void:
	var t := 0.0
	while motor.fase() != fase and t < maximo:
		await _esperar(0.1)
		t += 0.1


func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout


func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := _salida.path_join("mezclar_%s.png" % nombre)
	root.get_texture().get_image().save_png(ruta)
	print("captura -> %s" % ruta)
