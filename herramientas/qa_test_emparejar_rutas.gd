extends SceneTree

## Arnes QA de la demo jugable del Planeta Arcoiris (motor "emparejar", 13-Sep-2026).
## Recorre la ruta de cada hermano (Maxi/Semilla, Nicole/Brote, Sofia/Estrella) y verifica
## tablero, tamanos tactiles, voces, la logica de memoria (la primera carta NO se tapa sola),
## "no es este", toque que adelanta el tapado, par acertado con su ranura, ayuda de Brote y
## que al completar llegue `completado`.
##
## Uso: godot --headless --path . --script herramientas/qa_test_emparejar_rutas.gd

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const RUTAS := [
	{"perfil": "maxi", "nivel": "res://datos/niveles/arcoiris_emparejar_semilla_01.json", "cartas": 6, "lado_minimo": 96.0},
	{"perfil": "nicole", "nivel": "res://datos/niveles/arcoiris_emparejar_brote_01.json", "cartas": 10, "lado_minimo": 96.0},
	{"perfil": "sofia", "nivel": "res://datos/niveles/arcoiris_emparejar_estrella_01.json", "cartas": 16, "lado_minimo": 64.0},
]

var _fallos := 0


func _initialize() -> void:
	print("=== QA emparejar: rutas por hermano (demo Arcoiris) ===")
	for ruta in RUTAS:
		await _probar_ruta(ruta)
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _probar_ruta(ruta: Dictionary) -> void:
	print("-- ruta %s (%s) --" % [ruta["perfil"], ruta["nivel"].get_file()])
	var motor: Node = load(MOTOR).instantiate()
	if not motor is MinijuegoBase:
		_check(false, "el motor carga su script (revisa errores de parseo arriba)")
		return
	motor.ruta_nivel = ruta["nivel"]
	motor.id_perfil = ruta["perfil"]
	motor.segundos_auto_continuar = 0.5
	var completado := [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	get_root().add_child(motor)
	await _esperar(0.8)

	var cartas: Array = motor._cartas
	var nivel: Dictionary = motor.nivel
	var oculto: bool = nivel.get("oculto", false)
	_check(cartas.size() == ruta["cartas"], "tablero con %d cartas (hay %d)" % [ruta["cartas"], cartas.size()])
	_check(motor._ranuras.size() == nivel["pares"].size(), "una ranura de progreso por par")
	_probar_distribucion(motor, cartas, ruta["lado_minimo"])
	_probar_voces(nivel)
	var tapadas_ok := true
	for carta in cartas:
		tapadas_ok = tapadas_ok and carta.mostrando == (not oculto)
	_check(tapadas_ok, "cartas empiezan %s" % ("tapadas (memoria)" if oculto else "a la vista"))

	var por_pareja := {}
	for carta in cartas:
		if not por_pareja.has(carta.id_pareja):
			por_pareja[carta.id_pareja] = []
		por_pareja[carta.id_pareja].append(carta)
	var claves: Array = por_pareja.keys()
	var x: Array = por_pareja[claves[0]]
	var y: Array = por_pareja[claves[1]]
	var z: Array = por_pareja[claves[2]]

	# 1) La primera carta queda a la vista (antes se re-tapaba sola a los 850 ms).
	x[0].tocada.emit(x[0])
	await _esperar(2.2)
	_check(x[0].mostrando and motor._seleccionadas.size() == 1, "la primera carta sigue a la vista tras 2 s")
	if oculto:
		x[0].tocada.emit(x[0])
		await _esperar(0.1)
		_check(x[0].mostrando and motor._seleccionadas.size() == 1, "doble toque en memoria no re-tapa la carta")

	# 2) "No es este": ambas a la vista un rato y luego vuelven a su estado.
	y[0].tocada.emit(y[0])
	await _esperar(0.1)
	_check(motor._procesando and y[0].mostrando, "no es este: las dos quedan a la vista")
	var espera: float = nivel.get("tiempo_volteo_ms", 700) / 1000.0 if oculto else motor.SEGUNDOS_NO_ES_ESTE_VISIBLE
	await _esperar(espera + 0.3)
	_check(not motor._procesando and x[0].mostrando == (not oculto) and y[0].mostrando == (not oculto), "tras %.1f s se tapan solas" % espera)

	# 3) Tocar otra carta durante el "no es este" las tapa al tiro y selecciona la nueva.
	x[0].tocada.emit(x[0])
	y[0].tocada.emit(y[0])
	await _esperar(0.05)
	z[0].tocada.emit(z[0])
	await _esperar(0.05)
	_check(not motor._procesando and motor._seleccionadas == [z[0]], "toque durante 'no es este' adelanta el tapado y selecciona la nueva")
	_check(x[0].mostrando == (not oculto), "la carta del fallo anterior quedo como estaba")

	# 4) Par acertado: quedan resueltas y su figura llega a la primera ranura.
	z[1].tocada.emit(z[1])
	await _esperar(1.2)
	_check(z[0].esta_acertada and z[1].esta_acertada, "par acertado queda resuelto")
	_check(motor._ranuras[0].figura == z[0].figura, "la figura del par voló a su ranura (%s)" % motor._ranuras[0].figura)

	# 5) Brote: tras 3 fallos seguidos, Coco destapa un par un momento.
	if int(nivel.get("ayuda_tras_fallos", 0) if nivel.get("ayuda_tras_fallos") != null else 0) > 0:
		for i in 3:
			x[0].tocada.emit(x[0])
			y[0].tocada.emit(y[0])
			await _esperar(0.05)
			motor._terminar_no_es_este()
			await _esperar(0.05)
		var en_ayuda := 0
		for carta in cartas:
			if carta._estado == "ayuda" and carta.mostrando:
				en_ayuda += 1
		_check(en_ayuda == 2, "ayuda de Brote destapa un par (%d cartas)" % en_ayuda)
		await _esperar(motor.SEGUNDOS_AYUDA + 0.4)

	# 6) Especial: si el nivel lo tiene, su carta existe.
	var especiales := 0
	for carta in cartas:
		if carta.especial:
			especiales += 1
	if ruta["perfil"] != "maxi":
		_check(especiales == 2, "hay un par especial (momento memorable)")

	# 7) Completar todo emite completado.
	for clave in claves:
		var par: Array = por_pareja[clave]
		if par[0].esta_acertada:
			continue
		par[0].tocada.emit(par[0])
		par[1].tocada.emit(par[1])
		await _esperar(0.08)
	# La celebracion espera a que termine la voz de victoria antes de continuar sola (R6).
	var t0 := Time.get_ticks_msec()
	while completado[0] < 0 and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	_check(completado[0] > 0, "completado(destellos=%d) al terminar" % completado[0])
	motor.queue_free()
	await _esperar(0.1)


func _probar_distribucion(motor: Node, cartas: Array, lado_minimo: float) -> void:
	var pantalla := Rect2(0, 0, 1280, 720)
	var bloqueos := [
		motor.get_node("capa_ui/ui/boton_salir").get_global_rect(),
		motor.get_node("capa_ui/ui/boton_cometa").get_global_rect(),
		motor.get_node("%anfitriona").get_global_rect(),
		motor.get_node("%barra_progreso").get_global_rect(),
	]
	var dentro := true
	var sin_choques := true
	for i in cartas.size():
		var rect: Rect2 = cartas[i].get_global_rect()
		dentro = dentro and pantalla.encloses(rect)
		for bloqueo in bloqueos:
			sin_choques = sin_choques and not rect.intersects(bloqueo)
		for j in range(i + 1, cartas.size()):
			sin_choques = sin_choques and not rect.intersects(cartas[j].get_global_rect())
	_check(cartas[0].size.x >= lado_minimo, "cartas de %.0f px (minimo %.0f, GDD §6.1)" % [cartas[0].size.x, lado_minimo])
	_check(dentro, "todas las cartas dentro de la pantalla")
	_check(sin_choques, "cartas sin tocarse entre si ni con botones, Coco o la barra")


func _probar_voces(nivel: Dictionary) -> void:
	var faltan: Array = []
	for clave in nivel.get("lineas_voz", {}):
		var valor = nivel["lineas_voz"][clave]
		for ruta in (valor if valor is Array else [valor]):
			if not ResourceLoader.exists("res://assets/audio/" + str(ruta)):
				faltan.append(ruta)
	_check(faltan.is_empty(), "todas las voces del nivel existen %s" % ("" if faltan.is_empty() else str(faltan)))
