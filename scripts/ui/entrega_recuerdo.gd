class_name EntregaRecuerdo
extends CanvasLayer

## Entrega de un recuerdo con el SOBRE-ESTRELLA (docs/fichas/album-recuerdos.md §6, HE-47).
## Escena reutilizable: la montan la seleccion de personaje (primera apertura), el mapa de un
## planeta (zona completa) y el viaje estelar (burbuja-recuerdo). No conoce a ninguno: recibe la
## lista de recuerdos que devolvio `Recuerdos.desbloquear(...)` y emite `terminada`.
##
## Game feel (ficha §6):
## 1. Todo se detiene suavemente (velo) y Cometa avisa (linea del guion, si ya esta grabada).
## 2. El sobre-estrella baja girando al centro, grande (>200 px).
## 3. Un toque en CUALQUIER parte lo abre; si en 3 s nadie toca, se abre solo (Maxi).
## 4. La polaroid crece hasta ~70% de la pantalla, suena la voz de la familia y cae confeti.
## 5. La foto vuela al icono del album, que rebota (asi se aprende donde queda).
## 6. Sin boton de continuar: al terminar el audio (o con un toque) se vuelve al juego.
## Cada toque responde al instante con sonido y rebote (GDD §6 regla 5). Mientras dura, bloquea
## los toques a la pantalla de abajo.

signal terminada

const FotoRecuerdo := preload("res://scripts/ui/foto_recuerdo.gd")
const BotonAlbum := preload("res://scripts/ui/boton_album.gd")
const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const ESCENA := "res://escenas/ui/entrega_recuerdo.tscn"
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SFX_ABRIR := "res://assets/audio/sfx/ui/abrir.ogg"
const SFX_FIESTA := "res://assets/audio/sfx/ui/confirmar.ogg"
const SFX_GUARDAR := "res://assets/audio/sfx/ui/soltar.ogg"
const PANTALLA := Vector2(1280, 720)
const TAM_SOBRE := Vector2(260, 190)
const ALTO_FOTO := 504.0            # ~70% de 720
const BAJADA := 0.9
const AUTO_ABRIR := 3.0
const MIN_FOTO := 2.5               # la foto se queda al menos esto (sin audio de la familia)
const MAX_FOTO := 14.0
const TOQUE_FOTO_DESDE := 0.7       # un toque que venia de antes no se salta la foto
const VUELO := 0.65

## Donde esta el icono del album en la pantalla que monta la entrega; si es negativo, la entrega
## dibuja su propio icono arriba a la derecha.
var destino_album := Vector2(-1, -1)
## Linea de Cometa al aparecer el sobre y al guardar la foto (primera apertura: guion §1.1).
var voz_sobre := ""
var voz_final := ""

var _cola: Array = []
var _actual: Dictionary = {}
var _estado := ""
var _t := 0.0
var _tocado := false
var _fondo: Control
var _velo: ColorRect
var _sobre: Control
var _foto: Control
var _icono: Control
var _confeti: CPUParticles2D
var _icono_propio := false
var _tiempo := 0.0


## Crea la entrega lista para agregar al arbol.
static func crear(recuerdos_nuevos: Array, destino := Vector2(-1, -1)) -> EntregaRecuerdo:
	var entrega: EntregaRecuerdo = (load(ESCENA) as PackedScene).instantiate()
	entrega._cola = recuerdos_nuevos.duplicate()
	entrega.destino_album = destino
	return entrega


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	if _cola.is_empty():
		_terminar()
		return
	_siguiente()


func esta_activa() -> bool:
	return _estado != "" and _estado != "fin"


func estado() -> String:
	return _estado


## Equivale a un toque en cualquier parte (lo usan los tests headless).
func avanzar() -> void:
	_al_tocar()


func _construir() -> void:
	_fondo = Control.new()
	_fondo.name = "fondo"
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.position = Vector2.ZERO
	_fondo.size = PANTALLA
	_fondo.gui_input.connect(_al_input)
	_velo = ColorRect.new()
	_velo.color = Color(0.1, 0.05, 0.25, 0.0)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo.add_child(_velo)
	_velo.size = PANTALLA
	_icono_propio = destino_album.x < 0.0
	if _icono_propio:
		destino_album = Vector2(1170, 96)
		_icono = BotonAlbum.new()
		_icono.interactivo = false
		_icono.size = Vector2(150, 150)
		_icono.position = destino_album - _icono.size / 2.0
		_icono.modulate.a = 0.0
		_fondo.add_child(_icono)
	_sobre = Control.new()
	_sobre.name = "sobre"
	_sobre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sobre.size = TAM_SOBRE
	_sobre.pivot_offset = TAM_SOBRE / 2.0
	_sobre.draw.connect(_dibujar_sobre)
	_fondo.add_child(_sobre)
	_sobre.hide()


func _siguiente() -> void:
	_actual = _cola.pop_front()
	_cambiar("entrando")
	_velo.create_tween().tween_property(_velo, "color:a", 0.6, 0.35)
	if _icono_propio:
		_icono.create_tween().tween_property(_icono, "modulate:a", 1.0, 0.35)
	_sobre.show()
	_sobre.modulate.a = 1.0
	_sobre.scale = Vector2.ONE
	_sobre.position = Vector2(PANTALLA.x / 2.0 - TAM_SOBRE.x / 2.0, -TAM_SOBRE.y - 40.0)
	_sobre.rotation = -TAU
	var tween := _sobre.create_tween().set_parallel(true)
	tween.tween_property(_sobre, "position:y", PANTALLA.y / 2.0 - TAM_SOBRE.y / 2.0 - 20.0, BAJADA).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sobre, "rotation", 0.0, BAJADA).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_decir(_linea_sobre())


func _linea_sobre() -> String:
	if voz_sobre != "":
		var ruta := voz_sobre
		voz_sobre = ""
		return ruta
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null:
		return ""
	if bool(_actual.get("_solo_dorado", false)):
		return recuerdos.elegir_linea("dorado")
	var quien := str(_actual.get("_quien", ""))
	if str(_actual.get("album", "")) == "familia" and quien != "":
		return recuerdos.elegir_linea("familiar", quien)
	return recuerdos.elegir_linea("entrega")


func _cambiar(estado_nuevo: String) -> void:
	_estado = estado_nuevo
	_t = 0.0
	_tocado = false


func _process(delta: float) -> void:
	_t += delta
	_tiempo += delta
	if _sobre.visible:
		_sobre.queue_redraw()
	match _estado:
		"entrando":
			if _t >= BAJADA:
				_cambiar("sobre")
		"sobre":
			_sobre.rotation = sin(_tiempo * 5.0) * 0.06
			if _tocado or _t >= AUTO_ABRIR:
				_abrir()
		"foto":
			var audio := get_node_or_null("/root/Audio")
			var hablando: bool = audio != null and audio.esta_hablando()
			if (_tocado and _t >= TOQUE_FOTO_DESDE) or (_t >= MIN_FOTO and not hablando) or _t >= MAX_FOTO:
				_guardar_foto()
		"volando":
			if _t >= VUELO + 0.25:
				if _cola.is_empty():
					_terminar()
				else:
					_siguiente()


func _al_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_fondo.accept_event()
		_al_tocar()


## Respuesta inmediata a cualquier toque (<100 ms): sonido y rebote de lo que esta en pantalla.
func _al_tocar() -> void:
	_sfx(SFX_TOQUE)
	# en la foto, un toque que venia de antes (<0,7 s) no se la salta
	_tocado = _estado != "foto" or _t >= TOQUE_FOTO_DESDE
	match _estado:
		"entrando", "sobre":
			_sobre.scale = Vector2(1.12, 0.9)
			_sobre.create_tween().tween_property(_sobre, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if _estado == "entrando":
				# se abre apenas termine de llegar
				_estado = "sobre"
				_t = AUTO_ABRIR
		"foto":
			if _foto != null:
				_foto.scale = Vector2(1.04, 0.97)
				_foto.create_tween().tween_property(_foto, "scale", Vector2.ONE, 0.2)


func _abrir() -> void:
	_cambiar("abriendo")
	_sfx(SFX_ABRIR)
	var tween := _sobre.create_tween().set_parallel(true)
	tween.tween_property(_sobre, "scale", Vector2(1.6, 1.6), 0.3)
	tween.tween_property(_sobre, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(_sobre.hide)
	_estallido(PANTALLA / 2.0)
	# polaroid estelar
	if _foto != null:
		_foto.queue_free()
	_foto = FotoRecuerdo.new()
	_foto.name = "foto"
	var alto := ALTO_FOTO
	_foto.size = Vector2(alto * 0.84, alto)
	_foto.pivot_offset = _foto.size / 2.0
	_foto.position = PANTALLA / 2.0 - _foto.size / 2.0
	_fondo.add_child(_foto)
	_foto.configurar(_actual, false)
	_foto.scale = Vector2(0.15, 0.15)
	_foto.rotation = -0.2
	var crecer := _foto.create_tween().set_parallel(true)
	crecer.tween_property(_foto, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	crecer.tween_property(_foto, "rotation", -0.03, 0.55)
	_lanzar_confeti()
	_sfx(SFX_FIESTA)
	# voz de la familia; si todavia no existe, una linea generica de Cometa (si esta grabada)
	var recuerdos := get_node_or_null("/root/Recuerdos")
	var audio := get_node_or_null("/root/Audio")
	var stream: AudioStream = recuerdos.stream_voz(_actual) if recuerdos != null else null
	if audio != null:
		if stream != null:
			audio.reproducir_voz_stream(stream)
		elif recuerdos != null and not bool(_actual.get("_solo_dorado", false)):
			var generica: String = recuerdos.elegir_linea("generica")
			if generica != "":
				audio.reproducir_voz(generica)
	_despues(0.55, func() -> void:
		if _estado == "abriendo":
			_cambiar("foto"))


func _guardar_foto() -> void:
	_cambiar("volando")
	_sfx(SFX_GUARDAR)
	if _confeti != null:
		_confeti.emitting = false
	var tween := _foto.create_tween().set_parallel(true)
	var destino := destino_album - _foto.size / 2.0
	tween.tween_property(_foto, "position", destino, VUELO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_foto, "scale", Vector2(0.12, 0.12), VUELO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_foto, "rotation", 0.5, VUELO)
	tween.chain().tween_callback(_llego_al_album)
	if _cola.is_empty() and voz_final != "":
		_despues(VUELO, _decir.bind(voz_final))


func _llego_al_album() -> void:
	if _foto != null:
		_foto.queue_free()
		_foto = null
	_estallido(destino_album, 10)
	if _icono != null and _icono.has_method("rebotar"):
		_icono.rebotar()
	rebote_album.emit()


## Para que la pantalla que monta la entrega haga rebotar SU boton del album.
signal rebote_album


func _terminar() -> void:
	_cambiar("fin")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_velo, "color:a", 0.0, 0.3)
	if _icono_propio and _icono != null:
		tween.tween_property(_icono, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.chain().tween_callback(func() -> void:
		terminada.emit()
		queue_free())


# ---------------------------------------------------------------------------
# Dibujo y efectos
# ---------------------------------------------------------------------------

## Sobre-estrella: sobre lila con solapa y un sello-estrella con carita en el centro.
func _dibujar_sobre() -> void:
	var s := _sobre.size
	var cuerpo := StyleBoxFlat.new()
	cuerpo.bg_color = Color("#E9DDFF")
	cuerpo.set_corner_radius_all(22)
	cuerpo.border_color = COLOR_CONTORNO
	cuerpo.set_border_width_all(6)
	cuerpo.shadow_color = Color(0, 0, 0, 0.3)
	cuerpo.shadow_offset = Vector2(0, 8)
	cuerpo.shadow_size = 4
	_sobre.draw_style_box(cuerpo, Rect2(Vector2.ZERO, s))
	var solapa := PackedVector2Array([Vector2(12, 12), Vector2(s.x - 12, 12), Vector2(s.x / 2.0, s.y * 0.58)])
	_sobre.draw_colored_polygon(solapa, Color("#CDB8FA"))
	_sobre.draw_polyline(PackedVector2Array([Vector2(12, 12), Vector2(s.x / 2.0, s.y * 0.58), Vector2(s.x - 12, 12)]), COLOR_CONTORNO, 5.0, true)
	var pulso := 1.0 + 0.06 * sin(_tiempo * 6.0)
	Figura.dibujar(_sobre, "estrella", DORADO, Vector2(s.x / 2.0, s.y * 0.56), 62.0 * pulso, true, true)
	for k in 4:
		var angulo := _tiempo * 1.5 + k * TAU / 4.0
		var p := s / 2.0 + Vector2(cos(angulo) * s.x * 0.62, sin(angulo) * s.y * 0.7)
		Figura.dibujar(_sobre, "estrella", Color("#FFE38A"), p, 12.0, false)


func _estallido(centro: Vector2, cantidad := 16) -> void:
	for k in cantidad:
		var chispa := Control.new()
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chispa.size = Vector2.ONE * 30.0
		chispa.pivot_offset = chispa.size / 2.0
		var color: Color = Figura.COLORES_ARCOIRIS[k % Figura.COLORES_ARCOIRIS.size()]
		chispa.draw.connect(func() -> void: Figura.dibujar(chispa, "estrella", color, chispa.size / 2.0, 13.0, false))
		_fondo.add_child(chispa)
		chispa.position = centro - chispa.size / 2.0
		var destino := chispa.position + Vector2.from_angle(TAU * k / cantidad) * randf_range(120.0, 220.0)
		var tween := chispa.create_tween().set_parallel(true)
		tween.tween_property(chispa, "position", destino, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chispa, "scale", Vector2.ZERO, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chispa.queue_free)


## Confeti suave cayendo desde arriba mientras se mira la foto.
func _lanzar_confeti() -> void:
	if _confeti != null:
		_confeti.queue_free()
	_confeti = CPUParticles2D.new()
	_confeti.position = Vector2(PANTALLA.x / 2.0, -20)
	_confeti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confeti.emission_rect_extents = Vector2(PANTALLA.x / 2.0, 10)
	_confeti.amount = 120
	_confeti.lifetime = 4.0
	_confeti.direction = Vector2.DOWN
	_confeti.spread = 20.0
	_confeti.initial_velocity_min = 60.0
	_confeti.initial_velocity_max = 180.0
	_confeti.gravity = Vector2(0, 110)
	_confeti.angular_velocity_min = -360.0
	_confeti.angular_velocity_max = 360.0
	_confeti.scale_amount_min = 7.0
	_confeti.scale_amount_max = 12.0
	var gradiente := Gradient.new()
	gradiente.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var colores := PackedColorArray()
	var offsets := PackedFloat32Array()
	for i in Figura.COLORES_ARCOIRIS.size():
		offsets.append(float(i) / Figura.COLORES_ARCOIRIS.size())
		colores.append(Figura.COLORES_ARCOIRIS[i])
	gradiente.offsets = offsets
	gradiente.colors = colores
	_confeti.color_initial_ramp = gradiente
	_fondo.add_child(_confeti)
	_fondo.move_child(_confeti, 1)
	_confeti.emitting = true


func _decir(ruta: String) -> void:
	if ruta == "":
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_voz(ruta)


func _sfx(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(ruta)


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos, true).timeout
	if is_inside_tree():
		accion.call()
