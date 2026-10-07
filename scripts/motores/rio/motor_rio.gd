class_name MotorRio
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecánica "rio" — «Río de pintura», tipo Zuma (docs/roadmap-rio-de-pintura.md).
## Primer juego del Planeta Arcoíris para los tres hermanos (decisión del PO 06-Oct-2026): Coco, en su
## plato giratorio al centro, atrapa y dispara gotas con la lengua a un río de pintura que avanza por un
## cauce de galleta hacia el remolino gris. Tres iguales juntas revientan; si los extremos del corte
## coinciden, el río retrocede y revienta en cadena. Sofía mezcla primarios (rojo + azul = violeta).
## Maxi juega lo mismo que Nicole, solo que más lento.
##
## Hito H1 (núcleo jugable): reglas completas, Coco provisional (coco_base.png con tinte, lengua y
## gestos simples), récord y estrellas. Los poderes, la cresta súper y el arte final llegan en H2-H4.
##
## Las reglas viven en `LogicaRio` (probadas por `herramientas/qa_test_rio.gd`); aquí solo hay dibujo,
## entrada y el flujo de ganar o perder. Todo lo que cambia entre hermanos llega en el JSON del nivel.
##
## Entrada: tocar (o arrastrar) apunta y al soltar Coco dispara; tocar a Coco cambia la gota de la
## boca con la de la mano. Perder nunca castiga: "¡Glu glu glu!" y reintento de un toque (GDD §6).

signal partida_terminada(gano: bool, puntos: int)

const Figura := preload("res://scripts/ui/figura_vectorial.gd")
const TEXTURA_COCO := preload("res://assets/sprites/personajes/coco_base.png")

const PALETA := {
	"rojo": Color("#E8434B"), "amarillo": Color("#FFC83A"), "azul": Color("#3D7BE0"),
	"verde": Color("#36B866"), "naranja": Color("#FF8A3D"), "violeta": Color("#9B5DE5"),
	"rosa": Color("#FF7EB6"), "celeste": Color("#5CC8F0"),
}
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"
const SFX_LENGUA := "sfx/ui/toque.ogg"
const SFX_INSERTA := "sfx/ui/soltar.ogg"
const SFX_REVIENTA := "sfx/ui/confirmar.ogg"
const SFX_CAMBIO := "sfx/ui/seleccionar.ogg"
const SFX_GLU := "sfx/ui/zona_dormida.ogg"
const SFX_GANA := "sfx/ui/abrir.ogg"
const COLOR_CONTORNO := Color("#2B3350")
const TINTA := Color("#272140")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
const TURQUESA := Color("#45C6C0")
## Coco: altura en pantalla, distancia de la gota cargada al centro y radio para tocarla.
const ALTO_COCO := 168.0
const ORBITA := 86.0
const RADIO_TOQUE_COCO := 72.0
const PELIGRO := 0.82
const SEGUNDOS_RESUMEN_VICTORIA := 2.4

@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _boton_salir: Button = %boton_salir
@onready var _fin: Control = %fin
@onready var _boton_reintentar: Button = %boton_reintentar
@onready var _confeti: CPUParticles2D = %confeti

var logica := LogicaRio.new()
var recorrido: RecorridoRio
var _fuente: Font
var _cauce: Control

# Configuración visual (del nivel)
var _guia := "completa"  ## completa | corta | no
var _guia_largo := 1280.0
var _tiempo_par := 70.0
var _semilla := -1

# Estado de pantalla
var _t := 0.0
var _angulo := -PI / 2.0
var _apuntando := false
var _mirando := 1.0  ## 1 derecha, -1 izquierda (con histéresis, para que no tiemble)
var _lengua := 0.0  ## 0-1: estirón de la lengua al disparar
var _carga := 1.0  ## 0-1: la gota nueva "brota" en la boca
var _salto := 0.0
var _giro_coco := 0.0
var _tinte := Color.WHITE
var _gris := 0.0  ## 0-1: Coco chorreada después del glu glu
var _particulas: Array = []  ## {"pos", "vel", "r", "color", "vida"}
var _textos: Array = []  ## {"pos", "texto", "color", "t", "dur", "tam"}
var _record := 0
var _record_nuevo := false
var _estrellas := 0
var _fase := "jugando"  ## jugando | tragando | resumen | celebrando | perdio
var _ultimo_combo := 0


func _ready() -> void:
	super._ready()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_estilizar_boton(_boton_salir, CREMA)
	_estilizar_boton(_boton_reintentar, DORADO)
	_icono(_boton_salir, _dibujar_flecha)
	_icono(_boton_reintentar, _dibujar_icono_reintentar)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_boton_reintentar.pressed.connect(reintentar)
	_fin.gui_input.connect(_al_input_fin)
	_fin.draw.connect(_dibujar_fin)
	_fin.hide()
	# El cauce no cambia: se dibuja una vez en su propio Control, detrás de las gotas.
	_cauce = Control.new()
	_cauce.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_juego.add_child(_cauce)
	_cauce.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cauce.show_behind_parent = true
	_cauce.draw.connect(_dibujar_cauce)
	_juego.gui_input.connect(_al_input_juego)
	_juego.draw.connect(_dibujar_juego)
	_hud.draw.connect(_dibujar_hud)
	_configurar_confeti()
	logica.reventaron.connect(_al_reventar)
	logica.mezclaron.connect(_al_mezclar)
	logica.insertada.connect(_al_insertar)
	logica.empezo_a_tragar.connect(_al_empezar_a_tragar)
	logica.termino.connect(_al_terminar)
	if nivel.is_empty():
		push_error("motor_rio: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()


func _configurar_desde_nivel() -> void:
	var ruta_recorrido := str(nivel.get("recorrido", "res://datos/recorridos/arcoiris/z1_espiral.json"))
	recorrido = RecorridoRio.desde_archivo(ruta_recorrido)
	_guia = str(nivel.get("guia", "completa"))
	_guia_largo = float(nivel.get("guia_largo", 1280.0))
	_tiempo_par = float(nivel.get("tiempo_par", 70.0))
	logica.configurar(nivel, recorrido, _semilla)
	_record = _leer_record()
	_cauce.queue_redraw()
	_texto_flotante(recorrido.centro + Vector2(0, 150), "¡Junta 3 iguales!" if not logica.mezcla else "¡Mezcla y junta 3!", Color("#2E9E5B"), 2.6, 34)


## Fija la semilla del río antes de entrar al árbol (arnés QA: partidas deterministas).
func fijar_semilla(semilla: int) -> void:
	_semilla = semilla


func fase() -> String:
	return _fase


func reintentar() -> void:
	if _fase != "perdio":
		return
	reproducir_sfx(SFX_CAMBIO)
	_fin.hide()
	_gris = 0.0
	_particulas.clear()
	_textos.clear()
	_record_nuevo = false
	_fase = "jugando"
	logica.reiniciar()
	_tinte = Color.WHITE


func _process(delta: float) -> void:
	_t += delta
	if recorrido == null:
		return
	logica.avanzar(delta)
	_lengua = maxf(0.0, _lengua - delta / 0.14)
	_carga = minf(1.0, _carga + delta / 0.16)
	_salto = maxf(0.0, _salto - delta * 3.0)
	_giro_coco = move_toward(_giro_coco, 0.0, delta * 9.0)
	if _fase != "perdio":
		_gris = maxf(0.0, _gris - delta * 0.5) if _fase == "jugando" else _gris
	var objetivo := Color.WHITE.lerp(_color(logica.actual), 0.3) if logica.actual != "" else Color.WHITE
	_tinte = _tinte.lerp(objetivo, clampf(delta * 8.0, 0.0, 1.0))
	if absf(cos(_angulo)) > 0.25:
		_mirando = signf(cos(_angulo))
	for p in _particulas:
		p["vel"].y += 900.0 * delta
		p["pos"] += p["vel"] * delta
		p["vida"] -= delta
	_particulas = _particulas.filter(func(p): return p["vida"] > 0.0)
	for x in _textos:
		x["t"] += delta
	_textos = _textos.filter(func(x): return x["t"] < x["dur"])
	_juego.queue_redraw()
	_hud.queue_redraw()
	if _fin.visible:
		_fin.queue_redraw()


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _al_input_juego(evento: InputEvent) -> void:
	if recorrido == null:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_juego.accept_event()
		if _fase != "jugando":
			return
		if evento.pressed:
			if evento.position.distance_to(_centro_coco()) < RADIO_TOQUE_COCO:
				intercambiar()
				return
			_apuntando = true
			_apuntar(evento.position)
		elif _apuntando:
			_apuntando = false
			_apuntar(evento.position)
			disparar()
	elif evento is InputEventMouseMotion and _apuntando:
		_apuntar(evento.position)
		_juego.accept_event()


func _apuntar(p: Vector2) -> void:
	if p.distance_to(recorrido.centro) > 30.0:
		_angulo = (p - recorrido.centro).angle()


func apuntar_a(p: Vector2) -> void:
	_apuntar(p)


func disparar() -> bool:
	if logica.disparar(recorrido.centro + Vector2.from_angle(_angulo) * ORBITA, _angulo):
		_lengua = 1.0
		_carga = 0.0
		reproducir_sfx(SFX_LENGUA)
		return true
	return false


func intercambiar() -> void:
	if _fase != "jugando":
		return
	logica.intercambiar()
	_giro_coco = 1.0
	_carga = 0.4
	reproducir_sfx(SFX_CAMBIO)


func _al_input_fin(evento: InputEvent) -> void:
	# Tocar en cualquier parte del cartel también reintenta (Maxi no busca el botón).
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_fin.accept_event()
		reintentar()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	# PC: espacio dispara, Tab cambia la gota.
	if evento.keycode == KEY_SPACE:
		disparar()
	elif evento.keycode == KEY_TAB:
		intercambiar()


# ---------------------------------------------------------------------------
# Eventos del río
# ---------------------------------------------------------------------------

func _al_insertar(_posicion: Vector2, _color_id: String) -> void:
	reproducir_sfx(SFX_INSERTA)


func _al_reventar(cantidad: int, centro: Vector2, color_id: String, cadena: int, ganados: int) -> void:
	for k in cantidad * (3 if cantidad > 4 else 4):
		var a := randf() * TAU
		var v := randf_range(120.0, 420.0)
		_particulas.append({"pos": centro + Vector2.from_angle(a) * randf() * 20.0, "vel": Vector2.from_angle(a) * v + Vector2(0, -120),
			"r": logica.radio * randf_range(0.14, 0.36), "color": color_id, "vida": randf_range(0.6, 1.1)})
	_texto_flotante(centro, "+%d" % ganados, TINTA, 1.0, 30)
	if cadena > 1:
		_texto_flotante(recorrido.centro + Vector2(0, -150), "¡Cadena x%d!" % cadena, Color("#FF8A3D"), 1.3, 46)
		_giro_coco = 1.0
	_salto = 1.0 if cadena > 1 else 0.6
	# El reventón sube un semitono por cada eslabón de la cadena (como en Zuma).
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_sfx(resolver_ruta_audio(SFX_REVIENTA), pow(2.0, minf(cadena - 1, 12) / 12.0))


func _al_mezclar(a: String, b: String, resultado: String, posicion: Vector2) -> void:
	_texto_flotante(posicion + Vector2(0, -46), "%s + %s = %s" % [a, b, resultado], _color(resultado).darkened(0.15), 1.6, 26)


func _al_empezar_a_tragar() -> void:
	_fase = "tragando"
	_apuntando = false
	_texto_flotante(recorrido.fin + Vector2(0, -76), "¡Glu glu!", Color("#655D82"), 1.3, 42)
	reproducir_sfx(SFX_GLU)


func _al_terminar(gano: bool) -> void:
	_record_nuevo = _guardar_record(logica.puntos)
	partida_terminada.emit(gano, logica.puntos)
	if gano:
		_estrellas = LogicaRio.estrellas_por_tiempo(logica.tiempo, _tiempo_par)
		_fase = "resumen"
		reproducir_sfx(SFX_GANA)
		_confeti.position = recorrido.centro
		_confeti.restart()
		_confeti.emitting = true
		_texto_flotante(recorrido.centro + Vector2(0, -170), "¡Río limpio!", Color("#2E9E5B"), SEGUNDOS_RESUMEN_VICTORIA, 58)
		get_tree().create_timer(SEGUNDOS_RESUMEN_VICTORIA).timeout.connect(_celebrar_victoria)
	else:
		_fase = "perdio"
		_gris = 1.0
		_fin.show()


func _celebrar_victoria() -> void:
	if _fase != "resumen":
		return
	_fase = "celebrando"
	celebrar(10 + _estrellas * 5, _estrellas, _linea_voz("victoria"))


func _linea_voz(clave: String) -> String:
	var lineas = nivel.get("lineas_voz", {}).get(clave, "")
	if lineas is Array:
		return str(lineas.pick_random()) if not lineas.is_empty() else ""
	return str(lineas)


func _leer_record() -> int:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso == null or planeta_id == "" or id_perfil == "":
		return _record
	return progreso.obtener_record_nivel(id_perfil, planeta_id, _id_nivel_actual())


func _guardar_record(puntaje: int) -> bool:
	if puntaje <= _record:
		return false
	_record = puntaje
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and id_perfil != "":
		progreso.registrar_puntaje_nivel(id_perfil, planeta_id, _id_nivel_actual(), puntaje)
	return true


func _texto_flotante(posicion: Vector2, texto: String, color: Color, duracion: float, tamano: int) -> void:
	_textos.append({"pos": posicion, "texto": texto, "color": color, "t": 0.0, "dur": duracion, "tam": tamano})


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _color(id_color: String) -> Color:
	return PALETA.get(id_color, Color("#B9B4C9"))


func _centro_coco() -> Vector2:
	return recorrido.centro + Vector2(0, -6)


## Cauce de galleta con glaseado de menta (roadmap §4.1), dibujado una sola vez.
func _dibujar_cauce() -> void:
	if recorrido == null:
		return
	var puntos := PackedVector2Array()
	for i in range(0, recorrido.puntos.size(), 3):
		puntos.append(recorrido.puntos[i])
	puntos.append(recorrido.fin)
	var ancho := logica.radio * 2.0
	_cauce.draw_polyline(puntos, Color("#B98A5E", 0.55), ancho + 26.0, true)
	_cauce.draw_polyline(puntos, Color("#E9C58F"), ancho + 18.0, true)
	_cauce.draw_polyline(puntos, Color("#BDEFD9"), ancho + 8.0, true)
	_cauce.draw_polyline(puntos, Color("#FFF6E8"), ancho + 2.0, true)
	# Chispitas de colores en el glaseado (como el camino de chispitas del mapa).
	var colores := PALETA.values()
	for i in range(0, puntos.size(), 9):
		var p := puntos[i]
		var lado := 1.0 if (i / 9) % 2 == 0 else -1.0
		var dir := (puntos[mini(i + 1, puntos.size() - 1)] - p).normalized().orthogonal()
		_cauce.draw_circle(p + dir * lado * (ancho * 0.5 + 6.0), 2.6, Color(colores[(i / 9) % colores.size()], 0.85))


func _dibujar_juego() -> void:
	if recorrido == null:
		return
	_dibujar_nube()
	_dibujar_remolino()
	# De la cola a la cabeza: la cabeza queda encima.
	for i in range(logica.gotas.size() - 1, -1, -1):
		var g: Dictionary = logica.gotas[i]
		var s: float = g["s"]
		if s < -2.0:
			continue
		var p := recorrido.posicion(s)
		if g["ot"] > 0.0:
			p = g["origen"].lerp(p, 1.0 - g["ot"] / 0.12)
		var cerca := recorrido.largo - s
		var escala := maxf(0.2, cerca / logica.diametro()) if cerca < logica.diametro() else 1.0
		_dibujar_gota(_juego, p, logica.radio * escala, g["color"], g["id"])
	_dibujar_guia()
	for bala in logica.balas:
		_dibujar_gota(_juego, bala["pos"], logica.radio, bala["color"], 7)
	for p in _particulas:
		_juego.draw_circle(p["pos"], p["r"], Color(_color(p["color"]), minf(1.0, p["vida"] * 2.0)))
	_dibujar_coco()
	for x in _textos:
		var k: float = x["t"] / x["dur"]
		var escala := 0.7 + k * 2.0 if k < 0.15 else 1.0
		var alfa := (1.0 - k) / 0.25 if k > 0.75 else 1.0
		_texto(_juego, x["texto"], x["pos"] - Vector2(0, k * 40.0), int(x["tam"] * escala), Color(x["color"], alfa))


## Gota de pintura con carita (las del río parpadean cada tanto).
func _dibujar_gota(lienzo: Control, c: Vector2, r: float, id_color: String, id: int, cara := true) -> void:
	var base := _color(id_color)
	lienzo.draw_circle(c + Vector2(0, r * 0.12), r * 0.95, Color(COLOR_CONTORNO, 0.18))
	lienzo.draw_circle(c, r * 0.95, base.darkened(0.38))
	lienzo.draw_circle(c, r * 0.95 - maxf(2.0, r * 0.08), base)
	lienzo.draw_circle(c + Vector2(r * 0.12, r * 0.16), r * 0.62, base.darkened(0.08))
	lienzo.draw_circle(c - Vector2(r * 0.1, r * 0.12), r * 0.55, base.lightened(0.1))
	_elipse(lienzo, c + Vector2(-r * 0.38, -r * 0.42), Vector2(r * 0.22, r * 0.12), -0.6, Color(1, 1, 1, 0.8))
	if not cara or r < 8.0:
		return
	var parpadeo := fmod(_t * 1000.0 + id * 733.0, 4100.0) < 130.0
	for lado in [-1.0, 1.0]:
		var ojo := c + Vector2(lado * r * 0.27, r * 0.02)
		if parpadeo:
			lienzo.draw_line(ojo - Vector2(r * 0.1, 0), ojo + Vector2(r * 0.1, 0), TINTA, maxf(1.5, r * 0.07), true)
		else:
			lienzo.draw_circle(ojo, r * 0.11, TINTA)
			lienzo.draw_circle(ojo + Vector2(r * 0.04, -r * 0.04), r * 0.04, Color.WHITE)
	lienzo.draw_arc(c + Vector2(0, r * 0.22), r * 0.14, 0.15 * PI, 0.85 * PI, 10, TINTA, maxf(1.5, r * 0.07), true)


func _elipse(lienzo: Control, c: Vector2, radios: Vector2, angulo: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		puntos.append(c + Vector2(cos(a) * radios.x, sin(a) * radios.y).rotated(angulo))
	lienzo.draw_colored_polygon(puntos, color)


## La nube gris que destiñe el planeta asoma donde nace el río (roadmap §4.2). Se infla si llueve mucho.
func _dibujar_nube() -> void:
	var base := recorrido.posicion(0.0)
	var c := Vector2(base.x, minf(base.y, 720.0) - 30.0)
	var llenas := 0
	for g in logica.gotas:
		if g["s"] < 0.0:
			llenas += 1
	var inflado := 1.0 + minf(0.18, llenas * 0.006) + sin(_t * 2.0) * 0.02
	var gris := Color("#A9A5B8")
	for b in [Vector2(-46, 6), Vector2(46, 6), Vector2(-20, -18), Vector2(22, -22), Vector2(0, 10)]:
		_juego.draw_circle(c + b * inflado, 34.0 * inflado, gris.darkened(0.25))
	for b in [Vector2(-46, 6), Vector2(46, 6), Vector2(-20, -18), Vector2(22, -22), Vector2(0, 10)]:
		_juego.draw_circle(c + b * inflado, 30.0 * inflado, gris)
	# Cara de berrinche (chistosa, nunca de miedo).
	for lado in [-1.0, 1.0]:
		_juego.draw_circle(c + Vector2(lado * 16, -6), 4.5, TINTA)
		_juego.draw_line(c + Vector2(lado * 8, -18), c + Vector2(lado * 24, -14), TINTA, 3.0, true)
	_juego.draw_arc(c + Vector2(0, 14), 9.0, 1.15 * PI, 1.85 * PI, 10, TINTA, 3.0, true)
	_juego.draw_circle(c + Vector2(-30, 6), 6.0, Color("#E7B6C8", 0.7))
	_juego.draw_circle(c + Vector2(30, 6), 6.0, Color("#E7B6C8", 0.7))


## El remolino gris que se traga el río. Avisa peligro con un pulso rojo y al ganar florece.
func _dibujar_remolino() -> void:
	var c := recorrido.fin
	if _fase in ["resumen", "celebrando"]:
		var colores := PALETA.values()
		for k in 6:
			var a := TAU * k / 6.0 + _t * 0.6
			_juego.draw_circle(c + Vector2.from_angle(a) * 30.0, 24.0, colores[k])
		_juego.draw_circle(c, 22.0, DORADO)
		Figura.dibujar_cara(_juego, c, 0.5, true)
		return
	var peligro := logica.progreso_cabeza() > PELIGRO and _fase == "jugando"
	if peligro:
		_juego.draw_circle(c, 74.0, Color(0.91, 0.26, 0.29, 0.3 + 0.2 * sin(_t * 8.0)))
	for k in 5:
		_juego.draw_circle(c, 48.0 - k * 8.0, Color("#A7A4B4").lerp(Color("#3C3A48"), k / 4.0))
	var giro := _t * (2.4 + logica.progreso_cabeza() * 3.0)
	for brazo in 3:
		var linea := PackedVector2Array()
		var a := 0.0
		while a < 4.2:
			var r := 42.0 - a * 8.5
			linea.append(c + Vector2.from_angle(a + giro + brazo * 2.09) * r)
			a += 0.1
		_juego.draw_polyline(linea, Color(1, 1, 1, 0.55), 3.0, true)


## Línea de puntería: puntitos del color cargado hasta la gota donde pegaría.
func _dibujar_guia() -> void:
	if _guia == "no" or _fase != "jugando" or logica.actual == "":
		return
	var dir := Vector2.from_angle(_angulo)
	var p := recorrido.centro + dir * ORBITA
	var color := _color(logica.actual)
	var golpe := -1
	var recorrido_guia := 0.0
	var k := 0
	while recorrido_guia < _guia_largo:
		p += dir * 8.0
		recorrido_guia += 8.0
		k += 1
		if p.x < 0 or p.x > 1280 or p.y < 0 or p.y > 720:
			break
		golpe = logica.gota_en(p, logica.diametro() * 0.92)
		if golpe >= 0:
			break
		if k % 3 == 2:
			_juego.draw_circle(p, logica.radio * 0.16, Color(color, 0.8 * (1.0 - recorrido_guia / (_guia_largo + 1.0) * 0.5)))
	if golpe >= 0:
		var q := recorrido.posicion(logica.gotas[golpe]["s"])
		var segmentos := 16
		for s in segmentos:
			if s % 2 == 0:
				var a0 := TAU * s / segmentos + _t
				_juego.draw_arc(q, logica.radio + 7.0, a0, a0 + TAU / segmentos, 4, color, 4.0, true)


## Coco provisional (H1): el sprite canon con tinte del color cargado, lengua que sostiene la gota y la
## gota de reserva en la mano. El rig animado completo es el hito H2 (roadmap §3).
func _dibujar_coco() -> void:
	var c := _centro_coco()
	var dir := Vector2.from_angle(_angulo)
	# Plato giratorio de torta: las chispitas giran con la puntería.
	var plato := c + Vector2(0, 76)
	_elipse(_juego, plato + Vector2(0, 10), Vector2(86, 30), 0.0, Color("#E7A9C4"))
	_elipse(_juego, plato, Vector2(86, 30), 0.0, Color("#FFD9E8"))
	_elipse(_juego, plato, Vector2(70, 22), 0.0, Color("#FFF1F6"))
	var colores := PALETA.values()
	for k in 10:
		var a := _angulo + TAU * k / 10.0
		_juego.draw_circle(plato + Vector2(cos(a) * 78.0, sin(a) * 26.0), 3.2, colores[k % colores.size()])
	_juego.draw_circle(plato + Vector2(cos(_angulo) * 78.0, sin(_angulo) * 26.0), 7.0, DORADO)
	# Coco: respira, salta al reventar, gira al cambiar de gota, se inclina hacia donde apunta.
	var escala := ALTO_COCO / float(TEXTURA_COCO.get_height())
	var respira := 1.0 + sin(_t * 2.6) * 0.018
	var salto := sin(_salto * PI) * 26.0
	var temblor := Vector2(sin(_t * 47.0) * 2.0, 0) if _fase == "jugando" and logica.progreso_cabeza() > PELIGRO else Vector2.ZERO
	var inclinacion := clampf(dir.x * 0.12, -0.12, 0.12) + sin(_giro_coco * PI) * 0.35 * _mirando
	var tam := Vector2(TEXTURA_COCO.get_width(), TEXTURA_COCO.get_height()) * escala
	var pos := c + Vector2(0, -salto) + temblor
	var tinte := _tinte.lerp(Color(0.62, 0.62, 0.68), _gris)
	_juego.draw_set_transform(pos, inclinacion, Vector2(_mirando * (2.0 - respira), respira))
	_juego.draw_texture_rect(TEXTURA_COCO, Rect2(-tam / 2.0, tam), false, tinte)
	_juego.draw_set_transform_matrix(Transform2D.IDENTITY)
	var boca := pos + Vector2(1.3 * _mirando, -14.5).rotated(inclinacion)
	# Gotita de sudor cuando el río está por llegar al remolino (nunca llora).
	if temblor != Vector2.ZERO:
		var sudor := pos + Vector2(-34.0 * _mirando, -52.0 + fmod(_t * 30.0, 18.0))
		Figura.dibujar(_juego, "gota", Color("#8FD8F5"), sudor, 9.0, false)
	# Chorreada de gris después del glu glu.
	if _gris > 0.05:
		for k in 5:
			var x := -36.0 + k * 18.0
			_juego.draw_line(pos + Vector2(x, -60), pos + Vector2(x, -60 + 22.0 + 14.0 * sin(k * 1.7 + _t * 3.0)), Color("#8E8A9C", _gris), 8.0, true)
	# Gota de reserva en la mano contraria a la que apunta.
	if logica.siguiente != "" and _fase in ["jugando", "tragando"]:
		_dibujar_gota(_juego, pos + Vector2(-38.0 * _mirando, 34.0), logica.radio * 0.62, logica.siguiente, 2, false)
	# Lengua: sostiene la gota cargada y se estira al disparar.
	if _fase in ["jugando", "tragando"]:
		var largo := ORBITA + sin(_lengua * PI) * 44.0
		var punta := c + dir * largo
		_juego.draw_line(boca, punta, Color("#C9567A"), 13.0, true)
		_juego.draw_line(boca, punta, Color("#FF8FB1"), 9.0, true)
		_juego.draw_circle(punta, 7.0, Color("#FF8FB1"))
		if logica.actual != "" and _lengua < 0.5:
			_dibujar_gota(_juego, c + dir * ORBITA, logica.radio * (0.4 + 0.6 * _carga), logica.actual, 1)


func _dibujar_hud() -> void:
	if recorrido == null:
		return
	# Puntos y récord, en una píldora arriba al centro.
	var caja := Rect2(470, 14, 340, 74)
	_hud.draw_style_box(_caja_hud(), caja)
	_texto(_hud, str(logica.puntos), Vector2(caja.position.x + 100, caja.position.y + 40), 42, TINTA)
	Figura.dibujar(_hud, "estrella", DORADO, Vector2(caja.position.x + 214, caja.position.y + 37), 17.0, false)
	_texto(_hud, str(maxi(_record, logica.puntos)), Vector2(caja.position.x + 278, caja.position.y + 40), 30, Color("#2E9E5B"))
	# Cuánto río queda: barra que se llena a medida que se vacía el río.
	var barra := Rect2(1040, 34, 200, 20)
	_hud.draw_style_box(_caja_hud(), barra.grow(8))
	var frac := 1.0 - float(logica.gotas.size()) / maxf(1.0, logica.total)
	_hud.draw_rect(Rect2(barra.position, Vector2(barra.size.x * frac, barra.size.y)), Color("#2E9E5B"))
	_dibujar_gota(_hud, barra.position + Vector2(barra.size.x + 2, barra.size.y / 2.0), 14.0, "azul", 0, false)
	# Sofía: las tres recetas de mezcla, siempre a la vista.
	if logica.mezcla:
		var recetas := [["amarillo", "azul", "verde"], ["rojo", "amarillo", "naranja"], ["rojo", "azul", "violeta"]]
		for i in recetas.size():
			var y := 120.0 + i * 46.0
			var x := 1094.0
			_dibujar_gota(_hud, Vector2(x, y), 14.0, recetas[i][0], 0, false)
			_texto(_hud, "+", Vector2(x + 26, y), 24, Color("#655D82"))
			_dibujar_gota(_hud, Vector2(x + 52, y), 14.0, recetas[i][1], 0, false)
			_texto(_hud, "=", Vector2(x + 78, y), 24, Color("#655D82"))
			_dibujar_gota(_hud, Vector2(x + 110, y), 18.0, recetas[i][2], 0, false)


func _caja_hud() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(CREMA, 0.92)
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(4)
	caja.set_corner_radius_all(40)
	caja.anti_aliasing = true
	return caja


## Cartel de "¡Glu glu glu!": cómico, con el puntaje y el botón grande de otra vez.
func _dibujar_fin() -> void:
	_fin.draw_rect(Rect2(Vector2.ZERO, _fin.size), Color(COLOR_CONTORNO, 0.35))
	var tarjeta := Rect2(390, 150, 500, 400)
	var caja := _caja_hud()
	caja.set_corner_radius_all(48)
	caja.bg_color = CREMA
	_fin.draw_style_box(caja, tarjeta)
	var rebote := sin(_t * 5.0) * 6.0
	_texto(_fin, "¡Glu glu glu!", Vector2(640, 214 + rebote), 56, Color("#655D82"))
	_texto(_fin, str(logica.puntos), Vector2(590, 296), 44, TINTA)
	Figura.dibujar(_fin, "estrella", DORADO, Vector2(668, 293), 18.0, false)
	_texto(_fin, str(_record), Vector2(722, 296), 32, Color("#2E9E5B"))
	if _record_nuevo:
		_texto(_fin, "¡Nuevo récord!", Vector2(640, 344), 30, Color("#FF8A3D"))


func _texto(lienzo: Control, texto: String, centro: Vector2, tamano: int, color: Color) -> void:
	var fuente := _fuente if _fuente != null else ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var base := centro + Vector2(-ancho / 2.0, tamano * 0.35)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, maxi(4, int(tamano * 0.18)), Color(1, 1, 1, 0.95 * color.a))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


# ---------------------------------------------------------------------------
# Botones e iconos (mismo estilo que los demás motores)
# ---------------------------------------------------------------------------

func _configurar_confeti() -> void:
	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	degradado.colors = PackedColorArray(Figura.COLORES_ARCOIRIS)
	_confeti.color_initial_ramp = degradado


func _icono(boton: Button, dibujo: Callable) -> void:
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(dibujo.bind(icono))


func _estilizar_boton(boton: Button, fondo: Color) -> void:
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = fondo.darkened(0.12) if estado == "pressed" else fondo
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(5)
		caja.set_corner_radius_all(90)
		caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
		caja.shadow_offset = Vector2(0, 5)
		caja.shadow_size = 2
		caja.anti_aliasing = true
		boton.add_theme_stylebox_override(estado, caja)
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	boton.button_down.connect(func() -> void:
		boton.pivot_offset = boton.size / 2.0
		boton.scale = Vector2(0.9, 0.9)
		boton.create_tween().tween_property(boton, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


func _dibujar_flecha(icono: Control) -> void:
	var c := icono.size / 2.0
	var k := icono.size.x / 96.0
	var puntos := PackedVector2Array()
	for p in [Vector2(-26, 0), Vector2(2, -26), Vector2(2, -12), Vector2(26, -12), Vector2(26, 12), Vector2(2, 12), Vector2(2, 26)]:
		puntos.append(c + p * k)
	icono.draw_colored_polygon(puntos, TURQUESA)
	Figura.contornear(icono, puntos, 5.0 * k)


## Flecha circular de "otra vez" (sin texto, GDD §6 regla 3).
func _dibujar_icono_reintentar(icono: Control) -> void:
	var c := icono.size / 2.0
	var r := icono.size.x * 0.27
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, COLOR_CONTORNO, 22.0, true)
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, CREMA, 13.0, true)
	var punta := c + Vector2.from_angle(-PI * 0.15) * r
	var flecha := PackedVector2Array([punta + Vector2(-22, -6), punta + Vector2(18, -10), punta + Vector2(4, 26)])
	icono.draw_colored_polygon(flecha, CREMA)
	Figura.contornear(icono, flecha, 5.0)
