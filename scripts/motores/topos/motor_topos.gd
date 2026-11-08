class_name MotorTopos
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecánica "topos" — «¿Quién habla?», tipo Whac-a-Mole (docs/fichas/motor-topos.md, con los
## valores [HE-124] de la política de derrota del PO del 05-Nov-2026). Primer juego del Planeta Animalia: los
## animales asoman de sus madrigueras en el claro de la selva; suena la voz de uno y hay que tocar al que habló
## antes de que se vuelva a esconder. Tocar es hacer cosquillas: nadie recibe golpes.
##
## Las reglas viven en `LogicaTopos` (sin pantalla, probadas por `herramientas/qa_test_topos.gd`); aquí hay
## dibujo, entrada, sonido y el flujo de rondas, gags y celebraciones. Todo lo que cambia entre hermanos llega
## en el JSON del nivel (`datos/niveles/animalia/<zona>/topos_<perfil>.json`).
##
## Entrada: responde al PRESIONAR (§2.1), con `InputEventScreenTouch` (en PC el clic llega emulado como toque:
## `emulate_touch_from_mouse`), así dos dedos cuentan por separado (§6). Arte y sonidos PROVISIONALES: animales,
## fondo y madrigueras dibujados por código (`dibujo_animales.gd`), sonidos sintetizados
## (`sonidos_animales.gd`) hasta el catálogo de HE-114 y los CC0. Toby y el Coleccionauta usan sus PNG.
##
## Derrota (los tres perfiles, GDD §6 regla 11): "¡Nos escondimos todos!" y reintento de un toque en cualquier
## parte. Regalo, ayuda fuerte (Maxi) y descanso según `regalo_tras_derrotas`, `ayuda_fuerte_tras_derrotas` y
## `descanso_tras_derrotas`. Las derrotas se cuentan seguidas por estación y duran toda la sesión (salir al mapa
## no las borra). Destellos y estrellitas solo al ganar.
##
## MODO EQUIPO (motor-topos.md §12.2; modo-equipo.md §11.4): un solo claro, el turno se mide en pedidos. Tope por
## perfil (`aciertos_max_turno`), el escape corta el turno (`terminar_turno(true)`), el error es fallo suave,
## Maxi juega sin escape y con jugada automática. Gana el equipo al juntar `aciertos_meta` de su composición.

signal ronda_jugada(gano: bool, puntaje: int)

const Logica := preload("res://scripts/motores/topos/logica_topos.gd")
const Dibujo := preload("res://scripts/motores/topos/dibujo_animales.gd")
const Sonidos := preload("res://scripts/motores/topos/sonidos_animales.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const BarraRecord := preload("res://scripts/ui/barra_record.gd")
const PistaConCosto := preload("res://scripts/ui/pista_con_costo.gd")
const TEXTURA_TOBY := preload("res://assets/sprites/personajes/toby_provisional.png")
const TEXTURA_COMETA := preload("res://assets/sprites/personajes/cometa_base.png")
const TEXTURA_COLECCIONAUTA := preload("res://assets/sprites/personajes/coleccionauta_provisional.png")
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"

const SFX_PLING := "sfx/ui/confirmar.ogg"
const SFX_PUF := "sfx/ui/puf.ogg"
const SFX_META := "sfx/ui/abrir.ogg"
const SFX_HUESO := "sfx/ui/toque.ogg"
const SFX_REINTENTAR := "sfx/ui/seleccionar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const TINTA := Color("#272140")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const VERDE := Color("#2E9E5B")
const TURQUESA := Color("#45C6C0")
const TIERRA := Color("#8A5A3C")
const TIERRA_OSCURA := Color("#4A2E22")

## Disposiciones de §4 (1280 × 720): centro de cada hoyo (línea del hoyo), ancho del hoyo, alto del animal y
## zona de toque (animal + hoyo; todas >= 96 px, GDD §6.1).
const DISPOSICIONES := {
	3: {"pos": [Vector2(440, 520), Vector2(740, 520), Vector2(1040, 520)], "hoyo": 240.0, "alto": 220.0, "toque": Vector2(270, 320)},
	4: {"pos": [Vector2(380, 500), Vector2(620, 500), Vector2(860, 500), Vector2(1100, 500)], "hoyo": 200.0, "alto": 190.0, "toque": Vector2(230, 290)},
	6: {"pos": [Vector2(440, 380), Vector2(740, 380), Vector2(1040, 380), Vector2(440, 600), Vector2(740, 600), Vector2(1040, 600)], "hoyo": 190.0, "alto": 170.0, "toque": Vector2(230, 220)},
	9: {"pos": [Vector2(470, 300), Vector2(720, 300), Vector2(970, 300), Vector2(470, 470), Vector2(720, 470), Vector2(970, 470), Vector2(470, 640), Vector2(720, 640), Vector2(970, 640)], "hoyo": 150.0, "alto": 140.0, "toque": Vector2(200, 165)},
}
## En equipo el tablero va de y 128 a 600 (modo-equipo.md §4.1): las filas se comprimen.
const ESCALA_EQUIPO := 0.86
const RECT_CASA_EQUIPO := Rect2(1172, 8, 100, 96)
const RECT_COMETA := Rect2(124, 12, 100, 100)
const RECT_TOBY := Rect2(36, 470, 210, 250)
const RECT_ANTENA := Rect2(170, 326, 96, 96)
const RECT_CARTEL := Rect2(470, 108, 340, 92)
const RECT_OREJA := Rect2(712, 106, 96, 96)
const CENTRO_TOBY := Vector2(140, 712)
const ALTO_TOBY := 232.0
const SEGUNDOS_GAG := 2.5
const SEGUNDOS_GAG_SEMILLA := 1.5
const SEGUNDOS_FIESTA := 2.4
const SEGUNDOS_ENTRE_RONDAS := 2.6
const PRESENTACION_DORADO := "topos_toby_dorado"
const PRESENTACION_IMPOSTOR := "topos_impostor"
## Semitonos del coro (acorde mayor, §7.5).
const ACORDE := [0, 4, 7, 12, 16, 19, 24, 28, 31]

## Derrotas seguidas por estación y hermano, durante la sesión (§10.3: salir al mapa no las borra).
static var derrotas_sesion: Dictionary = {}

@onready var _fondo: Control = %fondo
@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _fin: Control = %fin
@onready var _boton_salir: Button = %boton_salir
@onready var _confeti: CPUParticles2D = %confeti

var logica: LogicaTopos = Logica.new()
var sonidos = Sonidos.new()
var _fuente: Font
var _semilla := -1
var _perfil := "brote"
var _disp: Dictionary = {}
var _pos: Array[Vector2] = []  ## por madriguera (línea del hoyo)
var _ancho_hoyo := 200.0
var _alto_animal := 190.0
var _toque := Vector2(230, 290)
var _capas_animal: Array = []  ## Control con recorte por madriguera
var _capas_frente: Array = []
var _suelo: Control
var _efectos: Control
var _vis: Array = []  ## estado visual por madriguera
var _reproductores: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _info_animal: Dictionary = {}

var _t := 0.0
var _fase := "intro"  ## intro | jugando | entre_rondas | fiesta | celebrando | gag | perdio
var _ronda := 1
var _rondas := 1
var _puntaje_previo := 0
var _ondas := "completas"
var _ondas_nivel := "completas"
var _regalo := false
var _ayuda_fuerte := false
var _descanso_dicho := false
var _derrotas_previas := 0
var _pistas_usadas := 0
var _estrellas := 0
var _record := 0
var _record_nuevo := false
var _barra: Control
var _pista_costo: Control
var _boton_antena: Control
var _t_fase := 0.0
var _intento := 0

# Efectos y reacciones
var _particulas: Array = []  ## {"pos", "vel", "r", "color", "vida"}
var _textos: Array = []  ## {"pos", "texto", "color", "t", "dur", "tam"}
var _anillos: Array = []  ## ondas de sonido: {"pos", "t", "dur", "arcos", "alfa"}
var _vuelos: Array = []  ## huesos al collar: {"desde", "hasta", "t", "dur"}
var _hojitas: Array = []  ## {"pos", "t"}
var _mano: Dictionary = {}  ## mano fantasma: {"id", "t"}
var _cartel: Dictionary = {}  ## {"texto", "id", "t"}
var _toby := {"salto": 0.0, "ladeo": 0.0, "tapa": 0.0, "aplaude": 0.0, "empanado": 0.0, "orgulloso": false, "ladra": 0.0}
var _colita := 0.0
var _racha_vista := 0
var _collar_brillo := 0.0
var _fiesta: Dictionary = {}  ## id madriguera -> {"animal", "t0", "modo": coro|gag}

# Equipo
var _eq: Dictionary = {}
var _eq_meta := 14
var _eq_aciertos := 0
var _eq_victoria := false
var _eq_cerrando := false
var _eq_restaurado := false
var _eq_gag: Dictionary = {}  ## {"fase", "t", "dur", "destino", "animales": [{"animal", "desde"}]}
var _perfiles_equipo: Dictionary = {}


func _ready() -> void:
	super._ready()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	for i in 8:
		var r := AudioStreamPlayer.new()
		r.bus = "SFX"
		add_child(r)
		_reproductores.append(r)
	_estilizar_boton(_boton_salir, CREMA)
	_icono(_boton_salir, _dibujar_flecha)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_fondo.draw.connect(_dibujar_fondo)
	_hud.draw.connect(_dibujar_hud)
	_fin.draw.connect(_dibujar_fin)
	_configurar_confeti()
	_conectar_logica()
	if nivel.is_empty():
		push_error("motor_topos: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()
	if turnos != null:
		_preparar_equipo()
	else:
		_empezar_intento(true)


func fijar_semilla(semilla: int) -> void:
	_semilla = semilla


func fase() -> String:
	return _fase


func _conectar_logica() -> void:
	logica.aviso.connect(_al_aviso)
	logica.asomo.connect(_al_asomar)
	logica.sono.connect(_al_sonar)
	logica.acierto.connect(_al_acertar)
	logica.error.connect(_al_errar)
	logica.vacia.connect(_al_tocar_vacia)
	logica.escape.connect(_al_escapar)
	logica.dorado_tocado.connect(_al_tocar_dorado)
	logica.impostor_tocado.connect(_al_tocar_impostor)
	logica.doble_completo.connect(_al_completar_doble)
	logica.meta_llena.connect(_al_llenar_meta)
	logica.ayuda.connect(_al_ayudar)
	logica.ronda_terminada.connect(_al_terminar_ronda)


func _configurar_desde_nivel() -> void:
	_perfil = str(nivel.get("perfil", "brote"))
	_rondas = maxi(1, int(nivel.get("rondas", 1)))
	_ondas_nivel = str(nivel.get("ondas_visibles", "completas"))
	_ondas = _ondas_nivel
	for a in nivel.get("animales", []):
		if a is Dictionary:
			_info_animal[str(a.get("id", ""))] = a
	logica.configurar(nivel, _semilla)
	var n := logica.n_madrigueras
	_disp = DISPOSICIONES[n]
	_ancho_hoyo = float(_disp["hoyo"])
	_alto_animal = float(_disp["alto"])
	_toque = _disp["toque"]
	_pos.clear()
	for p in _disp["pos"]:
		_pos.append(p)
	if es_modo_equipo():
		for i in _pos.size():
			_pos[i] = Vector2(_pos[i].x, 140.0 + (_pos[i].y - 190.0) * ESCALA_EQUIPO)
		_ancho_hoyo *= ESCALA_EQUIPO
		_alto_animal *= ESCALA_EQUIPO
		_toque *= ESCALA_EQUIPO
	_crear_capas()
	# Sonidos del pool (y los efectos propios) sintetizados una vez al cargar: el primer toque responde < 100 ms.
	for id in logica.animales:
		_stream_animal(id)
	for id in ["toby", "risita_hoyo", "achis", "tierrita", "plop", "toby_dorado", "impostor", "fiuu"]:
		sonidos.stream(id)
	_record = obtener_record()
	if _perfil != "semilla" and not es_modo_equipo():
		_barra = BarraRecord.new()
		_hud.get_parent().add_child(_barra)
		_hud.get_parent().move_child(_barra, _hud.get_index())
		_barra.position = Vector2(1196, 128)
		_barra.size = Vector2(64, 470)
		var umbrales: Dictionary = nivel.get("umbrales_puntaje", {})
		_barra.preparar(_record, float(umbrales.get("tres", 3000)))
	if bool(nivel.get("pistas_cuestan_estrellita", false)) and not es_modo_equipo():
		_boton_antena = Control.new()
		_boton_antena.name = "boton_antena"
		_boton_antena.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_boton_antena.position = RECT_ANTENA.position
		_boton_antena.size = RECT_ANTENA.size
		_hud.get_parent().add_child(_boton_antena)
		_pista_costo = PistaConCosto.crear(_hud.get_parent(), _boton_antena, _estrellitas_en_vivo)
	_fondo.queue_redraw()


func _crear_capas() -> void:
	for c in _capas_animal + _capas_frente:
		c.queue_free()
	_capas_animal.clear()
	_capas_frente.clear()
	_vis.clear()
	if _suelo == null:
		_suelo = Control.new()
		_suelo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_juego.add_child(_suelo)
		_suelo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_suelo.draw.connect(_dibujar_suelo)
	for i in _pos.size():
		_vis.append({"habla": 0.0, "yo": 0.0, "salto_ayuda": 0.0, "celebra": 0.0, "cosquillas": 0.0, "descubierto": 0.0, "animal": "", "tipo": ""})
	# De atrás hacia adelante: la fila de arriba primero (su frente queda bajo los animales de la fila de abajo).
	var orden := range(_pos.size())
	orden.sort_custom(func(a: int, b: int) -> bool: return _pos[a].y < _pos[b].y)
	for i in orden:
		var capa := Control.new()
		capa.name = "animal_%d" % i
		capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa.clip_contents = true
		var ancho := _ancho_hoyo * 1.9
		var alto := _alto_animal * 2.2
		capa.position = Vector2(_pos[i].x - ancho / 2.0, _pos[i].y - alto)
		capa.size = Vector2(ancho, alto + 4.0)
		capa.draw.connect(_dibujar_animal.bind(capa, i))
		_juego.add_child(capa)
		var frente := Control.new()
		frente.name = "frente_%d" % i
		frente.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frente.position = _pos[i] - Vector2(_ancho_hoyo, 40.0)
		frente.size = Vector2(_ancho_hoyo * 2.0, 120.0)
		frente.draw.connect(_dibujar_frente.bind(frente, i))
		_juego.add_child(frente)
		_capas_animal.append(capa)
		_capas_frente.append(frente)
	if _efectos == null:
		_efectos = Control.new()
		_efectos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_efectos.draw.connect(_dibujar_efectos)
	if _efectos.get_parent() != null:
		_juego.remove_child(_efectos)
	_juego.add_child(_efectos)
	_efectos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ---------------------------------------------------------------------------
# Rondas, intentos y fin
# ---------------------------------------------------------------------------

func _clave_sesion() -> String:
	return "%s:%s" % [obtener_id_personaje(), _id_nivel_actual()]


func derrotas_seguidas() -> int:
	return int(derrotas_sesion.get(_clave_sesion(), 0))


## Un intento de la ronda actual: aplica el regalo o la ayuda fuerte según las derrotas seguidas.
func _empezar_intento(primera_vez: bool) -> void:
	_intento += 1
	var id_intento := _intento
	var config: Dictionary = nivel.duplicate(true)
	var derrotas := derrotas_seguidas()
	_regalo = false
	_ayuda_fuerte = false
	var af = nivel.get("ayuda_fuerte_tras_derrotas", null)
	var regalo = nivel.get("regalo_tras_derrotas", null)
	var linea := ""
	if af is Dictionary and derrotas >= int(af.get("derrotas", 3)):
		# Ayuda fuerte de Maxi (§10.3): el animal espera, sin reloj y con pocos pedidos: victoria asegurada.
		_ayuda_fuerte = true
		config["t_arriba_s"] = af.get("t_arriba_s", null)
		config["duracion_s"] = null
		config["pedidos"] = int(af.get("pedidos", 6))
		config["ayuda_idle_s"] = af.get("ayuda_idle_s", [2, 4])
		linea = "ayuda_fuerte"
	elif regalo is Dictionary and derrotas >= int(regalo.get("derrotas", 2)):
		# Regalo: Toby "ayuda olfateando": meta más corta y ondas completas.
		_regalo = true
		config["meta"] = maxi(1, ceili(float(nivel.get("meta", 1)) * float(regalo.get("meta_factor", 0.8))))
		linea = "regalo"
	_ondas = "completas" if _regalo or _ayuda_fuerte else _ondas_nivel
	logica.configurar(config, _semilla if _semilla < 0 else _semilla + _intento)
	logica.bajar_todos()
	_fiesta.clear()
	_cartel = {}
	_mano = {}
	_fin.hide()
	_fase = "intro"
	_t_fase = 0.0
	var voz := ""
	if primera_vez and _ronda == 1:
		voz = _ruta_voz("intro")
	elif linea != "":
		voz = _ruta_voz(linea)
	var espera := 0.9
	if voz != "" and ResourceLoader.exists(resolver_ruta_audio(voz)):
		reproducir_voz(voz)
		await get_tree().create_timer(0.3).timeout
		await _esperar_voz_libre(7.0)
		espera = 0.3
	if primera_vez and _ronda == 1:
		_texto_flotante(Vector2(640, 250), "¡Escucha y toca!", VERDE, 1.6, 52)
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree() or id_intento != _intento or _fase != "intro":
		return
	_fase = "jugando"
	logica.empezar()


func reintentar() -> void:
	if _fase != "perdio":
		return
	reproducir_sfx(SFX_REINTENTAR)
	_empezar_intento(false)


func _al_terminar_ronda(gano: bool, puntaje: int) -> void:
	ronda_jugada.emit(gano, puntaje)
	if turnos != null:
		return
	_cartel = {}
	_mano = {}
	if gano:
		derrotas_sesion[_clave_sesion()] = 0
		if _ronda < _rondas:
			_puntaje_previo += puntaje
			_entre_rondas()
		else:
			_victoria()
	else:
		_derrotas_previas += 1
		derrotas_sesion[_clave_sesion()] = derrotas_seguidas() + 1
		_derrota()


func puntaje_total() -> int:
	return _puntaje_previo + logica.puntaje


## Mini-fiesta entre rondas: coro, confeti chico y "¡Ronda 2!". La ronda ganada queda ganada.
func _entre_rondas() -> void:
	_fase = "entre_rondas"
	_coro("coro")
	_confeti.position = Vector2(740, 360)
	_confeti.restart()
	_confeti.emitting = true
	_texto_flotante(Vector2(740, 230), "¡Ronda %d!" % (_ronda + 1), Color("#FF8A3D"), SEGUNDOS_ENTRE_RONDAS, 64)
	_voz("ronda_2")
	var id := _intento
	await get_tree().create_timer(SEGUNDOS_ENTRE_RONDAS).timeout
	if not is_inside_tree() or id != _intento or _fase != "entre_rondas":
		return
	_ronda += 1
	_empezar_intento(false)


func _calcular_estrellitas() -> int:
	if _perfil == "semilla":
		return 0
	var umbrales: Dictionary = nivel.get("umbrales_puntaje", {})
	var total := puntaje_total()
	var e := 1
	if total >= int(umbrales.get("tres", 1 << 30)):
		e = 3
	elif total >= int(umbrales.get("dos", 1 << 30)):
		e = 2
	if _perfil == "estrella":
		e = maxi(1, e - _pistas_usadas)
		if _derrotas_previas > 0 and nivel.has("max_estrellitas_tras_derrota"):
			e = mini(e, int(nivel["max_estrellitas_tras_derrota"]))
	return e


func _estrellitas_en_vivo() -> int:
	return clampi(3 - _pistas_usadas, 1, 3)


func _victoria() -> void:
	_fase = "fiesta"
	_estrellas = _calcular_estrellitas()
	var destellos := 15 if _perfil == "semilla" else 10 + _estrellas * 5
	# Salir durante la fiesta no pierde la victoria (GDD §6 regla 8, QA HE-60 B1).
	asegurar_victoria(destellos, _estrellas)
	var linea := _ruta_voz("victoria")
	if _perfil != "semilla":
		var total := puntaje_total()
		var habia := _record > 0
		if total > _record:
			_record_nuevo = registrar_record(total) or planeta_id == ""
			_record = total
			if _barra != null and not habia:
				_barra.plantar_banderita()
			linea = _ruta_voz("record" if habia else "primer_record")
			if linea == "":
				linea = _ruta_voz("victoria")
	_coro("coro")
	_toby["orgulloso"] = true
	_confeti.position = Vector2(740, 330)
	_confeti.restart()
	_confeti.emitting = true
	_texto_flotante(Vector2(740, 200), "¡Bravo!" if not _record_nuevo else "¡Nuevo récord!", VERDE, SEGUNDOS_FIESTA, 60)
	var id := _intento
	await get_tree().create_timer(SEGUNDOS_FIESTA).timeout
	if not is_inside_tree() or id != _intento:
		return
	_fase = "celebrando"
	celebrar(destellos, _estrellas, linea)


## "¡Nos escondimos todos!" (§10.2): todos salen a la vez, desafinados; a Toby se le empaña el casco y
## estornuda; los animales se caen de risa. Semilla: 1,5 s, volumen normal y afinado.
func _derrota() -> void:
	_fase = "gag"
	var suave := _perfil == "semilla"
	_coro("gag")
	_toby["empanado"] = 2.0
	_voz("derrota_gag")
	var dur := SEGUNDOS_GAG_SEMILLA if suave else SEGUNDOS_GAG
	var id := _intento
	await get_tree().create_timer(dur * 0.6).timeout
	if not is_inside_tree() or id != _intento:
		return
	_sonar_id("achis", 1.0, 0.0 if suave else 2.0)
	_toby["salto"] = 1.0
	await get_tree().create_timer(dur * 0.4).timeout
	if not is_inside_tree() or id != _intento or _fase != "gag":
		return
	_fase = "perdio"
	_t_fase = 0.0
	_fin.show()
	var descanso = nivel.get("descanso_tras_derrotas", null)
	if descanso != null and not _descanso_dicho and derrotas_seguidas() >= int(descanso):
		_descanso_dicho = true
		await _esperar_voz_libre(4.0)
		_voz("descansar")


## Todos los hoyos con un animal afuera: coro afinado (victoria, Semilla) o desafinado (gag).
func _coro(modo: String) -> void:
	_fiesta.clear()
	var pool: Array = logica.animales.duplicate()
	pool.shuffle()
	var desafinado := modo == "gag" and _perfil != "semilla"
	for i in _pos.size():
		var m: Dictionary = logica.madrigueras[i]
		var animal: String = m["animal"] if m["animal"] != "" and m["tipo"] in ["pedido", "senuelo"] else str(pool[i % pool.size()])
		_fiesta[i] = {"animal": animal, "t0": _t + i * 0.12, "modo": modo}
		var tono := pow(2.0, float(ACORDE[i % ACORDE.size()]) / 24.0) if not desafinado else randf_range(0.8, 1.25)
		var retraso := 0.0 if desafinado else i * 0.12
		_sonar_animal_en(animal, tono, 3.0 if desafinado else 0.0, retraso)
	logica.bajar_todos()


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and evento.pressed:
		presionar(evento.position)


## Un dedo que presiona en `p` (coordenadas de la pantalla de 1280 × 720). También la usan los arneses.
func presionar(p: Vector2) -> void:
	if nivel.is_empty() or _celebrando:
		return
	if _fase == "perdio":
		# Reintento de un toque en cualquier parte del cartel (Maxi no busca el botón).
		if _t_fase >= 0.25 and not _boton_salir.get_global_rect().has_point(p):
			reintentar()
		return
	if _boton_salir.get_global_rect().has_point(p):
		return
	if _pista_costo != null and _pista_costo.globo_abierto():
		return
	if turnos != null:
		_presionar_equipo(p)
		return
	if RECT_COMETA.has_point(p):
		_voz("instruccion")
		return
	if _boton_antena != null and RECT_ANTENA.has_point(p):
		if _fase == "jugando":
			_pista_costo.pedir(_usar_pista)
		return
	if not _cartel.is_empty() and RECT_OREJA.has_point(p):
		_tocar_oreja()
		return
	if RECT_TOBY.has_point(p):
		_tocar_toby()
		return
	_presionar_claro(p)


func _presionar_claro(p: Vector2) -> void:
	var id := madriguera_en(p)
	if id < 0 or _fase != "jugando":
		_hojitas.append({"pos": p, "t": 0.0})
		if id >= 0:
			_tierrita(_pos[id], 4)
		return
	var resultado := logica.tocar(id)
	if resultado == "ignorado":
		_vis[id]["cosquillas"] = 0.3


## Madriguera cuya zona de toque contiene `p` (la más cercana si se tocan); -1 si es pasto.
func madriguera_en(p: Vector2) -> int:
	var mejor := -1
	var dist := INF
	for i in _pos.size():
		if zona_toque(i).has_point(p):
			var d: float = p.distance_to(_pos[i] - Vector2(0, _alto_animal * 0.45))
			if d < dist:
				dist = d
				mejor = i
	return mejor


func zona_toque(i: int) -> Rect2:
	return Rect2(_pos[i].x - _toque.x / 2.0, _pos[i].y - _toque.y + 50.0 * (_toque.y / 320.0), _toque.x, _toque.y)


func punto_madriguera(i: int) -> Vector2:
	return _pos[i] - Vector2(0, _alto_animal * 0.45)


func _tocar_toby() -> void:
	_toby["ladra"] = 0.4
	_toby["salto"] = 0.7
	_sonar_id("toby")
	# Semilla: tocar a Toby repite el sonido del pedido (§6).
	if _perfil == "semilla" and _fase == "jugando":
		var id := logica.id_pedido()
		if id >= 0 and logica.madrigueras[id]["escrito"] == "":
			_al_sonar(id, logica.madrigueras[id]["animal"], "", true)


func _tocar_oreja() -> void:
	logica.usar_oreja()
	var animal := str(_cartel.get("animal", ""))
	var info: Dictionary = _info_animal.get(animal, {})
	var ruta := str(info.get("nombre_voz", ""))
	if ruta != "" and ResourceLoader.exists(resolver_ruta_audio(ruta)):
		reproducir_voz(ruta)
	else:
		_sonar_animal(animal)
	_cartel["oreja"] = 0.3


func _usar_pista(gratis: bool) -> bool:
	if _fase != "jugando":
		return false
	logica.pista_restante = int(nivel.get("pista_pedidos", 3))
	_ondas = "completas"
	if not gratis:
		_pistas_usadas += 1
	_voz("pista_usada")
	return true


# ---------------------------------------------------------------------------
# Eventos de la lógica
# ---------------------------------------------------------------------------

func _al_aviso(id: int) -> void:
	_tierrita(_pos[id], 5)
	_sonar_id("tierrita", randf_range(0.9, 1.2), -10.0)


func _al_asomar(id: int, animal: String, tipo: String) -> void:
	_vis[id]["animal"] = animal
	_vis[id]["tipo"] = tipo
	_vis[id]["descubierto"] = 0.0
	_tierrita(_pos[id], 6)
	if tipo == "dorado":
		_sonar_id("toby_dorado", 1.0, -4.0)
		if not presentacion_vista(PRESENTACION_DORADO):
			marcar_presentacion_vista(PRESENTACION_DORADO)
			_voz("toby_dorado_presenta")
	elif tipo == "impostor" and not presentacion_vista(PRESENTACION_IMPOSTOR):
		marcar_presentacion_vista(PRESENTACION_IMPOSTOR)
		_voz("impostor_presenta")


func _al_sonar(id: int, animal: String, escrito: String, repite: bool) -> void:
	if escrito != "":
		_cartel = {"texto": escrito, "id": id, "animal": animal, "t": 0.0, "oreja": 0.0}
		if logica.tipo_escrito == "letra" and not repite:
			var letras: Dictionary = nivel.get("lineas_voz", {}).get("letras", {})
			var ruta := str(letras.get(escrito, ""))
			if ruta != "" and ResourceLoader.exists(resolver_ruta_audio(ruta)):
				reproducir_voz(ruta)
		if not logica.madrigueras[id]["brilla"]:
			return
	else:
		_sonar_animal(animal)
	_vis[id]["habla"] = 0.25
	var cabeza := _pos[id] + Dibujo.punto_cabeza(animal, _alto_animal)
	var completas: bool = _ondas == "completas" or logica.madrigueras[id]["brilla"]
	_anillos.append({"pos": cabeza, "t": 0.0, "dur": 0.7, "arcos": 3 if completas else 1, "alfa": 1.0 if completas else 0.45})


func _al_acertar(id: int, puntos: int, racha: int, rapidito: bool) -> void:
	var animal: String = logica.madrigueras[id]["animal"]
	if not _cartel.is_empty() and _cartel.get("id", -1) == id:
		_cartel = {}
	_sonar_animal(animal, 1.35)
	var audio := get_node_or_null("/root/Audio")
	var semitonos := mini(maxi(racha - 1, 0), 12)
	if audio != null:
		audio.reproducir_sfx(resolver_ruta_audio(SFX_PLING), pow(2.0, semitonos / 12.0))
	var cabeza := _pos[id] + Dibujo.punto_cabeza(animal, _alto_animal)
	for k in 10:
		var a := randf() * TAU
		_particulas.append({"pos": cabeza, "vel": Vector2.from_angle(a) * randf_range(120, 320) + Vector2(0, -120), "r": randf_range(4, 8), "color": DORADO if k % 2 == 0 else Dibujo.color_de(animal), "vida": 0.6})
	if turnos == null:
		_vuelos.append({"desde": cabeza, "hasta": _punto_collar(logica.aciertos - 1), "t": 0.0, "dur": 0.5})
		if _perfil != "semilla":
			_texto_flotante(cabeza + Vector2(0, -30), "+%d" % puntos, Dibujo.color_de(animal).darkened(0.2), 0.8, 38)
			if rapidito:
				_texto_flotante(cabeza + Vector2(0, -80), "¡rapidito!", Color("#FF8A3D"), 0.8, 30)
			if _barra != null:
				_barra.fijar_puntaje(puntaje_total())
	_toby["salto"] = 1.0
	if turnos != null:
		_acierto_equipo()


func _al_errar(id: int, animal: String) -> void:
	_sonar_animal(animal)
	if _perfil == "semilla" or (turnos != null and turnos.perfil_actual() == "semilla"):
		# Ambos celebran: el señuelo baila un poquito (GDD §4). No es fallo.
		_vis[id]["celebra"] = 0.8
		return
	_vis[id]["yo"] = 0.6
	_toby["ladeo"] = 0.8
	if turnos != null and turnos.turno_activo():
		turnos.notificar_fallo_suave()


func _al_tocar_vacia(id: int) -> void:
	_tierrita(_pos[id], 8)
	reproducir_sfx(SFX_PUF, randf_range(0.95, 1.15), -6.0)


func _al_escapar(id: int, _animal: String) -> void:
	_sonar_id("risita_hoyo", randf_range(0.95, 1.1))
	_toby["tapa"] = 0.9
	if not _cartel.is_empty() and _cartel.get("id", -1) == id:
		_cartel = {}
	if _mano.get("id", -1) == id:
		_mano = {}
	if turnos != null and turnos.turno_activo() and not _eq_victoria:
		turnos.terminar_turno(true)


func _al_tocar_dorado(id: int, puntos: int) -> void:
	_sonar_id("toby_dorado", 1.2)
	_toby["aplaude"] = 1.0
	var p := punto_madriguera(id)
	if puntos > 0 and turnos == null:
		_texto_flotante(p + Vector2(0, -60), "+%d" % puntos, DORADO.darkened(0.25), 0.9, 44)
		if _barra != null:
			_barra.fijar_puntaje(puntaje_total())
	for k in 16:
		var a := TAU * k / 16.0
		_particulas.append({"pos": p, "vel": Vector2.from_angle(a) * 260.0, "r": 6.0, "color": DORADO, "vida": 0.6})
	_voz("toby_dorado")


func _al_tocar_impostor(id: int) -> void:
	_vis[id]["descubierto"] = 1.0
	_sonar_id("impostor")
	_voz("impostor")


func _al_completar_doble(puntos: int) -> void:
	if _perfil != "semilla" and turnos == null:
		_texto_flotante(Vector2(740, 230), "¡Doble! +%d" % puntos, Color("#9B5DE5"), 1.0, 44)


func _al_llenar_meta() -> void:
	_collar_brillo = 1.0
	reproducir_sfx(SFX_META, 1.2)
	if turnos == null and _fase == "jugando" and not logica.gana_al_llenar:
		_texto_flotante(Vector2(640, 130), "¡Meta!", DORADO.darkened(0.2), 1.2, 48)
		_voz("meta_llena")
		if _barra != null:
			_barra.fijar_puntaje(puntaje_total())


func _al_ayudar(nivel_ayuda: int, id: int) -> void:
	if nivel_ayuda == 1:
		_vis[id]["salto_ayuda"] = 0.5
	else:
		_mano = {"id": id, "t": 0.0}


# ---------------------------------------------------------------------------
# Bucle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_t_fase += delta
	if nivel.is_empty():
		return
	if turnos != null:
		_procesar_equipo(delta)
	if _fase == "jugando" or turnos != null or _fase in ["entre_rondas", "fiesta", "gag"]:
		logica.avanzar(delta)
	for v in _vis:
		for clave in ["habla", "yo", "salto_ayuda", "celebra", "cosquillas"]:
			v[clave] = maxf(0.0, v[clave] - delta)
		if v["descubierto"] > 0.0:
			v["descubierto"] = minf(2.0, v["descubierto"] + delta)
	for clave in ["salto", "ladeo", "tapa", "aplaude", "empanado", "ladra"]:
		_toby[clave] = maxf(0.0, _toby[clave] - delta * (2.5 if clave == "salto" else 1.0))
	var racha := logica.racha if _fase == "jugando" or turnos != null else 0
	_racha_vista = racha
	_colita += delta * (6.0 + mini(racha, 5) * 3.0)
	_collar_brillo = maxf(0.0, _collar_brillo - delta * 0.6) if not logica.meta_alcanzada else 1.0
	for p in _particulas:
		p["vel"].y += 700.0 * delta
		p["pos"] += p["vel"] * delta
		p["vida"] -= delta
	_particulas = _particulas.filter(func(p): return p["vida"] > 0.0)
	for lista in [_textos, _anillos, _vuelos, _hojitas]:
		for x in lista:
			x["t"] += delta
	_textos = _textos.filter(func(x): return x["t"] < x["dur"])
	_anillos = _anillos.filter(func(x): return x["t"] < x["dur"])
	_hojitas = _hojitas.filter(func(x): return x["t"] < 0.5)
	var llegaron := _vuelos.filter(func(x): return x["t"] >= x["dur"])
	_vuelos = _vuelos.filter(func(x): return x["t"] < x["dur"])
	if not llegaron.is_empty():
		reproducir_sfx(SFX_HUESO, 1.4, -8.0)
	if not _mano.is_empty():
		_mano["t"] += delta
		var m: Dictionary = logica.madrigueras[_mano["id"]]
		if not m["pedido"] or m["tocado"] or m["estado"] != "arriba":
			_mano = {}
	if not _cartel.is_empty():
		_cartel["t"] += delta
		_cartel["oreja"] = maxf(0.0, float(_cartel["oreja"]) - delta)
	for c in _capas_animal + _capas_frente:
		c.queue_redraw()
	_suelo.queue_redraw()
	_efectos.queue_redraw()
	_hud.queue_redraw()
	if _fin.visible:
		_fin.queue_redraw()


# ---------------------------------------------------------------------------
# Sonido
# ---------------------------------------------------------------------------

## Sonido del animal: el archivo del nivel si existe (CC0), si no el sintetizado.
func _stream_animal(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var info: Dictionary = _info_animal.get(id, {})
	var ruta := resolver_ruta_audio(str(info.get("sonido", "")))
	var stream: AudioStream = null
	if ruta != "" and ResourceLoader.exists(ruta):
		stream = load(ruta)
	if stream == null:
		stream = sonidos.stream(id)
	_streams[id] = stream
	return stream


func _sonar_animal(id: String, tono: float = 1.0, volumen_db: float = 0.0) -> void:
	_reproducir(_stream_animal(id), tono, volumen_db)


func _sonar_animal_en(id: String, tono: float, volumen_db: float, retraso: float) -> void:
	if retraso <= 0.0:
		_sonar_animal(id, tono, volumen_db)
		return
	var intento := _intento
	get_tree().create_timer(retraso).timeout.connect(func() -> void:
		if is_inside_tree() and intento == _intento:
			_sonar_animal(id, tono, volumen_db))


func _sonar_id(id: String, tono: float = 1.0, volumen_db: float = 0.0) -> void:
	_reproducir(sonidos.stream(id), tono, volumen_db)


func _reproducir(stream: AudioStream, tono: float, volumen_db: float) -> void:
	if stream == null:
		return
	var libre: AudioStreamPlayer = _reproductores[0]
	for r in _reproductores:
		if not r.playing:
			libre = r
			break
	libre.stream = stream
	libre.pitch_scale = tono
	libre.volume_db = volumen_db
	libre.play()


func _ruta_voz(clave: String) -> String:
	var valor = nivel.get("lineas_voz", {}).get(clave, "")
	if valor is Array:
		return str(valor.pick_random()) if not valor.is_empty() else ""
	if valor is Dictionary:
		return ""
	return str(valor)


## Voz de Toby solo si el archivo existe (el juego funciona sin audio; las líneas están en lineas_tts.tsv).
func _voz(clave: String) -> void:
	var ruta := _ruta_voz(clave)
	if ruta == "" or ruta == "PENDIENTE" or not ResourceLoader.exists(resolver_ruta_audio(ruta)):
		return
	reproducir_voz(ruta)


# ---------------------------------------------------------------------------
# Modo equipo (motor-topos.md §12.2; modo-equipo.md §11.4)
# ---------------------------------------------------------------------------

func _preparar_equipo() -> void:
	var bloque = nivel.get("equipo", {})
	_eq = bloque if bloque is Dictionary else {}
	_perfiles_equipo = nivel.get("perfiles", {}) if nivel.get("perfiles", {}) is Dictionary else {}
	_boton_salir.position = RECT_CASA_EQUIPO.position
	_boton_salir.size = RECT_CASA_EQUIPO.size
	_boton_salir.pivot_offset = RECT_CASA_EQUIPO.size / 2.0
	var perfiles := {}
	for id in equipo:
		perfiles[id] = perfil_de(id)
	var ui: Control = _boton_salir.get_parent()
	turnos.configurar(equipo, _config_gestor(), perfiles, ui)
	var capa := ui.get_node_or_null("capa_equipo")
	if capa != null:
		ui.move_child(capa, _hud.get_index())
	turnos.turno_iniciado.connect(func(_id: String, perfil: String) -> void: aplicar_perfil_turno(perfil))
	turnos.jugada_automatica_pedida.connect(_jugada_automatica_equipo)
	turnos.tope_alcanzado.connect(_al_tope_equipo)
	turnos.entrada_bloqueada_cambio.connect(func(bloqueada: bool) -> void:
		if bloqueada and _eq_gag.is_empty():
			logica.esconder_todos())
	logica.duracion = 0.0
	logica.meta = 0
	logica.gana_al_llenar = false
	logica.pausada = true
	logica.empezar()
	_fase = "jugando"
	_arrancar_equipo.call_deferred()


func _clave_equipo() -> String:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null:
		return progreso.clave_equipo(equipo)
	var copia := equipo.duplicate()
	copia.sort()
	return "+".join(PackedStringArray(copia))


func _config_gestor() -> Dictionary:
	var config: Dictionary = _eq.duplicate(true)
	var comps = _eq.get("composiciones", {})
	var comp: Dictionary = {}
	if comps is Dictionary and not comps.is_empty():
		comp = comps.get(_clave_equipo(), comps.values()[comps.size() - 1])
		if not comps.has(_clave_equipo()):
			push_warning("motor_topos: composicion '%s' no esta en %s; uso la de los tres" % [_clave_equipo(), ruta_nivel])
	config.erase("composiciones")
	config["pasos_rival"] = int(comp.get("pasos_rival", _eq.get("pasos_rival", 6)))
	_eq_meta = maxi(1, int(comp.get("aciertos_meta", _eq.get("aciertos_meta", 14))))
	config["aciertos_totales"] = _eq_meta
	config["lineas_voz"] = nivel.get("lineas_voz", {})
	var record := -1
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and not en_batalla:
		record = progreso.obtener_record_equipo(planeta_id, _id_nivel_actual(), _clave_equipo())
	config["record_pasos"] = record
	return config


func _arrancar_equipo() -> void:
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or _eq_victoria:
		return
	var intro := _ruta_voz("intro_ronda")
	if intro != "" and ResourceLoader.exists(resolver_ruta_audio(intro)):
		reproducir_voz(intro)
		await _esperar_voz_libre(6.0)
	if not is_inside_tree() or _eq_victoria:
		return
	if _eq_restaurado:
		turnos.empezar_retomando()
	else:
		turnos.empezar()


func _turno_jugable() -> bool:
	return turnos != null and turnos.turno_activo() and not turnos.entrada_bloqueada() and not _eq_cerrando \
		and not _eq_victoria and _eq_gag.is_empty()


## La capa del perfil del turno: t_arriba_s, asomados, repetición y ondas de quien juega (§12.2).
func aplicar_perfil_turno(perfil: String) -> void:
	var capa: Dictionary = _perfiles_equipo.get(perfil, {}).duplicate()
	capa["perfil"] = perfil
	logica.aplicar_perfil(capa)
	_ondas = str(capa.get("ondas_visibles", "completas"))
	_eq_cerrando = false


func _procesar_equipo(delta: float) -> void:
	logica.pausada = not _turno_jugable()
	if not _eq_gag.is_empty():
		_eq_gag["t"] += delta
		if _eq_gag["fase"] == "aspirar" and _eq_gag["t"] >= _eq_gag["dur"]:
			_eq_gag["fase"] = "oculto"
		elif _eq_gag["fase"] == "devolver" and _eq_gag["t"] >= _eq_gag["dur"]:
			_eq_gag = {}


func _presionar_equipo(p: Vector2) -> void:
	if not _turno_jugable():
		var id_bloqueado := madriguera_en(p)
		if id_bloqueado >= 0:
			_vis[id_bloqueado]["cosquillas"] = 0.2
		return
	_presionar_claro(p)


func _acierto_equipo() -> void:
	_eq_aciertos += 1
	turnos.notificar_acierto()
	if _eq_aciertos >= _eq_meta:
		_victoria_equipo()


## Tope del turno: espera a que el animal termine su salto y confirma (B2.1).
func _al_tope_equipo() -> void:
	_eq_cerrando = true
	await get_tree().create_timer(LogicaTopos.T_SALTO + 0.1).timeout
	if not is_inside_tree() or _eq_victoria:
		return
	turnos.confirmar_turno_estable()


## M2: 20 s sin tocar en el turno de Maxi -> el pedido salta solo hacia la barra del equipo como acierto.
func _jugada_automatica_equipo() -> void:
	if not _turno_jugable() or turnos.perfil_actual() != "semilla":
		return
	if logica.id_pedido() < 0:
		return
	_voz("maxi_regalito")
	logica.tocar_pedido()


func _victoria_equipo() -> void:
	if _eq_victoria:
		return
	_eq_victoria = true
	_fase = "fiesta"
	var pasos := turnos.pasos_usados()
	turnos.detener()
	logica.detener()
	_coro("coro")
	_confeti.position = Vector2(740, 360)
	_confeti.restart()
	_confeti.emitting = true
	reproducir_sfx(SFX_META)
	if en_batalla:
		await get_tree().create_timer(1.0).timeout
		if is_inside_tree():
			emitir_completado(0)
		return
	var resultado := asegurar_victoria_equipo(pasos)
	turnos.rival_aplaude()
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	if bool(resultado.get("record_nuevo", false)) and not bool(resultado.get("primer_record", false)):
		turnos.pista.saltar_banderita()
	_fase = "celebrando"
	celebrar_equipo(pasos, _ruta_voz("victoria_equipo"))


func ancla_meta_turno() -> Vector2:
	return Vector2(290, 400)


## Los animales asomados vuelan en espiral a la boca de la mochila-torre (si no hay ninguno arriba, salen tres
## del claro para el gag).
func gag_derrota_aspirar(destino: Vector2) -> float:
	var animales: Array = []
	for i in _pos.size():
		var m: Dictionary = logica.madrigueras[i]
		if m["estado"] != "abajo" and m["tipo"] in ["pedido", "senuelo"]:
			animales.append({"animal": m["animal"], "desde": _pos[i], "hoyo": i})
	if animales.is_empty():
		var pool: Array = logica.animales.duplicate()
		pool.shuffle()
		for k in mini(3, _pos.size()):
			animales.append({"animal": str(pool[k % pool.size()]), "desde": _pos[k * 2 % _pos.size()], "hoyo": k * 2 % _pos.size()})
	logica.bajar_todos()
	_eq_gag = {"fase": "aspirar", "t": 0.0, "dur": 0.9, "destino": destino, "animales": animales}
	_sonar_id("fiuu")
	return 0.9


## Los estornuda de vuelta: caen en sus hoyos con un "¡plop!" y quedan abajo (listos para quien juega).
func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	if _eq_gag.is_empty():
		return 0.0
	_eq_gag["fase"] = "devolver"
	_eq_gag["t"] = 0.0
	_eq_gag["dur"] = 0.7
	_sonar_id("achis")
	_sonar_id("plop", 1.0, -4.0)
	return 0.7


func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	_eq_gag = {}
	logica.bajar_todos()


func reintentar_equipo() -> void:
	pass


func contar_logro_equipo() -> int:
	return _eq_aciertos


func obtener_parcial_equipo() -> Dictionary:
	return {"aciertos": _eq_aciertos}


func restaurar_parcial_equipo(estado: Dictionary) -> void:
	_eq_aciertos = int(estado.get("aciertos", 0))
	_eq_restaurado = true


# ---------------------------------------------------------------------------
# Dibujo: fondo, suelo, animales, frentes, efectos
# ---------------------------------------------------------------------------

func _dibujar_fondo() -> void:
	var tema := str(nivel.get("fondo_tema", "campamento"))
	var ruta := str(nivel.get("fondo", ""))
	if ruta != "" and ResourceLoader.exists(ruta):
		_fondo.draw_texture_rect(load(ruta), Rect2(0, 0, 1280, 720), false)
		return
	var paletas := {
		"campamento": [Color("#BFE6FF"), Color("#E8F7FF"), Color("#5FAF4E"), Color("#9ED66B"), Color("#B5E07A")],
		"laguna": [Color("#A8E0FF"), Color("#E6F8FF"), Color("#4FA66A"), Color("#8ED48A"), Color("#A9E39A")],
		"pradera": [Color("#FFE3A8"), Color("#FFF6DA"), Color("#9AB85A"), Color("#C9DB7A"), Color("#DDE89A")],
		"nidos": [Color("#B8E8D0"), Color("#E9FFF3"), Color("#3E8F55"), Color("#7CC56E"), Color("#97D487")],
		"valle": [Color("#D8C8FF"), Color("#FFE6F2"), Color("#6A9F5C"), Color("#A7D27F"), Color("#BFE08F")],
	}
	var pal: Array = paletas.get(tema, paletas["campamento"])
	# Cielo en franjas suaves.
	for k in 12:
		_fondo.draw_rect(Rect2(0, k * 20, 1280, 21), pal[0].lerp(pal[1], k / 11.0))
	# Lejanía según el tema.
	match tema:
		"campamento":
			_fondo.draw_colored_polygon(PackedVector2Array([Vector2(60, 210), Vector2(150, 110), Vector2(240, 210)]), Color("#7BC67E"))
			_fondo.draw_colored_polygon(PackedVector2Array([Vector2(130, 210), Vector2(150, 150), Vector2(170, 210)]), Color("#3F7F4A"))
		"laguna":
			Dibujo._elipse(_fondo, Vector2(980, 228), Vector2(260, 40), 0.0, Color("#6CC3E8"), 0.0)
			for x in [880, 990, 1100]:
				Dibujo._elipse(_fondo, Vector2(x, 226), Vector2(26, 9), 0.0, Color("#4FA66A"), 0.0)
				_fondo.draw_circle(Vector2(x + 6, 220), 6.0, Color("#FF9FC2"))
		"pradera":
			_fondo.draw_line(Vector2(1080, 230), Vector2(1080, 150), Color("#7A5230"), 10.0)
			Dibujo._elipse(_fondo, Vector2(1080, 140), Vector2(90, 26), 0.0, Color("#6B9A3A"), 0.0)
		"nidos":
			for x in [180, 1150]:
				_fondo.draw_rect(Rect2(x - 26, 20, 52, 220), Color("#7A5230"))
				_fondo.draw_circle(Vector2(x, 30), 90.0, Color("#3E8F55"))
			Dibujo._elipse(_fondo, Vector2(1150, 120), Vector2(40, 16), 0.0, Color("#B8864E"), 0.0)
		"valle":
			_fondo.draw_colored_polygon(PackedVector2Array([Vector2(860, 230), Vector2(1010, 70), Vector2(1060, 70), Vector2(1210, 230)]), Color("#9C7BB0"))
			_fondo.draw_circle(Vector2(1035, 52), 18.0, Color(1, 1, 1, 0.7))
	# Árboles redondos del borde de la selva.
	for k in 16:
		var x := k * 86.0 - 20.0
		var r := 54.0 + (k * 37 % 5) * 8.0
		_fondo.draw_circle(Vector2(x, 236 - (k % 3) * 12), r, pal[2])
	_fondo.draw_rect(Rect2(0, 236, 1280, 484), pal[3])
	# Claro con vetas de pasto más claro y el sendero de huellitas (HE-A7b).
	for k in 7:
		Dibujo._elipse(_fondo, Vector2(160 + k * 180, 300 + (k % 2) * 260), Vector2(170, 50), 0.0, pal[4], 0.0)
	for k in 9:
		var p := Vector2(250 + k * 110, 700 - k * 18 + sin(k * 0.9) * 20)
		_fondo.draw_circle(p, 9.0, Color(pal[2], 0.45))
		for d in 3:
			_fondo.draw_circle(p + Vector2(-9 + d * 9, -12), 4.0, Color(pal[2], 0.45))
	for k in 18:
		var f := Vector2(40 + (k * 157) % 1220, 270 + (k * 97) % 430)
		_fondo.draw_circle(f, 5.0, [Color("#FF9FC2"), Color("#FFE066"), Color.WHITE][k % 3])


func _dibujar_suelo() -> void:
	for i in _pos.size():
		var c: Vector2 = _pos[i]
		Dibujo._elipse(_suelo, c + Vector2(0, -2), Vector2(_ancho_hoyo * 0.62, _ancho_hoyo * 0.2), 0.0, TIERRA, 3.0)
		Dibujo._elipse(_suelo, c, Vector2(_ancho_hoyo * 0.46, _ancho_hoyo * 0.12), 0.0, TIERRA_OSCURA, 0.0)
		var m: Dictionary = logica.madrigueras[i]
		if m["brilla"] and m["estado"] in ["aviso", "subiendo", "arriba"] and m["pedido"] and not m["tocado"]:
			var b := 0.5 + 0.5 * sin(_t * 10.0)
			Dibujo._elipse(_suelo, c, Vector2(_ancho_hoyo * 0.7, _ancho_hoyo * 0.26), 0.0, Color(1, 0.86, 0.3, 0.35 + 0.3 * b), 0.0)


func _dibujar_frente(capa: Control, i: int) -> void:
	var c := Vector2(_ancho_hoyo, 40.0)
	var frente := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		frente.append(c + Vector2(cos(a) * _ancho_hoyo * 0.62, sin(a) * _ancho_hoyo * 0.2 - 2.0))
	for k in 17:
		var a := PI - PI * k / 16.0
		frente.append(c + Vector2(cos(a) * _ancho_hoyo * 0.48, sin(a) * _ancho_hoyo * 0.12))
	capa.draw_colored_polygon(frente, TIERRA.lightened(0.08))
	var borde := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		borde.append(c + Vector2(cos(a) * _ancho_hoyo * 0.62, sin(a) * _ancho_hoyo * 0.2 - 2.0))
	capa.draw_polyline(borde, COLOR_CONTORNO, 3.0, true)
	# Pasto en el borde del montículo.
	for k in 7:
		var x := c.x + (k - 3) * _ancho_hoyo * 0.17
		var y := c.y + _ancho_hoyo * 0.17 - absf(k - 3) * 4.0
		var meneo := sin(_t * 2.0 + k + i) * 2.0
		capa.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, y), Vector2(x + meneo, y - 18), Vector2(x + 7, y)]), Color("#4E9C45"))


## Rise, respiración, habla, salto, bajada y fiesta del animal de la madriguera `i`, recortado en el hoyo.
func _dibujar_animal(capa: Control, i: int) -> void:
	var base := Vector2(capa.size.x / 2.0, capa.size.y - 4.0)
	var h := _alto_animal
	var m: Dictionary = logica.madrigueras[i]
	var v: Dictionary = _vis[i]
	var animal := ""
	var tipo := ""
	var dy := 0.0
	var escala := Vector2.ONE
	var rot := 0.0
	var cara := {"ojos": "normal", "boca": 0.0, "mirar": Vector2(-0.6, 0.25)}
	var fiesta: Dictionary = _fiesta.get(i, {})
	if not fiesta.is_empty():
		animal = fiesta["animal"]
		tipo = "senuelo"
		var k := _t - float(fiesta["t0"])
		if k < 0.0:
			return
		var sube := clampf(k / 0.14, 0.0, 1.0)
		dy = (1.0 - _ease_back(sube)) * (h + 20.0)
		if fiesta["modo"] == "coro":
			rot = sin(k * 9.0 + i) * 0.12
			dy -= absf(sin(k * 6.0 + i)) * 14.0
			cara = {"ojos": "risa", "boca": 0.6}
		else:
			# Se caen de risa dentro del hoyo.
			var cae := clampf((k - 0.9) / 0.6, 0.0, 1.0)
			rot = sin(k * 14.0 + i) * 0.2 + (cae * 0.9 if i % 2 == 0 else -cae * 0.9)
			dy += cae * cae * (h + 30.0)
			cara = {"ojos": "risa" if k > 0.5 else "grandes", "boca": 0.9}
	else:
		animal = m["animal"]
		tipo = m["tipo"]
		if animal == "":
			return
		var t: float = m["t"]
		match m["estado"]:
			"aviso", "abajo":
				return
			"subiendo":
				var k2 := clampf(t / LogicaTopos.T_SUBIR, 0.0, 1.0)
				dy = (1.0 - _ease_back(k2)) * (h + 20.0)
				escala = Vector2(1.0 - 0.08 * sin(k2 * PI), 1.0 + 0.15 * sin(k2 * PI))
			"arriba":
				var resp := 1.0 + 0.03 * sin(_t * TAU * 1.5 + i)
				escala = Vector2(1.0, resp)
				if v["habla"] > 0.0:
					var kh: float = v["habla"] / 0.25
					dy -= sin(kh * PI) * 10.0
					cara["boca"] = kh
				if v["salto_ayuda"] > 0.0:
					dy -= sin(v["salto_ayuda"] / 0.5 * PI) * 40.0
				if v["celebra"] > 0.0:
					rot = sin(v["celebra"] * 18.0) * 0.15
					cara["ojos"] = "cerrados"
					cara["boca"] = 0.5
				if v["cosquillas"] > 0.0:
					rot += sin(v["cosquillas"] * 40.0) * 0.06
				# Semilla: el pedido que se va a esconder saluda con la patita (§5.1).
				if m["pedido"] and m["dur"] > 0.0 and m["t_up"] > m["dur"] - 0.6 and _perfil == "semilla":
					rot = sin(_t * 12.0) * 0.1
			"bajando":
				var dur: float = m["dur_bajar"]
				var k3 := clampf(t / dur, 0.0, 1.0)
				dy = k3 * k3 * (h + 20.0)
				escala = Vector2(1.0 + 0.2 * k3, 1.0 - 0.2 * k3)
				if v["yo"] > 0.0:
					cara["ojos"] = "grandes"
				if m["escapando"]:
					cara["ojos"] = "guino"
			"saltando":
				var k4 := clampf(t / LogicaTopos.T_SALTO, 0.0, 1.0)
				dy = -60.0 * sin(k4 * PI) + maxf(0.0, (k4 - 0.65) / 0.35) * (h + 20.0)
				rot = sin(k4 * PI) * 0.35
				cara = {"ojos": "risa", "boca": 0.8}
		if v["yo"] > 0.0:
			cara["ojos"] = "grandes"
	capa.draw_set_transform(base + Vector2(0, dy), rot, escala)
	if tipo == "dorado" or animal == "toby_dorado":
		_dibujar_toby_dorado(capa, h)
	elif tipo == "impostor":
		_dibujar_impostor(capa, animal, h, float(v["descubierto"]))
	else:
		Dibujo.dibujar(capa, animal, h, cara)
		Dibujo.detalles(capa, animal, h, cara)
	capa.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ease_back(k: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(k - 1.0, 3) + c1 * pow(k - 1.0, 2)


func _dibujar_toby_dorado(capa: Control, h: float) -> void:
	var alto := h * 1.05
	var ancho := alto * TEXTURA_TOBY.get_width() / TEXTURA_TOBY.get_height()
	for k in 3:
		var a := _t * 3.0 + k * TAU / 3.0
		Dibujo.estrella(capa, Vector2(cos(a) * ancho * 0.7, -alto * 0.6 + sin(a) * alto * 0.3), 9.0, DORADO)
	capa.draw_texture_rect(TEXTURA_TOBY, Rect2(-ancho / 2.0, -alto, ancho, alto), false, Color(1.0, 0.86, 0.35))
	capa.draw_circle(Vector2(0, -alto * 0.75), alto * 0.3, Color(1, 0.95, 0.6, 0.18 + 0.1 * sin(_t * 8.0)))


## El Coleccionauta disfrazado (§8.4): orejas de cartón y bigotes pintados del animal que NO sonó. Al tocarlo
## se le cae el disfraz y se ríe a carcajadas. Siempre ridículo y torpe (R7).
func _dibujar_impostor(capa: Control, disfraz: String, h: float, descubierto: float) -> void:
	var alto := h * 1.05
	var ancho := alto * TEXTURA_COLECCIONAUTA.get_width() / TEXTURA_COLECCIONAUTA.get_height()
	var rect := Rect2(-ancho / 2.0, -alto, ancho, alto)
	capa.draw_texture_rect(TEXTURA_COLECCIONAUTA, rect, false)
	var color := Dibujo.color_de(disfraz)
	var caida := descubierto * descubierto * 120.0
	for s in [-1.0, 1.0]:
		var o := Vector2(s * ancho * 0.22 + s * caida * 0.4, -alto * 0.86 + caida)
		var oreja := PackedVector2Array([o + Vector2(-16, 10), o + Vector2(s * 6, -34), o + Vector2(16, 10)])
		Dibujo._poligono(capa, oreja, Color("#C9A26B"), 2.0)
		capa.draw_colored_polygon(PackedVector2Array([o + Vector2(-8, 6), o + Vector2(s * 4, -20), o + Vector2(8, 6)]), color)
	if descubierto <= 0.0:
		for s in [-1.0, 1.0]:
			for k in 3:
				var o2 := Vector2(s * ancho * 0.12, -alto * 0.58 + k * 6)
				capa.draw_line(o2, o2 + Vector2(s * 30, -6 + k * 6), TINTA, 2.5, true)


func _dibujar_efectos() -> void:
	for a in _anillos:
		var k: float = a["t"] / a["dur"]
		for q in int(a["arcos"]):
			var kq := k - q * 0.18
			if kq <= 0.0:
				continue
			var r := 30.0 + kq * 70.0
			var alfa: float = (1.0 - kq) * float(a["alfa"])
			for lado in [-1.0, 1.0]:
				var centro: float = -PI / 2.0 + lado * 0.9
				_efectos.draw_arc(a["pos"], r, centro - 0.45, centro + 0.45, 10, Color(1, 1, 1, alfa), 6.0, true)
				_efectos.draw_arc(a["pos"], r, centro - 0.45, centro + 0.45, 10, Color(COLOR_CONTORNO, alfa * 0.6), 2.0, true)
	for p in _particulas:
		_efectos.draw_circle(p["pos"], p["r"], Color(p["color"], clampf(p["vida"] * 2.0, 0.0, 1.0)))
	for x in _hojitas:
		var k2: float = x["t"] / 0.5
		for q in 3:
			var o: Vector2 = x["pos"] + Vector2((q - 1) * 14.0, 0)
			var meneo := sin(k2 * 12.0 + q) * 8.0 * (1.0 - k2)
			_efectos.draw_colored_polygon(PackedVector2Array([o + Vector2(-5, 0), o + Vector2(meneo, -22), o + Vector2(5, 0)]), Color("#3F8F3A", 1.0 - k2))
	for vuelo in _vuelos:
		var k3 := clampf(vuelo["t"] / vuelo["dur"], 0.0, 1.0)
		var desde: Vector2 = vuelo["desde"]
		var hasta: Vector2 = vuelo["hasta"]
		var p2 := desde.lerp(hasta, k3) + Vector2(0, -sin(k3 * PI) * 90.0)
		_dibujar_hueso(_efectos, p2, 1.0, true)
		Dibujo.estrella(_efectos, p2 + Vector2(22, -10), 10.0, DORADO)
	if not _mano.is_empty():
		var id: int = _mano["id"]
		var objetivo := punto_madriguera(id)
		var k4 := fmod(float(_mano["t"]), 1.2) / 1.2
		var p3 := objetivo + Vector2(70, 90).lerp(Vector2(10, 10), minf(1.0, k4 * 1.6))
		var alfa := 0.85 if k4 < 0.8 else (1.0 - k4) * 4.0
		_dibujar_mano(p3, alfa)
	if not _eq_gag.is_empty():
		_dibujar_gag_equipo()
	for x in _textos:
		var kt: float = x["t"] / x["dur"]
		_texto(_efectos, x["texto"], x["pos"] + Vector2(0, -kt * 40.0), x["tam"], Color(x["color"], 1.0 - maxf(0.0, kt - 0.7) / 0.3))


func _dibujar_gag_equipo() -> void:
	var fase_gag: String = _eq_gag["fase"]
	if fase_gag == "oculto":
		return
	var k := clampf(_eq_gag["t"] / maxf(0.01, _eq_gag["dur"]), 0.0, 1.0)
	if fase_gag == "devolver":
		k = 1.0 - k
	var destino: Vector2 = _eq_gag["destino"]
	for n in _eq_gag["animales"].size():
		var a: Dictionary = _eq_gag["animales"][n]
		var desde: Vector2 = a["desde"]
		var espiral := Vector2.from_angle(k * TAU * 1.5 + n) * 80.0 * (1.0 - k)
		var p := desde.lerp(destino, k * k) + espiral
		_efectos.draw_set_transform(p, k * TAU, Vector2.ONE * lerpf(1.0, 0.25, k))
		Dibujo.dibujar(_efectos, a["animal"], _alto_animal * 0.8, {"ojos": "grandes", "boca": 0.7})
		_efectos.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dibujar_mano(p: Vector2, alfa: float) -> void:
	var piel := Color(1.0, 0.93, 0.84, alfa)
	var borde := Color(COLOR_CONTORNO, alfa)
	_efectos.draw_circle(p + Vector2(10, 30), 26.0, borde)
	_efectos.draw_circle(p + Vector2(10, 30), 23.0, piel)
	_efectos.draw_line(p, p + Vector2(4, 24), borde, 20.0, true)
	_efectos.draw_line(p, p + Vector2(4, 24), piel, 14.0, true)


func _dibujar_hueso(lienzo: CanvasItem, c: Vector2, escala: float, lleno: bool, color: Color = Color("#FFF4DD")) -> void:
	var largo := 20.0 * escala
	var r := 7.0 * escala
	var relleno := color if lleno else Color(1, 1, 1, 0.35)
	var borde := COLOR_CONTORNO if lleno else Color(1, 1, 1, 0.75)
	for s in [-1.0, 1.0]:
		for q in [-1.0, 1.0]:
			lienzo.draw_circle(c + Vector2(s * largo, q * r * 0.7), r + 2.0, borde)
	lienzo.draw_rect(Rect2(c - Vector2(largo, r * 0.7 + 2.0), Vector2(largo * 2.0, r * 1.4 + 4.0)), borde)
	for s in [-1.0, 1.0]:
		for q in [-1.0, 1.0]:
			lienzo.draw_circle(c + Vector2(s * largo, q * r * 0.7), r, relleno)
	lienzo.draw_rect(Rect2(c - Vector2(largo, r * 0.7), Vector2(largo * 2.0, r * 1.4)), relleno)


# ---------------------------------------------------------------------------
# HUD: collar de la meta, solcito, Toby, Cometa, racha y cartel escrito
# ---------------------------------------------------------------------------

func _meta_visible() -> int:
	return maxi(1, logica.meta)


func _punto_collar(i: int) -> Vector2:
	var n := _meta_visible()
	var k := (i + 0.5) / n
	return Vector2(lerpf(450.0, 830.0, k), 46.0 + sin(k * PI) * 26.0)


func _dibujar_hud() -> void:
	if nivel.is_empty() or turnos != null:
		return
	# Collar de la meta: un hueso por acierto, sin números (§9).
	var n := _meta_visible()
	var puntos := PackedVector2Array()
	for k in 21:
		var f := k / 20.0
		puntos.append(Vector2(lerpf(430.0, 850.0, f), 40.0 + sin(f * PI) * 28.0))
	_hud.draw_polyline(puntos, COLOR_CONTORNO, 8.0, true)
	_hud.draw_polyline(puntos, Color("#E8434B") if _collar_brillo <= 0.0 else DORADO, 5.0, true)
	var escala := clampf(380.0 / n / 48.0, 0.42, 1.0)
	var llenos := mini(logica.aciertos - _vuelos.size(), n)
	for i in n:
		var p := _punto_collar(i)
		var color := Color("#FFF4DD") if _collar_brillo <= 0.0 else Color("#FFE38A")
		_dibujar_hueso(_hud, p, escala, i < llenos, color)
	if logica.meta_alcanzada:
		Dibujo.estrella(_hud, Vector2(640, 94), 16.0 + sin(_t * 6.0) * 2.0, DORADO)
	# Solcito de la ronda (§9.3): sin tic-tac, sin parpadeo, sin cambiar de color ni acelerar.
	if logica.duracion > 0.0:
		var fs := logica.fraccion_tiempo()
		var sol := Vector2(lerpf(1070.0, 1240.0, fs), 74.0 - sin(fs * PI) * 34.0)
		for k in 8:
			var a := TAU * k / 8.0 + _t * 0.3
			_hud.draw_line(sol + Vector2.from_angle(a) * 30.0, sol + Vector2.from_angle(a) * 40.0, Color("#FFB830"), 5.0, true)
		_hud.draw_circle(sol, 29.0, COLOR_CONTORNO)
		_hud.draw_circle(sol, 26.0, Color("#FFD23F"))
		for lado in [-1.0, 1.0]:
			_hud.draw_circle(sol + Vector2(lado * 8.0, -4.0), 3.5, TINTA)
		_hud.draw_arc(sol + Vector2(0, 2), 9.0, PI * 0.15, PI * 0.85, 10, TINTA, 3.0, true)
		# Al final se pone detrás de una hoja.
		Dibujo._elipse(_hud, Vector2(1236, 82), Vector2(42, 22), -0.4, Color("#4E9C45"), 2.0)
	# Rondas: puntitos sin números arriba del collar.
	if _rondas > 1:
		for r in _rondas:
			var pr := Vector2(612 + r * 56, 104)
			_hud.draw_circle(pr, 12.0, COLOR_CONTORNO)
			_hud.draw_circle(pr, 9.0, DORADO if r < _ronda - (0 if _fase in ["fiesta", "celebrando"] else 1) or (r == _ronda - 1 and _fase in ["fiesta", "celebrando", "entre_rondas"]) else Color(1, 1, 1, 0.8))
	_dibujar_cometa()
	_dibujar_toby()
	if not _cartel.is_empty():
		_dibujar_cartel()


func _dibujar_cometa() -> void:
	var alto := 92.0
	var ancho := alto * TEXTURA_COMETA.get_width() / TEXTURA_COMETA.get_height()
	var flota := sin(_t * 2.0) * 3.0
	_hud.draw_texture_rect(TEXTURA_COMETA, Rect2(RECT_COMETA.get_center().x - ancho / 2.0, RECT_COMETA.position.y + 4.0 + flota, ancho, alto), false)


func _dibujar_toby() -> void:
	var s := ALTO_TOBY / TEXTURA_TOBY.get_height()
	var ancho := TEXTURA_TOBY.get_width() * s
	var salto: float = sin(clampf(_toby["salto"], 0.0, 1.0) * PI) * 26.0
	var ladeo: float = sin(_toby["ladeo"] * PI) * 0.18
	var base := CENTRO_TOBY + Vector2(0, -salto)
	# Colita (detrás): menea más rápido con la racha (§9.2).
	var cola := base + Vector2(ancho * 0.36, -ALTO_TOBY * 0.22)
	var ang := -0.9 + sin(_colita) * 0.55
	var punta := cola + Vector2.from_angle(ang) * 46.0
	_hud.draw_line(cola, punta, COLOR_CONTORNO, 18.0, true)
	_hud.draw_line(cola, punta, Color("#C98A4B"), 13.0, true)
	_hud.draw_circle(punta, 8.0, Color.WHITE)
	# Antena con la estrellita (pista de Sofía, §10.4; brilla con racha ×5).
	var antena_base := base + Vector2(ancho * 0.3, -ALTO_TOBY * 0.56)
	var antena_punta := Vector2(RECT_ANTENA.get_center().x, RECT_ANTENA.get_center().y) + Vector2(0, -salto)
	_hud.draw_line(antena_base, antena_punta, COLOR_CONTORNO, 7.0, true)
	_hud.draw_line(antena_base, antena_punta, Color("#7BC67E"), 4.0, true)
	var brillo := 1.0 + (0.25 * sin(_t * 10.0) if _racha_vista >= 5 else 0.0)
	Dibujo.estrella(_hud, antena_punta, 16.0 * brillo, DORADO)
	if _boton_antena != null and _fase == "jugando":
		_hud.draw_arc(antena_punta, 30.0 + sin(_t * 3.0) * 2.0, 0.0, TAU, 24, Color(1, 0.86, 0.3, 0.5), 3.0, true)
	if _racha_vista >= 5:
		for k in 4:
			var a := _t * 5.0 + k * TAU / 4.0
			_hud.draw_circle(antena_punta + Vector2.from_angle(a) * 24.0, 3.0, Color("#FFE38A"))
	_hud.draw_set_transform(base, ladeo, Vector2.ONE)
	_hud.draw_texture_rect(TEXTURA_TOBY, Rect2(-ancho / 2.0, -ALTO_TOBY, ancho, ALTO_TOBY), false)
	var ojo_y := -ALTO_TOBY + 128.0 * s
	var ojos := [Vector2((98.0 - 125.0) * s, ojo_y), Vector2((152.0 - 125.0) * s, ojo_y)]
	if _racha_vista >= 3 and _fase == "jugando":
		for o in ojos:
			Dibujo.estrella(_hud, o, 12.0, DORADO)
	if _toby["tapa"] > 0.0:
		for o in ojos:
			Dibujo._elipse(_hud, o + Vector2(0, 4), Vector2(17, 14), 0.0, Color("#FFF1DF"), 2.0)
	if _toby["aplaude"] > 0.0:
		var junta := absf(sin(_toby["aplaude"] * 18.0)) * 20.0
		for lado in [-1.0, 1.0]:
			Dibujo._elipse(_hud, Vector2(lado * (8.0 + junta), -ALTO_TOBY * 0.38), Vector2(14, 18), 0.0, Color("#FFF1DF"), 2.0)
	if _toby["empanado"] > 0.0:
		_hud.draw_circle(Vector2(0, -ALTO_TOBY + 105.0 * s), 112.0 * s, Color(1, 1, 1, minf(0.7, _toby["empanado"] * 0.5)))
	_hud.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _toby["ladra"] > 0.0:
		_texto(_hud, "¡guau!", base + Vector2(70, -ALTO_TOBY - 10), 28, TINTA)
	if _racha_vista >= 2 and _perfil != "semilla" and _fase == "jugando":
		_texto(_hud, "×%d" % mini(_racha_vista, logica.racha_max), base + Vector2(105, -ALTO_TOBY * 0.62), 40, Color("#FF8A3D"))


func _dibujar_cartel() -> void:
	var r := RECT_CARTEL
	var rebote := 1.0 + 0.06 * maxf(0.0, 1.0 - float(_cartel["t"]) * 5.0)
	_hud.draw_set_transform(r.get_center(), 0.0, Vector2.ONE * rebote)
	var local := Rect2(-r.size / 2.0, r.size)
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#C98A4B")
	caja.border_color = Color("#6E3D1B")
	caja.set_border_width_all(5)
	caja.set_corner_radius_all(18)
	_hud.draw_style_box(caja, local)
	_texto(_hud, str(_cartel["texto"]), Vector2(-40, 2), 64 if str(_cartel["texto"]).length() > 1 else 72, CREMA)
	# Ícono de oreja (dice la palabra; quita el "¡rapidito!").
	var o := Vector2(r.size.x / 2.0 - 50.0, 0) + Vector2(0, -sin(float(_cartel["oreja"]) * 10.0) * 4.0)
	_hud.draw_circle(o, 30.0, CREMA)
	_hud.draw_arc(o + Vector2(2, -2), 14.0, -PI * 0.9, PI * 0.5, 14, COLOR_CONTORNO, 6.0, true)
	_hud.draw_circle(o + Vector2(0, 0), 4.0, COLOR_CONTORNO)
	_hud.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Cartel de la derrota: "¡Nos escondimos todos!" (Brote y Estrella con puntaje y récord); en Semilla solo la
## flecha gigante con la carita de Toby. Tocar en cualquier parte reintenta.
func _dibujar_fin() -> void:
	_fin.draw_rect(Rect2(Vector2.ZERO, _fin.size), Color(COLOR_CONTORNO, 0.3))
	var tarjeta := Rect2(420, 130, 440, 440)
	var caja := StyleBoxFlat.new()
	caja.bg_color = CREMA
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(5)
	caja.set_corner_radius_all(48)
	_fin.draw_style_box(caja, tarjeta)
	var rebote := sin(_t * 5.0) * 6.0
	var centro := Vector2(640, 440)
	if _perfil == "semilla":
		centro = Vector2(640, 350)
		_flecha_circular(_fin, centro, 150.0)
		# La carita de Toby adentro de la flecha (solo la cabeza: la textura recortada arriba).
		var alto := 92.0
		var region := Rect2(0, 0, TEXTURA_TOBY.get_width(), TEXTURA_TOBY.get_height() * 0.52)
		var ancho := alto * region.size.x / region.size.y
		_fin.draw_texture_rect_region(TEXTURA_TOBY, Rect2(640 - ancho / 2.0, 350 - alto / 2.0 + rebote * 0.5, ancho, alto), region)
		return
	_texto(_fin, "¡Nos escondimos todos!", Vector2(640, 190 + rebote), 40, Color("#655D82"))
	_texto(_fin, str(logica.puntaje + _puntaje_previo), Vector2(580, 262), 44, TINTA)
	Figura.dibujar(_fin, "estrella", DORADO, Vector2(660, 258), 18.0, false)
	_texto(_fin, str(_record), Vector2(720, 262), 32, VERDE)
	_flecha_circular(_fin, centro, 85.0)


func _flecha_circular(lienzo: Control, c: Vector2, r: float) -> void:
	lienzo.draw_circle(c, r, COLOR_CONTORNO)
	lienzo.draw_circle(c, r - 6.0, DORADO)
	var rr := r * 0.55
	lienzo.draw_arc(c, rr, -PI * 0.15, PI * 1.45, 32, CREMA, r * 0.18, true)
	var punta := c + Vector2.from_angle(-PI * 0.15) * rr
	lienzo.draw_colored_polygon(PackedVector2Array([punta + Vector2(-r * 0.25, -r * 0.08), punta + Vector2(r * 0.22, -r * 0.12), punta + Vector2(r * 0.04, r * 0.3)]), CREMA)


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _tierrita(c: Vector2, n: int) -> void:
	for k in n:
		var a := -PI / 2.0 + randf_range(-1.1, 1.1)
		_particulas.append({"pos": c + Vector2(randf_range(-20, 20), -4), "vel": Vector2.from_angle(a) * randf_range(120, 260), "r": randf_range(3, 6), "color": TIERRA.lightened(0.15), "vida": 0.45})


func _texto_flotante(posicion: Vector2, texto: String, color: Color, duracion: float, tamano: int) -> void:
	# En equipo ningún texto con dígitos (M8.5, R2).
	if turnos != null:
		return
	_textos.append({"pos": posicion, "texto": texto, "color": color, "t": 0.0, "dur": duracion, "tam": tamano})


func _texto(lienzo: CanvasItem, texto: String, centro: Vector2, tamano: int, color: Color) -> void:
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var base := centro + Vector2(-ancho / 2.0, tamano * 0.35)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, maxi(4, int(tamano * 0.18)), Color(1, 1, 1, 0.95 * color.a))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


func _configurar_confeti() -> void:
	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	degradado.colors = PackedColorArray(Figura.COLORES_ARCOIRIS)
	_confeti.color_initial_ramp = degradado


func _icono(boton: Button, dibujo: Callable) -> void:
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(dibujo.bind(icono))


func _estilizar_boton(boton: Button, fondo: Color) -> void:
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = fondo.darkened(0.12) if estado == "pressed" else fondo
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(5)
		caja.set_corner_radius_all(90)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
		caja.shadow_offset = Vector2(0, 5)
		caja.shadow_size = 2
		caja.anti_aliasing = true
		boton.add_theme_stylebox_override(estado, caja)
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	boton.button_down.connect(func() -> void:
		boton.pivot_offset = boton.size / 2.0
		boton.scale = Vector2(0.9, 0.9)
		boton.create_tween().tween_property(boton, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-26, 0), Vector2(2, -26), Vector2(2, -12), Vector2(26, -12), Vector2(26, 12), Vector2(2, 12), Vector2(2, 26)]:
		puntos.append(c + p * k)
	icono.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(icono, puntos, 5.0 * k)
