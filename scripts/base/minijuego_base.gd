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
##   (auditoria UX HE-10, B1): cerrar la app durante la fiesta nunca pierde el nivel ganado.
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

signal completado(destellos: int)
## El contenedor (escena del planeta) conecta esta senal para volver al mapa sin perder
## progreso (GDD §6 regla 8). Ningun motor navega por si mismo.
signal salir_solicitado()

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

## Contenido del nivel ya parseado (Dictionary). Vacio si la carga fallo.
var nivel: Dictionary = {}

var _celebrando := false
var _completado_emitido := false
var _progreso_registrado := false


func _ready() -> void:
	if id_perfil == "":
		var progreso := get_node_or_null("/root/Progreso")
		if progreso != null:
			id_perfil = progreso.perfil_seleccionado
	if ruta_nivel != "":
		cargar_nivel(ruta_nivel)


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


## "semilla" | "brote" | "estrella", tal cual viene en el nivel.
func obtener_perfil_dificultad() -> String:
	return String(nivel.get("perfil", "semilla"))


## Id del personaje que celebra: el hermano que juega o, en su defecto, el pensado por el perfil.
func obtener_id_personaje() -> String:
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


func reproducir_sfx(ruta: String) -> void:
	var ruta_final := resolver_ruta_audio(ruta)
	if ruta_final == "":
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta_final)


## Celebracion final comun a todos los motores (GDD §6 regla 9). Monta la escena de
## celebracion encima del motor, reproduce la linea de voz de cierre, espera a que el nino
## toque "seguir" (o al auto-continuar) y emite `completado(destellos)`.
## `estrellitas` (1-3) solo se muestran en perfil Estrella (ficha motor-emparejar §7).
## Llamadas repetidas mientras ya se celebra se ignoran.
func celebrar(destellos: int, estrellitas: int = 0, linea_voz: String = "") -> void:
	if _celebrando or _completado_emitido:
		return
	_celebrando = true
	var estrellitas_visibles := _estrellitas_visibles(estrellitas)
	# B1: el progreso queda guardado antes de la fiesta (salir siempre es seguro, GDD §6 regla 8).
	_registrar_una_vez(destellos, estrellitas_visibles)
	var escena: PackedScene = load(CELEBRACION_ESCENA)
	var celebracion := escena.instantiate()
	celebracion.id_personaje = obtener_id_personaje()
	celebracion.destellos = destellos
	celebracion.estrellitas = estrellitas_visibles
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


## Estrellitas solo en niveles Estrella jugados por quien tiene ese perfil (M4): un hermano
## menor que prueba un nivel de Sofia no ve huecos de estrella vacios.
func _estrellitas_visibles(estrellitas: int) -> int:
	if obtener_perfil_dificultad() != "estrella":
		return 0
	if obtener_id_personaje() != PERSONAJE_POR_PERFIL["estrella"]:
		return 0
	return clampi(estrellitas, 0, 3)


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
	_registrar_una_vez(destellos, estrellitas)
	completado.emit(destellos)


func _registrar_una_vez(destellos: int, estrellitas: int) -> void:
	if _progreso_registrado:
		return
	_progreso_registrado = true
	_registrar_progreso(destellos, estrellitas)


func _registrar_progreso(destellos: int, estrellitas: int) -> void:
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
