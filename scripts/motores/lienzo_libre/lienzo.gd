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
## LIENZO CON TEMA (`stickers_objeto`, ficha §8): los sellos del catalogo de `stickers.gd` crean
## STICKERS VIVOS (capa 3) que se tocan (saltan), se arrastran, se recolorean con el balde y se
## borran con la goma. La herramienta "conector" traza un CAMINO a mano alzada (pista, rieles,
## cerca, guirnalda, puente arcoiris...) que se pega a los stickers de sus puntas; si el tema trae
## `viajero`, un auto, tren o pony lo recorre ida y vuelta (o da vueltas si el camino se cierra).
## Los caminos van entre la pintura y los stickers; los viajeros, encima de los stickers.
##
## El lienzo no sabe de voces ni de encargos: avisa por senales y el motor decide que decir.

signal sticker_tocado(sticker: Control)
signal sticker_cambiado()
signal sticker_borrado(id: String, posicion: Vector2)
signal camino_creado(desde: Control, hasta: Control)
signal viajero_llego(sticker: Control)
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
const Stickers := preload("res://scripts/motores/lienzo_libre/stickers.gd")
const StickerVivo := preload("res://scripts/motores/lienzo_libre/sticker_vivo.gd")
const Grabador := preload("res://scripts/motores/lienzo_libre/grabador.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const COLOR_CONTORNO := Color("#2B3350")
const MAX_SELLOS_VIVOS := 40
## Stickers vivos del lienzo con tema: pasado el tope, el mas antiguo se hornea en la pintura.
const MAX_STICKERS := 60
const MAX_CAMINOS := 30
const MAX_VIAJEROS := 8
const VELOCIDAD_VIAJERO := 120.0
## Un toque que se mueve menos que esto es "tocar" (el sticker salta), no "arrastrar".
const TOLERANCIA_TOQUE := 14.0
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
## Lienzo con tema: los sellos crean stickers vivos; Semilla los tine con el color actual (Nicole y
## Sofia los recolorean con el balde); `conector` = {"tipo", "viajero"}.
var stickers_objeto := false
var sticker_con_color_actual := false
var conector: Dictionary = {}
## Con fondo de tema, rellenar todas sus zonas no es "terminar la lamina".
var avisar_completa := true
## Caminos del conector: [{"puntos", "tipo", "desde", "hasta", "cerrado", "largos"}].
var caminos: Array = []
var seleccionado: StickerVivo = null

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
var _capa_caminos: Control
var _capa_viajeros: Control
var _viajeros: Array = []  ## [{"nodo", "camino", "s", "dir"}]
var _arrastre: StickerVivo = null
var _arrastre_desfase := Vector2.ZERO
var _arrastre_recorrido := 0.0
var _camino_actual := PackedVector2Array()
var _tiempo := 0.0
static var _cache_stickers := {}
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
	_capa_caminos = Control.new()
	_capa_caminos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa_caminos)
	_capa_caminos.size = Vector2(tamano)
	_capa_caminos.draw.connect(_dibujar_caminos)
	_capa_sellos = Control.new()
	_capa_sellos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa_sellos)
	_capa_sellos.size = Vector2(tamano)
	_capa_viajeros = Control.new()
	_capa_viajeros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa_viajeros)
	_capa_viajeros.size = Vector2(tamano)
	_capa_guias = Control.new()
	_capa_guias.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa_guias)
	_capa_guias.size = Vector2(tamano)
	_capa_guias.draw.connect(_dibujar_guias)
	limpiar()


func _process(delta: float) -> void:
	_tiempo += delta
	if not _viajeros.is_empty():
		_mover_viajeros(delta)
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
	for hijo in _capa_viajeros.get_children():
		hijo.queue_free()
	caminos.clear()
	_viajeros.clear()
	seleccionado = null
	_arrastre = null
	_camino_actual = PackedVector2Array()
	queue_redraw()
	_capa_guias.queue_redraw()
	_capa_caminos.queue_redraw()


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
	if stickers_objeto and mosaico.is_empty():
		# Primero se decide que se toco, para que el motor sepa si fue un sticker (barra de edicion).
		var tocado: StickerVivo = sticker_en(punto) if herramienta != "conector" else null
		if tocado != null and herramienta not in ["goma", "balde"]:
			_arrastre = tocado
			_arrastre_desfase = tocado.centro() - punto
			_arrastre_recorrido = 0.0
			_capa_sellos.move_child(tocado, -1)
		toque_iniciado.emit()
		if herramienta == "conector":
			_camino_actual = PackedVector2Array([punto])
			_capa_caminos.queue_redraw()
			return
		if tocado != null:
			if herramienta == "goma":
				borrar_sticker(tocado)
			elif herramienta == "balde":
				tocado.color = color_actual
				tocado.saltar()
				color_usado.emit(color_actual)
				sticker_cambiado.emit()
			return
	else:
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
	if _arrastre != null:
		_arrastre_recorrido += distancia
		if is_instance_valid(_arrastre):
			_arrastre.poner_en((punto + _arrastre_desfase).clamp(Vector2.ZERO, Vector2(tamano)))
		_ultimo = punto
		return
	if not _camino_actual.is_empty():
		if _camino_actual[_camino_actual.size() - 1].distance_to(punto) >= 6.0:
			_camino_actual.append(punto.clamp(Vector2.ZERO, Vector2(tamano)))
			_capa_caminos.queue_redraw()
		_ultimo = punto
		return
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
	if _arrastre != null:
		var sticker := _arrastre
		_arrastre = null
		if is_instance_valid(sticker):
			if _arrastre_recorrido < TOLERANCIA_TOQUE:
				sticker_tocado.emit(sticker)
			else:
				sticker_cambiado.emit()
	if not _camino_actual.is_empty():
		_cerrar_camino()


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
	if stickers_objeto and Stickers.tiene(tipo):
		var sticker := poner_sticker(tipo, punto)
		sello_puesto.emit(tipo, punto)
		color_usado.emit(sticker.color)
		return
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
		var suyo := str(hijo.get_meta("tipo", ""))
		if not hijo.is_queued_for_deletion() and (suyo == tipo or (tipo == "dino" and Stickers.es_dino(suyo))):
			lista.append(hijo)
	lista = lista.slice(maxi(0, lista.size() - cuantos))
	for i in lista.size():
		var nodo: Control = lista[i]
		var espejado: bool = (nodo as TextureRect).flip_h if nodo is TextureRect else bool(nodo.get("espejo"))
		var paso := 34.0 * (-1.0 if espejado else 1.0)
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
# Lienzo con tema: stickers vivos
# ---------------------------------------------------------------------------

func poner_sticker(id: String, punto: Vector2) -> StickerVivo:
	var sticker := StickerVivo.new()
	var color := color_actual if sticker_con_color_actual else Stickers.color_por_defecto(id)
	sticker.preparar(id, color, float(lado_sello))
	_capa_sellos.add_child(sticker)
	sticker.poner_en(punto)
	sticker.aparecer()
	var vivos := stickers()
	if vivos.size() > MAX_STICKERS:
		_hornear_sticker(vivos[0])
	return sticker


## Stickers vivos en el lienzo (sin los que se estan borrando), del mas antiguo al mas nuevo.
func stickers() -> Array:
	var lista: Array = []
	for hijo in _capa_sellos.get_children():
		if hijo is StickerVivo and not hijo.is_queued_for_deletion():
			lista.append(hijo)
	return lista


## El sticker de mas arriba bajo `punto`, o null.
func sticker_en(punto: Vector2) -> StickerVivo:
	var lista := stickers()
	for i in range(lista.size() - 1, -1, -1):
		var sticker: StickerVivo = lista[i]
		if punto.distance_to(sticker.centro()) <= sticker.radio_toque():
			return sticker
	return null


## El sticker que se esta arrastrando ahora (o null).
func arrastrando() -> StickerVivo:
	return _arrastre


func seleccionar(sticker: StickerVivo) -> void:
	if is_instance_valid(seleccionado):
		seleccionado.seleccionado = false
	seleccionado = sticker
	if sticker != null:
		sticker.seleccionado = true


func borrar_sticker(sticker: StickerVivo) -> void:
	if not is_instance_valid(sticker):
		return
	if seleccionado == sticker:
		seleccionado = null
	for camino: Dictionary in caminos:
		if camino["desde"] == sticker:
			camino["desde"] = null
		if camino["hasta"] == sticker:
			camino["hasta"] = null
	sticker_borrado.emit(sticker.id, sticker.centro())
	sticker.queue_free()
	sticker_cambiado.emit()


func contar_stickers(id := "") -> int:
	var cuenta := 0
	for sticker: StickerVivo in stickers():
		if id == "" or sticker.id == id:
			cuenta += 1
	return cuenta


func ids_distintos() -> int:
	var ids := {}
	for sticker: StickerVivo in stickers():
		ids[sticker.id] = true
	return ids.size()


## Caminos que unen dos stickers distintos (los "conectaste" de Coco y los retos de Sofia).
func conexiones() -> int:
	var cuenta := 0
	for camino: Dictionary in caminos:
		var desde = camino["desde"]
		var hasta = camino["hasta"]
		if desde != null and hasta != null and desde != hasta and is_instance_valid(desde) and is_instance_valid(hasta):
			cuenta += 1
	return cuenta


func _hornear_sticker(sticker: StickerVivo) -> void:
	Raster.estampar(_pintura, _imagen_sticker(sticker), sticker.centro())
	_sucio = true
	sticker.queue_free()


func _imagen_sticker(sticker: StickerVivo) -> Image:
	var lado := maxi(8, roundi(sticker.lado * sticker.escala))
	var giro := snappedf(wrapf(sticker.rotation, -PI, PI), 0.01)
	var clave := "%s_%s_%d_%.2f_%s" % [sticker.id, (sticker.color as Color).to_html(), lado, giro, sticker.espejo]
	if not _cache_stickers.has(clave):
		if _cache_stickers.size() > 240:
			_cache_stickers.clear()
		_cache_stickers[clave] = Stickers.imagen(sticker.id, sticker.color, lado, giro, sticker.espejo)
	return _cache_stickers[clave]


# ---------------------------------------------------------------------------
# Lienzo con tema: caminos del conector y viajeros
# ---------------------------------------------------------------------------

## Termina el camino a mano alzada: lo suaviza, pega sus puntas a los stickers que toca y, si el
## tema tiene viajero, lo echa a andar.
func _cerrar_camino() -> void:
	var crudo := _camino_actual
	_camino_actual = PackedVector2Array()
	var puntos := remuestrear(suavizar(crudo), 10.0)
	var largo := _largo(puntos)
	if puntos.size() < 2 or largo < 50.0:
		_capa_caminos.queue_redraw()
		return
	var desde := sticker_en(crudo[0])
	var hasta := sticker_en(crudo[crudo.size() - 1])
	if desde != null:
		puntos[0] = desde.centro()
	if hasta != null:
		puntos[puntos.size() - 1] = hasta.centro()
	if desde == hasta:
		hasta = null
	var cerrado := desde == null and hasta == null and largo > 280.0 and puntos[0].distance_to(puntos[puntos.size() - 1]) < 80.0
	if cerrado:
		puntos.append(puntos[0])
	var camino := {"puntos": puntos, "tipo": str(conector.get("tipo", "camino")), "desde": desde, "hasta": hasta,
		"cerrado": cerrado, "largos": _largos(puntos)}
	caminos.append(camino)
	if caminos.size() > MAX_CAMINOS:
		var viejo: Dictionary = caminos.pop_front()
		for v: Dictionary in _viajeros.duplicate():
			if v["camino"] == viejo:
				(v["nodo"] as Node).queue_free()
				_viajeros.erase(v)
	_capa_caminos.queue_redraw()
	var viajero := str(conector.get("viajero", ""))
	if viajero != "" and Stickers.tiene(viajero):
		_lanzar_viajero(camino, viajero)
	for punta in [desde, hasta]:
		if punta != null:
			punta.saltar()
	camino_creado.emit(desde, hasta)


func _lanzar_viajero(camino: Dictionary, id: String) -> void:
	if _viajeros.size() >= MAX_VIAJEROS:
		var viejo: Dictionary = _viajeros.pop_front()
		(viejo["nodo"] as Node).queue_free()
	var nodo := StickerVivo.new()
	var color := color_actual if sticker_con_color_actual else Stickers.color_por_defecto(id)
	nodo.preparar(id, color, lado_sello * 0.8)
	_capa_viajeros.add_child(nodo)
	nodo.poner_en(camino["puntos"][0])
	nodo.aparecer()
	_viajeros.append({"nodo": nodo, "camino": camino, "s": 0.0, "dir": 1.0})


func _mover_viajeros(delta: float) -> void:
	for v: Dictionary in _viajeros:
		var nodo: StickerVivo = v["nodo"]
		if not is_instance_valid(nodo):
			continue
		var camino: Dictionary = v["camino"]
		var largos: PackedFloat32Array = camino["largos"]
		var total := largos[largos.size() - 1]
		var s: float = v["s"] + v["dir"] * VELOCIDAD_VIAJERO * delta
		if bool(camino["cerrado"]):
			s = fposmod(s, total)
		elif s >= total:
			s = total
			v["dir"] = -1.0
			_llegada(camino["hasta"])
		elif s <= 0.0:
			s = 0.0
			v["dir"] = 1.0
			_llegada(camino["desde"])
		v["s"] = s
		var p := punto_en(camino, s)
		var adelante := s + float(v["dir"]) * 8.0
		adelante = fposmod(adelante, total) if bool(camino["cerrado"]) else clampf(adelante, 0.0, total)
		var tangente := punto_en(camino, adelante) - p
		if absf(tangente.x) > 0.5 or absf(tangente.y) > 0.5:
			_orientar(nodo, tangente, delta)
		nodo.poner_en(p)
		if not nodo.id in Stickers.ROTAN:
			nodo.rebote = absf(sin(_tiempo * 9.0 + float(v["s"]) * 0.01)) * nodo.lado * 0.08


## Gira y espeja al viajero para que avance mirando hacia donde va (los animales solo se inclinan).
func _orientar(nodo: StickerVivo, tangente: Vector2, delta: float) -> void:
	var direccion: float = Stickers.DIRECCION.get(nodo.id, 0.0)
	var espejo := tangente.x < 0.0
	var adelante := PI - direccion if espejo else direccion
	var giro := wrapf(tangente.angle() - adelante, -PI, PI)
	if not nodo.id in Stickers.ROTAN:
		giro = clampf(giro, -0.45, 0.45)
	if nodo.espejo != espejo:
		nodo.espejo = espejo
		nodo.rotation = giro
	else:
		nodo.rotation = lerp_angle(nodo.rotation, giro, minf(1.0, delta * 10.0))


func _llegada(sticker) -> void:
	if sticker != null and is_instance_valid(sticker):
		sticker.saltar()
		viajero_llego.emit(sticker)


func viajeros() -> Array:
	var lista: Array = []
	for v: Dictionary in _viajeros:
		if is_instance_valid(v["nodo"]):
			lista.append(v["nodo"])
	return lista


## Punto del camino a `s` px de su inicio.
static func punto_en(camino: Dictionary, s: float) -> Vector2:
	var puntos: PackedVector2Array = camino["puntos"]
	var largos: PackedFloat32Array = camino["largos"]
	for i in range(1, largos.size()):
		if s <= largos[i]:
			var tramo := largos[i] - largos[i - 1]
			return puntos[i - 1].lerp(puntos[i], (s - largos[i - 1]) / tramo if tramo > 0.0 else 0.0)
	return puntos[puntos.size() - 1]


static func _largos(puntos: PackedVector2Array) -> PackedFloat32Array:
	var largos := PackedFloat32Array([0.0])
	for i in range(1, puntos.size()):
		largos.append(largos[i - 1] + puntos[i - 1].distance_to(puntos[i]))
	return largos


static func _largo(puntos: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, puntos.size()):
		total += puntos[i - 1].distance_to(puntos[i])
	return total


## Una pasada de Chaikin (sin mover las puntas): quita el temblor del dedo.
static func suavizar(puntos: PackedVector2Array) -> PackedVector2Array:
	if puntos.size() < 3:
		return puntos
	var salida := PackedVector2Array([puntos[0]])
	for i in puntos.size() - 1:
		salida.append(puntos[i].lerp(puntos[i + 1], 0.25))
		salida.append(puntos[i].lerp(puntos[i + 1], 0.75))
	salida.append(puntos[puntos.size() - 1])
	return salida


## Puntos a distancia pareja `paso` a lo largo de la linea (conserva las puntas).
static func remuestrear(puntos: PackedVector2Array, paso: float) -> PackedVector2Array:
	if puntos.size() < 2:
		return puntos
	var salida := PackedVector2Array([puntos[0]])
	var sobra := 0.0
	for i in range(1, puntos.size()):
		var a := puntos[i - 1]
		var b := puntos[i]
		var tramo := a.distance_to(b)
		var d := paso - sobra
		while d <= tramo:
			salida.append(a.lerp(b, d / tramo))
			d += paso
		sobra = tramo - (d - paso)
	if salida[salida.size() - 1].distance_to(puntos[puntos.size() - 1]) > 1.0:
		salida.append(puntos[puntos.size() - 1])
	return salida


func _dibujar_caminos() -> void:
	for camino: Dictionary in caminos:
		dibujar_camino(_capa_caminos, camino["puntos"], camino["tipo"])
	if _camino_actual.size() >= 2:
		dibujar_camino(_capa_caminos, _camino_actual, str(conector.get("tipo", "camino")))


## Dibuja un camino del conector sobre cualquier CanvasItem o Grabador (pantalla, PNG e icono de
## la herramienta, con `k` para achicarlo). Tipos: camino (pista con linea blanca), sendero,
## rieles, cerca, guirnalda (luces de colores), arcoiris (puente), estelar y destellos.
static func dibujar_camino(l, puntos: PackedVector2Array, tipo: String, k := 1.0) -> void:
	if puntos.size() < 2:
		return
	match tipo:
		"sendero":
			l.draw_polyline(puntos, COLOR_CONTORNO, 40.0 * k, true)
			l.draw_polyline(puntos, Color("#E8C88F"), 32.0 * k, true)
			var i := 0
			for muestra: Array in a_lo_largo(puntos, 26.0 * k):
				var normal := Vector2(-muestra[1].y, muestra[1].x)
				l.draw_circle(muestra[0] + normal * (7.0 * k if i % 2 == 0 else -7.0 * k), 4.0 * k, Color("#C9A36B"))
				i += 1
		"rieles":
			for muestra: Array in a_lo_largo(puntos, 18.0 * k):
				var normal := Vector2(-muestra[1].y, muestra[1].x)
				l.draw_line(muestra[0] - normal * 18.0 * k, muestra[0] + normal * 18.0 * k, Color("#9A6238"), 7.0 * k, true)
			for lado in [-1.0, 1.0]:
				var riel := desplazar_linea(puntos, lado * 10.0 * k)
				l.draw_polyline(riel, COLOR_CONTORNO, 7.0 * k, true)
				l.draw_polyline(riel, Color("#C9D0E0"), 4.0 * k, true)
		"cerca":
			for alto in [-20.0, -8.0]:
				var tabla := _trasladar(puntos, Vector2(0, alto * k))
				l.draw_polyline(tabla, COLOR_CONTORNO, 10.0 * k, true)
				l.draw_polyline(tabla, Color("#E6B07A"), 6.0 * k, true)
			for muestra: Array in a_lo_largo(puntos, 38.0 * k):
				var p: Vector2 = muestra[0]
				l.draw_line(p + Vector2(0, 4) * k, p + Vector2(0, -30) * k, COLOR_CONTORNO, 13.0 * k, true)
				l.draw_line(p + Vector2(0, 2) * k, p + Vector2(0, -28) * k, Color("#B07A55"), 8.0 * k, true)
		"guirnalda":
			l.draw_polyline(puntos, COLOR_CONTORNO, 3.0 * k, true)
			var i := 0
			for muestra: Array in a_lo_largo(puntos, 28.0 * k):
				var foco: Vector2 = muestra[0] + Vector2(0, 9) * k
				l.draw_circle(foco, 9.0 * k, COLOR_CONTORNO)
				l.draw_circle(foco, 7.0 * k, Figura.COLORES_ARCOIRIS[i % Figura.COLORES_ARCOIRIS.size()])
				l.draw_circle(foco + Vector2(-2.5, -2.5) * k, 2.2 * k, Color(1, 1, 1, 0.7))
				i += 1
		"arcoiris":
			var bandas := Figura.COLORES_ARCOIRIS.size()
			var ancho := 6.0 * k
			for lado in [-1.0, 1.0]:
				l.draw_polyline(desplazar_linea(puntos, lado * (bandas / 2.0 * ancho + 1.5 * k)), COLOR_CONTORNO, 4.0 * k, true)
			for j in bandas:
				l.draw_polyline(desplazar_linea(puntos, (j - (bandas - 1) / 2.0) * ancho), Figura.COLORES_ARCOIRIS[j], ancho + 1.0 * k, true)
		"estelar", "destellos":
			var i := 0
			var muestras := a_lo_largo(puntos, 14.0 * k)
			for muestra: Array in muestras:
				if i % 3 == 0:
					var forma := Figura.poligono("estrella", muestra[0], 10.0 * k)
					l.draw_colored_polygon(forma, Color("#FFE38A") if tipo == "estelar" or i % 2 == 0 else Color("#FF9FD2"))
					Figura.contornear(l, forma, 2.5 * k)
				else:
					l.draw_circle(muestra[0], 3.5 * k, Color("#FFF3B0") if tipo == "estelar" else Color("#FFD6F0"))
				i += 1
		_:
			l.draw_polyline(puntos, COLOR_CONTORNO, 50.0 * k, true)
			l.draw_polyline(puntos, Color("#8A90A6"), 42.0 * k, true)
			var i := 0
			for muestra: Array in a_lo_largo(puntos, 17.0 * k):
				if i % 2 == 0:
					var p: Vector2 = muestra[0]
					var dir: Vector2 = muestra[1]
					l.draw_line(p - dir * 7.0 * k, p + dir * 7.0 * k, Color.WHITE, 5.0 * k, true)
				i += 1


## Muestras [punto, direccion] cada `paso` px a lo largo de la linea.
static func a_lo_largo(puntos: PackedVector2Array, paso: float) -> Array:
	var muestras: Array = []
	var d := paso * 0.5
	var recorrido := 0.0
	for i in range(1, puntos.size()):
		var a := puntos[i - 1]
		var b := puntos[i]
		var tramo := a.distance_to(b)
		if tramo <= 0.0:
			continue
		var dir := (b - a) / tramo
		while d <= recorrido + tramo:
			muestras.append([a + dir * (d - recorrido), dir])
			d += paso
		recorrido += tramo
	return muestras


## La misma linea corrida `d` px hacia su izquierda (bandas del arcoiris, rieles).
static func desplazar_linea(puntos: PackedVector2Array, d: float) -> PackedVector2Array:
	var salida := PackedVector2Array()
	var n := puntos.size()
	for i in n:
		var antes := puntos[maxi(0, i - 1)]
		var despues := puntos[mini(n - 1, i + 1)]
		var dir := (despues - antes).normalized()
		salida.append(puntos[i] + Vector2(-dir.y, dir.x) * d)
	return salida


static func _trasladar(puntos: PackedVector2Array, desfase: Vector2) -> PackedVector2Array:
	var salida := PackedVector2Array()
	for p in puntos:
		salida.append(p + desfase)
	return salida


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
	if _completa_avisada or not avisar_completa:
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


## Mecanicas HE-40 #20 (03-Oct-2026): las celdas miden ~42 px, bajo los 64 del GDD. El pincel pinta la
## celda mas cercana al dedo dentro de `RADIO_CELDA` px, asi un dedo que cae justo afuera del borde
## igual pinta (zona efectiva >= 64 px).
const RADIO_CELDA := 32.0
const PASO_TRAZO_CELDAS := 10.0


func celda_cercana(punto: Vector2) -> Vector2i:
	var celda := celda_en(punto)
	if celda.x >= 0:
		return celda
	var filas: Array = mosaico.get("celdas", [])
	if filas.is_empty():
		return Vector2i(-1, -1)
	var rel := (punto - _origen_mosaico) / _lado_celda
	var y := clampi(floori(rel.y), 0, filas.size() - 1)
	var x := clampi(floori(rel.x), 0, str(filas[y]).length() - 1)
	var rect := Rect2(_origen_mosaico + Vector2(x, y) * _lado_celda, Vector2.ONE * _lado_celda)
	var dentro := Vector2(clampf(punto.x, rect.position.x, rect.end.x), clampf(punto.y, rect.position.y, rect.end.y))
	return Vector2i(x, y) if punto.distance_to(dentro) <= RADIO_CELDA else Vector2i(-1, -1)


func _pintar_celda(punto: Vector2) -> void:
	var celda := celda_cercana(punto)
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
	# Arrastrar pinta todas las celdas que cruza el trazo (un punto cada 10 px, HE-40 #20).
	var pasos := maxi(1, ceili(desde.distance_to(hasta) / minf(PASO_TRAZO_CELDAS, _lado_celda * 0.4)))
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
	if not caminos.is_empty():
		var grabador := Grabador.new()
		for camino: Dictionary in caminos:
			dibujar_camino(grabador, camino["puntos"], camino["tipo"])
		grabador.volcar(imagen)
	for nodo in _capa_sellos.get_children() + _capa_viajeros.get_children():
		if nodo.is_queued_for_deletion():
			continue
		if nodo is StickerVivo:
			Raster.estampar(imagen, _imagen_sticker(nodo), nodo.centro() + Vector2(0, -nodo.rebote * nodo.escala))
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
