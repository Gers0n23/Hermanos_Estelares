extends Control

## Lienzo del motor `lienzo_libre` (docs/fichas/motor-lienzo-libre.md §4, §8 y §9 "Lienzo v2").
##
## LIENZO V2 (17-Oct-2026): ocupa la pantalla completa (1280x720) y se puede ACERCAR (zoom con pinza,
## rueda o lupa). Con zoom, el pincel y los stickers nuevos conservan su tamano EN PANTALLA: en el
## mundo quedan mas chicos (mas detalle). Las laminas de 824x530 (zonas 2-5) se encuadran con escala
## uniforme en `area_segura`, la parte del papel que no tapan los botones de las esquinas.
##
## Capas, de abajo hacia arriba:
## 1. Papel y LAMINA vectorial (o MOSAICO por codigo), con `_draw`.
## 2. PINTURA: una sola `Image` del tamano del lienzo (`Image.blend_rect`, nativo).
## 3. CAMINOS (sendero, carretera, rieles, puente arcoiris...).
## 4. STICKERS: nodos vectoriales con CLASE (`stickers.gd`): `vivo` (anda por los caminos), `lugar`
##    (destino de caminos y viajeros; incluye los LUGARES FIJOS del fondo, invisibles, como el rio)
##    y `decorado` (solo visual). Tambien los sellos de Maxi de las zonas 2 y 5.
## 5. Guias (espejo, mandala) y la PISTA FANTASMA de Coco (camino punteado, sticker translucido).
##
## Un VIVO que se suelta sobre o cerca de un camino se sube y lo recorre: al llegar a un lugar emite
## `llegada`, sigue por otro camino de ese lugar si hay (redes: "orden") o vuelve; se baja al volver
## a su lugar de partida. En un camino CERRADO (circuito) da vueltas (`vuelta`). Las COMBINACIONES
## (p. ej. sol + nube de lluvia en el cielo) crean su resultado animado (`combinacion`).
##
## El lienzo no sabe de voces, objetivos ni encargos: avisa por senales y el motor decide.

signal sticker_tocado(sticker: Control)
signal sticker_cambiado()
signal sticker_borrado(id: String, posicion: Vector2)
signal camino_creado(desde: Control, hasta: Control, camino: Dictionary)
signal llegada(vivo: Control, lugar: Control, desde: Control)
signal vuelta(vivo: Control, vueltas: int)
signal vivo_subio(vivo: Control)
signal combinacion(resultado: String, posicion: Vector2)
signal zoom_cambiado(zoom: float)
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
const MAX_VIAJES := 12
const VELOCIDAD_VIAJERO := 130.0
## Segundos que el viajero se queda en un lugar al llegar (el pony toma agua).
const PAUSA_LLEGADA := 1.1
## Un toque que se mueve menos que esto (px de pantalla) es "tocar", no "arrastrar".
const TOLERANCIA_TOQUE := 14.0
const ZOOM_MAX := 3.0
## Caminos que adornan o encierran pero no llevan viajeros (R6 de lienzo-escenas-retos.md; la cerca
## se agrega por delegacion: es el corral, no un camino para pasear).
const SIN_VIAJEROS := ["guirnalda", "cerca"]
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const DORADO := Color("#FFCB3D")

var tamano := Vector2i(1280, 720)
var papel := Color("#FFF8EE")
var color_actual := Color("#EE4035")
var herramienta := "pincel"
var simetria := ""
## Centro de las simetrias (espejo y mandala): el de la lamina encuadrada.
var centro_simetria := Vector2(640, 360)
## Radio de la brocha y lado de los sellos, en px de PANTALLA (con zoom se dividen).
var radio_pincel := 16.0
var lado_sello := 84
var sellos_vivos := false
var rellenar_con_toque := false
var colores_ciclo: Array = []
var stickers_objeto := false
var sticker_con_color_actual := false
## Tipo del camino que se traza con la herramienta "camino_<tipo>" (o el `conector` heredado).
var tipo_camino := "sendero"
var conector: Dictionary = {}
var avisar_completa := true
## R2: distancia (px de pantalla) a la que un vivo soltado se sube a un camino.
var radio_subida := 60.0
## R1: una punta de camino a esta distancia (px de pantalla) del borde de un lugar se pega (Maxi 120).
var iman := 70.0
## R5: un trazo que termina a esta distancia de su inicio (y con este largo minimo) se cierra.
var cierre_distancia := 60.0
var cierre_largo := 280.0
## R2 en Semilla: al trazar un camino, el vivo mas cercano salta solo a la punta; y un vivo nuevo
## salta al camino si ya hay uno.
var auto_subir := false
## Lupa armada: el siguiente toque acerca al doble centrado ahi (no pinta).
var lupa_armada := false
## Clases por id que fija el tema (si falta, `Stickers.clase`).
var clases: Dictionary = {}
## Combinaciones del tema: [{"ingredientes": [...], "resultado", "en_zona"?, "distancia"?, "escala"?}].
var combinaciones: Array = []
## Zonas con nombre del tema: nombre -> [x, y, ancho, alto] (si no, se busca la region del fondo).
var zonas: Dictionary = {}
## Area del papel libre de botones: alli se encuadran las laminas chicas y el mosaico.
var area_segura := Rect2(Vector2.ZERO, Vector2(1280, 720))
## Caminos: [{"puntos", "tipo", "desde", "hasta", "cerrado", "largos", "k"}].
var caminos: Array = []
var seleccionado: StickerVivo = null
var zoom := 1.0
var zoom_permitido := true
## Mientras dos dedos hacen un gesto, la entrada de mouse emulada se ignora (dos dedos nunca pintan).
var en_gesto := false
## Largo total pintado en la hoja (px del mundo): mide el encargo de las hojas de trazo libre.
var recorrido_pintado := 0.0
## Dedo magico (Maxi z4): algun trazo cruzo las tres franjas de altura (arriba, medio y abajo).
var trazo_cruzo_franjas := false
## Usos de cada herramienta en la hoja (trazos o estampados), para el objetivo `usar`.
var usos: Dictionary = {}
var _trazo_min_y := 0.0
var _trazo_max_y := 0.0
## Puntos de muestreo (grilla de 16 px) dentro de las regiones de la guia, para la cobertura.
var _muestras_guia := PackedVector2Array()

var lamina: Dictionary = {}
var _tocadas := {}
var mosaico: Dictionary = {}
var guia: Dictionary = {}
var _escala_lamina := 1.0
var _desfase_lamina := Vector2.ZERO

var _pintura: Image
var _respaldo: Image
var _textura: ImageTexture
var _sucio := false
var _brochas := {}
var _calcomanias := {}
var _capa_sellos: Control
var _capa_guias: Control
var _capa_caminos: Control
var _capa_fantasma: Control
var _viajes: Array = []  ## [{"nodo", "camino", "s", "dir", "inicio", "piernas", "pausa", "vueltas", "andado"}]
var _arrastre: StickerVivo = null
var _arrastre_desfase := Vector2.ZERO
var _arrastre_recorrido := 0.0
var _arrastre_inicio := Vector2.ZERO
var _puestos_trazo: Array = []
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
## Pista fantasma: {"tipo": "camino"|"sticker"|"zona"|"circuito", ...} y segundos restantes.
var _fantasma: Dictionary = {}
var _fantasma_resta := 0.0

var _numero_camino := 0

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
	_capa_caminos = _capa(_dibujar_caminos)
	_capa_sellos = _capa(Callable())
	_capa_guias = _capa(_dibujar_guias)
	_capa_fantasma = _capa(_dibujar_fantasma)
	limpiar()


func _capa(dibujo: Callable) -> Control:
	var capa := Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa)
	capa.size = Vector2(tamano)
	if dibujo.is_valid():
		capa.draw.connect(dibujo)
	return capa


func _process(delta: float) -> void:
	_tiempo += delta
	if not _viajes.is_empty():
		_mover_viajeros(delta)
	if _sucio:
		_sucio = false
		_textura.update(_pintura)
	if _presionado and herramienta == "purpurina" and not _purpurina_disparada:
		_quieto += delta
		if _quieto >= 1.0:
			_purpurina_disparada = true
			purpurina_quieta.emit(_ultimo)
	if _fantasma_resta > 0.0:
		_fantasma_resta -= delta
		if _fantasma_resta <= 0.0:
			_fantasma = {}
		_capa_fantasma.queue_redraw()


# ---------------------------------------------------------------------------
# Preparacion de cada hoja
# ---------------------------------------------------------------------------

func limpiar() -> void:
	_pintura = Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	_respaldo = Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	_textura = ImageTexture.create_from_image(_pintura)
	lamina = {}
	mosaico = {}
	guia = {}
	simetria = ""
	centro_simetria = Vector2(tamano) / 2.0
	_escala_lamina = 1.0
	_desfase_lamina = Vector2.ZERO
	_celdas.clear()
	_completa_avisada = false
	for hijo in _capa_sellos.get_children():
		_capa_sellos.remove_child(hijo)
		hijo.queue_free()
	caminos.clear()
	_viajes.clear()
	seleccionado = null
	_arrastre = null
	_puestos_trazo.clear()
	_camino_actual = PackedVector2Array()
	_fantasma = {}
	_fantasma_resta = 0.0
	recorrido_pintado = 0.0
	trazo_cruzo_franjas = false
	usos = {}
	lupa_armada = false
	_muestras_guia = PackedVector2Array()
	combinaciones = []
	zonas = {}
	clases = {}
	ver_todo()
	queue_redraw()
	_capa_guias.queue_redraw()
	_capa_caminos.queue_redraw()
	_capa_fantasma.queue_redraw()


## Fija el encuadre de las laminas: las de otro tamano (824x530) se escalan de forma uniforme y se
## centran en `area_segura`; las que traen `tamano` igual al lienzo quedan tal cual.
func encuadrar(tam_original: Vector2) -> void:
	if tam_original.is_equal_approx(Vector2(tamano)) or tam_original.x <= 0.0:
		_escala_lamina = 1.0
		_desfase_lamina = Vector2.ZERO
	else:
		_escala_lamina = minf(area_segura.size.x / tam_original.x, area_segura.size.y / tam_original.y)
		_desfase_lamina = (area_segura.position + (area_segura.size - tam_original * _escala_lamina) / 2.0).round()
	centro_simetria = _desfase_lamina + tam_original * _escala_lamina / 2.0 if _escala_lamina != 1.0 else Vector2(tamano) / 2.0


func escala_lamina() -> float:
	return _escala_lamina


func poner_lamina(datos: Dictionary) -> void:
	lamina = Laminas.encuadrar(Laminas.preparar(datos), _escala_lamina, _desfase_lamina)
	_tocadas.clear()
	_completa_avisada = false
	queue_redraw()


func poner_guia(datos: Dictionary) -> void:
	guia = Laminas.encuadrar(Laminas.preparar(datos), _escala_lamina, _desfase_lamina)
	_muestras_guia = muestras_de(guia.get("regiones", []))
	queue_redraw()


## Puntos de una grilla de 16 px que caen dentro de alguna de las regiones.
func muestras_de(regiones: Array) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for y in range(8, tamano.y, 16):
		for x in range(8, tamano.x, 16):
			var p := Vector2(x, y)
			for region: Dictionary in regiones:
				if Geometry2D.is_point_in_polygon(p, region["poligono"]):
					puntos.append(p)
					break
	return puntos


## Fraccion (0-1) de la guia cubierta de pintura (espejo y mandala).
func cobertura_guia() -> float:
	if _muestras_guia.is_empty():
		return 0.0
	var pintadas := 0
	for p in _muestras_guia:
		if _pintura.get_pixelv(Vector2i(p)).a > 0.1:
			pintadas += 1
	return float(pintadas) / _muestras_guia.size()


func poner_mosaico(datos: Dictionary) -> void:
	mosaico = datos
	_celdas.clear()
	_completa_avisada = false
	var filas: Array = datos.get("celdas", [])
	var alto := filas.size()
	var ancho := 0
	for fila in filas:
		ancho = maxi(ancho, str(fila).length())
	_lado_celda = floorf(minf((area_segura.size.x - 16.0) / maxf(1, ancho), (area_segura.size.y - 16.0) / maxf(1, alto)))
	_lado_celda = minf(_lado_celda, float(datos.get("lado_maximo", 48)))
	_origen_mosaico = (area_segura.position + (area_segura.size - Vector2(ancho, alto) * _lado_celda) / 2.0).floor()
	queue_redraw()


func poner_simetria(tipo: String) -> void:
	simetria = tipo
	_capa_guias.queue_redraw()


func pintar_region(indice: int, color: Color) -> void:
	var regiones: Array = lamina.get("regiones", [])
	if indice < 0 or indice >= regiones.size():
		return
	regiones[indice]["color"] = color
	queue_redraw()


## Indice de la region del fondo con ese id (o -1).
func region_por_id(id: String) -> int:
	var regiones: Array = lamina.get("regiones", [])
	for i in regiones.size():
		if str(regiones[i].get("id", "")) == id:
			return i
	return -1


func region_tocada(indice: int) -> bool:
	return _tocadas.has(indice)


## ¿El punto esta en la zona con nombre? Primero las `zonas` del tema; si no, la region del fondo.
func en_zona(punto: Vector2, zona: String) -> bool:
	if zona == "":
		return true
	if zonas.has(zona):
		var r: Array = zonas[zona]
		return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(punto)
	var i := region_por_id(zona)
	if i >= 0:
		return Geometry2D.is_point_in_polygon(punto, lamina["regiones"][i]["poligono"])
	# Ampliacion del catalogo: `en_zona` tambien acepta un sticker-lugar (dentro de su radio).
	for lugar: StickerVivo in lugares():
		if lugar.id == zona and _distancia_a_lugar(lugar, punto) <= 0.0:
			return true
	return false


# ---------------------------------------------------------------------------
# Zoom (pinza de dos dedos, rueda del mouse o lupa)
# ---------------------------------------------------------------------------

## Acerca o aleja manteniendo fijo el punto de PANTALLA `ancla` (coordenadas del padre).
func aplicar_zoom(nuevo: float, ancla: Vector2) -> void:
	if not zoom_permitido:
		nuevo = 1.0
	nuevo = clampf(nuevo, 1.0, ZOOM_MAX)
	var mundo := (ancla - position) / zoom
	zoom = nuevo
	scale = Vector2(zoom, zoom)
	position = _limitar(ancla - mundo * zoom)
	zoom_cambiado.emit(zoom)


## Desplaza la vista (arrastre con dos dedos), sin salirse del papel.
func desplazar(delta_pantalla: Vector2) -> void:
	position = _limitar(position + delta_pantalla)


## Lupa (GDD §6.4: sin gestos complejos): con la lupa armada, el toque acerca al doble ahi.
func usar_lupa_en(punto_mundo: Vector2) -> void:
	lupa_armada = false
	aplicar_zoom(2.0, a_pantalla(punto_mundo))


func ver_todo() -> void:
	zoom = 1.0
	scale = Vector2.ONE
	position = Vector2.ZERO
	zoom_cambiado.emit(zoom)


func _limitar(pos: Vector2) -> Vector2:
	var minimo := Vector2(tamano) - Vector2(tamano) * zoom
	return Vector2(clampf(pos.x, minimo.x, 0.0), clampf(pos.y, minimo.y, 0.0))


## Punto del mundo (lienzo) a pantalla (coordenadas del padre) y al reves.
func a_pantalla(p: Vector2) -> Vector2:
	return position + p * zoom


func a_mundo(p: Vector2) -> Vector2:
	return (p - position) / zoom


# ---------------------------------------------------------------------------
# Entrada unificada (mouse y dedo: el toque se emula como mouse, GDD §6.4)
# ---------------------------------------------------------------------------

func _gui_input(evento: InputEvent) -> void:
	if bloqueado:
		return
	if evento is InputEventMouseButton and evento.pressed and evento.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if zoom_permitido and not _presionado:
			aplicar_zoom(zoom * (1.15 if evento.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), a_pantalla(evento.position))
		accept_event()
		return
	if en_gesto:
		accept_event()
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed and lupa_armada:
			usar_lupa_en(evento.position)
			accept_event()
			return
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
	_puestos_trazo.clear()
	_trazo_min_y = punto.y
	_trazo_max_y = punto.y
	usos[herramienta] = int(usos.get(herramienta, 0)) + 1
	# Respaldo de la pintura: si llega un segundo dedo, el trazo se deshace (dos dedos nunca pintan).
	_respaldo.copy_from(_pintura)
	if stickers_objeto and mosaico.is_empty():
		var tocado: StickerVivo = sticker_en(punto) if not herramienta.begins_with("camino_") and herramienta != "conector" else null
		if tocado != null and herramienta not in ["goma", "balde"]:
			_arrastre = tocado
			_arrastre_desfase = tocado.centro() - punto
			_arrastre_recorrido = 0.0
			_arrastre_inicio = tocado.centro()
			_bajar(tocado)
			_capa_sellos.move_child(tocado, -1)
		toque_iniciado.emit()
		if herramienta.begins_with("camino_") or herramienta == "conector":
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
	if distancia < 0.5 / zoom:
		return
	_quieto = 0.0
	if _arrastre != null:
		_arrastre_recorrido += distancia * zoom
		if is_instance_valid(_arrastre):
			_arrastre.poner_en((punto + _arrastre_desfase).clamp(Vector2.ZERO, Vector2(tamano)))
		_ultimo = punto
		return
	if not _camino_actual.is_empty():
		if _camino_actual[_camino_actual.size() - 1].distance_to(punto) >= 6.0 / zoom:
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
		if _recorrido >= _lado_mundo() * 1.1:
			_recorrido = 0.0
			_poner_sello(herramienta.trim_prefix("sello_"), punto)
		_ultimo = punto
		return
	if herramienta != "goma":
		recorrido_pintado += distancia
		_trazo_min_y = minf(_trazo_min_y, punto.y)
		_trazo_max_y = maxf(_trazo_max_y, punto.y)
		if _trazo_min_y < tamano.y / 3.0 and _trazo_max_y > tamano.y * 2.0 / 3.0:
			trazo_cruzo_franjas = true
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
	if not _presionado:
		return
	_presionado = false
	_puestos_trazo.clear()
	if _arrastre != null:
		var sticker := _arrastre
		_arrastre = null
		if is_instance_valid(sticker):
			if _arrastre_recorrido < TOLERANCIA_TOQUE:
				sticker_tocado.emit(sticker)
				if sticker.clase == "vivo":
					intentar_subir(sticker)
			else:
				if sticker.clase == "lugar":
					# Un lugar movido se despega de sus caminos (no quedan puntas colgando en el aire).
					for camino: Dictionary in caminos:
						if camino["desde"] == sticker:
							camino["desde"] = null
						if camino["hasta"] == sticker:
							camino["hasta"] = null
				sticker_cambiado.emit()
				intentar_subir(sticker)
				_revisar_combinaciones(sticker)
	if not _camino_actual.is_empty():
		_cerrar_camino()


## Llega un segundo dedo: deshace lo que hizo el primero en este trazo (pintura, stickers puestos,
## camino a medio trazar, arrastre) y queda en espera hasta que se levanten todos los dedos.
func cancelar_trazo() -> void:
	if not _presionado:
		return
	_presionado = false
	_pintura.copy_from(_respaldo)
	_sucio = true
	for sticker in _puestos_trazo:
		if is_instance_valid(sticker):
			sticker.queue_free()
	_puestos_trazo.clear()
	if _arrastre != null and is_instance_valid(_arrastre):
		_arrastre.poner_en(_arrastre_inicio)
	_arrastre = null
	_camino_actual = PackedVector2Array()
	_capa_caminos.queue_redraw()


func _paso_trazo() -> float:
	var r := radio_pincel / zoom
	match herramienta:
		"pincel_corazon", "pincel_estrella":
			return r * 2.6
		"purpurina":
			return r * 0.9
		"pincel_grueso":
			return r * 0.5
	return maxf(1.5 / zoom, r * 0.3)


func _radio_herramienta() -> float:
	match herramienta:
		"pincel_grueso", "goma":
			return radio_pincel * 1.8 / zoom
	return radio_pincel / zoom


func _lado_mundo() -> float:
	return lado_sello / zoom


func _color_del_trazo() -> Color:
	if herramienta == "arcoiris":
		var tono := fposmod(_recorrido_total / 420.0, 1.0)
		return Color.from_hsv(roundf(tono * 24.0) / 24.0, 0.62, 1.0)
	return color_actual


# ---------------------------------------------------------------------------
# Pintura en la Image
# ---------------------------------------------------------------------------

func _estampar_en(punto: Vector2, _primero: bool) -> void:
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
			var imagen := _calcomania(tipo, color_actual, maxi(8, int(radio_pincel * 2.4 / zoom)))
			for p in puntos:
				Raster.estampar(_pintura, imagen, p)
		"purpurina":
			for p in puntos:
				for i in 3:
					var chispa := _calcomania("destello", [DORADO, Color.WHITE, color_actual.lightened(0.3)][i], maxi(6, int(randf_range(10.0, 20.0) / zoom)))
					Raster.estampar(_pintura, chispa, p + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * radio_pincel * 1.2 / zoom)
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
			lista.append(Vector2(2.0 * centro_simetria.x - punto.x, punto.y))
		"mandala":
			var rel := punto - centro_simetria
			var reflejo := Vector2(rel.x, -rel.y)
			lista.clear()
			for k in 6:
				var angulo := TAU * k / 6.0
				lista.append(centro_simetria + rel.rotated(angulo))
				lista.append(centro_simetria + reflejo.rotated(angulo))
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
		_puestos_trazo.append(sticker)
		sello_puesto.emit(tipo, punto)
		color_usado.emit(sticker.color)
		if sticker.clase == "vivo" and not intentar_subir(sticker) and auto_subir:
			_saltar_al_camino(sticker)
		_revisar_combinaciones(sticker)
		return
	var imagen := _calcomania(tipo, color_actual, maxi(16, int(_lado_mundo())))
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
	_puestos_trazo.append(nodo)
	nodo.scale = Vector2(0.3, 0.3)
	nodo.create_tween().tween_property(nodo, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if cantidad_sellos_vivos() > MAX_SELLOS_VIVOS:
		for hijo in _capa_sellos.get_children():
			if hijo is TextureRect:
				_hornear_sello(hijo)
				break


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
			if hijo is StickerVivo and (hijo.fijo or esta_viajando(hijo)):
				continue
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
	var cuenta := 0
	for hijo in _capa_sellos.get_children():
		if hijo is TextureRect or (hijo is StickerVivo and not hijo.fijo):
			cuenta += 1
	return cuenta


# ---------------------------------------------------------------------------
# Stickers con clase
# ---------------------------------------------------------------------------

func clase_de(id: String) -> String:
	return str(clases.get(id, Stickers.clase(id)))


func poner_sticker(id: String, punto: Vector2, escala_extra := 1.0) -> StickerVivo:
	var sticker := StickerVivo.new()
	var color := color_actual if sticker_con_color_actual else Stickers.color_por_defecto(id)
	sticker.clase = clase_de(id)
	var lado := _lado_mundo() * (Stickers.ESCALA_LUGAR if sticker.clase == "lugar" else 1.0) * escala_extra
	sticker.preparar(id, color, lado)
	_capa_sellos.add_child(sticker)
	sticker.poner_en(punto)
	sticker.aparecer()
	var vivos := stickers()
	if vivos.size() > MAX_STICKERS:
		_hornear_sticker(vivos[0])
	return sticker


## Lugar de fondo (el rio, el lago, el volcan): invisible, solo destino de caminos y viajeros. Su
## `ancla` es donde se pega un camino; si trae `region` (id de una region del fondo), cuenta todo su
## poligono. Un lugar `lineal` (rio, mar) acepta caminos en cualquier punto de su borde.
func poner_lugar_fijo(id: String, centro: Vector2, radio: float, region := "", lineal := false) -> StickerVivo:
	var lugar := StickerVivo.new()
	lugar.clase = "lugar"
	lugar.fijo = true
	lugar.radio_fijo = radio
	lugar.preparar(id, Color.WHITE, radio * 2.0)
	var i := region_por_id(region if region != "" else id)
	if i >= 0:
		lugar.set_meta("poligono", lamina["regiones"][i]["poligono"])
	lugar.set_meta("lineal", lineal)
	_capa_sellos.add_child(lugar)
	lugar.poner_en(centro)
	return lugar


## Distancia de `punto` al lugar: <= 0 si esta adentro (de su region o de su radio).
func _distancia_a_lugar(lugar: StickerVivo, punto: Vector2) -> float:
	var d := punto.distance_to(lugar.centro()) - lugar.radio_toque(zoom)
	if lugar.has_meta("poligono"):
		var poligono: PackedVector2Array = lugar.get_meta("poligono")
		if Geometry2D.is_point_in_polygon(punto, poligono):
			return -1.0
		d = minf(d, _distancia_borde(poligono, punto))
	return d


static func _distancia_borde(poligono: PackedVector2Array, punto: Vector2) -> float:
	var mejor := INF
	for i in poligono.size():
		var q := Geometry2D.get_closest_point_to_segment(punto, poligono[i], poligono[(i + 1) % poligono.size()])
		mejor = minf(mejor, q.distance_to(punto))
	return mejor


## Donde se pega la punta de un camino a ese lugar: en los lugares de fondo con region (rio, lago,
## volcan), donde el nino toco si cayo adentro, o el borde mas cercano si quedo cerca (iman); en los
## stickers-lugar, su centro.
func _punta_en_lugar(lugar: StickerVivo, punto: Vector2) -> Vector2:
	if lugar.has_meta("poligono"):
		var poligono: PackedVector2Array = lugar.get_meta("poligono")
		if Geometry2D.is_point_in_polygon(punto, poligono):
			return punto
		var mejor := punto
		var mejor_d := INF
		for i in poligono.size():
			var q := Geometry2D.get_closest_point_to_segment(punto, poligono[i], poligono[(i + 1) % poligono.size()])
			if q.distance_to(punto) < mejor_d:
				mejor_d = q.distance_to(punto)
				mejor = q
		return mejor
	return lugar.centro()


## Stickers puestos por el nino (sin los lugares fijos ni los que se estan borrando).
func stickers() -> Array:
	var lista: Array = []
	for hijo in _capa_sellos.get_children():
		if hijo is StickerVivo and not hijo.fijo and not hijo.is_queued_for_deletion():
			lista.append(hijo)
	return lista


## Lugares (stickers de clase lugar y lugares fijos).
func lugares() -> Array:
	var lista: Array = []
	for hijo in _capa_sellos.get_children():
		if hijo is StickerVivo and hijo.clase == "lugar" and not hijo.is_queued_for_deletion():
			lista.append(hijo)
	return lista


func lugar_por_id(id: String) -> StickerVivo:
	for lugar: StickerVivo in lugares():
		if lugar.id == id:
			return lugar
	return null


## El sticker de mas arriba bajo `punto` (sin los fijos), o null.
func sticker_en(punto: Vector2) -> StickerVivo:
	var lista := stickers()
	for i in range(lista.size() - 1, -1, -1):
		var sticker: StickerVivo = lista[i]
		if punto.distance_to(sticker.centro()) <= sticker.radio_toque(zoom):
			return sticker
	return null


## El lugar mas cercano a `punto` (adentro o a menos de `extra` px del mundo de su borde), o null.
func lugar_en(punto: Vector2, extra := 0.0) -> StickerVivo:
	var mejor: StickerVivo = null
	var mejor_d := INF
	for lugar: StickerVivo in lugares():
		var d := _distancia_a_lugar(lugar, punto)
		if d <= extra and d < mejor_d:
			mejor = lugar
			mejor_d = d
	return mejor


func arrastrando() -> StickerVivo:
	return _arrastre


func seleccionar(sticker: StickerVivo) -> void:
	if is_instance_valid(seleccionado):
		seleccionado.seleccionado = false
	seleccionado = sticker
	if sticker != null:
		sticker.seleccionado = true


func borrar_sticker(sticker: StickerVivo) -> void:
	if not is_instance_valid(sticker) or sticker.fijo:
		return
	if seleccionado == sticker:
		seleccionado = null
	_bajar(sticker)
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


## Cuantos stickers que cumplen `filtro` hay dentro del camino cerrado mas lleno del tipo `tipo`.
func encerrados(filtro: Callable, tipo := "") -> int:
	var mejor := 0
	for camino: Dictionary in caminos:
		if not bool(camino["cerrado"]) or (tipo != "" and str(camino["tipo"]) != tipo):
			continue
		var cuenta := 0
		for sticker: StickerVivo in stickers():
			if filtro.call(sticker) and Geometry2D.is_point_in_polygon(sticker.centro(), camino["puntos"]):
				cuenta += 1
		mejor = maxi(mejor, cuenta)
	return mejor


## Caminos que unen dos lugares distintos.
func conexiones() -> int:
	var cuenta := 0
	for camino: Dictionary in caminos:
		var desde = camino["desde"]
		var hasta = camino["hasta"]
		if desde != null and hasta != null and desde != hasta and is_instance_valid(desde) and is_instance_valid(hasta):
			cuenta += 1
	return cuenta


func _hornear_sticker(sticker: StickerVivo) -> void:
	_bajar(sticker)
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
# Combinaciones magicas (sol + nube de lluvia en el cielo -> arcoiris)
# ---------------------------------------------------------------------------

## Combinaciones por CONTACTO (lienzo-escenas-retos.md §1.4): al soltar un sticker, si su centro
## queda a <= 0,6 x (radio A + radio B) de otro (o dentro de un lugar de fondo), se prueba la receta
## del par. Recetas de 3: tres instancias dentro de 200 px del ultimo soltado. `en`: el contacto debe
## ocurrir en esa region (si el fondo no la tiene, vale en cualquier parte). `modo`: "efecto" (quedan
## los ingredientes y aparece el resultado), "consume" (se van los de `consume`, o todos),
## "transforma" (el primero se convierte en el resultado). Un resultado que no es sticker es solo un
## efecto (destellos y voz, en el motor).
func _revisar_combinaciones(soltado: StickerVivo = null) -> void:
	if combinaciones.is_empty():
		return
	var candidatos: Array = [soltado] if soltado != null else stickers()
	for nuevo in candidatos:
		if not is_instance_valid(nuevo) or nuevo.is_queued_for_deletion():
			continue
		for datos: Dictionary in combinaciones:
			if _probar_receta(datos, nuevo):
				break


func _probar_receta(datos: Dictionary, nuevo: StickerVivo) -> bool:
	var ingredientes: Array = datos.get("ingredientes", [])
	if not ingredientes.has(nuevo.id):
		return false
	var resultado := str(datos.get("resultado", ""))
	var zona := str(datos.get("en", ""))
	if zona != "" and (region_por_id(zona) >= 0 or zonas.has(zona)) and not en_zona(nuevo.centro(), zona):
		return false
	var elegidos: Array = [nuevo]
	var faltan: Array = ingredientes.duplicate()
	faltan.erase(nuevo.id)
	var todos: Array = stickers() + lugares().filter(func(l) -> bool: return l.fijo)
	for ingrediente in faltan:
		var hallado: StickerVivo = null
		for otro: StickerVivo in todos:
			if otro.id != str(ingrediente) or elegidos.has(otro) or otro.is_queued_for_deletion() or otro.has_meta("magico"):
				continue
			var cerca := false
			if ingredientes.size() >= 3:
				cerca = otro.centro().distance_to(nuevo.centro()) <= 200.0
			elif otro.fijo:
				cerca = _distancia_a_lugar(otro, nuevo.centro()) <= nuevo.radio_toque(zoom) * 0.6
			else:
				cerca = otro.centro().distance_to(nuevo.centro()) <= 0.6 * (otro.radio_toque(zoom) + nuevo.radio_toque(zoom))
			if cerca:
				hallado = otro
				break
		if hallado == null:
			return false
		elegidos.append(hallado)
	var medio := Vector2.ZERO
	for sticker: StickerVivo in elegidos:
		medio += nuevo.centro() if sticker.fijo else sticker.centro()
		if not sticker.fijo:
			sticker.saltar()
	medio /= elegidos.size()
	var modo := str(datos.get("modo", "efecto"))
	var consume: Array = datos.get("consume", ingredientes if modo == "consume" else [])
	var posicion := medio
	if Stickers.tiene(resultado):
		if modo == "transforma":
			var base: StickerVivo = nuevo
			for sticker: StickerVivo in elegidos:
				if sticker.id == str(ingredientes[0]) and not sticker.fijo:
					base = sticker
			posicion = base.centro()
			_bajar(base)
			base.queue_free()
			var nacido := poner_sticker(resultado, posicion)
			_animar_magico(nacido, false)
			if nacido.clase == "vivo" and not intentar_subir(nacido) and auto_subir:
				_saltar_al_camino(nacido)
		else:
			var magico := poner_sticker(resultado, medio + Vector2(0, float(datos.get("bajo", 0.0))), float(datos.get("escala", 1.0)))
			# El resultado de un "efecto" (el arcoiris) es adorno animado; el de "consume" (la nube de
			# lluvia) es un sticker normal que sigue combinando (cadena C02 -> C01).
			if modo == "efecto":
				magico.set_meta("magico", true)
			_animar_magico(magico, modo == "efecto")
			posicion = magico.centro()
	for sticker: StickerVivo in elegidos:
		if not sticker.fijo and consume.has(sticker.id) and is_instance_valid(sticker) and not sticker.is_queued_for_deletion():
			_bajar(sticker)
			sticker.queue_free()
	combinacion.emit(resultado, posicion)
	return true


## El resultado de una combinacion crece desde cero y despues "respira" (arcoiris animado).
func _animar_magico(nodo: StickerVivo, respira := true) -> void:
	nodo.scale = Vector2.ZERO
	nodo.modulate.a = 0.0
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(nodo, "scale", Vector2.ONE * nodo.escala * 1.15, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo, "scale", Vector2.ONE * nodo.escala, 0.3)
	if not respira:
		return
	var latido := nodo.create_tween().set_loops()
	latido.tween_interval(0.9)
	latido.tween_property(nodo, "rebote", nodo.lado * 0.05, 0.6).set_trans(Tween.TRANS_SINE)
	latido.tween_property(nodo, "rebote", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


# ---------------------------------------------------------------------------
# Caminos y viajes de los vivos
# ---------------------------------------------------------------------------

func _cerrar_camino() -> void:
	var crudo := _camino_actual
	_camino_actual = PackedVector2Array()
	var tipo := herramienta.trim_prefix("camino_") if herramienta.begins_with("camino_") else str(conector.get("tipo", tipo_camino))
	agregar_camino(crudo, tipo, true)


## Agrega un camino (trazado o inicial del tema): suaviza, pega las puntas a los lugares y detecta
## circuitos. Devuelve el camino o {} si era demasiado corto.
func agregar_camino(crudo: PackedVector2Array, tipo: String, avisar := true) -> Dictionary:
	var puntos := remuestrear(suavizar(crudo), 10.0 / zoom)
	var largo := _largo(puntos)
	if puntos.size() < 2 or largo < 50.0 / zoom:
		_capa_caminos.queue_redraw()
		return {}
	var desde := lugar_en(crudo[0], iman / zoom)
	var hasta := lugar_en(crudo[crudo.size() - 1], iman / zoom)
	if desde == hasta and desde != null:
		# Las dos puntas en el mismo lugar: se pega la mas cercana.
		if _distancia_a_lugar(desde, crudo[0]) <= _distancia_a_lugar(desde, crudo[crudo.size() - 1]):
			hasta = null
		else:
			desde = null
	if desde != null:
		puntos = _pegar_punta(puntos, _punta_en_lugar(desde, crudo[0]))
	if hasta != null:
		puntos.reverse()
		puntos = _pegar_punta(puntos, _punta_en_lugar(hasta, crudo[crudo.size() - 1]))
		puntos.reverse()
	var cerrado := desde == null and hasta == null and largo > cierre_largo / zoom and puntos[0].distance_to(puntos[puntos.size() - 1]) <= cierre_distancia / zoom
	if cerrado:
		puntos.append(puntos[0])
	var camino := {"puntos": puntos, "tipo": tipo, "desde": desde, "hasta": hasta, "cerrado": cerrado,
		"largos": _largos(puntos), "k": 1.0 / zoom, "n": _numero_camino}
	_numero_camino += 1
	caminos.append(camino)
	if caminos.size() > MAX_CAMINOS:
		var viejo: Dictionary = caminos.pop_front()
		for v: Dictionary in _viajes.duplicate():
			if v["camino"] == viejo:
				_terminar_viaje(v)
	_capa_caminos.queue_redraw()
	for punta in [desde, hasta]:
		if punta != null and not punta.fijo:
			punta.saltar()
	if avisar:
		camino_creado.emit(desde, hasta, camino)
		if auto_subir and not tipo in SIN_VIAJEROS:
			_subir_mas_cercano(camino)
	return camino


## Pega el inicio del camino en `ancla` sin dejar un gancho: descarta los primeros puntos (hasta un
## tercio del trazo) que quedan detras del punto mas cercano al ancla.
static func _pegar_punta(puntos: PackedVector2Array, ancla: Vector2) -> PackedVector2Array:
	var limite := maxi(1, puntos.size() / 3)
	var mejor := 0
	for i in limite:
		if puntos[i].distance_to(ancla) < puntos[mejor].distance_to(ancla):
			mejor = i
	var salida := puntos.slice(mejor)
	salida[0] = ancla
	return remuestrear(salida, 10.0)


## R2 en Semilla: el vivo libre mas cercano al camino salta solo a su punta mas cercana y lo recorre.
func _subir_mas_cercano(camino: Dictionary) -> void:
	var mejor: StickerVivo = null
	var mejor_d := INF
	for sticker: StickerVivo in stickers():
		if sticker.clase != "vivo" or esta_viajando(sticker):
			continue
		var d: float = _mas_cercano(camino, sticker.centro())[1]
		if d < mejor_d:
			mejor = sticker
			mejor_d = d
	if mejor != null:
		_saltar_a(mejor, camino)


## Un vivo recien puesto salta al camino (con viajeros) mas cercano.
func _saltar_al_camino(vivo: StickerVivo) -> void:
	var mejor: Dictionary = {}
	var mejor_d := INF
	for camino: Dictionary in caminos:
		if str(camino["tipo"]) in SIN_VIAJEROS:
			continue
		var d: float = _mas_cercano(camino, vivo.centro())[1]
		if d < mejor_d:
			mejor = camino
			mejor_d = d
	if not mejor.is_empty():
		_saltar_a(vivo, mejor)


## Saltito hasta la punta mas cercana del camino y se sube.
func _saltar_a(vivo: StickerVivo, camino: Dictionary) -> void:
	var puntos: PackedVector2Array = camino["puntos"]
	var inicio := puntos[0]
	var fin := puntos[puntos.size() - 1]
	var destino := inicio if vivo.centro().distance_to(inicio) <= vivo.centro().distance_to(fin) else fin
	if bool(camino["cerrado"]):
		destino = punto_en(camino, _mas_cercano(camino, vivo.centro())[0])
	vivo.set_meta("saltando", true)
	var tween := vivo.create_tween()
	tween.tween_property(vivo, "position", destino - vivo.size / 2.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(vivo):
			vivo.remove_meta("saltando")
			intentar_subir(vivo))


## Un vivo soltado sobre (o cerca de) un camino se sube y lo recorre. Si se suelta sobre un lugar
## con caminos, sale por uno de ellos. Devuelve true si se subio.
func intentar_subir(vivo: StickerVivo) -> bool:
	if not is_instance_valid(vivo) or vivo.clase != "vivo" or caminos.is_empty():
		return false
	if esta_viajando(vivo):
		return true
	var p := vivo.centro()
	var mejor: Dictionary = {}
	var mejor_s := 0.0
	var mejor_d := INF
	var lugar := lugar_en(p, 8.0 / zoom)
	for camino: Dictionary in caminos:
		if str(camino["tipo"]) in SIN_VIAJEROS:
			continue
		if lugar != null and (camino["desde"] == lugar or camino["hasta"] == lugar):
			# Soltado sobre un lugar con caminos: sale por el primero de ellos.
			if mejor_d > 0.0:
				mejor = camino
				mejor_s = 0.0 if camino["desde"] == lugar else (camino["largos"] as PackedFloat32Array)[-1]
				mejor_d = 0.0
			continue
		var cerca := _mas_cercano(camino, p)
		if cerca[1] < mejor_d:
			mejor = camino
			mejor_s = cerca[0]
			mejor_d = cerca[1]
	if mejor.is_empty() or mejor_d > radio_subida / zoom:
		return false
	var total: float = (mejor["largos"] as PackedFloat32Array)[-1]
	var margen := maxf(60.0, total * 0.2)
	var dir := 1.0
	var inicio: StickerVivo = null
	if not bool(mejor["cerrado"]):
		if mejor_s <= margen and mejor["desde"] != null:
			inicio = mejor["desde"]
			dir = 1.0
		elif mejor_s >= total - margen and mejor["hasta"] != null:
			inicio = mejor["hasta"]
			dir = -1.0
		elif mejor["hasta"] != null and (mejor["desde"] == null or total - mejor_s > mejor_s):
			dir = 1.0
		elif mejor["desde"] != null:
			dir = -1.0
		else:
			dir = 1.0 if total - mejor_s > mejor_s else -1.0
	if _viajes.size() >= MAX_VIAJES:
		_terminar_viaje(_viajes[0])
	# R3: la primera llegada se registra "desde" el lugar donde se subio.
	_viajes.append({"nodo": vivo, "camino": mejor, "s": mejor_s, "dir": dir, "inicio": inicio, "piernas": 0,
		"pausa": 0.0, "vueltas": 0, "andado": 0.0, "ultimo_lugar": inicio})
	vivo.set_meta("viajando", true)
	vivo.saltar()
	vivo_subio.emit(vivo)
	return true


func esta_viajando(vivo: Control) -> bool:
	for v: Dictionary in _viajes:
		if v["nodo"] == vivo:
			return true
	return false


func _bajar(vivo: Control) -> void:
	for v: Dictionary in _viajes.duplicate():
		if v["nodo"] == vivo:
			_terminar_viaje(v)


func _terminar_viaje(v: Dictionary) -> void:
	_viajes.erase(v)
	var nodo = v["nodo"]
	if is_instance_valid(nodo):
		nodo.remove_meta("viajando")
		nodo.rotation = 0.0
		nodo.rebote = 0.0


## [s, distancia] del punto del camino mas cercano a `p`.
static func _mas_cercano(camino: Dictionary, p: Vector2) -> Array:
	var puntos: PackedVector2Array = camino["puntos"]
	var largos: PackedFloat32Array = camino["largos"]
	var mejor_s := 0.0
	var mejor_d := INF
	for i in range(1, puntos.size()):
		var q := Geometry2D.get_closest_point_to_segment(p, puntos[i - 1], puntos[i])
		var d := q.distance_to(p)
		if d < mejor_d:
			mejor_d = d
			mejor_s = largos[i - 1] + puntos[i - 1].distance_to(q)
	return [mejor_s, mejor_d]


func viajeros() -> Array:
	var lista: Array = []
	for v: Dictionary in _viajes:
		if is_instance_valid(v["nodo"]):
			lista.append(v["nodo"])
	return lista


func _mover_viajeros(delta: float) -> void:
	for v: Dictionary in _viajes.duplicate():
		var nodo: StickerVivo = v["nodo"]
		if not is_instance_valid(nodo) or nodo.is_queued_for_deletion():
			_viajes.erase(v)
			continue
		if nodo == _arrastre:
			continue
		if float(v["pausa"]) > 0.0:
			v["pausa"] = float(v["pausa"]) - delta
			nodo.rebote = absf(sin(_tiempo * 14.0)) * nodo.lado * 0.05
			continue
		var camino: Dictionary = v["camino"]
		var largos: PackedFloat32Array = camino["largos"]
		var total := largos[largos.size() - 1]
		var avance := VELOCIDAD_VIAJERO * delta
		var s: float = v["s"] + v["dir"] * avance
		if bool(camino["cerrado"]):
			v["andado"] = float(v["andado"]) + avance
			if float(v["andado"]) >= total:
				v["andado"] = float(v["andado"]) - total
				v["vueltas"] = int(v["vueltas"]) + 1
				nodo.saltar()
				vuelta.emit(nodo, int(v["vueltas"]))
			s = fposmod(s, total)
		elif s >= total or s <= 0.0:
			s = clampf(s, 0.0, total)
			v["s"] = s
			nodo.poner_en(punto_en(camino, s))
			_llegar_a_punta(v, camino["hasta"] if s >= total else camino["desde"])
			continue
		v["s"] = s
		var p := punto_en(camino, s)
		var adelante := s + float(v["dir"]) * 8.0
		adelante = fposmod(adelante, total) if bool(camino["cerrado"]) else clampf(adelante, 0.0, total)
		var tangente := punto_en(camino, adelante) - p
		if absf(tangente.x) > 0.5 or absf(tangente.y) > 0.5:
			_orientar(nodo, tangente, delta)
		nodo.poner_en(p)
		if not nodo.id in Stickers.ROTAN:
			nodo.rebote = absf(sin(_tiempo * 9.0 + s * 0.01)) * nodo.lado * 0.08


## El viajero llego a una punta del camino: si es un lugar, avisa la llegada y se queda un momento;
## despues sigue por otro camino de ese lugar (si hay) o se da vuelta. Se baja al volver a su lugar
## de partida (o tras 8 tramos, para que nunca quede dando vueltas para siempre).
func _llegar_a_punta(v: Dictionary, lugar) -> void:
	var nodo: StickerVivo = v["nodo"]
	var camino: Dictionary = v["camino"]
	v["piernas"] = int(v["piernas"]) + 1
	if lugar == null or not is_instance_valid(lugar):
		v["dir"] = -float(v["dir"])
		if int(v["piernas"]) >= 8:
			_terminar_viaje(v)
		return
	var desde = v.get("ultimo_lugar", null)
	if desde != null and not is_instance_valid(desde):
		desde = null
	nodo.saltar()
	if not lugar.fijo:
		lugar.saltar()
	llegada.emit(nodo, lugar, desde)
	v["ultimo_lugar"] = lugar
	# Recetas vivo + lugar al llegar (p. ej. el camion de bomberos llega al fuego).
	if not combinaciones.is_empty() and is_instance_valid(nodo):
		for datos: Dictionary in combinaciones:
			if (datos.get("ingredientes", []) as Array).has(lugar.id) and _probar_receta(datos, nodo):
				break
	if not is_instance_valid(nodo) or nodo.is_queued_for_deletion():
		return
	v["pausa"] = PAUSA_LLEGADA
	if v["inicio"] == null:
		v["inicio"] = lugar
	elif lugar == v["inicio"] and int(v["piernas"]) >= 2 or int(v["piernas"]) >= 8:
		_terminar_viaje(v)
		# Se baja a un costado del lugar para no volver a subirse solo.
		nodo.poner_en(lugar.centro() + Vector2(lugar.radio_toque(zoom) * 0.6 + nodo.lado * 0.3, nodo.lado * 0.25))
		return
	# Redes de caminos: sigue por otro camino de este lugar (el que menos uso), si hay.
	var otros: Array = []
	for otro: Dictionary in caminos:
		if otro != camino and not bool(otro["cerrado"]) and not str(otro["tipo"]) in SIN_VIAJEROS and (otro["desde"] == lugar or otro["hasta"] == lugar):
			otros.append(otro)
	if not otros.is_empty():
		# R4: sigue por uno que no sea por el que vino; si hay varios, el mas reciente.
		otros.sort_custom(func(a, b) -> bool: return int(a["n"]) > int(b["n"]))
		var siguiente: Dictionary = otros[0]
		v["camino"] = siguiente
		if siguiente["desde"] == lugar:
			v["s"] = 0.0
			v["dir"] = 1.0
		else:
			v["s"] = (siguiente["largos"] as PackedFloat32Array)[-1]
			v["dir"] = -1.0
		return
	v["dir"] = -float(v["dir"])


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


static func suavizar(puntos: PackedVector2Array) -> PackedVector2Array:
	if puntos.size() < 3:
		return puntos
	var salida := PackedVector2Array([puntos[0]])
	for i in puntos.size() - 1:
		salida.append(puntos[i].lerp(puntos[i + 1], 0.25))
		salida.append(puntos[i].lerp(puntos[i + 1], 0.75))
	salida.append(puntos[puntos.size() - 1])
	return salida


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
		dibujar_camino(_capa_caminos, camino["puntos"], camino["tipo"], float(camino.get("k", 1.0)))
	if _camino_actual.size() >= 2:
		var tipo := herramienta.trim_prefix("camino_") if herramienta.begins_with("camino_") else str(conector.get("tipo", tipo_camino))
		dibujar_camino(_capa_caminos, _camino_actual, tipo, 1.0 / zoom)


## Dibuja un camino (tipo "camino"/"carretera" = pista con linea blanca) sobre cualquier CanvasItem o Grabador (pantalla, PNG e icono de
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
# Pista fantasma de Coco
# ---------------------------------------------------------------------------

## Muestra una pista translucida unos segundos: {"tipo": "camino", "puntos"} (punteado animado del
## lugar A al B), {"tipo": "sticker", "id", "pos"} (un sticker translucido que late), {"tipo": "zona",
## "indice"} (el borde de una region que parpadea) o {"tipo": "circuito", "centro", "radios"}.
func mostrar_fantasma(datos: Dictionary, segundos := 4.0) -> void:
	_fantasma = datos
	_fantasma_resta = segundos
	_capa_fantasma.queue_redraw()


func fantasma_activo() -> Dictionary:
	return _fantasma


func _dibujar_fantasma() -> void:
	if _fantasma.is_empty():
		return
	var alfa := clampf(_fantasma_resta, 0.0, 1.0) * (0.55 + 0.3 * sin(_tiempo * 6.0))
	var blanco := Color(1, 1, 1, alfa)
	var oscuro := Color(COLOR_CONTORNO, alfa * 0.8)
	match str(_fantasma.get("tipo", "")):
		"camino", "circuito":
			var puntos: PackedVector2Array = _fantasma.get("puntos", PackedVector2Array())
			if puntos.size() < 2:
				return
			var desfase := fposmod(_tiempo * 60.0, 36.0)
			for muestra: Array in a_lo_largo(puntos, 36.0 / zoom):
				var p: Vector2 = muestra[0] + muestra[1] * desfase / zoom
				_capa_fantasma.draw_circle(p, 11.0 / zoom, oscuro)
				_capa_fantasma.draw_circle(p, 7.5 / zoom, blanco)
			# Una manito que recorre el camino: "dibuja por aqui".
			var total := _largo(puntos)
			var t := fposmod(_tiempo * 0.35, 1.0)
			var mano := punto_en({"puntos": puntos, "largos": _largos(puntos)}, t * total)
			Figura.dibujar(_capa_fantasma, "estrella", Color(DORADO, alfa), mano, 20.0 / zoom, false)
			var id := str(_fantasma.get("viajero", ""))
			if id != "" and Stickers.tiene(id):
				_capa_fantasma.draw_set_transform(mano + Vector2(0, -30.0 / zoom), 0.0, Vector2.ONE)
				Stickers.dibujar(_capa_fantasma, id, Color(Stickers.color_por_defecto(id), alfa), Vector2.ZERO, 34.0 / zoom)
				_capa_fantasma.draw_set_transform(Vector2.ZERO)
		"sticker":
			var id := str(_fantasma.get("id", ""))
			var pos: Vector2 = _fantasma.get("pos", Vector2(tamano) / 2.0)
			var r := lado_sello * 0.5 / zoom * (1.0 + 0.08 * sin(_tiempo * 5.0))
			_capa_fantasma.draw_circle(pos, r * 1.25, Color(1, 1, 1, alfa * 0.35))
			_capa_fantasma.draw_arc(pos, r * 1.25, 0.0, TAU, 40, oscuro, 4.0 / zoom, true)
			if Stickers.tiene(id):
				# El sticker translucido: se dibuja y se tapa con un velo blanco.
				Stickers.dibujar(_capa_fantasma, id, Stickers.color_por_defecto(id), pos, r * 0.9)
				_capa_fantasma.draw_circle(pos, r * 1.05, Color(1, 1, 1, 0.45))
		"celda":
			var celda: Vector2i = _fantasma.get("celda", Vector2i.ZERO)
			var rect := Rect2(_origen_mosaico + Vector2(celda) * _lado_celda, Vector2.ONE * _lado_celda).grow(4.0)
			_capa_fantasma.draw_rect(rect, Color(DORADO, alfa), false, 7.0 / zoom)
			_capa_fantasma.draw_rect(rect.grow(-3.0), blanco, false, 3.0 / zoom)
		"guia":
			# Espejo y mandala: el contorno de la guia parpadea ("pinta por aqui").
			for region: Dictionary in guia.get("regiones", []):
				var contorno: PackedVector2Array = region["poligono"].duplicate()
				contorno.append(contorno[0])
				_capa_fantasma.draw_polyline(contorno, Color(DORADO, alfa), 7.0 / zoom, true)
		"zona":
			var i := int(_fantasma.get("indice", -1))
			var regiones: Array = lamina.get("regiones", [])
			if i < 0 or i >= regiones.size():
				return
			var poligono: PackedVector2Array = regiones[i]["poligono"].duplicate()
			poligono.append(poligono[0])
			_capa_fantasma.draw_polyline(poligono, Color(DORADO, alfa), 9.0 / zoom, true)
			_capa_fantasma.draw_polyline(poligono, blanco, 4.0 / zoom, true)


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
			if not _tocadas.has(indice):
				_tocadas[indice] = true
				region_rellenada.emit(indice, nuevo)
				color_usado.emit(nuevo)
				_revisar_completa()
			return
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


## Mecanicas HE-40 #20: el pincel pinta la celda mas cercana dentro de `RADIO_CELDA` px.
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
	return Vector2i(x, y) if punto.distance_to(dentro) <= RADIO_CELDA / zoom else Vector2i(-1, -1)


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
				var tam := tam_letra if not pintada else int(tam_letra * 0.55)
				var color_numero := Color(COLOR_CONTORNO, 0.75) if not pintada else Color(1, 1, 1, 0.85)
				var base := rect.get_center() + Vector2(-_lado_celda / 2.0, tam * 0.36) if not pintada else rect.position + Vector2(3, tam + 1)
				var ancho := _lado_celda if not pintada else -1.0
				draw_string(_fuente, base, fila[x], HORIZONTAL_ALIGNMENT_CENTER if not pintada else HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, color_numero)
	var marco := Rect2(_origen_mosaico, Vector2(str(filas[0]).length() if not filas.is_empty() else 0, filas.size()) * _lado_celda)
	draw_rect(marco, COLOR_CONTORNO, false, 4.0)


func _dibujar_guias() -> void:
	var color := Color(COLOR_CONTORNO, 0.28)
	var alto := area_segura.size.y if _escala_lamina != 1.0 else float(tamano.y)
	match simetria:
		"espejo":
			var x := centro_simetria.x
			var y := centro_simetria.y - alto / 2.0 + 6.0
			while y < centro_simetria.y + alto / 2.0:
				_capa_guias.draw_line(Vector2(x, y), Vector2(x, y + 14.0), color, 4.0, true)
				y += 26.0
		"mandala":
			for k in 6:
				var dir := Vector2.from_angle(TAU * k / 6.0 + PI / 6.0)
				_capa_guias.draw_line(centro_simetria, centro_simetria + dir * alto * 0.49, color, 2.5, true)
			_capa_guias.draw_arc(centro_simetria, alto * 0.49, 0.0, TAU, 72, color, 3.0, true)


# ---------------------------------------------------------------------------
# Guardado
# ---------------------------------------------------------------------------

## Compone el dibujo completo (papel + lamina/mosaico + pintura + caminos + stickers) en una Image.
## No usa el renderer: funciona igual en la tablet que headless. Siempre a 1280x720, sin zoom.
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
			dibujar_camino(grabador, camino["puntos"], camino["tipo"], float(camino.get("k", 1.0)))
		grabador.volcar(imagen)
	for nodo in _capa_sellos.get_children():
		if nodo.is_queued_for_deletion():
			continue
		if nodo is StickerVivo:
			if nodo.fijo:
				continue
			Raster.estampar(imagen, _imagen_sticker(nodo), nodo.centro() + Vector2(0, -nodo.rebote * nodo.escala))
			continue
		var sello: Image = nodo.get_meta("imagen")
		if nodo.flip_h:
			sello = sello.duplicate()
			sello.flip_x()
		Raster.estampar(imagen, sello, nodo.position + nodo.size / 2.0)
	return imagen


func guardar_png(ruta: String) -> Error:
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	return componer().save_png(ruta)


## Pixeles de pintura no transparentes (para QA).
func pixeles_pintados() -> int:
	var cuenta := 0
	for y in range(0, tamano.y, 4):
		for x in range(0, tamano.x, 4):
			if _pintura.get_pixel(x, y).a > 0.1:
				cuenta += 1
	return cuenta
