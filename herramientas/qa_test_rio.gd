extends SceneTree

## Arnés QA del «Río de pintura» v2 (motor rio, tipo Zuma; docs/fichas/motor-rio.md §15).
##
## 1. Reglas (LogicaRio, determinista con semilla fija, sin pantalla): recorrido y puente, generador por
##    grupos (y el v1 sin `grupo`), colores de 2 + 1, retroceso espectacular, combo frente a cadena, gota
##    arcoíris, batidora (captura, rechazo, café, servir), túnel, munición ponderada y el Río de la batalla.
## 2. Simulación por hermano: un "jugador automático" (con batidora si el nivel la trae) para medir
##    victorias, tiempo, disparos por arcoíris, servidos y cafés por río. Son datos para la calibración
##    (HE-92, disenador-niveles), no una meta de diseño.
## 3. Escena: carga los niveles, dispara con un toque real (presionar y soltar), cambia la gota tocando a
##    Coco, sirve con la palanca (sin disparar), pierde ("¡Glu glu glu!" + reintento) y gana (`completado`).
##
## No fija `planeta_id`: no escribe en ningún guardado.
## Uso: godot --headless --path . --script herramientas/qa_test_rio.gd
## Con `-- --detalle` imprime también cada chequeo que pasa (por defecto solo fallas y resumen).

const MOTOR := "res://escenas/minijuegos/rio/motor_rio.tscn"
const NIVELES := {
	"maxi": "res://datos/niveles/arcoiris/zona1_claro/rio_semilla.json",
	"nicole": "res://datos/niveles/arcoiris/zona1_claro/rio_brote.json",
	"sofia": "res://datos/niveles/arcoiris/zona1_claro/rio_estrella.json",
	"sofia_z3": "res://datos/niveles/arcoiris/zona3_chupetines/rio_estrella.json",
}
const BATALLA := "res://datos/niveles/arcoiris/batalla/rio_equipo.json"
const DT := 1.0 / 60.0

var _fallos := 0
var _oks := 0
var _detalle := false
var _resumen: Array = []


func _initialize() -> void:
	_detalle = "--detalle" in OS.get_cmdline_user_args()
	print("=== QA rio v2: Río de pintura ===")
	_probar_recorrido_y_niveles()
	_probar_generador()
	_probar_terciarios()
	_probar_retroceso()
	_probar_combo_y_cadena()
	_probar_arcoiris()
	_probar_batidora()
	_probar_tunel()
	_probar_municion()
	_probar_batalla()
	_probar_varios()
	_probar_rondas()
	for hermano in NIVELES:
		_simular(hermano)
	for hermano in NIVELES:
		await _probar_escena(hermano)
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


func _seccion(nombre: String) -> void:
	if _detalle:
		print("\n## " + nombre)


## Los niveles traen `rondas: 3`; las pruebas de reglas parten de un río único (las rondas van en `_probar_rondas`).
func _nivel(ruta: String) -> Dictionary:
	var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	nivel.erase("rondas")
	return nivel


func _logica(ruta: String, semilla := 7) -> LogicaRio:
	return _logica_de(_nivel(ruta), semilla)


func _logica_de(nivel: Dictionary, semilla := 7) -> LogicaRio:
	var logica := LogicaRio.new()
	logica.configurar(nivel, RecorridoRio.desde_archivo(str(nivel["recorrido"])), semilla)
	return logica


## Arma un río a mano: colores de la cabeza a la cola, todas pegadas, la cabeza en `fraccion` del camino.
func _armar(logica: LogicaRio, colores: Array, fraccion := 0.5) -> void:
	logica.gotas.clear()
	logica.balas.clear()
	logica.pendientes.clear()
	logica.batidora.clear()
	logica.cafe_t = 0.0
	var s0 := logica.recorrido.largo * fraccion
	for i in colores.size():
		logica.gotas.append({"s": s0 - i * logica.diametro(), "color": colores[i], "id": 100 + i, "ot": 0.0, "origen": Vector2.ZERO})
	logica.entrando = false
	logica.estado = "jugando"
	logica.cadena = 0
	logica.combo = 0
	logica.puntos = 0
	logica.espera = 0.0


## Punto de impacto justo detrás de la gota `i` (sobre el recorrido): la nueva queda detrás de ella.
func _detras_de(logica: LogicaRio, i: int) -> Vector2:
	var s: float = logica.gotas[i]["s"]
	return logica.recorrido.posicion(s) - logica.recorrido.tangente(s) * logica.radio * 0.6


func _avanzar(logica: LogicaRio, segundos: float) -> void:
	var t := 0.0
	while t < segundos:
		logica.avanzar(DT)
		t += DT


# ---------------------------------------------------------------------------
# Recorrido, puente y niveles
# ---------------------------------------------------------------------------

func _probar_recorrido_y_niveles() -> void:
	_seccion("Recorrido y niveles")
	var recorrido := RecorridoRio.desde_archivo("res://datos/recorridos/arcoiris/z1_espiral.json")
	_chequear(recorrido.largo > 2000.0, "el recorrido de la zona 1 es largo (%.0f px)" % recorrido.largo)
	_chequear(recorrido.posicion(0.0).y >= 700.0, "el río nace abajo, fuera o al borde de la pantalla")
	_chequear(recorrido.fin.distance_to(recorrido.centro) < 260.0, "el remolino queda cerca de Coco, al final de la espiral")
	var dentro := true
	for p in recorrido.puntos:
		if p.y < 720 and (p.x < 0 or p.x > 1280 or p.y < 0):
			dentro = false
	_chequear(dentro, "todo el recorrido visible cabe en 1280x720")
	# Puente de la batidora (§10.1 y §13.2).
	_chequear(recorrido.tiene_puente(), "la espiral de la zona 1 trae puente_batidora")
	var frac := recorrido.s_puente / recorrido.largo
	_chequear(frac > 0.5 and frac < 0.7, "el puente queda a ~61 %% del recorrido (%.0f %%)" % (frac * 100.0))
	_chequear(frac < 0.82 - 0.1, "el puente queda lejos del peligro (82 %)")
	var b := recorrido.posicion_batidora()
	_chequear(absf(b.x - 640.0) < 30.0 and b.y > 540.0, "la batidora queda abajo del centro, en la última vuelta (%.0f, %.0f)" % [b.x, b.y])
	# Entre Coco y la batidora no pasa el río (salvo el tramo bajo el puente).
	var libre := true
	var desde := recorrido.centro
	for i in recorrido.puntos.size():
		var s := recorrido.acumulado[i]
		if absf(s - recorrido.s_puente) < recorrido.tunel_px + 52.0:
			continue
		var q := Geometry2D.get_closest_point_to_segment(recorrido.puntos[i], desde, b)
		if q.distance_to(recorrido.puntos[i]) < 52.0:
			libre = false
			break
	_chequear(libre, "ninguna parte del río a menos de 1 diámetro del segmento Coco-batidora")
	var pl := recorrido.posicion_palanca()
	_resumen.append("palanca en (%.0f, %.0f): su zona de toque llega a y=%.0f (R1: borde inferior 720)" % [pl.x, pl.y, pl.y + 48.0])
	_chequear(pl.y - 48.0 > b.y, "la palanca queda bajo la batidora")
	var sin_puente := RecorridoRio.desde_archivo("res://datos/recorridos/arcoiris/batalla_espiral.json")
	_chequear(not sin_puente.tiene_puente(), "un recorrido sin puente_batidora no tiene puente")

	for hermano in NIVELES:
		var nivel := _nivel(NIVELES[hermano])
		var logica := _logica(NIVELES[hermano])
		_chequear(logica.gotas.size() >= int(nivel["gotas"]) and logica.gotas.size() < int(nivel["gotas"]) + int(nivel["grupo"][0]), "%s: el río trae %d gotas (%d reales)" % [hermano, nivel["gotas"], logica.gotas.size()])
		var permitidos: Array = Array(nivel["colores"]) + Array(nivel.get("secundarios", [])) + LogicaRio.TERCIARIOS.keys()
		var colores_ok := true
		for g in logica.gotas:
			if not (g["color"] in permitidos):
				colores_ok = false
		_chequear(colores_ok, "%s: solo colores del nivel" % hermano)
		_chequear(logica.actual in nivel["colores"] or logica.actual == LogicaRio.ARCOIRIS, "%s: Coco carga munición del nivel" % hermano)
		_chequear(float(nivel["radio"]) * 2.0 >= 44.0, "%s: gotas de al menos 44 px" % hermano)
		_chequear(not nivel.has("mezclas"), "%s: sin 'mezclas' (obsoleto en la v2)" % hermano)
	var maxi := _logica(NIVELES["maxi"])
	_chequear(not maxi.tiene_batidora(), "Maxi: sin batidora, puente ni túnel")
	_chequear(maxi.grupo == Vector2i(3, 4), "Maxi: grupos de 3-4")
	var nicole := _logica(NIVELES["nicole"])
	_chequear(nicole.tiene_batidora() and nicole.batidora_espacios == 2 and nicole.secundarios == ["verde"], "Nicole: batidora de 2 y solo el verde")
	var z3 := _logica(NIVELES["sofia_z3"])
	_chequear(z3.batidora_espacios == 3 and int(z3.terciarios.get("cantidad", 0)) == 5, "Sofía zona 3: batidora de 3 y 5 colores de 2 + 1")
	_chequear(float(_nivel(NIVELES["maxi"])["velocidad"]) < float(_nivel(NIVELES["nicole"])["velocidad"]), "Maxi: más lento que Nicole")


# ---------------------------------------------------------------------------
# 1. Generador
# ---------------------------------------------------------------------------

func _probar_generador() -> void:
	_seccion("Generador por grupos")
	for hermano in NIVELES:
		var nivel := _nivel(NIVELES[hermano])
		var logica := _logica(NIVELES[hermano], 3)
		var g := Vector2i(int(nivel["grupo"][0]), int(nivel["grupo"][1]))
		var tamanos := {}
		var fuera := 0
		var mismo_color := 0
		var ultimo_bajo := 0
		var secundarias := 0
		var base := 0
		for r in 3000:
			logica.generar_rio()
			var grupos: Array = logica.grupos_generados
			for k in grupos.size():
				var n: int = grupos[k][1]
				tamanos[n] = int(tamanos.get(n, 0)) + 1
				if n < g.x or n > g.y:
					fuera += 1
				if k > 0 and grupos[k][0] == grupos[k - 1][0]:
					mismo_color += 1
				if grupos[k][0] in logica.secundarios:
					secundarias += n
				base += n
			if int(grupos.back()[1]) < g.x:
				ultimo_bajo += 1
		_chequear(fuera == 0, "%s: ningún grupo fuera de [%d, %d] en 3000 ríos" % [hermano, g.x, g.y])
		var todos := true
		for n in range(g.x, g.y + 1):
			if int(tamanos.get(n, 0)) == 0:
				todos = false
		_chequear(todos, "%s: aparecen todos los tamaños del rango %s" % [hermano, str(tamanos)])
		_chequear(mismo_color == 0, "%s: dos grupos seguidos nunca son del mismo color" % hermano)
		_chequear(ultimo_bajo == 0, "%s: el último grupo nunca baja del mínimo" % hermano)
		var fraccion := float(secundarias) / maxf(1.0, base)
		var p := float(nivel.get("p_secundario", 0.0))
		_chequear(absf(fraccion - p) <= 0.05, "%s: fracción de secundarios %.3f ~ p_secundario %.2f (±0,05)" % [hermano, fraccion, p])
	# Sin `grupo`: el río sale idéntico al de la v1 con la misma semilla.
	var nivel_v1 := _nivel(NIVELES["nicole"])
	nivel_v1.erase("grupo")
	nivel_v1.erase("secundarios")
	var logica := _logica_de(nivel_v1)
	var iguales := true
	for semilla in [1, 5, 99, 1234]:
		logica.rng.seed = semilla
		var nuevo := logica.generar_rio()
		if nuevo != _generar_v1_referencia(semilla, logica.total, logica.colores):
			iguales = false
	_chequear(iguales, "sin 'grupo': el río sale idéntico al generador v1 con la misma semilla")


## Copia literal del generador de la v1 (H1), para comprobar que un nivel sin `grupo` no cambia.
func _generar_v1_referencia(semilla: int, total: int, colores: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var salida: Array = []
	var previo := ""
	var repetidas := 0
	for i in total:
		var color := ""
		if previo != "" and repetidas < 2 and rng.randf() < 0.45:
			color = previo
		else:
			var opciones := colores.filter(func(c): return c != previo)
			color = opciones[rng.randi_range(0, opciones.size() - 1)]
		repetidas = repetidas + 1 if color == previo else 1
		previo = color
		salida.append(color)
	return salida


# ---------------------------------------------------------------------------
# 2. Colores de 2 + 1
# ---------------------------------------------------------------------------

func _probar_terciarios() -> void:
	_seccion("Colores de 2 + 1")
	var logica := _logica(NIVELES["sofia_z3"], 5)
	var cfg: Dictionary = logica.terciarios
	var cantidad_ok := 0
	var tipos_ok := 0
	var lejos_cabeza := true
	var separados := true
	var entre_grupos := true
	var rios := 500
	for r in rios:
		var lista := logica.generar_rio()
		var indices: Array = []
		var tipos := {}
		for i in lista.size():
			if LogicaRio.TERCIARIOS.has(lista[i]):
				indices.append(i)
				tipos[lista[i]] = true
		if indices.size() == int(cfg["cantidad"]):
			cantidad_ok += 1
		if tipos.size() == int(cfg["tipos"]):
			tipos_ok += 1
		for k in indices.size():
			var i: int = indices[k]
			if i < int(cfg["desde_gota"]):
				lejos_cabeza = false
			if k > 0 and i - int(indices[k - 1]) < int(cfg["separacion_min"]):
				separados = false
			# Entre dos grupos: tiene vecinos a los dos lados, de colores distintos (no partió un grupo).
			if i == 0 or i == lista.size() - 1 or lista[i - 1] == lista[i + 1] or LogicaRio.TERCIARIOS.has(lista[i - 1]) or LogicaRio.TERCIARIOS.has(lista[i + 1]):
				entre_grupos = false
	_chequear(cantidad_ok == rios, "2 + 1: exactamente %d por río (%d de %d ríos)" % [cfg["cantidad"], cantidad_ok, rios])
	_chequear(tipos_ok == rios, "2 + 1: de %d tipos (%d de %d ríos)" % [cfg["tipos"], tipos_ok, rios])
	_chequear(lejos_cabeza, "2 + 1: ninguno entre las primeras %d gotas" % cfg["desde_gota"])
	_chequear(separados, "2 + 1: separados por al menos %d gotas" % cfg["separacion_min"])
	_chequear(entre_grupos, "2 + 1: siempre entre dos grupos, nunca partiendo uno")


# ---------------------------------------------------------------------------
# 3. Retroceso espectacular
# ---------------------------------------------------------------------------

func _probar_retroceso() -> void:
	_seccion("Retroceso")
	var logica := _logica(NIVELES["maxi"])
	var eventos: Array = []
	logica.retroceso_atrae.connect(func(_a, _b) -> void: eventos.append("atrae"))
	logica.retroceso_choco.connect(func(_p, revienta: bool) -> void: eventos.append("choco_%s" % revienta))
	logica.reventaron.connect(func(n, _c, _col, cadena, _p, es_cadena) -> void: eventos.append("revento_%d_%d_%s" % [n, cadena, es_cadena]))
	# AA BB AA + B -> revientan 3 B; la parte de adelante vuelve, chocan las A y revientan 4 A con cadena x2.
	_armar(logica, ["rojo", "rojo", "azul", "azul", "rojo", "rojo"])
	logica.insertar(3, _detras_de(logica, 3), "azul")
	_avanzar(logica, 2.0)
	_chequear(eventos.size() >= 4 and eventos[0] == "revento_3_1_false", "AA BB AA + B: primero revientan 3 B (directo, cadena 1) %s" % str(eventos))
	var i_atrae := eventos.find("atrae")
	var i_choco := eventos.find("choco_true")
	var i_cadena := eventos.find("revento_4_2_true")
	_chequear(i_atrae >= 0 and i_choco > i_atrae, "retroceso_atrae antes del choque y retroceso_choco en el choque")
	_chequear(i_cadena > i_choco, "después chocan las A y revientan 4 con es_cadena y cadena == 2")
	_chequear(logica.puntos == 30 + 4 * 10 * 2, "puntos = gotas × 10 × cadena (%d)" % logica.puntos)
	# Un par que coincide pero suma 2: choca ("¡clac!") sin reventar.
	eventos.clear()
	_armar(logica, ["amarillo", "rojo", "rojo", "azul"])
	for k in range(2, 4):
		logica.gotas[k]["s"] -= 40.0
	_avanzar(logica, 1.5)
	_chequear(eventos.has("choco_false") and not eventos.any(func(e): return str(e).begins_with("revento")), "un par que suma 2 choca sin reventar %s" % str(eventos))
	_chequear(logica.gotas.size() == 4, "las 2 rojas quedan juntas en el río")
	# Dos grupos rojos que se juntan por retroceso revientan SIEMPRE, caiga donde caiga el hueco
	# (feedback del PO 17-Oct: a veces chocaban y quedaban pegadas sin reventar).
	var choques_ok := 0
	var choques := 0
	var hueco := 0.0
	while hueco < 40.0:
		_armar(logica, ["azul", "rojo", "rojo", "rojo", "rojo", "amarillo", "amarillo"])
		for k in range(3, 7):
			logica.gotas[k]["s"] -= hueco + 2.0 * logica.diametro()
		_avanzar(logica, 2.0)
		choques += 1
		if logica.gotas.size() == 3:
			choques_ok += 1
		hueco += 0.37
	_chequear(choques_ok == choques, "dos grupos rojos que chocan por retroceso revientan siempre (%d de %d)" % [choques_ok, choques])
	# El brillo de atracción se apaga si el par se deshace.
	_armar(logica, ["amarillo", "rojo", "rojo", "azul"])
	for k in range(2, 4):
		logica.gotas[k]["s"] -= 200.0
	logica.avanzar(DT)
	_chequear(logica.ids_atraidas().size() == 2, "las dos puntas iguales de un corte brillan")
	logica.gotas[2]["color"] = "azul"
	logica.avanzar(DT)
	_chequear(logica.ids_atraidas().is_empty(), "si el par deja de coincidir, el brillo se apaga")


# ---------------------------------------------------------------------------
# 4. Combo frente a cadena
# ---------------------------------------------------------------------------

func _probar_combo_y_cadena() -> void:
	_seccion("Combo y cadena")
	var logica := _logica(NIVELES["nicole"])
	var es_cadena: Array = []
	logica.reventaron.connect(func(_n, _c, _col, _ca, _p, e) -> void: es_cadena.append(e))
	_armar(logica, ["rojo", "rojo", "azul", "amarillo", "amarillo", "rosa"])
	logica.insertar(1, _detras_de(logica, 1), "rojo")
	logica.insertar(2, _detras_de(logica, 2), "amarillo")
	_chequear(logica.combo == 2 and logica.cadena == 1, "dos aciertos directos seguidos: combo 2 y cadena 1 (combo %d, cadena %d)" % [logica.combo, logica.cadena])
	_chequear(es_cadena == [false, false], "ningún acierto directo es cadena (nunca '¡Cadena ×2!')")
	_chequear(logica.puntos == 30 + 30 + 2 * 10, "puntos = gotas × 10 × cadena + bono de combo (%d)" % logica.puntos)
	_avanzar(logica, 0.5)
	var antes := logica.combo
	logica.disparo_a_batidora("rojo")
	logica.disparo_a_batidora("rosa")
	_chequear(logica.combo == antes, "disparar a la batidora (capturada o rebotada) no toca el combo")
	logica.balas.append({"pos": Vector2(640, 20), "vel": Vector2(0, -LogicaRio.VEL_BALA), "color": "rojo"})
	_avanzar(logica, DT * 6)
	_chequear(logica.combo == antes and logica.balas.is_empty(), "una bala que sale de la pantalla no toca el combo")
	logica.insertar(0, _detras_de(logica, 0), "rojo")
	_chequear(logica.combo == 0, "un disparo que se inserta sin reventar corta el combo")


# ---------------------------------------------------------------------------
# 5. Gota arcoíris
# ---------------------------------------------------------------------------

func _probar_arcoiris() -> void:
	_seccion("Gota arcoíris")
	var logica := _logica(NIVELES["maxi"], 11)
	var colores := ["rojo", "rojo", "rojo", "amarillo", "amarillo", "amarillo", "azul", "azul", "azul", "rosa", "rosa", "rosa"]
	for fase in ["normal", "peligro"]:
		_armar(logica, colores, 0.5 if fase == "normal" else 0.75)
		var cargas: Array = []
		var conexion := func() -> void: cargas.append(logica.disparos)
		logica.arcoiris_cargada.connect(conexion)
		for k in 8000:
			logica.espera = 0.0
			logica.disparar(Vector2(640, -100), -PI / 2.0)
			logica.balas.clear()
		logica.arcoiris_cargada.disconnect(conexion)
		var minimo := 1000000
		var suma := 0
		for k in range(1, cargas.size()):
			var entre: int = cargas[k] - cargas[k - 1]
			minimo = mini(minimo, entre)
			suma += entre
		var media := float(suma) / maxf(1.0, cargas.size() - 1)
		var p := 1.0 / logica.arcoiris_uno_cada * (logica.arcoiris_multiplicador if fase == "peligro" else 1.0)
		var esperada := (logica.arcoiris_minimo - 1) + 1.0 / p
		_chequear(minimo >= logica.arcoiris_minimo, "arcoíris (%s): nunca dos con menos de %d disparos entre ellas (mín %d)" % [fase, logica.arcoiris_minimo, minimo])
		_chequear(absf(media - esperada) <= esperada * 0.15, "arcoíris (%s): una cada %.1f disparos (esperado ≈ %.1f)" % [fase, media, esperada])
		_resumen.append("Maxi, arcoíris %s: una cada %.1f disparos (esperado ≈ %.1f)" % [fase, media, esperada])
	# Revienta un grupo de 1.
	var pegos := [0]
	logica.arcoiris_pego.connect(func(_p, _c) -> void: pegos[0] += 1)
	_armar(logica, ["amarillo", "rojo", "azul"])
	logica.insertar(1, _detras_de(logica, 1), LogicaRio.ARCOIRIS)
	_chequear(logica.gotas.size() == 2 and pegos[0] == 1 and logica.combo == 1, "la arcoíris revienta un grupo de 1 y cuenta como acierto de combo")
	# No se cambia por munición justa.
	_armar(logica, ["amarillo", "amarillo"])
	logica.actual = LogicaRio.ARCOIRIS
	logica.siguiente = LogicaRio.ARCOIRIS
	logica._ordenar_municion()
	_chequear(logica.actual == LogicaRio.ARCOIRIS and logica.siguiente == LogicaRio.ARCOIRIS, "la arcoíris no se cambia por munición justa")
	# Pasa por encima de la batidora.
	var nicole := _logica(NIVELES["nicole"])
	var rechazos := [0]
	nicole.batidora_rechazo.connect(func(_c, _m) -> void: rechazos[0] += 1)
	_armar(nicole, ["rojo", "rojo"], 0.2)
	nicole.arcoiris_uno_cada = 0
	var origen := nicole.recorrido.centro + Vector2(0, 86)
	var vel := (nicole.recorrido.posicion_batidora() - origen).normalized() * LogicaRio.VEL_BALA
	nicole.balas.append({"pos": origen, "vel": vel, "color": LogicaRio.ARCOIRIS})
	_avanzar(nicole, 0.3)
	_chequear(nicole.batidora.is_empty() and rechazos[0] == 0, "la arcoíris pasa por encima de la batidora")
	nicole.balas.append({"pos": origen, "vel": vel, "color": "rojo"})
	_avanzar(nicole, 0.3)
	_chequear(nicole.batidora == ["rojo"], "una roja por el mismo camino sí cae en la batidora")
	# No se pierde al servir ni con un rebote.
	_armar(nicole, ["verde", "verde", "rojo", "rojo", "amarillo", "azul"])
	nicole.batidora = ["amarillo", "azul"]
	nicole.actual = LogicaRio.ARCOIRIS
	nicole.siguiente = "rojo"
	nicole.servir()
	_chequear(nicole.actual == "verde" and nicole.siguiente == "verde", "servir: 2 verdes a boca y mano")
	for k in 2:
		nicole.espera = 0.0
		nicole.disparar(Vector2(640, -100), -PI / 2.0)
		nicole.balas.clear()
	_chequear(nicole.actual == LogicaRio.ARCOIRIS and nicole.siguiente == "rojo", "después de servir vuelven la arcoíris y la roja, en orden")
	nicole.batidora = ["amarillo", "azul"]
	nicole.actual = "rojo"
	nicole.siguiente = LogicaRio.ARCOIRIS
	nicole.espera = 0.0
	nicole.disparar(Vector2(640, -100), -PI / 2.0)
	nicole.balas.clear()
	nicole.disparo_a_batidora("rojo")
	_chequear(nicole.actual == "rojo" and nicole.siguiente == LogicaRio.ARCOIRIS, "un rebote devuelve la gota a la boca y la arcoíris sigue en la mano")


# ---------------------------------------------------------------------------
# 6-9. Batidora
# ---------------------------------------------------------------------------

func _probar_batidora() -> void:
	_seccion("Batidora")
	# 6. Resultado en vivo: toda la tabla de §10.3.
	var tabla := [
		[["rojo"], "rojo"], [["azul", "azul"], "azul"], [["amarillo", "amarillo", "amarillo"], "amarillo"],
		[["amarillo", "azul"], "verde"], [["azul", "amarillo"], "verde"], [["rojo", "amarillo"], "naranja"], [["rojo", "azul"], "violeta"],
		[["rojo", "rojo", "amarillo"], "rojo_naranja"], [["amarillo", "rojo", "amarillo"], "amarillo_naranja"],
		[["amarillo", "amarillo", "azul"], "amarillo_verde"], [["azul", "amarillo", "azul"], "azul_verde"],
		[["azul", "rojo", "azul"], "azul_violeta"], [["rojo", "azul", "rojo"], "rojo_violeta"],
		[["rojo", "amarillo", "azul"], "cafe"],
	]
	var tabla_ok := true
	for fila in tabla:
		if LogicaRio.mezcla_de(fila[0]) != fila[1]:
			tabla_ok = false
			print("    mezcla_de(%s) = %s (esperado %s)" % [str(fila[0]), LogicaRio.mezcla_de(fila[0]), fila[1]])
	_chequear(tabla_ok, "mezcla_de: toda la tabla de §10.3 (14 casos)")
	var z3 := _logica(NIVELES["sofia_z3"])
	var capturas: Array = []
	z3.batidora_capturo.connect(func(_c, _cont, resultado) -> void: capturas.append(resultado))
	var vivas_ok := true
	for fila in tabla:
		if fila[0].size() < 2 or fila[1] == "cafe":
			continue
		_armar(z3, ["rojo", "amarillo", "azul"])
		capturas.clear()
		for c in fila[0]:
			z3.disparo_a_batidora(c)
		if capturas.is_empty() or capturas.back() != fila[1] or z3.resultado_batidora() != fila[1]:
			vivas_ok = false
	_chequear(vivas_ok, "batidora de 3: el resultado en vivo es el correcto en cada captura")
	_armar(z3, ["rojo"])
	z3.disparo_a_batidora("rojo")
	_chequear(not z3.puede_servir(), "con un solo primario la palanca no sirve")
	z3.disparo_a_batidora("amarillo")
	_chequear(z3.puede_servir(), "batidora de 3: con 2 distintos ya se puede servir (o seguir agregando)")

	# 7. Rechazo: motivo y la gota vuelve a la boca.
	var nicole := _logica(NIVELES["nicole"])
	var motivos: Array = []
	nicole.batidora_rechazo.connect(func(_c, m) -> void: motivos.append(m))
	z3.batidora_rechazo.connect(func(_c, m) -> void: motivos.append(m))
	var casos := [
		[nicole, [], "rosa", "no_primario"], [nicole, [], "verde", "no_primario"], [z3, [], "rojo_naranja", "no_primario"],
		[nicole, ["amarillo", "azul"], "rojo", "llena"], [nicole, ["rojo"], "rojo", "repetido"],
		[z3, ["rojo", "rojo"], "rojo", "repetido"], [z3, ["rojo", "rojo", "azul"], "amarillo", "llena"],
	]
	for caso in casos:
		var l: LogicaRio = caso[0]
		_armar(l, ["rojo", "amarillo", "azul", "verde", "rosa", "rojo_naranja"])
		l.batidora = caso[1].duplicate()
		l.actual = "amarillo"
		l.siguiente = "azul"
		motivos.clear()
		var capturo := l.disparo_a_batidora(caso[2])
		_chequear(not capturo and motivos == [caso[3]] and l.actual == caso[2] and l.siguiente == "amarillo" and l.pendientes.front() == "azul",
			"rechazo de '%s' con %s: motivo '%s' y vuelve a la boca" % [caso[2], str(caso[1]), caso[3]])

	# 8. Café.
	_armar(z3, ["rojo", "amarillo", "azul"])
	var cafes := [0]
	var vacio := [0]
	z3.batidora_cafe.connect(func() -> void: cafes[0] += 1)
	z3.batidora_se_vacio.connect(func() -> void: vacio[0] += 1)
	for c in ["rojo", "amarillo", "azul"]:
		z3.disparo_a_batidora(c)
	_chequear(cafes[0] == 1 and z3.resultado_batidora() == "cafe" and not z3.puede_servir(), "rojo + amarillo + azul con 3 espacios: café, y no se sirve")
	motivos.clear()
	_avanzar(z3, 0.5)
	z3.disparo_a_batidora("rojo")
	_chequear(motivos == ["cafe"], "durante el eructo todo rebota (motivo 'cafe')")
	_avanzar(z3, 0.8)
	_chequear(z3.batidora.is_empty() and z3.cafe_t == 0.0 and vacio[0] == 1, "después de 1,2 s la batidora queda vacía")
	var nunca_cafe := true
	for a in LogicaRio.PRIMARIOS:
		for b in LogicaRio.PRIMARIOS:
			_armar(nicole, ["rojo"])
			nicole.disparo_a_batidora(a)
			nicole.disparo_a_batidora(b)
			if nicole.resultado_batidora() == "cafe":
				nunca_cafe = false
	_chequear(nunca_cafe, "con 2 espacios nunca sale café")

	# 9. Servir 2.
	_armar(nicole, ["verde", "verde", "rojo", "amarillo"])
	nicole.actual = "rojo"
	nicole.siguiente = "amarillo"
	nicole.batidora = ["rojo"]
	var vacias := [0]
	nicole.palanca_vacia.connect(func() -> void: vacias[0] += 1)
	_chequear(not nicole.servir() and vacias[0] == 1 and nicole.actual == "rojo" and nicole.siguiente == "amarillo", "sin resultado servible la palanca solo avisa y no cambia nada")
	nicole.batidora = ["amarillo", "azul"]
	var sirvio: Array = []
	nicole.batidora_sirvio.connect(func(c, n) -> void: sirvio.append([c, n]))
	_chequear(nicole.servir() and sirvio == [["verde", 2]] and nicole.batidora.is_empty(), "la palanca sirve 2 verdes y vacía la batidora")
	_chequear(nicole.actual == "verde" and nicole.siguiente == "verde" and nicole.pendientes.slice(0, 2) == ["rojo", "amarillo"], "boca y mano: verde y verde; lo de antes queda en pendientes, en orden")
	for k in 2:
		nicole.espera = 0.0
		nicole.disparar(Vector2(640, -100), -PI / 2.0)
		nicole.balas.clear()
	_chequear(nicole.actual == "rojo" and nicole.siguiente == "amarillo", "después de los 2 disparos vuelven la roja y la amarilla")
	# La servida sin destino se evapora.
	var evaporadas: Array = []
	nicole.servida_evaporada.connect(func(c) -> void: evaporadas.append(c))
	_armar(nicole, ["rojo", "rojo", "amarillo"])
	nicole.actual = "rojo"
	nicole.siguiente = "amarillo"
	nicole.batidora = ["amarillo", "azul"]
	nicole.servir()
	_chequear(evaporadas == ["verde", "verde"] and nicole.actual == "rojo" and nicole.siguiente == "amarillo", "una servida sin destino en el río se evapora y vuelve lo anterior %s" % str(evaporadas))
	evaporadas.clear()
	_armar(nicole, ["verde", "verde", "verde", "rojo"])
	nicole.batidora = ["amarillo", "azul"]
	nicole.servir()
	nicole.insertar(1, _detras_de(nicole, 1), "verde")
	_chequear(nicole.gotas.size() == 1 and evaporadas == ["verde", "verde"] and nicole.actual != "verde" and nicole.siguiente != "verde", "si un reventón limpia ese color, las servidas que quedaban se evaporan %s" % str(evaporadas))


# ---------------------------------------------------------------------------
# 10. Túnel
# ---------------------------------------------------------------------------

func _probar_tunel() -> void:
	_seccion("Túnel")
	var nicole := _logica(NIVELES["nicole"])
	nicole.arcoiris_uno_cada = 0
	var sp := nicole.recorrido.s_puente
	_armar(nicole, ["rojo", "rojo", "rojo"], 0.0)
	for i in 3:
		nicole.gotas[i]["s"] = sp + (1 - i) * nicole.diametro()
	var punto := nicole.recorrido.posicion(sp)
	_chequear(nicole.gota_en(punto, nicole.diametro()) == -1, "las gotas del túnel no se pueden golpear")
	var insertadas := [0]
	nicole.insertada.connect(func(_p, _c) -> void: insertadas[0] += 1)
	var origen := nicole.recorrido.centro + Vector2(0, 86)
	nicole.balas.append({"pos": origen, "vel": (punto - origen).normalized() * LogicaRio.VEL_BALA, "color": LogicaRio.ARCOIRIS})
	for k in 30:
		nicole._mover_balas(DT)
	_chequear(insertadas[0] == 0, "una bala que cruza el túnel no se inserta en las gotas escondidas")
	var maxi := _logica(NIVELES["maxi"])
	_armar(maxi, ["rojo"], 0.0)
	maxi.gotas[0]["s"] = sp
	_chequear(maxi.gota_en(maxi.recorrido.posicion(sp), maxi.diametro()) == 0, "sin batidora no hay túnel: la misma gota se ve y se golpea")
	# Las escondidas sí retroceden y revientan.
	var cadenas := [0]
	nicole.reventaron.connect(func(_n, _c, _col, _ca, _p, e) -> void: cadenas[0] += 1 if e else 0)
	_armar(nicole, ["amarillo", "rojo", "rojo", "rojo"], 0.0)
	nicole.gotas[0]["s"] = sp + nicole.diametro() * 0.5
	nicole.gotas[1]["s"] = sp - nicole.diametro() * 0.5
	nicole.gotas[2]["s"] = sp - nicole.diametro() * 1.5 - 30.0
	nicole.gotas[3]["s"] = sp - nicole.diametro() * 2.5 - 30.0
	_avanzar(nicole, 1.0)
	_chequear(cadenas[0] == 1 and nicole.gotas.size() == 1, "las gotas escondidas retroceden y revientan en cadena bajo el puente")


# ---------------------------------------------------------------------------
# 11. Munición ponderada
# ---------------------------------------------------------------------------

func _probar_municion() -> void:
	_seccion("Munición ponderada")
	var nicole := _logica(NIVELES["nicole"], 21)
	nicole.arcoiris_uno_cada = 0
	var rio := ["rojo", "rojo", "verde", "verde", "azul", "azul", "rojo", "rojo", "amarillo", "amarillo", "verde", "azul", "azul", "rojo", "rojo", "amarillo", "verde", "verde"]
	_armar(nicole, rio)
	var esperado := {}
	for i in rio.size():
		var peso := 3.0 if i < 12 else 1.0
		var c: String = rio[i]
		if c == "verde":
			esperado["amarillo"] = float(esperado.get("amarillo", 0.0)) + peso * 0.6
			esperado["azul"] = float(esperado.get("azul", 0.0)) + peso * 0.6
		else:
			esperado[c] = float(esperado.get(c, 0.0)) + peso
	var suma := 0.0
	for c in esperado:
		suma += esperado[c]
	var cuenta := {}
	var n := 10000
	for k in n:
		var c := nicole.municion()
		cuenta[c] = int(cuenta.get(c, 0)) + 1
	var cerca := true
	for c in esperado:
		if absf(float(cuenta.get(c, 0)) / n - esperado[c] / suma) > 0.015:
			cerca = false
	_chequear(cerca, "en 10.000 cargas cada color sale según su peso (×3 cabeza, ×0,6 ingredientes) %s" % str(cuenta))
	_chequear(not cuenta.has("rosa") and not cuenta.has("verde"), "un color que no está en el río nunca sale, y un secundario nunca es munición directa")


# ---------------------------------------------------------------------------
# Río de la batalla (modo equipo)
# ---------------------------------------------------------------------------

func _probar_batalla() -> void:
	_seccion("Río de la batalla")
	var nivel := _nivel(BATALLA)
	var logica := _logica(BATALLA)
	_chequear(logica.grupo != Vector2i.ZERO and logica.arcoiris_uno_cada > 0, "rio_equipo: con grupo %s y arcoíris cada %d (decisión del PO 17-Oct)" % [str(logica.grupo), logica.arcoiris_uno_cada])
	_chequear(not logica.tiene_batidora() and logica.terciarios.is_empty() and logica.secundarios.is_empty(), "rio_equipo: sin batidora, sin 2 + 1 ni secundarios")
	var solo_colores := true
	for g in logica.gotas:
		if not g["color"] in nivel["colores"]:
			solo_colores = false
	_chequear(solo_colores, "rio_equipo: solo los colores del nivel")
	_chequear(nivel.has("equipo") and int(nivel["equipo"]["cadena_vale_aciertos"]) == 2, "rio_equipo: conserva el bloque 'equipo' (cadena_vale_aciertos 2)")
	# cadena_vale_aciertos: dos aciertos directos seguidos NO cuentan como cadena (error de la v1).
	var vale := int(nivel["equipo"]["cadena_vale_aciertos"])
	var aciertos := [0]
	logica.reventaron.connect(func(_n, _c, _col, _ca, _p, e) -> void: aciertos[0] += LogicaRio.aciertos_por_reventon(e, vale))
	_armar(logica, ["rojo", "rojo", "azul", "amarillo", "amarillo", "rosa"])
	logica.insertar(1, _detras_de(logica, 1), "rojo")
	logica.insertar(2, _detras_de(logica, 2), "amarillo")
	_chequear(aciertos[0] == 2, "batalla: dos aciertos directos seguidos valen 2 aciertos, no una cadena (%d)" % aciertos[0])
	aciertos[0] = 0
	_armar(logica, ["rojo", "rojo", "azul", "azul", "rojo", "rojo"])
	logica.insertar(3, _detras_de(logica, 3), "azul")
	_avanzar(logica, 2.0)
	_chequear(aciertos[0] == 1 + vale, "batalla: un acierto con retroceso que revienta vale 1 + %d (%d)" % [vale, aciertos[0]])


func _probar_varios() -> void:
	_seccion("Varios")
	var logica := _logica(NIVELES["maxi"])
	# Munición justa: si un color se acaba, deja de salir.
	_armar(logica, ["azul", "azul", "rosa"])
	logica.arcoiris_uno_cada = 0
	logica.actual = "rojo"
	logica.siguiente = "rojo"
	logica.insertar(1, _detras_de(logica, 1), "azul")
	_chequear(logica.actual in logica.colores_presentes() and logica.siguiente in logica.colores_presentes(), "si un color se acaba del río, Coco deja de cargarlo")
	logica.actual = "rosa"
	logica.siguiente = "azul"
	logica.intercambiar()
	_chequear(logica.actual == "azul" and logica.siguiente == "rosa", "tocar a Coco intercambia boca y mano")
	_armar(logica, ["azul", "rosa"])
	var primero := logica.disparar(Vector2(640, 372), 0.0)
	var segundo := logica.disparar(Vector2(640, 372), 0.0)
	_chequear(primero and not segundo, "no se puede disparar dos veces en el mismo instante")
	_chequear(LogicaRio.estrellas_por_tiempo(60, 70) == 3 and LogicaRio.estrellas_por_tiempo(90, 70) == 2 and LogicaRio.estrellas_por_tiempo(200, 70) == 1, "estrellas: par=3, par x1.35=2, después 1")
	# Maxi también puede perder (PO 17-Oct): su río no se detiene antes del remolino.
	var quieto := _logica(NIVELES["maxi"])
	_avanzar(quieto, 600.0)
	_chequear(quieto.estado == "perdio", "Maxi: si nadie dispara, su río llega al remolino (no se detiene)")


# ---------------------------------------------------------------------------
# 12. Simulación por hermano
# ---------------------------------------------------------------------------

## Jugador automático: sirve si puede; apunta a la gota visible más avanzada de su color; con batidora,
## lleva a la batidora el primario que arma una mezcla que está en el río. Sin disparar, mide cuánto
## tarda el río en llegar al remolino.
func _simular(hermano: String) -> void:
	_seccion("Simulación: %s" % hermano)
	var victorias := 0
	var tiempos: Array = []
	var disparos := 0
	var arcoiris := 0
	var servidos := 0
	var cafes := 0
	var semillas := [1, 2, 3, 4, 5]
	var cargadas := [0]
	for semilla in semillas:
		var logica := _logica(NIVELES[hermano], semilla)
		logica.arcoiris_cargada.connect(func() -> void: cargadas[0] += 1)
		var centro := logica.recorrido.centro + Vector2(0, -6)
		var pasos := 0
		while logica.estado in ["jugando", "tragando"] and pasos < 60 * 400:
			if logica.estado == "jugando" and logica.espera <= 0.0 and logica.balas.is_empty() and not logica.gotas.is_empty():
				if logica.puede_servir():
					logica.servir()
				else:
					var destino := _destino(logica)
					if destino == Vector2.INF and logica.siguiente != logica.actual:
						logica.intercambiar()
						destino = _destino(logica)
					if destino == Vector2.INF:
						destino = logica.recorrido.posicion(maxf(1.0, logica.gotas[0]["s"]))
					logica.disparar(centro + (destino - centro).normalized() * 86.0, (destino - centro).angle())
			logica.avanzar(DT)
			pasos += 1
		if logica.estado == "gano":
			victorias += 1
			tiempos.append(logica.tiempo)
		disparos += logica.disparos
		arcoiris += logica.estadisticas["arcoiris"]
		servidos += logica.estadisticas["servidos"]
		cafes += logica.estadisticas["cafes"]
	var quieto := _logica(NIVELES[hermano])
	var t := 0.0
	while quieto.estado == "jugando" and t < 600.0:
		quieto.avanzar(DT)
		t += DT
	var media := 0.0
	for x in tiempos:
		media += x
	media = media / tiempos.size() if not tiempos.is_empty() else 0.0
	var linea := "%s: jugador automático gana %d/5 (%.0f s promedio); %.1f disparos por arcoíris cargada (%d de %d pegaron); %.1f servidos y %.1f cafés por río; sin disparar, el río llega al remolino a los %.0f s" % [
		hermano, victorias, media, float(disparos) / maxf(1.0, cargadas[0]), arcoiris, cargadas[0], servidos / 5.0, cafes / 5.0, t]
	_resumen.append(linea)
	_chequear(t > 40.0, "%s: el río tarda más de 40 s en llegar al remolino si nadie dispara" % hermano)
	if hermano in ["maxi", "nicole"]:
		_chequear(victorias >= 3, "%s: el río se puede ganar apuntando bien" % hermano)


## A dónde apunta el jugador automático, o Vector2.INF si no encuentra nada útil.
func _destino(logica: LogicaRio) -> Vector2:
	var c := logica.actual
	var mejor := -1
	for i in logica.gotas.size():
		var s: float = logica.gotas[i]["s"]
		if s <= 0.0 or s >= logica.recorrido.largo or logica.en_tunel(s):
			continue
		if c == LogicaRio.ARCOIRIS or logica.gotas[i]["color"] == c:
			mejor = i
			break
	if mejor >= 0:
		return logica.recorrido.posicion(logica.gotas[mejor]["s"])
	if logica.tiene_batidora() and c in LogicaRio.PRIMARIOS and logica.motivo_rechazo(c) == "":
		for g in logica.gotas:
			var receta := LogicaRio.receta(g["color"])
			if receta.is_empty() or g["s"] <= 0.0:
				continue
			var con := logica.batidora.duplicate()
			con.append(c)
			var encaja := true
			for ing in con:
				if con.count(ing) > receta.count(ing):
					encaja = false
			if encaja:
				return logica.recorrido.posicion_batidora()
	return Vector2.INF


# ---------------------------------------------------------------------------
# 13. Escena
# ---------------------------------------------------------------------------

func _clic(motor, posicion: Vector2, presionado: bool) -> void:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = presionado
	evento.position = posicion
	motor._al_input_juego(evento)


func _probar_escena(hermano: String) -> void:
	_seccion("Escena: %s" % hermano)
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
	_chequear(motor.fase() == "jugando", "%s: arranca jugando" % hermano)
	_chequear(motor.logica.gotas.size() > 0 and motor.recorrido != null, "%s: el río y el recorrido están cargados" % hermano)

	# Toque real: presionar lejos de Coco y soltar -> sale una gota.
	var objetivo := Vector2(1100, 200)
	await create_timer(0.3).timeout
	var antes: String = motor.logica.actual
	_clic(motor, objetivo, true)
	_clic(motor, objetivo, false)
	_chequear(motor.logica.balas.size() == 1 and motor.logica.balas[0]["color"] == antes, "%s: presionar y soltar dispara la gota de la boca" % hermano)

	# Tocar a Coco intercambia.
	var boca: String = motor.logica.actual
	var mano: String = motor.logica.siguiente
	_clic(motor, motor.recorrido.centro, true)
	_clic(motor, motor.recorrido.centro, false)
	_chequear(motor.logica.actual == mano and motor.logica.siguiente == boca, "%s: tocar a Coco cambia la gota de la boca con la de la mano" % hermano)

	# La palanca (Nicole y Sofía): tocarla sirve y no dispara.
	if motor.logica.tiene_batidora():
		await create_timer(0.3).timeout
		motor.logica.batidora = ["amarillo", "azul"]
		var servidas := [0]
		motor.logica.batidora_sirvio.connect(func(_c, _n) -> void: servidas[0] += 1)
		var balas_antes: int = motor.logica.balas.size()
		var palanca: Vector2 = motor.recorrido.posicion_palanca() + Vector2(30, 20)
		_clic(motor, palanca, true)
		_clic(motor, palanca, false)
		_chequear(servidas[0] == 1 and motor.logica.batidora.is_empty(), "%s: tocar la palanca (dentro de los 96 px) sirve" % hermano)
		_chequear(motor.logica.balas.size() == balas_antes, "%s: un toque en la palanca no dispara" % hermano)
		_clic(motor, palanca, true)
		_clic(motor, palanca, false)
		_chequear(servidas[0] == 1 and motor.logica.balas.size() == balas_antes, "%s: la palanca vacía solo tiembla (no sirve ni dispara)" % hermano)
	else:
		_chequear(not motor.recorrido.tiene_puente() or not motor.logica.tiene_batidora(), "%s: sin batidora no hay palanca" % hermano)

	# Perder: la cabeza llega al remolino -> traga -> "¡Glu glu glu!" con reintento.
	# Se adelanta el río entero (no solo la cabeza: si no, el retroceso la devuelve hacia su vecina).
	var adelanto: float = motor.recorrido.largo + 1.0 - motor.logica.gotas[0]["s"]
	for g in motor.logica.gotas:
		g["s"] += adelanto
	var t := 0.0
	while motor.fase() != "perdio" and t < 6.0:
		await create_timer(0.1).timeout
		t += 0.1
	_chequear(motor.fase() == "perdio", "%s: si el río llega al remolino, se lo traga (%.1f s) y aparece el cartel" % [hermano, t])
	_chequear(motor.get_node("%fin").visible, "%s: el cartel de Glu glu glu está a la vista" % hermano)
	_chequear(resultado["destellos"] == -1, "%s: perder no termina la estación ni registra nada" % hermano)
	motor.reintentar()
	_chequear(motor.fase() == "jugando" and motor.logica.gotas.size() == motor.logica.total_real, "%s: otra vez: río nuevo completo, con un toque" % hermano)

	# Ganar: se vacía el río -> "¡Río limpio!" -> celebración -> completado.
	await create_timer(0.2).timeout
	for ronda in motor.logica.rondas:
		motor.logica.gotas.clear()
		await create_timer(0.3).timeout
	t = 0.0
	while resultado["destellos"] == -1 and t < 20.0:
		await create_timer(0.2).timeout
		t += 0.2
	_chequear(resultado["destellos"] > 0, "%s: vaciar el río celebra y emite completado (%d destellos)" % [hermano, resultado["destellos"]])
	_chequear(resultado["terminadas"] == 2, "%s: se informó el fin de las 2 partidas (perdida y ganada)" % hermano)
	motor.queue_free()
	await create_timer(0.1).timeout


## Rondas y empuje (pedido del PO, 17-Oct-2026): 3 rondas por nivel, cada una más rápida, y sin esperas
## cuando el río queda sin gotas a la vista.
func _probar_rondas() -> void:
	_seccion("Rondas y empuje")
	for hermano in NIVELES:
		var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NIVELES[hermano]))
		_chequear(int(nivel.get("rondas", 1)) == 3, "%s: el nivel pide 3 rondas" % hermano)
		var logica := _logica_de(nivel)
		var rondas_vistas: Array = []
		logica.ronda_nueva.connect(func(r: int, _n: int) -> void: rondas_vistas.append(r))
		var velocidades: Array = []
		var gano := [false]
		logica.termino.connect(func(g: bool) -> void: gano[0] = g)
		for r in 3:
			_armar(logica, ["rojo", "rojo", "rojo"], 0.5)
			logica.entrando = false
			velocidades.append(logica.velocidad_actual())
			_chequear(logica.ronda == r + 1, "%s: estamos en la ronda %d" % [hermano, r + 1])
			logica.gotas.clear()
			logica.avanzar(0.05)
		_chequear(rondas_vistas == [2, 3] and gano[0] and logica.estado == "gano", "%s: vaciar 3 veces gana (rondas %s)" % [hermano, rondas_vistas])
		_chequear(velocidades[1] > velocidades[0] and velocidades[2] > velocidades[1], "%s: cada ronda es más rápida (%s)" % [hermano, velocidades])
		# Reintento: vuelve a la ronda en que se perdió, con sus puntos.
		var l2 := _logica_de(nivel)
		_armar(l2, ["rojo", "rojo", "rojo"], 0.5)
		l2.gotas.clear()
		l2.avanzar(0.05)
		_chequear(l2.ronda == 2 and l2.gotas.size() == l2.total_real, "%s: al vaciar la ronda 1 llega un río nuevo completo" % hermano)
		l2.puntos += 55
		l2.reiniciar(true)
		_chequear(l2.ronda == 2 and l2.estado == "jugando", "%s: reintentar vuelve a la ronda 2" % hermano)
		l2.reiniciar()
		_chequear(l2.ronda == 1 and l2.puntos == 0, "%s: reiniciar de cero vuelve a la ronda 1" % hermano)
		# Empuje: cabeza casi sin asomar -> rápido; con gotas a la vista, ritmo normal.
		var l3 := _logica_de(nivel)
		_armar(l3, ["rojo", "azul", "amarillo"], 0.02)
		_chequear(is_equal_approx(l3.velocidad_actual(), LogicaRio.VEL_ENTRADA), "%s: sin gotas a la vista la cola empuja rápido" % hermano)
		_armar(l3, ["rojo", "azul", "amarillo"], 0.5)
		_chequear(l3.velocidad_actual() < LogicaRio.VEL_ENTRADA, "%s: con gotas a la vista el ritmo es el normal" % hermano)
