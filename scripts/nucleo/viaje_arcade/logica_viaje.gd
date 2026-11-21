class_name LogicaViaje
extends RefCounted

## Lógica pura del viaje arcade (HE-136; ficha docs/fichas/viaje-arcade.md, "la ficha" en adelante).
## No conoce nodos, ni dibujo, ni audio: recibe la entrada del dedo en `actualizar()` y deja lo que
## pasó en `eventos` (sonidos, voces, confeti, checkpoints) para que la escena lo muestre. Así se
## puede correr headless con un jugador simulado (criterios §13 y calibración V7).
##
## Plano lógico 1280×720. La nave vuela hacia la derecha; todo lo demás entra por la derecha.
## Fases: intro -> juego (sectores) -> jefe -> encuentro (Coleccionauta) -> fin.
##        gag y reinicio interrumpen juego/jefe y vuelven al último checkpoint (§7.2).

const ANCHO := 1280.0
const ALTO := 720.0
const CAMPO := Rect2(60, 60, 1160, 600)                 # §4.2: margen de 60 px
const X_FRANJA := 340.0                                 # si x < 340 la nave no sube de y = 180
const Y_FRANJA := 180.0
const ICONO_DESCANSO := Rect2(1168, 12, 96, 96)         # §7.4
const POS_INICIO := Vector2(230, 380)
const VEL_BALA := 1100.0
const RADIO_BALA := 14.0
const IMAN := 60.0                                      # §4: los power-ups se recogen con imán de 60 px
const HITSTOP := 0.05
const HITSTOP_ENTRE := 0.3
const DESTELLOS_BLANCOS_POR_SEGUNDO := 3                # §2.8 fotosensibilidad
const ESPERA_SECTOR := 2.0                              # §10.3: la primera oleada entra ≥ 2 s después de la voz
const PUNTOS := {"meteorito": 50, "meteorito_chico": 20, "basura": 30, "boya": 40, "recolector": 60,
		"fila": 300, "punto_debil": 150, "jefe": 1000}
## Radio de choque = 70 % del dibujo (§5.1). El dibujo lo pone la escena con el mismo tamaño.
const RADIO_DIBUJO := {"meteorito": 62.0, "meteorito_chico": 34.0, "basura": 46.0, "boya": 44.0,
		"recolector": 46.0, "bala": 16.0}

var perfil_id := "brote"
var cfg: Dictionary = {}        # fila de datos/viaje/perfiles.json
var ruta: Dictionary = {}       # bloque del perfil en datos/viaje/rutas/<ruta>.json
var rng := RandomNumberGenerator.new()

var fase := "intro"
var t_fase := 0.0
var tiempo := 0.0
var eventos: Array = []

# la nave
var nave := POS_INICIO
var nave_vel := Vector2.ZERO
var corazones := 3
var corazones_max := 3
var invulnerable := 0.0
var escudo := false
var arma := 1
var minicometas := 0.0
var iman := 0.0
var _cadencia := 0.0
var _borde_t := 0.0

# puntaje y premios
var puntaje := 0
var multiplicador := 1
var racha := 0
var destellos_consolidados := 0
var destellos_en_juego := 0
var vidas_extra_dadas := 0
var record_anterior := 0
var _record_avisado := false

# recorrido
var sector := 0
var oleada := 0
var _espera := 0.0
var _esperando_vacia := false
var checkpoint := {"sector": 0, "oleada": 0}
var _cerrando_sector := false

# entidades
var enemigos: Array = []
var balas: Array = []           # de la nave
var balas_enemigas: Array = []
var objetos: Array = []         # cápsulas, destellos sueltos
var jefe: Dictionary = {}
var colec: Dictionary = {}      # el Coleccionauta en el encuentro
var _formaciones := {}
var _id := 0

# ayudas y reglas
var reinicios := 0
var derrotas_seguidas := 0
var volante := false            # "Cometa al volante" (Maxi, §7.4)
var regalo := false
var descanso_visible := false
var voz_sonando := false        # lo fija la escena: la pinza no se lanza mientras suena una voz (N-A5)
var _fase_antes_gag := "juego"
var _hitstop := 0.0
var _ultimo_hitstop := -10.0
var _destellos_blancos: Array = []
var temblor := 0.0              # trauma 0..1 (§4.1)


# --- preparar ---------------------------------------------------------------------

func preparar(perfiles: Dictionary, datos_ruta: Dictionary, id_perfil_dificultad: String, guardado: Dictionary = {},
		semilla := 7) -> void:
	perfil_id = id_perfil_dificultad if perfiles.has(id_perfil_dificultad) else "brote"
	cfg = perfiles[perfil_id]
	ruta = datos_ruta.get("perfiles", {}).get(perfil_id, {})
	rng.seed = semilla
	corazones_max = int(cfg["corazones"])
	corazones = corazones_max
	escudo = bool(cfg["escudo_por_sector"])
	record_anterior = int(guardado.get("record", 0))
	var cp = guardado.get("checkpoint", null)
	if cp is Dictionary and int(cp.get("sector", -1)) >= 0:
		checkpoint = {"sector": int(cp["sector"]), "oleada": int(cp.get("oleada", 0))}
		sector = checkpoint["sector"]
		oleada = checkpoint["oleada"]
	fase = "intro"
	t_fase = 0.0


func es_maxi() -> bool:
	return perfil_id == "semilla"


func n_sectores() -> int:
	return (ruta.get("sectores", []) as Array).size()


## Termina la intro (al acabar la voz o al saltarla con un toque, M13).
func empezar() -> void:
	if fase != "intro":
		return
	_ir_a_checkpoint(false)


## Progreso de la ruta para la barra de trayecto (0..1).
func avance() -> float:
	if fase == "encuentro" or fase == "fin":
		return 1.0
	if not jefe.is_empty() or sector >= n_sectores():
		return 0.92
	var n := maxi(1, n_sectores())
	var oleadas := maxi(1, (ruta["sectores"][sector]["oleadas"] as Array).size())
	return 0.85 * (float(sector) + float(oleada) / oleadas) / n


func velocidad_avance() -> float:
	var v: Array = cfg["velocidad_avance"]
	return lerpf(float(v[0]), float(v[1]), clampf(avance() / 0.85, 0.0, 1.0))


# --- bucle ------------------------------------------------------------------------

## entrada: {dedo: bool, nuevo_toque: bool, delta: Vector2, punto: Vector2, teclado: Vector2, disparo: bool}
func actualizar(dt: float, entrada: Dictionary) -> void:
	tiempo += dt
	t_fase += dt
	invulnerable = maxf(0.0, invulnerable - dt)
	minicometas = maxf(0.0, minicometas - dt)
	iman = maxf(0.0, iman - dt)
	temblor = maxf(0.0, temblor - dt * 2.0)
	_borde_t = maxf(0.0, _borde_t - dt)
	var dt_enemigos := dt
	if _hitstop > 0.0:
		_hitstop -= dt
		dt_enemigos = 0.0       # M2: el hit-stop congela solo enemigos y balas enemigas
	match fase:
		"intro":
			_mover_nave(dt, entrada)
		"juego":
			_mover_nave(dt, entrada)
			_disparar(dt, entrada)
			_avanzar_ruta(dt)
		"jefe":
			_mover_nave(dt, entrada)
			_disparar(dt, entrada)
			_actualizar_jefe(dt_enemigos)
		"encuentro":
			_mover_nave(dt, entrada)
			_disparar(dt, entrada)
			_actualizar_encuentro(dt)
		"gag":
			if t_fase >= float(cfg["gag"]):
				_reiniciar()
		"reinicio":
			if t_fase >= float(cfg["reinicio"]):
				fase = _fase_antes_gag
				t_fase = 0.0
				if descanso_pendiente():
					descanso_visible = true
					_evento("descanso_aparece")
		"fin":
			pass
	_mover_balas(dt, dt_enemigos)
	_mover_enemigos(dt_enemigos)
	_mover_objetos(dt)
	if fase in ["juego", "jefe", "encuentro"]:
		_choques()


## Tocar fuera de la franja durante el gag o el reinicio lo acorta (§7.2).
func acortar() -> void:
	if fase == "gag":
		_reiniciar()
	elif fase == "reinicio":
		t_fase = float(cfg["reinicio"])


# --- la nave ----------------------------------------------------------------------

func _mover_nave(dt: float, e: Dictionary) -> void:
	var antes := nave
	var dedo := bool(e.get("dedo", false))
	if dedo and cfg["seguimiento"] == "tope":
		# Maxi (§4.2): hacia el dedo desplazado 120 px arriba, sin suavizado, con tope de velocidad
		var objetivo: Vector2 = (e.get("punto", nave) as Vector2) - Vector2(0, float(cfg["desplazamiento_dedo"]))
		var paso := float(cfg["velocidad_max"]) * dt
		var falta := objetivo - nave
		nave = objetivo if falta.length() <= paso else nave + falta.normalized() * paso
	elif dedo:
		nave += e.get("delta", Vector2.ZERO) as Vector2        # Nicole y Sofía: 1:1
	var teclado: Vector2 = e.get("teclado", Vector2.ZERO)
	if teclado != Vector2.ZERO:
		nave += teclado.normalized() * float(cfg["velocidad_teclado"]) * dt
	if not jefe.is_empty() and jefe.get("empujando", false):
		nave.x -= 120.0 * dt      # M16: la aspiradora empuja como máximo 120 px/s
	var libre := nave
	nave = limitar(nave, float(cfg["radio_nave"]))
	if libre != nave and es_maxi() and _borde_t <= 0.0 and dedo:
		_borde_t = 0.3
		_evento("borde", {"pos": nave})            # rebote visual + "boing" suave, sin perder vida
	nave_vel = (nave - antes) / maxf(dt, 0.001)


## Campo jugable (§4.2): margen de 60 px, la franja de esquina y el icono de descanso quedan fuera.
func limitar(p: Vector2, radio: float) -> Vector2:
	p.x = clampf(p.x, CAMPO.position.x, CAMPO.end.x)
	p.y = clampf(p.y, CAMPO.position.y, CAMPO.end.y)
	if p.x - radio < X_FRANJA:
		p.y = maxf(p.y, Y_FRANJA + radio)
	if descanso_visible and p.x + radio > ICONO_DESCANSO.position.x:
		p.y = maxf(p.y, ICONO_DESCANSO.end.y + radio)
	return p


func _disparar(dt: float, e: Dictionary) -> void:
	_cadencia -= dt
	var dispara := bool(e.get("dedo", false)) or bool(e.get("disparo", false))
	if not dispara:
		_cadencia = 0.0
		return
	if bool(e.get("nuevo_toque", false)):
		_cadencia = 0.0      # §2.2: el primer disparo sale en el cuadro del toque
	if _cadencia > 0.0:
		return
	_cadencia = 1.0 / float(cfg["cadencia"])
	var punta := nave + Vector2(70, 4)
	match arma:
		1:
			_bala(punta, Vector2(VEL_BALA, 0))
		2:
			_bala(punta + Vector2(0, -14), Vector2(VEL_BALA, 0))
			_bala(punta + Vector2(0, 14), Vector2(VEL_BALA, 0))
		_:
			_bala(punta, Vector2(VEL_BALA, 0))
			_bala(punta + Vector2(-6, -10), Vector2(VEL_BALA, -170))
			_bala(punta + Vector2(-6, 10), Vector2(VEL_BALA, 170))
	if minicometas > 0.0:
		for lado in [-1, 1]:
			_bala(nave + Vector2(20, 64 * lado), Vector2(VEL_BALA, 0))
	_evento("disparo", {"pos": punta})


func _bala(p: Vector2, v: Vector2) -> void:
	balas.append({"pos": p, "vel": v})


# --- recorrido por sectores ---------------------------------------------------------

func _oleadas() -> Array:
	return ruta["sectores"][sector]["oleadas"]


func _avanzar_ruta(dt: float) -> void:
	if _cerrando_sector:
		if _pantalla_vacia(true):
			_cerrar_sector()
		return
	if oleada >= _oleadas().size():
		_cerrando_sector = true
		return
	var o: Dictionary = _oleadas()[oleada]
	if o.has("checkpoint") and oleada > 0 and not _esperando_vacia and checkpoint != {"sector": sector, "oleada": oleada}:
		_esperando_vacia = true     # §3: el checkpoint se marca con la pantalla vacía
	if _esperando_vacia:
		if not _pantalla_vacia(false):
			return
		_esperando_vacia = false
		_marcar_checkpoint(sector, oleada)
		_espera = maxf(_espera, 0.8)
	_espera -= dt
	if _espera > 0.0:
		return
	_soltar_oleada(o)
	oleada += 1
	_espera = float(o.get("espera", 2.0))


func _pantalla_vacia(con_objetos: bool) -> bool:
	if not enemigos.is_empty() or not balas_enemigas.is_empty():
		return false
	if con_objetos:
		for ob in objetos:
			if ob["tipo"] == "destello":
				return false
	return true


func _marcar_checkpoint(s: int, o: int) -> void:
	checkpoint = {"sector": s, "oleada": o}
	_evento("checkpoint", {"checkpoint": checkpoint.duplicate()})


func _cerrar_sector() -> void:
	_cerrando_sector = false
	destellos_consolidados += destellos_en_juego
	destellos_en_juego = 0
	descanso_visible = false
	var falta := corazones < corazones_max
	match str(cfg["corazon_por_sector"]):
		"garantizado", "si_falta":
			if falta:
				corazones += 1
				_evento("corazon_regalo")
	_evento("sector_listo", {"sector": sector})
	_evento("voz", {"clave": "viaje_sector_listo"})
	sector += 1
	oleada = 0
	if sector >= n_sectores():
		_marcar_checkpoint(sector, 0)       # checkpoint antes del jefe
		_preparar_jefe()
	else:
		_marcar_checkpoint(sector, 0)
		_empezar_sector()


func _empezar_sector() -> void:
	_espera = ESPERA_SECTOR + 1.0
	if cfg["escudo_por_sector"] and not escudo:
		escudo = true
		_evento("escudo")
	_evento("voz", {"clave": "viaje_sector_%d" % (sector + 1), "retraso": 1.0})


# --- oleadas ----------------------------------------------------------------------

func _nuevo(tipo: String, pos: Vector2, vel: Vector2, extra := {}) -> Dictionary:
	_id += 1
	var e := {"id": _id, "tipo": tipo, "pos": pos, "vel": vel, "t": 0.0, "giro": rng.randf_range(-1.5, 1.5),
			"radio": RADIO_DIBUJO.get(tipo, 40.0) * 0.7, "vida": 1, "golpe_t": 0.0}
	e.merge(extra, true)
	return e


func _cuantos(n: int) -> int:
	return int(ceil(n / 2.0)) if volante else n    # "Cometa al volante": enemigos a la mitad


func _soltar_oleada(o: Dictionary) -> void:
	var v := velocidad_avance()
	var n := _cuantos(int(o.get("n", 1)))
	var libres := int(cfg["enemigos_max"]) - enemigos.size()
	n = mini(n, maxi(1, libres))
	match str(o["tipo"]):
		"meteoritos":
			var hueco := float(cfg["hueco_min"])
			var centro := rng.randf_range(Y_FRANJA + hueco * 0.5, CAMPO.end.y - hueco * 0.5)
			for i in n:
				var y := rng.randf_range(CAMPO.position.y + 40, CAMPO.end.y - 20)
				if absf(y - centro) < hueco * 0.5:
					y = centro + signf(y - centro + 0.01) * hueco * 0.5 + signf(y - centro + 0.01) * 30
				y = clampf(y, 120, 650)
				var grande := float(cfg["golpes_meteorito"]) > 1
				enemigos.append(_nuevo("meteorito", Vector2(1360 + i * 150, y),
						Vector2(-v * rng.randf_range(0.85, 1.15), rng.randf_range(-18, 18)),
						{"vida": 1, "parte": grande, "variante": rng.randi_range(0, 2)}))
		"basura":
			for i in n:
				enemigos.append(_nuevo("basura", Vector2(1360 + i * 220, rng.randf_range(200, 600)),
						Vector2(-v * 0.8, 0), {"base_y": 0.0, "onda": rng.randf_range(40, 90),
						"variante": rng.randi_range(0, 1)}))
				enemigos[-1]["base_y"] = enemigos[-1]["pos"].y
		"formacion":
			_id += 1
			var fid := _id
			_formaciones[fid] = n
			var base_y := rng.randf_range(230, 520)
			var en_v := str(o.get("forma", "onda")) == "v"
			var picadas := []
			if cfg.get("picada", false):
				var cada := int(cfg.get("picada_cada", 3))
				for i in n:
					if (i + 1) % maxi(1, cada) == 0 or (cada == 1 and i % 2 == 1):
						picadas.append(i)
				if cada == 1:     # Sofía: en pareja, la mitad de la formación
					picadas = picadas.slice(0, maxi(2, n / 2))
			for i in n:
				var y := base_y + (absf(i - (n - 1) / 2.0) * 55.0 if en_v else 0.0)
				enemigos.append(_nuevo("recolector", Vector2(1360 + i * 105, y), Vector2(-v * 0.9, 0),
						{"base_y": y, "fila": fid, "onda": 70.0 if not en_v else 20.0, "fase_onda": i * 0.6,
						"picada": i in picadas, "picada_estado": "", "picada_t": 0.0}))
		"torretas":
			for i in n:
				enemigos.append(_nuevo("boya", Vector2(1360 + i * 160, rng.randf_range(220, 560)),
						Vector2(-v * 0.7, 0), {"x_alto": rng.randf_range(940, 1100), "base_y": 0.0, "vida": 2,
						"tiro_t": 1.0, "abanico": bool(o.get("abanico", false))}))
				enemigos[-1]["base_y"] = enemigos[-1]["pos"].y
	if o.has("capsula"):
		objetos.append({"tipo": "capsula", "cual": str(o["capsula"]), "pos": Vector2(1360, rng.randf_range(220, 560)),
				"vel": Vector2(-v * 0.55, 0), "t": 0.0})
	if o.get("destello", false):
		# §9.2: 1 destello suelto por sector, viaja con la oleada final (~6 s en cruzar)
		objetos.append({"tipo": "destello", "pos": Vector2(1380, rng.randf_range(300, 460)),
				"vel": Vector2(-215, 0), "t": 0.0, "sector": true})


func _mover_enemigos(dt: float) -> void:
	for e in enemigos.duplicate():
		e["t"] += dt
		e["golpe_t"] = maxf(0.0, e["golpe_t"] - dt)
		match str(e["tipo"]):
			"basura":
				e["pos"].x += e["vel"].x * dt
				e["pos"].y = e["base_y"] + sin(e["t"] * 1.3) * e["onda"]
			"recolector":
				_mover_recolector(e, dt)
			"boya":
				_mover_boya(e, dt)
			_:
				e["pos"] += e["vel"] * dt
				if e["pos"].y < 90 or e["pos"].y > 670:
					e["vel"].y = -e["vel"].y
		if e["pos"].x < -160 or e["pos"].x > ANCHO + 320 or e["pos"].y < -200 or e["pos"].y > ALTO + 200:
			_quitar_enemigo(e, false)
	for b in balas_enemigas:
		b["pos"] += b["vel"] * dt
	balas_enemigas = balas_enemigas.filter(func(b): return b["pos"].x > -60 and b["pos"].x < ANCHO + 60 \
			and b["pos"].y > -60 and b["pos"].y < ALTO + 60)


func _mover_recolector(e: Dictionary, dt: float) -> void:
	match str(e["picada_estado"]):
		"":
			e["pos"].x += e["vel"].x * dt
			e["pos"].y = e["base_y"] + sin(e["t"] * 2.2 + e["fase_onda"]) * e["onda"]
			if e["picada"] and e["pos"].x < 1020:
				e["picada_estado"] = "aviso"       # §5.2: brilla y suena antes de lanzarse
				e["picada_t"] = float(cfg["aviso"])
				_evento("aviso", {"pos": e["pos"], "id": e["id"]})
		"aviso":
			e["picada_t"] -= dt
			e["pos"].x += e["vel"].x * 0.25 * dt
			if e["picada_t"] <= 0.0:
				e["picada_estado"] = "picada"
				e["vel"] = (nave - e["pos"]).normalized() * velocidad_avance() * 2.2
		"picada":
			e["pos"] += e["vel"] * dt
			if e["pos"].x < nave.x - 40 and e["vel"].x > -100:
				e["vel"].x -= 600 * dt
		_:
			e["pos"] += e["vel"] * dt


func _mover_boya(e: Dictionary, dt: float) -> void:
	if e["t"] < 7.0:
		e["pos"].x = maxf(e["x_alto"], e["pos"].x + e["vel"].x * dt)
	else:
		e["pos"].x += e["vel"].x * dt
	e["pos"].y = e["base_y"] + sin(e["t"] * 1.6) * 18.0
	if not cfg["torretas_disparan"] or e["pos"].x > ANCHO - 20:
		return
	e["tiro_t"] -= dt
	if e["tiro_t"] <= float(cfg["aviso"]) * 0.6 and not e.get("avisando", false):
		e["avisando"] = true
		_evento("aviso", {"pos": e["pos"], "id": e["id"]})
	if e["tiro_t"] > 0.0:
		return
	e["avisando"] = false
	e["tiro_t"] = 2.2 if perfil_id == "brote" else 1.5
	var vel := float(cfg["bala_velocidad"])
	var dir := Vector2.LEFT
	if cfg["bala_apuntada"]:
		dir = (nave - e["pos"]).normalized()
	if e.get("abanico", false):
		_abanico(e["pos"], dir, vel, 5 if perfil_id == "estrella" else 3)
	else:
		_bala_enemiga(e["pos"] + Vector2(-30, 0), dir * vel, "burbuja")


func _bala_enemiga(p: Vector2, v: Vector2, tipo: String) -> void:
	if es_maxi():
		return      # §6: Maxi no tiene proyectiles enemigos
	balas_enemigas.append({"pos": p, "vel": v, "tipo": tipo, "radio": RADIO_DIBUJO["bala"] * 0.7})


func _abanico(p: Vector2, dir: Vector2, vel: float, n: int) -> void:
	for i in n:
		var a := (i - (n - 1) / 2.0) * 0.28
		_bala_enemiga(p + Vector2(-30, 0), dir.rotated(a) * vel, "burbuja")


func _quitar_enemigo(e: Dictionary, roto: bool) -> void:
	enemigos.erase(e)
	if e.has("fila"):
		var fid: int = e["fila"]
		if not roto:
			_formaciones.erase(fid)     # se escapó uno: ya no hay premio de fila
		elif _formaciones.has(fid):
			_formaciones[fid] -= 1
			if _formaciones[fid] <= 0:
				_formaciones.erase(fid)
				_sumar(PUNTOS["fila"], false)
				_evento("fila", {"pos": e["pos"]})


# --- choques ----------------------------------------------------------------------

func _choques() -> void:
	var radio_nave := float(cfg["radio_nave"])
	# balas de la nave contra enemigos, jefe y bolsas
	for b in balas.duplicate():
		var usada := false
		for e in enemigos:
			if e["pos"].x > ANCHO - 30:
				continue     # todavía entrando: no se rompe sin que el niño lo vea
			if b["pos"].distance_to(e["pos"]) < e["radio"] + RADIO_BALA:
				_golpear_enemigo(e)
				usada = true
				break
		if not usada and not jefe.is_empty() and jefe["estado"] != "vencido":
			usada = _golpear_jefe(b["pos"])
		if not usada and not colec.is_empty():
			usada = _golpear_bolsa(b["pos"])
		if usada:
			balas.erase(b)
	# la nave contra enemigos, balas y el cuerpo del jefe
	if invulnerable <= 0.0 and fase != "encuentro":
		for e in enemigos:
			if nave.distance_to(e["pos"]) < e["radio"] + radio_nave:
				e["vel"].x = absf(e["vel"].x) * 0.6 + 120    # rebota (§5.1)
				e["picada_estado"] = "rebote" if e["tipo"] == "recolector" else ""
				_recibir_golpe()
				return
		for b in balas_enemigas:
			if nave.distance_to(b["pos"]) < b["radio"] + radio_nave:
				balas_enemigas.erase(b)
				_evento("plop", {"pos": b["pos"]})
				_recibir_golpe()
				return
		if not jefe.is_empty() and jefe["estado"] != "vencido" and jefe["estado"] != "entra":
			if nave.distance_to(jefe["pos"]) < jefe["radio"] + radio_nave:
				_recibir_golpe()
	# la nave revienta bolsas por contacto (M11)
	if not colec.is_empty():
		_golpear_bolsa(nave, radio_nave)


func _golpear_enemigo(e: Dictionary) -> void:
	e["vida"] -= 1
	e["golpe_t"] = 0.08
	e["pos"].x += 5        # retroceso de 4-6 px (§4)
	_impacto(e["pos"])
	if e["vida"] > 0:
		return
	if e["tipo"] == "meteorito" and e.get("parte", false):
		# Sofía (§5.1): el meteorito grande se parte en 2 pedacitos que también hay que romper
		for lado in [-1, 1]:
			enemigos.append(_nuevo("meteorito_chico", e["pos"] + Vector2(0, 26 * lado),
					Vector2(e["vel"].x * 1.1, 90 * lado), {"variante": e.get("variante", 0)}))
	_quitar_enemigo(e, true)
	_sumar(int(PUNTOS.get(e["tipo"], 30)), true)
	var grande: bool = e["tipo"] in ["meteorito", "boya", "basura"]
	if grande:
		_pedir_hitstop()
	_evento("rompe", {"pos": e["pos"], "tipo": e["tipo"], "grande": grande})


func _impacto(p: Vector2) -> void:
	# §2.8: nunca más de 3 destellos blancos por segundo en toda la pantalla
	_destellos_blancos = _destellos_blancos.filter(func(t): return tiempo - t < 1.0)
	var blanco := _destellos_blancos.size() < DESTELLOS_BLANCOS_POR_SEGUNDO
	if blanco:
		_destellos_blancos.append(tiempo)
	_evento("impacto", {"pos": p, "blanco": blanco})


func _pedir_hitstop() -> void:
	if tiempo - _ultimo_hitstop >= HITSTOP_ENTRE:
		_ultimo_hitstop = tiempo
		_hitstop = HITSTOP


func _sumar(puntos: int, multiplica: bool) -> void:
	puntaje += puntos * (multiplicador if multiplica else 1)
	if multiplica:
		racha += 1
		if racha >= int(cfg["racha_por_paso"]):
			racha = 0
			if multiplicador < int(cfg["multiplicador_tope"]):
				multiplicador += 1
				_evento("multiplicador", {"valor": multiplicador})
	var extras: Array = cfg["vidas_extra"]
	if vidas_extra_dadas < extras.size() and puntaje >= int(extras[vidas_extra_dadas]):
		vidas_extra_dadas += 1
		corazones = mini(corazones + 1, corazones_max + 1)
		_evento("vida_extra")
	if record_anterior > 0 and not _record_avisado and reinicios == 0 and puntaje > record_anterior:
		_record_avisado = true
		_evento("record_superado")


func _recibir_golpe() -> void:
	temblor = minf(1.0, temblor + 0.6)
	_pedir_hitstop()
	if escudo:
		escudo = false
		invulnerable = 1.0
		_evento("escudo_revienta", {"pos": nave})
		return
	if volante and corazones <= 1:
		invulnerable = float(cfg["invulnerable"])
		_evento("boing", {"pos": nave})        # M5: con Cometa al volante solo "boing"
		return
	corazones -= 1
	racha = 0
	if cfg["arma_baja_al_golpe"]:
		arma = maxi(1, arma - 1)
	match str(cfg.get("multiplicador_golpe", "")):
		"mitad":
			multiplicador = maxi(1, multiplicador / 2)
		"uno":
			multiplicador = 1
	if corazones <= 0:
		_derrota()
		return
	invulnerable = float(cfg["invulnerable"])
	_evento("golpe", {"pos": nave, "corazones": corazones})


# --- derrota y "¡otra vez!" (§7) -----------------------------------------------------

func _derrota() -> void:
	_fase_antes_gag = "jefe" if not jefe.is_empty() else "juego"
	fase = "gag"
	t_fase = 0.0
	balas_enemigas.clear()
	balas.clear()
	_evento("derrota", {"pos": nave})
	_evento("voz", {"clave": "viaje_cometa_mareado"})


func _reiniciar() -> void:
	reinicios += 1
	derrotas_seguidas += 1
	fase = "reinicio"
	t_fase = 0.0
	regalo = derrotas_seguidas >= int(cfg["regalo_tras"])
	var tras := int(cfg["ayuda_fuerte_tras"])
	if tras > 0 and derrotas_seguidas >= tras and not volante:
		volante = true
		iman = 9999.0
		_evento("voz", {"clave": "viaje_cometa_al_volante"})
	elif descanso_pendiente():
		_evento("voz", {"clave": "viaje_descanso"})
	elif regalo:
		_evento("voz", {"clave": "viaje_regalo"})
	else:
		_evento("voz", {"clave": "viaje_otra_vez"})
	_ir_a_checkpoint(true)
	_evento("reinicio", {"pos": nave, "regalo": regalo})


func descanso_pendiente() -> bool:
	var tras := int(cfg["descanso_tras"])
	return tras > 0 and derrotas_seguidas >= tras


func _ir_a_checkpoint(es_reinicio: bool) -> void:
	enemigos.clear()
	balas_enemigas.clear()
	balas.clear()
	_formaciones.clear()
	objetos.clear()
	_cerrando_sector = false
	_esperando_vacia = false
	nave = POS_INICIO
	corazones = corazones_max
	invulnerable = 1.2
	if es_reinicio:
		arma = 2 if regalo else 1
		escudo = bool(cfg["escudo_por_sector"]) or regalo
		puntaje = 0
		multiplicador = 1
		racha = 0
		vidas_extra_dadas = 0
		if not es_maxi():
			destellos_en_juego = 0      # §9.2: Maxi conserva los del sector en curso [Confirmar PO]
	sector = int(checkpoint["sector"])
	oleada = int(checkpoint["oleada"])
	jefe = {}
	if sector >= n_sectores():
		_preparar_jefe()
		return
	_fase_antes_gag = "juego"
	fase = "juego" if not es_reinicio else "reinicio"
	if oleada == 0:
		_empezar_sector()
	else:
		_espera = 1.5


# --- el jefe: artefacto del Coleccionauta (§5.3) ----------------------------------------

func _preparar_jefe() -> void:
	var j: Dictionary = ruta.get("jefe", {})
	var fases: Array = j.get("fases", [["rebota", "abre"]])
	jefe = {"id": str(j.get("id", "meteorito_dormilon")), "pos": Vector2(1500, 360), "vida": int(j.get("vida", 80)),
			"vida_max": int(j.get("vida", 80)), "fases": fases, "fase": 0, "patron": 0, "estado": "entra",
			"t": -2.5, "radio": 105.0, "debil": false, "proyectil": str(j.get("proyectil", "piedrita")),
			"dir": 1.0, "base": Vector2(1010, 360), "tiros": 0, "empujando": false, "golpe_t": 0.0, "marcas": []}
	if fase != "reinicio":
		fase = "jefe"
	_fase_antes_gag = "jefe"
	_evento("voz", {"clave": "viaje_aviso_jefe", "retraso": 0.6})     # en el checkpoint, con pantalla vacía


func _patrones() -> Array:
	return jefe["fases"][jefe["fase"]]


func _actualizar_jefe(dt: float) -> void:
	if jefe.is_empty():
		return
	jefe["t"] += dt
	jefe["golpe_t"] = maxf(0.0, jefe["golpe_t"] - dt)
	var rapido := 1.25 if jefe["fase"] == 1 else 1.0
	var aviso := float(cfg["aviso"])
	match str(jefe["estado"]):
		"entra":
			if jefe["t"] > 0.0:
				jefe["pos"] = jefe["pos"].move_toward(jefe["base"], 380 * dt)
				if jefe["pos"].distance_to(jefe["base"]) < 2:
					_evento("jefe_listo")
					_siguiente_patron(false)
		"aviso":
			if jefe["t"] >= aviso:
				jefe["estado"] = "ataca"
				jefe["t"] = 0.0
				jefe["tiros"] = 0
		"ataca":
			_atacar(dt * rapido)
		"debil":
			jefe["pos"] = jefe["pos"].move_toward(jefe["base"], 200 * dt)
			if int(jefe["t"] / 0.5) != int((jefe["t"] - dt) / 0.5):
				_evento("tic", {"pos": punto_debil()})      # M12: sonido guía del punto débil
			if jefe["t"] >= (3.2 if es_maxi() else 2.4):
				jefe["debil"] = false
				_siguiente_patron(true)
		"vencido":
			if jefe["t"] > 1.4:
				_empezar_encuentro()


func _siguiente_patron(avanzar: bool) -> void:
	if avanzar:
		jefe["patron"] = (jefe["patron"] + 1) % _patrones().size()
	jefe["estado"] = "aviso"
	jefe["t"] = 0.0
	jefe["empujando"] = false
	_evento("aviso_jefe", {"patron": _patrones()[jefe["patron"]], "pos": jefe["pos"]})


func _atacar(dt: float) -> void:
	var patron: String = _patrones()[jefe["patron"]]
	var t: float = jefe["t"]
	var dur := 3.2
	var vel := maxf(160.0, float(cfg["bala_velocidad"]) * 1.15)
	match patron:
		"rebota", "abre":
			var v := 170.0 if es_maxi() else 260.0
			jefe["pos"].y += jefe["dir"] * v * dt
			if jefe["pos"].y < 190 or jefe["pos"].y > 590:
				jefe["dir"] = -jefe["dir"]
				jefe["pos"].y = clampf(jefe["pos"].y, 190, 590)
				_evento("rebote_jefe", {"pos": jefe["pos"]})
			if patron == "abre" and int(t / 0.8) != int((t - dt) / 0.8):
				_evento("confeti_jefe", {"pos": jefe["pos"]})     # §5.3: cae y no daña a Maxi
		"lanza_fila":
			var n := 5 if perfil_id == "estrella" else 4
			if jefe["tiros"] < n and t >= jefe["tiros"] * 0.4:
				jefe["tiros"] += 1
				var dir: Vector2 = (nave - jefe["pos"]).normalized() if cfg["bala_apuntada"] else Vector2.LEFT
				_bala_enemiga(jefe["pos"] + Vector2(-90, 0), dir * vel, jefe["proyectil"])
		"abanico":
			if jefe["tiros"] < 2 and t >= jefe["tiros"] * 1.2:
				jefe["tiros"] += 1
				var dir: Vector2 = (nave - jefe["pos"]).normalized() if cfg["bala_apuntada"] else Vector2.LEFT
				_abanico(jefe["pos"], dir, vel * 0.9, 5 if perfil_id == "estrella" else 3)
		"embiste":
			if t < 0.05:
				jefe["objetivo"] = Vector2(320, nave.y)
			if t < 1.4:
				jefe["pos"] = jefe["pos"].move_toward(jefe["objetivo"], 700 * dt)
			else:
				jefe["pos"] = jefe["pos"].move_toward(jefe["base"], 520 * dt)
			dur = 2.8
		"empuje":
			jefe["empujando"] = t > 0.2 and t < 2.6
			if jefe["tiros"] < 3 and t >= 0.6 + jefe["tiros"] * 0.8:
				jefe["tiros"] += 1
				_bala_enemiga(jefe["pos"] + Vector2(-90, rng.randf_range(-60, 60)),
						Vector2(-vel * 0.8, rng.randf_range(-40, 40)), jefe["proyectil"])
		"lluvia":
			# §5.3: caen desde arriba en lugares avisados (la marca brilla antes)
			if jefe["tiros"] < 5 and t >= jefe["tiros"] * 0.5:
				jefe["tiros"] += 1
				var x := clampf(nave.x + rng.randf_range(-260, 260), 380, 900)
				_bala_enemiga(Vector2(x, -40), Vector2(0, vel * 0.9), jefe["proyectil"])
	if jefe["t"] >= dur:
		jefe["empujando"] = false
		jefe["estado"] = "debil"
		jefe["debil"] = true
		jefe["t"] = 0.0
		_evento("debil_abre", {"pos": punto_debil()})


func punto_debil() -> Vector2:
	return jefe["pos"] + Vector2(-70, 10)


func _golpear_jefe(p: Vector2) -> bool:
	if jefe["estado"] == "entra":
		return false
	var en_debil: bool = jefe["debil"] and p.distance_to(punto_debil()) < 52
	if not en_debil and p.distance_to(jefe["pos"]) > jefe["radio"]:
		return false
	var dano := 3 if en_debil else 1
	jefe["vida"] -= dano
	jefe["golpe_t"] = 0.08
	_impacto(p)
	if en_debil:
		_pedir_hitstop()
		_sumar(PUNTOS["punto_debil"], false)
		_evento("golpe_debil", {"pos": p})
	if jefe["fase"] == 0 and jefe["fases"].size() > 1 and jefe["vida"] <= jefe["vida_max"] / 2:
		jefe["fase"] = 1
		jefe["patron"] = 0
		_evento("jefe_fase_2", {"pos": jefe["pos"]})
	if jefe["vida"] <= 0:
		_vencer_jefe()
	return true


func _vencer_jefe() -> void:
	jefe["estado"] = "vencido"
	jefe["t"] = 0.0
	jefe["debil"] = false
	jefe["empujando"] = false
	balas_enemigas.clear()
	enemigos.clear()
	_sumar(PUNTOS["jefe"], false)
	destellos_consolidados += 1 + destellos_en_juego      # §9.2: +1 al vencer el artefacto
	destellos_en_juego = 0
	derrotas_seguidas = 0
	descanso_visible = false
	_evento("jefe_vencido", {"pos": jefe["pos"], "id": jefe["id"]})


# --- el Coleccionauta (§8) ---------------------------------------------------------------

func _empezar_encuentro() -> void:
	var c: Dictionary = ruta.get("coleccionauta", {})
	jefe = {}
	fase = "encuentro"
	t_fase = 0.0
	var bolsas := []
	for off in [Vector2(-110, 115), Vector2(0, 140), Vector2(110, 115)]:
		bolsas.append({"off": off, "viva": true})
	colec = {"pos": Vector2(1450, 250), "estado": "entra", "t": 0.0, "bolsas": bolsas,
			"provoca": str(c.get("provoca", "")), "huye": str(c.get("huye", "")),
			"pinza": Vector2.ZERO, "pinza_activa": false, "pinza_enredo": false}


func _actualizar_encuentro(dt: float) -> void:
	colec["t"] += dt
	var t: float = colec["t"]
	var casa := Vector2(930, 220)
	match str(colec["estado"]):
		"entra":
			colec["pos"] = colec["pos"].move_toward(casa, 420 * dt)
			if colec["pos"].distance_to(casa) < 2 and t > 0.8:
				_cambiar_colec("provoca")
				_evento("voz", {"clave": colec["provoca"], "quien": "coleccionauta"})
		"provoca":
			colec["pos"].y = casa.y + sin(t * 2.0) * 14
			# N-A5: primero termina la voz `provoca`, después se telegrafía la pinza
			if t > 0.6 and not voz_sonando:
				_cambiar_colec("aviso_pinza")
				_evento("aviso_pinza", {"pos": colec["pos"]})
		"aviso_pinza":
			if t >= float(cfg["pinza_aviso"]):
				_cambiar_colec("pinza")
				colec["pinza_activa"] = true
				colec["pinza"] = colec["pos"] + Vector2(-40, 60)
				colec["pinza_obj"] = nave
		"pinza":
			var ida := t < 1.0
			var destino: Vector2 = colec["pinza_obj"] if ida else colec["pos"] + Vector2(-40, 60)
			colec["pinza"] = colec["pinza"].move_toward(destino, (520 if ida else 700) * dt)
			if not colec["pinza_enredo"] and colec["pinza"].distance_to(nave) < 50 + float(cfg["radio_nave"]):
				colec["pinza_enredo"] = true        # Pg: sin daño y la nave sigue obedeciendo al dedo
				_evento("gag_pinza", {"pos": nave})
			if t > 2.0:
				colec["pinza_activa"] = false
				_cambiar_colec("bolsas")
		"bolsas":
			colec["pos"].y = casa.y + sin(t * 2.0) * 14
			var quedan := (colec["bolsas"] as Array).any(func(b): return b["viva"])
			if t > (4.0 if es_maxi() else 3.0) or (not quedan and t > 0.8):
				_cambiar_colec("huye")
				_evento("voz", {"clave": colec["huye"], "quien": "coleccionauta"})
				_evento("huye", {"pos": colec["pos"]})
				for o in objetos:       # lo que cayó de las bolsas se va solito a la nave
					o["atraer"] = true
		"huye":
			colec["pos"] = colec["pos"].move_toward(Vector2(840, 300), 260 * dt)
			colec["escala"] = maxf(0.1, 1.0 - t / 2.6)
			if t > 2.8 and objetos.is_empty():
				_terminar()


func _cambiar_colec(estado: String) -> void:
	colec["estado"] = estado
	colec["t"] = 0.0


func pos_bolsa(b: Dictionary) -> Vector2:
	return colec["pos"] + b["off"]


func _golpear_bolsa(p: Vector2, radio_extra := RADIO_BALA) -> bool:
	if colec["estado"] != "bolsas":
		return false     # se revientan después de la pinza (§8.1)
	for b in colec["bolsas"]:
		if b["viva"] and p.distance_to(pos_bolsa(b)) < float(cfg["bolsa_tam"]) * 0.5 + radio_extra:
			b["viva"] = false
			var pb := pos_bolsa(b)
			_evento("bolsa_revienta", {"pos": pb})
			objetos.append({"tipo": "destello", "pos": pb, "vel": Vector2(-40, 70), "t": 0.0, "sector": false})
			if not (colec["bolsas"] as Array).any(func(x): return x["viva"]):
				_evento("voz", {"clave": "viaje_bolsa_vacia", "quien": "coleccionauta"})
			return true
	return false


func _terminar() -> void:
	destellos_consolidados += destellos_en_juego
	destellos_en_juego = 0
	fase = "fin"
	t_fase = 0.0
	_evento("fin", resultados())


## Resumen para la pantalla de resultados y el guardado (§9, §10.1).
func resultados() -> Dictionary:
	var estrellitas := 0
	if perfil_id == "estrella":
		var u: Array = cfg["umbral_estrellitas"]
		estrellitas = 1
		if puntaje >= int(u[0]):
			estrellitas = 2
		if puntaje >= int(u[1]) and reinicios == 0:
			estrellitas = 3
	var extra := 1 if estrellitas == 3 else 0
	var elegible := reinicios == 0
	return {"destellos": destellos_consolidados + extra, "puntaje": puntaje, "estrellitas": estrellitas,
			"record_elegible": elegible, "record": elegible and puntaje > record_anterior,
			"primer_record": elegible and record_anterior == 0 and puntaje > 0, "reinicios": reinicios}


# --- objetos: cápsulas y destellos (§5.4, §9.2) --------------------------------------------

func _mover_objetos(dt: float) -> void:
	var radio_nave := float(cfg["radio_nave"])
	for o in objetos.duplicate():
		o["t"] += dt
		if o.get("atraer", false) or (iman > 0.0 and o["tipo"] == "destello"):
			o["pos"] = o["pos"].move_toward(nave, 900 * dt)
		else:
			o["pos"] += o["vel"] * dt
			if o["tipo"] == "capsula":
				o["pos"].y += sin(o["t"] * 2.5) * 30 * dt
			if o["tipo"] == "destello" and not o.get("sector", false):
				o["vel"].y = maxf(o["vel"].y - 60 * dt, 15.0)     # flota al caer de la bolsa
		var alcance := radio_nave + IMAN + (float(cfg["hitbox_destello"]) * 0.5 if o["tipo"] == "destello" else 30.0)
		if fase in ["juego", "jefe", "encuentro"] and o["pos"].distance_to(nave) < alcance:
			objetos.erase(o)
			_recoger(o)
		elif o["pos"].x < -80 or o["pos"].y > ALTO + 80:
			objetos.erase(o)


func _recoger(o: Dictionary) -> void:
	if o["tipo"] == "destello":
		destellos_en_juego += 1
		_evento("destello", {"pos": o["pos"]})
		return
	match str(o["cual"]):
		"arma":
			arma = mini(3, arma + 1)
		"minicometas":
			minicometas = 12.0
		"iman":
			iman = maxf(iman, 10.0)
		"escudo":
			escudo = true
		"corazon":
			corazones = mini(corazones_max, corazones + 1)
		"supernova":
			for e in enemigos.duplicate():
				_quitar_enemigo(e, true)
				_sumar(int(PUNTOS.get(e["tipo"], 30)), true)
				_evento("rompe", {"pos": e["pos"], "tipo": e["tipo"], "grande": false})
			balas_enemigas.clear()
	_evento("capsula", {"pos": o["pos"], "cual": o["cual"]})


func _mover_balas(dt: float, _dt_enemigos: float) -> void:
	for b in balas:
		b["pos"] += b["vel"] * dt
	balas = balas.filter(func(b): return b["pos"].x < ANCHO + 40 and b["pos"].y > -40 and b["pos"].y < ALTO + 40)


func _evento(tipo: String, datos := {}) -> void:
	datos["tipo"] = tipo
	eventos.append(datos)


## La escena vacía la cola de eventos una vez por cuadro.
func sacar_eventos() -> Array:
	var e := eventos
	eventos = []
	return e
