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
	if perfil != "semilla":
		await _probar_zoom(motor)
	await _probar_dos_dedos(motor)
	var imagen: Image = lienzo.componer()
	_check(imagen.get_size() == Vector2i(1280, 720), "el PNG compone a 1280x720 con stickers y caminos")


func _poner(motor, id: String, p: Vector2):
	motor._elegir_herramienta("sello_" + id, false)
	motor.lienzo.empezar_trazo(p)
	motor.lienzo.terminar_trazo()
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
