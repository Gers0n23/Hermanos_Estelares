extends Node2D
## Pantalla de seleccion de personaje (HE-06 en Backlog — implementada aqui como parte
## del paquete de UI ad-hoc del mockup del PO "UI Sistema").
##
## 3 tarjetas grandes (Maxi/Nicole/Sofia), cada una un objetivo tactil enorme (320x~400
## px, muy por encima del minimo de 96 px — GDD §6 regla 1). Al tocar una tarjeta se fija
## el perfil activo en `Progreso` (autoload real, HE-07) y se navega al mapa estelar. El
## boton "volver" hace lo opuesto: vuelve al titulo sin tocar el perfil.
##
## Entrada unificada tactil+mouse por region (mismo patron que `titulo.gd`, adaptado a
## multiples objetivos): en vez de "toda la pantalla es un boton", cada tarjeta/boton
## define su rectangulo y se resuelve cual se toco en `_unhandled_input`.

const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/seleccionar.ogg"
const RUTA_SFX_VOLVER := "res://assets/audio/sfx/ui/cerrar.ogg"
const RUTA_VOZ_INVITACION := "res://assets/audio/voces/nucleo/seleccion_invitacion_01.ogg"
const SEGUNDOS_ENTRE_RECORDATORIOS := 12.0
const RUTA_MAPA := "res://escenas/nucleo/mapa_estelar.tscn"
const RUTA_TITULO := "res://escenas/nucleo/titulo.tscn"

@onready var _temporizador_recordatorio: Timer = $temporizador_recordatorio
@onready var _boton_volver: Control = $boton_volver

## Cada region tactil: rectangulo en coordenadas de pantalla + accion a ejecutar.
var _regiones: Array[Dictionary] = []
var _bloqueado := false


func _ready() -> void:
	_registrar_regiones()
	_reproducir_invitacion()
	_temporizador_recordatorio.wait_time = SEGUNDOS_ENTRE_RECORDATORIOS
	_temporizador_recordatorio.timeout.connect(_reproducir_invitacion)
	_temporizador_recordatorio.start()


func _registrar_regiones() -> void:
	for id_perfil in ["maxi", "nicole", "sofia"]:
		var tarjeta: Control = get_node("tarjeta_%s" % id_perfil)
		_regiones.append({
			"rect": Rect2(tarjeta.global_position, tarjeta.size),
			"accion": func(): _elegir_perfil(id_perfil),
		})
	_regiones.append({
		"rect": Rect2(_boton_volver.global_position, _boton_volver.size),
		"accion": func(): _volver_a_titulo(),
	})


func _reproducir_invitacion() -> void:
	Audio.reproducir_voz(RUTA_VOZ_INVITACION)


func _unhandled_input(evento: InputEvent) -> void:
	if _bloqueado:
		return
	var posicion: Vector2
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		posicion = (evento as InputEventScreenTouch).position
	elif evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		posicion = (evento as InputEventMouseButton).position
	else:
		return
	for region in _regiones:
		if (region["rect"] as Rect2).has_point(posicion):
			(region["accion"] as Callable).call()
			return


func _elegir_perfil(id_perfil: String) -> void:
	_bloqueado = true
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	Progreso.seleccionar_perfil(id_perfil)
	get_tree().change_scene_to_file(RUTA_MAPA)


func _volver_a_titulo() -> void:
	_bloqueado = true
	Audio.reproducir_sfx(RUTA_SFX_VOLVER)
	get_tree().change_scene_to_file(RUTA_TITULO)
