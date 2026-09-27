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
## Uso: godot --headless --path . --script herramientas/qa_test_encajar.gd [-- <filtro>]

const MOTOR := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
## Lado visual mas corto de una pieza en la bandeja. La zona tocable siempre es >= 96 px de
## diametro (PiezaEncajar.RADIO_TOQUE_MINIMO), aunque la forma sea delgada (tronco, cuello).
## Estrella: las figuras de 20+ piezas de Sofia tienen piezas delgadas a proposito (columnas, pilotes,
## almenas); herramientas/figuras_formas.py usa estos mismos minimos al disenarlas.
const LADO_MINIMO := {"semilla": 96.0, "brote": 52.0, "estrella": 22.0}

var _fallos := 0


func _initialize() -> void:
	print("=== QA encajar: Formas traviesas, 5 zonas x rutas de Maxi, Nicole y Sofia ===")
	var filtro := ""
	if OS.get_cmdline_user_args().size() > 0:
		filtro = OS.get_cmdline_user_args()[0]
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/formas_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			await _probar_nivel(ruta, HERMANOS[perfil])
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


func _probar_nivel(ruta: String, hermano: String) -> void:
	print("-- %s (%s) --" % [ruta.trim_prefix("res://datos/niveles/arcoiris/"), hermano])
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
	if bool(nivel.get("bandeja_escala_real", false)):
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
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 15000:
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
	_check(desordenadas > 0, "Estrella: %d piezas llegan giradas" % desordenadas)
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


func _calza_con_giros(motor: Node, pieza: PiezaEncajar, hueco: Dictionary) -> bool:
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
	for pieza in piezas:
		var medida: Vector2 = Geo.caja(pieza.poligono()).size * pieza.escala_bandeja
		var caja := Rect2(pieza.casa - medida / 2.0, medida)
		bandeja_ok = bandeja_ok and bandeja.encloses(caja)
		for otra in cajas:
			bandeja_ok = bandeja_ok and not caja.grow(-3).intersects(otra)
		cajas.append(caja)
		lado_min = minf(lado_min, minf(medida.x, medida.y))
	_check(bandeja_ok, "piezas dentro de la bandeja sin encimarse (factor %.2f)" % piezas[0].escala_bandeja)
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
	var prefijo := str(nivel.get("lineas_voz", {}).get("objetivo_prefijo", ""))
	if prefijo != "":
		for hueco in huecos:
			if not hueco["opcional"]:
				rutas.append(prefijo + hueco["nombre_voz"] + ".wav")
	for ruta in rutas:
		if not ResourceLoader.exists("res://assets/audio/" + str(ruta)):
			faltan.append(ruta)
	_check(faltan.is_empty(), "todas las voces del nivel existen (%d) %s" % [rutas.size(), "" if faltan.is_empty() else str(faltan)])
