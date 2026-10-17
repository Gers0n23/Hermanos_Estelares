extends SceneTree

## Capturas del modo equipo (HE-59) en ventana real, para revision visual del PO, `experto-ux-parvulo` y
## `tester-qa`: seleccion con "¡Juntos!" y armar equipo, mapa del equipo, Parejas en equipo (puerta, turno
## de Maxi con halo, guirnalda de Nicole, turno perfecto y resbalon, derrota-gag) y la fiesta multihermano.
## La puerta del primer turno se abre con un CLIC DE MOUSE real (`Input.parse_input_event`): prueba que la
## entrada unificada (mouse emulado como toque) llega al GestorTurnos.
## Usa el guardado de pruebas (lo fija Progreso al correr con --script) y lo deja limpio al terminar.
##
## Uso: godot --path . --script herramientas/capturar_equipo.gd -- <carpeta_salida>

const MOTOR := "res://escenas/minijuegos/emparejar/motor_emparejar.tscn"
const NIVEL := "res://datos/niveles/arcoiris/zona1_claro/parejas_equipo.json"
const SELECCION := "res://escenas/nucleo/seleccion_personaje.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"

var _carpeta := ""
var _progreso: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_carpeta = args[0] if args.size() > 0 else "user://capturas_equipo"
	DirAccess.make_dir_recursive_absolute(_carpeta)
	_progreso = get_root().get_node("Progreso")
	if _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: no es el guardado de pruebas")
		quit(1)
		return
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await process_frame
	await _seleccion()
	await _mapa()
	await _partida()
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	quit(0)


func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout


func _esperar_que(condicion: Callable, maximo := 10.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var imagen := get_root().get_texture().get_image()
	var ruta := _carpeta.path_join(nombre + ".png")
	imagen.save_png(ruta)
	print("captura: ", ruta)


func _clic(punto: Vector2) -> void:
	for presionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.pressed = presionado
		evento.position = punto
		evento.global_position = punto
		Input.parse_input_event(evento)
		await process_frame


func _seleccion() -> void:
	var recuerdos := get_root().get_node_or_null("Recuerdos")
	if recuerdos != null:
		recuerdos.desbloquear({"tipo": "primera_apertura"}, "")
	var ids: Array[String] = ["maxi", "nicole", "sofia"]
	_progreso.registrar_batalla_ganada("arcoiris_batalla_final", "arcoiris", ids, 0)
	_progreso.registrar_victoria_equipo("arcoiris", "arcoiris_z1_parejas_equipo", ids, 0, 4)
	change_scene_to_file(SELECCION)
	await _esperar(2.4)
	await _foto("01_seleccion_presentacion_nave")
	await _esperar(1.0)
	var sel := current_scene
	await _clic(sel.RECT_JUNTOS.get_center())
	await _esperar(0.8)
	var nicole: Control = sel.get_node("tarjeta_nicole")
	await _clic(Rect2(nicole.global_position, nicole.size).get_center())
	await _esperar(0.6)
	await _foto("02_armar_equipo_nicole_al_puf")
	await _clic(Rect2(nicole.global_position, nicole.size).get_center())
	await _esperar(0.4)


func _mapa() -> void:
	var ids: Array[String] = ["maxi", "nicole", "sofia"]
	_progreso.fijar_equipo(ids)
	change_scene_to_file(ARCOIRIS)
	await _esperar(1.5)
	await _foto("03_mapa_del_equipo")
	current_scene._abrir_burbuja(1)
	await _esperar(0.8)
	await _foto("04_mapa_del_equipo_burbuja_zona2")


func _partida() -> void:
	_progreso.limpiar_equipo()
	var vacio := Node.new()
	get_root().add_child(vacio)
	current_scene = vacio
	for hijo in get_root().get_children():
		if hijo.name == "mapa_arcoiris":
			hijo.queue_free()
	var motor: Node = load(MOTOR).instantiate()
	motor.ruta_nivel = NIVEL
	motor.planeta_id = ""
	motor.equipo = ["maxi", "nicole", "sofia"] as Array[String]
	motor.segundos_auto_continuar = 6.0
	get_root().add_child(motor)
	var g: GestorTurnos = motor.turnos
	await _esperar_que(func() -> bool: return g.en_puerta(), 15.0)
	await _esperar(0.5)
	await _foto("05_puerta_le_toca_a_maxi")
	# La puerta se abre con un clic de mouse real sobre el retrato grande.
	await _clic(Vector2(640, 364))
	var abrio := await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada(), 3.0)
	print("clic de mouse abre la puerta: ", abrio)
	await _esperar(0.6)
	await _foto("06_turno_de_maxi_halo")
	for carta in motor._eq_halo.duplicate():
		motor._al_tocar_carta(carta)
		await _esperar(0.3)
	await _esperar_que(func() -> bool: return g.en_puerta(), 8.0)
	await _esperar(0.3)
	await _foto("07_puerta_de_arrastre_nicole")
	g.abrir_puerta()
	await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada(), 5.0)
	_formar_par(motor)
	await _esperar(0.5)
	await _foto("08_guirnalda_nicole_una_encendida")
	_formar_par(motor)
	await _esperar(1.6)
	await _foto("09_turno_perfecto_0b")
	await _esperar_que(func() -> bool: return g.en_puerta(), 8.0)
	await _esperar(0.7)
	await _foto("10_resbalon_rival_sentado")
	# Derrota: el rival a un paso y un fallo.
	g.abrir_puerta()
	await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada(), 5.0)
	for carta in motor._eq_halo.duplicate():
		motor._al_tocar_carta(carta)
	await _esperar_que(func() -> bool: return g.en_puerta(), 8.0)
	g.abrir_puerta()
	await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada(), 5.0)
	g._pos_rival = g.pasos_rival() - 1
	g.pista.fijar_posicion(g._pos_rival)
	var par := _dos_distintas(motor)
	motor._al_tocar_carta(par[0])
	motor._al_tocar_carta(par[1])
	await _esperar_que(func() -> bool: return motor.en_derrota_equipo(), 8.0)
	await _esperar(0.5)
	await _foto("11_derrota_gag_aspira")
	await _esperar(1.4)
	await _foto("12_derrota_gag_sentado")
	motor.tocar_otra_vez_equipo()
	await _esperar(0.3)
	# Victoria: se forman todos los pares que faltan.
	await _esperar_que(func() -> bool: return g.en_puerta(), 12.0)
	g.detener()
	var pendientes := {}
	for carta in motor._cartas:
		if not carta.esta_acertada:
			pendientes[carta.id_pareja] = true
	var claves := pendientes.keys()
	g._turno_activo = true
	g._bloqueada = false
	g._actual = "sofia"
	g._detenido = false
	g._topes = {"semilla": 1}
	for clave in claves:
		var grupo: Array[CartaEmparejar] = []
		for carta in motor._cartas:
			if carta.id_pareja == clave and not carta.esta_acertada:
				grupo.append(carta)
		motor._par_equipo(grupo)
	await _esperar(4.2)
	await _foto("13_fiesta_equipo_gestos")
	await _esperar(2.4)
	await _foto("14_fiesta_equipo_choque")


func _formar_par(motor: Node) -> void:
	for carta in motor._cartas:
		if carta.esta_acertada:
			continue
		for otra in motor._cartas:
			if otra != carta and otra.id_pareja == carta.id_pareja and not otra.esta_acertada:
				motor._al_tocar_carta(carta)
				motor._al_tocar_carta(otra)
				return


func _dos_distintas(motor: Node) -> Array:
	var primera = null
	for carta in motor._cartas:
		if carta.esta_acertada:
			continue
		if primera == null:
			primera = carta
		elif carta.id_pareja != primera.id_pareja:
			return [primera, carta]
	return []
