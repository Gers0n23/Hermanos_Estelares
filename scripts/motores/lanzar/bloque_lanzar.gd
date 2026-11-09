class_name BloqueLanzar
extends RigidBody2D

## Una pieza de la torre (motor-lanzar.md §6.1, §6.4, §25.5). Duerme congelada (FREEZE_MODE_STATIC) entre tiros
## y solo despierta por un golpe; la logica (dano, despertar, dormir, botado) la lleva `TorreLanzar` en su
## `_physics_process`, para que el orden sea siempre el mismo (determinismo, §6.3). Arte provisional por codigo
## (HE-74 traera el arte): cajas de carton, latas de galletas, frascos de caramelo, caja sorpresa y trampolin.

const CONTORNO := Color("#2B3350")
const COLORES_MATERIAL := {
	"carton": Color("#D9A066"), "lata": Color("#8FB8DE"), "caramelo": Color("#FFB3D9"),
	"confeti": Color("#E0309A"), "resorte": Color("#4CC26A"),
}
const COLORES_MANCHA := {"rojo": Color("#F0453A"), "amarillo": Color("#FFD23F"), "azul": Color("#3F8CFF"), "dorado": Color("#FFC94A")}
const CAPA_MUNDO := 1
const CAPA_BLOQUES := 2
const CAPA_GLOBOS := 4

var id_bloque := ""
var material_bloque := "carton"
var forma := "rect"
var ancho := 60.0
var alto := 60.0
var peso_agarre := 1
var resistencia := 3
var salud := 3
var impulso_por_punto := 60.0
var irrompible := false
var es_trono := false
var contenido := ""
## Pose del JSON (centro y giro): el botado se mide contra ella (§6.5).
var pose_original := Transform2D.IDENTITY
## "en_pie" | "roto" | "suelo" (botada y no rearmada: decorado sin colision, §10.2).
var estado := "en_pie"
var botado := false
var manchas: Array = []
var apoyados: Array = []          # ids de los que se apoyan en este (los despierta, §6.2.3)
var quieto_t := 0.0
var v_prev := Vector2.ZERO
var halo := 0.0                   # radio del halo de punto debil (0 = sin halo)
var halo_color := Color("#FFD23F")
var tambaleo := 0.0               # grados del mecido de mentira (solo dibujo, §6.2.2)
var squash := 1.0


func preparar(datos: Dictionary, mat: Dictionary) -> void:
	id_bloque = str(datos.get("id", ""))
	material_bloque = str(datos.get("material", "carton"))
	forma = str(datos.get("forma", "rect"))
	contenido = str(datos.get("contenido", ""))
	var r: Array = datos.get("rect", [0, 0, 60, 60])
	ancho = float(r[2])
	alto = float(r[3])
	peso_agarre = int(datos.get("peso_agarre", 1))
	irrompible = bool(mat.get("irrompible", false))
	resistencia = int(mat.get("resistencia", 3))
	salud = resistencia
	impulso_por_punto = float(mat.get("impulso_por_punto", 60))
	var rot := float(datos.get("rot", 0.0))
	# rect: x,y = punto medio del borde inferior; el cuerpo vive en su centro.
	var base := Vector2(float(r[0]), float(r[1]))
	var centro := base + Vector2(0, -alto / 2.0).rotated(rot)
	pose_original = Transform2D(rot, centro)
	transform = pose_original
	name = "bloque_" + id_bloque
	collision_layer = CAPA_BLOQUES
	collision_mask = CAPA_MUNDO | CAPA_BLOQUES | CAPA_GLOBOS
	contact_monitor = true
	max_contacts_reported = 4
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.6
	angular_damp = 1.5
	can_sleep = false
	mass = maxf(0.05, float(mat.get("densidad", 1.0)) * ancho * alto / 2500.0)
	var pm := PhysicsMaterial.new()
	pm.friction = float(mat.get("friccion", 0.7))
	pm.bounce = clampf(float(mat.get("rebote", 0.05)), 0.0, 1.0)
	physics_material_override = pm
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	var forma_col := CollisionShape2D.new()
	forma_col.name = "forma"
	if forma == "capsula":
		var cap := CapsuleShape2D.new()
		cap.radius = ancho / 2.0
		cap.height = maxf(alto, ancho)
		forma_col.shape = cap
	else:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(ancho, alto)
		forma_col.shape = rect
	add_child(forma_col)


func dormido() -> bool:
	return freeze


func activo() -> bool:
	return estado == "en_pie"


## Congela en la pose actual (sin velocidad). Lo usa el asentamiento y el derribo.
func congelar() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	quieto_t = 0.0


func despertar() -> void:
	if estado != "en_pie":
		return
	freeze = false
	quieto_t = 0.0


## Rotura: sale del mundo fisico (sin colision) y deja de dibujarse; el motor suelta las particulas.
func romper() -> void:
	estado = "roto"
	congelar()
	collision_layer = 0
	collision_mask = 0
	hide()


## Botada y no rearmada (§10.2): queda en el suelo, en su pose, como decorado sin colision ni fisica.
func pasar_a_suelo() -> void:
	estado = "suelo"
	congelar()
	collision_layer = 0
	collision_mask = 0
	modulate = Color(1, 1, 1, 0.85)
	show()


## Vuelve congelada a su pose original, entera (rearmado, §10.2).
func rearmar() -> void:
	estado = "en_pie"
	botado = false
	salud = resistencia
	transform = pose_original
	congelar()
	collision_layer = CAPA_BLOQUES
	collision_mask = CAPA_MUNDO | CAPA_BLOQUES | CAPA_GLOBOS
	modulate = Color.WHITE
	show()


func agregar_mancha(punto_global: Vector2, color: String) -> void:
	if material_bloque == "resorte":
		return  # El trampolin siempre se ve limpio y verde (§25.5.2).
	manchas.append({"pos": to_local(punto_global).limit_length(maxf(ancho, alto) * 0.45), "color": color})
	while manchas.size() > 6:
		manchas.pop_front()
	queue_redraw()


func _process(_delta: float) -> void:
	if tambaleo != 0.0 or halo > 0.0:
		queue_redraw()


func _draw() -> void:
	var medio := Vector2(ancho, alto) / 2.0
	# Tambaleo de mentira con pivote en su propia base (§6.2.2): el cuerpo fisico nunca se mueve.
	var giro := deg_to_rad(tambaleo)
	var t := Transform2D(giro, Vector2(0, medio.y)) * Transform2D(0.0, Vector2(0, -medio.y))
	draw_set_transform_matrix(t.scaled_local(Vector2(1.0 / squash, squash)))
	if halo > 0.0:
		var pulso := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 220.0)
		draw_circle(Vector2.ZERO, halo * pulso, Color(halo_color, 0.35))
		draw_arc(Vector2.ZERO, halo * pulso, 0, TAU, 40, halo_color, 4.0, true)
	var color: Color = COLORES_MATERIAL.get(material_bloque, Color.WHITE)
	if es_trono:
		color = Color("#9B5DE5")
	var rect := Rect2(-medio, Vector2(ancho, alto))
	match material_bloque:
		"caramelo":
			_dibujar_frasco(rect, color)
		"lata":
			_redondeado(rect, color, 8.0)
			draw_rect(Rect2(rect.position + Vector2(4, alto * 0.35), Vector2(ancho - 8, alto * 0.3)), Color("#F6E7C1"))
			draw_circle(Vector2(0, alto * 0.0), minf(ancho, alto) * 0.12, Color("#B5713A"))
		"confeti":
			_redondeado(rect, color, 6.0)
			_estrella(Vector2.ZERO, minf(ancho, alto) * 0.3, Color("#FFD23F"))
			for k in 4:
				var p := Vector2(-ancho * 0.32 + k * ancho * 0.21, -alto * 0.36)
				draw_rect(Rect2(p, Vector2(5, 5)), Color("#4FD8E0"))
		"resorte":
			_redondeado(Rect2(rect.position + Vector2(0, alto * 0.55), Vector2(ancho, alto * 0.45)), Color("#2E8C48"), 4.0)
			_redondeado(Rect2(rect.position, Vector2(ancho, alto * 0.35)), color, 4.0)
			var zz := PackedVector2Array()
			for k in 9:
				zz.append(Vector2(-ancho * 0.4 + k * ancho * 0.1, (alto * 0.08) if k % 2 == 0 else (alto * 0.32)))
			draw_polyline(zz, Color.WHITE, 3.0, true)
		_:
			_redondeado(rect, color, 6.0)
			if es_trono:
				draw_rect(Rect2(rect.position + Vector2(10, 6), Vector2(ancho - 20, 6)), Color("#FFD6F5"))
			else:
				draw_rect(Rect2(Vector2(-ancho * 0.08, -medio.y), Vector2(ancho * 0.16, alto)), Color("#B97E45"))
	for m in manchas:
		var c: Color = COLORES_MANCHA.get(str(m["color"]), Color.WHITE)
		draw_circle(m["pos"], 7.0, c)
		draw_circle(m["pos"] + Vector2(6, 3), 3.5, c)
	if salud < resistencia and not irrompible and material_bloque != "caramelo":
		# Dano parcial visible (abolladura / tapa floja), sin numeros.
		draw_line(Vector2(-ancho * 0.25, -alto * 0.2), Vector2(ancho * 0.1, alto * 0.1), Color(CONTORNO, 0.6), 2.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _redondeado(rect: Rect2, color: Color, radio: float) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.border_color = CONTORNO
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(int(radio))
	draw_style_box(caja, rect)


func _dibujar_frasco(rect: Rect2, color: Color) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(color, 0.85)
	caja.border_color = CONTORNO
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(int(ancho / 2.0))
	draw_style_box(caja, rect)
	draw_rect(Rect2(rect.position + Vector2(ancho * 0.15, -4), Vector2(ancho * 0.7, 10)), Color("#FF6FB5"))
	draw_circle(Vector2(0, alto * 0.1), ancho * 0.18, Color("#FFF3B0"))


func _estrella(centro: Vector2, radio: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 10:
		var r := radio if i % 2 == 0 else radio * 0.45
		puntos.append(centro + Vector2.from_angle(-PI / 2.0 + PI * i / 5.0) * r)
	draw_colored_polygon(puntos, color)
