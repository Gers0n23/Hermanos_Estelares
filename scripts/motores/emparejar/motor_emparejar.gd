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

signal par_acertado(id_pareja: String)
signal intento_fallido()
signal nivel_fallado()
signal carta_intercambiada(a: CartaEmparejar, b: CartaEmparejar)
## B4 (auditoria UX 18-Jul-2026): la senal de salida `salir_solicitado()` vive desde HE-10
## en el contrato base (`minijuego_base.gd`), comun a todos los motores.

const CARTA_ESCENA: PackedScene = preload("res://escenas/minijuegos/emparejar/carta_emparejar.tscn")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
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
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_VOLTEAR := "sfx/ui/seleccionar.ogg"
const SFX_TAPAR := "sfx/ui/soltar.ogg"
const SFX_PAR := "sfx/ui/confirmar.ogg"
const SFX_NO_ES_ESTE := "sfx/ui/no_es_este.ogg"
const SFX_TOQUE := "sfx/ui/toque.ogg"
const SFX_GAG := "sfx/ui/abrir.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")

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
	_configurar_desde_nivel()
	_construir_tablero()
	_construir_progreso()
	_boton_pista.visible = bool(nivel.get("pistas_cuestan_estrellita", false))
	_reproducir_voz("intro", _linea("intro"))
	_actualizar_depuracion()


func _process(delta: float) -> void:
	_tiempo += delta
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	var bamboleo := absf(sin(_tiempo * 9.0)) * 5.0 if hablando else 0.0
	_anfitriona.position.y = _base_anfitriona.y - _salto_anfitriona - bamboleo


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_panel_depuracion.visible = not _panel_depuracion.visible
		_actualizar_depuracion()


func _configurar_desde_nivel() -> void:
	_oculto = bool(nivel.get("oculto", false))
	_tiempo_volteo_ms = int(nivel.get("tiempo_volteo_ms", 1200))
	var limite = nivel.get("limite_intentos", null)
	_limite_intentos = int(limite) if limite != null else null
	var ayuda = nivel.get("ayuda_tras_fallos", null)
	_ayuda_tras_fallos = int(ayuda) if ayuda != null else 0
	_tamano_grupo = maxi(2, int(nivel.get("tamano_grupo", 2)))
	_intercambios = int(nivel.get("intercambios_tras_acierto", 0))
	_pares_totales = _grupos_del_nivel().size()


## Grupos de cartas iguales. `grupos` (trios) o, por compatibilidad, `pares` con elemento_a/elemento_b.
func _grupos_del_nivel() -> Array:
	if nivel.has("grupos"):
		return nivel["grupos"]
	var grupos: Array = []
	for par: Dictionary in nivel.get("pares", []):
		grupos.append({"id_grupo": par.get("id_pareja", ""), "especial": par.get("especial", false),
			"figura": par.get("figura", ""), "color": par.get("color", ""),
			"elementos": [par.get("elemento_a", {}), par.get("elemento_b", {})]})
	return grupos


func _construir_tablero() -> void:
	var elementos: Array = []
	for grupo: Dictionary in _grupos_del_nivel():
		for info: Dictionary in grupo.get("elementos", []):
			var elemento := info.duplicate()
			elemento["id_pareja"] = grupo.get("id_grupo", "")
			elemento["figura"] = info.get("figura", grupo.get("figura", ""))
			elemento["color"] = info.get("color", grupo.get("color", ""))
			elemento["especial"] = grupo.get("especial", false)
			elementos.append(elemento)
	elementos.shuffle()

	var disposicion: Dictionary = nivel.get("disposicion", {})
	var columnas := maxi(1, int(disposicion.get("columnas", 4)))
	var filas := ceili(elementos.size() / float(columnas))
	_lado_carta = minf(LADO_MAXIMO_CARTA, minf(
		(ZONA_TABLERO.size.x - SEPARACION * (columnas - 1)) / columnas,
		(ZONA_TABLERO.size.y - SEPARACION * (filas - 1)) / filas))
	var medida := Vector2(columnas, filas) * _lado_carta + Vector2(columnas - 1, filas - 1) * SEPARACION
	var origen := ZONA_TABLERO.position + (ZONA_TABLERO.size - medida) / 2.0
	_mesa.position = origen - Vector2(22, 22)
	_mesa.size = medida + Vector2(44, 44)

	var halo_idle := bool(nivel.get("halo_idle", false))
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
		var ranura := Figura.new()
		ranura.figura = ""
		ranura.con_disco = true
		ranura.custom_minimum_size = Vector2.ONE * lado
		ranura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_progreso_pares.add_child(ranura)
		_ranuras.append(ranura)


func _al_tocar_carta(carta: CartaEmparejar) -> void:
	if carta.esta_acertada or _en_gag:
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

	carta.seleccionar()
	reproducir_sfx(SFX_VOLTEAR)
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
		reproducir_sfx(SFX_PAR)
		par_acertado.emit(a.id_pareja)
		_celebrar_grupo(grupo)
		if _pares_acertados >= _pares_totales:
			_celebrar_victoria()
		else:
			_reproducir_voz_acierto(a)
			if _intercambios > 0:
				_despues(0.75, _intercambiar_cartas.bind(_intercambios))
		_actualizar_depuracion()
		return

	if _limite_intentos != null:
		_intentos_usados += 1
	_fallos_seguidos += 1
	intento_fallido.emit()
	reproducir_sfx(SFX_NO_ES_ESTE)
	_reproducir_voz("no_es_este", _linea_al_azar("no_es_este"))
	for carta in grupo:
		carta.animar_no_es_este()
	_reaccion_anfitriona("menea")
	_actualizar_depuracion()

	_procesando = true
	_no_es_este = grupo
	_id_resolucion += 1
	var id := _id_resolucion
	var espera := _tiempo_volteo_ms / 1000.0 if _oculto else SEGUNDOS_NO_ES_ESTE_VISIBLE
	await get_tree().create_timer(espera).timeout
	if id == _id_resolucion:
		_terminar_no_es_este()


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
func _dar_ayuda(con_voz := true) -> void:
	var pendientes := {}
	for carta in _cartas:
		if not carta.esta_acertada:
			if not pendientes.has(carta.id_pareja):
				pendientes[carta.id_pareja] = []
			pendientes[carta.id_pareja].append(carta)
	if pendientes.is_empty():
		return
	var claves := pendientes.keys()
	for carta in pendientes[claves[randi() % claves.size()]]:
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
		if carta.figura in Figura.FIGURAS and not carta.es_sombra():
			voladora = carta
	var indice := _pares_acertados - 1
	if indice < _ranuras.size():
		_volar_a_ranura(voladora, medio, _ranuras[indice])
	_reaccion_anfitriona("salta")
	if voladora.especial:
		_arcoiris_especial()
		_confeti.restart()


## Cartas traviesas: `cantidad` pares de cartas tapadas cambian de lugar con un vuelo visible.
func _intercambiar_cartas(cantidad: int) -> void:
	if _en_gag or _pares_acertados >= _pares_totales:
		return
	var tapadas: Array = []
	for carta in _cartas:
		if not carta.esta_acertada and not carta.mostrando and not _seleccionadas.has(carta) and not _no_es_este.has(carta):
			tapadas.append(carta)
	tapadas.shuffle()
	for i in cantidad:
		if tapadas.size() < 2:
			break
		var a: CartaEmparejar = tapadas.pop_back()
		var b: CartaEmparejar = tapadas.pop_back()
		var lugar_a := a.position
		var lugar_b := b.position
		for par_movimiento in [[a, lugar_b], [b, lugar_a]]:
			var carta: CartaEmparejar = par_movimiento[0]
			_tablero.move_child(carta, -1)
			var tween := carta.create_tween()
			tween.tween_property(carta, "scale", Vector2.ONE * 1.12, 0.12)
			tween.tween_property(carta, "position", par_movimiento[1], 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(carta, "scale", Vector2.ONE, 0.15)
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
			_celebrar_victoria()
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


## Pista de Sofia: Coco destapa un momento una pareja pendiente y se gasta una estrellita.
func _al_tocar_pista() -> void:
	if _en_gag or _pares_acertados >= _pares_totales:
		return
	reproducir_sfx(SFX_TOQUE)
	if _procesando:
		_terminar_no_es_este()
	_pistas_usadas += 1
	_dar_ayuda(false)
	_reproducir_voz("pista_usada", _linea("pista_usada"))
	var estrella := Figura.new()
	estrella.figura = "estrella"
	estrella.con_cara = false
	estrella.color = DORADO
	estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estrella.size = Vector2.ONE * 46.0
	_efectos.add_child(estrella)
	estrella.global_position = _boton_pista.global_position + Vector2(25, 25)
	var tween := estrella.create_tween().set_parallel(true)
	tween.tween_property(estrella, "position:y", estrella.position.y + 90.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(estrella, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(estrella.queue_free)
	_actualizar_depuracion()


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()


func _volar_a_ranura(carta: CartaEmparejar, desde: Vector2, ranura) -> void:
	var volador := Figura.new()
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


func _reproducir_voz_acierto(carta: CartaEmparejar) -> void:
	# Enganche del hallazgo especial (ficha de nivel §8): linea unica fuera del pool aleatorio.
	if carta.especial and _linea("acierto_especial") != "":
		_reproducir_voz("acierto_especial", _linea("acierto_especial"))
		return
	_reproducir_voz("acierto_par", _linea_al_azar("acierto_par"))


func _linea(clave: String) -> String:
	var valor = nivel.get("lineas_voz", {}).get(clave, "")
	if valor is Array:
		return str(valor[0]) if not valor.is_empty() else ""
	return str(valor)


## Elige una variante sin repetir la ultima, para que no suene monotono.
func _linea_al_azar(clave: String) -> String:
	var opciones = nivel.get("lineas_voz", {}).get(clave, [])
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


func _celebrar_victoria() -> void:
	# Confeti y bailecito de Coco mientras la ultima figura vuela a su ranura; despues, la
	# celebracion final reutilizable (HE-10). `celebrar()` emite `completado` al terminar.
	_confeti.restart()
	_reaccion_anfitriona("baila")
	var destellos := _calcular_destellos()
	await get_tree().create_timer(0.9).timeout
	celebrar(destellos, _calcular_estrellitas(), _linea("victoria_final"))


## Puntaje 1-3 estrellitas del perfil Estrella (ficha motor-emparejar §7). Regla PROVISIONAL
## hasta que `disenador-niveles` defina umbrales en el nivel: ganar siempre da al menos 1.
## Sin limite de intentos -> 3; tras una derrota-gag -> 1; con la mitad o mas de los intentos
## sobrantes -> 3; si no -> 2. `celebrar()` solo las muestra en niveles Estrella.
func _calcular_estrellitas() -> int:
	var base := 3
	if _derrota_disparada:
		base = 1
	elif _limite_intentos != null:
		var sobrantes: int = max(int(_limite_intentos) - _intentos_usados, 0)
		base = 3 if sobrantes * 2 >= int(_limite_intentos) else 2
	# Cada pista resta una estrellita (retos de Sofia), sin bajar de 1.
	return maxi(1, base - _pistas_usadas)


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


func _actualizar_depuracion() -> void:
	if not _panel_depuracion.visible:
		return
	var limite := "sin limite" if _limite_intentos == null else str(_limite_intentos)
	var ayuda := "no" if _ayuda_tras_fallos == 0 else "tras %d fallos seguidos" % _ayuda_tras_fallos
	_panel_depuracion.text = "DEPURACION (F3)\nnivel: %s\nperfil: %s · juega: %s\npares: %d de %d\nfallos que cuentan: %d / %s\nfallos seguidos: %d · ayuda: %s\nderrota-gag ya ocurrio: %s\nsi termina ahora: %d destellos, %d estrellitas" % [
		nivel.get("id_nivel", "?"), obtener_perfil_dificultad(), obtener_id_personaje(),
		_pares_acertados, _pares_totales, _intentos_usados, limite, _fallos_seguidos, ayuda,
		"si" if _derrota_disparada else "no", _calcular_destellos(), _estrellitas_visibles(_calcular_estrellitas())]


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
