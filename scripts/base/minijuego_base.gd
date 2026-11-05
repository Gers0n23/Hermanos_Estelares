class_name MinijuegoBase
extends Node2D

## Contrato base para todo motor de mecanica (docs/stack-tecnico.md §2, tarjeta HE-10).
##
## Modelo de rutas personalizadas (GDD §5, 18-Jul-2026): un motor concreto (p. ej.
## "emparejar") es AGNOSTICO de tema y de hermano. Todo lo que cambia entre Maxi, Nicole y
## Sofia (perfil semilla|brote|estrella, tema, cantidad de elementos, lineas de voz) llega
## en el archivo de nivel JSON (`ruta_nivel`, ver docs/fichas/*). El motor emite
## `completado(destellos)` al terminar con exito.
##
## Lo que el contrato resuelve para TODOS los motores (regla de oro 3: se escribe una vez):
## - Carga/parseo del nivel (`cargar_nivel`) y lectura del perfil (`obtener_perfil_dificultad`).
## - Voz y efectos via el autoload `Audio`, con rutas del JSON relativas a `res://assets/audio/`.
## - Celebracion final reutilizable (`celebrar`): monta `escenas/ui/celebracion.tscn`
##   (confeti, estrellitas, gesto real del hermano, conteo de destellos; GDD §6 regla 9),
##   espera a que termine y recien ahi emite `completado`.
## - Registro en `Progreso` al completar (solo si el contenedor fijo `planeta_id`), en un
##   unico lugar: los motores no tocan el guardado. Se guarda ANTES de mostrar la celebracion
##   (auditoria UX HE-10, B1): cerrar la app durante la fiesta nunca pierde el nivel ganado. Desde
##   QA HE-60 B1 el motor llama `asegurar_victoria()` en el instante de ganar, asi tampoco se pierde
##   en la pausa (confeti, voz del ultimo par, record) previa a la celebracion.
## - Salida segura: senal `salir_solicitado` (GDD §6 regla 8). El motor nunca navega.
##
## El nucleo del juego nunca conoce mecanicas concretas: solo instancia la escena del
## motor con `ruta_nivel` (y `planeta_id`) seteados y escucha `completado`/`salir_solicitado`.
##
## CONVENCION DE ESCENA (fix bug piloto "emparejar" 18-Jul-2026, ver motor_emparejar.tscn):
## la raiz del motor es `Node2D` (para poder usar nodos 2D como CPUParticles2D con
## coordenadas de mundo, p. ej. el confeti de victoria). Pero TODA la UI a pantalla
## completa de un motor (Control/Container/botones) debe colgar de un `CanvasLayer`
## hijo de esa raiz, NUNCA de un `Control` colgado directo del `Node2D`. Motivo: un
## `Control` sin un `CanvasLayer` (ni otro `Control`) como ancestro no resuelve su
## `size` contra el viewport — resuelve a (0,0), lo que rompe cualquier layout basado
## en anclas/centrado (confirmado con Godot 4.7: `Control` bajo `Node2D` directo mide
## (0,0); el mismo `Control` bajo `CanvasLayer` mide el viewport completo). Patron
## correcto para todo motor nuevo:
## Node2D (raiz, script del motor)
##   └─ CanvasLayer ("capa_ui")
##       └─ Control (full rect, anchors_preset=15) — resto de la UI aqui
##   └─ (nodos 2D de mundo, p. ej. CPUParticles2D de confeti)

##
## MODO EQUIPO (docs/fichas/modo-equipo.md §11.3 y §11.4; HE-59): si el contenedor fija `equipo` (2 o 3
## ids) y el nivel trae `"modo_juego": "equipo"`, `_ready()` crea un `GestorTurnos` en `turnos` (generico:
## orden, pase, puerta, rival, tope y racha). El motor solo resuelve su composicion, llama
## `turnos.configurar(...)` y decide cuando termina un turno. Esta base registra la victoria en
## `Progreso.registrar_victoria_equipo` (nunca la estacion individual de nadie), monta la fiesta
## multihermano (`celebrar_equipo`) y orquesta la derrota-gag con los virtuales `gag_derrota_*`.
##
## EXTENSIONES HE-76 (motor-lanzar.md §12, §13.2 y §25; genericas, el nucleo no conoce la Torre):
## - Modo sin pista del gestor: la derrota-gag no anima `pista_rival`; aspira hacia `ancla_rival_motor()` y
##   lee la voz de `variante_derrota()`.
## - Momentos saltables (`momento_saltable_iniciado/terminado`, `saltar_momento`): el contenedor decide si se
##   salta (cinematica ya vista por la familia); el motor solo deja el estado final. Con las cinematicas
##   postergadas por presupuesto (PO, 05-Nov-2026) es el mismo gancho para el reemplazo provisional.
## - Revancha (`revancha`, `resultado_revancha`). v4.1 (motor-lanzar §25.18.7): tambien tiene parcial, solo
##   entre etapas; el motor devuelve `{}` cuando no hay nada que guardar y la base no lo emite.
## - Parcial a demanda (`notificar_parcial_equipo`): en el derribo de cada etapa, al empezarla y al terminar
##   cada derrota-gag, ademas del de cada `turno_cerrado`. El estado puede traer `"etapa"` (Progreso lo
##   protege, R17 = A) y `"etapa_iniciada"` (la interpreta el motor; ausente = true).
## - Politica `una_vez` de batalla.gd (§25.18.6): salta EN el manejador de `momento_saltable_iniciado`;
##   `iniciar_momento_saltable()` devuelve false si el momento quedo saltado en ese mismo instante.

signal completado(destellos: int)
## El contenedor (escena del planeta) conecta esta senal para volver al mapa sin perder
## progreso (GDD §6 regla 8). Ningun motor navega por si mismo.
signal salir_solicitado()
## M4 (batalla, HE-69): parcial de la ronda tras cada turno cerrado. Fuera de la batalla nadie lo escucha
## (m3: el modo equipo suelto no guarda parciales).
signal parcial_equipo_listo(estado: Dictionary)
## HE-76 (motor-lanzar §13.2): un momento animado que se puede saltar desde la 2.a vez ("caida_etapa",
## "caida_torre"...). El contenedor marca la cinematica vista al recibir `terminado`. El nucleo no sabe que hay
## dentro: solo el id.
signal momento_saltable_iniciado(id_animacion: String)
signal momento_saltable_terminado(id_animacion: String)
## Revancha (motor-lanzar §11 y §25.15): se emite antes de `completado`. record = recursos usados (-1 = sin
## record, p. ej. hubo ayudas).
signal resultado_revancha(estrellitas: int, record: int)

const CELEBRACION_ESCENA := "res://escenas/ui/celebracion.tscn"
const PREFIJO_AUDIO := "res://assets/audio/"
## Respaldo cuando no hay hermano seleccionado (p. ej. un motor corrido suelto en el
## editor o en un arnes QA): el perfil del nivel indica a quien esta pensado.
const PERSONAJE_POR_PERFIL := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
## Margen tras la voz de cierre antes de auto-continuar, para no cortarla (auditoria UX HE-10, R6).
const MARGEN_VOZ_AUTO_CONTINUAR := 1.5

## Ruta res:// al JSON de nivel a cargar. Puede setearse desde el inspector (al
## instanciar el motor dentro de la escena de un planeta) o por codigo antes de
## que el nodo entre al arbol.
@export_file("*.json") var ruta_nivel: String = ""
## Planeta al que pertenece el nivel ("arcoiris", ...). Lo fija el contenedor. Vacio =
## no se registra progreso (motor en prueba).
@export var planeta_id: String = ""
## Hermano que juega ("maxi"/"nicole"/"sofia"). Vacio = se toma `Progreso.perfil_seleccionado`.
@export var id_perfil: String = ""
## Segundos tras los que la celebracion continua sola si nadie toca el boton (0 = nunca).
@export var segundos_auto_continuar: float = 8.0
## Economia de destellos (disenador-niveles HE-40 §2.3, PROVISIONAL): si el contenedor lo fija (>= 0),
## la estacion celebra y registra ESTE monto en vez del calculo del motor (100 por estacion, 0 en retos
## dorados), igual para los tres hermanos. -1 = cada motor calcula el suyo (demo, arneses QA). El
## conteo por pieza/par/gota se sigue viendo durante el juego como feedback.
@export var destellos_fijos: int = -1
## Vacio = juego en solitario (todo igual que antes). 2 o 3 ids = modo equipo (si el nivel lo admite).
@export var equipo: Array[String] = []
## Revancha (motor-lanzar §11): el contenedor la pone antes de agregar el motor al arbol. Sin parcial.
@export var revancha: bool = false
## Ronda de batalla (modo-equipo.md §14.9 y §14.15 punto 5; lo fija batalla.gd, HE-69): al ganar, el motor no
## registra la victoria de equipo ni hace su fiesta: solo emite `completado(0)` (el interludio es de la batalla).
@export var en_batalla: bool = false

## Monto por hermano si el contenedor no fija `destellos_fijos` en un nivel de equipo (§7.1).
const DESTELLOS_EQUIPO_POR_DEFECTO := 50
const LADO_OTRA_VEZ_EQUIPO := 180.0

## Contenido del nivel ya parseado (Dictionary). Vacio si la carga fallo.
var nivel: Dictionary = {}
## Lo crea `_ready()` si `es_modo_equipo()`; null en solitario.
var turnos: GestorTurnos = null

var _celebrando := false
var _completado_emitido := false
var _progreso_registrado := false
var _resultado_equipo: Dictionary = {}
var _en_gag_equipo := false
var _gag_terminado := false
var _id_gag := 0
var _capa_gag: CanvasLayer
var _boton_otra_vez_equipo: Button
## Momentos saltables en curso (ids), en el orden en que empezaron.
var _momentos_en_curso: Array[String] = []


func _ready() -> void:
	if id_perfil == "" and equipo.is_empty():
		var progreso := get_node_or_null("/root/Progreso")
		if progreso != null:
			id_perfil = progreso.perfil_seleccionado
	if ruta_nivel != "":
		cargar_nivel(ruta_nivel)
	if es_modo_equipo():
		id_perfil = ""
		turnos = GestorTurnos.new()
		turnos.name = "gestor_turnos"
		add_child(turnos)
		turnos.rival_llego.connect(_al_llegar_rival)
		turnos.turno_cerrado.connect(func(_id: String, _perfecto: bool) -> void:
			notificar_parcial_equipo())


## Carga y parsea el JSON de nivel indicado. Devuelve el Dictionary resultante
## (vacio si hubo error). Los motores concretos pueden llamarla directamente para
## recargar contenido (p. ej. al reintentar con otro nivel).
func cargar_nivel(ruta: String) -> Dictionary:
	ruta_nivel = ruta
	nivel = {}
	_completado_emitido = false
	_progreso_registrado = false
	if not FileAccess.file_exists(ruta):
		push_error("minijuego_base: no se encontro el archivo de nivel: %s" % ruta)
		return nivel
	var texto := FileAccess.get_file_as_string(ruta)
	var resultado: Variant = JSON.parse_string(texto)
	if resultado is Dictionary:
		nivel = resultado
	else:
		push_error("minijuego_base: JSON invalido en %s" % ruta)
	return nivel


## "semilla" | "brote" | "estrella", tal cual viene en el nivel. En equipo (modo-equipo.md §14.15 punto 2,
## HE-70), el perfil del turno en curso (el del hermano cuyo retrato esta al centro o jugando); antes del
## primer turno, el del nivel.
func obtener_perfil_dificultad() -> String:
	if turnos != null and turnos.perfil_actual() != "":
		return turnos.perfil_actual()
	return String(nivel.get("perfil", "semilla"))


## Id del personaje que celebra: el hermano que juega o, en su defecto, el pensado por el perfil.
func obtener_id_personaje() -> String:
	# En equipo, el que juega el turno (lo usan las voces y los gestos del turno).
	if turnos != null and turnos.hermano_actual() != "":
		return turnos.hermano_actual()
	if id_perfil != "":
		return id_perfil
	return PERSONAJE_POR_PERFIL.get(obtener_perfil_dificultad(), "cometa")


## Las rutas de audio del JSON son relativas a assets/audio/ ("voces/emparejar/...ogg").
func resolver_ruta_audio(ruta: String) -> String:
	if ruta == "" or ruta.begins_with("res://"):
		return ruta
	return PREFIJO_AUDIO + ruta


func reproducir_voz(ruta: String) -> void:
	var ruta_final := resolver_ruta_audio(ruta)
	if ruta_final == "":
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta_final)


## `tono` cambia la altura del efecto (1.0 = original): p. ej. el "ding" de una racha sube un semitono por
## eslabon, como el reventon del Rio de pintura.
func reproducir_sfx(ruta: String, tono: float = 1.0, volumen_db: float = 0.0) -> void:
	var ruta_final := resolver_ruta_audio(ruta)
	if ruta_final == "":
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta_final, tono, volumen_db)


## Salir siempre es seguro (GDD §6 regla 8; QA HE-60 B1 y m8): el motor la llama EN EL INSTANTE en que
## el nino gana (ultimo par, ultima pieza, ultimo mural...), antes de cualquier animacion, voz de record o
## pausa previa a `celebrar()`. Guarda destellos, estrellitas y la estacion completada; si despues el nino
## toca "salir" y el motor se libera durante la fiesta, no se pierde nada. `celebrar()` ya no vuelve a
## guardar (es una sola vez por nivel cargado). Los motores solo pasan sus numeros: no tocan el guardado.
func asegurar_victoria(destellos: int, estrellitas: int = 0) -> void:
	_registrar_una_vez(_destellos_finales(destellos), _estrellitas_visibles(estrellitas))


## Celebracion final comun a todos los motores (GDD §6 regla 9). Monta la escena de
## celebracion encima del motor, reproduce la linea de voz de cierre, espera a que el nino
## toque "seguir" (o al auto-continuar) y emite `completado(destellos)`.
## `estrellitas` (1-3) solo se muestran en perfil Estrella (ficha motor-emparejar §7).
## Llamadas repetidas mientras ya se celebra se ignoran.
func celebrar(destellos: int, estrellitas: int = 0, linea_voz: String = "") -> void:
	if _celebrando or _completado_emitido:
		return
	_celebrando = true
	destellos = _destellos_finales(destellos)
	var estrellitas_visibles := _estrellitas_visibles(estrellitas)
	# B1: el progreso queda guardado antes de la fiesta (salir siempre es seguro, GDD §6 regla 8).
	_registrar_una_vez(destellos, estrellitas_visibles)
	var escena: PackedScene = load(CELEBRACION_ESCENA)
	var celebracion := escena.instantiate()
	celebracion.id_personaje = obtener_id_personaje()
	celebracion.destellos = destellos
	celebracion.estrellitas = estrellitas_visibles
	# Brote (ficha motor-emparejar §10.1.1): nunca huecos vacios, solo las estrellitas ganadas.
	celebracion.estrellitas_sin_huecos = obtener_perfil_dificultad() == "brote"
	celebracion.segundos_auto_continuar = _segundos_auto_continuar_con_voz(linea_voz)
	add_child(celebracion)
	reproducir_voz(linea_voz)
	await celebracion.terminada
	celebracion.queue_free()
	# R6: si el nino toco "seguir" antes, la voz de cierre no se encima a la pantalla siguiente.
	var audio := get_node_or_null("/root/Audio")
	if audio != null and linea_voz != "":
		audio.detener_voz()
	_celebrando = false
	emitir_completado(destellos, estrellitas_visibles)


func _destellos_finales(destellos: int) -> int:
	return destellos_fijos if destellos_fijos >= 0 else destellos


## Estrellitas solo en niveles Estrella jugados por quien tiene ese perfil (M4): un hermano
## menor que prueba un nivel de Sofia no ve huecos de estrella vacios. Desde HE-60 (ficha
## motor-emparejar §10.1.1) tambien un nivel Brote jugado por quien tiene ese perfil, si el nivel
## puntua por puntaje (`umbrales_puntaje`); ahi la estrellita minima es 1 ("la estrella de terminar").
func _estrellitas_visibles(estrellitas: int) -> int:
	# En equipo no hay estrellitas individuales (R2): la meta compartida es la estrellita del boton.
	if es_modo_equipo():
		return 0
	var perfil := obtener_perfil_dificultad()
	if perfil == "estrella" and obtener_id_personaje() == PERSONAJE_POR_PERFIL["estrella"]:
		return clampi(estrellitas, 0, 3)
	if perfil == "brote" and nivel.has("umbrales_puntaje") and obtener_id_personaje() == PERSONAJE_POR_PERFIL["brote"]:
		return clampi(estrellitas, 1, 3)
	return 0


## Nunca auto-continua antes de que termine la voz de cierre (+ margen). 0 se respeta (espera toque).
func _segundos_auto_continuar_con_voz(linea_voz: String) -> float:
	if segundos_auto_continuar <= 0.0:
		return 0.0
	var ruta := resolver_ruta_audio(linea_voz)
	if ruta == "" or not ResourceLoader.exists(ruta):
		return segundos_auto_continuar
	var stream := load(ruta) as AudioStream
	if stream == null:
		return segundos_auto_continuar
	return maxf(segundos_auto_continuar, stream.get_length() + MARGEN_VOZ_AUTO_CONTINUAR)


## Punto unico de salida exitosa del motor. Registra el resultado en `Progreso` (si hay
## `planeta_id`) y emite `completado` una sola vez por nivel cargado.
func emitir_completado(destellos: int, estrellitas: int = 0) -> void:
	if _completado_emitido:
		return
	_completado_emitido = true
	destellos = _destellos_finales(destellos)
	_registrar_una_vez(destellos, estrellitas)
	completado.emit(destellos)


func _registrar_una_vez(destellos: int, estrellitas: int) -> void:
	if _progreso_registrado:
		return
	_progreso_registrado = true
	_registrar_progreso(destellos, estrellitas)


func _registrar_progreso(destellos: int, estrellitas: int) -> void:
	# En equipo nunca se marca la estacion individual de nadie (PO, §7.1): registra `asegurar_victoria_equipo`.
	if es_modo_equipo():
		return
	if planeta_id == "" or id_perfil == "":
		return
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null:
		return
	progreso.marcar_nivel_completado(id_perfil, planeta_id, _id_nivel_actual(), destellos, estrellitas)
	# Un nivel ganado ya no tiene avance a medio jugar que retomar.
	progreso.borrar_estado_parcial(id_perfil, planeta_id, _id_nivel_actual())


func _id_nivel_actual() -> String:
	return str(nivel.get("id_nivel", ruta_nivel.get_file().get_basename()))


## Avance a medio jugar de este nivel para este hermano (niveles largos, p. ej. el reto dorado).
## Sin `planeta_id` (motor en prueba) no se guarda nada: el contrato es el mismo para todos los motores.
func guardar_estado_parcial(estado: Dictionary) -> void:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and id_perfil != "":
		progreso.guardar_estado_parcial(id_perfil, planeta_id, _id_nivel_actual(), estado)


func obtener_estado_parcial() -> Dictionary:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "" or id_perfil == "":
		return {}
	return progreso.obtener_estado_parcial(id_perfil, planeta_id, _id_nivel_actual())


func borrar_estado_parcial() -> void:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and id_perfil != "":
		progreso.borrar_estado_parcial(id_perfil, planeta_id, _id_nivel_actual())


## Record (mejor puntaje, "mas es mejor") de este nivel para este hermano: 0 = todavia no hay. Sin
## `planeta_id` (motor en prueba) no hay record guardado. Los motores no tocan el guardado.
func obtener_record() -> int:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "" or id_perfil == "":
		return 0
	return progreso.obtener_record_nivel(id_perfil, planeta_id, _id_nivel_actual())


## Guarda `puntaje` si supera el record. Devuelve true si es record nuevo (y quedo guardado).
func registrar_record(puntaje: int) -> bool:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "" or id_perfil == "":
		return false
	return progreso.registrar_puntaje_nivel(id_perfil, planeta_id, _id_nivel_actual(), puntaje)


## Mejores estrellitas ya ganadas en este nivel (0 si nunca se completo o no hay guardado).
func obtener_estrellitas_previas() -> int:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "" or id_perfil == "":
		return 0
	return progreso.obtener_estrellitas_nivel(id_perfil, planeta_id, _id_nivel_actual())


## Presentaciones de una sola vez por hermano ("vistazo", "vela", "lupa"...). Sin guardado (motor en
## prueba) nunca se dan por vistas, asi la presentacion se puede revisar siempre.
func presentacion_vista(tipo: String) -> bool:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or id_perfil == "" or planeta_id == "":
		return false
	return progreso.especial_conocido(id_perfil, tipo)


func marcar_presentacion_vista(tipo: String) -> void:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and id_perfil != "" and planeta_id != "":
		progreso.marcar_especial_conocido(id_perfil, tipo)


# ---------------------------------------------------------------------------
# Modo equipo (docs/fichas/modo-equipo.md §11.3 y §11.4; HE-59)
# ---------------------------------------------------------------------------

## equipo.size() >= 2 y el nivel trae "modo_juego": "equipo".
func es_modo_equipo() -> bool:
	return equipo.size() >= 2 and str(nivel.get("modo_juego", "")) == "equipo"


## Dificultad de un hermano: respeta el ajuste de la zona de padres. Sin Progreso, la de su edad.
func perfil_de(id_hermano: String) -> String:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null:
		var perfil: String = progreso.obtener_perfil_dificultad(id_hermano)
		if perfil != "":
			return perfil
	for perfil in PERSONAJE_POR_PERFIL:
		if PERSONAJE_POR_PERFIL[perfil] == id_hermano:
			return perfil
	return "semilla"


## Registra la victoria del equipo UNA vez, en el instante de ganar (QA HE-60 B1, GDD §6.8): 50 destellos
## a cada hermano que aun no los cobro en este nivel, el nivel en "ganados" y el record de pasos. Devuelve
## {premiados, record_nuevo, primer_record, primera_victoria_nivel}. Sin `planeta_id` (prueba) no guarda.
func asegurar_victoria_equipo(pasos_usados: int) -> Dictionary:
	if _progreso_registrado:
		return _resultado_equipo
	_progreso_registrado = true
	var monto := destellos_fijos if destellos_fijos >= 0 else DESTELLOS_EQUIPO_POR_DEFECTO
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "":
		var ninguno: Array[String] = []
		_resultado_equipo = {"premiados": ninguno, "record_nuevo": false, "primer_record": false,
			"primera_victoria_nivel": false}
		return _resultado_equipo
	_resultado_equipo = progreso.registrar_victoria_equipo(planeta_id, _id_nivel_actual(), equipo, monto, pasos_usados)
	return _resultado_equipo


## Reemplaza a celebrar() en equipo: registra ANTES de la fiesta (B1 de HE-10) y monta la celebracion
## multihermano (§5.6). pasos_usados = posicion del rival al ganar.
func celebrar_equipo(pasos_usados: int, linea_voz: String = "") -> void:
	if _celebrando or _completado_emitido:
		return
	_celebrando = true
	var resultado := asegurar_victoria_equipo(pasos_usados)
	var monto := destellos_fijos if destellos_fijos >= 0 else DESTELLOS_EQUIPO_POR_DEFECTO
	var escena: PackedScene = load(CELEBRACION_ESCENA)
	var celebracion := escena.instantiate()
	var ids: Array[String] = turnos.orden_unico() if turnos != null else equipo.duplicate()
	celebracion.ids_personajes = ids
	celebracion.id_personaje = ids[0] if not ids.is_empty() else "cometa"
	celebracion.premiados = resultado.get("premiados", [])
	celebracion.destellos = monto
	celebracion.estrellita_equipo = bool(resultado.get("primera_victoria_nivel", false))
	celebracion.voces_fiesta = _voces_fiesta()
	celebracion.segundos_auto_continuar = maxf(_segundos_auto_continuar_con_voz(linea_voz), 6.0 + ids.size() * 1.2) \
		if segundos_auto_continuar > 0.0 else 0.0
	add_child(celebracion)
	reproducir_voz(linea_voz)
	await celebracion.terminada
	celebracion.queue_free()
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()
	_celebrando = false
	emitir_completado(monto, 0)


## Voces de la fiesta del equipo (`lineas_voz.fiesta`), ya resueltas a res://. Las que no existen se omiten.
func _voces_fiesta() -> Dictionary:
	var fiesta = nivel.get("lineas_voz", {}).get("fiesta", {})
	if not fiesta is Dictionary:
		return {}
	var resueltas := {}
	for clave in fiesta:
		var valor = fiesta[clave]
		if valor is Dictionary:
			var por_id := {}
			for id in valor:
				por_id[id] = resolver_ruta_audio(str(valor[id]))
			resueltas[clave] = por_id
		else:
			resueltas[clave] = resolver_ruta_audio(str(valor))
	return resueltas


# --- Virtuales del motor para el modo equipo (implementacion vacia: un motor sin gag propio igual
# completa la secuencia de la derrota) ---

## Punto global del borde DERECHO-centro de la guirnalda (16 px a la izquierda de la mesa del motor).
## Vector2.INF = el gestor la pega a x 40, centrada en y 364.
func ancla_meta_turno() -> Vector2:
	return Vector2.INF


## Hace volar los elementos pendientes hacia `destino` (boca de la mochila-torre) y los oculta. Devuelve s.
func gag_derrota_aspirar(_destino: Vector2) -> float:
	return 0.0


## Los devuelve "estornudados" a su lugar, en el estado del perfil que juega despues. Devuelve s.
func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	return 0.0


## Corta lo que este en vuelo y deja al instante el estado final de "devolver".
func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	pass


## Lo propio del reintento (Parejas: revuelve las pendientes y hace un vistazo nuevo). Puede ser coroutine.
func reintentar_equipo() -> void:
	pass


## Cuanto se conservo en ESTA partida o ronda (pares, piezas, gotas) para el logro comun de Cometa.
func contar_logro_equipo() -> int:
	return 0


## M4 (batalla): estado de la ronda para retomarla. Fuera de la batalla no se usa.
func obtener_parcial_equipo() -> Dictionary:
	return {}


func restaurar_parcial_equipo(_estado: Dictionary) -> void:
	pass


## Emite el parcial de la ronda (`obtener_parcial_equipo()`) para quien lo guarde (batalla.gd). La base lo
## llama en cada `turno_cerrado` y al terminar cada derrota-gag; el motor, cuando su ficha pide otro momento
## (la Torre: en el derribo de E1/E2 y al empezar cada etapa, R17 = A). En solitario no emite; un estado vacio
## (`{}`: nada que guardar, p. ej. la revancha a mitad de E1) tampoco se emite.
func notificar_parcial_equipo() -> void:
	if not es_modo_equipo():
		return
	var estado := obtener_parcial_equipo()
	if estado.is_empty():
		return
	parcial_equipo_listo.emit(estado)


# --- Extensiones HE-76 (motor-lanzar §13.2): virtuales y momentos saltables ---

## Boca del rival en la escena del motor (modo sin pista): hacia aqui vuela lo que se aspira. Vacia = centro.
func ancla_rival_motor() -> Vector2:
	return Vector2(640, 360)


## Variante de la derrota-gag: "" = `lineas_voz.derrota_gag_equipo` es un Array (lo de Parejas); si no, la base
## lee `derrota_gag_equipo[clave]` (un Array). El motor decide la rotacion; la base no sabe que gag es.
func variante_derrota() -> String:
	return ""


## Virtual: corta el momento `id_animacion`, deja su estado final y llama `terminar_momento_saltable(id)`
## (como si hubiera terminado solo). Por defecto solo lo da por terminado: un motor que no anima nada propio
## (p. ej. una presentacion de voz) no necesita sobreescribirla. Puede llegar dentro del manejador de
## `momento_saltable_iniciado` (politica `una_vez`, conexion directa).
func saltar_momento(id_animacion: String) -> void:
	terminar_momento_saltable(id_animacion)


## El motor avisa que empieza un momento saltable. Devuelve true si sigue en curso despues de emitir; false si
## el contenedor lo salto en ese mismo instante (`una_vez` ya visto) o si ya estaba en curso: el motor entonces
## no muestra nada (en la bandeja de Nicole, suena `carga`). Llamadas repetidas con el mismo id se ignoran.
func iniciar_momento_saltable(id_animacion: String) -> bool:
	if id_animacion == "" or id_animacion in _momentos_en_curso:
		return false
	_momentos_en_curso.append(id_animacion)
	momento_saltable_iniciado.emit(id_animacion)
	return id_animacion in _momentos_en_curso


## El motor avisa que el momento termino (solo o saltado). Solo emite si estaba en curso: una vez por momento.
func terminar_momento_saltable(id_animacion: String) -> void:
	if not id_animacion in _momentos_en_curso:
		return
	_momentos_en_curso.erase(id_animacion)
	momento_saltable_terminado.emit(id_animacion)


func momento_saltable_en_curso(id_animacion: String = "") -> bool:
	if id_animacion == "":
		return not _momentos_en_curso.is_empty()
	return id_animacion in _momentos_en_curso


# --- Derrota-gag del equipo (§5.5 y §11.4): la orquesta la base ---

## El rival llego a la mesa: el retrato del siguiente ya esta al centro y la entrada bloqueada.
func _al_llegar_rival() -> void:
	_en_gag_equipo = true
	_gag_terminado = false
	_id_gag += 1
	var id := _id_gag
	turnos.barra.achicar_centro()
	_mostrar_otra_vez_equipo()
	# Sin pista (la Torre) el rival vive en la escena del motor: la base no anima pista_rival y apunta a su ancla.
	var sin_pista := turnos.sin_pista()
	var boca := ancla_rival_motor() if sin_pista else turnos.posicion_boca_rival()
	# 1-2. La mochila-torre aspira lo pendiente ("¡a mi coleccion!", "sluuurp").
	var linea := _lineas_gag()
	_decir_gag(linea, 0)
	var t_aspira := gag_derrota_aspirar(boca)
	if not sin_pista:
		t_aspira = maxf(turnos.pista.aspirar(), t_aspira)
	await get_tree().create_timer(maxf(t_aspira, 0.01)).timeout
	if id != _id_gag or not _en_gag_equipo:
		return
	# 3. Se infla, estornuda y todo vuelve a la mesa, ya listo para quien juega despues.
	_decir_gag(linea, 1)
	var t_devuelve := gag_derrota_devolver(turnos.perfil_actual())
	if not sin_pista:
		t_devuelve = maxf(turnos.pista.estornudar(), t_devuelve)
	await get_tree().create_timer(maxf(t_devuelve, 0.01)).timeout
	if id != _id_gag or not _en_gag_equipo:
		return
	_gag_terminado = true
	# motor-lanzar §12: el intento nuevo (con sus ayudas) queda guardado aunque salgan antes de "¡otra vez!".
	notificar_parcial_equipo()
	# 4. Cae sentado; voces en plural (nunca nombran a un hermano, B3.3) y el logro comun de Cometa.
	if not sin_pista:
		turnos.pista.sentarse()
	for i in range(2, linea.size()):
		await _esperar_voz_libre(4.0)
		if id != _id_gag or not _en_gag_equipo:
			return
		_decir_gag(linea, i)
	await _esperar_voz_libre(4.0)
	if id != _id_gag or not _en_gag_equipo:
		return
	reproducir_voz(_linea_logro_comun(contar_logro_equipo()))


## Lineas de la derrota-gag: un Array (Parejas) o, con `variante_derrota()` != "", el Array de esa clave en un
## mapa (la Torre). "PENDIENTE" (o cualquier valor que no sea Array) = clave ausente (nota HE-69, 07-Oct).
func _lineas_gag() -> Array:
	var lineas = nivel.get("lineas_voz", {}).get("derrota_gag_equipo", [])
	var variante := variante_derrota()
	if lineas is Dictionary:
		lineas = lineas.get(variante, []) if variante != "" else []
	return lineas if lineas is Array else []


func _decir_gag(lineas: Array, i: int) -> void:
	if i < lineas.size() and str(lineas[i]) != "PENDIENTE":
		reproducir_voz(str(lineas[i]))


## "¡Igual juntamos N parejas!": `logro_comun` (mapa "N" -> ruta) o, por compatibilidad, `pares_juntados`;
## con 0, `nos_alcanzo`.
func _linea_logro_comun(n: int) -> String:
	var voces: Dictionary = nivel.get("lineas_voz", {})
	if n <= 0:
		return str(voces.get("nos_alcanzo", ""))
	var mapa = voces.get("logro_comun", voces.get("pares_juntados", {}))
	return str(mapa.get(str(n), "")) if mapa is Dictionary else ""


func _esperar_voz_libre(maximo: float) -> void:
	var audio := get_node_or_null("/root/Audio")
	var inicio := Time.get_ticks_msec()
	await get_tree().process_frame
	while audio != null and audio.esta_hablando() and Time.get_ticks_msec() - inicio < maximo * 1000.0:
		await get_tree().process_frame


## "¡Otra vez!" de >= 160 x 160 px (m4), desde el segundo 0 del gag, centrado sobre el gag.
func _mostrar_otra_vez_equipo() -> void:
	if _capa_gag == null:
		_capa_gag = CanvasLayer.new()
		_capa_gag.layer = 5
		add_child(_capa_gag)
		_boton_otra_vez_equipo = Button.new()
		_boton_otra_vez_equipo.name = "boton_otra_vez_equipo"
		_boton_otra_vez_equipo.focus_mode = Control.FOCUS_NONE
		_boton_otra_vez_equipo.size = Vector2.ONE * LADO_OTRA_VEZ_EQUIPO
		_boton_otra_vez_equipo.position = Vector2(640, 470) - _boton_otra_vez_equipo.size / 2.0
		_boton_otra_vez_equipo.pivot_offset = _boton_otra_vez_equipo.size / 2.0
		_boton_otra_vez_equipo.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("#FFCB3D")
		estilo.border_color = Color("#2B3350")
		estilo.set_border_width_all(7)
		estilo.set_corner_radius_all(int(LADO_OTRA_VEZ_EQUIPO / 2.0))
		for nombre in ["normal", "hover", "pressed", "disabled", "focus"]:
			_boton_otra_vez_equipo.add_theme_stylebox_override(nombre, estilo)
		var icono := Control.new()
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono.size = _boton_otra_vez_equipo.size
		icono.draw.connect(func() -> void:
			# Flecha circular universal de "otra vez", sin texto.
			var c := icono.size / 2.0
			icono.draw_arc(c, 50.0, -PI * 0.15, PI * 1.45, 32, Color.WHITE, 16.0, true)
			var punta := c + Vector2.from_angle(-PI * 0.15) * 50.0
			icono.draw_colored_polygon(PackedVector2Array([punta + Vector2(-20, -14), punta + Vector2(22, -6), punta + Vector2(2, 26)]), Color.WHITE))
		_boton_otra_vez_equipo.add_child(icono)
		_capa_gag.add_child(_boton_otra_vez_equipo)
		_boton_otra_vez_equipo.pressed.connect(tocar_otra_vez_equipo)
	_boton_otra_vez_equipo.show()
	_boton_otra_vez_equipo.scale = Vector2.ZERO
	_boton_otra_vez_equipo.create_tween().tween_property(_boton_otra_vez_equipo, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## "¡Otra vez!" (en cualquier momento del gag): lo conservado queda, el rival vuelve a 0 y se abre la puerta
## del que ya estaba al centro. Tambien lo llaman los arneses.
func tocar_otra_vez_equipo() -> void:
	if not _en_gag_equipo:
		return
	_en_gag_equipo = false
	_id_gag += 1
	if _boton_otra_vez_equipo != null:
		_boton_otra_vez_equipo.hide()
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()
	if not _gag_terminado:
		_gag_terminado = true
		gag_derrota_terminar_ya(turnos.perfil_actual())
		notificar_parcial_equipo()
	await reintentar_equipo()
	if is_inside_tree():
		turnos.reiniciar_rival()


func en_derrota_equipo() -> bool:
	return _en_gag_equipo
