extends SceneTree
## QA de la narracion de Cometa (datos/historia/narracion.json + cola de voces de `Audio`).
## 1) Toda linea del catalogo existe y carga. 2) La cola dice las lineas en orden y un `reproducir_voz`
## la corta. 3) El titulo y el Mapa Estelar arrancan narrando sin errores (guardado de pruebas: el
## arnes corre con --script, asi que Progreso usa RUTA_GUARDADO_PRUEBAS).
## Uso: godot --headless --path . --script res://herramientas/qa_test_narracion.gd

var _ok := 0
var _fallas := 0


func _initialize() -> void:
	_revisar_catalogo()
	await process_frame
	await _revisar_cola()
	await _revisar_escena("res://escenas/nucleo/titulo.tscn")
	await _revisar_escena("res://escenas/nucleo/mapa_estelar.tscn")
	print("qa_test_narracion: %d OK / %d fallas" % [_ok, _fallas])
	quit(1 if _fallas > 0 else 0)


func _revisar_catalogo() -> void:
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/historia/narracion.json"))
	if not datos is Dictionary:
		_falla("narracion.json no se pudo leer")
		return
	for momento in datos["momentos"]:
		var lineas := Narracion.lineas(momento)
		if lineas.is_empty():
			_falla("momento sin lineas: %s" % momento)
		for ruta in lineas:
			if not ResourceLoader.exists(ruta) or load(ruta) == null:
				_falla("no existe: %s (%s)" % [ruta, momento])
			else:
				_ok += 1


func _revisar_cola() -> void:
	var audio: Node = root.get_node("Audio")
	var lineas := Narracion.lineas("menu:seleccion_maxi") + Narracion.lineas("menu:mapa_lejos")
	audio.reproducir_voces(lineas, 0.05)
	_afirmar(audio.esta_hablando(), "la cola empieza a hablar")
	var primera: AudioStream = audio._reproductor_voz.stream
	var limite := Time.get_ticks_msec() + 15000
	while audio._reproductor_voz.stream == primera and Time.get_ticks_msec() < limite:
		await process_frame
	_afirmar(audio._reproductor_voz.stream != primera and audio._reproductor_voz.playing, "pasa a la 2.a linea")
	audio.reproducir_voces(lineas)
	audio.reproducir_voz(lineas[1])
	_afirmar(audio._cola_voces.is_empty(), "reproducir_voz corta la cola")
	audio.detener_voz()
	_afirmar(not audio.esta_hablando(), "detener_voz deja todo en silencio")


func _revisar_escena(ruta: String) -> void:
	var escena: Node = (load(ruta) as PackedScene).instantiate()
	root.add_child(escena)
	for i in 10:
		await process_frame
	_afirmar(root.get_node("Audio").esta_hablando(), "%s arranca con Cometa hablando" % ruta.get_file())
	escena.queue_free()
	root.get_node("Audio").detener_voz()
	await process_frame


func _afirmar(condicion: bool, que: String) -> void:
	if condicion:
		_ok += 1
	else:
		_falla(que)


func _falla(mensaje: String) -> void:
	_fallas += 1
	print("FALLA: " + mensaje)
