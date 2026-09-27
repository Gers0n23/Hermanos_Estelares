extends "res://scripts/ui/figura_vectorial.gd"

## Icono de la barra de pares (y la figura que vuela hacia ella) del motor "emparejar".
## Igual que `figura_vectorial.gd`, pero ademas sabe dibujar los temas de los hermanos y las
## banderas de `dibujos_emparejar.gd`, sin tocar el script compartido de la UI.

const Dibujos := preload("res://scripts/motores/emparejar/dibujos_emparejar.gd")


func _draw() -> void:
	if not Dibujos.tiene(figura):
		super._draw()
		return
	var centro := size / 2.0
	var radio := minf(size.x, size.y) * 0.5
	if con_disco:
		draw_circle(centro, radio * 0.94, COLOR_DISCO)
		draw_arc(centro, radio * 0.94, 0.0, TAU, 40, COLOR_CONTORNO, maxf(2.5, radio * 0.08), true)
		radio *= 0.66
	Dibujos.dibujar(self, figura, color, centro, radio * 0.95, con_cara, alegre)
