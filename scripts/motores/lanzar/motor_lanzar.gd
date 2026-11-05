extends MinijuegoBase

## Motor `lanzar` (docs/fichas/motor-lanzar.md v4.1; primera aplicacion: la Torre de la Coleccion, HE-77).
## Angry Birds por turnos: resortera de Nicole y Sofia (disparo solo tras arrastre >= 40 px, B2, con estabilizador
## M2), tiro guiado de Maxi que siempre rompe su punto debil (L4, M5), globos de experta de Sofia y rebotón de
## Nicole (bandeja), agarre del Coleccionauta como unico contador, charco que crece, canasta como reloj
## (`maxi_intercalado`, 13 + 4 por etapa), ayudas (+4, gigante desde el 3.er intento de la etapa, pausa desde la
## 3.a derrota), rearmado con dano parcial y 3 etapas seguidas con guardado entre etapas (R17 = A, §25.18).
##
## Contrato: extiende MinijuegoBase; el nucleo no conoce la Torre y la Torre no toca el guardado (emite
## `parcial_equipo_listo` y los momentos saltables genericos). Fisica (`RigidBody2D`) solo aqui: ver TorreLanzar.
## Cinematicas postergadas (PO 05-Nov): cada momento es un gancho saltable con reemplazo provisional por codigo
## (storyboard cierre_arcoiris.md §25.1, nivel CS/PD). La cinematica de victoria completa es HE-78.
##
## Decisiones del PO por delegacion al orquestador (05-Nov-2026): sin pausa entre etapas (la caida corta y la
## transicion llevan directo a la etapa siguiente) y la revancha se juega SOLO con E3 (sin parcial; estrellitas y
## record de una sola torre, §11 v3).

signal derribo_inminente(punto_impacto: Vector2, desde_soltar: bool)

const RECT_CASA := Rect2(1172, 8, 100, 96)
const RECT_COMETA := Rect2(8, 4, 110, 96)
const RECT_INDICADOR := Rect2(568, 16, 144, 48)
const ZONA_JUEGO := Rect2(0, 110, 1280, 490)
const Y_BARRA := 610.0
const COCO_PIES := Vector2(85, 584)
const RAMO := Rect2(10, 140, 110, 290)
const CANASTA := Rect2(4, 520, 70, 64)
const LADO_BANDEJA := 104.0
const SEP_BANDEJA := 16.0
const COLORES_UI := {"rojo": Color("#F0453A"), "amarillo": Color("#FFD23F"), "azul": Color("#3F8CFF"), "dorado": Color("#FFC94A")}
const CONTORNO := Color("#2B3350")
const TEX_COCO := "res://assets/sprites/personajes/coco_base.png"
const SFX := {
	"goma": "res://assets/audio/sfx/ui/toque.ogg", "boing": "res://assets/audio/sfx/ui/blup.ogg",
	"plop": "res://assets/audio/sfx/ui/puf.ogg", "fiu": "res://assets/audio/sfx/ui/fiuu.ogg",
	"pomp": "res://assets/audio/sfx/ui/seleccionar.ogg", "pomf": "res://assets/audio/sfx/ui/polvo_boing.ogg",
	"pop": "res://assets/audio/sfx/ui/soltar.ogg", "tilin": "res://assets/audio/sfx/ui/confirmar.ogg",
}

## Multiplica todas las esperas y animaciones del motor (no la fisica). Solo arneses: 1.0 en el juego.
var escala_tiempo := 1.0
## Reloj del estabilizador en ms; >= 0 lo fija el arnes (muestras con marcas de tiempo exactas).
var reloj_qa_ms := -1
## Voces pedidas (clave o clave:sub), existan o no los archivos: para el arnes.
var voces_dichas: Array[String] = []

var torre: TorreLanzar
var coleccionauta: ColeccionautaLanzar
var _fondo: Node2D
var _charco_nodo: Node2D
var _vista: Node2D
var _ui: Control
var _indicador: Control
var _boton_casa: Button
var _coco: Sprite2D
var _rng := RandomNumberGenerator.new()

# Composicion
var _clave := ""
var _semilla_id := ""
var _base := 13
var _extra_1 := 4
var _extra_2 := 0
var _voz_ultimo_globo := true
var _quien_empezo := ""

# Torre / etapa
var _etapas: Array = []
var _idx := 0
var _etapa: Dictionary = {}
var _agarre_inicial := 24
var _agarre_perdido := 0
var _etapas_ganadas: Array = []
var _etapa_iniciada := false
var _intento := 1
var _derrotas_etapa := 0
var _derrotas_torre := 0
var _ultimo_gag := ""
var _gag_actual := ""
var _globos_restantes := 13
var _canasta_llena := 13
var _globo_k := 0
var _gigante_pendiente := false
var _gigante_usado := false
var _gigante_visto_etapa := false
var _presentacion_vista := false
var _charco := Vector2(120, 24)
var _charco_colores: Array = []
var _rastros := {}
var _ayuda_brote := 0
var _intento_nuevo_listo := true
var _botadas_intento := 0

# Sesion (en memoria, nunca en el parcial)
var _turnos_perfil := {}
var _explicado := {}
var _carga_dicha := {}
var _nombre_dicho := {}
var _repetir_dicho := false
var _fallos_seguidos := 0
var _reacciones := 0

# Turno y tiro
var _fase := "espera"     # espera | listo | apuntando | vuelo | cierre | derribo | anticipacion | caida | transicion
var _perfil_turno := ""
var _id_turno := ""
var _tipo_cargado := "normal"
var _color := "rojo"
var _es_gigante := false
var _objetivo: BloqueLanzar
var _tiro_peso := 0
var _tiro_minimo := 0
var _tiro_golpe := false
var _tiro_botadas: Array = []
var _tiro_t0 := 0
var _trono_botado := false
var _globo_tiro: GloboLanzar
var _disparo_pendiente: Dictionary = {}
var ultimo_impacto := Vector2.INF
var ultimo_anillo := Vector2.INF
var _guia: Dictionary = {}

# Gesto
var _dedo := -1
var _gesto := ""          # "" | resortera | maxi | ignorar
var _contacto := Vector2.ZERO
var _armado := false
var _bolsa := Vector2(260, 430)
var _bolsa_sigue := false
var _muestras: Array = []
var _t_maxi := 0.0
var _flechita_t := 0.0
var _manito_t := -1.0

# Frontera, derribo, retomar
var _en_frontera := false
var _foto_frontera: Dictionary = {}
var _derribo_hecho := false
var _derribo_emitido := false
var _estado_derribo: Dictionary = {}
var _saltar_caida_encolado := false
var _restaurado := false
var _estado_rest: Dictionary = {}
var _globos_agregados := false
var _tweens: Array[Tween] = []
var _inclinacion := 0.0
var _t_vida := 0.0


func _ready() -> void:
	super._ready()
	if nivel.is_empty():
		return
	_rng.seed = int(nivel.get("semilla", 1207))
	_etapas = nivel.get("etapas", [])
	_validar()
	_crear_escena()
	_resolver_composicion()
	_idx = (_etapas.size() - 1) if revancha else 0
	if revancha:
		_presentacion_vista = true
	_armar_etapa(_idx)
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


func _validar() -> void:
	for e in LogicaAgarre.validar_nivel(nivel):
		push_error("motor_lanzar: " + e)
	for etapa in _etapas:
		for e in LogicaAgarre.validar_etapa(etapa, nivel):
			push_error("motor_lanzar: " + e)


# ---------------------------------------------------------------------------
# Escena (arte provisional por codigo; HE-74 trae el arte)
# ---------------------------------------------------------------------------

func _crear_escena() -> void:
	_fondo = Node2D.new()
	_fondo.name = "fondo"
	_fondo.z_index = -10
	_fondo.draw.connect(_dibujar_fondo)
	add_child(_fondo)
	_charco_nodo = Node2D.new()
	_charco_nodo.name = "charco"
	_charco_nodo.z_index = -5
	_charco_nodo.draw.connect(_dibujar_charco)
	add_child(_charco_nodo)
	torre = TorreLanzar.new()
	torre.name = "torre"
	add_child(torre)
	torre.bloque_botado.connect(_al_botado)
	torre.bloque_roto.connect(_al_roto)
	torre.globo_retirado.connect(_al_retirar_globo)
	torre.primer_impacto.connect(func(g: GloboLanzar, p: Vector2) -> void:
		if g == _globo_tiro or g.principal:
			if ultimo_impacto == Vector2.INF:
				ultimo_impacto = p)
	torre.impacto_guiado.connect(_al_impacto_guiado)
	torre.golpe_directo.connect(_al_golpe_directo)
	torre.confeti_exploto.connect(func(p: Vector2) -> void:
		_sfx("pomf")
		_estallido(p, [Color("#E0309A"), Color("#FFD23F"), Color("#4FD8E0")], 22))
	torre.rebote_resorte.connect(func(_b: BloqueLanzar) -> void: _sfx("boing", 1.3))
	torre.tiro_terminado.connect(_fin_tiro)
	coleccionauta = ColeccionautaLanzar.new()
	coleccionauta.name = "coleccionauta"
	add_child(coleccionauta)
	_coco = Sprite2D.new()
	_coco.name = "coco"
	if ResourceLoader.exists(TEX_COCO):
		_coco.texture = load(TEX_COCO)
		_coco.scale = Vector2.ONE * (130.0 / float(_coco.texture.get_height()))
		_coco.offset = Vector2(0, -_coco.texture.get_height() / 2.0)
	_coco.position = COCO_PIES
	add_child(_coco)
	_vista = Node2D.new()
	_vista.name = "vista"
	_vista.z_index = 5
	_vista.draw.connect(_dibujar_vista)
	add_child(_vista)
	var capa := CanvasLayer.new()
	capa.name = "capa_ui"
	capa.layer = 1
	add_child(capa)
	_ui = Control.new()
	_ui.name = "ui"
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.size = Vector2(1280, 720)
	capa.add_child(_ui)
	_indicador = Control.new()
	_indicador.name = "indicador_torrecitas"
	_indicador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicador.position = RECT_INDICADOR.position
	_indicador.size = RECT_INDICADOR.size
	_indicador.draw.connect(_dibujar_indicador)
	_ui.add_child(_indicador)
	_boton_casa = Button.new()
	_boton_casa.name = "boton_casa"
	_boton_casa.focus_mode = Control.FOCUS_NONE
	_boton_casa.position = RECT_CASA.position
	_boton_casa.size = RECT_CASA.size
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


func _dibujar_fondo() -> void:
	# Cielo violeta con estrellas, planeta lejano con anillo y el arcoiris completo (C3: arte de HE-74).
	for i in 12:
		var t := float(i) / 11.0
		_fondo.draw_rect(Rect2(0, i * 60, 1280, 61), Color("#2A1450").lerp(Color("#7B4FB8"), t))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 60:
		_fondo.draw_circle(Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 420)), rng.randf_range(1.0, 2.6), Color(1, 1, 1, 0.8))
	_fondo.draw_circle(Vector2(1110, 170), 46, Color("#FF9ED6"))
	_fondo.draw_arc(Vector2(1110, 170), 70, PI * 0.9, PI * 2.1, 40, Color("#FFE38A"), 6.0, true)
	var colores := [Color("#F0453A"), Color("#FF9A3D"), Color("#FFD23F"), Color("#59C26A"), Color("#3F8CFF"), Color("#7B5CFF")]
	for k in colores.size():
		_fondo.draw_arc(Vector2(640, 760), 620.0 - k * 22.0, PI * 1.08, PI * 1.92, 64, Color(colores[k], 0.55), 20.0, true)
	_fondo.draw_rect(Rect2(0, 584, 1280, 136), Color("#5BC27A"))
	_fondo.draw_rect(Rect2(0, 584, 1280, 8), Color("#3E9A5A"))
	# La galleta-plataforma.
	if torre != null:
		var p := torre.plataforma_rect()
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color("#E3A857")
		caja.border_color = CONTORNO
		caja.set_border_width_all(3)
		caja.set_corner_radius_all(14)
		_fondo.draw_style_box(caja, p)
		for k in 6:
			_fondo.draw_circle(p.position + Vector2(30 + k * 62, p.size.y / 2.0), 5, Color("#8A4B1E"))


func _dibujar_charco() -> void:
	var centro := _vec(nivel.get("charco", {}).get("centro", [990, 580]))
	var puntos := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		puntos.append(centro + Vector2(cos(a) * _charco.x / 2.0, sin(a) * _charco.y / 2.0))
	var base_color := Color("#FF9ED6")
	if not _charco_colores.is_empty():
		base_color = COLORES_UI.get(str(_charco_colores[-1]), base_color)
	_charco_nodo.draw_colored_polygon(puntos, Color(base_color, 0.85))
	for k in mini(_charco_colores.size(), 6):
		var c: Color = COLORES_UI.get(str(_charco_colores[k]), Color.WHITE)
		_charco_nodo.draw_arc(centro + Vector2((k - 2.5) * _charco.x * 0.12, 0), _charco.y * 0.25, 0, PI * 1.5, 12, c, 3.0)


func _dibujar_indicador() -> void:
	# Tres torrecitas sin numeros ni texto (storyboard §25.2.2): gris por jugar, pintadas las ganadas, la actual respira.
	for k in 3:
		var base := Vector2(k * 52 + 2, 0)
		var escala := 1.0
		if k == _idx and not _etapas_ganadas.has(_id_etapa(k)):
			escala = 1.0 + 0.06 * (0.5 + 0.5 * sin(_t_vida * PI)) * (1.6 if k == 2 else 1.0)
		var r := Rect2(base + Vector2(20, 24) - Vector2(20, 24) * escala, Vector2(40, 48) * escala)
		if _etapas_ganadas.has(_id_etapa(k)):
			for f in 3:
				_indicador.draw_rect(Rect2(r.position + Vector2(0, f * r.size.y / 3.0), Vector2(r.size.x, r.size.y / 3.0)), [Color("#F0453A"), Color("#FFD23F"), Color("#3F8CFF")][f])
		else:
			_indicador.draw_rect(r, Color(1, 1, 1, 0.25))
		_indicador.draw_rect(r, CONTORNO, false, 3.0)


func _id_etapa(k: int) -> String:
	return str(_etapas[k].get("id", "e%d" % (k + 1))) if k < _etapas.size() else ""


func _dibujar_vista() -> void:
	var res: Dictionary = nivel.get("resortera", {})
	var reposo := _vec(res.get("bolsa_reposo", [260, 430]))
	var base := _vec(res.get("base", [260, 584]))
	# Canasta y ramo: un globo por cada uno que queda (sin numeros, §8.2).
	_vista.draw_rect(CANASTA, Color("#C98A4B"))
	_vista.draw_rect(CANASTA, CONTORNO, false, 3.0)
	var colores: Array = nivel.get("colores_globos", ["rojo", "amarillo", "azul"])
	for i in _globos_restantes:
		var col := i % 2
		var fila := i / 2
		var p := Vector2(RAMO.position.x + 30 + col * 50, RAMO.end.y - 22 - fila * (RAMO.size.y - 44) / 8.0)
		_vista.draw_line(p, CANASTA.get_center(), Color(1, 1, 1, 0.5), 1.5)
		_vista.draw_circle(p, 22, COLORES_UI.get(str(colores[(_globo_k + i) % colores.size()]), Color.WHITE))
		_vista.draw_arc(p, 22, 0, TAU, 20, CONTORNO, 2.0)
	# Resortera de regaliz.
	var horquilla_i := base + Vector2(-34, -150)
	var horquilla_d := base + Vector2(34, -150)
	_vista.draw_line(base, base + Vector2(0, -90), Color("#F4F4F4"), 16.0)
	_vista.draw_line(base + Vector2(0, -90), horquilla_i, Color("#F4F4F4"), 14.0)
	_vista.draw_line(base + Vector2(0, -90), horquilla_d, Color("#F4F4F4"), 14.0)
	_vista.draw_line(base + Vector2(0, -40), base + Vector2(0, -60), Color("#F0453A"), 16.0)
	var bolsa := _bolsa
	if _manito_t >= 0.0:
		var u := clampf(_manito_t / 0.8, 0.0, 1.0)
		bolsa = reposo + Vector2(-110, 100).normalized() * 150.0 * sin(u * PI) * 0.5
	_vista.draw_line(horquilla_i, bolsa, Color("#C2185B"), 6.0)
	_vista.draw_line(horquilla_d, bolsa, Color("#C2185B"), 6.0)
	if _fase in ["listo", "apuntando"] and _perfil_turno != "":
		var radio := 72.0 if _es_gigante else 26.0
		_vista.draw_circle(bolsa, radio, COLORES_UI.get("dorado" if _es_gigante else _color, Color.WHITE))
		_vista.draw_arc(bolsa, radio, 0, TAU, 24, CONTORNO, 3.0)
	if _manito_t >= 0.0:
		_vista.draw_circle(bolsa, 45, Color(1, 1, 1, 0.6))
	# Rastro del tiro anterior (solo el suyo, 35 %).
	var rastro: PackedVector2Array = _rastros.get(_perfil_turno, PackedVector2Array())
	if _fase in ["listo", "apuntando"]:
		for p in rastro:
			_vista.draw_circle(p, 4, Color(1, 1, 1, 0.35))
	# Guia (§5.4).
	if _fase == "apuntando" and not _guia.is_empty():
		var puntos: PackedVector2Array = _guia.get("puntos", PackedVector2Array())
		var n := puntos.size() if _perfil_turno == "brote" else mini(puntos.size(), int(_perfil_cfg().get("guia_arranque_puntos", 4)))
		for i in n:
			_vista.draw_circle(puntos[i], 5, Color.WHITE)
		if _perfil_turno == "brote" and _guia.get("impacto", Vector2.INF) != Vector2.INF:
			_vista.draw_arc(_guia["impacto"], 20, 0, TAU, 24, Color("#FFD23F"), 4.0)
	# Flechita fantasma "hacia atras".
	if _flechita_t > 0.0:
		var a := Color(1, 1, 1, clampf(_flechita_t / 0.6, 0.0, 1.0))
		_vista.draw_line(reposo + Vector2(40, 0), reposo + Vector2(-60, 40), a, 8.0)
		_vista.draw_colored_polygon(PackedVector2Array([reposo + Vector2(-80, 48), reposo + Vector2(-50, 20), reposo + Vector2(-44, 58)]), a)
	# Bandeja.
	var tipos := _tipos_bandeja()
	for i in tipos.size():
		var r := _rect_bandeja(i)
		var elegido: bool = tipos[i] == _tipo_cargado
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color.WHITE if elegido else Color(1, 1, 1, 0.65)
		caja.border_color = Color("#7B5CFF") if elegido else CONTORNO
		caja.set_border_width_all(5 if elegido else 3)
		caja.set_corner_radius_all(20)
		var alfa := 0.6 if _fase == "apuntando" else (1.0 if elegido else 0.65)
		_vista.draw_style_box(caja, r.grow(4.0 if elegido else 0.0))
		_vista.draw_circle(r.get_center(), 30, Color(COLORES_UI.get(_color, Color.WHITE), alfa))
		_dibujar_marca_tipo(r.get_center(), str(tipos[i]))
	# Globo fuera de pantalla por arriba: flechita pegada al borde.
	for g in torre.globos:
		if not g.retirado and g.global_position.y < 0:
			var x := clampf(g.global_position.x, 20, 1260)
			_vista.draw_colored_polygon(PackedVector2Array([Vector2(x, 4), Vector2(x - 12, 26), Vector2(x + 12, 26)]), COLORES_UI.get(g.color_globo, Color.WHITE))


func _dibujar_marca_tipo(c: Vector2, tipo: String) -> void:
	match tipo:
		"rebota":
			var zz := PackedVector2Array()
			for k in 7:
				zz.append(c + Vector2(-18 + k * 6, 4 if k % 2 == 0 else 14))
			_vista.draw_polyline(zz, Color.WHITE, 3.0)
		"triple":
			_vista.draw_circle(c + Vector2(20, 18), 12, Color.WHITE)
			_vista.draw_circle(c + Vector2(-20, 18), 12, Color.WHITE)
		"pesado":
			_vista.draw_line(c + Vector2(-14, -2), c + Vector2(-4, -2), CONTORNO, 3.0)
			_vista.draw_line(c + Vector2(4, -2), c + Vector2(14, -2), CONTORNO, 3.0)


func _estallido(punto: Vector2, colores: Array, cantidad: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = clampi(cantidad, 1, 36)
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 600)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	p.color = colores[0] if not colores.is_empty() else Color.WHITE
	p.position = punto
	p.z_index = 6
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


# ---------------------------------------------------------------------------
# Composicion y configuracion
# ---------------------------------------------------------------------------

func _resolver_composicion() -> void:
	var intentos: Dictionary = nivel.get("intentos", {})
	_base = int(intentos.get("globos_base", 13))
	_extra_1 = 0
	for ayuda in intentos.get("ayudas", []):
		_extra_1 += int(ayuda.get("globos_extra", 0))
	_voz_ultimo_globo = bool(intentos.get("voz_ultimo_globo", true))
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
		_base = int(comp.get("globos_base", _base))
		_extra_1 = int(comp.get("globos_extra_1", _extra_1))
		_extra_2 = int(comp.get("ayuda_2", {}).get("globos_extra", 0))
		_voz_ultimo_globo = bool(comp.get("voz_ultimo_globo", _voz_ultimo_globo)) and _semilla_id != ""
	else:
		_semilla_id = "solo" if _perfil_solo() == "semilla" else ""


func _config_gestor() -> Dictionary:
	var config: Dictionary = nivel.get("equipo", {}).duplicate(true)
	var comp: Dictionary = config.get("composiciones", {}).get(_clave, {})
	config.erase("composiciones")
	if comp.has("orden"):
		config["orden"] = comp["orden"]
	config["rival"] = null
	config["confirmar_turno"] = true
	config["lineas_voz"] = nivel.get("lineas_voz", {})
	return config


func _perfil_solo() -> String:
	if id_perfil != "":
		return perfil_de(id_perfil)
	return str(nivel.get("perfil", "brote"))


func _perfil_cfg(perfil: String = "") -> Dictionary:
	return nivel.get("perfiles", {}).get(perfil if perfil != "" else _perfil_turno, {})


# ---------------------------------------------------------------------------
# Etapas
# ---------------------------------------------------------------------------

func _armar_etapa(idx: int) -> void:
	_idx = clampi(idx, 0, maxi(0, _etapas.size() - 1))
	_etapa = _etapas[_idx] if not _etapas.is_empty() else {}
	torre.armar(_etapa.get("torre", {}), nivel)
	var comp_agarre = nivel.get("equipo", {}).get("composiciones", {}).get(_clave, {}).get("agarre_inicial", null)
	_agarre_inicial = int(comp_agarre) if (comp_agarre is float or comp_agarre is int) else int(_etapa.get("agarre_inicial", 20))
	_agarre_perdido = 0
	_intento = 1
	_derrotas_etapa = 0
	_canasta_llena = _base
	_globos_restantes = _base
	_globo_k = 0
	_gigante_pendiente = false
	_gigante_usado = false
	_gigante_visto_etapa = false
	_etapa_iniciada = false
	_botadas_intento = 0
	_ayuda_brote = 0
	_rastros = {}
	_charco = _vec(nivel.get("charco", {}).get("inicial", [120, 24]))
	_charco_colores = []
	_derribo_hecho = false
	_trono_botado = false
	_intento_nuevo_listo = true
	_inclinar(0.0)
	coleccionauta.nivel_lunares = _etapas_ganadas.size()
	coleccionauta.sombrerito = false
	coleccionauta.scale = Vector2.ONE
	_actualizar_coleccionauta()
	_fondo.queue_redraw()
	_charco_nodo.queue_redraw()
	_vista.queue_redraw()
	_indicador.queue_redraw()


func ultima_etapa() -> bool:
	return _idx >= _etapas.size() - 1


func etapa_actual() -> int:
	return _idx + 1


func agarre_restante() -> int:
	return _agarre_inicial - _agarre_perdido


func globos_restantes() -> int:
	return _globos_restantes


func intento_actual() -> int:
	return _intento


func fase() -> String:
	return _fase


func perfil_turno() -> String:
	return _perfil_turno


func _actualizar_coleccionauta() -> void:
	var cfg: Dictionary = nivel.get("coleccionauta", {})
	coleccionauta.estado_cara = LogicaAgarre.estado_cara(_agarre_perdido, _agarre_inicial, nivel.get("agarre", {}).get("estados_cara", [0.25, 0.5, 0.75]))
	_ubicar_coleccionauta(cfg)


func _ubicar_coleccionauta(cfg: Dictionary = {}) -> void:
	if torre.trono == null or _fase in ["caida", "transicion"]:
		return
	if cfg.is_empty():
		cfg = nivel.get("coleccionauta", {})
	var off := _vec(cfg.get("offset_en_trono", [0, -40]))
	var desliz := float(cfg.get("deslizamiento_max_px", 60)) * clampf(float(_agarre_perdido) / maxf(1.0, _agarre_inicial), 0.0, 1.0)
	var t := torre.trono
	coleccionauta.position = t.position + Vector2(0, -t.alto / 2.0) + Vector2(off.x + desliz, off.y + 40)
	# El Area2D sigue al sprite (M3), solo con la torre congelada.
	torre.area_coleccionauta.position = coleccionauta.position + Vector2(0, -60)


## Estado inicial de una etapa (§25.18.1): lo que devuelve el parcial desde el cuadro del derribo.
func _estado_inicial_etapa(idx: int) -> Dictionary:
	return {
		"etapa": idx + 1, "etapas_ganadas": _etapas_ganadas.duplicate(), "etapa_iniciada": false,
		"intento": 1, "derrotas_etapa": 0, "globos_restantes": _base, "gigante_usado": false, "agarre_perdido": 0,
		"bloques": {}, "manchas": [], "charco": null, "rastros": {}, "ayuda_brote_turnos_sin_derribo": 0,
		"presentacion_vista": true, "derrotas": _derrotas_torre, "ultimo_gag": _ultimo_gag,
	}


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
	if not is_inside_tree() or _derribo_hecho:
		return
	_empezar_turnos()


func _empezar_turnos() -> void:
	if turnos != null:
		if _restaurado:
			turnos.empezar_retomando()
		else:
			turnos.empezar()
	else:
		_turno_solo()


func _entrada() -> void:
	if revancha:
		_voz("intro_revancha")
		await _intro_corta()
	else:
		if not _presentacion_vista:
			await _momento("presenta_torre", _dur("presentacion_s", 12.0), func() -> void:
				_animar_armado(2.0)
				_voces_en_cadena(_lista_voz("presentacion")))
			_presentacion_vista = true
		await _intro_corta()
	await _presentar_especial()


## La intro corta (§25.18.3): `intro_coleccionauta` + `intro`. Nunca bloquea la entrada.
func _intro_corta(solo_intro: bool = false) -> void:
	var lista := _lista_voz("intro_ronda")
	voces_dichas.append("intro_corta" if not solo_intro else "intro")
	if solo_intro and lista.size() >= 2:
		lista = [lista[1]]
	await _voces_en_cadena(lista)


func _presentar_especial() -> void:
	var especial := str(_etapa.get("presenta_especial", ""))
	if especial == "" or especial == "null":
		return
	await _momento("presenta_" + especial, _dur("presenta_especial_s", 3.8), func() -> void:
		_voz("presenta_especial", especial)
		for b in torre.lista_bloques():
			if b.material_bloque == especial:
				b.halo = 44.0
				b.halo_color = Color("#B57BFF"))


## Re-entrada al retomar (§25.18.4): caso A (la etapa a medias) o B (sin tiros). Se salta desde la 1.a vez.
func _retomar() -> void:
	var caso_a := _etapa_iniciada
	var jugado := await _momento("retomar_torre", _dur("retomar_a_s" if caso_a else "retomar_b_s", 5.0), func() -> void:
		if caso_a:
			_intro_corta()
		else:
			_animar_armado(2.5)
			var llegada := str(_etapa.get("voz_llegada", ""))
			if _idx > 0 and llegada != "" and llegada != "<null>":
				_voz("etapa_llegada", llegada)
				_intro_corta(true)
			elif _presentacion_vista:
				_intro_corta()
			else:
				_voces_en_cadena(_lista_voz("presentacion"))
				_presentacion_vista = true)
	if not caso_a:
		await _presentar_especial()
	elif jugado and _globos_agregados:
		_voz("encontre_globos")


# ---------------------------------------------------------------------------
# Momentos saltables (ganchos con reemplazo provisional, storyboard §25.1)
# ---------------------------------------------------------------------------

## Reproduce el momento `id` (provisional por codigo) y espera a que termine o lo salten. Devuelve false si el
## contenedor lo salto en el mismo instante (politica `una_vez`): entonces no se ve ni se oye nada.
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


func saltar_momento(id_animacion: String) -> void:
	if not momento_saltable_en_curso(id_animacion):
		return
	_cortar_tweens()
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()
	_estado_final_momento(id_animacion)
	terminar_momento_saltable(id_animacion)


## §13.2: corta la caida final y deja el estado final del §9.4. La anticipacion nunca se salta: se encola.
func saltar_derribo() -> void:
	if _fase == "anticipacion":
		_saltar_caida_encolado = true
	elif momento_saltable_en_curso("caida_torre"):
		saltar_momento("caida_torre")


func estado_derribo() -> Dictionary:
	return _estado_derribo.duplicate(true)


func _estado_final_momento(id: String) -> void:
	match id:
		"presenta_torre", "retomar_torre":
			_fijar_poses_armado()
		"caida_etapa", "caida_torre":
			_estado_final_caida(id == "caida_torre")
		_:
			if id.begins_with("presenta_"):
				for b in torre.lista_bloques():
					if b.halo_color == Color("#B57BFF"):
						b.halo = 0.0
				_aplicar_halos()


func _cortar_tweens() -> void:
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


var _poses_armado: Dictionary = {}

## La torre llega volando por filas, de abajo hacia arriba (T1, TR3 y la re-entrada B). Solo dibujo: los cuerpos
## estan congelados y terminan en su pose exacta.
func _animar_armado(duracion: float) -> void:
	_poses_armado = {}
	var lista: Array = []
	for id in torre.orden_ids:
		var b: BloqueLanzar = torre.bloques[id]
		if b.estado == "roto":
			continue
		_poses_armado[id] = b.transform
		lista.append(b)
	lista.sort_custom(func(a: BloqueLanzar, c: BloqueLanzar) -> bool: return a.position.y > c.position.y)
	var paso := duracion * escala_tiempo / maxf(1.0, float(lista.size()))
	for i in lista.size():
		var b: BloqueLanzar = lista[i]
		var destino: Transform2D = _poses_armado[b.id_bloque]
		b.position = Vector2(1320, 260)
		var tw := _tween()
		tw.tween_interval(paso * i)
		tw.tween_property(b, "position", destino.origin, maxf(0.01, 0.3 * escala_tiempo)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			b.transform = destino
			_sfx("pop", 1.0 + 0.03 * i))


func _fijar_poses_armado() -> void:
	for id in _poses_armado:
		var b: BloqueLanzar = torre.bloques.get(id, null)
		if b != null:
			b.transform = _poses_armado[id]
	_poses_armado = {}
	_ubicar_coleccionauta()


## Corona alrededor del charco (nunca encima): pose deterministica por pieza.
func _pose_corona(i: int, b: BloqueLanzar) -> Vector2:
	var lado := -1.0 if i % 2 == 0 else 1.0
	var anillo := float(i / 2)
	var x := clampf(990.0 + lado * (270.0 + anillo * 26.0), 640.0, 1260.0)
	return Vector2(x, 584.0 - minf(b.alto, b.ancho) / 2.0)


func _animar_caida(final: bool) -> void:
	var i := 0
	for b in torre.lista_bloques():
		if b.estado == "roto":
			continue
		var destino := _pose_corona(i, b)
		i += 1
		var tw := _tween()
		tw.tween_interval((1.5 if not final else 2.0) * escala_tiempo)
		tw.tween_property(b, "position", destino, maxf(0.01, 0.9 * escala_tiempo)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(b, "rotation", PI / 2.0 if i % 3 == 0 else 0.0, maxf(0.01, 0.9 * escala_tiempo))
	if torre.trono != null:
		var tw2 := _tween()
		tw2.tween_interval(1.5 * escala_tiempo)
		tw2.tween_property(torre.trono, "position", Vector2(990, 566), maxf(0.01, 0.9 * escala_tiempo))
	var centro := _vec(nivel.get("charco", {}).get("centro", [990, 580]))
	var tw3 := _tween()
	tw3.tween_interval(1.5 * escala_tiempo)
	tw3.tween_property(coleccionauta, "position", centro + Vector2(0, -2), maxf(0.01, 0.9 * escala_tiempo)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw3.tween_callback(func() -> void:
		_sfx("plop")
		coleccionauta.scale = Vector2(1.15, 0.75)
		coleccionauta.nivel_lunares = 3 if final else _etapas_ganadas.size()
		_estallido(centro, [COLORES_UI["rojo"], COLORES_UI["amarillo"], COLORES_UI["azul"]], 30)
		if turnos != null and turnos.barra != null:
			for id in equipo:
				turnos.barra.gesto(id))
	tw3.tween_property(coleccionauta, "scale", Vector2.ONE, maxf(0.01, 0.2 * escala_tiempo))


func _estado_final_caida(final: bool) -> void:
	var i := 0
	for b in torre.lista_bloques():
		if b.estado == "roto":
			continue
		b.position = _pose_corona(i, b)
		i += 1
	if torre.trono != null:
		torre.trono.position = Vector2(990, 566)
	_inclinar(0.0)
	coleccionauta.position = _vec(nivel.get("charco", {}).get("centro", [990, 580])) + Vector2(0, -2)
	coleccionauta.scale = Vector2.ONE
	coleccionauta.nivel_lunares = 3 if final else _etapas_ganadas.size()
	coleccionauta.sombrerito = final
	_indicador.queue_redraw()


## Inclina toda la torre (solo dibujo y poses congeladas) con pivote en el centro de la plataforma.
func _inclinar(grados: float) -> void:
	_inclinacion = grados
	if torre == null:
		return
	var pivote := Vector2(990, 584)
	torre.transform = Transform2D(0.0, pivote) * Transform2D(deg_to_rad(grados), Vector2.ZERO) * Transform2D(0.0, -pivote)


# ---------------------------------------------------------------------------
# Turnos
# ---------------------------------------------------------------------------

func _turno_solo() -> void:
	await _esperar(0.4)
	if not is_inside_tree() or _derribo_hecho:
		return
	_al_turno_iniciado(id_perfil, _perfil_solo())


func _al_turno_iniciado(id: String, perfil: String) -> void:
	if _derribo_hecho:
		return
	_id_turno = id
	_perfil_turno = perfil
	_turnos_perfil[perfil] = int(_turnos_perfil.get(perfil, 0)) + 1
	_repetir_dicho = false
	# Coco saca un globo de la canasta (paso 4 del pase, §8.2).
	_globos_restantes = maxi(0, _globos_restantes - 1)
	var colores: Array = nivel.get("colores_globos", ["rojo", "amarillo", "azul"])
	_color = str(colores[_globo_k % colores.size()])
	_globo_k += 1
	_es_gigante = perfil == "semilla" and _gigante_pendiente
	if _es_gigante:
		_gigante_pendiente = false
		_gigante_usado = true
	_tipo_cargado = "gigante" if _es_gigante else "normal"
	_bolsa = _vec(nivel.get("resortera", {}).get("bolsa_reposo", [260, 430]))
	_objetivo = _elegir_objetivo_semilla() if perfil == "semilla" else null
	_aplicar_halos()
	_fase = "listo"
	_vista.queue_redraw()
	_voces_de_turno(perfil)


func _voces_de_turno(perfil: String) -> void:
	if perfil == "semilla":
		if _es_gigante:
			if not _gigante_visto_etapa:
				_gigante_visto_etapa = true
				_voz("gigante_aparece")
			_voz("gigante_turno")
		else:
			_voz("maxi_carga")
	elif perfil == "brote" and int(_turnos_perfil.get("brote", 0)) == 2:
		# D5 (§25.18.5): la bandeja se presenta en el 2.o turno de Nicole de la sesion, en lugar de `carga`.
		var jugado := await _momento("presenta_bandeja_nicole", 3.5, func() -> void:
			_voz("elige_globo_presenta_nicole"))
		if not jugado and _fase in ["listo", "apuntando"]:
			_voz_carga()
	else:
		_voz_carga()
		if perfil in ["brote", "estrella"] and not _explicado.get(perfil, false):
			# M1: la explicacion del tiro, solo en el primer turno de cada nina de la sesion.
			_explicado[perfil] = true
			_voz("explica_tiro")
			_manito_t = 0.0
	if _globos_restantes == 0 and _voz_ultimo_globo and perfil == "semilla":
		_voz("ultimo_globo")


func _voz_carga() -> void:
	if not _carga_dicha.get(_color, false):
		_carga_dicha[_color] = true
		_voz("carga", _color)
	else:
		_voz("carga_corta", _color)


func _elegir_objetivo_semilla() -> BloqueLanzar:
	var pd: Dictionary = _etapa.get("torre", {}).get("puntos_debiles", {})
	var claves := ["gigante_objetivo"] if _es_gigante else ["semilla", "semilla_respaldo"]
	for clave in claves:
		for id in pd.get(clave, []):
			var b := torre.bloque(str(id))
			if b != null and b.activo() and not b.botado:
				return b
	# Respaldo final: cualquier pieza en pie que no sostenga al trono ni sea resorte (G2).
	for b in torre.lista_bloques():
		if b.activo() and not b.botado and not b.id_bloque in torre.columna_trono and b.material_bloque != "resorte":
			return b
	for b in torre.lista_bloques():
		if b.activo():
			return b
	return null


func _aplicar_halos() -> void:
	var pd: Dictionary = _etapa.get("torre", {}).get("puntos_debiles", {})
	for b in torre.lista_bloques():
		b.halo = 0.0
	if _perfil_turno == "semilla" and _objetivo != null:
		_objetivo.halo = maxf(_objetivo.ancho, _objetivo.alto) * 0.8 + 18.0
		_objetivo.halo_color = Color("#FFD23F")
	elif _perfil_turno in ["brote", "estrella"]:
		var cfg = pd.get(_perfil_turno, {})
		if cfg is Dictionary:
			var r := float(cfg.get("halo_px", 72)) / 2.0
			if _perfil_turno == "brote" and _ayuda_brote >= int(_perfil_cfg("brote").get("ayuda_tras_turnos_sin_derribo", 2)):
				r *= 2.0
			for id in cfg.get("ids", []):
				var b := torre.bloque(str(id))
				if b != null and b.activo() and not b.botado:
					b.halo = r
					b.halo_color = Color("#FFE38A")


func _jugada_automatica() -> void:
	if _fase == "listo" and _perfil_turno == "semilla":
		_voz("maxi_regalito")
		_disparar_guiado()


func _turno_jugable() -> bool:
	if _fase != "listo" and _fase != "apuntando":
		return false
	if turnos != null:
		return turnos.turno_activo() and not turnos.entrada_bloqueada()
	return true


# ---------------------------------------------------------------------------
# Entrada (unificada: el proyecto emula el toque desde el mouse, solo eventos tactiles)
# ---------------------------------------------------------------------------

func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		procesar_toque(evento.position, evento.pressed, evento.index)
	elif evento is InputEventScreenDrag:
		procesar_arrastre(evento.position, evento.index)


func _ahora_ms() -> int:
	return reloj_qa_ms if reloj_qa_ms >= 0 else Time.get_ticks_msec()


func procesar_toque(pos: Vector2, presionado: bool, dedo: int = 0) -> void:
	if presionado:
		if _dedo >= 0:
			return   # Solo cuenta el primer dedo (§5.1).
		# Las presentaciones las corta el propio motor con cualquier toque en la zona de juego (§25.18.6).
		if ZONA_JUEGO.has_point(pos):
			for id in ["presenta_confeti", "presenta_resorte", "presenta_bandeja_nicole"]:
				if momento_saltable_en_curso(id):
					saltar_momento(id)
		# Toque en vuelo del triple (m4): solo en la zona de juego y desde 0,15 s.
		if _fase == "vuelo" and _globo_tiro != null and is_instance_valid(_globo_tiro) and _globo_tiro.tipo == "triple" \
				and not _globo_tiro.dividido and pos.y >= 110.0 and pos.y <= 600.0:
			var desde := float(nivel.get("proyectiles", {}).get("triple", {}).get("division", {}).get("toque_desde_s", 0.15))
			if float(_globo_tiro.cuadros) / 60.0 >= desde:
				torre.dividir(_globo_tiro, nivel.get("proyectiles", {}).get("triple", {}).get("division", {}))
				_globo_tiro = null
				return
		if not _turno_jugable() or RECT_CASA.has_point(pos) or RECT_COMETA.has_point(pos):
			_toque_decorativo(pos)
			return
		if _perfil_turno == "semilla":
			if pos.y < Y_BARRA and pos.y >= 110.0:
				_dedo = dedo
				_gesto = "maxi"
				_t_maxi = 0.0
				_contacto = pos
				_sfx("goma")
				_bolsa = _reposo() + Vector2(-60, 50)
				_fase = "apuntando"
				_vista.queue_redraw()
			return
		var i := _indice_bandeja(pos)
		if i >= 0 and _fase == "listo":
			elegir_globo(str(_tipos_bandeja()[i]))
			return
		var radio := LogicaAgarre.radio_agarre(nivel.get("resortera", {}), _perfil_turno)
		if pos.distance_to(_reposo()) <= radio:
			_dedo = dedo
			_gesto = "resortera"
			_contacto = pos
			_armado = false
			_muestras = []
			_manito_t = -1.0
			var audio := get_node_or_null("/root/Audio")
			if audio != null and audio.esta_hablando():
				audio.desvanecer_voz(0.15)
			var lado_x := float(nivel.get("resortera", {}).get("lado_torre_x", 260))
			_bolsa_sigue = pos.x <= lado_x
			if _bolsa_sigue:
				_bolsa = pos
				_sfx("goma")
			else:
				_flechita_t = 0.6
				_sfx("boing")
			_fase = "apuntando"
			_registrar_muestra()
			_vista.queue_redraw()
			return
		_toque_decorativo(pos)
	else:
		if dedo != _dedo:
			return
		_dedo = -1
		var gesto := _gesto
		_gesto = ""
		if gesto == "maxi":
			if _fase == "apuntando":
				_disparar_guiado()
		elif gesto == "resortera":
			_soltar_resortera()


func procesar_arrastre(pos: Vector2, dedo: int = 0) -> void:
	if dedo != _dedo or _gesto != "resortera":
		return
	var res: Dictionary = nivel.get("resortera", {})
	if pos.distance_to(_contacto) >= float(res.get("arrastre_min_px", 40)):
		_armado = true
	var reposo := _reposo()
	var lado_x := float(res.get("lado_torre_x", 260))
	if not _bolsa_sigue and pos.x <= lado_x:
		_bolsa_sigue = true
	var d := pos - reposo
	if not _bolsa_sigue or d.x >= float(res.get("reves_tolerancia_px", 40)):
		_bolsa = reposo
		_flechita_t = 0.6
		if not _repetir_dicho and _bolsa_sigue:
			_repetir_dicho = true
			_voz("repetir", _perfil_turno)
	else:
		_bolsa = reposo + d.limit_length(_estiramiento_max())
	_registrar_muestra()
	_vista.queue_redraw()


func _registrar_muestra() -> void:
	var t := _ahora_ms()
	var bufer := int(nivel.get("resortera", {}).get("estabilizador", {}).get("bufer_ms", 250))
	_muestras.append({"t": t, "p": _bolsa})
	while _muestras.size() > 1 and t - int(_muestras[0]["t"]) > bufer:
		_muestras.pop_front()


## Estabilizador M2: descarta los ultimos 60 ms y toma la muestra quieta mas reciente (< 150 px/s); si no hay,
## la de justo antes de la ventana.
func bolsa_estabilizada(t_suelta: int) -> Vector2:
	var est: Dictionary = nivel.get("resortera", {}).get("estabilizador", {})
	var descarta := int(est.get("descarta_ms", 60))
	var quieto := float(est.get("quieto_px_s", 150))
	var validas: Array = []
	for m in _muestras:
		if int(m["t"]) <= t_suelta - descarta:
			validas.append(m)
	if validas.is_empty():
		# Todo el gesto cupo en la ventana descartada (tiron de < 60 ms): no hay muestra previa, manda la bolsa
		# actual (con `cancelar_tiron_sin_pausa` apagado, un tiron rapido dispara).
		return _bolsa
	for i in range(validas.size() - 1, -1, -1):
		var anterior: Dictionary = validas[i - 1] if i > 0 else {}
		var vel := 0.0
		if not anterior.is_empty():
			var dt := maxf(1.0, float(int(validas[i]["t"]) - int(anterior["t"]))) / 1000.0
			vel = (validas[i]["p"] as Vector2).distance_to(anterior["p"]) / dt
		if vel < quieto:
			return validas[i]["p"]
	return validas[-1]["p"]


func _soltar_resortera() -> void:
	var res: Dictionary = nivel.get("resortera", {})
	var bolsa := bolsa_estabilizada(_ahora_ms())
	var estir := bolsa - _reposo()
	var ok := _armado and estir.length() >= float(res.get("estiramiento_min_px", 40)) and estir.x <= 0.0
	if not ok:
		# Toque o arrastre corto: se cancela, la bolsa vuelve con rebote y no se gasta nada (B2).
		_sfx("plop")
		_bolsa = _reposo()
		_fase = "listo"
		_vista.queue_redraw()
		return
	var dir := -estir.normalized()
	var ang := clampf(rad_to_deg(atan2(-dir.y, dir.x)), float(res.get("angulo_grados", [-15, 75])[0]), float(res.get("angulo_grados", [-15, 75])[1]))
	var fuerza := float(res.get("velocidad_max_px_s", 1300)) * minf(estir.length(), _estiramiento_max()) / _estiramiento_max()
	var vel := Vector2(cos(deg_to_rad(ang)), -sin(deg_to_rad(ang))) * fuerza
	_bolsa = bolsa
	_disparo_pendiente = {"tipo": _tipo_cargado, "desde": bolsa, "vel": vel}
	_al_soltar_globo()


func _estiramiento_max() -> float:
	var m = nivel.get("resortera", {}).get("estiramiento_max_px", {})
	return float(m.get(_perfil_turno, 220)) if m is Dictionary else float(m)


func _reposo() -> Vector2:
	return _vec(nivel.get("resortera", {}).get("bolsa_reposo", [260, 430]))


func _toque_decorativo(pos: Vector2) -> void:
	# Todo responde y nada cambia el juego (§5.6).
	if _coco.get_rect().has_point(_coco.to_local(pos)) or CANASTA.has_point(pos) or RAMO.has_point(pos):
		_sfx("boing", 1.2)
		return
	for b in torre.lista_bloques():
		if b.activo() and Rect2(b.position - Vector2(b.ancho, b.alto) / 2.0, Vector2(b.ancho, b.alto)).has_point(pos):
			b.squash = 0.88
			var tw := b.create_tween()
			tw.tween_property(b, "squash", 1.0, 0.12)
			_sfx("boing" if b.material_bloque == "resorte" else "pomp", 1.1)
			return


# --- Bandeja ---

func _tipos_bandeja() -> Array:
	if not _perfil_turno in ["brote", "estrella"] or _fase not in ["listo", "apuntando"]:
		return []
	var tipos: Array = _perfil_cfg().get("proyectiles", ["normal"])
	return tipos if tipos.size() > 1 else []


func _rect_bandeja(i: int) -> Rect2:
	var r: Array = _perfil_cfg().get("bandeja", [410, 480, 224, 104])
	return Rect2(float(r[0]) + i * (LADO_BANDEJA + SEP_BANDEJA), float(r[1]), LADO_BANDEJA, LADO_BANDEJA)


func _indice_bandeja(pos: Vector2) -> int:
	var tipos := _tipos_bandeja()
	for i in tipos.size():
		if _rect_bandeja(i).has_point(pos):
			return i
	return -1


## Elegir no gasta nada (§5.5); el nombre por voz suena la 1.a vez por sesion y por tipo.
func elegir_globo(tipo: String) -> void:
	if _fase != "listo" or not tipo in _tipos_bandeja():
		return
	_tipo_cargado = tipo
	_sfx("pomp", {"normal": 1.0, "rebota": 1.3, "triple": 1.6, "pesado": 0.7}.get(tipo, 1.0))
	if not _nombre_dicho.get(tipo, false):
		_nombre_dicho[tipo] = true
		_voz("globo_nombre", tipo)
	if momento_saltable_en_curso("presenta_bandeja_nicole"):
		saltar_momento("presenta_bandeja_nicole")
	_vista.queue_redraw()


func rects_bandeja() -> Array:
	var r: Array = []
	for i in _tipos_bandeja().size():
		r.append(_rect_bandeja(i))
	return r


# ---------------------------------------------------------------------------
# Disparo y tiro
# ---------------------------------------------------------------------------

func _disparar_guiado() -> void:
	if _objetivo == null:
		_objetivo = _elegir_objetivo_semilla()
	if _objetivo == null:
		return
	_disparo_pendiente = {"tipo": "gigante" if _es_gigante else "normal", "guiado": true}
	_al_soltar_globo()


## Comun a todos los tiros, en el instante de soltar: la etapa queda "iniciada" (D2) y la foto de frontera deja
## de valer; variante A del derribo si el minimo garantizado ya alcanza (§6.6, solo E3).
func _al_soltar_globo() -> void:
	_fase = "vuelo"
	_etapa_iniciada = true
	_en_frontera = false
	_manito_t = -1.0
	_tiro_peso = 0
	_tiro_minimo = 0
	_tiro_golpe = false
	_tiro_botadas = []
	_tiro_t0 = Time.get_ticks_msec()
	ultimo_impacto = Vector2.INF
	_sfx("fiu")
	for b in torre.lista_bloques():
		b.tambaleo = 0.0
	if bool(_disparo_pendiente.get("guiado", false)) and ultima_etapa() and not _derribo_emitido and _objetivo != null:
		var minimo := int(nivel.get("proyectiles", {}).get("gigante", {}).get("agarre_min", 12)) if _es_gigante else _objetivo.peso_agarre
		if minimo >= agarre_restante():
			_derribo_emitido = true
			derribo_inminente.emit(_objetivo.global_position, true)


func _physics_process(_delta: float) -> void:
	if not _disparo_pendiente.is_empty():
		var d := _disparo_pendiente
		_disparo_pendiente = {}
		var proy: Dictionary = nivel.get("proyectiles", {})
		var tipo := str(d.get("tipo", "normal"))
		if bool(d.get("guiado", false)):
			var dur := float(proy.get("gigante", {}).get("duracion_vuelo_s", 1.6)) if tipo == "gigante" else float(_perfil_cfg("semilla").get("duracion_vuelo_s", 0.9))
			_globo_tiro = torre.lanzar_guiado(tipo, "dorado" if tipo == "gigante" else _color, proy.get(tipo, proy.get("normal", {})), _reposo(), _objetivo, dur)
			_globo_tiro.velocidad_tras_impacto = float(_perfil_cfg("semilla").get("velocidad_tras_impacto_px_s", 300))
		else:
			var datos: Dictionary = proy.get(tipo, proy.get("normal", {}))
			var pred := torre.predecir(d["desde"], d["vel"], float(datos.get("radio_px", 26)))
			ultimo_anillo = pred.get("impacto", Vector2.INF)
			_globo_tiro = torre.lanzar(tipo, _color, datos, d["desde"], d["vel"])
		_bolsa = _reposo()
		_vista.queue_redraw()
	if _fase == "apuntando" and _gesto == "resortera" and _perfil_turno in ["brote", "estrella"]:
		var estir := _bolsa - _reposo()
		if estir.length() >= 10.0 and estir.x <= 0.0:
			var dir := -estir.normalized()
			var res: Dictionary = nivel.get("resortera", {})
			var ang := clampf(rad_to_deg(atan2(-dir.y, dir.x)), -15.0, 75.0)
			var fuerza := float(res.get("velocidad_max_px_s", 1300)) * minf(estir.length(), _estiramiento_max()) / _estiramiento_max()
			var proy2: Dictionary = nivel.get("proyectiles", {}).get(_tipo_cargado, {})
			_guia = torre.predecir(_bolsa, Vector2(cos(deg_to_rad(ang)), -sin(deg_to_rad(ang))) * fuerza, float(proy2.get("radio_px", 26)))
		else:
			_guia = {}


func _process(delta: float) -> void:
	_t_vida += delta
	if _gesto == "maxi" and _fase == "apuntando":
		_t_maxi += delta
		if _t_maxi >= float(_perfil_cfg("semilla").get("semilla_mantener_s", 1.2)):
			# M5: dedo apretado 1,2 s -> el globo sale solo; lo que haga ese dedo despues no cuenta.
			_gesto = "ignorar"
			_disparar_guiado()
	if _flechita_t > 0.0:
		_flechita_t -= delta
	if _manito_t >= 0.0:
		_manito_t += delta / maxf(0.001, escala_tiempo)
		if _manito_t > 0.8:
			_manito_t = -1.0
	# Tambaleo de mentira (§6.2.2): solo cuando nadie apunta ni hay tiro.
	var mecer := _fase in ["listo", "espera"] and (turnos == null or turnos.entrada_bloqueada() or _fase == "espera")
	var max_g := float(nivel.get("tambaleo_bloques", {}).get("max_grados", 1.0))
	var i := 0
	for b in torre.lista_bloques():
		b.tambaleo = sin(_t_vida * 1.7 + i * 0.9) * max_g if mecer else 0.0
		i += 1
	if _fase in ["vuelo", "apuntando"] or _flechita_t > 0.0 or _manito_t >= 0.0:
		_vista.queue_redraw()
	if int(_t_vida * 10.0) % 3 == 0:
		_indicador.queue_redraw()


func _al_botado(b: BloqueLanzar) -> void:
	if _fase != "vuelo" or _derribo_hecho:
		return
	if b.es_trono:
		_trono_botado = true
	else:
		_tiro_peso += b.peso_agarre
		_tiro_botadas.append(b.id_bloque)
		_botadas_intento += 1
	_revisar_derribo(b.global_position)


func _al_roto(b: BloqueLanzar) -> void:
	_sfx("pop")
	var colores := {"caramelo": [Color("#FFB3D9"), Color("#FFF3B0")], "carton": [Color("#D9A066")], "lata": [Color("#8FB8DE")],
		"confeti": [Color("#E0309A")]}
	_estallido(b.global_position, colores.get(b.material_bloque, [Color.WHITE]), 14)


func _al_golpe_directo(g: GloboLanzar) -> void:
	if _fase != "vuelo" or _tiro_golpe:
		return
	if _perfil_turno in nivel.get("agarre", {}).get("golpe_directo", {}).get("perfiles", ["brote", "estrella"]):
		_tiro_golpe = true
		if torre.trono != null:
			torre.trono.agregar_mancha(g.global_position, g.color_globo)
		_revisar_derribo(g.global_position)


func _al_impacto_guiado(g: GloboLanzar, _objetivo_roto: BloqueLanzar) -> void:
	if g.tipo == "gigante":
		_tiro_minimo = int(nivel.get("proyectiles", {}).get("gigante", {}).get("agarre_min", 12))
		_voz("gigante_impacto")
		_revisar_derribo(g.global_position)


func _al_retirar_globo(g: GloboLanzar) -> void:
	_estallido(g.global_position, [COLORES_UI.get(g.color_globo, Color.WHITE)], 8)
	if g.primer_contacto_suelo:
		_crecer_charco(nivel.get("charco", {}).get("escalon_globo_al_suelo", [25, 2]), g.color_globo)


func _agarre_vivo() -> int:
	var golpe := 1 if _tiro_golpe else 0
	return _agarre_inicial - _agarre_perdido - maxi(_tiro_peso, _tiro_minimo) - golpe


func _revisar_derribo(punto: Vector2) -> void:
	if _derribo_hecho:
		return
	if _agarre_vivo() <= 0 or _trono_botado:
		_derribo(punto)


func _fin_tiro() -> void:
	if _derribo_hecho or _fase != "vuelo":
		return
	_fase = "cierre"
	torre.limpiar_globos()
	var bono := LogicaAgarre.bono_tiro(_perfil_turno, _tiro_peso, _tiro_golpe, nivel.get("perfiles", {}), nivel.get("agarre", {}))
	_agarre_perdido += maxi(_tiro_peso, _tiro_minimo) + bono
	if _perfil_turno in ["brote", "estrella"]:
		_rastros[_perfil_turno] = torre.rastro.duplicate()
	if _tiro_botadas.is_empty():
		_crecer_charco(nivel.get("charco", {}).get("escalon_tiro_neutro", [50, 4]), _color)
	if _perfil_turno == "brote":
		_ayuda_brote = 0 if not _tiro_botadas.is_empty() else _ayuda_brote + 1
	_reaccion_tiro()
	_actualizar_coleccionauta()
	if agarre_restante() <= 0:
		_derribo(coleccionauta.global_position)
		return
	await _esperar(1.0)
	if not is_inside_tree() or _derribo_hecho:
		return
	_cerrar_turno()


func _reaccion_tiro() -> void:
	if _perfil_turno == "semilla":
		_voz("maxi_acierto")
		return
	var n := _tiro_botadas.size()
	if n >= int(nivel.get("acierto_grande_piezas", 3)):
		_voz("acierto_grande")
	elif n > 0:
		var frasco := false
		for id in _tiro_botadas:
			var b := torre.bloque(str(id))
			if b != null and b.material_bloque == "caramelo":
				frasco = true
		_voz("acierto_equipo", "frasco" if frasco else "caja")
	elif ultimo_impacto != Vector2.INF and _globo_toco_torre():
		_voz("acierto_equipo", "tambalea")
	else:
		# `fallo` como maximo 1 de cada 2 veces (§8.1); nunca en el turno de Maxi.
		_fallos_seguidos += 1
		if _fallos_seguidos % 2 == 1:
			_voz("fallo_equipo")
	_reacciones += 1
	if _reacciones % 3 == 0:
		_voz_despues("rival_reacciona")


func _globo_toco_torre() -> bool:
	return ultimo_impacto.x > 780.0


func _crecer_charco(escalon: Array, color: String) -> void:
	var maximo := _vec(nivel.get("charco", {}).get("maximo", [520, 60]))
	_charco = Vector2(minf(_charco.x + float(escalon[0]), maximo.x), minf(_charco.y + float(escalon[1]), maximo.y))
	if not color in _charco_colores:
		_charco_colores.append(color)
	_charco_nodo.queue_redraw()


func charco() -> Vector2:
	return _charco


func _cerrar_turno() -> void:
	_fase = "espera"
	_perfil_turno = ""
	_aplicar_halos()
	_vista.queue_redraw()
	if turnos != null:
		if _globos_restantes <= 0:
			_derrota()
		else:
			turnos.terminar_turno(false)
	else:
		if _globos_restantes <= 0:
			# Solitario (solo pruebas): reintento inmediato con el rearmado, sin gag.
			_derrotas_etapa += 1
			_derrotas_torre += 1
			_intento_nuevo_listo = false
			_preparar_intento_nuevo()
			await _intro_corta()
		_turno_solo()


# ---------------------------------------------------------------------------
# Derrota-gag (la orquesta la base, §10.1)
# ---------------------------------------------------------------------------

func _siguiente_del_intento() -> String:
	if _semilla_id != "":
		return _semilla_id
	# nicole+sofia: empieza una distinta en cada intento (§11.1).
	var otros: Array = turnos.orden_unico() if turnos != null else []
	if otros.size() >= 2:
		_quien_empezo = otros[1] if _quien_empezo == otros[0] or _quien_empezo == "" else otros[0]
		return _quien_empezo
	return ""


func _derrota() -> void:
	_derrotas_etapa += 1
	_derrotas_torre += 1
	var intentos: Dictionary = nivel.get("intentos", {})
	_gag_actual = LogicaAgarre.variante_gag(_derrotas_torre, _ultimo_gag, intentos.get("variantes_gag", []), intentos.get("gags_por_derrota", [1, 2, 3]))
	_ultimo_gag = _gag_actual
	_intento_nuevo_listo = false
	_voz_ayuda_tras_gag()
	turnos.terminar_turno_sin_recursos(_siguiente_del_intento())


func variante_derrota() -> String:
	return _gag_actual


func ancla_rival_motor() -> Vector2:
	return coleccionauta.global_position + Vector2(0, -60)


func gag_derrota_aspirar(_destino: Vector2) -> float:
	# Provisional (CS): el gag lo cuenta la voz; el Coleccionauta baila / estornuda / se infla.
	var tw := _tween()
	tw.tween_property(coleccionauta, "balanceo", 0.25, 0.3 * escala_tiempo)
	tw.tween_property(coleccionauta, "balanceo", -0.25, 0.4 * escala_tiempo)
	tw.tween_property(coleccionauta, "balanceo", 0.0, 0.3 * escala_tiempo)
	if _gag_actual == "baile":
		coleccionauta.nivel_lunares = maxi(coleccionauta.nivel_lunares, 1)
	return 1.4 * escala_tiempo


func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	_preparar_intento_nuevo()
	_voz("rival_rearma")
	return 1.0 * escala_tiempo


func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	_preparar_intento_nuevo()


func reintentar_equipo() -> void:
	await _intro_corta()


## Logro comun de Cometa (§10.1): el tramo (1 o 2) de las piezas botadas en el intento; 0 = nos_alcanzo.
func contar_logro_equipo() -> int:
	var total := torre.lista_bloques().size()
	return LogicaAgarre.tramo_logro(_botadas_ultimo_intento, total, float(nivel.get("intentos", {}).get("logro_comun_corte", 0.5)))


var _botadas_ultimo_intento := 0

func _voz_ayuda_tras_gag() -> void:
	_botadas_ultimo_intento = _botadas_intento
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
	var intentos: Dictionary = nivel.get("intentos", {})
	if _derrotas_etapa >= int(intentos.get("pausa_desde_derrota", 3)):
		_voz("pausa_desde_intento_3")
	elif _derrotas_etapa == 2:
		_voz("ayuda_intento_2")
	else:
		_voz("ayuda_intento_1")


## El intento nuevo (§10.2 y §10.3): rearmado con el 30 % del dano, ayudas por derrotas de la etapa.
func _preparar_intento_nuevo() -> void:
	if _intento_nuevo_listo:
		return
	_intento_nuevo_listo = true
	var botadas: Array = []
	var pesos := {}
	for b in torre.lista_bloques():
		pesos[b.id_bloque] = b.peso_agarre
		if b.botado:
			botadas.append(b.id_bloque)
	var intentos: Dictionary = nivel.get("intentos", {})
	var conservado := LogicaAgarre.agarre_conservado(_agarre_perdido, float(intentos.get("conservar_dano", 0.3)), not botadas.is_empty(),
		int(intentos.get("conservar_minimo_si_hubo_botadas", 1)))
	var suben := LogicaAgarre.elegir_rearmado(botadas, pesos, _etapa.get("torre", {}).get("orden_reparacion", []), conservado)
	for id in botadas:
		var b := torre.bloque(str(id))
		if id in suben:
			b.rearmar()
		elif b.estado == "en_pie":
			b.pasar_a_suelo()
	_agarre_perdido = conservado
	_intento += 1
	_botadas_intento = 0
	_canasta_llena = LogicaAgarre.canasta_del_intento(_base, _extra_1, _derrotas_etapa, _extra_2 if _semilla_id == "" else 0)
	_globos_restantes = _canasta_llena
	_globo_k = 0
	_gigante_pendiente = LogicaAgarre.gigante_en_intento(_derrotas_etapa, _semilla_id != "")
	_gigante_usado = false
	_trono_botado = false
	_actualizar_coleccionauta()
	_vista.queue_redraw()


# ---------------------------------------------------------------------------
# Derribo, etapas y victoria
# ---------------------------------------------------------------------------

func _derribo(punto: Vector2) -> void:
	if _derribo_hecho:
		return
	_derribo_hecho = true
	torre.congelar_todo()
	if turnos != null:
		turnos.detener()
	_fase = "derribo"
	_dedo = -1
	_gesto = ""
	_estado_derribo = {"bloques": torre.poses(), "inclinacion_trono": torre.trono.rotation if torre.trono != null else 0.0,
		"charco": {"ancho": _charco.x, "alto": _charco.y}, "punto_impacto": punto}
	if ultima_etapa():
		_victoria(punto)
	else:
		_fin_etapa()


func _fin_etapa() -> void:
	_etapas_ganadas.append(str(_etapa.get("id", "e%d" % etapa_actual())))
	# D1 (§25.18.1): en este mismo cuadro, con la fisica congelada y antes de `caida_etapa`, el parcial ya es el
	# estado inicial de la etapa siguiente. Salir en la caida o la transicion vuelve a la etapa siguiente.
	if not revancha:
		_foto_frontera = _estado_inicial_etapa(_idx + 1)
		_en_frontera = true
		notificar_parcial_equipo()
	_fase = "caida"
	torre.limpiar_globos()
	await _momento("caida_etapa", _dur("caida_corta_s", 5.5), func() -> void:
		_animar_caida(false)
		var lineas := _lista_voz("caida_etapa")
		if _idx < lineas.size():
			_voz_ruta("caida_etapa", str(lineas[_idx])))
	if not is_inside_tree():
		return
	_indicador.queue_redraw()
	_sfx("tilin")
	await _transicion()
	if not is_inside_tree():
		return
	await _empezar_etapa_nueva()


## Transicion <= 4 s, no se salta (§25.3 punto 3; storyboard §25.4). Sin pausa ni "¿seguimos?" (PO, 05-Nov).
func _transicion() -> void:
	_fase = "transicion"
	var siguiente := _idx + 1
	var llegada := str(_etapas[siguiente].get("voz_llegada", ""))
	if llegada != "" and llegada != "<null>":
		_voz("etapa_llegada", llegada)
	_sfx("plop")
	var tw := _tween()
	tw.tween_property(coleccionauta, "position:x", 1360.0, 0.6 * escala_tiempo)
	await _esperar(0.6)
	if not is_inside_tree():
		return
	_armar_etapa(siguiente)
	_fase = "transicion"
	coleccionauta.position.x = 1360.0
	_animar_armado(2.0)
	await _esperar(2.6)
	if not is_inside_tree():
		return
	_fijar_poses_armado()
	_fase = "espera"
	_ubicar_coleccionauta()


func _empezar_etapa_nueva() -> void:
	_fase = "espera"
	_derribo_hecho = false
	# El guardado "al empezar la etapa" (§25.3 punto 4): identico al del derribo (sigue la foto de frontera).
	notificar_parcial_equipo()
	# D3 (§25.18.3): sin intro corta al empezar E2 y E3; la llegada ya la reemplazo.
	await _presentar_especial()
	if not is_inside_tree():
		return
	if turnos != null:
		turnos.reiniciar_rival(_siguiente_del_intento())
	else:
		_turno_solo()


func _victoria(punto: Vector2) -> void:
	var minimo := _vec(nivel.get("charco", {}).get("minimo_al_derribo", [360, 44]))
	_charco = Vector2(maxf(_charco.x, minimo.x), maxf(_charco.y, minimo.y))
	_charco_nodo.queue_redraw()
	_etapas_ganadas.append(str(_etapa.get("id", "e3")))
	if not _derribo_emitido:
		_derribo_emitido = true
		derribo_inminente.emit(punto, false)
	# Anticipacion (§9.2): nunca se salta ni se marca vista. Provisional: la torre se inclina 11°.
	_fase = "anticipacion"
	_voz("anticipacion")
	var tw := _tween()
	tw.tween_method(_inclinar, 0.0, 11.0, maxf(0.01, _dur("anticipacion_s", 4.3) * escala_tiempo))
	await _esperar(_dur("anticipacion_s", 4.3))
	if not is_inside_tree():
		return
	_fase = "caida"
	torre.limpiar_globos()
	var encolado := _saltar_caida_encolado
	await _momento("caida_torre", _dur("caida_torre_s", 10.5), func() -> void:
		_animar_caida(true)
		_voces_en_cadena(_lista_voz("caida"))
		if encolado:
			saltar_momento.call_deferred("caida_torre"))
	if not is_inside_tree():
		return
	if revancha:
		var resultado := resultado_revancha_calculado()
		resultado_revancha.emit(int(resultado["estrellitas"]), int(resultado["record"]))
		if turnos != null and turnos.barra != null:
			for id in equipo:
				turnos.barra.gesto(id)
		_estallido(Vector2(640, 300), [COLORES_UI["amarillo"]], 30)
		await _esperar(1.5)
		emitir_completado(0)
	elif en_batalla:
		emitir_completado(0)
	elif es_modo_equipo():
		celebrar_equipo(0)
	else:
		celebrar(0)


## Revancha solo E3 (decision del PO por delegacion, 05-Nov-2026): estrellitas y record de una sola torre (§11
## v3). Solo con los tres; con dos, (0, -1) y batalla.gd no escribe nada (§11.1).
func resultado_revancha_calculado() -> Dictionary:
	var solo_con := str(nivel.get("revancha", {}).get("estrellitas_y_record_solo_con", "maxi+nicole+sofia"))
	if not es_modo_equipo() or _clave != solo_con:
		return {"estrellitas": 0, "record": -1}
	var sobrantes := _globos_restantes
	var estrellitas := 1
	if _derrotas_etapa == 0:
		estrellitas = 3 if sobrantes >= int(nivel.get("revancha", {}).get("sobrantes_tres", 1)) else 2
	var record := (_canasta_llena - _globos_restantes) if _derrotas_etapa == 0 else -1
	return {"estrellitas": estrellitas, "record": record}


# ---------------------------------------------------------------------------
# Parcial (§12 y §25.18)
# ---------------------------------------------------------------------------

func obtener_parcial_equipo() -> Dictionary:
	if revancha:
		return {}   # Revancha solo E3: sin parcial (salir no cuesta nada ni cuenta).
	if _en_frontera:
		return _foto_frontera.duplicate(true)
	var rastros := {}
	for p in _rastros:
		var lista: Array = []
		for v in (_rastros[p] as PackedVector2Array):
			lista.append([snappedf(v.x, 0.1), snappedf(v.y, 0.1)])
		rastros[p] = lista
	return {
		"etapa": etapa_actual(), "etapas_ganadas": _etapas_ganadas.duplicate(), "etapa_iniciada": _etapa_iniciada,
		"intento": _intento, "derrotas_etapa": _derrotas_etapa, "derrotas": _derrotas_torre, "ultimo_gag": _ultimo_gag,
		"globos_restantes": _globos_restantes, "gigante_usado": _gigante_usado, "agarre_perdido": _agarre_perdido,
		"bloques": torre.estado_bloques(), "manchas": [],
		"charco": {"ancho": _charco.x, "alto": _charco.y, "colores": _charco_colores.duplicate()},
		"rastros": rastros, "ayuda_brote_turnos_sin_derribo": _ayuda_brote, "presentacion_vista": _presentacion_vista,
	}


func restaurar_parcial_equipo(estado: Dictionary) -> void:
	if estado.is_empty() or revancha:
		return
	_restaurado = true
	_estado_rest = estado.duplicate(true)
	_etapas_ganadas = (estado.get("etapas_ganadas", []) as Array).duplicate()
	_derrotas_torre = int(estado.get("derrotas", 0))
	_ultimo_gag = str(estado.get("ultimo_gag", ""))
	_presentacion_vista = bool(estado.get("presentacion_vista", true))
	_armar_etapa(int(estado.get("etapa", 1)) - 1)
	# D2: sin el campo (guardado previo a la v4.1) = caso A, el seguro.
	_etapa_iniciada = bool(estado.get("etapa_iniciada", true))
	if not _etapa_iniciada:
		return
	_intento = int(estado.get("intento", 1))
	_derrotas_etapa = int(estado.get("derrotas_etapa", maxi(0, _intento - 1)))
	_agarre_perdido = int(estado.get("agarre_perdido", 0))
	torre.aplicar_estado_bloques(estado.get("bloques", {}))
	var ch = estado.get("charco", null)
	if ch is Dictionary:
		_charco = Vector2(float(ch.get("ancho", 120)), float(ch.get("alto", 24)))
		_charco_colores = (ch.get("colores", []) as Array).duplicate()
	for p in estado.get("rastros", {}):
		var lista := PackedVector2Array()
		for v in estado["rastros"][p]:
			lista.append(Vector2(float(v[0]), float(v[1])))
		_rastros[p] = lista
	_ayuda_brote = int(estado.get("ayuda_brote_turnos_sin_derribo", 0))
	_canasta_llena = LogicaAgarre.canasta_del_intento(_base, _extra_1, _derrotas_etapa, _extra_2 if _semilla_id == "" else 0)
	var guardados := int(estado.get("globos_restantes", _canasta_llena))
	var intentos: Dictionary = nivel.get("intentos", {})
	_globos_restantes = LogicaAgarre.globos_al_retomar(guardados, int(intentos.get("globos_minimos_al_retomar", 5)), _canasta_llena, _semilla_id != "")
	_globos_agregados = _globos_restantes > guardados
	_gigante_usado = bool(estado.get("gigante_usado", false))
	# Al retomar empieza Maxi: si el gigante de este intento no salio, es su globo (§12).
	_gigante_pendiente = LogicaAgarre.gigante_en_intento(_derrotas_etapa, _semilla_id != "") and not _gigante_usado
	_actualizar_coleccionauta()
	_charco_nodo.queue_redraw()
	_vista.queue_redraw()


# ---------------------------------------------------------------------------
# Gancho de arnes: un tiro con resultado fijo, sin fisica (flujo de etapas, derrotas y parcial)
# ---------------------------------------------------------------------------

## Solo arneses: consume el turno como un tiro real (suelta, etapa iniciada, foto de frontera vencida) y bota
## `ids` (rotura), con golpe directo opcional. Despues cierra el tiro por el camino normal.
func qa_tiro_simulado(ids: Array, golpe: bool = false) -> bool:
	if not _turno_jugable() or _fase != "listo":
		return false
	_disparo_pendiente = {}
	_al_soltar_globo()
	for id in ids:
		var b := torre.bloque(str(id))
		if b != null:
			torre.romper(b)
	if golpe and not _derribo_hecho:
		_tiro_golpe = true
		_revisar_derribo(Vector2(990, 200))
	if not _derribo_hecho:
		_fin_tiro()
	return true


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _dur(clave: String, defecto: float) -> float:
	return float(nivel.get("transicion_etapa", {}).get(clave, defecto))


func _vec(a) -> Vector2:
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO


func _esperar(segundos: float) -> void:
	var s := segundos * escala_tiempo
	if s <= 0.0:
		return
	await get_tree().create_timer(s).timeout


func _lista_voz(clave: String) -> Array:
	var v = nivel.get("lineas_voz", {}).get(clave, [])
	return v if v is Array else ([v] if str(v) != "" else [])


## Voz por clave (y sub-clave si es un mapa). Arreglo = variantes con la semilla del nivel. "PENDIENTE" o un
## archivo que no existe = sin voz y sin error (HE-86 trae las voces).
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
	var final := resolver_ruta_audio(ruta)
	if ResourceLoader.exists(final):
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


func _sfx(nombre: String, tono: float = 1.0) -> void:
	var ruta: String = SFX.get(nombre, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		reproducir_sfx(ruta, tono)
