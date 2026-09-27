extends Control

## Lienzo del motor `lienzo_libre` (docs/fichas/motor-lienzo-libre.md §4).
##
## Capas, de abajo hacia arriba:
## 1. Papel (color liso) y, si hay, la LAMINA vectorial (regiones rellenables + detalles) o el
##    MOSAICO por codigo (celdas con numero). Se dibujan con `_draw` y solo se redibujan al cambiar.
## 2. La PINTURA: una sola `Image` del tamano del lienzo, mostrada con una `ImageTexture`. Cada
##    trazo estampa una brocha con `Image.blend_rect` (nativo) y la textura se sube a lo mas una vez
##    por cuadro. Asi el rendimiento no depende de cuanto pinte el nino (nada de un nodo por trazo).
## 3. Sellos vivos (solo los dinos y autos de Maxi, para el gag de "caminar"): unos pocos nodos;
##    pasado un tope se hornean en la pintura.
## 4. Guias (eje del espejo, rayos del mandala), por encima y translucidas.
##
## Herramientas: "pincel", "pincel_grueso", "goma", "balde" (rellena la region tocada), "arcoiris"
## (el color cambia al avanzar), "purpurina", "pincel_corazon"/"pincel_estrella" (rastro de
## figuritas) y "sello_<tipo>" (una calcomania por toque). Simetria: "" | "espejo" | "mandala".
##
## El lienzo no sabe de voces ni de encargos: avisa por senales y el motor decide que decir.

signal toque_iniciado()
signal color_usado(color: Color)
signal sello_puesto(tipo: String, posicion: Vector2)
signal region_rellenada(indice: int, color: Color)
signal celda_pintada(correcta: bool)
signal lamina_completa()
signal nota(altura: float)
signal purpurina_quieta(posicion: Vector2)
signal color_ciclado(color: Color)

const Raster := preload("res://scripts/motores/lienzo_libre/rasterizador.gd")
const Laminas := preload("res://scripts/motores/lienzo_libre/laminas.gd")
const Sellos := preload("res://scripts/motores/lienzo_libre/sellos.gd")
const COLOR_CONTORNO := Color("#2B3350")
const MAX_SELLOS_VIVOS := 40
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const DORADO := Color("#FFCB3D")

var tamano := Vector2i(824, 530)
var papel := Color("#FFF8EE")
var color_actual := Color("#EE4035")
var herramienta := "pincel"
var simetria := ""
## Radio de la brocha (px del lienzo) y lado de los sellos, por perfil.
var radio_pincel := 16.0
var lado_sello := 84
var sellos_vivos := false
var rellenar_con_toque := false
## Semilla: si toca una region con el color que ya tiene, pasa al siguiente de esta lista (todo
## toque cambia algo, GDD §5).
var colores_ciclo: Array = []

var lamina: Dictionary = {}
var _tocadas := {}
var mosaico: Dictionary = {}
var guia: Dictionary = {}

var _pintura: Image
var _textura: ImageTexture
var _sucio := false
var _brochas := {}
var _calcomanias := {}
var _capa_sellos: Control
var _capa_guias: Control
var _presionado := false
var _ultimo := Vector2.ZERO
var _recorrido := 0.0
var _recorrido_total := 0.0
var _desde_nota := 0.0
var _ultima_region := -1
var _ultima_celda := Vector2i(-1, -1)
var _quieto := 0.0
var _purpurina_disparada := false
var _completa_avisada := false
var _fuente: Font
var bloqueado := false

## Mosaico: celdas pintadas (Vector2i -> Color), geometria de la grilla.
var _celdas := {}
var _lado_celda := 40.0
var _origen_mosaico := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = Vector2(tamano)
	size = Vector2(tamano)
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_capa_sellos = Control.new()
	_capa_sellos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa_sellos)
	_capa_sellos.size = Vector2(tamano)
	_capa_guias = Control.new()
	_capa_guias.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa_guias)
	_capa_guias.size = Vector2(tamano)
	_capa_guias.draw.connect(_dibujar_guias)
	limpiar()


func _process(delta: float) -> void:
	if _sucio:
		_sucio = false
		_textura.update(_pintura)
	if _presionado and herramienta == "purpurina" and not _purpurina_disparada:
		_quieto += delta
		if _quieto >= 1.0:
			_purpurina_disparada = true
			purpurina_quieta.emit(_ultimo)


# ---------------------------------------------------------------------------
# Preparacion de cada hoja
# ---------------------------------------------------------------------------

## Deja el lienzo en blanco (papel) y sin lamina, mosaico ni guia.
func limpiar() -> void:
	_pintura = Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	_textura = ImageTexture.create_from_image(_pintura)
	lamina = {}
	mosaico = {}
	guia = {}
	simetria = ""
	_celdas.clear()
	_completa_avisada = false
	for hijo in _capa_sellos.get_children():
		hijo.queue_free()
	queue_redraw()
	_capa_guias.queue_redraw()


func poner_lamina(datos: Dictionary) -> void:
	lamina = Laminas.preparar(datos)
	_tocadas.clear()
	_completa_avisada = false
	queue_redraw()


func poner_guia(datos: Dictionary) -> void:
	guia = Laminas.preparar(datos)
	queue_redraw()


func poner_mosaico(datos: Dictionary) -> void:
	mosaico = datos
	_celdas.clear()
	_completa_avisada = false
	var filas: Array = datos.get("celdas", [])
	var alto := filas.size()
	var ancho := 0
	for fila in filas:
		ancho = maxi(ancho, str(fila).length())
	_lado_celda = floorf(minf((tamano.x - 16.0) / maxf(1, ancho), (tamano.y - 16.0) / maxf(1, alto)))
	_lado_celda = minf(_lado_celda, float(datos.get("lado_maximo", 48)))
	_origen_mosaico = ((Vector2(tamano) - Vector2(ancho, alto) * _lado_celda) / 2.0).floor()
	queue_redraw()


func poner_simetria(tipo: String) -> void:
	simetria = tipo
	_capa_guias.queue_redraw()


## Cambia el color de una region (tambien lo usa "viste a Coco" para conservar colores).
func pintar_region(indice: int, color: Color) -> void:
	var regiones: Array = lamina.get("regiones", [])
	if indice < 0 or indice >= regiones.size():
		return
	regiones[indice]["color"] = color
	queue_redraw()


# ---------------------------------------------------------------------------
# Entrada unificada (mouse y dedo: el toque se emula como mouse, GDD §6.4)
# ---------------------------------------------------------------------------

func _gui_input(evento: InputEvent) -> void:
	if bloqueado:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			empezar_trazo(evento.position)
		else:
			terminar_trazo()
		accept_event()
	elif evento is InputEventMouseMotion and _presionado:
		continuar_trazo(evento.position)
		accept_event()


func empezar_trazo(punto: Vector2) -> void:
	_presionado = true
	_ultimo = punto
	_recorrido = 0.0
	_desde_nota = 0.0
	_quieto = 0.0
	_purpurina_disparada = false
	_ultima_region = -1
	_ultima_celda = Vector2i(-1, -1)
	toque_iniciado.emit()
	if not mosaico.is_empty():
		_pintar_celda(punto)
		return
	if herramienta == "balde" or (rellenar_con_toque and not lamina.is_empty() and not herramienta.begins_with("sello_")):
		_rellenar(punto)
		return
	if herramienta.begins_with("sello_"):
		_poner_sello(herramienta.trim_prefix("sello_"), punto)
		return
	if herramienta == "arcoiris":
		nota.emit(1.0 - punto.y / tamano.y)
	_estampar_en(punto, true)
	if herramienta != "goma":
		color_usado.emit(_color_del_trazo())


func continuar_trazo(punto: Vector2) -> void:
	if not _presionado:
		return
	var distancia := _ultimo.distance_to(punto)
	if distancia < 0.5:
		return
	_quieto = 0.0
	if not mosaico.is_empty():
		_pintar_linea_celdas(_ultimo, punto)
		_ultimo = punto
		return
	if herramienta == "balde" or (rellenar_con_toque and not lamina.is_empty() and not herramienta.begins_with("sello_")):
		_rellenar(punto)
		_ultimo = punto
		return
	if herramienta.begins_with("sello_"):
		_recorrido += distancia
		if _recorrido >= lado_sello * 1.1:
			_recorrido = 0.0
			_poner_sello(herramienta.trim_prefix("sello_"), punto)
		_ultimo = punto
		return
	var paso := _paso_trazo()
	var pasos := maxi(1, floori(distancia / paso))
	for k in range(1, pasos + 1):
		var p := _ultimo.lerp(punto, float(k) / pasos)
		_recorrido += distancia / pasos
		_desde_nota += distancia / pasos
		if _recorrido >= paso or herramienta in ["pincel", "pincel_grueso", "goma", "arcoiris"]:
			_estampar_en(p, false)
			if herramienta not in ["pincel", "pincel_grueso", "goma", "arcoiris"]:
				_recorrido = 0.0
	if herramienta == "arcoiris" and _desde_nota >= 70.0:
		_desde_nota = 0.0
		nota.emit(1.0 - punto.y / tamano.y)
		color_usado.emit(_color_del_trazo())
	_ultimo = punto


func terminar_trazo() -> void:
	_presionado = false


func _paso_trazo() -> float:
	match herramienta:
		"pincel_corazon", "pincel_estrella":
			return radio_pincel * 2.6
		"purpurina":
			return radio_pincel * 0.9
		"pincel_grueso":
			return radio_pincel * 0.5
	return maxf(1.5, radio_pincel * 0.3)


func _radio_herramienta() -> float:
	match herramienta:
		"pincel_grueso", "goma":
			return radio_pincel * 1.8
	return radio_pincel


## Color del trazo actual (el arcoiris cambia de color con la distancia recorrida).
func _color_del_trazo() -> Color:
	if herramienta == "arcoiris":
		var tono := fposmod(_recorrido_total / 420.0, 1.0)
		return Color.from_hsv(roundf(tono * 24.0) / 24.0, 0.62, 1.0)
	return color_actual



# ---------------------------------------------------------------------------
# Pintura en la Image
# ---------------------------------------------------------------------------

func _estampar_en(punto: Vector2, primero: bool) -> void:
	if herramienta == "arcoiris":
		_recorrido_total += radio_pincel * 0.3
	var puntos := puntos_simetricos(punto)
	match herramienta:
		"goma":
			var mascara := _brocha(Color.WHITE, _radio_herramienta())
			var vacio := Image.create(mascara.get_width(), mascara.get_height(), false, Image.FORMAT_RGBA8)
			for p in puntos:
				var tam := mascara.get_size()
				_pintura.blit_rect_mask(vacio, mascara, Rect2i(Vector2i.ZERO, tam), Vector2i(roundi(p.x - tam.x / 2.0), roundi(p.y - tam.y / 2.0)))
		"pincel_corazon", "pincel_estrella":
			var tipo := herramienta.trim_prefix("pincel_")
			var imagen := _calcomania(tipo, color_actual, int(radio_pincel * 2.4))
			for p in puntos:
				Raster.estampar(_pintura, imagen, p)
		"purpurina":
			for p in puntos:
				for i in 3:
					var chispa := _calcomania("destello", [DORADO, Color.WHITE, color_actual.lightened(0.3)][i], int(randf_range(10.0, 20.0)))
					Raster.estampar(_pintura, chispa, p + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * radio_pincel * 1.2)
		_:
			var brocha := _brocha(_color_del_trazo(), _radio_herramienta())
			for p in puntos:
				Raster.estampar(_pintura, brocha, p)
	_sucio = true


## Punto y sus copias segun la simetria activa (espejo: 2; mandala: 12 = 6 ejes con reflejo).
func puntos_simetricos(punto: Vector2) -> Array[Vector2]:
	var lista: Array[Vector2] = [punto]
	match simetria:
		"espejo":
			lista.append(Vector2(tamano.x - punto.x, punto.y))
		"mandala":
			var centro := Vector2(tamano) / 2.0
			var rel := punto - centro
			var reflejo := Vector2(rel.x, -rel.y)
			lista.clear()
			for k in 6:
				var angulo := TAU * k / 6.0
				lista.append(centro + rel.rotated(angulo))
				lista.append(centro + reflejo.rotated(angulo))
	return lista


func _brocha(color: Color, radio: float) -> Image:
	var clave := "%s_%d" % [color.to_html(), roundi(radio * 2.0)]
	if not _brochas.has(clave):
		if _brochas.size() > 64:
			_brochas.clear()
		_brochas[clave] = Raster.brocha(color, radio)
	return _brochas[clave]


func _calcomania(tipo: String, color: Color, lado: int) -> Image:
	var clave := "%s_%s_%d" % [tipo, color.to_html(), lado]
	if not _calcomanias.has(clave):
		if _calcomanias.size() > 64:
			_calcomanias.clear()
		_calcomanias[clave] = Sellos.imagen(tipo, color, lado)
	return _calcomanias[clave]


func _poner_sello(tipo: String, punto: Vector2) -> void:
	var imagen := _calcomania(tipo, color_actual, lado_sello)
	var puntos := puntos_simetricos(punto)
	for i in puntos.size():
		var p: Vector2 = puntos[i]
		var espejado := simetria == "espejo" and i == 1
		if sellos_vivos and tipo in ["dino", "auto"]:
			_sello_vivo(tipo, imagen, p, espejado)
		else:
			var final_img := imagen
			if espejado:
				final_img = imagen.duplicate()
				final_img.flip_x()
			Raster.estampar(_pintura, final_img, p)
			_sucio = true
	sello_puesto.emit(tipo, punto)
	color_usado.emit(color_actual)


func _sello_vivo(tipo: String, imagen: Image, punto: Vector2, espejado: bool) -> void:
	var nodo := TextureRect.new()
	nodo.texture = ImageTexture.create_from_image(imagen)
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nodo.flip_h = espejado
	nodo.size = Vector2(imagen.get_size())
	nodo.position = punto - nodo.size / 2.0
	nodo.pivot_offset = nodo.size / 2.0
	nodo.set_meta("tipo", tipo)
	nodo.set_meta("imagen", imagen)
	_capa_sellos.add_child(nodo)
	# Aparece con un "pop" (respuesta inmediata, GDD §6.5).
	nodo.scale = Vector2(0.3, 0.3)
	nodo.create_tween().tween_property(nodo, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _capa_sellos.get_child_count() > MAX_SELLOS_VIVOS:
		_hornear_sello(_capa_sellos.get_child(0))


func _hornear_sello(nodo: TextureRect) -> void:
	var imagen: Image = nodo.get_meta("imagen")
	if nodo.flip_h:
		imagen = imagen.duplicate()
		imagen.flip_x()
	Raster.estampar(_pintura, imagen, nodo.position + nodo.size / 2.0)
	_sucio = true
	nodo.queue_free()


## Gag de Maxi (ficha §3.10): los ultimos sellos de `tipo` dan un pasito en fila.
func caminar_sellos(tipo: String, cuantos: int) -> void:
	var lista: Array = []
	for hijo in _capa_sellos.get_children():
		if not hijo.is_queued_for_deletion() and hijo.get_meta("tipo", "") == tipo:
			lista.append(hijo)
	lista = lista.slice(maxi(0, lista.size() - cuantos))
	for i in lista.size():
		var nodo: TextureRect = lista[i]
		var paso := 34.0 * (-1.0 if nodo.flip_h else 1.0)
		var tween := nodo.create_tween()
		tween.tween_interval(i * 0.12)
		for salto in 2:
			tween.tween_property(nodo, "position", nodo.position + Vector2(paso * (salto + 0.5), -22), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(nodo, "rotation", deg_to_rad(-8.0 if salto == 0 else 8.0), 0.14)
			tween.tween_property(nodo, "position", nodo.position + Vector2(paso * (salto + 1), 0), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(nodo, "rotation", 0.0, 0.1)


func cantidad_sellos_vivos() -> int:
	return _capa_sellos.get_child_count()


# ---------------------------------------------------------------------------
# Laminas por zonas y mosaico por codigo
# ---------------------------------------------------------------------------

func _rellenar(punto: Vector2) -> void:
	var indice := Laminas.region_en(lamina, punto)
	if indice < 0 or indice == _ultima_region:
		return
	_ultima_region = indice
	var region: Dictionary = lamina["regiones"][indice]
	var nuevo := color_actual
	if (region["color"] as Color).is_equal_approx(nuevo):
		if colores_ciclo.is_empty():
			# Mismo color (p. ej. la estrella blanca de la bandera): cuenta como pintada igual.
			if not _tocadas.has(indice):
				_tocadas[indice] = true
				region_rellenada.emit(indice, nuevo)
				color_usado.emit(nuevo)
				_revisar_completa()
			return
		# Semilla: tocar de nuevo con el mismo color nunca "no hace nada"; pasa al color siguiente.
		var indice_color := 0
		for i in colores_ciclo.size():
			if (colores_ciclo[i] as Color).is_equal_approx(nuevo):
				indice_color = i
		nuevo = colores_ciclo[(indice_color + 1) % colores_ciclo.size()]
		color_actual = nuevo
		color_ciclado.emit(nuevo)
	region["color"] = nuevo
	_tocadas[indice] = true
	queue_redraw()
	region_rellenada.emit(indice, nuevo)
	color_usado.emit(nuevo)
	_revisar_completa()


func region_color(indice: int) -> Color:
	return lamina["regiones"][indice]["color"]


func regiones_rellenables() -> Array:
	var lista: Array = []
	var regiones: Array = lamina.get("regiones", [])
	for i in regiones.size():
		if not bool(regiones[i].get("fija", false)):
			lista.append(i)
	return lista


## Cuantas regiones rellenables ya se pintaron (aunque sea con su mismo color inicial).
func regiones_pintadas() -> int:
	var cuenta := 0
	for i in regiones_rellenables():
		if _tocadas.has(i):
			cuenta += 1
	return cuenta


func _revisar_completa() -> void:
	if _completa_avisada:
		return
	var completa := false
	if not mosaico.is_empty():
		completa = _celdas.size() >= total_celdas()
	elif not lamina.is_empty():
		var total := regiones_rellenables().size()
		completa = total > 0 and regiones_pintadas() >= total
	if completa:
		_completa_avisada = true
		lamina_completa.emit()


func celda_en(punto: Vector2) -> Vector2i:
	var rel := (punto - _origen_mosaico) / _lado_celda
	var celda := Vector2i(floori(rel.x), floori(rel.y))
	var filas: Array = mosaico.get("celdas", [])
	if celda.y < 0 or celda.y >= filas.size() or celda.x < 0 or celda.x >= str(filas[celda.y]).length():
		return Vector2i(-1, -1)
	return celda


func centro_celda(celda: Vector2i) -> Vector2:
	return _origen_mosaico + (Vector2(celda) + Vector2(0.5, 0.5)) * _lado_celda


func color_esperado(celda: Vector2i) -> Color:
	var codigo := str(mosaico["celdas"][celda.y])[celda.x]
	return Color(str(mosaico.get("colores", {}).get(codigo, "#FFFFFF")))


func total_celdas() -> int:
	var total := 0
	for fila in mosaico.get("celdas", []):
		total += str(fila).length()
	return total


func celdas_pintadas() -> int:
	return _celdas.size()


func celdas_correctas() -> int:
	var cuenta := 0
	for celda: Vector2i in _celdas:
		if (_celdas[celda] as Color).is_equal_approx(color_esperado(celda)):
			cuenta += 1
	return cuenta


func _pintar_celda(punto: Vector2) -> void:
	var celda := celda_en(punto)
	if celda.x < 0 or celda == _ultima_celda:
		return
	_ultima_celda = celda
	if _celdas.has(celda) and (_celdas[celda] as Color).is_equal_approx(color_actual):
		return
	_celdas[celda] = color_actual
	queue_redraw()
	celda_pintada.emit(color_actual.is_equal_approx(color_esperado(celda)))
	color_usado.emit(color_actual)
	_revisar_completa()


func _pintar_linea_celdas(desde: Vector2, hasta: Vector2) -> void:
	var pasos := maxi(1, ceili(desde.distance_to(hasta) / (_lado_celda * 0.4)))
	for k in range(1, pasos + 1):
		_pintar_celda(desde.lerp(hasta, float(k) / pasos))


# ---------------------------------------------------------------------------
# Dibujo en pantalla
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(tamano)), papel)
	if not guia.is_empty():
		Laminas.dibujar(self, guia, Vector2.ZERO, 1.0, float(guia.get("alfa", 0.35)))
	if not lamina.is_empty():
		Laminas.dibujar(self, lamina)
	if not mosaico.is_empty():
		_dibujar_mosaico()
	draw_texture(_textura, Vector2.ZERO)


func _dibujar_mosaico() -> void:
	var filas: Array = mosaico.get("celdas", [])
	var tam_letra := int(_lado_celda * 0.5)
	for y in filas.size():
		var fila := str(filas[y])
		for x in fila.length():
			var celda := Vector2i(x, y)
			var rect := Rect2(_origen_mosaico + Vector2(x, y) * _lado_celda, Vector2.ONE * _lado_celda)
			var pintada: bool = _celdas.has(celda)
			draw_rect(rect, _celdas[celda] if pintada else Color.WHITE)
			draw_rect(rect, Color(COLOR_CONTORNO, 0.18), false, 1.5)
			var correcta: bool = pintada and (_celdas[celda] as Color).is_equal_approx(color_esperado(celda))
			if _fuente != null and not correcta:
				# Numero grande si falta pintar; chiquito en la esquina si el color no coincide
				# (una pista suave, nunca un "error").
				var tam := tam_letra if not pintada else int(tam_letra * 0.55)
				var color_numero := Color(COLOR_CONTORNO, 0.75) if not pintada else Color(1, 1, 1, 0.85)
				var base := rect.get_center() + Vector2(-_lado_celda / 2.0, tam * 0.36) if not pintada else rect.position + Vector2(3, tam + 1)
				var ancho := _lado_celda if not pintada else -1.0
				draw_string(_fuente, base, fila[x], HORIZONTAL_ALIGNMENT_CENTER if not pintada else HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, color_numero)
	var marco := Rect2(_origen_mosaico, Vector2(str(filas[0]).length() if not filas.is_empty() else 0, filas.size()) * _lado_celda)
	draw_rect(marco, COLOR_CONTORNO, false, 4.0)


func _dibujar_guias() -> void:
	var color := Color(COLOR_CONTORNO, 0.28)
	match simetria:
		"espejo":
			var x := tamano.x / 2.0
			var y := 6.0
			while y < tamano.y:
				_capa_guias.draw_line(Vector2(x, y), Vector2(x, y + 14.0), color, 4.0, true)
				y += 26.0
		"mandala":
			var centro := Vector2(tamano) / 2.0
			for k in 6:
				var dir := Vector2.from_angle(TAU * k / 6.0 + PI / 6.0)
				_capa_guias.draw_line(centro, centro + dir * tamano.y * 0.49, color, 2.5, true)
			_capa_guias.draw_arc(centro, tamano.y * 0.49, 0.0, TAU, 72, color, 3.0, true)


# ---------------------------------------------------------------------------
# Guardado
# ---------------------------------------------------------------------------

## Compone el dibujo completo (papel + lamina/mosaico + pintura + sellos) en una Image. No usa el
## renderer: funciona igual en la tablet que headless.
func componer() -> Image:
	var imagen := Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	imagen.fill(papel)
	if not guia.is_empty():
		var tenue := guia.duplicate(true)
		for region: Dictionary in tenue.get("regiones", []):
			region["color"] = Color(region["color"], float(guia.get("alfa", 0.35)))
		Laminas.rasterizar(imagen, tenue)
	if not lamina.is_empty():
		Laminas.rasterizar(imagen, lamina)
	if not mosaico.is_empty():
		var filas: Array = mosaico.get("celdas", [])
		for y in filas.size():
			for x in str(filas[y]).length():
				var celda := Vector2i(x, y)
				var rect := Rect2i(Vector2i((_origen_mosaico + Vector2(x, y) * _lado_celda).round()), Vector2i.ONE * int(_lado_celda))
				imagen.fill_rect(rect, _celdas.get(celda, Color.WHITE))
	imagen.blend_rect(_pintura, Rect2i(Vector2i.ZERO, tamano), Vector2i.ZERO)
	for nodo in _capa_sellos.get_children():
		if nodo.is_queued_for_deletion():
			continue
		var sello: Image = nodo.get_meta("imagen")
		if nodo.flip_h:
			sello = sello.duplicate()
			sello.flip_x()
		Raster.estampar(imagen, sello, nodo.position + nodo.size / 2.0)
	return imagen


## Guarda el dibujo como PNG. Devuelve el error de `save_png` (OK = 0).
func guardar_png(ruta: String) -> Error:
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	return componer().save_png(ruta)


## Pixeles de pintura no transparentes (para QA: confirma que un trazo simulado dejo huella).
func pixeles_pintados() -> int:
	var cuenta := 0
	for y in range(0, tamano.y, 4):
		for x in range(0, tamano.x, 4):
			if _pintura.get_pixel(x, y).a > 0.1:
				cuenta += 1
	return cuenta
