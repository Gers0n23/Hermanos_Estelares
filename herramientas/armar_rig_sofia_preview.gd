# armar_rig_sofia_preview.gd — genera escenas/personajes/vista_previa_rig_sofia.tscn
#
# Vista previa TECNICA pedida directamente por el PO (no es una tarjeta del tablero):
# arma el rig de cutout de Sofia con las 10 piezas cortadas a mano en
# assets/generadas/sofia_piezas/ (copiadas sin auditar a assets/sprites/preview_sofia_rig/,
# ver nota en docs). Construye el arbol de nodos por codigo (en vez de escribir el .tscn a
# mano) para que Godot serialice el recurso Animation/AnimationLibrary sin errores de formato.
#
# Uso (desde la raiz del repo):
#   godot --headless --path . --script herramientas/armar_rig_sofia_preview.gd

extends SceneTree

const DIR_PIEZAS := "res://assets/sprites/preview_sofia_rig/"
const RUTA_SALIDA := "res://escenas/personajes/vista_previa_rig_sofia.tscn"

# Pivote (x,y) de cada pieza en el lienzo de 332x768 (docs/guia-corte-piezas.md §7).
# NOTA: "cinturon" no tiene entrada propia en esa tabla (no es una de las 10 piezas
# articuladas) — se ancla al mismo punto de cadera que el torso, del que cuelga, para
# que rote solidario con el torso sin necesitar un pivote independiente (correccion
# de orden de dibujo del PO, ver mensaje de coordinacion; pendiente anotar en el doc).
const PIVOTES := {
	"cabeza_casco": Vector2(166, 262),
	"antebrazo_mano_izq": Vector2(68, 392),
	"antebrazo_mano_der": Vector2(254, 392),
	"brazo_sup_izq": Vector2(102, 298),
	"brazo_sup_der": Vector2(226, 298),
	"torso": Vector2(166, 470),
	"cinturon": Vector2(166, 470),
	"pierna_inf_pie_izq": Vector2(118, 550),
	"pierna_inf_pie_der": Vector2(202, 550),
	"pierna_sup_izq": Vector2(118, 462),
	"pierna_sup_der": Vector2(202, 462),
}

# Orden de dibujo CORREGIDO por el PO (18-Jul-2026 -> ver mensaje de coordinacion),
# leido de arriba a abajo del panel de capas de Krita en
# assets/generadas/sofia_piezas/00_base_sofia.krz (arriba = mas al frente). Reemplaza
# el orden original de docs/guia-corte-piezas.md §7, que quedo desactualizado en dos
# puntos: cabeza_casco ahora va AL FONDO de todo (pelo detras del cuerpo, no delante)
# y torso pasa a ir detras de las 4 piezas de pierna. z_index mas alto = mas al frente
# (z_as_relative=false en cada Sprite2D, ver _crear_pieza).
const Z_INDEX := {
	"cinturon": 11,
	"pierna_inf_pie_izq": 10,
	"pierna_sup_izq": 9,
	"pierna_inf_pie_der": 8,
	"pierna_sup_der": 7,
	"torso": 6,
	"brazo_sup_der": 5,
	"brazo_sup_izq": 4,
	"antebrazo_mano_der": 3,
	"antebrazo_mano_izq": 2,
	"cabeza_casco": 1,
}

# Punto de anclaje canvas que representa la raiz "cadera": coincide con el pivote de
# cadera del torso (166,470), como indica la tabla ("166, 470 (cadera)").
const PIVOTE_CADERA := Vector2(166, 470)

# Donde queremos que caiga, en pantalla, el punto (0,0) del lienzo 332x768 (para centrar
# el personaje en un viewport de 1280x720).
const DESPLAZAMIENTO_LIENZO := Vector2(474, -24)


func _init() -> void:
	var raiz := Node2D.new()
	raiz.name = "vista_previa_rig_sofia"

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

	# cinturon comparte el pivote de cadera del torso -> position local (0,0), rota
	# solidario con el torso, sin pivote de articulacion propio (pedido del PO).
	var cinturon := _crear_pieza("cinturon", PIVOTES["cinturon"] - PIVOTES["torso"])
	torso.add_child(cinturon)

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

	var animador := _crear_animador()
	cadera.add_child(animador)

	# owner = raiz en TODOS los descendientes para que se guarden en el PackedScene.
	_asignar_owner(raiz, raiz)

	var empaquetada := PackedScene.new()
	var error := empaquetada.pack(raiz)
	if error != OK:
		push_error("No se pudo empaquetar la escena: %s" % error_string(error))
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(RUTA_SALIDA.get_base_dir())
	error = ResourceSaver.save(empaquetada, RUTA_SALIDA)
	if error != OK:
		push_error("No se pudo guardar la escena: %s" % error_string(error))
		quit(1)
		return

	print("Escena guardada en: %s" % RUTA_SALIDA)
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
