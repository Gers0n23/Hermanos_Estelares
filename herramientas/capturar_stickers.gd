extends SceneTree

## Hoja de contacto del catalogo de stickers del lienzo con tema (scripts/motores/lienzo_libre/
## stickers.gd): rasteriza cada sticker en CPU, igual que al guardar el PNG del dibujo, y arma una
## grilla con su color por defecto y una variante girada y espejada. Funciona headless.
##
## Uso: godot --headless --path . --script herramientas/capturar_stickers.gd -- <salida.png>

const Stickers := preload("res://scripts/motores/lienzo_libre/stickers.gd")
const Raster := preload("res://scripts/motores/lienzo_libre/rasterizador.gd")
const LADO := 120
const COLUMNAS := 10


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var salida := args[0] if args.size() > 0 else "user://stickers.png"
	var ids: Array = Stickers.CATALOGO.keys()
	var filas := ceili(ids.size() * 2.0 / COLUMNAS)
	var hoja := Image.create(COLUMNAS * LADO, filas * LADO, false, Image.FORMAT_RGBA8)
	hoja.fill(Color("#FFF8EE"))
	var t0 := Time.get_ticks_msec()
	for i in ids.size():
		var id: String = ids[i]
		for variante in 2:
			var k := i * 2 + variante
			var centro := Vector2((k % COLUMNAS + 0.5) * LADO, (k / COLUMNAS + 0.5) * LADO)
			var color := Stickers.color_por_defecto(id) if variante == 0 else Color("#FF7EB6")
			var imagen := Stickers.imagen(id, color, LADO - 8, 0.0 if variante == 0 else 0.5, variante == 1)
			Raster.estampar(hoja, imagen, centro)
	print("stickers: %d en %d ms" % [ids.size(), Time.get_ticks_msec() - t0])
	hoja.save_png(salida)
	print("hoja: ", salida)
	quit(0)
