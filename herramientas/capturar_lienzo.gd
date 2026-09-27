extends SceneTree

## Pantallazos de "Pinta con Coco" (motor lienzo_libre) en ventana real (no headless), para revisar
## la reconocibilidad de las laminas y la interfaz por perfil (PO / experto-ux-parvulo).
## Por cada nivel y hoja captura la pantalla recien abierta y la lamina terminada (regiones con su
## color sugerido, mosaico completo o unos trazos de muestra). Ademas captura TODO el pool de
## laminas de colorear y de mosaicos, no solo las que salen barajadas.
## Los dibujos que se guardan van a user://qa_dibujos y se borran al final.
##
## Uso: godot --path . --script herramientas/capturar_lienzo.gd -- <carpeta_salida> [filtro]

const MOTOR := "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn"
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}

var _carpeta := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_lienzo"
	var filtro := args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(_carpeta)
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/pinta_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			await _nivel(ruta, zona, perfil)
	if filtro == "" or filtro == "pool":
		await _pool("res://datos/niveles/arcoiris/zona2_charcos/pinta_brote.json", "nicole", "pool_zonas")
		await _pool("res://datos/niveles/arcoiris/zona2_charcos/pinta_estrella.json", "sofia", "pool_mosaico")
	quit(0)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := _carpeta.path_join(nombre + ".png")
	get_root().get_texture().get_image().save_png(ruta)
	print("captura: %s" % ruta)


func _abrir(ruta: String, hermano: String) -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = hermano
	motor.segundos_auto_continuar = 0.0
	motor.carpeta_dibujos = "user://qa_dibujos"
	get_root().add_child(motor)
	await _esperar(0.8)
	return motor


func _nivel(ruta: String, zona: String, perfil: String) -> void:
	var motor := await _abrir(ruta, HERMANOS[perfil])
	var base := "%s_%s" % [zona.substr(0, 5), perfil]
	for h in motor._hojas.size():
		while motor._indice_hoja != h:
			await process_frame
		await _esperar(0.7)
		await _capturar("%s_h%d_inicio" % [base, h + 1])
		_terminar_hoja(motor)
		await _esperar(0.5)
		await _capturar("%s_h%d_final" % [base, h + 1])
		if h + 1 < motor._hojas.size():
			motor.mostrar_a_coco()
	motor.queue_free()
	await _esperar(0.2)


## Muestra cada lamina del pool de un nivel terminada (para revisar todas, no solo las barajadas).
func _pool(ruta: String, hermano: String, prefijo: String) -> void:
	var motor := await _abrir(ruta, hermano)
	var pool: Array = motor.nivel.get("laminas", [])
	for lamina: Dictionary in pool:
		motor._hojas[0]["lamina"] = lamina
		motor._empezar_hoja(0)
		await _esperar(0.3)
		_terminar_hoja(motor)
		await _esperar(0.3)
		await _capturar("%s_%s" % [prefijo, lamina.get("id", "?")])
	motor.queue_free()
	await _esperar(0.2)


func _terminar_hoja(motor) -> void:
	var lienzo = motor.lienzo
	if not lienzo.mosaico.is_empty():
		var filas: Array = lienzo.mosaico["celdas"]
		for y in filas.size():
			for x in str(filas[y]).length():
				lienzo.color_actual = lienzo.color_esperado(Vector2i(x, y))
				lienzo._pintar_celda(lienzo.centro_celda(Vector2i(x, y)))
				lienzo._ultima_celda = Vector2i(-1, -1)
		return
	var regiones: Array = lienzo.lamina.get("regiones", [])
	var pinto := false
	for i in regiones.size():
		var region: Dictionary = regiones[i]
		if not bool(region.get("fija", false)) and region.has("sugerido"):
			lienzo.pintar_region(i, Color(str(region["sugerido"])))
			pinto = true
	if pinto:
		return
	# Papel en blanco, guia o escena fija: unos trazos (y sellos) de muestra con la herramienta activa.
	var colores := [Color("#EE4035"), Color("#FFD23F"), Color("#3470D8"), Color("#FF7EB6"), Color("#4CBF56")]
	for k in 5:
		lienzo.color_actual = colores[k]
		var y := 110.0 + k * 70.0
		lienzo.empezar_trazo(Vector2(120 + k * 30, y))
		for i in range(1, 16):
			lienzo.continuar_trazo(Vector2(120 + k * 30 + i * 28, y + sin(i * 0.6) * 30.0))
		lienzo.terminar_trazo()
