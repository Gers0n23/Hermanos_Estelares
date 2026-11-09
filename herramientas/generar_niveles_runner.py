#!/usr/bin/env python3
"""Genera los niveles de la «Carrera de Toby» (motor runner) del Planeta Animalia.

Fuentes: docs/fichas/motor-runner.md §8 y §11, docs/fichas/planeta-animalia-zonas.md §4.4 y §8, y la
política de derrota del PO del 05-Nov-2026 (todos los perfiles pueden perder; corazones: Semilla 3,
Brote 2, Estrella 1; regalo tras 2/2/3 derrotas; ayuda fuerte de Maxi tras 3).

Escribe datos/niveles/animalia/<zona>/runner_<perfil>.json (15), el reto dorado de Sofía en la zona 5
(runner_estrella_dorado.json) y un nivel de equipo (carrera de postas) por zona (runner_equipo.json).

Uso: python3 herramientas/generar_niveles_runner.py
Los umbrales de estrellitas salen de herramientas/qa_test_runner.gd (bot perfecto, ver UMBRALES abajo).
"""
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOZ = "voces/animalia/runner/"

ZONAS = [
    ("zona1_campamento", "campamento"),
    ("zona2_laguna", "laguna"),
    ("zona3_pradera", "pradera"),
    ("zona4_nidos", "nidos"),
    ("zona5_valle", "valle"),
]

# Catálogo de obstáculos: tamaño del dibujo [ancho, alto] en px. La caja de choque es 70 % × 80 %.
SUELO = {
    "hojas": [90, 50], "arbusto": [90, 70], "charquito": [100, 30], "tronco_goma": [90, 55],
    "arbusto_florido": [90, 70], "fardo": [80, 70], "cono": [60, 70], "manguera": [90, 45],
    "tronco": [90, 60], "piedra": [70, 55], "cerca_flores": [80, 65], "charco": [110, 30],
    "nenufar": [90, 35], "raiz": [100, 50], "hongo": [75, 65], "hongo_gigante": [85, 75],
    "caja": [75, 75], "hueso_juguete": [90, 40], "roca_esponja": [80, 60],
}
# Aéreos: "altura" = borde de abajo del dibujo sobre el suelo. Alto: pasa por arriba si no saltas
# (caja desde 141 px, más alta que la caja de cualquier corredor en el suelo); bajo: hay que saltarlo.
AEREO = {
    "pajarito_alto": ("pajarito", [70, 60], "aereo_alto", 135),
    "globo_alto": ("globo", [60, 60], "aereo_alto", 135),
    "gaviota_alta": ("gaviota", [80, 60], "aereo_alto", 135),
    "cometa_alta": ("cometa_papel", [70, 60], "aereo_alto", 135),
    "loro_alto": ("loro", [70, 60], "aereo_alto", 135),
    "lechucita_alta": ("lechucita", [70, 60], "aereo_alto", 135),
    "pajarito_bajo": ("pajarito", [70, 55], "aereo_bajo", 30),
    "globo_bajo": ("globo", [60, 55], "aereo_bajo", 30),
    "pez_bajo": ("pez", [70, 55], "aereo_bajo", 30),
    "hoja_baja": ("hoja", [70, 55], "aereo_bajo", 30),
    "estrellita_baja": ("estrellita", [65, 55], "aereo_bajo", 30),
}


def suelo(*ids):
    return [{"id": i, "dibujo": i, "tamano": SUELO[i], "tipo": "suelo"} for i in ids]


def aereo(*ids):
    lista = []
    for i in ids:
        dibujo, tam, tipo, altura = AEREO[i]
        lista.append({"id": i, "dibujo": dibujo, "tamano": tam, "tipo": tipo, "altura": altura})
    return lista


# --- Temas por zona y hermano (planeta-animalia-zonas.md §4.4) ---
TEMAS = {
    "semilla": [
        {"corredor": "trex", "obst": suelo("hojas", "arbusto"), "aer": [], "items": ["huevito"], "meta": "carpa",
         "tema": "Corre el T-rex por el campamento: montoncitos de hojas y arbustos; huevitos; la carpa de Toby revienta en confeti"},
        {"corredor": "spino", "obst": suelo("charquito", "tronco_goma"), "aer": [], "items": ["huevito"], "meta": "muelle",
         "tema": "Corre el spinosaurio por la laguna: cada charquito salpica; meta: el muelle"},
        {"corredor": "carno", "obst": suelo("arbusto_florido", "fardo"), "aer": [], "items": ["huevito"], "meta": "acacia",
         "tema": "Corre el carnotauro por la pradera: arbustos floridos y fardos; meta: la acacia"},
        {"corredor": "trex_bombero", "obst": suelo("cono", "manguera"), "aer": [], "items": ["gotita"], "meta": "cuartel",
         "tema": "¡T-rex bombero! Casco rojo y '¡uiu!' en cada salto; conos blanditos y mangueras; gotitas; el cuartel tira un chorro arcoiris"},
        {"corredor": "tres_dinos", "obst": suelo("hojas", "arbusto", "tronco_goma"), "aer": [], "items": ["huevito"], "meta": "volcan",
         "tema": "Los tres dinos en fila (T-rex, spinosaurio y carnotauro) saltan en cadena con un toque; meta: el volcan de confeti"},
    ],
    "brote": [
        {"corredor": "pony", "obst": suelo("tronco", "piedra", "cerca_flores"), "aer": [], "items": ["manzanita", "corazon"], "meta": "establo",
         "tema": "Corre un pony rosado: troncos, piedras redondas y cerquitas de flores; manzanitas y corazones; meta: el establo"},
        {"corredor": "pony", "obst": suelo("charco", "nenufar", "piedra"), "aer": [], "items": ["manzanita", "corazon"], "meta": "muelle",
         "tema": "El pony corre por la orilla: charcos y nenufares; meta: el muelle"},
        {"corredor": "jirafa", "obst": suelo("tronco", "piedra"), "aer": aereo("pajarito_alto"), "items": ["manzanita", "corazon"], "meta": "acacia",
         "tema": "Corre la jirafa: primeros pajaritos altos, que pasan por arriba si no salta (agacha el cuello); meta: la acacia"},
        {"corredor": "gatito", "obst": suelo("raiz", "hongo"), "aer": aereo("pajarito_alto"), "items": ["manzanita", "corazon"], "meta": "arbol_nidos",
         "tema": "Corre un gatito: raices y hongos; pajaritos altos; meta: el arbol de los nidos"},
        {"corredor": "pony_estelar", "obst": suelo("piedra", "tronco", "hongo"), "aer": aereo("pajarito_alto", "globo_bajo"), "items": ["manzanita", "corazon"], "meta": "arcoiris",
         "tema": "Corre el pony estelar con estela de estrellas: altos y bajos; meta: el arcoiris del valle"},
    ],
    "estrella": [
        {"corredor": "toby", "obst": suelo("tronco", "caja", "piedra"), "aer": aereo("globo_alto", "globo_bajo"), "items": ["huesito"], "meta": "carpa",
         "tema": "Toby corre por su campamento: troncos y cajas de exploracion; globos desde los 40 s; huesitos; meta: su carpa"},
        {"corredor": "toby", "obst": suelo("charco", "nenufar", "tronco"), "aer": aereo("gaviota_alta", "pez_bajo"), "items": ["huesito"], "meta": "muelle",
         "tema": "Charcos y nenufares; peces que saltan del agua (bajos) y gaviotas (altas) desde los 40 s"},
        {"corredor": "toby", "obst": suelo("tronco", "piedra", "fardo"), "aer": aereo("pajarito_alto", "cometa_alta", "pajarito_bajo"), "items": ["huesito"], "meta": "acacia",
         "tema": "Altos y bajos desde el inicio: pajaritos y cometas de papel; grupos de 2"},
        {"corredor": "toby", "obst": suelo("raiz", "hongo_gigante", "tronco"), "aer": aereo("loro_alto", "hoja_baja"), "items": ["huesito"], "meta": "arbol_nidos",
         "tema": "Raices, hongos gigantes, loros (altos) y hojas que caen (bajas); grupos de 3; salto variable opcional (mantener = mas alto)"},
        {"corredor": "toby", "obst": suelo("hueso_juguete", "roca_esponja", "tronco"), "aer": aereo("lechucita_alta", "estrellita_baja"), "items": ["huesito"], "meta": "volcan",
         "tema": "La carrera de noche: el atardecer llega a la mitad y se corre bajo estrellas fugaces; huesos de juguete y rocas de esponja"},
    ],
}

# --- Parámetros por perfil (planeta-animalia-zonas.md §4.4 + política del PO 05-Nov-2026) ---
PARAMS = {
    "semilla": {
        "velocidad": [240] * 5, "velocidad_max": [240] * 5, "segundos_a_max": [None] * 5,
        "min_s": [5.0] * 5, "grupo_max": [1] * 5, "meta_s": [40, 40, 42, 42, 44],
        "aereos": [None] * 5, "atardecer_en": [0.7] * 5,
    },
    "brote": {
        "velocidad": [400, 410, 425, 440, 450], "velocidad_max": [620, 640, 660, 680, 700], "segundos_a_max": [120] * 5,
        "min_s": [2.2, 2.1, 2.15, 2.1, 1.9], "grupo_max": [1, 1, 2, 1, 2], "meta_s": [40, 42, 40, 42, 42],
        "aereos": [None, None, {"desde_s": 0, "tipos": ["aereo_alto"], "p": 0.08},
                   {"desde_s": 0, "tipos": ["aereo_alto"], "p": 0.08},
                   {"desde_s": 0, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.1}],
        "atardecer_en": [0.7] * 5,
    },
    "estrella": {
        "velocidad": [560, 575, 590, 605, 620], "velocidad_max": [1000, 1025, 1050, 1075, 1100],
        "segundos_a_max": [120, 115, 110, 105, 100],
        "min_s": [1.2, 1.15, 1.05, 1.1, 0.95], "grupo_max": [2, 2, 2, 2, 3], "meta_s": [30, 32, 32, 33, 34],
        "aereos": [{"desde_s": 15, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.15},
                   {"desde_s": 15, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.15},
                   {"desde_s": 0, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.16},
                   {"desde_s": 0, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.18},
                   {"desde_s": 0, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.2}],
        "atardecer_en": [0.7, 0.7, 0.7, 0.7, 0.5],
    },
}

# Margen humano de la ventana de salto de un GRUPO (calibrado con el jugador simulado, ver qa_test_runner.gd).
MARGEN_GRUPO = {"semilla": 0.1, "brote": 0.32, "estrella": 0.26}

SALTO = {
    "semilla": {"duracion_s": 1.0, "altura": 250, "impulso_s": 0.06, "imantado_s": 2.0, "imantado_max_s": 1.6,
                "amable_px": 0, "en_cola_ms": 150, "variable": None},
    "brote": {"duracion_s": 0.8, "altura": 210, "impulso_s": 0.05, "imantado_s": 0, "imantado_max_s": 0,
              "amable_px": 12, "en_cola_ms": 150, "variable": None},
    "estrella": {"duracion_s": 0.62, "altura": 185, "impulso_s": 0.04, "imantado_s": 0, "imantado_max_s": 0,
                 "amable_px": 0, "en_cola_ms": 150, "variable": None},
}
VARIABLE = {"extra": 0.35, "desde_s": 0.12, "tope_s": 0.25}

CORREDOR = {
    "trex": {"alto": 170, "ancho": 130, "caja": [0.6, 0.75]},
    "spino": {"alto": 170, "ancho": 130, "caja": [0.6, 0.75]},
    "carno": {"alto": 170, "ancho": 130, "caja": [0.6, 0.75]},
    "trex_bombero": {"alto": 170, "ancho": 130, "caja": [0.6, 0.75]},
    "tres_dinos": {"alto": 170, "ancho": 130, "caja": [0.6, 0.75]},
    "pony": {"alto": 160, "ancho": 130, "caja": [0.6, 0.75]},
    "pony_estelar": {"alto": 160, "ancho": 130, "caja": [0.6, 0.75]},
    # La jirafa es alta: su caja es solo el cuerpo (agacha el cuello cuando pasa un aéreo alto).
    "jirafa": {"alto": 200, "ancho": 130, "caja": [0.6, 0.6]},
    "gatito": {"alto": 150, "ancho": 120, "caja": [0.6, 0.75]},
    "toby": {"alto": 150, "ancho": 120, "caja": [0.6, 0.75]},
}

POLITICA = {
    # docs/fichas/motor-runner.md [HE-124] y GDD §6 regla 11 (05-Nov-2026).
    "semilla": {"corazones": 3, "regalo_tras_derrotas": 2, "regalo": {"tipo": "corazon_extra", "corazones": 1},
                "ayuda_fuerte_tras_derrotas": {"derrotas": 3, "obstaculos_blandos": True},
                "descanso_tras_derrotas": None, "burbuja": None, "banderita_mitad": True,
                "tramo_record_s": None, "mostrar_puntaje": "no", "ayuda_idle_s": [5, 12], "inicio_libre_s": 3.0,
                "gag_s": 1.5},
    "brote": {"corazones": 2, "regalo_tras_derrotas": 2, "regalo": {"tipo": "burbuja"},
              "ayuda_fuerte_tras_derrotas": None, "descanso_tras_derrotas": 3,
              "burbuja": None, "banderita_mitad": True,
              "tramo_record_s": 45, "mostrar_puntaje": "barra", "ayuda_idle_s": None, "inicio_libre_s": 3.0,
              "gag_s": 2.5},
    "estrella": {"corazones": 1, "regalo_tras_derrotas": 3, "regalo": {"tipo": "burbuja", "banderita_mitad": True},
                 "ayuda_fuerte_tras_derrotas": None, "descanso_tras_derrotas": 4,
                 "burbuja": {"inicial": False, "cada_s": 55, "invulnerable_s": 1.0}, "banderita_mitad": False,
                 "tramo_record_s": 90, "mostrar_puntaje": "numero", "ayuda_idle_s": None, "inicio_libre_s": 2.5,
                 "gag_s": 2.5},
}
BURBUJA_ESTRELLA_CADA = [25, 25, 25, 25, 25]

# Umbrales de estrellitas (puntaje AL CRUZAR LA META; el tramo del récord solo cuenta para el récord).
# Calibrados con el bot perfecto del arnés (puntaje "perfecto" P en la meta, semilla 1..20):
# dos = ~70 % de P, tres = ~88 % de P. Ver herramientas/qa_test_runner.gd, sección "Calibración".
UMBRALES = {
    "brote": [None] * 5,
    "estrella": [None] * 5,
}
UMBRALES_PATH = os.path.join(RAIZ, "herramientas", "runner_umbrales.json")

ZONA_NOMBRE = ["el Campamento de Toby", "la Laguna de los Nenufares", "la Pradera de las Jirafas",
               "el Arbol de los Nidos", "el Valle de los Dinosaurios"]


def lineas_voz(perfil, z, corredor):
    n = z + 1
    lv = {
        "intro": VOZ + f"intro_{perfil}_z{n}.wav",
        "largada": VOZ + "largada.wav",
        "meta": [VOZ + "meta_01.wav", VOZ + "meta_02.wav"] if perfil != "semilla" else [VOZ + "meta_maxi_01.wav", VOZ + "meta_maxi_02.wav"],
        "derrota_gag": ([VOZ + "hojas_maxi_01.wav", VOZ + "hojas_maxi_02.wav"] if perfil == "semilla"
                        else [VOZ + f"al_barro_z{n}.wav", VOZ + "al_barro_01.wav", VOZ + "al_barro_02.wav"]),
        "regalo": VOZ + {"semilla": "regalo_corazon.wav", "brote": "regalo_burbuja.wav", "estrella": "regalo_burbuja_sofia.wav"}[perfil],
        "descansar": VOZ + "descansar.wav",
        "victoria": VOZ + f"victoria_{perfil}.wav",
        "burbuja_presenta": VOZ + "burbuja_presenta.wav",
    }
    lv["corazon_menos"] = [VOZ + "uy_01.wav", VOZ + "uy_02.wav"]
    if perfil == "semilla":
        lv["ayuda_fuerte"] = VOZ + "ayuda_fuerte_maxi.wav"
        lv["mitad"] = VOZ + "banderita_mitad_maxi.wav"
        lv.pop("descansar")
    else:
        lv["sigue_record"] = VOZ + "sigue_record.wav"
        lv["final_sendero"] = VOZ + "final_sendero.wav"
        lv["record"] = VOZ + "record.wav"
        lv["primer_record"] = VOZ + "primer_record.wav"
        lv["aereo_presenta"] = VOZ + ("aereo_presenta_jirafa.wav" if corredor == "jirafa" else "aereo_presenta.wav")
    if perfil == "brote":
        lv["mitad"] = VOZ + "banderita_mitad.wav"
    return lv


def nivel(perfil, z, umbrales):
    zona_id, escenario = ZONAS[z]
    tema = TEMAS[perfil][z]
    p = PARAMS[perfil]
    pol = POLITICA[perfil]
    salto = dict(SALTO[perfil])
    if perfil == "estrella" and z >= 3:
        salto["variable"] = dict(VARIABLE)
    burbuja = dict(pol["burbuja"]) if pol["burbuja"] else None
    if perfil == "estrella":
        burbuja["cada_s"] = BURBUJA_ESTRELLA_CADA[z]
    corredor = dict(CORREDOR[tema["corredor"]])
    corredor["id"] = tema["corredor"]
    d = {
        "id_nivel": f"animalia_z{z + 1}_runner_{perfil}",
        "motor": "runner",
        "perfil": perfil,
        "planeta": "animalia",
        "zona": zona_id,
        "tema": tema["tema"],
        "nota": ("dev-godot HE-119 (05-Nov-2026): generado por herramientas/generar_niveles_runner.py. Numeros de "
                 "planeta-animalia-zonas.md §4.4 y de motor-runner.md [HE-124] (politica de derrota del PO del "
                 "05-Nov-2026: corazones, regalo, ayuda fuerte, descanso). PROVISIONAL hasta la maqueta HE-110 y el playtest."),
        "escenario": {"id": escenario, "noche": perfil == "estrella" and z == 4},
        "fondo": {"parallax": [0.2, 0.5, 1.0], "atardecer_en": p["atardecer_en"][z]},
        "corredor": corredor,
        "obstaculos": tema["obst"] + tema["aer"],
        "caja_obstaculo": [0.7, 0.8],
        "coleccionables": {"ids": tema["items"], "puntos": 25, "radio": 22, "cada_s": [3, 6]},
        "meta": {"dibujo": tema["meta"]},
        "velocidad": p["velocidad"][z],
        "velocidad_max": p["velocidad_max"][z],
        "segundos_a_max": p["segundos_a_max"][z],
        "inicio_libre_s": pol["inicio_libre_s"],
        "salto": salto,
        "huecos": {"min_s": p["min_s"][z], "factor_max": 1.5, "grupo_max": p["grupo_max"][z], "repetidos_max": 2,
                   "margen_ventana_s": MARGEN_GRUPO[perfil]},
        "aereos": p["aereos"][z],
        "obstaculos_blandos": False,
        "corazones": pol["corazones"],
        "invulnerable_golpe_s": 1.0,
        "burbuja": burbuja,
        "meta_s": p["meta_s"][z],
        "tramo_record_s": pol["tramo_record_s"],
        "banderita_mitad": pol["banderita_mitad"],
        "regalo_tras_derrotas": pol["regalo_tras_derrotas"],
        "regalo": pol["regalo"],
        "ayuda_fuerte_tras_derrotas": pol["ayuda_fuerte_tras_derrotas"],
        "descanso_tras_derrotas": pol["descanso_tras_derrotas"],
        "gag_derrota_s": pol["gag_s"],
        "puntos": {"por_segundo": 10, "racha_saltos": 5, "racha": 50, "meta": 200, "final": 300},
        "hito_cada": 100,
        "mostrar_puntaje": pol["mostrar_puntaje"],
        "ayuda_idle_s": pol["ayuda_idle_s"],
        "lineas_voz": lineas_voz(perfil, z, tema["corredor"]),
    }
    if perfil in umbrales and umbrales[perfil][z] is not None:
        d["umbrales_puntaje"] = umbrales[perfil][z]
    return d


def dorado(umbrales):
    d = nivel("estrella", 4, umbrales)
    d.update({
        "id_nivel": "animalia_z5_runner_estrella_dorado",
        "tema": "Reto dorado 'Sendero sin fin' (planeta-animalia-zonas.md §6.2): el dinosaurio de Chrome puro. De 620 a 1150 px/s en 100 s, una sola burbuja inicial, grupos de 3, altos y bajos. Se completa al aguantar 150 s: aparece una aurora austral. Despues sigue sin fin por el record.",
        "velocidad": 620, "velocidad_max": 1150, "segundos_a_max": 100,
        "burbuja": {"inicial": True, "cada_s": None, "invulnerable_s": 1.0},
        "regalo": {"tipo": "burbuja"},
        "meta_s": 150, "tramo_record_s": -1,
        "huecos": {"min_s": 0.95, "factor_max": 1.5, "grupo_max": 3, "repetidos_max": 2},
        "meta": {"dibujo": "aurora"},
        "dorado": True,
    })
    d["fondo"]["atardecer_en"] = 0.2
    d["lineas_voz"]["meta"] = [VOZ + "aurora.wav"]
    d["lineas_voz"]["intro"] = VOZ + "intro_dorado.wav"
    d["lineas_voz"].pop("final_sendero", None)
    d.pop("umbrales_puntaje", None)
    if "dorado" in umbrales:
        d["umbrales_puntaje"] = umbrales["dorado"]
    return d


def perfil_equipo(perfil, z):
    """Capa de un perfil para la carrera de postas (motor-runner.md §12.2)."""
    tema = TEMAS[perfil][z]
    p = PARAMS[perfil]
    salto = dict(SALTO[perfil])
    corredor = dict(CORREDOR[tema["corredor"]])
    corredor["id"] = tema["corredor"]
    return {
        "corredor": corredor,
        "obstaculos": tema["obst"] + tema["aer"],
        "velocidad": p["velocidad"][z],
        "velocidad_max": p["velocidad"][z] + (0 if perfil == "semilla" else 60),
        "segundos_a_max": None if perfil == "semilla" else 30,
        "inicio_libre_s": 1.5,
        "salto": salto,
        "huecos": {"min_s": p["min_s"][z], "factor_max": 1.5, "grupo_max": p["grupo_max"][z], "repetidos_max": 2},
        "aereos": p["aereos"][z] if p["aereos"][z] is None else dict(p["aereos"][z], desde_s=0),
        # Maxi: su capa de Semilla (obstáculos blandos y salto imantado), §12.2.
        "obstaculos_blandos": perfil == "semilla",
        "coleccionables": {"ids": tema["items"], "puntos": 0, "radio": 22, "cada_s": [3, 6]},
    }


NUCLEO = "voces/nucleo/equipo/"


def equipo(z):
    zona_id, escenario = ZONAS[z]
    return {
        "id_nivel": f"animalia_z{z + 1}_runner_equipo",
        "motor": "runner",
        "modo_juego": "equipo",
        "perfil": "semilla",
        "planeta": "animalia",
        "zona": zona_id,
        "tema": f"Carrera de postas en {ZONA_NOMBRE[z]}: una sola carrera hasta la meta compartida; cada turno es un tramo y la posta (un huesito dorado) pasa al corredor del siguiente hermano (motor-runner.md §12.2)",
        "nota": ("dev-godot HE-119 (05-Nov-2026): PROVISIONAL. Tope por turno = obstaculos pasados limpios (semilla 2, "
                 "brote 5, estrella 8). La meta del equipo son `obstaculos_meta` pasos limpios en total. Choque sin "
                 "burbuja = fallo que corta el turno. Sin puntaje, sin burbuja y sin corazones en equipo. "
                 "planeta-animalia-zonas.md §8 solo pide equipo en ¿Quien habla?: estos niveles quedan listos para "
                 "cuando el PO quiera sumar la Carrera al modo equipo o a la batalla (HE-115)."),
        "escenario": {"id": escenario, "noche": False},
        "fondo": {"parallax": [0.2, 0.5, 1.0], "atardecer_en": 0.7},
        "corredor": dict(CORREDOR["toby"], id="toby"),
        "obstaculos": TEMAS["estrella"][z]["obst"],
        "caja_obstaculo": [0.7, 0.8],
        "velocidad": 400, "salto": SALTO["brote"],
        "huecos": {"min_s": 1.6, "factor_max": 1.5, "grupo_max": 1, "repetidos_max": 2},
        "meta": {"dibujo": TEMAS["estrella"][z]["meta"]},
        "equipo": {
            "rival": "coleccionauta",
            "orden": "maxi_intercalado",
            "puerta_tras_semilla": "arrastre",
            "bloqueo_tras_puerta_ms": 400,
            "maxi_mueve_rival": False,
            "semilla_auto_s": 20,
            "aciertos_max_turno": {"semilla": 2, "brote": 5, "estrella": 8},
            "composiciones": {
                "maxi+nicole+sofia": {"pasos_rival": 6, "obstaculos_meta": 30},
                "maxi+nicole": {"pasos_rival": 6, "obstaculos_meta": 21},
                "maxi+sofia": {"pasos_rival": 5, "obstaculos_meta": 24},
                "nicole+sofia": {"pasos_rival": 5, "obstaculos_meta": 32},
            },
            "perfiles": {pf: perfil_equipo(pf, z) for pf in ("semilla", "brote", "estrella")},
        },
        "lineas_voz": {
            "intro_ronda": VOZ + "equipo_intro.wav",
            "posta": VOZ + "equipo_posta.wav",
            "maxi_regalito": VOZ + "equipo_maxi_regalito.wav",
            "derrota_gag_equipo": [VOZ + "equipo_gag_01.wav", VOZ + "equipo_gag_02.wav", VOZ + "equipo_gag_03.wav"],
            "logro_comun": {str(k): VOZ + f"equipo_logro_{k:02d}.wav" for k in range(1, 7)},
            "nos_alcanzo": NUCLEO + "nos_alcanzo.wav",
            "victoria_equipo": VOZ + "equipo_victoria.wav",
            "le_toca": {
                "maxi": [NUCLEO + "le_toca_maxi_01.wav", NUCLEO + "le_toca_maxi_02.wav", NUCLEO + "le_toca_maxi_03.wav"],
                "nicole": [NUCLEO + "le_toca_nicole_01.wav", NUCLEO + "le_toca_nicole_02.wav", NUCLEO + "le_toca_nicole_03.wav"],
                "sofia": [NUCLEO + "le_toca_sofia_01.wav", NUCLEO + "le_toca_sofia_02.wav", NUCLEO + "le_toca_sofia_03.wav"],
            },
            "te_toca_recordatorio": {h: NUCLEO + f"te_toca_{h}.wav" for h in ("maxi", "nicole", "sofia")},
            "te_toca_recordatorio_ventanita": {h: NUCLEO + f"te_toca_{h}_ventanita.wav" for h in ("nicole", "sofia")},
            "sube_ventanita": {h: NUCLEO + f"sube_ventanita_{h}.wav" for h in ("nicole", "sofia")},
            "maxi_ayuda": NUCLEO + "maxi_ayuda.wav",
            "animo_hermanos": {
                "maxi": [NUCLEO + "animo_maxi_01.wav", NUCLEO + "animo_maxi_02.wav"],
                "nicole": [NUCLEO + "animo_nicole_01.wav", NUCLEO + "animo_nicole_02.wav"],
                "sofia": [NUCLEO + "animo_sofia_01.wav", NUCLEO + "animo_sofia_02.wav"],
            },
            "rival_avanza": [NUCLEO + f"coleccionauta/avanza_0{k}.wav" for k in range(1, 5)],
            "rival_embobado": [NUCLEO + f"coleccionauta/embobado_0{k}.wav" for k in range(1, 4)],
            "rival_retrocede": [NUCLEO + "coleccionauta/retrocede_01.wav", NUCLEO + "coleccionauta/retrocede_02.wav"],
            "rival_vuelve": NUCLEO + "coleccionauta/vuelve.wav",
        },
    }


def escribir(ruta, datos):
    ruta = os.path.join(RAIZ, ruta)
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main():
    umbrales = dict(UMBRALES)
    if os.path.exists(UMBRALES_PATH):
        with open(UMBRALES_PATH, encoding="utf-8") as f:
            umbrales.update(json.load(f))
    n = 0
    for z, (zona_id, _) in enumerate(ZONAS):
        for perfil in ("semilla", "brote", "estrella"):
            escribir(f"datos/niveles/animalia/{zona_id}/runner_{perfil}.json", nivel(perfil, z, umbrales))
            n += 1
        escribir(f"datos/niveles/animalia/{zona_id}/runner_equipo.json", equipo(z))
        n += 1
    escribir("datos/niveles/animalia/zona5_valle/runner_estrella_dorado.json", dorado(umbrales))
    n += 1
    print(f"{n} niveles escritos")


if __name__ == "__main__":
    main()
