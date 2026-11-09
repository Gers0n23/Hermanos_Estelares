extends SceneTree

## Captura el mapa ilustrado del Planeta Animalia (HE-120) en varios momentos del avance, con el estado
## de las zonas forzado en memoria: al llegar (todo durmiendo la siesta), a mitad de camino (3 rincones
## despiertos, el desfile en el sendero y el hito de la batalla), la burbuja de estaciones, el Gran
## Desfile (inicio, mitad y Dinito naciendo) y el planeta completo con Dinito en el campamento.
## Corre con `--script`, así que `Progreso` usa el guardado de pruebas (el de los niños no se toca).
##
## Uso (necesita ventana; sin pantalla, con xvfb-run):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 \
##       --script herramientas/capturar_mapa_animalia.gd -- salida=<carpeta> [perfil=sofia]

const ANIMALIA := "res://escenas/planetas/animalia/mapa_animalia.tscn"

var _salida := ""


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=", true, 1)
		if partes.size() == 2:
			args[partes[0]] = partes[1]
	_salida = str(args.get("salida", OS.get_user_data_dir()))
	var progreso := get_root().get_node("Progreso")
	var respaldo: Dictionary = progreso._datos.duplicate(true)
	progreso.perfil_seleccionado = str(args.get("perfil", "sofia"))
	change_scene_to_file(ANIMALIA)
	await _esperar(0.6)
	var mapa := current_scene
	var paisaje: Control = mapa._paisaje
	for momento in [["1_inicio", 1, 0], ["2_mitad", 4, 3]]:
		_forzar(mapa, momento[1], momento[2])
		if momento[0] == "2_mitad":
			paisaje._batalla_visible = true
			paisaje._hito_batalla.visible = true
			paisaje._burbujas_batalla = 3
			paisaje._gemas = [0, 2]
			paisaje._huevos = 3
		await _esperar(1.5)
		await _capturar("mapa_animalia_%s" % momento[0])
	mapa._abrir_burbuja(1)
	await _esperar(1.2)
	await _capturar("mapa_animalia_2_mitad_burbuja_z2")
	mapa._cerrar_burbuja(false)
	# Planeta completo: arranca el Gran Desfile.
	_forzar(mapa, 5, 5)
	for instante in [2.5, 6.5, 9.9]:
		while paisaje.desfile_activo() and paisaje._desfile_t < instante:
			await process_frame
		await _capturar("mapa_animalia_3_desfile_%02d" % int(instante * 10))
	paisaje.terminar_desfile()
	paisaje._aurora = true
	await _esperar(1.2)
	await _capturar("mapa_animalia_4_todo_dinito")
	progreso._datos = respaldo
	progreso.guardar()
	quit()


func _forzar(mapa: Node, abiertas: int, completas: int) -> void:
	for i in mapa.zonas.size():
		mapa.zonas[i]["abierta"] = i < abiertas
		mapa.zonas[i]["completa"] = i < completas
	mapa.seleccion = mini(completas, mapa.zonas.size() - 1)
	mapa._paisaje.actualizar(mapa.zonas)
	mapa._refrescar()


func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := _salida.path_join(nombre + ".png")
	get_root().get_texture().get_image().save_png(ruta)
	print("captura -> %s" % ruta)


func _esperar(segundos: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		await process_frame
