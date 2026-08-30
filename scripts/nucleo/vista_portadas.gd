extends Node2D
## Slideshow de arte conceptual dentro del disco de la pantalla de carga (`carga.tscn`,
## nodo `anillo_progreso/vista_portadas`) — reemplaza al slot donde antes flotaba Cometa
## por un teaser visual del juego (UI ad-hoc, pedido directo del PO).
##
## Recorre sus hijos `TextureRect` (cada uno ya recortado en circulo por el shader
## `disco_circular.gdshader`) y hace crossfade entre ellos en loop infinito. No depende
## de `DURACION_CARGA` de `carga.gd`: sigue ciclando aunque la barra ya haya llegado al
## 100%, porque la pantalla cambia de escena por su cuenta.

const SEGUNDOS_VISIBLE := 1.6
const SEGUNDOS_CROSSFADE := 0.6

var _slides: Array[TextureRect] = []


func _ready() -> void:
	for hijo in get_children():
		if hijo is TextureRect:
			_slides.append(hijo)
	if _slides.size() < 2:
		return
	_iniciar_ciclo()


func _iniciar_ciclo() -> void:
	var tween := create_tween().set_loops()
	for i in _slides.size():
		var actual: TextureRect = _slides[i]
		var siguiente: TextureRect = _slides[(i + 1) % _slides.size()]
		tween.tween_interval(SEGUNDOS_VISIBLE)
		tween.tween_property(actual, "modulate:a", 0.0, SEGUNDOS_CROSSFADE) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(siguiente, "modulate:a", 1.0, SEGUNDOS_CROSSFADE) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
