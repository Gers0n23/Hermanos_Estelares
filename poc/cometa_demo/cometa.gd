extends Area2D
## Cometa responde al toque con un rebote alegre y confeti.
## PoC del contrato tactil-primero: input unificado toque+mouse.

@onready var sprite: Sprite2D = $sprite
@onready var confeti: CPUParticles2D = $confeti

var _celebrando := false


func _ready() -> void:
	print("[demo] Cometa listo — toca para celebrar")
	input_event.connect(_al_recibir_input)
	_flotar()


func _flotar() -> void:
	# Vaiven suave permanente para que se sienta viva
	var tw := create_tween().set_loops()
	tw.tween_property(self, "position:y", position.y - 14.0, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", position.y, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _al_recibir_input(_viewport: Node, evento: InputEvent, _shape: int) -> void:
	if evento is InputEventScreenTouch and evento.pressed:
		celebrar()


func celebrar() -> void:
	if _celebrando:
		return
	_celebrando = true
	print("[demo] ¡Celebración! Confeti y rebote")
	confeti.restart()
	confeti.emitting = true
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func() -> void: _celebrando = false)
