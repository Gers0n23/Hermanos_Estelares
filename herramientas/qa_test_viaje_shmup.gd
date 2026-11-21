extends SceneTree

## Arnés headless del viaje arcade v2 (HE-136, shmup; ficha docs/fichas/viaje-arcade.md §13). Corre la
## LÓGICA (`logica_viaje.gd`, sin nodos) con un jugador simulado por perfil y ruta, y revisa los criterios
## que se pueden medir sin pantalla. No toca el guardado (no usa Progreso).
## (El arnés del viaje pixel anterior es `qa_test_viaje_arcade.gd`.)
##   godot --headless --path . --script herramientas/qa_test_viaje_shmup.gd [-- rutas=tierra_arcoiris]

const Logica := preload("res://scripts/nucleo/viaje_arcade/logica_viaje.gd")
var _fallas := 0


func _initialize() -> void:
	var perfiles: Dictionary = _json("res://datos/viaje/perfiles.json")
	var rutas := ["tierra_arcoiris", "arcoiris_animalia", "animalia_melodia", "corazon_coleccionauta"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("rutas="):
			rutas = Array(a.get_slice("=", 1).split(","))
	_criterios(perfiles, _json("res://datos/viaje/rutas/tierra_arcoiris.json"))
	for r in rutas:
		var datos: Dictionary = _json("res://datos/viaje/rutas/%s.json" % r)
		for p in ["semilla", "brote", "estrella"]:
			_partida(perfiles, datos, p, r)
	print("qa_viaje_shmup: %s (%d fallas)" % ["OK" if _fallas == 0 else "FALLA", _fallas])
	quit(1 if _fallas else 0)


func _json(ruta: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ruta))


func _revisar(ok: bool, que: String) -> void:
	if not ok:
		_fallas += 1
		print("  FALLA: ", que)


## Bot: se pone en la fila del enemigo más cercano, esquiva balas cercanas y dispara siempre.
func _partida(perfiles: Dictionary, datos: Dictionary, perfil: String, ruta: String) -> void:
	var l = Logica.new()
	l.preparar(perfiles, datos, perfil, {}, 3)
	l.empezar()
	var dt := 1.0 / 60.0
	var t := 0.0
	var visto := {}
	var derrotas := 0
	var max_enem := 0
	var t_jefe := 0.0
	var objetivo := Vector2(300, 380)
	var cuadro := 0
	while l.fase != "fin" and t < 400.0:
		t += dt
		cuadro += 1
		if cuadro % 6 == 0:
			var meta_y := 380.0
			var mejor := 9999.0
			for e in l.enemigos:
				var d: float = e["pos"].x - l.nave.x
				if d > 0 and d < mejor:
					mejor = d
					meta_y = e["pos"].y
			if not l.jefe.is_empty():
				meta_y = l.jefe["pos"].y + 60.0
				if l.jefe["debil"]:
					meta_y = l.punto_debil().y
				elif l.jefe["estado"] in ["aviso", "ataca"] and l._patrones()[l.jefe["patron"]] == "embiste":
					meta_y = l.jefe["pos"].y + (230.0 if l.jefe["pos"].y < 400 else -230.0)
			if not l.colec.is_empty():
				meta_y = l.colec["pos"].y + 130
			meta_y = _esquivar(l, meta_y)
			objetivo = Vector2(320, clampf(meta_y, 190, 640))
		var delta: Vector2 = (objetivo - l.nave).limit_length(14.0)
		l.voz_sonando = false
		l.actualizar(dt, {"dedo": true, "delta": delta, "punto": objetivo + Vector2(0, 120)})
		visto[l.fase] = true
		if l.fase == "jefe":
			t_jefe += dt
		max_enem = maxi(max_enem, l.enemigos.size())
		for ev in l.sacar_eventos():
			if ev["tipo"] == "derrota":
				derrotas += 1
	var r: Dictionary = l.resultados()
	print("  %-26s %-8s %5.1f s (jefe %4.1f s) derrotas=%d destellos=%d puntaje=%d enem_max=%d" % [ruta, perfil,
			t, t_jefe, derrotas, r["destellos"], r["puntaje"], max_enem])
	_revisar(l.fase == "fin", "%s/%s no llegó al final (fase %s)" % [ruta, perfil, l.fase])
	_revisar(visto.has("jefe") and visto.has("encuentro"), "%s/%s sin jefe o encuentro" % [ruta, perfil])
	_revisar(max_enem <= int(perfiles[perfil]["enemigos_max"]) + 2, "%s/%s demasiados enemigos" % [ruta, perfil])
	_revisar(r["destellos"] >= 3, "%s/%s pocos destellos (%d)" % [ruta, perfil, r["destellos"]])


## Elige la fila más segura mirando dónde estarán las balas (y el jefe que embiste) en el próximo medio segundo.
func _esquivar(l, meta_y: float) -> float:
	var peligros := []
	for b in l.balas_enemigas:
		for k in [0.15, 0.3, 0.45, 0.6]:
			peligros.append(b["pos"] + b["vel"] * k)
	if peligros.is_empty():
		return meta_y
	var mejor_y := meta_y
	var mejor := -99999.0
	for y in range(190, 650, 25):
		var p := Vector2(320, y)
		var cerca := 99999.0
		for q in peligros:
			cerca = minf(cerca, p.distance_to(q))
		var puntaje := minf(cerca, 140.0) - absf(y - meta_y) * 0.08 - absf(y - l.nave.y) * 0.15
		if puntaje > mejor:
			mejor = puntaje
			mejor_y = y
	return mejor_y


func _criterios(perfiles: Dictionary, datos: Dictionary) -> void:
	var dt := 1.0 / 60.0
	# 1. Nicole y Sofía: arrastre 1:1 en el mismo cuadro
	var l = Logica.new()
	l.preparar(perfiles, datos, "brote", {}, 1)
	l.empezar()
	var antes: Vector2 = l.nave
	l.actualizar(dt, {"dedo": true, "delta": Vector2(37, 21)})
	_revisar(l.nave.is_equal_approx(antes + Vector2(37, 21)), "1: arrastre 1:1")
	# 3. sin dedo no dispara; el primer disparo sale en el cuadro del toque
	l.balas.clear()
	l.actualizar(dt, {"dedo": false})
	_revisar(l.balas.is_empty(), "3: dispara sin dedo")
	l.actualizar(dt, {"dedo": true, "nuevo_toque": true})
	_revisar(not l.balas.is_empty(), "3: primer disparo en el cuadro del toque")
	# 2. Maxi: tope de 950 px/s y llegada en el mismo cuadro si está cerca (dedo - 120 px)
	var m = Logica.new()
	m.preparar(perfiles, datos, "semilla", {}, 1)
	m.empezar()
	m.nave = Vector2(600, 400)
	m.actualizar(dt, {"dedo": true, "punto": Vector2(1100, 520)})
	_revisar(absf(m.nave.distance_to(Vector2(600, 400)) - 950.0 / 60.0) < 0.5, "2: tope de Maxi")
	m.nave = Vector2(600, 400)
	m.actualizar(dt, {"dedo": true, "punto": Vector2(610, 525)})
	_revisar(m.nave.is_equal_approx(Vector2(610, 405)), "2: Maxi llega en un cuadro")
	# 5. la nave no entra en la franja de esquina
	for i in 120:
		m.actualizar(dt, {"dedo": true, "punto": Vector2(100, 100)})
	_revisar(m.nave.y >= 180.0, "5: la nave entró en la franja (y=%.0f)" % m.nave.y)
	# 6. golpes: Maxi no baja el arma; Nicole sí
	m.arma = 2
	m.invulnerable = 0.0
	m.escudo = false
	m._recibir_golpe()
	_revisar(m.arma == 2 and m.corazones == 4, "6: golpe de Maxi")
	l.arma = 2
	l.invulnerable = 0.0
	l._recibir_golpe()
	_revisar(l.arma == 1 and l.corazones == 3, "6: golpe de Nicole")
	# 9. derrota -> gag -> reinicio automático en <= 2 s, con vidas llenas y puntaje 0
	l.puntaje = 500
	l.corazones = 1
	l.invulnerable = 0.0
	l._recibir_golpe()
	_revisar(l.fase == "gag", "9: no hubo gag")
	var t := 0.0
	while l.fase in ["gag", "reinicio"] and t < 5.0:
		l.actualizar(dt, {})
		t += dt
	_revisar(t <= 2.05, "9: gag + reinicio = %.2f s" % t)
	_revisar(l.corazones == l.corazones_max and l.puntaje == 0 and l.enemigos.is_empty(), "8: estado del reinicio")
	_revisar(not l.resultados()["record_elegible"], "12: con '¡otra vez!' no hay récord")
	# 15. fotosensibilidad: nunca más de 3 destellos blancos por segundo
	l.sacar_eventos()
	for i in 20:
		l._impacto(Vector2(600, 300))
	var blancos := 0
	for ev in l.sacar_eventos():
		if ev["tipo"] == "impacto" and ev["blanco"]:
			blancos += 1
	_revisar(blancos <= 3, "15: %d destellos blancos en 1 s" % blancos)
	# Maxi no recibe proyectiles enemigos
	m._bala_enemiga(Vector2(500, 300), Vector2(-100, 0), "burbuja")
	_revisar(m.balas_enemigas.is_empty(), "Maxi recibió un proyectil")
	# 13. Cometa al volante tras 3 derrotas de Maxi; el último corazón queda protegido
	for i in 3:
		m.corazones = 1
		m.invulnerable = 0.0
		m.escudo = false
		m._recibir_golpe()
		m.acortar()
		m.acortar()
	_revisar(m.volante, "13: Cometa al volante")
	m.corazones = 1
	m.invulnerable = 0.0
	m.escudo = false
	m._recibir_golpe()
	_revisar(m.corazones == 1 and m.fase != "gag", "13: con Cometa al volante el último corazón no se pierde")
	# 13. descanso de Nicole tras 3 derrotas, la nave no entra en el icono
	var n = Logica.new()
	n.preparar(perfiles, datos, "brote", {}, 1)
	n.empezar()
	for i in 3:
		n.corazones = 1
		n.invulnerable = 0.0
		n.escudo = false     # el regalo trae escudo
		n._recibir_golpe()
		for k in 200:
			n.actualizar(dt, {})
	_revisar(n.descanso_visible, "13: icono de descanso de Nicole tras 3 derrotas")
	n.nave = Vector2(1200, 300)
	for k in 60:
		n.actualizar(dt, {"dedo": true, "delta": Vector2(0, -20)})
	_revisar(n.nave.y - 24 >= 108.0, "21: la nave entró en el icono de descanso (y=%.0f)" % n.nave.y)
	# 10. retomar desde un checkpoint guardado
	var c = Logica.new()
	c.preparar(perfiles, datos, "estrella", {"checkpoint": {"sector": 1, "oleada": 4}}, 1)
	c.empezar()
	_revisar(c.sector == 1 and c.oleada == 4, "10: no retomó el checkpoint guardado")
	print("  criterios §13 revisados")
