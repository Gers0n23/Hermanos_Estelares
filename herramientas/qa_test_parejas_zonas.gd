extends SceneTree

## QA de "Parejas de Coco" para Maxi (semilla) y Nicole (brote) en las 5 zonas del Planeta
## Arcoiris (PO 27-Sep-2026): rondas con pool, temas de sus gustos, banderas, mama y bebe,
## color <-> cosa, letra <-> dibujo y cartas que bailan.
##
## Por cada uno de los 10 niveles: valida los datos (rondas, pools mas grandes que lo que se usa,
## reglas por perfil, voces y dibujos que existen), sortea varias partidas para confirmar que el
## contenido cambia al rejugar y juega la partida completa ronda por ronda (un "no es este",
## todos los pares, mini-fiesta, siguiente ronda) hasta recibir `completado` con los destellos
## de todas las rondas.
##
## Uso: godot --headless --path . --script herramientas/qa_test_parejas_zonas.gd

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const Dibujos := preload("res://scripts/motores/emparejar/dibujos_emparejar.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const PERFILES := {"semilla": "maxi", "brote": "nicole"}
## Parejas por ronda que admite cada perfil (ficha de zonas §3.3) y lado minimo de carta (GDD §6.1).
const PARES_POR_PERFIL := {"semilla": [2, 5], "brote": [3, 6]}
const LADO_MINIMO := 96.0

var _fallos := 0
var _pares_jugados := {"semilla": 0, "brote": 0}


func _initialize() -> void:
	print("=== QA Parejas de Coco: Maxi y Nicole en las 5 zonas ===")
	for zona in ZONAS:
		for perfil in PERFILES:
			await _probar_nivel("res://datos/niveles/arcoiris/%s/parejas_%s.json" % [zona, perfil], perfil)
	print("pares por partida completa (5 zonas): Maxi %d, Nicole %d" % [_pares_jugados["semilla"], _pares_jugados["brote"]])
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


func _probar_nivel(ruta: String, perfil: String) -> void:
	print("-- %s (%s) --" % [ruta.trim_prefix("res://datos/niveles/arcoiris/"), PERFILES[perfil]])
	_check(FileAccess.file_exists(ruta), "el nivel existe")
	var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var rondas: Array = nivel.get("rondas", [])
	_check(nivel.get("perfil") == perfil and nivel.get("motor") == "emparejar", "perfil %s y motor emparejar" % perfil)
	_check(rondas.size() >= 2 and rondas.size() <= 3, "%d rondas (2-3)" % rondas.size())
	_check(nivel.get("limite_intentos") == null, "sin limite de intentos: nunca pierde")
	_validar_rondas(nivel, perfil)
	_validar_voces(nivel)
	_validar_rejugar(nivel)
	await _jugar(ruta, perfil, nivel)


func _validar_rondas(nivel: Dictionary, perfil: String) -> void:
	var rango: Array = PARES_POR_PERFIL[perfil]
	var datos_ok := true
	var dibujos_ok := true
	var detalle := []
	for i in nivel["rondas"].size():
		var ronda: Dictionary = nivel["rondas"][i]
		var pool: Array = ronda.get("pool", [])
		var cantidad := int(ronda.get("cantidad", 0))
		var oculto := bool(ronda.get("oculto", nivel.get("oculto", false)))
		var ids := {}
		for par: Dictionary in pool:
			ids[par["id_pareja"]] = true
			for clave in ["elemento_a", "elemento_b"]:
				var e: Dictionary = par[clave]
				var figura := str(e.get("figura", ""))
				if not (figura in Figura.FIGURAS or Dibujos.tiene(figura) or (e.get("estilo") == "letra" and str(e.get("letra", "")) != "")):
					dibujos_ok = false
					detalle.append(figura)
		datos_ok = datos_ok and cantidad >= rango[0] and cantidad <= rango[1] and pool.size() >= cantidad and ids.size() == pool.size()
		if perfil == "semilla":
			datos_ok = datos_ok and not oculto
		var fijos := pool.filter(func(p): return p.get("fijo", false)).size()
		print("        ronda %d: %s · %d de un pool de %d%s%s%s" % [i + 1, ronda.get("tema", "?"), cantidad, pool.size(),
			" · tapadas" if oculto else " · a la vista", " · bailan" if ronda.get("cartas_bailan", 0) else "",
			" · %d fija(s)" % fijos if fijos else ""])
	_check(datos_ok, "rondas con %d-%d parejas, pool suficiente, ids unicos%s" % [rango[0], rango[1], " y siempre a la vista (Maxi)" if perfil == "semilla" else ""])
	_check(dibujos_ok, "todas las cartas tienen dibujo %s" % ("" if dibujos_ok else str(detalle)))


## Toda voz que el nivel pueda pedir existe importada: generales, de ronda, por pareja y al tocar.
func _validar_voces(nivel: Dictionary) -> void:
	var rutas := []
	var juntar := func(valor) -> void:
		for r in (valor if valor is Array else [valor]):
			if str(r) != "":
				rutas.append(str(r))
	for clave in nivel.get("lineas_voz", {}):
		juntar.call(nivel["lineas_voz"][clave])
	for ronda: Dictionary in nivel["rondas"]:
		for clave in ronda.get("lineas_voz", {}):
			juntar.call(ronda["lineas_voz"][clave])
		for par: Dictionary in ronda.get("pool", []):
			juntar.call(par.get("voz", ""))
			for clave in ["elemento_a", "elemento_b"]:
				juntar.call(par[clave].get("voz_toque", ""))
	# HE-60: las voces del reto (racha, record, vela, vistazo, estrellitas) estan en el guion pero aun no
	# se generan (HE-67, requiere OK de costo del PO); el motor cae a la voz generica si faltan.
	var reto := rutas.filter(func(r): return str(r).contains("/emparejar/reto/"))
	var faltan := rutas.filter(func(r): return not str(r).contains("/emparejar/reto/") and not ResourceLoader.exists("res://assets/audio/" + r))
	_check(faltan.is_empty(), "%d voces del nivel existen %s" % [rutas.size() - reto.size(), "" if faltan.is_empty() else str(faltan)])
	var reto_faltan := reto.filter(func(r): return not ResourceLoader.exists("res://assets/audio/" + r))
	if not reto_faltan.is_empty():
		print("  PEND  %d voces de reto (HE-67) aun sin grabar" % reto_faltan.size())
	for i in nivel["rondas"].size():
		if i > 0:
			_check(str(nivel["rondas"][i].get("lineas_voz", {}).get("intro_ronda", "")) != "", "la ronda %d trae su consigna por voz" % (i + 1))


## Sortea 12 partidas: el contenido cambia al rejugar y las parejas fijas (Chile) siempre estan.
func _validar_rejugar(nivel: Dictionary) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.nivel = nivel
	var vistas := {}
	var fijas_ok := true
	for intento in 12:
		motor._preparar_rondas()
		var firma := ""
		for i in motor._rondas.size():
			var ids: Array = motor._rondas[i]["pares"].map(func(p): return p["id_pareja"])
			ids.sort()
			firma += "|" + ",".join(ids)
			fijas_ok = fijas_ok and ids.size() == int(nivel["rondas"][i]["cantidad"])
			for par: Dictionary in nivel["rondas"][i]["pool"]:
				if par.get("fijo", false):
					fijas_ok = fijas_ok and ids.has(par["id_pareja"])
		vistas[firma] = true
	motor.free()
	_check(vistas.size() >= 4, "al rejugar cambia el contenido (%d combinaciones distintas en 12 partidas)" % vistas.size())
	_check(fijas_ok, "cada ronda usa su cantidad y las parejas fijas siempre entran")


func _jugar(ruta: String, perfil: String, nivel: Dictionary) -> void:
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = PERFILES[perfil]
	motor.segundos_auto_continuar = 0.5
	var completado := [-1]
	var intercambios := [0]
	motor.completado.connect(func(d: int) -> void: completado[0] = d)
	motor.carta_intercambiada.connect(func(_a, _b) -> void: intercambios[0] += 1)
	get_root().add_child(motor)
	await _esperar(0.8)
	var total_pares := 0
	var rondas: Array = nivel["rondas"]
	for i in rondas.size():
		var ronda: Dictionary = rondas[i]
		var cantidad := int(ronda["cantidad"])
		var t0 := Time.get_ticks_msec()
		while (motor._ronda != i or motor._en_transicion) and Time.get_ticks_msec() - t0 < 12000:
			await process_frame
		await _esperar(0.7)
		# HE-60: el vistazo al repartir (rondas tapadas de Nicole) bloquea el tablero unos segundos.
		var t_vistazo := Time.get_ticks_msec()
		while motor._en_vistazo and Time.get_ticks_msec() - t_vistazo < 15000:
			await process_frame
		var cartas: Array = motor._cartas
		var oculto := bool(ronda.get("oculto", nivel.get("oculto", false)))
		_check(motor._ronda == i and cartas.size() == cantidad * 2, "ronda %d: tablero con %d cartas (hay %d)" % [i + 1, cantidad * 2, cartas.size()])
		_check(motor._ranuras.size() == cantidad, "ronda %d: una ranura por pareja" % (i + 1))
		_check(_marcadores_ok(motor, i), "ronda %d: estrellas de ronda (ganadas doradas, la actual encendida)" % (i + 1))
		_probar_distribucion(motor, cartas, "ronda %d" % (i + 1))
		var tapadas_ok := cartas.all(func(c): return c.mostrando == (not oculto))
		_check(tapadas_ok, "ronda %d: cartas %s" % [i + 1, "tapadas (memoria)" if oculto else "a la vista"])
		_probar_contenido(motor, cartas, ronda, i)

		var por_pareja := {}
		for carta in cartas:
			if not por_pareja.has(carta.id_pareja):
				por_pareja[carta.id_pareja] = []
			por_pareja[carta.id_pareja].append(carta)
		var claves: Array = por_pareja.keys()
		# Un "no es este" amistoso: se deseleccionan solas, sin castigo.
		por_pareja[claves[0]][0].tocada.emit(por_pareja[claves[0]][0])
		por_pareja[claves[1]][0].tocada.emit(por_pareja[claves[1]][0])
		await _esperar(0.05)
		_check(motor._procesando and not motor._en_gag, "ronda %d: 'no es este' sin derrota" % (i + 1))
		motor._terminar_no_es_este()
		await _esperar(0.05)
		# Letras: tocar una letra dice su nombre (voz_toque).
		var bailes_antes: int = intercambios[0]
		for n in claves.size():
			var par: Array = por_pareja[claves[n]]
			par[0].tocada.emit(par[0])
			par[1].tocada.emit(par[1])
			if n == 0:
				_check(par[0].esta_acertada and par[1].esta_acertada, "ronda %d: pareja '%s' resuelta" % [i + 1, claves[n]])
			if n == 0 and int(ronda.get("cartas_bailan", 0)) > 0:
				await _esperar(motor.SEGUNDOS_BAILE + 1.4)
				_check(intercambios[0] > bailes_antes, "ronda %d: las cartas bailan de lugar tras el acierto" % (i + 1))
				_probar_distribucion(motor, cartas, "ronda %d tras el baile" % (i + 1))
			else:
				await _esperar(0.12)
		total_pares += cantidad
		if i < rondas.size() - 1:
			await _esperar(0.3)
			_check(motor._en_transicion, "ronda %d: mini-fiesta entre rondas (tablero en pausa)" % (i + 1))
			var carta: Node = cartas[0]
			if is_instance_valid(carta):
				motor._al_tocar_carta(carta)
			_check(motor._seleccionadas.is_empty(), "ronda %d: tocar durante la mini-fiesta no hace nada raro" % (i + 1))
	var t1 := Time.get_ticks_msec()
	while completado[0] < 0 and Time.get_ticks_msec() - t1 < 20000:
		await process_frame
	_pares_jugados[perfil] += total_pares
	_check(completado[0] == total_pares * motor.DESTELLOS_POR_PAR, "completado(destellos=%d) una vez al final, con las %d parejas de todas las rondas" % [completado[0], total_pares])
	motor.queue_free()
	await _esperar(0.1)


func _marcadores_ok(motor: Node, ronda: int) -> bool:
	if motor._marcadores.size() != motor._rondas.size():
		return false
	for j in motor._marcadores.size():
		var m = motor._marcadores[j]
		if j < ronda and not (m.figura == "estrella" and not m.con_disco):
			return false
		if j == ronda and m.figura != "estrella":
			return false
		if j > ronda and m.figura != "":
			return false
	return true


## Contenido especifico de cada tipo de ronda.
func _probar_contenido(motor: Node, cartas: Array, ronda: Dictionary, i: int) -> void:
	var tema := str(ronda.get("tema", ""))
	var etiqueta := "ronda %d" % (i + 1)
	if tema.begins_with("banderas"):
		var todas := cartas.all(func(c): return Dibujos.es_bandera(c.figura))
		var con_voz := cartas.all(func(c): return motor._voces_par.has(c.id_pareja))
		var chile_o_japon := cartas.any(func(c): return c.figura == "bandera_chile")
		_check(todas and con_voz, "%s: banderas, y cada pareja dice su pais" % etiqueta)
		_check(chile_o_japon, "%s: la bandera de Chile siempre esta" % etiqueta)
	if tema.begins_with("mama y bebe"):
		var ok := true
		for id in _ids(cartas):
			var escalas: Array = cartas.filter(func(c): return c.id_pareja == id).map(func(c): return c.escala)
			escalas.sort()
			ok = ok and escalas.size() == 2 and escalas[0] < 0.7 and is_equal_approx(escalas[1], 1.0)
		_check(ok, "%s: cada pareja es una mama grande y su bebe chiquito" % etiqueta)
	if tema.begins_with("color y cosa"):
		var ok := true
		for id in _ids(cartas):
			var par: Array = cartas.filter(func(c): return c.id_pareja == id)
			var mancha: Array = par.filter(func(c): return c.figura == "mancha")
			var cosa: Array = par.filter(func(c): return c.figura != "mancha")
			ok = ok and mancha.size() == 1 and cosa.size() == 1 and mancha[0].color_figura.is_equal_approx(cosa[0].color_figura) and motor._voces_par.has(id)
		_check(ok, "%s: cada mancha va con una cosa de su mismo color (y se nombra el color)" % etiqueta)
	if tema.begins_with("letras"):
		var ok := true
		for id in _ids(cartas):
			var par: Array = cartas.filter(func(c): return c.id_pareja == id)
			var letra: Array = par.filter(func(c): return c.estilo == "letra")
			ok = ok and letra.size() == 1 and letra[0].letra.length() == 1 and letra[0].voz_toque != "" and motor._voces_par.has(id)
		_check(ok, "%s: cada dibujo va con su letra inicial; la letra dice su nombre al tocarla y el par dice 'S de sol'" % etiqueta)


func _ids(cartas: Array) -> Array:
	var ids := {}
	for c in cartas:
		ids[c.id_pareja] = true
	return ids.keys()


func _probar_distribucion(motor: Node, cartas: Array, etiqueta: String) -> void:
	var pantalla := Rect2(0, 0, 1280, 720)
	var bloqueos := [
		motor.get_node("capa_ui/ui/boton_salir").get_global_rect(),
		motor.get_node("capa_ui/ui/boton_cometa").get_global_rect(),
		motor.get_node("%anfitriona").get_global_rect(),
		motor.get_node("%barra_progreso").get_global_rect(),
	]
	var dentro := true
	var sin_choques := true
	for i in cartas.size():
		var rect: Rect2 = Rect2(cartas[i].position, cartas[i].size)
		rect.position += motor.get_node("%tablero").global_position
		dentro = dentro and pantalla.encloses(rect)
		for bloqueo in bloqueos:
			sin_choques = sin_choques and not rect.intersects(bloqueo)
		for j in range(i + 1, cartas.size()):
			var otro := Rect2(cartas[j].position + motor.get_node("%tablero").global_position, cartas[j].size)
			sin_choques = sin_choques and not rect.intersects(otro)
	_check(cartas[0].size.x >= LADO_MINIMO, "%s: cartas de %.0f px (minimo %.0f)" % [etiqueta, cartas[0].size.x, LADO_MINIMO])
	_check(dentro and sin_choques, "%s: cartas dentro de la pantalla, sin tocarse ni tapar botones, Coco o la barra" % etiqueta)
