class_name LogicaCortar
extends RefCounted

## Reglas puras del motor `cortar` («La Gran Burbujeada», jefe de Animalia; docs/fichas/batalla-animalia.md §5).
## Sin nodos ni pantalla: parabolas calculadas (sin fisica, GDD §8), interseccion segmento-circulo del trazo,
## sorteo con semilla, pool de animales, frascos (reloj de la oleada), conservacion del 30 %, ayudas, rotacion de
## gags y estrellitas de la revancha. Todo determinista: el arnes reproduce cualquier tanda con la misma semilla.


# ---------------------------------------------------------------------------
# Trayectorias (§5.9): x(t) = x0 + (xa - x0)·(2t/T), y(t) = y_pasto - 4·(y_pasto - ya)·(t/T)·(1 - t/T)
# ---------------------------------------------------------------------------

## `tr` = {x0, y0, xa, ya, T}. Sin bamboleo (lo suma la burbuja).
static func posicion(tr: Dictionary, t: float) -> Vector2:
	var duracion := maxf(0.001, float(tr.get("T", 1.0)))
	var u := clampf(t / duracion, 0.0, 1.0)
	var x0 := float(tr.get("x0", 0.0))
	var y0 := float(tr.get("y0", 0.0))
	var x := x0 + (float(tr.get("xa", x0)) - x0) * 2.0 * u
	var y := y0 - 4.0 * (y0 - float(tr.get("ya", y0))) * u * (1.0 - u)
	return Vector2(x, y)


## Arco de Brote/Estrella: sale del pasto en `salida_x`, deriva `deriva_x_px`, apice en `apice_y`. El arco entero
## (salida, apice y vuelta) queda dentro de la zona de juego con el radio de la burbuja (§5.2).
static func trayectoria_arco(rng: RandomNumberGenerator, nivel: Dictionary, radio: float, vuelo_s: float) -> Dictionary:
	var zona := zona_juego(nivel)
	var sx := _par(nivel.get("salida_x", [220, 1060]), Vector2(220, 1060))
	var dx := _par(nivel.get("deriva_x_px", [-200, 200]), Vector2(-200, 200))
	var ay := _par(nivel.get("apice_y", [190, 330]), Vector2(190, 330))
	var min_x := zona.position.x + radio
	var max_x := zona.end.x - radio
	var x0 := clampf(rng.randf_range(sx.x, sx.y), min_x, max_x)
	var caida := clampf(x0 + rng.randf_range(dx.x, dx.y), min_x, max_x)
	var ya := maxf(rng.randf_range(ay.x, ay.y), zona.position.y + radio)
	return {"x0": x0, "y0": float(nivel.get("pasto_y", 610)), "xa": (x0 + caida) / 2.0, "ya": ya, "T": vuelo_s}


## Burbuja trompeta: entra desde un costado (lado -1 izquierda, 1 derecha) hacia el centro.
static func trayectoria_costado(rng: RandomNumberGenerator, nivel: Dictionary, radio: float, vuelo_s: float, lado: int) -> Dictionary:
	var zona := zona_juego(nivel)
	var x0 := (zona.position.x + radio + 10.0) if lado < 0 else (zona.end.x - radio - 10.0)
	var caida := x0 - float(lado) * rng.randf_range(300.0, 420.0)
	var ay := _par(nivel.get("apice_y", [190, 330]), Vector2(190, 330))
	return {"x0": x0, "y0": float(nivel.get("pasto_y", 610)), "xa": (x0 + caida) / 2.0,
		"ya": maxf(rng.randf_range(ay.x, ay.y), zona.position.y + radio), "T": vuelo_s}


## Burbuja de Maxi (§5.4): sube y se queda flotando en x 400-880, y 300-380.
static func trayectoria_semilla(rng: RandomNumberGenerator, nivel: Dictionary, sube_s: float) -> Dictionary:
	var xa := rng.randf_range(400.0, 880.0)
	return {"x0": clampf(xa + rng.randf_range(-60.0, 60.0), 400.0, 880.0), "y0": float(nivel.get("pasto_y", 610)),
		"xa": xa, "ya": rng.randf_range(300.0, 380.0), "T": sube_s, "flota": true}


## Para la burbuja que flota: sube con ease-out hasta el apice y ahi se queda.
static func posicion_flotante(tr: Dictionary, t: float) -> Vector2:
	var u := clampf(t / maxf(0.001, float(tr.get("T", 1.2))), 0.0, 1.0)
	var e := 1.0 - pow(1.0 - u, 3.0)
	return Vector2(lerpf(float(tr["x0"]), float(tr["xa"]), e), lerpf(float(tr["y0"]), float(tr["ya"]), e))


static func zona_juego(nivel: Dictionary) -> Rect2:
	var z = nivel.get("zona_juego", [140, 110, 1000, 490])
	if z is Array and z.size() >= 4:
		return Rect2(float(z[0]), float(z[1]), float(z[2]), float(z[3]))
	return Rect2(140, 110, 1000, 490)


# ---------------------------------------------------------------------------
# Trazo (§5.3): cada par de muestras forma un segmento; revienta toda burbuja cuyo circulo de hitbox lo cruce
# ---------------------------------------------------------------------------

static func distancia_a_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var largo2 := ab.length_squared()
	if largo2 < 0.0001:
		return p.distance_to(a)
	var u := clampf((p - a).dot(ab) / largo2, 0.0, 1.0)
	return p.distance_to(a + ab * u)


static func segmento_cruza_circulo(a: Vector2, b: Vector2, centro: Vector2, radio: float) -> bool:
	return radio > 0.0 and distancia_a_segmento(centro, a, b) <= radio


## Radio de hitbox (§5.3): animal = radio + extra; calcetin = radio - menos (mas chica que el dibujo).
static func radio_hitbox(tipo: String, radio_visual: float, extra: float, menos_calcetin: float) -> float:
	if tipo == "calcetin":
		return maxf(4.0, radio_visual - menos_calcetin)
	return radio_visual + extra


# ---------------------------------------------------------------------------
# Pool de animales (§5.4): las burbujas salen del pool; un escape devuelve el animal al pool
# ---------------------------------------------------------------------------

static func total_pool(pool: Dictionary) -> int:
	var n := 0
	for id in pool:
		n += maxi(0, int(pool[id]))
	return n


## Saca un animal (con preferencia por los favoritos del perfil, si quedan). "" si el pool esta vacio.
static func sacar(pool: Dictionary, rng: RandomNumberGenerator, preferidos: Array = [], p_preferido: float = 0.75) -> String:
	var disponibles: Array = []
	for id in pool:
		if int(pool[id]) > 0:
			disponibles.append(str(id))
	if disponibles.is_empty():
		return ""
	disponibles.sort()
	var favs: Array = disponibles.filter(func(id: String) -> bool: return id in preferidos)
	var elegido := ""
	var tirada := rng.randf()
	if not favs.is_empty() and tirada < p_preferido:
		elegido = favs[rng.randi_range(0, favs.size() - 1)]
	else:
		var total := total_pool(pool)
		var k := rng.randi_range(0, total - 1)
		for id in disponibles:
			k -= int(pool[id])
			if k < 0:
				elegido = id
				break
	pool[elegido] = int(pool[elegido]) - 1
	return elegido


static func devolver(pool: Dictionary, id: String) -> void:
	if id == "":
		return
	pool[id] = int(pool.get(id, 0)) + 1


## Pool de la oleada menos los ya liberados (sirve al retomar y al reintentar).
static func pool_sin(pool_base: Dictionary, liberados: Array) -> Dictionary:
	var pool := {}
	for id in pool_base:
		pool[str(id)] = int(pool_base[id])
	for id in liberados:
		if int(pool.get(str(id), 0)) > 0:
			pool[str(id)] = int(pool[str(id)]) - 1
	return pool


static func meta_oleada(oleada: Dictionary) -> int:
	return int(oleada.get("meta", total_pool(oleada.get("pool", {}))))


# ---------------------------------------------------------------------------
# Frascos (el reloj de la oleada, D5) y reparto por el ciclo del gestor
# ---------------------------------------------------------------------------

## 9 en el intento 1 de la oleada; 13 desde la 1.a derrota de esa oleada.
static func frascos_intento(derrotas_oleada: int, valores: Array) -> int:
	if valores.is_empty():
		return 9
	return int(valores[0]) if derrotas_oleada <= 0 or valores.size() < 2 else int(valores[1])


## §5.7: los guardados, con un minimo, redondeados HACIA ARRIBA al siguiente valor de `retomar_valores`
## (5, 9, 13 = 1 mod 4: el retomado tambien termina con Maxi), sin pasar la canasta llena del intento.
static func frascos_al_retomar(guardados: int, retomar_valores: Array, canasta_llena: int) -> int:
	var valores: Array = []
	for v in retomar_valores:
		valores.append(int(v))
	valores.sort()
	var minimo: int = valores[0] if not valores.is_empty() else 1
	var n := maxi(guardados, minimo)
	for v in valores:
		if v >= n:
			n = v
			break
	return mini(n, maxi(canasta_llena, minimo))


## Quien juega cada frasco si el intento empieza en `ciclo[0]` (el gestor reinicia el ciclo con Maxi).
static func secuencia_turnos(ciclo: Array, frascos: int) -> Array:
	var r: Array = []
	if ciclo.is_empty():
		return r
	for i in frascos:
		r.append(ciclo[i % ciclo.size()])
	return r


static func reparto(ciclo: Array, frascos: int) -> Dictionary:
	var r := {}
	for id in secuencia_turnos(ciclo, frascos):
		r[id] = int(r.get(id, 0)) + 1
	return r


# ---------------------------------------------------------------------------
# Reintento, ayudas y gags (§5.5)
# ---------------------------------------------------------------------------

## D8: queda liberado el 30 % de lo liberado en el intento perdido, redondeado hacia abajo.
static func conservados(liberados: int, fraccion: float) -> int:
	return maxi(0, floori(float(liberados) * fraccion + 0.000001))


static func toby_ayuda(derrotas_oleada: int, desde: int) -> bool:
	return desde > 0 and derrotas_oleada >= desde


static func ofrecer_descanso(derrotas_oleada: int, desde: int) -> bool:
	return desde > 0 and derrotas_oleada >= desde


## 1.a, 2.a y 3.a derrota de la batalla: los gags en orden; desde la 4.a, rotan sin repetir el anterior.
static func variante_gag(derrotas: int, ultimo: String, gags: Array) -> String:
	if gags.is_empty():
		return ""
	if derrotas >= 1 and derrotas <= gags.size():
		return str(gags[derrotas - 1])
	var i := gags.find(ultimo)
	return str(gags[(i + 1) % gags.size()])


# ---------------------------------------------------------------------------
# Tandas (§5.4): una tanda = uno o dos soplidos; eventos con tiempo relativo al inicio de la tanda
# ---------------------------------------------------------------------------

## Valor de un parametro por oleada: escalar o arreglo [O1, O2, O3].
static func por_oleada(valor, idx: int, defecto = 0):
	if valor is Array:
		if valor.is_empty():
			return defecto
		return valor[clampi(idx, 0, valor.size() - 1)]
	return valor if valor != null else defecto


## Plan de la tanda: [{t, tipo: "anticipacion"|"burbuja"|"calcetin"|"siesta"|"trompeta", soplido}].
## `especiales` = ["siesta"] / ["trompeta"]: se agregan al final del soplido 1 y 2 (si hay uno solo, al 1.o).
static func planear_tanda(rng: RandomNumberGenerator, perfil: String, cfg: Dictionary, idx_oleada: int, especiales: Array = []) -> Array:
	var eventos: Array = []
	if perfil == "semilla":
		eventos.append({"t": 0.0, "tipo": "anticipacion", "soplido": 0})
		eventos.append({"t": 0.6, "tipo": "burbuja", "soplido": 0})
		return eventos
	var soplidos := maxi(1, int(cfg.get("soplidos", 2)))
	var n := maxi(1, int(por_oleada(cfg.get("burbujas", 3), idx_oleada, 3)))
	var intervalo := float(por_oleada(cfg.get("intervalo_s", 0.6), idx_oleada, 0.6))
	var pausa := float(cfg.get("pausa_soplidos_s", 0.8))
	var calc: Dictionary = cfg.get("calcetin", {})
	var p_calc := float(por_oleada(calc.get("p", 0), idx_oleada, 0.0))
	var max_calc := int(por_oleada(calc.get("max_tanda", 0), idx_oleada, 0))
	var calcetines := 0
	var t := 0.0
	for s in soplidos:
		eventos.append({"t": t, "tipo": "anticipacion", "soplido": s})
		var t_ultima := t + 0.6
		for i in n:
			t_ultima = t + 0.6 + intervalo * i
			eventos.append({"t": t_ultima, "tipo": "burbuja", "soplido": s})
		var tirada := rng.randf()
		if calcetines < max_calc and tirada < p_calc:
			calcetines += 1
			var j := rng.randi_range(0, n - 1)
			eventos.append({"t": t + 0.6 + intervalo * (j + 0.5), "tipo": "calcetin", "soplido": s})
		var especial := ""
		if s < especiales.size():
			especial = str(especiales[s])
		elif soplidos == 1 and especiales.size() > 1:
			especial = str(especiales[1])
		if especial != "":
			t_ultima += intervalo
			eventos.append({"t": t_ultima, "tipo": especial, "soplido": s})
		t = t_ultima + pausa
	eventos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	return eventos


# ---------------------------------------------------------------------------
# Revancha (§5.8)
# ---------------------------------------------------------------------------

## ★ ganar · ★★ sin perder ninguna oleada · ★★★ ademas >= `sobrantes_tres` frascos en cada oleada. Record =
## frascos usados en total (-1 si hubo ayudas, o sea si hubo alguna derrota). Solo con la composicion `solo_con`.
static func resultado_revancha(clave: String, solo_con: String, derrotas: int, sobrantes: Array, frascos_usados: int,
		sobrantes_tres: int = 2) -> Dictionary:
	if clave != solo_con:
		return {"estrellitas": 0, "record": -1}
	var estrellitas := 1
	if derrotas == 0:
		estrellitas = 2
		var todas := not sobrantes.is_empty()
		for s in sobrantes:
			if int(s) < sobrantes_tres:
				todas = false
		if todas:
			estrellitas = 3
	return {"estrellitas": estrellitas, "record": frascos_usados if derrotas == 0 else -1}


# ---------------------------------------------------------------------------
# Validacion del nivel
# ---------------------------------------------------------------------------

static func validar_nivel(nivel: Dictionary) -> Array[String]:
	var errores: Array[String] = []
	var oleadas = nivel.get("oleadas", [])
	if not oleadas is Array or oleadas.is_empty():
		errores.append("el nivel no trae 'oleadas'")
		return errores
	for o in oleadas:
		var pool = o.get("pool", {})
		if not pool is Dictionary or pool.is_empty():
			errores.append("oleada '%s' sin pool" % str(o.get("id", "?")))
			continue
		if meta_oleada(o) > total_pool(pool):
			errores.append("oleada '%s': meta %d mayor que el pool (%d)" % [str(o.get("id", "?")), meta_oleada(o), total_pool(pool)])
	var perfiles = nivel.get("perfiles", {})
	for p in ["semilla", "brote", "estrella"]:
		if not perfiles is Dictionary or not perfiles.has(p):
			errores.append("falta el perfil '%s'" % p)
	return errores


static func _par(a, defecto: Vector2) -> Vector2:
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return defecto
