class_name MotorEncajar
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "encajar" — "Formas traviesas" del Planeta Arcoiris
## (docs/fichas/motor-encajar.md, docs/fichas/planeta-arcoiris.md §2 y planeta-arcoiris-zonas.md §3.2).
##
## Piezas con forma se arrastran hasta su silueta. Agnostico de tema: todo llega en el nivel JSON.
## Cuatro MECANICAS (campo `mecanica`), todas con la misma bandeja, piezas y celebraciones:
## - `huecos` (por defecto): una FIGURA agrupa HUECOS; una pieza calza si su forma, tamano, giro y
##   espejo coinciden (comparacion de areas, geometria_formas.gd). Cubre formas sueltas (Maxi y
##   Nicole), figuras compuestas, la escena de Nicole y siluetas unidas.
## - `tangram_libre` (Sofia, v3): la silueta se llena con CUALQUIER solucion valida. La pieza soltada
##   se ajusta a la red del tangram (lado `lado_red`) y vale si queda dentro de la silueta sin pisar
##   otras. Las piezas puestas se pueden volver a tomar.
## - `memoria` (Sofia, v3): se ve el modelo a color unos segundos, Coco lo tapa y hay que copiarlo
##   de memoria: cada pieza a su lugar exacto (`exigir_color`). Mirar de nuevo cuesta una estrellita.
## - `marco` (Sofia, v3): rellenar un marco de cuadraditos con pentominos (Katamino); sobran piezas.
##
## `pruebas` encadena varias partidas en un solo nivel (desafio de la Cima). Cada prueba sobrescribe
## campos del nivel. Pistas que cuestan estrellita (`pistas_cuestan_estrellita`), boton espejo
## (`boton_espejo`), regalo de una pieza tras 2 derrotas (`regalo_tras_derrotas`) y avance guardado
## pieza a pieza (`guardar_avance`, reto dorado).
##
## Reglas por perfil (GDD §5), activadas por campos del nivel y no por el nombre del perfil:
## `sin_error` (Semilla: soltar mal nunca es "no"), `toque_lleva_a_casa`, `ayuda_idle_s`,
## `objetivo_guiado` (Brote: un objetivo a la vez), `enderezar_al_acercar`, `rotacion_por_toque`,
## `limite_intentos` (derrota-gag + estrellitas), `piezas_distractoras`, `guia_color`, `caras`.
##
## F3 (solo PC) muestra un panel de depuracion para el PO.

signal pieza_encajada(id_hueco: String)
signal intento_fallido()
signal figura_completada(id_figura: String)
signal nivel_fallado()
signal prueba_completada(indice: int)

const Geo := preload("res://scripts/motores/encajar/geometria_formas.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
## Zonas de la pantalla base 1280x720: a la izquierda Coco, arriba la barra de progreso, a la
## derecha la bandeja de piezas y abajo a la derecha Cometa. Un nivel puede cambiarlas
## (`zona_figuras`, `zona_bandeja`: [x, y, ancho, alto]).
const ZONA_FIGURAS := Rect2(236, 118, 640, 590)
const ZONA_BANDEJA := Rect2(894, 124, 366, 440)
const SEPARACION_MAXIMA := 90.0
const RELLENO_BANDEJA := 16.0
const ESCALA_ARRASTRE := 1.06
const DESTELLOS_POR_PIEZA := 10
const DESTELLOS_POR_INTENTO_SOBRANTE := 2
const SEGUNDOS_PISTA := 1.8
## Tangram libre: area que una pieza puede quedar fuera de la silueta o encima de otra (fraccion).
const TOLERANCIA_LIBRE := 0.05
## Tangram libre: fraccion de la silueta que debe quedar cubierta para ganar.
const COBERTURA_MINIMA := 0.97
const SEGUNDOS_VISTAZO := 2.0
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_TOMAR := "sfx/ui/seleccionar.ogg"
const SFX_SOLTAR := "sfx/ui/soltar.ogg"
const SFX_ENCAJE := "sfx/ui/confirmar.ogg"
const SFX_NO_ES_ESTE := "sfx/ui/no_es_este.ogg"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_GAG := "sfx/ui/abrir.ogg"
const SFX_GIRO := "sfx/ui/cerrar.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")

@onready var _siluetas: Control = %siluetas
@onready var _bandeja: Panel = %bandeja
@onready var _tablero: Control = %tablero
@onready var _efectos: Control = %efectos
@onready var _barra_progreso: PanelContainer = %barra_progreso
@onready var _progreso_piezas: HBoxContainer = %progreso_piezas
@onready var _anfitriona: TextureRect = %anfitriona
@onready var _boton_otra_vez: Button = %boton_otra_vez
@onready var _confeti: CPUParticles2D = %confeti
@onready var _boton_cometa: Button = %boton_cometa
@onready var _boton_salir: Button = %boton_salir
@onready var _panel_depuracion: Label = %panel_depuracion

var _figuras: Array = []
var _huecos: Array = []
var _piezas: Array[PiezaEncajar] = []
var _ranuras: Array = []
var _arrastrando := {}

## Configuracion vigente: el nivel con los campos de la prueba actual encima.
var _cfg: Dictionary = {}
var _pruebas: Array = []
var _indice_prueba := 0
var _mecanica := "huecos"
var _zona_figuras := ZONA_FIGURAS
var _zona_bandeja := ZONA_BANDEJA

var _requeridos := 0
var _encajados := 0
var _intentos_usados := 0
var _limite_intentos = null  ## null = sin limite
var _derrota_disparada := false
var _derrotas := 0
var _regalo_dado := false
var _en_gag := false
var _terminado := false
var _pistas_usadas := 0
var _destellos_pruebas := 0

var _iman := 120.0
var _sin_error := false
var _rotacion_por_toque := false
var _paso_rotacion := 90.0
var _enderezar := false
var _toque_lleva_a_casa := false
var _ayuda_idle := 0.0
var _objetivo_guiado := false
var _risa := false
var _caras := true
var _lado_minimo_bandeja := 0.0
var _exigir_color := false
var _boton_espejo_activo := false

## Tangram libre: red del tangram y piezas puestas (pieza -> poligono en pantalla).
var _lado_red := 0.0
var _origen_red := Vector2.ZERO
var _libres := {}
var _area_silueta := 0.0
## Marco: {"origen", "lado", "celdas": {Vector2i: true}, "lista": Array, "ocupadas": {Vector2i: pieza}}.
var _marco: Dictionary = {}
var _celdas_de := {}
## Memoria: mientras se ve el modelo no se puede arrastrar.
var _en_modelo := false

var _objetivo = null
var _inactivo := 0.0
var _pistas_dadas := 0
var _ultima_linea := ""
var _id_voz_diferida := 0
var _pieza_elegida: PiezaEncajar = null

var _boton_pista: Button
var _boton_espejo: Button
var _boton_ojo: Button

var _tiempo := 0.0
var _base_anfitriona := Vector2.ZERO
var _salto_anfitriona := 0.0
var _tween_anfitriona: Tween


func _ready() -> void:
	super._ready()
	_boton_otra_vez.hide()
	_panel_depuracion.hide()
	_estilizar_interfaz()
	_crear_botones_sofia()
	_boton_otra_vez.pressed.connect(_reintentar)
	_boton_cometa.pressed.connect(_al_tocar_cometa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_anfitriona.mouse_filter = Control.MOUSE_FILTER_STOP
	_anfitriona.gui_input.connect(_al_tocar_anfitriona)
	_anfitriona.pivot_offset = Vector2(_anfitriona.size.x / 2.0, _anfitriona.size.y)
	_base_anfitriona = _anfitriona.position
	if nivel.is_empty():
		push_error("motor_encajar: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_pruebas = nivel.get("pruebas", [])
	_iniciar_prueba()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	var bamboleo := absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0
	_anfitriona.position.y = _base_anfitriona.y - _salto_anfitriona - bamboleo
	if _ayuda_idle > 0.0 and not _terminado and not _en_gag and _arrastrando.is_empty():
		_inactivo += delta
		if _inactivo >= _ayuda_idle:
			_inactivo = 0.0
			_dar_pista()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Construccion del nivel (y de cada prueba)
# ---------------------------------------------------------------------------

func _iniciar_prueba() -> void:
	_cfg = nivel.duplicate()
	_cfg.erase("pruebas")
	if _indice_prueba < _pruebas.size():
		var prueba: Dictionary = _pruebas[_indice_prueba]
		for clave in prueba:
			if clave == "lineas_voz":
				var voces: Dictionary = nivel.get("lineas_voz", {}).duplicate()
				voces.merge(prueba["lineas_voz"], true)
				_cfg["lineas_voz"] = voces
			else:
				_cfg[clave] = prueba[clave]
	_configurar_desde_nivel()
	if _mecanica == "marco":
		_construir_marco()
	else:
		_construir_figuras()
		_construir_piezas()
	_construir_progreso()
	_siluetas.figuras = _figuras
	_siluetas.guia_color = bool(_cfg.get("guia_color", false))
	_siluetas.zona = _zona_figuras
	_siluetas.escena = _cfg.get("escena", {})
	_siluetas.queue_redraw()
	_actualizar_botones()
	var intro := _linea("intro")
	_reproducir_voz("intro", intro)
	if _objetivo_guiado:
		_elegir_objetivo()
		_voz_diferida("objetivo", _ruta_voz_objetivo(), _duracion_voz(intro) + 0.4)
	if _mecanica == "memoria":
		_mostrar_modelo(float(_cfg.get("segundos_modelo", 6.0)), _duracion_voz(intro) + 0.2)
	if bool(_cfg.get("guardar_avance", false)):
		_restaurar_avance()
	_actualizar_depuracion()


func _configurar_desde_nivel() -> void:
	var perfil := obtener_perfil_dificultad()
	_mecanica = str(_cfg.get("mecanica", "huecos"))
	_iman = float(_cfg.get("iman_tolerancia_px", 120.0))
	_sin_error = bool(_cfg.get("sin_error", perfil == "semilla"))
	var limite = _cfg.get("limite_intentos", null)
	_limite_intentos = int(limite) if limite != null and not _sin_error else null
	_rotacion_por_toque = bool(_cfg.get("rotacion_por_toque", false))
	_paso_rotacion = float(_cfg.get("paso_rotacion", 90.0))
	_enderezar = bool(_cfg.get("enderezar_al_acercar", false))
	_toque_lleva_a_casa = bool(_cfg.get("toque_lleva_a_casa", false))
	_ayuda_idle = float(_cfg.get("ayuda_idle_s", 0.0))
	_objetivo_guiado = bool(_cfg.get("objetivo_guiado", false))
	_risa = bool(_cfg.get("risa_al_encajar", false))
	_caras = bool(_cfg.get("caras", true))
	_lado_minimo_bandeja = float(_cfg.get("lado_minimo_bandeja", {"semilla": 96.0, "brote": 56.0}.get(perfil, 0.0)))
	_exigir_color = bool(_cfg.get("exigir_color", _mecanica == "memoria"))
	_boton_espejo_activo = bool(_cfg.get("boton_espejo", false))
	_lado_red = float(_cfg.get("lado_red", 0.0))
	_zona_figuras = _rect_de(_cfg.get("zona_figuras", null), ZONA_FIGURAS)
	_zona_bandeja = _rect_de(_cfg.get("zona_bandeja", null), ZONA_BANDEJA)
	_bandeja.position = _zona_bandeja.position
	_bandeja.size = _zona_bandeja.size


func _rect_de(valor, por_defecto: Rect2) -> Rect2:
	if valor is Array and valor.size() == 4:
		return Rect2(float(valor[0]), float(valor[1]), float(valor[2]), float(valor[3]))
	return por_defecto


## Con `lado_red`, las medidas y posiciones de las piezas vienen en unidades de la red del tangram.
func _escalar(datos: Dictionary) -> Dictionary:
	if _lado_red <= 0.0:
		return datos
	var copia := datos.duplicate(true)
	for pieza: Dictionary in copia.get("piezas", []):
		for campo in ["ancho", "alto", "x", "y"]:
			if pieza.has(campo):
				pieza[campo] = float(pieza[campo]) * _lado_red
	for campo in ["ancho", "alto"]:
		if copia.has(campo):
			copia[campo] = float(copia[campo]) * _lado_red
	return copia


func _construir_figuras() -> void:
	var pool: Array = []
	for datos in _cfg.get("figuras", []):
		pool.append(_escalar(datos))
	var hay_escena: bool = not _cfg.get("escena", {}).is_empty()
	if not hay_escena:
		pool.shuffle()
	var por_partida = _cfg.get("figuras_por_partida", null)
	if por_partida != null:
		pool = pool.slice(0, int(por_partida))

	var medidas: Array = []
	for datos: Dictionary in pool:
		var caja := Rect2()
		var primero := true
		for pieza: Dictionary in datos.get("piezas", []):
			var local := Geo.transformado(_contorno_de(pieza), float(pieza.get("rotacion", 0.0)), Vector2(float(pieza.get("x", 0)), float(pieza.get("y", 0))))
			var caja_pieza := Geo.caja(local)
			caja = caja_pieza if primero else caja.merge(caja_pieza)
			primero = false
		medidas.append(caja)

	var origenes: Array = []
	if hay_escena:
		for datos: Dictionary in pool:
			var centro: Array = datos.get("centro", [0, 0])
			origenes.append(_zona_figuras.position + Vector2(float(centro[0]), float(centro[1])))
	else:
		origenes = _repartir_figuras(medidas)
	if not origenes.is_empty():
		# La red del tangram tiene su origen en el origen de la (unica) figura: se redondea al pixel.
		origenes[0] = (origenes[0] as Vector2).round()
		_origen_red = origenes[0]

	for i in pool.size():
		var datos: Dictionary = pool[i]
		var figura := {
			"id": str(datos.get("id", "figura_%d" % i)),
			"huecos": [],
			"silueta_unida": bool(datos.get("silueta_unida", false)),
			"union": [],
			"voz_completa": str(datos.get("voz_completa", "")),
			"especial": bool(datos.get("especial", false)),
			"completa": false,
		}
		var poligonos: Array = []
		var indice := 0
		for pieza: Dictionary in datos.get("piezas", []):
			var base := _contorno_de(pieza)
			var forma := str(pieza.get("forma", "circulo"))
			var ancho := float(pieza.get("ancho", 100.0))
			var alto := float(pieza.get("alto", ancho))
			var grados := float(pieza.get("rotacion", 0.0))
			var centro: Vector2 = origenes[i] + Vector2(float(pieza.get("x", 0)), float(pieza.get("y", 0)))
			var redondeado := Geo.redondeado(forma, Geo.contorno(forma, ancho, alto), ancho, alto)
			if bool(pieza.get("espejo", false)):
				redondeado = Geo.espejado(redondeado)
			var hueco := {
				"id": "%s_%d" % [figura["id"], indice],
				"figura": _figuras.size(),
				"forma": forma,
				"ancho": ancho,
				"alto": alto,
				"rotacion": grados,
				"espejo": bool(pieza.get("espejo", false)),
				"centro": centro,
				"color": Color(str(pieza.get("color", "#FFCB3D"))),
				"decoracion": str(pieza.get("decoracion", "")),
				"cara": bool(pieza.get("cara", false)),
				"opcional": bool(pieza.get("opcional", false)),
				"especial": bool(pieza.get("especial", false)),
				"nombre_voz": str(pieza.get("nombre_voz", forma)),
				"forma_centrada": Geo.transformado(base, grados),
				"poligono": Geo.transformado(base, grados, centro),
				"dibujo": Geo.transformado(redondeado, grados, centro),
				"pieza": null,
			}
			indice += 1
			figura["huecos"].append(hueco)
			_huecos.append(hueco)
			if not hueco["opcional"]:
				_requeridos += 1
				poligonos.append(hueco["poligono"])
				_area_silueta += absf(Geo.area(hueco["poligono"]))
		if figura["silueta_unida"]:
			figura["union"] = Geo.unir(poligonos)
		_figuras.append(figura)


func _contorno_de(pieza: Dictionary) -> PackedVector2Array:
	var ancho := float(pieza.get("ancho", 100.0))
	var base := Geo.contorno(str(pieza.get("forma", "circulo")), ancho, float(pieza.get("alto", ancho)))
	return Geo.espejado(base) if bool(pieza.get("espejo", false)) else base


## Reparte las figuras en filas dentro de la zona (probando 1 fila, 2, 3...) y devuelve el origen
## de cada figura para que su caja quede centrada en su celda.
func _repartir_figuras(cajas: Array) -> Array:
	var n := cajas.size()
	var origenes: Array = []
	origenes.resize(n)
	for filas in range(1, n + 1):
		var por_fila := ceili(n / float(filas))
		var grupos: Array = []
		for inicio in range(0, n, por_fila):
			grupos.append(range(inicio, mini(inicio + por_fila, n)))
		var alto_total := 0.0
		var cabe := true
		for grupo in grupos:
			var ancho_fila := 0.0
			var alto_fila := 0.0
			for j in grupo:
				ancho_fila += (cajas[j] as Rect2).size.x
				alto_fila = maxf(alto_fila, (cajas[j] as Rect2).size.y)
			cabe = cabe and ancho_fila + 24.0 * (grupo.size() - 1) <= _zona_figuras.size.x
			alto_total += alto_fila
		cabe = cabe and alto_total + 24.0 * (grupos.size() - 1) <= _zona_figuras.size.y
		if not cabe and filas < n:
			continue
		var hueco_vertical := minf((_zona_figuras.size.y - alto_total) / (grupos.size() + 1), SEPARACION_MAXIMA)
		var y := _zona_figuras.position.y + (_zona_figuras.size.y - alto_total - hueco_vertical * (grupos.size() - 1)) / 2.0
		for grupo in grupos:
			var ancho_fila := 0.0
			var alto_fila := 0.0
			for j in grupo:
				ancho_fila += (cajas[j] as Rect2).size.x
				alto_fila = maxf(alto_fila, (cajas[j] as Rect2).size.y)
			var hueco_horizontal := minf((_zona_figuras.size.x - ancho_fila) / (grupo.size() + 1), SEPARACION_MAXIMA)
			var x: float = _zona_figuras.position.x + (_zona_figuras.size.x - ancho_fila - hueco_horizontal * (grupo.size() - 1)) / 2.0
			for j in grupo:
				var caja: Rect2 = cajas[j]
				var centro_celda := Vector2(x + caja.size.x / 2.0, y + alto_fila / 2.0)
				origenes[j] = centro_celda - caja.get_center()
				x += caja.size.x + hueco_horizontal
			y += alto_fila + hueco_vertical
		break
	return origenes


func _construir_piezas() -> void:
	var lista: Array = []
	for hueco in _huecos:
		var volteada: bool = hueco["espejo"]
		if _boton_espejo_activo:
			# Con boton espejo, la pieza llega sin voltear: si su lugar la pide volteada, hay que darla vuelta.
			volteada = false
		lista.append({"datos": {
			"id": "pieza_" + hueco["id"], "forma": hueco["forma"], "ancho": hueco["ancho"], "alto": hueco["alto"],
			"color": "#" + (hueco["color"] as Color).to_html(false), "decoracion": hueco["decoracion"],
			"especial": hueco["especial"], "volteada": volteada}, "hueco": hueco})
	var distractoras: Array = _cfg.get("piezas_distractoras", []).duplicate()
	distractoras.shuffle()
	var cuantas = _cfg.get("distractoras_por_partida", null)
	if cuantas != null:
		distractoras = distractoras.slice(0, int(cuantas))
	for i in distractoras.size():
		var datos: Dictionary = _escalar(distractoras[i] as Dictionary)
		datos["id"] = "distractora_%d" % i
		lista.append({"datos": datos, "hueco": null})
	lista.shuffle()

	for entrada in lista:
		var pieza := PiezaEncajar.new()
		_tablero.add_child(pieza)
		pieza.configurar(entrada["datos"])
		var hueco = entrada["hueco"]
		pieza.cara_siempre = _caras
		pieza.cara_al_completar = hueco != null and hueco["cara"]
		var grados := float(hueco["rotacion"]) if hueco != null else float(entrada["datos"].get("rotacion", 0.0))
		if _enderezar:
			grados = 0.0
		elif _rotacion_por_toque and bool(_cfg.get("rotacion_inicial_aleatoria", true)):
			grados = _rotacion_desordenada(pieza, hueco)
		pieza.rotacion_grados = wrapf(grados, 0.0, 360.0)
		pieza.rotation = deg_to_rad(pieza.rotacion_grados)
		_conectar_pieza(pieza)
	_acomodar_bandeja()


func _conectar_pieza(pieza: PiezaEncajar) -> void:
	pieza.tomada.connect(_al_tomar)
	pieza.movida.connect(_al_mover)
	pieza.soltada.connect(_al_soltar)
	pieza.tocada.connect(_al_tocar_pieza)
	_piezas.append(pieza)


## Marco de pentominos: tablero de cuadraditos centrado en la zona y una pieza por pentomino.
func _construir_marco() -> void:
	var filas: Array = _cfg.get("marco", [])
	var lado := float(_cfg.get("lado_celda", 64.0))
	var celdas := {}
	var lista: Array = []
	var columnas := 0
	for f in filas.size():
		var fila := str(filas[f])
		columnas = maxi(columnas, fila.length())
		for c in fila.length():
			if fila[c] == "#":
				celdas[Vector2i(c, f)] = true
				lista.append(Vector2i(c, f))
	var medida := Vector2(columnas, filas.size()) * lado
	var origen := (_zona_figuras.get_center() - medida / 2.0).round()
	_marco = {"origen": origen, "lado": lado, "celdas": celdas, "lista": lista, "ocupadas": {}, "medida": medida}
	_siluetas.marco = {"origen": origen, "lado": lado, "celdas": lista}
	_requeridos = int(_cfg.get("piezas_necesarias", ceili(lista.size() / 5.0)))
	for datos: Dictionary in _cfg.get("piezas_marco", []):
		var pieza := PiezaEncajar.new()
		_tablero.add_child(pieza)
		pieza.configurar({"id": str(datos.get("id", "")), "celdas": datos.get("celdas", []), "lado": lado,
			"color": str(datos.get("color", "#FFCB3D")), "volteada": _boton_espejo_activo and randi() % 2 == 0})
		pieza.cara_siempre = false
		pieza.rotacion_grados = float(randi() % 4) * 90.0
		pieza.rotation = deg_to_rad(pieza.rotacion_grados)
		_conectar_pieza(pieza)
	_piezas.shuffle()
	_acomodar_bandeja()


## Un giro al azar (multiplo del paso) con el que la pieza todavia NO calza en su hueco.
func _rotacion_desordenada(pieza: PiezaEncajar, hueco) -> float:
	var pasos := int(round(360.0 / _paso_rotacion))
	var opciones: Array = []
	for k in pasos:
		var grados := k * _paso_rotacion
		if hueco == null or not Geo.calzan(pieza.poligono(grados), hueco["forma_centrada"]):
			opciones.append(grados)
	if opciones.is_empty():
		return float(hueco["rotacion"]) if hueco != null else 0.0
	return opciones[randi() % opciones.size()]


## Acomoda las piezas en la bandeja en filas, achicandolas lo minimo necesario para que quepan
## todas (mismo factor para todas: se conservan los tamanos relativos, clave en "grande y chico").
func _acomodar_bandeja() -> void:
	var ordenes: Array = [_piezas.duplicate()]
	var por_alto := _piezas.duplicate()
	por_alto.sort_custom(func(a: PiezaEncajar, b: PiezaEncajar) -> bool: return _medida_bandeja(a).y > _medida_bandeja(b).y)
	ordenes.append(por_alto)
	var mejor: Dictionary = {}
	for orden in ordenes:
		var factor := 1.0
		while factor >= 0.3:
			var ubicacion := _empacar(orden, factor)
			if not ubicacion.is_empty():
				if mejor.is_empty() or factor > mejor["factor"] + 0.001:
					mejor = {"factor": factor, "centros": ubicacion, "orden": orden}
				break
			factor -= 0.04
	if mejor.is_empty():
		mejor = {"factor": 0.3, "centros": _empacar(ordenes[1], 0.3, true), "orden": ordenes[1]}
	var orden: Array = mejor["orden"]
	for i in orden.size():
		var pieza: PiezaEncajar = orden[i]
		pieza.escala_bandeja = _escala_en_bandeja(pieza, mejor["factor"])
		pieza.casa = mejor["centros"][i]
		pieza.fijar_centro(pieza.casa)
		pieza.aparecer(0.2 + i * 0.05)


func _medida_bandeja(pieza: PiezaEncajar, factor := 1.0) -> Vector2:
	return (Geo.caja(pieza.poligono()).size + Vector2(12, 12)) * _escala_en_bandeja(pieza, factor)


## Escala de una pieza en la bandeja: el factor comun, pero sin que su lado mas corto quede bajo
## `lado_minimo_bandeja` (Maxi 96 px, Nicole 56 px) y nunca mas grande que su tamano real.
func _escala_en_bandeja(pieza: PiezaEncajar, factor: float) -> float:
	var caja := Geo.caja(pieza.poligono()).size
	var lado := maxf(1.0, minf(caja.x, caja.y))
	return minf(1.0, maxf(factor, _lado_minimo_bandeja / lado))


## Empaca en filas. Devuelve los centros (mismo orden) o [] si no cabe con ese factor.
func _empacar(orden: Array, factor: float, forzar := false) -> Array:
	var ancho_util := _zona_bandeja.size.x - RELLENO_BANDEJA * 2.0
	var alto_util := _zona_bandeja.size.y - RELLENO_BANDEJA * 2.0
	var filas: Array = [[]]
	var ancho_fila := 0.0
	for i in orden.size():
		var medida := _medida_bandeja(orden[i], factor)
		if medida.x > ancho_util and not forzar:
			return []
		if ancho_fila + medida.x > ancho_util and not filas[-1].is_empty():
			filas.append([])
			ancho_fila = 0.0
		filas[-1].append(i)
		ancho_fila += medida.x + RELLENO_BANDEJA
	var alto_total := 0.0
	var altos: Array = []
	for fila in filas:
		var alto := 0.0
		for i in fila:
			alto = maxf(alto, _medida_bandeja(orden[i], factor).y)
		altos.append(alto)
		alto_total += alto
	alto_total += RELLENO_BANDEJA * (filas.size() - 1)
	if alto_total > alto_util and not forzar:
		return []
	var centros: Array = []
	centros.resize(orden.size())
	var y := _zona_bandeja.position.y + (_zona_bandeja.size.y - alto_total) / 2.0
	for f in filas.size():
		var total := -RELLENO_BANDEJA
		for i in filas[f]:
			total += _medida_bandeja(orden[i], factor).x + RELLENO_BANDEJA
		var x := _zona_bandeja.position.x + (_zona_bandeja.size.x - total) / 2.0
		for i in filas[f]:
			var medida := _medida_bandeja(orden[i], factor)
			centros[i] = Vector2(x + medida.x / 2.0, y + altos[f] / 2.0)
			x += medida.x + RELLENO_BANDEJA
		y += altos[f] + RELLENO_BANDEJA
	return centros


## Una ranura por pieza que hace falta: se llena con la forma encajada. Muestra cuanto falta sin numeros.
func _construir_progreso() -> void:
	var lado := 64.0 if _requeridos <= 6 else 52.0
	for i in _requeridos:
		var ranura := Control.new()
		ranura.custom_minimum_size = Vector2.ONE * lado
		ranura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ranura.draw.connect(_dibujar_ranura.bind(ranura))
		_progreso_piezas.add_child(ranura)
		_ranuras.append(ranura)


func _dibujar_ranura(ranura: Control) -> void:
	var centro := ranura.size / 2.0
	var radio := ranura.size.x * 0.46
	var pieza = ranura.get_meta("lleno") if ranura.has_meta("lleno") else null
	if pieza == null or not is_instance_valid(pieza):
		ranura.draw_circle(centro, radio, Color(1, 1, 1, 0.22))
		ranura.draw_arc(centro, radio, 0.0, TAU, 32, Color(1, 1, 1, 0.75), 3.0, true)
		return
	ranura.draw_circle(centro, radio, Color("#FFF8EE"))
	ranura.draw_arc(centro, radio, 0.0, TAU, 32, COLOR_CONTORNO, 3.5, true)
	var forma: PackedVector2Array = pieza.poligono()
	var caja := Geo.caja(forma)
	var escala := radio * 1.25 / maxf(caja.size.x, caja.size.y)
	var mini := PackedVector2Array()
	for p in forma:
		mini.append(centro + (p - caja.get_center()) * escala)
	Geo.pintar(ranura, mini, pieza.color, radio * 0.6)


# ---------------------------------------------------------------------------
# Interaccion
# ---------------------------------------------------------------------------

func _al_tomar(pieza: PiezaEncajar) -> void:
	_inactivo = 0.0
	if _terminado or _en_gag or _en_modelo:
		return
	_elegir(pieza)
	if pieza.colocada and _mecanica in ["tangram_libre", "marco"]:
		_quitar_colocada(pieza)
	_tablero.move_child(pieza, -1)
	reproducir_sfx(SFX_TOMAR)
	pieza.pulso()


func _al_mover(pieza: PiezaEncajar, punto: Vector2) -> void:
	if pieza.bloqueada or _terminado or _en_gag or _en_modelo:
		return
	_inactivo = 0.0
	if not _arrastrando.has(pieza):
		_arrastrando[pieza] = true
		pieza.agrandar(ESCALA_ARRASTRE)
		_siluetas.hueco_pista = null
	pieza.fijar_centro(punto)
	if _enderezar:
		var destino := 0.0
		for hueco in _candidatos(punto):
			if _calza(pieza, hueco):
				destino = hueco["rotacion"]
				break
		if not is_equal_approx(wrapf(destino, 0.0, 360.0), pieza.rotacion_grados):
			pieza.girar_a(destino, 0.18)
	# Resaltar el hueco cercano ayuda a Maxi y Nicole; a Sofia no se le regala la respuesta.
	if obtener_perfil_dificultad() != "estrella":
		var cercanos := _candidatos(punto)
		var nuevo = cercanos[0] if not cercanos.is_empty() else null
		if nuevo != _siluetas.hueco_cercano:
			_siluetas.hueco_cercano = nuevo
			_siluetas.queue_redraw()


func _al_soltar(pieza: PiezaEncajar, _punto: Vector2) -> void:
	_arrastrando.erase(pieza)
	_siluetas.hueco_cercano = null
	_siluetas.queue_redraw()
	if pieza.bloqueada or _terminado or _en_gag or _en_modelo:
		return
	soltar_pieza(pieza, pieza.centro_global())


## Resuelve una pieza soltada en `punto`. Devuelve "encajo" | "nada" | "rebote" | "girar" | "no_es_este".
## Publica para los arneses QA (misma ruta que un dedo real).
func soltar_pieza(pieza: PiezaEncajar, punto: Vector2) -> String:
	_inactivo = 0.0
	if pieza.colocada and _mecanica in ["tangram_libre", "marco"]:
		_quitar_colocada(pieza)
	match _mecanica:
		"tangram_libre":
			return _soltar_libre(pieza, punto)
		"marco":
			return _soltar_marco(pieza, punto)
	var candidatos := _candidatos(punto)
	if candidatos.is_empty():
		reproducir_sfx(SFX_SOLTAR)
		pieza.volver_a_casa()
		return "nada"
	for hueco in candidatos:
		if _calza(pieza, hueco):
			_encajar(pieza, hueco)
			return "encajo"
	if _sin_error:
		# Semilla: nunca un "no". La pieza vuelve saltando y su casita correcta brilla un momento.
		reproducir_sfx(SFX_SOLTAR)
		pieza.volver_a_casa()
		_mostrar_pista(pieza, _hueco_para(pieza))
		return "rebote"
	var solo_giro := false
	if _rotacion_por_toque:
		for hueco in candidatos:
			solo_giro = solo_giro or _calza_girando(pieza, hueco)
	return _fallar(pieza, solo_giro)


## "No es este": cuenta intento (si hay limite), voz amistosa, la pieza vuelve y puede venir la derrota-gag.
func _fallar(pieza: PiezaEncajar, solo_giro := false) -> String:
	if _limite_intentos != null:
		_intentos_usados += 1
	intento_fallido.emit()
	reproducir_sfx(SFX_NO_ES_ESTE)
	if solo_giro and _linea("girar") != "":
		_reproducir_voz("girar", _linea("girar"))
	else:
		_reproducir_voz("no_es_este", _linea_al_azar("no_es_este"))
	pieza.volver_a_casa(true)
	_reaccion_anfitriona("menea")
	if _limite_intentos != null and _intentos_usados >= int(_limite_intentos):
		_disparar_derrota_gag()
	_actualizar_depuracion()
	return "girar" if solo_giro else "no_es_este"


func _al_tocar_pieza(pieza: PiezaEncajar) -> void:
	_inactivo = 0.0
	if _terminado or _en_gag or _en_modelo:
		return
	if pieza.colocada and _mecanica in ["tangram_libre", "marco"]:
		# Una pieza puesta en el tablero solo da un saltito: para girarla hay que sacarla primero.
		reproducir_sfx(SFX_TOQUE)
		pieza.saltito(12.0)
		return
	if pieza.bloqueada:
		return
	_elegir(pieza)
	if _arrastrando.has(pieza):
		_arrastrando.erase(pieza)
	if _rotacion_por_toque:
		reproducir_sfx(SFX_GIRO)
		pieza.girar_a(pieza.rotacion_grados + _paso_rotacion)
		pieza.volver_a_casa()
		_actualizar_depuracion()
		return
	if _toque_lleva_a_casa:
		var hueco = _hueco_para(pieza)
		if hueco != null:
			_encajar(pieza, hueco)
			return
	reproducir_sfx(SFX_TOQUE)
	pieza.volver_a_casa()
	pieza.saltito(16.0)


func _elegir(pieza: PiezaEncajar) -> void:
	if not _boton_espejo_activo:
		return
	if _pieza_elegida != null and is_instance_valid(_pieza_elegida) and _pieza_elegida != pieza:
		_pieza_elegida.elegida = false
	_pieza_elegida = pieza
	pieza.elegida = true


## Huecos libres a distancia de iman de `punto`, del mas cercano al mas lejano.
func _candidatos(punto: Vector2) -> Array:
	var lista: Array = []
	for hueco in _huecos:
		if hueco["pieza"] != null:
			continue
		var distancia := Geo.distancia(punto, hueco["poligono"])
		if distancia <= _iman:
			lista.append([distancia, punto.distance_to(hueco["centro"]), hueco])
	lista.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (is_equal_approx(a[0], b[0]) and a[1] < b[1]))
	return lista.map(func(entrada: Array): return entrada[2])


func _calza(pieza: PiezaEncajar, hueco: Dictionary) -> bool:
	if _exigir_color and not pieza.color.is_equal_approx(hueco["color"]):
		return false
	var grados := float(hueco["rotacion"]) if _enderezar else pieza.rotacion_grados
	return Geo.calzan(pieza.poligono(grados), hueco["forma_centrada"])


func _calza_girando(pieza: PiezaEncajar, hueco: Dictionary) -> bool:
	if _exigir_color and not pieza.color.is_equal_approx(hueco["color"]):
		return false
	var pasos := int(round(360.0 / _paso_rotacion))
	for k in pasos:
		if Geo.calzan(pieza.poligono(k * _paso_rotacion), hueco["forma_centrada"]):
			return true
	return false


## Hueco libre (no opcional primero) donde esta pieza calza tal como esta girada, el mas cercano.
func _hueco_para(pieza: PiezaEncajar):
	var mejor = null
	var mejor_distancia := INF
	for hueco in _huecos:
		if hueco["pieza"] != null or not _calza(pieza, hueco):
			continue
		var distancia: float = pieza.centro_global().distance_to(hueco["centro"]) + (100000.0 if hueco["opcional"] else 0.0)
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = hueco
	return mejor


func _encajar(pieza: PiezaEncajar, hueco: Dictionary) -> void:
	_arrastrando.erase(pieza)
	hueco["pieza"] = pieza
	pieza.hueco = hueco
	pieza.elegida = false
	pieza.encajar_en(hueco["centro"], hueco["rotacion"])
	reproducir_sfx(SFX_ENCAJE)
	_estallido(hueco["centro"], 8, [pieza.color, DORADO])
	pieza_encajada.emit(hueco["id"])
	if _siluetas.hueco_pista == hueco:
		_siluetas.hueco_pista = null
	_siluetas.queue_redraw()
	if hueco["opcional"]:
		_celebrar_tesoro(pieza)
		return
	_encajados += 1
	_llenar_ranura(pieza)
	_reaccion_anfitriona("salta")
	var figura: Dictionary = _figuras[hueco["figura"]]
	var completa := true
	for otro in figura["huecos"]:
		completa = completa and (otro["opcional"] or otro["pieza"] != null)
	if _risa:
		_despues(0.5, pieza.reir)
	var voz_figura := ""
	if completa and not figura["completa"]:
		voz_figura = _completar_figura(figura)
	if _encajados >= _requeridos:
		_completar_prueba(voz_figura)
		_actualizar_depuracion()
		return
	var ruta_dicha := ""
	if voz_figura != "":
		ruta_dicha = voz_figura
		_reproducir_voz("figura_completa", voz_figura)
	elif _risa and _linea("risa") != "":
		ruta_dicha = _linea_al_azar("risa")
		_reproducir_voz("risa", ruta_dicha)
	else:
		ruta_dicha = _linea_al_azar("acierto")
		_reproducir_voz("acierto", ruta_dicha)
	if _objetivo_guiado and (_objetivo == null or _objetivo["pieza"] != null):
		_elegir_objetivo()
		_voz_diferida("objetivo", _ruta_voz_objetivo(), _duracion_voz(ruta_dicha) + 0.25)
	_actualizar_depuracion()


## La figura completa salta y sus piezas sonrien. Devuelve la voz a decir ("" si no hay).
func _completar_figura(figura: Dictionary) -> String:
	figura["completa"] = true
	figura_completada.emit(figura["id"])
	var i := 0
	var piezas_figura: Array = []
	for hueco in figura["huecos"]:
		if hueco["pieza"] != null:
			piezas_figura.append(hueco["pieza"])
	if piezas_figura.is_empty():
		piezas_figura = _libres.keys()
	for pieza in piezas_figura:
		_despues(0.6 + i * 0.07, func() -> void:
			pieza.alegre = true
			pieza.saltito(22.0))
		i += 1
	if figura["especial"]:
		_despues(0.5, func() -> void:
			_arcoiris_especial()
			_confeti.restart())
	if figura["voz_completa"] != "":
		return figura["voz_completa"]
	return _linea_al_azar("figura_completa") if figura["huecos"].size() > 1 else ""


func _celebrar_tesoro(pieza: PiezaEncajar) -> void:
	_despues(0.4, func() -> void: pieza.alegre = true)
	pieza.brillar(2.5)
	_confeti.restart()
	_reaccion_anfitriona("baila")
	_reproducir_voz("especial", _linea("especial"))


func _llenar_ranura(pieza: PiezaEncajar) -> void:
	for ranura in _ranuras:
		if ranura.has_meta("lleno"):
			continue
		ranura.set_meta("lleno", pieza)
		ranura.pivot_offset = ranura.size / 2.0
		ranura.scale = Vector2.ONE * 1.4
		ranura.create_tween().tween_property(ranura, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ranura.queue_redraw()
		return


## Tangram libre y marco: al sacar una pieza, las ranuras se reordenan con las piezas que siguen puestas.
func _refrescar_ranuras() -> void:
	var puestas: Array = _libres.keys() if _mecanica == "tangram_libre" else _celdas_de.keys()
	for i in _ranuras.size():
		var ranura: Control = _ranuras[i]
		if i < puestas.size():
			ranura.set_meta("lleno", puestas[i])
		elif ranura.has_meta("lleno"):
			ranura.remove_meta("lleno")
		ranura.queue_redraw()


# ---------------------------------------------------------------------------
# Tangram libre (Sofia): cualquier solucion que llene la silueta
# ---------------------------------------------------------------------------

func _soltar_libre(pieza: PiezaEncajar, punto: Vector2) -> String:
	var distancia := INF
	for figura in _figuras:
		for contorno in figura["union"]:
			distancia = minf(distancia, Geo.distancia(punto, contorno))
	if distancia > _iman:
		reproducir_sfx(SFX_SOLTAR)
		pieza.volver_a_casa()
		return "nada"
	var centro = centro_libre(pieza, punto)
	if centro == null:
		return _fallar(pieza)
	_colocar_libre(pieza, centro)
	return "encajo"


## Mejor centro para la pieza cerca de `punto`, ajustado a la red del tangram; null si no cabe.
## Publica para los arneses QA.
func centro_libre(pieza: PiezaEncajar, punto: Vector2):
	var forma := pieza.poligono()
	var area := absf(Geo.area(forma))
	# Con red, solo valen posiciones ajustadas a ella: una pieza interior cabe en cualquier punto de la
	# silueta, y sin ajuste quedaria corrida unos px, estorbando a sus vecinas.
	var candidatos: Array = [] if _lado_red > 0.0 else [punto]
	if _lado_red > 0.0:
		for v in forma:
			var p := punto + v
			var red := _origen_red + ((p - _origen_red) / _lado_red).round() * _lado_red
			candidatos.append(punto + (red - p))
	var mejor = null
	var mejor_costo := INF
	for c: Vector2 in candidatos:
		if _lado_red > 0.0 and c.distance_to(punto) > _lado_red * 0.95:
			continue
		var costo := _costo_libre(pieza, Geo.desplazado(forma, c))
		if costo < mejor_costo - 0.01:
			mejor_costo = costo
			mejor = c
	return mejor if mejor_costo <= area * TOLERANCIA_LIBRE else null


## Area de la pieza que queda fuera de la silueta + area que pisa a otras piezas puestas.
func _costo_libre(pieza: PiezaEncajar, poligono: PackedVector2Array) -> float:
	var dentro := 0.0
	for figura in _figuras:
		for contorno in figura["union"]:
			for trozo in Geometry2D.intersect_polygons(poligono, contorno):
				dentro += absf(Geo.area(trozo))
	var costo := absf(Geo.area(poligono)) - dentro
	for otra in _libres:
		if otra == pieza:
			continue
		for trozo in Geometry2D.intersect_polygons(poligono, _libres[otra]):
			costo += absf(Geo.area(trozo))
	return costo


func _colocar_libre(pieza: PiezaEncajar, centro: Vector2, silencioso := false) -> void:
	_arrastrando.erase(pieza)
	pieza.elegida = false
	pieza.encajar_libre(centro, pieza.rotacion_grados)
	_libres[pieza] = Geo.desplazado(pieza.poligono(), centro)
	_encajados = _libres.size()
	_refrescar_ranuras()
	pieza_encajada.emit(pieza.id)
	if silencioso:
		return
	reproducir_sfx(SFX_ENCAJE)
	_estallido(centro, 8, [pieza.color, DORADO])
	_reaccion_anfitriona("salta")
	if _cobertura() >= COBERTURA_MINIMA:
		var voz := _completar_figura(_figuras[0])
		_completar_prueba(voz)
	else:
		_reproducir_voz("acierto", _linea_al_azar("acierto"))
	_actualizar_depuracion()


func _cobertura() -> float:
	if _area_silueta <= 0.0:
		return 0.0
	var cubierta := 0.0
	for pieza in _libres:
		cubierta += absf(Geo.area(_libres[pieza]))
	return cubierta / _area_silueta


func _quitar_colocada(pieza: PiezaEncajar) -> void:
	_libres.erase(pieza)
	if _celdas_de.has(pieza):
		for celda in _celdas_de[pieza]:
			_marco["ocupadas"].erase(celda)
		_celdas_de.erase(pieza)
		_guardar_avance()
	pieza.liberar()
	pieza.alegre = false
	_encajados = _libres.size() if _mecanica == "tangram_libre" else _celdas_de.size()
	_refrescar_ranuras()


# ---------------------------------------------------------------------------
# Marco de pentominos (Sofia)
# ---------------------------------------------------------------------------

func _soltar_marco(pieza: PiezaEncajar, punto: Vector2) -> String:
	var tablero := Rect2(_marco["origen"], _marco["medida"]).grow(float(_marco["lado"]) * 0.8)
	if not tablero.has_point(punto):
		reproducir_sfx(SFX_SOLTAR)
		pieza.volver_a_casa()
		return "nada"
	var centro := centro_marco(pieza, punto)
	var celdas := celdas_en(pieza, centro)
	for celda in celdas:
		if not _marco["celdas"].has(celda) or _marco["ocupadas"].has(celda):
			return _fallar(pieza)
	_colocar_marco(pieza, centro, celdas)
	return "encajo"


## Centro de la pieza ajustado para que sus cuadraditos caigan justo sobre la cuadricula.
func centro_marco(pieza: PiezaEncajar, punto: Vector2) -> Vector2:
	var lado: float = _marco["lado"]
	var origen: Vector2 = _marco["origen"]
	var primera := punto + _desfase_celda(pieza, pieza.celdas[0])
	var ajustada := origen + ((primera - origen) / lado).floor() * lado + Vector2.ONE * lado / 2.0
	return punto + (ajustada - primera)


## Celdas del tablero que ocuparia la pieza con su centro en `centro` (con su giro y espejo actuales).
func celdas_en(pieza: PiezaEncajar, centro: Vector2) -> Array:
	var lado: float = _marco["lado"]
	var origen: Vector2 = _marco["origen"]
	var salida: Array = []
	for celda in pieza.celdas:
		var p := centro + _desfase_celda(pieza, celda) - origen
		salida.append(Vector2i(floori(p.x / lado + 0.001), floori(p.y / lado + 0.001)))
	return salida


func _desfase_celda(pieza: PiezaEncajar, celda) -> Vector2:
	var caja := Vector2.ZERO
	for otra in pieza.celdas:
		caja = Vector2(maxf(caja.x, float(otra[0]) + 1.0), maxf(caja.y, float(otra[1]) + 1.0))
	var local := (Vector2(float(celda[0]), float(celda[1])) + Vector2(0.5, 0.5) - caja / 2.0) * pieza.lado
	if pieza.volteada:
		local.x = -local.x
	return local.rotated(deg_to_rad(pieza.rotacion_grados))


func _colocar_marco(pieza: PiezaEncajar, centro: Vector2, celdas: Array, silencioso := false) -> void:
	_arrastrando.erase(pieza)
	pieza.elegida = false
	pieza.encajar_libre(centro, pieza.rotacion_grados)
	_celdas_de[pieza] = celdas
	for celda in celdas:
		_marco["ocupadas"][celda] = pieza
	_encajados = _celdas_de.size()
	_refrescar_ranuras()
	pieza_encajada.emit(pieza.id)
	_guardar_avance()
	if silencioso:
		return
	reproducir_sfx(SFX_ENCAJE)
	_estallido(centro, 8, [pieza.color, DORADO])
	_reaccion_anfitriona("salta")
	if _marco["ocupadas"].size() >= _marco["lista"].size():
		for otra in _celdas_de:
			_despues(0.5, func() -> void:
				otra.alegre = true
				otra.saltito(18.0))
		_completar_prueba(_linea_al_azar("figura_completa"))
	else:
		_reproducir_voz("acierto", _linea_al_azar("acierto"))
	_actualizar_depuracion()


## Pone una pieza del marco exactamente sobre `celdas_objetivo` probando sus giros y espejos.
func _colocar_marco_en(pieza: PiezaEncajar, celdas_objetivo: Array, silencioso: bool) -> bool:
	var objetivo := {}
	var minimo := Vector2(INF, INF)
	var maximo := Vector2(-INF, -INF)
	for celda in celdas_objetivo:
		var v := Vector2i(int(celda[0]), int(celda[1]))
		objetivo[v] = true
		minimo = minimo.min(Vector2(v))
		maximo = maximo.max(Vector2(v))
	var centro: Vector2 = _marco["origen"] + (minimo + maximo + Vector2.ONE) / 2.0 * float(_marco["lado"])
	var volteada_original := pieza.volteada
	var grados_original := pieza.rotacion_grados
	var espejos := [pieza.volteada, not pieza.volteada]
	for espejo in espejos:
		pieza.volteada = espejo
		for k in 4:
			pieza.rotacion_grados = float(k) * 90.0
			var celdas := celdas_en(pieza, centro)
			var iguales := celdas.size() == objetivo.size()
			for celda in celdas:
				iguales = iguales and objetivo.has(celda)
			if iguales:
				pieza.rotation = deg_to_rad(pieza.rotacion_grados)
				_colocar_marco(pieza, centro, celdas, silencioso)
				return true
	pieza.volteada = volteada_original
	pieza.rotacion_grados = grados_original
	return false


# ---------------------------------------------------------------------------
# Copia de memoria (Sofia)
# ---------------------------------------------------------------------------

## Muestra el modelo a color `segundos` y lo tapa con la cortina de Coco. Mientras, no se arrastra.
func _mostrar_modelo(segundos: float, espera := 0.0) -> void:
	_en_modelo = true
	_siluetas.modelo_visible = true
	_siluetas.queue_redraw()
	_actualizar_botones()
	if espera > 0.0:
		_reproducir_voz("mira_modelo", _linea("mira_modelo"))
	await get_tree().create_timer(segundos + espera).timeout
	if not is_inside_tree():
		return
	_reproducir_voz("tapa_modelo", _linea("tapa_modelo"))
	var tween := create_tween()
	tween.tween_property(_siluetas, "cortina", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		_siluetas.modelo_visible = false
		_siluetas.queue_redraw())
	tween.tween_property(_siluetas, "cortina", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree():
		return
	_en_modelo = false
	_siluetas.queue_redraw()
	_actualizar_botones()


func _al_tocar_ojo() -> void:
	if _en_modelo or _terminado or _en_gag:
		return
	reproducir_sfx(SFX_TOQUE)
	_gastar_estrellita(_boton_ojo)
	_mostrar_modelo(SEGUNDOS_VISTAZO)


# ---------------------------------------------------------------------------
# Pistas que cuestan estrellita, espejo y regalo tras derrotas (Sofia)
# ---------------------------------------------------------------------------

func _al_tocar_pista() -> void:
	if _en_modelo or _terminado or _en_gag:
		return
	reproducir_sfx(SFX_TOQUE)
	if colocar_pista():
		_gastar_estrellita(_boton_pista)
		_reproducir_voz("pista_usada", _linea("pista_usada"))
	_actualizar_depuracion()


func _gastar_estrellita(boton: Button) -> void:
	_pistas_usadas += 1
	var estrella := Figura.new()
	estrella.figura = "estrella"
	estrella.con_cara = false
	estrella.color = DORADO
	estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estrella.size = Vector2.ONE * 46.0
	estrella.pivot_offset = estrella.size / 2.0
	_efectos.add_child(estrella)
	estrella.global_position = boton.global_position + boton.size / 2.0 - estrella.size / 2.0
	var tween := estrella.create_tween().set_parallel(true)
	tween.tween_property(estrella, "position:y", estrella.position.y + 90.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(estrella, "rotation", 1.6, 0.9)
	tween.tween_property(estrella, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(estrella.queue_free)


## Coloca una pieza correcta en su lugar (o devuelve a la bandeja una mal puesta). true si hizo algo.
## Publica para los arneses QA.
func colocar_pista() -> bool:
	match _mecanica:
		"tangram_libre":
			return _pista_libre()
		"marco":
			return _pista_marco()
	for hueco in _huecos:
		if hueco["pieza"] != null or hueco["opcional"]:
			continue
		for pieza in _piezas:
			if pieza.colocada or pieza.forma != hueco["forma"] or not pieza.color.is_equal_approx(hueco["color"]):
				continue
			pieza.volteada = hueco["espejo"]
			pieza.rotacion_grados = wrapf(float(hueco["rotacion"]), 0.0, 360.0)
			pieza.brillar(SEGUNDOS_PISTA)
			_encajar(pieza, hueco)
			return true
	return false


func _pista_libre() -> bool:
	for hueco in _huecos:
		if hueco["opcional"]:
			continue
		var ocupado := false
		for otra in _libres:
			var pisado := 0.0
			for trozo in Geometry2D.intersect_polygons(hueco["poligono"], _libres[otra]):
				pisado += absf(Geo.area(trozo))
			ocupado = ocupado or pisado > absf(Geo.area(hueco["poligono"])) * 0.05
		if ocupado:
			continue
		for pieza in _piezas:
			if pieza.colocada or pieza.forma != hueco["forma"] or not is_equal_approx(pieza.ancho, hueco["ancho"]) or not is_equal_approx(pieza.alto, hueco["alto"]):
				continue
			pieza.volteada = hueco["espejo"]
			pieza.rotacion_grados = wrapf(float(hueco["rotacion"]), 0.0, 360.0)
			pieza.brillar(SEGUNDOS_PISTA)
			_colocar_libre(pieza, hueco["centro"])
			return true
	return _devolver_mal_puesta()


func _pista_marco() -> bool:
	for entrada: Dictionary in _cfg.get("solucion", []):
		var pieza: PiezaEncajar = null
		for candidata in _piezas:
			if candidata.id == str(entrada.get("id", "")):
				pieza = candidata
		if pieza == null or pieza.colocada:
			continue
		var libres := true
		for celda in entrada.get("celdas", []):
			libres = libres and not _marco["ocupadas"].has(Vector2i(int(celda[0]), int(celda[1])))
		if libres:
			pieza.brillar(SEGUNDOS_PISTA)
			return _colocar_marco_en(pieza, entrada["celdas"], false)
	return _devolver_mal_puesta()


## Si ninguna pista cabe, es porque hay una pieza mal puesta: vuelve a la bandeja brillando.
func _devolver_mal_puesta() -> bool:
	var puestas: Array = _libres.keys() if _mecanica == "tangram_libre" else _celdas_de.keys()
	for pieza in puestas:
		if _esta_bien_puesta(pieza):
			continue
		_quitar_colocada(pieza)
		pieza.bloqueada = false
		pieza.volver_a_casa(true)
		pieza.brillar(SEGUNDOS_PISTA)
		return true
	return false


func _esta_bien_puesta(pieza: PiezaEncajar) -> bool:
	if _mecanica == "marco":
		for entrada: Dictionary in _cfg.get("solucion", []):
			if str(entrada.get("id", "")) != pieza.id:
				continue
			var celdas: Array = _celdas_de.get(pieza, [])
			for celda in entrada.get("celdas", []):
				if not celdas.has(Vector2i(int(celda[0]), int(celda[1]))):
					return false
			return true
		return false
	for hueco in _huecos:
		if Geo.diferencia(_libres[pieza], hueco["poligono"]) <= Geo.TOLERANCIA_CALCE:
			return true
	return false


func _al_tocar_espejo() -> void:
	if _en_modelo or _terminado or _en_gag:
		return
	if _pieza_elegida == null or not is_instance_valid(_pieza_elegida) or _pieza_elegida.colocada:
		reproducir_sfx(SFX_TOQUE)
		_reproducir_voz("espejo_sin_pieza", _linea("espejo_sin_pieza"))
		return
	reproducir_sfx(SFX_GIRO)
	_pieza_elegida.voltear()
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Avance guardado pieza a pieza (reto dorado)
# ---------------------------------------------------------------------------

func _guardar_avance() -> void:
	if not bool(_cfg.get("guardar_avance", false)) or _terminado:
		return
	var piezas: Array = []
	for pieza in _celdas_de:
		var celdas: Array = []
		for celda in _celdas_de[pieza]:
			celdas.append([celda.x, celda.y])
		piezas.append({"id": pieza.id, "celdas": celdas})
	guardar_estado_parcial({"prueba": _indice_prueba, "piezas": piezas})


func _restaurar_avance() -> void:
	var estado := obtener_estado_parcial()
	if estado.is_empty() or int(estado.get("prueba", -1)) != _indice_prueba:
		return
	for guardada: Dictionary in estado.get("piezas", []):
		for pieza in _piezas:
			if pieza.id == str(guardada.get("id", "")) and not pieza.colocada:
				_colocar_marco_en(pieza, guardada.get("celdas", []), true)
	_actualizar_depuracion()


# ---------------------------------------------------------------------------
# Ayudas: objetivo guiado (Brote) y pista por inactividad (Semilla)
# ---------------------------------------------------------------------------

func _elegir_objetivo() -> void:
	var pendientes: Array = []
	for hueco in _huecos:
		if hueco["pieza"] == null and not hueco["opcional"]:
			pendientes.append(hueco)
	_objetivo = pendientes[randi() % pendientes.size()] if not pendientes.is_empty() else null
	_siluetas.hueco_objetivo = _objetivo
	_siluetas.queue_redraw()


func _ruta_voz_objetivo() -> String:
	if _objetivo == null:
		return ""
	var prefijo := str(_cfg.get("lineas_voz", {}).get("objetivo_prefijo", ""))
	return "" if prefijo == "" else prefijo + str(_objetivo["nombre_voz"]) + ".wav"


func _dar_pista() -> void:
	var hueco = null
	var pieza_pista: PiezaEncajar = null
	for pieza in _piezas:
		if pieza.colocada:
			continue
		hueco = _hueco_para(pieza)
		if hueco != null and not hueco["opcional"]:
			pieza_pista = pieza
			break
	if pieza_pista == null:
		return
	_pistas_dadas += 1
	_mostrar_pista(pieza_pista, hueco)
	pieza_pista.saltito(24.0)
	if _pistas_dadas % 2 == 1:
		_reproducir_voz("pista", _linea("pista"))


func _mostrar_pista(pieza: PiezaEncajar, hueco) -> void:
	if hueco == null:
		return
	pieza.brillar(SEGUNDOS_PISTA)
	_siluetas.hueco_pista = hueco
	_siluetas.queue_redraw()
	_despues(SEGUNDOS_PISTA, func() -> void:
		if _siluetas.hueco_pista == hueco:
			_siluetas.hueco_pista = null
			_siluetas.queue_redraw())


# ---------------------------------------------------------------------------
# Derrota-gag, reintento, pruebas y victoria
# ---------------------------------------------------------------------------

## Brote: las piezas sueltas se apilan en una torre que se derrumba. Estrella: las piezas se ponen a
## bailar por el tablero. En los dos, Coco se rie y aparece el boton gigante "¡otra vez!" (GDD §5).
func _disparar_derrota_gag() -> void:
	_derrota_disparada = true
	_derrotas += 1
	_en_gag = true
	nivel_fallado.emit()
	reproducir_sfx(SFX_GAG)
	_reproducir_voz("derrota_gag", _linea("derrota_gag"))
	_reaccion_anfitriona("rie")
	var pendientes: Array[PiezaEncajar] = []
	for pieza in _piezas:
		if not pieza.colocada:
			pieza.cancelar_arrastre()
			pieza.bloqueada = true
			pendientes.append(pieza)
	_arrastrando.clear()
	if obtener_perfil_dificultad() == "brote":
		_gag_torre(pendientes)
	else:
		_gag_baile(pendientes)
	_despues(1.3, func() -> void:
		_boton_otra_vez.show()
		_boton_otra_vez.pivot_offset = _boton_otra_vez.size / 2.0
		_boton_otra_vez.scale = Vector2.ZERO
		_boton_otra_vez.create_tween().tween_property(_boton_otra_vez, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_actualizar_depuracion()


func _gag_torre(pendientes: Array[PiezaEncajar]) -> void:
	var base := Vector2(556.0, 700.0)
	var y := base.y
	for i in pendientes.size():
		var pieza := pendientes[i]
		var alto := Geo.caja(pieza.poligono()).size.y * 0.6
		if y - alto < 150.0:
			base.x += 110.0
			y = base.y
		var destino := Vector2(base.x + randf_range(-10, 10), y - alto / 2.0)
		y -= alto * 0.92
		var caida := destino + Vector2(randf_range(-190, 190), randf_range(-20, 10))
		caida.y = minf(caida.y + 140.0, 690.0)
		var tween := pieza.nuevo_tween()
		tween.tween_interval(i * 0.08)
		tween.tween_property(pieza, "position", destino - pieza.size / 2.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(pieza, "scale", Vector2.ONE * 0.6, 0.32)
		tween.tween_interval(0.7 - i * 0.05)
		tween.tween_property(pieza, "position", caida - pieza.size / 2.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(pieza, "rotation", pieza.rotation + randf_range(-2.4, 2.4), 0.5)


func _gag_baile(pendientes: Array[PiezaEncajar]) -> void:
	for i in pendientes.size():
		var pieza := pendientes[i]
		var tween := pieza.nuevo_tween()
		for paso in 3:
			var punto := _zona_figuras.position + Vector2(randf() * _zona_figuras.size.x, randf() * _zona_figuras.size.y)
			tween.tween_property(pieza, "position", punto - pieza.size / 2.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(pieza, "rotation", pieza.rotation + TAU * (paso + 1) * (1 if i % 2 == 0 else -1), 0.38)
			tween.parallel().tween_property(pieza, "scale", Vector2.ONE * (0.8 if paso % 2 == 0 else 0.6), 0.38)


func _reintentar() -> void:
	_boton_otra_vez.hide()
	_en_gag = false
	# Mismo criterio que emparejar (M-QA1): el contador vuelve a cero para dar ritmo, pero el bono de
	# intentos sobrantes queda anulado para toda la partida (`_derrota_disparada`).
	_intentos_usados = 0
	reproducir_sfx(SFX_TOQUE)
	for pieza in _piezas:
		if pieza.colocada:
			continue
		pieza.bloqueada = false
		pieza.rotation = deg_to_rad(pieza.rotacion_grados)
		pieza.volver_a_casa()
	# Tras 2 derrotas, Coco regala una pieza puesta (no cuesta estrellita): nunca queda trabada.
	if _derrotas >= 2 and bool(_cfg.get("regalo_tras_derrotas", false)) and not _regalo_dado:
		_regalo_dado = true
		_despues(0.7, func() -> void:
			if colocar_pista():
				_reproducir_voz("regalo", _linea("regalo")))
	_actualizar_depuracion()


## Termino una prueba: si quedan, se celebra y se arma la siguiente; si no, la victoria final.
func _completar_prueba(voz_figura: String) -> void:
	if _indice_prueba + 1 >= _pruebas.size():
		_celebrar_victoria(voz_figura)
		return
	_terminado = true
	_destellos_pruebas += _destellos_prueba_actual()
	_borrar_avance_prueba()
	prueba_completada.emit(_indice_prueba)
	for pieza in _piezas:
		pieza.bloqueada = true
		pieza.cancelar_arrastre()
	_confeti.restart()
	_reaccion_anfitriona("baila")
	var espera := 1.0
	if voz_figura != "":
		_reproducir_voz("figura_completa", voz_figura)
		espera = clampf(_duracion_voz(voz_figura) + 0.3, 1.0, 3.8)
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree():
		return
	var voz_prueba := _linea_al_azar("prueba_superada")
	_reproducir_voz("prueba_superada", voz_prueba)
	await get_tree().create_timer(_duracion_voz(voz_prueba) + 0.4).timeout
	if not is_inside_tree():
		return
	_limpiar_tablero()
	_indice_prueba += 1
	_iniciar_prueba()


func _borrar_avance_prueba() -> void:
	if bool(_cfg.get("guardar_avance", false)):
		borrar_estado_parcial()


func _limpiar_tablero() -> void:
	for pieza in _piezas:
		pieza.queue_free()
	for ranura in _ranuras:
		ranura.queue_free()
	_piezas.clear()
	_ranuras.clear()
	_figuras.clear()
	_huecos.clear()
	_arrastrando.clear()
	_libres.clear()
	_celdas_de.clear()
	_marco = {}
	_requeridos = 0
	_encajados = 0
	_intentos_usados = 0
	_area_silueta = 0.0
	_objetivo = null
	_pieza_elegida = null
	_regalo_dado = false
	_siluetas.figuras = []
	_siluetas.marco = {}
	_siluetas.modelo_visible = false
	_siluetas.cortina = 0.0
	_siluetas.hueco_objetivo = null
	_siluetas.hueco_pista = null
	_siluetas.hueco_cercano = null
	_terminado = false
	_en_gag = false
	_en_modelo = false


func _celebrar_victoria(voz_figura: String) -> void:
	_terminado = true
	_siluetas.hueco_objetivo = null
	_siluetas.hueco_pista = null
	_siluetas.queue_redraw()
	_id_voz_diferida += 1
	for pieza in _piezas:
		pieza.bloqueada = true
		pieza.cancelar_arrastre()
	var espera := 0.9
	if voz_figura != "":
		_reproducir_voz("figura_completa", voz_figura)
		espera = clampf(_duracion_voz(voz_figura) + 0.3, 0.9, 3.8)
	_despues(0.5, func() -> void:
		_confeti.restart()
		_reaccion_anfitriona("baila"))
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree():
		return
	celebrar(_calcular_destellos(), _calcular_estrellitas(), _linea_al_azar("victoria_final"))


## Estrellitas del perfil Estrella. Regla PROVISIONAL, la misma de emparejar hasta que
## `disenador-niveles` fije umbrales: sin limite -> 3; tras derrota-gag -> 1; con la mitad o mas
## de los intentos sobrantes -> 3; si no -> 2. Cada pista (o vistazo al modelo) resta una, sin
## bajar de 1: ganar siempre da al menos una estrellita.
func _calcular_estrellitas() -> int:
	var base := 3
	if _derrota_disparada:
		base = 1
	elif _limite_intentos != null:
		var sobrantes: int = max(int(_limite_intentos) - _intentos_usados, 0)
		base = 3 if sobrantes * 2 >= int(_limite_intentos) else 2
	return maxi(1, base - _pistas_usadas)


func _destellos_prueba_actual() -> int:
	var total := _requeridos * DESTELLOS_POR_PIEZA
	if _limite_intentos != null and not _derrota_disparada:
		total += max(int(_limite_intentos) - _intentos_usados, 0) * DESTELLOS_POR_INTENTO_SOBRANTE
	return total


func _calcular_destellos() -> int:
	return _destellos_pruebas + _destellos_prueba_actual()


# ---------------------------------------------------------------------------
# Voz, anfitriona y efectos
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
	# Traza en consola para los arneses QA + reproduccion real via contrato base (HE-10).
	if ruta != "":
		print("[voz:%s] %s" % [clave, ruta])
		reproducir_voz(ruta)


## Dice una linea despues de `segundos`, salvo que otra voz diferida la reemplace antes.
func _voz_diferida(clave: String, ruta: String, segundos: float) -> void:
	if ruta == "":
		return
	_id_voz_diferida += 1
	var id := _id_voz_diferida
	await get_tree().create_timer(segundos).timeout
	if id == _id_voz_diferida and is_inside_tree() and not _terminado and not _en_gag:
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


## Tocar a Cometa repite la instruccion (GDD §6.2). En Brote nombra el objetivo actual; en Semilla,
## ademas, muestra una pista con brillo.
func _al_tocar_cometa() -> void:
	reproducir_sfx(SFX_TOQUE)
	_inactivo = 0.0
	if _objetivo_guiado and _objetivo != null:
		_reproducir_voz("objetivo", _ruta_voz_objetivo())
		return
	_reproducir_voz("pista", _linea("pista"))
	if _sin_error and not _terminado:
		_pistas_dadas += 1
		_dar_pista()


## Tocar a Coco: da un saltito y vuelve a explicar el juego.
func _al_tocar_anfitriona(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not toque:
		return
	reproducir_sfx(SFX_TOQUE)
	_reaccion_anfitriona("salta")
	_reproducir_voz("intro", _linea("intro"))


func _reaccion_anfitriona(tipo: String) -> void:
	if _tween_anfitriona != null and _tween_anfitriona.is_valid():
		_tween_anfitriona.kill()
	_anfitriona.rotation = 0.0
	_anfitriona.scale = Vector2.ONE
	_salto_anfitriona = 0.0
	var tween := create_tween()
	_tween_anfitriona = tween
	match tipo:
		"salta":
			tween.tween_property(_anfitriona, "scale", Vector2(1.08, 0.9), 0.08)
			tween.tween_property(self, "_salto_anfitriona", 46.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_anfitriona, "scale", Vector2(0.94, 1.08), 0.18)
			tween.tween_property(self, "_salto_anfitriona", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_anfitriona, "scale", Vector2.ONE, 0.3)
		"menea":
			for angulo in [-6.0, 6.0, -3.0, 0.0]:
				tween.tween_property(_anfitriona, "rotation", deg_to_rad(angulo), 0.1)
		"rie":
			for i in 4:
				tween.tween_property(self, "_salto_anfitriona", 20.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(_anfitriona, "rotation", deg_to_rad(-5.0 if i % 2 == 0 else 5.0), 0.1)
				tween.tween_property(self, "_salto_anfitriona", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(_anfitriona, "rotation", 0.0, 0.1)
		"baila":
			for i in 6:
				tween.tween_property(self, "_salto_anfitriona", 36.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(_anfitriona, "rotation", deg_to_rad(-9.0 if i % 2 == 0 else 9.0), 0.16)
				tween.tween_property(self, "_salto_anfitriona", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(_anfitriona, "rotation", 0.0, 0.12)


func _estallido(centro: Vector2, cantidad: int, colores: Array, escala := 1.0) -> void:
	for i in cantidad:
		var chispa := Figura.new()
		chispa.figura = "estrella"
		chispa.con_cara = false
		chispa.color = colores[i % colores.size()]
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * randf_range(20.0, 34.0) * escala
		chispa.pivot_offset = chispa.size / 2.0
		_efectos.add_child(chispa)
		chispa.global_position = centro - chispa.size / 2.0
		var angulo := TAU * i / cantidad + randf_range(-0.3, 0.3)
		var destino := chispa.position + Vector2.from_angle(angulo) * randf_range(60.0, 110.0) * escala
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "rotation", randf_range(-PI, PI), 0.55)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


## Momento memorable de una figura especial (la corona de Sofia): un arcoiris cruza el tablero.
func _arcoiris_especial() -> void:
	var arco := Control.new()
	arco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arco.modulate.a = 0.85
	_efectos.add_child(arco)
	arco.size = _efectos.size
	var estado := {"avance": 0.0}
	arco.draw.connect(func() -> void:
		var base := Vector2(640, 720)
		for i in Figura.COLORES_ARCOIRIS.size():
			arco.draw_arc(base, 560.0 - i * 26.0, PI, PI + PI * estado["avance"], 64, Figura.COLORES_ARCOIRIS[i], 27.0, true)
	)
	var tween := arco.create_tween()
	tween.tween_method(func(valor: float) -> void:
		estado["avance"] = valor
		arco.queue_redraw()
	, 0.0, 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(arco, "modulate:a", 0.0, 0.6).set_delay(0.6)
	tween.tween_callback(arco.queue_free)


func _actualizar_depuracion() -> void:
	if not _panel_depuracion.visible:
		return
	var limite := "sin limite" if _limite_intentos == null else str(_limite_intentos)
	var reglas: Array = []
	for campo in ["sin_error", "toque_lleva_a_casa", "objetivo_guiado", "enderezar_al_acercar", "rotacion_por_toque", "risa_al_encajar", "guia_color", "boton_espejo", "pistas_cuestan_estrellita", "regalo_tras_derrotas"]:
		if bool(_cfg.get(campo, false)):
			reglas.append(campo)
	_panel_depuracion.text = "DEPURACION (F3)\nnivel: %s\nperfil: %s · juega: %s\nmecanica: %s · prueba %d de %d\npiezas: %d de %d\niman: %.0f px\nfallos que cuentan: %d / %s\nderrotas: %d · pistas usadas: %d\nreglas: %s\nsi termina ahora: %d destellos, %d estrellitas" % [
		nivel.get("id_nivel", "?"), obtener_perfil_dificultad(), obtener_id_personaje(), _mecanica,
		_indice_prueba + 1, maxi(1, _pruebas.size()), _encajados, _requeridos, _iman, _intentos_usados, limite,
		_derrotas, _pistas_usadas, ", ".join(reglas), _calcular_destellos(), _estrellitas_visibles(_calcular_estrellitas())]


# ---------------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------------

## Botones de los retos de Sofia, creados por codigo: pista (arriba a la derecha), espejo y mirar el
## modelo (bajo la bandeja). Todos >= 96 px (GDD §6.1) y visibles solo si el nivel los usa.
func _crear_botones_sofia() -> void:
	var ui: Control = _boton_salir.get_parent()
	_boton_pista = _boton_redondo(ui, Rect2(1164, 16, 96, 96), DORADO, "Pista: pone una pieza (cuesta una estrellita)", _dibujar_icono_pista)
	_boton_pista.pressed.connect(_al_tocar_pista)
	_boton_espejo = _boton_redondo(ui, Rect2(900, 590, 110, 110), Color("#CFF5F1"), "Espejo: voltea la pieza elegida", _dibujar_icono_espejo)
	_boton_espejo.pressed.connect(_al_tocar_espejo)
	_boton_ojo = _boton_redondo(ui, Rect2(1022, 590, 110, 110), Color("#FFE3F1"), "Mirar el modelo otra vez (cuesta una estrellita)", _dibujar_icono_ojo)
	_boton_ojo.pressed.connect(_al_tocar_ojo)


func _actualizar_botones() -> void:
	_boton_pista.visible = bool(_cfg.get("pistas_cuestan_estrellita", false))
	_boton_espejo.visible = _boton_espejo_activo
	var rect_espejo := _rect_de(_cfg.get("boton_espejo_rect", null), Rect2(900, 590, 110, 110))
	_boton_espejo.position = rect_espejo.position
	_boton_espejo.size = rect_espejo.size
	_boton_ojo.visible = _mecanica == "memoria"
	_boton_ojo.disabled = _en_modelo
	_boton_ojo.modulate.a = 0.5 if _en_modelo else 1.0


func _boton_redondo(padre: Control, rect: Rect2, fondo: Color, ayuda: String, icono: Callable) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.tooltip_text = ayuda
	boton.custom_minimum_size = rect.size
	padre.add_child(boton)
	padre.move_child(boton, _efectos.get_index())
	boton.position = rect.position
	boton.size = rect.size
	_estilizar_boton(boton, fondo)
	var dibujo := Control.new()
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(dibujo)
	dibujo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dibujo.draw.connect(icono.bind(dibujo))
	boton.hide()
	return boton


## Pista: una estrellita con chispas (la ayuda se "paga" con una estrellita).
func _dibujar_icono_pista(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	Figura.dibujar(icono, "estrella", Color("#FFF3B0"), c + Vector2(0, 3) * k, 30.0 * k, false)
	for p in [Vector2(-30, -26), Vector2(30, -22), Vector2(26, 30)]:
		var chispa := Figura.poligono("estrella", c + p * k, 8.0 * k)
		icono.draw_colored_polygon(chispa, Color.WHITE)
		Figura.contornear(icono, chispa, 2.0 * k)


## Espejo: un triangulo y su reflejo a cada lado de una linea punteada.
func _dibujar_icono_espejo(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 110.0
	var izquierda := PackedVector2Array([c + Vector2(-8, -30) * k, c + Vector2(-8, 28) * k, c + Vector2(-40, 28) * k])
	var derecha := PackedVector2Array([c + Vector2(8, -30) * k, c + Vector2(40, 28) * k, c + Vector2(8, 28) * k])
	icono.draw_colored_polygon(izquierda, Color("#FF6B6B"))
	Figura.contornear(icono, izquierda, 4.0 * k)
	icono.draw_colored_polygon(derecha, Color("#4A8BE0"))
	Figura.contornear(icono, derecha, 4.0 * k)
	var y := -38.0
	while y < 36.0:
		icono.draw_line(c + Vector2(0, y) * k, c + Vector2(0, y + 8) * k, COLOR_CONTORNO, 3.0 * k, true)
		y += 14.0


## Ojo: mirar el modelo otra vez.
func _dibujar_icono_ojo(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 110.0
	var contorno := PackedVector2Array()
	for i in 33:
		var t := PI * i / 32.0
		contorno.append(c + Vector2(-cos(t) * 40.0, -sin(t) * 22.0) * k)
	for i in range(1, 32):
		var t := PI * i / 32.0
		contorno.append(c + Vector2(cos(t) * 40.0, sin(t) * 22.0) * k)
	icono.draw_colored_polygon(contorno, Color.WHITE)
	Figura.contornear(icono, contorno, 4.0 * k)
	icono.draw_circle(c, 14.0 * k, TURQUESA)
	icono.draw_circle(c, 7.0 * k, COLOR_CONTORNO)
	icono.draw_circle(c + Vector2(-4, -4) * k, 3.0 * k, Color.WHITE)


func _estilizar_interfaz() -> void:
	_estilizar_boton(_boton_salir, Color("#FFF8EE"))
	_estilizar_boton(_boton_cometa, Color("#CFF5F1"))
	_estilizar_boton(_boton_otra_vez, DORADO)
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_salir.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(_dibujar_flecha.bind(icono))

	if ResourceLoader.exists(RUTA_FUENTE):
		var fuente: Font = load(RUTA_FUENTE)
		_boton_otra_vez.add_theme_font_override("font", fuente)
		_panel_depuracion.add_theme_font_override("font", fuente)
	_boton_otra_vez.add_theme_font_size_override("font_size", 46)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_boton_otra_vez.add_theme_color_override(estado, COLOR_CONTORNO)

	var barra := StyleBoxFlat.new()
	barra.bg_color = Color(0.23, 0.16, 0.42, 0.55)
	barra.border_color = Color(1, 1, 1, 0.4)
	barra.set_border_width_all(3)
	barra.set_corner_radius_all(48)
	barra.set_content_margin_all(8)
	barra.content_margin_left = 16
	barra.content_margin_right = 16
	_barra_progreso.add_theme_stylebox_override("panel", barra)

	var bandeja := StyleBoxFlat.new()
	bandeja.bg_color = Color(1.0, 0.97, 0.93, 0.3)
	bandeja.border_color = Color(1, 1, 1, 0.6)
	bandeja.set_border_width_all(4)
	bandeja.set_corner_radius_all(40)
	_bandeja.add_theme_stylebox_override("panel", bandeja)
	_bandeja.position = ZONA_BANDEJA.position
	_bandeja.size = ZONA_BANDEJA.size

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(COLOR_CONTORNO, 0.85)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(12)
	_panel_depuracion.add_theme_stylebox_override("normal", panel)
	_panel_depuracion.add_theme_color_override("font_color", Color("#FFF8EE"))

	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	degradado.colors = PackedColorArray(Figura.COLORES_ARCOIRIS)
	_confeti.color_initial_ramp = degradado


func _estilizar_boton(boton: Button, fondo: Color) -> void:
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
	boton.button_down.connect(func() -> void:
		boton.pivot_offset = boton.size / 2.0
		boton.scale = Vector2(0.9, 0.9)
		boton.create_tween().tween_property(boton, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-26, 0), Vector2(2, -26), Vector2(2, -12), Vector2(26, -12), Vector2(26, 12), Vector2(2, 12), Vector2(2, 26)]:
		puntos.append(c + p * k)
	icono.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(icono, puntos, 5.0 * k)
