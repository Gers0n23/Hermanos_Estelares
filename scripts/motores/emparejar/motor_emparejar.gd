class_name MotorEmparejar
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "emparejar" (docs/fichas/motor-emparejar.md).
## Agnostico de tema: arma el tablero desde `nivel` (JSON, contrato §4 de la ficha) y aplica
## las reglas de escalado por perfil que ya vienen resueltas en los datos (cantidad de pares,
## `oculto`, `tiempo_volteo_ms`, `limite_intentos`, `ayuda_tras_fallos`, `halo_idle`). No
## conoce ponys, figuras ni ningun tema: cada elemento trae su `figura`/`color` o `sprite`.
##
## DEMO JUGABLE DEL PLANETA ARCOIRIS (13-Sep-2026, pedido del PO): escenario con el fondo real
## del planeta, Coco como anfitriona, cartas con el estilo del juego, barra de pares
## encontrados, voces TTS provisionales y una ruta por hermano en `datos/niveles/arcoiris_*`.
##
## Memoria (cambio de jugabilidad, a validar por disenador-mecanicas): la primera carta queda
## a la vista hasta tocar la segunda. `tiempo_volteo_ms` es cuanto quedan visibles las dos
## cartas de un "no es este" antes de taparse; tocar otra carta en ese lapso las tapa al tiro y
## sigue el juego (Sofia no espera, Maxi y Nicole tienen tiempo de mirar). Antes la primera se
## re-tapaba sola a los 850 ms, lo que hacia el nivel casi injugable.
##
## F3 (solo PC) muestra un panel de depuracion con intentos, fallos y puntaje para el PO.
##
## RONDAS (PO 27-Sep-2026, Maxi y Nicole): un nivel puede traer `rondas: [ {...} ]`. Cada ronda
## pisa los campos del nivel que traiga (`pares`, `disposicion`, `oculto`, `tiempo_volteo_ms`,
## `cartas_bailan`...; `lineas_voz` se mezcla) y puede sortear su contenido de un `pool` mayor
## (`cantidad` parejas; las de `fijo: true` siempre entran), asi que al rejugar cambia. Entre
## rondas hay mini-fiesta (confeti, baile de Coco, voz `ronda_superada`) y la estrella de la
## ronda se enciende arriba; `completado` sale una sola vez al final, con los destellos de todas.
## Un nivel sin `rondas` se juega exactamente como antes (Sofia y retos dorados intactos).
## Otros campos nuevos: `cartas_bailan` (N cartas a la vista cambian de lugar despacito tras cada
## acierto), `voz` por pareja (p. ej. "¡Chile!" o "¡S de sol!", en vez del acierto generico),
## `escala` y `voz_toque` por elemento, y los dibujos/banderas de `dibujos_emparejar.gd`.
##
## RETO REAL (HE-60, ficha §10.1, §10.1.1 y §10.2; PO 06-Oct-2026). Todo opcional y por datos: un nivel
## sin `puntaje` ni `vistazo` se juega exactamente como antes.
## - `puntaje.mostrar: "barra"` (Nicole y Sofia): racha x1-x5 con contador junto a Coco y nuditos en su
##   cresta, "¡a la primera!" (+200), "+N" que suben desde el par, barra de puntaje con banderita-cupcake
##   del record propio, vela del tiempo par (cupcake) y record personal al terminar.
## - `puntaje.mostrar: "solo_sonido"` (Maxi): solo la cresta y el "ding" que sube de tono. Sin numeros,
##   sin barra, sin vela ni record (GDD §6, regla de oro 2).
## - `vistazo`: al repartir, algunas cartas se muestran juntas un ratito (Nicole parejas completas,
##   Sofia cartas sueltas) en cada ronda tapada. No es una pista: no cuesta nada.
## - `umbrales_puntaje` (Nicole): 1-3 estrellitas por puntaje base (sin el bono de la vela).
## Las voces de reto aun no estan grabadas (HE-67): si falta una, suena la generica de siempre.
## Correcciones de las auditorias HE-60 (07-Oct-2026, UX y QA):
## - QA B1: la estacion, los destellos, las estrellitas y el record se guardan en el instante del ultimo par
##   (`asegurar_victoria` del contrato base), antes de la vela, el trofeo y la fiesta: salir es seguro.
## - QA M1: una presentacion de una sola vez ("vistazo", "vela") solo se marca si su voz existe y sono.
## - UX B1: sin las voces `vela_presenta` y `vela_dormida` no hay vela (una regla que no se puede explicar
##   por voz no se muestra).
## - UX M2: el vistazo siempre espera a que Coco calle y siempre dice "¡mira!".
## - UX M3: la vela recien se enciende despues de las voces de presentacion y de la consigna, y se pausa
##   mientras Coco o Cometa repiten una instruccion pedida, con el globo de la pista abierto y con la app
##   en segundo plano.

signal par_acertado(id_pareja: String)
signal intento_fallido()
signal nivel_fallado()
signal carta_intercambiada(a: CartaEmparejar, b: CartaEmparejar)
## Reto real (HE-60, ficha §10.9). `n` = pares seguidos sin "no es este" (0 = se corto).
signal racha_cambiada(n: int)
signal a_la_primera(id_pareja: String)
## La barra de puntaje paso la banderita del record propio (durante la partida, sin pausar).
signal record_superado()
## B4 (auditoria UX 18-Jul-2026): la senal de salida `salir_solicitado()` vive desde HE-10
## en el contrato base (`minijuego_base.gd`), comun a todos los motores.

const PistaConCosto := preload("res://scripts/ui/pista_con_costo.gd")
const BarraRecord := preload("res://scripts/ui/barra_record.gd")
const RachaCresta := preload("res://scripts/ui/racha_cresta.gd")
const VelaCupcake := preload("res://scripts/ui/vela_cupcake.gd")
const Cupcake := preload("res://scripts/ui/dibujo_cupcake.gd")
const CARTA_ESCENA: PackedScene = preload("res://escenas/minijuegos/emparejar/carta_emparejar.tscn")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const Icono := preload("res://scripts/motores/emparejar/icono_emparejar.gd")
const Dibujos := preload("res://scripts/motores/emparejar/dibujos_emparejar.gd")
const DESTELLOS_POR_PAR := 10
const DESTELLOS_POR_INTENTO_SOBRANTE := 2
## Zona del tablero en 1280x720: a la izquierda la anfitriona, arriba la barra de pares y
## abajo a la derecha Cometa.
const ZONA_TABLERO := Rect2(250, 122, 880, 584)
const SEPARACION := 14.0
const LADO_MAXIMO_CARTA := 210.0
## Modo visible (Semilla): cuanto dura el meneo del "no es este" antes de soltar las cartas.
const SEGUNDOS_NO_ES_ESTE_VISIBLE := 0.7
const SEGUNDOS_AYUDA := 1.3
## Rondas: cuanto dura la mini-fiesta antes de que las cartas se vayan, y el paseo de las
## cartas que bailan (lento a proposito: Maxi las sigue con la vista, no es un reto de memoria).
const SEGUNDOS_MINI_FIESTA := 2.6
const SEGUNDOS_BAILE := 1.4
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_VOLTEAR := "sfx/ui/seleccionar.ogg"
const SFX_TAPAR := "sfx/ui/soltar.ogg"
const SFX_PAR := "sfx/ui/confirmar.ogg"
const SFX_NO_ES_ESTE := "sfx/ui/no_es_este.ogg"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_GAG := "sfx/ui/abrir.ogg"
## UX HE-60 m2: sonidos propios suaves (nunca un tono grave tipo "wah-wah").
const SFX_PUF := "sfx/ui/puf.ogg"
const SFX_FIUU := "sfx/ui/fiuu.ogg"
const SFX_BLUP := "sfx/ui/blup.ogg"
## UX HE-60 m1: los toques durante el vistazo suenan bajito, con enfriamiento por carta.
const VOLUMEN_TOQUE_VISTAZO_DB := -12.0
const ENFRIAMIENTO_TOQUE_VISTAZO_MS := 150
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
## Reto real (HE-60): lugares fuera del tablero (ZONA_TABLERO va de x 250 a 1130). La barra del record a
## la derecha, bajo el medidor de estrellitas de la pista de Sofia y sobre Cometa; la vela bajo el boton de salir; el contador de racha
## sobre Coco.
const RECT_BARRA_RECORD := Rect2(1168, 172, 84, 396)
const RECT_VELA := Vector2(28, 126)
const RECT_CONTADOR_RACHA := Rect2(30, 222, 180, 92)
const SEGUNDOS_CASCADA_REPARTO := 0.035
const SEGUNDOS_CASCADA_TAPAR := 0.06
## Primera vez que un hermano ve el vistazo: se espera la intro (max) y se alarga un poco para la voz.
const SEGUNDOS_ESPERA_INTRO := 6.0
const SEGUNDOS_EXTRA_PRESENTACION := 1.5
## Tope de espera a que Coco termine una presentacion antes de encender la vela (UX M3).
const SEGUNDOS_ESPERA_PRESENTACION := 12.0
## UX m5: el trebol de "¡a la primera!" aterriza junto al contador xN (no sobre la vela).
const DESTINO_TREBOL := Vector2(120, 330)

@onready var _tablero: Control = %tablero
@onready var _mesa: Panel = %mesa
@onready var _efectos: Control = %efectos
@onready var _barra_progreso: PanelContainer = %barra_progreso
@onready var _progreso_pares: HBoxContainer = %progreso_pares
@onready var _anfitriona: TextureRect = %anfitriona
@onready var _boton_otra_vez: Button = %boton_otra_vez
@onready var _confeti: CPUParticles2D = %confeti
@onready var _boton_cometa: Button = %boton_cometa
@onready var _boton_salir: Button = %boton_salir
@onready var _panel_depuracion: Label = %panel_depuracion

var _cartas: Array[CartaEmparejar] = []
var _seleccionadas: Array[CartaEmparejar] = []
## Par de un "no es este" que sigue a la vista hasta taparse (o hasta el siguiente toque).
var _no_es_este: Array[CartaEmparejar] = []
var _procesando := false
var _id_resolucion := 0
var _ranuras: Array = []

var _pares_totales := 0
var _pares_acertados := 0
var _intentos_usados := 0
var _limite_intentos = null  ## null = infinito (contrato §4)
var _oculto := false
var _tiempo_volteo_ms := 1200
var _ayuda_tras_fallos := 0  ## 0 = sin ayuda automatica
var _fallos_seguidos := 0
## M-QA1 (QA 18-Jul-2026): una vez se dispara la derrota-gag, el bono de "intentos
## sobrantes" queda anulado para el resto de la partida (aunque se reintente), para que
## fallar a proposito + reintentar no pueda dar mas destellos que jugar limpio.
var _derrota_disparada := false
var _en_gag := false
var _lado_carta := 140.0
var _ultima_linea := ""
## Retos de Sofia (v3, PO 14-Sep-2026): trios (`tamano_grupo: 3`), cartas traviesas que cambian de
## lugar tras cada acierto (`intercambios_tras_acierto`), pistas que cuestan estrellita y regalo de
## un grupo tras 2 derrotas (`regalo_tras_derrotas`).
var _tamano_grupo := 2
var _intercambios := 0
var _pistas_usadas := 0
var _derrotas := 0
var _regalo_dado := false
var _boton_pista: Button
var _pista_costo: Control
## Umbrales de estrellitas del nivel ({"tres": N, "dos": M} en fallos; vacio = regla vieja).
var _umbrales: Dictionary = {}
## Nicole (HE-40 mecanicas #11): el par fallido se ve al menos esto aunque toque impaciente; el toque
## queda en espera (la carta pulsa al instante) y se aplica al cumplirse el minimo.
var _visible_minimo := 0.0
var _no_es_este_desde := 0.0
var _toques_en_espera: Array[CartaEmparejar] = []
var _espera_programada := false
## Rondas (Maxi y Nicole). `_conf` es el nivel con la ronda actual aplicada; sin rondas es el nivel.
var _conf: Dictionary = {}
var _rondas: Array = []
var _ronda := 0
var _pares_previos := 0  ## pares ganados en rondas anteriores (suman destellos)
var _en_transicion := false
var _bailes := 0
var _en_movimiento := {}
var _voces_par := {}
var _marcadores: Array = []

## Reto real (HE-60). `_reto` = bloque `puntaje` del nivel (vacio = sin reto: como antes).
var _reto: Dictionary = {}
var _con_barra := false  ## "barra": numeros, record y vela (Nicole/Sofia); si no, solo sonido y cresta
var _racha := 0
var _puntaje_base := 0  ## pares x racha + "a la primera" (las estrellitas de Nicole salen de aqui)
var _bono_vela := 0
var _record_previo := 0
var _pares_station := 0  ## pares de toda la estacion (todas las rondas), para la barra y los umbrales
## Cartas que ya estuvieron boca arriba alguna vez (vistazo, ayuda o toque): "a la primera" exige que
## todas las del par se den vuelta por primera vez en la misma jugada.
var _ya_vistas := {}
var _jugada_virgen := true
var _en_vistazo := false
var _vela_activa := false
var _vela_corriendo := false
var _vela_restante := 0.0
var _vela_total := 0.0
var _barra_record: Control
var _cresta: Control
var _vela: Control
var _contador_racha: Label
var _pompa: Control
var _trofeo: Control
## QA B1: el tablero final ya se gano (todo guardado); la vela ya no se enciende.
var _tablero_terminado := false
var _record_nuevo := false
## UX M3: pausas de la vela.
var _pausa_por_ayuda := false
var _app_en_pausa := false
var _ultimo_toque_vistazo := {}
## SOLO arneses QA: muestra la vela aunque falten sus voces (UX B1). En el juego siempre es false.
var vela_sin_voz_en_pruebas := false

var _tiempo := 0.0
var _base_anfitriona := Vector2.ZERO
var _salto_anfitriona := 0.0
var _tween_anfitriona: Tween


func _ready() -> void:
	super._ready()
	_boton_otra_vez.hide()
	_panel_depuracion.hide()
	_estilizar_interfaz()
	_crear_boton_pista()
	_boton_otra_vez.pressed.connect(_reintentar)
	_boton_cometa.pressed.connect(_al_tocar_cometa)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_anfitriona.mouse_filter = Control.MOUSE_FILTER_STOP
	_anfitriona.gui_input.connect(_al_tocar_anfitriona)
	_anfitriona.pivot_offset = Vector2(_anfitriona.size.x / 2.0, _anfitriona.size.y)
	_base_anfitriona = _anfitriona.position
	if nivel.is_empty():
		push_error("motor_emparejar: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_preparar_rondas()
	_conf = _config_de_ronda(0)
	_configurar_desde_nivel()
	_construir_marcadores_ronda()
	_construir_tablero()
	_construir_progreso()
	_preparar_reto()
	_boton_pista.visible = bool(nivel.get("pistas_cuestan_estrellita", false))
	_reproducir_voz("intro", _linea("intro"))
	_actualizar_depuracion()
	_arrancar_tablero()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	var bamboleo := absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0
	_anfitriona.position.y = _base_anfitriona.y - _salto_anfitriona - bamboleo
	_avanzar_vela(delta, hablando)


## UX M3: con la app en segundo plano (tablet) la vela no se consume.
func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_app_en_pausa = true
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_app_en_pausa = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()


func _configurar_desde_nivel() -> void:
	if _conf.is_empty():
		_conf = nivel
	_oculto = bool(_conf.get("oculto", false))
	_tiempo_volteo_ms = int(_conf.get("tiempo_volteo_ms", 1200))
	var limite = _conf.get("limite_intentos", null)
	_limite_intentos = int(limite) if limite != null else null
	var ayuda = _conf.get("ayuda_tras_fallos", null)
	_ayuda_tras_fallos = int(ayuda) if ayuda != null else 0
	_tamano_grupo = maxi(2, int(_conf.get("tamano_grupo", 2)))
	_intercambios = int(_conf.get("intercambios_tras_acierto", 0))
	_bailes = int(_conf.get("cartas_bailan", 0))
	_visible_minimo = float(_conf.get("visible_minimo_ms", 600 if obtener_perfil_dificultad() == "brote" else 0)) / 1000.0
	var umbrales = _conf.get("umbrales_estrellitas", nivel.get("umbrales_estrellitas", {}))
	_umbrales = umbrales if umbrales is Dictionary else {}
	_pares_totales = _grupos_del_nivel().size()


## Sortea el contenido de cada ronda desde su `pool` (una vez por partida: al rejugar cambia).
func _preparar_rondas() -> void:
	_rondas.clear()
	for ronda: Dictionary in nivel.get("rondas", []):
		var preparada: Dictionary = ronda.duplicate(true)
		if ronda.has("pool"):
			var fijos: Array = []
			var resto: Array = []
			for par: Dictionary in ronda["pool"]:
				if bool(par.get("fijo", false)):
					fijos.append(par)
				else:
					resto.append(par)
			resto.shuffle()
			var cantidad := int(ronda.get("cantidad", ronda["pool"].size()))
			var elegidos: Array = fijos.slice(0, cantidad)
			elegidos.append_array(resto.slice(0, maxi(0, cantidad - elegidos.size())))
			preparada["pares"] = elegidos
			preparada.erase("pool")
		_rondas.append(preparada)


## El nivel con la ronda `indice` aplicada encima (sin rondas: el nivel tal cual).
func _config_de_ronda(indice: int) -> Dictionary:
	if _rondas.is_empty():
		return nivel
	var conf: Dictionary = nivel.duplicate(true)
	conf.erase("rondas")
	var ronda: Dictionary = _rondas[mini(indice, _rondas.size() - 1)]
	for clave in ronda:
		if clave != "lineas_voz":
			conf[clave] = ronda[clave]
	if ronda.has("pares"):
		conf.erase("grupos")
	var voces: Dictionary = conf.get("lineas_voz", {}).duplicate()
	voces.merge(ronda.get("lineas_voz", {}), true)
	conf["lineas_voz"] = voces
	return conf


func _hay_rondas() -> bool:
	return _rondas.size() > 1


## Grupos de cartas iguales. `grupos` (trios) o, por compatibilidad, `pares` con elemento_a/elemento_b.
func _grupos_del_nivel() -> Array:
	var datos: Dictionary = nivel if _conf.is_empty() else _conf
	if datos.has("grupos"):
		return datos["grupos"]
	var grupos: Array = []
	for par: Dictionary in datos.get("pares", []):
		grupos.append({"id_grupo": par.get("id_pareja", ""), "especial": par.get("especial", false),
			"figura": par.get("figura", ""), "color": par.get("color", ""), "voz": par.get("voz", ""),
			"elementos": [par.get("elemento_a", {}), par.get("elemento_b", {})]})
	return grupos


func _construir_tablero() -> void:
	var elementos: Array = []
	_voces_par.clear()
	_ya_vistas.clear()
	_jugada_virgen = true
	for grupo: Dictionary in _grupos_del_nivel():
		if str(grupo.get("voz", "")) != "":
			_voces_par[str(grupo.get("id_grupo", ""))] = str(grupo["voz"])
		for info: Dictionary in grupo.get("elementos", []):
			var elemento := info.duplicate()
			elemento["id_pareja"] = grupo.get("id_grupo", "")
			elemento["figura"] = info.get("figura", grupo.get("figura", ""))
			elemento["color"] = info.get("color", grupo.get("color", ""))
			elemento["especial"] = grupo.get("especial", false)
			elementos.append(elemento)
	elementos.shuffle()

	var disposicion: Dictionary = _conf.get("disposicion", {})
	var columnas := maxi(1, int(disposicion.get("columnas", 4)))
	var filas := ceili(elementos.size() / float(columnas))
	_lado_carta = minf(LADO_MAXIMO_CARTA, minf(
		(ZONA_TABLERO.size.x - SEPARACION * (columnas - 1)) / columnas,
		(ZONA_TABLERO.size.y - SEPARACION * (filas - 1)) / filas))
	var medida := Vector2(columnas, filas) * _lado_carta + Vector2(columnas - 1, filas - 1) * SEPARACION
	var origen := ZONA_TABLERO.position + (ZONA_TABLERO.size - medida) / 2.0
	_mesa.position = origen - Vector2(22, 22)
	_mesa.size = medida + Vector2(44, 44)

	var halo_idle := bool(_conf.get("halo_idle", false))
	for i in elementos.size():
		var carta: CartaEmparejar = CARTA_ESCENA.instantiate()
		_tablero.add_child(carta)
		carta.size = Vector2.ONE * _lado_carta
		carta.position = origen + Vector2(i % columnas, i / columnas) * (_lado_carta + SEPARACION)
		carta.configurar(elementos[i], _oculto)
		carta.halo_idle = halo_idle
		carta.tocada.connect(_al_tocar_carta)
		carta.aparecer(0.15 + i * 0.035)
		_cartas.append(carta)


## Una ranura por par encontrado: se llena con la figura que vuela desde el tablero. Le
## muestra al nino cuanto le falta sin numeros ni texto.
func _construir_progreso() -> void:
	var lado := 76.0 if _pares_totales <= 5 else (62.0 if _pares_totales <= 10 else 44.0)
	for i in _pares_totales:
		var ranura := Icono.new()
		ranura.figura = ""
		ranura.con_disco = true
		ranura.custom_minimum_size = Vector2.ONE * lado
		ranura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_progreso_pares.add_child(ranura)
		_ranuras.append(ranura)


func _al_tocar_carta(carta: CartaEmparejar) -> void:
	if carta.esta_acertada or _en_gag or _en_transicion:
		return
	if _en_vistazo:
		# El vistazo no se puede saltar (ficha §10.2 punto 4): el toque solo hace el pulso suave y un
		# toquecito bajito (UX m1, GDD §6.5), con enfriamiento por carta para que un manotazo no haga rafaga.
		carta.pulso_espera()
		var ahora := Time.get_ticks_msec()
		if ahora - int(_ultimo_toque_vistazo.get(carta, -ENFRIAMIENTO_TOQUE_VISTAZO_MS)) >= ENFRIAMIENTO_TOQUE_VISTAZO_MS:
			_ultimo_toque_vistazo[carta] = ahora
			reproducir_sfx(SFX_TOQUE, 1.0, VOLUMEN_TOQUE_VISTAZO_DB)
		return

	if _procesando and _oculto and _visible_minimo > 0.0:
		var falta := _visible_minimo - (Time.get_ticks_msec() / 1000.0 - _no_es_este_desde)
		if falta > 0.0:
			carta.pulso_espera()
			if not _toques_en_espera.has(carta):
				_toques_en_espera.append(carta)
			if not _espera_programada:
				_espera_programada = true
				_despues(falta, _procesar_toque_en_espera)
			return

	if _procesando:
		# Tocar cualquier carta mientras se ve un "no es este" tapa el par al tiro y cuenta como
		# el primer toque de la jugada siguiente (si es una de las dos, queda a la vista).
		# B2: el toque nunca queda en silencio (GDD §6 regla 5): la seleccion trae su pulso.
		_terminar_no_es_este(carta)
		if _en_gag:
			return

	if _seleccionadas.has(carta):
		if _oculto:
			# En memoria no se re-tapa por un doble toque accidental: se perderia lo que ya vio.
			carta.pulso_espera()
			return
		# Toque 3 de la ficha: deseleccion voluntaria, sin penalidad ni conteo de intento.
		_seleccionadas.erase(carta)
		carta.deseleccionar(_oculto)
		return

	if _seleccionadas.is_empty():
		_jugada_virgen = true
	if _ya_vistas.has(carta) or not _oculto:
		_jugada_virgen = false
	_ya_vistas[carta] = true
	carta.seleccionar()
	reproducir_sfx(SFX_VOLTEAR)
	if carta.voz_toque != "":
		_reproducir_voz("toque", carta.voz_toque)
	_seleccionadas.append(carta)
	# Trios: el turno termina apenas una carta no coincide con la primera, o al completar el grupo.
	if carta.id_pareja != _seleccionadas[0].id_pareja or _seleccionadas.size() == _tamano_grupo:
		_resolver_par()
	_actualizar_depuracion()


func _resolver_par() -> void:
	var grupo: Array[CartaEmparejar] = _seleccionadas.duplicate()
	_seleccionadas.clear()
	var a: CartaEmparejar = grupo[0]

	var iguales := grupo.size() == _tamano_grupo
	for carta in grupo:
		iguales = iguales and carta.id_pareja == a.id_pareja
	if iguales:
		_fallos_seguidos = 0
		_pares_acertados += 1
		for carta in grupo:
			carta.marcar_acertada()
		var primera := _jugada_virgen and _oculto
		_jugada_virgen = false
		_sumar_acierto_reto(grupo, primera)
		par_acertado.emit(a.id_pareja)
		_celebrar_grupo(grupo)
		if _pares_acertados >= _pares_totales:
			_terminar_tablero(a)
		else:
			_reproducir_voz_acierto(a, primera)
			if _intercambios > 0:
				_despues(0.75, _intercambiar_cartas.bind(_intercambios))
			elif _bailes > 0:
				_despues(0.9, _intercambiar_cartas.bind(_bailes, true))
		_actualizar_depuracion()
		return

	if _limite_intentos != null:
		_intentos_usados += 1
	_fallos_seguidos += 1
	_jugada_virgen = false
	intento_fallido.emit()
	reproducir_sfx(SFX_NO_ES_ESTE)
	_cortar_racha()
	_reproducir_voz("no_es_este", _linea_al_azar("no_es_este"))
	for carta in grupo:
		carta.animar_no_es_este()
	_reaccion_anfitriona("menea")
	_actualizar_depuracion()

	_procesando = true
	_no_es_este_desde = Time.get_ticks_msec() / 1000.0
	_no_es_este = grupo
	_id_resolucion += 1
	var id := _id_resolucion
	var espera := _tiempo_volteo_ms / 1000.0 if _oculto else SEGUNDOS_NO_ES_ESTE_VISIBLE
	await get_tree().create_timer(espera).timeout
	if id == _id_resolucion:
		_terminar_no_es_este()


func _procesar_toque_en_espera() -> void:
	_espera_programada = false
	var cartas := _toques_en_espera.duplicate()
	_toques_en_espera.clear()
	for carta in cartas:
		if is_instance_valid(carta):
			_al_tocar_carta(carta)


func _terminar_no_es_este(excepto: CartaEmparejar = null) -> void:
	if not _procesando:
		return
	_procesando = false
	_id_resolucion += 1
	for carta in _no_es_este:
		if carta != excepto:
			carta.deseleccionar(_oculto)
	_no_es_este.clear()
	if _oculto:
		reproducir_sfx(SFX_TAPAR)
	if _limite_intentos != null and _intentos_usados >= _limite_intentos:
		_disparar_derrota_gag()
	elif _ayuda_tras_fallos > 0 and _fallos_seguidos >= _ayuda_tras_fallos:
		_fallos_seguidos = 0
		_dar_ayuda()


## Brote (ficha de motor §5): tras varios fallos seguidos, Coco "muestra un secretito":
## un par pendiente se destapa un momento con halo dorado.
func _dar_ayuda(con_voz := true, preferido := "") -> void:
	var pendientes := {}
	for carta in _cartas:
		if not carta.esta_acertada:
			if not pendientes.has(carta.id_pareja):
				pendientes[carta.id_pareja] = []
			pendientes[carta.id_pareja].append(carta)
	if pendientes.is_empty():
		return
	var claves := pendientes.keys()
	var elegido = preferido if pendientes.has(preferido) else claves[randi() % claves.size()]
	for carta in pendientes[elegido]:
		_ya_vistas[carta] = true
		carta.revelar_momento(SEGUNDOS_AYUDA)
	_reaccion_anfitriona("salta")
	if con_voz:
		_reproducir_voz("ayuda", _linea("ayuda"))


func _celebrar_grupo(grupo: Array) -> void:
	var medio := Vector2.ZERO
	for carta: CartaEmparejar in grupo:
		medio += carta.global_position + carta.size / 2.0
	medio /= grupo.size()
	var voladora: CartaEmparejar = grupo[0]
	for carta: CartaEmparejar in grupo:
		var centro := carta.global_position + carta.size / 2.0
		carta.saltar_hacia(medio)
		_estallido(centro, 8, [carta.color_figura, DORADO])
		# Vuela a la barra el dibujo (no la sombra, la mancha de color ni la letra); en "mama y
		# bebe", la mama.
		if _puntaje_voladora(carta) > _puntaje_voladora(voladora):
			voladora = carta
	var indice := _pares_acertados - 1
	if indice < _ranuras.size():
		_volar_a_ranura(voladora, medio, _ranuras[indice])
	_reaccion_anfitriona("salta")
	if voladora.especial:
		_arcoiris_especial()
		_confeti.restart()


func _puntaje_voladora(carta: CartaEmparejar) -> float:
	if carta.es_sombra() or carta.figura == "mancha":
		return 0.0
	if carta.figura in Figura.FIGURAS or Dibujos.tiene(carta.figura):
		return 2.0 + carta.escala
	return 1.0


## Cartas traviesas: `cantidad` pares de cartas tapadas cambian de lugar con un vuelo visible.
## Con `visibles` (cartas que bailan, Maxi): cartas a la vista pasean despacito a su nuevo lugar.
func _intercambiar_cartas(cantidad: int, visibles := false) -> void:
	if _en_gag or _en_transicion or _pares_acertados >= _pares_totales:
		return
	var libres: Array = []
	for carta in _cartas:
		if not carta.esta_acertada and (visibles or not carta.mostrando) and not _seleccionadas.has(carta) \
				and not _no_es_este.has(carta) and not _en_movimiento.has(carta):
			libres.append(carta)
	libres.shuffle()
	var duracion := SEGUNDOS_BAILE if visibles else 0.6
	for i in cantidad:
		if libres.size() < 2:
			break
		var a: CartaEmparejar = libres.pop_back()
		var b: CartaEmparejar = libres.pop_back()
		var lugar_a := a.position
		var lugar_b := b.position
		for par_movimiento in [[a, lugar_b], [b, lugar_a]]:
			var carta: CartaEmparejar = par_movimiento[0]
			_en_movimiento[carta] = true
			_tablero.move_child(carta, -1)
			var tween := carta.create_tween()
			tween.tween_property(carta, "scale", Vector2.ONE * 1.12, 0.12)
			tween.tween_property(carta, "position", par_movimiento[1], duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			if visibles:
				# Bailecito: se mece mientras camina.
				tween.parallel().tween_property(carta, "rotation", deg_to_rad(8.0), duracion / 4.0)
				tween.parallel().tween_property(carta, "rotation", deg_to_rad(-8.0), duracion / 2.0).set_delay(duracion / 4.0)
				tween.parallel().tween_property(carta, "rotation", 0.0, duracion / 4.0).set_delay(duracion * 0.75)
			tween.tween_property(carta, "scale", Vector2.ONE, 0.15)
			tween.tween_callback(func() -> void: _en_movimiento.erase(carta))
		carta_intercambiada.emit(a, b)
	reproducir_sfx(SFX_TAPAR)


## Coloca como acertado un grupo pendiente (regalo tras 2 derrotas). No suma estrellitas ni las quita.
func _regalar_grupo() -> void:
	for carta in _cartas:
		if carta.esta_acertada:
			continue
		var grupo: Array[CartaEmparejar] = []
		for otra in _cartas:
			if otra.id_pareja == carta.id_pareja and not otra.esta_acertada:
				grupo.append(otra)
		_pares_acertados += 1
		for otra in grupo:
			otra.marcar_acertada()
		reproducir_sfx(SFX_PAR)
		_celebrar_grupo(grupo)
		_reproducir_voz("regalo", _linea("regalo"))
		if _pares_acertados >= _pares_totales:
			_terminar_tablero(carta)
		_actualizar_depuracion()
		return


func _crear_boton_pista() -> void:
	_boton_pista = Button.new()
	_boton_pista.focus_mode = Control.FOCUS_NONE
	_boton_pista.tooltip_text = "Pista: muestra una pareja (cuesta una estrellita)"
	_boton_pista.custom_minimum_size = Vector2(96, 96)
	var padre: Control = _boton_salir.get_parent()
	padre.add_child(_boton_pista)
	padre.move_child(_boton_pista, _efectos.get_index())
	_boton_pista.position = Vector2(1164, 16)
	_boton_pista.size = Vector2(96, 96)
	_estilizar_boton(_boton_pista, DORADO)
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_pista.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(func() -> void:
		var c := icono.size / 2.0
		Figura.dibujar(icono, "estrella", Color("#FFF3B0"), c + Vector2(0, 3), 30.0, false)
		for p in [Vector2(-30, -26), Vector2(30, -22), Vector2(26, 30)]:
			var chispa := Figura.poligono("estrella", c + p, 8.0)
			icono.draw_colored_polygon(chispa, Color.WHITE)
			Figura.contornear(icono, chispa, 2.0))
	_boton_pista.pressed.connect(_al_tocar_pista)
	_boton_pista.hide()
	# Medidor de estrellitas y globo de confirmacion bajo el boton (HE-40 #4).
	_pista_costo = PistaConCosto.crear(padre, _boton_pista, _calcular_estrellitas)


## Pista de Sofia: Coco destapa un momento una pareja pendiente (la companera de la carta que ya tiene
## arriba, si hay: HE-40 #12). El 1.er toque abre el globo "¿te ayudo?"; tocarlo gasta la estrellita
## (HE-40 #4). Con 1 sola estrellita va directa y de regalo.
func _al_tocar_pista() -> void:
	if _en_gag or _pares_acertados >= _pares_totales:
		return
	_pista_costo.pedir(func(gratis: bool) -> bool:
		if _en_gag or _pares_acertados >= _pares_totales:
			return false
		var preferido := ""
		if not _seleccionadas.is_empty() and not _procesando:
			preferido = str(_seleccionadas[0].id_pareja)
		if _procesando:
			_terminar_no_es_este()
		_pistas_usadas += 1
		_dar_ayuda(false, preferido)
		if not gratis:
			_reproducir_voz("pista_usada", _linea("pista_usada"))
		_actualizar_depuracion()
		return true)


## Equivale a tocar el globo de confirmacion de la pista (arneses QA).
func confirmar_pista() -> void:
	_pista_costo.confirmar()


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()


func _volar_a_ranura(carta: CartaEmparejar, desde: Vector2, ranura) -> void:
	var volador := Icono.new()
	volador.figura = carta.figura
	volador.color = carta.color_figura
	volador.alegre = true
	volador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lado := _lado_carta * 0.6
	volador.size = Vector2.ONE * lado
	volador.pivot_offset = volador.size / 2.0
	_efectos.add_child(volador)
	volador.global_position = desde - volador.size / 2.0
	var destino: Vector2 = ranura.global_position + ranura.size / 2.0
	var escala_final: float = ranura.size.x * 0.68 / lado
	var tween := volador.create_tween()
	tween.tween_property(volador, "scale", Vector2.ONE * 1.25, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(volador, "global_position", destino - volador.size / 2.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(volador, "scale", Vector2.ONE * escala_final, 0.5)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(ranura):
			volador.queue_free()
			return
		ranura.figura = carta.figura
		ranura.color = carta.color_figura
		ranura.alegre = true
		ranura.pivot_offset = ranura.size / 2.0
		ranura.scale = Vector2.ONE * 1.35
		ranura.create_tween().tween_property(ranura, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_estallido(destino, 6, [DORADO, carta.color_figura], 0.6)
		volador.queue_free()
	)


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


## Momento memorable (ficha de nivel §7): un arcoiris cruza el tablero.
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


func _reproducir_voz_acierto(carta: CartaEmparejar, primera := false) -> void:
	# Pareja con nombre propio ("¡Chile!", "¡S de sol!"): se dice su nombre.
	if _voces_par.has(carta.id_pareja):
		_reproducir_voz("par", _voces_par[carta.id_pareja])
		return
	# Enganche del hallazgo especial (ficha de nivel §8): linea unica fuera del pool aleatorio.
	if carta.especial and _linea("acierto_especial") != "":
		_reproducir_voz("acierto_especial", _linea("acierto_especial"))
		return
	# Reto (HE-60): "¡a la primera!" y, desde la racha x2, la voz de racha REEMPLAZA a acierto_par
	# (guion §6: no suenan las dos). Si la linea aun no esta grabada, suena la generica.
	if _con_barra:
		if primera and _voz_existe(_linea_al_azar("a_la_primera")):
			_reproducir_voz("a_la_primera", _ultima_linea)
			return
		var voz_racha := _linea_racha()
		if voz_racha != "" and _voz_existe(voz_racha):
			_reproducir_voz("racha", voz_racha)
			return
	_reproducir_voz("acierto_par", _linea_al_azar("acierto_par"))


## Voz de la racha actual: x2..x5 por numero, y "sigue" estando en el tope.
func _linea_racha() -> String:
	if _racha < 2:
		return ""
	var voces = (nivel if _conf.is_empty() else _conf).get("lineas_voz", {}).get("racha", {})
	if not voces is Dictionary:
		return ""
	var tope := int(_reto.get("racha_tope", 5))
	if _racha > tope:
		return str(voces.get("sigue", voces.get(str(tope), "")))
	return str(voces.get(str(_racha), ""))


func _voz_existe(ruta: String) -> bool:
	var final := resolver_ruta_audio(ruta)
	return final != "" and ResourceLoader.exists(final)


func _linea(clave: String) -> String:
	var valor = (nivel if _conf.is_empty() else _conf).get("lineas_voz", {}).get(clave, "")
	if valor is Array:
		return str(valor[0]) if not valor.is_empty() else ""
	return str(valor)


## Elige una variante sin repetir la ultima, para que no suene monotono.
func _linea_al_azar(clave: String) -> String:
	var opciones = (nivel if _conf.is_empty() else _conf).get("lineas_voz", {}).get(clave, [])
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


## B3 (auditoria UX 18-Jul-2026): tocar a Cometa repite la instruccion (GDD §6.2, obligatoria).
func _al_tocar_cometa() -> void:
	reproducir_sfx(SFX_TOQUE)
	_reproducir_voz("pista", _linea("pista"))
	# UX M3: pedir ayuda no cuesta tiempo; la vela espera a que termine la instruccion.
	_pausa_por_ayuda = true


## Tocar a Coco: da un saltito y vuelve a explicar el juego.
func _al_tocar_anfitriona(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not toque:
		return
	reproducir_sfx(SFX_TOQUE)
	_reaccion_anfitriona("salta")
	# En rondas, Coco repite la consigna de la ronda en curso.
	if _ronda > 0 and _linea("intro_ronda") != "":
		_reproducir_voz("intro_ronda", _linea("intro_ronda"))
	else:
		_reproducir_voz("intro", _linea("intro"))
	_pausa_por_ayuda = true


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


## Derrota-gag (ficha de motor §6): las cartas pendientes se tapan, dan volteretas y se mezclan
## entre ellas; Coco se rie y aparece de inmediato el boton gigante "¡otra vez!".
func _disparar_derrota_gag() -> void:
	_derrota_disparada = true
	_derrotas += 1
	_en_gag = true
	nivel_fallado.emit()
	reproducir_sfx(SFX_GAG)
	_reproducir_voz("derrota_gag", _linea("derrota_gag"))
	_reaccion_anfitriona("rie")
	var pendientes: Array[CartaEmparejar] = []
	var lugares: Array[Vector2] = []
	for carta in _cartas:
		if not carta.esta_acertada:
			pendientes.append(carta)
			lugares.append(carta.position)
	lugares.shuffle()
	for i in pendientes.size():
		var carta := pendientes[i]
		carta.disabled = true
		carta.bailar_gag(i * 0.03)
		var tween := carta.create_tween()
		tween.tween_property(carta, "position", lugares[i], 0.55).set_delay(0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	_boton_otra_vez.show()
	_boton_otra_vez.pivot_offset = _boton_otra_vez.size / 2.0
	_boton_otra_vez.scale = Vector2.ZERO
	_boton_otra_vez.create_tween().tween_property(_boton_otra_vez, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_actualizar_depuracion()


func _reintentar() -> void:
	_boton_otra_vez.hide()
	_en_gag = false
	# Se resetea el contador solo para dar ritmo de juego al segundo intento (evita
	# retrigger inmediato de la derrota-gag ante el primer fallo). No reabre el bono de
	# puntaje: `_derrota_disparada` ya quedo en true y `_calcular_destellos()` lo respeta.
	_intentos_usados = 0
	_fallos_seguidos = 0
	_seleccionadas.clear()
	_no_es_este.clear()
	_procesando = false
	_id_resolucion += 1
	reproducir_sfx(SFX_TOQUE)
	for carta in _cartas:
		if not carta.esta_acertada:
			carta.reiniciar(_oculto)
	# Tras 2 derrotas, Coco regala un grupo ya encontrado (no cuesta estrellita): nunca queda trabada.
	if _derrotas >= 2 and bool(nivel.get("regalo_tras_derrotas", false)) and not _regalo_dado:
		_regalo_dado = true
		_despues(0.6, _regalar_grupo)
	_actualizar_depuracion()


## Tablero completo: si quedan rondas, mini-fiesta y siguiente ronda; si no, celebracion final.
func _terminar_tablero(ultima: CartaEmparejar) -> void:
	if _hay_rondas() and _ronda < _rondas.size() - 1:
		_fin_de_ronda(ultima)
	else:
		_celebrar_victoria(ultima)


func _celebrar_victoria(ultima: CartaEmparejar = null) -> void:
	# Confeti y bailecito de Coco mientras la ultima figura vuela a su ranura; despues, la
	# celebracion final reutilizable (HE-10). `celebrar()` emite `completado` al terminar.
	_en_transicion = _hay_rondas()
	_tablero_terminado = true
	_vela_corriendo = false
	# QA B1 (GDD §6 regla 8): TODO queda guardado en este instante, antes de la vela, el record y la
	# fiesta. La vela se cobra ya (lo que quede encendido); lo que viene despues es solo animacion.
	var destellos := _calcular_destellos()
	var estrellitas := _calcular_estrellitas()
	_bono_vela = _calcular_bono_vela()
	asegurar_victoria(destellos, estrellitas)
	var total := _puntaje_base + _bono_vela
	_record_nuevo = _con_barra and total > 0 and registrar_record(total)
	_confeti.restart()
	_reaccion_anfitriona("baila")
	_encender_marcador(_ronda)
	var espera := 0.9
	if ultima != null and _voces_par.has(ultima.id_pareja):
		# La ultima pareja tambien dice su nombre ("¡Japon!") antes de la fiesta final.
		_reproducir_voz("par", _voces_par[ultima.id_pareja])
		espera = 1.6
	await get_tree().create_timer(espera).timeout
	if not is_inside_tree():
		return
	# Reto (HE-60): la vela encendida se vuelve puntos y se registra el record ANTES de la fiesta.
	await _cobrar_vela()
	if not is_inside_tree():
		return
	await _cerrar_record()
	if not is_inside_tree():
		return
	_guardar_trofeo()
	celebrar(destellos, estrellitas, _linea_celebracion(estrellitas))


## Mini-fiesta entre rondas: confeti, Coco baila, se enciende la estrella de la ronda, las cartas
## se despiden y llega el tablero nuevo con su consigna.
func _fin_de_ronda(ultima: CartaEmparejar) -> void:
	_en_transicion = true
	_vela_corriendo = false
	_pares_previos += _pares_totales
	_confeti.restart()
	_reaccion_anfitriona("baila")
	_encender_marcador(_ronda)
	if _voces_par.has(ultima.id_pareja):
		_reproducir_voz("par", _voces_par[ultima.id_pareja])
		await _esperar_voz(2.2)
	else:
		await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return
	_reproducir_voz("ronda_superada", _linea_al_azar("ronda_superada"))
	await get_tree().create_timer(SEGUNDOS_MINI_FIESTA).timeout
	if not is_inside_tree():
		return
	for carta in _cartas:
		var tween := carta.create_tween().set_parallel(true)
		tween.tween_property(carta, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(carta, "modulate:a", 0.0, 0.35)
	for ranura in _ranuras:
		ranura.create_tween().tween_property(ranura, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.45).timeout
	if not is_inside_tree():
		return
	for carta in _cartas:
		carta.queue_free()
	_cartas.clear()
	for ranura in _ranuras:
		ranura.queue_free()
	_ranuras.clear()
	_en_movimiento.clear()
	_ronda += 1
	_iniciar_ronda()


func _iniciar_ronda() -> void:
	_conf = _config_de_ronda(_ronda)
	_configurar_desde_nivel()
	_seleccionadas.clear()
	_no_es_este.clear()
	_procesando = false
	_id_resolucion += 1
	_pares_acertados = 0
	_fallos_seguidos = 0
	_intentos_usados = 0
	_construir_tablero()
	_construir_progreso()
	_actualizar_marcadores()
	_reproducir_voz("intro_ronda", _linea("intro_ronda"))
	_en_transicion = false
	_actualizar_depuracion()
	_arrancar_tablero()


func _esperar_voz(maximo: float) -> void:
	var audio := get_node_or_null("/root/Audio")
	var inicio := Time.get_ticks_msec()
	await get_tree().process_frame
	while audio != null and audio.esta_hablando() and Time.get_ticks_msec() - inicio < maximo * 1000.0:
		await get_tree().process_frame


## Una estrella por ronda al comienzo de la barra: apagada, la actual brillando, las ganadas doradas.
func _construir_marcadores_ronda() -> void:
	if not _hay_rondas():
		return
	for i in _rondas.size():
		var marcador := Icono.new()
		marcador.figura = ""
		marcador.con_disco = true
		marcador.con_cara = false
		marcador.custom_minimum_size = Vector2.ONE * 46.0
		marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_progreso_pares.add_child(marcador)
		_marcadores.append(marcador)
	var separador := Control.new()
	separador.custom_minimum_size = Vector2(12, 0)
	separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progreso_pares.add_child(separador)
	_actualizar_marcadores()


func _actualizar_marcadores() -> void:
	for i in _marcadores.size():
		var marcador = _marcadores[i]
		if i < _ronda:
			marcador.con_disco = false
			marcador.figura = "estrella"
			marcador.color = DORADO
		elif i == _ronda:
			marcador.con_disco = true
			marcador.figura = "estrella"
			marcador.color = Color("#FFF3B0")
		else:
			marcador.con_disco = true
			marcador.figura = ""
		marcador.queue_redraw()


func _encender_marcador(indice: int) -> void:
	if indice >= _marcadores.size():
		return
	var marcador = _marcadores[indice]
	marcador.con_disco = false
	marcador.figura = "estrella"
	marcador.color = DORADO
	marcador.pivot_offset = marcador.size / 2.0
	marcador.scale = Vector2.ONE * 1.6
	marcador.create_tween().tween_property(marcador, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_estallido(marcador.global_position + marcador.size / 2.0, 8, [DORADO, TURQUESA], 0.7)


## Puntaje 1-3 estrellitas del perfil Estrella (ficha motor-emparejar §7). Con `umbrales_estrellitas`
## (HE-40): fallos <= tres -> 3, <= dos -> 2, si no 1. Sin el campo, la regla vieja: sin limite -> 3;
## con la mitad o mas de los intentos sobrantes -> 3; si no -> 2. Tras una derrota-gag -> 1. Ganar
## siempre da al menos 1. `celebrar()` solo las muestra en niveles Estrella.
func _calcular_estrellitas() -> int:
	if obtener_perfil_dificultad() == "brote" and nivel.has("umbrales_puntaje"):
		return _estrellitas_por_puntaje()
	var base := 3
	if _derrota_disparada:
		base = 1
	elif not _umbrales.is_empty():
		# disenador-niveles HE-40 §2.2: fallos <= tres -> 3, <= dos -> 2, si no 1.
		if _intentos_usados <= int(_umbrales.get("tres", 0)):
			base = 3
		elif _intentos_usados <= int(_umbrales.get("dos", 0)):
			base = 2
		else:
			base = 1
	elif _limite_intentos != null:
		var sobrantes: int = max(int(_limite_intentos) - _intentos_usados, 0)
		base = 3 if sobrantes * 2 >= int(_limite_intentos) else 2
	# Cada pista resta una estrellita (retos de Sofia), sin bajar de 1.
	return maxi(1, base - _pistas_usadas)


func _calcular_destellos() -> int:
	var total := (_pares_previos + _pares_totales) * DESTELLOS_POR_PAR
	# M-QA1 (QA 18-Jul-2026): el bono de "intentos sobrantes" solo tiene sentido si nunca
	# se agoto el limite. Si ya se disparo la derrota-gag (aunque se haya reintentado y
	# _intentos_usados se haya reseteado), el bono queda en 0 para toda la partida: asi
	# fallar a proposito + reintentar nunca puede superar el puntaje de jugar limpio.
	if _limite_intentos != null and not _derrota_disparada:
		var intentos_sobrantes: int = max(_limite_intentos - _intentos_usados, 0)
		total += intentos_sobrantes * DESTELLOS_POR_INTENTO_SOBRANTE
	return total


func _actualizar_depuracion() -> void:
	if not _panel_depuracion.visible:
		return
	var limite := "sin limite" if _limite_intentos == null else str(_limite_intentos)
	var reto := ""
	if not _reto.is_empty():
		reto = "
racha: %d · puntaje base: %d (+%d vela) · record previo: %d%s" % [_racha, _puntaje_base,
			_bono_vela, _record_previo, " · vela %.0f s" % _vela_restante if _vela_activa else ""]
	var ayuda := "no" if _ayuda_tras_fallos == 0 else "tras %d fallos seguidos" % _ayuda_tras_fallos
	var ronda := "" if not _hay_rondas() else " · ronda %d de %d" % [_ronda + 1, _rondas.size()]
	_panel_depuracion.text = "DEPURACION (F3)\nnivel: %s%s\nperfil: %s · juega: %s\npares: %d de %d\nfallos que cuentan: %d / %s\nfallos seguidos: %d · ayuda: %s\nderrota-gag ya ocurrio: %s\nsi termina ahora: %d destellos, %d estrellitas%s" % [
		nivel.get("id_nivel", "?"), ronda, obtener_perfil_dificultad(), obtener_id_personaje(),
		_pares_acertados, _pares_totales, _intentos_usados, limite, _fallos_seguidos, ayuda,
		"si" if _derrota_disparada else "no", _calcular_destellos(), _estrellitas_visibles(_calcular_estrellitas()), reto]


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
	barra.set_content_margin_all(10)
	barra.content_margin_left = 18
	barra.content_margin_right = 18
	_barra_progreso.add_theme_stylebox_override("panel", barra)

	var mesa := StyleBoxFlat.new()
	mesa.bg_color = Color(1.0, 0.97, 0.93, 0.22)
	mesa.border_color = Color(1, 1, 1, 0.5)
	mesa.set_border_width_all(3)
	mesa.set_corner_radius_all(40)
	_mesa.add_theme_stylebox_override("panel", mesa)

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


# ---------------------------------------------------------------------------
# Reto real (HE-60, ficha motor-emparejar §10.1, §10.1.1 y §10.2)
# ---------------------------------------------------------------------------

## Lee el bloque `puntaje` y arma lo que se ve: cresta (todos), y en "barra" el contador de racha, la
## barra con la banderita del record propio y la vela (si corresponde). Sin `puntaje`, nada cambia.
func _preparar_reto() -> void:
	_pares_station = _contar_pares_estacion()
	var reto = nivel.get("puntaje", null)
	_reto = reto if reto is Dictionary else {}
	if _reto.is_empty():
		return
	_con_barra = str(_reto.get("mostrar", "solo_sonido")) == "barra" and obtener_perfil_dificultad() != "semilla"
	_cresta = RachaCresta.new()
	_cresta.tope = int(_reto.get("racha_tope", 5))
	_cresta.mostrar_apagados = obtener_perfil_dificultad() != "semilla"
	_anfitriona.add_child(_cresta)
	if not _con_barra:
		return
	_record_previo = obtener_record()
	# Vela del tiempo par (UX M7): Sofia desde la primera partida; Nicole solo si ya tiene record en
	# esta estacion. `tiempo_par_s: null` (Nicole en la zona 1) = sin vela. UX B1: sin las voces que la
	# presentan y que acompanan su "puf", tampoco hay vela.
	var tiempo_par = _reto.get("tiempo_par_s", null)
	_vela_activa = tiempo_par != null and float(tiempo_par) > 0.0 \
		and (bool(_reto.get("vela_desde_primera", false)) or _record_previo > 0) \
		and _vela_explicable()
	var padre: Control = _boton_salir.get_parent()
	_barra_record = BarraRecord.new()
	padre.add_child(_barra_record)
	padre.move_child(_barra_record, _efectos.get_index())
	_barra_record.position = RECT_BARRA_RECORD.position
	_barra_record.size = RECT_BARRA_RECORD.size
	# UX M1: el alto se fija una sola vez aca (incluye el bono realista de la vela) y no cambia mas.
	_barra_record.preparar(_record_previo, _tope_barra())
	_barra_record.record_pasado.connect(_al_pasar_record)
	_barra_record.tocada.connect(_al_tocar_adorno)

	_contador_racha = Label.new()
	_contador_racha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contador_racha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contador_racha.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if ResourceLoader.exists(RUTA_FUENTE):
		_contador_racha.add_theme_font_override("font", load(RUTA_FUENTE))
	_contador_racha.add_theme_font_size_override("font_size", 64)
	_contador_racha.add_theme_color_override("font_color", DORADO)
	_contador_racha.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
	_contador_racha.add_theme_constant_override("outline_size", 14)
	padre.add_child(_contador_racha)
	padre.move_child(_contador_racha, _efectos.get_index())
	_contador_racha.position = RECT_CONTADOR_RACHA.position
	_contador_racha.size = RECT_CONTADOR_RACHA.size
	_contador_racha.pivot_offset = RECT_CONTADOR_RACHA.size / 2.0
	_contador_racha.hide()

	if _vela_activa:
		_vela_total = float(tiempo_par)
		_vela_restante = _vela_total
		_vela = VelaCupcake.new()
		# UX m3: para Sofia la vela es parte del reto y se tiene que leer de un vistazo.
		_vela.cera_larga = obtener_perfil_dificultad() == "estrella"
		padre.add_child(_vela)
		padre.move_child(_vela, _efectos.get_index())
		_vela.position = RECT_VELA
		_vela.tocada.connect(_al_tocar_adorno)


## UX B1: la vela solo se muestra si Coco puede presentarla y acompanar su "puf" con voz.
func _vela_explicable() -> bool:
	if vela_sin_voz_en_pruebas:
		return true
	return _voz_existe(_linea("vela_presenta")) and _voz_existe(_linea("vela_dormida"))


## UX m4: tocar la vela o la barra solo las menea con un "ding" suave (sin voz ni efecto en el juego).
func _al_tocar_adorno() -> void:
	reproducir_sfx(SFX_TOQUE, 1.5, -6.0)


func _contar_pares_estacion() -> int:
	if _rondas.is_empty():
		return _pares_totales
	var total := 0
	for ronda: Dictionary in _rondas:
		total += (ronda.get("grupos", ronda.get("pares", nivel.get("pares", []))) as Array).size()
	return total


## Alto sugerido de la barra: algo mas que el umbral de 3 estrellitas (Nicole) o ~x3 por par, mas el bono
## realista de la vela si la hay (mitad del tiempo par, UX M1). La barra usa max(record x 1.3, esto).
func _tope_barra() -> float:
	var base := float(_pares_station * int(_reto.get("por_par", 100)) * 3)
	var umbrales = nivel.get("umbrales_puntaje", null)
	if umbrales is Dictionary and umbrales.has("tres"):
		base = float(umbrales["tres"]) * 1.15
	if _vela_activa:
		base += float(_reto.get("tiempo_par_s", 0.0)) * float(_reto.get("bono_por_segundo", 10)) * 0.5
	return base


## Cada tablero nuevo (inicio o ronda): vistazo si toca y despues corre la vela.
func _arrancar_tablero() -> void:
	var ronda := _ronda
	if _hay_vistazo():
		await _hacer_vistazo()
		if not is_inside_tree() or ronda != _ronda:
			return
	if ronda == 0:
		# §10.1.1 punto 4: al volver a una estacion con 1 o 2 estrellitas, la pista de "otra estrellita".
		if obtener_perfil_dificultad() == "brote" and _estrellitas_visibles(1) > 0:
			var previas := obtener_estrellitas_previas()
			if previas == 1 or previas == 2:
				await _voz_cuando_calle("otra_estrellita", _linea("otra_estrellita"))
				if not is_inside_tree():
					return
		# QA M1: la presentacion solo se gasta si su voz existe y sono.
		var presenta := _linea("vela_presenta")
		if _vela_activa and not presentacion_vista("vela") and _voz_existe(presenta):
			await _voz_cuando_calle("vela_presenta", presenta)
			if not is_inside_tree():
				return
			marcar_presentacion_vista("vela")
	# UX M3: la vela recien se enciende cuando Coco termino de presentar y de dar la consigna.
	if _vela_activa:
		await _esperar_voz(SEGUNDOS_ESPERA_PRESENTACION)
		if not is_inside_tree() or ronda != _ronda:
			return
	_encender_vela()


func _hay_vistazo() -> bool:
	return _oculto and _conf.get("vistazo", null) is Dictionary and obtener_perfil_dificultad() != "semilla"


## Vistazo al repartir (§10.2): las elegidas se dan vuelta juntas con "¡mira!", una pompa se encoge
## mientras dura y revienta; despues se tapan en cascada. No se puede saltar ni cuesta nada.
func _hacer_vistazo() -> void:
	_en_vistazo = true
	var conf: Dictionary = _conf["vistazo"]
	var elegidas := _cartas_vistazo(conf)
	await get_tree().create_timer(0.15 + _cartas.size() * SEGUNDOS_CASCADA_REPARTO + 0.45).timeout
	if not is_inside_tree():
		return
	var segundos := float(conf.get("ms", 2000)) / 1000.0
	# UX M2: SIEMPRE se espera a que Coco termine (intro o consigna de la ronda): nadie memoriza cartas
	# mientras escucha una instruccion.
	await _esperar_voz(SEGUNDOS_ESPERA_INTRO)
	if not is_inside_tree():
		return
	var presenta := _linea("vistazo_presenta")
	if not presentacion_vista("vistazo") and _voz_existe(presenta):
		# Primera vez de este hermano: Coco lo cuenta como un secreto (en lugar de "¡mira!"). QA M1: solo
		# se da por presentado si la voz existe y sono.
		_reproducir_voz("vistazo_presenta", presenta)
		marcar_presentacion_vista("vistazo")
		segundos += SEGUNDOS_EXTRA_PRESENTACION
	else:
		# UX M2: siempre "¡mira!" justo antes de dar vuelta las cartas.
		_reproducir_voz("vistazo", _linea("vistazo"))
	reproducir_sfx(SFX_VOLTEAR, 1.2)
	for carta: CartaEmparejar in elegidas:
		_ya_vistas[carta] = true
		carta.destapar_vistazo()
		_estallido(carta.global_position + carta.size / 2.0, 5, [Color.WHITE, DORADO], 0.5)
	_mostrar_pompa(segundos)
	await get_tree().create_timer(segundos).timeout
	if not is_inside_tree():
		return
	for carta: CartaEmparejar in elegidas:
		if is_instance_valid(carta):
			carta.tapar_vistazo()
		await get_tree().create_timer(SEGUNDOS_CASCADA_TAPAR).timeout
		if not is_inside_tree():
			return
	reproducir_sfx(SFX_TAPAR)
	await get_tree().create_timer(0.2).timeout
	_en_vistazo = false


## Cuales se muestran (M6, aceptado por el PO): parejas completas (Nicole: 1 par con <= 10 cartas, 2 con
## 12-16) o cartas sueltas sin repetir grupo (Sofia: round(cartas/4)). `cartas` numerico pisa el "auto".
func _cartas_vistazo(conf: Dictionary) -> Array:
	var cantidad = conf.get("cartas", "auto")
	var auto: bool = not (cantidad is float or cantidad is int)
	var por_grupo := {}
	for carta in _cartas:
		if not carta.esta_acertada:
			if not por_grupo.has(carta.id_pareja):
				por_grupo[carta.id_pareja] = []
			por_grupo[carta.id_pareja].append(carta)
	var ids := por_grupo.keys()
	ids.shuffle()
	var elegidas: Array = []
	if bool(conf.get("pares_completos", obtener_perfil_dificultad() == "brote")):
		var grupos := (1 if _cartas.size() <= 10 else 2) if auto else maxi(1, int(cantidad) / _tamano_grupo)
		for id in ids.slice(0, grupos):
			elegidas.append_array(por_grupo[id])
	else:
		var sueltas := roundi(_cartas.size() / 4.0) if auto else int(cantidad)
		for id in ids.slice(0, sueltas):
			var grupo: Array = por_grupo[id]
			elegidas.append(grupo[randi() % grupo.size()])
	return elegidas


## Pompa de jabon sobre el tablero que se encoge mientras dura el vistazo y revienta al final.
func _mostrar_pompa(segundos: float) -> void:
	if _pompa != null and is_instance_valid(_pompa):
		_pompa.queue_free()
	var pompa := Control.new()
	_pompa = pompa
	pompa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efectos.add_child(pompa)
	# QA m4: mas grande y con contorno oscuro para que se vea sobre la barra de marcadores (es la senal
	# de "esto dura poco"). Nace sobre el borde de arriba de la mesa, sin tapar cartas.
	var centro := _mesa.position + Vector2(_mesa.size.x / 2.0, 2.0)
	var estado := {"radio": 46.0}
	pompa.draw.connect(func() -> void:
		var r: float = estado["radio"]
		pompa.draw_circle(centro, r, Color(0.75, 0.95, 1.0, 0.6))
		pompa.draw_arc(centro, r + 2.0, 0, TAU, 48, Color(COLOR_CONTORNO, 0.55), 3.0, true)
		pompa.draw_arc(centro, r, 0, TAU, 48, Color(1, 1, 1, 0.95), 4.0, true)
		pompa.draw_arc(centro, r * 0.7, -2.4, -1.4, 12, Color(1, 1, 1, 0.95), 4.0, true)
		pompa.draw_circle(centro + Vector2(r * 0.35, -r * 0.4), maxf(2.0, r * 0.12), Color(1, 1, 1, 0.9)))
	var tween := pompa.create_tween()
	tween.tween_method(func(valor: float) -> void:
		estado["radio"] = valor
		pompa.queue_redraw()
	, 46.0, 14.0, segundos)
	tween.tween_callback(func() -> void:
		_estallido(centro, 6, [Color.WHITE, Color("#BDEFFF")], 0.45)
		pompa.queue_free())


## Pareja formada con reto: racha, "ding" un semitono mas agudo por eslabon, cresta y (en barra) puntos.
func _sumar_acierto_reto(grupo: Array, primera: bool) -> void:
	if _reto.is_empty():
		reproducir_sfx(SFX_PAR)
		return
	_racha += 1
	var tope := int(_reto.get("racha_tope", 5))
	var multiplicador := mini(_racha, tope)
	reproducir_sfx(SFX_PAR, pow(2.0, (multiplicador - 1) / 12.0))
	_cresta.fijar(multiplicador)
	racha_cambiada.emit(_racha)
	if not _con_barra:
		return
	# m10: los numeros nacen SOBRE las cartas del par (ya destapadas), nunca entre ellas: si el par esta
	# lejos, el punto medio cae sobre cartas tapadas.
	var ultima: CartaEmparejar = grupo.back()
	var primera_carta: CartaEmparejar = grupo[0]
	var puntos := int(_reto.get("por_par", 100)) * multiplicador
	_puntaje_base += puntos
	_flotar_puntos("+%d" % puntos, ultima.global_position + ultima.size * Vector2(0.5, 0.42), ultima.color_figura)
	if primera:
		var bono := int(_reto.get("bono_a_la_primera", 200))
		_puntaje_base += bono
		_sello_a_la_primera(grupo, primera_carta.global_position + primera_carta.size * Vector2(0.5, 0.42), bono)
		a_la_primera.emit(str((grupo[0] as CartaEmparejar).id_pareja))
	_actualizar_contador_racha()
	if _barra_record.fijar_puntaje(_puntaje_base + _bono_vela):
		reproducir_sfx(SFX_BLUP, 1.0 + 0.05 * mini(_racha, 5))


## Un "no es este" corta la racha: los nuditos se apagan de a uno con un "fiuu" suave. Nunca resta puntos.
func _cortar_racha() -> void:
	if _reto.is_empty() or _racha == 0:
		return
	_racha = 0
	racha_cambiada.emit(0)
	_cresta.apagar_de_a_uno()
	# UX m2: "fiuu" suave propio, nunca grave. UX m7: en Semilla (Maxi) los nuditos se apagan en silencio.
	if obtener_perfil_dificultad() != "semilla":
		reproducir_sfx(SFX_FIUU)
	if _contador_racha != null and _contador_racha.visible:
		var tween := _contador_racha.create_tween()
		tween.tween_property(_contador_racha, "modulate:a", 0.0, 0.3)
		tween.tween_callback(_contador_racha.hide)


func _actualizar_contador_racha() -> void:
	if _contador_racha == null:
		return
	if _racha < 2:
		_contador_racha.hide()
		return
	_contador_racha.text = "×%d" % mini(_racha, int(_reto.get("racha_tope", 5)))
	_contador_racha.show()
	_contador_racha.modulate.a = 1.0
	_contador_racha.scale = Vector2.ONE * 1.45
	_contador_racha.create_tween().tween_property(_contador_racha, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Numeros que suben flotando 0,6 s desde el par que se va (m10: nunca sobre una carta tapada).
func _flotar_puntos(texto: String, centro: Vector2, color: Color, tamano := 44) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ResourceLoader.exists(RUTA_FUENTE):
		etiqueta.add_theme_font_override("font", load(RUTA_FUENTE))
	etiqueta.add_theme_font_size_override("font_size", tamano)
	# Crema con borde del color de la carta: se lee sobre cualquier dibujo o fondo.
	etiqueta.add_theme_color_override("font_color", Color("#FFF8EE"))
	etiqueta.add_theme_color_override("font_outline_color", color.darkened(0.45))
	etiqueta.add_theme_constant_override("outline_size", 14)
	_efectos.add_child(etiqueta)
	etiqueta.size = Vector2(200, tamano * 1.4)
	etiqueta.global_position = centro - etiqueta.size / 2.0
	var tween := etiqueta.create_tween().set_parallel(true)
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 36.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.chain().tween_callback(etiqueta.queue_free)


## "¡A la primera!": aro dorado en cada carta del par, campanita doble y un trebol dorado que vuela al
## costado. UX m5: ya no hay estela entre las cartas (cruzaba cartas tapadas); el aro no sale de la carta.
func _sello_a_la_primera(grupo: Array, origen: Vector2, bono: int) -> void:
	for carta: CartaEmparejar in grupo:
		_estallido(carta.global_position + carta.size / 2.0, 6, [DORADO, Color("#FFF3B0")], 0.8)
		_aro_dorado(carta)
	reproducir_sfx(SFX_PAR, 1.5)
	_despues(0.13, func() -> void: reproducir_sfx(SFX_PAR, 1.78))
	_flotar_puntos("+%d" % bono, origen, DORADO, 36)
	var trebol := Control.new()
	trebol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trebol.size = Vector2(72, 72)
	trebol.pivot_offset = trebol.size / 2.0
	_efectos.add_child(trebol)
	trebol.draw.connect(func() -> void: Cupcake.trebol(trebol, trebol.size / 2.0, 30.0))
	trebol.global_position = origen - trebol.size / 2.0
	trebol.scale = Vector2.ZERO
	var destino := DESTINO_TREBOL - trebol.size / 2.0
	var tween := trebol.create_tween()
	tween.tween_property(trebol, "scale", Vector2.ONE * 1.3, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(trebol, "position", destino, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(trebol, "scale", Vector2.ONE * 0.8, 0.6)
	tween.parallel().tween_property(trebol, "rotation", TAU, 0.6)
	tween.tween_property(trebol, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.tween_callback(trebol.queue_free)


## La barra paso la banderita: salta (lo hace la barra), confeti chico y "¡record!". No se pausa.
func _al_pasar_record() -> void:
	record_superado.emit()
	_estallido(_barra_record.punto_banderita(), 10, Figura.COLORES_ARCOIRIS, 0.7)
	reproducir_sfx(SFX_PAR, 1.6)
	_despues(0.6, func() -> void: _reproducir_voz("record_pasa", _linea("record_pasa")))


func _encender_vela() -> void:
	if _vela_activa and _vela != null and _vela_restante > 0.0 and not _tablero_terminado and not _en_transicion:
		_vela_corriendo = true


## La vela se consume solo mientras se juega (no en el vistazo, la mini-fiesta ni el gag). Sin tic-tac,
## sin parpadeo ni aceleracion (M7). Al acabarse: "puf" suave y Coco dice algo positivo; nada mas.
## UX M3: tampoco corre mientras Coco o Cometa repiten una instruccion que el nino pidio, con el globo de
## la pista abierto ni con la app en segundo plano.
func _avanzar_vela(delta: float, hablando := false) -> void:
	if not _vela_corriendo or _en_transicion or _en_vistazo or _en_gag or _app_en_pausa:
		return
	if _pausa_por_ayuda:
		if hablando:
			return
		_pausa_por_ayuda = false
	if _pista_costo != null and _pista_costo.globo_abierto():
		return
	_vela_restante = maxf(0.0, _vela_restante - delta)
	_vela.fraccion = _vela_restante / maxf(0.001, _vela_total)
	if _vela_restante <= 0.0:
		_vela_corriendo = false
		_vela.dormir()
		reproducir_sfx(SFX_PUF)
		_voz_cuando_calle("vela_dormida", _linea("vela_dormida"), 2.5)


## Bono de la vela que sigue encendida al terminar (0 si no hay vela o ya se durmio).
func _calcular_bono_vela() -> int:
	if not _vela_activa or _vela == null or _vela_restante <= 0.0:
		return 0
	return ceili(_vela_restante) * int(_reto.get("bono_por_segundo", 10))


## Fin de la estacion con la vela encendida: sus segundos se vuelven puntos con tintineo. El bono ya se
## calculo y guardo en `_celebrar_victoria` (QA B1); esto es solo la animacion.
func _cobrar_vela() -> void:
	if _bono_vela <= 0 or _vela == null:
		return
	var segundos := ceili(_vela_restante)
	_reproducir_voz("vela_encendida", _linea("vela_encendida"))
	var centro := _vela.global_position + _vela.size / 2.0
	var pasos := clampi(segundos, 1, 8)
	for i in pasos:
		reproducir_sfx(SFX_TOQUE, pow(2.0, i * 2.0 / 12.0))
		_barra_record.fijar_puntaje(_puntaje_base + int(_bono_vela * (i + 1) / float(pasos)))
		_estallido(centro, 3, [DORADO], 0.4)
		await get_tree().create_timer(0.09).timeout
		if not is_inside_tree():
			return
	_flotar_puntos("+%d" % _bono_vela, centro + Vector2(70, 0), DORADO, 36)
	await get_tree().create_timer(0.6).timeout


## Record personal al terminar (§10.1): ya quedo guardado en el instante del ultimo par (QA B1). Sin record
## previo, la banderita se clava ("¡tu primer record!", m6); si se supero, Coco muestra el trofeo-cupcake.
## Nunca el de otro.
func _cerrar_record() -> void:
	if not _record_nuevo:
		return
	if _record_previo <= 0:
		_barra_record.plantar_banderita()
		_estallido(_barra_record.punto_banderita(), 10, Figura.COLORES_ARCOIRIS, 0.7)
		_reproducir_voz("primer_record", _linea("primer_record"))
	else:
		_mostrar_trofeo()
		_reproducir_voz("record_nuevo", _linea_al_azar("record_nuevo"))
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		await _esperar_voz(3.5)


## QA m3: Coco SOSTIENE el trofeo delante del cuerpo (hijo de su sprite, asi salta y baila con ella) y no
## tapa la cresta ni el tablero. Se guarda antes de la celebracion para que no quede detras.
func _mostrar_trofeo() -> void:
	var trofeo := Control.new()
	_trofeo = trofeo
	trofeo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trofeo.size = Vector2(130, 150)
	trofeo.pivot_offset = Vector2(65, 150)
	_anfitriona.add_child(trofeo)
	trofeo.draw.connect(func() -> void: Cupcake.trofeo(trofeo, Vector2(65, 146), 110.0))
	# Pie del trofeo a la altura de la panza de Coco, centrado un poco a su derecha (su mano).
	trofeo.position = Vector2(_anfitriona.size.x / 2.0 - 65 + 18, _anfitriona.size.y * 0.92 - 150)
	trofeo.scale = Vector2.ZERO
	trofeo.create_tween().tween_property(trofeo, "scale", Vector2.ONE * 0.8, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_estallido(trofeo.global_position + Vector2(65, 100), 12, Figura.COLORES_ARCOIRIS)
	_reaccion_anfitriona("salta")


func _guardar_trofeo() -> void:
	if _trofeo == null or not is_instance_valid(_trofeo):
		return
	var trofeo := _trofeo
	_trofeo = null
	var tween := trofeo.create_tween()
	tween.tween_property(trofeo, "modulate:a", 0.0, 0.25)
	tween.tween_callback(trofeo.queue_free)


## UX m5: aro dorado que late DENTRO de la carta del par (no cruza ni tapa cartas vecinas).
func _aro_dorado(carta: CartaEmparejar) -> void:
	var aro := Control.new()
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efectos.add_child(aro)
	aro.size = carta.size
	aro.global_position = carta.global_position
	var estado := {"t": 0.0}
	aro.draw.connect(func() -> void:
		var t: float = estado["t"]
		var lado: float = aro.size.x
		var r := lado * (0.3 + 0.16 * t)
		aro.draw_arc(aro.size / 2.0, r, 0, TAU, 40, Color(DORADO, 0.95 * (1.0 - t)), maxf(3.0, lado * 0.05), true))
	var tween := aro.create_tween()
	tween.tween_method(func(valor: float) -> void:
		estado["t"] = valor
		aro.queue_redraw()
	, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(aro.queue_free)


## Estrellitas de Nicole (§10.1.1): por puntaje BASE (sin la vela). Terminar ya da 1.
func _estrellitas_por_puntaje() -> int:
	var umbrales = nivel.get("umbrales_puntaje", {})
	if not umbrales is Dictionary:
		umbrales = {}
	var dos := int(umbrales.get("dos", 150 * _pares_station))
	var tres := int(umbrales.get("tres", 230 * _pares_station))
	if _puntaje_base >= tres:
		return 3
	if _puntaje_base >= dos:
		return 2
	return 1


## Voz de la fiesta final: Nicole con estrellitas por puntaje oye la de su logro (nunca lo que falto).
func _linea_celebracion(estrellitas: int) -> String:
	var visibles := _estrellitas_visibles(estrellitas)
	if obtener_perfil_dificultad() == "brote" and visibles > 0:
		var voces = nivel.get("lineas_voz", {}).get("estrellitas_brote", {})
		if voces is Dictionary:
			var ruta := str(voces.get(str(visibles), ""))
			if _voz_existe(ruta):
				return ruta
	return _linea("victoria_final")


## Voz que espera a que Coco termine de hablar (presentaciones de una sola vez, pistas), sin pisar otra.
func _voz_cuando_calle(clave: String, ruta: String, maximo := SEGUNDOS_ESPERA_INTRO) -> void:
	if ruta == "":
		return
	await _esperar_voz(maximo)
	if is_inside_tree():
		_reproducir_voz(clave, ruta)
