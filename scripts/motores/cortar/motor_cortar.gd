extends MinijuegoBase

## Motor `cortar` (docs/fichas/batalla-animalia.md §5; HE-121): «La Gran Burbujeada», el jefe de la batalla de
## Animalia. Mecanica de Fruit Ninja: el Coleccionauta sopla burbujas con animales del desfile que vuelan en
## PARABOLAS CALCULADAS (LogicaCortar, sin motor de fisica, GDD §8) y el equipo las revienta con el trazo del dedo
## (interseccion segmento-circulo entre muestras: un trazo rapido no "salta" burbujas) o con un toque. Bomba = el
## calcetin; bananas de Arcade = burbuja de la siesta (Freeze) y burbuja trompeta (Frenzy); Zen = la ruta de Maxi.
##
## Patron de la Torre (motor-lanzar): `GestorTurnos` en modo SIN PISTA (`rival: null`), los frascos de jabon como
## reloj de la oleada (9 = M5 N2 S2; 13 = M7 N3 S3 desde la 1.a derrota de esa oleada), cada intento y cada oleada
## empiezan con Maxi y la ultima tanda es suya, 3 oleadas seguidas (una por piso de la mochila), guardado parcial en
## turno_cerrado, tras cada gag, al empezar cada oleada y en el cuadro en que se vacia cada piso, derrota-gag
## orquestada por la base con 3 gags que rotan, ayudas escalonadas y revancha. El motor nunca toca el guardado ni
## navega: emite `parcial_equipo_listo`, los momentos saltables y `completado(0)`.

signal liberado(id_animal: String, indice_en_trazo: int)
signal escapo(id_animal: String)
signal calcetin_reventado(perfil: String)
signal combo(n: int)
signal piso_vaciado(oleada: int)

const RECT_CASA := Rect2(1172, 8, 100, 96)
const SALIDA_LIBERADOS := Vector2(60, 560)
const TOBY_PIES := Vector2(78, 600)
const CONTORNO := Color("#2B3350")
const COLOR_SOLO := Color("#FFD23F")
const SFX := {
	"tik": "res://assets/audio/sfx/ui/toque.ogg",
	"pop": "res://assets/audio/sfx/ui/blup.ogg",
	"plip": "res://assets/audio/sfx/ui/confirmar.ogg",
	"campanita": "res://assets/audio/sfx/ui/seleccionar.ogg",
	"sluuurp": "res://assets/audio/sfx/ui/rebobinar.ogg",
	"fff": "res://assets/audio/sfx/ui/puf.ogg",
	"plof": "res://assets/audio/sfx/ui/puf.ogg",
	"fiu": "res://assets/audio/sfx/ui/fiuu.ogg",
	"pomp": "res://assets/audio/sfx/ui/cerrar.ogg",
}

## Solo arneses: multiplica las esperas y animaciones del motor (momentos, gags, pops). 1.0 en el juego.
var escala_tiempo := 1.0
## Solo arneses: acelera el reloj de las burbujas y de la tanda (1.0 en el juego).
var acelerar_qa := 1.0
## Voces pedidas (clave o clave:sub), existan o no los archivos: para el arnes.
var voces_dichas: Array[String] = []

var coleccionauta: ColeccionautaCortar
var toby: TobyCortar
var _fondo: Node2D
var _desfile_nodo: Node2D
var _pasto: Node2D
var _capa_burbujas: Node2D
var _efectos_nodo: Node2D
var _ui: Control
var _boton_casa: Button
var _rng := RandomNumberGenerator.new()
var _menos_movimiento := false

# --- Nivel y composicion ---
var _zona := Rect2(140, 110, 1000, 490)
var _pasto_y := 610.0
var _boca := ColeccionautaCortar.BOCA
var _oleadas: Array = []
var _clave := ""
var _semilla_id := ""
var _frascos_valores: Array = [9, 13]
var _retomar_valores: Array = [5, 9, 13]
var _quien_empezo := ""

# --- Estado de la oleada (lo que se guarda, §5.7) ---
var _idx := 0
var _oleada: Dictionary = {}
var _meta := 0
var _pool: Dictionary = {}
var _liberados: Array = []
var _oleadas_ganadas: Array = []
var _oleada_iniciada := false
var _intento := 1
var _derrotas_oleada := 0
var _derrotas := 0
var _ultimo_gag := ""
var _gag_actual := ""
var _frascos := 9
var _canasta := 9
var _toby_ayudo := false
var _siesta_usada := false
var _trompeta_usada := false
var _calcetin_presentado := false
var _presentacion_vista := false
var _liberados_al_perder := 0
var _intento_nuevo_listo := true

# --- Revancha (acumulados entre oleadas, §5.8) ---
var _rev_frascos_usados := 0
var _rev_sobrantes: Array = []
var _rev_derrotas := 0

# --- Tanda ---
var _fase := "espera"     # espera | tanda | fin_oleada | victoria | derrota
var _perfil_turno := ""
var _id_turno := ""
var _cfg: Dictionary = {}
var _cola: Array = []
var _t_tanda := 0.0
var _cola_pausada := false
var _burbujas: Array = []
var _corte_calcetin := false
var _siesta_t := 0.0
var _escapes := 0
var _turnos_perfil := {}
var _maxi_pedido := Vector2.INF
var _calcetin_presentacion: BurbujaCortar = null

# --- Trazo (un solo dedo) ---
var _dedo := -1
var _ultimo_punto := Vector2.ZERO
var _pops_trazo := 0
var _animales_trazo := 0
var _combo_dado := false
var _estela: Array = []
var _estela_dorada := false

# --- Efectos y desfile ---
var _efectos: Array = []
var _corredores: Array = []
var _desfile: Array = []
var _desfile_todos := false
var _t_vida := 0.0
var _tweens: Array[Tween] = []

# --- Frontera entre oleadas y retomar ---
var _en_frontera := false
var _foto_frontera: Dictionary = {}
var _restaurado := false
var _frascos_agregados := false


func _ready() -> void:
	super._ready()
	if nivel.is_empty():
		return
	for e in LogicaCortar.validar_nivel(nivel):
		push_error("motor_cortar: " + e)
	_oleadas = nivel.get("oleadas", [])
	_zona = LogicaCortar.zona_juego(nivel)
	_pasto_y = float(nivel.get("pasto_y", 610))
	_boca = _vec(nivel.get("boca_rival", [1160, 300]), ColeccionautaCortar.BOCA)
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.has_method("menos_movimiento"):
		_menos_movimiento = bool(progreso.menos_movimiento())
	if revancha:
		_presentacion_vista = true
	_crear_escena()
	_resolver_composicion()
	_armar_oleada(0)
	if turnos != null:
		var perfiles := {}
		for id in equipo:
			perfiles[id] = perfil_de(id)
		turnos.configurar(equipo, _config_gestor(), perfiles, _ui)
		var capa := _ui.get_node_or_null("capa_equipo")
		if capa != null:
			_ui.move_child(capa, 0)
		turnos.turno_iniciado.connect(_al_turno_iniciado)
		turnos.jugada_automatica_pedida.connect(_jugada_automatica)
	_arrancar.call_deferred()


# ---------------------------------------------------------------------------
# Escena (arte provisional por codigo; HE-114 trae el arte)
# ---------------------------------------------------------------------------

func _crear_escena() -> void:
	_fondo = _nodo_dibujo("fondo", -10, _dibujar_fondo)
	_desfile_nodo = _nodo_dibujo("desfile", -6, _dibujar_desfile)
	_capa_burbujas = Node2D.new()
	_capa_burbujas.name = "burbujas"
	add_child(_capa_burbujas)
	coleccionauta = ColeccionautaCortar.new()
	coleccionauta.name = "coleccionauta"
	coleccionauta.z_index = 1
	add_child(coleccionauta)
	_pasto = _nodo_dibujo("pasto", 2, _dibujar_pasto)
	toby = TobyCortar.new()
	toby.name = "toby"
	toby.position = TOBY_PIES
	toby.z_index = 3
	add_child(toby)
	_efectos_nodo = _nodo_dibujo("efectos", 5, _dibujar_efectos)
	var capa := CanvasLayer.new()
	capa.name = "capa_ui"
	capa.layer = 1
	add_child(capa)
	_ui = Control.new()
	_ui.name = "ui"
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.size = Vector2(1280, 720)
	capa.add_child(_ui)
	_boton_casa = Button.new()
	_boton_casa.name = "boton_casa"
	_boton_casa.focus_mode = Control.FOCUS_NONE
	_boton_casa.position = RECT_CASA.position
	_boton_casa.size = RECT_CASA.size
	_boton_casa.pivot_offset = RECT_CASA.size / 2.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFF4D6")
	estilo.border_color = CONTORNO
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(26)
	for nombre in ["normal", "hover", "pressed", "focus"]:
		_boton_casa.add_theme_stylebox_override(nombre, estilo)
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icono.size = RECT_CASA.size
	icono.draw.connect(func() -> void:
		var c := icono.size / 2.0
		icono.draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -2), c + Vector2(0, -28), c + Vector2(30, -2)]), Color("#F0453A"))
		icono.draw_rect(Rect2(c + Vector2(-22, -2), Vector2(44, 30)), Color("#FFD23F"))
		icono.draw_rect(Rect2(c + Vector2(-7, 10), Vector2(14, 18)), CONTORNO))
	_boton_casa.add_child(icono)
	_boton_casa.pressed.connect(func() -> void:
		_sfx("pomp")
		salir_solicitado.emit())
	_ui.add_child(_boton_casa)


func _nodo_dibujo(nombre: String, z: int, dibujo: Callable) -> Node2D:
	var n := Node2D.new()
	n.name = nombre
	n.z_index = z
	n.draw.connect(dibujo)
	add_child(n)
	return n


## El Campamento a la tarde: cielo, cerros, la carpa de Toby, banderines del desfile y arbolitos (§11: reutiliza la
## idea del fondo de la zona 1; provisional).
func _dibujar_fondo() -> void:
	for i in 12:
		var t := float(i) / 11.0
		_fondo.draw_rect(Rect2(0, i * 60, 1280, 61), Color("#8FD3FF").lerp(Color("#FFE9B8"), t))
	_fondo.draw_circle(Vector2(980, 120), 46, Color("#FFF1A8"))
	for k in 5:
		_fondo.draw_circle(Vector2(120 + k * 280, 640), 260, Color("#9BD77A").darkened(0.05 * (k % 2)))
	# Carpa de Toby a rayas.
	var base := Vector2(330, 470)
	for k in 6:
		var x0 := base.x - 120 + k * 40
		_fondo.draw_colored_polygon(PackedVector2Array([Vector2(base.x, 300), Vector2(x0, base.y), Vector2(x0 + 40, base.y)]),
			Color("#F0453A") if k % 2 == 0 else Color("#FFF4D6"))
	_fondo.draw_line(Vector2(base.x, 300), Vector2(base.x, 270), CONTORNO, 4.0)
	_fondo.draw_colored_polygon(PackedVector2Array([Vector2(base.x, 270), Vector2(base.x + 30, 280), Vector2(base.x, 290)]), Color("#3FCB5A"))
	# Arbolitos.
	for x in [620.0, 760.0, 1080.0]:
		_fondo.draw_rect(Rect2(x - 8, 420, 16, 70), Color("#9C6B3E"))
		_fondo.draw_circle(Vector2(x, 405), 48, Color("#5BC45A"))
	# Banderines del desfile.
	var colores := [Color("#F0453A"), Color("#FFD23F"), Color("#3F8CFF"), Color("#3FCB5A"), Color("#FF9ED6")]
	for k in 18:
		var x := 150.0 + k * 55.0
		var y := 118.0 + sin(float(k) / 17.0 * PI) * 26.0
		_fondo.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 40, y + 3), Vector2(x + 20, y + 34)]), colores[k % colores.size()])
	_fondo.draw_polyline(PackedVector2Array([Vector2(140, 116), Vector2(640, 146), Vector2(1140, 118)]), CONTORNO, 2.0, true)


## La mini fila del desfile que cruza por detras del pasto con los liberados (§5.2).
func _dibujar_desfile() -> void:
	var lista: Array = _desfile
	var n := mini(lista.size(), 26)
	for k in n:
		var id := str(lista[lista.size() - 1 - k])
		var x := fposmod(_t_vida * 34.0 + k * 40.0, 1060.0) + 120.0
		var salto := absf(sin(_t_vida * 6.0 + k)) * (10.0 if _desfile_todos else 4.0)
		DibujoCortar.dibujar_animal(_desfile_nodo, id, Vector2(x, 584 - salto), 15.0)


## Pasto alto adelante (franja y 590-640): de ahi salen y ahi vuelven las burbujas.
func _dibujar_pasto() -> void:
	_pasto.draw_rect(Rect2(0, 606, 1280, 114), Color("#5BB04A"))
	for k in 70:
		var x := 120.0 + k * 15.0
		var alto := 26.0 + float((k * 37) % 17)
		var mece := sin(_t_vida * 2.0 + k * 0.7) * 4.0
		_pasto.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 612), Vector2(x + mece, 612 - alto), Vector2(x + 7, 612)]),
			Color("#4E9E3E") if k % 2 == 0 else Color("#6CC25A"))


func _dibujar_efectos() -> void:
	# Estela del trazo: estrellitas del color del hermano que se apagan en `estela_ms` (dorada con combo).
	var ahora := _ahora_ms()
	var vida := float(nivel.get("trazo", {}).get("estela_ms", 150))
	var color := _color_turno()
	if _estela_dorada:
		color = Color("#FFC94A")
	for i in range(1, _estela.size()):
		var a: Dictionary = _estela[i - 1]
		var b: Dictionary = _estela[i]
		var alfa := clampf(1.0 - float(ahora - int(b["ms"])) / vida, 0.0, 1.0)
		if alfa <= 0.0:
			continue
		_efectos_nodo.draw_line(a["p"], b["p"], Color(color, alfa), 12.0 * alfa + 3.0, true)
		if not _menos_movimiento and i % 2 == 0:
			_estrella(_efectos_nodo, b["p"], 9.0 * alfa + 3.0, Color(Color.WHITE, alfa))
	for e in _efectos:
		var u := clampf(float(e["t"]) / float(e["dur"]), 0.0, 1.0)
		match str(e["tipo"]):
			"onda":
				_efectos_nodo.draw_arc(e["pos"], 18.0 + 46.0 * u, 0, TAU, 24, Color(e["color"], 1.0 - u), 6.0, true)
			"gota":
				_efectos_nodo.draw_circle((e["pos"] as Vector2) + (e["vel"] as Vector2) * u, 6.0 * (1.0 - u) + 1.0, Color(e["color"], 1.0 - u))
			"estrellas":
				var p: Vector2 = (e["desde"] as Vector2).lerp(e["hasta"], u)
				for k in 3:
					_estrella(_efectos_nodo, p + Vector2(k * 10 - 10, sin(u * 9.0 + k) * 8.0), 10.0, Color("#FFE38A"))
			"nube":
				for k in 6:
					_efectos_nodo.draw_circle((e["pos"] as Vector2) + Vector2.from_angle(k * 1.05) * (20.0 + 40.0 * u), 18.0 * (1.0 - u) + 4.0, Color(0.92, 0.92, 0.95, 1.0 - u))
			"confeti":
				var q: Vector2 = (e["pos"] as Vector2) + (e["vel"] as Vector2) * u + Vector2(0, 160.0 * u * u)
				_efectos_nodo.draw_rect(Rect2(q, Vector2(8, 5)), Color(e["color"], 1.0 - u * 0.5))
			"frasco":
				var f: Vector2 = (e["pos"] as Vector2) + Vector2(-80.0 * u, -60.0 * sin(u * PI) + 40.0 * u)
				_efectos_nodo.draw_rect(Rect2(f, Vector2(10, 14)), Color("#9FE3FF", 1.0 - u))
			"blup":
				DibujoCortar.dibujar_burbuja(_efectos_nodo, e["pos"], 10.0 + 14.0 * u, false, 1.0 - u * 0.8)
	for c in _corredores:
		var pos: Vector2 = c["pos"]
		DibujoCortar.dibujar_animal(_efectos_nodo, str(c["id"]), pos, 26.0)
		DibujoCortar.dibujar_paraguas_hoja(_efectos_nodo, pos + Vector2(0, -34), 30.0)


func _estrella(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, color)


# ---------------------------------------------------------------------------
# Composicion, gestor y oleadas
# ---------------------------------------------------------------------------

func _resolver_composicion() -> void:
	var frascos: Dictionary = nivel.get("frascos", {})
	_frascos_valores = [int(frascos.get("intento_1", 9)), int(frascos.get("desde_derrota_1", 13))]
	_retomar_valores = (frascos.get("retomar_valores", [5, 9, 13]) as Array).duplicate()
	_semilla_id = ""
	if es_modo_equipo():
		for id in equipo:
			if perfil_de(id) == "semilla":
				_semilla_id = id
		var progreso := get_node_or_null("/root/Progreso")
		var copia := equipo.duplicate()
		copia.sort()
		_clave = progreso.clave_equipo(equipo) if progreso != null else "+".join(PackedStringArray(copia))
		var comp: Dictionary = nivel.get("equipo", {}).get("composiciones", {}).get(_clave, {})
		if comp.get("frascos", null) is Array:
			_frascos_valores = (comp["frascos"] as Array).duplicate()
		if comp.get("retomar_valores", null) is Array:
			_retomar_valores = (comp["retomar_valores"] as Array).duplicate()
	else:
		_semilla_id = "solo" if _perfil_solo() == "semilla" else ""


func _config_gestor() -> Dictionary:
	var config: Dictionary = nivel.get("equipo", {}).duplicate(true)
	config.erase("composiciones")
	# §5.9: modo sin pista, sin `aciertos_max_turno` (el turno lo corta el motor al resolverse la tanda).
	config["rival"] = null
	config["confirmar_turno"] = true
	config.erase("aciertos_max_turno")
	config["lineas_voz"] = nivel.get("lineas_voz", {})
	return config


func _perfil_solo() -> String:
	if id_perfil != "":
		return perfil_de(id_perfil)
	return str(nivel.get("perfil", "brote"))


func _perfil_cfg(perfil: String) -> Dictionary:
	return nivel.get("perfiles", {}).get(perfil, {})


func _armar_oleada(idx: int) -> void:
	_idx = clampi(idx, 0, maxi(0, _oleadas.size() - 1))
	_oleada = _oleadas[_idx] if not _oleadas.is_empty() else {}
	_meta = LogicaCortar.meta_oleada(_oleada)
	_liberados = []
	_pool = LogicaCortar.pool_sin(_oleada.get("pool", {}), [])
	_oleada_iniciada = false
	_intento = 1
	_derrotas_oleada = 0
	_canasta = LogicaCortar.frascos_intento(0, _frascos_valores)
	_frascos = _canasta
	_toby_ayudo = false
	_siesta_usada = false
	_trompeta_usada = false
	_intento_nuevo_listo = true
	_desfile = []
	_desfile_todos = false
	_resembrar()
	coleccionauta.pisos_vacios = _idx
	coleccionauta.sentado = 0.0
	coleccionauta.frascos = _frascos
	_actualizar_ventanas()


## §5.9: semilla del nivel + intento + oleada, asi el arnes reproduce cualquier tanda.
func _resembrar() -> void:
	_rng.seed = int(nivel.get("semilla", 2511)) + _intento * 101 + (_idx + 1) * 1009


func _actualizar_ventanas() -> void:
	var ventanas: Array = []
	for i in 3:
		var ids: Array = []
		if i == _idx:
			for id in _ids_con_cupo(_pool):
				ids.append(id)
		elif i > _idx and i < _oleadas.size():
			ids = _ids_con_cupo(_oleadas[i].get("pool", {}))
		ventanas.append(ids.slice(0, 2))
	coleccionauta.ventanas = ventanas
	coleccionauta.frascos = _frascos


func _ids_con_cupo(pool: Dictionary) -> Array:
	var ids: Array = []
	for id in pool:
		if int(pool[id]) > 0:
			ids.append(str(id))
	ids.sort()
	return ids


# --- Consultas (arnes y quien quiera) ---

func oleada_actual() -> int:
	return _idx + 1

func frascos_restantes() -> int:
	return _frascos

func canasta_llena() -> int:
	return _canasta

func liberados_oleada() -> Array:
	return _liberados.duplicate()

func meta_actual() -> int:
	return _meta

func intento_actual() -> int:
	return _intento

func derrotas_oleada() -> int:
	return _derrotas_oleada

func fase() -> String:
	return _fase

func perfil_turno() -> String:
	return _perfil_turno

func burbujas_en_vuelo() -> Array:
	return _burbujas.filter(func(b: BurbujaCortar) -> bool: return b.activa())

func oleadas_ganadas() -> Array:
	return _oleadas_ganadas.duplicate()

func pool_restante() -> int:
	return LogicaCortar.total_pool(_pool)

func liberados_ultimo_intento() -> int:
	return _liberados_al_perder

func oleada_iniciada() -> bool:
	return _oleada_iniciada


# ---------------------------------------------------------------------------
# Arranque, entrada y retomar
# ---------------------------------------------------------------------------

func _arrancar() -> void:
	await _esperar(0.3)
	if not is_inside_tree() or nivel.is_empty():
		return
	if _restaurado:
		await _retomar()
	else:
		await _entrada()
	if not is_inside_tree() or _fase != "espera":
		return
	if turnos != null:
		if _restaurado:
			turnos.empezar_retomando()
		else:
			turnos.empezar()
	else:
		_turno_solo()


func _entrada() -> void:
	if revancha:
		_voz("revancha_intro")
		await _esperar_voz_libre(4.0)
		return
	if not _presentacion_vista:
		await _momento("presenta_burbujeada", _dur("presentacion_s", 12.0), func() -> void:
			_animar_presentacion()
			_voces_en_cadena(_lista_voz("presentacion")))
		_presentacion_vista = true
	else:
		# Intro corta: la regla de Cometa (presenta_02).
		_voz("intro")


## La mochila aspira a los animales del desfile a sus ventanitas y saca la varita (provisional por codigo).
func _animar_presentacion() -> void:
	var tw := _tween()
	tw.tween_property(coleccionauta, "balanceo", 0.2, 0.3 * escala_tiempo)
	tw.tween_property(coleccionauta, "balanceo", -0.2, 0.4 * escala_tiempo)
	tw.tween_property(coleccionauta, "balanceo", 0.0, 0.3 * escala_tiempo)
	for k in 8:
		_efectos.append({"tipo": "estrellas", "desde": Vector2(200 + k * 110, 560), "hasta": _boca, "t": -0.2 * k, "dur": 0.8})


## Re-entrada (§5.7): caso A (la oleada tal cual) o B (se presenta otra vez: «¡Pero tengo más!»). Se salta desde la
## 1.a vez (lo decide el contenedor).
func _retomar() -> void:
	var caso_a := _oleada_iniciada
	var jugado := await _momento("retomar_burbujeada", _dur("retomar_s", 5.0), func() -> void:
		if caso_a:
			_voz("retomar")
		else:
			_saltito()
			_voz("pero_tengo_mas"))
	if jugado and caso_a and _frascos_agregados:
		_voz_despues("encontre_frascos")


# ---------------------------------------------------------------------------
# Momentos saltables (ganchos con reemplazo provisional; la coreografia fina es de director-cinematicas)
# ---------------------------------------------------------------------------

func _momento(id: String, duracion: float, al_empezar: Callable = Callable()) -> bool:
	if not iniciar_momento_saltable(id):
		_estado_final_momento(id)
		return false
	if al_empezar.is_valid():
		al_empezar.call()
	var limite := duracion * escala_tiempo
	var t := 0.0
	while is_inside_tree() and momento_saltable_en_curso(id) and t < limite:
		await get_tree().process_frame
		t += get_process_delta_time()
	if momento_saltable_en_curso(id):
		_estado_final_momento(id)
		terminar_momento_saltable(id)
	return true


## Presentaciones de solo voz (combo, siesta, trompeta): nunca frenan el juego.
func _momento_breve(id: String, clave_voz: String, duracion: float = 2.5) -> void:
	if not iniciar_momento_saltable(id):
		return
	_voz(clave_voz)
	await _esperar(duracion)
	if is_inside_tree():
		terminar_momento_saltable(id)


func saltar_momento(id_animacion: String) -> void:
	if not momento_saltable_en_curso(id_animacion):
		return
	if id_animacion in ["presenta_burbujeada", "fin_oleada", "gran_estornudo", "retomar_burbujeada"]:
		_cortar_tweens()
		var audio := get_node_or_null("/root/Audio")
		if audio != null:
			audio.detener_voz()
	_estado_final_momento(id_animacion)
	terminar_momento_saltable(id_animacion)


func _estado_final_momento(id: String) -> void:
	match id:
		"presenta_burbujeada", "retomar_burbujeada":
			coleccionauta.balanceo = 0.0
			coleccionauta.sentado = 0.0
			coleccionauta.flota = 0.0
		"fin_oleada":
			coleccionauta.pisos_vacios = _idx + 1
			coleccionauta.sentado = 0.0
			coleccionauta.flota = 0.0
			coleccionauta.balanceo = 0.0
		"gran_estornudo":
			coleccionauta.pisos_vacios = 3
			coleccionauta.temblor = 0.0
			coleccionauta.burbuja_gorro = 0.0
			coleccionauta.flota = 0.0
			coleccionauta.sentado = 1.0
			coleccionauta.al_final_de_la_fila = true
			_desfile_todos = true
		"presenta_calcetin":
			_fin_presentacion_calcetin(true)


func _cortar_tweens() -> void:
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


# ---------------------------------------------------------------------------
# Turnos y tandas (§5.4)
# ---------------------------------------------------------------------------

func _turno_solo() -> void:
	await _esperar(0.4)
	if not is_inside_tree() or _fase != "espera":
		return
	_al_turno_iniciado(id_perfil if id_perfil != "" else "solo", _perfil_solo())


## Virtual de la ficha §5.9: deja listo el perfil del turno (lo llama `turno_iniciado`).
func aplicar_perfil_turno(perfil: String) -> void:
	_perfil_turno = perfil
	_cfg = _perfil_cfg(perfil)


func _al_turno_iniciado(id: String, perfil: String) -> void:
	if _fase != "espera":
		return
	_id_turno = id
	aplicar_perfil_turno(perfil)
	_turnos_perfil[perfil] = int(_turnos_perfil.get(perfil, 0)) + 1
	if int(_turnos_perfil[perfil]) == 1:
		_voz("instruccion", perfil)
	# Cada tanda destapa un frasco de jabon ("¡plip!") y lo tira.
	_frascos = maxi(0, _frascos - 1)
	_rev_frascos_usados += 1
	coleccionauta.frascos = _frascos
	_sfx("plip", 1.4)
	_efectos.append({"tipo": "frasco", "pos": Vector2(1190, 540), "t": 0.0, "dur": 0.6})
	# D2 de la Torre: la oleada queda "iniciada" en su primer soplido; la foto de frontera deja de valer.
	_oleada_iniciada = true
	_en_frontera = false
	_corte_calcetin = false
	_maxi_pedido = Vector2.INF
	_combo_dado = false
	var especiales: Array = []
	if perfil == "estrella":
		especiales = ["", ""]
		if not _siesta_usada and int(LogicaCortar.por_oleada(_cfg.get("siesta", {}).get("por_intento", 0), _idx, 0)) > 0:
			especiales[0] = "siesta"
		if not _trompeta_usada and int(LogicaCortar.por_oleada(_cfg.get("trompeta", {}).get("por_intento", 0), _idx, 0)) > 0:
			especiales[1] = "trompeta"
		if especiales == ["", ""]:
			especiales = []
	_cola = LogicaCortar.planear_tanda(_rng, perfil, _cfg, _idx, especiales)
	_t_tanda = 0.0
	_cola_pausada = false
	_fase = "tanda"


func _jugada_automatica() -> void:
	# §5.4: a los `semilla_auto_s` sin tocar, Toby salta y revienta la burbuja de Maxi.
	if _fase != "tanda" or _perfil_turno != "semilla":
		return
	_voz("regalito_maxi")
	_toby_salta()
	var b := _burbuja_maxi()
	if b != null:
		_reventar_diferido(b, 0, 0.3)
	else:
		_maxi_pedido = Vector2(640, 340)


func _process(delta: float) -> void:
	_t_vida += delta
	var dt := delta * acelerar_qa
	var dtb := dt
	if _siesta_t > 0.0:
		_siesta_t -= dt
		dtb *= float(_perfil_cfg("estrella").get("siesta", {}).get("factor", 0.5))
	if _fase == "tanda" and not _cola_pausada:
		_t_tanda += dtb
		while not _cola.is_empty() and float(_cola[0]["t"]) <= _t_tanda and _fase == "tanda" and not _cola_pausada:
			var ev: Dictionary = _cola[0]
			if str(ev["tipo"]) == "anticipacion" and _necesita_presentar_calcetin(int(ev["soplido"])):
				_presentar_calcetin(int(ev["soplido"]))
				break
			_cola.pop_front()
			_ejecutar_evento(ev)
	for b in _burbujas.duplicate():
		if (b as BurbujaCortar).avanzar(dtb):
			_al_volver_al_pasto(b)
	_actualizar_efectos(delta)
	if _fase == "tanda" and _tanda_resuelta():
		_cerrar_tanda()
	_desfile_nodo.queue_redraw()
	_pasto.queue_redraw()
	_efectos_nodo.queue_redraw()


func _ejecutar_evento(ev: Dictionary) -> void:
	match str(ev["tipo"]):
		"anticipacion":
			# Infla los cachetes 0,6 s ("ahi vienen") y la varita tiembla.
			var tw := create_tween()
			tw.tween_property(coleccionauta, "infla", 1.0, 0.3 / acelerar_qa)
			tw.tween_property(coleccionauta, "infla", 0.0, 0.3 / acelerar_qa)
		"burbuja":
			_lanzar_animal(int(ev["soplido"]), {})
		"burbuja_costado":
			var radio := _diametro() / 2.0
			_lanzar_animal(-1, LogicaCortar.trayectoria_costado(_rng, nivel, radio, _vuelo() * 1.1, int(ev.get("lado", 1))))
		"calcetin", "siesta", "trompeta":
			var radio := _diametro() / 2.0
			var b := _nueva_burbuja(str(ev["tipo"]), "", radio, LogicaCortar.trayectoria_arco(_rng, nivel, radio, _vuelo()), int(ev["soplido"]))
			if str(ev["tipo"]) == "calcetin":
				_sfx("fff", 0.8)


func _diametro() -> float:
	return float(LogicaCortar.por_oleada(_cfg.get("diametro", 140), _idx, 140))


func _vuelo() -> float:
	return float(LogicaCortar.por_oleada(_cfg.get("vuelo_s", 2.4), _idx, 2.4))


func _lanzar_animal(soplido: int, tr: Dictionary) -> void:
	var id := LogicaCortar.sacar(_pool, _rng, _cfg.get("preferidos", []))
	if id == "":
		return
	_actualizar_ventanas()
	if _perfil_turno == "semilla":
		var radio := float(_cfg.get("diametro", 200)) / 2.0
		var b := _nueva_burbuja("animal", id, radio, LogicaCortar.trayectoria_semilla(_rng, nivel, float(_cfg.get("sube_s", 1.2))), soplido)
		b.flota = true
		if _maxi_pedido != Vector2.INF:
			_maxi_va_al_dedo(b, _maxi_pedido)
		return
	var radio := _diametro() / 2.0
	if tr.is_empty():
		tr = LogicaCortar.trayectoria_arco(_rng, nivel, radio, _vuelo())
	_nueva_burbuja("animal", id, radio, tr, soplido)


func _nueva_burbuja(tipo: String, id: String, radio: float, tr: Dictionary, soplido: int) -> BurbujaCortar:
	var b := BurbujaCortar.new()
	b.tipo = tipo
	b.id_animal = id
	b.radio = radio
	b.trayectoria = tr
	b.flota = bool(tr.get("flota", false))
	b.soplido = soplido
	b.hitbox_extra = float(_cfg.get("hitbox_extra_px", 15))
	b.hitbox_menos = float(_cfg.get("calcetin", {}).get("hitbox_menos_px", 8))
	var bam: Dictionary = nivel.get("bamboleo", {})
	b.bamboleo_px = 0.0 if _menos_movimiento else float(bam.get("px", 6))
	b.bamboleo_hz = float(bam.get("hz", 2.0))
	_capa_burbujas.add_child(b)
	b.preparar(_rng.randf() * 2.0)
	_burbujas.append(b)
	return b


func _burbuja_maxi() -> BurbujaCortar:
	for b in _burbujas:
		if (b as BurbujaCortar).tipo == "animal" and (b as BurbujaCortar).flota and (b as BurbujaCortar).activa():
			return b
	return null


## Tanda resuelta = sin eventos pendientes y sin burbujas (reventadas, sorbidas o caidas al pasto).
func _tanda_resuelta() -> bool:
	return _cola.is_empty() and not _cola_pausada and _burbujas.is_empty() and _t_tanda > 0.0


func _cerrar_tanda() -> void:
	_fase = "espera"
	var corte := _corte_calcetin
	_corte_calcetin = false
	_dedo = -1
	if turnos != null:
		if _frascos <= 0:
			_derrota()
		else:
			turnos.terminar_turno(corte)
		return
	# Solitario (solo pruebas): sin frascos, reintento inmediato con las ayudas, sin gag.
	if _frascos <= 0:
		_derrotas_oleada += 1
		_derrotas += 1
		_intento_nuevo_listo = false
		_preparar_intento_nuevo()
	_turno_solo()


# ---------------------------------------------------------------------------
# El calcetin: presentacion (1.a vez por familia, politica una_vez) y efecto por perfil
# ---------------------------------------------------------------------------

func _necesita_presentar_calcetin(soplido: int) -> bool:
	if _calcetin_presentado:
		return false
	for ev in _cola:
		if str(ev["tipo"]) == "calcetin" and int(ev["soplido"]) == soplido:
			return true
	return false


## Sale solo y despacio con la voz de Toby; reventarlo en la presentacion solo hace el gag (sin efecto).
func _presentar_calcetin(soplido: int) -> void:
	_calcetin_presentado = true
	if not iniciar_momento_saltable("presenta_calcetin"):
		return
	for i in range(_cola.size() - 1, -1, -1):
		if str(_cola[i]["tipo"]) == "calcetin" and int(_cola[i]["soplido"]) == soplido:
			_cola.remove_at(i)
			break
	_cola_pausada = true
	_voz("presenta_calcetin")
	var radio := _diametro() / 2.0
	var tr := {"x0": 560.0, "y0": _pasto_y, "xa": 640.0, "ya": 260.0, "T": _vuelo() * 1.8}
	_calcetin_presentacion = _nueva_burbuja("calcetin", "", radio, tr, soplido)
	_calcetin_presentacion.lenta = true


func _fin_presentacion_calcetin(saltado: bool) -> void:
	if _calcetin_presentacion != null and saltado and _calcetin_presentacion in _burbujas:
		_quitar_burbuja(_calcetin_presentacion)
	_calcetin_presentacion = null
	_cola_pausada = false
	if not saltado:
		terminar_momento_saltable("presenta_calcetin")


func _calcetin(b: BurbujaCortar) -> void:
	calcetin_reventado.emit(_perfil_turno)
	_sfx("fff")
	_efectos.append({"tipo": "nube", "pos": b.position, "t": 0.0, "dur": 0.6})
	# El calcetin vuela y cae sobre el casco de Toby como sombrero; Toby estornuda.
	toby.sombrero_calcetin = true
	var tw := create_tween()
	tw.tween_property(toby, "estornudo", 1.0, 0.2 * escala_tiempo)
	tw.tween_property(toby, "estornudo", 0.0, 0.3 * escala_tiempo)
	_voz("calcetin_toby")
	if b.lenta:
		_fin_presentacion_calcetin(false)
		return
	if turnos != null:
		turnos.notificar_fallo_suave()
	var efecto := str(_cfg.get("calcetin", {}).get("efecto", "escapa_soplido"))
	if efecto == "corta_turno":
		# Estrella: las de ese soplido (y las que sigan en el aire) se escapan y el turno termina.
		_corte_calcetin = true
		_cola.clear()
		_cola_pausada = false
		for otra in _burbujas.duplicate():
			if (otra as BurbujaCortar).activa():
				_al_volver_al_pasto(otra)
	else:
		# Brote: se escapan las de ese soplido; el soplido siguiente sale igual.
		for i in range(_cola.size() - 1, -1, -1):
			if int(_cola[i]["soplido"]) == b.soplido and str(_cola[i]["tipo"]) != "anticipacion":
				_cola.remove_at(i)
		for otra in _burbujas.duplicate():
			if (otra as BurbujaCortar).activa() and (otra as BurbujaCortar).soplido == b.soplido:
				_al_volver_al_pasto(otra)


# ---------------------------------------------------------------------------
# Reventar, liberar, escapar
# ---------------------------------------------------------------------------

func _reventar(b: BurbujaCortar, indice: int) -> void:
	if not b in _burbujas or _fase != "tanda":
		return
	_burbujas.erase(b)
	b.estado = "reventada"
	_sfx("pop", pow(2.0, float(indice) / 12.0))
	if not _menos_movimiento:
		for k in 8:
			_efectos.append({"tipo": "gota", "pos": b.position, "vel": Vector2.from_angle(k * TAU / 8.0) * (b.radio + 30.0),
				"color": [Color("#FF9ED6"), Color("#8EE9FF"), Color("#FFE38A")][k % 3], "t": 0.0, "dur": 0.4})
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2.ONE * 1.15, 0.04 * escala_tiempo)
	tw.tween_property(b, "scale", Vector2.ZERO, 0.08 * escala_tiempo)
	tw.tween_callback(b.queue_free)
	match b.tipo:
		"animal":
			_liberar(b.id_animal, indice, b.position)
		"calcetin":
			_calcetin(b)
		"siesta":
			_siesta_usada = true
			_siesta_t = float(_cfg.get("siesta", {}).get("dura_s", 4.0))
			_momento_breve("presenta_siesta", "presenta_siesta")
		"trompeta":
			_trompeta_usada = true
			var cfg_t: Dictionary = _cfg.get("trompeta", {})
			var extra := int(cfg_t.get("extra", 4))
			var dura := float(cfg_t.get("dura_s", 3.0))
			for k in extra:
				_cola.append({"t": _t_tanda + 0.2 + dura * float(k) / maxf(1.0, extra), "tipo": "burbuja_costado", "soplido": -1, "lado": -1 if k % 2 == 0 else 1})
			_cola.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return float(a["t"]) < float(c["t"]))
			_momento_breve("presenta_trompeta", "presenta_trompeta")


func _reventar_diferido(b: BurbujaCortar, indice: int, segundos: float) -> void:
	b.estado = "marcada"
	await _esperar(segundos)
	if is_inside_tree() and b in _burbujas:
		b.estado = "vuelo"
		_reventar(b, indice)


func _liberar(id: String, indice: int, desde: Vector2) -> void:
	_liberados.append(id)
	_desfile.append(id)
	liberado.emit(id, indice)
	if turnos != null:
		turnos.notificar_acierto()
	_corredores.append({"id": id, "pos": desde, "desde": desde, "t": 0.0})
	_actualizar_ventanas()
	if _liberados.size() >= _meta and _fase == "tanda":
		_piso_vaciado()


func _al_volver_al_pasto(b: BurbujaCortar) -> void:
	if b == _calcetin_presentacion:
		_quitar_burbuja(b)
		_fin_presentacion_calcetin(false)
		return
	if b.tipo != "animal":
		# Calcetin y power-ups que nadie toco: caen al pasto y no pasa nada.
		_quitar_burbuja(b)
		return
	_escapar(b)


## La manguera la sorbe de vuelta ("sluuurp", nunca aspiradora) y el animal vuelve al pool contento.
func _escapar(b: BurbujaCortar) -> void:
	if b.estado == "escapando":
		return
	b.estado = "escapando"
	LogicaCortar.devolver(_pool, b.id_animal)
	_actualizar_ventanas()
	escapo.emit(b.id_animal)
	_sfx("sluuurp", 1.2, -6.0)
	_escapes += 1
	if _escapes % 3 == 1:
		var audio := get_node_or_null("/root/Audio")
		if audio == null or not audio.esta_hablando():
			_voz("escapo")
	var tw := create_tween()
	tw.tween_property(b, "position", _boca, 0.8 / acelerar_qa).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(b, "scale", Vector2.ONE * 0.25, 0.8 / acelerar_qa)
	tw.tween_callback(func() -> void: _quitar_burbuja(b))


func _quitar_burbuja(b: BurbujaCortar) -> void:
	_burbujas.erase(b)
	if is_instance_valid(b):
		b.queue_free()


func _actualizar_efectos(delta: float) -> void:
	for i in range(_efectos.size() - 1, -1, -1):
		var e: Dictionary = _efectos[i]
		e["t"] = float(e["t"]) + delta
		if float(e["t"]) >= float(e["dur"]):
			_efectos.remove_at(i)
	var limite := _ahora_ms() - int(nivel.get("trazo", {}).get("estela_ms", 150))
	while not _estela.is_empty() and int(_estela[0]["ms"]) < limite:
		_estela.pop_front()
	if _estela.is_empty():
		_estela_dorada = false
	# Los liberados saltan con su paraguas de hoja y corren a la salida, donde se suman al desfile.
	for i in range(_corredores.size() - 1, -1, -1):
		var c: Dictionary = _corredores[i]
		c["t"] = float(c["t"]) + delta / maxf(0.01, escala_tiempo)
		var u := clampf(float(c["t"]) / 1.4, 0.0, 1.0)
		c["pos"] = (c["desde"] as Vector2).lerp(SALIDA_LIBERADOS, u) + Vector2(0, -sin(minf(u * 3.0, 1.0) * PI) * 50.0)
		if u >= 1.0:
			_corredores.remove_at(i)


# ---------------------------------------------------------------------------
# Entrada (unificada: el proyecto emula el toque con el mouse; solo eventos tactiles; un solo dedo)
# ---------------------------------------------------------------------------

func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		procesar_toque(evento.position, evento.pressed, evento.index)
	elif evento is InputEventScreenDrag:
		procesar_arrastre(evento.position, evento.index)


func _jugable() -> bool:
	if _fase != "tanda" or _corte_calcetin:
		return false
	if turnos != null:
		return turnos.turno_activo() and not turnos.entrada_bloqueada()
	return true


func procesar_toque(pos: Vector2, presionado: bool, dedo: int = 0) -> void:
	if not presionado:
		if dedo == _dedo:
			_dedo = -1
		return
	if _dedo != -1 and dedo != _dedo:
		return   # R4: un segundo dedo apoyado se ignora.
	if coleccionauta.contiene(pos):
		# Se rie y saluda; nunca revienta nada.
		_sfx("tik", 1.5)
		var tw := create_tween()
		tw.tween_property(coleccionauta, "balanceo", 0.12, 0.08)
		tw.tween_property(coleccionauta, "balanceo", 0.0, 0.15)
		return
	if not _zona.has_point(pos):
		if pos.y >= 590.0 and pos.x >= 140.0 and pos.x <= 1140.0:
			_sfx("tik", 0.8, -8.0)
		return
	# Onda del color del hermano bajo el dedo, en el mismo cuadro (<= 16 ms), y un "tik" suave.
	_efectos.append({"tipo": "onda", "pos": pos, "color": _color_turno(), "t": 0.0, "dur": 0.3})
	_efectos_nodo.queue_redraw()
	_sfx("tik", 1.0, -10.0)
	if not _jugable():
		return
	_dedo = dedo
	_ultimo_punto = pos
	_pops_trazo = 0
	_animales_trazo = 0
	_combo_dado = false
	_estela = [{"p": pos, "ms": _ahora_ms()}]
	_probar_segmento(pos, pos)


func procesar_arrastre(pos: Vector2, dedo: int = 0) -> void:
	if dedo != _dedo or _dedo == -1:
		return
	_estela.append({"p": pos, "ms": _ahora_ms()})
	if _jugable():
		_probar_segmento(_ultimo_punto, pos)
	_ultimo_punto = pos


## Revienta toda burbuja cuyo circulo de hitbox cruce el segmento a-b, en el orden del trazo (escalera de pops).
func _probar_segmento(a: Vector2, b: Vector2) -> void:
	if _perfil_turno == "semilla":
		_maxi_toca(b)
		return
	var golpeadas: Array = []
	for burbuja in _burbujas:
		var bb := burbuja as BurbujaCortar
		if bb.activa() and bb.position.y < _pasto_y - 8.0 and LogicaCortar.segmento_cruza_circulo(a, b, bb.position, bb.radio_hitbox()):
			golpeadas.append(bb)
	golpeadas.sort_custom(func(x: BurbujaCortar, y: BurbujaCortar) -> bool: return x.position.distance_squared_to(a) < y.position.distance_squared_to(a))
	var min_combo := int(nivel.get("combo", {}).get("min_trazo", 3))
	for g in golpeadas:
		if not _jugable():
			return
		var es_animal := (g as BurbujaCortar).tipo == "animal"
		_reventar(g, _pops_trazo)
		_pops_trazo += 1
		if es_animal:
			_animales_trazo += 1
			if _animales_trazo >= min_combo and not _combo_dado and _fase == "tanda":
				_dar_combo(_animales_trazo)


## ¡Combo! (>= 3 en un trazo): destello dorado en la estela, campanita y Toby saca un animal mas por la ventanita.
func _dar_combo(n: int) -> void:
	_combo_dado = true
	_estela_dorada = true
	combo.emit(n)
	_sfx("campanita", 1.5)
	_momento_breve("presenta_combo", "presenta_combo")
	for k in int(nivel.get("combo", {}).get("libera_extra", 1)):
		var id := LogicaCortar.sacar(_pool, _rng)
		if id != "":
			_liberar(id, -1, coleccionauta.PISOS[_idx].get_center())
		if _fase != "tanda":
			return


## Turno de Maxi (§5.4): cualquier toque o trazo en la zona revienta su burbuja. Nunca falla.
func _maxi_toca(punto: Vector2) -> void:
	var b := _burbuja_maxi()
	if b == null:
		# Toco antes de que salga: no se pierde, la burbuja ira directo a su dedo.
		var hay_otra := false
		for x in _burbujas:
			hay_otra = hay_otra or (x as BurbujaCortar).flota
		if not hay_otra and _maxi_pedido == Vector2.INF:
			_maxi_pedido = punto
		return
	if b.t < b.duracion():
		_maxi_va_al_dedo(b, punto)
		return
	var cerca := punto.distance_to(b.position) < float(_cfg.get("justo_ahi_px", 150))
	_efectos.append({"tipo": "estrellas", "desde": punto, "hasta": b.position, "t": 0.0, "dur": 0.15})
	if cerca:
		_voz("justo_ahi_maxi")
	_reventar_diferido(b, 0, 0.15)


## Antes del apice, la burbuja "acelera" hacia su dedo («¡ya voy!») y revienta al llegar.
func _maxi_va_al_dedo(b: BurbujaCortar, punto: Vector2) -> void:
	_maxi_pedido = Vector2.INF
	b.estado = "marcada"
	_voz("ya_voy_maxi")
	var destino := Vector2(clampf(punto.x, _zona.position.x + b.radio, _zona.end.x - b.radio), clampf(punto.y, _zona.position.y + b.radio, _zona.end.y - b.radio))
	var tw := create_tween()
	tw.tween_property(b, "position", destino, 0.2 * escala_tiempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if b in _burbujas:
			b.estado = "vuelo"
			_reventar(b, 0))


func _color_turno() -> Color:
	if turnos != null and turnos.hermano_actual() != "":
		return turnos.color_de(turnos.hermano_actual())
	return COLOR_SOLO


func _toby_salta() -> void:
	var tw := create_tween()
	tw.tween_property(toby, "salto", 60.0, 0.15 * escala_tiempo).set_ease(Tween.EASE_OUT)
	tw.tween_property(toby, "salto", 0.0, 0.2 * escala_tiempo).set_ease(Tween.EASE_IN)


func _saltito() -> void:
	var tw := _tween()
	tw.tween_property(coleccionauta, "flota", 18.0, 0.15 * escala_tiempo)
	tw.tween_property(coleccionauta, "flota", 0.0, 0.2 * escala_tiempo)


# ---------------------------------------------------------------------------
# Fin de oleada y victoria (§5.6)
# ---------------------------------------------------------------------------

func _estado_inicial_oleada(idx: int) -> Dictionary:
	var estado := {
		"oleada": idx + 1, "etapa": idx + 1, "oleadas_ganadas": _oleadas_ganadas.duplicate(), "oleada_iniciada": false,
		"intento": 1, "derrotas_oleada": 0, "derrotas": _derrotas, "ultimo_gag": _ultimo_gag,
		"frascos_restantes": LogicaCortar.frascos_intento(0, _frascos_valores), "liberados": [],
		"toby_ayudo": false, "siesta_usada": false, "trompeta_usada": false,
		"calcetin_presentado": _calcetin_presentado, "presentacion_vista": true,
	}
	if revancha:
		estado["revancha"] = {"frascos_usados": _rev_frascos_usados, "sobrantes": _rev_sobrantes.duplicate(), "derrotas": _rev_derrotas}
	return estado


func _piso_vaciado() -> void:
	_fase = "fin_oleada"
	_cola.clear()
	_cola_pausada = false
	if _calcetin_presentacion != null:
		_calcetin_presentacion = null
		terminar_momento_saltable("presenta_calcetin")
	for b in _burbujas.duplicate():
		if (b as BurbujaCortar).tipo == "animal":
			LogicaCortar.devolver(_pool, (b as BurbujaCortar).id_animal)
		_quitar_burbuja(b)
	_dedo = -1
	_siesta_t = 0.0
	if turnos != null:
		turnos.detener()
	_oleadas_ganadas.append(str(_oleada.get("id", "o%d" % oleada_actual())))
	_rev_sobrantes.append(_frascos)
	_sfx("plof", 0.6)
	piso_vaciado.emit(oleada_actual())
	if _idx >= _oleadas.size() - 1:
		_victoria()
		return
	# En ESTE cuadro, con todo congelado y antes de `fin_oleada`, el parcial ya es la oleada siguiente (caso B).
	_foto_frontera = _estado_inicial_oleada(_idx + 1)
	_en_frontera = true
	notificar_parcial_equipo()
	var idx_ganada := _idx
	await _momento("fin_oleada", _dur("fin_oleada_s", 5.0), func() -> void: _animar_fin_oleada(idx_ganada))
	if not is_inside_tree():
		return
	_armar_oleada(idx_ganada + 1)
	_empezar_oleada_nueva()


func _animar_fin_oleada(idx_ganada: int) -> void:
	_efectos.append({"tipo": "blup", "pos": _boca + Vector2(20, 150), "t": 0.0, "dur": 0.8})
	var tw := _tween()
	tw.tween_property(coleccionauta, "sentado", 1.0, 0.4 * escala_tiempo)
	tw.tween_callback(func() -> void:
		coleccionauta.pisos_vacios = idx_ganada + 1
		_sfx("pop", 0.5))
	tw.tween_interval(0.8 * escala_tiempo)
	tw.tween_property(coleccionauta, "flota", 20.0, 0.15 * escala_tiempo)
	tw.tween_property(coleccionauta, "flota", 0.0, 0.2 * escala_tiempo)
	tw.tween_interval(2.0 * escala_tiempo)
	tw.tween_property(coleccionauta, "sentado", 0.0, 0.4 * escala_tiempo)
	_voz("fin_oleada", "o%d" % (idx_ganada + 1))
	if turnos != null and turnos.barra != null:
		for id in equipo:
			turnos.barra.aplaudir(id)


## Empieza la oleada siguiente: guardado "al empezar la oleada" (igual a la foto de frontera) y puerta de Maxi. Sin
## intro corta: la reemplazo `fin_oleada` (patron de la Torre).
func _empezar_oleada_nueva() -> void:
	_fase = "espera"
	notificar_parcial_equipo()
	if turnos != null:
		turnos.reiniciar_rival(_siguiente_del_intento())
	else:
		_turno_solo()


func _victoria() -> void:
	_fase = "victoria"
	coleccionauta.pisos_vacios = 3
	await _momento("gran_estornudo", _dur("gran_estornudo_s", 12.0), func() -> void:
		var tw := _tween()
		tw.tween_property(coleccionauta, "temblor", 1.0, 0.3 * escala_tiempo)
		tw.tween_interval(1.2 * escala_tiempo)
		tw.tween_property(coleccionauta, "temblor", 0.0, 0.2 * escala_tiempo)
		tw.tween_property(coleccionauta, "burbuja_gorro", 1.0, 0.5 * escala_tiempo)
		tw.tween_property(coleccionauta, "flota", 80.0, 1.5 * escala_tiempo).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(1.5 * escala_tiempo)
		tw.tween_callback(func() -> void: _sfx("plof"))
		tw.tween_property(coleccionauta, "burbuja_gorro", 0.0, 0.2 * escala_tiempo)
		tw.tween_property(coleccionauta, "flota", 0.0, 0.4 * escala_tiempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(coleccionauta, "sentado", 1.0, 0.2 * escala_tiempo)
		tw.tween_callback(func() -> void:
			_desfile_todos = true
			_confeti(Vector2(640, 300), 40)
			coleccionauta.al_final_de_la_fila = true)
		_desfile = []
		for o in _oleadas:
			for id in o.get("pool", {}):
				_desfile.append(str(id))
		_voces_en_cadena(_lista_voz("gran_estornudo")))
	if not is_inside_tree():
		return
	if revancha:
		var resultado := resultado_revancha_calculado()
		resultado_revancha.emit(int(resultado["estrellitas"]), int(resultado["record"]))
		_confeti(Vector2(640, 300), 30)
		await _esperar(1.5)
		emitir_completado(0)
	elif en_batalla:
		emitir_completado(0)
	elif es_modo_equipo():
		celebrar_equipo(0)
	else:
		celebrar(0)


func resultado_revancha_calculado() -> Dictionary:
	var cfg: Dictionary = nivel.get("revancha", {})
	if not es_modo_equipo():
		return {"estrellitas": 0, "record": -1}
	return LogicaCortar.resultado_revancha(_clave, str(cfg.get("estrellitas_y_record_solo_con", "maxi+nicole+sofia")),
		_rev_derrotas, _rev_sobrantes, _rev_frascos_usados, int(cfg.get("sobrantes_tres", 2)))


func _confeti(centro: Vector2, n: int) -> void:
	if _menos_movimiento:
		n = n / 3
	var colores := [Color("#F0453A"), Color("#FFD23F"), Color("#3F8CFF"), Color("#3FCB5A"), Color("#FF9ED6")]
	for k in n:
		_efectos.append({"tipo": "confeti", "pos": centro, "vel": Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(80, 320),
			"color": colores[k % colores.size()], "t": 0.0, "dur": 1.2})


# ---------------------------------------------------------------------------
# Derrota-gag (la orquesta la base, §5.5) y reintento con ayudas
# ---------------------------------------------------------------------------

func _siguiente_del_intento() -> String:
	if _semilla_id != "" and _semilla_id != "solo":
		return _semilla_id
	var ids: Array = turnos.orden_unico() if turnos != null else []
	if ids.size() >= 2:
		_quien_empezo = ids[1] if _quien_empezo == ids[0] or _quien_empezo == "" else ids[0]
		return _quien_empezo
	return ""


func _derrota() -> void:
	_fase = "derrota"
	_derrotas_oleada += 1
	_derrotas += 1
	_rev_derrotas += 1
	_gag_actual = LogicaCortar.variante_gag(_derrotas, _ultimo_gag, nivel.get("gags", []))
	_ultimo_gag = _gag_actual
	_liberados_al_perder = _liberados.size()
	_intento_nuevo_listo = false
	_voz_ayuda_tras_gag()
	turnos.terminar_turno_sin_recursos(_siguiente_del_intento())


func variante_derrota() -> String:
	return _gag_actual


func ancla_rival_motor() -> Vector2:
	return _boca


## Las burbujas que queden en el aire vuelan a la varita; el Coleccionauta hace su gag (provisional por codigo).
func gag_derrota_aspirar(destino: Vector2) -> float:
	for b in _burbujas.duplicate():
		var bb := b as BurbujaCortar
		if bb.tipo == "animal":
			LogicaCortar.devolver(_pool, bb.id_animal)
		var tw := create_tween()
		tw.tween_property(bb, "position", destino, 0.6 * escala_tiempo)
		tw.tween_callback(func() -> void: _quitar_burbuja(bb))
	_burbujas.clear()
	var tw := _tween()
	match _gag_actual:
		"burbuja_gorro":
			tw.tween_property(coleccionauta, "burbuja_gorro", 1.0, 0.3 * escala_tiempo)
			tw.tween_property(coleccionauta, "flota", 70.0, 0.7 * escala_tiempo)
			tw.tween_callback(func() -> void: _sfx("pop", 0.7))
			tw.tween_property(coleccionauta, "burbuja_gorro", 0.0, 0.1 * escala_tiempo)
			tw.tween_property(coleccionauta, "flota", 0.0, 0.3 * escala_tiempo)
			tw.tween_property(coleccionauta, "sentado", 1.0, 0.1 * escala_tiempo)
		"estornudo_jabon":
			tw.tween_property(coleccionauta, "infla", 1.0, 0.4 * escala_tiempo)
			tw.tween_callback(func() -> void:
				coleccionauta.infla = 0.0
				for k in 10:
					_efectos.append({"tipo": "blup", "pos": Vector2(1150 - k * 22, 450 - (k % 3) * 30), "t": -0.05 * k, "dur": 0.9}))
			tw.tween_property(coleccionauta, "empanado", 1.0, 0.2 * escala_tiempo)
			tw.tween_property(coleccionauta, "balanceo", 0.15, 0.3 * escala_tiempo)
			tw.tween_property(coleccionauta, "balanceo", -0.15, 0.3 * escala_tiempo)
		_:
			tw.tween_callback(func() -> void: coleccionauta.calcetin_cara = true)
			for k in 3:
				tw.tween_property(coleccionauta, "balanceo", 0.18, 0.15 * escala_tiempo)
				tw.tween_property(coleccionauta, "balanceo", -0.18, 0.15 * escala_tiempo)
	return 1.6 * escala_tiempo


## La mochila estornuda una lluvia de burbujas que revientan solas en confeti; los animales vuelven a las ventanitas.
func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	_preparar_intento_nuevo()
	_confeti(_boca + Vector2(40, -60), 30)
	for k in 8:
		_efectos.append({"tipo": "blup", "pos": Vector2(1240 - k * 14, 220 + k * 30), "t": -0.08 * k, "dur": 0.7})
	var tw := _tween()
	tw.tween_interval(0.6 * escala_tiempo)
	tw.tween_callback(_reponer_poses_gag)
	return 1.2 * escala_tiempo


func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	_cortar_tweens()
	_preparar_intento_nuevo()
	_reponer_poses_gag()


func _reponer_poses_gag() -> void:
	coleccionauta.burbuja_gorro = 0.0
	coleccionauta.flota = 0.0
	coleccionauta.sentado = 0.0
	coleccionauta.empanado = 0.0
	coleccionauta.balanceo = 0.0
	coleccionauta.calcetin_cara = false
	coleccionauta.infla = 0.0


## Ayudas escalonadas (§5.5) al tocar «¡otra vez!»: desde la 2.a derrota de la oleada, Toby revienta 3 el solo.
func reintentar_equipo() -> void:
	_boton_casa.scale = Vector2.ONE
	if LogicaCortar.toby_ayuda(_derrotas_oleada, int(nivel.get("toby_ayuda", {}).get("desde_derrota", 2))) and not _toby_ayudo:
		await _toby_ayuda()
	_fase = "espera"


func _toby_ayuda() -> void:
	_toby_ayudo = true
	_voz("ayuda_toby")
	var cuantas := mini(int(nivel.get("toby_ayuda", {}).get("revienta", 3)), maxi(0, _meta - _liberados.size() - 1))
	for k in cuantas:
		var id := LogicaCortar.sacar(_pool, _rng)
		if id == "":
			break
		_toby_salta()
		var p := Vector2(300 + k * 260, 300)
		_sfx("pop", pow(2.0, float(k) / 12.0))
		for j in 6:
			_efectos.append({"tipo": "gota", "pos": p, "vel": Vector2.from_angle(j * TAU / 6.0) * 90.0, "color": Color("#8EE9FF"), "t": 0.0, "dur": 0.4})
		_liberados.append(id)
		_desfile.append(id)
		liberado.emit(id, k)
		_corredores.append({"id": id, "pos": p, "desde": p, "t": 0.0})
		_actualizar_ventanas()
		await _esperar(0.4)
		if not is_inside_tree():
			return


## Logro comun de Cometa: la base lee `logro_comun[str(n)]`; 1 = «¡Igual liberamos a un montón!», 0 = «Esta vez se
## nos escaparon…». El numero real de liberados esta en `liberados_ultimo_intento()` (decision dev-godot 07-Nov).
func contar_logro_equipo() -> int:
	return 1 if _liberados_al_perder > 0 else 0


func _voz_ayuda_tras_gag() -> void:
	var t0 := Time.get_ticks_msec()
	while is_inside_tree() and not en_derrota_equipo() and Time.get_ticks_msec() - t0 < 8000:
		await get_tree().process_frame
	var id := _id_gag
	while is_inside_tree() and en_derrota_equipo() and not _gag_terminado:
		await get_tree().process_frame
	if _id_gag != id:
		return
	await _esperar(2.5)
	if not is_inside_tree() or not en_derrota_equipo():
		return
	if LogicaCortar.ofrecer_descanso(_derrotas_oleada, int(nivel.get("ofrecer_descanso_desde_derrota", 3))):
		_voz("ofrece_descanso")
		# La casa se agranda un 10 % y respira; seguir es tocar «¡otra vez!».
		var tw := _tween()
		tw.tween_property(_boton_casa, "scale", Vector2.ONE * 1.1, 0.4)
		tw.tween_property(_boton_casa, "scale", Vector2.ONE * 1.04, 0.6)
		tw.tween_property(_boton_casa, "scale", Vector2.ONE * 1.1, 0.6)
	elif _derrotas_oleada == 1:
		_voz("ayuda_jabon")


## El intento nuevo: 30 % de lo liberado queda (D8), frascos segun las derrotas de la oleada, semilla nueva.
func _preparar_intento_nuevo() -> void:
	if _intento_nuevo_listo:
		return
	_intento_nuevo_listo = true
	var quedan := LogicaCortar.conservados(_liberados.size(), float(nivel.get("conservar_al_reintentar", 0.3)))
	_liberados = _liberados.slice(0, quedan)
	_desfile = _liberados.duplicate()
	_pool = LogicaCortar.pool_sin(_oleada.get("pool", {}), _liberados)
	_intento += 1
	_canasta = LogicaCortar.frascos_intento(_derrotas_oleada, _frascos_valores)
	_frascos = _canasta
	_toby_ayudo = false
	_siesta_usada = false
	_trompeta_usada = false
	_resembrar()
	_actualizar_ventanas()


# ---------------------------------------------------------------------------
# Parcial (§5.7) y revancha (§5.8: solo entre oleadas)
# ---------------------------------------------------------------------------

func obtener_parcial_equipo() -> Dictionary:
	if revancha:
		# Salir a mitad de una oleada la reinicia entera: siempre la foto del inicio de la oleada en curso.
		return _foto_frontera.duplicate(true) if not _oleadas_ganadas.is_empty() else {}
	if _en_frontera:
		return _foto_frontera.duplicate(true)
	return {
		"oleada": oleada_actual(), "etapa": oleada_actual(), "oleadas_ganadas": _oleadas_ganadas.duplicate(),
		"oleada_iniciada": _oleada_iniciada, "intento": _intento, "derrotas_oleada": _derrotas_oleada,
		"derrotas": _derrotas, "ultimo_gag": _ultimo_gag, "frascos_restantes": _frascos,
		"liberados": _liberados.duplicate(), "toby_ayudo": _toby_ayudo, "siesta_usada": _siesta_usada,
		"trompeta_usada": _trompeta_usada, "calcetin_presentado": _calcetin_presentado,
		"presentacion_vista": _presentacion_vista,
	}


func restaurar_parcial_equipo(estado: Dictionary) -> void:
	if estado.is_empty() or nivel.is_empty():
		return
	_restaurado = true
	_oleadas_ganadas = (estado.get("oleadas_ganadas", []) as Array).duplicate()
	_derrotas = int(estado.get("derrotas", 0))
	_ultimo_gag = str(estado.get("ultimo_gag", ""))
	_calcetin_presentado = bool(estado.get("calcetin_presentado", false))
	_presentacion_vista = bool(estado.get("presentacion_vista", true))
	var rev = estado.get("revancha", {})
	if revancha and rev is Dictionary:
		_rev_frascos_usados = int(rev.get("frascos_usados", 0))
		_rev_sobrantes = (rev.get("sobrantes", []) as Array).duplicate()
		_rev_derrotas = int(rev.get("derrotas", 0))
	_armar_oleada(int(estado.get("oleada", estado.get("etapa", 1))) - 1)
	if revancha:
		_foto_frontera = estado.duplicate(true)
		_oleada_iniciada = false
		return
	_oleada_iniciada = bool(estado.get("oleada_iniciada", true))
	_intento = maxi(1, int(estado.get("intento", 1)))
	_derrotas_oleada = int(estado.get("derrotas_oleada", maxi(0, _intento - 1)))
	_canasta = LogicaCortar.frascos_intento(_derrotas_oleada, _frascos_valores)
	_frascos = _canasta
	if not _oleada_iniciada:
		# Caso B: la oleada se presenta otra vez, con la canasta llena del intento.
		_foto_frontera = estado.duplicate(true)
		_en_frontera = true
		_resembrar()
		_actualizar_ventanas()
		return
	_liberados = (estado.get("liberados", []) as Array).duplicate()
	_desfile = _liberados.duplicate()
	_pool = LogicaCortar.pool_sin(_oleada.get("pool", {}), _liberados)
	_toby_ayudo = bool(estado.get("toby_ayudo", false))
	_siesta_usada = bool(estado.get("siesta_usada", false))
	_trompeta_usada = bool(estado.get("trompeta_usada", false))
	var guardados := int(estado.get("frascos_restantes", _canasta))
	_frascos = LogicaCortar.frascos_al_retomar(guardados, _retomar_valores, _canasta)
	_frascos_agregados = _frascos > guardados
	_resembrar()
	_actualizar_ventanas()


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _dur(clave: String, defecto: float) -> float:
	return float(nivel.get("duraciones", {}).get(clave, defecto))


func _vec(a, defecto: Vector2) -> Vector2:
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return defecto


func _ahora_ms() -> int:
	return Time.get_ticks_msec()


func _esperar(segundos: float) -> void:
	var s := segundos * escala_tiempo
	if s <= 0.0 or not is_inside_tree():
		return
	await get_tree().create_timer(s).timeout


func _lista_voz(clave: String) -> Array:
	var v = nivel.get("lineas_voz", {}).get(clave, [])
	return v if v is Array else ([v] if str(v) != "" else [])


## Voz por clave (y sub-clave si es un mapa). Arreglo = variantes al azar. "PENDIENTE" o un archivo que no existe
## = sin voz y sin error (el juego funciona sin audio).
func _voz(clave: String, sub: String = "") -> void:
	var v = nivel.get("lineas_voz", {}).get(clave, "")
	if v is Dictionary:
		v = v.get(sub, "")
	if v is Array:
		v = v[_rng.randi_range(0, v.size() - 1)] if not v.is_empty() else ""
	_voz_ruta(clave if sub == "" else clave + ":" + sub, str(v))


func _voz_ruta(etiqueta: String, ruta: String) -> void:
	voces_dichas.append(etiqueta)
	if ruta == "" or ruta == "PENDIENTE":
		return
	if ResourceLoader.exists(resolver_ruta_audio(ruta)):
		reproducir_voz(ruta)


func _voces_en_cadena(rutas: Array) -> void:
	for ruta in rutas:
		_voz_ruta("cadena", str(ruta))
		await _esperar_voz_libre(4.0)
		if not is_inside_tree():
			return


func _voz_despues(clave: String) -> void:
	await _esperar_voz_libre(3.0)
	if is_inside_tree():
		_voz(clave)


func _sfx(nombre: String, tono: float = 1.0, volumen_db: float = 0.0) -> void:
	var ruta: String = SFX.get(nombre, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		reproducir_sfx(ruta, tono, volumen_db)


# ---------------------------------------------------------------------------
# Ganchos de arnes
# ---------------------------------------------------------------------------

## Solo arneses: revienta la burbuja `b` como si el trazo la hubiera cruzado (sin pasar por la pantalla).
func qa_reventar(b: BurbujaCortar) -> void:
	if _jugable():
		_reventar(b, 0)
