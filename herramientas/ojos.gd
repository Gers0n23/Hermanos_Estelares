extends SceneTree

## "Ojos" de Claude: arma una HOJA DE CONTACTO (PNG rotulado) para que el agente
## vea su propio trabajo y lo corrija solo, en vez de verificar a ciegas.
##
## Corre CON GPU (no --headless): el render headless no dibuja nada.
##
## Modo escena — corre una escena real, simula toques/arrastres y captura fotogramas:
##   godot --path . --script herramientas/ojos.gd -- escena=res://escenas/nucleo/titulo.tscn \
##       tiempos=0.5,1.5,3 [perfil=maxi] [toques=640,360@1.0;200,300@2.2] \
##       [arrastres=300,400>900,400@1.0] [recorte=x,y,ancho,alto] [columnas=3] [salida=.ojos/titulo.png]
##
## Modo svg — renderiza SVG (y opcionalmente la referencia) lado a lado para comparar:
##   godot --path . --script herramientas/ojos.gd -- \
##       svg=assets/fuentes_svg/personajes/maxi_base.svg,otro.svg \
##       [ref=assets/anclas/maxi_referencia.png] [alto=520] [salida=.ojos/maxi.png]
##
## Rutas relativas se resuelven contra la raíz del proyecto. La salida por defecto
## queda en .ojos/ (con .gdignore para que Godot no la importe; ignorada por git).
## Cada fotograma de la hoja lleva su rótulo (tiempo o archivo) y un aro rosado
## donde se simuló un toque, para que la revisión sepa qué se tocó y cuándo.

const ANCHO_CELDA := 640
const FONDO_HOJA := Color("#1b1433")
const COLOR_ROTULO := Color("#ffce3d")
const COLOR_TOQUE := Color("#ff5fae")
const DURACION_ARRASTRE := 0.45

var _args: Dictionary = {}


func _initialize() -> void:
	_args = _leer_args()
	var salida := _ruta_salida()
	var cuadros: Array = []  # [{imagen: Image, rotulo: String, toques: Array[Vector2]}]
	if _args.has("svg"):
		cuadros = _cuadros_svg()
	elif _args.has("escena"):
		cuadros = await _cuadros_escena()
	else:
		printerr("ojos: falta escena=... o svg=... (ver cabecera del script)")
		quit(1)
		return
	if cuadros.is_empty():
		printerr("ojos: no se obtuvo ningún cuadro")
		quit(1)
		return
	var hoja: Image = await _armar_hoja(cuadros)
	hoja.save_png(salida)
	print("ojos: hoja de contacto -> %s (%d cuadros)" % [salida, cuadros.size()])
	quit(0)


# --- argumentos ------------------------------------------------------------

func _leer_args() -> Dictionary:
	var resultado := {}
	for arg in OS.get_cmdline_user_args():
		var partes: PackedStringArray = arg.split("=", true, 1)
		resultado[partes[0]] = partes[1] if partes.size() > 1 else ""
	return resultado


func _absoluta(ruta: String) -> String:
	if ruta.begins_with("res://") or ruta.begins_with("user://"):
		return ProjectSettings.globalize_path(ruta)
	if ruta.is_absolute_path():
		return ruta
	return ProjectSettings.globalize_path("res://").path_join(ruta)


func _ruta_salida() -> String:
	var carpeta_ojos := ProjectSettings.globalize_path("res://.ojos")
	DirAccess.make_dir_recursive_absolute(carpeta_ojos)
	if not FileAccess.file_exists(carpeta_ojos.path_join(".gdignore")):
		FileAccess.open(carpeta_ojos.path_join(".gdignore"), FileAccess.WRITE).store_string("")
	if _args.has("salida"):
		var ruta := _absoluta(_args["salida"])
		DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
		return ruta
	var base: String = _args.get("escena", _args.get("svg", "hoja")).get_file().get_basename()
	return carpeta_ojos.path_join("%s.png" % base.split(",")[0])


# --- modo escena -------------------------------------------------------------

func _cuadros_escena() -> Array:
	if _args.has("perfil"):
		var progreso: Node = get_root().get_node_or_null("Progreso")
		if progreso:
			progreso.perfil_seleccionado = _args["perfil"]

	var escena: PackedScene = load(_args["escena"])
	if escena == null:
		printerr("ojos: no se pudo cargar %s" % _args["escena"])
		return []
	# Se registra como current_scene para que change_scene_to_* funcione igual que en el juego.
	var instancia := escena.instantiate()
	get_root().add_child(instancia)
	current_scene = instancia

	var tiempos: Array[float] = []
	for t in _args.get("tiempos", "0.5,1.5,3").split(","):
		tiempos.append(float(t))
	tiempos.sort()

	# Eventos de entrada programados: {t, tipo, desde, hasta}
	var eventos: Array = []
	for toque in _args.get("toques", "").split(";", false):
		var p := _parsear_evento(toque)
		eventos.append({"t": p[1], "tipo": "toque", "desde": p[0], "hasta": p[0]})
	for arrastre in _args.get("arrastres", "").split(";", false):
		var puntos: PackedStringArray = arrastre.split("@")[0].split(">")
		var t := float(arrastre.split("@")[1])
		eventos.append({"t": t, "tipo": "arrastre", "desde": _punto(puntos[0]), "hasta": _punto(puntos[1])})

	var cuadros: Array = []
	var t0 := Time.get_ticks_msec()
	var indice_tiempo := 0
	while indice_tiempo < tiempos.size():
		var ahora := (Time.get_ticks_msec() - t0) / 1000.0
		for evento in eventos:
			if not evento.get("hecho", false) and ahora >= evento["t"]:
				evento["hecho"] = true
				_ejecutar_evento(evento)
		if ahora >= tiempos[indice_tiempo]:
			await RenderingServer.frame_post_draw
			var marcas: Array = []
			for evento in eventos:
				# Se marca el toque en los cuadros tomados hasta 0,8 s después.
				if evento.get("hecho", false) and ahora - evento["t"] <= 0.8:
					marcas.append(evento["hasta"])
			var foto := get_root().get_texture().get_image()
			if _args.has("recorte"):
				# Zoom a una zona (x,y,ancho,alto en coords de pantalla) para revisar uniones/detalles.
				var r: PackedStringArray = _args["recorte"].split(",")
				var zona := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
				foto = foto.get_region(zona)
				marcas = marcas.map(func(m: Vector2) -> Vector2: return m - Vector2(zona.position))
			cuadros.append({
				"imagen": foto,
				"rotulo": "%.1f s" % tiempos[indice_tiempo],
				"toques": marcas,
			})
			indice_tiempo += 1
		await process_frame
	return cuadros


func _punto(texto: String) -> Vector2:
	var xy: PackedStringArray = texto.split(",")
	return Vector2(float(xy[0]), float(xy[1]))


func _parsear_evento(texto: String) -> Array:
	var partes: PackedStringArray = texto.split("@")
	return [_punto(partes[0]), float(partes[1])]


func _ejecutar_evento(evento: Dictionary) -> void:
	# Mouse con emulate_touch_from_mouse=true cubre tanto _gui_input como toques.
	_evento_mouse(evento["desde"], true)
	if evento["tipo"] == "arrastre":
		var pasos := 12
		for i in range(1, pasos + 1):
			await create_timer(DURACION_ARRASTRE / pasos).timeout
			var movimiento := InputEventMouseMotion.new()
			movimiento.position = evento["desde"].lerp(evento["hasta"], float(i) / pasos)
			movimiento.global_position = movimiento.position
			movimiento.button_mask = MOUSE_BUTTON_MASK_LEFT
			get_root().push_input(movimiento)
	else:
		await create_timer(0.08).timeout
	_evento_mouse(evento["hasta"], false)


func _evento_mouse(posicion: Vector2, presionado: bool) -> void:
	var boton := InputEventMouseButton.new()
	boton.button_index = MOUSE_BUTTON_LEFT
	boton.pressed = presionado
	boton.position = posicion
	boton.global_position = posicion
	get_root().push_input(boton)


# --- modo svg ----------------------------------------------------------------

func _cuadros_svg() -> Array:
	var alto := int(_args.get("alto", "520"))
	var cuadros: Array = []
	if _args.has("ref"):
		var referencia := _cargar_imagen(_absoluta(_args["ref"]))
		if referencia:
			cuadros.append({"imagen": _con_fondo(referencia), "rotulo": "REFERENCIA", "toques": []})
	for ruta in _args["svg"].split(","):
		var texto := FileAccess.get_file_as_string(_absoluta(ruta))
		if texto.is_empty():
			printerr("ojos: no se pudo leer %s" % ruta)
			continue
		var imagen := Image.new()
		# Primero se mide a escala 1 y luego se re-rasteriza a la altura pedida:
		# así el SVG se ve nítido, como en el pipeline real (exportar_sprites.gd).
		imagen.load_svg_from_string(texto, 1.0)
		var escala := float(alto) / maxi(imagen.get_height(), 1)
		imagen.load_svg_from_string(texto, escala)
		cuadros.append({"imagen": _con_fondo(imagen), "rotulo": ruta.get_file(), "toques": []})
	return cuadros


func _cargar_imagen(ruta: String) -> Image:
	# Varias anclas generadas son JPEG/WebP con extensión .png: se decide por el contenido.
	var bytes := FileAccess.get_file_as_bytes(ruta)
	var imagen := Image.new()
	var error := ERR_FILE_UNRECOGNIZED
	if bytes.size() > 12 and bytes[0] == 0x89 and bytes[1] == 0x50:
		error = imagen.load_png_from_buffer(bytes)
	elif bytes.size() > 12 and bytes[0] == 0xFF and bytes[1] == 0xD8:
		error = imagen.load_jpg_from_buffer(bytes)
	elif bytes.size() > 12 and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		error = imagen.load_webp_from_buffer(bytes)
	if error == OK:
		return imagen
	printerr("ojos: formato no reconocido en %s" % ruta)
	return null


func _con_fondo(imagen: Image) -> Image:
	# Gris neutro como las hojas de referencia: la transparencia no se confunde con blanco.
	var fondo := Image.create(imagen.get_width(), imagen.get_height(), false, Image.FORMAT_RGBA8)
	fondo.fill(Color("#d9d9dc"))
	imagen.convert(Image.FORMAT_RGBA8)
	fondo.blend_rect(imagen, Rect2i(Vector2i.ZERO, imagen.get_size()), Vector2i.ZERO)
	return fondo


# --- hoja de contacto --------------------------------------------------------

func _armar_hoja(cuadros: Array) -> Image:
	var columnas := int(_args.get("columnas", str(mini(cuadros.size(), 3))))
	var filas := ceili(float(cuadros.size()) / columnas)
	var alto_rotulo := 34
	var alto_celda := 0
	for cuadro in cuadros:
		var img: Image = cuadro["imagen"]
		alto_celda = maxi(alto_celda, int(img.get_height() * float(ANCHO_CELDA) / img.get_width()))
	var margen := 10

	var lienzo := SubViewport.new()
	lienzo.size = Vector2i(
		columnas * (ANCHO_CELDA + margen) + margen,
		filas * (alto_celda + alto_rotulo + margen) + margen)
	lienzo.transparent_bg = false
	lienzo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(lienzo)

	var fondo := ColorRect.new()
	fondo.color = FONDO_HOJA
	fondo.size = lienzo.size
	lienzo.add_child(fondo)

	for i in cuadros.size():
		var cuadro: Dictionary = cuadros[i]
		var img: Image = cuadro["imagen"]
		var escala := float(ANCHO_CELDA) / img.get_width()
		var origen := Vector2(
			margen + (i % columnas) * (ANCHO_CELDA + margen),
			margen + (i / columnas) * (alto_celda + alto_rotulo + margen))

		var rotulo := Label.new()
		rotulo.text = "%d · %s" % [i + 1, cuadro["rotulo"]]
		rotulo.position = origen
		rotulo.add_theme_color_override("font_color", COLOR_ROTULO)
		rotulo.add_theme_font_size_override("font_size", 22)
		lienzo.add_child(rotulo)

		var foto := TextureRect.new()
		foto.texture = ImageTexture.create_from_image(img)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		foto.position = origen + Vector2(0, alto_rotulo)
		foto.size = Vector2(ANCHO_CELDA, img.get_height() * escala)
		lienzo.add_child(foto)

		for toque in cuadro["toques"]:
			var aro := _Aro.new()
			aro.position = foto.position + toque * escala
			lienzo.add_child(aro)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var hoja := lienzo.get_texture().get_image()
	lienzo.queue_free()
	return hoja


class _Aro extends Node2D:
	func _draw() -> void:
		draw_arc(Vector2.ZERO, 22, 0, TAU, 32, COLOR_TOQUE, 5)
		draw_circle(Vector2.ZERO, 5, COLOR_TOQUE)
