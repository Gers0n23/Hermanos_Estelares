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
##
## HE-44 (validacion disenador-mecanicas + auditoria UX, 28-Sep-2026, PROVISIONAL):
## - El sobre se abre solo recien cuando Cometa termina su frase (+0,4 s; minimo 3 s, tope 6 s). Si el
##   nino lo abre antes, la voz de Cometa se desvanece en 0,15 s y la de la familia entra 0,35 s despues.
## - Antes de la voz de la familia, Cometa narra el pie de foto ("Aqui tenia tres mesecitos"), salvo que
##   el catalogo marque `pie_en_audio`. Sin audio de la familia: pie + linea generica.
## - Tocar la foto ANTES de que termine su audio no la cierra: la foto reacciona (squash, chispas y
##   "clic"). Despues del audio, un toque la guarda; si no, se va sola 1,5 s despues (4,5 s si no hay
##   audio). En Semilla (Maxi) los toques nunca la cierran: se va sola.
##
## HE-44 mecanicas #7 y #8 (03-Oct-2026, PROVISIONAL):
## - Cola: el velo se queda puesto entre recuerdos y desde el 2.o sobre Cometa dice una linea corta
##   ("¡Y otra mas!"). Tope de `TOPE_SOBRES` por entrega: quien la monta desbloquea solo esos y el resto
##   llega la proxima vez (`Recuerdos.desbloquear(..., maximo)`).
## - Solo marco dorado (Sofia ya tenia la foto): sin sobre. La polaroid aparece directo y un marco dorado
##   se dibuja a su alrededor en 1,2 s con un brillo que recorre el borde; suena `dorado`, cae confeti
##   dorado y la foto vuela al album.

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
const AUTO_ABRIR := 3.0             # minimo desde que llega el sobre
const TOPE_ABRIR := 6.0             # maximo, aunque Cometa siga hablando
const MARGEN_VOZ_SOBRE := 0.4       # despues de la frase de Cometa
const FUNDIDO_COMETA := 0.15
const PAUSA_VOZ_FAMILIA := 0.35     # la polaroid ya crecio cuando entra la voz
const INVITAR_TOQUE := 1.5          # el sobre salta para invitar a tocarlo (Maxi)
const MIN_FOTO_SIN_AUDIO := 4.5
const COLA_TRAS_AUDIO := 1.5
const MAX_FOTO := 14.0
const VUELO := 0.65
const HALO_ICONO := 0.8
const TOPE_SOBRES := 3
## Centro del boton del album en la seleccion de personaje (`seleccion_personaje.gd` RECT_ALBUM).
const DESTINO_ALBUM := Vector2(1000, 656)
const DIBUJO_MARCO := 1.2

## Donde esta el icono del album en la pantalla que monta la entrega; si es negativo, la entrega
## dibuja su propio icono arriba a la derecha.
var destino_album := Vector2(-1, -1)
## Linea de Cometa al aparecer el sobre y al guardar la foto (primera apertura: guion §1.1).
var voz_sobre := ""
## La frase del sobre cuenta la historia (primera apertura): el sobre no se abre solo antes de que
## termine, aunque pase el tope de 6 s (UX N1). El nino igual puede abrirlo antes con un toque.
var esperar_frase_completa := false
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
## Segundos (desde que llega el sobre) en que se abre solo: tras la frase de Cometa, entre 3 y 6 s.
var _abrir_en := AUTO_ABRIR
var _invito := false
## Audio de la foto: cola de lineas (rutas res:// o AudioStream) que suenan una tras otra.
var _cola_audio: Array = []
var _hay_audio_foto := false
var _audio_termino_en := -1.0
var _flash: ColorRect
var _mostrados := 0
## Marco dorado que se dibuja alrededor de la foto (entrega de solo marco dorado).
var _marco: Control
var _progreso_marco := 0.0


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
		# Donde vive el boton real del album (seleccion de personaje, abajo a la derecha): asi el nino
		# aprende un solo lugar (UX HE-44 R8, 03-Oct-2026).
		destino_album = DESTINO_ALBUM
		_icono = BotonAlbum.new()
		_icono.interactivo = false
		_icono.size = Vector2(140, 120)
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
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.size = PANTALLA
	_fondo.add_child(_flash)


func _siguiente() -> void:
	_actual = _cola.pop_front()
	_mostrados += 1
	_velo.create_tween().tween_property(_velo, "color:a", 0.6, 0.35)
	if _icono_propio:
		_icono.create_tween().tween_property(_icono, "modulate:a", 1.0, 0.35)
	if bool(_actual.get("_solo_dorado", false)):
		_mostrar_marco_dorado()
		return
	_cambiar("entrando")
	_sobre.show()
	_sobre.modulate.a = 1.0
	_sobre.scale = Vector2.ONE
	_sobre.position = Vector2(PANTALLA.x / 2.0 - TAM_SOBRE.x / 2.0, -TAM_SOBRE.y - 40.0)
	_sobre.rotation = -TAU
	var tween := _sobre.create_tween().set_parallel(true)
	tween.tween_property(_sobre, "position:y", PANTALLA.y / 2.0 - TAM_SOBRE.y / 2.0 - 20.0, BAJADA).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sobre, "rotation", 0.0, BAJADA).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sobre.set_meta("estrella_grande", 1.0)
	var linea := _linea_sobre()
	_decir(linea)
	# Se abre solo recien cuando Cometa termina su frase (nunca la corta): 3 s minimo, 6 s tope.
	var tope := maxf(TOPE_ABRIR, _duracion(linea) - BAJADA + MARGEN_VOZ_SOBRE) if esperar_frase_completa else TOPE_ABRIR
	esperar_frase_completa = false
	_abrir_en = clampf(_duracion(linea) - BAJADA + MARGEN_VOZ_SOBRE, AUTO_ABRIR, tope)
	_invito = false


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
	# Desde el 2.o sobre de la misma entrega, una linea corta: Cometa no repite la entrada completa.
	if _mostrados > 1:
		var corta: String = recuerdos.elegir_linea("otra")
		if corta != "":
			return corta
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
	if is_instance_valid(_marco):
		_marco.queue_redraw()
	match _estado:
		"entrando":
			if _t >= BAJADA:
				_cambiar("sobre")
		"sobre":
			_sobre.rotation = sin(_tiempo * 5.0) * 0.06
			if not _invito and _t >= INVITAR_TOQUE and not _tocado:
				_invitar_a_tocar()
			if _tocado or _t >= _abrir_en:
				_abrir()
		"foto":
			_avanzar_audio_foto()
			if foto_lista() and (_t >= _cierre_automatico() or (_tocado and not _es_semilla())):
				_guardar_foto()
			elif _t >= MAX_FOTO:
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
		_al_tocar(evento.position)


## Respuesta inmediata a cualquier toque (<100 ms): sonido y rebote de lo que esta en pantalla.
func _al_tocar(punto := Vector2(-1, -1)) -> void:
	_sfx(SFX_TOQUE)
	# En la foto, un toque solo cuenta para guardarla cuando ya sono su audio (HE-44 #1, UX R2).
	_tocado = _estado != "foto" or foto_lista()
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
				# Reaccion juguetona (nunca un toque muerto): squash, chispas desde el dedo y "clic".
				_foto.scale = Vector2(1.04, 0.97)
				_foto.create_tween().tween_property(_foto, "scale", Vector2.ONE, 0.2)
				if not foto_lista() or _es_semilla():
					_estallido(punto if punto.x >= 0.0 else PANTALLA / 2.0, 4)
					_sfx(SFX_GUARDAR)


func _abrir() -> void:
	_cambiar("abriendo")
	_sfx(SFX_ABRIR)
	# Si el nino abrio antes de que Cometa terminara, su voz se desvanece (no se corta en seco).
	var audio_ := get_node_or_null("/root/Audio")
	if audio_ != null and audio_.esta_hablando():
		audio_.desvanecer_voz(FUNDIDO_COMETA)
	# Flash de polaroid.
	_flash.color.a = 0.35
	_flash.create_tween().tween_property(_flash, "color:a", 0.0, 0.12)
	var tween := _sobre.create_tween().set_parallel(true)
	tween.tween_property(_sobre, "scale", Vector2(1.6, 1.6), 0.3)
	tween.tween_property(_sobre, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(_sobre.hide)
	_estallido(PANTALLA / 2.0)
	_crear_foto()
	_foto.scale = Vector2(0.15, 0.15)
	_foto.rotation = -0.2
	var crecer := _foto.create_tween().set_parallel(true)
	crecer.tween_property(_foto, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	crecer.tween_property(_foto, "rotation", -0.03, 0.55)
	_lanzar_confeti()
	_sfx(SFX_FIESTA)
	# Audio de la foto: pie narrado por Cometa + voz de la familia (o, si falta, una linea generica).
	_cola_audio = _audio_de_la_foto()
	_hay_audio_foto = not _cola_audio.is_empty()
	_audio_termino_en = -1.0
	_despues(0.55, func() -> void:
		if _estado == "abriendo":
			_cambiar("foto"))
	_despues(PAUSA_VOZ_FAMILIA, _siguiente_audio_foto)


## Polaroid estelar al centro, a ~70 % de la pantalla.
func _crear_foto() -> void:
	if _foto != null:
		_foto.queue_free()
	_foto = FotoRecuerdo.new()
	_foto.name = "foto"
	_foto.size = Vector2(ALTO_FOTO * 0.84, ALTO_FOTO)
	_foto.pivot_offset = _foto.size / 2.0
	_foto.position = PANTALLA / 2.0 - _foto.size / 2.0
	_fondo.add_child(_foto)
	_foto.configurar(_actual, false)


## Solo marco dorado (HE-44 #8): Sofia ya tenia la foto, asi que no hay sobre. La foto aparece directo
## y el marco dorado se dibuja a su alrededor; despues sigue como cualquier foto (sin audio de familia).
func _mostrar_marco_dorado() -> void:
	_cambiar("abriendo")
	_sobre.hide()
	_decir(_linea_sobre())
	_crear_foto()
	_foto.scale = Vector2(0.92, 0.92)
	_foto.modulate.a = 0.0
	var aparecer := _foto.create_tween().set_parallel(true)
	aparecer.tween_property(_foto, "modulate:a", 1.0, 0.25)
	aparecer.tween_property(_foto, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_foto.rotation = -0.03
	_marco = Control.new()
	_marco.name = "marco_dorado"
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marco.size = _foto.size
	_marco.draw.connect(_dibujar_marco_dorado)
	_foto.add_child(_marco)
	_progreso_marco = 0.0
	var dibujar := _marco.create_tween()
	dibujar.tween_property(self, "_progreso_marco", 1.0, DIBUJO_MARCO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	dibujar.tween_callback(func() -> void:
		_sfx(SFX_FIESTA)
		_estallido(_foto.global_position + _foto.size / 2.0, 12))
	_lanzar_confeti(true)
	_cola_audio = []
	_hay_audio_foto = false
	_audio_termino_en = -1.0
	_despues(DIBUJO_MARCO, func() -> void:
		if _estado == "abriendo":
			_cambiar("foto"))


## Recorre el borde de la foto desde arriba al centro en sentido horario hasta `_progreso_marco`,
## con una chispa brillante en la punta.
func _dibujar_marco_dorado() -> void:
	var s := _marco.size
	var m := -10.0
	var esquinas := [Vector2(s.x / 2.0, m), Vector2(s.x - m, m), Vector2(s.x - m, s.y - m), Vector2(m, s.y - m), Vector2(m, m), Vector2(s.x / 2.0, m)]
	var total := 0.0
	for i in esquinas.size() - 1:
		total += (esquinas[i + 1] - esquinas[i]).length()
	var falta := total * _progreso_marco
	var trazo := PackedVector2Array([esquinas[0]])
	for i in esquinas.size() - 1:
		var tramo: float = (esquinas[i + 1] - esquinas[i]).length()
		if falta >= tramo:
			trazo.append(esquinas[i + 1])
			falta -= tramo
		else:
			trazo.append(esquinas[i].lerp(esquinas[i + 1], falta / tramo))
			break
	if trazo.size() < 2:
		return
	_marco.draw_polyline(trazo, COLOR_CONTORNO, 22.0, true)
	_marco.draw_polyline(trazo, DORADO, 15.0, true)
	_marco.draw_polyline(trazo, Color("#FFF3B0"), 4.0, true)
	var punta: Vector2 = trazo[trazo.size() - 1]
	if _progreso_marco < 1.0:
		Figura.dibujar(_marco, "estrella", Color("#FFF3B0"), punta, 22.0 + 4.0 * sin(_tiempo * 20.0), false)


## Lo que suena con la foto abierta, en orden. El pie no suena si la familia ya lo dijo (`pie_en_audio`).
func _audio_de_la_foto() -> Array:
	var cola: Array = []
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null or bool(_actual.get("_solo_dorado", false)):
		return cola
	var stream: AudioStream = recuerdos.stream_voz(_actual)
	if not bool(_actual.get("pie_en_audio", false)):
		var pie: String = recuerdos.ruta_linea(str(_actual.get("pie", "")))
		if pie != "":
			cola.append(pie)
	if stream != null:
		cola.append(stream)
	else:
		var generica: String = recuerdos.elegir_linea("generica")
		if generica != "":
			cola.append(generica)
	return cola


func _siguiente_audio_foto() -> void:
	if not (_estado in ["abriendo", "foto"]):
		return
	var audio := get_node_or_null("/root/Audio")
	if _cola_audio.is_empty() or audio == null:
		return
	var siguiente = _cola_audio.pop_front()
	if siguiente is AudioStream:
		audio.reproducir_voz_stream(siguiente)
	else:
		audio.reproducir_voz(str(siguiente))


## Encadena las lineas de la foto y anota cuando termino todo su audio.
func _avanzar_audio_foto() -> void:
	if _audio_termino_en >= 0.0 or not _hay_audio_foto:
		return
	var audio := get_node_or_null("/root/Audio")
	var hablando: bool = audio != null and audio.esta_hablando()
	if hablando or _t < 0.1:
		return
	if not _cola_audio.is_empty():
		_siguiente_audio_foto()
		return
	_audio_termino_en = _t


## La foto ya se vio: termino su audio (o pasaron 4,5 s si no tiene). Recien ahi un toque la guarda.
func foto_lista() -> bool:
	if _estado != "foto":
		return false
	if _hay_audio_foto:
		return _audio_termino_en >= 0.0
	return _t >= MIN_FOTO_SIN_AUDIO


func _cierre_automatico() -> float:
	return (_audio_termino_en + COLA_TRAS_AUDIO) if _hay_audio_foto else MIN_FOTO_SIN_AUDIO


## A los 2 anos el toque no es una decision de seguir: en Semilla la foto siempre se va sola.
func _es_semilla() -> bool:
	var quien := str(_actual.get("_quien", ""))
	if quien == "":
		var progreso := get_node_or_null("/root/Progreso")
		quien = str(progreso.perfil_seleccionado) if progreso != null else ""
	return quien == "maxi"


## A los 1,5 s sin toque el sobre salta y su estrella crece: invita a tocarlo (HE-44 #4).
func _invitar_a_tocar() -> void:
	_invito = true
	_sfx(SFX_TOQUE)
	var base := _sobre.position
	var tween := _sobre.create_tween()
	tween.tween_property(_sobre, "position:y", base.y - 18.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sobre, "position:y", base.y, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_sobre.set_meta("estrella_grande", 1.15)


func _duracion(ruta: String) -> float:
	if ruta == "" or not ResourceLoader.exists(ruta):
		return 0.0
	var stream := load(ruta) as AudioStream
	return stream.get_length() if stream != null else 0.0


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
		# El icono se queda un momento con su halo: asi se aprende donde quedo la foto (HE-44 #6).
		tween.tween_property(_icono, "modulate:a", 0.0, 0.3).set_delay(HALO_ICONO)
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
	var pulso := (1.0 + 0.06 * sin(_tiempo * 6.0)) * float(_sobre.get_meta("estrella_grande", 1.0))
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
func _lanzar_confeti(dorado := false) -> void:
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
	var paleta: Array = [DORADO, Color("#FFE38A"), Color("#FFF3B0"), Color("#F2A93B")] if dorado else Figura.COLORES_ARCOIRIS
	for i in paleta.size():
		offsets.append(float(i) / paleta.size())
		colores.append(paleta[i])
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
