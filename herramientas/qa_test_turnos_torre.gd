extends SceneTree

## Arnes de desarrollo de HE-76 (extensiones de turnos del nucleo para la Torre; motor-lanzar.md §8, §12, §13.2
## y §25; modo-equipo.md §11.4). Todo con el guardado de pruebas (aislado) y un motor FALSO generico: el nucleo
## no conoce la Torre, asi que el arnes tampoco la necesita.
## 1. GestorTurnos en modo sin pista (`rival: null` + `confirmar_turno: true`): puerta y pase como siempre, sin
##    rival, retroceso, resbalon ni guirnalda; `posicion_boca_rival()` = INF.
## 2. `terminar_turno_sin_recursos(siguiente)` -> paso 0/2 -> `rival_llego` con `siguiente` al centro.
## 3. `reiniciar_rival(forzar_id)`: reinicia el ciclo desde ese hermano; 13 tiros por intento = M7 N3 S3 y el
##    ultimo es de Maxi; tambien corta un turno activo (inicio de etapa).
## 4. minijuego_base: derrota sin pista hacia `ancla_rival_motor()` con la voz de `variante_derrota()`, parcial en
##    turno_cerrado, al terminar el gag y a demanda (etapa), revancha sin parcial, momentos saltables.
## 5. Progreso: `etapa` en el parcial de la batalla (R17 = A), nunca vuelve a una etapa menor, y revanchas.
## Uso: godot --headless --path . --script herramientas/qa_test_turnos_torre.gd

const RUTA_NIVEL := "user://qa_torre_nivel_falso.json"
const PERFILES := {"maxi": "semilla", "nicole": "brote", "sofia": "estrella"}
const ANCLA_FALSA := Vector2(990, 200)

const FUENTE_MOTOR := """
extends MinijuegoBase

var destino_aspirar := Vector2.ZERO
var voces: Array = []
var etapa := 1
var saltados: Array = []

func _ready() -> void:
	super._ready()
	if turnos != null:
		var capa := CanvasLayer.new()
		add_child(capa)
		var perfiles := {}
		for id in equipo:
			perfiles[id] = perfil_de(id)
		turnos.escala_tiempo = 0.02
		turnos.configurar(equipo, nivel.get("equipo", {}), perfiles, capa)

func ancla_rival_motor() -> Vector2:
	return Vector2(990, 200)

func variante_derrota() -> String:
	return "chicle"

func gag_derrota_aspirar(destino: Vector2) -> float:
	destino_aspirar = destino
	return 0.05

func gag_derrota_devolver(_perfil: String) -> float:
	return 0.05

func reproducir_voz(ruta: String) -> void:
	voces.append(ruta)

func obtener_parcial_equipo() -> Dictionary:
	return {"etapa": etapa, "globos_restantes": 9}

func saltar_momento(id_animacion: String) -> void:
	saltados.append(id_animacion)
	terminar_momento_saltable(id_animacion)
"""

var _fallos := 0
var _oks := 0
var _progreso: Node
var _eventos: Array = []
var _respaldo := ""


func _initialize() -> void:
	print("=== QA dev HE-76: extensiones de turnos para la Torre (nucleo generico) ===")
	_progreso = get_root().get_node_or_null("Progreso")
	if _progreso == null or _progreso.ruta_guardado != _progreso.RUTA_GUARDADO_PRUEBAS:
		print("ABORTA: Progreso no apunta al guardado de pruebas")
		quit(1)
		return
	if FileAccess.file_exists(_progreso.ruta_guardado):
		_respaldo = FileAccess.get_file_as_string(_progreso.ruta_guardado)
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	await process_frame
	await _probar_sin_pista()
	await _probar_sin_recursos()
	await _probar_reinicio_ciclo()
	await _probar_base()
	_probar_progreso()
	# Restaura el guardado de pruebas tal como estaba.
	if _respaldo != "":
		var f := FileAccess.open(_progreso.ruta_guardado, FileAccess.WRITE)
		f.store_string(_respaldo)
		f.close()
	_progreso.cargar()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_NIVEL))
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar_que(condicion: Callable, maximo := 6.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < maximo * 1000.0:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _ids(lista: Array) -> Array[String]:
	var r: Array[String] = []
	for x in lista:
		r.append(str(x))
	return r


func _config_torre(extra := {}) -> Dictionary:
	var config := {"orden": "maxi_intercalado", "puerta_tras_semilla": "arrastre", "bloqueo_tras_puerta_ms": 400,
		"maxi_mueve_rival": false, "racha_retrocede_rival": 3, "semilla_auto_s": 20, "pasos_rival": 5,
		"rival": null, "confirmar_turno": true}
	config.merge(extra, true)
	return config


func _crear_gestor(ids: Array, config: Dictionary) -> GestorTurnos:
	var motor := Node2D.new()
	get_root().add_child(motor)
	var capa := CanvasLayer.new()
	motor.add_child(capa)
	var gestor := GestorTurnos.new()
	gestor.escala_tiempo = 0.02
	motor.add_child(gestor)
	var perfiles := {}
	for id in ids:
		perfiles[id] = PERFILES[id]
	gestor.configurar(_ids(ids), config, perfiles, capa)
	_eventos.clear()
	gestor.rival_movido.connect(func(p: int) -> void: _eventos.append("movido:%d" % p))
	gestor.rival_resbalo.connect(func() -> void: _eventos.append("resbalo"))
	gestor.rival_llego.connect(func() -> void: _eventos.append("llego"))
	gestor.tope_alcanzado.connect(func() -> void: _eventos.append("tope"))
	gestor.turno_iniciado.connect(func(id: String, _p: String) -> void: _eventos.append("turno:" + id))
	gestor.turno_cerrado.connect(func(id: String, perfecto: bool) -> void: _eventos.append("cerrado:%s:%s" % [id, perfecto]))
	return gestor


func _abrir_y_esperar_turno(g: GestorTurnos, id: String) -> bool:
	if not await _esperar_que(func() -> bool: return g.en_puerta()):
		return false
	g.abrir_puerta()
	return await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada() and g.hermano_actual() == id)


# ---------------------------------------------------------------------------
# 1. Modo sin pista
# ---------------------------------------------------------------------------

func _probar_sin_pista() -> void:
	print("-- 1. GestorTurnos sin pista --")
	var con := _crear_gestor(["maxi", "nicole", "sofia"], _config_torre({"rival": {}}))
	_check(not con.sin_pista(), "con rival (no null) el modo es el de siempre")
	con.get_parent().queue_free()
	var epilogo := _crear_gestor(["maxi", "nicole"], _config_torre({"confirmar_turno": false}))
	_check(not epilogo.sin_pista(), "rival null + confirmar_turno false (epilogo) NO es el modo sin pista")
	epilogo.get_parent().queue_free()

	var g := _crear_gestor(["maxi", "nicole", "sofia"], _config_torre({"aciertos_max_turno": {"brote": 2}}))
	_check(g.sin_pista(), "rival null + confirmar_turno true -> sin_pista()")
	_check(g.posicion_boca_rival() == Vector2.INF, "sin pista: posicion_boca_rival() = INF")
	_check(g.pista.sin_pista, "la pista solo dibuja a Cometa (sin galletas ni rival)")
	g.empezar()
	_check(await _abrir_y_esperar_turno(g, "maxi"), "empieza Maxi tras su puerta")
	g.terminar_turno(false)
	_check(await _abrir_y_esperar_turno(g, "nicole"), "pase y puerta como siempre: le toca a Nicole")
	_check(g._puerta_arrastre, "tras Maxi la puerta sigue siendo de arrastre (B1.2)")
	_check(not g.meta.visible, "sin guirnalda aunque el perfil tenga tope")
	g.notificar_acierto()
	_check(not ("tope" in _eventos), "1 acierto de 2: sin tope")
	g.notificar_acierto()
	_check("tope" in _eventos and g.entrada_bloqueada(), "el tope sigue cerrando el turno")
	g.confirmar_turno_estable()
	_check("cerrado:nicole:false" in _eventos, "sin pista no hay turno perfecto (perfecto = false)")
	_check(await _abrir_y_esperar_turno(g, "maxi"), "despues de Nicole vuelve Maxi")
	g.terminar_turno(false)
	_check(await _abrir_y_esperar_turno(g, "sofia"), "le toca a Sofia")
	for k in 6:
		g.notificar_acierto()
	g.terminar_turno(false)
	_check(await _abrir_y_esperar_turno(g, "maxi"), "despues de Sofia, Maxi")
	var nada_del_rival := true
	for e in _eventos:
		if str(e).begins_with("movido") or e == "resbalo" or e == "llego":
			nada_del_rival = false
	_check(nada_del_rival and g.pasos_usados() == 0, "sin pista: ni rival_movido, ni resbalon, ni rival_llego en el pase (ni con racha)")
	g.get_parent().queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 2. terminar_turno_sin_recursos
# ---------------------------------------------------------------------------

func _probar_sin_recursos() -> void:
	print("-- 2. terminar_turno_sin_recursos --")
	var g := _crear_gestor(["maxi", "nicole", "sofia"], _config_torre())
	g.empezar()
	await _abrir_y_esperar_turno(g, "maxi")
	_eventos.clear()
	g.terminar_turno_sin_recursos("maxi")
	_check(g.entrada_bloqueada() and not g.turno_activo(), "bloquea la entrada en el acto")
	_check("cerrado:maxi:false" in _eventos, "emite turno_cerrado (el parcial se guarda ahi)")
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos), "termina en rival_llego (el equipo perdio el intento)")
	_check(g.hermano_actual() == "maxi" and g.barra.en_centro() == "maxi", "el siguiente (Maxi, el mismo) queda al centro")
	_check(not g.en_puerta() and g.entrada_bloqueada(), "sin puerta: la derrota la orquesta la base")
	g.terminar_turno(false)
	g.notificar_acierto()
	_check(_eventos.count("llego") == 1, "detenido: terminar_turno y notificar_acierto no hacen nada")
	g.reiniciar_rival("maxi")
	_check(await _abrir_y_esperar_turno(g, "maxi"), "reiniciar_rival('maxi') abre la puerta de Maxi")
	g.terminar_turno(false)
	_check(await _abrir_y_esperar_turno(g, "nicole"), "y el ciclo sigue desde Maxi: Nicole")
	_eventos.clear()
	g.terminar_turno_sin_recursos("maxi")
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos), "sin recursos en el turno de Nicole -> rival_llego")
	_check(g.hermano_actual() == "maxi" and g.barra.en_centro() == "maxi", "siguiente_id fija quien queda al centro (Maxi)")
	g.reiniciar_rival()
	_check(await _abrir_y_esperar_turno(g, "maxi"), "reiniciar_rival() sin id abre al del centro")
	g.get_parent().queue_free()

	# Sin siguiente_id: el siguiente del orden.
	var g2 := _crear_gestor(["maxi", "nicole", "sofia"], _config_torre())
	g2.empezar()
	await _abrir_y_esperar_turno(g2, "maxi")
	g2.terminar_turno_sin_recursos()
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos) and g2.hermano_actual() == "nicole", "sin siguiente_id queda al centro el siguiente del orden")
	g2.get_parent().queue_free()

	# Tambien con pista (generico): llega sin mover al rival.
	var g3 := _crear_gestor(["maxi", "nicole"], _config_torre({"rival": {}}))
	g3.empezar()
	await _abrir_y_esperar_turno(g3, "maxi")
	g3.terminar_turno(false)
	await _abrir_y_esperar_turno(g3, "nicole")
	_eventos.clear()
	g3.terminar_turno_sin_recursos()
	_check(await _esperar_que(func() -> bool: return "llego" in _eventos) and g3.pasos_usados() == 0, "con pista tambien sirve: rival_llego sin mover al rival")
	g3.get_parent().queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 3. Reinicio del ciclo por intento / etapa (13 globos = M7 N3 S3)
# ---------------------------------------------------------------------------

func _probar_reinicio_ciclo() -> void:
	print("-- 3. reiniciar_rival(forzar_id): cada intento empieza y termina con Maxi --")
	var g := _crear_gestor(["maxi", "nicole", "sofia"], _config_torre())
	g.empezar()
	for intento in 2:
		var globos := 13 if intento == 0 else 17
		var cuenta := {"maxi": 0, "nicole": 0, "sofia": 0}
		var ultimo := ""
		for tiro in globos:
			var ok := await _esperar_que(func() -> bool: return g.en_puerta())
			if not ok:
				break
			g.abrir_puerta()
			await _esperar_que(func() -> bool: return g.turno_activo() and not g.entrada_bloqueada())
			ultimo = g.hermano_actual()
			cuenta[ultimo] += 1
			if tiro < globos - 1:
				g.terminar_turno(false)
			else:
				_eventos.clear()
				g.terminar_turno_sin_recursos("maxi")
		var esperado := {"maxi": 7, "nicole": 3, "sofia": 3} if globos == 13 else {"maxi": 9, "nicole": 4, "sofia": 4}
		_check(cuenta == esperado, "%d globos: %s (esperado %s)" % [globos, cuenta, esperado])
		_check(ultimo == "maxi", "%d globos: el ultimo tiro es de Maxi" % globos)
		await _esperar_que(func() -> bool: return "llego" in _eventos)
		g.reiniciar_rival("maxi")
	# Inicio de etapa con un turno activo de otra hermana: corta el turno y abre la puerta de Maxi.
	await _abrir_y_esperar_turno(g, "maxi")
	g.terminar_turno(false)
	_check(await _abrir_y_esperar_turno(g, "nicole"), "turno de Nicole en curso")
	g.reiniciar_rival("maxi")
	_check(not g.turno_activo() and g.entrada_bloqueada(), "reiniciar_rival corta el turno activo y bloquea la entrada")
	_check(g.barra.en_centro() == "maxi", "Maxi vuela al centro")
	_check(await _abrir_y_esperar_turno(g, "maxi"), "nueva etapa: la puerta es de Maxi")
	g.terminar_turno(false)
	_check(await _abrir_y_esperar_turno(g, "nicole"), "y el orden sigue desde Maxi (Nicole)")
	g.get_parent().queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4. minijuego_base con un motor falso
# ---------------------------------------------------------------------------

func _escribir_nivel(extra_equipo := {}) -> void:
	var equipo := _config_torre(extra_equipo)
	var nivel := {"id_nivel": "nivel_falso_torre", "perfil": "brote", "modo_juego": "equipo", "equipo": equipo,
		"lineas_voz": {"derrota_gag_equipo": {"chicle": ["voces/falsa/chicle_1.ogg", "PENDIENTE", "voces/falsa/chicle_3.ogg"],
			"baile": ["voces/falsa/baile_1.ogg"]}, "nos_alcanzo": "voces/falsa/nos_alcanzo.ogg"}}
	var f := FileAccess.open(RUTA_NIVEL, FileAccess.WRITE)
	f.store_string(JSON.stringify(nivel))
	f.close()


func _crear_motor_falso(revancha := false) -> MinijuegoBase:
	var script := GDScript.new()
	script.source_code = FUENTE_MOTOR
	script.reload()
	var motor: MinijuegoBase = script.new()
	motor.ruta_nivel = RUTA_NIVEL
	motor.equipo = _ids(["maxi", "nicole", "sofia"])
	motor.revancha = revancha
	get_root().add_child(motor)
	return motor


func _probar_base() -> void:
	print("-- 4. minijuego_base: derrota sin pista, parcial, revancha y momentos saltables --")
	_escribir_nivel()
	var base := MinijuegoBase.new()
	_check(base.ancla_rival_motor() == Vector2(640, 360), "ancla_rival_motor() vacia = centro de la pantalla")
	_check(base.variante_derrota() == "", "variante_derrota() vacia = \"\" (lineas en Array, como Parejas)")
	_check(not base.revancha, "revancha = false por defecto")
	base.free()

	var motor := _crear_motor_falso()
	_check(motor.turnos != null and motor.turnos.sin_pista(), "el motor falso arma el gestor en modo sin pista")
	var parciales: Array = []
	motor.parcial_equipo_listo.connect(func(e: Dictionary) -> void: parciales.append(e.duplicate()))
	motor.turnos.empezar()
	await _abrir_y_esperar_turno(motor.turnos, "maxi")
	motor.turnos.terminar_turno(false)
	_check(parciales.size() == 1 and int(parciales[0].get("etapa", 0)) == 1, "turno_cerrado -> parcial con la etapa del motor")
	motor.etapa = 2
	motor.notificar_parcial_equipo()
	_check(parciales.size() == 2 and int(parciales[1]["etapa"]) == 2, "notificar_parcial_equipo(): parcial a demanda (inicio de etapa)")
	await _abrir_y_esperar_turno(motor.turnos, "nicole")
	motor.voces.clear()
	motor.turnos.terminar_turno_sin_recursos("maxi")
	_check(await _esperar_que(func() -> bool: return motor.en_derrota_equipo()), "sin recursos -> la base orquesta la derrota-gag")
	_check(await _esperar_que(func() -> bool: return motor._gag_terminado), "el gag termina")
	_check(motor.destino_aspirar == ANCLA_FALSA, "aspira hacia ancla_rival_motor() (%s)" % motor.destino_aspirar)
	_check(parciales.size() == 4, "parcial al cerrar el turno y otro al terminar el gag (%d)" % parciales.size())
	var dijo_chicle: bool = motor.voces.size() >= 1 and str(motor.voces[0]).ends_with("chicle_1.ogg")
	_check(dijo_chicle, "la voz del gag sale de derrota_gag_equipo[variante_derrota()]")
	_check(not ("PENDIENTE" in motor.voces), "\"PENDIENTE\" se trata como clave ausente (nunca se reproduce)")
	await _esperar_que(func() -> bool: return motor.voces.size() >= 3, 3.0)
	_check(str(motor.voces[-1]).ends_with("nos_alcanzo.ogg") or "voces/falsa/chicle_3.ogg" in motor.voces, "siguen las voces en plural y el logro comun")
	motor.tocar_otra_vez_equipo()
	_check(await _abrir_y_esperar_turno(motor.turnos, "maxi"), "\"¡otra vez!\" -> reiniciar_rival() y la puerta de Maxi")
	_check(motor._boton_otra_vez_equipo != null and motor._boton_otra_vez_equipo.size.x >= 160.0, "el boton \"¡otra vez!\" mide >= 160 px")

	# "¡Otra vez!" a mitad del gag: igual queda el parcial del intento nuevo.
	motor.turnos.terminar_turno_sin_recursos("maxi")
	await _esperar_que(func() -> bool: return motor.en_derrota_equipo())
	var antes := parciales.size()
	motor.tocar_otra_vez_equipo()
	_check(parciales.size() == antes + 1, "\"¡otra vez!\" antes de que termine el gag tambien deja el parcial")
	await _abrir_y_esperar_turno(motor.turnos, "maxi")

	# Momentos saltables.
	var iniciados: Array = []
	var terminados: Array = []
	motor.momento_saltable_iniciado.connect(func(id: String) -> void: iniciados.append(id))
	motor.momento_saltable_terminado.connect(func(id: String) -> void: terminados.append(id))
	motor.iniciar_momento_saltable("caida_etapa")
	motor.iniciar_momento_saltable("caida_etapa")
	_check(iniciados == ["caida_etapa"] and motor.momento_saltable_en_curso("caida_etapa"), "momento_saltable_iniciado una sola vez por momento")
	motor.saltar_momento("caida_etapa")
	_check(motor.saltados == ["caida_etapa"] and terminados == ["caida_etapa"], "saltar_momento deja el estado final y emite terminado")
	motor.terminar_momento_saltable("caida_etapa")
	_check(terminados.size() == 1 and not motor.momento_saltable_en_curso(), "terminado no se repite")
	motor.queue_free()
	await process_frame

	# Revancha: sin parcial.
	var rev := _crear_motor_falso(true)
	var parciales_rev: Array = []
	rev.parcial_equipo_listo.connect(func(e: Dictionary) -> void: parciales_rev.append(e))
	rev.turnos.empezar()
	await _abrir_y_esperar_turno(rev.turnos, "maxi")
	rev.turnos.terminar_turno(false)
	rev.notificar_parcial_equipo()
	_check(parciales_rev.is_empty(), "en revancha nunca se emite el parcial")
	rev.queue_free()

	# Solitario: notificar_parcial_equipo no hace nada y no hay gestor.
	var solo := _crear_motor_falso()
	solo.queue_free()
	var script := GDScript.new()
	script.source_code = FUENTE_MOTOR
	script.reload()
	var suelto: MinijuegoBase = script.new()
	suelto.ruta_nivel = RUTA_NIVEL
	get_root().add_child(suelto)
	var p_suelto: Array = []
	suelto.parcial_equipo_listo.connect(func(e: Dictionary) -> void: p_suelto.append(e))
	suelto.notificar_parcial_equipo()
	_check(suelto.turnos == null and p_suelto.is_empty(), "en solitario: sin gestor y sin parcial")
	suelto.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. Progreso: etapa en el parcial y revanchas
# ---------------------------------------------------------------------------

func _probar_progreso() -> void:
	print("-- 5. Progreso: etapa en el parcial (R17 = A) y revanchas --")
	var b := "arcoiris_batalla_final"
	_check(_progreso.guardar_parcial_batalla(b, "torre", {"etapa": 2, "etapas_ganadas": ["e1"]}), "guarda el parcial de la etapa 2")
	_check(_progreso.obtener_etapa_parcial_batalla(b, "torre") == 2, "obtener_etapa_parcial_batalla = 2")
	_check(int(_progreso.obtener_parcial_batalla(b)["etapa"]) == 2, "parcial.etapa queda junto a ronda y estado")
	_check(not _progreso.guardar_parcial_batalla(b, "torre", {"etapa": 1}), "un parcial de la etapa 1 (ya ganada) se rechaza")
	_check(_progreso.obtener_etapa_parcial_batalla(b, "torre") == 2, "y el guardado sigue en la etapa 2")
	_check(_progreso.guardar_parcial_batalla(b, "torre", {"etapa": 2, "intento": 2}), "otro intento de la misma etapa se guarda")
	_check(_progreso.guardar_parcial_batalla(b, "torre", {"etapa": 3}), "la etapa 3 se guarda")
	_progreso.cargar()
	_check(_progreso.obtener_etapa_parcial_batalla(b, "torre") == 3, "la etapa sobrevive a recargar el archivo (JSON)")
	_check(_progreso.obtener_etapa_parcial_batalla(b, "parejas") == 0, "otra ronda: etapa 0")
	_progreso.borrar_parcial_batalla(b)
	_check(_progreso.obtener_etapa_parcial_batalla(b, "torre") == 0, "sin parcial: etapa 0")
	_check(_progreso.guardar_parcial_batalla(b, "parejas", {"pares": ["a"]}), "rondas sin etapas: igual que antes")
	_check(int(_progreso.obtener_parcial_batalla(b)["etapa"]) == 0, "sin etapa en el estado, parcial.etapa = 0")
	_check(_progreso.guardar_parcial_batalla(b, "torre", {"etapa": 1}), "ronda nueva: la etapa 1 se guarda aunque antes hubiera otra ronda")
	_progreso.borrar_parcial_batalla(b)
	# Guardado viejo sin parcial.etapa: se lee del estado.
	_progreso._batalla(b)["parcial"] = {"ronda": "torre", "estado": {"etapa": 2.0}}
	_check(_progreso.obtener_etapa_parcial_batalla(b, "torre") == 2, "guardado sin parcial.etapa: la lee del estado")
	_progreso.borrar_parcial_batalla(b)

	_check(_progreso.obtener_revancha_batalla(b, "torre") == {"estrellitas": 0, "record": -1}, "revancha sin jugar: 0 estrellitas, sin record")
	var r1: Dictionary = _progreso.registrar_revancha_batalla(b, "torre", 2, 30)
	_check(r1["estrellitas_nuevas"] and r1["record_nuevo"] and r1["primer_record"], "1.a revancha: estrellitas y primer record")
	var r2: Dictionary = _progreso.registrar_revancha_batalla(b, "torre", 1, 34)
	_check(not r2["estrellitas_nuevas"] and not r2["record_nuevo"], "peor revancha no baja nada")
	var r3: Dictionary = _progreso.registrar_revancha_batalla(b, "torre", 3, -1)
	_check(r3["estrellitas_nuevas"] and not r3["record_nuevo"], "con ayudas (record -1): suben estrellitas, el record no se toca")
	_check(_progreso.obtener_revancha_batalla(b, "torre") == {"estrellitas": 3, "record": 30}, "queda 3 estrellitas y record 30")
	var r4: Dictionary = _progreso.registrar_revancha_batalla(b, "torre", 3, 28)
	_check(r4["record_nuevo"] and not r4["primer_record"] and int(_progreso.obtener_revancha_batalla(b, "torre")["record"]) == 28, "menos globos es record nuevo")
	_check(not _progreso.batalla_ganada(b), "la revancha no toca la batalla ni sus parciales")
