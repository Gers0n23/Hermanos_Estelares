extends SceneTree

## Arnes QA de "Formas traviesas" (motor encajar): juega las 15 variantes (5 zonas x 3 rutas).
## "Arma la figura" (PO 27-Sep-2026): verifica ademas que la bandeja muestre las piezas a su tamano
## real (`bandeja_escala_real`), que la cola las reponga al encajar y que toda pieza ofrecida tenga
## un lugar libre donde calza. El reto dorado de Sofia (marco) sigue en qa_test_retos_sofia.gd.
## Por nivel verifica armado (piezas, huecos dentro de su zona, bandeja sin choques, tamanos
## tactiles), voces existentes, que todo hueco tenga su pieza, las reglas del perfil (Semilla sin
## "no", toque que lleva a casa; Brote con objetivo guiado y enderezado; Estrella con giro por toque
## y distractoras), la derrota-gag con reintento y que al completar llegue `completado(destellos)`.
##
## Rondas (PO 27-Sep-2026): cada nivel es una serie de rondas sorteadas de un pool. Por nivel se juega
## (1) la PARTIDA COMPLETA, ronda a ronda: cuantas rondas, figura fija primero, grupos de Sofia, curva
## de dificultad, medallas, mini-fiesta entre rondas, avance guardado y RETOMADO a mitad de la serie, y
## `completado` solo al final; y (2) CADA FIGURA DEL POOL por separado (nivel temporal de una ronda) con
## todas las verificaciones de arriba. Las banderas piden cada franja en su color (`exigir_color`).
## Respalda y restaura `user://progreso.json`.
##
## Uso: godot --headless --path . --script herramientas/qa_test_encajar.gd [-- <filtro> [<filtro figura>]]

const MOTOR := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
## Lado visual mas corto de una pieza en la bandeja. La zona tocable siempre es >= 96 px de
## diametro (PiezaEncajar.RADIO_TOQUE_MINIMO), aunque la forma sea delgada (tronco, cuello).
## Estrella: las figuras de 20+ piezas de Sofia tienen piezas delgadas a proposito (columnas, pilotes,
## almenas); herramientas/figuras_formas.py usa estos mismos minimos al disenarlas.
const LADO_MINIMO := {"semilla": 96.0, "brote": 52.0, "estrella": 22.0}

const PLANETA_QA := "qa_encajar"
const CARPETA_TEMPORAL := "user://qa_encajar"
const GUARDADO := "user://progreso.json"
const RONDAS_ESPERADAS := {"semilla": 4, "brote": 3, "estrella": 2}

var _fallos := 0
var _figuras_probadas := 0


func _initialize() -> void:
	print("=== QA encajar: Formas traviesas, 5 zonas x rutas de Maxi, Nicole y Sofia, con rondas ===")
	var args := OS.get_cmdline_user_args()
	var filtro: String = args[0] if args.size() > 0 else ""
	var filtro_figura: String = args[1] if args.size() > 1 else ""
	var respaldo = FileAccess.get_file_as_string(GUARDADO) if FileAccess.file_exists(GUARDADO) else null
	DirAccess.make_dir_recursive_absolute(CARPETA_TEMPORAL)
	if filtro == "" and filtro_figura == "":
		_probar_sin_bichos()
		await _probar_umbrales_y_regalo()
		await _probar_guardado_pieza_a_pieza()
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/formas_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
			if filtro_figura == "":
				await _probar_rondas(ruta, nivel, HERMANOS[perfil])
			for figura: Dictionary in nivel.get("figuras", []):
				if filtro_figura != "" and not str(figura["id"]).contains(filtro_figura):
					continue
				var solo := nivel.duplicate(true)
				solo["figuras"] = [figura]
				solo["rondas"] = 1
				var temporal := CARPETA_TEMPORAL.path_join("%s_%s_%s.json" % [zona, perfil, figura["id"]])
				var archivo := FileAccess.open(temporal, FileAccess.WRITE)
				archivo.store_string(JSON.stringify(solo))
				archivo.close()
				await _probar_nivel(temporal, HERMANOS[perfil], "%s/%s -> %s" % [zona, perfil, figura["id"]])
				_figuras_probadas += 1
	if respaldo != null:
		var archivo := FileAccess.open(GUARDADO, FileAccess.WRITE)
		archivo.store_string(respaldo)
		archivo.close()
	print("=== %d figuras del pool probadas una por una ===" % _figuras_probadas)
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _nuevo_motor(ruta: String, hermano: String, con_progreso: bool) -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = hermano
	motor.segundos_auto_continuar = 0.4
	if con_progreso:
		motor.planeta_id = PLANETA_QA
	get_root().add_child(motor)
	return motor


## Encaja todas las piezas de la ronda en curso, como lo haria un nino (con giros si el nivel deja).
func _completar_ronda(motor: Node) -> bool:
	var avanzo := true
	var todo_encajo := true
	while avanzo and motor._encajados < motor._requeridos and not motor._terminado:
		avanzo = false
		for pieza: PiezaEncajar in motor._piezas.duplicate():
			if not is_instance_valid(pieza) or pieza.colocada or motor._encajados >= motor._requeridos:
				continue
			var hueco = _hueco_libre_para(motor, pieza)
			if hueco == null:
				continue
			if motor._rotacion_por_toque:
				for k in 8:
					if Geo.calzan(pieza.poligono(), hueco["forma_centrada"]):
						break
					pieza.tocada.emit(pieza)
			var r: String = motor.soltar_pieza(pieza, hueco["centro"])
			if r != "encajo":
				todo_encajo = false
				print("        %s en %s -> %s" % [pieza.id, hueco["id"], r])
				continue
			avanzo = true
			await _esperar(0.02)
	return todo_encajo and motor._encajados >= motor._requeridos


func _esperar_ronda(motor: Node, indice: int, resultado: Dictionary) -> bool:
	var t0 := Time.get_ticks_msec()
	while motor._indice_prueba < indice and resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	await _esperar(0.3)
	return motor._indice_prueba >= indice


## Partida completa del nivel real: todas sus rondas, la mini-fiesta entre ellas, el avance guardado y
## retomado a mitad de la serie, y `completado` solo al final.
func _probar_rondas(ruta: String, nivel: Dictionary, hermano: String) -> void:
	print("-- %s (%s) PARTIDA CON RONDAS --" % [ruta.trim_prefix("res://datos/niveles/arcoiris/"), hermano])
	var perfil: String = nivel.get("perfil", "")
	var progreso := get_root().get_node("Progreso")
	var id_nivel := str(nivel.get("id_nivel", ""))
	progreso.borrar_estado_parcial(hermano, PLANETA_QA, id_nivel)
	var pedido = nivel.get("rondas", null)
	_check(pedido != null, "el nivel declara rondas (%s)" % str(pedido))
	if pedido == null:
		return
	var esperadas: int = pedido.size() if pedido is Array else int(pedido)
	_check(esperadas == RONDAS_ESPERADAS[perfil], "%d rondas por estacion para %s" % [esperadas, hermano])
	var pool: Array = nivel["figuras"]
	_check(pool.size() > esperadas, "pool de %d figuras (mas que las rondas: rejugar cambia)" % pool.size())
	var motor := _nuevo_motor(ruta, hermano, true)
	var resultado := {"destellos": -1}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	await _esperar(0.9)
	var ids: Array = motor._rondas.map(func(r: Dictionary) -> String: return r["id"])
	_check(motor._modo_rondas and ids.size() == esperadas, "partida de %d rondas: %s" % [ids.size(), ", ".join(ids)])
	var unicos := {}
	for id in ids:
		unicos[id] = true
	_check(unicos.size() == ids.size(), "sin figuras repetidas en la partida")
	var por_id := {}
	for figura: Dictionary in pool:
		por_id[figura["id"]] = figura
	var fija := pool.filter(func(f: Dictionary) -> bool: return bool(f.get("fija", false)))
	if not fija.is_empty() and not (pedido is Array):
		_check(ids[0] == fija[0]["id"], "la figura fija (%s) va primera" % fija[0]["id"])
	if pedido is Array:
		var grupos_ok := true
		for i in ids.size():
			grupos_ok = grupos_ok and str(por_id[ids[i]].get("grupo", "")) == str(pedido[i])
		_check(grupos_ok, "una ronda por grupo, en orden: %s" % str(pedido))
	else:
		var curva_ok := true
		var desde: int = 1 if not fija.is_empty() else 0
		for i in range(desde + 1, ids.size()):
			curva_ok = curva_ok and int(por_id[ids[i]]["dificultad"]) >= int(por_id[ids[i - 1]]["dificultad"])
		_check(curva_ok, "las rondas suben suave (dificultad no baja)")
	_check(motor._medallas != null and motor._medallas.visible, "medallas de rondas visibles (sin numeros)")

	# Ronda 1 y el avance guardado.
	var ok: bool = await _completar_ronda(motor)
	_check(ok, "ronda 1 (%s) completa" % ids[0])
	_check(await _esperar_ronda(motor, 1, resultado), "tras la mini-fiesta entra la ronda 2 (%s)" % ids[1])
	_check(resultado["destellos"] < 0, "completado NO llega entre rondas")
	var estado: Dictionary = progreso.obtener_estado_parcial(hermano, PLANETA_QA, id_nivel)
	_check(int(estado.get("indice", -1)) == 1 and estado.get("rondas", []) == ids, "avance guardado en la ronda 2 con las mismas figuras")
	var destellos_ronda_1: int = motor._destellos_pruebas
	motor.queue_free()
	await _esperar(0.3)

	# El nino vuelve: retoma en la ronda 2, con las mismas figuras y los destellos ganados.
	motor = _nuevo_motor(ruta, hermano, true)
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	await _esperar(0.9)
	var ids2: Array = motor._rondas.map(func(r: Dictionary) -> String: return r["id"])
	_check(motor._indice_prueba == 1 and ids2 == ids and motor._destellos_pruebas == destellos_ronda_1,
		"al volver retoma la ronda 2 con las mismas figuras y %d destellos" % destellos_ronda_1)
	_check(motor._rondas[0]["hecha"] and not motor._rondas[1]["hecha"], "la medalla de la ronda 1 sigue llena")
	for i in range(1, ids.size()):
		ok = await _completar_ronda(motor)
		_check(ok, "ronda %d (%s) completa" % [i + 1, ids[i]])
		if i + 1 < ids.size():
			_check(await _esperar_ronda(motor, i + 1, resultado), "entra la ronda %d" % [i + 2])
	var t0 := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	_check(resultado["destellos"] > destellos_ronda_1, "completado(destellos=%d) solo al final de las %d rondas" % [resultado["destellos"], ids.size()])
	_check(progreso.obtener_estado_parcial(hermano, PLANETA_QA, id_nivel).is_empty(), "al ganar se borra el avance a medio jugar")
	motor.queue_free()
	await _esperar(0.2)


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


func _probar_nivel(ruta: String, hermano: String, etiqueta := "") -> void:
	print("-- %s (%s) --" % [etiqueta if etiqueta != "" else ruta.trim_prefix("res://datos/niveles/arcoiris/"), hermano])
	_check(FileAccess.file_exists(ruta), "existe el nivel")
	var motor: Node = load(MOTOR).instantiate()
	if not motor is MinijuegoBase:
		_check(false, "el motor carga su script (revisa errores de parseo arriba)")
		return
	motor.ruta_nivel = ruta
	motor.id_perfil = hermano
	motor.segundos_auto_continuar = 0.4
	var resultado := {"destellos": -1}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	get_root().add_child(motor)
	await _esperar(0.9)

	var nivel: Dictionary = motor.nivel
	var perfil: String = nivel.get("perfil", "")
	var piezas: Array = motor._piezas
	var huecos: Array = motor._huecos
	var distractoras := 0
	if nivel.has("piezas_distractoras"):
		distractoras = int(nivel.get("distractoras_por_partida", nivel["piezas_distractoras"].size()))
	_check(motor._requeridos > 0, "%d huecos requeridos" % motor._requeridos)
	var total: int = piezas.size() + motor._cola.size()
	_check(total == huecos.size() + distractoras, "%d piezas (%d en la bandeja + %d en la cola) = %d huecos + %d distractoras" % [total, piezas.size(), motor._cola.size(), huecos.size(), distractoras])
	if motor._requeridos > motor.MAX_RANURAS:
		_check(motor._ranuras.size() == 1 and motor._ranuras[0].has_meta("barra"), "figura grande: barra de progreso continua")
	else:
		_check(motor._ranuras.size() == motor._requeridos, "una ranura de progreso por hueco requerido")
	_probar_distribucion(motor, piezas, huecos, perfil)
	_probar_voces(nivel, huecos)
	_check(_toda_pieza_tiene_lugar(motor, piezas, huecos), "cada pieza de la bandeja tiene un hueco libre donde calza")
	if motor._exigir_color:
		await _probar_color(motor, piezas, huecos)
	if motor._escala_real:
		_probar_escala_real(motor, piezas, huecos)

	match perfil:
		"semilla":
			await _probar_semilla(motor, piezas, huecos)
		"brote":
			await _probar_brote(motor, piezas, huecos)
		"estrella":
			await _probar_estrella(motor, piezas, huecos)

	if motor._limite_intentos != null:
		await _probar_derrota(motor, piezas, huecos)

	# Completar todo como lo haria un nino: tomar una pieza de la bandeja, girarla (tocando) y soltarla
	# sobre un hueco libre donde calce. La cola repone la bandeja a medida que se encaja.
	var todo_encajo := true
	var repuestas := 0
	var cola_inicial: int = motor._cola.size()
	var avanzo := true
	while avanzo and motor._encajados < motor._requeridos:
		avanzo = false
		for pieza: PiezaEncajar in motor._piezas.duplicate():
			if pieza.colocada or motor._encajados >= motor._requeridos:
				continue
			var hueco = _hueco_libre_para(motor, pieza)
			if hueco == null:
				continue
			if motor._rotacion_por_toque:
				for k in 8:
					if Geo.calzan(pieza.poligono(), hueco["forma_centrada"]):
						break
					pieza.tocada.emit(pieza)
			var cola_antes: int = motor._cola.size()
			var r: String = motor.soltar_pieza(pieza, hueco["centro"])
			if r != "encajo":
				todo_encajo = false
				print("        %s en %s -> %s" % [pieza.id, hueco["id"], r])
				continue
			repuestas += cola_antes - motor._cola.size()
			avanzo = true
			await _esperar(0.03)
	_check(todo_encajo and motor._encajados >= motor._requeridos, "todas las piezas encajan en su hueco (%d/%d)" % [motor._encajados, motor._requeridos])
	if cola_inicial > 0:
		_check(motor._cola.is_empty() and repuestas == cola_inicial, "la cola repuso la bandeja al encajar (%d piezas)" % repuestas)
	var t0 := Time.get_ticks_msec()
	# La fiesta final espera la voz de la figura (con dato, hasta 7,5 s) y la celebracion.
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	_check(resultado["destellos"] > 0, "completado(destellos=%d) al terminar" % resultado["destellos"])
	motor.queue_free()
	await _esperar(0.15)


func _probar_semilla(motor: Node, piezas: Array, huecos: Array) -> void:
	_check(motor._sin_error and motor._limite_intentos == null, "Semilla: sin error ni limite")
	var par := _par_equivocado(motor, piezas, huecos)
	if not par.is_empty():
		var r: String = motor.soltar_pieza(par[0], par[1]["centro"])
		_check(r == "rebote" and motor._intentos_usados == 0, "Semilla: soltar mal rebota sin 'no' ni intento (%s)" % r)
		await _esperar(0.5)
	# Tocar una pieza la manda sola a su casita.
	var libre: PiezaEncajar = null
	for pieza in piezas:
		if not pieza.colocada and motor._hueco_para(pieza) != null:
			libre = pieza
			break
	if libre != null:
		libre.tocada.emit(libre)
		await _esperar(0.4)
		_check(libre.colocada, "Semilla: tocar una pieza la lleva a su casita")
	# Pista por inactividad.
	motor._inactivo = motor._ayuda_idle - 0.05
	await _esperar(0.2)
	_check(motor._siluetas.hueco_pista != null, "Semilla: tras %.0f s quieto, brilla una casita de pista" % motor._ayuda_idle)


func _probar_brote(motor: Node, piezas: Array, huecos: Array) -> void:
	_check(motor._objetivo_guiado and motor._siluetas.hueco_objetivo != null, "Brote: hay un objetivo resaltado")
	var ruta_objetivo: String = motor._ruta_voz_objetivo()
	_check(ResourceLoader.exists("res://assets/audio/" + ruta_objetivo), "Brote: voz del objetivo existe (%s)" % ruta_objetivo.get_file())
	if motor._enderezar:
		for pieza in piezas:
			_check(is_zero_approx(pieza.rotacion_grados), "Brote: piezas derechas en la bandeja")
			break
	var par := _par_equivocado(motor, piezas, huecos)
	if not par.is_empty():
		var antes: int = motor._intentos_usados
		var r: String = motor.soltar_pieza(par[0], par[1]["centro"])
		var espera := antes + (1 if motor._limite_intentos != null else 0)
		_check(r == "no_es_este" and motor._intentos_usados == espera, "Brote: forma equivocada -> no es este (%s)" % r)
		await _esperar(0.6)
	var objetivo: Dictionary = motor._objetivo
	var pieza: PiezaEncajar = _pieza_libre_para(motor, piezas, objetivo)
	if pieza != null:
		var r: String = motor.soltar_pieza(pieza, objetivo["centro"])
		_check(r == "encajo", "Brote: la pieza del objetivo encaja%s" % (" y se endereza" if motor._enderezar else ""))
		await _esperar(0.1)
		_check(motor._objetivo != objetivo, "Brote: al encajar, el objetivo pasa a otra forma")


func _probar_estrella(motor: Node, piezas: Array, huecos: Array) -> void:
	_check(motor._limite_intentos != null, "Estrella: tiene limite (estrellitas)")
	if not motor._rotacion_por_toque:
		return
	var desordenadas := 0
	for pieza in piezas:
		if pieza.id.begins_with("pieza_"):
			var hueco = _hueco_origen(huecos, pieza)
			if hueco != null and not Geo.calzan(pieza.poligono(), hueco["forma_centrada"]):
				desordenadas += 1
	# Piezas casi cuadradas (trozos de franja de Rusia) calzan igual giradas 90°: ahi no hay que girar.
	var girables := 0
	for pieza in piezas:
		var hueco = _hueco_origen(huecos, pieza)
		if hueco != null and not (Geo.calzan(pieza.poligono(float(hueco["rotacion"]) + 90.0), hueco["forma_centrada"]) and Geo.calzan(pieza.poligono(float(hueco["rotacion"]) + 180.0), hueco["forma_centrada"])):
			girables += 1
	_check(desordenadas > 0 or girables == 0, "Estrella: %d piezas llegan giradas (%d necesitan giro)" % [desordenadas, girables])
	for pieza in piezas:
		var hueco = _hueco_origen(huecos, pieza)
		if hueco == null or Geo.calzan(pieza.poligono(), hueco["forma_centrada"]):
			continue
		var solo_ese := true
		for otro in motor._candidatos(hueco["centro"]):
			for otra in piezas:
				solo_ese = solo_ese and not (otro != hueco and Geo.calzan(pieza.poligono(), otro["forma_centrada"]))
		if not solo_ese:
			continue
		var antes: int = motor._intentos_usados
		var r: String = motor.soltar_pieza(pieza, hueco["centro"])
		if motor._giro_cuenta_fallo:
			_check(r == "girar" and motor._intentos_usados == antes + 1, "Estrella: pieza correcta pero chueca -> pide girar (%s)" % r)
			await _esperar(0.6)
			var giros := 0
			while not Geo.calzan(pieza.poligono(), hueco["forma_centrada"]) and giros < 8:
				pieza.tocada.emit(pieza)
				giros += 1
			_check(giros > 0 and giros < 8, "Estrella: tocar gira la pieza (%d toques)" % giros)
			await _esperar(0.3)
			r = motor.soltar_pieza(pieza, hueco["centro"])
			_check(r == "encajo", "Estrella: ya girada, encaja")
		else:
			# HE-40 #5: acertar el lugar con la pieza chueca no es fallo; queda flotando sobre su hueco.
			_check(r == "girar" and motor._intentos_usados == antes and motor.pieza_flotando() == pieza,
				"Estrella: pieza correcta pero chueca -> NO cuenta fallo y queda flotando sobre su hueco (%s, intentos %d)" % [r, motor._intentos_usados])
			await _esperar(0.3)
			_check(pieza.modulate.a < 0.9 and pieza.centro_global().distance_to(hueco["centro"]) < 4.0, "Estrella: flota semitransparente sobre el hueco")
			var giros := 0
			while not pieza.colocada and giros < 8:
				pieza.tocada.emit(pieza)
				giros += 1
				await _esperar(0.05)
			_check(pieza.colocada and giros < 8, "Estrella: con toques gira ahi mismo y encaja sola (%d toques)" % giros)
			_check(motor.pieza_flotando() == null and is_equal_approx(pieza.modulate.a, 1.0), "Estrella: deja de flotar al encajar")
		break


func _probar_derrota(motor: Node, piezas: Array, huecos: Array) -> void:
	var par := _par_equivocado(motor, piezas, huecos)
	if par.is_empty():
		print("        (sin par equivocado para forzar la derrota-gag)")
		return
	motor._intentos_usados = int(motor._limite_intentos) - 1
	motor.soltar_pieza(par[0], par[1]["centro"])
	_check(motor._en_gag, "derrota-gag al agotar %d intentos" % motor._limite_intentos)
	await _esperar(1.6)
	_check(motor._boton_otra_vez.visible, "aparece el boton gigante '¡otra vez!'")
	motor._boton_otra_vez.pressed.emit()
	await _esperar(0.6)
	var libres := true
	for pieza in piezas:
		libres = libres and (pieza.colocada or not pieza.bloqueada)
	_check(not motor._en_gag and libres and motor._intentos_usados == 0, "reintento: piezas libres y contador en cero, lo encajado se queda")


## Pieza sin colocar + hueco libre donde no calza de ninguna forma (ni girando ni cerca de otro que calce).
func _par_equivocado(motor: Node, piezas: Array, huecos: Array) -> Array:
	for pieza in piezas:
		if pieza.colocada:
			continue
		for hueco in huecos:
			if hueco["pieza"] != null or hueco["opcional"]:
				continue
			var alguno := false
			for candidato in motor._candidatos(hueco["centro"]):
				alguno = alguno or _calza_con_giros(motor, pieza, candidato)
			if not alguno:
				return [pieza, hueco]
	return []


## Hueco libre y requerido donde la pieza calza con los giros que permite el nivel (el de su origen primero).
func _hueco_libre_para(motor: Node, pieza: PiezaEncajar):
	var origen = _hueco_origen(motor._huecos, pieza)
	if origen != null and origen["pieza"] == null and _calza_con_giros(motor, pieza, origen):
		return origen
	for hueco in motor._huecos:
		if hueco["pieza"] == null and not hueco["opcional"] and _calza_con_giros(motor, pieza, hueco):
			return hueco
	for hueco in motor._huecos:
		if hueco["pieza"] == null and _calza_con_giros(motor, pieza, hueco):
			return hueco
	return null


## La bandeja nunca ofrece una pieza (que no sea distractora) sin un lugar libre donde calce.
func _toda_pieza_tiene_lugar(motor: Node, piezas: Array, _huecos: Array) -> bool:
	var ok := true
	for pieza: PiezaEncajar in piezas:
		if pieza.colocada or not pieza.id.begins_with("pieza_"):
			continue
		if _hueco_libre_para(motor, pieza) == null:
			ok = false
			print("        %s no tiene lugar libre" % pieza.id)
	return ok


## La queja del PO (27-Sep-2026): las piezas de la derecha no se veian capaces de armar la figura de la
## izquierda. Con escala real, cada pieza de la bandeja mide lo mismo que su silueta.
func _probar_escala_real(motor: Node, piezas: Array, huecos: Array) -> void:
	var ok := true
	for pieza: PiezaEncajar in piezas:
		if pieza.colocada:
			continue
		ok = ok and is_equal_approx(pieza.escala_bandeja, 1.0)
		var hueco = _hueco_origen(huecos, pieza)
		if hueco != null:
			var a := absf(Geo.area(pieza.poligono()))
			var b := absf(Geo.area(hueco["poligono"]))
			ok = ok and absf(a - b) <= b * 0.02
	_check(ok, "bandeja a escala real: cada pieza mide lo mismo que su silueta")


## Banderas: una franja del mismo tamano pero de otro color no entra (Maxi: rebota y su casita brilla).
func _probar_color(motor: Node, piezas: Array, huecos: Array) -> void:
	for pieza: PiezaEncajar in piezas:
		if pieza.colocada:
			continue
		for hueco in huecos:
			if hueco["pieza"] != null or pieza.color.is_equal_approx(hueco["color"]):
				continue
			if not Geo.calzan(pieza.poligono(hueco["rotacion"]), hueco["forma_centrada"]):
				continue
			var otro_color := true
			for c in motor._candidatos(hueco["centro"]):
				otro_color = otro_color and not (pieza.color.is_equal_approx(c["color"]) and Geo.calzan(pieza.poligono(c["rotacion"]), c["forma_centrada"]))
			if not otro_color:
				continue
			var antes: int = motor._intentos_usados
			pieza.girar_a(hueco["rotacion"], 0.0)
			var r: String = motor.soltar_pieza(pieza, hueco["centro"])
			_check(r in ["rebote", "no_es_este"] and not pieza.colocada, "bandera: franja de otro color no entra (%s)" % r)
			motor._intentos_usados = antes
			await _esperar(0.5)
			return


func _calza_con_giros(motor: Node, pieza: PiezaEncajar, hueco: Dictionary) -> bool:
	if motor._exigir_color and not pieza.color.is_equal_approx(hueco["color"]):
		return false
	if motor._enderezar:
		return Geo.calzan(pieza.poligono(hueco["rotacion"]), hueco["forma_centrada"])
	if motor._rotacion_por_toque:
		return motor._calza_girando(pieza, hueco)
	return Geo.calzan(pieza.poligono(), hueco["forma_centrada"])


func _pieza_libre_para(motor: Node, piezas: Array, hueco: Dictionary) -> PiezaEncajar:
	var origen: PiezaEncajar = null
	for pieza in piezas:
		if pieza.id == "pieza_" + hueco["id"] and not pieza.colocada:
			origen = pieza
	if origen != null:
		return origen
	for pieza in piezas:
		if not pieza.colocada and _calza_con_giros(motor, pieza, hueco):
			return pieza
	return null


func _hueco_origen(huecos: Array, pieza: PiezaEncajar):
	for hueco in huecos:
		if pieza.id == "pieza_" + hueco["id"]:
			return hueco
	return null


## Asignacion hueco -> pieza (cada pieza a lo mas una vez).
func _asignacion(motor: Node, piezas: Array, huecos: Array) -> Dictionary:
	var usadas := {}
	var asignacion := {}
	for hueco in huecos:
		var elegida: PiezaEncajar = null
		for pieza in piezas:
			if usadas.has(pieza) or pieza.colocada:
				continue
			if pieza.id == "pieza_" + hueco["id"]:
				elegida = pieza
				break
		if elegida == null:
			for pieza in piezas:
				if not usadas.has(pieza) and not pieza.colocada and _calza_con_giros(motor, pieza, hueco):
					elegida = pieza
					break
		if elegida != null:
			usadas[elegida] = true
			asignacion[hueco["id"]] = elegida
		elif hueco["pieza"] != null:
			asignacion[hueco["id"]] = hueco["pieza"]
	return asignacion


func _probar_distribucion(motor: Node, piezas: Array, huecos: Array, perfil: String) -> void:
	var zona_figuras: Rect2 = motor.ZONA_FIGURAS.grow(4)
	var bandeja: Rect2 = motor.ZONA_BANDEJA.grow(4)
	var bloqueos := [
		motor.get_node("%boton_salir").get_global_rect(),
		motor.get_node("%boton_cometa").get_global_rect(),
		motor.get_node("%anfitriona").get_global_rect(),
		Rect2(motor.get_node("%barra_progreso").get_global_rect().position, motor.get_node("%barra_progreso").get_combined_minimum_size()),
	]
	var huecos_ok := true
	for hueco in huecos:
		var caja := Geo.caja(hueco["poligono"])
		if not zona_figuras.encloses(caja):
			huecos_ok = false
			print("        hueco %s fuera de la zona: %s" % [hueco["id"], caja])
		for bloqueo in bloqueos:
			if caja.intersects(bloqueo.grow(-2)):
				huecos_ok = false
				print("        hueco %s tapa un boton/Coco/barra" % hueco["id"])
	_check(huecos_ok, "siluetas dentro de su zona, sin tapar botones, Coco ni la barra")

	var cajas: Array = []
	var bandeja_ok := true
	var lado_min := INF
	var emblemas_ok := true
	for pieza in piezas:
		var medida: Vector2 = Geo.caja(pieza.poligono()).size * pieza.escala_bandeja
		var caja := Rect2(pieza.casa - medida / 2.0, medida)
		bandeja_ok = bandeja_ok and bandeja.encloses(caja)
		for otra in cajas:
			bandeja_ok = bandeja_ok and not caja.grow(-3).intersects(otra)
		cajas.append(caja)
		var origen = _hueco_origen(huecos, pieza)
		if origen != null and int(origen.get("capa", 0)) > 0:
			# Emblema encima (estrella de Chile de Maxi): se ve de >= 52 px; su zona tocable es de 96 px.
			emblemas_ok = emblemas_ok and minf(medida.x, medida.y) >= minf(52.0, LADO_MINIMO[perfil])
			continue
		lado_min = minf(lado_min, minf(medida.x, medida.y))
	_check(bandeja_ok, "piezas dentro de la bandeja sin encimarse (factor %.2f)" % piezas[0].escala_bandeja)
	_check(emblemas_ok, "emblemas encima de al menos 52 px")
	_check(lado_min >= LADO_MINIMO[perfil], "pieza mas chica en bandeja: %.0f px (minimo %s %.0f; zona tocable >= 96 px)" % [lado_min, perfil, LADO_MINIMO[perfil]])


func _probar_voces(nivel: Dictionary, huecos: Array) -> void:
	var faltan: Array = []
	var rutas: Array = []
	for clave in nivel.get("lineas_voz", {}):
		if clave == "objetivo_prefijo":
			continue
		var valor = nivel["lineas_voz"][clave]
		rutas.append_array(valor if valor is Array else [valor])
	for figura in nivel.get("figuras", []):
		if figura.has("voz_completa"):
			rutas.append(figura["voz_completa"])
		var config: Dictionary = figura.get("config", {})
		for clave in config.get("lineas_voz", {}):
			var valor = config["lineas_voz"][clave]
			rutas.append_array(valor if valor is Array else [valor])
		for sub in config.get("figuras", []):
			if sub.has("voz_completa"):
				rutas.append(sub["voz_completa"])
	var prefijo := str(nivel.get("lineas_voz", {}).get("objetivo_prefijo", ""))
	if prefijo != "":
		for hueco in huecos:
			if not hueco["opcional"]:
				rutas.append(prefijo + hueco["nombre_voz"] + ".wav")
	for ruta in rutas:
		if not ResourceLoader.exists("res://assets/audio/" + str(ruta)):
			faltan.append(ruta)
	_check(faltan.is_empty(), "todas las voces del nivel existen (%d) %s" % [rutas.size(), "" if faltan.is_empty() else str(faltan)])


# ---------------------------------------------------------------------------
# HE-40 (28-Sep-2026): sin bichos, umbrales de estrellitas, bandera primero y regalo por ronda
# ---------------------------------------------------------------------------

const PROHIBIDOS := ["mariposa", "abeja", "arana", "bicho", "insecto", "catarina", "chinita", "gusano", "hormiga", "mosca", "libelula"]


## Auditoria UX HE-40 R1 (bloqueante): ninguna figura ni voz nombra un bicho en ningun perfil.
func _probar_sin_bichos() -> void:
	print("-- HE-40 R1: sin bichos en ningun nivel de Formas --")
	var encontrados: Array = []
	for zona in ZONAS:
		for perfil in HERMANOS:
			var texto := FileAccess.get_file_as_string("res://datos/niveles/arcoiris/%s/formas_%s.json" % [zona, perfil]).to_lower()
			for bicho in PROHIBIDOS:
				if texto.contains(bicho):
					encontrados.append("%s/%s: %s" % [zona, perfil, bicho])
	_check(encontrados.is_empty(), "ninguna figura de Formas es un bicho %s" % str(encontrados))


## Sofia (zona 1): la bandera va primero y trae sus umbrales; la regla 3/2/1 en los bordes; el regalo
## tras 2 derrotas pone el 15 % de lo que falta (1-4) y `_derrotas` se reinicia en cada ronda.
func _probar_umbrales_y_regalo() -> void:
	print("-- HE-40: umbrales de estrellitas, bandera primero y regalo por ronda (Sofia z1) --")
	var ruta := "res://datos/niveles/arcoiris/zona1_claro/formas_estrella.json"
	var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	_check(nivel.get("rondas", []) == ["bandera", "monumento"], "Sofia arma primero la bandera y cierra con el monumento")
	_check(int(nivel.get("piezas_en_bandeja", 0)) == 4, "zona 1: 4 piezas en la bandeja (curva suave)")
	var progreso := get_root().get_node("Progreso")
	progreso.borrar_estado_parcial("sofia", PLANETA_QA, str(nivel.get("id_nivel", "")))
	var motor := _nuevo_motor(ruta, "sofia", false)
	await _esperar(0.9)
	var umbrales: Dictionary = motor._umbrales
	_check(not umbrales.is_empty() and int(umbrales["tres"]) == 3 and int(umbrales["dos"]) == 8, "la ronda de bandera lee sus umbrales (%s)" % str(umbrales))
	var casos := {3: 3, 4: 2, 8: 2, 9: 1}
	var bordes_ok := true
	for fallos in casos:
		motor._intentos_usados = fallos
		bordes_ok = bordes_ok and motor._estrellitas_base() == casos[fallos]
	_check(bordes_ok, "umbrales en los bordes: <=3 -> 3, 4..8 -> 2, 9 -> 1")
	motor._intentos_usados = 0
	motor._pistas_usadas = 1
	_check(motor._calcular_estrellitas() == 2, "cada pista resta una estrellita")
	motor._pistas_usadas = 0
	# Dos derrotas en la ronda: el regalo pone el 15 % de lo que falta (entre 1 y 4).
	var piezas: Array = motor._piezas.duplicate()
	var huecos: Array = motor._huecos
	var esperado: int = motor.piezas_de_regalo()
	_check(esperado == clampi(ceili(0.15 * (motor._requeridos - motor._encajados)), 1, 4), "regalo = 15 %% de las %d que faltan -> %d" % [motor._requeridos - motor._encajados, esperado])
	var antes: int = motor._encajados
	for vuelta in 2:
		var par := _par_equivocado(motor, motor._piezas.filter(func(p: PiezaEncajar) -> bool: return not p.colocada), huecos)
		if par.is_empty():
			print("        (sin par equivocado para forzar la derrota-gag)")
			break
		motor._intentos_usados = int(motor._limite_intentos) - 1
		motor.soltar_pieza(par[0], par[1]["centro"])
		_check(motor._en_gag, "derrota-gag %d en la ronda" % (vuelta + 1))
		await _esperar(1.5)
		motor._boton_otra_vez.pressed.emit()
		await _esperar(0.3)
	await _esperar(0.7 + esperado * 0.35 + 0.4)
	_check(motor._encajados == antes + esperado and motor._pistas_usadas == 0, "tras 2 derrotas Coco regala %d pieza(s) sin costo (%d -> %d)" % [esperado, antes, motor._encajados])
	_check(motor._derrotas == 2, "la ronda lleva 2 derrotas")
	motor._limpiar_tablero()
	_check(motor._derrotas == 0 and not motor._regalo_dado, "bug HE-40 #6: las derrotas se reinician en cada ronda")
	motor.queue_free()
	await _esperar(0.2)


## disenador-niveles HE-40 #12: salir a mitad de una ronda no pierde las piezas puestas.
func _probar_guardado_pieza_a_pieza() -> void:
	print("-- HE-40 #12: guardado pieza a pieza dentro de la ronda (Sofia z3) --")
	var ruta := "res://datos/niveles/arcoiris/zona3_chupetines/formas_estrella.json"
	var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var progreso := get_root().get_node("Progreso")
	var id_nivel := str(nivel.get("id_nivel", ""))
	progreso.borrar_estado_parcial("sofia", PLANETA_QA, id_nivel)
	var motor := _nuevo_motor(ruta, "sofia", true)
	await _esperar(0.9)
	var ids: Array = motor._rondas.map(func(r: Dictionary) -> String: return r["id"])
	var puestas := 0
	# La bandeja se repone al encajar (cola): se relee en cada intento en vez de recorrer una copia
	# fija, que dejaba fuera las piezas nuevas y fallaba al azar segun la bandera sorteada.
	for intento in 20:
		if puestas >= 3:
			break
		var pieza: PiezaEncajar = null
		var libre = null
		for candidata: PiezaEncajar in motor._en_bandeja():
			libre = _hueco_libre_para(motor, candidata)
			if libre is Dictionary:
				pieza = candidata
				break
		if pieza == null:
			await _esperar(0.2)
			continue
		var hueco: Dictionary = libre
		for k in 8:
			if Geo.calzan(pieza.poligono(), hueco["forma_centrada"]):
				break
			pieza.tocada.emit(pieza)
		if motor.soltar_pieza(pieza, hueco["centro"]) == "encajo":
			puestas += 1
		await _esperar(0.05)
	var estado: Dictionary = progreso.obtener_estado_parcial("sofia", PLANETA_QA, id_nivel)
	_check(puestas == 3 and (estado.get("huecos_hechos", []) as Array).size() == 3 and int(estado.get("indice", -1)) == 0, "cada pieza puesta queda guardada (%d huecos)" % (estado.get("huecos_hechos", []) as Array).size())
	motor.queue_free()
	await _esperar(0.3)
	motor = _nuevo_motor(ruta, "sofia", true)
	await _esperar(0.9)
	var ids2: Array = motor._rondas.map(func(r: Dictionary) -> String: return r["id"])
	_check(motor._indice_prueba == 0 and ids2 == ids and motor._encajados == 3, "al volver, la misma ronda con sus 3 piezas puestas (%d)" % motor._encajados)
	var colocadas: int = motor._piezas.filter(func(p: PiezaEncajar) -> bool: return p.colocada).size()
	_check(colocadas == 3 and motor._en_bandeja().size() > 0, "las piezas repuestas estan en su lugar y la bandeja sigue con piezas")
	motor.queue_free()
	progreso.borrar_estado_parcial("sofia", PLANETA_QA, id_nivel)
	await _esperar(0.2)
