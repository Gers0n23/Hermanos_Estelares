class_name TobyCortar
extends Node2D

## Toby, el perrito bombero anfitrion de Animalia, PROVISIONAL por codigo (HE-114 trae el arte). Vive abajo a la
## izquierda, fuera de la zona de juego. Poses: saltar (revienta la burbuja de Maxi o ayuda), estornudar y el
## calcetin de sombrero sobre su casco (gag del calcetin, guino a la Torre). `position` = sus pies.

const CONTORNO := Color("#2B3350")

var sombrero_calcetin := false
var salto := 0.0
var estornudo := 0.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, -52 - salto + sin(_t * 2.5) * 2.0)
	# Colita que se mueve.
	draw_line(c + Vector2(26, 22), c + Vector2(44, 2 + sin(_t * 9.0) * 8.0), Color("#C98A4B"), 8.0, true)
	draw_circle(c + Vector2(0, 26), 30, CONTORNO)
	draw_circle(c + Vector2(0, 26), 27, Color("#E3B57A"))
	DibujoCortar.dibujar_animal(self, "perro", c + Vector2(0, -14), 30.0, estornudo > 0.5)
	# Casco de bombero.
	draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -26), c + Vector2(-20, -48), c + Vector2(20, -48), c + Vector2(30, -26)]), Color("#E23B2E"))
	draw_circle(c + Vector2(0, -38), 5, Color("#FFD23F"))
	if sombrero_calcetin:
		DibujoCortar.dibujar_calcetin(self, c + Vector2(4, -62), 26.0, -0.5)
	for s in [-1.0, 1.0]:
		draw_circle(c + Vector2(s * 14, 54), 9, Color("#E3B57A"))
