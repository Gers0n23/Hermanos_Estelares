extends RefCounted

## Grabador de dibujos para el motor `lienzo_libre`: imita los `draw_*` de un CanvasItem y guarda
## cada primitiva. Asi los dibujos por codigo (`dibujos_emparejar.gd`, `figura_vectorial.gd`,
## `stickers.gd`) se pintan en pantalla como vectores (nitidos a cualquier tamano o giro) y, al
## guardar el PNG, se rasterizan en CPU con `rasterizador.gd`, que tambien funciona headless.
##
## Uso: `var g := Grabador.new(); Stickers.dibujar(g, id, color, Vector2.ZERO, Grabador.RADIO)`
## y despues `g.rasterizar(lado, giro, espejo)`.

const Raster := preload("res://scripts/motores/lienzo_libre/rasterizador.gd")

## Radio con que se graba un dibujo (unidades del grabador).
const RADIO := 100.0

var _ops: Array = []  ## [tipo, datos...]


func draw_colored_polygon(puntos: PackedVector2Array, color: Color, _uvs := PackedVector2Array(), _textura = null) -> void:
	if puntos.size() >= 3:
		_ops.append(["poligono", puntos.duplicate(), color])


func draw_polyline(puntos: PackedVector2Array, color: Color, ancho := -1.0, _suave := false) -> void:
	if puntos.size() >= 2:
		_ops.append(["linea", puntos.duplicate(), color, maxf(1.0, ancho), false])


func draw_line(desde: Vector2, hasta: Vector2, color: Color, ancho := -1.0, _suave := false) -> void:
	_ops.append(["linea", PackedVector2Array([desde, hasta]), color, maxf(1.0, ancho), false])


func draw_circle(centro: Vector2, radio: float, color: Color, relleno := true, ancho := -1.0, _suave := false) -> void:
	var puntos := _arco(centro, radio, 0.0, TAU, maxi(16, int(radio * 0.6)))
	if relleno:
		_ops.append(["poligono", puntos, color])
	else:
		_ops.append(["linea", puntos, color, maxf(1.0, ancho), true])


func draw_arc(centro: Vector2, radio: float, desde: float, hasta: float, lados: int, color: Color, ancho := -1.0, _suave := false) -> void:
	_ops.append(["linea", _arco(centro, radio, desde, hasta, lados), color, maxf(1.0, ancho), false])


func draw_rect(rect: Rect2, color: Color, relleno := true, ancho := -1.0, _suave := false) -> void:
	var puntos := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	if relleno:
		_ops.append(["poligono", puntos, color])
	else:
		_ops.append(["linea", puntos, color, maxf(1.0, ancho), true])


## Convierte lo grabado en una Image cuadrada de `lado` px. El dibujo se graba centrado en (0,0) con
## radio `RADIO` y ocupa el 90 % de la imagen. `giro` en radianes; `espejo` invierte en x.
func rasterizar(lado: int, giro := 0.0, espejo := false) -> Image:
	var escala_ss := 3 if lado <= 90 else 2
	var ancho := lado * escala_ss
	var imagen := Image.create(ancho, ancho, false, Image.FORMAT_RGBA8)
	var k := ancho / 2.0 * 0.9 / RADIO
	var xform := Transform2D(giro, Vector2(ancho, ancho) / 2.0) * Transform2D.FLIP_X if espejo else Transform2D(giro, Vector2(ancho, ancho) / 2.0)
	volcar(imagen, xform.scaled_local(Vector2(k, k)), k)
	imagen.resize(lado, lado, Image.INTERPOLATE_BILINEAR)
	return imagen


## Pinta lo grabado directo sobre `imagen` (sin supersampleo), p. ej. los caminos del dibujo.
## `k` escala los grosores de linea (la escala de `xform`).
func volcar(imagen: Image, xform := Transform2D.IDENTITY, k := 1.0) -> void:
	for op: Array in _ops:
		var puntos := PackedVector2Array()
		for p: Vector2 in op[1]:
			puntos.append(xform * p)
		var color: Color = op[2]
		if op[0] == "poligono":
			Raster.rellenar_poligono(imagen, puntos, color, color.a < 1.0)
		else:
			Raster.trazar(imagen, puntos, float(op[3]) * k, color, bool(op[4]))


static func _arco(centro: Vector2, radio: float, desde: float, hasta: float, lados: int) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var n := maxi(2, lados)
	for i in n + 1:
		puntos.append(centro + Vector2.from_angle(lerpf(desde, hasta, float(i) / n)) * radio)
	if is_equal_approx(absf(hasta - desde), TAU):
		puntos.remove_at(puntos.size() - 1)
	return puntos
