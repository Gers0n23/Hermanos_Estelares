class_name TorreLanzar
extends Node2D

## La torre de una etapa y su fisica (motor-lanzar.md §6 y §25.5-§25.7). Excepcion de fisica del GDD §8 (PO,
## 13-Oct-2026), SOLO para este motor:
## - La torre duerme congelada (FREEZE_MODE_STATIC) entre tiros y solo despierta por un golpe (y lo que se apoya
##   en lo despertado); se vuelve a dormir sola y, desde el retiro del ultimo globo, el asentamiento dura <= 3,5 s.
## - Toda la logica corre en `_physics_process` de este nodo, en un orden fijo, y los contactos de la fisica se
##   encolan y se procesan al cuadro siguiente: mismas poses + mismo tiro = mismo resultado (§6.3).
## - El botado se mide en vivo (§6.5) para que el motor detecte el derribo en el cuadro exacto (§6.6).
## No sabe nada de turnos, perfiles ni agarre: eso es del motor.

signal bloque_botado(bloque: BloqueLanzar)
signal bloque_roto(bloque: BloqueLanzar)
signal globo_retirado(globo: GloboLanzar)
signal primer_impacto(globo: GloboLanzar, punto: Vector2)
signal impacto_guiado(globo: GloboLanzar, objetivo: BloqueLanzar)
signal golpe_directo(globo: GloboLanzar)
signal confeti_exploto(punto: Vector2)
signal rebote_resorte(bloque: BloqueLanzar)
signal tiro_terminado()

const DT := 1.0 / 60.0

var mundo: Dictionary = {}
var materiales: Dictionary = {}
var retiro: Dictionary = {}
var explosion_cfg: Dictionary = {}
var gravedad := 980.0
var bloques: Dictionary = {}           # id -> BloqueLanzar (incluye el trono)
var orden_ids: Array[String] = []      # orden de creacion (determinismo)
var trono: BloqueLanzar
var globos: Array[GloboLanzar] = []
var columna_trono: Array = []
var tiro_activo := false
var rastro: PackedVector2Array = PackedVector2Array()
var cadena_tiro := 0
var cuadro := 0
var area_coleccionauta: Area2D
var zona_juego := Rect2(0, 110, 1280, 490)

var _contactos: Array = []
var _explosiones: Array = []           # [{pos, cuadro}]
var _ultima_explosion := -1000
var _t_asentamiento := 0.0
var _cuadro_rastro := 0
var _suelo: StaticBody2D
var _plataforma: StaticBody2D
var _plataforma_rect := Rect2()


# ---------------------------------------------------------------------------
# Armado
# ---------------------------------------------------------------------------

## Arma la torre de una etapa (`etapa.torre` del JSON) congelada en la pose exacta del JSON.
func armar(torre: Dictionary, nivel: Dictionary) -> void:
	desarmar()
	mundo = nivel.get("mundo", {})
	materiales = nivel.get("materiales", {})
	retiro = nivel.get("retiro_globos", {})
	explosion_cfg = materiales.get("confeti", {}).get("explosion", {})
	gravedad = float(mundo.get("gravedad_px_s2", 980))
	var zj: Array = mundo.get("zona_juego", [0, 110, 1280, 490])
	zona_juego = Rect2(float(zj[0]), float(zj[1]), float(zj[2]), float(zj[3]))
	var space := get_world_2d().space
	PhysicsServer2D.space_set_param(space, PhysicsServer2D.SPACE_PARAM_SOLVER_ITERATIONS, int(mundo.get("iteraciones_solver", 24)))
	PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY, gravedad)
	PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2.DOWN)
	var suelo_y := float(mundo.get("suelo_y", 584))
	_suelo = _cuerpo_estatico("suelo", Rect2(-2000, suelo_y, 5280, 200))
	var plat: Array = torre.get("plataforma", {}).get("rect", [990, 584, 380, 36])
	_plataforma_rect = Rect2(float(plat[0]) - float(plat[2]) / 2.0, float(plat[1]) - float(plat[3]), float(plat[2]), float(plat[3]))
	_plataforma = _cuerpo_estatico("plataforma", _plataforma_rect)
	var lista: Array = torre.get("bloques", []).duplicate()
	var datos_trono: Dictionary = torre.get("trono", {})
	for datos in lista:
		_crear_bloque(datos, false)
	if not datos_trono.is_empty():
		trono = _crear_bloque(datos_trono, true)
	# Grafo de apoyos (§6.2.3): quien se apoya en quien, con las poses del JSON.
	var todos := lista.duplicate()
	if not datos_trono.is_empty():
		todos.append(datos_trono)
	var desp: Dictionary = mundo.get("despertar", {})
	var grafo := LogicaAgarre.apoyos(todos, torre.get("plataforma", {}), float(desp.get("apoyo_tolerancia_px", 3)), float(desp.get("apoyo_superposicion", 0.2)))
	for id in grafo:
		for abajo in grafo[id]:
			if bloques.has(abajo):
				(bloques[abajo] as BloqueLanzar).apoyados.append(id)
	columna_trono = LogicaAgarre.apoyos_del_trono(torre)
	area_coleccionauta = Area2D.new()
	area_coleccionauta.name = "area_coleccionauta"
	area_coleccionauta.collision_layer = 0
	area_coleccionauta.collision_mask = BloqueLanzar.CAPA_GLOBOS
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = float(nivel.get("coleccionauta", {}).get("radio_golpe_px", 56))
	forma.shape = circulo
	area_coleccionauta.add_child(forma)
	add_child(area_coleccionauta)
	area_coleccionauta.body_entered.connect(func(cuerpo: Node) -> void:
		if cuerpo is GloboLanzar and not (cuerpo as GloboLanzar).retirado:
			golpe_directo.emit(cuerpo))
	if trono != null:
		area_coleccionauta.position = trono.position + Vector2(0, -60)
	queue_redraw()


func desarmar() -> void:
	for hijo in get_children():
		remove_child(hijo)
		hijo.free()
	bloques.clear()
	orden_ids.clear()
	globos.clear()
	trono = null
	_contactos.clear()
	_explosiones.clear()
	tiro_activo = false
	columna_trono = []


func _cuerpo_estatico(nombre: String, rect: Rect2) -> StaticBody2D:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = nombre
	cuerpo.collision_layer = BloqueLanzar.CAPA_MUNDO
	cuerpo.collision_mask = 0
	cuerpo.position = rect.get_center()
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.0
	cuerpo.physics_material_override = pm
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	forma.shape = r
	cuerpo.add_child(forma)
	add_child(cuerpo)
	return cuerpo


func _crear_bloque(datos: Dictionary, es_trono: bool) -> BloqueLanzar:
	var b := BloqueLanzar.new()
	var mat: Dictionary = materiales.get(str(datos.get("material", "carton")), {})
	b.preparar(datos, mat)
	b.es_trono = es_trono
	add_child(b)
	bloques[b.id_bloque] = b
	orden_ids.append(b.id_bloque)
	b.body_entered.connect(_al_contacto_bloque.bind(b))
	return b


func bloque(id: String) -> BloqueLanzar:
	return bloques.get(id, null)


func plataforma_rect() -> Rect2:
	return _plataforma_rect


## Bloques en el orden del JSON (sin el trono).
func lista_bloques() -> Array[BloqueLanzar]:
	var lista: Array[BloqueLanzar] = []
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		if not b.es_trono:
			lista.append(b)
	return lista


# ---------------------------------------------------------------------------
# Globos
# ---------------------------------------------------------------------------

func lanzar(tipo: String, color: String, datos: Dictionary, desde: Vector2, velocidad: Vector2) -> GloboLanzar:
	var g := _crear_globo(tipo, color, datos)
	g.position = desde
	g.linear_velocity = velocidad
	g.v_prev = velocidad
	_empezar_tiro()
	return g


## Tiro guiado (Maxi, gigante): vuela sin colision hasta `objetivo` y ahi lo rompe (rotura forzada, §6.5).
func lanzar_guiado(tipo: String, color: String, datos: Dictionary, desde: Vector2, objetivo: BloqueLanzar, duracion: float) -> GloboLanzar:
	var g := _crear_globo(tipo, color, datos)
	g.set_meta("objetivo", objetivo.id_bloque)
	g.guiar(desde, objetivo.global_position, duracion)
	_empezar_tiro()
	return g


func _crear_globo(tipo: String, color: String, datos: Dictionary) -> GloboLanzar:
	var g := GloboLanzar.new()
	var vidas: Dictionary = retiro.get("vida_tras_contacto_cuadros", {})
	g.preparar(tipo, color, datos, int(vidas.get(tipo, vidas.get("normal", 110))))
	add_child(g)
	globos.append(g)
	g.body_entered.connect(_al_contacto_globo.bind(g))
	return g


func _empezar_tiro() -> void:
	if tiro_activo:
		return
	tiro_activo = true
	cadena_tiro = 0
	_t_asentamiento = 0.0
	rastro = PackedVector2Array()
	_cuadro_rastro = 0


## Triple (§5.5): un toque en vuelo lo divide en 3 en abanico de ±7°.
func dividir(g: GloboLanzar, division: Dictionary) -> void:
	if g.retirado or g.dividido or g.guiado:
		return
	g.dividido = true
	var abanico := deg_to_rad(float(division.get("abanico_grados", 7)))
	var datos := {"radio_px": float(division.get("radio_cada_uno_px", 18)), "masa": float(division.get("masa_cada_uno", 0.5)),
		"rebote": g.rebote, "multiplicador_dano": g.multiplicador}
	var cantidad := int(division.get("cantidad", 3))
	for k in cantidad:
		var ang := (float(k) - float(cantidad - 1) / 2.0) * abanico
		var mini := _crear_globo("triple_mini", g.color_globo, datos)
		mini.position = g.position
		mini.linear_velocity = g.linear_velocity.rotated(ang)
		mini.v_prev = mini.linear_velocity
		mini.principal = k == cantidad / 2
		mini.cuadros = g.cuadros
	_retirar(g, false)


func globos_vivos() -> int:
	var n := 0
	for g in globos:
		if not g.retirado:
			n += 1
	return n


# ---------------------------------------------------------------------------
# Contactos (se encolan; se procesan en el cuadro siguiente, en orden fijo)
# ---------------------------------------------------------------------------

func _al_contacto_globo(cuerpo: Node, g: GloboLanzar) -> void:
	if g.retirado or g.guiado:
		return
	_contactos.append({"tipo": "globo", "g": g, "c": cuerpo, "va": g.v_prev, "vd": g.linear_velocity, "p": g.global_position})


func _al_contacto_bloque(cuerpo: Node, b: BloqueLanzar) -> void:
	if not cuerpo is BloqueLanzar or b.freeze or not b.activo():
		return
	_contactos.append({"tipo": "bloque", "a": b, "c": cuerpo, "va": b.v_prev, "vd": b.linear_velocity})


func _procesar_contactos() -> void:
	var lista := _contactos
	_contactos = []
	var impulso_min := float(mundo.get("despertar", {}).get("impulso_min", 40))
	for c in lista:
		if c["tipo"] == "globo":
			var g: GloboLanzar = c["g"]
			if not is_instance_valid(g) or g.retirado:
				continue
			var cuerpo: Node = c["c"]
			if not is_instance_valid(cuerpo):
				continue
			if g.cuadros_contacto < 0:
				# Tocar el suelo cuenta como golpe (§25.7): arranca el reloj de retiro.
				g.cuadros_contacto = 0
				g.primer_contacto_suelo = not cuerpo is BloqueLanzar
				primer_impacto.emit(g, c["p"])
			if not cuerpo is BloqueLanzar:
				continue
			var b := cuerpo as BloqueLanzar
			if not b.activo():
				continue
			g.golpeo_bloque = true
			var va: Vector2 = c["va"]
			var vd: Vector2 = c["vd"]
			b.agregar_mancha(c["p"], g.color_globo)
			if b.material_bloque == "resorte":
				_rebotar_en_resorte(g, b, va)
				if b.freeze and g.mass * va.length() >= impulso_min:
					_despertar_con_apoyados(b)
				continue
			if g.tipo == "pesado" and b.material_bloque in g.atraviesa and g.atraviesa_restante > 0:
				g.atraviesa_restante -= 1
				romper(b)
				g.linear_velocity = va * g.velocidad_tras_atravesar
				continue
			var impulso := g.mass * (va - vd).length()
			var dano := mini(3, int(floor(impulso / maxf(1.0, b.impulso_por_punto)))) * g.multiplicador
			if not b.irrompible and dano > 0:
				b.salud -= int(dano)
				if b.salud <= 0:
					romper(b)
					continue
			if b.freeze and impulso >= impulso_min:
				_despertar_con_apoyados(b)
				b.linear_velocity += va * (g.mass / (g.mass + b.mass)) * 1.2
				b.angular_velocity += clampf((c["p"] - b.global_position).cross(va) * 0.00002 * g.mass, -3.0, 3.0)
		else:
			var a: BloqueLanzar = c["a"]
			var otro: Node = c["c"]
			if not is_instance_valid(a) or not is_instance_valid(otro) or not otro is BloqueLanzar:
				continue
			var b2 := otro as BloqueLanzar
			if not b2.activo():
				continue
			var imp := a.mass * ((c["va"] as Vector2) - (c["vd"] as Vector2)).length()
			if b2.material_bloque == "confeti" and bool(explosion_cfg.get("rompe_por_bloque", true)) and imp >= b2.impulso_por_punto:
				romper(b2)
				continue
			if b2.freeze and imp >= impulso_min:
				_despertar_con_apoyados(b2)


## Trampolin (§25.5.2): rebote 1,1 (manda el mayor), a mano porque el motor de fisica no admite > 1.
func _rebotar_en_resorte(g: GloboLanzar, b: BloqueLanzar, va: Vector2) -> void:
	var normal := Vector2.UP.rotated(b.global_rotation)
	if (g.global_position - b.global_position).dot(normal) < 0.0:
		normal = -normal
	var rebote := maxf(1.1, g.rebote)
	var vmax := 1300.0
	if va.dot(normal) < 0.0:
		g.linear_velocity = va.bounce(normal) * rebote
		g.linear_velocity = g.linear_velocity.limit_length(vmax)
	b.squash = 0.6
	var tw := b.create_tween()
	tw.tween_property(b, "squash", 1.0, 0.15)
	rebote_resorte.emit(b)


func _despertar_con_apoyados(b: BloqueLanzar) -> void:
	var pendientes: Array = [b.id_bloque]
	var vistos := {}
	while not pendientes.is_empty():
		var id := str(pendientes.pop_front())
		if vistos.has(id):
			continue
		vistos[id] = true
		var x: BloqueLanzar = bloques.get(id, null)
		if x == null or not x.activo():
			continue
		x.despertar()
		if bool(mundo.get("despertar", {}).get("por_apoyo", true)):
			pendientes.append_array(x.apoyados)


func romper(b: BloqueLanzar) -> void:
	if b == null or not b.activo() or b.irrompible:
		return
	b.romper()
	_marcar_botado(b)
	bloque_roto.emit(b)
	# Lo que se apoyaba en el se despierta (si no, quedaria flotando).
	for id in b.apoyados:
		var x: BloqueLanzar = bloques.get(id, null)
		if x != null:
			_despertar_con_apoyados(x)
	if b.material_bloque == "confeti":
		_encolar_explosion(b.global_position)


func _marcar_botado(b: BloqueLanzar) -> void:
	if b.botado:
		return
	b.botado = true
	bloque_botado.emit(b)


# ---------------------------------------------------------------------------
# Confeti (§25.5.1)
# ---------------------------------------------------------------------------

func _encolar_explosion(punto: Vector2) -> void:
	if cadena_tiro >= int(explosion_cfg.get("cadena_max", 3)):
		return
	cadena_tiro += 1
	var retardo := int(round(float(explosion_cfg.get("retardo_cadena_s", 0.1)) / DT))
	var cuando := maxi(cuadro, _ultima_explosion + retardo)
	_ultima_explosion = cuando
	_explosiones.append({"pos": punto, "cuadro": cuando})


func _explotar(punto: Vector2) -> void:
	var radio := float(explosion_cfg.get("radio_px", 150))
	var v_borde := float(explosion_cfg.get("v_borde_px_s", 90))
	var v_centro := float(explosion_cfg.get("v_centro_px_s", 510))
	var v_arriba := float(explosion_cfg.get("v_arriba_px_s", 60))
	var empuja_trono := bool(explosion_cfg.get("empuja_trono", false))
	var inmunes: Array = explosion_cfg.get("inmunes", [])
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		if not b.activo() or (b.es_trono and not empuja_trono):
			continue
		if "apoyos_trono" in inmunes and id in columna_trono:
			continue
		var d := b.global_position.distance_to(punto)
		if d >= radio:
			continue
		_despertar_con_apoyados(b)
		var dir := (b.global_position - punto).normalized() if d > 0.01 else Vector2.UP
		b.linear_velocity += dir * (v_borde + (v_centro - v_borde) * (1.0 - d / radio)) + Vector2(0, -v_arriba)
	for g in globos:
		if g.retirado or g.guiado:
			continue
		var dg := g.global_position.distance_to(punto)
		if dg < radio:
			var dirg := (g.global_position - punto).normalized() if dg > 0.01 else Vector2.UP
			g.linear_velocity += dirg * (v_borde + (v_centro - v_borde) * (1.0 - dg / radio)) + Vector2(0, -v_arriba)
	confeti_exploto.emit(punto)


# ---------------------------------------------------------------------------
# El paso fijo
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	cuadro += 1
	_procesar_contactos()
	# Explosiones vencidas (en orden).
	var restantes: Array = []
	for e in _explosiones:
		if int(e["cuadro"]) <= cuadro:
			_explotar(e["pos"])
		else:
			restantes.append(e)
	_explosiones = restantes
	_avanzar_globos(delta)
	_avanzar_bloques(delta)
	if tiro_activo:
		if globos_vivos() == 0:
			_t_asentamiento += delta
			if _t_asentamiento >= float(mundo.get("asentamiento_max_s", 3.5)):
				_congelar_bloques()
		if globos_vivos() == 0 and _explosiones.is_empty() and _contactos.is_empty() and todo_dormido():
			tiro_activo = false
			tiro_terminado.emit()


func _avanzar_globos(delta: float) -> void:
	var fuera_x: Array = retiro.get("fuera_x", [-60, 1340])
	var fuera_y := float(retiro.get("fuera_abajo_y", 720))
	var vida_max := int(retiro.get("vida_max_cuadros", 420))
	for g: GloboLanzar in globos.duplicate():
		if g.retirado:
			continue
		if g.guiado:
			g.guia_t += delta
			g.position = g.punto_guiado(g.guia_t)
			g.estela.append(g.position)
			if g.principal and _cuadro_rastro % 4 == 0:
				rastro.append(g.position)
			_cuadro_rastro += 1
			if g.guia_t >= g.guia_dur:
				var objetivo: BloqueLanzar = bloques.get(str(g.get_meta("objetivo", "")), null)
				if objetivo != null and objetivo.activo():
					romper(objetivo)
				if g.retirado or not tiro_activo:
					continue
				g.soltar_a_fisica()
				g.cuadros_contacto = 0
				g.golpeo_bloque = true
				primer_impacto.emit(g, g.global_position)
				impacto_guiado.emit(g, objetivo)
			continue
		g.cuadros += 1
		if g.cuadros_contacto >= 0:
			g.cuadros_contacto += 1
		if g.principal and _cuadro_rastro % 4 == 0:
			rastro.append(g.position)
		_cuadro_rastro += 1
		var p := g.global_position
		if p.x < float(fuera_x[0]) or p.x > float(fuera_x[1]) or p.y > fuera_y:
			_retirar(g, true)
		elif g.cuadros_contacto >= g.vida_contacto or g.cuadros >= vida_max:
			_retirar(g, true)
		else:
			g.v_prev = g.linear_velocity


func _retirar(g: GloboLanzar, avisar: bool) -> void:
	if g.retirado:
		return
	g.retirado = true
	g.collision_layer = 0
	g.collision_mask = 0
	g.freeze = true
	g.hide()
	if avisar:
		globo_retirado.emit(g)
	g.queue_free()
	globos.erase(g)


func _avanzar_bloques(delta: float) -> void:
	var reposo: Dictionary = mundo.get("reposo", {})
	var v_min := float(reposo.get("v_px_s", 8))
	var w_min := float(reposo.get("w_rad_s", 0.1))
	var durante := float(reposo.get("durante_s", 0.4))
	var derribo: Dictionary = mundo.get("derribo", {})
	var desp := float(derribo.get("desplazamiento_px", 40))
	var giro := deg_to_rad(float(derribo.get("giro_grados", 35)))
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		if not b.activo():
			continue
		if not b.freeze:
			if b.linear_velocity.length() < v_min and absf(b.angular_velocity) < w_min:
				b.quieto_t += delta
				if b.quieto_t >= durante:
					b.congelar()
			else:
				b.quieto_t = 0.0
			b.v_prev = b.linear_velocity
		# El botado se mide en vivo solo durante el tiro (las coreografias mueven piezas congeladas).
		if not b.botado and tiro_activo:
			var movido := b.position.distance_to(b.pose_original.origin) >= desp
			var girado := absf(angle_difference(b.rotation, b.pose_original.get_rotation())) >= giro
			var afuera := not zona_juego.grow(40).has_point(b.position)
			if movido or girado or afuera:
				_marcar_botado(b)


func todo_dormido() -> bool:
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		if b.activo() and not b.freeze:
			return false
	return true


func _congelar_bloques() -> void:
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		if b.activo() and not b.freeze:
			b.congelar()


## Derribo (§6.6): congela TODO en este cuadro (bloques y globos) y descarta lo encolado.
func congelar_todo() -> void:
	_congelar_bloques()
	for g in globos:
		if not g.retirado:
			g.linear_velocity = Vector2.ZERO
			g.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			g.freeze = true
			g.guiado = false
	_contactos.clear()
	_explosiones.clear()
	tiro_activo = false


## Saca los globos que quedaron (p. ej. congelados en el derribo) sin avisar.
func limpiar_globos() -> void:
	for g: GloboLanzar in globos.duplicate():
		_retirar(g, false)


# ---------------------------------------------------------------------------
# Estado (parcial §12, derribo §13.2)
# ---------------------------------------------------------------------------

## Solo lo que cambio respecto del JSON: {id: {estado, pos, rot, salud, manchas}}.
func estado_bloques() -> Dictionary:
	var r := {}
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		var cambio := b.estado != "en_pie" or b.salud != b.resistencia or not b.manchas.is_empty() \
			or b.transform != b.pose_original or b.botado
		if not cambio:
			continue
		var e := {"estado": b.estado}
		if b.estado != "roto":
			e["pos"] = [snappedf(b.position.x, 0.01), snappedf(b.position.y, 0.01)]
			e["rot"] = snappedf(b.rotation, 0.0001)
		if b.salud != b.resistencia:
			e["salud"] = b.salud
		if b.botado and b.estado == "en_pie":
			e["botado"] = true
		if not b.manchas.is_empty():
			var ms: Array = []
			for m in b.manchas:
				ms.append({"pos": [snappedf(m["pos"].x, 0.1), snappedf(m["pos"].y, 0.1)], "color": m["color"]})
			e["manchas"] = ms
		r[id] = e
	return r


func aplicar_estado_bloques(estado: Dictionary) -> void:
	for id in estado:
		var b: BloqueLanzar = bloques.get(str(id), null)
		if b == null:
			continue
		var e: Dictionary = estado[id]
		var est := str(e.get("estado", "en_pie"))
		if e.has("pos"):
			var p: Array = e["pos"]
			b.transform = Transform2D(float(e.get("rot", 0.0)), Vector2(float(p[0]), float(p[1])))
		b.congelar()
		if e.has("salud"):
			b.salud = int(e["salud"])
		b.manchas = []
		for m in e.get("manchas", []):
			var mp: Array = m.get("pos", [0, 0])
			b.manchas.append({"pos": Vector2(float(mp[0]), float(mp[1])), "color": str(m.get("color", "rojo"))})
		match est:
			"roto":
				b.romper()
				b.botado = true
			"suelo":
				b.pasar_a_suelo()
				b.botado = true
			_:
				b.botado = bool(e.get("botado", false))
		b.queue_redraw()


## Poses de todos los bloques (para la coreografia y el arnes de determinismo).
func poses() -> Dictionary:
	var r := {}
	for id in orden_ids:
		var b: BloqueLanzar = bloques[id]
		r[id] = {"pos": b.position, "rot": b.rotation, "estado": b.estado}
	return r


# ---------------------------------------------------------------------------
# Guia (§5.4): la misma integracion semi-implicita del motor de fisica, con el circulo del globo
# ---------------------------------------------------------------------------

## Puntos cada `cada_s` hasta el primer choque (o `max_t`). {puntos, impacto (INF si no choca), cuerpo}.
func predecir(desde: Vector2, velocidad: Vector2, radio: float, max_t: float = 3.0, cada_s: float = 0.06) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	q.shape = circulo
	q.collision_mask = BloqueLanzar.CAPA_MUNDO | BloqueLanzar.CAPA_BLOQUES
	var puntos := PackedVector2Array()
	var p := desde
	var v := velocidad
	var t := 0.0
	var proximo := 0.0
	var impacto := Vector2.INF
	var cuerpo: Object = null
	while t < max_t:
		if t >= proximo:
			puntos.append(p)
			proximo += cada_s
		v += Vector2(0, gravedad) * DT
		var mov := v * DT
		q.transform = Transform2D(0.0, p)
		q.motion = mov
		var r := space.cast_motion(q)
		if r.size() >= 2 and r[0] < 1.0:
			impacto = p + mov * r[0]
			q.transform = Transform2D(0.0, impacto + mov.normalized() * 1.5)
			q.motion = Vector2.ZERO
			var choques := space.intersect_shape(q, 1)
			if not choques.is_empty():
				cuerpo = choques[0].get("collider")
			break
		p += mov
		t += DT
		if p.y > 760.0 or p.x > 1400.0 or p.x < -100.0:
			break
	return {"puntos": puntos, "impacto": impacto, "cuerpo": cuerpo}
