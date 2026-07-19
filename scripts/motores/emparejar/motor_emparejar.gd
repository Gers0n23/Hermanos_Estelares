class_name MotorEmparejar
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecanica "emparejar" (docs/fichas/motor-emparejar.md).
## Agnostico de tema: carga el tablero completo desde `nivel` (JSON, contrato §4 de la
## ficha) y aplica las reglas de escalado por perfil que ya vienen resueltas en los datos
## (cantidad de pares, oculto, tiempo_volteo_ms, limite_intentos). No conoce ponys,
## dinosaurios ni ningun tema concreto.
##
## PILOTO DE PROCESO (18-Jul-2026): sin sprites/audio finales. Las voces quedan como
## TODO impresos en consola con el ID de linea que le corresponderia reproducir via el
## autoload `Audio` (aun no implementado en el proyecto).

signal par_acertado(id_pareja: String)
signal intento_fallido()
signal nivel_fallado()
## B4 (auditoria UX 18-Jul-2026): hook de salida. El nodo padre (futuro contenedor de
## pantalla, ver GDD §6 regla 8 "salir siempre es seguro") debe conectar esta senal para
## navegar de vuelta al mapa sin perder progreso. Este motor no navega por si mismo.
signal salir_solicitado()

const CARTA_ESCENA: PackedScene = preload("res://escenas/minijuegos/emparejar/carta_emparejar.tscn")
const DESTELLOS_POR_PAR := 10
const DESTELLOS_POR_INTENTO_SOBRANTE := 2

@onready var _tablero: GridContainer = %tablero
@onready var _boton_otra_vez: Button = %boton_otra_vez
@onready var _etiqueta_gag: Label = %etiqueta_gag
@onready var _confeti: CPUParticles2D = %confeti
@onready var _contador_destellos: Label = %contador_destellos
@onready var _boton_estelita: Button = %boton_estelita
@onready var _boton_salir: Button = %boton_salir

var _cartas: Array[CartaEmparejar] = []
var _seleccionadas: Array[CartaEmparejar] = []
var _procesando := false

var _pares_totales := 0
var _pares_acertados := 0
var _intentos_usados := 0
var _limite_intentos = null  ## null = infinito (contrato §4)
var _oculto := false
var _tiempo_volteo_ms := 1200
## M-QA1 (QA 18-Jul-2026): una vez se dispara la derrota-gag, el bono de "intentos
## sobrantes" queda anulado para el resto de la partida (aunque se reintente), para que
## fallar a proposito + reintentar no pueda dar mas destellos que jugar limpio.
var _derrota_disparada := false

## Identifica la carta "en espera de volteo" vigente, para que un timeout viejo no
## desactive por error a una carta seleccionada mas tarde.
var _id_esperando_volteo := ""


func _ready() -> void:
	super._ready()
	_boton_otra_vez.hide()
	_etiqueta_gag.hide()
	_contador_destellos.hide()
	if nivel.is_empty():
		push_error("motor_emparejar: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()
	_construir_tablero()
	_boton_otra_vez.pressed.connect(_reintentar)
	_boton_estelita.pressed.connect(_al_tocar_estelita)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_reproducir_voz("intro", nivel.get("lineas_voz", {}).get("intro", ""))


func _configurar_desde_nivel() -> void:
	_oculto = nivel.get("oculto", false)
	_tiempo_volteo_ms = nivel.get("tiempo_volteo_ms", 1200)
	_limite_intentos = nivel.get("limite_intentos", null)
	_pares_totales = nivel.get("pares", []).size()


func _construir_tablero() -> void:
	var disposicion: Dictionary = nivel.get("disposicion", {})
	_tablero.columns = disposicion.get("columnas", 4)

	var elementos: Array = []
	for par: Dictionary in nivel.get("pares", []):
		var id_pareja: String = par.get("id_pareja", "")
		for clave in ["elemento_a", "elemento_b"]:
			var info: Dictionary = par.get(clave, {})
			elementos.append({
				"id_pareja": id_pareja,
				"id_elemento": info.get("id", ""),
				"sprite": info.get("sprite", ""),
			})
	elementos.shuffle()

	for datos_elemento in elementos:
		var carta: CartaEmparejar = CARTA_ESCENA.instantiate()
		_tablero.add_child(carta)
		carta.configurar(datos_elemento["id_pareja"], datos_elemento["id_elemento"], datos_elemento["sprite"], _oculto)
		carta.tocada.connect(_al_tocar_carta)
		_cartas.append(carta)


func _al_tocar_carta(carta: CartaEmparejar) -> void:
	if carta.esta_acertada:
		return

	if _procesando:
		# B2 (auditoria UX 18-Jul-2026): mientras se resuelve un "no es este" (~500 ms),
		# el toque no se ignora en silencio: se confirma con un pulso minimo aunque no
		# sume a la seleccion todavia (GDD §6 regla 5, respuesta <100 ms a todo toque).
		carta.pulso_espera()
		return

	if _seleccionadas.has(carta):
		# Toque 3 de la ficha: deseleccion voluntaria, sin penalidad ni conteo de intento.
		_seleccionadas.erase(carta)
		carta.deseleccionar(_oculto)
		_id_esperando_volteo = ""
		return

	if _seleccionadas.size() >= 2:
		return

	carta.seleccionar()
	_seleccionadas.append(carta)

	if _seleccionadas.size() == 1:
		if _oculto:
			_iniciar_temporizador_volteo(carta)
	else:
		_id_esperando_volteo = ""
		_resolver_par()


func _iniciar_temporizador_volteo(carta: CartaEmparejar) -> void:
	# Fila 4 de la ficha: en modo memoria, si no se completa el par a tiempo se re-tapa.
	_id_esperando_volteo = carta.id_elemento
	var temporizador := get_tree().create_timer(_tiempo_volteo_ms / 1000.0)
	temporizador.timeout.connect(func() -> void:
		if _id_esperando_volteo == carta.id_elemento and _seleccionadas.size() == 1 and _seleccionadas[0] == carta:
			_seleccionadas.erase(carta)
			carta.deseleccionar(_oculto)
			_id_esperando_volteo = ""
	)


func _resolver_par() -> void:
	_procesando = true
	var a: CartaEmparejar = _seleccionadas[0]
	var b: CartaEmparejar = _seleccionadas[1]

	if a.id_pareja == b.id_pareja:
		a.marcar_acertada()
		b.marcar_acertada()
		_pares_acertados += 1
		_seleccionadas.clear()
		par_acertado.emit(a.id_pareja)
		_reproducir_voz_acierto(a.id_pareja)
		_procesando = false
		if _pares_acertados >= _pares_totales:
			_celebrar_victoria()
		return

	if _limite_intentos != null:
		_intentos_usados += 1
	intento_fallido.emit()
	_reproducir_voz_no_es_este()
	a.animar_no_es_este()
	b.animar_no_es_este()

	await get_tree().create_timer(0.5).timeout

	a.deseleccionar(_oculto)
	b.deseleccionar(_oculto)
	_seleccionadas.clear()
	_procesando = false

	if _limite_intentos != null and _intentos_usados >= _limite_intentos:
		_disparar_derrota_gag()


func _reproducir_voz_acierto(id_pareja: String) -> void:
	var voces: Dictionary = nivel.get("lineas_voz", {})
	# Enganche del hallazgo especial pedido por disenador-niveles (§8 de la ficha de
	# nivel): linea unica fuera del pool aleatorio para el par secreto, via la senal
	# par_acertado(id_pareja) que el motor ya expone.
	if id_pareja == "pony_arcoiris_secreto":
		_reproducir_voz("acierto_par_secreto", "voces/emparejar/estrella_ponys/acierto_par_secreto_01.ogg")
		_animar_arcoiris_secreto()
		return
	var opciones: Array = voces.get("acierto_par", [])
	if not opciones.is_empty():
		_reproducir_voz("acierto_par", opciones[randi() % opciones.size()])


func _animar_arcoiris_secreto() -> void:
	# Micro-celebracion extra del "momento memorable" (ficha de nivel §7): placeholder
	# de un destello de confeti corto sobre el tablero completo.
	_confeti.emitting = true


func _reproducir_voz_no_es_este() -> void:
	var voces: Dictionary = nivel.get("lineas_voz", {})
	var opciones: Array = voces.get("no_es_este", [])
	if not opciones.is_empty():
		_reproducir_voz("no_es_este", opciones[randi() % opciones.size()])


func _reproducir_voz(clave: String, ruta: String) -> void:
	# TODO(voz): reemplazar por Audio.reproducir_voz(ruta) cuando exista el autoload Audio
	# (docs/stack-tecnico.md §2). Por ahora solo deja constancia en consola para el smoke test.
	if ruta != "":
		print("[voz TODO:%s] %s" % [clave, ruta])


## B3 (auditoria UX 18-Jul-2026): tocar a Estelita repite la instruccion (GDD §6.2,
## obligatoria). Para este piloto reproduce la linea `pista` del nivel.
func _al_tocar_estelita() -> void:
	_reproducir_voz("pista", nivel.get("lineas_voz", {}).get("pista", ""))


func _disparar_derrota_gag() -> void:
	_derrota_disparada = true
	nivel_fallado.emit()
	_reproducir_voz("derrota_gag", nivel.get("lineas_voz", {}).get("derrota_gag", ""))
	_etiqueta_gag.show()
	_boton_otra_vez.show()
	for carta in _cartas:
		if not carta.esta_acertada:
			carta.disabled = true
			# Placeholder del gag "salen galopando en circulo" (ficha de nivel §6): giro
			# gracioso de cada carta pendiente al ritmo de una "musiquita tonta" (TODO SFX).
			var tween := carta.create_tween()
			tween.tween_property(carta, "rotation", TAU, 0.6)
			tween.tween_callback(func() -> void: carta.rotation = 0.0)


func _reintentar() -> void:
	_boton_otra_vez.hide()
	_etiqueta_gag.hide()
	# Se resetea el contador solo para dar ritmo de juego al segundo intento (evita
	# retrigger inmediato de la derrota-gag ante el primer fallo). No reabre el bono de
	# puntaje: `_derrota_disparada` ya quedo en true y `_calcular_destellos()` lo respeta.
	_intentos_usados = 0
	_seleccionadas.clear()
	_id_esperando_volteo = ""
	for carta in _cartas:
		if not carta.esta_acertada:
			carta.reiniciar(_oculto)


func _celebrar_victoria() -> void:
	_reproducir_voz("victoria_final", nivel.get("lineas_voz", {}).get("victoria_final", ""))
	_confeti.emitting = true
	# TODO(personajes): disparar aqui el gesto real de celebracion del perfil jugador
	# (docs/perfil-jugadores.md) cuando el nodo padre lo exponga; el motor solo emite
	# la senal `completado`.
	var destellos := _calcular_destellos()
	_contador_destellos.text = "* %d" % destellos
	_contador_destellos.show()
	await get_tree().create_timer(1.2).timeout
	emitir_completado(destellos)


func _calcular_destellos() -> int:
	var total := _pares_totales * DESTELLOS_POR_PAR
	# M-QA1 (QA 18-Jul-2026): el bono de "intentos sobrantes" solo tiene sentido si nunca
	# se agoto el limite. Si ya se disparo la derrota-gag (aunque se haya reintentado y
	# _intentos_usados se haya reseteado), el bono queda en 0 para toda la partida: asi
	# fallar a proposito + reintentar nunca puede superar el puntaje de jugar limpio.
	if _limite_intentos != null and not _derrota_disparada:
		var intentos_sobrantes: int = max(_limite_intentos - _intentos_usados, 0)
		total += intentos_sobrantes * DESTELLOS_POR_INTENTO_SOBRANTE
	return total
