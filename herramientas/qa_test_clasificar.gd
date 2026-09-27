extends SceneTree

## Arnes QA de "Lluvia de colores" (motor clasificar): juega las 15 variantes (5 zonas x 3 rutas).
## Por nivel verifica: armado (charcos y gotas con tamano tactil del perfil), que existan todas las
## voces que el nivel nombra (incluidos colores, pedidos y datos curiosos), las reglas del perfil
## (Semilla nunca dice "no" ni pierde; Brote y Estrella cuentan fallos por tanda con derrota-gag y
## reintento; mezcla que tine a medias; gota gris; charcos que se mueven; gotas que se dividen;
## arcoiris del cielo; Coco que nombra el color), las pistas y el regalo de Sofia, y que al
## completar todas las tandas llegue `completado(destellos)`.
##
## Corre acelerado (Engine.time_scale) para no demorar: los tiempos del juego no cambian.
##
## Uso: godot --headless --path . --script herramientas/qa_test_clasificar.gd [-- <filtro>]

const MOTOR := "res://escenas/minijuegos/clasificar/motor_clasificar.tscn"
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const TAMANO_MINIMO := {"semilla": 96.0, "brote": 64.0, "estrella": 64.0}
const VELOCIDAD := 6.0

var _fallos := 0
var _resumen: Array = []


func _initialize() -> void:
	print("=== QA clasificar: Lluvia de colores, 5 zonas x rutas de Maxi, Nicole y Sofia ===")
	Engine.time_scale = VELOCIDAD
	var filtro := ""
	if OS.get_cmdline_user_args().size() > 0:
		filtro = OS.get_cmdline_user_args()[0]
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/lluvia_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			await _probar_nivel(ruta, perfil)
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


func _esperar_jugable(motor, maximo := 30.0) -> bool:
	var t := 0.0
	while motor.esta_esperando() and t < maximo:
		await _esperar(0.1)
		t += 0.1
	return not motor.esta_esperando()


func _probar_nivel(ruta: String, perfil: String) -> void:
	print("\n== %s (%s) ==" % [ruta.get_file(), ruta.get_base_dir().get_file()])
	var motor = load(MOTOR).instantiate()
	if not motor.has_method("soltar_gota_en"):
		_chequear(false, "el script del motor carga sin errores")
		motor.free()
		return
	motor.ruta_nivel = ruta
	motor.id_perfil = HERMANOS[perfil]
	motor.segundos_auto_continuar = 1.0
	var estado := {"destellos": -1, "rondas": 0, "fallidos": 0, "clasificadas": 0, "mezclas": 0}
	motor.completado.connect(func(d: int) -> void: estado["destellos"] = d)
	motor.ronda_completada.connect(func(_i: int) -> void: estado["rondas"] += 1)
	motor.nivel_fallado.connect(func() -> void: estado["fallidos"] += 1)
	motor.gota_clasificada.connect(func(_c: String, _ch: String) -> void: estado["clasificadas"] += 1)
	motor.mezcla_lograda.connect(func(_r: String) -> void: estado["mezclas"] += 1)
	get_root().add_child(motor)
	await _esperar(0.2)
	var nivel: Dictionary = motor.nivel
	_chequear(not nivel.is_empty(), "nivel cargado (%s)" % nivel.get("id_nivel", "?"))
	_chequear(str(nivel.get("perfil")) == perfil and str(nivel.get("motor")) == "clasificar", "perfil y motor del JSON")
	_verificar_voces(nivel)
	await _esperar_jugable(motor)
	_verificar_tamanos(motor, perfil)

	var limite = nivel.get("limite_intentos", null)
	if perfil == "semilla":
		_chequear(limite == null, "Semilla sin limite de intentos")
		await _probar_semilla(motor, nivel)
	else:
		await _probar_reglas(motor, nivel)
		if limite != null:
			await _probar_derrota(motor, int(limite))
			if ruta.contains("zona1_claro/lluvia_estrella") or ruta.contains("zona3_chupetines/lluvia_brote"):
				await _probar_derrota(motor, int(limite))
				await _esperar(1.5)
				_chequear(motor._regalo_dado, "tras 2 derrotas Coco regala un acierto")
		if perfil == "estrella":
			await _probar_pista(motor)

	var t0 := Time.get_ticks_msec()
	var completo := await _jugar_hasta_el_final(motor, estado)
	var seg := (Time.get_ticks_msec() - t0) / 1000.0 * VELOCIDAD
	_chequear(completo, "llega completado(destellos) (destellos=%d)" % estado["destellos"])
	_chequear(estado["rondas"] == int(nivel.get("rondas", 1)), "se jugaron las %d tandas (vistas %d)" % [int(nivel.get("rondas", 1)), estado["rondas"]])
	var estrellitas: int = motor._calcular_estrellitas()
	if perfil == "estrella":
		_chequear(estrellitas >= 1 and estrellitas <= 3, "estrellitas 1-3 (%d)" % estrellitas)
		if estado["fallidos"] > 0:
			_chequear(estrellitas == 1 or motor._pistas_usadas > 0, "tras derrota-gag, 1 estrellita")
	_resumen.append("%-34s tandas=%d aciertos=%d mezclas=%d derrotas=%d destellos=%d estrellitas=%d (bot: %.0f s de juego)" % [
		ruta.get_base_dir().get_file() + "/" + ruta.get_file(), estado["rondas"], estado["clasificadas"], estado["mezclas"],
		estado["fallidos"], estado["destellos"], estrellitas if perfil == "estrella" else 0, seg])
	motor.queue_free()
	await _esperar(0.3)


func _verificar_voces(nivel: Dictionary) -> void:
	var faltan: Array = []
	var voces: Dictionary = nivel.get("lineas_voz", {})
	for clave in voces:
		var valor = voces[clave]
		if str(clave).begins_with("prefijo_"):
			continue
		for ruta in (valor if valor is Array else [valor]):
			if not ResourceLoader.exists("res://assets/audio/" + str(ruta)):
				faltan.append(ruta)
	var colores: Array = []
	colores.append_array(nivel.get("colores", []))
	colores.append_array(nivel.get("pool_gotas", []))
	colores.append_array(nivel.get("pedidos", []))
	colores.append_array(nivel.get("paleta_gotas", []))
	if bool(nivel.get("arcoiris_cielo", false)):
		colores.append_array(["rojo", "naranja", "amarillo", "verde", "azul", "violeta"])
	for c in colores:
		if voces.has("prefijo_colores") and not ResourceLoader.exists("res://assets/audio/%s%s.wav" % [voces["prefijo_colores"], c]):
			faltan.append("color " + str(c))
	for c in nivel.get("pedidos", []):
		for prefijo in ["prefijo_datos", "prefijo_necesito"]:
			if voces.has(prefijo) and not ResourceLoader.exists("res://assets/audio/%s%s.wav" % [voces[prefijo], c]):
				faltan.append("%s %s" % [prefijo, c])
	for c in nivel.get("pool_gotas", []):
		if voces.has("prefijo_pedidos") and not ResourceLoader.exists("res://assets/audio/%s%s.wav" % [voces["prefijo_pedidos"], c]):
			faltan.append("pedido " + str(c))
	_chequear(faltan.is_empty(), "todas las voces existen %s" % ("" if faltan.is_empty() else str(faltan)))


func _verificar_tamanos(motor, perfil: String) -> void:
	var minimo: float = TAMANO_MINIMO[perfil]
	var chicos: Array = []
	for charco in motor.charcos_activos():
		if charco.size.x < minimo or charco.size.y < minimo:
			chicos.append("charco %s" % charco.size)
	for gota in motor.gotas_activas():
		# Zona tocable: radio de _has_point (>= 48 px siempre).
		var radio: float = maxf(gota.size.x * 0.5 + 16.0, 48.0)
		if radio * 2.0 < minimo:
			chicos.append("gota %s" % gota.size)
		if perfil == "semilla" and gota.size.x < 96.0:
			chicos.append("gota semilla %s" % gota.size)
	_chequear(chicos.is_empty(), "objetivos tactiles >= %d px %s" % [int(minimo), "" if chicos.is_empty() else str(chicos)])


## Maxi: soltar en el charco "equivocado" igual hace magia; variantes especificas por zona.
func _probar_semilla(motor, nivel: Dictionary) -> void:
	var gotas: Array = motor.gotas_activas()
	_chequear(not gotas.is_empty(), "hay gota en pantalla")
	if gotas.is_empty():
		return
	var gota = gotas[0]
	if bool(nivel.get("gotas_divisibles", false)):
		var antes: int = motor.gotas_activas().size()
		motor.tocar_gota(gota)
		await _esperar(0.6)
		_chequear(motor.gotas_activas().size() == antes + 1, "la gota gigante se divide en dos gotitas")
		for gotita in motor.gotas_activas():
			if gotita.tipo != "gigante":
				gota = gotita
	if bool(nivel.get("arcoiris_cielo", false)):
		motor.tocar_gota(gota)
		await _esperar(1.2)
		_chequear(motor._avance_bandas[0] > 0.9, "tocar la gota pinta la primera franja del arcoiris")
		return
	var otro = null
	for charco in motor.charcos_activos():
		if charco.color_id != gota.color_id:
			otro = charco
	if bool(nivel.get("charco_llama", false)):
		var llama := false
		for charco in motor.charcos_activos():
			llama = llama or (charco.llamando and charco.color_id == gota.color_id)
		_chequear(llama, "el charco del color de la gota brilla y la llama")
	var resultado: String = motor.soltar_gota_en(gota, otro)
	_chequear(resultado == "magia", "charco de otro color = magia, nunca 'no' (%s)" % resultado)
	await _esperar(0.8)
	_chequear(not motor._boton_otra_vez.visible and motor._fallos_total == 0, "sin fallos ni derrota")


## Brote/Estrella: regla de acierto y "todavia no".
func _probar_reglas(motor, nivel: Dictionary) -> void:
	await _esperar_gotas(motor)
	var gota = _gota_util(motor)
	if gota == null:
		_chequear(false, "hay una gota util en pantalla")
		return
	var correcto = motor.charco_correcto_para(gota)
	var incorrecto = null
	for charco in motor.charcos_activos():
		if charco != correcto and (not charco.es_mezcla or not charco.faltantes().has(gota.color_id)):
			incorrecto = charco
	if bool(nivel.get("nombrar_color_por_voz", false)):
		_chequear(motor._charco_objetivo != null and motor._charco_objetivo.llamando and motor._charco_objetivo.solo_contorno,
			"Coco nombra un color y su charco de contorno brilla")
		var mala = null
		for otra in motor.gotas_activas():
			if otra.color_id != motor._color_pedido:
				mala = otra
		incorrecto = motor._charco_objetivo
		var r: String = motor.soltar_gota_en(mala, incorrecto)
		_chequear(r == "no_es_este", "gota de otro color = 'todavia no' (%s)" % r)
		await _esperar(0.6)
		gota = _gota_util(motor)
		correcto = motor._charco_objetivo
	elif incorrecto != null:
		var r2: String = motor.soltar_gota_en(gota, incorrecto)
		_chequear(r2 == "no_es_este", "charco equivocado = 'todavia no' (%s)" % r2)
		await _esperar(0.6)
		gota = _gota_util(motor)
		correcto = motor.charco_correcto_para(gota)
	if gota == null or correcto == null:
		return
	var posiciones: Array = []
	for charco in motor.charcos_activos():
		posiciones.append(charco.position)
	var resultado: String = motor.soltar_gota_en(gota, correcto)
	if motor._modo == "mezcla":
		_chequear(resultado == "componente" or resultado == "mezcla", "componente correcto tine el charco (%s)" % resultado)
		if resultado == "componente":
			_chequear(correcto.recibidos.size() == 1 and not correcto.resuelto, "charco a medio tenir")
	else:
		_chequear(resultado == "acierto", "gota a su charco = acierto (%s)" % resultado)
	if bool(nivel.get("charcos_moviles", false)):
		await _esperar(1.6)
		var otras: Array = []
		for charco in motor.charcos_activos():
			otras.append(charco.position)
		_chequear(otras != posiciones, "los charcos cambiaron de lugar tras el acierto")
	if nivel.has("gota_distractora"):
		await _esperar_jugable(motor)
		var gris = motor._crear_gota("gris", "gris")
		gris.fijar_centro(Vector2(700, 200))
		var charco = motor.charcos_activos()[0]
		var r3: String = motor.soltar_gota_en(gris, charco)
		_chequear(r3 == "gris", "la gota gris en un charco no sirve (%s)" % r3)
	await _esperar(0.8)


func _probar_derrota(motor, limite: int) -> void:
	await _esperar_jugable(motor)
	var guardia := 0
	var resultado := ""
	while resultado != "derrota" and guardia < limite * 4:
		guardia += 1
		await _esperar_gotas(motor)
		if motor._en_gag:
			break
		var gota = null
		var charco = null
		for g in motor.gotas_activas():
			if g.en_vuelo:
				continue
			for c in motor.charcos_activos():
				if motor._nombrar:
					if g.color_id != motor._color_pedido:
						gota = g
						charco = motor._charco_objetivo
				elif c != motor.charco_correcto_para(g) and not c.resuelto and not (c.es_mezcla and c.faltantes().has(g.color_id)):
					gota = g
					charco = c
			if gota != null:
				break
		if gota == null:
			await _esperar(0.3)
			continue
		resultado = motor.soltar_gota_en(gota, charco)
		await _esperar(0.45)
	_chequear(motor._en_gag, "al agotar %d fallos de la tanda: derrota-gag" % limite)
	await _esperar(1.9)
	_chequear(motor._boton_otra_vez.visible, "aparece el boton gigante '¡otra vez!'")
	var logrados: int = motor._logrados_ronda
	motor._boton_otra_vez.pressed.emit()
	await _esperar(1.2)
	_chequear(not motor._en_gag and motor._fallos_ronda == 0, "reintento de un toque: fallos de la tanda en cero")
	_chequear(motor._logrados_ronda >= logrados, "lo logrado se conserva tras el reintento")
	await _esperar_gotas(motor)
	_chequear(not motor.gotas_activas().is_empty(), "vuelven las gotas tras el reintento")


func _probar_pista(motor) -> void:
	await _esperar_jugable(motor)
	var antes: int = motor._pistas_usadas
	_chequear(motor._boton_pista.visible, "boton de pista (estrella dorada) visible para Sofia")
	motor._boton_pista.pressed.emit()
	await _esperar(0.2)
	_chequear(motor._pistas_usadas == antes + 1, "la pista cuesta una estrellita")
	var visible := false
	for charco in motor.charcos_activos():
		visible = visible or charco.receta_visible_hasta > Time.get_ticks_msec() / 1000.0
	_chequear(visible, "la pista muestra la receta un momento")


func _esperar_gotas(motor, maximo := 20.0) -> void:
	var t := 0.0
	while (motor.gotas_activas().is_empty() or motor.esta_esperando()) and t < maximo and not motor._terminado:
		await _esperar(0.1)
		t += 0.1


func _gota_util(motor):
	for gota in motor.gotas_activas():
		if not gota.en_vuelo and gota.tipo != "gris" and motor.charco_correcto_para(gota) != null:
			return gota
	return null


## Juega bien hasta terminar todas las tandas (como un nino que acierta).
func _jugar_hasta_el_final(motor, estado: Dictionary) -> bool:
	var t := 0.0
	while estado["destellos"] < 0 and t < 400.0:
		if motor._terminado or motor.esta_esperando():
			await _esperar(0.2)
			t += 0.2
			continue
		var hizo := false
		for gota in motor.gotas_activas():
			if gota.en_vuelo:
				continue
			if gota.tipo == "gigante" or motor._arcoiris_cielo:
				motor.tocar_gota(gota)
				hizo = true
				break
			if motor._modo == "libre":
				var charco = motor.charco_correcto_para(gota)
				if charco == null:
					charco = motor.charcos_activos().pick_random()
				motor.soltar_gota_en(gota, charco)
				hizo = true
				break
			if gota.tipo == "gris":
				continue
			var destino = motor.charco_correcto_para(gota)
			if destino != null:
				motor.soltar_gota_en(gota, destino)
				hizo = true
				break
		await _esperar(0.35 if hizo else 0.15)
		t += 0.35 if hizo else 0.15
	return estado["destellos"] >= 0
