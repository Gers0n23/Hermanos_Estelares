extends Node2D
## Camino curvo del mapa estelar: dibuja el trazo tenue completo y, encima, el tramo
## recorrido en dorado brillante (equivalente al `clip-path` del mockup sobre una copia
## dorada del mismo `<path>`). `mapa_estelar.gd` arma la curva con `fijar_curva()` y fija
## `proporcion` (0.0-1.0) segun cuantos planetas estan desbloqueados.

const COLOR_TENUE := Color(1, 1, 1, 0.22)
const COLOR_DORADO := Color("ffce3d")
## Camino de "migas de estrella": puntos cada PASO px (dorados lo recorrido, tenues lo que falta).
const PASO := 24.0
const RADIO_PUNTO := 5.0

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
	var largo_total := curva.get_baked_length()
	var recorrido := largo_total * proporcion
	var d := PASO * 0.5
	while d < largo_total:
		var punto := curva.sample_baked(d)
		if d <= recorrido:
			draw_circle(punto, RADIO_PUNTO * 2.2, Color(COLOR_DORADO, 0.18))
			draw_circle(punto, RADIO_PUNTO * 1.2, COLOR_DORADO)
		else:
			draw_circle(punto, RADIO_PUNTO * 0.8, COLOR_TENUE)
		d += PASO
