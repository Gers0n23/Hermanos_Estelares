extends SceneTree

## Arnes QA del modo dios en el album de recuerdos (PO 10-Nov-2026): con el modo dios activo, el album
## muestra TODOS los recuerdos (fotos y huecos, tambien los de momentos que aun no existen).
## Usa un guardado temporal (user://qa_modo_dios_tmp.json): nunca toca el real ni el del modo dios.
##
## Uso: godot --headless --path . --script herramientas/qa_test_modo_dios_album.gd

const TMP := "user://qa_modo_dios_tmp.json"

var _fallos := 0


func _initialize() -> void:
	var progreso: Node = get_root().get_node("Progreso")
	var recuerdos: Node = get_root().get_node("Recuerdos")
	var total: int = recuerdos.recuerdos.size()

	# Guardado temporal: el real y el de modo dios quedan intactos.
	progreso.ruta_guardado = TMP
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	progreso.cargar()

	# 1. Sin modo dios no concede nada.
	_check(progreso.modo_dios == false, "arranca sin modo dios")
	_check(recuerdos.conceder_todos_modo_dios() == 0, "sin modo dios: no concede recuerdos")
	var visibles_normal: int = recuerdos.recuerdos_album("familia").size()

	# 2. Con modo dios: concede todos y el album los muestra.
	progreso.modo_dios = true
	_check(recuerdos.conceder_todos_modo_dios() == total, "modo dios: concede los %d recuerdos" % total)
	_check(recuerdos.conceder_todos_modo_dios() == 0, "idempotente: la segunda vez no concede nada")
	for album in ["maxi", "nicole", "sofia", "familia"]:
		var n_album := 0
		for rec in recuerdos.recuerdos:
			if str(rec.get("album", "")) == album:
				n_album += 1
		_check(recuerdos.recuerdos_album(album).size() == n_album,
			"%s: se ven los %d recuerdos del album" % [album, n_album])
	_check(recuerdos.recuerdos_album("familia").size() >= visibles_normal,
		"familia: con modo dios hay al menos tantos como sin el")

	# 3. Lo concedido queda solo en el guardado activo (el temporal).
	_check(progreso.ruta_guardado == TMP, "lo concedido se guarda en el guardado de prueba")

	# Limpieza: vuelve al estado previo y borra el temporal.
	progreso.modo_dios = false
	progreso.ruta_guardado = progreso.RUTA_GUARDADO_PRUEBAS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))

	print("RESULTADO modo dios album: %s (%d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", _fallos])
	quit(0 if _fallos == 0 else 1)


func _check(cond: bool, texto: String) -> void:
	if cond:
		print("  ok   ", texto)
	else:
		_fallos += 1
		print("  FALLO", texto)
