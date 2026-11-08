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
## Margen extra alrededor del disco de un planeta jugable: el area tocable siempre supera
## los 96 px de GDD §6.1 aunque el disco se dibuje mas chico.
const MARGEN_TOQUE_PLANETA := 28.0

## Los 6 planetas del capitulo 1 (GDD §2), en el orden fijo de la ruta, mas chicos a
## medida que se alejan. Cada uno se dibuja redondo con sus propios atributos
## (`planeta_dibujado.gd` + `planeta.gdshader`, 27-Sep-2026): ya no se recorta arte
## rectangular dentro de un disco.
const TIERRA := {"id": "tierra", "nombre": "La Tierra", "pos": Vector2(92, 620), "radio": 70.0}
const PLANETAS := [
	{"id": "arcoiris", "nombre": "Arcoíris", "pos": Vector2(318, 478), "radio": 86.0, "mapa": "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn", "datos": "res://datos/planetas/arcoiris/mapa.json"},
	{"id": "animalia", "nombre": "Animalia", "pos": Vector2(530, 290), "radio": 70.0, "mapa": "res://escenas/planetas/animalia/mapa_animalia.tscn", "datos": "res://datos/planetas/animalia/mapa.json"},
	{"id": "melodia", "nombre": "Melodía", "pos": Vector2(705, 480), "radio": 60.0},
	{"id": "cuenta_cuentas", "nombre": "Cuenta-Cuentas", "pos": Vector2(880, 290), "radio": 54.0},
	{"id": "letralandia", "nombre": "Letralandia", "pos": Vector2(1045, 450), "radio": 48.0},
	{"id": "corazon", "nombre": "Corazón", "pos": Vector2(1185, 265), "radio": 44.0},
]
## Recorte de la cara en los retratos oficiales (512x768, pies en y=720) para el HUD.
const REGION_CARA := Rect2(146, 62, 220, 220)
## Centro de la nave sobre la superficie del planeta donde está posada (media altura del
## sprite a escala 0.2, menos un poquito para que se vea apoyada y no flotando).
const ALTO_NAVE_SOBRE_PLANETA := 22.0
const RUTA_VIAJE := "res://escenas/nucleo/viaje_estelar.tscn"

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

## STUB de entrada a un planeta (hasta HE-09 `Navegacion`): un planeta con "mapa" abre su mapa
## interno de zonas y estaciones (`mapa_planeta.gd`, datos en `datos/planetas/<id>/mapa.json`),
## que es quien lanza los minijuegos. Un planeta con "escena"/"nivel" abre ese motor directo
## (queda para pruebas). El mapa solo conoce el CONTRATO de `minijuego_base.gd`, nunca la
## mecanica concreta (regla de oro 3). Desde el 14-Sep-2026 Arcoiris abre su mapa de zonas.
##
## Solo el Planeta 1 (Arcoiris) es real y jugable en este capitulo (stack-tecnico.md,
## decision del 18-Jul-2026 "lanzamiento por capitulos"). HE-08 reemplaza este numero
## fijo por el progreso real del hermano activo (piezas de nave conseguidas).
const PLANETAS_DESBLOQUEADOS_STUB := 1

## HE-120 (05-Nov-2026) y HE-82 (07-Nov-2026): el planeta siguiente se abre cuando el `mapa.json` del
## anterior cumple su `viaje_siguiente_requiere` ({"partida": id} -> `Progreso.partida_hecha(id)`, estado
## FAMILIAR de HE-81: viaja cualquier hermano, tenga o no su pieza). Mientras no se cumple, ese planeta es el
## "destino en espera" (motor-lanzar §13.4 M9): lejano, sin candado; al tocarlo late, suena una voz de
## `voz_destino_espera` del planeta de origen y una flechita de luz vuelve al origen. Modo de desarrollo para revisar
## Animalia sin terminar Arcoiris: F6 (solo builds de depuracion) o `-- abrir_planetas` en la linea de
## comandos. No se guarda: es una vista del PO, como F4 en el mapa de un planeta.
static var abrir_planetas_dev := false
## M9: las variantes de `voz_destino_espera` se alternan entre visitas al Mapa (vive en la sesion).
static var _indice_voz_espera := 0

const SFX_TILIN_TONO := 1.6
const SEGUNDOS_FLECHITA := 2.0
const COLOR_FLECHITA := Color(1.0, 0.92, 0.55)

var _desbloqueados := PLANETAS_DESBLOQUEADOS_STUB

@onready var _camino: Node2D = $camino
@onready var _contenedor_planetas: Node2D = $contenedor_planetas
@onready var _nave: Node2D = $nave
@onready var _forma_nave: Node2D = $nave/forma_nave
@onready var _estela_nave: CanvasItem = $nave/forma_nave/estela
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
var _despegando := false
## Nodo dibujado de cada planeta por id (latido, respiracion del origen).
var _nodos_planeta := {}
## `mapa.json` ya leidos (ruta -> Dictionary).
var _mapas_leidos := {}
## M9: la voz del destino en espera suena como maximo una vez por visita.
var _voz_espera_dicha := false
var _flechita: Line2D


func _ready() -> void:
	_id_perfil = Progreso.perfil_seleccionado if Progreso.perfil_seleccionado != "" else "maxi"
	if "abrir_planetas" in OS.get_cmdline_user_args() or "--abrir_planetas" in OS.get_cmdline_user_args():
		abrir_planetas_dev = true
	_desbloqueados = planetas_desbloqueados()
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


## Cuantos planetas de la ruta estan abiertos: el 1 siempre; cada siguiente, si el anterior cumple su
## `viaje_siguiente_requiere` (o con el modo de desarrollo).
func planetas_desbloqueados() -> int:
	var abiertos := PLANETAS_DESBLOQUEADOS_STUB
	while abiertos < PLANETAS.size():
		var siguiente: Dictionary = PLANETAS[abiertos]
		if str(siguiente.get("mapa", "")) == "" or not ResourceLoader.exists(str(siguiente["mapa"])):
			break
		if not (abrir_planetas_dev or _viaje_cumplido(PLANETAS[abiertos - 1])):
			break
		abiertos += 1
	return abiertos


## true si el `viaje_siguiente_requiere` del planeta `datos` se cumple. Sin el bloque, el siguiente no se abre.
func _viaje_cumplido(datos: Dictionary) -> bool:
	var requiere = _leer_mapa(datos).get("viaje_siguiente_requiere", null)
	if not requiere is Dictionary:
		return false
	var partida := str((requiere as Dictionary).get("partida", ""))
	return partida != "" and Progreso.partida_hecha(partida)


func _leer_mapa(datos: Dictionary) -> Dictionary:
	var ruta := str(datos.get("datos", ""))
	if ruta == "":
		return {}
	if not _mapas_leidos.has(ruta):
		var mapa: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta)) if FileAccess.file_exists(ruta) else null
		_mapas_leidos[ruta] = mapa if mapa is Dictionary else {}
	return _mapas_leidos[ruta]


## Indice en PLANETAS del destino en espera (M9): el siguiente al ultimo abierto, si ese ultimo declara un
## `viaje_siguiente_requiere` que todavia no se cumple. -1 si no hay (o con el modo de desarrollo).
func indice_destino_en_espera() -> int:
	if abrir_planetas_dev or _desbloqueados >= PLANETAS.size():
		return -1
	var origen: Dictionary = PLANETAS[_desbloqueados - 1]
	if not _leer_mapa(origen).get("viaje_siguiente_requiere", null) is Dictionary or _viaje_cumplido(origen):
		return -1
	return _desbloqueados


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_F6 and OS.is_debug_build():
		abrir_planetas_dev = not abrir_planetas_dev
		print("[mapa_estelar] F6 planetas abiertos para revisar: %s" % abrir_planetas_dev)
		get_tree().reload_current_scene()


func _pintar_hud() -> void:
	var perfil := Progreso.obtener_perfil(_id_perfil)
	var color: Color = COLORES_HERMANO.get(_id_perfil, Color.WHITE)
	_hud_nombre.text = str(perfil.get("nombre", _id_perfil.capitalize()))
	_hud_nivel.text = str(perfil.get("perfil_dificultad", ""))
	_hud_nivel.add_theme_color_override("font_color", color)
	_hud_destellos.text = str(Progreso.obtener_destellos_totales(_id_perfil))
	var ruta_retrato: String = RETRATOS_HERMANO.get(_id_perfil, "")
	if ruta_retrato != "" and ResourceLoader.exists(ruta_retrato):
		var cara := AtlasTexture.new()
		cara.atlas = load(ruta_retrato)
		cara.region = REGION_CARA
		_hud_retrato.texture = cara
	var estilo_base: StyleBox = _hud_anillo.get_theme_stylebox("panel")
	if estilo_base is StyleBoxFlat:
		var estilo: StyleBoxFlat = (estilo_base as StyleBoxFlat).duplicate()
		estilo.border_color = color
		_hud_anillo.add_theme_stylebox_override("panel", estilo)


func _pintar_camino() -> void:
	var curva := _construir_curva_camino()
	_camino.fijar_curva(curva)
	var indice_actual: int = clampi(_desbloqueados, 1, PLANETAS.size()) - 1
	var offset_meta: float = curva.get_closest_offset(PLANETAS[indice_actual]["pos"])
	var largo_total: float = curva.get_baked_length()
	_camino.proporcion = 0.0 if largo_total <= 0.0 else offset_meta / largo_total


## Curva suave que sale de la Tierra y pasa exactamente por el centro de cada planeta
## (tangentes tipo Catmull-Rom).
func _construir_curva_camino() -> Curve2D:
	var puntos: Array[Vector2] = [TIERRA["pos"] + Vector2(40, -30)]
	for datos in PLANETAS:
		puntos.append(datos["pos"])
	var curva := Curve2D.new()
	curva.bake_interval = 6.0
	for i in puntos.size():
		var previo: Vector2 = puntos[maxi(i - 1, 0)]
		var siguiente: Vector2 = puntos[mini(i + 1, puntos.size() - 1)]
		var tangente := (siguiente - previo) * 0.28
		curva.add_point(puntos[i], -tangente, tangente)
	return curva


func _pintar_tierra() -> void:
	_crear_planeta(TIERRA, true, false)


func _pintar_planetas() -> void:
	var indice_actual: int = clampi(_desbloqueados, 1, PLANETAS.size()) - 1
	for i in PLANETAS.size():
		var desbloqueado: bool = (i + 1) <= _desbloqueados
		var planeta := _crear_planeta(PLANETAS[i], desbloqueado, i == indice_actual)
		if i == indice_actual:
			_latir(planeta)


func _crear_planeta(datos: Dictionary, desbloqueado: bool, actual: bool) -> Node2D:
	var radio: float = datos["radio"]
	var pos: Vector2 = datos["pos"]
	if actual:
		# aura dorada del planeta al que vamos (se lee sin saber leer: "ahi toca ir")
		var aura := TextureRect.new()
		var degradado := Gradient.new()
		degradado.colors = PackedColorArray([Color(1, 0.85, 0.3, 0.55), Color(1, 0.85, 0.3, 0.0)])
		var textura := GradientTexture2D.new()
		textura.gradient = degradado
		textura.fill = GradientTexture2D.FILL_RADIAL
		textura.fill_from = Vector2(0.5, 0.5)
		textura.fill_to = Vector2(1.0, 0.5)
		aura.texture = textura
		aura.size = Vector2.ONE * radio * 3.6
		aura.position = pos - aura.size / 2.0
		aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_contenedor_planetas.add_child(aura)
	var planeta := PlanetaDibujado.new()
	_nodos_planeta[str(datos["id"])] = planeta
	planeta.id_planeta = datos["id"]
	planeta.radio = radio
	planeta.apagado = not desbloqueado
	planeta.position = pos
	_contenedor_planetas.add_child(planeta)
	# la Tierra esta pegada al borde inferior: su nombre va arriba
	var abajo: bool = pos.y + radio + 50.0 < 720.0
	var arriba := -radio - 48.0
	if Progreso.obtener_ubicacion_nave(_id_perfil) == datos["id"]:
		arriba -= ALTO_NAVE_SOBRE_PLANETA * 2.0 + 8.0  # por encima de la nave posada
	_crear_etiqueta(str(datos["nombre"]), pos + Vector2(0, radio + 14.0 if abajo else arriba), radio, desbloqueado, actual)
	return planeta


## Nombre en una pildora bajo el planeta (Sofia lee; los chicos se guian por la voz).
func _crear_etiqueta(nombre: String, centro_arriba: Vector2, radio: float, desbloqueado: bool, actual: bool) -> void:
	var etiqueta := Label.new()
	etiqueta.text = nombre
	etiqueta.add_theme_font_override("font", load(RUTA_FUENTE_NOMBRES))
	etiqueta.add_theme_font_size_override("font_size", clampi(int(radio * 0.34), 17, 28))
	etiqueta.add_theme_color_override("font_color", Color(0.23, 0.11, 0.45) if actual else Color(1, 1, 1, 0.92 if desbloqueado else 0.6))
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 0.84, 0.3) if actual else Color(0.075, 0.04, 0.19, 0.55)
	fondo.set_corner_radius_all(20)
	fondo.content_margin_left = 14
	fondo.content_margin_right = 14
	fondo.content_margin_top = 0
	fondo.content_margin_bottom = 2
	etiqueta.add_theme_stylebox_override("normal", fondo)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor_planetas.add_child(etiqueta)
	etiqueta.reset_size()
	etiqueta.position = centro_arriba - Vector2(etiqueta.size.x / 2.0, 0)


func _latir(planeta: Node2D) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(planeta, "scale", Vector2.ONE * 1.05, 1.1) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(planeta, "scale", Vector2.ONE, 1.1) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## La nave-estrella (diseño final) está posada ENCIMA del planeta donde quedó estacionada
## (`Progreso.obtener_ubicacion_nave`): toda aventura empieza sobre la Tierra y, después de
## cada viaje, la nave queda sobre el planeta al que se llegó.
func _posicionar_nave() -> void:
	var datos := _datos_planeta(Progreso.obtener_ubicacion_nave(_id_perfil))
	_nave.position = (datos["pos"] as Vector2) + Vector2(0, -float(datos["radio"]) - ALTO_NAVE_SOBRE_PLANETA)
	_nave.scale = Vector2.ONE
	_estela_nave.visible = false  # estacionada: sin estela de vuelo
	_pintar_piezas_nave()


## HE-82 (motor-lanzar §13.4): la pieza de cada planeta se dibuja PUESTA en la nave si su partida esta hecha
## (estado familiar); antes, el hermano que ya la gano la ve envuelta junto a la nave. Lee `pieza_nave.id`
## ("ala_izquierda", "ala_derecha", ...) de cada `mapa.json`; dibujo provisional por codigo hasta el arte.
func _pintar_piezas_nave() -> void:
	var puestas: Array[Dictionary] = []
	var envueltas: Array[Dictionary] = []
	for datos in PLANETAS:
		var pieza = _leer_mapa(datos).get("pieza_nave", null)
		if not pieza is Dictionary or str((pieza as Dictionary).get("id", "")) == "":
			continue
		var entrada := {"id": str(pieza["id"]), "planeta": str(datos["id"])}
		if Progreso.partida_hecha(str(datos["id"])):
			puestas.append(entrada)
		elif Progreso.tiene_pieza_nave(_id_perfil, str(datos["id"])):
			envueltas.append(entrada)
	var lienzo := Node2D.new()
	lienzo.name = "piezas_nave"
	lienzo.show_behind_parent = true
	_forma_nave.add_child(lienzo)
	lienzo.set_meta("puestas", puestas.map(func(e): return e["id"]))
	lienzo.set_meta("envueltas", envueltas.map(func(e): return e["id"]))
	lienzo.draw.connect(func() -> void:
		for e in puestas:
			_dibujar_pieza_puesta(lienzo, e)
		for k in envueltas.size():
			_dibujar_pieza_envuelta(lienzo, envueltas[k], k))
	lienzo.queue_redraw()


func _colores_planeta(planeta_id: String) -> Array[Color]:
	var estilo: Dictionary = PlanetaDibujado.ESTILOS.get(planeta_id, PlanetaDibujado.ESTILOS["arcoiris"])
	var colores: Array[Color] = []
	for i in 3:
		colores.append(Color(str(estilo["colores"][i])))
	return colores


## Ala de tres franjas con los colores de su planeta, pegada al costado de la nave (82 x 55 px a escala 0.2).
func _dibujar_pieza_puesta(lienzo: CanvasItem, pieza: Dictionary) -> void:
	var lado := -1.0 if "izquierd" in str(pieza["id"]) else 1.0
	var colores := _colores_planeta(str(pieza["planeta"]))
	for k in 3:
		var a := 1.0 - k * 0.22
		var forma := PackedVector2Array([Vector2(lado * 18, -4), Vector2(lado * (18 + 26 * a), -16 * a - 2),
			Vector2(lado * (18 + 30 * a), 4), Vector2(lado * 18, 10)])
		lienzo.draw_colored_polygon(forma, colores[k])
	lienzo.draw_polyline(PackedVector2Array([Vector2(lado * 18, -4), Vector2(lado * 44, -18), Vector2(lado * 48, 4),
		Vector2(lado * 18, 10)]), PlanetaDibujado.CONTORNO, 2.0, true)


## Paquetito con moño al pie de la nave: la pieza ganada que espera la ceremonia.
func _dibujar_pieza_envuelta(lienzo: CanvasItem, pieza: Dictionary, k: int) -> void:
	var lado := -1.0 if "izquierd" in str(pieza["id"]) else 1.0
	var centro := Vector2(lado * (54 + 26 * k), 14)
	var caja := Rect2(centro - Vector2(11, 9), Vector2(22, 18))
	lienzo.draw_rect(caja, _colores_planeta(str(pieza["planeta"]))[0])
	lienzo.draw_rect(caja, PlanetaDibujado.CONTORNO, false, 2.0)
	lienzo.draw_line(centro + Vector2(0, -9), centro + Vector2(0, 9), Color.WHITE, 3.0)
	lienzo.draw_line(centro + Vector2(-11, 0), centro + Vector2(11, 0), Color.WHITE, 3.0)
	lienzo.draw_circle(centro + Vector2(-4, -11), 4.0, Color.WHITE)
	lienzo.draw_circle(centro + Vector2(4, -11), 4.0, Color.WHITE)


func _datos_planeta(id: String) -> Dictionary:
	for datos in PLANETAS:
		if datos["id"] == id:
			return datos
	return TIERRA


## Balanceo continuo de la navecita (equivalente a `he-bob 1.8s` del mockup).
func _iniciar_bob_nave() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_forma_nave, "position:y", -3.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_forma_nave, "rotation", deg_to_rad(2.0), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_forma_nave, "position:y", 0.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_forma_nave, "rotation", deg_to_rad(-2.0), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _pintar_burbuja() -> void:
	var indice: int = clampi(_desbloqueados, 1, PLANETAS.size()) - 1
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
	for i in mini(_desbloqueados, PLANETAS.size()):
		var datos: Dictionary = PLANETAS[i]
		if str(datos.get("escena", "")) == "" and str(datos.get("mapa", "")) == "":
			continue
		var radio: float = datos["radio"]
		var rect := Rect2(datos["pos"] - Vector2(radio, radio), Vector2(radio, radio) * 2.0).grow(MARGEN_TOQUE_PLANETA)
		_regiones.append({"rect": rect, "accion": _entrar_planeta.bind(datos)})
	# Los planetas lejanos tambien responden (GDD §6: nada muerto en pantalla), sin candado ni "bup": el
	# destino en espera con su voz y la flechita (M9); los demas, solo el latido.
	for i in range(mini(_desbloqueados, PLANETAS.size()), PLANETAS.size()):
		var datos: Dictionary = PLANETAS[i]
		var radio: float = datos["radio"]
		var rect := Rect2(datos["pos"] - Vector2(radio, radio), Vector2(radio, radio) * 2.0).grow(MARGEN_TOQUE_PLANETA)
		_regiones.append({"rect": rect, "accion": tocar_planeta_lejano.bind(i)})


## Toque en un planeta todavia no abierto (M9 de motor-lanzar §13.4 si es el destino en espera): late en el
## mismo frame (escala 1,08 y vuelta en 0,25 s) con un tilin; el destino en espera dice ademas una voz de
## `voz_destino_espera` del planeta de origen (alternadas entre visitas, maximo una por visita) y una
## flechita de luz va al origen, que respira. Nunca abre nada.
func tocar_planeta_lejano(indice: int) -> void:
	if _despegando or indice < 0 or indice >= PLANETAS.size():
		return
	var datos: Dictionary = PLANETAS[indice]
	var nodo: Node2D = _nodos_planeta.get(str(datos["id"]), null)
	if nodo != null:
		nodo.scale = Vector2.ONE * 1.08
		var tween := create_tween()
		tween.tween_property(nodo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Audio.reproducir_sfx(RUTA_SFX_TOQUE, SFX_TILIN_TONO)
	if indice != indice_destino_en_espera():
		return
	var origen: Dictionary = PLANETAS[indice - 1]
	_mostrar_flechita(datos["pos"], origen["pos"], float(datos["radio"]), float(origen["radio"]))
	var nodo_origen: Node2D = _nodos_planeta.get(str(origen["id"]), null)
	if nodo_origen != null:
		var respira := create_tween()
		respira.tween_property(nodo_origen, "modulate", Color(1.25, 1.2, 1.05), 0.5).set_trans(Tween.TRANS_SINE)
		respira.tween_property(nodo_origen, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	if _voz_espera_dicha:
		return
	var voces = _leer_mapa(origen).get("voz_destino_espera", [])
	if voces is String:
		voces = [voces]
	if not voces is Array or (voces as Array).is_empty():
		return
	_voz_espera_dicha = true
	_temporizador_recordatorio.start()  # que la invitacion no pise la voz
	var ruta := str(voces[_indice_voz_espera % (voces as Array).size()])
	_indice_voz_espera += 1
	Audio.reproducir_voz(ruta if ruta.begins_with("res://") else "res://assets/audio/" + ruta)


## Flechita de luz del destino al origen (2 s): la linea crece, y al llegar se desvanece.
func _mostrar_flechita(desde: Vector2, hasta: Vector2, radio_desde: float, radio_hasta: float) -> void:
	if _flechita != null and is_instance_valid(_flechita):
		_flechita.queue_free()
	var direccion := (hasta - desde).normalized()
	var inicio := desde + direccion * (radio_desde + 8.0)
	var fin := hasta - direccion * (radio_hasta + 14.0)
	_flechita = Line2D.new()
	_flechita.name = "flechita_espera"
	_flechita.width = 7.0
	_flechita.default_color = COLOR_FLECHITA
	_flechita.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_flechita.end_cap_mode = Line2D.LINE_CAP_ROUND
	_flechita.points = PackedVector2Array([inicio, inicio])
	add_child(_flechita)
	var linea := _flechita
	# el tween vive en la linea: si un toque nuevo la reemplaza, su tween muere con ella
	var tween := linea.create_tween()
	tween.tween_method(func(t: float) -> void:
		var punta := inicio.lerp(fin, t)
		var normal := Vector2(-direccion.y, direccion.x)
		linea.points = PackedVector2Array([inicio, punta, punta - direccion * 16.0 + normal * 11.0, punta,
			punta - direccion * 16.0 - normal * 11.0]), 0.0, 1.0, SEGUNDOS_FLECHITA * 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(linea, "modulate:a", 0.0, SEGUNDOS_FLECHITA * 0.4)
	tween.tween_callback(linea.queue_free)


## `_input` y no `_unhandled_input`: las tarjetas/botones son `Panel` (filtro STOP), que se
## quedan con el clic en la GUI y nunca llegaba a las regiones. Aqui se resuelve antes.
func _input(evento: InputEvent) -> void:
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
			get_viewport().set_input_as_handled()
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


## Abre el motor del planeta como escena actual. Las senales se conectan al SceneTree (que
## sobrevive al cambio de escena), no a este mapa, que se libera al salir: al terminar la
## celebracion o tocar "salir" se vuelve al mapa, con el progreso ya guardado por el contrato.
func _entrar_planeta(datos: Dictionary) -> void:
	if _despegando:
		return
	# si la nave está en otro planeta, primero se viaja (minijuego pixel del viaje estelar)
	if Progreso.obtener_ubicacion_nave(_id_perfil) != str(datos["id"]) and ResourceLoader.exists(RUTA_VIAJE):
		_viajar_a(datos)
		return
	var ruta_mapa := str(datos.get("mapa", ""))
	if ruta_mapa != "" and ResourceLoader.exists(ruta_mapa):
		Audio.reproducir_sfx(RUTA_SFX_TOQUE)
		_temporizador_recordatorio.stop()
		get_tree().change_scene_to_file(ruta_mapa)
		return
	var ruta_escena := str(datos.get("escena", ""))
	if not ResourceLoader.exists(ruta_escena):
		push_warning("mapa_estelar: el planeta %s no tiene escena jugable (%s)" % [datos["id"], ruta_escena])
		return
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	_temporizador_recordatorio.stop()
	var motor: Node = (load(ruta_escena) as PackedScene).instantiate()
	# Ruta personalizada (GDD §5): cada hermano abre su propio nivel; "nivel" es el respaldo.
	var niveles: Dictionary = datos.get("niveles", {})
	motor.ruta_nivel = str(niveles.get(_id_perfil, datos.get("nivel", "")))
	motor.planeta_id = str(datos["id"])
	motor.id_perfil = _id_perfil
	var arbol := get_tree()
	var volver_al_mapa := Callable(arbol, "change_scene_to_file").bind(scene_file_path)
	motor.completado.connect(volver_al_mapa.unbind(1), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	motor.salir_solicitado.connect(volver_al_mapa, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	arbol.root.add_child(motor)
	arbol.current_scene = motor
	queue_free()


## La nave despega del planeta donde está (un saltito en el mapa) y se abre el viaje estelar
## de ese origen a ese destino. Al terminar, los destellos del camino y la nueva ubicación
## quedan guardados y se entra al planeta. Las señales van a `Progreso`/`SceneTree`, que
## sobreviven al cambio de escena (este mapa se libera).
func _viajar_a(datos: Dictionary) -> void:
	_despegando = true
	_temporizador_recordatorio.stop()
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	var origen := Progreso.obtener_ubicacion_nave(_id_perfil)
	var destino := str(datos["id"])
	var tween := create_tween()
	tween.tween_property(_nave, "position:y", _nave.position.y - 50.0, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_nave, "modulate:a", 0.0, 0.35).set_delay(0.2)
	await tween.finished
	var viaje: Node = (load(RUTA_VIAJE) as PackedScene).instantiate()
	viaje.planeta_origen = origen
	viaje.planeta_destino = destino
	var ruta_mapa := str(datos.get("mapa", ""))
	var siguiente := ruta_mapa if ruta_mapa != "" and ResourceLoader.exists(ruta_mapa) else scene_file_path
	var arbol := get_tree()
	viaje.completado.connect(Progreso.registrar_viaje.bind(_id_perfil, destino), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	viaje.completado.connect(Callable(arbol, "change_scene_to_file").bind(siguiente).unbind(1), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	arbol.root.add_child(viaje)
	arbol.current_scene = viaje
	queue_free()
