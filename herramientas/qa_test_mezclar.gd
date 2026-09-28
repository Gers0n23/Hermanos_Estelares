extends SceneTree

## Arnes QA del "Taller de pinturas de Coco" (motor mezclar, Sofia): juega los 5 niveles completos.
## Por nivel verifica: que existan todas las voces que nombra (incluida la receta de cada pedido),
## que cada pedido tenga receta y sus pigmentos caigan, tamanos tactiles, el bucle completo
## (receta -> atrapar -> agitar -> lata -> 3 latas -> mural), que los 3 pedidos de un mural sean
## distintos, el gag de gota equivocada (vacia SOLO la lata en curso, cuenta un fallo y nunca
## termina el nivel), la libreta (cuesta una estrellita), que dejar pasar gotas no castigue, una
## atrapada real con la fisica de caida, el solcito de z5 y que llegue `completado(destellos)`.
##
## Corre acelerado (Engine.time_scale). Uso:
## godot --headless --path . --script herramientas/qa_test_mezclar.gd [-- <filtro>]

const MOTOR := "res://escenas/minijuegos/mezclar/motor_mezclar.tscn"
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const VELOCIDAD := 6.0

var _fallos := 0
var _resumen: Array = []


func _initialize() -> void:
	print("=== QA mezclar: Taller de pinturas de Coco, 5 zonas de Sofia ===")
	Engine.time_scale = VELOCIDAD
	var filtro := ""
	if OS.get_cmdline_user_args().size() > 0:
		filtro = OS.get_cmdline_user_args()[0]
	for zona in ZONAS:
		var ruta := "res://datos/niveles/arcoiris/%s/mezcla_estrella.json" % zona
		if filtro != "" and not ruta.contains(filtro):
			continue
		await _probar_nivel(ruta, zona)
	Engine.time_scale = 1.0
	print("--- resumen ---")
	for linea in _resumen:
		print(linea)
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _chequear(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  ok  %s" % mensaje)
	else:
		_fallos += 1
		print("  FALLA %s" % mensaje)


func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout


func _esperar_fase(motor, fases: Array, maximo := 40.0) -> bool:
	var t := 0.0
	while not (motor.fase() in fases) and t < maximo:
		await _esperar(0.1)
		t += 0.1
	return motor.fase() in fases


func _existe_voz(ruta: String) -> bool:
	return ResourceLoader.exists("res://assets/audio/" + ruta)


func _probar_nivel(ruta: String, zona: String) -> void:
	print("\n## %s" % ruta)
	var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var escena: PackedScene = load(MOTOR)
	var motor = escena.instantiate()
	motor.ruta_nivel = ruta
	motor.id_perfil = "sofia"
	var resultado := {"destellos": -1}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	var murales_emitidos := [0]
	motor.mural_terminado.connect(func(_i: int) -> void: murales_emitidos[0] += 1)
	root.add_child(motor)
	await _esperar(0.1)

	# Datos y voces
	var voces: Dictionary = nivel.get("lineas_voz", {})
	var faltan_voces: Array = []
	for clave in voces:
		if str(clave).begins_with("prefijo_"):
			continue
		var valor = voces[clave]
		for r in (valor if valor is Array else [valor]):
			if not _existe_voz(str(r)):
				faltan_voces.append(str(r))
	for color in nivel["pedidos"]:
		if not _existe_voz(str(voces["prefijo_recetas"]) + str(color) + ".wav"):
			faltan_voces.append("receta " + str(color))
	_chequear(faltan_voces.is_empty(), "todas las voces existen %s" % str(faltan_voces))
	var sin_receta: Array = (nivel["pedidos"] as Array).filter(func(c) -> bool: return not motor._recetas.has(str(c)))
	_chequear(sin_receta.is_empty(), "todos los pedidos tienen receta %s" % str(sin_receta))
	var pigmentos_ok := true
	for color in nivel["pedidos"]:
		for pigmento in motor._recetas[str(color)]:
			pigmentos_ok = pigmentos_ok and motor._pigmentos.has(pigmento)
	_chequear(pigmentos_ok, "los pigmentos de todas las recetas caen (%s)" % str(motor._pigmentos))
	_chequear(motor._boton_libreta.size.x >= 96.0 and motor._boton_listo.size.y >= 96.0 and motor._tam_gota >= 64.0,
		"tamanos tactiles (libreta %s, listo %s, gota %d)" % [motor._boton_libreta.size, motor._boton_listo.size, motor._tam_gota])

	var murales: int = int(nivel.get("murales", 2))
	var probe_sucio := false
	var probe_libreta := false
	var probe_pasar := false
	var probe_fisica := false
	var probe_solcito := false
	var pedidos_vistos: Array = []
	var latas_hechas := 0
	var inicio := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - inicio < 150000:
		var fase: String = motor.fase()
		match fase:
			"receta":
				if motor.tarjeta_visible() and motor._tarjeta_modo == "memorizar":
					if not probe_solcito and float(nivel.get("memorizar_s", 0)) > 0.0:
						# z5: la receta se esconde sola (reloj real: voz + memorizar_s).
						probe_solcito = true
						var t0 := Time.get_ticks_msec()
						while motor.tarjeta_visible() and Time.get_ticks_msec() - t0 < 20000:
							await _esperar(0.2)
						_chequear(not motor.tarjeta_visible(), "z5: la receta se esconde sola tras el solcito")
					else:
						motor.confirmar_receta()
				await _esperar(0.3)
			"atrapar":
				if not pedidos_vistos.has(motor.pedidos_mural()):
					var p: Array = motor.pedidos_mural()
					pedidos_vistos.append(p)
					_chequear(p.size() == 3 and p[0] != p[1] and p[1] != p[2] and p[0] != p[2], "mural con 3 latas distintas %s" % str(p))
				if not probe_pasar:
					probe_pasar = true
					var antes: int = motor.fallos()
					motor._mover_frasco_a(motor.FRASCO_MAX_X if motor.frasco_x() < 690.0 else motor.FRASCO_MIN_X)
					var t := 0.0
					var llegaron := 0
					while t < 8.0 and llegaron == 0:
						var n: int = motor.gotas_en_pantalla().size()
						await _esperar(0.1)
						t += 0.1
						if motor.gotas_en_pantalla().size() < n:
							llegaron += 1
					_chequear(motor.fallos() == antes, "dejar pasar gotas no cuenta fallo")
				if not probe_fisica and motor.fase() == "atrapar":
					# Frasco bajo la gota mas baja: debe entrar sola por la fisica de caida.
					var capas_antes: int = motor._capas.size()
					var fallos_antes: int = motor.fallos()
					var t := 0.0
					while t < 10.0 and motor._capas.size() == capas_antes and motor.fallos() == fallos_antes and motor.fase() == "atrapar":
						var baja = null
						for g in motor.gotas_en_pantalla():
							if g["pos"].y < motor.Y_BOCA and (baja == null or g["pos"].y > baja["pos"].y):
								baja = g
						if baja != null:
							motor._mover_frasco_a(baja["pos"].x)
						await _esperar(0.05)
						t += 0.05
					probe_fisica = true
					_chequear(motor._capas.size() != capas_antes or motor.fallos() != fallos_antes or motor.fase() != "atrapar",
						"una gota que cae dentro del frasco se atrapa sola")
					await _esperar_fase(motor, ["atrapar", "agitar"], 10.0)
					continue
				if not probe_sucio and motor.fase() == "atrapar":
					probe_sucio = true
					var latas_antes: int = motor.latas().size()
					var antes: int = motor.fallos()
					var malo := "gris"
					for pigmento in ["rojo", "amarillo", "azul", "blanco"]:
						if not motor.faltantes().has(pigmento):
							malo = pigmento
							break
					var r: String = motor.atrapar_color(malo)
					_chequear(r == "sucio" and motor.fallos() == antes + 1 and motor.fase() == "sucio", "gota que no va ensucia y cuenta un fallo (%s)" % malo)
					await _esperar_fase(motor, ["atrapar"], 12.0)
					_chequear(motor._capas.is_empty() and motor.latas().size() == latas_antes, "tras el puaj el frasco queda vacio y las latas hechas se conservan")
					continue
				if not probe_libreta and zona == "zona2_charcos" and motor.fase() == "atrapar":
					probe_libreta = true
					var e_antes: int = motor.estrellitas_calculadas()
					motor.tocar_libreta()
					await _esperar(0.2)
					_chequear(motor.tarjeta_visible() and motor.revisiones() == 1, "la libreta muestra la receta y cuenta una revision")
					_chequear(motor.estrellitas_calculadas() == maxi(1, e_antes - 1), "la libreta cuesta una estrellita")
					await _esperar_fase(motor, ["atrapar"], 20.0)
					continue
				# Juego perfecto: atrapa lo que falta.
				var faltan: Dictionary = motor.faltantes()
				if not faltan.is_empty():
					var r2: String = motor.atrapar_color(str(faltan.keys()[0]))
					if r2 == "":
						await _esperar(0.1)
				await _esperar(0.05)
			"agitar":
				motor.agitar(0.55)
				await _esperar(0.1)
				if motor.fase() == "lata":
					latas_hechas += 1
			_:
				await _esperar(0.2)
	await _esperar(0.5)
	_chequear(resultado["destellos"] > 0, "completado(destellos=%d)" % resultado["destellos"])
	_chequear(murales_emitidos[0] == murales and motor.murales_hechos() == murales, "se pintaron %d murales (%d)" % [murales, murales_emitidos[0]])
	_chequear(motor._latas_total == murales * 3, "latas totales = %d (%d)" % [murales * 3, motor._latas_total])
	var estrellitas: int = motor.estrellitas_calculadas()
	_chequear(estrellitas >= 1 and estrellitas <= 3, "estrellitas en rango (%d)" % estrellitas)
	_resumen.append("%s: murales %d, latas %d, fallos %d, libreta %d, estrellitas %d, destellos %d" % [
		zona, motor.murales_hechos(), motor._latas_total, motor.fallos(), motor.revisiones(), estrellitas, resultado["destellos"]])
	motor.queue_free()
	await _esperar(0.3)
