class_name LogicaTopos
extends RefCounted

## Reglas de «¿Quién habla?» (motor `topos`, tipo Whac-a-Mole; docs/fichas/motor-topos.md §5, §6, §8 y §9).
## Sin pantalla y determinista con semilla (patrón de `LogicaRio`): el motor solo dibuja, escucha la entrada y
## arma el flujo de rondas, gags y celebraciones. El arnés `herramientas/qa_test_topos.gd` la prueba sola.
##
## Cada madriguera es un Dictionary con su animal y su estado:
##   abajo -> aviso (tierrita) -> subiendo (0,12 s) -> arriba -> bajando (0,15 s) | saltando (acierto, 0,35 s)
## Dos modos (§5): `tandas` (suben `asomados` a la vez, uno es el pedido; se resuelve y vuelve a empezar) y
## `continuo` (cada uno sube y baja a su ritmo, entre `asomados_min` y `asomados_max`; cada
## `intervalo_pedido_s` habla uno de los que están arriba y les queda al menos el 60 % de su tiempo).
##
## Política de derrota del PO (HE-124, 05-Nov-2026): todos los perfiles pueden perder. Aquí solo se cuenta:
## la ronda termina con el sol (`duracion_s`) y se gana con `meta` aciertos; si la meta se llena antes, se
## sigue jugando hasta el final (§5.3). Sin reloj (ayuda fuerte de Semilla, `pedidos`) se gana en el instante
## en que se llena (`gana_al_llenar`). Nada resta puntaje: un error o un escape solo cortan la racha. En
## Semilla tocar al equivocado no es fallo y el escape es lento, con saludo (§5.1 paso 5, §10.1).

signal aviso(id: int)
## tipo: "pedido" | "senuelo" | "dorado" | "impostor"
signal asomo(id: int, id_animal: String, tipo: String)
## El pedido habló. `escrito` != "" = pedido escrito (palabra o letra): no suena el animal, se muestra el cartel.
## `repite` = repetición del mismo pedido (Semilla cada 3 s, Brote una vez, ayuda de Semilla).
signal sono(id: int, id_animal: String, escrito: String, repite: bool)
signal acierto(id: int, puntos: int, racha: int, rapidito: bool)
## En Semilla el error es "suave de verdad": el señuelo celebra y se queda arriba, el pedido vuelve a llamar.
signal error(id: int, id_animal: String)
signal vacia(id: int)
signal escape(id: int, id_animal: String)
signal bajo(id: int)
signal dorado_tocado(id: int, puntos: int)
signal impostor_tocado(id: int)
signal doble_completo(puntos: int)
signal meta_llena()
## Semilla quieto (§8.1): nivel 1 = el pedido salta y vuelve a sonar; nivel 2 = mano fantasma.
signal ayuda(nivel: int, id: int)
signal ronda_terminada(gano: bool, puntaje: int)

const T_SUBIR := 0.12
const T_BAJAR := 0.15
const T_BAJAR_ERROR := 0.2
const T_SALTO := 0.35
const T_REPETIR_SEMILLA := 3.0
const T_AVISO_PISTA := 0.4
const SEPARACION_DOBLE := 0.4
const FRACCION_MIN_PEDIDO := 0.6
const T_DORADO_MIN := 1.6
## Semilla: el animal saluda con la patita antes de bajar (0,3 s) y baja despacio.
const T_ESCAPE_SEMILLA := 0.45

# --- Configuración (del nivel) ---
var perfil := "brote"
var modo := "tandas"
var n_madrigueras := 4
var asomados := 3
var asomados_min := 2
var asomados_max := 4
var intervalo_pedido := 1.4
## <= 0 = sin límite (Semilla: el animal espera).
var t_arriba := 2.6
var variacion := 0.25
var aviso_s := 0.15
var pausa := 0.7
## <= 0 = sin reloj (modo equipo: el turno se mide en pedidos).
var duracion := 60.0
## 0 = sin meta (modo equipo).
var meta := 12
var gana_al_llenar := false
var repetir := "no"
var animales: Array[String] = []
## id -> {"inicial": "V", "palabra": "VACA"}
var info: Dictionary = {}
var similares: Array = []
var p_similar := 0.0
var p_escrito := 0.0
var tipo_escrito := "palabra"
var p_doble := 0.0
var separacion_doble := SEPARACION_DOBLE
var dorado_cada := 0.0
var dorado_puntos := 300
var dorado_una_vez := false
var impostor_cada := 0.0
var sorpresa := ""
var pts_acierto := 100
var racha_max := 5
var pts_rapidito := 50
var fraccion_rapidito := 0.4
var pts_doble := 200
var pts_meta := 500
var ayuda_idle: Array = [3.0, 5.0]
## Pedidos que todavía llevan la pista de Sofía (la madriguera brilla antes de subir).
var pista_restante := 0

# --- Estado ---
var rng := RandomNumberGenerator.new()
var madrigueras: Array = []
var estado := "esperando"  ## esperando | jugando | terminada
var gano := false
## En equipo: sin turno activo no empieza ningún pedido (pase, puerta, gag).
var pausada := false
var tiempo := 0.0
var aciertos := 0
var puntaje := 0
var racha := 0
var errores := 0
var escapes := 0
var meta_alcanzada := false
var pedidos_hechos := 0
var ultimo_pedido := ""
var stats := {"pedidos": 0, "similares": 0, "escritos": 0, "dobles": 0, "dorados": 0, "impostores": 0}
var _fase := "pausa"  ## tandas: pausa | arriba
var _t_fase := 0.0
var _t_quieto := 0.0
var _ayuda_dada := 0
var _t_dorado := 0.0
var _t_impostor := 0.0
var _t_pedido := 0.0
var _t_spawn := 0.0
var _sorpresa_en := -1
var _dorado_en := -1
var _primera_tanda := true
## grupo de pedido -> [aciertos, tamaño] (pedido doble).
var _grupo_aciertos := {}
var _grupo_tamano := {}


func configurar(nivel: Dictionary, semilla: int = -1) -> void:
	if semilla >= 0:
		rng.seed = semilla
	else:
		rng.randomize()
	perfil = str(nivel.get("perfil", "brote"))
	modo = str(nivel.get("modo", "tandas"))
	n_madrigueras = int(nivel.get("madrigueras", 4))
	if not n_madrigueras in [3, 4, 6, 9]:
		push_warning("LogicaTopos: madrigueras %d no tiene disposicion; uso 4" % n_madrigueras)
		n_madrigueras = 4
	asomados = int(nivel.get("asomados", 3))
	asomados_min = int(nivel.get("asomados_min", 2))
	asomados_max = int(nivel.get("asomados_max", 4))
	intervalo_pedido = float(nivel.get("intervalo_pedido_s", 1.4))
	t_arriba = _num(nivel.get("t_arriba_s", 2.6), 0.0)
	variacion = float(nivel.get("variacion_t_arriba", 0.25))
	aviso_s = float(nivel.get("aviso_s", 0.15))
	pausa = float(nivel.get("pausa_entre_pedidos", 0.7))
	duracion = _num(nivel.get("duracion_s", 60.0), 0.0)
	meta = int(_num(nivel.get("meta", 0), 0.0))
	# Sin reloj (`duracion_s: null`, ayuda fuerte de Semilla) se juega por cantidad: `pedidos` aciertos y gana.
	if duracion <= 0.0 and nivel.get("pedidos", null) != null:
		meta = int(nivel["pedidos"])
	gana_al_llenar = bool(nivel.get("gana_al_llenar", duracion <= 0.0 and meta > 0))
	repetir = str(nivel.get("repetir_sonido", "no"))
	animales.clear()
	info.clear()
	for a in nivel.get("animales", []):
		var id := str(a.get("id", "")) if a is Dictionary else str(a)
		if id == "" or id in animales:
			continue
		animales.append(id)
		if a is Dictionary:
			info[id] = {"inicial": str(a.get("inicial", "")), "palabra": str(a.get("palabra", ""))}
		else:
			info[id] = {"inicial": "", "palabra": ""}
	similares = nivel.get("similares", []) if nivel.get("similares", []) is Array else []
	p_similar = float(nivel.get("p_similar", 0.0))
	var escrito = nivel.get("pedido_escrito", {})
	p_escrito = float(escrito.get("p", 0.0)) if escrito is Dictionary else 0.0
	tipo_escrito = str(escrito.get("tipo", "palabra")) if escrito is Dictionary else "palabra"
	var doble = nivel.get("pedido_doble", {})
	p_doble = float(doble.get("p", 0.0)) if doble is Dictionary else 0.0
	separacion_doble = float(doble.get("separacion_s", SEPARACION_DOBLE)) if doble is Dictionary else SEPARACION_DOBLE
	var dorado = nivel.get("toby_dorado", null)
	dorado_cada = 0.0
	dorado_una_vez = false
	if dorado is Dictionary:
		dorado_puntos = int(dorado.get("puntos", 300))
		if str(dorado.get("cada_s", "")) == "una_vez" or bool(dorado.get("una_vez", false)):
			dorado_una_vez = true
		else:
			dorado_cada = float(dorado.get("cada_s", 15))
	var impostor = nivel.get("impostor", null)
	impostor_cada = float(impostor.get("cada_s", 15)) if impostor is Dictionary else 0.0
	var sorpresa_cfg = nivel.get("sorpresa", null)
	sorpresa = str(sorpresa_cfg.get("id", "")) if sorpresa_cfg is Dictionary else ""
	var pts = nivel.get("puntos", {})
	if pts is Dictionary:
		pts_acierto = int(pts.get("acierto", 100))
		racha_max = int(pts.get("racha_max", 5))
		pts_rapidito = int(pts.get("rapidito", 50))
		fraccion_rapidito = float(pts.get("rapidito_fraccion", 0.4))
		pts_doble = int(pts.get("doble", 200))
		pts_meta = int(pts.get("meta", 500))
	var idle = nivel.get("ayuda_idle_s", [3, 5])
	ayuda_idle = [float(idle[0]), float(idle[1])] if idle is Array and idle.size() >= 2 else [3.0, 5.0]
	_validar()
	_crear_madrigueras()


func _num(valor, por_defecto: float) -> float:
	return por_defecto if valor == null else float(valor)


## §11: validación al cargar, con aviso y valor por defecto.
func _validar() -> void:
	var pool := _pool()
	if asomados > n_madrigueras:
		push_warning("LogicaTopos: asomados %d > madrigueras %d" % [asomados, n_madrigueras])
		asomados = n_madrigueras
	if asomados > pool.size():
		push_warning("LogicaTopos: el pool tiene %d animales y asoman %d" % [pool.size(), asomados])
		asomados = maxi(1, pool.size())
	asomados = maxi(1, asomados)
	asomados_max = clampi(asomados_max, 1, mini(n_madrigueras, pool.size()))
	asomados_min = clampi(asomados_min, 1, asomados_max)


func _crear_madrigueras() -> void:
	madrigueras.clear()
	for i in n_madrigueras:
		madrigueras.append(_madriguera_vacia(i))


func _madriguera_vacia(i: int) -> Dictionary:
	return {"id": i, "animal": "", "tipo": "", "estado": "abajo", "t": 0.0, "dur": 0.0, "t_up": 0.0,
		"pedido": false, "sono": false, "t_sono": 0.0, "retraso": 0.0, "tocado": false, "escapando": false,
		"escrito": "", "t_rep": 0.0, "repitio": false, "aviso_dur": 0.0, "brilla": false, "grupo": 0,
		"oreja": false}


## Aplica la capa de un perfil (modo equipo, `aplicar_perfil_turno`): solo los campos presentes.
func aplicar_perfil(capa: Dictionary) -> void:
	if capa.has("perfil"):
		perfil = str(capa["perfil"])
	if capa.has("t_arriba_s"):
		t_arriba = _num(capa["t_arriba_s"], 0.0)
	if capa.has("asomados"):
		asomados = int(capa["asomados"])
	if capa.has("repetir_sonido"):
		repetir = str(capa["repetir_sonido"])
	if capa.has("pausa_entre_pedidos"):
		pausa = float(capa["pausa_entre_pedidos"])
	if capa.has("aviso_s"):
		aviso_s = float(capa["aviso_s"])
	if capa.has("p_similar"):
		p_similar = float(capa["p_similar"])
	_validar()


## Ronda nueva desde cero (también el reintento: nada guardado se toca).
func empezar() -> void:
	_crear_madrigueras()
	estado = "jugando"
	gano = false
	tiempo = 0.0
	aciertos = 0
	puntaje = 0
	racha = 0
	errores = 0
	escapes = 0
	meta_alcanzada = false
	pedidos_hechos = 0
	ultimo_pedido = ""
	_fase = "pausa"
	_t_fase = pausa * 0.5
	_t_quieto = 0.0
	_ayuda_dada = 0
	_t_dorado = 0.0
	_t_impostor = 0.0
	_t_pedido = intervalo_pedido * 0.6
	_t_spawn = 0.0
	_primera_tanda = true
	_grupo_aciertos.clear()
	_grupo_tamano.clear()
	var total := maxi(meta, 6)
	_sorpresa_en = rng.randi_range(1, maxi(1, total / 2)) if sorpresa != "" else -1
	_dorado_en = rng.randi_range(2, maxi(2, total - 2)) if dorado_una_vez else -1


# ---------------------------------------------------------------------------
# Paso de simulación
# ---------------------------------------------------------------------------

func avanzar(delta: float) -> void:
	_animar(delta)
	if estado != "jugando" or pausada:
		return
	if duracion > 0.0:
		tiempo += delta
		if tiempo >= duracion:
			_terminar(meta <= 0 or aciertos >= meta)
			return
	if modo == "continuo":
		_paso_continuo(delta)
	else:
		_paso_tandas(delta)
	_paso_quieto(delta)


func fraccion_tiempo() -> float:
	return clampf(tiempo / duracion, 0.0, 1.0) if duracion > 0.0 else 0.0


func _animar(delta: float) -> void:
	var jugando := estado == "jugando"
	for m in madrigueras:
		match m["estado"]:
			"abajo":
				pass
			"aviso":
				m["t"] += delta
				if m["t"] >= m["aviso_dur"]:
					m["estado"] = "subiendo"
					m["t"] = 0.0
					asomo.emit(m["id"], m["animal"], m["tipo"] if not m["pedido"] else "pedido")
			"subiendo":
				m["t"] += delta
				if m["t"] >= T_SUBIR:
					m["estado"] = "arriba"
					m["t"] = 0.0
					m["t_up"] = 0.0
			"arriba":
				m["t"] += delta
				if jugando and not pausada:
					m["t_up"] += delta
					_arriba(m)
			"bajando":
				m["t"] += delta
				if m["t"] >= m["dur_bajar"]:
					var era: String = m["animal"]
					var id: int = m["id"]
					# Pedido doble: si el otro del grupo ya se tocó, el que se escapa no corta la racha.
					var escapo: bool = m["escapando"] and int(_grupo_aciertos.get(m["grupo"], 0)) == 0
					madrigueras[id] = _madriguera_vacia(id)
					if escapo and jugando:
						_contar_escape(id, era)
					bajo.emit(id)
			"saltando":
				m["t"] += delta
				if m["t"] >= T_SALTO:
					var id2: int = m["id"]
					madrigueras[id2] = _madriguera_vacia(id2)
					bajo.emit(id2)


func _arriba(m: Dictionary) -> void:
	if m["pedido"] and not m["tocado"]:
		if not m["sono"] and m["t_up"] >= m["retraso"]:
			_sonar(m, false)
		elif m["sono"]:
			if repetir == "cada_3s" and m["t_up"] - m["t_rep"] >= T_REPETIR_SEMILLA:
				_sonar(m, true)
			elif repetir == "una_vez" and not m["repitio"] and m["dur"] > 0.0 and m["t_up"] - m["t_sono"] >= (m["dur"] - m["t_sono"]) * 0.5:
				m["repitio"] = true
				_sonar(m, true)
	if m["dur"] > 0.0 and m["t_up"] >= m["dur"]:
		var escapa: bool = m["pedido"] and not m["tocado"]
		_bajar(m, T_ESCAPE_SEMILLA if escapa and perfil == "semilla" else T_BAJAR, escapa)


func _sonar(m: Dictionary, repite: bool) -> void:
	if not repite:
		m["t_sono"] = m["t_up"]
		_t_quieto = 0.0
		_ayuda_dada = 0
	m["sono"] = true
	m["t_rep"] = m["t_up"]
	sono.emit(m["id"], m["animal"], m["escrito"], repite)


func _bajar(m: Dictionary, segundos: float, escapando := false) -> void:
	m["estado"] = "bajando"
	m["t"] = 0.0
	m["dur_bajar"] = segundos
	m["escapando"] = escapando


func _contar_escape(id: int, id_animal: String) -> void:
	escapes += 1
	racha = 0 if perfil != "semilla" else racha
	escape.emit(id, id_animal)


func _terminar(gano_ronda: bool) -> void:
	if estado != "jugando":
		return
	estado = "terminada"
	gano = gano_ronda
	ronda_terminada.emit(gano, puntaje)


# ---------------------------------------------------------------------------
# Modo tandas (§5.1)
# ---------------------------------------------------------------------------

func _paso_tandas(delta: float) -> void:
	_t_dorado += delta
	if _fase == "arriba":
		if _tanda_resuelta():
			for m in madrigueras:
				if m["estado"] in ["aviso", "subiendo", "arriba"] and not m["tocado"]:
					if m["estado"] == "aviso":
						madrigueras[m["id"]] = _madriguera_vacia(m["id"])
					else:
						_bajar(m, T_BAJAR)
			_fase = "pausa"
			_t_fase = 0.0
		return
	_t_fase += delta
	if _t_fase < pausa:
		return
	if not _empezar_tanda():
		return
	_fase = "arriba"


## Resuelta = ningún pedido sigue pendiente (todos tocados, escapados o bajando).
func _tanda_resuelta() -> bool:
	for m in madrigueras:
		if m["pedido"] and not m["tocado"] and m["estado"] in ["aviso", "subiendo", "arriba"]:
			return false
	return true


func _libres() -> Array:
	var r: Array = []
	for m in madrigueras:
		if m["estado"] == "abajo":
			r.append(m["id"])
	return r


func _pool() -> Array:
	return animales.filter(func(a: String) -> bool: return a != sorpresa)


func _pareja_de(id: String) -> Array:
	var r: Array = []
	for par in similares:
		if par is Array and par.size() == 2:
			if str(par[0]) == id:
				r.append(str(par[1]))
			elif str(par[1]) == id:
				r.append(str(par[0]))
	return r


func _escrito_de(id: String) -> String:
	var d: Dictionary = info.get(id, {})
	return str(d.get("inicial" if tipo_escrito == "letra" else "palabra", ""))


## Elige el contenido de una tanda y abre las madrigueras. Devuelve false si todavía no hay lugar.
func _empezar_tanda() -> bool:
	var libres := _libres()
	var pool := _pool()
	var cuantos := asomados
	if libres.size() < cuantos:
		return false
	var candidatos: Array = pool.filter(func(a: String) -> bool: return a != ultimo_pedido)
	if candidatos.is_empty():
		candidatos = pool.duplicate()
	var pedidos: Array = []
	var escrito := ""
	# Sorpresa (Maxi z3: el triceratops asoma una vez por ronda como pedido).
	if sorpresa != "" and pedidos_hechos == _sorpresa_en:
		pedidos.append(sorpresa)
	var usar_similar := p_similar > 0.0 and rng.randf() < p_similar
	var es_escrito := p_escrito > 0.0 and rng.randf() < p_escrito
	if pedidos.is_empty():
		var base := candidatos
		if usar_similar:
			var con_pareja: Array = base.filter(func(a: String) -> bool:
				return _pareja_de(a).any(func(b: String) -> bool: return b in pool))
			if con_pareja.is_empty():
				usar_similar = false
			else:
				base = con_pareja
		if es_escrito:
			var con_texto: Array = base.filter(func(a: String) -> bool: return _escrito_de(a) != "")
			if con_texto.is_empty():
				es_escrito = false
			else:
				base = con_texto
		pedidos.append(base[rng.randi_range(0, base.size() - 1)])
	else:
		usar_similar = false
		es_escrito = false
	if es_escrito:
		escrito = _escrito_de(pedidos[0])
	var es_doble := not es_escrito and p_doble > 0.0 and cuantos >= 3 and rng.randf() < p_doble
	if es_doble:
		var otros: Array = pool.filter(func(a: String) -> bool: return not a in pedidos and not a in _pareja_de(pedidos[0]))
		if otros.is_empty():
			es_doble = false
		else:
			pedidos.append(otros[rng.randi_range(0, otros.size() - 1)])
	var senuelos := _elegir_senuelos(pedidos, cuantos - pedidos.size(), usar_similar, escrito)
	var contenido: Array = []
	for p in pedidos:
		contenido.append({"animal": p, "tipo": "pedido"})
	for s in senuelos:
		contenido.append({"animal": s, "tipo": "senuelo"})
	# Toby dorado (§8.4): en Semilla una vez por ronda; en Brote y Estrella cada `cada_s` si hay lugar.
	var con_dorado := false
	if dorado_una_vez and pedidos_hechos == _dorado_en:
		con_dorado = true
	elif dorado_cada > 0.0 and _t_dorado >= dorado_cada and not _primera_tanda:
		con_dorado = true
	if con_dorado and libres.size() > contenido.size():
		contenido.append({"animal": "toby_dorado", "tipo": "dorado"})
		_t_dorado = rng.randf_range(-2.0, 2.0)
		stats["dorados"] += 1
	_primera_tanda = false
	_barajar(libres)
	var pista := pista_restante > 0
	if pista:
		pista_restante -= 1
	for k in contenido.size():
		var m: Dictionary = madrigueras[libres[k]]
		var c: Dictionary = contenido[k]
		m["animal"] = c["animal"]
		m["tipo"] = c["tipo"]
		m["pedido"] = c["tipo"] == "pedido"
		m["estado"] = "aviso"
		m["t"] = 0.0
		m["aviso_dur"] = T_AVISO_PISTA if pista and m["pedido"] else aviso_s
		m["brilla"] = pista and m["pedido"]
		m["dur"] = t_arriba if m["pedido"] and t_arriba > 0.0 else -1.0
		if c["tipo"] == "dorado":
			m["dur"] = maxf(t_arriba, T_DORADO_MIN) if t_arriba > 0.0 else -1.0
		m["escrito"] = escrito if m["pedido"] and pedidos.find(c["animal"]) == 0 else ""
		var orden := pedidos.find(c["animal"]) if m["pedido"] else -1
		m["retraso"] = separacion_doble * orden if orden > 0 else 0.0
		if orden > 0 and m["dur"] > 0.0:
			m["dur"] += m["retraso"]
		m["grupo"] = pedidos_hechos
		aviso.emit(m["id"])
	ultimo_pedido = pedidos[0]
	_grupo_tamano[pedidos_hechos] = pedidos.size()
	pedidos_hechos += 1
	stats["pedidos"] += 1
	if usar_similar:
		stats["similares"] += 1
	if escrito != "":
		stats["escritos"] += 1
	if pedidos.size() > 1:
		stats["dobles"] += 1
	return true


## Señuelos distintos entre sí y del pedido. Con `usar_similar`, el primero es la pareja parecida; si no, se
## evitan las parejas. Con pedido de letra, ninguno empieza con la misma letra.
func _elegir_senuelos(pedidos: Array, cuantos: int, usar_similar: bool, escrito: String) -> Array:
	var pool := _pool()
	var elegidos: Array = []
	var parejas: Array = []
	for p in pedidos:
		parejas.append_array(_pareja_de(p))
	if usar_similar:
		var opciones: Array = parejas.filter(func(a: String) -> bool: return a in pool and not a in pedidos)
		if not opciones.is_empty() and cuantos > 0:
			elegidos.append(opciones[rng.randi_range(0, opciones.size() - 1)])
	var resto: Array = pool.filter(func(a: String) -> bool:
		if a in pedidos or a in elegidos or a in parejas:
			return false
		if escrito != "" and tipo_escrito == "letra" and str(info.get(a, {}).get("inicial", "")) == escrito:
			return false
		return true)
	_barajar(resto)
	while elegidos.size() < cuantos and not resto.is_empty():
		elegidos.append(resto.pop_back())
	# Pool chico: se relaja la regla de las parejas (nunca la de "distintos").
	if elegidos.size() < cuantos:
		var extra: Array = pool.filter(func(a: String) -> bool: return not a in pedidos and not a in elegidos)
		_barajar(extra)
		while elegidos.size() < cuantos and not extra.is_empty():
			elegidos.append(extra.pop_back())
	return elegidos


func _barajar(lista: Array) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp


# ---------------------------------------------------------------------------
# Modo continuo (§5.2)
# ---------------------------------------------------------------------------

func activos() -> int:
	var n := 0
	for m in madrigueras:
		if m["estado"] in ["aviso", "subiendo", "arriba"]:
			n += 1
	return n


func _hay_pedido_activo() -> bool:
	for m in madrigueras:
		if m["pedido"] and not m["tocado"] and m["estado"] in ["aviso", "subiendo", "arriba"]:
			return true
	return false


func _paso_continuo(delta: float) -> void:
	_t_spawn -= delta
	_t_pedido += delta
	_t_dorado += delta
	_t_impostor += delta
	var n := activos()
	var libres := _libres()
	if not libres.is_empty():
		if impostor_cada > 0.0 and _t_impostor >= impostor_cada and n < asomados_max:
			_asomar_continuo(libres, "impostor")
			_t_impostor = rng.randf_range(-2.0, 2.0)
		elif dorado_cada > 0.0 and _t_dorado >= dorado_cada and n < asomados_max:
			_asomar_continuo(libres, "dorado")
			_t_dorado = rng.randf_range(-2.0, 2.0)
		elif n < asomados_min or (n < asomados_max and _t_spawn <= 0.0):
			_asomar_continuo(libres, "senuelo")
			_t_spawn = rng.randf_range(0.2, 0.55)
	if _t_pedido >= intervalo_pedido and not _hay_pedido_activo():
		if _elegir_pedido_continuo():
			_t_pedido = 0.0


func _asomar_continuo(libres: Array, tipo: String) -> void:
	var id: int = libres[rng.randi_range(0, libres.size() - 1)]
	var m: Dictionary = madrigueras[id]
	var en_uso: Array = []
	for o in madrigueras:
		if o["estado"] != "abajo" and o["tipo"] in ["senuelo", "pedido"]:
			en_uso.append(o["animal"])
	var animal := ""
	if tipo == "dorado":
		animal = "toby_dorado"
		stats["dorados"] += 1
	elif tipo == "impostor":
		# El disfraz es de un animal que NO está sonando (§8.4).
		var disfraces: Array = _pool().filter(func(a: String) -> bool: return not a in en_uso)
		animal = disfraces[rng.randi_range(0, disfraces.size() - 1)] if not disfraces.is_empty() else _pool()[0]
		stats["impostores"] += 1
	else:
		var opciones: Array = _pool().filter(func(a: String) -> bool: return not a in en_uso)
		if opciones.is_empty():
			return
		# Las parejas parecidas solo comparten claro con probabilidad p_similar.
		var sin_pareja: Array = opciones.filter(func(a: String) -> bool:
			return not _pareja_de(a).any(func(b: String) -> bool: return b in en_uso))
		if not sin_pareja.is_empty() and not (p_similar > 0.0 and rng.randf() < p_similar):
			opciones = sin_pareja
		animal = opciones[rng.randi_range(0, opciones.size() - 1)]
	m["animal"] = animal
	m["tipo"] = tipo
	m["pedido"] = false
	m["estado"] = "aviso"
	m["t"] = 0.0
	m["aviso_dur"] = aviso_s
	m["dur"] = t_arriba * (1.0 + rng.randf_range(-variacion, variacion))
	if tipo == "dorado":
		m["dur"] = maxf(m["dur"], T_DORADO_MIN)
	aviso.emit(id)


## Habla uno de los que están arriba con >= 60 % de su tiempo por delante (o dos, en el pedido doble).
func _elegir_pedido_continuo() -> bool:
	var elegibles: Array = []
	for m in madrigueras:
		if m["estado"] == "arriba" and m["tipo"] == "senuelo" and not m["tocado"] and m["animal"] != ultimo_pedido \
				and m["dur"] - m["t_up"] >= FRACCION_MIN_PEDIDO * m["dur"]:
			elegibles.append(m)
	if elegibles.is_empty():
		return false
	var es_escrito := p_escrito > 0.0 and rng.randf() < p_escrito
	var base := elegibles
	if es_escrito:
		var con_texto: Array = elegibles.filter(func(m: Dictionary) -> bool: return _escrito_de(m["animal"]) != "")
		if con_texto.is_empty():
			es_escrito = false
		else:
			base = con_texto
	var primero: Dictionary = base[rng.randi_range(0, base.size() - 1)]
	var grupo: Array = [primero]
	if not es_escrito and p_doble > 0.0 and elegibles.size() >= 2 and rng.randf() < p_doble:
		var resto: Array = elegibles.filter(func(m: Dictionary) -> bool: return m != primero)
		grupo.append(resto[rng.randi_range(0, resto.size() - 1)])
	var pista := pista_restante > 0
	if pista:
		pista_restante -= 1
	for k in grupo.size():
		var m: Dictionary = grupo[k]
		m["pedido"] = true
		m["tipo"] = "pedido"
		m["grupo"] = pedidos_hechos
		m["brilla"] = pista
		m["escrito"] = _escrito_de(m["animal"]) if es_escrito and k == 0 else ""
		m["retraso"] = m["t_up"] + separacion_doble * k
		if k > 0:
			m["dur"] = maxf(m["dur"], m["retraso"] + FRACCION_MIN_PEDIDO * t_arriba)
		if k == 0:
			_sonar(m, false)
	ultimo_pedido = primero["animal"]
	_grupo_tamano[pedidos_hechos] = grupo.size()
	pedidos_hechos += 1
	stats["pedidos"] += 1
	if es_escrito:
		stats["escritos"] += 1
	if grupo.size() > 1:
		stats["dobles"] += 1
	return true


# ---------------------------------------------------------------------------
# Ayuda de Semilla cuando se queda quieto (§8.1)
# ---------------------------------------------------------------------------

func _paso_quieto(delta: float) -> void:
	if perfil != "semilla":
		return
	var pedido := _pedido_sonando()
	if pedido.is_empty():
		return
	_t_quieto += delta
	if _ayuda_dada == 0 and _t_quieto >= float(ayuda_idle[0]):
		_ayuda_dada = 1
		ayuda.emit(1, pedido["id"])
		_sonar(pedido, true)
	elif _ayuda_dada == 1 and _t_quieto >= float(ayuda_idle[1]):
		_ayuda_dada = 2
		ayuda.emit(2, pedido["id"])


func _pedido_sonando() -> Dictionary:
	for m in madrigueras:
		if m["pedido"] and not m["tocado"] and m["estado"] == "arriba" and m["sono"]:
			return m
	return {}


## Madriguera del pedido que espera ser tocado (-1 si no hay): para la mano fantasma, la ayuda y los arneses.
func id_pedido() -> int:
	for m in madrigueras:
		if m["pedido"] and not m["tocado"] and m["estado"] in ["subiendo", "arriba"]:
			return m["id"]
	return -1


# ---------------------------------------------------------------------------
# Toques (§6)
# ---------------------------------------------------------------------------

## Devuelve "acierto" | "error" | "vacia" | "dorado" | "impostor" | "ignorado".
func tocar(id: int) -> String:
	if id < 0 or id >= madrigueras.size() or estado != "jugando" or pausada:
		return "ignorado"
	_t_quieto = 0.0
	var m: Dictionary = madrigueras[id]
	if m["tocado"]:
		return "ignorado"
	match m["estado"]:
		"abajo", "aviso":
			vacia.emit(id)
			return "vacia"
		"saltando":
			return "ignorado"
		"bajando":
			# Un toque en la bajada del pedido todavía vale (el ojo del niño lo vio arriba).
			if m["pedido"] and m["escapando"]:
				m["escapando"] = false
				return _acertar(m)
			return "ignorado"
	# subiendo o arriba
	match m["tipo"]:
		"pedido":
			if not m["sono"]:
				# Tocar "justo cuando sale" vale (§4): el pedido cuenta aunque no haya terminado de hablar.
				m["t_sono"] = m["t_up"]
			return _acertar(m)
		"dorado":
			m["tocado"] = true
			m["estado"] = "saltando"
			m["t"] = 0.0
			var pts := dorado_puntos if perfil != "semilla" else 0
			puntaje += pts
			dorado_tocado.emit(id, pts)
			return "dorado"
		"impostor":
			m["tocado"] = true
			racha = 0
			errores += 1
			_bajar(m, T_BAJAR_ERROR * 2.0)
			impostor_tocado.emit(id)
			return "impostor"
	# Señuelo.
	if perfil == "semilla":
		# Ambos celebran (GDD §4): el señuelo se queda y el pedido vuelve a llamar enseguida.
		error.emit(id, m["animal"])
		var p := _pedido_sonando()
		if not p.is_empty():
			_sonar(p, true)
		return "error"
	errores += 1
	m["tocado"] = true
	racha = 0
	_bajar(m, T_BAJAR_ERROR)
	error.emit(id, m["animal"])
	return "error"


func _acertar(m: Dictionary) -> String:
	m["tocado"] = true
	var estaba_bajando: bool = m["estado"] == "bajando"
	m["estado"] = "saltando"
	m["t"] = 0.0
	racha += 1
	aciertos += 1
	var rapidito := false
	var pts := 0
	if perfil != "semilla":
		var mult := mini(racha, racha_max)
		pts = pts_acierto * mult
		var ventana := fraccion_rapidito * t_arriba
		if t_arriba > 0.0 and not estaba_bajando and not m["oreja"] and m["t_up"] - m["t_sono"] <= ventana:
			rapidito = true
			pts += pts_rapidito
	puntaje += pts
	acierto.emit(m["id"], pts, racha, rapidito)
	# Pedido doble: los dos (en cualquier orden) dan el bonus.
	var g: int = m["grupo"]
	_grupo_aciertos[g] = int(_grupo_aciertos.get(g, 0)) + 1
	if int(_grupo_tamano.get(g, 1)) > 1 and _grupo_aciertos[g] == _grupo_tamano[g]:
		if perfil != "semilla":
			puntaje += pts_doble
		doble_completo.emit(pts_doble)
	if meta > 0 and not meta_alcanzada and aciertos >= meta:
		meta_alcanzada = true
		if perfil != "semilla":
			puntaje += pts_meta
		meta_llena.emit()
		if gana_al_llenar:
			_terminar(true)
	return "acierto"


## El ícono de oreja del cartel dice la palabra y quita el "¡rapidito!" de ese pedido (§8.3).
func usar_oreja() -> void:
	for m in madrigueras:
		if m["pedido"] and not m["tocado"] and m["escrito"] != "":
			m["oreja"] = true


## Jugada automática de Maxi en equipo (M2) y ayudas: toca el pedido que espera.
func tocar_pedido() -> String:
	var id := id_pedido()
	return tocar(id) if id >= 0 else "ignorado"


## Todos abajo al instante (pase del equipo, gag, reintento).
func bajar_todos() -> void:
	for i in madrigueras.size():
		madrigueras[i] = _madriguera_vacia(i)
	_fase = "pausa"
	_t_fase = 0.0


## Ronda terminada desde afuera (p. ej. el equipo ganó): no emite nada.
func detener() -> void:
	estado = "terminada"


## Todos bajan suave sin contar escape (fin de turno en equipo: "durante el pase no asoma nadie").
func esconder_todos() -> void:
	for i in madrigueras.size():
		var m: Dictionary = madrigueras[i]
		if m["estado"] == "aviso":
			madrigueras[i] = _madriguera_vacia(i)
		elif m["estado"] in ["subiendo", "arriba"] and not m["tocado"]:
			_bajar(m, T_BAJAR)
