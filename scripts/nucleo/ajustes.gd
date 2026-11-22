extends Control
## Ajustes / zona de papas (decision del PO 10-Nov-2026). Se entra desde el boton "ajustes" del titulo.
##
## Primero pide un PIN de 4 digitos (`Progreso.PIN_MODO_DIOS`) para que los ninos no entren por accidente;
## despues muestra el panel: modo dios (activarlo/apagarlo y borrar su guardado aparte), volumen de musica,
## efectos y voz (21-Nov-2026) y "Reiniciar partidas" con confirmacion en dos toques. Esta pantalla es
## para adultos, por eso usa texto y botones normales (no aplica la regla de "sin texto" del GDD §6).

const RUTA_TITULO := "res://escenas/nucleo/titulo.tscn"
const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/confirmar.ogg"
const LARGO_PIN := 4
const COLOR_FONDO := Color(0.12, 0.06, 0.3)
const COLOR_ORO := Color(1.0, 0.85, 0.3)
const ANCHO_COLUMNA := 520.0
## Bus de audio -> nombre que ve el papa.
const BUSES_VOLUMEN := {"Musica": "Música", "SFX": "Efectos", "Voz": "Voz"}
const RUTA_VOZ_MUESTRA := "res://assets/audio/voces/nucleo/titulo_vuelta_01.wav"

var _pin := ""
var _puntos: Array[Panel] = []
var _caja_puntos: HBoxContainer
var _vista_pin: VBoxContainer
var _vista_panel: VBoxContainer
var _estado: Label
var _boton_dios: Button
var _aviso: Label
var _boton_reiniciar: Button
var _boton_cancelar: Button
var _confirmando_reinicio := false
var _barras_volumen: Dictionary = {}
var _volumen_cambiado := false


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
	_vista_panel = _columna(Vector2(60, 24), 1160)
	_vista_panel.add_theme_constant_override("separation", 14)
	_vista_panel.add_child(_texto("Zona de papás", 36, COLOR_ORO))
	var columnas := HBoxContainer.new()
	columnas.alignment = BoxContainer.ALIGNMENT_CENTER
	columnas.add_theme_constant_override("separation", 60)
	columnas.add_child(_construir_columna_dios())
	columnas.add_child(_construir_columna_sonido())
	_vista_panel.add_child(columnas)
	var volver := _boton("Volver al título", Vector2(420, 64), 22)
	volver.pressed.connect(_volver_al_titulo)
	_vista_panel.add_child(volver)
	_aviso = _texto("", 18, Color(0.7, 1.0, 0.7))
	_vista_panel.add_child(_aviso)


func _construir_columna_dios() -> VBoxContainer:
	var columna := _columna_interna()
	columna.add_child(_texto("Modo dios", 28, COLOR_ORO))
	var explicacion := _texto("Abre todo el juego: todos los planetas, todas las zonas y estaciones, los "
		+ "niveles dorados, \"¡Juntos!\" y el hito de la batalla. Usa un guardado aparte: el progreso real "
		+ "de los niños no se toca. Se apaga solo al cerrar la app.", 18, Color(1, 1, 1, 0.85))
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacion.custom_minimum_size.x = ANCHO_COLUMNA
	columna.add_child(explicacion)
	_estado = _texto("", 24, Color.WHITE)
	columna.add_child(_estado)
	_boton_dios = _boton("", Vector2(400, 72), 24)
	_boton_dios.pressed.connect(_alternar_modo_dios)
	columna.add_child(_boton_dios)
	var borrar := _boton("Borrar guardado de prueba", Vector2(400, 60), 20)
	borrar.pressed.connect(_borrar_guardado)
	columna.add_child(borrar)
	return columna


func _construir_columna_sonido() -> VBoxContainer:
	var columna := _columna_interna()
	columna.add_child(_texto("Sonido", 28, COLOR_ORO))
	for bus in BUSES_VOLUMEN:
		columna.add_child(_fila_volumen(bus, BUSES_VOLUMEN[bus]))
	columna.add_child(_texto("Partidas", 28, COLOR_ORO))
	var explicacion := _texto("Borra el avance de Maxi, Nicole y Sofía (planetas, destellos, piezas, álbum "
		+ "y récords) y el juego parte desde cero. El volumen se mantiene.", 18, Color(1, 1, 1, 0.85))
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacion.custom_minimum_size.x = ANCHO_COLUMNA
	columna.add_child(explicacion)
	_boton_reiniciar = _boton("", Vector2(400, 64), 22)
	_boton_reiniciar.pressed.connect(_al_reiniciar)
	columna.add_child(_boton_reiniciar)
	_boton_cancelar = _boton("Cancelar", Vector2(400, 56), 20)
	_boton_cancelar.pressed.connect(_cancelar_reinicio)
	columna.add_child(_boton_cancelar)
	_pintar_reinicio()
	return columna


func _fila_volumen(bus: String, nombre: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	var etiqueta := _texto(nombre, 20, Color.WHITE)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	etiqueta.custom_minimum_size.x = 110
	fila.add_child(etiqueta)
	var barra := HSlider.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.step = 0.05
	barra.custom_minimum_size = Vector2(300, 48)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.value = Audio.obtener_volumen(bus)
	fila.add_child(barra)
	var porcentaje := _texto("", 20, Color(1, 1, 1, 0.85))
	porcentaje.custom_minimum_size.x = 70
	fila.add_child(porcentaje)
	porcentaje.text = "%d%%" % roundi(barra.value * 100.0)
	barra.value_changed.connect(_al_cambiar_volumen.bind(bus, porcentaje))
	barra.drag_ended.connect(_al_soltar_volumen.bind(bus))
	_barras_volumen[bus] = barra
	return fila


func _al_cambiar_volumen(valor: float, bus: String, porcentaje: Label) -> void:
	Audio.set_volumen(bus, valor)
	porcentaje.text = "%d%%" % roundi(valor * 100.0)
	_volumen_cambiado = true


## Al soltar la barra se escucha una muestra del nivel elegido.
func _al_soltar_volumen(_cambio: bool, bus: String) -> void:
	if bus == Audio.BUS_VOZ and ResourceLoader.exists(RUTA_VOZ_MUESTRA):
		Audio.reproducir_voz(RUTA_VOZ_MUESTRA)
	elif bus == Audio.BUS_SFX:
		_sonar()


## Publica para el arnes y la UI.
func fijar_volumen(bus: String, valor: float) -> void:
	if _barras_volumen.has(bus):
		_barras_volumen[bus].value = valor


func _guardar_volumen_si_cambio() -> void:
	if _volumen_cambiado:
		Audio.guardar_volumenes()
		_volumen_cambiado = false


func _al_reiniciar() -> void:
	_sonar()
	if not _confirmando_reinicio:
		_confirmando_reinicio = true
		_pintar_reinicio()
		_aviso.text = "¿Seguro? Esto no se puede deshacer desde el juego."
		return
	reiniciar_partidas()


## Publica para el arnes: borra el guardado real sin pasar por la confirmacion.
func reiniciar_partidas() -> void:
	Progreso.reiniciar_partidas()
	_confirmando_reinicio = false
	_pintar_reinicio()
	if Progreso.modo_dios:
		_aviso.text = "Partidas reales reiniciadas. El modo dios sigue activo con su guardado aparte."
	else:
		_aviso.text = "Partidas reiniciadas: el juego parte desde cero."


func _cancelar_reinicio() -> void:
	_sonar()
	_confirmando_reinicio = false
	_pintar_reinicio()
	_aviso.text = ""


func _pintar_reinicio() -> void:
	_boton_reiniciar.text = "Sí, borrar todo" if _confirmando_reinicio else "Reiniciar partidas"
	_boton_reiniciar.add_theme_color_override("font_color",
		Color(1.0, 0.55, 0.5) if _confirmando_reinicio else Color.WHITE)
	_boton_cancelar.visible = _confirmando_reinicio


func _columna_interna() -> VBoxContainer:
	var columna := VBoxContainer.new()
	columna.custom_minimum_size.x = ANCHO_COLUMNA
	columna.alignment = BoxContainer.ALIGNMENT_BEGIN
	columna.add_theme_constant_override("separation", 12)
	return columna


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
	_confirmando_reinicio = false
	_pintar_reinicio()
	_pintar_panel()


func panel_visible() -> bool:
	return _vista_panel.visible


func _volver_al_titulo() -> void:
	_guardar_volumen_si_cambio()
	get_tree().change_scene_to_file(RUTA_TITULO)


func _exit_tree() -> void:
	_guardar_volumen_si_cambio()


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
