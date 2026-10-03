extends SceneTree

## Arnes QA de "Pinta con Coco" (motor lienzo_libre): juega los 15 niveles (5 zonas x 3 rutas).
## Por nivel verifica: carga y hojas armadas, voces referenciadas existentes (incluidas las de los
## patrones de colores, pedidos y mezclas), tamanos tactiles (paleta, herramientas y "mostrar a Coco"
## >= 64 px; >= 96 px en Semilla), que toda region rellenable se pueda tocar, que un trazo simulado
## deje pintura, que el mosaico se complete y avise, pedidos de Coco y mezclas cumplidos, trajes de
## Coco, y que "mostrar a Coco" guarde un PNG valido por hoja y al final llegue `completado(destellos)`.
## Los dibujos van a user://qa_dibujos (nunca pisa los dibujos reales de los ninos) y se borran al final.
##
## Uso: godot --headless --path . --script herramientas/qa_test_lienzo.gd [-- <filtro>]

const MOTOR := "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn"
const Laminas := preload("res://scripts/motores/lienzo_libre/laminas.gd")
const Colores := preload("res://scripts/motores/lienzo_libre/colores_lienzo.gd")
const Stickers := preload("res://scripts/motores/lienzo_libre/stickers.gd")
const ZONAS := ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
const HERMANOS := {"semilla": "maxi", "brote": "nicole", "estrella": "sofia"}
const CARPETA_QA := "user://qa_dibujos"

var _fallos := 0


func _initialize() -> void:
	print("=== QA lienzo_libre: Pinta con Coco, 5 zonas x rutas de Maxi, Nicole y Sofia ===")
	var filtro := ""
	if OS.get_cmdline_user_args().size() > 0:
		filtro = OS.get_cmdline_user_args()[0]
	for zona in ZONAS:
		for perfil in HERMANOS:
			var ruta := "res://datos/niveles/arcoiris/%s/pinta_%s.json" % [zona, perfil]
			if filtro != "" and not ruta.contains(filtro):
				continue
			await _probar_nivel(ruta, HERMANOS[perfil])
	await _probar_mezclas()
	_borrar(CARPETA_QA)
	print("=== RESULTADO: %s (%d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


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
	motor.hoja_mostrada.connect(func(i: int, png: String) -> void: mostradas.append(png))
	get_root().add_child(motor)
	await _esperar(0.5)

	var nivel: Dictionary = motor.nivel
	var perfil := str(nivel.get("perfil", ""))
	_check(str(nivel.get("motor", "")) == "lienzo_libre", "motor lienzo_libre, encargo %s" % nivel.get("encargo", "?"))
	var hojas: int = motor._hojas.size()
	_check(hojas >= 1, "%d hojas en la partida" % hojas)
	_revisar_voces(nivel)

	for h in hojas:
		while motor._indice_hoja != h and is_instance_valid(motor):
			await process_frame
		await _esperar(0.35)
		if motor.eligiendo_tema:
			await _elegir_tema(motor, nivel, h)
		var hoja: Dictionary = motor._hojas[h]
		var lamina: Dictionary = hoja["lamina"]
		var encargo: String = motor._encargo
		print("   hoja %d/%d: %s · %s" % [h + 1, hojas, encargo, lamina.get("id", "papel en blanco")])
		_revisar_tactil(motor, perfil)
		var lienzo = motor.lienzo
		if lienzo.stickers_objeto:
			await _jugar_tema(motor, perfil)
		elif not lienzo.mosaico.is_empty():
			await _jugar_mosaico(motor)
		elif encargo == "mezcla_paleta":
			await _jugar_mezcla(motor)
		elif not lienzo.lamina.is_empty() and not lienzo.regiones_rellenables().is_empty():
			if lamina.has("trajes"):
				await _jugar_trajes(motor, lamina)
			await _jugar_zonas(motor, encargo == "coco_pide")
		else:
			_jugar_trazo(motor)
		if not motor.boton_mostrar.visible:
			motor._al_tocar_anfitriona(_toque())
		_check(motor.boton_mostrar.visible, "boton 'mostrar a Coco' visible (Semilla: al tocar a Coco o tras un momento)")
		if perfil == "semilla":
			# Mecanicas HE-40 #21: el boton aparece a los >= 45 s. Niveles HE-40 #11: si Maxi sigue
			# pintando 90 s mas, Coco pregunta "¿me lo muestras?" una sola vez y no muestra la hoja sola.
			_check(float(hoja["cfg"].get("segundos_mostrar", 0.0)) >= 45.0, "Semilla: boton a los >= 45 s (%s)" % hoja["cfg"].get("segundos_mostrar"))
			_check(motor._segundos_recordar > 0.0 and _existe_voz(str((nivel["lineas_voz"].get("me_lo_muestras", [""]) as Array)[0])),
				"Semilla: recordatorio 'me lo muestras' con voz a los %s s" % motor._segundos_recordar)
			motor._tiempo_hoja = motor._boton_visible_desde + motor._segundos_recordar + 0.1
			await process_frame
			await process_frame
			_check(motor._recordado and motor._indice_hoja == h and motor.boton_mostrar.visible,
				"Semilla: Coco recuerda una vez y la hoja sigue abierta (sin auto-mostrar)")
		var png: String = motor.mostrar_a_coco()
		_revisar_png(png, motor.lienzo.tamano)
		if bool(hoja["cfg"].get("guardar_como", "") != ""):
			var fijo := "%s/%s/%s.png" % [CARPETA_QA, hermano, hoja["cfg"]["guardar_como"]]
			_check(FileAccess.file_exists(fijo), "copia fija para el hangar: %s" % fijo.get_file())
	var t0 := Time.get_ticks_msec()
	while resultado["destellos"] < 0 and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	_check(mostradas.size() == hojas, "%d hojas mostradas a Coco" % mostradas.size())
	_check(resultado["destellos"] > 0, "completado(destellos) recibido: %d" % resultado["destellos"])
	motor.queue_free()
	await process_frame


## Selector de tema (Nicole 2 tarjetas, Sofia 3): tarjetas grandes y distintas de lo ya jugado.
func _elegir_tema(motor, nivel: Dictionary, h: int) -> void:
	var opciones: Array = motor._hojas[h].get("opciones", [])
	_check(opciones.size() == int(nivel.get("opciones_tema", 1)), "selector de tema con %d tarjetas" % opciones.size())
	var chicas := 0
	for hijo in motor._selector.get_children():
		if hijo is Button and minf(hijo.size.x, hijo.size.y) < 200.0:
			chicas += 1
	_check(chicas == 0, "tarjetas de tema grandes (>= 200 px)")
	var jugados: Array = []
	for i in h:
		jugados.append(str(motor._hojas[i]["tema"].get("id", "")))
	var repetidas := 0
	for tema: Dictionary in opciones:
		if jugados.has(str(tema.get("id", ""))):
			repetidas += 1
	_check(repetidas == 0, "las tarjetas no repiten temas ya jugados (%s)" % str(jugados))
	motor.elegir_tema(h % opciones.size())
	await _esperar(0.3)
	_check(not motor.eligiendo_tema and not motor._hojas[h]["tema"].is_empty(), "tema elegido: %s" % motor._hojas[h]["tema"].get("id", "?"))


## Lienzo con tema: pone cada sticker, lo toca, lo arrastra, lo edita, lo recolorea, lo conecta con
## el conector (y ve andar al viajero), cierra un circuito, y cumple los retos de Sofia.
func _jugar_tema(motor, perfil: String) -> void:
	var lienzo = motor.lienzo
	var cfg: Dictionary = motor._cfg
	var tema: Dictionary = motor._hojas[motor._indice_hoja]["tema"]
	var ids: Array = cfg.get("stickers", [])
	print("   tema %s: %d stickers, conector %s" % [tema.get("id", "?"), ids.size(), str(cfg.get("conector", {}))])
	_check(not lienzo.lamina.is_empty() and lienzo.lamina["regiones"].size() >= 4, "fondo del tema con %d zonas" % lienzo.lamina.get("regiones", []).size())
	_check(ids.size() >= (3 if perfil == "semilla" else 8), "%d stickers para %s (Sofia >= 13, Nicole 8, Maxi 3)" % [ids.size(), perfil])
	if perfil == "estrella":
		_check(ids.size() >= 13, "Sofia tiene muchas opciones: %d stickers" % ids.size())
	var faltan: Array = []
	for id in ids:
		if not Stickers.tiene(str(id)):
			faltan.append(id)
		elif not _existe_voz(str(cfg.get("voces_stickers", "")) % id):
			faltan.append("voz " + str(id))
	_check(faltan.is_empty(), "stickers en el catalogo y con voz%s" % ("" if faltan.is_empty() else " — faltan: %s" % str(faltan)))
	var tiene_bolsa := (cfg.get("herramientas", []) as Array).has("bolsa")
	_check(tiene_bolsa == (perfil != "semilla"), "bolsa de stickers solo para Nicole y Sofia (Maxi los tiene a mano)")
	if tiene_bolsa:
		motor._abrir_bandeja()
		var botones: Array = []
		for hijo in motor._bandeja.get_children():
			if hijo is Button:
				botones.append(hijo)
		var chicos := botones.filter(func(b) -> bool: return minf(b.size.x, b.size.y) < 64.0)
		_check(motor._bandeja.visible and botones.size() == ids.size() and chicos.is_empty(), "bolsa abierta con %d stickers >= 64 px" % botones.size())
		var dentro := Rect2(Vector2(232, 80), Vector2(824, 530)).encloses(Rect2(motor._bandeja.position, motor._bandeja.size))
		_check(dentro, "la bolsa cabe sobre el lienzo (%s)" % Rect2(motor._bandeja.position, motor._bandeja.size))
		botones[1].pressed.emit()
		_check(not motor._bandeja.visible and lienzo.herramienta == "sello_" + str(ids[1]), "elegir en la bolsa cierra y deja el sticker listo")

	# Poner cada sticker en una grilla.
	var puestos: Array = []
	for i in maxi(ids.size(), 8):
		motor._elegir_herramienta("sello_" + str(ids[i % ids.size()]), false)
		var p := Vector2(90 + (i % 6) * 128, 90 + (i / 6) * 150)
		lienzo.empezar_trazo(p)
		lienzo.terminar_trazo()
		puestos.append(p)
	_check(lienzo.stickers().size() == puestos.size(), "%d stickers puestos" % lienzo.stickers().size())

	# Tocar un sticker: salta (no se pone otro encima); Nicole y Sofia ven la barra de edicion.
	var tocados := {"n": 0}
	lienzo.sticker_tocado.connect(func(_s) -> void: tocados["n"] += 1, CONNECT_ONE_SHOT)
	var cuantos: int = lienzo.stickers().size()
	lienzo.empezar_trazo(puestos[0])
	lienzo.terminar_trazo()
	_check(tocados["n"] == 1 and lienzo.stickers().size() == cuantos, "tocar un sticker lo hace saltar (sin duplicarlo)")
	_check(motor._barra.visible == (perfil != "semilla"), "barra de edicion: %s" % ("no (Maxi)" if perfil == "semilla" else "si"))
	if motor._barra.visible:
		var chicos := 0
		for hijo in motor._barra.get_children():
			if hijo is Button and minf(hijo.size.x, hijo.size.y) < 64.0:
				chicos += 1
		_check(chicos == 0, "botones de edicion >= 64 px")
		var sticker = lienzo.seleccionado
		motor._accion_sticker("agrandar")
		_check(sticker.escala > 1.0, "agrandar: escala %.2f" % sticker.escala)
		if perfil == "estrella":
			motor._accion_sticker("girar")
			motor._accion_sticker("espejo")
			_check(absf(sticker.rotation) > 0.1 and sticker.espejo, "Sofia gira y espeja el sticker")
		motor._accion_sticker("achicar")

	# Arrastrar un sticker lo mueve.
	var movido = lienzo.stickers()[1]
	var antes: Vector2 = movido.centro()
	lienzo.empezar_trazo(antes)
	for k in range(1, 11):
		lienzo.continuar_trazo(antes + Vector2(6.0 * k, 4.0 * k))
	lienzo.terminar_trazo()
	_check(movido.centro().distance_to(antes + Vector2(60, 40)) < 2.0, "arrastrar mueve el sticker")

	# Balde sobre un sticker lo recolorea (Nicole y Sofia).
	if (cfg.get("herramientas", []) as Array).has("balde"):
		motor._elegir_herramienta("balde", false)
		lienzo.color_actual = Color("#9357D6")
		var pintado = lienzo.stickers()[2]
		lienzo.empezar_trazo(pintado.centro())
		lienzo.terminar_trazo()
		_check((pintado.color as Color).is_equal_approx(Color("#9357D6")), "el balde recolorea el sticker")

	# Conector: unir dos stickers; si hay viajero, anda.
	var conector: Dictionary = cfg.get("conector", {})
	_check(not conector.is_empty() and (cfg.get("herramientas", []) as Array).has("conector"), "conector del tema: %s" % str(conector))
	motor._elegir_herramienta("conector", false)
	var a = lienzo.stickers()[3]
	var b = lienzo.stickers()[4]
	_trazar(lienzo, [a.centro(), (a.centro() + b.centro()) / 2.0 + Vector2(0, 60), b.centro()])
	_check(lienzo.caminos.size() == 1 and lienzo.conexiones() == 1, "el conector une dos stickers (%d caminos)" % lienzo.caminos.size())
	if str(conector.get("viajero", "")) != "":
		_check(lienzo.viajeros().size() == 1, "el viajero %s sale a recorrer el camino" % conector["viajero"])
		var inicio: Vector2 = lienzo.viajeros()[0].centro()
		await _esperar(0.8)
		_check(lienzo.viajeros()[0].centro().distance_to(inicio) > 20.0, "el viajero avanza por el camino")
	# Un circuito cerrado lejos de los stickers: el viajero da vueltas.
	var centro := Vector2(412, 420)
	var circulo: Array = []
	for i in 25:
		circulo.append(centro + Vector2.from_angle(TAU * i / 24.0 + 0.2) * Vector2(170, 70))
	var libres: bool = lienzo.sticker_en(circulo[0]) == null and lienzo.sticker_en(circulo[circulo.size() - 1]) == null
	_trazar(lienzo, circulo)
	if libres:
		_check(bool(lienzo.caminos.back()["cerrado"]), "un camino que vuelve al inicio queda cerrado (circuito)")
	var c = lienzo.stickers()[5]
	_trazar(lienzo, [b.centro(), c.centro() + Vector2(0, 1)])
	_check(lienzo.conexiones() >= 2, "segunda conexion (%d)" % lienzo.conexiones())

	# Goma sobre un sticker lo borra.
	if (cfg.get("herramientas", []) as Array).has("goma"):
		motor._elegir_herramienta("goma", false)
		var total: int = lienzo.stickers().size()
		var borrado = lienzo.stickers().back()
		lienzo.empezar_trazo(borrado.centro())
		lienzo.terminar_trazo()
		await process_frame
		_check(lienzo.stickers().size() == total - 1, "la goma borra un sticker")

	# Pintar un poco con el pincel (bajo los stickers) y con varios colores.
	motor._elegir_herramienta("pincel", false)
	for i in mini(6, motor._botones_color.size()):
		motor._seleccionar_color(motor._botones_color[i], false)
		lienzo.empezar_trazo(Vector2(40 + i * 120, 500))
		lienzo.continuar_trazo(Vector2(90 + i * 120, 510))
		lienzo.terminar_trazo()

	# Retos de Sofia.
	if perfil == "estrella":
		_check(motor._retos.size() == 3, "3 retos de artista")
		for reto: Dictionary in motor._retos:
			var datos: Dictionary = reto["datos"]
			if str(datos.get("tipo", "")) == "stickers":
				motor._elegir_herramienta("sello_" + str(datos["sticker"]), false)
				for k in int(datos.get("n", 1)):
					lienzo.empezar_trazo(Vector2(120 + k * 110, 470))
					lienzo.terminar_trazo()
			_check(_existe_voz(str(datos.get("voz", ""))), "voz del reto %s" % datos.get("tipo", "?"))
		motor._revisar_retos()
		var hechos := 0
		for reto: Dictionary in motor._retos:
			if reto["hecho"]:
				hechos += 1
		_check(hechos == 3, "retos cumplidos: %d de 3" % hechos)
	else:
		_check(motor._retos.is_empty(), "sin retos para %s" % perfil)
	var imagen: Image = lienzo.componer()
	var solo_fondo := Image.create(lienzo.tamano.x, lienzo.tamano.y, false, Image.FORMAT_RGBA8)
	solo_fondo.fill(lienzo.papel)
	Laminas.rasterizar(solo_fondo, lienzo.lamina)
	var con_sticker: Vector2 = c.centro()
	_check(not imagen.get_pixelv(Vector2i(con_sticker)).is_equal_approx(solo_fondo.get_pixelv(Vector2i(con_sticker))), "el PNG incluye los stickers")
	await _esperar(0.1)


func _trazar(lienzo, puntos: Array) -> void:
	lienzo.empezar_trazo(puntos[0])
	for i in range(1, puntos.size()):
		var desde: Vector2 = puntos[i - 1]
		var hasta: Vector2 = puntos[i]
		for k in range(1, 9):
			lienzo.continuar_trazo(desde.lerp(hasta, k / 8.0))
	lienzo.terminar_trazo()


func _toque() -> InputEventMouseButton:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = true
	return evento


## Toda ruta de voz del nivel (y las de los patrones) debe existir.
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
		for clave in ["voces_colores"]:
			if nivel.has(clave) and not _existe_voz(str(nivel[clave]) % id):
				faltan.append(str(nivel[clave]) % id)
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


func _revisar_tactil(motor, perfil: String) -> void:
	var minimo := 96.0 if perfil == "semilla" else 64.0
	var chicos: Array = []
	for entrada: Dictionary in motor._botones_color:
		var tam: Vector2 = entrada["boton"].size
		if minf(tam.x, tam.y) < minimo:
			chicos.append("color %s" % tam)
	for entrada: Dictionary in motor._botones_herramienta:
		var tam: Vector2 = entrada["boton"].size
		if minf(tam.x, tam.y) < minimo:
			chicos.append("%s %s" % [entrada["id"], tam])
	if minf(motor.boton_mostrar.size.x, motor.boton_mostrar.size.y) < 96.0:
		chicos.append("mostrar %s" % motor.boton_mostrar.size)
	_check(chicos.is_empty(), "tactiles >= %d px (%d colores, %d herramientas, mostrar %s)%s" % [minimo, motor._botones_color.size(), motor._botones_herramienta.size(), motor.boton_mostrar.size, "" if chicos.is_empty() else " — chicos: %s" % str(chicos)])


## Un trazo en diagonal con la herramienta activa debe dejar pintura (o un sello).
func _jugar_trazo(motor) -> void:
	var lienzo = motor.lienzo
	var antes: int = lienzo.pixeles_pintados() + lienzo.cantidad_sellos_vivos()
	lienzo.empezar_trazo(Vector2(150, 150))
	for i in range(1, 21):
		lienzo.continuar_trazo(Vector2(150, 150).lerp(Vector2(650, 400), i / 20.0))
	lienzo.terminar_trazo()
	lienzo._process(0.016)
	var despues: int = lienzo.pixeles_pintados() + lienzo.cantidad_sellos_vivos()
	_check(despues > antes, "trazo con '%s' deja huella (%d -> %d)" % [lienzo.herramienta, antes, despues])
	if lienzo.simetria != "":
		var espejo: Vector2 = lienzo.puntos_simetricos(Vector2(150, 150))[1]
		var imagen: Image = lienzo._pintura
		_check(imagen.get_pixelv(Vector2i(espejo)).a > 0.1, "simetria '%s': el reflejo tambien se pinto" % lienzo.simetria)


## Toca cada region rellenable en un punto donde sea la de mas arriba; al final debe avisar completa.
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
			for entrada: Dictionary in motor._botones_color:
				if entrada["id"] == str(motor._pedidos[motor._pedido_actual]):
					motor._seleccionar_color(entrada, false)
		else:
			var entradas: Array = motor._botones_color
			if not entradas.is_empty():
				motor._seleccionar_color(entradas[randi() % entradas.size()], false)
		lienzo.empezar_trazo(punto)
		lienzo.terminar_trazo()
	_check(inalcanzables.is_empty(), "%d regiones rellenables, todas tocables%s" % [regiones.size(), "" if inalcanzables.is_empty() else " — tapadas: %s" % str(inalcanzables)])
	_check(lienzo.regiones_pintadas() == regiones.size() - inalcanzables.size(), "%d regiones pintadas" % lienzo.regiones_pintadas())
	_check(completa["si"], "la lamina avisa que quedo completa")
	if con_pedidos:
		_check(pedidos_cumplidos["n"] >= motor._pedidos.size() or motor._pedido_actual < 0, "Coco pide: %d pedidos cumplidos" % pedidos_cumplidos["n"])
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


## Colorear por codigo: pinta cada celda con su color de la leyenda arrastrando por filas.
func _jugar_mosaico(motor) -> void:
	var lienzo = motor.lienzo
	var completa := {"si": false}
	lienzo.lamina_completa.connect(func() -> void: completa["si"] = true, CONNECT_ONE_SHOT)
	var total: int = lienzo.total_celdas()
	_check(lienzo._lado_celda >= 40.0, "celdas de %d px (%dx%d)" % [lienzo._lado_celda, str(lienzo.mosaico["celdas"][0]).length(), lienzo.mosaico["celdas"].size()])
	_check(motor._botones_color.size() == lienzo.mosaico.get("colores", {}).size(), "leyenda con %d colores numerados" % motor._botones_color.size())
	for entrada: Dictionary in motor._botones_color:
		motor._seleccionar_color(entrada, false)
		var filas: Array = lienzo.mosaico["celdas"]
		for y in filas.size():
			for x in str(filas[y]).length():
				if lienzo.color_esperado(Vector2i(x, y)).is_equal_approx(entrada["color"]):
					lienzo.empezar_trazo(lienzo.centro_celda(Vector2i(x, y)))
					lienzo.terminar_trazo()
	_check(lienzo.celdas_correctas() == total, "%d de %d celdas con su color" % [lienzo.celdas_correctas(), total])
	_check(completa["si"], "el mosaico avisa completo (Coco dice cual es)")
	await _esperar(2.0)
	_check(motor._lamina_nombrada, "Coco nombro el dibujo secreto")


## Mezcla: echa gotas para cumplir cada pedido de Coco y pinta con la mezcla.
func _jugar_mezcla(motor) -> void:
	var recetas := {"verde": {"azul": 1, "amarillo": 1}, "naranja": {"rojo": 1, "amarillo": 1}, "violeta": {"rojo": 1, "azul": 1},
		"rosado": {"rojo": 1, "blanco": 1}, "celeste": {"azul": 1, "blanco": 1}, "cafe": {"rojo": 1, "amarillo": 1, "azul": 1},
		"lila": {"rojo": 1, "azul": 1, "blanco": 1}}
	var cumplidos := {"n": 0}
	motor.pedido_cumplido.connect(func(_id: String) -> void: cumplidos["n"] += 1)
	var total: int = motor._pedidos.size()
	for i in total:
		var pedido := str(motor._pedidos[motor._pedido_actual])
		motor._gotas = {}
		var receta: Dictionary = recetas.get(pedido, {})
		var orden: Array = receta.keys()
		for id in orden:
			for k in int(receta[id]):
				motor._agregar_gota(id)
		await _esperar(0.05)
	_check(cumplidos["n"] == total, "mezcla: %d de %d pedidos cumplidos mezclando" % [cumplidos["n"], total])
	_check(motor._mis_colores.size() > 0, "las mezclas quedan en 'mis colores' (%d)" % motor._mis_colores.size())
	await _jugar_zonas(motor, false)


func _jugar_trajes(motor, lamina: Dictionary) -> void:
	for id in lamina.get("orden_trajes", []):
		motor._elegir_traje(str(id), false)
		_check(motor._traje == str(id), "traje de Coco: %s" % id)
	await _esperar(0.1)


func _revisar_png(ruta: String, tamano: Vector2i) -> void:
	if ruta == "":
		_check(false, "se guardo el PNG del dibujo")
		return
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
	_check(imagen != null and imagen.get_size() == tamano, "PNG guardado %s (%s)" % [ruta.get_file(), imagen.get_size() if imagen != null else "ilegible"])
	if imagen != null:
		var colores := {}
		for y in range(0, tamano.y, 23):
			for x in range(0, tamano.x, 23):
				colores[imagen.get_pixel(x, y).to_html(false)] = true
		_check(colores.size() >= 3, "el PNG tiene dibujo (%d colores distintos)" % colores.size())


## Tabla de mezclas del modelo RYB: lo que ensena el colegio.
func _probar_mezclas() -> void:
	print("-- mezclas de colores (RYB) --")
	var casos := [[{"azul": 1, "amarillo": 1}, "verde"], [{"rojo": 1, "amarillo": 1}, "naranja"], [{"rojo": 1, "azul": 1}, "violeta"],
		[{"rojo": 1, "amarillo": 1, "azul": 1}, "cafe"], [{"rojo": 1, "blanco": 1}, "rosado"], [{"azul": 2, "blanco": 1}, "celeste"],
		[{"rojo": 1, "azul": 1, "blanco": 1}, "lila"], [{"rojo": 3}, "rojo"]]
	for caso in casos:
		var nombre := Colores.nombre_mezcla(caso[0])
		var color := Colores.mezclar(caso[0])
		_check(nombre == caso[1], "%s -> %s (#%s)" % [str(caso[0]), nombre, color.to_html(false)])
	var verde := Colores.mezclar({"azul": 1, "amarillo": 1})
	_check(verde.g > verde.r and verde.g > verde.b, "azul + amarillo se ve verde")
	var cafe := Colores.mezclar({"rojo": 1, "amarillo": 1, "azul": 1})
	_check(cafe.r > cafe.b and cafe.get_luminance() > 0.15, "los tres primarios dan cafe, no negro")
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
