class_name ColeccionautaLanzar
extends Node2D

## El Coleccionauta de la Torre, PROVISIONAL (cutout simple, storyboard cierre_arcoiris.md §25.1 nivel CS): el
## retrato `coleccionauta_provisional.png` con tweens, gotitas de sudor por estado de agarre (§6.6), lunares por
## etapa ganada (§25.2.3) y la tapa-sombrerito del final. Sin rig: HE-74 traera el arte. No es un cuerpo fisico;
## su Area2D vive en la torre y la recoloca el motor.

const TEXTURA := "res://assets/sprites/personajes/coleccionauta_provisional.png"
const ALTO := 120.0
const LUNARES := [Color("#F0453A"), Color("#FFD23F"), Color("#3F8CFF"), Color("#FF9ED6")]

var estado_cara := 0       # 0 orgulloso, 1 "¡uy!", 2 agarrado con las dos manos, 3 colgando de un dedo
var nivel_lunares := 0     # 0-3
var sombrerito := false
var balanceo := 0.0
var _sprite: Sprite2D
var _t := 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "retrato"
	if ResourceLoader.exists(TEXTURA):
		_sprite.texture = load(TEXTURA)
		var alto_tex := float(_sprite.texture.get_height())
		_sprite.scale = Vector2.ONE * (ALTO / maxf(1.0, alto_tex))
	_sprite.offset = Vector2(0, -(_sprite.texture.get_height() if _sprite.texture != null else ALTO) / 2.0)
	add_child(_sprite)


func _process(delta: float) -> void:
	_t += delta
	# El bamboleo crece con el agarre perdido (§6.6: lo dramatico lo hace el rig, no la torre).
	var amp := deg_to_rad(4.0) * float(estado_cara) / 3.0
	_sprite.rotation = sin(_t * 3.1) * amp + balanceo
	queue_redraw()


func _draw() -> void:
	var cuerpo := Vector2(0, -ALTO * 0.45)
	for i in nivel_lunares * 4:
		var ang := float(i) * 2.4
		var r := 18.0 + float(i % 3) * 10.0
		draw_circle(cuerpo + Vector2(cos(ang) * r, sin(ang) * r * 1.3), 6.0, LUNARES[i % LUNARES.size()])
	for k in estado_cara:
		# Gotitas de sudor.
		var p := Vector2(30.0 + k * 6.0, -ALTO * 0.85 + k * 12.0 + fmod(_t * 30.0 + k * 9.0, 10.0))
		draw_circle(p, 4.0, Color("#8EE9FF"))
	if sombrerito:
		draw_rect(Rect2(-22, -ALTO - 6, 44, 10), Color("#FF6FB5"))
