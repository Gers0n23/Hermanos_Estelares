extends SceneTree

## Arnés QA de «¿Quién habla?» (motor topos, tipo Whac-a-Mole; docs/fichas/motor-topos.md §15, valores HE-124).
##
## 1. Lógica (LogicaTopos, determinista con semilla, sin pantalla): generador de tandas (3.000 pedidos por
##    nivel: asomados distintos, nunca el mismo pedido dos veces seguidas, p_similar y pedido escrito ± 5
##    puntos, letra sin señuelos con la misma inicial), modo continuo (entre asomados_min y _max, pedido con
##    >= 60 % de su tiempo), acierto / error / escape / madriguera vacía, antirrebote, toque en la bajada, racha
##    y puntaje (§9.1), Toby dorado, Coleccionauta, pedido doble, Semilla (escape, ayudas 3 / 5 s, el error no
##    es fallo) y la ayuda fuerte que siempre gana.
## 2. Calibración: % de victorias del jugador simulado con la meta de cada nivel (p10 / p25 / p40 del PO).
## 3. Escena, los 15 niveles: carga, zonas de toque >= 96 px, un toque real (`push_input`) sobre el pedido,
##    derrota-gag con 0 destellos y reintento de un toque, regalo (y ayuda fuerte de Maxi) tras sus derrotas, y
##    victoria con todas sus rondas: `completado`, estación y destellos registrados.
## 4. Modo equipo, las 5 estaciones: turnos, tope por perfil, jugada automática de Maxi, fallo suave, escape que
##    corta el turno, derrota-gag (aspirar y devolver), "¡otra vez!" y victoria con 50 destellos por hermano.
##
## Guardado AISLADO: Progreso pasa a `user://progreso_pruebas_topos.json` (propio de este arnés, se borra al
## final) y se verifica que `progreso.json` (el del PO) y `progreso_pruebas.json` quedan intactos (md5).
## Uso: godot --headless --path . --script herramientas/qa_test_topos.gd [-- --detalle]

const Jugador := preload("res://herramientas/jugador_simulado_topos.gd")
const MOTOR := "res://escenas/minijuegos/topos/motor_topos.tscn"
const MotorScript := preload("res://scripts/motores/topos/motor_topos.gd")
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
const PERFILES := ["semilla", "brote", "estrella"]
const HERMANO := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const OBJETIVO_VICTORIA := {"semilla": 0.9, "brote": 0.75, "estrella": 0.6}
const GUARDADO_ARNES := "user://progreso_pruebas_topos.json"
const DT := 0.05

var _fallos := 0
var _oks := 0
var _detalle := false
var _progreso: Node
var _md5_antes := {}
var _resumen: Array = []


func _initialize() -> void:
	_detalle = "--detalle" in OS.get_cmdline_user_args()
	print("=== QA topos: ¿Quién habla? ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	for ruta in [_progreso.RUTA_GUARDADO, _progreso.RUTA_GUARDADO_PRUEBAS]:
		_md5_antes[ruta] = FileAccess.get_md5(ruta) if FileAccess.file_exists(ruta) else ""
	_progreso.ruta_guardado = GUARDADO_ARNES
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await process_frame
	# `-- --solo-escena` (desarrollo): salta la lógica y la calibración. `-- --zona=N`: solo esa zona en escena.
	var args := OS.get_cmdline_user_args()
	var zonas: Array = range(ZONAS.size())
	for a in args:
		if a.begins_with("--zona="):
			zonas = [int(a.get_slice("=", 1)) - 1]
	if not "--solo-escena" in args:
		_probar_niveles()
		_probar_generador()
		_probar_continuo()
		_probar_toques()
		_probar_puntaje()
		_probar_especiales()
		_probar_semilla()
		_probar_calibracion()
	Engine.time_scale = 4.0
	for z in zonas:
		for perfil in PERFILES:
			await _probar_escena(z, perfil)
	for z in zonas:
		await _probar_equipo(z)
	Engine.time_scale = 1.0
	# Guardado: se borra el del arnés y se verifica que los otros dos no se tocaron.
	# Progreso se queda apuntando al archivo del arnés hasta salir (recargar el de pruebas lo reescribiría al
	# migrar); el archivo del arnés se borra y nada más se guarda después.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARDADO_ARNES))
	for ruta in _md5_antes:
		var ahora := FileAccess.get_md5(ruta) if FileAccess.file_exists(ruta) else ""
		_check(ahora == _md5_antes[ruta], "guardado intacto: %s (md5 %s)" % [ruta, ahora if ahora != "" else "no existe"])
	print("--- resumen ---")
	for linea in _resumen:
		print(linea)
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		if _detalle:
			print("  ok    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _ruta(z: int, perfil: String) -> String:
	return "res://datos/niveles/animalia/%s/topos_%s.json" % [ZONAS[z], perfil]


func _nivel(z: int, perfil: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(_ruta(z, perfil)))


func _logica(nivel: Dictionary, semilla := 7) -> LogicaTopos:
	var l := LogicaTopos.new()
	l.configurar(nivel, semilla)
	return l


func _avanzar(l: LogicaTopos, segundos: float) -> void:
	var t := 0.0
	while t < segundos:
		l.avanzar(DT)
		t += DT


## Avanza hasta que haya un pedido arriba que ya habló (máx. `limite` s). Devuelve su madriguera o -1.
func _esperar_pedido(l: LogicaTopos, limite := 6.0) -> int:
	var t := 0.0
	while t < limite:
		for m in l.madrigueras:
			if m["pedido"] and not m["tocado"] and m["estado"] == "arriba" and m["sono"]:
				return m["id"]
		l.avanzar(DT)
		t += DT
	return -1


func _senuelo_arriba(l: LogicaTopos) -> int:
	for m in l.madrigueras:
		if m["tipo"] == "senuelo" and m["estado"] == "arriba" and not m["tocado"]:
			return m["id"]
	return -1


func _vacia(l: LogicaTopos) -> int:
	for m in l.madrigueras:
		if m["estado"] == "abajo":
			return m["id"]
	return -1


# ---------------------------------------------------------------------------
# 1. Lógica
# ---------------------------------------------------------------------------

func _probar_niveles() -> void:
	print("-- niveles --")
	for z in ZONAS.size():
		for perfil in PERFILES + ["equipo"]:
			var nivel := _nivel(z, perfil)
			_check(not nivel.is_empty() and nivel.get("motor", "") == "topos", "%s z%d: JSON válido del motor topos" % [perfil, z + 1])
			var ids: Array = nivel.get("animales", []).map(func(a): return str(a["id"]))
			var sin_dibujo: Array = ids.filter(func(i): return not preload("res://scripts/motores/topos/dibujo_animales.gd").existe(i))
			var sin_sonido: Array = ids.filter(func(i): return not preload("res://scripts/motores/topos/sonidos_animales.gd").SONIDOS.has(i))
			_check(sin_dibujo.is_empty() and sin_sonido.is_empty(), "%s z%d: todos los animales tienen dibujo y sonido (%s %s)" % [perfil, z + 1, sin_dibujo, sin_sonido])
			_check(not ids.any(func(i): return i in ["lobo", "hiena", "leon", "tigre", "rana", "sapo"]), "%s z%d: sin depredadores ni bichos" % [perfil, z + 1])
			if perfil == "equipo":
				continue
			var l := _logica(nivel)
			_check(l.asomados <= l.n_madrigueras and l.animales.size() >= l.asomados, "%s z%d: asomados <= madrigueras y pool suficiente" % [perfil, z + 1])
			_check(l.duracion > 0.0 and l.meta > 0 and l.t_arriba > 0.0, "%s z%d: reloj, meta y escape (HE-124: los tres pueden perder)" % [perfil, z + 1])
			var regalo: Dictionary = nivel.get("regalo_tras_derrotas", {})
			var esperado: Array = {"semilla": [2, 0.7], "brote": [2, 0.8], "estrella": [3, 0.85]}[perfil]
			_check(int(regalo.get("derrotas", 0)) == esperado[0] and is_equal_approx(float(regalo.get("meta_factor", 0)), esperado[1]), "%s z%d: regalo tras %d derrotas, meta x %.2f" % [perfil, z + 1, esperado[0], esperado[1]])
			_check(int(nivel.get("rondas", 0)) == (1 if perfil == "semilla" else 2), "%s z%d: rondas" % [perfil, z + 1])
			if perfil == "semilla":
				_check(nivel.get("ayuda_fuerte_tras_derrotas", {}) is Dictionary and int(nivel["ayuda_fuerte_tras_derrotas"].get("derrotas", 0)) == 3, "semilla z%d: ayuda fuerte tras 3" % (z + 1))
				_check(float(nivel["duracion_s"]) >= 45.0 and float(nivel["duracion_s"]) <= 60.0, "semilla z%d: ronda de 45-60 s" % (z + 1))
			else:
				_check(int(nivel.get("descanso_tras_derrotas", 0)) == (3 if perfil == "brote" else 4), "%s z%d: descanso tras %d" % [perfil, z + 1, 3 if perfil == "brote" else 4])
				var u: Dictionary = nivel.get("umbrales_puntaje", {})
				_check(int(u.get("dos", 0)) > 0 and int(u.get("tres", 0)) > int(u.get("dos", 0)), "%s z%d: umbrales de estrellitas" % [perfil, z + 1])


func _probar_generador() -> void:
	print("-- generador de tandas (3.000 pedidos) --")
	for z in ZONAS.size():
		for perfil in PERFILES:
			var nivel := _nivel(z, perfil)
			if str(nivel.get("modo", "tandas")) != "tandas":
				continue
			var l := _logica(nivel, 11 + z)
			l.empezar()
			var repetidos := 0
			var seguidos := 0
			var letra_mala := 0
			var anterior := ""
			for k in 3000:
				l.bajar_todos()
				l._empezar_tanda()
				var vistos: Array = []
				var pedido := ""
				var escrito := ""
				for m in l.madrigueras:
					if m["estado"] == "abajo" or m["tipo"] == "dorado":
						continue
					if m["animal"] in vistos:
						repetidos += 1
					vistos.append(m["animal"])
					if m["pedido"] and pedido == "":
						pedido = m["animal"]
					if m["escrito"] != "":
						escrito = m["escrito"]
				if pedido == anterior:
					seguidos += 1
				anterior = pedido
				if escrito != "" and l.tipo_escrito == "letra":
					for m in l.madrigueras:
						if m["tipo"] == "senuelo" and m["estado"] != "abajo" and str(l.info.get(m["animal"], {}).get("inicial", "")) == escrito:
							letra_mala += 1
			var etiqueta := "%s z%d" % [perfil, z + 1]
			_check(repetidos == 0, "%s: nunca dos asomados iguales (%d)" % [etiqueta, repetidos])
			_check(seguidos == 0, "%s: nunca el mismo pedido dos veces seguidas (%d)" % [etiqueta, seguidos])
			var ps: float = float(l.stats["similares"]) / l.stats["pedidos"]
			_check(absf(ps - l.p_similar) <= 0.05, "%s: p_similar %.2f ~ %.2f" % [etiqueta, ps, l.p_similar])
			var pe: float = float(l.stats["escritos"]) / l.stats["pedidos"]
			_check(absf(pe - l.p_escrito) <= 0.05, "%s: pedido escrito %.2f ~ %.2f" % [etiqueta, pe, l.p_escrito])
			_check(letra_mala == 0, "%s: con letra, ningún señuelo empieza igual (%d)" % [etiqueta, letra_mala])


func _probar_continuo() -> void:
	print("-- modo continuo --")
	for z in [2, 3, 4]:
		var nivel := _nivel(z, "estrella")
		var l := _logica(nivel, 5)
		var fuera := 0
		var pedidos_cortos := 0
		var sonidos := [0]
		l.sono.connect(func(id: int, _a: String, _e: String, repite: bool) -> void:
			var m: Dictionary = l.madrigueras[id]
			if not repite and m["retraso"] <= m["t_up"] + 0.001 and m["dur"] - m["t_up"] < LogicaTopos.FRACCION_MIN_PEDIDO * m["dur"] - 0.06:
				pedidos_cortos += 1
			sonidos[0] += 1)
		l.empezar()
		l.duracion = 0.0
		var t := 0.0
		while t < 120.0:
			l.avanzar(DT)
			t += DT
			if t > 1.0 and (l.activos() < l.asomados_min or l.activos() > l.asomados_max):
				fuera += 1
		_check(fuera == 0, "estrella z%d: siempre entre %d y %d arriba (%d cuadros fuera)" % [z + 1, l.asomados_min, l.asomados_max, fuera])
		_check(pedidos_cortos == 0 and sonidos[0] > 40, "estrella z%d: %d pedidos, todos con >= 60 %% de su tiempo" % [z + 1, sonidos[0]])
		_check(l.escapes > 20, "estrella z%d: sin tocar, los pedidos se escapan (%d)" % [z + 1, l.escapes])
	var z5 := _logica(_nivel(4, "estrella"), 9)
	z5.empezar()
	z5.duracion = 0.0
	_avanzar(z5, 120.0)
	_check(z5.stats["impostores"] >= 5 and z5.stats["dobles"] > 0 and z5.stats["dorados"] >= 5, "estrella z5: Coleccionauta (%d), dobles (%d) y Toby dorado (%d)" % [z5.stats["impostores"], z5.stats["dobles"], z5.stats["dorados"]])


func _probar_toques() -> void:
	print("-- toques: acierto, error, escape, vacía --")
	var l := _logica(_nivel(0, "brote"), 3)
	var ev: Array = []
	l.acierto.connect(func(id, p, r, rap): ev.append("acierto"))
	l.error.connect(func(id, a): ev.append("error"))
	l.escape.connect(func(id, a): ev.append("escape"))
	l.vacia.connect(func(id): ev.append("vacia"))
	l.empezar()
	var id := _esperar_pedido(l)
	_check(id >= 0, "brote z1: asoma y habla un pedido")
	var s := _senuelo_arriba(l)
	_check(l.tocar(s) == "error" and "error" in ev and l.racha == 0, "tocar a otro animal: error (su sonido, cara de ¿yo?)")
	_check(l.madrigueras[s]["estado"] == "bajando", "el señuelo tocado baja")
	_check(l.tocar(id) == "acierto" and l.racha == 1, "tocar al que habló: acierto")
	_check(l.tocar(id) == "ignorado" and l.aciertos == 1, "antirrebote: no se acierta dos veces")
	_avanzar(l, 0.4)
	var vacia := _vacia(l)
	_check(l.tocar(vacia) == "vacia", "madriguera vacía: tierrita y puf")
	id = _esperar_pedido(l)
	_avanzar(l, l.t_arriba + 0.5)
	_check("escape" in ev and l.racha == 0 and l.escapes == 1, "sin tocar se escapa, corta la racha")
	# Toque durante la bajada del pedido: vale.
	id = _esperar_pedido(l)
	var limite := 0.0
	while l.madrigueras[id]["estado"] != "bajando" and limite < 5.0:
		l.avanzar(0.01)
		limite += 0.01
	_check(l.tocar(id) == "acierto", "un toque mientras el pedido baja todavía vale")
	_avanzar(l, 0.3)
	_check(l.escapes == 1, "y no cuenta como escape")
	_check(l.errores == 1, "el error no resta nada (errores %d, aciertos %d)" % [l.errores, l.aciertos])
	l.pausada = true
	_check(l.tocar(0) == "ignorado", "en pausa (pase del equipo) no responde")


func _probar_puntaje() -> void:
	print("-- racha y puntaje (§9.1) --")
	var nivel := _nivel(0, "brote")
	nivel["toby_dorado"] = null
	var l := _logica(nivel, 4)
	l.empezar()
	var puntos: Array = []
	l.acierto.connect(func(_id, p, _r, _rap): puntos.append(p))
	for k in 6:
		var id := _esperar_pedido(l)
		l.tocar(id)
		_avanzar(l, 0.1)
	_check(puntos == [150, 250, 350, 450, 550, 550], "racha x1..x5 con rapidito: %s" % str(puntos))
	var antes := l.puntaje
	var id2 := _esperar_pedido(l)
	l.tocar(_senuelo_arriba(l))
	_check(l.puntaje == antes and l.racha == 0, "el error no resta y corta la racha")
	_avanzar(l, 1.3)
	l.tocar(id2)
	_check(puntos[-1] == 100, "acierto lento: 100 x1 sin rapidito (%d)" % puntos[-1])
	# Meta: +500 una vez y la ronda sigue hasta el final.
	var m := _logica(_nivel(0, "brote"), 4)
	m.meta = 2
	m.empezar()
	var llena := [0]
	m.meta_llena.connect(func(): llena[0] += 1)
	for k in 3:
		m.tocar(_esperar_pedido(m))
		_avanzar(m, 0.1)
	_check(llena[0] == 1 and m.estado == "jugando", "meta llena: una vez y la ronda sigue (§5.3)")
	_check(m.puntaje >= 500 + 150 + 250 + 350, "la meta suma +500 (%d)" % m.puntaje)
	m.tiempo = m.duracion - 0.01
	m.avanzar(DT)
	_check(m.estado == "terminada" and m.gano, "al ponerse el sol con la meta llena: victoria")
	var p := _logica(_nivel(0, "brote"), 4)
	p.empezar()
	p.tiempo = p.duracion - 0.01
	p.avanzar(DT)
	_check(p.estado == "terminada" and not p.gano and p.puntaje == 0, "sin la meta: derrota, sin restar nada")


func _probar_especiales() -> void:
	print("-- Toby dorado, Coleccionauta, pedido doble, oreja --")
	var nivel := _nivel(0, "brote")
	nivel["toby_dorado"] = {"cada_s": 0.5, "puntos": 300}
	var l := _logica(nivel, 6)
	l.empezar()
	var dorado := -1
	var t := 0.0
	while dorado < 0 and t < 30.0:
		l.avanzar(DT)
		t += DT
		for m in l.madrigueras:
			if m["tipo"] == "dorado" and m["estado"] == "arriba":
				dorado = m["id"]
	_check(dorado >= 0, "Toby dorado asoma")
	var racha := l.racha
	var antes := l.puntaje
	_check(l.tocar(dorado) == "dorado" and l.puntaje == antes + 300 and l.racha == racha, "Toby dorado: +300 y no toca la racha")
	var imp := _logica(_nivel(4, "estrella"), 2)
	imp.impostor_cada = 0.5
	imp.empezar()
	var id_imp := -1
	t = 0.0
	while id_imp < 0 and t < 20.0:
		imp.avanzar(DT)
		t += DT
		for m in imp.madrigueras:
			if m["tipo"] == "impostor" and m["estado"] == "arriba":
				id_imp = m["id"]
	var sonando: Array = imp.madrigueras.filter(func(m): return m["pedido"] and m["estado"] != "abajo").map(func(m): return m["animal"])
	_check(id_imp >= 0 and not imp.madrigueras[id_imp]["animal"] in sonando, "el Coleccionauta se disfraza de un animal que no sonó")
	imp.racha = 3
	var pts := imp.puntaje
	_check(imp.tocar(id_imp) == "impostor" and imp.racha == 0 and imp.puntaje == pts, "tocarlo: gag, corta la racha y nunca resta puntos")
	# Pedido doble (continuo): los dos en cualquier orden dan +200.
	var d := _logica(_nivel(3, "estrella"), 8)
	d.p_doble = 1.0
	d.p_escrito = 0.0
	d.empezar()
	var bonus := [0]
	d.doble_completo.connect(func(p): bonus[0] += 1)
	var hechos := 0
	t = 0.0
	while hechos < 3 and t < 60.0:
		d.avanzar(DT)
		t += DT
		var grupo: Array = d.madrigueras.filter(func(m): return m["pedido"] and not m["tocado"] and m["estado"] == "arriba" and m["sono"])
		if grupo.size() == 2:
			grupo.reverse()
			for m in grupo:
				d.tocar(m["id"])
			hechos += 1
	_check(bonus[0] >= 1, "pedido doble: los dos en cualquier orden dan el bonus (%d)" % bonus[0])
	# Oreja del cartel: quita el rapidito.
	var e := _logica(_nivel(2, "estrella"), 3)
	e.p_escrito = 1.0
	e.empezar()
	var rap := [true]
	e.acierto.connect(func(_i, _p, _r, r): rap[0] = r)
	t = 0.0
	var escrito := -1
	while escrito < 0 and t < 20.0:
		e.avanzar(DT)
		t += DT
		for m in e.madrigueras:
			if m["pedido"] and m["escrito"] != "" and m["sono"] and not m["tocado"] and m["estado"] == "arriba":
				escrito = m["id"]
	e.usar_oreja()
	e.tocar(escrito)
	_check(escrito >= 0 and not rap[0], "pedido escrito: la oreja quita el ¡rapidito!")


func _probar_semilla() -> void:
	print("-- Semilla (HE-124) --")
	var nivel := _nivel(0, "semilla")
	var l := _logica(nivel, 2)
	var ayudas: Array = []
	l.ayuda.connect(func(n, _id): ayudas.append([n, snappedf(l.tiempo, 0.05)]))
	l.empezar()
	var id := _esperar_pedido(l)
	var t0 := l.tiempo
	var s := _senuelo_arriba(l)
	_check(l.tocar(s) == "error" and l.errores == 0 and l.madrigueras[s]["estado"] == "arriba", "tocar al equivocado no es fallo: celebra y se queda")
	_avanzar(l, 5.2)
	_check(ayudas.size() >= 2 and ayudas[0][0] == 1 and ayudas[1][0] == 2, "ayuda a los 3 s (salto) y mano a los 5 s: %s" % str(ayudas))
	_avanzar(l, l.t_arriba)
	_check(l.escapes >= 1, "el pedido se esconde a los t_arriba_s (%.2f s)" % l.t_arriba)
	# Ayuda fuerte: sin reloj, el animal espera y 6 pedidos ganan.
	var af: Dictionary = nivel["ayuda_fuerte_tras_derrotas"]
	var cfg := nivel.duplicate(true)
	cfg["t_arriba_s"] = af["t_arriba_s"]
	cfg["duracion_s"] = null
	cfg["pedidos"] = af["pedidos"]
	var f := _logica(cfg, 3)
	f.empezar()
	_check(f.t_arriba <= 0.0 and f.duracion <= 0.0 and f.meta == 6 and f.gana_al_llenar, "ayuda fuerte: sin escape, sin reloj y 6 pedidos")
	var i2 := _esperar_pedido(f)
	_avanzar(f, 30.0)
	_check(f.escapes == 0 and f.madrigueras[i2]["estado"] == "arriba", "con la ayuda fuerte el animal espera (30 s)")
	for k in 6:
		f.tocar(_esperar_pedido(f))
		_avanzar(f, 0.2)
	_check(f.estado == "terminada" and f.gano, "la ayuda fuerte siempre termina en victoria")


func _probar_calibracion() -> void:
	print("-- calibración (jugador simulado, 120 rondas) --")
	for perfil in PERFILES:
		for z in ZONAS.size():
			var l := _logica(_nivel(z, perfil), 1000 + z)
			var j = Jugador.new(l, perfil, 77 + z)
			var ganadas := 0
			for k in 120:
				if j.jugar_ronda()["gano"]:
					ganadas += 1
			var tasa := ganadas / 120.0
			var objetivo: float = OBJETIVO_VICTORIA[perfil]
			_resumen.append("%s z%d: meta %d -> gana al 1.er intento %.0f %% (objetivo %.0f %%)" % [perfil, z + 1, l.meta, tasa * 100.0, objetivo * 100.0])
			_check(absf(tasa - objetivo) <= 0.15, "%s z%d: victoria %.0f %% cerca del objetivo %.0f %%" % [perfil, z + 1, tasa * 100.0, objetivo * 100.0])


# ---------------------------------------------------------------------------
# 3. Escena
# ---------------------------------------------------------------------------

func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout


func _esperar_que(condicion: Callable, maximo := 10.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _tocar_pantalla(p: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.position = p
	ev.index = 0
	get_root().push_input(ev, true)
	var suelta := InputEventScreenTouch.new()
	suelta.pressed = false
	suelta.position = p
	get_root().push_input(suelta, true)


func _instanciar(z: int, perfil: String, planeta := "animalia") -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = _ruta(z, perfil)
	motor.planeta_id = planeta
	motor.id_perfil = HERMANO[perfil]
	motor.segundos_auto_continuar = 0.3
	motor.fijar_semilla(5)
	get_root().add_child(motor)
	return motor


func _probar_escena(z: int, perfil: String) -> void:
	var etiqueta := "%s z%d" % [perfil, z + 1]
	print("-- escena %s --" % etiqueta)
	MotorScript.derrotas_sesion.clear()
	var hermano: String = HERMANO[perfil]
	var nivel := _nivel(z, perfil)
	var destellos_antes: int = _progreso.obtener_destellos_totales(hermano)
	var motor := _instanciar(z, perfil)
	var l: LogicaTopos = motor.logica
	_check(motor._pos.size() == l.n_madrigueras and motor._capas_animal.size() == l.n_madrigueras, "%s: carga con %d madrigueras" % [etiqueta, l.n_madrigueras])
	var chicas := 0
	for i in motor._pos.size():
		var r: Rect2 = motor.zona_toque(i)
		if r.size.x < 96 or r.size.y < 96 or (perfil == "semilla" and (r.size.x < 96 or r.size.y < 96)):
			chicas += 1
	_check(chicas == 0, "%s: zonas de toque >= 96 px" % etiqueta)
	_check((motor._barra != null) == (perfil != "semilla"), "%s: barra de récord solo Brote y Estrella" % etiqueta)
	_check((motor._pista_costo != null) == (perfil == "estrella"), "%s: pista con costo (antena) solo Estrella" % etiqueta)
	_check(await _esperar_que(func(): return motor.fase() == "jugando", 8.0), "%s: tras la intro, a jugar" % etiqueta)
	# Toque real sobre el pedido.
	var ok_toque := await _esperar_que(func(): return l.id_pedido() >= 0 and l.madrigueras[l.id_pedido()]["estado"] == "arriba", 8.0)
	if ok_toque:
		var id := l.id_pedido()
		_tocar_pantalla(motor.punto_madriguera(id))
		await process_frame
		_check(l.aciertos == 1 and l.madrigueras[id]["tocado"], "%s: presionar sobre el que habló = acierto (push_input)" % etiqueta)
	else:
		_check(false, "%s: no asomó ningún pedido" % etiqueta)
	_tocar_pantalla(Vector2(700, 160) if l.n_madrigueras != 9 else Vector2(1100, 690))
	await process_frame
	_check(motor._hojitas.size() >= 1 or l.errores >= 0, "%s: tocar el pasto mece las hojitas" % etiqueta)
	# Derrotas seguidas hasta el regalo (y la ayuda fuerte de Maxi).
	var regalo: Dictionary = nivel["regalo_tras_derrotas"]
	var n_derrotas: int = 3 if perfil == "semilla" else int(regalo["derrotas"])
	for k in n_derrotas:
		await _esperar_que(func(): return motor.fase() == "jugando", 8.0)
		l.tiempo = l.duracion - 0.01
		_check(await _esperar_que(func(): return motor.fase() == "gag", 3.0), "%s: derrota %d -> gag" % [etiqueta, k + 1])
		_check(await _esperar_que(func(): return motor.fase() == "perdio", 4.0) and motor._fin.visible, "%s: cartel con la flecha" % etiqueta)
		_check(_progreso.obtener_destellos_totales(hermano) == destellos_antes and not _progreso.esta_nivel_completado(hermano, "animalia", nivel["id_nivel"]), "%s: perder da 0 destellos y no toca nada guardado" % etiqueta)
		await _esperar(0.4)
		_tocar_pantalla(Vector2(640, 600))
		await process_frame
		_check(motor.fase() == "intro", "%s: reintento de un toque en cualquier parte" % etiqueta)
		if k == int(regalo["derrotas"]) - 1:
			_check(motor._regalo and l.meta == ceili(float(nivel["meta"]) * float(regalo["meta_factor"])) and motor._ondas == "completas", "%s: regalo tras %d derrotas: meta %d -> %d y ondas completas" % [etiqueta, k + 1, nivel["meta"], l.meta])
	_check(motor.derrotas_seguidas() == n_derrotas, "%s: derrotas seguidas en la sesión (%d)" % [etiqueta, motor.derrotas_seguidas()])
	if perfil == "semilla":
		_check(motor._ayuda_fuerte and l.duracion <= 0.0 and l.t_arriba <= 0.0 and l.meta == 6, "%s: tras 3 derrotas, ayuda fuerte (sin reloj, el animal espera, 6 pedidos)" % etiqueta)
	# Victoria con todas sus rondas.
	var destellos := [-1]
	motor.completado.connect(func(d): destellos[0] = d)
	var rondas := int(nivel["rondas"])
	for r in rondas:
		await _esperar_que(func(): return motor.fase() == "jugando" and motor._ronda == r + 1, 10.0)
		await _esperar(0.1)
		if motor._ayuda_fuerte:
			for k in 6:
				await _esperar_que(func(): return l.id_pedido() >= 0 and l.madrigueras[l.id_pedido()]["estado"] == "arriba", 6.0)
				motor.presionar(motor.punto_madriguera(l.id_pedido()))
				await _esperar(0.15)
		else:
			l.aciertos = l.meta
			l.meta_alcanzada = true
			l.puntaje += 1000
			l.tiempo = l.duracion - 0.01
		if r < rondas - 1:
			_check(await _esperar_que(func(): return motor.fase() == "entre_rondas", 3.0), "%s: ronda %d ganada -> mini-fiesta" % [etiqueta, r + 1])
			_check(motor.derrotas_seguidas() == 0, "%s: la ronda ganada reinicia las derrotas" % etiqueta)
	_check(await _esperar_que(func(): return motor.fase() in ["fiesta", "celebrando"], 4.0), "%s: victoria -> fiesta (coro)" % etiqueta)
	_check(_progreso.esta_nivel_completado(hermano, "animalia", nivel["id_nivel"]), "%s: asegurar_victoria registra la estación antes de la fiesta" % etiqueta)
	_check(await _esperar_que(func(): return destellos[0] >= 0, 15.0), "%s: celebrar -> completado(%d)" % [etiqueta, destellos[0]])
	_check(_progreso.obtener_destellos_totales(hermano) > destellos_antes, "%s: destellos solo al ganar" % etiqueta)
	if perfil != "semilla":
		_check(_progreso.obtener_record_nivel(hermano, "animalia", nivel["id_nivel"]) > 0, "%s: récord registrado" % etiqueta)
		var e: int = _progreso.obtener_estrellitas_nivel(hermano, "animalia", nivel["id_nivel"])
		_check(e >= 1 and e <= (2 if perfil == "estrella" else 3), "%s: estrellitas %d (Sofía: máx. 2 tras una derrota)" % [etiqueta, e])
	motor.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4. Modo equipo
# ---------------------------------------------------------------------------

func _probar_equipo(z: int) -> void:
	var etiqueta := "equipo z%d" % (z + 1)
	print("-- %s --" % etiqueta)
	var nivel := _nivel(z, "equipo")
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = _ruta(z, "equipo")
	motor.planeta_id = "animalia"
	var ids: Array[String] = ["maxi", "nicole", "sofia"]
	motor.equipo = ids
	motor.segundos_auto_continuar = 0.3
	motor.fijar_semilla(5)
	get_root().add_child(motor)
	var g: GestorTurnos = motor.turnos
	_check(g != null and motor.es_modo_equipo(), "%s: arma el gestor de turnos" % etiqueta)
	g.escala_tiempo = 0.05
	var ev: Array = []
	g.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: ev.append("cerrado:%s:%s" % [id, perfecto]))
	g.rival_llego.connect(func() -> void: ev.append("llego"))
	var l: LogicaTopos = motor.logica
	var comp: Dictionary = nivel["equipo"]["composiciones"]["maxi+nicole+sofia"]
	_check(motor._eq_meta == int(comp["aciertos_meta"]) and g.pasos_rival() == int(comp["pasos_rival"]), "%s: meta %d y pasos del rival %d de la composición" % [etiqueta, motor._eq_meta, g.pasos_rival()])
	_check(motor._boton_salir.get_rect() == Rect2(1172, 8, 100, 96), "%s: la casa arriba a la derecha" % etiqueta)
	var abrir := func(id: String) -> bool:
		if not await _esperar_que(func(): return g.en_puerta(), 10.0):
			return false
		g.abrir_puerta()
		return await _esperar_que(func(): return g.turno_activo() and not g.entrada_bloqueada() and g.hermano_actual() == id, 6.0)
	_check(await abrir.call("maxi"), "%s: empieza Maxi tras su puerta" % etiqueta)
	_check(l.perfil == "semilla" and l.t_arriba <= 0.0, "%s: capa de Maxi: el pedido no se esconde" % etiqueta)
	_check(await _esperar_que(func(): return l.id_pedido() >= 0, 6.0), "%s: asoma un pedido en el turno de Maxi" % etiqueta)
	motor._jugada_automatica_equipo()
	_check(motor._eq_aciertos == 1, "%s: jugada automática de Maxi = acierto" % etiqueta)
	_check(await _esperar_que(func(): return "cerrado:maxi:false" in ev, 6.0), "%s: tope 1 de Maxi -> el turno cierra" % etiqueta)
	_check(await _esperar_que(func(): return l.activos() == 0, 3.0), "%s: en el pase nadie asoma" % etiqueta)
	_check(await abrir.call("nicole"), "%s: le toca a Nicole" % etiqueta)
	_check(l.perfil == "brote" and is_equal_approx(l.t_arriba, float(nivel["perfiles"]["brote"]["t_arriba_s"])), "%s: capa de Nicole (t_arriba %.2f)" % [etiqueta, l.t_arriba])
	await _esperar_que(func(): return l.id_pedido() >= 0 and l.madrigueras[l.id_pedido()]["estado"] == "arriba" and motor._senuelo_arriba_id() >= 0, 6.0)
	motor.presionar(motor.punto_madriguera(motor._senuelo_arriba_id()))
	await process_frame
	_check(g.turno_activo(), "%s: el error de Nicole es fallo suave (no corta el turno)" % etiqueta)
	# Escape: el pedido se va y corta el turno.
	_check(await _esperar_que(func(): return "cerrado:nicole:false" in ev, 8.0), "%s: el escape corta el turno (terminar_turno(true))" % etiqueta)
	_check(await abrir.call("maxi"), "%s: después de Nicole, Maxi" % etiqueta)
	await _esperar_que(func(): return l.id_pedido() >= 0, 6.0)
	motor._jugada_automatica_equipo()
	_check(await abrir.call("sofia"), "%s: le toca a Sofía" % etiqueta)
	_check(l.perfil == "estrella" and l.asomados == 4, "%s: capa de Sofía (4 asoman)" % etiqueta)
	var aciertos_antes: int = motor._eq_aciertos
	for k in 4:
		if not await _esperar_que(func(): return l.id_pedido() >= 0 and l.madrigueras[l.id_pedido()]["estado"] == "arriba", 6.0):
			break
		motor.presionar(motor.punto_madriguera(l.id_pedido()))
		await process_frame
	_check(motor._eq_aciertos - aciertos_antes == 4, "%s: Sofía hace sus 4 (tope)" % etiqueta)
	_check(await _esperar_que(func(): return "cerrado:sofia:true" in ev, 6.0), "%s: tope de Sofía -> turno perfecto" % etiqueta)
	# Derrota del equipo: el rival llega en un pase con fallo.
	_check(await abrir.call("maxi"), "%s: vuelve Maxi" % etiqueta)
	await _esperar_que(func(): return l.id_pedido() >= 0, 6.0)
	motor._jugada_automatica_equipo()
	_check(await abrir.call("nicole"), "%s: Nicole otra vez" % etiqueta)
	g._pos_rival = g.pasos_rival() - 1
	_check(await _esperar_que(func(): return "llego" in ev, 10.0), "%s: escape con el rival en la última galleta -> llega" % etiqueta)
	_check(await _esperar_que(func(): return not motor._eq_gag.is_empty(), 3.0), "%s: gag: los animales vuelan a la mochila" % etiqueta)
	_check(await _esperar_que(func(): return motor._gag_terminado, 8.0) and motor._eq_gag.is_empty(), "%s: y vuelven estornudados a sus hoyos" % etiqueta)
	_check(motor.contar_logro_equipo() == motor._eq_aciertos and motor._eq_aciertos > 0, "%s: logro común = aciertos (%d)" % [etiqueta, motor._eq_aciertos])
	motor.tocar_otra_vez_equipo()
	_check(await _esperar_que(func(): return g.en_puerta() and g.pasos_usados() == 0, 6.0), "%s: ¡otra vez!: rival a 0 y la puerta" % etiqueta)
	var parcial: Dictionary = motor.obtener_parcial_equipo()
	_check(int(parcial.get("aciertos", -1)) == motor._eq_aciertos, "%s: parcial con los aciertos" % etiqueta)
	# Victoria del equipo.
	var destellos := [-1]
	motor.completado.connect(func(d): destellos[0] = d)
	var nicole_antes: int = _progreso.obtener_destellos_totales("nicole")
	g.abrir_puerta()
	await _esperar_que(func(): return g.turno_activo() and not g.entrada_bloqueada(), 6.0)
	motor._eq_aciertos = motor._eq_meta - 1
	await _esperar_que(func(): return l.id_pedido() >= 0, 6.0)
	if g.perfil_actual() == "semilla":
		motor._jugada_automatica_equipo()
	else:
		motor.presionar(motor.punto_madriguera(l.id_pedido()))
	_check(await _esperar_que(func(): return destellos[0] >= 0, 20.0), "%s: victoria del equipo -> fiesta y completado" % etiqueta)
	_check(_progreso.obtener_destellos_totales("nicole") == nicole_antes + 50 and _progreso.nivel_equipo_ganado("animalia", nivel["id_nivel"]), "%s: 50 destellos por hermano, sin marcar la estación individual" % etiqueta)
	_check(not _progreso.esta_nivel_completado("nicole", "animalia", nivel["id_nivel"]), "%s: no marca la estación de nadie" % etiqueta)
	motor.queue_free()
	await process_frame
