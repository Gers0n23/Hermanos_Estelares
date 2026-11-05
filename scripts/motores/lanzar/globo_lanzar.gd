class_name GloboLanzar
extends RigidBody2D

## Globo de pintura (motor-lanzar.md §5, §6.1 y §25.7). Fisico con CCD; deja mancha en cada contacto y se retira
## por tiempo (110/200 cuadros tras el primer contacto con un bloque o el suelo, 420 desde el lanzamiento) o al
## salir por un lado o por abajo. El tiro guiado de Maxi y el gigante vuelan cinematicos (sin colision) hasta su
## objetivo y recien ahi pasan a la fisica. La logica la lleva `TorreLanzar`.

const COLORES := {"rojo": Color("#F0453A"), "amarillo": Color("#FFD23F"), "azul": Color("#3F8CFF"), "dorado": Color("#FFC94A")}
const CONTORNO := Color("#2B3350")

var tipo := "normal"          # normal | rebota | triple | triple_mini | pesado | gigante
var color_globo := "rojo"
var radio := 26.0
var multiplicador := 1.0
var vida_contacto := 110
var cuadros := 0
var cuadros_contacto := -1
var primer_contacto_suelo := false
var atraviesa: Array = []
var atraviesa_restante := 0
var velocidad_tras_atravesar := 0.8
var rebote := 0.15
var v_prev := Vector2.ZERO
var retirado := false
var principal := true          # el rastro sigue al globo principal del tiro
var dividido := false
## Vuelo guiado (Maxi y gigante): de `guia_desde` a `guia_hasta` en `guia_dur` s, con apice `guia_alto`.
var guiado := false
var guia_desde := Vector2.ZERO
var guia_hasta := Vector2.ZERO
var guia_alto := 120.0
var guia_dur := 0.9
var guia_t := 0.0
var estela: Array = []
var golpeo_bloque := false


func preparar(t: String, color: String, datos: Dictionary, vida: int) -> void:
	tipo = t
	color_globo = color
	radio = float(datos.get("radio_px", 26))
	multiplicador = float(datos.get("multiplicador_dano", 1.0))
	rebote = float(datos.get("rebote", 0.15))
	atraviesa = datos.get("atraviesa", [])
	atraviesa_restante = int(datos.get("atraviesa_max", 0))
	velocidad_tras_atravesar = float(datos.get("velocidad_tras_atravesar", 0.8))
	vida_contacto = vida
	name = "globo_" + t
	mass = maxf(0.05, float(datos.get("masa", 1.0)))
	collision_layer = BloqueLanzar.CAPA_GLOBOS
	collision_mask = BloqueLanzar.CAPA_MUNDO | BloqueLanzar.CAPA_BLOQUES
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = 0.5
	can_sleep = false
	var pm := PhysicsMaterial.new()
	pm.friction = 0.4
	pm.bounce = clampf(rebote, 0.0, 1.0)
	physics_material_override = pm
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	forma.shape = circulo
	add_child(forma)


## Vuelo cinematico (sin colision) hasta el objetivo: el de Maxi nunca falla (§5.3).
func guiar(desde: Vector2, hasta: Vector2, duracion: float) -> void:
	guiado = true
	guia_desde = desde
	guia_hasta = hasta
	guia_dur = maxf(0.1, duracion)
	guia_t = 0.0
	guia_alto = 90.0 + 0.12 * absf(hasta.x - desde.x)
	position = desde
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0


func punto_guiado(t: float) -> Vector2:
	var u := clampf(t / guia_dur, 0.0, 1.0)
	var p := guia_desde.lerp(guia_hasta, u)
	var cima := minf(guia_desde.y, guia_hasta.y) - guia_alto
	# Parabola que pasa por los extremos con apice `cima` a mitad de camino (aprox.).
	p.y += (cima - (guia_desde.y + guia_hasta.y) / 2.0) * 4.0 * u * (1.0 - u)
	return p


## Fin del vuelo guiado: pasa a la fisica con la velocidad tangente del arco.
func soltar_a_fisica() -> void:
	var dt := 1.0 / 60.0
	var tangente := (punto_guiado(guia_dur) - punto_guiado(guia_dur - dt)) / dt
	guiado = false
	collision_layer = BloqueLanzar.CAPA_GLOBOS
	collision_mask = BloqueLanzar.CAPA_MUNDO | BloqueLanzar.CAPA_BLOQUES
	freeze = false
	linear_velocity = tangente.limit_length(520.0)


func _draw() -> void:
	var c: Color = COLORES.get(color_globo, Color.WHITE)
	if tipo == "gigante":
		# Dorado-arcoiris (§6.8).
		draw_circle(Vector2.ZERO, radio, Color("#FFC94A"))
		for k in 3:
			draw_arc(Vector2.ZERO, radio * (0.75 - k * 0.18), PI * 1.1, PI * 1.9, 24, [Color("#F0453A"), Color("#FFD23F"), Color("#3F8CFF")][k], 6.0, true)
	else:
		draw_circle(Vector2.ZERO, radio, c)
	draw_arc(Vector2.ZERO, radio, 0, TAU, 32, CONTORNO, 3.0, true)
	draw_circle(Vector2(-radio * 0.35, -radio * 0.35), radio * 0.22, Color(1, 1, 1, 0.7))
	match tipo:
		"rebota":
			var zz := PackedVector2Array()
			for k in 7:
				zz.append(Vector2(-radio * 0.6 + k * radio * 0.2, radio * (0.05 if k % 2 == 0 else 0.35)))
			draw_polyline(zz, Color.WHITE, 3.0, true)
		"triple":
			draw_circle(Vector2(radio * 0.7, radio * 0.5), radio * 0.45, c)
			draw_circle(Vector2(-radio * 0.7, radio * 0.5), radio * 0.45, c)
		"pesado":
			draw_line(Vector2(-radio * 0.4, -radio * 0.05), Vector2(-radio * 0.1, -radio * 0.05), CONTORNO, 3.0)
			draw_line(Vector2(radio * 0.1, -radio * 0.05), Vector2(radio * 0.4, -radio * 0.05), CONTORNO, 3.0)
			draw_arc(Vector2(0, radio * 0.35), radio * 0.2, PI, TAU, 10, CONTORNO, 3.0)
