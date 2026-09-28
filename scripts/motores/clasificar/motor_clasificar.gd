class_name MotorClasificar
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "clasificar" — "Lluvia de colores" (docs/fichas/motor-clasificar.md).
##
## Elementos con un atributo (aqui, gotas de un color) se llevan a un objetivo que lo pide (un
## charco). Agnostico de tema: todo lo que cambia entre Maxi, Nicole y Sofia llega en el JSON del
## nivel (contrato §4 de la ficha). Cuatro formas de jugar, elegidas por datos:
## - `libre` (Semilla): cualquier charco hace magia; nunca hay "no". Variantes: gota quieta, caida
##   lenta con salto al charco mas cercano, charco que llama (`charco_llama`), gotas gigantes que se
##   dividen (`gotas_divisibles`) y arcoiris en el cielo (`arcoiris_cielo`: sin charcos).
## - `directo` (Brote): cada gota a su charco del mismo color, un objetivo a la vez. Variantes:
##   charcos decorados, charcos que cambian de lugar (`charcos_moviles`), gota-jirafa bonus y
##   `nombrar_color_por_voz` (Coco nombra el color y los charcos solo tienen contorno).
## - `mezcla` (Estrella): charcos que piden un color que se arma con 2-3 componentes; el primero
##   "tine a medias". Variantes: receta a la vista (`guia_receta`), gota gris que hay que dejar pasar
##   (`gota_distractora`), blanco y cafe, y pedidos encadenados con reloj amable
##   (`reloj_estrellitas`, solo da estrellitas: nunca termina el nivel ni apura).
##
## Duracion (PO 27-Sep-2026: >= 1 h por hermano en el planeta): cada nivel se juega en TANDAS
## (`rondas` x `por_ronda`) con mini-fiesta entre tandas; colores y lugares se barajan en cada
## partida. `limite_intentos` cuenta fallos POR TANDA: al agotarse, derrota-gag (Nicole: Coco se
## tine y estornuda un arcoiris; Sofia: los charcos se desbordan y Coco queda pintada) y reintento
## de un toque sin perder lo logrado.
##
## F3 (solo PC) muestra un panel de depuracion para el PO.

signal gota_clasificada(color_id: String, charco_id: String)
signal intento_fallido()
signal mezcla_lograda(resultado: String)
signal ronda_completada(indice: int)
signal nivel_fallado()

const Gota := preload("res://scripts/motores/clasificar/gota_clasificar.gd")
const Charco := preload("res://scripts/motores/clasificar/charco_clasificar.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")

## Paleta por defecto (el nivel puede sobreescribirla con `paleta`). Rojo/rosado y azul/celeste
## estan separados lo justo para la discriminacion fina de Nicole z4.
const PALETA := {
	"rojo": "#FF5A5A", "azul": "#3F7FE0", "amarillo": "#FFD23F", "rosado": "#FF8CC6",
	"verde": "#5CCB5F", "naranja": "#FF9A3C", "violeta": "#9B6BDE", "celeste": "#8AD8F7",
	"blanco": "#FFFFFF", "cafe": "#9A6440", "lila": "#CDA8F2", "verde_claro": "#B2EB8F",
	"gris": "#A9A7B3", "turquesa": "#45C6C0",
}
## Recetas reales de mezcla de pinturas (el nivel puede agregar o cambiar con `recetas`).
const RECETAS := {
	"verde": ["azul", "amarillo"], "naranja": ["rojo", "amarillo"], "violeta": ["rojo", "azul"],
	"rosado": ["rojo", "blanco"], "celeste": ["azul", "blanco"], "cafe": ["rojo", "amarillo", "azul"],
	"lila": ["rojo", "azul", "blanco"], "verde_claro": ["azul", "amarillo", "blanco"],
}
const BANDAS_ARCOIRIS := ["rojo", "naranja", "amarillo", "verde", "azul", "violeta"]
const TAMANO_GOTA := {"semilla": 130.0, "brote": 112.0, "estrella": 96.0}
## Cielo por donde caen las gotas (a la izquierda Coco, abajo a la derecha Cometa, arriba la barra).
const ZONA_CIELO := Rect2(290, 110, 820, 360)
const Y_APARICION := 160.0
const BASE_CHARCOS := 708.0
const ARCO_CENTRO := Vector2(700, 640)
const ARCO_RADIO := 380.0
const ARCO_ANCHO := 36.0
const DESTELLOS_POR_GOTA := 3
const DESTELLOS_POR_MEZCLA := 8
const DESTELLOS_TANDA_LIMPIA := 5
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_TOMAR := "sfx/ui/seleccionar.ogg"
const SFX_SOLTAR := "sfx/ui/soltar.ogg"
const SFX_ACIERTO := "sfx/ui/confirmar.ogg"
const SFX_NO_ES_ESTE := "sfx/ui/no_es_este.ogg"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_GAG := "sfx/ui/abrir.ogg"
const SFX_MOVER := "sfx/ui/cerrar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")

@onready var _cielo: Control = %cielo
@onready var _capa_charcos: Control = %charcos
@onready var _capa_gotas: Control = %gotas
@onready var _efectos: Control = %efectos
@onready var _barra: Control = %barra
@onready var _anfitriona: TextureRect = %anfitriona
@onready var _manchas_coco: Control = %manchas_coco
@onready var _boton_otra_vez: Button = %boton_otra_vez
@onready var _confeti: CPUParticles2D = %confeti
@onready var _boton_cometa: Button = %boton_cometa
@onready var _boton_salir: Button = %boton_salir
@onready var _panel_depuracion: Label = %panel_depuracion

# --- Configuracion (desde el nivel) ---
var _modo := "libre"
var _velocidad := 0.0
var _variacion := 0.0
var _simultaneas := 1
var _iman := 140.0
var _limite = null  ## null = sin limite; si no, fallos por tanda
var _umbrales: Dictionary = {}
var _ayuda_tras_fallos := 0
var _ayuda_idle := 0.0
var _regalo := false
var _pistas_cuestan := false
var _tam_gota := 120.0
var _numero_rondas := 4
var _por_ronda := 8
var _colores: Array = []
var _decoraciones: Dictionary = {}
var _paleta: Dictionary = {}
var _recetas: Dictionary = {}
var _pedidos_pool: Array = []
var _mazo_pedidos: Array = []  ## mazo de pedidos de Sofia: persiste entre tandas
var _ultimos_pedidos: Array = []
var _paleta_gotas: Array = []
var _charco_llama := false
var _divisibles := false
var _arcoiris_cielo := false
var _charcos_moviles := false
var _nombrar := false
var _guia_receta := false
var _prob_gris := 0.0
var _reloj_s := 0.0
var _encadenado := false
var _dino_rango := Vector2i.ZERO
var _especial: Dictionary = {}

# --- Estado ---
var _gotas: Array = []
var _charcos: Array = []
var _cola: Array = []
var _ronda := 0
var _meta_ronda := 0
var _logrados_ronda := 0
var _colores_barra: Array = []
var _fallos_ronda := 0
var _fallos_total := 0
var _fallos_seguidos := 0
var _derrota_disparada := false
var _derrotas := 0
var _regalo_dado := false
var _pistas_usadas := 0
var _en_gag := false
var _en_transicion := true
var _terminado := false
var _aciertos := 0
var _mezclas := 0
var _tandas_limpias := 0
var _a_tiempo := 0
var _pedidos_con_reloj := 0
var _gota_elegida = null
var _color_pedido := ""
var _charco_objetivo = null
var _proximo_dino := 0
var _especial_dado := false
var _datos_dichos := {}
var _bailan_dicho := false
var _espera_spawn := 0.0
var _inactivo := 0.0
var _voz_ocupada_hasta := 0.0
var _ultima_linea := ""
var _avance_bandas: Array = []
var _manchas: Array = []

var _boton_pista: Button
var _tiempo := 0.0
var _base_anfitriona := Vector2.ZERO
var _salto_anfitriona := 0.0
var _tween_anfitriona: Tween


func _ready() -> void:
	super._ready()
	_boton_otra_vez.hide()
	_panel_depuracion.hide()
	_estilizar_interfaz()
	_crear_boton_pista()
	_boton_otra_vez.pressed.connect(_reintentar)
	_boton_cometa.pressed.connect(_al_tocar_cometa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_anfitriona.mouse_filter = Control.MOUSE_FILTER_STOP
	_anfitriona.gui_input.connect(_al_tocar_anfitriona)
	_anfitriona.pivot_offset = Vector2(_anfitriona.size.x / 2.0, _anfitriona.size.y)
	_base_anfitriona = _anfitriona.position
	_manchas_coco.draw.connect(_dibujar_manchas_coco)
	_cielo.draw.connect(_dibujar_cielo)
	_barra.draw.connect(_dibujar_barra)
	if nivel.is_empty():
		push_error("motor_clasificar: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()
	_boton_pista.visible = _pistas_cuestan and _modo == "mezcla"
	if _modo != "mezcla" and not _arcoiris_cielo:
		_construir_charcos_de_color()
	_reproducir_voz("intro", _linea("intro"), true)
	_despues(0.7, _iniciar_ronda.bind(0))
	_actualizar_depuracion()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	var bamboleo := absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0
	_anfitriona.position.y = _base_anfitriona.y - _salto_anfitriona - bamboleo
	if _arcoiris_cielo:
		_cielo.queue_redraw()
	if _en_gag or _terminado or _en_transicion:
		return
	var suelo := _y_suelo()
	for gota in _gotas.duplicate():
		if is_instance_valid(gota) and gota.cayendo and not gota.en_vuelo and not gota.esta_presionada() \
				and gota.centro_global().y > suelo:
			_gota_al_suelo(gota)
	if _modo == "mezcla":
		_espera_spawn -= delta
		if _espera_spawn <= 0.0 and _gotas.size() < _simultaneas:
			_espera_spawn = 0.8
			_crear_gota_mezcla()
		# Reloj amable: se detiene mientras Coco habla (intro, pedido, dato curioso), asi escuchar
		# nunca cuesta estrellitas.
		if _ahora() >= _voz_ocupada_hasta:
			for charco in _charcos:
				if is_instance_valid(charco) and charco.reloj >= 0.0 and charco.reloj < 1.0 and not charco.resuelto:
					charco.reloj = minf(1.0, charco.reloj + delta / _reloj_s)
	if _ayuda_idle > 0.0:
		_inactivo += delta
		if _inactivo >= _ayuda_idle:
			_inactivo = 0.0
			_ayuda_por_inactividad()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Configuracion y armado
# ---------------------------------------------------------------------------

func _configurar_desde_nivel() -> void:
	var perfil := obtener_perfil_dificultad()
	_modo = str(nivel.get("modo", "libre"))
	_velocidad = float(nivel.get("velocidad_caida", 0.0))
	_variacion = clampf(float(nivel.get("variacion_velocidad", 0.0)), 0.0, 0.9)
	_simultaneas = maxi(1, int(nivel.get("elementos_simultaneos", 1)))
	_iman = float(nivel.get("iman_tolerancia_px", 140.0))
	var limite = nivel.get("limite_intentos", null)
	_limite = int(limite) if limite != null else null
	_umbrales = nivel.get("umbrales_estrellitas", {})
	_ayuda_tras_fallos = int(nivel.get("ayuda_tras_fallos", 0))
	_ayuda_idle = float(nivel.get("ayuda_idle_s", 0.0))
	_regalo = bool(nivel.get("regalo_tras_derrotas", false))
	_pistas_cuestan = bool(nivel.get("pistas_cuestan_estrellita", false))
	_tam_gota = float(nivel.get("tamano_gota", TAMANO_GOTA.get(perfil, 110.0)))
	_numero_rondas = maxi(1, int(nivel.get("rondas", 4)))
	_por_ronda = maxi(1, int(nivel.get("por_ronda", 6)))
	_colores = nivel.get("colores", [])
	_decoraciones = nivel.get("decoraciones", {})
	_paleta = PALETA.duplicate()
	_paleta.merge(nivel.get("paleta", {}), true)
	_recetas = RECETAS.duplicate(true)
	_recetas.merge(nivel.get("recetas", {}), true)
	_pedidos_pool = nivel.get("pedidos", [])
	_paleta_gotas = nivel.get("paleta_gotas", ["rojo", "azul", "amarillo"])
	_charco_llama = bool(nivel.get("charco_llama", false))
	_divisibles = bool(nivel.get("gotas_divisibles", false))
	_arcoiris_cielo = bool(nivel.get("arcoiris_cielo", false))
	_charcos_moviles = bool(nivel.get("charcos_moviles", false))
	_nombrar = bool(nivel.get("nombrar_color_por_voz", false))
	_guia_receta = bool(nivel.get("guia_receta", false))
	var distractora: Dictionary = nivel.get("gota_distractora", {})
	_prob_gris = float(distractora.get("probabilidad", 0.0))
	var reloj: Dictionary = nivel.get("reloj_estrellitas", {})
	_reloj_s = float(reloj.get("segundos_por_pedido", 0.0))
	_encadenado = bool(nivel.get("pedidos_encadenados", false))
	var dino: Dictionary = nivel.get("sorpresa_dino", {})
	if not dino.is_empty():
		_dino_rango = Vector2i(int(dino.get("cada_min", 5)), int(dino.get("cada_max", 8)))
		_proximo_dino = randi_range(_dino_rango.x, _dino_rango.y)
	_especial = nivel.get("gota_especial", {})


func _color(id: String) -> Color:
	return Color(str(_paleta.get(id, "#FFFFFF")))


func _y_suelo() -> float:
	if _arcoiris_cielo:
		return 650.0
	return 405.0 if _modo == "mezcla" else 470.0


## Charcos de un color (libre/directo/nombrar), repartidos al azar a lo ancho (rejugabilidad).
func _construir_charcos_de_color() -> void:
	var ids := _colores.duplicate()
	if _nombrar:
		ids = []
		for i in int(nivel.get("charcos_contorno", 3)):
			ids.append("")
	ids.shuffle()
	var xs := _posiciones_x(ids.size())
	var espacio := 720.0 / maxf(1.0, ids.size() - 1.0) if ids.size() > 1 else 400.0
	var ancho := minf(230.0 if obtener_perfil_dificultad() == "semilla" else 200.0, espacio - 14.0)
	var tamano := Vector2(ancho, 150.0)
	for i in ids.size():
		var id: String = ids[i]
		var charco: CharcoClasificar = Charco.new()
		charco.configurar({
			"id": "charco_%s" % (id if id != "" else str(i)), "color_id": id, "color": _color(id) if id != "" else Color.WHITE,
			"decoracion": _decoraciones.get(id, ""), "solo_contorno": _nombrar,
		}, tamano)
		_capa_charcos.add_child(charco)
		charco.position = Vector2(xs[i] - tamano.x / 2.0, BASE_CHARCOS - tamano.y)
		charco.tocado.connect(_al_tocar_charco)
		_charcos.append(charco)
		_aparecer(charco, i * 0.08)


func _posiciones_x(n: int) -> Array:
	if n <= 1:
		return [700.0]
	var desde := 420.0 if n <= 3 else 350.0
	var hasta := 980.0 if n <= 3 else 1020.0
	var xs: Array = []
	for i in n:
		xs.append(lerpf(desde, hasta, i / float(n - 1)))
	return xs


func _aparecer(nodo: Control, retraso: float) -> void:
	nodo.scale = Vector2.ZERO
	var tween := nodo.create_tween()
	tween.tween_interval(retraso)
	tween.tween_property(nodo, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Tandas (rondas)
# ---------------------------------------------------------------------------

func _iniciar_ronda(indice: int) -> void:
	if not is_inside_tree() or _terminado:
		return
	_ronda = indice
	_fallos_ronda = 0
	_logrados_ronda = 0
	_colores_barra.clear()
	_gota_elegida = null
	if _arcoiris_cielo:
		_cola = []
		for id in BANDAS_ARCOIRIS:
			_cola.append({"color": id, "tipo": "normal"})
		_avance_bandas = []
		for i in BANDAS_ARCOIRIS.size():
			_avance_bandas.append(0.0)
		_meta_ronda = BANDAS_ARCOIRIS.size()
	elif _modo == "mezcla":
		_cola = _armar_pedidos()
		_meta_ronda = _cola.size()
		if _encadenado:
			_crear_charcos_mezcla([_cola.pop_front()])
		else:
			_crear_charcos_mezcla(_cola.duplicate())
			_cola.clear()
		_espera_spawn = 0.4
	elif _nombrar:
		_cola = _armar_cola_nombrar()
		_meta_ronda = _cola.size()
		for charco in _charcos:
			charco.solo_contorno = true
			charco.color_id = ""
			charco.color = Color.WHITE
			charco.llamando = false
	else:
		_cola = _armar_cola_colores()
		_meta_ronda = _cola.size() * (2 if _divisibles else 1)
	# Cada tanda nueva baraja los charcos con una vuelta suave (rejugabilidad y atencion).
	var mover := indice > 0 and _modo != "mezcla" and not _arcoiris_cielo and _charcos.size() > 1
	if mover:
		_mover_charcos()
	_en_transicion = false
	_barra.queue_redraw()
	if mover:
		_despues(1.0, _reponer)
	else:
		_reponer()
	_actualizar_depuracion()


## Colores parejos y barajados: cada color aparece casi lo mismo y nunca tres veces seguido.
func _armar_cola_colores() -> Array:
	var pool: Array = nivel.get("pool_gotas", _colores)
	var lista: Array = []
	while lista.size() < _por_ronda:
		var tanda := pool.duplicate()
		tanda.shuffle()
		lista.append_array(tanda)
	lista.resize(_por_ronda)
	lista.shuffle()
	for i in range(2, lista.size()):
		if lista[i] == lista[i - 1] and lista[i] == lista[i - 2]:
			var j := (i + 3) % lista.size()
			var tmp = lista[i]
			lista[i] = lista[j]
			lista[j] = tmp
	var cola: Array = []
	for id in lista:
		cola.append({"color": id, "tipo": "gigante" if _divisibles else "normal"})
	if not _especial.is_empty() and not _especial_dado and _ronda == int(_especial.get("ronda", 1)):
		_especial_dado = true
		cola.insert(cola.size() / 2, {"color": str(_especial.get("color", "amarillo")), "tipo": str(_especial.get("tipo", "jirafa"))})
	return cola


## Nicole z5: los colores que Coco va a nombrar en esta tanda (distintos entre si).
func _armar_cola_nombrar() -> Array:
	var pool: Array = nivel.get("pool_gotas", _colores).duplicate()
	pool.shuffle()
	var cola: Array = []
	for i in mini(_charcos.size(), pool.size()):
		cola.append({"color": pool[i], "tipo": "normal"})
	return cola


## Sofia: pedidos de la tanda, sacados de un mazo que dura toda la partida. Ningun color se repite
## hasta haber pedido todos los del pool, y dos tandas seguidas nunca piden el mismo grupo (feedback
## del PO 27-Sep-2026: antes el mazo se rearmaba en cada tanda y con un pool chico pedia siempre lo
## mismo).
func _armar_pedidos() -> Array:
	var lista: Array = []
	var intentos := 0
	while lista.size() < _por_ronda and intentos < 100:
		intentos += 1
		if _mazo_pedidos.is_empty():
			_mazo_pedidos = _pedidos_pool.duplicate()
			_mazo_pedidos.shuffle()
			# al rearmar, lo recien pedido (esta tanda y la anterior) va al fondo del mazo
			_mazo_pedidos.sort_custom(func(x, y): return _peso_reciente(x, lista) < _peso_reciente(y, lista))
		var candidato = _mazo_pedidos.pop_front()
		if lista.has(candidato) and _pedidos_pool.size() >= _por_ronda:
			_mazo_pedidos.append(candidato)
			continue
		lista.append(candidato)
	var mismo_grupo := lista.size() == _ultimos_pedidos.size()
	for c in lista:
		mismo_grupo = mismo_grupo and _ultimos_pedidos.has(c)
	if mismo_grupo and _pedidos_pool.size() > _por_ronda and not _mazo_pedidos.is_empty():
		var cambio = _mazo_pedidos.pop_front()
		_mazo_pedidos.append(lista[lista.size() - 1])
		lista[lista.size() - 1] = cambio
	lista.shuffle()
	_ultimos_pedidos = lista.duplicate()
	return lista


func _peso_reciente(color, tanda_actual: Array) -> int:
	if tanda_actual.has(color):
		return 2
	return 1 if _ultimos_pedidos.has(color) else 0


func _terminar_ronda() -> void:
	_en_transicion = true
	ronda_completada.emit(_ronda)
	if _limite != null and _fallos_ronda == 0 and not _derrota_disparada:
		_tandas_limpias += 1
	_gota_elegida = null
	for gota in _gotas:
		if is_instance_valid(gota):
			gota.irse(true)
	_gotas.clear()
	for charco in _charcos:
		if is_instance_valid(charco):
			charco.llamando = false
	_barra.queue_redraw()
	var espera := 0.6
	if _arcoiris_cielo:
		_arcoiris_gigante()
		_reproducir_voz("arcoiris_completo", _linea_al_azar("arcoiris_completo"), true)
		espera = 2.2
	if _ronda + 1 >= _numero_rondas:
		_despues(espera, _celebrar_victoria)
		return
	_confeti.restart()
	_reaccion_anfitriona("baila")
	for charco in _charcos:
		if is_instance_valid(charco):
			charco.brillar(1.2)
			charco.salpicar(DORADO)
	espera = maxf(espera + 0.6, _voz_ocupada_hasta - _ahora() + 0.3)
	_despues(espera, func() -> void:
		_reproducir_voz("nueva_ronda", _linea_al_azar("nueva_ronda"), true)
		_despues(1.8, _iniciar_ronda.bind(_ronda + 1)))
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Gotas
# ---------------------------------------------------------------------------

func _crear_gota(id: String, tipo := "normal", lado := 0.0) -> GotaClasificar:
	var gota: GotaClasificar = Gota.new()
	var tam := lado if lado > 0.0 else _tam_gota * (1.3 if tipo == "gigante" else 1.0)
	gota.configurar(id, _color(id), tam, tipo)
	_capa_gotas.add_child(gota)
	gota.velocidad = _velocidad * (1.0 + randf_range(-_variacion, _variacion))
	gota.cayendo = _velocidad > 0.0
	gota.tomada.connect(_al_tomar)
	gota.movida.connect(_al_mover)
	gota.soltada.connect(_al_soltar)
	gota.tocada.connect(_al_tocar_gota)
	_gotas.append(gota)
	return gota


## Gotas que ocupan lugar en pantalla. Con gotas divisibles, cada gotita cuenta como media gigante
## (asi nunca se juntan mas de `elementos_simultaneos` gigantes o sus pares de gotitas).
func _vivas_para_reponer() -> float:
	var n := 0.0
	for gota in _gotas:
		if is_instance_valid(gota):
			n += 0.5 if _divisibles and gota.tipo != "gigante" else 1.0
	return n


## Pone gotas nuevas de la cola hasta llenar `elementos_simultaneos`.
func _reponer() -> void:
	if _en_gag or _terminado or _en_transicion or not is_inside_tree():
		return
	if _modo == "mezcla":
		return
	if _nombrar:
		if _gotas.is_empty() and not _cola.is_empty():
			_nuevo_pedido_nombrar()
		return
	var retraso := 0.0
	while _vivas_para_reponer() < _simultaneas and not _cola.is_empty():
		var info: Dictionary = _cola.pop_front()
		var gota := _crear_gota(info["color"], info["tipo"])
		gota.casa = _lugar_para_gota(gota)
		gota.fijar_centro(gota.casa)
		gota.aparecer(retraso)
		retraso += 0.25
		if info["tipo"] == "jirafa":
			_despues(0.3, func() -> void: _reproducir_voz("especial_aparece", _linea("especial_aparece"), true))
	_actualizar_llamada()


## Donde nace una gota: quieta junto a un charco (Maxi z1), quieta en el cielo (Nicole z1) o arriba
## del cielo para caer, sin encimarse con otra.
func _lugar_para_gota(gota: GotaClasificar) -> Vector2:
	if _velocidad <= 0.0 and _modo == "libre" and not _charcos.is_empty():
		var libres := _charcos.filter(func(c) -> bool:
			for otra in _gotas:
				if otra != gota and is_instance_valid(otra) and absf(otra.casa.x - c.centro_charco().x) < 60.0:
					return false
			return true)
		var charco = (libres if not libres.is_empty() else _charcos).pick_random()
		return Vector2(charco.centro_charco().x, 430.0)
	var y := 330.0 if _velocidad <= 0.0 else Y_APARICION
	var mejor := Vector2(ZONA_CIELO.get_center().x, y)
	var mejor_distancia := -1.0
	for intento in 12:
		var x := randf_range(ZONA_CIELO.position.x + gota.size.x * 0.6, ZONA_CIELO.end.x - gota.size.x * 0.6)
		var distancia := 9999.0
		for otra in _gotas:
			if otra != gota and is_instance_valid(otra):
				distancia = minf(distancia, absf(otra.centro_global().x - x))
		if distancia > mejor_distancia:
			mejor_distancia = distancia
			mejor = Vector2(x, y)
		if distancia > gota.size.x * 1.4:
			break
	return mejor


## Sofia: gotas de la paleta que caen sin parar, casi siempre de un color que sirve.
func _crear_gota_mezcla() -> void:
	var tipo := "normal"
	var id := ""
	var hay_gris := _gotas.any(func(g) -> bool: return is_instance_valid(g) and g.tipo == "gris")
	if _prob_gris > 0.0 and not hay_gris and randf() < _prob_gris:
		tipo = "gris"
		id = "gris"
	else:
		var necesarios := _colores_necesarios()
		var en_pantalla: Array = []
		for gota in _gotas:
			if is_instance_valid(gota):
				en_pantalla.append(gota.color_id)
		var faltan := necesarios.filter(func(c) -> bool: return not en_pantalla.has(c))
		if not faltan.is_empty() and randf() < 0.75:
			id = faltan.pick_random()
		elif not necesarios.is_empty() and randf() < 0.5:
			id = necesarios.pick_random()
		else:
			id = _paleta_gotas.pick_random()
	var gota := _crear_gota(id, tipo)
	gota.casa = _lugar_para_gota(gota)
	gota.fijar_centro(gota.casa)
	gota.aparecer()


func _colores_necesarios() -> Array:
	var lista: Array = []
	for charco in _charcos:
		if is_instance_valid(charco) and charco.es_mezcla and not charco.resuelto:
			for componente in charco.faltantes():
				if not lista.has(componente):
					lista.append(componente)
	return lista


## Una gota que llega al suelo nunca se pierde ni castiga: vuelve a caer desde arriba. En la mezcla
## de Sofia se aplasta y viene otra (la gris que se deja pasar es justo lo que hay que hacer).
func _gota_al_suelo(gota: GotaClasificar) -> void:
	if _modo == "mezcla":
		_gotas.erase(gota)
		if _gota_elegida == gota:
			_gota_elegida = null
		if gota.tipo == "gris":
			_estallido(gota.centro_global(), 6, [Color.WHITE, DORADO], 0.6)
			if randf() < 0.35:
				_reproducir_voz("dejaste_pasar", _linea("dejaste_pasar"))
		gota.irse(false)
		return
	gota.en_vuelo = true
	var tween := gota.nuevo_tween()
	tween.tween_property(gota, "scale", Vector2(1.3, 0.6), 0.1)
	tween.tween_property(gota, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		gota.scale = Vector2.ONE
		gota.casa = _lugar_para_gota(gota)
		gota.fijar_centro(gota.casa))
	tween.tween_property(gota, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func() -> void: gota.en_vuelo = false)


# ---------------------------------------------------------------------------
# Entrada: tomar, arrastrar, soltar y tocar
# ---------------------------------------------------------------------------

func _puede_jugar() -> bool:
	return not (_en_gag or _terminado or _en_transicion)


func _al_tomar(gota: GotaClasificar) -> void:
	if not _puede_jugar():
		gota.cancelar_arrastre()
		return
	_inactivo = 0.0
	_capa_gotas.move_child(gota, -1)
	gota.agrandar(1.12)
	reproducir_sfx(SFX_TOMAR)


func _al_mover(gota: GotaClasificar, punto: Vector2) -> void:
	if not _puede_jugar():
		return
	gota.fijar_centro(punto)
	var charco = _charco_cerca(punto)
	if charco != null:
		charco.brillar(0.15)


func _al_soltar(gota: GotaClasificar, punto: Vector2) -> void:
	if not _puede_jugar():
		return
	var charco = _charco_cerca(punto)
	if charco == null and _modo == "libre" and not _arcoiris_cielo and punto.y > 420.0:
		charco = _charco_mas_cercano_x(punto.x)
	if _arcoiris_cielo:
		_pintar_banda(gota)
		return
	if charco != null:
		soltar_gota_en(gota, charco)
		return
	reproducir_sfx(SFX_SOLTAR)
	if gota.tipo == "gigante":
		_dividir(gota)
		return
	gota.agrandar(1.0)
	if gota.cayendo:
		# Cae desde donde la dejo: sin volver atras ni perder nada.
		var suelo := _y_suelo() - 30.0
		gota.casa = Vector2(clampf(punto.x, ZONA_CIELO.position.x, ZONA_CIELO.end.x), clampf(punto.y, ZONA_CIELO.position.y, suelo))
		gota.fijar_centro(gota.casa)
	else:
		gota.volver_a_casa()


func _al_tocar_gota(gota: GotaClasificar) -> void:
	if not _puede_jugar() or gota.en_vuelo:
		return
	_inactivo = 0.0
	reproducir_sfx(SFX_TOQUE)
	if gota.tipo == "gigante":
		_dividir(gota)
		return
	if _arcoiris_cielo:
		_pintar_banda(gota)
		return
	if _modo == "libre":
		gota.agrandar(1.0)
		var charco = _charco_mas_cercano_x(gota.centro_global().x)
		if charco != null:
			soltar_gota_en(gota, charco)
		return
	gota.pulso()
	if _gota_elegida == gota:
		gota.elegida = false
		_gota_elegida = null
		return
	if _gota_elegida != null and is_instance_valid(_gota_elegida):
		_gota_elegida.elegida = false
	gota.elegida = true
	_gota_elegida = gota


func _al_tocar_charco(charco: CharcoClasificar) -> void:
	if not _puede_jugar():
		return
	_inactivo = 0.0
	charco.pulso()
	reproducir_sfx(SFX_TOQUE)
	if _gota_elegida != null and is_instance_valid(_gota_elegida) and not _gota_elegida.en_vuelo:
		soltar_gota_en(_gota_elegida, charco)
		return
	var libres := gotas_activas()
	if _modo == "libre" and not libres.is_empty():
		var cercana = libres[0]
		for gota in libres:
			if gota.centro_global().distance_to(charco.centro_charco()) < cercana.centro_global().distance_to(charco.centro_charco()):
				cercana = gota
		soltar_gota_en(cercana, charco)
	elif _nombrar and charco == _charco_objetivo:
		_decir_pedido()
	elif _modo == "directo" and not _nombrar and libres.size() == 1:
		soltar_gota_en(libres[0], charco)


func _charco_cerca(punto: Vector2):
	var mejor = null
	var mejor_distancia := INF
	for charco in _charcos:
		if not is_instance_valid(charco):
			continue
		var distancia := 0.0
		if not charco.get_global_rect().has_point(punto):
			var radios: Vector2 = charco.radio_charco()
			distancia = punto.distance_to(charco.centro_charco()) - maxf(radios.x, radios.y)
		if distancia <= _iman and distancia < mejor_distancia:
			mejor = charco
			mejor_distancia = distancia
	return mejor


func _charco_mas_cercano_x(x: float):
	var mejor = null
	for charco in _charcos:
		if is_instance_valid(charco) and (mejor == null or absf(charco.centro_charco().x - x) < absf(mejor.centro_charco().x - x)):
			mejor = charco
	return mejor


# ---------------------------------------------------------------------------
# Resolver: el corazon de las reglas (publico para los arneses QA)
# ---------------------------------------------------------------------------

## Lleva `gota` a `charco` y aplica la regla del modo. Devuelve lo que paso: "magia", "doble_fiesta",
## "acierto", "componente", "mezcla", "no_es_este", "gris", "derrota", "dividida", "ocupado" o
## "ignorado".
func soltar_gota_en(gota: GotaClasificar, charco: CharcoClasificar) -> String:
	if not is_instance_valid(gota) or not is_instance_valid(charco) or gota.en_vuelo or not _puede_jugar():
		return "ignorado"
	_inactivo = 0.0
	if _gota_elegida == gota:
		_gota_elegida = null
	gota.elegida = false
	if gota.tipo == "gigante":
		_dividir(gota)
		return "dividida"
	if _arcoiris_cielo:
		_pintar_banda(gota)
		return "magia"
	match _modo:
		"libre":
			return _magia(gota, charco)
		"mezcla":
			if charco.resuelto or charco.faltantes().is_empty():
				gota.volver_a_casa(true)
				charco.menear()
				return "ocupado"
			if gota.tipo == "gris":
				return _fallo(gota, charco, "gris")
			if charco.faltantes().has(gota.color_id):
				return _componente(gota, charco)
			return _fallo(gota, charco, "no_es_este")
		_:
			if _nombrar:
				if gota.color_id == _color_pedido:
					_acierto_nombrar(gota)
					return "acierto"
				return _fallo(gota, charco, "no_es_este")
			if gota.color_id == charco.color_id:
				_acierto(gota, charco)
				return "acierto"
			return _fallo(gota, charco, "no_es_este")


## Semilla: todo charco hace magia de color. Si el charco "llama" (z3) y es el de su color, doble fiesta.
func _magia(gota: GotaClasificar, charco: CharcoClasificar) -> String:
	_gotas.erase(gota)
	var doble := _charco_llama and gota.color_id == charco.color_id
	var color_gota: Color = gota.color
	var sorpresa := false
	if _dino_rango != Vector2i.ZERO:
		_proximo_dino -= 1
		if _proximo_dino <= 0:
			sorpresa = true
			_proximo_dino = randi_range(_dino_rango.x, _dino_rango.y)
	_sumar_logro(color_gota)
	reproducir_sfx(SFX_SOLTAR)
	gota.saltar_a(charco.centro_charco(), func() -> void:
		charco.salpicar(color_gota)
		reproducir_sfx(SFX_ACIERTO)
		_estallido(charco.centro_charco(), 12 if doble else 7, [color_gota, charco.color, DORADO], 1.4 if doble else 1.0)
		if doble:
			_despues(0.2, func() -> void: _estallido(charco.centro_charco() + Vector2(0, -60), 10, [DORADO, color_gota, Color.WHITE], 1.8))
			_reaccion_anfitriona("salta")
		if sorpresa:
			_dino_de_pintura(charco.centro_charco() + Vector2(0, -150), color_gota))
	if sorpresa:
		_reproducir_voz("especial", _linea("especial"), true)
	elif doble:
		_reproducir_voz("doble_fiesta", _linea_al_azar("doble_fiesta"))
	elif randf() < 0.55:
		_reproducir_voz("color", _voz_color(gota.color_id))
	else:
		_reproducir_voz("acierto", _linea_al_azar("acierto"))
	gota_clasificada.emit(gota.color_id, charco.id)
	_tras_logro(0.4)
	return "doble_fiesta" if doble else "magia"


func _acierto(gota: GotaClasificar, charco: CharcoClasificar) -> void:
	_gotas.erase(gota)
	_fallos_seguidos = 0
	var color_gota: Color = gota.color
	var es_jirafa := gota.tipo == "jirafa"
	_sumar_logro(color_gota)
	reproducir_sfx(SFX_SOLTAR)
	gota.saltar_a(charco.centro_charco(), func() -> void:
		charco.salpicar(color_gota)
		reproducir_sfx(SFX_ACIERTO)
		_estallido(charco.centro_charco(), 8, [color_gota, DORADO]))
	if es_jirafa:
		_arcoiris_especial()
		_confeti.restart()
		_reaccion_anfitriona("baila")
		_reproducir_voz("especial", _linea("especial"), true)
	elif randf() < 0.5:
		_reproducir_voz("color", _voz_color(gota.color_id))
	else:
		_reproducir_voz("acierto", _linea_al_azar("acierto"))
		_reaccion_anfitriona("salta")
	gota_clasificada.emit(gota.color_id, charco.id)
	if _charcos_moviles and _logrados_ronda < _meta_ronda:
		_despues(0.55, _mover_charcos)
		_tras_logro(1.7)
	else:
		_tras_logro(0.5)


## Nicole z5: la gota pedida pinta el charco de contorno que brilla; las otras se van flotando.
func _acierto_nombrar(gota: GotaClasificar) -> void:
	var charco: CharcoClasificar = _charco_objetivo
	_gotas.erase(gota)
	_fallos_seguidos = 0
	for otra in _gotas:
		if is_instance_valid(otra):
			otra.irse(true)
	_gotas.clear()
	var color_gota: Color = gota.color
	var id_color := gota.color_id
	charco.llamando = false
	_sumar_logro(color_gota)
	reproducir_sfx(SFX_SOLTAR)
	gota.saltar_a(charco.centro_charco(), func() -> void:
		charco.solo_contorno = false
		charco.color = color_gota
		charco.color_id = id_color
		charco.salpicar(color_gota)
		reproducir_sfx(SFX_ACIERTO)
		_estallido(charco.centro_charco(), 9, [color_gota, DORADO]))
	_reproducir_voz("color", _voz_color(id_color))
	_reaccion_anfitriona("salta")
	gota_clasificada.emit(id_color, charco.id)
	_tras_logro(1.3)


func _nuevo_pedido_nombrar() -> void:
	var info: Dictionary = _cola.pop_front()
	_color_pedido = info["color"]
	_charco_objetivo = null
	for charco in _charcos:
		if charco.solo_contorno:
			_charco_objetivo = charco
			break
	if _charco_objetivo == null:
		_charco_objetivo = _charcos[0]
	_charco_objetivo.llamando = true
	var pool: Array = nivel.get("pool_gotas", _colores).duplicate()
	pool.erase(_color_pedido)
	pool.shuffle()
	var opciones: Array = [_color_pedido]
	for i in mini(int(nivel.get("opciones_por_pedido", 3)) - 1, pool.size()):
		opciones.append(pool[i])
	opciones.shuffle()
	var xs := [480.0, 700.0, 920.0] if opciones.size() == 3 else _posiciones_x(opciones.size())
	for i in opciones.size():
		var gota := _crear_gota(opciones[i])
		gota.cayendo = false
		gota.casa = Vector2(xs[i], 330.0)
		gota.fijar_centro(gota.casa)
		gota.aparecer(0.1 + i * 0.12)
	_despues(0.35, _decir_pedido)


func _decir_pedido() -> void:
	if _color_pedido != "" and _puede_jugar():
		_reproducir_voz("pedido", str(_linea("prefijo_pedidos")) + _color_pedido + ".wav", true)


## Sofia: un componente correcto tine a medias; el ultimo completa la mezcla con explosion de color.
func _componente(gota: GotaClasificar, charco: CharcoClasificar) -> String:
	_gotas.erase(gota)
	_fallos_seguidos = 0
	charco.recibidos.append(gota.color_id)
	var completa: bool = charco.faltantes().is_empty()
	var color_gota: Color = gota.color
	reproducir_sfx(SFX_SOLTAR)
	gota.saltar_a(charco.centro_charco(), func() -> void:
		charco.salpicar(color_gota)
		_estallido(charco.centro_charco(), 5, [color_gota], 0.8)
		if completa:
			_mezcla_lograda(charco))
	if not completa:
		_reproducir_voz("componente", _linea_al_azar("componente"))
	return "mezcla" if completa else "componente"


func _mezcla_lograda(charco: CharcoClasificar) -> void:
	if not is_instance_valid(charco) or charco.resuelto:
		return
	charco.resuelto = true
	charco.llamando = false
	if charco.reloj >= 0.0:
		_pedidos_con_reloj += 1
		if charco.reloj < 1.0:
			_a_tiempo += 1
			charco.reloj_a_tiempo = true
		charco.reloj = -1.0
	_mezclas += 1
	reproducir_sfx(SFX_ACIERTO)
	_sumar_logro(charco.color_resultado)
	_estallido(charco.centro_charco(), 14, [charco.color_resultado, DORADO, Color.WHITE], 1.5)
	charco.salpicar(charco.color_resultado)
	_reaccion_anfitriona("salta")
	mezcla_lograda.emit(charco.resultado)
	if not _datos_dichos.has(charco.resultado) and _linea("prefijo_datos") != "":
		_datos_dichos[charco.resultado] = true
		_reproducir_voz("dato", str(_linea("prefijo_datos")) + charco.resultado + ".wav", true)
	elif charco.reloj_a_tiempo and randf() < 0.5:
		_reproducir_voz("a_tiempo", _linea("a_tiempo"))
	elif randf() < 0.5:
		_reproducir_voz("color", _voz_color(charco.resultado))
	else:
		_reproducir_voz("mezcla_lograda", _linea_al_azar("mezcla_lograda"))
	if _logrados_ronda >= _meta_ronda:
		_despues(0.3, _terminar_ronda)
	elif _encadenado and not _cola.is_empty():
		_despues(1.4, func() -> void:
			if _puede_jugar() or _en_gag:
				_crear_charcos_mezcla([_cola.pop_front()]))
	_actualizar_depuracion()


func _crear_charcos_mezcla(pedidos: Array) -> void:
	for charco in _charcos:
		if is_instance_valid(charco):
			var tween: Tween = charco.create_tween()
			tween.tween_property(charco, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(charco.queue_free)
	_charcos.clear()
	var xs := _posiciones_x(pedidos.size())
	var tamano := Vector2(250.0, 262.0)
	for i in pedidos.size():
		var resultado: String = pedidos[i]
		var receta: Array = _recetas.get(resultado, [])
		var colores := {}
		for componente in receta:
			colores[componente] = _color(componente)
		var charco: CharcoClasificar = Charco.new()
		charco.configurar({
			"id": "mezcla_%s_%d" % [resultado, i], "es_mezcla": true, "resultado": resultado,
			"color_resultado": _color(resultado), "receta": receta, "colores_receta": colores,
			"mostrar_receta": _guia_receta, "reloj": 0.0 if _reloj_s > 0.0 else -1.0,
		}, tamano)
		_capa_charcos.add_child(charco)
		charco.position = Vector2(xs[i] - tamano.x / 2.0, BASE_CHARCOS - tamano.y)
		charco.tocado.connect(_al_tocar_charco)
		_charcos.append(charco)
		_aparecer(charco, 0.1 + i * 0.1)
	if _encadenado and pedidos.size() == 1:
		_despues(0.3, func() -> void: _reproducir_voz("pedido", str(_linea("prefijo_necesito")) + str(pedidos[0]) + ".wav"))


## Maxi z4: la gota gigante se parte en dos gotitas que rebotan a los lados (causa-efecto).
func _dividir(gota: GotaClasificar) -> void:
	_gotas.erase(gota)
	var centro := gota.centro_global()
	reproducir_sfx(SFX_SOLTAR)
	_estallido(centro, 8, [gota.color, Color.WHITE], 1.2)
	_reproducir_voz("dividir", _linea_al_azar("dividir"))
	for lado in [-1.0, 1.0]:
		var gotita := _crear_gota(gota.color_id, "normal", maxf(104.0, _tam_gota * 0.85))
		gotita.fijar_centro(centro)
		var destino := Vector2(clampf(centro.x + lado * 95.0, ZONA_CIELO.position.x + 50.0, ZONA_CIELO.end.x - 50.0), minf(centro.y + 20.0, _y_suelo() - 60.0))
		gotita.casa = destino
		gotita.en_vuelo = true
		gotita.scale = Vector2.ONE * 0.4
		var tween := gotita.nuevo_tween()
		tween.tween_method(func(t: float) -> void:
			gotita.fijar_centro(centro.lerp(destino, t) + Vector2(0, -70.0 * 4.0 * t * (1.0 - t)))
		, 0.0, 1.0, 0.4)
		tween.parallel().tween_property(gotita, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void: gotita.en_vuelo = false)
	gota.queue_free()
	_actualizar_depuracion()


## Maxi z5: la gota sube como fuego artificial y pinta la franja siguiente del arcoiris del cielo.
func _pintar_banda(gota: GotaClasificar) -> void:
	if gota.en_vuelo:
		return
	_gotas.erase(gota)
	var indice := _logrados_ronda
	var id_banda: String = BANDAS_ARCOIRIS[mini(indice, BANDAS_ARCOIRIS.size() - 1)]
	var color_banda := _color(id_banda)
	_sumar_logro(color_banda)
	var radio := ARCO_RADIO - indice * ARCO_ANCHO
	var destino := ARCO_CENTRO + Vector2.from_angle(PI + PI * randf_range(0.3, 0.7)) * radio
	gota.en_vuelo = true
	var tween := gota.nuevo_tween()
	tween.tween_property(gota, "global_position", destino - gota.size / 2.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(gota, "scale", Vector2.ONE * 0.5, 0.42)
	tween.tween_callback(func() -> void:
		reproducir_sfx(SFX_ACIERTO)
		_estallido(destino, 14, [color_banda, DORADO, Color.WHITE], 1.6)
		var avance := _avance_bandas
		if indice < avance.size():
			var anima := create_tween()
			anima.tween_method(func(v: float) -> void:
				if indice < avance.size():
					avance[indice] = v
				_cielo.queue_redraw()
			, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT))
	tween.tween_callback(gota.queue_free)
	_reproducir_voz("color", _voz_color(id_banda))
	gota_clasificada.emit(id_banda, "cielo")
	_tras_logro(0.7)


func _sumar_logro(color_logro: Color) -> void:
	_logrados_ronda += 1
	_aciertos += 1
	_colores_barra.append(color_logro)
	_barra.queue_redraw()
	_actualizar_llamada()
	_actualizar_depuracion()


func _tras_logro(espera: float) -> void:
	if _modo == "mezcla":
		return
	if _logrados_ronda >= _meta_ronda:
		_despues(espera, _terminar_ronda)
	else:
		_despues(espera, _reponer)


## "Todavia no" amistoso: la gota vuelve, el charco se menea y (si hay limite) cuenta un fallo.
func _fallo(gota: GotaClasificar, charco: CharcoClasificar, clave: String) -> String:
	reproducir_sfx(SFX_NO_ES_ESTE)
	charco.menear()
	if gota.cayendo and not _nombrar:
		gota.casa = Vector2(gota.centro_global().x, clampf(gota.centro_global().y - 90.0, Y_APARICION, _y_suelo() - 60.0))
	gota.volver_a_casa(true)
	_reproducir_voz(clave, _linea_al_azar(clave))
	_reaccion_anfitriona("menea")
	intento_fallido.emit()
	_fallos_seguidos += 1
	_fallos_total += 1
	if _limite != null:
		_fallos_ronda += 1
		if _fallos_ronda >= int(_limite):
			_disparar_derrota_gag()
			_actualizar_depuracion()
			return "derrota"
	if _ayuda_tras_fallos > 0 and _fallos_seguidos >= _ayuda_tras_fallos:
		_fallos_seguidos = 0
		_despues(0.6, _dar_ayuda.bind(gota))
	_actualizar_depuracion()
	return "gris" if clave == "gris" else "no_es_este"


## Nicole: tras varios "todavia no" seguidos, la gota y su charco brillan y Cometa da una pista.
func _dar_ayuda(gota) -> void:
	if not _puede_jugar():
		return
	if _nombrar:
		for otra in _gotas:
			if is_instance_valid(otra) and otra.color_id == _color_pedido:
				otra.brillar(2.0)
		_decir_pedido()
		return
	if gota == null or not is_instance_valid(gota):
		return
	gota.brillar(2.0)
	var charco = charco_correcto_para(gota)
	if charco != null:
		charco.brillar(2.0)
	_reproducir_voz("ayuda", _linea("ayuda"))


## Maxi quieto un rato: la gota da un saltito y brilla (nunca voz insistente).
func _ayuda_por_inactividad() -> void:
	for gota in gotas_activas():
		gota.saltito()
		gota.brillar(1.5)
		var charco = charco_correcto_para(gota)
		if charco != null:
			charco.brillar(1.5)
		reproducir_sfx(SFX_TOQUE)
		return


## Brillo que llama (Maxi z3): el charco del color de la gota en pantalla brilla.
func _actualizar_llamada() -> void:
	if not _charco_llama:
		return
	var colores: Array = []
	for gota in _gotas:
		if is_instance_valid(gota):
			colores.append(gota.color_id)
	for charco in _charcos:
		if is_instance_valid(charco):
			charco.llamando = colores.has(charco.color_id)


## Nicole z3 (y entre tandas): los charcos cambian de lugar con una vuelta suave.
func _mover_charcos() -> void:
	if _charcos.size() < 2:
		return
	var lugares: Array = []
	for charco in _charcos:
		lugares.append(charco.position)
	var nuevos := lugares.duplicate()
	for intento in 6:
		nuevos.shuffle()
		if nuevos != lugares:
			break
	reproducir_sfx(SFX_MOVER)
	for i in _charcos.size():
		var charco: CharcoClasificar = _charcos[i]
		var desde: Vector2 = lugares[i]
		var hasta: Vector2 = nuevos[i]
		var tween := charco.create_tween()
		tween.tween_method(func(t: float) -> void:
			charco.position = desde.lerp(hasta, t) + Vector2(0, -70.0 * sin(PI * t))
			charco.rotation = sin(TAU * t) * 0.08
		, 0.0, 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _charcos_moviles and not _bailan_dicho:
		_bailan_dicho = true
		_reproducir_voz("charcos_bailan", _linea("charcos_bailan"), true)


# ---------------------------------------------------------------------------
# Derrota-gag, reintento, regalo y pistas
# ---------------------------------------------------------------------------

## Nicole: las gotas vuelan hacia Coco, que se tine de todos los colores y estornuda un arcoiris.
## Sofia: los charcos se desbordan y salpican todo el tablero, Coco incluida, que se sacude riendo.
func _disparar_derrota_gag() -> void:
	_derrota_disparada = true
	_derrotas += 1
	_en_gag = true
	nivel_fallado.emit()
	reproducir_sfx(SFX_GAG)
	_reproducir_voz("derrota_gag", _linea("derrota_gag"), true)
	_gota_elegida = null
	var colores: Array = []
	for gota in _gotas:
		if is_instance_valid(gota):
			gota.cancelar_arrastre()
			gota.bloqueada = true
			gota.elegida = false
			colores.append(gota.color)
			# La gota no se pierde: vuelve a la cola de la tanda para el reintento.
			if _modo != "mezcla" and not _nombrar:
				_cola.push_front({"color": gota.color_id, "tipo": gota.tipo})
	if _nombrar and _color_pedido != "":
		_cola.push_front({"color": _color_pedido, "tipo": "normal"})
		if _charco_objetivo != null:
			_charco_objetivo.llamando = false
	if obtener_perfil_dificultad() == "brote":
		_gag_estornudo(colores)
	else:
		_gag_pintura()
	_gotas.clear()
	_despues(1.6, func() -> void:
		_boton_otra_vez.show()
		_boton_otra_vez.pivot_offset = _boton_otra_vez.size / 2.0
		_boton_otra_vez.scale = Vector2.ZERO
		_boton_otra_vez.create_tween().tween_property(_boton_otra_vez, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_actualizar_depuracion()


func _gag_estornudo(colores: Array) -> void:
	var cabeza := _anfitriona.get_global_rect().get_center() + Vector2(10, -60)
	for gota in _gotas:
		if is_instance_valid(gota):
			gota.saltar_a(cabeza, func() -> void: pass, 180.0)
	if colores.is_empty():
		colores = [_color("rosado"), _color("celeste"), _color("amarillo")]
	var tween := _anfitriona.create_tween()
	for i in 6:
		tween.tween_property(_anfitriona, "modulate", colores[i % colores.size()].lerp(Color.WHITE, 0.35), 0.16)
	tween.tween_callback(func() -> void:
		_reaccion_anfitriona("salta")
		_estornudo_arcoiris(cabeza))
	tween.tween_interval(1.4)
	tween.tween_property(_anfitriona, "modulate", Color.WHITE, 0.6)


func _estornudo_arcoiris(origen: Vector2) -> void:
	var arco := Control.new()
	arco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efectos.add_child(arco)
	arco.size = _efectos.size
	var estado := {"avance": 0.0}
	# Arco grande que sale de la cabeza de Coco y cruza el tablero.
	arco.draw.connect(func() -> void:
		var centro := origen + Vector2(330, 220)
		var inicio := (origen - centro).angle()
		for i in Figura.COLORES_ARCOIRIS.size():
			arco.draw_arc(centro, 398.0 - i * 22.0, inicio, inicio + (TAU - 0.25 - inicio) * estado["avance"], 64, Figura.COLORES_ARCOIRIS[i], 22.0, true))
	var tween := arco.create_tween()
	tween.tween_method(func(v: float) -> void:
		estado["avance"] = v
		arco.queue_redraw()
	, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(arco, "modulate:a", 0.0, 0.8).set_delay(0.9)
	tween.tween_callback(arco.queue_free)
	_estallido(origen + Vector2(40, 0), 10, Figura.COLORES_ARCOIRIS, 1.4)


func _gag_pintura() -> void:
	for gota in _gotas:
		if is_instance_valid(gota):
			gota.irse(false)
	var coco := _anfitriona.get_global_rect()
	for charco in _charcos:
		if not is_instance_valid(charco):
			continue
		var colores: Array = [charco.color_resultado if charco.es_mezcla else charco.color]
		for componente in charco.recibidos:
			colores.append(_color(componente))
		charco.salpicar(colores[0])
		for i in 7:
			var hacia_coco := i < 3
			var destino := coco.position + Vector2(randf_range(30, coco.size.x - 30), randf_range(40, coco.size.y - 60)) if hacia_coco \
				else Vector2(randf_range(260, 1120), randf_range(130, 520))
			_gota_voladora(charco.centro_charco(), destino, colores[i % colores.size()], hacia_coco)
	_reaccion_anfitriona("rie")


## Manchita de pintura que vuela y, si cae en Coco, queda pegada hasta el reintento.
func _gota_voladora(desde: Vector2, hasta: Vector2, tinta: Color, en_coco: bool) -> void:
	var mancha := Control.new()
	mancha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mancha.size = Vector2.ONE * 40.0
	mancha.pivot_offset = mancha.size / 2.0
	_efectos.add_child(mancha)
	mancha.global_position = desde - mancha.size / 2.0
	mancha.draw.connect(func() -> void:
		mancha.draw_circle(mancha.size / 2.0, 16.0, tinta)
		mancha.draw_arc(mancha.size / 2.0, 16.0, 0.0, TAU, 20, COLOR_CONTORNO, 3.0, true))
	var tween := mancha.create_tween()
	tween.tween_method(func(t: float) -> void:
		mancha.global_position = desde.lerp(hasta, t) + Vector2(0, -160.0 * 4.0 * t * (1.0 - t)) - mancha.size / 2.0
	, 0.0, 1.0, randf_range(0.45, 0.7))
	tween.tween_callback(func() -> void:
		if en_coco:
			_manchas.append({"p": hasta - _anfitriona.global_position, "r": randf_range(12.0, 22.0), "c": tinta})
			_manchas_coco.modulate.a = 1.0
			_manchas_coco.queue_redraw()
		else:
			_estallido(hasta, 4, [tinta], 0.6))
	tween.tween_property(mancha, "scale", Vector2(1.6, 0.5), 0.08)
	tween.tween_property(mancha, "modulate:a", 0.0, 0.5 if not en_coco else 0.1)
	tween.tween_callback(mancha.queue_free)


func _dibujar_manchas_coco() -> void:
	for mancha in _manchas:
		var centro: Vector2 = mancha["p"]
		var radio: float = mancha["r"]
		_manchas_coco.draw_circle(centro, radio, mancha["c"])
		for k in 3:
			_manchas_coco.draw_circle(centro + Vector2.from_angle(k * 2.1) * radio * 0.95, radio * 0.35, mancha["c"])
		_manchas_coco.draw_arc(centro, radio, 0.0, TAU, 20, Color(COLOR_CONTORNO, 0.5), 2.0, true)


func _reintentar() -> void:
	if not _en_gag:
		return
	_boton_otra_vez.hide()
	_en_gag = false
	# Mismo criterio que emparejar/encajar (M-QA1): el contador de la tanda vuelve a cero para dar
	# ritmo, pero el bono queda anulado para toda la partida (`_derrota_disparada`).
	_fallos_ronda = 0
	_fallos_seguidos = 0
	reproducir_sfx(SFX_TOQUE)
	var tween := _manchas_coco.create_tween()
	tween.tween_property(_manchas_coco, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		_manchas.clear()
		_manchas_coco.queue_redraw())
	_anfitriona.modulate = Color.WHITE
	_reaccion_anfitriona("salta")
	_espera_spawn = 0.3
	_reponer()
	# Tras 2 derrotas, Coco regala un acierto (no cuesta estrellita): nunca queda trabada.
	if _derrotas >= 2 and _regalo and not _regalo_dado:
		_regalo_dado = true
		_despues(0.8, _regalar)
	_actualizar_depuracion()


func _regalar() -> void:
	if not _puede_jugar():
		return
	if _modo == "mezcla":
		for charco in _charcos:
			if is_instance_valid(charco) and not charco.resuelto:
				charco.recibidos = charco.receta.duplicate()
				_reproducir_voz("regalo", _linea("regalo"), true)
				_mezcla_lograda(charco)
				return
		return
	for gota in gotas_activas():
		if _nombrar and gota.color_id == _color_pedido:
			_reproducir_voz("regalo", _linea("regalo"), true)
			_acierto_nombrar(gota)
			return
		var charco = charco_correcto_para(gota)
		if charco != null and not _nombrar:
			_reproducir_voz("regalo", _linea("regalo"), true)
			_acierto(gota, charco)
			return


func _crear_boton_pista() -> void:
	_boton_pista = Button.new()
	_boton_pista.focus_mode = Control.FOCUS_NONE
	_boton_pista.tooltip_text = "Pista: muestra una receta (cuesta una estrellita)"
	_boton_pista.custom_minimum_size = Vector2(96, 96)
	var padre: Control = _boton_salir.get_parent()
	padre.add_child(_boton_pista)
	padre.move_child(_boton_pista, _efectos.get_index())
	_boton_pista.position = Vector2(1164, 16)
	_boton_pista.size = Vector2(96, 96)
	_estilizar_boton(_boton_pista, DORADO)
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_pista.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(func() -> void:
		var c := icono.size / 2.0
		Figura.dibujar(icono, "estrella", Color("#FFF3B0"), c + Vector2(0, 3), 30.0, false)
		for p in [Vector2(-30, -26), Vector2(30, -22), Vector2(26, 30)]:
			var chispa := Figura.poligono("estrella", c + p, 8.0)
			icono.draw_colored_polygon(chispa, Color.WHITE)
			Figura.contornear(icono, chispa, 2.0))
	_boton_pista.pressed.connect(_al_tocar_pista)
	_boton_pista.hide()


## Pista de Sofia: la receta de un pedido se ve un momento y brilla una gota que sirve. Cuesta
## una estrellita (sin bajar de 1).
func _al_tocar_pista() -> void:
	if not _puede_jugar():
		return
	reproducir_sfx(SFX_TOQUE)
	var objetivo = null
	for charco in _charcos:
		if is_instance_valid(charco) and not charco.resuelto:
			objetivo = charco
			break
	if objetivo == null:
		return
	objetivo.receta_visible_hasta = _ahora() + 3.5
	objetivo.brillar(3.5)
	var faltan: Array = objetivo.faltantes()
	var marcada := false
	for gota in gotas_activas():
		if faltan.has(gota.color_id):
			gota.brillar(3.5)
			marcada = true
			break
	if not marcada and not faltan.is_empty():
		var gota := _crear_gota(faltan.pick_random())
		gota.casa = _lugar_para_gota(gota)
		gota.fijar_centro(gota.casa)
		gota.aparecer()
		gota.brillar(3.5)
	_pistas_usadas += 1
	_reproducir_voz("pista_usada", _linea("pista_usada"), true)
	var estrella := Figura.new()
	estrella.figura = "estrella"
	estrella.con_cara = false
	estrella.color = DORADO
	estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estrella.size = Vector2.ONE * 46.0
	estrella.pivot_offset = estrella.size / 2.0
	_efectos.add_child(estrella)
	estrella.global_position = _boton_pista.global_position + Vector2(25, 25)
	var tween := estrella.create_tween().set_parallel(true)
	tween.tween_property(estrella, "position:y", estrella.position.y + 90.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(estrella, "rotation", 1.6, 0.9)
	tween.tween_property(estrella, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(estrella.queue_free)
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Victoria y puntaje
# ---------------------------------------------------------------------------

func _celebrar_victoria() -> void:
	if _terminado:
		return
	_terminado = true
	_confeti.restart()
	_reaccion_anfitriona("baila")
	var espera := 1.2
	if _modo == "mezcla":
		# Momento memorable de Sofia: el tablero se ilumina con un mural arcoiris + dato final.
		_mural_arcoiris()
		var ruta := _linea("dato_final")
		_reproducir_voz("dato_final", ruta, true)
		espera = clampf(_duracion_voz(ruta) + 0.4, 1.5, 9.0)
	else:
		_arcoiris_especial()
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree():
		return
	celebrar(_calcular_destellos(), _calcular_estrellitas(), _linea_al_azar("victoria_final"))


## Estrellitas del perfil Estrella (1-3). Umbrales por nivel (`umbrales_estrellitas`: fallos
## totales para 3 y para 2), PROVISIONALES hasta que `disenador-niveles` los valide. Tras
## derrota-gag -> 1. Con reloj amable, tambien cuenta cuantos pedidos salieron a tiempo. Cada pista
## resta una. Ganar siempre da al menos 1.
func _calcular_estrellitas() -> int:
	var base := 3
	if _derrota_disparada:
		base = 1
	elif not _umbrales.is_empty():
		if _fallos_total <= int(_umbrales.get("tres", 0)):
			base = 3
		elif _fallos_total <= int(_umbrales.get("dos", 0)):
			base = 2
		else:
			base = 1
	if _pedidos_con_reloj > 0:
		var fraccion := _a_tiempo / float(_pedidos_con_reloj)
		var por_reloj := 3 if fraccion >= 0.8 else (2 if fraccion >= 0.4 else 1)
		base = mini(base, por_reloj)
	return maxi(1, base - _pistas_usadas)


func _calcular_destellos() -> int:
	var total := (_aciertos - _mezclas) * DESTELLOS_POR_GOTA + _mezclas * DESTELLOS_POR_MEZCLA
	if _limite != null and not _derrota_disparada:
		total += _tandas_limpias * DESTELLOS_TANDA_LIMPIA
	return maxi(total, 1)


# ---------------------------------------------------------------------------
# API para arneses QA
# ---------------------------------------------------------------------------

func gotas_activas() -> Array:
	var lista: Array = []
	for gota in _gotas:
		if is_instance_valid(gota) and not gota.bloqueada:
			lista.append(gota)
	return lista


func charcos_activos() -> Array:
	return _charcos.filter(func(c) -> bool: return is_instance_valid(c))


## El charco donde esta gota es un acierto (null en modo libre o si no hay).
func charco_correcto_para(gota):
	if gota == null or not is_instance_valid(gota):
		return null
	for charco in _charcos:
		if not is_instance_valid(charco):
			continue
		if _nombrar:
			if gota.color_id == _color_pedido:
				return _charco_objetivo
			continue
		if charco.es_mezcla:
			if not charco.resuelto and charco.faltantes().has(gota.color_id) and gota.tipo != "gris":
				return charco
		elif charco.color_id == gota.color_id:
			return charco
	return null


func tocar_gota(gota) -> void:
	_al_tocar_gota(gota)


func tocar_charco(charco) -> void:
	_al_tocar_charco(charco)


func esta_esperando() -> bool:
	return _en_transicion or _en_gag or _terminado


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


func _voz_color(id: String) -> String:
	var prefijo := _linea("prefijo_colores")
	return prefijo + id + ".wav" if prefijo != "" else ""


## Las voces cortas (aciertos) nunca cortan una importante (intro, pedido, dato curioso, gag).
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


## Tocar a Cometa repite la instruccion (GDD §6.2). En Nicole z5 repite el color pedido.
func _al_tocar_cometa() -> void:
	reproducir_sfx(SFX_TOQUE)
	_inactivo = 0.0
	if _nombrar and _color_pedido != "" and _puede_jugar():
		_decir_pedido()
		return
	_reproducir_voz("pista", _linea("pista"), true)
	if _modo == "libre" and _puede_jugar():
		_ayuda_por_inactividad()


func _al_tocar_anfitriona(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not toque:
		return
	reproducir_sfx(SFX_TOQUE)
	_reaccion_anfitriona("salta")
	_reproducir_voz("intro", _linea("intro"), true)


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
		"menea":
			for angulo in [-6.0, 6.0, -3.0, 0.0]:
				tween.tween_property(_anfitriona, "rotation", deg_to_rad(angulo), 0.1)
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
		chispa.global_position = centro - chispa.size / 2.0
		var angulo := TAU * i / cantidad + randf_range(-0.3, 0.3)
		var destino := chispa.position + Vector2.from_angle(angulo) * randf_range(60.0, 110.0) * escala
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 0.55)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


## Arcoiris que cruza el tablero (bonus de Nicole, cierre de Maxi).
func _arcoiris_especial() -> void:
	var arco := Control.new()
	arco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arco.modulate.a = 0.85
	_efectos.add_child(arco)
	arco.size = _efectos.size
	var estado := {"avance": 0.0}
	arco.draw.connect(func() -> void:
		var base := Vector2(640, 720)
		for i in Figura.COLORES_ARCOIRIS.size():
			arco.draw_arc(base, 560.0 - i * 26.0, PI, PI + PI * estado["avance"], 64, Figura.COLORES_ARCOIRIS[i], 27.0, true))
	var tween := arco.create_tween()
	tween.tween_method(func(valor: float) -> void:
		estado["avance"] = valor
		arco.queue_redraw()
	, 0.0, 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(arco, "modulate:a", 0.0, 0.6).set_delay(0.6)
	tween.tween_callback(arco.queue_free)


## Maxi z5: el arcoiris del cielo, completo, crece y brilla.
func _arcoiris_gigante() -> void:
	_confeti.restart()
	_reaccion_anfitriona("baila")
	var tween := _cielo.create_tween()
	_cielo.pivot_offset = ARCO_CENTRO
	tween.tween_property(_cielo, "scale", Vector2.ONE * 1.12, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_cielo, "scale", Vector2.ONE, 0.4)
	for i in 5:
		_despues(0.2 * i, func() -> void:
			_estallido(ARCO_CENTRO + Vector2.from_angle(PI + randf() * PI) * randf_range(200, 380), 10, Figura.COLORES_ARCOIRIS, 1.5))
	_despues(2.0, func() -> void:
		var apaga := _cielo.create_tween()
		apaga.tween_property(_cielo, "modulate:a", 0.0, 0.4)
		apaga.tween_callback(func() -> void:
			for i in _avance_bandas.size():
				_avance_bandas[i] = 0.0
			_cielo.modulate.a = 1.0
			_cielo.queue_redraw()))


## Sofia, final: mural arcoiris que ilumina todo el tablero, con manchas de pintura de sus mezclas.
func _mural_arcoiris() -> void:
	var mural := Control.new()
	mural.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efectos.add_child(mural)
	mural.size = _efectos.size
	var manchas: Array = []
	for i in 26:
		manchas.append({"p": Vector2(randf_range(260, 1120), randf_range(140, 560)), "r": randf_range(14, 34), "c": Figura.COLORES_ARCOIRIS[i % 6]})
	var estado := {"avance": 0.0}
	mural.draw.connect(func() -> void:
		var base := Vector2(690, 640)
		var colores := [_color("rojo"), _color("naranja"), _color("amarillo"), _color("verde"), _color("azul"), Color("#5B4BC4"), _color("violeta")]
		for i in colores.size():
			mural.draw_arc(base, 470.0 - i * 30.0, PI, PI + PI * estado["avance"], 72, colores[i], 30.0, true)
		for k in manchas.size():
			if k / float(manchas.size()) < estado["avance"]:
				mural.draw_circle(manchas[k]["p"], manchas[k]["r"], manchas[k]["c"])
				mural.draw_arc(manchas[k]["p"], manchas[k]["r"], 0.0, TAU, 20, COLOR_CONTORNO, 3.0, true))
	var tween := mural.create_tween()
	tween.tween_method(func(v: float) -> void:
		estado["avance"] = v
		mural.queue_redraw()
	, 0.0, 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.5)
	tween.tween_property(mural, "modulate:a", 0.0, 0.8)
	tween.tween_callback(mural.queue_free)


## Sorpresa de Maxi: la salpicadura forma un dinosaurio de pintura que ruge bajito y se hace chispas.
func _dino_de_pintura(centro: Vector2, tinta: Color) -> void:
	var dino := Control.new()
	dino.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dino.size = Vector2(240, 200)
	dino.pivot_offset = Vector2(120, 190)
	_efectos.add_child(dino)
	dino.global_position = centro - Vector2(120, 150)
	var cuerpo := tinta if tinta.get_luminance() < 0.85 else _color("verde")
	dino.draw.connect(func() -> void:
		var c := Vector2(110, 120)
		var contorno := func(forma: PackedVector2Array) -> void:
			dino.draw_colored_polygon(forma, cuerpo)
			Figura.contornear(dino, forma, 4.0)
		# Cola, patas, cuerpo, cuello y cabeza de T-rex (manchas de pintura redonditas).
		contorno.call(PackedVector2Array([c + Vector2(-40, -10), c + Vector2(-105, 25), c + Vector2(-40, 25)]))
		for x in [-18.0, 22.0]:
			contorno.call(_elipse(c + Vector2(x, 48), Vector2(14, 26)))
		contorno.call(_elipse(c, Vector2(56, 40)))
		contorno.call(_elipse(c + Vector2(48, -44), Vector2(22, 30)))
		contorno.call(_elipse(c + Vector2(72, -70), Vector2(40, 26)))
		for k in 4:
			var p := c + Vector2(-30 + k * 22, -38 - (k % 2) * 4)
			contorno.call(PackedVector2Array([p + Vector2(-10, 4), p + Vector2(0, -16), p + Vector2(10, 4)]))
		dino.draw_line(c + Vector2(42, -8), c + Vector2(58, 4), COLOR_CONTORNO, 5.0, true)
		dino.draw_circle(c + Vector2(80, -78), 6.0, COLOR_CONTORNO)
		dino.draw_circle(c + Vector2(78, -80), 2.2, Color.WHITE)
		dino.draw_arc(c + Vector2(88, -62), 12.0, 0.2, 2.2, 10, COLOR_CONTORNO, 3.5, true)
		dino.draw_circle(c + Vector2(-8, -6), 10.0, Color(1, 1, 1, 0.35)))
	dino.scale = Vector2(0.2, 0.2)
	var tween := dino.create_tween()
	tween.tween_property(dino, "scale", Vector2(1.15, 0.85), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dino, "scale", Vector2.ONE, 0.15)
	for i in 4:
		tween.tween_property(dino, "rotation", deg_to_rad(-6.0 if i % 2 == 0 else 6.0), 0.09)
	tween.tween_property(dino, "rotation", 0.0, 0.09)
	tween.tween_interval(0.9)
	tween.tween_callback(func() -> void: _estallido(dino.global_position + Vector2(120, 110), 14, [cuerpo, DORADO, Color.WHITE], 1.5))
	tween.tween_property(dino, "modulate:a", 0.0, 0.3)
	tween.tween_callback(dino.queue_free)
	reproducir_sfx(SFX_GAG)


func _elipse(centro: Vector2, radios: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 24:
		var angulo := TAU * i / 24.0
		puntos.append(centro + Vector2(cos(angulo) * radios.x, sin(angulo) * radios.y))
	return puntos


# ---------------------------------------------------------------------------
# Dibujo del cielo (arcoiris de Maxi z5) y de la barra de progreso
# ---------------------------------------------------------------------------

func _dibujar_cielo() -> void:
	if not _arcoiris_cielo:
		return
	for i in BANDAS_ARCOIRIS.size():
		var radio := ARCO_RADIO - i * ARCO_ANCHO
		var avance: float = _avance_bandas[i] if i < _avance_bandas.size() else 0.0
		# Franja por pintar: fantasmita punteado para que se vea que falta.
		for k in 24:
			if k % 2 == 0:
				_cielo.draw_arc(ARCO_CENTRO, radio, PI + PI * k / 24.0, PI + PI * (k + 1) / 24.0, 4, Color(1, 1, 1, 0.35), ARCO_ANCHO - 8.0, true)
		if avance > 0.0:
			_cielo.draw_arc(ARCO_CENTRO, radio, PI, PI + PI * avance, 64, _color(BANDAS_ARCOIRIS[i]), ARCO_ANCHO - 2.0, true)
	_cielo.draw_arc(ARCO_CENTRO, ARCO_RADIO + ARCO_ANCHO / 2.0, PI, TAU, 64, Color(COLOR_CONTORNO, 0.5), 3.0, true)
	for lado in [-1.0, 1.0]:
		var nube := ARCO_CENTRO + Vector2(lado * (ARCO_RADIO - ARCO_ANCHO * 2.5), 0)
		for k in 3:
			_cielo.draw_circle(nube + Vector2((k - 1) * 46.0, -12.0 * (1 - absf(k - 1))), 44.0, Color("#FFF8EE"))
		Figura.dibujar_cara(_cielo, nube + Vector2(0, -6), 60.0, true)


## Barra de la tanda: una gotita por acierto que falta (se llena con su color) y una estrella por
## tanda (llena las tandas ya hechas). Sin numeros ni texto.
func _dibujar_barra() -> void:
	var lado := 44.0 if _meta_ronda <= 9 else 32.0
	var ancho_gotas := _meta_ronda * (lado + 6.0)
	var ancho_rondas := _numero_rondas * 30.0
	var ancho := ancho_gotas + ancho_rondas + 60.0
	var caja := Rect2(Vector2(640.0 - ancho / 2.0, 20.0), Vector2(ancho, 70.0))
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.23, 0.16, 0.42, 0.55)
	estilo.border_color = Color(1, 1, 1, 0.4)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(35)
	_barra.draw_style_box(estilo, caja)
	var x := caja.position.x + 24.0 + lado / 2.0
	var y := caja.get_center().y
	for i in _meta_ronda:
		var centro := Vector2(x + i * (lado + 6.0), y)
		if i < _colores_barra.size():
			Figura.dibujar(_barra, "gota", _colores_barra[i], centro, lado * 0.46, false)
		else:
			_barra.draw_circle(centro, lado * 0.3, Color(1, 1, 1, 0.22))
			_barra.draw_arc(centro, lado * 0.3, 0.0, TAU, 20, Color(1, 1, 1, 0.7), 2.5, true)
	var x_rondas := caja.position.x + 36.0 + ancho_gotas + 15.0
	for r in _numero_rondas:
		var centro := Vector2(x_rondas + r * 30.0, y)
		var estrella := Figura.poligono("estrella", centro, 13.0)
		var hecha := r < _ronda or (r == _ronda and _en_transicion and _logrados_ronda >= _meta_ronda)
		_barra.draw_colored_polygon(estrella, DORADO if hecha else Color(1, 1, 1, 0.25 if r > _ronda else 0.55))
		Figura.contornear(_barra, estrella, 2.0)


func _actualizar_depuracion() -> void:
	if _panel_depuracion == null or not _panel_depuracion.visible:
		return
	var limite := "sin limite" if _limite == null else str(_limite)
	_panel_depuracion.text = "DEPURACION (F3)\nnivel: %s\nperfil: %s · juega: %s · modo: %s\ntanda: %d de %d · logrados: %d de %d\nfallos tanda: %d / %s · total: %d\nderrota-gag: %d · pistas: %d\na tiempo: %d de %d\nsi termina ahora: %d destellos, %d estrellitas" % [
		nivel.get("id_nivel", "?"), obtener_perfil_dificultad(), obtener_id_personaje(), _modo,
		_ronda + 1, _numero_rondas, _logrados_ronda, _meta_ronda, _fallos_ronda, limite, _fallos_total,
		_derrotas, _pistas_usadas, _a_tiempo, _pedidos_con_reloj, _calcular_destellos(), _estrellitas_visibles(_calcular_estrellitas())]


func _estilizar_interfaz() -> void:
	_estilizar_boton(_boton_salir, Color("#FFF8EE"))
	_estilizar_boton(_boton_cometa, Color("#CFF5F1"))
	_estilizar_boton(_boton_otra_vez, DORADO)
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_salir.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(_dibujar_flecha.bind(icono))
	if ResourceLoader.exists(RUTA_FUENTE):
		var fuente: Font = load(RUTA_FUENTE)
		_boton_otra_vez.add_theme_font_override("font", fuente)
		_panel_depuracion.add_theme_font_override("font", fuente)
	_boton_otra_vez.add_theme_font_size_override("font_size", 46)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_boton_otra_vez.add_theme_color_override(estado, COLOR_CONTORNO)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(COLOR_CONTORNO, 0.85)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(12)
	_panel_depuracion.add_theme_stylebox_override("normal", panel)
	_panel_depuracion.add_theme_color_override("font_color", Color("#FFF8EE"))
	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	degradado.colors = PackedColorArray(Figura.COLORES_ARCOIRIS)
	_confeti.color_initial_ramp = degradado


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
