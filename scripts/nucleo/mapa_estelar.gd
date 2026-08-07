extends Node2D
## Mapa estelar / hub (HE-08 en Backlog — implementado aqui como parte del paquete de
## UI ad-hoc del mockup del PO "UI Sistema").
##
## STUB EXPLICITO: los 6 planetas, sus posiciones/colores y cuantos estan desbloqueados
## viven como constantes en este script (`PLANETAS`, `PLANETAS_DESBLOQUEADOS_STUB`), no
## en `datos/planetas.json` ni en un autoload `Navegacion` — ninguno de los dos existe
## todavia. Cuando se planifique HE-08 (mapa data-driven real, con desbloqueo segun
## progreso guardado) y HE-09 (`Navegacion`), este script se reemplaza por la version
## data-driven; por ahora cubre fielmente el diseno visual y la navegacion basica entre
## las pantallas de este paquete.
##
## Planetas no desbloqueados NUNCA se marcan con candado/"proximamente" (GDD §3): se ven
## a distancia, en escala de grises y desenfocados — un "tease", no un muro.

const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/toque.ogg"
const SEGUNDOS_ENTRE_RECORDATORIOS := 14.0
const RUTA_SELECCION := "res://escenas/nucleo/seleccion_personaje.tscn"
const RUTA_TITULO := "res://escenas/nucleo/titulo.tscn"
const RUTA_SHADER_DISCO := "res://assets/shaders/disco_circular.gdshader"
const RUTA_FUENTE_NOMBRES := "res://assets/fuentes/fuente_baloo_800.tres"

## Los 6 planetas del capitulo 1 (GDD §2), en el orden fijo de la ruta. "pos"/"radio"/
## "dy"/"escala" reproducen la perspectiva creciente del mockup (mas chicos y mas altos
## a medida que se alejan); "textura" usa arte real ya aprobado en `assets/anclas/`
## cuando existe (Arcoiris, Animalia) y cae a un degradê generado cuando todavia no hay
## arte final (Melodia en adelante — tarea de HE-13+).
const PLANETAS := [
	{"id": "arcoiris", "nombre": "Arcoíris", "pos": Vector2(300, 545), "radio": 84.0, "dy": 36.0, "escala": 1.0, "color_a": Color("ff9ec7"), "color_b": Color("ffd86b"), "color_c": Color("7fe3d0"), "textura": "res://assets/anclas/planeta_arcoiris_referencia.png"},
	{"id": "animalia", "nombre": "Animalia", "pos": Vector2(520, 315), "radio": 65.0, "dy": 30.0, "escala": 0.78, "color_a": Color("a7e05a"), "color_b": Color("4fbf7a"), "color_c": Color("2b7f56"), "textura": "res://assets/anclas/planeta_animalia_referencia.png"},
	{"id": "melodia", "nombre": "Melodía", "pos": Vector2(700, 490), "radio": 54.0, "dy": 26.0, "escala": 0.64, "color_a": Color("ff6bd6"), "color_b": Color("a06bff"), "color_c": Color("5b2f96"), "textura": ""},
	{"id": "cuenta_cuentas", "nombre": "Cuenta-Cuentas", "pos": Vector2(890, 265), "radio": 45.0, "dy": 22.0, "escala": 0.53, "color_a": Color("5aa8ff"), "color_b": Color("3b5bd6"), "color_c": Color("1f2f8c"), "textura": ""},
	{"id": "letralandia", "nombre": "Letralandia", "pos": Vector2(1060, 430), "radio": 38.0, "dy": 20.0, "escala": 0.45, "color_a": Color("ffc76b"), "color_b": Color("ff8a3d"), "color_c": Color("c25219"), "textura": ""},
	{"id": "corazon", "nombre": "Corazón", "pos": Vector2(1195, 215), "radio": 31.0, "dy": 17.0, "escala": 0.37, "color_a": Color("8ad8ff"), "color_b": Color("ff7eb6"), "color_c": Color("c2477f"), "textura": ""},
]

const COLORES_HERMANO := {
	"maxi": Color("4aa8ff"),
	"nicole": Color("ff5fae"),
	"sofia": Color("4fd8e0"),
}

const RETRATOS_HERMANO := {
	"maxi": "res://assets/sprites/personajes/maxi_base.png",
	"nicole": "res://assets/sprites/personajes/nicole_base.png",
	"sofia": "res://assets/sprites/personajes/sofia_base.png",
}

## Solo el Planeta 1 (Arcoiris) es real y jugable en este capitulo (stack-tecnico.md,
## decision del 18-Jul-2026 "lanzamiento por capitulos"). HE-08 reemplaza este numero
## fijo por el progreso real del hermano activo (piezas de nave conseguidas).
const PLANETAS_DESBLOQUEADOS_STUB := 1

@onready var _camino: Node2D = $camino
@onready var _contenedor_planetas: Node2D = $contenedor_planetas
@onready var _nave: Node2D = $nave
@onready var _forma_nave: Node2D = $nave/forma_nave
@onready var _hud_retrato: TextureRect = $hud/anillo_retrato/retrato
@onready var _hud_anillo: Panel = $hud/anillo_retrato
@onready var _hud_nombre: Label = $hud/texto_nombre
@onready var _hud_nivel: Label = $hud/texto_nivel
@onready var _hud_destellos: Label = $hud/grupo_destellos/texto_destellos
@onready var _burbuja_texto: Label = $burbuja_cometa/texto
@onready var _boton_hangar: Control = $boton_hangar
@onready var _boton_casa: Control = $boton_casa
@onready var _boton_papas: Control = $boton_papas
@onready var _temporizador_recordatorio: Timer = $temporizador_recordatorio

var _id_perfil := "maxi"
var _regiones: Array[Dictionary] = []
var _ruta_voz_actual := ""


func _ready() -> void:
	_id_perfil = Progreso.perfil_seleccionado if Progreso.perfil_seleccionado != "" else "maxi"
	_pintar_hud()
	_pintar_camino()
	_pintar_tierra()
	_pintar_planetas()
	_posicionar_nave()
	_iniciar_bob_nave()
	_pintar_burbuja()
	_registrar_regiones()
	_reproducir_invitacion()
	_temporizador_recordatorio.wait_time = SEGUNDOS_ENTRE_RECORDATORIOS
	_temporizador_recordatorio.timeout.connect(_reproducir_invitacion)
	_temporizador_recordatorio.start()


func _pintar_hud() -> void:
	var perfil := Progreso.obtener_perfil(_id_perfil)
	var color: Color = COLORES_HERMANO.get(_id_perfil, Color.WHITE)
	_hud_nombre.text = str(perfil.get("nombre", _id_perfil.capitalize()))
	_hud_nivel.text = str(perfil.get("perfil_dificultad", ""))
	_hud_nivel.add_theme_color_override("font_color", color)
	_hud_destellos.text = str(Progreso.obtener_destellos_totales(_id_perfil))
	var ruta_retrato: String = RETRATOS_HERMANO.get(_id_perfil, "")
	if ruta_retrato != "" and ResourceLoader.exists(ruta_retrato):
		_hud_retrato.texture = load(ruta_retrato)
	var estilo_base: StyleBox = _hud_anillo.get_theme_stylebox("panel")
	if estilo_base is StyleBoxFlat:
		var estilo: StyleBoxFlat = (estilo_base as StyleBoxFlat).duplicate()
		estilo.border_color = color
		_hud_anillo.add_theme_stylebox_override("panel", estilo)


func _pintar_camino() -> void:
	var curva := _construir_curva_camino()
	_camino.fijar_curva(curva)
	var indice_actual: int = clampi(PLANETAS_DESBLOQUEADOS_STUB, 1, PLANETAS.size()) - 1
	var offset_meta: float = curva.get_closest_offset(PLANETAS[indice_actual]["pos"])
	var largo_total: float = curva.get_baked_length()
	_camino.proporcion = 0.0 if largo_total <= 0.0 else offset_meta / largo_total


## Reconstruye a mano, en puntos de control de Bezier cubica, el mismo `<path>` SVG del
## mockup (`M152 572 Q226 548 300 545 C400 542 430 330 520 315 S620 505 700 490 S810 275
## 890 265 S990 440 1060 430 S1160 225 1195 215`) — los 6 nodos coinciden exactamente con
## los extremos de cada segmento, asi que la curva pasa justo por cada planeta.
func _construir_curva_camino() -> Curve2D:
	var curva := Curve2D.new()
	curva.bake_interval = 6.0
	curva.add_point(Vector2(152, 572), Vector2.ZERO, Vector2(49.33, -16))
	curva.add_point(Vector2(300, 545), Vector2(-49.33, 2), Vector2(100, -3))
	curva.add_point(Vector2(520, 315), Vector2(-90, 15), Vector2(90, -15))
	curva.add_point(Vector2(700, 490), Vector2(-80, 15), Vector2(80, -15))
	curva.add_point(Vector2(890, 265), Vector2(-80, 10), Vector2(80, -10))
	curva.add_point(Vector2(1060, 430), Vector2(-70, 10), Vector2(70, -10))
	curva.add_point(Vector2(1195, 215), Vector2(-35, 10), Vector2.ZERO)
	return curva


func _pintar_tierra() -> void:
	_crear_disco(Vector2(96, 622), 84.0, Color("8ed6ff"), Color("3f8fe0"), Color("1c4f96"), "", true, "La Tierra", 22, true)


func _pintar_planetas() -> void:
	for i in PLANETAS.size():
		var datos: Dictionary = PLANETAS[i]
		var desbloqueado: bool = (i + 1) <= PLANETAS_DESBLOQUEADOS_STUB
		var tamano_fuente: int = maxi(15, int(30 * float(datos["escala"])))
		_crear_disco(datos["pos"], datos["radio"], datos["color_a"], datos["color_b"], datos["color_c"], datos["textura"], desbloqueado, datos["nombre"], tamano_fuente, false)


## `etiqueta_arriba` deja el nombre encima del disco en vez de debajo — lo usa la Tierra,
## que esta pegada al borde inferior de la pantalla y no tiene lugar debajo.
func _crear_disco(pos: Vector2, radio: float, color_a: Color, color_b: Color, color_c: Color, ruta_textura: String, desbloqueado: bool, nombre: String, tamano_fuente: int, etiqueta_arriba: bool) -> void:
	var textura: Texture2D
	if ruta_textura != "" and ResourceLoader.exists(ruta_textura):
		textura = load(ruta_textura)
	else:
		textura = _generar_textura_gradiente(color_a, color_b, color_c)

	var disco := TextureRect.new()
	disco.texture = textura
	disco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disco.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	disco.position = pos - Vector2(radio, radio)
	disco.size = Vector2(radio * 2.0, radio * 2.0)
	var material := ShaderMaterial.new()
	material.shader = load(RUTA_SHADER_DISCO)
	material.set_shader_parameter("escala_de_grises", not desbloqueado)
	material.set_shader_parameter("desenfoque", 0.0 if desbloqueado else 0.8)
	material.set_shader_parameter("opacidad", 1.0 if desbloqueado else 0.55)
	disco.material = material
	_contenedor_planetas.add_child(disco)

	var etiqueta := Label.new()
	etiqueta.text = nombre
	etiqueta.add_theme_font_size_override("font_size", tamano_fuente)
	etiqueta.add_theme_color_override("font_color", Color(1, 1, 1, 0.55 if not desbloqueado else 0.92))
	etiqueta.add_theme_font_override("font", load(RUTA_FUENTE_NOMBRES))
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var offset_y: float = -(radio + 44.0) if etiqueta_arriba else radio + 10.0
	etiqueta.position = pos + Vector2(-100, offset_y)
	etiqueta.size = Vector2(200, 40)
	_contenedor_planetas.add_child(etiqueta)


func _generar_textura_gradiente(color_a: Color, color_b: Color, color_c: Color) -> GradientTexture2D:
	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	degradado.colors = PackedColorArray([color_a, color_b, color_c])
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.34, 0.28)
	textura.fill_to = Vector2(0.95, 0.28)
	return textura


## Puerto directo de la funcion `nave(d)` del mockup: estaciona la navecita a la
## izquierda del disco del planeta actual (el ultimo desbloqueado), mas cerca cuanto
## mas grande es el disco.
func _posicionar_nave() -> void:
	var indice: int = clampi(PLANETAS_DESBLOQUEADOS_STUB, 1, PLANETAS.size()) - 1
	var datos: Dictionary = PLANETAS[indice]
	var radio: float = datos["radio"]
	var escala: float = datos["escala"]
	var cx: float = (datos["pos"] as Vector2).x
	var cy: float = (datos["pos"] as Vector2).y - float(datos["dy"])
	var dx: float = radio + 75.0 * escala + 30.0 * escala
	if indice == 0:
		_nave.position = Vector2(cx - dx, cy - (radio + 55.0 + 22.0))
	else:
		_nave.position = Vector2(cx - dx, cy)
	_nave.scale = Vector2.ONE * clampf(escala, 0.55, 1.0)


## Balanceo continuo de la navecita (equivalente a `he-bob 1.8s` del mockup).
func _iniciar_bob_nave() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_forma_nave, "position:y", -8.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_forma_nave, "rotation", deg_to_rad(3.0), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_forma_nave, "position:y", 0.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_forma_nave, "rotation", deg_to_rad(-3.0), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _pintar_burbuja() -> void:
	var indice: int = clampi(PLANETAS_DESBLOQUEADOS_STUB, 1, PLANETAS.size()) - 1
	var datos: Dictionary = PLANETAS[indice]
	_burbuja_texto.text = "¡Vamos al Planeta %s!" % str(datos["nombre"])
	_ruta_voz_actual = "res://assets/audio/voces/planetas/%s_invitacion_01.ogg" % str(datos["id"])


## Invitacion de Cometa (voz), repetida como en `titulo.gd`/`seleccion_personaje.gd`
## (GDD §6 regla 2: ninguna instruccion depende de saber leer, aunque la burbuja de
## texto tambien la muestre para Sofia). La linea todavia no esta grabada — `Audio`
## avisa por consola sin romper la pantalla (mismo contrato ya usado en el resto del
## nucleo).
func _reproducir_invitacion() -> void:
	Audio.reproducir_voz(_ruta_voz_actual)


func _registrar_regiones() -> void:
	_regiones.append({"rect": Rect2(_boton_casa.global_position, _boton_casa.size), "accion": func(): _ir_a_seleccion()})
	_regiones.append({"rect": Rect2(_boton_papas.global_position, _boton_papas.size), "accion": func(): _ir_a_titulo()})
	_regiones.append({"rect": Rect2(_boton_hangar.global_position, _boton_hangar.size), "accion": func(): _tocar_hangar()})


func _unhandled_input(evento: InputEvent) -> void:
	var posicion: Vector2
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		posicion = (evento as InputEventScreenTouch).position
	elif evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		posicion = (evento as InputEventMouseButton).position
	else:
		return
	for region in _regiones:
		if (region["rect"] as Rect2).has_point(posicion):
			(region["accion"] as Callable).call()
			return


func _ir_a_seleccion() -> void:
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	get_tree().change_scene_to_file(RUTA_SELECCION)


func _ir_a_titulo() -> void:
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	get_tree().change_scene_to_file(RUTA_TITULO)


## El hangar estelar (progreso de la nave pieza a pieza, HE-14+) todavia no existe: el
## boton igual responde al toque con feedback inmediato (GDD §6 regla 5, nunca un
## elemento "muerto" en pantalla) aunque hoy no navegue a ningun lado.
func _tocar_hangar() -> void:
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	var tween := create_tween()
	tween.tween_property(_boton_hangar, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(_boton_hangar, "scale", Vector2(1.0, 1.0), 0.16)
