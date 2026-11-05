class_name MotorBuscar
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "buscar" — «Escondite animal», tipo ¿Donde esta Wally? / Hidden Folks
## (docs/fichas/motor-buscar.md, tarjeta HE-118; derrota segun HE-124 y GDD §6 regla 11).
##
## Los animales de Toby se escondieron en una escena de la selva mas grande que la pantalla, llena de cosas
## que reaccionan al tocarlas. Arrastrar recorre la escena (inercia corta y rebote en los bordes); tocar
## (menos de `umbral_arrastre_px` de movimiento) encuentra o hace reaccionar. Todo responde al presionar
## (onda + "tic", < 100 ms). Las reglas viven en `LogicaBuscar`; la geometria comun (lo que se dibuja, lo
## que tapa y lo que se toca) en `GeometriaBuscar`; el arte provisional en `dibujos_buscar.gd`.
##
## Por perfil (todo llega del JSON del nivel):
## - Semilla (Maxi): sin lista (fila de amigos encontrados), cualquier animal vale, los escondidos hacen
##   ruido, ayudas a los 6 y 10 s, 2 escenas por estacion. Perder es posible pero suave: solcito de 3 x par,
##   gag de 1,5 s, reintento de un toque, regalo tras 2 y ayuda fuerte tras 3 (todos asoman, sin sol).
## - Brote (Nicole): un objetivo a la vez con voz, silueta y PALABRA; sol de 2,2 x par sobre la escena entera.
## - Estrella (Sofia): 3 tarjetas con pista escrita, senuelos, camuflaje, lupa (z3+), radar de Toby con costo,
##   sol de 1,6 x par, regalo tras 3 y guardado parcial.
## Destellos y estrellitas solo al ganar. Nunca rojo, nunca se quita progreso.
##
## MODO EQUIPO (ficha §12.2): una escena compartida; lo que encuentra uno queda para todos. Tope por turno,
## `segundos_por_turno` sin encontrar -> el activo se cambia de escondite y `terminar_turno(true)`; senuelo ->
## `notificar_fallo_suave()`; Maxi: el activo asoma y la escena se desliza hasta el; jugada automatica.
## La derrota del equipo la orquesta minijuego_base (aspirar / devolver con escondites nuevos).

signal partida_terminada(gano: bool, puntos: int)
signal secreto_encontrado(id: String)

const G := preload("res://scripts/motores/buscar/geometria_buscar.gd")
const D := preload("res://scripts/motores/buscar/dibujos_buscar.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const PistaConCosto := preload("res://scripts/ui/pista_con_costo.gd")
const TEXTURA_TOBY := "res://assets/sprites/personajes/toby_provisional.png"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"

## SFX PROVISIONALES (los de la interfaz con otro tono) hasta los sonidos "hechos con la boca" (§7.4).
const SFX_TIC := "sfx/ui/toque.ogg"
const SFX_ENCONTRADO := "sfx/ui/confirmar.ogg"
const SFX_VUELO := "sfx/ui/fiuu.ogg"
const SFX_TARJETA := "sfx/ui/seleccionar.ogg"
const SFX_ABRIR := "sfx/ui/abrir.ogg"
const SFX_SENUELO := "sfx/ui/blup.ogg"
const SFX_CLIC := "sfx/ui/cerrar.ogg"
const SFX_SOL := "sfx/ui/zona_dormida.ogg"
const SFX_REINTENTAR := "sfx/ui/seleccionar.ogg"
const SFX_ANIMAL := "sfx/ui/blup.ogg"
const SFX_OBJETO := "sfx/ui/polvo.ogg"

const CONTORNO := Color("#2B3350")
const TINTA := Color("#272140")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const PANTALLA := Vector2(1280, 720)
## Franja de la lista (sobre un tronco) y donde caben las tarjetas (Toby queda a la izquierda).
const FRANJA := Rect2(212, 604, 1056, 112)
const RECT_MAPITA := Rect2(1060, 124, 200, 60)
const RECT_TOQUE_MAPITA := Rect2(1060, 106, 200, 96)
const RECT_CASA_EQUIPO := Rect2(1172, 8, 100, 96)
const DUR_INTRO := 2.4
const DUR_SALTO := 0.3
const DUR_VUELO := 0.6
const DUR_FOTO := 2.2

@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _boton_salir: Button = %boton_salir
@onready var _boton_toby: Button = %boton_toby
@onready var _boton_lupa: Button = %boton_lupa
@onready var _barra: Control = %barra_record
@onready var _fin: Control = %fin
@onready var _boton_reintentar: Button = %boton_reintentar
@onready var _boton_descansar: Button = %boton_descansar
@onready var _confeti: CPUParticles2D = %confeti

var logica := LogicaBuscar.new()
var _semilla := -1
var _fuente: Font
var _toby: Texture2D
var _fase := "intro"  ## intro | jugando | ronda | foto | celebrando | perdio
var _t := 0.0
var _menos_movimiento := false

# Camara
var _vista := Vector2.ZERO
var _zoom := 1.0
var _vel := Vector2.ZERO
var _tween_cam: Tween

# Entrada
var _presionado := false
var _arrastrando := false
var _p0 := Vector2.ZERO
var _p_ultimo := Vector2.ZERO
var _umbral := 16.0
var _lupa_armada := false

# Efectos
var _ondas: Array = []  ## {"pos" (pantalla), "t"}
var _particulas: Array = []  ## mundo: {"pos", "vel", "r", "color", "vida", "dur", "g", "estrella"}
var _textos: Array = []  ## pantalla: {"pos", "texto", "color", "t", "dur", "tam"}
var _vuelos: Array = []  ## {"id", "desde" (mundo), "hasta" (pantalla), "t"}
var _en_fila: Array[String] = []  ## ya llegaron a su tarjeta/puntito (Semilla: fila de amigos)
var _anim_obj: Dictionary = {}  ## id -> {"sacudir", "rebote", "ultimo"}
var _saltitos: Dictionary = {}  ## id animal -> t (saludo del senuelo / secreto)
var _globos: Array = []  ## {"id", "texto", "t"}
var _asomes: Dictionary = {}  ## id -> {"t", "dur"}
var _senal: Dictionary = {}  ## Toby senala: {"id", "t"}
var _circulo_pista: Dictionary = {}  ## {"centro" (mundo), "t"}
var _borde_pista: Dictionary = {}  ## {"lado": Vector2, "t"}
var _toby_salto := 0.0
var _toby_olfatea := 0.0
var _tarjeta_rebote := 0.0
var _intro_t := 0.0
var _foto_t := 0.0
var _gag_t := 0.0
var _flash := 0.0
var _carreras: Array = []  ## equipo: el activo corre a otro escondite {"id", "desde", "t"}

# Ayudas y ruido
var _t_quieto := 0.0
var _ayuda_paso := 0
var _t_ruido := 6.0
var _ayuda_idle: Array = []
var _ruido_s: Array = []

# Puntaje
var _record := 0
var _estrellitas := 0
var _destellos := 0
var _pista_costo: Control

# Voz
var _cola_voz: Array[String] = []

# Equipo
var _eq: Dictionary = {}
var _eq_t_turno := 0.0
var _eq_tope := false
var _eq_victoria := false
var _eq_restaurado := false
var _eq_gag: Dictionary = {}  ## {"fase": aspirar|oculto|devolver, "t", "dur", "destino", "desde": {id: Vector2}}


func _ready() -> void:
	super._ready()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	if ResourceLoader.exists(TEXTURA_TOBY):
		_toby = load(TEXTURA_TOBY)
	_estilizar_boton(_boton_salir, CREMA)
	_estilizar_boton(_boton_reintentar, DORADO)
	_estilizar_boton(_boton_descansar, CREMA)
	_estilizar_boton(_boton_lupa, CREMA)
	_icono(_boton_salir, _dibujar_flecha)
	_icono(_boton_reintentar, _dibujar_icono_reintentar)
	_icono(_boton_descansar, _dibujar_casita)
	_icono(_boton_lupa, _dibujar_lupa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_boton_descansar.pressed.connect(func() -> void: salir_solicitado.emit())
	_boton_reintentar.pressed.connect(reintentar)
	_boton_lupa.pressed.connect(usar_lupa)
	_boton_toby.pressed.connect(tocar_toby)
	_boton_toby.mouse_filter = Control.MOUSE_FILTER_STOP
	_fin.gui_input.connect(_al_input_fin)
	_fin.draw.connect(_dibujar_fin)
	_fin.hide()
	_juego.gui_input.connect(_al_input_juego)
	_juego.draw.connect(_dibujar_juego)
	_hud.draw.connect(_dibujar_hud)
	_configurar_confeti()
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.has_method("menos_movimiento"):
		_menos_movimiento = bool(progreso.menos_movimiento())
	if nivel.is_empty():
		push_error("motor_buscar: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	logica.encontrado.connect(_al_encontrar)
	logica.senuelo_tocado.connect(_al_senuelo)
	logica.secreto_tocado.connect(_al_secreto)
	logica.objeto_tocado.connect(_al_objeto)
	logica.escondite_abierto.connect(_al_abrir)
	logica.objetivo_activo.connect(_al_objetivo_activo)
	logica.ya_encontrado.connect(_al_ya_encontrado)
	logica.escena_completa.connect(_al_completar)
	logica.ronda_escena_terminada.connect(_al_terminar_ronda)
	logica.sol_puesto.connect(_al_ponerse_sol)
	_configurar_desde_nivel()
	if turnos != null:
		_preparar_equipo()


func _configurar_desde_nivel() -> void:
	logica.configurar(nivel, _semilla)
	_umbral = float(nivel.get("umbral_arrastre_px", 16))
	_ayuda_idle = nivel.get("ayuda_idle_s", []) if nivel.get("ayuda_idle_s", []) is Array else []
	_ruido_s = nivel.get("ruido_semilla_s", []) if nivel.get("ruido_semilla_s", []) is Array else []
	if _ruido_s.size() >= 2:
		_t_ruido = logica.rng.randf_range(float(_ruido_s[0]), float(_ruido_s[1]))
	var escena: Dictionary = nivel.get("escena", {})
	_vista = G.vec(escena.get("inicio_vista", [0, 0]))
	_vista = _vista_limitada(_vista, _zoom)
	_record = obtener_record()
	var perfil := logica.perfil
	# Brote: el bono de tiempo y la barra de record, solo con record previo (HE-124).
	if perfil == "brote":
		logica.bonus_tiempo_activo = _record > 0
	var con_barra := turnos == null and (perfil == "estrella" or (perfil == "brote" and _record > 0))
	_barra.visible = con_barra
	if con_barra:
		var umbral_tres := float(logica.umbrales.get("tres", 2000))
		_barra.call("preparar", _record, umbral_tres)
	_boton_lupa.visible = bool(nivel.get("lupa", false)) and turnos == null
	_boton_toby.tooltip_text = "Radar de Toby" if perfil == "estrella" else "Toby"
	if perfil == "estrella" and bool(nivel.get("pistas_cuestan_estrellita", true)) and turnos == null:
		_pista_costo = PistaConCosto.crear(_boton_toby.get_parent(), _boton_toby, logica.estrellitas_en_vivo)
	# Sofia: se retoma la escena a medio jugar (ficha §12.1).
	if perfil == "estrella" and turnos == null:
		var parcial := obtener_estado_parcial()
		if not parcial.is_empty() and logica.restaurar_parcial(parcial):
			for id in logica.encontrados:
				_en_fila.append(id)
	_fase = "intro"
	_intro_t = 0.0
	_decir(_linea_voz("cuenta_toby"))
	_decir(_linea_voz("intro"))


## Fija la semilla del sorteo antes de entrar al arbol (arnes QA: partidas deterministas).
func fijar_semilla(semilla: int) -> void:
	_semilla = semilla


func fase() -> String:
	return _fase


# ---------------------------------------------------------------------------
# Bucle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	if logica.nivel.is_empty():
		return
	match _fase:
		"intro":
			_intro_t += delta
			if _intro_t >= DUR_INTRO:
				_terminar_intro()
		"jugando":
			if _puede_jugar():
				logica.avanzar(delta)
				_procesar_ayudas(delta)
			if turnos != null:
				_procesar_equipo(delta)
		"foto":
			_foto_t += delta
			_flash = maxf(0.0, _flash - delta * 2.5)
			if _foto_t >= 0.7 and _foto_t - delta < 0.7:
				_flash = 1.0
				reproducir_sfx(SFX_CLIC)
			if _foto_t >= DUR_FOTO:
				_celebrar_final()
		"perdio":
			_gag_t += delta
	_procesar_camara(delta)
	_procesar_efectos(delta)
	_procesar_voz()
	_juego.queue_redraw()
	_hud.queue_redraw()
	if _fin.visible:
		_fin.queue_redraw()


func _puede_jugar() -> bool:
	if turnos != null:
		return turnos.turno_activo() and not turnos.entrada_bloqueada() and _eq_gag.is_empty() and not _eq_victoria
	return true


func _terminar_intro() -> void:
	if _fase != "intro":
		return
	_fase = "jugando"
	_t_quieto = 0.0
	if turnos != null:
		return
	_decir(_linea_voz("instruccion"))
	if logica.modo_lista == "uno":
		_decir(_linea_voz("busca", logica.activo()))
	if logica.ayuda_fuerte():
		_decir(_linea_voz("ayuda_fuerte"))
	_presentar_una_vez()


func _presentar_una_vez() -> void:
	if _boton_lupa.visible and not presentacion_vista("lupa_buscar"):
		_decir(_linea_voz("presenta_lupa"))
		marcar_presentacion_vista("lupa_buscar")
	if logica.perfil == "estrella" and not presentacion_vista("radar_toby"):
		_decir(_linea_voz("presenta_radar"))
		marcar_presentacion_vista("radar_toby")


# ---------------------------------------------------------------------------
# Camara: arrastre, inercia, rebote, lupa y mapita
# ---------------------------------------------------------------------------

func tamano_escena() -> Vector2:
	return logica.tamano_escena


func _vista_limitada(v: Vector2, zoom: float) -> Vector2:
	var ver := PANTALLA / zoom
	var maximo := (tamano_escena() - ver).max(Vector2.ZERO)
	return v.clamp(Vector2.ZERO, maximo)


func pantalla_a_mundo(p: Vector2) -> Vector2:
	return _vista + p / _zoom


func mundo_a_pantalla(w: Vector2) -> Vector2:
	return (w - _vista) * _zoom


func _procesar_camara(delta: float) -> void:
	if _presionado and _arrastrando:
		return
	if _tween_cam != null and _tween_cam.is_valid() and _tween_cam.is_running():
		return
	if _vel.length() > 1.0 and not _menos_movimiento:
		_vista += _vel * delta
		_vel *= exp(-delta * 10.0)  # frenado en ~0,4 s
	else:
		_vel = Vector2.ZERO
	var limitada := _vista_limitada(_vista, _zoom)
	if limitada != _vista:
		# Rebote elastico en los bordes.
		_vista = _vista.lerp(limitada, 1.0 - exp(-delta * 14.0))
		_vel *= 0.5
		if _vista.distance_to(limitada) < 0.5:
			_vista = limitada


func mover_vista_a(centro_mundo: Vector2, segundos := 0.35) -> void:
	var destino := _vista_limitada(centro_mundo - PANTALLA / _zoom / 2.0, _zoom)
	_vel = Vector2.ZERO
	if _tween_cam != null and _tween_cam.is_valid():
		_tween_cam.kill()
	if segundos <= 0.0 or _menos_movimiento:
		_vista = destino
		return
	_tween_cam = create_tween()
	_tween_cam.tween_property(self, "_vista", destino, segundos).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _zoom_a(nuevo: float, punto_pantalla: Vector2) -> void:
	var w := pantalla_a_mundo(punto_pantalla)
	var destino := _vista_limitada(w - PANTALLA / nuevo / 2.0, nuevo)
	if _tween_cam != null and _tween_cam.is_valid():
		_tween_cam.kill()
	_vel = Vector2.ZERO
	_tween_cam = create_tween().set_parallel(true)
	_tween_cam.tween_property(self, "_zoom", nuevo, 0.3).set_trans(Tween.TRANS_SINE)
	_tween_cam.tween_property(self, "_vista", destino, 0.3).set_trans(Tween.TRANS_SINE)


## Lupa (misma regla que Pinta v2, lienzo-escenas-retos.md §1.7): un toque la arma, el siguiente toque en
## la escena acerca 2x ahi; tocarla con zoom vuelve a 1x. Armada, otro toque la desarma. Publica para QA.
func usar_lupa() -> void:
	reproducir_sfx(SFX_TIC)
	if _zoom > 1.01:
		_zoom_a(1.0, PANTALLA / 2.0)
		_lupa_armada = false
	elif _lupa_armada:
		_lupa_armada = false
	else:
		_lupa_armada = true
	_boton_lupa.queue_redraw()
	for hijo in _boton_lupa.get_children():
		(hijo as Control).queue_redraw()


func zoom_actual() -> float:
	return _zoom


func lupa_armada() -> bool:
	return _lupa_armada


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _al_input_juego(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_juego.accept_event()
		if evento.pressed:
			presionar(evento.position)
		else:
			soltar(evento.position)
	elif evento is InputEventMouseMotion and _presionado:
		_juego.accept_event()
		mover(evento.position)


## Presionar: onda + "tic" al instante (GDD §6, < 100 ms). Publica para QA.
func presionar(p: Vector2) -> void:
	_presionado = true
	_arrastrando = false
	_p0 = p
	_p_ultimo = p
	_vel = Vector2.ZERO
	_t_quieto = 0.0
	_ayuda_paso = 0
	_ondas.append({"pos": p, "t": 0.0})
	reproducir_sfx(SFX_TIC, 1.0, -8.0)
	if _tween_cam != null and _tween_cam.is_valid() and not _lupa_armada:
		_tween_cam.kill()


func mover(p: Vector2) -> void:
	if not _presionado:
		return
	if not _arrastrando and p.distance_to(_p0) > _umbral and _fase in ["jugando", "intro"] and not FRANJA.has_point(_p0):
		_arrastrando = true
	if _arrastrando:
		var d := (p - _p_ultimo) / _zoom
		var limitada := _vista_limitada(_vista - d, _zoom)
		var fuera := (_vista - d) - limitada
		# Fuera del borde el arrastre se pone "elastico" (rebote al soltar).
		_vista = limitada + fuera * 0.35
		var dt := maxf(get_process_delta_time(), 1.0 / 120.0)
		_vel = _vel.lerp(-d / dt, 0.5)
	_p_ultimo = p


func soltar(p: Vector2) -> void:
	if not _presionado:
		return
	_presionado = false
	if _arrastrando:
		_arrastrando = false
		if _menos_movimiento:
			_vel = Vector2.ZERO
		return
	if p.distance_to(_p0) > _umbral:
		return
	tocar_pantalla(p)


## Un toque ya resuelto (sin arrastre). Publica para QA.
func tocar_pantalla(p: Vector2) -> void:
	if _fase == "intro":
		_intro_t = DUR_INTRO
		_terminar_intro()
		return
	if _fase != "jugando":
		return
	if FRANJA.has_point(p):
		_tocar_lista(p)
		return
	if (logica.perfil != "semilla" or turnos != null) and _mapita_visible() and RECT_TOQUE_MAPITA.has_point(p):
		_tocar_mapita(p)
		return
	if _lupa_armada:
		_lupa_armada = false
		_zoom_a(2.0, p)
		return
	if not _puede_jugar():
		return
	tocar_mundo(pantalla_a_mundo(p))


## Toque en coordenadas de la escena (lo usa el arnes para tocar el centro visible de un animal).
func tocar_mundo(w: Vector2) -> Dictionary:
	if _fase != "jugando" or not _puede_jugar():
		return {"tipo": "nada", "id": ""}
	var res := logica.tocar(w)
	if res["tipo"] == "nada":
		_soltar_hojitas(w, Color("#9BD47A"), 3)
	return res


func _al_input_fin(evento: InputEvent) -> void:
	var toque: bool = evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT
	if not toque:
		return
	_fin.accept_event()
	# Toda la tarjeta del cartel es "¡otra vez!" (un toque).
	if _rect_cartel().has_point(evento.position):
		reintentar()


func _tocar_lista(p: Vector2) -> void:
	_tarjeta_rebote = 1.0
	reproducir_sfx(SFX_TARJETA)
	match logica.modo_lista:
		"uno":
			var id := logica.activo()
			_decir(_linea_voz("busca", id), true)
		"tarjetas":
			var act := logica.activos()
			for i in act.size():
				if _rect_tarjeta(i).has_point(p):
					var pista: Dictionary = logica.animales[act[i]].get("pista", {})
					_decir(str(pista.get("voz", "")), true)
		_:
			_decir(_linea_voz("instruccion"), true)


func _mapita_visible() -> bool:
	return bool(nivel.get("mapita", false)) and tamano_escena().x > PANTALLA.x + 1


func _rect_mapa() -> Rect2:
	var t := tamano_escena()
	var alto := clampf(RECT_MAPITA.size.x * t.y / t.x, 40.0, 90.0)
	return Rect2(RECT_MAPITA.position, Vector2(RECT_MAPITA.size.x, alto))


func _tocar_mapita(p: Vector2) -> void:
	var r := _rect_mapa()
	var k := ((p - r.position) / r.size).clamp(Vector2.ZERO, Vector2.ONE)
	mover_vista_a(k * tamano_escena(), 0.35)


## Toby: en Sofia es el radar (pista con costo); para los demas repite la instruccion y salta.
func tocar_toby() -> void:
	_toby_salto = 1.0
	if _fase != "jugando":
		return
	if logica.perfil == "estrella" and _pista_costo != null and turnos == null:
		_pista_costo.call("pedir", _accion_pista)
		return
	reproducir_sfx(SFX_ANIMAL, 1.3)
	if logica.modo_lista == "uno":
		_decir(_linea_voz("busca", logica.activo()), true)
	else:
		_decir(_linea_voz("instruccion"), true)


## Radar de Toby (§10.4): fuera de pantalla brilla el borde y la escena se desliza; dentro, un circulo
## calido de 300 px que lo contiene sin senalarlo exacto.
func _accion_pista(gratis: bool) -> bool:
	var id := logica.activo()
	if id == "":
		return false
	logica.usar_pista(not gratis)
	_toby_olfatea = 1.6
	_decir(_linea_voz("pista_usada"))
	var centro: Vector2 = logica.medida(id)["centro"]
	if logica.esta_dentro(id) and not logica.revelado(id):
		centro = G.caja_de(logica.cobertura_objeto(logica.pieza_de(logica.escondite(id)))).get_center()
	var sp := mundo_a_pantalla(centro)
	if Rect2(Vector2.ZERO, PANTALLA).grow(-40).has_point(sp) and sp.y < FRANJA.position.y:
		var desvio := Vector2(logica.rng.randf_range(-80, 80), logica.rng.randf_range(-60, 60))
		_circulo_pista = {"centro": centro + desvio / _zoom, "t": 0.0}
	else:
		var lado := (sp - PANTALLA / 2.0).normalized()
		_borde_pista = {"lado": lado, "t": 0.0}
		mover_vista_a(pantalla_a_mundo(PANTALLA / 2.0 + lado * Vector2(320, 160)), 0.6)
	return true


# ---------------------------------------------------------------------------
# Reacciones de la logica
# ---------------------------------------------------------------------------

func _al_encontrar(id: String, puntos: int, racha: int, ojo: bool) -> void:
	var esc := logica.escondite(id)
	var m: Dictionary = logica.medida(id)
	var centro: Vector2 = m["centro"]
	_vuelos.append({"id": id, "desde": logica.pie_animal(id), "esc": esc.duplicate(), "hasta": _destino_tarjeta(id), "t": 0.0,
		"regalo": id in logica.regalados})
	_asomes.erase(id)
	_estallido(centro, 16, ojo)
	reproducir_sfx(SFX_ENCONTRADO, pow(2.0, maxi(0, racha - 1) / 12.0))
	var animal: Dictionary = logica.animales.get(id, {})
	reproducir_sfx(str(animal.get("sonido", SFX_ANIMAL)), float(animal.get("tono", 1.0)), -2.0)
	_decir(str(animal.get("nombre_voz", "")))
	_toby_salto = 1.0
	_t_quieto = 0.0
	_ayuda_paso = 0
	_senal = {}
	if puntos > 0:
		_texto_flotante(mundo_a_pantalla(centro) + Vector2(0, -40), "+%d" % puntos, Color("#2E9E5B"), 1.1, 34)
	if ojo:
		_texto_flotante(mundo_a_pantalla(centro) + Vector2(0, -86), "¡Ojo de águila!", Color("#E08A00"), 1.4, 30)
	if _barra.visible:
		_barra.call("fijar_puntaje", logica.puntos)
	if turnos != null:
		_eq_t_turno = 0.0
		if not logica.completa():
			turnos.notificar_acierto()
		return
	if logica.perfil == "estrella" and not logica.completa():
		guardar_estado_parcial(logica.estado_parcial())


func _al_senuelo(id: String) -> void:
	var animal: Dictionary = logica.animales.get(id, {})
	_saltitos[id] = 0.0
	reproducir_sfx(str(animal.get("sonido", SFX_SENUELO)), float(animal.get("tono", 1.2)))
	_decir(_linea_voz("senuelo", id), true)
	var saludo := str(animal.get("saludo", ""))
	if saludo != "" and logica.perfil != "semilla":
		_globos.append({"id": id, "texto": saludo, "t": 0.0})
	if turnos != null:
		turnos.notificar_fallo_suave()


func _al_secreto(id: String) -> void:
	var animal: Dictionary = logica.animales.get(id, {})
	_saltitos[id] = 0.0
	reproducir_sfx(str(animal.get("sonido", SFX_ANIMAL)), float(animal.get("tono", 1.4)))
	_decir(_linea_voz("secreto", id), true)
	_estallido(logica.medida(id)["centro"], 10, true)
	secreto_encontrado.emit(id)


func _al_objeto(id: String) -> void:
	var obj: Dictionary = logica.objetos.get(id, {})
	var anim: Dictionary = _anim_obj.get(id, {"sacudir": 0.0, "rebote": 0.0, "ultimo": -10.0})
	# Enfriamiento de 0,5 s: a rafagas solo responde la onda y el tic (ficha §7.1).
	if _t - float(anim["ultimo"]) < 0.5:
		return
	anim["ultimo"] = _t
	var caja := G.caja_de(logica.cobertura_objeto(id))
	match str(obj.get("reaccion", "sacudir")):
		"sacudir":
			anim["sacudir"] = 1.0
			_soltar_hojitas(Vector2(caja.get_center().x, caja.position.y + 20), Color("#6CC46F"), 6)
		"salpicar", "chorro":
			anim["rebote"] = 1.0
			_soltar_gotas(Vector2(caja.get_center().x, caja.position.y + 10), 10 if str(obj.get("reaccion")) == "chorro" else 7,
				str(obj.get("reaccion")) == "chorro")
		"puf":
			anim["rebote"] = 1.0
			_soltar_hojitas(caja.get_center(), Color(1, 1, 1, 0.9), 8)
		"xilofono":
			anim["rebote"] = 1.0
			anim["nota"] = int(anim.get("nota", 0)) + 1
		_:
			anim["rebote"] = 1.0
	_anim_obj[id] = anim
	var tono := 1.0
	if str(obj.get("reaccion", "")) == "xilofono":
		tono = pow(2.0, ([0, 2, 4, 5, 7, 9, 11, 12][int(anim.get("nota", 0)) % 8]) / 12.0)
	reproducir_sfx(str(obj.get("sonido", SFX_OBJETO)), tono * float(obj.get("tono", 1.0)), -3.0)


func _al_abrir(id_objeto: String, id_animal: String) -> void:
	var anim: Dictionary = _anim_obj.get(id_objeto, {"sacudir": 0.0, "rebote": 0.0, "ultimo": -10.0})
	anim["rebote"] = 1.0
	anim["ultimo"] = _t
	_anim_obj[id_objeto] = anim
	reproducir_sfx(SFX_ABRIR)
	var caja := G.caja_de(logica.cobertura_objeto(id_objeto))
	_soltar_hojitas(caja.get_center(), DORADO, 8)
	if id_animal != "":
		_saltitos[id_animal] = 0.0


func _al_objetivo_activo(id: String) -> void:
	if turnos == null and logica.modo_lista == "uno" and _fase == "jugando":
		_decir(_linea_voz("busca", id))


func _al_ya_encontrado(_id: String) -> void:
	_decir(_linea_voz("ya_encontrado"))


func _al_completar() -> void:
	if turnos != null:
		_victoria_equipo()
		return
	_ganar()


func _al_terminar_ronda(_ronda: int) -> void:
	_fase = "ronda"
	get_tree().create_timer(DUR_SALTO + DUR_VUELO + 0.5).timeout.connect(_empezar_ronda_nueva)


func _empezar_ronda_nueva() -> void:
	if _fase != "ronda" or not is_inside_tree():
		return
	_decir(_linea_voz("otra_vez"))
	logica.siguiente_ronda_escena()
	_en_fila.clear()
	_vuelos.clear()
	_asomes.clear()
	_fase = "intro"
	_intro_t = 0.6


# ---------------------------------------------------------------------------
# Ganar, perder y reintentar
# ---------------------------------------------------------------------------

func _ganar() -> void:
	_fase = "foto"
	_foto_t = -(DUR_SALTO + DUR_VUELO)
	var puntaje := logica.puntaje_final()
	_estrellitas = logica.estrellitas_finales()
	_destellos = 20 if logica.perfil == "semilla" else 10 + _estrellitas * 5
	# Salir durante la foto no pierde la victoria (GDD §6 regla 8, QA HE-60 B1).
	asegurar_victoria(_destellos, _estrellitas)
	partida_terminada.emit(true, puntaje)
	if logica.perfil != "semilla":
		var nuevo := registrar_record(puntaje)
		if nuevo or puntaje > _record:
			_decir(_linea_voz("primer_record" if _record <= 0 else "record"))
			if _barra.visible:
				_barra.call("fijar_puntaje", puntaje)
				if _record <= 0:
					_barra.call("plantar_banderita")
			_texto_flotante(Vector2(640, 200), "¡Récord!", Color("#FF8A3D"), 2.0, 54)
	_confeti.restart()
	_confeti.emitting = true


func _celebrar_final() -> void:
	if _fase != "foto":
		return
	_fase = "celebrando"
	celebrar(_destellos, _estrellitas, _linea_voz("victoria"))


func _al_ponerse_sol() -> void:
	if turnos != null:
		return
	_fase = "perdio"
	_gag_t = 0.0
	_presionado = false
	_arrastrando = false
	reproducir_sfx(SFX_SOL)
	_decir(_linea_voz("derrota_gag"), true)
	partida_terminada.emit(false, logica.puntos)
	if logica.perfil == "estrella":
		guardar_estado_parcial(logica.estado_parcial())
	get_tree().create_timer(duracion_gag()).timeout.connect(_mostrar_cartel)


## Gag de la derrota: 1,5 s en Semilla, 2,5 s en los demas (ficha §10.1 y §10.2).
func duracion_gag() -> float:
	return 1.5 if logica.perfil == "semilla" else 2.5


func _mostrar_cartel() -> void:
	if _fase != "perdio" or not is_inside_tree():
		return
	_fin.show()
	_boton_descansar.visible = logica.ofrecer_descanso()
	if _boton_descansar.visible:
		_decir(_linea_voz("descansar"))
	_boton_reintentar.pivot_offset = _boton_reintentar.size / 2.0
	_boton_reintentar.scale = Vector2.ZERO
	_boton_reintentar.create_tween().tween_property(_boton_reintentar, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## "¡Otra vez!" (un toque): los encontrados quedan, los demas se cambian de escondite y el sol vuelve con
## tiempo proporcional. Tras `regalo_tras_derrotas`, Toby encuentra uno con el olfato.
func reintentar() -> void:
	if _fase != "perdio":
		return
	reproducir_sfx(SFX_REINTENTAR)
	_fin.hide()
	_particulas.clear()
	_textos.clear()
	_globos.clear()
	_asomes.clear()
	_senal = {}
	_circulo_pista = {}
	logica.reintentar()
	_fase = "intro"
	_intro_t = 0.8
	if logica.ayuda_fuerte():
		_decir(_linea_voz("ayuda_fuerte"), true)
	if logica.regalo_disponible():
		get_tree().create_timer(DUR_INTRO - _intro_t + 0.6).timeout.connect(_dar_regalo)
	if logica.perfil == "estrella":
		guardar_estado_parcial(logica.estado_parcial())


func _dar_regalo() -> void:
	if _fase != "jugando" or not logica.regalo_disponible() or not is_inside_tree():
		return
	_toby_olfatea = 1.4
	_decir(_linea_voz("regalo"), true)
	logica.regalar()


# ---------------------------------------------------------------------------
# Ayudas, ruido y efectos
# ---------------------------------------------------------------------------

func _procesar_ayudas(delta: float) -> void:
	if turnos != null or not _vuelos.is_empty():
		return
	_t_quieto += delta
	if _ayuda_idle.size() >= 2:
		var a := float(_ayuda_idle[0])
		var b := float(_ayuda_idle[1])
		if logica.ayuda_fuerte():
			a *= 0.5
			b *= 0.5
		if _ayuda_paso == 0 and _t_quieto >= a:
			_ayuda_paso = 1
			var id := _objetivo_cercano()
			if logica.perfil == "brote":
				var sp := mundo_a_pantalla(logica.medida(id)["centro"]) if id != "" else PANTALLA / 2.0
				if id != "" and not Rect2(Vector2.ZERO, PANTALLA).has_point(sp):
					mover_vista_a(logica.medida(id)["centro"], 0.8)
			elif id != "":
				asomar(id, 1.8)
		elif _ayuda_paso == 1 and _t_quieto >= b:
			_ayuda_paso = 2
			var id2 := _objetivo_cercano()
			if id2 != "":
				asomar(id2, 2.2)
				if logica.perfil == "semilla":
					_senal = {"id": id2, "t": 0.0}
					_toby_salto = 1.0
				mover_vista_a(logica.medida(id2)["centro"], 0.6)
				_decir(_linea_voz("busca", id2))
		elif _ayuda_paso == 2 and _t_quieto >= b + 5.0:
			_ayuda_paso = 0
			_t_quieto = maxf(0.0, a - 3.0)
	if logica.perfil == "semilla" and _ruido_s.size() >= 2:
		_t_ruido -= delta
		if _t_ruido <= 0.0:
			_t_ruido = logica.rng.randf_range(float(_ruido_s[0]), float(_ruido_s[1]))
			var resto := logica.faltan()
			if not resto.is_empty():
				var id3: String = resto[logica.rng.randi_range(0, resto.size() - 1)]
				asomar(id3, 0.8)
				var animal: Dictionary = logica.animales.get(id3, {})
				reproducir_sfx(str(animal.get("sonido", SFX_ANIMAL)), float(animal.get("tono", 1.0)), -4.0)


func _objetivo_cercano() -> String:
	var mejor := ""
	var mejor_d := INF
	var centro := pantalla_a_mundo(PANTALLA / 2.0)
	for id in logica.activos():
		var d := centro.distance_to(logica.pie_animal(id))
		if d < mejor_d:
			mejor = id
			mejor_d = d
	return mejor


## El animal asoma la cabeza un rato (ayuda o ruido): en ese tiempo tambien es mas facil de tocar.
func asomar(id: String, dur: float) -> void:
	if logica.esta_dentro(id) and not logica.revelado(id):
		var pieza := logica.pieza_de(logica.escondite(id))
		var anim: Dictionary = _anim_obj.get(pieza, {"sacudir": 0.0, "rebote": 0.0, "ultimo": -10.0})
		anim["sacudir"] = 1.0
		_anim_obj[pieza] = anim
		return
	_asomes[id] = {"t": 0.0, "dur": dur}


func _procesar_efectos(delta: float) -> void:
	for o in _ondas:
		o["t"] += delta
	_ondas = _ondas.filter(func(o) -> bool: return o["t"] < 0.25)
	for p in _particulas:
		p["vida"] += delta
		p["vel"] += Vector2(0, p["g"]) * delta
		p["pos"] += p["vel"] * delta
	_particulas = _particulas.filter(func(p) -> bool: return p["vida"] < p["dur"])
	for tx in _textos:
		tx["t"] += delta
	_textos = _textos.filter(func(tx) -> bool: return tx["t"] < tx["dur"])
	for g in _globos:
		g["t"] += delta
	_globos = _globos.filter(func(g) -> bool: return g["t"] < 2.2)
	for id in _saltitos.keys():
		_saltitos[id] += delta
		if _saltitos[id] > 0.6:
			_saltitos.erase(id)
	for id in _anim_obj:
		var a: Dictionary = _anim_obj[id]
		a["sacudir"] = maxf(0.0, float(a["sacudir"]) - delta * 2.0)
		a["rebote"] = maxf(0.0, float(a["rebote"]) - delta * 3.0)
	# Escondites cerrados con alguien adentro: se sacuden solitos cada tanto ("algo se mueve").
	if _fase == "jugando" and fmod(_t, 4.0) < delta:
		for oid in logica.objetos:
			if logica.abierto(oid) < 1.0 and logica.animal_dentro(oid) != "":
				var anim: Dictionary = _anim_obj.get(oid, {"sacudir": 0.0, "rebote": 0.0, "ultimo": -10.0})
				anim["sacudir"] = 0.5
				_anim_obj[oid] = anim
	var fijos := logica.ayuda_fuerte() and logica.ayuda_fuerte_todos_asoman
	for id in _asomes.keys():
		var a2: Dictionary = _asomes[id]
		a2["t"] += delta
		var k := clampf(a2["t"] / a2["dur"], 0.0, 1.0)
		var valor := minf(1.0, sin(k * PI) * 1.6)
		if k >= 1.0:
			_asomes.erase(id)
			valor = 0.0
		if not (fijos and id in logica.asomados and float(logica.asomados[id]) >= 1.0 and not _asomes.has(id)):
			if fijos:
				valor = 1.0
			if valor <= 0.0:
				logica.asomados.erase(id)
			else:
				logica.asomados[id] = valor
	for v in _vuelos:
		v["t"] += delta
		if v["t"] >= DUR_SALTO + DUR_VUELO and not v.get("llego", false):
			v["llego"] = true
			_en_fila.append(v["id"])
			_tarjeta_rebote = 1.0
			reproducir_sfx(SFX_TARJETA, 1.2)
	_vuelos = _vuelos.filter(func(v) -> bool: return not v.get("llego", false))
	if not _senal.is_empty():
		_senal["t"] += delta
		if _senal["t"] > 3.0 or _senal["id"] in logica.encontrados:
			_senal = {}
	if not _circulo_pista.is_empty():
		_circulo_pista["t"] += delta
		if _circulo_pista["t"] > 4.5:
			_circulo_pista = {}
	if not _borde_pista.is_empty():
		_borde_pista["t"] += delta
		if _borde_pista["t"] > 2.0:
			_borde_pista = {}
	_toby_salto = maxf(0.0, _toby_salto - delta * 2.2)
	_toby_olfatea = maxf(0.0, _toby_olfatea - delta)
	_tarjeta_rebote = maxf(0.0, _tarjeta_rebote - delta * 3.0)
	for c in _carreras:
		c["t"] += delta
	_carreras = _carreras.filter(func(c) -> bool: return c["t"] < 0.7)
	if not _eq_gag.is_empty():
		_eq_gag["t"] += delta


func _estallido(centro: Vector2, n: int, dorado: bool) -> void:
	for i in n:
		var ang := TAU * i / n + logica.rng.randf_range(-0.2, 0.2)
		_particulas.append({"pos": centro, "vel": Vector2.from_angle(ang) * logica.rng.randf_range(160, 320), "r": 9.0,
			"color": DORADO if dorado or i % 2 == 0 else Color("#FFFFFF"), "vida": 0.0, "dur": 0.8, "g": 300.0, "estrella": true})
	_particulas.append({"pos": centro, "vel": Vector2.ZERO, "r": 30.0, "color": DORADO, "vida": 0.0, "dur": 0.5, "g": 0.0, "anillo": true})


func _soltar_hojitas(desde: Vector2, color: Color, n: int) -> void:
	for i in n:
		_particulas.append({"pos": desde + Vector2(logica.rng.randf_range(-40, 40), 0), "vel": Vector2(logica.rng.randf_range(-90, 90), logica.rng.randf_range(-160, -40)),
			"r": logica.rng.randf_range(5, 9), "color": color, "vida": 0.0, "dur": 0.9, "g": 380.0})


func _soltar_gotas(desde: Vector2, n: int, chorro: bool) -> void:
	for i in n:
		var vel := Vector2(logica.rng.randf_range(-60, 60), logica.rng.randf_range(-520, -380)) if chorro else Vector2(logica.rng.randf_range(-150, 150), logica.rng.randf_range(-260, -120))
		_particulas.append({"pos": desde, "vel": vel, "r": logica.rng.randf_range(5, 8), "color": Color("#7FD3F7"), "vida": 0.0, "dur": 1.0, "g": 700.0})


func _texto_flotante(pos: Vector2, texto: String, color: Color, dur: float, tam: int) -> void:
	if turnos != null:
		return  # En equipo, ningun texto con numeros (R2 de modo-equipo).
	_textos.append({"pos": pos, "texto": texto, "color": color, "t": 0.0, "dur": dur, "tam": tam})


# ---------------------------------------------------------------------------
# Voz (todo funciona sin audio: las lineas que no existen se omiten)
# ---------------------------------------------------------------------------

func _linea_voz(clave: String, sub := "") -> String:
	var valor = nivel.get("lineas_voz", {}).get(clave, "")
	if sub != "" and valor is Dictionary:
		valor = valor.get(sub, "")
	if valor is Array:
		return str(valor[logica.rng.randi_range(0, valor.size() - 1)]) if not valor.is_empty() else ""
	if valor is Dictionary:
		return ""
	return str(valor)


func _decir(ruta: String, ya := false) -> void:
	if ruta == "" or ruta == "PENDIENTE" or not ResourceLoader.exists(resolver_ruta_audio(ruta)):
		return
	var audio := get_node_or_null("/root/Audio")
	if audio == null:
		return
	if ya or not audio.esta_hablando():
		_cola_voz.clear()
		reproducir_voz(ruta)
	elif _cola_voz.size() < 2:
		_cola_voz.append(ruta)


func _procesar_voz() -> void:
	if _cola_voz.is_empty():
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null and not audio.esta_hablando():
		reproducir_voz(_cola_voz.pop_front())


# ---------------------------------------------------------------------------
# Destinos de la lista
# ---------------------------------------------------------------------------

func _indice_objetivo(id: String) -> int:
	return logica.objetivos.find(id)


## Centro (pantalla) del puntito / casillero de un objetivo en la franja.
func _destino_tarjeta(id: String) -> Vector2:
	var i := _indice_objetivo(id)
	if i < 0:
		return Vector2(110, 560)
	match logica.modo_lista:
		"libre":
			return _centro_casillero(i)
		_:
			return _centro_puntito(i)


func _centro_casillero(i: int) -> Vector2:
	var n := maxi(1, logica.objetivos.size())
	var paso := minf(130.0, (FRANJA.size.x - 40.0) / n)
	var x0 := FRANJA.get_center().x - paso * (n - 1) / 2.0
	return Vector2(x0 + paso * i, FRANJA.get_center().y)


func _centro_puntito(i: int) -> Vector2:
	var n := logica.objetivos.size()
	if logica.modo_lista == "uno":
		var x0 := 600.0
		var paso := minf(84.0, (FRANJA.end.x - x0 - 30.0) / maxi(1, n))
		return Vector2(x0 + paso * (i + 0.5), FRANJA.get_center().y)
	var porfila := int(ceil(n / 2.0))
	var col := i % porfila
	var fila := i / porfila
	var paso2 := minf(30.0, 110.0 / maxi(1, porfila - 1))
	return Vector2(1142.0 + paso2 * col, FRANJA.position.y + 34.0 + fila * 44.0)


func _rect_tarjeta(i: int) -> Rect2:
	if logica.modo_lista == "uno":
		return Rect2(226, 612, 360, 96)
	return Rect2(224 + i * 300, 612, 290, 96)


func _rect_cartel() -> Rect2:
	return Rect2(370, 140, 540, 420)


# ---------------------------------------------------------------------------
# Dibujo: escena
# ---------------------------------------------------------------------------

func _dibujar_juego() -> void:
	if logica.nivel.is_empty():
		return
	_juego.draw_set_transform(-_vista * _zoom, 0.0, Vector2(_zoom, _zoom))
	var escena: Dictionary = nivel.get("escena", {})
	var tarde := 0.0 if logica.limite <= 0.0 else pow(logica.avance_sol(), 2.0)
	if _fase == "perdio":
		tarde = 1.0
	D.dibujar_fondo(_juego, escena.get("fondo", {}), tamano_escena(), _t, tarde)
	# Piezas y animales ordenados por z (de atras hacia adelante).
	var cosas: Array = []
	for oid in logica.orden_objetos:
		cosas.append({"z": logica.z_objeto(oid), "obj": oid})
	var en_vuelo: Array = _vuelos.map(func(v) -> String: return v["id"])
	var mostrar_todos := _fase == "perdio"
	for id in logica.en_escena():
		if id in logica.encontrados or id in en_vuelo:
			continue
		if not _eq_gag.is_empty() and logica.es_objetivo(id):
			continue
		if logica.esta_dentro(id) and not logica.revelado(id) and not mostrar_todos:
			continue
		cosas.append({"z": logica.z_animal(id), "animal": id})
	cosas.sort_custom(func(a, b) -> bool: return float(a["z"]) < float(b["z"]))
	var usadas := {}
	for id in logica.encontrados:
		usadas[logica.pieza_de(logica.escondite(id))] = true
	for c in cosas:
		if c.has("obj"):
			var oid: String = c["obj"]
			D.dibujar_pieza(_juego, logica.objetos[oid], logica.abierto(oid), _anim_obj.get(oid, {}), _t + oid.hash() % 100, usadas.has(oid))
		elif not mostrar_todos:
			_dibujar_animal_en_escena(c["animal"])
	if mostrar_todos:
		_dibujar_gag_derrota()
	elif _fase == "intro":
		_dibujar_intro_corrida()
	# Vuelos: el salto se ve en la escena (squash al despegar, stretch en el aire).
	for v in _vuelos:
		if float(v["t"]) < DUR_SALTO:
			var k := float(v["t"]) / DUR_SALTO
			var esc: Dictionary = v["esc"]
			var pie: Vector2 = v["desde"] + Vector2(0, -sin(k * PI) * 90.0 - k * 40.0)
			D.dibujar_animal(_juego, _aspecto(v["id"]), pie, float(esc.get("tamano", 100)), bool(esc.get("espejo", false)),
				{"feliz": true, "squash": -0.6 * sin(k * PI) if k > 0.15 else 0.8 * (1.0 - k / 0.15), "rot": k * TAU * 0.25})
	_dibujar_particulas()
	if not _circulo_pista.is_empty():
		var a := clampf(1.0 - maxf(0.0, float(_circulo_pista["t"]) - 3.5), 0.0, 1.0)
		var c: Vector2 = _circulo_pista["centro"]
		_juego.draw_circle(c, 150.0, Color(1.0, 0.85, 0.4, 0.18 * a))
		_juego.draw_arc(c, 150.0 + 6.0 * sin(_t * 4.0), 0, TAU, 48, Color(1.0, 0.7, 0.2, 0.75 * a), 7.0, true)
	if not _senal.is_empty() and logica.animales.has(_senal["id"]):
		var arriba: Rect2 = logica.zona_toque(_senal["id"])
		var punta := Vector2(arriba.get_center().x, arriba.position.y - 10.0 - 14.0 * absf(sin(_t * 6.0)))
		_dibujar_flechita(punta)
	# Lo que sigue va en pantalla.
	_juego.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if tarde > 0.0:
		_juego.draw_rect(Rect2(Vector2.ZERO, PANTALLA), Color(1.0, 0.55, 0.25, 0.16 * tarde))
	if _fase == "perdio":
		_juego.draw_rect(Rect2(Vector2.ZERO, PANTALLA), Color(0.15, 0.1, 0.35, minf(0.28, _gag_t * 0.4)))
	if not _borde_pista.is_empty():
		var lado: Vector2 = _borde_pista["lado"]
		var a2 := 0.6 * (1.0 - float(_borde_pista["t"]) / 2.0)
		var x := 0.0 if lado.x < 0 else PANTALLA.x - 40.0
		if absf(lado.x) >= absf(lado.y):
			_juego.draw_rect(Rect2(x, 0, 40, FRANJA.position.y), Color(1.0, 0.8, 0.3, a2))
		else:
			_juego.draw_rect(Rect2(0, 0.0 if lado.y < 0 else FRANJA.position.y - 40.0, PANTALLA.x, 40), Color(1.0, 0.8, 0.3, a2))
	for g in _globos:
		if logica.animales.has(g["id"]):
			var sp := mundo_a_pantalla(G.caja_de(logica.partes_animal(g["id"])).position + Vector2(40, 0))
			_globo_texto(sp, str(g["texto"]))
	for o in _ondas:
		var k2 := float(o["t"]) / 0.25
		_juego.draw_arc(o["pos"], 20.0 + 30.0 * k2, 0, TAU, 28, Color(1, 1, 1, 0.85 * (1.0 - k2)), 5.0, true)
	if not _eq_gag.is_empty():
		_dibujar_gag_equipo()
	for c2 in _carreras:
		var k3 := clampf(float(c2["t"]) / 0.6, 0.0, 1.0)
		var desde := mundo_a_pantalla(c2["desde"])
		var hasta := mundo_a_pantalla(logica.pie_animal(c2["id"]))
		D.dibujar_animal(_juego, _aspecto(c2["id"]), desde.lerp(hasta, k3) + Vector2(0, -60.0 * sin(k3 * PI)), 70.0, hasta.x < desde.x,
			{"silueta": Color(CONTORNO, 0.55 * (1.0 - k3 * 0.5))})


func _aspecto(id: String) -> Dictionary:
	return logica.animales.get(id, {}).get("aspecto", {})


func _dibujar_animal_en_escena(id: String) -> void:
	var esc := logica.escondite(id)
	var tam := logica.tamano_animal(id)
	var op := {}
	if bool(esc.get("camuflaje", false)):
		var pieza: Dictionary = logica.objetos.get(logica.pieza_de(esc), {})
		var colores: Array = D.COLORES_PIEZA.get(str(pieza.get("tipo", "")), ["#7FBF6A"])
		op["tinte"] = Color(str(pieza.get("color", colores[mini(1, colores.size() - 1)])))
		op["mezcla"] = float(esc.get("mezcla", 0.4))
	var pie := logica.pie_animal(id)
	var sq := 0.0
	if _saltitos.has(id):
		var k := float(_saltitos[id]) / 0.6
		pie += Vector2(0, -sin(k * PI) * tam * 0.3)
		sq = -0.4 * sin(k * PI)
		op["feliz"] = true
	else:
		# Respiran: un vaiven minimo para que la escena este viva.
		sq = 0.08 * sin(_t * 2.2 + id.hash() % 7)
	op["squash"] = sq
	op["ojos_cerrados"] = fmod(_t + (id.hash() % 50) * 0.1, 4.0) < 0.12
	D.dibujar_animal(_juego, _aspecto(id), pie, tam, bool(esc.get("espejo", false)), op)


## Intro: Toby cuenta y los animales corren a sus escondites (siluetas rapidas, §5.1).
func _dibujar_intro_corrida() -> void:
	var k := clampf(_intro_t / (DUR_INTRO * 0.8), 0.0, 1.0)
	if k >= 1.0:
		return
	var origen := pantalla_a_mundo(Vector2(140, 560))
	for id in logica.en_escena():
		if id in logica.encontrados:
			continue
		var destino := logica.pie_animal(id)
		var kk := ease(k, 0.6)
		var p := origen.lerp(destino, kk) + Vector2(0, -sin(kk * PI) * 120.0)
		D.dibujar_animal(_juego, _aspecto(id), p, logica.tamano_animal(id) * 0.8, destino.x < origen.x,
			{"silueta": Color(CONTORNO, 0.55 * (1.0 - k))})


func _dibujar_gag_derrota() -> void:
	var k := clampf(_gag_t / 0.5, 0.0, 1.0)
	for id in logica.en_escena():
		if id in logica.encontrados:
			continue
		var tam := logica.tamano_animal(id)
		var pie := logica.pie_animal(id) + Vector2(0, -tam * 0.6 * k - absf(sin(_t * 7.0 + id.hash() % 5)) * 26.0)
		D.dibujar_animal(_juego, _aspecto(id), pie, tam, bool(logica.escondite(id).get("espejo", false)),
			{"feliz": true, "squash": 0.15 * sin(_t * 9.0), "rot": 0.15 * sin(_t * 5.0 + id.hash() % 3)})


func _dibujar_particulas() -> void:
	for p in _particulas:
		var a := 1.0 - float(p["vida"]) / float(p["dur"])
		var color: Color = p["color"]
		if p.get("anillo", false):
			_juego.draw_arc(p["pos"], float(p["r"]) + 90.0 * (1.0 - a), 0, TAU, 32, Color(color, a), 6.0, true)
		elif p.get("estrella", false):
			D.estrella(_juego, p["pos"], float(p["r"]), Color(color, a))
		else:
			_juego.draw_circle(p["pos"], float(p["r"]), Color(color, a))


func _dibujar_flechita(punta: Vector2) -> void:
	var pts := PackedVector2Array([punta, punta + Vector2(-26, -34), punta + Vector2(-10, -34), punta + Vector2(-10, -70),
		punta + Vector2(10, -70), punta + Vector2(10, -34), punta + Vector2(26, -34)])
	D.trazar(_juego, pts, 10.0)
	D.rellenar(_juego, pts, DORADO)


func _globo_texto(p: Vector2, texto: String) -> void:
	var tam := 24
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 32.0
	var r := Rect2(p + Vector2(-ancho / 2.0, -64), Vector2(ancho, 48)).intersection(Rect2(8, 8, 1264, 590))
	var caja := _caja(CREMA, 22)
	_juego.draw_style_box(caja, r)
	_texto(_juego, texto, r.get_center(), tam, TINTA)


func _dibujar_gag_equipo() -> void:
	var fase_g := str(_eq_gag["fase"])
	if fase_g == "oculto":
		return
	var k := clampf(float(_eq_gag["t"]) / maxf(0.01, float(_eq_gag["dur"])), 0.0, 1.0)
	var destino: Vector2 = _eq_gag["destino"]
	for id in logica.faltan():
		var sp := mundo_a_pantalla(logica.pie_animal(id))
		var desde: Vector2 = _eq_gag.get("desde", {}).get(id, sp)
		var p := desde.lerp(destino, k * k) if fase_g == "aspirar" else destino.lerp(sp, k)
		var esc := 1.0 - 0.7 * k if fase_g == "aspirar" else 0.3 + 0.7 * k
		D.dibujar_animal(_juego, _aspecto(id), p, 80.0 * esc, false, {"feliz": true})


# ---------------------------------------------------------------------------
# Dibujo: HUD (lista, Toby, sol, mapita, intro, foto)
# ---------------------------------------------------------------------------

func _dibujar_hud() -> void:
	if logica.nivel.is_empty():
		return
	_dibujar_franja()
	_dibujar_toby()
	if logica.limite > 0.0 and turnos == null:
		_dibujar_sol()
	if _mapita_visible() and (logica.perfil != "semilla" or turnos != null):
		_dibujar_mapita()
	# Vuelos hacia la tarjeta (en pantalla).
	for v in _vuelos:
		var t := float(v["t"])
		if t < DUR_SALTO:
			continue
		var k := clampf((t - DUR_SALTO) / DUR_VUELO, 0.0, 1.0)
		var esc: Dictionary = v["esc"]
		var desde := mundo_a_pantalla(v["desde"] + Vector2(0, -130))
		var hasta: Vector2 = v["hasta"] + Vector2(0, 30)
		var p := desde.lerp(hasta, k) + Vector2(0, -sin(k * PI) * 140.0)
		var tam := lerpf(float(esc.get("tamano", 100)) * _zoom, 60.0, k)
		D.dibujar_animal(_hud, _aspecto(v["id"]), p, tam, false, {"feliz": true})
		for q in 4:
			_hud.draw_circle(p + Vector2(-12.0 * q, 8.0 * q) * (1.0 if hasta.x > desde.x else -1.0), 6.0 - q, Color(DORADO, 0.6 - q * 0.12))
	if _fase == "intro":
		_dibujar_cuenta()
	if _fase == "foto":
		_dibujar_foto()
	for tx in _textos:
		var k2 := float(tx["t"]) / float(tx["dur"])
		var color: Color = tx["color"]
		color.a = 1.0 - maxf(0.0, k2 - 0.6) / 0.4
		_texto(_hud, tx["texto"], tx["pos"] + Vector2(0, -40.0 * k2), int(tx["tam"]), color)
	if _fase == "perdio" and _gag_t < duracion_gag() + 0.2:
		_texto(_hud, "¡Aquí estábamos!" if logica.perfil != "semilla" else "", Vector2(640, 120 - 10.0 * absf(sin(_t * 6.0))), 56, Color("#FF8A3D"))
		# Lucecitas de la carpa de Toby que se encienden.
		for i in 24:
			var x := 40.0 + i * 52.0
			var y := 24.0 + 10.0 * sin(i * 0.9)
			var on := fmod(_t * 4.0 + i, 3.0) < 2.0
			_hud.draw_circle(Vector2(x, y), 9.0, ([Color("#FFCB3D"), Color("#FF7EB6"), Color("#7FD3F7")][i % 3]) if on else Color(1, 1, 1, 0.3))


func _dibujar_franja() -> void:
	var caja := _caja(Color("#B07A4A"), 30)
	caja.border_color = CONTORNO
	caja.set_border_width_all(5)
	_hud.draw_style_box(caja, FRANJA)
	for i in 3:
		var y := FRANJA.position.y + 26.0 + i * 30.0
		_hud.draw_line(Vector2(FRANJA.position.x + 40, y), Vector2(FRANJA.end.x - 40, y + 4.0), Color("#9A6740"), 3.0, true)
	var rebote := 1.0 + 0.06 * sin(_tarjeta_rebote * PI)
	match logica.modo_lista:
		"libre":
			for i in logica.objetivos.size():
				var c := _centro_casillero(i)
				_hud.draw_circle(c, 46.0, Color(CREMA, 0.35))
				_hud.draw_arc(c, 46.0, 0, TAU, 32, Color(CREMA, 0.9), 4.0, true)
			var j := 0
			for id in _en_fila:
				if j >= logica.objetivos.size():
					break
				var c2 := _centro_casillero(j)
				_hud.draw_circle(c2, 46.0, CREMA)
				D.dibujar_animal(_hud, _aspecto(id), c2 + Vector2(0, 40), 78.0, false, {"feliz": true})
				j += 1
		"uno":
			var id2 := logica.activo()
			var r := _rect_tarjeta(0)
			r = r.grow(4.0 * (rebote - 1.0) * 20.0)
			_hud.draw_style_box(_caja(CREMA, 26), r)
			if id2 != "":
				var perfil_turno := logica.perfil
				var animal: Dictionary = logica.animales.get(id2, {})
				if perfil_turno == "estrella" and turnos != null and animal.has("pista"):
					_texto_ajustado(_hud, str(animal["pista"].get("texto", "")), r, 22)
				else:
					D.dibujar_animal(_hud, _aspecto(id2), Vector2(r.position.x + 62, r.end.y - 8), 84.0, false, {"silueta": Color("#5B4F7A")})
					if bool(nivel.get("mostrar_palabra", true)):
						_texto(_hud, str(animal.get("palabra", animal.get("nombre", id2))).to_upper(), Vector2(r.position.x + 236, r.get_center().y), 46, TINTA)
			_dibujar_puntitos()
		"tarjetas":
			var act := logica.activos()
			for i in act.size():
				var r2 := _rect_tarjeta(i)
				_hud.draw_style_box(_caja(CREMA, 22), r2)
				var pista: Dictionary = logica.animales.get(act[i], {}).get("pista", {})
				_texto_ajustado(_hud, str(pista.get("texto", "?")), r2.grow(-10), 21)
			_dibujar_puntitos()


func _dibujar_puntitos() -> void:
	for i in logica.objetivos.size():
		var id := logica.objetivos[i]
		var c := _centro_puntito(i)
		var radio := 30.0 if logica.modo_lista == "uno" else 13.0
		if id in _en_fila:
			_hud.draw_circle(c, radio, CREMA)
			if logica.modo_lista == "uno":
				D.dibujar_animal(_hud, _aspecto(id), c + Vector2(0, radio * 0.85), radio * 1.7, false, {"feliz": true})
			else:
				_hud.draw_circle(c, radio * 0.6, DORADO)
		else:
			_hud.draw_circle(c, radio, Color(CREMA, 0.35))
		_hud.draw_arc(c, radio, 0, TAU, 24, Color(CREMA, 0.95), 3.0, true)


func _dibujar_toby() -> void:
	var salto := sin(_toby_salto * PI) * 26.0
	var rot := 0.0
	if _fase == "perdio":
		rot = -0.35 + 0.05 * sin(_t * 10.0)
	if _toby_olfatea > 0.0:
		rot = 0.06 * sin(_t * 30.0)
	var alto := 230.0
	if _toby != null:
		var ancho := alto * _toby.get_width() / _toby.get_height()
		var base := Vector2(100, 714 - salto)
		_hud.draw_set_transform(base, rot, Vector2.ONE)
		_hud.draw_texture_rect(_toby, Rect2(Vector2(-ancho / 2.0, -alto), Vector2(ancho, alto)), false)
		_hud.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		D.dibujar_animal(_hud, {"forma": "sentado", "color": "#C98B4E", "color2": "#FFF1DC", "orejas": "caidas"}, Vector2(100, 714 - salto), 200.0, false, {})
	# Antena-radar (Sofia) o tocar para repetir: una estrellita dorada que respira.
	var antena := Vector2(100, 452 - salto)
	_hud.draw_line(Vector2(100, 490 - salto), antena, CONTORNO, 5.0, true)
	var giro := _t * 6.0 if _toby_olfatea > 0.0 else 0.0
	_hud.draw_set_transform(antena, giro, Vector2.ONE)
	D.estrella(_hud, Vector2.ZERO, 22.0 + 2.0 * sin(_t * 3.0), CONTORNO)
	D.estrella(_hud, Vector2.ZERO, 17.0 + 2.0 * sin(_t * 3.0), DORADO)
	_hud.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _toby_olfatea > 0.0:
		_texto(_hud, "snif snif", Vector2(200, 430), 24, Color("#5B4F7A"))
	# Ayuda fuerte: un animal se le sube a la cabeza en el gag.
	if _fase == "perdio":
		var resto := logica.faltan()
		if not resto.is_empty():
			D.dibujar_animal(_hud, _aspecto(resto[0]), Vector2(110, 520 - absf(sin(_t * 7.0)) * 16.0), 80.0, false, {"feliz": true})


## El sol baja despacio detras de los arboles (sin tic-tac ni parpadeo). Semilla: solcito que bosteza.
func _dibujar_sol() -> void:
	var k := logica.avance_sol() if _fase != "perdio" else 1.0
	var c := Vector2(1240, lerpf(244, 568, k))
	var color := Color("#FFD93D").lerp(Color("#FF8A3D"), k)
	for i in 8:
		var a := TAU * i / 8.0 + _t * 0.3
		_hud.draw_line(c + Vector2.from_angle(a) * 32.0, c + Vector2.from_angle(a) * 42.0, color, 5.0, true)
	_hud.draw_circle(c, 29.0, CONTORNO)
	_hud.draw_circle(c, 25.0, color)
	Figura.dibujar_cara(_hud, c + Vector2(0, 2), 30.0, k > 0.85)
	if logica.perfil == "semilla" and k > 0.6:
		_hud.draw_circle(c + Vector2(0, 10), 4.0 + 3.0 * absf(sin(_t * 2.0)), CONTORNO)
	# Arbolitos delante: el sol se esconde detras.
	var cerro := PackedVector2Array([Vector2(1196, 604), Vector2(1196, 580), Vector2(1214, 560), Vector2(1236, 574), Vector2(1258, 552), Vector2(1280, 566), Vector2(1280, 604)])
	D.rellenar(_hud, cerro, Color("#4FAE5C"))
	D.trazar(_hud, cerro, 4.0)


func _dibujar_mapita() -> void:
	var r := _rect_mapa()
	_hud.draw_style_box(_caja(Color("#B8E3A0"), 12), r.grow(4))
	var t := tamano_escena()
	var vista := Rect2(r.position + _vista / t * r.size, PANTALLA / _zoom / t * r.size)
	_hud.draw_rect(vista.intersection(r), Color(1, 1, 1, 0.45))
	_hud.draw_rect(vista.intersection(r), CONTORNO, false, 3.0)


func _dibujar_cuenta() -> void:
	var n := int(floor(_intro_t / 0.7)) + 1
	if n > 3 or _intro_t > DUR_INTRO * 0.9:
		return
	var k := fmod(_intro_t, 0.7) / 0.7
	_texto(_hud, str(n), Vector2(640, 300), int(90 + 50 * sin(k * PI)), Color("#FF8A3D", 1.0 - k * 0.5))


func _dibujar_foto() -> void:
	var k := clampf(_foto_t / 0.4, 0.0, 1.0)
	if _foto_t < 0.0:
		return
	_hud.draw_rect(Rect2(Vector2.ZERO, PANTALLA), Color(1.0, 0.97, 0.9, 0.55 * k))
	var marco := Rect2(250, 140, 780, 440)
	_hud.draw_style_box(_caja(CREMA, 18), marco)
	var lista := logica.objetivos
	var n := lista.size()
	var paso := minf(110.0, 640.0 / maxi(1, n))
	for i in n:
		var x := 640.0 - paso * (n - 1) / 2.0 + paso * i
		var y := 500.0 - 30.0 * absf(sin(_t * 5.0 + i))
		D.dibujar_animal(_hud, _aspecto(lista[i]), Vector2(x, y), minf(120.0, paso * 1.3), i % 2 == 1, {"feliz": true})
	if _toby != null:
		var alto := 200.0
		var ancho := alto * _toby.get_width() / _toby.get_height()
		_hud.draw_texture_rect(_toby, Rect2(Vector2(640 - ancho / 2.0, 330 - alto * 0.5), Vector2(ancho, alto)), false)
	if _flash > 0.0:
		_hud.draw_rect(Rect2(Vector2.ZERO, PANTALLA), Color(1, 1, 1, _flash))


func _dibujar_fin() -> void:
	_fin.draw_rect(Rect2(Vector2.ZERO, _fin.size), Color(CONTORNO, 0.25))
	var r := _rect_cartel()
	_fin.draw_style_box(_caja(CREMA, 48), r)
	var rebote := sin(_t * 5.0) * 6.0
	# Semilla: sin texto ni puntaje, solo la flecha gigante (ficha §10.1).
	if logica.perfil != "semilla":
		_texto(_fin, "¡Se puso el sol!", Vector2(640, 200 + rebote), 52, Color("#E08A00"))
	else:
		var c := Vector2(640, 220 + rebote)
		_fin.draw_circle(c, 34.0, Color("#FF8A3D"))
		Figura.dibujar_cara(_fin, c, 36.0, true)


# ---------------------------------------------------------------------------
# Modo equipo (ficha §12.2; modo-equipo.md §11.4)
# ---------------------------------------------------------------------------

func _preparar_equipo() -> void:
	var bloque = nivel.get("equipo", {})
	_eq = bloque if bloque is Dictionary else {}
	logica.factor_sol = 0.0
	logica.limite = 0.0
	logica.modo_lista = "uno"
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
		ui.move_child(capa, _hud.get_index() + 1)
	turnos.turno_iniciado.connect(func(_id: String, perfil: String) -> void: aplicar_perfil_turno(perfil))
	turnos.jugada_automatica_pedida.connect(_jugada_automatica_equipo)
	turnos.tope_alcanzado.connect(func() -> void: _eq_tope = true)
	_arrancar_equipo.call_deferred()


func _config_gestor() -> Dictionary:
	var config: Dictionary = _eq.duplicate(true)
	var comps = _eq.get("composiciones", {})
	var comp: Dictionary = {}
	if comps is Dictionary and not comps.is_empty():
		var clave := _clave_equipo()
		comp = comps.get(clave, comps.values()[0])
	config.erase("composiciones")
	config["pasos_rival"] = int(comp.get("pasos_rival", _eq.get("pasos_rival", 6)))
	config["aciertos_totales"] = logica.objetivos.size()
	config["lineas_voz"] = nivel.get("lineas_voz", {})
	var record := -1
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and not en_batalla:
		record = progreso.obtener_record_equipo(planeta_id, _id_nivel_actual(), _clave_equipo())
	config["record_pasos"] = record
	return config


func _clave_equipo() -> String:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null:
		return progreso.clave_equipo(equipo)
	var copia := equipo.duplicate()
	copia.sort()
	return "+".join(PackedStringArray(copia))


func _arrancar_equipo() -> void:
	await get_tree().create_timer(DUR_INTRO + 0.2).timeout
	if not is_inside_tree() or _eq_victoria:
		return
	if _eq_restaurado:
		turnos.empezar_retomando()
	else:
		turnos.empezar()


## La capa del perfil del turno (§12.2): zona de toque, abrir y encontrar, y para Maxi el activo asoma y
## la escena se desliza hasta el.
func aplicar_perfil_turno(perfil: String) -> void:
	logica.perfil = perfil
	logica.zona_min = float({"semilla": 160, "brote": 96, "estrella": 64}.get(perfil, 96))
	logica.abrir_y_encontrar = perfil != "estrella"
	logica._medidas.clear()
	_eq_t_turno = 0.0
	_eq_tope = false
	logica.asomados.clear()
	var id := logica.activo()
	if id == "":
		return
	if perfil == "semilla":
		if logica.esta_dentro(id):
			logica.abiertos[logica.pieza_de(logica.escondite(id))] = int(logica.objetos[logica.pieza_de(logica.escondite(id))].get("pasos", 1))
		logica.asomados[id] = 1.0
		logica._medidas.clear()
		mover_vista_a(logica.medida(id)["centro"], 0.6)
		var animal: Dictionary = logica.animales.get(id, {})
		reproducir_sfx(str(animal.get("sonido", SFX_ANIMAL)), float(animal.get("tono", 1.0)))
	else:
		_decir(_linea_voz("busca", id))


func _procesar_equipo(delta: float) -> void:
	if _eq_victoria or not _eq_gag.is_empty():
		return
	if _eq_tope and _vuelos.is_empty():
		_eq_tope = false
		turnos.confirmar_turno_estable()
		return
	if not turnos.turno_activo() or turnos.entrada_bloqueada():
		return
	var limites = _eq.get("segundos_por_turno", {})
	var perfil := turnos.perfil_actual()
	var lim := float(limites.get(perfil, 0)) if limites is Dictionary else 0.0
	if lim <= 0.0:
		return
	_eq_t_turno += delta
	if _eq_t_turno >= lim:
		_eq_t_turno = 0.0
		cortar_turno_por_tiempo()


## Se acabo el tiempo del turno sin encontrar: el activo se cambia de escondite (se lo ve correr, gag) y el
## turno termina con fallo. Publica para QA.
func cortar_turno_por_tiempo() -> void:
	var id := logica.activo()
	if id != "":
		var desde := logica.pie_animal(id)
		logica.asomados.erase(id)
		if logica.cambiar_escondite(id):
			_carreras.append({"id": id, "desde": desde, "t": 0.0})
			reproducir_sfx(SFX_VUELO)
	turnos.terminar_turno(true)


func _jugada_automatica_equipo() -> void:
	var id := logica.activo()
	if id == "" or not _puede_jugar():
		return
	if logica.esta_dentro(id):
		logica.abiertos[logica.pieza_de(logica.escondite(id))] = int(logica.objetos[logica.pieza_de(logica.escondite(id))].get("pasos", 1))
		logica._medidas.clear()
	logica.tocar_animal(id)


func _victoria_equipo() -> void:
	if _eq_victoria:
		return
	_eq_victoria = true
	_fase = "foto"
	_foto_t = 0.0
	var pasos := turnos.pasos_usados()
	turnos.detener()
	_confeti.restart()
	_confeti.emitting = true
	if en_batalla:
		await get_tree().create_timer(1.0).timeout
		if is_inside_tree():
			emitir_completado(0)
		return
	asegurar_victoria_equipo(pasos)
	turnos.rival_aplaude()
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	_fase = "celebrando"
	celebrar_equipo(pasos, _linea_voz("victoria_equipo"))


func ancla_meta_turno() -> Vector2:
	return Vector2(FRANJA.position.x - 8.0, FRANJA.get_center().y)


func gag_derrota_aspirar(destino: Vector2) -> float:
	var desde := {}
	for id in logica.faltan():
		desde[id] = mundo_a_pantalla(logica.pie_animal(id))
	_eq_gag = {"fase": "aspirar", "t": 0.0, "dur": 0.8, "destino": destino, "desde": desde}
	return 0.8


## Los estornuda a escondites NUEVOS (ficha §12.2); lo encontrado queda.
func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	var destino: Vector2 = _eq_gag.get("destino", PANTALLA / 2.0)
	_resortear_faltantes()
	_eq_gag = {"fase": "devolver", "t": 0.0, "dur": 0.6, "destino": destino}
	return 0.6


func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	if _eq_gag.get("fase", "") == "aspirar":
		_resortear_faltantes()
	_eq_gag = {}


func _resortear_faltantes() -> void:
	var ids: Array = logica.faltan()
	var previos := {}
	for id in ids:
		previos[id] = int(logica.asignacion.get(id, 0))
	logica.abiertos.clear()
	logica.asomados.clear()
	logica.sortear_escondites(ids, previos)


func contar_logro_equipo() -> int:
	return logica.encontrados.size()


func obtener_parcial_equipo() -> Dictionary:
	return {"encontrados": logica.encontrados.duplicate(), "asignacion": logica.asignacion.duplicate()}


func restaurar_parcial_equipo(estado: Dictionary) -> void:
	var lista = estado.get("encontrados", [])
	if not lista is Array:
		return
	for id in lista:
		if str(id) in logica.objetivos and not str(id) in logica.encontrados:
			logica.encontrados.append(str(id))
			_en_fila.append(str(id))
	var asig = estado.get("asignacion", {})
	if asig is Dictionary:
		for id in asig:
			if logica.animales.has(str(id)):
				logica.fijar_escondite(str(id), int(asig[id]))
	_eq_restaurado = true


# ---------------------------------------------------------------------------
# Botones, cajas y textos (mismo estilo que los demas motores)
# ---------------------------------------------------------------------------

func _caja(fondo: Color, radio: int) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(radio)
	caja.shadow_color = Color(CONTORNO, 0.25)
	caja.shadow_offset = Vector2(0, 4)
	caja.shadow_size = 2
	caja.anti_aliasing = true
	return caja


func _texto(lienzo: CanvasItem, texto: String, centro: Vector2, tamano: int, color: Color) -> void:
	if texto == "":
		return
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var base := centro + Vector2(-ancho / 2.0, tamano * 0.35)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, maxi(4, int(tamano * 0.18)), Color(1, 1, 1, 0.95 * color.a))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


## Texto en hasta 3 lineas dentro de una tarjeta (pistas escritas de Sofia).
func _texto_ajustado(lienzo: CanvasItem, texto: String, rect: Rect2, tamano: int) -> void:
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var palabras := texto.split(" ")
	var lineas: Array[String] = []
	var actual := ""
	for p in palabras:
		var prueba := p if actual == "" else actual + " " + p
		if fuente.get_string_size(prueba, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x > rect.size.x - 16.0 and actual != "":
			lineas.append(actual)
			actual = p
		else:
			actual = prueba
	if actual != "":
		lineas.append(actual)
	var alto_linea := tamano * 1.1
	var y0 := rect.get_center().y - alto_linea * (lineas.size() - 1) / 2.0
	for i in lineas.size():
		_texto(lienzo, lineas[i], Vector2(rect.get_center().x, y0 + alto_linea * i), tamano, TINTA)


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
		caja.border_color = CONTORNO
		caja.set_border_width_all(5)
		caja.set_corner_radius_all(90)
		caja.shadow_color = Color(CONTORNO, 0.3)
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


func _dibujar_icono_reintentar(icono: Control) -> void:
	var c := icono.size / 2.0
	var r := icono.size.x * 0.27
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, CONTORNO, 22.0, true)
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, CREMA, 13.0, true)
	var punta := c + Vector2.from_angle(-PI * 0.15) * r
	var flecha := PackedVector2Array([punta + Vector2(-22, -6), punta + Vector2(18, -10), punta + Vector2(4, 26)])
	icono.draw_colored_polygon(flecha, CREMA)
	Figura.contornear(icono, flecha, 5.0)


func _dibujar_casita(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var casa := PackedVector2Array([c + Vector2(-24, 2) * k, c + Vector2(0, -22) * k, c + Vector2(24, 2) * k, c + Vector2(18, 2) * k,
		c + Vector2(18, 24) * k, c + Vector2(-18, 24) * k, c + Vector2(-18, 2) * k])
	icono.draw_colored_polygon(casa, TURQUESA)
	Figura.contornear(icono, casa, 5.0 * k)
	# Lunita: "a descansar".
	icono.draw_circle(c + Vector2(26, -26) * k, 9.0 * k, DORADO)


func _dibujar_lupa(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0 * 0.9
	var activo := _lupa_armada or _zoom > 1.01
	if activo:
		icono.draw_circle(c, 44.0 * k, Color(DORADO, 0.55))
	icono.draw_circle(c + Vector2(-6, -6) * k, 22.0 * k, Color("#CFF5F1"))
	icono.draw_arc(c + Vector2(-6, -6) * k, 22.0 * k, 0, TAU, 28, CONTORNO, 6.0 * k, true)
	icono.draw_line(c + Vector2(10, 10) * k, c + Vector2(28, 28) * k, CONTORNO, 10.0 * k, true)
	icono.draw_line(c + Vector2(-16, -6) * k, c + Vector2(4, -6) * k, CONTORNO, 5.0 * k, true)
	if _zoom <= 1.01:
		icono.draw_line(c + Vector2(-6, -16) * k, c + Vector2(-6, 4) * k, CONTORNO, 5.0 * k, true)
