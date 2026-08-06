extends SceneTree

## Arnes de QA ad hoc para la pantalla de titulo (HE-05, `herramientas/` esta gdignored,
## mismo patron que `qa_test_emparejar.gd`). Corre headless, instancia la escena real,
## simula un toque/clic y confirma que la senal publica `toque_para_empezar` se dispara
## sin errores ni tironeos entre el tween de pulso y el de destello.
##
## Uso: godot --headless --path . --script herramientas/qa_test_titulo.gd

var _titulo: Node


func _initialize() -> void:
	print("=== QA titulo: instanciando escena real ===")
	# Carga diferida (no preload al parsear este script): evita una carrera de arranque
	# en modo --script donde los autoloads (Audio) todavia no estan resueltos como
	# identificador global si el .tscn/.gd se compila demasiado temprano.
	var escena_titulo: PackedScene = load("res://escenas/nucleo/titulo.tscn")
	_titulo = escena_titulo.instantiate()
	get_root().add_child(_titulo)

	var senal_recibida := [false]
	_titulo.toque_para_empezar.connect(func() -> void:
		senal_recibida[0] = true
		print("SENAL toque_para_empezar() recibida")
	)

	# add_child difiere _ready(): esperamos unos frames para que arranquen el pulso y el
	# temporizador de recordatorio antes de simular el toque.
	for i in range(10):
		await process_frame

	print("-- Simulando un toque en pantalla (InputEventScreenTouch) --")
	var evento_toque := InputEventScreenTouch.new()
	evento_toque.pressed = true
	evento_toque.position = Vector2(640.0, 480.0)
	_titulo._unhandled_input(evento_toque)
	await process_frame

	print("-- Simulando un clic de mouse (InputEventMouseButton), como en PC --")
	var evento_clic := InputEventMouseButton.new()
	evento_clic.pressed = true
	evento_clic.button_index = MOUSE_BUTTON_LEFT
	evento_clic.position = Vector2(300.0, 200.0)
	_titulo._unhandled_input(evento_clic)
	await process_frame

	# Deja correr varios frames mas para que los tweens (pulso, destello, chispas) hagan
	# su ciclo completo sin quedar en un estado invalido ni disparar errores.
	for i in range(30):
		await process_frame

	print("senal_recibida (esperado true, disparada al menos una vez) = %s" % senal_recibida[0])
	print("=== FIN qa_test_titulo (%s) ===" % ("OK" if senal_recibida[0] else "FALLO"))
	quit(0 if senal_recibida[0] else 1)
