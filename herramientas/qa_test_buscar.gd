extends SceneTree

## Arnes QA del «Escondite animal» (motor buscar, HE-118; docs/fichas/motor-buscar.md §15 con HE-124).
##
## 1. Niveles (5 zonas x 3 perfiles + equipo): carga, parametros HE-124 (sol, regalo, ayuda fuerte, descanso),
##    y para CADA escondite de cada animal: parte visible MEDIDA >= `visible_min` (con la pieza abierta si es un
##    escondite que se abre), zona de toque >= minimo del perfil, dentro de la escena y sobre la lista.
## 2. Sorteo con semilla: siempre uno de los declarados, sin piezas compartidas ni cajas pisadas.
## 3. Tocable: en varias partidas, tocar el centro visible de cada objetivo lo encuentra (abriendo antes su
##    escondite si hace falta) y la partida se gana.
## 4. Reglas: senuelo frente a objetivo, racha y ojo de aguila, 2 pasos, "ya encontrado", toque frente a arrastre.
## 5. Sol (los tres perfiles): derrota, encontrados intactos, escondites nuevos, tiempo proporcional, regalo,
##    ayuda fuerte de Semilla (sin sol, todos asoman), descanso, 0 estrellitas al perder.
## 6. Escena: cada nivel se juega entero en el motor (victoria y `completado`), derrota-gag con reintento de un
##    toque, lupa, mapita, guardado parcial de Sofia, marca del huevito de Dinito y destellos solo al ganar.
## 7. Modo equipo: tope por perfil, turno de Maxi (asoma), tiempo del turno con cambio de escondite, jugada
##    automatica, senuelo/fallo suave, derrota-gag con escondites nuevos y victoria.
##
## Guardado AISLADO: usa `progreso_pruebas.json` (lo elige Progreso al correr con --script), lo respalda y lo
## restaura, y verifica por md5 que el guardado real del PO (`user://progreso.json`) queda intacto.
## Uso: godot --headless --path . --script herramientas/qa_test_buscar.gd [-- --detalle]

const G := preload("res://scripts/motores/buscar/geometria_buscar.gd")
const MOTOR := "res://escenas/minijuegos/buscar/motor_buscar.tscn"
const RAIZ := "res://datos/niveles/animalia/"
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
const PERFILES := ["semilla", "brote", "estrella"]
const EQUIPO := "res://datos/niveles/animalia/zona1_campamento/buscar_equipo.json"
const GUARDADO_REAL := "user://progreso.json"
const SOL := {"semilla": [3.0, 60.0], "brote": [2.2, 60.0], "estrella": [1.6, 45.0]}
const REGALO := {"semilla": 2, "brote": 2, "estrella": 3}
const MINIMO := {"semilla": 160.0, "brote": 96.0, "estrella": 64.0}

var _fallos := 0
var _oks := 0
var _detalle := false
var _progreso: Node
var _respaldo := ""
var _md5_real := ""


func _initialize() -> void:
	_detalle = "--detalle" in OS.get_cmdline_user_args()
	print("=== QA buscar: Escondite animal (HE-118) ===")
	_md5_real = FileAccess.get_md5(GUARDADO_REAL) if FileAccess.file_exists(GUARDADO_REAL) else ""
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
	for zi in ZONAS.size():
		for perfil in PERFILES:
			_probar_nivel(zi, perfil)
	_probar_nivel_equipo_datos()
	_probar_reglas()
	_probar_sol()
	Engine.time_scale = 4.0
	for zi in ZONAS.size():
		for perfil in PERFILES:
			await _jugar_escena(zi, perfil)
	await _probar_derrota_escena("estrella", 2)
	await _probar_derrota_escena("semilla", 0)
	await _probar_entrada_y_lupa()
	await _probar_guardado()
	await _probar_equipo()
	Engine.time_scale = 1.0
	# Restaurar el guardado de pruebas y verificar el del PO.
	if _respaldo != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo)
		f.close()
	_progreso.cargar()
	var md5_fin := FileAccess.get_md5(GUARDADO_REAL) if FileAccess.file_exists(GUARDADO_REAL) else ""
	_check(md5_fin == _md5_real, "el guardado real del PO queda intacto (md5 %s)" % md5_fin)
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


func _ruta(zi: int, perfil: String) -> String:
	return RAIZ + ZONAS[zi] + "/buscar_%s.json" % perfil


func _leer(ruta: String) -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return datos if datos is Dictionary else {}


func _logica(nivel: Dictionary, semilla := 3) -> LogicaBuscar:
	var l := LogicaBuscar.new()
	l.configurar(nivel, semilla)
	return l


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


## Un punto dentro de la pieza (para abrirla con un toque).
func _punto_pieza(l: LogicaBuscar, oid: String) -> Vector2:
	for prim in l.cobertura_objeto(oid):
		var c: Vector2 = G.caja(prim).get_center()
		if G.contiene(prim, c) and l.que_hay(c)["id"] == oid:
			return c
	for prim in l.cobertura_objeto(oid):
		var caja := G.caja(prim)
		for k in 25:
			var q := caja.position + caja.size * Vector2((k % 5 + 0.5) / 5.0, (k / 5 + 0.5) / 5.0)
			if l.que_hay(q)["id"] == oid:
				return q
	return G.caja(l.cobertura_objeto(oid)[0]).get_center()


## Encuentra `id` como lo haria un nino: abre su escondite si hace falta y toca su centro visible.
func _encontrar(l: LogicaBuscar, id: String) -> Dictionary:
	var vueltas := 0
	while not l.revelado(id) and not id in l.encontrados and vueltas < 4:
		var r := l.tocar(_punto_pieza(l, l.pieza_de(l.escondite(id))))
		vueltas += 1
		if r.get("tipo", "") == "encontrado" and r.get("id", "") == id:
			return r
	if id in l.encontrados:
		return {"tipo": "encontrado", "id": id}
	return l.tocar(l.medida(id)["centro"])


# ---------------------------------------------------------------------------
# 1-3. Niveles: visibilidad medida, zonas de toque, sorteo y tocable
# ---------------------------------------------------------------------------

func _probar_nivel(zi: int, perfil: String) -> void:
	var ruta := _ruta(zi, perfil)
	var nivel := _leer(ruta)
	var nombre := "z%d %s" % [zi + 1, perfil]
	_check(not nivel.is_empty(), "%s: el nivel carga (%s)" % [nombre, ruta])
	if nivel.is_empty():
		return
	_check(nivel.get("motor") == "buscar" and nivel.get("perfil") == perfil, "%s: motor y perfil" % nombre)
	_check(nivel.get("id_nivel") == "animalia_z%d_buscar_%s" % [zi + 1, perfil], "%s: id_nivel con la convencion" % nombre)
	var sol: Dictionary = nivel.get("sol", {})
	_check(is_equal_approx(float(sol.get("factor_par", 0)), SOL[perfil][0]) and is_equal_approx(float(sol.get("minimo_reintento_s", 0)), SOL[perfil][1]),
		"%s: sol HE-124 {%s, %s}" % [nombre, SOL[perfil][0], SOL[perfil][1]])
	_check(float(nivel.get("tiempo_par_s", 0)) > 0, "%s: tiempo par definido (%s s)" % [nombre, nivel.get("tiempo_par_s")])
	_check(int(nivel.get("regalo_tras_derrotas", 0)) == REGALO[perfil], "%s: regalo tras %d derrotas" % [nombre, REGALO[perfil]])
	if perfil == "semilla":
		_check(nivel.get("ayuda_fuerte_tras_derrotas") is Dictionary and int(nivel["ayuda_fuerte_tras_derrotas"]["derrotas"]) == 3, "%s: ayuda fuerte tras 3" % nombre)
		_check(nivel.get("descanso_tras_derrotas") == null, "%s: sin oferta de descanso (la ayuda fuerte resuelve)" % nombre)
		_check(int(nivel.get("escenas", 1)) == 2, "%s: 2 escenas por estacion" % nombre)
	else:
		_check(int(nivel.get("descanso_tras_derrotas", 0)) == (3 if perfil == "brote" else 4), "%s: descanso tras %d" % [nombre, 3 if perfil == "brote" else 4])
		_check(nivel.get("umbrales_puntaje", {}).has("tres"), "%s: umbrales de estrellitas" % nombre)
	var l := _logica(nivel)
	var vmin := float(nivel.get("visible_min", 0))
	var minimo: float = MINIMO[perfil]
	var tam := l.tamano_escena
	var malos: Array[String] = []
	var peor := 1.0
	var n_esc := 0
	for id in l.animales:
		var lista := l.escondites_de(id)
		if lista.size() < 2:
			malos.append("%s tiene %d escondites" % [id, lista.size()])
		for k in lista.size():
			n_esc += 1
			l.fijar_escondite(id, k)
			var f := l.fraccion_visible_revelado(id)
			peor = minf(peor, f)
			if f < vmin - 0.005:
				malos.append("%s#%d visible %.2f < %.2f" % [id, k, f, vmin])
			# Zona de toque medida con la pieza abierta (asi se toca de verdad).
			var pieza := l.pieza_de(lista[k])
			if l.esta_dentro(id):
				l.abiertos[pieza] = int(l.objetos[pieza].get("pasos", 1))
				l._medidas.clear()
			var zona := l.zona_toque(id)
			l.abiertos.clear()
			l._medidas.clear()
			if zona.size.x < minimo - 0.5 or zona.size.y < minimo - 0.5:
				malos.append("%s#%d zona %s < %d" % [id, k, zona.size, minimo])
			if zona.end.y > l.zona_util_max_y + 0.5:
				malos.append("%s#%d zona bajo la lista (%.0f)" % [id, k, zona.end.y])
			if not Rect2(Vector2.ZERO, tam).encloses(G.caja_de(l.partes_animal(id))):
				malos.append("%s#%d fuera de la escena" % [id, k])
	_check(malos.is_empty(), "%s: %d escondites; todos visibles >= %d %% (peor %.0f %%), zona >= %d px y sobre la lista %s" % [nombre, n_esc, roundi(vmin * 100), peor * 100, minimo, "" if malos.is_empty() else str(malos.slice(0, 4))])
	# Sorteo con varias semillas.
	var sorteo_ok := true
	var tocable_ok := true
	var gana_ok := true
	var detalle := ""
	for semilla in 12:
		var l2 := _logica(nivel, 100 + semilla)
		if not l2.ultimo_sorteo_unico:
			sorteo_ok = false
			detalle = "semilla %d: el sorteo no separo a todos" % semilla
		_check_sorteo_silencioso(l2, func(m: String) -> void:
			sorteo_ok = false
			detalle = m)
		if l2.objetivos.size() != int(nivel.get("objetivos_por_partida", 0)):
			sorteo_ok = false
			detalle = "objetivos por partida %d" % l2.objetivos.size()
		# Tocable: cada objetivo con un toque en su centro visible (y su escondite abierto antes).
		var rondas := int(nivel.get("escenas", 1))
		for r in rondas:
			for id in l2.objetivos.duplicate():
				if id in l2.encontrados:
					continue
				var res := _encontrar(l2, id)
				if not id in l2.encontrados:
					tocable_ok = false
					detalle = "semilla %d: %s no se encontro (%s)" % [semilla, id, res]
			if l2.estado == "ronda":
				l2.siguiente_ronda_escena()
				if not l2.ultimo_sorteo_unico:
					sorteo_ok = false
					detalle = "semilla %d: la 2.a escena no separo a todos" % semilla
		if l2.estado != "gano":
			gana_ok = false
	_check(sorteo_ok, "%s: sorteo (12 semillas) siempre declarado, sin piezas compartidas ni cajas pisadas %s" % [nombre, detalle if not sorteo_ok else ""])
	_check(tocable_ok, "%s: cada objetivo se encuentra tocando su centro visible %s" % [nombre, detalle if not tocable_ok else ""])
	_check(gana_ok, "%s: la partida se gana al encontrarlos a todos" % nombre)


func _check_sorteo_silencioso(l: LogicaBuscar, falla: Callable) -> void:
	var piezas := {}
	var cajas: Array = []
	for id in l.en_escena():
		var i := int(l.asignacion.get(id, -1))
		if i < 0 or i >= l.escondites_de(id).size():
			falla.call("%s sin escondite declarado" % id)
			return
		var pieza := l.pieza_de(l.escondite(id))
		if piezas.has(pieza):
			falla.call("%s comparte %s con %s" % [id, pieza, piezas[pieza]])
			return
		piezas[pieza] = id
		var caja := l.caja_escondite(l.escondite(id))
		for otra in cajas:
			if LogicaBuscar.se_pisan(otra, caja):
				falla.call("%s se pisa con otro escondite" % id)
				return
		cajas.append(caja)


func _probar_nivel_equipo_datos() -> void:
	var nivel := _leer(EQUIPO)
	_check(nivel.get("modo_juego") == "equipo" and nivel.get("sol") == null, "equipo: nivel de equipo, sin sol (el reloj es el rival)")
	var eq: Dictionary = nivel.get("equipo", {})
	var tope: Dictionary = eq.get("aciertos_max_turno", {})
	_check(int(tope.get("semilla", 0)) == 1 and int(tope.get("brote", 0)) == 1 and int(tope.get("estrella", 0)) == 2, "equipo: tope por turno 1 / 1 / 2")
	var seg: Dictionary = eq.get("segundos_por_turno", {})
	_check(int(seg.get("brote", 0)) == 40 and int(seg.get("estrella", 0)) == 35 and not seg.has("semilla"), "equipo: 40 s Nicole, 35 s Sofia (Maxi: jugada automatica)")
	_check(nivel.get("escena", {}).get("tamano", []) == [2560.0, 720.0] and nivel.get("objetivos", []).size() == 6, "equipo: escena 2560 x 720 con 6 objetivos")


# ---------------------------------------------------------------------------
# 4. Reglas
# ---------------------------------------------------------------------------

func _probar_reglas() -> void:
	print("-- reglas --")
	# Brote: uno a la vez, "ya encontrado", un toque abre y encuentra.
	var nivel := _leer(_ruta(4, "brote"))
	var l := _logica(nivel, 7)
	var eventos: Array = []
	l.ya_encontrado.connect(func(id: String) -> void: eventos.append("ya:" + id))
	l.encontrado.connect(func(id: String, p: int, r: int, o: bool) -> void: eventos.append("enc:%s:%d:%d:%s" % [id, p, r, o]))
	var primero := l.activo()
	var segundo: String = l.objetivos[1]
	_check(l.activos().size() == 1, "Brote: un objetivo activo a la vez")
	_encontrar(l, segundo)
	_check(segundo in l.encontrados and l.activo() == primero, "Brote: tocar uno de la lista que no es el activo lo encuentra igual")
	_encontrar(l, primero)
	_check("ya:" + segundo in eventos, "Brote: al llegar su turno avisa '¡ese ya lo encontraste!'")
	var abrible := ""
	for oid in l.objetos:
		if bool(l.objetos[oid].get("escondite", false)):
			abrible = oid
	_check(abrible != "", "Brote z5: hay escondites que se abren")
	# Forzar a un objetivo dentro de la pieza y abrir con un toque.
	var forzado := ""
	for id in l.faltan():
		for k in l.escondites_de(id).size():
			if str(l.escondites_de(id)[k].get("dentro_de", "")) != "":
				l.fijar_escondite(id, k)
				forzado = id
				break
		if forzado != "":
			break
	if forzado != "":
		var pieza := l.pieza_de(l.escondite(forzado))
		l.abiertos.erase(pieza)
		l._medidas.clear()
		var r := l.tocar(_punto_pieza(l, pieza))
		_check(r["tipo"] == "encontrado" and r["id"] == forzado, "Brote: un toque abre el escondite y encuentra (%s en %s: %s)" % [forzado, pieza, r])
	# Estrella: senuelo corta la racha; objetos no; ojo de aguila; 2 pasos.
	var ne := _leer(_ruta(3, "estrella"))
	var e := _logica(ne, 11)
	var enc: Array = []
	e.encontrado.connect(func(id: String, p: int, r: int, o: bool) -> void: enc.append([id, p, r, o]))
	var a1: String = e.activos()[0]
	_encontrar_limpio(e, a1)
	_check(not enc.is_empty() and enc[-1][2] == 1 and enc[-1][3] == true and enc[-1][1] >= 200, "Estrella: primer encontrado sin tocar nada: racha 1 + ojo de aguila (%s)" % [enc[-1] if not enc.is_empty() else []])
	# Tocar un objeto que no esconde a nadie: no corta la racha, si el ojo de aguila.
	var objeto_libre := ""
	for oid in e.orden_objetos:
		if e.animal_dentro(oid) == "" and not bool(e.objetos[oid].get("escondite", false)):
			objeto_libre = oid
			break
	var hay := e.que_hay(_punto_pieza(e, objeto_libre))
	if hay["tipo"] == "objeto":
		e.tocar_objeto(objeto_libre)
	var a2: String = e.activos()[0]
	_encontrar_limpio(e, a2)
	_check(enc[-1][2] == 2 and enc[-1][3] == false, "Estrella: tocar un objeto no corta la racha (x2) pero quita el ojo de aguila")
	var senuelo: String = e.senuelos[0]
	var r2 := e.tocar_animal(senuelo)
	_check(r2["tipo"] == "senuelo" and e.racha == 0, "Estrella: el senuelo saluda y corta la racha")
	# Objetivo superpuesto a un senuelo: gana el objetivo.
	var obj_id: String = e.activos()[0]
	if e.revelado(obj_id):
		var centro: Vector2 = e.medida(obj_id)["centro"]
		var guardado := e.asignacion.duplicate()
		var sen_esc := e.escondite(senuelo).duplicate()
		var falso := sen_esc.duplicate()
		falso["pos"] = [e.pie_animal(obj_id).x, e.pie_animal(obj_id).y]
		falso["z"] = e.z_animal(obj_id) + 0.1
		e.animales[senuelo]["escondites"].append(falso)
		e.fijar_escondite(senuelo, e.escondites_de(senuelo).size() - 1)
		_check(e.que_hay(centro)["id"] == obj_id, "un toque sobre un objetivo superpuesto a un senuelo da el objetivo")
		e.animales[senuelo]["escondites"].pop_back()
		e.asignacion = guardado
		e._medidas.clear()
	# Dos pasos (z4 Estrella tiene 2 de 2 pasos).
	var dos := ""
	for oid in e.objetos:
		if int(e.objetos[oid].get("pasos", 1)) == 2:
			dos = oid
	_check(dos != "", "Estrella z4: hay escondites de 2 pasos")
	var quien := ""
	for id in e.faltan():
		for k in e.escondites_de(id).size():
			if str(e.escondites_de(id)[k].get("dentro_de", "")) == dos:
				e.fijar_escondite(id, k)
				quien = id
		if quien != "":
			break
	if quien != "":
		for otro in e.en_escena():
			if otro != quien and e.pieza_de(e.escondite(otro)) == dos:
				e.asignacion[otro] = (int(e.asignacion[otro]) + 1) % e.escondites_de(otro).size()
		var p := _punto_pieza(e, dos)
		var t1 := e.tocar(p)
		_check(t1["tipo"] == "paso" and not e.revelado(quien), "2 pasos: el primer toque entreabre (sigue escondido)")
		var t2 := e.tocar(p)
		_check(t2["tipo"] == "abrio" and e.revelado(quien), "2 pasos: el segundo abre y se ve (Estrella toca despues al animal)")
		var antes := e.puntos
		e.tocar(e.medida(quien)["centro"])
		_check(quien in e.encontrados and e.puntos - antes >= 200, "2 pasos: encontrado con +100 de escondite de 2 pasos")
	# Semilla: libre, cualquier animal vale.
	var s := _logica(_leer(_ruta(0, "semilla")), 5)
	_check(s.activos().size() == s.objetivos.size(), "Semilla: sin lista, todos valen")
	var ultimo: String = s.objetivos[-1]
	_encontrar(s, ultimo)
	_check(ultimo in s.encontrados and s.puntos == 0, "Semilla: cualquiera vale y no hay puntaje")


func _encontrar_limpio(l: LogicaBuscar, id: String) -> void:
	# Abrir el escondite de alguien no corta el ojo de aguila.
	_encontrar(l, id)


# ---------------------------------------------------------------------------
# 5. Sol, reintento, regalo, ayuda fuerte y descanso
# ---------------------------------------------------------------------------

func _probar_sol() -> void:
	print("-- sol --")
	for perfil in PERFILES:
		var nivel := _leer(_ruta(1, perfil))
		var l := _logica(nivel, 9)
		var par := float(nivel["tiempo_par_s"])
		_check(is_equal_approx(l.limite, par * SOL[perfil][0]), "%s: el sol dura %s x par (%.0f s)" % [perfil, SOL[perfil][0], l.limite])
		var puesto := [false]
		l.sol_puesto.connect(func() -> void: puesto[0] = true)
		var id0: String = l.objetivos[0]
		_encontrar(l, id0)
		var asig_antes := l.asignacion.duplicate()
		l.avanzar(l.limite + 0.1)
		_check(puesto[0] and l.estado == "perdio" and l.derrotas == 1, "%s: se puso el sol -> derrota" % perfil)
		_check(l.tocar(l.medida(l.objetivos[1])["centro"])["tipo"] == "nada", "%s: perdido, ya no se encuentra nada" % perfil)
		l.reintentar()
		_check(id0 in l.encontrados and l.estado == "jugando", "%s: reintento de un toque; los encontrados quedan" % perfil)
		var cambiaron := 0
		for id in l.faltan():
			if l.escondites_de(id).size() > 1 and int(l.asignacion[id]) != int(asig_antes[id]):
				cambiaron += 1
		_check(cambiaron >= maxi(1, l.faltan().size() / 2), "%s: los que faltan se cambian de escondite (%d de %d)" % [perfil, cambiaron, l.faltan().size()])
		var esperado := maxf(par * SOL[perfil][0] * l.faltan().size() / l.objetivos.size(), SOL[perfil][1])
		_check(is_equal_approx(l.limite, esperado), "%s: sol proporcional a los que faltan, minimo %d s (%.0f)" % [perfil, SOL[perfil][1], l.limite])
		# Hasta el regalo.
		while l.derrotas < REGALO[perfil]:
			l.avanzar(l.limite + 0.1)
			l.reintentar()
		_check(l.regalo_disponible(), "%s: regalo de Toby tras %d derrotas" % [perfil, REGALO[perfil]])
		var antes := l.encontrados.size()
		var regalado := l.regalar()
		_check(regalado != "" and l.encontrados.size() == antes + 1 and regalado in l.regalados, "%s: Toby encuentra uno con el olfato" % perfil)
		if perfil == "semilla":
			l.avanzar(l.limite + 0.1)
			l.reintentar()
			_check(l.ayuda_fuerte() and l.limite == 0.0, "semilla: ayuda fuerte tras 3 derrotas: sin sol (victoria asegurada)")
			var todos := true
			for id in l.faltan():
				if float(l.asomados.get(id, 0)) < 1.0:
					todos = false
			_check(todos, "semilla: con la ayuda fuerte todos asoman a la vez")
			l.avanzar(10000.0)
			_check(l.estado == "jugando", "semilla: con la ayuda fuerte el sol no se pone")
			_check(not l.ofrecer_descanso(), "semilla: nunca se ofrece descansar")
		else:
			while l.derrotas < (3 if perfil == "brote" else 4):
				l.avanzar(l.limite + 0.1)
				l.reintentar()
			_check(l.ofrecer_descanso(), "%s: se ofrece descansar tras %d derrotas" % [perfil, l.derrotas])
			_check(l.estrellitas_en_vivo() <= 2, "%s: tras perder, como mucho 2 estrellitas" % perfil)


# ---------------------------------------------------------------------------
# 6. Escena: jugar cada nivel en el motor
# ---------------------------------------------------------------------------

func _instanciar(ruta: String, semilla := 4, planeta := "", perfil_id := "") -> Node:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.planeta_id = planeta
	motor.id_perfil = perfil_id
	motor.segundos_auto_continuar = 0.3
	motor.fijar_semilla(semilla)
	get_root().add_child(motor)
	return motor


func _jugar_todo(motor: Node) -> bool:
	var l: LogicaBuscar = motor.logica
	motor.tocar_pantalla(Vector2(640, 300))  # salta la intro
	for ronda in 3:
		if not await _esperar_que(func() -> bool: return motor.fase() == "jugando", 6.0):
			return false
		for id in l.objetivos.duplicate():
			if id in l.encontrados:
				continue
			var vueltas := 0
			while not l.revelado(id) and not id in l.encontrados and vueltas < 4:
				motor.tocar_mundo(_punto_pieza(l, l.pieza_de(l.escondite(id))))
				vueltas += 1
			if not id in l.encontrados:
				motor.tocar_mundo(l.medida(id)["centro"])
		if l.estado == "gano":
			return true
	return l.estado == "gano"


func _jugar_escena(zi: int, perfil: String) -> void:
	var nombre := "escena z%d %s" % [zi + 1, perfil]
	var motor := _instanciar(_ruta(zi, perfil), 20 + zi)
	var completado := [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	await process_frame
	_check(motor.fase() == "intro", "%s: arranca con Toby contando (intro)" % nombre)
	var gano := await _jugar_todo(motor)
	_check(gano, "%s: se juega entero tocando a cada animal" % nombre)
	_check(await _esperar_que(func() -> bool: return completado[0] >= 0, 12.0), "%s: foto de grupo y `completado(%d)`" % [nombre, completado[0]])
	if perfil == "estrella" and zi >= 2:
		_check(motor._boton_lupa.visible, "%s: la lupa esta disponible desde z3" % nombre)
	motor.queue_free()
	await process_frame


func _probar_derrota_escena(perfil: String, zi: int) -> void:
	var nombre := "derrota escena z%d %s" % [zi + 1, perfil]
	var motor := _instanciar(_ruta(zi, perfil), 31)
	var l: LogicaBuscar = motor.logica
	var completado := [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	motor.tocar_pantalla(Vector2(640, 300))
	await _esperar_que(func() -> bool: return motor.fase() == "jugando", 4.0)
	var id0: String = l.objetivos[0]
	if l.revelado(id0):
		motor.tocar_mundo(l.medida(id0)["centro"])
	else:
		_encontrar(l, id0)
	l.t_intento = l.limite - 0.01
	_check(await _esperar_que(func() -> bool: return motor.fase() == "perdio", 3.0), "%s: se pone el sol -> gag '¡Se puso el sol!'" % nombre)
	_check(is_equal_approx(motor.duracion_gag(), 1.5 if perfil == "semilla" else 2.5), "%s: gag de %.1f s" % [nombre, motor.duracion_gag()])
	_check(await _esperar_que(func() -> bool: return motor._fin.visible, 4.0), "%s: cartel con '¡otra vez!' grande" % nombre)
	_check(motor._boton_reintentar.size.x >= 160, "%s: boton de reintento >= 160 px" % nombre)
	_check(completado[0] < 0, "%s: perder no emite completado ni da destellos" % nombre)
	# Toque en cualquier parte del cartel = otra vez.
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = motor._rect_cartel().position + Vector2(30, 30)
	motor._al_input_fin(ev)
	_check(not motor._fin.visible and id0 in l.encontrados, "%s: tocar el cartel reintenta y lo encontrado queda" % nombre)
	# Llegar al regalo con derrotas seguidas.
	while l.derrotas < REGALO[perfil]:
		await _esperar_que(func() -> bool: return motor.fase() == "jugando", 4.0)
		l.t_intento = l.limite - 0.01
		await _esperar_que(func() -> bool: return motor.fase() == "perdio", 3.0)
		motor.reintentar()
	var antes := l.encontrados.size()
	_check(await _esperar_que(func() -> bool: return l.encontrados.size() > antes, 6.0), "%s: tras %d derrotas Toby regala uno en la escena" % [nombre, REGALO[perfil]])
	motor.queue_free()
	await process_frame


func _probar_entrada_y_lupa() -> void:
	print("-- entrada, lupa y mapita --")
	var motor := _instanciar(_ruta(2, "estrella"), 8)
	var l: LogicaBuscar = motor.logica
	motor.tocar_pantalla(Vector2(640, 300))
	await _esperar_que(func() -> bool: return motor.fase() == "jugando", 4.0)
	motor.presionar(Vector2(700, 300))
	_check(motor._ondas.size() >= 1, "presionar: onda al instante bajo el dedo")
	var vista0: Vector2 = motor._vista
	motor.mover(Vector2(600, 300))
	motor.soltar(Vector2(600, 300))
	_check(motor._vista.x > vista0.x + 50, "arrastrar > 16 px recorre la escena (%.0f -> %.0f)" % [vista0.x, motor._vista.x])
	var toques := [0]
	l.objeto_tocado.connect(func(_id: String) -> void: toques[0] += 1)
	var oid: String = l.orden_objetos[l.orden_objetos.size() / 2]
	motor.mover_vista_a(G.caja_de(l.cobertura_objeto(oid)).get_center(), 0.0)
	await process_frame
	var punto: Vector2 = motor.mundo_a_pantalla(_punto_pieza(l, oid))
	if l.que_hay(_punto_pieza(l, oid))["tipo"] == "objeto" and not bool(l.objetos[oid].get("escondite", false)):
		motor.presionar(punto)
		motor.mover(punto + Vector2(10, 0))
		motor.soltar(punto)
		_check(toques[0] == 1, "un toque que se mueve < 16 px es toque: la pieza reacciona (%s en %s, fase %s, vista %s)" % [oid, punto, motor.fase(), motor._vista])
		motor.presionar(punto)
		motor.mover(punto + Vector2(40, 0))
		motor.soltar(punto)
		_check(toques[0] == 1, "si se mueve > 16 px es arrastre: no toca nada")
	motor.usar_lupa()
	_check(motor.lupa_armada(), "lupa: un toque la arma")
	motor.tocar_pantalla(Vector2(640, 300))
	await _esperar(0.5)
	_check(is_equal_approx(motor.zoom_actual(), 2.0) and not motor.lupa_armada(), "lupa: el siguiente toque acerca 2x ahi")
	motor.usar_lupa()
	await _esperar(0.5)
	_check(is_equal_approx(motor.zoom_actual(), 1.0), "lupa: tocarla con zoom vuelve a 1x")
	motor.tocar_pantalla(motor._rect_mapa().end - Vector2(4, 4))
	await _esperar(0.5)
	_check(motor._vista.x > l.tamano_escena.x - 1280 - 40, "mapita: tocarlo lleva la escena ahi")
	# Radar de Toby: con 3 estrellitas abre el globo y cuesta una.
	motor.tocar_toby()
	_check(motor._pista_costo.globo_abierto(), "radar de Toby: pide confirmacion (cuesta una estrellita)")
	motor._pista_costo.confirmar()
	_check(l.pistas == 1 and l.estrellitas_en_vivo() == 2, "radar de Toby: confirmado, la partida queda en 2 estrellitas")
	_check(not motor._circulo_pista.is_empty() or not motor._borde_pista.is_empty(), "radar de Toby: circulo calido o borde que brilla")
	motor.queue_free()
	await process_frame


func _probar_guardado() -> void:
	print("-- guardado (pruebas) --")
	# Sofia: parcial tras cada encontrado; al volver retoma encontrados y escondites.
	var ruta := _ruta(0, "estrella")
	var motor := _instanciar(ruta, 12, "animalia", "sofia")
	var l: LogicaBuscar = motor.logica
	motor.tocar_pantalla(Vector2(640, 300))
	await _esperar_que(func() -> bool: return motor.fase() == "jugando", 4.0)
	var id0: String = l.activos()[0]
	var res := _encontrar(l, id0)
	var asig := l.asignacion.duplicate()
	var objs := l.objetivos.duplicate()
	_check(not _progreso.obtener_estado_parcial("sofia", "animalia", "animalia_z1_buscar_estrella").is_empty(), "Sofia: guardado parcial tras encontrar (%s)" % res["tipo"])
	motor.queue_free()
	await process_frame
	var motor2 := _instanciar(ruta, 77, "animalia", "sofia")
	var l2: LogicaBuscar = motor2.logica
	_check(id0 in l2.encontrados and l2.asignacion == asig and l2.objetivos == objs, "Sofia: al volver retoma encontrados, objetivos y escondites")
	var gano := await _jugar_todo(motor2)
	_check(gano and _progreso.esta_nivel_completado("sofia", "animalia", "animalia_z1_buscar_estrella"), "Sofia: al ganar la estacion queda completada")
	_check(_progreso.obtener_estado_parcial("sofia", "animalia", "animalia_z1_buscar_estrella").is_empty(), "Sofia: al ganar se borra el parcial")
	var estrellitas: int = _progreso.obtener_estrellitas_nivel("sofia", "animalia", "animalia_z1_buscar_estrella")
	_check(estrellitas >= 1 and estrellitas <= 3, "Sofia: estrellitas por puntaje registradas (%d)" % estrellitas)
	motor2.queue_free()
	await process_frame
	# Huevito de Dinito (HE-120): tocarlo marca animalia_huevo_z<n> en el hermano.
	var motor3 := _instanciar(_ruta(1, "brote"), 5, "animalia", "nicole")
	var l3: LogicaBuscar = motor3.logica
	motor3.tocar_pantalla(Vector2(640, 300))
	await _esperar_que(func() -> bool: return motor3.fase() == "jugando", 4.0)
	_check(not _progreso.especial_conocido("nicole", "animalia_huevo_z2"), "huevito: antes de tocarlo no hay marca")
	var r := _encontrar(l3, "huevito")
	_check(r["tipo"] == "secreto" and _progreso.especial_conocido("nicole", "animalia_huevo_z2"), "huevito de Dinito: tocarlo marca 'animalia_huevo_z2' para el mapa (%s)" % r["tipo"])
	_check(not _progreso.esta_nivel_completado("nicole", "animalia", "animalia_z2_buscar_brote"), "el secreto no cuenta como objetivo ni completa nada")
	motor3.queue_free()
	await process_frame
	# Derrota con guardado: 0 destellos.
	var motor4 := _instanciar(_ruta(0, "brote"), 6, "animalia", "nicole")
	var l4: LogicaBuscar = motor4.logica
	motor4.tocar_pantalla(Vector2(640, 300))
	await _esperar_que(func() -> bool: return motor4.fase() == "jugando", 4.0)
	l4.t_intento = l4.limite
	await _esperar_que(func() -> bool: return motor4.fase() == "perdio", 3.0)
	_check(not _progreso.esta_nivel_completado("nicole", "animalia", "animalia_z1_buscar_brote"), "perder no registra la estacion ni destellos")
	motor4.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 7. Modo equipo
# ---------------------------------------------------------------------------

func _abrir_turno(motor: Node, id: String) -> bool:
	var g: GestorTurnos = motor.turnos
	if not await _esperar_que(func() -> bool: return g.en_puerta(), 12.0):
		return false
	g.abrir_puerta()
	return await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada() and g.hermano_actual() == id, 6.0)


func _probar_equipo() -> void:
	print("-- modo equipo --")
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = EQUIPO
	var tres: Array[String] = ["maxi", "nicole", "sofia"]
	motor.equipo = tres
	motor.segundos_auto_continuar = 0.3
	motor.fijar_semilla(5)
	get_root().add_child(motor)
	var g: GestorTurnos = motor.turnos
	g.escala_tiempo = 0.05
	var eventos: Array = []
	g.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: eventos.append("cerrado:%s:%s" % [id, perfecto]))
	g.rival_llego.connect(func() -> void: eventos.append("llego"))
	g.tope_alcanzado.connect(func() -> void: eventos.append("tope"))
	var l: LogicaBuscar = motor.logica
	_check(g != null and l.limite == 0.0, "equipo: gestor de turnos armado y sin sol")
	_check(await _abrir_turno(motor, "maxi"), "equipo: empieza Maxi tras su puerta")
	var activo := l.activo()
	_check(float(l.asomados.get(activo, 0)) >= 1.0 and l.zona_min == 160.0, "equipo Maxi: el activo asoma y la zona de toque es de 160 px")
	motor.tocar_mundo(l.medida(activo)["centro"])
	_check(activo in l.encontrados and "tope" in eventos, "equipo Maxi: encontrar 1 llega al tope (1)")
	_check(await _esperar_que(func() -> bool: return "cerrado:maxi:false" in eventos, 6.0), "equipo: con el animal en su tarjeta el turno se confirma estable")
	_check(await _abrir_turno(motor, "nicole"), "equipo: le toca a Nicole")
	_check(l.zona_min == 96.0, "equipo Nicole: zona de toque de 96 px")
	var activo_n := l.activo()
	var asig_antes := int(l.asignacion[activo_n])
	motor.cortar_turno_por_tiempo()
	_check(int(l.asignacion[activo_n]) != asig_antes or l.escondites_de(activo_n).size() == 1, "equipo: sin encontrar a tiempo, el activo se cambia de escondite")
	_check(await _esperar_que(func() -> bool: return "cerrado:nicole:false" in eventos, 4.0), "equipo: y el turno de Nicole termina con fallo")
	_check(await _abrir_turno(motor, "maxi"), "equipo: vuelve Maxi")
	var antes := l.encontrados.size()
	motor._jugada_automatica_equipo()
	_check(l.encontrados.size() == antes + 1, "equipo: jugada automatica de Maxi (el activo salta solo)")
	_check(await _abrir_turno(motor, "sofia"), "equipo: le toca a Sofia")
	_check(l.zona_min == 64.0 and not l.abrir_y_encontrar, "equipo Sofia: zona de 64 px y escondites en 2 toques")
	var a1 := l.activo()
	_encontrar(l, a1)
	_check(not "tope" in eventos.slice(eventos.rfind("cerrado:maxi:false")) or eventos.count("tope") == 2, "equipo Sofia: 1 encontrado no llega a su tope de 2")
	# Derrota del equipo: el rival llega -> aspirar y devolver con escondites nuevos.
	g._pos_rival = g.pasos_rival() - 1
	var faltan_antes := l.faltan()
	var asig := l.asignacion.duplicate()
	motor.cortar_turno_por_tiempo()
	_check(await _esperar_que(func() -> bool: return "llego" in eventos, 6.0), "equipo: el rival llega -> derrota-gag de la base")
	_check(await _esperar_que(func() -> bool: return motor._eq_gag.get("fase", "") == "devolver" or motor._eq_gag.is_empty(), 4.0), "equipo: aspira a los que faltan y los estornuda")
	var cambiados := 0
	for id in faltan_antes:
		if int(l.asignacion[id]) != int(asig[id]):
			cambiados += 1
	_check(cambiados >= 1 and motor.contar_logro_equipo() == l.encontrados.size(), "equipo: los no encontrados vuelven a escondites nuevos (%d) y el logro comun son los encontrados" % cambiados)
	motor.tocar_otra_vez_equipo()
	# Victoria: encontrar al resto.
	var completado := [-1]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	for id in l.faltan():
		l.tocar_animal(id)
	_check(motor._eq_victoria, "equipo: con los 6 encontrados gana el equipo")
	_check(await _esperar_que(func() -> bool: return completado[0] >= 0, 12.0), "equipo: fiesta del equipo y completado")
	motor.queue_free()
	await process_frame
