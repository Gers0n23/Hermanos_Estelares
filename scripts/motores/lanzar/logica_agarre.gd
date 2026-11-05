class_name LogicaAgarre
extends RefCounted

## Logica pura del motor `lanzar` (docs/fichas/motor-lanzar.md v4.1 §6.6, §8, §10, §11, §12 y §25). Sin nodos
## ni fisica: la usan el motor y los arneses. Todo es estatico y determinista.

const ORDEN_PERFILES := ["semilla", "brote", "estrella"]


## El siguiente valor >= n que es ≡ 1 (mod 4): 5, 9, 13, 17... (§8.1, regla v3 M4).
static func redondear_1_mod_4(n: int) -> int:
	var v := maxi(1, n)
	while v % 4 != 1:
		v += 1
	return v


static func es_1_mod_4(n: int) -> bool:
	return n > 0 and n % 4 == 1


## Canasta llena del intento: la base de la etapa y +extra desde la 1.a derrota DE LA ETAPA (§25.4). `ayuda_2`
## suma globos en la 2.a derrota cuando no hay gigante (revancha nicole+sofia, §11.1).
static func canasta_del_intento(base: int, extra_1: int, derrotas_etapa: int, extra_2: int = 0) -> int:
	var total := base
	if derrotas_etapa >= 1:
		total += extra_1
	if derrotas_etapa >= 2:
		total += extra_2
	return total


## El gigante reemplaza al primer globo de Maxi desde el 3.er intento de la etapa (= 2 derrotas, §10.3).
static func gigante_en_intento(derrotas_etapa: int, hay_semilla: bool) -> bool:
	return hay_semilla and derrotas_etapa >= 2


## Globos al retomar (§12 y §25.4): max(restantes, minimo), redondeado al siguiente ≡ 1 (mod 4) con Maxi, sin
## superar la canasta llena del intento en curso. Sin Maxi (nicole+sofia) solo el minimo y el tope.
static func globos_al_retomar(restantes: int, minimo: int, tope: int, con_semilla: bool = true) -> int:
	var n := maxi(restantes, minimo)
	if con_semilla:
		n = redondear_1_mod_4(n)
	return mini(n, maxi(tope, 1)) if tope > 0 else n


## Agarre conservado al reintentar (§10.2, v3 m2): max(1, round(factor x perdido)) si hubo botadas; 0 si no.
static func agarre_conservado(perdido: int, factor: float, hubo_botadas: bool, minimo: int = 1) -> int:
	if perdido <= 0 or not hubo_botadas:
		return 0
	return mini(perdido, maxi(minimo, roundi(factor * perdido)))


## Que piezas suben en el rearmado (§10.2): en el orden de `orden_reparacion`, mientras lo que queda botado siga
## >= `conservado`. Si se boto al menos una, al menos una queda en el suelo ("¡y algunas ya no suben!").
## `botadas` = ids botados en el intento (sin el trono); `pesos` = {id: peso_agarre}.
static func elegir_rearmado(botadas: Array, pesos: Dictionary, orden_reparacion: Array, conservado: int) -> Array:
	var restante := 0
	for id in botadas:
		restante += int(pesos.get(id, 0))
	var suben: Array = []
	for id in orden_reparacion:
		if not id in botadas:
			continue
		var p := int(pesos.get(id, 0))
		if restante - p >= conservado:
			suben.append(id)
			restante -= p
	if not botadas.is_empty() and suben.size() >= botadas.size():
		# La ultima de orden_reparacion se queda abajo.
		suben.pop_back()
	return suben


## Gag de la derrota n de la Torre (§10.1): 1, 2 y 3 fijos; desde la 4.a rotan los 4 sin repetir el anterior.
static func variante_gag(derrota_n: int, ultimo: String, variantes: Array, por_derrota: Array = [1, 2, 3]) -> String:
	if variantes.is_empty() or derrota_n <= 0:
		return ""
	if derrota_n <= por_derrota.size():
		var i := clampi(int(por_derrota[derrota_n - 1]) - 1, 0, variantes.size() - 1)
		return str(variantes[i])
	var previo := variantes.find(ultimo)
	return str(variantes[(previo + 1) % variantes.size()])


## Bono del tiro (§6.6 y §7.2): resbalon de Brote (>= 2 -> +1) y de Estrella (>= 3 -> +2) y golpe directo (+1),
## con el tope por tiro. Semilla nunca.
static func bono_tiro(perfil: String, peso_tiro: int, golpe_directo: bool, perfiles: Dictionary, agarre_cfg: Dictionary) -> int:
	if perfil == "semilla" or perfil == "":
		return 0
	var bono := 0
	var resbalon = perfiles.get(perfil, {}).get("resbalon", {})
	if resbalon is Dictionary and not resbalon.is_empty() and peso_tiro >= int(resbalon.get("derribo_min", 99)):
		bono += int(resbalon.get("bonus", 0))
	var golpe: Dictionary = agarre_cfg.get("golpe_directo", {})
	if golpe_directo and perfil in golpe.get("perfiles", []):
		bono += int(golpe.get("bonus", 1))
	return mini(bono, int(agarre_cfg.get("bonus_max_por_tiro", 3)))


## Tramo del logro comun (§10.1): 0 sin botadas, 1 bajo el corte, 2 desde el corte.
static func tramo_logro(botadas: int, total: int, corte: float) -> int:
	if botadas <= 0:
		return 0
	return 2 if float(botadas) >= corte * maxf(1.0, float(total)) else 1


## Estado de cara del Coleccionauta (0-3) segun la fraccion del agarre perdido (§6.6).
static func estado_cara(perdido: int, inicial: int, cortes: Array) -> int:
	var f := float(perdido) / maxf(1.0, float(inicial))
	var estado := 0
	for c in cortes:
		if f >= float(c):
			estado += 1
	return mini(estado, 3)


## Estrellitas de la revancha v4.1 (§25.15 y §25.18.7): 1 ganar; 2 sin perder ninguna etapa; 3 ademas con
## sobrante en cada etapa.
static func estrellitas_revancha(derrotas_revancha: int, con_sobrante_en_todas: bool) -> int:
	if derrotas_revancha > 0:
		return 1
	return 3 if con_sobrante_en_todas else 2


## Cuantos tiros le tocan a cada uno con `n` globos y el ciclo del gestor (empezando en el indice 0).
static func reparto(ciclo: Array, n: int) -> Dictionary:
	var cuenta := {}
	for k in n:
		var id := str(ciclo[k % ciclo.size()]) if not ciclo.is_empty() else ""
		cuenta[id] = int(cuenta.get(id, 0)) + 1
	return cuenta


# ---------------------------------------------------------------------------
# Geometria de la torre (rect = [x, y, ancho, alto], x,y = punto medio del borde inferior; §14)
# ---------------------------------------------------------------------------

static func rect_de(bloque: Dictionary) -> Rect2:
	var r: Array = bloque.get("rect", [0, 0, 0, 0])
	return Rect2(float(r[0]) - float(r[2]) / 2.0, float(r[1]) - float(r[3]), float(r[2]), float(r[3]))


## Grafo de apoyos (§6.2.3): B se apoya en A si el borde inferior de B esta a <= tol px del superior de A y se
## superponen >= sup (fraccion del mas angosto) en horizontal. Devuelve {id: [ids en los que se apoya]}; la
## plataforma es "plataforma".
static func apoyos(bloques: Array, plataforma: Dictionary, tol: float = 3.0, sup: float = 0.2) -> Dictionary:
	var resultado := {}
	var todos: Array = bloques.duplicate()
	if not plataforma.is_empty():
		var p := plataforma.duplicate()
		p["id"] = "plataforma"
		todos.append(p)
	for b in bloques:
		var rb := rect_de(b)
		var lista: Array = []
		for a in todos:
			if a == b:
				continue
			var ra := rect_de(a)
			if absf(rb.end.y - ra.position.y) > tol:
				continue
			var solape := minf(rb.end.x, ra.end.x) - maxf(rb.position.x, ra.position.x)
			if solape >= sup * minf(rb.size.x, ra.size.x):
				lista.append(str(a.get("id", "")))
		resultado[str(b.get("id", ""))] = lista
	return resultado


## Ids de la columna que sostiene al trono (directos y por debajo), sin la plataforma (G1/G2).
static func apoyos_del_trono(torre: Dictionary) -> Array:
	var bloques: Array = torre.get("bloques", []).duplicate()
	var trono: Dictionary = torre.get("trono", {})
	if trono.is_empty():
		return []
	bloques.append(trono)
	var grafo := apoyos(bloques, torre.get("plataforma", {}))
	var columna: Array = []
	var pendientes: Array = grafo.get(str(trono.get("id", "trono")), []).duplicate()
	while not pendientes.is_empty():
		var id := str(pendientes.pop_front())
		if id == "plataforma" or id in columna:
			continue
		columna.append(id)
		pendientes.append_array(grafo.get(id, []))
	return columna


## peso_botable (§25.2.1): suma de peso_agarre de las piezas de la etapa, sin trono ni bonos.
static func peso_botable(torre: Dictionary) -> int:
	var total := 0
	for b in torre.get("bloques", []):
		total += int(b.get("peso_agarre", 0))
	return total


## Validaciones al cargar (§14 y §25.8). Devuelve la lista de errores (vacia = OK); el motor los informa con
## push_error y sigue (nunca se cuelga).
static func validar_etapa(etapa: Dictionary, nivel: Dictionary) -> Array[String]:
	var errores: Array[String] = []
	var torre: Dictionary = etapa.get("torre", {})
	var bloques: Array = torre.get("bloques", [])
	var trono: Dictionary = torre.get("trono", {})
	var id_etapa := str(etapa.get("id", "?"))
	var materiales: Dictionary = nivel.get("materiales", {})
	var ids := {}
	for b in bloques:
		var id := str(b.get("id", ""))
		if ids.has(id):
			errores.append("%s: id repetido %s" % [id_etapa, id])
		ids[id] = b
		if not materiales.has(str(b.get("material", ""))):
			errores.append("%s: material desconocido en %s" % [id_etapa, id])
	if trono.is_empty():
		errores.append("%s: sin trono" % id_etapa)
	var max_cuerpos := int(nivel.get("mundo", {}).get("max_cuerpos", 40))
	if bloques.size() + 2 + 3 > max_cuerpos:
		errores.append("%s: %d cuerpos > %d" % [id_etapa, bloques.size() + 5, max_cuerpos])
	# Balance (§25.2.1).
	var factor := float(nivel.get("balance", {}).get("factor_min", 1.3))
	var agarre := int(etapa.get("agarre_inicial", 0))
	if float(peso_botable(torre)) < factor * agarre:
		errores.append("%s: peso_botable %d < %.1f x agarre %d" % [id_etapa, peso_botable(torre), factor, agarre])
	# G5: nada flota.
	var todos := bloques.duplicate()
	if not trono.is_empty():
		todos.append(trono)
	var grafo := apoyos(todos, torre.get("plataforma", {}))
	for id in grafo:
		if (grafo[id] as Array).is_empty():
			errores.append("%s: %s flota (G5)" % [id_etapa, id])
	# El trono es el mas alto.
	if not trono.is_empty():
		var cima_trono := rect_de(trono).position.y
		for b in bloques:
			if rect_de(b).position.y < cima_trono - 0.5:
				errores.append("%s: %s queda mas alto que el trono" % [id_etapa, str(b.get("id", ""))])
	# G1: la columna del trono, solo lata o carton.
	var columna := apoyos_del_trono(torre)
	for id in columna:
		var mat := str(ids.get(id, {}).get("material", ""))
		if mat != "lata" and mat != "carton":
			errores.append("%s: el trono se apoya en %s (%s) (G1)" % [id_etapa, id, mat])
	# G2: Maxi nunca apunta a la columna del trono ni a un resorte.
	var pd: Dictionary = torre.get("puntos_debiles", {})
	for clave in ["semilla", "semilla_respaldo"]:
		for id in pd.get(clave, []):
			if not ids.has(str(id)):
				errores.append("%s: %s de %s no existe" % [id_etapa, id, clave])
			elif str(id) in columna or str(ids[str(id)].get("material", "")) == "resorte":
				errores.append("%s: %s en %s es apoyo del trono o resorte (G2)" % [id_etapa, id, clave])
	for clave in ["gigante_objetivo"]:
		for id in pd.get(clave, []):
			if not ids.has(str(id)):
				errores.append("%s: %s de %s no existe" % [id_etapa, id, clave])
	for clave in ["brote", "estrella"]:
		var bloque_pd = pd.get(clave, {})
		for id in (bloque_pd.get("ids", []) if bloque_pd is Dictionary else []):
			if not ids.has(str(id)):
				errores.append("%s: %s de %s no existe" % [id_etapa, id, clave])
	for id in torre.get("orden_reparacion", []):
		if not ids.has(str(id)):
			errores.append("%s: %s de orden_reparacion no existe" % [id_etapa, id])
	return errores


## Validaciones comunes del nivel (§14 y §25.8): reparto ≡ 1 (mod 4) con Maxi, gags, carga y bandejas.
static func validar_nivel(nivel: Dictionary) -> Array[String]:
	var errores: Array[String] = []
	var intentos: Dictionary = nivel.get("intentos", {})
	var base := int(intentos.get("globos_base", 13))
	var extra := 0
	for ayuda in intentos.get("ayudas", []):
		extra += int(ayuda.get("globos_extra", 0))
	if not es_1_mod_4(base) or not es_1_mod_4(base + extra):
		errores.append("globos_base %d / %d no son ≡ 1 (mod 4)" % [base, base + extra])
	var comps = nivel.get("equipo", {}).get("composiciones", {})
	if comps is Dictionary:
		for clave in comps:
			var c: Dictionary = comps[clave]
			if not c.has("globos_base"):
				continue
			var b := int(c["globos_base"])
			var e := int(c.get("globos_extra_1", 4))
			if "maxi" in str(clave) and not (es_1_mod_4(b) or (b % 2 == 1 and str(clave).count("+") == 1)):
				errores.append("composicion %s: %d impar/≡ 1 (mod 4) requerido" % [clave, b])
			if not "maxi" in str(clave) and (b % 2 != 0 or (b + e) % 2 != 0):
				errores.append("composicion %s: sin Maxi los globos deben ser pares" % clave)
	if (intentos.get("variantes_gag", []) as Array).size() != 4:
		errores.append("variantes_gag debe tener 4 entradas")
	var carga = nivel.get("lineas_voz", {}).get("carga", {})
	for color in nivel.get("colores_globos", []):
		if not (carga is Dictionary and carga.has(color)):
			errores.append("lineas_voz.carga sin %s" % color)
	# Bandejas fuera del circulo de agarre de su perfil, a >= 24 px.
	var res: Dictionary = nivel.get("resortera", {})
	var bolsa_a: Array = res.get("bolsa_reposo", [260, 430])
	var bolsa := Vector2(float(bolsa_a[0]), float(bolsa_a[1]))
	for perfil in ["brote", "estrella"]:
		var r = nivel.get("perfiles", {}).get(perfil, {}).get("bandeja", [])
		if not r is Array or r.size() != 4:
			continue
		var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		var radio := radio_agarre(res, perfil)
		var cercano := Vector2(clampf(bolsa.x, rect.position.x, rect.end.x), clampf(bolsa.y, rect.position.y, rect.end.y))
		if cercano.distance_to(bolsa) < radio + 24.0:
			errores.append("bandeja de %s a menos de 24 px del circulo de agarre" % perfil)
	return errores


static func radio_agarre(resortera: Dictionary, perfil: String) -> float:
	var r = resortera.get("radio_agarre_px", 120)
	if r is Dictionary:
		return float(r.get(perfil, 120))
	return float(r)
