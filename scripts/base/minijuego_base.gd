class_name MinijuegoBase
extends Node2D

## Contrato base para todo motor de mecanica (docs/stack-tecnico.md §2).
##
## Un motor concreto (p. ej. "emparejar") extiende este script, recibe la ruta de un
## archivo de nivel/contenido en JSON (perfil semilla|brote|estrella incluido en los
## datos, ver docs/fichas/*) y emite `completado(destellos)` al terminar con exito.
## El nucleo del juego nunca conoce mecanicas concretas: solo instancia la escena del
## motor con `ruta_nivel` seteado y escucha esta senal.
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

## Ruta res:// al JSON de nivel a cargar. Puede setearse desde el inspector (al
## instanciar el motor dentro de la escena de un planeta) o por codigo antes de
## que el nodo entre al arbol.
@export_file("*.json") var ruta_nivel: String = ""

## Contenido del nivel ya parseado (Dictionary). Vacio si la carga fallo.
var nivel: Dictionary = {}


func _ready() -> void:
	if ruta_nivel != "":
		cargar_nivel(ruta_nivel)


## Carga y parsea el JSON de nivel indicado. Devuelve el Dictionary resultante
## (vacio si hubo error). Los motores concretos pueden llamarla directamente para
## recargar contenido (p. ej. al reintentar con otro nivel).
func cargar_nivel(ruta: String) -> Dictionary:
	ruta_nivel = ruta
	nivel = {}
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


## Punto unico de salida exitosa del motor. Los motores concretos deben llamar esto
## en vez de emitir `completado` directamente, para dejar un lugar central donde
## enganchar telemetria/guardado a futuro sin tocar cada motor.
func emitir_completado(destellos: int) -> void:
	completado.emit(destellos)
