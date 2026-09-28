extends Control

## Polaroid estelar de un recuerdo (album "Las migas de papa", ficha §6-§7). La usan el album
## (miniaturas y foto abierta) y la entrega del sobre-estrella.
##
## Tres aspectos, todos dibujados en codigo (sin assets nuevos):
## - FOTO REAL: `assets/recuerdos/fotos/<id>.*` si el PO ya la copio.
## - PLACEHOLDER (encontrado, sin foto real todavia): la imagen del personaje del album a color
##   pleno, con el numero del recuerdo dibujado en el pie.
## - HUECO (no encontrado): los tres hermanos atenuados con tinte violeta y un sello de estrella
##   con "?" encima, para que nunca se confunda con una foto ya encontrada.
## El pie de foto con la edad es un extra para quien lee (Sofia); nunca hace falta leerlo.

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const COLOR_CONTORNO := Color("#2B3350")
const COLOR_PAPEL := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TINTE_HUECO := Color(0.72, 0.66, 0.95, 0.5)

var recuerdo: Dictionary = {}
var hueco := false
## Foto recien llegada que aun no se vio en el album: late con un brillo.
var nuevo := false:
	set(valor):
		nuevo = valor
		set_process(nuevo)
var dorado := false
var mostrar_pie := true
## "cubrir" (miniatura: llena el marco) o "contener" (foto abierta: se ve entera).
var ajuste_foto_real := "cubrir"

var _foto_real: Texture2D
var _imagen: Dictionary = {}
var _fuente: Font
var _tiempo := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	set_process(nuevo)
	resized.connect(queue_redraw)


## `es_hueco`: dibuja el marco-silueta en vez de la foto.
func configurar(rec: Dictionary, es_hueco: bool) -> void:
	recuerdo = rec
	hueco = es_hueco
	_foto_real = null
	_imagen = {}
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos != null:
		if hueco:
			_imagen = recuerdos.imagen_hueco()
		else:
			_foto_real = recuerdos.textura_foto(rec)
			if _foto_real == null:
				_imagen = recuerdos.imagen_placeholder(str(rec.get("album", "")))
			var info: Dictionary = recuerdos.info_encontrado(str(rec.get("id", "")))
			dorado = bool(info.get("dorado", false)) or bool(rec.get("_dorado", false))
	queue_redraw()


func tiene_foto_real() -> bool:
	return _foto_real != null


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _draw() -> void:
	var lado := size
	var m := lado.x * 0.07
	var pie := lado.y * 0.19
	var tarjeta := Rect2(Vector2.ZERO, lado)
	if nuevo:
		var pulso := 0.5 + 0.5 * sin(_tiempo * 4.0)
		var brillo := StyleBoxFlat.new()
		brillo.bg_color = Color(DORADO, 0.25 + 0.35 * pulso)
		brillo.set_corner_radius_all(int(lado.x * 0.1))
		var extra := 8.0 + 6.0 * pulso
		brillo.expand_margin_left = extra
		brillo.expand_margin_right = extra
		brillo.expand_margin_top = extra
		brillo.expand_margin_bottom = extra
		draw_style_box(brillo, tarjeta)
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(COLOR_PAPEL, 0.55) if hueco else COLOR_PAPEL
	caja.set_corner_radius_all(int(lado.x * 0.06))
	caja.border_color = DORADO if dorado else (Color(COLOR_CONTORNO, 0.5) if hueco else COLOR_CONTORNO)
	caja.set_border_width_all(int(maxf(4.0, lado.x * (0.045 if dorado else 0.02))))
	caja.shadow_color = Color(COLOR_CONTORNO, 0.18 if hueco else 0.35)
	caja.shadow_offset = Vector2(0, lado.x * 0.025)
	caja.shadow_size = 3
	caja.anti_aliasing = true
	draw_style_box(caja, tarjeta)

	var zona_foto := Rect2(m, m, lado.x - m * 2.0, lado.y - m - pie)
	var album := str(recuerdo.get("album", ""))
	var recuerdos := get_node_or_null("/root/Recuerdos")
	var color_album: Color = recuerdos.color_album(album) if recuerdos != null else DORADO
	if hueco:
		draw_rect(zona_foto, Color("#5B3F8F"))
		_dibujar_imagen(_imagen, zona_foto, TINTE_HUECO)
		draw_rect(zona_foto, Color(0.35, 0.2, 0.6, 0.25))
		var centro := zona_foto.get_center()
		var radio := zona_foto.size.x * 0.3
		Figura.dibujar(self, "estrella", DORADO, centro, radio, false)
		_texto("?", centro + Vector2(0, radio * 0.32), radio * 0.95, COLOR_CONTORNO)
	elif _foto_real != null:
		draw_rect(zona_foto, Color.BLACK)
		_dibujar_imagen({"textura": _foto_real, "region": Rect2(Vector2.ZERO, _foto_real.get_size()), "ajuste": ajuste_foto_real}, zona_foto, Color.WHITE)
	else:
		draw_rect(zona_foto, color_album.lerp(Color.WHITE, 0.55))
		_dibujar_imagen(_imagen, zona_foto, Color.WHITE)
	if not hueco:
		draw_rect(zona_foto, Color(COLOR_CONTORNO, 0.6), false, maxf(2.0, lado.x * 0.01))

	# Pie de la polaroid: numero del recuerdo (en el placeholder, grande) y edad (extra lector).
	var y_pie := lado.y - pie * 0.5
	if hueco:
		for k in 3:
			draw_circle(Vector2(lado.x * (0.38 + k * 0.12), y_pie), lado.x * 0.022, Color(COLOR_CONTORNO, 0.3))
		_dibujar_brillos_dorados(lado)
		return
	var orden := int(recuerdo.get("orden", 0))
	# Placeholder: el numero va GRANDE sobre la esquina de la foto (se distingue de una foto real);
	# con foto real, chiquito en el pie.
	var radio_numero := zona_foto.size.x * 0.15 if _foto_real == null else pie * 0.28
	var c_numero := Vector2(m + radio_numero + 2.0, y_pie)
	if _foto_real == null:
		c_numero = zona_foto.position + Vector2.ONE * (radio_numero + lado.x * 0.03)
	draw_circle(c_numero, radio_numero, color_album)
	draw_arc(c_numero, radio_numero, 0.0, TAU, 32, COLOR_CONTORNO, maxf(2.0, lado.x * 0.012), true)
	_texto(str(orden), c_numero + Vector2(0, radio_numero * 0.42), radio_numero * 1.2, COLOR_PAPEL, true)
	if mostrar_pie:
		var edad := str(recuerdo.get("edad", ""))
		if edad != "" and _fuente != null:
			var tam := int(clampf(pie * 0.34, 12.0, 34.0))
			var x0 := (c_numero.x + radio_numero + 8.0) if _foto_real != null else m
			draw_string(_fuente, Vector2(x0, y_pie + tam * 0.36), edad, HORIZONTAL_ALIGNMENT_CENTER, lado.x - x0 - m, tam, Color(COLOR_CONTORNO, 0.85))
	_dibujar_brillos_dorados(lado)


func _dibujar_brillos_dorados(lado: Vector2) -> void:
	if not dorado or hueco:
		return
	for p in [Vector2(0.0, 0.0), Vector2(lado.x, 0.0), Vector2(lado.x, lado.y), Vector2(0.0, lado.y)]:
		Figura.dibujar(self, "estrella", DORADO, p, lado.x * 0.07, false)


## Dibuja `imagen` ({textura, region, ajuste}) dentro de `destino`: "cubrir" recorta al centro
## para llenar; "contener" la muestra entera.
func _dibujar_imagen(imagen: Dictionary, destino: Rect2, tinte: Color) -> void:
	if imagen.is_empty() or imagen.get("textura") == null:
		return
	var textura: Texture2D = imagen["textura"]
	var region: Rect2 = imagen["region"]
	if str(imagen.get("ajuste", "cubrir")) == "contener":
		var escala := minf(destino.size.x / region.size.x, destino.size.y / region.size.y)
		var tam := region.size * escala
		draw_texture_rect_region(textura, Rect2(destino.get_center() - tam / 2.0, tam), region, tinte)
		return
	var aspecto := destino.size.x / destino.size.y
	var fuente := region
	if region.size.x / region.size.y > aspecto:
		fuente.size.x = region.size.y * aspecto
		fuente.position.x += (region.size.x - fuente.size.x) / 2.0
	else:
		fuente.size.y = region.size.x / aspecto
		fuente.position.y += (region.size.y - fuente.size.y) * 0.3
	draw_texture_rect_region(textura, destino, fuente, tinte)


func _texto(texto: String, base: Vector2, tam: float, color: Color, contorno := false) -> void:
	if _fuente == null:
		return
	var t := int(maxf(10.0, tam))
	var ancho := 400.0
	if contorno:
		draw_string_outline(_fuente, base - Vector2(ancho / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_CENTER, ancho, t, maxi(3, t / 6), COLOR_CONTORNO)
	draw_string(_fuente, base - Vector2(ancho / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_CENTER, ancho, t, color)
