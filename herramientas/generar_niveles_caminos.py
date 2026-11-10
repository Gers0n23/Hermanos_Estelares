"""Genera los niveles de «Cada quien a su casa» (motor caminos, tipo Flow Free) del Planeta Animalia.

Fuentes: docs/fichas/motor-caminos.md (§4, §8, §9, §10, §11) y docs/fichas/planeta-animalia-zonas.md §4.2,
§8 y §9, con la POLÍTICA DE DERROTA del PO del 05-Nov-2026 (todos pueden perder; tormenta 3x / 2,2x / 1,6x
el tiempo par; regalo tras 2 / 2 / 3 derrotas; ayuda fuerte de Maxi tras 3).

Los tableros NO se inventan al jugar (regla 4 de la ficha): se fabrican aquí una sola vez, con semilla fija,
y quedan escritos en el JSON junto con su `solucion`. Cada tablero se valida con `solver_caminos.py`:
- con `llenar`: solución ÚNICA que cubre todas las celdas (y las dos direcciones de cada puente);
- sin `llenar` (Maxi, Nicole z1-z2 y equipo): la solución guardada es la de menor largo total y se exige que
  esa mínima sea única (lo que dibujan la guía, el regalo y la mano fantasma).

Cómo se fabrica un tablero con llenado: camino hamiltoniano aleatorio (movimientos "backbite") cortado en
tramos de 3+ celdas; los puentes se crean uniendo dos tramos a través de una celda donde otro tramo pasa
recto; las rocas recortan una punta de un tramo. Se reintenta hasta que el solver confirma la unicidad.

Uso:  python3 herramientas/generar_niveles_caminos.py      (reescribe datos/niveles/animalia/*/caminos_*.json)
"""

from __future__ import annotations

import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solver_caminos import Tablero, a_xy, contar_soluciones, solucion_minima, validar_solucion  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LETRAS = "ABCDEFGHI"

# Colores de los caminos (uno por par, en orden). Distintos entre sí también para daltonismo leve: además del
# color, cada animal deja su propia huella.
COLORES = ["#E8434B", "#3D7BE0", "#36B866", "#FFC83A", "#FF8A3D", "#9B5DE5", "#FF7EB6", "#5CC8F0", "#A0673F"]

ZONAS = {
    1: ("zona1_campamento", "#BFE59A", "#8CCB6A"),
    2: ("zona2_laguna", "#B9E6E0", "#7CC8C0"),
    3: ("zona3_pradera", "#F3E6A0", "#D9C46A"),
    4: ("zona4_nidos", "#A9DB9A", "#5FAE5A"),
    5: ("zona5_valle", "#E8D2B8", "#C49A74"),
}

# ---------------------------------------------------------------------------------------------------------
# Catálogo de animales: parámetros del dibujo vectorial procedural (scripts/motores/caminos/dibujo_caminos.gd)
# cuerpo / detalle / oscuro, forma de cabeza, orejas, hocico, extras, huella y tono de su "voz" provisional.
# ---------------------------------------------------------------------------------------------------------


def A(nombre, cuerpo, detalle, oscuro, cabeza, orejas, hocico, extras, huella, tono=1.0):
    return {"nombre": nombre, "huella": huella, "tono": tono,
            "dibujo": {"cuerpo": cuerpo, "detalle": detalle, "oscuro": oscuro, "cabeza": cabeza,
                       "orejas": orejas, "hocico": hocico, "extras": extras}}


ANIMALES = {
    "perro": A("perro", "#C98A4B", "#F6E3C6", "#7A4A26", "redonda", "caidas", "nariz", ["mancha_ojo"], "pata", 1.0),
    "perrito": A("perrito", "#E3AA6A", "#FFF1DD", "#8A5530", "redonda", "caidas", "nariz", ["mejillas"], "pata", 1.25),
    "perrito_bombero": A("perrito bombero", "#FFFFFF", "#F4F4F4", "#2B2B2B", "redonda", "caidas", "nariz",
                         ["manchas", "casco_bombero"], "pata", 1.2),
    "vaca": A("vaca", "#FFFFFF", "#F7B7C4", "#3A3A3A", "ancha", "laterales", "morro", ["manchas", "cuernos"], "pezuna", 0.7),
    "pato": A("pato", "#FFD84A", "#FF9F2E", "#C98A10", "redonda", "ninguna", "pico_pato", ["penacho"], "pato", 1.3),
    "patito": A("patito", "#FFE36B", "#FF9F2E", "#D9A410", "redonda", "ninguna", "pico_pato", ["penacho", "mejillas"], "pato", 1.5),
    "gato": A("gato", "#F2A65A", "#FFE7CC", "#C9742E", "redonda", "punta", "nariz", ["rayas", "bigotes"], "pata", 1.1),
    "gatito": A("gatito", "#C8C0D8", "#FFF4FA", "#8E86A8", "redonda", "punta", "nariz", ["bigotes", "mejillas", "lazo"], "pata", 1.4),
    "gallina": A("gallina", "#FFFFFF", "#FFB52E", "#E8434B", "redonda", "ninguna", "pico", ["cresta"], "ave", 1.2),
    "pollito": A("pollito", "#FFE14D", "#FF9F2E", "#E0B020", "redonda", "ninguna", "pico", ["penacho", "mejillas"], "ave", 1.6),
    "tortuga": A("tortuga", "#9BD45E", "#D8EFA0", "#4E7D2B", "redonda", "ninguna", "nariz", ["caparazon"], "pata", 0.8),
    "hipopotamo": A("hipopótamo", "#A99BC8", "#E2C2DC", "#6E6090", "ancha", "pequenas", "morro", [], "pezuna", 0.6),
    "caballo": A("caballo", "#A86B3C", "#E8C8A8", "#4A2E1E", "alargada", "caballo", "morro", ["melena"], "pezuna", 0.9),
    "pony": A("pony", "#FFC4DD", "#FFF0F6", "#B565D8", "alargada", "caballo", "morro", ["melena", "flequillo"], "pezuna", 1.2),
    "pony_estelar": A("pony estelar", "#E9E4FF", "#FFFFFF", "#5A6CF0", "alargada", "caballo", "morro",
                      ["melena", "flequillo", "estrellas"], "pezuna", 1.3),
    "elefante": A("elefante", "#A9B4C2", "#D7DEE7", "#7A8696", "ancha", "grandes", "trompa", [], "pezuna", 0.6),
    "jirafa": A("jirafa", "#F6C35B", "#FFE7A8", "#B9772E", "alargada", "laterales", "morro", ["osiconos", "manchas"], "pezuna", 0.9),
    "jirafita": A("jirafita", "#FAD27A", "#FFF0C4", "#C98A3E", "alargada", "laterales", "morro",
                  ["osiconos", "manchas", "mejillas"], "pezuna", 1.4),
    "cebra": A("cebra", "#FFFFFF", "#E2E2E2", "#2B2B2B", "alargada", "caballo", "morro", ["rayas", "melena"], "pezuna", 1.0),
    "flamenco": A("flamenco", "#FF8FB1", "#FFD0DE", "#2B2B2B", "redonda", "ninguna", "pico_curvo", ["mejillas"], "ave", 1.3),
    "cisne": A("cisne", "#FFFFFF", "#FF9F2E", "#2B2B2B", "redonda", "ninguna", "pico", ["antifaz_pico"], "pato", 1.1),
    "cisne_cuello_negro": A("cisne de cuello negro", "#2B2B2B", "#C9CDD6", "#E8434B", "redonda", "ninguna", "pico",
                            ["carúncula", "mejilla_blanca"], "pato", 1.0),
    "mono": A("mono", "#A0673F", "#F2D3B0", "#6E4126", "redonda", "redondas", "nariz", ["cara_mono"], "pata", 1.3),
    "loro": A("loro", "#36B866", "#FFD84A", "#E8434B", "redonda", "ninguna", "pico_curvo", ["cresta"], "ave", 1.5),
    "buho": A("búho", "#A07850", "#F2E0C0", "#6E4E30", "redonda", "punta", "pico", ["ojos_grandes"], "plumita", 0.8),
    "perezoso": A("perezoso", "#B39B7C", "#E8DCC8", "#6E5A44", "redonda", "ninguna", "nariz", ["antifaz"], "pata", 0.7),
    "pinguino": A("pingüino de Humboldt", "#2B3350", "#FFFFFF", "#F28C8C", "redonda", "ninguna", "pico", ["cara_blanca"], "pato", 1.1),
    "lobo_marino": A("lobo marino", "#8A6E5A", "#C9B09A", "#4A3A2E", "redonda", "pequenas", "nariz", ["bigotes"], "aleta", 0.8),
    "oso_polar": A("oso polar", "#F4F4F0", "#E6E6DE", "#2B2B2B", "redonda", "redondas", "nariz", [], "pata", 0.7),
    "ballena": A("ballena", "#5C8FD6", "#DDEBFA", "#3A6AB0", "ancha", "ninguna", "sonrisa", ["chorro"], "burbuja", 0.5),
    "huillin": A("huillín", "#7A5236", "#D8BFA2", "#4A2E1E", "redonda", "pequenas", "nariz", ["bigotes"], "pata", 1.2),
    "gerbo": A("gerbo", "#E8B57E", "#FFF0DC", "#A8743E", "redonda", "redondas", "nariz", ["bigotes", "mejillas"], "pata", 1.6),
    "cuy": A("cuy", "#C98A4B", "#FFFFFF", "#7A4A26", "redonda", "pequenas", "nariz", ["mancha_blanca", "bigotes"], "pata", 1.5),
    "conejo": A("conejo", "#E9E2DA", "#FFC4D6", "#9A8E84", "redonda", "largas", "nariz", ["dientes"], "pata", 1.4),
    "huemul": A("huemul", "#9C7A55", "#E2CFB4", "#5A4028", "alargada", "punta", "morro", ["astas"], "pezuna", 0.9),
    "pudu": A("pudú", "#A0683A", "#E0B88A", "#5A3A1E", "redonda", "redondas", "nariz", ["cuernitos", "mejillas"], "pezuna", 1.3),
    "guanaco": A("guanaco", "#D49A5E", "#F2DCC0", "#8A8A8A", "alargada", "punta", "morro", ["cara_gris"], "pezuna", 1.0),
    "alpaca": A("alpaca", "#F3E3C3", "#FFF8EA", "#B8A07A", "alargada", "punta", "morro", ["copete"], "pezuna", 1.1),
    "condor": A("cóndor", "#2B2B2B", "#FFFFFF", "#D98A8A", "redonda", "ninguna", "pico_curvo", ["golilla", "cabeza_rosada"], "plumita", 0.8),
    "camello": A("camello", "#D9A35F", "#F0D2A4", "#9A6A34", "alargada", "pequenas", "morro", ["jorobita"], "pezuna", 0.8),
    "panda": A("panda", "#FFFFFF", "#FFFFFF", "#2B2B2B", "redonda", "redondas_oscuras", "nariz", ["antifaz_panda"], "pata", 1.0),
    "tucan": A("tucán", "#2B2B2B", "#FFFFFF", "#FF8A3D", "redonda", "ninguna", "pico_tucan", ["mejilla_blanca"], "plumita", 1.2),
    "tricahue": A("tricahue", "#4E8F3A", "#FFD84A", "#E8434B", "redonda", "ninguna", "pico_curvo", ["pecho_rojo"], "plumita", 1.3),
    "monito_del_monte": A("monito del monte", "#B08A6E", "#F2E2D2", "#3A2A20", "redonda", "redondas", "nariz",
                          ["antifaz", "ojos_grandes"], "pata", 1.6),
    "carpintero": A("carpintero negro", "#2B2B2B", "#F4F4F4", "#E8434B", "redonda", "ninguna", "pico", ["cresta"], "plumita", 1.1),
    "koala": A("koala", "#A9B0BA", "#E8ECF0", "#2B2B2B", "redonda", "grandes", "nariz_grande", [], "pata", 0.9),
    "castor": A("castor", "#8A5A36", "#D2A47C", "#5A3A1E", "redonda", "pequenas", "nariz", ["dientes"], "pata", 1.0),
    "milodon": A("milodón", "#8C6B4A", "#C8A882", "#5A4430", "ancha", "pequenas", "morro", ["pelaje"], "pata", 0.5),
    # Dinos de Maxi: redondos, sonrientes y torpes (planeta-animalia-zonas.md §3).
    "braquiosaurio": A("braquiosaurio", "#8FCB6A", "#D9F2B8", "#5E9C43", "dino", "ninguna", "dino", ["manchas", "cuello"], "dino", 0.6),
    "triceratops": A("triceratops", "#F2A04A", "#FFE0B0", "#C46F25", "dino", "ninguna", "pico_dino", ["volante", "cuernos_tri"], "dino", 0.8),
    "trex": A("T-rex", "#7BC86C", "#E8F5C8", "#4D9441", "dino", "ninguna", "dino", ["dientes_dino"], "dino", 0.5),
    "spinosaurio": A("spinosaurio", "#4FA3C7", "#CDEBF5", "#2E7395", "dino", "ninguna", "dino", ["vela"], "dino", 0.65),
    "carnotauro": A("carnotauro", "#E2725B", "#FFD2C2", "#B04A36", "dino", "ninguna", "dino", ["cuernitos"], "dino", 0.7),
    "huevito": A("huevito", "#FFF4DE", "#FFFFFF", "#7BC86C", "huevo", "ninguna", "ninguna", ["manchas", "grieta"], "dino", 1.8),
}


def C(nombre, tipo, color, color2="", variante=""):
    return {"nombre": nombre, "dibujo": {"tipo": tipo, "color": color, "color2": color2, "variante": variante}}


CASAS = {
    "casita_perro": C("la casita", "casita", "#E8434B", "#F6E3C6"),
    "cucha": C("la cucha", "casita", "#3D7BE0", "#F6E3C6"),
    "granero": C("el granero", "granero", "#C8463C", "#FFFFFF"),
    "establo": C("el establo", "establo", "#B5723E", "#F2D3A0"),
    "gallinero": C("el gallinero", "gallinero", "#E8A23A", "#FFF1C8"),
    "laguna": C("la laguna", "agua", "#5CC8F0", "#9BE07A", "laguna"),
    "laguna_rosada": C("la laguna rosada", "agua", "#FF9CC0", "#9BE07A", "laguna"),
    "canasto": C("el canasto", "canasto", "#D9A35F", "#FF9CC0"),
    "canasto_colgante": C("el canasto colgante", "canasto", "#C98A4B", "#8CCB6A", "colgante"),
    "cuartel": C("el cuartel de bomberos", "cuartel", "#E8434B", "#FFD84A"),
    "arena": C("la arena", "arena", "#F6D98A", "#5CC8F0", "playa"),
    "charco_barro": C("el charco de barro", "agua", "#9A6A44", "#7FBF5A", "barro"),
    "arboles_altos": C("los árboles altos", "arbol", "#4FA35A", "#8A5A36", "altos"),
    "pradera_flores": C("la pradera de flores", "pasto", "#8CCB6A", "#FF7EB6", "flores"),
    "rio": C("el río", "agua", "#4FA3E0", "#8CCB6A", "rio"),
    "volcan": C("el volcán", "montana", "#A0674A", "#FF8A3D", "volcan"),
    "cueva": C("la cueva", "cueva", "#9A8A7A", "#3A2E28"),
    "nido_mama_trex": C("el nido de mamá T-rex", "nido", "#C9A26A", "#7BC86C", "mama"),
    "pradera": C("la pradera", "pasto", "#8CCB6A", "#FFD84A", "pradera"),
    "nenufar": C("el nenúfar", "nenufar", "#4FB86A", "#FF9CC0"),
    "juncal": C("el juncal", "pasto", "#7FB86A", "#5CC8F0", "juncos"),
    "acacia": C("la acacia", "arbol", "#7DB04A", "#8A5A36", "acacia"),
    "mama_jirafa": C("mamá jirafa", "mama", "#F6C35B", "#FF7EB6", "jirafa"),
    "pasto_alto": C("el pasto alto", "pasto", "#B8C85A", "#8A9A3A", "alto"),
    "charca": C("la charca", "agua", "#6CB8E0", "#C9A26A", "charca"),
    "palmera": C("la palmera", "arbol", "#4FB86A", "#A0673F", "palmera"),
    "nido": C("el nido", "nido", "#B88A5A", "#8CCB6A"),
    "hueco_arbol": C("el hueco del árbol", "cueva", "#8A5A36", "#3A2418", "tronco"),
    "liana": C("la liana", "liana", "#4FA35A", "#2E7A3A"),
    "nube_estrellas": C("la nube de estrellas", "nube", "#F4F0FF", "#FFD84A"),
    # Hábitats de Sofía (casas neutras desde z2: sin el color del animal).
    "cojin": C("el cojín", "cojin", "#9B5DE5", "#FFD84A"),
    "castillito_carton": C("el castillito de cartón", "castillito", "#D2A06A", "#A0673F"),
    "casita_heno": C("la casita de heno", "casita", "#E8C35A", "#F6E3C6", "heno"),
    "madriguera": C("la madriguera", "cueva", "#8CCB6A", "#5A3A1E", "madriguera"),
    "roquerio": C("el roquerío", "montana", "#9AA3AE", "#4FA3E0", "roquerio"),
    "cueva_costa": C("la cueva de la costa", "cueva", "#C9B08A", "#2E3A4A", "costa"),
    "salar": C("el salar", "agua", "#F2F4F8", "#FF9CC0", "salar"),
    "humedal": C("el humedal", "agua", "#7CC0B8", "#7FB86A", "humedal"),
    "rio_bosque": C("el río del bosque", "agua", "#4FA3E0", "#2E7A3A", "rio_bosque"),
    "tempano": C("el témpano", "hielo", "#DDF3FF", "#4FA3E0"),
    "mar": C("el mar abierto", "agua", "#2E6FC0", "#DDEBFA", "mar"),
    "cordillera_nevada": C("la cordillera nevada", "montana", "#7A8AA0", "#FFFFFF", "nevada"),
    "bosque_lluvioso": C("el bosque lluvioso", "arbol", "#2E8A4A", "#5CC8F0", "lluvioso"),
    "estepa": C("la estepa patagónica", "pasto", "#D8C88A", "#A8B87A", "estepa"),
    "bofedal": C("el bofedal del altiplano", "agua", "#6CC0A8", "#C8E07A", "bofedal"),
    "cumbre": C("la cumbre", "montana", "#8A7A6A", "#FFFFFF", "cumbre"),
    "desierto": C("el desierto", "arena", "#F2C878", "#7FB86A", "desierto"),
    "bambu": C("el bambú", "bambu", "#7FC85A", "#4E8F3A"),
    "selva_tropical": C("la selva tropical", "arbol", "#2EA05A", "#FF7EB6", "selva"),
    "barranco": C("el barranco", "montana", "#C98A5A", "#8A5A36", "barranco"),
    "nido_musgo": C("el nido de musgo", "nido", "#6E9A4A", "#A8D07A", "musgo"),
    "tronco_roble": C("el tronco de roble", "cueva", "#7A5236", "#2E1E14", "roble"),
    "eucalipto": C("el eucalipto", "arbol", "#8AB8A0", "#B8A08A", "eucalipto"),
    "bananero": C("el bananero", "arbol", "#5FB84A", "#FFD84A", "bananero"),
    "represa": C("la represa", "represa", "#8A5A36", "#4FA3E0"),
    "cueva_milodon": C("la cueva del milodón", "cueva", "#A89A8A", "#2E2620", "milodon"),
    "carpa_toby": C("la carpa de Toby", "carpa", "#FF8A3D", "#FFD84A"),
}

# ---------------------------------------------------------------------------------------------------------
# Contenido por zona y hermano (planeta-animalia-zonas.md §4.2)
# ---------------------------------------------------------------------------------------------------------

PERFILES = {
    "semilla": {
        "cuadricula": {1: (4, 3), 2: (4, 3), 3: (4, 3), 4: (5, 4), 5: (5, 4)},
        "pares": {1: 2, 2: 2, 3: 2, 4: 3, 5: 3},
        "tableros": {1: 5, 2: 5, 3: 5, 4: 5, 5: 5},
        "llenar": {z: False for z in range(1, 6)},
        "rocas": {z: 0 for z in range(1, 6)},
        "puentes": {z: 0 for z in range(1, 6)},
        "forma": {1: "recto", 2: "recto", 3: "una_curva", 4: "una_curva", 5: "dos_curvas"},
        "tiempo_par": {1: 15, 2: 18, 3: 20, 4: 22, 5: 25},
    },
    "brote": {
        "cuadricula": {1: (5, 5), 2: (5, 5), 3: (6, 6), 4: (6, 6), 5: (6, 6)},
        "pares": {1: 3, 2: 4, 3: 4, 4: 5, 5: 5},
        "tableros": {z: 4 for z in range(1, 6)},
        "llenar": {1: False, 2: False, 3: True, 4: True, 5: True},
        "rocas": {1: 0, 2: 0, 3: 0, 4: 1, 5: 2},
        "puentes": {z: 0 for z in range(1, 6)},
        "forma": {z: "curvas" for z in range(1, 6)},
        "tiempo_par": {1: 35, 2: 45, 3: 60, 4: 70, 5: 80},
    },
    "estrella": {
        "cuadricula": {1: (7, 7), 2: (7, 7), 3: (8, 8), 4: (8, 8), 5: (9, 9)},
        "pares": {1: 6, 2: 7, 3: 7, 4: 8, 5: 9},
        "tableros": {1: 4, 2: 4, 3: 4, 4: 3, 5: 3},
        "llenar": {z: True for z in range(1, 6)},
        "rocas": {1: 0, 2: 2, 3: 3, 4: 3, 5: 4},
        "puentes": {1: 0, 2: 0, 3: 1, 4: 1, 5: 2},
        "forma": {z: "serpenteante" for z in range(1, 6)},
        "tiempo_par": {1: 60, 2: 70, 3: 85, 4: 95, 5: 120},
    },
}

# Política de derrota del PO (05-Nov-2026): todos pueden perder; nunca castigo ni quitar progreso.
DERROTA = {
    "semilla": {"tormenta": {"factor_par": 3.0}, "regalo_tras_derrotas": 2,
                "ayuda_fuerte_tras_derrotas": {"derrotas": 3, "caminos_regalados": "todos_menos_uno", "sin_tormenta": True},
                "descanso_tras_derrotas": None},
    "brote": {"tormenta": {"factor_par": 2.2}, "regalo_tras_derrotas": 2, "ayuda_fuerte_tras_derrotas": None,
              "descanso_tras_derrotas": 3},
    "estrella": {"tormenta": {"factor_par": 1.6}, "regalo_tras_derrotas": 3, "ayuda_fuerte_tras_derrotas": None,
                 "descanso_tras_derrotas": 4},
}

# (animal, casa). "fijos_primero"/"fijos_ultimo": el que va siempre en el primer/último tablero.
# "fijos": van en todos los tableros. "prohibidos": pares de casas que no comparten tablero (§4.2).
CONTENIDO = {
    ("semilla", 1): {"pool": [("perro", "casita_perro"), ("vaca", "granero"), ("pato", "laguna"), ("gato", "canasto"),
                              ("gallina", "gallinero")]},
    ("semilla", 2): {"pool": [("perrito_bombero", "cuartel"), ("pato", "laguna"), ("tortuga", "arena"),
                              ("hipopotamo", "charco_barro"), ("perro", "casita_perro")],
                     "fijos_primero": ["perrito_bombero"]},
    ("semilla", 3): {"pool": [("braquiosaurio", "arboles_altos"), ("triceratops", "pradera_flores"), ("caballo", "establo"),
                              ("vaca", "granero"), ("elefante", "rio")], "fijos_primero": ["braquiosaurio"]},
    ("semilla", 4): {"pool": [("trex", "volcan"), ("spinosaurio", "rio"), ("carnotauro", "cueva"),
                              ("braquiosaurio", "arboles_altos"), ("triceratops", "pradera_flores")]},
    ("semilla", 5): {"pool": [("trex", "volcan"), ("spinosaurio", "rio"), ("carnotauro", "cueva"),
                              ("braquiosaurio", "arboles_altos"), ("triceratops", "pradera_flores"),
                              ("huevito", "nido_mama_trex")], "fijos_ultimo": ["huevito"], "solo_ultimo": ["huevito"]},
    ("brote", 1): {"pool": [("pony", "establo"), ("gatito", "canasto"), ("perrito", "casita_perro"), ("pato", "laguna"),
                            ("caballo", "pradera")], "fijos": ["pony", "gatito"]},
    ("brote", 2): {"pool": [("pony", "establo"), ("gatito", "canasto"), ("patito", "nenufar"), ("flamenco", "laguna_rosada"),
                            ("cisne", "juncal")], "fijos": ["flamenco"]},
    ("brote", 3): {"pool": [("jirafa", "acacia"), ("jirafita", "mama_jirafa"), ("cebra", "pasto_alto"), ("caballo", "pradera"),
                            ("pony", "establo"), ("elefante", "charca")], "fijos": ["jirafita"]},
    ("brote", 4): {"pool": [("mono", "palmera"), ("loro", "nido"), ("gatito", "canasto_colgante"), ("buho", "hueco_arbol"),
                            ("perezoso", "liana"), ("pony", "establo")], "fijos": ["gatito"]},
    ("brote", 5): {"pool": [("pony_estelar", "nube_estrellas"), ("jirafa", "acacia"), ("pony", "establo"),
                            ("caballo", "pradera"), ("gatito", "canasto"), ("perrito", "casita_perro")],
                   "fijos_ultimo": ["pony_estelar"], "solo_ultimo": ["pony_estelar"]},
    ("estrella", 1): {"pool": [("perrito", "cucha"), ("gatito", "cojin"), ("gerbo", "castillito_carton"), ("pony", "establo"),
                               ("cuy", "casita_heno"), ("conejo", "madriguera"), ("pollito", "gallinero")],
                      "fijos": ["perrito", "gerbo"]},
    ("estrella", 2): {"pool": [("lobo_marino", "roquerio"), ("pinguino", "cueva_costa"), ("flamenco", "salar"),
                               ("cisne_cuello_negro", "humedal"), ("huillin", "rio_bosque"), ("oso_polar", "tempano"),
                               ("ballena", "mar")]},
    ("estrella", 3): {"pool": [("huemul", "cordillera_nevada"), ("pudu", "bosque_lluvioso"), ("guanaco", "estepa"),
                               ("alpaca", "bofedal"), ("condor", "cumbre"), ("camello", "desierto"), ("jirafa", "acacia"),
                               ("panda", "bambu")], "prohibidos": [("huemul", "condor")]},
    ("estrella", 4): {"pool": [("tucan", "selva_tropical"), ("tricahue", "barranco"), ("monito_del_monte", "nido_musgo"),
                               ("carpintero", "tronco_roble"), ("koala", "eucalipto"), ("mono", "bananero"),
                               ("castor", "represa"), ("panda", "bambu"), ("oso_polar", "tempano")],
                      "prohibidos": [("tucan", "mono")]},
    ("estrella", 5): {"pool": [("milodon", "cueva_milodon"), ("perrito", "carpa_toby"), ("pinguino", "cueva_costa"),
                               ("huemul", "cordillera_nevada"), ("flamenco", "salar"), ("koala", "eucalipto"),
                               ("ballena", "mar"), ("camello", "desierto"), ("pudu", "bosque_lluvioso"), ("castor", "represa")],
                      "fijos": ["milodon", "perrito"]},
}

NOMBRE_ZONA = {1: "El Campamento de Toby", 2: "La Laguna de los Nenúfares", 3: "La Pradera de las Jirafas",
               4: "El Árbol de los Nidos", 5: "El Valle de los Dinosaurios"}

# ---------------------------------------------------------------------------------------------------------
# Fabricación de tableros
# ---------------------------------------------------------------------------------------------------------


def vecinos(i, w, h):
    x, y = i % w, i // w
    r = []
    if x > 0:
        r.append(i - 1)
    if x < w - 1:
        r.append(i + 1)
    if y > 0:
        r.append(i - w)
    if y < h - 1:
        r.append(i + w)
    return r


def hamiltoniano(w, h, rng):
    camino = []
    for y in range(h):
        fila = list(range(y * w, y * w + w))
        camino += fila if y % 2 == 0 else fila[::-1]
    for _ in range(w * h * 40):
        if rng.random() < 0.5:
            camino.reverse()
        fin = camino[-1]
        opciones = [n for n in vecinos(fin, w, h) if n != camino[-2]]
        n = rng.choice(opciones)
        k = camino.index(n)
        camino = camino[:k + 1] + camino[k + 1:][::-1]
    return camino


def cortar(camino, k, minimo, rng):
    n = len(camino)
    for _ in range(200):
        cortes = sorted(rng.sample(range(minimo, n - minimo + 1), k - 1)) if k > 1 else []
        bordes = [0] + cortes + [n]
        if all(bordes[i + 1] - bordes[i] >= minimo for i in range(k)):
            return [camino[bordes[i]:bordes[i + 1]] for i in range(k)]
    return None


def eje_recto(seg, k, w):
    a, b, c = seg[k - 1], seg[k], seg[k + 1]
    if a // w == b // w == c // w:
        return 0
    if a % w == b % w == c % w:
        return 1
    return -1


def poner_puente(segs, w, h, rng, puentes, minimo):
    candidatos = []
    for si, seg in enumerate(segs):
        for k in range(1, len(seg) - 1):
            c = seg[k]
            if c in puentes or any(n in puentes for n in vecinos(c, w, h)):
                continue
            eje = eje_recto(seg, k, w)
            if eje < 0:
                continue
            if seg[k - 1] in puentes or seg[k + 1] in puentes:
                continue
            x, y = c % w, c // w
            if eje == 0:
                if y == 0 or y == h - 1:
                    continue
                u, d = c - w, c + w
            else:
                if x == 0 or x == w - 1:
                    continue
                u, d = c - 1, c + 1
            candidatos.append((si, c, u, d))
    rng.shuffle(candidatos)
    for si, c, u, d in candidatos:
        def donde(celda):
            for j, s in enumerate(segs):
                if celda in s and j != si:
                    idxs = [t for t, q in enumerate(s) if q == celda]
                    return j, idxs[0]
            return None
        a = donde(u)
        b = donde(d)
        if a is None or b is None or u in puentes or d in puentes:
            continue
        (j1, i1), (j2, i2) = a, b
        nuevos = []
        if j1 != j2:
            s1, s2 = segs[j1], segs[j2]
            op1 = []
            if i1 + 1 >= minimo or i1 == len(s1) - 1 or True:
                op1.append((s1[:i1 + 1], s1[i1 + 1:]))
                op1.append((s1[i1:][::-1], s1[:i1]))
            op2 = [(s2[i2:], s2[:i2]), (s2[:i2 + 1][::-1], s2[i2 + 1:])]
            rng.shuffle(op1)
            rng.shuffle(op2)
            hecho = False
            for p1, r1 in op1:
                for p2, r2 in op2:
                    partes = [r for r in (r1, r2) if r]
                    if any(len(r) < minimo for r in partes):
                        continue
                    if any(q in puentes for q in (p1[-1], p2[0])):
                        continue
                    nuevo = p1 + [c] + p2
                    if any(r and (r[0] in puentes or r[-1] in puentes) for r in partes):
                        continue
                    resto = [s for j, s in enumerate(segs) if j not in (j1, j2)]
                    nuevos = resto + [nuevo] + partes
                    hecho = True
                    break
                if hecho:
                    break
            if not hecho:
                continue
        else:
            s = segs[j1]
            idx_u = s.index(u)
            idx_d = s.index(d)
            lo, hi = min(idx_u, idx_d), max(idx_u, idx_d)
            if hi - lo < 2:
                continue
            nuevo = s[:lo + 1] + [c] + s[hi:]
            medio = s[lo + 1:hi]
            if len(medio) < minimo or medio[0] in puentes or medio[-1] in puentes:
                continue
            resto = [q for j, q in enumerate(segs) if j != j1]
            nuevos = resto + [nuevo, medio]
        puentes.add(c)
        return nuevos
    return None


def se_toca(segs, w, puentes):
    """True si algún camino se toca a sí mismo (dos celdas no consecutivas vecinas). Las soluciones únicas de
    Flow Free casi nunca lo hacen: filtrarlo antes del solver sube mucho la tasa de tableros únicos."""
    for s in segs:
        pos = {c: k for k, c in enumerate(s) if c not in puentes}
        for c, k in pos.items():
            x, y = c % w, c // w
            for n in (c + 1 if x < w - 1 else -1, c + w):
                if n in pos and abs(pos[n] - k) > 1:
                    return True
    return False


def tablero_con_llenado(w, h, pares, rocas, n_puentes, rng, minimo=3, segundos=90.0, max_nodos=300000):
    """Busca un tablero con solución única durante `segundos`. Si no aparece (tableros grandes con puentes),
    se queda con el candidato válido que tenga menos soluciones alternativas encontradas (se marca unica=False)."""
    import time
    t0 = time.time()
    mejor = None
    intento = 0
    while time.time() - t0 < segundos or mejor is None:
        intento += 1
        camino = hamiltoniano(w, h, rng)
        k0 = pares - n_puentes + rng.randint(0, n_puentes)
        segs = cortar(camino, k0, minimo, rng)
        if segs is None:
            continue
        puentes = set()
        ok = True
        for _ in range(n_puentes):
            nuevos = poner_puente(segs, w, h, rng, puentes, minimo)
            if nuevos is None:
                ok = False
                break
            segs = nuevos
        if not ok or len(segs) != pares:
            continue
        celdas_roca = set()
        for _ in range(rocas):
            largos = [s for s in segs if len(s) > minimo and s[0] not in puentes and s[-1] not in puentes
                      and s[1] not in puentes and s[-2] not in puentes]
            if not largos:
                ok = False
                break
            s = rng.choice(largos)
            celdas_roca.add(s.pop(rng.choice([0, -1])))
        if not ok or any(len(s) < minimo for s in segs):
            continue
        if any(s[0] in puentes or s[-1] in puentes for s in segs):
            continue
        filas, sol = _escribir(w, h, segs, celdas_roca, puentes, rng)
        t = Tablero(filas)
        sol_xy = a_xy(t, sol)
        assert not validar_solucion(filas, sol_xy, True), validar_solucion(filas, sol_xy, True)
        n, sols, agotado = contar_soluciones(filas, True, 2, max_nodos)
        if n == 1 and not agotado:
            return filas, a_xy(t, sols[0]), True
        if mejor is None:
            mejor = (filas, sol_xy)
    return mejor[0], mejor[1], False


def _escribir(w, h, segs, rocas, puentes, rng):
    grilla = [["."] * w for _ in range(h)]
    for i in rocas:
        grilla[i // w][i % w] = "#"
    for i in puentes:
        grilla[i // w][i % w] = "+"
    orden = list(range(len(segs)))
    rng.shuffle(orden)
    sol = {}
    for letra_i, si in enumerate(orden):
        s = segs[si]
        if rng.random() < 0.5:
            s = s[::-1]
        letra = LETRAS[letra_i]
        grilla[s[0] // w][s[0] % w] = letra
        grilla[s[-1] // w][s[-1] % w] = letra.lower()
        sol[letra] = s
    return ["".join(f) for f in grilla], sol


def curvas(camino_xy):
    n = 0
    for k in range(1, len(camino_xy) - 1):
        a, b, c = camino_xy[k - 1], camino_xy[k], camino_xy[k + 1]
        if (b[0] - a[0], b[1] - a[1]) != (c[0] - b[0], c[1] - b[1]):
            n += 1
    return n


def tablero_sin_llenado(w, h, pares, forma, rng, rocas=0, intentos=20000, usados=None):
    """Maxi, Nicole z1-z2 y equipo: la solución de menor largo total, única; con la forma pedida."""
    usados = usados if usados is not None else set()
    for intento in range(intentos):
        if forma in ("curvas",) or pares >= 4:
            camino = hamiltoniano(w, h, rng)
            segs = cortar(camino, pares, 3, rng)
            if segs is None:
                continue
            extremos = [(s[0], s[-1]) for s in segs]
        else:
            celdas = list(range(w * h))
            rng.shuffle(celdas)
            extremos = []
            libres = set(celdas)
            for _ in range(pares):
                elegido = None
                for a in list(libres):
                    for b in list(libres):
                        if a == b:
                            continue
                        ax, ay, bx, by = a % w, a // w, b % w, b // w
                        dist = abs(ax - bx) + abs(ay - by)
                        if dist < 2:
                            continue
                        if forma == "recto" and not (ax == bx or ay == by):
                            continue
                        if forma == "recto" and dist < 3 and w > 3:
                            continue
                        if rng.random() < 0.08:
                            elegido = (a, b)
                            break
                    if elegido:
                        break
                if elegido is None:
                    break
                extremos.append(elegido)
                libres.discard(elegido[0])
                libres.discard(elegido[1])
            if len(extremos) != pares:
                continue
        grilla = [["."] * w for _ in range(h)]
        for k, (a, b) in enumerate(extremos):
            grilla[a // w][a % w] = LETRAS[k]
            grilla[b // w][b % w] = LETRAS[k].lower()
        if rocas:
            vacias = [i for i in range(w * h) if grilla[i // w][i % w] == "."]
            for i in rng.sample(vacias, rocas):
                grilla[i // w][i % w] = "#"
        filas = ["".join(f) for f in grilla]
        if tuple(filas) in usados:
            continue
        sol, n_min, agotado = solucion_minima(filas, 200000)
        if sol is None or agotado or n_min != 1:
            continue
        t = Tablero(filas)
        sol_xy = a_xy(t, sol)
        cs = [curvas(c) for c in sol_xy.values()]
        largos = [len(c) for c in sol_xy.values()]
        if min(largos) < 3:
            continue
        if forma == "recto" and max(cs) > 0:
            continue
        if forma == "una_curva" and (max(cs) != 1):
            continue
        if forma == "dos_curvas" and (max(cs) < 1 or max(cs) > 2 or sum(1 for c in cs if c >= 1) < 2):
            continue
        if forma == "curvas" and (sum(1 for c in cs if c >= 1) < 2 or max(cs) < 2):
            continue
        usados.add(tuple(filas))
        return filas, sol_xy, intento
    raise RuntimeError("no se encontro tablero sin llenado %dx%d %d %s" % (w, h, pares, forma))


# ---------------------------------------------------------------------------------------------------------
# Animales por tablero
# ---------------------------------------------------------------------------------------------------------


def repartir(contenido, tableros, pares, rng):
    pool = [a for a, _ in contenido["pool"]]
    casa_de = dict(contenido["pool"])
    fijos = contenido.get("fijos", [])
    primero = contenido.get("fijos_primero", [])
    ultimo = contenido.get("fijos_ultimo", [])
    solo_ultimo = set(contenido.get("solo_ultimo", []))
    prohibidos = contenido.get("prohibidos", [])
    usos = {a: 0 for a in pool}
    res = []
    for t in range(tableros):
        elegidos = list(fijos)
        if t == 0:
            elegidos += [a for a in primero if a not in elegidos]
        if t == tableros - 1:
            elegidos += [a for a in ultimo if a not in elegidos]
        candidatos = [a for a in pool if a not in elegidos and not (a in solo_ultimo and t != tableros - 1)]
        rng.shuffle(candidatos)
        candidatos.sort(key=lambda a: usos[a])
        for a in candidatos:
            if len(elegidos) >= pares:
                break
            if any((a == p and q in elegidos) or (a == q and p in elegidos) for p, q in prohibidos):
                continue
            elegidos.append(a)
        assert len(elegidos) == pares, (contenido, t, elegidos)
        for a in elegidos:
            usos[a] += 1
        # el protagonista del primer/último tablero va como par A (el que la guía muestra primero)
        especiales = [a for a in elegidos if a in primero or (a in ultimo and t == tableros - 1)]
        resto = [a for a in elegidos if a not in especiales]
        rng.shuffle(resto)
        res.append([(a, casa_de[a]) for a in especiales + resto])
    return res


# ---------------------------------------------------------------------------------------------------------
# Puntaje (Brote) y voces
# ---------------------------------------------------------------------------------------------------------

PUNTOS = {"llegada": 100, "racha_max": 5, "tablero": 300, "sin_borrones": 300, "por_segundo": 10}


def puntaje_simulado(tableros, pares, par, frac_tiempo, borrones):
    racha = 0
    total = 0
    for _ in range(tableros):
        for k in range(pares):
            if borrones and k == 1:
                racha = 0
            racha = min(racha + 1, PUNTOS["racha_max"])
            total += PUNTOS["llegada"] * racha
        total += PUNTOS["tablero"]
        if not borrones:
            total += PUNTOS["sin_borrones"]
        total += int(PUNTOS["por_segundo"] * max(0.0, par - frac_tiempo * par))
    return total


def redondear(x, a=100):
    return int(round(x / a)) * a


def voz(ruta):
    return "voces/animalia/caminos/" + ruta + ".wav"


def lineas_voz(perfil, zona, pares_usados, casas_usadas, casas_modo):
    z = "zona%d" % zona
    lv = {
        "intro": voz("%s/%s_intro" % (z, perfil)),
        "instruccion": voz("%s/%s_instruccion" % (z, perfil)),
        "tablero_listo": [voz("comun/tablero_listo_%02d" % i) for i in (1, 2, 3)],
        "victoria": [voz("comun/victoria_%s_%02d" % (perfil, i)) for i in (1, 2)],
        "derrota_gag": voz("comun/tormenta_%s" % perfil),
        "otra_vez": voz("comun/otra_vez"),
        "regalo": voz("comun/regalo"),
        "nube_presenta": voz("comun/nube_presenta_%s" % perfil),
        "nombres": {a: "voces/animalia/nombres/%s.wav" % a for a in pares_usados},
    }
    if perfil == "semilla":
        lv["guia"] = voz("comun/guia_semilla")
        lv["ayuda_fuerte"] = voz("comun/ayuda_fuerte")
        lv["valvula"] = voz("comun/valvula_sopla")
    else:
        lv["descansar"] = voz("comun/descansar")
        lv["faltan_flores"] = voz("comun/faltan_flores")
        lv["record"] = voz("comun/record")
        lv["primer_record"] = voz("comun/primer_record")
        lv["sin_borrones"] = voz("comun/sin_borrones")
    if perfil == "brote":
        lv["casa_late"] = voz("comun/casa_late")
    if perfil == "estrella":
        lv["casa_ajena"] = [voz("comun/casa_ajena_%02d" % i) for i in (1, 2)]
        lv["pista_usada"] = voz("comun/pista_usada")
    if casas_modo == "habitat":
        lv["habitats"] = {c: "voces/animalia/caminos/habitats/%s.wav" % c for c in casas_usadas}
    return lv


# ---------------------------------------------------------------------------------------------------------
# Armado de cada nivel
# ---------------------------------------------------------------------------------------------------------


def armar_nivel(perfil, zona, rng, dorado=False):
    P = PERFILES[perfil]
    w, h = P["cuadricula"][zona]
    pares = P["pares"][zona]
    n_tab = P["tableros"][zona]
    llenar = P["llenar"][zona]
    rocas = P["rocas"][zona]
    puentes = P["puentes"][zona]
    forma = P["forma"][zona]
    par = P["tiempo_par"][zona]
    contenido = CONTENIDO[(perfil, zona)]
    if dorado:
        # El gran tablero de Toby (planeta-animalia-zonas.md §6.2): 9x9, 8 pares, 3 puentes y 4 rocas.
        w, h, pares, n_tab, rocas, puentes, par = 9, 9, 8, 1, 4, 3, 150
    casas_modo = "color" if perfil != "estrella" or zona == 1 else "habitat"
    reparto = repartir(contenido, n_tab, pares, rng)
    tableros = []
    usados = set()
    for t_i, elenco in enumerate(reparto):
        if llenar:
            presupuesto = 25.0 if w <= 6 else (60.0 if w == 7 else 45.0)
            filas, sol, unica = tablero_con_llenado(w, h, pares, rocas, puentes, rng, segundos=presupuesto)
        else:
            filas, sol, _ = tablero_sin_llenado(w, h, pares, forma, rng, rocas, usados=usados)
            unica = True
        pares_json = {}
        for k, (animal, casa) in enumerate(elenco):
            pares_json[LETRAS[k]] = {"animal": animal, "casa": casa, "color": COLORES[k]}
        tableros.append({
            "id": "t%d" % (t_i + 1),
            "celdas": filas,
            "pares": pares_json,
            "tiempo_par_s": par,
            "solucion": sol,
            "solucion_unica": unica,
        })
        print("  %s z%d t%d listo %dx%d" % (perfil, zona, t_i + 1, w, h), flush=True)
    animales_usados = sorted({a for e in reparto for a, _ in e})
    casas_usadas = sorted({c for e in reparto for _, c in e})
    catalogo = {}
    for a in animales_usados:
        catalogo[a] = ANIMALES[a]
    for c in casas_usadas:
        catalogo[c] = CASAS[c]
    zona_id, fondo1, fondo2 = ZONAS[zona]
    sufijo = "_dorado" if dorado else ""
    nivel = {
        "id_nivel": "animalia_z%d_caminos_%s%s" % (zona, perfil, sufijo),
        "motor": "caminos",
        "perfil": perfil,
        "planeta": "animalia",
        "zona": zona_id,
        "tema": NOMBRE_ZONA[zona],
        "nota": ("Generado por herramientas/generar_niveles_caminos.py (dev-godot, HE-117, 05-Nov-2026). "
                 "Tableros con solucion validada por herramientas/solver_caminos.py (con llenado: unica si solucion_unica; si no, valida; "
                 "sin llenado: la de menor largo total, unica). Politica de derrota del PO 05-Nov-2026. PROVISIONAL hasta el "
                 "playtest: disenador-niveles puede afinar tiempos y umbrales."),
        "fondo": {"cielo": fondo1, "suelo": fondo2, "zona": zona},
        "llenar": llenar,
        "casas": casas_modo,
        "cortar_ajenos": perfil != "semilla",
        "animal_bajo_dedo": perfil == "semilla",
        "iman_casa": 1 if perfil == "semilla" else 0,
        "empezar_desde_casa": perfil != "semilla" and casas_modo == "color",
        "histeresis": 0.35 if perfil != "semilla" else 0.25,
        "atraso_max_celdas": 3 if perfil != "semilla" else 4,
        "transformar": True,
        "orden_tableros": "fijo",
        "tableros": tableros,
        "catalogo": catalogo,
        "puntos": dict(PUNTOS) if perfil != "semilla" else None,
        "umbrales_puntaje": None,
        "umbrales_estrellitas": {"trazos_de_mas": 1, "intentos_casa": 0} if perfil == "estrella" else None,
        "tiempo_par": perfil != "semilla",
        "tormenta": None if dorado else dict(DERROTA[perfil]["tormenta"]),
        "regalo_tras_derrotas": DERROTA[perfil]["regalo_tras_derrotas"],
        "ayuda_fuerte_tras_derrotas": DERROTA[perfil]["ayuda_fuerte_tras_derrotas"],
        "descanso_tras_derrotas": DERROTA[perfil]["descanso_tras_derrotas"],
        "ayuda_idle_s": [6, 10] if perfil == "semilla" else ([15] if perfil == "brote" else []),
        "valvula_s": 6 if perfil == "semilla" else 0,
        "pistas_cuestan_estrellita": perfil == "estrella",
        "guardado_parcial": True,
        "lineas_voz": lineas_voz(perfil, zona, animales_usados, casas_usadas, casas_modo),
    }
    if perfil == "brote":
        dos = puntaje_simulado(n_tab, pares, par, 0.85, 1)
        tres = puntaje_simulado(n_tab, pares, par, 0.6, 0) * 0.92
        nivel["umbrales_puntaje"] = {"dos": redondear(dos), "tres": redondear(tres)}
    if dorado:
        nivel["reto_dorado"] = True
        nivel["nota_dorado"] = "El gran tablero de Toby (planeta-animalia-zonas.md §6.2): sin tormenta, con guardado parcial, 0 destellos."
    return nivel


def armar_equipo(rng):
    """Tablero compartido 6x6, 5 pares, sin llenado (motor-caminos.md §12.2). Casas de color."""
    elenco = [("vaca", "granero"), ("perrito", "casita_perro"), ("gatito", "canasto"), ("pony", "establo"),
              ("pato", "laguna")]
    filas, sol, _ = tablero_sin_llenado(6, 6, 5, "curvas", rng)
    pares_json = {LETRAS[k]: {"animal": a, "casa": c, "color": COLORES[k]} for k, (a, c) in enumerate(elenco)}
    catalogo = {a: ANIMALES[a] for a, _ in elenco}
    catalogo.update({c: CASAS[c] for _, c in elenco})
    eq = "voces/nucleo/equipo/"
    return {
        "id_nivel": "animalia_z1_caminos_equipo",
        "motor": "caminos",
        "modo_juego": "equipo",
        "perfil": "brote",
        "planeta": "animalia",
        "zona": "zona1_campamento",
        "tema": "Cada quien a su casa en equipo: un tablero compartido",
        "nota": ("motor-caminos.md §12.2 y modo-equipo.md §11.4 (dev-godot HE-117, 05-Nov-2026). Un tablero 6x6 con 5 "
                 "pares y sin llenado; los caminos llegados quedan fijos; tope por turno M1 N1 S2; segundos_por_turno "
                 "N45 S40 sin llegar -> fallo que pasa el turno. PROVISIONAL: calibrar pasos_rival con el simulador."),
        "fondo": {"cielo": ZONAS[1][1], "suelo": ZONAS[1][2], "zona": 1},
        "llenar": False,
        "casas": "color",
        "cortar_ajenos": True,
        "animal_bajo_dedo": False,
        "iman_casa": 0,
        "empezar_desde_casa": True,
        "histeresis": 0.35,
        "atraso_max_celdas": 3,
        "transformar": True,
        "tableros": [{"id": "t1", "celdas": filas, "pares": pares_json, "tiempo_par_s": 0, "solucion": sol}],
        "catalogo": catalogo,
        "puntos": None,
        "tormenta": None,
        "regalo_tras_derrotas": 0,
        "equipo": {
            "rival": "coleccionauta",
            "orden": "maxi_intercalado",
            "puerta_tras_semilla": "arrastre",
            "bloqueo_tras_puerta_ms": 400,
            "maxi_mueve_rival": False,
            "racha_retrocede_rival": 0,
            "semilla_auto_s": 20,
            "aciertos_max_turno": {"semilla": 1, "brote": 1, "estrella": 2},
            "segundos_por_turno": {"brote": 45, "estrella": 40},
            "llegados_fijos": True,
            "composiciones": {
                "maxi+nicole": {"pasos_rival": 6},
                "maxi+sofia": {"pasos_rival": 6},
                "nicole+sofia": {"pasos_rival": 5},
                "maxi+nicole+sofia": {"pasos_rival": 6},
            },
        },
        "lineas_voz": {
            "intro_ronda": voz("equipo/intro"),
            "maxi_regalito": voz("equipo/maxi_regalito"),
            "maxi_brilla": voz("equipo/maxi_brilla"),
            "victoria_equipo": voz("equipo/victoria"),
            "derrota_gag_equipo": [voz("equipo/coleccionauta_aspira"), voz("equipo/coleccionauta_estornuda"),
                                   voz("equipo/toby_otra_vez")],
            "logro_comun": {str(n): voz("equipo/logro_%d" % n) for n in range(1, 5)},
            "nos_alcanzo": eq + "nos_alcanzo.wav",
            "le_toca": {h: [eq + "le_toca_%s_0%d.wav" % (h, i) for i in (1, 2, 3)] for h in ("maxi", "nicole", "sofia")},
            "te_toca_recordatorio": {h: eq + "te_toca_%s.wav" % h for h in ("maxi", "nicole", "sofia")},
            "te_toca_recordatorio_ventanita": {h: eq + "te_toca_%s_ventanita.wav" % h for h in ("nicole", "sofia")},
            "sube_ventanita": {h: eq + "sube_ventanita_%s.wav" % h for h in ("nicole", "sofia")},
            "maxi_ayuda": eq + "maxi_ayuda.wav",
            "animo_hermanos": {h: [eq + "animo_%s_0%d.wav" % (h, i) for i in (1, 2)] for h in ("maxi", "nicole", "sofia")},
            "rival_avanza": [eq + "coleccionauta/avanza_0%d.wav" % i for i in (1, 2, 3, 4)],
            "rival_embobado": [eq + "coleccionauta/embobado_0%d.wav" % i for i in (1, 2, 3)],
            "rival_retrocede": [eq + "coleccionauta/retrocede_0%d.wav" % i for i in (1, 2)],
            "rival_vuelve": eq + "coleccionauta/vuelve.wav",
            "nombres": {a: "voces/animalia/nombres/%s.wav" % a for a, _ in elenco},
        },
    }


def escribir(nivel, ruta_rel):
    ruta = os.path.join(RAIZ, ruta_rel)
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    texto = json.dumps(nivel, ensure_ascii=False, indent=2)
    # las filas del tablero y las soluciones quedan en una línea cada una (legibles a mano)
    with open(ruta, "w", encoding="utf-8") as f:
        f.write(_compactar(texto) + "\n")
    print("escrito", ruta_rel, flush=True)


def _compactar(texto):
    import re
    # listas cortas de números ([x, y]) en una sola línea
    texto = re.sub(r"\[\s+(-?\d+),\s+(-?\d+)\s+\]", r"[\1, \2]", texto)
    texto = re.sub(r"\[\s+((?:\[-?\d+, -?\d+\],?\s*)+)\]", lambda m: "[" + re.sub(r"\s+", " ", m.group(1)).strip() + "]", texto)
    return texto


def main():
    solo = sys.argv[1:]  # p. ej. "estrella:5" para regenerar uno solo
    for perfil in ("semilla", "brote", "estrella"):
        for zona in range(1, 6):
            clave = "%s:%d" % (perfil, zona)
            if solo and clave not in solo:
                continue
            rng = random.Random(hash_estable(clave))
            nivel = armar_nivel(perfil, zona, rng)
            escribir(nivel, "datos/niveles/animalia/%s/caminos_%s.json" % (ZONAS[zona][0], perfil))
    if not solo or "dorado" in solo:
        rng = random.Random(hash_estable("dorado"))
        escribir(armar_nivel("estrella", 5, rng, dorado=True), "datos/niveles/animalia/zona5_valle/caminos_estrella_dorado.json")
    if not solo or "equipo" in solo:
        rng = random.Random(hash_estable("equipo"))
        escribir(armar_equipo(rng), "datos/niveles/animalia/zona1_campamento/caminos_equipo.json")


def hash_estable(texto):
    h = 2166136261
    for ch in texto.encode("utf-8"):
        h = ((h ^ ch) * 16777619) & 0xFFFFFFFF
    return h


if __name__ == "__main__":
    main()
