# armar_rig_maxi_preview.gd — genera escenas/personajes/vista_previa_rig_maxi.tscn
#
# Vista previa TECNICA del rig de cutout de Maxi (pedido directo del PO, fuera del tablero),
# gemela de armar_rig_sofia_preview.gd. Piezas: cabeza_casco y torso cortadas a mano por el
# PO en Krita; las otras 8 cortadas por herramientas/cortar_piezas_maxi.py siguiendo el mapa
# assets/generadas/maxi_piezas/00_mapa_cortes.png (copiadas a assets/sprites/preview_maxi_rig/).
# Maxi no lleva cinturon aparte: queda dentro del torso (no tiene tunica que lo tape).
#
# Uso (desde la raiz del repo):
#   godot --headless --path . --script herramientas/armar_rig_maxi_preview.gd
# Revision visual (hoja de contacto de la animacion):
#   bash herramientas/ojos.sh escena=res://escenas/personajes/vista_previa_rig_maxi.tscn tiempos=0.1,0.6,1.0,1.3,1.6,2.1
# Prueba de estres de articulaciones (poses extremas, para revisar los casquetes pintados):
#   godot --headless --path . --script herramientas/armar_rig_maxi_preview.gd -- prueba
#   bash herramientas/ojos.sh escena=res://escenas/personajes/vista_previa_rig_maxi_prueba.tscn tiempos=0.5,1.5,2.5,3.5

extends SceneTree

const DIR_PIEZAS := "res://assets/sprites/preview_maxi_rig/"
const RUTA_SALIDA := "res://escenas/personajes/vista_previa_rig_maxi.tscn"
const RUTA_PRUEBA := "res://escenas/personajes/vista_previa_rig_maxi_prueba.tscn"

# Pivote (x,y) de cada pieza en el lienzo de 306x697: los escribe el cortador
# (herramientas/cortar_piezas_maxi.py, codo y rodilla centrados en el miembro) en
# pivotes.json, asi cortes y rig nunca quedan desincronizados.
const RUTA_PIVOTES := "res://assets/generadas/maxi_piezas/pivotes.json"
var PIVOTES := {}

# Orden de dibujo = orden de capas de assets/generadas/maxi_piezas/01_piezas_maxi.kra
# (arriba = mas al frente). Mismo criterio que Sofia: el torso tapa el hombro y el brazo
# tapa el codo, asi los casquetes pintados de cada articulacion quedan escondidos en
# reposo. A diferencia de Sofia, la cabeza va DELANTE del torso: Maxi no tiene pelo
# largo detras del cuerpo y la burbuja del casco apoya sobre el cuello.
const Z_INDEX := {
	"cabeza_casco": 10,
	"torso": 9,
	"brazo_sup_izq": 8,
	"brazo_sup_der": 7,
	"antebrazo_mano_izq": 6,
	"antebrazo_mano_der": 5,
	"pierna_inf_pie_izq": 4,
	"pierna_inf_pie_der": 3,
	"pierna_sup_izq": 2,
	"pierna_sup_der": 1,
}

# Raiz "cadera" = pivote de cadera del torso.
const PIVOTE_CADERA := Vector2(153, 410)

# Donde cae en pantalla el (0,0) del lienzo 306x697 (centrado en 1280x720).
const DESPLAZAMIENTO_LIENZO := Vector2(487, 8)


func _init() -> void:
	var crudo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA_PIVOTES))
	for nombre in crudo:
		PIVOTES[nombre] = Vector2(crudo[nombre][0], crudo[nombre][1])
	var raiz := Node2D.new()
	raiz.name = "vista_previa_rig_maxi"

	var fondo := _crear_fondo()
	raiz.add_child(fondo)

	var cadera := Node2D.new()
	cadera.name = "cadera"
	cadera.position = DESPLAZAMIENTO_LIENZO + PIVOTE_CADERA
	raiz.add_child(cadera)

	# torso cuelga directo de cadera; su pivote coincide con el de cadera -> position local (0,0)
	var torso := _crear_pieza("torso", PIVOTES["torso"] - PIVOTE_CADERA)
	cadera.add_child(torso)

	var cabeza := _crear_pieza("cabeza_casco", PIVOTES["cabeza_casco"] - PIVOTES["torso"])
	torso.add_child(cabeza)


	var brazo_izq := _crear_pieza("brazo_sup_izq", PIVOTES["brazo_sup_izq"] - PIVOTES["torso"])
	torso.add_child(brazo_izq)
	var antebrazo_izq := _crear_pieza("antebrazo_mano_izq", PIVOTES["antebrazo_mano_izq"] - PIVOTES["brazo_sup_izq"])
	brazo_izq.add_child(antebrazo_izq)

	var brazo_der := _crear_pieza("brazo_sup_der", PIVOTES["brazo_sup_der"] - PIVOTES["torso"])
	torso.add_child(brazo_der)
	var antebrazo_der := _crear_pieza("antebrazo_mano_der", PIVOTES["antebrazo_mano_der"] - PIVOTES["brazo_sup_der"])
	brazo_der.add_child(antebrazo_der)

	var pierna_sup_izq := _crear_pieza("pierna_sup_izq", PIVOTES["pierna_sup_izq"] - PIVOTE_CADERA)
	cadera.add_child(pierna_sup_izq)
	var pierna_inf_izq := _crear_pieza("pierna_inf_pie_izq", PIVOTES["pierna_inf_pie_izq"] - PIVOTES["pierna_sup_izq"])
	pierna_sup_izq.add_child(pierna_inf_izq)

	var pierna_sup_der := _crear_pieza("pierna_sup_der", PIVOTES["pierna_sup_der"] - PIVOTE_CADERA)
	cadera.add_child(pierna_sup_der)
	var pierna_inf_der := _crear_pieza("pierna_inf_pie_der", PIVOTES["pierna_inf_pie_der"] - PIVOTES["pierna_sup_der"])
	pierna_sup_der.add_child(pierna_inf_der)

	var prueba := "prueba" in OS.get_cmdline_user_args()
	var animador := _crear_animador_prueba() if prueba else _crear_animador()
	cadera.add_child(animador)

	# owner = raiz en TODOS los descendientes para que se guarden en el PackedScene.
	_asignar_owner(raiz, raiz)

	var empaquetada := PackedScene.new()
	var error := empaquetada.pack(raiz)
	if error != OK:
		push_error("No se pudo empaquetar la escena: %s" % error_string(error))
		quit(1)
		return

	var ruta := RUTA_PRUEBA if prueba else RUTA_SALIDA
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	error = ResourceSaver.save(empaquetada, ruta)
	if error != OK:
		push_error("No se pudo guardar la escena: %s" % error_string(error))
		quit(1)
		return

	print("Escena guardada en: %s" % ruta)
	quit(0)


func _crear_pieza(nombre: String, posicion_local: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = nombre
	sprite.texture = load(DIR_PIEZAS + nombre + ".png")
	sprite.centered = false
	sprite.offset = -PIVOTES[nombre]
	sprite.position = posicion_local
	sprite.z_index = Z_INDEX[nombre]
	sprite.z_as_relative = false
	return sprite


func _crear_fondo() -> Sprite2D:
	var gradiente := Gradient.new()
	gradiente.set_offset(0, 0.0)
	gradiente.set_offset(1, 1.0)
	gradiente.set_color(0, Color(0.55, 0.8, 0.95))
	gradiente.set_color(1, Color(0.85, 0.95, 1.0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2(0.5, 0)
	textura.fill_to = Vector2(0.5, 1)
	textura.width = 1280
	textura.height = 720
	var fondo := Sprite2D.new()
	fondo.name = "fondo"
	fondo.texture = textura
	fondo.position = Vector2(640, 360)
	fondo.z_index = -10
	fondo.z_as_relative = false
	return fondo


func _crear_animador() -> AnimationPlayer:
	var animacion := Animation.new()
	animacion.resource_name = "vista_previa"
	animacion.length = 2.4
	animacion.loop_mode = Animation.LOOP_LINEAR

	# 0: bob de cadera (respiracion / peso del cuerpo)
	_agregar_track_valor(animacion, ".:position", [0.0, 0.6, 1.2, 1.8, 2.4], [
		DESPLAZAMIENTO_LIENZO + PIVOTE_CADERA,
		DESPLAZAMIENTO_LIENZO + PIVOTE_CADERA + Vector2(0, -6),
		DESPLAZAMIENTO_LIENZO + PIVOTE_CADERA,
		DESPLAZAMIENTO_LIENZO + PIVOTE_CADERA + Vector2(0, -6),
		DESPLAZAMIENTO_LIENZO + PIVOTE_CADERA,
	])
	# 1: torso — leve balanceo (respiracion)
	_agregar_track_valor(animacion, "torso:rotation", [0.0, 0.6, 1.2, 1.8, 2.4],
		[0.0, 0.03, 0.0, -0.03, 0.0])
	# 2: cabeza — leve inclinacion
	_agregar_track_valor(animacion, "torso/cabeza_casco:rotation", [0.0, 0.6, 1.2, 1.8, 2.4],
		[0.0, -0.04, 0.0, 0.04, 0.0])
	# 3: hombro derecho — saludo (se levanta el brazo)
	_agregar_track_valor(animacion, "torso/brazo_sup_der:rotation", [0.0, 0.3, 0.9, 1.9, 2.4],
		[0.0, 0.0, -1.05, -1.05, 0.0])
	# 4: codo derecho — flexion + agite de saludo
	_agregar_track_valor(animacion, "torso/brazo_sup_der/antebrazo_mano_der:rotation",
		[0.0, 0.9, 1.15, 1.4, 1.65, 1.9, 2.4],
		[0.0, -0.5, -0.85, -0.35, -0.85, -0.5, 0.0])
	# 5 y 6: cadera de piernas — leve cambio de peso
	_agregar_track_valor(animacion, "pierna_sup_izq:rotation", [0.0, 1.2, 2.4], [0.0, 0.03, 0.0])
	_agregar_track_valor(animacion, "pierna_sup_der:rotation", [0.0, 1.2, 2.4], [0.0, -0.03, 0.0])

	var biblioteca := AnimationLibrary.new()
	biblioteca.add_animation("vista_previa", animacion)

	var animador := AnimationPlayer.new()
	animador.name = "animador"
	animador.add_animation_library("", biblioteca)
	animador.autoplay = "vista_previa"
	return animador


# Poses extremas sostenidas (cada una 1 s): reposo, brazos arriba con codos doblados,
# brazos abiertos con codos hacia adentro + rodillas dobladas, cabeza muy inclinada.
func _crear_animador_prueba() -> AnimationPlayer:
	var animacion := Animation.new()
	animacion.length = 4.0
	var t := [0.0, 0.4, 1.0, 1.4, 2.0, 2.4, 3.0, 3.4, 4.0]
	var poses := {
		"torso/brazo_sup_der:rotation": [0.0, 0.0, 0.0, -1.6, -1.6, -0.9, -0.9, 0.0, 0.0],
		"torso/brazo_sup_der/antebrazo_mano_der:rotation": [0.0, 0.0, 0.0, -1.2, -1.2, 1.3, 1.3, 0.0, 0.0],
		"torso/brazo_sup_izq:rotation": [0.0, 0.0, 0.0, 1.6, 1.6, 0.9, 0.9, 0.0, 0.0],
		"torso/brazo_sup_izq/antebrazo_mano_izq:rotation": [0.0, 0.0, 0.0, 1.2, 1.2, -1.3, -1.3, 0.0, 0.0],
		"pierna_sup_izq:rotation": [0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0],
		"pierna_sup_izq/pierna_inf_pie_izq:rotation": [0.0, 0.0, 0.0, 0.0, 0.0, -0.9, -0.9, 0.0, 0.0],
		"pierna_sup_der:rotation": [0.0, 0.0, 0.0, 0.0, 0.0, -0.35, -0.35, 0.0, 0.0],
		"pierna_sup_der/pierna_inf_pie_der:rotation": [0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.6, 0.0, 0.0],
		"torso/cabeza_casco:rotation": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3],
	}
	for ruta in poses:
		_agregar_track_valor(animacion, ruta, t, poses[ruta])
	var biblioteca := AnimationLibrary.new()
	biblioteca.add_animation("prueba", animacion)
	var animador := AnimationPlayer.new()
	animador.name = "animador"
	animador.add_animation_library("", biblioteca)
	animador.autoplay = "prueba"
	return animador


func _agregar_track_valor(animacion: Animation, ruta: String, tiempos: Array, valores: Array) -> void:
	var indice := animacion.add_track(Animation.TYPE_VALUE)
	animacion.track_set_path(indice, NodePath(ruta))
	animacion.value_track_set_update_mode(indice, Animation.UPDATE_CONTINUOUS)
	for i in tiempos.size():
		animacion.track_insert_key(indice, tiempos[i], valores[i])


func _asignar_owner(nodo: Node, raiz: Node) -> void:
	for hijo in nodo.get_children():
		hijo.owner = raiz
		_asignar_owner(hijo, raiz)
