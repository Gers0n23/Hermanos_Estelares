extends Node2D

## Album de recuerdos "Las migas de papa" (docs/fichas/album-recuerdos.md §7, HE-46).
##
## Se abre desde la seleccion de personaje con el boton libro-album; cualquiera lo mira, sin
## elegir perfil antes. Tres vistas, todo por iconos y voz (GDD §6, sin texto obligatorio):
## - PORTADA: cuatro albumes apilados (Maxi, Nicole, Sofia y Familia). Cada tapa tiene la cara,
##   el nombre y cuantas fotos hay encontradas en numeros. Sin estrellas.
## - DOBLE PAGINA: el album abierto. Dos paginas con 4 polaroids cada una (8 por vista). Se pasa
##   de vista con flechas (chevron) o deslizando. Los huecos son marcos con estrella y "?": al
##   tocarlos Cometa da la pista (si su linea ya esta grabada; si no, animacion sola).
## - FOTO ABIERTA: grande, vuelve a sonar la voz de la familia; boton grande de cerrar.
## Las fotos nuevas brillan la primera vez que se ven en su pagina y quedan marcadas como vistas.
##
## Data-driven: todo sale de `Recuerdos` (catalogo) y `Progreso` (encontrados). No conoce
## planetas ni minijuegos.
##
## UX HE-44 (03-Oct-2026, PROVISIONAL):
## - R6: las fotos rebotan al presionar pero actuan al SOLTAR: si el dedo casi no se movio, abren la
##   foto; si se deslizo, pasan de pagina.
## - R10: boton de Cometa de 116 px abajo a la derecha, como en los minijuegos: repite la instruccion.
##
## UX (21-Nov-2026, PO): sin icono de libro arriba en la portada; el boton de volver a los albumes
## es un estante de portadas (no una flecha) para que no se confunda con las flechas de pagina.

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
const NOMBRES := {"maxi": "Maxi", "nicole": "Nicole", "sofia": "Sofía", "familia": "Familia"}
## Inclinacion de cada album en la pila de la portada (grados): que parezcan puestos a mano.
const ANGULOS := [-2.0, 1.5, -1.0, 2.5]
const RETRATOS := {
	"maxi": "res://assets/sprites/personajes/maxi_base.png",
	"nicole": "res://assets/sprites/personajes/nicole_base.png",
	"sofia": "res://assets/sprites/personajes/sofia_base.png",
}
## Encuadre de la cabeza (casco, pelo y mentón) en el retrato de 512×768. Se recorta en círculo.
## Igual que `recorte_retrato` de datos/recuerdos/catalogo.json.
const RECORTE_CARA := Rect2(122, 44, 268, 268)
const TAM_TAPA := Vector2(230, 310)
const TAM_CELDA := Vector2(200, 238)
## Doble pagina: 4 fotos por pagina, dos paginas por vista.
const POR_PAGINA := 8
const DESLIZAR_MIN := 90.0
const TOQUE_MAX := 20.0
const RUTA_COMETA := "res://assets/sprites/personajes/cometa_base.png"

var _id_voz_foto := 0
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
var _boton_cometa: Control
var _textura_cometa: Texture2D


func _ready() -> void:
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	if ResourceLoader.exists(RUTA_COMETA):
		_textura_cometa = load(RUTA_COMETA)
	for id in RETRATOS:
		if ResourceLoader.exists(RETRATOS[id]):
			_caras[id] = load(RETRATOS[id])
	# Modo dios: se ven todas las fotos y huecos del album para revisarlo (solo en su guardado).
	if _recuerdos() != null:
		_recuerdos().conceder_todos_modo_dios()
	_construir()
	mostrar_portada()
	_decir(_recuerdos().elegir_linea("album_invitacion") if _recuerdos() != null else "")


func _recuerdos() -> Node:
	return get_node_or_null("/root/Recuerdos")


func _process(delta: float) -> void:
	_tiempo += delta
	_boton_volver.queue_redraw()
	_boton_cometa.queue_redraw()
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
	for i in ALBUMES.size():
		var album: String = ALBUMES[i]
		var centro_x := 640.0 + (i - 1.5) * 260.0
		var y := 200.0 + (6.0 if i % 2 == 1 else -4.0)
		var tapa := _control(_capa_portada, Rect2(Vector2(centro_x - TAM_TAPA.x / 2.0, y), TAM_TAPA), _dibujar_tapa.bind(album))
		tapa.name = "tapa_%s" % album
		tapa.rotation = deg_to_rad(ANGULOS[i])
		tapa.tooltip_text = "Álbum de %s" % NOMBRES[album]
		tapa.gui_input.connect(_al_tocar.bind(abrir_album.bind(album)))
		_tapas[album] = tapa

	_capa_pagina = _capa("pagina")
	# Album abierto (doble pagina): es el primer hijo, se dibuja debajo de todo lo demas.
	var hoja := _control(_capa_pagina, Rect2(160, 140, 960, 575), _dibujar_hoja)
	hoja.name = "hoja"
	hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cabecera := _control(_capa_pagina, Rect2(580, 10, 120, 120), _dibujar_cabecera)
	cabecera.name = "cabecera"
	cabecera.gui_input.connect(_al_tocar.bind(_tocar_cabecera))
	for k in POR_PAGINA:
		# k 0-3: pagina izquierda; 4-7: pagina derecha. Dos columnas por pagina.
		var lado_pagina := (k / 4) % 2
		var i := k % 4
		var columna := i % 2
		var fila := i / 2
		var x_pagina := 400.0 if lado_pagina == 0 else 880.0
		var centro := Vector2(x_pagina + (columna * 2 - 1) * 115.0, 310.0 + fila * 260.0)
		var celda: Control = FotoRecuerdo.new()
		celda.name = "celda_%d" % k
		celda.size = TAM_CELDA
		celda.position = centro - TAM_CELDA / 2.0
		celda.pivot_offset = TAM_CELDA / 2.0
		_capa_pagina.add_child(celda)
		celda.mouse_filter = Control.MOUSE_FILTER_STOP
		celda.gui_input.connect(_al_tocar_celda.bind(k))
		_celdas.append(celda)
	_flecha_izq = _boton(_capa_pagina, Rect2(24, 300, 120, 120), COLOR_PAPEL, _dibujar_flecha.bind(-1.0), pasar_pagina.bind(-1))
	_flecha_izq.name = "flecha_izq"
	_flecha_der = _boton(_capa_pagina, Rect2(1136, 300, 120, 120), COLOR_PAPEL, _dibujar_flecha.bind(1.0), pasar_pagina.bind(1))
	_flecha_der.name = "flecha_der"

	_boton_volver = _boton(_ui, Rect2(24, 20, 112, 112), COLOR_PAPEL, _dibujar_volver, volver)
	_boton_volver.name = "boton_volver"
	_boton_cometa = _boton(_ui, Rect2(1144, 584, 116, 116), Color("#CFF5F1"), _dibujar_cometa, repetir_instruccion)
	_boton_cometa.name = "boton_cometa"

	_capa_foto = _capa("foto")
	var velo := ColorRect.new()
	velo.color = Color(0.08, 0.04, 0.2, 0.82)
	velo.size = Vector2(1280, 720)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	# UX HE-44 R5: tocar fuera de la foto la cierra (nunca un toque muerto).
	velo.gui_input.connect(_al_tocar.bind(cerrar_foto))
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
	var cerrar := _boton(_capa_foto, Rect2(1136, 24, 120, 120), COLOR_PAPEL, _dibujar_cerrar, cerrar_foto)
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
	_capa_pagina.get_node("hoja").queue_redraw()
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
	if vista != "foto":
		return
	_id_voz_foto += 1
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


## Presionar da el rebote leve al instante; soltar decide: toque corto abre, deslizar pasa de pagina.
func _al_tocar_celda(evento: InputEvent, k: int) -> void:
	if not (evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT):
		return
	get_viewport().set_input_as_handled()
	if evento.pressed:
		_toque_inicio = evento.global_position
		_rebotar(_celdas[k], 1.04)
		return
	if _toque_inicio == Vector2.INF:
		return
	var movido: Vector2 = evento.global_position - _toque_inicio
	_toque_inicio = Vector2.INF
	if absf(movido.x) >= DESLIZAR_MIN:
		pasar_pagina(-1 if movido.x > 0 else 1)
	elif movido.length() <= TOQUE_MAX:
		_tocar_celda(k)


## Cometa repite la instruccion de la vista actual (GDD §6 regla 2).
func repetir_instruccion() -> void:
	_rebotar(_boton_cometa)
	var recuerdos := _recuerdos()
	if recuerdos == null:
		return
	match vista:
		"portada":
			_decir(recuerdos.elegir_linea("album_invitacion"))
		"pagina":
			var vacio: bool = recuerdos.contar(album_abierto)[0] == 0 and recuerdos.recuerdos_album(album_abierto).is_empty()
			_decir(recuerdos.elegir_linea("album_vacio") if vacio else recuerdos.elegir_linea("tapa", album_abierto))
		"foto":
			_repetir_voz()


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


## Tocar la foto abierta repite su voz. Antes, Cometa narra el pie de foto ("Aqui tenia tres
## mesecitos", guion recuerdos §8; UX HE-44 R9), salvo que la familia ya lo diga en su audio.
func _repetir_voz(con_sonido := true) -> void:
	if _recuerdo_abierto.is_empty():
		return
	if con_sonido:
		_rebotar(_foto_grande, 1.03)
	var recuerdos := _recuerdos()
	var audio := get_node_or_null("/root/Audio")
	if recuerdos == null or audio == null:
		return
	_id_voz_foto += 1
	var id := _id_voz_foto
	var rec := _recuerdo_abierto
	var stream: AudioStream = recuerdos.stream_voz(rec)
	var pie := "" if bool(rec.get("pie_en_audio", false)) else str(recuerdos.ruta_linea(str(rec.get("pie", ""))))
	if pie != "":
		_decir(pie)
		var largo := 1.5
		var recurso := load(pie) as AudioStream
		if recurso != null:
			largo = recurso.get_length()
		await get_tree().create_timer(largo + 0.25).timeout
		if not is_inside_tree() or id != _id_voz_foto or _recuerdo_abierto != rec:
			return
	if stream != null:
		audio.reproducir_voz_stream(stream)
	else:
		_decir(recuerdos.elegir_linea("generica"))


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

## Tapa de album de tela, apilada en la portada: lomo, etiqueta crema con la cara y el nombre,
## y el conteo en numeros abajo. Sin estrellas.
func _dibujar_tapa(c: Control, album: String) -> void:
	var recuerdos := _recuerdos()
	var color: Color = recuerdos.color_album(album) if recuerdos != null else DORADO
	var lado := c.size
	var nuevos: bool = recuerdos != null and recuerdos.album_tiene_nuevos(album)
	if nuevos:
		var brillo := StyleBoxFlat.new()
		brillo.bg_color = Color(DORADO, 0.25 + 0.2 * sin(_tiempo * 4.0))
		brillo.set_corner_radius_all(14)
		for lado_margen in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			brillo.set_expand_margin(lado_margen, 10.0)
		c.draw_style_box(brillo, Rect2(Vector2.ZERO, lado))
	# hojas del bloque de paginas, asomando por la derecha y abajo
	var hojas := StyleBoxFlat.new()
	hojas.bg_color = Color("#F4EBDD")
	hojas.set_corner_radius_all(6)
	hojas.border_color = Color("#CFC2AA")
	hojas.set_border_width_all(2)
	c.draw_style_box(hojas, Rect2(Vector2(8, 6), lado - Vector2(8, 4)))
	# tapa de tela
	var tapa := StyleBoxFlat.new()
	tapa.bg_color = color
	tapa.set_corner_radius_all(8)
	tapa.border_color = color.darkened(0.35)
	tapa.set_border_width_all(3)
	tapa.shadow_color = Color(0.05, 0.02, 0.15, 0.5)
	tapa.shadow_offset = Vector2(4, 8)
	tapa.shadow_size = 10
	c.draw_style_box(tapa, Rect2(Vector2.ZERO, lado))
	# trama fina de tela
	for x in range(18, int(lado.x), 6):
		c.draw_line(Vector2(x, 0), Vector2(x, lado.y), Color(0, 0, 0, 0.035), 1.0)
	for y in range(0, int(lado.y), 6):
		c.draw_line(Vector2(0, y), Vector2(lado.x, y), Color(1, 1, 1, 0.03), 1.0)
	# lomo
	c.draw_rect(Rect2(0, 0, 16, lado.y), color.darkened(0.25))
	c.draw_rect(Rect2(16, 0, 2, lado.y), Color(1, 1, 1, 0.22))
	# etiqueta crema con la cara y el nombre
	var etiqueta := Rect2(lado.x * 0.2, lado.y * 0.12, lado.x * 0.72, lado.y * 0.62)
	var cartel := StyleBoxFlat.new()
	cartel.bg_color = COLOR_PAPEL
	cartel.set_corner_radius_all(4)
	cartel.border_color = Color(COLOR_CONTORNO, 0.5)
	cartel.set_border_width_all(2)
	c.draw_style_box(cartel, etiqueta)
	var centro := etiqueta.get_center() + Vector2(0, -22)
	if album == "familia":
		for p in [["maxi", Vector2(-30, 12), 56.0], ["sofia", Vector2(30, 10), 60.0], ["nicole", Vector2(0, -16), 66.0]]:
			_dibujar_cara(c, str(p[0]), centro + (p[1] as Vector2), float(p[2]))
	else:
		_dibujar_cara(c, album, centro, 116.0)
	_texto(c, NOMBRES.get(album, album), Vector2(etiqueta.position.x, etiqueta.end.y - 14.0), etiqueta.size.x, 30, COLOR_CONTORNO)
	# conteo en numeros (encontradas / total)
	if recuerdos != null:
		var conteo: Array = recuerdos.contar(album)
		_texto(c, "%d / %d" % [conteo[0], conteo[1]], Vector2(16, lado.y - 34.0), lado.x - 16.0, 26, COLOR_PAPEL)


## Album abierto: la funda asoma alrededor y dentro hay dos paginas con su pliegue central.
func _dibujar_hoja(c: Control) -> void:
	var recuerdos := _recuerdos()
	var color: Color = recuerdos.color_album(album_abierto) if recuerdos != null and album_abierto != "" else DORADO
	var funda := StyleBoxFlat.new()
	funda.bg_color = color
	funda.set_corner_radius_all(14)
	funda.border_color = color.darkened(0.35)
	funda.set_border_width_all(4)
	funda.shadow_color = Color(0.05, 0.02, 0.15, 0.45)
	funda.shadow_offset = Vector2(0, 10)
	funda.shadow_size = 14
	c.draw_style_box(funda, Rect2(Vector2(-14, -12), c.size + Vector2(28, 30)))
	var papel := StyleBoxFlat.new()
	papel.bg_color = Color("#FFF9EF")
	papel.set_corner_radius_all(4)
	c.draw_style_box(papel, Rect2(Vector2.ZERO, c.size))
	# pliegue central: sombra suave a cada lado del lomo
	var mitad := c.size.x / 2.0
	c.draw_rect(Rect2(mitad - 36.0, 0.0, 36.0, c.size.y), Color(COLOR_CONTORNO, 0.05))
	c.draw_rect(Rect2(mitad - 6.0, 0.0, 6.0, c.size.y), Color(COLOR_CONTORNO, 0.14))
	c.draw_rect(Rect2(mitad, 0.0, 6.0, c.size.y), Color(COLOR_CONTORNO, 0.08))


## Cara del personaje (`tam` = diametro) recortada en circulo: nunca se sale del marco redondo.
func _dibujar_cara(c: Control, id: String, centro: Vector2, tam: float) -> void:
	var textura: Texture2D = _caras.get(id)
	if textura == null:
		Figura.dibujar(c, "estrella", DORADO, centro, tam * 0.4, true)
		return
	_retrato_circular(c, textura, RECORTE_CARA, centro, tam / 2.0)


## Dibuja la region `region` de `textura` dentro de un circulo (poligono con UV).
func _retrato_circular(c: Control, textura: Texture2D, region: Rect2, centro: Vector2, radio: float) -> void:
	var puntos := PackedVector2Array()
	var uvs := PackedVector2Array()
	var tam_textura := textura.get_size()
	var pasos := 48
	for k in pasos:
		var q := Vector2.from_angle(TAU * k / pasos)
		puntos.append(centro + q * radio)
		uvs.append((region.position + (q + Vector2.ONE) * 0.5 * region.size) / tam_textura)
	c.draw_polygon(puntos, PackedColorArray([Color.WHITE]), uvs, textura)


func _dibujar_cabecera(c: Control) -> void:
	var recuerdos := _recuerdos()
	var color: Color = recuerdos.color_album(album_abierto) if recuerdos != null and album_abierto != "" else DORADO
	var centro := c.size / 2.0
	c.draw_circle(centro + Vector2(0, 5), 56.0, Color(COLOR_CONTORNO, 0.3))
	c.draw_circle(centro, 56.0, color)
	c.draw_arc(centro, 56.0, 0.0, TAU, 40, COLOR_CONTORNO, 5.0, true)
	if album_abierto == "familia":
		_dibujar_cara(c, "maxi", centro + Vector2(-26, 10), 52.0)
		_dibujar_cara(c, "sofia", centro + Vector2(26, 8), 56.0)
		_dibujar_cara(c, "nicole", centro + Vector2(0, -14), 54.0)
	elif album_abierto != "":
		_dibujar_cara(c, album_abierto, centro, 96.0)
	# puntitos de pagina
	var total := paginas()
	for k in total:
		var p := Vector2(centro.x + (k - (total - 1) / 2.0) * 22.0, c.size.y - 4.0)
		c.draw_circle(p, 7.0, DORADO if k == pagina else Color(1, 1, 1, 0.5))


## Flecha de pagina: chevron grueso (distinto del icono de volver).
func _dibujar_flecha(c: Control, direccion: float) -> void:
	var centro := c.size / 2.0
	var pts := PackedVector2Array([centro + Vector2(-14.0 * direccion, -26.0), centro + Vector2(16.0 * direccion, 0.0), centro + Vector2(-14.0 * direccion, 26.0)])
	c.draw_polyline(pts, COLOR_CONTORNO, 40.0, true)
	c.draw_polyline(pts, TURQUESA, 24.0, true)


## Volver: en la portada, una casa (vuelve a la seleccion). Dentro del album, un estante con
## cuatro portadas: vuelve a los albumes. Asi no se confunde con las flechas de pagina.
func _dibujar_volver(c: Control) -> void:
	var centro := c.size / 2.0
	if vista == "portada":
		var casa := PackedVector2Array([centro + Vector2(-30, -2), centro + Vector2(0, -32), centro + Vector2(30, -2),
			centro + Vector2(22, -2), centro + Vector2(22, 28), centro + Vector2(-22, 28), centro + Vector2(-22, -2)])
		c.draw_colored_polygon(casa, Color("#FF9F4A"))
		Figura.contornear(c, casa, 5.0)
		c.draw_rect(Rect2(centro + Vector2(-8, 8), Vector2(16, 20)), COLOR_CONTORNO)
		return
	var colores := [Color("#4AA8FF"), Color("#FF5FAE"), Color("#4FD8E0"), Color("#FFCB3D")]
	for k in 4:
		var pos := centro + Vector2(float(k % 2) * 30.0 - 15.0, float(k / 2) * 30.0 - 15.0)
		var portada := StyleBoxFlat.new()
		portada.bg_color = colores[k]
		portada.set_corner_radius_all(3)
		portada.border_color = COLOR_CONTORNO
		portada.set_border_width_all(3)
		c.draw_style_box(portada, Rect2(pos - Vector2(12, 14), Vector2(24, 28)))


func _dibujar_cerrar(c: Control) -> void:
	var centro := c.size / 2.0
	for angulo in [PI / 4.0, -PI / 4.0]:
		var d := Vector2.from_angle(angulo) * 28.0
		c.draw_line(centro - d, centro + d, COLOR_CONTORNO, 18.0, true)
		c.draw_line(centro - d, centro + d, Color("#FF6B6B"), 10.0, true)


func _dibujar_cometa(c: Control) -> void:
	if _textura_cometa == null:
		Figura.dibujar(c, "estrella", DORADO, c.size / 2.0, 40.0, true)
		return
	# Mismo retrato que el boton de Cometa de los minijuegos, sin deformarlo.
	var alto := c.size.y - 14.0
	var ancho := alto * _textura_cometa.get_width() / float(_textura_cometa.get_height())
	var bote := 3.0 * sin(_tiempo * 3.0)
	c.draw_texture_rect(_textura_cometa, Rect2(Vector2((c.size.x - ancho) / 2.0, 8.0 + bote), Vector2(ancho, alto)), false)


# ---------------------------------------------------------------------------
# Sonido y animaciones
# ---------------------------------------------------------------------------

func _texto(c: Control, texto: String, base: Vector2, ancho: float, tam: int, color := COLOR_CONTORNO) -> void:
	if _fuente == null:
		return
	c.draw_string(_fuente, base, texto, HORIZONTAL_ALIGNMENT_CENTER, ancho, tam, color)


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
