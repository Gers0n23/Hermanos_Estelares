#!/usr/bin/env python3
"""Genera los niveles de «¿Quién habla?» (motor topos) del Planeta Animalia y su guion de voces.

Fuentes: docs/fichas/motor-topos.md (§8.1, §10.3 y §11, valores [HE-124] de la política de derrota del PO,
05-Nov-2026) y docs/fichas/planeta-animalia-zonas.md §4.1 (elencos por zona y hermano), §8 y §9 (rutas).

Escribe:
  datos/niveles/animalia/<zona>/topos_{semilla,brote,estrella,equipo}.json   (5 zonas x 4 = 20 archivos)
  assets/audio/voces/animalia/topos/lineas_tts.tsv                           (guion para el TTS, sin audio)

Los umbrales de estrellitas (p50 / p80) salen del jugador simulado de herramientas/simular_topos.gd
(ver UMBRALES). Uso: python3 herramientas/generar_niveles_topos.py
"""
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZONAS = ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
NOMBRE_ZONA = ["el Campamento", "la Laguna", "la Pradera", "el Árbol de los nidos", "el Valle"]
TEMA_FONDO = ["campamento", "laguna", "pradera", "nidos", "valle"]
V = "voces/animalia/topos"

NOMBRES = {
    "vaca": "vaca", "perro": "perro", "gato": "gato", "pato": "pato", "caballo": "caballo", "gallo": "gallo",
    "lobo_marino": "lobo marino", "hipopotamo": "hipopótamo", "elefante": "elefante", "chancho": "chanchito",
    "perrito_bombero": "perrito bombero", "oveja": "oveja", "burro": "burrito", "triceratops": "triceratops",
    "trex": "tiranosaurio", "spinosaurio": "espinosaurio", "carnotauro": "carnotauro",
    "braquiosaurio": "braquiosaurio", "dinito": "Dinito", "gatito": "gatito", "flamenco": "flamenco",
    "jirafa": "jirafa", "cebra": "cebra", "mono": "mono", "tucan": "tucán", "loro": "loro", "buho": "búho",
    "pony": "pony", "pony_estelar": "pony estelar", "perrito": "perrito", "gerbo": "gerbo", "cabrita": "cabrita",
    "pollito": "pollito", "cuy": "cuy", "pinguino": "pingüino", "ganso": "ganso", "huillin": "huillín",
    "ballena": "ballena", "alpaca": "alpaca", "guanaco": "guanaco", "huemul": "huemul", "pudu": "pudú",
    "nandu": "ñandú", "cabra": "cabra", "lechuza": "lechuza", "tricahue": "tricahue", "choroy": "choroy",
    "carpintero": "carpintero", "mono_aullador": "mono aullador", "perezoso": "perezoso", "chucao": "chucao",
    "condor": "cóndor",
}
# Palabras escritas de Sofía (≤ 8 letras, planeta-animalia-zonas.md §4.1).
PALABRAS = {
    "perrito": "PERRITO", "gatito": "GATITO", "pony": "PONY", "gerbo": "GERBO", "pato": "PATO", "ganso": "GANSO",
    "ballena": "BALLENA", "burro": "BURRO", "caballo": "CABALLO", "cebra": "CEBRA", "jirafa": "JIRAFA",
    "alpaca": "ALPACA", "pudu": "PUDÚ", "nandu": "ÑANDÚ", "oveja": "OVEJA", "cabra": "CABRA", "buho": "BÚHO",
    "tucan": "TUCÁN", "mono": "MONO", "chucao": "CHUCAO", "pinguino": "PINGÜINO",
}
# Letra inicial de Nicole z5.
INICIALES = {"pony": "P", "gatito": "G", "jirafa": "J", "caballo": "C", "vaca": "V", "oveja": "O", "mono": "M"}
SONIDO_LETRA = {"P": "ppp", "G": "ggg", "J": "jjj", "C": "k k k", "V": "vvv", "O": "ooo", "M": "mmm"}

POOLS = {
    "semilla": [
        ["vaca", "perro", "gato", "pato", "caballo", "gallo"],
        ["pato", "lobo_marino", "hipopotamo", "elefante", "chancho", "perrito_bombero"],
        ["caballo", "vaca", "oveja", "elefante", "burro", "triceratops"],
        ["trex", "spinosaurio", "carnotauro", "triceratops", "braquiosaurio", "perro"],
        ["trex", "spinosaurio", "carnotauro", "triceratops", "braquiosaurio", "dinito"],
    ],
    "brote": [
        ["gatito", "caballo", "vaca", "perro", "pato", "oveja"],
        ["pato", "flamenco", "hipopotamo", "lobo_marino", "gatito", "caballo"],
        ["jirafa", "cebra", "elefante", "caballo", "gatito", "burro"],
        ["mono", "tucan", "loro", "buho", "gatito", "caballo", "pony"],
        ["jirafa", "pony", "caballo", "gatito", "vaca", "oveja", "mono", "pony_estelar"],
    ],
    "estrella": [
        ["perrito", "gatito", "gerbo", "pony", "cabrita", "pollito", "cuy"],
        ["lobo_marino", "pinguino", "pato", "ganso", "flamenco", "huillin", "ballena"],
        ["caballo", "burro", "pony", "cebra", "jirafa", "alpaca", "guanaco", "huemul", "pudu", "nandu", "oveja", "cabra"],
        ["buho", "lechuza", "tucan", "tricahue", "choroy", "carpintero", "mono_aullador", "perezoso", "chucao"],
        ["perrito", "gatito", "pony", "gerbo", "pinguino", "lobo_marino", "ballena", "huemul", "pudu", "alpaca",
         "condor", "buho", "lechuza", "tricahue"],
    ],
}
SIMILARES = {
    "semilla": [[], [], [["vaca", "triceratops"]], [], []],
    "brote": [[], [], [], [["pony", "caballo"]], [["pony", "caballo"]]],
    "estrella": [[], [["pato", "ganso"]], [["burro", "caballo"], ["oveja", "cabra"], ["alpaca", "jirafa"]],
                 [["tricahue", "choroy"], ["buho", "lechuza"]], [["buho", "lechuza"]]],
}

# Metas por ronda. La regla del PO (HE-124, GDD §6 regla 11) es el PERCENTIL del jugador simulado de cada edad:
# p10 Maxi, p25 Nicole, p40 Sofía. La ficha estimó 5->7, 14->18 y 20->28 lineales; el simulador
# (herramientas/simular_topos.gd, 400 rondas) muestra que con los t_arriba_s de cada zona esos números caen
# fuera del percentil en varias zonas (p. ej. Nicole z5 ganaba el 7,5 % y Sofía z1 el 99 %), así que aquí van
# los percentiles medidos ("las ajusta disenador-niveles con el simulador manteniendo los percentiles", §8.1).
META_FICHA = {"semilla": [5, 5, 6, 6, 7], "brote": [14, 15, 16, 17, 18], "estrella": [20, 22, 24, 26, 28]}
METAS = {"semilla": [4, 4, 5, 6, 6], "brote": [16, 17, 16, 16, 12], "estrella": [26, 26, 24, 26, 22]}

# Umbrales de estrellitas (suma de las 2 rondas): p50 y p80 del jugador simulado (herramientas/simular_topos.gd,
# 400 partidas por nivel, semilla fija). PROVISIONALES hasta el playtest.
UMBRALES = {
    "brote": [(11050, 12850), (11150, 13000), (11150, 12650), (10450, 12450), (7350, 8800)],
    "estrella": [(19150, 21100), (17400, 19900), (13200, 15050), (13600, 15900), (10100, 11550)],
}


def animal(id_, perfil, zona_i):
    a = {"id": id_, "sonido": "sfx/animalia/animales/%s.ogg" % id_, "nombre_voz": "voces/animalia/nombres/%s.wav" % id_}
    if perfil == "estrella" and id_ in PALABRAS:
        a["palabra"] = PALABRAS[id_]
    if perfil == "brote" and zona_i == 4 and id_ in INICIALES:
        a["inicial"] = INICIALES[id_]
    return a


def voces_comunes(perfil, n):
    p = "%s/%s" % (V, perfil)
    v = {
        "intro": "%s/z%d_intro.wav" % (p, n),
        "instruccion": "%s/instruccion.wav" % p,
        "meta_llena": "%s/meta_llena.wav" % p,
        "victoria": ["%s/victoria_0%d.wav" % (p, i) for i in (1, 2, 3)],
        "derrota_gag": ["%s/derrota_gag_0%d.wav" % (p, i) for i in (1, 2)],
        "regalo": "%s/regalo.wav" % p,
        "toby_dorado": ["%s/toby_dorado_0%d.wav" % (p, i) for i in (1, 2)],
        "toby_dorado_presenta": "%s/toby_dorado_presenta.wav" % p,
        "toby_tocado": "%s/toby_tocado.wav" % p,
    }
    if perfil == "semilla":
        v["ayuda_fuerte"] = "%s/ayuda_fuerte.wav" % p
    else:
        v["ronda_2"] = "%s/ronda_2.wav" % p
        v["descansar"] = "%s/descansar.wav" % p
        v["record"] = "%s/record.wav" % p
        v["primer_record"] = "%s/primer_record.wav" % p
    if perfil == "estrella":
        v["pista_usada"] = "%s/pista_usada.wav" % p
        if n == 5:
            v["impostor"] = ["%s/impostor_0%d.wav" % (p, i) for i in (1, 2)]
            v["impostor_presenta"] = "%s/impostor_presenta.wav" % p
    if perfil == "brote" and n == 5:
        v["letras"] = {l: "%s/letras/%s.wav" % (V, l.lower()) for l in sorted(set(INICIALES.values()))}
    return v


def base(perfil, i):
    zona = ZONAS[i]
    return {
        "id_nivel": "animalia_z%d_topos_%s" % (i + 1, perfil),
        "motor": "topos",
        "perfil": perfil,
        "planeta": "animalia",
        "zona": zona,
        "fondo_tema": TEMA_FONDO[i],
        "fondo": "",
    }


def semilla(i):
    n = i + 1
    d = base("semilla", i)
    d.update({
        "tema": ["El corralito", "Chapuzones", "¡Llega un dino!", "Dinos del bosque alto", "Todos los dinos"][i],
        "nota": "HE-116 (05-Nov-2026). Valores [HE-124] de motor-topos.md §8.1 y §10: reloj, escape a los t_arriba_s y meta al p10 (Maxi pierde, pero suave). Tocar al equivocado no es fallo (celebra). PROVISIONAL hasta el playtest.",
        "madrigueras": [3, 3, 3, 4, 4][i],
        "modo": "tandas",
        "asomados": [2, 2, 2, 3, 3][i],
        "t_arriba_s": [6.0, 5.75, 5.5, 5.25, 5.0][i],
        "aviso_s": 0.15,
        "pausa_entre_pedidos": 0.9,
        "pedidos": None,
        "duracion_s": [45, 50, 55, 60, 60][i],
        "rondas": 1,
        "meta": METAS["semilla"][i],
        "meta_ficha": META_FICHA["semilla"][i],
        "repetir_sonido": "cada_3s",
        "ondas_visibles": "completas",
        "animales": [animal(a, "semilla", i) for a in POOLS["semilla"][i] if not (i == 2 and a == "triceratops")]
        + ([animal("triceratops", "semilla", i)] if i == 2 else []),
        "similares": SIMILARES["semilla"][i],
        "p_similar": 0.0,
        "pedido_escrito": {"p": 0.0, "tipo": "palabra"},
        "pedido_doble": {"p": 0.0, "separacion_s": 0.4},
        "toby_dorado": {"cada_s": "una_vez", "puntos": 0},
        "impostor": None,
        "sorpresa": {"id": "triceratops"} if i == 2 else None,
        "ayuda_idle_s": [3, 5],
        "regalo_tras_derrotas": {"derrotas": 2, "meta_factor": 0.7},
        "ayuda_fuerte_tras_derrotas": {"derrotas": 3, "t_arriba_s": None, "pedidos": 6, "ayuda_idle_s": [2, 4]},
        "descanso_tras_derrotas": None,
        "pistas_cuestan_estrellita": False,
        "lineas_voz": voces_comunes("semilla", n),
    })
    return d


def brote(i):
    n = i + 1
    d = base("brote", i)
    sim = SIMILARES["brote"][i]
    d.update({
        "tema": ["Los amigos del campamento", "La orilla", "Las jirafas", "Arriba en los nidos", "El valle mágico"][i],
        "nota": "HE-116 (05-Nov-2026). Valores [HE-124] de motor-topos.md §8.1: meta al p25 (14 -> 18 por ronda), 2 rondas de 60 s, regalo tras 2 derrotas (meta x 0,8) y descanso tras 3. Umbrales de estrellitas: p50/p80 del jugador simulado (simular_topos.gd). PROVISIONAL.",
        "madrigueras": [4, 4, 6, 6, 6][i],
        "modo": "tandas",
        "asomados": [3, 3, 4, 4, 4][i],
        "t_arriba_s": [2.6, 2.4, 2.2, 2.0, 1.8][i],
        "aviso_s": 0.15,
        "pausa_entre_pedidos": [0.7, 0.7, 0.65, 0.6, 0.6][i],
        "pedidos": None,
        "duracion_s": 60,
        "rondas": 2,
        "meta": METAS["brote"][i],
        "meta_ficha": META_FICHA["brote"][i],
        "repetir_sonido": ["una_vez", "una_vez", "no", "no", "no"][i],
        "ondas_visibles": "completas",
        "animales": [animal(a, "brote", i) for a in POOLS["brote"][i]],
        "similares": sim,
        "p_similar": [0.0, 0.0, 0.0, 0.15, 0.2][i],
        "pedido_escrito": {"p": 0.25 if i == 4 else 0.0, "tipo": "letra"},
        "pedido_doble": {"p": 0.0, "separacion_s": 0.4},
        "toby_dorado": {"cada_s": 15, "puntos": 300},
        "impostor": None,
        "puntos": {"acierto": 100, "racha_max": 5, "rapidito": 50, "rapidito_fraccion": 0.4, "doble": 200, "meta": 500},
        "umbrales_puntaje": {"dos": UMBRALES["brote"][i][0], "tres": UMBRALES["brote"][i][1]},
        "regalo_tras_derrotas": {"derrotas": 2, "meta_factor": 0.8},
        "ayuda_fuerte_tras_derrotas": None,
        "descanso_tras_derrotas": 3,
        "pistas_cuestan_estrellita": False,
        "lineas_voz": voces_comunes("brote", n),
    })
    return d


def estrella(i):
    n = i + 1
    d = base("estrella", i)
    continuo = i >= 2
    d.update({
        "tema": ["Cachorros", "Laguna y costa de Chile", "Pradera y altiplano", "Aves y selva", "El gran coro"][i],
        "nota": "HE-116 (05-Nov-2026). Valores [HE-124] de motor-topos.md §8.1: meta al p40 (20 -> 28 por ronda), 2 rondas de 60 s, regalo tras 3 derrotas (meta x 0,85), descanso tras 4 y pista con costo. Umbrales: p50/p80 del jugador simulado (simular_topos.gd). PROVISIONAL.",
        "madrigueras": [6, 6, 9, 9, 9][i],
        "modo": "continuo" if continuo else "tandas",
        "asomados": [4, 5, 4, 4, 4][i],
        "asomados_min": [2, 2, 2, 3, 3][i],
        "asomados_max": [4, 5, 4, 5, 6][i],
        "intervalo_pedido_s": [1.4, 1.4, 1.4, 1.25, 1.1][i],
        "t_arriba_s": [1.6, 1.45, 1.3, 1.15, 1.0][i],
        "variacion_t_arriba": 0.25,
        "aviso_s": 0.08,
        "pausa_entre_pedidos": 0.5,
        "pedidos": None,
        "duracion_s": 60,
        "rondas": 2,
        "meta": METAS["estrella"][i],
        "meta_ficha": META_FICHA["estrella"][i],
        "repetir_sonido": "no",
        "ondas_visibles": "completas" if i < 2 else "minimas",
        "animales": [animal(a, "estrella", i) for a in POOLS["estrella"][i]],
        "similares": SIMILARES["estrella"][i],
        "p_similar": [0.0, 0.2, 0.25, 0.3, 0.3][i],
        "pedido_escrito": {"p": 0.25 if i >= 2 else 0.0, "tipo": "palabra"},
        "pedido_doble": {"p": 0.2 if i >= 3 else 0.0, "separacion_s": 0.4},
        "toby_dorado": {"cada_s": 12, "puntos": 300},
        "impostor": {"cada_s": 15} if i == 4 else None,
        "puntos": {"acierto": 100, "racha_max": 5, "rapidito": 50, "rapidito_fraccion": 0.4, "doble": 200, "meta": 500},
        "umbrales_puntaje": {"dos": UMBRALES["estrella"][i][0], "tres": UMBRALES["estrella"][i][1]},
        "regalo_tras_derrotas": {"derrotas": 3, "meta_factor": 0.85},
        "ayuda_fuerte_tras_derrotas": None,
        "descanso_tras_derrotas": 4,
        "max_estrellitas_tras_derrota": 2,
        "pistas_cuestan_estrellita": True,
        "pista_pedidos": 3,
        "lineas_voz": voces_comunes("estrella", n),
    })
    return d


VOCES_NUCLEO_EQUIPO = {
    "le_toca": {h: ["voces/nucleo/equipo/le_toca_%s_0%d.wav" % (h, k) for k in (1, 2, 3)] for h in ("maxi", "nicole", "sofia")},
    "te_toca_recordatorio": {h: "voces/nucleo/equipo/te_toca_%s.wav" % h for h in ("maxi", "nicole", "sofia")},
    "te_toca_recordatorio_ventanita": {h: "voces/nucleo/equipo/te_toca_%s_ventanita.wav" % h for h in ("nicole", "sofia")},
    "sube_ventanita": {h: "voces/nucleo/equipo/sube_ventanita_%s.wav" % h for h in ("nicole", "sofia")},
    "maxi_ayuda": "voces/nucleo/equipo/maxi_ayuda.wav",
    "animo_hermanos": {h: ["voces/nucleo/equipo/animo_%s_0%d.wav" % (h, k) for k in (1, 2)] for h in ("maxi", "nicole", "sofia")},
    "rival_avanza": ["voces/nucleo/equipo/coleccionauta/avanza_0%d.wav" % k for k in (1, 2, 3, 4)],
}


def equipo(i):
    n = i + 1
    d = base("equipo", i)
    pool = [a for a in POOLS["brote"][i] if a != "pony_estelar"]
    if i in (3, 4):
        pool = [a for a in pool if a != "pony"]  # sin pares parecidos en equipo: el claro es de los tres
    extra = i  # la meta del equipo crece una por zona
    d.update({
        "id_nivel": "animalia_z%d_topos_equipo" % n,
        "perfil": "brote",
        "modo_juego": "equipo",
        "tema": "¿Quién habla? en equipo: un solo claro y el turno se mide en pedidos (motor-topos.md §12.2)",
        "nota": "HE-116 (05-Nov-2026). Contrato de modo-equipo.md §11.4 y motor-topos.md §12.2: tope por turno (M 1, N 3, S 4), el escape corta el turno, el error es fallo suave, Maxi sin escape y con jugada automatica. Gana el equipo al juntar aciertos_meta; el Coleccionauta avanza en los pases con fallo. Valores de dev-godot PROVISIONALES: disenador-niveles debe simularlos (como HE-66).",
        "madrigueras": 6,
        "modo": "tandas",
        "asomados": 3,
        "t_arriba_s": 2.4,
        "aviso_s": 0.15,
        "pausa_entre_pedidos": 0.7,
        "duracion_s": None,
        "rondas": 1,
        "meta": None,
        "repetir_sonido": "una_vez",
        "ondas_visibles": "completas",
        "animales": [animal(a, "brote", 0) for a in pool],
        "similares": [],
        "p_similar": 0.0,
        "toby_dorado": None,
        "impostor": None,
        "perfiles": {
            "semilla": {"t_arriba_s": None, "asomados": 2, "repetir_sonido": "cada_3s", "ondas_visibles": "completas", "pausa_entre_pedidos": 0.9},
            "brote": {"t_arriba_s": [2.6, 2.4, 2.2, 2.0, 1.8][i], "asomados": 3, "repetir_sonido": "una_vez", "ondas_visibles": "completas", "pausa_entre_pedidos": 0.7},
            "estrella": {"t_arriba_s": [1.6, 1.45, 1.3, 1.15, 1.0][i], "asomados": 4, "repetir_sonido": "no", "ondas_visibles": "completas" if i < 2 else "minimas", "pausa_entre_pedidos": 0.5},
        },
        "equipo": {
            "rival": "coleccionauta",
            "orden": "maxi_intercalado",
            "puerta_tras_semilla": "arrastre",
            "bloqueo_tras_puerta_ms": 400,
            "ms_volteo_equipo": 800,
            "maxi_mueve_rival": False,
            "racha_retrocede_rival": 0,
            "semilla_auto_s": 20,
            "aciertos_max_turno": {"semilla": 1, "brote": 3, "estrella": 4},
            "composiciones": {
                "maxi+nicole": {"pasos_rival": 5, "aciertos_meta": 10 + extra},
                "maxi+sofia": {"pasos_rival": 5, "aciertos_meta": 11 + extra},
                "nicole+sofia": {"pasos_rival": 6, "aciertos_meta": 14 + extra},
                "maxi+nicole+sofia": {"pasos_rival": 6, "aciertos_meta": 14 + extra},
            },
        },
        "lineas_voz": dict(VOCES_NUCLEO_EQUIPO, **{
            "intro_ronda": "%s/equipo/z%d_intro.wav" % (V, n),
            "maxi_regalito": "%s/equipo/maxi_regalito.wav" % V,
            "derrota_gag_equipo": ["%s/equipo/derrota_gag_0%d.wav" % (V, k) for k in (1, 2, 3)],
            "logro_comun": {str(k): "%s/equipo/logro_%02d.wav" % (V, k) for k in range(1, 21)},
            "nos_alcanzo": "%s/equipo/nos_alcanzo.wav" % V,
            "victoria_equipo": "%s/equipo/victoria.wav" % V,
        }),
    })
    return d


# ---------------------------------------------------------------------------
# Guion de voces (Toby; textos para el TTS que elija el PO)
# ---------------------------------------------------------------------------

INTROS = {
    "semilla": [
        "¡Hola, Maxi! Soy Toby. Mis amigos se esconden en sus hoyitos. ¡Escucha quién habla y tócalo!",
        "¡Chapuzones, Maxi! ¿Escuchas? ¡Toca al que hace el ruido!",
        "¡Shhh, Maxi! Hoy viene un dino sorpresa... ¡escucha y toca al que habla!",
        "¡Dinos en el bosque, Maxi! ¡Grrr! Toca al dino que habla.",
        "¡Todos los dinos, Maxi! Y el chiquitito Dinito. ¡Escucha y toca!",
    ],
    "brote": [
        "¡Hola, Nicole! Mis amigos del campamento juegan a esconderse. ¡Toca al que habló antes de que se esconda!",
        "¡A la orilla, Nicole! Escucha bien y toca al que hace el sonido. ¡Rapidito!",
        "¡Llegaron las jirafas, Nicole! La jirafa hace un zumbido suavecito. ¿Lo escuchas?",
        "¡Arriba en los nidos, Nicole! Ojo: el pony y el caballo relinchan distinto. ¡Escucha bien!",
        "¡El valle mágico, Nicole! A veces te muestro una letra: toca al animal que empieza con esa letra.",
    ],
    "estrella": [
        "¡Sofía, los cachorros quieren jugar! Toca al que habló antes de que se esconda. ¿Cuántos atrapas en un minuto?",
        "La laguna y la costa de Chile, Sofía. Cuidado: el pato y el ganso suenan parecido.",
        "Ahora todos salen y se esconden a su ritmo. Toca solo al que habla... ¡y a veces te lo escribo en un cartel!",
        "Aves y selva, Sofía. A veces hablan dos seguidos: ¡toca a los dos!",
        "El gran coro, Sofía. Y ojo: alguien se disfrazó de animal... ¡no lo toques!",
    ],
}
TEXTOS = {
    "semilla": {
        "instruccion": "¡Escucha! Toca al animalito que hace el ruido.",
        "meta_llena": "¡Siii! ¡El collar está lleno! ¡Sigamos jugando!",
        "victoria_01": "¡Lo lograste, Maxi! ¡Qué oído de explorador!",
        "victoria_02": "¡Bravo, Maxi! ¡Todos mis amigos te aplauden!",
        "victoria_03": "¡Guau, guau! ¡Ganaste, Maxi!",
        "derrota_gag_01": "¡Achís! ¡Jajaja! ¡Otra vez, otra vez!",
        "derrota_gag_02": "¡Uy, se nos hizo de noche! ¡Juguemos otra vez!",
        "regalo": "¡Te ayudo con mi nariz! Esta vez el collar es más cortito.",
        "ayuda_fuerte": "¡Ahora yo te ayudo a buscar! Los animalitos te esperan.",
        "toby_dorado_01": "¡Me encontraste! ¡Soy yo, Toby dorado!",
        "toby_dorado_02": "¡Jiji! ¡Hola, Maxi!",
        "toby_dorado_presenta": "¡Sorpresa! A veces yo también me escondo, brillando como el oro.",
        "toby_tocado": "¡Guau! ¡Escucha otra vez!",
    },
    "brote": {
        "instruccion": "Escucha el sonido y toca al animal que habló, antes de que se esconda.",
        "meta_llena": "¡Collar lleno, Nicole! ¡Sigue sumando puntos!",
        "ronda_2": "¡Ganaste la primera ronda! ¡Vamos con la segunda!",
        "victoria_01": "¡Lo lograste, Nicole! ¡Tienes oído de jirafa!",
        "victoria_02": "¡Increíble, Nicole! ¡Todos mis amigos cantan para ti!",
        "victoria_03": "¡Bravo, Nicole! ¡Qué rapidez!",
        "derrota_gag_01": "¡Nos escondimos todos! ¡Achís! ¡Otra vez!",
        "derrota_gag_02": "¡Jajaja, se me empañó el casco! ¿Jugamos otra?",
        "regalo": "¡Te ayudo olfateando! Esta vez el collar es más cortito.",
        "descansar": "¿Vamos a jugar a otra cosa y volvemos después? ¡Tú eliges!",
        "record": "¡Nuevo récord, Nicole! ¡Te ganaste el hueso-trofeo!",
        "primer_record": "¡Tu primer récord! Aquí queda tu banderita.",
        "toby_dorado_01": "¡Me atrapaste! ¡Puntos dorados!",
        "toby_dorado_02": "¡Toby dorado! ¡Bien, Nicole!",
        "toby_dorado_presenta": "¡Si me ves brillar, tócame! ¡Valgo muchos puntos!",
        "toby_tocado": "¡Guau! ¡Tú puedes, Nicole!",
    },
    "estrella": {
        "instruccion": "Toca solo al que habla, antes de que se esconda. Llena el collar antes de que se ponga el sol.",
        "meta_llena": "¡Meta! Ahora, a buscar el récord.",
        "ronda_2": "Primera ronda lista. ¡La segunda va más rápido!",
        "victoria_01": "¡Ganaste, Sofía! Tienes reflejos de líder.",
        "victoria_02": "¡Qué oído, Sofía! Ni el búho te gana.",
        "victoria_03": "¡Bravo! Todos los animales cantan en tu honor.",
        "derrota_gag_01": "¡Nos escondimos todos! ¡Achís! ¿La revancha?",
        "derrota_gag_02": "¡Jajaja! Se me empañó el casco. ¡Otra vez, Sofía!",
        "regalo": "Te ayudo olfateando: esta vez la meta es un poquito más corta.",
        "descansar": "¿Y si jugamos a otra cosa y volvemos? El récord te espera.",
        "record": "¡Nuevo récord, Sofía! El hueso-trofeo es tuyo.",
        "primer_record": "Tu primer récord. ¡A superarlo!",
        "pista_usada": "¡Olfateo, olfateo! Mira dónde brilla.",
        "toby_dorado_01": "¡Me atrapaste! Trescientos puntos.",
        "toby_dorado_02": "¡Toby dorado! ¡Qué reflejos!",
        "toby_dorado_presenta": "Si me ves brillar, tócame: valgo trescientos puntos, y no corto tu racha.",
        "toby_tocado": "¡Guau! Concéntrate, tú puedes.",
        "impostor_01": "¡Me descubriste! ¡Jajaja, qué cosquillas!",
        "impostor_02": "¡Ay, se me cayeron las orejas de cartón!",
        "impostor_presenta": "¡Cuidado! El Coleccionauta se disfrazó de animal. ¡A él no lo toques!",
    },
}
EQUIPO_TEXTOS = {
    "maxi_regalito": "¡Mira, Maxi! ¡El animalito salta solito para ti!",
    "derrota_gag_01": "¡A mi colección! ¡Sluuurp!",
    "derrota_gag_02": "¡Achís! ¡Uy, se me escaparon todos!",
    "derrota_gag_03": "¡Jajaja! ¡Otra vez, equipo!",
    "nos_alcanzo": "¡Nos alcanzó! Pero juntos lo volvemos a intentar.",
    "victoria": "¡Lo logramos juntos! ¡Los animales cantan para el equipo!",
}
EQUIPO_INTROS = [
    "¡Juntos, en el campamento! Escuchen quién habla y tóquenlo. ¡Cada uno en su turno!",
    "¡Equipo a la laguna! Toquen al que habla antes de que se esconda.",
    "¡Equipo a la pradera! ¡Que no se escape ninguno!",
    "¡Equipo a los nidos! Escuchen bien, por turnos.",
    "¡El valle, equipo! ¡Juntemos muchos animalitos!",
]


def guion():
    lineas = [
        "# Voces de «¿Quién habla?» (motor topos, Planeta Animalia; HE-116, 05-Nov-2026). Las dice Toby.",
        "# Generado por herramientas/generar_niveles_topos.py (mismas rutas que los JSON de datos/niveles/animalia/).",
        "# Formato: ruta relativa a assets/audio/ <TAB> texto. La directiva '# personaje: <id>' elige la voz (herramientas/voces_personajes/<id>/).",
        "# Sin audio todavia: el juego funciona sin estos archivos (Audio.reproducir_voz los salta y el motor revisa que existan).",
        "# Pendiente de guionista (HE-112): revisar tono y datos; los sonidos de animales y SFX son sintetizados (motor) hasta los CC0.",
        "# personaje: toby",
    ]
    for perfil in ("semilla", "brote", "estrella"):
        for n in range(1, 6):
            lineas.append("%s/%s/z%d_intro.wav\t%s" % (V, perfil, n, INTROS[perfil][n - 1]))
        for clave, texto in TEXTOS[perfil].items():
            lineas.append("%s/%s/%s.wav\t%s" % (V, perfil, clave, texto))
    for letra in sorted(set(INICIALES.values())):
        lineas.append("%s/letras/%s.wav\t¡%s!" % (V, letra.lower(), SONIDO_LETRA[letra]))
    for n in range(1, 6):
        lineas.append("%s/equipo/z%d_intro.wav\t%s" % (V, n, EQUIPO_INTROS[n - 1]))
    for clave, texto in EQUIPO_TEXTOS.items():
        lineas.append("%s/equipo/%s.wav\t%s" % (V, clave, texto))
    for k in range(1, 21):
        lineas.append("%s/equipo/logro_%02d.wav\t¡Igual encontramos %d animalito%s!" % (V, k, k, "" if k == 1 else "s"))
    lineas.append("# Nombres de animales (compartidos por los 4 motores de Animalia; si otro guion ya los tiene, gana uno solo).")
    usados = sorted({a for pools in POOLS.values() for pool in pools for a in pool})
    for a in usados:
        lineas.append("voces/animalia/nombres/%s.wav\t¡%s!" % (a, NOMBRES[a][0].upper() + NOMBRES[a][1:]))
    return "\n".join(lineas) + "\n"


def main():
    for i, zona in enumerate(ZONAS):
        carpeta = os.path.join(RAIZ, "datos", "niveles", "animalia", zona)
        os.makedirs(carpeta, exist_ok=True)
        for nombre, datos in (("semilla", semilla(i)), ("brote", brote(i)), ("estrella", estrella(i)), ("equipo", equipo(i))):
            ruta = os.path.join(carpeta, "topos_%s.json" % nombre)
            with open(ruta, "w", encoding="utf-8") as f:
                json.dump(datos, f, ensure_ascii=False, indent=2)
                f.write("\n")
    ruta_tsv = os.path.join(RAIZ, "assets", "audio", "voces", "animalia", "topos", "lineas_tts.tsv")
    os.makedirs(os.path.dirname(ruta_tsv), exist_ok=True)
    with open(ruta_tsv, "w", encoding="utf-8") as f:
        f.write(guion())
    print("20 niveles y el guion de voces escritos.")


if __name__ == "__main__":
    main()
