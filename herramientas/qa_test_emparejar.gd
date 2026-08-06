extends SceneTree

## Arnes de QA ad hoc para el piloto del motor "emparejar" (ejercicio de humo del flujo
## de agentes, no contenido final). Corre headless, instancia la escena del motor con el
## nivel piloto, simula toques como lo haria un nino y deja constancia en consola de cada
## paso + del valor final de completado(destellos).
##
## Nota 18-Jul-2026 (correccion de bloqueantes B1-B4 + M-QA1): `CartaEmparejar` dejo de
## extender `Button` (ver B1), por lo que ya no expone la senal `pressed`. `_tocar()` ahora
## dispara la senal publica `tocada(self)` directamente (el camino final que el motor
## escucha tras press+release dentro de tolerancia). Se agregaron los modos
## "b1_tolerancia", "b2_feedback", "b3_estelita", "b4_salir" y "puntaje_no_explotable" para
## verificar especificamente cada correccion.
##
## Uso: godot --headless --path . --script herramientas/qa_test_emparejar.gd -- <modo>
## modo: "sofia_normal" | "maxi_random" | "machaque" | "derrota_forzada" | "salir_reentrar"
##       | "b1_tolerancia" | "b2_feedback" | "b3_estelita" | "b4_salir" | "puntaje_no_explotable"

const MOTOR_ESCENA := preload("res://escenas/minijuegos/emparejar/motor_emparejar.tscn")

var _motor: Node
var _modo := "sofia_normal"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_modo = args[0]
	print("=== QA emparejar: modo=%s ===" % _modo)
	await _montar_motor()
	match _modo:
		"sofia_normal":
			await _correr_sofia_normal()
		"maxi_random":
			await _correr_maxi_random()
		"machaque":
			await _correr_machaque()
		"derrota_forzada":
			await _correr_derrota_forzada()
		"salir_reentrar":
			await _correr_salir_reentrar()
		"b1_tolerancia":
			await _correr_b1_tolerancia()
		"b2_feedback":
			await _correr_b2_feedback()
		"b3_estelita":
			await _correr_b3_estelita()
		"b4_salir":
			await _correr_b4_salir()
		"puntaje_no_explotable":
			await _correr_puntaje_no_explotable()
		_:
			print("MODO DESCONOCIDO: %s" % _modo)
			quit(1)


func _montar_motor() -> void:
	_motor = MOTOR_ESCENA.instantiate()
	get_root().add_child(_motor)
	_motor.completado.connect(func(destellos: int) -> void:
		print("SENAL completado(destellos=%d) recibida" % destellos)
	)
	_motor.par_acertado.connect(func(id: String) -> void:
		print("SENAL par_acertado(%s)" % id)
	)
	_motor.nivel_fallado.connect(func() -> void:
		print("SENAL nivel_fallado()")
	)
	_motor.salir_solicitado.connect(func() -> void:
		print("SENAL salir_solicitado() recibida")
	)
	# add_child no garantiza que _ready() ya corrio (se defiere al proximo idle frame);
	# esperamos varios frames para asegurar que _construir_tablero() ya poblo el tablero.
	for i in range(5):
		await process_frame
	print("Motor montado. Nodo tablero tiene %d hijos." % _cartas().size())


func _cartas() -> Array:
	# Recorre el GridContainer del tablero (unique name %tablero dentro de ui/centro).
	var tablero := _motor.get_node("ui/centro/tablero")
	return tablero.get_children()


## Simula un toque "limpio" disparando directamente la senal publica que el motor escucha
## (equivalente al resultado de un press+release valido dentro de tolerancia, ver B1).
func _tocar(carta: Node) -> void:
	if carta == null or not is_instance_valid(carta):
		print("  (toque sobre carta invalida, ignorado)")
		return
	carta.tocada.emit(carta)


func _esperar(seg: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < seg * 1000:
		await process_frame


## --- Sofia (8): ritmo normal a rapido, resuelve pares correctamente cuando puede,
## incluye toques durante la ventana "no es este" para probar B2, y busca el par secreto.
func _correr_sofia_normal() -> void:
	var cartas: Array = _cartas()
	print("Total cartas en tablero: %d" % cartas.size())
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	# Construye mapa id_pareja -> [cartas] usando propiedades publicas del script.
	var por_pareja := {}
	for c in cartas:
		var idp: String = c.id_pareja
		if not por_pareja.has(idp):
			por_pareja[idp] = []
		por_pareja[idp].append(c)

	# 1) Toca dos cartas de distinta pareja para forzar un "no es este", y durante la
	#    ventana de 500ms de resolucion, intenta tocar una tercera carta (verifica B2).
	var claves: Array = por_pareja.keys()
	var pareja_x: Array = por_pareja[claves[0]]
	var pareja_y: Array = por_pareja[claves[1]]
	print("-- Forzando 'no es este' entre %s y %s --" % [claves[0], claves[1]])
	_tocar(pareja_x[0])
	await _esperar(0.05)
	_tocar(pareja_y[0])
	await _esperar(0.05)
	print("Tocando una TERCERA carta durante la ventana de 500ms de 'no es este' (esperado: pulso de espera, B2)...")
	_tocar(pareja_x[1] if pareja_x.size() > 1 else pareja_y[1])
	await _esperar(0.6)

	# 2) Ahora completa todos los pares en orden correcto (ritmo rapido, sin pausas largas).
	print("-- Completando todos los pares en orden correcto --")
	for idp in por_pareja.keys():
		var par: Array = por_pareja[idp]
		if par[0].esta_acertada:
			continue
		_tocar(par[0])
		await _esperar(0.05)
		_tocar(par[1])
		await _esperar(0.55)  # esperar resolucion (incluye la ventana no_es_este si aplica)

	await _esperar(1.5)
	print("=== FIN sofia_normal ===")
	quit(0)


## --- Maxi (2): toques al azar, incluye tocar la misma carta muchas veces seguidas y
## quedarse quieto un rato entre toques. No hay concepto de perder para su perfil, pero
## el motor se corre igual con el nivel de Sofia para estresar la robustez del codigo
## ante entradas caoticas (no representa el nivel real de Maxi, que no existe aun).
func _correr_maxi_random() -> void:
	var cartas: Array = _cartas()
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	randomize()
	print("-- Maxi: 40 toques al azar, incluye repeticiones sobre la misma carta --")
	var ultima: Node = null
	for i in range(40):
		var carta: Node = cartas[randi() % cartas.size()]
		if i % 5 == 0 and ultima != null:
			carta = ultima  # machaca la misma carta varias veces seguidas
		_tocar(carta)
		ultima = carta
		await _esperar(0.02)  # dedos rapidos e imprecisos, casi sin pausa
	print("-- Maxi: pausa larga (se queda quieto) --")
	await _esperar(2.0)
	_tocar(cartas[0])
	await _esperar(1.0)
	print("=== FIN maxi_random (sin crash = OK) ===")
	quit(0)


## --- Caso cruel: toque repetido/machacado sobre el mismo boton (doble-toque rapido). ---
func _correr_machaque() -> void:
	var cartas: Array = _cartas()
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	var carta: Node = cartas[0]
	print("-- Machacando 20 veces la misma carta en rafaga --")
	for i in range(20):
		_tocar(carta)
		await _esperar(0.01)
	await _esperar(0.5)
	print("-- Ahora selecciono un segundo elemento de otra pareja y machaco tambien --")
	var otra: Node = cartas[1]
	for i in range(10):
		_tocar(otra)
		await _esperar(0.01)
	await _esperar(1.0)
	print("=== FIN machaque (sin crash = OK) ===")
	quit(0)


## --- Fuerza agotar limite_intentos (16) fallando pares a proposito, valida derrota-gag,
## boton "otra vez" de un toque, y que los pares ya acertados no se pierdan al reintentar. ---
func _correr_derrota_forzada() -> void:
	var cartas: Array = _cartas()
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	var por_pareja := {}
	for c in cartas:
		var idp: String = c.id_pareja
		if not por_pareja.has(idp):
			por_pareja[idp] = []
		por_pareja[idp].append(c)
	var claves: Array = por_pareja.keys()

	# Acierta 1 par primero, para poder verificar que sobrevive al reintento.
	var primero: Array = por_pareja[claves[0]]
	print("-- Acertando 1 par antes de forzar la derrota: %s --" % claves[0])
	_tocar(primero[0])
	await _esperar(0.05)
	_tocar(primero[1])
	await _esperar(0.6)

	# Falla 16 veces a proposito emparejando cartas de parejas distintas restantes.
	print("-- Fallando pares a proposito hasta agotar limite_intentos=16 --")
	var restantes: Array = []
	for k in claves:
		if k != claves[0]:
			restantes.append(por_pareja[k])
	var intentos := 0
	var idx := 0
	while intentos < 17:
		var par_a: Array = restantes[idx % restantes.size()]
		var par_b: Array = restantes[(idx + 1) % restantes.size()]
		if par_a == par_b:
			idx += 1
			continue
		_tocar(par_a[0])
		await _esperar(0.05)
		_tocar(par_b[0])
		await _esperar(0.6)
		intentos += 1
		idx += 1
		print("  intento fallido #%d" % intentos)
		if intentos >= 16:
			break

	await _esperar(0.5)
	print("-- Verificando boton_otra_vez visible y reintentando con UN toque --")
	var boton := _motor.get_node("ui/boton_otra_vez")
	print("boton_otra_vez.visible = %s" % boton.visible)
	print("Carta ya acertada sigue esta_acertada=true? %s" % primero[0].esta_acertada)
	boton.pressed.emit()
	await _esperar(0.3)
	print("Tras reintentar: carta acertada sigue esta_acertada=true? %s (debe seguir true, cero progreso perdido)" % primero[0].esta_acertada)
	print("boton_otra_vez.visible tras reintentar = %s (debe ser false)" % boton.visible)

	# Ahora completa el resto correctamente para llegar a completado() y ver destellos.
	print("-- Completando el resto de pares correctamente tras el reintento --")
	for idp in por_pareja.keys():
		var par: Array = por_pareja[idp]
		if par[0].esta_acertada:
			continue
		_tocar(par[0])
		await _esperar(0.05)
		_tocar(par[1])
		await _esperar(0.6)
	await _esperar(1.5)
	print("=== FIN derrota_forzada (destellos esperados <= 110, ver M-QA1) ===")
	quit(0)


## --- Existe forma de salir a mitad de partida? Busca cualquier nodo/boton de salida. ---
func _correr_salir_reentrar() -> void:
	print("-- Buscando algun control de salida/volver en el arbol de la escena --")
	_buscar_salida(_motor, 0)
	print("=== FIN salir_reentrar (ver arriba si se encontro algo) ===")
	quit(0)


func _buscar_salida(nodo: Node, profundidad: int) -> void:
	var nombre: String = nodo.name.to_lower()
	if "salir" in nombre or "volver" in nombre or "cerrar" in nombre or "home" in nombre or "casa" in nombre or "estelita" in nombre:
		print("  Posible control de salida/ayuda encontrado: %s (%s)" % [nodo.get_path(), nodo.get_class()])
	for hijo in nodo.get_children():
		_buscar_salida(hijo, profundidad + 1)


## --- B1: verifica que un release desplazado dentro de la tolerancia SI cuenta como
## toque valido, y que uno fuera de tolerancia NO cuenta (sin usar Button.pressed). ---
func _correr_b1_tolerancia() -> void:
	var cartas: Array = _cartas()
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	var carta: Node = cartas[0]
	# Nota GDScript: las lambdas capturan variables locales POR VALOR, no por referencia.
	# Se usa un Array de 1 elemento (objeto, capturado por referencia) como contador mutable.
	var recibidos := [0]
	carta.tocada.connect(func(_c: Node) -> void:
		recibidos[0] += 1
		print("  tocada.emit recibido (total=%d)" % recibidos[0])
	)

	var rect: Rect2 = carta.get_global_rect()
	var origen: Vector2 = rect.position + rect.size / 2.0

	print("-- Caso 1: press en el centro, release desplazado 20px (dentro de tolerancia=56px) --")
	carta._procesar_evento(-1, origen, true)
	carta._procesar_evento(-1, origen + Vector2(20, 0), false)
	await _esperar(0.05)
	print("  recibidos tras caso 1 (esperado 1): %d" % recibidos[0])
	assert(recibidos[0] == 1, "B1: un release dentro de tolerancia debe contar como toque")

	print("-- Caso 2: press en el centro, release desplazado 200px (fuera de tolerancia) --")
	carta._procesar_evento(-1, origen, true)
	carta._procesar_evento(-1, origen + Vector2(200, 0), false)
	await _esperar(0.05)
	print("  recibidos tras caso 2 (esperado sigue 1, no debe sumar): %d" % recibidos[0])
	assert(recibidos[0] == 1, "B1: un release fuera de tolerancia NO debe contar como toque")

	print("=== FIN b1_tolerancia (%s) ===" % ("OK" if recibidos[0] == 1 else "FALLO"))
	quit(0 if recibidos[0] == 1 else 1)


## --- B2: durante _procesando, un toque en otra carta debe reaccionar (pulso), no
## quedar en silencio total. Verificamos que no truene y que la escala cambie. ---
func _correr_b2_feedback() -> void:
	var cartas: Array = _cartas()
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	var por_pareja := {}
	for c in cartas:
		var idp: String = c.id_pareja
		if not por_pareja.has(idp):
			por_pareja[idp] = []
		por_pareja[idp].append(c)
	var claves: Array = por_pareja.keys()
	var pareja_x: Array = por_pareja[claves[0]]
	var pareja_y: Array = por_pareja[claves[1]]
	var tercera: Node = pareja_x[1] if pareja_x.size() > 1 else pareja_y[1]

	print("-- Forzando 'no es este' y tocando una tercera carta durante la ventana --")
	_tocar(pareja_x[0])
	await _esperar(0.02)
	_tocar(pareja_y[0])
	await _esperar(0.02)
	tercera.scale = Vector2.ONE
	_tocar(tercera)
	await _esperar(0.02)
	var escala_tras_toque: Vector2 = tercera.scale
	print("  escala de la tercera carta justo tras el toque durante _procesando: %s (esperado != (1,1), pulso activo)" % escala_tras_toque)
	var ok: bool = escala_tras_toque != Vector2.ONE
	await _esperar(0.6)
	print("=== FIN b2_feedback (%s) ===" % ("OK" if ok else "FALLO"))
	quit(0 if ok else 1)


## --- B3: tocar el boton_estelita debe existir y disparar la reproduccion de `pista`
## (placeholder de consola "[voz TODO:pista] ..."). ---
func _correr_b3_estelita() -> void:
	var boton := _motor.get_node_or_null("ui/boton_estelita")
	if boton == null:
		print("ERROR QA: no existe ui/boton_estelita")
		quit(1)
		return
	print("boton_estelita encontrado, custom_minimum_size=%s (>=96px esperado)" % boton.custom_minimum_size)
	print("-- Tocando a Estelita (deberia imprimir '[voz TODO:pista] ...') --")
	boton.pressed.emit()
	await _esperar(0.05)
	print("=== FIN b3_estelita ===")
	quit(0)


## --- B4: tocar el boton_salir debe emitir la senal salir_solicitado(). ---
func _correr_b4_salir() -> void:
	var boton := _motor.get_node_or_null("ui/boton_salir")
	if boton == null:
		print("ERROR QA: no existe ui/boton_salir")
		quit(1)
		return
	print("boton_salir encontrado, custom_minimum_size=%s (>=64px esperado)" % boton.custom_minimum_size)
	# Array de 1 elemento: capturado por referencia dentro de la lambda (a diferencia de un bool local).
	var recibida := [false]
	_motor.salir_solicitado.connect(func() -> void: recibida[0] = true)
	boton.pressed.emit()
	await _esperar(0.05)
	print("salir_solicitado recibida? %s" % recibida[0])
	print("=== FIN b4_salir (%s) ===" % ("OK" if recibida[0] else "FALLO"))
	quit(0 if recibida[0] else 1)


## --- M-QA1: compara destellos de una partida limpia (sofia_normal-like, 1 fallo) contra
## una partida con derrota forzada + reintento; el segundo NUNCA debe ser mayor. ---
func _correr_puntaje_no_explotable() -> void:
	var cartas: Array = _cartas()
	if cartas.is_empty():
		print("ERROR QA: tablero vacio, abortando modo")
		quit(1)
		return
	var por_pareja := {}
	for c in cartas:
		var idp: String = c.id_pareja
		if not por_pareja.has(idp):
			por_pareja[idp] = []
		por_pareja[idp].append(c)
	var claves: Array = por_pareja.keys()

	# Array de 1 elemento: capturado por referencia dentro de la lambda (a diferencia de un int local).
	var destellos_finales := [-1]
	_motor.completado.connect(func(d: int) -> void:
		destellos_finales[0] = d
	)

	# Acierta 1 par, falla 16 a proposito, reintenta, completa el resto.
	var primero: Array = por_pareja[claves[0]]
	_tocar(primero[0])
	await _esperar(0.05)
	_tocar(primero[1])
	await _esperar(0.6)

	var restantes: Array = []
	for k in claves:
		if k != claves[0]:
			restantes.append(por_pareja[k])
	var intentos := 0
	var idx := 0
	while intentos < 16:
		var par_a: Array = restantes[idx % restantes.size()]
		var par_b: Array = restantes[(idx + 1) % restantes.size()]
		if par_a == par_b:
			idx += 1
			continue
		_tocar(par_a[0])
		await _esperar(0.05)
		_tocar(par_b[0])
		await _esperar(0.6)
		intentos += 1
		idx += 1

	await _esperar(0.5)
	var boton := _motor.get_node("ui/boton_otra_vez")
	boton.pressed.emit()
	await _esperar(0.3)

	for idp in por_pareja.keys():
		var par: Array = por_pareja[idp]
		if par[0].esta_acertada:
			continue
		_tocar(par[0])
		await _esperar(0.05)
		_tocar(par[1])
		await _esperar(0.6)
	await _esperar(1.5)

	var destellos_limpios_esperados: int = por_pareja.size() * 10 + 15 * 2  # 1 solo fallo real
	print("destellos_finales (16 fallos + reintento) = %d" % destellos_finales[0])
	print("destellos de una partida limpia con 1 fallo (referencia, ver sofia_normal) = %d" % destellos_limpios_esperados)
	var ok: bool = destellos_finales[0] <= destellos_limpios_esperados
	print("=== FIN puntaje_no_explotable (%s: %d <= %d) ===" % ["OK" if ok else "FALLO", destellos_finales[0], destellos_limpios_esperados])
	quit(0 if ok else 1)
