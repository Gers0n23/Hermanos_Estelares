extends Node2D
## Anillo de progreso circular de la pantalla de carga (`carga.gd`).
##
## Dibuja por codigo el track tenue completo y el arco dorado que se va llenando segun
## `progreso` (0-100), reproduciendo el `conic-gradient` del mockup sin depender de
## texturas nuevas. `carga.gd` actualiza `progreso` en cada tick del tween de carga.

const RADIO_EXTERIOR := 250.0
const GROSOR_ARCO := 26.0
const RADIO_INTERIOR := 205.0
const COLOR_DORADO := Color("ffce3d")

var progreso: float = 0.0:
	set(valor):
		progreso = valor
		queue_redraw()


func _draw() -> void:
	# Disco interior donde flota Cometa.
	draw_circle(Vector2.ZERO, RADIO_INTERIOR, Color(0.169, 0.086, 0.376, 1.0))
	draw_arc(Vector2.ZERO, RADIO_INTERIOR, 0.0, TAU, 64, Color(1, 1, 1, 0.4), 3.0, true)

	# Track tenue completo (equivalente al "0" del conic-gradient).
	draw_arc(Vector2.ZERO, RADIO_EXTERIOR, 0.0, TAU, 96, Color(1, 1, 1, 0.078), GROSOR_ARCO, true)

	# Arco dorado de progreso, empieza arriba (-90°) y avanza en sentido horario.
	if progreso > 0.0:
		var angulo_inicio := -PI / 2.0
		var angulo_fin := angulo_inicio + TAU * (progreso / 100.0)
		draw_arc(Vector2.ZERO, RADIO_EXTERIOR, angulo_inicio, angulo_fin, 96, COLOR_DORADO, GROSOR_ARCO, true)
