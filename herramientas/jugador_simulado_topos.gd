extends RefCounted

## Jugador simulado de «¿Quién habla?» por edad (motor-topos.md §13.6): juega rondas completas contra
## `LogicaTopos` (sin pantalla) con un tiempo de reacción y una tasa de error configurables. Lo usan
## `herramientas/simular_topos.gd` (calibración: % de victorias y percentiles de aciertos y puntaje) y el arnés
## `qa_test_topos.gd`. Los parámetros son ESTIMACIONES de dev-godot (reacción auditiva de 2, 5 y 8 años
## sobre la de un adulto, como §1 de la ficha); se ajustan con el playtest real.

const PERFILES := {
	# media y desvío del tiempo de reacción (s) desde que suena el pedido, mínimo, prob. de no reconocerlo
	# (no toca y el pedido se escapa: el ~20 % de fallos que estima la ficha §8.1), prob. de tocar primero a
	# otro animal, prob. de distraerse (y cuánto), extra por leer y por sonidos parecidos.
	"semilla": {"rt": 2.5, "sd": 1.0, "min": 0.9, "omite": 0.3, "error": 0.35, "distraccion": 0.12, "dist_s": [2.0, 5.0], "leer": 0.0, "similar": 0.0, "dorado": 0.5, "impostor": 0.0},
	"brote": {"rt": 1.3, "sd": 0.4, "min": 0.55, "omite": 0.17, "error": 0.15, "distraccion": 0.04, "dist_s": [0.8, 2.0], "leer": 0.6, "similar": 0.15, "dorado": 0.6, "impostor": 0.0},
	"estrella": {"rt": 0.85, "sd": 0.22, "min": 0.45, "omite": 0.13, "error": 0.1, "distraccion": 0.03, "dist_s": [0.5, 1.5], "leer": 0.45, "similar": 0.12, "dorado": 0.7, "impostor": 0.15},
}
const DT := 0.05

var logica: LogicaTopos
var p: Dictionary
var rng := RandomNumberGenerator.new()
var _agenda: Array = []  ## {"t", "id", "animal"}
var _t := 0.0


func _init(l: LogicaTopos, perfil: String, semilla: int) -> void:
	logica = l
	p = PERFILES.get(perfil, PERFILES["brote"])
	rng.seed = semilla
	logica.sono.connect(_al_sonar)
	logica.asomo.connect(_al_asomar)
	logica.ayuda.connect(_al_ayudar)


func _reaccion() -> float:
	var rt := maxf(float(p["min"]), rng.randfn(float(p["rt"]), float(p["sd"])))
	if rng.randf() < float(p["distraccion"]):
		rt += rng.randf_range(float(p["dist_s"][0]), float(p["dist_s"][1]))
	return rt


func _al_sonar(id: int, animal: String, escrito: String, repite: bool) -> void:
	if repite:
		return
	if rng.randf() < float(p["omite"]):
		return
	var rt := _reaccion()
	if escrito != "":
		rt += float(p["leer"])
	var error := float(p["error"])
	if logica.madrigueras.any(func(m: Dictionary) -> bool: return m["animal"] in logica._pareja_de(animal) and m["estado"] != "abajo"):
		error += float(p["similar"])
	if logica.perfil == "estrella" and logica.modo == "continuo":
		error += 0.04  # ondas mínimas
	if rng.randf() < error:
		var otros: Array = logica.madrigueras.filter(func(m: Dictionary) -> bool:
			return m["estado"] in ["subiendo", "arriba"] and not m["pedido"] and m["tipo"] == "senuelo")
		if not otros.is_empty():
			var o: Dictionary = otros[rng.randi_range(0, otros.size() - 1)]
			_agenda.append({"t": _t + rt * 0.85, "id": o["id"], "animal": o["animal"]})
			rt += 0.4
	_agenda.append({"t": _t + rt, "id": id, "animal": animal})


func _al_asomar(id: int, animal: String, tipo: String) -> void:
	if tipo == "dorado" and rng.randf() < float(p["dorado"]):
		_agenda.append({"t": _t + _reaccion() * 0.8, "id": id, "animal": animal})
	elif tipo == "impostor" and rng.randf() < float(p["impostor"]):
		_agenda.append({"t": _t + _reaccion(), "id": id, "animal": animal})


## La ayuda de Semilla (el pedido salta a los 3 s, la mano a los 5 s) despierta al distraído.
func _al_ayudar(nivel: int, id: int) -> void:
	for a in _agenda:
		if a["id"] == id:
			a["t"] = minf(a["t"], _t + rng.randf_range(0.6, 1.6) / nivel)


## Juega una ronda entera. Devuelve {"gano", "aciertos", "puntaje", "escapes", "errores"}.
func jugar_ronda() -> Dictionary:
	logica.empezar()
	_agenda.clear()
	_t = 0.0
	var limite := (logica.duracion if logica.duracion > 0.0 else 300.0) + 5.0
	while logica.estado == "jugando" and _t < limite:
		_t += DT
		logica.avanzar(DT)
		var listos := _agenda.filter(func(a: Dictionary) -> bool: return a["t"] <= _t)
		_agenda = _agenda.filter(func(a: Dictionary) -> bool: return a["t"] > _t)
		for a in listos:
			var m: Dictionary = logica.madrigueras[a["id"]]
			if m["animal"] == a["animal"] and m["estado"] in ["subiendo", "arriba", "bajando"]:
				logica.tocar(a["id"])
	return {"gano": logica.gano, "aciertos": logica.aciertos, "puntaje": logica.puntaje,
		"escapes": logica.escapes, "errores": logica.errores}


static func percentil(valores: Array, q: float) -> float:
	var orden := valores.duplicate()
	orden.sort()
	if orden.is_empty():
		return 0.0
	return float(orden[clampi(int(round(q * (orden.size() - 1))), 0, orden.size() - 1)])
