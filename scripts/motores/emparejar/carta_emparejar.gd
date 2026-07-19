class_name CartaEmparejar
extends Control

## Una carta/elemento tocable del motor "emparejar" (docs/fichas/motor-emparejar.md).
## PLACEHOLDER VISUAL: sin sprites finales todavia, usa color + texto (id_pareja) como
## marcador. dev-godot/disenador-personajes reemplazan esto por los sprites reales del
## contrato de datos (elemento_a.sprite, elemento_b.sprite, sprite_dorso) sin tocar la
## logica de estados de este script.
##
## Corrige hallazgo B1 (auditoria UX 18-Jul-2026): ya NO extiende `Button` nativo. Un
## `BaseButton` cancela el toque si el puntero sale del rect mientras esta presionado, lo
## que pierde toques ante el arrastre corto natural de un dedo (contrato §3 de la ficha de
## motor: "un gesto de arrastre iniciado sobre un elemento se trata como un toque simple
## sobre el punto de origen"). Este script rastrea press/release por posicion global con
## una tolerancia de movimiento, sin depender del ruteo de rect de los Control nativos.

signal tocada(carta: CartaEmparejar)

const TAMANO_MINIMO := Vector2(140, 140)  ## >= 64px GDD §6.1 (Estrella; Semilla exige >=96px)
const TOLERANCIA_TOQUE_PX := 56.0  ## radio de tolerancia de arrastre corto (B1)

const COLOR_NORMAL := Color(0.55, 0.75, 0.95)
const COLOR_SELECCIONADA := Color(1.0, 0.85, 0.3)
const COLOR_ACERTADA := Color(0.45, 0.85, 0.55)
const COLOR_DORSO := Color(0.35, 0.35, 0.55)
const COLOR_NO_ES_ESTE := Color(0.9, 0.6, 0.85)

var id_elemento: String = ""
var id_pareja: String = ""
var sprite_ruta: String = ""      ## TODO(arte): usar Texture real en vez de texto placeholder
var esta_acertada: bool = false
var disabled: bool = false

var _oculto: bool = false
var _mostrando: bool = false
var _color_base: Color = COLOR_NORMAL

var _rastreando := false
var _indice_toque := -2  ## -1 = mouse, >=0 = indice de InputEventScreenTouch
var _punto_inicio := Vector2.ZERO

@onready var _fondo: ColorRect = %fondo
@onready var _etiqueta: Label = %etiqueta


func _ready() -> void:
	custom_minimum_size = TAMANO_MINIMO
	mouse_filter = Control.MOUSE_FILTER_STOP
	_actualizar_visual()


## Prepara la carta con los datos de un elemento del par (contrato §4 de la ficha).
func configurar(nuevo_id_pareja: String, nuevo_id_elemento: String, nuevo_sprite_ruta: String, oculto: bool) -> void:
	id_pareja = nuevo_id_pareja
	id_elemento = nuevo_id_elemento
	sprite_ruta = nuevo_sprite_ruta
	esta_acertada = false
	disabled = false
	reiniciar(oculto)


func _input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventScreenTouch:
		print("[DEBUG carta %s] InputEventScreenTouch pos=%s pressed=%s" % [id_elemento, event.position, event.pressed])
		_procesar_evento(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		print("[DEBUG carta %s] InputEventMouseButton pos=%s pressed=%s global_rect=%s" % [id_elemento, event.position, event.pressed, get_global_rect()])
		_procesar_evento(-1, event.position, event.pressed)


## Rastrea press/release por posicion global, sin exigir que el release ocurra dentro del
## rect (a diferencia de BaseButton). Si el release cae dentro de TOLERANCIA_TOQUE_PX del
## punto de origen, se considera un toque valido (B1).
func _procesar_evento(indice: int, posicion_global: Vector2, presionado: bool) -> void:
	if presionado:
		if _rastreando:
			return
		if not get_global_rect().has_point(posicion_global):
			return
		_rastreando = true
		_indice_toque = indice
		_punto_inicio = posicion_global
	else:
		if not _rastreando or _indice_toque != indice:
			print("[DEBUG carta %s] release ignorado: rastreando=%s indice=%s vs %s" % [id_elemento, _rastreando, _indice_toque, indice])
			return
		_rastreando = false
		var distancia := posicion_global.distance_to(_punto_inicio)
		print("[DEBUG carta %s] release distancia=%s tolerancia=%s" % [id_elemento, distancia, TOLERANCIA_TOQUE_PX])
		if distancia <= TOLERANCIA_TOQUE_PX:
			print("[DEBUG carta %s] EMITE tocada" % id_elemento)
			tocada.emit(self)


## Toque 1: seleccionar (revela si estaba tapada). Feedback <100ms (GDD §6.4).
func seleccionar() -> void:
	_mostrando = true
	_color_base = COLOR_SELECCIONADA
	_reventar_pulso()
	_actualizar_visual()


## Deselecciona (voluntaria, timeout de volteo, o tras "no es este"). Vuelve a taparse
## si el modo es oculto.
func deseleccionar(oculto: bool) -> void:
	if esta_acertada:
		return
	_mostrando = not oculto
	_color_base = COLOR_NORMAL
	_actualizar_visual()


## Par acertado: queda visible y deshabilitada, con micro-celebracion (§3/§7 ficha de motor).
func marcar_acertada() -> void:
	esta_acertada = true
	_mostrando = true
	disabled = true
	_color_base = COLOR_ACERTADA
	_actualizar_visual()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)


## "No es este" (§3 fila 2b): meneo amistoso, nunca temblor de error.
func animar_no_es_este() -> void:
	_color_base = COLOR_NO_ES_ESTE
	_actualizar_visual()
	var tween := create_tween()
	tween.tween_property(self, "rotation", deg_to_rad(-6), 0.08)
	tween.tween_property(self, "rotation", deg_to_rad(6), 0.08)
	tween.tween_property(self, "rotation", 0.0, 0.08)


## Reinicio tras derrota-gag: solo se llama sobre cartas no acertadas (§6 ficha de motor).
func reiniciar(oculto: bool) -> void:
	_oculto = oculto
	_mostrando = not oculto
	esta_acertada = false
	disabled = false
	rotation = 0.0
	scale = Vector2.ONE
	_color_base = COLOR_NORMAL if _mostrando else COLOR_DORSO
	_actualizar_visual()


## Corrige hallazgo B2 (auditoria UX 18-Jul-2026): feedback minimo cuando el motor recibe
## un toque mientras esta resolviendo un "no es este" (_procesando == true). No cambia
## estado de seleccion, solo confirma al nino que su toque "existio" (GDD §6 regla 5).
func pulso_espera() -> void:
	_reventar_pulso()


func _reventar_pulso() -> void:
	scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)


func _actualizar_visual() -> void:
	if _fondo:
		_fondo.color = _color_base
	if _mostrando:
		# TODO(arte): reemplazar por TextureRect con sprite_ruta cuando exista el sprite final.
		_etiqueta.text = _texto_marcador()
	else:
		_etiqueta.text = "*"  # TODO(arte): sprite_dorso comun del nivel


func _texto_marcador() -> String:
	if id_pareja.length() <= 3:
		return id_pareja.to_upper()
	return id_pareja.substr(0, 3).to_upper()
