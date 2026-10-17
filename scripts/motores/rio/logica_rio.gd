class_name LogicaRio
extends RefCounted

## Reglas del "Río de pintura" (tipo Zuma), sin dibujo ni entrada: docs/fichas/motor-rio.md (v2).
## Vive aparte del motor para que el arnés QA (`herramientas/qa_test_rio.gd`) la pruebe determinista,
## con semilla fija y sin pantalla.
##
## Convención: `gotas[0]` es la CABEZA del río (la más avanzada, la más cerca del remolino) y la última
## es la COLA, la que empuja a todas. `s` es la distancia recorrida sobre `RecorridoRio`.
##
## Reglas (ficha v2, decisiones del PO del 17-Oct-2026):
## - Generador por grupos `grupo: [min, max]` (§5.1). Sin `grupo`, el generador v1 tal cual.
## - Colores de 2 + 1 sueltos entre dos grupos (§5.3), solo en las etapas difíciles de Sofía.
## - Entrada rápida, inserción y reventón de 3+ (§5.2). Ya NO hay mezcla dentro del río.
## - Retroceso espectacular (§6): las puntas iguales se atraen (rampa de 0,1 s), chocan ("¡clac!") y,
##   si suman 3+, revientan en cadena. El choque usa el mismo margen que `tocan()` (`_chocar()`), y los
##   cortes atraídos se recuerdan entre pasos (`_atraidas`) para que revienten aunque los cierre la cola.
## - Combo (disparos seguidos que revientan) y cadena (retrocesos de un mismo disparo) separados (§7).
## - Munición ponderada por urgencia, munición justa y cola boca → mano → pendientes (§8).
## - Gota arcoíris (§9) y batidora sobre el puente con palanca, túnel y café (§10).

signal reventaron(cantidad: int, centro: Vector2, color: String, cadena: int, puntos: int, es_cadena: bool)
signal insertada(posicion: Vector2, color: String)
signal combo_cambio(combo: int)
signal retroceso_atrae(id_a: int, id_b: int)
signal retroceso_choco(posicion: Vector2, revienta: bool)
signal batidora_capturo(color: String, contenido: Array, resultado: String)
signal batidora_rechazo(color: String, motivo: String)
signal batidora_cafe()
signal batidora_se_vacio()
signal batidora_sirvio(color: String, cantidad: int)
signal palanca_vacia()
signal arcoiris_cargada()
signal arcoiris_pego(posicion: Vector2, color: String)
signal servida_evaporada(color: String)
signal empezo_a_tragar()
signal termino(gano: bool)
signal ronda_nueva(ronda: int, rondas: int)

const PRIMARIOS := ["rojo", "amarillo", "azul"]
const ARCOIRIS := "arcoiris"
const CAFE := "cafe"
## Recetas (§10.3 y §5.3). Los 2 + 1 usan ids PROVISIONALES: sus nombres para los niños los pone
## `guionista` (HE-94, pendiente de la decisión "naranja/naranjo" del PO).
const SECUNDARIOS := {"verde": ["amarillo", "azul"], "naranja": ["rojo", "amarillo"], "violeta": ["rojo", "azul"]}
const TERCIARIOS := {
	"rojo_naranja": ["rojo", "rojo", "amarillo"], "amarillo_naranja": ["amarillo", "amarillo", "rojo"],
	"amarillo_verde": ["amarillo", "amarillo", "azul"], "azul_verde": ["azul", "azul", "amarillo"],
	"azul_violeta": ["azul", "azul", "rojo"], "rojo_violeta": ["rojo", "rojo", "azul"],
}
const VEL_ENTRADA := 420.0
const VEL_RETROCESO := 420.0
const RAMPA_RETROCESO := 0.1
## El remolino se traga el río en ~2 s, sea del largo que sea (perder es un gag corto, no una espera).
const VEL_TRAGAR := 900.0
const SEGUNDOS_TRAGAR := 2.0
const VEL_BALA := 1150.0
const SEGUNDOS_SUBIDA := 90.0
## Si el río queda casi sin gotas a la vista (cabeza antes de este `s`), la cola las empuja rápido
## hasta aquí: nadie espera a que lleguen las gotas de atrás (pedido del PO, 17-Oct-2026).
const EMPUJE_HASTA := 300.0
## Cuánto sube la velocidad en cada ronda siguiente (0,15 = +15 % por ronda).
const SUBIDA_POR_RONDA := 0.15
const PUNTOS_POR_GOTA := 10
const RADIO_BATIDORA := 56.0
const SEGUNDOS_CAFE := 1.2
const SEGUNDOS_REBOTE := 0.32
const SEGUNDOS_SERVIR := 0.38

var recorrido: RecorridoRio
var rng := RandomNumberGenerator.new()

# Configuración (del nivel)
var radio := 26.0
var total := 36  ## gotas pedidas por el nivel
var total_real := 36  ## gotas con las que nació el río (el último grupo nunca se corta bajo `grupo.min`)
var colores: Array = ["rojo", "amarillo", "azul", "verde"]
var velocidad := 26.0
var subida := 0.35
var entrada_hasta := 0.28
var enfriamiento := 0.22
var grupo := Vector2i.ZERO  ## (0, 0) = sin `grupo`: generador v1
var secundarios: Array = []
var p_secundario := 0.0
var terciarios: Dictionary = {}
var batidora_espacios := 0  ## 0 = sin batidora, puente ni túnel
var batidora_servir := 2
var batidora_pistas := "no"
var arcoiris_uno_cada := 0  ## 0 = sin gota arcoíris
var arcoiris_minimo := 6
var arcoiris_umbral := 0.6
var arcoiris_multiplicador := 2.5
var gotas_cabeza := 12
var peso_cabeza := 3.0
var peso_componente := 0.6
var rondas := 1  ## rondas por nivel (el JSON puede pedir 3); con 1 se comporta como la v2
var subida_ronda := SUBIDA_POR_RONDA

# Estado
var gotas: Array = []  ## {"s", "color", "id", "ot" (seg. de vuelo de inserción), "origen" (Vector2)}
var balas: Array = []  ## {"pos", "vel", "color"}
var actual := ""  ## la gota de la boca
var siguiente := ""  ## la gota de la mano
var pendientes: Array = []  ## lo que vuelve después de servir o de un rebote (§8.3); no se ve
var puntos := 0
var cadena := 0
var combo := 0
var tiempo := 0.0  ## total de la partida (todas las rondas)
var ronda := 1
var t_ronda := 0.0  ## segundos de la ronda actual (la subida de velocidad parte de cero en cada ronda)
var _puntos_ronda := 0
var _tiempo_ronda := 0.0
var estado := "jugando"  ## jugando | tragando | gano | perdio
var entrando := true
var espera := 0.0
var mayor_cadena := 0
var mayor_combo := 0
var disparos := 0
var batidora: Array = []  ## ingredientes adentro, en orden
var cafe_t := 0.0  ## > 0 mientras la batidora eructa café
var batidora_usada := false
var batidora_servida := false
var estadisticas := {"servidos": 0, "cafes": 0, "arcoiris": 0, "cadenas": 0, "rebotes": 0}
var _vel_tragar := VEL_TRAGAR
var _sig_id := 0
var _atraidas: Array = []  ## [id de la punta de adelante, id de la de atrás] de cortes que se están cerrando
var _tiempo_atraccion := {}  ## "idA:idB" -> segundos desde que el par se atrae (rampa y señal)
var _desde_arcoiris := 0
## Grupos del último río generado con `grupo` ([color, tamaño], de la cabeza a la cola): para el arnés.
var grupos_generados: Array = []


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
	# Con varias rondas, cada una lleva una fracción de las gotas del nivel (3 ríos enteros serían eternos).
	rondas = maxi(1, int(nivel.get("rondas", 1)))
	subida_ronda = float(nivel.get("subida_por_ronda", SUBIDA_POR_RONDA))
	if rondas > 1:
		total = maxi(18, roundi(total * float(nivel.get("fraccion_ronda", 0.6))))
	colores = Array(nivel.get("colores", colores))
	velocidad = float(nivel.get("velocidad", velocidad))
	subida = float(nivel.get("subida", subida))
	entrada_hasta = float(nivel.get("entrada_rapida_hasta", entrada_hasta))
	var g: Variant = nivel.get("grupo", null)
	grupo = Vector2i(int(g[0]), int(g[1])) if g is Array and g.size() >= 2 else Vector2i.ZERO
	secundarios = Array(nivel.get("secundarios", []))
	p_secundario = float(nivel.get("p_secundario", 0.0))
	var t: Variant = nivel.get("terciarios", null)
	terciarios = t if t is Dictionary else {}
	var b: Variant = nivel.get("batidora", null)
	batidora_espacios = 0
	if b is Dictionary and recorrido != null and recorrido.tiene_puente():
		batidora_espacios = clampi(int(b.get("espacios", 2)), 2, 3)
		batidora_servir = maxi(1, int(b.get("servir", 2)))
		batidora_pistas = str(b.get("pistas", "siempre"))
	elif b is Dictionary:
		push_warning("LogicaRio: el nivel trae batidora pero el recorrido no tiene puente_batidora")
	var a: Variant = nivel.get("arcoiris", null)
	arcoiris_uno_cada = 0
	if a is Dictionary:
		arcoiris_uno_cada = maxi(0, int(a.get("uno_cada", 14)))
		arcoiris_minimo = int(a.get("minimo_entre", 6))
		arcoiris_umbral = float(a.get("umbral_peligro", 0.6))
		arcoiris_multiplicador = float(a.get("multiplicador_peligro", 2.5))
	var m: Dictionary = nivel.get("municion", {}) if nivel.get("municion", {}) is Dictionary else {}
	gotas_cabeza = int(m.get("gotas_cabeza", 12))
	peso_cabeza = float(m.get("peso_cabeza", 3.0))
	peso_componente = float(m.get("peso_componente", 0.6))
	if bool(nivel.get("mezclas", false)) and batidora_espacios == 0:
		push_warning("LogicaRio: 'mezclas' es obsoleto (ya no hay mezcla dentro del río); usa 'batidora'")
	reiniciar()


func tiene_batidora() -> bool:
	return batidora_espacios > 0


## `conservar_ronda`: el reintento tras perder vuelve a empezar la ronda en que se perdió, no la partida.
func reiniciar(conservar_ronda := false) -> void:
	_llenar_rio()
	ronda = ronda if conservar_ronda else 1
	puntos = _puntos_ronda if conservar_ronda else 0
	tiempo = _tiempo_ronda if conservar_ronda else 0.0
	t_ronda = 0.0
	_puntos_ronda = puntos
	_tiempo_ronda = tiempo
	cadena = 0
	combo = 0
	mayor_cadena = 0
	mayor_combo = 0
	disparos = 0
	estado = "jugando"
	entrando = true
	espera = 0.0
	batidora.clear()
	cafe_t = 0.0
	batidora_usada = false
	batidora_servida = false
	estadisticas = {"servidos": 0, "cafes": 0, "arcoiris": 0, "cadenas": 0, "rebotes": 0}
	_desde_arcoiris = 0
	actual = municion()
	siguiente = municion()


## Río nuevo (inicio, reintento o ronda siguiente): todas las gotas esperan en la nube.
func _llenar_rio() -> void:
	gotas.clear()
	balas.clear()
	pendientes.clear()
	_atraidas.clear()
	_tiempo_atraccion.clear()
	var d := diametro()
	var lista := generar_rio()
	for i in lista.size():
		gotas.append(_nueva_gota(-i * d, lista[i]))
	total_real = gotas.size()


## Ganó la ronda: si quedan, llega un río nuevo más rápido; si era la última, gana. Conserva puntos y
## la munición de Coco (la justa se reordena para el río nuevo).
func _terminar_ronda() -> void:
	if ronda >= rondas:
		estado = "gano"
		termino.emit(true)
		return
	ronda += 1
	_llenar_rio()
	t_ronda = 0.0
	_puntos_ronda = puntos
	_tiempo_ronda = tiempo
	cadena = 0
	combo = 0
	entrando = true
	espera = 0.0
	batidora.clear()
	cafe_t = 0.0
	_ordenar_municion()
	ronda_nueva.emit(ronda, rondas)


func _nueva_gota(s: float, color: String) -> Dictionary:
	_sig_id += 1
	return {"s": s, "color": color, "id": _sig_id, "ot": 0.0, "origen": Vector2.ZERO}


# ---------------------------------------------------------------------------
# Generador del río (§5.1 y §5.3)
# ---------------------------------------------------------------------------

## Colores del río, de la cabeza a la cola. Usa `rng`: con la misma semilla sale el mismo río.
func generar_rio() -> Array:
	if grupo == Vector2i.ZERO:
		return _generar_v1()
	var cantidad_ter := int(terciarios.get("cantidad", 0)) if not terciarios.is_empty() else 0
	var base_total := maxi(1, total - cantidad_ter)
	var salida: Array = []
	var bordes: Array = []  ## índices donde empieza un grupo (menos el primero)
	var previo := ""
	var gmin := maxi(1, grupo.x)
	var gmax := maxi(gmin, grupo.y)
	grupos_generados = []
	while salida.size() < base_total:
		var candidatos: Array = colores
		if not secundarios.is_empty() and rng.randf() < p_secundario:
			candidatos = secundarios
		candidatos = candidatos.filter(func(c): return c != previo)
		if candidatos.is_empty():
			candidatos = colores.filter(func(c): return c != previo)
		var color: String = candidatos[rng.randi_range(0, candidatos.size() - 1)]
		var n := rng.randi_range(gmin, gmax)
		# El último grupo nunca se corta por debajo del mínimo (Maxi no termina con una gota suelta).
		n = maxi(mini(n, base_total - salida.size()), gmin)
		if not salida.is_empty():
			bordes.append(salida.size())
		for k in n:
			salida.append(color)
		grupos_generados.append([color, n])
		previo = color
	if cantidad_ter > 0:
		salida = _insertar_terciarios(salida, bordes, cantidad_ter)
	return salida


## El generador de la v1 tal cual (incluido su tope de 2 seguidas): lo usa un nivel sin `grupo`.
func _generar_v1() -> Array:
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


## Coloca los 2 + 1 en bordes entre dos grupos (nunca parten uno), lejos de la cabeza y separados (§5.3).
func _insertar_terciarios(base: Array, bordes: Array, cantidad: int) -> Array:
	var desde := int(terciarios.get("desde_gota", 12))
	var separacion := int(terciarios.get("separacion_min", 8))
	var n_tipos := int(terciarios.get("tipos", 3))
	var tipos: Array = Array(terciarios.get("tipos_fijos", []))
	if tipos.is_empty():
		var todos: Array = TERCIARIOS.keys()
		_barajar(todos)
		tipos = todos.slice(0, clampi(n_tipos, 1, todos.size()))
	var candidatos: Array = bordes.filter(func(b): return b >= desde)
	var elegidos: Array = []
	for intento in 40:
		var mezcla := candidatos.duplicate()
		_barajar(mezcla)
		var tomados: Array = []
		for b in mezcla:
			if tomados.size() >= cantidad:
				break
			var lejos := true
			for u in tomados:
				if absi(int(u) - int(b)) < separacion:
					lejos = false
					break
			if lejos:
				tomados.append(b)
		if tomados.size() > elegidos.size():
			elegidos = tomados
		if elegidos.size() >= cantidad:
			break
	if elegidos.size() < cantidad:
		push_warning("LogicaRio: solo caben %d de %d colores de 2 + 1 en este río" % [elegidos.size(), cantidad])
	# Cada tipo sale al menos una vez; el resto, al azar entre los tipos del río.
	var lista_tipos: Array = []
	for k in elegidos.size():
		lista_tipos.append(tipos[k] if k < tipos.size() else tipos[rng.randi_range(0, tipos.size() - 1)])
	_barajar(lista_tipos)
	elegidos.sort()
	var salida := base.duplicate()
	for k in range(elegidos.size() - 1, -1, -1):
		salida.insert(int(elegidos[k]), lista_tipos[k])
	return salida


func _barajar(lista: Array) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp


# ---------------------------------------------------------------------------
# Colores y recetas
# ---------------------------------------------------------------------------

static func receta(color: String) -> Array:
	if SECUNDARIOS.has(color):
		return SECUNDARIOS[color]
	if TERCIARIOS.has(color):
		return TERCIARIOS[color]
	return []


## Ingredientes distintos de un color (un primario o el rosado: él mismo).
static func componentes(color: String) -> Array:
	var r := receta(color)
	if r.is_empty():
		return [color]
	var unicos: Array = []
	for c in r:
		if not c in unicos:
			unicos.append(c)
	return unicos


## Resultado de la batidora (§10.3): 1 primario o iguales → ese primario; 2 distintos → secundario;
## 2 iguales + 1 distinto → el 2 + 1; 3 distintos → café. Vacía → "".
static func mezcla_de(contenido: Array) -> String:
	if contenido.is_empty():
		return ""
	var cuenta := {}
	for c in contenido:
		cuenta[c] = int(cuenta.get(c, 0)) + 1
	var distintos: Array = cuenta.keys()
	if distintos.size() == 1:
		return distintos[0]
	if distintos.size() >= 3:
		return CAFE
	if contenido.size() == 2:
		for s in SECUNDARIOS:
			var par: Array = SECUNDARIOS[s]
			if distintos[0] in par and distintos[1] in par:
				return s
		return CAFE
	var dominante: String = distintos[0] if cuenta[distintos[0]] > cuenta[distintos[1]] else distintos[1]
	var otro: String = distintos[1] if dominante == distintos[0] else distintos[0]
	for t in TERCIARIOS:
		var r: Array = TERCIARIOS[t]
		if r[0] == dominante and r[2] == otro:
			return t
	return CAFE


## Una gota "servida": un color que no es munición directa del nivel ni arcoíris (secundario o 2 + 1).
func es_servida(color: String) -> bool:
	return color != "" and color != ARCOIRIS and not color in colores


# ---------------------------------------------------------------------------
# Munición (§8 y §9)
# ---------------------------------------------------------------------------

func colores_presentes() -> Array:
	var presentes := {}
	for g in gotas:
		presentes[g["color"]] = true
	return presentes.keys()


func _presente(color: String) -> bool:
	for g in gotas:
		if g["color"] == color:
			return true
	return false


## Pesos de la munición ponderada (§8.1): ×`peso_cabeza` en las `gotas_cabeza` de adelante y, con
## batidora, ×`peso_componente` para los ingredientes de lo que está en el río.
func pesos_municion() -> Dictionary:
	var w := {}
	for i in gotas.size():
		var peso := peso_cabeza if i < gotas_cabeza else 1.0
		var c: String = gotas[i]["color"]
		if c in colores:
			w[c] = float(w.get(c, 0.0)) + peso
		elif tiene_batidora():
			for ing in componentes(c):
				if ing in colores:
					w[ing] = float(w.get(ing, 0.0)) + peso * peso_componente
	return w


## Una gota nueva para Coco: a veces arcoíris; si no, ponderada por lo que urge.
func municion() -> String:
	if arcoiris_uno_cada > 0 and _desde_arcoiris >= arcoiris_minimo:
		var prob := 1.0 / arcoiris_uno_cada
		if progreso_cabeza() > arcoiris_umbral:
			prob *= arcoiris_multiplicador
		if rng.randf() < prob:
			_desde_arcoiris = 0
			arcoiris_cargada.emit()
			return ARCOIRIS
	var w := pesos_municion()
	var suma := 0.0
	for k in w:
		suma += w[k]
	if suma <= 0.0:
		return colores[rng.randi_range(0, colores.size() - 1)]
	var r := rng.randf() * suma
	for k in w:
		r -= w[k]
		if r <= 0.0:
			return k
	return w.keys()[0]


## ¿Sirve todavía esta gota? (si no, se cambia: munición justa de Zuma). La arcoíris siempre sirve; una
## servida sirve si su color sigue en el río; un primario, si está o es ingrediente de algo (con batidora).
func util(color: String) -> bool:
	if color == ARCOIRIS:
		return true
	if es_servida(color):
		return _presente(color)
	for g in gotas:
		if g["color"] == color:
			return true
		if tiene_batidora() and not g["color"] in colores and color in componentes(g["color"]):
			return true
	return false


## Saca la próxima gota de la cola: primero los pendientes (que sigan sirviendo), después munición nueva.
func _sacar() -> String:
	while not pendientes.is_empty():
		var c: String = pendientes.pop_front()
		if util(c):
			return c
		_descartar(c)
	return municion()


func _descartar(color: String) -> void:
	if es_servida(color):
		servida_evaporada.emit(color)


## Munición justa (§8.2): lo que ya no sirve se cambia. La servida sin destino se evapora y sube la
## siguiente; un primario inútil se cambia por uno nuevo. La arcoíris nunca se toca.
func _ordenar_municion() -> void:
	if gotas.is_empty():
		return
	for k in 20:
		if util(actual):
			break
		_descartar(actual)
		if es_servida(actual):
			actual = siguiente
			siguiente = _sacar()
		else:
			actual = _sacar()
	for k in 20:
		if util(siguiente):
			break
		_descartar(siguiente)
		siguiente = _sacar()


func intercambiar() -> void:
	var t := actual
	actual = siguiente
	siguiente = t


## Dispara desde `origen` en la dirección `angulo`. Devuelve false si todavía no se puede.
func disparar(origen: Vector2, angulo: float) -> bool:
	if estado != "jugando" or espera > 0.0 or actual == "":
		return false
	balas.append({"pos": origen, "vel": Vector2.from_angle(angulo) * VEL_BALA, "color": actual})
	disparos += 1
	_desde_arcoiris += 1
	actual = siguiente
	siguiente = _sacar()
	_ordenar_municion()
	espera = enfriamiento
	return true


# ---------------------------------------------------------------------------
# Batidora (§10)
# ---------------------------------------------------------------------------

## "" si la batidora acepta este color; si no, el motivo del rebote.
func motivo_rechazo(color: String) -> String:
	if cafe_t > 0.0:
		return "cafe"
	if not color in PRIMARIOS:
		return "no_primario"
	if batidora.size() >= batidora_espacios:
		return "llena"
	var iguales := batidora.count(color)
	if (batidora_espacios == 2 and iguales >= 1) or (batidora_espacios >= 3 and iguales >= 2):
		return "repetido"
	return ""


## Una gota le pegó a la batidora: captura o rebote (la rechazada vuelve a la boca, §8.3).
func disparo_a_batidora(color: String) -> bool:
	var motivo := motivo_rechazo(color)
	if motivo != "":
		estadisticas["rebotes"] += 1
		pendientes.push_front(siguiente)
		siguiente = actual
		actual = color
		espera = maxf(espera, SEGUNDOS_REBOTE)
		batidora_rechazo.emit(color, motivo)
		_ordenar_municion()
		return false
	batidora.append(color)
	batidora_usada = true
	var resultado := mezcla_de(batidora)
	batidora_capturo.emit(color, batidora.duplicate(), resultado)
	if resultado == CAFE:
		cafe_t = SEGUNDOS_CAFE
		estadisticas["cafes"] += 1
		batidora_cafe.emit()
	return true


func resultado_batidora() -> String:
	return CAFE if cafe_t > 0.0 else mezcla_de(batidora)


func puede_servir() -> bool:
	if not tiene_batidora() or estado != "jugando" or cafe_t > 0.0 or batidora.size() < 2:
		return false
	var r := mezcla_de(batidora)
	return r != "" and r != CAFE and not r in PRIMARIOS


## La palanca: sirve `batidora_servir` gotas del color mezclado a boca y mano; lo que Coco tenía vuelve
## después, en el mismo orden (§8.3). Sin nada que servir solo avisa (`palanca_vacia`).
func servir() -> bool:
	if not puede_servir():
		if tiene_batidora() and estado == "jugando":
			palanca_vacia.emit()
		return false
	var r := mezcla_de(batidora)
	pendientes.push_front(siguiente)
	pendientes.push_front(actual)
	for k in range(batidora_servir - 1, 1, -1):
		pendientes.push_front(r)
	actual = r
	siguiente = r if batidora_servir >= 2 else _sacar()
	batidora.clear()
	batidora_servida = true
	estadisticas["servidos"] += 1
	espera = maxf(espera, SEGUNDOS_SERVIR)
	batidora_sirvio.emit(r, batidora_servir)
	_ordenar_municion()
	return true


## Hay en el río, a la vista (fuera del túnel), una gota que se arma en la batidora.
func hay_mezcla_a_la_vista() -> bool:
	if not tiene_batidora():
		return false
	for g in gotas:
		if g["s"] > 0.0 and g["s"] < recorrido.largo and not g["color"] in colores and not en_tunel(g["s"]):
			return true
	return false


func en_tunel(s: float) -> bool:
	return tiene_batidora() and absf(s - recorrido.s_puente) < recorrido.tunel_px


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


## Revienta el tramo de `i` si tiene 3+ (o siempre, si `forzar`: la gota arcoíris). La cadena vale 1 en un
## reventón directo y sube 1 por cada retroceso que revienta (nunca por aciertos seguidos: eso es el combo).
func _reventar_en(i: int, es_cadena: bool, forzar := false) -> int:
	var t := tramo(i)
	var n := t.y - t.x + 1
	if n < 3 and not forzar:
		return 0
	cadena = maxi(cadena, 1) + 1 if es_cadena else 1
	mayor_cadena = maxi(mayor_cadena, cadena)
	if es_cadena:
		estadisticas["cadenas"] += 1
	var suma := Vector2.ZERO
	var color: String = gotas[i]["color"]
	for k in range(t.x, t.y + 1):
		suma += recorrido.posicion(gotas[k]["s"])
	for k in n:
		gotas.remove_at(t.x)
	var ganados := n * PUNTOS_POR_GOTA * cadena
	puntos += ganados
	reventaron.emit(n, suma / n, color, cadena, ganados, es_cadena)
	_ordenar_municion()
	return n


## Inserta la bala que pegó en la gota `j`. La gota nueva queda delante o detrás según el lado del impacto.
## La arcoíris toma el color de la gota tocada y revienta ese grupo aunque sea de 1.
func insertar(j: int, posicion_bala: Vector2, color: String) -> void:
	var g: Dictionary = gotas[j]
	var p := recorrido.posicion(g["s"])
	var delante := (posicion_bala - p).dot(recorrido.tangente(g["s"])) > 0.0
	var es_arcoiris := color == ARCOIRIS
	var real: String = g["color"] if es_arcoiris else color
	var nueva := _nueva_gota(g["s"] + diametro() if delante else g["s"], real)
	nueva["origen"] = posicion_bala
	nueva["ot"] = 0.12
	var idx := j if delante else j + 1
	gotas.insert(idx, nueva)
	cadena = 0
	insertada.emit(p, real)
	if es_arcoiris:
		estadisticas["arcoiris"] += 1
		arcoiris_pego.emit(p, real)
	var n := _reventar_en(idx, false, es_arcoiris)
	if n > 0:
		combo += 1
		mayor_combo = maxi(mayor_combo, combo)
		if combo > 1:
			puntos += combo * PUNTOS_POR_GOTA
	else:
		combo = 0
	combo_cambio.emit(combo)


## Para la batalla (modo-equipo.md §5, `cadena_vale_aciertos`): cuántos aciertos de racha vale un
## reventón. Solo un reventón por retroceso (`es_cadena`) vale `cadena_vale`; un acierto directo vale 1,
## aunque venga después de otro (el error de la v1 contaba dos aciertos seguidos como cadena).
static func aciertos_por_reventon(es_cadena: bool, cadena_vale: int) -> int:
	return maxi(1, cadena_vale) if es_cadena else 1


func progreso_cabeza() -> float:
	if gotas.is_empty() or recorrido == null or recorrido.largo <= 0.0:
		return 0.0
	return clampf(gotas[0]["s"] / recorrido.largo, 0.0, 1.0)


func velocidad_actual() -> float:
	if estado == "tragando":
		return _vel_tragar
	if entrando:
		return VEL_ENTRADA
	# Empuje: sin gotas a la vista, la cola avanza rápido hasta que asoma la cabeza (sin esperas).
	if not gotas.is_empty() and gotas[0]["s"] < EMPUJE_HASTA:
		return VEL_ENTRADA
	var por_ronda := 1.0 + subida_ronda * (ronda - 1)
	return velocidad * por_ronda * (1.0 + subida * minf(1.0, t_ronda / SEGUNDOS_SUBIDA))


func avanzar(dt: float) -> void:
	if espera > 0.0:
		espera -= dt
	if cafe_t > 0.0:
		cafe_t -= dt
		if cafe_t <= 0.0:
			cafe_t = 0.0
			batidora.clear()
			batidora_se_vacio.emit()
	if estado == "jugando":
		tiempo += dt
		t_ronda += dt
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
				_terminar_ronda()
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


## Ids de las gotas que brillan porque su corte se está cerrando (§6, "atracción").
func ids_atraidas() -> Dictionary:
	var ids := {}
	for par in _atraidas:
		ids[par[0]] = true
		ids[par[1]] = true
	return ids


## Si los extremos de un corte son del mismo color, el tramo de adelante vuelve hasta chocar.
## El choque se detecta con el mismo margen que `tocan()`: si no, un hueco que queda entre
## `diametro()` y `diametro() + 2` ya cuenta como "pegado" y las puntas se juntaban sin reventar.
func _retroceder(dt: float) -> void:
	# Cortes atraídos el paso anterior que se cerraron por otro lado (la cola los empujó): igual chocan.
	for par in _atraidas:
		var i := _indice_de(par[0])
		if i >= 0 and i + 1 < gotas.size() and gotas[i + 1]["id"] == par[1] and tocan(i):
			_atraidas.clear()
			_chocar(i)
			return
	_atraidas.clear()
	var grupos: Array = []
	var ini := 0
	for i in gotas.size():
		if not tocan(i):
			grupos.append(Vector2i(ini, i))
			ini = i + 1
	var vivos := {}
	for g in grupos.size() - 1:
		var a: Vector2i = grupos[g]
		var b0: int = grupos[g + 1].x
		if gotas[a.y]["color"] != gotas[b0]["color"]:
			continue
		var clave := "%d:%d" % [gotas[a.y]["id"], gotas[b0]["id"]]
		var t_par: float = _tiempo_atraccion.get(clave, -1.0)
		if t_par < 0.0:
			t_par = 0.0
			retroceso_atrae.emit(gotas[a.y]["id"], gotas[b0]["id"])
		t_par += dt
		vivos[clave] = t_par
		# Rampa de 0,1 s (ease-in): se lee como "se atraen", no como un salto.
		var k := minf(1.0, t_par / RAMPA_RETROCESO)
		for q in range(a.x, a.y + 1):
			gotas[q]["s"] -= VEL_RETROCESO * k * k * dt
		if tocan(a.y):
			_chocar(a.y)
			_atraidas.clear()
			_tiempo_atraccion = vivos
			return
		_atraidas.append([gotas[a.y]["id"], gotas[b0]["id"]])
	_tiempo_atraccion = vivos


## Las puntas iguales de un corte (`i` adelante, `i + 1` atrás) quedan justo pegadas: "¡clac!" y, si
## suman 3 o más, revientan en cadena. Dos que suman 2 se unen sin reventar (como en Zuma).
func _chocar(i: int) -> void:
	var falta: float = diametro() - (gotas[i]["s"] - gotas[i + 1]["s"])
	var desde := i
	while desde > 0 and tocan(desde - 1):
		desde -= 1
	for k in range(desde, i + 1):
		gotas[k]["s"] += falta
	var t := tramo(i)
	retroceso_choco.emit(recorrido.posicion(gotas[i]["s"] - radio), t.y - t.x + 1 >= 3)
	_reventar_en(i, true)


func _indice_de(id: int) -> int:
	for i in gotas.size():
		if gotas[i]["id"] == id:
			return i
	return -1


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
	var centro_batidora := recorrido.posicion_batidora() if tiene_batidora() else Vector2.INF
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
			# La arcoíris pasa por encima de la batidora (§9).
			if tiene_batidora() and bala["color"] != ARCOIRIS and p.distance_to(centro_batidora) < RADIO_BATIDORA:
				disparo_a_batidora(bala["color"])
				fin = true
				break
			var golpe := gota_en(p, d * 0.92)
			if golpe >= 0:
				insertar(golpe, p, bala["color"])
				fin = true
				break
		if not fin:
			vivas.append(bala)
	balas = vivas


## Índice de la gota visible más cercana a `p` dentro de `distancia`, o -1. Las del túnel no se ven.
func gota_en(p: Vector2, distancia: float) -> int:
	var mejor := -1
	var mejor_d := distancia
	for i in gotas.size():
		var s: float = gotas[i]["s"]
		if s <= -2.0 or s >= recorrido.largo or en_tunel(s):
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
