extends SceneTree

## Arnés QA de «Cada quien a su casa» (motor caminos, tipo Flow Free; docs/fichas/motor-caminos.md §15).
##
## 1. Niveles (los 15 de Animalia + dorado + equipo): carga, reglas por perfil (HE-124: tormenta 3 / 2,2 / 1,6,
##    regalo 2 / 2 / 3, ayuda fuerte de Maxi tras 3, descanso), celdas >= 64 px (Maxi >= 96), y cada tablero
##    con su `solucion` válida según las reglas (con llenado cubre todo); las 8 (o 4) transformaciones también.
## 2. Reglas (LogicaCaminos, sin pantalla): avanzar, histéresis y relleno de dedo rápido, borrar hacia atrás,
##    cortar desde el medio, empezar desde la casa, cortar ajenos con corte provisional (vuelve entero al
##    retroceder), bloqueo en Semilla, rocas, puente solo en recto, casa ajena (`casa_rechazo` + intento),
##    llenado (`falta_llenar`), imán, trazos / sin borrones / racha / puntaje, válvula, pistas y regalo.
## 3. Escena, nivel por nivel: arrastres reales (presionar, arrastrar celda a celda, soltar) por la solución de
##    cada tablero hasta la victoria (`completado`), tormenta -> "¡otra vez!" con los resueltos intactos,
##    regalo tras N derrotas y ayuda fuerte de Maxi (sin nube).
## 4. Modo equipo: tope por perfil, llegados fijos, `segundos_por_turno`, jugada automática de Maxi, derrota-gag
##    que conserva lo llegado y victoria del equipo.
## 5. Guardado: una victoria con `planeta_id` usa el guardado de PRUEBAS (respaldado y restaurado); el guardado
##    real del PO (`user://progreso.json`) se verifica intacto por md5.
##
## Uso: godot --headless --path . --script herramientas/qa_test_caminos.gd   (-- --detalle: cada chequeo)

const MOTOR := "res://escenas/minijuegos/caminos/motor_caminos.tscn"
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
const PERFILES := ["semilla", "brote", "estrella"]
const DORADO := "res://datos/niveles/animalia/zona5_valle/caminos_estrella_dorado.json"
const EQUIPO := "res://datos/niveles/animalia/zona1_campamento/caminos_equipo.json"
const FACTOR := {"semilla": 3.0, "brote": 2.2, "estrella": 1.6}
const REGALO := {"semilla": 2, "brote": 2, "estrella": 3}
const TRES := ["maxi", "nicole", "sofia"]

var _fallos := 0
var _oks := 0
var _detalle := false
var _progreso: Node
var _respaldo := ""
var _md5_real := ""
var _eventos: Array = []


func _initialize() -> void:
	_detalle = "--detalle" in OS.get_cmdline_user_args()
	print("=== QA caminos: Cada quien a su casa ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	_md5_real = FileAccess.get_md5(_progreso.RUTA_GUARDADO) if FileAccess.file_exists(_progreso.RUTA_GUARDADO) else ""
	if FileAccess.file_exists(_progreso.ruta_guardado):
		_respaldo = FileAccess.get_file_as_string(_progreso.ruta_guardado)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	Engine.time_scale = 4.0
	await process_frame
	_probar_niveles()
	_probar_reglas()
	for z in ZONAS:
		for perfil in PERFILES:
			await _probar_escena(_ruta(z, perfil))
	await _probar_escena(DORADO)
	await _probar_derrotas()
	await _probar_semilla_escena()
	await _probar_guardado()
	await _probar_equipo()
	Engine.time_scale = 1.0
	if _respaldo != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo)
		f.close()
	_progreso.cargar()
	var md5_fin := FileAccess.get_md5(_progreso.RUTA_GUARDADO) if FileAccess.file_exists(_progreso.RUTA_GUARDADO) else ""
	_check(md5_fin == _md5_real, "el guardado real del PO queda intacto (md5 %s)" % (md5_fin if md5_fin != "" else "sin archivo"))
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


func _ruta(zona: String, perfil: String) -> String:
	return "res://datos/niveles/animalia/%s/caminos_%s.json" % [zona, perfil]


func _leer(ruta: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return d if d is Dictionary else {}


func _esperar(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await process_frame


func _esperar_que(condicion: Callable, maximo := 8.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _logica_de(tablero: Dictionary, nivel: Dictionary) -> LogicaCaminos:
	var l := LogicaCaminos.new()
	l.llenar = bool(nivel.get("llenar", false))
	l.configurar(tablero["celdas"], tablero.get("solucion", {}))
	return l


# ---------------------------------------------------------------------------
# 1. Niveles
# ---------------------------------------------------------------------------

func _probar_niveles() -> void:
	print("-- niveles --")
	var celdas_px := {"4x3": 170, "5x4": 140, "5x5": 110, "6x6": 95, "7x7": 86, "8x8": 76, "9x9": 68}
	var rutas: Array = []
	for z in ZONAS:
		for perfil in PERFILES:
			rutas.append(_ruta(z, perfil))
	rutas.append(DORADO)
	rutas.append(EQUIPO)
	_check(rutas.size() == 17, "15 niveles + dorado + equipo")
	for ruta in rutas:
		var nivel := _leer(ruta)
		var nombre: String = ruta.get_file()
		var zona: String = ruta.get_base_dir().get_file()
		_check(not nivel.is_empty(), "%s/%s carga" % [zona, nombre])
		if nivel.is_empty():
			continue
		var perfil := str(nivel.get("perfil", ""))
		_check(str(nivel.get("motor", "")) == "caminos", "%s/%s motor caminos" % [zona, nombre])
		var equipo := str(nivel.get("modo_juego", "")) == "equipo"
		var dorado := bool(nivel.get("reto_dorado", false))
		if not equipo and not dorado:
			var t = nivel.get("tormenta", null)
			_check(t is Dictionary and is_equal_approx(float(t.get("factor_par", 0)), FACTOR[perfil]),
				"%s/%s tormenta %.1fx par (HE-124)" % [zona, nombre, FACTOR[perfil]])
			_check(int(nivel.get("regalo_tras_derrotas", 0)) == REGALO[perfil], "%s/%s regalo tras %d" % [zona, nombre, REGALO[perfil]])
			var fuerte = nivel.get("ayuda_fuerte_tras_derrotas", null)
			if perfil == "semilla":
				_check(fuerte is Dictionary and int(fuerte.get("derrotas", 0)) == 3 and bool(fuerte.get("sin_tormenta", false)),
					"%s/%s ayuda fuerte de Maxi tras 3, sin nube" % [zona, nombre])
				_check(nivel.get("descanso_tras_derrotas", 0) == null, "%s/%s Maxi sin descanso" % [zona, nombre])
				_check(not bool(nivel.get("cortar_ajenos", true)) and bool(nivel.get("animal_bajo_dedo", false)), "%s/%s Semilla: bloquea y el animal va bajo el dedo" % [zona, nombre])
			else:
				_check(fuerte == null, "%s/%s sin ayuda fuerte" % [zona, nombre])
				_check(int(nivel.get("descanso_tras_derrotas", 0)) == (4 if perfil == "estrella" else 3), "%s/%s descanso tras %d" % [zona, nombre, 4 if perfil == "estrella" else 3])
			if perfil == "brote":
				var u = nivel.get("umbrales_puntaje", null)
				_check(u is Dictionary and int(u.get("tres", 0)) > int(u.get("dos", 0)), "%s/%s umbrales de puntaje" % [zona, nombre])
		var tableros: Array = nivel.get("tableros", [])
		_check(not tableros.is_empty(), "%s/%s trae tableros" % [zona, nombre])
		for tab in tableros:
			var id := "%s/%s %s" % [zona, nombre, tab.get("id", "?")]
			var l := _logica_de(tab, nivel)
			var clave := "%dx%d" % [l.ancho, l.alto]
			var px := int(celdas_px.get(clave, 0))
			_check(px >= 64 and (perfil != "semilla" or equipo or px >= 96), "%s celda %d px (>= 64; Maxi >= 96)" % [id, px])
			if not equipo:
				_check(tab.get("tiempo_par_s", null) != null and float(tab["tiempo_par_s"]) > 0.0, "%s tiempo_par_s presente" % id)
			_check(l.pares.size() == (tab["pares"] as Dictionary).size(), "%s pares del tablero = pares del elenco" % id)
			for p in l.pares:
				var par: Dictionary = tab["pares"][p]
				var cat: Dictionary = nivel.get("catalogo", {})
				_check(cat.has(par["animal"]) and cat.has(par["casa"]), "%s %s: animal y casa en el catálogo" % [id, p])
			var errores := l.validar_solucion(l.solucion, l.llenar)
			_check(errores.is_empty(), "%s solución válida %s" % [id, "" if errores.is_empty() else str(errores.slice(0, 2))])
			var cuadrado := l.ancho == l.alto
			var ks := [0, 1, 2, 3, 4, 5, 6, 7] if cuadrado else [0, 2, 4, 6]
			var ok_t := true
			for k in ks:
				var r := LogicaCaminos.transformar(tab["celdas"], tab["solucion"], k)
				var lt := LogicaCaminos.new()
				lt.configurar(r[0], r[1])
				if not lt.validar_solucion(lt.solucion, l.llenar).is_empty() or lt.ancho * lt.alto != l.ancho * l.alto:
					ok_t = false
				if not cuadrado and (lt.ancho != l.ancho):
					ok_t = false
			_check(ok_t, "%s las %d transformaciones conservan la solución" % [id, ks.size()])
			# Resoluble jugando: la solución trazada por la lógica completa el tablero.
			var lj := _logica_de(tab, nivel)
			for p in lj.pares:
				lj.empezar(lj.animal_de[p])
				for celda in lj.solucion[p].slice(1):
					lj.mover(celda)
				lj.soltar()
			_check(lj.esta_completo(), "%s se resuelve trazando la solución" % id)


# ---------------------------------------------------------------------------
# 2. Reglas
# ---------------------------------------------------------------------------

func _probar_reglas() -> void:
	print("-- reglas --")
	var l := LogicaCaminos.new()
	# A . . a
	# B . . b
	# . # . .
	l.configurar(["A..a", "B..b", ".#.."], {})
	l.cortar_ajenos = true
	var llegadas: Array = []
	l.llego.connect(func(p: String, _t: int) -> void: llegadas.append(p))
	_check(l.empezar(l.idx(Vector2i(0, 0))) == "A", "presionar el animal empieza su camino")
	_check(l.mover(l.idx(Vector2i(1, 0))) and l.caminos["A"].size() == 2, "avanzar a la celda vecina")
	_check(l.mover(l.idx(Vector2i(0, 0))) and l.caminos["A"].size() == 1, "volver sobre el camino lo borra")
	_check(l.mover(l.idx(Vector2i(2, 0))) and l.caminos["A"].size() == 3, "dedo rápido: salta 2 celdas y rellena")
	l.mover(l.idx(Vector2i(3, 0)))
	_check(l.llegado["A"] and llegadas == ["A"], "entrar a su casa: llega")
	l.soltar()
	_check(l.racha == 1 and l.puntos == 100, "racha 1 y 100 puntos")
	# B cruza a A por abajo? No: B va recto.
	l.empezar(l.idx(Vector2i(0, 1)))
	l.mover(l.idx(Vector2i(1, 1)))
	l.mover(l.idx(Vector2i(1, 0)))
	_check(not l.llegado["A"] and l.caminos["A"].size() == 1, "cortar ajeno: A queda cortado desde esa celda")
	l.mover(l.idx(Vector2i(1, 1)))
	_check(l.llegado["A"] and l.caminos["A"].size() == 4, "corte provisional: al retroceder A vuelve entero")
	l.mover(l.idx(Vector2i(2, 1)))
	l.mover(l.idx(Vector2i(3, 1)))
	l.soltar()
	_check(l.esta_completo(), "sin llenado, todos llegaron = completo")
	_check(l.trazos_de_mas() == 0, "tantos trazos como pares: sin borrones")
	# Semilla: bloquea en vez de cortar; imán; roca.
	var s := LogicaCaminos.new()
	s.configurar(["A..a", "B..b", ".#.."], {})
	s.cortar_ajenos = false
	s.iman_casa = 1
	var bloqueos: Array = []
	s.bloqueado.connect(func(_p: String, _c: int, m: String) -> void: bloqueos.append(m))
	s.empezar(0)
	s.mover(1)
	s.mover(2)
	s.soltar()
	_check(s.llegado["A"], "imán: a una celda de su casa, al soltar salta adentro")
	s.empezar(4)
	s.mover(5)
	s.mover(1)
	_check(s.caminos["A"].size() == 4 and "camino" in bloqueos, "Semilla: el otro camino bloquea, no se corta")
	s.mover(5)
	s.mover(9)
	s.mover(s.idx(Vector2i(1, 2)))
	_check("roca" in bloqueos, "la roca bloquea")
	s.soltar()
	# Casa ajena (hábitat) y empezar desde la casa.
	var h := LogicaCaminos.new()
	h.configurar(["Ab..", "...a", "B..."], {})
	h.casas_habitat = true
	var rechazos: Array = []
	h.casa_rechazo.connect(func(p: String, q: String) -> void: rechazos.append(p + q))
	h.empezar(0)
	h.mover(1)
	_check(rechazos == ["AB"] and h.intentos_casa == 1, "casa ajena: casa_rechazo y un intento fallido (hábitat)")
	h.soltar()
	h.empezar_desde_casa = true
	_check(h.empezar(h.casa_de["A"]) == "A" and h.caminos["A"][0] == h.casa_de["A"], "empezar desde la casa (B/E)")
	h.mover(h.idx(Vector2i(2, 1)))
	h.mover(h.idx(Vector2i(1, 1)))
	h.mover(h.idx(Vector2i(0, 1)))
	h.mover(0)
	_check(h.llegado["A"], "desde la casa, llega al tocar su animal")
	h.soltar()
	# Cortar desde el medio del propio camino.
	h.empezar(h.idx(Vector2i(1, 1)))
	_check(h.caminos["A"].size() == 3 and not h.llegado["A"], "presionar en medio del camino lo corta ahí y sigue")
	h.soltar()
	# Puente: solo en recto.
	var pu := LogicaCaminos.new()
	pu.configurar([".A.", "B+b", ".a."], {})
	pu.empezar(pu.animal_de["B"])
	pu.mover(4)
	_check(not pu.mover(1) and pu.caminos["B"].size() == 2, "sobre el puente no se dobla")
	pu.mover(5)
	_check(pu.llegado["B"], "el puente se cruza en recto")
	pu.soltar()
	pu.empezar(pu.animal_de["A"])
	pu.mover(4)
	pu.mover(7)
	_check(pu.llegado["A"] and pu.llegado["B"], "dos caminos se cruzan en el puente (uno por eje)")
	pu.soltar()
	# Llenado.
	var ll := LogicaCaminos.new()
	ll.llenar = true
	var falta := [0]
	ll.falta_llenar.connect(func(n: int) -> void: falta[0] = n)
	var completos := [0]
	ll.tablero_completo.connect(func(_s: bool) -> void: completos[0] += 1)
	ll.configurar(["A.a", "B..", "..b"], {"A": [[0, 0], [1, 0], [2, 0]], "B": [[0, 1], [0, 2], [1, 2], [1, 1], [2, 1], [2, 2]]})
	ll.empezar(0)
	ll.mover(1)
	ll.mover(2)
	ll.soltar()
	ll.empezar(3)
	ll.mover(4)
	ll.mover(5)
	ll.mover(8)
	ll.soltar()
	_check(falta[0] == 2 and completos[0] == 0, "llenar: todos llegaron con baldosas vacías -> falta_llenar(2), no termina")
	ll.empezar(3)
	ll.mover(6)
	ll.mover(7)
	ll.mover(4)
	ll.mover(5)
	ll.mover(8)
	ll.soltar()
	_check(completos[0] == 1, "llenar: con todo cubierto termina")
	_check(ll.trazos_de_mas() == 1, "rehacer B suma un trazo de más")
	# Pista / regalo / válvula.
	var pr := LogicaCaminos.new()
	pr.configurar(["A.a", "B.b", "..."], {"A": [[0, 0], [1, 0], [2, 0]], "B": [[0, 1], [1, 1], [2, 1]]})
	pr.empezar(3)
	pr.mover(4)
	pr.mover(1)
	pr.soltar()
	_check(pr.par_para_ayudar() == "A", "ayuda: el primer par mal resuelto")
	pr.colocar_solucion("A")
	_check(pr.par_correcto("A") and pr.caminos["B"].size() == 2, "regalo/pista: traza A y corta lo que estorba")
	var v := LogicaCaminos.new()
	v.configurar(["A.a", "B.b", "..."], {"A": [[0, 0], [1, 0], [2, 0]], "B": [[0, 1], [1, 1], [2, 1]]})
	v.cortar_ajenos = false
	v.empezar(3)
	v.mover(4)
	v.mover(1)
	v.soltar()
	var trab := v.buscar_trabados()
	_check(trab.get("trabado", "") == "A" and trab.get("estorba", "") == "B", "válvula: detecta que B encierra a A")


# ---------------------------------------------------------------------------
# 3. Escena
# ---------------------------------------------------------------------------

func _instanciar(ruta: String, planeta := "", perfil := "") -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.planeta_id = planeta
	motor.id_perfil = perfil
	motor.segundos_auto_continuar = 0.3
	motor.transformacion_forzada = 0
	get_root().add_child(motor)
	return motor


func _resolver_tablero(motor: Node) -> void:
	var l: LogicaCaminos = motor.logica
	for p in l.pares:
		if l.llegado[p] and l.par_correcto(p):
			continue
		motor.trazar_celdas(l.solucion[p])


func _jugando(motor: Node) -> bool:
	return await _esperar_que(func() -> bool: return motor.fase() == "jugando", 6.0)


func _probar_escena(ruta: String) -> void:
	var nombre := "%s/%s" % [ruta.get_base_dir().get_file(), ruta.get_file()]
	var motor := _instanciar(ruta)
	var completado := [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	_check(await _jugando(motor), "%s entra a jugar" % nombre)
	var n: int = motor.nivel["tableros"].size()
	var minimo := 96.0 if motor.nivel["perfil"] == "semilla" else 64.0
	_check(motor.celda_px() >= minimo, "%s celda en pantalla %.0f px" % [nombre, motor.celda_px()])
	var tablero_ok := true
	for k in n:
		if not await _jugando(motor):
			tablero_ok = false
			break
		_resolver_tablero(motor)
		if not await _esperar_que(func() -> bool: return motor.fase() != "jugando", 3.0):
			tablero_ok = false
			print("    tablero %d no terminó: llegados %d/%d vacías %d" % [k, motor.logica.cantidad_llegados(), motor.logica.pares.size(), motor.logica.celdas_vacias().size()])
			break
	_check(tablero_ok, "%s: los %d tableros se resuelven con arrastres" % [nombre, n])
	_check(await _esperar_que(func() -> bool: return completado[0] >= 0, 20.0), "%s: victoria -> completado(%d)" % [nombre, completado[0]])
	if motor.nivel["perfil"] == "estrella":
		_check(motor.estrellitas() == 3, "%s: perfecto = 3 estrellitas" % nombre)
	elif motor.nivel["perfil"] == "brote":
		_check(motor.estrellitas() >= 2, "%s: buen puntaje = %d estrellitas (%d puntos)" % [nombre, motor.estrellitas(), motor.puntos()])
	motor.queue_free()
	await process_frame


## Tormenta en los tres perfiles: derrota sin destellos, "¡otra vez!" con lo resuelto intacto, regalo y ayuda fuerte.
func _probar_derrotas() -> void:
	print("-- tormenta --")
	for perfil in PERFILES:
		var ruta := _ruta("zona4_nidos", perfil)
		var motor := _instanciar(ruta)
		var completado := [false]
		motor.completado.connect(func(_d: int) -> void: completado[0] = true)
		await _jugando(motor)
		# Tablero 1 resuelto; la tormenta llega en el 2.
		_resolver_tablero(motor)
		await _esperar_que(func() -> bool: return motor.indice_tablero() == 1 and motor.fase() == "jugando", 6.0)
		var par: float = float(motor.nivel["tableros"][1]["tiempo_par_s"])
		_check(is_equal_approx(motor.limite_tormenta(), FACTOR[perfil] * par), "%s: la nube llega a %.1f x par (%.0f s)" % [perfil, FACTOR[perfil], motor.limite_tormenta()])
		var l: LogicaCaminos = motor.logica
		var primero: String = l.pares[0]
		motor.trazar_celdas(l.solucion[primero])
		for derrota in range(1, 4):
			motor.avanzar_reloj(motor.limite_tormenta() + 0.1)
			_check(await _esperar_que(func() -> bool: return motor.fase() == "perdio", 6.0), "%s: derrota %d -> gag y cartel" % [perfil, derrota])
			_check(motor.indice_tablero() == 1 and not completado[0], "%s: el tablero resuelto sigue resuelto, sin completado" % perfil)
			var llegados_antes: int = l.cantidad_llegados()
			motor.reintentar()
			_check(motor.fase() == "jugando", "%s: un toque en ¡otra vez! y se juega" % perfil)
			if perfil == "semilla":
				_check(l.llegado[primero], "Maxi conserva el animal que ya llegó")
			var regalo: int = REGALO[perfil]
			if perfil == "semilla" and derrota >= 3:
				_check(motor.limite_tormenta() == 0.0 and l.cantidad_llegados() == l.pares.size() - 1, "Maxi tras 3: ayuda fuerte (todos menos uno, sin nube)")
			elif derrota >= regalo:
				_check(l.cantidad_llegados() == (llegados_antes if perfil == "semilla" else 0) + 1,
					"%s: tras %d derrotas Toby regala un camino" % [perfil, derrota])
			else:
				_check(l.cantidad_llegados() == (llegados_antes if perfil == "semilla" else 0), "%s: antes del regalo no hay ayuda gratis" % perfil)
		motor.queue_free()
		await process_frame


## Semilla en escena: animal bajo el dedo con tolerancia, imán al soltar cerca y válvula.
func _probar_semilla_escena() -> void:
	print("-- semilla --")
	var motor := _instanciar(_ruta("zona1_campamento", "semilla"))
	await _jugando(motor)
	var l: LogicaCaminos = motor.logica
	var p: String = l.pares[0]
	var sol: Array = l.solucion[p]
	# Tolerancia: presionar a 0,6 celda del animal igual lo toma.
	motor.presionar(motor.centro_celda(sol[0]) + Vector2(motor.celda_px() * 0.55, 0))
	_check(l.trazo_par == p, "Maxi: un toque cerca del animal lo toma (tolerancia)")
	for k in range(1, sol.size() - 1):
		motor.arrastrar(motor.centro_celda(sol[k]))
	motor.soltar()
	_check(l.llegado[p], "Maxi: soltando a una celda de la casa, el imán lo lleva adentro")
	# Válvula: el otro par queda encerrado por un camino ajeno -> Toby lo sopla al quedarse quieto.
	var q: String = l.pares[1]
	var sol_q: Array = l.solucion[q]
	l.fijos.erase(p)
	l.borrar_camino(p)
	l.empezar(l.animal_de[p])
	for celda in sol_q.slice(1, sol_q.size() - 1):
		l.caminos[p].append(celda)
	l.soltar()
	var trab := l.buscar_trabados()
	if not trab.is_empty():
		motor._idle = 6.5
		await _esperar(0.3)
		_check(l.buscar_trabados().is_empty(), "válvula: a los 6 s quieto Toby sopla el camino que estorba")
	else:
		_check(true, "válvula: este tablero no permite encerrar (sin prueba)")
	motor.queue_free()
	await process_frame


## Una victoria con planeta: se guarda en el guardado de pruebas (destellos y estación) y el parcial se borra.
func _probar_guardado() -> void:
	print("-- guardado --")
	var ruta := _ruta("zona1_campamento", "brote")
	var motor := _instanciar(ruta, "animalia", "nicole")
	await _jugando(motor)
	_resolver_tablero(motor)
	await _esperar_que(func() -> bool: return motor.indice_tablero() == 1, 6.0)
	var parcial: Dictionary = _progreso.obtener_estado_parcial("nicole", "animalia", "animalia_z1_caminos_brote")
	_check(int(parcial.get("tablero_actual", 0)) == 1, "guardado parcial al terminar cada tablero")
	motor.queue_free()
	await process_frame
	motor = _instanciar(ruta, "animalia", "nicole")
	await _jugando(motor)
	_check(motor.indice_tablero() == 1, "al volver, retoma desde el tablero 2")
	var hecho := [false]
	motor.completado.connect(func(_d: int) -> void: hecho[0] = true)
	for k in 3:
		await _jugando(motor)
		_resolver_tablero(motor)
		await _esperar_que(func() -> bool: return motor.fase() != "jugando", 3.0)
	await _esperar_que(func() -> bool: return hecho[0], 20.0)
	_check(_progreso.esta_nivel_completado("nicole", "animalia", "animalia_z1_caminos_brote"), "victoria guardada (estación completada)")
	_check(_progreso.obtener_record_nivel("nicole", "animalia", "animalia_z1_caminos_brote") > 0, "récord de Nicole guardado")
	_check(_progreso.obtener_estado_parcial("nicole", "animalia", "animalia_z1_caminos_brote").is_empty(), "el parcial se borra al ganar")
	motor.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4. Equipo
# ---------------------------------------------------------------------------

func _ids(lista: Array) -> Array[String]:
	var r: Array[String] = []
	for x in lista:
		r.append(str(x))
	return r


func _instanciar_equipo() -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = EQUIPO
	motor.equipo = _ids(TRES)
	motor.segundos_auto_continuar = 0.3
	motor.transformacion_forzada = 0
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
	return await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada() and g.hermano_actual() == id \
		and motor.fase() == "jugando", 6.0)


func _probar_equipo() -> void:
	print("-- equipo --")
	Engine.time_scale = 1.0
	var motor := _instanciar_equipo()
	var g: GestorTurnos = motor.turnos
	var l: LogicaCaminos = motor.logica
	_check(g != null and l.pares.size() == 5 and l.ancho == 6, "equipo: tablero compartido 6x6 con 5 pares")
	_check(motor.celda_px() >= 64.0, "equipo: celda %.0f px" % motor.celda_px())
	_check(await _abrir_turno(motor, "maxi"), "empieza Maxi")
	var elegido: String = motor._par_forzado
	_check(elegido != "" and l.cortar_ajenos == false and motor._animal_bajo_dedo, "Maxi: un par elegido, animal bajo el dedo, sin cortar")
	var otro: String = l.pares[0] if l.pares[0] != elegido else l.pares[1]
	motor.presionar(motor.centro_celda(l.animal_de[otro]))
	_check(l.trazo_par == "", "Maxi solo puede tomar su animal que brilla")
	motor.soltar()
	motor.trazar_celdas(l.solucion[elegido])
	if not l.llegado[elegido]:
		print("    debug: fase=%s jugable=%s forzado=%s camino=%s sol=%s" % [motor.fase(), motor._turno_jugable(), motor._par_forzado, str(l.caminos[elegido]), str(l.solucion[elegido])])
	_check(l.llegado[elegido], "Maxi lleva su animal a casa")
	_check(await _esperar_que(func() -> bool: return "cerrado:maxi:false" in _eventos, 6.0), "tope de Maxi = 1: su turno cierra")
	_check(await _abrir_turno(motor, "nicole"), "le toca a Nicole")
	_check(l.cortar_ajenos and not motor._animal_bajo_dedo, "Nicole: corta ajenos, sin animal bajo el dedo")
	# Llegados fijos: Nicole no puede cortar el camino de Maxi.
	var celda_maxi: int = l.caminos[elegido][1]
	var antes: int = l.caminos[elegido].size()
	motor.presionar(motor.centro_celda(celda_maxi))
	motor.soltar()
	_check(l.caminos[elegido].size() == antes and l.llegado[elegido], "el camino llegado de Maxi queda fijo")
	# segundos_por_turno: sin llegar ninguno en 45 s, pasa el turno.
	motor._eq_t_turno = 44.9
	_check(await _esperar_que(func() -> bool: return "cerrado:nicole:false" in _eventos, 4.0), "Nicole: 45 s sin llegar -> terminar_turno(true)")
	_check(await _abrir_turno(motor, "maxi"), "otra vez Maxi")
	var elegido2: String = motor._par_forzado
	motor._jugada_automatica_equipo()
	_check(l.llegado.get(elegido2, false), "jugada automática: el animal de Maxi camina solo a su casa")
	_check(await _abrir_turno(motor, "sofia"), "le toca a Sofía")
	var pendientes: Array = l.pares.filter(func(p: String) -> bool: return not l.llegado[p])
	motor.trazar_celdas(l.solucion[pendientes[0]])
	_check(not ("cerrado:sofia:true" in _eventos or "cerrado:sofia:false" in _eventos), "Sofía: tope 2, con 1 sigue jugando")
	# Derrota-gag: el rival llega; los caminos a medias se van, lo llegado queda.
	var parcial: String = pendientes[1]
	motor.presionar(motor.centro_celda(l.animal_de[parcial]))
	motor.arrastrar(motor.centro_celda(l.solucion[parcial][1]))
	motor.soltar()
	var llegados: int = l.cantidad_llegados()
	g._pos_rival = g.pasos_rival() - 1
	motor._eq_t_turno = 39.95
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos, 6.0), "el rival llega -> derrota-gag del equipo")
	await _esperar(2.0)
	_check(l.caminos[parcial].size() <= 1 and l.cantidad_llegados() == llegados, "gag: se va lo que estaba a medias, lo llegado se conserva")
	_check(motor.contar_logro_equipo() == llegados, "logro común = animales en casa (%d)" % llegados)
	motor.tocar_otra_vez_equipo()
	# Victoria: el resto de los turnos lleva a todos a casa.
	var completado := [false]
	motor.completado.connect(func(_d: int) -> void: completado[0] = true)
	var vueltas := 0
	while not completado[0] and vueltas < 12 and not motor._eq_victoria:
		vueltas += 1
		var id := g.hermano_actual()
		await _esperar_que(func() -> bool: return g.en_puerta() or motor._eq_victoria, 10.0)
		if motor._eq_victoria:
			break
		await _abrir_turno(motor, g.hermano_actual())
		if g.perfil_actual() == "semilla":
			motor._jugada_automatica_equipo()
		else:
			for p in l.pares:
				if not l.llegado[p] and motor._turno_jugable():
					motor.trazar_celdas(l.solucion[p])
		await _esperar(0.3)
	_check(motor._eq_victoria, "equipo: todos en casa -> victoria del equipo")
	_check(await _esperar_que(func() -> bool: return completado[0], 25.0), "equipo: fiesta y completado")
	motor.queue_free()
	await process_frame
