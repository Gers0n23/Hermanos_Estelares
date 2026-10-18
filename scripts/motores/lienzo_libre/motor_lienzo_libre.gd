class_name MotorLienzoLibre
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "lienzo_libre" — "Pinta con Coco" del Planeta Arcoiris
## (docs/fichas/motor-lienzo-libre.md, §9 "Lienzo v2").
##
## LIENZO V2 (pedido del PO, 17-Oct-2026):
## - El lienzo ocupa la PANTALLA COMPLETA (1280x720). Las herramientas viven en un DOCK de botones
##   redondos sin texto (columna izquierda): Colores, Pinceles, Cosas que se mueven, Decorados y Lupa.
##   Cada uno abre un POPUP (uno a la vez) que se cierra al elegir o al tocar el lienzo. Maxi tiene
##   menos grupos y botones de >= 96 px.
## - Esquinas: arriba a la izquierda salir + tarjeta de INSPIRACION (se agranda y Coco la narra);
##   arriba a la derecha los OBJETIVOS; a la derecha Coco, "mostrar a Coco" y Cometa.
## - OBJETIVOS OBLIGATORIOS (`objetivos` del JSON, reemplazan a los `retos`): todos se necesitan para
##   pasar la hoja. Maxi ve 1 a la vez; Nicole y Sofia 3. Cada chip es un pictograma con progreso que,
##   al tocarlo, hace que Coco repita la consigna. Sin avance, Coco da una PISTA FANTASMA. Al cumplir
##   todos: gran celebracion y aparece "mostrar a Coco". Sin tiempo limite, sin fallo.
## - ZOOM con pinza, rueda o lupa (no para Maxi). Un dedo pinta; dos dedos nunca pintan.
## - MUNDO GRANDE (ficha §12): en las hojas con tema de Nicole y Sofia el mundo mide 2x2 pantallas;
##   arranca en zoom 1 (un cuarto de la hoja) y "ver todo" aleja hasta la hoja entera.
##
## Encargos de las zonas 2-5 (`encargo`): libre, sellos_escena, colorear_zonas, colorear_codigo,
## pinta_coco, coco_pide, mezcla_paleta, dedo_magico, espejo, mandala, decora_ala, viste_coco. En
## esas hojas el objetivo base es el propio encargo (`{"tipo": "encargo"}`).
##
## Cada hoja se muestra a Coco, se guarda como PNG en user://dibujos/<hermano>/ y pasa a la
## siguiente; la ultima dispara la celebracion comun y `completado(destellos)`. F3: depuracion.

signal hoja_mostrada(indice: int, ruta_png: String)
signal pedido_cumplido(id_color: String)
signal objetivo_cumplido(indice: int, tipo: String)
signal objetivos_completos()

const Lienzo := preload("res://scripts/motores/lienzo_libre/lienzo.gd")
const Colores := preload("res://scripts/motores/lienzo_libre/colores_lienzo.gd")
const Laminas := preload("res://scripts/motores/lienzo_libre/laminas.gd")
const Sellos := preload("res://scripts/motores/lienzo_libre/sellos.gd")
const Cresta := preload("res://scripts/motores/lienzo_libre/cresta_coco.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const Stickers := preload("res://scripts/motores/lienzo_libre/stickers.gd")
const StickerVivo := preload("res://scripts/motores/lienzo_libre/sticker_vivo.gd")

## Pantalla base 1280x720: el lienzo la ocupa entera; los botones van en las esquinas.
const RECT_LIENZO := Rect2(0, 0, 1280, 720)
## Parte del papel que no tapan los botones: alli se encuadran las laminas de 824x530 y el mosaico.
const AREA_SEGURA := Rect2(128, 168, 972, 544)
## Ficha §12: lado del mundo (en pantallas) de las hojas con tema de Nicole y Sofia (Maxi: 1).
const ESCALA_MUNDO_GRANDE := 2.0
const DOCK_X := 12.0
const DOCK_Y := 128.0
const RECT_INSPIRACION := Rect2(128, 12, 192, 108)
const RECT_MOSTRAR := Rect2(1117, 440, 142, 142)
const BORDE_OBJETIVOS := 1268.0
const CARPETA_DIBUJOS := "user://dibujos"
## Destellos (ficha §9.6): 10 por hoja mostrada + un fondo de 36 por hoja repartido entre sus
## objetivos (Maxi 3 x 12, Nicole 6 x 6, Sofia 12 x 3) + 1 por color distinto (hasta 10).
const DESTELLOS_POR_HOJA := 10
const DESTELLOS_OBJETIVOS_POR_HOJA := 36
const MAX_DESTELLOS_COLORES := 10
const SEGUNDOS_ENTRE_NOMBRES := 2.2
const SEGUNDOS_ENTRE_REACCIONES := 2.6
const SEGUNDOS_ENTRE_LLEGADAS := 2.4
## Escalera de pistas (lienzo-escenas-retos.md §6.2), en segundos sin avance: nivel 1 (voz + la
## tarjeta late), nivel 2 (lo necesario brilla en el dock), nivel 3 (mano fantasma) y repeticion
## (0 = solo a pedido, tocando a Coco). Maxi antes que nadie.
const ESCALERA_PISTAS := {
	"semilla": {"voz": 8.0, "brilla": 8.0, "mano": 15.0, "repetir": 12.0},
	"brote": {"voz": 20.0, "brilla": 35.0, "mano": 50.0, "repetir": 30.0},
	"estrella": {"voz": 45.0, "brilla": 75.0, "mano": 105.0, "repetir": 0.0},
}
## Valvula de Semilla (§6.4): tras la 3.a mano fantasma en un mismo objetivo, el siguiente toque de
## Maxi en cualquier parte lo completa. Nicole y Sofia no la tienen (reto real).
const MANOS_VALVULA := 3
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_ELEGIR := "sfx/ui/seleccionar.ogg"
const SFX_SELLO := "sfx/ui/soltar.ogg"
const SFX_RELLENO := "sfx/ui/confirmar.ogg"
const SFX_MOSTRAR := "sfx/ui/abrir.ogg"
## Fisica, sol, deshacer y reiniciar (ficha §10): SFX originales de `componer_sfx_ui.py`.
const SFX_POLVO := "sfx/ui/polvo.ogg"
const SFX_POLVO_MAXI := "sfx/ui/polvo_boing.ogg"
const SFX_CAIDA := "sfx/ui/fiuu.ogg"
const SFX_CHISPORROTEO := "sfx/ui/chisporroteo.ogg"
const SFX_REBOBINAR := "sfx/ui/rebobinar.ogg"
const SFX_FUUSH := "sfx/ui/fuuush.ogg"
const SFX_PUF := "sfx/ui/puf.ogg"
const SFX_HOP := "sfx/ui/blup.ogg"
## Reiniciar la hoja: mantener presionada la escoba este tiempo (anti-accidente infantil).
const SEGUNDOS_REINICIAR := 1.2
## Botones "deshacer" y "reiniciar", arriba, a la derecha de la tarjeta de inspiracion.
const X_EDICION := 340.0
const Y_EDICION := 14.0
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
const PALETA_SEMILLA := ["rojo", "azul", "amarillo", "verde", "rosa", "violeta"]
const PALETA_COMPLETA := ["rojo", "naranja", "amarillo", "verde", "azul", "violeta", "rosa", "turquesa", "celeste", "blanco", "cafe", "negro", "gris", "verde_oscuro"]
const PRIMARIOS := ["rojo", "amarillo", "azul", "blanco"]
const PINCELES := ["pincel", "pincel_grueso", "goma", "balde", "arcoiris", "purpurina", "pincel_corazon", "pincel_estrella"]
const NOTAS_HZ := [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0]

@onready var _ui: Control = %ui
@onready var _anfitriona: TextureRect = %anfitriona
@onready var _efectos: Control = %efectos
@onready var _confeti: CPUParticles2D = %confeti
@onready var _boton_cometa: Button = %boton_cometa
@onready var _boton_salir: Button = %boton_salir
@onready var _panel_depuracion: Label = %panel_depuracion

var lienzo: Lienzo
var carpeta_dibujos := CARPETA_DIBUJOS
var boton_mostrar: Button
var pngs_guardados: Array[String] = []

var _hojas: Array = []
var _indice_hoja := -1
var _cfg: Dictionary = {}
var _encargo := "libre"
var _perfil := "semilla"
var _mostrando := false
var _terminado := false

## Dock y popups.
var _dock: Control
var _dock_botones: Array = []  ## [{"boton": Button, "grupo": String}]
var _grupos: Dictionary = {}  ## grupo -> Array de items (ids de herramienta)
var _popup: Control
var _popup_grupo := ""
var _velo: Button
var _botones_color: Array = []  ## [{"boton", "color", "id", "numero"}] (los del popup abierto)
var _entradas_color: Array = []  ## [{"color", "id", "numero"}] de la hoja (aunque el popup este cerrado)
var _botones_herramienta: Array = []  ## [{"boton", "id"}] del popup abierto
var _boton_ver_todo: Button
var _fuente: Font

## Deshacer y reiniciar (ficha §10.3-10.4).
var _boton_deshacer: Button
var _boton_reiniciar: Button
var _anillo_reiniciar: Control
## Segundos que lleva presionada la escoba (-1 = suelta).
var _reinicio_t := -1.0
var _barriendo := false
var _ms_ultimo_sol := -100000
var _ms_pista_reiniciar := -100000

## Coco como burbujita (ficha §11.4): solo aparece cuando habla o celebra.
const CENTRO_BURBUJA := Vector2(1190, 302)
const RADIO_BURBUJA := 70.0
const MARGEN_BURBUJA := 0.7
var _burbuja_coco: Control
var _cuerpo_coco: Control
var _coco_hasta := 0.0
var _coco_saliendo := false
var _tween_burbuja: Tween

## Inspiracion (tarjeta chica y grande).
var _inspiracion: Button
var _inspiracion_grande: Control

## Objetivos.
var _objetivos: Array = []  ## [{"datos", "actual", "meta", "hecho", "chip", "registro"}]
var _objetivos_ui: Control
var _a_la_vez := 3
var _objetivos_listos := false
var _destellos_objetivos := 0
var _sin_avance := 0.0
var _pausa_pista := 0.0
var _peldano := 0
var _valvula_lista := false
var _historial_viajes := {}  ## id de instancia del vivo -> [ids de lugares a los que llego]
var _ms_ultima_llegada := -100000
var _sellos_hoja := 0
var _sondeo := 0.0

var _puntos_hojas: Control
var _burbuja: Control
var _cresta: Cresta
var _barra: Control
var _selector: Control
var eligiendo_tema := false
var _temas_libres: Array = []
var _nombrados := {}
var _ms_ultimo_nombre := -100000
var _conectados := 0
var _grupos_nombrados := {}

var _colores_usados: Array = []
var _colores_hoja := {}
var _recientes: Array = []
var _ms_ultimo_arcoiris := -100000
var _ms_ultima_reaccion := -100000
var _usados_especiales := {}
var _dinos_seguidos := 0
var _paseos_dino := 0
var _lamina_nombrada := false

var _pedidos: Array = []
var _pedido_actual := -1
var _fallos_pedido := 0
var _gotas := {}
var _mezclas_dichas := {}
var _mis_colores: Array = []
var _traje := ""

## Pinza de dos dedos.
var _dedos := {}
var _pinza_inicio := {}

var _segundos_recordar := 0.0
var _recordado := false
var _boton_visible_desde := 0.0
var _tiempo_hoja := 0.0
var _hubo_toque := false
var _tiempo := 0.0
var _base_anfitriona := Vector2.ZERO
var _salto_anfitriona := 0.0
var _tween_anfitriona: Tween
var _tween_mostrar: Tween
var _voz_diferida_id := 0
var _ultima_linea := ""
var _notas: Array[AudioStreamPlayer] = []
var _sonidos_nota: Array = []
var _indice_nota := 0
var _ms_sfx := {}


func _ready() -> void:
	super._ready()
	randomize()
	_panel_depuracion.hide()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_construir_interfaz()
	_boton_cometa.pressed.connect(_al_tocar_cometa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_armar_burbuja_coco()
	if nivel.is_empty():
		push_error("motor_lienzo_libre: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_perfil = obtener_perfil_dificultad()
	_armar_hojas()
	_empezar_hoja(0)


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	var bamboleo := absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0
	_burbuja_coco.position.y = _base_anfitriona.y - _salto_anfitriona - bamboleo
	# Ficha §11.4: la burbujita de Coco se va sola cuando termino de hablar (mas un margen).
	if _burbuja_coco.visible and not _coco_saliendo and not hablando and not _mostrando and _tiempo > _coco_hasta:
		_ocultar_coco()
	if _reinicio_t >= 0.0:
		_reinicio_t += delta
		_anillo_reiniciar.queue_redraw()
		if _reinicio_t >= SEGUNDOS_REINICIAR:
			_reinicio_t = -1.0
			reiniciar_lienzo()
	if _terminado or _mostrando or eligiendo_tema or _indice_hoja < 0:
		return
	_tiempo_hoja += delta
	_sondeo += delta
	if _sondeo >= 0.25:
		_sondeo = 0.0
		_revisar_objetivos()
	if not _objetivos_listos:
		if _pausa_pista > 0.0:
			_pausa_pista -= delta
		else:
			_sin_avance += delta
			_subir_escalera()
	elif boton_mostrar.visible and not _recordado and _segundos_recordar > 0.0 \
			and _tiempo_hoja >= _boton_visible_desde + _segundos_recordar:
		_recordado = true
		_revelar_boton_mostrar(false)
		_reproducir_voz("me_lo_muestras", _linea_al_azar("me_lo_muestras"))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()


## Pinza de dos dedos (zoom y desplazamiento). Al llegar el segundo dedo se deshace lo que hizo el
## primero en ese trazo: dos dedos nunca pintan (tampoco en Maxi, que no tiene zoom).
func _input(event: InputEvent) -> void:
	if lienzo == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_dedos[event.index] = event.position
		else:
			_dedos.erase(event.index)
		if _dedos.size() >= 2 and not lienzo.en_gesto:
			lienzo.cancelar_trazo()
			lienzo.en_gesto = true
			_empezar_pinza()
		elif _dedos.is_empty() and lienzo.en_gesto:
			lienzo.en_gesto = false
			_pinza_inicio = {}
	elif event is InputEventScreenDrag:
		_dedos[event.index] = event.position
		if lienzo.en_gesto and _dedos.size() >= 2 and not _pinza_inicio.is_empty():
			var puntos := _dos_dedos()
			var distancia := maxf(1.0, puntos[0].distance_to(puntos[1]))
			var medio: Vector2 = (puntos[0] + puntos[1]) / 2.0
			if lienzo.zoom_permitido:
				lienzo.aplicar_zoom(float(_pinza_inicio["zoom"]) * distancia / float(_pinza_inicio["distancia"]), _pinza_inicio["medio"])
				lienzo.desplazar(medio - _pinza_inicio["medio"])
				_pinza_inicio["medio"] = medio
				_pinza_inicio["zoom"] = lienzo.zoom
				_pinza_inicio["distancia"] = distancia


func _empezar_pinza() -> void:
	var puntos := _dos_dedos()
	_pinza_inicio = {"zoom": lienzo.zoom, "distancia": maxf(1.0, puntos[0].distance_to(puntos[1])), "medio": (puntos[0] + puntos[1]) / 2.0}


func _dos_dedos() -> Array:
	var lista: Array = _dedos.values()
	return [lista[0], lista[1]]


# ---------------------------------------------------------------------------
# Hojas y etapas
# ---------------------------------------------------------------------------

func _armar_hojas() -> void:
	_hojas.clear()
	var temas: Array = nivel.get("temas", [])
	if not temas.is_empty():
		_armar_hojas_con_tema(temas)
		return
	var etapas: Array = nivel.get("etapas", [])
	if etapas.is_empty():
		etapas = [{}]
	for i in etapas.size():
		var cfg := _config_de_etapa(etapas[i])
		var elegidas := _elegir_laminas(cfg)
		for j in elegidas.size():
			_hojas.append({"cfg": cfg, "lamina": elegidas[j], "etapa": i, "primera_de_etapa": j == 0})


func _armar_hojas_con_tema(temas: Array) -> void:
	var cuantas := mini(int(nivel.get("temas_por_partida", 2)), temas.size())
	_temas_libres = temas.duplicate()
	_temas_libres.shuffle()
	var asignados: Array = []
	if int(nivel.get("opciones_tema", 1)) <= 1:
		asignados = _elegir_laminas({"laminas": temas, "laminas_por_partida": cuantas, "al_menos_una": nivel.get("al_menos_una", "")})
	for i in cuantas:
		var hoja := {"cfg": {}, "lamina": {}, "etapa": i, "primera_de_etapa": true, "tema": {}}
		if i < asignados.size():
			_asignar_tema(hoja, asignados[i])
		_hojas.append(hoja)


func _asignar_tema(hoja: Dictionary, tema: Dictionary) -> void:
	hoja["tema"] = tema
	hoja["cfg"] = _config_de_etapa(tema)
	hoja["lamina"] = tema.get("fondo", {})
	for i in range(_temas_libres.size() - 1, -1, -1):
		if str(_temas_libres[i].get("id", "")) == str(tema.get("id", "")):
			_temas_libres.remove_at(i)


func _config_de_etapa(etapa: Dictionary) -> Dictionary:
	var cfg := nivel.duplicate(true)
	cfg.erase("etapas")
	cfg.erase("temas")
	for clave in etapa:
		if clave == "lineas_voz":
			var voces: Dictionary = nivel.get("lineas_voz", {}).duplicate()
			voces.merge(etapa["lineas_voz"], true)
			cfg["lineas_voz"] = voces
		else:
			cfg[clave] = etapa[clave]
	return cfg


func _elegir_laminas(cfg: Dictionary) -> Array:
	var pool: Array = cfg.get("laminas", []).duplicate()
	if pool.is_empty():
		return [{}]
	var fija: Array = []
	if bool(cfg.get("primera_fija", false)):
		fija.append(pool.pop_front())
	pool.shuffle()
	var cuantas := int(cfg.get("laminas_por_partida", 1)) - fija.size()
	var elegidas: Array = pool.slice(0, maxi(0, cuantas))
	var etiqueta := str(cfg.get("al_menos_una", ""))
	if etiqueta != "" and not elegidas.is_empty():
		var tiene := false
		for lamina: Dictionary in elegidas:
			if (lamina.get("etiquetas", []) as Array).has(etiqueta):
				tiene = true
		if not tiene:
			for lamina: Dictionary in pool:
				if (lamina.get("etiquetas", []) as Array).has(etiqueta):
					elegidas[randi() % elegidas.size()] = lamina
					break
	return fija + elegidas


func _empezar_hoja(indice: int) -> void:
	_indice_hoja = indice
	var hoja: Dictionary = _hojas[indice]
	if hoja.has("tema") and (hoja["tema"] as Dictionary).is_empty():
		_boton_deshacer.hide()
		_boton_reiniciar.hide()
		_mostrar_selector()
		return
	_cfg = hoja["cfg"]
	_encargo = str(_cfg.get("encargo", "libre"))
	_tiempo_hoja = 0.0
	_hubo_toque = false
	_mostrando = false
	_lamina_nombrada = false
	_colores_hoja.clear()
	_dinos_seguidos = 0
	_sellos_hoja = 0
	_usados_especiales["dinos_estampados"] = 0
	_voz_diferida_id += 1
	_anfitriona.modulate = Color.WHITE
	_cerrar_popup()
	_cerrar_inspiracion()

	# Ficha §12: mundo grande solo en las hojas con tema y con zoom (Nicole y Sofia); el JSON puede
	# fijar otro `escala_mundo`. Maxi y las hojas de colorear de las zonas 2-5 siguen a 1x.
	var con_zoom := _perfil != "semilla" and bool(_cfg.get("zoom", true))
	var con_tema := not (hoja.get("tema", {}) as Dictionary).is_empty()
	lienzo.fijar_escala_mundo(float(_cfg.get("escala_mundo", ESCALA_MUNDO_GRANDE)) if con_zoom and con_tema else 1.0)
	lienzo.limpiar()
	lienzo.bloqueado = false
	lienzo.fijar_area_libre(AREA_SEGURA)
	lienzo.zoom_permitido = con_zoom
	lienzo.papel = Color(str(_cfg.get("papel", "#FFF8EE")))
	lienzo.radio_pincel = float(_cfg.get("radio_pincel", {"semilla": 26.0, "brote": 16.0, "estrella": 11.0}.get(_perfil, 16.0)))
	lienzo.lado_sello = int(_cfg.get("lado_sello", {"semilla": 124, "brote": 88, "estrella": 72}.get(_perfil, 88)))
	lienzo.sellos_vivos = bool(_cfg.get("sellos_vivos", _perfil == "semilla"))
	lienzo.rellenar_con_toque = bool(_cfg.get("rellenar_con_toque", false))
	var tema: Dictionary = hoja.get("tema", {})
	lienzo.stickers_objeto = not tema.is_empty()
	lienzo.sticker_con_color_actual = _perfil == "semilla" and bool(_cfg.get("tenir_stickers", true))
	lienzo.conector = _cfg.get("conector", {})
	# Reglas R1, R2 y R5 del catalogo: Maxi tiene iman grande, cierre generoso y auto-subida.
	lienzo.radio_subida = 84.0 if _perfil == "semilla" else 60.0
	lienzo.iman = 120.0 if _perfil == "semilla" else 70.0
	lienzo.cierre_distancia = 150.0 if _perfil == "semilla" else 60.0
	lienzo.cierre_largo = 500.0 if _perfil == "semilla" else 280.0
	lienzo.auto_subir = _perfil == "semilla"
	# Ficha §11.1-11.2: caminos mas finos (Maxi algo mas anchos) y, con la herramienta de camino, el dedo
	# quieto sobre uno lo borra (Maxi necesita mas tiempo: menos borrados por accidente).
	lienzo.ancho_caminos = Lienzo.ANCHO_CAMINO_SEMILLA if _perfil == "semilla" else Lienzo.ANCHO_CAMINO
	lienzo.segundos_borrar_camino = 1.5 if _perfil == "semilla" else Lienzo.SEGUNDOS_BORRAR_CAMINO
	lienzo.avisar_completa = not lienzo.stickers_objeto
	_nombrados.clear()
	_conectados = 0
	_historial_viajes.clear()
	_ocultar_barra()
	var lamina: Dictionary = hoja["lamina"]
	if lamina.has("papel"):
		lienzo.papel = Color(str(lamina["papel"]))
	var tam: Array = lamina.get("tamano", [824, 530])
	lienzo.encuadrar(Vector2(float(tam[0]), float(tam[1])))
	match str(lamina.get("tipo", "zonas")):
		"papel":
			pass
		"mosaico":
			if not lamina.is_empty():
				lienzo.poner_mosaico(lamina)
		"guia":
			lienzo.poner_guia(lamina)
		_:
			if not lamina.is_empty():
				lienzo.poner_lamina(lamina)
	lienzo.poner_simetria(str(_cfg.get("simetria", "")))
	_traje = ""
	if lamina.has("trajes"):
		_elegir_traje(str((lamina.get("orden_trajes", lamina["trajes"].keys()) as Array)[0]), true)
	if lienzo.stickers_objeto:
		_preparar_escena(tema)

	_preparar_colores()
	_construir_grupos()
	_construir_dock()
	_construir_inspiracion(lamina)
	_construir_puntos_hojas()
	_preparar_pedidos()
	_preparar_mezcla()
	_preparar_objetivos()
	# Ficha §12.5: encuadre de arranque (mundo grande: zoom 1 mirando el horizonte; si no, la hoja entera).
	lienzo.encuadre_inicial()
	# La hoja quedo armada: esa es la foto a la que vuelve "reiniciar" (y el historial empieza vacio).
	lienzo.fijar_inicio()
	_colocar_botones_edicion()

	_segundos_recordar = float(_cfg.get("segundos_recordar_mostrar", 0.0))
	_recordado = false
	_boton_visible_desde = 0.0
	boton_mostrar.visible = false
	boton_mostrar.scale = Vector2.ONE
	if _tween_mostrar != null and _tween_mostrar.is_valid():
		_tween_mostrar.kill()

	var intro := _linea("intro") if hoja["primera_de_etapa"] else _linea_al_azar("siguiente")
	var espera := 0.0
	if lienzo.stickers_objeto and _inspiracion.visible:
		# §1.7: la tarjeta de inspiracion se abre grande mientras Coco la narra y despues se encoge.
		abrir_inspiracion()
		var voz_inspiracion := str((_inspiracion.get_meta("datos", {}) as Dictionary).get("voz", ""))
		espera = maxf(5.0, _duracion_voz(voz_inspiracion) + 1.0)
		_despues_en_hoja(espera, _cerrar_inspiracion)
		espera += 0.3
	else:
		_reproducir_voz("intro", intro)
		espera = _duracion_voz(intro) + 0.5
	if _pedido_actual >= 0:
		_voz_diferida("pedido", _ruta_pedido(), espera)
	elif lienzo.stickers_objeto:
		var primero := _objetivo_activo()
		if not primero.is_empty():
			_voz_diferida("objetivo", str(primero["datos"].get("voz", "")), espera)
	_actualizar_depuracion()


## Lienzo con tema: lugares fijos del fondo, clases, combinaciones, zonas y caminos iniciales.
func _preparar_escena(tema: Dictionary) -> void:
	var clases := {}
	for clase in ["vivos", "lugares", "decorados"]:
		for id in tema.get(clase, []):
			clases[str(id)] = clase.trim_suffix("s") if clase != "lugares" else "lugar"
	lienzo.clases = clases
	lienzo.combinaciones = _cfg.get("combinaciones", [])
	# Ficha §12: las coordenadas del tema vienen en px de la pantalla (1280x720); en el mundo grande se
	# escalan (zonas, lugares de fondo, puestos y caminos iniciales). Los stickers no se agrandan.
	var e := lienzo.escala_mundo
	var zonas := {}
	var zonas_tema: Dictionary = tema.get("zonas", {})
	for nombre in zonas_tema:
		var r: Array = zonas_tema[nombre]
		zonas[nombre] = [float(r[0]) * e, float(r[1]) * e, float(r[2]) * e, float(r[3]) * e]
	lienzo.zonas = zonas
	# Lugares de fondo (§1.1): {id, ancla, radio, region?, lineal?}.
	for datos: Dictionary in tema.get("lugares_fondo", []):
		lienzo.poner_lugar_fijo(str(datos.get("id", "")), Laminas.vec(datos.get("ancla", null)) * e, float(datos.get("radio", 80.0)) * e,
			str(datos.get("region", "")), bool(datos.get("lineal", false)))
	# Lugares que ya vienen puestos (el granero de la granja): stickers normales.
	for datos: Dictionary in tema.get("puestos", []):
		var puesto: StickerVivo = lienzo.poner_sticker(str(datos.get("sticker", "")), Laminas.vec(datos.get("pos", null)) * e, float(datos.get("escala", 1.0)))
		puesto.set_meta("puesto", true)
	for datos: Dictionary in tema.get("caminos_iniciales", []):
		var puntos := PackedVector2Array()
		for p in datos.get("puntos", []):
			puntos.append(Laminas.vec(p) * e)
		lienzo.agregar_camino(puntos, str(datos.get("tipo", "sendero")), false)
	var caminos: Array = tema.get("caminos", [])
	if not caminos.is_empty():
		lienzo.tipo_camino = str(caminos[0])
	# Fisica (§10): gravedad si hay cielo y no es espacio; Maxi cae mas lento y con mas "¡puff!".
	lienzo.caida_suave = _perfil == "semilla"
	lienzo.preparar_fisica(tema)


# ---------------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------------

func _construir_interfaz() -> void:
	_estilizar_boton(_boton_salir, Color("#FFF8EE"))
	_estilizar_boton(_boton_cometa, Color("#CFF5F1"))
	var flecha := _icono(_boton_salir, _dibujar_flecha)
	flecha.queue_redraw()

	lienzo = Lienzo.new()
	_ui.add_child(lienzo)
	_ui.move_child(lienzo, 0)
	lienzo.position = Vector2.ZERO
	lienzo.toque_iniciado.connect(_al_tocar_lienzo)
	lienzo.color_usado.connect(_al_usar_color)
	lienzo.sello_puesto.connect(_al_poner_sello)
	lienzo.region_rellenada.connect(_al_rellenar_region)
	lienzo.celda_pintada.connect(func(_c: bool) -> void: _sfx_suave(SFX_TOQUE))
	lienzo.lamina_completa.connect(_al_completar_lamina)
	lienzo.nota.connect(_tocar_nota)
	lienzo.purpurina_quieta.connect(_lluvia_dorada)
	lienzo.color_ciclado.connect(_al_ciclar_color)
	lienzo.sticker_tocado.connect(_al_tocar_sticker)
	lienzo.sticker_cambiado.connect(_revisar_objetivos)
	lienzo.sticker_borrado.connect(_al_borrar_sticker)
	lienzo.camino_creado.connect(_al_crear_camino)
	lienzo.llegada.connect(_al_llegar)
	lienzo.vuelta.connect(_al_dar_vuelta)
	lienzo.vivo_subio.connect(func(vivo: Control) -> void:
		# `orden` cuenta un mismo viaje continuo: cada subida empieza un historial nuevo.
		_historial_viajes.erase(vivo.get_instance_id())
		_sfx_suave(SFX_ELEGIR))
	lienzo.combinacion.connect(_al_combinar)
	lienzo.zoom_cambiado.connect(_al_cambiar_zoom)
	lienzo.caida_iniciada.connect(_al_empezar_caida)
	lienzo.aterrizo.connect(_al_aterrizar)
	lienzo.sol_quemo.connect(_al_quemar_sol)
	lienzo.historial_cambiado.connect(_al_cambiar_historial)
	lienzo.montado.connect(_al_montar)
	lienzo.camino_borrado.connect(func(_c: Dictionary) -> void:
		reproducir_sfx(SFX_PUF)
		_revisar_objetivos())

	_puntos_hojas = Control.new()
	_puntos_hojas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_puntos_hojas)
	_puntos_hojas.position = Vector2(440, 8)
	_puntos_hojas.size = Vector2(400, 40)
	_puntos_hojas.draw.connect(_dibujar_puntos_hojas)

	_burbuja = Control.new()
	_burbuja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_burbuja)
	_burbuja.position = Vector2(970, 300)
	_burbuja.size = Vector2(140, 66)
	_burbuja.draw.connect(_dibujar_burbuja)
	_burbuja.hide()

	boton_mostrar = Button.new()
	boton_mostrar.focus_mode = Control.FOCUS_NONE
	boton_mostrar.tooltip_text = "Mostrar el dibujo a Coco"
	boton_mostrar.custom_minimum_size = RECT_MOSTRAR.size
	_ui.add_child(boton_mostrar)
	boton_mostrar.position = RECT_MOSTRAR.position
	boton_mostrar.size = RECT_MOSTRAR.size
	boton_mostrar.pivot_offset = RECT_MOSTRAR.size / 2.0
	_estilizar_boton(boton_mostrar, Color("#FFE3F1"))
	var cara := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = _anfitriona.texture
	atlas.region = Rect2(38, 20, 218, 218)
	cara.texture = atlas
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton_mostrar.add_child(cara)
	cara.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cara.offset_left = 10
	cara.offset_top = 6
	cara.offset_right = -10
	cara.offset_bottom = -14
	_icono(boton_mostrar, _dibujar_marquito)
	boton_mostrar.pressed.connect(mostrar_a_coco)
	boton_mostrar.hide()

	_cresta = Cresta.new()
	_anfitriona.add_child(_cresta)
	_cresta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cresta.preparar(_anfitriona.texture)

	_objetivos_ui = Control.new()
	_objetivos_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_objetivos_ui)

	_dock = Control.new()
	_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_dock)

	# Deshacer (flecha curva) y reiniciar (escoba que se mantiene presionada), sin texto (§10.3-10.4).
	_boton_deshacer = Button.new()
	_boton_deshacer.focus_mode = Control.FOCUS_NONE
	_boton_deshacer.tooltip_text = "deshacer"
	_boton_deshacer.custom_minimum_size = Vector2(64, 64)
	_ui.add_child(_boton_deshacer)
	_estilizar_boton(_boton_deshacer, Color("#FFF8EE"))
	_boton_deshacer.set_meta("dibujo", _icono(_boton_deshacer, _dibujar_icono_deshacer))
	_boton_deshacer.pressed.connect(deshacer)
	_boton_reiniciar = Button.new()
	_boton_reiniciar.focus_mode = Control.FOCUS_NONE
	_boton_reiniciar.tooltip_text = "reiniciar"
	_boton_reiniciar.custom_minimum_size = Vector2(64, 64)
	_ui.add_child(_boton_reiniciar)
	_estilizar_boton(_boton_reiniciar, Color("#FFF8EE"), false)
	_icono(_boton_reiniciar, _dibujar_icono_reiniciar)
	_anillo_reiniciar = _icono(_boton_reiniciar, _dibujar_anillo_reiniciar)
	_boton_reiniciar.button_down.connect(_empezar_a_mantener)
	_boton_reiniciar.button_up.connect(_soltar_reiniciar)

	_inspiracion = Button.new()
	_inspiracion.focus_mode = Control.FOCUS_NONE
	_inspiracion.tooltip_text = "Idea de Coco"
	_ui.add_child(_inspiracion)
	_inspiracion.position = RECT_INSPIRACION.position
	_inspiracion.size = RECT_INSPIRACION.size
	_inspiracion.pivot_offset = RECT_INSPIRACION.size / 2.0
	_inspiracion.pressed.connect(abrir_inspiracion)
	_inspiracion.button_down.connect(_rebote.bind(_inspiracion))
	_inspiracion.hide()

	_barra = Control.new()
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_barra)
	_barra.hide()

	# Velo: cualquier toque fuera del popup (tambien sobre el lienzo) lo cierra sin pintar.
	_velo = Button.new()
	_velo.flat = true
	_velo.focus_mode = Control.FOCUS_NONE
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		_velo.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	_ui.add_child(_velo)
	_velo.position = Vector2.ZERO
	_velo.size = Vector2(1280, 720)
	_velo.pressed.connect(func() -> void:
		_cerrar_popup()
		_cerrar_inspiracion())
	_velo.hide()
	_popup = Control.new()
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_popup)
	_popup.hide()
	_inspiracion_grande = Control.new()
	_inspiracion_grande.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_inspiracion_grande)
	_inspiracion_grande.hide()

	_selector = Control.new()
	_selector.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_selector)
	_selector.position = RECT_LIENZO.position
	_selector.size = RECT_LIENZO.size
	_selector.hide()

	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	degradado.colors = PackedColorArray(Figura.COLORES_ARCOIRIS)
	_confeti.color_initial_ramp = degradado

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(COLOR_CONTORNO, 0.85)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(12)
	_panel_depuracion.add_theme_stylebox_override("normal", panel)
	_panel_depuracion.add_theme_color_override("font_color", Color("#FFF8EE"))
	_preparar_notas()
	_ui.move_child(_efectos, -1)
	_ui.move_child(_panel_depuracion, -1)


func _icono(padre: Control, dibujo: Callable) -> Control:
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(dibujo.bind(icono))
	return icono


func _vaciar(contenedor: Control) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


func _lado_boton() -> float:
	return 100.0 if _perfil == "semilla" else 84.0


# ---------------------------------------------------------------------------
# Dock de herramientas y popups (un solo popup abierto a la vez)
# ---------------------------------------------------------------------------

## Colores de la hoja: leyenda numerada (mosaico), primarios (mezcla) o la paleta.
func _preparar_colores() -> void:
	_entradas_color.clear()
	if not lienzo.mosaico.is_empty():
		var colores: Dictionary = lienzo.mosaico.get("colores", {})
		var claves := colores.keys()
		claves.sort()
		for clave in claves:
			_entradas_color.append({"id": "", "color": Color(str(colores[clave])), "numero": str(clave)})
	elif _encargo == "mezcla_paleta":
		for id in _cfg.get("paleta", PRIMARIOS):
			_entradas_color.append({"id": str(id), "color": Colores.color(str(id)), "numero": ""})
	else:
		for id in _cfg.get("paleta", PALETA_SEMILLA if _perfil == "semilla" else PALETA_COMPLETA):
			_entradas_color.append({"id": str(id), "color": Colores.color(str(id)), "numero": ""})
	if not _entradas_color.is_empty() and _encargo != "mezcla_paleta":
		var inicial := str(_cfg.get("color_inicial", ""))
		var elegido: Dictionary = _entradas_color[0]
		for entrada: Dictionary in _entradas_color:
			if entrada["id"] == inicial:
				elegido = entrada
		lienzo.color_actual = elegido["color"]
	lienzo.colores_ciclo = []
	if _perfil == "semilla":
		for entrada: Dictionary in _entradas_color:
			lienzo.colores_ciclo.append(entrada["color"])


## Reparte las herramientas de la hoja en grupos. Con tema: `vivos` + `lugares` + `caminos` van en
## "Cosas que se mueven" y `decorados` en "Decorados". Sin tema, los sellos van en "Decorados".
func _construir_grupos() -> void:
	_grupos = {}
	if not _entradas_color.is_empty():
		_grupos["colores"] = ["colores"]
	var pinceles: Array = []
	var decorados: Array = []
	var cosas: Array = []
	var lista: Array = _cfg.get("herramientas", _herramientas_por_defecto())
	for id in lista:
		var clave := str(id)
		if clave in PINCELES:
			pinceles.append(clave)
		elif clave.begins_with("sello_"):
			decorados.append(clave)
	var tema: Dictionary = _hojas[_indice_hoja].get("tema", {})
	if not tema.is_empty():
		var vivos: Array = tema.get("vivos", [])
		var lugares: Array = tema.get("lugares", [])
		var decos: Array = tema.get("decorados", [])
		if vivos.is_empty() and lugares.is_empty() and decos.is_empty():
			for id in tema.get("stickers", []):
				match Stickers.clase(str(id)):
					"vivo": vivos.append(id)
					"lugar": lugares.append(id)
					_: decos.append(id)
		for id in vivos + lugares:
			cosas.append("sello_" + str(id))
		var caminos: Array = tema.get("caminos", [])
		if caminos.is_empty() and not (tema.get("conector", {}) as Dictionary).is_empty():
			caminos = [str(tema["conector"].get("tipo", "sendero"))]
		for tipo in caminos:
			cosas.append("camino_" + str(tipo))
		decorados = []
		for id in decos:
			decorados.append("sello_" + str(id))
	# Ficha §11.3: los personajes ("amigos") en todas las escenas con tema; el que juega va primero.
	var amigos: Array = []
	if not tema.is_empty():
		for id in _cfg.get("amigos", []):
			if Stickers.tiene(str(id)):
				amigos.append("sello_" + str(id))
		var propio := "sello_" + obtener_id_personaje()
		if amigos.has(propio):
			amigos.erase(propio)
			amigos.push_front(propio)
	if not amigos.is_empty():
		if _perfil == "semilla":
			cosas.append_array(amigos)
		else:
			_grupos["amigos"] = amigos
	if _perfil == "semilla" and not cosas.is_empty():
		# Maxi: menos grupos. Sus decorados (el huevo) van junto a los vivos y el camino.
		cosas = cosas + decorados
		decorados = []
	if not pinceles.is_empty():
		_grupos["pinceles"] = pinceles
	if not cosas.is_empty():
		_grupos["cosas"] = cosas
	if not decorados.is_empty():
		_grupos["decorados"] = decorados
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	if lamina.has("trajes"):
		var trajes: Array = []
		for id in lamina.get("orden_trajes", lamina["trajes"].keys()):
			trajes.append("traje_" + str(id))
		_grupos["trajes"] = trajes
	if lienzo.zoom_permitido:
		_grupos["lupa"] = ["lupa"]
	# La herramienta inicial del nivel se respeta aunque no este en el dock (el arcoiris del dedo magico).
	var inicial := str(_cfg.get("herramienta_inicial", ""))
	if inicial.begins_with("sello_") and not _herramienta_existe(inicial):
		inicial = ""
	if inicial == "":
		inicial = "pincel" if pinceles.has("pincel") else (str(pinceles[0]) if not pinceles.is_empty() else (str(cosas[0]) if not cosas.is_empty() else "pincel"))
	_elegir_herramienta(inicial, false)


func _herramienta_existe(id: String) -> bool:
	for grupo in _grupos:
		if (_grupos[grupo] as Array).has(id):
			return true
	return false


func _herramientas_por_defecto() -> Array:
	match _perfil:
		"semilla":
			return ["pincel", "sello_dino", "sello_auto"]
		"brote":
			return ["pincel", "pincel_corazon", "pincel_estrella", "goma"]
	return ["pincel", "pincel_grueso", "pincel_estrella", "purpurina", "goma"]


func _construir_dock() -> void:
	_vaciar(_dock)
	_dock_botones.clear()
	var lado := _lado_boton()
	var sep := 10.0 if _perfil == "semilla" else 8.0
	var y := DOCK_Y
	for grupo in ["colores", "pinceles", "cosas", "decorados", "amigos", "trajes", "lupa"]:
		if not _grupos.has(grupo):
			continue
		var boton := Button.new()
		boton.focus_mode = Control.FOCUS_NONE
		boton.tooltip_text = grupo
		boton.custom_minimum_size = Vector2(64, 64)
		_dock.add_child(boton)
		boton.position = Vector2(DOCK_X + (96.0 - lado) / 2.0, y)
		boton.size = Vector2(lado, lado)
		boton.pivot_offset = boton.size / 2.0
		boton.set_meta("grupo", grupo)
		_estilizar_boton(boton, Color("#FFF8EE"))
		boton.set_meta("dibujo", _icono(boton, _dibujar_dock))
		boton.pressed.connect(_al_tocar_dock.bind(grupo))
		_dock_botones.append({"boton": boton, "grupo": grupo})
		y += lado + sep
	# "Ver todo": aparece solo con zoom, debajo de la lupa.
	_boton_ver_todo = Button.new()
	_boton_ver_todo.focus_mode = Control.FOCUS_NONE
	_boton_ver_todo.tooltip_text = "ver_todo"
	_boton_ver_todo.custom_minimum_size = Vector2(64, 64)
	_dock.add_child(_boton_ver_todo)
	# "Ver todo" va a la derecha de la lupa (el ultimo boton): con el grupo de amigos, abajo no cabe.
	_boton_ver_todo.position = Vector2(DOCK_X + (96.0 - lado) / 2.0 + lado + sep, y - lado - sep) if not _dock_botones.is_empty() else Vector2(DOCK_X, y)
	_boton_ver_todo.size = Vector2(lado, lado)
	_boton_ver_todo.set_meta("grupo", "ver_todo")
	_estilizar_boton(_boton_ver_todo, Color("#CFF5F1"))
	_boton_ver_todo.set_meta("dibujo", _icono(_boton_ver_todo, _dibujar_dock))
	_boton_ver_todo.pressed.connect(func() -> void:
		_sfx_suave(SFX_ELEGIR)
		lienzo.ver_todo())
	_boton_ver_todo.visible = lienzo.zoom > lienzo.zoom_minimo() + 0.01
	_refrescar_dock()


func _refrescar_dock() -> void:
	for entrada: Dictionary in _dock_botones:
		var boton: Button = entrada["boton"]
		var grupo: String = entrada["grupo"]
		var activo := (grupo == "lupa" and (lienzo.lupa_armada or lienzo.zoom > lienzo.zoom_base() + 0.01)) or \
			(grupo != "colores" and grupo != "lupa" and (_grupos.get(grupo, []) as Array).has(lienzo.herramienta))
		_estilizar_boton(boton, Color("#FFE38A") if activo else Color("#FFF8EE"), false)
		(boton.get_meta("dibujo") as Control).queue_redraw()


func _al_tocar_dock(grupo: String) -> void:
	_sfx_suave(SFX_ELEGIR)
	if grupo == "lupa":
		_cerrar_popup()
		usar_lupa()
		return
	var items: Array = _grupos.get(grupo, [])
	# Un grupo con una sola herramienta (el pincel de Maxi) la elige directo, sin popup.
	if grupo != "colores" and items.size() == 1:
		_cerrar_popup()
		_elegir_herramienta(str(items[0]))
		return
	if _popup.visible and _popup_grupo == grupo:
		_cerrar_popup()
		return
	abrir_popup(grupo)


## Lupa (lienzo-escenas-retos.md §1.7 y ficha §12.4): sin acercar, queda ARMADA y el siguiente toque
## en el lienzo acerca ahi (desde la hoja entera al zoom normal; desde el normal, al doble). Acercada,
## vuelve al zoom normal sin perder lo que se miraba. Armada, otro toque la desarma. La pinza de dos
## dedos y la rueda del mouse quedan como extra. Publica para QA.
func usar_lupa() -> void:
	if lienzo.lupa_armada:
		lienzo.lupa_armada = false
	elif lienzo.zoom > lienzo.zoom_base() + 0.01:
		lienzo.volver_a_base()
	else:
		lienzo.lupa_armada = true
	_refrescar_dock()


## Abre el popup del grupo al lado de su boton del dock. Publica para QA.
func abrir_popup(grupo: String) -> void:
	_cerrar_popup()
	_cerrar_inspiracion()
	_ocultar_barra()
	_popup_grupo = grupo
	_vaciar(_popup)
	_botones_color.clear()
	_botones_herramienta.clear()
	var filas: Array = []
	var lado := _lado_boton()
	if grupo == "colores":
		lado = 100.0 if _perfil == "semilla" else 72.0
		var columnas := 3 if _perfil == "semilla" else 7
		var fila: Array = []
		for entrada: Dictionary in _entradas_color:
			fila.append(entrada)
			if fila.size() >= columnas:
				filas.append(fila)
				fila = []
		if not fila.is_empty():
			filas.append(fila)
	elif grupo == "cosas":
		var vivos: Array = []
		var lugares: Array = []
		var caminos: Array = []
		var amigos: Array = []
		for id in _grupos.get(grupo, []):
			var clave := str(id)
			if Stickers.es_personaje(clave.trim_prefix("sello_")):
				amigos.append(clave)
			elif clave.begins_with("camino_"):
				caminos.append(clave)
			elif lienzo.clase_de(clave.trim_prefix("sello_")) == "lugar":
				lugares.append(clave)
			else:
				vivos.append(clave)
		for lista in [vivos, lugares, caminos]:
			if not lista.is_empty():
				filas.append(lista)
		for i in range(0, amigos.size(), 6):
			filas.append(amigos.slice(i, i + 6))
	else:
		var items: Array = _grupos.get(grupo, [])
		for i in range(0, items.size(), 6):
			filas.append(items.slice(i, i + 6))
	var sep := 10.0
	var columnas_max := 0
	for fila: Array in filas:
		columnas_max = maxi(columnas_max, fila.size())
	var extra_mezcla := 0.0
	if grupo == "colores" and _encargo == "mezcla_paleta":
		extra_mezcla = 160.0
	var tam := Vector2(columnas_max * lado + (columnas_max - 1) * sep + 32.0 + extra_mezcla, filas.size() * lado + (filas.size() - 1) * sep + 32.0)
	if grupo == "colores" and _encargo == "mezcla_paleta" and not _mis_colores.is_empty():
		tam.y += lado + sep
	var boton_dock: Button = null
	for entrada: Dictionary in _dock_botones:
		if entrada["grupo"] == grupo:
			boton_dock = entrada["boton"]
	var y0 := boton_dock.position.y if boton_dock != null else DOCK_Y
	_popup.position = Vector2(DOCK_X + 96.0 + 14.0, clampf(y0 - 16.0, 8.0, 712.0 - tam.y))
	_popup.size = tam
	_popup.pivot_offset = Vector2(0, tam.y / 2.0)
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFF8EE")
	estilo.border_color = COLOR_CONTORNO
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(28)
	estilo.shadow_color = Color(COLOR_CONTORNO, 0.35)
	estilo.shadow_size = 8
	panel.add_theme_stylebox_override("panel", estilo)
	_popup.add_child(panel)
	panel.size = tam
	for f in filas.size():
		var fila: Array = filas[f]
		for c in fila.size():
			var rect := Rect2(16.0 + c * (lado + sep), 16.0 + f * (lado + sep), lado, lado)
			if grupo == "colores":
				var entrada: Dictionary = fila[c]
				var boton := _boton_color(entrada["color"], str(entrada["numero"]), rect)
				var datos := {"boton": boton, "color": entrada["color"], "id": entrada["id"], "numero": entrada["numero"]}
				boton.set_meta("elegido", (entrada["color"] as Color).is_equal_approx(lienzo.color_actual) and _encargo != "mezcla_paleta")
				_botones_color.append(datos)
				boton.pressed.connect(_al_elegir_color.bind(datos))
			else:
				var id := str(fila[c])
				var boton := _boton_item(id, rect)
				boton.pressed.connect(_al_elegir_item.bind(id))
	if grupo == "colores" and _encargo == "mezcla_paleta":
		_armar_platito(Vector2(tam.x - extra_mezcla - 8.0, 8.0), lado, Vector2(16.0, filas.size() * (lado + sep) + 16.0))
	_velo.show()
	_popup.show()
	_ui.move_child(_velo, -1)
	_ui.move_child(_popup, -1)
	_ui.move_child(_efectos, -1)
	_popup.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(_popup, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Coco nombra el grupo la primera vez en la hoja ("¡Colores!"): toda instruccion con voz.
	if not _grupos_nombrados.has(grupo):
		_grupos_nombrados[grupo] = true
		_reproducir_voz("grupo", _linea("grupo_" + grupo))


func _cerrar_popup() -> void:
	if _popup == null:
		return
	_popup.hide()
	_popup_grupo = ""
	_botones_color.clear()
	_botones_herramienta.clear()
	if _inspiracion_grande == null or not _inspiracion_grande.visible:
		_velo.hide()


func popup_abierto() -> String:
	return _popup_grupo if _popup.visible else ""


func _boton_color(color: Color, numero: String, rect: Rect2) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.flat = true
	boton.custom_minimum_size = Vector2(64, 64)
	boton.tooltip_text = "Color %s" % numero if numero != "" else "Color"
	_popup.add_child(boton)
	boton.position = rect.position
	boton.size = rect.size
	boton.set_meta("color", color)
	boton.set_meta("numero", numero)
	boton.set_meta("elegido", false)
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		boton.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	var dibujo := _icono(boton, _dibujar_mancha)
	boton.set_meta("dibujo", dibujo)
	boton.button_down.connect(_rebote.bind(boton))
	return boton


func _boton_item(id: String, rect: Rect2) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.tooltip_text = id
	boton.custom_minimum_size = Vector2(64, 64)
	_popup.add_child(boton)
	boton.position = rect.position
	boton.size = rect.size
	boton.pivot_offset = rect.size / 2.0
	boton.set_meta("id", id)
	var elegido := id == lienzo.herramienta or id == "traje_" + _traje
	_estilizar_boton(boton, Color("#FFE38A") if elegido else Color.WHITE)
	boton.set_meta("dibujo", _icono(boton, _dibujar_herramienta))
	_botones_herramienta.append({"boton": boton, "id": id})
	return boton


func _al_elegir_item(id: String) -> void:
	if id.begins_with("traje_"):
		_elegir_traje(id.trim_prefix("traje_"), false)
		_cerrar_popup()
		return
	_elegir_herramienta(id)
	_cerrar_popup()
	if id.begins_with("sello_") and lienzo.stickers_objeto:
		_nombrar_sticker(id.trim_prefix("sello_"), false)
	elif id.begins_with("camino_"):
		_primer_uso_especial("conector")


func _al_elegir_color(entrada: Dictionary) -> void:
	_sfx_suave(SFX_ELEGIR)
	if _encargo == "mezcla_paleta":
		_agregar_gota(str(entrada["id"]))
		return
	_seleccionar_color(entrada, true)
	_cerrar_popup()


func _seleccionar_color(entrada: Dictionary, con_reaccion: bool) -> void:
	lienzo.color_actual = entrada["color"]
	for otra: Dictionary in _botones_color:
		var boton: Button = otra["boton"]
		boton.set_meta("elegido", otra == entrada)
		(boton.get_meta("dibujo") as Control).queue_redraw()
	_refrescar_iconos()
	if con_reaccion and _perfil == "semilla":
		_reaccion_color(entrada["color"], true)


## Elige un color por id (o el n-esimo) sin abrir el popup. Publica para QA.
func elegir_color(indice: int) -> void:
	if indice < 0 or indice >= _entradas_color.size():
		return
	var entrada: Dictionary = _entradas_color[indice]
	if _encargo == "mezcla_paleta":
		_agregar_gota(str(entrada["id"]))
	else:
		_seleccionar_color(entrada, false)


func _al_ciclar_color(_color: Color) -> void:
	_refrescar_iconos()


func _refrescar_iconos() -> void:
	for entrada: Dictionary in _botones_herramienta:
		var boton: Button = entrada["boton"]
		if is_instance_valid(boton):
			(boton.get_meta("dibujo") as Control).queue_redraw()
	if _dock_botones.size() > 0:
		_refrescar_dock()


func _elegir_herramienta(id: String, con_sonido := true) -> void:
	if con_sonido:
		_sfx_suave(SFX_ELEGIR)
	lienzo.herramienta = id
	if id.begins_with("camino_"):
		lienzo.tipo_camino = id.trim_prefix("camino_")
	if not (id == "sello_dino" or Stickers.es_dino(id.trim_prefix("sello_"))):
		_dinos_seguidos = 0
	_ocultar_barra()
	_refrescar_iconos()


func _al_cambiar_zoom(zoom: float) -> void:
	if _boton_ver_todo != null and is_instance_valid(_boton_ver_todo):
		_boton_ver_todo.visible = zoom > lienzo.zoom_minimo() + 0.01
	if not _dock_botones.is_empty():
		_refrescar_dock()
	_ocultar_barra()
	_actualizar_depuracion()


## "Viste a Coco": cambia el traje conservando los colores de las partes que ya pinto.
func _elegir_traje(id: String, inicial: bool) -> void:
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	var trajes: Dictionary = lamina.get("trajes", {})
	if not trajes.has(id):
		return
	var colores := {}
	for region: Dictionary in lienzo.lamina.get("regiones", []):
		if not bool(region.get("fija", false)):
			colores[str(region.get("id", ""))] = region["color"]
	var combinada := lamina.duplicate(true)
	combinada.erase("trajes")
	var traje: Dictionary = trajes[id]
	combinada["regiones"] = _regiones_con_traje(lamina, traje)
	combinada["detalles"] = (traje.get("detalles_atras", []) as Array) + (lamina.get("detalles", []) as Array) + (traje.get("detalles", []) as Array)
	lienzo.poner_lamina(combinada)
	var regiones: Array = lienzo.lamina["regiones"]
	for i in regiones.size():
		var clave := str(regiones[i].get("id", ""))
		if colores.has(clave):
			lienzo.pintar_region(i, colores[clave])
	_traje = id
	if not inicial:
		_sfx_suave(SFX_RELLENO)
		_reaccion_anfitriona("salta")
		_reproducir_voz("traje", str(traje.get("voz", "")))
		_elegir_herramienta(lienzo.herramienta, false)


## Regiones de Coco con el traje: `regiones_atras` (la capa) va detras del cuerpo, justo despues del
## fondo y el piso; el resto del traje va encima.
func _regiones_con_traje(lamina: Dictionary, traje: Dictionary) -> Array:
	var base: Array = lamina.get("regiones", [])
	var atras: Array = traje.get("regiones_atras", [])
	var corte := 0
	while corte < base.size() and str(base[corte].get("id", "")) in ["fondo", "piso"]:
		corte += 1
	return base.slice(0, corte) + atras + base.slice(corte) + (traje.get("regiones", []) as Array)


func _construir_puntos_hojas() -> void:
	_puntos_hojas.visible = _hojas.size() > 1
	_puntos_hojas.queue_redraw()


func _dibujar_puntos_hojas() -> void:
	var n := _hojas.size()
	var lado := 30.0
	var sep := 12.0
	var x0 := (_puntos_hojas.size.x - (n * lado + (n - 1) * sep)) / 2.0
	for i in n:
		var centro := Vector2(x0 + i * (lado + sep) + lado / 2.0, _puntos_hojas.size.y / 2.0)
		var rect := Rect2(centro - Vector2(lado, lado * 0.8) / 2.0, Vector2(lado, lado * 0.8))
		var hecho := i < _indice_hoja
		var actual := i == _indice_hoja
		var fondo := Color("#FFF8EE") if actual else (DORADO if hecho else Color(1, 1, 1, 0.5))
		_puntos_hojas.draw_rect(rect, fondo)
		_puntos_hojas.draw_rect(rect, COLOR_CONTORNO, false, 3.0)
		if hecho:
			Figura.dibujar(_puntos_hojas, "estrella", Color.WHITE, centro, 9.0, false)


# ---------------------------------------------------------------------------
# Tarjeta de inspiracion (esquina superior izquierda)
# ---------------------------------------------------------------------------

## La tarjeta muestra la escena de ejemplo del tema (`inspiracion`, armada con nuestros stickers) o,
## en las zonas 2-5, el modelo de la lamina o la imagen de la nave. Tocarla la agranda y Coco la narra.
func _construir_inspiracion(lamina: Dictionary) -> void:
	_vaciar(_inspiracion)
	var datos := _datos_inspiracion(lamina)
	_inspiracion.visible = not datos.is_empty()
	if datos.is_empty():
		return
	_inspiracion.set_meta("datos", datos)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color("#FFF8EE")
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(4)
		caja.set_corner_radius_all(16)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
		caja.shadow_size = 4
		_inspiracion.add_theme_stylebox_override(estado, caja)
	_inspiracion.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_inspiracion.rotation = deg_to_rad(-3.0)
	var dibujo := Control.new()
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dibujo.clip_contents = true
	_inspiracion.add_child(dibujo)
	dibujo.position = Vector2(8, 8)
	dibujo.size = RECT_INSPIRACION.size - Vector2(16, 16)
	dibujo.draw.connect(_dibujar_inspiracion.bind(dibujo, datos))
	# Una lupita en la esquina: "tocame para verla grande".
	var lupita := _icono(_inspiracion, func(icono: Control) -> void:
		var c := icono.size - Vector2(20, 20)
		icono.draw_circle(c, 15.0, Color.WHITE)
		icono.draw_arc(c, 15.0, 0, TAU, 20, COLOR_CONTORNO, 3.0, true)
		icono.draw_arc(c + Vector2(-2, -2), 6.0, 0, TAU, 14, COLOR_CONTORNO, 2.5, true)
		icono.draw_line(c + Vector2(2, 2), c + Vector2(8, 8), COLOR_CONTORNO, 3.0, true))
	lupita.queue_redraw()


func _datos_inspiracion(lamina: Dictionary) -> Dictionary:
	var tema: Dictionary = _hojas[_indice_hoja].get("tema", {})
	if not tema.is_empty() and tema.has("inspiracion"):
		var datos: Dictionary = (tema["inspiracion"] as Dictionary).duplicate()
		datos["fondo"] = Laminas.preparar(tema.get("fondo", {}))
		datos["tamano"] = Vector2(RECT_LIENZO.size)
		# Ficha §12.7: la tarjeta es una IDEA de la hoja entera, no un mapa a escala: sus stickers
		# conservan el tamano de siempre aunque el mundo sea grande (a la mitad no se reconocen).
		return datos
	var imagen := str(_cfg.get("imagen_modelo", ""))
	if imagen != "" and bool(_cfg.get("modelo", false)) and ResourceLoader.exists(imagen):
		return {"imagen": imagen, "voz": _linea("intro")}
	if bool(_cfg.get("modelo", false)) and not lamina.is_empty() and str(lamina.get("tipo", "zonas")) == "zonas":
		var copia := Laminas.preparar(lamina)
		for region: Dictionary in copia["regiones"]:
			if region.has("sugerido"):
				region["color"] = Color(str(region["sugerido"]))
		var tam: Array = lamina.get("tamano", [824, 530])
		return {"fondo": copia, "tamano": Vector2(float(tam[0]), float(tam[1])), "elementos": [], "voz": _linea("intro"),
			"papel": str(_cfg.get("papel", "#FFF8EE"))}
	return {}


func _dibujar_inspiracion(lienzo_ui: Control, datos: Dictionary) -> void:
	if datos.has("imagen"):
		var textura: Texture2D = load(str(datos["imagen"]))
		var escala_img := minf(lienzo_ui.size.x / textura.get_width(), lienzo_ui.size.y / textura.get_height())
		var tam_img := textura.get_size() * escala_img
		lienzo_ui.draw_texture_rect(textura, Rect2((lienzo_ui.size - tam_img) / 2.0, tam_img), false)
		return
	var tam: Vector2 = datos.get("tamano", Vector2(RECT_LIENZO.size))
	var escala := minf(lienzo_ui.size.x / tam.x, lienzo_ui.size.y / tam.y)
	var desfase := (lienzo_ui.size - tam * escala) / 2.0
	lienzo_ui.draw_rect(Rect2(desfase, tam * escala), Color(str(datos.get("papel", "#FFF8EE"))))
	Laminas.dibujar(lienzo_ui, datos.get("fondo", {}), desfase, escala)
	for camino: Dictionary in datos.get("caminos", []):
		var puntos := PackedVector2Array()
		for p in camino.get("puntos", []):
			puntos.append(desfase + Laminas.vec(p) * escala)
		Lienzo.dibujar_camino(lienzo_ui, Lienzo.remuestrear(Lienzo.suavizar(puntos), 6.0), str(camino.get("tipo", "sendero")), escala)
	for elemento: Dictionary in datos.get("elementos", []):
		var id := str(elemento.get("sticker", ""))
		var radio := float(lienzo.lado_sello) * 0.45 * float(elemento.get("escala", 1.0)) * escala
		if Stickers.clase(id) == "lugar":
			radio *= Stickers.ESCALA_LUGAR
		Stickers.dibujar(lienzo_ui, id, Stickers.color_por_defecto(id), desfase + Laminas.vec(elemento.get("pos", null)) * escala, radio)


## La tarjeta se abre grande sobre el lienzo y Coco la narra. Se cierra con cualquier toque.
func abrir_inspiracion() -> void:
	if not _inspiracion.visible:
		return
	_cerrar_popup()
	_sfx_suave(SFX_MOSTRAR)
	var datos: Dictionary = _inspiracion.get_meta("datos", {})
	_vaciar(_inspiracion_grande)
	var tam := Vector2(880, 495)
	_inspiracion_grande.position = (Vector2(1280, 720) - tam) / 2.0
	_inspiracion_grande.size = tam
	_inspiracion_grande.pivot_offset = Vector2.ZERO
	var marco := Panel.new()
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFF8EE")
	estilo.border_color = COLOR_CONTORNO
	estilo.set_border_width_all(6)
	estilo.set_corner_radius_all(26)
	estilo.shadow_color = Color(COLOR_CONTORNO, 0.4)
	estilo.shadow_size = 12
	marco.add_theme_stylebox_override("panel", estilo)
	_inspiracion_grande.add_child(marco)
	marco.size = tam
	var dibujo := Control.new()
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dibujo.clip_contents = true
	_inspiracion_grande.add_child(dibujo)
	dibujo.position = Vector2(14, 14)
	dibujo.size = tam - Vector2(28, 28)
	dibujo.draw.connect(_dibujar_inspiracion.bind(dibujo, datos))
	_velo.show()
	_inspiracion_grande.show()
	_ui.move_child(_velo, -1)
	_ui.move_child(_inspiracion_grande, -1)
	_ui.move_child(_efectos, -1)
	_inspiracion_grande.scale = Vector2(0.3, 0.3)
	_inspiracion_grande.position = RECT_INSPIRACION.position
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_inspiracion_grande, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_inspiracion_grande, "position", (Vector2(1280, 720) - tam) / 2.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reaccion_anfitriona("salta")
	_reproducir_voz("inspiracion", str(datos.get("voz", "")))


func _cerrar_inspiracion() -> void:
	if _inspiracion_grande == null or not _inspiracion_grande.visible:
		return
	_inspiracion_grande.hide()
	if not _popup.visible:
		_velo.hide()


func inspiracion_abierta() -> bool:
	return _inspiracion_grande.visible


# ---------------------------------------------------------------------------
# Reacciones al pintar
# ---------------------------------------------------------------------------

func _al_tocar_lienzo() -> void:
	_hubo_toque = true
	# §6.1: Nicole pausa el reloj de pistas 10 s tras cualquier toque; Sofia lo reinicia.
	if _perfil == "brote":
		_pausa_pista = 10.0
	elif _perfil == "estrella":
		_reiniciar_pistas()
	if _valvula_lista and _perfil == "semilla":
		_usar_valvula()
	if _barra.visible and lienzo.arrastrando() != lienzo.seleccionado:
		_ocultar_barra()
	if lienzo.herramienta in ["pincel_corazon", "pincel_estrella", "purpurina", "arcoiris"]:
		_primer_uso_especial(lienzo.herramienta)
	if lienzo.herramienta.begins_with("sello_"):
		_sfx_suave(SFX_SELLO)
	elif lienzo.herramienta == "balde" or lienzo.rellenar_con_toque:
		pass
	else:
		_sfx_suave(SFX_TOQUE)


func _al_usar_color(color: Color) -> void:
	var ahora := Time.get_ticks_msec()
	var nuevo_en_partida := true
	for c: Color in _colores_usados:
		if c.is_equal_approx(color):
			nuevo_en_partida = false
	if nuevo_en_partida:
		_colores_usados.append(color)
	var clave := color.to_html(false)
	var nuevo_en_hoja := not _colores_hoja.has(clave)
	_colores_hoja[clave] = true
	if nuevo_en_hoja:
		_revisar_objetivos()
	_cresta.imitar(_ultimos_colores())
	_recientes.append([ahora, color])
	while not _recientes.is_empty() and ahora - int(_recientes[0][0]) > 8000:
		_recientes.pop_front()
	if _revisar_arcoiris(ahora):
		return
	if _encargo == "coco_pide" and _revisar_pedido_color(color):
		return
	if nuevo_en_hoja and _perfil != "semilla" and lienzo.mosaico.is_empty():
		_reaccion_color(color, false)
	elif nuevo_en_hoja and _perfil == "semilla" and lienzo.herramienta != "arcoiris":
		_reaccion_color(color, false)
	_actualizar_depuracion()


## Los ultimos colores distintos usados (el mas nuevo al final), para la cresta.
func _ultimos_colores() -> Array:
	var lista: Array = []
	for i in range(_recientes.size() - 1, -1, -1):
		var c: Color = _recientes[i][1]
		var repetido := false
		for otro: Color in lista:
			if otro.is_equal_approx(c):
				repetido = true
		if not repetido:
			lista.push_front(c)
		if lista.size() >= Cresta.MAX_FRANJAS:
			break
	if lista.is_empty() and not _colores_usados.is_empty():
		lista.append(_colores_usados.back())
	return lista


## Momento memorable universal (ficha §3.10): 4 colores distintos seguidos -> cresta arcoiris.
func _revisar_arcoiris(ahora: int) -> bool:
	if ahora - _ms_ultimo_arcoiris < 20000:
		return false
	var distintos: Array = []
	for dato in _recientes:
		var c: Color = dato[1]
		var ya := false
		for otro: Color in distintos:
			if otro.is_equal_approx(c):
				ya = true
		if not ya:
			distintos.append(c)
	if distintos.size() < 4:
		return false
	_ms_ultimo_arcoiris = ahora
	_cresta.imitar(Figura.COLORES_ARCOIRIS.duplicate())
	_reaccion_anfitriona("baila")
	_estallido(_anfitriona.global_position + Vector2(_anfitriona.size.x * 0.55, 20), 12, Figura.COLORES_ARCOIRIS, 1.2)
	_reproducir_voz("arcoiris", _linea_al_azar("arcoiris"))
	_despues(2.2, func() -> void: _cresta.imitar(_ultimos_colores()))
	return true


func _reaccion_color(color: Color, forzar: bool) -> void:
	var ahora := Time.get_ticks_msec()
	var audio := get_node_or_null("/root/Audio")
	if not forzar and (ahora - _ms_ultima_reaccion < SEGUNDOS_ENTRE_REACCIONES * 1000.0 or (audio != null and audio.esta_hablando())):
		return
	_ms_ultima_reaccion = ahora
	var id := _id_de_color(color)
	var patron := str(_cfg.get("voces_colores", ""))
	if patron != "" and id != "":
		_reproducir_voz("color", patron % id)
	_reaccion_anfitriona("salta")


func _id_de_color(color: Color) -> String:
	var candidatos: Array = []
	for entrada: Dictionary in _entradas_color:
		if str(entrada["id"]) != "":
			candidatos.append(entrada["id"])
	for id in Colores.COLORES:
		if Colores.color(id).is_equal_approx(color):
			return id
	return Colores.mas_cercano(color, candidatos if _encargo != "mezcla_paleta" else [])


func _al_poner_sello(tipo: String, _posicion: Vector2) -> void:
	_sellos_hoja += 1
	if tipo == "dino" or Stickers.es_dino(tipo):
		_usados_especiales["dinos_estampados"] = _dinos_estampados() + 1
	if lienzo.stickers_objeto:
		_nombrar_sticker(tipo, false)
	else:
		_primer_uso_especial("sello_" + tipo)
	if tipo == "dino" or Stickers.es_dino(tipo):
		_dinos_seguidos += 1
		if lienzo.sellos_vivos and _dinos_seguidos >= 3 and not lienzo.stickers_objeto:
			_dinos_seguidos = 0
			_despues(0.35, func() -> void: lienzo.caminar_sellos("dino", 3))
			if _paseos_dino < 2:
				_reproducir_voz("dino_camina", _linea_al_azar("dino_camina"))
			_paseos_dino += 1
	else:
		_dinos_seguidos = 0
	_revisar_objetivos()


func _primer_uso_especial(herramienta: String) -> void:
	if _usados_especiales.has(herramienta):
		return
	_usados_especiales[herramienta] = true
	var clave := "uso_" + herramienta
	var linea := _linea_al_azar(clave)
	if linea != "":
		_reproducir_voz(clave, linea)
	if herramienta in ["pincel_corazon", "sello_corazon"] and _perfil == "brote":
		_corazon_coreano()


func _al_rellenar_region(indice: int, color: Color) -> void:
	_sfx_suave(SFX_RELLENO)
	var region: Dictionary = lienzo.lamina["regiones"][indice]
	var poligono: PackedVector2Array = region["poligono"]
	var caja := Rect2(poligono[0], Vector2.ZERO)
	for p in poligono:
		caja = caja.expand(p)
	_estallido(lienzo.a_pantalla(caja.get_center()), 6, [color, color.lightened(0.4), Color.WHITE], 0.8)
	if bool(_cfg.get("tinte_coco", false)) and str(region.get("id", "")) == "cuerpo":
		_anfitriona.modulate = Color.WHITE.lerp(color, 0.5)
		_reaccion_anfitriona("salta")
	_registrar_evento("pintar_zona", {"zona": str(region.get("id", "")), "color": color})
	_revisar_objetivos()


func _al_completar_lamina() -> void:
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	var espera := 0.6
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.esta_hablando():
		espera = 1.6
	_revisar_objetivos()
	_despues(espera, func() -> void:
		if _mostrando:
			return
		var voz := str(lamina.get("voz", ""))
		if voz != "":
			_lamina_nombrada = true
			_reproducir_voz("lamina", voz)
			var dato := str(lamina.get("voz_dato", ""))
			if dato != "":
				_voz_diferida("dato", dato, _duracion_voz(voz) + 0.3))


# ---------------------------------------------------------------------------
# Lienzo con tema: elegir el tema (Nicole entre 2 tarjetas, Sofia entre 3)
# ---------------------------------------------------------------------------

func _mostrar_selector() -> void:
	eligiendo_tema = true
	_cfg = nivel
	_hubo_toque = false
	_tiempo_hoja = 0.0
	_voz_diferida_id += 1
	lienzo.limpiar()
	lienzo.bloqueado = true
	_vaciar(_dock)
	_dock_botones.clear()
	_vaciar(_objetivos_ui)
	_objetivos.clear()
	_inspiracion.hide()
	_cerrar_popup()
	_ocultar_barra()
	boton_mostrar.visible = false
	_construir_puntos_hojas()
	if _temas_libres.is_empty():
		_temas_libres = nivel.get("temas", []).duplicate()
		_temas_libres.shuffle()
	var opciones := _temas_libres.slice(0, maxi(1, int(nivel.get("opciones_tema", 2))))
	_hojas[_indice_hoja]["opciones"] = opciones
	_vaciar(_selector)
	_selector.show()
	var fondo := Panel.new()
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFE3F1")
	estilo.set_corner_radius_all(14)
	fondo.add_theme_stylebox_override("panel", estilo)
	_selector.add_child(fondo)
	fondo.size = RECT_LIENZO.size
	var n := opciones.size()
	var sep := 26.0
	var ancho := minf(300.0, (RECT_LIENZO.size.x - sep * (n + 1)) / n)
	var alto := minf(430.0, RECT_LIENZO.size.y - 60.0)
	var x0 := (RECT_LIENZO.size.x - (ancho * n + sep * (n - 1))) / 2.0
	for i in n:
		var tarjeta := _tarjeta_tema(opciones[i], Rect2(x0 + i * (ancho + sep), (RECT_LIENZO.size.y - alto) / 2.0, ancho, alto))
		tarjeta.pressed.connect(elegir_tema.bind(i))
		tarjeta.scale = Vector2(0.6, 0.6)
		var tween := tarjeta.create_tween()
		tween.tween_interval(0.08 * i)
		tween.tween_property(tarjeta, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var voz := _linea("elige_tema")
	_reproducir_voz("elige_tema", voz)
	_narrar_opciones(opciones, _duracion_voz(voz) + 0.3)
	_actualizar_depuracion()


## Tarjeta de un tema, sin texto: el fondo en miniatura con tres de sus stickers y, abajo, su
## conector con el viajero (lo que se va a poder hacer).
func _tarjeta_tema(tema: Dictionary, rect: Rect2) -> Button:
	var tarjeta := Button.new()
	tarjeta.focus_mode = Control.FOCUS_NONE
	tarjeta.tooltip_text = str(tema.get("id", "tema"))
	_selector.add_child(tarjeta)
	tarjeta.position = rect.position
	tarjeta.size = rect.size
	tarjeta.pivot_offset = rect.size / 2.0
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color("#FFF8EE").darkened(0.08) if estado == "pressed" else Color("#FFF8EE")
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(6)
		caja.set_corner_radius_all(30)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
		caja.shadow_offset = Vector2(0, 7)
		caja.shadow_size = 3
		tarjeta.add_theme_stylebox_override(estado, caja)
	tarjeta.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tarjeta.button_down.connect(_rebote.bind(tarjeta))
	var ventana := Control.new()
	ventana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ventana.clip_contents = true
	tarjeta.add_child(ventana)
	ventana.position = Vector2(16, 16)
	ventana.size = Vector2(rect.size.x - 32, rect.size.y * 0.66 - 16)
	var fondo := Laminas.preparar(tema.get("fondo", {})) if not (tema.get("fondo", {}) as Dictionary).is_empty() else {}
	var portada: Array = tema.get("portada", (tema.get("stickers", []) as Array).slice(0, 3))
	ventana.draw.connect(func() -> void:
		var escala := maxf(ventana.size.x / RECT_LIENZO.size.x, ventana.size.y / RECT_LIENZO.size.y)
		var desfase := (ventana.size - RECT_LIENZO.size * escala) / 2.0
		if not fondo.is_empty():
			Laminas.dibujar(ventana, fondo, desfase, escala)
		var radio := minf(ventana.size.x * 0.2, ventana.size.y * 0.24)
		for j in portada.size():
			var p := Vector2(ventana.size.x * (0.22 + 0.28 * j), ventana.size.y * (0.66 if j % 2 == 0 else 0.5))
			Stickers.dibujar(ventana, str(portada[j]), Stickers.color_por_defecto(str(portada[j])), p, radio))
	var borde := Panel.new()
	borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.border_color = COLOR_CONTORNO
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)
	borde.add_theme_stylebox_override("panel", estilo)
	tarjeta.add_child(borde)
	borde.position = ventana.position - Vector2(2, 2)
	borde.size = ventana.size + Vector2(4, 4)
	var pie := Control.new()
	pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(pie)
	pie.position = Vector2(16, rect.size.y * 0.66 + 8)
	pie.size = Vector2(rect.size.x - 32, rect.size.y * 0.34 - 24)
	var conector: Dictionary = tema.get("conector", {})
	pie.draw.connect(func() -> void:
		if conector.is_empty():
			return
		var puntos := PackedVector2Array()
		for i in 25:
			var t := i / 24.0
			puntos.append(Vector2(pie.size.x * (0.08 + 0.84 * t), pie.size.y * (0.62 - 0.22 * sin(t * TAU))))
		Lienzo.dibujar_camino(pie, puntos, str(conector.get("tipo", "camino")), 0.7)
		var viajero := str(conector.get("viajero", ""))
		if viajero != "":
			Stickers.dibujar(pie, viajero, Stickers.color_por_defecto(viajero), Vector2(pie.size.x * 0.5, pie.size.y * 0.45), minf(46.0, pie.size.y * 0.42)))
	return tarjeta


## Despues de "¿que dibujamos?", Coco nombra cada tarjeta mientras salta (Nicole aun no lee).
func _narrar_opciones(opciones: Array, espera: float) -> void:
	var id := _voz_diferida_id
	await get_tree().create_timer(espera).timeout
	for i in opciones.size():
		if not eligiendo_tema or id != _voz_diferida_id or not is_inside_tree():
			return
		var tarjeta := _selector.get_child(i + 1) as Control
		if tarjeta != null:
			_rebote(tarjeta, 2)
		var nombre := str((opciones[i].get("lineas_voz", {}) as Dictionary).get("nombre", ""))
		_reproducir_voz("nombre_tema", nombre)
		await get_tree().create_timer(_duracion_voz(nombre) + 0.35).timeout


## Elige la tarjeta `indice` del selector y empieza la hoja con ese tema. Publica para QA.
func elegir_tema(indice: int) -> void:
	if not eligiendo_tema:
		return
	var hoja: Dictionary = _hojas[_indice_hoja]
	var opciones: Array = hoja.get("opciones", [])
	if indice < 0 or indice >= opciones.size():
		return
	eligiendo_tema = false
	_voz_diferida_id += 1
	_sfx_suave(SFX_ELEGIR)
	_asignar_tema(hoja, opciones[indice])
	_selector.hide()
	_vaciar(_selector)
	_empezar_hoja(_indice_hoja)
	lienzo.modulate.a = 0.0
	create_tween().tween_property(lienzo, "modulate:a", 1.0, 0.3)


# ---------------------------------------------------------------------------
# Stickers: tocar, editar, borrar; caminos, llegadas, vueltas y combinaciones
# ---------------------------------------------------------------------------

func _al_tocar_sticker(sticker: StickerVivo) -> void:
	_sfx_suave(SFX_TOQUE)
	if sticker.id in Stickers.ANDAN and not lienzo.esta_viajando(sticker):
		sticker.andar()
	else:
		sticker.saltar()
	_nombrar_sticker(sticker.id, true)
	if _perfil == "semilla" or _mostrando:
		return
	lienzo.seleccionar(sticker)
	_mostrar_barra(sticker)


func _mostrar_barra(sticker: StickerVivo) -> void:
	var acciones := ["achicar", "agrandar", "borrar"] if _perfil == "brote" else ["achicar", "agrandar", "girar", "espejo", "borrar"]
	_vaciar(_barra)
	var lado := 72.0 if _perfil == "brote" else 64.0
	var sep := 8.0
	var sep_borrar := 24.0
	var tam := Vector2(acciones.size() * lado + (acciones.size() - 2) * sep + sep_borrar + 16.0, lado + 16.0)
	var centro := lienzo.a_pantalla(sticker.centro())
	var radio: float = sticker.radio_toque(lienzo.zoom) * lienzo.zoom
	var y := centro.y - radio - tam.y - 4.0
	if y < 8.0:
		y = centro.y + radio + 4.0
	var x := clampf(centro.x - tam.x / 2.0, 120.0, 1100.0 - tam.x)
	_barra.position = Vector2(x, clampf(y, 8.0, 712.0 - tam.y))
	_barra.size = tam
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(COLOR_CONTORNO, 0.82)
	estilo.set_corner_radius_all(int(tam.y / 2.0))
	panel.add_theme_stylebox_override("panel", estilo)
	_barra.add_child(panel)
	panel.size = tam
	for i in acciones.size():
		var boton := Button.new()
		boton.focus_mode = Control.FOCUS_NONE
		boton.tooltip_text = str(acciones[i])
		boton.custom_minimum_size = Vector2(64, 64)
		_barra.add_child(boton)
		boton.position = Vector2(8.0 + i * (lado + sep) + (sep_borrar - sep if acciones[i] == "borrar" else 0.0), 8.0)
		boton.size = Vector2(lado, lado)
		boton.set_meta("accion", acciones[i])
		_estilizar_boton(boton, Color("#FFB3C7") if acciones[i] == "borrar" else Color("#FFF8EE"))
		_icono(boton, _dibujar_accion)
		boton.pressed.connect(_accion_sticker.bind(str(acciones[i])))
	_barra.show()
	_ui.move_child(_barra, -1)
	_ui.move_child(_efectos, -1)


func _ocultar_barra() -> void:
	if _barra == null:
		return
	_barra.hide()
	if lienzo != null:
		lienzo.seleccionar(null)


func _accion_sticker(accion: String) -> void:
	var sticker := lienzo.seleccionado
	if not is_instance_valid(sticker):
		_ocultar_barra()
		return
	_sfx_suave(SFX_ELEGIR)
	# Editar un sticker tambien se puede deshacer (por delegacion, ficha §10.3).
	lienzo.empezar_paso()
	match accion:
		"achicar":
			sticker.escala = maxf(0.5, sticker.escala / 1.25)
		"agrandar":
			sticker.escala = minf(2.4, sticker.escala * 1.25)
		"girar":
			sticker.rotation = wrapf(sticker.rotation + PI / 6.0, -PI, PI)
		"espejo":
			sticker.espejo = not sticker.espejo
		"borrar":
			lienzo.borrar_sticker(sticker)
			lienzo.cerrar_paso()
			_ocultar_barra()
			return
	lienzo.cerrar_paso()
	sticker.saltar()
	_mostrar_barra(sticker)
	_revisar_objetivos()


func _al_borrar_sticker(_id: String, posicion: Vector2) -> void:
	_sfx_suave(SFX_TOQUE)
	_estallido(lienzo.a_pantalla(posicion), 8, [Color.WHITE, Color("#FFE38A"), Color("#FFB3C7")], 0.8)
	_revisar_objetivos()


func _al_crear_camino(desde: StickerVivo, hasta: StickerVivo, camino: Dictionary) -> void:
	_sfx_suave(SFX_RELLENO)
	if desde != null and hasta != null:
		_registrar_evento("conectar", {"a": desde.id, "b": hasta.id, "tipo": str(camino.get("tipo", ""))})
		_conectados += 1
		_estallido(lienzo.a_pantalla((desde.centro() + hasta.centro()) / 2.0), 10, Figura.COLORES_ARCOIRIS, 1.0)
		_reaccion_anfitriona("salta")
		if _conectados <= 2:
			_voz_diferida("conectado", _linea_al_azar("conectado"), 0.5)
	elif bool(camino.get("cerrado", false)):
		_estallido(lienzo.a_pantalla(camino["puntos"][0]), 8, Figura.COLORES_ARCOIRIS, 0.9)
	_revisar_objetivos()


## Un vivo llego a un lugar: cuenta para `llegadas` y `orden`, y el lugar reacciona (el pony toma
## agua en el rio: "¡glu glu!").
func _al_llegar(vivo: StickerVivo, lugar: StickerVivo, desde: StickerVivo) -> void:
	var clave := vivo.get_instance_id()
	var historial: Array = _historial_viajes.get(clave, [])
	if historial.is_empty() and desde != null:
		historial.append(desde.id)
	historial.append(lugar.id)
	_historial_viajes[clave] = historial
	_registrar_evento("llegadas", {"viajero": vivo.id, "instancia": clave, "desde": desde.id if desde != null else "", "hasta": lugar.id})
	_registrar_evento("orden", {"viajero": vivo.id, "instancia": clave})
	var reaccion: Dictionary = (_cfg.get("al_llegar", {}) as Dictionary).get(lugar.id, {})
	var punto := lienzo.a_pantalla(lugar.centro() if lugar.fijo else vivo.centro())
	match str(reaccion.get("efecto", "")):
		"agua":
			_estallido(lienzo.a_pantalla(vivo.centro()), 8, [Color("#6FC3F0"), Color("#BFE8FF"), Color.WHITE], 0.8)
		"corazones":
			_estallido(punto, 8, [Color("#FF7EB6"), Color("#FFB3C7"), Color.WHITE], 0.9)
		"manzanas":
			_estallido(punto, 8, [Color("#EE4035"), Color("#7DD87A"), Color.WHITE], 0.9)
		_:
			_estallido(punto, 6, [DORADO, Color.WHITE], 0.7)
	var ahora := Time.get_ticks_msec()
	if ahora - _ms_ultima_llegada > SEGUNDOS_ENTRE_LLEGADAS * 1000.0:
		_ms_ultima_llegada = ahora
		var voz := str(reaccion.get("voz", ""))
		if voz != "":
			_reproducir_voz("llegada", voz)
		elif bool(_cfg.get("nombrar_estaciones", false)):
			_nombrar_sticker(lugar.id, true, 0.0)
	_revisar_objetivos()


func _al_dar_vuelta(vivo: StickerVivo, vueltas: int) -> void:
	_registrar_evento("circuito", {"viajero": vivo.id, "instancia": vivo.get_instance_id(), "vueltas": vueltas})
	_sfx_suave(SFX_ELEGIR)
	_revisar_objetivos()


func _al_combinar(resultado: String, posicion: Vector2) -> void:
	_registrar_evento("combinacion", {"resultado": resultado})
	_sfx_suave(SFX_MOSTRAR)
	var colores: Array = Figura.COLORES_ARCOIRIS
	if not Stickers.tiene(resultado):
		# Efecto sin sticker (pony_feliz: corazones; humito: nube gris...).
		colores = {"pony_feliz": [Color("#FF7EB6"), Color("#FFB3C7"), Color.WHITE], "humito": [Color("#C9D0E0"), Color.WHITE]}.get(resultado, colores)
	_estallido(lienzo.a_pantalla(posicion), 16, colores, 1.4)
	_reaccion_anfitriona("baila")
	for datos: Dictionary in _cfg.get("combinaciones", []):
		if str(datos.get("resultado", "")) == resultado and str(datos.get("voz", "")) != "":
			_reproducir_voz("combinacion", str(datos["voz"]))
			break
	_revisar_objetivos()


func _nombrar_sticker(id: String, forzar: bool, pausa := SEGUNDOS_ENTRE_NOMBRES) -> void:
	var patron := str(_cfg.get("voces_stickers", ""))
	if patron == "" or (not forzar and _nombrados.has(id)):
		return
	var ahora := Time.get_ticks_msec()
	if ahora - _ms_ultimo_nombre < pausa * 1000.0:
		return
	var ruta := patron % id
	if not _existe_voz(ruta):
		return
	_nombrados[id] = true
	_ms_ultimo_nombre = ahora
	_reproducir_voz("sticker", ruta)


func _existe_voz(ruta: String) -> bool:
	var final := resolver_ruta_audio(ruta)
	return final != "" and ResourceLoader.exists(final)


# ---------------------------------------------------------------------------
# Objetivos obligatorios (ficha §9.4). Vocabulario: llegadas, conectar, circuito, poner,
# combinacion, pintar_zona, colores, orden, encargo. Cada uno lleva `voz` e `icono`.
# ---------------------------------------------------------------------------

func _preparar_objetivos() -> void:
	_objetivos.clear()
	_objetivos_listos = false
	_vaciar(_objetivos_ui)
	var lista: Array = _cfg.get("objetivos", [])
	if lista.is_empty():
		lista = [{"tipo": "encargo", "voz": _linea("intro"), "icono": "encargo"}]
	for datos: Dictionary in lista:
		_objetivos.append({"datos": datos, "actual": 0, "meta": _meta_de(datos), "hecho": false, "chip": null, "registro": {},
			"ya": false, "mostrado": false, "manos": 0})
	_a_la_vez = int(_cfg.get("objetivos_a_la_vez", 1 if _perfil == "semilla" else 3))
	_reiniciar_pistas()
	_llenar_chips()
	_revisar_objetivos()


func _reiniciar_pistas() -> void:
	_sin_avance = 0.0
	_peldano = 0


func _meta_de(datos: Dictionary) -> int:
	match str(datos.get("tipo", "")):
		"llegadas", "poner", "colores", "encerrar", "usar":
			return maxi(1, int(datos.get("n", 1)))
		"circuito":
			return maxi(1, int(datos.get("vueltas", 1)))
		"orden":
			return maxi(1, (datos.get("lugares", []) as Array).size())
		"pintar_zona":
			var zona = datos.get("zona", "")
			return maxi(1, (zona as Array).size()) if zona is Array else 1
		"encargo":
			return _meta_encargo(datos)
	return 1


## Criterio de cada encargo (lienzo-escenas-retos.md §7.1).
func _meta_encargo(datos: Dictionary) -> int:
	if not lienzo.mosaico.is_empty():
		return lienzo.total_celdas()
	if _encargo == "coco_pide" and not _pedidos.is_empty():
		return _pedidos.size()
	if _encargo == "sellos_escena":
		return int(datos.get("n", 3))
	if _encargo == "dedo_magico":
		return 1
	if _encargo in ["espejo", "mandala"]:
		return 100
	if not lienzo.lamina.is_empty() and not _regiones_encargo().is_empty() and not lienzo.stickers_objeto:
		return _regiones_encargo().size()
	return int(datos.get("n", {"semilla": 1500, "brote": 2500, "estrella": 3500}.get(_perfil, 2500)))


## Regiones que cuentan para el encargo. Maxi en el ala: solo las grandes (sin estrellitas).
func _regiones_encargo() -> Array:
	var lista: Array = []
	for i in lienzo.regiones_rellenables():
		var id := str(lienzo.lamina["regiones"][i].get("id", ""))
		if _perfil == "semilla" and _encargo == "decora_ala" and id.begins_with("estrellita"):
			continue
		lista.append(i)
	return lista


## Objetivos visibles: los primeros `_a_la_vez` de la cola que no se han ido (los pendientes y los
## que se cumplieron antes de aparecer, que entran con el check y se van en 1 s).
func _indices_activos() -> Array:
	var activos: Array = []
	for i in _objetivos.size():
		var objetivo: Dictionary = _objetivos[i]
		if not objetivo["hecho"] or (objetivo["ya"] and not objetivo["mostrado"]):
			activos.append(i)
			if activos.size() >= _a_la_vez:
				break
	return activos


func _objetivo_activo() -> Dictionary:
	for i in _indices_activos():
		if not _objetivos[i]["hecho"]:
			return _objetivos[i]
	return {}


func objetivos_pendientes() -> int:
	var n := 0
	for objetivo: Dictionary in _objetivos:
		if not objetivo["hecho"]:
			n += 1
	return n


## Guarda lo que paso en la escena (eventos reales: llegadas, combinaciones, conexiones...) en el
## registro de cada objetivo de ese tipo, este visible o no (§1.3: se evaluan desde el inicio).
func _registrar_evento(tipo: String, datos: Dictionary) -> void:
	for objetivo: Dictionary in _objetivos:
		var o: Dictionary = objetivo["datos"]
		var registro: Dictionary = objetivo["registro"]
		if str(o.get("tipo", "")) != tipo:
			continue
		match tipo:
			"llegadas":
				if _coincide(str(datos["viajero"]), str(o.get("viajero", ""))) and str(datos["hasta"]) == str(o.get("hasta", "")) \
						and (str(o.get("desde", "")) == "" or str(datos["desde"]) == str(o.get("desde", ""))):
					registro[datos["instancia"]] = true
			"conectar":
				var a := str(o.get("a", ""))
				var b := str(o.get("b", ""))
				var camino_ok := str(o.get("camino", "")) == "" or str(o.get("camino", "")) == str(datos["tipo"])
				if camino_ok and ((datos["a"] == a and datos["b"] == b) or (datos["a"] == b and datos["b"] == a)):
					registro["ok"] = true
			"circuito":
				if _coincide(str(datos["viajero"]), str(o.get("viajero", ""))):
					registro["max"] = maxi(int(registro.get("max", 0)), int(datos["vueltas"]))
			"combinacion":
				if str(datos["resultado"]) == str(o.get("resultado", "")):
					registro["ok"] = true
			"montar":
				# Objetivo OPCIONAL (§11.9): "sube a alguien a un pony" ({jinete?, montura?}).
				if (str(o.get("jinete", "")) == "" or str(datos["jinete"]) == str(o.get("jinete", ""))) \
						and _coincide(str(datos["montura"]), str(o.get("montura", ""))):
					registro["ok"] = true
			"orden":
				if _coincide(str(datos["viajero"]), str(o.get("viajero", ""))):
					var historial: Array = _historial_viajes.get(datos["instancia"], [])
					registro["max"] = maxi(int(registro.get("max", 0)), _prefijo_en_orden(historial, o.get("lugares", [])))


func _coincide(id: String, patron: String) -> bool:
	return patron == "" or id == patron or (patron == "dino" and Stickers.es_dino(id))


## Cuantos lugares de `orden` aparecen en ese orden en el historial de un viaje (puede haber paradas
## extra entre ellos).
func _prefijo_en_orden(historial: Array, orden: Array) -> int:
	var k := 0
	for lugar in historial:
		if k < orden.size() and str(lugar) == str(orden[k]):
			k += 1
	return k


func _medir(objetivo: Dictionary) -> int:
	var o: Dictionary = objetivo["datos"]
	var registro: Dictionary = objetivo["registro"]
	match str(o.get("tipo", "")):
		"llegadas":
			return registro.size()
		"conectar":
			if bool(registro.get("ok", false)):
				return 1
			for camino: Dictionary in lienzo.caminos:
				var d = camino["desde"]
				var h = camino["hasta"]
				if d == null or h == null or not is_instance_valid(d) or not is_instance_valid(h):
					continue
				var camino_ok := str(o.get("camino", "")) == "" or str(o.get("camino", "")) == str(camino["tipo"])
				var a := str(o.get("a", ""))
				var b := str(o.get("b", ""))
				if camino_ok and ((d.id == a and h.id == b) or (d.id == b and h.id == a)):
					return 1
			return 0
		"circuito", "orden":
			return int(registro.get("max", 0))
		"poner":
			var cuenta := 0
			for sticker: StickerVivo in lienzo.stickers():
				if _coincide(sticker.id, str(o.get("sticker", ""))) and lienzo.en_zona(sticker.centro(), str(o.get("en_zona", ""))) \
						and not sticker.has_meta("magico") and not sticker.has_meta("puesto"):
					cuenta += 1
			return cuenta
		"encerrar":
			var patron := str(o.get("sticker", ""))
			return lienzo.encerrados(func(st) -> bool: return _coincide(st.id, patron), str(o.get("con", "")))
		"usar":
			var herramienta := str(o.get("herramienta", ""))
			if herramienta == "purpurina":
				return int(registro.get("lluvias", 0))
			return int(lienzo.usos.get(herramienta, 0))
		"combinacion", "montar":
			return 1 if bool(registro.get("ok", false)) else 0
		"pintar_zona":
			return _medir_pintar_zona(o)
		"colores":
			return _colores_hoja.size()
		"encargo":
			return _medir_encargo()
	return 0


## `pintar_zona {zona, color?, distintos?}`: la region (o la lista de regiones) tocada con el balde,
## del color con nombre mas cercano si se pide, y con colores distintos si `distintos`.
func _medir_pintar_zona(o: Dictionary) -> int:
	var zonas = o.get("zona", "")
	var lista: Array = zonas if zonas is Array else [zonas]
	var pedido := str(o.get("color", ""))
	var cuenta := 0
	var vistos := {}
	for zona in lista:
		var i := lienzo.region_por_id(str(zona))
		if i < 0 or not lienzo.region_tocada(i):
			continue
		var nombre := Colores.mas_cercano(lienzo.region_color(i), PALETA_COMPLETA)
		if pedido != "" and nombre != pedido:
			continue
		if bool(o.get("distintos", false)) and vistos.has(nombre):
			continue
		vistos[nombre] = true
		cuenta += 1
	return cuenta


func _medir_encargo() -> int:
	if not lienzo.mosaico.is_empty():
		return lienzo.celdas_correctas()
	if _encargo == "coco_pide" and not _pedidos.is_empty():
		return _pedidos.size() if _pedido_actual < 0 else _pedido_actual
	if _encargo == "sellos_escena":
		return _dinos_estampados()
	if _encargo == "dedo_magico":
		return 1 if lienzo.trazo_cruzo_franjas else 0
	if _encargo in ["espejo", "mandala"]:
		var meta := 0.6 if _encargo == "espejo" else 0.75
		return mini(100, int(lienzo.cobertura_guia() / meta * 100.0))
	if not lienzo.lamina.is_empty() and not _regiones_encargo().is_empty() and not lienzo.stickers_objeto:
		var cuenta := 0
		for i in _regiones_encargo():
			if lienzo.region_tocada(i):
				cuenta += 1
		return cuenta
	return int(lienzo.recorrido_pintado * lienzo.zoom)


func _dinos_estampados() -> int:
	return int(_usados_especiales.get("dinos_estampados", 0))


## Mide TODOS los objetivos pendientes (§1.3) y cumple los que llegaron a su meta. Los que no estan a
## la vista quedan cumplidos "de antes" y entran despues con el check. Por eventos y cada 0,25 s.
func _revisar_objetivos() -> void:
	if _objetivos.is_empty() or _mostrando or _terminado or _objetivos_listos:
		return
	var visibles := _indices_activos()
	var cumplir: Array = []
	for i in _objetivos.size():
		var objetivo: Dictionary = _objetivos[i]
		if objetivo["hecho"]:
			continue
		if str(objetivo["datos"].get("tipo", "")) == "encargo":
			# La meta del encargo puede cambiar (otro traje de Coco tiene otras partes).
			objetivo["meta"] = _meta_encargo(objetivo["datos"])
		var valor := mini(_medir(objetivo), int(objetivo["meta"]))
		if valor > int(objetivo["actual"]):
			objetivo["actual"] = valor
			if visibles.has(i):
				# §6.1: Maxi solo reinicia con el objetivo activo; Nicole y Sofia, con cualquiera visible.
				if _perfil != "semilla" or _objetivo_activo() == objetivo:
					_reiniciar_pistas()
				var chip = objetivo["chip"]
				if chip != null and is_instance_valid(chip):
					_rebote(chip)
					(chip.get_meta("dibujo") as Control).queue_redraw()
		if valor >= int(objetivo["meta"]):
			cumplir.append(i)
	for i in cumplir:
		_cumplir_objetivo(i, not visibles.has(i))
	_actualizar_depuracion()


func _cumplir_objetivo(indice: int, de_antes := false) -> void:
	var objetivo: Dictionary = _objetivos[indice]
	if objetivo["hecho"]:
		return
	objetivo["hecho"] = true
	objetivo["ya"] = de_antes
	objetivo["actual"] = objetivo["meta"]
	_valvula_lista = false
	var premio := ceili(float(DESTELLOS_OBJETIVOS_POR_HOJA) / _objetivos.size())
	_destellos_objetivos += premio
	objetivo_cumplido.emit(indice, str(objetivo["datos"].get("tipo", "")))
	_reiniciar_pistas()
	if de_antes:
		# Entrara a la cola con el check puesto (en `_llenar_chips`).
		if objetivos_pendientes() == 0 and _indices_activos().is_empty():
			_objetivos_listos = true
			_todos_cumplidos()
		return
	objetivo["mostrado"] = true
	var chip = objetivo["chip"]
	if chip != null and is_instance_valid(chip):
		_estilizar_boton(chip, Color("#FFE38A"), false)
		(chip.get_meta("dibujo") as Control).queue_redraw()
		_rebote(chip, 2)
		_estallido(chip.global_position + chip.size / 2.0, 12, [DORADO, Color.WHITE, TURQUESA], 1.1)
	if objetivos_pendientes() == 0:
		_objetivos_listos = true
		_todos_cumplidos()
		return
	_reaccion_anfitriona("salta")
	# Celebracion corta (GDD §5, ritmo rapido): Maxi grita "¡siii!"; Nicole y Sofia, una linea breve.
	var voz := _linea_al_azar("objetivo_cumplido")
	_reproducir_voz("objetivo_cumplido", voz)
	_despues_en_hoja(0.9, _llenar_chips)
	var siguiente := _objetivo_activo()
	if not siguiente.is_empty() and _perfil == "semilla":
		_voz_diferida("objetivo", str(siguiente["datos"].get("voz", "")), _duracion_voz(voz) + 0.4)


## Todos los objetivos cumplidos: gran celebracion y aparece "mostrar a Coco" (antes no existe).
func _todos_cumplidos() -> void:
	objetivos_completos.emit()
	_confeti_en(Vector2(640, 360))
	_reaccion_anfitriona("baila")
	_estallido(Vector2(640, 300), 20, Figura.COLORES_ARCOIRIS, 1.6)
	var voz := _linea_al_azar("hoja_lista")
	_reproducir_voz("hoja_lista", voz)
	_despues_en_hoja(1.0, _llenar_chips)
	_despues(0.4, func() -> void: _revelar_boton_mostrar(false))


## Arma las tarjetas de los objetivos visibles (arriba a la derecha) y la fila de estrellitas.
## Tarjetas de 180x150 en Maxi y de 130x110 en Nicole y Sofia (§1.5), sin numeros.
func _llenar_chips() -> void:
	if _objetivos_ui == null:
		return
	_vaciar(_objetivos_ui)
	for objetivo: Dictionary in _objetivos:
		objetivo["chip"] = null
	var tam := Vector2(180, 150) if _perfil == "semilla" else Vector2(130, 110)
	var sep := 10.0
	var activos := _indices_activos()
	var ancho := activos.size() * tam.x + maxi(0, activos.size() - 1) * sep
	var ancho_ui := maxf(ancho, minf(12.0, _objetivos.size()) * 18.0)
	_objetivos_ui.position = Vector2(BORDE_OBJETIVOS - ancho_ui, 8)
	_objetivos_ui.size = Vector2(ancho_ui, tam.y + 26.0)
	var x := ancho_ui - ancho
	var ya_hechos: Array = []
	for i in activos:
		var objetivo: Dictionary = _objetivos[i]
		var chip := Button.new()
		chip.focus_mode = Control.FOCUS_NONE
		chip.tooltip_text = "Objetivo: %s" % objetivo["datos"].get("tipo", "")
		chip.custom_minimum_size = Vector2(64, 64)
		_objetivos_ui.add_child(chip)
		chip.position = Vector2(x, 0)
		chip.size = tam
		chip.pivot_offset = chip.size / 2.0
		chip.set_meta("indice", i)
		for estado in ["normal", "hover", "pressed", "disabled"]:
			var caja := StyleBoxFlat.new()
			caja.bg_color = Color("#FFE38A") if objetivo["hecho"] else Color("#FFF8EE")
			caja.border_color = COLOR_CONTORNO
			caja.set_border_width_all(5)
			caja.set_corner_radius_all(26)
			caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
			caja.shadow_offset = Vector2(0, 5)
			chip.add_theme_stylebox_override(estado, caja)
		chip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		chip.button_down.connect(_rebote.bind(chip))
		chip.set_meta("dibujo", _icono(chip, _dibujar_chip))
		chip.pressed.connect(tocar_objetivo.bind(i))
		objetivo["chip"] = chip
		chip.scale = Vector2(0.5, 0.5)
		create_tween().tween_property(chip, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if objetivo["ya"] and not objetivo["mostrado"]:
			ya_hechos.append(i)
		x += tam.x + sep
	# Estrellitas: cuantos objetivos tiene la hoja y cuantos van (sin numeros).
	var puntos := Control.new()
	puntos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objetivos_ui.add_child(puntos)
	puntos.position = Vector2(0, tam.y + 6.0)
	puntos.size = Vector2(_objetivos_ui.size.x, 18)
	puntos.draw.connect(func() -> void:
		var n := _objetivos.size()
		if n <= 1:
			return
		var paso := minf(18.0, puntos.size.x / n)
		for k in n:
			var c := Vector2(puntos.size.x - (n - k - 0.5) * paso, 9)
			var estrella := Figura.poligono("estrella", c, 8.0)
			puntos.draw_colored_polygon(estrella, DORADO if _objetivos[k]["hecho"] else Color(1, 1, 1, 0.85))
			Figura.contornear(puntos, estrella, 2.0))
	puntos.queue_redraw()
	if not ya_hechos.is_empty():
		# §1.6: "¡eso ya lo habias hecho!" y se va en 1 s.
		_reproducir_voz("ya_hecho", _linea_al_azar("ya_hecho"))
		for i in ya_hechos:
			var chip = _objetivos[i]["chip"]
			if chip != null:
				_estallido(chip.global_position + chip.size / 2.0, 8, [DORADO, Color.WHITE], 0.9)
		_despues_en_hoja(1.0, func() -> void:
			for i in ya_hechos:
				_objetivos[i]["mostrado"] = true
			if objetivos_pendientes() == 0:
				if not _objetivos_listos:
					_objetivos_listos = true
					_todos_cumplidos()
				else:
					_llenar_chips()
			else:
				_llenar_chips())


## Tocar un chip: Coco repite la consigna y muestra la pista fantasma de ese objetivo.
func tocar_objetivo(indice: int) -> void:
	if indice < 0 or indice >= _objetivos.size():
		return
	_sfx_suave(SFX_TOQUE)
	var objetivo: Dictionary = _objetivos[indice]
	_reproducir_voz("objetivo", str(objetivo["datos"].get("voz", "")))
	if not objetivo["hecho"]:
		_mostrar_pista_de(objetivo)


## Escalera de pistas (§6.2) segun los segundos sin avance.
func _subir_escalera() -> void:
	var escalera: Dictionary = ESCALERA_PISTAS.get(_perfil, ESCALERA_PISTAS["brote"])
	var objetivo := _objetivo_activo()
	if objetivo.is_empty():
		return
	if _peldano == 0 and _sin_avance >= float(escalera["voz"]):
		_peldano = 1
		_reproducir_voz("pista_objetivo", str(objetivo["datos"].get("voz", "")))
		var chip = objetivo["chip"]
		if chip != null and is_instance_valid(chip):
			_rebote(chip, 3)
	if _peldano == 1 and _sin_avance >= float(escalera["brilla"]):
		_peldano = 2
		_brillar_necesario(objetivo)
	if _peldano == 2 and _sin_avance >= float(escalera["mano"]):
		_peldano = 3
		_reaccion_anfitriona("salta")
		_mostrar_pista_de(objetivo)
	if _peldano == 3 and float(escalera["repetir"]) > 0.0 and _sin_avance >= float(escalera["mano"]) + float(escalera["repetir"]):
		_sin_avance = float(escalera["mano"])
		_reproducir_voz("pista_objetivo", str(objetivo["datos"].get("voz", "")))
		_mostrar_pista_de(objetivo)


## Nivel 2: lo que hace falta brilla (el grupo del dock que lo tiene).
func _brillar_necesario(objetivo: Dictionary) -> void:
	var o: Dictionary = objetivo["datos"]
	match str(o.get("tipo", "")):
		"pintar_zona", "colores", "encargo":
			_pulsar_grupo("colores")
		"usar":
			_pulsar_grupo("pinceles")
		_:
			_pulsar_grupo("cosas")
			_pulsar_grupo("decorados")


## Valvula de Semilla: completa el paso como lo haria la mano (pone, conecta) y lo celebra.
func _usar_valvula() -> void:
	_valvula_lista = false
	var objetivo := _objetivo_activo()
	if objetivo.is_empty():
		return
	var o: Dictionary = objetivo["datos"]
	match str(o.get("tipo", "")):
		"poner":
			var id := str(o.get("sticker", ""))
			for k in maxi(0, int(objetivo["meta"]) - _medir(objetivo)):
				lienzo.poner_sticker("trex" if id == "dino" else id, _pos_sugerida(id) + Vector2(70 * k, 10 * k))
		"conectar":
			var a := lienzo.lugar_por_id(str(o.get("a", "")))
			var b := lienzo.lugar_por_id(str(o.get("b", "")))
			if a != null and b != null:
				lienzo.agregar_camino(_curva(a.centro(), b.centro()), str(o.get("camino", lienzo.tipo_camino)))
	_revisar_objetivos()
	if not objetivo["hecho"]:
		_cumplir_objetivo(_objetivos.find(objetivo))


## Pista fantasma (sin avance un rato, o al tocar a Coco): Coco repite la consigna del primer
## objetivo pendiente y deja ver, translucido, que hacer (camino punteado, sticker que falta, zona).
func pista_fantasma() -> void:
	var objetivo := _objetivo_activo()
	if objetivo.is_empty():
		return
	_peldano = 3
	_reaccion_anfitriona("salta")
	_reproducir_voz("pista_objetivo", str(objetivo["datos"].get("voz", "")))
	_mostrar_pista_de(objetivo)


func _mostrar_pista_de(objetivo: Dictionary) -> void:
	var o: Dictionary = objetivo["datos"]
	objetivo["manos"] = int(objetivo["manos"]) + 1
	if _perfil == "semilla" and int(objetivo["manos"]) >= MANOS_VALVULA:
		_valvula_lista = true
	match str(o.get("tipo", "")):
		"conectar", "llegadas", "orden":
			var a := str(o.get("a", o.get("desde", "")))
			var b := str(o.get("b", o.get("hasta", "")))
			if str(o.get("tipo", "")) == "orden":
				var lugares: Array = o.get("lugares", [])
				a = str(lugares[0]) if lugares.size() > 0 else ""
				b = str(lugares[1]) if lugares.size() > 1 else ""
			var lugar_b := lienzo.lugar_por_id(b)
			var lugar_a := lienzo.lugar_por_id(a) if a != "" else null
			if str(o.get("tipo", "")) == "llegadas" and lugar_a != null and lugar_b != null and not _hay_camino(lugar_a, lugar_b):
				# §6.3: sin camino, primero la pista de conectar.
				lienzo.mostrar_fantasma({"tipo": "camino", "puntos": _curva(lugar_a.centro(), lugar_b.centro())}, 4.5)
				_pulsar_grupo("cosas")
				return
			if lugar_b == null:
				_pista_sticker(b)
				return
			if lugar_a == null and a != "":
				_pista_sticker(a)
				return
			var viajero := str(o.get("viajero", "")) if str(o.get("tipo", "")) != "conectar" else ""
			if viajero == "dino":
				viajero = "trex"
			var desde: Vector2 = lugar_a.centro() if lugar_a != null else _pos_sugerida(viajero)
			var puntos := _curva(desde, lugar_b.centro())
			var existente := _camino_entre(lugar_a, lugar_b)
			if not existente.is_empty():
				puntos = existente["puntos"]
				if existente["desde"] != lugar_a:
					puntos = puntos.duplicate()
					puntos.reverse()
			if viajero != "" and lienzo.stickers().filter(func(s) -> bool: return _coincide(s.id, str(o.get("viajero", "")))).is_empty():
				_pista_sticker(viajero)
				return
			lienzo.mostrar_fantasma({"tipo": "camino", "puntos": puntos, "viajero": viajero}, 4.5)
			_pulsar_grupo("cosas")
		"poner":
			_pista_sticker(str(o.get("sticker", "")))
		"combinacion":
			for datos: Dictionary in _cfg.get("combinaciones", []):
				if str(datos.get("resultado", "")) == str(o.get("resultado", "")):
					var nodos: Array = []
					for ingrediente in datos.get("ingredientes", []):
						var nodo = _primer_sticker(str(ingrediente))
						if nodo == null:
							_pista_sticker(str(ingrediente))
							return
						nodos.append(nodo)
					# Estan todos: la mano lleva el primero hasta el segundo (§6.3).
					if nodos.size() >= 2:
						lienzo.mostrar_fantasma({"tipo": "camino", "puntos": _curva(nodos[0].centro(), nodos[1].centro()),
							"viajero": str(nodos[0].id)}, 4.5)
					return
		"encerrar":
			var centro := Vector2(640, 520) * lienzo.escala_mundo
			for sticker: StickerVivo in lienzo.stickers():
				if _coincide(sticker.id, str(o.get("sticker", ""))):
					centro = sticker.centro()
					break
			var ovalo := PackedVector2Array()
			for k in 33:
				ovalo.append(centro + Vector2.from_angle(TAU * k / 32.0) * Vector2(170, 90))
			lienzo.mostrar_fantasma({"tipo": "circuito", "puntos": ovalo}, 4.5)
			_pulsar_grupo("cosas")
		"usar":
			_pulsar_grupo("pinceles")
		"circuito":
			var puntos := PackedVector2Array()
			for k in 33:
				puntos.append(Vector2(640, 520) * lienzo.escala_mundo + Vector2.from_angle(TAU * k / 32.0) * Vector2(260, 90))
			lienzo.mostrar_fantasma({"tipo": "circuito", "puntos": puntos, "viajero": str(o.get("viajero", ""))}, 4.5)
			_pulsar_grupo("cosas")
		"pintar_zona":
			lienzo.mostrar_fantasma({"tipo": "zona", "indice": lienzo.region_por_id(str(o.get("zona", "")))}, 4.5)
			_pulsar_grupo("colores")
		"colores":
			_pulsar_grupo("colores")
		"encargo":
			if not lienzo.mosaico.is_empty():
				# §6.3: la primera celda sin terminar parpadea.
				var filas: Array = lienzo.mosaico.get("celdas", [])
				for y in filas.size():
					for x in str(filas[y]).length():
						var celda := Vector2i(x, y)
						if not lienzo._celdas.has(celda) or not (lienzo._celdas[celda] as Color).is_equal_approx(lienzo.color_esperado(celda)):
							lienzo.mostrar_fantasma({"tipo": "celda", "celda": celda}, 4.5)
							_pulsar_grupo("colores")
							return
			elif _encargo == "dedo_magico":
				lienzo.mostrar_fantasma({"tipo": "camino", "puntos": PackedVector2Array([Vector2(640, 60) * lienzo.escala_mundo, Vector2(560, 360) * lienzo.escala_mundo, Vector2(660, 660) * lienzo.escala_mundo])}, 4.5)
			elif _encargo in ["espejo", "mandala"]:
				lienzo.mostrar_fantasma({"tipo": "guia"}, 4.5)
			elif not lienzo.lamina.is_empty() and not lienzo.stickers_objeto:
				for i in lienzo.regiones_rellenables():
					if not lienzo.region_tocada(i):
						lienzo.mostrar_fantasma({"tipo": "zona", "indice": i}, 4.5)
						break
			if _pedido_actual >= 0:
				_voz_diferida("pedido", _ruta_pedido(), 1.6)
			_pulsar_grupo("colores" if _encargo in ["colorear_zonas", "colorear_codigo", "coco_pide", "mezcla_paleta", "pinta_coco", "decora_ala", "viste_coco"] else "pinceles")


func _hay_camino(a: StickerVivo, b: StickerVivo) -> bool:
	return not _camino_entre(a, b).is_empty()


func _camino_entre(a, b) -> Dictionary:
	if a == null or b == null:
		return {}
	for camino: Dictionary in lienzo.caminos:
		if (camino["desde"] == a and camino["hasta"] == b) or (camino["desde"] == b and camino["hasta"] == a):
			return camino
	return {}


## El primer sticker (o lugar de fondo) con ese id, o null.
func _primer_sticker(id: String):
	for sticker: StickerVivo in lienzo.stickers():
		if sticker.id == id:
			return sticker
	return lienzo.lugar_por_id(id)


func _pista_sticker(id: String) -> void:
	if id == "":
		return
	if id == "dino":
		id = "trex"
	if lienzo.lugar_por_id(id) != null and lienzo.lugar_por_id(id).fijo:
		return
	lienzo.mostrar_fantasma({"tipo": "sticker", "id": id, "pos": _pos_sugerida(id)}, 4.5)
	for grupo in ["cosas", "decorados"]:
		if (_grupos.get(grupo, []) as Array).has("sello_" + id):
			_pulsar_grupo(grupo)


## Donde poner un sticker de pista: el de la inspiracion si esta; si no, cerca del centro.
func _pos_sugerida(id: String) -> Vector2:
	var tema: Dictionary = _hojas[_indice_hoja].get("tema", {})
	for elemento: Dictionary in (tema.get("inspiracion", {}) as Dictionary).get("elementos", []):
		if str(elemento.get("sticker", "")) == id or (id == "trex" and Stickers.es_dino(str(elemento.get("sticker", "")))):
			return Laminas.vec(elemento.get("pos", null)) * lienzo.escala_mundo
	return Vector2(620, 420) * lienzo.escala_mundo


func _curva(a: Vector2, b: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var normal := (b - a).orthogonal().normalized() * minf(80.0, a.distance_to(b) * 0.15)
	for k in 21:
		var t := k / 20.0
		puntos.append(a.lerp(b, t) + normal * sin(t * PI))
	return puntos


func _pulsar_grupo(grupo: String) -> void:
	for entrada: Dictionary in _dock_botones:
		if entrada["grupo"] == grupo:
			_rebote(entrada["boton"], 3)


# ---------------------------------------------------------------------------
# Coco pide colores (Nicole, zona 3)
# ---------------------------------------------------------------------------

func _preparar_pedidos() -> void:
	_pedidos.clear()
	_pedido_actual = -1
	_fallos_pedido = 0
	_burbuja.hide()
	var lista: Array = _cfg.get("pedidos", []).duplicate()
	if lista.is_empty() or _encargo not in ["coco_pide", "mezcla_paleta"]:
		return
	lista.shuffle()
	var cuantos := int(_cfg.get("pedidos_por_partida", lista.size()))
	_pedidos = lista.slice(0, cuantos)
	_pedido_actual = 0


func _ruta_pedido() -> String:
	if _pedido_actual < 0 or _pedido_actual >= _pedidos.size():
		return ""
	var patron := str(_cfg.get("voces_pedidos", ""))
	return patron % str(_pedidos[_pedido_actual]) if patron != "" else ""


func _revisar_pedido_color(color: Color) -> bool:
	if _pedido_actual < 0 or _pedido_actual >= _pedidos.size():
		return false
	var pedido := str(_pedidos[_pedido_actual])
	if _id_de_color(color) == pedido:
		_cumplir_pedido(pedido)
		return true
	_fallos_pedido += 1
	if _fallos_pedido >= 2:
		# Pista suave (Brote: los errores dan pistas por voz): la burbuja muestra el color y su
		# mancha en la paleta salta. Nunca un "no".
		_fallos_pedido = 0
		_mostrar_burbuja(Colores.color(pedido))
		for entrada: Dictionary in _botones_color:
			if entrada["id"] == pedido:
				_rebote(entrada["boton"], 3)
		_reproducir_voz("pedido", _ruta_pedido())
		return true
	return false


func _cumplir_pedido(pedido: String) -> void:
	pedido_cumplido.emit(pedido)
	_burbuja.hide()
	_fallos_pedido = 0
	var patron := str(_cfg.get("voces_logrado", _cfg.get("voces_colores", "")))
	var voz := patron % pedido if patron != "" else ""
	_reproducir_voz("pedido_logrado", voz)
	_reaccion_anfitriona("baila")
	_estallido(_anfitriona.global_position + Vector2(_anfitriona.size.x / 2.0, 40), 10, [Colores.color(pedido), DORADO, Color.WHITE], 1.2)
	_pedido_actual += 1
	_actualizar_depuracion()
	if _pedido_actual >= _pedidos.size():
		_pedido_actual = -1
		_voz_diferida("pedidos_listos", _linea_al_azar("pedidos_listos"), _duracion_voz(voz) + 0.4)
		_despues(_duracion_voz(voz) + 0.4, func() -> void: _revelar_boton_mostrar(false))
	else:
		_voz_diferida("pedido", _ruta_pedido(), _duracion_voz(voz) + 0.5)
	_revisar_objetivos()


func _mostrar_burbuja(color: Color) -> void:
	_burbuja.set_meta("color", color)
	_burbuja.show()
	_burbuja.queue_redraw()
	_rebote(_burbuja)


func _dibujar_burbuja() -> void:
	var color: Color = _burbuja.get_meta("color", Color.WHITE)
	var rect := Rect2(Vector2(4, 4), _burbuja.size - Vector2(8, 8))
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#FFF8EE")
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(28)
	_burbuja.draw_style_box(caja, rect)
	Figura.dibujar(_burbuja, "gota", color, rect.get_center(), 24.0, false)


# ---------------------------------------------------------------------------
# Mezcla en la paleta (Sofia, zona 3): el platito vive dentro del popup de colores
# ---------------------------------------------------------------------------

func _preparar_mezcla() -> void:
	_gotas = {}
	_mezclas_dichas.clear()
	_mis_colores.clear()
	if _encargo == "mezcla_paleta":
		lienzo.color_actual = Color.WHITE


func _armar_platito(pos: Vector2, lado: float, pos_mis: Vector2) -> void:
	var platito := Button.new()
	platito.focus_mode = Control.FOCUS_NONE
	platito.flat = true
	platito.tooltip_text = "Platito de mezcla"
	platito.custom_minimum_size = Vector2(64, 64)
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		platito.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	_popup.add_child(platito)
	platito.position = pos
	platito.size = Vector2(150, 110)
	platito.set_meta("platito", true)
	var dibujo := _icono(platito, _dibujar_platito)
	platito.set_meta("dibujo", dibujo)
	platito.pressed.connect(func() -> void:
		_sfx_suave(SFX_ELEGIR)
		lienzo.color_actual = Colores.mezclar(_gotas) if not _gotas.is_empty() else Color.WHITE
		_refrescar_iconos()
		_cerrar_popup())
	var vaciar := Button.new()
	vaciar.focus_mode = Control.FOCUS_NONE
	vaciar.tooltip_text = "Vaciar el platito"
	_popup.add_child(vaciar)
	vaciar.position = pos + Vector2(40, 116)
	vaciar.size = Vector2(66, 66)
	vaciar.custom_minimum_size = Vector2(64, 64)
	_estilizar_boton(vaciar, Color("#CFF5F1"))
	_icono(vaciar, _dibujar_icono_vaciar)
	vaciar.pressed.connect(func() -> void:
		_sfx_suave(SFX_TOQUE)
		_gotas = {}
		lienzo.color_actual = Color.WHITE
		dibujo.queue_redraw()
		_refrescar_iconos())
	for i in _mis_colores.size():
		var boton := _boton_color(_mis_colores[i], "", Rect2(pos_mis + Vector2(i * (lado + 10.0), 0), Vector2(lado, lado)))
		var guardado: Color = _mis_colores[i]
		boton.pressed.connect(func() -> void:
			_sfx_suave(SFX_ELEGIR)
			lienzo.color_actual = guardado
			_refrescar_iconos()
			_cerrar_popup())


func _agregar_gota(id: String) -> void:
	if int(_gotas.get(id, 0)) >= 9:
		return
	_gotas[id] = int(_gotas.get(id, 0)) + 1
	var mezcla := Colores.mezclar(_gotas)
	lienzo.color_actual = mezcla
	for hijo in _popup.get_children():
		if hijo.has_meta("platito"):
			(hijo.get_meta("dibujo") as Control).queue_redraw()
			_rebote(hijo)
	_refrescar_iconos()
	var nombre := Colores.nombre_mezcla(_gotas)
	_guardar_mi_color(mezcla)
	if _pedido_actual >= 0 and _pedido_actual < _pedidos.size() and nombre == str(_pedidos[_pedido_actual]):
		_mezclas_dichas[nombre] = true
		_cumplir_pedido(nombre)
		return
	var total := 0
	for v in _gotas.values():
		total += int(v)
	if total >= 2 and not _mezclas_dichas.has(nombre) and nombre not in PRIMARIOS:
		_mezclas_dichas[nombre] = true
		var patron := str(_cfg.get("voces_mezclas", ""))
		if patron != "":
			_reproducir_voz("mezcla", patron % nombre)
			_reaccion_anfitriona("salta")


func _guardar_mi_color(color: Color) -> void:
	for c: Color in _mis_colores:
		if c.is_equal_approx(color):
			return
	_mis_colores.append(color)
	if _mis_colores.size() > 6:
		_mis_colores.pop_front()


func _dibujar_platito(icono: Control) -> void:
	var c := Vector2(icono.size.x / 2.0 - 30, icono.size.y / 2.0 + 6)
	var plato := Laminas.elipse(c, 66, 50, 40)
	icono.draw_colored_polygon(plato, Color.WHITE)
	var cerrado := plato.duplicate()
	cerrado.append(plato[0])
	icono.draw_polyline(cerrado, COLOR_CONTORNO, 4.0, true)
	icono.draw_colored_polygon(Laminas.elipse(c, 50, 36, 40), Color("#EEF2F8"))
	if not _gotas.is_empty():
		var mancha := Laminas.elipse(c + Vector2(0, 2), 40, 28, 40)
		icono.draw_colored_polygon(mancha, Colores.mezclar(_gotas))
		var borde := mancha.duplicate()
		borde.append(mancha[0])
		icono.draw_polyline(borde, Color(COLOR_CONTORNO, 0.5), 2.5, true)
	# Gotitas de la receta (cuantas de cada color) al lado del plato.
	var y := 16.0
	for id in PRIMARIOS:
		var n := int(_gotas.get(id, 0))
		for k in mini(n, 5):
			icono.draw_circle(Vector2(icono.size.x - 76 + k * 13, y + 80), 6.0, Colores.color(id))
			icono.draw_arc(Vector2(icono.size.x - 76 + k * 13, y + 80), 6.0, 0, TAU, 12, COLOR_CONTORNO, 1.5, true)
		y += 16.0


# ---------------------------------------------------------------------------
# Mostrar a Coco (solo con todos los objetivos cumplidos)
# ---------------------------------------------------------------------------

func _revelar_boton_mostrar(con_voz: bool) -> void:
	if _terminado or _mostrando or not _objetivos_listos:
		return
	var ya_visible := boton_mostrar.visible
	if not ya_visible:
		_boton_visible_desde = _tiempo_hoja
		boton_mostrar.scale = Vector2(0.2, 0.2)
	boton_mostrar.visible = true
	_ui.move_child(boton_mostrar, -1)
	_ui.move_child(_efectos, -1)
	if _tween_mostrar != null and _tween_mostrar.is_valid():
		_tween_mostrar.kill()
	_tween_mostrar = create_tween()
	if not ya_visible:
		_tween_mostrar.tween_property(boton_mostrar, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 4:
		_tween_mostrar.tween_property(boton_mostrar, "scale", Vector2(1.14, 1.14), 0.3).set_trans(Tween.TRANS_SINE)
		_tween_mostrar.tween_property(boton_mostrar, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	if con_voz and not ya_visible:
		_reproducir_voz("muestramelo", _linea_al_azar("muestramelo"))


## El nino le muestra su dibujo a Coco: se guarda el PNG, Coco celebra y se pasa a la hoja siguiente
## o a la celebracion final. Con objetivos pendientes no pasa nada (Coco repite el que falta): todos
## son necesarios. Publica para los arneses QA.
func mostrar_a_coco() -> String:
	if _mostrando or _terminado or _indice_hoja < 0:
		return ""
	if not _objetivos_listos:
		var activo := _objetivo_activo()
		if not activo.is_empty():
			_reproducir_voz("objetivo", str(activo["datos"].get("voz", "")))
		return ""
	_mostrando = true
	_cerrar_popup()
	_cerrar_inspiracion()
	mostrar_coco(6.0)
	_reinicio_t = -1.0
	_boton_deshacer.hide()
	_boton_reiniciar.hide()
	lienzo.bloqueado = true
	lienzo.terminar_trazo()
	_voz_diferida_id += 1
	if _tween_mostrar != null and _tween_mostrar.is_valid():
		_tween_mostrar.kill()
	boton_mostrar.scale = Vector2.ONE
	reproducir_sfx(SFX_MOSTRAR)
	var ruta := _guardar_dibujo()
	hoja_mostrada.emit(_indice_hoja, ruta)
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"]
	var voz := ""
	if not _lamina_nombrada and str(lamina.get("voz", "")) != "":
		voz = str(lamina["voz"])
	elif _es_igualita():
		voz = _linea_al_azar("igualita")
	if voz == "":
		voz = _linea_al_azar("mostrar")
	_reproducir_voz("mostrar", voz)
	var colores := _ultimos_colores()
	_cresta.imitar(colores if colores.size() >= 2 else Figura.COLORES_ARCOIRIS.duplicate())
	_reaccion_anfitriona("baila")
	_confeti_en(Vector2(640, 360))
	_estallido(boton_mostrar.global_position + boton_mostrar.size / 2.0, 14, Figura.COLORES_ARCOIRIS, 1.3)
	var tween := create_tween()
	tween.tween_property(lienzo, "modulate", Color(1.15, 1.15, 1.15), 0.18)
	tween.tween_property(lienzo, "modulate", Color.WHITE, 0.25)
	var espera := clampf(_duracion_voz(voz) + 0.5, 1.4, 5.0)
	_despues(espera, _despues_de_mostrar)
	return ruta


## Como `_despues`, pero se cancela si la hoja cambio entre medio.
func _despues_en_hoja(segundos: float, accion: Callable) -> void:
	var hoja := _indice_hoja
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree() and hoja == _indice_hoja and not _mostrando:
		accion.call()


func _despues_de_mostrar() -> void:
	if _indice_hoja + 1 < _hojas.size():
		var tween := create_tween()
		tween.tween_property(lienzo, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func() -> void: _empezar_hoja(_indice_hoja + 1))
		tween.tween_property(lienzo, "modulate:a", 1.0, 0.3)
		return
	_terminado = true
	celebrar(calcular_destellos(), 0, _linea_al_azar("victoria_final"))


## Destellos (ficha §9.6): 10 por hoja mostrada + los de cada objetivo cumplido (36 por hoja
## repartidos entre sus objetivos) + 1 por color distinto usado (hasta 10).
func calcular_destellos() -> int:
	return maxi(1, _indice_hoja + 1) * DESTELLOS_POR_HOJA + _destellos_objetivos + mini(_colores_usados.size(), MAX_DESTELLOS_COLORES)


## Colorear por zonas con tarjeta modelo: si cada zona quedo del color de la tarjeta, Coco lo nota.
func _es_igualita() -> bool:
	if not bool(_cfg.get("modelo", false)) or lienzo.lamina.is_empty():
		return false
	var candidatos: Array = []
	for entrada: Dictionary in _botones_color:
		candidatos.append(entrada["id"])
	for i in lienzo.regiones_rellenables():
		var region: Dictionary = lienzo.lamina["regiones"][i]
		if not region.has("sugerido"):
			continue
		var esperado := Colores.mas_cercano(Color(str(region["sugerido"])), candidatos)
		if Colores.mas_cercano(region["color"], candidatos) != esperado:
			return false
	return true


func _guardar_dibujo() -> String:
	var hermano := obtener_id_personaje()
	var sello := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var ruta := "%s/%s/%s_%d_%s.png" % [carpeta_dibujos, hermano, str(nivel.get("id_nivel", "dibujo")), _indice_hoja + 1, sello]
	var imagen := lienzo.componer()
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	var error := imagen.save_png(ruta)
	if error != OK:
		push_warning("motor_lienzo_libre: no se pudo guardar el dibujo en %s (%s)" % [ruta, error_string(error)])
		return ""
	pngs_guardados.append(ruta)
	print("[dibujo] %s" % ruta)
	# El ala decorada y el traje de Coco tienen nombre fijo para que el hangar y el mapa los encuentren.
	var fijo := str(_cfg.get("guardar_como", ""))
	if fijo != "":
		imagen.save_png("%s/%s/%s.png" % [carpeta_dibujos, hermano, fijo])
	if _traje != "":
		var colores := {}
		for region: Dictionary in lienzo.lamina.get("regiones", []):
			if not bool(region.get("fija", false)):
				colores[str(region.get("id", ""))] = "#" + (region["color"] as Color).to_html(false)
		var archivo := FileAccess.open("%s/%s/traje_coco.json" % [carpeta_dibujos, hermano], FileAccess.WRITE)
		if archivo != null:
			archivo.store_string(JSON.stringify({"traje": _traje, "colores": colores}, "  "))
			archivo.close()
	return ruta


# ---------------------------------------------------------------------------
# Momentos memorables y efectos
# ---------------------------------------------------------------------------

## Nicole: Coco le devuelve su corazon coreano la primera vez que usa el pincel corazon.
func _corazon_coreano() -> void:
	var corazon := Figura.new()
	corazon.figura = "corazon"
	corazon.color = Color("#FF7EB6")
	corazon.con_cara = true
	corazon.alegre = true
	corazon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corazon.size = Vector2(110, 110)
	corazon.pivot_offset = corazon.size / 2.0
	_efectos.add_child(corazon)
	corazon.global_position = _anfitriona.global_position + Vector2(_anfitriona.size.x / 2.0 - 55, -70)
	corazon.scale = Vector2.ZERO
	var tween := corazon.create_tween()
	tween.tween_property(corazon, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		tween.tween_property(corazon, "scale", Vector2(1.0, 1.0), 0.18)
		tween.tween_property(corazon, "scale", Vector2(1.2, 1.2), 0.18)
	tween.tween_property(corazon, "modulate:a", 0.0, 0.4)
	tween.tween_callback(corazon.queue_free)
	_reaccion_anfitriona("salta")


## Sofia: la purpurina quieta un segundo hace llover destellos dorados (ficha §3.10).
func _lluvia_dorada(posicion: Vector2) -> void:
	for objetivo: Dictionary in _objetivos:
		if str(objetivo["datos"].get("tipo", "")) == "usar" and str(objetivo["datos"].get("herramienta", "")) == "purpurina":
			objetivo["registro"]["lluvias"] = int(objetivo["registro"].get("lluvias", 0)) + 1
	_primer_uso_especial("purpurina_lluvia")
	var global := lienzo.a_pantalla(posicion)
	for i in 22:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = DORADO if i % 3 else Color.WHITE
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(14.0, 26.0)
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.global_position = global + Vector2(randf_range(-90, 90), randf_range(-140, -40))
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position:y", chispa.position.y + randf_range(120, 220), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 1.1)
		tween.tween_property(chispa, "modulate:a", 0.0, 1.1).set_delay(0.5)
		tween.chain().tween_callback(chispa.queue_free)
	var herramienta := lienzo.herramienta
	var color := lienzo.color_actual
	lienzo.color_actual = DORADO
	for i in 14:
		var p := posicion + Vector2(randf_range(-80, 80), randf_range(-30, 110))
		lienzo._estampar_en(p, false)
	lienzo.color_actual = color
	lienzo.herramienta = herramienta


func _preparar_notas() -> void:
	for i in 4:
		var reproductor := AudioStreamPlayer.new()
		reproductor.bus = "SFX"
		add_child(reproductor)
		_notas.append(reproductor)
	for hz in NOTAS_HZ:
		_sonidos_nota.append(_campanita(hz))


## Nota de campanita sintetizada (seno con armonico y caida suave): sin archivos de audio.
func _campanita(hz: float) -> AudioStreamWAV:
	var frecuencia := 22050
	var muestras := int(frecuencia * 0.7)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / frecuencia
		var envolvente := exp(-t * 5.5) * minf(1.0, t * 200.0)
		var valor := (sin(TAU * hz * t) * 0.7 + sin(TAU * hz * 2.0 * t) * 0.2 + sin(TAU * hz * 3.0 * t) * 0.1) * envolvente * 0.45
		datos.encode_s16(i * 2, int(clampf(valor, -1.0, 1.0) * 32767.0))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = frecuencia
	sonido.stereo = false
	sonido.data = datos
	return sonido


## Dedo magico: la altura del trazo elige la nota (mas arriba, mas aguda).
func _tocar_nota(altura: float) -> void:
	if not bool(_cfg.get("notas", false)) or _sonidos_nota.is_empty():
		return
	var indice := clampi(int(altura * _sonidos_nota.size()), 0, _sonidos_nota.size() - 1)
	var reproductor := _notas[_indice_nota % _notas.size()]
	_indice_nota += 1
	reproductor.stream = _sonidos_nota[indice]
	reproductor.play()


func _confeti_en(posicion: Vector2) -> void:
	_confeti.position = posicion
	_confeti.restart()


func _estallido(centro: Vector2, cantidad: int, colores: Array, escala := 1.0) -> void:
	for i in cantidad:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = colores[i % colores.size()]
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(18.0, 30.0) * escala
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.global_position = centro - chispa.size / 2.0
		var angulo := TAU * i / cantidad + randf_range(-0.3, 0.3)
		var destino := chispa.position + Vector2.from_angle(angulo) * randf_range(50.0, 100.0) * escala
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 0.5)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


# ---------------------------------------------------------------------------
# Voz, Coco y Cometa
# ---------------------------------------------------------------------------

func _linea(clave: String) -> String:
	var valor = _cfg.get("lineas_voz", {}).get(clave, "")
	if valor is Array:
		return str(valor[0]) if not valor.is_empty() else ""
	return str(valor)


## Elige una variante sin repetir la ultima, para que no suene monotono.
func _linea_al_azar(clave: String) -> String:
	var opciones = _cfg.get("lineas_voz", {}).get(clave, [])
	if not (opciones is Array):
		return str(opciones)
	if opciones.is_empty():
		return ""
	var elegida := str(opciones[randi() % opciones.size()])
	if elegida == _ultima_linea and opciones.size() > 1:
		elegida = str(opciones[(opciones.find(elegida) + 1) % opciones.size()])
	_ultima_linea = elegida
	return elegida


func _reproducir_voz(clave: String, ruta: String) -> void:
	# Traza en consola para los arneses QA + reproduccion real via contrato base.
	if ruta != "":
		print("[voz:%s] %s" % [clave, ruta])
		reproducir_voz(ruta)
		# Coco aparece en su burbujita solo mientras habla (§11.4).
		mostrar_coco(_duracion_voz(ruta))


func _voz_diferida(clave: String, ruta: String, segundos: float) -> void:
	if ruta == "":
		return
	_voz_diferida_id += 1
	var id := _voz_diferida_id
	await get_tree().create_timer(segundos).timeout
	if id == _voz_diferida_id and is_inside_tree() and not _terminado and not _mostrando:
		_reproducir_voz(clave, ruta)


func _duracion_voz(ruta: String) -> float:
	var final := resolver_ruta_audio(ruta)
	if final == "" or not ResourceLoader.exists(final):
		return 0.8
	var stream := load(final) as AudioStream
	return stream.get_length() if stream != null else 0.8


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()


## Efecto de respuesta inmediata (GDD §6.5), sin ametrallar el mismo sonido al arrastrar.
func _sfx_suave(ruta: String) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - int(_ms_sfx.get(ruta, -1000)) < 90:
		return
	_ms_sfx[ruta] = ahora
	reproducir_sfx(ruta)


## Tocar a Cometa repite la instruccion (GDD §6.2): el pedido actual, la pista o la intro.
func _al_tocar_cometa() -> void:
	_sfx_suave(SFX_TOQUE)
	if _pedido_actual >= 0 and _ruta_pedido() != "":
		_reproducir_voz("pedido", _ruta_pedido())
		return
	var pista := _linea("pista")
	_reproducir_voz("pista", pista if pista != "" else _linea("intro"))


## Tocar a Coco: salta y repite el objetivo que toca, con su pista fantasma. Con todo cumplido,
## pide que le muestren el dibujo.
func _al_tocar_anfitriona(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not toque:
		return
	_sfx_suave(SFX_TOQUE)
	_reaccion_anfitriona("salta")
	if _objetivos_listos:
		_revelar_boton_mostrar(true)
		return
	pista_fantasma()


func _reaccion_anfitriona(tipo: String) -> void:
	# Las celebraciones (tambien el salto de Maxi al caer un sticker) traen a Coco en su burbujita.
	mostrar_coco(2.2 if tipo == "baila" else 0.9)
	if _tween_anfitriona != null and _tween_anfitriona.is_valid():
		_tween_anfitriona.kill()
	_cuerpo_coco.rotation = 0.0
	_cuerpo_coco.scale = Vector2.ONE
	_salto_anfitriona = 0.0
	var tween := create_tween()
	_tween_anfitriona = tween
	match tipo:
		"salta":
			tween.tween_property(_cuerpo_coco, "scale", Vector2(1.08, 0.9), 0.08)
			tween.tween_property(self, "_salto_anfitriona", 28.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_cuerpo_coco, "scale", Vector2(0.94, 1.08), 0.18)
			tween.tween_property(self, "_salto_anfitriona", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_cuerpo_coco, "scale", Vector2.ONE, 0.3)
		"baila":
			for i in 6:
				tween.tween_property(self, "_salto_anfitriona", 24.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(_cuerpo_coco, "rotation", deg_to_rad(-12.0 if i % 2 == 0 else 12.0), 0.16)
				tween.tween_property(self, "_salto_anfitriona", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(_cuerpo_coco, "rotation", 0.0, 0.12)


func _rebote(control: Control, veces := 1) -> void:
	control.pivot_offset = control.size / 2.0
	var tween := control.create_tween()
	for i in veces:
		tween.tween_property(control, "scale", Vector2(0.86, 0.86), 0.07)
		tween.tween_property(control, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _actualizar_depuracion() -> void:
	if not _panel_depuracion.visible:
		return
	var pendientes: Array = []
	for objetivo: Dictionary in _objetivos:
		if not objetivo["hecho"]:
			pendientes.append("%s %d/%d" % [objetivo["datos"].get("tipo", "?"), objetivo["actual"], objetivo["meta"]])
	_panel_depuracion.text = "DEPURACION (F3)\nnivel: %s\nperfil: %s · juega: %s\nencargo: %s · hoja %d de %d\nherramienta: %s · zoom %.1f\nobjetivos pendientes: %s\nsi muestra ahora: %d destellos" % [
		nivel.get("id_nivel", "?"), _perfil, obtener_id_personaje(), _encargo, _indice_hoja + 1, _hojas.size(),
		lienzo.herramienta, lienzo.zoom, ", ".join(pendientes) if not pendientes.is_empty() else "ninguno", calcular_destellos()]


# ---------------------------------------------------------------------------
# Fisica, sol, deshacer y reiniciar (ficha §10)
# ---------------------------------------------------------------------------

## Coco deja de ocupar un lugar fijo del lienzo (ficha §11.4): vive en una BURBUJITA redonda con su cara
## (el mismo TextureRect, con su cresta que imita colores, recortado por un circulo) a la derecha, debajo
## de las tarjetas de objetivos y arriba de "mostrar a Coco" (no tapa el objetivo que narra). Aparece
## con un "pop" cuando habla o celebra y se va sola al terminar. Tocarla mientras esta da la pista;
## si no esta, tocar la tarjeta del objetivo repite su voz (o Cometa repite la instruccion).
func _armar_burbuja_coco() -> void:
	var lado := Vector2.ONE * RADIO_BURBUJA * 2.0
	_burbuja_coco = Control.new()
	_burbuja_coco.mouse_filter = Control.MOUSE_FILTER_STOP
	_burbuja_coco.tooltip_text = _anfitriona.tooltip_text
	_ui.add_child(_burbuja_coco)
	_ui.move_child(_burbuja_coco, _anfitriona.get_index())
	_burbuja_coco.size = lado
	_burbuja_coco.position = CENTRO_BURBUJA - lado / 2.0
	_burbuja_coco.pivot_offset = lado / 2.0
	_base_anfitriona = _burbuja_coco.position
	_burbuja_coco.gui_input.connect(_al_tocar_anfitriona)
	_cuerpo_coco = Control.new()
	_cuerpo_coco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_burbuja_coco.add_child(_cuerpo_coco)
	_cuerpo_coco.size = lado
	_cuerpo_coco.pivot_offset = Vector2(lado.x / 2.0, lado.y)
	_cuerpo_coco.draw.connect(func() -> void:
		# Sombra y colita de globo de dialogo (apunta hacia el lienzo).
		var c := lado / 2.0
		_cuerpo_coco.draw_circle(c + Vector2(0, 5), RADIO_BURBUJA, Color(COLOR_CONTORNO, 0.25))
		var cola := PackedVector2Array([c + Vector2(-RADIO_BURBUJA * 0.55, RADIO_BURBUJA * 0.55), c + Vector2(-RADIO_BURBUJA * 1.2, RADIO_BURBUJA * 1.05),
			c + Vector2(-RADIO_BURBUJA * 0.15, RADIO_BURBUJA * 0.85)])
		_cuerpo_coco.draw_colored_polygon(cola, Color("#FFF3FA"))
		var borde := cola.duplicate()
		borde.append(cola[0])
		_cuerpo_coco.draw_polyline(borde, COLOR_CONTORNO, 4.0, true))
	var mascara := Control.new()
	mascara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascara.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_cuerpo_coco.add_child(mascara)
	mascara.size = lado
	mascara.draw.connect(func() -> void: mascara.draw_circle(lado / 2.0, RADIO_BURBUJA, Color("#FFF3FA")))
	# La cabeza de coco_base.png (293x459) ocupa ~(30..264, 0..230): se centra en el circulo.
	_anfitriona.reparent(mascara, false)
	_anfitriona.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_anfitriona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anfitriona.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_anfitriona.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tam := _anfitriona.texture.get_size() if _anfitriona.texture != null else Vector2(293, 459)
	var escala := RADIO_BURBUJA * 2.0 / 228.0
	_anfitriona.size = tam * escala
	_anfitriona.position = lado / 2.0 - Vector2(147, 112) * escala
	_anfitriona.rotation = 0.0
	_anfitriona.scale = Vector2.ONE
	var aro := Control.new()
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cuerpo_coco.add_child(aro)
	aro.size = lado
	aro.draw.connect(func() -> void:
		aro.draw_arc(lado / 2.0, RADIO_BURBUJA - 2.0, 0.0, TAU, 48, COLOR_CONTORNO, 5.0, true)
		aro.draw_arc(lado / 2.0, RADIO_BURBUJA - 10.0, -2.6, -1.9, 10, Color(1, 1, 1, 0.8), 5.0, true))
	_burbuja_coco.hide()


## Coco aparece (o se queda) en su burbujita al menos `segundos` mas el margen. Publica para QA.
func mostrar_coco(segundos: float) -> void:
	_coco_hasta = maxf(_coco_hasta, _tiempo + segundos + MARGEN_BURBUJA)
	if _burbuja_coco.visible and not _coco_saliendo:
		return
	_coco_saliendo = false
	if _tween_burbuja != null and _tween_burbuja.is_valid():
		_tween_burbuja.kill()
	_burbuja_coco.show()
	_ui.move_child(_burbuja_coco, -1)
	_ui.move_child(_efectos, -1)
	_burbuja_coco.scale = Vector2(0.2, 0.2)
	_tween_burbuja = _burbuja_coco.create_tween()
	_tween_burbuja.tween_property(_burbuja_coco, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ocultar_coco() -> void:
	_coco_saliendo = true
	if _tween_burbuja != null and _tween_burbuja.is_valid():
		_tween_burbuja.kill()
	_tween_burbuja = _burbuja_coco.create_tween()
	_tween_burbuja.tween_property(_burbuja_coco, "scale", Vector2(0.15, 0.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween_burbuja.tween_callback(func() -> void:
		_burbuja_coco.hide()
		_coco_saliendo = false)


func coco_visible() -> bool:
	return _burbuja_coco.visible and not _coco_saliendo


## Un personaje se subio a un animal o vehiculo: "¡hop!" y destellitos (§11.9).
func _al_montar(jinete: StickerVivo, montura: StickerVivo) -> void:
	reproducir_sfx(SFX_HOP, 1.3)
	_estallido(lienzo.a_pantalla(jinete.centro()), 8, [DORADO, Color.WHITE, Color("#FF7EB6")], 0.8)
	_registrar_evento("montar", {"jinete": jinete.id, "montura": montura.id})
	_revisar_objetivos()


## Maxi oye un silbidito al empezar a caer (gracioso, no de error).
func _al_empezar_caida(_sticker: StickerVivo) -> void:
	if _perfil == "semilla":
		reproducir_sfx(SFX_CAIDA, 0.75)


## "¡Puff!" al aterrizar. Maxi: boing mas gracioso, estrellitas y Coco salta.
func _al_aterrizar(sticker: StickerVivo, grande: bool) -> void:
	_sfx_suave(SFX_POLVO_MAXI if grande else SFX_POLVO)
	if grande:
		var base := sticker.centro() + Vector2(0, sticker.lado * sticker.escala * 0.43)
		_estallido(lienzo.a_pantalla(base), 8, [Color("#F6EBD8"), Color.WHITE, DORADO], 0.9)
		_reaccion_anfitriona("salta")
	_revisar_objetivos()


## El sol se quemo las manos fuera del cielo: chisporroteo y "¡uy, qué calor!" (sin repetir seguido).
func _al_quemar_sol(_sol: StickerVivo, _cuantos: int) -> void:
	reproducir_sfx(SFX_CHISPORROTEO)
	_reaccion_anfitriona("salta")
	var ahora := Time.get_ticks_msec()
	if ahora - _ms_ultimo_sol > 4000:
		_ms_ultimo_sol = ahora
		_reproducir_voz("sol_quema", _linea("sol_quema"))


func _colocar_botones_edicion() -> void:
	var lado := _lado_boton()
	var y := Y_EDICION + (100.0 - lado) / 2.0
	for i in 2:
		var boton: Button = [_boton_deshacer, _boton_reiniciar][i]
		boton.position = Vector2(X_EDICION + i * (lado + 28.0), y)
		boton.size = Vector2(lado, lado)
		boton.pivot_offset = boton.size / 2.0
		boton.scale = Vector2.ONE
		boton.show()
	_reinicio_t = -1.0
	_barriendo = false
	_al_cambiar_historial(lienzo.pasos_para_deshacer())


## Con historial vacio la flecha se ve apagada (sigue respondiendo al toque con un saltito).
func _al_cambiar_historial(pasos: int) -> void:
	if _boton_deshacer == null:
		return
	_boton_deshacer.modulate = Color.WHITE if pasos > 0 else Color(1, 1, 1, 0.45)
	(_boton_deshacer.get_meta("dibujo") as Control).queue_redraw()


## Deshace la ultima accion (trazo, sticker puesto o movido, camino...). No quita objetivos cumplidos
## ni destellos. Publica para QA.
func deshacer() -> bool:
	if _mostrando or _terminado or _barriendo or lienzo.bloqueado:
		return false
	_cerrar_popup()
	_ocultar_barra()
	if not lienzo.deshacer():
		_sfx_suave(SFX_TOQUE)
		return false
	_sfx_suave(SFX_REBOBINAR)
	_estallido(_boton_deshacer.global_position + _boton_deshacer.size / 2.0, 6, [Color("#FF9A2E"), Color.WHITE], 0.6)
	_revisar_objetivos()
	return true


func _empezar_a_mantener() -> void:
	if _mostrando or _terminado or _barriendo:
		return
	_cerrar_popup()
	_ocultar_barra()
	_reinicio_t = 0.0
	_sfx_suave(SFX_TOQUE)
	_anillo_reiniciar.queue_redraw()


## Se solto antes de tiempo: el anillo se vacia y Coco explica (una vez cada tanto) que hay que dejar
## el dedo apretado.
func _soltar_reiniciar() -> void:
	if _reinicio_t < 0.0:
		return
	var corto := _reinicio_t < SEGUNDOS_REINICIAR
	_reinicio_t = -1.0
	_anillo_reiniciar.queue_redraw()
	if corto:
		_rebote(_boton_reiniciar)
		var ahora := Time.get_ticks_msec()
		if ahora - _ms_pista_reiniciar > 8000:
			_ms_pista_reiniciar = ahora
			_reproducir_voz("reiniciar_mantener", _linea("reiniciar_mantener"))


## Reinicia la hoja con un "¡fuuush!" de escoba: borra pintura, stickers y caminos y vuelve a los
## iniciales; vacia el historial; los objetivos cumplidos y los destellos se quedan. Publica para QA
## (`animado` = false lo hace al instante).
func reiniciar_lienzo(animado := true) -> void:
	if _mostrando or _terminado or _barriendo:
		return
	_cerrar_popup()
	_ocultar_barra()
	if not animado:
		lienzo.reiniciar()
		_revisar_objetivos()
		return
	_barriendo = true
	lienzo.bloqueado = true
	reproducir_sfx(SFX_FUUSH)
	var escoba := Control.new()
	escoba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escoba.size = Vector2(220, 220)
	escoba.pivot_offset = Vector2(110, 200)
	escoba.draw.connect(_dibujar_escoba_grande.bind(escoba))
	_efectos.add_child(escoba)
	escoba.position = Vector2(-240, 420)
	escoba.rotation = -0.35
	var tween := escoba.create_tween()
	tween.tween_property(escoba, "position:x", 560.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(escoba, "rotation", 0.35, 0.32)
	tween.tween_callback(func() -> void:
		lienzo.reiniciar()
		_revisar_objetivos()
		for i in 5:
			_estallido(Vector2(200 + i * 220, 520 + (i % 2) * 60), 5, [Color("#F6EBD8"), Color.WHITE, Color("#FFE38A")], 0.9))
	tween.tween_property(escoba, "position:x", 1380.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(escoba, "rotation", -0.35, 0.36)
	tween.tween_callback(func() -> void:
		escoba.queue_free()
		_barriendo = false
		if not _mostrando:
			lienzo.bloqueado = false
		_reaccion_anfitriona("salta")
		_reproducir_voz("reiniciar", _linea("reiniciar")))


func _dibujar_icono_deshacer(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var radio := 22.0 * k
	var centro := c + Vector2(4, 6) * k
	# Arco de la flecha (de la derecha, por arriba, hacia la izquierda) y su punta.
	icono.draw_arc(centro, radio, PI * 1.05, TAU * 1.0 + PI * 0.25, 24, COLOR_CONTORNO, 15.0 * k, true)
	icono.draw_arc(centro, radio, PI * 1.05, TAU * 1.0 + PI * 0.25, 24, Color("#FF9A2E"), 8.0 * k, true)
	var punta := centro + Vector2.from_angle(PI * 1.05) * radio
	var cabeza := PackedVector2Array([punta + Vector2(-16, -2) * k, punta + Vector2(10, -6) * k, punta + Vector2(-2, 18) * k])
	icono.draw_colored_polygon(cabeza, Color("#FF9A2E"))
	cabeza.append(cabeza[0])
	icono.draw_polyline(cabeza, COLOR_CONTORNO, 4.0 * k, true)


func _dibujar_icono_reiniciar(icono: Control) -> void:
	_dibujar_escoba(icono, icono.size / 2.0 + Vector2(2, 4) * icono.size.x / 96.0, icono.size.x / 96.0 * 0.8)


## Anillo que se llena mientras se mantiene presionada la escoba.
func _dibujar_anillo_reiniciar(icono: Control) -> void:
	if _reinicio_t < 0.0:
		return
	var c := icono.size / 2.0
	var r := icono.size.x / 2.0 - 4.0
	var k := clampf(_reinicio_t / SEGUNDOS_REINICIAR, 0.0, 1.0)
	icono.draw_arc(c, r, 0.0, TAU, 40, Color(COLOR_CONTORNO, 0.25), 10.0, true)
	icono.draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color("#45C6C0"), 10.0, true)


func _dibujar_escoba_grande(control: Control) -> void:
	_dibujar_escoba(control, Vector2(110, 110), 2.4)


## Escoba de peluche: palo de madera, atadura violeta y paja dorada.
func _dibujar_escoba(l: Control, c: Vector2, k: float) -> void:
	l.draw_line(c + Vector2(18, -40) * k, c + Vector2(-2, 8) * k, COLOR_CONTORNO, 11.0 * k, true)
	l.draw_line(c + Vector2(18, -40) * k, c + Vector2(-2, 8) * k, Color("#B07A55"), 6.0 * k, true)
	var paja := PackedVector2Array([c + Vector2(-10, 4) * k, c + Vector2(8, 10) * k, c + Vector2(6, 40) * k, c + Vector2(-30, 34) * k])
	l.draw_colored_polygon(paja, Color("#FFCB3D"))
	var contorno := paja.duplicate()
	contorno.append(paja[0])
	l.draw_polyline(contorno, COLOR_CONTORNO, 4.0 * k, true)
	for t in [0.3, 0.55, 0.8]:
		l.draw_line(c + Vector2(-10, 4).lerp(Vector2(8, 10), t) * k, c + Vector2(-30, 34).lerp(Vector2(6, 40), t) * k, Color("#D9A21E"), 2.5 * k, true)
	l.draw_line(c + Vector2(-11, 3) * k, c + Vector2(9, 9) * k, Color("#9357D6"), 6.0 * k, true)


# ---------------------------------------------------------------------------
# Dibujo de iconos (estilo "peluche pintado", sin texto)
# ---------------------------------------------------------------------------

func _estilizar_boton(boton: Button, fondo: Color, conectar := true) -> void:
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = fondo.darkened(0.12) if estado == "pressed" else fondo
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(5)
		caja.set_corner_radius_all(64)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
		caja.shadow_offset = Vector2(0, 5)
		caja.shadow_size = 2
		caja.anti_aliasing = true
		boton.add_theme_stylebox_override(estado, caja)
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if conectar:
		boton.button_down.connect(_rebote.bind(boton))


## Icono de cada boton del dock: el color actual, el pincel o sticker elegido del grupo, la lupa.
func _dibujar_dock(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	var grupo: String = boton.get_meta("grupo", "")
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	match grupo:
		"colores":
			var r := 30.0 * k
			icono.draw_circle(c, r + 4.0 * k, Color.WHITE)
			icono.draw_circle(c, r, lienzo.color_actual)
			icono.draw_arc(c, r, 0, TAU, 32, COLOR_CONTORNO, 4.0 * k, true)
			for i in 5:
				var p := c + Vector2.from_angle(-PI * 0.9 + i * PI * 0.2) * (r + 10.0 * k)
				icono.draw_circle(p, 6.0 * k, Figura.COLORES_ARCOIRIS[i])
			icono.draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.18, Color(1, 1, 1, 0.55))
		"lupa":
			icono.draw_circle(c + Vector2(-6, -6) * k, 22.0 * k, Color("#CFF5F1"))
			icono.draw_arc(c + Vector2(-6, -6) * k, 22.0 * k, 0, TAU, 28, COLOR_CONTORNO, 6.0 * k, true)
			icono.draw_line(c + Vector2(10, 10) * k, c + Vector2(28, 28) * k, COLOR_CONTORNO, 10.0 * k, true)
			icono.draw_line(c + Vector2(-16, -6) * k, c + Vector2(4, -6) * k, COLOR_CONTORNO, 5.0 * k, true)
			icono.draw_line(c + Vector2(-6, -16) * k, c + Vector2(-6, 4) * k, COLOR_CONTORNO, 5.0 * k, true)
		"ver_todo":
			var rect := Rect2(c - Vector2(26, 18) * k, Vector2(52, 36) * k)
			icono.draw_rect(rect, Color("#FFF8EE"))
			icono.draw_rect(rect, COLOR_CONTORNO, false, 4.0 * k)
			for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var p: Vector2 = c + esquina * Vector2(34, 26) * k
				icono.draw_line(p, p - esquina * Vector2(10, 0) * k, COLOR_CONTORNO, 4.0 * k, true)
				icono.draw_line(p, p - esquina * Vector2(0, 10) * k, COLOR_CONTORNO, 4.0 * k, true)
		_:
			var items: Array = _grupos.get(grupo, [])
			var id: String = lienzo.herramienta if items.has(lienzo.herramienta) else (str(items[0]) if not items.is_empty() else "")
			if grupo == "trajes" and _traje != "":
				id = "traje_" + _traje
			_dibujar_item(icono, id)


func _dibujar_herramienta(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	_dibujar_item(icono, boton.get_meta("id", ""))


func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-26, 0), Vector2(2, -26), Vector2(2, -12), Vector2(26, -12), Vector2(26, 12), Vector2(2, 12), Vector2(2, 26)]:
		puntos.append(c + p * k)
	icono.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(icono, puntos, 5.0 * k)


## Marquito con un dibujito en la esquina del boton "mostrar a Coco": "le muestro mi dibujo".
func _dibujar_marquito(icono: Control) -> void:
	var rect := Rect2(icono.size - Vector2(62, 54), Vector2(56, 46))
	icono.draw_rect(rect, Color("#FFF8EE"))
	icono.draw_rect(rect, COLOR_CONTORNO, false, 4.0)
	var c := rect.get_center()
	icono.draw_circle(c + Vector2(-10, -6), 8.0, Color("#FF7EB6"))
	icono.draw_circle(c + Vector2(8, 4), 9.0, Color("#6FD6E8"))
	icono.draw_circle(c + Vector2(-4, 10), 6.0, DORADO)


## Mancha de pintura redondita de la paleta (con numero en el mosaico de Sofia).
func _dibujar_mancha(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	var color: Color = boton.get_meta("color", Color.WHITE)
	var numero: String = boton.get_meta("numero", "")
	var elegido: bool = boton.get_meta("elegido", false)
	var c := icono.size / 2.0
	var r := minf(icono.size.x, icono.size.y) * 0.42
	var mancha := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var ondulacion := 1.0 + 0.06 * sin(a * 5.0 + color.h * 10.0)
		mancha.append(c + Vector2(cos(a) * r * ondulacion * (icono.size.x / icono.size.y if numero != "" else 1.0), sin(a) * r * ondulacion))
	if elegido:
		var halo := PackedVector2Array()
		for p in mancha:
			halo.append(c + (p - c) * 1.18)
		icono.draw_colored_polygon(halo, Color(1, 1, 1, 0.9))
		Figura.contornear(icono, halo, 4.0)
	icono.draw_colored_polygon(mancha, color)
	Figura.contornear(icono, mancha, 4.0)
	icono.draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.55))
	if numero != "" and _fuente != null:
		var claro := color.get_luminance() > 0.6
		var tam := int(r * 1.1)
		icono.draw_string(_fuente, Vector2(0, c.y + tam * 0.36), numero, HORIZONTAL_ALIGNMENT_CENTER, icono.size.x, tam, COLOR_CONTORNO if claro else Color.WHITE)


func _dibujar_item(icono: Control, id: String) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var color := lienzo.color_actual
	if id.begins_with("traje_"):
		_dibujar_traje_mini(icono, id.trim_prefix("traje_"))
		return
	if id.begins_with("camino_"):
		_dibujar_icono_camino(icono, id.trim_prefix("camino_"), c, k)
		return
	if id.begins_with("sello_") and lienzo.stickers_objeto and Stickers.tiene(id.trim_prefix("sello_")):
		var sticker := id.trim_prefix("sello_")
		Stickers.dibujar(icono, sticker, color if _perfil == "semilla" else Stickers.color_por_defecto(sticker), c, 38.0 * k)
		return
	if id.begins_with("sello_"):
		var tipo := id.trim_prefix("sello_")
		var radio := 34.0 * k
		for parte: Dictionary in Sellos.partes(tipo, color):
			var poligono := PackedVector2Array()
			for p: Vector2 in parte["poligono"]:
				poligono.append(c + p * radio)
			if poligono.size() >= 3 and parte.has("color"):
				icono.draw_colored_polygon(poligono, parte["color"])
				if parte.get("contorno", true):
					Figura.contornear(icono, poligono, 2.5 * k)
		return
	match id:
		"pincel", "pincel_grueso":
			var grosor := 12.0 if id == "pincel" else 22.0
			icono.draw_line(c + Vector2(18, -26) * k, c + Vector2(-2, 2) * k, Color("#C98A4B"), 10.0 * k, true)
			icono.draw_circle(c + Vector2(-8, 10) * k, grosor * k, color)
			icono.draw_arc(c + Vector2(-8, 10) * k, grosor * k, 0, TAU, 24, COLOR_CONTORNO, 3.0 * k, true)
		"goma":
			var goma := Laminas.rectangulo(Rect2(c + Vector2(-28, -16) * k, Vector2(56, 32) * k), 8.0 * k)
			icono.draw_colored_polygon(goma, Color("#FFB3C7"))
			Figura.contornear(icono, goma, 3.5 * k)
			icono.draw_line(c + Vector2(4, -16) * k, c + Vector2(4, 16) * k, COLOR_CONTORNO, 3.0 * k)
		"balde":
			var balde := PackedVector2Array([c + Vector2(-24, -10) * k, c + Vector2(24, -10) * k, c + Vector2(18, 28) * k, c + Vector2(-18, 28) * k])
			icono.draw_colored_polygon(balde, Color("#D7DCEA"))
			Figura.contornear(icono, balde, 3.5 * k)
			icono.draw_colored_polygon(Laminas.elipse(c + Vector2(0, -10) * k, 24 * k, 8 * k, 20), color)
			icono.draw_arc(c + Vector2(0, -12) * k, 26 * k, PI, TAU, 16, COLOR_CONTORNO, 3.0 * k, true)
			Figura.dibujar(icono, "gota", color, c + Vector2(26, 14) * k, 12 * k, false)
		"arcoiris":
			for i in Figura.COLORES_ARCOIRIS.size():
				icono.draw_arc(c + Vector2(0, 14) * k, (34.0 - i * 5.0) * k, PI, TAU, 24, Figura.COLORES_ARCOIRIS[i], 5.5 * k, true)
		"purpurina":
			for p in [[Vector2(-12, -8), 16.0, DORADO], [Vector2(16, 12), 12.0, Color("#FFF3B0")], [Vector2(-10, 20), 9.0, color]]:
				var chispa := PackedVector2Array()
				for i in 8:
					chispa.append(c + p[0] * k + Vector2.from_angle(-PI / 2.0 + i * PI / 4.0) * p[1] * k * (1.0 if i % 2 == 0 else 0.3))
				icono.draw_colored_polygon(chispa, p[2])
				Figura.contornear(icono, chispa, 2.0 * k)
		"pincel_corazon", "pincel_estrella":
			var figura := id.trim_prefix("pincel_")
			for p in [[Vector2(-16, 12), 14.0], [Vector2(2, -4), 12.0], [Vector2(18, -18), 10.0]]:
				Figura.dibujar(icono, figura, color, c + p[0] * k, p[1] * k, false)


## Icono de un tipo de camino: un tramo curvo con su estilo.
func _dibujar_icono_camino(icono: Control, tipo: String, c: Vector2, k: float) -> void:
	var puntos := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		puntos.append(c + Vector2(-32.0 + 64.0 * t, 14.0 - 24.0 * sin(t * PI)) * k)
	Lienzo.dibujar_camino(icono, puntos, tipo, 0.5 * k, 1.0)


## Pictograma del objetivo y su progreso ("3/5") o una estrella al cumplirlo.
func _dibujar_chip(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	var i: int = boton.get_meta("indice", 0)
	if i >= _objetivos.size():
		return
	var objetivo: Dictionary = _objetivos[i]
	var o: Dictionary = objetivo["datos"]
	var c := icono.size / 2.0 + Vector2(0, -8)
	var r := icono.size.y * 0.3
	var iconos = o.get("icono", "")
	if iconos is String:
		iconos = [iconos] if iconos != "" else []
	if iconos.size() >= 3:
		# Combinacion: A + B = resultado (Sofia ve "?" en los ingredientes, §1.5).
		var paso := icono.size.x / 3.4
		for k in 3:
			var p := c + Vector2((k - 1) * paso, 0)
			_dibujar_pictograma(icono, str(iconos[k]), p, r * 0.6)
		for k in 2:
			var p := c + Vector2((k - 0.5) * paso, 0)
			var signo := "+" if k == 0 else "="
			if _fuente != null:
				icono.draw_string(_fuente, p + Vector2(-8, 8), signo, HORIZONTAL_ALIGNMENT_CENTER, 16, 20, COLOR_CONTORNO)
	elif iconos.size() >= 2:
		_dibujar_pictograma(icono, str(iconos[0]), c + Vector2(-r * 0.62, -r * 0.1), r * 0.72)
		_dibujar_pictograma(icono, str(iconos[1]), c + Vector2(r * 0.62, r * 0.1), r * 0.72)
		icono.draw_line(c + Vector2(-r * 0.2, r * 0.75), c + Vector2(r * 0.35, r * 0.75), COLOR_CONTORNO, 3.0, true)
		icono.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.5, r * 0.75), c + Vector2(r * 0.3, r * 0.6), c + Vector2(r * 0.3, r * 0.9)]), COLOR_CONTORNO)
	elif iconos.size() == 1:
		_dibujar_pictograma(icono, str(iconos[0]), c, r)
	if objetivo["hecho"]:
		var estrella := Figura.poligono("estrella", icono.size - Vector2(18, 18), 14.0)
		icono.draw_colored_polygon(estrella, DORADO)
		Figura.contornear(icono, estrella, 2.5)
	elif int(objetivo["meta"]) > 1 and int(objetivo["meta"]) <= 12 and str(o.get("tipo", "")) != "encargo":
		# Cantidad como fila de puntitos (●●○), sin numeros (§1.5).
		var n := int(objetivo["meta"])
		var radio := minf(7.0, icono.size.x / (n * 2.6))
		var y := icono.size.y - 14.0
		for k in n:
			var p := Vector2(icono.size.x / 2.0 + (k - (n - 1) / 2.0) * radio * 2.6, y)
			icono.draw_circle(p, radio, DORADO if k < int(objetivo["actual"]) else Color.WHITE)
			icono.draw_arc(p, radio, 0, TAU, 14, COLOR_CONTORNO, 2.0, true)
	elif str(o.get("tipo", "")) == "encargo" and int(objetivo["meta"]) > 1:
		var t := float(objetivo["actual"]) / float(objetivo["meta"])
		var barra := Rect2(Vector2(icono.size.x * 0.2, icono.size.y - 16.0), Vector2(icono.size.x * 0.6, 8.0))
		icono.draw_rect(barra, Color.WHITE)
		icono.draw_rect(Rect2(barra.position, Vector2(barra.size.x * t, barra.size.y)), DORADO)
		icono.draw_rect(barra, COLOR_CONTORNO, false, 2.0)


## Pictogramas: un sticker del catalogo, un camino ("camino:<tipo>") o un simbolo (colores, pincel,
## encargo, circuito, dino).
func _dibujar_pictograma(icono: Control, id: String, c: Vector2, r: float) -> void:
	if id == "dino":
		id = "trex"
	if Stickers.tiene(id):
		Stickers.dibujar(icono, id, Stickers.color_por_defecto(id), c, r)
		return
	if id.begins_with("camino:"):
		_dibujar_icono_camino(icono, id.trim_prefix("camino:"), c, r / 34.0)
		return
	match id:
		"?":
			icono.draw_circle(c, r * 0.7, Color("#E9E4FF"))
			icono.draw_arc(c, r * 0.7, 0, TAU, 24, COLOR_CONTORNO, 3.0, true)
			if _fuente != null:
				icono.draw_string(_fuente, c + Vector2(-r, r * 0.35), "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.1), COLOR_CONTORNO)
		"colores":
			for j in 5:
				var p := c + Vector2.from_angle(-PI / 2.0 + j * TAU / 5.0) * r * 0.55
				icono.draw_circle(p, r * 0.3, Figura.COLORES_ARCOIRIS[j])
				icono.draw_arc(p, r * 0.3, 0.0, TAU, 12, COLOR_CONTORNO, 2.0, true)
		"circuito":
			icono.draw_arc(c, r * 0.8, 0, TAU, 32, COLOR_CONTORNO, r * 0.4, true)
			icono.draw_arc(c, r * 0.8, 0, TAU, 32, Color("#E8C88F"), r * 0.28, true)
			icono.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.8, -r * 0.3), c + Vector2(r * 1.1, r * 0.1), c + Vector2(r * 0.5, r * 0.1)]), COLOR_CONTORNO)
		_:
			# "encargo" y "pincel": un pincel con pintura y una estrellita.
			icono.draw_line(c + Vector2(r * 0.6, -r * 0.8), c + Vector2(-r * 0.1, r * 0.1), Color("#C98A4B"), r * 0.3, true)
			icono.draw_circle(c + Vector2(-r * 0.3, r * 0.35), r * 0.38, lienzo.color_actual)
			icono.draw_arc(c + Vector2(-r * 0.3, r * 0.35), r * 0.38, 0, TAU, 20, COLOR_CONTORNO, 2.5, true)
			Figura.dibujar(icono, "estrella", DORADO, c + Vector2(r * 0.6, r * 0.5), r * 0.32, false)


## Iconos de la barra de edicion: chico, grande, girar, espejo y borrar.
func _dibujar_accion(icono: Control) -> void:
	var boton := icono.get_parent() as Button
	var accion: String = boton.get_meta("accion", "")
	var c := icono.size / 2.0
	var k := icono.size.x / 64.0
	match accion:
		"achicar":
			Figura.dibujar(icono, "estrella", DORADO, c + Vector2(4, 4) * k, 11.0 * k, false)
			for dir in [Vector2(-1, -1), Vector2(1, -1)]:
				icono.draw_line(c + dir * 24.0 * k, c + dir * 14.0 * k, COLOR_CONTORNO, 3.5 * k, true)
		"agrandar":
			Figura.dibujar(icono, "estrella", DORADO, c, 24.0 * k, false)
		"girar":
			icono.draw_arc(c, 17.0 * k, -PI * 0.9, PI * 0.6, 20, COLOR_CONTORNO, 5.0 * k, true)
			var punta := c + Vector2.from_angle(PI * 0.6) * 17.0 * k
			icono.draw_colored_polygon(PackedVector2Array([punta + Vector2(-9, -2) * k, punta + Vector2(7, -8) * k, punta + Vector2(4, 9) * k]), COLOR_CONTORNO)
		"espejo":
			icono.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -16) * k, c + Vector2(-6, 16) * k, c + Vector2(-24, 0) * k]), TURQUESA)
			icono.draw_colored_polygon(PackedVector2Array([c + Vector2(6, -16) * k, c + Vector2(6, 16) * k, c + Vector2(24, 0) * k]), Color("#FF9FC8"))
			for y in [-20.0, -8.0, 4.0, 16.0]:
				icono.draw_line(c + Vector2(0, y) * k, c + Vector2(0, y + 7.0) * k, COLOR_CONTORNO, 3.0 * k)
		"borrar":
			var tacho := PackedVector2Array([c + Vector2(-14, -8) * k, c + Vector2(14, -8) * k, c + Vector2(10, 20) * k, c + Vector2(-10, 20) * k])
			icono.draw_colored_polygon(tacho, Color.WHITE)
			Figura.contornear(icono, tacho, 3.0 * k)
			icono.draw_line(c + Vector2(-18, -13) * k, c + Vector2(18, -13) * k, COLOR_CONTORNO, 4.0 * k, true)
			icono.draw_line(c + Vector2(-5, -18) * k, c + Vector2(5, -18) * k, COLOR_CONTORNO, 4.0 * k, true)
			for x in [-5.0, 0.0, 5.0]:
				icono.draw_line(c + Vector2(x, -2) * k, c + Vector2(x * 0.8, 14) * k, COLOR_CONTORNO, 2.0 * k, true)


func _dibujar_traje_mini(icono: Control, id: String) -> void:
	var lamina: Dictionary = _hojas[_indice_hoja]["lamina"] if _indice_hoja >= 0 else {}
	var trajes: Dictionary = lamina.get("trajes", {})
	if not trajes.has(id):
		return
	var mini := lamina.duplicate(true)
	mini.erase("trajes")
	var traje: Dictionary = trajes[id]
	mini["regiones"] = _regiones_con_traje(lamina, traje)
	mini["detalles"] = []
	var preparada := Laminas.preparar(mini)
	for region: Dictionary in preparada["regiones"]:
		if region.has("sugerido"):
			region["color"] = Color(str(region["sugerido"]))
	var caja := Rect2(250, 20, 330, 500)
	var datos_caja = lamina.get("caja_mini", null)
	if datos_caja is Array and datos_caja.size() == 4:
		caja = Rect2(float(datos_caja[0]), float(datos_caja[1]), float(datos_caja[2]), float(datos_caja[3]))
	var escala := minf((icono.size.x - 12.0) / caja.size.x, (icono.size.y - 12.0) / caja.size.y)
	var desfase := icono.size / 2.0 - caja.get_center() * escala
	Laminas.dibujar(icono, preparada, desfase, escala)


func _dibujar_icono_vaciar(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 66.0
	var gota := Figura.poligono("gota", c, 18.0 * k)
	icono.draw_colored_polygon(gota, Color("#8ED3FF"))
	Figura.contornear(icono, gota, 2.5 * k)
	icono.draw_arc(c + Vector2(0, 2) * k, 26.0 * k, -PI * 0.9, PI * 0.2, 20, COLOR_CONTORNO, 3.5 * k, true)
	var punta := c + Vector2.from_angle(PI * 0.2) * 26.0 * k
	icono.draw_colored_polygon(PackedVector2Array([punta + Vector2(-8, -4) * k, punta + Vector2(6, -6) * k, punta + Vector2(0, 8) * k]), COLOR_CONTORNO)
