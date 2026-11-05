class_name MotorRunner
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecánica "runner" — «Carrera de Toby», tipo el dinosaurio de Chrome (docs/fichas/motor-runner.md,
## HE-119). Cuarto juego del Planeta Animalia. El corredor de cada hermano (los dinos de Maxi; pony, jirafa,
## gatito o pony estelar de Nicole; Toby de Sofía) corre solo por el sendero; un toque EN CUALQUIER PARTE lo
## hace saltar. Hay meta (gana la estación) y, para Nicole y Sofía, un tramo extra por el récord.
##
## Las reglas viven en `LogicaRunner` (sin pantalla, determinista con semilla; las prueba
## `herramientas/qa_test_runner.gd`); el arte está en `dibujos_runner.gd` (vectorial por código). Aquí: entrada,
## dibujo, sonidos, el flujo de ganar o perder y el modo equipo. Todo lo que cambia entre hermanos llega en el
## JSON del nivel.
##
## Derrota (PO 05-Nov-2026, HE-124; GDD §6 regla 11): corazones Semilla 3 / Brote 2 / Estrella 1. Al gastar el
## último antes de la meta: gag "¡al barro!" (Maxi: se sienta en las hojas y estornuda confeti), cartel que se
## toca en cualquier parte para reintentar, regalo de la mascota tras `regalo_tras_derrotas` derrotas seguidas
## (corazón extra o burbuja de la suerte), ayuda fuerte de Maxi tras 3 (todo se atraviesa: la meta queda
## asegurada) y "¿descansamos?" sin obligar. Destellos y estrellitas solo al cruzar la meta.
##
## Entrada: tocar (o clic) en cualquier parte salvo la casa, Cometa y la barra del récord = saltar; mantener =
## más alto si el nivel trae `salto.variable`. PC: espacio o flecha arriba.
##
## MODO EQUIPO (§12.2, carrera de postas): con `equipo` y un nivel `"modo_juego": "equipo"`, cada turno es un
## tramo con el corredor y la capa del perfil que juega; cada obstáculo pasado limpio es un acierto; al tope el
## corredor frena y entrega la posta; un choque sin burbuja corta el turno. Sin puntaje, corazones ni burbuja.

signal partida_terminada(gano: bool, puntos: int)

const Dibujos := preload("res://scripts/motores/runner/dibujos_runner.gd")
const BarraRecord := preload("res://scripts/ui/barra_record.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const TEXTURA_COMETA := "res://assets/sprites/personajes/cometa_base.png"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"

## SFX PROVISIONALES (los de la interfaz con otro tono) hasta los propios de la ficha §6.5.
const SFX_IMPULSO := "sfx/ui/toque.ogg"
const SFX_SALTO := "sfx/ui/fiuu.ogg"
const SFX_ATERRIZAR := "sfx/ui/polvo.ogg"
const SFX_COLECCIONABLE := "sfx/ui/confirmar.ogg"
const SFX_HITO := "sfx/ui/seleccionar.ogg"
const SFX_BURBUJA_PLOP := "sfx/ui/blup.ogg"
const SFX_BURBUJA_NUEVA := "sfx/ui/chisporroteo.ogg"
const SFX_UY := "sfx/ui/polvo_boing.ogg"
const SFX_CRUNCH := "sfx/ui/puf.ogg"
const SFX_SPLOSH := "sfx/ui/soltar.ogg"
const SFX_META := "sfx/ui/abrir.ogg"
const SFX_ATARDECER := "sfx/ui/zona_dormida.ogg"
const SFX_GUINO := "sfx/ui/blup.ogg"
const SFX_POSTA := "sfx/ui/fuuush.ogg"

const TINTA := Color("#272140")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const ROSA_CORAZON := Color("#FF7EB6")
const COLORES_HERMANO := {"maxi": Color("#3E77CC"), "nicole": Color("#E8589C"), "sofia": Color("#2FB3AD")}
const COLOR_CORREDOR := {
	"toby": Color("#C9813F"), "pony": Color("#FFB8D6"), "pony_estelar": Color("#D9C8FF"), "gatito": Color("#FFC27A"),
	"jirafa": Color("#FFD35C"), "trex": Color("#7BC96F"), "spino": Color("#5BB5C9"), "carno": Color("#F29A4A"),
	"trex_bombero": Color("#7BC96F"), "tres_dinos": Color("#7BC96F"),
}

const SUELO_SOLO := 600.0
const SUELO_EQUIPO := 560.0
const SEGUNDOS_INTRO := 1.6
const SEGUNDOS_INTRO_CORTA := 0.7
const SEGUNDOS_RESUMEN := 2.2
const SEGUNDOS_FIESTA_META_SEMILLA := 2.4
const RECT_CAMINO := Rect2(430, 30, 420, 30)
const PRESENTA_AEREO := "runner_aereo_alto"
const PRESENTA_BURBUJA := "runner_burbuja"

@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _boton_salir: Button = %boton_salir
@onready var _boton_cometa: Button = %boton_cometa
@onready var _fin: Control = %fin
@onready var _boton_reintentar: Button = %boton_reintentar
@onready var _confeti: CPUParticles2D = %confeti

var logica := LogicaRunner.new()
var _fuente: Font
var _textura_cometa: Texture2D
var _barra: Control
var _semilla := -1
var _menos_movimiento := false

# Configuración del nivel
var _escenario := "campamento"
var _corredor := "toby"
var _meta_dibujo := "carpa"
var _mostrar := "numero"  ## numero | barra | no
var _umbrales: Dictionary = {}
var _regalo_tras := 0
var _regalo: Dictionary = {}
var _ayuda_fuerte: Dictionary = {}
var _descanso_tras := 0
var _gag_s := 2.5
var _dorado := false
var _suelo := SUELO_SOLO

# Estado de pantalla
var _fase := "intro"  ## intro | corriendo | tramo | fiesta_meta | resumen | celebrando | gag | perdio
var _t := 0.0
var _t_fase := 0.0
var _intro_s := SEGUNDOS_INTRO
var _scroll := 0.0
var _ciclo := 0.0
var _squash := 0.0
var _estira := 0.0
var _voltereta := 0.0
var _guino := 0.0
var _tropiezo := 0.0
var _mira := 0.0
var _rugido := 0.0
var _noche := 0.0
var _noche_objetivo := 0.0
var _aurora := 0.0
var _fiesta_meta := 0.0
var _temblor := 0.0
var _particulas: Array = []  ## {pos, vel, r, color, vida, forma}
var _textos: Array = []  ## {pos, texto, color, t, dur, tam}
var _gotas_barro: Array = []  ## {pos, r, vida}
var _corazones_volando: Array = []  ## {pos, vel, t}
var _x_meta_visual := INF
var _derrotas := 0
var _estrellas := 0
var _destellos := 0
var _puntos_meta := 0
var _record := 0
var _record_nuevo := false
var _record_pasado := false
var _salto_bandera := 0.0
var _motivo_fin := ""
var _regalo_en_curso := false
var _ayuda_fuerte_en_curso := false
var _desde_mitad := false
var _gano := false

# Modo equipo
const SEGUNDOS_POSTA_QUIETO := 0.4
var _eq: Dictionary = {}
var _eq_total := 30
var _eq_logrados := 0
var _eq_tramos := 0
var _eq_victoria := false
var _eq_cerrando := false
var _eq_corredor_por_perfil: Dictionary = {}
var _eq_gag: Dictionary = {}  ## {fase, t, dur, destino}
var _eq_falla := false


func _ready() -> void:
	super._ready()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	if ResourceLoader.exists(TEXTURA_COMETA):
		_textura_cometa = load(TEXTURA_COMETA)
	_estilizar_boton(_boton_salir, CREMA)
	_estilizar_boton(_boton_cometa, Color("#CFF5F1"))
	_estilizar_boton(_boton_reintentar, DORADO)
	_icono(_boton_salir, _dibujar_flecha)
	_icono(_boton_cometa, _dibujar_cometa)
	_icono(_boton_reintentar, _dibujar_icono_reintentar)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_boton_cometa.pressed.connect(_tocar_cometa)
	_boton_reintentar.pressed.connect(reintentar)
	_fin.gui_input.connect(_al_input_fin)
	_fin.draw.connect(_dibujar_fin)
	_fin.hide()
	_juego.gui_input.connect(_al_input_juego)
	_juego.draw.connect(_dibujar_juego)
	_hud.draw.connect(_dibujar_hud)
	_configurar_confeti()
	_conectar_logica()
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.has_method("menos_movimiento"):
		_menos_movimiento = bool(progreso.menos_movimiento())
	if nivel.is_empty():
		push_error("motor_runner: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()
	if turnos != null:
		_preparar_equipo()
	else:
		_empezar(true)


func _conectar_logica() -> void:
	logica.salto_iniciado.connect(_al_impulso)
	logica.despego.connect(_al_despegar)
	logica.aterrizo.connect(_al_aterrizar)
	logica.toque_en_el_aire.connect(_al_tocar_en_el_aire)
	logica.paso_obstaculo.connect(_al_pasar)
	logica.choco.connect(_al_chocar)
	logica.atraveso.connect(_al_atravesar)
	logica.coleccionable.connect(_al_coleccionar)
	logica.burbuja_nueva.connect(_al_burbuja_nueva)
	logica.hito.connect(_al_hito)
	logica.racha.connect(_al_racha)
	logica.atardecer.connect(_al_atardecer)
	logica.paso_mitad.connect(_al_pasar_mitad)
	logica.meta.connect(_al_llegar_meta)
	logica.aereo_presentado.connect(_al_presentar_aereo)
	logica.ayuda_mirar.connect(_al_ayuda_mirar)
	logica.fin_carrera.connect(_al_terminar_carrera)


func _configurar_desde_nivel() -> void:
	var esc = nivel.get("escenario", {})
	_escenario = str(esc.get("id", "campamento")) if esc is Dictionary else "campamento"
	_corredor = str(nivel.get("corredor", {}).get("id", "toby"))
	_meta_dibujo = str(nivel.get("meta", {}).get("dibujo", "carpa"))
	_mostrar = str(nivel.get("mostrar_puntaje", "numero"))
	_umbrales = nivel.get("umbrales_puntaje", {}) if nivel.get("umbrales_puntaje", null) is Dictionary else {}
	_regalo_tras = int(nivel.get("regalo_tras_derrotas", 0)) if nivel.get("regalo_tras_derrotas", null) != null else 0
	_regalo = nivel.get("regalo", {}) if nivel.get("regalo", null) is Dictionary else {"tipo": "burbuja"}
	var ayuda = nivel.get("ayuda_fuerte_tras_derrotas", null)
	_ayuda_fuerte = ayuda if ayuda is Dictionary else ({"derrotas": int(ayuda)} if ayuda != null else {})
	_descanso_tras = int(nivel.get("descanso_tras_derrotas", 3)) if nivel.get("descanso_tras_derrotas", 3) != null else 0
	_gag_s = float(nivel.get("gag_derrota_s", 2.5))
	_dorado = bool(nivel.get("dorado", false))
	logica.configurar(nivel, _semilla)
	_record = obtener_record()
	if _mostrar == "barra" and turnos == null:
		_barra = BarraRecord.new()
		_barra.name = "barra_record"
		_barra.position = Vector2(1196, 130)
		_barra.size = Vector2(64, 300)
		_hud.get_parent().add_child(_barra)
		_barra.preparar(_record, float(_umbrales.get("tres", 2000)) * 1.3)
		_barra.record_pasado.connect(_al_pasar_record)
		_barra.tocada.connect(func() -> void: reproducir_sfx(SFX_HITO, 1.5, -6.0))


## Fija la semilla antes de entrar al árbol (arnés QA: carreras reproducibles).
func fijar_semilla(semilla: int) -> void:
	_semilla = semilla


func fase() -> String:
	return _fase


func derrotas() -> int:
	return _derrotas


## Intro: el corredor se pone en posición y Cometa da la largada; en los reintentos, largada corta sin voz.
func _empezar(con_voz: bool) -> void:
	_fase = "intro"
	_t_fase = 0.0
	_intro_s = SEGUNDOS_INTRO if con_voz else SEGUNDOS_INTRO_CORTA
	if con_voz:
		reproducir_voz(_linea("intro"))
		get_tree().create_timer(0.1).timeout.connect(func() -> void:
			var audio := get_node_or_null("/root/Audio")
			if audio == null or not audio.esta_hablando():
				reproducir_voz(_linea("largada")))


func _arrancar_carrera() -> void:
	_fase = "corriendo"
	_t_fase = 0.0


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _al_input_juego(evento: InputEvent) -> void:
	if not evento is InputEventMouseButton or evento.button_index != MOUSE_BUTTON_LEFT:
		return
	if turnos != null and (evento.position.y < 100.0 or evento.position.y > 610.0):
		return  # pista del rival, Cometa y barra del equipo: son del gestor
	_juego.accept_event()
	if evento.pressed:
		saltar()
	else:
		soltar()


func _unhandled_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or evento.echo:
		return
	if evento.keycode != KEY_SPACE and evento.keycode != KEY_UP:
		return
	if evento.pressed:
		if _fase == "perdio":
			reintentar()
		else:
			saltar()
	else:
		soltar()


## Un toque. Siempre responde en el mismo cuadro: impulso, salto en cola, guiño o saltito.
func saltar() -> bool:
	if turnos != null and not _turno_jugable():
		_guino = 1.0
		return false
	if _fase == "intro":
		_guino = 1.0
		reproducir_sfx(SFX_GUINO, 1.4, -8.0)
		return false
	if not (_fase == "corriendo" or _fase == "tramo"):
		return false
	return logica.tocar()


func soltar() -> void:
	logica.soltar()


func _al_input_fin(evento: InputEvent) -> void:
	# Tocar en cualquier parte del cartel reintenta (un toque, Maxi no busca el botón).
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_fin.accept_event()
		reintentar()


func _tocar_cometa() -> void:
	reproducir_sfx(SFX_GUINO)
	reproducir_voz(_linea("intro"))


# ---------------------------------------------------------------------------
# Bucle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_t += delta
	_t_fase += delta
	if nivel.is_empty():
		return
	if turnos != null:
		_procesar_equipo(delta)
	match _fase:
		"intro":
			if _t_fase >= _intro_s and turnos == null:
				_arrancar_carrera()
		"corriendo", "tramo":
			if _mundo_corre():
				logica.avanzar(delta)
				_scroll += logica.velocidad * delta
		"fiesta_meta":
			# Maxi ya ganó: el mundo frena suave mientras revienta el confeti.
			_scroll += maxf(0.0, logica.velocidad * (1.0 - _t_fase / 1.2)) * delta
		"gag":
			if _t_fase >= _gag_s:
				_mostrar_cartel()
	_animar(delta)
	_juego.queue_redraw()
	_hud.queue_redraw()
	if _fin.visible:
		_fin.queue_redraw()


func _mundo_corre() -> bool:
	if turnos == null:
		return true
	if logica.estado == "frenando":
		return true
	return not turnos.entrada_bloqueada() and _eq_gag.is_empty() and not _eq_victoria and not _eq_cerrando


func _animar(delta: float) -> void:
	var corre := (_fase == "corriendo" or _fase == "tramo") and _mundo_corre() and logica.velocidad > 0.0
	if corre and logica.fase_salto == "suelo":
		_ciclo += delta * (8.0 + logica.velocidad / 60.0)
		if fmod(_ciclo, PI) < delta * (8.0 + logica.velocidad / 60.0) and randf() < 0.6:
			_polvito(Vector2(LogicaRunner.X_CORREDOR - 30, _suelo), 2)
	_squash = maxf(0.0, _squash - delta * 7.0)
	_estira = maxf(0.0, _estira - delta * 3.0)
	_voltereta = maxf(0.0, _voltereta - delta * 2.4)
	_guino = maxf(0.0, _guino - delta * 3.0)
	_tropiezo = maxf(0.0, _tropiezo - delta * 1.6)
	_rugido = maxf(0.0, _rugido - delta * 1.5)
	_mira = maxf(0.0, _mira - delta * 0.6)
	_temblor = maxf(0.0, _temblor - delta * 2.0)
	_salto_bandera = maxf(0.0, _salto_bandera - delta * 2.0)
	_noche = move_toward(_noche, _noche_objetivo, delta / 8.0)
	if _fiesta_meta > 0.0:
		_fiesta_meta = minf(1.0, _fiesta_meta + delta / 1.2)
	if _dorado and logica.meta_alcanzada:
		_aurora = minf(1.0, _aurora + delta / 3.0)
	for p in _particulas:
		p["vel"].y += p.get("g", 700.0) * delta
		p["pos"] += p["vel"] * delta
		p["vida"] -= delta
	_particulas = _particulas.filter(func(p): return p["vida"] > 0.0)
	for x in _textos:
		x["t"] += delta
	_textos = _textos.filter(func(x): return x["t"] < x["dur"])
	for g in _gotas_barro:
		g["vida"] -= delta
		g["pos"].y += delta * 40.0
	_gotas_barro = _gotas_barro.filter(func(g): return g["vida"] > 0.0)
	for c in _corazones_volando:
		c["t"] += delta
		c["pos"] += c["vel"] * delta
		c["vel"] += Vector2(sin(c["t"] * 6.0) * 120.0, -30.0) * delta
	_corazones_volando = _corazones_volando.filter(func(c): return c["t"] < 1.4)
	if _menos_movimiento:
		_temblor = 0.0
	_juego.position = Vector2(randf() - 0.5, randf() - 0.5) * 16.0 * _temblor if _temblor > 0.0 else Vector2.ZERO


# ---------------------------------------------------------------------------
# Eventos de la carrera
# ---------------------------------------------------------------------------

func _al_impulso(ayudado: bool) -> void:
	_squash = 1.0
	reproducir_sfx(SFX_IMPULSO, 0.8, -4.0)
	if _es_dino():
		_rugido = 1.0
	if ayudado:
		_mira = 1.0


func _al_despegar() -> void:
	_estira = 1.0
	var tono := 1.0
	if _corredor_actual() == "trex_bombero":
		tono = 1.6  # "¡uiu!"
	reproducir_sfx(SFX_SALTO, tono, -4.0)
	_polvito(Vector2(LogicaRunner.X_CORREDOR, _suelo), 5)


func _al_aterrizar() -> void:
	_squash = 0.8
	reproducir_sfx(SFX_ATERRIZAR, 1.0, -8.0)
	_polvito(Vector2(LogicaRunner.X_CORREDOR, _suelo), 6)


## Toque en el aire: no hay doble salto, pero el corredor guiña (Maxi: voltereta y rugido).
func _al_tocar_en_el_aire() -> void:
	_guino = 1.0
	if logica.imantado_s > 0.0:
		_voltereta = 1.0
		_rugido = 1.0
	reproducir_sfx(SFX_GUINO, 1.3, -8.0)


func _al_pasar(id: String, limpio: bool) -> void:
	if turnos != null:
		_pase_equipo(limpio)
		return
	if limpio and logica.imantado_s > 0.0:
		# Maxi: estrellita y rugido por cada salto.
		_rugido = 1.0
		for k in 5:
			_particulas.append({"pos": _pos_corredor() + Vector2(0, -120), "vel": Vector2(randf_range(-160, 160), randf_range(-320, -120)),
				"r": 9.0, "color": DORADO, "vida": 0.8, "forma": "estrella"})


func _al_chocar(_id: String, con_burbuja: bool, fatal: bool) -> void:
	if con_burbuja:
		reproducir_sfx(SFX_BURBUJA_PLOP, 0.8)
		for k in 14:
			var a := randf() * TAU
			_particulas.append({"pos": _pos_corredor() + Vector2(0, -70) + Vector2.from_angle(a) * 80.0,
				"vel": Vector2.from_angle(a) * randf_range(100, 260), "r": randf_range(3, 7), "color": Color("#BFE8FF"), "vida": 0.7})
		return
	if turnos != null:
		_eq_falla = true
		_tropiezo = 1.0
		reproducir_sfx(SFX_UY, 1.0)
		return
	if fatal:
		return  # lo maneja `_al_terminar_carrera` (gag o fin del tramo)
	# Un corazón menos (R10): sale volando como hojita, "¡uy!" chistoso, el corredor no se cae.
	_tropiezo = 1.0
	_temblor = 0.15
	reproducir_sfx(SFX_UY, 1.1)
	_corazones_volando.append({"pos": _pos_corazon(logica.corazones), "vel": Vector2(60, -40), "t": 0.0})
	if _es_semilla():
		_crunch()


func _al_atravesar(_id: String) -> void:
	_crunch()


func _crunch() -> void:
	reproducir_sfx(SFX_CRUNCH, 1.2)
	var colores := [Color("#E8A33D"), Color("#D9693A"), Color("#F2C84B"), Color("#7DD87A")]
	for k in 12:
		_particulas.append({"pos": _pos_corredor() + Vector2(40, -30), "vel": Vector2(randf_range(-120, 260), randf_range(-420, -160)),
			"r": randf_range(6, 11), "color": colores[k % 4], "vida": 1.0, "forma": "hoja", "g": 500.0})


func _al_coleccionar(_id: String, seguidos: int) -> void:
	var p := _pos_corredor() + Vector2(0, -logica.corredor_alto)
	reproducir_sfx(SFX_COLECCIONABLE, pow(2.0, minf(seguidos - 1, 12) / 12.0), -2.0)
	for k in 8:
		var a := randf() * TAU
		_particulas.append({"pos": p, "vel": Vector2.from_angle(a) * randf_range(80, 220), "r": 5.0, "color": DORADO, "vida": 0.5, "g": 0.0})
	if not _es_semilla() and turnos == null:
		_texto_flotante(p + Vector2(30, -10), "+%d" % int(nivel.get("coleccionables", {}).get("puntos", 25)), Color("#FF8A3D"), 0.9, 34)


func _al_burbuja_nueva() -> void:
	reproducir_sfx(SFX_BURBUJA_NUEVA, 1.2)
	if not presentacion_vista(PRESENTA_BURBUJA):
		marcar_presentacion_vista(PRESENTA_BURBUJA)
		reproducir_voz(_linea("burbuja_presenta"))


func _al_hito(_n: int) -> void:
	if _es_semilla() or turnos != null:
		return
	reproducir_sfx(SFX_HITO, 1.5, -6.0)
	_estira = maxf(_estira, 0.4)


func _al_racha(_n: int) -> void:
	reproducir_sfx(SFX_COLECCIONABLE, 1.8, -4.0)
	for k in 10:
		var a := -PI / 2.0 + randf_range(-1.2, 1.2)
		_particulas.append({"pos": _pos_corredor() + Vector2(-50, -80), "vel": Vector2.from_angle(a) * randf_range(120, 280),
			"r": 6.0, "color": Color.from_hsv(randf(), 0.5, 1.0), "vida": 0.7, "forma": "estrella", "g": 200.0})


## Atardecer (el modo noche de Chrome): el cielo pasa a dorado y después a una noche estrellada, nunca oscura.
func _al_atardecer() -> void:
	_noche_objetivo = 1.0
	reproducir_sfx(SFX_ATARDECER, 1.0, -6.0)


func _al_pasar_mitad() -> void:
	reproducir_sfx(SFX_HITO, 1.2, -4.0)
	_salto_bandera = 1.0


func _al_presentar_aereo() -> void:
	if presentacion_vista(PRESENTA_AEREO):
		return
	marcar_presentacion_vista(PRESENTA_AEREO)
	reproducir_voz(_linea("aereo_presenta"))


func _al_ayuda_mirar() -> void:
	_mira = 1.0
	_rugido = 1.0
	reproducir_sfx(SFX_GUINO, 0.6, -6.0)


func _al_pasar_record() -> void:
	if _record_pasado or _record <= 0:
		return
	_record_pasado = true
	_salto_bandera = 1.0
	reproducir_sfx(SFX_HITO, 1.8)
	_texto_flotante(Vector2(640, 220), "¡Récord!", Color("#FF8A3D"), 1.4, 52)
	for k in 16:
		_particulas.append({"pos": Vector2(LogicaRunner.X_CORREDOR + 30, _suelo - 150), "vel": Vector2(randf_range(-200, 200), randf_range(-420, -160)),
			"r": 6.0, "color": Color.from_hsv(randf(), 0.6, 1.0), "vida": 1.0})


## La meta: la estación queda ganada EN ESTE INSTANTE (QA HE-60 B1), antes del confeti y del tramo.
func _al_llegar_meta() -> void:
	if turnos != null:
		return
	_gano = true
	_puntos_meta = int(logica.puntos)
	_estrellas = _estrellas_por_puntaje(_puntos_meta)
	_destellos = 10 + _estrellas * 5
	_derrotas = 0
	asegurar_victoria(_destellos, _estrellas)
	_fiesta_meta = 0.01
	reproducir_sfx(SFX_META, 1.0)
	var x := _x_meta_pantalla()
	_confeti.position = Vector2(x if x < 1280 else LogicaRunner.X_CORREDOR + 120, _suelo - 160)
	_confeti.restart()
	_confeti.emitting = true
	reproducir_voz(_linea("meta"))
	if logica.estado == "tramo":
		_fase = "tramo"
		get_tree().create_timer(1.6).timeout.connect(func() -> void:
			if _fase == "tramo":
				reproducir_voz(_linea("sigue_record")))
	else:
		_fase = "fiesta_meta"
		_t_fase = 0.0
		partida_terminada.emit(true, _puntos_meta)
		get_tree().create_timer(SEGUNDOS_FIESTA_META_SEMILLA).timeout.connect(_celebrar_victoria)


func _estrellas_por_puntaje(puntos: int) -> int:
	if _umbrales.is_empty():
		return 0 if _es_semilla() else 1
	var e := 1
	if puntos >= int(_umbrales.get("dos", 1 << 30)):
		e = 2
	if puntos >= int(_umbrales.get("tres", 1 << 30)):
		e = 3
	# Ficha §9.2: Sofía, tras una derrota (y con el regalo), máximo 2.
	if obtener_perfil_dificultad() == "estrella" and (_derrotas > 0 or _regalo_en_curso):
		e = mini(e, 2)
	return e


func _al_terminar_carrera(puntaje: int, motivo: String) -> void:
	if turnos != null:
		_fallo_equipo()
		return
	_motivo_fin = motivo
	match motivo:
		"meta":
			pass  # Semilla: ya lo resolvió `_al_llegar_meta`
		"final", "choque_tramo":
			if motivo == "final":
				reproducir_voz(_linea("final_sendero"))
				_confeti.position = Vector2(640, 300)
				_confeti.restart()
				_confeti.emitting = true
			else:
				_tropiezo = 1.0
				reproducir_sfx(SFX_UY)
			var primero := _record <= 0
			_record_nuevo = puntaje > _record and registrar_record(puntaje)
			if _record_nuevo:
				_record = puntaje
				if _barra != null and primero:
					_barra.plantar_banderita()
			partida_terminada.emit(true, puntaje)
			_fase = "resumen"
			_t_fase = 0.0
			if _record_nuevo and motivo != "final":
				reproducir_voz(_linea("primer_record" if primero else "record"))
			get_tree().create_timer(SEGUNDOS_RESUMEN).timeout.connect(_celebrar_victoria)
		"derrota":
			_empezar_gag(puntaje)


func _celebrar_victoria() -> void:
	if _fase != "resumen" and _fase != "fiesta_meta":
		return
	_fase = "celebrando"
	celebrar(_destellos, _estrellas, _linea("victoria"))


# ---------------------------------------------------------------------------
# Derrota-gag y reintento
# ---------------------------------------------------------------------------

func _empezar_gag(puntaje: int) -> void:
	_fase = "gag"
	_t_fase = 0.0
	_derrotas += 1
	partida_terminada.emit(false, puntaje)
	# El récord solo puede subir (también con una carrera perdida, como el "HI" de Chrome).
	if not _es_semilla() and puntaje > _record and registrar_record(puntaje):
		_record = puntaje
		_record_nuevo = true
	reproducir_sfx(SFX_UY, 0.9)
	_temblor = 0.15
	_corazones_volando.append({"pos": _pos_corazon(0), "vel": Vector2(60, -40), "t": 0.0})
	reproducir_voz(_linea("derrota_gag"))
	if not _es_semilla():
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if _fase == "gag":
				reproducir_sfx(SFX_SPLOSH, 0.7)
				_temblor = 0.1)
		get_tree().create_timer(1.7).timeout.connect(_salpicar_barro)
	else:
		get_tree().create_timer(_gag_s * 0.7).timeout.connect(func() -> void:
			if _fase == "gag":
				_estornudo_confeti())


## Gotitas de barro caricaturescas "sobre el vidrio": caen y se limpian solas en 1 s (R5). Sin "menos movimiento".
func _salpicar_barro() -> void:
	if _fase != "gag" or _menos_movimiento:
		return
	for k in 9:
		_gotas_barro.append({"pos": Vector2(randf_range(120, 1160), randf_range(120, 520)), "r": randf_range(14, 30), "vida": 1.0})


## Maxi (§10.1): se sienta en un montón de hojas, le cae una hoja en la nariz y estornuda confeti.
func _estornudo_confeti() -> void:
	reproducir_sfx(SFX_CRUNCH, 1.6)
	for k in 24:
		var a := -PI / 2.0 + randf_range(-1.3, 1.3)
		_particulas.append({"pos": _pos_corredor() + Vector2(50, -120), "vel": Vector2.from_angle(a) * randf_range(160, 420),
			"r": randf_range(4, 8), "color": Color.from_hsv(randf(), 0.6, 1.0), "vida": 1.2, "g": 500.0})


func _mostrar_cartel() -> void:
	_fase = "perdio"
	_fin.show()
	var regalo := _regalo_tras > 0 and _derrotas >= _regalo_tras
	var ayuda := not _ayuda_fuerte.is_empty() and _derrotas >= int(_ayuda_fuerte.get("derrotas", 3))
	if ayuda and _derrotas == int(_ayuda_fuerte.get("derrotas", 3)):
		reproducir_voz(_linea("ayuda_fuerte"))
	elif regalo and _derrotas == _regalo_tras:
		reproducir_voz(_linea("regalo"))
	elif _descanso_tras > 0 and _derrotas == _descanso_tras:
		reproducir_voz(_linea("descansar"))


## Reintento de un toque: largada corta sin voz. Con la banderita (si se pasó), el regalo o la ayuda fuerte.
func reintentar() -> void:
	if _fase != "perdio":
		return
	reproducir_sfx(SFX_GUINO, 1.2)
	_fin.hide()
	_particulas.clear()
	_textos.clear()
	_gotas_barro.clear()
	_record_nuevo = false
	_record_pasado = false
	_noche = 0.0
	_noche_objetivo = 0.0
	_regalo_en_curso = _regalo_tras > 0 and _derrotas >= _regalo_tras
	_ayuda_fuerte_en_curso = not _ayuda_fuerte.is_empty() and _derrotas >= int(_ayuda_fuerte.get("derrotas", 3))
	var con_burbuja := _regalo_en_curso and str(_regalo.get("tipo", "burbuja")) == "burbuja"
	var extra := int(_regalo.get("corazones", 1)) if _regalo_en_curso and str(_regalo.get("tipo", "")) == "corazon_extra" else 0
	if _regalo_en_curso and bool(_regalo.get("banderita_mitad", false)):
		logica.banderita_mitad = true
	if _ayuda_fuerte_en_curso:
		# La victoria queda asegurada: todo se atraviesa sin gastar corazones ("¡carrera de hojas!").
		logica.blandos = bool(_ayuda_fuerte.get("obstaculos_blandos", true))
		logica.ayuda_fuerte = not logica.blandos
	_desde_mitad = logica.banderita_mitad and logica.tiene_mitad()
	if not _desde_mitad:
		logica.semilla += 1  # otra secuencia (reproducible), como Chrome
	logica.reiniciar(_desde_mitad, con_burbuja, extra)
	if _desde_mitad:
		reproducir_voz(_linea("mitad"))
	if logica.t >= logica.atardecer_en * logica.meta_s:
		_noche = 1.0
		_noche_objetivo = 1.0
	if _barra != null:
		_barra.preparar(_record, float(_umbrales.get("tres", 2000)) * 1.3)
		_barra.fijar_puntaje(int(logica.puntos))
	_empezar(false)


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _pos_corredor() -> Vector2:
	return Vector2(LogicaRunner.X_CORREDOR, _suelo - logica.y)


func _x_meta_pantalla() -> float:
	return logica.x_meta


func _dibujar_juego() -> void:
	Dibujos.fondo(_juego, _escenario, _scroll, _noche, _t, _suelo, _aurora)
	# Meta
	var xm := logica.x_meta
	if xm != INF and xm < 1500.0:
		Dibujos.meta(_juego, _meta_dibujo, Vector2(xm + 60.0, _suelo), _t, _fiesta_meta)
	# Banderita a la mitad (Nicole, Maxi, o Sofía con regalo) y banderita del récord en el mundo.
	_dibujar_banderitas()
	# Coleccionables
	for it in logica.items:
		if it["tomado"]:
			continue
		var p := Vector2(it["x"], _suelo - it["altura"])
		p = _pos_gag(p)
		if it["tipo"] == "burbuja":
			Dibujos.burbuja(_juego, p, it["radio"], _t)
		else:
			Dibujos.item(_juego, it["id"], p, it["radio"], _t)
	# Obstáculos (la sombra primero)
	for o in logica.obstaculos:
		for k in int(o["n"]):
			var x: float = o["x"] + k * o["e"]
			var abajo: float = _suelo - (o["altura"] if o["tipo"] != "suelo" else 0.0)
			var r := Rect2(Vector2(x, abajo - o["alto"]), Vector2(o["e"], o["alto"]))
			r.position = _pos_gag(r.position + r.size / 2.0) - r.size / 2.0
			if o["tipo"] != "suelo":
				_juego.draw_circle(Vector2(r.get_center().x, _suelo + 4), o["e"] * 0.3, Color(0, 0, 0, 0.1))
				Dibujos.aereo(_juego, o["dibujo"], r, _t, int(o["sid"]) + k)
			else:
				Dibujos.obstaculo(_juego, o["dibujo"], r, _t, int(o["sid"]) + k)
	_dibujar_corredor()
	# Partículas
	for p in _particulas:
		var a := clampf(p["vida"] * 2.0, 0.0, 1.0)
		var col: Color = p["color"]
		match p.get("forma", ""):
			"estrella":
				_juego.draw_colored_polygon(Dibujos.estrella_pts(p["pos"], p["r"]), Color(col, a))
			"hoja":
				_juego.draw_colored_polygon(Dibujos.elipse_pts(p["pos"], Vector2(p["r"], p["r"] * 0.5), p["vida"] * 8.0), Color(col, a))
			_:
				_juego.draw_circle(p["pos"], p["r"], Color(col, a))
	for x in _textos:
		var k: float = x["t"] / x["dur"]
		var esc := 0.7 + k * 2.0 if k < 0.15 else 1.0
		var alfa := (1.0 - k) / 0.25 if k > 0.75 else 1.0
		_texto(_juego, x["texto"], x["pos"] - Vector2(0, k * 40.0), int(x["tam"] * esc), Color(x["color"], alfa))


func _dibujar_banderitas() -> void:
	if turnos != null:
		return
	if logica.banderita_mitad and not logica.meta_alcanzada:
		var t_falta := logica.t_mitad() - logica.t
		var x := LogicaRunner.X_CORREDOR + t_falta * logica.velocidad
		if x > -100.0 and x < 1400.0:
			Dibujos.banderita_record(_juego, Vector2(x, _suelo), Color("#B48CE8"), null, _salto_bandera)
	if _record > 0 and not _es_semilla() and (_fase == "corriendo" or _fase == "tramo" or _fase == "intro"):
		var x := LogicaRunner.X_CORREDOR + 30.0 + (_record - logica.puntos) * logica.v0 / maxf(1.0, float(logica.puntos_cfg.get("por_segundo", 10)))
		if x > -100.0 and x < 1400.0:
			var color: Color = COLORES_HERMANO.get(obtener_id_personaje(), DORADO)
			Dibujos.banderita_record(_juego, Vector2(x, _suelo), color, null, _salto_bandera, true)
		if not _record_pasado and logica.puntos > _record and _barra == null:
			_al_pasar_record()


func _dibujar_corredor() -> void:
	var id := _corredor_actual()
	var alto := logica.corredor_alto
	var pies := _pos_corredor()
	var escala := Vector2.ONE
	if logica.fase_salto == "impulso":
		escala = Vector2(1.2, 0.8)
	elif _squash > 0.0:
		escala = Vector2(1.0 + 0.2 * _squash, 1.0 - 0.2 * _squash)
	elif logica.fase_salto == "aire" and logica.t_aire < logica.duracion_salto * 0.5:
		escala = Vector2(0.9, 1.15)
	var rot := 0.0
	var barro := 0.0
	var boca := "abierta" if _rugido > 0.3 or logica.fase_salto == "aire" else "feliz"
	if _voltereta > 0.0:
		rot = (1.0 - _voltereta) * TAU
	if _tropiezo > 0.0 and _fase != "gag":
		rot = sin(_tropiezo * PI) * -0.5
		boca = "oh"
	# Gag de derrota
	if _fase == "gag" or _fase == "perdio":
		var k := _t_fase if _fase == "gag" else _gag_s
		if _es_semilla() and turnos == null:
			# Sentado en las hojas, con una hoja en la nariz.
			escala = Vector2(1.1, 0.85)
			boca = "oh" if k < _gag_s * 0.7 else "abierta"
			pies = Vector2(LogicaRunner.X_CORREDOR + 20, _suelo)
			Dibujos.obstaculo(_juego, "hojas", Rect2(pies + Vector2(-80, -40), Vector2(160, 46)), _t, 3)
		else:
			if k < 1.2:
				rot = k / 1.2 * TAU * 3.0
				pies = Vector2(LogicaRunner.X_CORREDOR + k * 120.0, _suelo - sin(k / 1.2 * PI) * 60.0)
			else:
				pies = Vector2(LogicaRunner.X_CORREDOR + 144.0, _suelo)
				Dibujos.elipse(_juego, pies + Vector2(0, -6), Vector2(110, 22), Color("#8A5A3A"))
				Dibujos.elipse(_juego, pies + Vector2(-20, -12), Vector2(30, 6), Color("#A87650"), 0.0, false)
				escala = Vector2(1.1, 0.9)
				barro = 1.0
				boca = "abierta"
				if k > 1.5 and k < 2.3:
					rot = sin(k * 40.0) * 0.15  # se sacude como perrito
			_dibujar_risas(k)
	var pose := {"fase": _ciclo, "aire": logica.fase_salto == "aire", "escala": escala, "rot": rot, "t": _t,
		"parpadeo": fmod(_t, 3.4) < 0.12 or _guino > 0.5, "boca": boca, "barro": barro, "cuello": _cuello_jirafa()}
	if logica.invulnerable > 0.0 and fmod(_t, 0.16) < 0.08 and _fase != "gag":
		return  # parpadeo de 1 s sin choques
	if id == "tres_dinos" and (_fase == "corriendo" or _fase == "intro" or _fase == "fiesta_meta"):
		# Los tres dinos en fila: saltan en cadena con el mismo toque (solo dibujo).
		for q in [2, 1]:
			var retraso := q * 0.13
			var yq := _altura_en(logica.t_aire - retraso) if logica.fase_salto == "aire" else 0.0
			var pq := Vector2(pies.x - q * 120.0, _suelo - yq)
			var otra := pose.duplicate()
			otra["fase"] = _ciclo + q * 1.3
			otra["aire"] = yq > 0.0
			Dibujos.corredor(_juego, "carno" if q == 2 else "spino", pq, alto * 0.85, otra)
	_juego.draw_colored_polygon(Dibujos.elipse_pts(Vector2(LogicaRunner.X_CORREDOR, _suelo + 2), Vector2(46 - minf(logica.y, 200) * 0.1, 8)), Color(0, 0, 0, 0.12))
	Dibujos.corredor(_juego, id, pies, alto, pose)
	if logica.burbuja and _fase != "gag":
		Dibujos.burbuja(_juego, pies + Vector2(6, -alto * 0.5), alto * 0.62, _t)
	if _ayuda_fuerte_en_curso and (_fase == "corriendo") and turnos == null:
		Dibujos.burbuja(_juego, pies + Vector2(6, -alto * 0.5), alto * 0.66, _t * 2.0, 0.35)


func _altura_en(t_aire: float) -> float:
	var k := clampf(t_aire / logica.duracion_salto, 0.0, 1.0)
	return logica.altura_actual * 4.0 * k * (1.0 - k)


## La jirafa agacha el cuello cuando se acerca un aéreo alto (gag de la ficha de zonas §12.5).
func _cuello_jirafa() -> float:
	if _corredor_actual() != "jirafa":
		return 0.0
	for o in logica.obstaculos:
		if o["tipo"] == "aereo_alto" and o["x"] < LogicaRunner.X_CORREDOR + 320.0 and o["x"] + o["e"] > LogicaRunner.X_CORREDOR - 80.0:
			return 1.0
	return 0.0


## Los pajaritos se ríen del gag (y Toby se tapa la boca si no es el corredor).
func _dibujar_risas(k: float) -> void:
	for q in 2:
		var p := Vector2(560 + q * 90, 300 + sin(_t * 8.0 + q) * 10.0)
		Dibujos.aereo(_juego, "pajarito", Rect2(p, Vector2(60, 50)), _t, q)
		if k > 0.6:
			_texto(_juego, "ja", p + Vector2(30, -30 - fmod(_t * 30.0 + q * 15, 30)), 26, Color("#655D82"))
	if _corredor_actual() != "toby":
		var pies := Vector2(1080, _suelo)
		Dibujos.corredor(_juego, "toby", pies, 130.0, {"t": _t, "boca": "abierta", "parpadeo": true})
		Dibujos.circulo(_juego, pies + Vector2(40, -120), 12.0, Color("#FFF6E6"))


func _dibujar_hud() -> void:
	if nivel.is_empty():
		return
	# Gotitas de barro "sobre el vidrio".
	for g in _gotas_barro:
		var a := clampf(g["vida"] * 1.5, 0.0, 1.0)
		_hud.draw_circle(g["pos"], g["r"], Color(0.48, 0.32, 0.2, 0.75 * a))
		_hud.draw_circle(g["pos"] + Vector2(-g["r"] * 0.3, -g["r"] * 0.3), g["r"] * 0.25, Color(1, 1, 1, 0.4 * a))
	if turnos != null:
		_dibujar_camino(Vector2(0, 92), float(_eq_logrados) / maxf(1.0, _eq_total))
		return
	_dibujar_camino(Vector2.ZERO, logica.progreso_meta())
	_dibujar_corazones()
	if _mostrar == "numero":
		var caja := Rect2(1000, 14, 262, 74)
		_hud.draw_style_box(_caja_hud(), caja)
		_texto(_hud, str(int(logica.puntos)), Vector2(caja.position.x + 78, caja.position.y + 40), 40, TINTA)
		var color: Color = COLORES_HERMANO.get(obtener_id_personaje(), DORADO)
		_hud.draw_colored_polygon(PackedVector2Array([Vector2(caja.position.x + 156, caja.position.y + 20), Vector2(caja.position.x + 184, caja.position.y + 30), Vector2(caja.position.x + 156, caja.position.y + 40)]), color)
		_hud.draw_line(Vector2(caja.position.x + 156, caja.position.y + 18), Vector2(caja.position.x + 156, caja.position.y + 58), TINTA, 3.0)
		_texto(_hud, str(maxi(_record, int(logica.puntos))), Vector2(caja.position.x + 216, caja.position.y + 40), 28, Color("#2E9E5B"))
	elif _mostrar == "barra" and _barra != null and (_fase == "corriendo" or _fase == "tramo"):
		if int(logica.puntos) != _barra.puntaje():
			_barra.fijar_puntaje(int(logica.puntos))


## "Camino a la meta": huellitas con la cara del corredor que avanza hacia la banderita, sin números.
func _dibujar_camino(desplaz: Vector2, frac: float) -> void:
	var r := Rect2(RECT_CAMINO.position + desplaz, RECT_CAMINO.size)
	var y := r.get_center().y
	var fondo := _caja_hud()
	fondo.set_corner_radius_all(20)
	_hud.draw_style_box(fondo, r.grow_individual(18, 10, 40, 10))
	for k in 12:
		var x := r.position.x + r.size.x * k / 11.0
		var hecho := k / 11.0 <= frac
		_hud.draw_circle(Vector2(x, y + (3 if k % 2 == 0 else -3)), 5.0, Color("#C9813F") if hecho else Color("#D9CFC0"))
	var fin := Vector2(r.end.x + 14, y)
	_hud.draw_line(fin + Vector2(0, 14), fin + Vector2(0, -22), TINTA, 3.0)
	_hud.draw_colored_polygon(PackedVector2Array([fin + Vector2(0, -22), fin + Vector2(22, -14), fin + Vector2(0, -6)]), Color("#FF8FC4"))
	if turnos == null and logica.banderita_mitad:
		var mx := r.position.x + r.size.x * 0.5
		var pasada := logica.tiene_mitad() or logica.t >= logica.t_mitad()
		_hud.draw_line(Vector2(mx, y + 10), Vector2(mx, y - 18), TINTA, 2.0)
		_hud.draw_colored_polygon(PackedVector2Array([Vector2(mx, y - 18), Vector2(mx + 16, y - 12), Vector2(mx, y - 6)]), Color("#B48CE8") if pasada else Color("#D9CFC0"))
	var cara := Vector2(r.position.x + r.size.x * clampf(frac, 0.0, 1.0), y)
	if turnos != null:
		for id in turnos.orden_unico():
			var col: Color = COLORES_HERMANO.get(id, DORADO)
			_hud.draw_circle(cara + Vector2(0, -2), 18.0, TINTA)
			_hud.draw_circle(cara + Vector2(0, -2), 16.0, col)
			cara.x -= 16.0
		return
	var color: Color = COLOR_CORREDOR.get(_corredor, DORADO)
	_hud.draw_circle(cara, 19.0, TINTA)
	_hud.draw_circle(cara, 17.0, color)
	Dibujos.ojo(_hud, cara + Vector2(-5, -2), 4.0, false)
	Dibujos.ojo(_hud, cara + Vector2(6, -2), 4.0, false)
	_hud.draw_arc(cara + Vector2(0, 5), 5.0, 0.3, PI - 0.3, 8, TINTA, 2.0, true)


func _pos_corazon(i: int) -> Vector2:
	var lado := 30.0 if _es_semilla() else 24.0
	return Vector2(270.0 + i * lado * 2.3, 64.0)


func _dibujar_corazones() -> void:
	var total := maxi(logica.corazones_max, logica.corazones)
	var lado := 30.0 if _es_semilla() else 24.0
	for i in total:
		var c := _pos_corazon(i)
		var lleno := i < logica.corazones
		if lleno:
			var latido := 1.0 + 0.06 * sin(_t * 5.0 + i)
			Dibujos.poligono(_hud, Dibujos.corazon_pts(c, lado * latido), ROSA_CORAZON)
			_hud.draw_circle(c + Vector2(-lado * 0.35, -lado * 0.3), lado * 0.14, Color(1, 1, 1, 0.7))
		else:
			_hud.draw_polyline(Dibujos.corazon_pts(c, lado * 0.9) + PackedVector2Array([Dibujos.corazon_pts(c, lado * 0.9)[0]]), Color(1, 1, 1, 0.65), 3.0, true)
	for cv in _corazones_volando:
		var a := 1.0 - cv["t"] / 1.4
		_hud.draw_set_transform(cv["pos"], sin(cv["t"] * 8.0) * 0.6, Vector2.ONE)
		_hud.draw_colored_polygon(Dibujos.corazon_pts(Vector2.ZERO, lado * 0.8), Color(ROSA_CORAZON, a))
		_hud.draw_set_transform_matrix(Transform2D.IDENTITY)


## Cartel de "¡Al barro!" (o las hojas de Maxi): puntaje, banderita del récord y la flecha grande.
func _dibujar_fin() -> void:
	_fin.draw_rect(Rect2(Vector2.ZERO, _fin.size), Color(0.17, 0.2, 0.31, 0.3))
	var tarjeta := Rect2(390, 130, 500, 450)
	var caja := _caja_hud()
	caja.set_corner_radius_all(48)
	caja.bg_color = CREMA
	_fin.draw_style_box(caja, tarjeta)
	var rebote := sin(_t * 5.0) * 6.0
	var titulo := "¡Achís!" if _es_semilla() else "¡Al barro!"
	_texto(_fin, titulo, Vector2(640, 196 + rebote), 56, Color("#8A5A3A"))
	if not _es_semilla():
		_texto(_fin, str(int(logica.puntos)), Vector2(590, 270), 44, TINTA)
		var color: Color = COLORES_HERMANO.get(obtener_id_personaje(), DORADO)
		_fin.draw_line(Vector2(660, 252), Vector2(660, 292), TINTA, 3.0)
		_fin.draw_colored_polygon(PackedVector2Array([Vector2(660, 252), Vector2(690, 262), Vector2(660, 274)]), color)
		_texto(_fin, str(_record), Vector2(730, 272), 32, Color("#2E9E5B"))
		if _record_nuevo:
			_texto(_fin, "¡Nuevo récord!", Vector2(640, 326), 30, Color("#FF8A3D"))
	# Lo que trae el reintento: un regalo de la mascota o la ayuda fuerte, sin texto obligatorio.
	var regalo := _regalo_tras > 0 and _derrotas >= _regalo_tras
	var ayuda := not _ayuda_fuerte.is_empty() and _derrotas >= int(_ayuda_fuerte.get("derrotas", 3))
	var p := Vector2(820, 200)
	if ayuda:
		Dibujos.obstaculo(_fin, "hojas", Rect2(p + Vector2(-34, -10), Vector2(68, 40)), _t, 1)
	elif regalo:
		if str(_regalo.get("tipo", "")) == "corazon_extra":
			Dibujos.poligono(_fin, Dibujos.corazon_pts(p + Vector2(0, 8 + rebote * 0.5), 26.0), ROSA_CORAZON)
		else:
			Dibujos.burbuja(_fin, p + Vector2(0, 8 + rebote * 0.5), 30.0, _t)
	if _es_semilla() or _corredor != "":
		Dibujos.corredor(_fin, _corredor, Vector2(470, 560), 110.0, {"t": _t, "boca": "abierta", "barro": 0.0 if _es_semilla() else 0.8})


func _texto(lienzo: CanvasItem, texto: String, centro: Vector2, tamano: int, color: Color) -> void:
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var base := centro + Vector2(-ancho / 2.0, tamano * 0.35)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, maxi(4, int(tamano * 0.18)), Color(1, 1, 1, 0.95 * color.a))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


func _texto_flotante(posicion: Vector2, texto: String, color: Color, duracion: float, tamano: int) -> void:
	if turnos != null:
		return  # en equipo ningún número ni texto (R2)
	_textos.append({"pos": posicion, "texto": texto, "color": color, "t": 0.0, "dur": duracion, "tam": tamano})


func _polvito(p: Vector2, n: int) -> void:
	for k in n:
		_particulas.append({"pos": p + Vector2(randf_range(-16, 16), -4), "vel": Vector2(randf_range(-140, -20), randf_range(-90, -20)),
			"r": randf_range(4, 8), "color": Color(0.85, 0.75, 0.6, 0.8), "vida": 0.45, "g": 0.0})


func _caja_hud() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(CREMA, 0.92)
	caja.border_color = Color("#2B3350")
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(40)
	caja.anti_aliasing = true
	return caja


func _linea(clave: String) -> String:
	var lineas = nivel.get("lineas_voz", {}).get(clave, "")
	if lineas is Array:
		return str(lineas.pick_random()) if not lineas.is_empty() else ""
	return str(lineas) if str(lineas) != "PENDIENTE" else ""


func _es_semilla() -> bool:
	return obtener_perfil_dificultad() == "semilla"


func _es_dino() -> bool:
	return _corredor_actual() in ["trex", "spino", "carno", "trex_bombero", "tres_dinos"]


func _corredor_actual() -> String:
	return _corredor


# ---------------------------------------------------------------------------
# Botones e íconos
# ---------------------------------------------------------------------------

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
		caja.border_color = Color("#2B3350")
		caja.set_border_width_all(5)
		caja.set_corner_radius_all(90)
		caja.shadow_color = Color(0.17, 0.2, 0.31, 0.3)
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


func _dibujar_cometa(icono: Control) -> void:
	if _textura_cometa == null:
		Dibujos.circulo(icono, icono.size / 2.0, 30.0, Color("#7DD8C9"))
		return
	var alto := icono.size.y * 0.82
	var ancho := alto * _textura_cometa.get_width() / float(_textura_cometa.get_height())
	var c := icono.size / 2.0 + Vector2(0, sin(_t * 2.0) * 2.0)
	icono.draw_texture_rect(_textura_cometa, Rect2(c - Vector2(ancho, alto) / 2.0, Vector2(ancho, alto)), false)


## Flecha circular de "otra vez" (sin texto, GDD §6 regla 3).
func _dibujar_icono_reintentar(icono: Control) -> void:
	var c := icono.size / 2.0
	var r := icono.size.x * 0.27
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, Color("#2B3350"), 22.0, true)
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, CREMA, 13.0, true)
	var punta := c + Vector2.from_angle(-PI * 0.15) * r
	var flecha := PackedVector2Array([punta + Vector2(-22, -6), punta + Vector2(18, -10), punta + Vector2(4, 26)])
	icono.draw_colored_polygon(flecha, CREMA)
	Figura.contornear(icono, flecha, 5.0)


# ---------------------------------------------------------------------------
# Modo equipo: la carrera de postas (§12.2)
# ---------------------------------------------------------------------------

func _preparar_equipo() -> void:
	var bloque = nivel.get("equipo", {})
	_eq = bloque if bloque is Dictionary else {}
	_suelo = SUELO_EQUIPO
	_boton_cometa.hide()  # Cometa vive en la pista del gestor
	_boton_salir.position = Vector2(1172, 8)
	_boton_salir.size = Vector2(100, 96)
	var perfiles := {}
	for id in equipo:
		perfiles[id] = perfil_de(id)
	var comps = _eq.get("composiciones", {})
	var comp: Dictionary = {}
	if comps is Dictionary and not comps.is_empty():
		comp = comps.get(_clave_equipo(), comps.values()[0])
	_eq_total = int(comp.get("obstaculos_meta", _eq.get("obstaculos_meta", 30)))
	var config: Dictionary = _eq.duplicate(true)
	config.erase("composiciones")
	config.erase("perfiles")
	config["pasos_rival"] = int(comp.get("pasos_rival", _eq.get("pasos_rival", 5)))
	config["aciertos_totales"] = _eq_total
	config["lineas_voz"] = nivel.get("lineas_voz", {})
	var record := -1
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and not en_batalla:
		record = progreso.obtener_record_equipo(planeta_id, _id_nivel_actual(), _clave_equipo())
	config["record_pasos"] = record
	var ui: Control = _boton_salir.get_parent()
	turnos.configurar(equipo, config, perfiles, ui)
	var capa := ui.get_node_or_null("capa_equipo")
	if capa != null:
		ui.move_child(capa, _hud.get_index())
	turnos.turno_iniciado.connect(func(_id: String, perfil: String) -> void: aplicar_perfil_turno(perfil))
	turnos.tope_alcanzado.connect(_al_tope_equipo)
	turnos.jugada_automatica_pedida.connect(_jugada_automatica_equipo)
	_fase = "corriendo"
	logica.estado = "quieto"
	_arrancar_equipo.call_deferred()


func _clave_equipo() -> String:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null:
		return progreso.clave_equipo(equipo)
	var copia := equipo.duplicate()
	copia.sort()
	return "+".join(PackedStringArray(copia))


func _arrancar_equipo() -> void:
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or _eq_victoria:
		return
	var intro := _linea("intro_ronda")
	if intro != "" and ResourceLoader.exists(resolver_ruta_audio(intro)):
		reproducir_voz(intro)
		await _esperar_voz_libre(6.0)
	if not is_inside_tree() or _eq_victoria:
		return
	turnos.empezar()


## La posta: el corredor, la velocidad, el salto, los huecos y los aéreos del perfil que juega ahora.
func aplicar_perfil_turno(perfil: String) -> void:
	var capas = _eq.get("perfiles", {})
	var capa: Dictionary = capas.get(perfil, {}) if capas is Dictionary else {}
	var params := nivel.duplicate(true)
	for clave in capa:
		params[clave] = capa[clave]
	params.erase("burbuja")  # en equipo no hay burbuja (§12.2)
	_corredor = str(params.get("corredor", {}).get("id", "toby"))
	logica.preparar_tramo(params, float(params.get("inicio_libre_s", 1.5)))
	_eq_cerrando = false
	_eq_falla = false
	_fase = "corriendo"
	reproducir_sfx(SFX_POSTA, 1.0, -4.0)


func _turno_jugable() -> bool:
	return turnos != null and turnos.turno_activo() and not turnos.entrada_bloqueada() and not _eq_cerrando \
		and not _eq_victoria and logica.estado == "jugando"


func _pase_equipo(limpio: bool) -> void:
	if not limpio or _eq_victoria or not turnos.turno_activo():
		return
	_eq_logrados += 1
	turnos.notificar_acierto()
	if _eq_logrados >= _eq_total:
		_victoria_equipo()


## Tope del turno: los obstáculos que faltan se van con un "puf", el corredor frena y, quieto, entrega la posta.
func _al_tope_equipo() -> void:
	if _eq_victoria:
		return
	_eq_tramos += 1
	logica.frenar()
	reproducir_sfx(SFX_CRUNCH, 1.4, -6.0)
	_esperar_quieto_y(func() -> void: turnos.confirmar_turno_estable())


## Choque sin burbuja: tropiezo, se sienta y el turno termina con fallo.
func _fallo_equipo() -> void:
	if _eq_victoria or _eq_cerrando:
		return
	_eq_cerrando = true
	logica.estado = "jugando"
	logica.frenar()
	_esperar_quieto_y(func() -> void: turnos.terminar_turno(true))


func _esperar_quieto_y(accion: Callable) -> void:
	var id_turno := turnos.hermano_actual()
	while is_inside_tree() and logica.estado != "quieto":
		await get_tree().process_frame
	await get_tree().create_timer(SEGUNDOS_POSTA_QUIETO).timeout
	if not is_inside_tree() or _eq_victoria or turnos.hermano_actual() != id_turno:
		return
	accion.call()


## Maxi sin tocar `semilla_auto_s`: el dino salta solo el siguiente obstáculo (cuenta como paso limpio).
func _jugada_automatica_equipo() -> void:
	if not _turno_jugable() or turnos.perfil_actual() != "semilla":
		return
	reproducir_voz(_linea("maxi_regalito"))
	logica._auto_una_vez = true


func _procesar_equipo(delta: float) -> void:
	if not _eq_gag.is_empty():
		_eq_gag["t"] += delta
		if _eq_gag["fase"] == "aspirar" and _eq_gag["t"] >= _eq_gag["dur"]:
			_eq_gag["fase"] = "oculto"
		elif _eq_gag["fase"] == "devolver" and _eq_gag["t"] >= _eq_gag["dur"]:
			_eq_gag = {}


func _pos_gag(p: Vector2) -> Vector2:
	if _eq_gag.is_empty():
		return p
	if _eq_gag["fase"] == "oculto":
		return Vector2(-999, -999)
	var k := clampf(_eq_gag["t"] / maxf(0.01, _eq_gag["dur"]), 0.0, 1.0)
	if _eq_gag["fase"] == "devolver":
		k = 1.0 - k
	return p.lerp(_eq_gag["destino"], k * k)


func _victoria_equipo() -> void:
	if _eq_victoria:
		return
	_eq_victoria = true
	_fase = "resumen"
	var pasos := turnos.pasos_usados()
	turnos.detener()
	logica.frenar()
	_confeti.position = Vector2(640, 300)
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
	celebrar_equipo(pasos, _linea("victoria_equipo"))


func ancla_meta_turno() -> Vector2:
	return Vector2(150, 300)


func gag_derrota_aspirar(destino: Vector2) -> float:
	_eq_gag = {"fase": "aspirar", "t": 0.0, "dur": 0.8, "destino": destino}
	return 0.8


func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	var destino: Vector2 = _eq_gag.get("destino", Vector2(640, 60))
	# Vuelven más adelante, con aire para arrancar.
	for o in logica.obstaculos:
		o["x"] += 500.0
	for it in logica.items:
		it["x"] += 500.0
	_eq_gag = {"fase": "devolver", "t": 0.0, "dur": 0.6, "destino": destino}
	return 0.6


func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	_eq_gag = {}


func contar_logro_equipo() -> int:
	return _eq_tramos


func obtener_parcial_equipo() -> Dictionary:
	return {"logrados": _eq_logrados, "tramos": _eq_tramos}


func restaurar_parcial_equipo(estado: Dictionary) -> void:
	_eq_logrados = int(estado.get("logrados", 0))
	_eq_tramos = int(estado.get("tramos", 0))
