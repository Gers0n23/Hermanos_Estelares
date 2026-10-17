class_name GestorTurnos
extends Node

## Gestor de turnos del modo equipo (docs/fichas/modo-equipo.md §4, §5.2, §6 y §11.4; HE-59).
##
## Capa GENERICA del nucleo (regla de oro 4): sabe del orden de los turnos, el turno actual, el pase de
## turno (pasos 0, 0b, 1, 2, puerta, 4 y bloqueo de 400 ms), los pasos del rival, el tope de aciertos por
## turno, la racha, el retroceso y el resbalon. NO sabe que es un "par", una carta ni ningun juego: el
## motor solo le dice cuando hubo un acierto (`notificar_acierto`) y cuando termina un turno
## (`terminar_turno`, o `confirmar_turno_estable` tras `tope_alcanzado`).
##
## La UI del modo (barra del equipo, pista del rival y guirnalda) la crea y la maneja este gestor; el motor
## solo da la posicion de su mesa (`ancla_meta_turno()`). Reglas que se cumplen aqui:
## - R6/B3: el rival avanza en el PASO 2 del pase, con el retrato del siguiente ya volando al centro; nunca
##   por el error de alguien con nombre. Maxi (semilla) no lo mueve (`maxi_mueve_rival: false`).
## - Turno perfecto (PO 07-Oct-2026): con tope, llegar al tope sin que un fallo corte el turno hace
##   retroceder al rival (paso 0b) y en ese pase se RESBALA y no avanza (UX N10). Nunca hay derrota tras un
##   turno perfecto. Sin tope rige la racha de 3 (`racha_retrocede_rival`).
## - B1: la puerta del turno se abre tocando el retrato grande (o arrastrandolo a su ventanita despues de
##   un turno de Maxi) y despues hay 400 ms de bloqueo. Recordatorio "¡te toca!" a los 10 s, maximo 2.
## - M2: en turnos semilla, `semilla_auto_s` sin ningun toque pide la jugada automatica al motor.
##
## Fuera de alcance de HE-59 (van en HE-69 / HE-76): modo sin puerta (`confirmar_turno: false`, epilogo),
## `rival: null` de la Torre, `terminar_turno_sin_recursos()` y `reiniciar_rival(forzar_id)` completo.

signal turno_iniciado(id_hermano: String, perfil: String)
signal rival_movido(posicion: int)
signal rival_resbalo()
signal rival_llego()
signal entrada_bloqueada_cambio(bloqueada: bool)
signal jugada_automatica_pedida()
signal tope_alcanzado()
signal turno_cerrado(id_hermano: String, perfecto: bool)

const BarraEquipo := preload("res://scripts/ui/barra_equipo.gd")
const PistaRival := preload("res://scripts/ui/pista_rival.gd")
const MetaTurno := preload("res://scripts/ui/meta_turno.gd")

## Colores de turno (m1): los de las tarjetas de seleccion. El aura de Sofia nunca es rosa.
const COLORES := {"maxi": Color("#3E77CC"), "nicole": Color("#E8589C"), "sofia": Color("#2FB3AD")}
const ORDEN_PERFILES := ["semilla", "brote", "estrella"]
const PREFIJO_AUDIO := "res://assets/audio/"
const SFX_FIUU := "res://assets/audio/sfx/ui/fiuu.ogg"
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_PAR := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_ABRIR := "res://assets/audio/sfx/ui/seleccionar.ogg"
const SFX_PLOF := "res://assets/audio/sfx/ui/puf.ogg"
const SFX_BOING := "res://assets/audio/sfx/ui/blup.ogg"
const SEGUNDOS_RECORDATORIO := 10.0
const MAX_RECORDATORIOS := 2
const ENFRIAMIENTO_REPETIR_MS := 2000
const ALFA_VELO := 0.4

## Solo arneses: multiplica todas las esperas del pase (1.0 = tiempos reales del juego).
var escala_tiempo := 1.0

var _equipo: Array[String] = []
var _perfiles: Dictionary = {}
var _config: Dictionary = {}
var _voces: Dictionary = {}
var _ciclo: Array[String] = []
var _indice := 0
var _actual := ""
var _pos_rival := 0
var _pasos_rival := 5
var _topes: Dictionary = {}
var _aciertos_turno := 0
var _racha_turno := 0
var _retrocesos_turno := 0
var _aciertos_equipo := 0
var _aciertos_totales := 0

var _bloqueada := true
var _turno_activo := false
var _esperando_confirmacion := false
var _detenido := false
var _id_pase := 0

var _en_puerta := false
var _puerta_arrastre := false
var _arrastrando := false
var _indice_dedo := -2
var _t_puerta := 0.0
var _recordatorios := 0
var _ultimo_repetir := -ENFRIAMIENTO_REPETIR_MS
var _voz_0b := ""
var _sono_guardala := false

var _auto_t := 0.0
var _auto_pedida := false
var _ultimas_voces := {}

var _capa: Control
var _velo: ColorRect
var barra: Control
var pista: Control
var meta: Control
var _motor: Node

signal _puerta_abierta


# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------

## `config` = bloque `equipo` del nivel, ya con la composicion resuelta por el motor: `pasos_rival`,
## `aciertos_max_turno` (siempre con "semilla"), `aciertos_totales`, `record_pasos` y `lineas_voz`.
## `perfiles` = {id: "semilla"|"brote"|"estrella"}. `capa_ui` = la capa de UI del motor.
func configurar(equipo: Array[String], config: Dictionary, perfiles: Dictionary, capa_ui: Node) -> void:
	_equipo = equipo.duplicate()
	_perfiles = perfiles.duplicate()
	_config = config
	_voces = config.get("lineas_voz", {}) if config.get("lineas_voz", {}) is Dictionary else {}
	_pasos_rival = maxi(1, int(config.get("pasos_rival", 5)))
	_aciertos_totales = int(config.get("aciertos_totales", 0))
	var topes = config.get("aciertos_max_turno", {})
	_topes = topes if topes is Dictionary else {}
	_motor = get_parent()
	_ciclo = construir_ciclo(_equipo, _perfiles, str(config.get("orden", "maxi_intercalado")))
	_crear_ui(capa_ui, int(config.get("record_pasos", -1)))


## Orden de los turnos (§4.2). "maxi_intercalado" (por defecto): el menor (semilla) va entre cada uno de
## los otros: M -> N -> M -> S. "menor_a_mayor": sin intercalar. Siempre empieza el menor.
static func construir_ciclo(equipo: Array[String], perfiles: Dictionary, orden: String) -> Array[String]:
	var ordenados: Array[String] = equipo.duplicate()
	ordenados.sort_custom(func(a: String, b: String) -> bool:
		var pa := ORDEN_PERFILES.find(str(perfiles.get(a, "")))
		var pb := ORDEN_PERFILES.find(str(perfiles.get(b, "")))
		return pa < pb if pa != pb else a < b)
	var ciclo: Array[String] = []
	var semillas: Array[String] = []
	var otros: Array[String] = []
	for id in ordenados:
		if str(perfiles.get(id, "")) == "semilla":
			semillas.append(id)
		else:
			otros.append(id)
	if orden == "maxi_intercalado" and semillas.size() == 1 and otros.size() >= 1:
		for otro in otros:
			ciclo.append(semillas[0])
			ciclo.append(otro)
		return ciclo
	return ordenados


func _crear_ui(capa_ui: Node, record_pasos: int) -> void:
	_capa = Control.new()
	_capa.name = "capa_equipo"
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.position = Vector2.ZERO
	_capa.size = Vector2(1280, 720)
	if capa_ui != null:
		capa_ui.add_child(_capa)
	else:
		add_child(_capa)
	_velo = ColorRect.new()
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.color = Color(0.1, 0.05, 0.2, ALFA_VELO)
	_velo.position = Vector2(0, 100)
	_velo.size = Vector2(1280, 510)
	_velo.modulate.a = 0.0
	_capa.add_child(_velo)
	pista = PistaRival.new()
	pista.name = "pista_rival"
	_capa.add_child(pista)
	pista.configurar(_pasos_rival, record_pasos)
	meta = MetaTurno.new()
	meta.name = "meta_turno"
	_capa.add_child(meta)
	barra = BarraEquipo.new()
	barra.name = "barra_equipo"
	_capa.add_child(barra)
	barra.preparar(orden_unico(), _colores_equipo())


func _colores_equipo() -> Dictionary:
	var colores := {}
	for id in _equipo:
		colores[id] = color_de(id)
	return colores


func color_de(id: String) -> Color:
	return COLORES.get(id, Color.WHITE)


## Ids en el orden de los turnos, sin repetir (orden de las ventanitas y de la fiesta final).
func orden_unico() -> Array[String]:
	var lista: Array[String] = []
	for id in _ciclo:
		if id not in lista:
			lista.append(id)
	return lista


# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------

func hermano_actual() -> String:
	return _actual


func perfil_actual() -> String:
	return str(_perfiles.get(_actual, ""))


func entrada_bloqueada() -> bool:
	return _bloqueada


func turno_activo() -> bool:
	return _turno_activo


func pasos_usados() -> int:
	return _pos_rival


func pasos_rival() -> int:
	return _pasos_rival


func ciclo() -> Array[String]:
	return _ciclo.duplicate()


func tope_de(perfil: String) -> int:
	return int(_topes.get(perfil, 0))


func posicion_boca_rival() -> Vector2:
	return pista.boca_global() if pista != null else Vector2(640, 60)


func punto_cinta() -> Vector2:
	return pista.punto_cinta_global() if pista != null else Vector2(1040, 40)


# ---------------------------------------------------------------------------
# Flujo de turnos
# ---------------------------------------------------------------------------

## Primer turno (Maxi si juega), con su puerta.
func empezar() -> void:
	_detenido = false
	_pos_rival = 0
	_indice = 0
	_actual = _ciclo[0] if not _ciclo.is_empty() else ""
	pista.fijar_posicion(0)
	_bloquear(true)
	_id_pase += 1
	var id := _id_pase
	barra.volar_al_centro(_actual)
	_velo_a(1.0)
	_decir_le_toca(_actual, false)
	await _esperar(0.6)
	if id != _id_pase:
		return
	await _puerta_y_turno(id, false)


## M4/N6: igual que `empezar()` tras restaurar un parcial (rival en 0 y primer turno del menor).
func empezar_retomando() -> void:
	await empezar()


## Suma un acierto al turno. Con tope para el perfil: enciende la guirnalda y, al llegar al tope, bloquea
## la entrada y emite `tope_alcanzado` (el motor confirma con `confirmar_turno_estable`). Sin tope: la
## racha de `racha_retrocede_rival` hace retroceder al rival en el momento. Maxi nunca mueve al rival.
func notificar_acierto() -> void:
	if not _turno_activo or _esperando_confirmacion or _detenido:
		return
	_aciertos_turno += 1
	_aciertos_equipo += 1
	_auto_t = 0.0
	if _aciertos_totales > 0:
		pista.fraccion_cinta = float(_aciertos_equipo) / _aciertos_totales
	barra.aplaudir(_actual)
	barra.gesto(_actual)
	pista.cara_ay_no()
	_voz_rival_par()
	var perfil := perfil_actual()
	var tope := tope_de(perfil)
	if tope > 0:
		if perfil != "semilla":
			var n: int = meta.encender()
			_sfx(SFX_PAR, pow(2.0, (n - 1) / 12.0))
		if _aciertos_turno >= tope:
			_esperando_confirmacion = true
			_bloquear(true)
			tope_alcanzado.emit()
		return
	var racha := int(_config.get("racha_retrocede_rival", 0))
	if racha <= 0 or (perfil == "semilla" and not bool(_config.get("maxi_mueve_rival", false))):
		return
	_racha_turno += 1
	if _racha_turno % racha == 0:
		_retroceder_rival()
		_retrocesos_turno += 1
		_voz_despues("rival_retrocede_celebra", 2.0)


## "No es este" que NO corta el turno (el besito de Coco de Nicole) o que si lo corta: quienes miran solo
## dan animo (B2). No cuenta nada ni deja rastro en pantalla.
func notificar_fallo_suave() -> void:
	barra.animar_animo(_actual)
	# B2 (grabacion opcional de los ninos): suena UNO solo, un hermano al azar entre los que miran (nunca el
	# que juega), despues de la voz de Coco. Si no hay grabacion, solo la animacion.
	var mirando: Array = orden_unico().filter(func(id: String) -> bool: return id != _actual)
	if mirando.is_empty():
		return
	var quien: String = mirando.pick_random()
	if _ruta_voz("animo_hermanos", quien) != "":
		_voz_despues_sub("animo_hermanos", quien, 1.0)


func _voz_despues_sub(clave: String, sub: String, margen: float) -> void:
	var ruta := _ruta_voz(clave, sub)
	if ruta == "" or not ResourceLoader.exists(ruta):
		return
	# Sin chequeo de pase: el animo tambien acompana al "no es este" que corta el turno; nunca pisa otra voz
	# (si ya suena "¡le toca a…!", se omite).
	await _esperar_bus_libre(4.0)
	await _esperar(minf(margen, 0.3))
	var audio := get_node_or_null("/root/Audio")
	if not is_inside_tree() or _detenido or (audio != null and audio.esta_hablando()):
		return
	_reproducir(ruta, clave)


## El motor corta el turno (por fallo, o porque se gastaron sus recursos), siempre en estado estable.
func terminar_turno(con_fallo: bool) -> void:
	if not _turno_activo or _esperando_confirmacion or _detenido:
		return
	_turno_activo = false
	_bloquear(true)
	turno_cerrado.emit(_actual, false)
	_pase(con_fallo, false)


## B2.1: respuesta del motor a `tope_alcanzado` cuando no queda nada en vuelo. Paso 0b si el perfil no es
## semilla (turno perfecto: retroceso y, en el pase, resbalon); si es semilla, su celebracion de siempre.
func confirmar_turno_estable() -> void:
	if not _esperando_confirmacion or _detenido:
		return
	_esperando_confirmacion = false
	_turno_activo = false
	var perfecto := perfil_actual() != "semilla"
	_voz_0b = ""
	turno_cerrado.emit(_actual, perfecto)
	if not perfecto:
		_pase(false, false)
		return
	_id_pase += 1
	var id := _id_pase
	# Paso 0b: "¡turno perfecto!" (Cometa; la presentacion la primera vez por familia), gesto, la barra
	# aplaude y la guirnalda destella y suelta su chispa hacia los pies del rival.
	var presentacion := _ruta_voz("turno_perfecto_presenta")
	var progreso := get_node_or_null("/root/Progreso")
	var presenta: bool = presentacion != "" and progreso != null and not progreso.cinematica_vista("nucleo:turno_perfecto") \
		and ResourceLoader.exists(presentacion)
	if presenta:
		_reproducir(presentacion, "turno_perfecto_presenta")
	else:
		_decir("turno_perfecto")
	barra.gesto(_actual)
	barra.aplaudir(_actual)
	meta.destellar()
	_chispa_hacia_rival()
	await _esperar(0.5)
	if id != _id_pase:
		return
	await _esperar_bus_libre(2.5)
	if id != _id_pase:
		return
	if presenta and progreso != null:
		progreso.marcar_cinematica_vista("nucleo:turno_perfecto")
	# Retroceso por turno perfecto (minimo galleta 0: ahi solo trastabilla, sin voz).
	var retrocede := _pos_rival > 0
	_retroceder_rival()
	if _voz_0b != "":
		# N13: "¡guardala para tu proximo turno!" reemplaza esa vez a rival_retrocede.
		_reproducir(_voz_0b, "guardala_proximo_turno")
		_sono_guardala = true
	elif retrocede:
		_decir("rival_retrocede")
	await _esperar(0.9)
	if id != _id_pase:
		return
	await _esperar_bus_libre(1.5)
	if id != _id_pase:
		return
	_pase(false, true)


## N13: el motor encola una voz para el paso 0b (reemplaza esa vez a `rival_retrocede`).
func encolar_voz_0b(ruta: String) -> void:
	_voz_0b = _resolver(ruta)


## Tras "¡otra vez!": el rival vuelve a la galleta 0 y se abre la puerta del hermano que ya estaba al centro.
func reiniciar_rival(forzar_id: String = "") -> void:
	_detenido = false
	if forzar_id != "" and forzar_id in _ciclo:
		_actual = forzar_id
		_indice = _ciclo.find(forzar_id)
	_pos_rival = 0
	rival_movido.emit(0)
	pista.volver_a_cero()
	_decir("rival_vuelve")
	barra.centrar_de_nuevo()
	_id_pase += 1
	var id := _id_pase
	await _esperar(0.8)
	if id != _id_pase:
		return
	_decir_le_toca(_actual, false)
	await _puerta_y_turno(id, false)


## Victoria (o salida): corta todo lo que este en curso y deja la entrada como esta.
func detener() -> void:
	_detenido = true
	_id_pase += 1
	_turno_activo = false
	_esperando_confirmacion = false
	_en_puerta = false
	meta.retirar()


func rival_aplaude() -> void:
	pista.aplaudir()
	_decir("rival_aplaude")


# ---------------------------------------------------------------------------
# El pase (§4.3)
# ---------------------------------------------------------------------------

func _pase(con_fallo: bool, perfecto: bool) -> void:
	_id_pase += 1
	var id := _id_pase
	var saliente := _actual
	var perfil_saliente := str(_perfiles.get(saliente, ""))
	var resbala := perfecto or (bool(_config.get("resbalon_tras_racha", false)) and _retrocesos_turno > 0)
	if con_fallo:
		meta.apagar_despacio()
	# Paso 0: solo tras un turno de Maxi (ritual, M3.3).
	if perfil_saliente == "semilla":
		barra.ritual_fin_semilla(saliente)
		_decir("porras_fin_maxi")
		await _esperar(1.2)
		if id != _id_pase:
			return
	# Paso 1: solo tras "no es este": las cartas quedan a la vista para que todo el equipo se acuerde.
	if con_fallo:
		await _esperar(float(_config.get("ms_volteo_equipo", 1500)) / 1000.0)
		if id != _id_pase:
			return
	# Paso 2: el retrato del siguiente vuela al centro y, en ese mismo momento, el rival se mueve.
	meta.retirar()
	_indice = (_indice + 1) % maxi(1, _ciclo.size())
	_actual = _ciclo[_indice]
	var arrastre := perfil_saliente == "semilla" and str(_config.get("puerta_tras_semilla", "arrastre")) == "arrastre" \
		and str(_perfiles.get(_actual, "")) != "semilla"
	barra.volar_al_centro(_actual)
	_velo_a(1.0)
	_sfx(SFX_FIUU)
	_decir_le_toca(_actual, arrastre)
	var llego := false
	if resbala:
		rival_resbalo.emit()
		pista.resbalar()
		_sfx(SFX_PLOF, 1.0, -6.0)
		_voz_despues("rival_resbala", 1.0, true)
	elif perfil_saliente != "semilla" or bool(_config.get("maxi_mueve_rival", false)):
		_pos_rival = mini(_pos_rival + 1, _pasos_rival)
		rival_movido.emit(_pos_rival)
		pista.saltar_a(_pos_rival)
		_sfx(SFX_BOING, 1.0, -6.0)
		llego = _pos_rival >= _pasos_rival
		if not llego:
			_voz_despues("rival_avanza", 1.0, true)
	else:
		pista.embobado()
	await _esperar(0.6)
	if id != _id_pase:
		return
	if llego:
		# La derrota-gag empieza con el retrato del siguiente ya en el centro, sin abrir la puerta: perder
		# "le pasa a todos" (B3). La orquesta minijuego_base.
		_detenido = true
		rival_llego.emit()
		return
	await _puerta_y_turno(id, arrastre)


## Pasos 3 (puerta), 4 (vuelve a la ventanita) y 5 (bloqueo de 400 ms) y empieza el turno.
func _puerta_y_turno(id: int, arrastre: bool) -> void:
	_en_puerta = true
	_puerta_arrastre = arrastre
	_arrastrando = false
	_t_puerta = 0.0
	_recordatorios = 0
	barra.mostrar_flechita(arrastre)
	await _puerta_abierta
	if id != _id_pase:
		return
	_en_puerta = false
	barra.mostrar_flechita(false)
	_sfx(SFX_ABRIR)
	# Paso 4: el retrato vuelve a su ventanita, el tablero se aclara y el rival se para si estaba sentado.
	barra.volver_a_ventanita(_actual)
	_velo_a(0.0)
	pista.pararse()
	await _esperar(0.4)
	if id != _id_pase:
		return
	# Paso 5: bloqueo obligatorio despues de abrir la puerta (B1.3).
	await _esperar(maxf(0.0, float(_config.get("bloqueo_tras_puerta_ms", 400))) / 1000.0)
	if id != _id_pase:
		return
	_iniciar_turno()


func _iniciar_turno() -> void:
	_aciertos_turno = 0
	_racha_turno = 0
	_retrocesos_turno = 0
	_auto_t = 0.0
	_auto_pedida = false
	_sono_guardala = false
	_turno_activo = true
	_esperando_confirmacion = false
	barra.fijar_actual(_actual)
	var perfil := perfil_actual()
	var tope := tope_de(perfil)
	if tope > 0 and perfil != "semilla":
		var ancla := Vector2.INF
		if _motor != null and _motor.has_method("ancla_meta_turno"):
			ancla = _motor.ancla_meta_turno()
		meta.mostrar(tope, color_de(_actual), ancla)
	_bloquear(false)
	turno_iniciado.emit(_actual, perfil)


## Abre la puerta (toque en el retrato, o soltarlo sobre su ventanita). Tambien la usan los arneses.
func abrir_puerta() -> void:
	if not _en_puerta:
		return
	_en_puerta = false
	_puerta_abierta.emit()


func en_puerta() -> bool:
	return _en_puerta


func _retroceder_rival() -> void:
	if _pos_rival > 0:
		_pos_rival -= 1
		rival_movido.emit(_pos_rival)
	pista.tropezar_atras(_pos_rival)


func _bloquear(valor: bool) -> void:
	if _bloqueada == valor:
		return
	_bloqueada = valor
	entrada_bloqueada_cambio.emit(valor)


func _velo_a(alfa: float) -> void:
	if _velo == null:
		return
	_velo.create_tween().tween_property(_velo, "modulate:a", alfa, 0.25)


func _chispa_hacia_rival() -> void:
	if not meta.visible:
		return
	var chispa := Control.new()
	chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chispa.size = Vector2(28, 28)
	chispa.draw.connect(func() -> void:
		var puntos := PackedVector2Array()
		for i in 10:
			var r := 14.0 if i % 2 == 0 else 7.0
			puntos.append(Vector2(14, 14) + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * r)
		chispa.draw_colored_polygon(puntos, Color("#FFE38A")))
	_capa.add_child(chispa)
	chispa.global_position = meta.punto_salida() - chispa.size / 2.0
	var tween := chispa.create_tween()
	tween.tween_property(chispa, "global_position", pista.pies_global() - chispa.size / 2.0, 0.4 * escala_tiempo) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(chispa.queue_free)


# ---------------------------------------------------------------------------
# Entrada: puerta, ventanitas de porra, Cometa y la guirnalda. Nunca se consume el evento (las cartas
# reciben el mismo toque y, con la entrada bloqueada, solo hacen el pulso).
# ---------------------------------------------------------------------------

## Solo eventos tactiles: el proyecto emula el toque desde el mouse (`emulate_touch_from_mouse`), asi que en
## PC el clic llega como InputEventScreenTouch y no se procesa dos veces (entrada unificada, GDD §6.4).
func _input(evento: InputEvent) -> void:
	if barra == null:
		return
	if evento is InputEventScreenDrag:
		if _arrastrando and evento.index == _indice_dedo:
			barra.mover_centro_a(evento.position)
		return
	if not evento is InputEventScreenTouch:
		return
	var toque := evento as InputEventScreenTouch
	if toque.pressed:
		# Cualquier pulsacion reinicia el conteo de la jugada automatica (M2).
		_auto_t = 0.0
		_al_presionar(toque.position, toque.index)
	elif _arrastrando and toque.index == _indice_dedo:
		soltar_arrastre(toque.position)


## Fin del arrastre del retrato de la puerta (B1.2): con el imán de 80 px alrededor de la ventanita se abre;
## si no, el retrato vuelve blandito al centro, sin sonido de error.
func soltar_arrastre(punto: Vector2) -> void:
	_arrastrando = false
	if barra.distancia_a_ventanita(_actual, punto) <= BarraEquipo.IMAN_VENTANITA:
		abrir_puerta()
	else:
		barra.soltar_centro_lejos()


func _al_presionar(punto: Vector2, dedo: int) -> void:
	if _en_puerta:
		if barra.rect_puerta().has_point(punto):
			if _puerta_arrastre:
				_arrastrando = true
				_indice_dedo = dedo
			else:
				abrir_puerta()
			return
		# Toque fuera del retrato: salta y repite "¡le toca a…!" (enfriamiento de 2 s).
		if not PistaRival.RECT_COMETA.has_point(punto):
			barra.saltar_centro()
			var ahora := Time.get_ticks_msec()
			if ahora - _ultimo_repetir >= ENFRIAMIENTO_REPETIR_MS:
				_ultimo_repetir = ahora
				_decir_le_toca(_actual, _puerta_arrastre)
			return
	if PistaRival.RECT_COMETA.has_point(punto):
		_tocar_cometa()
		return
	if meta.visible and meta.get_global_rect().has_point(punto):
		meta.titilar()
		return
	var porra: String = barra.tocar_porra(punto)
	if porra != "":
		# Se silencia mientras suena la voz "le toca a…".
		var audio := get_node_or_null("/root/Audio")
		if audio == null or not audio.esta_hablando():
			_sfx(SFX_TOQUE, 1.3, -4.0)


## Cometa repite la regla y de quien es el turno (M4 de HE-58, M6 de HE-66, GDD §6.2).
func _tocar_cometa() -> void:
	pista.tocar_cometa()
	_sfx(SFX_TOQUE)
	var tope := tope_de(perfil_actual())
	if tope > 0 and perfil_actual() != "semilla" and _ruta_voz("repetir_equipo_tope") != "":
		_decir("repetir_equipo_tope")
	elif _ruta_voz("repetir_equipo") != "":
		_decir("repetir_equipo")
	else:
		_decir_le_toca(_actual, false)


func _process(delta: float) -> void:
	if _en_puerta:
		_t_puerta += delta
		# m5: "¡Nicole, te toca!" a los 10 s sin abrir, como maximo 2 veces; despues solo respira.
		if _recordatorios < MAX_RECORDATORIOS and _t_puerta >= SEGUNDOS_RECORDATORIO * (_recordatorios + 1):
			_recordatorios += 1
			var clave := "te_toca_recordatorio_ventanita" if _puerta_arrastre else "te_toca_recordatorio"
			_decir(clave, _actual)
		return
	# M2: turno semilla sin ningun toque durante `semilla_auto_s` -> jugada automatica.
	var auto_s := float(_config.get("semilla_auto_s", 0))
	if auto_s > 0.0 and _turno_activo and not _bloqueada and not _auto_pedida and perfil_actual() == "semilla":
		_auto_t += delta / maxf(0.001, escala_tiempo)
		if _auto_t >= auto_s:
			_auto_pedida = true
			jugada_automatica_pedida.emit()


# ---------------------------------------------------------------------------
# Voces (lineas_voz del nivel; si falta un archivo, se sigue sin voz y nunca falla)
# ---------------------------------------------------------------------------

func _decir_le_toca(id: String, arrastre: bool) -> void:
	if arrastre and _ruta_voz("sube_ventanita", id) != "":
		_decir("sube_ventanita", id)
	else:
		_decir("le_toca", id)


func _resolver(ruta: String) -> String:
	if ruta == "" or ruta == "PENDIENTE":
		return ""
	return ruta if ruta.begins_with("res://") else PREFIJO_AUDIO + ruta


## Ruta de una clave de voz (con sub-clave por hermano si es un mapa). Arreglo = variantes al azar sin
## repetir la anterior.
func _ruta_voz(clave: String, sub := "") -> String:
	var valor = _voces.get(clave, "")
	if valor is Dictionary:
		valor = valor.get(sub, "")
	if valor is Array:
		if valor.is_empty():
			return ""
		var anterior: String = _ultimas_voces.get(clave + sub, "")
		var opciones: Array = valor.filter(func(r) -> bool: return str(r) != anterior)
		if opciones.is_empty():
			opciones = valor
		valor = opciones.pick_random()
		_ultimas_voces[clave + sub] = str(valor)
	return _resolver(str(valor))


func _decir(clave: String, sub := "") -> void:
	_reproducir(_ruta_voz(clave, sub), clave)


func _reproducir(ruta: String, clave: String) -> void:
	if ruta == "":
		return
	print("[voz:%s] %s" % [clave, ruta.trim_prefix(PREFIJO_AUDIO)])
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta)


## Voz opcional que va DESPUES de la que suena: solo si el bus queda libre dentro de `margen` s y (si
## `solo_con_puerta`) la puerta sigue cerrada; si no, se omite. Nunca pisa otra voz (§4.3, §8).
func _voz_despues(clave: String, margen: float, solo_con_puerta := false) -> void:
	var ruta := _ruta_voz(clave)
	if ruta == "" or not ResourceLoader.exists(ruta):
		return
	var id := _id_pase
	var audio := get_node_or_null("/root/Audio")
	# Espera a que termine la voz que esta sonando ("¡le toca a…!") y le da `margen` s para quedar libre.
	await _esperar_bus_libre(6.0)
	var inicio := Time.get_ticks_msec()
	while audio != null and audio.esta_hablando() and Time.get_ticks_msec() - inicio < margen * 1000.0:
		await get_tree().process_frame
	await _esperar(0.15)
	if not is_inside_tree() or id != _id_pase or _detenido:
		return
	if solo_con_puerta and (not _en_puerta or _sono_guardala):
		return
	if audio != null and audio.esta_hablando():
		return
	_reproducir(ruta, clave)


## La voz del rival al formarse un acierto: como maximo 1 de cada 3, y nunca encima de otra voz.
func _voz_rival_par() -> void:
	if _aciertos_equipo % 3 != 1:
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.esta_hablando():
		return
	_decir("rival_par")


func _esperar_bus_libre(maximo: float) -> void:
	var audio := get_node_or_null("/root/Audio")
	var inicio := Time.get_ticks_msec()
	while audio != null and audio.esta_hablando() and Time.get_ticks_msec() - inicio < maximo * 1000.0 * escala_tiempo:
		await get_tree().process_frame


func _esperar(segundos: float) -> void:
	if segundos <= 0.0:
		return
	await get_tree().create_timer(segundos * escala_tiempo).timeout


func _sfx(ruta: String, tono := 1.0, volumen_db := 0.0) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null and ResourceLoader.exists(ruta):
		audio.reproducir_sfx(ruta, tono, volumen_db)
