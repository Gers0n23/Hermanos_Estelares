extends SceneTree

## Arnes de desarrollo de HE-59 (modo equipo + Parejas en equipo). Verifica, con el guardado de pruebas:
## 1. Progreso v3: migracion v2 -> v3 sin perder nada, equipo activo en memoria, 50 destellos una sola vez
##    por hermano y nivel, record "menos pasos es mejor", estrellitas del boton, batalla -> "¡Juntos!", y que
##    el guardado no tenga datos de pares/aciertos/fallos por hermano (R2).
## 2. GestorTurnos (generico): orden maxi_intercalado y menor_a_mayor, puerta + bloqueo, Maxi no mueve al
##    rival, el rival avanza solo en el paso 2, turno perfecto -> retroceso + resbalon (nunca derrota tras
##    un turno perfecto), racha de 3 sin tope, resbalon_tras_racha, rival_llego y reinicio, jugada automatica.
## 3. Motor emparejar en equipo: layout (cartas >= 110 px con 4 filas, separacion 10 px, hitbox <= y 604,
##    guirnalda a >= 40 px del borde), turno guiado de Maxi, besito de Nicole, partida completa ganada (50 a
##    cada uno, sin marcar la estacion individual), y derrota-gag que conserva los pares formados.
## 4. Seleccion ("¡Juntos!" solo desbloqueado, armar equipo con minimo 2) y mapa del equipo.
##
## El arnes de QA oficial del modo (`qa_test_equipo_parejas.gd`, HE-64) es de `tester-qa`; este es el de dev.
## Uso: godot --headless --path . --script herramientas/qa_test_gestor_turnos.gd

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const NIVEL_Z1 := "res://datos/niveles/arcoiris/zona1_claro/parejas_equipo.json"
const SELECCION := "res://escenas/nucleo/seleccion_personaje.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const PERFILES := {"maxi": "semilla", "nicole": "brote", "sofia": "estrella"}

var _fallos := 0
var _progreso: Node
var _eventos: Array = []


func _initialize() -> void:
	print("=== QA dev HE-59: modo equipo (GestorTurnos + Parejas en equipo) ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	# El arbol recien queda activo despues del primer cuadro (si no, los nodos agregados no tienen arbol).
	await process_frame
	_probar_progreso()
	await _probar_gestor()
	await _probar_motor_layout()
	await _probar_motor_partida()
	await _probar_motor_derrota()
	await _probar_seleccion()
	await _probar_mapa_equipo()
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
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


## Espera hasta que `condicion` sea true (o `maximo` s). Devuelve si se cumplio.
func _esperar_que(condicion: Callable, maximo := 8.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _ids(lista: Array) -> Array[String]:
	var r: Array[String] = []
	for x in lista:
		r.append(str(x))
	return r


# ---------------------------------------------------------------------------
# 1. Progreso
# ---------------------------------------------------------------------------

func _probar_progreso() -> void:
	print("-- 1. Progreso v3 --")
	_check(_progreso.VERSION_ACTUAL == 3, "version actual del guardado = 3")
	var v2 := {"version": 2, "recuerdos_encontrados": {"r1": {"visto": true}}, "perfiles": {
		"maxi": {"id": "maxi", "perfil_dificultad": "semilla", "destellos_totales": 120,
			"planetas": {"arcoiris": {"destellos": 120, "niveles": {"n1": {"completado": true, "estrellitas": 0}}}}}}}
	var migrado: Dictionary = _progreso._migrar_datos(v2.duplicate(true))
	_check(int(migrado.get("version", 0)) == 3, "v2 -> v3 sube la version")
	_check(migrado.get("equipo", null) is Dictionary and migrado["equipo"].has("cinematicas_vistas"), "v2 -> v3 agrega el bloque equipo")
	var planeta: Dictionary = migrado["perfiles"]["maxi"]["planetas"]["arcoiris"]
	_check(int(planeta["destellos"]) == 120 and planeta["niveles"].has("n1"), "v2 -> v3 conserva destellos y niveles")
	_check(planeta.get("equipo_premiado", null) is Array and planeta.get("coleccion", null) is Array, "v2 -> v3 agrega equipo_premiado y coleccion")
	_check(migrado["recuerdos_encontrados"].has("r1"), "v2 -> v3 conserva los recuerdos")

	_progreso.fijar_equipo(_ids(["sofia", "maxi"]))
	_check(_progreso.equipo_activo == _ids(["maxi", "sofia"]), "fijar_equipo ordena (maxi+sofia)")
	_progreso.fijar_equipo(_ids(["maxi"]))
	_check(_progreso.equipo_activo == _ids(["maxi", "sofia"]), "fijar_equipo rechaza un equipo de 1")
	_progreso.limpiar_equipo()
	_check(_progreso.equipo_activo.is_empty(), "limpiar_equipo vacia el equipo")
	_check(_progreso.clave_equipo(["sofia", "nicole", "maxi"]) == "maxi+nicole+sofia", "clave_equipo alfabetica")

	var antes := {}
	for id in PERFILES:
		antes[id] = _progreso.obtener_destellos_totales(id)
	var r1: Dictionary = _progreso.registrar_victoria_equipo("arcoiris", "nivel_eq", _ids(["maxi", "nicole"]), 50, 4)
	_check(r1["premiados"].size() == 2 and r1["primer_record"] and r1["primera_victoria_nivel"], "1.a victoria: premia a los dos, primer record, primera del nivel")
	_check(_progreso.obtener_destellos_totales("maxi") == antes["maxi"] + 50 and _progreso.obtener_destellos_totales("nicole") == antes["nicole"] + 50, "+50 a cada uno")
	var r2: Dictionary = _progreso.registrar_victoria_equipo("arcoiris", "nivel_eq", _ids(["maxi", "nicole"]), 50, 5)
	_check(r2["premiados"].is_empty() and not r2["record_nuevo"], "2.a victoria igual: nadie cobra; 5 pasos no es record")
	var r3: Dictionary = _progreso.registrar_victoria_equipo("arcoiris", "nivel_eq", _ids(["maxi", "nicole", "sofia"]), 50, 3)
	_check(r3["premiados"] == _ids(["sofia"]), "con otro equipo solo cobra quien no habia cobrado")
	_check(_progreso.obtener_record_equipo("arcoiris", "nivel_eq", "maxi+nicole") == 4, "record por combinacion: menos es mejor")
	_check(_progreso.contar_niveles_equipo_ganados("arcoiris") == 1, "estrellitas del boton = niveles de equipo ganados")
	_check(not _progreso.esta_nivel_completado("maxi", "arcoiris", "nivel_eq"), "la victoria en equipo NO marca el nivel individual")
	_check(not _progreso.modo_equipo_desbloqueado(), "\"¡Juntos!\" bloqueado antes de la batalla")
	var premiados: Array = _progreso.registrar_batalla_ganada("arcoiris_batalla_final", "arcoiris", _ids(["maxi", "nicole", "sofia"]), 100)
	_check(premiados.size() == 3 and _progreso.batalla_ganada("arcoiris_batalla_final"), "batalla ganada paga a los tres")
	_check(_progreso.registrar_batalla_ganada("arcoiris_batalla_final", "arcoiris", _ids(["maxi", "nicole", "sofia"]), 100).is_empty(), "la batalla paga una sola vez")
	_check(_progreso.modo_equipo_desbloqueado(), "\"¡Juntos!\" desbloqueado al ganar la batalla")
	var texto := JSON.stringify(_progreso._datos)
	_check(not ("\"pares\"" in texto or "\"aciertos\"" in texto or "\"fallos\"" in texto), "el guardado no tiene pares/aciertos/fallos por hermano (R2)")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()


# ---------------------------------------------------------------------------
# 2. GestorTurnos
# ---------------------------------------------------------------------------

func _crear_gestor(ids: Array, topes: Dictionary, pasos := 5, extra := {}) -> GestorTurnos:
	var motor := Node2D.new()
	get_root().add_child(motor)
	var capa := CanvasLayer.new()
	motor.add_child(capa)
	var ui := Control.new()
	capa.add_child(ui)
	var gestor := GestorTurnos.new()
	gestor.escala_tiempo = 0.02
	motor.add_child(gestor)
	var config := {"orden": "maxi_intercalado", "puerta_tras_semilla": "arrastre", "bloqueo_tras_puerta_ms": 400,
		"ms_volteo_equipo": 1500, "maxi_mueve_rival": false, "racha_retrocede_rival": 3, "semilla_auto_s": 20,
		"pasos_rival": pasos, "aciertos_max_turno": topes, "aciertos_totales": 12}
	config.merge(extra, true)
	var perfiles := {}
	for id in ids:
		perfiles[id] = PERFILES[id]
	gestor.configurar(_ids(ids), config, perfiles, ui)
	_eventos.clear()
	gestor.rival_movido.connect(func(p: int) -> void: _eventos.append("movido:%d" % p))
	gestor.rival_resbalo.connect(func() -> void: _eventos.append("resbalo"))
	gestor.rival_llego.connect(func() -> void: _eventos.append("llego"))
	gestor.tope_alcanzado.connect(func() -> void: _eventos.append("tope"))
	gestor.turno_iniciado.connect(func(id: String, _p: String) -> void: _eventos.append("turno:" + id))
	gestor.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: _eventos.append("cerrado:%s:%s" % [id, perfecto]))
	gestor.jugada_automatica_pedida.connect(func() -> void: _eventos.append("auto"))
	return gestor


## Abre la puerta en cuanto aparece y espera el turno de `id`.
func _abrir_y_esperar_turno(g: GestorTurnos, id: String) -> bool:
	var ok := await _esperar_que(func() -> bool: return g.en_puerta(), 6.0)
	if not ok:
		return false
	g.abrir_puerta()
	return await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada() and g.hermano_actual() == id, 6.0)


func _probar_gestor() -> void:
	print("-- 2. GestorTurnos --")
	var p3 := {"maxi": "semilla", "nicole": "brote", "sofia": "estrella"}
	_check(GestorTurnos.construir_ciclo(_ids(["sofia", "nicole", "maxi"]), p3, "maxi_intercalado") == _ids(["maxi", "nicole", "maxi", "sofia"]), "los tres: M -> N -> M -> S")
	_check(GestorTurnos.construir_ciclo(_ids(["maxi", "nicole"]), p3, "maxi_intercalado") == _ids(["maxi", "nicole"]), "maxi+nicole: M -> N")
	_check(GestorTurnos.construir_ciclo(_ids(["nicole", "sofia"]), p3, "maxi_intercalado") == _ids(["nicole", "sofia"]), "nicole+sofia: N -> S")
	_check(GestorTurnos.construir_ciclo(_ids(["maxi", "nicole", "sofia"]), p3, "menor_a_mayor") == _ids(["maxi", "nicole", "sofia"]), "menor_a_mayor: M -> N -> S")

	var g := _crear_gestor(["maxi", "nicole", "sofia"], {"semilla": 1, "brote": 2, "estrella": 3})
	_check(g.entrada_bloqueada(), "antes de empezar la entrada esta bloqueada")
	g.empezar()
	_check(await _abrir_y_esperar_turno(g, "maxi"), "la partida empieza con Maxi tras su puerta")
	# Maxi: su par cierra el turno por tope 1; no mueve al rival.
	g.notificar_acierto()
	_check("tope" in _eventos and g.entrada_bloqueada(), "Maxi: tope 1 -> tope_alcanzado y entrada bloqueada")
	g.confirmar_turno_estable()
	_check("cerrado:maxi:false" in _eventos, "turno de Maxi cierra con perfecto = false")
	_check(await _esperar_que(func() -> bool: return g.en_puerta(), 6.0), "tras Maxi se abre la puerta de la siguiente")
	_check(g.pasos_usados() == 0 and not ("movido:1" in _eventos), "Maxi nunca mueve al rival")
	_check(g._puerta_arrastre, "tras un turno de Maxi la puerta es de arrastre (B1.2)")
	g.soltar_arrastre(Vector2(640, 364))
	_check(g.en_puerta(), "soltar lejos de la ventanita no abre la puerta")
	_check(await _abrir_y_esperar_turno(g, "nicole"), "abre la puerta de Nicole")
	# Nicole falla: el rival avanza en el paso 2 (no en el momento del fallo).
	g.terminar_turno(true)
	_check(g.pasos_usados() == 0, "el fallo no mueve al rival en el momento (B3)")
	_check(await _esperar_que(func() -> bool: return g.pasos_usados() == 1, 6.0), "el rival salta 1 galleta en el paso 2 del pase")
	_check(await _abrir_y_esperar_turno(g, "maxi"), "despues de Nicole vuelve Maxi (intercalado)")
	g.notificar_acierto()
	g.confirmar_turno_estable()
	_check(await _abrir_y_esperar_turno(g, "sofia"), "despues de Maxi le toca a Sofia")
	# Sofia: turno perfecto (3) -> retrocede a 0 en el 0b y en el pase se resbala.
	_eventos.clear()
	for k in 3:
		g.notificar_acierto()
	_check("tope" in _eventos, "Sofia: el 3.er acierto llega al tope")
	g.confirmar_turno_estable()
	_check("cerrado:sofia:true" in _eventos, "turno perfecto: turno_cerrado con perfecto = true")
	_check(await _esperar_que(func() -> bool: return "resbalo" in _eventos, 6.0), "tras el turno perfecto el rival se resbala en el pase")
	_check(g.pasos_usados() == 0 and "movido:0" in _eventos, "retroceso de 1 -> 0 y el pase no avanza (neto -1)")
	# Rival en la galleta 3 y turno perfecto de Nicole -> queda en 2.
	_check(await _abrir_y_esperar_turno(g, "maxi"), "vuelve Maxi")
	g.notificar_acierto()
	g.confirmar_turno_estable()
	_check(await _abrir_y_esperar_turno(g, "nicole"), "Nicole otra vez")
	g._pos_rival = 3
	_eventos.clear()
	g.notificar_acierto()
	g.notificar_acierto()
	g.confirmar_turno_estable()
	_check(await _esperar_que(func() -> bool: return "resbalo" in _eventos, 6.0) and g.pasos_usados() == 2, "galleta 3 + turno perfecto de Nicole -> 2 y se resbala (sigue en 2)")
	# Turno perfecto con el rival en pasos - 1 nunca termina en derrota.
	_check(await _abrir_y_esperar_turno(g, "maxi"), "Maxi")
	g.notificar_acierto()
	g.confirmar_turno_estable()
	_check(await _abrir_y_esperar_turno(g, "sofia"), "Sofia")
	g._pos_rival = 4
	_eventos.clear()
	for k in 3:
		g.notificar_acierto()
	g.confirmar_turno_estable()
	await _esperar_que(func() -> bool: return g.en_puerta(), 6.0)
	_check(not ("llego" in _eventos) and g.pasos_usados() == 3, "turno perfecto en pasos-1: nunca rival_llego")
	# Fallo con el rival en pasos - 1 -> llega (derrota-gag con el siguiente al centro).
	_check(await _abrir_y_esperar_turno(g, "maxi"), "Maxi")
	g.notificar_acierto()
	g.confirmar_turno_estable()
	_check(await _abrir_y_esperar_turno(g, "nicole"), "Nicole")
	g._pos_rival = 4
	_eventos.clear()
	g.terminar_turno(true)
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos, 6.0), "fallo con el rival en pasos-1 -> rival_llego")
	_check(not g.en_puerta() and g.hermano_actual() == "maxi" and g.entrada_bloqueada(), "tras llegar: el siguiente (Maxi) queda al centro sin puerta y la entrada bloqueada")
	g.reiniciar_rival()
	_check(g.pasos_usados() == 0, "reiniciar_rival -> galleta 0")
	_check(await _abrir_y_esperar_turno(g, "maxi"), "la puerta se abre para el que ya estaba al centro")
	# Jugada automatica de Maxi (20 s sin toque, acelerado).
	_eventos.clear()
	_check(await _esperar_que(func() -> bool: return "auto" in _eventos, 3.0), "semilla_auto_s pide la jugada automatica en el turno de Maxi")
	g.get_parent().queue_free()

	# Sin tope (maxi+sofia): la racha de 3 hace retroceder en el momento y el pase avanza.
	var g2 := _crear_gestor(["maxi", "sofia"], {"semilla": 1}, 5)
	g2.empezar()
	await _abrir_y_esperar_turno(g2, "maxi")
	g2.notificar_acierto()
	g2.confirmar_turno_estable()
	_check(await _abrir_y_esperar_turno(g2, "sofia"), "maxi+sofia: le toca a Sofia")
	g2._pos_rival = 2
	_eventos.clear()
	for k in 3:
		g2.notificar_acierto()
	_check(not ("tope" in _eventos) and g2.pasos_usados() == 1, "sin tope: la racha de 3 hace retroceder en el momento")
	g2.terminar_turno(true)
	_check(await _esperar_que(func() -> bool: return g2.pasos_usados() == 2, 6.0) and not ("resbalo" in _eventos), "sin resbalon_tras_racha el pase avanza +1")
	g2.get_parent().queue_free()

	var g3 := _crear_gestor(["maxi", "sofia"], {"semilla": 1}, 5, {"resbalon_tras_racha": true})
	g3.empezar()
	await _abrir_y_esperar_turno(g3, "maxi")
	g3.notificar_acierto()
	g3.confirmar_turno_estable()
	await _abrir_y_esperar_turno(g3, "sofia")
	g3._pos_rival = 2
	_eventos.clear()
	for k in 6:
		g3.notificar_acierto()
	g3.terminar_turno(true)
	await _esperar_que(func() -> bool: return "resbalo" in _eventos, 6.0)
	_check(g3.pasos_usados() == 0 and _eventos.count("resbalo") == 1, "con resbalon_tras_racha: 2 retrocesos y un solo resbalon (no avanza)")
	g3.get_parent().queue_free()
	await _esperar(0.2)


# ---------------------------------------------------------------------------
# 3. Motor emparejar en equipo
# ---------------------------------------------------------------------------

func _crear_motor(ids: Array, ruta := NIVEL_Z1, planeta := "arcoiris") -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.planeta_id = planeta
	motor.equipo = _ids(ids)
	motor.destellos_fijos = 50
	motor.segundos_auto_continuar = 0.3
	get_root().add_child(motor)
	motor.turnos.escala_tiempo = 0.05
	return motor


func _probar_motor_layout() -> void:
	print("-- 3a. Parejas en equipo: layout por composicion (zona 1) --")
	for ids in [["maxi", "nicole"], ["maxi", "sofia"], ["nicole", "sofia"], ["maxi", "nicole", "sofia"]]:
		var motor := _crear_motor(ids, NIVEL_Z1, "")
		await process_frame
		var clave := "+".join(PackedStringArray(ids))
		var cartas: Array = motor._cartas
		var comp: Dictionary = motor._eq_comp
		_check(cartas.size() == int(comp["cantidad"]) * 2, "%s: %d cartas (%d pares)" % [clave, cartas.size(), int(comp["cantidad"])])
		var lado: float = motor._lado_carta
		var con_maxi: bool = "maxi" in ids
		_check(not con_maxi or lado >= 110.0, "%s: cartas de %.1f px (>= 110 con Maxi)" % [clave, lado])
		if int(comp["filas"]) >= 4:
			_check(is_equal_approx(motor._separacion, 10.0), "%s: separacion 10 px con 4 filas" % clave)
		var abajo := 0.0
		for carta in cartas:
			abajo = maxf(abajo, carta.get_global_rect().end.y)
		_check(abajo <= 604.0, "%s: hitbox de la fila inferior <= y 604 (%.1f)" % [clave, abajo])
		var ancla: Vector2 = motor.ancla_meta_turno()
		_check(ancla.x - 64.0 >= 40.0, "%s: la guirnalda queda a >= 40 px del borde izquierdo (x %.0f)" % [clave, ancla.x - 64.0])
		_check(motor._boton_salir.size.x >= 96.0 and motor._boton_salir.size.y >= 96.0 and motor._boton_salir.position.y + motor._boton_salir.size.y <= 128.0 - 24.0 + 1.0, "%s: casa >= 96 px y a 24 px del tablero" % clave)
		_check(not motor._anfitriona.visible and not motor._barra_progreso.visible, "%s: sin Coco fijo ni barra de pares (R2)" % clave)
		var topes: Dictionary = motor.turnos._topes
		var con_tope: bool = clave in ["maxi+nicole", "maxi+nicole+sofia"]
		_check(int(topes.get("semilla", 0)) == 1 and (topes.has("brote") == (con_tope and "nicole" in ids)), "%s: topes %s" % [clave, topes])
		motor.queue_free()
		await process_frame


func _formar_par(motor: Node, id_pareja: String) -> void:
	for carta in motor._cartas:
		if carta.id_pareja == id_pareja and not carta.esta_acertada and not motor._seleccionadas.has(carta):
			motor._al_tocar_carta(carta)
			if motor._seleccionadas.is_empty():
				return


func _pareja_pendiente(motor: Node) -> String:
	for carta in motor._cartas:
		if not carta.esta_acertada:
			return carta.id_pareja
	return ""


func _dos_distintas(motor: Node) -> Array:
	var primera = null
	for carta in motor._cartas:
		if carta.esta_acertada:
			continue
		if primera == null:
			primera = carta
		elif carta.id_pareja != primera.id_pareja:
			return [primera, carta]
	return []


## Juega el turno actual: Maxi toca su halo; Nicole/Sofia forman pares hasta su tope (o fallan si `fallar`).
func _jugar_turno(motor: Node, fallar := false) -> void:
	var g: GestorTurnos = motor.turnos
	# Abre la puerta en cuanto aparece (el pase puede estar en curso) y espera el turno.
	await _esperar_que(func() -> bool:
		if g.en_puerta():
			g.abrir_puerta()
		return g.turno_activo() and not g.entrada_bloqueada() or motor._eq_victoria or motor.en_derrota_equipo(), 10.0)
	if motor._eq_victoria or motor.en_derrota_equipo():
		return
	var id := g.hermano_actual()
	if g.perfil_actual() == "semilla":
		for carta in motor._eq_halo.duplicate():
			motor._al_tocar_carta(carta)
		return
	if fallar:
		for vez in (2 if g.perfil_actual() == "brote" else 1):
			var par := _dos_distintas(motor)
			if par.is_empty():
				return
			motor._al_tocar_carta(par[0])
			motor._al_tocar_carta(par[1])
			await _esperar(0.05)
		return
	var tope := g.tope_de(g.perfil_actual())
	var n := tope if tope > 0 else 3
	for k in n:
		var pareja := _pareja_pendiente(motor)
		if pareja == "" or not g.turno_activo() or g.entrada_bloqueada():
			break
		_formar_par(motor, pareja)
		await process_frame
	if tope <= 0 and g.turno_activo() and not g.entrada_bloqueada():
		var par := _dos_distintas(motor)
		if not par.is_empty():
			motor._al_tocar_carta(par[0])
			motor._al_tocar_carta(par[1])
	await _esperar_que(func() -> bool: return g.hermano_actual() != id or motor._eq_victoria or motor.en_derrota_equipo(), 10.0)


func _probar_motor_partida() -> void:
	print("-- 3b. Parejas en equipo: partida completa de los tres --")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	var antes := {}
	for id in PERFILES:
		antes[id] = _progreso.obtener_destellos_totales(id)
	var motor := _crear_motor(["maxi", "nicole", "sofia"])
	var completado := [false]
	motor.completado.connect(func(_d: int) -> void: completado[0] = true)
	var g: GestorTurnos = motor.turnos
	_check(await _esperar_que(func() -> bool: return g.en_puerta(), 15.0), "tras la intro y el vistazo se abre la puerta del primer turno")
	_check(g.hermano_actual() == "maxi", "empieza Maxi")
	# Durante la puerta las cartas solo hacen el pulso.
	var primera: CartaEmparejar = motor._cartas[0]
	motor._al_tocar_carta(primera)
	_check(not primera.mostrando, "con la puerta cerrada una carta no se da vuelta (B1.4)")
	g.abrir_puerta()
	await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada(), 5.0)
	_check(motor._eq_halo.size() == 2, "turno de Maxi: dos cartas con halo dorado")
	# Toque fuera del halo: se ve y se tapa sola; su turno no termina.
	var fuera: CartaEmparejar = null
	for carta in motor._cartas:
		if not carta in motor._eq_halo:
			fuera = carta
			break
	motor._al_tocar_carta(fuera)
	_check(fuera.mostrando and g.turno_activo(), "Maxi: carta sin halo se da vuelta y el turno sigue")
	await _esperar(0.9)
	_check(not fuera.mostrando, "Maxi: la carta sin halo se tapa sola a los 700 ms")
	var pares_antes: int = motor._pares_acertados
	for carta in motor._eq_halo.duplicate():
		motor._al_tocar_carta(carta)
	_check(motor._pares_acertados == pares_antes + 1, "Maxi siempre aporta un par (R5)")
	await _esperar_que(func() -> bool: return g.en_puerta(), 8.0)
	_check(g.pasos_usados() == 0 and g.hermano_actual() == "nicole", "tras Maxi: rival quieto y le toca a Nicole")
	g.abrir_puerta()
	await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada(), 5.0)
	# Besito de Coco: el primer fallo de Nicole no corta el turno.
	var par := _dos_distintas(motor)
	motor._al_tocar_carta(par[0])
	motor._al_tocar_carta(par[1])
	_check(g.turno_activo() and not g.entrada_bloqueada(), "Nicole: el primer \"no es este\" no termina el turno (besito)")
	await _esperar(0.1)
	# ... y si despues forma sus 2 pares, es turno perfecto.
	_eventos.clear()
	g.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: _eventos.append("cerrado:%s:%s" % [id, perfecto]))
	_formar_par(motor, _pareja_pendiente(motor))
	_formar_par(motor, _pareja_pendiente(motor))
	_check(await _esperar_que(func() -> bool: return "cerrado:nicole:true" in _eventos, 5.0), "besito + 2 pares = turno perfecto de Nicole")
	# Se juega hasta ganar (turnos perfectos).
	var vueltas := 0
	while not motor._eq_victoria and vueltas < 40:
		vueltas += 1
		await _jugar_turno(motor)
	_check(motor._eq_victoria, "el equipo gana la partida (%d turnos jugados)" % vueltas)
	_check(_progreso.nivel_equipo_ganado("arcoiris", "arcoiris_z1_parejas_equipo"), "el nivel de equipo queda ganado (estrellita del boton)")
	var bien := true
	for id in PERFILES:
		bien = bien and _progreso.obtener_destellos_totales(id) == antes[id] + 50
	_check(bien, "50 destellos a cada hermano, guardados en el instante de ganar")
	_check(not _progreso.esta_nivel_completado("maxi", "arcoiris", "arcoiris_z1_parejas_equipo") and not _progreso.esta_nivel_completado("nicole", "arcoiris", "arcoiris_parejas_brote_z1"), "no se marca ninguna estacion individual")
	_check(_progreso.obtener_record_equipo("arcoiris", "arcoiris_z1_parejas_equipo", "maxi+nicole+sofia") >= 0, "queda el record de pasos del equipo")
	_check(await _esperar_que(func() -> bool: return completado[0], 25.0), "tras la fiesta multihermano se emite completado")
	motor.queue_free()
	await process_frame


func _probar_motor_derrota() -> void:
	print("-- 3c. Parejas en equipo: derrota-gag que conserva lo logrado --")
	var motor := _crear_motor(["nicole", "sofia"], NIVEL_Z1, "")
	var g: GestorTurnos = motor.turnos
	await _esperar_que(func() -> bool: return g.en_puerta(), 15.0)
	await _jugar_turno(motor)  # Nicole forma pares (sin tope: 3 y despues falla)
	var conservados: int = motor._pares_acertados
	_check(conservados >= 1, "antes de perder el equipo ya formo %d pares" % conservados)
	var vueltas := 0
	while not motor.en_derrota_equipo() and vueltas < 30:
		vueltas += 1
		await _jugar_turno(motor, true)
	_check(motor.en_derrota_equipo(), "el rival llega a la mesa tras %d turnos fallados (derrota-gag)" % vueltas)
	_check(motor._boton_otra_vez_equipo != null and motor._boton_otra_vez_equipo.visible and motor._boton_otra_vez_equipo.size.x >= 160.0, "\"¡otra vez!\" >= 160 px desde el segundo 0")
	await _esperar(0.4)
	motor.tocar_otra_vez_equipo()  # a mitad del gag
	_check(motor._pares_acertados == conservados, "\"¡otra vez!\" a mitad del gag conserva los %d pares" % conservados)
	var visibles := true
	for carta in motor._cartas:
		visibles = visibles and carta.visible and is_equal_approx(carta.scale.x, 1.0)
	_check(visibles, "todas las cartas vuelven a la mesa al instante")
	_check(await _esperar_que(func() -> bool: return g.en_puerta(), 12.0) and g.pasos_usados() == 0, "rival en 0 y se abre la puerta del que estaba al centro")
	motor.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4. Seleccion y mapa del equipo
# ---------------------------------------------------------------------------

func _probar_seleccion() -> void:
	print("-- 4a. Seleccion: \"¡Juntos!\" y armar equipo --")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	var recuerdos := get_root().get_node_or_null("Recuerdos")
	if recuerdos != null:
		recuerdos.desbloquear({"tipo": "primera_apertura"}, "")
	change_scene_to_file(SELECCION)
	await process_frame
	await process_frame
	var sel := current_scene
	_check(sel._nave == null or not sel._nave.visible, "antes de ganar la batalla no hay \"¡Juntos!\" (seleccion de siempre)")
	sel.tocar_en(sel.RECT_JUNTOS.get_center())
	_check(not sel._armando, "tocar donde iria la nave no hace nada sin el modo")
	_progreso.registrar_batalla_ganada("arcoiris_batalla_final", "arcoiris", _ids(["maxi", "nicole", "sofia"]), 0)
	_progreso.marcar_modo_equipo_presentado()
	change_scene_to_file(SELECCION)
	await process_frame
	await process_frame
	sel = current_scene
	_check(sel._nave != null and sel._nave.visible, "con la batalla ganada aparece \"¡Juntos!\"")
	_check(sel.RECT_JUNTOS.size.x >= 96.0 and sel.RECT_JUNTOS.size.y >= 96.0, "\"¡Juntos!\" >= 96 px")
	sel.tocar_en(sel.RECT_JUNTOS.get_center())
	_check(sel._armando and not sel._boton_album.visible, "tocar la nave entra a armar equipo y oculta el album")
	_check(sel.equipo_armado() == _ids(["maxi", "nicole", "sofia"]), "las tres tarjetas parten adentro")
	var centro_nicole: Vector2 = Rect2(sel.get_node("tarjeta_nicole").global_position, sel.get_node("tarjeta_nicole").size).get_center()
	var centro_maxi: Vector2 = Rect2(sel.get_node("tarjeta_maxi").global_position, sel.get_node("tarjeta_maxi").size).get_center()
	sel.tocar_en(centro_nicole)
	_check(sel.equipo_armado() == _ids(["maxi", "sofia"]), "tocar a Nicole la manda al puf")
	_check(sel.get_node("tarjeta_nicole").modulate.r < 0.7 and sel.get_node("tarjeta_nicole").modulate.a == 1.0, "en el puf queda al 60 % de brillo (nunca gris ni transparente)")
	sel.tocar_en(centro_maxi)
	_check(sel.equipo_armado() == _ids(["maxi", "sofia"]), "minimo dos: Maxi no puede salir si quedan dos")
	sel.tocar_en(centro_nicole)
	_check(sel.equipo_armado() == _ids(["maxi", "nicole", "sofia"]), "Nicole vuelve a la nave")
	sel.tocar_en(Rect2(sel.get_node("boton_volver").global_position, sel.get_node("boton_volver").size).get_center())
	_check(not sel._armando and sel._boton_album.visible and _progreso.equipo_activo.is_empty(), "la flecha sale de armar equipo y el equipo queda vacio")
	sel.tocar_en(sel.RECT_JUNTOS.get_center())
	sel.tocar_en(centro_maxi)
	sel.tocar_en(sel.RECT_JUNTOS.get_center())
	_check(_progreso.equipo_activo == _ids(["nicole", "sofia"]), "\"¡Despegar!\" fija el equipo (nicole+sofia)")
	_check(await _esperar_que(func() -> bool: return current_scene != null and current_scene.scene_file_path == ARCOIRIS, 4.0), "\"¡Despegar!\" lleva al mapa de Arcoiris")


func _probar_mapa_equipo() -> void:
	print("-- 4b. Mapa del equipo --")
	_progreso.fijar_equipo(_ids(["maxi", "nicole", "sofia"]))
	change_scene_to_file(ARCOIRIS)
	await process_frame
	await process_frame
	var mapa := current_scene
	_check(mapa.modo_equipo, "el mapa entra en modo equipo")
	var todas := true
	var solo_parejas := true
	for zona in mapa.zonas:
		todas = todas and zona["abierta"]
		for estacion in zona["estaciones"]:
			solo_parejas = solo_parejas and (estacion["jugable"] == (estacion["juego"] == "parejas"))
	_check(todas, "todas las zonas abiertas (incluida la secreta)")
	_check(solo_parejas, "solo despiertan las estaciones con nivel_equipo (Parejas)")
	var j := -1
	for k in mapa.zonas[0]["estaciones"].size():
		if mapa.zonas[0]["estaciones"][k]["juego"] == "parejas":
			j = k
	mapa.lanzar_estacion(0, j, 0.01)
	_check(await _esperar_que(func() -> bool: return current_scene != null and "turnos" in current_scene and current_scene.equipo.size() == 3, 4.0), "la estacion abre el motor con el equipo")
	var motor := current_scene
	_check(motor.id_perfil == "" and motor.destellos_fijos == 50 and motor.turnos != null, "el motor recibe id_perfil vacio, 50 destellos por hermano y crea su GestorTurnos")
	motor.salir_solicitado.emit()
	await _esperar_que(func() -> bool: return current_scene != null and current_scene.scene_file_path == ARCOIRIS, 4.0)
	_check(current_scene.modo_equipo, "salir vuelve al mapa del equipo (sin perder nada)")
	current_scene._volver_al_mapa_estelar()
	_check(await _esperar_que(func() -> bool: return current_scene != null and current_scene.scene_file_path == SELECCION, 4.0) and _progreso.equipo_activo.is_empty(), "la flecha del mapa del equipo vuelve a la seleccion y vacia el equipo")
