extends SceneTree

## Arnés QA del modo dios (Ajustes + PIN, decisión del PO 10-Nov-2026).
## Verifica: PIN incorrecto no activa nada; el correcto cambia al guardado aparte (`progreso_dios.json`) sin
## tocar el real ni el de pruebas; con el modo activo están abiertos los planetas del Mapa Estelar, todas
## las zonas de Arcoíris y Animalia, "¡Juntos!" y el hito de la batalla de Animalia; la pantalla de Ajustes
## pide el PIN antes de mostrar el panel; el título lleva a Ajustes; apagar vuelve al guardado anterior; y
## "borrar guardado de prueba" borra solo el del modo dios.
##
## Uso: godot --headless --path . --script herramientas/qa_test_modo_dios.gd

const REAL := "user://progreso.json"
const PRUEBAS := "user://progreso_pruebas.json"
const DIOS := "user://progreso_dios.json"
const ARCOIRIS := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const ANIMALIA := "res://escenas/planetas/animalia/mapa_animalia.tscn"
const MAPA_ESTELAR := "res://escenas/nucleo/mapa_estelar.tscn"
const AJUSTES := "res://escenas/nucleo/ajustes.tscn"
const TITULO := "res://escenas/nucleo/titulo.tscn"

var _fallos := 0
var _oks := 0
var _progreso: Node
var _respaldo_dios = null


func _initialize() -> void:
	print("=== QA modo dios ===")
	_progreso = get_root().get_node("Progreso")
	var md5_real := _md5(REAL)
	if FileAccess.file_exists(DIOS):
		_respaldo_dios = FileAccess.get_file_as_string(DIOS)
	_progreso.borrar_guardado_dios()
	_check(_progreso.ruta_guardado == PRUEBAS, "el arnés parte en el guardado de pruebas")
	_progreso._datos = _progreso._crear_datos_por_defecto()
	_progreso.guardar()
	var md5_pruebas := _md5(PRUEBAS)

	# PIN
	_check(not _progreso.activar_modo_dios("0000") and not _progreso.modo_dios, "PIN incorrecto no activa el modo dios")
	_check(_progreso.ruta_guardado == PRUEBAS, "PIN incorrecto no cambia el guardado")
	_check(_progreso.activar_modo_dios(_progreso.PIN_MODO_DIOS) and _progreso.modo_dios, "PIN correcto activa el modo dios")
	_check(_progreso.ruta_guardado == DIOS and FileAccess.file_exists(DIOS), "el modo dios usa su propio guardado")
	_progreso.agregar_destellos("sofia", "arcoiris", 77)
	_check(_md5(PRUEBAS) == md5_pruebas and _md5(REAL) == md5_real, "jugar en modo dios no toca los otros guardados")
	_check(_progreso.modo_equipo_desbloqueado(), "\"¡Juntos!\" disponible en modo dios")

	await _probar_mapas()
	await _probar_ajustes()
	await _probar_titulo()

	# Apagar y borrar
	_progreso.desactivar_modo_dios()
	_check(not _progreso.modo_dios and _progreso.ruta_guardado == PRUEBAS, "apagar vuelve al guardado anterior")
	_check(_progreso.obtener_destellos_totales("sofia") == 0, "los destellos del modo dios no aparecen en el guardado normal")
	_check(not _progreso.modo_equipo_desbloqueado(), "apagado, \"¡Juntos!\" vuelve a depender de la batalla")
	_progreso.borrar_guardado_dios()
	_check(not FileAccess.file_exists(DIOS), "borrar guardado de prueba elimina solo el del modo dios")
	_check(FileAccess.file_exists(PRUEBAS) and _md5(REAL) == md5_real, "el guardado real sigue intacto")

	if _respaldo_dios != null:
		var f := FileAccess.open(DIOS, FileAccess.WRITE)
		f.store_string(_respaldo_dios)
		f.close()
	print("=== RESULTADO: %s (%d OK, %d fallos) ===" % ["OK" if _fallos == 0 else "FALLA", _oks, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_mapas() -> void:
	var estelar: Node = load(MAPA_ESTELAR).instantiate()
	get_root().add_child(estelar)
	await process_frame
	var total := 0
	for datos: Dictionary in estelar.PLANETAS:
		if str(datos.get("mapa", "")) != "" and ResourceLoader.exists(str(datos["mapa"])):
			total += 1
	_check(estelar.planetas_desbloqueados() >= 2 and estelar.planetas_desbloqueados() == total,
		"Mapa Estelar: todos los planetas con mapa abiertos (%d)" % estelar.planetas_desbloqueados())
	_check(estelar.indice_destino_en_espera() == -1, "Mapa Estelar: ningún destino en espera")
	estelar.queue_free()
	await process_frame

	for ruta in [ARCOIRIS, ANIMALIA]:
		for perfil in ["maxi", "nicole", "sofia"]:
			_progreso.seleccionar_perfil(perfil)
			var mapa: Node = load(ruta).instantiate()
			get_root().add_child(mapa)
			await process_frame
			var abiertas := 0
			for zona: Dictionary in mapa.zonas:
				abiertas += 1 if zona["abierta"] else 0
			_check(mapa.zonas.size() > 0 and abiertas == mapa.zonas.size(),
				"%s/%s: todas las zonas abiertas (%d/%d)" % [mapa.planeta_id, perfil, abiertas, mapa.zonas.size()])
			if ruta == ANIMALIA:
				_check(mapa._paisaje.hito_batalla_visible(), "animalia/%s: hito de la batalla visible" % perfil)
			mapa.queue_free()
			await process_frame


func _probar_ajustes() -> void:
	var ajustes: Node = load(AJUSTES).instantiate()
	get_root().add_child(ajustes)
	await process_frame
	_check(not ajustes.panel_visible(), "Ajustes abre pidiendo el PIN")
	for d in "1357":
		ajustes.ingresar_digito(d)
	_check(not ajustes.panel_visible(), "Ajustes: PIN incorrecto no muestra el panel")
	for d in _progreso.PIN_MODO_DIOS:
		ajustes.ingresar_digito(d)
	_check(ajustes.panel_visible(), "Ajustes: PIN correcto muestra el panel del modo dios")
	ajustes.queue_free()
	await process_frame


func _probar_titulo() -> void:
	var titulo: Node = load(TITULO).instantiate()
	get_root().add_child(titulo)
	await process_frame
	var boton: Control = titulo.get_node_or_null("boton_papas")
	_check(boton != null and (boton.get_node("texto_papas") as Label).text == "ajustes", "el título tiene el botón de ajustes")
	_check(titulo.RUTA_AJUSTES == AJUSTES and ResourceLoader.exists(AJUSTES), "el botón lleva a la escena de Ajustes")
	titulo.queue_free()
	await process_frame


func _md5(ruta: String) -> String:
	return FileAccess.get_md5(ruta) if FileAccess.file_exists(ruta) else "(no existe)"


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		_oks += 1
		print("  OK    " + mensaje)
	else:
		_fallos += 1
		print("  FALLA " + mensaje)
