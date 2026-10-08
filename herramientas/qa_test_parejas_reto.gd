extends SceneTree

## QA de HE-60 "Parejas de Coco con reto real" (ficha motor-emparejar §10.1, §10.1.1 y §10.2) para los
## tres perfiles:
## - Maxi (semilla, zona 1): racha solo con sonido y cresta; sin numeros, barra, vela, vistazo ni record.
## - Nicole (brote, zona 2): vistazo de parejas completas, racha x1-x5, "¡a la primera!", el fallo corta
##   la racha sin restar, record personal (primera partida sin vela; la segunda, con vela porque ya hay
##   record) y estrellitas 1-3 por puntaje base guardadas en Progreso.
## - Sofia (estrella, zona 1): vela desde la primera partida, vistazo de cartas sueltas, tope x5,
##   estrellitas por fallos sin cambios y record con el bono de la vela.
## - Un nivel sin `puntaje` ni `vistazo` se juega exactamente como antes.
## - Correcciones de las auditorias HE-60 (07-Oct-2026): salir tras el ultimo par no pierde la estacion
##   (QA B1), las presentaciones de una sola vez solo se marcan si su voz existe (QA M1), sin voces de la
##   vela no hay vela (UX B1), la banderita no se mueve aunque el puntaje rebalse (UX M1) y la vela se
##   pausa con Cometa hablando, con el globo de la pista y con la app en segundo plano (UX M3).
##
## La vela exige sus voces (UX B1), que aun no existen (HE-67): para probar su mecanica, los casos de vela
## la fuerzan con `vela_sin_voz_en_pruebas`.
##
## Usa SOLO el guardado de pruebas (user://progreso_pruebas.json): si Progreso apunta al real, aborta.
## Uso: godot --headless --path . --script herramientas/qa_test_parejas_reto.gd

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const RUTA := "res://datos/niveles/arcoiris/%s/parejas_%s.json"
const BarraRecord := preload("res://scripts/ui/barra_record.gd")

var _fallos := 0
var _progreso: Node


func _initialize() -> void:
	print("=== QA HE-60: Parejas de Coco con reto real ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas (%s)" % (_progreso.ruta_guardado if _progreso else "sin Progreso"))
		quit(1)
		return
	# Guardado de pruebas limpio: records y presentaciones parten en cero.
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await _probar_maxi()
	await _probar_nicole()
	await _probar_sofia()
	await _probar_sin_reto()
	await _probar_correcciones_auditoria()
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


func _crear(zona: String, perfil: String, id: String, nivel := {}) -> Node:
	var motor: Node = load(MOTOR).instantiate()
	if nivel.is_empty():
		motor.ruta_nivel = RUTA % [zona, perfil]
		motor.planeta_id = "arcoiris"
	else:
		motor.nivel = nivel
	motor.id_perfil = id
	motor.segundos_auto_continuar = 0.3
	motor.vela_sin_voz_en_pruebas = true
	return motor


func _voz_del_nivel(motor: Node, clave: String) -> bool:
	var ruta := str(motor.nivel.get("lineas_voz", {}).get(clave, ""))
	return ruta != "" and ResourceLoader.exists("res://assets/audio/" + ruta)


func _esperar_tablero(motor: Node, ronda: int) -> void:
	var t0 := Time.get_ticks_msec()
	while (motor._ronda != ronda or motor._en_transicion) and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	await _esperar(0.6)


func _esperar_fin_vistazo(motor: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while motor._en_vistazo and Time.get_ticks_msec() - t0 < 15000:
		await process_frame


func _por_pareja(motor: Node) -> Dictionary:
	var grupos := {}
	for carta in motor._cartas:
		if carta.esta_acertada:
			continue
		if not grupos.has(carta.id_pareja):
			grupos[carta.id_pareja] = []
		grupos[carta.id_pareja].append(carta)
	return grupos


func _tocar_grupo(motor: Node, grupo: Array) -> void:
	for carta in grupo:
		carta.tocada.emit(carta)
	await _esperar(0.12)


## Un "no es este" con dos cartas de grupos distintos (sin vistas si se puede) y se limpia al tiro.
func _fallar(motor: Node) -> void:
	var grupos := _por_pareja(motor)
	var ids := grupos.keys()
	var a = grupos[ids[0]][0]
	var b = grupos[ids[1]][0]
	a.tocada.emit(a)
	b.tocada.emit(b)
	await _esperar(0.05)
	motor._terminar_no_es_este()
	await _esperar(0.05)


func _resolver_todo(motor: Node) -> void:
	var grupos := _por_pareja(motor)
	for id in grupos:
		await _tocar_grupo(motor, grupos[id])


func _esperar_completado(motor: Node, completado: Array) -> void:
	var t0 := Time.get_ticks_msec()
	while completado[0] < 0 and Time.get_ticks_msec() - t0 < 25000:
		await process_frame


# ---------------------------------------------------------------------------

func _probar_maxi() -> void:
	print("-- Maxi · semilla · zona 1 --")
	var motor := _crear("zona1_claro", "semilla", "maxi")
	var completado := [-1]
	var rachas: Array = []
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	motor.racha_cambiada.connect(func(n: int) -> void: rachas.append(n))
	get_root().add_child(motor)
	await _esperar_tablero(motor, 0)
	_check(motor._cresta != null and motor._cresta.get_parent() == motor._anfitriona, "la cresta de Coco esta (racha solo con sonido y nuditos)")
	_check(motor._barra_record == null and motor._contador_racha == null and motor._vela == null, "sin barra de record, sin contador x2 ni vela")
	_check(not motor._en_vistazo and not motor._hay_vistazo(), "sin vistazo (sus cartas ya estan a la vista)")
	var grupos := _por_pareja(motor)
	await _tocar_grupo(motor, grupos[grupos.keys()[0]])
	_check(motor._racha == 1 and motor._cresta.encendidos == 1, "un par enciende un nudito (racha 1)")
	for i in motor._rondas.size():
		await _esperar_tablero(motor, i)
		if i == motor._rondas.size() - 1:
			# Ultima ronda (3 parejas): un par y un "no es este" que corta la racha.
			grupos = _por_pareja(motor)
			await _tocar_grupo(motor, grupos[grupos.keys()[0]])
			_check(motor._racha >= 2 and motor._cresta.encendidos >= 2, "la racha sigue entre rondas (%d nuditos)" % motor._cresta.encendidos)
			await _fallar(motor)
			await _esperar(0.3)
			_check(motor._racha == 0 and rachas.back() == 0 and motor._cresta.encendidos == 0, "el 'no es este' corta la racha y apaga los nuditos, sin castigo")
		await _resolver_todo(motor)
	await _esperar_completado(motor, completado)
	_check(completado[0] > 0, "completado(%d) al final" % completado[0])
	_check(motor._puntaje_base == 0, "Maxi no acumula puntaje visible (0)")
	_check(_progreso.obtener_record_nivel("maxi", "arcoiris", motor._id_nivel_actual()) == 0, "no se guarda record para Maxi")
	_check(_progreso.obtener_estrellitas_nivel("maxi", "arcoiris", motor._id_nivel_actual()) == 0, "Maxi no gana estrellitas")
	motor.queue_free()
	await _esperar(0.1)


func _probar_nicole() -> void:
	print("-- Nicole · brote · zona 2, primera partida --")
	var motor := _crear("zona2_charcos", "brote", "nicole")
	var completado := [-1]
	var primeras := [0]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	motor.a_la_primera.connect(func(_id: String) -> void: primeras[0] += 1)
	get_root().add_child(motor)
	await _esperar(0.9 + motor._cartas.size() * motor.SEGUNDOS_CASCADA_REPARTO)
	_check(motor._en_vistazo, "al repartir hay vistazo (ronda tapada)")
	# Primera vez: Coco espera la intro y presenta el vistazo; contamos las cartas a la vista mientras dura.
	var t0 := Time.get_ticks_msec()
	var maximo := 0
	var ids_vistos := {}
	while motor._en_vistazo and Time.get_ticks_msec() - t0 < 15000:
		var a_la_vista: Array = motor._cartas.filter(func(c): return c.mostrando)
		if a_la_vista.size() > maximo:
			maximo = a_la_vista.size()
			ids_vistos.clear()
			for c in a_la_vista:
				ids_vistos[c.id_pareja] = ids_vistos.get(c.id_pareja, 0) + 1
		await process_frame
	_check(maximo == 2 and ids_vistos.size() == 1, "vistazo de 1 pareja completa con %d cartas (vio %d de %s)" % [motor._cartas.size(), maximo, ids_vistos])
	_check(motor._cartas.all(func(c): return not c.mostrando), "tras el vistazo todas vuelven a taparse")
	# QA M1: solo se gasta la presentacion si su voz existe (y sono).
	_check(_progreso.especial_conocido("nicole", "vistazo") == _voz_del_nivel(motor, "vistazo_presenta"),
		"presentacion del vistazo marcada solo si su voz existe (voz %s, marcada %s)" % [_voz_del_nivel(motor, "vistazo_presenta"), _progreso.especial_conocido("nicole", "vistazo")])
	_check(motor._vela == null, "primera partida sin record: no hay vela (M7.1)")
	_check(motor._barra_record != null and motor._barra_record.record == 0, "barra de puntaje sin banderita (no hay record)")
	# Un par que nadie vio: "¡a la primera!".
	var grupos := _por_pareja(motor)
	var virgen := ""
	for id in grupos:
		if grupos[id].all(func(c): return not motor._ya_vistas.has(c)):
			virgen = id
			break
	await _tocar_grupo(motor, grupos[virgen])
	_check(primeras[0] == 1 and motor._puntaje_base == 300, "'¡a la primera!': 100 x1 + 200 (puntaje %d)" % motor._puntaje_base)
	# Un par ya visto (el del vistazo) no es "a la primera"; la racha sube a x2.
	grupos = _por_pareja(motor)
	var visto := ""
	for id in grupos:
		if grupos[id].any(func(c): return motor._ya_vistas.has(c)):
			visto = id
			break
	if visto != "":
		await _tocar_grupo(motor, grupos[visto])
		_check(primeras[0] == 1 and motor._racha == 2 and motor._puntaje_base == 500, "par ya visto: x2 = 200, sin bono (puntaje %d)" % motor._puntaje_base)
		_check(motor._contador_racha.visible and motor._contador_racha.text == "×2", "contador de racha '×2' junto a Coco")
	await _resolver_todo(motor)
	for i in range(1, motor._rondas.size()):
		await _esperar_tablero(motor, i)
		await _esperar_fin_vistazo(motor)
		if i == 1:
			var antes: int = motor._puntaje_base
			await _fallar(motor)
			_check(motor._racha == 0 and motor._puntaje_base == antes,"el fallo corta la racha y no resta puntos (%d)" % motor._puntaje_base)
		await _resolver_todo(motor)
	await _esperar_completado(motor, completado)
	var id_nivel: String = motor._id_nivel_actual()
	var record: int = _progreso.obtener_record_nivel("nicole", "arcoiris", id_nivel)
	var estrellitas: int = _progreso.obtener_estrellitas_nivel("nicole", "arcoiris", id_nivel)
	_check(completado[0] > 0, "completado(%d) al final" % completado[0])
	_check(record == motor._puntaje_base and record > 0, "primer record guardado = puntaje base %d (sin vela)" % record)
	_check(motor._barra_record.record == record, "la banderita queda clavada en el primer record")
	_check(estrellitas == motor._estrellitas_por_puntaje() and estrellitas >= 1, "estrellitas por puntaje guardadas: %d (umbrales %s)" % [estrellitas, motor.nivel["umbrales_puntaje"]])
	motor.queue_free()
	await _esperar(0.1)

	print("-- Nicole · brote · zona 2, segunda partida (ya hay record) --")
	motor = _crear("zona2_charcos", "brote", "nicole")
	completado = [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	get_root().add_child(motor)
	await _esperar(0.5)
	_check(motor._record_previo == record and motor._barra_record.record == record, "la banderita-cupcake esta a la altura de SU record (%d)" % record)
	_check(motor._vela != null and motor._vela_activa and motor._vela_total == 75.0, "con record, aparece la vela (75 s, desde la zona 2)")
	await _esperar_fin_vistazo(motor)
	var restante: float = motor._vela_restante
	await _esperar(0.5)
	_check(motor._vela_restante < restante, "la vela se consume mientras se juega")
	for i in motor._rondas.size():
		await _esperar_tablero(motor, i)
		await _esperar_fin_vistazo(motor)
		await _resolver_todo(motor)
	await _esperar_completado(motor, completado)
	var total: int = motor._puntaje_base + motor._bono_vela
	_check(motor._bono_vela > 0, "la vela seguia encendida: +%d de regalo" % motor._bono_vela)
	_check(_progreso.obtener_record_nivel("nicole", "arcoiris", id_nivel) == maxi(record, total), "record = max(anterior, base + vela) = %d" % maxi(record, total))
	_check(_progreso.especial_conocido("nicole", "vela") == _voz_del_nivel(motor, "vela_presenta"),
		"presentacion de la vela marcada solo si su voz existe (voz %s)" % _voz_del_nivel(motor, "vela_presenta"))
	motor.queue_free()
	await _esperar(0.1)


func _probar_sofia() -> void:
	print("-- Sofia · estrella · zona 1 --")
	var motor := _crear("zona1_claro", "estrella", "sofia")
	var completado := [-1]
	var primeras := [0]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	motor.a_la_primera.connect(func(_id: String) -> void: primeras[0] += 1)
	get_root().add_child(motor)
	await _esperar(0.5)
	_check(motor._vela != null and motor._vela_activa, "vela desde la primera partida (vela_desde_primera)")
	_check(motor._vela.size.y < 80.0 and not Rect2(motor._vela.position, motor._vela.size).intersects(motor.ZONA_TABLERO), "vela de menos de 80 px y fuera del tablero")
	var t0 := Time.get_ticks_msec()
	var maximo := 0
	var repetidos := false
	await _esperar(0.9)
	while motor._en_vistazo and Time.get_ticks_msec() - t0 < 15000:
		var a_la_vista: Array = motor._cartas.filter(func(c): return c.mostrando)
		if a_la_vista.size() > maximo:
			maximo = a_la_vista.size()
			var ids := {}
			for c in a_la_vista:
				ids[c.id_pareja] = true
			repetidos = ids.size() != a_la_vista.size()
		await process_frame
	var esperadas := roundi(motor._cartas.size() / 4.0)
	_check(maximo == esperadas and not repetidos, "vistazo de %d cartas sueltas de %d, nunca dos del mismo par (vio %d)" % [esperadas, motor._cartas.size(), maximo])
	var vela_antes: float = motor._vela_restante
	_check(is_equal_approx(vela_antes, motor._vela_total), "la vela no corre durante el vistazo")
	await _resolver_todo(motor)
	await _esperar_completado(motor, completado)
	var pares: int = motor._pares_totales
	var esperado := 0
	for k in range(1, pares + 1):
		esperado += 100 * mini(k, 5)
	esperado += 200 * primeras[0]
	_check(motor._puntaje_base == esperado, "racha con tope x5: puntaje base %d (esperado %d, %d a la primera)" % [motor._puntaje_base, esperado, primeras[0]])
	_check(motor._calcular_estrellitas() == 3, "sin fallos: 3 estrellitas (por fallos, como siempre)")
	var record: int = _progreso.obtener_record_nivel("sofia", "arcoiris", motor._id_nivel_actual())
	_check(motor._bono_vela > 0 and record == motor._puntaje_base + motor._bono_vela, "record con la vela: %d (+%d vela)" % [record, motor._bono_vela])
	motor.queue_free()
	await _esperar(0.1)


func _probar_sin_reto() -> void:
	print("-- Nivel sin `puntaje` ni `vistazo`: igual que antes --")
	var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA % ["zona1_claro", "estrella"]))
	for clave in ["puntaje", "vistazo", "umbrales_puntaje"]:
		nivel.erase(clave)
	var motor := _crear("", "", "sofia", nivel)
	var completado := [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	get_root().add_child(motor)
	await _esperar(0.9)
	_check(motor._reto.is_empty() and motor._cresta == null and motor._barra_record == null and motor._vela == null, "sin cresta, barra ni vela")
	_check(not motor._en_vistazo and motor._cartas.all(func(c): return not c.mostrando), "sin vistazo: todas tapadas desde el inicio")
	await _resolver_todo(motor)
	await _esperar_completado(motor, completado)
	_check(completado[0] > 0 and motor._puntaje_base == 0, "completado(%d), sin puntaje" % completado[0])
	motor.queue_free()
	await _esperar(0.1)


# ---------------------------------------------------------------------------
# Correcciones de las auditorias UX y QA de HE-60 (07-Oct-2026)
# ---------------------------------------------------------------------------

func _probar_correcciones_auditoria() -> void:
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()

	print("-- UX B1: sin las voces de la vela, no hay vela --")
	var motor := _crear("zona1_claro", "estrella", "sofia")
	motor.vela_sin_voz_en_pruebas = false
	get_root().add_child(motor)
	await _esperar(0.3)
	var hay_voces := _voz_del_nivel(motor, "vela_presenta") and _voz_del_nivel(motor, "vela_dormida")
	_check((motor._vela != null) == hay_voces, "vela solo con sus voces (voces %s, vela %s)" % [hay_voces, motor._vela != null])
	print("-- QA M1: el vistazo no se da por presentado sin su voz --")
	await _esperar_fin_vistazo(motor)
	_check(_progreso.especial_conocido("sofia", "vistazo") == _voz_del_nivel(motor, "vistazo_presenta"),
		"Sofia: vistazo marcado = %s (voz %s)" % [_progreso.especial_conocido("sofia", "vistazo"), _voz_del_nivel(motor, "vistazo_presenta")])
	motor.queue_free()
	await _esperar(0.1)

	print("-- UX M1: la banderita no se mueve aunque el puntaje rebalse --")
	var barra: Control = BarraRecord.new()
	get_root().add_child(barra)
	barra.size = Vector2(84, 396)
	barra.preparar(1000, 500.0)
	var tope_inicial: float = barra.tope
	var altura_inicial: float = barra._altura(barra.record)
	var rebalso_antes: bool = barra.fijar_puntaje(int(tope_inicial * 0.9))
	var rebalso: bool = barra.fijar_puntaje(int(tope_inicial * 1.5))
	_check(is_equal_approx(barra.tope, tope_inicial) and is_equal_approx(barra._altura(barra.record), altura_inicial),
		"puntaje = 1,5 x tope: tope %.0f y banderita a la misma altura (%.1f)" % [barra.tope, barra._altura(barra.record)])
	_check(not rebalso_antes and rebalso and barra._burbujas.size() > 0, "al pasar el tope rebalsa con burbujas (no re-escala)")
	barra.queue_free()

	print("-- UX M3: la vela se pausa con Cometa hablando, con el globo de pista y con la app en pausa --")
	motor = _crear("zona1_claro", "estrella", "sofia")
	get_root().add_child(motor)
	await _esperar_fin_vistazo(motor)
	var t0 := Time.get_ticks_msec()
	while not motor._vela_corriendo and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	_check(motor._vela_corriendo, "la vela se enciende despues del vistazo y de las voces")
	var audio := get_root().get_node_or_null("Audio")
	motor._al_tocar_cometa()
	if audio != null and audio.esta_hablando():
		var antes: float = motor._vela_restante
		await _esperar(0.4)
		_check(is_equal_approx(motor._vela_restante, antes), "con Cometa repitiendo la consigna la vela no corre")
		audio.detener_voz()
	else:
		print("  INFO  la voz de pista de Cometa no existe: se omite su pausa")
	await _esperar(0.1)
	motor._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var antes_foco: float = motor._vela_restante
	await _esperar(0.3)
	_check(is_equal_approx(motor._vela_restante, antes_foco), "con la app en segundo plano la vela no corre")
	motor._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	motor._pista_costo._capa.show()
	var antes_globo: float = motor._vela_restante
	await _esperar(0.3)
	_check(is_equal_approx(motor._vela_restante, antes_globo), "con el globo de la pista abierto la vela no corre")
	motor._pista_costo._capa.hide()
	await _esperar(0.3)
	_check(motor._vela_restante < antes_globo, "al cerrarse todo, la vela sigue")
	motor.queue_free()
	await _esperar(0.1)

	print("-- QA B1: salir justo despues del ultimo par no pierde la estacion --")
	for caso in [["zona2_charcos", "brote", "nicole"], ["zona1_claro", "estrella", "sofia"]]:
		motor = _crear(caso[0], caso[1], caso[2])
		get_root().add_child(motor)
		var id_nivel: String = motor._id_nivel_actual()
		for i in maxi(1, motor._rondas.size()):
			await _esperar_tablero(motor, i)
			await _esperar_fin_vistazo(motor)
			await _resolver_todo(motor)
		await _esperar(0.3)
		# El nino toca "salir" durante la vela, el trofeo o la voz del record: el motor se libera.
		var en_fiesta: bool = motor._celebrando
		motor.queue_free()
		await _esperar(0.2)
		_check(not en_fiesta, "%s: todavia no empezo la celebracion (ventana de la vela y el record)" % caso[2])
		_check(_progreso.esta_nivel_completado(caso[2], "arcoiris", id_nivel), "%s: la estacion queda completada aunque salga a los 0,3 s" % caso[2])
		_check(_progreso.obtener_record_nivel(caso[2], "arcoiris", id_nivel) > 0, "%s: el record tambien quedo guardado" % caso[2])
		_check(_progreso.obtener_estrellitas_nivel(caso[2], "arcoiris", id_nivel) >= 1, "%s: y sus estrellitas" % caso[2])
