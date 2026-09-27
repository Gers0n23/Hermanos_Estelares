extends SceneTree

## Arnés QA del viaje estelar en modo arcade (pedido del PO 27-Sep-2026: disparar a
## meteoritos y basura, moverse adelante/atrás y poder "morir" tras varios choques).
## Verifica, para cada perfil (semilla/brote/estrella):
## - la nave se mueve adelante y atrás (eje x), con dedo y con teclado;
## - dispara (Maxi solo; Nicole/Sofía mientras el dedo está apoyado) y los rayitos rompen
##   rocas según los golpes de su perfil; la roca grande se parte en dos (brote/estrella);
## - escuadrilla completa rota => premio de 3 destellos; si una se escapa, no hay premio;
## - poder de triple disparo (3 rayitos) y corazón que recupera vida;
## - Maxi nunca pierde (sin corazones); Nicole 5 y Sofía 3 corazones; sin corazones la
##   nave se desarma, se rearma y sigue desde el último punto de control con esos destellos;
##   desde la 2.ª avería suma un corazón extra;
## - el meteorito gigante aparece al final, aguanta sus golpes y suelta 6 destellos;
## - el viaje completo (despegue -> aterrizaje) sigue emitiendo `completado(destellos)`.
## El bucle se avanza a mano (`_process` con delta fijo) para que sea determinista.
##
## Uso: godot --headless --path . --script herramientas/qa_test_viaje_arcade.gd

const VIAJE := "res://escenas/nucleo/viaje_estelar.tscn"
const DT := 1.0 / 60.0

var _fallos := 0
var _oks := 0


func _initialize() -> void:
	print("=== QA viaje estelar arcade ===")
	await process_frame  # con el árbol ya andando, add_child corre `_ready` al instante
	for perfil in ["semilla", "brote", "estrella"]:
		print("-- perfil %s" % perfil)
		_probar_movimiento(perfil)
		_probar_disparo(perfil)
		_probar_romper_roca(perfil)
		_probar_escuadrilla(perfil)
		_probar_premios(perfil)
		_probar_vidas(perfil)
		_probar_jefe(perfil)
		await _probar_viaje_completo(perfil)
	print("=== RESULTADO: %s (%d OK, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


## Viaje ya en el espacio, con el bucle detenido para avanzarlo a mano.
func _viaje(perfil: String, duracion := 0.0) -> Node2D:
	var v: Node2D = (load(VIAJE) as PackedScene).instantiate()
	v.perfil_dificultad = perfil
	v.planeta_origen = "tierra"
	v.planeta_destino = "arcoiris"
	get_root().add_child(v)
	v.set_process(false)
	v.set_process_unhandled_input(false)
	if duracion > 0.0:
		v._cfg["duracion"] = duracion
	v._elevacion = v.ELEVACION_MAX
	v._nave = Vector2(80, 100)
	v._objetivo = v._nave
	v._cambiar_fase("viaje")
	# sin aparición al azar: cada prueba pone lo que necesita
	for campo in ["_proximo_obstaculo", "_proximo_destello", "_proxima_hilera", "_proxima_lluvia",
			"_proxima_escuadrilla", "_proximo_poder", "_proximo_corazon"]:
		v.set(campo, 9999.0)
	return v


func _avanzar(v: Node2D, segundos: float) -> void:
	for i in int(round(segundos / DT)):
		v._process(DT)


func _cerrar(v: Node2D) -> void:
	v.queue_free()


func _probar_movimiento(perfil: String) -> void:
	var v := _viaje(perfil)
	v._objetivo = Vector2(220, 100)
	_avanzar(v, 2.0)
	_check(v._nave.x > 200.0, "%s: la nave avanza hacia adelante (x=%.0f)" % [perfil, v._nave.x])
	v._objetivo = Vector2(30, 60)
	_avanzar(v, 2.0)
	_check(v._nave.x < 45.0 and v._nave.y < 70.0, "%s: la nave retrocede y sube (%s)" % [perfil, v._nave])
	v._objetivo = Vector2(999, -50)
	_avanzar(v, 3.0)
	_check(v._nave.x <= v.X_MAX and v._nave.y >= v.TECHO + 8, "%s: la nave no sale de la pantalla ni tapa la barra" % perfil)
	_cerrar(v)


func _probar_disparo(perfil: String) -> void:
	var v := _viaje(perfil)
	v._tocando = false
	_avanzar(v, 0.5)
	var auto: bool = v._cfg["disparo_auto"]
	if auto:
		_check(v._balas.size() > 0, "%s: dispara solo, sin tocar" % perfil)
	else:
		_check(v._balas.is_empty(), "%s: sin dedo apoyado no dispara" % perfil)
		v._tocando = true
		_avanzar(v, 0.5)
		_check(v._balas.size() >= 2, "%s: con el dedo apoyado dispara (%d rayitos)" % [perfil, v._balas.size()])
		v._tocando = false
	_cerrar(v)


func _probar_romper_roca(perfil: String) -> void:
	var v := _viaje(perfil)
	v._tocando = true
	var roca: Dictionary = v._nuevo_obstaculo("roca", Vector2(170, 103), Vector2.ZERO, 7.0)
	v._obstaculos.append(roca)
	var golpes: int = v._cfg["golpes"]["roca"]
	_check(roca["vida"] == golpes, "%s: la roca aguanta %d rayito(s)" % [perfil, golpes])
	_avanzar(v, 1.5)
	_check(not v._obstaculos.has(roca), "%s: los rayitos rompen la roca" % perfil)
	var chicas: int = v._obstaculos.filter(func(o): return o["tipo"] == "roca_chica").size()
	if v._cfg["se_parten"]:
		_check(chicas == 2 or v._obstaculos.is_empty(), "%s: la roca grande se parte en dos chicas (%d)" % [perfil, chicas])
	else:
		_check(chicas == 0, "%s: la roca no se parte (Maxi)" % perfil)
	_cerrar(v)


func _probar_escuadrilla(perfil: String) -> void:
	var v := _viaje(perfil)
	v._lanzar_escuadrilla()
	var integrantes: Array = v._obstaculos.duplicate()
	_check(integrantes.size() == 5 and integrantes.all(func(o): return o["ruta"] == "onda"), "%s: escuadrilla de 5 en onda" % perfil)
	var antes: int = v._destellos.size()
	for o in integrantes:
		while v._obstaculos.has(o):
			v._impactar(o, o["pos"])
	var soltados: int = v._destellos.size() - antes
	_check(soltados >= 3, "%s: romper la fila completa suelta el premio (%d destellos)" % [perfil, soltados])
	# una que se escapa: esa escuadrilla ya no da premio
	v._destellos.clear()
	v._lanzar_escuadrilla()
	var otra: Array = v._obstaculos.duplicate()
	var escapada: Dictionary = otra[0]
	escapada["pos"] = Vector2(-100, 100)
	v._mover_obstaculos(0.0, 0.0)
	_check(not v._escuadrillas.has(escapada["esc"]), "%s: si una se escapa, la escuadrilla pierde el premio" % perfil)
	_cerrar(v)


func _probar_premios(perfil: String) -> void:
	var v := _viaje(perfil)
	v._recoger(v._nuevo_premio("poder", v._centro_nave()))
	_check(v._triple > 0.0, "%s: la burbuja de poder activa el triple disparo" % perfil)
	v._balas.clear()
	v._cadencia = 0.0
	v._tocando = true
	v._disparar(DT)
	_check(v._balas.size() == 3, "%s: triple disparo = 3 rayitos por tiro" % perfil)
	var antes: int = v._recogidos
	v._recoger(v._nuevo_premio("destello", v._centro_nave()))
	_check(v._recogidos == antes + 1, "%s: el destello suma 1" % perfil)
	if v._vidas_max > 0:
		v._vidas = 1
		v._recoger(v._nuevo_premio("corazon", v._centro_nave()))
		_check(v._vidas == 2, "%s: el corazón devuelve una vida" % perfil)
		v._vidas = v._vidas_max
		v._recoger(v._nuevo_premio("corazon", v._centro_nave()))
		_check(v._vidas == v._vidas_max, "%s: el corazón no pasa del máximo" % perfil)
	_cerrar(v)


## Choque real: una roca justo sobre la nave, un paso del bucle de obstáculos.
func _chocar(v: Node2D) -> void:
	v._invulnerable = 0.0
	v._giro = 0.0
	v._obstaculos.append(v._nuevo_obstaculo("roca", v._centro_nave(), Vector2.ZERO, 7.0))
	v._mover_obstaculos(0.0, 0.0)


func _probar_vidas(perfil: String) -> void:
	var v := _viaje(perfil, 30.0)
	var vidas: int = v._cfg["vidas"]
	if vidas == 0:
		for i in 12:
			_chocar(v)
		_check(v._fase == "viaje" and v._vidas_max == 0, "%s: Maxi choca 12 veces y nunca se desarma" % perfil)
		_cerrar(v)
		return
	_check(v._vidas == vidas, "%s: empieza con %d corazones" % [perfil, vidas])
	# pasa el primer punto de control con 4 destellos
	v._recogidos = 4
	v._recorrido = 10.5
	v._revisar_punto_control()
	_check(is_equal_approx(v._control, 10.0) and v._recogidos_control == 4, "%s: banderita del primer tercio guardada" % perfil)
	v._recorrido = 18.0
	v._recogidos = 9
	for i in vidas - 1:
		_chocar(v)
	_check(v._fase == "viaje" and v._vidas == 1, "%s: tras %d choques queda 1 corazón" % [perfil, vidas - 1])
	_chocar(v)
	_check(v._fase == "averia", "%s: sin corazones la nave se desarma" % perfil)
	_check(v._piezas.size() > 10, "%s: pedacitos de la nave flotando (%d)" % [perfil, v._piezas.size()])
	_avanzar(v, v.AVERIA + v.REPARACION + 0.1)
	_check(v._fase == "viaje", "%s: Cometa rearma la nave y el viaje sigue" % perfil)
	_check(absf(v._recorrido - 10.0) < 0.2, "%s: vuelve al punto de control (%.2f s)" % [perfil, v._recorrido])
	_check(v._recogidos == 4, "%s: con los destellos del punto de control (%d)" % [perfil, v._recogidos])
	_check(v._vidas == vidas and v._invulnerable > 0.0, "%s: corazones llenos y protegido al volver" % perfil)
	# segunda avería: ayuda escondida
	for i in vidas:
		_chocar(v)
	_avanzar(v, v.AVERIA + v.REPARACION + 0.1)
	_check(v._vidas_max == vidas + 1 and v._vidas == vidas + 1, "%s: desde la 2.ª avería, un corazón extra" % perfil)
	_cerrar(v)


func _probar_jefe(perfil: String) -> void:
	var v := _viaje(perfil, 30.0)
	v._recorrido = 30.0 - v.JEFE_ANTES + 0.5
	v._proximo_obstaculo = 9999.0
	v._generar(DT)
	var jefe = v._jefe_vivo()
	_check(jefe != null, "%s: aparece el meteorito gigante al final" % perfil)
	if jefe == null:
		_cerrar(v)
		return
	var golpes: int = v._cfg["jefe_golpes"]
	_check(jefe["vida"] == golpes, "%s: el gigante aguanta %d rayitos" % [perfil, golpes])
	var antes: int = v._destellos.size()
	for i in golpes - 1:
		v._impactar(jefe, jefe["pos"])
	_check(v._obstaculos.has(jefe), "%s: con un rayito menos sigue entero" % perfil)
	v._impactar(jefe, jefe["pos"])
	_check(not v._obstaculos.has(jefe) and v._destellos.size() - antes == 6, "%s: se rompe y suelta 6 destellos" % perfil)
	v._generar(DT)
	_check(v._jefe_vivo() == null, "%s: no vuelve a aparecer en el mismo tramo" % perfil)
	_cerrar(v)


func _probar_viaje_completo(perfil: String) -> void:
	var v: Node2D = (load(VIAJE) as PackedScene).instantiate()
	v.perfil_dificultad = perfil
	v.planeta_origen = "tierra"
	v.planeta_destino = "animalia"
	get_root().add_child(v)
	v.set_process(false)
	v._cfg["duracion"] = 20.0
	var emitido := [-1]
	v.completado.connect(func(n): emitido[0] = n)
	v._tocando = true
	var t := 0.0
	while emitido[0] < 0 and t < 60.0:
		# el dedo va siguiendo una onda, como jugaría un niño
		if v._fase == "viaje":
			v._objetivo = Vector2(60 + 50 * sin(t * 0.7), 100 + 45 * sin(t * 1.3))
		v._process(DT)
		t += DT
	_check(emitido[0] >= 0, "%s: el viaje completo termina y emite completado(%d) a los %.0f s" % [perfil, emitido[0], t])
	v.queue_free()
	await process_frame
