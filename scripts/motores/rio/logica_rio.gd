class_name LogicaRio
extends RefCounted

## Reglas del "Río de pintura" (tipo Zuma), sin dibujo ni entrada: docs/roadmap-rio-de-pintura.md §5.
## Vive aparte del motor para que el arnés QA (`herramientas/qa_test_rio.gd`) la pruebe determinista,
## con semilla fija y sin pantalla.
##
## Convención: `gotas[0]` es la CABEZA del río (la más avanzada, la más cerca del remolino) y la última
## es la COLA, la que empuja a todas. `s` es la distancia recorrida sobre `RecorridoRio`.
##
## Reglas (copiadas de Zuma, ajustadas en el mockup jugable aprobado por el PO 06-Oct-2026):
## - Entrada rápida hasta `entrada_rapida_hasta` del recorrido; después, la velocidad del nivel, que
##   sube de a poco (`subida`) durante los primeros 90 s.
## - Inserción: la gota disparada entra donde pega; con 3+ iguales contiguas, revientan.
## - Retroceso: si los extremos de un corte son del mismo color, el tramo de adelante vuelve, choca y
##   revienta en cadena (multiplicador).
## - Mezcla (Sofía): un primario que toca a otro primario DISTINTO los convierte a ambos en el secundario.
## - Munición justa: solo se cargan colores que siguen en el río (con mezcla, sus primarios).

signal reventaron(cantidad: int, centro: Vector2, color: String, cadena: int, puntos: int)
signal mezclaron(color_a: String, color_b: String, resultado: String, posicion: Vector2)
signal insertada(posicion: Vector2, color: String)
signal empezo_a_tragar()
signal termino(gano: bool)

const PRIMARIOS := ["rojo", "amarillo", "azul"]
const COMPONENTES := {"verde": ["amarillo", "azul"], "naranja": ["rojo", "amarillo"], "violeta": ["rojo", "azul"]}
const VEL_ENTRADA := 420.0
const VEL_RETROCESO := 520.0
## El remolino se traga el río en ~2 s, sea del largo que sea (perder es un gag corto, no una espera).
const VEL_TRAGAR := 900.0
const SEGUNDOS_TRAGAR := 2.0
const VEL_BALA := 1150.0
const SEGUNDOS_SUBIDA := 90.0
const PUNTOS_POR_GOTA := 10

var recorrido: RecorridoRio
var rng := RandomNumberGenerator.new()

# Configuración (del nivel)
var radio := 26.0
var total := 36
var colores: Array = ["rojo", "amarillo", "azul", "verde"]
var velocidad := 26.0
var subida := 0.35
var mezcla := false
var entrada_hasta := 0.28
var enfriamiento := 0.22

# Estado
var gotas: Array = []  ## {"s", "color", "id", "ot" (seg. de vuelo de inserción), "origen" (Vector2)}
var balas: Array = []  ## {"pos", "vel", "color"}
var actual := ""
var siguiente := ""
var puntos := 0
var cadena := 0
var tiempo := 0.0
var estado := "jugando"  ## jugando | tragando | gano | perdio
var entrando := true
var espera := 0.0
var mayor_cadena := 0
var _vel_tragar := VEL_TRAGAR
var _sig_id := 0


func diametro() -> float:
	return radio * 2.0


func configurar(nivel: Dictionary, recorrido_rio: RecorridoRio, semilla: int = -1) -> void:
	recorrido = recorrido_rio
	if semilla >= 0:
		rng.seed = semilla
	else:
		rng.randomize()
	radio = float(nivel.get("radio", radio))
	total = int(nivel.get("gotas", total))
	colores = Array(nivel.get("colores", colores))
	velocidad = float(nivel.get("velocidad", velocidad))
	subida = float(nivel.get("subida", subida))
	mezcla = bool(nivel.get("mezclas", false))
	entrada_hasta = float(nivel.get("entrada_rapida_hasta", entrada_hasta))
	reiniciar()


func reiniciar() -> void:
	gotas.clear()
	balas.clear()
	var previo := ""
	var repetidas := 0
	var d := diametro()
	for i in total:
		var color := ""
		# Grupitos de 1-3 del mismo color, como en Zuma: el río nunca es "uno de cada uno".
		if previo != "" and repetidas < 2 and rng.randf() < 0.45:
			color = previo
		else:
			var opciones := colores.filter(func(c): return c != previo)
			color = opciones[rng.randi_range(0, opciones.size() - 1)]
		repetidas = repetidas + 1 if color == previo else 1
		previo = color
		gotas.append(_nueva_gota(-i * d, color))
	puntos = 0
	cadena = 0
	mayor_cadena = 0
	tiempo = 0.0
	estado = "jugando"
	entrando = true
	espera = 0.0
	actual = municion()
	siguiente = municion()


func _nueva_gota(s: float, color: String) -> Dictionary:
	_sig_id += 1
	return {"s": s, "color": color, "id": _sig_id, "ot": 0.0, "origen": Vector2.ZERO}


# ---------------------------------------------------------------------------
# Munición
# ---------------------------------------------------------------------------

func colores_presentes() -> Array:
	var presentes := {}
	for g in gotas:
		presentes[g["color"]] = true
	return presentes.keys()


func municion() -> String:
	var opciones: Array = []
	var presentes := colores_presentes()
	if not mezcla:
		opciones = colores.filter(func(c): return c in presentes)
	else:
		var conjunto := {}
		for c in presentes:
			if c in PRIMARIOS:
				conjunto[c] = true
			else:
				for p in COMPONENTES.get(c, []):
					conjunto[p] = true
		opciones = conjunto.keys()
	if opciones.is_empty():
		opciones = PRIMARIOS if mezcla else colores
	return opciones[rng.randi_range(0, opciones.size() - 1)]


## ¿Sirve todavía este color de munición? (si no, se cambia: munición justa de Zuma).
func util(color: String) -> bool:
	for g in gotas:
		if g["color"] == color:
			return true
		if mezcla and color in COMPONENTES.get(g["color"], []):
			return true
	return false


func intercambiar() -> void:
	var t := actual
	actual = siguiente
	siguiente = t


## Dispara desde `origen` en la dirección `angulo`. Devuelve false si todavía no se puede.
func disparar(origen: Vector2, angulo: float) -> bool:
	if estado != "jugando" or espera > 0.0 or actual == "":
		return false
	balas.append({"pos": origen, "vel": Vector2.from_angle(angulo) * VEL_BALA, "color": actual})
	actual = siguiente if util(siguiente) else municion()
	siguiente = municion()
	espera = enfriamiento
	return true


func _refrescar_municion() -> void:
	if gotas.is_empty():
		return
	if not util(actual):
		actual = municion()
	if not util(siguiente):
		siguiente = municion()


# ---------------------------------------------------------------------------
# Reglas del río
# ---------------------------------------------------------------------------

func tocan(i: int) -> bool:
	return i + 1 < gotas.size() and gotas[i]["s"] - gotas[i + 1]["s"] <= diametro() + 2.0


func tramo(i: int) -> Vector2i:
	var c: String = gotas[i]["color"]
	var lo := i
	var hi := i
	while lo > 0 and tocan(lo - 1) and gotas[lo - 1]["color"] == c:
		lo -= 1
	while hi < gotas.size() - 1 and tocan(hi) and gotas[hi + 1]["color"] == c:
		hi += 1
	return Vector2i(lo, hi)


func _reventar_en(i: int, es_cadena: bool) -> int:
	var t := tramo(i)
	var n := t.y - t.x + 1
	if n < 3:
		return 0
	cadena = cadena + 1 if es_cadena else maxi(1, cadena + 1)
	mayor_cadena = maxi(mayor_cadena, cadena)
	var suma := Vector2.ZERO
	var color: String = gotas[i]["color"]
	for k in range(t.x, t.y + 1):
		suma += recorrido.posicion(gotas[k]["s"])
	for k in n:
		gotas.remove_at(t.x)
	var ganados := n * PUNTOS_POR_GOTA * cadena
	puntos += ganados
	reventaron.emit(n, suma / n, color, cadena, ganados)
	_refrescar_municion()
	return n


## Inserta la bala que pegó en la gota `j`. La gota nueva queda delante o detrás según el lado del impacto.
func insertar(j: int, posicion_bala: Vector2, color: String) -> void:
	var g: Dictionary = gotas[j]
	var p := recorrido.posicion(g["s"])
	var delante := (posicion_bala - p).dot(recorrido.tangente(g["s"])) > 0.0
	var nueva := _nueva_gota(g["s"] + diametro() if delante else g["s"], color)
	nueva["origen"] = posicion_bala
	nueva["ot"] = 0.12
	var idx := j if delante else j + 1
	gotas.insert(idx, nueva)
	insertada.emit(p, color)
	var n := _reventar_en(idx, false)
	if n == 0 and mezcla and color in PRIMARIOS:
		for k in [idx - 1, idx + 1]:
			if k < 0 or k >= gotas.size():
				continue
			var otra: Dictionary = gotas[k]
			var juntas := tocan(k) if k < idx else tocan(idx)
			if juntas and otra["color"] in PRIMARIOS and otra["color"] != color:
				var resultado := mezcla_de(color, otra["color"])
				mezclaron.emit(color, otra["color"], resultado, recorrido.posicion(nueva["s"]))
				nueva["color"] = resultado
				otra["color"] = resultado
				n = _reventar_en(idx, false)
				_refrescar_municion()
				break
	if n == 0:
		cadena = 0


static func mezcla_de(a: String, b: String) -> String:
	for secundario in COMPONENTES:
		var par: Array = COMPONENTES[secundario]
		if a in par and b in par and a != b:
			return secundario
	return a


func progreso_cabeza() -> float:
	if gotas.is_empty() or recorrido == null or recorrido.largo <= 0.0:
		return 0.0
	return clampf(gotas[0]["s"] / recorrido.largo, 0.0, 1.0)


func velocidad_actual() -> float:
	if estado == "tragando":
		return _vel_tragar
	if entrando:
		return VEL_ENTRADA
	return velocidad * (1.0 + subida * minf(1.0, tiempo / SEGUNDOS_SUBIDA))


func avanzar(dt: float) -> void:
	if espera > 0.0:
		espera -= dt
	if estado == "jugando":
		tiempo += dt
	if estado in ["jugando", "tragando"]:
		if estado == "jugando":
			_retroceder(dt)
		if not gotas.is_empty():
			var vel := velocidad_actual()
			if estado == "tragando":
				for g in gotas:
					g["s"] += vel * dt
			else:
				gotas[gotas.size() - 1]["s"] += vel * dt
			if entrando and gotas[0]["s"] > recorrido.largo * entrada_hasta:
				entrando = false
		_empujar(dt)
		for g in gotas:
			if g["ot"] > 0.0:
				g["ot"] -= dt
		if estado == "jugando":
			if gotas.is_empty():
				estado = "gano"
				termino.emit(true)
			elif gotas[0]["s"] >= recorrido.largo:
				estado = "tragando"
				var cola: float = gotas[gotas.size() - 1]["s"]
				_vel_tragar = maxf(VEL_TRAGAR, (recorrido.largo - cola) / SEGUNDOS_TRAGAR)
				empezo_a_tragar.emit()
		elif estado == "tragando":
			gotas = gotas.filter(func(g): return g["s"] < recorrido.largo)
			if gotas.is_empty():
				estado = "perdio"
				termino.emit(false)
	_mover_balas(dt)


## Si los extremos de un corte son del mismo color, el tramo de adelante vuelve hasta chocar.
func _retroceder(dt: float) -> void:
	var grupos: Array = []
	var ini := 0
	for i in gotas.size():
		if not tocan(i):
			grupos.append(Vector2i(ini, i))
			ini = i + 1
	for g in grupos.size() - 1:
		var a: Vector2i = grupos[g]
		var b0: int = grupos[g + 1].x
		if gotas[a.y]["color"] != gotas[b0]["color"]:
			continue
		for k in range(a.x, a.y + 1):
			gotas[k]["s"] -= VEL_RETROCESO * dt
		var falta: float = diametro() - (gotas[a.y]["s"] - gotas[b0]["s"])
		if falta > 0.0:
			for k in range(a.x, a.y + 1):
				gotas[k]["s"] += falta
			_reventar_en(a.y, true)
			break


## Las que se tocan se empujan hacia adelante, con suavidad (la gota insertada "abre espacio").
func _empujar(dt: float) -> void:
	var d := diametro()
	for i in range(gotas.size() - 2, -1, -1):
		var minimo: float = gotas[i + 1]["s"] + d
		if gotas[i]["s"] < minimo:
			gotas[i]["s"] = minf(minimo, gotas[i]["s"] + maxf(700.0 * dt, (minimo - gotas[i]["s"]) * 0.35))


func _mover_balas(dt: float) -> void:
	var d := diametro()
	var vivas: Array = []
	for bala in balas:
		var pasos := maxi(1, ceili(VEL_BALA * dt / (radio * 0.35)))
		var fin := false
		for k in pasos:
			bala["pos"] += bala["vel"] * dt / pasos
			var p: Vector2 = bala["pos"]
			if p.x < -40 or p.x > 1320 or p.y < -40 or p.y > 760:
				fin = true
				break
			if estado != "jugando":
				continue
			var golpe := gota_en(p, d * 0.92)
			if golpe >= 0:
				insertar(golpe, p, bala["color"])
				fin = true
				break
		if not fin:
			vivas.append(bala)
	balas = vivas


## Índice de la gota visible más cercana a `p` dentro de `distancia`, o -1.
func gota_en(p: Vector2, distancia: float) -> int:
	var mejor := -1
	var mejor_d := distancia
	for i in gotas.size():
		var s: float = gotas[i]["s"]
		if s <= -2.0 or s >= recorrido.largo:
			continue
		var dd := recorrido.posicion(s).distance_to(p)
		if dd < mejor_d:
			mejor_d = dd
			mejor = i
	return mejor


## Estrellas de un río ganado según el tiempo (como el mockup: par, par x1.35).
static func estrellas_por_tiempo(segundos: float, tiempo_par: float) -> int:
	if segundos <= tiempo_par:
		return 3
	if segundos <= tiempo_par * 1.35:
		return 2
	return 1
