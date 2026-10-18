extends Control

## Lienzo del motor `lienzo_libre` (docs/fichas/motor-lienzo-libre.md §4, §8 y §9 "Lienzo v2").
##
## LIENZO V2 (17-Oct-2026): ocupa la pantalla completa (1280x720) y se puede ACERCAR (zoom con pinza,
## rueda o lupa). Con zoom, el pincel y los stickers nuevos conservan su tamano EN PANTALLA: en el
## mundo quedan mas chicos (mas detalle). Las laminas de 824x530 (zonas 2-5) se encuadran con escala
## uniforme en `area_segura`, la parte del papel que no tapan los botones de las esquinas.
##
## MUNDO GRANDE (ficha §12, 17-Oct-2026): en las hojas con tema de Nicole y Sofia el mundo mide
## `escala_mundo` (2) veces la pantalla: 2560x1440. El fondo, sus zonas y las posiciones del tema se
## escalan; stickers, pincel y caminos NO (miden en pantalla lo mismo que antes al zoom 1, el de
## arranque). Zoom 1 = 1 px del mundo por px de pantalla; se aleja hasta ver la hoja entera
## (`zoom_minimo()`, 0,5) y se acerca hasta `zoom_maximo()` (2). Maxi y las hojas de colorear: 1x.
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
## Fisica (ficha §10): un sticker que pesa empieza a caer / aterriza ("¡puff!"); `grande` en Maxi.
signal caida_iniciada(sticker: Control)
signal aterrizo(sticker: Control, grande: bool)
## El sol soltado fuera del cielo tizno a `cuantos` stickers y vuela de vuelta; despues llega al cielo.
signal sol_quemo(sol: Control, cuantos: int)
signal sol_en_el_cielo(sol: Control)
## Deshacer: cuantos pasos quedan en el historial (0 = boton apagado).
signal historial_cambiado(pasos: int)
## Un camino se borro entero (goma o dedo quieto con la herramienta de camino), ficha §11.1.
signal camino_borrado(camino: Dictionary)
## Un personaje se subio a un animal o vehiculo (ficha §11.9).
signal montado(jinete: Control, montura: Control)

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
## Mundo grande (ficha §12): pantalla base, tope del zoom y segundos del paseo de la camara.
const TAMANO_PANTALLA := Vector2i(1280, 720)
const ZOOM_MAX_MUNDO_GRANDE := 2.0
const SEGUNDOS_ENFOQUE := 0.6
## Pintura en mosaicos: al pintar solo se sube a la GPU el pedazo tocado (no la Image entera).
const LADO_MOSAICO := Vector2i(640, 360)
## Caminos que adornan o encierran pero no llevan viajeros (R6 de lienzo-escenas-retos.md; la cerca
## se agrega por delegacion: es el corral, no un camino para pasear).
const SIN_VIAJEROS := ["guirnalda", "cerca"]
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const DORADO := Color("#FFCB3D")
## Fisica (ficha §10): aceleracion de la caida en px/s² (Maxi, mas lenta) y tope de velocidad.
const GRAVEDAD := 2600.0
const GRAVEDAD_SEMILLA := 1500.0
const VELOCIDAD_MAX_CAIDA := 2400.0
## Sol fuera del cielo: radio del tiznado (px del mundo), segundos que dura y del vuelo de vuelta.
const RADIO_TIZNE := 180.0
const SEGUNDOS_TIZNE := 3.0
const SEGUNDOS_VUELO_SOL := 1.1
const COLOR_TIZNE := Color(0.42, 0.37, 0.35)
## Deshacer: pasos que se recuerdan.
const MAX_PASOS := 20
## Ficha §11.2: grosor de los caminos (factor del ancho de su seccion; antes 1.0). Maxi, algo mas anchos.
const ANCHO_CAMINO := 0.55
const ANCHO_CAMINO_SEMILLA := 0.7
## Ficha §11.1: con la herramienta de camino, el dedo quieto este tiempo sobre un camino lo borra.
const SEGUNDOS_BORRAR_CAMINO := 1.2

var tamano := Vector2i(1280, 720)
## Cuantas pantallas mide el mundo por lado (1 = como la pantalla; 2 = mundo grande, ficha §12).
var escala_mundo := 1.0
## Parte de la PANTALLA libre de botones (sin escalar): ahi se busca mostrar las pistas.
var area_libre := Rect2(Vector2.ZERO, Vector2(1280, 720))
var _tween_vista: Tween
## Pista que quedo esperando a que se levante el dedo para mover la camara.
var _enfoque_pendiente := Rect2()
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
## Grosor de los caminos nuevos (ANCHO_CAMINO o ANCHO_CAMINO_SEMILLA) y segundos del dedo quieto para
## borrar uno con la herramienta de camino.
var ancho_caminos := ANCHO_CAMINO
var segundos_borrar_camino := SEGUNDOS_BORRAR_CAMINO
var _camino_tenido: Dictionary = {}
var _tenido_t := 0.0
var _tenido_inicio := Vector2.ZERO
## Jinetes montados: [{"jinete", "montura", "asiento"}] (ficha §11.9).
var _jinetes: Array = []
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

## FISICA (ficha §10): con cielo y sin ser espacio hay gravedad; `cielo` es el rect de la zona.
var gravedad := false
var cielo := Rect2()
## Maxi: caida mas lenta y "¡puff!" mas grande.
var caida_suave := false
## Fisica por id que fija el tema (`pesan` / `vuelan`); si falta, `Stickers.fisica`.
var fisicas: Dictionary = {}
var _suelos: Array = []  ## poligonos de las regiones de suelo (donde se aterriza)
var _caidas: Array = []  ## [{"nodo", "v", "y_final", "auto"}]
var _polvos: Array = []  ## nubecitas de polvo, humo y chispas: [{"pos", "tipo", "t", "dur", "tam", "partes"}]
var _capa_efectos: Control

## DESHACER (ficha §10.3): pila de fotos del estado ANTES de cada accion; `_inicio` es la hoja recien
## preparada (para reiniciar).
var _historial: Array = []
var _paso_abierto: Dictionary = {}
var _firma_paso := ""
var _pintura_tocada := false
var _inicio: Dictionary = {}

var _pintura: Image
var _respaldo: Image
## Mosaicos de la pintura en pantalla: [{"rect": Rect2i, "imagen": Image, "textura": ImageTexture}].
var _mosaicos_pintura: Array = []
## Parte de la pintura cambiada desde el ultimo cuadro (en px del mundo); vacia = nada que subir.
var _rect_sucio := Rect2i()
## `_sucio = true` marca TODA la pintura (deshacer, hornear); los trazos marcan solo su pedazo.
var _sucio := false:
	set(valor):
		_sucio = valor
		if valor:
			_pintura_tocada = true
			_rect_sucio = Rect2i(Vector2i.ZERO, tamano)
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
	_capa_efectos = _capa(_dibujar_efectos)
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
	if not _caidas.is_empty():
		_mover_caidas(delta)
	if not _jinetes.is_empty():
		_seguir_monturas()
	if _presionado and not _camino_tenido.is_empty():
		_tenido_t += delta
		_capa_caminos.queue_redraw()
		if _tenido_t >= segundos_borrar_camino:
			var camino := _camino_tenido
			_camino_tenido = {}
			_camino_actual = PackedVector2Array()
			borrar_camino(camino)
	if not _polvos.is_empty():
		for polvo: Dictionary in _polvos.duplicate():
			polvo["t"] = float(polvo["t"]) + delta
			if float(polvo["t"]) >= float(polvo["dur"]):
				_polvos.erase(polvo)
		_capa_efectos.queue_redraw()
	if _rect_sucio.has_area():
		_subir_pintura()
	if _enfoque_pendiente.has_area() and not _presionado and not en_gesto:
		var rect := _enfoque_pendiente
		_enfoque_pendiente = Rect2()
		mostrar_en_vista(rect)
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

## Fija el tamano del mundo para la hoja (ficha §12): 1 = la pantalla; 2 = mundo grande (2560x1440).
## Se llama ANTES de `limpiar()` (que crea la pintura del tamano nuevo).
func fijar_escala_mundo(escala: float) -> void:
	escala_mundo = maxf(1.0, escala)
	tamano = Vector2i((Vector2(TAMANO_PANTALLA) * escala_mundo).round())
	custom_minimum_size = Vector2(tamano)
	size = Vector2(tamano)
	for capa in [_capa_caminos, _capa_sellos, _capa_efectos, _capa_guias, _capa_fantasma]:
		if capa != null:
			capa.size = Vector2(tamano)
	area_segura = Rect2(area_libre.position * escala_mundo, area_libre.size * escala_mundo)


## Parte de la pantalla sin botones. En el mundo, `area_segura` es esa misma parte con la hoja entera
## a la vista (escalada por `escala_mundo`).
func fijar_area_libre(rect: Rect2) -> void:
	area_libre = rect
	area_segura = Rect2(rect.position * escala_mundo, rect.size * escala_mundo)


func limpiar() -> void:
	_pintura = Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	_respaldo = Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	_crear_mosaicos_pintura()
	_enfoque_pendiente = Rect2()
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
	gravedad = false
	cielo = Rect2()
	fisicas = {}
	_suelos = []
	_caidas.clear()
	_polvos.clear()
	_jinetes.clear()
	_historial.clear()
	_paso_abierto = {}
	_inicio = {}
	historial_cambiado.emit(0)
	ver_todo()
	queue_redraw()
	_capa_efectos.queue_redraw()
	_capa_guias.queue_redraw()
	_capa_caminos.queue_redraw()
	_capa_fantasma.queue_redraw()


## Fija el encuadre de las laminas: las de otro tamano (824x530) se escalan de forma uniforme y se
## centran en `area_segura`; las que traen `tamano` igual al lienzo quedan tal cual.
func encuadrar(tam_original: Vector2) -> void:
	if tam_original.is_equal_approx(Vector2(tamano)) or tam_original.x <= 0.0:
		_escala_lamina = 1.0
		_desfase_lamina = Vector2.ZERO
	elif tam_original.is_equal_approx(Vector2(TAMANO_PANTALLA)) and escala_mundo > 1.0:
		# Mundo grande (ficha §12): el fondo 16:9 llena el mundo entero.
		_escala_lamina = escala_mundo
		_desfase_lamina = Vector2.ZERO
	else:
		_escala_lamina = minf(area_segura.size.x / tam_original.x, area_segura.size.y / tam_original.y)
		_desfase_lamina = (area_segura.position + (area_segura.size - tam_original * _escala_lamina) / 2.0).round()
	centro_simetria = _desfase_lamina + tam_original * _escala_lamina / 2.0 if _escala_lamina != 1.0 else Vector2(tamano) / 2.0


func escala_lamina() -> float:
	return _escala_lamina


func poner_lamina(datos: Dictionary) -> void:
	lamina = Laminas.encuadrar(Laminas.preparar(datos), _escala_lamina, _desfase_lamina)
	if escala_mundo > 1.0 and is_equal_approx(_escala_lamina, escala_mundo):
		# El contorno del fondo crece con el fondo (con la hoja entera a la vista se ve como antes).
		lamina["escala_trazo"] = escala_mundo
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

## Zoom con el que se ve la hoja ENTERA (1 en el mundo 1x; 0,5 en el mundo grande).
func zoom_minimo() -> float:
	return minf(float(TAMANO_PANTALLA.x) / tamano.x, float(TAMANO_PANTALLA.y) / tamano.y)


func zoom_maximo() -> float:
	return ZOOM_MAX_MUNDO_GRANDE if escala_mundo > 1.0 else ZOOM_MAX


## Zoom "normal" (1 px del mundo = 1 px de pantalla): el de arranque y al que vuelve la lupa.
func zoom_base() -> float:
	return clampf(1.0, zoom_minimo(), zoom_maximo())


## Zoom con el que se CREAN las cosas (pincel, stickers, caminos): con la vista alejada se usa el
## normal, asi lo nuevo no crece en el mundo (alejarse sirve para tener mas lugar, ficha §12.3).
func zoom_trazo() -> float:
	return maxf(zoom, 1.0)


## Acerca o aleja manteniendo fijo el punto de PANTALLA `ancla` (coordenadas del padre).
func aplicar_zoom(nuevo: float, ancla: Vector2) -> void:
	_parar_paseo()
	if not zoom_permitido:
		nuevo = zoom_base()
	nuevo = clampf(nuevo, zoom_minimo(), zoom_maximo())
	var mundo := (ancla - position) / zoom
	zoom = nuevo
	scale = Vector2(zoom, zoom)
	position = _limitar(ancla - mundo * zoom)
	zoom_cambiado.emit(zoom)


## Desplaza la vista (arrastre con dos dedos), sin salirse del papel.
func desplazar(delta_pantalla: Vector2) -> void:
	_parar_paseo()
	position = _limitar(position + delta_pantalla)


## Lupa (GDD §6.4: sin gestos complejos): con la lupa armada, el toque acerca ahi. Desde la hoja
## entera (o algo alejada) va al zoom normal; desde el normal, al doble (ficha §12.4).
func usar_lupa_en(punto_mundo: Vector2) -> void:
	lupa_armada = false
	var destino := zoom_base() if zoom < zoom_base() - 0.01 else zoom_base() * 2.0
	_parar_paseo()
	_poner_vista(destino, punto_mundo)
	zoom_cambiado.emit(zoom)


## "Ver todo": la hoja entera a la vista (en el mundo 1x es volver a 1x).
func ver_todo() -> void:
	_parar_paseo()
	_poner_vista(zoom_minimo(), Vector2(tamano) / 2.0)
	zoom_cambiado.emit(zoom)


## Lupa con zoom: vuelve al zoom normal sin perder lo que se estaba mirando (en el mundo 1x, es
## "ver todo", como antes).
func volver_a_base() -> void:
	_parar_paseo()
	_poner_vista(zoom_base(), centro_de_vista())
	zoom_cambiado.emit(zoom)


## Encuadre de arranque (ficha §12.5). Mundo 1x: la hoja entera. Mundo grande: zoom normal, centrado
## en X y con el horizonte (el borde de abajo del cielo) a un tercio de la altura de la pantalla, asi
## lo primero que se ve es suelo para poner cosas y una franja de cielo arriba. Sin cielo, el centro.
func encuadre_inicial() -> void:
	if escala_mundo <= 1.0 or not zoom_permitido:
		ver_todo()
		return
	var centro := Vector2(tamano) / 2.0
	if cielo.has_area() and cielo.end.y < tamano.y - 4.0:
		centro.y = cielo.end.y - TAMANO_PANTALLA.y / 3.0 + TAMANO_PANTALLA.y / 2.0
	_parar_paseo()
	_poner_vista(zoom_base(), centro)
	zoom_cambiado.emit(zoom)


## Punto del mundo que esta en el centro de la pantalla.
func centro_de_vista() -> Vector2:
	return a_mundo(Vector2(TAMANO_PANTALLA) / 2.0)


## Rect del mundo que se ve en pantalla.
func vista_mundo() -> Rect2:
	return Rect2(a_mundo(Vector2.ZERO), Vector2(TAMANO_PANTALLA) / zoom)


## ¿El rect del mundo se ve entero en la parte de la pantalla sin botones?
func se_ve(rect: Rect2) -> bool:
	return area_libre.encloses(Rect2(a_pantalla(rect.position), rect.size * zoom))


## Mueve la camara suavemente para que se vea `rect` (px del mundo) en la parte sin botones: se
## desplaza y, si no cabe, se aleja (nunca mas que la hoja entera). Si ya se ve, no hace nada. Si hay
## un dedo pintando, espera a que se levante (nunca mueve la hoja debajo del dedo).
func mostrar_en_vista(rect: Rect2) -> void:
	if not zoom_permitido or rect == Rect2():
		return
	rect = rect.grow(24.0 / zoom)
	if se_ve(rect):
		return
	if _presionado or en_gesto:
		_enfoque_pendiente = rect
		return
	var destino_zoom := minf(zoom, minf(area_libre.size.x / maxf(1.0, rect.size.x), area_libre.size.y / maxf(1.0, rect.size.y)))
	destino_zoom = clampf(destino_zoom, zoom_minimo(), zoom_maximo())
	# El centro del rect va al centro de la parte libre de la pantalla. Si el borde de la hoja no deja
	# llevarlo hasta ahi (una pista pegada a una orilla), se prueba alejando un poco mas y se queda el
	# encuadre donde MAS se ve la pista sin botones encima (a igualdad, el mas cercano).
	var centro_libre := area_libre.get_center()
	var hasta_pos := Vector2.ZERO
	var mejor := -1.0
	var z := destino_zoom
	while true:
		var pos := _limitar_con(centro_libre - rect.get_center() * z, z)
		var en_pantalla := Rect2(pos + rect.position * z, rect.size * z)
		var fraccion := en_pantalla.intersection(area_libre).get_area() / maxf(1.0, en_pantalla.get_area())
		if fraccion > mejor + 0.01:
			mejor = fraccion
			destino_zoom = z
			hasta_pos = pos
		if fraccion >= 0.999 or z <= zoom_minimo() + 0.001:
			break
		z = maxf(zoom_minimo(), z * 0.9)
	var desde_zoom := zoom
	var desde_pos := position
	_parar_paseo()
	_tween_vista = create_tween()
	_tween_vista.tween_method(func(k: float) -> void:
		zoom = lerpf(desde_zoom, destino_zoom, k)
		scale = Vector2(zoom, zoom)
		position = _limitar(desde_pos.lerp(hasta_pos, k)), 0.0, 1.0, SEGUNDOS_ENFOQUE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_vista.tween_callback(func() -> void: zoom_cambiado.emit(zoom))


func paseando() -> bool:
	return _tween_vista != null and _tween_vista.is_valid() and _tween_vista.is_running()


func _parar_paseo() -> void:
	if _tween_vista != null and _tween_vista.is_valid():
		_tween_vista.kill()
	_tween_vista = null


## Pone el zoom y deja el punto del mundo `centro` en el centro de la pantalla (sin salirse del papel).
func _poner_vista(nuevo_zoom: float, centro: Vector2) -> void:
	zoom = clampf(nuevo_zoom, zoom_minimo(), zoom_maximo())
	scale = Vector2(zoom, zoom)
	position = _limitar(Vector2(TAMANO_PANTALLA) / 2.0 - centro * zoom)


func _limitar(pos: Vector2) -> Vector2:
	return _limitar_con(pos, zoom)


## Nunca se ve fuera de la hoja: si la hoja (a ese zoom) es mas grande que la pantalla, sus bordes no
## pueden entrar; si cabe, queda centrada.
func _limitar_con(pos: Vector2, z: float) -> Vector2:
	var pantalla := Vector2(TAMANO_PANTALLA)
	var hoja := Vector2(tamano) * z
	var salida := pos
	for eje in 2:
		if hoja[eje] <= pantalla[eje] + 0.01:
			salida[eje] = (pantalla[eje] - hoja[eje]) / 2.0
		else:
			salida[eje] = clampf(pos[eje], pantalla[eje] - hoja[eje], 0.0)
	return salida


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
	# Tambien es la pintura "de antes" del paso que se guarda para deshacer.
	_respaldo.copy_from(_pintura)
	empezar_paso()
	if stickers_objeto and mosaico.is_empty():
		var tocado: StickerVivo = sticker_en(punto) if not herramienta.begins_with("camino_") and herramienta != "conector" else null
		if tocado != null and herramienta not in ["goma", "balde"]:
			# Se puede atrapar en el aire a un sticker que cae o al sol que vuelve al cielo.
			_detener_fisica(tocado)
			# Agarrar al jinete lo baja del montable (§11.9); si se suelta ahi mismo, vuelve a subir.
			if esta_montado(tocado):
				desmontar(tocado)
				tocado.set_meta("era_jinete", true)
			_arrastre = tocado
			_arrastre_desfase = tocado.centro() - punto
			_arrastre_recorrido = 0.0
			_arrastre_inicio = tocado.centro()
			_bajar(tocado)
			_al_frente(tocado)
		toque_iniciado.emit()
		if herramienta.begins_with("camino_") or herramienta == "conector":
			_camino_actual = PackedVector2Array([punto])
			# Dedo quieto sobre un camino: lo borra (§11.1). Si el dedo se mueve, traza uno nuevo.
			_camino_tenido = camino_en(punto)
			_tenido_t = 0.0
			_tenido_inicio = punto
			_capa_caminos.queue_redraw()
			return
		if tocado == null and herramienta == "goma":
			_borrar_caminos_en(punto)
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
	if stickers_objeto and _camino_actual.is_empty() and (herramienta.begins_with("camino_") or herramienta == "conector"):
		# El dedo quieto ya borro un camino: este trazo no pinta ni traza.
		_ultimo = punto
		return
	if not _camino_tenido.is_empty() and punto.distance_to(_tenido_inicio) * zoom > TOLERANCIA_TOQUE:
		_camino_tenido = {}
		_capa_caminos.queue_redraw()
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
	if herramienta == "goma" and stickers_objeto:
		# La goma borra los caminos que toca, enteros (§11.1).
		var tramos := maxi(1, ceili(distancia * zoom / 10.0))
		for k in range(1, tramos + 1):
			_borrar_caminos_en(_ultimo.lerp(punto, float(k) / tramos))
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
	_camino_tenido = {}
	_puestos_trazo.clear()
	if _arrastre != null:
		var sticker := _arrastre
		_arrastre = null
		if is_instance_valid(sticker):
			if _arrastre_recorrido < TOLERANCIA_TOQUE:
				sticker_tocado.emit(sticker)
				var subio := (sticker.has_meta("era_jinete") and _intentar_montar(sticker)) or (sticker.clase == "vivo" and intentar_subir(sticker))
				# Atrapado en el aire y soltado ahi mismo: sigue cayendo.
				if not subio and sticker.has_meta("atrapado"):
					_soltar(sticker)
			else:
				if sticker.clase == "lugar":
					# Un lugar movido se despega de sus caminos (no quedan puntas colgando en el aire).
					for camino: Dictionary in caminos:
						if camino["desde"] == sticker:
							camino["desde"] = null
						if camino["hasta"] == sticker:
							camino["hasta"] = null
				sticker_cambiado.emit()
				# Fisica (§10): si no se subio a un camino y quedo en el cielo, cae (o el sol vuelve
				# volando); las combinaciones se revisan al aterrizar.
				if _intentar_montar(sticker):
					pass
				elif intentar_subir(sticker) or not _soltar(sticker):
					_revisar_combinaciones(sticker)
			if is_instance_valid(sticker):
				sticker.remove_meta("atrapado")
				sticker.remove_meta("era_jinete")
	if not _camino_actual.is_empty():
		_cerrar_camino()
	cerrar_paso()


## Llega un segundo dedo: deshace lo que hizo el primero en este trazo (pintura, stickers puestos,
## camino a medio trazar, arrastre) y queda en espera hasta que se levanten todos los dedos.
func cancelar_trazo() -> void:
	if not _presionado:
		return
	_presionado = false
	_camino_tenido = {}
	_pintura.copy_from(_respaldo)
	_sucio = true
	for sticker in _puestos_trazo:
		if is_instance_valid(sticker):
			sticker.queue_free()
	_puestos_trazo.clear()
	if _arrastre != null and is_instance_valid(_arrastre):
		_arrastre.poner_en(_arrastre_inicio)
		if _arrastre.has_meta("atrapado"):
			_arrastre.remove_meta("atrapado")
			_soltar(_arrastre)
		if _arrastre.has_meta("era_jinete"):
			_arrastre.remove_meta("era_jinete")
			_intentar_montar(_arrastre)
	_arrastre = null
	_camino_actual = PackedVector2Array()
	_capa_caminos.queue_redraw()
	# Lo que hizo el primer dedo ya se deshizo: no queda como paso del historial.
	_paso_abierto = {}


func _paso_trazo() -> float:
	var r := radio_pincel / zoom_trazo()
	match herramienta:
		"pincel_corazon", "pincel_estrella":
			return r * 2.6
		"purpurina":
			return r * 0.9
		"pincel_grueso":
			return r * 0.5
	return maxf(1.5 / zoom_trazo(), r * 0.3)


func _radio_herramienta() -> float:
	match herramienta:
		"pincel_grueso", "goma":
			return radio_pincel * 1.8 / zoom_trazo()
	return radio_pincel / zoom_trazo()


func _lado_mundo() -> float:
	return lado_sello / zoom_trazo()


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
				_marcar_pintura(p, tam)
		"pincel_corazon", "pincel_estrella":
			var tipo := herramienta.trim_prefix("pincel_")
			var imagen := _calcomania(tipo, color_actual, maxi(8, int(radio_pincel * 2.4 / zoom_trazo())))
			for p in puntos:
				_estampar_pintura(imagen, p)
		"purpurina":
			for p in puntos:
				for i in 3:
					var chispa := _calcomania("destello", [DORADO, Color.WHITE, color_actual.lightened(0.3)][i], maxi(6, int(randf_range(10.0, 20.0) / zoom_trazo())))
					_estampar_pintura(chispa, p + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * radio_pincel * 1.2 / zoom_trazo())
		_:
			var brocha := _brocha(_color_del_trazo(), _radio_herramienta())
			for p in puntos:
				_estampar_pintura(brocha, p)
	_pintura_tocada = true


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


## Estampa en la pintura y marca solo ese pedazo para subirlo a la GPU.
func _estampar_pintura(sello: Image, centro: Vector2) -> void:
	Raster.estampar(_pintura, sello, centro)
	_marcar_pintura(centro, sello.get_size())


func _marcar_pintura(centro: Vector2, tam: Vector2i) -> void:
	_pintura_tocada = true
	var rect := Rect2i(Vector2i(roundi(centro.x - tam.x / 2.0) - 1, roundi(centro.y - tam.y / 2.0) - 1), tam + Vector2i(2, 2))
	rect = rect.intersection(Rect2i(Vector2i.ZERO, tamano))
	if not rect.has_area():
		return
	_rect_sucio = rect if not _rect_sucio.has_area() else _rect_sucio.merge(rect)


## Parte la pintura en mosaicos de LADO_MOSAICO (4 en el mundo 1x, 16 en el grande): cada cuadro
## solo se sube a la GPU lo que cambio (subir 2560x1440 enteros en cada trazo seria lento en la tablet).
func _crear_mosaicos_pintura() -> void:
	_mosaicos_pintura.clear()
	for y in range(0, tamano.y, LADO_MOSAICO.y):
		for x in range(0, tamano.x, LADO_MOSAICO.x):
			var rect := Rect2i(x, y, mini(LADO_MOSAICO.x, tamano.x - x), mini(LADO_MOSAICO.y, tamano.y - y))
			var imagen := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
			_mosaicos_pintura.append({"rect": rect, "imagen": imagen, "textura": ImageTexture.create_from_image(imagen)})
	_rect_sucio = Rect2i()


func _subir_pintura() -> void:
	var sucio := _rect_sucio
	_rect_sucio = Rect2i()
	_sucio = false
	for mosaico_pintura: Dictionary in _mosaicos_pintura:
		var rect: Rect2i = mosaico_pintura["rect"]
		if rect.intersects(sucio):
			var imagen: Image = mosaico_pintura["imagen"]
			imagen.blit_rect(_pintura, rect, Vector2i.ZERO)
			(mosaico_pintura["textura"] as ImageTexture).update(imagen)


## Mosaicos que se subieron (para QA): cuantos hay en total.
func mosaicos_pintura() -> int:
	return _mosaicos_pintura.size()


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
		if _intentar_montar(sticker):
			pass
		elif sticker.clase == "vivo" and intentar_subir(sticker):
			pass
		elif sticker.clase == "vivo" and auto_subir and _hay_camino_con_viajeros():
			_saltar_al_camino(sticker)
		elif _soltar(sticker, true):
			# Cae (o el sol vuelve al cielo): las combinaciones se revisan al aterrizar.
			return
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
			_estampar_pintura(final_img, p)
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
	# Los personajes son altos y delgados: se ponen mas grandes para que se vean (y se toquen) como un pony.
	if Stickers.es_personaje(id):
		lado *= Stickers.ESCALA_PERSONAJE
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
		var centro := sticker.centro()
		var radio := sticker.radio_toque(zoom)
		if sticker.sentado:
			# El jinete sentado se ve mas chico: se toca solo en lo que se ve de el.
			var alto := sticker.lado * sticker.escala * sticker.achique * 0.9 * Stickers.RECORTE_SENTADO
			# Solo lo que asoma sobre el asiento: tocar el lomo o el centro del montable agarra al montable.
			centro = centro + Vector2(0.0, _alto_base(sticker) - alto * 0.75)
			radio = maxf(30.0 / maxf(zoom, 0.01), alto * 0.45)
		if punto.distance_to(centro) <= radio:
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
	# Goma sobre la pareja: se va lo que se toco; si era el montable, sus jinetes se bajan.
	desmontar(sticker)
	for jinete in jinetes_de(sticker):
		desmontar(jinete)
		_soltar(jinete)
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
	var lado := maxi(8, roundi(sticker.lado * sticker.escala * sticker.achique))
	var giro := snappedf(wrapf(sticker.rotation, -PI, PI), 0.01)
	var clave := "%s_%s_%d_%.2f_%s_%s" % [sticker.id, (sticker.color as Color).to_html(), lado, giro, sticker.espejo, sticker.sentado]
	if not _cache_stickers.has(clave):
		if _cache_stickers.size() > 240:
			_cache_stickers.clear()
		_cache_stickers[clave] = Stickers.imagen(sticker.id, sticker.color, lado, giro, sticker.espejo, sticker.sentado)
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
# Fisica: los que pesan caen con "¡puff!" (ficha §10.1)
# ---------------------------------------------------------------------------

## Configura la gravedad de la hoja con tema. Hay gravedad si la escena tiene CIELO y no es espacio:
## - el cielo es la zona `cielo` del tema; si falta, se deduce de la region `cielo` del fondo: llega
##   hasta donde empiezan las regiones de suelo (las que tocan el borde de abajo);
## - es espacio si el tema trae `"gravedad": false`, si su id dice "espacio"/"espacial" o si tiene
##   una zona o region `espacio` (alli todo flota);
## - las regiones de suelo (las que bajan mas que el cielo) son donde se aterriza.
func preparar_fisica(tema: Dictionary) -> void:
	fisicas = {}
	for id in tema.get("pesan", []):
		fisicas[str(id)] = "pesa"
	for id in tema.get("vuelan", []):
		fisicas[str(id)] = "vuela"
	cielo = Rect2()
	_suelos = []
	if zonas.has("cielo"):
		var r: Array = zonas["cielo"]
		cielo = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	elif region_por_id("cielo") >= 0:
		var borde := float(tamano.y)
		for region: Dictionary in lamina["regiones"]:
			var caja := _caja_de(region["poligono"])
			if str(region.get("id", "")) != "cielo" and caja.end.y >= tamano.y - 4.0:
				borde = minf(borde, caja.position.y)
		if borde < tamano.y - 4.0:
			cielo = Rect2(0.0, 0.0, float(tamano.x), borde)
	var espacio := false
	if tema.has("gravedad"):
		espacio = not bool(tema["gravedad"])
	else:
		var id_tema := str(tema.get("id", ""))
		espacio = id_tema.contains("espacio") or id_tema.contains("espacial") or zonas.has("espacio") or region_por_id("espacio") >= 0
	gravedad = not espacio and cielo.has_area()
	if gravedad:
		for region: Dictionary in lamina.get("regiones", []):
			if str(region.get("id", "")) != "cielo" and _caja_de(region["poligono"]).end.y > cielo.end.y + 1.0:
				_suelos.append(region["poligono"])


static func _caja_de(poligono: PackedVector2Array) -> Rect2:
	if poligono.is_empty():
		return Rect2()
	var caja := Rect2(poligono[0], Vector2.ZERO)
	for p in poligono:
		caja = caja.expand(p)
	return caja


func fisica_de(id: String) -> String:
	return str(fisicas.get(id, Stickers.fisica(id)))


## ¿El punto esta en el cielo (con gravedad activa)?
func en_cielo(punto: Vector2) -> bool:
	return gravedad and cielo.has_point(punto)


func esta_cayendo(sticker: Control) -> bool:
	for caida: Dictionary in _caidas:
		if caida["nodo"] == sticker:
			return true
	return false


## Distancia del centro a la "base" (los pies) del dibujo.
static func _alto_base(sticker: StickerVivo) -> float:
	return sticker.lado * sticker.escala * 0.43


## Se solto un sticker (nuevo o arrastrado): el sol fuera del cielo se quema y vuelve volando; uno que
## pesa con la base en el cielo cae. Devuelve true si quedo "ocupado" (cayendo o volando): quien llama
## no revisa combinaciones (se revisan al terminar). `auto`: R2 de Maxi al aterrizar.
func _soltar(sticker: StickerVivo, auto := false) -> bool:
	if not gravedad or not is_instance_valid(sticker) or sticker.fijo or sticker.has_meta("magico") \
			or sticker.has_meta("saltando") or esta_viajando(sticker) or esta_montado(sticker):
		return false
	if sticker.id == "sol":
		if cielo.has_point(sticker.centro()):
			return false
		_sol_fuera_del_cielo(sticker)
		return true
	if fisica_de(sticker.id) != "pesa":
		return false
	return _caer(sticker, auto)


## Busca donde aterriza (la primera superficie bajo sus pies: una region de suelo o un lugar; si no
## hay, el borde de abajo del cielo) y lo deja cayendo. Si ya esta apoyado, no cae.
func _caer(sticker: StickerVivo, auto := false) -> bool:
	var base := sticker.centro() + Vector2(0.0, _alto_base(sticker))
	if not cielo.has_point(base):
		return false
	var y := base.y
	var suelo := -1.0
	while y <= float(tamano.y) - 4.0:
		if _es_superficie(Vector2(base.x, y), sticker):
			suelo = y
			break
		y += 4.0
	if suelo < 0.0:
		suelo = minf(cielo.end.y + 6.0, float(tamano.y) - 4.0)
	elif suelo > base.y + 3.0:
		suelo += 6.0  # se "planta" un poquito en el pasto
	if suelo - base.y < 3.0:
		return false
	_caidas.append({"nodo": sticker, "v": 0.0, "y_final": sticker.centro().y + suelo - base.y, "auto": auto})
	sticker.deformar = Vector2(0.9, 1.12)
	caida_iniciada.emit(sticker)
	return true


func _es_superficie(p: Vector2, propio: StickerVivo) -> bool:
	for poligono: PackedVector2Array in _suelos:
		if Geometry2D.is_point_in_polygon(p, poligono):
			return true
	for lugar: StickerVivo in lugares():
		if lugar == propio:
			continue
		if lugar.fijo:
			if lugar.has_meta("poligono") and Geometry2D.is_point_in_polygon(p, lugar.get_meta("poligono")):
				return true
		elif p.distance_to(lugar.centro()) <= lugar.radio_toque(zoom) * 0.7:
			return true
	return false


## Caida con aceleracion (no lineal), estirandose; al llegar, aterriza.
func _mover_caidas(delta: float) -> void:
	var g := GRAVEDAD_SEMILLA if caida_suave else GRAVEDAD
	for caida: Dictionary in _caidas.duplicate():
		var nodo = caida["nodo"]
		if not is_instance_valid(nodo) or nodo.is_queued_for_deletion() or nodo == _arrastre:
			_caidas.erase(caida)
			continue
		caida["v"] = minf(float(caida["v"]) + g * delta, VELOCIDAD_MAX_CAIDA)
		var p: Vector2 = nodo.centro()
		p.y += float(caida["v"]) * delta
		if p.y >= float(caida["y_final"]):
			p.y = float(caida["y_final"])
			nodo.poner_en(p)
			_caidas.erase(caida)
			_aterrizar(nodo, bool(caida["auto"]))
		else:
			nodo.poner_en(p)


## "¡Puff!": aplastado, rebote chico, estirado y quieto; nubecita de polvo. Despues sigue como
## cualquier sticker soltado: caminos, combinaciones y objetivos.
func _aterrizar(nodo: StickerVivo, auto: bool) -> void:
	var grande := caida_suave
	var tween := nodo.create_tween()
	nodo.set_meta("tween_fisica", tween)
	tween.tween_property(nodo, "deformar", Vector2(1.32, 0.68) if grande else Vector2(1.22, 0.78), 0.07).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo, "deformar", Vector2(0.9, 1.12), 0.1)
	tween.parallel().tween_property(nodo, "rebote", nodo.lado * (0.24 if grande else 0.14), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo, "rebote", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(nodo, "deformar", Vector2.ONE, 0.16)
	tween.tween_property(nodo, "deformar", Vector2(1.08, 0.94), 0.05)
	tween.tween_property(nodo, "deformar", Vector2.ONE, 0.08)
	_agregar_polvo(nodo.centro() + Vector2(0.0, _alto_base(nodo)), "polvo", nodo.lado * nodo.escala, grande)
	aterrizo.emit(nodo, grande)
	if _intentar_montar(nodo):
		pass
	elif nodo.clase == "vivo" and not intentar_subir(nodo) and auto and auto_subir and _hay_camino_con_viajeros():
		_saltar_al_camino(nodo)
	_revisar_combinaciones(nodo)
	sticker_cambiado.emit()


## Detiene la fisica de un sticker (lo atrapan en el aire, salta a un camino o se deshace un paso).
func _detener_fisica(nodo: StickerVivo) -> void:
	for caida: Dictionary in _caidas.duplicate():
		if caida["nodo"] == nodo:
			_caidas.erase(caida)
			nodo.set_meta("atrapado", true)
	if nodo.has_meta("volando"):
		_matar_tween(nodo, "tween_vuelo")
		nodo.remove_meta("volando")
		nodo.rotation = float(nodo.get_meta("giro_vuelo", nodo.rotation))
		nodo.set_meta("atrapado", true)
	nodo.expresion = ""
	nodo.deformar = Vector2.ONE


# ---------------------------------------------------------------------------
# El sol solo vive en el cielo (ficha §10.2)
# ---------------------------------------------------------------------------

## Sol soltado fuera del cielo: tizna lo cercano (temporal, ~3 s), pone cara de "¡ups!" y vuelve
## volando en arco a un lugar libre del cielo. Nada se borra y la pintura no se quema.
func _sol_fuera_del_cielo(sol: StickerVivo) -> void:
	var cuantos := 0
	for otro: StickerVivo in stickers():
		if otro != sol and not otro.has_meta("magico") and otro.centro().distance_to(sol.centro()) <= RADIO_TIZNE:
			_tiznar(otro)
			cuantos += 1
	for par: Dictionary in _jinetes:
		var uno = par["jinete"]
		var otro = par["montura"]
		if is_instance_valid(uno) and is_instance_valid(otro) and esta_tiznado(uno) != esta_tiznado(otro):
			_tiznar(otro if esta_tiznado(uno) else uno)
	_agregar_polvo(sol.centro(), "chispas", sol.lado * sol.escala)
	sol.expresion = "ups"
	sol.set_meta("volando", true)
	sol.set_meta("giro_vuelo", sol.rotation)
	var desde := sol.centro()
	var destino := _lugar_libre_en_cielo(sol)
	sol.set_meta("destino_vuelo", destino)
	var arriba := maxf(cielo.position.y + sol.lado * 0.5, minf(desde.y, destino.y) - 220.0)
	var control := Vector2((desde.x + destino.x) / 2.0, arriba)
	var tween := sol.create_tween()
	sol.set_meta("tween_vuelo", tween)
	# Susto: tiembla un instante y despues sale volando dando una vuelta.
	for i in 4:
		tween.tween_property(sol, "temblor", 6.0 if i % 2 == 0 else -6.0, 0.05)
	tween.tween_property(sol, "temblor", 0.0, 0.05)
	var giro := sol.rotation
	tween.tween_method(func(k: float) -> void:
		if is_instance_valid(sol):
			var a := desde.lerp(control, k)
			sol.poner_en(a.lerp(control.lerp(destino, k), k))
			sol.rotation = giro + TAU * k, 0.0, 1.0, SEGUNDOS_VUELO_SOL).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_sol_llego.bind(sol))
	sol_quemo.emit(sol, cuantos)


func _sol_llego(sol: StickerVivo) -> void:
	if not is_instance_valid(sol):
		return
	sol.remove_meta("volando")
	sol.rotation = float(sol.get_meta("giro_vuelo", 0.0))
	sol.expresion = ""
	sol.saltar()
	sol_en_el_cielo.emit(sol)
	# De vuelta en el cielo sigue sirviendo para combinar (sol + nube de lluvia = arcoiris).
	_revisar_combinaciones(sol)
	sticker_cambiado.emit()


## Punto libre del cielo para el sol: dentro del area sin botones si se puede, lejos de los otros
## stickers y cerca de donde estaba.
func _lugar_libre_en_cielo(sol: StickerVivo) -> Vector2:
	var zona := cielo.intersection(area_segura)
	if zona.size.y < sol.lado * 0.8 or zona.size.x < sol.lado:
		zona = cielo
	var margen := sol.lado * 0.5 * sol.escala
	var mejor := Vector2(zona.get_center().x, zona.position.y + maxf(margen, zona.size.y / 2.0))
	var mejor_puntaje := -INF
	var y := zona.position.y + margen
	var fin_y := maxf(y, zona.end.y - margen)
	while y <= fin_y + 0.1:
		var x := zona.position.x + margen
		while x <= zona.end.x - margen:
			var p := Vector2(x, y)
			var lejania := 220.0
			for otro: StickerVivo in stickers():
				if otro != sol:
					lejania = minf(lejania, p.distance_to(otro.centro()))
			var puntaje := lejania - absf(x - sol.centro().x) * 0.15
			if puntaje > mejor_puntaje:
				mejor_puntaje = puntaje
				mejor = p
			x += 40.0
		y += 30.0
	return mejor


## Tiznado temporal (opcion A del PO): oscuro, humito y temblorcito; a los 3 s se sacude, suelta un
## polvito y vuelve a su color. No castiga: nada se borra.
func _tiznar(nodo: StickerVivo) -> void:
	_matar_tween(nodo, "tween_tizne")
	nodo.set_meta("tiznado", true)
	var tween := nodo.create_tween()
	nodo.set_meta("tween_tizne", tween)
	tween.tween_property(nodo, "self_modulate", COLOR_TIZNE, 0.15)
	for i in 5:
		tween.tween_property(nodo, "temblor", 4.0 if i % 2 == 0 else -4.0, 0.05)
	tween.tween_property(nodo, "temblor", 0.0, 0.05)
	for i in 3:
		tween.tween_callback(func() -> void:
			if is_instance_valid(nodo):
				_agregar_polvo(nodo.centro() - Vector2(0.0, nodo.lado * nodo.escala * 0.3), "humo", nodo.lado * nodo.escala))
		tween.tween_interval(SEGUNDOS_TIZNE / 3.0)
	# Se sacude como un perrito mojado y queda limpio.
	tween.tween_callback(func() -> void:
		if is_instance_valid(nodo):
			_agregar_polvo(nodo.centro(), "polvito", nodo.lado * nodo.escala))
	for i in 6:
		tween.tween_property(nodo, "temblor", 7.0 if i % 2 == 0 else -7.0, 0.06)
	tween.tween_property(nodo, "temblor", 0.0, 0.05)
	tween.parallel().tween_property(nodo, "self_modulate", Color.WHITE, 0.25)
	tween.tween_callback(func() -> void:
		if is_instance_valid(nodo):
			nodo.remove_meta("tiznado")
			nodo.saltar())


func esta_tiznado(nodo: Control) -> bool:
	return is_instance_valid(nodo) and nodo.has_meta("tiznado")


# ---------------------------------------------------------------------------
# Efectos dibujados en el mundo: polvo del aterrizaje, humito del tiznado, chispas del sol
# ---------------------------------------------------------------------------

func _agregar_polvo(pos: Vector2, tipo: String, tam: float, grande := false) -> void:
	var cantidad: int = {"polvo": 11 if grande else 7, "humo": 3, "polvito": 7, "chispas": 9}.get(tipo, 6)
	var duracion: float = {"polvo": 0.85 if grande else 0.55, "humo": 1.3, "polvito": 0.5, "chispas": 0.45}.get(tipo, 0.5)
	var partes: Array = []
	for i in cantidad:
		var dir: Vector2
		match tipo:
			"polvo":
				dir = Vector2((-1.0 if i % 2 == 0 else 1.0) * randf_range(0.45, 1.0), -randf_range(0.05, 0.4))
			"humo":
				dir = Vector2(randf_range(-0.25, 0.25), -1.0)
			_:
				dir = Vector2.from_angle(TAU * i / cantidad + randf_range(-0.25, 0.25))
		partes.append([dir, randf_range(0.7, 1.15), randf_range(-0.3, 0.3)])
	_polvos.append({"pos": pos, "tipo": tipo, "t": 0.0, "dur": duracion, "tam": tam * (1.45 if grande else 1.0), "partes": partes})
	_capa_efectos.queue_redraw()


func _dibujar_efectos() -> void:
	for efecto: Dictionary in _polvos:
		var k := clampf(float(efecto["t"]) / float(efecto["dur"]), 0.0, 1.0)
		var sale := 1.0 - (1.0 - k) * (1.0 - k)
		var alfa := 1.0 - k
		var tam: float = efecto["tam"]
		var pos: Vector2 = efecto["pos"]
		for parte: Array in efecto["partes"]:
			var dir: Vector2 = parte[0]
			var vel: float = parte[1]
			match str(efecto["tipo"]):
				"polvo":
					var p := pos + dir * tam * 0.78 * vel * sale
					var r := tam * (0.1 + 0.13 * sale) * vel
					_capa_efectos.draw_circle(p, r, Color("#F6EBD8", 0.92 * alfa))
					_capa_efectos.draw_arc(p, r, 0.0, TAU, 14, Color(COLOR_CONTORNO, 0.3 * alfa), maxf(1.5, tam * 0.02), true)
				"polvito":
					var p := pos + dir * tam * 0.55 * vel * sale
					_capa_efectos.draw_circle(p, tam * 0.06 * vel * (1.0 - k * 0.5), Color("#FFF3B0", alfa))
				"humo":
					var p := pos + Vector2(dir.x + float(parte[2]) * sin(k * 6.0), dir.y) * tam * 0.7 * sale
					_capa_efectos.draw_circle(p, tam * (0.08 + 0.16 * sale) * vel, Color("#7E7A88", 0.55 * alfa))
				"chispas":
					var p := pos + dir * tam * 0.75 * vel * sale
					_capa_efectos.draw_circle(p, tam * 0.05 * vel * (1.0 - k), Color("#FF9A2E", alfa))
					_capa_efectos.draw_circle(p, tam * 0.025 * vel * (1.0 - k), Color("#FFF3B0", alfa))


func efectos_activos() -> int:
	return _polvos.size()


# ---------------------------------------------------------------------------
# Deshacer y reiniciar (ficha §10.3 y §10.4)
# ---------------------------------------------------------------------------
# Cada accion (trazo, balde, sello o sticker puesto, sticker movido, camino trazado, editar un
# sticker) guarda una FOTO del estado de ANTES: stickers (nodo y propiedades), caminos, viajes, colores
# de las regiones, celdas del mosaico y, solo si la accion pinto, la pintura comprimida. Deshacer
# restaura la ultima foto: reusa los nodos que siguen vivos (los objetivos y viajes los reconocen) y
# recrea los que se fueron. Los objetivos cumplidos y los destellos NO se tocan (viven en el motor y
# nunca se descumplen).

func empezar_paso() -> void:
	if not _paso_abierto.is_empty():
		cerrar_paso()
	_paso_abierto = _capturar()
	_firma_paso = _firma()
	_pintura_tocada = false


func cerrar_paso() -> void:
	if _paso_abierto.is_empty():
		return
	var paso := _paso_abierto
	_paso_abierto = {}
	if _pintura_tocada:
		var datos := _respaldo.get_data()
		paso["pintura"] = datos.compress(FileAccess.COMPRESSION_ZSTD)
		paso["pintura_bytes"] = datos.size()
	elif _firma() == _firma_paso:
		return  # no cambio nada (un toque suelto): no gasta un paso
	_historial.append(paso)
	while _historial.size() > MAX_PASOS:
		_historial.pop_front()
	historial_cambiado.emit(_historial.size())


func pasos_para_deshacer() -> int:
	return _historial.size()


## Deshace la ultima accion. Devuelve false si no habia nada (o hay un dedo pintando).
func deshacer() -> bool:
	if _presionado or _historial.is_empty():
		return false
	var paso: Dictionary = _historial.pop_back()
	var pintura: Image = null
	if paso.has("pintura"):
		var datos: PackedByteArray = (paso["pintura"] as PackedByteArray).decompress(int(paso["pintura_bytes"]), FileAccess.COMPRESSION_ZSTD)
		pintura = Image.create_from_data(tamano.x, tamano.y, false, Image.FORMAT_RGBA8, datos)
	_restaurar(paso, pintura)
	historial_cambiado.emit(_historial.size())
	return true


## La hoja quedo preparada (fondo, lugares, puestos y caminos iniciales): esa es la foto de reinicio.
func fijar_inicio() -> void:
	_inicio = _capturar()
	_historial.clear()
	_paso_abierto = {}
	historial_cambiado.emit(0)


## Vuelve la hoja a como empezo: sin pintura, sin los stickers y caminos puestos, con los colores y
## stickers iniciales. Vacia el historial. Los objetivos cumplidos y los destellos se mantienen.
func reiniciar() -> void:
	if _inicio.is_empty():
		return
	_presionado = false
	_paso_abierto = {}
	_camino_actual = PackedVector2Array()
	var vacia := Image.create(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	_restaurar(_inicio, vacia)
	_polvos.clear()
	_historial.clear()
	historial_cambiado.emit(0)


func _capturar() -> Dictionary:
	var nodos: Array = []
	for nodo in _capa_sellos.get_children():
		if nodo.is_queued_for_deletion():
			continue
		if nodo is StickerVivo:
			if nodo.fijo:
				continue
			var centro: Vector2 = nodo.centro()
			for caida: Dictionary in _caidas:
				if caida["nodo"] == nodo:
					centro.y = float(caida["y_final"])
			var giro: float = nodo.rotation
			if nodo.has_meta("volando"):
				centro = nodo.get_meta("destino_vuelo", centro)
				giro = float(nodo.get_meta("giro_vuelo", giro))
			nodos.append({"tipo": "sticker", "nodo": nodo, "iid": nodo.get_instance_id(), "id": nodo.id, "clase": nodo.clase,
				"color": nodo.color, "lado": nodo.lado, "escala": nodo.escala, "giro": giro, "espejo": nodo.espejo, "centro": centro,
				"puesto": nodo.has_meta("puesto"), "magico": nodo.has_meta("magico")})
		elif nodo is TextureRect:
			nodos.append({"tipo": "sello", "nodo": nodo, "iid": nodo.get_instance_id(), "posicion": nodo.position, "flip": nodo.flip_h,
				"sello": str(nodo.get_meta("tipo", "")), "imagen": nodo.get_meta("imagen")})
	var foto_caminos: Array = []
	for camino: Dictionary in caminos:
		foto_caminos.append({"camino": camino, "desde": camino["desde"], "hasta": camino["hasta"],
			"desde_iid": _iid(camino["desde"]), "hasta_iid": _iid(camino["hasta"])})
	var foto_viajes: Array = []
	for v: Dictionary in _viajes:
		foto_viajes.append({"v": v.duplicate(), "nodo_iid": _iid(v["nodo"]), "inicio_iid": _iid(v["inicio"]), "ultimo_iid": _iid(v.get("ultimo_lugar", null))})
	var colores: Array = []
	for region: Dictionary in lamina.get("regiones", []):
		colores.append(region["color"])
	var foto_jinetes: Array = []
	for par: Dictionary in _jinetes:
		foto_jinetes.append({"jinete_iid": _iid(par["jinete"]), "montura_iid": _iid(par["montura"]), "asiento": par["asiento"]})
	return {"nodos": nodos, "caminos": foto_caminos, "viajes": foto_viajes, "colores": colores, "celdas": _celdas.duplicate(),
		"jinetes": foto_jinetes}


static func _iid(nodo) -> int:
	return nodo.get_instance_id() if nodo != null and is_instance_valid(nodo) else 0


## Huella barata del estado (para no guardar pasos que no cambiaron nada).
func _firma() -> String:
	var partes: PackedStringArray = []
	for nodo in _capa_sellos.get_children():
		if nodo.is_queued_for_deletion() or (nodo is StickerVivo and nodo.fijo):
			continue
		if nodo is StickerVivo:
			partes.append("%d:%s:%s:%s:%.2f:%.2f:%s" % [nodo.get_instance_id(), nodo.id, Vector2i(nodo.centro().round()), (nodo.color as Color).to_html(),
				nodo.escala, nodo.rotation, nodo.espejo])
		else:
			partes.append("%d:%s" % [nodo.get_instance_id(), Vector2i(nodo.position.round())])
	partes.append("c%d_%d" % [caminos.size(), _numero_camino])
	for par: Dictionary in _jinetes:
		partes.append("j%d>%d" % [_iid(par["jinete"]), _iid(par["montura"])])
	for region: Dictionary in lamina.get("regiones", []):
		partes.append((region["color"] as Color).to_html())
	partes.append("m%d_%s" % [_celdas.size(), str(_celdas.values().hash())])
	return ",".join(partes)


func _restaurar(foto: Dictionary, pintura: Image) -> void:
	_caidas.clear()
	_arrastre = null
	seleccionar(null)
	var vigentes := {}
	for entrada: Dictionary in foto["nodos"]:
		var nodo = entrada["nodo"]
		if is_instance_valid(nodo) and not nodo.is_queued_for_deletion() and nodo.get_parent() == _capa_sellos:
			vigentes[entrada["iid"]] = nodo
	# Lo que se agrego despues de la foto se va (en silencio: no es "borrar").
	for nodo in _capa_sellos.get_children():
		if nodo.is_queued_for_deletion() or (nodo is StickerVivo and nodo.fijo):
			continue
		if not vigentes.has(nodo.get_instance_id()):
			_capa_sellos.remove_child(nodo)
			nodo.queue_free()
	var mapa := {}
	for entrada: Dictionary in foto["nodos"]:
		var nodo = vigentes.get(entrada["iid"], null)
		if entrada["tipo"] == "sello":
			if nodo == null:
				nodo = TextureRect.new()
				nodo.texture = ImageTexture.create_from_image(entrada["imagen"])
				nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
				nodo.size = Vector2((entrada["imagen"] as Image).get_size())
				nodo.pivot_offset = nodo.size / 2.0
				nodo.set_meta("tipo", entrada["sello"])
				nodo.set_meta("imagen", entrada["imagen"])
				_capa_sellos.add_child(nodo)
			nodo.flip_h = entrada["flip"]
			nodo.position = entrada["posicion"]
			nodo.rotation = 0.0
			nodo.scale = Vector2.ONE
		else:
			var nuevo: bool = nodo == null
			if nuevo:
				nodo = StickerVivo.new()
				nodo.clase = entrada["clase"]
				nodo.preparar(entrada["id"], entrada["color"], entrada["lado"])
				_capa_sellos.add_child(nodo)
			_limpiar_estado_fisico(nodo)
			nodo.color = entrada["color"]
			nodo.escala = entrada["escala"]
			nodo.rotation = entrada["giro"]
			nodo.espejo = entrada["espejo"]
			nodo.poner_en(entrada["centro"])
			if entrada["puesto"]:
				nodo.set_meta("puesto", true)
			if entrada["magico"]:
				nodo.set_meta("magico", true)
			if nuevo:
				if entrada["magico"]:
					_animar_magico(nodo, true)
				else:
					nodo.aparecer()
		mapa[entrada["iid"]] = nodo
		_capa_sellos.move_child(nodo, -1)
	# Caminos de la foto (los trazados despues se van; sus viajeros se bajan).
	caminos.clear()
	for foto_camino: Dictionary in foto["caminos"]:
		var camino: Dictionary = foto_camino["camino"]
		camino["desde"] = _resolver(mapa, foto_camino["desde_iid"], foto_camino["desde"])
		camino["hasta"] = _resolver(mapa, foto_camino["hasta_iid"], foto_camino["hasta"])
		caminos.append(camino)
	for v: Dictionary in _viajes:
		if is_instance_valid(v["nodo"]):
			v["nodo"].remove_meta("viajando")
	_viajes.clear()
	for foto_viaje: Dictionary in foto["viajes"]:
		var v: Dictionary = (foto_viaje["v"] as Dictionary).duplicate()
		var nodo = mapa.get(foto_viaje["nodo_iid"], null)
		if nodo == null or not caminos.has(v["camino"]):
			continue
		v["nodo"] = nodo
		v["inicio"] = _resolver(mapa, foto_viaje["inicio_iid"], v["inicio"])
		v["ultimo_lugar"] = _resolver(mapa, foto_viaje["ultimo_iid"], v.get("ultimo_lugar", null))
		_viajes.append(v)
		nodo.set_meta("viajando", true)
	# Parejas de la foto (montar y desmontar se deshacen).
	_jinetes.clear()
	for par: Dictionary in foto.get("jinetes", []):
		var jinete = mapa.get(par["jinete_iid"], null)
		var montura = mapa.get(par["montura_iid"], null)
		if jinete != null and montura != null:
			_jinetes.append({"jinete": jinete, "montura": montura, "asiento": par["asiento"]})
			jinete.sentado = true
			jinete.achique = Stickers.ACHIQUE_JINETE
	_seguir_monturas()
	var regiones: Array = lamina.get("regiones", [])
	var colores: Array = foto["colores"]
	if colores.size() == regiones.size():
		for i in regiones.size():
			regiones[i]["color"] = colores[i]
	_celdas = (foto["celdas"] as Dictionary).duplicate()
	if pintura != null:
		_pintura.copy_from(pintura)
		_sucio = true
		_subir_pintura()
	queue_redraw()
	_capa_caminos.queue_redraw()
	_capa_efectos.queue_redraw()
	sticker_cambiado.emit()


## El nodo que corresponde a un iid de la foto: el restaurado, o el mismo si sigue vivo (lugares de
## fondo), o null si ya no existe.
func _resolver(mapa: Dictionary, iid: int, original):
	if iid == 0:
		return null
	if mapa.has(iid):
		return mapa[iid]
	if original != null and is_instance_valid(original) and not original.is_queued_for_deletion():
		return original
	return null


## Corta (y olvida) el tween guardado en la meta `clave`, si hay.
static func _matar_tween(nodo: Node, clave: String) -> void:
	if not nodo.has_meta(clave):
		return
	var tween = nodo.get_meta(clave)
	if tween is Tween and tween.is_valid():
		tween.kill()
	nodo.remove_meta(clave)


func _limpiar_estado_fisico(nodo: StickerVivo) -> void:
	for clave in ["tween_tizne", "tween_vuelo", "tween_fisica", "tween_salto"]:
		_matar_tween(nodo, clave)
	for clave in ["tiznado", "volando", "atrapado", "saltando", "viajando", "giro_vuelo", "destino_vuelo"]:
		nodo.remove_meta(clave)
	nodo.detener()
	nodo.self_modulate = Color.WHITE
	nodo.modulate = Color.WHITE
	nodo.temblor = 0.0
	nodo.deformar = Vector2.ONE
	nodo.expresion = ""
	nodo.rebote = 0.0
	nodo.sentado = false
	nodo.achique = 1.0
	nodo.remove_meta("era_jinete")


# ---------------------------------------------------------------------------
# Jinetes: personajes que se suben a animales y vehiculos (ficha §11.9)
# ---------------------------------------------------------------------------

func montura_de(jinete: Control) -> StickerVivo:
	for par: Dictionary in _jinetes:
		if par["jinete"] == jinete:
			return par["montura"]
	return null


func jinetes_de(montura: Control) -> Array:
	var lista: Array = []
	for par: Dictionary in _jinetes:
		if par["montura"] == montura:
			lista.append(par["jinete"])
	return lista


func esta_montado(jinete: Control) -> bool:
	return montura_de(jinete) != null


func _asiento_libre(montura: StickerVivo) -> int:
	var ocupados := {}
	for par: Dictionary in _jinetes:
		if par["montura"] == montura:
			ocupados[int(par["asiento"])] = true
	var asientos := Stickers.asientos(montura.id)
	for i in asientos.size():
		if not ocupados.has(i):
			return i
	return -1


## Punto del asiento `i` en el mundo (sigue el espejo, el giro y el saltito del montable).
func _punto_asiento(montura: StickerVivo, i: int) -> Vector2:
	var asiento: Vector2 = Stickers.asientos(montura.id)[i]
	var r := montura.lado * montura.escala * 0.45
	var local := Vector2(asiento.x * (-1.0 if montura.espejo else 1.0), asiento.y) * r
	return montura.centro() + local.rotated(montura.rotation) - Vector2(0.0, montura.rebote * montura.escala)


## Se solto `sticker`: si es un jinete libre cerca de un montable con asiento, se sube; si es un montable,
## sube al jinete libre mas cercano. Zona de snap: el radio del montable (Maxi, x1,5). True si monto.
func _intentar_montar(sticker: StickerVivo) -> bool:
	if not is_instance_valid(sticker) or sticker.fijo or sticker.has_meta("magico"):
		return false
	var holgura := 1.5 if auto_subir else 1.0
	if Stickers.es_jinete(sticker.id) and not esta_montado(sticker) and jinetes_de(sticker).is_empty():
		var mejor: StickerVivo = null
		var mejor_d := INF
		for otro: StickerVivo in stickers():
			if otro == sticker or not Stickers.es_montable(otro.id) or _asiento_libre(otro) < 0 or otro.has_meta("magico"):
				continue
			var d := minf(sticker.centro().distance_to(otro.centro()), (sticker.centro() + Vector2(0, _alto_base(sticker))).distance_to(otro.centro()))
			if d <= otro.radio_toque(zoom) * holgura and d < mejor_d:
				mejor = otro
				mejor_d = d
		if mejor != null:
			montar(sticker, mejor)
			return true
	elif Stickers.es_montable(sticker.id) and _asiento_libre(sticker) >= 0:
		var mejor: StickerVivo = null
		var mejor_d := INF
		for otro: StickerVivo in stickers():
			if otro == sticker or not Stickers.es_jinete(otro.id) or esta_montado(otro) or not jinetes_de(otro).is_empty():
				continue
			var d := otro.centro().distance_to(sticker.centro())
			if d <= sticker.radio_toque(zoom) * holgura and d < mejor_d:
				mejor = otro
				mejor_d = d
		if mejor != null:
			montar(mejor, sticker)
			return true
	return false


## Sube al jinete al asiento libre: brinquito con squash, destellitos y senal `montado` (el motor pone
## el "¡hop!"). Desde ahi se mueve con el montable (camino, arrastre y caida).
func montar(jinete: StickerVivo, montura: StickerVivo, asiento := -1) -> void:
	if asiento < 0:
		asiento = _asiento_libre(montura)
	if asiento < 0:
		return
	_detener_fisica(jinete)
	jinete.remove_meta("atrapado")
	_bajar(jinete)
	_jinetes.append({"jinete": jinete, "montura": montura, "asiento": asiento})
	jinete.sentado = true
	jinete.achique = Stickers.ACHIQUE_JINETE
	jinete.rotation = 0.0
	_seguir_monturas()
	_capa_sellos.move_child(jinete, -1)
	var tween := jinete.create_tween()
	jinete.set_meta("tween_fisica", tween)
	tween.tween_property(jinete, "deformar", Vector2(1.2, 0.8), 0.07)
	tween.tween_property(jinete, "deformar", Vector2(0.92, 1.1), 0.1)
	tween.tween_property(jinete, "deformar", Vector2.ONE, 0.12)
	_agregar_polvo(_punto_asiento(montura, asiento), "polvito", montura.lado * montura.escala)
	montado.emit(jinete, montura)


func desmontar(jinete: StickerVivo) -> void:
	for par: Dictionary in _jinetes.duplicate():
		if par["jinete"] == jinete:
			_jinetes.erase(par)
	if is_instance_valid(jinete):
		jinete.sentado = false
		jinete.achique = 1.0
		jinete.rebote = 0.0


## Cada cuadro el jinete se acomoda en su asiento: mira hacia donde mira el montable y rebota con el.
func _seguir_monturas() -> void:
	for par: Dictionary in _jinetes.duplicate():
		var jinete = par["jinete"]
		var montura = par["montura"]
		if not is_instance_valid(jinete) or jinete.is_queued_for_deletion():
			_jinetes.erase(par)
			continue
		if not is_instance_valid(montura) or montura.is_queued_for_deletion():
			# El montable se fue (combinacion, goma): el jinete se baja donde esta y, si pesa, cae.
			# Si el montable se transformo ahi mismo (pony + varita = unicornio), se sube al nuevo.
			_jinetes.erase(par)
			desmontar(jinete)
			if not _intentar_montar(jinete):
				_soltar(jinete)
			continue
		var asiento: Vector2 = _punto_asiento(montura, int(par["asiento"]))
		jinete.espejo = montura.espejo
		jinete.poner_en(asiento - Vector2(0.0, _alto_base(jinete)))
		if jinete.self_modulate != montura.self_modulate and montura.has_meta("tiznado"):
			jinete.self_modulate = montura.self_modulate


## El montable va al frente (arrastre) y sus jinetes, encima de el.
func _al_frente(nodo: StickerVivo) -> void:
	_capa_sellos.move_child(nodo, -1)
	for jinete in jinetes_de(nodo):
		_capa_sellos.move_child(jinete, -1)


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
	var puntos := remuestrear(suavizar(crudo), 10.0 / zoom_trazo())
	var largo := _largo(puntos)
	if puntos.size() < 2 or largo < 50.0 / zoom_trazo():
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
		"largos": _largos(puntos), "k": 1.0 / zoom_trazo(), "n": _numero_camino, "ancho": ancho_caminos}
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


## El camino bajo `punto` (el mas cercano dentro de su ancho dibujado + un margen de dedo), o {}.
func camino_en(punto: Vector2) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_d := INF
	for camino: Dictionary in caminos:
		var media := 21.0 * float(camino.get("ancho", ANCHO_CAMINO)) * float(camino.get("k", 1.0))
		var tolerancia := maxf(media + 10.0 / zoom, 22.0 / zoom)
		var d: float = _mas_cercano(camino, punto)[1]
		if d <= tolerancia and d < mejor_d:
			mejor = camino
			mejor_d = d
	return mejor


func _borrar_caminos_en(punto: Vector2) -> void:
	var camino := camino_en(punto)
	if not camino.is_empty():
		borrar_camino(camino)


## Borra un camino ENTERO con una fila de "puff" a lo largo (nunca deja un hueco a medias). Sus viajeros
## se bajan donde estan. Entra al historial con la accion en curso (§11.1).
func borrar_camino(camino: Dictionary) -> void:
	if not caminos.has(camino):
		return
	caminos.erase(camino)
	var bajados: Array = []
	for v: Dictionary in _viajes.duplicate():
		if v["camino"] == camino:
			bajados.append(v["nodo"])
			_terminar_viaje(v)
	# Un viajero que iba por un puente en el cielo y pesa, cae (fisica §10.1).
	for nodo in bajados:
		if is_instance_valid(nodo):
			_soltar(nodo)
	var muestras := a_lo_largo(camino["puntos"], 70.0 / zoom_trazo())
	if muestras.is_empty():
		muestras = [[camino["puntos"][0], Vector2.RIGHT]]
	for muestra: Array in muestras:
		_agregar_polvo(muestra[0], "polvo", 60.0 / zoom_trazo())
	_capa_caminos.queue_redraw()
	camino_borrado.emit(camino)
	sticker_cambiado.emit()


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
		if sticker.clase != "vivo" or esta_viajando(sticker) or esta_montado(sticker):
			continue
		var d: float = _mas_cercano(camino, sticker.centro())[1]
		if d < mejor_d:
			mejor = sticker
			mejor_d = d
	if mejor != null:
		_saltar_a(mejor, camino)


func _hay_camino_con_viajeros() -> bool:
	for camino: Dictionary in caminos:
		if not str(camino["tipo"]) in SIN_VIAJEROS:
			return true
	return false


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
	_detener_fisica(vivo)
	vivo.set_meta("saltando", true)
	var tween := vivo.create_tween()
	vivo.set_meta("tween_salto", tween)
	tween.tween_property(vivo, "position", destino - vivo.size / 2.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(vivo):
			vivo.remove_meta("saltando")
			intentar_subir(vivo))


## Un vivo soltado sobre (o cerca de) un camino se sube y lo recorre. Si se suelta sobre un lugar
## con caminos, sale por uno de ellos. Devuelve true si se subio.
func intentar_subir(vivo: StickerVivo) -> bool:
	if not is_instance_valid(vivo) or vivo.clase != "vivo" or caminos.is_empty() or esta_montado(vivo):
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
		var puntos: PackedVector2Array = camino["puntos"]
		var k := float(camino.get("k", 1.0))
		var ancho := float(camino.get("ancho", ANCHO_CAMINO))
		var aviso := clampf((_tenido_t - 0.2) / maxf(0.1, segundos_borrar_camino - 0.2), 0.0, 1.0) if camino == _camino_tenido else 0.0
		if aviso > 0.0:
			# Aviso de que se va a borrar: tiembla cada vez mas y se aclara.
			puntos = _trasladar(puntos, Vector2(sin(_tiempo * 45.0) * 4.0 * aviso, 0.0) / zoom)
			_capa_caminos.draw_polyline(puntos, Color(1, 1, 1, 0.75 * aviso), (34.0 * ancho + 18.0) * k, true)
		dibujar_camino(_capa_caminos, puntos, camino["tipo"], k, ancho)
	if _camino_actual.size() >= 2 and _camino_tenido.is_empty():
		var tipo := herramienta.trim_prefix("camino_") if herramienta.begins_with("camino_") else str(conector.get("tipo", tipo_camino))
		dibujar_camino(_capa_caminos, _camino_actual, tipo, 1.0 / zoom_trazo(), ancho_caminos)


## Dibuja un camino sobre cualquier CanvasItem o Grabador (pantalla, PNG e icono de la herramienta,
## con `k` para achicarlo). Tipos: camino (pista con linea blanca), sendero, rieles, cerca, guirnalda
## (luces de colores), arcoiris (puente), estelar y destellos.
## Ficha §11.2: `a` es el ANCHO de la seccion (1.0 = el grosor v1). Los caminos son PLANOS, como vistos
## desde arriba: borde fino (2,5 px por lado), sin volumen de tubo; el largo de los adornos (piedritas,
## durmientes, luces) no cambia, asi cada tipo se sigue reconociendo.
static func dibujar_camino(l, puntos: PackedVector2Array, tipo: String, k := 1.0, a := ANCHO_CAMINO) -> void:
	if puntos.size() < 2:
		return
	var adorno := maxf(a, 0.6)
	match tipo:
		"sendero":
			var ancho := 32.0 * a * k
			l.draw_polyline(puntos, COLOR_CONTORNO, ancho + 5.0 * k, true)
			l.draw_polyline(puntos, Color("#E8C88F"), ancho, true)
			var i := 0
			for muestra: Array in a_lo_largo(puntos, 26.0 * k):
				var normal := Vector2(-muestra[1].y, muestra[1].x)
				l.draw_circle(muestra[0] + normal * (ancho * 0.22 if i % 2 == 0 else -ancho * 0.22), 3.0 * adorno * k, Color("#C9A36B"))
				i += 1
		"rieles":
			for muestra: Array in a_lo_largo(puntos, 18.0 * k):
				var normal := Vector2(-muestra[1].y, muestra[1].x)
				l.draw_line(muestra[0] - normal * 18.0 * a * k, muestra[0] + normal * 18.0 * a * k, Color("#9A6238"), 7.0 * adorno * k, true)
			for lado in [-1.0, 1.0]:
				var riel := desplazar_linea(puntos, lado * 10.0 * a * k)
				l.draw_polyline(riel, COLOR_CONTORNO, 6.0 * adorno * k, true)
				l.draw_polyline(riel, Color("#C9D0E0"), 3.5 * adorno * k, true)
		"cerca":
			var alto := maxf(a, 0.7)
			for altura in [-20.0, -8.0]:
				var tabla := _trasladar(puntos, Vector2(0, altura * alto * k))
				l.draw_polyline(tabla, COLOR_CONTORNO, 9.0 * alto * k, true)
				l.draw_polyline(tabla, Color("#E6B07A"), 5.0 * alto * k, true)
			for muestra: Array in a_lo_largo(puntos, 38.0 * k):
				var p: Vector2 = muestra[0]
				l.draw_line(p + Vector2(0, 4) * k, p + Vector2(0, -30) * alto * k, COLOR_CONTORNO, 11.0 * alto * k, true)
				l.draw_line(p + Vector2(0, 2) * k, p + Vector2(0, -28) * alto * k, Color("#B07A55"), 6.5 * alto * k, true)
		"guirnalda":
			l.draw_polyline(puntos, COLOR_CONTORNO, 3.0 * k, true)
			var i := 0
			for muestra: Array in a_lo_largo(puntos, 28.0 * k):
				var foco: Vector2 = muestra[0] + Vector2(0, 9) * adorno * k
				l.draw_circle(foco, 9.0 * adorno * k, COLOR_CONTORNO)
				l.draw_circle(foco, 7.0 * adorno * k, Figura.COLORES_ARCOIRIS[i % Figura.COLORES_ARCOIRIS.size()])
				l.draw_circle(foco + Vector2(-2.5, -2.5) * adorno * k, 2.2 * adorno * k, Color(1, 1, 1, 0.7))
				i += 1
		"arcoiris":
			var bandas := Figura.COLORES_ARCOIRIS.size()
			var ancho := 6.0 * a * k
			for lado in [-1.0, 1.0]:
				l.draw_polyline(desplazar_linea(puntos, lado * (bandas / 2.0 * ancho + 1.2 * k)), COLOR_CONTORNO, 3.0 * k, true)
			for j in bandas:
				l.draw_polyline(desplazar_linea(puntos, (j - (bandas - 1) / 2.0) * ancho), Figura.COLORES_ARCOIRIS[j], ancho + 0.8 * k, true)
		"estelar", "destellos":
			var i := 0
			var tam := maxf(a, 0.75)
			var muestras := a_lo_largo(puntos, 14.0 * k)
			for muestra: Array in muestras:
				if i % 3 == 0:
					var forma := Figura.poligono("estrella", muestra[0], 10.0 * tam * k)
					l.draw_colored_polygon(forma, Color("#FFE38A") if tipo == "estelar" or i % 2 == 0 else Color("#FF9FD2"))
					Figura.contornear(l, forma, 2.0 * k)
				else:
					l.draw_circle(muestra[0], 3.5 * tam * k, Color("#FFF3B0") if tipo == "estelar" else Color("#FFD6F0"))
				i += 1
		_:
			var ancho := 42.0 * a * k
			l.draw_polyline(puntos, COLOR_CONTORNO, ancho + 5.0 * k, true)
			l.draw_polyline(puntos, Color("#8A90A6"), ancho, true)
			var i := 0
			for muestra: Array in a_lo_largo(puntos, 17.0 * k):
				if i % 2 == 0:
					var p: Vector2 = muestra[0]
					var dir: Vector2 = muestra[1]
					l.draw_line(p - dir * 7.0 * k, p + dir * 7.0 * k, Color.WHITE, 4.0 * adorno * k, true)
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
	# Ficha §12.6: si la pista queda fuera de la vista (o tapada por los botones), la camara va a ella.
	if not datos.is_empty() and segundos > 0.0:
		var rect := rect_fantasma()
		if rect != Rect2():
			# Tambien el tiempo del paseo: la pista sigue visible un rato despues de llegar.
			# Una zona grande (el rio, el pasto) basta con que asome en la vista.
			var basta_parte := str(datos.get("tipo", "")) == "zona"
			if basta_parte and Rect2(a_pantalla(rect.position), rect.size * zoom).intersection(area_libre).get_area() >= minf(rect.get_area() * zoom * zoom, area_libre.get_area()) * 0.25:
				return
			if not se_ve(rect.grow(24.0 / zoom)):
				_fantasma_resta += SEGUNDOS_ENFOQUE
			mostrar_en_vista(rect)


## Rect del mundo que ocupa la pista fantasma (vacio si no se puede saber).
func rect_fantasma() -> Rect2:
	match str(_fantasma.get("tipo", "")):
		"camino", "circuito":
			var puntos: PackedVector2Array = _fantasma.get("puntos", PackedVector2Array())
			if puntos.is_empty():
				return Rect2()
			var caja := Rect2(puntos[0], Vector2.ZERO)
			for p in puntos:
				caja = caja.expand(p)
			return caja.grow(40.0 / zoom_trazo())
		"sticker":
			var pos: Vector2 = _fantasma.get("pos", Vector2(tamano) / 2.0)
			var r := lado_sello * 0.65 / zoom_trazo()
			return Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0)
		"zona":
			var i := int(_fantasma.get("indice", -1))
			var regiones: Array = lamina.get("regiones", [])
			if i >= 0 and i < regiones.size():
				return _caja_de(regiones[i]["poligono"])
	return Rect2()


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
			var r := lado_sello * 0.5 / zoom_trazo() * (1.0 + 0.08 * sin(_tiempo * 5.0))
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
	for mosaico_pintura: Dictionary in _mosaicos_pintura:
		draw_texture(mosaico_pintura["textura"], Vector2((mosaico_pintura["rect"] as Rect2i).position))


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
## No usa el renderer: funciona igual en la tablet que headless. Siempre a 1280x720, sin zoom: el
## mundo grande (ficha §12) se compone entero y se reduce (la hoja completa, como en "ver todo").
func componer() -> Image:
	var imagen := _componer_mundo()
	if imagen.get_size() != TAMANO_PANTALLA:
		imagen.resize(TAMANO_PANTALLA.x, TAMANO_PANTALLA.y, Image.INTERPOLATE_LANCZOS)
	return imagen


func _componer_mundo() -> Image:
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
			dibujar_camino(grabador, camino["puntos"], camino["tipo"], float(camino.get("k", 1.0)), float(camino.get("ancho", ANCHO_CAMINO)))
		grabador.volcar(imagen)
	for nodo in _capa_sellos.get_children():
		if nodo.is_queued_for_deletion():
			continue
		if nodo is StickerVivo:
			if nodo.fijo:
				continue
			var donde: Vector2 = nodo.centro() + Vector2(0, -nodo.rebote * nodo.escala)
			if nodo.achique != 1.0:
				# Achicado alrededor de la base (jinete): la base queda donde esta.
				donde += Vector2(0.0, _alto_base(nodo) * (1.0 - nodo.achique))
			Raster.estampar(imagen, _imagen_sticker(nodo), donde)
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
