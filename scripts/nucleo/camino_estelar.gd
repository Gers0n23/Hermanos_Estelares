extends Node2D
## Camino curvo del mapa estelar: dibuja el trazo tenue completo y, encima, el tramo
## recorrido en dorado brillante (equivalente al `clip-path` del mockup sobre una copia
## dorada del mismo `<path>`). `mapa_estelar.gd` arma la curva con `fijar_curva()` y fija
## `proporcion` (0.0-1.0) segun cuantos planetas estan desbloqueados.

const COLOR_TENUE := Color(1, 1, 1, 0.1)
const COLOR_DORADO := Color("ffce3d")
const GROSOR := 13.0

var curva: Curve2D

var proporcion: float = 0.0:
	set(valor):
		proporcion = clampf(valor, 0.0, 1.0)
		queue_redraw()


func fijar_curva(nueva_curva: Curve2D) -> void:
	curva = nueva_curva
	queue_redraw()


func _draw() -> void:
	if curva == null:
		return
	var puntos_totales := curva.get_baked_points()
	if puntos_totales.size() > 1:
		draw_polyline(puntos_totales, COLOR_TENUE, GROSOR, true)
	if proporcion <= 0.0:
		return
	var largo := curva.get_baked_length() * proporcion
	var pasos: int = maxi(2, int(largo / 10.0))
	var puntos_dorados := PackedVector2Array()
	for i in range(pasos + 1):
		var t: float = largo * float(i) / float(pasos)
		puntos_dorados.append(curva.sample_baked(t))
	# Resplandor suave detras del trazo crujiente, como el drop-shadow dorado del mockup.
	draw_polyline(puntos_dorados, Color(COLOR_DORADO, 0.35), GROSOR + 10.0, true)
	draw_polyline(puntos_dorados, COLOR_DORADO, GROSOR, true)
