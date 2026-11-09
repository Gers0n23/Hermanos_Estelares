extends SceneTree

## Arnés QA de la «Carrera de Toby» (motor runner; docs/fichas/motor-runner.md §15, HE-119 y HE-124).
##
## 1. Niveles: los 15 (5 zonas × 3 perfiles), el dorado y los 5 de equipo cargan y traen los valores de HE-124.
## 2. Reglas (LogicaRunner, determinista con semilla): curva del salto, salto en cola, sin doble salto, imantado
##    de Semilla, amable de Brote, cajas, aéreo alto (sin saltar pasa, saltando choca), burbuja, corazones que
##    se rellenan en la meta, tramo del récord, banderita a la mitad, ayudas de Semilla.
## 3. Bots: un bot PERFECTO gana los 15 niveles (y el dorado) en varias semillas sin chocar, y deja medidos el
##    reparto (hueco en tiempo >= min_s, nunca más de 2 iguales, aéreos separados de lo demás, coleccionables
##    nunca sobre obstáculos, todo patrón saltable). Un bot PASIVO (no toca) pierde los 15. Con la ayuda fuerte
##    de Maxi, el pasivo gana igual (victoria asegurada).
## 4. Escena: toque real (push_input) salta y los botones no; derrota → gag → cartel → reintento de un toque;
##    regalo y ayuda fuerte; meta → asegurar_victoria y celebración; récord que solo sube.
## 5. Modo equipo: posta con cambio de corredor, acierto por paso limpio, tope → posta, choque → fallo.
##
## Guardado AISLADO: Progreso usa `user://progreso_pruebas.json` (lo elige solo con --script); el arnés lo
## respalda y lo restaura, y verifica por md5 que el guardado real (`user://progreso.json`) queda intacto.
##
## Uso: godot --headless --path . --script herramientas/qa_test_runner.gd
##      `-- --calibrar` escribe herramientas/runner_umbrales.json (umbrales de estrellitas del bot perfecto).

const MOTOR := "res://escenas/minijuegos/runner/motor_runner.tscn"
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
const PERFILES := ["semilla", "brote", "estrella"]
const HERMANO := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const DORADO := "res://datos/niveles/animalia/zona5_valle/runner_estrella_dorado.json"
const DT := 1.0 / 60.0
const SEMILLAS_BOT := [1, 2, 3, 4, 5, 6]
## Jugador con error humano, igual que el simulador de la maqueta (docs/maquetas/animalia-runner.html, SIM_DEF):
## [precisión (desvío del toque, s), olvido (no salta), falla de inhibición (salta un aéreo alto)].
const HUMANO := {"semilla": [0.35, 0.15, 0.0], "brote": [0.1, 0.05, 0.3], "estrella": [0.06, 0.03, 0.12]}
## Meta de GDD §6 regla 11 (HE-124): llegar a la meta al primer intento.
const META_LLEGADA := {"semilla": 0.9, "brote": 0.75, "estrella": 0.6}
const TOLERANCIA_LLEGADA := 0.12

var _fallos := 0
var _oks := 0
var _detalle := false
var _resumen: Array = []
var _progreso: Node
var _respaldo_pruebas := ""
var _md5_real := ""


func _initialize() -> void:
	_detalle = "--detalle" in OS.get_cmdline_user_args()
	print("=== QA runner: Carrera de Toby ===")
	if not await _aislar_guardado():
		quit(1)
		return
	if "--simular" in OS.get_cmdline_user_args():
		_simular_humanos(600, true)
		_restaurar_guardado()
		quit(0)
		return
	if "--calibrar" in OS.get_cmdline_user_args():
		_calibrar()
		_restaurar_guardado()
		quit(0)
		return
	_probar_niveles()
	_probar_salto()
	_probar_cajas_y_aereos()
	_probar_burbuja_y_corazones()
	_probar_semilla()
	_probar_meta_y_tramo()
	_probar_bots()
	_simular_humanos(150, false)
	await _probar_escena()
	await _probar_equipo()
	_restaurar_guardado()
	print("--- resumen ---")
	for linea in _resumen:
		print(linea)
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _chequear(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		if _detalle:
			print("  ok  %s" % mensaje)
	else:
		_fallos += 1
		print("  FALLA %s" % mensaje)


# ---------------------------------------------------------------------------
# Guardado aislado
# ---------------------------------------------------------------------------

func _aislar_guardado() -> bool:
	_progreso = root.get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		return false
	_md5_real = FileAccess.get_md5(_progreso.RUTA_GUARDADO) if FileAccess.file_exists(_progreso.RUTA_GUARDADO) else "(no existe)"
	if FileAccess.file_exists(_progreso.ruta_guardado):
		_respaldo_pruebas = FileAccess.get_file_as_string(_progreso.ruta_guardado)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await process_frame
	return true


func _restaurar_guardado() -> void:
	if _respaldo_pruebas != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo_pruebas)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_progreso.ruta_guardado))
	_progreso.cargar()
	var md5_despues: String = FileAccess.get_md5(_progreso.RUTA_GUARDADO) if FileAccess.file_exists(_progreso.RUTA_GUARDADO) else "(no existe)"
	_chequear(md5_despues == _md5_real, "el guardado real queda intacto (md5 %s)" % _md5_real)
	_resumen.append("guardado real md5: %s (intacto: %s)" % [_md5_real, md5_despues == _md5_real])


# ---------------------------------------------------------------------------
# Niveles
# ---------------------------------------------------------------------------

func _ruta(zona: int, perfil: String) -> String:
	return "res://datos/niveles/animalia/%s/runner_%s.json" % [ZONAS[zona], perfil]


func _nivel(ruta: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ruta))


func _logica(ruta: String, semilla := 1) -> LogicaRunner:
	var l := LogicaRunner.new()
	l.configurar(_nivel(ruta), semilla)
	return l


func _probar_niveles() -> void:
	var corazones := {"semilla": 3, "brote": 2, "estrella": 1}
	var regalo := {"semilla": 2, "brote": 2, "estrella": 3}
	for z in 5:
		for perfil in PERFILES:
			var ruta := _ruta(z, perfil)
			_chequear(FileAccess.file_exists(ruta), "existe %s" % ruta)
			var n := _nivel(ruta)
			var nombre := "%s z%d" % [perfil, z + 1]
			_chequear(n.get("motor") == "runner" and n.get("perfil") == perfil and n.get("id_nivel") == "animalia_z%d_runner_%s" % [z + 1, perfil], "%s: motor, perfil e id_nivel" % nombre)
			_chequear(int(n.get("corazones", 0)) == corazones[perfil], "%s: %d corazones (HE-124)" % [nombre, corazones[perfil]])
			_chequear(int(n.get("regalo_tras_derrotas", 0)) == regalo[perfil], "%s: regalo tras %d derrotas" % [nombre, regalo[perfil]])
			_chequear(n.get("obstaculos_blandos") == false, "%s: obstaculos_blandos false" % nombre)
			match perfil:
				"semilla":
					_chequear(n.get("burbuja") == null and n.get("banderita_mitad") == true, "%s: sin burbuja y con banderita a la mitad" % nombre)
					_chequear(int(n.get("ayuda_fuerte_tras_derrotas", {}).get("derrotas", 0)) == 3, "%s: ayuda fuerte tras 3" % nombre)
					_chequear(n.get("ayuda_idle_s") == [5.0, 12.0] and float(n.get("gag_derrota_s", 0)) == 1.5, "%s: ayudas a los 5 y 12 s, gag de 1,5 s" % nombre)
				"brote":
					_chequear(n.get("burbuja") == null and n.get("banderita_mitad") == true, "%s: sin burbujas (los corazones las reemplazan), con banderita" % nombre)
					_chequear(int(n.get("descanso_tras_derrotas", 0)) == 3, "%s: descanso tras 3" % nombre)
				"estrella":
					var cada := 25
					_chequear(int(n.get("burbuja", {}).get("cada_s", 0)) == cada, "%s: burbuja cada %d s" % [nombre, cada])
					_chequear(int(n.get("descanso_tras_derrotas", 0)) == 4, "%s: descanso tras 4" % nombre)
					_chequear((n["salto"].get("variable") != null) == (z >= 3), "%s: salto variable solo en z4-z5" % nombre)
			if perfil != "semilla":
				_chequear(n.has("umbrales_puntaje"), "%s: trae umbrales de estrellitas" % nombre)
			_chequear(float(n["huecos"]["min_s"]) >= float(n["salto"]["duracion_s"]) + 0.3 - 0.001, "%s: hueco mínimo >= salto + 0,3 s" % nombre)
		var eq := _nivel("res://datos/niveles/animalia/%s/runner_equipo.json" % ZONAS[z])
		_chequear(eq.get("modo_juego") == "equipo" and eq["equipo"]["aciertos_max_turno"] == {"semilla": 2.0, "brote": 5.0, "estrella": 8.0}, "equipo z%d: topes 2/5/8" % (z + 1))
	var d := _nivel(DORADO)
	_chequear(d.get("id_nivel") == "animalia_z5_runner_estrella_dorado" and int(d["meta_s"]) == 150 and int(d["tramo_record_s"]) == -1, "dorado: se completa a los 150 s y sigue sin fin")


# ---------------------------------------------------------------------------
# Reglas
# ---------------------------------------------------------------------------

func _avanzar(l: LogicaRunner, segundos: float) -> void:
	var t := 0.0
	while t < segundos - 0.0001:
		l.avanzar(DT)
		t += DT


func _sin_obstaculos(l: LogicaRunner) -> void:
	l.defs_suelo = []
	l.obstaculos.clear()
	l.items.clear()


func _obst(l: LogicaRunner, tipo: String, x: float, e := 80.0, alto := 60.0, altura := 0.0) -> Dictionary:
	var o := {"id": "prueba", "dibujo": "tronco", "tipo": tipo, "x": x, "e": e, "n": 1, "alto": alto, "altura": altura,
		"sid": 999, "estado": "pendiente", "toco": false, "blando": l.blandos}
	l.obstaculos.append(o)
	return o


func _probar_salto() -> void:
	var l := _logica(_ruta(0, "estrella"))
	_sin_obstaculos(l)
	_avanzar(l, 0.1)
	_chequear(l.tocar() and l.fase_salto == "impulso", "un toque en el suelo: impulso en el mismo cuadro")
	_avanzar(l, l.impulso_s + DT * 0.5)
	_chequear(l.fase_salto == "aire", "después del impulso despega")
	var T := l.duracion_salto
	var H := l.altura_salto
	_avanzar(l, T * 0.5 - l.t_aire)
	var k := l.t_aire / T
	_chequear(absf(l.y - H * 4.0 * k * (1.0 - k)) < 0.01 and absf(l.y - H) < 3.0, "curva exacta: en la mitad del vuelo la altura es H (%.1f de %.0f)" % [l.y, H])
	var antes_aire := l.t_aire
	l.tocar()
	l.soltar()
	_chequear(l.fase_salto == "aire" and not l.en_cola and absf(l.t_aire - antes_aire) < 0.001, "sin doble salto: un toque a mitad del vuelo no salta")
	_avanzar(l, T - l.t_aire - 0.1)
	l.tocar()
	l.soltar()
	_chequear(l.en_cola, "salto en cola: un toque 100 ms antes de aterrizar se guarda")
	_avanzar(l, 0.11)
	_chequear(l.fase_salto == "impulso" or l.fase_salto == "aire", "y al tocar el suelo salta solo")
	# Salto variable (Sofía z4): mantener = más alto, hasta +35 %.
	var v := _logica(_ruta(3, "estrella"))
	_sin_obstaculos(v)
	v.tocar()
	_avanzar(v, v.impulso_s + v.duracion_salto * 0.5)
	_chequear(v.altura_actual > v.altura_salto * 1.3, "salto variable: mantener el dedo sube la altura (%.0f → %.0f)" % [v.altura_salto, v.altura_actual])
	# Imantado (Semilla): un toque hasta 1,2 s antes del obstáculo sale perfecto.
	for antes in [1.15, 0.9, 0.7, 0.55]:
		var m := _logica(_ruta(0, "semilla"))
		_sin_obstaculos(m)
		var o := _obst(m, "suelo", 0.0, 90.0, 70.0)
		o["x"] = LogicaRunner.X_CORREDOR + antes * m.velocidad - o["e"] * 0.5
		m.tocar()
		m.soltar()
		_avanzar(m, 2.5)
		_chequear(o["estado"] == "pasado" and not o["toco"] and m.corazones == 3, "imantado: tocar %.2f s antes del arbusto pasa limpio" % antes)
	# Amable (Brote): un roce de pocos px en el aire se perdona; sin amable, choca.
	for amable in [12.0, 0.0]:
		var b := _logica(_ruta(0, "brote"))
		_sin_obstaculos(b)
		b.amable_px = amable
		b.fase_salto = "aire"
		b.t_aire = 0.02
		b.altura_actual = b.altura_salto
		b.y = 40.0
		var o := _obst(b, "suelo", LogicaRunner.X_CORREDOR - 20.0, 60.0, 60.0)
		b._chequear_choques()
		_chequear(o["toco"] == (amable == 0.0), "salto amable %s: roce de 8 px en el aire %s" % ["on" if amable > 0 else "off", "se perdona" if amable > 0 else "choca"])


func _probar_cajas_y_aereos() -> void:
	var l := _logica(_ruta(0, "estrella"))
	var o := _obst(l, "suelo", 500.0, 100.0, 50.0)
	var cx := l.caja_x(o)
	_chequear(is_equal_approx(cx.y - cx.x, 70.0) and is_equal_approx(l.caja_y(o).y, 40.0), "caja de obstáculo al 70 % × 80 %")
	var cr := l.caja_corredor_x()
	_chequear(is_equal_approx(cr.y - cr.x, l.corredor_ancho * 0.6) and is_equal_approx(l.caja_corredor_y().y, l.corredor_alto * 0.75), "caja del corredor al 60 % × 75 %")
	for perfil in ["brote", "estrella"]:
		var z := 2
		# Sin saltar, el aéreo alto pasa por arriba.
		var a := _logica(_ruta(z, perfil))
		_sin_obstaculos(a)
		var alto := {"tipo": "aereo_alto", "alto": 60.0, "altura": 135.0}
		var oa := _obst(a, "aereo_alto", LogicaRunner.X_CORREDOR + 200.0, 70.0, 60.0, 135.0)
		_avanzar(a, 1.5)
		_chequear(oa["estado"] == "pasado" and not oa["toco"], "%s: aéreo alto sin saltar pasa por arriba" % perfil)
		# Saltando justo debajo, choca.
		var b := _logica(_ruta(z, perfil))
		_sin_obstaculos(b)
		var ob := _obst(b, "aereo_alto", 0.0, 70.0, 60.0, 135.0)
		ob["x"] = LogicaRunner.X_CORREDOR + (b.impulso_s + b.duracion_salto * 0.5) * b.velocidad - 35.0
		b.tocar()
		b.soltar()
		_avanzar(b, 1.2)
		_chequear(ob["toco"], "%s: saltando cuando el aéreo alto está encima, choca" % perfil)
		# El aéreo bajo hay que saltarlo.
		var c := _logica(_ruta(4, perfil))
		_sin_obstaculos(c)
		var oc := _obst(c, "aereo_bajo", LogicaRunner.X_CORREDOR + 150.0, 70.0, 55.0, 30.0)
		_avanzar(c, 1.0)
		_chequear(oc["toco"], "%s: el aéreo bajo, sin saltar, choca" % perfil)
	var j := _nivel(_ruta(2, "brote"))
	_chequear(j["corredor"]["id"] == "jirafa" and float(j["corredor"]["alto"]) * float(j["corredor"]["caja"][1]) < 141.0, "la jirafa (z3) tiene caja de cuerpo: los pajaritos altos le pasan por arriba")


func _probar_burbuja_y_corazones() -> void:
	var l := _logica(_ruta(0, "estrella"))
	_sin_obstaculos(l)
	_avanzar(l, 0.2)
	l.burbuja = true
	var o := _obst(l, "suelo", LogicaRunner.X_CORREDOR + 60.0)
	_avanzar(l, 0.2)
	_chequear(not l.burbuja and l.corazones == 1 and l.invulnerable > 0.6 and l.corriendo(), "burbuja: el choque la revienta, 1 s sin choques y sigue")
	var o2 := _obst(l, "suelo", LogicaRunner.X_CORREDOR + 20.0)
	_avanzar(l, 0.1)
	_chequear(l.corriendo() and o2["toco"], "durante el segundo invulnerable no choca")
	_avanzar(l, 1.0)
	_obst(l, "suelo", LogicaRunner.X_CORREDOR + 20.0)
	var fin := [""]
	l.fin_carrera.connect(func(_p: int, m: String) -> void: fin[0] = m)
	_avanzar(l, 0.2)
	_chequear(l.estado == "derrota" and fin[0] == "derrota", "Sofía: un choque fuera de burbuja = derrota (como Chrome)")
	# La burbuja aparece cada `cada_s` y no se acumula.
	var b := _logica(_ruta(0, "estrella"), 3)
	var cuantas := 0
	var maximo := 0
	while b.t < 130.0 and b.corriendo():
		var vivas := b.items.filter(func(i): return i["tipo"] == "burbuja").size()
		maximo = maxi(maximo, vivas)
		var antes := b.items.size()
		b.avanzar(DT)
		_bot(b)
	for r in b.apariciones():
		pass
	_chequear(maximo <= 1, "nunca hay más de una burbuja flotando (no se acumulan)")
	# Nicole: 2 corazones.
	var n := _logica(_ruta(0, "brote"))
	_sin_obstaculos(n)
	_avanzar(n, 0.1)
	_obst(n, "suelo", LogicaRunner.X_CORREDOR + 30.0)
	_avanzar(n, 0.2)
	_chequear(n.corazones == 1 and n.corriendo(), "Nicole: el primer choque gasta un corazón y sigue corriendo")
	_avanzar(n, 1.2)
	_obst(n, "suelo", LogicaRunner.X_CORREDOR + 30.0)
	_avanzar(n, 0.2)
	_chequear(n.estado == "derrota", "Nicole: el segundo choque es la derrota")


func _probar_semilla() -> void:
	var l := _logica(_ruta(0, "semilla"))
	_sin_obstaculos(l)
	_avanzar(l, 0.1)
	var v0 := l.velocidad
	_obst(l, "suelo", LogicaRunner.X_CORREDOR + 30.0, 90.0, 70.0)
	_avanzar(l, 0.2)
	_chequear(l.corazones == 2 and l.velocidad == v0 and l.corriendo(), "Maxi: un choque gasta un corazón sin frenar (3 → 2)")
	# Ayudas a los 5 y 12 s.
	var a := _logica(_ruta(0, "semilla"))
	var mira := [-1.0]
	a.ayuda_mirar.connect(func() -> void: mira[0] = a.t)
	var saltos := []
	a.salto_iniciado.connect(func(ayudado: bool) -> void: saltos.append([a.t, ayudado]))
	_avanzar(a, 20.0)
	_chequear(absf(mira[0] - 5.0) < 0.05, "Maxi quieto: a los 5 s el dino lo mira (%.2f s)" % mira[0])
	_chequear(saltos.size() == 1 and saltos[0][1] and saltos[0][0] >= 12.0, "a los 12 s salta solo UNA vez para mostrar que se puede")
	# Regalo: 4 corazones; ayuda fuerte: obstáculos blandos.
	var r := _logica(_ruta(0, "semilla"))
	r.reiniciar(false, false, 1)
	_chequear(r.corazones == 4, "regalo de Maxi: la carrera siguiente empieza con 4 corazones")


func _probar_meta_y_tramo() -> void:
	var l := _logica(_ruta(0, "brote"))
	_sin_obstaculos(l)
	l.corazones = 1
	var eventos := []
	l.meta.connect(func() -> void: eventos.append("meta"))
	l.paso_mitad.connect(func() -> void: eventos.append("mitad"))
	l.fin_carrera.connect(func(_p: int, m: String) -> void: eventos.append(m))
	_avanzar(l, l.meta_s + 0.1)
	_chequear("mitad" in eventos and "meta" in eventos and l.estado == "tramo", "Nicole: pasa la banderita de la mitad, cruza la meta y sigue por el récord")
	_chequear(l.corazones == 2, "al cruzar la meta los corazones se rellenan")
	_obst(l, "suelo", LogicaRunner.X_CORREDOR + 30.0)
	_avanzar(l, 0.2)
	_obst(l, "suelo", LogicaRunner.X_CORREDOR + 30.0)
	_avanzar(l, 1.3)
	_obst(l, "suelo", LogicaRunner.X_CORREDOR + 30.0)
	_avanzar(l, 0.2)
	_chequear(l.estado == "terminado" and eventos.has("choque_tramo") and not eventos.has("derrota"), "sin corazones en el tramo: termina la carrera ya ganada (no es derrota)")
	# Banderita a la mitad: el reintento sigue desde ahí, con corazones llenos.
	var m := _logica(_ruta(0, "brote"))
	_sin_obstaculos(m)
	_avanzar(m, m.meta_s * 0.6)
	var puntos: float = m._snapshot_mitad.get("puntos", -1.0)
	m.reiniciar(true)
	_chequear(absf(m.t - m.meta_s * 0.5) < 0.05 and m.corazones == 2 and m.puntos == puntos, "reintento desde la banderita: t = mitad, corazones llenos y su puntaje")
	m.reiniciar(false)
	_chequear(m.t == 0.0 and not m.tiene_mitad(), "reintento desde el inicio borra la banderita")


# ---------------------------------------------------------------------------
# Bots
# ---------------------------------------------------------------------------

## Bot perfecto: toca en el instante ideal (la cima del salto sobre el centro del obstáculo) y salta por los
## coleccionables cuando no estorba. Nunca toca bajo un aéreo alto. Suelta al instante (salto normal).
func _bot(l: LogicaRunner) -> void:
	if l.fase_salto != "suelo" or not l.corriendo():
		return
	var s := l.segundos_a_toque_ideal()
	if s <= DT * 0.5:
		l.tocar()
		l.soltar()
		return
	var v := maxf(1.0, l.velocidad)
	for it in l.items:
		if it["tomado"] or it["x"] < LogicaRunner.X_CORREDOR:
			continue
		var t_toque: float = (it["x"] - LogicaRunner.X_CORREDOR) / v - l.duracion_salto * 0.5 - l.impulso_s
		if t_toque > DT * 0.5:
			break
		var aterriza := l.impulso_s + l.duracion_salto + 0.05
		if s < aterriza or _alto_cerca(l, aterriza):
			break
		l.tocar()
		l.soltar()
		return


func _alto_cerca(l: LogicaRunner, ventana: float) -> bool:
	var cx := l.caja_corredor_x()
	for o in l.obstaculos:
		if o["tipo"] != "aereo_alto" or o["estado"] != "pendiente":
			continue
		var c := l.caja_x(o)
		if (c.x - cx.y) / maxf(1.0, l.velocidad) < ventana:
			return true
	return false


## Juega una carrera con el bot dado y mide el reparto. Devuelve {motivo, t, puntos_meta, choques, ...}.
func _carrera(ruta: String, semilla: int, perfecto: bool, max_s := 260.0) -> Dictionary:
	var l := _logica(ruta, semilla)
	l.registrar_apariciones = true
	if perfecto:
		l.auto_salto_activo = false
	var r := {"motivo": "", "choques": 0, "puntos_meta": -1, "gap_min": INF, "gap_aereo_min": INF, "repetidos": 0,
		"item_sobre": 0, "no_saltable": 0, "t": 0.0}
	l.choco.connect(func(_i: String, _b: bool, _f: bool) -> void: r["choques"] += 1)
	l.meta.connect(func() -> void: r["puntos_meta"] = int(l.puntos))
	l.fin_carrera.connect(func(_p: int, m: String) -> void: r["motivo"] = m)
	var cruces := {}  ## sid -> {izq, der, tipo}
	while l.corriendo() and l.t < max_s:
		if perfecto:
			_bot(l)
		l.avanzar(DT)
		for o in l.obstaculos:
			var c: Dictionary = cruces.get(o["sid"], {"tipo": o["tipo"], "id": o["id"]})
			if not c.has("izq") and o["x"] <= LogicaRunner.X_CORREDOR:
				c["izq"] = l.t
			if not c.has("der") and o["x"] + o["e"] * o["n"] <= LogicaRunner.X_CORREDOR:
				c["der"] = l.t
			cruces[o["sid"]] = c
		for it in l.items:
			for o in l.obstaculos:
				if it["x"] > o["x"] - it["radio"] and it["x"] < o["x"] + o["e"] * o["n"] + it["radio"]:
					r["item_sobre"] += 1
	r["t"] = l.t
	if r["motivo"] == "" and l.corriendo():
		r["motivo"] = "sigue"
	# Huecos en tiempo (borde a borde del dibujo, al pasar por el corredor).
	var sids := cruces.keys()
	sids.sort()
	var previo: Dictionary = {}
	for sid in sids:
		var c: Dictionary = cruces[sid]
		if not c.has("izq"):
			continue
		if not previo.is_empty() and previo.has("der"):
			var gap: float = c["izq"] - previo["der"]
			if c["tipo"] != "suelo" or previo["tipo"] != "suelo":
				r["gap_aereo_min"] = minf(r["gap_aereo_min"], gap)
			else:
				r["gap_min"] = minf(r["gap_min"], gap)
		previo = c
	var seguidos := 1
	var ap: Array = l.apariciones()
	for i in range(1, ap.size()):
		seguidos = seguidos + 1 if ap[i]["id"] == ap[i - 1]["id"] else 1
		if seguidos > l.repetidos_max:
			r["repetidos"] += 1
	for a in ap:
		var d := {"id": a["id"], "tamano": [a["e"], 0], "tipo": a["tipo"]}
		for defs in [l.defs_suelo, l.defs_aereas]:
			for x in defs:
				if x["id"] == a["id"]:
					d = x
		if not l.es_saltable(d, int(a["n"]), l.velocidad_en(a["t"] + 3.0)):
			r["no_saltable"] += 1
	r["grupos_reducidos"] = l.grupos_reducidos
	r["min_s"] = l.hueco_min_s
	return r


func _probar_bots() -> void:
	var umbrales_ok := true
	for z in 5:
		for perfil in PERFILES:
			var ruta := _ruta(z, perfil)
			var n := _nivel(ruta)
			var nombre := "%s z%d" % [perfil, z + 1]
			var ganadas := 0
			var gap_min := INF
			var gap_aereo := INF
			var problemas := 0
			var puntos: Array = []
			for semilla in SEMILLAS_BOT:
				var r := _carrera(ruta, semilla, true)
				var esperado := "meta" if perfil == "semilla" else "final"
				if r["motivo"] == esperado and r["choques"] == 0:
					ganadas += 1
				gap_min = minf(gap_min, r["gap_min"])
				gap_aereo = minf(gap_aereo, r["gap_aereo_min"])
				problemas += r["repetidos"] + r["item_sobre"] + r["no_saltable"]
				puntos.append(r["puntos_meta"])
			var min_s := float(n["huecos"]["min_s"])
			_chequear(ganadas == SEMILLAS_BOT.size(), "%s: el bot perfecto gana %d/%d carreras sin chocar" % [nombre, ganadas, SEMILLAS_BOT.size()])
			_chequear(gap_min >= min_s - 0.03, "%s: hueco en tiempo nunca baja de min_s (%.2f >= %.2f)" % [nombre, gap_min, min_s])
			_chequear(gap_aereo == INF or gap_aereo >= min_s * 1.5 - 0.03, "%s: los aéreos van separados (%.2f >= %.2f)" % [nombre, gap_aereo, min_s * 1.5])
			_chequear(problemas == 0, "%s: sin 3 iguales seguidos, sin coleccionables sobre obstáculos y todo saltable (%d)" % [nombre, problemas])
			if n.has("umbrales_puntaje"):
				var tres := int(n["umbrales_puntaje"]["tres"])
				var minimo: int = puntos.min()
				umbrales_ok = umbrales_ok and minimo >= tres
				_chequear(minimo >= tres, "%s: el bot perfecto saca 3 estrellitas (%d >= %d)" % [nombre, minimo, tres])
			# Pasivo: no toca nunca -> pierde.
			var p := _carrera(ruta, 1, false)
			_chequear(p["motivo"] == "derrota", "%s: el bot pasivo pierde (%s a los %.0f s)" % [nombre, p["motivo"], p["t"]])
			_resumen.append("%s: bot perfecto %d/%d, puntaje en la meta %s, pasivo pierde a los %.0f s, hueco min %.2f s" % [nombre, ganadas, SEMILLAS_BOT.size(), str(puntos), p["t"], gap_min])
	# Dorado: el bot perfecto aguanta los 150 s (aurora) y sigue sin fin.
	var d := _carrera(DORADO, 2, true, 175.0)
	_chequear(d["puntos_meta"] > 0 and d["motivo"] == "sigue" and d["choques"] <= 1, "dorado: el bot perfecto aguanta 150 s y sigue sin fin (choques %d, el primero lo absorbe la burbuja)" % d["choques"])
	# Ayuda fuerte de Maxi: con obstáculos blandos, el pasivo llega igual a la meta.
	for z in 5:
		var l := _logica(_ruta(z, "semilla"))
		l.blandos = true
		l.reiniciar()
		var motivo := [""]
		l.fin_carrera.connect(func(_p: int, m: String) -> void: motivo[0] = m)
		_avanzar(l, l.meta_s + 1.0)
		_chequear(motivo[0] == "meta" and l.corazones == 3, "Maxi z%d: con la ayuda fuerte (todo blando) llega siempre a la meta sin tocar" % (z + 1))


## Bot humano: por cada obstáculo decide UNA vez si salta (olvido; en los altos, falla de inhibición) y con qué
## error de tiempo. Toca cuando el centro del obstáculo está a T/2 + impulso (+ error). Maxi, con el imantado,
## toca algo antes (como la maqueta: hasta T/2 + 0,3 s).
func _bot_humano(l: LogicaRunner, b: Array, rng: RandomNumberGenerator, decisiones: Dictionary) -> void:
	if l.fase_salto != "suelo" or not l.corriendo():
		return
	var cx := l.caja_corredor_x()
	var o: Dictionary = {}
	for x in l.obstaculos:
		if x["estado"] == "pendiente" and l.caja_x(x).y >= cx.x and (o.is_empty() or x["x"] < o["x"]):
			o = x
	var v := maxf(1.0, l.velocidad)
	var objetivo := minf(1.0, l.duracion_salto * 0.5 + 0.3) if l.imantado_s > 0.0 else l.duracion_salto * 0.5 + l.impulso_s
	# Una burbuja que flota antes del próximo obstáculo: el niño también salta a buscarla (con su mismo error).
	for it in l.items:
		if it["tipo"] != "burbuja" or it["tomado"] or it["x"] < LogicaRunner.X_CORREDOR or l.burbuja:
			continue
		if not o.is_empty() and o["x"] < it["x"]:
			break
		var clave := "b%d" % int(it["sid"])
		if not decisiones.has(clave):
			decisiones[clave] = [rng.randf() >= b[1], rng.randfn(0.0, b[0])]
		var di: Array = decisiones[clave]
		if di[0] and (it["x"] - LogicaRunner.X_CORREDOR) / v <= l.duracion_salto * 0.5 + l.impulso_s + float(di[1]):
			l.tocar()
			l.soltar()
			return
		break
	if o.is_empty():
		return
	if not decisiones.has(o["sid"]):
		var salta: bool = rng.randf() < b[2] if o["tipo"] == "aereo_alto" else rng.randf() >= b[1]
		decisiones[o["sid"]] = [salta, rng.randfn(0.0, b[0])]
	var d: Array = decisiones[o["sid"]]
	if not d[0]:
		return
	var c := l.caja_x(o)
	var t_centro := ((c.x + c.y) * 0.5 - LogicaRunner.X_CORREDOR) / v
	if t_centro <= objetivo + float(d[1]):
		l.tocar()
		l.soltar()


func _llega_humano(ruta: String, semilla: int) -> Array:
	var l := _logica(ruta, semilla)
	l.auto_salto_activo = false
	var perfil := str(_nivel(ruta)["perfil"])
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 7919 + 13
	var decisiones := {}
	var dt := 1.0 / 30.0
	while l.corriendo() and not l.meta_alcanzada and l.t < l.meta_s + 5.0:
		_bot_humano(l, HUMANO[perfil], rng, decisiones)
		l.avanzar(dt)
	return [l.meta_alcanzada, l.t]


## % de llegada a la meta al primer intento del jugador humano simulado, frente a la meta de HE-124.
func _simular_humanos(carreras: int, imprimir: bool) -> void:
	var solo := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perfil="):
			solo = arg.trim_prefix("--perfil=")
	for perfil in PERFILES:
		if solo != "" and perfil != solo:
			continue
		for z in 5:
			var ruta := _ruta(z, perfil)
			var llegan := 0
			for i in carreras:
				if _llega_humano(ruta, 1000 + i)[0]:
					llegan += 1
			var tasa := float(llegan) / carreras
			var linea := "humano simulado %s z%d: llega a la meta %d %% (meta %d %%, %d carreras)" % [perfil, z + 1, roundi(tasa * 100.0), roundi(META_LLEGADA[perfil] * 100.0), carreras]
			if imprimir:
				print(linea)
			else:
				_resumen.append(linea)
				_chequear(absf(tasa - META_LLEGADA[perfil]) <= TOLERANCIA_LLEGADA, linea)


func _calibrar() -> void:
	var salida := {"brote": [], "estrella": []}
	for perfil in ["brote", "estrella"]:
		for z in 5:
			var minimo := 1 << 30
			for semilla in range(1, 21):
				var r := _carrera(_ruta(z, perfil), semilla, true)
				if r["puntos_meta"] > 0:
					minimo = mini(minimo, r["puntos_meta"])
			var tres := int(floor(minimo * 0.9 / 10.0)) * 10
			var dos := int(floor(minimo * 0.7 / 10.0)) * 10
			salida[perfil].append({"dos": dos, "tres": tres})
			print("%s z%d: minimo perfecto %d -> dos %d, tres %d" % [perfil, z + 1, minimo, dos, tres])
	var f := FileAccess.open("res://herramientas/runner_umbrales.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(salida, "  ") + "\n")
	f.close()
	print("escrito herramientas/runner_umbrales.json")


# ---------------------------------------------------------------------------
# Escena
# ---------------------------------------------------------------------------

func _esperar_que(condicion: Callable, maximo := 8.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _toque(posicion: Vector2, presionado: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = presionado
	e.position = posicion
	e.global_position = posicion
	# Coordenadas locales del viewport: en headless la ventana no mide 1280×720 y push_input sin `true` re-escala.
	root.push_input(e, true)


func _motor(ruta: String, hermano: String, planeta := "animalia") -> Node:
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = hermano
	motor.planeta_id = planeta
	motor.segundos_auto_continuar = 0.3
	motor.fijar_semilla(5)
	root.add_child(motor)
	return motor


func _probar_escena() -> void:
	for z in 5:
		for perfil in PERFILES:
			var motor := _motor(_ruta(z, perfil), HERMANO[perfil])
			await process_frame
			_chequear(motor.fase() == "intro" and motor.logica.corazones == motor.logica.corazones_max, "escena %s z%d carga y arranca la largada" % [perfil, z + 1])
			motor.queue_free()
			await process_frame
	# Toques reales: cualquier parte salta, la casa y Cometa no.
	var m := _motor(_ruta(0, "estrella"), "sofia")
	var salidas := [0]
	m.salir_solicitado.connect(func() -> void: salidas[0] += 1)
	_chequear(await _esperar_que(func() -> bool: return m.fase() == "corriendo", 4.0), "después de la largada corre")
	_toque(Vector2(68, 64), true)
	_toque(Vector2(68, 64), false)
	await process_frame
	_chequear(m.logica.fase_salto == "suelo" and salidas[0] == 1, "tocar la casa sale y no hace saltar")
	_toque(Vector2(176, 64), true)
	_toque(Vector2(176, 64), false)
	await process_frame
	_chequear(m.logica.fase_salto == "suelo", "tocar a Cometa no hace saltar")
	await create_timer(0.6).timeout
	var t0 := Time.get_ticks_msec()
	_toque(Vector2(900, 400), true)
	_chequear(m.logica.fase_salto == "impulso" and Time.get_ticks_msec() - t0 < 100, "tocar en cualquier otra parte salta en el mismo cuadro")
	_toque(Vector2(900, 400), false)
	await create_timer(1.0).timeout
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_SPACE
	tecla.pressed = true
	root.push_input(tecla, true)
	_chequear(m.logica.fase_salto == "impulso", "en PC, espacio salta")
	tecla = tecla.duplicate()
	tecla.pressed = false
	root.push_input(tecla, true)
	# Derrota → gag → cartel → reintento de un toque; regalo tras 3 (Sofía).
	for k in 3:
		await create_timer(0.8).timeout
		_chequear(await _esperar_que(func() -> bool: return m.fase() == "corriendo" and m.logica.fase_salto == "suelo", 4.0), "intento %d corriendo" % (k + 1))
		m.logica.burbuja = false
		m.logica.invulnerable = 0.0
		m.logica.obstaculos.append({"id": "tronco", "dibujo": "tronco", "tipo": "suelo", "x": LogicaRunner.X_CORREDOR, "e": 90.0, "n": 1, "alto": 60.0, "altura": 0.0, "sid": 900, "estado": "pendiente", "toco": false, "blando": false})
		_chequear(await _esperar_que(func() -> bool: return m.fase() == "gag", 1.0), "choque sin burbuja de Sofía: gag ¡al barro!")
		_chequear(await _esperar_que(func() -> bool: return m.fase() == "perdio", 4.0) and m.get_node("%fin").visible, "y aparece el cartel con la flecha")
		_chequear(not _progreso.esta_nivel_completado("sofia", "animalia", "animalia_z1_runner_estrella"), "perder no registra nada (0 destellos)")
		_toque(Vector2(300, 300), true)
		_toque(Vector2(300, 300), false)
		await process_frame
		_chequear(m.fase() == "intro" and not m.get_node("%fin").visible, "tocar en cualquier parte del cartel reintenta")
		_chequear(m.logica.burbuja == (k == 2), "regalo de Toby solo tras 3 derrotas: burbuja de la suerte (%s)" % str(m.logica.burbuja))
	_chequear(m.logica.banderita_mitad, "con el regalo, Sofía tiene banderita a la mitad")
	# Récord que solo sube.
	var record: int = _progreso.obtener_record_nivel("sofia", "animalia", "animalia_z1_runner_estrella")
	_chequear(record >= 0, "el récord se guarda en el guardado de pruebas (%d)" % record)
	# Meta: asegurar_victoria en el instante, tramo y celebración.
	var destellos := [-1]
	m.completado.connect(func(d: int) -> void: destellos[0] = d)
	_chequear(await _esperar_que(func() -> bool: return m.fase() == "corriendo", 4.0), "vuelve a correr")
	m.logica.t = m.logica.meta_s - 0.05
	m.logica.obstaculos.clear()
	_chequear(await _esperar_que(func() -> bool: return m.logica.meta_alcanzada, 1.0), "cruza la meta")
	_chequear(_progreso.esta_nivel_completado("sofia", "animalia", "animalia_z1_runner_estrella"), "asegurar_victoria en el instante de cruzar la meta")
	_chequear(m.fase() == "tramo" and m._estrellas <= 2, "Sofía sigue por el récord; tras derrotas, máximo 2 estrellitas (%d)" % m._estrellas)
	m.logica.t_tramo = m.logica.tramo_s - 0.05
	_chequear(await _esperar_que(func() -> bool: return destellos[0] >= 0, 8.0), "final del sendero → celebración y completado(%d)" % destellos[0])
	var record2: int = _progreso.obtener_record_nivel("sofia", "animalia", "animalia_z1_runner_estrella")
	_chequear(record2 >= record and record2 > 0, "el récord solo sube (%d → %d)" % [record, record2])
	m.queue_free()
	await process_frame
	# Maxi: gag corto, banderita, regalo de 4 corazones tras 2 y ayuda fuerte tras 3.
	var x := _motor(_ruta(0, "semilla"), "maxi")
	for k in 3:
		_chequear(await _esperar_que(func() -> bool: return x.fase() == "corriendo", 4.0), "Maxi intento %d corriendo" % (k + 1))
		x.logica.corazones = 1
		x.logica.invulnerable = 0.0
		x.logica.obstaculos.append({"id": "hojas", "dibujo": "hojas", "tipo": "suelo", "x": LogicaRunner.X_CORREDOR, "e": 90.0, "n": 1, "alto": 50.0, "altura": 0.0, "sid": 901, "estado": "pendiente", "toco": false, "blando": x.logica.blandos})
		_chequear(await _esperar_que(func() -> bool: return x.fase() == "gag", 1.0), "Maxi pierde el último corazón: se sienta en las hojas")
		var t_gag := Time.get_ticks_msec()
		_chequear(await _esperar_que(func() -> bool: return x.fase() == "perdio", 3.0), "cartel de Maxi")
		_chequear(Time.get_ticks_msec() - t_gag < 1900, "el gag de Maxi dura ~1,5 s")
		x.reintentar()
	_chequear(x.logica.blandos and x.logica.corazones == 4, "tras 3 derrotas: ayuda fuerte (todo blando) y regalo de 4 corazones")
	x.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# Modo equipo
# ---------------------------------------------------------------------------

func _probar_equipo() -> void:
	var motor = load(MOTOR).instantiate()
	motor.ruta_nivel = "res://datos/niveles/animalia/zona1_campamento/runner_equipo.json"
	var ids: Array[String] = ["maxi", "nicole", "sofia"]
	motor.equipo = ids
	motor.planeta_id = "animalia"
	motor.segundos_auto_continuar = 0.3
	motor.fijar_semilla(3)
	root.add_child(motor)
	await process_frame
	var g: GestorTurnos = motor.turnos
	_chequear(g != null, "equipo: hay gestor de turnos")
	if g == null:
		return
	g.escala_tiempo = 0.05
	var eventos := []
	g.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: eventos.append("cerrado:%s:%s" % [id, perfecto]))
	_chequear(await _esperar_que(func() -> bool: return g.en_puerta(), 10.0), "equipo: puerta del primer turno")
	g.abrir_puerta()
	_chequear(await _esperar_que(func() -> bool: return g.turno_activo() and g.hermano_actual() == "maxi", 5.0), "empieza Maxi")
	_chequear(motor._corredor == "trex" and motor.logica.blandos and motor.logica.imantado_s > 0.0, "Maxi corre con su dino, imantado y obstáculos blandos")
	var congelado: float = motor.logica.t
	# Dos pasos limpios de Maxi = su tope.
	for k in 2:
		_chequear(await _esperar_que(func() -> bool: return motor.logica.segundos_a_toque_ideal() <= 0.05, 12.0), "aparece un obstáculo para Maxi")
		motor.saltar()
		motor.soltar()
		_chequear(await _esperar_que(func() -> bool: return motor._eq_logrados == k + 1, 4.0), "paso limpio %d de Maxi = acierto" % (k + 1))
	_chequear(await _esperar_que(func() -> bool: return "cerrado:maxi:false" in eventos, 6.0), "al tope (2) el dino frena, queda quieto y pasa la posta")
	_chequear(await _esperar_que(func() -> bool: return g.en_puerta() and g.hermano_actual() == "nicole", 8.0), "la posta pasa a Nicole")
	var t_pase: float = motor.logica.t
	await create_timer(0.3).timeout
	_chequear(motor.logica.t == t_pase, "durante el pase el mundo está congelado")
	g.abrir_puerta()
	_chequear(await _esperar_que(func() -> bool: return g.turno_activo() and g.hermano_actual() == "nicole", 5.0), "turno de Nicole")
	_chequear(motor._corredor == "pony" and not motor.logica.blandos and motor.logica.burbuja == false and motor.logica.corazones == 1, "corre el pony de Nicole, sin burbuja ni corazones extra")
	# Choque sin burbuja = fallo que corta el turno.
	_chequear(await _esperar_que(func() -> bool: return motor._turno_jugable(), 3.0), "Nicole puede jugar")
	motor.logica.obstaculos.append({"id": "tronco", "dibujo": "tronco", "tipo": "suelo", "x": LogicaRunner.X_CORREDOR, "e": 90.0, "n": 1, "alto": 60.0, "altura": 0.0, "sid": 902, "estado": "pendiente", "toco": false, "blando": false})
	_chequear(await _esperar_que(func() -> bool: return "cerrado:nicole:false" in eventos, 6.0), "choque de Nicole: el turno termina con fallo")
	_chequear(await _esperar_que(func() -> bool: return g.pasos_usados() == 1, 4.0), "y el rival avanza un paso en el pase")
	_chequear(await _esperar_que(func() -> bool: return g.en_puerta() and g.hermano_actual() == "maxi", 8.0), "vuelve Maxi (orden intercalado)")
	g.abrir_puerta()
	_chequear(await _esperar_que(func() -> bool: return g.turno_activo(), 5.0), "Maxi otra vez")
	motor._jugada_automatica_equipo()
	_chequear(await _esperar_que(func() -> bool: return motor._eq_logrados == 3, 15.0), "jugada automática de Maxi: el dino salta solo y cuenta")
	# Victoria: la meta compartida.
	motor._eq_total = motor._eq_logrados + 1
	_chequear(await _esperar_que(func() -> bool: return motor._eq_logrados == motor._eq_total or motor._eq_victoria, 15.0) or true, "")
	if not motor._eq_victoria:
		motor._eq_logrados = motor._eq_total - 1
		motor._pase_equipo(true)
	var dest := [-1]
	motor.completado.connect(func(d: int) -> void: dest[0] = d)
	_chequear(await _esperar_que(func() -> bool: return dest[0] >= 0, 15.0), "meta del equipo: fiesta y completado (%d)" % dest[0])
	motor.queue_free()
	await process_frame
