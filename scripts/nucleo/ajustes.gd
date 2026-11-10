extends Control
## Ajustes / zona de papas (decision del PO 10-Nov-2026). Se entra desde el boton "ajustes" del titulo.
##
## Primero pide un PIN de 4 digitos (`Progreso.PIN_MODO_DIOS`) para que los ninos no entren por accidente;
## despues muestra el panel del modo dios: activarlo/apagarlo y borrar su guardado aparte. Esta pantalla es
## para adultos, por eso usa texto y botones normales (no aplica la regla de "sin texto" del GDD §6).

const RUTA_TITULO := "res://escenas/nucleo/titulo.tscn"
const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/confirmar.ogg"
const LARGO_PIN := 4
const COLOR_FONDO := Color(0.12, 0.06, 0.3)
const COLOR_ORO := Color(1.0, 0.85, 0.3)

var _pin := ""
var _puntos: Array[Panel] = []
var _caja_puntos: HBoxContainer
var _vista_pin: VBoxContainer
var _vista_panel: VBoxContainer
var _estado: Label
var _boton_dios: Button
var _aviso: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = COLOR_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_construir_vista_pin()
	_construir_vista_panel()
	_mostrar_pin()


# --- PIN ---------------------------------------------------------------------

func _construir_vista_pin() -> void:
	_vista_pin = _columna(Vector2(440, 40), 400)
	_vista_pin.add_child(_texto("Zona de papás", 40, COLOR_ORO))
	_vista_pin.add_child(_texto("Ingresa el PIN de 4 dígitos", 22, Color(1, 1, 1, 0.85)))
	_caja_puntos = HBoxContainer.new()
	_caja_puntos.alignment = BoxContainer.ALIGNMENT_CENTER
	_caja_puntos.add_theme_constant_override("separation", 22)
	for i in LARGO_PIN:
		var punto := Panel.new()
		punto.custom_minimum_size = Vector2(28, 28)
		_caja_puntos.add_child(punto)
		_puntos.append(punto)
	_vista_pin.add_child(_caja_puntos)
	var teclado := GridContainer.new()
	teclado.columns = 3
	teclado.add_theme_constant_override("h_separation", 16)
	teclado.add_theme_constant_override("v_separation", 12)
	for etiqueta in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "volver", "0", "borrar"]:
		var boton := _boton(etiqueta, Vector2(120, 88), 34 if etiqueta.length() == 1 else 22)
		boton.pressed.connect(_al_tecla.bind(etiqueta))
		teclado.add_child(boton)
	_vista_pin.add_child(teclado)
	_pintar_puntos()


func _al_tecla(etiqueta: String) -> void:
	_sonar()
	match etiqueta:
		"volver":
			_volver_al_titulo()
		"borrar":
			_pin = _pin.substr(0, maxi(0, _pin.length() - 1))
			_pintar_puntos()
		_:
			ingresar_digito(etiqueta)


## Publica para el arnes: agrega un digito y valida al completar los 4.
func ingresar_digito(digito: String) -> void:
	if _pin.length() >= LARGO_PIN:
		return
	_pin += digito
	_pintar_puntos()
	if _pin.length() < LARGO_PIN:
		return
	if Progreso.pin_valido(_pin):
		_pin = ""
		_mostrar_panel()
	else:
		_pin_incorrecto()


func _pin_incorrecto() -> void:
	_pin = ""
	var origen := _caja_puntos.position
	var tween := create_tween()
	for desvio in [14.0, -14.0, 9.0, -9.0, 0.0]:
		tween.tween_property(_caja_puntos, "position:x", origen.x + desvio, 0.05)
	tween.tween_callback(_pintar_puntos)


func _pintar_puntos() -> void:
	for i in _puntos.size():
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(14)
		estilo.bg_color = COLOR_ORO if i < _pin.length() else Color(1, 1, 1, 0.18)
		_puntos[i].add_theme_stylebox_override("panel", estilo)


func _unhandled_key_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo) or not _vista_pin.visible:
		return
	var tecla: int = (evento as InputEventKey).keycode
	if tecla >= KEY_0 and tecla <= KEY_9:
		ingresar_digito(str(tecla - KEY_0))
	elif tecla >= KEY_KP_0 and tecla <= KEY_KP_9:
		ingresar_digito(str(tecla - KEY_KP_0))
	elif tecla == KEY_BACKSPACE:
		_al_tecla("borrar")


# --- Panel del modo dios -------------------------------------------------------

func _construir_vista_panel() -> void:
	_vista_panel = _columna(Vector2(290, 60), 700)
	_vista_panel.add_child(_texto("Modo dios", 40, COLOR_ORO))
	var explicacion := _texto("Abre todo el juego: todos los planetas, todas las zonas y estaciones, los "
		+ "niveles dorados, \"¡Juntos!\" y el hito de la batalla. Usa un guardado aparte: el progreso real "
		+ "de los niños no se toca. Se apaga solo al cerrar la app.", 20, Color(1, 1, 1, 0.85))
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacion.custom_minimum_size.x = 700
	_vista_panel.add_child(explicacion)
	_estado = _texto("", 26, Color.WHITE)
	_vista_panel.add_child(_estado)
	_boton_dios = _boton("", Vector2(420, 80), 26)
	_boton_dios.pressed.connect(_alternar_modo_dios)
	_vista_panel.add_child(_boton_dios)
	var borrar := _boton("Borrar guardado de prueba", Vector2(420, 64), 22)
	borrar.pressed.connect(_borrar_guardado)
	_vista_panel.add_child(borrar)
	var volver := _boton("Volver al título", Vector2(420, 64), 22)
	volver.pressed.connect(_volver_al_titulo)
	_vista_panel.add_child(volver)
	_aviso = _texto("", 18, Color(0.7, 1.0, 0.7))
	_vista_panel.add_child(_aviso)


func _alternar_modo_dios() -> void:
	_sonar()
	if Progreso.modo_dios:
		Progreso.desactivar_modo_dios()
		_aviso.text = "Volviste al guardado real de los niños."
	else:
		Progreso.activar_modo_dios(Progreso.PIN_MODO_DIOS)
		_aviso.text = "Modo dios activo: elige un hermano y juega lo que quieras."
	_pintar_panel()


func _borrar_guardado() -> void:
	_sonar()
	Progreso.borrar_guardado_dios()
	_aviso.text = "Guardado de prueba borrado (el real sigue intacto)."


func _pintar_panel() -> void:
	_estado.text = "Estado: ACTIVO" if Progreso.modo_dios else "Estado: apagado"
	_estado.add_theme_color_override("font_color", COLOR_ORO if Progreso.modo_dios else Color.WHITE)
	_boton_dios.text = "Apagar modo dios" if Progreso.modo_dios else "Activar modo dios"


func _mostrar_pin() -> void:
	_vista_pin.visible = true
	_vista_panel.visible = false


func _mostrar_panel() -> void:
	_vista_pin.visible = false
	_vista_panel.visible = true
	_aviso.text = ""
	_pintar_panel()


func panel_visible() -> bool:
	return _vista_panel.visible


func _volver_al_titulo() -> void:
	get_tree().change_scene_to_file(RUTA_TITULO)


# --- Utilidades de UI ----------------------------------------------------------

func _columna(posicion: Vector2, ancho: float) -> VBoxContainer:
	var columna := VBoxContainer.new()
	columna.position = posicion
	columna.custom_minimum_size.x = ancho
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 18)
	add_child(columna)
	return columna


func _texto(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta


func _boton(texto: String, tamano_min: Vector2, tamano_fuente: int) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = tamano_min
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton.add_theme_font_size_override("font_size", tamano_fuente)
	return boton


func _sonar() -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null and ResourceLoader.exists(RUTA_SFX_TOQUE):
		audio.reproducir_sfx(RUTA_SFX_TOQUE)
