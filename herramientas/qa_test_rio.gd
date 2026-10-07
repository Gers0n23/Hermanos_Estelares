extends SceneTree

## Arnés QA del «Río de pintura» (motor rio, tipo Zuma; docs/roadmap-rio-de-pintura.md §12).
##
## 1. Reglas (LogicaRio, determinista con semilla fija, sin pantalla): recorrido, armado del río,
##    munición justa, inserción y reventón, retroceso en cadena, mezcla de Sofía, ganar y perder.
## 2. Simulación por hermano: un "jugador automático" que apunta a la gota del mismo color, para medir
##    si el río se puede ganar y en cuánto tiempo; y cuánto tarda el río en llegar al remolino si nadie
##    dispara. Son datos para afinar la curva (roadmap §10), no una meta de diseño.
## 3. Escena: carga los 3 niveles de la zona 1, dispara con un toque real (presionar y soltar), cambia la
##    gota tocando a Coco, pierde ("¡Glu glu glu!" + reintento) y gana (celebración + `completado`).
##
## No fija `planeta_id`: no escribe en ningún guardado.
## Uso: godot --headless --path . --script herramientas/qa_test_rio.gd

const MOTOR := "res://escenas/minijuegos/rio/motor_rio.tscn"
const NIVELES := {
	"maxi": "res://datos/niveles/arcoiris/zona1_claro/rio_semilla.json",
	"nicole": "res://datos/niveles/arcoiris/zona1_claro/rio_brote.json",
	"sofia": "res://datos/niveles/arcoiris/zona1_claro/rio_estrella.json",
}
const DT := 1.0 / 60.0

var _fallos := 0
var _resumen: Array = []


func _initialize() -> void:
	print("=== QA rio: Río de pintura (zona 1) ===")
	_probar_reglas()
	for hermano in NIVELES:
		_simular(hermano)
	for hermano in NIVELES:
		await _probar_escena(hermano)
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


func _nivel(ruta: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ruta))


func _logica(ruta: String, semilla := 7) -> LogicaRio:
	var nivel := _nivel(ruta)
	var logica := LogicaRio.new()
	logica.configurar(nivel, RecorridoRio.desde_archivo(str(nivel["recorrido"])), semilla)
	return logica


## Arma un río a mano: colores de la cabeza a la cola, todas pegadas, la cabeza a mitad de camino.
func _armar(logica: LogicaRio, colores: Array) -> void:
	logica.gotas.clear()
	var s0 := logica.recorrido.largo * 0.5
	for i in colores.size():
		logica.gotas.append({"s": s0 - i * logica.diametro(), "color": colores[i], "id": 100 + i, "ot": 0.0, "origen": Vector2.ZERO})
	logica.entrando = false
	logica.estado = "jugando"
	logica.cadena = 0
	logica.puntos = 0


## Punto de impacto justo detrás de la gota `i` (sobre el recorrido): la nueva queda detrás de ella.
func _detras_de(logica: LogicaRio, i: int) -> Vector2:
	var s: float = logica.gotas[i]["s"]
	return logica.recorrido.posicion(s) - logica.recorrido.tangente(s) * logica.radio * 0.6


func _probar_reglas() -> void:
	print("\n## Reglas")
	var recorrido := RecorridoRio.desde_archivo("res://datos/recorridos/arcoiris/z1_espiral.json")
	_chequear(recorrido.largo > 2000.0, "el recorrido de la zona 1 es largo (%.0f px)" % recorrido.largo)
	_chequear(recorrido.posicion(0.0).y >= 700.0, "el río nace abajo, fuera o al borde de la pantalla")
	_chequear(recorrido.fin.distance_to(recorrido.centro) < 260.0, "el remolino queda cerca de Coco, al final de la espiral")
	var dentro := true
	for p in recorrido.puntos:
		if p.y < 720 and (p.x < 0 or p.x > 1280 or p.y < 0):
			dentro = false
	_chequear(dentro, "todo el recorrido visible cabe en 1280x720")

	for hermano in NIVELES:
		var nivel := _nivel(NIVELES[hermano])
		var logica := _logica(NIVELES[hermano])
		_chequear(logica.gotas.size() == int(nivel["gotas"]), "%s: el río trae %d gotas" % [hermano, nivel["gotas"]])
		var colores_ok := true
		for g in logica.gotas:
			if not (g["color"] in nivel["colores"]):
				colores_ok = false
		_chequear(colores_ok, "%s: solo colores del nivel" % hermano)
		var maxima_racha := 0
		var racha := 0
		for i in logica.gotas.size():
			racha = racha + 1 if i > 0 and logica.gotas[i]["color"] == logica.gotas[i - 1]["color"] else 1
			maxima_racha = maxi(maxima_racha, racha)
		_chequear(maxima_racha <= 3, "%s: nunca nacen 4 seguidas del mismo color (máx %d)" % [hermano, maxima_racha])
		if logica.mezcla:
			_chequear(logica.actual in LogicaRio.PRIMARIOS and logica.siguiente in LogicaRio.PRIMARIOS, "%s: con mezcla, Coco solo carga primarios" % hermano)
		else:
			_chequear(logica.actual in logica.colores_presentes(), "%s: la munición es un color que está en el río" % hermano)
		_chequear(float(nivel["radio"]) * 2.0 >= 44.0, "%s: gotas de al menos 44 px" % hermano)

	var maxi := _nivel(NIVELES["maxi"])
	var nicole := _nivel(NIVELES["nicole"])
	_chequear(float(maxi["velocidad"]) < float(nicole["velocidad"]), "Maxi: el mismo río que Nicole, más lento")
	for clave in ["gotas", "colores", "radio", "mezclas", "guia", "recorrido"]:
		_chequear(str(maxi[clave]) == str(nicole[clave]), "Maxi: '%s' igual que Nicole (solo cambia la velocidad)" % clave)

	# Inserción y reventón: rojo rojo [rojo] azul -> revientan 3 rojas.
	var logica := _logica(NIVELES["nicole"])
	_armar(logica, ["rojo", "rojo", "azul", "amarillo", "azul"])
	logica.insertar(1, _detras_de(logica, 1), "rojo")
	_chequear(logica.gotas.size() == 3 and logica.puntos == 30, "insertar la 3.ª roja revienta el grupo (+30)")

	# Sin match: se inserta y no revienta nada; la cadena se corta.
	_armar(logica, ["rojo", "azul", "amarillo"])
	logica.insertar(0, _detras_de(logica, 0), "rosa")
	_chequear(logica.gotas.size() == 4 and logica.cadena == 0, "una gota sin pareja se queda en el río (no se castiga)")

	# Retroceso en cadena: rojo rojo azul azul [azul] rojo verde -> revientan las azules, el tramo de
	# adelante (rojo rojo) vuelve, choca con la roja de atrás y revientan 3 rojas con cadena x2.
	_armar(logica, ["rojo", "rojo", "azul", "azul", "rojo", "amarillo", "amarillo"])
	logica.insertar(3, _detras_de(logica, 3), "azul")
	_chequear(logica.gotas.size() == 5, "las 3 azules revientan y queda un corte")
	for k in 120:
		logica.avanzar(DT)
	_chequear(logica.mayor_cadena >= 2, "el corte con extremos rojos retrocede y revienta en cadena (x%d)" % logica.mayor_cadena)
	_chequear(logica.gotas.size() == 2, "después de la cadena quedan solo las 2 amarillas")
	_chequear(logica.puntos == 30 + 30 * 2, "la cadena multiplica los puntos (%d)" % logica.puntos)

	# Mezcla (Sofía): verde verde [amarillo] azul -> amarillo + azul = verde, revientan 4 verdes.
	var sofia := _logica(NIVELES["sofia"])
	_armar(sofia, ["verde", "verde", "azul", "rojo", "naranja"])
	var mezclas := [0]
	sofia.mezclaron.connect(func(_a, _b, _r, _p) -> void: mezclas[0] += 1)
	sofia.insertar(1, _detras_de(sofia, 1), "amarillo")
	_chequear(mezclas[0] == 1, "Sofía: amarillo junto a azul se mezcla")
	_chequear(sofia.gotas.size() == 2, "Sofía: la mezcla da verde y revientan las 4 verdes")
	_chequear(LogicaRio.mezcla_de("rojo", "azul") == "violeta" and LogicaRio.mezcla_de("rojo", "amarillo") == "naranja", "recetas: rojo+azul=violeta, rojo+amarillo=naranja")
	# Con mezcla, igual primario con igual primario no mezcla.
	_armar(sofia, ["azul", "verde", "rojo"])
	sofia.insertar(0, _detras_de(sofia, 0), "azul")
	_chequear(sofia.gotas[0]["color"] == "azul" and sofia.gotas[1]["color"] == "azul", "Sofía: azul junto a azul no mezcla, se agrupa")

	# Munición justa: si un color se acaba, deja de salir.
	_armar(logica, ["azul", "azul", "rosa"])
	logica.actual = "rojo"
	logica.siguiente = "rojo"
	logica.insertar(1, _detras_de(logica, 1), "azul")
	_chequear(logica.actual in logica.colores_presentes() and logica.siguiente in logica.colores_presentes(), "si un color se acaba del río, Coco deja de cargarlo")

	# Intercambio.
	logica.actual = "rosa"
	logica.siguiente = "azul"
	logica.intercambiar()
	_chequear(logica.actual == "azul" and logica.siguiente == "rosa", "tocar a Coco intercambia boca y mano")

	# Enfriamiento entre disparos.
	_armar(logica, ["azul", "rosa"])
	logica.espera = 0.0
	var primero := logica.disparar(Vector2(640, 372), 0.0)
	var segundo := logica.disparar(Vector2(640, 372), 0.0)
	_chequear(primero and not segundo, "no se puede disparar dos veces en el mismo instante")

	# Estrellas por tiempo.
	_chequear(LogicaRio.estrellas_por_tiempo(60, 70) == 3 and LogicaRio.estrellas_por_tiempo(90, 70) == 2 and LogicaRio.estrellas_por_tiempo(200, 70) == 1, "estrellas: par=3, par x1.35=2, después 1")


## Jugador automático: apunta a la gota visible más avanzada de su color (o, con mezcla, a la vecina de
## un primario distinto que la convierta). Mide si se gana y en cuánto. Y aparte: sin disparar, cuánto
## tarda el río en llegar al remolino.
func _simular(hermano: String) -> void:
	print("\n## Simulación: %s" % hermano)
	var victorias := 0
	var tiempos: Array = []
	for semilla in [1, 2, 3, 4, 5]:
		var logica := _logica(NIVELES[hermano], semilla)
		var centro := logica.recorrido.centro + Vector2(0, -6)
		var pasos := 0
		while logica.estado in ["jugando", "tragando"] and pasos < 60 * 400:
			if logica.estado == "jugando" and logica.espera <= 0.0 and logica.balas.is_empty() and not logica.gotas.is_empty():
				var objetivo := _objetivo(logica)
				if objetivo == -1 and logica.siguiente != logica.actual:
					logica.intercambiar()
					objetivo = _objetivo(logica)
				if objetivo == -1:
					objetivo = 0
				var destino := logica.recorrido.posicion(logica.gotas[objetivo]["s"])
				logica.disparar(centro + (destino - centro).normalized() * 86.0, (destino - centro).angle())
			logica.avanzar(DT)
			pasos += 1
		if logica.estado == "gano":
			victorias += 1
			tiempos.append(logica.tiempo)
	var quieto := _logica(NIVELES[hermano])
	var t := 0.0
	while quieto.estado == "jugando" and t < 600.0:
		quieto.avanzar(DT)
		t += DT
	var media := 0.0
	for x in tiempos:
		media += x
	media = media / tiempos.size() if not tiempos.is_empty() else 0.0
	var linea := "%s: jugador automático gana %d/5 (%.0f s promedio); sin disparar, el río llega al remolino a los %.0f s" % [hermano, victorias, media, t]
	print("  " + linea)
	_resumen.append(linea)
	_chequear(t > 40.0, "%s: el río tarda más de 40 s en llegar al remolino si nadie dispara" % hermano)
	if hermano != "sofia":
		_chequear(victorias >= 3, "%s: el río se puede ganar apuntando bien" % hermano)


func _objetivo(logica: LogicaRio) -> int:
	var mejor := -1
	for i in logica.gotas.size():
		var s: float = logica.gotas[i]["s"]
		if s <= 0.0 or s >= logica.recorrido.largo:
			continue
		var c: String = logica.gotas[i]["color"]
		if c == logica.actual:
			return i
		if mejor == -1 and logica.mezcla and logica.actual in LogicaRio.COMPONENTES.get(c, []):
			mejor = i
	return mejor


func _clic(motor, posicion: Vector2, presionado: bool) -> void:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = presionado
	evento.position = posicion
	motor._al_input_juego(evento)


func _probar_escena(hermano: String) -> void:
	print("\n## Escena: %s" % hermano)
	var escena: PackedScene = load(MOTOR)
	var motor = escena.instantiate()
	motor.ruta_nivel = NIVELES[hermano]
	motor.id_perfil = hermano
	motor.segundos_auto_continuar = 0.5
	motor.fijar_semilla(11)
	var resultado := {"destellos": -1, "terminadas": 0}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	motor.partida_terminada.connect(func(_g: bool, _p: int) -> void: resultado["terminadas"] += 1)
	root.add_child(motor)
	await create_timer(0.3).timeout
	_chequear(motor.fase() == "jugando", "arranca jugando")
	_chequear(motor.logica.gotas.size() > 0 and motor.recorrido != null, "el río y el recorrido están cargados")

	# Toque real: presionar lejos de Coco y soltar -> sale una gota.
	var objetivo := Vector2(1100, 200)
	await create_timer(0.3).timeout
	var antes: String = motor.logica.actual
	_clic(motor, objetivo, true)
	_clic(motor, objetivo, false)
	_chequear(motor.logica.balas.size() == 1, "presionar y soltar dispara una gota")
	_chequear(motor.logica.balas.size() == 1 and motor.logica.balas[0]["color"] == antes, "sale la gota que Coco tenía en la boca")

	# Tocar a Coco intercambia.
	var boca: String = motor.logica.actual
	var mano: String = motor.logica.siguiente
	_clic(motor, motor.recorrido.centro, true)
	_clic(motor, motor.recorrido.centro, false)
	_chequear(motor.logica.actual == mano and motor.logica.siguiente == boca, "tocar a Coco cambia la gota de la boca con la de la mano")

	# Perder: la cabeza llega al remolino -> traga -> "¡Glu glu glu!" con reintento.
	# Se adelanta el río entero (no solo la cabeza: si no, el retroceso la devuelve hacia su vecina).
	var adelanto: float = motor.recorrido.largo + 1.0 - motor.logica.gotas[0]["s"]
	for g in motor.logica.gotas:
		g["s"] += adelanto
	var t := 0.0
	while motor.fase() != "perdio" and t < 6.0:
		await create_timer(0.1).timeout
		t += 0.1
	_chequear(motor.fase() == "perdio", "si el río llega al remolino, se lo traga en pocos segundos (%.1f s) y aparece el cartel" % t)
	_chequear(motor.get_node("%fin").visible, "el cartel de Glu glu glu está a la vista")
	_chequear(resultado["destellos"] == -1, "perder no termina la estación ni registra nada")
	motor.reintentar()
	_chequear(motor.fase() == "jugando" and motor.logica.gotas.size() == motor.logica.total, "otra vez: río nuevo completo, con un toque")

	# Ganar: se vacía el río -> "¡Río limpio!" -> celebración -> completado.
	await create_timer(0.2).timeout
	motor.logica.gotas.clear()
	t = 0.0
	while resultado["destellos"] == -1 and t < 20.0:
		await create_timer(0.2).timeout
		t += 0.2
	_chequear(resultado["destellos"] > 0, "vaciar el río celebra y emite completado (%d destellos)" % resultado["destellos"])
	_chequear(resultado["terminadas"] == 2, "se informó el fin de las 2 partidas (perdida y ganada)")
	motor.queue_free()
	await create_timer(0.1).timeout
