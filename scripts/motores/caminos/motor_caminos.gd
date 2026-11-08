class_name MotorCaminos
extends "res://scripts/base/minijuego_base.gd"

## Motor de mecánica "caminos" — «Cada quien a su casa», tipo Flow Free (docs/fichas/motor-caminos.md).
## Planeta Animalia, los tres hermanos: en una cuadrícula del claro cada animal llega a su casa dejando un
## camino de huellitas; los caminos no se cruzan y en los niveles difíciles hay que cubrir todas las baldosas.
##
## Las reglas viven en `LogicaCaminos` (probadas por `herramientas/qa_test_caminos.gd`); el dibujo (animales,
## casas, huellas) en `DibujoCaminos`, todo vectorial por código y PROVISIONAL hasta el arte de HE-114. Aquí
## solo hay entrada, dibujo, ayudas, tormenta y el flujo de tableros. Todo lo que cambia entre hermanos llega en
## el JSON del nivel (`datos/niveles/animalia/<zona>/caminos_<perfil>.json`).
##
## POLÍTICA DE DERROTA (PO 05-Nov-2026, HE-124; GDD §6 regla 11): los tres pueden perder por la NUBE (reloj =
## `tormenta.factor_par` × `tiempo_par_s` del tablero: Maxi 3, Nicole 2,2, Sofía 1,6). Perder es un gag
## ("¡la tormenta de risa!") con "¡otra vez!" de un toque; los tableros ya resueltos quedan resueltos (Maxi
## además conserva los animales que ya llegaron). Regalo de Toby (traza un camino) tras `regalo_tras_derrotas`
## en el mismo tablero; Maxi recibe la ayuda fuerte tras 3 (todos menos uno y sin nube). Destellos y
## estrellitas solo al ganar. Nunca rojo, nunca se quita lo ganado.
##
## MODO EQUIPO (§12.2; modo-equipo.md §11.4): un tablero compartido; los caminos llegados quedan fijos; tope de
## animales en casa por turno (M 1, N 1, S 2); `segundos_por_turno` sin llegar ninguno -> `terminar_turno(true)`;
## Maxi juega un par elegido (el más corto) con el animal bajo el dedo; `semilla_auto_s` -> el animal camina solo.

signal tablero_terminado(indice: int)
signal derrota(indice: int, derrotas: int)

const Dibujo := preload("res://scripts/motores/caminos/dibujo_caminos.gd")
const PistaConCosto := preload("res://scripts/ui/pista_con_costo.gd")
const BarraRecord := preload("res://scripts/ui/barra_record.gd")
const TEXTURA_TOBY := "res://assets/sprites/personajes/toby_provisional.png"
const RUTA_FUENTE := "res://assets/fuentes/fuente_baloo_800.tres"

## SFX PROVISIONALES (los de la interfaz con otro tono) hasta tener los propios (§7.5).
const SFX_HUELLA := "sfx/ui/toque.ogg"
const SFX_BORRAR := "sfx/ui/fiuu.ogg"
const SFX_CORTE := "sfx/ui/puf.ogg"
const SFX_BOING := "sfx/ui/blup.ogg"
const SFX_LLEGADA := "sfx/ui/confirmar.ogg"
const SFX_TABLERO := "sfx/ui/abrir.ogg"
const SFX_BARRER := "sfx/ui/polvo.ogg"
const SFX_TRUENO := "sfx/ui/zona_dormida.ogg"
const SFX_ANIMAL := "sfx/ui/seleccionar.ogg"
const SFX_FLOR := "sfx/ui/soltar.ogg"
const SFX_TOC := "sfx/ui/polvo_boing.ogg"

const TINTA := Color("#2B3350")
const CREMA := Color("#FFF8EE")
const DORADO := Color("#FFCB3D")
## Celda por cuadrícula (ficha §4): todas sobre 64 px; Maxi sobre 96 px.
const CELDA_POR_TAMANO := {"4x3": 170, "5x4": 140, "5x5": 110, "6x6": 95, "7x7": 86, "8x8": 76, "9x9": 68}
const CENTRO_TABLERO := Vector2(640, 384)
const RECT_TOBY := Rect2(14, 520, 190, 196)
const LADO_BOTON := 96.0
const SEGUNDOS_FIESTA := 1.5
const RECT_CASA_EQUIPO := Rect2(1172, 8, 100, 96)

@onready var _juego: Control = %juego
@onready var _hud: Control = %hud
@onready var _boton_salir: Button = %boton_salir
@onready var _fin: Control = %fin
@onready var _boton_otra_vez: Button = %boton_otra_vez
@onready var _confeti: CPUParticles2D = %confeti
@onready var _fondo: Control = %fondo

var logica := LogicaCaminos.new()
var _fuente: Font
var _tex_toby: Texture2D
var _rng := RandomNumberGenerator.new()
## -1 = al azar (con `transformar`). Los arneses la fijan para que el tablero sea el del JSON.
var transformacion_forzada := -1

# Tablero
var _tableros: Array = []
var _i := 0
var _tablero: Dictionary = {}
var _celda := 100.0
var _origen := Vector2.ZERO
var _perfil := "semilla"
var _catalogo: Dictionary = {}
var _casas_color := true
var _animal_bajo_dedo := false
var _histeresis := 0.35

# Flujo
var _fase := "entrando"  ## entrando | jugando | fiesta | tormenta | perdio | celebrando
var _t := 0.0
var _t_fase := 0.0
var _t_tablero := 0.0
var _idle := 0.0
var _ayuda_nivel := 0  ## 0 nada, 1 guía, 2 mano fantasma (Semilla); 1 casa que late (Brote)
var _derrotas_tablero := 0
var _derrotas_total := 0
var _sin_nube := false
var _puntos_inicio := 0
var _racha_inicio := 0
var _pistas := 0
var _stats: Array = []  ## por tablero resuelto: {"trazos_de_mas", "en_par", "intentos_casa"}
var _intentos_casa_total := 0
var _faltan_dicho := false
var _record_previo := 0
var _barra: Control
var _pista: Control
var _boton_pista: Button
var _boton_barrer: Button
var _toby: Control
var _dijo_presentacion := {}

# Trazo
var _arrastrando := false
var _celda_dedo := -1
var _pos_dedo := Vector2.ZERO
var _sin_mover := true
var _par_forzado := ""

# Animaciones
var _paseos: Dictionary = {}  ## par -> {"t", "dur", "celdas"}
var _flor_t: Dictionary = {}  ## celda -> instante en que florece
var _salto: Dictionary = {}  ## par -> t
var _ey: Dictionary = {}  ## par -> t
var _sacude: Dictionary = {}  ## celda -> t
var _abre: Dictionary = {}  ## celda -> t
var _toc: Dictionary = {}  ## celda -> t
var _particulas: Array = []  ## {"pos","vel","t","dur","color","tipo","r"}
var _guia: Dictionary = {}  ## {"par", "t"}
var _mano_t := 0.0
var _gag_t := 0.0
var _toby_salto := 0.0
var _mojado := 0.0
var _late_vacias := 0.0
var _ultimo_bloqueo_ms := 0

# Equipo
var _eq: Dictionary = {}
var _eq_victoria := false
var _eq_t_turno := 0.0
var _eq_esperando_paseo := false
var _eq_contados: Dictionary = {}
var _eq_gag: Dictionary = {}
var _eq_restaurado := false


func _ready() -> void:
	super._ready()
	_rng.randomize()
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	if ResourceLoader.exists(TEXTURA_TOBY):
		_tex_toby = load(TEXTURA_TOBY)
	_estilizar_boton(_boton_salir, CREMA)
	_icono(_boton_salir, _dibujar_casa_icono)
	_boton_salir.pressed.connect(func() -> void: salir_solicitado.emit())
	_estilizar_boton(_boton_otra_vez, DORADO)
	_icono(_boton_otra_vez, _dibujar_otra_vez)
	_boton_otra_vez.pressed.connect(reintentar)
	_fin.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			reintentar())
	_fin.draw.connect(_dibujar_fin)
	_fin.hide()
	_juego.gui_input.connect(_al_input)
	_juego.draw.connect(_dibujar_juego)
	_hud.draw.connect(_dibujar_hud)
	_fondo.draw.connect(_dibujar_fondo)
	_crear_controles()
	logica.camino_cambio.connect(_al_cambiar)
	logica.camino_cortado.connect(_al_cortar)
	logica.llego.connect(_al_llegar)
	logica.casa_rechazo.connect(_al_rechazo)
	logica.bloqueado.connect(_al_bloqueo)
	logica.tablero_completo.connect(_al_completar)
	logica.falta_llenar.connect(_al_faltar)
	if nivel.is_empty():
		push_error("motor_caminos: nivel vacio, revisa ruta_nivel (%s)" % ruta_nivel)
		return
	_configurar_desde_nivel()
	if turnos != null:
		_preparar_equipo()
	else:
		_retomar_parcial()
		_cargar_tablero(_i)
		_voz("intro")


## Semilla del azar (giros y espejos): los arneses la fijan antes de entrar al árbol.
func fijar_semilla(semilla: int) -> void:
	_rng.seed = semilla


func fase() -> String:
	return _fase


func indice_tablero() -> int:
	return _i


func celda_px() -> float:
	return _celda


func derrotas_tablero() -> int:
	return _derrotas_tablero


func _configurar_desde_nivel() -> void:
	_perfil = obtener_perfil_dificultad()
	_catalogo = nivel.get("catalogo", {})
	_casas_color = str(nivel.get("casas", "color")) == "color"
	_tableros = nivel.get("tableros", [])
	var p = nivel.get("puntos", null)
	if p is Dictionary:
		logica.puntos_cfg = p
	_aplicar_reglas(_perfil)
	if _perfil != "semilla" and turnos == null:
		_record_previo = obtener_record()
		_barra = BarraRecord.new()
		_barra.position = Vector2(1196, 150)
		_barra.size = Vector2(56, 420)
		_juego.get_parent().add_child(_barra)
		var umbrales = nivel.get("umbrales_puntaje", null)
		var tope := 4000.0
		if umbrales is Dictionary:
			tope = float(umbrales.get("tres", 4000))
		else:
			tope = 1500.0 * _tableros.size()
		_barra.preparar(_record_previo, tope)
	if _perfil == "estrella" and bool(nivel.get("pistas_cuestan_estrellita", false)) and turnos == null:
		_boton_pista.show()
		_pista = PistaConCosto.crear(_juego.get_parent(), _boton_pista, _estrellitas_actuales)
	_fondo.queue_redraw()


## Reglas del perfil (en solitario, las del nivel; en equipo, las del hermano del turno).
func _aplicar_reglas(perfil: String) -> void:
	var es_semilla := perfil == "semilla"
	logica.llenar = bool(nivel.get("llenar", false))
	logica.cortar_ajenos = bool(nivel.get("cortar_ajenos", true)) and not es_semilla
	logica.empezar_desde_casa = bool(nivel.get("empezar_desde_casa", true)) and not es_semilla and _casas_color
	logica.casas_habitat = not _casas_color
	logica.iman_casa = int(nivel.get("iman_casa", 0)) if turnos == null else (1 if es_semilla else 0)
	logica.atraso_max = int(nivel.get("atraso_max_celdas", 3))
	# En Semilla un animal que ya llegó no se pierde nunca; en equipo, los llegados son de todos.
	logica.llegados_fijos = es_semilla or (turnos != null and bool(_eq.get("llegados_fijos", true)))
	_animal_bajo_dedo = bool(nivel.get("animal_bajo_dedo", false)) if turnos == null else es_semilla
	_histeresis = float(nivel.get("histeresis", 0.35)) if turnos == null else (0.25 if es_semilla else 0.35)


func _crear_controles() -> void:
	var ui: Control = _boton_salir.get_parent()
	_boton_barrer = Button.new()
	_boton_barrer.name = "boton_barrer"
	_boton_barrer.tooltip_text = "Barrer"
	_boton_barrer.focus_mode = Control.FOCUS_NONE
	_boton_barrer.position = Vector2(20, 400)
	_boton_barrer.size = Vector2.ONE * LADO_BOTON
	_boton_barrer.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_estilizar_boton(_boton_barrer, Color("#CDEFC0"))
	_icono(_boton_barrer, _dibujar_escoba)
	_boton_barrer.pressed.connect(barrer)
	ui.add_child(_boton_barrer)
	_boton_pista = Button.new()
	_boton_pista.name = "boton_pista"
	_boton_pista.tooltip_text = "Pista de Toby"
	_boton_pista.focus_mode = Control.FOCUS_NONE
	_boton_pista.position = Vector2(20, 150)
	_boton_pista.size = Vector2.ONE * LADO_BOTON
	_boton_pista.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_estilizar_boton(_boton_pista, Color("#FFF1B8"))
	_icono(_boton_pista, _dibujar_antena)
	_boton_pista.pressed.connect(pedir_pista)
	_boton_pista.hide()
	ui.add_child(_boton_pista)
	_toby = Control.new()
	_toby.name = "toby"
	_toby.position = RECT_TOBY.position
	_toby.size = RECT_TOBY.size
	_toby.mouse_filter = Control.MOUSE_FILTER_STOP
	_toby.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			tocar_toby())
	ui.add_child(_toby)
	ui.move_child(_fin, ui.get_child_count() - 1)


# ---------------------------------------------------------------------------
# Tableros
# ---------------------------------------------------------------------------

func _retomar_parcial() -> void:
	if not bool(nivel.get("guardado_parcial", true)):
		return
	var estado := obtener_estado_parcial()
	if estado.is_empty():
		return
	var i := int(estado.get("tablero_actual", 0))
	if i <= 0 or i >= _tableros.size():
		return
	_i = i
	logica.puntos = int(estado.get("puntos", 0))
	logica.racha = int(estado.get("racha", 0))
	_pistas = int(estado.get("pistas", 0))
	_derrotas_total = int(estado.get("derrotas", 0))
	var stats = estado.get("stats", [])
	_stats = stats if stats is Array else []


func _cargar_tablero(i: int) -> void:
	_i = i
	_tablero = _tableros[i]
	var celdas: Array = _tablero.get("celdas", [])
	var sol: Dictionary = _tablero.get("solucion", {})
	if bool(nivel.get("transformar", false)) or transformacion_forzada >= 0:
		var cuadrado := celdas.size() == str(celdas[0]).length()
		var k := transformacion_forzada
		if k < 0:
			k = _rng.randi_range(0, 7) if cuadrado else [0, 2, 4, 6][_rng.randi_range(0, 3)]
		var r := LogicaCaminos.transformar(celdas, sol, k)
		celdas = r[0]
		sol = r[1]
	var puntos := logica.puntos
	var racha := logica.racha
	logica.configurar(celdas, sol)
	logica.puntos = puntos
	logica.racha = racha
	_puntos_inicio = puntos
	_racha_inicio = racha
	var clave := "%dx%d" % [logica.ancho, logica.alto]
	_celda = float(nivel.get("celda_px", CELDA_POR_TAMANO.get(clave, floor(minf(700.0 / logica.ancho, 610.0 / logica.alto)))))
	var centro := CENTRO_TABLERO
	if turnos != null:
		_celda = minf(_celda, 88.0)
		centro = Vector2(660, 404)
	_origen = centro - Vector2(logica.ancho, logica.alto) * _celda / 2.0
	_derrotas_tablero = 0
	_sin_nube = false
	_t_tablero = 0.0
	_idle = 0.0
	_ayuda_nivel = 0
	_faltan_dicho = false
	_paseos.clear()
	_flor_t.clear()
	_guia = {}
	_particulas.clear()
	_fase = "entrando"
	_t_fase = 0.0
	if _tablero.get("tiempo_par_s", null) == null and nivel.get("tormenta", null) != null:
		push_warning("motor_caminos: tablero %s sin tiempo_par_s: sin tormenta" % _tablero.get("id", "?"))
	_presentar_habitat()


## Toby presenta el primer hábitat que este hermano todavía no conoce (uno por tablero, §14 R5).
func _presentar_habitat() -> void:
	var habitats = nivel.get("lineas_voz", {}).get("habitats", {})
	if not habitats is Dictionary or habitats.is_empty():
		return
	for p in logica.pares:
		var casa := _id_casa(p)
		var clave := "caminos_habitat_" + casa
		if habitats.has(casa) and not presentacion_vista(clave) and not _dijo_presentacion.has(casa):
			_dijo_presentacion[casa] = true
			marcar_presentacion_vista(clave)
			_voz_ruta(str(habitats[casa]))
			return


func _id_animal(p: String) -> String:
	return str(_tablero.get("pares", {}).get(p, {}).get("animal", ""))


func _id_casa(p: String) -> String:
	return str(_tablero.get("pares", {}).get(p, {}).get("casa", ""))


func _color_par(p: String) -> Color:
	return Dibujo.col(_tablero.get("pares", {}).get(p, {}).get("color", "#E8434B"))


func _tiempo_par() -> float:
	var v = _tablero.get("tiempo_par_s", null)
	return float(v) if v != null else 0.0


## Segundos de nube del tablero (0 = sin tormenta).
func limite_tormenta() -> float:
	var tormenta = nivel.get("tormenta", null)
	if not tormenta is Dictionary or _sin_nube or turnos != null or _tiempo_par() <= 0.0:
		return 0.0
	return float(tormenta.get("factor_par", 2.0)) * _tiempo_par()


# ---------------------------------------------------------------------------
# Bucle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_t_fase += delta
	_toby_salto = maxf(0.0, _toby_salto - delta * 3.0)
	_mojado = maxf(0.0, _mojado - delta * 0.25) if _fase != "tormenta" else _mojado
	_actualizar_particulas(delta)
	_actualizar_paseos(delta)
	match _fase:
		"entrando":
			if _t_fase >= _segundos_entrada():
				_fase = "jugando"
				_t_fase = 0.0
		"jugando":
			if not _pausado():
				_t_tablero += delta
				_idle += delta
				_ayudas()
				var limite := limite_tormenta()
				if limite > 0.0 and _t_tablero >= limite and not logica.esta_completo():
					_perder()
		"fiesta":
			if _t_fase >= SEGUNDOS_FIESTA and _paseos.is_empty():
				_siguiente_tablero()
		"tormenta":
			if _t_fase >= _segundos_gag():
				_fase = "perdio"
				_t_fase = 0.0
				_fin.show()
				_fin.queue_redraw()
	if turnos != null:
		_procesar_equipo(delta)
	_juego.queue_redraw()
	_hud.queue_redraw()
	if _fin.visible:
		_fin.queue_redraw()


## Cascada de baldosas (0,02 s por celda, ficha §5) con tope de 1 s para que el 9 x 9 no haga esperar.
func _segundos_entrada() -> float:
	return minf(0.02 * logica.ancho * logica.alto, 0.7) + 0.3


func _pausado() -> bool:
	if turnos == null:
		return false
	return not _turno_jugable()


func _segundos_gag() -> float:
	return 1.5 if _perfil == "semilla" else 2.5


## Ayudas por quietud (§8.1): Semilla guía (6 s), mano fantasma (10 s) y válvula; Brote, casa que late (15 s).
func _ayudas() -> void:
	if _arrastrando:
		return
	var tiempos: Array = nivel.get("ayuda_idle_s", [])
	if turnos != null:
		tiempos = [6, 10] if obtener_perfil_dificultad() == "semilla" else []
	if tiempos.is_empty():
		return
	var valvula := float(nivel.get("valvula_s", 0))
	if valvula > 0.0 and _idle >= valvula and _ayuda_nivel < 3:
		var trabados := logica.buscar_trabados()
		if not trabados.is_empty():
			soplar(str(trabados["estorba"]))
			return
	if _ayuda_nivel == 0 and _idle >= float(tiempos[0]):
		_ayuda_nivel = 1
		var p := _par_para_guia()
		if p != "":
			if _perfil == "brote" and turnos == null:
				_voz("casa_late")
			else:
				_salto[p] = _t
				_mostrar_guia(p)
				_voz("guia")
	elif _ayuda_nivel == 1 and tiempos.size() > 1 and _idle >= float(tiempos[1]):
		_ayuda_nivel = 2
		_mano_t = 0.0


func _par_para_guia() -> String:
	if _par_forzado != "":
		return _par_forzado
	for p in logica.pares:
		if not logica.llegado[p]:
			return p
	return ""


func _mostrar_guia(p: String) -> void:
	_guia = {"par": p, "t": _t}


## Válvula de Semilla (§10.1): Toby sopla el camino que encierra a otro (se va en hojitas).
func soplar(p: String) -> void:
	for celda in logica.caminos[p]:
		_hojitas(_centro(celda), _color_par(p), 3)
	logica.borrar_camino(p)
	_paseos.erase(p)
	_toby_salto = 1.0
	_voz("valvula")
	_idle = 0.0
	_ayuda_nivel = 0
	var falta := _par_para_guia()
	if falta != "":
		_mostrar_guia(falta)


# ---------------------------------------------------------------------------
# Entrada (táctil y mouse, mismo código)
# ---------------------------------------------------------------------------

func _al_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_juego.accept_event()
		if evento.pressed:
			presionar(evento.position)
		else:
			soltar(evento.position)
	elif evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_juego.accept_event()
		arrastrar(evento.position)


## Celda bajo un punto de pantalla (-1 si cae fuera del tablero).
func celda_en(pos: Vector2) -> int:
	var local := (pos - _origen) / _celda
	if local.x < 0 or local.y < 0 or local.x >= logica.ancho or local.y >= logica.alto:
		return -1
	return int(local.y) * logica.ancho + int(local.x)


## Centro en pantalla de una celda.
func centro_celda(i: int) -> Vector2:
	return _centro(i)


func _centro(i: int) -> Vector2:
	var p := logica.xy(i)
	return _origen + (Vector2(p) + Vector2(0.5, 0.5)) * _celda


func presionar(pos: Vector2) -> void:
	if _fase != "jugando" or (turnos != null and not _turno_jugable()):
		return
	_idle = 0.0
	_ayuda_nivel = 0
	_guia = {} if _perfil != "semilla" else _guia
	var celda := celda_en(pos)
	# Tolerancia generosa de Maxi: un toque cerca de su animal (o de la cabeza de su camino) lo toma.
	if _perfil == "semilla" or (turnos != null and obtener_perfil_dificultad() == "semilla"):
		celda = _celda_tolerante(pos, celda)
	if celda < 0:
		return
	var p := logica.empezar(celda, _par_forzado)
	if p == "":
		_tocar_suelto(celda)
		return
	_arrastrando = true
	_celda_dedo = logica.cabeza(p)
	_pos_dedo = pos
	_sin_mover = true
	_paseos.erase(p)
	_salto[p] = _t
	reproducir_sfx(SFX_ANIMAL, float(_catalogo.get(_id_animal(p), {}).get("tono", 1.0)))


func _celda_tolerante(pos: Vector2, celda: int) -> int:
	var mejor := celda
	var mejor_d := INF
	for p in logica.pares:
		if _par_forzado != "" and p != _par_forzado:
			continue
		if logica.llegado[p]:
			continue
		for c in [logica.animal_de[p], logica.cabeza(p)]:
			if c < 0:
				continue
			var d := pos.distance_to(_centro(c))
			if d < _celda * 0.75 and d < mejor_d:
				mejor_d = d
				mejor = c
	return mejor


func arrastrar(pos: Vector2) -> void:
	if not _arrastrando:
		return
	_pos_dedo = pos
	var c := celda_en(pos)
	if c < 0 or c == _celda_dedo:
		return
	# Histéresis (§6.1): para entrar a una celda vecina el dedo debe pasar el 35 % de ella.
	if _celda_dedo >= 0 and logica.adyacentes(c, _celda_dedo):
		var d := logica.xy(c) - logica.xy(_celda_dedo)
		var local := (pos - _origen) / _celda - Vector2(logica.xy(c))
		var dentro := local.x if d.x > 0 else (1.0 - local.x if d.x < 0 else (local.y if d.y > 0 else 1.0 - local.y))
		if dentro < _histeresis:
			return
	var antes: int = (logica.caminos[logica.trazo_par] as Array).size() if logica.trazo_par != "" else 0
	if logica.mover(c):
		_sin_mover = false
		var despues: int = (logica.caminos[logica.trazo_par] as Array).size() if logica.trazo_par != "" else 0
		if despues > antes:
			reproducir_sfx(SFX_HUELLA, pow(2.0, minf(12.0, despues - 1) / 12.0), -4.0)
		elif despues < antes:
			reproducir_sfx(SFX_BORRAR, pow(2.0, -minf(12.0, antes - despues) / 12.0), -6.0)
	_celda_dedo = c


func soltar(_pos := Vector2.ZERO) -> void:
	if not _arrastrando:
		return
	_arrastrando = false
	var p := logica.trazo_par
	logica.soltar()
	if p != "" and _sin_mover and (_perfil == "semilla" or (turnos != null and obtener_perfil_dificultad() == "semilla")):
		# Tocar sin arrastrar (Semilla): su nombre y la guía de huellitas fantasma hasta su casa (2 s).
		_mostrar_guia(p)
		_decir_nombre(p)
	_celda_dedo = -1


## Arrastre completo por una lista de celdas (lo usan los arneses: el mismo camino que haría un dedo).
func trazar_celdas(celdas: Array) -> void:
	if celdas.is_empty():
		return
	presionar(_centro(celdas[0]))
	for k in range(1, celdas.size()):
		arrastrar(_centro(celdas[k]))
	soltar(_centro(celdas[-1]))


func _tocar_suelto(celda: int) -> void:
	match logica.tipo[celda]:
		LogicaCaminos.CASA:
			_abre[celda] = _t
			reproducir_sfx(SFX_ANIMAL, 0.8)
			if not _casas_color:
				var habitats = nivel.get("lineas_voz", {}).get("habitats", {})
				var casa := _id_casa(logica.par_en[celda])
				if habitats is Dictionary and habitats.has(casa):
					_voz_ruta(str(habitats[casa]))
		LogicaCaminos.ROCA:
			_toc[celda] = _t
			reproducir_sfx(SFX_TOC, 1.2, -4.0)
		LogicaCaminos.ANIMAL:
			var p := logica.par_en[celda]
			_salto[p] = _t
			reproducir_sfx(SFX_ANIMAL, float(_catalogo.get(_id_animal(p), {}).get("tono", 1.0)))
		_:
			_flor_t[celda] = _t
			reproducir_sfx(SFX_FLOR, 1.3, -6.0)
			var t0 := _t
			get_tree().create_timer(0.5).timeout.connect(func() -> void:
				if _flor_t.get(celda, -1.0) == t0 and logica.ocupante(celda) == "":
					_flor_t.erase(celda))


func tocar_toby() -> void:
	_toby_salto = 1.0
	reproducir_sfx(SFX_ANIMAL, 1.1)
	_voz("instruccion")


## Barrer (§6.2): todos los caminos se van con un viento de hojas. Sin confirmación: no cuesta nada.
func barrer() -> void:
	if _fase != "jugando" or (turnos != null and not _turno_jugable()):
		return
	for p in logica.pares:
		if logica.fijos.has(p):
			continue
		for celda in logica.caminos[p]:
			_hojitas(_centro(celda), _color_par(p), 1)
		_paseos.erase(p)
	logica.barrer()
	_idle = 0.0
	reproducir_sfx(SFX_BARRER)


## Pista de Sofía (§10.4): Toby traza el camino correcto de un par. Cuesta una estrellita (globo de confirmación).
func pedir_pista() -> void:
	if _fase != "jugando" or _pista == null:
		return
	_pista.pedir(_accion_pista)


func _accion_pista(gratis: bool) -> bool:
	var p := logica.par_para_ayudar()
	if p == "":
		return false
	_toby_salto = 1.0
	logica.colocar_solucion(p)
	if not gratis:
		_pistas += 1
	_voz("pista_usada")
	return true


# ---------------------------------------------------------------------------
# Eventos de la lógica
# ---------------------------------------------------------------------------

func _al_cambiar(_p: String) -> void:
	_juego.queue_redraw()


func _al_cortar(q: String, celda: int) -> void:
	_ey[q] = _t
	_paseos.erase(q)
	_hojitas(_centro(celda), _color_par(q), 6)
	reproducir_sfx(SFX_CORTE, 1.1, -3.0)


func _al_llegar(p: String, _trazos: int) -> void:
	var celdas: Array = (logica.caminos[p] as Array).duplicate()
	if not celdas.is_empty() and celdas[0] == logica.casa_de[p]:
		celdas.reverse()
	_paseos[p] = {"t": 0.0, "dur": clampf(0.08 * celdas.size(), 0.6, 1.2), "celdas": celdas}
	for k in celdas.size():
		_flor_t[celdas[k]] = _t + 0.03 * k
	if _guia.get("par", "") == p:
		_guia = {}
	_idle = 0.0
	_ayuda_nivel = 0
	if turnos != null:
		_llegada_equipo(p)


func _al_rechazo(p: String, q: String) -> void:
	var casa: int = logica.casa_de[q]
	_sacude[casa] = _t
	reproducir_sfx(SFX_BOING, 0.9, -2.0)
	if logica.casas_habitat:
		_intentos_casa_total += 1
		_voz("casa_ajena")
		if turnos != null:
			turnos.notificar_fallo_suave()
	_ey[p] = _t


func _al_bloqueo(p: String, celda: int, motivo: String) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_bloqueo_ms < 250:
		return
	_ultimo_bloqueo_ms = ahora
	match motivo:
		"roca":
			_toc[celda] = _t
			reproducir_sfx(SFX_TOC, 1.2, -4.0)
		"camino":
			# Semilla: no se corta; el animal se frena y saluda al otro con su sonido.
			var otro := logica.ocupante(celda)
			if otro != "":
				_salto[otro] = _t
				reproducir_sfx(SFX_ANIMAL, float(_catalogo.get(_id_animal(otro), {}).get("tono", 1.0)), -4.0)
		_:
			_salto[p] = _t


func _al_faltar(n: int) -> void:
	_late_vacias = _t
	if not _faltan_dicho:
		_faltan_dicho = true
		_voz("faltan_flores")


## Último animal adentro (con llenado, última baldosa cubierta).
func _al_completar(sin_borrones: bool) -> void:
	if turnos != null:
		_victoria_equipo()
		return
	var par := _tiempo_par()
	var en_par := par <= 0.0 or _t_tablero <= par
	if bool(nivel.get("tiempo_par", false)) and par > 0.0:
		logica.puntos += int(float(logica.puntos_cfg.get("por_segundo", 10)) * maxf(0.0, par - _t_tablero))
	_stats.append({"trazos_de_mas": logica.trazos_de_mas(), "en_par": en_par, "intentos_casa": logica.intentos_casa})
	if _barra != null:
		_barra.fijar_puntaje(logica.puntos)
	if sin_borrones and _perfil != "semilla":
		_voz("sin_borrones")
	reproducir_sfx(SFX_TABLERO)
	_fase = "fiesta"
	_t_fase = 0.0
	tablero_terminado.emit(_i)
	_confeti.position = _origen + Vector2(logica.ancho, logica.alto) * _celda / 2.0
	_confeti.restart()
	_confeti.emitting = true
	if _i >= _tableros.size() - 1:
		_ganar()
	else:
		if bool(nivel.get("guardado_parcial", true)):
			guardar_estado_parcial({"tablero_actual": _i + 1, "puntos": logica.puntos, "racha": logica.racha,
				"pistas": _pistas, "derrotas": _derrotas_total, "stats": _stats})
		_voz("tablero_listo")


func _siguiente_tablero() -> void:
	if _i + 1 < _tableros.size():
		_cargar_tablero(_i + 1)


# ---------------------------------------------------------------------------
# Victoria y derrota
# ---------------------------------------------------------------------------

## Estrellitas según la ficha §9.2. Brote: por puntaje (`umbrales_puntaje`). Estrella: por reglas (trazos de más,
## casas ajenas, tiempo par), menos las pistas; tras una derrota, máximo 2.
func estrellitas() -> int:
	if _perfil == "brote":
		var u = nivel.get("umbrales_puntaje", null)
		if not u is Dictionary:
			return 1
		if logica.puntos >= int(u.get("tres", 0)):
			return 3
		if logica.puntos >= int(u.get("dos", 0)):
			return 2
		return 1
	if _perfil != "estrella":
		return 0
	var umbral = nivel.get("umbrales_estrellitas", {})
	var de_mas := int(umbral.get("trazos_de_mas", 1)) if umbral is Dictionary else 1
	var casa_max := int(umbral.get("intentos_casa", 0)) if umbral is Dictionary else 0
	var fallas := 0
	var trazos_ok := true
	var tiempo_ok := true
	for s in _stats:
		if int(s.get("trazos_de_mas", 0)) > de_mas:
			trazos_ok = false
		if not bool(s.get("en_par", true)):
			tiempo_ok = false
	if not trazos_ok:
		fallas += 1
	if not tiempo_ok:
		fallas += 1
	if _intentos_casa_total > casa_max:
		fallas += 1
	var e := clampi(3 - fallas, 1, 3)
	e = clampi(e - _pistas, 1, 3)
	if _derrotas_total > 0:
		e = mini(e, 2)
	return e


## Para el medidor de la pista: las estrellitas que lleva la partida ahora.
func _estrellitas_actuales() -> int:
	return estrellitas() if _perfil == "estrella" else 3


func puntos() -> int:
	return logica.puntos


func _ganar() -> void:
	var e := estrellitas()
	# Salir siempre es seguro: la estación queda guardada en el instante de ganar (QA HE-60 B1).
	asegurar_victoria(100, e)
	var record_nuevo := false
	var primero := false
	if _perfil != "semilla":
		primero = _record_previo <= 0
		record_nuevo = registrar_record(logica.puntos)
	_fase = "celebrando_previo"
	await get_tree().create_timer(SEGUNDOS_FIESTA + 0.6).timeout
	if not is_inside_tree():
		return
	if record_nuevo and _barra != null:
		if primero:
			_barra.plantar_banderita()
			_voz("primer_record")
		else:
			_voz("record")
		await _esperar_voz_libre(3.0)
	if not is_inside_tree():
		return
	_fase = "celebrando"
	celebrar(100, e, _linea_existente("victoria"))


func _perder() -> void:
	_arrastrando = false
	logica.soltar()
	_fase = "tormenta"
	_t_fase = 0.0
	_gag_t = 0.0
	_derrotas_tablero += 1
	_derrotas_total += 1
	_mojado = 1.0
	_toby_salto = 1.0
	reproducir_sfx(SFX_TRUENO, 0.9 if _perfil != "semilla" else 1.4)
	_voz("derrota_gag")
	derrota.emit(_i, _derrotas_tablero)
	var descanso = nivel.get("descanso_tras_derrotas", null)
	if descanso != null and int(descanso) > 0 and _derrotas_tablero >= int(descanso):
		get_tree().create_timer(_segundos_gag() + 0.2).timeout.connect(func() -> void:
			if is_inside_tree() and _fase == "perdio":
				_voz("descansar")
				var tw := _boton_salir.create_tween()
				_boton_salir.pivot_offset = _boton_salir.size / 2.0
				tw.tween_property(_boton_salir, "scale", Vector2.ONE * 1.15, 0.25)
				tw.tween_property(_boton_salir, "scale", Vector2.ONE, 0.25))


## "¡Otra vez!" (un toque): se reintenta solo el tablero en curso, con la nube al inicio. Maxi conserva los
## animales que ya llegaron. Tras `regalo_tras_derrotas`, Toby regala un camino; Maxi, tras 3, la ayuda fuerte.
func reintentar() -> void:
	if _fase != "perdio":
		return
	_fin.hide()
	reproducir_sfx(SFX_ANIMAL, 1.2)
	_voz("otra_vez")
	if _perfil == "semilla":
		for p in logica.pares:
			if not logica.llegado[p]:
				logica.borrar_camino(p)
	else:
		logica.reiniciar()
		logica.puntos = _puntos_inicio
		logica.racha = _racha_inicio
	_paseos.clear()
	for celda in _flor_t.keys():
		if logica.ocupante(celda) == "" or not logica.llegado.get(logica.ocupante(celda), false):
			_flor_t.erase(celda)
	_t_tablero = 0.0
	_idle = 0.0
	_ayuda_nivel = 0
	_fase = "jugando"
	_t_fase = 0.0
	var fuerte = nivel.get("ayuda_fuerte_tras_derrotas", null)
	if fuerte is Dictionary and _derrotas_tablero >= int(fuerte.get("derrotas", 3)):
		ayuda_fuerte(bool(fuerte.get("sin_tormenta", true)))
		return
	var regalo := int(nivel.get("regalo_tras_derrotas", 0))
	if regalo > 0 and _derrotas_tablero >= regalo:
		regalar_camino()


## Regalo de Toby: traza él un camino correcto (como una pista gratis).
func regalar_camino() -> bool:
	var p := logica.par_para_ayudar()
	if p == "":
		return false
	_toby_salto = 1.0
	logica.colocar_solucion(p)
	_voz("regalo")
	return true


## Ayuda fuerte de Maxi (HE-124): Toby lleva a todos menos uno y ese tablero ya no tiene nube.
func ayuda_fuerte(sin_tormenta := true) -> void:
	var pendientes: Array[String] = []
	for p in logica.pares:
		if not logica.llegado[p]:
			pendientes.append(p)
	for k in range(pendientes.size() - 1):
		logica.colocar_solucion(pendientes[k])
	_sin_nube = sin_tormenta
	_toby_salto = 1.0
	_voz("ayuda_fuerte")
	if not pendientes.is_empty():
		_mostrar_guia(pendientes[-1])
		_ayuda_nivel = 2
		_mano_t = 0.0


## Arnés: lleva el reloj del tablero hasta `segundos` (la nube avanza; si llega, tormenta).
func avanzar_reloj(segundos: float) -> void:
	_t_tablero = segundos


# ---------------------------------------------------------------------------
# Voces y sonido
# ---------------------------------------------------------------------------

func _linea(clave: String) -> String:
	var v = nivel.get("lineas_voz", {}).get(clave, "")
	if v is Array:
		return str(v[_rng.randi_range(0, v.size() - 1)]) if not v.is_empty() else ""
	return str(v) if v != null else ""


func _linea_existente(clave: String) -> String:
	var ruta := _linea(clave)
	return ruta if ruta != "" and ResourceLoader.exists(resolver_ruta_audio(ruta)) else ""


## Solo suena si el archivo existe: el juego funciona sin las voces grabadas (y sin advertencias).
func _voz(clave: String) -> void:
	_voz_ruta(_linea(clave))


func _voz_ruta(ruta: String) -> void:
	if ruta == "" or ruta == "PENDIENTE":
		return
	if not ResourceLoader.exists(resolver_ruta_audio(ruta)):
		return
	reproducir_voz(ruta)


func _decir_nombre(p: String) -> void:
	var nombres = nivel.get("lineas_voz", {}).get("nombres", {})
	if nombres is Dictionary and nombres.has(_id_animal(p)):
		_voz_ruta(str(nombres[_id_animal(p)]))


# ---------------------------------------------------------------------------
# Animaciones
# ---------------------------------------------------------------------------

func _actualizar_paseos(delta: float) -> void:
	for p in _paseos.keys():
		var paseo: Dictionary = _paseos[p]
		paseo["t"] += delta
		if paseo["t"] >= paseo["dur"]:
			_paseos.erase(p)
			var casa: int = logica.casa_de[p]
			_abre[casa] = _t
			reproducir_sfx(SFX_LLEGADA, pow(2.0, mini(logica.racha, 5) / 12.0))
			for k in 12:
				var a := TAU * k / 12.0
				_particulas.append({"pos": _centro(casa), "vel": Vector2.from_angle(a) * 220.0, "t": 0.0, "dur": 0.6,
					"color": DORADO, "tipo": "estrella", "r": _celda * 0.1})
			if turnos != null and _eq_esperando_paseo and _paseos.is_empty():
				_eq_esperando_paseo = false
				turnos.confirmar_turno_estable()


func _actualizar_particulas(delta: float) -> void:
	for k in range(_particulas.size() - 1, -1, -1):
		var q: Dictionary = _particulas[k]
		q["t"] += delta
		q["pos"] += q["vel"] * delta
		q["vel"] *= 0.92
		q["vel"].y += 260.0 * delta if q["tipo"] == "hoja" else 0.0
		if q["t"] >= q["dur"]:
			_particulas.remove_at(k)


func _hojitas(pos: Vector2, color: Color, n: int) -> void:
	for k in n:
		_particulas.append({"pos": pos, "vel": Vector2(_rng.randf_range(-160, 160), _rng.randf_range(-220, -60)), "t": 0.0,
			"dur": 0.5, "color": color.lerp(Color("#5FAE5A"), 0.5), "tipo": "hoja", "r": _celda * 0.08})


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _dibujar_fondo() -> void:
	var f = nivel.get("fondo", {})
	var cielo := Dibujo.col(f.get("cielo", "#BFE59A") if f is Dictionary else "#BFE59A")
	var suelo := Dibujo.col(f.get("suelo", "#8CCB6A") if f is Dictionary else "#8CCB6A")
	var zona := int(f.get("zona", 1)) if f is Dictionary else 1
	var tam := Vector2(1280, 720)
	var arriba := cielo.lerp(Color("#EAF7FF"), 0.55)
	for k in 12:
		var y0 := tam.y * k / 12.0
		_fondo.draw_rect(Rect2(0, y0, tam.x, tam.y / 12.0 + 1), arriba.lerp(cielo, k / 11.0))
	var lomas := PackedVector2Array([Vector2(0, 720)])
	for k in 17:
		var x := k * 80.0
		lomas.append(Vector2(x, 470 + sin(k * 0.9) * 26.0 + cos(k * 0.37) * 18.0))
	lomas.append(Vector2(1280, 720))
	_fondo.draw_colored_polygon(lomas, suelo)
	for k in 18:
		var p := Vector2(fmod(k * 173.0, 1280.0), 560 + fmod(k * 97.0, 150.0))
		Dibujo.flor(_fondo, p, 9.0, [Color("#FF7EB6"), Color("#FFFFFF"), Color("#FFD84A")][k % 3], 1.0)
	# Hito de la zona en las esquinas (planeta-animalia-zonas.md §2.0).
	var hito := {1: {"tipo": "carpa", "color": "#FF8A3D", "color2": "#FFD84A"},
		2: {"tipo": "nenufar", "color": "#4FB86A", "color2": "#FF9CC0"},
		3: {"tipo": "arbol", "variante": "acacia", "color": "#7DB04A"},
		4: {"tipo": "arbol", "variante": "selva", "color": "#2EA05A", "color2": "#FF7EB6"},
		5: {"tipo": "montana", "variante": "volcan", "color": "#A0674A", "color2": "#FF8A3D"}}
	var d: Dictionary = hito.get(zona, hito[1])
	_dibujar_hito(Vector2(1170, 640), 90.0, d)


func _dibujar_hito(c: Vector2, r: float, d: Dictionary) -> void:
	var tipo := str(d.get("tipo", ""))
	var color := Dibujo.col(d.get("color", "#8CCB6A"))
	var color2 := Dibujo.col(d.get("color2", "#FFFFFF"))
	var g := r * Dibujo.CONTORNO
	match tipo:
		"arbol":
			Dibujo._arbol(_fondo, c, r, color, color2, str(d.get("variante", "")), g, 0.0)
		"montana":
			Dibujo._montana(_fondo, c, r, color, color2, str(d.get("variante", "")), g, 0.0)
		_:
			# casa sin placa: se dibuja sobre una placa transparente
			Dibujo.casa(_fondo, c, r, d, Color(0, 0, 0, 0), 0.0, 0.0, false)


func _dibujar_juego() -> void:
	if logica.ancho == 0:
		return
	var w := logica.ancho * _celda
	var h := logica.alto * _celda
	var marco := Rect2(_origen, Vector2(w, h)).grow(14)
	Dibujo.rect_redondo(_juego, marco.grow(4), 26, Color(0, 0, 0, 0.12))
	Dibujo.rect_redondo_c(_juego, marco, 24, Color("#8A6A4A"), TINTA, 4)
	var aparecer := clampf(_t_fase / maxf(0.01, _segundos_entrada() - 0.05), 0.0, 1.0) if _fase == "entrando" else 1.0
	var vacias_late := _t - _late_vacias < 3.0 and logica.todos_llegaron() and logica.llenar
	# Baldosas (caen en cascada al entrar, florecen al cubrirse).
	for i in logica.ancho * logica.alto:
		var p := logica.xy(i)
		var orden := float(i) / maxf(1.0, logica.ancho * logica.alto)
		if orden > aparecer:
			continue
		var r := Rect2(_origen + Vector2(p) * _celda, Vector2.ONE * _celda).grow(-2)
		var base := Color("#CDEBA8") if (p.x + p.y) % 2 == 0 else Color("#BFE29A")
		if logica.tipo[i] == LogicaCaminos.ROCA:
			base = Color("#B8C49A")
		var ocup := logica.ocupante(i)
		var florece := float(_flor_t.get(i, -1.0))
		if ocup != "" and logica.llegado.get(ocup, false) and florece >= 0.0 and _t >= florece:
			base = base.lerp(_color_par(ocup).lightened(0.55), 0.6)
		if vacias_late and logica.tipo[i] in [LogicaCaminos.VACIA, LogicaCaminos.PUENTE] and not logica.celda_cubierta(i):
			base = base.lerp(Color("#FFF6B0"), 0.5 + 0.5 * sin(_t * 6.0))
		Dibujo.rect_redondo(_juego, r, _celda * 0.16, base)
		if florece >= 0.0 and _t >= florece and (ocup == "" or logica.llegado.get(ocup, false)):
			var k := clampf((_t - florece) / 0.3, 0.0, 1.0)
			var col := Color("#FFFFFF") if ocup == "" else _color_par(ocup).lightened(0.3)
			Dibujo.flor(_juego, r.position + Vector2(_celda * 0.2, _celda * 0.2), _celda * 0.1, col, k)
			Dibujo.flor(_juego, r.end - Vector2(_celda * 0.2, _celda * 0.2), _celda * 0.08, Color("#FFFFFF"), k)
	if aparecer < 1.0:
		return
	for i in logica.ancho * logica.alto:
		if logica.tipo[i] == LogicaCaminos.ROCA:
			Dibujo.roca(_juego, _centro(i), _celda * 0.45, maxf(0.0, 0.3 - (_t - float(_toc.get(i, -9.0)))) / 0.3)
		elif logica.tipo[i] == LogicaCaminos.PUENTE:
			Dibujo.puente(_juego, _centro(i), _celda)
	# Guía (huellitas fantasma de la solución) y mano fantasma.
	if not _guia.is_empty() and _t - float(_guia["t"]) < 2.0 or _ayuda_nivel == 2:
		var gp := str(_guia.get("par", _par_para_guia()))
		if gp != "" and logica.solucion.has(gp):
			_dibujar_huellas(logica.solucion[gp], gp, 0.35 + 0.15 * sin(_t * 5.0))
	# Caminos.
	for p in logica.pares:
		_dibujar_camino(p)
	# Casas.
	for p in logica.pares:
		var casa: int = logica.casa_de[p]
		var c := _centro(casa)
		var sac := maxf(0.0, 0.4 - (_t - float(_sacude.get(casa, -9.0)))) / 0.4
		c.x += sin(_t * 50.0) * 6.0 * sac
		var llama := 0.0
		var cab := logica.cabeza(p)
		if cab >= 0 and not logica.llegado[p] and logica.adyacentes(cab, casa):
			llama = 0.6 + 0.4 * sin(_t * 8.0)
		var abre := maxf(0.0, 0.5 - (_t - float(_abre.get(casa, -9.0)))) * 2.0
		if _perfil == "brote" and turnos == null and _ayuda_nivel >= 1 and p == _par_para_guia():
			llama = maxf(llama, 0.5 + 0.5 * sin(_t * 5.0))
		var escala := 1.0 + 0.15 * abre
		var d: Dictionary = _catalogo.get(_id_casa(p), {}).get("dibujo", {"tipo": "casita"})
		Dibujo.casa(_juego, c, _celda * 0.45 * escala, d, _color_par(p) if _casas_color else Color(0, 0, 0, 0), maxf(llama, abre), _t)
	# Animales.
	for p in logica.pares:
		_dibujar_animal(p)
	# Mano fantasma (Semilla, 10 s quieto): recorre la solución en bucle.
	if _ayuda_nivel == 2 and _fase == "jugando":
		var gp := _par_para_guia()
		if gp != "" and logica.solucion.has(gp):
			var sol: Array = logica.solucion[gp]
			var u := fmod(_t * 0.6, 1.3)
			var pos := _punto_en(sol, clampf(u, 0.0, 1.0))
			_dibujar_mano(pos + Vector2(_celda * 0.15, _celda * 0.2))
	# Punta brillante bajo el dedo (en Estrella, 40 px arriba del dedo para que no la tape, R1).
	if _arrastrando and logica.trazo_par != "" and not _animal_bajo_dedo:
		var arriba := Vector2(0, -40) if _perfil == "estrella" else Vector2.ZERO
		var tipo_h := str(_catalogo.get(_id_animal(logica.trazo_par), {}).get("huella", "pata"))
		_juego.draw_circle(_pos_dedo + arriba, _celda * 0.3, Color(1, 1, 1, 0.55))
		Dibujo.huella(_juego, _pos_dedo + arriba, -PI / 2, _celda * 0.45, tipo_h, _color_par(logica.trazo_par).darkened(0.2))
	# Partículas.
	for q in _particulas:
		var a := 1.0 - float(q["t"]) / float(q["dur"])
		var col: Color = q["color"]
		col.a = a
		if q["tipo"] == "estrella":
			_juego.draw_colored_polygon(Dibujo.estrella_puntos(q["pos"], q["r"], q["t"] * 6.0), col)
		else:
			Dibujo.elipse(_juego, q["pos"], q["r"], q["r"] * 0.5, col, q["t"] * 8.0)
	if _fase == "tormenta" or (_fase == "perdio" and _t_fase < 1.0):
		_dibujar_lluvia()


func _dibujar_camino(p: String) -> void:
	var c: Array = logica.caminos[p]
	if c.size() < 2:
		return
	var color := _color_par(p)
	var pts := PackedVector2Array()
	for celda in c:
		pts.append(_centro(celda))
	var ancho := _celda * 0.42
	var claro := color.lightened(0.45)
	if _eq_gag.get("fase", "") in ["aspirar", "oculto"] and not logica.llegado[p]:
		return
	_juego.draw_polyline(pts, color.darkened(0.25), ancho + 6.0, true)
	for q in pts:
		_juego.draw_circle(q, (ancho + 6.0) / 2.0, color.darkened(0.25))
	_juego.draw_polyline(pts, claro, ancho, true)
	for q in pts:
		_juego.draw_circle(q, ancho / 2.0, claro)
	_dibujar_huellas(c, p, 1.0)


## Huellitas del animal a lo largo de `celdas` (alternadas izquierda/derecha).
func _dibujar_huellas(celdas: Array, p: String, alfa: float) -> void:
	var tipo_h := str(_catalogo.get(_id_animal(p), {}).get("huella", "pata"))
	var color := _color_par(p).darkened(0.35)
	if not _casas_color and _perfil == "estrella":
		color = Color("#8A6A4A")
	color.a = alfa
	var paso := 0
	for k in range(1, celdas.size()):
		var a := _centro(celdas[k - 1])
		var b := _centro(celdas[k])
		var dir := (b - a).normalized()
		for m in 2:
			var pos := a.lerp(b, 0.25 + 0.5 * m)
			var lado := dir.orthogonal() * _celda * 0.1 * (1.0 if paso % 2 == 0 else -1.0)
			Dibujo.huella(_juego, pos + lado, dir.angle(), _celda * 0.26, tipo_h, color)
			paso += 1


func _punto_en(celdas: Array, u: float) -> Vector2:
	if celdas.size() == 1:
		return _centro(celdas[0])
	var f := u * (celdas.size() - 1)
	var k := mini(int(f), celdas.size() - 2)
	return _centro(celdas[k]).lerp(_centro(celdas[k + 1]), f - k)


func _dibujar_animal(p: String) -> void:
	var d: Dictionary = _catalogo.get(_id_animal(p), {}).get("dibujo", {})
	var r := _celda * 0.42
	var origen: int = logica.animal_de[p]
	var estado := {"t": _t, "boca": "feliz", "orejas": 0.0, "mira": Vector2.ZERO}
	var salto := maxf(0.0, 0.35 - (_t - float(_salto.get(p, -9.0)))) / 0.35
	estado["salto"] = sin(salto * PI)
	if _t - float(_ey.get(p, -9.0)) < 0.7:
		estado["boca"] = "ey"
	if logica.trazo_par == p and _arrastrando:
		estado["orejas"] = 1.0
		estado["mira"] = (_pos_dedo - _centro(origen)).normalized()
	if _fase in ["tormenta", "perdio"] and not logica.llegado[p]:
		estado["mojado"] = true
	var pos := _centro(origen)
	var c: Array = logica.caminos[p]
	if _paseos.has(p):
		var paseo: Dictionary = _paseos[p]
		var u := clampf(float(paseo["t"]) / float(paseo["dur"]), 0.0, 1.0)
		pos = _punto_en(paseo["celdas"], u)
		estado["salto"] = absf(sin(u * PI * paseo["celdas"].size()))
		Dibujo.base_animal(_juego, _centro(origen), r * 0.6, _color_par(p))
	elif logica.llegado[p] and not (_eq_gag.get("fase", "") == "devolver" and false):
		# Ya en casa: se asoma por arriba de la casa.
		var casa := _centro(logica.casa_de[p])
		Dibujo.base_animal(_juego, _centro(origen), r * 0.6, _color_par(p))
		Dibujo.animal(_juego, casa + Vector2(0, -_celda * 0.32 + sin(_t * 2.0 + origen) * 2.0), r * 0.55, d, estado)
		return
	elif _animal_bajo_dedo and c.size() > 1 and c[0] == origen:
		# Semilla: el animal viaja con el dedo; en su lugar queda su camita.
		Dibujo.base_animal(_juego, _centro(origen), r * 0.7, _color_par(p))
		pos = _pos_dedo if (_arrastrando and logica.trazo_par == p) else _centro(c[-1])
		if _arrastrando and logica.trazo_par == p:
			pos = _centro(c[-1]).lerp(_pos_dedo, 0.5)
	else:
		Dibujo.base_animal(_juego, pos, r, _color_par(p))
	if turnos != null and _par_forzado == p and _turno_jugable():
		_juego.draw_circle(pos, r * (1.15 + 0.08 * sin(_t * 5.0)), Color(1, 0.85, 0.3, 0.45))
	Dibujo.animal(_juego, pos, r, d, estado)
	if _fase in ["tormenta", "perdio"] and not logica.llegado[p]:
		Dibujo.paraguas_hoja(_juego, pos + Vector2(0, -r * 0.9), r * 0.7, _t)


func _dibujar_mano(p: Vector2) -> void:
	var col := Color(1, 1, 1, 0.85)
	Dibujo.elipse(_juego, p + Vector2(0, 14), 18, 22, col)
	_juego.draw_line(p + Vector2(0, 0), p + Vector2(0, -26), col, 12.0, true)
	_juego.draw_circle(p + Vector2(0, -26), 6, col)
	_juego.draw_arc(p + Vector2(0, -26), 6, PI, TAU, 8, TINTA, 2.0)


func _dibujar_lluvia() -> void:
	var semilla := _perfil == "semilla"
	for k in 60:
		var x := fmod(k * 97.0 + _t * 60.0, 1280.0)
		var y := fmod(k * 53.0 + _t * (420.0 if not semilla else 160.0), 720.0)
		if semilla:
			# Lluvia de burbujas (Maxi): no da miedo, se ve para jugar.
			_juego.draw_arc(Vector2(x, y), 10.0 + k % 3 * 4.0, 0, TAU, 14, Color(0.6, 0.85, 1.0, 0.8), 2.5, true)
		else:
			_juego.draw_line(Vector2(x, y), Vector2(x - 6, y + 22), Color(0.55, 0.75, 1.0, 0.7), 3.0, true)
	# Gotitas en el "vidrio" que se limpian solas.
	for k in 10:
		var x := fmod(k * 131.0, 1280.0)
		var y := fmod(k * 71.0, 400.0) + _t_fase * 60.0
		Dibujo.elipse(_juego, Vector2(x, y), 8, 12, Color(0.7, 0.88, 1.0, maxf(0.0, 0.6 - _t_fase * 0.2)))


func _dibujar_hud() -> void:
	# Toby (abajo a la izquierda): salta al hablar; empapado tras la tormenta.
	if _tex_toby != null:
		var tam := _tex_toby.get_size()
		var esc := minf(RECT_TOBY.size.x / tam.x, RECT_TOBY.size.y / tam.y)
		var dib := tam * esc
		var pos := RECT_TOBY.position + Vector2((RECT_TOBY.size.x - dib.x) / 2.0, RECT_TOBY.size.y - dib.y)
		pos.y -= sin(_toby_salto * PI) * 18.0
		var tinte := Color.WHITE.lerp(Color("#BFD8FF"), _mojado * 0.6)
		_hud.draw_texture_rect(_tex_toby, Rect2(pos, dib), false, tinte)
		if _mojado > 0.05:
			for k in 6:
				var g := pos + Vector2(dib.x * (0.2 + 0.12 * k), fmod(_t * 50.0 + k * 23.0, dib.y * 0.6))
				Dibujo.elipse(_hud, g, 4, 7, Color(0.5, 0.75, 1.0, _mojado))
	if _fase == "celebrando" or logica.ancho == 0:
		return
	# Avance de la estación: una huellita por tablero (arriba a la derecha), sin números.
	var n := _tableros.size()
	for k in n:
		var c := Vector2(1240 - (n - 1 - k) * 40, 40)
		var hecho := k < _i or (k == _i and _fase in ["fiesta", "celebrando_previo"])
		_hud.draw_circle(c, 17, Color(1, 1, 1, 0.75))
		Dibujo.huella(_hud, c, -PI / 2, 30, "pata", Color("#E8434B") if hecho else Color(0.5, 0.5, 0.55, 0.35))
	# Nube del relojito (riel corto arriba del tablero; no acelera, no parpadea).
	var limite := limite_tormenta()
	if limite > 0.0 and _fase in ["entrando", "jugando", "tormenta"]:
		var x0 := 360.0
		var x1 := 900.0
		var y := 34.0
		_hud.draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.6), 6.0, true)
		_hud.draw_circle(Vector2(x1, y), 9, Color(1, 1, 1, 0.8))
		var u := clampf(_t_tablero / limite, 0.0, 1.0)
		var gris := 0.0 if _perfil == "semilla" else 0.35 + 0.5 * u
		Dibujo.nube(_hud, Vector2(lerpf(x0, x1, u), y), 46.0, gris, _t)
	# Racha (Brote y Estrella).
	if _perfil != "semilla" and turnos == null and logica.racha >= 2 and _fuente != null:
		_texto(_hud, "×%d" % logica.racha, Vector2(1224, 610), 30, Color("#E8589C"))


func _dibujar_fin() -> void:
	_fin.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(1, 1, 1, 0.25))
	Dibujo.rect_redondo_c(_fin, Rect2(440, 240, 400, 330), 40, CREMA, TINTA, 6)
	if _tex_toby != null:
		var tam := _tex_toby.get_size()
		var esc := 120.0 / tam.y
		_fin.draw_texture_rect(_tex_toby, Rect2(Vector2(640 - tam.x * esc / 2.0, 250), tam * esc), false, Color("#DDEBFF"))


func _texto(lienzo: Control, texto: String, centro: Vector2, tamano: int, color: Color) -> void:
	if _fuente == null:
		return
	var ancho := _fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, tamano).x
	lienzo.draw_string_outline(_fuente, centro + Vector2(-ancho / 2.0, tamano * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, 8, Color.WHITE)
	lienzo.draw_string(_fuente, centro + Vector2(-ancho / 2.0, tamano * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


# --- Botones con ícono dibujado (sin texto, GDD §6.3) ---

func _estilizar_boton(boton: Button, fondo: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = TINTA
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(28)
	for nombre in ["normal", "hover", "pressed", "disabled", "focus"]:
		boton.add_theme_stylebox_override(nombre, estilo)


func _icono(boton: Button, dibujo: Callable) -> void:
	var icono := Control.new()
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.draw.connect(dibujo.bind(icono))
	boton.add_child(icono)


func _dibujar_casa_icono(icono: Control) -> void:
	var c := icono.size / 2.0
	var s := minf(icono.size.x, icono.size.y) * 0.28
	icono.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.2, 0), c + Vector2(0, -s * 1.1), c + Vector2(s * 1.2, 0)]), Color("#E8434B"))
	icono.draw_rect(Rect2(c + Vector2(-s * 0.85, 0), Vector2(s * 1.7, s * 1.1)), Color("#FFC83A"))
	icono.draw_rect(Rect2(c + Vector2(-s * 0.25, s * 0.35), Vector2(s * 0.5, s * 0.75)), TINTA)


func _dibujar_otra_vez(icono: Control) -> void:
	var c := icono.size / 2.0
	var r := minf(icono.size.x, icono.size.y) * 0.3
	icono.draw_arc(c, r, -PI * 0.15, PI * 1.45, 32, Color.WHITE, r * 0.32, true)
	var punta := c + Vector2.from_angle(-PI * 0.15) * r
	icono.draw_colored_polygon(PackedVector2Array([punta + Vector2(-r * 0.4, -r * 0.28), punta + Vector2(r * 0.44, -r * 0.12), punta + Vector2(r * 0.04, r * 0.52)]), Color.WHITE)


func _dibujar_escoba(icono: Control) -> void:
	var c := icono.size / 2.0
	icono.draw_line(c + Vector2(18, -30), c + Vector2(-4, 8), Color("#8A5A36"), 8.0, true)
	for k in 5:
		var a := PI * 0.55 + k * 0.18
		Dibujo.elipse(icono, c + Vector2(-8, 16) + Vector2.from_angle(a) * 14.0, 6, 14, Color("#4FB86A"), a)


func _dibujar_antena(icono: Control) -> void:
	var c := icono.size / 2.0
	icono.draw_line(c + Vector2(0, 26), c + Vector2(0, -14), TINTA, 6.0, true)
	icono.draw_colored_polygon(Dibujo.estrella_puntos(c + Vector2(0, -20), 18, _t), Color("#FFC83A"))
	icono.draw_arc(c + Vector2(0, -20), 28, -PI * 0.8, -PI * 0.2, 10, TINTA, 3.0, true)


# ---------------------------------------------------------------------------
# Modo equipo (§12.2; modo-equipo.md §11.4)
# ---------------------------------------------------------------------------

func _preparar_equipo() -> void:
	var bloque = nivel.get("equipo", {})
	_eq = bloque if bloque is Dictionary else {}
	_boton_salir.position = RECT_CASA_EQUIPO.position
	_boton_salir.size = RECT_CASA_EQUIPO.size
	_boton_barrer.hide()
	var perfiles := {}
	for id in equipo:
		perfiles[id] = perfil_de(id)
	var ui: Control = _boton_salir.get_parent()
	turnos.configurar(equipo, _config_gestor(), perfiles, ui)
	var capa := ui.get_node_or_null("capa_equipo")
	if capa != null:
		ui.move_child(capa, _hud.get_index())
	turnos.turno_iniciado.connect(func(_id: String, perfil: String) -> void: aplicar_perfil_turno(perfil))
	turnos.jugada_automatica_pedida.connect(_jugada_automatica_equipo)
	turnos.tope_alcanzado.connect(_al_tope_equipo)
	_cargar_tablero(0)
	_aplicar_reglas("brote")
	_arrancar_equipo.call_deferred()


func _clave_equipo() -> String:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null:
		return progreso.clave_equipo(equipo)
	var copia := equipo.duplicate()
	copia.sort()
	return "+".join(PackedStringArray(copia))


func _config_gestor() -> Dictionary:
	var config: Dictionary = _eq.duplicate(true)
	var comps = _eq.get("composiciones", {})
	var comp: Dictionary = {}
	if comps is Dictionary and not comps.is_empty():
		comp = comps.get(_clave_equipo(), comps.values()[0])
	config.erase("composiciones")
	config["pasos_rival"] = int(comp.get("pasos_rival", _eq.get("pasos_rival", 5)))
	config["aciertos_totales"] = (nivel.get("tableros", [{}])[0].get("pares", {}) as Dictionary).size()
	config["lineas_voz"] = nivel.get("lineas_voz", {})
	var record := -1
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and planeta_id != "" and not en_batalla:
		record = progreso.obtener_record_equipo(planeta_id, _id_nivel_actual(), _clave_equipo())
	config["record_pasos"] = record
	return config


func _arrancar_equipo() -> void:
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or _eq_victoria:
		return
	_voz("intro_ronda")
	await _esperar_voz_libre(6.0)
	if not is_inside_tree() or _eq_victoria:
		return
	if _eq_restaurado:
		turnos.empezar_retomando()
	else:
		turnos.empezar()


func _turno_jugable() -> bool:
	return turnos != null and turnos.turno_activo() and not turnos.entrada_bloqueada() and not _eq_victoria \
		and _eq_gag.is_empty() and not _eq_esperando_paseo


## La capa del perfil del turno: reglas, guía y, para Maxi, el par elegido (el más corto que quede).
func aplicar_perfil_turno(perfil: String) -> void:
	_perfil = perfil
	_aplicar_reglas(perfil)
	_eq_t_turno = 0.0
	_eq_esperando_paseo = false
	_idle = 0.0
	_ayuda_nivel = 0
	_par_forzado = ""
	if perfil == "semilla":
		_par_forzado = _elegir_par_maxi()
		if _par_forzado != "":
			_mostrar_guia(_par_forzado)
			_voz("maxi_brilla")


func _elegir_par_maxi() -> String:
	var mejor := ""
	var largo := 9999
	for p in logica.pares:
		if logica.llegado[p]:
			continue
		var ruta := logica.ruta_libre(p, true)
		if ruta.is_empty():
			ruta.assign(logica.solucion.get(p, []))
		if ruta.size() < largo:
			largo = ruta.size()
			mejor = p
	return mejor


func _procesar_equipo(delta: float) -> void:
	if not _eq_gag.is_empty():
		_eq_gag["t"] += delta
		if _eq_gag["fase"] == "aspirar" and _eq_gag["t"] >= _eq_gag["dur"]:
			_eq_gag["fase"] = "oculto"
		elif _eq_gag["fase"] == "devolver" and _eq_gag["t"] >= _eq_gag["dur"]:
			_eq_gag = {}
	if not _turno_jugable():
		return
	var limites = _eq.get("segundos_por_turno", {})
	var limite := float(limites.get(turnos.perfil_actual(), 0)) if limites is Dictionary else 0.0
	if limite <= 0.0:
		return
	_eq_t_turno += delta
	if _eq_t_turno >= limite:
		# Nadie llegó en el tiempo del turno: el animal "se sienta a esperar" y pasa el turno.
		_eq_t_turno = 0.0
		_arrastrando = false
		logica.soltar()
		turnos.terminar_turno(true)


func _llegada_equipo(p: String) -> void:
	if _eq_contados.has(p):
		return
	_eq_contados[p] = true
	_eq_t_turno = 0.0
	if logica.esta_completo():
		return  # la victoria la maneja _al_completar
	turnos.notificar_acierto()


func _al_tope_equipo() -> void:
	_arrastrando = false
	logica.soltar()
	if _paseos.is_empty():
		turnos.confirmar_turno_estable()
	else:
		_eq_esperando_paseo = true


## M2: `semilla_auto_s` sin tocar nada en el turno de Maxi -> su animal camina solo a su casa.
func _jugada_automatica_equipo() -> void:
	if not _turno_jugable() or turnos.perfil_actual() != "semilla":
		return
	if _par_forzado == "" or logica.llegado.get(_par_forzado, true):
		_par_forzado = _elegir_par_maxi()
	if _par_forzado == "":
		return
	_voz("maxi_regalito")
	var ruta := logica.ruta_libre(_par_forzado, true)
	if ruta.is_empty():
		logica.colocar_solucion(_par_forzado)
	else:
		logica.colocar_ruta(_par_forzado, ruta)


func _victoria_equipo() -> void:
	if _eq_victoria:
		return
	_eq_victoria = true
	_fase = "celebrando"
	var pasos := turnos.pasos_usados()
	turnos.detener()
	_confeti.restart()
	_confeti.emitting = true
	reproducir_sfx(SFX_TABLERO)
	if en_batalla:
		await get_tree().create_timer(1.0).timeout
		if is_inside_tree():
			emitir_completado(0)
		return
	var resultado := asegurar_victoria_equipo(pasos)
	turnos.rival_aplaude()
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	if bool(resultado.get("record_nuevo", false)) and not bool(resultado.get("primer_record", false)):
		turnos.pista.saltar_banderita()
	celebrar_equipo(pasos, _linea_existente("victoria_equipo"))


func ancla_meta_turno() -> Vector2:
	return Vector2(_origen.x - 30.0, _origen.y + logica.alto * _celda / 2.0)


## Los caminos a medias vuelan a la mochila-torre (los llegados quedan: lo conservado nunca se toca).
func gag_derrota_aspirar(destino: Vector2) -> float:
	_arrastrando = false
	logica.soltar()
	for p in logica.pares:
		if not logica.llegado[p]:
			for celda in logica.caminos[p]:
				_particulas.append({"pos": _centro(celda), "vel": (destino - _centro(celda)) * 1.6, "t": 0.0, "dur": 0.6,
					"color": _color_par(p), "tipo": "hoja", "r": _celda * 0.1})
	_eq_gag = {"fase": "aspirar", "t": 0.0, "dur": 0.8}
	return 0.8


## Los animales sin casa se sacuden y vuelven a su punto de partida (sus caminos a medias ya no están).
func gag_derrota_devolver(_perfil_siguiente: String) -> float:
	for p in logica.pares:
		if not logica.llegado[p]:
			logica.borrar_camino(p)
			_salto[p] = _t
	_eq_gag = {"fase": "devolver", "t": 0.0, "dur": 0.6}
	return 0.6


func gag_derrota_terminar_ya(_perfil_siguiente: String) -> void:
	for p in logica.pares:
		if not logica.llegado[p]:
			logica.borrar_camino(p)
	_eq_gag = {}


func contar_logro_equipo() -> int:
	return logica.cantidad_llegados()


func obtener_parcial_equipo() -> Dictionary:
	var llegados := {}
	for p in logica.pares:
		if logica.llegado[p]:
			llegados[p] = (logica.caminos[p] as Array).duplicate()
	return {"llegados": llegados}


func restaurar_parcial_equipo(estado: Dictionary) -> void:
	var llegados = estado.get("llegados", {})
	if not llegados is Dictionary:
		return
	for p in llegados:
		if logica.pares.has(p):
			logica.caminos[p] = (llegados[p] as Array).duplicate()
			logica.llegado[p] = true
			logica.fijos[p] = true
			logica.llegadas_contadas[p] = true
			_eq_contados[p] = true
	_eq_restaurado = true
