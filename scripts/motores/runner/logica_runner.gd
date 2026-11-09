class_name LogicaRunner
extends RefCounted

## Reglas de la «Carrera de Toby» (motor runner, tipo el dinosaurio de Chrome; docs/fichas/motor-runner.md).
##
## Sin pantalla y determinista: con la misma semilla y los mismos pasos de tiempo, la carrera es idéntica
## (el arnés `herramientas/qa_test_runner.gd` lo usa para jugar con bots). No es contenido procedural: el
## nivel trae los obstáculos, sus tamaños y las reglas de reparto de Chrome; esto solo los reparte.
##
## Coordenadas: x de pantalla (el corredor vive fijo en x 220; los obstáculos nacen en x 1320 y viajan a la
## izquierda) y alturas SOBRE EL SUELO (0 = el sendero). El motor decide dónde dibuja el suelo.
##
## El salto NO es física (GDD §8, ficha §6.2): es una curva y(t) = H·4·(t/T)·(1 − t/T) de duración y
## altura fijas, con un impulso previo (respuesta inmediata al toque), salto en cola, imantado (Semilla),
## amable (Brote) y variable opcional (Estrella z4-z5). Los choques son cajas que se superponen.
##
## Política de derrota del PO (05-Nov-2026, HE-124; GDD §6 regla 11): todos los perfiles pueden perder.
## `corazones` (Semilla 3, Brote 2, Estrella 1) se gastan con cada choque sin burbuja; con 0 antes de la meta
## la carrera termina en "derrota". Al cruzar la meta se rellenan; en el tramo del récord quedarse sin
## corazones solo termina una carrera ya ganada.

signal salto_iniciado(ayudado: bool)
signal despego()
signal aterrizo()
signal toque_en_el_aire()
signal paso_obstaculo(id: String, limpio: bool)
signal choco(id: String, con_burbuja: bool, fatal: bool)
signal atraveso(id: String)
signal coleccionable(id: String, seguidos: int)
signal burbuja_nueva()
signal hito(n: int)
signal racha(n: int)
signal atardecer()
signal paso_mitad()
signal meta()
signal aereo_presentado()
signal ayuda_mirar()
signal fin_carrera(puntaje: int, motivo: String)

const X_CORREDOR := 220.0
const X_APARECE := 1320.0
## Margen humano mínimo (s) que debe quedar en la ventana de salto de un grupo a la velocidad de llegada.
const MARGEN_VENTANA_S := 0.1
const PESOS_GRUPO := [0.5, 0.35, 0.15]

var rng := RandomNumberGenerator.new()
var semilla := 0

# --- Parámetros (del nivel o del perfil del turno) ---
var v0 := 400.0
var vmax := 400.0
var t_a_max := 0.0
var inicio_libre := 3.0
var duracion_salto := 0.8
var altura_salto := 210.0
var impulso_s := 0.05
var imantado_s := 0.0
var imantado_max_s := 0.0
var amable_px := 0.0
var en_cola_s := 0.15
var variable: Dictionary = {}
var hueco_min_s := 1.5
var factor_max := 1.5
var grupo_max := 1
var repetidos_max := 2
## Margen humano (s) que debe sobrar en la ventana de salto de un grupo; si no, el grupo se achica.
var margen_ventana := MARGEN_VENTANA_S
var aereos: Dictionary = {}
var blandos := false
var burbuja_cfg: Dictionary = {}
var corazones_max := 1
var invulnerable_golpe_s := 1.5
var meta_s := 60.0
var tramo_s := 0.0  ## 0 = termina en la meta; < 0 = sin fin (reto dorado)
var banderita_mitad := false
var puntos_cfg := {"por_segundo": 10.0, "racha_saltos": 5, "racha": 50, "meta": 200, "final": 300, "coleccionable": 25}
var hito_cada := 100
var ayuda_idle: Array = []
var atardecer_en := 0.7
var defs_suelo: Array = []
var defs_aereas: Array = []
var caja_obstaculo := Vector2(0.7, 0.8)
var corredor_ancho := 120.0
var corredor_alto := 150.0
var corredor_caja := Vector2(0.6, 0.75)
var item_cfg: Dictionary = {}

# --- Estado de la carrera ---
var estado := "listo"  ## listo | jugando | tramo | terminado | derrota | frenando | quieto
var t := 0.0
var t_tramo := 0.0
var velocidad := 0.0
var distancia := 0.0
var puntos := 0.0
var corazones := 1
var burbuja := false
var invulnerable := 0.0
var racha_limpios := 0
var limpios_total := 0
var items_seguidos := 0
var obstaculos: Array = []  ## {id, dibujo, tipo, x, e (ancho de cada pieza), n, alto, altura, blando, estado, toco, sid}
var items: Array = []  ## {id, tipo (item|burbuja), x, altura, radio, tomado}
var x_meta := INF  ## dónde está la meta en pantalla (INF = todavía no aparece)
var meta_alcanzada := false
var ayuda_fuerte := false
var auto_salto_activo := true  ## los bots del arnés lo apagan para medir solo su juego

# Corredor
var fase_salto := "suelo"  ## suelo | impulso | aire
var y := 0.0
var t_impulso := 0.0
var dur_impulso := 0.0
var t_aire := 0.0
var altura_actual := 0.0
var en_cola := false
var mantenido := false
var t_mantenido := 0.0
var salto_ayudado := false

# Reparto
var _generando := false
var _proximo_x := X_APARECE
var _plan: Dictionary = {}
var _ultimos_ids: Array = []
var _ultimo_fue_aereo := false
var _aereo_alto_presentado := false
var _t_item := 0.0
var _proximo_item_s := 4.0
var _t_ultima_burbuja := 0.0
var _sid := 0
var _hito_n := 0
var _atardecer_dado := false
var _mitad_dada := false
var _snapshot_mitad: Dictionary = {}
var _t_sin_toque := 0.0
var _mirar_dado := false
var _auto_una_vez := false
var _auto_una_usada := false
var _registro: Array = []  ## para el arnés: {sid, id, tipo, n, x_entrada, t, v} de cada aparición
var grupos_reducidos := 0
var registrar_apariciones := false


# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------

func configurar(nivel: Dictionary, semilla_inicial: int = -1) -> void:
	semilla = semilla_inicial if semilla_inicial >= 0 else int(Time.get_ticks_usec() % 2147483647)
	aplicar_parametros(nivel)
	corazones_max = maxi(1, int(nivel.get("corazones", 1)))
	meta_s = float(nivel.get("meta_s", 60.0))
	var tramo = nivel.get("tramo_record_s", null)
	tramo_s = float(tramo) if tramo != null else 0.0
	banderita_mitad = bool(nivel.get("banderita_mitad", false))
	var p = nivel.get("puntos", {})
	if p is Dictionary:
		for clave in p:
			puntos_cfg[clave] = p[clave]
	hito_cada = maxi(1, int(nivel.get("hito_cada", 100)))
	var idle = nivel.get("ayuda_idle_s", null)
	ayuda_idle = idle if idle is Array and idle.size() >= 2 else []
	var fondo = nivel.get("fondo", {})
	atardecer_en = float(fondo.get("atardecer_en", 0.7)) if fondo is Dictionary else 0.7
	reiniciar()


## Lo que cambia entre perfiles (también lo usa el modo equipo al pasar la posta).
func aplicar_parametros(nivel: Dictionary) -> void:
	v0 = float(nivel.get("velocidad", 400.0))
	vmax = maxf(v0, float(nivel.get("velocidad_max", v0)))
	t_a_max = float(nivel.get("segundos_a_max", 0.0)) if nivel.get("segundos_a_max", null) != null else 0.0
	inicio_libre = float(nivel.get("inicio_libre_s", 3.0))
	var s: Dictionary = nivel.get("salto", {})
	duracion_salto = float(s.get("duracion_s", 0.8))
	altura_salto = float(s.get("altura", 210.0))
	impulso_s = float(s.get("impulso_s", 0.05))
	imantado_s = float(s.get("imantado_s", 0.0))
	imantado_max_s = maxf(impulso_s, float(s.get("imantado_max_s", 0.0)))
	amable_px = float(s.get("amable_px", 0.0))
	en_cola_s = float(s.get("en_cola_ms", 150.0)) / 1000.0
	variable = s.get("variable", {}) if s.get("variable", null) is Dictionary else {}
	var h: Dictionary = nivel.get("huecos", {})
	hueco_min_s = float(h.get("min_s", 1.5))
	factor_max = maxf(1.0, float(h.get("factor_max", 1.5)))
	grupo_max = clampi(int(h.get("grupo_max", 1)), 1, 3)
	repetidos_max = maxi(1, int(h.get("repetidos_max", 2)))
	margen_ventana = float(h.get("margen_ventana_s", MARGEN_VENTANA_S))
	aereos = nivel.get("aereos", {}) if nivel.get("aereos", null) is Dictionary else {}
	blandos = bool(nivel.get("obstaculos_blandos", false))
	burbuja_cfg = nivel.get("burbuja", {}) if nivel.get("burbuja", null) is Dictionary else {}
	invulnerable_golpe_s = float(nivel.get("invulnerable_golpe_s", 1.5))
	var c: Dictionary = nivel.get("corredor", {})
	corredor_alto = float(c.get("alto", 150.0))
	corredor_ancho = float(c.get("ancho", 120.0))
	var caja: Array = c.get("caja", [0.6, 0.75])
	corredor_caja = Vector2(float(caja[0]), float(caja[1]))
	var co: Array = nivel.get("caja_obstaculo", [0.7, 0.8])
	caja_obstaculo = Vector2(float(co[0]), float(co[1]))
	defs_suelo = []
	defs_aereas = []
	for d in nivel.get("obstaculos", []):
		if str(d.get("tipo", "suelo")) == "suelo":
			defs_suelo.append(d)
		else:
			defs_aereas.append(d)
	item_cfg = nivel.get("coleccionables", {}) if nivel.get("coleccionables", null) is Dictionary else {}
	_validar()


## Reglas de la ficha §11: el hueco mínimo debe dejar aterrizar y volver a saltar.
func _validar() -> void:
	if hueco_min_s < duracion_salto + 0.3 - 0.0001:
		push_warning("logica_runner: huecos.min_s (%.2f) < duracion_salto + 0,3 s; se sube" % hueco_min_s)
		hueco_min_s = duracion_salto + 0.3


## Empieza una carrera nueva (o desde la banderita de la mitad, si se pasó y el nivel la tiene).
func reiniciar(desde_mitad := false, con_burbuja := false, corazones_extra := 0) -> void:
	rng.seed = semilla
	var snap := _snapshot_mitad if desde_mitad and not _snapshot_mitad.is_empty() else {}
	t = float(snap.get("t", 0.0))
	puntos = float(snap.get("puntos", 0.0))
	if not snap.is_empty():
		# Otra secuencia de obstáculos que la del inicio, pero igual de reproducible.
		rng.seed = semilla + 7919
	t_tramo = 0.0
	velocidad = velocidad_en(t)
	distancia = 0.0
	corazones = corazones_max + maxi(0, corazones_extra)
	burbuja = con_burbuja or bool(burbuja_cfg.get("inicial", false))
	invulnerable = 0.0
	racha_limpios = 0
	items_seguidos = 0
	obstaculos.clear()
	items.clear()
	x_meta = INF
	meta_alcanzada = false
	fase_salto = "suelo"
	y = 0.0
	en_cola = false
	mantenido = false
	salto_ayudado = false
	_generando = false
	_proximo_x = X_APARECE
	_plan = {}
	_ultimos_ids.clear()
	_ultimo_fue_aereo = false
	_t_item = 0.0
	_proximo_item_s = _sortear_item_s()
	_t_ultima_burbuja = t
	_hito_n = int(puntos) / hito_cada
	_atardecer_dado = t >= atardecer_en * meta_s
	_mitad_dada = not snap.is_empty()
	if snap.is_empty():
		_snapshot_mitad = {}
	_t_sin_toque = 0.0
	_mirar_dado = false
	_auto_una_vez = false
	_auto_una_usada = false
	_inicio_libre_hasta = t + (inicio_libre if snap.is_empty() else minf(inicio_libre, 2.0))
	estado = "jugando"


var _inicio_libre_hasta := 3.0


func velocidad_en(tiempo: float) -> float:
	if t_a_max <= 0.0:
		return v0
	return v0 + (vmax - v0) * clampf(tiempo / t_a_max, 0.0, 1.0)


func corriendo() -> bool:
	return estado == "jugando" or estado == "tramo"


func progreso_meta() -> float:
	return clampf(t / maxf(0.001, meta_s), 0.0, 1.0)


func tiene_mitad() -> bool:
	return not _snapshot_mitad.is_empty()


func t_mitad() -> float:
	return meta_s * 0.5


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

## Un toque (o espacio). Devuelve true si el corredor responde (impulso, cola o guiño): siempre responde.
func tocar() -> bool:
	_t_sin_toque = 0.0
	_mirar_dado = false
	if not corriendo():
		return false
	mantenido = true
	t_mantenido = 0.0
	if fase_salto == "suelo":
		_iniciar_impulso(false)
		return true
	if fase_salto == "aire" and duracion_salto - t_aire <= en_cola_s:
		en_cola = true
		return true
	toque_en_el_aire.emit()
	return true


## Soltar el dedo (solo importa con salto variable).
func soltar() -> void:
	mantenido = false


func _iniciar_impulso(ayudado: bool) -> void:
	fase_salto = "impulso"
	t_impulso = 0.0
	dur_impulso = impulso_s
	salto_ayudado = ayudado
	en_cola = false
	if imantado_s > 0.0:
		# Salto imantado (Semilla): el impulso se estira para despegar en el instante justo.
		var objetivo := proximo_a_saltar()
		if not objetivo.is_empty():
			var t_centro := _tiempo_hasta_x(_centro_caja_x(objetivo))
			if t_centro <= imantado_s:
				dur_impulso = clampf(t_centro - duracion_salto * 0.5, impulso_s, imantado_max_s)
	salto_iniciado.emit(ayudado)


# ---------------------------------------------------------------------------
# Paso de simulación
# ---------------------------------------------------------------------------

func avanzar(dt: float) -> void:
	if estado == "frenando":
		_avanzar_frenando(dt)
		return
	if not corriendo():
		return
	t += dt
	if estado == "tramo":
		t_tramo += dt
	velocidad = velocidad_en(t)
	var dx := velocidad * dt
	distancia += dx
	_avanzar_corredor(dt)
	_mover_mundo(dx)
	_generar()
	_chequear_choques()
	if not corriendo():
		return
	_chequear_items()
	_puntuar(dt)
	_hitos_de_carrera()
	_ayudas(dt)
	invulnerable = maxf(0.0, invulnerable - dt)


func _avanzar_corredor(dt: float) -> void:
	if mantenido:
		t_mantenido += dt
	match fase_salto:
		"impulso":
			t_impulso += dt
			if t_impulso >= dur_impulso:
				fase_salto = "aire"
				t_aire = t_impulso - dur_impulso
				altura_actual = altura_salto
				despego.emit()
		"aire":
			t_aire += dt
			if not variable.is_empty() and mantenido:
				var desde := float(variable.get("desde_s", 0.12))
				var tope := float(variable.get("tope_s", 0.25))
				var k := clampf((t_mantenido - desde) / maxf(0.01, tope - desde), 0.0, 1.0)
				altura_actual = maxf(altura_actual, altura_salto * (1.0 + float(variable.get("extra", 0.35)) * k))
			if t_aire >= duracion_salto:
				fase_salto = "suelo"
				y = 0.0
				aterrizo.emit()
				if en_cola:
					en_cola = false
					_iniciar_impulso(false)
	if fase_salto == "aire":
		var k := clampf(t_aire / duracion_salto, 0.0, 1.0)
		y = altura_actual * 4.0 * k * (1.0 - k)
	else:
		y = 0.0


func _mover_mundo(dx: float) -> void:
	for o in obstaculos:
		o["x"] -= dx
	for it in items:
		it["x"] -= dx
	if x_meta != INF:
		x_meta -= dx
	obstaculos = obstaculos.filter(func(o): return o["x"] + o["e"] * o["n"] > -200.0)
	var nuevos: Array = []
	for it in items:
		if it["x"] < -120.0:
			if it["tipo"] == "item" and not it["tomado"]:
				items_seguidos = 0
			continue
		nuevos.append(it)
	items = nuevos
	if _generando:
		_proximo_x -= dx


# ---------------------------------------------------------------------------
# Reparto de obstáculos (reglas de Chrome, ficha §8.2)
# ---------------------------------------------------------------------------

func _generar() -> void:
	if not _generando:
		if t < _inicio_libre_hasta or defs_suelo.is_empty():
			return
		_generando = true
		_proximo_x = X_APARECE
		_plan = _planear(false)
	# La meta aparece a la distancia justa para cruzarla en `meta_s`.
	if not meta_alcanzada and x_meta == INF and t + (X_APARECE - X_CORREDOR) / maxf(1.0, velocidad) >= meta_s:
		x_meta = X_CORREDOR + _px_hasta(meta_s - t)
	while _proximo_x <= X_APARECE:
		var llegada := t + (_proximo_x - X_CORREDOR) / maxf(1.0, velocidad)
		if _zona_meta(llegada):
			# Alrededor de la meta no hay obstáculos: se corre el próximo un poco más adelante.
			_proximo_x += velocidad * 0.5
			if tramo_s == 0.0 and llegada > meta_s - 1.5:
				_proximo_x = INF
			continue
		_poner(_plan, _proximo_x)
		var siguiente := _planear(_plan.get("tipo", "suelo") != "suelo")
		var hueco := rng.randf_range(hueco_min_s, hueco_min_s * factor_max)
		var aereo_cerca: bool = _plan.get("tipo", "suelo") != "suelo" or siguiente.get("tipo", "suelo") != "suelo"
		if aereo_cerca:
			hueco = maxf(hueco, hueco_min_s * 1.5)
		if bool(_plan.get("presenta", false)) or bool(siguiente.get("presenta", false)):
			hueco = maxf(hueco, hueco_min_s * 2.0)
		var fin_x: float = _proximo_x + float(_plan["e"]) * int(_plan["n"])
		# Velocidad a la que llegará el hueco: así el hueco EN TIEMPO nunca baja del mínimo aunque se acelere.
		var t_llegada := t + (fin_x - X_CORREDOR) / maxf(1.0, velocidad) + hueco + 0.5
		var hueco_px := hueco * velocidad_en(t_llegada)
		if not aereo_cerca:
			_quizas_item(fin_x, hueco_px, hueco)
		_proximo_x = fin_x + hueco_px
		_plan = siguiente


func _zona_meta(llegada: float) -> bool:
	if meta_alcanzada:
		return false
	return llegada > meta_s - 1.2 and llegada < meta_s + 1.0


func _px_hasta(segundos: float) -> float:
	# Distancia que recorre el mundo en `segundos` desde ahora (integral de la velocidad lineal).
	var paso := 0.02
	var s := 0.0
	var px := 0.0
	while s < segundos:
		var d := minf(paso, segundos - s)
		px += velocidad_en(t + s + d * 0.5) * d
		s += d
	return px


## Decide el próximo elemento: un aéreo solo, o un grupo de 1 a `grupo_max` piezas iguales.
func _planear(previo_aereo: bool) -> Dictionary:
	var t_aprox := t + (X_APARECE - X_CORREDOR) / maxf(1.0, velocidad)
	if not aereos.is_empty() and not defs_aereas.is_empty() and not previo_aereo \
			and t_aprox >= float(aereos.get("desde_s", 0.0)) and rng.randf() < float(aereos.get("p", 0.2)):
		var tipos: Array = aereos.get("tipos", ["aereo_alto"])
		var candidatas := defs_aereas.filter(func(d): return str(d.get("tipo", "")) in tipos)
		if not candidatas.is_empty():
			var inicio := rng.randi() % candidatas.size()
			for k in candidatas.size():
				var d: Dictionary = candidatas[(inicio + k) % candidatas.size()]
				if _repetiria(str(d["id"])):
					continue
				var presenta := str(d.get("tipo", "")) == "aereo_alto" and not _aereo_alto_presentado
				if presenta:
					_aereo_alto_presentado = true
				return _plan_de(d, 1, presenta)
	# Suelo: sin más de `repetidos_max` iguales seguidos.
	var opciones := defs_suelo.filter(func(d): return not _repetiria(str(d["id"])))
	if opciones.is_empty():
		opciones = defs_suelo.duplicate()
	var d: Dictionary = opciones[rng.randi() % opciones.size()]
	var n := _sortear_grupo()
	var v_llegada := velocidad_en(t_aprox + hueco_min_s * factor_max + 1.0)
	while n > 1 and not es_saltable(d, n, v_llegada):
		n -= 1
		grupos_reducidos += 1
	if not es_saltable(d, n, v_llegada):
		push_warning("logica_runner: '%s' no se puede saltar a %.0f px/s con este salto" % [d["id"], v_llegada])
	return _plan_de(d, n, false)


## true si poner `id` haría más de `repetidos_max` iguales seguidos.
func _repetiria(id: String) -> bool:
	if _ultimos_ids.size() < repetidos_max:
		return false
	for i in _ultimos_ids.slice(-repetidos_max):
		if i != id:
			return false
	return true


func _plan_de(d: Dictionary, n: int, presenta: bool) -> Dictionary:
	var tam: Array = d.get("tamano", [80, 60])
	return {"id": str(d["id"]), "dibujo": str(d.get("dibujo", d["id"])), "tipo": str(d.get("tipo", "suelo")),
		"e": float(tam[0]), "alto": float(tam[1]), "altura": float(d.get("altura", 0.0)), "n": n, "presenta": presenta}


func _sortear_grupo() -> int:
	var total := 0.0
	for i in grupo_max:
		total += PESOS_GRUPO[i]
	var r := rng.randf() * total
	for i in grupo_max:
		r -= PESOS_GRUPO[i]
		if r <= 0.0:
			return i + 1
	return 1


func _poner(plan: Dictionary, x: float) -> void:
	_sid += 1
	var o := plan.duplicate()
	o["x"] = x
	o["sid"] = _sid
	o["estado"] = "pendiente"  ## pendiente | pasado
	o["toco"] = false
	o["blando"] = blandos
	o["t_aparece"] = t
	obstaculos.append(o)
	_ultimos_ids.append(o["id"])
	if _ultimos_ids.size() > 6:
		_ultimos_ids.pop_front()
	_ultimo_fue_aereo = o["tipo"] != "suelo"
	if registrar_apariciones:
		_registro.append({"sid": _sid, "id": o["id"], "tipo": o["tipo"], "n": o["n"], "x": x, "t": t,
			"v": velocidad, "e": o["e"]})
	if bool(o.get("presenta", false)):
		aereo_presentado.emit()


## ¿Se puede pasar este grupo con el salto del perfil a velocidad `v`? Ventana de vuelo por encima de la
## caja (curva exacta) frente al tiempo que la caja del corredor se superpone en x con la del grupo.
func es_saltable(d: Dictionary, n: int, v: float) -> bool:
	var tam: Array = d.get("tamano", [80, 60])
	var plan := _plan_de(d, n, false)
	if plan["tipo"] == "aereo_alto":
		return true
	var arriba := caja_y(plan).y
	if arriba >= altura_salto:
		return false
	var ventana := duracion_salto * sqrt(1.0 - arriba / altura_salto)
	var ancho_caja := caja_x_ancho(float(tam[0]), n)
	var cruce := (ancho_caja + corredor_ancho * corredor_caja.x) / maxf(1.0, v)
	return ventana - cruce >= (MARGEN_VENTANA_S if n == 1 else margen_ventana)


# --- Cajas ---

func caja_x_ancho(e: float, n: int) -> float:
	return e * n - e * (1.0 - caja_obstaculo.x)


## [izquierda, derecha] de la caja del obstáculo en x.
func caja_x(o: Dictionary) -> Vector2:
	var margen: float = o["e"] * (1.0 - caja_obstaculo.x) * 0.5
	return Vector2(o["x"] + margen, o["x"] + o["e"] * o["n"] - margen)


## [abajo, arriba] de la caja del obstáculo (alturas sobre el suelo). Suelo: centrada abajo; aéreos: al medio.
func caja_y(o: Dictionary) -> Vector2:
	var alto: float = o["alto"]
	if o["tipo"] == "suelo":
		return Vector2(0.0, alto * caja_obstaculo.y)
	var margen := alto * (1.0 - caja_obstaculo.y) * 0.5
	return Vector2(o["altura"] + margen, o["altura"] + alto - margen)


func caja_corredor_x() -> Vector2:
	var m := corredor_ancho * corredor_caja.x * 0.5
	return Vector2(X_CORREDOR - m, X_CORREDOR + m)


func caja_corredor_y() -> Vector2:
	return Vector2(y, y + corredor_alto * corredor_caja.y)


func _centro_caja_x(o: Dictionary) -> float:
	var c := caja_x(o)
	return (c.x + c.y) * 0.5


func _tiempo_hasta_x(x: float) -> float:
	return (x - X_CORREDOR) / maxf(1.0, velocidad)


## El próximo obstáculo que hay que saltar (suelo o aéreo bajo) que todavía no pasó. {} si no hay.
func proximo_a_saltar() -> Dictionary:
	var mejor: Dictionary = {}
	var cx := caja_corredor_x()
	for o in obstaculos:
		if o["estado"] != "pendiente" or o["tipo"] == "aereo_alto":
			continue
		if caja_x(o).y < cx.x:
			continue
		if mejor.is_empty() or o["x"] < mejor["x"]:
			mejor = o
	return mejor


## Segundos hasta el toque ideal (el que pone la cima del salto sobre el centro del obstáculo). INF si no hay.
func segundos_a_toque_ideal() -> float:
	var o := proximo_a_saltar()
	if o.is_empty():
		return INF
	return _tiempo_hasta_x(_centro_caja_x(o)) - duracion_salto * 0.5 - impulso_s


# ---------------------------------------------------------------------------
# Choques, pasos y coleccionables
# ---------------------------------------------------------------------------

func _chequear_choques() -> void:
	var cx := caja_corredor_x()
	var cy := caja_corredor_y()
	for o in obstaculos:
		if o["estado"] != "pendiente":
			continue
		var ox := caja_x(o)
		if ox.y < cx.x:
			o["estado"] = "pasado"
			var limpio: bool = not o["toco"]
			if limpio:
				racha_limpios += 1
				limpios_total += 1
				if racha_limpios % maxi(1, int(puntos_cfg.get("racha_saltos", 5))) == 0:
					puntos += float(puntos_cfg.get("racha", 50))
					racha.emit(racha_limpios)
			paso_obstaculo.emit(o["id"], limpio)
			continue
		if o["toco"] or ox.x > cx.y:
			continue
		var oy := caja_y(o)
		var solape := minf(cy.y, oy.y) - maxf(cy.x, oy.x)
		if solape <= 0.0:
			continue
		# Salto amable (Brote): un roce de pocos píxeles en el aire se perdona y pasa.
		if amable_px > 0.0 and fase_salto == "aire" and o["tipo"] != "aereo_alto" and solape <= amable_px:
			continue
		if invulnerable > 0.0:
			o["toco"] = true
			continue
		_chocar(o)
		if not corriendo():
			return


func _chocar(o: Dictionary) -> void:
	o["toco"] = true
	racha_limpios = 0
	if o["blando"]:
		atraveso.emit(o["id"])
		return
	if burbuja:
		burbuja = false
		invulnerable = float(burbuja_cfg.get("invulnerable_s", 1.0))
		_t_ultima_burbuja = t
		choco.emit(o["id"], true, false)
		return
	corazones -= 1
	if corazones > 0:
		invulnerable = invulnerable_golpe_s
		choco.emit(o["id"], false, false)
		return
	if estado == "tramo":
		estado = "terminado"
		choco.emit(o["id"], false, true)
		fin_carrera.emit(int(puntos), "choque_tramo")
		return
	estado = "derrota"
	choco.emit(o["id"], false, true)
	fin_carrera.emit(int(puntos), "derrota")


func _chequear_items() -> void:
	var cx := caja_corredor_x()
	var cy := caja_corredor_y()
	for it in items:
		if it["tomado"]:
			continue
		var r: float = it["radio"] * 1.5
		var px := clampf(it["x"], cx.x, cx.y)
		var py := clampf(it["altura"], cy.x, cy.y)
		if Vector2(px - it["x"], py - it["altura"]).length() <= r:
			it["tomado"] = true
			if it["tipo"] == "burbuja":
				burbuja = true
				_t_ultima_burbuja = t
				burbuja_nueva.emit()
			else:
				items_seguidos += 1
				puntos += float(item_cfg.get("puntos", puntos_cfg.get("coleccionable", 25)))
				coleccionable.emit(it["id"], items_seguidos)


func _sortear_item_s() -> float:
	var cada = item_cfg.get("cada_s", [3, 6])
	if cada is Array and cada.size() >= 2:
		return rng.randf_range(float(cada[0]), float(cada[1]))
	return 4.0


## Un coleccionable (o una burbuja nueva) flota en medio de un hueco amplio, a la altura de un salto: nunca
## sobre un obstáculo y siempre con tiempo de aterrizar antes del siguiente.
func _quizas_item(fin_x: float, hueco_px: float, hueco_s: float) -> void:
	if hueco_s < duracion_salto + impulso_s + 0.5:
		return
	var t_en := t + (fin_x + hueco_px * 0.5 - X_CORREDOR) / maxf(1.0, velocidad)
	if not meta_alcanzada and absf(t_en - meta_s) < 2.0:
		return
	var quiere_burbuja := not burbuja_cfg.is_empty() and burbuja_cfg.get("cada_s", null) != null and not burbuja \
		and items.filter(func(i): return i["tipo"] == "burbuja" and not i["tomado"]).is_empty() \
		and t - _t_ultima_burbuja >= float(burbuja_cfg.get("cada_s", 30))
	var quiere_item := not item_cfg.is_empty() and t - _t_item >= _proximo_item_s
	if not quiere_burbuja and not quiere_item:
		return
	var radio := float(item_cfg.get("radio", 22.0))
	var alto_c := corredor_alto * corredor_caja.y
	var altura := altura_salto * 0.9 + alto_c * 0.5
	var tipo := "burbuja" if quiere_burbuja else "item"
	if tipo == "burbuja":
		radio = 30.0
		_t_ultima_burbuja = t
	else:
		_t_item = t
		_proximo_item_s = _sortear_item_s()
	var ids: Array = item_cfg.get("ids", [item_cfg.get("id", "item")])
	var id := "burbuja" if tipo == "burbuja" else str(ids[rng.randi() % ids.size()])
	_sid += 1
	items.append({"sid": _sid, "id": id, "tipo": tipo, "x": fin_x + hueco_px * 0.5, "altura": altura, "radio": radio, "tomado": false})


# ---------------------------------------------------------------------------
# Puntaje, hitos y meta
# ---------------------------------------------------------------------------

func _puntuar(dt: float) -> void:
	puntos += float(puntos_cfg.get("por_segundo", 10.0)) * (velocidad / maxf(1.0, v0)) * dt
	var n := int(puntos) / hito_cada
	if n > _hito_n:
		_hito_n = n
		hito.emit(n)


func _hitos_de_carrera() -> void:
	if not _atardecer_dado and t >= atardecer_en * meta_s:
		_atardecer_dado = true
		atardecer.emit()
	if banderita_mitad and not _mitad_dada and t >= meta_s * 0.5:
		_mitad_dada = true
		_snapshot_mitad = {"t": t, "puntos": puntos}
		paso_mitad.emit()
	if not meta_alcanzada and t >= meta_s:
		meta_alcanzada = true
		puntos += float(puntos_cfg.get("meta", 200))
		corazones = maxi(corazones, corazones_max)
		# El estado cambia ANTES de avisar: quien escucha `meta` ya sabe si sigue el tramo del récord.
		estado = "terminado" if tramo_s == 0.0 else "tramo"
		t_tramo = 0.0
		meta.emit()
		if estado == "terminado":
			fin_carrera.emit(int(puntos), "meta")
			return
	if estado == "tramo" and tramo_s > 0.0 and t_tramo >= tramo_s:
		puntos += float(puntos_cfg.get("final", 300))
		estado = "terminado"
		fin_carrera.emit(int(puntos), "final")


## Ayudas de Semilla (HE-124): a los 5 s sin tocar el dino mira (señal); a los 12 s salta solo UNA vez por
## carrera (para mostrar que se puede). `ayuda_fuerte` (lo pone el motor si el nivel lo pide) además hace
## saltar solo al corredor cada vez que hace falta; la ayuda fuerte de Semilla del nivel usa en cambio
## `blandos` (todo se atraviesa sin gastar corazones): con cualquiera de las dos, la meta está asegurada.
func _ayudas(dt: float) -> void:
	_t_sin_toque += dt
	if not ayuda_idle.is_empty():
		if not _mirar_dado and _t_sin_toque >= float(ayuda_idle[0]):
			_mirar_dado = true
			ayuda_mirar.emit()
		if not _auto_una_usada and _t_sin_toque >= float(ayuda_idle[1]):
			_auto_una_vez = true
	if not auto_salto_activo or fase_salto != "suelo":
		return
	if ayuda_fuerte or _auto_una_vez:
		if segundos_a_toque_ideal() <= dt * 0.5:
			if _auto_una_vez:
				_auto_una_vez = false
				_auto_una_usada = true
			_iniciar_impulso(true)


# ---------------------------------------------------------------------------
# Modo equipo: frenar para pasar la posta
# ---------------------------------------------------------------------------

## El turno llegó al tope: los obstáculos que faltan se van con un "puf" y el corredor frena hasta quedar quieto.
func frenar() -> void:
	if estado == "quieto":
		return
	estado = "frenando"
	obstaculos = obstaculos.filter(func(o): return o["estado"] == "pasado")
	items.clear()


func _avanzar_frenando(dt: float) -> void:
	velocidad = maxf(0.0, velocidad - maxf(v0, 300.0) * dt / 0.8)
	var dx := velocidad * dt
	_mover_mundo(dx)
	_avanzar_corredor(dt)
	en_cola = false
	if velocidad <= 0.0 and fase_salto == "suelo":
		estado = "quieto"


## Posta (equipo): mismo mundo, perfil nuevo; sin obstáculos a la vista y con un respiro para arrancar.
func preparar_tramo(params: Dictionary, segundos_libres := 1.5) -> void:
	aplicar_parametros(params)
	corazones_max = 1
	corazones = 1
	burbuja = false
	invulnerable = 0.0
	obstaculos.clear()
	items.clear()
	fase_salto = "suelo"
	y = 0.0
	en_cola = false
	mantenido = false
	t = 0.0
	velocidad = velocidad_en(0.0)
	_generando = false
	_plan = {}
	_ultimos_ids.clear()
	_inicio_libre_hasta = segundos_libres
	meta_s = INF
	meta_alcanzada = true
	x_meta = INF
	tramo_s = 0.0
	ayuda_idle = []
	estado = "jugando"


func apariciones() -> Array:
	return _registro
