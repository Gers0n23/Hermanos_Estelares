class_name CinematicaHistoria
extends Control
## Reproductor de escenas de historia tipo "motion comic" (docs/guiones/escena_intro.md, Narracion §4:
## "escenas de niños = stills con voz encima; el movimiento sale de la camara y del entorno").
##
## Todo sale de un JSON (`ruta_datos`, p. ej. datos/historia/intro.json): una lista de planos, cada uno
## una imagen con camara (paneo/zoom con Tween que sigue el largo REAL de cada voz), un video .ogv o una
## subescena animada ("escena": .tscn cuya raiz tiene `reproducir(cine)`, p. ej. la transformacion de los
## trajes) que usa la voz y los toques de este reproductor via `ejecutar()`, `esperar()` y `termino()`.
## Asi la misma escena sirve para la intro, la llegada a Arcoiris y las videollamadas, y cambiar el
## ritmo o una imagen es editar datos, no codigo.
##
## Reglas de UX (GDD §6): un toque adelanta a la linea siguiente (nunca se queda "pegada"); la primera
## vez no hay boton de saltar (es la historia), las siguientes aparece uno grande arriba a la derecha.
## Si una voz aun no existe, se muestra su texto como subtitulo PROVISIONAL y se espera lo que tardaria
## en decirse: la escena es jugable y revisable antes de tener todas las voces.

@export_file("*.json") var ruta_datos := "res://datos/historia/intro.json"

const CARPETA_NARRACION := "res://assets/audio/voces/historia/narracion/"
const CARPETA_LINEAS := "res://assets/audio/voces/historia/intro/"
const PANTALLA := Vector2(1280, 720)
const MARCO_LLAMADA := Rect2(150, 70, 980, 551)
const SEGUNDOS_MIN_POR_PASO := 0.6
const LETRAS_POR_SEGUNDO := 14.0

var _datos: Dictionary = {}
var _cam := Vector3(0.5, 0.5, 1.0)  # x, y (0-1 sobre la imagen) y zoom (1 = cubre el visor)
var _tween_cam: Tween
var _saltar_paso := false
var _terminar := false
var _inicio_paso := 0.0

var _visor: Control
var _lienzo: Sprite2D
var _borde_llamada: Panel
var _video: VideoStreamPlayer
var _velo: ColorRect
var _subtitulo: Label
var _boton_saltar: Button
var _subescena: Node


func _ready() -> void:
	_construir_nodos()
	var texto := FileAccess.get_file_as_string(ruta_datos)
	var parseado: Variant = JSON.parse_string(texto)
	if not parseado is Dictionary:
		push_error("CinematicaHistoria: no pude leer %s" % ruta_datos)
		_ir_a_siguiente()
		return
	_datos = parseado
	_boton_saltar.visible = Progreso.cinematica_vista(str(_datos.get("id_vista", "")))
	var musica := str(_datos.get("musica", ""))
	if musica != "" and ResourceLoader.exists(musica):
		Audio.reproducir_musica(musica)
	_reproducir.call_deferred()


func _construir_nodos() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color("1b1033")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	_visor = Control.new()
	_visor.clip_contents = true
	_visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visor)
	_lienzo = Sprite2D.new()
	_lienzo.centered = false
	_visor.add_child(_lienzo)

	_borde_llamada = Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.border_color = Color("ffd45c")
	estilo.set_border_width_all(12)
	estilo.set_corner_radius_all(10)
	estilo.shadow_color = Color(1.0, 0.83, 0.36, 0.45)
	estilo.shadow_size = 24
	_borde_llamada.add_theme_stylebox_override("panel", estilo)
	_borde_llamada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_borde_llamada.visible = false
	add_child(_borde_llamada)

	_video = VideoStreamPlayer.new()
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.visible = false
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_video)

	_subtitulo = Label.new()
	_subtitulo.position = Vector2(140, 600)
	_subtitulo.size = Vector2(1000, 100)
	_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitulo.add_theme_font_size_override("font_size", 26)
	_subtitulo.add_theme_color_override("font_color", Color.WHITE)
	_subtitulo.add_theme_color_override("font_outline_color", Color("1b1033"))
	_subtitulo.add_theme_constant_override("outline_size", 10)
	_subtitulo.visible = false
	_subtitulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitulo)

	_velo = ColorRect.new()
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.color = Color(0, 0, 0, 1)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_velo)

	# Saltar: solo cuando la familia ya vio esta escena (la primera vez es la historia).
	_boton_saltar = Button.new()
	_boton_saltar.text = "⏭"
	_boton_saltar.add_theme_font_size_override("font_size", 52)
	_boton_saltar.position = Vector2(1150, 20)
	_boton_saltar.size = Vector2(110, 110)
	_boton_saltar.focus_mode = Control.FOCUS_NONE
	_boton_saltar.pressed.connect(func() -> void:
		_terminar = true
		_saltar_paso = true
		Audio.detener_voz())
	add_child(_boton_saltar)


# --- Secuencia ---

func _reproducir() -> void:
	for plano: Dictionary in _datos.get("planos", []):
		if _terminar:
			break
		await _reproducir_plano(plano)
	_finalizar()


func _reproducir_plano(plano: Dictionary) -> void:
	var entrada := str(plano.get("entrada", "fundido"))
	await _cubrir(entrada)
	_liberar_subescena()
	if plano.has("escena"):
		await _reproducir_subescena(plano)
		return
	if plano.has("video"):
		await _reproducir_video(plano)
		return
	var ruta := str(plano.get("imagen", ""))
	if not ResourceLoader.exists(ruta):
		push_warning("CinematicaHistoria: falta la imagen %s; salto el plano" % ruta)
		return
	_video.visible = false
	_video.stop()
	_video.paused = false
	_poner_marco(str(plano.get("marco", "")))
	_lienzo.texture = load(ruta)
	_lienzo.position = Vector2.ZERO
	_detener_camara()
	_aplicar_camara(_vec3(plano.get("camara", [0.5, 0.5, 1.0])))
	await _descubrir(entrada)
	for paso: Dictionary in plano.get("pasos", []):
		if _terminar:
			return
		await _ejecutar_paso(paso)


func _reproducir_video(plano: Dictionary) -> void:
	var ruta := str(plano["video"])
	if not ResourceLoader.exists(ruta):
		push_warning("CinematicaHistoria: falta el video %s; salto el plano" % ruta)
		await _descubrir("corte")
		return
	_poner_marco("")
	_video.stop()
	_video.paused = false  # el video anterior quedo en pausa en su ultimo cuadro
	_video.stream = load(ruta)
	_video.visible = true
	_video.play()
	await _descubrir(str(plano.get("entrada", "fundido")))
	_saltar_paso = false
	for paso: Dictionary in plano.get("pasos", []):
		if _terminar or not _video.is_playing():
			break
		await _ejecutar_paso(paso)
	_saltar_paso = false
	while _video.is_playing() and not _saltar_paso and not _terminar:
		await get_tree().process_frame
	_saltar_paso = false
	# El ultimo cuadro del video se queda en pantalla hasta que el plano siguiente lo cubra.
	_video.paused = true


func _reproducir_subescena(plano: Dictionary) -> void:
	var ruta := str(plano["escena"])
	if not ResourceLoader.exists(ruta):
		push_warning("CinematicaHistoria: falta la escena %s; salto el plano" % ruta)
		return
	_video.visible = false
	_video.stop()
	_video.paused = false
	_poner_marco("")
	_subescena = (load(ruta) as PackedScene).instantiate()
	add_child(_subescena)
	move_child(_subescena, _video.get_index() + 1)  # bajo el subtitulo, el velo y el boton de saltar
	await _descubrir(str(plano.get("entrada", "fundido")))
	if _subescena.has_method("reproducir"):
		await _subescena.reproducir(self)
	# Queda en pantalla hasta que el plano siguiente la cubra (y ahi se libera).


func _liberar_subescena() -> void:
	if is_instance_valid(_subescena):
		_subescena.queue_free()
	_subescena = null


# --- API para subescenas: misma voz, subtitulo provisional y toque-para-avanzar que los planos ---

func ejecutar(datos: Dictionary) -> void:
	await _ejecutar_paso(datos)


func esperar(segundos: float) -> void:
	_saltar_paso = false
	_inicio_paso = _ahora()
	await _esperar(segundos)


func termino() -> bool:
	return _terminar


func _ejecutar_paso(paso: Dictionary) -> void:
	_saltar_paso = false
	_inicio_paso = _ahora()
	if paso.has("sfx") and ResourceLoader.exists(str(paso["sfx"])):
		Audio.reproducir_sfx(str(paso["sfx"]))
	if paso.has("foco"):
		_mover_camara(_vec3(paso["foco"]), float(paso.get("duracion_foco", 1.1)))
	match str(paso.get("efecto", "")):
		"destello":
			await _destello(str(paso.get("imagen", "")))
		"temblor":
			_temblor()
		"saltito":
			_saltito()
		"hablar":
			_hablar()
	if paso.has("voz"):
		await _decir(paso)
	if paso.has("pausa"):
		await _esperar(float(paso["pausa"]))


## Dice una linea; si su audio no existe aun, muestra el texto como subtitulo provisional.
func _decir(paso: Dictionary) -> void:
	var ruta := _ruta_voz(str(paso["voz"]))
	var texto := str(paso.get("texto", ""))
	if ruta != "":
		Audio.reproducir_voz(ruta)
		await get_tree().process_frame
		while Audio.esta_hablando() and not _saltar_paso and not _terminar:
			await get_tree().process_frame
		if _saltar_paso:
			Audio.detener_voz()
		await _esperar(0.25)
		return
	_subtitulo.text = "%s: «%s»" % [str(paso.get("quien", "")), texto]
	_subtitulo.visible = true
	await _esperar(maxf(1.6, texto.length() / LETRAS_POR_SEGUNDO))
	_subtitulo.visible = false


func _ruta_voz(id: String) -> String:
	var carpeta := CARPETA_NARRACION if id.begins_with("narr_") else CARPETA_LINEAS
	for extension in [".ogg", ".wav"]:
		if ResourceLoader.exists(carpeta + id + extension):
			return carpeta + id + extension
	push_warning("CinematicaHistoria: linea pendiente de grabar: %s" % id)
	return ""


func _esperar(segundos: float) -> void:
	var fin := _ahora() + segundos
	while _ahora() < fin and not _saltar_paso and not _terminar:
		await get_tree().process_frame


func _finalizar() -> void:
	Progreso.marcar_cinematica_vista(str(_datos.get("id_vista", "")))
	Audio.detener_voz()
	_ir_a_siguiente()


func _ir_a_siguiente() -> void:
	var siguiente := str(_datos.get("siguiente", "res://escenas/nucleo/seleccion_personaje.tscn"))
	get_tree().change_scene_to_file.call_deferred(siguiente)


# --- Entrada del niño: un toque adelanta a la linea siguiente ---

func _input(evento: InputEvent) -> void:
	var toque := (evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed) \
		or (evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
		and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not toque:
		return
	if _boton_saltar.visible and _boton_saltar.get_global_rect().has_point(_posicion(evento)):
		return  # lo atiende el boton
	if _ahora() - _inicio_paso < SEGUNDOS_MIN_POR_PASO:
		return  # tocar muy seguido no se "come" la historia
	_saltar_paso = true


func _posicion(evento: InputEvent) -> Vector2:
	if evento is InputEventScreenTouch:
		return (evento as InputEventScreenTouch).position
	return (evento as InputEventMouseButton).position


# --- Camara (paneo y zoom sobre la imagen) ---

func _poner_marco(marco: String) -> void:
	var rect := MARCO_LLAMADA if marco == "llamada" else Rect2(Vector2.ZERO, PANTALLA)
	_visor.position = rect.position
	_visor.size = rect.size
	_visor.pivot_offset = rect.size / 2.0
	_visor.scale = Vector2.ONE
	_borde_llamada.visible = marco == "llamada"
	_borde_llamada.position = rect.position - Vector2(12, 12)
	_borde_llamada.size = rect.size + Vector2(24, 24)


func _mover_camara(destino: Vector3, segundos: float) -> void:
	_detener_camara()
	_tween_cam = create_tween()
	_tween_cam.tween_method(_aplicar_camara, _cam, destino, maxf(segundos, 0.01)) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _detener_camara() -> void:
	if _tween_cam != null and _tween_cam.is_valid():
		_tween_cam.kill()


func _aplicar_camara(cam: Vector3) -> void:
	_cam = cam
	if _lienzo.texture == null:
		return
	var tam_img := _lienzo.texture.get_size()
	var tam_visor := _visor.size
	var escala := maxf(tam_visor.x / tam_img.x, tam_visor.y / tam_img.y) * maxf(cam.z, 1.0)
	var medio := tam_visor / (2.0 * escala)  # media pantalla, en pixeles de la imagen
	var centro := Vector2(clampf(cam.x * tam_img.x, medio.x, tam_img.x - medio.x),
		clampf(cam.y * tam_img.y, medio.y, tam_img.y - medio.y))
	_lienzo.scale = Vector2(escala, escala)
	_lienzo.position = tam_visor / 2.0 - centro * escala


# --- Transiciones y efectos ---

func _cubrir(entrada: String) -> void:
	match entrada:
		"fundido":
			_velo.color = Color(0, 0, 0, _velo.color.a)
			await _tween_velo(1.0, 0.35)
		"destello":
			_velo.color = Color(1.0, 0.95, 0.8, _velo.color.a)
			await _tween_velo(1.0, 0.18)


func _descubrir(entrada: String) -> void:
	if entrada == "corte":
		_velo.color.a = 0.0
		return
	await _tween_velo(0.0, 0.45)


func _tween_velo(alfa: float, segundos: float) -> void:
	if is_equal_approx(_velo.color.a, alfa):
		return
	var tween := create_tween()
	tween.tween_property(_velo, "color:a", alfa, segundos)
	await tween.finished


## Destello calido; si el paso trae otra imagen, se cambia debajo del destello (p. ej. ropa de casa → traje).
func _destello(imagen: String) -> void:
	_velo.color = Color(1.0, 0.95, 0.8, 0.0)
	await _tween_velo(0.95, 0.2)
	if imagen != "" and ResourceLoader.exists(imagen):
		_lienzo.texture = load(imagen)
		_aplicar_camara(_cam)
	await _tween_velo(0.0, 0.55)


func _temblor() -> void:
	var tween := create_tween()
	for i in 6:
		var desvio := Vector2(randf_range(-9, 9), randf_range(-6, 6))
		tween.tween_property(_visor, "position", _visor.position + desvio, 0.05)
	tween.tween_property(_visor, "position", _visor.position, 0.06)


func _saltito() -> void:
	var tween := create_tween()
	tween.tween_property(_visor, "position:y", _visor.position.y - 14.0, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visor, "position:y", _visor.position.y, 0.32) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Videollamada: la ventana "late" suave mientras papá habla.
func _hablar() -> void:
	var tween := create_tween()
	tween.tween_property(_visor, "scale", Vector2(1.025, 1.025), 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_visor, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)


# --- Utilidades ---

func _ahora() -> float:
	return Time.get_ticks_msec() / 1000.0


func _vec3(valor: Variant) -> Vector3:
	var arr: Array = valor if valor is Array else [0.5, 0.5, 1.0]
	return Vector3(float(arr[0]), float(arr[1]), float(arr[2]) if arr.size() > 2 else 1.0)
