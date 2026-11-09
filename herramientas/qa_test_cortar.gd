extends SceneTree

## Arnes QA del motor `cortar` («La Gran Burbujeada», jefe de Animalia; docs/fichas/batalla-animalia.md §5 y §16).
## 1. Logica pura (LogicaCortar, semilla fija): parabolas dentro de la zona, interseccion segmento-circulo, hitbox
##    reducida del calcetin, pool, frascos (reparto M5 N2 S2 / M7 N3 S3, retomar 5-9-13), 30 %, gags, revancha.
## 2. Escena con un bot: trazo que cruza 3 burbujas (combo), calcetin que no se revienta rozandolo, turno de Maxi
##    que nunca falla (toque en una esquina, Toby a los 20 s, sin calcetin), calcetin de Nicole y de Sofia.
## 3. Bot que gana las 3 oleadas (guardado en el cuadro en que se vacia cada piso, caso B al retomar, victoria con
##    `completado(0)`) y bot que pierde (gags que rotan, 13 frascos, Toby ayuda, oferta de descanso, 30 %).
## 4. Retomar (frascos 5/9/13, caso A/B, empieza Maxi) y revancha (solo entre oleadas, estrellitas).
## Guardado AISLADO: hace de batalla.gd contra `progreso_pruebas.json` (respaldado y restaurado) y verifica que el
## guardado real del PO (`user://progreso.json`) queda intacto (md5).
## Uso: godot --headless --path . --script herramientas/qa_test_cortar.gd   (con `-- --detalle`: cada chequeo)

const ESCENA := "res://escenas/minijuegos/cortar/motor_cortar.tscn"
const NIVEL := "res://datos/niveles/animalia/batalla/burbujeada_equipo.json"
const NIVEL_QA := "user://qa_cortar_nivel.json"
const ID_BATALLA := "animalia_batalla_final"
const RONDA := "burbujeada"
const TRES: Array[String] = ["maxi", "nicole", "sofia"]

var _fallos := 0
var _oks := 0
var _detalle := false
var _progreso: Node
var _respaldo := ""
var _md5_real := ""
var _parciales: Array = []
var _momentos: Array = []
var _saltar_momentos := true


func _initialize() -> void:
	_detalle = "--detalle" in OS.get_cmdline_user_args()
	print("=== QA cortar: La Gran Burbujeada ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	if FileAccess.file_exists(_progreso.RUTA_GUARDADO):
		_md5_real = FileAccess.get_md5(_progreso.RUTA_GUARDADO)
	if FileAccess.file_exists(_progreso.ruta_guardado):
		_respaldo = FileAccess.get_file_as_string(_progreso.ruta_guardado)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await process_frame
	_probar_logica()
	await _probar_trazo_y_calcetin()
	await _probar_maxi()
	await _probar_calcetin_perfiles()
	await _probar_bot_gana()
	await _probar_retomar_caso_b()
	await _probar_bot_pierde()
	await _probar_retomar_caso_a()
	await _probar_revancha()
	# Restaura el guardado de pruebas y verifica que el real no se toco.
	if _respaldo != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo)
		f.close()
	_progreso.cargar()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(NIVEL_QA))
	if _md5_real != "":
		_check(FileAccess.get_md5(_progreso.RUTA_GUARDADO) == _md5_real, "guardado real del PO intacto (md5 %s)" % _md5_real)
	else:
		_check(not FileAccess.file_exists(_progreso.RUTA_GUARDADO), "no se creo un guardado real")
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		if _detalle:
			print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _seccion(nombre: String) -> void:
	print("-- " + nombre)


func _nivel() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(NIVEL))


# ---------------------------------------------------------------------------
# 1. Logica pura
# ---------------------------------------------------------------------------

func _probar_logica() -> void:
	_seccion("logica pura")
	var nivel := _nivel()
	var zona := LogicaCortar.zona_juego(nivel)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2511
	var dentro := true
	var apice_ok := true
	for perfil in ["brote", "estrella"]:
		var cfg: Dictionary = nivel["perfiles"][perfil]
		for o in 3:
			var r := float(LogicaCortar.por_oleada(cfg["diametro"], o)) / 2.0
			for k in 200:
				var tr := LogicaCortar.trayectoria_arco(rng, nivel, r, float(LogicaCortar.por_oleada(cfg["vuelo_s"], o)))
				var ya := float(tr["ya"])
				apice_ok = apice_ok and ya >= 190.0 and ya <= 330.0
				for i in 21:
					var p := LogicaCortar.posicion(tr, float(tr["T"]) * i / 20.0)
					dentro = dentro and p.x - r >= zona.position.x - 0.01 and p.x + r <= zona.end.x + 0.01 and p.y - r >= zona.position.y - 0.01
	_check(dentro, "las parabolas (con el radio) no salen de la zona de juego ni por los lados ni por arriba")
	_check(apice_ok, "apice en y 190-330")
	var tr0 := {"x0": 300.0, "y0": 610.0, "xa": 400.0, "ya": 250.0, "T": 2.0}
	_check(LogicaCortar.posicion(tr0, 0.0).is_equal_approx(Vector2(300, 610)), "parabola: sale del pasto en t=0")
	_check(LogicaCortar.posicion(tr0, 1.0).is_equal_approx(Vector2(400, 250)), "parabola: apice en t=T/2")
	_check(LogicaCortar.posicion(tr0, 2.0).is_equal_approx(Vector2(500, 610)), "parabola: vuelve al pasto en t=T")
	var ts := LogicaCortar.trayectoria_semilla(rng, nivel, 1.2)
	var pa := LogicaCortar.posicion_flotante(ts, 50.0)
	_check(pa.x >= 400 and pa.x <= 880 and pa.y >= 300 and pa.y <= 380, "la burbuja de Maxi flota en x 400-880, y 300-380")
	# Interseccion por segmentos: un trazo de 2 muestras cruza 3 burbujas.
	var a := Vector2(150, 300)
	var b := Vector2(1100, 330)
	var cruzadas := 0
	for c in [Vector2(300, 310), Vector2(640, 330), Vector2(980, 300)]:
		if LogicaCortar.segmento_cruza_circulo(a, b, c, 55.0 + 10.0):
			cruzadas += 1
	_check(cruzadas == 3, "un trazo de 2 muestras cruza las 3 burbujas (%d)" % cruzadas)
	_check(not LogicaCortar.segmento_cruza_circulo(Vector2(0, 0), Vector2(100, 0), Vector2(50, 80), 70.0), "segmento lejos: no cruza")
	_check(LogicaCortar.segmento_cruza_circulo(Vector2(0, 0), Vector2(0, 0), Vector2(10, 0), 20.0), "toque (segmento de largo 0) dentro del circulo")
	# Calcetin: hitbox = radio - 8 (mas chica que el dibujo).
	var r_calc := 52.0
	var hb := LogicaCortar.radio_hitbox("calcetin", r_calc, 10.0, 8.0)
	_check(is_equal_approx(hb, r_calc - 8.0), "hitbox del calcetin = radio - 8")
	_check(not LogicaCortar.segmento_cruza_circulo(Vector2(0, r_calc + 9.0), Vector2(400, r_calc + 9.0), Vector2(200, 0), hb), "trazo a 9 px FUERA del borde del calcetin: no revienta")
	_check(not LogicaCortar.segmento_cruza_circulo(Vector2(0, r_calc - 7.0), Vector2(400, r_calc - 7.0), Vector2(200, 0), hb), "trazo 7 px DENTRO del dibujo del calcetin: no revienta")
	_check(LogicaCortar.segmento_cruza_circulo(Vector2(0, r_calc + 9.0), Vector2(400, r_calc + 9.0), Vector2(200, 0), LogicaCortar.radio_hitbox("animal", r_calc, 10.0, 8.0)), "el mismo trazo a 9 px SI revienta un animal (Estrella: radio + 10)")
	# Pool.
	var pool := {"pato": 2, "vaca": 1}
	var sacados: Array = []
	for k in 3:
		sacados.append(LogicaCortar.sacar(pool, rng, ["vaca"]))
	_check(LogicaCortar.total_pool(pool) == 0 and LogicaCortar.sacar(pool, rng) == "", "el pool se vacia y luego devuelve ''")
	LogicaCortar.devolver(pool, "pato")
	_check(int(pool["pato"]) == 1, "un escape devuelve el animal al pool")
	var ps := LogicaCortar.pool_sin({"pato": 3, "vaca": 2}, ["pato", "vaca", "vaca"])
	_check(int(ps["pato"]) == 2 and int(ps["vaca"]) == 0, "pool_sin descuenta los liberados")
	# Frascos y reparto por el ciclo del gestor.
	var ciclo := GestorTurnos.construir_ciclo(TRES, {"maxi": "semilla", "nicole": "brote", "sofia": "estrella"}, "maxi_intercalado")
	var r9 := LogicaCortar.reparto(ciclo, 9)
	var r13 := LogicaCortar.reparto(ciclo, 13)
	_check(r9 == {"maxi": 5, "nicole": 2, "sofia": 2}, "9 frascos = M5 N2 S2 (%s)" % str(r9))
	_check(r13 == {"maxi": 7, "nicole": 3, "sofia": 3}, "13 frascos = M7 N3 S3 (%s)" % str(r13))
	_check(LogicaCortar.secuencia_turnos(ciclo, 9).back() == "maxi" and LogicaCortar.secuencia_turnos(ciclo, 13).back() == "maxi", "la ultima tanda siempre es de Maxi")
	_check(LogicaCortar.frascos_intento(0, [9, 13]) == 9 and LogicaCortar.frascos_intento(1, [9, 13]) == 13 and LogicaCortar.frascos_intento(3, [9, 13]) == 13, "9 en el intento 1; 13 desde la 1.a derrota")
	var casos := [[7, 9, 9], [3, 9, 5], [0, 13, 5], [10, 13, 13], [6, 13, 9], [12, 13, 13], [9, 9, 9]]
	var retomar_ok := true
	for c in casos:
		var n := LogicaCortar.frascos_al_retomar(c[0], [5, 9, 13], c[1])
		retomar_ok = retomar_ok and n == c[2] and n in [5, 9, 13]
	_check(retomar_ok, "frascos al retomar: minimo 5, hacia arriba a 5/9/13, sin pasar la canasta")
	_check(LogicaCortar.conservados(10, 0.3) == 3 and LogicaCortar.conservados(9, 0.3) == 2 and LogicaCortar.conservados(3, 0.3) == 0, "conservacion del 30 % redondeada hacia abajo")
	var gags := ["burbuja_gorro", "estornudo_jabon", "calcetin_volador"]
	var g := [LogicaCortar.variante_gag(1, "", gags), LogicaCortar.variante_gag(2, gags[0], gags), LogicaCortar.variante_gag(3, gags[1], gags)]
	_check(g == gags, "gags 1.o, 2.o y 3.o en orden")
	var sin_repetir := true
	var ultimo: String = gags[2]
	for d in range(4, 12):
		var v := LogicaCortar.variante_gag(d, ultimo, gags)
		sin_repetir = sin_repetir and v != ultimo
		ultimo = v
	_check(sin_repetir, "desde la 4.a derrota rotan sin repetir el anterior")
	_check(LogicaCortar.toby_ayuda(2, 2) and not LogicaCortar.toby_ayuda(1, 2) and LogicaCortar.ofrecer_descanso(3, 3) and not LogicaCortar.ofrecer_descanso(2, 3), "ayudas: Toby desde la 2.a, descanso desde la 3.a")
	# Tandas: calcetin por perfil y oleada.
	var sem_calc := 0
	var brote_o1 := 0
	var brote_o2 := 0
	var est_max_ok := true
	var est_calc := 0
	for k in 400:
		for ev in LogicaCortar.planear_tanda(rng, "semilla", nivel["perfiles"]["semilla"], k % 3):
			sem_calc += 1 if ev["tipo"] != "burbuja" and ev["tipo"] != "anticipacion" else 0
		for ev in LogicaCortar.planear_tanda(rng, "brote", nivel["perfiles"]["brote"], 0):
			brote_o1 += 1 if ev["tipo"] == "calcetin" else 0
		for ev in LogicaCortar.planear_tanda(rng, "brote", nivel["perfiles"]["brote"], 1):
			brote_o2 += 1 if ev["tipo"] == "calcetin" else 0
		for o in 3:
			var n := 0
			for ev in LogicaCortar.planear_tanda(rng, "estrella", nivel["perfiles"]["estrella"], o):
				n += 1 if ev["tipo"] == "calcetin" else 0
			est_calc += n
			est_max_ok = est_max_ok and n <= [1, 1, 2][o]
	_check(sem_calc == 0, "Semilla: nunca calcetin ni power-ups en el plan")
	_check(brote_o1 == 0 and brote_o2 > 0, "Brote: sin calcetin en O1, si desde O2 (%d)" % brote_o2)
	_check(est_max_ok and est_calc > 0, "Estrella: calcetin con su maximo por tanda (1 · 1 · 2)")
	var plan := LogicaCortar.planear_tanda(rng, "estrella", nivel["perfiles"]["estrella"], 2, ["siesta", "trompeta"])
	var tipos := plan.map(func(e: Dictionary) -> String: return str(e["tipo"]))
	_check("siesta" in tipos and "trompeta" in tipos and tipos.count("burbuja") == 14, "Estrella O3: 2 x 7 burbujas + siesta + trompeta")
	# Revancha.
	_check(LogicaCortar.resultado_revancha("maxi+nicole+sofia", "maxi+nicole+sofia", 0, [3, 2, 4], 20) == {"estrellitas": 3, "record": 20}, "revancha: ★★★ sin derrotas y >= 2 sobrantes")
	_check(LogicaCortar.resultado_revancha("maxi+nicole+sofia", "maxi+nicole+sofia", 0, [3, 1, 4], 22)["estrellitas"] == 2, "revancha: ★★ sin derrotas")
	_check(LogicaCortar.resultado_revancha("maxi+nicole+sofia", "maxi+nicole+sofia", 1, [3, 2, 4], 30) == {"estrellitas": 1, "record": -1}, "revancha: ★ con derrota y sin record")
	_check(LogicaCortar.resultado_revancha("maxi+nicole", "maxi+nicole+sofia", 0, [5, 5, 5], 10) == {"estrellitas": 0, "record": -1}, "revancha con dos: sin estrellitas ni record")
	_check(LogicaCortar.validar_nivel(nivel).is_empty(), "el nivel del jefe valida sin errores")


# ---------------------------------------------------------------------------
# Escena: utilidades
# ---------------------------------------------------------------------------

func _crear_motor(ids: Array, ruta := NIVEL, extra := {}) -> Node:
	var motor: Node = load(ESCENA).instantiate()
	motor.ruta_nivel = ruta
	var eq: Array[String] = []
	for id in ids:
		eq.append(str(id))
	motor.equipo = eq
	motor.en_batalla = true
	motor.revancha = bool(extra.get("revancha", false))
	if eq.is_empty():
		motor.id_perfil = str(extra.get("perfil", "nicole"))
	motor.escala_tiempo = 0.05
	motor.acelerar_qa = float(extra.get("acelerar", 4.0))
	_momentos = []
	_parciales = []
	motor.momento_saltable_iniciado.connect(func(id: String) -> void:
		_momentos.append(id)
		if _saltar_momentos:
			motor.saltar_momento.call_deferred(id))
	motor.parcial_equipo_listo.connect(func(estado: Dictionary) -> void:
		# Hace de batalla.gd: mismo camino de siempre.
		_parciales.append(estado.duplicate(true))
		_progreso.guardar_parcial_batalla(ID_BATALLA, RONDA if not motor.revancha else "burbujeada_revancha", estado))
	get_root().add_child(motor)
	if motor.turnos != null:
		motor.turnos.escala_tiempo = 0.02
	if extra.has("restaurar"):
		motor.restaurar_parcial_equipo(extra["restaurar"])
	return motor


func _liberar_motor(motor: Node) -> void:
	if is_instance_valid(motor):
		motor.queue_free()
	await process_frame
	await process_frame


## Bot por cuadro: abre la puerta, y en la tanda revienta segun `modo` ("gana": todo menos el calcetin; "pierde":
## solo Maxi; "maxi": solo Maxi, igual que pierde). Devuelve cuando `fin` es true o se acaba el tiempo.
func _bot(motor: Node, modo: String, fin: Callable, maximo := 90.0, al_cuadro: Callable = Callable()) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if not is_instance_valid(motor) or fin.call():
			return true
		if motor.turnos != null and motor.turnos.en_puerta():
			motor.turnos.abrir_puerta()
		if motor.en_derrota_equipo() and motor._gag_terminado:
			motor.tocar_otra_vez_equipo()
		if al_cuadro.is_valid():
			al_cuadro.call()
		if motor.fase() == "tanda" and motor._jugable():
			if motor.perfil_turno() == "semilla":
				if not motor.burbujas_en_vuelo().is_empty():
					_tocar(motor, Vector2(142, 112))   # una esquina de la zona
			elif modo == "gana":
				for b in motor.burbujas_en_vuelo():
					var bb := b as BurbujaCortar
					if bb.tipo == "calcetin" or bb.position.y > 595.0 or bb.position.y < 112.0:
						continue
					if _cerca_de_calcetin(motor, bb.position):
						continue
					_tocar(motor, bb.position)
		await process_frame
	return fin.call()


func _cerca_de_calcetin(motor: Node, p: Vector2) -> bool:
	for b in motor.burbujas_en_vuelo():
		var bb := b as BurbujaCortar
		if bb.tipo == "calcetin" and bb.position.distance_to(p) <= bb.radio_hitbox() + 6.0:
			return true
	return false


func _tocar(motor: Node, p: Vector2) -> void:
	motor.procesar_toque(p, true, 0)
	motor.procesar_toque(p, false, 0)


func _esperar_que(condicion: Callable, maximo := 10.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _fijar(b: BurbujaCortar, p: Vector2) -> void:
	b.trayectoria = {"x0": p.x, "xa": p.x, "y0": p.y, "ya": p.y, "T": 1000.0}
	b.bamboleo_px = 0.0
	b.t = 1.0
	b.position = p


func _nivel_qa(cambios: Callable) -> String:
	var n := _nivel()
	cambios.call(n)
	var f := FileAccess.open(NIVEL_QA, FileAccess.WRITE)
	f.store_string(JSON.stringify(n))
	f.close()
	return NIVEL_QA


# ---------------------------------------------------------------------------
# 2. Trazo, combo, calcetin y multitactil (solitario Estrella, reloj quieto)
# ---------------------------------------------------------------------------

func _probar_trazo_y_calcetin() -> void:
	_seccion("trazo por segmentos, combo, calcetin, un solo dedo")
	var ruta := _nivel_qa(func(n: Dictionary) -> void:
		n["perfil"] = "estrella"
		n["perfiles"]["estrella"]["calcetin"]["p"] = [1, 1, 1]
		n["perfiles"]["estrella"]["calcetin"]["max_tanda"] = [2, 2, 2])
	var motor := _crear_motor([], ruta, {"perfil": "sofia"})
	var hay := await _esperar_que(func() -> bool: return motor.burbujas_en_vuelo().size() >= 4, 10.0)
	_check(hay, "Estrella en solitario sopla burbujas")
	motor.acelerar_qa = 0.0
	var animales: Array = motor.burbujas_en_vuelo().filter(func(b: BurbujaCortar) -> bool: return b.tipo == "animal")
	var liberados: Array = []
	var combos: Array = []
	motor.liberado.connect(func(id: String, i: int) -> void: liberados.append([id, i]))
	motor.combo.connect(func(n: int) -> void: combos.append(n))
	if animales.size() >= 3:
		_fijar(animales[0], Vector2(300, 310))
		_fijar(animales[1], Vector2(640, 330))
		_fijar(animales[2], Vector2(980, 300))
		for k in range(3, animales.size()):
			_fijar(animales[k], Vector2(200 + k * 120, 500))
		for b in motor.burbujas_en_vuelo():
			if (b as BurbujaCortar).tipo != "animal":
				_fijar(b, Vector2(640, 160))
		var antes: int = motor.liberados_oleada().size()
		# Un trazo rapido de 2 muestras (presionar + 1 arrastre) que cruza las 3.
		motor.procesar_toque(Vector2(150, 300), true, 0)
		# R4: un segundo dedo apoyado se ignora (ni trazo ni pop).
		motor.procesar_toque(Vector2(200 + 3 * 120, 500), true, 1)
		motor.procesar_arrastre(Vector2(200 + 3 * 120, 500), 1)
		motor.procesar_arrastre(Vector2(1100, 330), 0)
		motor.procesar_toque(Vector2(1100, 330), false, 0)
		var del_trazo: Array = liberados.filter(func(x: Array) -> bool: return int(x[1]) >= 0)
		_check(del_trazo.size() == 3, "el trazo de 2 muestras revento las 3 burbujas que cruzo (%d)" % del_trazo.size())
		_check(del_trazo.map(func(x: Array) -> int: return int(x[1])) == [0, 1, 2], "cada pop sube un semitono: indices 0, 1, 2 en el orden del trazo")
		_check(combos == [3], "¡combo! con la 3.a burbuja del trazo (%s)" % str(combos))
		_check(motor.liberados_oleada().size() == antes + 4, "el combo libera un animal mas (Toby por la ventanita)")
		_check(animales.size() < 4 or animales[3] in motor.burbujas_en_vuelo(), "el segundo dedo no revento nada")
		_check("presenta_combo" in _momentos, "momento presenta_combo")
	# Calcetin: radio - 8; un trazo a 7 px dentro del dibujo no lo revienta; en el centro, si.
	var calc: BurbujaCortar = null
	for b in motor.burbujas_en_vuelo():
		if (b as BurbujaCortar).tipo == "calcetin" and not (b as BurbujaCortar).lenta:
			calc = b
	if calc == null:
		# Las congeladas no vuelven nunca al pasto: se revientan para que la tanda se resuelva y salga la siguiente.
		for b in motor.burbujas_en_vuelo():
			if (b as BurbujaCortar).tipo != "calcetin":
				motor.qa_reventar(b)
		motor.acelerar_qa = 4.0
		await _esperar_que(func() -> bool:
			for b in motor.burbujas_en_vuelo():
				if (b as BurbujaCortar).tipo == "calcetin":
					return true
			return false, 10.0)
		motor.acelerar_qa = 0.0
		for b in motor.burbujas_en_vuelo():
			if (b as BurbujaCortar).tipo == "calcetin":
				calc = b
	_check(calc != null, "salio un calcetin (p = 1 en el nivel de prueba)")
	if calc != null:
		for b in motor.burbujas_en_vuelo():
			if b != calc:
				_fijar(b, Vector2(1000, 520))
		_fijar(calc, Vector2(640, 300))
		var reventados: Array = []
		motor.calcetin_reventado.connect(func(p: String) -> void: reventados.append(p))
		var y_roce := 300.0 + calc.radio - 7.0
		motor.procesar_toque(Vector2(300, y_roce), true, 0)
		motor.procesar_arrastre(Vector2(980, y_roce), 0)
		motor.procesar_toque(Vector2(980, y_roce), false, 0)
		_check(reventados.is_empty() and calc in motor.burbujas_en_vuelo(), "rozar el calcetin 7 px dentro de su dibujo no lo revienta")
		var y_lejos := 300.0 + calc.radio + 9.0
		motor.procesar_toque(Vector2(300, y_lejos), true, 0)
		motor.procesar_arrastre(Vector2(980, y_lejos), 0)
		motor.procesar_toque(Vector2(980, y_lejos), false, 0)
		_check(reventados.is_empty(), "un trazo a 9 px del borde del calcetin no lo revienta")
		_tocar(motor, Vector2(640, 300))
		_check(reventados == ["estrella"], "tocar el centro del calcetin si lo revienta")
		_check(motor.toby.sombrero_calcetin, "el calcetin cae sobre el casco de Toby")
	await _liberar_motor(motor)


# ---------------------------------------------------------------------------
# 2b. Maxi nunca falla
# ---------------------------------------------------------------------------

func _probar_maxi() -> void:
	_seccion("turno de Maxi")
	var motor := _crear_motor(TRES)
	motor.turnos.escala_tiempo = 1.0   # asi la jugada automatica (20 s) no salta durante la espera
	var ok := await _esperar_que(func() -> bool:
		if motor.turnos.en_puerta():
			motor.turnos.abrir_puerta()
		return motor.fase() == "tanda" and not motor.burbujas_en_vuelo().is_empty(), 15.0)
	_check(ok and motor.perfil_turno() == "semilla" and motor.turnos.hermano_actual() == "maxi", "la oleada empieza con Maxi")
	var b: BurbujaCortar = motor.burbujas_en_vuelo()[0] if ok else null
	_check(b != null and b.flota and b.radio >= 100.0, "su burbuja (200 px) sube y flota")
	# 3 s reales x 4 = 12 s de vuelo: nunca se escapa.
	var escapes: Array = []
	motor.escapo.connect(func(id: String) -> void: escapes.append(id))
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await process_frame
	_check(escapes.is_empty() and b in motor.burbujas_en_vuelo(), "la burbuja de Maxi nunca se escapa")
	var solo_animal := true
	for x in motor._burbujas:
		solo_animal = solo_animal and (x as BurbujaCortar).tipo == "animal"
	_check(solo_animal, "Maxi nunca ve el calcetin ni power-ups")
	# A los 20 s sin tocar, Toby la revienta.
	var libres: Array = []
	motor.liberado.connect(func(id: String, _i: int) -> void: libres.append(id))
	motor.turnos.escala_tiempo = 0.02
	await _esperar_que(func() -> bool: return not libres.is_empty(), 5.0)
	_check(libres.size() == 1 and "regalito_maxi" in motor.voces_dichas, "a los 20 s sin tocar la revienta Toby («¡Maxi nos dejo un regalito!»)")
	# Segundo turno de Maxi (tras Nicole): un toque en una esquina de la zona.
	await _bot(motor, "pierde", func() -> bool: return motor.turnos.hermano_actual() == "maxi" and motor.fase() == "tanda" and libres.size() >= 1 and motor.frascos_restantes() <= 6, 30.0)
	var antes := libres.size()
	motor.turnos.escala_tiempo = 1.0   # que no la reviente Toby: tiene que ser el toque de la esquina
	await _esperar_que(func() -> bool: return not motor.burbujas_en_vuelo().is_empty(), 5.0)
	var bm: BurbujaCortar = motor._burbuja_maxi()
	if bm != null:
		await _esperar_que(func() -> bool: return not is_instance_valid(bm) or bm.t >= bm.duracion(), 3.0)
	_tocar(motor, Vector2(142, 112))
	await _esperar_que(func() -> bool: return libres.size() > antes, 2.0)
	_check(libres.size() == antes + 1, "un toque en una esquina de la zona revienta la burbuja de Maxi")
	await _liberar_motor(motor)


# ---------------------------------------------------------------------------
# 2c. Calcetin de Nicole (no corta) y de Sofia (corta el turno)
# ---------------------------------------------------------------------------

func _probar_calcetin_perfiles() -> void:
	_seccion("calcetin por perfil")
	var ruta := _nivel_qa(func(n: Dictionary) -> void:
		n["perfiles"]["brote"]["calcetin"]["p"] = [1, 1, 1]
		n["perfiles"]["brote"]["calcetin"]["max_tanda"] = [1, 1, 1]
		n["perfiles"]["estrella"]["calcetin"]["p"] = [1, 1, 1])
	var motor := _crear_motor(TRES, ruta)
	var resultados := {}
	var turnos_ids: Array = []
	motor.turnos.turno_iniciado.connect(func(id: String, _p: String) -> void: turnos_ids.append(id))
	var al_cuadro := func() -> void:
		if motor.fase() != "tanda" or not motor._jugable():
			return
		var perfil: String = motor.perfil_turno()
		if perfil == "semilla" or resultados.has(perfil):
			return
		for b in motor.burbujas_en_vuelo():
			var bb := b as BurbujaCortar
			if bb.tipo == "calcetin" and not bb.lenta and bb.position.y < 590:
				var en_aire: int = motor.burbujas_en_vuelo().size()
				var plan: int = motor._cola.size()
				var lib: int = motor.liberados_oleada().size()
				motor.qa_reventar(bb)
				var r := {"cola_antes": plan, "cola": motor._cola.duplicate(), "en_aire": en_aire, "lib": lib, "turnos": turnos_ids.size(),
					"soplido": bb.soplido, "corte": motor._corte_calcetin}
				resultados[perfil] = r
				return
	await _bot(motor, "gana", func() -> bool: return resultados.has("brote") and resultados.has("estrella") and turnos_ids.size() >= 5, 90.0, al_cuadro)
	var rb: Dictionary = resultados.get("brote", {})
	var re: Dictionary = resultados.get("estrella", {})
	_check(not rb.is_empty(), "Nicole se encontro con un calcetin")
	if not rb.is_empty():
		var quedan_otro_soplido := (rb["cola"] as Array).filter(func(e: Dictionary) -> bool: return int(e["soplido"]) != int(rb["soplido"]))
		var quedan_mismo := (rb["cola"] as Array).filter(func(e: Dictionary) -> bool: return int(e["soplido"]) == int(rb["soplido"]) and str(e["tipo"]) != "anticipacion")
		_check(not bool(rb["corte"]) and quedan_mismo.is_empty(), "Brote: el calcetin hace escapar su soplido y el turno sigue")
		_check(int(rb["soplido"]) == 1 or not quedan_otro_soplido.is_empty(), "Brote: el 2.o soplido sale igual")
	_check(not re.is_empty(), "Sofia se encontro con un calcetin")
	if not re.is_empty():
		_check(bool(re["corte"]) and (re["cola"] as Array).is_empty(), "Estrella: el calcetin corta el turno (nada mas por soplar)")
	await _esperar_que(func() -> bool: return turnos_ids.size() > int(re.get("turnos", 0)), 10.0)
	_check(turnos_ids.size() > int(re.get("turnos", 0)) and turnos_ids[int(re.get("turnos", 1))] == "maxi", "tras el corte de Sofia el turno pasa (a Maxi)")
	await _liberar_motor(motor)


# ---------------------------------------------------------------------------
# 3. Bot que gana: 3 oleadas, guardado al vaciar cada piso, victoria
# ---------------------------------------------------------------------------

var _parcial_o1: Dictionary = {}

func _probar_bot_gana() -> void:
	_seccion("bot que gana las 3 oleadas")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	var motor := _crear_motor(TRES)
	var pisos: Array = []
	var guardado_en_piso: Array = []
	var completado: Array = []
	var primeros: Array = []
	var maxi_limpio := [true]
	var ultimo_turno := [""]
	motor.piso_vaciado.connect(func(o: int) -> void:
		pisos.append(o)
		guardado_en_piso.append(_parciales.size()))
	motor.completado.connect(func(d: int) -> void: completado.append(d))
	motor.turnos.turno_iniciado.connect(func(id: String, perfil: String) -> void:
		if motor.frascos_restantes() == motor.canasta_llena() - 1:
			primeros.append(id)
		ultimo_turno[0] = id)
	var vigilar := func() -> void:
		if motor.perfil_turno() == "semilla":
			for b in motor._burbujas:
				if (b as BurbujaCortar).tipo != "animal":
					maxi_limpio[0] = false
	var gano := await _bot(motor, "gana", func() -> bool: return not completado.is_empty(), 240.0, vigilar)
	_check(gano, "el bot gana las 3 oleadas")
	_check(pisos == [1, 2, 3], "piso_vaciado en O1, O2 y O3 (%s)" % str(pisos))
	_check(completado == [0], "completado(0) en la batalla")
	_check(motor.oleadas_ganadas() == ["o1", "o2", "o3"], "oleadas ganadas o1, o2, o3")
	_check(motor._derrotas == 0, "sin derrotas (bot perfecto)")
	_check(primeros.size() >= 3 and primeros.all(func(id: String) -> bool: return id == "maxi"), "cada oleada empieza con Maxi (%s)" % str(primeros))
	_check(maxi_limpio[0], "en los turnos de Maxi nunca hubo calcetin ni power-ups")
	_check("fin_oleada" in _momentos and "gran_estornudo" in _momentos, "momentos fin_oleada y gran_estornudo")
	_check(_momentos.count("fin_oleada") == 2, "fin_oleada solo en O1 y O2")
	# Guardado en el cuadro en que se vacia el piso de O1: la oleada siguiente, sin empezar (caso B).
	var en_o1: Array = _parciales.filter(func(e: Dictionary) -> bool: return int(e.get("oleada", 0)) == 2 and not bool(e.get("oleada_iniciada", true)))
	_check(not en_o1.is_empty(), "al vaciar el piso de O1 se guarda O2 con oleada_iniciada false")
	if not en_o1.is_empty():
		_parcial_o1 = en_o1[0]
		_check(_parcial_o1.get("oleadas_ganadas", []) == ["o1"] and int(_parcial_o1.get("frascos_restantes", 0)) == 9 and int(_parcial_o1.get("etapa", 0)) == 2,
			"el parcial de frontera trae o1 ganada, 9 frascos y etapa 2 (Progreso lo protege)")
	var tanda_cerradas := _parciales.filter(func(e: Dictionary) -> bool: return bool(e.get("oleada_iniciada", false)))
	_check(tanda_cerradas.size() >= 20, "parcial en cada turno_cerrado (%d)" % tanda_cerradas.size())
	var ultima_etapa := 0
	var nunca_baja := true
	for e in _parciales:
		nunca_baja = nunca_baja and int(e.get("etapa", 0)) >= ultima_etapa
		ultima_etapa = int(e.get("etapa", 0))
	_check(nunca_baja, "el parcial nunca vuelve a una oleada ganada")
	await _liberar_motor(motor)


func _probar_retomar_caso_b() -> void:
	_seccion("retomar en el fin de oleada (caso B)")
	if _parcial_o1.is_empty():
		_check(false, "no hay parcial de frontera para probar")
		return
	_saltar_momentos = true
	var motor := _crear_motor(TRES, NIVEL, {"restaurar": _parcial_o1})
	_check(motor.oleada_actual() == 2 and not motor.oleada_iniciada() and motor.frascos_restantes() == 9, "vuelve a O2 sin empezar, con 9 frascos")
	_check(motor.coleccionauta.pisos_vacios == 1, "el piso de O1 sigue vacio")
	var primero := [""]
	motor.turnos.turno_iniciado.connect(func(id: String, _p: String) -> void:
		if primero[0] == "":
			primero[0] = id)
	await _bot(motor, "pierde", func() -> bool: return primero[0] != "", 15.0)
	_check("retomar_burbujeada" in _momentos and "pero_tengo_mas" in motor.voces_dichas, "re-entrada caso B: retomar_burbujeada con «¡Pero tengo mas!»")
	_check(primero[0] == "maxi", "al retomar empieza Maxi")
	await _liberar_motor(motor)


# ---------------------------------------------------------------------------
# 3b. Bot que pierde: gags, ayudas, 30 %, frascos, guardado tras el gag
# ---------------------------------------------------------------------------

var _parcial_tras_gag: Dictionary = {}

func _probar_bot_pierde() -> void:
	_seccion("bot que pierde (solo revienta Maxi)")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	var motor := _crear_motor(TRES)
	var llegadas: Array = []
	var gags: Array = []
	var por_intento := {}
	var info: Array = []
	motor.turnos.rival_llego.connect(func() -> void:
		llegadas.append(motor.turnos.hermano_actual())
		gags.append(motor.variante_derrota())
		info.append({"liberados": motor.liberados_oleada().size(), "intento": motor.intento_actual()}))
	motor.turnos.turno_iniciado.connect(func(id: String, _p: String) -> void:
		var k: int = motor.intento_actual()
		if not por_intento.has(k):
			por_intento[k] = []
		por_intento[k].append(id))
	var conservados: Array = []
	var frascos_intento: Array = []
	var toby: Array = []
	var descanso := [false]
	# Deja correr el gag hasta su final (y 3 s mas para la voz de ayuda) antes de tocar «¡otra vez!».
	var fin := func() -> bool: return llegadas.size() >= 3 and not motor.en_derrota_equipo() and motor.fase() == "tanda"
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 200000 and not fin.call():
		if motor.turnos.en_puerta():
			motor.turnos.abrir_puerta()
		if motor.en_derrota_equipo():
			if motor._gag_terminado:
				var t_gag := Time.get_ticks_msec()
				while Time.get_ticks_msec() - t_gag < 400:
					await process_frame
				if motor._derrotas_oleada >= 3:
					descanso[0] = "ofrece_descanso" in motor.voces_dichas and motor._boton_casa.scale.x > 1.0
				conservados.append(motor.liberados_oleada().size())
				frascos_intento.append(motor.frascos_restantes())
				if llegadas.size() == 1:
					_parcial_tras_gag = _parciales.back().duplicate(true) if not _parciales.is_empty() else {}
				var antes: int = motor.liberados_oleada().size()
				await motor.tocar_otra_vez_equipo()
				toby.append(motor.liberados_oleada().size() - antes)
		elif motor.fase() == "tanda" and motor._jugable() and motor.perfil_turno() == "semilla" and not motor.burbujas_en_vuelo().is_empty():
			_tocar(motor, Vector2(1138, 598))
		await process_frame
	_check(llegadas.size() >= 3, "3 derrotas de la oleada (%d)" % llegadas.size())
	_check(llegadas.all(func(id: String) -> bool: return id == "maxi"), "sin frascos y con animales: rival_llego con Maxi al centro")
	_check(gags.slice(0, 3) == ["burbuja_gorro", "estornudo_jabon", "calcetin_volador"], "gags 1.o-3.o: %s" % str(gags))
	_check(motor._boton_otra_vez_equipo != null, "«¡otra vez!» desde el segundo 0 del gag")
	if motor._boton_otra_vez_equipo != null:
		_check(motor._boton_otra_vez_equipo.size.x >= 160 and motor._boton_otra_vez_equipo.size.y >= 160, "«¡otra vez!» >= 160 x 160 px")
	var i1: Array = por_intento.get(1, [])
	var i2: Array = por_intento.get(2, [])
	_check(i1.size() == 9 and i1.count("maxi") == 5 and i1.count("nicole") == 2 and i1.count("sofia") == 2, "intento 1: 9 frascos = M5 N2 S2 (%s)" % str(i1))
	_check(i2.size() == 13 and i2.count("maxi") == 7 and i2.count("nicole") == 3 and i2.count("sofia") == 3, "intento 2: 13 frascos = M7 N3 S3 (%d)" % i2.size())
	_check(not i1.is_empty() and i1[0] == "maxi" and i1.back() == "maxi" and not i2.is_empty() and i2[0] == "maxi" and i2.back() == "maxi", "cada intento empieza y termina con Maxi")
	if info.size() >= 2 and conservados.size() >= 2:
		_check(conservados[0] == LogicaCortar.conservados(int(info[0]["liberados"]), 0.3), "al reintentar queda el 30 %% de %d = %d" % [int(info[0]["liberados"]), conservados[0]])
		_check(frascos_intento[0] == 13 and frascos_intento[1] == 13, "13 frascos desde la 1.a derrota de la oleada")
	_check("ayuda_jabon" in motor.voces_dichas, "1.a derrota: «¡Le pase mas jabon!»")
	_check(toby.size() >= 2 and toby[0] == 0 and toby[1] == 3 and "ayuda_toby" in motor.voces_dichas, "desde la 2.a derrota Toby revienta 3 al empezar el intento (%s)" % str(toby))
	_check(descanso[0], "desde la 3.a derrota Cometa ofrece descansar y la casa se agranda")
	_check(motor.contar_logro_equipo() == 1, "logro comun: «¡Igual liberamos a un monton!»")
	var tras_gag: Array = _parciales.filter(func(e: Dictionary) -> bool: return int(e.get("intento", 0)) == 2 and int(e.get("frascos_restantes", 0)) == 13)
	_check(not tras_gag.is_empty(), "parcial tras el gag con el intento nuevo (intento 2, 13 frascos)")
	var guardado: Dictionary = _progreso.obtener_parcial_batalla(ID_BATALLA)
	_check(str(guardado.get("ronda", "")) == RONDA and int(guardado.get("etapa", 0)) == 1, "Progreso guarda el parcial en la ronda burbujeada")
	await _liberar_motor(motor)


func _probar_retomar_caso_a() -> void:
	_seccion("retomar a mitad de oleada (caso A)")
	var guardado: Dictionary = _progreso.obtener_parcial_batalla(ID_BATALLA)
	var estado: Dictionary = guardado.get("estado", {})
	_check(not estado.is_empty() and bool(estado.get("oleada_iniciada", false)), "hay un parcial de oleada iniciada")
	var frascos_guardados := int(estado.get("frascos_restantes", 0))
	var motor := _crear_motor(TRES, NIVEL, {"restaurar": estado})
	_check(motor.oleada_actual() == int(estado.get("oleada", 1)) and motor.liberados_oleada() == estado.get("liberados", []), "vuelve a la oleada con sus liberados")
	_check(motor.frascos_restantes() in [5, 9, 13] and motor.frascos_restantes() >= mini(frascos_guardados, 13), "frascos al retomar en {5, 9, 13} (%d guardados -> %d)" % [frascos_guardados, motor.frascos_restantes()])
	var primero := [""]
	motor.turnos.turno_iniciado.connect(func(id: String, _p: String) -> void:
		if primero[0] == "":
			primero[0] = id)
	await _bot(motor, "pierde", func() -> bool: return primero[0] != "", 15.0)
	_check("retomar_burbujeada" in _momentos and "retomar" in motor.voces_dichas, "re-entrada caso A: «¡Seguimos donde quedamos!»")
	_check(primero[0] == "maxi", "al retomar empieza Maxi")
	await _liberar_motor(motor)
	# Un parcial con pocos frascos (salir justo antes del gag) vuelve con 5.
	var poco := estado.duplicate(true)
	poco["frascos_restantes"] = 1
	var m2 := _crear_motor(TRES, NIVEL, {"restaurar": poco})
	_check(m2.frascos_restantes() == 5 and m2._frascos_agregados, "1 frasco guardado -> 5 al retomar («¡Encontre unos frascos mas!»)")
	await _liberar_motor(m2)


# ---------------------------------------------------------------------------
# 4. Revancha
# ---------------------------------------------------------------------------

func _probar_revancha() -> void:
	_seccion("revancha")
	var motor := _crear_motor(TRES, NIVEL, {"revancha": true})
	var resultado: Array = []
	motor.resultado_revancha.connect(func(e: int, r: int) -> void: resultado.append([e, r]))
	var vacio_al_inicio: bool = motor.obtener_parcial_equipo().is_empty()
	_check(vacio_al_inicio, "revancha a mitad de O1: sin parcial")
	var fotos: Array = []
	motor.piso_vaciado.connect(func(_o: int) -> void: fotos.append(_parciales.size()))
	var gano := await _bot(motor, "gana", func() -> bool: return not resultado.is_empty(), 240.0)
	_check(gano and not resultado.is_empty(), "la revancha se gana y emite resultado_revancha")
	if not resultado.is_empty():
		_check(int(resultado[0][0]) >= 2 and int(resultado[0][1]) > 0, "sin derrotas: ★★ o mas y record de frascos (%s)" % str(resultado[0]))
	var solo_frontera := _parciales.all(func(e: Dictionary) -> bool: return not bool(e.get("oleada_iniciada", true)) and e.has("revancha"))
	_check(not _parciales.is_empty() and solo_frontera, "la revancha guarda solo entre oleadas, con sus acumulados")
	_check(not "presenta_burbujeada" in _momentos, "la revancha no repite la presentacion")
	await _liberar_motor(motor)
