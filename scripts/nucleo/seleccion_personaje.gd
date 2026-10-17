extends Node2D
## Pantalla de seleccion de personaje (HE-06 en Backlog — implementada aqui como parte
## del paquete de UI ad-hoc del mockup del PO "UI Sistema").
##
## 3 tarjetas grandes (Maxi/Nicole/Sofia), cada una un objetivo tactil enorme (320x~400
## px, muy por encima del minimo de 96 px — GDD §6 regla 1). Al tocar una tarjeta se fija
## el perfil activo en `Progreso` (autoload real, HE-07) y se navega al mapa estelar. El
## boton "volver" hace lo opuesto: vuelve al titulo sin tocar el perfil.
##
## Entrada unificada tactil+mouse por region (mismo patron que `titulo.gd`, adaptado a
## multiples objetivos): en vez de "toda la pantalla es un boton", cada tarjeta/boton
## define su rectangulo y se resuelve cual se toco en `_input`.
##
## MODO EQUIPO (HE-59, docs/fichas/modo-equipo.md §3): el boton "¡Juntos!" (la nave de juguete con las tres
## caritas en sus ventanitas y las 5 estrellitas del equipo) aparece SOLO como premio al ganar la batalla
## (`Progreso.modo_equipo_desbloqueado()`); antes, la seleccion es exactamente la de siempre (sin candado ni
## hueco). Al tocarlo se arma el equipo: las tres tarjetas parten adentro, tocar una la saca al puf o la
## vuelve a subir, minimo dos, y "¡Despegar!" (la misma nave con fuego, en el mismo lugar) lleva al mapa de
## Arcoiris en modo equipo. La presentacion unica ocurre la primera vez que se abre con el modo disponible.
## F5 (solo builds de depuracion) muestra "¡Juntos!" sin la batalla, para que el PO lo revise.

const RUTA_SFX_TOQUE := "res://assets/audio/sfx/ui/seleccionar.ogg"
const RUTA_SFX_VOLVER := "res://assets/audio/sfx/ui/cerrar.ogg"
const RUTA_SFX_SALTO := "res://assets/audio/sfx/ui/blup.ogg"
const RUTA_SFX_PUF := "res://assets/audio/sfx/ui/puf.ogg"
const RUTA_VOZ_INVITACION := "res://assets/audio/voces/nucleo/seleccion_invitacion_01.ogg"
const SEGUNDOS_ENTRE_RECORDATORIOS := 12.0
const RUTA_MAPA := "res://escenas/nucleo/mapa_estelar.tscn"
## v1 del modo equipo: "¡Despegar!" va directo al mapa de Arcoiris en modo equipo (§3.3).
const RUTA_MAPA_EQUIPO := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"
const PLANETA_EQUIPO := "arcoiris"
const RUTA_TITULO := "res://escenas/nucleo/titulo.tscn"
const RUTA_ALBUM := "res://escenas/nucleo/album_recuerdos.tscn"
const BotonAlbum := preload("res://scripts/ui/boton_album.gd")
const EntregaRecuerdoScript := preload("res://scripts/ui/entrega_recuerdo.gd")
const BarraEquipo := preload("res://scripts/ui/barra_equipo.gd")
## Boton del album de recuerdos (ficha album-recuerdos §7). Va AQUI y no en el titulo: el titulo
## entero es un solo objetivo tactil ("toca para empezar") y un boton adentro competiria con el;
## la seleccion es donde se juntan los tres, sin perfil elegido, y el album es de todos.
## UX HE-44 R7 (03-Oct-2026): 36 px bajo la tarjeta de Sofia (antes 18) y 78 px de "volver".
const RECT_ALBUM := Rect2(930, 596, 140, 120)
## "¡Juntos!" y "¡Despegar!" ocupan el MISMO rectangulo (M5.4): 44 px de aire con el globo, 50 con el
## album y 38 con la tarjeta de Nicole.
const RECT_JUNTOS := Rect2(640, 598, 240, 110)
## Cometa (abajo a la izquierda) se puede tocar mientras se arma el equipo: repite la consigna (M4).
const RECT_COMETA := Rect2(50, 572, 112, 120)
const IDS := ["maxi", "nicole", "sofia"]
const COLOR_CONTORNO := Color("#2B3350")
const DORADO := Color("#FFCB3D")
const VOCES_EQUIPO := {
	"presenta": "res://assets/audio/voces/nucleo/equipo/presenta.wav",
	"invitacion": "res://assets/audio/voces/nucleo/seleccion_invitacion_equipo.wav",
	"juntos": "res://assets/audio/voces/nucleo/equipo/juntos.wav",
	"armar": "res://assets/audio/voces/nucleo/equipo/armar.wav",
	"minimo_dos": "res://assets/audio/voces/nucleo/equipo/minimo_dos.wav",
	"despegar": "res://assets/audio/voces/nucleo/equipo/despegar.wav",
	"al_puf": "res://assets/audio/voces/nucleo/equipo/al_puf_%s.wav",
	"sube_nave": "res://assets/audio/voces/nucleo/equipo/sube_nave_%s.wav",
	"yo_tambien": "res://assets/audio/voces/nucleo/equipo/yo_tambien_%s.wav",
}

@onready var _temporizador_recordatorio: Timer = $temporizador_recordatorio
@onready var _boton_volver: Control = $boton_volver

## Cada region tactil: rectangulo en coordenadas de pantalla + accion a ejecutar.
var _regiones: Array[Dictionary] = []
var _bloqueado := false
var _boton_album: Control
var _entrega: Node

var _nave: Control
var _armando := false
var _en_nave := {"maxi": true, "nicole": true, "sofia": true}
var _asientos := {}
var _tiempo := 0.0
var _invitacion_equipo := false
var _presentando := false


func _ready() -> void:
	# El equipo vive en memoria y se vacia cada vez que se abre la seleccion (§11.5).
	Progreso.limpiar_equipo()
	_registrar_regiones()
	_crear_boton_album()
	_crear_nave_si_corresponde()
	_temporizador_recordatorio.wait_time = SEGUNDOS_ENTRE_RECORDATORIOS
	_temporizador_recordatorio.timeout.connect(_reproducir_invitacion)
	if _entregar_primera_apertura():
		return
	if _presentar_nave_si_corresponde():
		return
	_reproducir_invitacion()
	_temporizador_recordatorio.start()
	_avisar_foto_nueva()


func _process(delta: float) -> void:
	_tiempo += delta
	if _nave != null and _nave.visible and not _presentando:
		# Vaiven suave en reposo (+-3 grados, 2,4 s); nunca parpadea.
		_nave.rotation = deg_to_rad(3.0) * sin(_tiempo * TAU / 2.4)
		_nave.queue_redraw()


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_F5 and OS.is_debug_build():
		Progreso.forzar_modo_equipo_depuracion = not Progreso.forzar_modo_equipo_depuracion
		print("[seleccion] F5 modo equipo forzado (depuracion): %s" % Progreso.forzar_modo_equipo_depuracion)
		if _armando:
			_salir_de_armar()
		_crear_nave_si_corresponde()


func _crear_boton_album() -> void:
	_boton_album = BotonAlbum.new()
	_boton_album.name = "boton_album"
	_boton_album.position = RECT_ALBUM.position
	_boton_album.size = RECT_ALBUM.size
	add_child(_boton_album)
	_boton_album.tocado.connect(_abrir_album)


## Primera vez que se abre el juego (con el album): la foto familiar "antes del secuestro" llega
## en su sobre-estrella y vuela a este boton. Evento generico: el nucleo no sabe que foto es.
func _entregar_primera_apertura() -> bool:
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null:
		return false
	var nuevos: Array = recuerdos.desbloquear({"tipo": "primera_apertura"}, "")
	if nuevos.is_empty():
		return false
	_bloqueado = true
	_entrega = EntregaRecuerdoScript.crear(nuevos, RECT_ALBUM.get_center())
	# Guion §1.1 en orden fijo (UX N1, 02-Oct-2026): primero que paso ("¡pffft!, se le volaron las
	# fotos"), y al guardar la foto, que las demas andan flotando. La historia no se corta: el sobre
	# espera la frase completa.
	var lineas: Array = recuerdos.catalogo.get("voces", {}).get("primera", [])
	if not lineas.is_empty():
		_entrega.voz_sobre = recuerdos.ruta_linea(str(lineas[0]))
		_entrega.esperar_frase_completa = true
	if lineas.size() > 1:
		_entrega.voz_final = recuerdos.ruta_linea(str(lineas[1]))
	_entrega.rebote_album.connect(func() -> void: _boton_album.rebotar())
	_entrega.terminada.connect(_al_terminar_entrega)
	add_child(_entrega)
	return true


func _al_terminar_entrega() -> void:
	_entrega = null
	_bloqueado = false
	# La presentacion de la nave espera a que la entrega termine: nunca se superponen (§3.1).
	if _presentar_nave_si_corresponde():
		return
	_temporizador_recordatorio.start()


## "¡Psst! Hay una foto nueva esperando en el album" (una vez al entrar, si esta grabada).
func _avisar_foto_nueva() -> void:
	var recuerdos := get_node_or_null("/root/Recuerdos")
	if recuerdos == null or not recuerdos.hay_nuevos():
		return
	var ruta: String = recuerdos.elegir_linea("album_nueva")
	if ruta == "":
		return
	await get_tree().create_timer(3.5).timeout
	if is_inside_tree() and not _bloqueado:
		Audio.reproducir_voz(ruta)


func _abrir_album() -> void:
	if _bloqueado or _armando:
		return
	_bloqueado = true
	_temporizador_recordatorio.stop()
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	Audio.detener_voz()
	get_tree().change_scene_to_file(RUTA_ALBUM)


func _registrar_regiones() -> void:
	for id_perfil in IDS:
		var tarjeta: Control = get_node("tarjeta_%s" % id_perfil)
		_regiones.append({
			"rect": Rect2(tarjeta.global_position, tarjeta.size),
			"accion": func(): _elegir_perfil(id_perfil),
		})
	_regiones.append({
		"rect": Rect2(_boton_volver.global_position, _boton_volver.size),
		"accion": func(): _volver_a_titulo(),
	})
	_regiones.append({"rect": RECT_JUNTOS, "accion": func(): _tocar_nave()})
	_regiones.append({"rect": RECT_COMETA, "accion": func(): _tocar_cometa()})


func _reproducir_invitacion() -> void:
	if _armando:
		return
	# M5.3: con el modo disponible, el recordatorio alterna entre la invitacion de siempre y la de la nave.
	if _nave != null and _nave.visible and _invitacion_equipo and ResourceLoader.exists(VOCES_EQUIPO["invitacion"]):
		Audio.reproducir_voz(VOCES_EQUIPO["invitacion"])
		_saltito(_nave)
	else:
		Audio.reproducir_voz(RUTA_VOZ_INVITACION)
	if _nave != null and _nave.visible:
		_invitacion_equipo = not _invitacion_equipo


## `_input` y no `_unhandled_input`: las tarjetas/botones son `Panel` (filtro STOP), que se
## quedan con el clic en la GUI y nunca llegaba a las regiones. Aqui se resuelve antes.
## Solo InputEventScreenTouch (HE-59): el proyecto emula el toque desde el mouse, asi que en PC el clic
## tambien llega como toque. Antes se atendian los dos y cada clic contaba doble; con las tarjetas que
## alternan (armar equipo) eso las sacaba y metia en el mismo clic.
func _input(evento: InputEvent) -> void:
	if _bloqueado:
		return
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		tocar_en((evento as InputEventScreenTouch).position)


## Resuelve un toque en coordenadas de pantalla (tambien lo usan los arneses).
func tocar_en(posicion: Vector2) -> void:
	if _bloqueado:
		return
	for region in _regiones:
		if (region["rect"] as Rect2).has_point(posicion):
			get_viewport().set_input_as_handled()
			(region["accion"] as Callable).call()
			return


func _elegir_perfil(id_perfil: String) -> void:
	if _armando:
		_alternar_en_nave(id_perfil)
		return
	_bloqueado = true
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	Progreso.seleccionar_perfil(id_perfil)
	get_tree().change_scene_to_file(RUTA_MAPA)


func _volver_a_titulo() -> void:
	if _armando:
		# La flecha sale del modo equipo: reaparecen el album y el globo y el equipo queda vacio (§3.2).
		Audio.reproducir_sfx(RUTA_SFX_VOLVER)
		_salir_de_armar()
		return
	_bloqueado = true
	Audio.reproducir_sfx(RUTA_SFX_VOLVER)
	get_tree().change_scene_to_file(RUTA_TITULO)


# ---------------------------------------------------------------------------
# Modo equipo: "¡Juntos!" y armar el equipo (§3.1 y §3.2)
# ---------------------------------------------------------------------------

func _crear_nave_si_corresponde() -> void:
	var disponible: bool = Progreso.modo_equipo_desbloqueado()
	if _nave == null and disponible:
		_nave = Control.new()
		_nave.name = "boton_juntos"
		_nave.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_nave.position = RECT_JUNTOS.position
		_nave.size = RECT_JUNTOS.size
		_nave.pivot_offset = RECT_JUNTOS.size / 2.0
		_nave.draw.connect(_dibujar_nave)
		add_child(_nave)
		for i in IDS.size():
			var cara := TextureRect.new()
			cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cara.texture = BarraEquipo.cara(IDS[i])
			cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			cara.size = Vector2(44, 44)
			cara.position = Vector2(52 + i * 54, 20)
			if ResourceLoader.exists(BarraEquipo.SHADER_DISCO):
				var mascara := ShaderMaterial.new()
				mascara.shader = load(BarraEquipo.SHADER_DISCO)
				cara.material = mascara
			_nave.add_child(cara)
	if _nave != null:
		_nave.visible = disponible


## Presentacion unica (M5.2): la primera vez que la seleccion se abre con el modo disponible, la nave entra
## volando desde la derecha, se estaciona (1,5 s) y Cometa dice "¡Ahora pueden jugar juntos!".
func _presentar_nave_si_corresponde() -> bool:
	if _nave == null or not _nave.visible or Progreso.modo_equipo_presentado():
		return false
	_presentando = true
	_bloqueado = true
	var destino := _nave.position
	_nave.position = Vector2(1400, destino.y - 160)
	_nave.rotation = deg_to_rad(-12)
	var tween := _nave.create_tween()
	tween.tween_property(_nave, "position", destino, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_nave, "rotation", 0.0, 1.5)
	tween.tween_callback(func() -> void:
		_presentando = false
		_bloqueado = false
		if ResourceLoader.exists(VOCES_EQUIPO["presenta"]):
			Audio.reproducir_voz(VOCES_EQUIPO["presenta"])
		# Se marca al terminar la presentacion, no al empezarla.
		Progreso.marcar_modo_equipo_presentado()
		_invitacion_equipo = false
		_temporizador_recordatorio.start())
	return true


func _tocar_nave() -> void:
	if _nave == null or not _nave.visible:
		return
	if _armando:
		_despegar()
		return
	# Al tocar "¡Juntos!": la nave salta, "¡vamos juntos!" y se pasa a armar el equipo.
	_temporizador_recordatorio.stop()
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	_saltito(_nave)
	_voz(VOCES_EQUIPO["juntos"])
	_entrar_a_armar()


func _entrar_a_armar() -> void:
	_armando = true
	for id in IDS:
		_en_nave[id] = true
	# M5.4: se ocultan el album y el globo de texto para que no compitan.
	_boton_album.hide()
	var burbuja := get_node_or_null("burbuja_ayuda")
	if burbuja != null:
		burbuja.hide()
	for id in IDS:
		var tarjeta: Control = get_node("tarjeta_%s" % id)
		var asiento := _asientos.get(id, null) as Control
		if asiento == null:
			asiento = Control.new()
			asiento.mouse_filter = Control.MOUSE_FILTER_IGNORE
			asiento.size = Vector2(120, 44)
			asiento.position = Vector2((tarjeta.size.x - 120) / 2.0, tarjeta.size.y - 6)
			asiento.draw.connect(_dibujar_asiento.bind(asiento, id))
			tarjeta.add_child(asiento)
			_asientos[id] = asiento
		asiento.show()
		asiento.queue_redraw()
		tarjeta.modulate = Color.WHITE
		_saltito(tarjeta)
	_nave.queue_redraw()
	_despues(0.9, func() -> void: _voz(VOCES_EQUIPO["armar"]))


func _salir_de_armar() -> void:
	_armando = false
	_boton_album.show()
	var burbuja := get_node_or_null("burbuja_ayuda")
	if burbuja != null:
		burbuja.show()
	for id in IDS:
		var tarjeta: Control = get_node("tarjeta_%s" % id)
		tarjeta.modulate = Color.WHITE
		if _asientos.has(id):
			_asientos[id].hide()
	if _nave != null:
		for cara in _nave.get_children():
			(cara as CanvasItem).modulate = Color.WHITE
	Progreso.limpiar_equipo()
	if _nave != null:
		_nave.queue_redraw()
	_temporizador_recordatorio.start()


## Tocar una tarjeta la saca o la mete (§3.2). Al salir se sienta en el puf ("yo miro") al 60 % de brillo,
## nunca gris ni tachada; minimo 2: si se intenta sacar a uno con dos, la tarjeta se mece con carino.
func _alternar_en_nave(id: String) -> void:
	var tarjeta: Control = get_node("tarjeta_%s" % id)
	var adentro := IDS.filter(func(i: String) -> bool: return _en_nave[i])
	if _en_nave[id] and adentro.size() <= 2:
		_mecer(tarjeta)
		Audio.reproducir_sfx(RUTA_SFX_TOQUE)
		_voz(VOCES_EQUIPO["minimo_dos"])
		return
	_en_nave[id] = not _en_nave[id]
	if _en_nave[id]:
		tarjeta.modulate = Color.WHITE
		_saltito(tarjeta)
		Audio.reproducir_sfx(RUTA_SFX_SALTO)
		_voz(VOCES_EQUIPO["sube_nave"] % id)
		_voz_despues(VOCES_EQUIPO["yo_tambien"] % id)
	else:
		tarjeta.modulate = Color(0.6, 0.6, 0.6, 1.0)
		Audio.reproducir_sfx(RUTA_SFX_PUF)
		_voz(VOCES_EQUIPO["al_puf"] % id)
	if _asientos.has(id):
		_asientos[id].queue_redraw()
	# En la nave, la carita de quien mira desde el puf tambien queda al 60 %.
	if _nave != null and _nave.get_child_count() > IDS.find(id):
		(_nave.get_child(IDS.find(id)) as CanvasItem).modulate = Color.WHITE if _en_nave[id] else Color(0.6, 0.6, 0.6, 1.0)
	_nave.queue_redraw()


func equipo_armado() -> Array[String]:
	var ids: Array[String] = []
	for id in IDS:
		if _en_nave[id]:
			ids.append(id)
	return ids


func _despegar() -> void:
	var ids := equipo_armado()
	if ids.size() < 2:
		return
	_bloqueado = true
	_temporizador_recordatorio.stop()
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	_voz(VOCES_EQUIPO["despegar"])
	Progreso.fijar_equipo(ids)
	var tween := _nave.create_tween()
	tween.tween_property(_nave, "position:y", _nave.position.y - 30, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_nave, "position", Vector2(1400, -200), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(RUTA_MAPA_EQUIPO))


func _tocar_cometa() -> void:
	if not _armando:
		return
	Audio.reproducir_sfx(RUTA_SFX_TOQUE)
	_voz(VOCES_EQUIPO["armar"])
	var cometa := get_node_or_null("cometa_ayuda")
	if cometa is Node2D:
		var base: Vector2 = cometa.position
		var tween := create_tween()
		tween.tween_property(cometa, "position:y", base.y - 18, 0.12)
		tween.tween_property(cometa, "position:y", base.y, 0.25).set_trans(Tween.TRANS_BOUNCE)


## La nave de juguete del living, de perfil, con las caritas en sus ventanitas. En armar equipo lleva fuego
## de cohete ("¡Despegar!"). Debajo, las 5 estrellitas del equipo (una por zona ganada en equipo, §7.3),
## apagadas "por llenar", nunca con candado.
func _dibujar_nave() -> void:
	var casco := Rect2(30, 10, 190, 66)
	if _armando:
		var largo := 34.0 + 10.0 * sin(_tiempo * 18.0)
		var fuego := PackedVector2Array([Vector2(32, 26), Vector2(32 - largo, 43), Vector2(32, 60)])
		_nave.draw_colored_polygon(fuego, Color("#FF9F4A"))
		var nucleo := PackedVector2Array([Vector2(32, 34), Vector2(32 - largo * 0.55, 43), Vector2(32, 52)])
		_nave.draw_colored_polygon(nucleo, Color("#FFE38A"))
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#E9EEF8")
	caja.border_color = COLOR_CONTORNO
	caja.set_border_width_all(5)
	caja.set_corner_radius_all(30)
	caja.corner_radius_top_right = 60
	caja.corner_radius_bottom_right = 60
	caja.anti_aliasing = true
	caja.shadow_color = Color(COLOR_CONTORNO, 0.3)
	caja.shadow_size = 4
	caja.shadow_offset = Vector2(0, 4)
	_nave.draw_style_box(caja, casco)
	for i in IDS.size():
		var centro := Vector2(74 + i * 54, 42)
		var color := Color("#FFF8EE") if not _armando or _en_nave[IDS[i]] else Color(1, 1, 1, 0.35)
		_nave.draw_circle(centro, 25.0, color)
		_nave.draw_arc(centro, 25.0, 0.0, TAU, 32, COLOR_CONTORNO, 3.0, true)
	var ganadas: int = Progreso.contar_niveles_equipo_ganados(PLANETA_EQUIPO)
	for k in 5:
		var punto := Vector2(54 + k * 34, 94)
		var puntos := PackedVector2Array()
		for j in 10:
			var r := 13.0 if j % 2 == 0 else 6.5
			puntos.append(punto + Vector2.from_angle(-PI / 2.0 + PI * j / 5.0) * r)
		_nave.draw_colored_polygon(puntos, DORADO if k < ganadas else Color(1, 1, 1, 0.3))
		_nave.draw_polyline(puntos + PackedVector2Array([puntos[0]]), DORADO if k >= ganadas else COLOR_CONTORNO, 2.0, true)


## Bajo cada tarjeta: el asiento de la nave encendido (adentro) o el puf de "yo miro" (afuera).
func _dibujar_asiento(control: Control, id: String) -> void:
	var adentro: bool = _en_nave[id]
	var c := control.size / 2.0
	if adentro:
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color("#45C6C0")
		caja.border_color = COLOR_CONTORNO
		caja.set_border_width_all(4)
		caja.set_corner_radius_all(14)
		control.draw_style_box(caja, Rect2(c - Vector2(46, 16), Vector2(92, 32)))
		control.draw_circle(c, 7.0, DORADO)
	else:
		control.draw_circle(c + Vector2(0, 4), 30.0, Color("#F26CA8"))
		control.draw_arc(c + Vector2(0, 4), 30.0, PI, TAU, 24, COLOR_CONTORNO, 4.0, true)
		control.draw_line(c + Vector2(-30, 4), c + Vector2(30, 4), COLOR_CONTORNO, 4.0, true)


func _saltito(nodo: CanvasItem) -> void:
	if nodo == null:
		return
	var base: Vector2 = nodo.position
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "position:y", base.y - 16, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo, "position:y", base.y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _mecer(nodo: Control) -> void:
	var tween := nodo.create_tween()
	for angulo in [-4.0, 4.0, -2.0, 0.0]:
		tween.tween_property(nodo, "rotation", deg_to_rad(angulo), 0.1)


func _voz(ruta: String) -> void:
	if ruta != "" and ResourceLoader.exists(ruta):
		Audio.reproducir_voz(ruta)


## La grabacion de los ninos ("¡yo tambien!", opcional) suena despues de la de Cometa.
func _voz_despues(ruta: String) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var espera := 0.0
	await get_tree().process_frame
	while Audio.esta_hablando() and espera < 3.0:
		await get_tree().process_frame
		espera += get_process_delta_time()
	if is_inside_tree() and _armando:
		Audio.reproducir_voz(ruta)


func _despues(segundos: float, accion: Callable) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_inside_tree():
		accion.call()
