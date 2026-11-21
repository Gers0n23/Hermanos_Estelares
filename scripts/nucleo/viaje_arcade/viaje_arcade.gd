extends Node2D

## Viaje arcade entre planetas (HE-136; ficha docs/fichas/viaje-arcade.md). Pantalla del NÚCLEO (no es un
## minijuego): reemplaza al viaje pixel de `viaje_estelar.gd` y el mapa estelar la lanza igual, con
## `planeta_origen` / `planeta_destino`, y escucha `completado(destellos)` y `salir_solicitado`.
##
## Empalma con las cinemáticas de viaje (HE-130, `poc/cinematica_blender/despegue_viaje.py`):
##   video de despegue (hasta que la nave ya está en el espacio)  ->  el juego arranca desde esa misma
##   composición (la misma nave, los mismos planetas y el mismo cielo, renderizados en Blender por
##   `poc/cinematica_blender/sprites_viaje.py`)  ->  shmup  ->  resultados  ->  la nave y el planeta
##   destino vuelven a la composición del empalme  ->  video de llegada (cuyo último cuadro es el primero
##   de la presentación del planeta)  ->  presentación del planeta destino.
## Los videos se cortan con `herramientas/cortar_videos_viaje.py`. Solo se ven la primera vez que ESE
## hermano hace ESA ruta (N-B2); después se entra directo al juego y la llegada es corta (§7.1-4).
##
## La lógica vive en `logica_viaje.gd` (sin nodos); esta escena dibuja, escucha el dedo y suena.
##
## Revisar con ojos (perfil = hermano):
##   bash herramientas/ojos.sh escena=res://escenas/nucleo/viaje_arcade.tscn perfil=nicole \
##        viaje=animalia,melodia sin_video=1 bot=1 tiempos=1,4,8,15

signal completado(destellos: int)
signal salir_solicitado

const RUTA_PERFILES := "res://datos/viaje/perfiles.json"
const CARPETA_RUTAS := "res://datos/viaje/rutas/"
const SPR := "res://assets/sprites/viaje/"
const VOCES := "res://assets/audio/voces/viaje/"

## Composición del cuadro de empalme de los videos (cuadro F_CORTE + 15; igual en las 6 rutas).
const EMPALME_NAVE := Vector2(348, 377)     # medido sobre empalme/*.png (cuerpo de la nave)
const EMPALME_NAVE_ESCALA := 1.2
const EMPALME_DESTINO := Vector2(814, 328)
const EMPALME_DESTINO_ESCALA := 0.42
## La nave en juego: el cuerpo mide ~130 px (§0). Centro del cuerpo dentro del sprite de 480×300.
const NAVE_ESCALA := 0.47
const NAVE_CENTRO := Vector2(276, 142)

const CIELO_ARRIBA := Color("#241958")
const CIELO_ABAJO := Color("#2e1e63")
const ESTRELLA := Color("#ffe98a")
const CONTORNO := Color("#4b3247")
const ORO := Color("#ffd23f")

## Franja de esquina (§4.2, regla 11): casa y Cometa de 96 px con 40 px entre bordes.
const FRANJA := Rect2(0, 0, 280, 120)
const RECT_CASA := Rect2(12, 12, 96, 96)
const RECT_COMETA := Rect2(148, 12, 96, 96)

## Tamaño de dibujo (px) de cada cosa; el radio de choque de la lógica es el 70 % (§5.1).
const TAM := {"meteorito": 124.0, "meteorito_chico": 68.0, "basura": 92.0, "boya": 88.0, "recolector": 100.0,
		"jefe": 250.0, "coleccionauta": 300.0}
const JEFE_SPRITE := {"meteorito_dormilon": "jefe_tierra_arcoiris_despierto", "aspiradora": "jefe_arcoiris_animalia",
		"tocadiscos": "jefe_animalia_melodia", "grua_cubos": "jefe_melodia_cuenta_cuentas",
		"torre_bloques": "jefe_cuenta_cuentas_letralandia", "globo_caritas": "jefe_letralandia_corazon",
		"nave_coleccionauta": "jefe_corazon_coleccionauta"}
const COLOR_PROYECTIL := {"burbuja": Color("#bff0ff"), "piedrita": Color("#d2b9a4"), "cajita": Color("#ffcb3d"),
		"nota": Color("#ff6bd6"), "cubo": Color("#4a6ae0"), "bloque": Color("#ffb35c"), "globito": Color("#ff9ec7"),
		"bolsita": Color("#e8c79a")}
const CONFETI := [Color("#ff6b6b"), Color("#ffcb3d"), Color("#7dd87a"), Color("#6fd6e8"), Color("#b48ce8"),
		Color("#ff9ec7")]

const SFX := {
	"disparo": "res://assets/audio/sfx/viaje/disparo.ogg", "impacto": "res://assets/audio/sfx/viaje/golpe.ogg",
	"rompe": "res://assets/audio/sfx/viaje/explosion.ogg", "boing": "res://assets/audio/sfx/ui/polvo_boing.ogg",
	"derrota": "res://assets/audio/sfx/viaje/averia.ogg", "reinicio": "res://assets/audio/sfx/viaje/reparada.ogg",
	"capsula": "res://assets/audio/sfx/viaje/poder.ogg", "corazon": "res://assets/audio/sfx/viaje/corazon.ogg",
	"jefe": "res://assets/audio/sfx/viaje/jefe.ogg", "jefe_vencido": "res://assets/audio/sfx/viaje/jefe_explota.ogg",
	"fila": "res://assets/audio/sfx/viaje/escuadrilla.ogg", "destello": "res://assets/audio/sfx/ui/seleccionar.ogg",
	"pluf": "res://assets/audio/sfx/ui/puf.ogg", "pop": "res://assets/audio/sfx/ui/toque.ogg",
	"plop": "res://assets/audio/sfx/ui/blup.ogg", "aviso": "res://assets/audio/sfx/ui/fiuu.ogg",
	"bolsa": "res://assets/audio/sfx/ui/abrir.ogg", "huye": "res://assets/audio/sfx/ui/fuuush.ogg",
	"tic": "res://assets/audio/sfx/ui/toque.ogg", "fanfarria": "res://assets/audio/sfx/ui/confirmar.ogg",
}
const MUSICA_VIAJE := "res://assets/audio/musica/viaje_minimax.ogg"
const MUSICA_RESULTADOS := "res://assets/audio/musica/llegada_planeta.ogg"   # el chiptune como guiño (§7.1-8)
## Voces que cuentan como "instrucción" (tocar a Cometa las repite, M7).
const INSTRUCCIONES := ["viaje_intro_maxi", "viaje_intro_nicole", "viaje_intro_sofia", "viaje_sector_1",
		"viaje_sector_2", "viaje_sector_3", "viaje_sector_4", "viaje_aviso_jefe", "viaje_otra_vez", "viaje_regalo",
		"viaje_descanso", "viaje_cometa_al_volante"]

@export var planeta_origen := ""
@export var planeta_destino := ""

var logica: LogicaViaje
var id_perfil := ""
var id_ruta := ""
var datos_ruta: Dictionary = {}
var _guardado: Dictionary = {}

var _etapa := "inicio"    # video_despegue, entrada, juego, resultados, salida, video_llegada, video_presentacion, fin
var _t_etapa := 0.0
var _tex := {}
var _usado := {}           # textura -> Rect2 visible (para centrar y escalar sin el margen transparente)
var _estrellas: Array = []
var _particulas: Array = []
var _anillos: Array = []   # fogonazos / ondas {pos, r, vida, color}
var _avisos := {}          # id -> segundos de brillo (telegrafía)
var _sacudida := Vector2.ZERO
var _resultados: Dictionary = {}
var _destellos_hud := 0.0

# entrada
var _dedo := -1
var _punto := Vector2.ZERO
var _delta := Vector2.ZERO
var _nuevo_toque := false
var _bot := false

# voz (§2.6, N-A1)
var _voz: AudioStreamPlayer
var _disparo: AudioStreamPlayer
var _pium_ventana: Array = []
var _cola_voz := {}
var _voces_retrasadas: Array = []
var _ultima_instruccion := ""
var _cometa_salto := 0.0
var _cometa_mareo := 0.0

# video
var _video: VideoStreamPlayer
var _capa_video: CanvasLayer
var _velo := 0.0           # 0..1 fundido de pantalla (color _velo_color)
var _velo_color := Color.BLACK
var _empalme: Texture2D
var _empalme_alfa := 0.0
var _mundo: Node2D
var _hud: Node2D
var _completado := false
var _primera_vez := false    # este hermano aún no vio los videos de esta ruta (N-B2)
var _narrado: Array = []      # momentos de narración ya lanzados en esta pasada
var _intro_pendiente := false # la instrucción de la intro espera a que Cometa termine de narrar
var _t_intro := 0.0           # _t_etapa en que sonó la instrucción de la intro
var _tono_destello := 1.0


func _ready() -> void:
	_leer_argumentos()
	id_perfil = _perfil_activo()
	_elegir_ruta()
	_cargar_texturas()
	var perfiles: Dictionary = _leer_json(RUTA_PERFILES)
	var dificultad := "brote"
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and id_perfil != "":
		dificultad = progreso.obtener_perfil_dificultad(id_perfil)
		_guardado = progreso.obtener_viaje(id_perfil, id_ruta)
	if _argumento("perfil_dificultad") != "":
		dificultad = _argumento("perfil_dificultad")
	if _argumento("checkpoint") != "":      # revisión: checkpoint=sector,oleada (sector = nº de sectores -> jefe)
		var cp := _argumento("checkpoint").split(",")
		_guardado["checkpoint"] = {"sector": int(cp[0]), "oleada": int(cp[1]) if cp.size() > 1 else 0}
	logica = LogicaViaje.new()
	logica.preparar(perfiles, datos_ruta, dificultad, _guardado, hash(id_ruta) % 1000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 140:
		_estrellas.append({"pos": Vector2(rng.randf() * 1280, rng.randf() * 720), "capa": i % 3,
				"tam": rng.randf_range(1.2, 2.6) + (2.5 if i % 17 == 0 else 0.0), "fase": rng.randf() * TAU})
	_mundo = _capa_dibujo("mundo", _dibujar_mundo)
	_hud = _capa_dibujo("hud", _dibujar_hud)
	_preparar_audio()
	_preparar_video()
	var video: Dictionary = datos_ruta.get("video", {})
	if ResourceLoader.exists(str(video.get("empalme", ""))):
		_empalme = load(str(video["empalme"]))
	_primera_vez = not bool(_guardado.get("video_visto", false)) and _argumento("sin_video") == ""
	if _primera_vez and ResourceLoader.exists(str(video.get("despegue", ""))):
		_cambiar_etapa("video_despegue")
		_reproducir_video(str(video["despegue"]))
	else:
		_cambiar_etapa("entrada")


func _exit_tree() -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_musica()


# --- datos -----------------------------------------------------------------------

func _leer_argumentos() -> void:
	var viaje := _argumento("viaje").split(",")
	if planeta_origen == "":
		planeta_origen = viaje[0] if viaje.size() == 2 else "tierra"
	if planeta_destino == "":
		planeta_destino = viaje[1] if viaje.size() == 2 else "arcoiris"
	_bot = _argumento("bot") != ""


func _argumento(nombre: String) -> String:
	for argumento in OS.get_cmdline_user_args():
		if argumento.trim_prefix("--").begins_with(nombre + "="):
			return argumento.get_slice("=", 1)
	return ""


func _perfil_activo() -> String:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and progreso.perfil_seleccionado != "":
		return progreso.perfil_seleccionado
	return _argumento("perfil") if _argumento("perfil") != "" else "nicole"


## La ruta exacta trae sus videos. Un viaje que no tiene ruta propia (por ejemplo, volver hacia atrás en el
## mapa) usa las oleadas y el jefe de la ruta que llega a ese destino, sin videos.
func _elegir_ruta() -> void:
	id_ruta = "%s_%s" % [planeta_origen, planeta_destino]
	var ruta_datos := CARPETA_RUTAS + id_ruta + ".json"
	if ResourceLoader.exists(ruta_datos) or FileAccess.file_exists(ruta_datos):
		datos_ruta = _leer_json(ruta_datos)
		return
	for archivo in DirAccess.get_files_at(CARPETA_RUTAS):
		if archivo.ends_with("_%s.json" % planeta_destino):
			datos_ruta = _leer_json(CARPETA_RUTAS + archivo)
			break
	if datos_ruta.is_empty():
		datos_ruta = _leer_json(CARPETA_RUTAS + "tierra_arcoiris.json")
	datos_ruta["video"] = {}


func _leer_json(ruta: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string(ruta)
	var datos = JSON.parse_string(texto)
	if not datos is Dictionary:
		push_warning("viaje_arcade: no se pudo leer %s" % ruta)
		return {}
	return datos


func _cargar_texturas() -> void:
	var nombres := ["nave_0", "nave_1", "nave_2", "nave_quieta", "meteorito_0", "meteorito_1", "meteorito_2",
			"meteorito_chico", "basura_satelite", "basura_barril", "recolector", "boya", "bolsa",
			"coleccionauta_nave", "jefe_tierra_arcoiris_dormido"]
	nombres.append_array(JEFE_SPRITE.values())
	for n in nombres:
		_textura(n, SPR + n + ".png")
	for p in [planeta_origen, planeta_destino]:
		_textura("planeta_" + p, SPR + "planeta_%s.png" % p)
	_textura("cometa", "res://assets/sprites/personajes/cometa_base.png")
	_textura("coleccionauta", "res://assets/sprites/personajes/coleccionauta_provisional.png")
	_textura("celebracion", "res://assets/sprites/personajes/%s_celebracion.png" % id_perfil)


func _textura(clave: String, ruta: String) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var t: Texture2D = load(ruta)
	_tex[clave] = t
	var img := t.get_image()
	_usado[clave] = Rect2(img.get_used_rect()) if img != null else Rect2(Vector2.ZERO, t.get_size())


# --- audio y video ----------------------------------------------------------------------

func _preparar_audio() -> void:
	_voz = AudioStreamPlayer.new()
	_voz.bus = "Voz"
	add_child(_voz)
	_disparo = AudioStreamPlayer.new()
	_disparo.bus = "SFX"
	if ResourceLoader.exists(SFX["disparo"]):
		_disparo.stream = load(SFX["disparo"])
	add_child(_disparo)


func _sonar(clave: String, tono := 1.0, db := 0.0) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null and SFX.has(clave):
		audio.reproducir_sfx(SFX[clave], tono, db)


func _musica(ruta: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.reproducir_musica(ruta)


## Voz con cola de una línea (N-A1): si hay acción en pantalla, espera a la próxima pantalla vacía.
func _decir(clave: String, quien := "cometa", forzar := false) -> void:
	if clave == "":
		return
	if clave in INSTRUCCIONES:
		_ultima_instruccion = clave
	if not forzar and _hay_accion():
		_cola_voz = {"clave": clave, "quien": quien}
		return
	var ruta := VOCES + "%s/%s.wav" % [quien, clave]
	if not ResourceLoader.exists(ruta):
		return
	_voz.stream = load(ruta)
	_voz.pitch_scale = 0.82 if quien == "coleccionauta" else 1.08    # TTS provisional: el Coleccionauta más grave
	_voz.play()


func _hay_accion() -> bool:
	if logica == null or not logica.fase in ["juego", "jefe"]:
		return false
	if not logica.enemigos.is_empty() or not logica.balas_enemigas.is_empty():
		return true
	return not logica.jefe.is_empty() and logica.jefe.get("estado", "") in ["aviso", "ataca"]


func _preparar_video() -> void:
	_capa_video = CanvasLayer.new()
	_capa_video.layer = 20
	add_child(_capa_video)
	_video = VideoStreamPlayer.new()
	_video.size = Vector2(1280, 720)
	_video.expand = true
	_video.bus = "Musica"
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_video.finished.connect(_video_termino)
	_capa_video.add_child(_video)


func _reproducir_video(ruta: String) -> void:
	var stream: VideoStream = load(ruta)
	if stream == null:
		_video_termino()
		return
	_video.stream = stream
	_video.visible = true
	_video.play()
	match _etapa:
		"video_despegue":
			_narrar("despegue")
		"video_presentacion":
			_narrar("presentacion")


func _video_termino() -> void:
	_video.stop()
	match _etapa:
		"video_despegue":
			_marcar_video_visto()
			_cambiar_etapa("entrada")
		"video_llegada":
			var pres := str(datos_ruta.get("video", {}).get("presentacion", ""))
			if ResourceLoader.exists(pres):
				_cambiar_etapa("video_presentacion")
				_reproducir_video(pres)
			else:
				_terminar()
		"video_presentacion":
			_terminar()
	if _etapa == "entrada":
		_video.visible = false


func _marcar_video_visto() -> void:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and id_perfil != "":
		progreso.fijar_viaje(id_perfil, id_ruta, "video_visto", true)


func _cambiar_etapa(etapa: String) -> void:
	_etapa = etapa
	print("DEPURA etapa ", etapa, " t=", Time.get_ticks_msec())
	_t_etapa = 0.0
	match etapa:
		"entrada":
			_velo = 0.0 if _empalme != null else 1.0
			_velo_color = Color.BLACK
			_empalme_alfa = 1.0 if _empalme != null else 0.0
			_musica(MUSICA_VIAJE)
			_intro()
		"resultados":
			_musica(MUSICA_RESULTADOS)


# --- intro y fin ---------------------------------------------------------------------

## §3 y N-B2: Maxi oye su intro corta en cada entrada; Nicole y Sofía, la primera vez en esa ruta.
func _intro() -> void:
	# Cometa narra el despegue la primera vez del hermano en la ruta (narracion-cometa.md §1.5 y §2.7). Si la
	# ruta tiene video de despegue, ya empezo sobre el video; si no (Tierra -> Arcoiris), empieza aqui. La
	# instruccion del juego espera a que termine (nunca se pisan).
	_narrar("despegue")
	if _audio_narrando():
		_intro_pendiente = true
		return
	_decir_intro()


func _decir_intro() -> void:
	_t_intro = _t_etapa
	var clave: String = {"semilla": "viaje_intro_maxi", "brote": "viaje_intro_nicole",
			"estrella": "viaje_intro_sofia"}.get(logica.perfil_id, "viaje_intro_nicole")
	_ultima_instruccion = clave
	if logica.es_maxi() or not bool(_guardado.get("intro_vista", false)):
		_decir(clave, "cometa", true)
		var progreso := get_node_or_null("/root/Progreso")
		if progreso != null and id_perfil != "":
			progreso.fijar_viaje(id_perfil, id_ruta, "intro_vista", true)


## Narracion de Cometa de un momento del viaje (`datos/historia/narracion.json`, "viaje:<ruta>:<momento>"),
## una sola vez por momento: va por el autoload Audio para que la de la presentacion siga sonando al
## llegar al mapa del planeta.
func _narrar(momento: String) -> void:
	if not _primera_vez or momento in _narrado:
		return
	_narrado.append(momento)
	var clave := "narracion_%s_vista" % momento
	if bool(_guardado.get(clave, false)):
		return
	var lineas := Narracion.lineas("viaje:%s:%s" % [id_ruta, momento])
	var audio := get_node_or_null("/root/Audio")
	if lineas.is_empty() or audio == null:
		return
	audio.reproducir_voces(lineas)
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and id_perfil != "":
		progreso.fijar_viaje(id_perfil, id_ruta, clave, true)


func _audio_narrando() -> bool:
	var audio := get_node_or_null("/root/Audio")
	return audio != null and audio.esta_hablando()


func _terminar() -> void:
	if _completado:
		return
	_completado = true
	_etapa = "fin"
	_video.visible = false
	completado.emit(int(_resultados.get("destellos", logica.destellos_consolidados)))


func _salir() -> void:
	if _completado:
		return
	_completado = true
	_sonar("pop")
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.detener_voz()  # salir corta la narracion del viaje
	salir_solicitado.emit()


# --- bucle -----------------------------------------------------------------------------

func _process(dt: float) -> void:
	_t_etapa += dt
	_cometa_salto = maxf(0.0, _cometa_salto - dt * 3.0)
	_cometa_mareo = maxf(0.0, _cometa_mareo - dt)
	for e in _estrellas:
		var corre: float = 0.0 if _etapa.begins_with("video") else [18.0, 45.0, 90.0][e["capa"]] * (1.6 if _etapa == "juego" else 0.6)
		e["pos"].x -= corre * dt
		if e["pos"].x < -4:
			e["pos"].x = 1284
	match _etapa:
		"entrada":
			_empalme_alfa = maxf(0.0, _empalme_alfa - dt / 0.6)
			_velo = maxf(0.0, _velo - dt / 0.6)
			_jugar(dt)
			if _t_etapa > 0.6:
				_etapa = "juego"
		"juego":
			_jugar(dt)
		"resultados":
			_destellos_hud = minf(float(_resultados.get("destellos", 0)), _destellos_hud + dt * 2.0)
			if _t_etapa > 6.0:
				_cambiar_etapa("salida")
		"salida":
			var video: Dictionary = datos_ruta.get("video", {})
			var largo := _primera_vez and ResourceLoader.exists(str(video.get("llegada", "")))
			if _t_etapa > 1.3:
				_empalme_alfa = minf(1.0, _empalme_alfa + dt / 0.35) if _empalme != null else 0.0
				if _empalme == null:
					_velo_color = Color.WHITE
					_velo = minf(1.0, _velo + dt / 0.6)
			if _t_etapa > 1.7:
				if largo:
					_cambiar_etapa("video_llegada")
					_reproducir_video(str(video["llegada"]))
				else:
					_terminar()
	_actualizar_efectos(dt)
	_mundo.queue_redraw()
	_hud.queue_redraw()


func _jugar(dt: float) -> void:
	var teclado := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		teclado.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		teclado.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		teclado.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		teclado.y += 1
	var entrada := {"dedo": _dedo != -1, "nuevo_toque": _nuevo_toque, "delta": _delta, "punto": _punto,
			"teclado": teclado, "disparo": Input.is_key_pressed(KEY_SPACE)}
	if _bot:
		entrada = _entrada_bot()
	_nuevo_toque = false
	_delta = Vector2.ZERO
	if _intro_pendiente and not _audio_narrando():
		_intro_pendiente = false
		_decir_intro()
	logica.voz_sonando = _voz.playing or _intro_pendiente
	var t_intro := _t_etapa - _t_intro
	if logica.fase == "intro" and not _intro_pendiente and (t_intro > 14.0 or not _voz.playing and t_intro > 0.8):
		logica.empezar()
	logica.actualizar(dt, entrada)
	for ev in logica.sacar_eventos():
		_evento(ev)
	# cola de voz: suena en la próxima pantalla vacía (N-A1)
	if not _cola_voz.is_empty() and not _hay_accion() and not _voz.playing:
		var c := _cola_voz
		_cola_voz = {}
		_decir(c["clave"], c["quien"], true)
	for v in _voces_retrasadas.duplicate():
		v["t"] -= dt
		if v["t"] <= 0.0:
			_voces_retrasadas.erase(v)
			_decir(v["clave"], v.get("quien", "cometa"))
	if logica.fase == "fin" and _etapa == "juego":
		_cambiar_etapa("resultados")


## Jugador simulado para revisar con ojos: sigue la fila del enemigo más cercano y dispara siempre.
func _entrada_bot() -> Dictionary:
	var objetivo_y := 360.0 + sin(logica.tiempo * 0.9) * 180.0
	var mejor := 99999.0
	for e in logica.enemigos:
		if e["pos"].x > logica.nave.x and e["pos"].x - logica.nave.x < mejor:
			mejor = e["pos"].x - logica.nave.x
			objetivo_y = e["pos"].y
	if not logica.jefe.is_empty():
		objetivo_y = logica.jefe["pos"].y
	if not logica.colec.is_empty():
		objetivo_y = logica.colec["pos"].y + 120
	var meta := Vector2(clampf(320 + sin(logica.tiempo * 0.4) * 80, 260, 600), objetivo_y)
	var delta := (meta - logica.nave).limit_length(14.0)
	return {"dedo": true, "nuevo_toque": false, "delta": delta, "punto": meta + Vector2(0, 120),
			"teclado": Vector2.ZERO, "disparo": true}


# --- eventos de la lógica: sonido y efectos ---------------------------------------------------

func _evento(ev: Dictionary) -> void:
	var p: Vector2 = ev.get("pos", Vector2.ZERO)
	var maxi := logica.es_maxi()
	match str(ev["tipo"]):
		"disparo":
			_pium()
		"impacto":
			_sonar("impacto", randf_range(0.95, 1.1), -4.0)
			_chispas(p, 6, [Color.WHITE, ORO])
		"rompe":
			_sonar("rompe", randf_range(0.9, 1.15), -2.0)
			_tono_destello = minf(_tono_destello + 0.04, 1.6)
			_confeti(p, 26 if bool(ev.get("grande", false)) else 14, ev.get("tipo", "") in ["basura", "boya"])
		"fila":
			_sonar("fila")
			_anillo(p, ORO)
		"golpe", "boing":
			_sonar("boing")
			_sacudir()
		"escudo_revienta":
			_sonar("plop")
			_anillo(p, Color("#9fe6ff"))
		"plop":
			_sonar("plop")
		"derrota":
			_sonar("derrota")
			_cometa_mareo = 1.2
			_confeti(p, 40 if maxi else 60, true, [Color("#8edcc4"), Color("#fff1d8"), Color("#c9b6e8"), Color("#f5c542")])
		"reinicio":
			_sonar("reinicio")
			_anillo(logica.nave, Color.WHITE, 140.0)
		"checkpoint":
			_guardar_checkpoint(ev["checkpoint"])
		"capsula":
			_sonar("capsula")
			_anillo(p, ORO)
			if ev.get("cual", "") == "supernova":
				_anillo(logica.nave, Color("#fff6c8"), 900.0)
		"destello":
			_sonar("destello", _tono_destello)
			_tono_destello = minf(_tono_destello + 0.08, 1.8)
			_chispas(p, 10, [ORO, Color.WHITE])
		"corazon_regalo", "vida_extra":
			_sonar("corazon")
		"multiplicador":
			_sonar("destello", 1.0 + 0.12 * int(ev.get("valor", 1)))
		"aviso":
			_avisos[ev.get("id", 0)] = logica.cfg["aviso"]
			_sonar("aviso", 1.3, -8.0)
		"aviso_jefe", "aviso_pinza":
			_sonar("aviso", 0.9, -4.0)
		"jefe_listo":
			_sonar("jefe")
		"debil_abre":
			_anillo(p, ORO, 70.0)
		"tic":
			_sonar("tic", 1.8, -10.0)
		"golpe_debil":
			_confeti(p, 10, false)
		"confeti_jefe":
			_confeti(p, 12, false)
			_sacudir(0.25)
		"rebote_jefe":
			_sacudir(0.2)
		"jefe_fase_2":
			_anillo(p, Color("#ff9ec7"), 220.0)
			_sonar("jefe", 1.2)
		"jefe_vencido":
			_sonar("jefe_vencido")
			_confeti(p, 40 if maxi else 70, true)
			_anillo(p, ORO, 300.0)
		"gag_pinza":
			_sonar("boing", 1.3)
		"bolsa_revienta":
			_sonar("bolsa")
			_confeti(p, 16, false)
		"huye":
			_sonar("huye")
		"borde":
			_sonar("boing", 1.5, -10.0)
		"sector_listo":
			_confeti(Vector2(640, 200), 30, false)
		"record_superado":
			_sonar("destello", 1.5)
			_anillo(Vector2(1000, 50), ORO, 80.0)
		"descanso_aparece":
			pass
		"voz":
			var clave := str(ev.get("clave", ""))
			if float(ev.get("retraso", 0.0)) > 0.0:
				_voces_retrasadas.append({"clave": clave, "t": float(ev["retraso"]), "quien": ev.get("quien", "cometa")})
			else:
				_decir(clave, str(ev.get("quien", "cometa")))
		"fin":
			_fin_de_ruta(ev)


## M15: el pium de Maxi va a −6 dB y como máximo 4 por segundo.
func _pium() -> void:
	var tope := int(logica.cfg.get("pium_tope_por_segundo", 0))
	if tope > 0:
		_pium_ventana = _pium_ventana.filter(func(t): return logica.tiempo - t < 1.0)
		if _pium_ventana.size() >= tope:
			return
		_pium_ventana.append(logica.tiempo)
	_disparo.volume_db = float(logica.cfg.get("pium_db", 0.0)) - 6.0
	_disparo.pitch_scale = randf_range(0.95, 1.08)
	_disparo.play()


func _guardar_checkpoint(cp: Dictionary) -> void:
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and id_perfil != "":
		progreso.fijar_viaje(id_perfil, id_ruta, "checkpoint", cp)


func _fin_de_ruta(r: Dictionary) -> void:
	_resultados = r.duplicate()
	var progreso := get_node_or_null("/root/Progreso")
	if progreso != null and id_perfil != "":
		progreso.completar_viaje_ruta(id_perfil, id_ruta)
		if r.get("record_elegible", false):
			_resultados["record"] = progreso.registrar_record_viaje(id_perfil, id_ruta, int(r["puntaje"]))
	if _resultados.get("record", false):
		_decir("viaje_primer_record" if _resultados.get("primer_record", false) else "viaje_record", "cometa", true)
		_confeti(Vector2(640, 300), 50, false)
	_sonar("fanfarria")


# --- efectos ----------------------------------------------------------------------------

func _confeti(p: Vector2, n: int, tuercas: bool, colores: Array = CONFETI) -> void:
	if logica.es_maxi():
		n = mini(n, 40)      # P1: tope de 40 partículas por evento en Maxi
	for i in n:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * randf_range(120, 420)
		_particulas.append({"pos": p, "vel": v, "vida": randf_range(0.7, 1.2), "color": colores[i % colores.size()],
				"tam": randf_range(5, 10), "giro": randf() * TAU, "tuerca": tuercas and i % 4 == 0})


func _chispas(p: Vector2, n: int, colores: Array) -> void:
	for i in n:
		var a := randf() * TAU
		_particulas.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(200, 380), "vida": 0.3,
				"color": colores[i % colores.size()], "tam": 3.5, "giro": 0.0, "tuerca": false})


func _anillo(p: Vector2, c: Color, r := 90.0) -> void:
	_anillos.append({"pos": p, "r": 10.0, "max": r, "vida": 0.45, "color": c})


func _sacudir(fuerza := 0.6) -> void:
	logica.temblor = minf(1.0, logica.temblor + fuerza)


func _actualizar_efectos(dt: float) -> void:
	for p in _particulas:
		p["pos"] += p["vel"] * dt
		p["vel"] *= 0.93
		p["vel"].y += 260 * dt
		p["vida"] -= dt
		p["giro"] += dt * 6
	_particulas = _particulas.filter(func(p): return p["vida"] > 0.0)
	for a in _anillos:
		a["vida"] -= dt
		a["r"] = lerpf(a["r"], a["max"], 0.25)
	_anillos = _anillos.filter(func(a): return a["vida"] > 0.0)
	for k in _avisos.keys():
		_avisos[k] -= dt
		if _avisos[k] <= 0.0:
			_avisos.erase(k)
	# §4.1: temblor por trauma con ruido (no seno), amplitud ∝ trauma²; tope por perfil
	var trauma := logica.temblor if logica != null else 0.0
	var tope := float(logica.cfg.get("temblor_max", 10.0)) if logica != null else 0.0
	_sacudida = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * tope * trauma * trauma
	_mundo.position = _sacudida


# --- entrada (§4) -------------------------------------------------------------------------

func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		var toque := evento as InputEventScreenTouch
		if toque.pressed:
			_tocar(toque.index, toque.position)
		elif toque.index == _dedo:
			_dedo = -1
	elif evento is InputEventScreenDrag:
		var arrastre := evento as InputEventScreenDrag
		if arrastre.index == _dedo:
			_delta += arrastre.position - _punto
			_punto = arrastre.position


func _tocar(indice: int, pos: Vector2) -> void:
	if _dedo != -1:
		return      # M4: solo el primer dedo controla
	# franja de esquina (regla 11): solo casa y Cometa reaccionan
	if FRANJA.has_point(pos):
		if RECT_CASA.grow(8).has_point(pos):
			_salir()
		elif RECT_COMETA.grow(8).has_point(pos):
			_cometa_salto = 1.0
			if _voz.playing or _hay_accion():
				_sonar("pluf")
				_cola_voz = {"clave": _ultima_instruccion, "quien": "cometa"}
			else:
				_decir(_ultima_instruccion, "cometa", true)
		else:
			_sonar("pluf", 1.0, -6.0)
			_cometa_salto = 0.5
		return
	match _etapa:
		"video_despegue", "video_llegada", "video_presentacion":
			_sonar("pop")       # P3: se salta con un toque, sin disparar ni mover
			_video_termino()
			return
		"resultados":
			if _t_etapa > 1.5:
				_cambiar_etapa("salida")
			return
		"salida", "fin":
			return
	if logica.descanso_visible and LogicaViaje.ICONO_DESCANSO.grow(6).has_point(pos):
		_descansar()
		return
	if logica.fase == "intro":
		_sonar("pop")
		_voz.stop()
		logica.empezar()
	elif logica.fase in ["gag", "reinicio"]:
		logica.acortar()
	_dedo = indice
	_punto = pos
	_nuevo_toque = true


## §7.4: el icono de descanso lleva al mapa con el checkpoint guardado, sin "¿seguro?".
func _descansar() -> void:
	_decir("viaje_adios", "cometa", true)
	_salir()


# --- dibujo ---------------------------------------------------------------------------------

func _capa_dibujo(nombre: String, dibujo: Callable) -> Node2D:
	var n := Node2D.new()
	n.name = nombre
	n.draw.connect(dibujo)
	add_child(n)
	return n


func _sprite(lienzo: CanvasItem, clave: String, centro: Vector2, alto_o_ancho: float, modulo := Color.WHITE,
		por_ancho := false, giro := 0.0, voltear := false, estira := Vector2.ONE) -> void:
	if not _tex.has(clave):
		lienzo.draw_circle(centro, alto_o_ancho * 0.4, Color("#c9b6e8"))
		return
	var t: Texture2D = _tex[clave]
	var u: Rect2 = _usado[clave]
	var escala := alto_o_ancho / (u.size.x if por_ancho else maxf(u.size.x, u.size.y))
	var tam := u.size * escala
	lienzo.draw_set_transform(centro, giro, Vector2(-1 if voltear else 1, 1) * estira)
	lienzo.draw_texture_rect_region(t, Rect2(-tam / 2, tam), u, modulo)
	lienzo.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _dibujar_mundo() -> void:
	var m := _mundo
	m.draw_rect(Rect2(-40, -40, 1360, 800), CIELO_ARRIBA)
	for i in 8:
		var y := 360.0 + i * 50
		m.draw_rect(Rect2(-40, y, 1360, 52), CIELO_ARRIBA.lerp(CIELO_ABAJO, (i + 1) / 8.0))
	for e in _estrellas:
		var c := ESTRELLA
		c.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 600.0 + e["fase"])
		if e["tam"] > 3.0:
			_estrellita(m, e["pos"], e["tam"] * 1.6, c)
		else:
			m.draw_circle(e["pos"], e["tam"], c)
	_dibujar_planetas(m)
	if logica == null:
		return
	for o in logica.objetos:
		_dibujar_objeto(m, o)
	for e in logica.enemigos:
		_dibujar_enemigo(m, e)
	if not logica.jefe.is_empty():
		_dibujar_jefe(m)
	if not logica.colec.is_empty():
		_dibujar_coleccionauta(m)
	for b in logica.balas_enemigas:
		var c: Color = COLOR_PROYECTIL.get(b["tipo"], Color.WHITE)
		m.draw_circle(b["pos"], 17, CONTORNO)
		m.draw_circle(b["pos"], 14, c)
		m.draw_circle(b["pos"] + Vector2(-4, -5), 4, Color(1, 1, 1, 0.8))
	for b in logica.balas:
		m.draw_line(b["pos"] - Vector2(26, 0), b["pos"], Color("#fff6c8"), 7.0, true)
		_estrellita(m, b["pos"], 9.0, ORO)
	_dibujar_nave(m)
	for p in _particulas:
		var c: Color = p["color"]
		c.a = clampf(p["vida"] * 2.0, 0.0, 1.0)
		m.draw_set_transform(p["pos"], p["giro"], Vector2.ONE)
		if p["tuerca"]:
			m.draw_circle(Vector2.ZERO, p["tam"], Color("#d6d6e6", c.a))
			m.draw_circle(Vector2.ZERO, p["tam"] * 0.4, CIELO_ARRIBA)
		else:
			m.draw_rect(Rect2(-p["tam"] / 2, -p["tam"] / 4, p["tam"], p["tam"] / 2), c)
		m.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for a in _anillos:
		var c: Color = a["color"]
		c.a = clampf(a["vida"] * 2.2, 0.0, 1.0)
		m.draw_arc(a["pos"], a["r"], 0, TAU, 48, c, 6.0, true)


func _estrellita(m: CanvasItem, p: Vector2, r: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(p + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	m.draw_colored_polygon(pts, c)


## El origen se queda atrás al empezar; el destino crece con el avance y, al salir, vuelve a la
## composición exacta del cuadro de empalme del video de llegada.
func _dibujar_planetas(m: CanvasItem) -> void:
	var t_juego := logica.tiempo if logica != null else 0.0
	var o := clampf(t_juego / 3.0, 0.0, 1.0)
	if o < 1.0 and _tex.has("planeta_" + planeta_origen):
		_sprite(m, "planeta_" + planeta_origen, Vector2(-120 - 300 * o, 330), 620.0, Color(1, 1, 1, 1.0 - o * 0.5))
	var clave := "planeta_" + planeta_destino
	if not _tex.has(clave):
		return
	var av := logica.avance() if logica != null else 0.0
	var pos := EMPALME_DESTINO.lerp(Vector2(1090, 250), clampf(t_juego / 1.2, 0.0, 1.0))
	var escala := lerpf(EMPALME_DESTINO_ESCALA, 0.30 + 0.25 * av, clampf(t_juego / 1.2, 0.0, 1.0))
	if _etapa in ["salida", "video_llegada", "video_presentacion", "fin"]:
		var s := smoothstep(0.0, 1.3, _t_etapa) if _etapa == "salida" else 1.0
		pos = pos.lerp(EMPALME_DESTINO, s)
		escala = lerpf(escala, EMPALME_DESTINO_ESCALA, s)
	var t: Texture2D = _tex[clave]
	var tam := t.get_size() * escala
	m.draw_texture_rect(t, Rect2(pos - tam / 2, tam), false)


func _dibujar_nave(m: CanvasItem) -> void:
	if logica.fase == "gag":
		return      # se desarmó en pedacitos
	var p := logica.nave
	var escala := NAVE_ESCALA
	if _etapa == "entrada":
		var s := smoothstep(0.0, 0.6, _t_etapa)
		p = EMPALME_NAVE.lerp(p, s)
		escala = lerpf(EMPALME_NAVE_ESCALA, NAVE_ESCALA, s)
	elif _etapa in ["salida", "video_llegada", "fin"]:
		var s := smoothstep(0.0, 1.3, _t_etapa) if _etapa == "salida" else 1.0
		p = p.lerp(EMPALME_NAVE, s)
		escala = lerpf(NAVE_ESCALA, EMPALME_NAVE_ESCALA, s)
	if logica.invulnerable > 0.0 and logica.fase != "reinicio" and int(logica.invulnerable * 12) % 2 == 0:
		return      # parpadeo de invulnerabilidad
	var cuadro := "nave_%d" % (int(Time.get_ticks_msec() / 70) % 3)
	var tope_giro := deg_to_rad(10.0 if logica.es_maxi() else 16.0)       # P5: alabeo de Maxi ≤ 10°
	var giro := clampf(logica.nave_vel.y / 2400.0, -tope_giro, tope_giro)
	var t: Texture2D = _tex.get(cuadro)
	if t == null:
		m.draw_circle(p, 40, Color("#8edcc4"))
		return
	m.draw_set_transform(p, giro, Vector2(escala, escala))
	m.draw_texture(t, -NAVE_CENTRO)
	m.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if logica.volante:     # copiloto decorativo: un gorrito de Cometa asomando en la cúpula (N-B1)
		m.draw_circle(p + Vector2(18, -52) * escala / NAVE_ESCALA, 11, Color("#ffd23f"))
	if logica.escudo:
		var r := 78.0
		m.draw_circle(p, r, Color(0.62, 0.9, 1.0, 0.18))
		m.draw_arc(p, r, 0, TAU, 48, Color(0.75, 0.95, 1.0, 0.8), 4.0, true)
	if logica.minicometas > 0.0:
		for lado in [-1, 1]:
			_sprite(m, "cometa", p + Vector2(10, 64 * lado), 54.0)


func _dibujar_enemigo(m: CanvasItem, e: Dictionary) -> void:
	var tipo: String = e["tipo"]
	var clave := tipo
	match tipo:
		"meteorito":
			clave = "meteorito_%d" % int(e.get("variante", 0))
		"basura":
			clave = "basura_satelite" if int(e.get("variante", 0)) == 0 else "basura_barril"
	var modulo := Color(2.2, 2.2, 2.2) if e["golpe_t"] > 0.0 else Color.WHITE
	if _avisos.has(e["id"]) or e.get("picada_estado", "") == "aviso":
		var brillo := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 60.0)
		m.draw_circle(e["pos"], TAM.get(tipo, 90.0) * 0.62, Color(1.0, 0.85, 0.3, 0.25 + 0.3 * brillo))
		modulo = modulo * Color(1.0 + 0.5 * brillo, 1.0 + 0.4 * brillo, 1.0)
	var giro := 0.0
	if tipo.begins_with("meteorito") or tipo == "basura":
		giro = e["t"] * float(e["giro"])
	_sprite(m, clave, e["pos"], TAM.get(tipo, 90.0), modulo, false, giro)


func _dibujar_objeto(m: CanvasItem, o: Dictionary) -> void:
	var p: Vector2 = o["pos"]
	var pulso := 1.0 + 0.1 * sin(o["t"] * 8.0)
	if o["tipo"] == "destello":
		var r := float(logica.cfg["hitbox_destello"]) * 0.42 * pulso
		m.draw_circle(p, r * 1.1, Color(1.0, 0.95, 0.6, 0.25))
		_estrellita(m, p, r, ORO)
		_estrellita(m, p, r * 0.45, Color.WHITE)
		return
	m.draw_circle(p, 34 * pulso, Color(1, 1, 1, 0.25))
	m.draw_arc(p, 34 * pulso, 0, TAU, 32, Color(1, 1, 1, 0.9), 3.0, true)
	match str(o["cual"]):
		"arma":
			_estrellita(m, p, 20, Color("#ff9f4a"))
			m.draw_line(p + Vector2(-12, 0), p + Vector2(14, 0), Color.WHITE, 5.0)
		"minicometas":
			_sprite(m, "cometa", p, 50.0)
		"iman":
			m.draw_arc(p + Vector2(0, -2), 14, 0, PI, 16, Color("#ff5f7a"), 9.0)
			m.draw_line(p + Vector2(-14, -2), p + Vector2(-14, -16), Color("#ff5f7a"), 9.0)
			m.draw_line(p + Vector2(14, -2), p + Vector2(14, -16), Color("#ff5f7a"), 9.0)
		"supernova":
			_estrellita(m, p, 26, Color("#fff6c8"))
			_estrellita(m, p, 14, Color("#ff9ec7"))
		"corazon":
			_corazon(m, p, 22, Color("#ff5f9e"))
		"escudo":
			m.draw_arc(p, 18, 0, TAU, 24, Color("#9fe6ff"), 6.0)


func _dibujar_jefe(m: CanvasItem) -> void:
	var j := logica.jefe
	var clave: String = JEFE_SPRITE.get(j["id"], "jefe_tierra_arcoiris_despierto")
	if j["id"] == "meteorito_dormilon" and j["estado"] in ["entra", "debil"]:
		clave = "jefe_tierra_arcoiris_dormido"     # bosteza entre ataques
	var modulo := Color(1.3, 1.3, 1.3) if j["golpe_t"] > 0.0 else Color.WHITE     # §2.8: recibe ráfagas, nunca blanco sostenido
	var tam := float(TAM["jefe"])
	if j["estado"] == "aviso":     # telegrafía: brilla y tiembla (§5.2), sin voz
		var b := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 50.0)
		m.draw_circle(j["pos"], tam * 0.6, Color(1.0, 0.85, 0.3, 0.2 + 0.25 * b))
		modulo = Color(1.0 + 0.6 * b, 1.0 + 0.4 * b, 1.0)
	if j["estado"] == "vencido":
		var s := maxf(0.0, 1.0 - j["t"] / 0.5)
		tam *= s
		if tam < 4:
			return
	var giro := 0.0
	if j["estado"] == "ataca" and j["id"] == "tocadiscos":
		giro = j["t"] * 3.0
	if j.get("empujando", false):     # M16: el chorro se ve (viento visible)
		for i in 6:
			var x := fmod(Time.get_ticks_msec() / 2.0 + i * 140.0, 800.0)
			m.draw_line(Vector2(j["pos"].x - 120 - x, j["pos"].y - 60 + i * 24),
					Vector2(j["pos"].x - 170 - x, j["pos"].y - 60 + i * 24), Color(1, 1, 1, 0.5), 4.0)
	_sprite(m, clave, j["pos"], tam, modulo, false, giro)
	if j["id"] == "globo_caritas":
		var colores := [Color("#ffd23f"), Color("#7dd87a"), Color("#6fd6e8"), Color("#ff6b6b")]
		var c: Color = colores[int(j["patron"]) % 4]
		m.draw_circle(j["pos"] + Vector2(0, -20), 36, c)
		m.draw_circle(j["pos"] + Vector2(-12, -28), 5, CONTORNO)
		m.draw_circle(j["pos"] + Vector2(12, -28), 5, CONTORNO)
		m.draw_arc(j["pos"] + Vector2(0, -16), 14, 0.2, PI - 0.2, 12, CONTORNO, 4.0)
	if j["debil"]:
		var pd := logica.punto_debil()
		var b := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
		m.draw_circle(pd, 40 + 8 * b, Color(1.0, 0.85, 0.2, 0.35))
		_estrellita(m, pd, 30 + 6 * b, ORO)
		_estrellita(m, pd, 13, Color.WHITE)
	# lluvia: marca donde va a caer (telegrafía)
	if j["estado"] == "aviso" and logica._patrones()[j["patron"]] == "lluvia":
		for i in 4:
			var x := 420.0 + i * 140.0
			m.draw_line(Vector2(x, 130), Vector2(x, 660), Color(1, 0.9, 0.4, 0.2), 30.0)


func _dibujar_coleccionauta(m: CanvasItem) -> void:
	var c := logica.colec
	var p: Vector2 = c["pos"]
	var esc := float(c.get("escala", 1.0))
	if c["pinza_activa"] or c["estado"] == "aviso_pinza":
		var base := p + Vector2(-40, 60) * esc
		var punta: Vector2 = c["pinza"] if c["pinza_activa"] else base
		if c["estado"] == "aviso_pinza":
			var b := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 60.0)
			m.draw_circle(base, 30 + 10 * b, Color(1, 0.85, 0.3, 0.45))
		m.draw_line(base, punta, Color("#d6d6e6"), 9.0, true)
		m.draw_line(base, punta, CONTORNO, 3.0, true)
		m.draw_arc(punta, 24, PI * 0.25, PI * 1.75, 16, Color("#8fe36b"), 10.0, true)
	for b in c["bolsas"]:
		if b["viva"] and c["estado"] in ["pinza", "bolsas"]:     # §8.1: las bolsas cuelgan después de la provocación
			var pb := logica.pos_bolsa(b)
			m.draw_line(p + b["off"] * 0.3, pb + Vector2(0, -30), CONTORNO, 3.0)
			_sprite(m, "bolsa", pb, float(logica.cfg["bolsa_tam"]))
	_sprite(m, "coleccionauta", p + Vector2(0, -78) * esc, 150.0 * esc)
	_sprite(m, "coleccionauta_nave", p, float(TAM["coleccionauta"]) * esc, Color.WHITE, true)


func _corazon(m: CanvasItem, p: Vector2, r: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var t := TAU * k / 24.0
		var x := 16 * pow(sin(t), 3)
		var y := -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		pts.append(p + Vector2(x, y) * r / 16.0)
	m.draw_colored_polygon(pts, c)


# --- HUD (sin texto obligatorio, §2.7) ---------------------------------------------------------

func _dibujar_hud() -> void:
	var h := _hud
	if logica == null or _etapa.begins_with("video") or _etapa == "fin":
		_dibujar_velos(h)
		return
	_dibujar_franja(h)
	# corazones (R3: grandes, ≥ 64 px en Maxi)
	var tam_c := 30.0 if logica.es_maxi() else 24.0
	for i in maxi(logica.corazones, logica.corazones_max):
		var lleno := i < logica.corazones
		var p := Vector2(320 + i * tam_c * 2.3, 44)
		_corazon(h, p + Vector2(2, 3), tam_c + 3, CONTORNO)
		_corazon(h, p, tam_c, Color("#ff5f9e") if lleno else Color(1, 1, 1, 0.25))
	# barra de trayecto (§3): una banderita por sector y el Coleccionauta al final, sin números
	if logica.jefe.is_empty():
		var x0 := 320.0
		var x1 := 860.0
		var y := 98.0
		h.draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.35), 6.0, true)
		var n := maxi(1, logica.n_sectores())
		for s in n:
			var fx := x0 + (x1 - x0) * 0.85 * (s + 1) / n
			var hecho := logica.sector > s
			h.draw_line(Vector2(fx, y), Vector2(fx, y - 22), Color.WHITE, 3.0)
			h.draw_colored_polygon(PackedVector2Array([Vector2(fx, y - 22), Vector2(fx + 18, y - 16), Vector2(fx, y - 10)]),
					ORO if hecho else Color(1, 1, 1, 0.5))
		_sprite(h, "coleccionauta", Vector2(x1 + 18, y - 4), 40.0)
		var px := x0 + (x1 - x0) * logica.avance()
		_sprite(h, "nave_quieta", Vector2(px, y), 54.0, Color.WHITE, true)
	else:
		# barra del jefe (M3): ancha, arriba al centro, sin corazones, con el icono del artefacto (N-A4)
		var j := logica.jefe
		var r := Rect2(400, 86, 480, 22)
		h.draw_rect(r.grow(4), CONTORNO)
		h.draw_rect(r, Color(1, 1, 1, 0.2))
		var f := clampf(float(j["vida"]) / float(j["vida_max"]), 0.0, 1.0)
		h.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), Color("#ff9ec7"))
		var icono: String = JEFE_SPRITE.get(j["id"], "")
		_sprite(h, icono, Vector2(r.end.x + 34, r.get_center().y), 58.0, Color.WHITE if f > 0 else Color(1, 1, 1, 0.3))
	# puntaje: Maxi con 3 estrellas (M6); Nicole y Sofía con número y ×N
	if logica.es_maxi():
		for i in 3:
			var llena := i < logica.multiplicador
			var p := Vector2(985 + i * 58, 52)
			_estrellita(h, p + Vector2(2, 3), 27, CONTORNO)
			_estrellita(h, p, 25, ORO if llena else Color(1, 1, 1, 0.25))
		if logica.multiplicador >= 3:
			h.draw_circle(Vector2(1043, 52), 90, Color(1, 0.85, 0.3, 0.1))
	else:
		var fuente := ThemeDB.fallback_font
		var texto := str(logica.puntaje)
		var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		h.draw_string_outline(fuente, Vector2(1140 - ancho, 58), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, 10, CONTORNO)
		h.draw_string(fuente, Vector2(1140 - ancho, 58), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
		if logica.multiplicador > 1:
			var mt := "×%d" % logica.multiplicador
			h.draw_string_outline(fuente, Vector2(1080, 100), mt, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 8, CONTORNO)
			h.draw_string(fuente, Vector2(1080, 100), mt, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, ORO)
	# destellos ganados en el viaje
	var total := logica.destellos_consolidados + logica.destellos_en_juego
	for i in total:
		_estrellita(h, Vector2(320 + i * 30, 140), 12, ORO if i < logica.destellos_consolidados else Color(1, 1, 0.7, 0.6))
	if logica.descanso_visible:
		_dibujar_descanso(h)
	if _etapa == "resultados":
		_dibujar_resultados(h)
	_dibujar_velos(h)


func _dibujar_franja(h: CanvasItem) -> void:
	# casa (sale sin "¿seguro?", GDD §6.8)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFF4D6")
	estilo.border_color = CONTORNO
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(26)
	h.draw_style_box(estilo, RECT_CASA)
	var c := RECT_CASA.get_center()
	h.draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -2), c + Vector2(0, -28), c + Vector2(30, -2)]), Color("#F0453A"))
	h.draw_rect(Rect2(c + Vector2(-22, -2), Vector2(44, 30)), Color("#FFD23F"))
	h.draw_rect(Rect2(c + Vector2(-7, 10), Vector2(14, 18)), CONTORNO)
	# Cometa: fijo en la franja (Maxi) o flotando dentro de ella (Nicole y Sofía); se estira al tocarlo
	var pc := RECT_COMETA.get_center()
	if not logica.es_maxi():
		pc.y += sin(Time.get_ticks_msec() / 500.0) * 4.0
	pc.y -= _cometa_salto * 10.0
	var estira := 1.0 + 0.18 * _cometa_salto
	var giro := _cometa_mareo * 9.0 if logica.fase == "gag" else 0.0
	h.draw_circle(RECT_COMETA.get_center(), 50, Color(1, 1, 1, 0.12))
	_sprite(h, "cometa", pc, 92.0, Color.WHITE, false, giro, false, Vector2(1.0 / estira, estira))


func _dibujar_descanso(h: CanvasItem) -> void:
	var r: Rect2 = LogicaViaje.ICONO_DESCANSO
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#3B2F78")
	estilo.border_color = Color("#fff4d6")
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(26)
	h.draw_style_box(estilo, r)
	var c := r.get_center()
	h.draw_circle(c + Vector2(-6, -10), 24, Color("#fff2a8"))
	h.draw_circle(c + Vector2(6, -18), 22, Color("#3B2F78"))      # luna
	h.draw_rect(Rect2(c + Vector2(-30, 12), Vector2(60, 16)), Color("#ff9ec7"))     # camita
	h.draw_rect(Rect2(c + Vector2(-30, 4), Vector2(18, 12)), Color.WHITE)
	h.draw_line(c + Vector2(-32, 30), c + Vector2(-32, 6), Color("#fff4d6"), 5)
	h.draw_line(c + Vector2(32, 30), c + Vector2(32, 18), Color("#fff4d6"), 5)


## §10.1: resultados sin texto. Destellos que suben uno a uno, estrellitas de Sofía, puntaje de Nicole y
## Sofía, y el hermano celebrando (puño arriba de Maxi en el récord, Ph).
func _dibujar_resultados(h: CanvasItem) -> void:
	var a := clampf(_t_etapa / 0.4, 0.0, 1.0)
	var panel := Rect2(290, 170, 700, 400)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.16, 0.12, 0.38, 0.88 * a)
	estilo.border_color = Color(1, 0.95, 0.8, a)
	estilo.set_border_width_all(6)
	estilo.set_corner_radius_all(40)
	h.draw_style_box(estilo, panel)
	var salto := absf(sin(_t_etapa * 5.0)) * 18.0 if _resultados.get("record", false) or _t_etapa < 2.0 else 0.0
	_sprite(h, "celebracion", Vector2(410, 390 - salto), 330.0, Color(1, 1, 1, a))
	var n := int(_resultados.get("destellos", 0))
	var visibles := int(_destellos_hud)
	for i in n:
		var p := Vector2(600 + (i % 5) * 70, 260 + (i / 5) * 70)
		if i < visibles:
			_estrellita(h, p + Vector2(2, 3), 30, CONTORNO)
			_estrellita(h, p, 28, ORO)
		else:
			_estrellita(h, p, 28, Color(1, 1, 1, 0.15))
	if logica.perfil_id == "estrella":
		for i in 3:
			var p := Vector2(640 + i * 90, 420)
			var llena := i < int(_resultados.get("estrellitas", 1)) and _t_etapa > 1.0 + i * 0.4
			_estrellita(h, p, 36, Color("#fff6c8") if llena else Color(1, 1, 1, 0.15))
	if not logica.es_maxi():
		var fuente := ThemeDB.fallback_font
		var cuenta := int(lerpf(0, float(_resultados.get("puntaje", 0)), clampf((_t_etapa - 0.8) / 1.5, 0.0, 1.0)))
		var texto := str(cuenta)
		h.draw_string_outline(fuente, Vector2(600, 520), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 56, 12, CONTORNO)
		h.draw_string(fuente, Vector2(600, 520), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 56,
				ORO if _resultados.get("record", false) else Color.WHITE)


func _dibujar_velos(h: CanvasItem) -> void:
	if _empalme != null and _empalme_alfa > 0.0:
		h.draw_texture_rect(_empalme, Rect2(0, 0, 1280, 720), false, Color(1, 1, 1, _empalme_alfa))
	if _velo > 0.0:
		var c := _velo_color
		c.a = _velo
		h.draw_rect(Rect2(0, 0, 1280, 720), c)
