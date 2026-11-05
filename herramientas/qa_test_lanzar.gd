extends SceneTree

## Arnes de desarrollo de HE-77 (motor `lanzar`, la Torre de la Coleccion; motor-lanzar.md v4.1 §20, §25.12 y
## §25.18.9). Guardado AISLADO (progreso_pruebas.json, respaldado y restaurado; el real se verifica por md5).
## 1. Logica pura: reparto 13/17, retomar 5/9/13/17 con tope, rearmado (>= 1 queda en el suelo), gags, bonos.
## 2. Validaciones al cargar: el nivel real pasa; balance, G1, G2 y G5 dan error.
## 3. Fisica: torre quieta sin tiros, determinismo (mismo vector -> mismo resultado, ±0,5 px), tiro <= 10,5 s y el
##    anillo de la guia contra el impacto real.
## 4. Resortera: grilla de 20 px de toques cortos en el circulo de agarre sin disparo; < 40 px no dispara; lado de
##    la torre no salta; estabilizador con desliz.
## 5. Maxi: tiro guiado aporta >= 1, nunca a la columna del trono; dedo apretado 1,2 s dispara solo.
## 6. Flujo de equipo (gancho qa_tiro_simulado, sin fisica): reparto, explicacion y bandeja de Nicole (D5), derribo
##    de E1 con parcial de frontera (D1/D2) antes de caida_etapa, sin intro corta en E2 (D3), derrotas, ayudas,
##    rearmado, gigante, E3 con derribo_inminente y completado solo al final; Progreso nunca vuelve atras.
## 7. Retomar: caso B saltado (retomar_torre), caso A exacto con globos 5/9, parcial sin etapa_iniciada = caso A.
## 8. Revancha solo E3 (decision del PO por delegacion, 05-Nov): sin parcial, estrellitas y record; con dos (0, -1).
## 9. Escena: ningun digito, targets >= 96 px, Coco/ramo/canasta fuera del circulo de agarre.
## Uso: godot --headless --path . --script herramientas/qa_test_lanzar.gd

const RUTA_NIVEL := "res://datos/niveles/arcoiris/batalla/torre_equipo.json"
const ESCENA := "res://escenas/minijuegos/lanzar/motor_lanzar.tscn"
const BATALLA := "qa_batalla_torre"

var _fallos := 0
var _oks := 0
var _progreso: Node
var _respaldo := ""
var _md5_real := ""
var _nivel: Dictionary = {}
var _eventos: Array = []
var _turnos_ids: Array = []
var _parcial_a: Dictionary = {}


func _initialize() -> void:
	print("=== QA dev HE-77: motor lanzar (la Torre) ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	_md5_real = FileAccess.get_md5("user://progreso.json") if FileAccess.file_exists("user://progreso.json") else ""
	if FileAccess.file_exists(_progreso.ruta_guardado):
		_respaldo = FileAccess.get_file_as_string(_progreso.ruta_guardado)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	_nivel = JSON.parse_string(FileAccess.get_file_as_string(RUTA_NIVEL))
	# Fisica 4x mas rapida con el MISMO paso (1/60 s): 240 ticks/s y time_scale 4.
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4.0
	await process_frame
	_probar_logica()
	_probar_validaciones()
	await _probar_fisica()
	await _probar_resortera()
	await _probar_maxi()
	await _probar_flujo()
	await _probar_retomar()
	await _probar_revancha()
	await _probar_escena()
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	if _respaldo != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo)
		f.close()
	_progreso.cargar()
	var md5_fin := FileAccess.get_md5("user://progreso.json") if FileAccess.file_exists("user://progreso.json") else ""
	_check(md5_fin == _md5_real, "el guardado real no se toco (md5)")
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar_que(condicion: Callable, maximo := 8.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _cuadros(n: int) -> void:
	for i in n:
		await physics_frame


func _ids(lista: Array) -> Array[String]:
	var r: Array[String] = []
	for x in lista:
		r.append(str(x))
	return r


# ---------------------------------------------------------------------------
# 1. Logica pura
# ---------------------------------------------------------------------------

func _probar_logica() -> void:
	print("-- 1. Logica pura (LogicaAgarre) --")
	var ciclo := ["maxi", "nicole", "maxi", "sofia"]
	_check(LogicaAgarre.reparto(ciclo, 13) == {"maxi": 7, "nicole": 3, "sofia": 3}, "13 globos: Maxi 7, Nicole 3, Sofia 3")
	_check(LogicaAgarre.reparto(ciclo, 17) == {"maxi": 9, "nicole": 4, "sofia": 4}, "17 globos: Maxi 9, Nicole 4, Sofia 4")
	_check(str(ciclo[(13 - 1) % 4]) == "maxi" and str(ciclo[(17 - 1) % 4]) == "maxi", "el ultimo globo (13.o y 17.o) es de Maxi")
	_check(LogicaAgarre.globos_al_retomar(0, 5, 13) == 5 and LogicaAgarre.globos_al_retomar(3, 5, 13) == 5, "retomar: minimo 5")
	_check(LogicaAgarre.globos_al_retomar(6, 5, 13) == 9 and LogicaAgarre.globos_al_retomar(10, 5, 13) == 13, "retomar: redondeo a 9 y 13 (≡ 1 mod 4)")
	_check(LogicaAgarre.globos_al_retomar(14, 5, 17) == 17 and LogicaAgarre.globos_al_retomar(12, 5, 13) == 13, "retomar: 17 con canasta de 17; nunca supera la canasta del intento")
	_check(LogicaAgarre.canasta_del_intento(13, 4, 0) == 13 and LogicaAgarre.canasta_del_intento(13, 4, 1) == 17 and LogicaAgarre.canasta_del_intento(13, 4, 3) == 17, "canasta 13 -> 17 desde la 1.a derrota de la etapa, y se queda")
	_check(LogicaAgarre.canasta_del_intento(12, 4, 2, 2) == 18, "nicole+sofia: ayuda 2 = +2 globos")
	_check(not LogicaAgarre.gigante_en_intento(1, true) and LogicaAgarre.gigante_en_intento(2, true) and not LogicaAgarre.gigante_en_intento(2, false), "gigante desde el 3.er intento, solo con Maxi")
	_check(LogicaAgarre.agarre_conservado(10, 0.3, true) == 3 and LogicaAgarre.agarre_conservado(2, 0.3, true) == 1 and LogicaAgarre.agarre_conservado(5, 0.3, false) == 0, "conservado = max(1, round(0,3 x perdido)) si hubo botadas")
	var pesos := {"a": 1, "b": 1, "c": 2}
	var suben := LogicaAgarre.elegir_rearmado(["a", "b", "c"], pesos, ["a", "b", "c"], 1)
	_check(suben.size() == 2 and not "c" in suben, "rearmado: suben hasta dejar el conservado botado")
	_check(LogicaAgarre.elegir_rearmado(["a"], pesos, ["a"], 0).is_empty(), "rearmado: con 1 botada, esa queda en el suelo (m2)")
	var vars := ["baile", "estornudo", "globo_que_vuelve", "chicle"]
	var seq: Array = []
	var ultimo := ""
	for n in range(1, 8):
		ultimo = LogicaAgarre.variante_gag(n, ultimo, vars)
		seq.append(ultimo)
	_check(seq == ["baile", "estornudo", "globo_que_vuelve", "chicle", "baile", "estornudo", "globo_que_vuelve"], "gags 1-2-3 y desde la 4.a rotan sin repetir el anterior: %s" % [seq])
	var perfiles: Dictionary = _nivel["perfiles"]
	var agarre: Dictionary = _nivel["agarre"]
	_check(LogicaAgarre.bono_tiro("brote", 2, false, perfiles, agarre) == 1 and LogicaAgarre.bono_tiro("brote", 1, false, perfiles, agarre) == 0, "resbalon de Brote con >= 2")
	_check(LogicaAgarre.bono_tiro("estrella", 3, true, perfiles, agarre) == 3 and LogicaAgarre.bono_tiro("estrella", 2, false, perfiles, agarre) == 0, "doble resbalon de Estrella con >= 3, + golpe, tope 3")
	_check(LogicaAgarre.bono_tiro("semilla", 5, true, perfiles, agarre) == 0, "Semilla nunca produce resbalon ni golpe")
	_check(LogicaAgarre.tramo_logro(0, 20, 0.5) == 0 and LogicaAgarre.tramo_logro(4, 20, 0.5) == 1 and LogicaAgarre.tramo_logro(10, 20, 0.5) == 2, "logro comun en 2 tramos")


# ---------------------------------------------------------------------------
# 2. Validaciones
# ---------------------------------------------------------------------------

func _probar_validaciones() -> void:
	print("-- 2. Validaciones al cargar (§14, §25.8) --")
	_check(LogicaAgarre.validar_nivel(_nivel).is_empty(), "nivel real: reparto, gags, carga y bandejas OK %s" % [LogicaAgarre.validar_nivel(_nivel)])
	var pesos_ok := [32, 27, 26]
	var piezas_ok := [20, 16, 17]
	for i in 3:
		var etapa: Dictionary = _nivel["etapas"][i]
		var errores := LogicaAgarre.validar_etapa(etapa, _nivel)
		_check(errores.is_empty(), "E%d: valida (balance, G1, G2, G5, trono arriba) %s" % [i + 1, errores])
		_check(LogicaAgarre.peso_botable(etapa["torre"]) == pesos_ok[i] and (etapa["torre"]["bloques"] as Array).size() == piezas_ok[i], "E%d: %d piezas y peso_botable %d (§25.2.3)" % [i + 1, piezas_ok[i], pesos_ok[i]])
	var e1: Dictionary = _nivel["etapas"][0].duplicate(true)
	e1["agarre_inicial"] = 30
	_check(_tiene(LogicaAgarre.validar_etapa(e1, _nivel), "peso_botable"), "balance: peso_botable < 1,3 x agarre da error")
	var e1b: Dictionary = _nivel["etapas"][0].duplicate(true)
	for b in e1b["torre"]["bloques"]:
		if b["id"] == "l05":
			b["material"] = "caramelo"
	_check(_tiene(LogicaAgarre.validar_etapa(e1b, _nivel), "G1"), "G1: trono apoyado en un frasco da error")
	var e1c: Dictionary = _nivel["etapas"][0].duplicate(true)
	e1c["torre"]["puntos_debiles"]["semilla"].append("l06")
	_check(_tiene(LogicaAgarre.validar_etapa(e1c, _nivel), "G2"), "G2: apoyo del trono en semilla da error")
	var e3: Dictionary = _nivel["etapas"][2].duplicate(true)
	e3["torre"]["puntos_debiles"]["semilla"].append("r01")
	_check(_tiene(LogicaAgarre.validar_etapa(e3, _nivel), "G2"), "G2: resorte en semilla da error")
	var e1d: Dictionary = _nivel["etapas"][0].duplicate(true)
	e1d["torre"]["bloques"][0]["rect"][1] = 500
	_check(_tiene(LogicaAgarre.validar_etapa(e1d, _nivel), "G5"), "G5: una pieza flotando da error")
	var n2: Dictionary = _nivel.duplicate(true)
	n2["intentos"]["globos_base"] = 12
	_check(not LogicaAgarre.validar_nivel(n2).is_empty(), "globos_base 12 (no ≡ 1 mod 4) da error")


func _tiene(errores: Array, texto: String) -> bool:
	for e in errores:
		if texto in str(e):
			return true
	return false


# ---------------------------------------------------------------------------
# 3. Fisica: quietud, determinismo, duracion del tiro y anillo
# ---------------------------------------------------------------------------

func _torre_nueva(idx: int) -> TorreLanzar:
	var t := TorreLanzar.new()
	get_root().add_child(t)
	t.armar(_nivel["etapas"][idx]["torre"], _nivel)
	return t


func _probar_fisica() -> void:
	print("-- 3. Fisica: quietud y determinismo (§6.2, §6.3, §25.7) --")
	var t := _torre_nueva(0)
	var botados := [0]
	t.bloque_botado.connect(func(_b: BloqueLanzar) -> void: botados[0] += 1)
	var antes := t.poses()
	await _cuadros(600)
	var mov := 0.0
	for id in antes:
		mov = maxf(mov, (antes[id]["pos"] as Vector2).distance_to(t.poses()[id]["pos"]))
	_check(botados[0] == 0 and mov == 0.0 and t.todo_dormido(), "10 s sin tiros: 0 botados y ninguna pose se movio (la torre duerme)")
	t.queue_free()
	await process_frame
	var vel := Vector2(cos(deg_to_rad(28.0)), -sin(deg_to_rad(28.0))) * 1180.0
	var r1 := await _tiro_fisico(vel)
	var r2 := await _tiro_fisico(vel)
	var maxd := 0.0
	for id in r1["poses"]:
		maxd = maxf(maxd, (r1["poses"][id]["pos"] as Vector2).distance_to(r2["poses"][id]["pos"]))
	print("    tiro: %d botadas, %.2f s, impacto %s, anillo %s" % [r1["botados"], r1["dur"], r1["impacto"], r1["anillo"]])
	_check(r1["terminado"] and r2["terminado"], "los dos tiros terminan solos (fin del tiro = sin globos y todo dormido)")
	_check(r1["botados"] > 0, "el tiro de referencia bota algo")
	_check(maxd <= 0.5 and r1["botados"] == r2["botados"], "determinismo: mismo vector -> mismas poses (max %.4f px <= 0,5)" % maxd)
	_check(float(r1["dur"]) <= 10.5, "ningun tiro pasa de 10,5 s (%.2f s)" % r1["dur"])
	_check(r1["anillo"] != Vector2.INF and (r1["anillo"] as Vector2).distance_to(r1["impacto"]) <= 10.0, "el impacto real cae a <= 10 px del anillo de la guia (%.2f px)" % (r1["anillo"] as Vector2).distance_to(r1["impacto"]))
	_check(int(r1["globos_max_cuadros"]) <= 420, "ningun globo vive mas de 420 cuadros")
	# Un globo que solo toca el suelo se retira a los 110 cuadros de su primer contacto.
	var t2 := _torre_nueva(0)
	await _cuadros(2)
	var g := t2.lanzar("normal", "rojo", _nivel["proyectiles"]["normal"], Vector2(260, 430), Vector2(80, -100))
	var retiro := [-1]
	var contacto := [-1]
	t2.primer_impacto.connect(func(_g: GloboLanzar, _p: Vector2) -> void: contacto[0] = t2.cuadro)
	t2.globo_retirado.connect(func(gg: GloboLanzar) -> void:
		retiro[0] = t2.cuadro
		_check(gg.primer_contacto_suelo, "el globo que cae al suelo cuenta el suelo como contacto"))
	await _esperar_que(func() -> bool: return retiro[0] >= 0, 6.0)
	_check(retiro[0] - contacto[0] >= 109 and retiro[0] - contacto[0] <= 112, "retiro a los 110 cuadros del primer contacto con el suelo (%d)" % (retiro[0] - contacto[0]))
	t2.queue_free()
	# Resorte irrompible: un pesado no lo rompe.
	var t3 := _torre_nueva(2)
	var r := t3.bloque("r01")
	for k in 5:
		t3._contactos.append({"tipo": "globo", "g": t3.lanzar("pesado", "azul", _nivel["proyectiles"]["pesado"], Vector2(905, 360), Vector2(0, 400)), "c": r, "va": Vector2(0, 900), "vd": Vector2.ZERO, "p": r.global_position})
	await _cuadros(3)
	_check(r.activo() and r.manchas.is_empty(), "el resorte no se rompe con el pesado y queda limpio")
	t3.queue_free()
	await process_frame


func _tiro_fisico(vel: Vector2) -> Dictionary:
	var t := _torre_nueva(0)
	await _cuadros(3)
	var botados := [0]
	t.bloque_botado.connect(func(_b: BloqueLanzar) -> void: botados[0] += 1)
	var pred := t.predecir(Vector2(260, 430), vel, 26.0)
	var impacto := [Vector2.INF]
	var max_c := [0]
	t.primer_impacto.connect(func(g: GloboLanzar, p: Vector2) -> void:
		if impacto[0] == Vector2.INF and g.principal:
			impacto[0] = p)
	t.globo_retirado.connect(func(g: GloboLanzar) -> void: max_c[0] = maxi(max_c[0], g.cuadros))
	var c0 := t.cuadro
	t.lanzar("normal", "rojo", _nivel["proyectiles"]["normal"], Vector2(260, 430), vel)
	var fin := [false]
	t.tiro_terminado.connect(func() -> void: fin[0] = true)
	await _esperar_que(func() -> bool: return fin[0], 6.0)
	var r := {"poses": t.poses(), "botados": botados[0], "dur": float(t.cuadro - c0) / 60.0, "terminado": fin[0],
		"impacto": impacto[0], "anillo": pred["impacto"], "globos_max_cuadros": max_c[0]}
	t.queue_free()
	await process_frame
	return r


# ---------------------------------------------------------------------------
# Motores
# ---------------------------------------------------------------------------

func _motor(opciones: Dictionary = {}) -> Node:
	var m: Node = (load(ESCENA) as PackedScene).instantiate()
	m.escala_tiempo = float(opciones.get("escala", 0.02))
	if opciones.has("perfil"):
		m.id_perfil = str(opciones["perfil"])
	if opciones.has("equipo"):
		m.equipo = _ids(opciones["equipo"])
	m.en_batalla = bool(opciones.get("en_batalla", false))
	m.revancha = bool(opciones.get("revancha", false))
	get_root().add_child(m)
	if m.turnos != null:
		m.turnos.escala_tiempo = 0.02
	_eventos = []
	_turnos_ids = []
	m.parcial_equipo_listo.connect(func(e: Dictionary) -> void:
		_eventos.append({"t": "parcial", "e": e.duplicate(true)})
		if bool(opciones.get("guardar", false)):
			_progreso.guardar_parcial_batalla(BATALLA, "torre", e))
	m.momento_saltable_iniciado.connect(func(id: String) -> void: _eventos.append({"t": "ini", "id": id}))
	m.momento_saltable_terminado.connect(func(id: String) -> void: _eventos.append({"t": "fin", "id": id}))
	m.derribo_inminente.connect(func(_p: Vector2, desde: bool) -> void: _eventos.append({"t": "derribo", "desde": desde}))
	m.completado.connect(func(d: int) -> void: _eventos.append({"t": "completado", "d": d}))
	m.resultado_revancha.connect(func(e: int, rec: int) -> void: _eventos.append({"t": "revancha", "e": e, "r": rec}))
	if m.turnos != null:
		m.turnos.turno_iniciado.connect(func(id: String, _p: String) -> void: _turnos_ids.append(id))
	return m


func _hay(t: String, id: String = "") -> bool:
	for e in _eventos:
		if e["t"] == t and (id == "" or e.get("id", "") == id):
			return true
	return false


func _indice(t: String, id: String = "") -> int:
	for i in _eventos.size():
		if _eventos[i]["t"] == t and (id == "" or _eventos[i].get("id", "") == id):
			return i
	return -1


func _parciales() -> Array:
	return _eventos.filter(func(e) -> bool: return e["t"] == "parcial").map(func(e) -> Dictionary: return e["e"])


func _esperar_listo(m: Node) -> bool:
	return await _esperar_que(func() -> bool: return m.fase() == "listo" and m._turno_jugable(), 8.0)


## Equipo: abre la puerta del turno y juega un tiro simulado.
func _jugar_turno(m: Node, ids: Array = [], golpe := false) -> bool:
	if not await _esperar_que(func() -> bool: return m.turnos.en_puerta() or (m.fase() == "listo" and m._turno_jugable()), 8.0):
		return false
	if m.turnos.en_puerta():
		m.turnos.abrir_puerta()
	if not await _esperar_listo(m):
		return false
	return m.qa_tiro_simulado(ids, golpe)


# ---------------------------------------------------------------------------
# 4. Resortera
# ---------------------------------------------------------------------------

func _probar_resortera() -> void:
	print("-- 4. Resortera de Nicole (B2, M2, §5.2) --")
	var m := _motor({"perfil": "nicole"})
	_check(await _esperar_listo(m), "solitario Brote: el turno queda listo")
	_check(m.perfil_turno() == "brote", "perfil del turno: brote")
	var reposo: Vector2 = m._reposo()
	var globos0: int = m.globos_restantes()
	var puntos := 0
	var disparos := 0
	for x in range(-120, 121, 20):
		for y in range(-120, 121, 20):
			var p := reposo + Vector2(x, y)
			if p.distance_to(reposo) > 120.0:
				continue
			puntos += 1
			m.procesar_toque(p, true, 0)
			m.procesar_toque(p, false, 0)
			if not m._disparo_pendiente.is_empty() or m.fase() == "vuelo":
				disparos += 1
	await _cuadros(3)
	_check(puntos > 100 and disparos == 0 and m.torre.globos.is_empty() and m.globos_restantes() == globos0, "%d toques cortos en grilla de 20 px: ningun disparo ni globo gastado" % puntos)
	m.procesar_toque(reposo + Vector2(-10, 10), true, 0)
	m.procesar_arrastre(reposo + Vector2(-35, 25), 0)
	m.procesar_toque(reposo + Vector2(-35, 25), false, 0)
	await _cuadros(2)
	_check(m.torre.globos.is_empty() and m.fase() == "listo", "arrastre < 40 px desde el contacto: se cancela, no gasta")
	m.procesar_toque(reposo + Vector2(60, 0), true, 0)
	_check(m._bolsa == reposo, "contacto del lado de la torre (x > 260): la bolsa no salta")
	m.procesar_arrastre(reposo + Vector2(120, 0), 0)
	m.procesar_toque(reposo + Vector2(120, 0), false, 0)
	await _cuadros(2)
	_check(m.torre.globos.is_empty(), "al reves no dispara")
	# Estabilizador: estira, se queda quieto y al levantar el dedo desliza 30 px hacia adelante en < 60 ms.
	m.reloj_qa_ms = 1000
	m.procesar_toque(reposo + Vector2(-5, 5), true, 0)
	var quieto := reposo + Vector2(-140, 95)
	for k in 10:
		m.reloj_qa_ms = 1000 + k * 30
		m.procesar_arrastre((reposo + Vector2(-5, 5)).lerp(quieto, float(k + 1) / 10.0), 0)
	for k in 6:
		m.reloj_qa_ms = 1300 + k * 30
		m.procesar_arrastre(quieto, 0)
	m.reloj_qa_ms = 1480
	m.procesar_arrastre(quieto + Vector2(15, -8), 0)
	m.reloj_qa_ms = 1500
	m.procesar_arrastre(quieto + Vector2(30, -16), 0)
	var estab: Vector2 = m.bolsa_estabilizada(1500)
	_check(estab.distance_to(quieto) < 0.5, "el estabilizador descarta el desliz de los ultimos 60 ms (toma la muestra quieta)")
	m.procesar_toque(quieto + Vector2(30, -16), false, 0)
	_check(m.fase() == "vuelo" and m.globos_restantes() == globos0, "arrastre real + estiramiento: dispara (el globo ya se habia sacado al empezar el turno)")
	await _esperar_que(func() -> bool: return m.ultimo_impacto != Vector2.INF, 6.0)
	var d: float = m.ultimo_anillo.distance_to(m.ultimo_impacto) if m.ultimo_anillo != Vector2.INF else 999.0
	_check(d <= 10.0, "con desliz, el impacto real cae a <= 10 px del anillo del cuadro estabilizado (%.2f px)" % d)
	m.reloj_qa_ms = -1
	m.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. Maxi
# ---------------------------------------------------------------------------

func _probar_maxi() -> void:
	print("-- 5. Maxi: tiro guiado (L4, G2, M5) --")
	var m := _motor({"perfil": "maxi", "escala": 0.05})
	var aportes: Array = []
	var nunca_trono := true
	for k in 6:
		if not await _esperar_listo(m):
			break
		var obj: BloqueLanzar = m._objetivo
		if obj == null or obj.es_trono or obj.id_bloque in m.torre.columna_trono or obj.material_bloque == "resorte":
			nunca_trono = false
		var antes: int = m._agarre_perdido
		var etapa_antes: int = m.etapa_actual()
		if k == 0:
			m.procesar_toque(Vector2(600, 300), true, 0)
			m.procesar_arrastre(Vector2(400, 200), 0)
			m.procesar_toque(Vector2(400, 200), false, 0)
		else:
			m.procesar_toque(Vector2(500 + k * 40, 250), true, 0)
			m.procesar_toque(Vector2(500 + k * 40, 250), false, 0)
		await _esperar_que(func() -> bool: return m.fase() in ["cierre", "espera", "derribo", "caida", "transicion"], 6.0)
		await _esperar_que(func() -> bool: return m.fase() != "vuelo", 12.0)
		if m.etapa_actual() != etapa_antes or m._derribo_hecho:
			aportes.append(99)
			break
		aportes.append(m._agarre_perdido - antes)
	print("    aportes de Maxi por turno: %s" % [aportes])
	_check(not aportes.is_empty() and aportes.all(func(a) -> bool: return int(a) >= 1), "cada tiro de Maxi bota algo (aporte >= 1)")
	_check(nunca_trono, "el objetivo de Maxi nunca es el trono, su columna ni un resorte")
	m.queue_free()
	await process_frame
	var m2 := _motor({"perfil": "maxi", "escala": 0.05})
	await _esperar_listo(m2)
	m2.procesar_toque(Vector2(700, 300), true, 0)
	await create_timer(0.9).timeout     # 0,9 s de juego (time_scale 4 -> 0,225 s reales)
	_check(m2.fase() == "apuntando", "con el dedo apretado 0,9 s todavia no sale")
	await create_timer(0.45).timeout
	_check(m2.fase() == "vuelo", "a los 1,2 s ± 0,1 s el globo sale solo, sin soltar (M5)")
	m2.procesar_toque(Vector2(700, 300), false, 0)
	m2.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 6. Flujo de equipo
# ---------------------------------------------------------------------------

func _probar_flujo() -> void:
	print("-- 6. Flujo de equipo: etapas, derrotas y parcial (§25.3, §25.18) --")
	_progreso.borrar_parcial_batalla(BATALLA)
	var m := _motor({"equipo": ["maxi", "nicole", "sofia"], "en_batalla": true, "guardar": true})
	_check(m.turnos != null and m.turnos.sin_pista(), "equipo: GestorTurnos en modo sin pista")
	_check(m.etapa_actual() == 1 and m.agarre_restante() == 24 and m.globos_restantes() == 13, "E1: agarre 24 y canasta de 13")
	# Intento 1 de E1: turnos 1-6 neutros, con la explicacion y la bandeja de Nicole.
	var voces_por_turno: Array = []
	for k in 6:
		var v0: int = m.voces_dichas.size()
		var jugado := await _jugar_turno(m, [])
		if not jugado:
			_check(false, "E1 turno %d jugado" % (k + 1))
		voces_por_turno.append(m.voces_dichas.slice(v0))
	_check(_turnos_ids.slice(0, 6) == ["maxi", "nicole", "maxi", "sofia", "maxi", "nicole"], "orden maxi_intercalado empezando por Maxi: %s" % [_turnos_ids.slice(0, 6)])
	_check("explica_tiro" in voces_por_turno[1] and "explica_tiro" in voces_por_turno[3], "explicacion del tiro en el 1.er turno de Nicole y de Sofia")
	_check(not "explica_tiro" in voces_por_turno[5], "la explicacion no se repite en el 2.o turno de Nicole")
	_check(_hay("ini", "presenta_bandeja_nicole") and "elige_globo_presenta_nicole" in voces_por_turno[5], "D5: la bandeja de Nicole se presenta en su 2.o turno")
	_check(not voces_por_turno[5].any(func(v) -> bool: return str(v).begins_with("carga")), "D5: en ese turno no suena carga")
	_check(not voces_por_turno[1].any(func(v) -> bool: return str(v).begins_with("elige_globo")), "D5: nunca en su 1.er turno")
	var p_turno: Array = _parciales()
	_check(not p_turno.is_empty() and bool(p_turno[-1]["etapa_iniciada"]) and int(p_turno[-1]["etapa"]) == 1, "turno_cerrado: parcial de E1 con etapa_iniciada = true")
	# Derribo de E1 (trono botado) en el turno 7 (Maxi).
	var n_ev := _eventos.size()
	await _jugar_turno(m, ["trono"])
	var i_parcial := -1
	for i in range(n_ev, _eventos.size()):
		if _eventos[i]["t"] == "parcial":
			i_parcial = i
			break
	var i_caida := _indice("ini", "caida_etapa")
	_check(i_parcial >= 0 and i_caida > i_parcial, "D1: el parcial se emite en el cuadro del derribo, ANTES de caida_etapa")
	var foto: Dictionary = _eventos[i_parcial]["e"] if i_parcial >= 0 else {}
	print("    foto: ", foto)
	_check(int(foto.get("etapa", 0)) == 2 and foto.get("etapas_ganadas", []) == ["e1"] and foto.get("etapa_iniciada", true) == false \
		and int(foto.get("globos_restantes", 0)) == 13 and int(foto.get("intento", 0)) == 1 and (foto.get("bloques", {1: 1}) as Dictionary).is_empty(),
		"D1/D2: la foto es el estado inicial de E2 (etapa 2, e1 ganada, etapa_iniciada false, 13 globos)")
	_check(_progreso.obtener_etapa_parcial_batalla(BATALLA, "torre") == 2, "Progreso guarda la etapa 2 desde el derribo")
	var v_derribo: int = m.voces_dichas.size()
	_check(not _hay("derribo"), "E1 no emite derribo_inminente")
	_check(await _esperar_que(func() -> bool: return m.turnos.en_puerta() and m.etapa_actual() == 2, 8.0), "tras la caida corta y la transicion (sin pausa) se abre la puerta de E2")
	_check(_hay("fin", "caida_etapa"), "caida_etapa termina (momento saltable)")
	_check(m.turnos.hermano_actual() == "maxi", "E2 empieza con Maxi (reiniciar_rival)")
	var ps := _parciales()
	print("    ultimo: ", ps[-1])
	_check(ps[-1] == foto, "el parcial de 'al empezar la etapa' es identico al del derribo")
	_check(not m.voces_dichas.slice(v_derribo).has("intro_corta") and m.voces_dichas.slice(v_derribo).has("etapa_llegada:etapa_2_llega"), "D3: al empezar E2 no suena la intro corta; si la llegada")
	_check(m.agarre_restante() == 20 and m.globos_restantes() == 13 and m.charco() == Vector2(120, 24), "E2: agarre 20, canasta 13 y charco chico")
	_check(not _hay("completado"), "completado no sale en E1")
	# E2, intento 1: Nicole bota 2 frascos (resbalon); el resto neutro hasta gastar la canasta.
	_turnos_ids.clear()
	await _jugar_turno(m, [])
	var p_iniciada: Dictionary = _parciales()[-1]
	_check(bool(p_iniciada["etapa_iniciada"]), "D2: tras el primer globo de E2 la etapa queda iniciada")
	await _jugar_turno(m, ["f02", "f03"])
	_check(m._agarre_perdido == 3, "2 frascos + resbalon de Brote = 3 de agarre")
	_parcial_a = _parciales()[-1].duplicate(true)
	for k in 11:
		await _jugar_turno(m, [])
	_check(_turnos_ids.size() == 13 and _turnos_ids.count("maxi") == 7 and _turnos_ids.count("nicole") == 3 and _turnos_ids.count("sofia") == 3 and _turnos_ids[-1] == "maxi",
		"canasta de 13: Maxi 7, Nicole 3, Sofia 3 y el ultimo es de Maxi")
	_check(await _esperar_que(func() -> bool: return m.en_derrota_equipo(), 6.0), "sin globos y con la torre en pie: derrota-gag en el pase")
	_check(m.variante_derrota() == "baile" and m.turnos.barra.en_centro() == "maxi", "1.a derrota: gag 'baile' y Maxi al centro")
	await _esperar_que(func() -> bool: return m._gag_terminado, 4.0)
	m.tocar_otra_vez_equipo()
	await _esperar_que(func() -> bool: return m.turnos.en_puerta(), 6.0)
	_check(m.intento_actual() == 2 and m.globos_restantes() == 17, "intento 2: canasta 17 (+4)")
	_check(m._agarre_perdido == 1 and m.torre.bloque("f02").activo() and m.torre.bloque("f03").estado == "roto", "rearmado: conservado 1, sube f02 y f03 se queda abajo (m2)")
	_turnos_ids.clear()
	for k in 17:
		await _jugar_turno(m, [])
	_check(_turnos_ids.count("maxi") == 9 and _turnos_ids.count("nicole") == 4 and _turnos_ids.count("sofia") == 4 and _turnos_ids[-1] == "maxi", "canasta de 17: Maxi 9, Nicole 4, Sofia 4, el ultimo de Maxi")
	await _esperar_que(func() -> bool: return m.en_derrota_equipo(), 6.0)
	_check(m.variante_derrota() == "estornudo", "2.a derrota de la Torre: 'estornudo'")
	m.tocar_otra_vez_equipo()
	await _esperar_que(func() -> bool: return m.turnos.en_puerta(), 6.0)
	_check(m.intento_actual() == 3 and m.globos_restantes() == 17 and m._gigante_pendiente, "intento 3: 17 globos y el gigante pendiente")
	await _jugar_turno(m, [])
	_check(m._es_gigante and _turnos_ids[-1] == "maxi" and m.globos_restantes() == 16, "el gigante es el primer globo del intento, de Maxi (reemplaza, no se suma)")
	# Derribo de E2 en el turno 2 del intento 3.
	await _jugar_turno(m, ["trono"])
	_check(await _esperar_que(func() -> bool: return m.turnos.en_puerta() and m.etapa_actual() == 3, 8.0), "E3 abre con la puerta de Maxi")
	_check(_hay("ini", "presenta_resorte") and _hay("fin", "presenta_resorte"), "E3: presentacion del trampolin (momento presenta_resorte)")
	_check(m.intento_actual() == 1 and m.globos_restantes() == 13 and not m._gigante_pendiente and m._derrotas_torre == 2, "E3: intento 1, canasta 13, sin gigante; el conteo de gags de la Torre sigue (2)")
	_check(not _progreso.guardar_parcial_batalla(BATALLA, "torre", {"etapa": 2}) and _progreso.obtener_etapa_parcial_batalla(BATALLA, "torre") == 3, "Progreso rechaza volver a la etapa 2 ya ganada")
	# Derrota en E3 -> la 3.a de la Torre es 'globo_que_vuelve', aunque sea la 1.a de la etapa.
	for k in 13:
		await _jugar_turno(m, [])
	await _esperar_que(func() -> bool: return m.en_derrota_equipo(), 6.0)
	_check(m.variante_derrota() == "globo_que_vuelve" and m._derrotas_etapa == 1, "los gags cuentan por Torre y las ayudas por etapa")
	m.tocar_otra_vez_equipo()
	await _esperar_que(func() -> bool: return m.turnos.en_puerta(), 6.0)
	_check(m.globos_restantes() == 17 and not m._gigante_pendiente, "1.a derrota de E3: +4, sin gigante todavia")
	# Victoria en E3.
	await _jugar_turno(m, ["trono"])
	_check(await _esperar_que(func() -> bool: return _hay("completado"), 8.0), "E3: completado(0) al final")
	var derribos := _eventos.filter(func(e) -> bool: return e["t"] == "derribo")
	_check(derribos.size() == 1 and derribos[0]["desde"] == false, "derribo_inminente una sola vez, desde_soltar = false (variante B)")
	_check(_indice("derribo") < _indice("ini", "caida_torre") and _indice("fin", "caida_torre") < _indice("completado"), "orden: derribo_inminente -> caida_torre -> completado")
	var comp := _eventos.filter(func(e) -> bool: return e["t"] == "completado")
	_check(comp.size() == 1 and int(comp[0]["d"]) == 0, "en batalla solo completado(0)")
	_check(m.charco().x >= 360.0, "en el derribo final el charco mide >= 360 px")
	_check(not m.momento_saltable_en_curso("anticipacion"), "la anticipacion no es un momento saltable")
	m.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 7. Retomar
# ---------------------------------------------------------------------------

func _probar_retomar() -> void:
	print("-- 7. Retomar (§12, §25.18.2 y §25.18.4) --")
	var foto := {"etapa": 2, "etapas_ganadas": ["e1"], "etapa_iniciada": false, "intento": 1, "globos_restantes": 13,
		"gigante_usado": false, "agarre_perdido": 0, "bloques": {}, "manchas": [], "charco": null, "rastros": {},
		"ayuda_brote_turnos_sin_derribo": 0, "presentacion_vista": true, "derrotas": 3, "ultimo_gag": "chicle"}
	var m := _motor({"equipo": ["maxi", "nicole", "sofia"], "en_batalla": true})
	m.momento_saltable_iniciado.connect(func(id: String) -> void:
		if id == "retomar_torre":
			m.saltar_momento(id))
	m.restaurar_parcial_equipo(foto)
	_check(await _esperar_que(func() -> bool: return m.turnos.en_puerta(), 6.0), "caso B: tras retomar_torre, la puerta")
	_check(_hay("ini", "retomar_torre") and _hay("fin", "retomar_torre"), "retomar_torre se salta (desde la 1.a vez) y termina")
	_check(m.etapa_actual() == 2 and m.turnos.hermano_actual() == "maxi" and m.agarre_restante() == 20, "caso B: E2 entera, empieza Maxi")
	_check(not m.voces_dichas.has("etapa_llegada:etapa_2_llega"), "saltado: no suena ninguna voz de la re-entrada")
	_check(m.obtener_parcial_equipo()["etapa"] == 2 and not bool(m.obtener_parcial_equipo()["etapa_iniciada"]), "el parcial sigue en E2 sin iniciar")
	m.queue_free()
	await process_frame
	# Caso A: el parcial de E2 a medias del flujo, con 3 globos -> 5.
	var a := _parcial_a.duplicate(true)
	a["globos_restantes"] = 3
	var m2 := _motor({"equipo": ["maxi", "nicole", "sofia"], "en_batalla": true})
	m2.restaurar_parcial_equipo(a)
	await _esperar_que(func() -> bool: return m2.turnos.en_puerta(), 6.0)
	var r: Dictionary = m2.obtener_parcial_equipo()
	_check(m2.globos_restantes() == 5 and m2.voces_dichas.has("encontre_globos"), "caso A: 3 globos -> 5 y suena encontre_globos")
	_check(r["bloques"] == a["bloques"] and int(r["agarre_perdido"]) == int(a["agarre_perdido"]) and r["charco"]["ancho"] == a["charco"]["ancho"], "caso A: torre, agarre y charco exactamente igual")
	_check(m2.voces_dichas.has("intro_corta"), "caso A: suena la intro corta")
	m2.queue_free()
	await process_frame
	var b := _parcial_a.duplicate(true)
	b["globos_restantes"] = 6
	b.erase("etapa_iniciada")
	var m3 := _motor({"equipo": ["maxi", "nicole", "sofia"], "en_batalla": true})
	m3.restaurar_parcial_equipo(b)
	_check(m3._etapa_iniciada and m3.globos_restantes() == 9, "parcial sin etapa_iniciada = caso A; 6 globos -> 9")
	m3.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 8. Revancha (solo E3)
# ---------------------------------------------------------------------------

func _probar_revancha() -> void:
	print("-- 8. Revancha solo E3 (decision del PO por delegacion, 05-Nov-2026) --")
	var m := _motor({"equipo": ["maxi", "nicole", "sofia"], "en_batalla": true, "revancha": true})
	_check(m.etapa_actual() == 3, "la revancha empieza directo en E3")
	_check(m.obtener_parcial_equipo().is_empty(), "sin parcial (salir no cuesta nada ni cuenta)")
	await _jugar_turno(m, [])
	await _jugar_turno(m, ["trono"])
	await _esperar_que(func() -> bool: return _hay("completado"), 8.0)
	var rev := _eventos.filter(func(e) -> bool: return e["t"] == "revancha")
	_check(rev.size() == 1 and int(rev[0]["e"]) == 3 and int(rev[0]["r"]) == 2, "1.er intento con sobrantes: 3 estrellitas y record = 2 globos usados")
	_check(_indice("revancha") < _indice("completado"), "resultado_revancha antes de completado")
	m.queue_free()
	await process_frame
	var m2 := _motor({"equipo": ["maxi", "nicole"], "en_batalla": true, "revancha": true})
	_check(m2.globos_restantes() == 13, "maxi+nicole: canasta de 13")
	await _jugar_turno(m2, ["trono"])
	await _esperar_que(func() -> bool: return _hay("completado"), 8.0)
	var rev2 := _eventos.filter(func(e) -> bool: return e["t"] == "revancha")
	_check(rev2.size() == 1 and int(rev2[0]["e"]) == 0 and int(rev2[0]["r"]) == -1, "con dos hermanos: resultado_revancha(0, -1)")
	m2.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 9. Escena
# ---------------------------------------------------------------------------

func _probar_escena() -> void:
	print("-- 9. Escena: R2, targets y layout --")
	var m := _motor({"equipo": ["maxi", "nicole", "sofia"]})
	await _esperar_que(func() -> bool: return m.turnos.en_puerta(), 6.0)
	var con_digitos: Array = []
	_buscar_digitos(m, con_digitos)
	_check(con_digitos.is_empty(), "ningun digito en la escena del motor %s" % [con_digitos])
	var casa: Button = m._boton_casa
	_check(casa.size.x >= 96 and casa.size.y >= 96, "la casa mide >= 96 px")
	await _jugar_turno(m, [])
	await _esperar_que(func() -> bool: return m.turnos.en_puerta(), 6.0)
	m.turnos.abrir_puerta()
	await _esperar_listo(m)
	var rects: Array = m.rects_bandeja()
	_check(m.perfil_turno() == "brote" and rects.size() == 2 and rects.all(func(r: Rect2) -> bool: return r.size.x >= 96 and r.size.y >= 96), "bandeja de Nicole: 2 globos de 104 px")
	var bolsa: Vector2 = m._reposo()
	var ok_bandeja := true
	for r in rects:
		var cerca := Vector2(clampf(bolsa.x, r.position.x, r.end.x), clampf(bolsa.y, r.position.y, r.end.y))
		ok_bandeja = ok_bandeja and cerca.distance_to(bolsa) >= 120.0 + 24.0
	_check(ok_bandeja, "la bandeja queda a >= 24 px del circulo de agarre")
	_check(m._tipo_cargado == "normal", "viene cargado el normal")
	m.elegir_globo("rebota")
	_check(m._tipo_cargado == "rebota" and m.voces_dichas.has("globo_nombre:rebota"), "elegir el rebotón: no gasta y dice su nombre la 1.a vez")
	var coco := Rect2(40, 454, 90, 130)
	var cerca_coco := Vector2(clampf(bolsa.x, coco.position.x, coco.end.x), clampf(bolsa.y, coco.position.y, coco.end.y))
	var cerca_ramo := Vector2(clampf(bolsa.x, 10, 120), clampf(bolsa.y, 140, 430))
	_check(cerca_coco.distance_to(bolsa) > 120.0 and cerca_ramo.distance_to(bolsa) > 120.0, "Coco y el ramo quedan fuera del circulo de agarre")
	m.queue_free()
	await process_frame


func _buscar_digitos(nodo: Node, salida: Array) -> void:
	var texto := ""
	if nodo is Label or nodo is Button or nodo is RichTextLabel:
		texto = str(nodo.get("text"))
	var re := RegEx.new()
	re.compile("[0-9]")
	if texto != "" and re.search(texto) != null:
		salida.append(str(nodo.get_path()))
	for hijo in nodo.get_children():
		_buscar_digitos(hijo, salida)
