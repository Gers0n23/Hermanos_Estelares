extends Control

## Cresta de Coco que imita los colores que usa el nino (ficha planeta-arcoiris §3.1 y §3.10).
##
## Se cuelga del `TextureRect` de Coco. Al empezar detecta en el sprite los pixeles de la cresta
## (los muy saturados de la parte de arriba de la cabeza) y despues los repinta en franjas con los
## ultimos colores usados, conservando las luces y sombras del dibujo original. Si la textura no
## se puede leer (p. ej. headless), no dibuja nada y el juego sigue igual.

## Zona del sprite coco_base.png (293x459) donde vive la cresta.
const ZONA_CRESTA := Rect2i(118, 0, 90, 50)
const SATURACION_MINIMA := 0.33
const MAX_FRANJAS := 5

var _pixeles: Array = []  ## [Vector2i posicion, float luz]
var _caja := Rect2i()
var _textura_cresta: ImageTexture
var _colores: Array = []
var _textura_base: Texture2D


func preparar(textura: Texture2D) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_textura_base = textura
	var imagen: Image = textura.get_image() if textura != null else null
	if imagen == null or imagen.is_empty():
		return
	if imagen.is_compressed():
		imagen.decompress()
	var zona := ZONA_CRESTA.intersection(Rect2i(Vector2i.ZERO, imagen.get_size()))
	var primero := true
	for y in range(zona.position.y, zona.end.y):
		for x in range(zona.position.x, zona.end.x):
			var c := imagen.get_pixel(x, y)
			if c.a > 0.5 and c.s >= SATURACION_MINIMA:
				_pixeles.append([Vector2i(x, y), c.v])
				_caja = Rect2i(x, y, 1, 1) if primero else _caja.merge(Rect2i(x, y, 1, 1))
				primero = false


## Repinta la cresta con estos colores (el mas nuevo arriba). Lista vacia = cresta original.
func imitar(colores: Array) -> void:
	_colores = colores.slice(maxi(0, colores.size() - MAX_FRANJAS))
	if _pixeles.is_empty():
		return
	if _colores.is_empty():
		_textura_cresta = null
		queue_redraw()
		return
	var imagen := Image.create(_caja.size.x, _caja.size.y, false, Image.FORMAT_RGBA8)
	var n := _colores.size()
	for dato in _pixeles:
		var p: Vector2i = dato[0]
		var luz: float = dato[1]
		# Franjas diagonales, como las bandas del arcoiris original de la cresta.
		var t := clampf((float(p.x - _caja.position.x) / _caja.size.x) * 0.6 + (float(p.y - _caja.position.y) / _caja.size.y) * 0.4, 0.0, 0.999)
		var base: Color = _colores[n - 1 - int(t * n)]
		var color := base.darkened(clampf(0.85 - luz, 0.0, 0.4)) if luz < 0.85 else base.lightened(clampf(luz - 0.9, 0.0, 0.25))
		imagen.set_pixelv(p - _caja.position, color)
	_textura_cresta = ImageTexture.create_from_image(imagen)
	queue_redraw()


func _draw() -> void:
	if _textura_cresta == null or _textura_base == null:
		return
	var padre := get_parent() as Control
	var tam_tex := _textura_base.get_size()
	var escala := minf(padre.size.x / tam_tex.x, padre.size.y / tam_tex.y)
	var desfase := (padre.size - tam_tex * escala) / 2.0
	draw_texture_rect(_textura_cresta, Rect2(desfase + Vector2(_caja.position) * escala, Vector2(_caja.size) * escala), false)
