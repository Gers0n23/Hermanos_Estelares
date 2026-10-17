class_name MotorRio
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecánica "rio" — «Río de pintura», tipo Zuma (ficha docs/fichas/motor-rio.md v2).
## Primer juego del Planeta Arcoíris para los tres hermanos (decisión del PO 06-Oct-2026): Coco, en su
## plato giratorio al centro, atrapa y dispara gotas con la lengua a un río de pintura que avanza por un
## cauce de galleta hacia el remolino gris. Tres iguales juntas revientan; si los extremos del corte
## coinciden, se atraen, chocan ("¡clac!") y revientan en cadena.
##
## v2 (HE-91, decisiones del PO del 17-Oct-2026): grupos más largos por hermano, retroceso espectacular,
## combo separado de la cadena, gota arcoíris salvavidas y, para Nicole y Sofía, la batidora sobre un
## puente (se le disparan primarios; la palanca sirve 2 disparos del color mezclado; el río pasa por un
## túnel debajo). Ya no hay mezcla dentro del río. Batidora, puente, túnel y palanca están dibujados por
## código: arte PROVISIONAL hasta HE-93.
##
## Las reglas viven en `LogicaRio` (probadas por `herramientas/qa_test_rio.gd`); aquí solo hay dibujo,
## entrada y el flujo de ganar o perder. Todo lo que cambia entre hermanos llega en el JSON del nivel.
##
## Entrada: tocar (o arrastrar) apunta y al soltar Coco dispara; tocar a Coco cambia la gota de la
## boca con la de la mano; tocar la palanca sirve. Perder nunca castiga: "¡Glu glu glu!" y reintento de
## un toque (GDD §6). PC: espacio dispara, Tab intercambia, S sirve.

signal partida_terminada(gano: bool, puntos: int)

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const TEXTURA_COCO := preload("res://assets/sprites/personajes/coco_base.png")

const PALETA := {
	"rojo": Color("#E8434B"), "amarillo": Color("#FFC83A"), "azul": Color("#3D7BE0"),
	"verde": Color("#36B866"), "naranja": Color("#FF8A3D"), "violeta": Color("#9B5DE5"),
	"rosa": Color("#FF7EB6"), "celeste": Color("#5CC8F0"),
	# Colores de 2 + 1 (ids provisionales hasta HE-94) y el café de la batidora.
	"rojo_naranja": Color("#F2582B"), "amarillo_naranja": Color("#FFAA2E"), "amarillo_verde": Color("#AFD13A"),
	"azul_verde": Color("#1FA39A"), "azul_violeta": Color("#5A5FD8"), "rojo_violeta": Color("#C93E8E"),
	"cafe": Color("#8B5A3C"),
}
const GAJOS_ARCOIRIS := ["#E8434B", "#FF8A3D", "#FFC83A", "#36B866", "#3D7BE0", "#9B5DE5"]
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
## SFX PROVISIONALES: se reusan los de la interfaz con otro tono hasta tener los propios del Río
## (clac, boing, glug, fiuuu, puaj, arpegio arcoíris, cuerda elástica; ficha §6, §9 y §10).
const SFX_LENGUA := "sfx/ui/toque.ogg"
const SFX_INSERTA := "sfx/ui/soltar.ogg"
const SFX_REVIENTA := "sfx/ui/confirmar.ogg"
const SFX_CAMBIO := "sfx/ui/seleccionar.ogg"
const SFX_GLU := "sfx/ui/zona_dormida.ogg"
const SFX_GANA := "sfx/ui/abrir.ogg"
const SFX_CLAC := "sfx/ui/toque.ogg"
const SFX_BOING := "sfx/ui/blup.ogg"
const SFX_GLUG := "sfx/ui/soltar.ogg"
const SFX_SERVIR := "sfx/ui/abrir.ogg"
const SFX_PUAJ := "sfx/ui/puf.ogg"
const SFX_PUF := "sfx/ui/puf.ogg"
const SFX_ARCOIRIS := "sfx/ui/confirmar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const TINTA := Color("#272140")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
## Coco: altura en pantalla, distancia de la gota cargada al centro y radio para tocarla.
const ALTO_COCO := 168.0
const ORBITA := 86.0
const RADIO_TOQUE_COCO := 72.0
## Palanca: dibujo de 72 px y zona de toque de 96 px (ficha §10.6).
const RADIO_PALANCA := 36.0
const RADIO_TOQUE_PALANCA := 48.0
const PELIGRO := 0.82
const SEGUNDOS_RESUMEN_VICTORIA := 2.4
const PRESENTACION_BATIDORA := "rio_batidora"

@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _boton_salir: Button = %boton_salir
@onready var _fin: Control = %fin
@onready var _boton_reintentar: Button = %boton_reintentar
@onready var _confeti: CPUParticles2D = %confeti

var logica := LogicaRio.new()
var recorrido: RecorridoRio
var _fuente: Font
var _cauce: Control

# Configuración visual (del nivel)
var _guia := "completa"  ## completa | corta | no
var _guia_largo := 1280.0
var _tiempo_par := 70.0
var _semilla := -1
var _pistas := false  ## flechas de la batidora en este río (§10.8)
var _menos_movimiento := false  ## sin temblor de pantalla (opción de la zona de padres, cuando exista)

# Estado de pantalla
var _t := 0.0
var _angulo := -PI / 2.0
var _apuntando := false
var _mirando := 1.0  ## 1 derecha, -1 izquierda (con histéresis, para que no tiemble)
var _lengua := 0.0  ## 0-1: estirón de la lengua al disparar
var _carga := 1.0  ## 0-1: la gota nueva "brota" en la boca
var _salto := 0.0
var _giro_coco := 0.0
var _tinte := Color.WHITE
var _gris := 0.0  ## 0-1: Coco chorreada después del glu glu
var _particulas: Array = []  ## {"pos", "vel", "r", "color", "vida", "sube"}
var _textos: Array = []  ## {"pos", "texto", "color", "t", "dur", "tam"}
var _anillos: Array = []  ## {"pos", "t", "dur", "color", "r0", "r1"}
var _vuelos: Array = []  ## gotas que vuelan a la boca de Coco: {"desde", "t", "dur", "color"}
var _temblor := 0.0
var _batidora_tiembla := 0.0
var _palanca_hundida := 0.0
var _record := 0
var _record_nuevo := false
var _estrellas := 0
var _fase := "jugando"  ## jugando | tragando | resumen | celebrando | perdio


func _ready() -> void:
	super._ready()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_estilizar_boton(_boton_salir, CREMA)
	_estilizar_boton(_boton_reintentar, DORADO)
	_icono(_boton_salir, _dibujar_flecha)
	_icono(_boton_reintentar, _dibujar_icono_reintentar)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_boton_reintentar.pressed.connect(reintentar)
	_fin.gui_input.connect(_al_input_fin)
	_fin.draw.connect(_dibujar_fin)
	_fin.hide()
	# El cauce no cambia: se dibuja una vez en su propio Control, detrás de las gotas.
	_cauce = Control.new()
	_cauce.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_juego.add_child(_cauce)
	_cauce.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cauce.show_behind_parent = true
	_cauce.draw.connect(_dibujar_cauce)
	_juego.gui_input.connect(_al_input_juego)
	_juego.draw.connect(_dibujar_juego)
	_hud.draw.connect(_dibujar_hud)
	_configurar_confeti()
	logica.reventaron.connect(_al_reventar)
	logica.insertada.connect(_al_insertar)
	logica.combo_cambio.connect(_al_cambiar_combo)
	logica.retroceso_choco.connect(_al_chocar)
	logica.batidora_capturo.connect(_al_capturar)
	logica.batidora_rechazo.connect(_al_rechazar)
	logica.batidora_cafe.connect(_al_cafe)
	logica.batidora_se_vacio.connect(_al_vaciar_batidora)
	logica.batidora_sirvio.connect(_al_servir)
	logica.palanca_vacia.connect(_al_palanca_vacia)
	logica.arcoiris_pego.connect(_al_pegar_arcoiris)
	logica.servida_evaporada.connect(_al_evaporar)
	logica.empezo_a_tragar.connect(_al_empezar_a_tragar)
	logica.termino.connect(_al_terminar)
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.has_method("menos_movimiento"):
		_menos_movimiento = bool(progreso.menos_movimiento())
	if nivel.is_empty():
		push_error("motor_rio: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()


func _configurar_desde_nivel() -> void:
	var ruta_recorrido := str(nivel.get("recorrido", "res://datos/recorridos/arcoiris/z1_espiral.json"))
	recorrido = RecorridoRio.desde_archivo(ruta_recorrido)
	_guia = str(nivel.get("guia", "completa"))
	_guia_largo = float(nivel.get("guia_largo", 1280.0))
	_tiempo_par = float(nivel.get("tiempo_par", 70.0))
	logica.configurar(nivel, recorrido, _semilla)
	match logica.batidora_pistas:
		"siempre":
			_pistas = logica.tiene_batidora()
		"primera_vez":
			_pistas = logica.tiene_batidora() and not presentacion_vista(PRESENTACION_BATIDORA)
		_:
			_pistas = false
	_record = _leer_record()
	_cauce.queue_redraw()
	_texto_flotante(recorrido.centro + Vector2(0, 150), "¡Junta 3 iguales!", Color("#2E9E5B"), 2.6, 34)


## Fija la semilla del río antes de entrar al árbol (arnés QA: partidas deterministas).
func fijar_semilla(semilla: int) -> void:
	_semilla = semilla


func fase() -> String:
	return _fase


func reintentar() -> void:
	if _fase != "perdio":
		return
	reproducir_sfx(SFX_CAMBIO)
	_fin.hide()
	_gris = 0.0
	_particulas.clear()
	_textos.clear()
	_anillos.clear()
	_vuelos.clear()
	_record_nuevo = false
	_fase = "jugando"
	logica.reiniciar()
	_tinte = Color.WHITE


func _process(delta: float) -> void:
	_t += delta
	if recorrido == null:
		return
	logica.avanzar(delta)
	_lengua = maxf(0.0, _lengua - delta / 0.14)
	_carga = minf(1.0, _carga + delta / 0.16)
	_salto = maxf(0.0, _salto - delta * 3.0)
	_giro_coco = move_toward(_giro_coco, 0.0, delta * 9.0)
	_temblor = maxf(0.0, _temblor - delta * 1.6)
	_batidora_tiembla = maxf(0.0, _batidora_tiembla - delta)
	_palanca_hundida = maxf(0.0, _palanca_hundida - delta)
	if _fase != "perdio":
		_gris = maxf(0.0, _gris - delta * 0.5) if _fase == "jugando" else _gris
	var objetivo := Color.WHITE
	if logica.actual != "" and logica.actual != LogicaRio.ARCOIRIS:
		objetivo = Color.WHITE.lerp(_color(logica.actual), 0.3)
	_tinte = _tinte.lerp(objetivo, clampf(delta * 8.0, 0.0, 1.0))
	if absf(cos(_angulo)) > 0.25:
		_mirando = signf(cos(_angulo))
	for p in _particulas:
		p["vel"].y += (-60.0 if p.get("sube", false) else 900.0) * delta
		p["pos"] += p["vel"] * delta
		p["vida"] -= delta
	_particulas = _particulas.filter(func(p): return p["vida"] > 0.0)
	for x in _textos:
		x["t"] += delta
	_textos = _textos.filter(func(x): return x["t"] < x["dur"])
	for a in _anillos:
		a["t"] += delta
	_anillos = _anillos.filter(func(a): return a["t"] < a["dur"])
	for v in _vuelos:
		v["t"] += delta
	_vuelos = _vuelos.filter(func(v):
		if v["t"] >= v["dur"]:
			_carga = 0.3
			return false
		return true)
	# Temblor suave de pantalla (§6), desactivable con "menos movimiento". El HUD no tiembla.
	if _temblor > 0.0 and not _menos_movimiento:
		_juego.position = Vector2(randf() - 0.5, randf() - 0.5) * 14.0 * _temblor
	else:
		_juego.position = Vector2.ZERO
	_juego.queue_redraw()
	_hud.queue_redraw()
	if _fin.visible:
		_fin.queue_redraw()


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _al_input_juego(evento: InputEvent) -> void:
	if recorrido == null:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_juego.accept_event()
		if _fase != "jugando":
			return
		# La posición del evento es la del Control del juego, que puede estar corrido por el temblor.
		var p: Vector2 = evento.position + _juego.position
		if evento.pressed:
			if logica.tiene_batidora() and p.distance_to(recorrido.posicion_palanca()) < RADIO_TOQUE_PALANCA:
				servir()
				return
			if p.distance_to(_centro_coco()) < RADIO_TOQUE_COCO:
				intercambiar()
				return
			_apuntando = true
			_apuntar(p)
		elif _apuntando:
			_apuntando = false
			_apuntar(p)
			disparar()
	elif evento is InputEventMouseMotion and _apuntando:
		_apuntar(evento.position + _juego.position)
		_juego.accept_event()


func _apuntar(p: Vector2) -> void:
	if p.distance_to(recorrido.centro) > 30.0:
		_angulo = (p - recorrido.centro).angle()


func apuntar_a(p: Vector2) -> void:
	_apuntar(p)


func disparar() -> bool:
	if logica.disparar(recorrido.centro + Vector2.from_angle(_angulo) * ORBITA, _angulo):
		_lengua = 1.0
		_carga = 0.0
		reproducir_sfx(SFX_LENGUA)
		return true
	return false


func intercambiar() -> void:
	if _fase != "jugando":
		return
	logica.intercambiar()
	_giro_coco = 1.0
	_carga = 0.4
	reproducir_sfx(SFX_CAMBIO)


## Tocar la palanca: el botón se hunde siempre (respuesta inmediata) y sirve si hay algo listo.
func servir() -> bool:
	if _fase != "jugando" or not logica.tiene_batidora():
		return false
	_palanca_hundida = 0.15
	return logica.servir()


func _al_input_fin(evento: InputEvent) -> void:
	# Tocar en cualquier parte del cartel también reintenta (Maxi no busca el botón).
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_fin.accept_event()
		reintentar()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	# PC (atajos de prueba): espacio dispara, Tab cambia la gota, S sirve.
	if evento.keycode == KEY_SPACE:
		disparar()
	elif evento.keycode == KEY_TAB:
		intercambiar()
	elif evento.keycode == KEY_S:
		servir()


# ---------------------------------------------------------------------------
# Eventos del río
# ---------------------------------------------------------------------------

func _al_insertar(_posicion: Vector2, _color_id: String) -> void:
	reproducir_sfx(SFX_INSERTA)


func _al_reventar(cantidad: int, centro: Vector2, color_id: String, cadena: int, ganados: int, es_cadena: bool) -> void:
	for k in cantidad * 5:
		var a := randf() * TAU
		var v := randf_range(120.0, 440.0)
		_particulas.append({"pos": centro + Vector2.from_angle(a) * randf() * 20.0, "vel": Vector2.from_angle(a) * v + Vector2(0, -120),
			"r": logica.radio * randf_range(0.14, 0.36), "color": color_id, "vida": randf_range(0.6, 1.1)})
	_anillos.append({"pos": centro, "t": 0.0, "dur": 0.35, "color": _color(color_id), "r0": logica.radio, "r1": logica.radio * 2.6})
	_texto_flotante(centro, "+%d" % ganados, TINTA, 1.0, 30)
	if es_cadena:
		_texto_flotante(recorrido.centro + Vector2(0, -150), "¡Cadena ×%d!" % cadena, Color("#FF6A2A"), 1.4, 50)
		_temblor = maxf(_temblor, 0.3)
		_giro_coco = 1.0
	_salto = 1.0 if es_cadena else 0.6
	# El reventón sube un semitono por combo y otro por eslabón de la cadena (tope 12, como en Zuma).
	var semitonos := minf(cadena - 1 + logica.combo, 12)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(resolver_ruta_audio(SFX_REVIENTA), pow(2.0, semitonos / 12.0))


func _al_cambiar_combo(combo: int) -> void:
	if combo > 1:
		_texto_flotante(recorrido.centro + Vector2(150, -96), "Combo %d" % combo, Color("#2E9E5B"), 0.9, 30)


## "¡Clac!": anillo blanco en el punto de contacto y temblor suave, aunque no revienten (§6).
func _al_chocar(posicion: Vector2, _revienta: bool) -> void:
	_anillos.append({"pos": posicion, "t": 0.0, "dur": 0.3, "color": Color.WHITE, "r0": 8.0, "r1": 70.0})
	_temblor = maxf(_temblor, 0.14)
	reproducir_sfx(SFX_CLAC, 1.5)


func _al_capturar(color_id: String, _contenido: Array, _resultado: String) -> void:
	reproducir_sfx(SFX_GLUG, 0.6)
	_batidora_tiembla = 0.35
	var b := recorrido.posicion_batidora()
	for k in 10:
		var a := -PI / 2.0 + randf_range(-1.0, 1.0)
		_particulas.append({"pos": b + Vector2(0, -40), "vel": Vector2(cos(a) * 160.0, sin(a) * 220.0), "r": randf_range(4.0, 7.0), "color": color_id, "vida": 0.6})


## "¡Esto no va aquí!": la batidora dice que no y la gota vuelve en arco a la boca (§10.4). Nunca un error.
func _al_rechazar(color_id: String, _motivo: String) -> void:
	_batidora_tiembla = 0.5
	reproducir_sfx(SFX_BOING, 0.75)
	_vuelos.append({"desde": recorrido.posicion_batidora() + Vector2(0, -30), "t": 0.0, "dur": LogicaRio.SEGUNDOS_REBOTE, "color": color_id})


func _al_cafe() -> void:
	_batidora_tiembla = LogicaRio.SEGUNDOS_CAFE
	reproducir_sfx(SFX_PUAJ, 0.6)


func _al_vaciar_batidora() -> void:
	var b := recorrido.posicion_batidora()
	for k in 14:
		_particulas.append({"pos": b + Vector2(randf_range(-20.0, 20.0), -50.0), "vel": Vector2(randf_range(-60.0, 60.0), randf_range(-240.0, -120.0)),
			"r": randf_range(6.0, 12.0), "color": "cafe", "vida": 0.8, "sube": true})


func _al_servir(color_id: String, _cantidad: int) -> void:
	reproducir_sfx(SFX_SERVIR, 1.3)
	var b := recorrido.posicion_batidora() + Vector2(0, -20)
	_vuelos.append({"desde": b, "t": 0.0, "dur": LogicaRio.SEGUNDOS_SERVIR, "color": color_id})
	_anillos.append({"pos": recorrido.centro, "t": -LogicaRio.SEGUNDOS_SERVIR, "dur": 0.5, "color": _color(color_id), "r0": 30.0, "r1": 110.0})
	_salto = 0.7
	if logica.batidora_pistas == "primera_vez":
		marcar_presentacion_vista(PRESENTACION_BATIDORA)


func _al_palanca_vacia() -> void:
	_batidora_tiembla = 0.4
	reproducir_sfx(SFX_BOING, 0.6, -6.0)


func _al_pegar_arcoiris(posicion: Vector2, _color_id: String) -> void:
	for q in 6:
		_anillos.append({"pos": posicion, "t": -q * 0.04, "dur": 0.5, "color": Color(GAJOS_ARCOIRIS[q]), "r0": 10.0, "r1": 90.0})
	reproducir_sfx(SFX_ARCOIRIS, 1.5)


## La servida que ya no tiene dónde ir se evapora con un "puf" de chispitas (§8.2).
func _al_evaporar(color_id: String) -> void:
	reproducir_sfx(SFX_PUF)
	var c := recorrido.centro + Vector2.from_angle(_angulo) * ORBITA
	for k in 12:
		var a := randf() * TAU
		_particulas.append({"pos": c, "vel": Vector2.from_angle(a) * randf_range(60.0, 180.0), "r": randf_range(3.0, 6.0), "color": color_id, "vida": 0.5, "sube": true})


func _al_empezar_a_tragar() -> void:
	_fase = "tragando"
	_apuntando = false
	_texto_flotante(recorrido.fin + Vector2(0, -76), "¡Glu glu!", Color("#655D82"), 1.3, 42)
	reproducir_sfx(SFX_GLU)


func _al_terminar(gano: bool) -> void:
	_record_nuevo = _guardar_record(logica.puntos)
	partida_terminada.emit(gano, logica.puntos)
	if gano:
		_estrellas = LogicaRio.estrellas_por_tiempo(logica.tiempo, _tiempo_par)
		# Salir durante el resumen no pierde la victoria (GDD §6 regla 8, QA HE-60 m8).
		asegurar_victoria(10 + _estrellas * 5, _estrellas)
		_fase = "resumen"
		reproducir_sfx(SFX_GANA)
		_confeti.position = recorrido.centro
		_confeti.restart()
		_confeti.emitting = true
		_texto_flotante(recorrido.centro + Vector2(0, -170), "¡Río limpio!", Color("#2E9E5B"), SEGUNDOS_RESUMEN_VICTORIA, 58)
		get_tree().create_timer(SEGUNDOS_RESUMEN_VICTORIA).timeout.connect(_celebrar_victoria)
	else:
		_fase = "perdio"
		_gris = 1.0
		_fin.show()


func _celebrar_victoria() -> void:
	if _fase != "resumen":
		return
	_fase = "celebrando"
	celebrar(10 + _estrellas * 5, _estrellas, _linea_voz("victoria"))


func _linea_voz(clave: String) -> String:
	var lineas = nivel.get("lineas_voz", {}).get(clave, "")
	if lineas is Array:
		return str(lineas.pick_random()) if not lineas.is_empty() else ""
	return str(lineas)


func _leer_record() -> int:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "" or id_perfil == "":
		return _record
	return progreso.obtener_record_nivel(id_perfil, planeta_id, _id_nivel_actual())


func _guardar_record(puntaje: int) -> bool:
	if puntaje <= _record:
		return false
	_record = puntaje
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and id_perfil != "":
		progreso.registrar_puntaje_nivel(id_perfil, planeta_id, _id_nivel_actual(), puntaje)
	return true


func _texto_flotante(posicion: Vector2, texto: String, color: Color, duracion: float, tamano: int) -> void:
	_textos.append({"pos": posicion, "texto": texto, "color": color, "t": 0.0, "dur": duracion, "tam": tamano})


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _color(id_color: String) -> Color:
	return PALETA.get(id_color, Color("#B9B4C9"))


func _centro_coco() -> Vector2:
	return recorrido.centro + Vector2(0, -6)


## Cauce de galleta con glaseado de menta (roadmap §4.1), dibujado una sola vez.
func _dibujar_cauce() -> void:
	if recorrido == null:
		return
	var puntos := PackedVector2Array()
	for i in range(0, recorrido.puntos.size(), 3):
		puntos.append(recorrido.puntos[i])
	puntos.append(recorrido.fin)
	var ancho := logica.radio * 2.0
	_cauce.draw_polyline(puntos, Color("#B98A5E", 0.55), ancho + 26.0, true)
	_cauce.draw_polyline(puntos, Color("#E9C58F"), ancho + 18.0, true)
	_cauce.draw_polyline(puntos, Color("#BDEFD9"), ancho + 8.0, true)
	_cauce.draw_polyline(puntos, Color("#FFF6E8"), ancho + 2.0, true)
	# Chispitas de colores en el glaseado (como el camino de chispitas del mapa).
	var colores := GAJOS_ARCOIRIS.map(func(h): return Color(h)) + [Color("#FF7EB6")]
	for i in range(0, puntos.size(), 9):
		var p := puntos[i]
		var lado := 1.0 if (i / 9) % 2 == 0 else -1.0
		var dir := (puntos[mini(i + 1, puntos.size() - 1)] - p).normalized().orthogonal()
		_cauce.draw_circle(p + dir * lado * (ancho * 0.5 + 6.0), 2.6, Color(colores[(i / 9) % colores.size()], 0.85))


func _dibujar_juego() -> void:
	if recorrido == null:
		return
	_dibujar_nube()
	_dibujar_remolino()
	# De la cola a la cabeza: la cabeza queda encima. Las del túnel no se ven (§10.1).
	var atraidas := logica.ids_atraidas()
	var latido := 0.5 + 0.5 * sin(_t * TAU * 3.0)
	for i in range(logica.gotas.size() - 1, -1, -1):
		var g: Dictionary = logica.gotas[i]
		var s: float = g["s"]
		if s < -2.0 or logica.en_tunel(s):
			continue
		var p := recorrido.posicion(s)
		if g["ot"] > 0.0:
			p = g["origen"].lerp(p, 1.0 - g["ot"] / 0.12)
		var cerca := recorrido.largo - s
		var escala := maxf(0.2, cerca / logica.diametro()) if cerca < logica.diametro() else 1.0
		# Atracción (§6): las puntas iguales de un corte brillan y laten antes de chocar.
		if atraidas.has(g["id"]):
			_juego.draw_circle(p, logica.radio * (1.25 + 0.15 * latido), Color(1, 1, 1, 0.55 + 0.3 * latido))
		_dibujar_gota(_juego, p, logica.radio * escala, g["color"], g["id"])
	if logica.tiene_batidora():
		_dibujar_puente()
	_dibujar_guia()
	_dibujar_pistas()
	for bala in logica.balas:
		_dibujar_gota(_juego, bala["pos"], logica.radio, bala["color"], 7)
	var boca := recorrido.centro + Vector2.from_angle(_angulo) * ORBITA
	for v in _vuelos:
		var k := clampf(v["t"] / v["dur"], 0.0, 1.0)
		var q: Vector2 = v["desde"].lerp(boca, k) - Vector2(0, sin(k * PI) * 60.0)
		_dibujar_gota(_juego, q, logica.radio * 0.9, v["color"], 3, false)
	for a in _anillos:
		if a["t"] < 0.0:
			continue
		var k: float = a["t"] / a["dur"]
		_juego.draw_arc(a["pos"], lerpf(a["r0"], a["r1"], k), 0.0, TAU, 40, Color(a["color"], 1.0 - k), 6.0 * (1.0 - k) + 1.0, true)
	for p in _particulas:
		_juego.draw_circle(p["pos"], p["r"], Color(_color(p["color"]), minf(1.0, p["vida"] * 2.0)))
	_dibujar_coco()
	for x in _textos:
		var k: float = x["t"] / x["dur"]
		var escala := 0.7 + k * 2.0 if k < 0.15 else 1.0
		var alfa := (1.0 - k) / 0.25 if k > 0.75 else 1.0
		_texto(_juego, x["texto"], x["pos"] - Vector2(0, k * 40.0), int(x["tam"] * escala), Color(x["color"], alfa))


## Gota de pintura con carita (las del río parpadean cada tanto). Los 2 + 1 llevan su receta en
## puntitos (§5.3); la arcoíris, gajos que giran (§9).
func _dibujar_gota(lienzo: Control, c: Vector2, r: float, id_color: String, id: int, cara := true) -> void:
	if id_color == LogicaRio.ARCOIRIS:
		_dibujar_arcoiris(lienzo, c, r)
		return
	var base := _color(id_color)
	lienzo.draw_circle(c + Vector2(0, r * 0.12), r * 0.95, Color(COLOR_CONTORNO, 0.18))
	lienzo.draw_circle(c, r * 0.95, base.darkened(0.38))
	lienzo.draw_circle(c, r * 0.95 - maxf(2.0, r * 0.08), base)
	lienzo.draw_circle(c + Vector2(r * 0.12, r * 0.16), r * 0.62, base.darkened(0.08))
	lienzo.draw_circle(c - Vector2(r * 0.1, r * 0.12), r * 0.55, base.lightened(0.1))
	_elipse(lienzo, c + Vector2(-r * 0.38, -r * 0.42), Vector2(r * 0.22, r * 0.12), -0.6, Color(1, 1, 1, 0.8))
	if LogicaRio.TERCIARIOS.has(id_color):
		var rc: Array = LogicaRio.TERCIARIOS[id_color]
		for i in rc.size():
			var q := c + Vector2((i - 1) * r * 0.34, -r * 0.5)
			lienzo.draw_circle(q, r * 0.17, Color.WHITE)
			lienzo.draw_circle(q, r * 0.12, _color(rc[i]))
	if not cara or r < 8.0:
		return
	var parpadeo := fmod(_t * 1000.0 + id * 733.0, 4100.0) < 130.0
	for lado in [-1.0, 1.0]:
		var ojo := c + Vector2(lado * r * 0.27, r * 0.02)
		if parpadeo:
			lienzo.draw_line(ojo - Vector2(r * 0.1, 0), ojo + Vector2(r * 0.1, 0), TINTA, maxf(1.5, r * 0.07), true)
		else:
			lienzo.draw_circle(ojo, r * 0.11, TINTA)
			lienzo.draw_circle(ojo + Vector2(r * 0.04, -r * 0.04), r * 0.04, Color.WHITE)
	lienzo.draw_arc(c + Vector2(0, r * 0.22), r * 0.14, 0.15 * PI, 0.85 * PI, 10, TINTA, maxf(1.5, r * 0.07), true)


## La gota arcoíris: 6 gajos de color que giran y un aro blanco que late.
func _dibujar_arcoiris(lienzo: Control, c: Vector2, r: float) -> void:
	lienzo.draw_circle(c + Vector2(0, r * 0.12), r * 0.95, Color(COLOR_CONTORNO, 0.18))
	lienzo.draw_circle(c, r * 0.95, Color("#3A2F5E"))
	for k in 6:
		var a0 := _t * 2.4 + k * TAU / 6.0
		var gajo := PackedVector2Array([c])
		for q in 9:
			gajo.append(c + Vector2.from_angle(a0 + TAU / 6.0 * q / 8.0) * r * 0.86)
		lienzo.draw_colored_polygon(gajo, Color(GAJOS_ARCOIRIS[k]))
	lienzo.draw_circle(c, r * 0.34, Color.WHITE)
	_elipse(lienzo, c + Vector2(-r * 0.38, -r * 0.42), Vector2(r * 0.22, r * 0.12), -0.6, Color(1, 1, 1, 0.85))
	var b := 0.5 + 0.5 * sin(_t * 8.0)
	lienzo.draw_arc(c, r * 1.08 + b * 3.0, 0.0, TAU, 32, Color(1, 1, 1, 0.4 + 0.4 * b), 3.0, true)


func _elipse(lienzo: Control, c: Vector2, radios: Vector2, angulo: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		puntos.append(c + Vector2(cos(a) * radios.x, sin(a) * radios.y).rotated(angulo))
	lienzo.draw_colored_polygon(puntos, color)


## La nube gris que destiñe el planeta asoma donde nace el río (roadmap §4.2). Se infla si llueve mucho.
func _dibujar_nube() -> void:
	var base := recorrido.posicion(0.0)
	var c := Vector2(base.x, minf(base.y, 720.0) - 30.0)
	var llenas := 0
	for g in logica.gotas:
		if g["s"] < 0.0:
			llenas += 1
	var inflado := 1.0 + minf(0.18, llenas * 0.005) + sin(_t * 2.0) * 0.02
	var gris := Color("#A9A5B8")
	for b in [Vector2(-46, 6), Vector2(46, 6), Vector2(-20, -18), Vector2(22, -22), Vector2(0, 10)]:
		_juego.draw_circle(c + b * inflado, 34.0 * inflado, gris.darkened(0.25))
	for b in [Vector2(-46, 6), Vector2(46, 6), Vector2(-20, -18), Vector2(22, -22), Vector2(0, 10)]:
		_juego.draw_circle(c + b * inflado, 30.0 * inflado, gris)
	# Cara de berrinche (chistosa, nunca de miedo).
	for lado in [-1.0, 1.0]:
		_juego.draw_circle(c + Vector2(lado * 16, -6), 4.5, TINTA)
		_juego.draw_line(c + Vector2(lado * 8, -18), c + Vector2(lado * 24, -14), TINTA, 3.0, true)
	_juego.draw_arc(c + Vector2(0, 14), 9.0, 1.15 * PI, 1.85 * PI, 10, TINTA, 3.0, true)
	_juego.draw_circle(c + Vector2(-30, 6), 6.0, Color("#E7B6C8", 0.7))
	_juego.draw_circle(c + Vector2(30, 6), 6.0, Color("#E7B6C8", 0.7))


## El remolino gris que se traga el río. Avisa peligro con un pulso rojo y al ganar florece.
func _dibujar_remolino() -> void:
	var c := recorrido.fin
	if _fase in ["resumen", "celebrando"]:
		for k in 6:
			var a := TAU * k / 6.0 + _t * 0.6
			_juego.draw_circle(c + Vector2.from_angle(a) * 30.0, 24.0, Color(GAJOS_ARCOIRIS[k]))
		_juego.draw_circle(c, 22.0, DORADO)
		Figura.dibujar_cara(_juego, c, 0.5, true)
		return
	var peligro := logica.progreso_cabeza() > PELIGRO and _fase == "jugando"
	if peligro:
		_juego.draw_circle(c, 74.0, Color(0.91, 0.26, 0.29, 0.3 + 0.2 * sin(_t * 8.0)))
	for k in 5:
		_juego.draw_circle(c, 48.0 - k * 8.0, Color("#A7A4B4").lerp(Color("#3C3A48"), k / 4.0))
	var giro := _t * (2.4 + logica.progreso_cabeza() * 3.0)
	for brazo in 3:
		var linea := PackedVector2Array()
		var a := 0.0
		while a < 4.2:
			var r := 42.0 - a * 8.5
			linea.append(c + Vector2.from_angle(a + giro + brazo * 2.09) * r)
			a += 0.1
		_juego.draw_polyline(linea, Color(1, 1, 1, 0.55), 3.0, true)


## Puente de galleta con bocas de túnel, batidora y palanca (§10). Arte PROVISIONAL hasta HE-93.
func _dibujar_puente() -> void:
	var jarra := recorrido.posicion_batidora()
	var tg := recorrido.tangente(recorrido.s_puente)
	var d := logica.diametro()
	var largo := recorrido.tunel_px + 8.0
	var alto := d / 2.0 + 30.0
	_juego.draw_set_transform(jarra, tg.angle(), Vector2.ONE)
	for lado in [-1.0, 1.0]:
		_elipse(_juego, Vector2(lado * largo, 0), Vector2(14, d / 2.0 + 8.0), 0.0, Color("#6B4A33"))
		_elipse(_juego, Vector2(lado * largo, 0), Vector2(9, d / 2.0 + 2.0), 0.0, Color("#3E2A1D"))
	var galleta := StyleBoxFlat.new()
	galleta.bg_color = Color("#E2B57A")
	galleta.border_color = Color("#B98A5E")
	galleta.set_border_width_all(4)
	galleta.set_corner_radius_all(18)
	galleta.anti_aliasing = true
	_juego.draw_style_box(galleta, Rect2(-largo, -alto, largo * 2.0, alto * 2.0))
	# Glaseado punteado y chispas de chocolate.
	var x := -largo + 14.0
	while x < largo - 10.0:
		_juego.draw_circle(Vector2(x, -alto + 10.0), 2.2, Color(1, 0.96, 0.91, 0.75))
		_juego.draw_circle(Vector2(x, alto - 10.0), 2.2, Color(1, 0.96, 0.91, 0.75))
		x += 13.0
	for q in [Vector2(-48, -34), Vector2(40, -38), Vector2(-30, 36), Vector2(52, 30), Vector2(0, -44)]:
		_juego.draw_circle(q, 5.0, Color("#7A5236"))
	_juego.draw_set_transform_matrix(Transform2D.IDENTITY)
	# Batidora: tiembla al capturar, al rechazar y al eructar.
	var tiembla := sin(_t * 60.0) * 5.0 * minf(1.0, _batidora_tiembla) if _batidora_tiembla > 0.0 else 0.0
	var c := jarra + Vector2(tiembla, 0)
	if not logica.batidora_usada and logica.hay_mezcla_a_la_vista():
		var b := 0.5 + 0.5 * sin(_t * 5.0)
		_juego.draw_circle(c + Vector2(0, -8), 62.0 + b * 8.0, Color(1, 0.8, 0.24, 0.25 + 0.25 * b))
	# Base (motor) con un puntito por espacio.
	var base := StyleBoxFlat.new()
	base.bg_color = Color("#FF8FB1")
	base.border_color = COLOR_CONTORNO
	base.set_border_width_all(4)
	base.set_corner_radius_all(12)
	base.anti_aliasing = true
	_juego.draw_style_box(base, Rect2(c.x - 40, c.y + 14, 80, 30))
	var espacios := logica.batidora_espacios
	for k in espacios:
		var punto := c + Vector2(-(espacios - 1) * 13.0 + k * 26.0, 29)
		_juego.draw_circle(punto, 8.0, Color("#FFF6E8"))
		if k < logica.batidora.size():
			_juego.draw_circle(punto, 6.0, _color(logica.batidora[k]))
	# Vaso con el líquido del resultado en vivo.
	var vaso := PackedVector2Array([c + Vector2(-36, -50), c + Vector2(36, -50), c + Vector2(28, 14), c + Vector2(-28, 14)])
	_juego.draw_colored_polygon(vaso, Color(1, 1, 1, 0.75))
	var resultado := logica.resultado_batidora()
	if resultado != "":
		var nivel_liquido := float(logica.batidora.size()) / espacios
		var arriba := 14.0 - 60.0 * nivel_liquido
		var ola := sin(_t * 6.0) * 3.0
		var liquido := PackedVector2Array()
		for q in 9:
			var fx := -1.0 + q / 4.0
			var y := arriba + ola * (1.0 - absf(fx)) - 4.0 * (1.0 - fx * fx)
			var ancho_y := 36.0 - 8.0 * (y + 50.0) / 64.0
			liquido.append(c + Vector2(fx * ancho_y, y))
		var abajo_ancho := 28.0
		liquido.append(c + Vector2(abajo_ancho, 14))
		liquido.append(c + Vector2(-abajo_ancho, 14))
		_juego.draw_colored_polygon(liquido, _color(resultado))
		if logica.cafe_t > 0.0:
			for k in 4:
				_juego.draw_circle(c + Vector2(-18 + k * 12, arriba + 10.0 + sin(_t * 9.0 + k) * 6.0), 4.0, Color("#6A4129"))
	var borde := vaso.duplicate()
	borde.append(vaso[0])
	_juego.draw_polyline(borde, COLOR_CONTORNO, 4.0, true)
	_juego.draw_line(c + Vector2(-22, -42), c + Vector2(-26, 2), Color(1, 1, 1, 0.9), 4.0, true)
	# Aspas: giran mientras tiembla o eructa.
	var giro := _t * 30.0 if _batidora_tiembla > 0.0 or logica.cafe_t > 0.0 else 0.0
	var eje := c + Vector2(0, 6)
	_juego.draw_line(eje + Vector2(-12, 0).rotated(giro), eje + Vector2(12, 0).rotated(giro), COLOR_CONTORNO, 3.0, true)
	_juego.draw_line(eje + Vector2(0, -5).rotated(giro), eje + Vector2(0, 5).rotated(giro), COLOR_CONTORNO, 3.0, true)
	# Palanca para servir: gris si no hay nada; dorada, con halo y la gotita del resultado si está lista.
	var lista := logica.puede_servir()
	var pl := recorrido.posicion_palanca()
	var r := RADIO_PALANCA * (0.9 if _palanca_hundida > 0.0 else 1.0)
	if lista:
		var b := 0.5 + 0.5 * sin(_t * 7.0)
		_juego.draw_circle(pl, 46.0 + b * 6.0, Color(1, 0.8, 0.24, 0.35 + 0.3 * b))
	_juego.draw_circle(pl + Vector2(0, 4), r, Color(COLOR_CONTORNO, 0.3))
	_juego.draw_circle(pl, r, COLOR_CONTORNO)
	_juego.draw_circle(pl, r - 4.0, DORADO if lista else Color("#E7E3EE"))
	if lista:
		_dibujar_gota(_juego, pl + Vector2(0, 4), 15.0, resultado, 0, false)
	var flecha := PackedVector2Array([pl + Vector2(0, -26), pl + Vector2(11, -13), pl + Vector2(-11, -13)])
	_juego.draw_colored_polygon(flecha, COLOR_CONTORNO if lista else Color("#B9B4C9"))


## Pistas sin voz (§10.8): flecha punteada de Coco a la batidora y flecha a la palanca la primera vez.
func _dibujar_pistas() -> void:
	if not _pistas or _fase != "jugando":
		return
	var b := 0.5 + 0.5 * sin(_t * 5.0)
	var jarra := recorrido.posicion_batidora()
	if not logica.batidora_usada and logica.hay_mezcla_a_la_vista():
		var desde := recorrido.centro + Vector2(0, 96)
		var hasta := jarra + Vector2(0, -64)
		var largo := desde.distance_to(hasta)
		var paso := 16.0
		var corrido := fmod(_t * 40.0, paso)
		var k := corrido
		while k < largo:
			_juego.draw_circle(desde.lerp(hasta, k / largo), 3.0, Color(1, 0.67, 0.18, 0.5 + 0.4 * b))
			k += paso
	elif logica.batidora_usada and not logica.batidora_servida and logica.puede_servir():
		var pl := recorrido.posicion_palanca()
		var punta := pl + Vector2(44, -30 - b * 8.0)
		var cuerpo := punta + Vector2(30, -30)
		_juego.draw_line(cuerpo, punta, Color("#FFAA2E"), 10.0, true)
		var dir := (punta - cuerpo).normalized()
		_juego.draw_colored_polygon(PackedVector2Array([punta + dir * 12.0, punta + dir.orthogonal() * 12.0, punta - dir.orthogonal() * 12.0]), Color("#FFAA2E"))


## Línea de puntería: puntitos del color cargado hasta la gota (o la batidora) donde pegaría.
func _dibujar_guia() -> void:
	if _guia == "no" or _fase != "jugando" or logica.actual == "":
		return
	var dir := Vector2.from_angle(_angulo)
	var p := recorrido.centro + dir * ORBITA
	var es_arcoiris := logica.actual == LogicaRio.ARCOIRIS
	var color := _color("violeta") if es_arcoiris else _color(logica.actual)
	var golpe := -1
	var a_batidora := false
	var batidora := recorrido.posicion_batidora() if logica.tiene_batidora() else Vector2.INF
	var recorrido_guia := 0.0
	var k := 0
	while recorrido_guia < _guia_largo:
		p += dir * 8.0
		recorrido_guia += 8.0
		k += 1
		if p.x < 0 or p.x > 1280 or p.y < 0 or p.y > 720:
			break
		if not es_arcoiris and p.distance_to(batidora) < LogicaRio.RADIO_BATIDORA:
			a_batidora = true
			break
		golpe = logica.gota_en(p, logica.diametro() * 0.92)
		if golpe >= 0:
			break
		if k % 3 == 2:
			_juego.draw_circle(p, logica.radio * 0.16, Color(color, 0.8 * (1.0 - recorrido_guia / (_guia_largo + 1.0) * 0.5)))
	var centro_anillo := Vector2.INF
	var radio_anillo := logica.radio + 7.0
	if golpe >= 0:
		centro_anillo = recorrido.posicion(logica.gotas[golpe]["s"])
	elif a_batidora:
		centro_anillo = batidora + Vector2(0, -16)
		radio_anillo = 52.0
	if centro_anillo != Vector2.INF:
		var segmentos := 16
		for s in segmentos:
			if s % 2 == 0:
				var a0 := TAU * s / segmentos + _t
				_juego.draw_arc(centro_anillo, radio_anillo, a0, a0 + TAU / segmentos, 4, color, 4.0, true)


## Coco provisional (H1): el sprite canon con tinte del color cargado, lengua que sostiene la gota y la
## gota de reserva en la mano. El rig animado completo es el hito H2 (roadmap §3).
func _dibujar_coco() -> void:
	var c := _centro_coco()
	var dir := Vector2.from_angle(_angulo)
	# Plato giratorio de torta: las chispitas giran con la puntería.
	var plato := c + Vector2(0, 76)
	_elipse(_juego, plato + Vector2(0, 10), Vector2(86, 30), 0.0, Color("#E7A9C4"))
	_elipse(_juego, plato, Vector2(86, 30), 0.0, Color("#FFD9E8"))
	_elipse(_juego, plato, Vector2(70, 22), 0.0, Color("#FFF1F6"))
	for k in 10:
		var a := _angulo + TAU * k / 10.0
		_juego.draw_circle(plato + Vector2(cos(a) * 78.0, sin(a) * 26.0), 3.2, Color(GAJOS_ARCOIRIS[k % 6]))
	_juego.draw_circle(plato + Vector2(cos(_angulo) * 78.0, sin(_angulo) * 26.0), 7.0, DORADO)
	# Coco: respira, salta al reventar, gira al cambiar de gota, se inclina hacia donde apunta.
	var escala := ALTO_COCO / float(TEXTURA_COCO.get_height())
	var respira := 1.0 + sin(_t * 2.6) * 0.018
	var salto := sin(_salto * PI) * 26.0
	var temblor := Vector2(sin(_t * 47.0) * 2.0, 0) if _fase == "jugando" and logica.progreso_cabeza() > PELIGRO else Vector2.ZERO
	var inclinacion := clampf(dir.x * 0.12, -0.12, 0.12) + sin(_giro_coco * PI) * 0.35 * _mirando
	var tam := Vector2(TEXTURA_COCO.get_width(), TEXTURA_COCO.get_height()) * escala
	var pos := c + Vector2(0, -salto) + temblor
	var tinte := _tinte.lerp(Color(0.62, 0.62, 0.68), _gris)
	_juego.draw_set_transform(pos, inclinacion, Vector2(_mirando * (2.0 - respira), respira))
	_juego.draw_texture_rect(TEXTURA_COCO, Rect2(-tam / 2.0, tam), false, tinte)
	_juego.draw_set_transform_matrix(Transform2D.IDENTITY)
	var boca := pos + Vector2(1.3 * _mirando, -14.5).rotated(inclinacion)
	# Gotita de sudor cuando el río está por llegar al remolino (nunca llora).
	if temblor != Vector2.ZERO:
		var sudor := pos + Vector2(-34.0 * _mirando, -52.0 + fmod(_t * 30.0, 18.0))
		Figura.dibujar(_juego, "gota", Color("#8FD8F5"), sudor, 9.0, false)
	# Chorreada de gris después del glu glu.
	if _gris > 0.05:
		for k in 5:
			var x := -36.0 + k * 18.0
			_juego.draw_line(pos + Vector2(x, -60), pos + Vector2(x, -60 + 22.0 + 14.0 * sin(k * 1.7 + _t * 3.0)), Color("#8E8A9C", _gris), 8.0, true)
	# Gota de reserva en la mano contraria a la que apunta.
	if logica.siguiente != "" and _fase in ["jugando", "tragando"]:
		_dibujar_gota(_juego, pos + Vector2(-38.0 * _mirando, 34.0), logica.radio * 0.62, logica.siguiente, 2, false)
	# Lengua: sostiene la gota cargada y se estira al disparar. Mientras una gota vuela hacia la boca
	# (rebote o servida), la boca espera vacía.
	if _fase in ["jugando", "tragando"]:
		var largo := ORBITA + sin(_lengua * PI) * 44.0
		var punta := c + dir * largo
		_juego.draw_line(boca, punta, Color("#C9567A"), 13.0, true)
		_juego.draw_line(boca, punta, Color("#FF8FB1"), 9.0, true)
		_juego.draw_circle(punta, 7.0, Color("#FF8FB1"))
		if logica.actual != "" and _lengua < 0.5 and _vuelos.is_empty():
			_dibujar_gota(_juego, c + dir * ORBITA, logica.radio * (0.4 + 0.6 * _carga), logica.actual, 1)


func _dibujar_hud() -> void:
	if recorrido == null:
		return
	# Puntos y récord, en una píldora arriba al centro.
	var caja := Rect2(470, 14, 340, 74)
	_hud.draw_style_box(_caja_hud(), caja)
	_texto(_hud, str(logica.puntos), Vector2(caja.position.x + 100, caja.position.y + 40), 42, TINTA)
	Figura.dibujar(_hud, "estrella", DORADO, Vector2(caja.position.x + 214, caja.position.y + 37), 17.0, false)
	_texto(_hud, str(maxi(_record, logica.puntos)), Vector2(caja.position.x + 278, caja.position.y + 40), 30, Color("#2E9E5B"))
	if logica.combo > 1 and _fase == "jugando":
		_texto(_hud, "Combo %d" % logica.combo, Vector2(640, 108), 26, Color("#2E9E5B"))
	# Cuánto río queda: barra que se llena a medida que se vacía el río (con el total real).
	var barra := Rect2(1040, 34, 200, 20)
	_hud.draw_style_box(_caja_hud(), barra.grow(8))
	var frac := 1.0 - float(logica.gotas.size()) / maxf(1.0, logica.total_real)
	_hud.draw_rect(Rect2(barra.position, Vector2(barra.size.x * frac, barra.size.y)), Color("#2E9E5B"))
	_dibujar_gota(_hud, barra.position + Vector2(barra.size.x + 2, barra.size.y / 2.0), 14.0, "azul", 0, false)
	if logica.tiene_batidora():
		_dibujar_recetas()


## Recetas vivas (§10.7): los secundarios del nivel siempre; los 2 + 1, solo si están en el río. Se
## encienden según lo que hay en la batidora y se atenúan si ese color ya no está en el río.
func _dibujar_recetas() -> void:
	var presentes := logica.colores_presentes()
	var filas: Array = logica.secundarios.duplicate()
	for c in presentes:
		if LogicaRio.TERCIARIOS.has(c) and not c in filas:
			filas.append(c)
	if filas.is_empty():
		return
	var alto := 46.0
	var y0 := 92.0
	var caja := _caja_hud()
	caja.set_corner_radius_all(22)
	_hud.draw_style_box(caja, Rect2(1062, y0, 202, filas.size() * alto + 16.0))
	var contenido := logica.batidora
	var resultado := logica.resultado_batidora()
	var b := 0.5 + 0.5 * sin(_t * 5.0)
	for i in filas.size():
		var c: String = filas[i]
		var y := y0 + 8.0 + alto * i + alto / 2.0
		var rc := LogicaRio.receta(c)
		var activo: bool = c in presentes
		var parcial := not contenido.is_empty()
		for ing in contenido:
			if contenido.count(ing) > rc.count(ing):
				parcial = false
		var fila := Rect2(1068, y - 21, 190, 42)
		if resultado == c or (parcial and activo):
			var resaltado := StyleBoxFlat.new()
			resaltado.bg_color = Color(1, 0.8, 0.24, 0.6 if resultado == c else 0.25)
			resaltado.set_corner_radius_all(16)
			_hud.draw_style_box(resaltado, fila)
		if _pistas and logica.batidora_pistas == "siempre" and not logica.batidora_usada and activo:
			var marco := StyleBoxFlat.new()
			marco.draw_center = false
			marco.border_color = Color(1, 0.8, 0.24, 0.5 + 0.5 * b)
			marco.set_border_width_all(3)
			marco.set_corner_radius_all(16)
			_hud.draw_style_box(marco, fila)
		var alfa := 1.0 if activo else 0.3
		var x := 1086.0
		for k in rc.size():
			_dibujar_gota_alfa(Vector2(x, y), 12.0, rc[k], alfa)
			x += 28.0
			if k < rc.size() - 1:
				_texto(_hud, "+", Vector2(x - 14.0, y), 18, Color("#655D82", alfa))
		_texto(_hud, "=", Vector2(x - 2.0, y), 22, Color("#655D82", alfa))
		_dibujar_gota_alfa(Vector2(x + 30.0, y), 17.0, c, alfa)


func _dibujar_gota_alfa(c: Vector2, r: float, id_color: String, alfa: float) -> void:
	if alfa >= 1.0:
		_dibujar_gota(_hud, c, r, id_color, 0, false)
		return
	_hud.draw_circle(c, r * 0.95, Color(_color(id_color).darkened(0.38), alfa))
	_hud.draw_circle(c, r * 0.95 - 2.0, Color(_color(id_color), alfa))


func _caja_hud() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(CREMA, 0.92)
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(40)
	caja.anti_aliasing = true
	return caja


## Cartel de "¡Glu glu glu!": cómico, con el puntaje y el botón grande de otra vez.
func _dibujar_fin() -> void:
	_fin.draw_rect(Rect2(Vector2.ZERO, _fin.size), Color(COLOR_CONTORNO, 0.35))
	var tarjeta := Rect2(390, 150, 500, 400)
	var caja := _caja_hud()
	caja.set_corner_radius_all(48)
	caja.bg_color = CREMA
	_fin.draw_style_box(caja, tarjeta)
	var rebote := sin(_t * 5.0) * 6.0
	_texto(_fin, "¡Glu glu glu!", Vector2(640, 214 + rebote), 56, Color("#655D82"))
	_texto(_fin, str(logica.puntos), Vector2(590, 296), 44, TINTA)
	Figura.dibujar(_fin, "estrella", DORADO, Vector2(668, 293), 18.0, false)
	_texto(_fin, str(_record), Vector2(722, 296), 32, Color("#2E9E5B"))
	if _record_nuevo:
		_texto(_fin, "¡Nuevo récord!", Vector2(640, 344), 30, Color("#FF8A3D"))


func _texto(lienzo: Control, texto: String, centro: Vector2, tamano: int, color: Color) -> void:
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var base := centro + Vector2(-ancho / 2.0, tamano * 0.35)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, maxi(4, int(tamano * 0.18)), Color(1, 1, 1, 0.95 * color.a))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


# ---------------------------------------------------------------------------
# Botones e iconos (mismo estilo que los demás motores)
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


## Flecha circular de "otra vez" (sin texto, GDD §6 regla 3).
func _dibujar_icono_reintentar(icono: Control) -> void:
	var c := icono.size / 2.0
	var r := icono.size.x * 0.27
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, COLOR_CONTORNO, 22.0, true)
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, CREMA, 13.0, true)
	var punta := c + Vector2.from_angle(-PI * 0.15) * r
	var flecha := PackedVector2Array([punta + Vector2(-22, -6), punta + Vector2(18, -10), punta + Vector2(4, 26)])
	icono.draw_colored_polygon(flecha, CREMA)
	Figura.contornear(icono, flecha, 5.0)
