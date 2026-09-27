extends Node2D

## "Viaje estelar" en PIXEL ART: el minijuego que se juega al viajar de un planeta a otro
## (pedido directo del PO; el mapa estelar lo lanza al tocar un planeta, 27-Sep-2026).
## Tres partes, todas sin texto:
##   1. DESPEGUE desde el planeta de origen: la nave está sobre su plataforma, en el
##      paisaje propio de ese planeta (la casita de los niños en la Tierra, palmeras y
##      animalitos en Animalia...). Tres luces se encienden (o el niño toca para despegar
##      ya), la nave sube, el cielo se vuelve espacio y el planeta queda abajo, curvo.
##   2. VIAJE por el espacio: el niño toca o arrastra para mover la nave, recoge destellos
##      y esquiva rocas y satélites.
##   3. ATERRIZAJE en el planeta de destino: aparece, la nave entra a su cielo y baja
##      despacito a la plataforma, y los habitantes del planeta celebran la llegada.
## Origen y destino cambian el paisaje, el horizonte, la bolita de la barra de trayecto y
## la celebración: no es lo mismo salir de la Tierra que llegar a Melodía.
##
## Reglas de UX (GDD §6): nada castiga, apura ni frustra.
## - Chocar NO es perder: la nave hace un "trompo" gracioso, la roca rebota con un
##   "boing", a Cometa le giran estrellitas de mareo y los destellos que se sueltan
##   quedan flotando cerca para volver a recogerlos. Nunca hay "game over": el viaje
##   siempre llega al planeta.
## - Maxi (semilla): pocos obstáculos, lentos, que además SE APARTAN solos de la nave;
##   chocar no suelta destellos. Nicole (brote): más rocas y satélites; suelta 1.
##   Sofía (estrella): más rápido, lluvias de meteoritos, la nave se mueve también hacia
##   adelante/atrás; suelta 2.
##
## Emite `completado(destellos)` cuando termina la celebración del aterrizaje.
##
## Ver en movimiento (perfil = hermano; viaje=origen,destino; duracion_viaje acorta la
## parte del espacio para revisar despegue y aterrizaje):
##   bash herramientas/ojos.sh escena=res://escenas/nucleo/viaje_estelar.tscn perfil=nicole \
##        viaje=tierra,arcoiris duracion_viaje=4 tiempos=0.5,2.5,4,5.5,7,14,17,19

signal completado(destellos: int)

const Arte := preload("res://scripts/nucleo/arte_pixel.gd")

const ESCALA := 4
const ANCHO := 320
const ALTO := 180
const TECHO := 26          # debajo de la barra de trayecto
const RADIO_NAVE := 10.0   # caja de choque indulgente: más chica que el dibujo
const RADIO_COMETA := 6.0

## Paisaje: la textura de suelo empieza en SUELO_Y; la superficie queda ~50 px más abajo.
const SUELO_Y := 100
const PLATAFORMA_ORIGEN := 100
const PLATAFORMA_DESTINO := 160
## Radio del planeta visto desde muy cerca (horizonte curvo al despegar y aterrizar).
const RADIO_HORIZONTE := 200
## Altura (en px de cámara) a la que el paisaje ya quedó abajo y empieza el espacio.
const ELEVACION_MAX := 320.0
const CUENTA := 2.8        # 3 luces antes de despegar (tocar la pantalla lo adelanta)
const SUBIDA := 5.2
const BAJADA := 5.0
const FIESTA := 3.4        # celebración en el planeta de destino antes de terminar

const NIVELES := {
	"semilla": {
		"duracion": 35.0, "obstaculo_cada": [3.4, 4.6], "velocidad": 26.0,
		"satelites": false, "lluvias": false, "se_apartan": true, "suelta": 0,
		"radio_recoger": 20.0, "mueve_x": false,
	},
	"brote": {
		"duracion": 45.0, "obstaculo_cada": [1.9, 2.8], "velocidad": 34.0,
		"satelites": true, "lluvias": false, "se_apartan": false, "suelta": 1,
		"radio_recoger": 17.0, "mueve_x": false,
	},
	"estrella": {
		"duracion": 55.0, "obstaculo_cada": [1.15, 1.8], "velocidad": 44.0,
		"satelites": true, "lluvias": true, "se_apartan": false, "suelta": 2,
		"radio_recoger": 15.0, "mueve_x": true,
	},
}

const SFX_LUZ := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_DESPEGUE := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_DESTELLO := "res://assets/audio/sfx/ui/seleccionar.ogg"
const SFX_ATERRIZAJE := "res://assets/audio/sfx/ui/abrir.ogg"
## Chiptune original (herramientas/componer_chiptune.py): loop del viaje y fanfarria al aterrizar.
const MUSICA_VIAJE := "res://assets/audio/musica/viaje_estelar.ogg"
const MUSICA_LLEGADA := "res://assets/audio/musica/llegada_planeta.ogg"

## Perfil de dificultad; vacío = el del hermano seleccionado en `Progreso`.
@export var perfil_dificultad: String = ""
## Planeta desde donde se despega y donde se aterriza (ids de `mapa_estelar.gd`).
@export var planeta_origen: String = ""
@export var planeta_destino: String = ""

var _cfg: Dictionary
var _tex := {}
var _rng := RandomNumberGenerator.new()

var _fase := "despegue"    # despegue -> viaje -> llegada -> aterrizaje -> fin
var _t := 0.0
var _fase_t := 0.0         # segundos dentro de la fase actual
var _recorrido := 0.0      # segundos de viaje transcurridos
var _elevacion := 0.0      # altura de la "cámara" sobre el paisaje (despegue/aterrizaje)
var _nave := Vector2(PLATAFORMA_ORIGEN, 137)
var _objetivo := Vector2(70, 100)
var _inclinacion_extra := 0.0
var _chorros := 0.0        # fuerza de los chorros de abajo (despegar/aterrizar)
var _giro := 0.0           # trompo tras un choque (radianes que faltan)
var _invulnerable := 0.0
var _mareo := 0.0
var _temblor := 0.0
var _salto_cometa := 0.0
var _flash := 0.0          # destello blanco al entrar a la atmósfera del destino
var _luces := 0
var _recogidos := 0
var _proximo_obstaculo := 1.4
var _proximo_destello := 0.5
var _proxima_hilera := 7.0
var _proxima_lluvia := 14.0
var _llegada := 0.0
var _estrellas_fondo: Array = []   # [pos, capa]
var _obstaculos: Array = []        # {tipo, pos, vel, radio, ang, vang, golpeado}
var _destellos: Array = []         # {pos, vel, fase, espera}
var _chispas: Array = []           # {pos, vel, vida, color}
var _humo: Array = []              # {pos, vel, vida, radio}
var _aros: Array = []              # {pos, radio}
var _completado_emitido := false


func _ready() -> void:
	_rng.seed = 11
	scale = Vector2(ESCALA, ESCALA)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_leer_argumentos()
	_cfg = NIVELES[_elegir_perfil()].duplicate()
	var duracion_prueba := _argumento("duracion_viaje")
	if duracion_prueba != "":
		_cfg["duracion"] = maxf(4.0, float(duracion_prueba))
	_tex["cometa"] = Arte.desde_grilla(Arte.COMETA)
	_tex["destello"] = Arte.desde_grilla(Arte.DESTELLO)
	_tex["roca"] = Arte.desde_grilla(Arte.ROCA)
	_tex["roca_chica"] = Arte.desde_grilla(Arte.ROCA_CHICA)
	_tex["satelite"] = Arte.desde_grilla(Arte.SATELITE)
	_tex["nave"] = Arte.construir_nave()
	_tex["perrito"] = Arte.desde_grilla(Arte.PERRITO)
	_tex["gatito"] = Arte.desde_grilla(Arte.GATITO)
	_tex["conejito"] = Arte.desde_grilla(Arte.CONEJITO)
	_tex["corazon"] = Arte.desde_grilla(Arte.CORAZON)
	_tex["nota"] = Arte.desde_grilla(Arte.NOTA)
	_tex["destino"] = Arte.construir_mundo(planeta_destino, 30)
	_tex["destino_mini"] = Arte.construir_mundo(planeta_destino, 6)
	_tex["origen_mini"] = Arte.construir_mundo(planeta_origen, 6)
	_tex["origen_lejos"] = Arte.construir_mundo(planeta_origen, 24)
	for lugar in ["origen", "destino"]:
		var id: String = planeta_origen if lugar == "origen" else planeta_destino
		var plataforma := PLATAFORMA_ORIGEN if lugar == "origen" else PLATAFORMA_DESTINO
		_tex["cielo_" + lugar] = Arte.construir_cielo(id)
		_tex["suelo_" + lugar] = Arte.construir_suelo(id, plataforma)
		_tex["horizonte_" + lugar] = Arte.construir_mundo(id, RADIO_HORIZONTE, 64)
	for i in 90:
		_estrellas_fondo.append([Vector2(_rng.randf() * ANCHO, _rng.randf() * ALTO), i % 3])
	_nave = Vector2(PLATAFORMA_ORIGEN, _superficie(planeta_origen, PLATAFORMA_ORIGEN, 0.0) - 13)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_musica(MUSICA_VIAJE)


func _exit_tree() -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_musica()


## Origen/destino: los fija quien lanza el viaje (el mapa estelar). Para revisar a mano con
## `ojos` se aceptan `viaje=origen,destino` y `duracion_viaje=N` por línea de comandos.
func _leer_argumentos() -> void:
	var viaje := _argumento("viaje").split(",")
	if planeta_origen == "":
		planeta_origen = viaje[0] if viaje.size() == 2 else "tierra"
	if planeta_destino == "":
		planeta_destino = viaje[1] if viaje.size() == 2 else "arcoiris"


func _argumento(nombre: String) -> String:
	for argumento in OS.get_cmdline_user_args():
		if argumento.trim_prefix("--").begins_with(nombre + "="):
			return argumento.get_slice("=", 1)
	return ""


func _elegir_perfil() -> String:
	if perfil_dificultad in NIVELES:
		return perfil_dificultad
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.perfil_seleccionado != "":
		var perfil: String = progreso.obtener_perfil_dificultad(progreso.perfil_seleccionado)
		if perfil in NIVELES:
			return perfil
	return "brote"


func _sonar(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)


## Altura en pantalla de la superficie del planeta en la columna x.
func _superficie(id: String, plataforma: int, elevacion: float) -> float:
	return SUELO_Y + Arte.altura_con_plataforma(id, plataforma, plataforma) + elevacion


# --- bucle -----------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_fase_t += delta
	var velocidad: float = _cfg["velocidad"]
	var elevacion_antes := _elevacion
	match _fase:
		"despegue":
			_despegar()
		"viaje":
			_recorrido += delta
			_generar(delta)
			if _recorrido >= _cfg["duracion"]:
				_cambiar_fase("llegada")
		"llegada":
			_llegada += delta
			_objetivo = Vector2(170, 95)
			if _llegada > 3.2:
				_cambiar_fase("aterrizaje")
				_flash = 1.0
				# lo que quedaba en el espacio no entra a la atmósfera del planeta
				_destellos.clear()
				_obstaculos.clear()
				_nave = Vector2(110, 60)
		"aterrizaje":
			_aterrizar()
		"fin":
			if _fase_t > FIESTA and not _completado_emitido:
				_completado_emitido = true
				completado.emit(_recogidos)

	# estrellas: corren hacia la izquierda al volar; hacia abajo/arriba al subir/bajar
	var sube := _elevacion - elevacion_antes
	var corre := velocidad if _fase in ["viaje", "llegada"] else velocidad * 0.25
	for e in _estrellas_fondo:
		e[0].x -= [0.2, 0.45, 0.9][e[1]] * corre * delta
		e[0].y += [0.15, 0.3, 0.6][e[1]] * sube
		if e[0].x < -2:
			e[0] = Vector2(ANCHO + 2, _rng.randf() * ALTO)
		e[0].y = fposmod(e[0].y, ALTO)

	if _fase in ["viaje", "llegada"]:
		_mover_nave(delta)
	_mover_obstaculos(delta, velocidad)
	_mover_destellos(delta, velocidad)
	_mover_efectos(delta)
	queue_redraw()


func _cambiar_fase(fase: String) -> void:
	_fase = fase
	_fase_t = 0.0


func _despegar() -> void:
	var luces := clampi(int(_fase_t / (CUENTA / 3.0)), 0, 3)
	if luces > _luces:
		_luces = luces
		_sonar(SFX_LUZ if luces < 3 else SFX_DESPEGUE)
		if luces == 3:
			_temblor = 0.5
	var base_y := _superficie(planeta_origen, PLATAFORMA_ORIGEN, 0.0) - 13
	if _fase_t < CUENTA:
		_chorros = 0.25 * _luces
		_nave = Vector2(PLATAFORMA_ORIGEN, base_y + (0.5 if int(_t * 20.0) % 2 == 0 and _luces > 0 else 0.0))
		return
	var s := clampf((_fase_t - CUENTA) / SUBIDA, 0.0, 1.0)
	_elevacion = ELEVACION_MAX * pow(s, 2.2)
	_chorros = 1.0 - smoothstep(0.55, 0.9, s)
	var alza := 1.0 - pow(1.0 - clampf(s * 2.2, 0.0, 1.0), 3)
	var avanza := smoothstep(0.5, 1.0, s)
	_nave = Vector2(lerpf(PLATAFORMA_ORIGEN, 70, avanza), lerpf(base_y, 100, alza))
	_inclinacion_extra = -0.32 * sin(PI * s)
	if _fase_t < CUENTA + 1.4 and _rng.randf() < 0.7:
		_soplar_humo(Vector2(_nave.x + _rng.randf_range(-10, 14), _superficie(planeta_origen, PLATAFORMA_ORIGEN, _elevacion)))
	if s >= 1.0:
		_elevacion = ELEVACION_MAX
		_inclinacion_extra = 0.0
		_objetivo = _nave
		_cambiar_fase("viaje")


func _aterrizar() -> void:
	var s := clampf(_fase_t / BAJADA, 0.0, 1.0)
	_elevacion = ELEVACION_MAX * pow(1.0 - s, 2.2)
	var base_y := _superficie(planeta_destino, PLATAFORMA_DESTINO, 0.0) - 13
	var llega := smoothstep(0.0, 1.0, s)
	_nave = Vector2(lerpf(110, PLATAFORMA_DESTINO, smoothstep(0.0, 0.6, s)), lerpf(60, base_y, llega))
	_inclinacion_extra = 0.18 * (1.0 - smoothstep(0.0, 0.7, s))
	_chorros = smoothstep(0.35, 0.6, s) * (1.0 - smoothstep(0.97, 1.0, s))
	if s > 0.8 and _rng.randf() < 0.6:
		_soplar_humo(Vector2(_nave.x + _rng.randf_range(-12, 14), _superficie(planeta_destino, PLATAFORMA_DESTINO, _elevacion)))
	if s >= 1.0:
		_elevacion = 0.0
		_inclinacion_extra = 0.0
		_cambiar_fase("fin")
		_temblor = 0.2
		_sonar(SFX_ATERRIZAJE)
		var audio := get_node_or_null("/root/Audio")
		if audio != null:
			audio.reproducir_musica(MUSICA_LLEGADA, false)
		for i in 3:
			_estallido(_nave + Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-30, -10)), 24, 50.0, 110.0)


func _soplar_humo(pos: Vector2) -> void:
	var lado := -1.0 if _rng.randf() < 0.5 else 1.0
	_humo.append({"pos": pos, "vel": Vector2(lado * _rng.randf_range(20, 45), _rng.randf_range(-8, -2)),
		"vida": _rng.randf_range(0.8, 1.4), "radio": _rng.randf_range(2.5, 4.5)})


func _generar(delta: float) -> void:
	_proximo_obstaculo -= delta
	_proximo_destello -= delta
	_proxima_hilera -= delta
	_proxima_lluvia -= delta
	var quedan: float = _cfg["duracion"] - _recorrido
	if _proximo_obstaculo <= 0 and quedan > 3.0:
		var rango: Array = _cfg["obstaculo_cada"]
		_proximo_obstaculo = _rng.randf_range(rango[0], rango[1])
		# el primer obstáculo viene a la altura de la nave: así se aprende a esquivar
		var y := _nave.y if _recorrido < 2.5 else _rng.randf_range(TECHO + 12, ALTO - 16)
		if _cfg["satelites"] and _rng.randf() < 0.35:
			_obstaculos.append({"tipo": "satelite", "pos": Vector2(ANCHO + 20, y), "vel": Vector2(-0.8, 0),
				"radio": 8.0, "ang": 0.0, "vang": 0.0, "golpeado": false, "fase": _rng.randf() * TAU})
		else:
			_obstaculos.append({"tipo": "roca", "pos": Vector2(ANCHO + 14, y), "vel": Vector2(-1.0, 0),
				"radio": 7.0, "ang": 0.0, "vang": _rng.randf_range(-0.6, 0.6), "golpeado": false, "fase": 0.0})
	if _cfg["lluvias"] and _proxima_lluvia <= 0 and quedan > 5.0:
		_proxima_lluvia = _rng.randf_range(11.0, 15.0)
		var hueco := _rng.randi_range(1, 4)  # siempre queda un hueco claro para pasar
		for i in 6:
			if i == hueco or i == hueco + 1:
				continue
			_obstaculos.append({"tipo": "roca_chica", "pos": Vector2(ANCHO + 10 + i * 9, TECHO + 10 + i * 24),
				"vel": Vector2(-1.25, 0.12), "radio": 4.5, "ang": 0.0, "vang": 1.2, "golpeado": false, "fase": 0.0})
	if _proximo_destello <= 0 and quedan > 2.0:
		_proximo_destello = _rng.randf_range(0.8, 1.4)
		_destellos.append({"pos": Vector2(ANCHO + 8, _rng.randf_range(TECHO + 10, ALTO - 14)),
			"vel": Vector2.ZERO, "fase": _rng.randf() * TAU, "espera": 0.0})
	if _proxima_hilera <= 0 and quedan > 4.0:
		_proxima_hilera = _rng.randf_range(8.0, 11.0)
		var y0 := _rng.randf_range(TECHO + 30, ALTO - 40)
		for i in 5:  # hilera en arco: premia seguirla con el dedo
			_destellos.append({"pos": Vector2(ANCHO + 8 + i * 16, y0 - sin(i / 4.0 * PI) * 18),
				"vel": Vector2.ZERO, "fase": i * 0.6, "espera": 0.0})


func _mover_nave(delta: float) -> void:
	var suave := 1.0 - exp(-4.0 * delta)
	_nave.y = lerpf(_nave.y, _objetivo.y, suave)
	if _cfg["mueve_x"] or _fase != "viaje":
		_nave.x = lerpf(_nave.x, _objetivo.x, suave)
	_nave.y = clampf(_nave.y, TECHO + 8, ALTO - 12)
	_nave.x = clampf(_nave.x, 30, 230)
	if _giro > 0:
		_giro = maxf(0.0, _giro - TAU / 0.8 * delta)


func _mover_obstaculos(delta: float, velocidad: float) -> void:
	var centro := _centro_nave()
	for o in _obstaculos.duplicate():
		o["pos"] += o["vel"] * velocidad * delta
		o["ang"] += o["vang"] * delta
		if o["tipo"] == "satelite" and not o["golpeado"]:
			o["pos"].y += sin(_t * 1.6 + o["fase"]) * 6.0 * delta
		if o["golpeado"]:
			o["vel"] *= 0.985
		elif _cfg["se_apartan"]:
			# ayuda para Maxi: lo que viene de frente se corre suavemente de su camino
			var dx: float = o["pos"].x - centro.x
			var dy: float = o["pos"].y - centro.y
			if dx > -4 and dx < 80 and absf(dy) < 28:
				var lado := 1.0 if dy >= 0 else -1.0
				if o["pos"].y < TECHO + 20:
					lado = 1.0
				elif o["pos"].y > ALTO - 20:
					lado = -1.0
				o["pos"].y += lado * 34.0 * delta
		if not o["golpeado"] and _invulnerable <= 0 and _fase == "viaje" and (
				o["pos"].distance_to(centro) < RADIO_NAVE + o["radio"]
				or o["pos"].distance_to(_centro_cometa()) < RADIO_COMETA + o["radio"]):
			_chocar(o)
		var p: Vector2 = o["pos"]
		if p.x < -30 or p.x > ANCHO + 60 or p.y < -30 or p.y > ALTO + 30:
			_obstaculos.erase(o)


func _mover_destellos(delta: float, velocidad: float) -> void:
	var centro := _centro_nave()
	var radio: float = _cfg["radio_recoger"]
	for d in _destellos.duplicate():
		d["espera"] = maxf(0.0, d["espera"] - delta)
		if d["vel"].length() > 1.0:  # destello soltado en un choque: vuela y se frena
			d["pos"] += d["vel"] * delta
			d["vel"] *= 0.92
			d["pos"].x -= 0.25 * velocidad * delta
		else:
			d["pos"].x -= 0.8 * velocidad * delta
		d["pos"].y += sin(_t * 2.0 + d["fase"]) * 8.0 * delta
		d["pos"].y = clampf(d["pos"].y, TECHO + 6, ALTO - 8)
		if d["espera"] <= 0 and _fase in ["viaje", "llegada"] and (d["pos"].distance_to(centro) < radio + 10
				or d["pos"].distance_to(_centro_cometa()) < radio):
			_recoger(d)
		elif d["pos"].x < -10:
			_destellos.erase(d)


func _mover_efectos(delta: float) -> void:
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_mareo = maxf(0.0, _mareo - delta)
	_temblor = maxf(0.0, _temblor - delta)
	_flash = maxf(0.0, _flash - delta * 1.8)
	_salto_cometa = maxf(0.0, _salto_cometa - delta * 2.0)
	if _fase == "fin" and _salto_cometa <= 0:
		_salto_cometa = 1.0  # en la fiesta final Cometa salta sin parar
	for a in _aros.duplicate():
		a["radio"] += 70.0 * delta
		if a["radio"] > 34:
			_aros.erase(a)
	for c in _chispas.duplicate():
		c["pos"] += c["vel"] * delta
		c["vel"] *= 0.94
		c["vida"] -= delta
		if c["vida"] <= 0:
			_chispas.erase(c)
	for h in _humo.duplicate():
		h["pos"] += h["vel"] * delta
		h["vel"] *= 0.96
		h["radio"] += 3.0 * delta
		h["vida"] -= delta
		if h["vida"] <= 0:
			_humo.erase(h)


func _centro_nave() -> Vector2:
	return _nave + Vector2(4, 2)


## Cometa vuela delante de la nave: también cuenta para chocar (si no, la roca lo
## atravesaría) y para recoger destellos.
func _centro_cometa() -> Vector2:
	return _nave + Vector2(43, -11)


# --- eventos ---------------------------------------------------------------------

func _recoger(destello: Dictionary) -> void:
	_destellos.erase(destello)
	_recogidos += 1
	_aros.append({"pos": destello["pos"], "radio": 4.0})
	_salto_cometa = 1.0
	_estallido(destello["pos"], 20, 45.0, 95.0)
	_sonar(SFX_DESTELLO)


## Choque amable: trompo + rebote + mareo; se sueltan (quizás) destellos recuperables.
func _chocar(obstaculo: Dictionary) -> void:
	var centro := _centro_nave()
	var lejos: Vector2 = (obstaculo["pos"] - centro).normalized()
	if lejos == Vector2.ZERO:
		lejos = Vector2.RIGHT
	obstaculo["golpeado"] = true
	obstaculo["vel"] = (lejos + Vector2(0.6, 0)).normalized() * 2.2  # "boing": sale rebotando
	obstaculo["vang"] = 7.0 * (1.0 if lejos.y >= 0 else -1.0)
	_giro = TAU
	_invulnerable = 1.6
	_mareo = 1.8
	_temblor = 0.25
	_objetivo.y = clampf(_nave.y - lejos.y * 22.0, TECHO + 8, ALTO - 12)
	_aros.append({"pos": (centro + obstaculo["pos"]) / 2.0, "radio": 3.0})
	var suelta := mini(int(_cfg["suelta"]), _recogidos)
	_recogidos -= suelta
	for i in suelta:
		var ang := -PI / 2 + (i - (suelta - 1) / 2.0) * 0.9
		_destellos.append({"pos": centro, "vel": Vector2.from_angle(ang) * 70.0 + Vector2(25, 0),
			"fase": _rng.randf() * TAU, "espera": 0.7})


func _estallido(pos: Vector2, cantidad: int, vmin: float, vmax: float) -> void:
	for i in cantidad:
		var ang := TAU * i / cantidad
		_chispas.append({
			"pos": pos, "vel": Vector2.from_angle(ang) * _rng.randf_range(vmin, vmax),
			"vida": _rng.randf_range(0.6, 1.1),
			"color": [Color("#ffd23f"), Color.WHITE, Color("#ff9ed6"), Color("#4fd8e0")][i % 4],
		})


func _unhandled_input(evento: InputEvent) -> void:
	var pos := Vector2.INF
	if evento is InputEventMouseButton and evento.pressed:
		pos = evento.position
	elif evento is InputEventMouseMotion and evento.button_mask & MOUSE_BUTTON_MASK_LEFT:
		pos = evento.position
	elif evento is InputEventScreenTouch and evento.pressed or evento is InputEventScreenDrag:
		pos = evento.position
	if pos == Vector2.INF:
		return
	if _fase == "despegue":
		# tocar durante la cuenta enciende las luces que faltan: despega de inmediato
		if _fase_t < CUENTA and _fase_t > 0.3:
			_fase_t = CUENTA
		return
	if _fase != "viaje":
		return
	var p := pos / ESCALA
	# tocar un destello lo recoge directo; tocar el cielo lleva la nave hacia ahí
	for d in _destellos:
		if d["espera"] <= 0 and d["pos"].distance_to(p) < _cfg["radio_recoger"]:
			_recoger(d)
			return
	_objetivo = Vector2(p.x - 20, p.y)


# --- dibujo ----------------------------------------------------------------------

func _draw() -> void:
	var sacudon := Vector2.ZERO
	if _temblor > 0:
		sacudon = Vector2(round(sin(_t * 90.0) * 2.0), round(cos(_t * 70.0)))
	draw_set_transform(sacudon)
	draw_rect(Rect2(-4, -4, ANCHO + 8, ALTO + 8), Color("#120a2c"))
	for i in 6:
		draw_rect(Rect2(0, 20 + i * 26, ANCHO, 13), Color(0.35, 0.18, 0.55, 0.06 + 0.02 * (i % 2)))
	for e in _estrellas_fondo:
		var brillo: float = 0.35 + 0.3 * e[1] + 0.2 * sin(_t * 3.0 + e[0].y)
		draw_rect(Rect2(e[0].floor(), Vector2.ONE * (1 + int(e[1] == 2))), Color(1, 1, 1, brillo))

	if _fase == "despegue":
		_dibujar_paisaje("origen", planeta_origen, PLATAFORMA_ORIGEN, sacudon)
	elif _fase in ["aterrizaje", "fin"]:
		_dibujar_paisaje("destino", planeta_destino, PLATAFORMA_DESTINO, sacudon)
	elif _fase == "viaje" and _recorrido < 4.0:
		# el planeta de origen se aleja hacia la izquierda al empezar a volar
		var x := lerpf(40.0, -60.0, _recorrido / 4.0)
		draw_texture(_tex["origen_lejos"], Vector2(x - 25, 150 - 25 + _recorrido * 6.0))

	if _fase == "llegada":  # el planeta de destino aparece y crece
		var avance := clampf(_llegada / 3.0, 0.0, 1.0)
		var x := lerpf(ANCHO + 40, 250, 1.0 - pow(1.0 - avance, 3))
		draw_texture(_tex["destino"], Vector2(x - 31, 64))

	for d in _destellos:
		var pulso := 1.0 + 0.15 * sin(_t * 8.0 + d["fase"])
		var col := Color(1, 1, 1, 0.55 if d["espera"] > 0 else 1.0)
		draw_texture(_tex["destello"], (d["pos"] - Vector2(6, 6) * pulso).floor(), col)

	for o in _obstaculos:
		var tex: Texture2D = _tex[o["tipo"]]
		var inclinacion: float = o["ang"] if o["tipo"] != "satelite" else o["ang"] + 0.15 * sin(_t + o["fase"])
		draw_set_transform(o["pos"].floor() + sacudon, inclinacion)
		draw_texture(tex, -(tex.get_size() / 2.0).floor())
		draw_set_transform(sacudon)

	for h in _humo:
		_circulo_pixel(h["pos"] + sacudon, h["radio"], Color(1, 1, 1, clampf(h["vida"], 0.0, 0.85)))
	_dibujar_nave(sacudon)

	for c in _chispas:
		draw_rect(Rect2(c["pos"].floor(), Vector2.ONE * 3), c["color"])
	for a in _aros:
		draw_arc(a["pos"], a["radio"], 0, TAU, 24, Color(1, 0.9, 0.4, 1.0 - a["radio"] / 34.0), 2.0)
	draw_set_transform(Vector2.ZERO)
	_dibujar_hud()
	if _flash > 0:
		draw_rect(Rect2(0, 0, ANCHO, ALTO), Color(1, 1, 1, _flash))


## Cielo, horizonte curvo, suelo, plataforma y habitantes del planeta. Todo baja con la
## elevación: al despegar el paisaje se va y queda el planeta redondo; al aterrizar, al revés.
func _dibujar_paisaje(lugar: String, id: String, plataforma: int, sacudon: Vector2) -> void:
	var e := _elevacion
	var cielo := 1.0 - clampf((e - 10.0) / 150.0, 0.0, 1.0)
	if cielo > 0:
		draw_texture(_tex["cielo_" + lugar], Vector2(0, e * 0.35).floor() + sacudon, Color(1, 1, 1, cielo))
	var y_suelo := SUELO_Y + e
	if y_suelo < ALTO:
		_dibujar_suelo(lugar, id, plataforma, y_suelo, sacudon)
	# el planeta curvo aparece recién cuando el suelo cercano ya se va por abajo, y va
	# encima de lo que queda del paisaje (si no, techos y árboles asoman sobre el planeta)
	var y_horizonte := 150.0 + maxf(0.0, e - 30.0) * 0.5
	var horizonte := clampf((e - 30.0) / 30.0, 0.0, 1.0)
	if y_horizonte < ALTO and horizonte > 0:
		draw_texture(_tex["horizonte_" + lugar], Vector2(160 - RADIO_HORIZONTE - 1, y_horizonte).floor() + sacudon, Color(1, 1, 1, horizonte))


func _dibujar_suelo(lugar: String, id: String, plataforma: int, y_suelo: float, sacudon: Vector2) -> void:
	draw_texture(_tex["suelo_" + lugar], Vector2(0, y_suelo).floor() + sacudon)
	var fiesta := 1.0 if _fase == "fin" else 0.0
	_dibujar_habitantes(id, y_suelo, plataforma, fiesta, sacudon)
	var sup := _superficie(id, plataforma, _elevacion)
	# plataforma de la nave con luces
	var base := Vector2(plataforma - 20, sup - 2).floor() + sacudon
	draw_rect(Rect2(base + Vector2(-1, -1), Vector2(42, 5)), Arte.CONTORNO)
	draw_rect(Rect2(base, Vector2(40, 3)), Color("#d6d6e6"))
	draw_rect(Rect2(base + Vector2(0, 2), Vector2(40, 1)), Color("#9a9ab4"))
	for i in 5:
		var prendida := int(_t * 4.0 + i) % 5 == 0 or _fase == "fin"
		draw_rect(Rect2(base + Vector2(3 + i * 8, 0), Vector2(2, 1)), Color("#ffd23f") if prendida else Color("#c98a12"))
	if lugar == "origen":
		# torrecita con las 3 luces de la cuenta (roja, amarilla, verde)
		var torre := Vector2(plataforma + 26, sup).floor() + sacudon
		draw_rect(Rect2(torre + Vector2(-1, -26), Vector2(4, 26)), Arte.CONTORNO)
		draw_rect(Rect2(torre + Vector2(0, -25), Vector2(2, 25)), Color("#d6d6e6"))
		var colores := [Color("#ff5f7a"), Color("#ffd23f"), Color("#5fe08a")]
		for i in 3:
			var centro := torre + Vector2(1, -22 + i * 7)
			_circulo_pixel(centro, 3.2, Arte.CONTORNO)
			var c: Color = colores[i] if _luces > 2 - i else Color(0.35, 0.3, 0.45)
			_circulo_pixel(centro, 2.2, c)
			if _luces > 2 - i:
				_circulo_pixel(centro, 5.0, Color(c, 0.25))


## Los que viven en cada planeta: se mueven un poquito siempre y, al aterrizar, celebran.
func _dibujar_habitantes(id: String, y_suelo: float, plataforma: int, fiesta: float, sacudon: Vector2) -> void:
	var suelo := func(x: float) -> float: return y_suelo + Arte.altura_con_plataforma(id, x, plataforma)
	var salto := func(i: int) -> float:
		return -absf(sin(_t * 7.0 + i * 1.3)) * 6.0 * fiesta - absf(sin(_t * 2.0 + i)) * 1.0
	match id:
		"animalia":
			var animales := [["perrito", 52.0], ["gatito", 236.0], ["conejito", 270.0]]
			for i in animales.size():
				var tex: Texture2D = _tex[animales[i][0]]
				var x: float = animales[i][1]
				var y: float = suelo.call(x) - tex.get_height() + 2 + salto.call(i)
				draw_texture(tex, Vector2(x - tex.get_width() / 2.0, y).floor() + sacudon)
		"melodia", "corazon":
			var tex: Texture2D = _tex["nota" if id == "melodia" else "corazon"]
			for i in 6:
				var ciclo := fposmod(_t * (0.25 + 0.3 * fiesta) + i / 6.0, 1.0)
				var x: float = [30.0, 60.0, 214.0, 244.0, 280.0, 300.0][i] + sin(_t * 2.0 + i) * 3.0
				var y: float = suelo.call(x) - 6 - ciclo * 50.0
				draw_texture(tex, Vector2(x, y).floor() + sacudon, Color(1, 1, 1, 1.0 - ciclo * ciclo))
		"cuenta_cuentas", "letralandia":
			var glifos := ["1", "2", "3"] if id == "cuenta_cuentas" else ["A", "B", "C"]
			var fondos := [Color("#ffd23f"), Color("#4fd8e0"), Color("#ff9ed6")]
			for i in 3:
				var x: float = [48.0, 232.0, 262.0][i]
				var y: float = suelo.call(x) - 11 + salto.call(i)
				var p := Vector2(x - 5, y).floor() + sacudon
				draw_rect(Rect2(p - Vector2.ONE, Vector2(11, 11)), Arte.CONTORNO)
				draw_rect(Rect2(p, Vector2(9, 9)), fondos[i])
				var filas: Array = Arte.GLIFOS[glifos[i]]
				for fy in filas.size():
					for fx in 3:
						if filas[fy][fx] == "#":
							draw_rect(Rect2(p + Vector2(3 + fx, 2 + fy), Vector2.ONE), Arte.CONTORNO)
		"arcoiris":
			for i in 8:  # brillitos alrededor de los chupetines
				var x: float = [22.0, 38.0, 206.0, 222.0, 280.0, 296.0, 250.0, 60.0][i]
				var y: float = suelo.call(x) - 28 - fposmod(i * 7.0, 12.0) + salto.call(i)
				if sin(_t * 5.0 + i * 2.1) > 0.2 - fiesta:
					draw_rect(Rect2(Vector2(x, y).floor() + sacudon, Vector2(2, 2)), Color.WHITE)
		"tierra":
			for i in 3:  # humito de la chimenea de la casa
				var ciclo := fposmod(_t * 0.4 + i / 3.0, 1.0)
				var p := Vector2(246 + ciclo * 8.0, suelo.call(246.0) - 34 - ciclo * 22.0)
				_circulo_pixel(p + sacudon, 1.5 + ciclo * 2.5, Color(1, 1, 1, 0.8 * (1.0 - ciclo)))


func _circulo_pixel(centro: Vector2, radio: float, color: Color) -> void:
	var r := int(ceil(radio))
	for dy in range(-r, r + 1):
		var ancho := int(floor(sqrt(maxf(0.0, radio * radio - dy * dy))))
		if ancho > 0 or absi(dy) < r:
			draw_rect(Rect2(floorf(centro.x) - ancho, floorf(centro.y) + dy, ancho * 2 + 1, 1), color)


func _dibujar_nave(sacudon: Vector2) -> void:
	# parpadeo suave mientras dura la protección tras un choque
	if _invulnerable > 0 and int(_t * 12.0) % 2 == 0:
		return
	var base := (_nave - Vector2(25, 16)).floor() + sacudon
	var en_tierra := _fase in ["despegue", "fin"] and _elevacion <= 0.0 and _chorros <= 0.0
	if not en_tierra:
		for i in 3:
			var centro: Vector2 = base + Arte.PROPULSORES[i]
			var largo := 5 + int(3 * abs(sin(_t * 18.0 + i * 1.7)))
			draw_rect(Rect2(centro + Vector2(-3 - largo, -1), Vector2(largo, 3)), Color("#ffab3d"))
			draw_rect(Rect2(centro + Vector2(-3 - largo / 2, 0), Vector2(largo / 2, 1)), Color("#fff27a"))
	if _chorros > 0.05:
		# chorros de abajo para despegar y aterrizar
		for dx in [-6, 12]:
			var largo := int((4 + 3 * absf(sin(_t * 22.0 + dx))) * _chorros * 2.0)
			var p := (_nave + Vector2(dx, 11)).floor() + sacudon
			draw_rect(Rect2(p + Vector2(-2, 0), Vector2(5, largo)), Color("#ffab3d"))
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, largo * 0.6)), Color("#fff27a"))
	var inclinacion := _inclinacion_extra - _giro
	if _fase in ["viaje", "llegada"]:
		inclinacion += clampf((_objetivo.y - _nave.y) * 0.01, -0.25, 0.25)
	draw_set_transform(_nave.floor() + sacudon, inclinacion)
	draw_texture(_tex["nave"], Vector2(-25, -16))
	draw_set_transform(sacudon)

	var cabeza := (_nave + Vector2(34, -22 + 3 * sin(_t * 2.5) - 10 * sin(_salto_cometa * PI))).floor() + sacudon
	draw_texture(_tex["cometa"], cabeza)
	if _mareo > 0:  # estrellitas de mareo girando sobre la cabeza de Cometa
		for i in 3:
			var ang := _t * 6.0 + TAU * i / 3.0
			var p := cabeza + Vector2(9, -2) + Vector2(cos(ang) * 9, sin(ang) * 3)
			draw_rect(Rect2(p.floor(), Vector2(2, 2)), Color("#ffd23f"))
			draw_rect(Rect2(p.floor() + Vector2(0, -1), Vector2(1, 1)), Color.WHITE)


func _dibujar_hud() -> void:
	# contador sin texto: una estrellita por destello, apiladas como un montoncito
	# (en vuelo, arriba a la izquierda; al llegar, todas en fila arriba al centro)
	if _fase == "fin":
		var n := mini(_recogidos, 36)
		var x0 := 160.0 - mini(n, 12) * 11 / 2.0
		for i in n:
			draw_texture(_tex["destello"], Vector2(x0 + (i % 12) * 11, 8 + (i / 12) * 9))
		return
	if _fase == "despegue" or _fase == "aterrizaje":
		return
	# barra de trayecto sin texto: planeta de origen -> nave -> planeta de destino
	var x0 := 108.0
	var x1 := 212.0
	for x in range(int(x0) + 8, int(x1) - 6, 4):
		draw_rect(Rect2(x, 11, 2, 1), Color(1, 1, 1, 0.45))
	draw_texture(_tex["origen_mini"], Vector2(x0 - 7, 4))
	draw_texture(_tex["destino_mini"], Vector2(x1 - 7, 4))
	var avance := clampf(_recorrido / _cfg["duracion"], 0.0, 1.0)
	var xn := lerpf(x0 + 6, x1 - 8, avance)
	draw_rect(Rect2(xn - 3, 9, 6, 4), Color("#8fdcc0"))
	draw_rect(Rect2(xn - 5, 10, 2, 2), Color("#ffab3d"))
	draw_rect(Rect2(xn + 3, 10, 1, 2), Color("#bfe8f5"))
	for i in mini(_recogidos, 27):
		draw_texture(_tex["destello"], Vector2(3 + (i % 9) * 10, 2 + (i / 9) * 8))
