class_name MotorMezclar
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "mezclar" — "Taller de pinturas de Coco" (docs/fichas/motor-mezclar.md).
##
## Reemplaza la mezcla de Sofia en "Lluvia de colores" (pedido del PO 27-Sep-2026: la mezcla antigua
## era muy facil y no tenia proposito). El bucle:
## 1. Coco quiere pintar un MURAL y pide 3 latas de colores concretos.
## 2. Por cada lata se muestra la RECETA con proporciones reales de pigmentos (modelo RYB + blanco),
##    p. ej. verde limon = 2 amarillas + 1 azul. Sofia la memoriza y la receta se esconde; la
##    libreta la vuelve a mostrar, pero cuesta una estrellita.
## 3. Caen gotas desde arriba y Sofia mueve el FRASCO (arrastrar, o tocar donde quiere que vaya)
##    para atrapar solo las de la receta. Una gota que no va (color equivocado, una de mas o la
##    gris) ensucia la mezcla: gag de "¡puaj!", el frasco se vacia y esa lata se empieza de nuevo.
##    Nunca se pierden las latas ya hechas ni se termina el nivel (GDD §6, regla de oro 2).
## 4. Con la receta completa se tapa el frasco y se AGITA (arrastrar de lado a lado, o mantener
##    presionado): las capas de colores se funden en el color final y sale una lata.
## 5. Con 3 latas, Coco las recibe y pinta el mural region por region. `murales` por nivel.
##
## Todo lo que cambia entre zonas llega en el JSON del nivel (contrato §4 de la ficha). Las gotas que
## se dejan pasar nunca castigan. F3 (solo PC) muestra un panel de depuracion para el PO.

signal gota_atrapada(color_id: String, sirve: bool)
signal lata_lista(color_id: String)
signal mural_terminado(indice: int)

const Figura := preload("res://scripts/ui/figura_vectorial.gd")

## Pigmentos y colores resultantes. Los resultados son la mezcla real aproximada (RYB).
const PALETA := {
	"rojo": "#F2474A", "amarillo": "#FFD23F", "azul": "#3F7FE0", "blanco": "#FFFFFF", "gris": "#A9A7B3",
	"verde": "#4DBE55", "naranja": "#FF9A3C", "violeta": "#9B6BDE",
	"verde_limon": "#A6D83B", "verde_azulado": "#2E9E8F", "mango": "#FFB42E", "tomate": "#F4643A",
	"fucsia": "#D63F8C", "anil": "#5549C2", "rosado": "#FF9CC8", "celeste": "#8AD8F7",
	"durazno": "#FFBE8F", "cafe": "#96603B", "lila": "#CDA8F2", "verde_claro": "#B2EB8F",
	"turquesa": "#45C6C0", "verde_oliva": "#8C8C35", "chocolate": "#7A3F28",
	"sucio": "#8C7B66",
}
## Recetas con proporciones (gotas por pigmento). El nivel puede agregar o cambiar con `recetas`.
const RECETAS := {
	"verde": {"amarillo": 1, "azul": 1},
	"naranja": {"rojo": 1, "amarillo": 1},
	"violeta": {"rojo": 1, "azul": 1},
	"verde_limon": {"amarillo": 2, "azul": 1},
	"verde_azulado": {"amarillo": 1, "azul": 2},
	"mango": {"rojo": 1, "amarillo": 2},
	"tomate": {"rojo": 2, "amarillo": 1},
	"fucsia": {"rojo": 2, "azul": 1},
	"anil": {"rojo": 1, "azul": 2},
	"rosado": {"rojo": 1, "blanco": 2},
	"celeste": {"azul": 1, "blanco": 2},
	"durazno": {"rojo": 1, "amarillo": 1, "blanco": 1},
	"cafe": {"rojo": 1, "amarillo": 1, "azul": 1},
	"lila": {"rojo": 1, "azul": 1, "blanco": 1},
	"verde_claro": {"amarillo": 1, "azul": 1, "blanco": 1},
	"turquesa": {"amarillo": 1, "azul": 2, "blanco": 1},
	"verde_oliva": {"rojo": 1, "amarillo": 2, "azul": 1},
	"chocolate": {"rojo": 2, "amarillo": 1, "azul": 1},
}
const ORDEN_PIGMENTOS := ["rojo", "amarillo", "azul", "blanco"]
const DIBUJOS_MURAL := ["flor", "casa", "cohete", "pez", "mariposa", "arcoiris"]

## Zona de juego: las gotas caen dentro de AREA y el frasco recorre su parte baja.
const AREA := Rect2(250, 128, 880, 560)
const Y_APARICION := 150.0
const Y_BOCA := 520.0
const Y_SUELO := 700.0
const FRASCO_ANCHO := 140.0
const FRASCO_ALTO := 150.0
const FRASCO_MIN_X := 320.0
const FRASCO_MAX_X := 1050.0
const HUD := Rect2(404, 12, 472, 108)
const MURAL_GRANDE := Rect2(360, 118, 560, 400)
const DESTELLOS_POR_LATA := 8
const DESTELLOS_POR_MURAL := 10
const DESTELLOS_MURAL_LIMPIO := 5
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_ATRAPAR := "sfx/ui/soltar.ogg"
const SFX_BIEN := "sfx/ui/confirmar.ogg"
const SFX_PUAJ := "sfx/ui/no_es_este.ogg"
const SFX_TAPA := "sfx/ui/cerrar.ogg"
const SFX_LATA := "sfx/ui/abrir.ogg"
const SFX_ELEGIR := "sfx/ui/seleccionar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")

@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _anfitriona: TextureRect = %anfitriona
@onready var _boton_salir: Button = %boton_salir
@onready var _boton_cometa: Button = %boton_cometa
@onready var _boton_libreta: Button = %boton_libreta
@onready var _tarjeta: Control = %tarjeta_receta
@onready var _boton_listo: Button = %boton_listo
@onready var _mural: Control = %mural
@onready var _efectos: Control = %efectos
@onready var _panel_depuracion: Label = %panel_depuracion
@onready var _confeti: CPUParticles2D = %confeti

# Configuracion (del nivel)
var _paleta: Dictionary = {}
var _recetas: Dictionary = {}
var _pool: Array = []
var _pigmentos: Array = []
var _velocidad := 110.0
var _variacion := 0.0
var _simultaneas := 2
var _intervalo := 1.1
var _tam_gota := 84.0
var _prob_gris := 0.0
var _prob_util := 0.6
var _ranuras := true
var _memorizar_s := 0.0
var _numero_murales := 2
var _dibujos: Array = []
var _libreta_cuesta := true
var _umbrales: Dictionary = {}

# Estado
var _fase := "intro"  ## intro | receta | atrapar | sucio | agitar | lata | mural | fin
var _gotas: Array = []  ## {"color", "pos", "vel", "radio", "giro"}
var _salpicaduras: Array = []  ## {"pos", "color", "t"}
var _frasco_x := 690.0
var _objetivo_x := 690.0
var _presionado := false
var _ultimo_puntero := Vector2.ZERO
var _capas: Array = []  ## pigmentos atrapados, en orden
var _receta: Dictionary = {}
var _color_pedido := ""
var _agitado := 0.0
var _ultimo_sentido := 0.0
var _tapa := 0.0
var _suciedad := 0.0
var _bamboleo := 0.0
var _espera_spawn := 0.0
var _ultima_x_spawn := -1000.0
var _sin_util := 0
var _mural_idx := 0
var _dibujo_actual := "flor"
var _pedidos_mural: Array = []
var _latas: Array = []
var _mazo: Array = []
var _ultimos_hechos: Array = []
var _fallos := 0
var _fallos_mural := 0
var _murales_limpios := 0
var _revisiones := 0
var _latas_total := 0
var _datos_dichos := {}
var _tarjeta_modo := ""  ## "memorizar" | "revisar"
var _tarjeta_hasta := 0.0
var _tarjeta_total := 0.0
var _pintado_mural: Array = [0.0, 0.0, 0.0]
var _mural_visible := false
var _tiempo := 0.0
var _voz_ocupada_hasta := 0.0
var _ultima_linea := ""
var _base_anfitriona := Vector2.ZERO
var _salto_anfitriona := 0.0
var _tween_anfitriona: Tween
var _fuente: Font


func _ready() -> void:
	super._ready()
	_panel_depuracion.hide()
	_tarjeta.hide()
	_mural.hide()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_estilizar_interfaz()
	_boton_cometa.pressed.connect(_al_tocar_cometa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_boton_libreta.pressed.connect(_al_tocar_libreta)
	_boton_listo.pressed.connect(_al_tocar_listo)
	_anfitriona.mouse_filter = Control.MOUSE_FILTER_STOP
	_anfitriona.gui_input.connect(_al_tocar_anfitriona)
	_anfitriona.pivot_offset = Vector2(_anfitriona.size.x / 2.0, _anfitriona.size.y)
	_base_anfitriona = _anfitriona.position
	_juego.gui_input.connect(_al_input_juego)
	_juego.draw.connect(_dibujar_juego)
	_hud.draw.connect(_dibujar_hud)
	_tarjeta.draw.connect(_dibujar_tarjeta)
	_mural.draw.connect(_dibujar_mural_grande)
	if nivel.is_empty():
		push_error("motor_mezclar: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()
	_reproducir_voz("intro", _linea("intro"), true)
	_despues(maxf(1.2, _duracion_voz(_linea("intro")) + 0.3), _nuevo_mural)
	_actualizar_depuracion()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	_anfitriona.position.y = _base_anfitriona.y - _salto_anfitriona - (absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0)
	# El frasco sigue al dedo con suavidad; su velocidad lo inclina un poco (se ve "de verdad").
	var antes := _frasco_x
	_frasco_x = lerpf(_frasco_x, _objetivo_x, clampf(delta * 16.0, 0.0, 1.0))
	var velocidad_frasco := (_frasco_x - antes) / maxf(delta, 0.0001)
	_bamboleo = lerpf(_bamboleo, clampf(velocidad_frasco / 2200.0, -0.28, 0.28), clampf(delta * 10.0, 0.0, 1.0))
	if _fase == "atrapar":
		_mover_gotas(delta)
		_espera_spawn -= delta
		if _espera_spawn <= 0.0 and _gotas.size() < _simultaneas:
			_espera_spawn = _intervalo * randf_range(0.8, 1.2)
			_crear_gota()
	elif _fase == "sucio":
		_mover_gotas(delta)
	elif _fase == "agitar" and _presionado and absf(_ultimo_puntero.x - _frasco_x) < FRASCO_ANCHO:
		# Alternativa a sacudir: mantener presionado el frasco tambien mezcla (mas lento).
		_sumar_agitado(delta * 0.3)
	if _tarjeta.visible and _tarjeta_hasta > 0.0 and _ahora() >= _tarjeta_hasta:
		_cerrar_tarjeta()
	for s in _salpicaduras.duplicate():
		s["t"] += delta
		if s["t"] > 0.6:
			_salpicaduras.erase(s)
	_juego.queue_redraw()
	_hud.queue_redraw()
	if _tarjeta.visible:
		_tarjeta.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_F3 and not event.echo:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()
	elif event.keycode in [KEY_LEFT, KEY_RIGHT] and _fase in ["atrapar", "agitar"]:
		# PC: las flechas tambien mueven (y agitan) el frasco.
		var paso := -70.0 if event.keycode == KEY_LEFT else 70.0
		_mover_frasco_a(_objetivo_x + paso)
		if _fase == "agitar":
			_agitar_por_movimiento(paso)


# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------

func _configurar_desde_nivel() -> void:
	_paleta = PALETA.duplicate()
	_paleta.merge(nivel.get("paleta", {}), true)
	_recetas = RECETAS.duplicate(true)
	_recetas.merge(nivel.get("recetas", {}), true)
	_pool = (nivel.get("pedidos", ["verde", "naranja", "violeta"]) as Array).filter(func(c) -> bool: return _recetas.has(str(c)))
	if _pool.is_empty():
		_pool = ["verde", "naranja", "violeta"]
	_pigmentos = nivel.get("pigmentos", [])
	if _pigmentos.is_empty():
		for color in _pool:
			for pigmento in _recetas[color]:
				if not _pigmentos.has(pigmento):
					_pigmentos.append(pigmento)
	_velocidad = float(nivel.get("velocidad_caida", 110.0))
	_variacion = clampf(float(nivel.get("variacion_velocidad", 0.0)), 0.0, 0.8)
	_simultaneas = maxi(1, int(nivel.get("elementos_simultaneos", 2)))
	_intervalo = maxf(0.3, float(nivel.get("intervalo_gotas_s", 1.1)))
	_tam_gota = maxf(64.0, float(nivel.get("tamano_gota", 84.0)))
	_prob_gris = clampf(float(nivel.get("gota_distractora", {}).get("probabilidad", 0.0)), 0.0, 0.5)
	_prob_util = clampf(float(nivel.get("probabilidad_util", 0.6)), 0.2, 0.95)
	_ranuras = bool(nivel.get("ranuras_visibles", true))
	_memorizar_s = float(nivel.get("memorizar_s", 0.0))
	_numero_murales = maxi(1, int(nivel.get("murales", 2)))
	_dibujos = nivel.get("dibujos_mural", DIBUJOS_MURAL.duplicate())
	_libreta_cuesta = bool(nivel.get("libreta_cuesta_estrellita", true))
	_umbrales = nivel.get("umbrales_estrellitas", {"tres": 2, "dos": 5})
	_mazo = []


func _color(id: String) -> Color:
	return Color(str(_paleta.get(id, "#FFFFFF")))


func _gotas_de_receta(receta: Dictionary) -> int:
	var total := 0
	for pigmento in receta:
		total += int(receta[pigmento])
	return total


## Cuantas gotas de cada pigmento faltan para completar la receta actual.
func faltantes() -> Dictionary:
	var faltan := {}
	for pigmento in _receta:
		var n := int(_receta[pigmento]) - _capas.count(pigmento)
		if n > 0:
			faltan[pigmento] = n
	return faltan


# ---------------------------------------------------------------------------
# Bucle: mural -> 3 latas -> receta -> atrapar -> agitar -> lata
# ---------------------------------------------------------------------------

## Pedidos del mural: 3 colores distintos del pool (mazo barajado), sin repetir los recien hechos.
func _armar_pedidos_mural() -> Array:
	var elegidos: Array = []
	var intentos := 0
	while elegidos.size() < 3 and intentos < 40:
		intentos += 1
		if _mazo.is_empty():
			_mazo = _pool.duplicate()
			_mazo.shuffle()
		var candidato: String = _mazo.pop_front()
		var reciente := _ultimos_hechos.has(candidato) and _pool.size() > 4
		if elegidos.has(candidato) or (reciente and intentos < 30):
			_mazo.append(candidato)
			continue
		elegidos.append(candidato)
	while elegidos.size() < 3:
		elegidos.append(_pool.pick_random())
	return elegidos


func _nuevo_mural() -> void:
	if not is_inside_tree():
		return
	_fallos_mural = 0
	_latas.clear()
	_pedidos_mural = _armar_pedidos_mural()
	_dibujo_actual = str(_dibujos[_mural_idx % _dibujos.size()]) if not _dibujos.is_empty() else "flor"
	_pintado_mural = [0.0, 0.0, 0.0]
	_reaccion_anfitriona("salta")
	var ruta := _linea_al_azar("mural_pedido")
	_reproducir_voz("mural_pedido", ruta, true)
	# El HUD muestra el mural nuevo sin pintar y las 3 latas que pide Coco.
	_hud.pivot_offset = HUD.get_center()
	_hud.scale = Vector2(0.85, 0.85)
	_hud.create_tween().tween_property(_hud, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_despues(clampf(_duracion_voz(ruta), 1.0, 5.0) + 0.2, _siguiente_lata)
	_actualizar_depuracion()


func _siguiente_lata() -> void:
	if not is_inside_tree() or _fase == "fin":
		return
	_color_pedido = str(_pedidos_mural[_latas.size()])
	_receta = (_recetas[_color_pedido] as Dictionary).duplicate()
	_capas.clear()
	_agitado = 0.0
	_tapa = 0.0
	_suciedad = 0.0
	_mostrar_tarjeta("memorizar")
	_actualizar_depuracion()


func _empezar_a_atrapar() -> void:
	if _fase == "fin":
		return
	_fase = "atrapar"
	_espera_spawn = 0.3
	_sin_util = 0
	_reproducir_voz("a_atrapar", _linea_al_azar("a_atrapar"))
	_actualizar_depuracion()


func _mover_frasco_a(x: float) -> void:
	_objetivo_x = clampf(x, FRASCO_MIN_X, FRASCO_MAX_X)


# ---------------------------------------------------------------------------
# Gotas
# ---------------------------------------------------------------------------

func _crear_gota() -> void:
	var faltan := faltantes()
	var color := ""
	var forzar_util := _sin_util >= 2 and not faltan.is_empty()
	if not forzar_util and randf() < _prob_gris:
		color = "gris"
	elif forzar_util or (randf() < _prob_util and not faltan.is_empty()):
		color = str(faltan.keys().pick_random())
	else:
		color = str(_pigmentos.pick_random())
	if faltan.has(color):
		_sin_util = 0
	else:
		_sin_util += 1
	# Lejos de la gota anterior, para que se puedan distinguir y atrapar de a una.
	var x := 0.0
	for intento in 8:
		x = randf_range(AREA.position.x + 70.0, AREA.end.x - 70.0)
		if absf(x - _ultima_x_spawn) > 170.0:
			break
	_ultima_x_spawn = x
	var vel := _velocidad * (1.0 + randf_range(-_variacion, _variacion))
	_gotas.append({"color": color, "pos": Vector2(x, Y_APARICION), "vel": vel, "radio": _tam_gota * 0.5,
		"giro": randf_range(-0.12, 0.12), "nace": 0.0})


func _mover_gotas(delta: float) -> void:
	for gota in _gotas.duplicate():
		var y_antes: float = gota["pos"].y
		gota["pos"].y += gota["vel"] * delta
		gota["nace"] = minf(1.0, gota["nace"] + delta * 5.0)
		var y_ahora: float = gota["pos"].y
		var boca := Y_BOCA + 6.0
		if _fase == "atrapar" and y_antes < boca and y_ahora >= boca \
				and absf(gota["pos"].x - _frasco_x) <= FRASCO_ANCHO * 0.5 + gota["radio"] * 0.35:
			_gotas.erase(gota)
			_atrapar(str(gota["color"]))
		elif y_ahora > Y_SUELO:
			# Dejar pasar una gota nunca castiga: se aplasta en el suelo y listo.
			_gotas.erase(gota)
			_salpicaduras.append({"pos": Vector2(gota["pos"].x, Y_SUELO - 6.0), "color": _color(gota["color"]), "t": 0.0})


## Resultado de que una gota caiga dentro del frasco: "sirve", "completa" o "sucio".
func _atrapar(color: String) -> String:
	var faltan := faltantes()
	_capas.append(color)
	var centro := Vector2(_frasco_x, Y_BOCA + 20.0)
	if not faltan.has(color):
		gota_atrapada.emit(color, false)
		_ensuciar(color)
		return "sucio"
	gota_atrapada.emit(color, true)
	reproducir_sfx(SFX_ATRAPAR)
	_estallido(centro, 6, [_color(color), Color.WHITE], 0.8)
	if faltantes().is_empty():
		_receta_completa()
		return "completa"
	_reproducir_voz("bien", _linea_al_azar("bien"))
	_actualizar_depuracion()
	return "sirve"


## Gag de "¡puaj!": la mezcla se pone color barro, burbujea y el frasco se vacia. Solo se reinicia
## la lata en curso: las latas hechas y el mural nunca se pierden.
func _ensuciar(color: String) -> void:
	_fase = "sucio"
	_fallos += 1
	_fallos_mural += 1
	reproducir_sfx(SFX_PUAJ)
	_reaccion_anfitriona("rie")
	var clave := "gris" if color == "gris" and _linea("gris") != "" else "sucio"
	var ruta := _linea_al_azar(clave)
	_reproducir_voz(clave, ruta, true)
	var tween := create_tween()
	tween.tween_property(self, "_suciedad", 1.0, 0.45)
	tween.tween_interval(maxf(0.9, _duracion_voz(ruta) - 0.6))
	tween.tween_callback(_vaciar_frasco)
	tween.tween_property(self, "_suciedad", 0.0, 0.25)
	tween.tween_callback(_seguir_tras_ensuciar)
	_actualizar_depuracion()


func _vaciar_frasco() -> void:
	_estallido(Vector2(_frasco_x, Y_BOCA + 40.0), 10, [_color("sucio"), Color("#6B5B4A"), Color.WHITE], 1.0)
	_capas.clear()


func _seguir_tras_ensuciar() -> void:
	if _fase == "sucio":
		_fase = "atrapar"
		_espera_spawn = 0.4


func _receta_completa() -> void:
	_fase = "agitar"
	_agitado = 0.0
	_ultimo_sentido = 0.0
	reproducir_sfx(SFX_TAPA)
	# Las gotas que quedaban en el aire se desvanecen: ahora toca mezclar.
	for gota in _gotas:
		_salpicaduras.append({"pos": gota["pos"], "color": _color(gota["color"]), "t": 0.2})
	_gotas.clear()
	create_tween().tween_property(self, "_tapa", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reproducir_voz("a_mezclar", _linea("a_mezclar"), true)
	_actualizar_depuracion()


func _agitar_por_movimiento(dx: float) -> void:
	if _fase != "agitar":
		return
	var sentido := signf(dx)
	var avance := absf(dx) / 1500.0
	# Cambiar de sentido (sacudir de verdad) mezcla mas que arrastrar en una sola direccion.
	if sentido != 0.0 and sentido != _ultimo_sentido:
		avance += 0.035
		_ultimo_sentido = sentido
	_sumar_agitado(avance)


func _sumar_agitado(cantidad: float) -> void:
	if _fase != "agitar":
		return
	_agitado = minf(1.0, _agitado + cantidad)
	if _agitado >= 1.0:
		_mezcla_lista()


## Las capas se fundieron: sale una lata del color pedido y vuela a su lugar del pedido de Coco.
func _mezcla_lista() -> void:
	_fase = "lata"
	_latas.append(_color_pedido)
	_latas_total += 1
	_ultimos_hechos.append(_color_pedido)
	while _ultimos_hechos.size() > 2:
		_ultimos_hechos.pop_front()
	lata_lista.emit(_color_pedido)
	reproducir_sfx(SFX_LATA)
	_estallido(Vector2(_frasco_x, Y_BOCA + 50.0), 16, [_color(_color_pedido), DORADO, Color.WHITE], 1.4)
	_lata_voladora(Vector2(_frasco_x, Y_BOCA + 60.0), _centro_ranura_lata(_latas.size() - 1), _color(_color_pedido))
	_reaccion_anfitriona("salta")
	# Primera vez de un color con dato curioso: Coco lo cuenta. Si no, una celebracion corta.
	var ruta := ""
	var prefijo := _linea("prefijo_datos")
	if prefijo != "" and not _datos_dichos.has(_color_pedido) and ResourceLoader.exists(resolver_ruta_audio(prefijo + _color_pedido + ".wav")):
		_datos_dichos[_color_pedido] = true
		ruta = prefijo + _color_pedido + ".wav"
		_reproducir_voz("dato", ruta, true)
	else:
		ruta = _linea_al_azar("lata_lista")
		_reproducir_voz("lata_lista", ruta, true)
	var espera := clampf(_duracion_voz(ruta) + 0.3, 1.3, 9.0)
	_despues(espera, func() -> void:
		_capas.clear()
		_tapa = 0.0
		_agitado = 0.0
		if _latas.size() >= 3:
			_entregar_latas()
		else:
			_siguiente_lata())
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Tarjeta de receta (memorizar y revisar)
# ---------------------------------------------------------------------------

func _mostrar_tarjeta(modo: String, segundos_extra := 0.0) -> void:
	_tarjeta_modo = modo
	var previa := _fase
	_fase = "receta"
	set_meta("fase_previa", previa)
	_tarjeta.show()
	_tarjeta.pivot_offset = _tarjeta.size / 2.0
	_tarjeta.scale = Vector2(0.6, 0.6)
	_tarjeta.modulate.a = 0.0
	var tween := _tarjeta.create_tween().set_parallel(true)
	tween.tween_property(_tarjeta, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_tarjeta, "modulate:a", 1.0, 0.2)
	_boton_listo.visible = modo == "memorizar"
	var receta_voz := _voz_receta(_color_pedido)
	var duracion := _duracion_voz(receta_voz)
	if modo == "memorizar":
		_reproducir_voz("receta", receta_voz, true)
		_despues(duracion + 0.2, func() -> void:
			if _tarjeta.visible and _tarjeta_modo == "memorizar":
				_reproducir_voz("memoriza", _linea("memoriza"), true))
		# Zonas altas: la receta se ve solo un ratito (el reloj empieza cuando Coco termina de leerla).
		_tarjeta_total = _memorizar_s
		_tarjeta_hasta = _ahora() + duracion + _memorizar_s if _memorizar_s > 0.0 else 0.0
	else:
		_tarjeta_total = 0.0
		_tarjeta_hasta = _ahora() + segundos_extra + maxf(3.5, duracion + 0.5)
	_actualizar_depuracion()


func _al_tocar_listo() -> void:
	if _tarjeta.visible and _tarjeta_modo == "memorizar":
		reproducir_sfx(SFX_ELEGIR)
		_cerrar_tarjeta()


func _cerrar_tarjeta() -> void:
	if not _tarjeta.visible:
		return
	_tarjeta_hasta = 0.0
	var modo := _tarjeta_modo
	_tarjeta_modo = ""
	var destino := _boton_libreta.position + _boton_libreta.size / 2.0
	var tween := _tarjeta.create_tween().set_parallel(true)
	tween.tween_property(_tarjeta, "scale", Vector2(0.15, 0.15), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_tarjeta, "position", destino - _tarjeta.size / 2.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_tarjeta, "modulate:a", 0.0, 0.35)
	var origen := _tarjeta.position
	tween.chain().tween_callback(func() -> void:
		_tarjeta.hide()
		_tarjeta.position = origen
		_tarjeta.scale = Vector2.ONE)
	if modo == "memorizar":
		var audio := get_node_or_null("/root/Audio")
		if audio != null:
			audio.detener_voz()
		_voz_ocupada_hasta = 0.0
		_despues(0.35, _empezar_a_atrapar)
	else:
		var previa := str(get_meta("fase_previa", "atrapar"))
		_fase = previa if previa in ["atrapar", "agitar"] else "atrapar"


## Libreta: vuelve a mostrar la receta de la lata en curso. Cuesta una estrellita (sin bajar de 1).
func _al_tocar_libreta() -> void:
	if not (_fase in ["atrapar", "agitar"]) or _color_pedido == "":
		reproducir_sfx(SFX_TOQUE)
		return
	reproducir_sfx(SFX_TOQUE)
	var antes := 0.0
	if _libreta_cuesta:
		_revisiones += 1
		_estrellita_que_cae(_boton_libreta.position + Vector2(25, 25))
		var ruta := _linea("revisar")
		_reproducir_voz("revisar", ruta, true)
		antes = clampf(_duracion_voz(ruta), 0.5, 4.0) if ruta != "" else 0.0
	_mostrar_tarjeta("revisar", antes)
	_despues(antes, func() -> void:
		if _tarjeta.visible and _tarjeta_modo == "revisar":
			_reproducir_voz("receta", _voz_receta(_color_pedido), true))
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Entrega a Coco y mural
# ---------------------------------------------------------------------------

func _entregar_latas() -> void:
	_fase = "mural"
	var ruta := _linea("entregar")
	_reproducir_voz("entregar", ruta, true)
	var centro_coco := _anfitriona.position + Vector2(_anfitriona.size.x * 0.5, _anfitriona.size.y * 0.45)
	for i in 3:
		_despues(0.18 * i, func() -> void:
			_lata_voladora(_centro_ranura_lata(i), centro_coco, _color(str(_latas[i]))))
	_despues(0.9, func() -> void: _reaccion_anfitriona("salta"))
	_despues(maxf(1.3, _duracion_voz(ruta) * 0.6), _pintar_mural)


func _pintar_mural() -> void:
	_mural_visible = true
	_mural.show()
	_mural.pivot_offset = _mural.size / 2.0
	_mural.scale = Vector2(0.3, 0.3)
	_mural.modulate.a = 0.0
	var tween := _mural.create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mural, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_mural, "modulate:a", 1.0, 0.3)
	tween.set_parallel(false)
	for i in 3:
		tween.tween_interval(0.35)
		tween.tween_callback(func() -> void:
			reproducir_sfx(SFX_BIEN)
			var c := MURAL_GRANDE.position + _centro_region(_dibujo_actual, i) * MURAL_GRANDE.size
			_estallido(c, 12, [_color(str(_latas[i])), Color.WHITE, DORADO], 1.4))
		tween.tween_method(func(v: float) -> void:
			_pintado_mural[i] = v
			_mural.queue_redraw()
			_hud.queue_redraw()
		, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_mural_terminado)


func _mural_terminado() -> void:
	_confeti.restart()
	_reaccion_anfitriona("baila")
	if _fallos_mural == 0:
		_murales_limpios += 1
	mural_terminado.emit(_mural_idx)
	_mural_idx += 1
	var ruta := _linea_al_azar("mural_listo")
	_reproducir_voz("mural_listo", ruta, true)
	var espera := clampf(_duracion_voz(ruta) + 0.8, 2.5, 7.0)
	_despues(espera, func() -> void:
		var tween := _mural.create_tween().set_parallel(true)
		tween.tween_property(_mural, "scale", Vector2(0.4, 0.4), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_mural, "modulate:a", 0.0, 0.35)
		tween.chain().tween_callback(func() -> void:
			_mural.hide()
			_mural_visible = false
			if _mural_idx >= _numero_murales:
				_celebrar_victoria()
			else:
				_nuevo_mural()))
	_actualizar_depuracion()


func _celebrar_victoria() -> void:
	if _fase == "fin":
		return
	_fase = "fin"
	_confeti.restart()
	_reaccion_anfitriona("baila")
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	celebrar(_calcular_destellos(), _calcular_estrellitas(), _linea_al_azar("victoria_final"))


func _calcular_estrellitas() -> int:
	var base := 1
	if _fallos <= int(_umbrales.get("tres", 2)):
		base = 3
	elif _fallos <= int(_umbrales.get("dos", 5)):
		base = 2
	return maxi(1, base - _revisiones)


func _calcular_destellos() -> int:
	return _latas_total * DESTELLOS_POR_LATA + _mural_idx * DESTELLOS_POR_MURAL + _murales_limpios * DESTELLOS_MURAL_LIMPIO


# ---------------------------------------------------------------------------
# Entrada: un solo camino para tactil y mouse (arrastrar o tocar donde ir)
# ---------------------------------------------------------------------------

func _al_input_juego(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_presionado = evento.pressed
		_ultimo_puntero = evento.position
		if evento.pressed and _fase in ["atrapar", "sucio", "agitar"]:
			_mover_frasco_a(evento.position.x)
		_juego.accept_event()
	elif evento is InputEventMouseMotion and _presionado:
		var dx: float = evento.position.x - _ultimo_puntero.x
		_ultimo_puntero = evento.position
		if _fase in ["atrapar", "sucio", "agitar"]:
			_mover_frasco_a(evento.position.x)
		if _fase == "agitar":
			_agitar_por_movimiento(dx)
		_juego.accept_event()


func _al_tocar_cometa() -> void:
	reproducir_sfx(SFX_TOQUE)
	var clave := "pista_agitar" if _fase == "agitar" and _linea("pista_agitar") != "" else "pista"
	_reproducir_voz(clave, _linea(clave), true)


func _al_tocar_anfitriona(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	reproducir_sfx(SFX_TOQUE)
	_reaccion_anfitriona("salta")
	_reproducir_voz("intro", _linea("intro"), true)


# ---------------------------------------------------------------------------
# API para el arnes QA (juega sin tocar la pantalla)
# ---------------------------------------------------------------------------

func fase() -> String:
	return _fase


func color_pedido() -> String:
	return _color_pedido


func receta_actual() -> Dictionary:
	return _receta.duplicate()


func pedidos_mural() -> Array:
	return _pedidos_mural.duplicate()


func latas() -> Array:
	return _latas.duplicate()


func murales_hechos() -> int:
	return _mural_idx


func fallos() -> int:
	return _fallos


func revisiones() -> int:
	return _revisiones


func gotas_en_pantalla() -> Array:
	return _gotas.duplicate(true)


func tarjeta_visible() -> bool:
	return _tarjeta.visible


func frasco_x() -> float:
	return _frasco_x


func confirmar_receta() -> void:
	_al_tocar_listo()


func tocar_libreta() -> void:
	_al_tocar_libreta()


## Simula que una gota de `color` cae dentro del frasco. Devuelve "sirve", "completa", "sucio" o "".
func atrapar_color(color: String) -> String:
	if _fase != "atrapar":
		return ""
	return _atrapar(color)


func agitar(cantidad: float) -> void:
	_sumar_agitado(cantidad)


func estrellitas_calculadas() -> int:
	return _calcular_estrellitas()


func destellos_calculados() -> int:
	return _calcular_destellos()


# ---------------------------------------------------------------------------
# Dibujo: gotas, frasco, HUD, tarjeta y mural
# ---------------------------------------------------------------------------

func _dibujar_juego() -> void:
	# Estante del frasco: una repisa suave que marca por donde se mueve.
	var repisa := Rect2(AREA.position.x + 20.0, Y_BOCA + FRASCO_ALTO + 4.0, AREA.size.x - 40.0, 16.0)
	_dibujar_caja(_juego, repisa, Color(CREMA, 0.55), 8, Color(COLOR_CONTORNO, 0.35), 3)
	for s in _salpicaduras:
		var t: float = s["t"] / 0.6
		var color: Color = s["color"]
		color.a = 1.0 - t
		for k in 5:
			var angulo := PI + PI * (k + 0.5) / 5.0
			_juego.draw_circle(s["pos"] + Vector2.from_angle(angulo) * (10.0 + 34.0 * t), 7.0 * (1.0 - t * 0.6), color)
	for gota in _gotas:
		var radio: float = gota["radio"] * (0.4 + 0.6 * gota["nace"])
		var es_gris: bool = gota["color"] == "gris"
		Figura.dibujar(_juego, "gota", _color(gota["color"]), gota["pos"], radio, true, not es_gris)
		if es_gris:
			# La gris tiene carita de dormida y una nubecita: se nota que "no tiene color".
			_juego.draw_circle(gota["pos"] + Vector2(radio * 0.9, -radio * 1.1), radio * 0.22, Color(1, 1, 1, 0.8))
			_juego.draw_circle(gota["pos"] + Vector2(radio * 1.2, -radio * 1.35), radio * 0.14, Color(1, 1, 1, 0.8))
	_dibujar_frasco(_juego, Vector2(_frasco_x, Y_BOCA), _bamboleo + _sacudida())
	if _fase == "agitar":
		_dibujar_flechas_agitar(_juego, Vector2(_frasco_x, Y_BOCA + FRASCO_ALTO * 0.5))


func _sacudida() -> float:
	if _fase == "sucio":
		return sin(_tiempo * 40.0) * 0.06 * _suciedad
	return 0.0


## Frasco de vidrio con capas de pintura (una por gota) que al agitar se funden en el color final.
func _dibujar_frasco(lienzo: Control, boca: Vector2, giro: float) -> void:
	var ancho := FRASCO_ANCHO
	var alto := FRASCO_ALTO
	var xf := Transform2D(giro, boca + Vector2(0, alto)) # pivote en la base
	lienzo.draw_set_transform_matrix(xf)
	var cuerpo := Rect2(-ancho * 0.5, -alto, ancho, alto)
	# Sombra
	lienzo.draw_colored_polygon(Figura._elipse(Vector2(0, 4), ancho * 0.55, 12.0), Color(COLOR_CONTORNO, 0.18))
	# Vidrio (fondo)
	_dibujar_caja(lienzo, cuerpo, Color(1, 1, 1, 0.35), 30, COLOR_CONTORNO, 0)
	# Pintura
	var total := maxi(_gotas_de_receta(_receta), 2)
	var interior := cuerpo.grow(-9.0)
	var alto_capa := (interior.size.y - 14.0) / float(total)
	var final := _color(_color_pedido) if _color_pedido != "" else Color.WHITE
	var ondas := sin(_tiempo * 3.0) * 3.0
	for k in _capas.size():
		var color := _color(str(_capas[k]))
		color = color.lerp(final, clampf(_agitado * 1.2, 0.0, 1.0)) if _fase in ["agitar", "lata"] else color
		color = color.lerp(_color("sucio"), _suciedad)
		var y1 := interior.end.y - alto_capa * (k + 1)
		var capa := Rect2(interior.position.x, y1, interior.size.x, interior.end.y - y1 if k == 0 else alto_capa + 2.0)
		if k == 0:
			_dibujar_caja(lienzo, capa, color, 22, Color.TRANSPARENT, 0)
		else:
			lienzo.draw_rect(Rect2(capa.position.x, capa.position.y, capa.size.x, alto_capa + 4.0), color)
	if not _capas.is_empty():
		var tope := interior.end.y - alto_capa * _capas.size()
		var ultimo := _color(str(_capas[-1])).lerp(final, clampf(_agitado * 1.2, 0.0, 1.0) if _fase in ["agitar", "lata"] else 0.0).lerp(_color("sucio"), _suciedad)
		var superficie := PackedVector2Array()
		for i in 13:
			var x := interior.position.x + interior.size.x * i / 12.0
			superficie.append(Vector2(x, tope + sin(i * 0.9 + _tiempo * 4.0) * (2.0 + _agitado * 5.0) + ondas * 0.3))
		superficie.append(Vector2(interior.end.x, tope + 8.0))
		superficie.append(Vector2(interior.position.x, tope + 8.0))
		lienzo.draw_colored_polygon(superficie, ultimo)
	# Burbujas del "puaj"
	if _suciedad > 0.05:
		for k in 6:
			var ciclo := fmod(_tiempo * 1.6 + k * 0.37, 1.0)
			var p := Vector2(interior.position.x + 18.0 + fmod(k * 23.0, interior.size.x - 30.0), interior.end.y - ciclo * interior.size.y)
			lienzo.draw_arc(p, 6.0 + k % 3 * 2.0, 0.0, TAU, 14, Color(1, 1, 1, 0.8 * _suciedad), 2.5, true)
	# Brillos del vidrio y contorno
	lienzo.draw_rect(Rect2(cuerpo.position.x + 14.0, cuerpo.position.y + 18.0, 12.0, alto * 0.62), Color(1, 1, 1, 0.55))
	lienzo.draw_rect(Rect2(cuerpo.position.x + 32.0, cuerpo.position.y + 18.0, 5.0, alto * 0.4), Color(1, 1, 1, 0.45))
	_dibujar_caja(lienzo, cuerpo, Color.TRANSPARENT, 30, COLOR_CONTORNO, 6)
	# Boca (aro) o tapa
	var aro := Rect2(-ancho * 0.56, -alto - 12.0, ancho * 1.12, 22.0)
	_dibujar_caja(lienzo, aro, Color("#DDF4FF"), 11, COLOR_CONTORNO, 5)
	if _tapa > 0.01:
		var alto_tapa := 30.0 * _tapa
		var tapa := Rect2(-ancho * 0.6, -alto - 12.0 - alto_tapa, ancho * 1.2, alto_tapa + 14.0)
		_dibujar_caja(lienzo, tapa, Color("#FF7AA8"), 14, COLOR_CONTORNO, 5)
		lienzo.draw_circle(Vector2(0, tapa.position.y + 2.0), 11.0 * _tapa, Color("#FF7AA8"))
		lienzo.draw_arc(Vector2(0, tapa.position.y + 2.0), 11.0 * _tapa, PI, TAU, 16, COLOR_CONTORNO, 4.0, true)
	# Etiqueta con ranuras: una por gota de la receta (en zonas altas solo se ven las ya atrapadas).
	var n := _gotas_de_receta(_receta)
	if n > 0 and _fase != "lata":
		var visibles := n if _ranuras else _capas.size()
		if visibles > 0:
			var paso := 30.0
			var ancho_etq := paso * visibles + 14.0
			var etiqueta := Rect2(-ancho_etq * 0.5, -alto * 0.52, ancho_etq, 38.0)
			_dibujar_caja(lienzo, etiqueta, CREMA, 12, COLOR_CONTORNO, 4)
			for k in visibles:
				var c := Vector2(etiqueta.position.x + 7.0 + paso * (k + 0.5), etiqueta.get_center().y)
				if k < _capas.size():
					var color := _color(str(_capas[k])).lerp(_color("sucio"), _suciedad)
					lienzo.draw_circle(c, 11.0, color)
					lienzo.draw_arc(c, 11.0, 0.0, TAU, 18, COLOR_CONTORNO, 2.5, true)
				else:
					lienzo.draw_arc(c, 10.0, 0.0, TAU, 18, Color(COLOR_CONTORNO, 0.45), 2.5, true)
	# Medidor de mezcla (arco alrededor del frasco)
	if _fase == "agitar":
		var centro := Vector2(0, -alto * 0.5)
		lienzo.draw_arc(centro, alto * 0.72, -PI * 0.5, PI * 1.5, 48, Color(1, 1, 1, 0.45), 12.0, true)
		lienzo.draw_arc(centro, alto * 0.72, -PI * 0.5, -PI * 0.5 + TAU * _agitado, 48, DORADO, 12.0, true)
	lienzo.draw_set_transform_matrix(Transform2D.IDENTITY)


func _dibujar_flechas_agitar(lienzo: Control, centro: Vector2) -> void:
	var pulso := 1.0 + sin(_tiempo * 8.0) * 0.12
	for lado in [-1.0, 1.0]:
		var base := centro + Vector2(lado * (FRASCO_ANCHO * 0.5 + 70.0 + sin(_tiempo * 8.0) * 8.0), 0)
		var puntos := PackedVector2Array()
		for p in [Vector2(-10, -16), Vector2(8, -16), Vector2(8, -30), Vector2(34, 0), Vector2(8, 30), Vector2(8, 16), Vector2(-10, 16)]:
			puntos.append(base + Vector2(p.x * lado, p.y) * pulso)
		lienzo.draw_colored_polygon(puntos, DORADO)
		Figura.contornear(lienzo, puntos, 4.0)


## Lata de pintura con asa, tapa y chorrito del color.
func _dibujar_lata(lienzo: CanvasItem, centro: Vector2, alto: float, color: Color, llena := true) -> void:
	var ancho := alto * 0.86
	var cuerpo := Rect2(centro.x - ancho * 0.5, centro.y - alto * 0.38, ancho, alto * 0.8)
	lienzo.draw_arc(Vector2(centro.x, cuerpo.position.y), ancho * 0.36, PI, TAU, 16, COLOR_CONTORNO, maxf(2.0, alto * 0.05), true)
	var metal := Color("#DCE3F0") if llena else Color(1, 1, 1, 0.5)
	_dibujar_caja(lienzo, cuerpo, metal, int(alto * 0.12), COLOR_CONTORNO, maxi(2, int(alto * 0.06)))
	var banda := Rect2(cuerpo.position.x, cuerpo.position.y + alto * 0.2, ancho, alto * 0.36)
	if llena:
		lienzo.draw_rect(banda, color)
		lienzo.draw_rect(Rect2(banda.position.x + ancho * 0.12, banda.position.y + 3.0, ancho * 0.1, banda.size.y - 6.0), Color(1, 1, 1, 0.45))
	else:
		# Lata pendiente: el color pedido se ve claro (Sofia necesita saber que esta fabricando),
		# pero la lata es de vidrio vacio y sin estrellita.
		lienzo.draw_rect(banda, Color(color, 0.85))
	lienzo.draw_line(banda.position, banda.position + Vector2(ancho, 0), COLOR_CONTORNO, maxf(1.5, alto * 0.035))
	lienzo.draw_line(banda.end - Vector2(ancho, 0), banda.end, COLOR_CONTORNO, maxf(1.5, alto * 0.035))
	var tapa := Rect2(cuerpo.position.x - 3.0, cuerpo.position.y - alto * 0.08, ancho + 6.0, alto * 0.13)
	_dibujar_caja(lienzo, tapa, color if llena else Color(1, 1, 1, 0.6), int(alto * 0.06), COLOR_CONTORNO, maxi(2, int(alto * 0.05)))
	if llena:
		var chorro := PackedVector2Array([tapa.position + Vector2(ancho * 0.62, tapa.size.y), tapa.position + Vector2(ancho * 0.84, tapa.size.y),
			tapa.position + Vector2(ancho * 0.84, tapa.size.y + alto * 0.2), tapa.position + Vector2(ancho * 0.73, tapa.size.y + alto * 0.26),
			tapa.position + Vector2(ancho * 0.62, tapa.size.y + alto * 0.16)])
		lienzo.draw_colored_polygon(chorro, color)


func _centro_ranura_lata(i: int) -> Vector2:
	return HUD.position + Vector2(206.0 + i * 88.0, HUD.size.y * 0.5)


func _dibujar_hud() -> void:
	if _pedidos_mural.is_empty():
		return
	_dibujar_caja(_hud, HUD, Color(0.23, 0.16, 0.42, 0.62), 30, Color(1, 1, 1, 0.5), 3)
	# Mural en miniatura: se pinta al entregar las latas.
	var mini := Rect2(HUD.position + Vector2(14, 10), Vector2(128, HUD.size.y - 20))
	_dibujar_mural(_hud, mini, _dibujo_actual, _colores_mural(), _pintado_mural)
	# Las 3 latas que pide Coco: hechas (llenas), la actual (salta) y las que faltan (suaves).
	for i in 3:
		var centro := _centro_ranura_lata(i)
		var hecha := i < _latas.size()
		var actual := i == _latas.size() and _fase in ["receta", "atrapar", "sucio", "agitar"]
		if actual:
			centro.y += -4.0 + sin(_tiempo * 5.0) * 4.0
			_hud.draw_circle(centro, 42.0, Color(DORADO, 0.35 + 0.2 * sin(_tiempo * 5.0)))
		_dibujar_lata(_hud, centro, 70.0, _color(str(_pedidos_mural[i])), hecha)
		if hecha:
			Figura.dibujar(_hud, "estrella", DORADO, centro + Vector2(28, -30), 13.0, false)
	# Murales del nivel: una estrellita por mural (llena si ya se pinto).
	for k in _numero_murales:
		var p := HUD.position + Vector2(HUD.size.x - 24.0, 24.0 + k * 30.0)
		Figura.dibujar(_hud, "estrella", DORADO if k < _mural_idx else Color(1, 1, 1, 0.35), p, 11.0, false)


func _colores_mural() -> Array:
	var colores: Array = []
	for i in 3:
		colores.append(_color(str(_pedidos_mural[i])) if i < _pedidos_mural.size() else Color.WHITE)
	return colores


func _dibujar_mural_grande() -> void:
	var local := Rect2(Vector2.ZERO, _mural.size)
	_dibujar_caja(_mural, local.grow(10.0), Color("#F7E3C4"), 30, COLOR_CONTORNO, 6)
	_dibujar_mural(_mural, local.grow(-14.0), _dibujo_actual, _colores_mural(), _pintado_mural)


## Tarjeta de receta: lata del color pedido = gotas agrupadas por pigmento (se ve cuantas de cada
## una sin leer numeros). En zonas altas un solcito se va poniendo mientras queda a la vista.
func _dibujar_tarjeta() -> void:
	if _color_pedido == "":
		return
	var lado := _tarjeta.size
	_dibujar_caja(_tarjeta, Rect2(Vector2.ZERO, lado), CREMA, 40, COLOR_CONTORNO, 6)
	var centro_y := lado.y * 0.42
	_dibujar_lata(_tarjeta, Vector2(92, centro_y), 120.0, _color(_color_pedido), true)
	# Signo "=" grande
	for k in 2:
		_dibujar_caja(_tarjeta, Rect2(166, centro_y - 18.0 + k * 24.0, 40, 12), COLOR_CONTORNO, 6, Color.TRANSPARENT, 0)
	# Gotas agrupadas por pigmento y centradas en el espacio a la derecha del "=".
	var grupos: Array = ORDEN_PIGMENTOS.filter(func(p) -> bool: return _receta.has(p))
	var paso := 70.0 if _gotas_de_receta(_receta) <= 3 else 60.0
	var ancho_total := _gotas_de_receta(_receta) * paso + (grupos.size() - 1) * 50.0
	var x := 222.0 + maxf(0.0, (lado.x - 240.0 - ancho_total) / 2.0)
	for g in grupos.size():
		if g > 0:
			_dibujar_mas(_tarjeta, Vector2(x + 25.0, centro_y + 6.0))
			x += 50.0
		for k in int(_receta[grupos[g]]):
			Figura.dibujar(_tarjeta, "gota", _color(grupos[g]), Vector2(x + paso * 0.5, centro_y + 12.0), 32.0, true, true)
			x += paso
	# Solcito que se pone (solo al memorizar con tiempo)
	if _tarjeta_modo == "memorizar" and _tarjeta_total > 0.0 and _tarjeta_hasta > 0.0:
		var queda := clampf((_tarjeta_hasta - _ahora()) / _tarjeta_total, 0.0, 1.0)
		var sol := Vector2(lado.x - 44.0, 44.0)
		_tarjeta.draw_circle(sol, 24.0, Color(DORADO, 0.3))
		_tarjeta.draw_arc(sol, 17.0, -PI * 0.5, -PI * 0.5 + TAU * queda, 32, DORADO, 14.0, true)
		_tarjeta.draw_arc(sol, 24.0, 0.0, TAU, 32, COLOR_CONTORNO, 3.0, true)
	elif _tarjeta_modo == "revisar":
		# Libreta: marca que esta vez costo una estrellita.
		Figura.dibujar(_tarjeta, "estrella", DORADO, Vector2(lado.x - 40.0, 40.0), 20.0, false)


func _dibujar_mas(lienzo: CanvasItem, centro: Vector2) -> void:
	lienzo.draw_rect(Rect2(centro.x - 14.0, centro.y - 4.0, 28.0, 8.0), COLOR_CONTORNO)
	lienzo.draw_rect(Rect2(centro.x - 4.0, centro.y - 14.0, 8.0, 28.0), COLOR_CONTORNO)


## Centro de cada region del mural (0..1 del rectangulo), para chispas y animaciones.
func _centro_region(dibujo: String, i: int) -> Vector2:
	var centros := {
		"flor": [Vector2(0.5, 0.36), Vector2(0.5, 0.36), Vector2(0.5, 0.8)],
		"casa": [Vector2(0.5, 0.66), Vector2(0.5, 0.3), Vector2(0.5, 0.75)],
		"cohete": [Vector2(0.5, 0.48), Vector2(0.5, 0.2), Vector2(0.5, 0.86)],
		"pez": [Vector2(0.45, 0.5), Vector2(0.82, 0.5), Vector2(0.44, 0.24)],
		"mariposa": [Vector2(0.5, 0.32), Vector2(0.5, 0.7), Vector2(0.5, 0.5)],
		"arcoiris": [Vector2(0.5, 0.3), Vector2(0.5, 0.45), Vector2(0.5, 0.6)],
	}
	return (centros.get(dibujo, centros["flor"]) as Array)[i]


## Mural de 3 regiones sobre una pared de ladrillos. Region sin pintar: blanca con un fantasma del
## color que necesita; pintada: el color de la lata (se "rellena" de abajo hacia arriba).
func _dibujar_mural(lienzo: CanvasItem, rect: Rect2, dibujo: String, colores: Array, pintado: Array) -> void:
	_dibujar_caja(lienzo, rect, Color("#FFF1DD"), int(minf(rect.size.x, rect.size.y) * 0.12), COLOR_CONTORNO, 3)
	var fila := rect.size.y / 5.0
	for f in range(1, 5):
		var y := rect.position.y + fila * f
		lienzo.draw_line(Vector2(rect.position.x + 4.0, y), Vector2(rect.end.x - 4.0, y), Color("#E9CFAE"), maxf(1.0, rect.size.y * 0.012))
	var p := func(x: float, y: float) -> Vector2: return rect.position + Vector2(x, y) * rect.size
	var escala := minf(rect.size.x, rect.size.y)
	var trazo := maxf(2.0, escala * 0.022)
	var regiones: Array = [[], [], []]  # por region: lista de poligonos
	match dibujo:
		"casa":
			regiones[0].append(_rect_poly(Rect2(p.call(0.24, 0.46), rect.size * Vector2(0.52, 0.42))))
			regiones[1].append(PackedVector2Array([p.call(0.16, 0.48), p.call(0.5, 0.14), p.call(0.84, 0.48)]))
			regiones[2].append(_rect_poly(Rect2(p.call(0.43, 0.64), rect.size * Vector2(0.14, 0.24))))
			regiones[2].append(_rect_poly(Rect2(p.call(0.29, 0.54), rect.size * Vector2(0.1, 0.1))))
			regiones[2].append(_rect_poly(Rect2(p.call(0.61, 0.54), rect.size * Vector2(0.1, 0.1))))
		"cohete":
			regiones[0].append(Figura._elipse(p.call(0.5, 0.5), rect.size.x * 0.13, rect.size.y * 0.3))
			regiones[1].append(PackedVector2Array([p.call(0.4, 0.28), p.call(0.5, 0.06), p.call(0.6, 0.28)]))
			regiones[1].append(PackedVector2Array([p.call(0.38, 0.62), p.call(0.26, 0.82), p.call(0.4, 0.76)]))
			regiones[1].append(PackedVector2Array([p.call(0.62, 0.62), p.call(0.74, 0.82), p.call(0.6, 0.76)]))
			regiones[2].append(PackedVector2Array([p.call(0.43, 0.8), p.call(0.5, 0.96), p.call(0.57, 0.8)]))
		"pez":
			regiones[0].append(Figura._elipse(p.call(0.44, 0.52), rect.size.x * 0.28, rect.size.y * 0.24))
			regiones[1].append(PackedVector2Array([p.call(0.7, 0.52), p.call(0.92, 0.3), p.call(0.92, 0.74)]))
			# Aleta de arriba y burbujas grandes: la tercera lata tambien se luce.
			regiones[2].append(PackedVector2Array([p.call(0.3, 0.33), p.call(0.44, 0.12), p.call(0.58, 0.33)]))
			regiones[2].append(Figura._elipse(p.call(0.1, 0.34), escala * 0.08, escala * 0.08))
			regiones[2].append(Figura._elipse(p.call(0.16, 0.14), escala * 0.06, escala * 0.06))
		"mariposa":
			regiones[0].append(Figura._elipse(p.call(0.33, 0.34), rect.size.x * 0.16, rect.size.y * 0.2))
			regiones[0].append(Figura._elipse(p.call(0.67, 0.34), rect.size.x * 0.16, rect.size.y * 0.2))
			regiones[1].append(Figura._elipse(p.call(0.36, 0.68), rect.size.x * 0.12, rect.size.y * 0.15))
			regiones[1].append(Figura._elipse(p.call(0.64, 0.68), rect.size.x * 0.12, rect.size.y * 0.15))
			regiones[2].append(Figura._elipse(p.call(0.5, 0.5), rect.size.x * 0.045, rect.size.y * 0.32))
		"arcoiris":
			for i in 3:
				var radio_ext := rect.size.x * (0.4 - i * 0.09)
				var banda := PackedVector2Array()
				for k in 25:
					banda.append(p.call(0.5, 0.86) + Vector2.from_angle(PI + PI * k / 24.0) * radio_ext)
				for k in range(24, -1, -1):
					banda.append(p.call(0.5, 0.86) + Vector2.from_angle(PI + PI * k / 24.0) * (radio_ext - rect.size.x * 0.085))
				regiones[i].append(banda)
		_:
			# flor
			for k in 6:
				regiones[0].append(Figura._elipse(p.call(0.5, 0.36) + Vector2.from_angle(TAU * k / 6.0) * escala * 0.19, escala * 0.12, escala * 0.12))
			regiones[1].append(Figura._elipse(p.call(0.5, 0.36), escala * 0.12, escala * 0.12))
			regiones[2].append(_rect_poly(Rect2(p.call(0.485, 0.52), Vector2(rect.size.x * 0.03, rect.size.y * 0.4))))
			regiones[2].append(Figura._elipse(p.call(0.4, 0.74), escala * 0.1, escala * 0.05))
			regiones[2].append(Figura._elipse(p.call(0.6, 0.68), escala * 0.1, escala * 0.05))
	# Flor (tallo) y pez (aleta) dibujan la region 2 detras de las demas.
	var orden := [2, 0, 1] if dibujo in ["flor", "pez"] else [0, 1, 2]
	for i in orden:
		var color: Color = colores[i]
		var avance: float = float(pintado[i])
		for forma in regiones[i]:
			lienzo.draw_colored_polygon(forma, Color.WHITE)
			lienzo.draw_colored_polygon(forma, Color(color, 0.22))
			if avance > 0.0:
				var caja := _limites(forma)
				var corte := _rect_poly(Rect2(caja.position.x - 2.0, caja.end.y - caja.size.y * avance, caja.size.x + 4.0, caja.size.y * avance + 2.0))
				for trozo in Geometry2D.intersect_polygons(forma, corte):
					if trozo.size() >= 3:
						lienzo.draw_colored_polygon(trozo, color)
			Figura.contornear(lienzo, forma, trazo)
	if dibujo == "flor" or dibujo == "pez":
		var ojo: Vector2 = p.call(0.5, 0.36) if dibujo == "flor" else p.call(0.32, 0.46)
		Figura.dibujar_cara(lienzo, ojo, escala * (0.16 if dibujo == "flor" else 0.2), float(pintado[1]) >= 1.0)


func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _limites(forma: PackedVector2Array) -> Rect2:
	var caja := Rect2(forma[0], Vector2.ZERO)
	for punto in forma:
		caja = caja.expand(punto)
	return caja


func _dibujar_caja(lienzo: CanvasItem, rect: Rect2, fondo: Color, radio: int, borde: Color, grosor: int) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.draw_center = fondo.a > 0.0
	caja.border_color = borde
	caja.set_border_width_all(grosor)
	caja.set_corner_radius_all(radio)
	caja.anti_aliasing = true
	lienzo.draw_style_box(caja, rect)


# ---------------------------------------------------------------------------
# Voz, anfitriona y efectos
# ---------------------------------------------------------------------------

func _ahora() -> float:
	return Time.get_ticks_msec() / 1000.0


func _linea(clave: String) -> String:
	var valor = nivel.get("lineas_voz", {}).get(clave, "")
	if valor is Array:
		return str(valor[0]) if not valor.is_empty() else ""
	return str(valor)


## Elige una variante sin repetir la ultima, para que no suene monotono.
func _linea_al_azar(clave: String) -> String:
	var opciones = nivel.get("lineas_voz", {}).get(clave, [])
	if not (opciones is Array):
		return str(opciones)
	if opciones.is_empty():
		return ""
	var elegida := str(opciones[randi() % opciones.size()])
	if elegida == _ultima_linea and opciones.size() > 1:
		elegida = str(opciones[(opciones.find(elegida) + 1) % opciones.size()])
	_ultima_linea = elegida
	return elegida


func _voz_receta(color: String) -> String:
	var prefijo := _linea("prefijo_recetas")
	return prefijo + color + ".wav" if prefijo != "" else ""


## Las voces cortas nunca cortan una importante (intro, receta, dato curioso, gag).
func _reproducir_voz(clave: String, ruta: String, importante := false) -> void:
	if ruta == "":
		return
	var ahora := _ahora()
	if not importante and ahora < _voz_ocupada_hasta:
		return
	print("[voz:%s] %s" % [clave, ruta])
	reproducir_voz(ruta)
	if importante:
		_voz_ocupada_hasta = ahora + _duracion_voz(ruta)


func _duracion_voz(ruta: String) -> float:
	var final := resolver_ruta_audio(ruta)
	if final == "" or not ResourceLoader.exists(final):
		return 0.8
	var stream := load(final) as AudioStream
	return stream.get_length() if stream != null else 0.8


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()


func _reaccion_anfitriona(tipo: String) -> void:
	if _tween_anfitriona != null and _tween_anfitriona.is_valid():
		_tween_anfitriona.kill()
	_anfitriona.rotation = 0.0
	_anfitriona.scale = Vector2.ONE
	_salto_anfitriona = 0.0
	var tween := create_tween()
	_tween_anfitriona = tween
	match tipo:
		"salta":
			tween.tween_property(_anfitriona, "scale", Vector2(1.08, 0.9), 0.08)
			tween.tween_property(self, "_salto_anfitriona", 46.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_anfitriona, "scale", Vector2(0.94, 1.08), 0.18)
			tween.tween_property(self, "_salto_anfitriona", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_anfitriona, "scale", Vector2.ONE, 0.3)
		"rie":
			for i in 6:
				tween.tween_property(self, "_salto_anfitriona", 20.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(_anfitriona, "rotation", deg_to_rad(-7.0 if i % 2 == 0 else 7.0), 0.1)
				tween.tween_property(self, "_salto_anfitriona", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(_anfitriona, "rotation", 0.0, 0.1)
		"baila":
			for i in 6:
				tween.tween_property(self, "_salto_anfitriona", 36.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(_anfitriona, "rotation", deg_to_rad(-9.0 if i % 2 == 0 else 9.0), 0.16)
				tween.tween_property(self, "_salto_anfitriona", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(_anfitriona, "rotation", 0.0, 0.12)


func _estallido(centro: Vector2, cantidad: int, colores: Array, escala := 1.0) -> void:
	for i in cantidad:
		var chispa := Figura.new()
		chispa.figura = "estrella" if i % 3 != 2 else "gota"
		chispa.con_cara = false
		chispa.color = colores[i % colores.size()]
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(20.0, 34.0) * escala
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.position = centro - chispa.size / 2.0
		var angulo := TAU * i / cantidad + randf_range(-0.3, 0.3)
		var destino := chispa.position + Vector2.from_angle(angulo) * randf_range(60.0, 110.0) * escala
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 0.55)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


func _lata_voladora(desde: Vector2, hasta: Vector2, color: Color) -> void:
	var lata := Control.new()
	lata.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lata.size = Vector2(90, 90)
	lata.pivot_offset = lata.size / 2.0
	_efectos.add_child(lata)
	lata.position = desde - lata.size / 2.0
	lata.draw.connect(func() -> void: _dibujar_lata(lata, lata.size / 2.0, 70.0, color, true))
	var medio := (desde + hasta) / 2.0 + Vector2(0, -140)
	var tween := lata.create_tween()
	tween.tween_method(func(t: float) -> void:
		var q := desde.lerp(medio, t).lerp(medio.lerp(hasta, t), t)
		lata.position = q - lata.size / 2.0
		lata.rotation = sin(t * PI) * 0.5
	, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(lata, "scale", Vector2(1.25, 0.8), 0.08)
	tween.tween_property(lata, "scale", Vector2.ZERO, 0.18)
	tween.tween_callback(lata.queue_free)


func _estrellita_que_cae(desde: Vector2) -> void:
	var estrella := Figura.new()
	estrella.figura = "estrella"
	estrella.con_cara = false
	estrella.color = DORADO
	estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estrella.size = Vector2.ONE * 46.0
	estrella.pivot_offset = estrella.size / 2.0
	_efectos.add_child(estrella)
	estrella.position = desde
	var tween := estrella.create_tween().set_parallel(true)
	tween.tween_property(estrella, "position:y", estrella.position.y + 90.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(estrella, "rotation", 1.6, 0.9)
	tween.tween_property(estrella, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(estrella.queue_free)


# ---------------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------------

func _estilizar_interfaz() -> void:
	_estilizar_boton(_boton_salir, CREMA)
	_estilizar_boton(_boton_cometa, Color("#CFF5F1"))
	_estilizar_boton(_boton_libreta, Color("#FFE9A8"))
	_estilizar_boton(_boton_listo, TURQUESA)
	_icono(_boton_salir, _dibujar_flecha)
	_icono(_boton_libreta, _dibujar_icono_libreta)
	_icono(_boton_listo, _dibujar_visto)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(COLOR_CONTORNO, 0.85)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(12)
	_panel_depuracion.add_theme_stylebox_override("normal", panel)
	_panel_depuracion.add_theme_color_override("font_color", CREMA)
	if _fuente != null:
		_panel_depuracion.add_theme_font_override("font", _fuente)
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
		caja.set_corner_radius_all(64)
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


## Libreta de recetas con una gota y una estrellita (recordar que cuesta una).
func _dibujar_icono_libreta(icono: Control) -> void:
	var c := icono.size / 2.0
	var hoja := Rect2(c + Vector2(-24, -28), Vector2(46, 56))
	_dibujar_caja(icono, hoja, CREMA, 8, COLOR_CONTORNO, 4)
	for k in 3:
		icono.draw_circle(Vector2(hoja.position.x, hoja.position.y + 12.0 + k * 16.0), 4.0, COLOR_CONTORNO)
	Figura.dibujar(icono, "gota", Color("#4DBE55"), c + Vector2(0, 4), 14.0, false)
	Figura.dibujar(icono, "estrella", DORADO, c + Vector2(24, -26), 12.0, false)


func _dibujar_visto(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.y / 120.0
	var puntos := PackedVector2Array([c + Vector2(-34, 2) * k, c + Vector2(-12, 24) * k, c + Vector2(34, -24) * k])
	icono.draw_polyline(puntos, COLOR_CONTORNO, 22.0 * k, true)
	icono.draw_polyline(puntos, CREMA, 12.0 * k, true)


func _actualizar_depuracion() -> void:
	if not _panel_depuracion.visible:
		return
	_panel_depuracion.text = "fase: %s\nmural: %d/%d (%s)\npedidos: %s\nlatas: %s\nreceta: %s\ncapas: %s\nfallos: %d  libreta: %d\nestrellitas: %d  destellos: %d" % [
		_fase, _mural_idx, _numero_murales, _dibujo_actual, str(_pedidos_mural), str(_latas), str(_receta),
		str(_capas), _fallos, _revisiones, _calcular_estrellitas(), _calcular_destellos()]
