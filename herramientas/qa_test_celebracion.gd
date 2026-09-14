extends SceneTree

## Arnes de QA de HE-10: escena de celebracion reutilizable + contrato `minijuego_base.gd`.
## Corre headless (mismo patron que qa_test_emparejar.gd). No escribe en el guardado real:
## el contrato solo registra progreso con `planeta_id`, y aqui nunca se fija.
##
## Uso: godot --headless --path . --script herramientas/qa_test_celebracion.gd

const ESCENA := "res://escenas/ui/celebracion.tscn"
const NIVEL_PILOTO := "res://datos/niveles/piloto_emparejar_estrella_01.json"

var _fallos := 0


func _initialize() -> void:
	print("=== QA celebracion + contrato base (HE-10) ===")
	for id in ["maxi", "nicole", "sofia", "desconocido"]:
		await _probar_celebracion_manual(id)
	await _probar_auto_continuar()
	await _probar_contrato_base()
	await _probar_guardado_antes_de_celebrar()
	_probar_estrellitas_por_perfil()
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(seg: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < seg * 1000:
		await process_frame


func _probar_celebracion_manual(id: String) -> void:
	print("-- celebracion con boton: %s --" % id)
	var c: Node = load(ESCENA).instantiate()
	c.id_personaje = id
	c.destellos = 87
	c.estrellitas = 2
	c.segundos_auto_continuar = 0.0
	var recibida := [false]
	c.terminada.connect(func() -> void: recibida[0] = true)
	get_root().add_child(c)

	await _esperar(1.0)
	_check(c._personaje.texture != null, "personaje con sprite (fallback a Cometa si no existe)")
	_check(not c._boton_continuar.visible, "boton 'seguir' aun oculto a 1 s (no se salta la fiesta)")
	_check(c._raiz.mouse_filter == Control.MOUSE_FILTER_STOP, "bloquea toques al juego de abajo")

	await _esperar(2.4)
	_check(c._etiqueta_conteo.text == "87", "conteo animado llega a 87 (vale '%s')" % c._etiqueta_conteo.text)
	_check(c._boton_continuar.visible, "boton 'seguir' visible a 3.4 s")
	_check(c._boton_continuar.size.x >= 96.0, "boton >= 96 px (GDD §6.1): %.0f px" % c._boton_continuar.size.x)
	var llenas := 0
	for slot in c._slots_estrellitas:
		if slot.color == c.DORADO:
			llenas += 1
	_check(c._slots_estrellitas.size() == 3 and llenas == 2, "3 espacios de estrellitas, 2 llenas (llenas=%d)" % llenas)
	_check(not recibida[0], "no termina sola con auto=0")

	_check(c._boton_continuar.action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS, "boton responde al apoyar el dedo (R1)")
	var hijos_antes: int = c._raiz.get_child_count()
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = c._pos_pies - Vector2(0, c._alto * 0.5)
	c._al_tocar_fondo(toque)
	_check(c._raiz.get_child_count() > hijos_antes, "tocar al personaje suelta estrellitas (R3)")
	await _esperar(0.08)
	_check(c._salto_mimo > 0.0, "tocar al personaje le da un saltito extra (R3)")
	_check(not recibida[0], "tocar fuera del boton nunca cierra la celebracion")

	c._boton_continuar.button_down.emit()
	await _esperar(0.15)
	_check(c._boton_continuar.scale.x < 1.0, "boton se encoge al apoyar el dedo (R2): %.2f" % c._boton_continuar.scale.x)
	c._boton_continuar.pressed.emit()
	await _esperar(0.5)
	_check(recibida[0], "senal terminada tras tocar 'seguir'")
	c.queue_free()
	await process_frame


func _probar_auto_continuar() -> void:
	print("-- celebracion con auto-continuar --")
	var c: Node = load(ESCENA).instantiate()
	c.id_personaje = "maxi"
	c.destellos = 0
	c.segundos_auto_continuar = 1.5
	var veces := [0]
	c.terminada.connect(func() -> void: veces[0] += 1)
	get_root().add_child(c)
	await _esperar(2.3)
	_check(veces[0] == 1, "termina sola una vez tras 1.5 s (veces=%d)" % veces[0])
	_check(c._slots_estrellitas.is_empty(), "sin estrellitas cuando estrellitas=0")
	c.terminar()
	await _esperar(0.4)
	_check(veces[0] == 1, "terminar() es idempotente")
	c.queue_free()
	await process_frame


func _probar_contrato_base() -> void:
	print("-- contrato minijuego_base.gd --")
	var motor := Node2D.new()
	motor.set_script(load("res://scripts/base/minijuego_base.gd"))
	motor.ruta_nivel = NIVEL_PILOTO
	motor.segundos_auto_continuar = 1.0
	var recibidos: Array = []
	motor.completado.connect(func(d: int) -> void: recibidos.append(d))
	get_root().add_child(motor)
	await process_frame

	_check(motor.obtener_perfil_dificultad() == "estrella", "lee perfil del nivel")
	_check(motor.obtener_id_personaje() == "sofia", "sin hermano seleccionado celebra el del perfil (sofia)")
	_check(motor.resolver_ruta_audio("voces/x.ogg") == "res://assets/audio/voces/x.ogg", "resuelve rutas de audio del JSON")
	_check(motor.resolver_ruta_audio("res://y.ogg") == "res://y.ogg", "respeta rutas res:// absolutas")

	motor.celebrar(40, 3, "voces/emparejar/estrella_ponys/victoria_final_01.ogg")
	motor.celebrar(40, 3)
	await process_frame
	var celebraciones := motor.get_children().filter(func(n: Node) -> bool: return n is CanvasLayer)
	_check(celebraciones.size() == 1, "una sola celebracion aunque se llame dos veces")
	_check(recibidos.is_empty(), "completado NO se emite antes de terminar la celebracion")
	await _esperar(2.0)
	_check(recibidos == [40], "completado(40) emitido al terminar (recibidos=%s)" % str(recibidos))
	motor.emitir_completado(99)
	_check(recibidos.size() == 1, "completado no se re-emite en el mismo nivel")
	motor.cargar_nivel(NIVEL_PILOTO)
	motor.emitir_completado(10)
	_check(recibidos == [40, 10], "recargar nivel rearma completado")
	motor.queue_free()
	await process_frame


## B1 (auditoria UX): el nivel queda guardado ANTES de la fiesta; cerrar la app durante la
## celebracion no pierde nada. Se usa un doble de prueba para no tocar el guardado real.
func _probar_guardado_antes_de_celebrar() -> void:
	print("-- guardado antes de celebrar (B1) --")
	var doble := GDScript.new()
	doble.source_code = "extends \"res://scripts/base/minijuego_base.gd\"\nvar registros: Array = []\nfunc _registrar_progreso(d: int, e: int) -> void:\n\tregistros.append([d, e])\n"
	doble.reload()
	var motor := Node2D.new()
	motor.set_script(doble)
	motor.ruta_nivel = NIVEL_PILOTO
	motor.planeta_id = "arcoiris"
	motor.id_perfil = "sofia"
	motor.segundos_auto_continuar = 1.0
	get_root().add_child(motor)
	await process_frame
	motor.celebrar(55, 2)
	await process_frame
	_check(motor.registros == [[55, 2]], "progreso registrado apenas empieza la celebracion (registros=%s)" % str(motor.registros))
	await _esperar(2.0)
	_check(motor.registros.size() == 1, "no se registra dos veces al terminar")
	motor.queue_free()
	await process_frame


## M4: estrellitas solo en nivel Estrella jugado por Sofia; nunca huecos vacios para los menores.
func _probar_estrellitas_por_perfil() -> void:
	print("-- estrellitas por perfil (M4) --")
	var motor := Node2D.new()
	motor.set_script(load("res://scripts/base/minijuego_base.gd"))
	motor.nivel = {"perfil": "estrella"}
	motor.id_perfil = "sofia"
	_check(motor._estrellitas_visibles(2) == 2, "Sofia en nivel Estrella ve sus 2 estrellitas")
	_check(motor._estrellitas_visibles(9) == 3, "estrellitas se limitan a 3")
	motor.id_perfil = "maxi"
	_check(motor._estrellitas_visibles(2) == 0, "Maxi en nivel Estrella no ve huecos de estrella")
	motor.id_perfil = "sofia"
	motor.nivel = {"perfil": "brote"}
	_check(motor._estrellitas_visibles(2) == 0, "nivel Brote no muestra estrellitas")
	motor.segundos_auto_continuar = 0.0
	_check(motor._segundos_auto_continuar_con_voz("voces/no_existe.ogg") == 0.0, "auto-continuar 0 se respeta con voz")
	motor.segundos_auto_continuar = 8.0
	_check(motor._segundos_auto_continuar_con_voz("voces/no_existe.ogg") == 8.0, "voz sin grabar no altera auto-continuar")
	motor.free()
