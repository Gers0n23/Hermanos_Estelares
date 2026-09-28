extends Node2D

## Album de recuerdos "Las migas de papa" (docs/fichas/album-recuerdos.md §7, HE-46).
##
## Se abre desde la seleccion de personaje con el boton libro-album; cualquiera lo mira, sin
## elegir perfil antes. Tres vistas, todo por iconos y voz (GDD §6, sin texto obligatorio):
## - PORTADA: 4 tapas grandes (Maxi, Nicole, Sofia y Familia) con la cara de cada uno.
## - PAGINA: cuadricula de 2x3 polaroids (>=200x238 px, ficha: >180) en orden de edad. Se pasa
##   de pagina con flechas grandes o deslizando. Los huecos son marcos con estrella y "?": al
##   tocarlos Cometa da la pista (si su linea ya esta grabada; si no, animacion sola).
## - FOTO ABIERTA: grande, vuelve a sonar la voz de la familia; boton grande de cerrar.
## Las fotos nuevas brillan la primera vez que se ven en su pagina y quedan marcadas como vistas.
##
## Data-driven: todo sale de `Recuerdos` (catalogo) y `Progreso` (encontrados). No conoce
## planetas ni minijuegos.

const FotoRecuerdo := preload("res://scripts/ui/foto_recuerdo.gd")
const BotonAlbum := preload("res://scripts/ui/boton_album.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const RUTA_SELECCION := "res://escenas/nucleo/seleccion_personaje.tscn"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_ABRIR := "res://assets/audio/sfx/ui/abrir.ogg"
const SFX_CERRAR := "res://assets/audio/sfx/ui/cerrar.ogg"
const SFX_PAGINA := "res://assets/audio/sfx/ui/seleccionar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const COLOR_PAPEL := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const ALBUMES := ["maxi", "nicole", "sofia", "familia"]
const RETRATOS := {
	"maxi": "res://assets/sprites/personajes/maxi_base.png",
	"nicole": "res://assets/sprites/personajes/nicole_base.png",
	"sofia": "res://assets/sprites/personajes/sofia_base.png",
}
const RECORTE_CARA := Rect2(146, 62, 220, 220)
const TAM_TAPA := Vector2(250, 340)
const TAM_CELDA := Vector2(200, 238)
const POR_PAGINA := 6
const DESLIZAR_MIN := 90.0

var album_abierto := ""
var pagina := 0
var vista := "portada"   # portada | pagina | foto

var _ui: Control
var _capa_portada: Control
var _capa_pagina: Control
var _capa_foto: Control
var _boton_volver: Control
var _flecha_izq: Control
var _flecha_der: Control
var _tapas: Dictionary = {}
var _celdas: Array = []
var _foto_grande: Control
var _recuerdo_abierto: Dictionary = {}
var _fuente: Font
var _tiempo := 0.0
var _toque_inicio := Vector2.INF
var _caras: Dictionary = {}


func _ready() -> void:
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	for id in RETRATOS:
		if ResourceLoader.exists(RETRATOS[id]):
			_caras[id] = load(RETRATOS[id])
	_construir()
	mostrar_portada()
	_decir(_recuerdos().elegir_linea("album_invitacion") if _recuerdos() != null else "")


func _recuerdos() -> Node:
	return get_node_or_null("/root/Recuerdos")


func _process(delta: float) -> void:
	_tiempo += delta
	_boton_volver.queue_redraw()
	if vista == "portada":
		for tapa in _tapas.values():
			tapa.queue_redraw()


# ---------------------------------------------------------------------------
# Construccion
# ---------------------------------------------------------------------------

func _construir() -> void:
	_ui = Control.new()
	_ui.name = "ui"
	_ui.size = Vector2(1280, 720)
	_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_ui)
	_ui.gui_input.connect(_al_deslizar)

	_capa_portada = _capa("portada")
	var x0 := (1280.0 - (TAM_TAPA.x * 4.0 + 40.0 * 3.0)) / 2.0
	for i in ALBUMES.size():
		var album: String = ALBUMES[i]
		var tapa := _control(_capa_portada, Rect2(Vector2(x0 + i * (TAM_TAPA.x + 40.0), 210), TAM_TAPA), _dibujar_tapa.bind(album))
		tapa.name = "tapa_%s" % album
		tapa.tooltip_text = "Álbum de %s" % album.capitalize()
		tapa.gui_input.connect(_al_tocar.bind(abrir_album.bind(album)))
		_tapas[album] = tapa
	var libro := _control(_capa_portada, Rect2(560, 40, 160, 140), func(c: Control) -> void:
		BotonAlbum.dibujar_libro(c, c.size / 2.0, 130.0, _tiempo))
	libro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_capa_pagina = _capa("pagina")
	var cabecera := _control(_capa_pagina, Rect2(580, 10, 120, 120), _dibujar_cabecera)
	cabecera.name = "cabecera"
	cabecera.gui_input.connect(_al_tocar.bind(_tocar_cabecera))
	for k in POR_PAGINA:
		var columna := k % 3
		var fila := k / 3
		var centro := Vector2(640.0 + (columna - 1) * 270.0, 268.0 + fila * 290.0)
		var celda: Control = FotoRecuerdo.new()
		celda.name = "celda_%d" % k
		celda.size = TAM_CELDA
		celda.position = centro - TAM_CELDA / 2.0
		celda.pivot_offset = TAM_CELDA / 2.0
		_capa_pagina.add_child(celda)
		celda.mouse_filter = Control.MOUSE_FILTER_STOP
		celda.gui_input.connect(_al_tocar.bind(_tocar_celda.bind(k)))
		_celdas.append(celda)
	_flecha_izq = _boton(_capa_pagina, Rect2(40, 300, 120, 120), Color("#FFF8EE"), _dibujar_flecha.bind(-1.0), pasar_pagina.bind(-1))
	_flecha_izq.name = "flecha_izq"
	_flecha_der = _boton(_capa_pagina, Rect2(1120, 300, 120, 120), Color("#FFF8EE"), _dibujar_flecha.bind(1.0), pasar_pagina.bind(1))
	_flecha_der.name = "flecha_der"

	_boton_volver = _boton(_ui, Rect2(24, 20, 112, 112), Color("#FFF8EE"), _dibujar_volver, volver)
	_boton_volver.name = "boton_volver"

	_capa_foto = _capa("foto")
	var velo := ColorRect.new()
	velo.color = Color(0.08, 0.04, 0.2, 0.82)
	velo.size = Vector2(1280, 720)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa_foto.add_child(velo)
	_foto_grande = FotoRecuerdo.new()
	_foto_grande.name = "foto_grande"
	_foto_grande.size = Vector2(560, 666)
	_foto_grande.position = Vector2(640, 360) - _foto_grande.size / 2.0
	_foto_grande.pivot_offset = _foto_grande.size / 2.0
	_foto_grande.ajuste_foto_real = "contener"
	_capa_foto.add_child(_foto_grande)
	_foto_grande.mouse_filter = Control.MOUSE_FILTER_STOP
	_foto_grande.gui_input.connect(_al_tocar.bind(_repetir_voz))
	var cerrar := _boton(_capa_foto, Rect2(1136, 24, 120, 120), Color("#FFF8EE"), _dibujar_cerrar, cerrar_foto)
	cerrar.name = "boton_cerrar"


func _capa(nombre: String) -> Control:
	var capa := Control.new()
	capa.name = nombre
	capa.size = Vector2(1280, 720)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(capa)
	return capa


func _control(padre: Control, rect: Rect2, dibujo: Callable) -> Control:
	var control := Control.new()
	control.position = rect.position
	control.size = rect.size
	control.pivot_offset = rect.size / 2.0
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.draw.connect(func() -> void: dibujo.call(control))
	padre.add_child(control)
	return control


## Boton redondo grande (>=112 px) con icono dibujado; rebota al tocarlo.
func _boton(padre: Control, rect: Rect2, fondo: Color, icono: Callable, accion: Callable) -> Control:
	var boton := _control(padre, rect, func(c: Control) -> void:
		var centro := c.size / 2.0
		var radio := c.size.x / 2.0 - 4.0
		c.draw_circle(centro + Vector2(0, 5), radio, Color(COLOR_CONTORNO, 0.3))
		c.draw_circle(centro, radio, fondo)
		c.draw_arc(centro, radio, 0.0, TAU, 48, COLOR_CONTORNO, 5.0, true)
		icono.call(c))
	boton.gui_input.connect(_al_tocar.bind(accion))
	return boton


# ---------------------------------------------------------------------------
# Vistas
# ---------------------------------------------------------------------------

func mostrar_portada() -> void:
	vista = "portada"
	album_abierto = ""
	_capa_portada.show()
	_capa_pagina.hide()
	_capa_foto.hide()
	for tapa in _tapas.values():
		tapa.queue_redraw()


func abrir_album(album: String) -> void:
	_sfx(SFX_ABRIR)
	var tapa: Control = _tapas.get(album)
	if tapa != null:
		_rebotar(tapa)
	album_abierto = album
	pagina = 0
	vista = "pagina"
	_capa_portada.hide()
	_capa_pagina.show()
	_capa_foto.hide()
	_llenar_pagina()
	var recuerdos := _recuerdos()
	if recuerdos == null:
		return
	if recuerdos.contar(album)[0] == 0 and recuerdos.recuerdos_album(album).is_empty():
		_decir(recuerdos.elegir_linea("album_vacio"))
	else:
		_decir(recuerdos.elegir_linea("tapa", album))


func paginas() -> int:
	var recuerdos := _recuerdos()
	if recuerdos == null or album_abierto == "":
		return 1
	return maxi(1, ceili(recuerdos.recuerdos_album(album_abierto).size() / float(POR_PAGINA)))


func pasar_pagina(direccion: int) -> void:
	var nueva := clampi(pagina + direccion, 0, paginas() - 1)
	if nueva == pagina:
		_menear(_flecha_der if direccion > 0 else _flecha_izq)
		return
	_sfx(SFX_PAGINA)
	pagina = nueva
	_llenar_pagina()
	for celda: Control in _celdas:
		celda.position.x += 80.0 * direccion
		celda.modulate.a = 0.0
		var tween := celda.create_tween().set_parallel(true)
		tween.tween_property(celda, "position:x", celda.position.x - 80.0 * direccion, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(celda, "modulate:a", 1.0, 0.2)


func _llenar_pagina() -> void:
	var recuerdos := _recuerdos()
	var lista: Array = recuerdos.recuerdos_album(album_abierto) if recuerdos != null else []
	for k in POR_PAGINA:
		var indice := pagina * POR_PAGINA + k
		var celda: Control = _celdas[k]
		if indice >= lista.size():
			celda.hide()
			celda.set_meta("recuerdo", {})
			continue
		var rec: Dictionary = lista[indice]
		var id := str(rec["id"])
		var encontrado: bool = recuerdos.esta_encontrado(id)
		celda.show()
		celda.set_meta("recuerdo", rec)
		celda.configurar(rec, not encontrado)
		var info: Dictionary = recuerdos.info_encontrado(id)
		celda.nuevo = encontrado and not info.get("visto", false)
		if celda.nuevo:
			recuerdos.marcar_visto(id)
	var varias := paginas() > 1
	_flecha_izq.visible = varias
	_flecha_der.visible = varias
	_flecha_izq.modulate.a = 0.45 if pagina == 0 else 1.0
	_flecha_der.modulate.a = 0.45 if pagina >= paginas() - 1 else 1.0
	_capa_pagina.get_node("cabecera").queue_redraw()


func abrir_foto(rec: Dictionary) -> void:
	_sfx(SFX_ABRIR)
	_recuerdo_abierto = rec
	vista = "foto"
	_capa_foto.show()
	_foto_grande.configurar(rec, false)
	_foto_grande.scale = Vector2(0.3, 0.3)
	_foto_grande.create_tween().tween_property(_foto_grande, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_repetir_voz(false)


func cerrar_foto() -> void:
	_sfx(SFX_CERRAR)
	_detener_voz()
	vista = "pagina"
	_capa_foto.hide()
	_recuerdo_abierto = {}


## Boton volver: de la foto a la pagina, de la pagina a la portada, de la portada a la seleccion.
func volver() -> void:
	match vista:
		"foto":
			cerrar_foto()
		"pagina":
			_sfx(SFX_CERRAR)
			_detener_voz()
			mostrar_portada()
		_:
			_sfx(SFX_CERRAR)
			_detener_voz()
			get_tree().change_scene_to_file(RUTA_SELECCION)


# ---------------------------------------------------------------------------
# Interaccion
# ---------------------------------------------------------------------------

func _al_tocar(evento: InputEvent, accion: Callable) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_toque_inicio = evento.global_position
			get_viewport().set_input_as_handled()
			accion.call()


## Deslizar en la pagina (sobre el fondo) pasa de pagina.
func _al_deslizar(evento: InputEvent) -> void:
	if vista != "pagina" or not evento is InputEventMouseButton or evento.button_index != MOUSE_BUTTON_LEFT:
		return
	if evento.pressed:
		_toque_inicio = evento.position
	elif _toque_inicio != Vector2.INF:
		var dx: float = evento.position.x - _toque_inicio.x
		_toque_inicio = Vector2.INF
		if absf(dx) >= DESLIZAR_MIN:
			pasar_pagina(-1 if dx > 0 else 1)


func _tocar_celda(k: int) -> void:
	if vista != "pagina":
		return
	var celda: Control = _celdas[k]
	var rec: Dictionary = celda.get_meta("recuerdo", {})
	if rec.is_empty():
		return
	var recuerdos := _recuerdos()
	if recuerdos != null and recuerdos.esta_encontrado(str(rec["id"])):
		_rebotar(celda)
		abrir_foto(rec)
	else:
		# hueco: pista de Cometa (si esta grabada) + meneo; nunca un "no"
		_sfx(SFX_TOQUE)
		_menear(celda)
		if recuerdos != null:
			_decir(recuerdos.ruta_pista(rec))


func _tocar_cabecera() -> void:
	_sfx(SFX_TOQUE)
	_rebotar(_capa_pagina.get_node("cabecera"))
	var recuerdos := _recuerdos()
	if recuerdos != null:
		_decir(recuerdos.elegir_linea("tapa", album_abierto))


## Tocar la foto abierta repite su voz.
func _repetir_voz(con_sonido := true) -> void:
	if _recuerdo_abierto.is_empty():
		return
	if con_sonido:
		_rebotar(_foto_grande, 1.03)
	var recuerdos := _recuerdos()
	var audio := get_node_or_null("/root/Audio")
	if recuerdos == null or audio == null:
		return
	var stream: AudioStream = recuerdos.stream_voz(_recuerdo_abierto)
	if stream != null:
		audio.reproducir_voz_stream(stream)
	else:
		_decir(recuerdos.elegir_linea("generica"))


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _dibujar_tapa(c: Control, album: String) -> void:
	var recuerdos := _recuerdos()
	var color: Color = recuerdos.color_album(album) if recuerdos != null else DORADO
	var lado := c.size
	var nuevos: bool = recuerdos != null and recuerdos.album_tiene_nuevos(album)
	if nuevos:
		var brillo := StyleBoxFlat.new()
		brillo.bg_color = Color(DORADO, 0.3 + 0.25 * sin(_tiempo * 4.0))
		brillo.set_corner_radius_all(40)
		for lado_margen in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			brillo.set_expand_margin(lado_margen, 12.0)
		c.draw_style_box(brillo, Rect2(Vector2.ZERO, lado))
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(34)
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(6)
	caja.shadow_color = Color(COLOR_CONTORNO, 0.35)
	caja.shadow_offset = Vector2(0, 8)
	caja.shadow_size = 3
	c.draw_style_box(caja, Rect2(Vector2.ZERO, lado))
	# lomo del album
	c.draw_rect(Rect2(14, 16, 18, lado.y - 32), color.darkened(0.25))
	var centro := Vector2(lado.x / 2.0 + 8.0, 130.0)
	c.draw_circle(centro, 92.0, COLOR_PAPEL)
	c.draw_arc(centro, 92.0, 0.0, TAU, 48, COLOR_CONTORNO, 5.0, true)
	if album == "familia":
		for p in [["maxi", Vector2(-46, 22), 62.0], ["sofia", Vector2(46, 18), 70.0], ["nicole", Vector2(0, -26), 66.0]]:
			_dibujar_cara(c, str(p[0]), centro + (p[1] as Vector2), float(p[2]))
		Figura.dibujar(c, "corazon", Color("#F26CA8"), centro + Vector2(0, 58), 18.0, false)
	else:
		_dibujar_cara(c, album, centro, 150.0)
	# progreso sin numeros: una estrellita por foto visible (llena = encontrada)
	if recuerdos != null:
		var visibles: Array = recuerdos.recuerdos_album(album)
		var n := visibles.size()
		var por_fila := 7
		for k in n:
			var fila := k / por_fila
			var en_fila := mini(por_fila, n - fila * por_fila)
			var x := lado.x / 2.0 + 8.0 + (k % por_fila - (en_fila - 1) / 2.0) * 28.0
			var y := 262.0 + fila * 30.0
			var encontrado: bool = recuerdos.esta_encontrado(str(visibles[k]["id"]))
			Figura.dibujar(c, "estrella", DORADO if encontrado else Color(COLOR_PAPEL, 0.45), Vector2(x, y), 12.0, false)
	if nuevos:
		Figura.dibujar(c, "estrella", DORADO, Vector2(lado.x - 22, 22), 26.0 + 3.0 * sin(_tiempo * 6.0), false)


func _dibujar_cara(c: Control, id: String, centro: Vector2, tam: float) -> void:
	var textura: Texture2D = _caras.get(id)
	if textura == null:
		Figura.dibujar(c, "estrella", DORADO, centro, tam * 0.4, true)
		return
	c.draw_texture_rect_region(textura, Rect2(centro - Vector2.ONE * tam / 2.0, Vector2.ONE * tam), RECORTE_CARA)


func _dibujar_cabecera(c: Control) -> void:
	var recuerdos := _recuerdos()
	var color: Color = recuerdos.color_album(album_abierto) if recuerdos != null else DORADO
	var centro := c.size / 2.0
	c.draw_circle(centro + Vector2(0, 5), 56.0, Color(COLOR_CONTORNO, 0.3))
	c.draw_circle(centro, 56.0, color)
	c.draw_arc(centro, 56.0, 0.0, TAU, 40, COLOR_CONTORNO, 5.0, true)
	if album_abierto == "familia":
		_dibujar_cara(c, "maxi", centro + Vector2(-26, 10), 52.0)
		_dibujar_cara(c, "sofia", centro + Vector2(26, 8), 56.0)
		_dibujar_cara(c, "nicole", centro + Vector2(0, -14), 54.0)
	else:
		_dibujar_cara(c, album_abierto, centro, 96.0)
	# puntitos de pagina
	var total := paginas()
	for k in total:
		var p := Vector2(centro.x + (k - (total - 1) / 2.0) * 22.0, c.size.y - 4.0)
		c.draw_circle(p, 7.0, DORADO if k == pagina else Color(1, 1, 1, 0.5))


func _dibujar_flecha(c: Control, direccion: float) -> void:
	var centro := c.size / 2.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-28, -12), Vector2(0, -12), Vector2(0, -32), Vector2(32, 0), Vector2(0, 32), Vector2(0, 12), Vector2(-28, 12)]:
		puntos.append(centro + Vector2(p.x * direccion, p.y))
	c.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(c, puntos, 5.0)


func _dibujar_volver(c: Control) -> void:
	# casa si vuelve a la seleccion, flecha si vuelve dentro del album
	var centro := c.size / 2.0
	if vista == "portada":
		var casa := PackedVector2Array([centro + Vector2(-30, -2), centro + Vector2(0, -32), centro + Vector2(30, -2),
			centro + Vector2(22, -2), centro + Vector2(22, 28), centro + Vector2(-22, 28), centro + Vector2(-22, -2)])
		c.draw_colored_polygon(casa, Color("#FF9F4A"))
		Figura.contornear(c, casa, 5.0)
		c.draw_rect(Rect2(centro + Vector2(-8, 8), Vector2(16, 20)), COLOR_CONTORNO)
	else:
		_dibujar_flecha(c, -1.0)


func _dibujar_cerrar(c: Control) -> void:
	var centro := c.size / 2.0
	for angulo in [PI / 4.0, -PI / 4.0]:
		var d := Vector2.from_angle(angulo) * 28.0
		c.draw_line(centro - d, centro + d, COLOR_CONTORNO, 18.0, true)
		c.draw_line(centro - d, centro + d, Color("#FF6B6B"), 10.0, true)


# ---------------------------------------------------------------------------
# Sonido y animaciones
# ---------------------------------------------------------------------------

func _decir(ruta: String) -> void:
	if ruta == "":
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta)


func _detener_voz() -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()


func _sfx(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)
	if _boton_volver != null:
		_boton_volver.queue_redraw()


func _rebotar(nodo: Control, fuerza := 1.12) -> void:
	nodo.pivot_offset = nodo.size / 2.0
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "scale", Vector2(fuerza, 2.0 - fuerza), 0.08)
	tween.tween_property(nodo, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _menear(nodo: Control) -> void:
	var tween := nodo.create_tween()
	for angulo in [-7.0, 7.0, -4.0, 0.0]:
		tween.tween_property(nodo, "rotation", deg_to_rad(angulo), 0.08)
