# renderizar_retrato_sofia.gd — genera el retrato estatico oficial de Sofia
# (assets/sprites/personajes/sofia_base.png) a partir del rig cutout aprobado
# en assets/sprites/preview_sofia_rig/ (auditado por experto-ux-parvulo + PO el
# 05-Ago-2026, ver docs/auditorias-ux/2026-08-05_rig-sofia.md).
#
# Reemplaza el retrato anterior (pipeline SVG->PNG plano de HE-D2). Este script
# NO arma nodos ni SubViewport: como la pose de reposo (rotacion 0 en todas las
# piezas) hace que cada pieza quede alineada exactamente en el mismo sistema de
# coordenadas del lienzo de 332x768 (ver PIVOTES/offset en
# herramientas/armar_rig_sofia_preview.gd), alcanza con componer las 11 capas
# PNG por encima una de otra (compositing alfa por CPU, sin GPU/viewport) en el
# orden de Z_INDEX de esa misma referencia, y despues centrar el resultado en
# un lienzo de 512x768 (mismo tamano que el sofia_base.png anterior) para que
# titulo.tscn / seleccion_personaje.tscn / mapa_estelar.gd sigan funcionando
# sin tocar ninguna escena ni script (todas referencian el mismo path).
#
# Uso (desde la raiz del repo):
#   godot --headless --path . --script herramientas/renderizar_retrato_sofia.gd

extends SceneTree

const DIR_PIEZAS := "res://assets/sprites/preview_sofia_rig/"
const RUTA_SALIDA := "res://assets/sprites/personajes/sofia_base.png"

const ANCHO_LIENZO_PIEZA := 332
const ALTO_LIENZO_PIEZA := 768
const ANCHO_FINAL := 512
const ALTO_FINAL := 768

# Orden de dibujo de atras (fondo) a adelante (primer plano), leido de menor a
# mayor Z_INDEX en herramientas/armar_rig_sofia_preview.gd (pelo detras de
# todo, cinturon al frente de todo).
const ORDEN_DIBUJO: Array[String] = [
	"cabeza_casco",
	"antebrazo_mano_izq",
	"antebrazo_mano_der",
	"brazo_sup_izq",
	"brazo_sup_der",
	"torso",
	"pierna_sup_der",
	"pierna_inf_pie_der",
	"pierna_sup_izq",
	"pierna_inf_pie_izq",
	"cinturon",
]


func _init() -> void:
	var lienzo_pieza := Image.create_empty(ANCHO_LIENZO_PIEZA, ALTO_LIENZO_PIEZA, false, Image.FORMAT_RGBA8)

	for nombre in ORDEN_DIBUJO:
		var ruta := DIR_PIEZAS + nombre + ".png"
		var textura: Texture2D = load(ruta)
		if textura == null:
			push_error("No se pudo cargar la pieza: " + ruta)
			quit(1)
			return
		var imagen_pieza := textura.get_image()
		if imagen_pieza.is_compressed():
			imagen_pieza.decompress()
		if imagen_pieza.get_size() != Vector2i(ANCHO_LIENZO_PIEZA, ALTO_LIENZO_PIEZA):
			push_error("Pieza con lienzo inesperado (%s): %s" % [imagen_pieza.get_size(), ruta])
			quit(1)
			return
		lienzo_pieza.blend_rect(imagen_pieza, Rect2i(Vector2i.ZERO, imagen_pieza.get_size()), Vector2i.ZERO)

	# Centrar horizontalmente el lienzo de la pieza (332 de ancho) dentro del
	# lienzo final (512), mismo tamano que el sofia_base.png anterior.
	var lienzo_final := Image.create_empty(ANCHO_FINAL, ALTO_FINAL, false, Image.FORMAT_RGBA8)
	var desplazo_x := int((ANCHO_FINAL - ANCHO_LIENZO_PIEZA) / 2.0)
	lienzo_final.blend_rect(lienzo_pieza, Rect2i(Vector2i.ZERO, lienzo_pieza.get_size()), Vector2i(desplazo_x, 0))

	var error := lienzo_final.save_png(RUTA_SALIDA)
	if error != OK:
		push_error("No se pudo guardar el retrato (%s): %s" % [error_string(error), RUTA_SALIDA])
		quit(1)
		return

	print("Retrato guardado en: %s (%dx%d)" % [RUTA_SALIDA, lienzo_final.get_width(), lienzo_final.get_height()])
	quit(0)
