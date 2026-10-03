extends SceneTree

## Arnes QA headless del album de recuerdos "Las migas de papa" (HE-45/46/47,
## docs/fichas/album-recuerdos.md). Cubre:
##  1. Catalogo: 14 recuerdos por hermano + 9 familiares, ids unicos, orden de edad, momentos validos.
##  2. Disponibilidad: hoy solo son huecos los momentos que existen (primer viaje, zonas 2 y 4 de
##     Arcoiris, primera apertura); planetas futuros, piezas y rescate quedan ocultos.
##  3. Migracion del guardado v1 -> v2 sin perder progreso.
##  4. Fallback: sin foto/voz real => placeholder; con archivo copiado (sin importar) => se usa.
##  5. Desbloqueo por eventos genericos, idempotencia, reglas personal/familiar, marco dorado.
##  6. Pantalla del album, entrega (sobre-estrella), mapa del planeta y burbuja del viaje.
## Respalda y restaura `user://progreso.json`.
##
## Uso: godot --headless --path . --script herramientas/qa_test_recuerdos.gd

const GUARDADO := "user://progreso.json"
const ALBUM := "res://escenas/nucleo/album_recuerdos.tscn"
const SELECCION := "res://escenas/nucleo/seleccion_personaje.tscn"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const VIAJE := "res://escenas/nucleo/viaje_estelar.tscn"
const MAPA_ARCOIRIS := "res://datos/planetas/arcoiris/mapa.json"

var _fallos := 0
var _oks := 0
var _respaldo = null
var _progreso: Node
var _recuerdos: Node


func _initialize() -> void:
	print("=== QA album de recuerdos (las migas de papa) ===")
	_progreso = get_root().get_node("Progreso")
	_recuerdos = get_root().get_node("Recuerdos")
	if FileAccess.file_exists(GUARDADO):
		_respaldo = FileAccess.get_file_as_string(GUARDADO)

	_probar_catalogo()
	_probar_disponibilidad()
	_probar_migracion()
	_probar_fallback()
	_probar_desbloqueo()
	await _probar_album()
	await _probar_entrega()
	await _probar_seleccion()
	await _probar_mapa_planeta()
	await _probar_viaje()

	if _respaldo != null:
		var archivo := FileAccess.open(GUARDADO, FileAccess.WRITE)
		archivo.store_string(_respaldo)
		archivo.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARDADO))
	_progreso.cargar()
	print("=== RESULTADO: %s (%d OK, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame


func _reiniciar_progreso() -> void:
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()


func _ids(lista: Array) -> Array:
	return lista.map(func(r: Dictionary) -> String: return str(r["id"]))


# ---------------------------------------------------------------------------

func _probar_catalogo() -> void:
	print("-- 1. catalogo --")
	var lista: Array = _recuerdos.recuerdos
	_check(lista.size() == 51, "51 recuerdos en el catalogo (%d)" % lista.size())
	var vistos := {}
	var unicos := true
	var por_album := {"maxi": [], "nicole": [], "sofia": [], "familia": []}
	var tipos_ok := true
	for rec in lista:
		unicos = unicos and not vistos.has(rec["id"])
		vistos[rec["id"]] = true
		por_album[str(rec["album"])].append(rec)
		tipos_ok = tipos_ok and str(rec["momento"]["tipo"]) in ["primera_apertura", "viaje", "zona_completa", "pieza_nave", "rescate_final"]
	_check(unicos, "ids unicos")
	_check(tipos_ok, "todos los momentos tienen un tipo valido")
	for hermano in ["maxi", "nicole", "sofia"]:
		var suyos: Array = por_album[hermano]
		var orden_ok := true
		var edad_ok := true
		for k in suyos.size():
			orden_ok = orden_ok and int(suyos[k]["orden"]) == k + 1 and str(suyos[k]["id"]) == "%s_%02d" % [hermano, k + 1]
			edad_ok = edad_ok and str(suyos[k].get("edad", "")) != ""
		_check(suyos.size() == 14 and orden_ok, "%s: 14 recuerdos %s_01..14 en orden de edad" % [hermano, hermano])
		_check(edad_ok, "%s: cada recuerdo trae su edad sugerida" % hermano)
	_check(por_album["familia"].size() == 9, "9 recuerdos familiares")
	_check(str(_recuerdos.obtener("familia_01")["momento"]["tipo"]) == "primera_apertura", "familia_01 = primera apertura")
	_check(str(_recuerdos.obtener("maxi_01")["momento"]["tipo"]) == "viaje", "maxi_01 = primer despegue (viaje)")
	_check(str(_recuerdos.obtener("sofia_02")["momento"].get("zona", "")) == "zona2_charcos"
		and str(_recuerdos.obtener("sofia_03")["momento"].get("zona", "")) == "zona4_islotes", "zonas 2 y 4 de Arcoiris dan la 2a y 3a foto")


func _probar_disponibilidad() -> void:
	print("-- 2. disponibilidad (huecos visibles) --")
	_reiniciar_progreso()
	for hermano in ["maxi", "nicole", "sofia"]:
		var ids := _ids(_recuerdos.recuerdos_album(hermano))
		_check(ids == ["%s_01" % hermano, "%s_02" % hermano, "%s_03" % hermano], "%s: hoy se ven 3 huecos (%s)" % [hermano, str(ids)])
	_check(_ids(_recuerdos.recuerdos_album("familia")) == ["familia_01"], "familia: solo la primera apertura")
	_check(not _recuerdos.esta_disponible(_recuerdos.obtener("maxi_04")), "planetas futuros sin mapa: ocultos")
	_check(not _recuerdos.esta_disponible(_recuerdos.obtener("familia_02")), "pieza de nave: oculta hasta que exista su escena")
	_check(not _recuerdos.esta_disponible(_recuerdos.obtener("familia_09")), "rescate final: oculto")


func _probar_migracion() -> void:
	print("-- 3. migracion v1 -> v2 --")
	var viejo := {
		"version": 1,
		"perfiles": {
			"maxi": {"id": "maxi", "nombre": "Maxi", "perfil_dificultad": "semilla", "destellos_totales": 7,
				"piezas_nave": [], "planetas": {"arcoiris": {"destellos": 7, "niveles": {"nivel_x": {"completado": true, "estrellitas": 0}}}},
				"volumenes": {"Musica": 0.5, "SFX": 1.0, "Voz": 1.0}, "ubicacion_nave": "arcoiris"},
		},
	}
	var archivo := FileAccess.open(GUARDADO, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(viejo))
	archivo.close()
	_progreso.cargar()
	_check(_progreso.VERSION_ACTUAL == 2, "VERSION_ACTUAL = 2")
	_check(_progreso._datos.get("version") == 2, "los datos quedan en version 2")
	_check(_progreso._datos.get("recuerdos_encontrados") is Dictionary and _progreso._datos["recuerdos_encontrados"].is_empty(), "migracion agrega recuerdos_encontrados vacio")
	_check(_progreso.obtener_destellos_totales("maxi") == 7 and _progreso.esta_nivel_completado("maxi", "arcoiris", "nivel_x"), "destellos y niveles de Maxi intactos")
	_check(_progreso.obtener_ubicacion_nave("maxi") == "arcoiris" and is_equal_approx(_progreso.obtener_volumen("maxi", "Musica"), 0.5), "ubicacion de la nave y volumen intactos")
	_check(_progreso.obtener_ids_perfiles().size() == 3, "se completan los perfiles faltantes")
	var en_disco: Variant = JSON.parse_string(FileAccess.get_file_as_string(GUARDADO))
	_check(en_disco is Dictionary and int(en_disco.get("version", 0)) == 2 and en_disco.has("recuerdos_encontrados"), "el archivo en disco quedo en v2")
	# un guardado v2 con recuerdos se conserva tal cual al recargar
	_progreso.registrar_recuerdo("familia_01", "")
	_progreso.cargar()
	_check(_progreso.tiene_recuerdo("familia_01"), "los recuerdos sobreviven a recargar el guardado")


func _probar_fallback() -> void:
	print("-- 4. fallback a placeholders y archivos reales copiados --")
	var falso := {"id": "qa_recuerdo_prueba", "album": "maxi", "orden": 1}
	_check(_recuerdos.ruta_foto_real(falso) == "" and _recuerdos.textura_foto(falso) == null, "sin foto real => null (la UI usa el placeholder)")
	_check(_recuerdos.stream_voz(falso) == null, "sin voz real => null")
	for album in ["maxi", "nicole", "sofia", "familia"]:
		var imagen: Dictionary = _recuerdos.imagen_placeholder(album)
		_check(not imagen.is_empty() and imagen["textura"] != null, "placeholder de %s disponible" % album)
	_check(not _recuerdos.imagen_hueco().is_empty(), "imagen del hueco (hermanos_alturas) disponible")
	# El PO copia un archivo sin abrir el editor (no importado): se lee directo del disco.
	var carpeta_fotos := ProjectSettings.globalize_path("res://assets/recuerdos/fotos/")
	var carpeta_voces := ProjectSettings.globalize_path("res://assets/recuerdos/voces/")
	DirAccess.make_dir_recursive_absolute(carpeta_fotos)
	DirAccess.make_dir_recursive_absolute(carpeta_voces)
	var ruta_png := carpeta_fotos.path_join("qa_recuerdo_prueba.png")
	var imagen := Image.create(64, 48, false, Image.FORMAT_RGB8)
	imagen.fill(Color.ORANGE)
	imagen.save_png(ruta_png)
	var ruta_wav := carpeta_voces.path_join("qa_recuerdo_prueba.wav")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var datos := PackedByteArray()
	datos.resize(22050)
	wav.data = datos
	wav.save_to_wav(ruta_wav)
	_recuerdos._cache_texturas.clear()
	var textura: Texture2D = _recuerdos.textura_foto(falso)
	_check(textura != null and textura.get_width() == 64, "foto real copiada => se usa (%s)" % _recuerdos.ruta_foto_real(falso))
	_check(_recuerdos.stream_voz(falso) != null, "voz real copiada (.wav) => se usa")
	DirAccess.remove_absolute(ruta_png)
	DirAccess.remove_absolute(ruta_wav)
	_recuerdos._cache_texturas.clear()
	_check(_recuerdos.textura_foto(falso) == null, "al borrar la foto vuelve el placeholder")
	_check(_recuerdos.ruta_linea("recuerdos_entrega_01") == "" or ResourceLoader.exists(_recuerdos.ruta_linea("recuerdos_entrega_01")), "lineas de Cometa sin grabar => silencio (sin error)")
	var arco: Dictionary = _recuerdos.obtener("maxi_02")
	_check(_recuerdos.ruta_pista(arco) != "", "pista de un hueco de Arcoiris: usa una linea de Cometa existente mientras falta la suya")


func _probar_desbloqueo() -> void:
	print("-- 5. desbloqueo por eventos genericos --")
	_reiniciar_progreso()
	var primera: Array = _recuerdos.desbloquear({"tipo": "primera_apertura"}, "")
	_check(_ids(primera) == ["familia_01"], "primera apertura => familia_01")
	_check(_recuerdos.desbloquear({"tipo": "primera_apertura"}, "sofia").is_empty(), "idempotente: la primera apertura no se repite (ni con otro hermano)")
	var viaje := {"tipo": "viaje", "origen": "tierra", "destino": "arcoiris"}
	_check(_ids(_recuerdos.pendientes(viaje, "maxi")) == ["maxi_01"], "pendientes del primer viaje de Maxi: maxi_01 (sin guardar)")
	_check(not _progreso.tiene_recuerdo("maxi_01"), "pendientes() no guarda nada")
	_check(_ids(_recuerdos.desbloquear(viaje, "maxi")) == ["maxi_01"], "primer viaje de Maxi => maxi_01")
	_check(_recuerdos.desbloquear(viaje, "maxi").is_empty(), "segundo viaje de Maxi: nada repetido")
	# HE-44 #7: con tope, lo que no cabe NO se guarda y llega la proxima vez.
	_check(_recuerdos.desbloquear(viaje, "nicole", 0).is_empty() and not _progreso.tiene_recuerdo("nicole_01"), "HE-44 #7: con tope 0 no se entrega ni se guarda nada")
	_check(_ids(_recuerdos.desbloquear(viaje, "nicole")) == ["nicole_01"], "primer viaje de Nicole => nicole_01 (personal)")
	var zona2 := {"tipo": "zona_completa", "planeta": "arcoiris", "zona": "zona2_charcos", "numero": 2, "perfecta": false}
	_check(_ids(_recuerdos.desbloquear(zona2, "maxi")) == ["maxi_02"], "zona 2 de Arcoiris (Maxi) => maxi_02")
	_check(_recuerdos.desbloquear({"tipo": "zona_completa", "planeta": "arcoiris", "zona": "zona1_claro", "numero": 1}, "maxi").is_empty(), "zona 1 no da foto")
	_check(not _progreso.tiene_recuerdo("nicole_02"), "la zona de Maxi no le da la foto de Nicole")
	var zona4_perfecta := {"tipo": "zona_completa", "planeta": "arcoiris", "zona": "zona4_islotes", "numero": 4, "perfecta": true}
	var sofia: Array = _recuerdos.desbloquear(zona4_perfecta, "sofia")
	_check(_ids(sofia) == ["sofia_03"] and bool(sofia[0]["_dorado"]) and not bool(sofia[0]["_solo_dorado"]), "zona 4 perfecta de Sofia => sofia_03 con marco dorado")
	_check(_recuerdos.desbloquear(zona4_perfecta, "sofia").is_empty(), "repetir la zona perfecta no re-entrega")
	_recuerdos.desbloquear(zona2, "sofia")
	var dorado_despues: Array = _recuerdos.desbloquear({"tipo": "zona_completa", "planeta": "arcoiris", "zona": "zona2_charcos", "numero": 2, "perfecta": true}, "sofia")
	_check(_ids(dorado_despues) == ["sofia_02"] and bool(dorado_despues[0]["_solo_dorado"]), "estrellitas maximas despues: la foto ya estaba, solo gana el marco dorado")
	_check(_recuerdos.contar("maxi") == [2, 3] and _recuerdos.contar("familia") == [1, 1], "conteo de Maxi 2/3 y familia 1/1")
	_check(_recuerdos.hay_nuevos() and _recuerdos.album_tiene_nuevos("maxi"), "hay fotos nuevas sin ver (brillo)")
	for id in _progreso.obtener_recuerdos_encontrados().keys():
		_recuerdos.marcar_visto(str(id))
	_check(not _recuerdos.hay_nuevos(), "al verlas se apaga el brillo")
	_progreso.cargar()
	_check(_progreso.tiene_recuerdo("maxi_02") and _progreso.obtener_recuerdos_encontrados()["sofia_03"]["dorado"], "todo quedo guardado en disco")
	_check(str(_progreso.obtener_recuerdos_encontrados()["maxi_01"]["quien"]) == "maxi", "se guarda quien encontro cada foto")


func _probar_album() -> void:
	print("-- 6a. pantalla del album --")
	_reiniciar_progreso()
	_recuerdos.desbloquear({"tipo": "primera_apertura"}, "")
	_recuerdos.desbloquear({"tipo": "viaje", "origen": "tierra", "destino": "arcoiris"}, "maxi")
	change_scene_to_file(ALBUM)
	await _esperar(0.3)
	var album := current_scene
	_check(album != null and album.vista == "portada", "el album abre en la portada")
	if album == null:
		return
	_check(album._tapas.size() == 4, "4 tapas (Maxi, Nicole, Sofia, Familia)")
	var grandes := true
	for tapa in album._tapas.values():
		grandes = grandes and tapa.size.x >= 180.0 and tapa.size.y >= 180.0
	_check(grandes, "tapas >= 180 px")
	_check(album._boton_volver.size.x >= 96.0, "boton volver >= 96 px")
	album.abrir_album("maxi")
	await _esperar(0.1)
	_check(album.vista == "pagina" and album.album_abierto == "maxi", "tocar la tapa de Maxi abre su album")
	var visibles: Array = album._celdas.filter(func(c: Control) -> bool: return c.visible)
	_check(visibles.size() == 3, "3 polaroids en la pagina de Maxi (%d)" % visibles.size())
	_check(visibles.size() == 3 and not visibles[0].hueco and visibles[1].hueco and visibles[2].hueco, "maxi_01 encontrada; 02 y 03 son huecos")
	_check(visibles.size() == 3 and visibles[0].size.x >= 180.0 and visibles[0].size.y >= 180.0, "miniaturas >= 180 px (%s)" % str(visibles[0].size if visibles.size() > 0 else ""))
	_check(visibles.size() == 3 and not visibles[0].tiene_foto_real(), "sin foto real: placeholder del personaje")
	_check(visibles.size() == 3 and visibles[0].nuevo and _progreso.obtener_recuerdos_encontrados()["maxi_01"]["visto"], "la foto nueva brilla y queda marcada como vista")
	var pantalla := Rect2(0, 0, 1280, 720)
	var dentro := true
	for celda in visibles:
		dentro = dentro and pantalla.encloses(celda.get_global_rect())
	_check(dentro, "la cuadricula 2x3 cabe en 1280x720")
	_check(not album._flecha_der.visible, "una sola pagina: sin flechas")
	album._tocar_celda(1)
	_check(album.vista == "pagina", "tocar un hueco no abre nada (solo pista + meneo)")
	album._tocar_celda(0)
	_check(album.vista == "foto" and album._capa_foto.visible, "tocar una foto encontrada la abre grande")
	_check(album._foto_grande.size.y >= 600.0, "foto abierta grande (%d px de alto)" % int(album._foto_grande.size.y))
	album.volver()
	_check(album.vista == "pagina", "volver cierra la foto")
	# UX HE-44 R6: la foto actua al soltar; un toque corto la abre.
	album._al_tocar_celda(_clic(Vector2(400, 300), true), 0)
	album._al_tocar_celda(_clic(Vector2(406, 303), false), 0)
	_check(album.vista == "foto", "R6: presionar y soltar casi sin moverse abre la foto")
	album.volver()
	# UX HE-44 R10: boton de Cometa de 116 px que repite la instruccion, sin tapar nada.
	var cometa: Rect2 = album._boton_cometa.get_global_rect()
	var libre := cometa.size.x >= 116.0 and pantalla.encloses(cometa)
	for nodo in visibles + album._tapas.values() + [album._flecha_der, album._boton_volver]:
		libre = libre and not nodo.get_global_rect().intersects(cometa)
	_check(libre, "R10: boton de Cometa de 116 px dentro de la pantalla y sin tapar fotos, tapas ni flechas")
	album.repetir_instruccion()
	_check(album.vista == "pagina", "R10: tocar a Cometa en la pagina repite la instruccion (no navega)")
	album.volver()
	_check(album.vista == "portada", "volver de la pagina lleva a la portada")
	album.repetir_instruccion()
	_check(album.vista == "portada", "R10: tocar a Cometa en la portada repite la invitacion")
	album.abrir_album("familia")
	_check(album._celdas[0].visible and not album._celdas[0].hueco, "album familiar con la foto de la primera apertura")
	# UX HE-44 R6: deslizar empezando SOBRE una foto pasa de pagina (no la abre).
	var pagina_esperada: int = mini(1, album.paginas() - 1)
	album._al_tocar_celda(_clic(Vector2(700, 300), true), 0)
	album._al_tocar_celda(_clic(Vector2(560, 310), false), 0)
	_check(album.vista == "pagina" and album.pagina == pagina_esperada,
		"R6: deslizar sobre una foto no la abre y pasa de pagina si hay otra (pagina %d de %d)" % [album.pagina + 1, album.paginas()])
	album.volver()
	album.volver()
	await _esperar(0.2)
	_check(current_scene != null and current_scene.scene_file_path == SELECCION, "volver desde la portada lleva a la seleccion de personaje")


func _clic(punto: Vector2, presionado: bool) -> InputEventMouseButton:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = presionado
	evento.position = punto
	evento.global_position = punto
	return evento


func _probar_entrega() -> void:
	print("-- 6b. entrega (sobre-estrella) --")
	var terminada := [false]
	var rec: Dictionary = _recuerdos.obtener("maxi_02").duplicate()
	rec["_quien"] = "maxi"
	var entrega: Node = load("res://scripts/ui/entrega_recuerdo.gd").crear([rec])
	entrega.terminada.connect(func() -> void: terminada[0] = true)
	get_root().add_child(entrega)
	await _esperar(0.3)
	_check(entrega.estado() == "entrando", "el sobre baja girando")
	_check(entrega._sobre.size.x > 200.0, "sobre-estrella grande (> 200 px)")
	_check(entrega.destino_album == entrega.DESTINO_ALBUM, "UX HE-44 R8: sin boton propio, la foto vuela abajo a la derecha, donde vive el album")
	_check(entrega._abrir_en >= entrega.AUTO_ABRIR and entrega._abrir_en <= entrega.TOPE_ABRIR, "HE-44 #2: el sobre se abre tras la frase de Cometa, entre 3 y 6 s (%.1f s)" % entrega._abrir_en)
	await _esperar(entrega.BAJADA + entrega._abrir_en + 0.3)
	_check(entrega.estado() in ["abriendo", "foto"], "sin toque, se abre solo (%s)" % entrega.estado())
	await _esperar(0.7)
	_check(entrega._foto != null and entrega._foto.size.y >= 480.0, "la polaroid ocupa ~70% del alto")
	_check(entrega._hay_audio_foto, "HE-44 UX R1: la foto tiene voz (pie narrado + linea de Cometa mientras falta la familia)")
	# Maxi toca muchas veces seguidas: la foto NO se va antes de terminar su audio (HE-44 #1, UX R2).
	for k in 10:
		entrega.avanzar()
		await _esperar(0.1)
	_check(entrega.estado() == "foto", "10 toques seguidos no se saltan la foto ni su voz (%s)" % entrega.estado())
	var t0 := Time.get_ticks_msec()
	while entrega.estado() == "foto" and Time.get_ticks_msec() - t0 < 16000:
		await _esperar(0.2)
	var dur := (Time.get_ticks_msec() - t0) / 1000.0
	_check(entrega._audio_termino_en >= 0.0, "la foto espero a que terminara su audio")
	await _esperar(2.6)
	_check(terminada[0], "en Semilla la foto se va sola tras su audio (+1,5 s) y la entrega termina (%.1f s)" % dur)
	# un toque temprano abre el sobre apenas llega
	terminada[0] = false
	var entrega2: Node = load("res://scripts/ui/entrega_recuerdo.gd").crear([rec, _recuerdos.obtener("familia_01")])
	entrega2.terminada.connect(func() -> void: terminada[0] = true)
	get_root().add_child(entrega2)
	await _esperar(0.2)
	entrega2.avanzar()
	await _esperar(1.3)
	_check(entrega2.estado() in ["abriendo", "foto"], "un toque en cualquier parte abre el sobre")
	await _esperar(0.3)
	entrega2.avanzar()
	await _esperar(0.3)
	_check(entrega2.estado() == "foto", "un toque antes de que termine el audio no guarda la foto")
	var t1 := Time.get_ticks_msec()
	while entrega2.estado() == "foto" and Time.get_ticks_msec() - t1 < 16000:
		if entrega2.foto_lista() and not entrega2._es_semilla():
			entrega2.avanzar()
		await _esperar(0.1)
	await _esperar(1.2)
	_check(entrega2.esta_activa() and entrega2.estado() in ["entrando", "sobre", "abriendo", "foto"], "con dos fotos llega el segundo sobre (%s)" % entrega2.estado())
	_check(entrega2._mostrados == 2 and entrega2._linea_sobre().contains("otra_"), "HE-44 #7: desde el 2.o sobre Cometa dice la linea corta (%s)" % entrega2._linea_sobre().get_file())
	_check(entrega2._velo.color.a > 0.5, "HE-44 #7: el velo sigue puesto entre recuerdos")
	_check(entrega2.TOPE_SOBRES == 3, "HE-44 #7: tope de 3 sobres por entrega")
	var t2 := Time.get_ticks_msec()
	while not terminada[0] and Time.get_ticks_msec() - t2 < 25000:
		await _esperar(0.25)
	_check(terminada[0], "sin tocar nada, la entrega de dos fotos termina sola")
	# HE-44 #8: solo marco dorado (Sofia ya tenia la foto): sin sobre, el marco se dibuja alrededor.
	terminada[0] = false
	var dorado: Dictionary = _recuerdos.obtener("sofia_02").duplicate()
	dorado["_quien"] = "sofia"
	dorado["_dorado"] = true
	dorado["_solo_dorado"] = true
	var entrega3: Node = load("res://scripts/ui/entrega_recuerdo.gd").crear([dorado])
	entrega3.terminada.connect(func() -> void: terminada[0] = true)
	get_root().add_child(entrega3)
	await _esperar(0.3)
	_check(not entrega3._sobre.visible and entrega3._foto != null and is_instance_valid(entrega3._marco), "HE-44 #8: solo marco dorado -> sin sobre, la foto aparece directo con su marco")
	_check(entrega3._progreso_marco > 0.0 and entrega3._progreso_marco < 1.0, "HE-44 #8: el marco se va dibujando (%.2f)" % entrega3._progreso_marco)
	await _esperar(entrega3.DIBUJO_MARCO + 0.2)
	_check(is_equal_approx(entrega3._progreso_marco, 1.0) and entrega3.estado() == "foto", "HE-44 #8: en 1,2 s el marco queda completo (%s)" % entrega3.estado())
	var t3 := Time.get_ticks_msec()
	while not terminada[0] and Time.get_ticks_msec() - t3 < 10000:
		await _esperar(0.25)
	_check(terminada[0], "HE-44 #8: la foto dorada vuela al album y la entrega termina sola")


func _probar_seleccion() -> void:
	print("-- 6c. seleccion de personaje: boton del album y primera apertura --")
	_reiniciar_progreso()
	change_scene_to_file(SELECCION)
	await _esperar(0.3)
	var seleccion := current_scene
	_check(seleccion._boton_album != null and seleccion._boton_album.size.x >= 96.0 and seleccion._boton_album.size.y >= 96.0, "boton del album >= 96 px")
	_check(Rect2(0, 0, 1280, 720).encloses(seleccion._boton_album.get_global_rect()), "boton del album dentro de la pantalla")
	var choca := false
	for nombre in ["tarjeta_maxi", "tarjeta_nicole", "tarjeta_sofia", "boton_volver", "burbuja_ayuda"]:
		var nodo: Control = seleccion.get_node(nombre)
		choca = choca or Rect2(nodo.global_position, nodo.size).intersects(seleccion._boton_album.get_global_rect())
	_check(not choca, "el boton del album no choca con tarjetas ni botones")
	var sofia: Control = seleccion.get_node("tarjeta_sofia")
	var separacion: float = seleccion._boton_album.global_position.y - (sofia.global_position.y + sofia.size.y)
	_check(separacion >= 36.0, "UX HE-44 R7: el album queda a >= 36 px de la tarjeta de Sofia (%d px)" % int(separacion))
	_check(_progreso.tiene_recuerdo("familia_01") and seleccion._entrega != null, "primera apertura: llega el sobre con familia_01")
	_check(seleccion._bloqueado, "mientras llega el sobre no se elige personaje por accidente")
	# La foto espera a que termine su voz (HE-44): se espera la entrega entera, con tope.
	var t_sel := Time.get_ticks_msec()
	while seleccion._entrega != null and Time.get_ticks_msec() - t_sel < 40000:
		await _esperar(0.25)
	await _esperar(0.3)
	_check(seleccion._entrega == null and not seleccion._bloqueado, "al terminar la entrega la seleccion vuelve a responder")
	_check(seleccion._boton_album.nuevos, "el boton del album brilla: hay una foto nueva")
	change_scene_to_file(SELECCION)
	await _esperar(0.3)
	_check(current_scene._entrega == null, "la segunda vez no hay sobre (idempotente)")
	current_scene._boton_album.tocado.emit()
	await _esperar(0.3)
	_check(current_scene != null and current_scene.scene_file_path == ALBUM, "tocar el libro abre el album")


func _probar_mapa_planeta() -> void:
	print("-- 6d. mapa del planeta: zona completa => foto --")
	_reiniciar_progreso()
	_progreso.perfil_seleccionado = "maxi"
	var mapa_json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAPA_ARCOIRIS))
	for zona in mapa_json["zonas"]:
		if int(zona["numero"]) > 2:
			continue
		for estacion in zona["estaciones"]:
			var ruta := str(estacion.get("niveles", {}).get("maxi", ""))
			if ruta == "" or not FileAccess.file_exists(ruta) or not ResourceLoader.exists(str(estacion.get("escena", ""))):
				continue
			var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
			_progreso.marcar_nivel_completado("maxi", "arcoiris", str(nivel.get("id_nivel", ruta.get_file().get_basename())), 1)
	change_scene_to_file(ARCOIRIS)
	await _esperar(0.4)
	var mapa := current_scene
	_check(mapa.zonas[1]["completa"], "zona 2 de Maxi completa")
	_check(not _progreso.tiene_recuerdo("maxi_02"), "la foto se guarda recien al mostrarse (no antes)")
	# El mapa espera la celebracion completa (bienvenida / zona / regalo) antes del sobre (HE-44 #10).
	var t_mapa := Time.get_ticks_msec()
	while mapa.get_node_or_null("entrega_recuerdo") == null and Time.get_ticks_msec() - t_mapa < 30000:
		await _esperar(0.25)
	_check(_progreso.tiene_recuerdo("maxi_02"), "zona 2 completa => maxi_02 encontrada")
	_check(not _progreso.tiene_recuerdo("maxi_03"), "zona 4 aun no => maxi_03 sigue escondida")
	_check(mapa.get_node_or_null("entrega_recuerdo") != null, "llega el sobre-estrella sobre el mapa")
	change_scene_to_file(ARCOIRIS)
	await _esperar(3.0)
	_check(current_scene.get_node_or_null("entrega_recuerdo") == null, "volver al mapa no repite la foto")


func _probar_viaje() -> void:
	print("-- 6e. viaje estelar: burbuja-recuerdo --")
	_reiniciar_progreso()
	_progreso.perfil_seleccionado = "nicole"
	var viaje: Node = (load(VIAJE) as PackedScene).instantiate()
	viaje.planeta_origen = "tierra"
	viaje.planeta_destino = "arcoiris"
	get_root().add_child(viaje)
	await _esperar(0.2)
	_check(viaje.hay_burbuja_pendiente(), "primer viaje de Nicole: hay burbuja-recuerdo pendiente")
	viaje._fase = "viaje"
	viaje._burbuja = {"pos": Vector2(200, 90), "fase": 0.0}
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = Vector2(200, 90) * viaje.ESCALA
	viaje._unhandled_input(toque)
	_check(_progreso.tiene_recuerdo("nicole_01"), "tocar la burbuja la atrapa => nicole_01")
	_check(viaje._entrega != null, "el viaje se detiene y llega el sobre-estrella")
	var t_antes: float = viaje._t
	await _esperar(0.5)
	_check(is_equal_approx(viaje._t, t_antes), "el viaje queda en pausa durante la entrega")
	var t_viaje := Time.get_ticks_msec()
	while viaje._entrega != null and Time.get_ticks_msec() - t_viaje < 40000:
		await _esperar(0.25)
	await _esperar(0.3)
	_check(viaje._entrega == null and viaje._t > t_antes, "al terminar la entrega el viaje sigue")
	viaje.queue_free()
	await _esperar(0.1)
	var viaje2: Node = (load(VIAJE) as PackedScene).instantiate()
	viaje2.planeta_origen = "arcoiris"
	viaje2.planeta_destino = "tierra"
	get_root().add_child(viaje2)
	await _esperar(0.2)
	_check(not viaje2.hay_burbuja_pendiente(), "segundo viaje: la burbuja no se repite")
	viaje2.queue_free()
	await _esperar(0.1)
