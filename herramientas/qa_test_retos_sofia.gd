extends SceneTree

## Arnes QA de los retos de Sofia, dificultad v3 (decision del PO 14-Sep-2026).
##
## Formas traviesas (motor encajar), las 5 zonas y el reto dorado:
## - tangram libre: la silueta se llena con la solucion del nivel soltando cada pieza como un dedo
##   (el iman la ajusta a la red), una pieza fuera de lugar no calza, el espejo es obligatorio en la
##   zona 2 y hay pieza intrusa;
## - copia de memoria: se ve el modelo y se tapa, el color equivocado no calza, mirar otra vez resta
##   una estrellita;
## - marco de pentominos: cada pieza de la solucion calza soltandola corrida (ajuste a la cuadricula),
##   una pieza encimada no calza y sobran piezas;
## - pruebas encadenadas (zona 4 y Cima), derrota-gag y regalo de una pieza tras 2 derrotas, pista
##   que coloca una pieza y resta estrellita, avance guardado del reto dorado.
## Parejas de Coco (motor emparejar), las 5 zonas y el reto dorado: tamano del tablero y de las
## cartas, recetas, trios (el turno termina al primer error), sombras con trampa de espejo, cartas
## traviesas, pista, regalo tras 2 derrotas y completado.
## Mapa del planeta: niveles de Sofia en las estaciones y boton del reto dorado.
##
## Uso: godot --headless --path . --script herramientas/qa_test_retos_sofia.gd [-- <filtro>]

const MOTOR_ENCAJAR := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const MOTOR_EMPAREJAR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const NIVELES := "res://datos/niveles/arcoiris/"
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
## Lado minimo de una carta de Sofia en 1280x720 (GDD §6.1 para Estrella).
const CARTA_MINIMA := 64.0

var _fallos := 0
var _filtro := ""


func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		_filtro = OS.get_cmdline_user_args()[0]
	print("=== QA retos de Sofia (dificultad v3) ===")
	var formas: Array = []
	var parejas: Array = []
	for zona in ZONAS:
		formas.append(NIVELES + zona + "/formas_estrella.json")
		parejas.append(NIVELES + zona + "/parejas_estrella.json")
	formas.append(NIVELES + "zona5_cima/formas_estrella_dorado.json")
	parejas.append(NIVELES + "zona5_cima/parejas_estrella_dorado.json")
	for ruta in formas:
		if _filtro == "" or ruta.contains(_filtro):
			await _probar_formas(ruta)
	for ruta in parejas:
		if _filtro == "" or ruta.contains(_filtro):
			await _probar_parejas(ruta)
	if _filtro == "" or "mapa".contains(_filtro):
		await _probar_mapa()
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


func _voces_existen(voces: Dictionary) -> Array:
	var faltan: Array = []
	for clave in voces:
		var valor = voces[clave]
		for ruta in (valor if valor is Array else [valor]):
			if not ResourceLoader.exists("res://assets/audio/" + str(ruta)):
				faltan.append(ruta)
	return faltan


# ---------------------------------------------------------------------------
# Formas traviesas
# ---------------------------------------------------------------------------

func _probar_formas(ruta: String) -> void:
	print("-- %s --" % ruta.trim_prefix(NIVELES))
	_check(FileAccess.file_exists(ruta), "existe el nivel")
	var motor: Node = load(MOTOR_ENCAJAR).instantiate()
	if not motor is MinijuegoBase:
		_check(false, "el motor carga su script")
		return
	motor.ruta_nivel = ruta
	motor.id_perfil = "sofia"
	motor.segundos_auto_continuar = 0.3
	var resultado := {"destellos": -1, "pruebas": 0}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	motor.prueba_completada.connect(func(_i: int) -> void: resultado["pruebas"] += 1)
	get_root().add_child(motor)
	await _esperar(0.8)
	var nivel: Dictionary = motor.nivel
	_check(nivel.get("perfil", "") == "estrella", "perfil Estrella")
	var voces: Array = _voces_existen(nivel.get("lineas_voz", {}))
	for prueba in nivel.get("pruebas", []):
		voces.append_array(_voces_existen(prueba.get("lineas_voz", {})))
	_check(voces.is_empty(), "todas las voces del nivel existen %s" % ("" if voces.is_empty() else str(voces)))
	_check(motor._boton_pista.visible, "boton de pista visible (cuesta estrellita)")

	var total_pruebas := maxi(1, nivel.get("pruebas", []).size())
	for indice in total_pruebas:
		_check(motor._indice_prueba == indice, "prueba %d de %d armada (%s)" % [indice + 1, total_pruebas, motor._mecanica])
		match motor._mecanica:
			"tangram_libre":
				await _probar_tangram(motor)
			"memoria":
				await _probar_memoria(motor)
			"marco":
				await _probar_marco(motor, indice == 0 and ruta.contains("zona4"))
		if indice + 1 < total_pruebas:
			var t0 := Time.get_ticks_msec()
			while motor._indice_prueba == indice and Time.get_ticks_msec() - t0 < 12000:
				await process_frame
			await _esperar(0.3)
	var t1 := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t1 < 15000:
		await process_frame
	_check(resultado["pruebas"] == total_pruebas - 1, "se celebraron %d pruebas intermedias" % resultado["pruebas"])
	_check(resultado["destellos"] > 0, "completado(destellos=%d) al terminar" % resultado["destellos"])
	var estrellitas: int = motor._calcular_estrellitas()
	_check(estrellitas >= 1 and estrellitas <= 3, "estrellitas en rango (%d, pistas usadas %d)" % [estrellitas, motor._pistas_usadas])
	motor.queue_free()
	await _esperar(0.15)


func _distribucion_ok(motor: Node) -> void:
	var bandeja: Rect2 = motor._zona_bandeja.grow(4)
	var ok := true
	for pieza: PiezaEncajar in motor._piezas:
		if pieza.colocada:
			continue
		var medida: Vector2 = Geo.caja(pieza.poligono()).size * pieza.escala_bandeja
		ok = ok and bandeja.encloses(Rect2(pieza.casa - medida / 2.0, medida))
	_check(ok, "piezas dentro de la bandeja (factor %.2f)" % motor._piezas[0].escala_bandeja)


## Tangram libre: arma la silueta con la solucion del nivel, soltando cada pieza corrida unos px.
func _probar_tangram(motor: Node) -> void:
	var huecos: Array = motor._huecos
	var distractoras := int(motor._cfg.get("distractoras_por_partida", 0))
	_check(motor._piezas.size() == huecos.size() + distractoras, "%d piezas = %d de la silueta + %d intrusa(s)" % [motor._piezas.size(), huecos.size(), distractoras])
	_check(motor._figuras[0]["union"].size() == 1, "silueta unida en un solo contorno")
	_distribucion_ok(motor)
	var usadas := {}
	if bool(motor._cfg.get("boton_espejo", false)):
		var p_hueco = null
		for hueco in huecos:
			if hueco["forma"] == "paralelogramo":
				p_hueco = hueco
		var pieza_p := _pieza_para(motor, p_hueco, usadas)
		if p_hueco != null and pieza_p != null and p_hueco["espejo"]:
			pieza_p.rotacion_grados = p_hueco["rotacion"]
			_check(not pieza_p.volteada and motor.centro_libre(pieza_p, p_hueco["centro"]) == null, "espejo obligatorio: el paralelogramo sin voltear no calza")
			motor._elegir(pieza_p)
			motor._al_tocar_espejo()
			await _esperar(0.35)
			_check(pieza_p.volteada and motor.centro_libre(pieza_p, p_hueco["centro"]) != null, "boton espejo voltea la pieza elegida y ahora calza")
		if pieza_p != null:
			usadas.erase(pieza_p)
	# Una pieza grande soltada sobre una zona donde no cabe (girada 45° fuera de la red) no calza.
	for pieza: PiezaEncajar in motor._piezas:
		if pieza.forma == "triangulo_rect" and pieza.ancho > motor._lado_red * 1.9:
			pieza.rotacion_grados = 45.0
			var r0: String = motor.soltar_pieza(pieza, huecos[0]["centro"])
			_check(r0 == "no_es_este", "pieza girada que no cabe -> no es este (%s)" % r0)
			await _esperar(0.3)
			break
	var todas := true
	var pista_probada := false
	for hueco in huecos:
		if motor._terminado:
			break
		if not pista_probada:
			pista_probada = true
			var antes: int = motor._encajados
			motor._al_tocar_pista()
			await _esperar(0.3)
			_check(motor._encajados == antes + 1 and motor._pistas_usadas == 1, "pista: coloca una pieza correcta y gasta una estrellita")
			continue
		if _hueco_cubierto(motor, hueco):
			continue
		var pieza := _pieza_para(motor, hueco, usadas)
		if pieza == null:
			todas = false
			continue
		pieza.volteada = hueco["espejo"]
		pieza.rotacion_grados = hueco["rotacion"]
		var costo_exacto: float = motor._costo_libre(pieza, Geo.desplazado(pieza.poligono(), hueco["centro"]))
		var r: String = motor.soltar_pieza(pieza, hueco["centro"] + Vector2(9, -7))
		if r != "encajo":
			todas = false
			print("        %s (%s %.1fx%.1f rot %.0f espejo %s) en %s -> %s | costo exacto %.1f de area %.1f | diferencia forma %.3f" % [
				pieza.id, pieza.forma, pieza.ancho, pieza.alto, pieza.rotacion_grados, pieza.volteada, hueco["id"], r,
				costo_exacto, absf(Geo.area(pieza.poligono())), Geo.diferencia(pieza.poligono(), hueco["forma_centrada"])])
			var poligono := Geo.desplazado(pieza.poligono(), hueco["centro"])
			for otra in motor._libres:
				var pisado := 0.0
				for trozo in Geometry2D.intersect_polygons(poligono, motor._libres[otra]):
					pisado += absf(Geo.area(trozo))
				if pisado > 1.0:
					var su_hueco := ""
					for h in huecos:
						if Geo.diferencia(motor._libres[otra], h["poligono"]) <= 0.02:
							su_hueco = h["id"]
					print("          pisa %.0f px2 de %s (esta en hueco '%s')" % [pisado, otra.id, su_hueco])
			var dentro := 0.0
			for contorno in motor._figuras[0]["union"]:
				for trozo in Geometry2D.intersect_polygons(poligono, contorno):
					dentro += absf(Geo.area(trozo))
			print("          fuera de la silueta: %.0f px2 (contornos en la union: %d)" % [absf(Geo.area(poligono)) - dentro, motor._figuras[0]["union"].size()])
		await _esperar(0.05)
	_check(todas, "cada pieza de la solucion calza soltandola cerca (ajuste a la red)")
	_check(motor._cobertura() >= motor.COBERTURA_MINIMA, "silueta cubierta (%.0f %%)" % (motor._cobertura() * 100.0))


func _hueco_cubierto(motor: Node, hueco: Dictionary) -> bool:
	for pieza in motor._libres:
		if Geo.diferencia(motor._libres[pieza], hueco["poligono"]) <= Geo.TOLERANCIA_CALCE:
			return true
	return false


func _pieza_para(motor: Node, hueco, usadas: Dictionary) -> PiezaEncajar:
	if hueco == null:
		return null
	for pieza: PiezaEncajar in motor._piezas:
		if usadas.has(pieza) or pieza.colocada or not pieza.id.begins_with("pieza_"):
			continue
		if pieza.forma == hueco["forma"] and is_equal_approx(pieza.ancho, hueco["ancho"]) and is_equal_approx(pieza.alto, hueco["alto"]):
			usadas[pieza] = true
			return pieza
	return null


func _probar_memoria(motor: Node) -> void:
	_check(motor._en_modelo and motor._siluetas.modelo_visible, "se ve el modelo a color y no se puede arrastrar")
	var t0 := Time.get_ticks_msec()
	while motor._en_modelo and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	_check(not motor._en_modelo and not motor._siluetas.modelo_visible, "Coco tapa el modelo")
	_distribucion_ok(motor)
	var huecos: Array = motor._huecos
	# Color equivocado: una pieza con la misma forma pero otro color no calza.
	var probado := false
	for hueco in huecos:
		for pieza: PiezaEncajar in motor._piezas:
			if pieza.colocada or pieza.forma != hueco["forma"] or pieza.color.is_equal_approx(hueco["color"]):
				continue
			if not (is_equal_approx(pieza.ancho, hueco["ancho"]) and is_equal_approx(pieza.alto, hueco["alto"])):
				continue
			pieza.volteada = hueco["espejo"]
			pieza.rotacion_grados = hueco["rotacion"]
			var r: String = motor.soltar_pieza(pieza, hueco["centro"])
			# "girar" tambien vale: su propio hueco puede estar al lado y solo le falta el giro.
			_check(r in ["no_es_este", "girar"], "memoria: misma forma de otro color no encaja (%s)" % r)
			probado = true
			break
		if probado:
			break
	await _esperar(0.4)
	motor._al_tocar_ojo()
	await _esperar(0.1)
	_check(motor._pistas_usadas >= 1 and motor._en_modelo, "mirar otra vez muestra el modelo y resta una estrellita")
	t0 = Time.get_ticks_msec()
	while motor._en_modelo and Time.get_ticks_msec() - t0 < 8000:
		await process_frame
	var todas := true
	for hueco in huecos:
		if hueco["pieza"] != null:
			continue
		var pieza: PiezaEncajar = null
		for candidata: PiezaEncajar in motor._piezas:
			if not candidata.colocada and candidata.forma == hueco["forma"] and candidata.color.is_equal_approx(hueco["color"]):
				pieza = candidata
		if pieza == null:
			todas = false
			continue
		pieza.volteada = hueco["espejo"]
		pieza.rotacion_grados = hueco["rotacion"]
		var r: String = motor.soltar_pieza(pieza, hueco["centro"] + Vector2(6, 4))
		todas = todas and r == "encajo"
		await _esperar(0.05)
	_check(todas, "memoria: cada pieza con su color en su lugar encaja")


func _probar_marco(motor: Node, probar_derrotas: bool) -> void:
	var marco: Dictionary = motor._marco
	var solucion: Array = motor._cfg.get("solucion", [])
	if motor._cfg.get("modo", "") == "reto_dorado":
		_check(motor._piezas.size() == 12 and motor._requeridos == 12, "reto dorado: las 12 piezas llenan el rectangulo")
		_check(bool(motor._cfg.get("guardar_avance", false)), "reto dorado: guarda el avance pieza a pieza")
	else:
		_check(motor._piezas.size() > motor._requeridos, "marco: sobran piezas (%d piezas, %d necesarias)" % [motor._piezas.size(), motor._requeridos])
	_check(solucion.size() == motor._requeridos, "la solucion del nivel usa %d piezas" % solucion.size())
	var celdas_solucion := 0
	for entrada in solucion:
		celdas_solucion += entrada["celdas"].size()
	_check(celdas_solucion == marco["lista"].size(), "la solucion cubre las %d celdas del marco" % marco["lista"].size())
	_distribucion_ok(motor)
	if probar_derrotas:
		await _probar_derrotas_marco(motor)
	var todas := true
	var encimada := false
	for entrada in solucion:
		if motor._terminado:
			break
		var pieza: PiezaEncajar = null
		for candidata: PiezaEncajar in motor._piezas:
			if candidata.id == entrada["id"]:
				pieza = candidata
		if pieza == null or pieza.colocada:
			continue
		var centro = _orientar(motor, pieza, entrada["celdas"])
		if centro == null:
			todas = false
			continue
		if not encimada and not motor._celdas_de.is_empty():
			# Encima de una pieza ya puesta: no calza.
			var otra: PiezaEncajar = motor._celdas_de.keys()[0]
			var ocupada: Vector2i = motor._celdas_de[otra][0]
			var lado := float(marco["lado"])
			var centro_ocupada: Vector2 = marco["origen"] + (Vector2(ocupada) + Vector2(0.5, 0.5)) * lado
			# El primer cuadradito de la pieza cae justo sobre una celda ya ocupada.
			var r0: String = motor.soltar_pieza(pieza, centro_ocupada - motor._desfase_celda(pieza, pieza.celdas[0]))
			_check(r0 == "no_es_este", "marco: pieza encimada -> no es este (%s)" % r0)
			encimada = true
			await _esperar(0.3)
			centro = _orientar(motor, pieza, entrada["celdas"])
		var r: String = motor.soltar_pieza(pieza, centro + Vector2(float(marco["lado"]) * 0.3, -float(marco["lado"]) * 0.25))
		if r != "encajo":
			todas = false
			print("        %s -> %s" % [pieza.id, r])
		await _esperar(0.05)
	_check(todas, "marco: cada pieza de la solucion calza soltandola corrida (ajuste a la cuadricula)")


## Busca giro y espejo con que la pieza cae sobre `celdas`; deja la pieza asi y devuelve el centro.
func _orientar(motor: Node, pieza: PiezaEncajar, celdas: Array):
	var objetivo := {}
	var minimo := Vector2(INF, INF)
	var maximo := Vector2(-INF, -INF)
	for celda in celdas:
		var v := Vector2i(int(celda[0]), int(celda[1]))
		objetivo[v] = true
		minimo = minimo.min(Vector2(v))
		maximo = maximo.max(Vector2(v))
	var centro: Vector2 = motor._marco["origen"] + (minimo + maximo + Vector2.ONE) / 2.0 * float(motor._marco["lado"])
	for espejo in [false, true]:
		pieza.volteada = espejo
		for k in 4:
			pieza.rotacion_grados = k * 90.0
			var ocupadas: Array = motor.celdas_en(pieza, centro)
			var iguales := ocupadas.size() == objetivo.size()
			for celda in ocupadas:
				iguales = iguales and objetivo.has(celda)
			if iguales:
				return centro
	return null


func _probar_derrotas_marco(motor: Node) -> void:
	var pieza: PiezaEncajar = motor._piezas[0]
	var fuera: Vector2 = motor._marco["origen"] + Vector2(-float(motor._marco["lado"]) * 0.6, -float(motor._marco["lado"]) * 0.6)
	for vuelta in 2:
		motor._intentos_usados = int(motor._limite_intentos) - 1
		var r: String = motor.soltar_pieza(pieza, fuera)
		_check(r == "no_es_este" and motor._en_gag, "derrota-gag %d al agotar los intentos (%s)" % [vuelta + 1, r])
		await _esperar(1.5)
		_check(motor._boton_otra_vez.visible, "aparece '¡otra vez!'")
		var antes: int = motor._encajados
		motor._boton_otra_vez.pressed.emit()
		await _esperar(1.2)
		if vuelta == 1:
			_check(motor._encajados == antes + 1 and motor._pistas_usadas == 0, "tras 2 derrotas Coco regala una pieza puesta (sin gastar estrellita)")
	# Se quita el regalo para que la prueba siga con la solucion completa.
	for puesta in motor._celdas_de.keys():
		motor._quitar_colocada(puesta)
		puesta.volver_a_casa()
	await _esperar(0.3)


# ---------------------------------------------------------------------------
# Parejas de Coco
# ---------------------------------------------------------------------------

func _probar_parejas(ruta: String) -> void:
	print("-- %s --" % ruta.trim_prefix(NIVELES))
	_check(FileAccess.file_exists(ruta), "existe el nivel")
	var motor: Node = load(MOTOR_EMPAREJAR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = "sofia"
	motor.segundos_auto_continuar = 0.3
	var resultado := {"destellos": -1, "intercambios": 0}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	motor.carta_intercambiada.connect(func(_a, _b) -> void: resultado["intercambios"] += 1)
	get_root().add_child(motor)
	await _esperar(1.0)
	var nivel: Dictionary = motor.nivel
	var cartas: Array = motor._cartas
	var tam: int = motor._tamano_grupo
	var faltan := _voces_existen(nivel.get("lineas_voz", {}))
	_check(faltan.is_empty(), "todas las voces del nivel existen %s" % ("" if faltan.is_empty() else str(faltan)))
	_check(cartas.size() == motor._pares_totales * tam, "%d cartas = %d grupos de %d" % [cartas.size(), motor._pares_totales, tam])
	_check(motor._lado_carta >= CARTA_MINIMA, "cartas de %.0f px (minimo %.0f)" % [motor._lado_carta, CARTA_MINIMA])
	var zona: Rect2 = motor.ZONA_TABLERO.grow(2)
	var dentro := true
	for carta in cartas:
		dentro = dentro and zona.encloses(carta.get_global_rect())
	_check(dentro, "tablero dentro de su zona")
	_check(motor._boton_pista.visible, "boton de pista visible")
	match str(nivel.get("modo", "")):
		"correspondencia":
			_check(cartas.filter(func(c): return c.estilo == "receta").size() == motor._pares_totales, "una carta receta por pareja")
		"sombras":
			_check(cartas.filter(func(c): return c.es_sombra()).size() == motor._pares_totales, "una sombra por pareja")
			_check(_siluetas_distintas(cartas), "sombras con trampa: ninguna sombra es igual a otra (espejo y giros)")

	var grupos := {}
	for carta in cartas:
		if not grupos.has(carta.id_pareja):
			grupos[carta.id_pareja] = []
		grupos[carta.id_pareja].append(carta)
	var ids: Array = grupos.keys()

	# Fallo: primera carta de un grupo y primera de otro. En trios el turno termina en esa segunda carta.
	var antes: int = motor._intentos_usados
	grupos[ids[0]][0].tocada.emit(grupos[ids[0]][0])
	await _esperar(0.05)
	grupos[ids[1]][0].tocada.emit(grupos[ids[1]][0])
	await _esperar(0.05)
	_check(motor._intentos_usados == antes + 1 and motor._seleccionadas.is_empty(), "grupo equivocado -> fallo y el turno termina al primer error")
	await _esperar(float(nivel.get("tiempo_volteo_ms", 900)) / 1000.0 + 0.2)

	# Pista y regalo tras 2 derrotas.
	motor._al_tocar_pista()
	await _esperar(0.2)
	_check(motor._pistas_usadas == 1, "pista usada (resta estrellita)")
	await _esperar(1.5)
	if nivel.get("regalo_tras_derrotas", false):
		for vuelta in 2:
			motor._intentos_usados = int(motor._limite_intentos) - 1
			grupos[ids[0]][0].tocada.emit(grupos[ids[0]][0])
			grupos[ids[1]][0].tocada.emit(grupos[ids[1]][0])
			await _esperar(float(nivel.get("tiempo_volteo_ms", 900)) / 1000.0 + 0.3)
			_check(motor._en_gag, "derrota-gag %d" % (vuelta + 1))
			await _esperar(1.0)
			var acertados: int = motor._pares_acertados
			motor._boton_otra_vez.pressed.emit()
			await _esperar(1.0)
			if vuelta == 1:
				_check(motor._pares_acertados == acertados + 1, "tras 2 derrotas Coco regala un grupo")

	# Completar todo: cada grupo pendiente, carta por carta.
	for id in ids:
		var pendientes: Array = grupos[id].filter(func(c): return not c.esta_acertada)
		if pendientes.is_empty():
			continue
		for carta in pendientes:
			carta.tocada.emit(carta)
			await _esperar(0.02)
		await _esperar(0.9 if motor._intercambios > 0 else 0.1)
	if motor._intercambios > 0:
		_check(resultado["intercambios"] > 0, "cartas traviesas: %d intercambios visibles" % resultado["intercambios"])
	var t0 := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 12000:
		await process_frame
	_check(motor._pares_acertados == motor._pares_totales, "todos los grupos encontrados")
	_check(resultado["destellos"] > 0, "completado(destellos=%d)" % resultado["destellos"])
	motor.queue_free()
	await _esperar(0.15)


## Firma geometrica de cada sombra (forma, giro y espejo): dos sombras iguales harian ambigua la pareja.
func _siluetas_distintas(cartas: Array) -> bool:
	var firmas := {}
	for carta in cartas:
		if not carta.es_sombra():
			continue
		var base: PackedVector2Array
		if carta.forma != "":
			base = Geo.contorno(carta.forma, 100.0, 70.0 if carta.forma != "triangulo_rect" else 100.0)
		else:
			base = Figura_poligono(carta.figura)
		if carta.espejo:
			base = Geo.espejado(base)
		base = Geo.transformado(base, carta.rotacion_figura)
		for otra in firmas.values():
			if carta.figura == otra["figura"] and carta.forma == otra["forma"] and Geo.diferencia(base, otra["poligono"]) < 0.04:
				print("        sombras iguales: %s y %s" % [carta.id_pareja, otra["id"]])
				return false
		firmas[carta.id_pareja] = {"poligono": base, "figura": carta.figura, "forma": carta.forma, "id": carta.id_pareja}
	return true


func Figura_poligono(nombre: String) -> PackedVector2Array:
	var Figura := load("res://scripts/ui/figura_vectorial.gd")
	return Figura.poligono(nombre, Vector2.ZERO, 50.0)


# ---------------------------------------------------------------------------
# Mapa del planeta
# ---------------------------------------------------------------------------

func _probar_mapa() -> void:
	print("-- mapa del Planeta Arcoiris (ruta de Sofia) --")
	var progreso := get_root().get_node_or_null("/root/Progreso")
	var previo: String = progreso.perfil_seleccionado if progreso != null else ""
	if progreso != null:
		progreso.perfil_seleccionado = "sofia"
	var escena: PackedScene = load("res://escenas/planetas/arcoiris/mapa_arcoiris.tscn")
	var Mapa = load("res://scripts/nucleo/mapa_planeta.gd")
	Mapa.todo_abierto = true
	var mapa: Node = escena.instantiate()
	get_root().add_child(mapa)
	await _esperar(0.5)
	var parejas_ok := true
	for zona in mapa.zonas:
		for estacion in zona["estaciones"]:
			if estacion["juego"] in ["formas", "parejas"]:
				parejas_ok = parejas_ok and estacion["jugable"] and estacion["perfil_nivel"] == "estrella"
	_check(parejas_ok, "Sofia tiene Formas y Parejas de Estrella en las 5 zonas")
	mapa.seleccion = 4
	mapa._mostrar_estaciones()
	var dorados := 0
	for tarjeta in mapa._tarjetas:
		var boton: Button = tarjeta.get_meta("dorado")
		dorados += 1 if boton.visible else 0
		if boton.visible:
			_check(boton.size.x >= 96.0, "boton del reto dorado >= 96 px")
	_check(dorados == 2, "la Cima muestra 2 retos dorados (Formas y Parejas) con F4")
	Mapa.todo_abierto = false
	mapa.calcular_estado()
	mapa._mostrar_estaciones()
	var ocultos := true
	for tarjeta in mapa._tarjetas:
		ocultos = ocultos and not tarjeta.get_meta("dorado").visible
	_check(ocultos, "sin 3 estrellitas (y sin F4) el reto dorado no aparece")
	mapa.queue_free()
	if progreso != null:
		progreso.perfil_seleccionado = previo
	await _esperar(0.2)
