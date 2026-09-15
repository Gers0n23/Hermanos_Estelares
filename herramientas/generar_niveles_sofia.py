"""Genera los niveles de Sofía con la dificultad v3 (decisión del PO, 14-Sep-2026).

Usa `disenar_retos_sofia.py` para resolver cada tangram y cada marco. Así todo nivel generado tiene
solución verificada, y las pistas del motor usan esa solución. Escribe:

- `datos/niveles/arcoiris/<zona>/formas_estrella.json` (5 zonas) + `zona5_cima/formas_estrella_dorado.json`
- `datos/niveles/arcoiris/<zona>/parejas_estrella.json` (5 zonas) + `zona5_cima/parejas_estrella_dorado.json`

Uso: python herramientas/generar_niveles_sofia.py
"""

from __future__ import annotations

import json
import pickle
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import disenar_retos_sofia as D  # noqa: E402

NIVELES = D.RAIZ / "datos" / "niveles" / "arcoiris"
CANDIDATOS_ESPEJO = Path(__file__).resolve().parent / "retos_sofia_candidatos_espejo.pkl"
COLORES_TANGRAM = ["#FF6B6B", "#4A8BE0", "#7DD87A", "#FFCB3D", "#B48CE8", "#FF9F4A", "#45C6C0"]
COLORES_TANGRAM_2 = ["#F26CA8", "#6FD6E8", "#3FB57A", "#FFE38A", "#9B6BD9", "#FFB25B", "#2E9E9A"]
COLORES_PENTOMINO = {
    "F": "#FF6B6B", "I": "#4A8BE0", "L": "#7DD87A", "N": "#FFCB3D", "P": "#B48CE8", "T": "#FF9F4A",
    "U": "#45C6C0", "V": "#F26CA8", "W": "#6FD6E8", "X": "#FFE38A", "Y": "#9B6BD9", "Z": "#B07A4F",
}
SILUETAS = {
    "casa": [(0, 2), (2, 0), (4, 2), (3, 2), (3, 4), (1, 4), (1, 2)],
    "velero": [(2, 0), (3, 1), (2, 1), (2, 3), (4, 3), (3, 4), (1, 4), (0, 3), (-1, 3)],
    "pez": [(0, 0), (2, 0), (1, 1), (2, 2), (0, 4), (0, 3), (-1, 4), (-1, 0), (0, 1)],
    "cohete": [(1, 0), (2, 1), (2, 3), (3, 4), (-1, 4), (0, 3), (0, 1)],
    "cuadrado": [(0, 2), (2, 0), (4, 2), (2, 4)],
}
NAVE = [(2, 0), (3, 1), (3, 4), (5, 6), (3, 6), (2, 7), (1, 6), (-1, 6), (1, 4), (1, 1)]
MARCO_NAVE = ["...#....", "...##...", "..####..", ".######.", ".######.", "########", "########", "###..###", "##....##"]
FIGURAS_VOZ = {"casa": "casa", "velero": "barco", "pez": "pez", "cohete": "cohete"}
## Siluetas generadas al azar que exigen espejo (índice en el archivo de candidatos) y su nombre.
ESPEJO_ELEGIDOS = {"pajarito": 9, "flecha": 13, "tortuga": 20, "bumeran": 18}
VOZ_FORMAS = "voces/arcoiris/formas/estrella/"
VOZ_PAREJAS = "voces/arcoiris/emparejar/estrella/"


def resolver_cuartos(objetivo, piezas, maximo):
    xs = [c[0] for c in objetivo]
    ys = [c[1] for c in objetivo]
    caja = [(min(xs), min(ys)), (max(xs) + 1, min(ys)), (max(xs) + 1, max(ys) + 1), (min(xs), max(ys) + 1)]
    original = D.cuartos
    D.cuartos = lambda p: frozenset(objetivo) if p is caja else original(p)
    try:
        return D.resolver_tangram(caja, piezas, maximo)
    finally:
        D.cuartos = original


def figura_tangram(id_figura, solucion, colores, voz=""):
    piezas = []
    for i, (tipo, poligono) in enumerate(solucion):
        g = D.a_godot(tipo, poligono)
        piezas.append({"forma": g["forma"], "ancho": round(g["ancho"], 4), "alto": round(g["alto"], 4),
                       "rotacion": g["rotacion"], "espejo": g["espejo"], "x": round(g["x"], 4), "y": round(g["y"], 4),
                       "color": colores[i % len(colores)]})
    figura = {"id": id_figura, "silueta_unida": True, "piezas": piezas}
    if voz:
        figura["voz_completa"] = f"voces/arcoiris/formas/figuras/{voz}.wav"
    return figura


def espejo_de_p(solucion):
    for tipo, poligono in solucion:
        if tipo == "P":
            return D.a_godot(tipo, poligono)["espejo"]
    return None


def voces_formas(**extra):
    base = {
        "acierto": [f"{VOZ_FORMAS}acierto_0{i}.wav" for i in (1, 2, 3)],
        "no_es_este": [f"{VOZ_FORMAS}no_es_este_0{i}.wav" for i in (1, 2)],
        "figura_completa": [f"{VOZ_FORMAS}figura_completa_0{i}.wav" for i in (1, 2)],
        "derrota_gag": f"{VOZ_FORMAS}derrota_gag_01.wav",
        "victoria_final": [f"{VOZ_FORMAS}victoria_0{i}.wav" for i in (1, 2)],
        "pista_usada": f"{VOZ_FORMAS}pista_usada_01.wav",
        "regalo": f"{VOZ_FORMAS}regalo_01.wav",
        "espejo_sin_pieza": f"{VOZ_FORMAS}espejo_sin_pieza_01.wav",
        "girar": f"{VOZ_FORMAS}girar_01.wav",
        "prueba_superada": [f"{VOZ_FORMAS}prueba_superada_0{i}.wav" for i in (1, 2)],
    }
    base.update({k: (VOZ_FORMAS + v if isinstance(v, str) else v) for k, v in extra.items()})
    return base


def nivel_formas(zona, sufijo, **datos):
    nivel = {"id_nivel": f"arcoiris_z{zona[4]}_formas_estrella{sufijo}", "motor": "encajar", "perfil": "estrella",
             "planeta": "arcoiris", "zona": zona, "tema": "formas traviesas", "anfitrion_id": "coco",
             "fondo_id": "planeta_arcoiris", "dificultad": "v3 (PO 14-Sep-2026)", "caras": False, "guia_color": False,
             "pistas_cuestan_estrellita": True, "regalo_tras_derrotas": True}
    nivel.update(datos)
    return nivel


def pentominos(letras):
    return [{"id": l, "celdas": [list(c) for c in D.PENTOMINOS[l]], "color": COLORES_PENTOMINO[l]} for l in letras]


def solucion_marco(solucion):
    return [{"id": nombre, "celdas": [list(c) for c in celdas]} for nombre, celdas in solucion]


def escribir(ruta: Path, datos):
    ruta.parent.mkdir(parents=True, exist_ok=True)
    ruta.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("escrito", ruta.relative_to(D.RAIZ).as_posix())


def generar_formas():
    soluciones = {n: D.resolver_tangram(s, D.JUEGO_TANGRAM, 50) for n, s in SILUETAS.items()}
    voz = lambda n: FIGURAS_VOZ.get(n, "")
    tangram = lambda n, colores=COLORES_TANGRAM: figura_tangram(n, soluciones[n][0], colores, voz(n))

    escribir(NIVELES / "zona1_claro" / "formas_estrella.json", nivel_formas(
        "zona1_claro", "", mecanica="tangram_libre", modo="tangram", lado_red=96, iman_tolerancia_px=70,
        rotacion_por_toque=True, paso_rotacion=45, rotacion_inicial_aleatoria=True, limite_intentos=None,
        figuras_por_partida=1, figuras=[tangram(n) for n in ["casa", "cohete", "pez"]],
        lineas_voz=voces_formas(intro="intro_tangram_z1.wav", pista="pista_tangram_01.wav")))

    candidatos = pickle.load(open(CANDIDATOS_ESPEJO, "rb"))
    figuras = []
    for nombre in ["velero"] + list(ESPEJO_ELEGIDOS):
        if nombre == "velero":
            lista = soluciones["velero"]
        else:
            objetivo = frozenset(tuple(c) for c in candidatos[ESPEJO_ELEGIDOS[nombre]][0])
            lista = resolver_cuartos(objetivo, D.JUEGO_TANGRAM, 50)
        espejos = {espejo_de_p(s) for s in lista}
        if espejos == {False}:
            # Se refleja la silueta: la única quiralidad válida pasa a ser la del paralelogramo volteado.
            lista = [[(t, [(-x, y) for x, y in pol]) for t, pol in s] for s in lista]
            espejos = {espejo_de_p(s) for s in lista}
        assert espejos == {True}, (nombre, espejos)
        figuras.append(figura_tangram(nombre, lista[0], COLORES_TANGRAM, voz(nombre)))
    escribir(NIVELES / "zona2_charcos" / "formas_estrella.json", nivel_formas(
        "zona2_charcos", "", mecanica="tangram_libre", modo="tangram", lado_red=90, iman_tolerancia_px=70,
        rotacion_por_toque=True, paso_rotacion=45, rotacion_inicial_aleatoria=True, boton_espejo=True,
        limite_intentos=None, figuras_por_partida=1, figuras=figuras, distractoras_por_partida=1,
        piezas_distractoras=[{"forma": "triangulo_rect", "ancho": 1, "alto": 1, "color": "#F26CA8"},
                             {"forma": "cuadrado", "ancho": 1, "alto": 1, "color": "#F26CA8"},
                             {"forma": "triangulo_rect", "ancho": round(D.RAIZ2, 4), "alto": round(D.RAIZ2, 4), "color": "#F26CA8"}],
        lineas_voz=voces_formas(intro="intro_espejo_z2.wav", pista="pista_espejo_01.wav")))

    memoria = [tangram(n) for n in ["casa", "cohete", "pez", "velero", "cuadrado"]]
    escribir(NIVELES / "zona3_chupetines" / "formas_estrella.json", nivel_formas(
        "zona3_chupetines", "", mecanica="memoria", modo="tangram", lado_red=84, iman_tolerancia_px=55,
        segundos_modelo=5, exigir_color=True, boton_espejo=True, rotacion_por_toque=True, paso_rotacion=45,
        rotacion_inicial_aleatoria=True, limite_intentos=8, figuras_por_partida=1, figuras=memoria,
        lineas_voz=voces_formas(intro="intro_memoria_z3.wav", pista="pista_memoria_01.wav",
                                mira_modelo="mira_modelo_01.wav", tapa_modelo="tapa_modelo_01.wav")))

    z4a = D.resolver_marco(["#####"] * 5, list("FLPTWXY"), 1)[0]
    z4b = D.resolver_marco(["######"] * 5, list("FILNTWXYZ"), 1)[0]
    escribir(NIVELES / "zona4_islotes" / "formas_estrella.json", nivel_formas(
        "zona4_islotes", "", mecanica="marco", modo="marco", boton_espejo=True, rotacion_por_toque=True,
        paso_rotacion=90, iman_tolerancia_px=60,
        lineas_voz=voces_formas(intro="intro_marco_z4.wav", pista="pista_marco_01.wav"),
        pruebas=[
            {"marco": ["#####"] * 5, "lado_celda": 76, "limite_intentos": 8, "piezas_necesarias": 5,
             "piezas_marco": pentominos("FLPTWXY"), "solucion": solucion_marco(z4a)},
            {"marco": ["######"] * 5, "lado_celda": 72, "limite_intentos": 10, "piezas_necesarias": 6,
             "piezas_marco": pentominos("FILNTWXYZ"), "solucion": solucion_marco(z4b),
             "lineas_voz": {"intro": VOZ_FORMAS + "intro_marco_z4b.wav"}},
        ]))

    nave = D.resolver_tangram(NAVE, D.JUEGO_TANGRAM * 2, 5)
    sol_nave = D.resolver_marco(MARCO_NAVE, list("FILPTUVWXYZN"), 1)[0]
    escribir(NIVELES / "zona5_cima" / "formas_estrella.json", nivel_formas(
        "zona5_cima", "", modo="desafio", boton_espejo=True,
        lineas_voz=voces_formas(intro="intro_cima_1.wav", pista="pista_tangram_01.wav", victoria_final="victoria_cima_01.wav",
                                mira_modelo="mira_modelo_01.wav", tapa_modelo="tapa_modelo_01.wav"),
        pruebas=[
            {"mecanica": "tangram_libre", "lado_red": 68, "iman_tolerancia_px": 60, "rotacion_por_toque": True,
             "paso_rotacion": 45, "rotacion_inicial_aleatoria": True, "limite_intentos": None, "figuras_por_partida": 1,
             "figuras": [figura_tangram("nave", nave[0], COLORES_TANGRAM + COLORES_TANGRAM_2)]},
            {"mecanica": "marco", "marco": MARCO_NAVE, "lado_celda": 58, "limite_intentos": 12, "piezas_necesarias": 9,
             "rotacion_por_toque": True, "paso_rotacion": 90, "piezas_marco": pentominos("FILPTUVWXYZN"),
             "solucion": solucion_marco(sol_nave),
             "lineas_voz": {"intro": VOZ_FORMAS + "intro_cima_2.wav", "pista": VOZ_FORMAS + "pista_marco_01.wav"}},
            {"mecanica": "memoria", "lado_red": 84, "iman_tolerancia_px": 55, "segundos_modelo": 3, "exigir_color": True,
             "rotacion_por_toque": True, "paso_rotacion": 45, "rotacion_inicial_aleatoria": True, "limite_intentos": 8,
             "figuras_por_partida": 1, "figuras": [memoria[3], memoria[4]],
             "lineas_voz": {"intro": VOZ_FORMAS + "intro_cima_3.wav", "pista": VOZ_FORMAS + "pista_memoria_01.wav"}},
        ]))

    dorado = D.resolver_marco(["##########"] * 6, list("FILPTUVWXYZN"), 1)[0]
    escribir(NIVELES / "zona5_cima" / "formas_estrella_dorado.json", nivel_formas(
        "zona5_cima", "_dorado", mecanica="marco", modo="reto_dorado", boton_espejo=True, rotacion_por_toque=True,
        paso_rotacion=90, iman_tolerancia_px=60, marco=["##########"] * 6, lado_celda=54, limite_intentos=None,
        piezas_necesarias=12, guardar_avance=True, regalo_tras_derrotas=False,
        zona_figuras=[236, 104, 900, 360], zona_bandeja=[236, 470, 894, 238], boton_espejo_rect=[1150, 250, 110, 110],
        piezas_marco=pentominos("FILPTUVWXYZN"), solucion=solucion_marco(dorado),
        lineas_voz=voces_formas(intro="intro_dorado.wav", pista="pista_marco_01.wav", victoria_final="victoria_dorado_01.wav")))


def voces_parejas(zona_num, pista, **extra):
    voces = {
        "intro": f"{VOZ_PAREJAS}intro_z{zona_num}.wav",
        "pista": VOZ_PAREJAS + pista,
        "acierto_par": [f"{VOZ_PAREJAS}acierto_par_0{i}.wav" for i in (1, 2, 3)],
        "no_es_este": [f"{VOZ_PAREJAS}no_es_este_0{i}.wav" for i in (1, 2)],
        "acierto_especial": f"{VOZ_PAREJAS}acierto_especial_01.wav",
        "victoria_final": f"{VOZ_PAREJAS}victoria_final_01.wav",
        "derrota_gag": f"{VOZ_PAREJAS}derrota_gag_01.wav",
        "pista_usada": f"{VOZ_PAREJAS}pista_usada_01.wav",
        "regalo": f"{VOZ_PAREJAS}regalo_01.wav",
    }
    voces.update({k: VOZ_PAREJAS + v for k, v in extra.items()})
    return voces


def nivel_parejas(zona, sufijo, **datos):
    nivel = {"id_nivel": f"arcoiris_z{zona[4]}_parejas_estrella{sufijo}", "motor": "emparejar", "perfil": "estrella",
             "planeta": "arcoiris", "zona": zona, "tema": "memoria", "anfitrion_id": "coco", "fondo_id": "planeta_arcoiris",
             "dificultad": "v3 (PO 14-Sep-2026)", "modo": "identico", "oculto": True, "tiempo_volteo_ms": 900,
             "ayuda_tras_fallos": None, "halo_idle": False, "pistas_cuestan_estrellita": True, "regalo_tras_derrotas": True}
    nivel.update(datos)
    return nivel


def par(id_par, a, b, especial=False):
    salida = {"id_pareja": id_par, "elemento_a": dict(a, id=f"{id_par}_a"), "elemento_b": dict(b, id=f"{id_par}_b")}
    if especial:
        salida["especial"] = True
    return salida


def pares_identicos(lista):
    salida = [par(n, {"figura": n.split("_")[0], "color": c}, {"figura": n.split("_")[0], "color": c}) for n, c in lista]
    arcoiris = {"figura": "arcoiris", "color": "#FFFFFF"}
    salida.append(par("arcoiris_secreto", arcoiris, arcoiris, True))
    return salida


def generar_parejas():
    colores = [("estrella", "#FFCB3D"), ("estrella_rosa", "#F26CA8"), ("corazon", "#F26CA8"), ("corazon_azul", "#4A8BE0"),
               ("circulo", "#4A8BE0"), ("triangulo", "#7DD87A"), ("cuadrado", "#FF9F4A"), ("luna", "#B48CE8"),
               ("gota", "#45C6C0"), ("rombo", "#FF6B6B"), ("flor", "#FFB25B")]
    escribir(NIVELES / "zona1_claro" / "parejas_estrella.json", nivel_parejas(
        "zona1_claro", "", disposicion={"filas": 4, "columnas": 6}, limite_intentos=16, pares=pares_identicos(colores),
        lineas_voz=voces_parejas(1, "pista_01.wav")))

    rojo, amarillo, azul, blanco, negro = "#FF4B4B", "#FFD23D", "#3F7FE0", "#FFFFFF", "#2B3350"
    recetas = [("verde", "#7DD87A", [azul, amarillo]), ("naranja", "#FF9F4A", [rojo, amarillo]),
               ("violeta", "#9B6BD9", [rojo, azul]), ("rosado", "#FFB3C7", [rojo, blanco]),
               ("celeste", "#9ED8F5", [azul, blanco]), ("cafe", "#9C6B42", [rojo, amarillo, azul]),
               ("gris", "#A7A9B4", [negro, blanco]), ("lila", "#D2B8F0", ["#9B6BD9", blanco]),
               ("crema", "#FFF0A8", [amarillo, blanco]), ("verde_claro", "#C4F0B8", ["#4CC25A", blanco])]
    escribir(NIVELES / "zona2_charcos" / "parejas_estrella.json", nivel_parejas(
        "zona2_charcos", "", modo="correspondencia", disposicion={"filas": 4, "columnas": 5}, limite_intentos=15,
        pares=[par(n, {"figura": "gota", "color": c}, {"estilo": "receta", "receta": r}) for n, c, r in recetas],
        lineas_voz=voces_parejas(2, "pista_z2.wav")))

    trios = [("estrella", "#FFCB3D"), ("corazon", "#F26CA8"), ("circulo", "#4A8BE0"), ("triangulo", "#7DD87A"),
             ("luna", "#B48CE8"), ("gota", "#45C6C0"), ("flor", "#FF9F4A")]
    escribir(NIVELES / "zona3_chupetines" / "parejas_estrella.json", nivel_parejas(
        "zona3_chupetines", "", modo="trios", tamano_grupo=3, disposicion={"filas": 3, "columnas": 7}, limite_intentos=42,
        tiempo_volteo_ms=1000,
        grupos=[{"id_grupo": n, "elementos": [{"id": f"{n}_{k}", "figura": n, "color": c} for k in range(3)]} for n, c in trios],
        lineas_voz=voces_parejas(3, "pista_z3.wav")))

    catorce = colores + [("rombo_verde", "#7DD87A"), ("luna_amarilla", "#FFCB3D")]
    escribir(NIVELES / "zona4_islotes" / "parejas_estrella.json", nivel_parejas(
        "zona4_islotes", "", modo="traviesas", disposicion={"filas": 4, "columnas": 7}, limite_intentos=24,
        intercambios_tras_acierto=2, pares=pares_identicos(catorce[:13]), lineas_voz=voces_parejas(4, "pista_z4.wav")))

    sombras = [
        ("luna", {"figura": "luna", "color": "#B48CE8"}),
        ("luna_espejo", {"figura": "luna", "color": "#FFCB3D", "espejo": True}),
        ("triangulo_rect", {"forma": "triangulo_rect", "color": "#FF6B6B"}),
        ("triangulo_rect_espejo", {"forma": "triangulo_rect", "color": "#4A8BE0", "espejo": True}),
        ("paralelogramo", {"forma": "paralelogramo", "color": "#45C6C0"}),
        ("paralelogramo_espejo", {"forma": "paralelogramo", "color": "#F26CA8", "espejo": True}),
        ("gota_derecha", {"figura": "gota", "color": "#6FD6E8", "rotacion": 90}),
        ("gota_izquierda", {"figura": "gota", "color": "#7DD87A", "rotacion": 270}),
        ("semicirculo", {"forma": "semicirculo", "color": "#FF9F4A"}),
        ("semicirculo_girado", {"forma": "semicirculo", "color": "#9B6BD9", "rotacion": 90}),
        ("trapecio", {"forma": "trapecio", "color": "#FFB25B"}),
        ("trapecio_girado", {"forma": "trapecio", "color": "#B07A4F", "rotacion": 180}),
        ("estrella", {"figura": "estrella", "color": "#FFCB3D"}),
        ("corazon", {"figura": "corazon", "color": "#F26CA8"}),
        ("flor", {"figura": "flor", "color": "#FF6B6B"}),
        ("arcoiris_secreto", {"figura": "arcoiris", "color": "#FFFFFF"}),
        ("triangulo_rect_90", {"forma": "triangulo_rect", "color": "#7DD87A", "rotacion": 90}),
        ("triangulo_rect_180", {"forma": "triangulo_rect", "color": "#FFCB3D", "rotacion": 180}),
    ]

    def pares_sombra(lista):
        salida = []
        for nombre, figura in lista:
            sombra = {k: v for k, v in figura.items() if k != "color"}
            sombra["estilo"] = "sombra"
            salida.append(par(nombre, figura, sombra, nombre == "arcoiris_secreto"))
        return salida

    escribir(NIVELES / "zona5_cima" / "parejas_estrella.json", nivel_parejas(
        "zona5_cima", "", modo="sombras", disposicion={"filas": 4, "columnas": 8}, limite_intentos=32,
        tiempo_volteo_ms=800, intercambios_tras_acierto=1, pares=pares_sombra(sombras[:16]),
        lineas_voz=voces_parejas(5, "pista_z5.wav")))
    escribir(NIVELES / "zona5_cima" / "parejas_estrella_dorado.json", nivel_parejas(
        "zona5_cima", "_dorado", modo="sombras", disposicion={"filas": 4, "columnas": 9}, limite_intentos=42,
        tiempo_volteo_ms=800, intercambios_tras_acierto=2, regalo_tras_derrotas=False, pares=pares_sombra(sombras),
        lineas_voz=voces_parejas(5, "pista_z5.wav", intro="intro_dorado.wav", victoria_final="victoria_dorado_01.wav")))


if __name__ == "__main__":
    generar_formas()
    generar_parejas()
