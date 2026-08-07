extends Node2D
## Anillo decorativo "a rayas" dibujado por codigo (sin textura nueva), usado detras del
## marco de portada del titulo y como adorno general. Reemplaza el
## `repeating-conic-gradient` con mascara circular del mockup con arcos punteados.

@export var radio := 300.0
@export var segmentos := 26
@export var color := Color(1, 1, 1, 0.08)
@export var grosor := 16.0


func _draw() -> void:
	var paso := TAU / float(segmentos)
	for i in segmentos:
		if i % 2 == 0:
			var angulo_inicio := i * paso
			var angulo_fin := angulo_inicio + paso * 0.6
			draw_arc(Vector2.ZERO, radio, angulo_inicio, angulo_fin, 6, color, grosor, true)
