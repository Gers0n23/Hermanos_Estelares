class_name LogicaCaminos
extends RefCounted

## Reglas de «Cada quien a su casa» (motor caminos, tipo Flow Free; docs/fichas/motor-caminos.md §6, §9 y §12).
## Sin pantalla y determinista: la usa el motor y la prueba `herramientas/qa_test_caminos.gd`.
##
## Tablero (igual que el JSON del nivel): filas de texto; `A-Z` animal, `a-z` su casa, `#` roca, `+` puente,
## `.` vacía. Un camino es la lista de celdas desde la punta donde empezó (su animal o, en Brote y Estrella con
## casas de color, su casa) hasta su cabeza. Llega cuando toca la otra punta.
##
## - Avanzar celda a celda (sin diagonales); un salto de hasta `atraso_max` celdas se rellena con el camino
##   más corto libre (dedo rápido). Volver sobre el propio camino lo borra.
## - Otro camino: con `cortar_ajenos` se corta desde esa celda y el corte es PROVISIONAL mientras dure el trazo
##   (si el dedo retrocede, el camino cortado vuelve entero, como en Flow Free); sin cortar (Semilla) bloquea.
## - Rocas bloquean; un puente acepta un camino horizontal y uno vertical, siempre en recto.
## - Casa ajena: bloquea con `casa_rechazo`. Con casas de hábitat (Estrella z2+) suma un intento fallido.
## - `llenar`: el tablero recién está completo con todas las baldosas cubiertas (y los puentes en sus dos ejes).
## - Equipo: con `llegados_fijos`, un camino llegado no se puede cortar ni rehacer (§12.2).

signal camino_cambio(par: String)
signal camino_cortado(par: String, celda: int)
signal llego(par: String, trazos: int)
signal casa_rechazo(par: String, casa_de: String)
signal bloqueado(par: String, celda: int, motivo: String)
signal tablero_completo(sin_borrones: bool)
signal falta_llenar(vacias: int)

const VACIA := 0
const ROCA := 1
const PUENTE := 2
const ANIMAL := 3
const CASA := 4
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var ancho := 0
var alto := 0
var tipo: PackedInt32Array = PackedInt32Array()
var par_en: Array[String] = []  ## letra del par en celdas de animal/casa ("" en las demás)
var pares: Array[String] = []
var animal_de: Dictionary = {}  ## par -> celda
var casa_de: Dictionary = {}  ## par -> celda
var solucion: Dictionary = {}  ## par -> Array[int] (del animal a la casa)

# Reglas (del nivel o del perfil del turno)
var llenar := false
var cortar_ajenos := true
var empezar_desde_casa := true
var casas_habitat := false
var iman_casa := 0
var atraso_max := 3
var llegados_fijos := false

# Estado
var caminos: Dictionary = {}  ## par -> Array[int]
var llegado: Dictionary = {}  ## par -> bool
var fijos: Dictionary = {}  ## par -> true (equipo: camino llegado que nadie corta)
var trazo_par := ""
var _cortes: Dictionary = {}  ## par -> camino original antes del corte provisional
var _completo_emitido := false
var _falta_emitido := false

# Puntaje (§9.1)
var puntos_cfg := {"llegada": 100, "racha_max": 5, "tablero": 300, "sin_borrones": 300, "por_segundo": 10}
var puntos := 0
var racha := 0
var trazos: Dictionary = {}  ## par -> trazos de este tablero
var intentos_casa := 0
var llegadas_contadas: Dictionary = {}  ## par -> true (cada animal suma una vez por tablero)


# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------

## `celdas`: filas del tablero. `sol`: {par: [[x, y], ...]} (del animal a la casa).
func configurar(celdas: Array, sol: Dictionary = {}) -> void:
	alto = celdas.size()
	ancho = str(celdas[0]).length() if alto > 0 else 0
	tipo = PackedInt32Array()
	tipo.resize(ancho * alto)
	par_en.clear()
	par_en.resize(ancho * alto)
	pares.clear()
	animal_de.clear()
	casa_de.clear()
	for y in alto:
		var fila := str(celdas[y])
		for x in ancho:
			var c := fila[x]
			var i := y * ancho + x
			par_en[i] = ""
			if c == "#":
				tipo[i] = ROCA
			elif c == "+":
				tipo[i] = PUENTE
			elif c == ".":
				tipo[i] = VACIA
			elif c == c.to_upper():
				tipo[i] = ANIMAL
				par_en[i] = c
				animal_de[c] = i
				if not c in pares:
					pares.append(c)
			else:
				tipo[i] = CASA
				par_en[i] = c.to_upper()
				casa_de[c.to_upper()] = i
	pares.sort()
	solucion.clear()
	for p in sol:
		var lista: Array[int] = []
		for xy in sol[p]:
			lista.append(int(xy[0]) + int(xy[1]) * ancho)
		solucion[str(p)] = lista
	reiniciar()


## Deja el tablero vacío (barrer o tablero nuevo). No toca el puntaje ni la racha.
func reiniciar() -> void:
	caminos.clear()
	llegado.clear()
	fijos.clear()
	trazos.clear()
	llegadas_contadas.clear()
	for p in pares:
		caminos[p] = [] as Array[int]
		llegado[p] = false
		trazos[p] = 0
	trazo_par = ""
	_cortes.clear()
	_completo_emitido = false
	_falta_emitido = false
	intentos_casa = 0


## Giros y espejos que conservan la solución (§11.2). k = 0-7 en tableros cuadrados (bit 2 = espejo, bits 0-1 =
## giros de 90°); en los rectangulares solo 0, 2, 4 y 6 (sin girar 90°). Devuelve [celdas, solucion].
static func transformar(celdas: Array, sol: Dictionary, k: int) -> Array:
	var h := celdas.size()
	var w := str(celdas[0]).length()
	var rot := k & 3
	var espejo := (k & 4) != 0
	if w != h and rot % 2 == 1:
		rot = (rot + 1) % 4
	var nw := h if rot % 2 == 1 else w
	var nh := w if rot % 2 == 1 else h
	var mapa := func(x: int, y: int) -> Vector2i:
		var xx := (w - 1 - x) if espejo else x
		match rot:
			1:
				return Vector2i(h - 1 - y, xx)
			2:
				return Vector2i(w - 1 - xx, h - 1 - y)
			3:
				return Vector2i(y, w - 1 - xx)
		return Vector2i(xx, y)
	var grilla: Array = []
	for y in nh:
		var fila: Array = []
		fila.resize(nw)
		grilla.append(fila)
	for y in h:
		var fila := str(celdas[y])
		for x in w:
			var p: Vector2i = mapa.call(x, y)
			grilla[p.y][p.x] = fila[x]
	var nuevas: Array = []
	for fila in grilla:
		nuevas.append("".join(PackedStringArray(fila)))
	var nueva_sol := {}
	for par in sol:
		var lista: Array = []
		for xy in sol[par]:
			var p: Vector2i = mapa.call(int(xy[0]), int(xy[1]))
			lista.append([p.x, p.y])
		nueva_sol[par] = lista
	return [nuevas, nueva_sol]


# ---------------------------------------------------------------------------
# Utilidades de grilla
# ---------------------------------------------------------------------------

func xy(i: int) -> Vector2i:
	return Vector2i(i % ancho, i / ancho)


func idx(p: Vector2i) -> int:
	if p.x < 0 or p.y < 0 or p.x >= ancho or p.y >= alto:
		return -1
	return p.y * ancho + p.x


func vecino(i: int, d: Vector2i) -> int:
	return idx(xy(i) + d)


func adyacentes(a: int, b: int) -> bool:
	var d := xy(a) - xy(b)
	return absi(d.x) + absi(d.y) == 1


func es_puente(i: int) -> bool:
	return i >= 0 and tipo[i] == PUENTE


func cabeza(p: String) -> int:
	var c: Array = caminos.get(p, [])
	return c[-1] if not c.is_empty() else -1


## La punta opuesta a donde empezó el camino (su meta).
func meta(p: String) -> int:
	var c: Array = caminos.get(p, [])
	if not c.is_empty() and c[0] == casa_de[p]:
		return animal_de[p]
	return casa_de[p]


## Eje en que el camino `p` cruza el puente `i` (0 horizontal, 1 vertical), -1 si no lo cruza.
func _eje_en(p: String, k: int) -> int:
	var c: Array = caminos[p]
	if k <= 0 or k >= c.size():
		return -1
	var d := xy(c[k]) - xy(c[k - 1])
	return 0 if d.y == 0 else 1


## Quién ocupa la celda `i` (en un puente, en el eje `eje`). "" = libre. Las puntas son de su par.
func ocupante(i: int, eje := -1) -> String:
	if par_en[i] != "":
		return par_en[i]
	for p in pares:
		var c: Array = caminos[p]
		var k := c.find(i)
		if k < 0:
			continue
		if tipo[i] != PUENTE or eje < 0 or _eje_en(p, k) == eje:
			return p
	return ""


## Pares cuyo camino pasa por la celda (en un puente pueden ser dos).
func pares_en(i: int) -> Array[String]:
	var r: Array[String] = []
	for p in pares:
		if (caminos[p] as Array).has(i):
			r.append(p)
	return r


func celda_cubierta(i: int) -> bool:
	match tipo[i]:
		ROCA:
			return true
		ANIMAL, CASA:
			return true
		PUENTE:
			return ocupante(i, 0) != "" and ocupante(i, 1) != ""
	return ocupante(i) != ""


func celdas_vacias() -> Array[int]:
	var r: Array[int] = []
	for i in ancho * alto:
		if tipo[i] in [VACIA, PUENTE] and not celda_cubierta(i):
			r.append(i)
	return r


func todos_llegaron() -> bool:
	for p in pares:
		if not llegado[p]:
			return false
	return true


func esta_completo() -> bool:
	return todos_llegaron() and (not llenar or celdas_vacias().is_empty())


func cantidad_llegados() -> int:
	var n := 0
	for p in pares:
		if llegado[p]:
			n += 1
	return n


# ---------------------------------------------------------------------------
# Trazo
# ---------------------------------------------------------------------------

## Presionar sobre la celda `i`. Devuelve el par que empieza a trazar ("" si ahí no hay nada que trazar).
## `par_forzado` (equipo, turno de Maxi): solo ese par se puede tomar.
func empezar(i: int, par_forzado := "") -> String:
	if i < 0:
		return ""
	var p := ""
	var desde := -1  ## índice del camino desde donde se sigue (-1 = empezar de nuevo desde la punta)
	if tipo[i] == ANIMAL:
		p = par_en[i]
		var c: Array = caminos[p]
		if not c.is_empty() and c[-1] == i and c[0] != i:
			desde = c.size() - 1  # la cabeza llegó a su animal (camino desde la casa): se retoma
	elif tipo[i] == CASA:
		p = par_en[i]
		var c: Array = caminos[p]
		if not c.is_empty() and c[-1] == i and c[0] != i:
			desde = c.size() - 1
		elif not empezar_desde_casa:
			return ""
	else:
		for q in pares:
			var c: Array = caminos[q]
			var k := c.find(i)
			if k >= 0:
				p = q
				desde = k
				break
	if p == "" or (par_forzado != "" and p != par_forzado):
		return ""
	if fijos.has(p):
		return ""
	trazo_par = p
	_cortes.clear()
	trazos[p] = int(trazos.get(p, 0)) + 1
	if desde < 0:
		var tenia := (caminos[p] as Array).size() > 1
		if llegado[p]:
			_romper_racha()
		caminos[p] = [i] as Array[int]
		llegado[p] = false
		if tenia:
			camino_cambio.emit(p)
	else:
		_truncar(p, desde)
	return p


## El dedo está sobre la celda `i` (ya con histéresis aplicada por el motor). Avanza, retrocede o rellena.
## Devuelve true si el camino cambió.
func mover(i: int) -> bool:
	var p := trazo_par
	if p == "" or i < 0:
		return false
	var c: Array = caminos[p]
	if c.is_empty() or c[-1] == i:
		return false
	# Volver sobre el propio camino lo borra hasta ahí (en un puente, solo si es la celda previa).
	var k := c.find(i)
	if k >= 0 and (tipo[i] != PUENTE or k == c.size() - 2):
		_truncar(p, k)
		_restaurar_cortes()
		camino_cambio.emit(p)
		return true
	if llegado[p]:
		return false
	var cambio := false
	if adyacentes(c[-1], i):
		cambio = _paso(p, i)
	else:
		var tramo := _tramo_rapido(p, i)
		for celda in tramo:
			if not _paso(p, celda):
				break
			cambio = true
			if llegado[p]:
				break
	if cambio:
		_restaurar_cortes()
		camino_cambio.emit(p)
	return cambio


## Soltar el dedo: los cortes provisionales quedan firmes. Con imán (Semilla), si la cabeza quedó a una celda de
## su meta, salta sola adentro. Devuelve true si el imán completó el camino.
func soltar() -> bool:
	var p := trazo_par
	trazo_par = ""
	_cortes.clear()
	if p == "" or llegado[p] or iman_casa <= 0:
		return false
	var c: Array = caminos[p]
	if c.size() < 1:
		return false
	var m := meta(p)
	if adyacentes(c[-1], m) and not es_puente(c[-1]):
		trazo_par = p
		var ok := _paso(p, m)
		trazo_par = ""
		if ok:
			camino_cambio.emit(p)
			return true
	return false


## Un paso desde la cabeza hasta la celda vecina `n`. Devuelve true si avanzó.
func _paso(p: String, n: int) -> bool:
	var c: Array = caminos[p]
	var h: int = c[-1]
	var d := xy(n) - xy(h)
	# Sobre un puente solo se sigue en recto.
	if es_puente(h) and c.size() >= 2:
		var entrada := xy(h) - xy(c[-2])
		if entrada != d:
			bloqueado.emit(p, n, "puente")
			return false
	var eje := 0 if d.y == 0 else 1
	match tipo[n]:
		ROCA:
			bloqueado.emit(p, n, "roca")
			return false
		ANIMAL, CASA:
			if n == meta(p):
				c.append(n)
				llegado[p] = true
				_al_llegar(p)
				return true
			if par_en[n] != p and tipo[n] == CASA:
				if casas_habitat:
					intentos_casa += 1
				casa_rechazo.emit(p, par_en[n])
			else:
				bloqueado.emit(p, n, "punta")
			return false
		PUENTE:
			var siguiente := vecino(n, d)
			if siguiente < 0 or tipo[siguiente] == ROCA or c.has(n):
				bloqueado.emit(p, n, "puente")
				return false
			var otro := ocupante(n, eje)
			if otro != "" and otro != p:
				if not _cortar(otro, n, p):
					return false
			c.append(n)
			return true
	var otro := ocupante(n)
	if otro != "" and otro != p:
		if not _cortar(otro, n, p):
			return false
	c.append(n)
	return true


## Corta el camino `q` desde la celda `n` (provisional mientras dure el trazo). false si no se puede.
func _cortar(q: String, n: int, quien: String) -> bool:
	if not cortar_ajenos or fijos.has(q):
		bloqueado.emit(quien, n, "camino")
		return false
	var c: Array = caminos[q]
	var k := c.find(n)
	if k <= 0:
		return false
	if not _cortes.has(q):
		_cortes[q] = c.duplicate()
	if llegado[q]:
		llegado[q] = false
	_romper_racha()
	caminos[q] = c.slice(0, k) as Array[int]
	camino_cortado.emit(q, n)
	camino_cambio.emit(q)
	return true


## Corte provisional (Flow Free): mientras el dedo no suelte, cada camino cortado recupera el tramo más largo de
## su original que ya no choca con el trazo.
func _restaurar_cortes() -> void:
	if _cortes.is_empty() or trazo_par == "":
		return
	var mio: Array = caminos[trazo_par]
	for q in _cortes.keys():
		var original: Array = _cortes[q]
		var largo := original.size()
		for k in original.size():
			var celda: int = original[k]
			if mio.has(celda) and celda != original[0]:
				if tipo[celda] == PUENTE:
					var eje_q := _eje_lista(original, k)
					var k_mio := mio.find(celda)
					if _eje_lista(mio, k_mio) != eje_q:
						continue
				largo = k
				break
		var actual: Array = caminos[q]
		if largo > actual.size():
			caminos[q] = original.slice(0, largo) as Array[int]
			if largo == original.size() and original[-1] == _meta_de_lista(q, original):
				llegado[q] = true
			camino_cambio.emit(q)
		if largo == original.size():
			_cortes.erase(q)


func _eje_lista(lista: Array, k: int) -> int:
	if k <= 0 or k >= lista.size():
		return -1
	var d := xy(lista[k]) - xy(lista[k - 1])
	return 0 if d.y == 0 else 1


func _meta_de_lista(q: String, lista: Array) -> int:
	return animal_de[q] if lista[0] == casa_de[q] else casa_de[q]


func _truncar(p: String, k: int) -> void:
	var c: Array = caminos[p]
	if k < c.size() - 1:
		if llegado[p]:
			llegado[p] = false
			_romper_racha()
		caminos[p] = c.slice(0, k + 1) as Array[int]


## Dedo rápido: el camino ortogonal más corto (BFS) desde la cabeza hasta `destino`, de hasta `atraso_max`
## celdas, que no pase por rocas, puntas ajenas ni caminos que no se pueden cortar. [] si no hay.
func _tramo_rapido(p: String, destino: int) -> Array[int]:
	var c: Array = caminos[p]
	var origen: int = c[-1]
	var dist_max := atraso_max
	var d0 := xy(destino) - xy(origen)
	if absi(d0.x) + absi(d0.y) > dist_max:
		return []
	var previo := {origen: -1}
	var cola: Array[int] = [origen]
	var nivel := {origen: 0}
	while not cola.is_empty():
		var a: int = cola.pop_front()
		if a == destino:
			break
		if int(nivel[a]) >= dist_max:
			continue
		for d in DIRS:
			var b := vecino(a, d)
			if b < 0 or previo.has(b):
				continue
			if not _transitable(p, b) and b != destino:
				continue
			if b == destino and tipo[b] in [ANIMAL, CASA] and b != meta(p):
				continue
			previo[b] = a
			nivel[b] = int(nivel[a]) + 1
			cola.append(b)
	if not previo.has(destino):
		return []
	var tramo: Array[int] = []
	var x := destino
	while x != origen:
		tramo.push_front(x)
		x = previo[x]
	return tramo


func _transitable(p: String, i: int) -> bool:
	match tipo[i]:
		ROCA, ANIMAL, CASA:
			return false
		PUENTE:
			return false  # el relleno rápido no se arriesga a girar sobre un puente
	if (caminos[p] as Array).has(i):
		return false
	var otro := ocupante(i)
	if otro == "" or otro == p:
		return true
	return cortar_ajenos and not fijos.has(otro)


# ---------------------------------------------------------------------------
# Llegadas, puntaje y fin del tablero
# ---------------------------------------------------------------------------

func _al_llegar(p: String) -> void:
	if not llegadas_contadas.has(p):
		llegadas_contadas[p] = true
		racha = mini(racha + 1, int(puntos_cfg.get("racha_max", 5)))
		puntos += int(puntos_cfg.get("llegada", 100)) * racha
	if llegados_fijos:
		fijos[p] = true
	llego.emit(p, int(trazos.get(p, 0)))
	revisar_fin()


## Emite `tablero_completo` (una vez) o `falta_llenar` (una vez por tablero) según corresponda.
func revisar_fin() -> void:
	if _completo_emitido or not todos_llegaron():
		return
	if llenar:
		var vacias := celdas_vacias()
		if not vacias.is_empty():
			if not _falta_emitido:
				_falta_emitido = true
				falta_llenar.emit(vacias.size())
			return
	_completo_emitido = true
	var sin_borrones := trazos_totales() <= pares.size()
	puntos += int(puntos_cfg.get("tablero", 300))
	if sin_borrones:
		puntos += int(puntos_cfg.get("sin_borrones", 300))
	tablero_completo.emit(sin_borrones)


func completo_emitido() -> bool:
	return _completo_emitido


func trazos_totales() -> int:
	var n := 0
	for p in pares:
		n += int(trazos.get(p, 0))
	return n


func trazos_de_mas() -> int:
	return maxi(0, trazos_totales() - pares.size())


func _romper_racha() -> void:
	racha = 0


## Barrer (§6.2): todos los caminos se borran (menos los fijos del equipo).
func barrer() -> void:
	var hubo := false
	for p in pares:
		if fijos.has(p):
			continue
		if (caminos[p] as Array).size() > 0:
			hubo = true
		caminos[p] = [] as Array[int]
		llegado[p] = false
	trazo_par = ""
	_cortes.clear()
	if hubo:
		_romper_racha()
	for p in pares:
		camino_cambio.emit(p)


## Borra el camino de un par (válvula de Toby, gag del equipo). Si estaba llegado, deja de estarlo.
func borrar_camino(p: String) -> void:
	caminos[p] = [] as Array[int]
	llegado[p] = false
	fijos.erase(p)
	if trazo_par == p:
		trazo_par = ""
	camino_cambio.emit(p)


# ---------------------------------------------------------------------------
# Ayudas: solución guardada, pistas, regalo y mano fantasma
# ---------------------------------------------------------------------------

## ¿El camino de `p` es exactamente el de la solución y llegó?
func par_correcto(p: String) -> bool:
	if not llegado[p] or not solucion.has(p):
		return false
	var c: Array = caminos[p]
	var s: Array = solucion[p]
	if c == s:
		return true
	var r := c.duplicate()
	r.reverse()
	return r == s


## El primer par que no está bien resuelto (orden de la solución), o "".
func par_para_ayudar(excluir: Array = []) -> String:
	for p in pares:
		if p in excluir:
			continue
		if not par_correcto(p):
			return p
	return ""


## Toby traza el camino de la solución de `p` (pista, regalo, ayuda fuerte). Lo que estorba se corta o se borra
## (Toby sopla). Devuelve true si hizo algo.
func colocar_solucion(p: String) -> bool:
	if not solucion.has(p) or par_correcto(p):
		return false
	var s: Array = solucion[p]
	for q in pares:
		if q == p:
			continue
		var c: Array = caminos[q]
		for k in range(1, c.size()):
			var celda: int = c[k]
			if not s.has(celda):
				continue
			if tipo[celda] == PUENTE:
				var ks := s.find(celda)
				if _eje_lista(s, ks) != _eje_en(q, k):
					continue
			caminos[q] = c.slice(0, k) as Array[int]
			if llegado[q]:
				llegado[q] = false
			fijos.erase(q)
			camino_cortado.emit(q, celda)
			camino_cambio.emit(q)
			break
	trazos[p] = maxi(1, int(trazos.get(p, 0)))
	caminos[p] = s.duplicate() as Array[int]
	llegado[p] = false
	camino_cambio.emit(p)
	llegado[p] = true
	_al_llegar(p)
	return true


## Camino libre más corto (BFS) del animal de `p` a su casa, sin pisar caminos de otros (los que no se pueden
## cortar nunca; los demás solo si `atravesar_ajenos`). [] si no hay. Lo usan la válvula y el equipo.
func ruta_libre(p: String, atravesar_ajenos := false) -> Array[int]:
	var origen: int = animal_de[p]
	var destino: int = casa_de[p]
	var previo := {origen: -1}
	var cola: Array[int] = [origen]
	while not cola.is_empty():
		var a: int = cola.pop_front()
		if a == destino:
			break
		for d in DIRS:
			var b := vecino(a, d)
			if b < 0 or previo.has(b):
				continue
			if b != destino:
				if tipo[b] in [ROCA, ANIMAL, CASA, PUENTE]:
					continue
				var otro := ocupante(b)
				if otro != "" and otro != p and (fijos.has(otro) or not atravesar_ajenos):
					continue
			previo[b] = a
			cola.append(b)
	if not previo.has(destino):
		return []
	var r: Array[int] = []
	var x := destino
	while x != -1:
		r.push_front(x)
		x = previo[x]
	return r


## Pone `ruta` como camino de `p` (ya llegado), cortando a los que estorban. Lo usa la jugada automática de Maxi.
func colocar_ruta(p: String, ruta: Array[int]) -> void:
	for q in pares:
		if q == p:
			continue
		var c: Array = caminos[q]
		for k in range(1, c.size()):
			if ruta.has(c[k]):
				caminos[q] = c.slice(0, k) as Array[int]
				llegado[q] = false
				camino_cortado.emit(q, c[k])
				camino_cambio.emit(q)
				break
	trazos[p] = maxi(1, int(trazos.get(p, 0)))
	caminos[p] = ruta.duplicate() as Array[int]
	camino_cambio.emit(p)
	llegado[p] = true
	_al_llegar(p)


## Semilla, válvula contra trabarse (§10.1): un par que ya no tiene salida porque otro camino le tapa todo.
## Devuelve {"trabado": par, "estorba": par} o {}.
func buscar_trabados() -> Dictionary:
	for p in pares:
		if llegado[p]:
			continue
		if not ruta_libre(p, false).is_empty():
			continue
		# ¿quién le estorba? el primer par cuyo camino pisa su solución (o su ruta libre atravesando ajenos)
		var ruta: Array = solucion.get(p, ruta_libre(p, true))
		for celda in ruta:
			for q in pares_en(celda):
				if q != p and not fijos.has(q):
					return {"trabado": p, "estorba": q}
	return {}


## ¿Se puede todavía conectar cada par sin cruzarse? (búsqueda chica, para tableros sin llenar; equipo y Semilla).
## Los caminos llegados se respetan; los demás se ignoran (se pueden rehacer).
func hay_salida_para_todos() -> bool:
	var pendientes: Array[String] = []
	var ocupadas := {}
	for p in pares:
		if llegado[p]:
			for celda in caminos[p]:
				ocupadas[celda] = p
		else:
			pendientes.append(p)
	return _buscar(pendientes, ocupadas, 0)


func _buscar(pendientes: Array[String], ocupadas: Dictionary, profundidad: int) -> bool:
	if pendientes.is_empty():
		return true
	if profundidad > 6:
		return true  # no se gasta más: se asume que hay salida
	var p := pendientes[0]
	var origen: int = animal_de[p]
	var destino: int = casa_de[p]
	var previo := {origen: -1}
	var cola: Array[int] = [origen]
	while not cola.is_empty():
		var a: int = cola.pop_front()
		if a == destino:
			break
		for d in DIRS:
			var b := vecino(a, d)
			if b < 0 or previo.has(b):
				continue
			if b != destino and (tipo[b] in [ROCA, ANIMAL, CASA, PUENTE] or ocupadas.has(b)):
				continue
			previo[b] = a
			cola.append(b)
	if not previo.has(destino):
		return false
	var nuevas := ocupadas.duplicate()
	var x := destino
	while x != -1:
		nuevas[x] = p
		x = previo[x]
	var resto: Array[String] = pendientes.slice(1)
	return _buscar(resto, nuevas, profundidad + 1)


## Comprueba que una solución ({par: [celdas]}) cumple las reglas del tablero. Devuelve la lista de errores.
func validar_solucion(sol: Dictionary, con_llenado: bool) -> Array[String]:
	var errores: Array[String] = []
	var usadas := {}
	var usos_puente := {}
	for p in pares:
		if not sol.has(p):
			errores.append("falta el camino de %s" % p)
			continue
		var c: Array = sol[p]
		if c.is_empty() or c[0] != animal_de[p] or c[-1] != casa_de[p]:
			errores.append("%s no une su animal con su casa" % p)
			continue
		for k in c.size():
			var celda: int = c[k]
			if tipo[celda] == ROCA:
				errores.append("%s pisa una roca" % p)
			if k > 0 and not adyacentes(c[k - 1], celda):
				errores.append("%s salta celdas" % p)
			if tipo[celda] == PUENTE:
				if k == 0 or k == c.size() - 1:
					errores.append("%s termina en un puente" % p)
					continue
				var d1 := xy(celda) - xy(c[k - 1])
				var d2 := xy(c[k + 1]) - xy(celda)
				if d1 != d2:
					errores.append("%s dobla sobre un puente" % p)
				var clave := "%d:%d" % [celda, 0 if d1.y == 0 else 1]
				if usos_puente.has(clave):
					errores.append("puente usado dos veces en el mismo eje")
				usos_puente[clave] = p
			else:
				if usadas.has(celda):
					errores.append("%s cruza a %s" % [p, usadas[celda]])
				usadas[celda] = p
			if tipo[celda] in [ANIMAL, CASA] and par_en[celda] != p:
				errores.append("%s pasa por una punta ajena" % p)
	if con_llenado:
		for i in ancho * alto:
			match tipo[i]:
				VACIA:
					if not usadas.has(i):
						errores.append("baldosa sin cubrir %s" % str(xy(i)))
				PUENTE:
					if not usos_puente.has("%d:0" % i) or not usos_puente.has("%d:1" % i):
						errores.append("puente sin cubrir %s" % str(xy(i)))
	return errores
