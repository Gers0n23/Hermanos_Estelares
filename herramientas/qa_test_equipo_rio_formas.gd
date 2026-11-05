extends SceneTree

## Arnes de desarrollo de HE-70: contrato de turnos dentro de `rio` y `encajar` (modo-equipo.md §11.4, §14.3 y
## §14.15). Usa los niveles reales de la batalla, sin `planeta_id` (no escribe en ningun guardado) salvo el
## caso de victoria fuera de la batalla, que usa el guardado de pruebas (aislado) y lo restaura.
## Rio: pausa real con la entrada bloqueada, tope del 70 %, gotas por turno (M 1, N 3, S 3), turno que cierra
##   con el rio quieto, reventon de Maxi (halo, carga del color, toda la pantalla dispara, umbral 2, siempre
##   revienta), jugada automatica, cadena = 2 aciertos, sin textos/HUD, derrota-gag que conserva el rio,
##   parcial y victoria (fiesta del equipo o, en batalla, solo `completado(0)`).
## Formas: capa por perfil en cada turno ("fiu" que endereza o gira), pieza con halo de Maxi y las demas
##   inertes, tope {1, 2, 3} con confirmacion estable y turno perfecto, segunda oportunidad de Nicole, soltar
##   en el vacio no es fallo, fallo que pasa el turno, gag que conserva lo encajado, parcial y victoria.
## Uso: godot --headless --path . --script herramientas/qa_test_equipo_rio_formas.gd

const MOTOR_RIO := "res://escenas/minijuegos/rio/motor_rio.tscn"
const NIVEL_RIO := "res://datos/niveles/arcoiris/batalla/rio_equipo.json"
const MOTOR_FORMAS := "res://escenas/minijuegos/encajar/motor_encajar.tscn"
const NIVEL_FORMAS := "res://datos/niveles/arcoiris/batalla/formas_equipo.json"
const TRES := ["maxi", "nicole", "sofia"]

var _fallos := 0
var _oks := 0
var _eventos: Array = []
var _progreso: Node
var _respaldo := ""


func _initialize() -> void:
	print("=== QA dev HE-70: turnos en el Rio y en Formas ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	if FileAccess.file_exists(_progreso.ruta_guardado):
		_respaldo = FileAccess.get_file_as_string(_progreso.ruta_guardado)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await process_frame
	await _probar_rio()
	await _probar_rio_victoria()
	await _probar_formas()
	await _probar_formas_victoria()
	if _respaldo != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo)
		f.close()
	_progreso.cargar()
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


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


func _instanciar(escena: String, nivel: String, planeta := "", batalla := false) -> Node:
	var motor: Node = load(escena).instantiate()
	motor.ruta_nivel = nivel
	motor.planeta_id = planeta
	motor.equipo = _ids(TRES)
	motor.en_batalla = batalla
	motor.segundos_auto_continuar = 0.3
	if motor.has_method("fijar_semilla"):
		motor.fijar_semilla(5)
	get_root().add_child(motor)
	motor.turnos.escala_tiempo = 0.05
	_eventos.clear()
	motor.turnos.turno_iniciado.connect(func(id: String, _p: String) -> void: _eventos.append("turno:" + id))
	motor.turnos.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: _eventos.append("cerrado:%s:%s" % [id, perfecto]))
	motor.turnos.rival_llego.connect(func() -> void: _eventos.append("llego"))
	motor.turnos.tope_alcanzado.connect(func() -> void: _eventos.append("tope"))
	return motor


func _abrir_turno(motor: Node, id: String) -> bool:
	var g: GestorTurnos = motor.turnos
	if not await _esperar_que(func() -> bool: return g.en_puerta(), 10.0):
		return false
	g.abrir_puerta()
	return await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada() and g.hermano_actual() == id, 6.0)


## Rio a mano (cabeza -> cola), todas pegadas y a la vista, con la cabeza en `fraccion` del recorrido.
func _armar_rio(motor: Node, colores: Array, fraccion := 0.45) -> void:
	var logica: LogicaRio = motor.logica
	logica.gotas.clear()
	logica.balas.clear()
	var s0: float = logica.recorrido.largo * fraccion
	for i in colores.size():
		logica.gotas.append({"s": s0 - i * logica.diametro(), "color": colores[i], "id": 900 + i, "ot": 0.0, "origen": Vector2.ZERO})
	logica.entrando = false
	logica.espera = 0.0


# ---------------------------------------------------------------------------
# Rio
# ---------------------------------------------------------------------------

func _probar_rio() -> void:
	print("-- Rio en equipo --")
	var motor := _instanciar(MOTOR_RIO, NIVEL_RIO)
	var logica: LogicaRio = motor.logica
	var g: GestorTurnos = motor.turnos
	_check(g != null and not g.sin_pista(), "el Rio arma el gestor con la pista de galletas")
	_check(is_equal_approx(logica.tope_cabeza, 0.7), "tope_avance 0.7 -> la cabeza nunca pasa el 70 %")
	_check(motor._boton_salir.get_rect() == Rect2(1172, 8, 100, 96), "la casa queda arriba a la derecha (100 x 96)")
	_check(g.pasos_rival() == 7, "pasos_rival de la composicion de los tres (7)")
	var s0: float = logica.gotas[0]["s"]
	await _esperar(0.3)
	_check(is_equal_approx(logica.gotas[0]["s"], s0), "antes de la primera puerta (entrada bloqueada) el rio esta quieto")
	_check(await _abrir_turno(motor, "maxi"), "empieza Maxi tras su puerta")
	_armar_rio(motor, ["rojo", "azul", "amarillo", "rosa", "azul"])
	motor.aplicar_perfil_turno("semilla")
	_check(motor._eq_objetivo == [900], "objetivo de Maxi: con empate, el tramo mas cercano a la cabeza (%s)" % str(motor._eq_objetivo))
	_check(logica.actual == "rojo", "Coco carga el color exacto del objetivo")
	var mano: String = logica.siguiente
	motor.intercambiar()
	_check(logica.actual == "rojo" and logica.siguiente == mano, "en el turno de Maxi no hay intercambio")
	_armar_rio(motor, ["rojo", "azul", "azul", "amarillo", "rosa"])
	motor.aplicar_perfil_turno("semilla")
	_check(motor._eq_objetivo == [901, 902], "objetivo: el tramo visible mas largo (azul de 2)")
	_armar_rio(motor, ["rojo", "azul", "amarillo", "rosa", "azul"])
	motor.aplicar_perfil_turno("semilla")
	var antes := logica.gotas.size()
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = motor.recorrido.centro
	motor._al_input_juego(ev)
	_check(not motor._eq_bala_maxi.is_empty(), "toda la pantalla dispara, tambien un toque sobre Coco")
	_check(await _esperar_que(func() -> bool: return logica.gotas.size() == antes - 1, 3.0), "la bala de Maxi revienta su tramo de 1 (umbral 2): %d -> %d gotas" % [antes, logica.gotas.size()])
	_check(motor._textos.is_empty(), "en equipo no aparece ningun texto (+N, cadena, combo)")
	_check(await _esperar_que(func() -> bool: return "cerrado:maxi:false" in _eventos, 4.0), "con su 1 gota gastada y el rio quieto, el turno de Maxi cierra")
	_check(await _esperar_que(func() -> bool: return g.entrada_bloqueada(), 2.0), "en el pase la entrada esta bloqueada")
	var s_pase: float = logica.gotas[0]["s"]
	await _esperar(0.3)
	_check(is_equal_approx(logica.gotas[0]["s"], s_pase), "rio_se_detiene_en_pase: en el pase el rio no avanza")
	_check(await _abrir_turno(motor, "nicole"), "le toca a Nicole")
	_check(motor._guia == "completa" and motor._eq_limite == 3, "Nicole: guia completa y 3 gotas por turno")
	var disparadas := 0
	for k in 4:
		motor.apuntar_a(Vector2(1200, 150))
		if motor.disparar():
			disparadas += 1
		logica.espera = 0.0
		await _esperar(0.05)
	_check(disparadas == 3, "Nicole dispara 3 gotas y la 4.a no sale (%d)" % disparadas)
	var aciertos_antes: int = g._aciertos_turno
	motor._reventon_equipo(3, "azul", true)
	_check(g._aciertos_turno - aciertos_antes == 2, "una cadena vale 2 aciertos de racha (cadena_vale_aciertos)")
	motor._reventon_equipo(3, "azul", false)
	_check(g._aciertos_turno - aciertos_antes == 3, "un reventon directo vale 1")
	_check(await _esperar_que(func() -> bool: return "cerrado:nicole:false" in _eventos, 6.0), "sin balas en vuelo, el turno de Nicole cierra (sin fallo)")
	_check(await _abrir_turno(motor, "maxi"), "despues de Nicole, Maxi")
	_armar_rio(motor, ["azul", "rojo", "rojo", "amarillo"])
	motor.aplicar_perfil_turno("semilla")
	antes = logica.gotas.size()
	motor._jugada_automatica_equipo()
	_check(not motor._eq_bala_maxi.is_empty(), "jugada automatica (M2): la gota de Maxi sale sola")
	_check(await _esperar_que(func() -> bool: return logica.gotas.size() == antes - 2, 3.0), "y revienta el tramo con halo (2 + 1)")
	_check(await _abrir_turno(motor, "sofia"), "le toca a Sofia")
	_check(motor._guia == "no", "Sofia juega sin guia (guia_por_perfil)")
	# Tope del 70 %: con la cabeza en el tope la cola no avanza mas.
	_armar_rio(motor, ["rojo", "azul", "amarillo", "rosa"], 0.69)
	await _esperar(1.5)
	_check(logica.gotas[0]["s"] <= logica.recorrido.largo * 0.7 + logica.diametro(), "la cabeza se frena en el 70 %% (%.0f de %.0f)" % [logica.gotas[0]["s"], logica.recorrido.largo])
	_check(logica.estado == "jugando", "nunca empieza a tragar (sin derrota propia)")
	# Derrota-gag: rival en pasos - 1 y el turno de Sofia cierra -> llega.
	g._pos_rival = g.pasos_rival() - 1
	var colores_antes := logica.colores_en_orden()
	motor._eq_disparos = motor._eq_limite
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos, 6.0), "el rival llega en el pase -> derrota-gag de la base")
	_check(await _esperar_que(func() -> bool: return motor._eq_gag.get("fase", "") == "oculto" or motor._eq_gag.get("fase", "") == "devolver", 4.0), "las gotas vuelan a la mochila")
	_check(await _esperar_que(func() -> bool: return motor._gag_terminado, 6.0) and motor._eq_gag.is_empty(), "y vuelven al cauce")
	_check(logica.colores_en_orden() == colores_antes, "el gag no toca el rio (mismas gotas, mismo orden)")
	_check(motor.contar_logro_equipo() > 0, "logro comun: gotas reventadas en la ronda (%d)" % motor.contar_logro_equipo())
	motor.tocar_otra_vez_equipo()
	_check(await _esperar_que(func() -> bool: return g.en_puerta() and g.pasos_usados() == 0, 6.0), "\"¡otra vez!\": rival a 0 y la puerta del que estaba al centro")
	# Parcial y restauracion.
	var parcial: Dictionary = motor.obtener_parcial_equipo()
	_check(parcial.get("gotas", []) == logica.colores_en_orden(), "parcial: las gotas que quedan, en su orden")
	motor.queue_free()
	await process_frame
	var otro := _instanciar(MOTOR_RIO, NIVEL_RIO)
	otro.restaurar_parcial_equipo(parcial)
	_check(otro.logica.colores_en_orden() == parcial["gotas"] and otro._eq_restaurado, "restaurar_parcial_equipo vuelve con el mismo rio")
	_check(await _abrir_turno(otro, "maxi"), "al retomar empieza Maxi (empezar_retomando)")
	otro.queue_free()
	await process_frame


func _probar_rio_victoria() -> void:
	print("-- Rio en equipo: victoria --")
	# En la batalla: solo completado(0), sin registrar nada.
	var motor := _instanciar(MOTOR_RIO, NIVEL_RIO, "arcoiris", true)
	var destellos := [-1]
	motor.completado.connect(func(d: int) -> void: destellos[0] = d)
	await _abrir_turno(motor, "maxi")
	motor.logica.gotas.clear()
	_check(await _esperar_que(func() -> bool: return destellos[0] >= 0, 5.0) and destellos[0] == 0, "en batalla, vaciar el rio emite completado(0)")
	_check(_progreso.contar_niveles_equipo_ganados("arcoiris") == 0 and _progreso.obtener_destellos_totales("maxi") == 0, "en batalla no se registra victoria de equipo ni destellos")
	motor.queue_free()
	await process_frame
	# Fuera de la batalla: fiesta del equipo y 50 destellos a cada uno.
	var libre := _instanciar(MOTOR_RIO, NIVEL_RIO, "arcoiris", false)
	var d2 := [-1]
	libre.completado.connect(func(d: int) -> void: d2[0] = d)
	await _abrir_turno(libre, "maxi")
	libre.logica.gotas.clear()
	_check(await _esperar_que(func() -> bool: return d2[0] >= 0, 15.0), "fuera de la batalla: fiesta del equipo y completado (%d)" % d2[0])
	_check(_progreso.obtener_destellos_totales("nicole") == 50 and not _progreso.esta_nivel_completado("nicole", "arcoiris", "arcoiris_batalla_rio_equipo"), "50 destellos a cada uno, sin marcar la estacion individual")
	libre.queue_free()
	await process_frame
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()


# ---------------------------------------------------------------------------
# Formas
# ---------------------------------------------------------------------------

func _hueco_libre_de(motor: Node, pieza: PiezaEncajar) -> Variant:
	return motor._hueco_de(pieza)


## Un hueco libre de OTRO color que la pieza (con exigir_color no calza nunca).
func _hueco_ajeno(motor: Node, pieza: PiezaEncajar) -> Variant:
	for hueco in motor._huecos:
		if hueco["pieza"] == null and not (hueco["color"] as Color).is_equal_approx(pieza.color):
			return hueco
	return null


func _pieza_bandeja(motor: Node, excepto = null) -> PiezaEncajar:
	for pieza in motor._en_bandeja():
		if pieza != excepto and motor._hueco_de(pieza) != null and motor._hueco_de(pieza)["pieza"] == null:
			return pieza
	return null


## Encaja `pieza` como la soltaria un dedo, ya girada a su lugar.
func _encajar_bien(motor: Node, pieza: PiezaEncajar) -> String:
	var hueco = motor._hueco_de(pieza)
	pieza.rotacion_grados = float(hueco["rotacion"])
	pieza.rotation = deg_to_rad(pieza.rotacion_grados)
	return motor.soltar_pieza(pieza, hueco["centro"])


func _probar_formas() -> void:
	print("-- Formas en equipo --")
	var motor := _instanciar(MOTOR_FORMAS, NIVEL_FORMAS)
	var g: GestorTurnos = motor.turnos
	await _esperar(0.2)
	_check(not motor._anfitriona.visible and not motor._barra_progreso.visible and not motor._boton_cometa.visible, "sin Coco fijo, barra de piezas ni Cometa propio (Cometa vive en la pista)")
	_check(motor._boton_salir.get_rect() == Rect2(1172, 8, 100, 96), "la casa queda arriba a la derecha")
	_check(motor.ancla_meta_turno() == Vector2(134, 356), "la guirnalda va 16 px a la izquierda de zona_figuras (%s)" % motor.ancla_meta_turno())
	_check(motor._requeridos == 12 and g._aciertos_totales == 12, "12 piezas y la cinta cuenta 12 aciertos")
	var una := _pieza_bandeja(motor)
	motor._al_tocar_pieza(una)
	_check(not una.colocada, "antes de abrir la puerta las piezas solo hacen el pulso")
	_check(await _abrir_turno(motor, "maxi"), "empieza Maxi")
	var objetivo: PiezaEncajar = motor._eq_pieza_objetivo
	_check(objetivo != null, "Maxi: una pieza con halo (la mas grande de la bandeja)")
	var mas_grande := true
	for p in motor._en_bandeja():
		if p.ancho * p.alto > objetivo.ancho * objetivo.alto and motor._hueco_de(p) != null:
			mas_grande = false
	_check(mas_grande and motor._siluetas.hueco_objetivo == motor._hueco_de(objetivo), "es la mas grande y su hueco respira")
	var otra := _pieza_bandeja(motor, objetivo)
	motor._al_tocar_pieza(otra)
	_check(not otra.colocada, "las otras piezas son inertes en el turno de Maxi")
	motor._al_tocar_pieza(objetivo)
	_check(objetivo.colocada, "toque_lleva_a_casa: un toque y la pieza vuela a su lugar")
	_check("tope" in _eventos, "tope 1 de Maxi")
	_check(await _esperar_que(func() -> bool: return "cerrado:maxi:false" in _eventos, 4.0), "el motor confirma con la mesa quieta y el turno cierra")
	_check(await _abrir_turno(motor, "nicole"), "le toca a Nicole")
	await _esperar(0.45)
	var derechas := true
	for p in motor._en_bandeja():
		var h = motor._hueco_de(p)
		if h != null and not is_equal_approx(wrapf(float(h["rotacion"]), 0.0, 360.0), p.rotacion_grados):
			derechas = false
	_check(derechas, "Nicole: las piezas se enderezan (fiu) al empezar su turno")
	_check(not motor._rotacion_por_toque and not motor._sin_error, "Nicole: sin rotacion por toque y con error")
	var vacio := _pieza_bandeja(motor)
	_check(motor.soltar_pieza(vacio, Vector2(640, 700)) == "nada" and g.turno_activo(), "soltar en el vacio no es fallo: el turno sigue")
	var fallada := _pieza_bandeja(motor)
	var ajeno = _hueco_ajeno(motor, fallada)
	_check(motor.soltar_pieza(fallada, ajeno["centro"]) == "no_es_este", "una pieza en un hueco equivocado es fallo")
	await _esperar(0.6)
	_check(g.turno_activo() and not ("cerrado:nicole:false" in _eventos), "segunda oportunidad de Nicole: su primer fallo no corta el turno")
	_check(_encajar_bien(motor, _pieza_bandeja(motor)) == "encajo", "Nicole encaja una")
	_check(_encajar_bien(motor, _pieza_bandeja(motor)) == "encajo", "y otra (tope 2)")
	_check(await _esperar_que(func() -> bool: return "cerrado:nicole:true" in _eventos, 4.0), "turno perfecto de Nicole (aun tras la segunda oportunidad)")
	_check(await _abrir_turno(motor, "maxi"), "vuelve Maxi")
	motor._jugada_automatica_equipo()
	_check(await _esperar_que(func() -> bool: return "cerrado:maxi:false" in _eventos and _eventos.count("cerrado:maxi:false") == 2, 4.0), "jugada automatica de Maxi: su pieza vuela sola y cierra el turno")
	_check(await _abrir_turno(motor, "sofia"), "le toca a Sofia")
	await _esperar(0.45)
	var giradas := 0
	for p in motor._en_bandeja():
		var h = motor._hueco_de(p)
		if h != null and not motor._calza(p, h):
			giradas += 1
	_check(giradas > 0 and motor._rotacion_por_toque, "Sofia: piezas giradas al azar (%d sin calzar) y rotacion por toque" % giradas)
	var encajados_antes: int = motor._encajados
	g._pos_rival = g.pasos_rival() - 1
	var resultado := ""
	for p in motor._en_bandeja():
		for hueco in motor._huecos:
			if resultado == "no_es_este" or hueco["pieza"] != null or (hueco["color"] as Color).is_equal_approx(p.color):
				continue
			resultado = motor.soltar_pieza(p, hueco["centro"])
			if resultado == "girar":
				motor._dejar_de_flotar(p)
	_check(resultado == "no_es_este", "Sofia suelta una pieza en un hueco equivocado")
	_check(await _esperar_que(func() -> bool: return "cerrado:sofia:false" in _eventos, 3.0), "Sofia: el primer fallo pasa el turno")
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos, 6.0), "con el rival en pasos - 1, llega en el pase")
	_check(await _esperar_que(func() -> bool: return motor._gag_terminado, 6.0), "la derrota-gag termina")
	var visibles := true
	for p in motor._en_bandeja():
		if not p.visible:
			visibles = false
	_check(visibles and motor._encajados == encajados_antes, "las piezas vuelven a la bandeja y lo encajado se conserva (%d)" % motor._encajados)
	var derechas_maxi := true
	for p in motor._en_bandeja():
		var h = motor._hueco_de(p)
		if h != null and not is_equal_approx(wrapf(float(h["rotacion"]), 0.0, 360.0), p.rotacion_grados):
			derechas_maxi = false
	_check(derechas_maxi, "m2: vuelven en el estado del perfil siguiente (Maxi: derechas)")
	var parcial: Dictionary = motor.obtener_parcial_equipo()
	_check(parcial.get("huecos_hechos", []).size() == motor._encajados, "parcial: los huecos llenos (%d)" % parcial.get("huecos_hechos", []).size())
	motor.tocar_otra_vez_equipo()
	_check(await _abrir_turno(motor, "maxi"), "\"¡otra vez!\" abre la puerta de Maxi")
	motor.queue_free()
	await process_frame
	var otro := _instanciar(MOTOR_FORMAS, NIVEL_FORMAS)
	await _esperar(0.1)
	otro.restaurar_parcial_equipo(parcial)
	_check(otro._encajados == parcial["huecos_hechos"].size() and otro._eq_restaurado, "restaurar_parcial_equipo vuelve a poner las piezas")
	_check(await _abrir_turno(otro, "maxi"), "al retomar empieza Maxi")
	otro.queue_free()
	await process_frame


func _probar_formas_victoria() -> void:
	print("-- Formas en equipo: victoria en batalla --")
	var motor := _instanciar(MOTOR_FORMAS, NIVEL_FORMAS, "arcoiris", true)
	var destellos := [-1]
	motor.completado.connect(func(d: int) -> void: destellos[0] = d)
	await _abrir_turno(motor, "maxi")
	for hueco in motor._huecos.duplicate():
		if hueco["pieza"] != null or hueco["opcional"]:
			continue
		var pieza: PiezaEncajar = null
		for p in motor._piezas:
			if not p.colocada and p.id == "pieza_" + str(hueco["id"]):
				pieza = p
		if pieza == null:
			for i in motor._cola.size():
				if motor._cola[i]["hueco"] == hueco:
					pieza = motor._crear_pieza(motor._cola[i])
					motor._cola.remove_at(i)
					break
		if pieza != null:
			motor._encajar(pieza, hueco)
	_check(await _esperar_que(func() -> bool: return destellos[0] >= 0, 6.0) and destellos[0] == 0, "en batalla, la ultima pieza emite completado(0)")
	_check(_progreso.contar_niveles_equipo_ganados("arcoiris") == 0, "en batalla no se registra victoria de equipo")
	motor.queue_free()
	await process_frame
