class_name MotorLienzoLibre
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "lienzo_libre" — "Pinta con Coco" del Planeta Arcoiris
## (docs/fichas/motor-lienzo-libre.md, planeta-arcoiris.md §3 y planeta-arcoiris-zonas.md §3.4).
##
## Juego de expresion SIN FALLO para nadie: el destello se gana al tocar "mostrar a Coco" (boton
## grande con la cara de Coco, sin texto). Coco imita en vivo los colores usados en su cresta.
## Agnostico de tema: todo llega en el nivel JSON. El campo `encargo` elige la idea de Coco:
##
## - `libre`: papel en blanco (zona 1).
## - `sellos_escena`: estampar dinos, autos y estrellas sobre una escena (Maxi).
## - `colorear_zonas`: tocar una parte de la lamina la rellena (Nicole), con tarjeta modelo.
## - `colorear_codigo`: mosaico de numeros -> colores que revela una bandera o un lugar (Sofia).
## - `pinta_coco`: cada toque rellena una parte grande de Coco, que se tine en vivo (Maxi).
## - `coco_pide`: Coco pide colores por voz; cualquier resultado se celebra (Nicole).
## - `mezcla_paleta`: solo primarios y blanco; los demas colores se mezclan en el platito (Sofia).
## - `dedo_magico`: el trazo deja un arcoiris que suena (Maxi).
## - `espejo`: lo pintado en un lado aparece en el otro (Nicole).
## - `mandala`: simetria de 6 ejes (Sofia).
## - `decora_ala`: pintar el ala de la nave; queda guardada para el hangar (los tres).
## - `viste_coco`: elegir y pintar el traje de Coco (Nicole).
##
## Un nivel puede traer varias HOJAS seguidas (laminas de un pool barajado, `laminas_por_partida`)
## y varias ETAPAS (`etapas`: p. ej. decorar el ala y despues vestir a Coco). Cada hoja se muestra
## a Coco, se guarda como PNG en user://dibujos/<hermano>/ y pasa a la siguiente; la ultima dispara
## la celebracion comun y `completado(destellos)`.
##
## F3 (solo PC) muestra un panel de depuracion para el PO.

signal hoja_mostrada(indice: int, ruta_png: String)
signal pedido_cumplido(id_color: String)

const Lienzo := preload("res://scripts/motores/lienzo_libre/lienzo.gd")
const Colores := preload("res://scripts/motores/lienzo_libre/colores_lienzo.gd")
const Laminas := preload("res://scripts/motores/lienzo_libre/laminas.gd")
const Sellos := preload("res://scripts/motores/lienzo_libre/sellos.gd")
const Cresta := preload("res://scripts/motores/lienzo_libre/cresta_coco.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")

## Pantalla base 1280x720: a la izquierda salir, tarjeta modelo, "mostrar a Coco" y Coco; al centro
## el lienzo; abajo las herramientas; a la derecha la paleta y Cometa.
const RECT_LIENZO := Rect2(232, 80, 824, 530)
const RECT_PALETA := Rect2(1066, 84, 206, 490)
const RECT_HERRAMIENTAS := Rect2(232, 618, 824, 98)
const RECT_MODELO := Rect2(14, 122, 206, 132)
const RECT_MOSTRAR := Rect2(46, 262, 142, 142)
const CARPETA_DIBUJOS := "user://dibujos"
const DESTELLOS_POR_HOJA := 20
const MAX_DESTELLOS_COLORES := 10
const SEGUNDOS_ENTRE_REACCIONES := 2.6
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_ELEGIR := "sfx/ui/seleccionar.ogg"
const SFX_SELLO := "sfx/ui/soltar.ogg"
const SFX_RELLENO := "sfx/ui/confirmar.ogg"
const SFX_MOSTRAR := "sfx/ui/abrir.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const PALETA_SEMILLA := ["rojo", "azul", "amarillo", "verde", "rosa", "violeta"]
const PALETA_COMPLETA := ["rojo", "naranja", "amarillo", "verde", "azul", "violeta", "rosa", "turquesa", "blanco", "negro", "cafe", "celeste"]
const PRIMARIOS := ["rojo", "amarillo", "azul", "blanco"]
## Escala pentatonica (Do mayor) del dedo magico: cualquier trazo suena bonito.
const NOTAS_HZ := [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0]

@onready var _ui: Control = %ui
@onready var _anfitriona: TextureRect = %anfitriona
@onready var _efectos: Control = %efectos
@onready var _confeti: CPUParticles2D = %confeti
@onready var _boton_cometa: Button = %boton_cometa
@onready var _boton_salir: Button = %boton_salir
@onready var _panel_depuracion: Label = %panel_depuracion

var lienzo: Lienzo
var boton_mostrar: Button
## Rutas de los PNG guardados en esta partida (para QA y para el hangar).
var pngs_guardados: Array[String] = []

var _hojas: Array = []
var _indice_hoja := -1
var _cfg: Dictionary = {}
var _encargo := "libre"
var _perfil := "semilla"
var _mostrando := false
var _terminado := false

var _paleta: Control
var _herramientas: Control
var _modelo: Control
var _puntos_hojas: Control
var _burbuja: Control
var _platito: Control
var _cresta: Cresta
var _botones_color: Array = []  ## [{"boton": Button, "color": Color, "id": String, "numero": String}]
var _botones_herramienta: Array = []  ## [{"boton": Button, "id": String}]
var _fuente: Font

var _colores_usados: Array = []  ## colores distintos de la partida (para la cresta y destellos)
var _colores_hoja := {}
var _recientes: Array = []  ## [[ms, Color]] para el momento arcoiris
var _ms_ultimo_arcoiris := -100000
var _ms_ultima_reaccion := -100000
var _usados_especiales := {}
var _dinos_seguidos := 0
var _paseos_dino := 0
var _lamina_nombrada := false

var _pedidos: Array = []
var _pedido_actual := -1
var _fallos_pedido := 0
var _gotas := {}
var _mezclas_dichas := {}
var _mis_colores: Array = []
var _traje := ""

var _segundos_mostrar := 0.0
var _tiempo_hoja := 0.0
var _hubo_toque := false
var _tiempo := 0.0
var _base_anfitriona := Vector2.ZERO
var _salto_anfitriona := 0.0
var _tween_anfitriona: Tween
var _tween_mostrar: Tween
var _voz_diferida_id := 0
var _ultima_linea := ""
var _notas: Array[AudioStreamPlayer] = []
var _sonidos_nota: Array = []
var _indice_nota := 0
var _ms_sfx := {}


func _ready() -> void:
	super._ready()
	randomize()
	_panel_depuracion.hide()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_construir_interfaz()
	_boton_cometa.pressed.connect(_al_tocar_cometa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_anfitriona.mouse_filter = Control.MOUSE_FILTER_STOP
	_anfitriona.gui_input.connect(_al_tocar_anfitriona)
	_anfitriona.pivot_offset = Vector2(_anfitriona.size.x / 2.0, _anfitriona.size.y)
	_base_anfitriona = _anfitriona.position
	if nivel.is_empty():
		push_error("motor_lienzo_libre: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_perfil = obtener_perfil_dificultad()
	_armar_hojas()
	_empezar_hoja(0)


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	var bamboleo := absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0
	_anfitriona.position.y = _base_anfitriona.y - _salto_anfitriona - bamboleo
	if _terminado or _mostrando or _indice_hoja < 0:
		return
	_tiempo_hoja += delta
	if not boton_mostrar.visible and _segundos_mostrar > 0.0 and _hubo_toque and _tiempo_hoja >= _segundos_mostrar:
		_revelar_boton_mostrar(true)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Hojas y etapas
# ---------------------------------------------------------------------------

## Arma la lista de hojas de la partida: cada etapa aporta 1 o varias laminas de su pool.
func _armar_hojas() -> void:
	_hojas.clear()
	var etapas: Array = nivel.get("etapas", [])
	if etapas.is_empty():
		etapas = [{}]
	for i in etapas.size():
		var cfg := _config_de_etapa(etapas[i])
		var elegidas := _elegir_laminas(cfg)
		for j in elegidas.size():
			_hojas.append({"cfg": cfg, "lamina": elegidas[j], "etapa": i, "primera_de_etapa": j == 0})


func _config_de_etapa(etapa: Dictionary) -> Dictionary:
	var cfg := nivel.duplicate(true)
	cfg.erase("etapas")
	for clave in etapa:
		if clave == "lineas_voz":
			var voces: Dictionary = nivel.get("lineas_voz", {}).duplicate()
			voces.merge(etapa["lineas_voz"], true)
			cfg["lineas_voz"] = voces
		else:
			cfg[clave] = etapa[clave]
	return cfg


## Elige las laminas de la etapa: baraja el pool (salvo `primera_fija`), toma `laminas_por_partida`
## y, si se pide `al_menos_una`, asegura una con esa etiqueta (p. ej. "chile").
func _elegir_laminas(cfg: Dictionary) -> Array:
	var pool: Array = cfg.get("laminas", []).duplicate()
	if pool.is_empty():
		return [{}]
	var fija: Array = []
	if bool(cfg.get("primera_fija", false)):
		fija.append(pool.pop_front())
	pool.shuffle()
	var cuantas := int(cfg.get("laminas_por_partida", 1)) - fija.size()
	var elegidas: Array = pool.slice(0, maxi(0, cuantas))
	var etiqueta := str(cfg.get("al_menos_una", ""))
	if etiqueta != "" and not elegidas.is_empty():
		var tiene := false
		for lamina: Dictionary in elegidas:
			if (lamina.get("etiquetas", []) as Array).has(etiqueta):
				tiene = true
		if not tiene:
			for lamina: Dictionary in pool:
				if (lamina.get("etiquetas", []) as Array).has(etiqueta):
					elegidas[randi() % elegidas.size()] = lamina
					break
	return fija + elegidas


func _empezar_hoja(indice: int) -> void:
	_indice_hoja = indice
	var hoja: Dictionary = _hojas[indice]
	_cfg = hoja["cfg"]
	_encargo = str(_cfg.get("encargo", "libre"))
	_tiempo_hoja = 0.0
	_hubo_toque = false
	_mostrando = false
	_lamina_nombrada = false
	_colores_hoja.clear()
	_dinos_seguidos = 0
	_voz_diferida_id += 1
	_anfitriona.modulate = Color.WHITE

	lienzo.limpiar()
	lienzo.bloqueado = false
	lienzo.papel = Color(str(_cfg.get("papel", "#FFF8EE")))
	lienzo.radio_pincel = float(_cfg.get("radio_pincel", {"semilla": 26.0, "brote": 16.0, "estrella": 11.0}.get(_perfil, 16.0)))
	lienzo.lado_sello = int(_cfg.get("lado_sello", {"semilla": 124, "brote": 88, "estrella": 72}.get(_perfil, 88)))
	lienzo.sellos_vivos = bool(_cfg.get("sellos_vivos", _perfil == "semilla"))
	lienzo.rellenar_con_toque = bool(_cfg.get("rellenar_con_toque", false))
	var lamina: Dictionary = hoja["lamina"]
	match str(lamina.get("tipo", "zonas")):
		"mosaico":
			if not lamina.is_empty():
				lienzo.poner_mosaico(lamina)
		"guia":
			lienzo.poner_guia(lamina)
		_:
			if not lamina.is_empty():
				lienzo.poner_lamina(lamina)
	lienzo.poner_simetria(str(_cfg.get("simetria", "")))
	_traje = ""
	if lamina.has("trajes"):
		_elegir_traje(str((lamina.get("orden_trajes", lamina["trajes"].keys()) as Array)[0]), true)

	_construir_paleta()
	_construir_herramientas()
	_construir_modelo(lamina)
	_construir_puntos_hojas()
	_preparar_pedidos()
	_preparar_mezcla()

	_segundos_mostrar = float(_cfg.get("segundos_mostrar", 0.0))
	boton_mostrar.visible = _segundos_mostrar <= 0.0
	boton_mostrar.scale = Vector2.ONE
	if _tween_mostrar != null and _tween_mostrar.is_valid():
		_tween_mostrar.kill()

	var intro := _linea("intro") if hoja["primera_de_etapa"] else _linea_al_azar("siguiente")
	_reproducir_voz("intro", intro)
	if _pedido_actual >= 0:
		_voz_diferida("pedido", _ruta_pedido(), _duracion_voz(intro) + 0.5)
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------------

func _construir_interfaz() -> void:
	_estilizar_boton(_boton_salir, Color("#FFF8EE"))
	_estilizar_boton(_boton_cometa, Color("#CFF5F1"))
	var flecha := _icono(_boton_salir, _dibujar_flecha)
	flecha.queue_redraw()

	lienzo = Lienzo.new()
	var marco := Panel.new()
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.0)
	estilo.border_color = COLOR_CONTORNO
	estilo.set_border_width_all(6)
	estilo.set_corner_radius_all(18)
	estilo.shadow_color = Color(COLOR_CONTORNO, 0.35)
	estilo.shadow_size = 8
	estilo.shadow_offset = Vector2(0, 6)
	marco.add_theme_stylebox_override("panel", estilo)
	_ui.add_child(lienzo)
	_ui.move_child(lienzo, 0)
	lienzo.position = RECT_LIENZO.position
	_ui.add_child(marco)
	_ui.move_child(marco, 1)
	marco.position = RECT_LIENZO.position - Vector2(6, 6)
	marco.size = RECT_LIENZO.size + Vector2(12, 12)
	lienzo.pivot_offset = RECT_LIENZO.size / 2.0
	lienzo.toque_iniciado.connect(_al_tocar_lienzo)
	lienzo.color_usado.connect(_al_usar_color)
	lienzo.sello_puesto.connect(_al_poner_sello)
	lienzo.region_rellenada.connect(_al_rellenar_region)
	lienzo.celda_pintada.connect(func(_c: bool) -> void: _sfx_suave(SFX_TOQUE))
	lienzo.lamina_completa.connect(_al_completar_lamina)
	lienzo.nota.connect(_tocar_nota)
	lienzo.purpurina_quieta.connect(_lluvia_dorada)
	lienzo.color_ciclado.connect(_al_ciclar_color)

	_paleta = Control.new()
	_paleta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_paleta)
	_paleta.position = RECT_PALETA.position
	_paleta.size = RECT_PALETA.size
	_herramientas = Control.new()
	_herramientas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_herramientas)
	_herramientas.position = RECT_HERRAMIENTAS.position
	_herramientas.size = RECT_HERRAMIENTAS.size

	_modelo = Control.new()
	_modelo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_modelo)
	_modelo.position = RECT_MODELO.position
	_modelo.size = RECT_MODELO.size

	_puntos_hojas = Control.new()
	_puntos_hojas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_puntos_hojas)
	_puntos_hojas.position = Vector2(RECT_LIENZO.position.x, 14)
	_puntos_hojas.size = Vector2(RECT_LIENZO.size.x, 56)
	_puntos_hojas.draw.connect(_dibujar_puntos_hojas)

	_burbuja = Control.new()
	_burbuja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_burbuja)
	_burbuja.position = Vector2(RECT_LIENZO.end.x - 150, 8)
	_burbuja.size = Vector2(140, 66)
	_burbuja.draw.connect(_dibujar_burbuja)
	_burbuja.hide()

	boton_mostrar = Button.new()
	boton_mostrar.focus_mode = Control.FOCUS_NONE
	boton_mostrar.tooltip_text = "Mostrar el dibujo a Coco"
	boton_mostrar.custom_minimum_size = RECT_MOSTRAR.size
	_ui.add_child(boton_mostrar)
	boton_mostrar.position = RECT_MOSTRAR.position
	boton_mostrar.size = RECT_MOSTRAR.size
	boton_mostrar.pivot_offset = RECT_MOSTRAR.size / 2.0
	_estilizar_boton(boton_mostrar, Color("#FFE3F1"))
	var cara := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = _anfitriona.texture
	atlas.region = Rect2(38, 20, 218, 218)
	cara.texture = atlas
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton_mostrar.add_child(cara)
	cara.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cara.offset_left = 10
	cara.offset_top = 6
	cara.offset_right = -10
	cara.offset_bottom = -14
	_icono(boton_mostrar, _dibujar_marquito)
	boton_mostrar.pressed.connect(mostrar_a_coco)

	_cresta = Cresta.new()
	_anfitriona.add_child(_cresta)
	_cresta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cresta.preparar(_anfitriona.texture)

	_platito = Control.new()
	_platito.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_platito)
	_platito.position = RECT_PALETA.position
	_platito.size = RECT_PALETA.size

	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	degradado.colors = PackedColorArray(Figura.COLORES_ARCOIRIS)
	_confeti.color_initial_ramp = degradado

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(COLOR_CONTORNO, 0.85)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(12)
	_panel_depuracion.add_theme_stylebox_override("normal", panel)
	_panel_depuracion.add_theme_color_override("font_color", Color("#FFF8EE"))
	_preparar_notas()
	_ui.move_child(_efectos, -1)
	_ui.move_child(_panel_depuracion, -1)


func _icono(padre: Control, dibujo: Callable) -> Control:
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(dibujo.bind(icono))
	return icono


func _vaciar(contenedor: Control) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


## Paleta segun la hoja: leyenda numerada (mosaico), primarios con platito (mezcla) o colores.
func _construir_paleta() -> void:
	_vaciar(_paleta)
	_botones_color.clear()
	var entradas: Array = []  # [id, Color, numero]
	if not lienzo.mosaico.is_empty():
		var colores: Dictionary = lienzo.mosaico.get("colores", {})
		var claves := colores.keys()
		claves.sort()
		for clave in claves:
			entradas.append(["", Color(str(colores[clave])), str(clave)])
	elif _encargo == "mezcla_paleta":
		for id in _cfg.get("paleta", PRIMARIOS):
			entradas.append([str(id), Colores.color(str(id)), ""])
	else:
		for id in _cfg.get("paleta", PALETA_SEMILLA if _perfil == "semilla" else PALETA_COMPLETA):
			entradas.append([str(id), Colores.color(str(id)), ""])

	var columnas := 1 if not lienzo.mosaico.is_empty() else 2
	var ancho := RECT_PALETA.size.x if columnas == 1 else (RECT_PALETA.size.x - 8.0) / 2.0
	var alto := 0.0
	if _perfil == "semilla" and lienzo.mosaico.is_empty():
		alto = 100.0
	elif _encargo == "mezcla_paleta":
		alto = 78.0
	else:
		var filas := ceili(entradas.size() / float(columnas))
		alto = clampf((RECT_PALETA.size.y - (filas - 1) * 8.0) / maxf(1, filas), 64.0, 96.0)
	for i in entradas.size():
		var fila := i / columnas
		var col := i % columnas
		var rect := Rect2(col * (ancho + 8.0), fila * (alto + 8.0), ancho, alto)
		var boton := _boton_color(entradas[i][1], str(entradas[i][2]), rect)
		var entrada := {"boton": boton, "color": entradas[i][1], "id": entradas[i][0], "numero": entradas[i][2]}
		_botones_color.append(entrada)
		boton.pressed.connect(_al_elegir_color.bind(entrada))
	if not _botones_color.is_empty() and _encargo != "mezcla_paleta":
		var inicial := str(_cfg.get("color_inicial", ""))
		var elegido: Dictionary = _botones_color[0]
		for entrada: Dictionary in _botones_color:
			if entrada["id"] == inicial:
				elegido = entrada
		_seleccionar_color(elegido, false)
	lienzo.colores_ciclo = []
	if _perfil == "semilla":
		for entrada: Dictionary in _botones_color:
			lienzo.colores_ciclo.append(entrada["color"])


func _boton_color(color: Color, numero: String, rect: Rect2) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.flat = true
	boton.custom_minimum_size = Vector2(64, 64)
	boton.tooltip_text = "Color %s" % numero if numero != "" else "Color"
	_paleta.add_child(boton)
	boton.position = rect.position
	boton.size = rect.size
	boton.set_meta("color", color)
	boton.set_meta("numero", numero)
	boton.set_meta("elegido", false)
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		boton.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	var dibujo := _icono(boton, _dibujar_mancha)
	boton.set_meta("dibujo", dibujo)
	boton.button_down.connect(_rebote.bind(boton))
	return boton


func _al_elegir_color(entrada: Dictionary) -> void:
	_sfx_suave(SFX_ELEGIR)
	if _encargo == "mezcla_paleta":
		_agregar_gota(str(entrada["id"]))
		return
	_seleccionar_color(entrada, true)


func _seleccionar_color(entrada: Dictionary, con_reaccion: bool) -> void:
	lienzo.color_actual = entrada["color"]
	for otra: Dictionary in _botones_color:
		var boton: Button = otra["boton"]
		boton.set_meta("elegido", otra == entrada)
		(boton.get_meta("dibujo") as Control).queue_redraw()
	_refrescar_iconos()
	if con_reaccion and _perfil == "semilla":
		# Maxi: el color elegido se nombra al instante (causa-efecto, sin esperar a pintar).
		_reaccion_color(entrada["color"], true)


func _al_ciclar_color(color: Color) -> void:
	for entrada: Dictionary in _botones_color:
		if (entrada["color"] as Color).is_equal_approx(color):
			_seleccionar_color(entrada, false)
			return


func _refrescar_iconos() -> void:
	for entrada: Dictionary in _botones_herramienta:
		var boton: Button = entrada["boton"]
		(boton.get_meta("dibujo") as Control).queue_redraw()


## Barra de herramientas: pinceles, goma, balde, sellos... (o los trajes de Coco).
func _construir_herramientas() -> void:
	_vaciar(_herramientas)
	_botones_herramienta.clear()
	var lista: Array = _cfg.get("herramientas", _herramientas_por_defecto())
	var trajes: Array = []
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	if lamina.has("trajes"):
		trajes = lamina.get("orden_trajes", lamina["trajes"].keys())
	var total := lista.size() + trajes.size()
	if total == 0:
		lienzo.herramienta = "pincel"
		return
	var lado := 96.0 if _perfil == "semilla" else 90.0
	var separacion := 14.0
	var ancho_total := total * lado + (total - 1) * separacion
	var x := (RECT_HERRAMIENTAS.size.x - ancho_total) / 2.0
	for id in trajes:
		var boton := _boton_herramienta("traje_" + str(id), Rect2(x, (RECT_HERRAMIENTAS.size.y - lado) / 2.0, lado, lado))
		boton.pressed.connect(_elegir_traje.bind(str(id), false))
		x += lado + separacion
	for id in lista:
		var boton := _boton_herramienta(str(id), Rect2(x, (RECT_HERRAMIENTAS.size.y - lado) / 2.0, lado, lado))
		boton.pressed.connect(_elegir_herramienta.bind(str(id)))
		x += lado + separacion
	var inicial := str(_cfg.get("herramienta_inicial", lista[0] if not lista.is_empty() else "pincel"))
	_elegir_herramienta(inicial, false)


func _herramientas_por_defecto() -> Array:
	match _perfil:
		"semilla":
			return ["pincel", "sello_dino", "sello_auto"]
		"brote":
			return ["pincel", "pincel_corazon", "pincel_estrella", "goma"]
	return ["pincel", "pincel_grueso", "pincel_estrella", "purpurina", "goma"]


func _boton_herramienta(id: String, rect: Rect2) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.tooltip_text = id
	boton.custom_minimum_size = Vector2(64, 64)
	_herramientas.add_child(boton)
	boton.position = rect.position
	boton.size = rect.size
	boton.pivot_offset = rect.size / 2.0
	boton.set_meta("id", id)
	boton.set_meta("elegido", false)
	_estilizar_boton(boton, Color("#FFF8EE"))
	var dibujo := _icono(boton, _dibujar_herramienta)
	boton.set_meta("dibujo", dibujo)
	_botones_herramienta.append({"boton": boton, "id": id})
	return boton


func _elegir_herramienta(id: String, con_sonido := true) -> void:
	if con_sonido:
		_sfx_suave(SFX_ELEGIR)
	lienzo.herramienta = id
	for entrada: Dictionary in _botones_herramienta:
		var boton: Button = entrada["boton"]
		var elegido: bool = entrada["id"] == id or entrada["id"] == "traje_" + _traje
		boton.set_meta("elegido", elegido)
		_estilizar_boton(boton, Color("#FFE38A") if entrada["id"] == id else (Color("#CFF5F1") if elegido else Color("#FFF8EE")), false)
		(boton.get_meta("dibujo") as Control).queue_redraw()
	if id != "sello_dino":
		_dinos_seguidos = 0


## "Viste a Coco": cambia el traje conservando los colores de las partes que ya pinto.
func _elegir_traje(id: String, inicial: bool) -> void:
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	var trajes: Dictionary = lamina.get("trajes", {})
	if not trajes.has(id):
		return
	var colores := {}
	for region: Dictionary in lienzo.lamina.get("regiones", []):
		if not bool(region.get("fija", false)):
			colores[str(region.get("id", ""))] = region["color"]
	var combinada := lamina.duplicate(true)
	combinada.erase("trajes")
	var traje: Dictionary = trajes[id]
	combinada["regiones"] = (lamina.get("regiones", []) as Array) + (traje.get("regiones", []) as Array)
	combinada["detalles"] = (traje.get("detalles_atras", []) as Array) + (lamina.get("detalles", []) as Array) + (traje.get("detalles", []) as Array)
	lienzo.poner_lamina(combinada)
	var regiones: Array = lienzo.lamina["regiones"]
	for i in regiones.size():
		var clave := str(regiones[i].get("id", ""))
		if colores.has(clave):
			lienzo.pintar_region(i, colores[clave])
	_traje = id
	if not inicial:
		_sfx_suave(SFX_RELLENO)
		_reaccion_anfitriona("salta")
		_reproducir_voz("traje", str(traje.get("voz", "")))
		_elegir_herramienta(lienzo.herramienta, false)


func _construir_modelo(lamina: Dictionary) -> void:
	_vaciar(_modelo)
	var hay_modelo: bool = bool(_cfg.get("modelo", false)) and not lamina.is_empty() and str(lamina.get("tipo", "zonas")) == "zonas"
	_modelo.visible = hay_modelo
	if not hay_modelo:
		return
	var copia := Laminas.preparar(lamina)
	for region: Dictionary in copia["regiones"]:
		if region.has("sugerido"):
			region["color"] = Color(str(region["sugerido"]))
	var tarjeta := Panel.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFF8EE")
	estilo.border_color = COLOR_CONTORNO
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(16)
	estilo.shadow_color = Color(COLOR_CONTORNO, 0.3)
	estilo.shadow_size = 4
	tarjeta.add_theme_stylebox_override("panel", estilo)
	_modelo.add_child(tarjeta)
	tarjeta.size = RECT_MODELO.size
	tarjeta.rotation = deg_to_rad(-3.0)
	var dibujo := Control.new()
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(dibujo)
	dibujo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dibujo.draw.connect(func() -> void:
		var escala := minf((RECT_MODELO.size.x - 16.0) / RECT_LIENZO.size.x, (RECT_MODELO.size.y - 16.0) / RECT_LIENZO.size.y)
		var desfase := (RECT_MODELO.size - RECT_LIENZO.size * escala) / 2.0
		dibujo.draw_rect(Rect2(desfase, RECT_LIENZO.size * escala), Color(str(_cfg.get("papel", "#FFF8EE"))))
		Laminas.dibujar(dibujo, copia, desfase, escala))


func _construir_puntos_hojas() -> void:
	_puntos_hojas.visible = _hojas.size() > 1
	_puntos_hojas.queue_redraw()


func _dibujar_puntos_hojas() -> void:
	var n := _hojas.size()
	var lado := 44.0
	var sep := 16.0
	var x0 := (_puntos_hojas.size.x - (n * lado + (n - 1) * sep)) / 2.0
	for i in n:
		var centro := Vector2(x0 + i * (lado + sep) + lado / 2.0, _puntos_hojas.size.y / 2.0)
		var rect := Rect2(centro - Vector2(lado, lado * 0.8) / 2.0, Vector2(lado, lado * 0.8))
		var hecho := i < _indice_hoja
		var actual := i == _indice_hoja
		var fondo := Color("#FFF8EE") if actual else (DORADO if hecho else Color(1, 1, 1, 0.35))
		_puntos_hojas.draw_rect(rect, fondo)
		_puntos_hojas.draw_rect(rect, COLOR_CONTORNO, false, 4.0 if actual else 3.0)
		if hecho:
			Figura.dibujar(_puntos_hojas, "estrella", Color.WHITE, centro, 13.0, false)


# ---------------------------------------------------------------------------
# Reacciones al pintar
# ---------------------------------------------------------------------------

func _al_tocar_lienzo() -> void:
	_hubo_toque = true
	if lienzo.herramienta in ["pincel_corazon", "pincel_estrella", "purpurina", "arcoiris"]:
		_primer_uso_especial(lienzo.herramienta)
	if lienzo.herramienta.begins_with("sello_"):
		_sfx_suave(SFX_SELLO)
	elif lienzo.herramienta == "balde" or lienzo.rellenar_con_toque:
		pass
	else:
		_sfx_suave(SFX_TOQUE)


func _al_usar_color(color: Color) -> void:
	var ahora := Time.get_ticks_msec()
	var nuevo_en_partida := true
	for c: Color in _colores_usados:
		if c.is_equal_approx(color):
			nuevo_en_partida = false
	if nuevo_en_partida:
		_colores_usados.append(color)
	var clave := color.to_html(false)
	var nuevo_en_hoja := not _colores_hoja.has(clave)
	_colores_hoja[clave] = true
	_cresta.imitar(_ultimos_colores())
	_recientes.append([ahora, color])
	while not _recientes.is_empty() and ahora - int(_recientes[0][0]) > 8000:
		_recientes.pop_front()
	if _revisar_arcoiris(ahora):
		return
	if _encargo == "coco_pide" and _revisar_pedido_color(color):
		return
	if nuevo_en_hoja and _perfil != "semilla" and lienzo.mosaico.is_empty():
		_reaccion_color(color, false)
	elif nuevo_en_hoja and _perfil == "semilla" and lienzo.herramienta != "arcoiris":
		_reaccion_color(color, false)
	_actualizar_depuracion()


## Los ultimos colores distintos usados (el mas nuevo al final), para la cresta.
func _ultimos_colores() -> Array:
	var lista: Array = []
	for i in range(_recientes.size() - 1, -1, -1):
		var c: Color = _recientes[i][1]
		var repetido := false
		for otro: Color in lista:
			if otro.is_equal_approx(c):
				repetido = true
		if not repetido:
			lista.push_front(c)
		if lista.size() >= Cresta.MAX_FRANJAS:
			break
	if lista.is_empty() and not _colores_usados.is_empty():
		lista.append(_colores_usados.back())
	return lista


## Momento memorable universal (ficha §3.10): 4 colores distintos seguidos -> cresta arcoiris.
func _revisar_arcoiris(ahora: int) -> bool:
	if ahora - _ms_ultimo_arcoiris < 20000:
		return false
	var distintos: Array = []
	for dato in _recientes:
		var c: Color = dato[1]
		var ya := false
		for otro: Color in distintos:
			if otro.is_equal_approx(c):
				ya = true
		if not ya:
			distintos.append(c)
	if distintos.size() < 4:
		return false
	_ms_ultimo_arcoiris = ahora
	_cresta.imitar(Figura.COLORES_ARCOIRIS.duplicate())
	_reaccion_anfitriona("baila")
	_estallido(_anfitriona.global_position + Vector2(_anfitriona.size.x * 0.55, 20), 12, Figura.COLORES_ARCOIRIS, 1.2)
	_reproducir_voz("arcoiris", _linea_al_azar("arcoiris"))
	_despues(2.2, func() -> void: _cresta.imitar(_ultimos_colores()))
	return true


func _reaccion_color(color: Color, forzar: bool) -> void:
	var ahora := Time.get_ticks_msec()
	var audio := get_node_or_null("/root/Audio")
	if not forzar and (ahora - _ms_ultima_reaccion < SEGUNDOS_ENTRE_REACCIONES * 1000.0 or (audio != null and audio.esta_hablando())):
		return
	_ms_ultima_reaccion = ahora
	var id := _id_de_color(color)
	var patron := str(_cfg.get("voces_colores", ""))
	if patron != "" and id != "":
		_reproducir_voz("color", patron % id)
	_reaccion_anfitriona("salta")


func _id_de_color(color: Color) -> String:
	var candidatos: Array = []
	for entrada: Dictionary in _botones_color:
		if str(entrada["id"]) != "":
			candidatos.append(entrada["id"])
	for id in Colores.COLORES:
		if Colores.color(id).is_equal_approx(color):
			return id
	return Colores.mas_cercano(color, candidatos if _encargo != "mezcla_paleta" else [])


func _al_poner_sello(tipo: String, _posicion: Vector2) -> void:
	_primer_uso_especial("sello_" + tipo)
	if tipo == "dino":
		_dinos_seguidos += 1
		if lienzo.sellos_vivos and _dinos_seguidos >= 3:
			_dinos_seguidos = 0
			_despues(0.35, func() -> void: lienzo.caminar_sellos("dino", 3))
			if _paseos_dino < 2:
				_reproducir_voz("dino_camina", _linea_al_azar("dino_camina"))
			_paseos_dino += 1
	else:
		_dinos_seguidos = 0


## Primera vez que se usa un pincel o sello especial: Coco (o Cometa) lo nota con carino.
func _primer_uso_especial(herramienta: String) -> void:
	if _usados_especiales.has(herramienta):
		return
	_usados_especiales[herramienta] = true
	var clave := "uso_" + herramienta
	var linea := _linea_al_azar(clave)
	if linea != "":
		_reproducir_voz(clave, linea)
	if herramienta in ["pincel_corazon", "sello_corazon"] and _perfil == "brote":
		_corazon_coreano()


func _al_rellenar_region(indice: int, color: Color) -> void:
	_sfx_suave(SFX_RELLENO)
	var region: Dictionary = lienzo.lamina["regiones"][indice]
	var poligono: PackedVector2Array = region["poligono"]
	var caja := Rect2(poligono[0], Vector2.ZERO)
	for p in poligono:
		caja = caja.expand(p)
	_estallido(lienzo.global_position + caja.get_center(), 6, [color, color.lightened(0.4), Color.WHITE], 0.8)
	if bool(_cfg.get("tinte_coco", false)) and str(region.get("id", "")) == "cuerpo":
		_anfitriona.modulate = Color.WHITE.lerp(color, 0.5)
		_reaccion_anfitriona("salta")


func _al_completar_lamina() -> void:
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	var espera := 0.6
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.esta_hablando():
		espera = 1.6
	_despues(espera, func() -> void:
		if _mostrando:
			return
		_confeti_en(lienzo.global_position + RECT_LIENZO.size / 2.0)
		_reaccion_anfitriona("baila")
		var voz := str(lamina.get("voz", ""))
		if voz != "":
			_lamina_nombrada = true
			_reproducir_voz("lamina", voz)
			var dato := str(lamina.get("voz_dato", ""))
			if dato != "":
				_voz_diferida("dato", dato, _duracion_voz(voz) + 0.3)
		else:
			_reproducir_voz("lamina_completa", _linea_al_azar("lamina_completa"))
		_revelar_boton_mostrar(false))


# ---------------------------------------------------------------------------
# Coco pide colores (Nicole, zona 3)
# ---------------------------------------------------------------------------

func _preparar_pedidos() -> void:
	_pedidos.clear()
	_pedido_actual = -1
	_fallos_pedido = 0
	_burbuja.hide()
	var lista: Array = _cfg.get("pedidos", []).duplicate()
	if lista.is_empty() or _encargo not in ["coco_pide", "mezcla_paleta"]:
		return
	lista.shuffle()
	var cuantos := int(_cfg.get("pedidos_por_partida", lista.size()))
	_pedidos = lista.slice(0, cuantos)
	_pedido_actual = 0


func _ruta_pedido() -> String:
	if _pedido_actual < 0 or _pedido_actual >= _pedidos.size():
		return ""
	var patron := str(_cfg.get("voces_pedidos", ""))
	return patron % str(_pedidos[_pedido_actual]) if patron != "" else ""


func _revisar_pedido_color(color: Color) -> bool:
	if _pedido_actual < 0 or _pedido_actual >= _pedidos.size():
		return false
	var pedido := str(_pedidos[_pedido_actual])
	if _id_de_color(color) == pedido:
		_cumplir_pedido(pedido)
		return true
	_fallos_pedido += 1
	if _fallos_pedido >= 2:
		# Pista suave (Brote: los errores dan pistas por voz): la burbuja muestra el color y su
		# mancha en la paleta salta. Nunca un "no".
		_fallos_pedido = 0
		_mostrar_burbuja(Colores.color(pedido))
		for entrada: Dictionary in _botones_color:
			if entrada["id"] == pedido:
				_rebote(entrada["boton"], 3)
		_reproducir_voz("pedido", _ruta_pedido())
		return true
	return false


func _cumplir_pedido(pedido: String) -> void:
	pedido_cumplido.emit(pedido)
	_burbuja.hide()
	_fallos_pedido = 0
	var patron := str(_cfg.get("voces_logrado", _cfg.get("voces_colores", "")))
	var voz := patron % pedido if patron != "" else ""
	_reproducir_voz("pedido_logrado", voz)
	_reaccion_anfitriona("baila")
	_estallido(_anfitriona.global_position + Vector2(_anfitriona.size.x / 2.0, 40), 10, [Colores.color(pedido), DORADO, Color.WHITE], 1.2)
	_pedido_actual += 1
	_actualizar_depuracion()
	if _pedido_actual >= _pedidos.size():
		_pedido_actual = -1
		_voz_diferida("pedidos_listos", _linea_al_azar("pedidos_listos"), _duracion_voz(voz) + 0.4)
		_despues(_duracion_voz(voz) + 0.4, func() -> void: _revelar_boton_mostrar(false))
	else:
		_voz_diferida("pedido", _ruta_pedido(), _duracion_voz(voz) + 0.5)


func _mostrar_burbuja(color: Color) -> void:
	_burbuja.set_meta("color", color)
	_burbuja.show()
	_burbuja.queue_redraw()
	_rebote(_burbuja)


func _dibujar_burbuja() -> void:
	var color: Color = _burbuja.get_meta("color", Color.WHITE)
	var rect := Rect2(Vector2(4, 4), _burbuja.size - Vector2(8, 8))
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#FFF8EE")
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(28)
	_burbuja.draw_style_box(caja, rect)
	Figura.dibujar(_burbuja, "gota", color, rect.get_center(), 24.0, false)


# ---------------------------------------------------------------------------
# Mezcla en la paleta (Sofia, zona 3)
# ---------------------------------------------------------------------------

func _preparar_mezcla() -> void:
	_vaciar(_platito)
	_gotas = {}
	_mezclas_dichas.clear()
	_mis_colores.clear()
	if _encargo != "mezcla_paleta":
		return
	var platito := Button.new()
	platito.focus_mode = Control.FOCUS_NONE
	platito.flat = true
	platito.tooltip_text = "Platito de mezcla"
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		platito.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	_platito.add_child(platito)
	platito.position = Vector2(0, 176)
	platito.size = Vector2(RECT_PALETA.size.x, 150)
	var dibujo := _icono(platito, _dibujar_platito)
	platito.set_meta("dibujo", dibujo)
	platito.pressed.connect(func() -> void:
		_sfx_suave(SFX_ELEGIR)
		_rebote(platito)
		lienzo.color_actual = Colores.mezclar(_gotas) if not _gotas.is_empty() else Color.WHITE)
	var vaciar := Button.new()
	vaciar.focus_mode = Control.FOCUS_NONE
	vaciar.tooltip_text = "Vaciar el platito"
	_platito.add_child(vaciar)
	vaciar.position = Vector2(RECT_PALETA.size.x - 70, 180)
	vaciar.size = Vector2(66, 66)
	vaciar.custom_minimum_size = Vector2(64, 64)
	_estilizar_boton(vaciar, Color("#CFF5F1"))
	_icono(vaciar, _dibujar_icono_vaciar)
	vaciar.pressed.connect(func() -> void:
		_sfx_suave(SFX_TOQUE)
		_gotas = {}
		lienzo.color_actual = Color.WHITE
		dibujo.queue_redraw()
		_refrescar_iconos())
	lienzo.color_actual = Color.WHITE


func _agregar_gota(id: String) -> void:
	if int(_gotas.get(id, 0)) >= 9:
		return
	_gotas[id] = int(_gotas.get(id, 0)) + 1
	var mezcla := Colores.mezclar(_gotas)
	lienzo.color_actual = mezcla
	var dibujo: Control = (_platito.get_child(0) as Control).get_meta("dibujo")
	dibujo.queue_redraw()
	_rebote(_platito.get_child(0))
	_refrescar_iconos()
	var nombre := Colores.nombre_mezcla(_gotas)
	_guardar_mi_color(mezcla)
	if _pedido_actual >= 0 and _pedido_actual < _pedidos.size() and nombre == str(_pedidos[_pedido_actual]):
		_mezclas_dichas[nombre] = true
		_cumplir_pedido(nombre)
		return
	var total := 0
	for v in _gotas.values():
		total += int(v)
	if total >= 2 and not _mezclas_dichas.has(nombre) and nombre not in PRIMARIOS:
		_mezclas_dichas[nombre] = true
		var patron := str(_cfg.get("voces_mezclas", ""))
		if patron != "":
			_reproducir_voz("mezcla", patron % nombre)
			_reaccion_anfitriona("salta")


## "Mis colores": las ultimas mezclas quedan guardadas en la paleta para volver a usarlas.
func _guardar_mi_color(color: Color) -> void:
	for c: Color in _mis_colores:
		if c.is_equal_approx(color):
			return
	_mis_colores.append(color)
	if _mis_colores.size() > 6:
		_mis_colores.pop_front()
	for hijo in _platito.get_children():
		if hijo.has_meta("mi_color"):
			_platito.remove_child(hijo)
			hijo.queue_free()
	for i in _mis_colores.size():
		var boton := Button.new()
		boton.focus_mode = Control.FOCUS_NONE
		boton.flat = true
		boton.set_meta("mi_color", true)
		boton.set_meta("color", _mis_colores[i])
		boton.set_meta("elegido", false)
		boton.set_meta("numero", "")
		for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
			boton.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
		_platito.add_child(boton)
		boton.position = Vector2((i % 3) * 69.0, 336.0 + (i / 3) * 72.0)
		boton.size = Vector2(66, 66)
		_icono(boton, _dibujar_mancha)
		var color: Color = _mis_colores[i]
		boton.pressed.connect(func() -> void:
			_sfx_suave(SFX_ELEGIR)
			_rebote(boton)
			lienzo.color_actual = color
			_refrescar_iconos())


func _dibujar_platito(icono: Control) -> void:
	var c := Vector2(icono.size.x / 2.0 - 30, icono.size.y / 2.0 + 6)
	var plato := Laminas.elipse(c, 66, 50, 40)
	icono.draw_colored_polygon(plato, Color.WHITE)
	var cerrado := plato.duplicate()
	cerrado.append(plato[0])
	icono.draw_polyline(cerrado, COLOR_CONTORNO, 4.0, true)
	icono.draw_colored_polygon(Laminas.elipse(c, 50, 36, 40), Color("#EEF2F8"))
	if not _gotas.is_empty():
		var mancha := Laminas.elipse(c + Vector2(0, 2), 40, 28, 40)
		icono.draw_colored_polygon(mancha, Colores.mezclar(_gotas))
		var borde := mancha.duplicate()
		borde.append(mancha[0])
		icono.draw_polyline(borde, Color(COLOR_CONTORNO, 0.5), 2.5, true)
	# Gotitas de la receta (cuantas de cada color) al lado del plato.
	var y := 16.0
	for id in PRIMARIOS:
		var n := int(_gotas.get(id, 0))
		for k in mini(n, 5):
			icono.draw_circle(Vector2(icono.size.x - 76 + k * 13, y + 80), 6.0, Colores.color(id))
			icono.draw_arc(Vector2(icono.size.x - 76 + k * 13, y + 80), 6.0, 0, TAU, 12, COLOR_CONTORNO, 1.5, true)
		y += 16.0


# ---------------------------------------------------------------------------
# Mostrar a Coco (el destello, sin evaluar nada)
# ---------------------------------------------------------------------------

func _revelar_boton_mostrar(con_voz: bool) -> void:
	if _terminado or _mostrando:
		return
	var ya_visible := boton_mostrar.visible
	boton_mostrar.visible = true
	if _tween_mostrar != null and _tween_mostrar.is_valid():
		_tween_mostrar.kill()
	_tween_mostrar = create_tween().set_loops(4)
	_tween_mostrar.tween_property(boton_mostrar, "scale", Vector2(1.14, 1.14), 0.3).set_trans(Tween.TRANS_SINE)
	_tween_mostrar.tween_property(boton_mostrar, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	if con_voz and not ya_visible:
		_reproducir_voz("muestramelo", _linea_al_azar("muestramelo"))


## El nino le muestra su dibujo a Coco: se guarda el PNG, Coco celebra (sin evaluar) y se pasa a
## la hoja siguiente o a la celebracion final. Publica para los arneses QA.
func mostrar_a_coco() -> String:
	if _mostrando or _terminado or _indice_hoja < 0:
		return ""
	_mostrando = true
	lienzo.bloqueado = true
	lienzo.terminar_trazo()
	_voz_diferida_id += 1
	if _tween_mostrar != null and _tween_mostrar.is_valid():
		_tween_mostrar.kill()
	boton_mostrar.scale = Vector2.ONE
	reproducir_sfx(SFX_MOSTRAR)
	var ruta := _guardar_dibujo()
	hoja_mostrada.emit(_indice_hoja, ruta)
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	var voz := ""
	if not _lamina_nombrada and str(lamina.get("voz", "")) != "":
		voz = str(lamina["voz"])
	elif _es_igualita():
		voz = _linea_al_azar("igualita")
	if voz == "":
		voz = _linea_al_azar("mostrar")
	_reproducir_voz("mostrar", voz)
	var colores := _ultimos_colores()
	_cresta.imitar(colores if colores.size() >= 2 else Figura.COLORES_ARCOIRIS.duplicate())
	_reaccion_anfitriona("baila")
	_confeti_en(lienzo.global_position + RECT_LIENZO.size / 2.0)
	_estallido(boton_mostrar.global_position + boton_mostrar.size / 2.0, 14, Figura.COLORES_ARCOIRIS, 1.3)
	var tween := create_tween()
	tween.tween_property(lienzo, "scale", Vector2(1.03, 1.03), 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(lienzo, "scale", Vector2.ONE, 0.2)
	var espera := clampf(_duracion_voz(voz) + 0.5, 1.4, 5.0)
	_despues(espera, _despues_de_mostrar)
	return ruta


func _despues_de_mostrar() -> void:
	if _indice_hoja + 1 < _hojas.size():
		var tween := create_tween()
		lienzo.pivot_offset = RECT_LIENZO.size / 2.0
		tween.tween_property(lienzo, "modulate:a", 0.0, 0.25)
		tween.parallel().tween_property(lienzo, "scale", Vector2(0.92, 0.92), 0.25)
		tween.tween_callback(func() -> void: _empezar_hoja(_indice_hoja + 1))
		tween.tween_property(lienzo, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(lienzo, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		return
	_terminado = true
	celebrar(calcular_destellos(), 0, _linea_al_azar("victoria_final"))


## 20 destellos por hoja mostrada + 1 por color distinto usado (hasta 10). Nunca se exige nada.
func calcular_destellos() -> int:
	return maxi(1, _indice_hoja + 1) * DESTELLOS_POR_HOJA + mini(_colores_usados.size(), MAX_DESTELLOS_COLORES)


## Colorear por zonas con tarjeta modelo: si cada zona quedo del color de la tarjeta, Coco lo nota.
func _es_igualita() -> bool:
	if not bool(_cfg.get("modelo", false)) or lienzo.lamina.is_empty():
		return false
	var candidatos: Array = []
	for entrada: Dictionary in _botones_color:
		candidatos.append(entrada["id"])
	for i in lienzo.regiones_rellenables():
		var region: Dictionary = lienzo.lamina["regiones"][i]
		if not region.has("sugerido"):
			continue
		var esperado := Colores.mas_cercano(Color(str(region["sugerido"])), candidatos)
		if Colores.mas_cercano(region["color"], candidatos) != esperado:
			return false
	return true


func _guardar_dibujo() -> String:
	var hermano := obtener_id_personaje()
	var sello := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var ruta := "%s/%s/%s_%d_%s.png" % [CARPETA_DIBUJOS, hermano, str(nivel.get("id_nivel", "dibujo")), _indice_hoja + 1, sello]
	var imagen := lienzo.componer()
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	var error := imagen.save_png(ruta)
	if error != OK:
		push_warning("motor_lienzo_libre: no se pudo guardar el dibujo en %s (%s)" % [ruta, error_string(error)])
		return ""
	pngs_guardados.append(ruta)
	print("[dibujo] %s" % ruta)
	# El ala decorada y el traje de Coco tienen nombre fijo para que el hangar y el mapa los encuentren.
	var fijo := str(_cfg.get("guardar_como", ""))
	if fijo != "":
		imagen.save_png("%s/%s/%s.png" % [CARPETA_DIBUJOS, hermano, fijo])
	if _traje != "":
		var colores := {}
		for region: Dictionary in lienzo.lamina.get("regiones", []):
			if not bool(region.get("fija", false)):
				colores[str(region.get("id", ""))] = "#" + (region["color"] as Color).to_html(false)
		var archivo := FileAccess.open("%s/%s/traje_coco.json" % [CARPETA_DIBUJOS, hermano], FileAccess.WRITE)
		if archivo != null:
			archivo.store_string(JSON.stringify({"traje": _traje, "colores": colores}, "  "))
			archivo.close()
	return ruta


# ---------------------------------------------------------------------------
# Momentos memorables y efectos
# ---------------------------------------------------------------------------

## Nicole: Coco le devuelve su corazon coreano la primera vez que usa el pincel corazon.
func _corazon_coreano() -> void:
	var corazon := Figura.new()
	corazon.figura = "corazon"
	corazon.color = Color("#FF7EB6")
	corazon.con_cara = true
	corazon.alegre = true
	corazon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corazon.size = Vector2(110, 110)
	corazon.pivot_offset = corazon.size / 2.0
	_efectos.add_child(corazon)
	corazon.global_position = _anfitriona.global_position + Vector2(_anfitriona.size.x / 2.0 - 55, -70)
	corazon.scale = Vector2.ZERO
	var tween := corazon.create_tween()
	tween.tween_property(corazon, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		tween.tween_property(corazon, "scale", Vector2(1.0, 1.0), 0.18)
		tween.tween_property(corazon, "scale", Vector2(1.2, 1.2), 0.18)
	tween.tween_property(corazon, "modulate:a", 0.0, 0.4)
	tween.tween_callback(corazon.queue_free)
	_reaccion_anfitriona("salta")


## Sofia: la purpurina quieta un segundo hace llover destellos dorados (ficha §3.10).
func _lluvia_dorada(posicion: Vector2) -> void:
	_primer_uso_especial("purpurina_lluvia")
	var global := lienzo.global_position + posicion
	for i in 22:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = DORADO if i % 3 else Color.WHITE
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(14.0, 26.0)
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.global_position = global + Vector2(randf_range(-90, 90), randf_range(-140, -40))
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position:y", chispa.position.y + randf_range(120, 220), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 1.1)
		tween.tween_property(chispa, "modulate:a", 0.0, 1.1).set_delay(0.5)
		tween.chain().tween_callback(chispa.queue_free)
	var herramienta := lienzo.herramienta
	var color := lienzo.color_actual
	lienzo.color_actual = DORADO
	for i in 14:
		var p := posicion + Vector2(randf_range(-80, 80), randf_range(-30, 110))
		lienzo._estampar_en(p, false)
	lienzo.color_actual = color
	lienzo.herramienta = herramienta


func _preparar_notas() -> void:
	for i in 4:
		var reproductor := AudioStreamPlayer.new()
		reproductor.bus = "SFX"
		add_child(reproductor)
		_notas.append(reproductor)
	for hz in NOTAS_HZ:
		_sonidos_nota.append(_campanita(hz))


## Nota de campanita sintetizada (seno con armonico y caida suave): sin archivos de audio.
func _campanita(hz: float) -> AudioStreamWAV:
	var frecuencia := 22050
	var muestras := int(frecuencia * 0.7)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / frecuencia
		var envolvente := exp(-t * 5.5) * minf(1.0, t * 200.0)
		var valor := (sin(TAU * hz * t) * 0.7 + sin(TAU * hz * 2.0 * t) * 0.2 + sin(TAU * hz * 3.0 * t) * 0.1) * envolvente * 0.45
		datos.encode_s16(i * 2, int(clampf(valor, -1.0, 1.0) * 32767.0))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = frecuencia
	sonido.stereo = false
	sonido.data = datos
	return sonido


## Dedo magico: la altura del trazo elige la nota (mas arriba, mas aguda).
func _tocar_nota(altura: float) -> void:
	if not bool(_cfg.get("notas", false)) or _sonidos_nota.is_empty():
		return
	var indice := clampi(int(altura * _sonidos_nota.size()), 0, _sonidos_nota.size() - 1)
	var reproductor := _notas[_indice_nota % _notas.size()]
	_indice_nota += 1
	reproductor.stream = _sonidos_nota[indice]
	reproductor.play()


func _confeti_en(posicion: Vector2) -> void:
	_confeti.position = posicion
	_confeti.restart()


func _estallido(centro: Vector2, cantidad: int, colores: Array, escala := 1.0) -> void:
	for i in cantidad:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = colores[i % colores.size()]
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(18.0, 30.0) * escala
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.global_position = centro - chispa.size / 2.0
		var angulo := TAU * i / cantidad + randf_range(-0.3, 0.3)
		var destino := chispa.position + Vector2.from_angle(angulo) * randf_range(50.0, 100.0) * escala
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 0.5)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


# ---------------------------------------------------------------------------
# Voz, Coco y Cometa
# ---------------------------------------------------------------------------

func _linea(clave: String) -> String:
	var valor = _cfg.get("lineas_voz", {}).get(clave, "")
	if valor is Array:
		return str(valor[0]) if not valor.is_empty() else ""
	return str(valor)


## Elige una variante sin repetir la ultima, para que no suene monotono.
func _linea_al_azar(clave: String) -> String:
	var opciones = _cfg.get("lineas_voz", {}).get(clave, [])
	if not (opciones is Array):
		return str(opciones)
	if opciones.is_empty():
		return ""
	var elegida := str(opciones[randi() % opciones.size()])
	if elegida == _ultima_linea and opciones.size() > 1:
		elegida = str(opciones[(opciones.find(elegida) + 1) % opciones.size()])
	_ultima_linea = elegida
	return elegida


func _reproducir_voz(clave: String, ruta: String) -> void:
	# Traza en consola para los arneses QA + reproduccion real via contrato base.
	if ruta != "":
		print("[voz:%s] %s" % [clave, ruta])
		reproducir_voz(ruta)


func _voz_diferida(clave: String, ruta: String, segundos: float) -> void:
	if ruta == "":
		return
	_voz_diferida_id += 1
	var id := _voz_diferida_id
	await get_tree().create_timer(segundos).timeout
	if id == _voz_diferida_id and is_inside_tree() and not _terminado and not _mostrando:
		_reproducir_voz(clave, ruta)


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


## Efecto de respuesta inmediata (GDD §6.5), sin ametrallar el mismo sonido al arrastrar.
func _sfx_suave(ruta: String) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - int(_ms_sfx.get(ruta, -1000)) < 90:
		return
	_ms_sfx[ruta] = ahora
	reproducir_sfx(ruta)


## Tocar a Cometa repite la instruccion (GDD §6.2): el pedido actual o la intro de la etapa.
func _al_tocar_cometa() -> void:
	_sfx_suave(SFX_TOQUE)
	if _pedido_actual >= 0 and _ruta_pedido() != "":
		_reproducir_voz("pedido", _ruta_pedido())
		return
	var pista := _linea("pista")
	_reproducir_voz("pista", pista if pista != "" else _linea("intro"))


## Tocar a Coco: salta y vuelve a explicar. En Semilla, ademas, aparece "mostrar a Coco".
func _al_tocar_anfitriona(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not toque:
		return
	_sfx_suave(SFX_TOQUE)
	_reaccion_anfitriona("salta")
	if not boton_mostrar.visible:
		_revelar_boton_mostrar(true)
		return
	_reproducir_voz("intro", _linea("intro"))


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
			tween.tween_property(self, "_salto_anfitriona", 40.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_anfitriona, "scale", Vector2(0.94, 1.08), 0.18)
			tween.tween_property(self, "_salto_anfitriona", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_anfitriona, "scale", Vector2.ONE, 0.3)
		"baila":
			for i in 6:
				tween.tween_property(self, "_salto_anfitriona", 32.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(_anfitriona, "rotation", deg_to_rad(-9.0 if i % 2 == 0 else 9.0), 0.16)
				tween.tween_property(self, "_salto_anfitriona", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(_anfitriona, "rotation", 0.0, 0.12)


func _rebote(control: Control, veces := 1) -> void:
	control.pivot_offset = control.size / 2.0
	var tween := control.create_tween()
	for i in veces:
		tween.tween_property(control, "scale", Vector2(0.86, 0.86), 0.07)
		tween.tween_property(control, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _actualizar_depuracion() -> void:
	if not _panel_depuracion.visible:
		return
	var pedido := "-" if _pedido_actual < 0 or _pedido_actual >= _pedidos.size() else str(_pedidos[_pedido_actual])
	_panel_depuracion.text = "DEPURACION (F3)\nnivel: %s\nperfil: %s · juega: %s\nencargo: %s · hoja %d de %d\nlamina: %s\nherramienta: %s\ncolores usados: %d\npedido: %s\nsi muestra ahora: %d destellos" % [
		nivel.get("id_nivel", "?"), _perfil, obtener_id_personaje(), _encargo, _indice_hoja + 1, _hojas.size(),
		str(_hojas[_indice_hoja]["lamina"].get("id", "-")) if _indice_hoja >= 0 else "-", lienzo.herramienta,
		_colores_usados.size(), pedido, calcular_destellos()]


# ---------------------------------------------------------------------------
# Dibujo de iconos (estilo "peluche pintado", sin texto)
# ---------------------------------------------------------------------------

func _estilizar_boton(boton: Button, fondo: Color, conectar := true) -> void:
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
	if conectar:
		boton.button_down.connect(_rebote.bind(boton))


func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-26, 0), Vector2(2, -26), Vector2(2, -12), Vector2(26, -12), Vector2(26, 12), Vector2(2, 12), Vector2(2, 26)]:
		puntos.append(c + p * k)
	icono.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(icono, puntos, 5.0 * k)


## Marquito con un dibujito en la esquina del boton "mostrar a Coco": "le muestro mi dibujo".
func _dibujar_marquito(icono: Control) -> void:
	var rect := Rect2(icono.size - Vector2(62, 54), Vector2(56, 46))
	icono.draw_rect(rect, Color("#FFF8EE"))
	icono.draw_rect(rect, COLOR_CONTORNO, false, 4.0)
	var c := rect.get_center()
	icono.draw_circle(c + Vector2(-10, -6), 8.0, Color("#FF7EB6"))
	icono.draw_circle(c + Vector2(8, 4), 9.0, Color("#6FD6E8"))
	icono.draw_circle(c + Vector2(-4, 10), 6.0, DORADO)


## Mancha de pintura redondita de la paleta (con numero en el mosaico de Sofia).
func _dibujar_mancha(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	var color: Color = boton.get_meta("color", Color.WHITE)
	var numero: String = boton.get_meta("numero", "")
	var elegido: bool = boton.get_meta("elegido", false)
	var c := icono.size / 2.0
	var r := minf(icono.size.x, icono.size.y) * 0.42
	var mancha := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var ondulacion := 1.0 + 0.06 * sin(a * 5.0 + color.h * 10.0)
		mancha.append(c + Vector2(cos(a) * r * ondulacion * (icono.size.x / icono.size.y if numero != "" else 1.0), sin(a) * r * ondulacion))
	if elegido:
		var halo := PackedVector2Array()
		for p in mancha:
			halo.append(c + (p - c) * 1.18)
		icono.draw_colored_polygon(halo, Color(1, 1, 1, 0.9))
		Figura.contornear(icono, halo, 4.0)
	icono.draw_colored_polygon(mancha, color)
	Figura.contornear(icono, mancha, 4.0)
	icono.draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.55))
	if numero != "" and _fuente != null:
		var claro := color.get_luminance() > 0.6
		var tam := int(r * 1.1)
		icono.draw_string(_fuente, Vector2(0, c.y + tam * 0.36), numero, HORIZONTAL_ALIGNMENT_CENTER, icono.size.x, tam, COLOR_CONTORNO if claro else Color.WHITE)


func _dibujar_herramienta(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	var id: String = boton.get_meta("id", "")
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var color := lienzo.color_actual
	if id.begins_with("traje_"):
		_dibujar_traje_mini(icono, id.trim_prefix("traje_"))
		return
	if id.begins_with("sello_"):
		var tipo := id.trim_prefix("sello_")
		var radio := 34.0 * k
		for parte: Dictionary in Sellos.partes(tipo, color):
			var poligono := PackedVector2Array()
			for p: Vector2 in parte["poligono"]:
				poligono.append(c + p * radio)
			if poligono.size() >= 3 and parte.has("color"):
				icono.draw_colored_polygon(poligono, parte["color"])
				if parte.get("contorno", true):
					Figura.contornear(icono, poligono, 2.5 * k)
		return
	match id:
		"pincel", "pincel_grueso":
			var grosor := 12.0 if id == "pincel" else 22.0
			icono.draw_line(c + Vector2(18, -26) * k, c + Vector2(-2, 2) * k, Color("#C98A4B"), 10.0 * k, true)
			icono.draw_circle(c + Vector2(-8, 10) * k, grosor * k, color)
			icono.draw_arc(c + Vector2(-8, 10) * k, grosor * k, 0, TAU, 24, COLOR_CONTORNO, 3.0 * k, true)
		"goma":
			var goma := Laminas.rectangulo(Rect2(c + Vector2(-28, -16) * k, Vector2(56, 32) * k), 8.0 * k)
			icono.draw_colored_polygon(goma, Color("#FFB3C7"))
			Figura.contornear(icono, goma, 3.5 * k)
			icono.draw_line(c + Vector2(4, -16) * k, c + Vector2(4, 16) * k, COLOR_CONTORNO, 3.0 * k)
		"balde":
			var balde := PackedVector2Array([c + Vector2(-24, -10) * k, c + Vector2(24, -10) * k, c + Vector2(18, 28) * k, c + Vector2(-18, 28) * k])
			icono.draw_colored_polygon(balde, Color("#D7DCEA"))
			Figura.contornear(icono, balde, 3.5 * k)
			icono.draw_colored_polygon(Laminas.elipse(c + Vector2(0, -10) * k, 24 * k, 8 * k, 20), color)
			icono.draw_arc(c + Vector2(0, -12) * k, 26 * k, PI, TAU, 16, COLOR_CONTORNO, 3.0 * k, true)
			Figura.dibujar(icono, "gota", color, c + Vector2(26, 14) * k, 12 * k, false)
		"arcoiris":
			for i in Figura.COLORES_ARCOIRIS.size():
				icono.draw_arc(c + Vector2(0, 14) * k, (34.0 - i * 5.0) * k, PI, TAU, 24, Figura.COLORES_ARCOIRIS[i], 5.5 * k, true)
		"purpurina":
			for p in [[Vector2(-12, -8), 16.0, DORADO], [Vector2(16, 12), 12.0, Color("#FFF3B0")], [Vector2(-10, 20), 9.0, color]]:
				var chispa := PackedVector2Array()
				for i in 8:
					chispa.append(c + p[0] * k + Vector2.from_angle(-PI / 2.0 + i * PI / 4.0) * p[1] * k * (1.0 if i % 2 == 0 else 0.3))
				icono.draw_colored_polygon(chispa, p[2])
				Figura.contornear(icono, chispa, 2.0 * k)
		"pincel_corazon", "pincel_estrella":
			var figura := id.trim_prefix("pincel_")
			for p in [[Vector2(-16, 12), 14.0], [Vector2(2, -4), 12.0], [Vector2(18, -18), 10.0]]:
				Figura.dibujar(icono, figura, color, c + p[0] * k, p[1] * k, false)


func _dibujar_traje_mini(icono: Control, id: String) -> void:
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"] if _indice_hoja >= 0 else {}
	var trajes: Dictionary = lamina.get("trajes", {})
	if not trajes.has(id):
		return
	var mini := lamina.duplicate(true)
	mini.erase("trajes")
	var traje: Dictionary = trajes[id]
	mini["regiones"] = (lamina.get("regiones", []) as Array) + (traje.get("regiones", []) as Array)
	mini["detalles"] = []
	var preparada := Laminas.preparar(mini)
	for region: Dictionary in preparada["regiones"]:
		if region.has("sugerido"):
			region["color"] = Color(str(region["sugerido"]))
	var caja := Rect2(250, 20, 330, 500)
	var datos_caja = lamina.get("caja_mini", null)
	if datos_caja is Array and datos_caja.size() == 4:
		caja = Rect2(float(datos_caja[0]), float(datos_caja[1]), float(datos_caja[2]), float(datos_caja[3]))
	var escala := minf((icono.size.x - 12.0) / caja.size.x, (icono.size.y - 12.0) / caja.size.y)
	var desfase := icono.size / 2.0 - caja.get_center() * escala
	Laminas.dibujar(icono, preparada, desfase, escala)


func _dibujar_icono_vaciar(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 66.0
	var gota := Figura.poligono("gota", c, 18.0 * k)
	icono.draw_colored_polygon(gota, Color("#8ED3FF"))
	Figura.contornear(icono, gota, 2.5 * k)
	icono.draw_arc(c + Vector2(0, 2) * k, 26.0 * k, -PI * 0.9, PI * 0.2, 20, COLOR_CONTORNO, 3.5 * k, true)
	var punta := c + Vector2.from_angle(PI * 0.2) * 26.0 * k
	icono.draw_colored_polygon(PackedVector2Array([punta + Vector2(-8, -4) * k, punta + Vector2(6, -6) * k, punta + Vector2(0, 8) * k]), COLOR_CONTORNO)
