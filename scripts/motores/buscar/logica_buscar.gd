class_name LogicaBuscar
extends RefCounted

## Reglas del «Escondite animal» (motor buscar, docs/fichas/motor-buscar.md §5-§10 y §12), sin pantalla y
## deterministas con semilla (ficha §2 regla 6). Las prueba `herramientas/qa_test_buscar.gd`.
##
## - Sorteo de escondites: cada animal trae 2-3 escondites hechos a mano en el nivel; por partida se sortea
##   uno y dos animales nunca comparten la misma pieza (§11.2).
## - Toque: el motor pasa un punto de la escena (ya resuelto toque frente a arrastre). Gana el objetivo frente
##   al senuelo y el animal frente a la pieza (§6). Tocar nunca es un error.
## - Listas: libre (Semilla, cualquier animal vale), uno (Brote, uno a la vez; tocar otro de la lista lo
##   encuentra igual) y tarjetas (Estrella, 3 tarjetas con pista escrita).
## - Puntaje (Brote y Estrella, §9.1): 100 x racha (1-5), "ojo de aguila", escondite de 2 pasos y tiempo par.
## - Derrota (politica del PO, 05-Nov-2026, manda sobre la ficha): TODOS los perfiles pueden perder con el
##   sol (`sol.factor_par` x `tiempo_par_s`). Al reintentar los encontrados quedan, los que faltan cambian de
##   escondite y el sol vuelve con tiempo proporcional a los que faltan. Regalo de Toby tras
##   `regalo_tras_derrotas`; en Semilla, ayuda fuerte tras `ayuda_fuerte_tras_derrotas`.
## - Destellos y estrellitas solo al ganar (los calcula el motor); perder nunca quita nada.

signal encontrado(id: String, puntos: int, racha: int, ojo_aguila: bool)
signal senuelo_tocado(id: String)
signal secreto_tocado(id: String)
signal objeto_tocado(id: String)
signal escondite_abierto(id_objeto: String, id_animal: String)
signal objetivo_activo(id: String)
signal ya_encontrado(id: String)
signal ronda_escena_terminada(ronda: int)
signal escena_completa()
signal sol_puesto()

const G := preload("res://scripts/motores/buscar/geometria_buscar.gd")

# --- Configuracion (del nivel) ---
var nivel: Dictionary = {}
var perfil := "semilla"
var modo_lista := "libre"  ## libre | uno | tarjetas
var tarjetas_visibles := 3
var tamano_escena := Vector2(1280, 720)
var zona_util_max_y := 590.0
var zona_min := 160.0
var margen := 24.0
var tiempo_par := 0.0
var factor_sol := 0.0  ## 0 = sin derrota (modo equipo)
var minimo_reintento := 45.0
var regalo_tras := 0
var ayuda_fuerte_tras := 0
var ayuda_fuerte_todos_asoman := true
var ayuda_fuerte_sin_sol := true
var descanso_tras := 3  ## 0 = nunca se ofrece descansar
var bonus_tiempo_activo := true  ## Brote: solo con record previo (HE-124); lo fija el motor
var rondas_escena := 1
var racha_brote_s := 25.0
var puntos_cfg := {"encontrado": 100, "racha_max": 5, "ojo_aguila": 100, "dos_pasos": 100, "por_segundo": 10}
var umbrales := {}
var abrir_y_encontrar := false  ## Semilla y Brote: un toque abre y encuentra (§6)

# --- Contenido ---
var objetos: Dictionary = {}  ## id -> datos de la pieza
var orden_objetos: Array[String] = []  ## por z (de atras hacia adelante)
var animales: Dictionary = {}  ## id -> datos del animal
var objetivos: Array[String] = []  ## los de la lista de ESTA partida, en orden
var senuelos: Array[String] = []
var secretos: Array[String] = []

# --- Estado ---
var rng := RandomNumberGenerator.new()
var asignacion: Dictionary = {}  ## id_animal -> indice de escondite
var abiertos: Dictionary = {}  ## id_objeto -> pasos dados
var encontrados: Array[String] = []
var regalados: Array[String] = []
var secretos_vistos: Array[String] = []
var indice_lista := 0
var puntos := 0
var racha := 0
var limpio := true  ## nada tocado desde el ultimo encontrado (ojo de aguila)
var t_ultimo := 0.0
var t_total := 0.0
var t_intento := 0.0
var limite := 0.0
var derrotas := 0
var pistas := 0
var ronda := 1
var estado := "jugando"  ## jugando | perdio | ronda | gano
var asomados: Dictionary = {}  ## id -> 0-1 (ayudas: el animal asoma)
var tope_turno_equipo := false

var _medidas: Dictionary = {}  ## cache: "id:indice:abierto" -> medida


func configurar(datos: Dictionary, semilla := -1) -> void:
	nivel = datos
	if semilla >= 0:
		rng.seed = semilla
	else:
		rng.randomize()
	perfil = str(datos.get("perfil", "semilla"))
	modo_lista = str(datos.get("modo_lista", {"semilla": "libre", "brote": "uno", "estrella": "tarjetas"}.get(perfil, "libre")))
	tarjetas_visibles = int(datos.get("tarjetas_visibles", 3))
	var escena: Dictionary = datos.get("escena", {})
	tamano_escena = G.vec(escena.get("tamano", [1280, 720]))
	zona_util_max_y = float(escena.get("zona_util_max_y", tamano_escena.y - 130.0))
	zona_min = float(datos.get("zona_toque_min_px", {"semilla": 160, "brote": 96, "estrella": 64}.get(perfil, 96)))
	margen = float(datos.get("margen_toque_px", 24))
	tiempo_par = float(datos.get("tiempo_par_s", 0) if datos.get("tiempo_par_s", 0) != null else 0)
	var sol = datos.get("sol", null)
	factor_sol = float(sol.get("factor_par", 0.0)) if sol is Dictionary else 0.0
	minimo_reintento = float(sol.get("minimo_reintento_s", 45.0)) if sol is Dictionary else 45.0
	regalo_tras = int(datos.get("regalo_tras_derrotas", 0) if datos.get("regalo_tras_derrotas", 0) != null else 0)
	# HE-124: `ayuda_fuerte_tras_derrotas` es null, un entero o {derrotas, todos_asoman, sin_sol}.
	var fuerte = datos.get("ayuda_fuerte_tras_derrotas", null)
	ayuda_fuerte_tras = 0
	if fuerte is Dictionary:
		ayuda_fuerte_tras = int(fuerte.get("derrotas", 3))
		ayuda_fuerte_todos_asoman = bool(fuerte.get("todos_asoman", true))
		ayuda_fuerte_sin_sol = bool(fuerte.get("sin_sol", true))
	elif fuerte != null:
		ayuda_fuerte_tras = int(fuerte)
	# Sin la clave, 3 (retrocompatibilidad HE-124); null = nunca (Semilla: la ayuda fuerte ya resuelve).
	var descanso = datos.get("descanso_tras_derrotas", 3) if datos.has("descanso_tras_derrotas") else 3
	descanso_tras = int(descanso) if descanso != null else 0
	if factor_sol > 0.0 and tiempo_par <= 0.0:
		push_warning("logica_buscar: sol sin tiempo_par_s en %s; sin sol" % datos.get("id_nivel", "?"))
		factor_sol = 0.0
	rondas_escena = maxi(1, int(datos.get("escenas", 1)))
	racha_brote_s = float(datos.get("racha_brote_s", 25.0))
	var cfg = datos.get("puntos", {})
	if cfg is Dictionary:
		for clave in cfg:
			puntos_cfg[clave] = cfg[clave]
	umbrales = datos.get("umbrales_puntaje", {}) if datos.get("umbrales_puntaje", {}) is Dictionary else {}
	abrir_y_encontrar = perfil != "estrella"
	objetos.clear()
	orden_objetos.clear()
	for obj in datos.get("objetos", []):
		objetos[str(obj["id"])] = obj
		orden_objetos.append(str(obj["id"]))
	orden_objetos.sort_custom(func(a: String, b: String) -> bool: return z_objeto(a) < z_objeto(b))
	animales.clear()
	for animal in datos.get("animales", []):
		animales[str(animal["id"])] = animal
	_elegir_objetivos()
	senuelos.clear()
	for id in datos.get("senuelos", []):
		if animales.has(str(id)):
			senuelos.append(str(id))
	secretos.clear()
	for id in datos.get("secretos", []):
		if animales.has(str(id)):
			secretos.append(str(id))
	reiniciar_partida()


## Objetivos de la partida: `objetivos` es el pool; con `objetivos_por_partida` se sortean (los de
## `objetivos_fijos` siempre entran, p. ej. el hermanito de Toby) y se conserva el orden del pool.
func _elegir_objetivos() -> void:
	objetivos.clear()
	var pool: Array = datos_lista("objetivos")
	var n := int(nivel.get("objetivos_por_partida", pool.size()))
	var fijos: Array = datos_lista("objetivos_fijos")
	var elegidos: Array = fijos.duplicate()
	var resto: Array = pool.filter(func(id) -> bool: return not id in fijos)
	_barajar(resto)
	for id in resto:
		if elegidos.size() >= n:
			break
		elegidos.append(id)
	for id in pool:
		if id in elegidos and animales.has(id):
			objetivos.append(id)
	if bool(nivel.get("orden_aleatorio", perfil != "semilla")):
		var fijos_primero: Array[String] = []
		var otros: Array[String] = []
		for id in objetivos:
			(fijos_primero if id in fijos else otros).append(id)
		_barajar(otros)
		objetivos.assign(fijos_primero + otros)
		# Los fijos (el hermanito de Toby) no tienen que ir siempre primeros: entran en un lugar sorteado.
		if not fijos_primero.is_empty() and objetivos.size() > 1:
			var id0: String = objetivos.pop_front()
			objetivos.insert(rng.randi_range(0, mini(2, objetivos.size())), id0)


func datos_lista(clave: String) -> Array:
	var salida: Array = []
	for id in nivel.get(clave, []):
		salida.append(str(id))
	return salida


func reiniciar_partida() -> void:
	encontrados.clear()
	regalados.clear()
	secretos_vistos.clear()
	abiertos.clear()
	asomados.clear()
	_medidas.clear()
	indice_lista = 0
	puntos = 0
	racha = 0
	limpio = true
	t_total = 0.0
	t_intento = 0.0
	t_ultimo = 0.0
	derrotas = 0
	pistas = 0
	ronda = 1
	estado = "jugando"
	sortear_escondites(en_escena(), {})
	limite = tiempo_par * factor_sol if factor_sol > 0.0 and tiempo_par > 0.0 else 0.0


## Todos los animales que se esconden en esta partida (lista + senuelos + secretos).
func en_escena() -> Array[String]:
	var ids: Array[String] = []
	for id in objetivos + senuelos + secretos:
		if not id in ids:
			ids.append(id)
	return ids


func z_objeto(id: String) -> float:
	var obj: Dictionary = objetos.get(id, {})
	return float(obj.get("z", G.vec(obj.get("pos", [0, 0])).y))


func _barajar(lista: Array) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp


# ---------------------------------------------------------------------------
# Escondites
# ---------------------------------------------------------------------------

func escondites_de(id: String) -> Array:
	return animales.get(id, {}).get("escondites", [])


func escondite(id: String) -> Dictionary:
	var lista := escondites_de(id)
	var i := int(asignacion.get(id, 0))
	return lista[i] if i >= 0 and i < lista.size() else {}


func pieza_de(esc: Dictionary) -> String:
	return str(esc.get("dentro_de", esc.get("detras_de", "")))


func esta_dentro(id: String) -> bool:
	return escondite(id).has("dentro_de")


## Sortea un escondite para cada id (ficha §2 regla 5). `previos` (id -> indice) se evita si hay otro
## libre (al reintentar "se cambian de escondite"). Las piezas ya ocupadas por los que NO se sortean se
## respetan. Dos animales nunca comparten pieza.
func sortear_escondites(ids: Array, previos: Dictionary) -> void:
	var ocupadas := {}
	for otro in asignacion:
		if not otro in ids and not otro in encontrados:
			ocupadas[pieza_de(escondite(otro))] = true
	var orden: Array = ids.duplicate()
	_barajar(orden)
	var resultado := {}
	if not _sortear_rec(orden, 0, ocupadas, previos, resultado, true):
		if not _sortear_rec(orden, 0, ocupadas, {}, resultado, true):
			push_warning("logica_buscar: no hay escondites distintos para todos en %s" % nivel.get("id_nivel", "?"))
			_sortear_rec(orden, 0, {}, {}, resultado, false)
	for id in resultado:
		asignacion[id] = resultado[id]
	_medidas.clear()


func _sortear_rec(orden: Array, i: int, ocupadas: Dictionary, previos: Dictionary, resultado: Dictionary, unico: bool) -> bool:
	if i >= orden.size():
		return true
	var id: String = orden[i]
	var opciones: Array = range(escondites_de(id).size())
	_barajar(opciones)
	for k in opciones:
		var pieza := pieza_de(escondites_de(id)[k])
		if unico and ocupadas.has(pieza):
			continue
		if previos.has(id) and k == int(previos[id]) and escondites_de(id).size() > 1 and unico:
			# Solo se acepta repetir si de verdad no hay otra pieza libre (lo resuelve la segunda pasada).
			continue
		resultado[id] = k
		ocupadas[pieza] = true
		if _sortear_rec(orden, i + 1, ocupadas, previos, resultado, unico):
			return true
		ocupadas.erase(pieza)
		resultado.erase(id)
	return false


func fijar_escondite(id: String, indice: int) -> void:
	asignacion[id] = indice
	_medidas.clear()


## Cambia de escondite a un animal (modo equipo: se le acabo el tiempo al turno). Devuelve true si cambio.
func cambiar_escondite(id: String) -> bool:
	var antes := int(asignacion.get(id, 0))
	sortear_escondites([id], {id: antes})
	return int(asignacion.get(id, 0)) != antes


# ---------------------------------------------------------------------------
# Geometria en el mundo
# ---------------------------------------------------------------------------

func tamano_animal(id: String) -> float:
	var esc := escondite(id)
	return float(esc.get("tamano", nivel.get("tamano_animal", 120)))


func pie_animal(id: String) -> Vector2:
	var esc := escondite(id)
	var base := G.vec(esc.get("pos", [0, 0]))
	var a := float(asomados.get(id, 0.0))
	if a > 0.0:
		base += G.vec(esc.get("asoma", [0, -1])) * tamano_animal(id) * 0.45 * a
	return base


func partes_animal(id: String) -> Array:
	var esc := escondite(id)
	return G.animal_mundo(animales[id].get("aspecto", {}), pie_animal(id), tamano_animal(id), bool(esc.get("espejo", false)))


func z_animal(id: String) -> float:
	var esc := escondite(id)
	if esc.has("z"):
		return float(esc["z"])
	return z_objeto(pieza_de(esc)) - 0.5


func abierto(id_objeto: String) -> float:
	var obj: Dictionary = objetos.get(id_objeto, {})
	var pasos := maxi(1, int(obj.get("pasos", 1)))
	return clampf(float(abiertos.get(id_objeto, 0)) / pasos, 0.0, 1.0)


func cobertura_objeto(id_objeto: String) -> Array:
	return G.cobertura(objetos[id_objeto], abierto(id_objeto))


## Coberturas de todo lo que esta delante de `z`.
func coberturas_delante(z: float) -> Array:
	var salida: Array = []
	for oid in orden_objetos:
		if z_objeto(oid) > z:
			salida.append_array(cobertura_objeto(oid))
	return salida


## Medida de la parte visible del animal en su escondite actual (con la pieza como este ahora).
func medida(id: String) -> Dictionary:
	var clave := "%s:%d:%.2f:%.2f" % [id, int(asignacion.get(id, 0)), abierto(pieza_de(escondite(id))), float(asomados.get(id, 0.0))]
	if _medidas.has(clave):
		return _medidas[clave]
	var m := G.medir_visible(partes_animal(id), coberturas_delante(z_animal(id)))
	# Los asomos animados (valores intermedios) no se guardan: la cache no crece sin fin.
	var a := float(asomados.get(id, 0.0))
	if a == 0.0 or a == 1.0:
		_medidas[clave] = m
	return m


## Fraccion visible medida con su pieza ABIERTA si es un escondite que se abre (ficha §6: el minimo de
## parte visible se cumple cuando el animal queda a la vista).
func fraccion_visible_revelado(id: String) -> float:
	var pieza := pieza_de(escondite(id))
	var antes = abiertos.get(pieza, null)
	if esta_dentro(id):
		abiertos[pieza] = int(objetos[pieza].get("pasos", 1))
	_medidas.clear()
	var f := float(medida(id)["fraccion"])
	if antes == null:
		abiertos.erase(pieza)
	else:
		abiertos[pieza] = antes
	_medidas.clear()
	return f


## El animal se puede tocar: no encontrado y, si esta adentro de una pieza, la pieza ya abierta.
func revelado(id: String) -> bool:
	if id in encontrados:
		return false
	if esta_dentro(id):
		return abierto(pieza_de(escondite(id))) >= 1.0
	return true


func zona_toque(id: String) -> Rect2:
	var m := medida(id)
	var zona := G.zona_toque(m, partes_animal(id), margen, zona_min)
	return zona


# ---------------------------------------------------------------------------
# Lista de objetivos
# ---------------------------------------------------------------------------

func faltan() -> Array[String]:
	var salida: Array[String] = []
	for id in objetivos:
		if not id in encontrados:
			salida.append(id)
	return salida


## Los que se buscan ahora: libre = todos los que faltan; uno = el primero; tarjetas = los 3 primeros.
func activos() -> Array[String]:
	var resto := faltan()
	var n := resto.size()
	match modo_lista:
		"uno":
			n = mini(1, n)
		"tarjetas":
			n = mini(tarjetas_visibles, n)
	var salida: Array[String] = []
	for i in n:
		salida.append(resto[i])
	return salida


func activo() -> String:
	var lista := activos()
	return lista[0] if not lista.is_empty() else ""


func es_objetivo(id: String) -> bool:
	return id in objetivos


func completa() -> bool:
	return faltan().is_empty()


# ---------------------------------------------------------------------------
# Toque
# ---------------------------------------------------------------------------

## Que hay bajo un punto de la escena (sin efectos). {"tipo": animal|objeto|nada, "id"}.
func que_hay(punto: Vector2) -> Dictionary:
	var mejor := ""
	var mejor_prioridad := 99
	var mejor_dist := INF
	var act := activos()
	for id in en_escena():
		if not revelado(id):
			continue
		if not zona_toque(id).has_point(punto):
			continue
		var prioridad := 3
		if id in act:
			prioridad = 0
		elif es_objetivo(id):
			prioridad = 1
		elif id in secretos:
			prioridad = 2
		var d := punto.distance_to(medida(id)["centro"])
		if prioridad < mejor_prioridad or (prioridad == mejor_prioridad and d < mejor_dist):
			mejor = id
			mejor_prioridad = prioridad
			mejor_dist = d
	if mejor != "":
		return {"tipo": "animal", "id": mejor}
	for i in range(orden_objetos.size() - 1, -1, -1):
		var oid: String = orden_objetos[i]
		if G.union_contiene(cobertura_objeto(oid), punto):
			return {"tipo": "objeto", "id": oid}
	return {"tipo": "nada", "id": ""}


## Un toque del nino en la escena. Devuelve {"tipo": encontrado|ya|senuelo|secreto|abrio|paso|objeto|nada,
## "id", "animal"}. Las senales salen en el momento.
func tocar(punto: Vector2) -> Dictionary:
	if estado != "jugando":
		return {"tipo": "nada", "id": ""}
	var hay := que_hay(punto)
	if hay["tipo"] == "animal":
		return tocar_animal(hay["id"])
	if hay["tipo"] == "objeto":
		return tocar_objeto(hay["id"])
	return {"tipo": "nada", "id": ""}


func tocar_animal(id: String) -> Dictionary:
	if id in encontrados:
		return {"tipo": "ya", "id": id}
	if es_objetivo(id):
		_encontrar(id, false)
		return {"tipo": "encontrado", "id": id}
	if id in secretos:
		if not id in secretos_vistos:
			secretos_vistos.append(id)
		secreto_tocado.emit(id)
		return {"tipo": "secreto", "id": id}
	# Senuelo: saluda; en Estrella corta la racha (§9.1). Tocarlo nunca quita nada.
	limpio = false
	if perfil == "estrella":
		racha = 0
	senuelo_tocado.emit(id)
	return {"tipo": "senuelo", "id": id}


## Animal escondido DENTRO de una pieza (en esta partida), o "".
func animal_dentro(id_objeto: String) -> String:
	for id in en_escena():
		if id in encontrados:
			continue
		var esc := escondite(id)
		if str(esc.get("dentro_de", "")) == id_objeto:
			return id
	return ""


func tocar_objeto(id_objeto: String) -> Dictionary:
	var obj: Dictionary = objetos.get(id_objeto, {})
	var adentro := animal_dentro(id_objeto)
	if bool(obj.get("escondite", false)) and G.es_abrible(str(obj.get("tipo", ""))) and abierto(id_objeto) < 1.0:
		var pasos := maxi(1, int(obj.get("pasos", 1)))
		abiertos[id_objeto] = int(abiertos.get(id_objeto, 0)) + 1
		_medidas.clear()
		# Abrir el escondite de alguien no corta el "ojo de aguila"; abrir uno vacio es explorar.
		if adentro == "":
			limpio = false
		if int(abiertos[id_objeto]) < pasos:
			objeto_tocado.emit(id_objeto)
			return {"tipo": "paso", "id": id_objeto, "animal": adentro}
		escondite_abierto.emit(id_objeto, adentro)
		if adentro != "" and abrir_y_encontrar and es_objetivo(adentro):
			_encontrar(adentro, false)
			return {"tipo": "encontrado", "id": adentro, "abrio": id_objeto}
		return {"tipo": "abrio", "id": id_objeto, "animal": adentro}
	limpio = false
	objeto_tocado.emit(id_objeto)
	return {"tipo": "objeto", "id": id_objeto}


func _encontrar(id: String, regalo: bool) -> void:
	var act := activos()
	var en_activos := id in act
	var ganados := 0
	var ojo := false
	if perfil != "semilla":
		if perfil == "brote" and t_total - t_ultimo > racha_brote_s and not encontrados.is_empty():
			racha = 0
		if not regalo:
			racha = mini(racha + 1, int(puntos_cfg.get("racha_max", 5)))
			ganados = int(puntos_cfg.get("encontrado", 100)) * maxi(1, racha)
			ojo = limpio and en_activos
			if ojo:
				ganados += int(puntos_cfg.get("ojo_aguila", 100))
			var esc := escondite(id)
			if esc.has("dentro_de") and int(objetos.get(str(esc["dentro_de"]), {}).get("pasos", 1)) >= 2:
				ganados += int(puntos_cfg.get("dos_pasos", 100))
	puntos += ganados
	encontrados.append(id)
	if regalo:
		regalados.append(id)
	limpio = true
	t_ultimo = t_total
	asomados.erase(id)
	encontrado.emit(id, ganados, racha, ojo)
	_avanzar_lista(id)
	if completa():
		if ronda < rondas_escena:
			estado = "ronda"
			ronda_escena_terminada.emit(ronda)
		else:
			estado = "gano"
			escena_completa.emit()


## Brote: si el siguiente de la lista ya estaba encontrado (se toco antes de tiempo), se avisa.
func _avanzar_lista(recien: String) -> void:
	if modo_lista != "uno":
		return
	while indice_lista < objetivos.size() and objetivos[indice_lista] in encontrados:
		var id := objetivos[indice_lista]
		indice_lista += 1
		if id != recien:
			ya_encontrado.emit(id)
	var nuevo := activo()
	if nuevo != "":
		objetivo_activo.emit(nuevo)


## Maxi: la segunda escena de la estacion ("¡se escondieron otra vez!"): mismos animales, otros escondites.
func siguiente_ronda_escena() -> void:
	if estado != "ronda":
		return
	var previos := asignacion.duplicate()
	ronda += 1
	encontrados.clear()
	abiertos.clear()
	asomados.clear()
	indice_lista = 0
	t_intento = 0.0
	limite = tiempo_par * factor_sol if factor_sol > 0.0 and tiempo_par > 0.0 else 0.0
	sortear_escondites(en_escena(), previos)
	_aplicar_ayuda_fuerte()
	estado = "jugando"


# ---------------------------------------------------------------------------
# Tiempo, sol y reintento
# ---------------------------------------------------------------------------

func avanzar(dt: float) -> void:
	if estado != "jugando":
		return
	t_total += dt
	t_intento += dt
	if limite > 0.0 and t_intento >= limite:
		estado = "perdio"
		derrotas += 1
		sol_puesto.emit()


## 0 = recien salio, 1 = se puso. Sin sol, siempre 0.
func avance_sol() -> float:
	return clampf(t_intento / limite, 0.0, 1.0) if limite > 0.0 else 0.0


## "¡Otra vez!": los encontrados quedan, los que faltan se cambian de escondite y el sol vuelve con tiempo
## proporcional a los que faltan (minimo `minimo_reintento_s`).
func reintentar() -> void:
	if estado != "perdio":
		return
	var resto := faltan()
	var previos := {}
	var ids: Array = []
	for id in en_escena():
		if not id in encontrados:
			ids.append(id)
			previos[id] = int(asignacion.get(id, 0))
	abiertos.clear()
	asomados.clear()
	sortear_escondites(ids, previos)
	t_intento = 0.0
	var total := maxi(1, objetivos.size())
	limite = maxf(tiempo_par * factor_sol * float(resto.size()) / total, minimo_reintento) if factor_sol > 0.0 else 0.0
	_aplicar_ayuda_fuerte()
	racha = 0
	limpio = true
	t_ultimo = t_total
	estado = "jugando"


func regalo_disponible() -> bool:
	return regalo_tras > 0 and derrotas >= regalo_tras and estado == "jugando" and not completa()


func ayuda_fuerte() -> bool:
	return ayuda_fuerte_tras > 0 and derrotas >= ayuda_fuerte_tras


## Ayuda fuerte de Semilla (HE-124, ficha §10.1): todos asoman y llaman a la vez y no hay sol: el intento (y
## la escena siguiente) quedan con la victoria asegurada.
func _aplicar_ayuda_fuerte() -> void:
	if not ayuda_fuerte():
		return
	if ayuda_fuerte_sin_sol:
		limite = 0.0
	if ayuda_fuerte_todos_asoman:
		for id in en_escena():
			if not id in encontrados:
				asomados[id] = 1.0
	_medidas.clear()


## Se ofrece descansar (sin obligar) en el cartel de la derrota (GDD §6 regla 11).
func ofrecer_descanso() -> bool:
	return descanso_tras > 0 and derrotas >= descanso_tras


## Toby encuentra uno con el olfato (el activo, o el primero que falta). Sin puntos. Devuelve el id.
func regalar() -> String:
	var id := activo()
	if id == "":
		return ""
	_encontrar(id, true)
	return id


## Radar de Toby (Sofia, §10.4): el objetivo de la primera tarjeta. El costo lo cobra el motor.
func usar_pista(pagada: bool) -> String:
	var id := activo()
	if id != "" and pagada:
		pistas += 1
	return id


# ---------------------------------------------------------------------------
# Puntaje y estrellitas
# ---------------------------------------------------------------------------

func bonus_tiempo() -> int:
	if perfil == "semilla" or tiempo_par <= 0.0 or not bonus_tiempo_activo:
		return 0
	return int(maxf(0.0, tiempo_par - t_total)) * int(puntos_cfg.get("por_segundo", 10))


func puntaje_final() -> int:
	return puntos + bonus_tiempo()


## Las que lleva la partida en vivo (medidor de la pista con costo): 3 menos pistas, tope 2 tras perder.
func estrellitas_en_vivo() -> int:
	var tope := 2 if derrotas > 0 else 3
	return clampi(3 - pistas, 1, tope)


func estrellitas_finales() -> int:
	if perfil == "semilla":
		return 0
	var total := puntaje_final()
	var por_puntaje := 1
	if not umbrales.is_empty():
		if total >= int(umbrales.get("tres", 1 << 30)):
			por_puntaje = 3
		elif total >= int(umbrales.get("dos", 1 << 30)):
			por_puntaje = 2
	else:
		por_puntaje = 3
	var tope := 2 if derrotas > 0 else 3
	return clampi(por_puntaje - (pistas if perfil == "estrella" else 0), 1, tope)


# ---------------------------------------------------------------------------
# Guardado parcial (Sofia, escenas de ~5 min, §12.1)
# ---------------------------------------------------------------------------

func estado_parcial() -> Dictionary:
	return {"objetivos": objetivos.duplicate(), "encontrados": encontrados.duplicate(), "asignacion": asignacion.duplicate(),
		"puntos": puntos, "racha": racha, "t_total": t_total, "derrotas": derrotas, "pistas": pistas,
		"indice_lista": indice_lista, "abiertos": abiertos.duplicate()}


func restaurar_parcial(d: Dictionary) -> bool:
	var objs = d.get("objetivos", [])
	if not objs is Array or objs.is_empty():
		return false
	for id in objs:
		if not animales.has(str(id)):
			return false
	objetivos.clear()
	for id in objs:
		objetivos.append(str(id))
	encontrados.clear()
	for id in d.get("encontrados", []):
		if str(id) in objetivos:
			encontrados.append(str(id))
	var asig = d.get("asignacion", {})
	if asig is Dictionary:
		for id in asig:
			if animales.has(str(id)) and int(asig[id]) < escondites_de(str(id)).size():
				asignacion[str(id)] = int(asig[id])
	var ab = d.get("abiertos", {})
	abiertos.clear()
	if ab is Dictionary:
		for oid in ab:
			if objetos.has(str(oid)):
				abiertos[str(oid)] = int(ab[oid])
	puntos = int(d.get("puntos", 0))
	racha = int(d.get("racha", 0))
	t_total = float(d.get("t_total", 0.0))
	t_ultimo = t_total
	derrotas = int(d.get("derrotas", 0))
	pistas = int(d.get("pistas", 0))
	indice_lista = int(d.get("indice_lista", 0))
	# Se retoma con el sol de los que faltan, como tras un reintento.
	t_intento = 0.0
	if factor_sol > 0.0:
		limite = maxf(tiempo_par * factor_sol * float(faltan().size()) / maxi(1, objetivos.size()), minimo_reintento)
	_medidas.clear()
	return true
