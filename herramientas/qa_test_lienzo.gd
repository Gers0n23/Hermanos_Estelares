extends SceneTree

## Arnes QA de "Pinta con Coco" v2 (motor lienzo_libre, ficha motor-lienzo-libre.md §9 y
## lienzo-escenas-retos.md): juega los 15 niveles (5 zonas x 3 rutas) y el epilogo de la batalla en
## solitario. Por nivel verifica: hojas, voces existentes, tamanos tactiles (dock, popups, tarjetas de
## objetivos, "mostrar a Coco"), popups (uno a la vez, se cierran al elegir o al tocar el lienzo), que
## los objetivos BLOQUEAN la hoja hasta cumplirse y la DESBLOQUEAN al final, la pista fantasma, el PNG
## de cada hoja y `completado(destellos)`.
##
## Las escenas piloto (parque de dinos, granja de ponys, ciudad de los ponys) se juegan de verdad:
## stickers con clase, caminos pegados a lugares, viajeros que llegan (eventos reales), combinaciones,
## corral (encerrar), circuito, orden, pintar zona, zoom con lupa y dos dedos que no pintan.
##
## Los dibujos van a user://qa_dibujos y se borran al final. NO toca progreso.json (el motor no usa
## el autoload Progreso sin `planeta_id`); igual, corre con el juego cerrado.
##
## Uso: godot --headless --path . --script herramientas/qa_test_lienzo.gd [-- <filtro>] [-- -v]

const MOTOR := "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn"
const Laminas := preload("res://scripts/motores/lienzo_libre/laminas.gd")
const Colores := preload("res://scripts/motores/lienzo_libre/colores_lienzo.gd")
const Stickers := preload("res://scripts/motores/lienzo_libre/stickers.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const CARPETA_QA := "user://qa_dibujos"
const EQUIPO := "res://datos/niveles/arcoiris/batalla/pinta_mochila_equipo.json"

var _fallos := 0
var _ok := 0
var _detalle := false


func _initialize() -> void:
	print("=== QA lienzo_libre v2: Pinta con Coco, 5 zonas x Maxi, Nicole y Sofia + epilogo ===")
	var filtro := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "-v":
			_detalle = true
		else:
			filtro = arg
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/pinta_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			await _probar_nivel(ruta, HERMANOS[perfil])
	if filtro == "" or EQUIPO.contains(filtro):
		await _probar_nivel(EQUIPO, "maxi")
	await _probar_fisica_suelta()
	await _probar_mezclas()
	_borrar(CARPETA_QA)
	Engine.time_scale = 1.0
	print("=== RESULTADO: %s (%d ok, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _ok, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_ok += 1
		if _detalle:
			print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


## Espera (con el tiempo del juego acelerado) hasta que se cumpla `condicion` o pasen `tope` s reales.
func _esperar_que(condicion: Callable, tope := 8.0) -> bool:
	Engine.time_scale = 6.0
	var t0 := Time.get_ticks_msec()
	while not condicion.call() and Time.get_ticks_msec() - t0 < tope * 1000.0:
		await process_frame
	Engine.time_scale = 1.0
	return condicion.call()


func _existe_voz(ruta: String) -> bool:
	return ResourceLoader.exists("res://assets/audio/" + ruta)


func _probar_nivel(ruta: String, hermano: String) -> void:
	print("-- %s (%s) --" % [ruta.trim_prefix("res://datos/niveles/arcoiris/"), hermano])
	_check(FileAccess.file_exists(ruta), "existe el nivel")
	var motor: Node = load(MOTOR).instantiate()
	if not motor is MinijuegoBase:
		_check(false, "el motor carga su script (revisa errores de parseo arriba)")
		return
	motor.ruta_nivel = ruta
	motor.id_perfil = hermano
	motor.segundos_auto_continuar = 0.4
	motor.carpeta_dibujos = CARPETA_QA
	var resultado := {"destellos": -1}
	motor.completado.connect(func(d: int) -> void: resultado["destellos"] = d)
	var mostradas: Array = []
	motor.hoja_mostrada.connect(func(_i: int, png: String) -> void: mostradas.append(png))
	get_root().add_child(motor)
	await _esperar(0.4)

	var nivel: Dictionary = motor.nivel
	var perfil := str(nivel.get("perfil", "semilla"))
	_check(str(nivel.get("motor", "")) == "lienzo_libre", "motor lienzo_libre, encargo %s" % nivel.get("encargo", "?"))
	_check(not nivel.has("retos") and not JSON.stringify(nivel).contains("\"retos\""), "sin `retos` v1 (los reemplazan los objetivos)")
	var hojas: int = motor._hojas.size()
	_check(hojas >= 1, "%d hojas en la partida" % hojas)
	_revisar_voces(nivel)

	for h in hojas:
		while motor._indice_hoja != h and is_instance_valid(motor):
			await process_frame
		await _esperar(0.3)
		if motor.eligiendo_tema:
			motor.elegir_tema(0)
			await _esperar(0.3)
		var hoja: Dictionary = motor._hojas[h]
		var lamina: Dictionary = hoja["lamina"]
		var encargo: String = motor._encargo
		print("   hoja %d/%d: %s · %s · %d objetivos" % [h + 1, hojas, encargo, lamina.get("id", "papel"), motor._objetivos.size()])
		if motor.lienzo.stickers_objeto:
			_check(motor.inspiracion_abierta(), "la inspiracion se abre grande al empezar (Coco la narra)")
		_revisar_tactil(motor, perfil)
		_revisar_objetivos_ui(motor, perfil, hoja)
		await _revisar_popups(motor, perfil)
		_check(motor.lienzo.size == Vector2(1280, 720) and motor.lienzo.position == Vector2.ZERO, "lienzo a pantalla completa (1280x720)")
		# Bloqueo: con objetivos pendientes no hay "mostrar a Coco".
		_check(not motor.boton_mostrar.visible and motor.mostrar_a_coco() == "" and motor._indice_hoja == h,
			"objetivos pendientes BLOQUEAN la hoja (sin boton y mostrar_a_coco no pasa)")
		await _revisar_pista(motor)
		var lienzo = motor.lienzo
		if lienzo.stickers_objeto:
			await _jugar_escena(motor, perfil, str(hoja["tema"].get("id", "")))
		elif not lienzo.mosaico.is_empty():
			await _jugar_mosaico(motor)
		elif encargo == "mezcla_paleta":
			await _jugar_mezcla(motor)
		elif encargo in ["espejo", "mandala"]:
			await _cubrir_guia(motor)
		elif encargo == "dedo_magico":
			_trazo(lienzo, Vector2(640, 40), Vector2(660, 690), 30)
		elif not lienzo.lamina.is_empty() and not lienzo.regiones_rellenables().is_empty():
			if lamina.has("trajes"):
				await _jugar_trajes(motor, lamina)
			await _jugar_zonas(motor, encargo == "coco_pide")
		else:
			_jugar_trazo(motor)
		motor._revisar_objetivos()
		await _esperar(0.3)
		var pendientes: Array = []
		for o: Dictionary in motor._objetivos:
			if not o["hecho"]:
				pendientes.append("%s %d/%d" % [o["datos"].get("tipo", "?"), o["actual"], o["meta"]])
		_check(pendientes.is_empty(), "todos los objetivos cumplidos%s" % ("" if pendientes.is_empty() else " — faltan: %s" % str(pendientes)))
		if not lienzo.stickers_objeto:
			await _probar_deshacer_simple(motor)
		await _esperar_que(func() -> bool: return motor.boton_mostrar.visible, 4.0)
		_check(motor.boton_mostrar.visible, "objetivos cumplidos DESBLOQUEAN la hoja: aparece 'mostrar a Coco'")
		var png: String = motor.mostrar_a_coco()
		_revisar_png(png)
		if str(hoja["cfg"].get("guardar_como", "")) != "":
			_check(FileAccess.file_exists("%s/%s/%s.png" % [CARPETA_QA, hermano, hoja["cfg"]["guardar_como"]]), "copia fija para el hangar")
	var t0 := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 25000:
		await process_frame
	_check(mostradas.size() == hojas, "%d hojas mostradas a Coco" % mostradas.size())
	_check(resultado["destellos"] > 0, "completado(destellos) = %d" % resultado["destellos"])
	motor.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# Interfaz: tactiles, dock, popups, tarjetas de objetivos, pista fantasma
# ---------------------------------------------------------------------------

func _revisar_tactil(motor, perfil: String) -> void:
	var minimo := 96.0 if perfil == "semilla" else 64.0
	var chicos: Array = []
	for entrada: Dictionary in motor._dock_botones:
		var tam: Vector2 = entrada["boton"].size
		if minf(tam.x, tam.y) < minimo:
			chicos.append("dock %s %s" % [entrada["grupo"], tam])
	if minf(motor.boton_mostrar.size.x, motor.boton_mostrar.size.y) < 96.0:
		chicos.append("mostrar %s" % motor.boton_mostrar.size)
	var sin_herramientas: bool = (motor._cfg.get("herramientas", ["x"]) as Array).is_empty() and (motor._cfg.get("paleta", ["x"]) as Array).is_empty()
	_check(chicos.is_empty() and (not motor._dock_botones.is_empty() or sin_herramientas), "dock de %d botones >= %d px%s" % [motor._dock_botones.size(), minimo, "" if chicos.is_empty() else " — chicos: %s" % str(chicos)])
	var grupos: Array = motor._grupos.keys()
	if perfil == "semilla":
		_check(not grupos.has("lupa") and not motor.lienzo.zoom_permitido and motor._dock_botones.size() <= 3, "Maxi: sin zoom y a lo mas 3 grupos (%s)" % str(grupos))
	else:
		_check(grupos.has("lupa") and motor.lienzo.zoom_permitido, "Nicole y Sofia tienen lupa")


func _revisar_objetivos_ui(motor, perfil: String, hoja: Dictionary) -> void:
	var cantidad: int = motor._objetivos.size()
	var tema: Dictionary = hoja.get("tema", {})
	if not tema.is_empty():
		var esperado: int = {"semilla": 3, "brote": 6, "estrella": 12}[perfil]
		_check(cantidad == esperado, "%d objetivos obligatorios (esperado %d)" % [cantidad, esperado])
		var tipos := {}
		for o: Dictionary in motor._objetivos:
			tipos[str(o["datos"].get("tipo", ""))] = int(tipos.get(str(o["datos"].get("tipo", "")), 0)) + 1
		var max_repetido := 0
		for t in tipos:
			max_repetido = maxi(max_repetido, int(tipos[t]))
		if perfil == "estrella":
			_check(tipos.size() >= 7 and max_repetido <= 3, "Sofia: %d tipos distintos, ninguno mas de 3 veces" % tipos.size())
	else:
		_check(cantidad >= 1 and str(motor._objetivos[0]["datos"].get("tipo", "")) == "encargo", "zonas 2-5: objetivo base `encargo`")
	var visibles: int = motor._indices_activos().size()
	var a_la_vez := 1 if perfil == "semilla" else 3
	_check(visibles == mini(a_la_vez, cantidad), "objetivos visibles a la vez: %d (Maxi 1, Nicole y Sofia 3)" % visibles)
	var sin_voz: Array = []
	var chicos: Array = []
	for o: Dictionary in motor._objetivos:
		var pendiente_equipo: bool = str(motor.nivel.get("modo_juego", "")) == "equipo"
		if not (_existe_voz(str(o["datos"].get("voz", ""))) or pendiente_equipo) or o["datos"].get("icono", "") is String and str(o["datos"].get("icono", "")) == "":
			sin_voz.append(str(o["datos"].get("tipo", "?")))
		var chip = o["chip"]
		if chip != null and minf(chip.size.x, chip.size.y) < (96.0 if perfil == "semilla" else 64.0):
			chicos.append(chip.size)
	_check(sin_voz.is_empty(), "cada objetivo tiene voz e icono%s" % ("" if sin_voz.is_empty() else " — faltan: %s" % str(sin_voz)))
	_check(chicos.is_empty(), "tarjetas de objetivo grandes%s" % ("" if chicos.is_empty() else str(chicos)))


## Popups: uno a la vez; cada boton >= minimo; elegir cierra; el velo (tocar el lienzo) cierra.
func _revisar_popups(motor, perfil: String) -> void:
	var minimo := 96.0 if perfil == "semilla" else 64.0
	var herramienta: String = motor.lienzo.herramienta
	var abiertos := 0
	for grupo in motor._grupos:
		var items: Array = motor._grupos[grupo]
		if grupo == "lupa" or (grupo != "colores" and items.size() <= 1):
			continue
		motor.abrir_popup(grupo)
		abiertos += 1
		var botones: Array = motor._popup.get_children().filter(func(b) -> bool: return b is Button)
		var chicos := botones.filter(func(b) -> bool: return minf(b.size.x, b.size.y) < minimo)
		var dentro := Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(Rect2(motor._popup.position, motor._popup.size))
		_check(motor.popup_abierto() == grupo and chicos.is_empty() and dentro, "popup '%s': %d botones >= %d px, dentro de la pantalla" % [grupo, botones.size(), minimo])
	if abiertos >= 2:
		var visibles := 0
		for hijo in motor._ui.get_children():
			if hijo == motor._popup and hijo.visible:
				visibles += 1
		_check(visibles == 1, "un solo popup abierto a la vez")
	if abiertos > 0:
		motor._velo.pressed.emit()
		_check(motor.popup_abierto() == "", "tocar fuera (el lienzo) cierra el popup")
	if motor._grupos.has("pinceles") and (motor._grupos["pinceles"] as Array).size() > 1:
		motor.abrir_popup("pinceles")
		var item := str(motor._grupos["pinceles"][1])
		motor._al_elegir_item(item)
		_check(motor.popup_abierto() == "" and motor.lienzo.herramienta == item, "elegir en el popup cierra y deja la herramienta lista (%s)" % item)
	if motor._grupos.has("colores") and motor._encargo != "mezcla_paleta":
		motor.abrir_popup("colores")
		if motor._botones_color.size() > 1:
			motor._botones_color[1]["boton"].pressed.emit()
			_check(motor.popup_abierto() == "" and motor.lienzo.color_actual.is_equal_approx(motor._entradas_color[1]["color"]), "elegir un color cierra el popup")
	motor._elegir_herramienta(herramienta, false)
	await process_frame


## Pista fantasma: sin avance, Coco muestra la pista del primer objetivo pendiente.
func _revisar_pista(motor) -> void:
	var escalera: Dictionary = motor.ESCALERA_PISTAS[motor._perfil]
	motor._sin_avance = float(escalera["mano"]) + 0.1
	motor._peldano = 2
	motor._subir_escalera()
	var objetivo: Dictionary = motor._objetivo_activo()
	var tipo := str(objetivo["datos"].get("tipo", ""))
	var con_fantasma: bool = not motor.lienzo.fantasma_activo().is_empty()
	var solo_pulso: bool = tipo in ["colores", "usar"] or (tipo == "encargo" and motor._encargo in ["coco_pide", "sellos_escena", "libre"])
	_check(motor._peldano == 3 and (con_fantasma or solo_pulso), "pista fantasma tras %ss sin avance (%s: %s)" % [escalera["mano"], tipo, motor.lienzo.fantasma_activo().get("tipo", "pulso del dock")])
	motor.lienzo.mostrar_fantasma({}, 0.0)
	motor._reiniciar_pistas()
	motor._valvula_lista = false
	await process_frame


# ---------------------------------------------------------------------------
# Escenas piloto (lienzo con tema)
# ---------------------------------------------------------------------------

func _jugar_escena(motor, perfil: String, escena: String) -> void:
	var lienzo = motor.lienzo
	_check(lienzo.lamina.get("regiones", []).size() >= 4 and Vector2(lienzo.tamano) == Vector2(1280, 720), "fondo 16:9 con %d zonas" % lienzo.lamina.get("regiones", []).size())
	motor.abrir_inspiracion()
	_check(motor.inspiracion_abierta(), "tocar la tarjeta de inspiracion la agranda")
	motor._velo.pressed.emit()
	_check(not motor.inspiracion_abierta(), "un toque la cierra")
	# Clases.
	var tema: Dictionary = motor._hojas[motor._indice_hoja]["tema"]
	var clases_ok := true
	for id in tema.get("vivos", []):
		clases_ok = clases_ok and lienzo.clase_de(str(id)) == "vivo" and Stickers.tiene(str(id))
	for id in tema.get("lugares", []):
		clases_ok = clases_ok and lienzo.clase_de(str(id)) == "lugar"
	for id in tema.get("decorados", []):
		clases_ok = clases_ok and lienzo.clase_de(str(id)) == "decorado" and Stickers.tiene(str(id))
	_check(clases_ok, "clases de stickers (vivo, lugar, decorado) y todos en el catalogo")
	await _probar_burbuja(motor)
	_check((motor._grupos.get("cosas", []) as Array).any(func(i) -> bool: return str(i).begins_with("camino_")), "los caminos estan en 'Cosas que se mueven'")
	match escena:
		"parque_dinos":
			await _escena_dinos(motor)
		"granja_ponys":
			await _escena_granja(motor)
		"ciudad_ponys":
			await _escena_ciudad(motor)
		_:
			_check(false, "escena sin guion de QA: %s" % escena)
	# Ficha §10: fisica, sol, deshacer y reiniciar (con todos los objetivos ya cumplidos: no se pierden).
	await _probar_fisica(motor, perfil, escena)
	if (tema.get("decorados", []) as Array).has("sol"):
		await _probar_sol(motor)
	await _probar_caminos_s11(motor, perfil)
	await _probar_amigos(motor, perfil)
	await _probar_jinetes(motor, perfil)
	await _probar_deshacer(motor, perfil)
	await _probar_reiniciar(motor, escena)
	if perfil != "semilla":
		await _probar_zoom(motor)
	await _probar_dos_dedos(motor)
	var imagen: Image = lienzo.componer()
	_check(imagen.get_size() == Vector2i(1280, 720), "el PNG compone a 1280x720 con stickers y caminos")


func _poner(motor, id: String, p: Vector2):
	motor._elegir_herramienta("sello_" + id, false)
	var antes: Array = motor.lienzo.stickers()
	motor.lienzo.empezar_trazo(p)
	motor.lienzo.terminar_trazo()
	# El nuevo (no el ultimo hijo: un jinete que se sube pasa al frente).
	for s in motor.lienzo.stickers():
		if not antes.has(s):
			return s
	return motor.lienzo.stickers().back()


## Arrastra un sticker hasta `destino` (como el dedo): asi se suelta un vivo sobre un lugar o un
## ingrediente sobre otro (tocar encima de un sticker lo mueve, no pone otro).
func _arrastrar(motor, sticker, destino: Vector2) -> void:
	var lienzo = motor.lienzo
	var desde: Vector2 = sticker.centro()
	lienzo.empezar_trazo(desde)
	for k in range(1, 13):
		lienzo.continuar_trazo(desde.lerp(destino, k / 12.0))
	lienzo.terminar_trazo()


func _camino(motor, tipo: String, puntos: Array) -> Dictionary:
	motor._elegir_herramienta("camino_" + tipo, false)
	var antes: int = motor.lienzo.caminos.size()
	_trazar(motor.lienzo, puntos)
	return motor.lienzo.caminos.back() if motor.lienzo.caminos.size() > antes else {}


func _cumplido(motor, indice: int) -> bool:
	motor._revisar_objetivos()
	return motor._objetivos[indice]["hecho"]


func _escena_dinos(motor) -> void:
	var lienzo = motor.lienzo
	_check(lienzo.lugar_por_id("volcan") != null and lienzo.lugar_por_id("lago") != null, "lugares de fondo: volcan y lago")
	_poner(motor, "trex", Vector2(560, 470))
	_check(not _cumplido(motor, 0), "1 T-rex no alcanza (pide 2)")
	_poner(motor, "trex", Vector2(700, 480))
	_check(_cumplido(motor, 0), "obj 1 poner: dos T-rex")
	await _esperar(1.0)
	_check(motor._indices_activos() == [1], "Maxi ve 1 objetivo a la vez: entra el siguiente")
	# Imán grande de Maxi: las puntas caen cerca (no encima) del volcan y del lago.
	var camino := _camino(motor, "sendero", [Vector2(1010, 470), Vector2(700, 600), Vector2(480, 610)])
	_check(not camino.is_empty() and camino["desde"] != null and camino["hasta"] != null, "R1: el sendero se pega al volcan y al lago")
	_check(_cumplido(motor, 1), "obj 2 conectar volcan-lago")
	var llego := {"si": false}
	lienzo.llegada.connect(func(_v, l, _d) -> void:
		if l.id == "lago":
			llego["si"] = true)
	_check(await _esperar_que(func() -> bool: return not lienzo.viajeros().is_empty(), 3.0), "R2 Semilla: un T-rex salta solo al camino")
	_check(await _esperar_que(func() -> bool: return llego["si"], 10.0), "el T-rex llega al lago (evento llegada)")
	await _esperar(1.0)
	var huevo = _poner(motor, "huevo", Vector2(1150, 660))
	_arrastrar(motor, huevo, Vector2(1020, 400))
	await process_frame
	_check(lienzo.contar_stickers("dino_bebe") == 1 and (not is_instance_valid(huevo) or huevo.is_queued_for_deletion()), "C03: el huevo junto al volcan se transforma en dino bebe")
	_check(_cumplido(motor, 2), "obj 3 combinacion dino_bebe")


func _escena_granja(motor) -> void:
	var lienzo = motor.lienzo
	var granero = lienzo.lugar_por_id("granero")
	_check(granero != null and lienzo.lugar_por_id("rio") != null, "granero ya puesto y rio de fondo (lineal)")
	_poner(motor, "pony_amigo", Vector2(520, 640))
	_poner(motor, "pony_amigo", Vector2(640, 650))
	_check(_cumplido(motor, 0), "obj 1 poner dos ponys")
	# Sendero del granero a la orilla del rio (lugar lineal: vale cualquier punto del borde).
	var camino := _camino(motor, "sendero", [granero.centro() + Vector2(40, 30), Vector2(600, 500), Vector2(960, 520)])
	_check(not camino.is_empty() and camino["desde"] == granero and camino["hasta"] != null and camino["hasta"].id == "rio", "el sendero se pega al granero y a la orilla del rio")
	_check(_cumplido(motor, 1), "obj 2 conectar granero-rio")
	# Dos ponys soltados sobre el granero salen por el sendero y llegan al rio.
	var p1 = _poner(motor, "pony_amigo", Vector2(80, 650))
	var p2 = _poner(motor, "pony_amigo", Vector2(80, 560))
	_arrastrar(motor, p1, granero.centro())
	_arrastrar(motor, p2, granero.centro() + Vector2(10, 5))
	_check(lienzo.esta_viajando(p1) and lienzo.esta_viajando(p2), "R2: un pony soltado sobre el establo se sube al sendero")
	_check(await _esperar_que(func() -> bool: return _cumplido(motor, 2), 12.0), "obj 3 llegadas: dos ponys distintos del establo al rio")
	# Combinaciones: sol + nube de lluvia en el cielo -> arcoiris; pony + manzana -> pony feliz.
	_poner(motor, "sol", Vector2(700, 140))
	_arrastrar(motor, _poner(motor, "nube_lluvia", Vector2(900, 150)), Vector2(760, 150))
	_check(lienzo.contar_stickers("arcoiris") == 1, "C01: sol + nube de lluvia en el cielo -> arcoiris animado")
	_check(_cumplido(motor, 3), "obj 4 combinacion arcoiris")
	var suelto = _poner(motor, "pony_amigo", Vector2(150, 680))
	_check(not lienzo.esta_viajando(suelto), "un pony lejos de los caminos se queda quieto")
	var manzana = _poner(motor, "manzana", Vector2(330, 690))
	_arrastrar(motor, manzana, suelto.centro() + Vector2(30, 0))
	await process_frame
	_check(lienzo.contar_stickers("manzana") == 0 and _cumplido(motor, 4), "C07: pony + manzana -> pony feliz (la manzana se consume)")
	# Corral: una cerca cerrada alrededor de dos ponys.
	var a = _poner(motor, "pony_amigo", Vector2(600, 660))
	var b = _poner(motor, "pony_amigo", Vector2(680, 660))
	var ovalo: Array = []
	for k in 25:
		ovalo.append(Vector2(640, 655) + Vector2.from_angle(-PI / 2.0 + TAU * k / 24.0) * Vector2(150, 50))
	var corral := _camino(motor, "cerca", ovalo)
	_check(not corral.is_empty() and bool(corral["cerrado"]) and not lienzo.esta_viajando(a) and not lienzo.esta_viajando(b), "R5: la cerca cerrada es un corral (sin viajeros)")
	_check(_cumplido(motor, 5), "obj 6 encerrar dos ponys con la cerca")


func _escena_ciudad(motor) -> void:
	var lienzo = motor.lienzo
	var casas: Array = []
	for x in [180, 300, 420]:
		casas.append(_poner(motor, "casa", Vector2(x, 300)))
	_check(_cumplido(motor, 0), "obj 1 poner tres casas")
	for x in [200, 330, 460]:
		_poner(motor, "pony_amigo", Vector2(x, 690))
	_check(_cumplido(motor, 1), "obj 2 poner tres ponys")
	var castillo = _poner(motor, "castillo", Vector2(980, 260))
	_camino(motor, "sendero", [casas[2].centro(), Vector2(700, 320), castillo.centro()])
	_check(_cumplido(motor, 2), "obj 3 conectar casa-castillo")
	_arrastrar(motor, _poner(motor, "pony_amigo", Vector2(560, 450)), casas[2].centro())
	_arrastrar(motor, _poner(motor, "pony_amigo", Vector2(560, 450)), casas[2].centro() + Vector2(8, 6))
	_check(await _esperar_que(func() -> bool: return _cumplido(motor, 3), 14.0), "obj 4 llegadas: dos ponys de su casa a la escuela")
	var granero = _poner(motor, "granero", Vector2(640, 420))
	_camino(motor, "sendero", [granero.centro(), Vector2(645, 470), Vector2(650, 535)])
	_check(_cumplido(motor, 4), "obj 5 conectar granero-rio (orilla)")
	_arrastrar(motor, _poner(motor, "pony_amigo", Vector2(820, 440)), granero.centro())
	_arrastrar(motor, _poner(motor, "pony_amigo", Vector2(820, 440)), granero.centro() + Vector2(6, 4))
	_check(await _esperar_que(func() -> bool: return _cumplido(motor, 5), 10.0), "obj 6 llegadas: dos ponys del establo al rio")
	# Cadena Little Alchemy: nube + nube -> nube de lluvia; + sol -> arcoiris.
	_poner(motor, "nube", Vector2(400, 120))
	_arrastrar(motor, _poner(motor, "nube", Vector2(600, 120)), Vector2(440, 125))
	_check(lienzo.contar_stickers("nube_lluvia") == 1 and lienzo.contar_stickers("nube") == 0, "C02: dos nubes -> nube de lluvia (se consumen)")
	_arrastrar(motor, _poner(motor, "sol", Vector2(700, 120)), lienzo.stickers().filter(func(s) -> bool: return s.id == "nube_lluvia")[0].centro() + Vector2(40, 0) if lienzo.contar_stickers("nube_lluvia") > 0 else Vector2(440, 120))
	_check(lienzo.contar_stickers("arcoiris") == 1, "C02 -> C01: la nube de lluvia nueva + sol -> arcoiris")
	var suelto = _poner(motor, "pony_amigo", Vector2(1150, 690))
	_arrastrar(motor, _poner(motor, "varita", Vector2(1000, 690)), Vector2(1180, 690))
	await process_frame
	_check(not is_instance_valid(suelto) or suelto.is_queued_for_deletion(), "C15: pony + varita -> el pony se transforma")
	_check(lienzo.contar_stickers("unicornio") == 1, "aparece el unicornio")
	# Circuito: un camino cerrado lejos de los lugares; el unicornio se suelta encima y da vueltas.
	var loop: Array = []
	for k in 25:
		loop.append(Vector2(1000, 470) + Vector2.from_angle(TAU * k / 24.0) * Vector2(130, 55))
	var pista := _camino(motor, "arcoiris", loop)
	_check(not pista.is_empty() and bool(pista["cerrado"]), "R5: el puente arcoiris cerrado es un circuito")
	var unicornio = lienzo.stickers().filter(func(s) -> bool: return s.id == "unicornio")[0]
	unicornio.poner_en(Vector2(1130, 470))
	lienzo.intentar_subir(unicornio)
	_check(lienzo.esta_viajando(unicornio), "el unicornio soltado en el circuito se sube")
	_check(await _esperar_que(func() -> bool: return _cumplido(motor, 9), 14.0), "obj 10 circuito: dos vueltas")
	# Pintar el rio de turquesa con el balde.
	motor._elegir_herramienta("balde", false)
	lienzo.color_actual = Colores.color("turquesa")
	lienzo.empezar_trazo(Vector2(300, 575))
	lienzo.terminar_trazo()
	_check(_cumplido(motor, 10), "obj 11 pintar_zona rio de turquesa")
	# Orden: casa -> castillo -> rio (con un sendero castillo-rio, R4 lo sigue sin parar).
	_camino(motor, "sendero", [castillo.centro(), Vector2(900, 420), Vector2(880, 540)])
	_arrastrar(motor, _poner(motor, "pony_amigo", Vector2(560, 450)), casas[2].centro())
	_check(await _esperar_que(func() -> bool: return _cumplido(motor, 11), 16.0), "obj 12 orden: casa -> castillo -> rio en un viaje")
	for i in [6, 7, 8]:
		_check(_cumplido(motor, i), "obj %d combinacion cumplido (aunque estuviera en la cola)" % (i + 1))


# ---------------------------------------------------------------------------
# Ficha §10: fisica (pesa / vuela), sol fuera del cielo, deshacer y reiniciar
# ---------------------------------------------------------------------------

## Primer punto de la lista sin stickers ni lugares encima.
func _libre(lienzo, candidatos: Array) -> Vector2:
	for p: Vector2 in candidatos:
		if lienzo.sticker_en(p) == null and lienzo.lugar_en(p, 30.0) == null:
			return p
	return candidatos[0]


func _puntos_cielo(lienzo) -> Array:
	var y: float = lienzo.cielo.position.y + 45.0
	return [Vector2(560, y), Vector2(640, y), Vector2(720, y), Vector2(480, y), Vector2(820, y), Vector2(400, y), Vector2(900, y)]


func _puntos_suelo() -> Array:
	return [Vector2(560, 690), Vector2(760, 680), Vector2(880, 690), Vector2(470, 690), Vector2(330, 690), Vector2(980, 690)]


func _esperar_aterrizaje(lienzo, sticker) -> bool:
	return await _esperar_que(func() -> bool: return is_instance_valid(sticker) and not lienzo.esta_cayendo(sticker), 6.0)


func _probar_fisica(motor, perfil: String, escena: String) -> void:
	var lienzo = motor.lienzo
	var cielo_esperado: float = {"parque_dinos": 440.0, "granja_ponys": 300.0, "ciudad_ponys": 290.0}.get(escena, -1.0)
	_check(lienzo.gravedad and is_equal_approx(lienzo.cielo.end.y, cielo_esperado), "§10.1 gravedad activa: cielo hasta y=%d" % lienzo.cielo.end.y)
	_check(lienzo.caida_suave == (perfil == "semilla"), "caida mas lenta solo para Maxi")
	# Objetivos y combinaciones del cielo: lo que se pide en el cielo vuela (nunca se vuelve imposible).
	var del_cielo: Array = []
	for o: Dictionary in motor._objetivos:
		if str(o["datos"].get("en_zona", "")) == "cielo":
			del_cielo.append(str(o["datos"].get("sticker", "")))
	for c: Dictionary in motor._cfg.get("combinaciones", []):
		if str(c.get("en", "")) == "cielo":
			del_cielo.append_array(c.get("ingredientes", []))
	var pesan := del_cielo.filter(func(id) -> bool: return lienzo.fisica_de(str(id)) == "pesa")
	_check(pesan.is_empty(), "lo que se pide en el cielo vuela (%s)%s" % [", ".join(PackedStringArray(del_cielo)), "" if pesan.is_empty() else " — PESAN: %s" % str(pesan)])
	# Un sticker que pesa, puesto en el cielo, cae con aceleracion y aterriza fuera del cielo con "¡puff!".
	var id: String = {"parque_dinos": "huevo", "granja_ponys": "pony_amigo", "ciudad_ponys": "casa"}.get(escena, "arbol")
	var aterrizajes: Array = []
	var al_aterrizar := func(s, grande: bool) -> void: aterrizajes.append([s, grande, lienzo.efectos_activos()])
	lienzo.aterrizo.connect(al_aterrizar)
	var punto := _libre(lienzo, _puntos_cielo(lienzo))
	var cosa = _poner(motor, id, punto)
	_check(cosa.id == id and lienzo.esta_cayendo(cosa), "%s soltado en el cielo empieza a caer" % id)
	var y0: float = cosa.centro().y
	lienzo._mover_caidas(0.05)
	var y1: float = cosa.centro().y
	lienzo._mover_caidas(0.05)
	var y2: float = cosa.centro().y
	_check(y2 - y1 > (y1 - y0) * 1.5, "la caida acelera (%.1f px y luego %.1f px)" % [y1 - y0, y2 - y1])
	_check(await _esperar_aterrizaje(lienzo, cosa), "aterriza")
	var base: Vector2 = cosa.centro() + Vector2(0, cosa.lado * cosa.escala * 0.43)
	_check(is_instance_valid(cosa) and lienzo.stickers().has(cosa) and cosa.centro().y > y0 + 40.0, "nunca desaparece: %s bajo de y=%d a y=%d" % [id, y0, cosa.centro().y])
	_check(not lienzo._soltar(cosa) and (not lienzo.cielo.has_point(base) or lienzo._es_superficie(base - Vector2(0, 4), cosa)), "queda apoyado en el suelo (base y=%d)" % base.y)
	_check(aterrizajes.size() == 1 and aterrizajes[0][1] == (perfil == "semilla"), "señal de aterrizaje ('¡puff!' %s)" % ("grande para Maxi" if perfil == "semilla" else "normal"))
	_check(not aterrizajes.is_empty() and int(aterrizajes[0][2]) > 0, "nubecita de polvo al aterrizar")
	lienzo.aterrizo.disconnect(al_aterrizar)
	# Se puede atrapar en el aire: arrastrarlo al cielo lo deja caer otra vez al soltar.
	var antes_arrastre: Vector2 = cosa.centro()
	var pasos_antes: int = lienzo.pasos_para_deshacer()
	_arrastrar(motor, cosa, _libre(lienzo, _puntos_cielo(lienzo)))
	_check(lienzo.esta_cayendo(cosa), "arrastrado al cielo, vuelve a caer")
	await _esperar_aterrizaje(lienzo, cosa)
	_check(lienzo.pasos_para_deshacer() == mini(pasos_antes + 1, lienzo.MAX_PASOS), "arrastrar + caer es UN solo paso del historial")
	motor.deshacer()
	_check(cosa.centro().distance_to(antes_arrastre) < 1.0, "deshacer el soltar lo devuelve a donde estaba antes de agarrarlo (no al cielo)")
	# Lo que vuela se queda donde se suelta.
	var nube = _poner(motor, "estrella", _libre(lienzo, _puntos_cielo(lienzo)))
	var donde: Vector2 = nube.centro()
	await _esperar(0.2)
	_check(not lienzo.esta_cayendo(nube) and nube.centro().distance_to(donde) < 1.0 and lienzo.en_zona(nube.centro(), "cielo"), "la estrella (vuela) se queda en el cielo")


## §10.2: el sol fuera del cielo tizna lo cercano (temporal), pone cara de "¡ups!" y vuelve al cielo.
func _probar_sol(motor) -> void:
	var lienzo = motor.lienzo
	var centro := _libre(lienzo, [Vector2(700, 600), Vector2(560, 640), Vector2(860, 640), Vector2(420, 640)])
	var vecinos: Array = [_poner(motor, "arbol", centro + Vector2(-90, 10)), _poner(motor, "flor", centro + Vector2(95, 20))]
	lienzo._process(0.016)
	var pintura: int = lienzo.pixeles_pintados()
	var quemas: Array = []
	var al_quemar := func(_s, n: int) -> void: quemas.append(n)
	lienzo.sol_quemo.connect(al_quemar)
	var sol = _poner(motor, "sol", centro)
	_check(quemas.size() == 1 and quemas[0] >= 2, "sol fuera del cielo: tizna %d stickers cercanos" % (quemas[0] if not quemas.is_empty() else 0))
	_check(vecinos.all(func(v) -> bool: return lienzo.esta_tiznado(v)) and sol.expresion == "ups", "los vecinos quedan tiznados y el sol pone cara de '¡ups!'")
	_check(await _esperar_que(func() -> bool: return not sol.has_meta("volando"), 5.0), "el sol vuela de vuelta")
	_check(lienzo.en_zona(sol.centro(), "cielo") and lienzo.cielo.has_point(sol.centro()) and sol.expresion == "", "el sol termina en el cielo (y=%d), con su cara de siempre" % sol.centro().y)
	_check(await _esperar_que(func() -> bool: return vecinos.all(func(v) -> bool: return not lienzo.esta_tiznado(v)), 6.0), "a los ~3 s los tiznados se sacuden")
	_check(vecinos.all(func(v) -> bool: return is_instance_valid(v) and v.self_modulate.is_equal_approx(Color.WHITE)), "y vuelven a su color: nada se destruye")
	lienzo._process(0.016)
	_check(lienzo.pixeles_pintados() == pintura, "la pintura hecha a mano no se quema")
	lienzo.sol_quemo.disconnect(al_quemar)
	# De vuelta en el cielo sigue combinando: sol + nube de lluvia = arcoiris.
	var arcoiris: int = lienzo.contar_stickers("arcoiris")
	var lluvia = lienzo.poner_sticker("nube_lluvia", Vector2(sol.centro().x, lienzo.cielo.end.y - 30.0))
	_arrastrar(motor, lluvia, sol.centro() + Vector2(40, 0))
	_check(lienzo.contar_stickers("arcoiris") == arcoiris + 1, "el sol que volvio al cielo sigue haciendo arcoiris con la nube de lluvia")


## §10.3: deshacer cada tipo de accion, el limite de 20 pasos, y que los objetivos no se pierdan.
func _probar_deshacer(motor, _perfil: String) -> void:
	var lienzo = motor.lienzo
	var hechos: int = motor._objetivos.filter(func(o) -> bool: return o["hecho"]).size()
	var destellos: int = motor.calcular_destellos()
	_check(lienzo.pasos_para_deshacer() > 0 and lienzo.pasos_para_deshacer() <= lienzo.MAX_PASOS, "historial con %d pasos (tope %d)" % [lienzo.pasos_para_deshacer(), lienzo.MAX_PASOS])
	_check(minf(motor._boton_deshacer.size.x, motor._boton_deshacer.size.y) >= motor._lado_boton() and motor._boton_deshacer.visible and motor._boton_reiniciar.visible, "botones deshacer y reiniciar de %d px" % motor._boton_deshacer.size.x)
	# Pincel.
	motor._elegir_herramienta("pincel", false)
	lienzo._process(0.016)
	var pixeles: int = lienzo.pixeles_pintados()
	var a := _libre(lienzo, _puntos_suelo())
	_trazo(lienzo, a, a + Vector2(80, -30), 12)
	lienzo._process(0.016)
	var con_trazo: int = lienzo.pixeles_pintados()
	motor.deshacer()
	_check(con_trazo > pixeles and lienzo.pixeles_pintados() == pixeles, "deshacer un trazo de pincel (%d -> %d -> %d px)" % [pixeles, con_trazo, lienzo.pixeles_pintados()])
	# Balde (el parque de Maxi tiene el fondo fijo y no tiene balde: ahi no aplica).
	if not lienzo.regiones_rellenables().is_empty():
		motor._elegir_herramienta("balde", false)
		var punto_balde := Vector2(640, 20)
		for i in lienzo.regiones_rellenables():
			var p = _punto_de(lienzo.lamina, i)
			if p != null and lienzo.sticker_en(p) == null and lienzo.lugar_en(p, 0.0) == null:
				punto_balde = p
				break
		var indice: int = Laminas.region_en(lienzo.lamina, punto_balde)
		var color_antes: Color = lienzo.region_color(indice)
		lienzo.color_actual = Color("#9357D6") if not color_antes.is_equal_approx(Color("#9357D6")) else Color("#FF6B6B")
		lienzo.empezar_trazo(punto_balde)
		lienzo.terminar_trazo()
		var pintado: bool = not lienzo.region_color(indice).is_equal_approx(color_antes)
		motor.deshacer()
		_check(pintado and lienzo.region_color(indice).is_equal_approx(color_antes), "deshacer el balde devuelve el color de la zona")
	# Sticker puesto.
	var cuantos: int = lienzo.stickers().size()
	var flor = _poner(motor, "flor", _libre(lienzo, _puntos_suelo()))
	motor.deshacer()
	await process_frame
	_check(lienzo.stickers().size() == cuantos and (not is_instance_valid(flor) or flor.is_queued_for_deletion()), "deshacer un sticker puesto lo quita")
	# Sticker movido.
	var movible = lienzo.stickers().filter(func(s) -> bool: return not lienzo.esta_viajando(s) and not s.has_meta("magico") 		and not lienzo.cielo.has_point(s.centro()) and lienzo.sticker_en(s.centro()) == s)[0]
	var desde: Vector2 = movible.centro()
	_arrastrar(motor, movible, _libre(lienzo, _puntos_suelo()))
	var se_movio: bool = movible.centro().distance_to(desde) > 20.0
	motor.deshacer()
	_check(se_movio and is_instance_valid(movible) and movible.centro().distance_to(desde) < 1.0, "deshacer un sticker movido lo devuelve (el mismo, no una copia)")
	# Camino con un viajero: al deshacer el camino, el viajero se baja.
	var vivo_id: String = motor._hojas[motor._indice_hoja]["tema"].get("vivos", ["pony_amigo"])[0]
	var viajero = _poner(motor, vivo_id, _libre(lienzo, [Vector2(200, 700), Vector2(140, 700), Vector2(1000, 700)]))
	await _esperar_aterrizaje(lienzo, viajero)
	# Maxi (R2) salta solo al sendero que ya hay: se baja antes de trazar el camino nuevo.
	lienzo._detener_fisica(viajero)
	lienzo._bajar(viajero)
	viajero.remove_meta("saltando")
	viajero.poner_en(Vector2(200, 700))
	var caminos: int = lienzo.caminos.size()
	var camino := _camino(motor, "sendero", [Vector2(300, 700), Vector2(600, 705), Vector2(900, 700)])
	if not lienzo.esta_viajando(viajero):
		viajero.poner_en(Vector2(600, 705))
		lienzo.intentar_subir(viajero)
	_check(not camino.is_empty() and lienzo.esta_viajando(viajero), "un %s viaja por el camino nuevo" % vivo_id)
	motor.deshacer()
	_check(lienzo.caminos.size() == caminos and not lienzo.esta_viajando(viajero) and is_instance_valid(viajero), "deshacer el camino: se va y su viajero se baja")
	# Limite: 25 trazos -> solo se recuerdan 20; se deshacen todos y el boton queda apagado.
	motor._elegir_herramienta("pincel", false)
	for i in 25:
		var p := Vector2(150 + (i % 5) * 40, 600 + (i / 5) * 18)
		_trazo(lienzo, p, p + Vector2(20, 0), 3)
	_check(lienzo.pasos_para_deshacer() == lienzo.MAX_PASOS, "el historial recuerda %d pasos como maximo" % lienzo.MAX_PASOS)
	var deshechos := 0
	while motor.deshacer():
		deshechos += 1
	_check(deshechos == lienzo.MAX_PASOS and lienzo.pasos_para_deshacer() == 0 and motor._boton_deshacer.modulate.a < 0.6, "%d deshacer seguidos; con historial vacio el boton se ve apagado" % deshechos)
	motor._revisar_objetivos()
	await process_frame
	var hechos_despues: int = motor._objetivos.filter(func(o) -> bool: return o["hecho"]).size()
	_check(hechos_despues == hechos and motor.calcular_destellos() >= destellos and motor.boton_mostrar.visible, "deshacer NO quita objetivos cumplidos (%d) ni destellos (%d -> %d)" % [hechos_despues, destellos, motor.calcular_destellos()])


## §10.4: reiniciar con la escoba mantenida 1,2 s: vuelve a la hoja inicial y conserva lo ganado.
func _probar_reiniciar(motor, escena: String) -> void:
	var lienzo = motor.lienzo
	var inicial: int = (lienzo._inicio["nodos"] as Array).size()
	var caminos_iniciales: int = (lienzo._inicio["caminos"] as Array).size()
	var hechos: int = motor._objetivos.filter(func(o) -> bool: return o["hecho"]).size()
	var destellos: int = motor.calcular_destellos()
	motor._elegir_herramienta("pincel", false)
	_trazo(lienzo, Vector2(300, 640), Vector2(700, 660), 20)
	_poner(motor, "flor", _libre(lienzo, _puntos_suelo()))
	var antes: int = lienzo.stickers().size()
	# Un toque corto no borra nada (anti-accidente).
	motor._empezar_a_mantener()
	await _esperar(0.15)
	motor._soltar_reiniciar()
	_check(lienzo.stickers().size() == antes and motor._reinicio_t < 0.0, "un toque corto en la escoba no borra nada")
	motor._empezar_a_mantener()
	_check(await _esperar_que(func() -> bool: return motor._barriendo, 3.0), "mantener %.1f s barre la hoja ('¡fuuush!')" % motor.SEGUNDOS_REINICIAR)
	_check(await _esperar_que(func() -> bool: return not motor._barriendo, 3.0), "la escoba termina de barrer")
	motor._soltar_reiniciar()
	await process_frame
	lienzo._process(0.016)
	_check(lienzo.stickers().size() == inicial and lienzo.caminos.size() == caminos_iniciales and lienzo.pixeles_pintados() == 0,
		"hoja como al empezar: %d stickers y %d caminos iniciales, sin pintura" % [lienzo.stickers().size(), lienzo.caminos.size()])
	if escena == "granja_ponys":
		_check(lienzo.lugar_por_id("granero") != null, "el granero que venia puesto sigue ahi")
	if escena == "ciudad_ponys":
		var rio: int = lienzo.region_por_id("rio")
		_check(lienzo.region_color(rio).is_equal_approx(lienzo._inicio["colores"][rio]) and not lienzo.region_color(rio).is_equal_approx(Colores.color("turquesa")), "el rio pintado de turquesa vuelve a su color inicial")
	_check(lienzo.pasos_para_deshacer() == 0 and not lienzo.bloqueado, "reiniciar vacia el historial y se puede seguir pintando")
	var hechos_despues: int = motor._objetivos.filter(func(o) -> bool: return o["hecho"]).size()
	_check(hechos_despues == hechos and motor.calcular_destellos() >= destellos and motor.boton_mostrar.visible, "reiniciar conserva objetivos cumplidos (%d) y destellos (%d -> %d)" % [hechos_despues, destellos, motor.calcular_destellos()])


func _estado_hoja(lienzo) -> String:
	lienzo._process(0.016)
	var colores: PackedStringArray = []
	for region: Dictionary in lienzo.lamina.get("regiones", []):
		colores.append((region["color"] as Color).to_html())
	return "%d|%d|%d|%d|%s" % [hash(lienzo._pintura.get_data()), lienzo.cantidad_sellos_vivos(), lienzo.celdas_pintadas(), lienzo._celdas.values().hash(), ",".join(colores)]


## Zonas 2-5: el ultimo trazo con la herramienta de la hoja (pincel, balde, sellos, mosaico) se deshace.
func _probar_deshacer_simple(motor) -> void:
	var lienzo = motor.lienzo
	# Un color distinto al actual, para que el trazo cambie algo aunque la hoja ya este pintada.
	for k in motor._entradas_color.size():
		if not (motor._entradas_color[k]["color"] as Color).is_equal_approx(lienzo.color_actual) and motor._encargo != "mezcla_paleta":
			motor.elegir_color(k)
			break
	var antes := _estado_hoja(lienzo)
	var centro: Vector2 = lienzo.area_segura.get_center()
	_trazo(lienzo, centro - Vector2(120, 20), centro + Vector2(120, 40), 24)
	var con_trazo := _estado_hoja(lienzo)
	if con_trazo == antes:
		print("   (deshacer: el trazo con '%s' no cambio nada en esta hoja; encargo %s, relleno %s, zoom %s, bloqueado %s)" % [lienzo.herramienta, motor._encargo, lienzo.rellenar_con_toque, lienzo.zoom, lienzo.bloqueado])
		return
	var ok: bool = motor.deshacer()
	_check(ok and _estado_hoja(lienzo) == antes, "deshacer el ultimo trazo con '%s'" % lienzo.herramienta)
	await process_frame


# ---------------------------------------------------------------------------
# Ficha §11: borrar caminos, caminos finos, personajes ("amigos") y Coco como burbujita
# ---------------------------------------------------------------------------

func _trazo_quieto(lienzo, punto: Vector2, segundos: float) -> void:
	lienzo.empezar_trazo(punto)
	var t := 0.0
	while t < segundos:
		lienzo._process(0.1)
		t += 0.1


## §11.1 y §11.2: caminos mas finos (tocables igual) y borrarlos enteros con la goma o el dedo quieto.
func _probar_caminos_s11(motor, perfil: String) -> void:
	var lienzo = motor.lienzo
	var esperado: float = lienzo.ANCHO_CAMINO_SEMILLA if perfil == "semilla" else lienzo.ANCHO_CAMINO
	_check(is_equal_approx(lienzo.ancho_caminos, esperado) and esperado < 1.0, "§11.2 caminos mas finos: ancho %.2f del v1 (Maxi algo mas anchos)" % esperado)
	var y := 700.0
	var camino := _camino(motor, "sendero", [Vector2(100, y), Vector2(265, y + 4), Vector2(430, y)])
	_check(not camino.is_empty() and is_equal_approx(float(camino["ancho"]), esperado), "el camino nuevo guarda su ancho")
	var dibujado := 32.0 * esperado / 2.0 + 2.5
	_check(lienzo.camino_en(Vector2(265, y + 4 - dibujado - 8.0)) == camino, "se toca con el dedo aunque el dibujo sea fino (%.0f px fuera del dibujo)" % 8.0)
	# Pintar encima con el pincel NO lo borra (anti-accidente).
	motor._elegir_herramienta("pincel", false)
	_trazo(lienzo, Vector2(250, y - 40), Vector2(280, y + 15), 10)
	_check(lienzo.caminos.has(camino), "pintar encima de un camino no lo borra")
	# Dedo quieto con la herramienta de camino: poco tiempo no borra; si se mueve, traza otro.
	motor._elegir_herramienta("camino_sendero", false)
	_trazo_quieto(lienzo, Vector2(265, y + 4), lienzo.segundos_borrar_camino * 0.4)
	lienzo.terminar_trazo()
	_check(lienzo.caminos.has(camino), "un toque corto con la herramienta de camino no lo borra")
	# Un viajero arriba (un amigo), y el dedo quieto el tiempo completo lo borra entero.
	var amigo: String = "sello_" + motor.obtener_id_personaje()
	var viajero = _poner(motor, amigo.trim_prefix("sello_"), Vector2(120, 690))
	lienzo._detener_fisica(viajero)
	lienzo._bajar(viajero)
	viajero.remove_meta("saltando")
	viajero.poner_en(Vector2(200, y + 3))
	lienzo.intentar_subir(viajero)
	_check(lienzo.esta_viajando(viajero), "un personaje (%s) viaja por el camino" % viajero.id)
	motor._elegir_herramienta("camino_sendero", false)
	var cuantos: int = lienzo.caminos.size()
	var borrados := {"n": 0}
	var al_borrar := func(_c) -> void: borrados["n"] += 1
	lienzo.camino_borrado.connect(al_borrar)
	_trazo_quieto(lienzo, Vector2(265, y + 4), lienzo.segundos_borrar_camino + 0.2)
	lienzo.continuar_trazo(Vector2(330, y - 60))
	lienzo.terminar_trazo()
	_check(not lienzo.caminos.has(camino) and lienzo.caminos.size() == cuantos - 1 and borrados["n"] == 1,
		"dedo quieto %.1f s sobre el camino: se borra ENTERO y no se traza otro" % lienzo.segundos_borrar_camino)
	_check(is_instance_valid(viajero) and not lienzo.esta_viajando(viajero) and lienzo.efectos_activos() > 0, "su viajero se baja y queda una fila de '¡puff!'")
	motor.deshacer()
	_check(lienzo.caminos.has(camino), "borrar un camino se deshace")
	# Goma: pasarla por encima borra el camino entero (Nicole y Sofia la tienen; Maxi, no).
	if (motor._grupos.get("pinceles", []) as Array).has("goma"):
		motor._elegir_herramienta("goma", false)
		var desde := _libre(lienzo, [Vector2(330, y - 50), Vector2(380, y - 50), Vector2(300, y - 70)])
		_trazo(lienzo, desde, Vector2(desde.x + 10, y + 15), 8)
		_check(not lienzo.caminos.has(camino) and borrados["n"] == 2, "la goma borra el camino que toca, entero")
		motor.deshacer()
		_check(lienzo.caminos.has(camino), "deshacer devuelve el camino borrado con la goma")
	lienzo.camino_borrado.disconnect(al_borrar)


## §11.3: los personajes como stickers "amigos".
func _probar_amigos(motor, perfil: String) -> void:
	var lienzo = motor.lienzo
	var amigos: Array = Stickers.AMIGOS
	var vuelan := ["cometa", "coleccionauta"]
	var bien := amigos.all(func(id) -> bool:
		return Stickers.tiene(id) and Stickers.es_personaje(id) and lienzo.clase_de(id) == "vivo" \
			and Stickers.fisica(id) == ("vuela" if id in vuelan else "pesa") and _existe_voz("voces/arcoiris/pinta/stickers/%s.wav" % id))
	_check(bien, "§11.3 %d amigos: vivos, con arte, nombre por voz; vuelan Cometa y el Coleccionauta" % amigos.size())
	var propio: String = "sello_" + motor.obtener_id_personaje()
	if perfil == "semilla":
		var cosas: Array = motor._grupos.get("cosas", [])
		_check(motor._dock_botones.size() <= 3 and amigos.all(func(id) -> bool: return cosas.has("sello_" + id)), "Maxi: los amigos van en 'Cosas' (sigue con 3 botones en el dock)")
		motor.abrir_popup("cosas")
		var dentro := Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(Rect2(motor._popup.position, motor._popup.size))
		_check(dentro, "el popup de cosas de Maxi, con su fila de amigos, cabe en pantalla")
		motor._cerrar_popup()
	else:
		var grupo: Array = motor._grupos.get("amigos", [])
		_check(grupo.size() == amigos.size() and str(grupo[0]) == propio, "grupo 'amigos' en el dock, con %s primero" % propio.trim_prefix("sello_"))
		var abajo := 0.0
		for entrada: Dictionary in motor._dock_botones:
			abajo = maxf(abajo, entrada["boton"].position.y + entrada["boton"].size.y)
		var ver: Button = motor._boton_ver_todo
		_check(abajo <= 712.0 and ver.position.y + ver.size.y <= 712.0 and ver.position.x + ver.size.x < 260.0, "el dock con amigos cabe (abajo y=%d) y 'ver todo' va al lado de la lupa" % abajo)
	# Un amigo puesto en el cielo: los que pesan caen, Cometa flota.
	var hermano = _poner(motor, propio.trim_prefix("sello_"), _libre(lienzo, _puntos_cielo(lienzo)))
	var cometa = _poner(motor, "cometa", _libre(lienzo, _puntos_cielo(lienzo)))
	var maxi_al_camino: bool = perfil == "semilla" and (hermano.has_meta("saltando") or lienzo.esta_viajando(hermano))
	_check((lienzo.esta_cayendo(hermano) or maxi_al_camino) and not lienzo.esta_cayendo(cometa),
		"%s %s; Cometa se queda flotando" % [hermano.id, "salta al camino (R2 de Maxi)" if maxi_al_camino else "cae del cielo"])
	await _esperar_aterrizaje(lienzo, hermano)
	# El PNG del dibujo incluye el arte de los personajes (tambien girado).
	var imagen: Image = Stickers.imagen("papa", Color.WHITE, 96, 0.5, true)
	var opacos := 0
	for yy in range(0, 96, 4):
		for xx in range(0, 96, 4):
			if imagen.get_pixel(xx, yy).a > 0.5:
				opacos += 1
	_check(imagen.get_size() == Vector2i(96, 96) and opacos > 40, "el arte de papa se rasteriza para el PNG (girado y espejado)")


## §11.4: Coco aparece en su burbujita solo cuando habla o celebra, sin tapar los objetivos.
func _probar_burbuja(motor) -> void:
	var burbuja: Control = motor._burbuja_coco
	_check(motor._anfitriona.get_parent().get_parent().get_parent() == burbuja, "Coco vive dentro de la burbujita (su cresta sigue imitando colores)")
	motor._burbuja_coco.hide()
	motor._coco_hasta = 0.0
	motor.tocar_objetivo(motor._indices_activos()[0])
	_check(motor.coco_visible(), "tocar la tarjeta del objetivo repite su voz y trae a Coco")
	var rect_burbuja := Rect2(burbuja.global_position, burbuja.size)
	var tapa := false
	for objetivo: Dictionary in motor._objetivos:
		var chip = objetivo["chip"]
		if chip != null and is_instance_valid(chip) and chip.visible and Rect2(chip.global_position, chip.size).intersects(rect_burbuja):
			tapa = true
	_check(not tapa and not rect_burbuja.intersects(Rect2(motor.boton_mostrar.position, motor.boton_mostrar.size)), "la burbuja no tapa las tarjetas de objetivo ni 'mostrar a Coco'")
	# Sin voces en curso ni pistas pendientes, la burbuja debe irse sola.
	motor._voz_diferida_id += 1
	motor._pausa_pista = 60.0
	var audio := get_root().get_node_or_null("Audio")
	if audio != null:
		audio.detener_voz()
	motor._coco_hasta = motor._tiempo - 1.0
	_check(await _esperar_que(func() -> bool: return not burbuja.visible, 8.0), "terminada la voz, la burbuja se va sola (no ocupa lugar)")
	motor._reaccion_anfitriona("salta")
	_check(motor.coco_visible(), "una celebracion (el salto de Coco) tambien la trae")
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	motor.lienzo.mostrar_fantasma({}, 0.0)
	motor._al_tocar_anfitriona(toque)
	_check(not motor.lienzo.fantasma_activo().is_empty() or motor._objetivos_listos, "tocar la burbuja da la pista (como tocar a Coco)")
	motor.lienzo.mostrar_fantasma({}, 0.0)
	motor._reiniciar_pistas()
	motor._pausa_pista = 0.0
	# Los toques de prueba cuentan como "manos" de pista: que no armen la valvula de Maxi.
	motor._valvula_lista = false
	for objetivo: Dictionary in motor._objetivos:
		objetivo["manos"] = 0


## §11.9 jinetes: montar, moverse juntos, caer juntos, desmontar, deshacer y vehiculo con dos asientos.
func _base_de(s) -> Vector2:
	return s.centro() + Vector2(0, s.lado * s.escala * 0.43)


func _cabeza_jinete(lienzo, s) -> Vector2:
	var alto: float = s.lado * s.escala * s.achique * 0.9 * Stickers.RECORTE_SENTADO
	return _base_de(s) - Vector2(0, alto * 0.75)


func _sin_camino_cerca(lienzo, d: Vector2) -> bool:
	for camino: Dictionary in lienzo.caminos:
		if float(lienzo._mas_cercano(camino, d)[1]) < 110.0:
			return false
	return true


func _probar_jinetes(motor, perfil: String) -> void:
	var lienzo = motor.lienzo
	var montables := ["pony_amigo", "unicornio", "trex", "spinosaurio", "jirafa", "carrito", "bus", "bomberos", "tren"]
	_check(montables.all(func(id) -> bool: return Stickers.es_montable(id)) and Stickers.AMIGOS.all(func(id) -> bool: return Stickers.es_jinete(id)),
		"§11.9 montables (animales grandes y vehiculos) y jinetes (los amigos)")
	var hermano: String = motor.obtener_id_personaje()
	# Objetivo OPCIONAL "sube a alguien a un pony" (no esta en las escenas obligatorias).
	var opcional := {"datos": {"tipo": "montar", "montura": "pony_amigo"}, "actual": 0, "meta": 1, "hecho": true, "chip": null, "registro": {},
		"ya": false, "mostrado": true, "manos": 0}
	motor._objetivos.append(opcional)
	var p := _libre(lienzo, [Vector2(760, 690), Vector2(900, 690), Vector2(620, 690), Vector2(1000, 690), Vector2(480, 690)])
	var pony = lienzo.poner_sticker("pony_amigo", p)
	var jinete = lienzo.poner_sticker(hermano, Vector2(p.x, 520) if not lienzo.gravedad else Vector2(p.x, lienzo.cielo.end.y + 140))
	var pasos: int = lienzo.pasos_para_deshacer()
	var montados := {"n": 0}
	var al_montar := func(_j, _m) -> void: montados["n"] += 1
	lienzo.montado.connect(al_montar)
	_arrastrar(motor, jinete, pony.centro() + Vector2(0, -15))
	lienzo._process(0.016)
	_check(lienzo.montura_de(jinete) == pony and jinete.sentado and montados["n"] == 1, "montar: %s soltado sobre el pony se sube (sentado, con '¡hop!')" % hermano)
	_check(_base_de(jinete).distance_to(lienzo._punto_asiento(pony, 0)) < 2.0, "queda en el asiento del lomo")
	_check(lienzo.pasos_para_deshacer() == mini(pasos + 1, lienzo.MAX_PASOS), "montar es un paso del historial")
	_check(bool(opcional["registro"].get("ok", false)), "objetivo opcional 'sube a alguien a un pony' se registra")
	motor._objetivos.erase(opcional)
	# Mover juntos: arrastrar el pony se lleva al jinete.
	# Lejos de los caminos (si no, el pony se sube a pasear, que tambien esta bien).
	var destino := p + Vector2(0, -150)
	for d: Vector2 in [p + Vector2(-170, -60), p + Vector2(170, -60), p + Vector2(0, -150), p + Vector2(-300, -100)]:
		if lienzo.sticker_en(d) == null and lienzo.camino_en(d).is_empty() and _sin_camino_cerca(lienzo, d):
			destino = d
			break
	_arrastrar(motor, pony, destino)
	lienzo._process(0.016)
	# (Si quedo junto a un camino, el pony se sube a pasear con su jinete: tambien es "juntos".)
	_check(pony.centro().distance_to(p) > 50.0 and lienzo.montura_de(jinete) == pony and _base_de(jinete).distance_to(lienzo._punto_asiento(pony, 0)) < 2.0,
		"mover juntos: arrastrar el pony se lleva al jinete%s" % (" (y pasean por el camino)" if lienzo.esta_viajando(pony) else ""))
	# Deshacer: primero el movimiento (siguen juntos), despues el montaje (se baja).
	motor.deshacer()
	lienzo._process(0.016)
	_check(pony.centro().distance_to(p) < 1.0 and lienzo.montura_de(jinete) == pony, "deshacer el movimiento: vuelven juntos")
	motor.deshacer()
	lienzo._process(0.016)
	_check(not lienzo.esta_montado(jinete) and not jinete.sentado and is_instance_valid(jinete), "deshacer el montaje: el jinete se baja")
	# Montar de nuevo y desmontar arrastrando al jinete.
	_arrastrar(motor, jinete, pony.centro() + Vector2(0, -15))
	lienzo._process(0.016)
	var cabeza := _cabeza_jinete(lienzo, jinete)
	lienzo.empezar_trazo(cabeza)
	for k in range(1, 13):
		lienzo.continuar_trazo(cabeza.lerp(cabeza + Vector2(-220, 10), k / 12.0))
	lienzo.terminar_trazo()
	lienzo._process(0.016)
	_check(lienzo.montura_de(jinete) != pony and lienzo.jinetes_de(pony).is_empty() and pony.centro().distance_to(p) < 1.0, "desmontar: arrastrar al jinete fuera lo baja (el pony se queda)")
	if lienzo.esta_montado(jinete):
		lienzo.desmontar(jinete)
	# Un segundo jinete en un pony ocupado se queda al lado.
	_arrastrar(motor, jinete, pony.centro() + Vector2(0, -15))
	var otro = lienzo.poner_sticker("papa", Vector2(p.x - 260, 600))
	_arrastrar(motor, otro, pony.centro() + Vector2(10, -15))
	lienzo._process(0.016)
	_check(lienzo.montura_de(jinete) == pony and not lienzo.esta_montado(otro), "un jinete por pony: el segundo se queda al lado")
	otro.poner_en(Vector2(p.x, 470))
	# Caer juntos: el pony con su jinete, soltado en el cielo, cae y aterrizan juntos.
	if lienzo.gravedad:
		_arrastrar(motor, pony, _libre(lienzo, _puntos_cielo(lienzo)))
		lienzo._mover_caidas(0.05)
		lienzo._seguir_monturas()
		var cayendo: bool = lienzo.esta_cayendo(pony)
		var junto: bool = _base_de(jinete).distance_to(lienzo._punto_asiento(pony, 0)) < 2.0
		await _esperar_aterrizaje(lienzo, pony)
		lienzo._process(0.016)
		_check(cayendo and junto and lienzo.montura_de(jinete) == pony and is_instance_valid(jinete) and not lienzo.cielo.has_point(_base_de(pony)) \
			and _base_de(jinete).distance_to(lienzo._punto_asiento(pony, 0)) < 2.0, "caer juntos: el pony cae con su jinete y aterrizan juntos")
	# Vehiculo: dos asientos arriba (techo).
	var q := _libre(lienzo, [Vector2(420, 690), Vector2(1000, 690), Vector2(300, 690), Vector2(900, 650)])
	var bus = lienzo.poner_sticker("bus", q)
	_arrastrar(motor, otro, bus.centro() + Vector2(-10, -20))
	var tercero = lienzo.poner_sticker("coco", Vector2(q.x + 200, 520))
	_arrastrar(motor, tercero, bus.centro() + Vector2(15, -20))
	lienzo._process(0.016)
	var arriba: bool = _base_de(otro).y < bus.centro().y - bus.lado * 0.15 and _base_de(tercero).y < bus.centro().y - bus.lado * 0.15
	_check(lienzo.jinetes_de(bus).size() == 2 and arriba and otro.sentado and tercero.sentado, "vehiculo: dos jinetes sentados arriba del bus")
	# Goma sobre el jinete: se va solo el jinete; deshacer lo devuelve montado.
	motor._elegir_herramienta("goma", false)
	lienzo.empezar_trazo(_cabeza_jinete(lienzo, tercero))
	lienzo.terminar_trazo()
	await process_frame
	_check(is_instance_valid(bus) and not bus.is_queued_for_deletion() and lienzo.jinetes_de(bus).size() == 1, "goma sobre la pareja: borra lo que se toco (el jinete)")
	motor.deshacer()
	lienzo._process(0.016)
	_check(lienzo.jinetes_de(bus).size() == 2, "deshacer la goma: el jinete vuelve a su asiento")
	lienzo.montado.disconnect(al_montar)


## Fisica sin motor: clasificacion pesa/vuela, cielo deducido del fondo, escenas sin cielo y espacio.
func _probar_fisica_suelta() -> void:
	print("-- fisica del lienzo (pesa / vuela, espacio, sin cielo) --")
	var pesan := ["trex", "spinosaurio", "carnotauro", "dino_bebe", "pony_amigo", "unicornio", "casa", "castillo", "granero", "arbol", "palmera", "jirafa", "gatito", "perrito", "tren", "moai"]
	var vuelan := ["nube", "nube_lluvia", "estrella", "sol", "luna", "globo", "arcoiris", "cohete", "planeta", "lechuza", "escoba", "pajaro", "cometa", "constelacion"]
	_check(pesan.all(func(id) -> bool: return Stickers.fisica(id) == "pesa"), "pesan: %s" % ", ".join(PackedStringArray(pesan)))
	_check(vuelan.all(func(id) -> bool: return Stickers.fisica(id) == "vuela"), "vuelan: %s" % ", ".join(PackedStringArray(vuelan)))
	var lienzo = load("res://scripts/motores/lienzo_libre/lienzo.gd").new()
	get_root().add_child(lienzo)
	lienzo.stickers_objeto = true
	lienzo.encuadrar(Vector2(1280, 720))
	var con_cielo := {"tipo": "zonas", "tamano": [1280, 720], "regiones": [
		{"id": "cielo", "forma": "rect", "rect": [0, 0, 1280, 720]}, {"id": "sol", "forma": "circulo", "centro": [200, 120], "radio": 60},
		{"id": "pasto", "forma": "rect", "rect": [0, 420, 1280, 300]}]}
	lienzo.poner_lamina(con_cielo)
	lienzo.preparar_fisica({"id": "parque"})
	_check(lienzo.gravedad and is_equal_approx(lienzo.cielo.end.y, 420.0), "sin zona `cielo`, el cielo se deduce del fondo (hasta el pasto, y=420)")
	var trex = lienzo.poner_sticker("trex", Vector2(640, 100))
	_check(lienzo._soltar(trex), "con cielo, el T-rex cae")
	lienzo._caidas.clear()
	var estrella = lienzo.poner_sticker("estrella", Vector2(700, 100))
	_check(not lienzo._soltar(estrella), "la estrella flota en el cielo (`poner estrella en_zona cielo` sigue siendo posible)")
	lienzo.preparar_fisica({"id": "mision_espacial"})
	_check(not lienzo.gravedad and not lienzo._soltar(trex), "espacio (por id): sin gravedad, todo flota")
	lienzo.preparar_fisica({"id": "otra", "gravedad": false})
	_check(not lienzo.gravedad, "espacio (por `gravedad: false` en el tema): sin gravedad")
	lienzo.zonas = {"espacio": [0, 0, 1280, 420]}
	lienzo.preparar_fisica({"id": "luna"})
	_check(not lienzo.gravedad, "espacio (zona `espacio`): sin gravedad")
	lienzo.limpiar()
	lienzo.encuadrar(Vector2(1280, 720))
	lienzo.poner_lamina({"tipo": "zonas", "tamano": [1280, 720], "regiones": [{"id": "pared", "forma": "rect", "rect": [0, 0, 1280, 720]}]})
	lienzo.preparar_fisica({"id": "fiesta"})
	var pony = lienzo.poner_sticker("pony_amigo", Vector2(640, 80))
	_check(not lienzo.gravedad and not lienzo._soltar(pony), "escena sin cielo: no hay gravedad")
	var sol = lienzo.poner_sticker("sol", Vector2(640, 600))
	_check(not lienzo._soltar(sol) and not sol.has_meta("volando"), "escena sin cielo: el sol no se quema en ningun lado")
	lienzo.queue_free()
	await process_frame


## Lupa 1x/2x y rueda: con zoom, el pincel y los stickers nuevos conservan su tamano en pantalla.
func _probar_zoom(motor) -> void:
	var lienzo = motor.lienzo
	motor._elegir_herramienta("pincel", false)
	var radio_1x: float = lienzo._radio_herramienta()
	motor.usar_lupa()
	_check(lienzo.lupa_armada and lienzo.zoom == 1.0, "lupa: queda armada")
	lienzo.usar_lupa_en(Vector2(640, 400))
	_check(is_equal_approx(lienzo.zoom, 2.0) and motor._boton_ver_todo.visible, "lupa: el toque acerca al doble y aparece 'ver todo'")
	_check(is_equal_approx(lienzo._radio_herramienta(), radio_1x / 2.0), "con zoom el pincel es mas fino en el mundo (mismo tamano en pantalla)")
	var lado_1x: float = float(lienzo.lado_sello)
	var nuevo = lienzo.poner_sticker("flor", lienzo.a_mundo(Vector2(640, 420)))
	_check(is_equal_approx(nuevo.lado, lado_1x / 2.0), "con zoom el sticker nuevo mide lo mismo en pantalla")
	var antes: Vector2 = lienzo.a_mundo(Vector2(300, 300))
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_UP
	rueda.pressed = true
	rueda.position = lienzo.a_mundo(Vector2(300, 300))
	lienzo._gui_input(rueda)
	_check(lienzo.zoom > 2.0 and lienzo.a_mundo(Vector2(300, 300)).distance_to(antes) < 1.0, "rueda del mouse: acerca manteniendo el punto bajo el cursor")
	motor._boton_ver_todo.pressed.emit()
	_check(lienzo.zoom == 1.0 and lienzo.position == Vector2.ZERO and not motor._boton_ver_todo.visible, "'ver todo' vuelve a 1x")


## Dos dedos nunca pintan: el segundo dedo deshace lo que hizo el primero en ese trazo.
func _probar_dos_dedos(motor) -> void:
	var lienzo = motor.lienzo
	motor._elegir_herramienta("pincel", false)
	lienzo._process(0.016)
	var antes: int = lienzo.pixeles_pintados()
	# Un punto libre de stickers (si no, el dedo arrastraria un sticker en vez de pintar).
	var inicio := Vector2(400, 650)
	for candidato in [Vector2(400, 650), Vector2(150, 700), Vector2(640, 700), Vector2(900, 690), Vector2(300, 200)]:
		if lienzo.sticker_en(candidato) == null and lienzo.sticker_en(candidato + Vector2(60, 10)) == null:
			inicio = candidato
			break
	var t1 := InputEventScreenTouch.new()
	t1.index = 0
	t1.pressed = true
	t1.position = inicio
	motor._input(t1)
	lienzo.empezar_trazo(inicio)
	lienzo.continuar_trazo(inicio + Vector2(60, 10))
	lienzo._process(0.016)
	var con_trazo: int = lienzo.pixeles_pintados()
	var t2 := InputEventScreenTouch.new()
	t2.index = 1
	t2.pressed = true
	t2.position = Vector2(700, 650)
	motor._input(t2)
	lienzo._process(0.016)
	_check(con_trazo > antes and lienzo.pixeles_pintados() == antes and lienzo.en_gesto, "dos dedos: el trazo del primero se deshace y no se pinta")
	for t in [t1, t2]:
		var suelta := InputEventScreenTouch.new()
		suelta.index = t.index
		suelta.pressed = false
		motor._input(suelta)
	_check(not lienzo.en_gesto, "al soltar los dedos vuelve a pintar con uno")


# ---------------------------------------------------------------------------
# Zonas 2-5 (encargo)
# ---------------------------------------------------------------------------

func _trazar(lienzo, puntos: Array) -> void:
	lienzo.empezar_trazo(puntos[0])
	for i in range(1, puntos.size()):
		var desde: Vector2 = puntos[i - 1]
		var hasta: Vector2 = puntos[i]
		for k in range(1, 9):
			lienzo.continuar_trazo(desde.lerp(hasta, k / 8.0))
	lienzo.terminar_trazo()


func _trazo(lienzo, a: Vector2, b: Vector2, pasos: int) -> void:
	lienzo.empezar_trazo(a)
	for i in range(1, pasos + 1):
		lienzo.continuar_trazo(a.lerp(b, float(i) / pasos))
	lienzo.terminar_trazo()


func _jugar_trazo(motor) -> void:
	var lienzo = motor.lienzo
	var antes: int = lienzo.pixeles_pintados() + lienzo.cantidad_sellos_vivos()
	_trazo(lienzo, Vector2(200, 200), Vector2(1000, 650), 40)
	lienzo._process(0.016)
	var despues: int = lienzo.pixeles_pintados() + lienzo.cantidad_sellos_vivos()
	_check(despues > antes, "trazo con '%s' deja huella (%d -> %d)" % [lienzo.herramienta, antes, despues])


## Espejo y mandala: el encargo es cubrir la guia (60 % / 75 %) con la simetria.
func _cubrir_guia(motor) -> void:
	var lienzo = motor.lienzo
	motor._elegir_herramienta("pincel_grueso" if motor._grupos.get("pinceles", []).has("pincel_grueso") else "pincel", false)
	lienzo.radio_pincel = 24.0
	var area: Rect2 = lienzo.area_segura
	var y := area.position.y + 10.0
	while y < area.end.y:
		_trazo(lienzo, Vector2(area.position.x, y), Vector2(area.get_center().x + 4.0, y), 30)
		y += 28.0
	var espejo: Vector2 = lienzo.puntos_simetricos(area.position + Vector2(30, 30))[1]
	_check(lienzo._pintura.get_pixelv(Vector2i(espejo)).a > 0.1, "simetria '%s': el reflejo tambien se pinto" % lienzo.simetria)
	_check(lienzo.cobertura_guia() >= (0.6 if motor._encargo == "espejo" else 0.75), "guia cubierta: %d %%" % int(lienzo.cobertura_guia() * 100.0))
	await process_frame


func _jugar_zonas(motor, con_pedidos: bool) -> void:
	var lienzo = motor.lienzo
	lienzo.herramienta = "balde"
	var completa := {"si": false}
	lienzo.lamina_completa.connect(func() -> void: completa["si"] = true, CONNECT_ONE_SHOT)
	var inalcanzables: Array = []
	var pedidos_cumplidos := {"n": 0}
	if con_pedidos:
		motor.pedido_cumplido.connect(func(_id: String) -> void: pedidos_cumplidos["n"] += 1)
	var regiones: Array = lienzo.regiones_rellenables()
	for i in regiones:
		var punto = _punto_de(lienzo.lamina, i)
		if punto == null:
			inalcanzables.append(str(lienzo.lamina["regiones"][i].get("id", i)))
			continue
		if con_pedidos and motor._pedido_actual >= 0:
			for k in motor._entradas_color.size():
				if motor._entradas_color[k]["id"] == str(motor._pedidos[motor._pedido_actual]):
					motor.elegir_color(k)
		elif not motor._entradas_color.is_empty():
			motor.elegir_color(randi() % motor._entradas_color.size())
		lienzo.empezar_trazo(punto)
		lienzo.terminar_trazo()
	_check(inalcanzables.is_empty(), "%d regiones rellenables, todas tocables%s" % [regiones.size(), "" if inalcanzables.is_empty() else " — tapadas: %s" % str(inalcanzables)])
	_check(completa["si"], "la lamina avisa que quedo completa")
	if con_pedidos:
		_check(motor._pedido_actual < 0, "Coco pide: %d pedidos cumplidos" % pedidos_cumplidos["n"])
	await _esperar(0.2)


func _punto_de(lamina: Dictionary, indice: int):
	var poligono: PackedVector2Array = lamina["regiones"][indice]["poligono"]
	var caja := Rect2(poligono[0], Vector2.ZERO)
	for p in poligono:
		caja = caja.expand(p)
	var centro := caja.get_center()
	if Laminas.region_en(lamina, centro) == indice:
		return centro
	var paso := maxf(2.0, minf(caja.size.x, caja.size.y) / 12.0)
	var y := caja.position.y + paso / 2.0
	while y < caja.end.y:
		var x := caja.position.x + paso / 2.0
		while x < caja.end.x:
			if Laminas.region_en(lamina, Vector2(x, y)) == indice:
				return Vector2(x, y)
			x += paso
		y += paso
	return null


func _jugar_mosaico(motor) -> void:
	var lienzo = motor.lienzo
	var total: int = lienzo.total_celdas()
	_check(lienzo._lado_celda >= 40.0 and lienzo.area_segura.encloses(Rect2(lienzo._origen_mosaico, Vector2(str(lienzo.mosaico["celdas"][0]).length(), lienzo.mosaico["celdas"].size()) * lienzo._lado_celda)),
		"mosaico dentro del area libre de botones, celdas de %d px" % lienzo._lado_celda)
	for k in motor._entradas_color.size():
		motor.elegir_color(k)
		var color: Color = motor._entradas_color[k]["color"]
		var filas: Array = lienzo.mosaico["celdas"]
		for y in filas.size():
			for x in str(filas[y]).length():
				if lienzo.color_esperado(Vector2i(x, y)).is_equal_approx(color):
					lienzo.empezar_trazo(lienzo.centro_celda(Vector2i(x, y)))
					lienzo.terminar_trazo()
	_check(lienzo.celdas_correctas() == total, "%d de %d celdas con su color" % [lienzo.celdas_correctas(), total])
	await _esperar(0.2)


func _jugar_mezcla(motor) -> void:
	var recetas := {"verde": {"azul": 1, "amarillo": 1}, "naranja": {"rojo": 1, "amarillo": 1}, "violeta": {"rojo": 1, "azul": 1},
		"rosado": {"rojo": 1, "blanco": 1}, "celeste": {"azul": 1, "blanco": 1}, "cafe": {"rojo": 1, "amarillo": 1, "azul": 1},
		"lila": {"rojo": 1, "azul": 1, "blanco": 1}}
	motor.abrir_popup("colores")
	_check(motor._popup.get_children().any(func(b) -> bool: return b.has_meta("platito")), "el platito de mezcla vive en el popup de colores")
	var total: int = motor._pedidos.size()
	var cumplidos := {"n": 0}
	motor.pedido_cumplido.connect(func(_id: String) -> void: cumplidos["n"] += 1)
	for i in total:
		var pedido := str(motor._pedidos[motor._pedido_actual])
		motor._gotas = {}
		var receta: Dictionary = recetas.get(pedido, {})
		for id in receta:
			for k in int(receta[id]):
				motor._agregar_gota(id)
		await _esperar(0.05)
	_check(cumplidos["n"] == total, "mezcla: %d de %d pedidos cumplidos" % [cumplidos["n"], total])
	_check(motor.popup_abierto() == "colores", "mezclar gotas no cierra el popup")
	motor._cerrar_popup()
	await _jugar_zonas(motor, false)


func _jugar_trajes(motor, lamina: Dictionary) -> void:
	for id in lamina.get("orden_trajes", []):
		motor._elegir_traje(str(id), false)
		_check(motor._traje == str(id), "traje de Coco: %s" % id)
	await _esperar(0.1)


# ---------------------------------------------------------------------------
# Voces, PNG y mezclas
# ---------------------------------------------------------------------------

func _revisar_voces(nivel: Dictionary) -> void:
	var rutas: Array = []
	_juntar_rutas(nivel, rutas)
	var faltan: Array = []
	for r in rutas:
		if not _existe_voz(r):
			faltan.append(r)
	var ids: Array = nivel.get("paleta", []).duplicate()
	if str(nivel.get("encargo", "")) == "mezcla_paleta":
		ids = Colores.COLORES.keys()
	for id in ids:
		if nivel.has("voces_colores") and not _existe_voz(str(nivel["voces_colores"]) % id):
			faltan.append(str(nivel["voces_colores"]) % id)
	for pedido in nivel.get("pedidos", []):
		for clave in ["voces_pedidos", "voces_logrado"]:
			if nivel.has(clave) and not _existe_voz(str(nivel[clave]) % pedido):
				faltan.append(str(nivel[clave]) % pedido)
	_check(faltan.is_empty(), "%d voces referenciadas existen%s" % [rutas.size(), "" if faltan.is_empty() else " — faltan: %s" % str(faltan)])


func _juntar_rutas(valor, rutas: Array) -> void:
	if valor is Dictionary:
		for v in valor.values():
			_juntar_rutas(v, rutas)
	elif valor is Array:
		for v in valor:
			_juntar_rutas(v, rutas)
	elif valor is String and valor.begins_with("voces/") and not valor.contains("%s"):
		if not rutas.has(valor):
			rutas.append(valor)


func _revisar_png(ruta: String) -> void:
	if ruta == "":
		_check(false, "se guardo el PNG del dibujo")
		return
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
	var colores := {}
	if imagen != null:
		for y in range(0, imagen.get_height(), 29):
			for x in range(0, imagen.get_width(), 29):
				colores[imagen.get_pixel(x, y).to_html(false)] = true
	_check(imagen != null and imagen.get_size() == Vector2i(1280, 720) and colores.size() >= 2, "PNG 1280x720 guardado con dibujo (%d colores)" % colores.size())


func _probar_mezclas() -> void:
	print("-- mezclas de colores (RYB) --")
	var casos := [[{"azul": 1, "amarillo": 1}, "verde"], [{"rojo": 1, "amarillo": 1}, "naranja"], [{"rojo": 1, "azul": 1}, "violeta"],
		[{"rojo": 1, "amarillo": 1, "azul": 1}, "cafe"], [{"rojo": 1, "blanco": 1}, "rosado"], [{"azul": 2, "blanco": 1}, "celeste"],
		[{"rojo": 1, "azul": 1, "blanco": 1}, "lila"], [{"rojo": 3}, "rojo"]]
	for caso in casos:
		_check(Colores.nombre_mezcla(caso[0]) == caso[1], "%s -> %s" % [str(caso[0]), caso[1]])
	await process_frame


func _borrar(carpeta: String) -> void:
	var dir := DirAccess.open(carpeta)
	if dir == null:
		return
	for sub in dir.get_directories():
		_borrar(carpeta.path_join(sub))
	for archivo in dir.get_files():
		dir.remove(archivo)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(carpeta))
