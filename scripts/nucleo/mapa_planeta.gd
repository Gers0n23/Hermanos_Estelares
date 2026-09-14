extends Node2D

## Mapa interno de un planeta: zonas y estaciones (GDD §3 "Mapa de cada planeta", HE-41,
## docs/fichas/planeta-arcoiris-zonas.md). Es el "menu secundario" entre el Mapa Estelar y los
## minijuegos.
##
## Data-driven desde `ruta_mapa` (p. ej. `datos/planetas/arcoiris/mapa.json`): zonas, sus 4
## estaciones, escena del motor y nivel de cada hermano. Regla de oro 3: este nucleo NUNCA conoce
## minijuegos concretos; solo instancia la escena que dice el JSON con el contrato de
## `minijuego_base.gd` (ruta_nivel, planeta_id, id_perfil, completado, salir_solicitado).
##
## Progreso: no guarda nada propio. El estado de estaciones y zonas se DERIVA de los niveles que
## `Progreso` ya registra por hermano (id_nivel completado + mejores estrellitas), asi que no hizo
## falta migrar la version del guardado (HE-41 la preveia; queda para cuando se guarden datos nuevos).
##
## Reglas (ficha de zonas §2.1): zona 1 abierta; la siguiente se abre al completar 2 estaciones de
## la actual. Mientras falten minijuegos por implementar, se piden min(2, estaciones jugables), para
## que nadie quede trabado. La zona secreta se revela al completar todas las estaciones jugables de
## la anterior. Zonas no abiertas: dormidas y descoloridas, nunca con candado (GDD §3).
##
## UX (GDD §6): todo narrado por voz, objetivos >=96 px, sin texto obligatorio (los nombres son un
## extra para Sofia). Tocar a Cometa lleva directo a la siguiente estacion pendiente (riesgo 5 de la
## ficha: Maxi no tiene que navegar). F4 (solo PC, depuracion del PO) abre todas las zonas.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const RUTA_MAPA_ESTELAR := "res://escenas/nucleo/mapa_estelar.tscn"
const PREFIJO_AUDIO := "res://assets/audio/"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const RUTA_COMETA := "res://assets/sprites/personajes/cometa_base.png"
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_ELEGIR := "res://assets/audio/sfx/ui/seleccionar.ogg"
const SFX_NO := "res://assets/audio/sfx/ui/no_es_este.ogg"
const SFX_FIESTA := "res://assets/audio/sfx/ui/confirmar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const RADIO_ZONA := 62.0
const LADO_TARJETA := 196.0
const PANEL_ESTACIONES := Rect2(236, 470, 894, 236)
const COLOR_DORMIDA := Color("#B9B4C9")
const BANDAS := ["rojo", "naranja", "amarillo", "verde", "azul", "violeta"]
const COLOR_BANDA := {
	"rojo": Color("#FF6B6B"), "naranja": Color("#FF9F4A"), "amarillo": Color("#FFCB3D"),
	"verde": Color("#7DD87A"), "azul": Color("#4A8BE0"), "violeta": Color("#B48CE8"), "brillo": Color("#FFE38A"),
}
const COLORES_HERMANO := {"maxi": Color("4aa8ff"), "nicole": Color("ff5fae"), "sofia": Color("4fd8e0")}
const RETRATOS_HERMANO := {
	"maxi": "res://assets/sprites/personajes/maxi_base.png",
	"nicole": "res://assets/sprites/personajes/nicole_base.png",
	"sofia": "res://assets/sprites/personajes/sofia_base.png",
}

## Lo que cada hermano ya vio de cada planeta en esta sesion: al volver de un juego se celebra lo
## que cambio (el color que vuelve, la zona que despierta). Se deriva del progreso; no se persiste.
static var _visto := {}
static var _zona_elegida := {}
static var _ruta_por_defecto := ""
## F4: el PO puede abrir todas las zonas para revisar variantes sin jugar las anteriores.
static var todo_abierto := false

@export_file("*.json") var ruta_mapa: String = ""

var mapa: Dictionary = {}
var planeta_id := ""
var zonas: Array = []
var seleccion := 0
var id_perfil := "maxi"

var _ui: Control
var _efectos: Control
var _camino: Control
var _arcoiris: Control
var _nodos_zona: Array = []
var _tarjetas: Array = []
var _titulo_zona: Label
var _anfitriona: TextureRect
var _boton_cometa: Button
var _boton_salir: Button
var _cache_ids := {}
var _tiempo := 0.0
var _lanzando := false
var _siguiente: Array = [-1, -1]
var _avance_bandas := {}
var _salto_coco := 0.0
var _base_coco := Vector2.ZERO
var _id_voces := 0


func _ready() -> void:
	if ruta_mapa == "":
		ruta_mapa = _ruta_por_defecto
	_ruta_por_defecto = ruta_mapa
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.perfil_seleccionado != "":
		id_perfil = progreso.perfil_seleccionado
	if not FileAccess.file_exists(ruta_mapa):
		push_error("mapa_planeta: no existe el mapa %s" % ruta_mapa)
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta_mapa))
	if not datos is Dictionary:
		push_error("mapa_planeta: JSON invalido en %s" % ruta_mapa)
		return
	mapa = datos
	planeta_id = str(mapa.get("planeta_id", ""))
	calcular_estado()
	_construir_ui()
	var clave := _clave()
	var elegida: int = _zona_elegida.get(clave, -1)
	seleccion = elegida if elegida >= 0 and elegida < zonas.size() and zonas[elegida]["abierta"] else zona_sugerida()
	_celebrar_cambios()
	_mostrar_estaciones()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	if _anfitriona != null:
		_anfitriona.position.y = _base_coco.y - _salto_coco - (absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0)
	for nodo in _nodos_zona:
		nodo.queue_redraw()
	for tarjeta in _tarjetas:
		tarjeta.queue_redraw()
	if not _avance_bandas.is_empty():
		_arcoiris.queue_redraw()


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_F4:
		todo_abierto = not todo_abierto
		print("[mapa_planeta] F4 todas las zonas abiertas: %s" % todo_abierto)
		calcular_estado()
		_marcar_visto()
		_reproducir_sfx(SFX_ELEGIR)
		_refrescar()


func _clave() -> String:
	return "%s|%s" % [id_perfil, planeta_id]


# ---------------------------------------------------------------------------
# Estado (derivado de Progreso)
# ---------------------------------------------------------------------------

func calcular_estado() -> void:
	zonas.clear()
	var progreso := get_node_or_null("/root/Progreso")
	for datos_zona: Dictionary in mapa.get("zonas", []):
		var estaciones: Array = []
		var jugables := 0
		var completadas := 0
		for datos_estacion: Dictionary in datos_zona.get("estaciones", []):
			var ruta_nivel := str(datos_estacion.get("niveles", {}).get(id_perfil, ""))
			var escena := str(datos_estacion.get("escena", ""))
			var jugable := ruta_nivel != "" and escena != "" and ResourceLoader.exists(escena) and FileAccess.file_exists(ruta_nivel)
			var id_nivel := _id_nivel(ruta_nivel) if jugable else ""
			var completada := false
			var estrellitas := 0
			if jugable and progreso != null:
				completada = progreso.esta_nivel_completado(id_perfil, planeta_id, id_nivel)
				estrellitas = progreso.obtener_estrellitas_nivel(id_perfil, planeta_id, id_nivel)
			jugables += 1 if jugable else 0
			completadas += 1 if completada else 0
			estaciones.append({"datos": datos_estacion, "juego": str(datos_estacion.get("juego", "")), "jugable": jugable,
				"completada": completada, "estrellitas": estrellitas, "ruta_nivel": ruta_nivel, "escena": escena,
				"perfil_nivel": _perfil_nivel(ruta_nivel) if jugable else ""})
		zonas.append({"datos": datos_zona, "estaciones": estaciones, "jugables": jugables, "completadas": completadas,
			"completa": jugables > 0 and completadas == jugables, "abierta": false,
			"secreta": bool(datos_zona.get("secreta", false))})
	var regla := int(mapa.get("estaciones_para_abrir_siguiente", 2))
	for i in zonas.size():
		var zona: Dictionary = zonas[i]
		if i == 0 or todo_abierto:
			zona["abierta"] = true
			continue
		var anterior: Dictionary = zonas[i - 1]
		if zona["secreta"]:
			zona["abierta"] = anterior["abierta"] and anterior["completa"]
		else:
			zona["abierta"] = anterior["abierta"] and anterior["completadas"] >= mini(regla, anterior["jugables"])


func _id_nivel(ruta: String) -> String:
	if _cache_ids.has(ruta):
		return _cache_ids[ruta]["id"]
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var id := ruta.get_file().get_basename()
	var perfil := ""
	if datos is Dictionary:
		id = str(datos.get("id_nivel", id))
		perfil = str(datos.get("perfil", ""))
	_cache_ids[ruta] = {"id": id, "perfil": perfil}
	return id


func _perfil_nivel(ruta: String) -> String:
	_id_nivel(ruta)
	return _cache_ids[ruta]["perfil"]


## Primera zona abierta con algo pendiente; si todo esta hecho, la ultima abierta.
func zona_sugerida() -> int:
	var ultima := 0
	for i in zonas.size():
		if not zonas[i]["abierta"]:
			continue
		ultima = i
		for estacion in zonas[i]["estaciones"]:
			if estacion["jugable"] and not estacion["completada"]:
				return i
	return ultima


## [zona, estacion] de la siguiente estacion pendiente (primero en la zona elegida) o [-1, -1].
func siguiente_estacion() -> Array:
	var orden: Array = [seleccion]
	for i in zonas.size():
		if i != seleccion:
			orden.append(i)
	for i in orden:
		if not zonas[i]["abierta"]:
			continue
		var estaciones: Array = zonas[i]["estaciones"]
		for j in estaciones.size():
			if estaciones[j]["jugable"] and not estaciones[j]["completada"]:
				return [i, j]
	return [-1, -1]


func _marcar_visto() -> void:
	var abiertas: Array = []
	var completas: Array = []
	for zona in zonas:
		abiertas.append(zona["abierta"])
		completas.append(zona["completa"])
	_visto[_clave()] = {"abiertas": abiertas, "completas": completas}


## Compara con lo ultimo que este hermano vio: el color que vuelve y la zona que despierta se
## celebran con animacion y voz. La primera visita da la bienvenida.
func _celebrar_cambios() -> void:
	var previo: Variant = _visto.get(_clave(), null)
	_marcar_visto()
	var voces: Dictionary = mapa.get("voces", {})
	if previo == null:
		_decir_en_orden([str(voces.get("bienvenida", ""))], 0.5)
		return
	var lista: Array = []
	for i in zonas.size():
		if zonas[i]["completa"] and not previo["completas"][i]:
			for banda in zonas[i]["datos"].get("bandas", []):
				_avance_bandas[banda] = 0.0
			lista.append(str(zonas[i]["datos"].get("voz_completada", "")))
			_despues(0.6, _fiesta_zona.bind(i))
	for i in zonas.size():
		if zonas[i]["abierta"] and not previo["abiertas"][i]:
			seleccion = i
			lista.append(str(voces.get("secreta_revelada" if zonas[i]["secreta"] else "zona_abierta", "")))
			_despues(0.9, _fiesta_zona.bind(i))
	if not lista.is_empty():
		_reproducir_sfx(SFX_FIESTA)
		_decir_en_orden(lista, 0.6)


# ---------------------------------------------------------------------------
# Construccion de la pantalla
# ---------------------------------------------------------------------------

func _construir_ui() -> void:
	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -1
	add_child(capa_fondo)
	var fondo := TextureRect.new()
	var ruta_fondo := str(mapa.get("fondo", ""))
	if ResourceLoader.exists(ruta_fondo):
		fondo.texture = load(ruta_fondo)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var velo := ColorRect.new()
	velo.color = Color(0.23, 0.16, 0.42, 0.38)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var capa := CanvasLayer.new()
	add_child(capa)
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_camino = _control_dibujo(Rect2(0, 0, 1280, 720), _dibujar_camino)
	_arcoiris = _control_dibujo(Rect2(440, 6, 400, 160), _dibujar_arcoiris)

	for i in zonas.size():
		var posicion: Array = zonas[i]["datos"].get("posicion", [200 + i * 220, 300])
		var centro := Vector2(float(posicion[0]), float(posicion[1]))
		var nodo := _control_dibujo(Rect2(centro - Vector2.ONE * 80.0, Vector2.ONE * 160.0), _dibujar_zona.bind(i))
		nodo.mouse_filter = Control.MOUSE_FILTER_STOP
		nodo.pivot_offset = nodo.size / 2.0
		nodo.gui_input.connect(_al_tocar.bind(_tocar_zona.bind(i)))
		nodo.tooltip_text = str(zonas[i]["datos"].get("nombre", ""))
		_nodos_zona.append(nodo)
		var etiqueta := _etiqueta(str(zonas[i]["datos"].get("nombre", "")), 21)
		etiqueta.position = centro + Vector2(-120, RADIO_ZONA + 10.0)
		etiqueta.size = Vector2(240, 34)
		etiqueta.name = "etiqueta_zona_%d" % i
		nodo.set_meta("etiqueta", etiqueta)

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = PANEL_ESTACIONES.position
	panel.size = PANEL_ESTACIONES.size
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.23, 0.16, 0.42, 0.5)
	estilo.border_color = Color(1, 1, 1, 0.45)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(44)
	panel.add_theme_stylebox_override("panel", estilo)
	_ui.add_child(panel)
	_titulo_zona = _etiqueta("", 24)
	_titulo_zona.position = PANEL_ESTACIONES.position + Vector2(0, -2)
	_titulo_zona.size = Vector2(PANEL_ESTACIONES.size.x, 30)
	_titulo_zona.visible = false

	var total := LADO_TARJETA * 4.0 + 18.0 * 3.0
	for j in 4:
		var origen := Vector2(PANEL_ESTACIONES.position.x + (PANEL_ESTACIONES.size.x - total) / 2.0 + j * (LADO_TARJETA + 18.0), PANEL_ESTACIONES.position.y + 20.0)
		var tarjeta := _control_dibujo(Rect2(origen, Vector2.ONE * LADO_TARJETA), _dibujar_tarjeta.bind(j))
		tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
		tarjeta.pivot_offset = tarjeta.size / 2.0
		tarjeta.gui_input.connect(_al_tocar.bind(_tocar_estacion.bind(j)))
		_tarjetas.append(tarjeta)

	var ruta_coco := str(mapa.get("anfitrion", ""))
	_anfitriona = TextureRect.new()
	if ResourceLoader.exists(ruta_coco):
		_anfitriona.texture = load(ruta_coco)
	_anfitriona.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_anfitriona.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anfitriona.position = Vector2(34, 452)
	_anfitriona.size = Vector2(172, 256)
	_anfitriona.pivot_offset = Vector2(86, 256)
	_anfitriona.tooltip_text = "Coco: toca para escuchar de nuevo"
	_anfitriona.gui_input.connect(_al_tocar.bind(_tocar_coco))
	_ui.add_child(_anfitriona)
	_base_coco = _anfitriona.position

	_boton_salir = _boton(Rect2(20, 16, 96, 96), Color("#FFF8EE"), "Volver al mapa estelar")
	var flecha := Control.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_salir.add_child(flecha)
	flecha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flecha.draw.connect(_dibujar_flecha.bind(flecha))
	_boton_salir.pressed.connect(_volver_al_mapa_estelar)

	_boton_cometa = _boton(Rect2(1144, 584, 116, 116), Color("#CFF5F1"), "Cometa: vamos al siguiente juego")
	var retrato_cometa := TextureRect.new()
	if ResourceLoader.exists(RUTA_COMETA):
		retrato_cometa.texture = load(RUTA_COMETA)
	retrato_cometa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato_cometa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato_cometa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_cometa.add_child(retrato_cometa)
	retrato_cometa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retrato_cometa.offset_left = 12
	retrato_cometa.offset_top = 8
	retrato_cometa.offset_right = -12
	retrato_cometa.offset_bottom = -6
	_boton_cometa.pressed.connect(_tocar_cometa)

	_construir_retrato_hermano()
	_efectos = Control.new()
	_efectos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_efectos)
	_efectos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _control_dibujo(rect: Rect2, dibujo: Callable) -> Control:
	var control := Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.position = rect.position
	control.size = rect.size
	control.draw.connect(func() -> void: dibujo.call(control))
	_ui.add_child(control)
	return control


func _etiqueta(texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(RUTA_FUENTE):
		etiqueta.add_theme_font_override("font", load(RUTA_FUENTE))
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", Color("#FFF8EE"))
	etiqueta.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
	etiqueta.add_theme_constant_override("outline_size", 8)
	_ui.add_child(etiqueta)
	return etiqueta


func _boton(rect: Rect2, fondo: Color, ayuda: String) -> Button:
	var boton := Button.new()
	boton.position = rect.position
	boton.size = rect.size
	boton.custom_minimum_size = rect.size
	boton.focus_mode = Control.FOCUS_NONE
	boton.tooltip_text = ayuda
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = fondo.darkened(0.12) if estado == "pressed" else fondo
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(5)
		caja.set_corner_radius_all(64)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
		caja.shadow_offset = Vector2(0, 5)
		caja.shadow_size = 2
		boton.add_theme_stylebox_override(estado, caja)
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	boton.button_down.connect(func() -> void:
		boton.pivot_offset = boton.size / 2.0
		boton.scale = Vector2(0.9, 0.9)
		boton.create_tween().tween_property(boton, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_ui.add_child(boton)
	return boton


## Quien juega, arriba a la derecha: retrato del hermano en un disco de su color.
func _construir_retrato_hermano() -> void:
	var color: Color = COLORES_HERMANO.get(id_perfil, Color.WHITE)
	var disco := _control_dibujo(Rect2(1170, 16, 92, 92), func(control: Control) -> void:
		control.draw_circle(control.size / 2.0, 44.0, Color("#FFF8EE"))
		control.draw_arc(control.size / 2.0, 42.0, 0.0, TAU, 40, color, 7.0, true))
	var retrato := TextureRect.new()
	var ruta: String = RETRATOS_HERMANO.get(id_perfil, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		retrato.texture = load(ruta)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retrato.position = Vector2(12, 8)
	retrato.size = Vector2(68, 68)
	retrato.clip_contents = true
	disco.add_child(retrato)


func _refrescar() -> void:
	for nodo in _nodos_zona:
		nodo.queue_redraw()
	_camino.queue_redraw()
	_arcoiris.queue_redraw()
	_mostrar_estaciones()


func _mostrar_estaciones() -> void:
	_zona_elegida[_clave()] = seleccion
	_siguiente = siguiente_estacion()
	for j in _tarjetas.size():
		_tarjetas[j].visible = j < zonas[seleccion]["estaciones"].size()
		_tarjetas[j].queue_redraw()
	for i in _nodos_zona.size():
		var etiqueta: Label = _nodos_zona[i].get_meta("etiqueta")
		etiqueta.visible = not zonas[i]["secreta"] or zonas[i]["abierta"]
		etiqueta.modulate.a = 1.0 if zonas[i]["abierta"] else 0.6


# ---------------------------------------------------------------------------
# Interaccion
# ---------------------------------------------------------------------------

func _al_tocar(evento: InputEvent, accion: Callable) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		accion.call()


func _tocar_zona(i: int) -> void:
	if _lanzando:
		return
	var nodo: Control = _nodos_zona[i]
	var voces: Dictionary = mapa.get("voces", {})
	if not zonas[i]["abierta"]:
		_reproducir_sfx(SFX_NO)
		_menear(nodo)
		_decir(str(voces.get("secreta_lejana" if zonas[i]["secreta"] else "zona_dormida", "")))
		return
	_reproducir_sfx(SFX_ELEGIR)
	_rebotar(nodo)
	seleccion = i
	_mostrar_estaciones()
	_camino.queue_redraw()
	_decir(str(zonas[i]["datos"].get("voz_llegada", "")))


func _tocar_estacion(j: int) -> void:
	if _lanzando or j >= zonas[seleccion]["estaciones"].size():
		return
	var estacion: Dictionary = zonas[seleccion]["estaciones"][j]
	var tarjeta: Control = _tarjetas[j]
	if not estacion["jugable"]:
		_reproducir_sfx(SFX_NO)
		_menear(tarjeta)
		_decir(str(mapa.get("voces", {}).get("estacion_pronto", "")))
		return
	lanzar_estacion(seleccion, j)


func _tocar_coco() -> void:
	_reproducir_sfx(SFX_TOQUE)
	var tween := create_tween()
	tween.tween_property(self, "_salto_coco", 40.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_salto_coco", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_decir(str(zonas[seleccion]["datos"].get("voz_llegada", "")))


## Cometa lleva directo a la siguiente estacion pendiente (un toque, sin navegar).
func _tocar_cometa() -> void:
	if _lanzando:
		return
	_reproducir_sfx(SFX_TOQUE)
	var voces: Dictionary = mapa.get("voces", {})
	var destino := siguiente_estacion()
	if destino[0] < 0:
		_decir(str(voces.get("todo_listo", "")))
		return
	seleccion = destino[0]
	_mostrar_estaciones()
	_decir(str(voces.get("cometa_vamos", "")))
	lanzar_estacion(destino[0], destino[1], 1.4)


## Abre el motor de una estacion con el contrato de minijuego_base. Al terminar o salir se vuelve a
## este mapa (la escena se recarga y celebra lo que cambio).
func lanzar_estacion(i: int, j: int, espera := 0.0) -> void:
	var estacion: Dictionary = zonas[i]["estaciones"][j]
	if not estacion["jugable"]:
		return
	_lanzando = true
	_zona_elegida[_clave()] = i
	var tarjeta: Control = _tarjetas[j]
	_reproducir_sfx(SFX_ELEGIR)
	var tween := tarjeta.create_tween()
	tween.tween_property(tarjeta, "scale", Vector2(1.12, 0.9), 0.1)
	tween.tween_property(tarjeta, "scale", Vector2.ONE * 1.06, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if espera <= 0.0:
		var juego: Dictionary = mapa.get("juegos", {}).get(estacion["juego"], {})
		_decir(str(juego.get("voz", "")))
		espera = 0.9
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree():
		return
	var escena: PackedScene = load(estacion["escena"])
	var motor: Node = escena.instantiate()
	motor.ruta_nivel = estacion["ruta_nivel"]
	motor.planeta_id = planeta_id
	motor.id_perfil = id_perfil
	var arbol := get_tree()
	var volver := Callable(arbol, "change_scene_to_file").bind(scene_file_path if scene_file_path != "" else "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn")
	motor.completado.connect(volver.unbind(1), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	motor.salir_solicitado.connect(volver, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()
	arbol.root.add_child(motor)
	arbol.current_scene = motor
	queue_free()


func _volver_al_mapa_estelar() -> void:
	_reproducir_sfx(SFX_TOQUE)
	get_tree().change_scene_to_file(RUTA_MAPA_ESTELAR)


# ---------------------------------------------------------------------------
# Voz, sonido y animaciones
# ---------------------------------------------------------------------------

func _decir(ruta: String) -> void:
	_id_voces += 1
	_reproducir_voz(ruta)


func _reproducir_voz(ruta: String) -> void:
	if ruta == "":
		return
	print("[voz:mapa] %s" % ruta)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta if ruta.begins_with("res://") else PREFIJO_AUDIO + ruta)


func _reproducir_sfx(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)


## Varias lineas seguidas (una espera a la otra). Un toque nuevo del nino corta la secuencia.
func _decir_en_orden(rutas: Array, retraso: float) -> void:
	_id_voces += 1
	var id := _id_voces
	await get_tree().create_timer(retraso).timeout
	for ruta in rutas:
		if id != _id_voces or not is_inside_tree():
			return
		_reproducir_voz(str(ruta))
		await get_tree().create_timer(_duracion(str(ruta)) + 0.35).timeout


func _duracion(ruta: String) -> float:
	var final := ruta if ruta.begins_with("res://") else PREFIJO_AUDIO + ruta
	if ruta == "" or not ResourceLoader.exists(final):
		return 0.5
	var stream := load(final) as AudioStream
	return stream.get_length() if stream != null else 0.5


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()


func _rebotar(nodo: Control) -> void:
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "scale", Vector2(1.14, 0.9), 0.08)
	tween.tween_property(nodo, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _menear(nodo: Control) -> void:
	var tween := nodo.create_tween()
	for angulo in [-7.0, 7.0, -4.0, 0.0]:
		tween.tween_property(nodo, "rotation", deg_to_rad(angulo), 0.08)


func _fiesta_zona(i: int) -> void:
	var nodo: Control = _nodos_zona[i]
	nodo.scale = Vector2.ONE * 0.6
	nodo.create_tween().tween_property(nodo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var centro := nodo.position + nodo.size / 2.0
	for k in 12:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = Figura.COLORES_ARCOIRIS[k % Figura.COLORES_ARCOIRIS.size()]
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(22.0, 36.0)
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.position = centro - chispa.size / 2.0
		var destino := chispa.position + Vector2.from_angle(TAU * k / 12.0) * randf_range(90.0, 140.0)
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _centro_zona(i: int) -> Vector2:
	var posicion: Array = zonas[i]["datos"].get("posicion", [0, 0])
	return Vector2(float(posicion[0]), float(posicion[1]))


func _dibujar_camino(control: Control) -> void:
	for i in range(1, zonas.size()):
		if zonas[i]["secreta"] and not zonas[i]["abierta"]:
			continue
		var a := _centro_zona(i - 1)
		var b := _centro_zona(i)
		var control_medio := (a + b) / 2.0 + Vector2(0, 70.0 if i % 2 == 1 else -70.0)
		var color := Color(1, 1, 1, 0.9) if zonas[i]["abierta"] else Color(1, 1, 1, 0.32)
		var pasos := 16
		for k in range(2, pasos - 1):
			var t := k / float(pasos)
			var punto := a.lerp(control_medio, t).lerp(control_medio.lerp(b, t), t)
			control.draw_circle(punto, 7.0, color)


func _dibujar_arcoiris(control: Control) -> void:
	var base := Vector2(200, 150)
	var ancho := 17.0
	var exterior := 136.0
	var encendidas := {}
	for zona in zonas:
		if zona["completa"]:
			for banda in zona["datos"].get("bandas", []):
				encendidas[banda] = true
	for k in BANDAS.size():
		var banda: String = BANDAS[k]
		var radio := exterior - ancho * (k + 0.5)
		control.draw_arc(base, radio, PI, TAU, 48, Color(1, 1, 1, 0.22), ancho, true)
		if encendidas.has(banda):
			var avance := 1.0
			if _avance_bandas.has(banda):
				_avance_bandas[banda] = minf(1.0, _avance_bandas[banda] + get_process_delta_time() / 1.2)
				avance = _avance_bandas[banda]
				if avance >= 1.0:
					_avance_bandas.erase(banda)
			control.draw_arc(base, radio, PI, PI + PI * avance, 48, COLOR_BANDA[banda], ancho + 1.0, true)
	control.draw_arc(base, exterior, PI, TAU, 48, COLOR_CONTORNO, 4.0, true)
	control.draw_arc(base, exterior - ancho * BANDAS.size(), PI, TAU, 48, COLOR_CONTORNO, 4.0, true)
	var medio := exterior - ancho * BANDAS.size() * 0.5
	for lado in [-1.0, 1.0]:
		var c := base + Vector2(lado * medio, -4.0)
		for desfase in [Vector2(-26, 4), Vector2(0, -8), Vector2(26, 4)]:
			control.draw_circle(c + desfase, 22.0, Color.WHITE)
		Figura.dibujar_cara(control, c + Vector2(0, -2), 34.0, encendidas.size() >= BANDAS.size())
	if encendidas.has("brillo"):
		for k in 5:
			var angulo := PI + PI * (k + 0.5) / 5.0
			var punto := base + Vector2.from_angle(angulo) * (exterior + 12.0 + sin(_tiempo * 4.0 + k) * 4.0)
			Figura.dibujar(control, "estrella", COLOR_BANDA["brillo"], punto, 11.0, false)


func _color_zona(i: int) -> Color:
	var bandas: Array = zonas[i]["datos"].get("bandas", ["amarillo"])
	return COLOR_BANDA.get(bandas[0], DORADO)


func _dibujar_zona(control: Control, i: int) -> void:
	var zona: Dictionary = zonas[i]
	var centro := control.size / 2.0
	if zona["secreta"] and not zona["abierta"]:
		# Resplandor lejano en la cima: una promesa, nunca un candado.
		var pulso := 0.5 + 0.5 * sin(_tiempo * 2.2)
		for k in 3:
			control.draw_circle(centro, 30.0 + k * 14.0 + pulso * 6.0, Color(1.0, 0.9, 0.55, 0.16 - k * 0.04))
		Figura.dibujar(control, "estrella", Color("#FFE38A"), centro, 22.0 + pulso * 3.0, false)
		return
	if i == seleccion:
		var color_hermano: Color = COLORES_HERMANO.get(id_perfil, Color.WHITE)
		control.draw_circle(centro, RADIO_ZONA + 13.0, Color(color_hermano, 0.28 + 0.14 * sin(_tiempo * 3.0)))
		control.draw_arc(centro, RADIO_ZONA + 10.0, 0.0, TAU, 48, color_hermano, 6.0, true)
	var color := COLOR_DORMIDA
	if zona["completa"]:
		color = _color_zona(i)
	elif zona["abierta"]:
		color = _color_zona(i).lerp(Color.WHITE, 0.45)
	Figura.dibujar(control, "circulo", color, centro, RADIO_ZONA / 0.9, false)
	var bandas: Array = zona["datos"].get("bandas", [])
	if bandas.size() > 1 and zona["abierta"]:
		var segundo: Color = COLOR_BANDA.get(bandas[1], DORADO)
		control.draw_arc(centro, RADIO_ZONA * 0.72, 0.0, TAU, 40, Color(segundo, 0.9 if zona["completa"] else 0.5), 9.0, true)
	if zona["abierta"]:
		Figura.dibujar_cara(control, centro + Vector2(0, 6), RADIO_ZONA * 0.95, zona["completa"])
	else:
		_dibujar_cara_dormida(control, centro + Vector2(0, 6), RADIO_ZONA * 0.95)
	if zona["completa"]:
		for k in 3:
			var punto := centro + Vector2.from_angle(-PI * 0.8 + k * PI * 0.3) * (RADIO_ZONA + 4.0)
			Figura.dibujar(control, "estrella", DORADO, punto, 12.0 + 2.0 * sin(_tiempo * 3.0 + k), false)
	if zona["abierta"]:
		var estaciones: Array = zona["estaciones"]
		for j in estaciones.size():
			var punto := centro + Vector2.from_angle(PI / 2.0 + (j - (estaciones.size() - 1) / 2.0) * 0.42) * (RADIO_ZONA - 2.0)
			var estacion: Dictionary = estaciones[j]
			if estacion["completada"]:
				Figura.dibujar(control, "estrella", DORADO, punto, 13.0, false)
			elif estacion["jugable"]:
				control.draw_circle(punto, 8.0, Color("#FFF8EE"))
				control.draw_arc(punto, 8.0, 0.0, TAU, 20, COLOR_CONTORNO, 3.0, true)
			else:
				control.draw_circle(punto, 6.0, Color(1, 1, 1, 0.35))


func _dibujar_cara_dormida(lienzo: CanvasItem, centro: Vector2, escala: float) -> void:
	var grosor := maxf(2.0, escala * 0.055)
	for lado in [-1.0, 1.0]:
		var ojo := centro + Vector2(lado * escala * 0.3, -escala * 0.02)
		lienzo.draw_arc(ojo, escala * 0.1, PI * 0.15, PI * 0.85, 10, COLOR_CONTORNO, grosor, true)
	lienzo.draw_circle(centro + Vector2(0, escala * 0.16), escala * 0.06, COLOR_CONTORNO)
	var z := centro + Vector2(escala * 0.52, -escala * 0.55) + Vector2(0, sin(_tiempo * 2.0) * 4.0)
	for k in 2:
		var s := escala * (0.14 - k * 0.04)
		var o := z + Vector2(k * escala * 0.2, -k * escala * 0.22)
		lienzo.draw_polyline(PackedVector2Array([o + Vector2(-s, -s), o + Vector2(s, -s), o + Vector2(-s, s), o + Vector2(s, s)]), Color("#FFF8EE"), grosor * 1.2, true)


func _dibujar_tarjeta(control: Control, j: int) -> void:
	var estaciones: Array = zonas[seleccion]["estaciones"]
	if j >= estaciones.size():
		return
	var estacion: Dictionary = estaciones[j]
	var lado := control.size
	var es_siguiente: bool = _siguiente[0] == seleccion and _siguiente[1] == j
	var caja := StyleBoxFlat.new()
	caja.set_corner_radius_all(36)
	caja.anti_aliasing = true
	if estacion["jugable"]:
		caja.bg_color = Color("#FFF3C4") if estacion["completada"] else Color("#FFF8EE")
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(5)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.35)
		caja.shadow_offset = Vector2(0, 6)
		caja.shadow_size = 3
	else:
		caja.bg_color = Color(1, 1, 1, 0.26)
		caja.border_color = Color(1, 1, 1, 0.5)
		caja.set_border_width_all(4)
	control.draw_style_box(caja, Rect2(Vector2.ZERO, lado))
	if es_siguiente:
		var brillo := StyleBoxFlat.new()
		brillo.draw_center = false
		brillo.set_corner_radius_all(40)
		brillo.border_color = Color(DORADO, 0.55 + 0.45 * sin(_tiempo * 4.0))
		brillo.set_border_width_all(8)
		brillo.expand_margin_left = 6
		brillo.expand_margin_right = 6
		brillo.expand_margin_top = 6
		brillo.expand_margin_bottom = 6
		control.draw_style_box(brillo, Rect2(Vector2.ZERO, lado))
	var centro_icono := Vector2(lado.x / 2.0, lado.y * 0.43)
	_dibujar_icono(control, estacion["juego"], centro_icono, 56.0, estacion["jugable"])
	var abajo := Vector2(lado.x / 2.0, lado.y - 30.0)
	if estacion["completada"]:
		Figura.dibujar(control, "estrella", DORADO, Vector2(lado.x - 30.0, 30.0), 24.0, true, true)
		if estacion["perfil_nivel"] == "estrella":
			for k in 3:
				var color := DORADO if k < int(estacion["estrellitas"]) else Color(COLOR_CONTORNO, 0.18)
				Figura.dibujar(control, "estrella", color, abajo + Vector2((k - 1) * 34.0, 0), 15.0, false)
		else:
			_dibujar_triangulo_jugar(control, abajo, 16.0)
	elif estacion["jugable"]:
		_dibujar_triangulo_jugar(control, abajo, 18.0)
	else:
		for k in 3:
			control.draw_circle(abajo + Vector2((k - 1) * 22.0, 0), 6.0, Color(1, 1, 1, 0.6))


func _dibujar_triangulo_jugar(control: Control, centro: Vector2, radio: float) -> void:
	control.draw_circle(centro, radio * 1.35, TURQUESA)
	control.draw_arc(centro, radio * 1.35, 0.0, TAU, 28, COLOR_CONTORNO, 3.5, true)
	var puntos := PackedVector2Array([centro + Vector2(-radio * 0.45, -radio * 0.7), centro + Vector2(radio * 0.75, 0), centro + Vector2(-radio * 0.45, radio * 0.7)])
	control.draw_colored_polygon(puntos, Color("#FFF8EE"))


## Iconos universales de cada minijuego (sin texto, GDD §6 regla 3).
func _dibujar_icono(control: Control, juego: String, centro: Vector2, radio: float, activo: bool) -> void:
	var tono := func(color: Color) -> Color: return color if activo else Color(color.lerp(Color("#9A96AD"), 0.75), 0.7)
	match juego:
		"lluvia":
			Figura.dibujar(control, "gota", tono.call(Color("#6FD6E8")), centro + Vector2(0, 6), radio * 0.9, activo)
			Figura.dibujar(control, "gota", tono.call(Color("#FF6B6B")), centro + Vector2(-radio * 0.95, -radio * 0.5), radio * 0.35, false)
			Figura.dibujar(control, "gota", tono.call(Color("#FFCB3D")), centro + Vector2(radio * 0.95, -radio * 0.35), radio * 0.3, false)
		"formas":
			Figura.dibujar(control, "triangulo", tono.call(Color("#7DD87A")), centro + Vector2(-radio * 0.5, -radio * 0.35), radio * 0.62, activo)
			Figura.dibujar(control, "cuadrado", tono.call(Color("#4A8BE0")), centro + Vector2(radio * 0.55, -radio * 0.2), radio * 0.52, false)
			Figura.dibujar(control, "circulo", tono.call(Color("#FF6B6B")), centro + Vector2(0, radio * 0.6), radio * 0.46, false)
		"parejas":
			for k in 2:
				var desfase := Vector2((k - 0.5) * radio * 0.8, (0.5 - k) * radio * 0.1)
				var carta := PackedVector2Array()
				var angulo := deg_to_rad(-12.0 if k == 0 else 10.0)
				for p in [Vector2(-0.55, -0.75), Vector2(0.55, -0.75), Vector2(0.55, 0.75), Vector2(-0.55, 0.75)]:
					carta.append(centro + desfase + (p * radio).rotated(angulo))
				control.draw_colored_polygon(carta, tono.call(Color("#B48CE8") if k == 0 else Color("#FFF8EE")))
				Figura.contornear(control, carta, 4.0)
				Figura.dibujar(control, "corazon" if k == 0 else "estrella", tono.call(Color("#F26CA8") if k == 0 else Color("#FFCB3D")), centro + desfase, radio * 0.3, false)
		"pinta":
			var paleta := PackedVector2Array()
			for k in 32:
				var a := TAU * k / 32.0
				paleta.append(centro + Vector2(cos(a) * radio * 1.0, sin(a) * radio * 0.72))
			control.draw_colored_polygon(paleta, tono.call(Color("#F2D3A6")))
			Figura.contornear(control, paleta, 4.0)
			var colores := [Color("#FF6B6B"), Color("#FFCB3D"), Color("#7DD87A"), Color("#4A8BE0")]
			for k in colores.size():
				control.draw_circle(centro + Vector2(-radio * 0.5 + k * radio * 0.33, -radio * 0.2 + (k % 2) * radio * 0.3), radio * 0.15, tono.call(colores[k]))
			control.draw_line(centro + Vector2(radio * 0.3, radio * 0.75), centro + Vector2(radio * 1.0, -radio * 0.45), tono.call(Color("#B07A4F")), 9.0, true)
		_:
			Figura.dibujar(control, "estrella", tono.call(DORADO), centro, radio * 0.8, activo)


func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-26, 0), Vector2(2, -26), Vector2(2, -12), Vector2(26, -12), Vector2(26, 12), Vector2(2, 12), Vector2(2, 26)]:
		puntos.append(c + p * k)
	icono.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(icono, puntos, 5.0 * k)
