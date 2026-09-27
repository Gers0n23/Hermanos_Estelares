extends Node2D
## Vista de prueba de los planetas dibujados del mapa estelar (planeta_dibujado.gd).

const IDS := ["tierra", "arcoiris", "animalia", "melodia", "cuenta_cuentas", "letralandia", "corazon"]


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("1b0f3a")
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	for i in IDS.size():
		var p := PlanetaDibujado.new()
		p.id_planeta = IDS[i]
		p.radio = 78.0
		p.position = Vector2(170 + (i % 4) * 310, 190 + (i / 4) * 340)
		p.apagado = i == 6 and false
		add_child(p)
	var gris := PlanetaDibujado.new()
	gris.id_planeta = "melodia"
	gris.radio = 60.0
	gris.apagado = true
	gris.position = Vector2(1100, 540)
	add_child(gris)
