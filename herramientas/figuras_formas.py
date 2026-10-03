"""Figuras de "Formas traviesas" (motor encajar): primero la figura, después las piezas.

Decisión del PO (27-Sep-2026): la figura final se diseña primero —algo reconocible en Chile, acorde
a la edad de cada hermano— y las piezas salen de cortarla. Así la bandeja SIEMPRE puede armar la
silueta: cada pieza es un trozo real del dibujo.

Cada figura se escribe en px de pantalla (esquina superior izquierda de la caja de cada pieza), con
formas primitivas del motor (geometria_formas.gd). El script:

1. Valida cada figura: sin solapes, sin piezas sueltas (salvo `permitir_sueltas`), que quepa en el
   tablero (640x590) y cada pieza en la bandeja (366x440), lado mínimo por perfil, y que dos piezas
   con la misma geometría tengan el mismo color (el motor calza por geometría: serían
   intercambiables y la figura terminada quedaría con colores cruzados). Avisa de piezas "casi
   iguales" (confundibles) que no son intercambiables.
2. Dibuja una vista previa PNG (figura armada + piezas sueltas) en la carpeta indicada.
3. Con --escribir, reescribe los niveles `datos/niveles/arcoiris/<zona>/formas_<perfil>.json`.

Rondas (PO 27-Sep-2026): cada estación es una serie de rondas, una figura a la vez, sorteadas de un
pool por zona (`ESTACIONES`): Maxi 4 rondas de ~6 figuras, Nicole 3 de ~5 y Sofía 2 (un monumento
de Chile y una bandera). Las banderas usan colores y proporciones oficiales; los emblemas (estrella de
Chile, disco de Japón, sol de Argentina) son piezas de `capa` 1+ que van ENCIMA del fondo, y las
franjas iguales de distinto color se distinguen con `exigir_color` (cada franja en su color).

Uso:
    python herramientas/figuras_formas.py --previas <carpeta> [--escribir]
"""

import argparse
import json
import math
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NIVELES = os.path.join(RAIZ, "datos", "niveles", "arcoiris")
TABLERO = (640, 590)
BANDEJA_UTIL = (366 - 32, 440 - 32)  # ZONA_BANDEJA menos RELLENO_BANDEJA a cada lado
LADO_MINIMO = {"semilla": 96, "brote": 52, "estrella": 22}  # los mismos de qa_test_encajar.gd
TOLERANCIA_CALCE = 0.1
# Nada de bichos en ningun nivel, fondo o transicion donde juegue Nicole (le dan miedo) ni Sofia
# (rechazo): perfil-jugadores.md y auditoria UX HE-40 (R1). Como todo esta desbloqueado entre hermanos,
# vale para los tres perfiles. El validador corta si una figura o su voz nombra alguno.
PROHIBIDOS = ("mariposa", "abeja", "arana", "araña", "bicho", "insecto", "catarina", "chinita", "gusano",
              "hormiga", "mosca", "libelula", "escarabajo", "grillo", "caracol")

# ---------------------------------------------------------------------------
# Primitivas (x, y = esquina superior izquierda de la caja YA girada, en px)
# ---------------------------------------------------------------------------

ORIENTACION = {"◣": 0, "◤": 90, "◥": 180, "◢": 270}


def _pieza(forma, x, y, w, h, color, rotacion=0, **extra):
    # ancho/alto son la caja SIN girar: a 90° y 270° se intercambian.
    ancho, alto = (h, w) if rotacion in (90, 270) else (w, h)
    p = {"forma": forma, "ancho": ancho, "alto": alto, "color": color, "cx": x + w / 2, "cy": y + h / 2}
    if rotacion:
        p["rotacion"] = rotacion
    p.update(extra)
    return p


def R(x, y, w, h, color, **extra):
    return _pieza("cuadrado" if w == h else "rectangulo", x, y, w, h, color, **extra)


def T(x, y, w, h, color, abajo=False, **extra):
    """Triángulo isósceles con la punta arriba (o abajo)."""
    return _pieza("triangulo", x, y, w, h, color, 180 if abajo else 0, **extra)


def TR(x, y, w, h, color, orientacion, **extra):
    """Triángulo rectángulo; `orientacion` dice dónde queda el ángulo recto: ◣ ◤ ◥ ◢."""
    return _pieza("triangulo_rect", x, y, w, h, color, ORIENTACION[orientacion], **extra)


def TP(x, y, w, h, color, invertido=False, **extra):
    """Trapecio: lado corto = 60 % del largo. Normal: corto arriba. Invertido: corto abajo."""
    return _pieza("trapecio", x, y, w, h, color, 180 if invertido else 0, **extra)


def C(x, y, d, color, **extra):
    return _pieza("circulo", x, y, d, d, color, **extra)


def E(x, y, d, color, **extra):
    return _pieza("estrella", x, y, d, d, color, **extra)


def O(x, y, w, h, color, **extra):
    return _pieza("ovalo", x, y, w, h, color, **extra)


def RB(x, y, w, h, color, **extra):
    return _pieza("rombo", x, y, w, h, color, **extra)


ABIERTO = {"abajo": 0, "izquierda": 90, "arriba": 180, "derecha": 270}


def SC(x, y, w, h, color, plano="abajo", **extra):
    """Semicírculo (media elipse); `plano` dice de qué lado queda el lado recto."""
    return _pieza("semicirculo", x, y, w, h, color, ABIERTO[plano], **extra)


def P(forma, cx, cy, ancho, alto, color, rotacion=0, **extra):
    """Pieza por su CENTRO y su caja sin girar (para giros que no son múltiplos de 90°)."""
    p = {"forma": forma, "ancho": ancho, "alto": alto, "color": color, "cx": cx, "cy": cy}
    if rotacion:
        p["rotacion"] = rotacion
    p.update(extra)
    return p


# ---------------------------------------------------------------------------
# Geometría (misma que geometria_formas.gd)
# ---------------------------------------------------------------------------


def contorno(forma, ancho, alto):
    mx, my = ancho / 2, alto / 2
    if forma in ("cuadrado", "rectangulo"):
        return [(-mx, -my), (mx, -my), (mx, my), (-mx, my)]
    if forma == "triangulo":
        return [(0, -my), (mx, my), (-mx, my)]
    if forma == "triangulo_rect":
        return [(-mx, -my), (mx, my), (-mx, my)]
    if forma == "trapecio":
        return [(-mx * 0.6, -my), (mx * 0.6, -my), (mx, my), (-mx, my)]
    if forma == "rombo":
        return [(0, -my), (mx, 0), (0, my), (-mx, 0)]
    if forma == "semicirculo":
        return [(math.cos(math.pi + math.pi * i / 24) * mx, my + math.sin(math.pi + math.pi * i / 24) * alto) for i in range(25)]
    if forma == "estrella":
        return [(math.cos(-math.pi / 2 + i * math.pi / 5) * (0.98 if i % 2 == 0 else 0.47) * mx,
                 math.sin(-math.pi / 2 + i * math.pi / 5) * (0.98 if i % 2 == 0 else 0.47) * my) for i in range(10)]
    return [(math.cos(2 * math.pi * i / 48) * mx, math.sin(2 * math.pi * i / 48) * my) for i in range(48)]


def girado(puntos, grados):
    a = math.radians(grados)
    c, s = math.cos(a), math.sin(a)
    return [(x * c - y * s, x * s + y * c) for x, y in puntos]


def poligono(p):
    return [(x + p["cx"], y + p["cy"]) for x, y in girado(contorno(p["forma"], p["ancho"], p["alto"]), p.get("rotacion", 0))]


def area(P):
    return abs(sum(P[i][0] * P[i - 1][1] - P[i - 1][0] * P[i][1] for i in range(len(P)))) / 2


def adentro(x, y, P):
    r = False
    for i in range(len(P)):
        x1, y1 = P[i]
        x2, y2 = P[i - 1]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            r = not r
    return r


def caja(P):
    xs = [x for x, _ in P]
    ys = [y for _, y in P]
    return min(xs), min(ys), max(xs), max(ys)


def diferencia_formas(a, b, rotaciones):
    """0 = misma forma (con alguno de los giros permitidos de `a`), 1 = nada en común. Por muestreo."""
    mejor = 1.0
    base_b = girado(contorno(b["forma"], b["ancho"], b["alto"]), b.get("rotacion", 0))
    for g in rotaciones:
        base_a = girado(contorno(a["forma"], a["ancho"], a["alto"]), g)
        x0, y0, x1, y1 = caja(base_a + base_b)
        paso = max(x1 - x0, y1 - y0) / 60
        en_a = en_b = comun = 0
        y = y0 + paso / 2
        while y < y1:
            x = x0 + paso / 2
            while x < x1:
                ia, ib = adentro(x, y, base_a), adentro(x, y, base_b)
                en_a += ia
                en_b += ib
                comun += ia and ib
                x += paso
            y += paso
        mejor = min(mejor, 1 - comun / max(en_a, en_b, 1))
    return mejor


# ---------------------------------------------------------------------------
# Figuras
# ---------------------------------------------------------------------------

# Paleta "peluche pintado" del juego.
ROJO, NARANJO, AMARILLO, VERDE, CELESTE, AZUL, LILA, ROSADO, TURQUESA = (
    "#FF6B6B", "#FF9F4A", "#FFCB3D", "#7DD87A", "#6FD6E8", "#4A8BE0", "#B48CE8", "#F26CA8", "#45C6C0")
CAFE, BLANCO, GRIS, NOCHE = "#A8744F", "#FFF8EE", "#B9B4C8", "#5B3F8C"


def iglesia_chiloe():
    """Sofía, zona 1 (25 piezas, sin giro): iglesia de Castro, amarilla y lila, con torre y pórtico."""
    fachada, lila, ventana, columna, gradas = "#FFD24D", "#9B6BD9", NOCHE, "#FFF1C2", GRIS
    p = [
        T(180, 0, 60, 100, lila),                       # aguja de la torre
        R(180, 100, 60, 50, fachada),                   # campanario alto
        R(165, 150, 25, 60, fachada), R(190, 150, 40, 60, ventana), R(230, 150, 25, 60, fachada),
        R(155, 210, 110, 70, fachada),                  # base de la torre
        TR(15, 210, 140, 70, lila, "◢"), TR(265, 210, 140, 70, lila, "◣"),   # techo a dos aguas
        R(15, 280, 155, 50, fachada), R(170, 280, 80, 50, ventana), R(250, 280, 155, 50, fachada),
        R(15, 330, 195, 20, lila), R(210, 330, 195, 20, lila),                # cornisa
    ]
    x = 15
    for i in range(9):                                  # pórtico: 5 columnas y 4 arcos
        ancho = 22 if i % 2 == 0 else 70
        p.append(R(x, 350, ancho, 110, columna if i % 2 == 0 else ventana))
        x += ancho
    p += [R(0, 460, 140, 22, gradas), R(140, 460, 140, 22, gradas), R(280, 460, 140, 22, gradas)]
    return p


def palafitos():
    """Sofía, zona 2 (27 piezas, con giro): tres palafitos de Castro sobre el agua."""
    madera = CAFE
    p = []
    # Casa rosada: paredes 40x160.
    p += [T(0, 80, 130, 70, ROJO), R(0, 150, 40, 160, ROSADO), R(40, 150, 50, 70, BLANCO), R(40, 220, 50, 90, ROSADO),
          R(90, 150, 40, 160, ROSADO)]
    # Casa turquesa (la alta, con puerta): paredes 45x200.
    p += [T(130, 30, 150, 80, AZUL), R(130, 110, 45, 200, TURQUESA), R(175, 110, 60, 55, BLANCO),
          R(175, 165, 60, 45, TURQUESA), R(175, 210, 60, 100, NOCHE), R(235, 110, 45, 200, TURQUESA)]
    # Casa amarilla (la baja y angosta, techo de una agua): paredes 40x120.
    p += [TR(280, 120, 120, 70, LILA, "◢"),        # techo de una sola agua
          R(280, 190, 40, 120, AMARILLO), R(320, 190, 40, 50, BLANCO),
          R(320, 240, 40, 70, AMARILLO), R(360, 190, 40, 120, AMARILLO)]
    p += [R(0, 310, 200, 16, madera), R(200, 310, 200, 16, madera)]             # muelle
    for x in (8, 58, 108, 146, 198, 250, 290, 334, 378):                       # pilotes
        p.append(R(x, 326, 16, 64, madera))
    return p


def santiago():
    """Sofía, zona 3 (25 piezas, con giro): Costanera Center, Torre Entel y la cordillera."""
    nieve, cerro, vidrio, vidrio_osc = BLANCO, "#9C8CC8", "#8FD0F5", AZUL
    p = [
        T(34, 160, 102, 120, nieve), TP(0, 280, 170, 80, cerro),                # cerro nevado
        R(0, 360, 50, 100, "#FF9F80"), R(50, 360, 70, 100, AMARILLO), R(120, 360, 50, 100, "#FF9F80"),
        T(190, 20, 20, 40, ROJO), R(190, 60, 20, 70, BLANCO),                   # antena de la Entel
        R(160, 130, 80, 36, "#E0E4F0"), R(185, 166, 30, 294, "#C8CDE0"),        # disco y torre Entel
        TP(295, 40, 90, 60, vidrio_osc, invertido=True),                        # corona de la Costanera
    ]
    p += [R(230, y, 65, 40, CELESTE) for y in (300, 340, 380, 420)]            # edificio de 4 pisos
    for y in (100, 172, 244, 316, 388):                                         # cuerpo de vidrio
        p.append(R(313, y, 54, 72, vidrio))
    p += [R(367, 340, 50, 60, ROSADO), R(367, 400, 50, 60, ROSADO)]
    p += [R(0, 460, 139, 20, GRIS), R(139, 460, 139, 20, GRIS), R(278, 460, 139, 20, GRIS)]   # calle
    return p


def moais():
    """Sofía, zona 4 (28 piezas, con giro): moáis de Rapa Nui sobre su ahu."""
    piedra, piedra2, sombra, pukao = "#9A938C", "#857E77", "#5E5853", "#C8553D"
    p = []
    top = 70  # todas las caras parten a la misma altura: los cuerpos llegan juntos al ahu (y = 310)
    for i, x in enumerate((0, 110, 220)):
        if i != 1:
            p.append(R(x + 12, top - 30, 56, 30, pukao))                # sombrero rojo (pukao)
        p += [
            R(x, top, 80, 34, piedra),                                  # frente
            R(x, top + 34, 24, 28, sombra), R(x + 24, top + 34, 32, 28, piedra), R(x + 56, top + 34, 24, 28, sombra),
            R(x, top + 62, 80, 76, piedra),                             # nariz larga y mejillas
            R(x, top + 138, 80, 16, sombra),                            # boca
            R(x, top + 154, 80, 34, piedra),                            # mentón (igual a la frente)
            R(x - 5, top + 188, 90, 52, piedra2),                       # hombros
        ]
    p += [R(-15, 310, 160, 36, "#7A6E63"), R(145, 310, 160, 36, "#7A6E63")]            # ahu (plataforma)
    return p


def castillo():
    """Sofía, zona 5 (30 piezas, con giro): Castillo Hidalgo en la cima del cerro Santa Lucía."""
    piedra, piedra2, techo, ventana, pasto = "#E8D7B8", "#D9C39C", AZUL, NOCHE, VERDE
    p = []
    for x in (88, 292):                                                          # torres con techo
        p += [T(x - 8, 130, 76, 70, techo),
              R(x, 200, 20, 110, piedra), R(x + 20, 200, 20, 45, ventana), R(x + 20, 245, 20, 65, piedra),
              R(x + 40, 200, 20, 110, piedra), R(x, 310, 60, 110, piedra2)]
    p += [R(190, 190, 20, 110, piedra), R(210, 190, 20, 40, ventana), R(210, 230, 20, 70, piedra),
          R(230, 190, 20, 110, piedra)]                                          # torre del homenaje
    p += [R(x, 170, 17, 20, piedra) for x in (190, 233)]                    # almenas del homenaje
    p += [R(x, 280, 17, 20, piedra) for x in (148, 173, 250, 275)]               # almenas de la muralla
    p += [R(148, 300, 42, 120, piedra2), R(190, 300, 60, 40, piedra2), R(190, 340, 60, 80, CAFE),
          R(250, 300, 42, 120, piedra2)]                                         # muralla y portón
    p += [TR(8, 420, 80, 80, pasto, "◢"), R(88, 420, 132, 80, pasto), R(220, 420, 132, 80, pasto), TR(352, 420, 80, 80, pasto, "◣")]  # cerro
    return p


# --- Nicole (Brote): 6 a 9 piezas, nombre de la forma por voz ---

def casita_nicole():
    return [T(0, 0, 260, 110, ROJO, nombre_voz="triangulo"),
            R(10, 110, 70, 180, ROSADO, nombre_voz="rectangulo"),
            R(80, 110, 100, 60, AMARILLO, nombre_voz="rectangulo_chico"),
            R(80, 170, 100, 120, CAFE, nombre_voz="rectangulo_grande"),
            R(180, 110, 70, 70, CELESTE, nombre_voz="cuadrado"),
            R(180, 180, 70, 110, ROSADO, nombre_voz="rectangulo")]


def micro():
    return [R(0, 0, 80, 60, CELESTE, nombre_voz="rectangulo"), R(80, 0, 80, 60, CELESTE, nombre_voz="rectangulo"),
            R(160, 0, 80, 60, CELESTE, nombre_voz="rectangulo"), R(240, 0, 60, 60, "#BDEBFA", nombre_voz="cuadrado_chico"),
            R(0, 60, 300, 80, AMARILLO, nombre_voz="rectangulo_grande"),
            C(30, 140, 76, NOCHE, nombre_voz="circulo", decoracion="rueda"),
            C(194, 140, 76, NOCHE, nombre_voz="circulo", decoracion="rueda")]


def faro():
    return [T(20, 0, 80, 60, ROJO, nombre_voz="triangulo"),
            R(30, 60, 60, 50, AMARILLO, nombre_voz="cuadrado_chico"),
            R(0, 110, 120, 44, NOCHE, nombre_voz="rectangulo"),
            R(15, 154, 90, 80, ROJO, nombre_voz="rectangulo"),
            R(15, 234, 90, 56, BLANCO, nombre_voz="rectangulo_chico"),
            R(15, 290, 90, 80, ROJO, nombre_voz="rectangulo"),
            TP(-20, 370, 160, 56, GRIS, nombre_voz="trapecio")]


def tren():
    return [TP(50, 0, 90, 50, NOCHE, invertido=True, nombre_voz="trapecio"),
            R(73, 50, 44, 50, NOCHE, nombre_voz="rectangulo_chico"),
            R(0, 100, 240, 110, ROJO, nombre_voz="rectangulo_grande"),
            R(230, 10, 160, 44, AZUL, nombre_voz="rectangulo"),
            R(240, 54, 140, 156, AZUL, nombre_voz="rectangulo_grande"),
            C(15, 210, 70, NOCHE, nombre_voz="circulo_chico", decoracion="rueda"),
            C(125, 210, 70, NOCHE, nombre_voz="circulo_chico", decoracion="rueda"),
            C(255, 210, 110, NOCHE, nombre_voz="circulo_grande", decoracion="rueda")]


# --- Maxi (Semilla): 3-4 piezas gigantes, color guía ---

def casita_maxi():
    return [T(0, 0, 280, 130, ROJO), R(40, 130, 200, 200, AZUL),
            C(300, 0, 130, AMARILLO, cara=True)]


def barquito():
    return [TR(30, 0, 130, 180, BLANCO, "◢"), TR(160, 0, 130, 180, AMARILLO, "◣"),
            TP(0, 180, 320, 110, ROJO, invertido=True)]


def pino():
    # Las capas encajan borde con borde: la base del triángulo = el lado corto del trapecio.
    return [E(120, 0, 140, AMARILLO, cara=True), T(95, 124, 190, 120, VERDE), TP(31.5, 244, 317, 130, VERDE),
            R(140, 374, 100, 100, CAFE)]


def monito_nieve():
    return [C(35, 0, 130, BLANCO, cara=True), C(0, 130, 200, BLANCO), R(200, 180, 150, 150, ROJO),
            R(50, -100, 100, 100, NOCHE)]



# ---------------------------------------------------------------------------
# Banderas (PO 27-Sep-2026): colores oficiales y proporciones correctas.
# ---------------------------------------------------------------------------
# Emblemas complejos simplificados con respeto: el sol de Argentina y Uruguay es un círculo dorado,
# los escudos son una forma simple. Van en `capa` 1+ (encima del fondo). Las franjas del mismo tamaño
# y distinto color piden `exigir_color` (config de la bandera).

BLANCO_B = "#FFFFFF"
CHILE_AZUL, CHILE_ROJO = "#0039A6", "#D52B1E"


def _cortes(largo, partes):
    """Reparte `largo` en trozos proporcionales a `partes` (que suman lo que sea)."""
    total = float(sum(partes))
    return [largo * p / total for p in partes]


def franjas(x0, y0, ancho, alto, colores, horizontal=True, cortes=None, voces=None):
    """Franjas iguales; `cortes[i]` parte la franja i en trozos (proporciones) a lo largo."""
    p = []
    n = len(colores)
    for i, color in enumerate(colores):
        trozos = cortes[i] if cortes else [1]
        extra = {"nombre_voz": voces[i]} if voces else {}
        if horizontal:
            alto_f = alto / n
            x = x0
            for largo in _cortes(ancho, trozos):
                p.append(R(x, y0 + i * alto_f, largo, alto_f, color, **extra))
                x += largo
        else:
            ancho_f = ancho / n
            y = y0
            for largo in _cortes(alto, trozos):
                p.append(R(x0 + i * ancho_f, y, ancho_f, largo, color, **extra))
                y += largo
    return p


def rejilla(x0, y0, anchos, altos, color, **extra):
    """Rectángulo cortado en una grilla irregular (columnas `anchos` x filas `altos`, en px)."""
    p = []
    y = y0
    for h in altos:
        x = x0
        for w in anchos:
            p.append(R(x, y, w, h, color, **extra))
            x += w
        y += h
    return p


def chile(u, corte_blanco=(1,), corte_rojo=(1,), voz=False):
    """Chile 2:3: cuadrado azul (u), franja blanca (2u), franja roja (3u) y la estrella (diámetro u/2)."""
    v = (lambda c: {"nombre_voz": c}) if voz else (lambda c: {})
    p = [R(0, 0, u, u, CHILE_AZUL, **v("color_azul"))]
    x = u
    for largo in _cortes(2 * u, corte_blanco):
        p.append(R(x, 0, largo, u, BLANCO_B, **v("color_blanco")))
        x += largo
    x = 0
    for largo in _cortes(3 * u, corte_rojo):
        p.append(R(x, u, largo, u, CHILE_ROJO, **v("color_rojo")))
        x += largo
    d = u / 2
    p.append(E(u / 2 - d / 2, u / 2 - d / 2, d, BLANCO_B, capa=1, emblema=True, **v("estrella")))
    return p


def japon(anchos, altos, voz=False):
    """Japón 2:3: fondo blanco (cortado en grilla) y el disco rojo (3/5 del alto) al centro."""
    ancho, alto = sum(anchos), sum(altos)
    extra = {"nombre_voz": "color_blanco"} if voz else {}
    p = rejilla(0, 0, anchos, altos, BLANCO_B, **extra)
    d = alto * 0.6
    p.append(C(ancho / 2 - d / 2, alto / 2 - d / 2, d, "#BC002D", capa=1, **({"nombre_voz": "circulo_rojo"} if voz else {})))
    return p


def tricolor_vertical(ancho, alto, colores, cortes=None, voces=None):
    return franjas(0, 0, ancho, alto, colores, horizontal=False, cortes=cortes, voces=voces)


def tricolor_horizontal(ancho, alto, colores, cortes=None, voces=None):
    return franjas(0, 0, ancho, alto, colores, horizontal=True, cortes=cortes, voces=voces)


FRANCIA = ("#0055A4", BLANCO_B, "#EF4135")
ITALIA = ("#009246", BLANCO_B, "#CE2B37")
PERU = ("#D91023", BLANCO_B, "#D91023")
ALEMANIA = ("#222222", "#DD0000", "#FFCE00")
BOLIVIA = ("#D52B1E", "#F9E300", "#007934")
RUSIA = (BLANCO_B, "#0039A6", "#D52B1E")
INDIA = ("#FF9933", BLANCO_B, "#138808")
MEXICO = ("#006847", BLANCO_B, "#CE1126")
ARG_CELESTE, SOL_DORADO = "#74ACDF", "#F6B40E"
COLOR_VOZ = {"#0055A4": "color_azul", "#0039A6": "color_azul", BLANCO_B: "color_blanco", "#EF4135": "color_rojo",
             "#009246": "color_verde", "#CE2B37": "color_rojo", "#D91023": "color_rojo", "#222222": "color_negro",
             "#DD0000": "color_rojo", "#FFCE00": "color_amarillo", "#D52B1E": "color_rojo", "#F9E300": "color_amarillo",
             "#007934": "color_verde", ARG_CELESTE: "color_celeste", "#FCD116": "color_amarillo", "#003893": "color_azul",
             "#CE1126": "color_rojo", "#009C3B": "color_verde", "#FFDF00": "color_amarillo"}


def _voces(colores):
    return [COLOR_VOZ[c] for c in colores]


def argentina(alto, cortes=None, d_sol=None, voz=False):
    """Argentina 9:14: celeste, blanca y celeste; el Sol de Mayo simplificado en un círculo dorado."""
    ancho = alto * 14 / 9
    colores = (ARG_CELESTE, BLANCO_B, ARG_CELESTE)
    p = tricolor_horizontal(ancho, alto, colores, cortes, _voces(colores) if voz else None)
    d = d_sol or alto / 3 * 0.78
    p.append(C(ancho / 2 - d / 2, alto / 2 - d / 2, d, SOL_DORADO, capa=1, **({"nombre_voz": "sol_dorado"} if voz else {})))
    return p


def colombia(ancho, alto, cortes=(1, 1, 1), voz=False, escudo=False):
    """Colombia (y Ecuador con `escudo`) 2:3: amarillo la mitad, azul y rojo un cuarto cada uno."""
    colores = ("#FCD116", "#003893", "#CE1126")
    altos = (alto / 2, alto / 4, alto / 4)
    p = []
    y = 0
    for color, h, corte in zip(colores, altos, cortes):
        x = 0
        for largo in _cortes(ancho, corte):
            p.append(R(x, y, largo, h, color, **({"nombre_voz": COLOR_VOZ[color]} if voz else {})))
            x += largo
        y += h
    if escudo:
        # Escudo de Ecuador simplificado: un óvalo celeste con borde dorado (el cóndor queda fuera).
        p.append(O(ancho / 2 - 34, alto / 2 - 44, 68, 88, "#E8B93A", capa=1))
        p.append(O(ancho / 2 - 24, alto / 2 - 32, 48, 64, "#8FD0F5", capa=2))
    return p


def brasil(ancho, cortes_verde, voz=False):
    """Brasil 7:10 (20 x 14 módulos): rombo amarillo a 1,7 módulos del borde y el globo azul (radio 3,5)."""
    alto = ancho * 0.7
    m = ancho / 20
    p = rejilla(0, 0, _cortes(ancho, cortes_verde[0]), _cortes(alto, cortes_verde[1]), "#009C3B",
                **({"nombre_voz": "color_verde"} if voz else {}))
    x0, y0, x1, y1 = 1.7 * m, 1.7 * m, ancho - 1.7 * m, alto - 1.7 * m
    cx, cy = ancho / 2, alto / 2
    w, h = cx - x0, cy - y0
    extra = {"nombre_voz": "color_amarillo"} if voz else {}
    p += [TR(x0, y0, w, h, "#FFDF00", "◢", capa=1, **extra), TR(cx, y0, w, h, "#FFDF00", "◣", capa=1, **extra),
          TR(x0, cy, w, h, "#FFDF00", "◥", capa=1, **extra), TR(cx, cy, w, h, "#FFDF00", "◤", capa=1, **extra)]
    d = 7 * m
    p.append(C(cx - d / 2, cy - d / 2, d, "#002776", capa=2, **({"nombre_voz": "circulo_azul"} if voz else {})))
    return p


def uruguay():
    """Uruguay 2:3: 9 franjas blancas y azules; cuadro blanco de 5 franjas con el Sol de Mayo."""
    alto = 306.0
    ancho = alto * 1.5
    f = alto / 9
    lado = 5 * f
    azul = "#0038A8"
    p = [R(0, 0, lado, lado, BLANCO_B)]
    for i in range(9):
        color = BLANCO_B if i % 2 == 0 else azul
        if i < 5:
            p.append(R(lado, i * f, ancho - lado, f, color))
        else:
            mitad = [ancho * 0.46, ancho * 0.54] if i % 2 else [ancho * 0.54, ancho * 0.46]
            p += [R(0, i * f, mitad[0], f, color), R(mitad[0], i * f, mitad[1], f, color)]
    d = lado * 0.62
    p.append(C(lado / 2 - d / 2, lado / 2 - d / 2, d, SOL_DORADO, capa=1))
    return p


def paraguay():
    """Paraguay 3:5: roja, blanca y azul; el escudo simplificado (círculo verde con estrella dorada)."""
    ancho, alto = 450.0, 270.0
    p = tricolor_horizontal(ancho, alto, ("#D52B1E", BLANCO_B, "#0038A8"), cortes=[(3, 4, 3), (4, 2, 4), (3, 4, 3)])
    d = 78
    p.append(C(ancho / 2 - d / 2, alto / 2 - d / 2, d, "#3A8F3A", capa=1))
    p.append(E(ancho / 2 - 20, alto / 2 - 20, 40, "#FFCB3D", capa=2))
    return p


def venezuela():
    """Venezuela 2:3: amarilla, azul y roja con 8 estrellas blancas en arco (bandera civil, sin escudo)."""
    ancho, alto = 450.0, 300.0
    p = tricolor_horizontal(ancho, alto, ("#FFCC00", "#00247D", "#CF142B"), cortes=[(3, 4, 3), (4, 3, 4), (3, 4, 3)])
    cx, cy, radio, d = ancho / 2, 212.0, 82.0, 26.0
    for k in range(8):
        a = math.radians(205 + k * (130 / 7))
        x, y = cx + radio * math.cos(a), cy + radio * math.sin(a)
        p.append(E(x - d / 2, y - d / 2, d, BLANCO_B, capa=1))
    return p


def china():
    """China 2:3 (30 x 20 módulos): estrella grande (radio 3) y cuatro chicas (radio 1), sin girar."""
    m = 15.0
    p = rejilla(0, 0, [130, 160, 160], [95, 110, 95], "#DE2910")
    amarillo = "#FFDE00"
    p.append(E(5 * m - 3 * m, 5 * m - 3 * m, 6 * m, amarillo, capa=1))
    for cx, cy in ((10, 2), (12, 4), (12, 7), (10, 9)):
        p.append(E(cx * m - m, cy * m - m, 2 * m, amarillo, capa=1))
    return p


def eeuu():
    """EE.UU. 10:19: 13 franjas (cortadas para caber en la bandeja), cuadro azul y 5 estrellas
    (simplificación: la bandera real tiene 50)."""
    alto = 299.0
    ancho = alto * 1.9
    f = alto / 13
    canton_w, canton_h = alto * 0.76, 7 * f
    rojo, azul = "#B22234", "#3C3B6E"
    p = [R(0, 0, canton_w, canton_h, azul)]
    for i in range(13):
        color = rojo if i % 2 == 0 else BLANCO_B
        if i < 7:
            resto = ancho - canton_w
            partes = [0.47, 0.53] if i % 2 == 0 else [0.53, 0.47]
            x = canton_w
            for largo in _cortes(resto, partes):
                p.append(R(x, i * f, largo, f, color))
                x += largo
        else:
            partes = [0.5, 0.5] if i % 2 == 0 else [0.45, 0.55]
            x = 0
            for largo in _cortes(ancho, partes):
                p.append(R(x, i * f, largo, f, color))
                x += largo
    d = 30
    for cx, cy in ((0.25, 0.28), (0.75, 0.28), (0.5, 0.5), (0.25, 0.72), (0.75, 0.72)):
        p.append(E(canton_w * cx - d / 2, canton_h * cy - d / 2, d, BLANCO_B, capa=1))
    return p


def india():
    ancho, alto = 450.0, 300.0
    p = tricolor_horizontal(ancho, alto, INDIA, cortes=[(4, 3, 4, 3), (3, 4, 3, 4), (4, 3, 4, 3)])
    d = 76
    # Chakra de Ashoka simplificada: rueda azul marino.
    p.append(C(ancho / 2 - d / 2, alto / 2 - d / 2, d, "#000080", capa=1))
    return p


def mexico():
    """México 4:7: verde, blanca y roja; el escudo simplificado (águila café sobre un nopal verde)."""
    ancho, alto = 476.0, 272.0
    p = tricolor_vertical(ancho, alto, MEXICO, cortes=[(3, 4, 3, 4), (4, 3, 4, 3), (3, 4, 3, 4)])
    cx, cy = ancho / 2, alto / 2
    p.append(O(cx - 36, cy - 48, 72, 80, "#8B5A2B", capa=1))
    p.append(SC(cx - 42, cy + 32, 84, 30, "#3F9B45", plano="arriba", capa=1))
    return p


# --- Banderas por perfil ---

def f_japon_maxi():
    return japon([225, 225], [300])


def f_francia_maxi():
    return tricolor_vertical(450, 300, FRANCIA)


def f_italia_maxi():
    return tricolor_vertical(450, 300, ITALIA)


def f_peru_maxi():
    return tricolor_vertical(450, 300, PERU)


def f_chile_maxi():
    # u = 150: la franja roja se corta en dos para caber en la bandeja; estrella de 75 px (emblema).
    return chile(150, corte_rojo=(1, 1))


def f_francia_nicole():
    return tricolor_vertical(390, 260, FRANCIA, cortes=[(1, 1)] * 3, voces=_voces(FRANCIA))


def f_italia_nicole():
    return tricolor_vertical(390, 260, ITALIA, cortes=[(1, 1)] * 3, voces=_voces(ITALIA))


def f_peru_nicole():
    return tricolor_vertical(390, 260, PERU, cortes=[(1, 1)] * 3, voces=_voces(PERU))


def f_colombia_nicole():
    return colombia(420, 280, cortes=((1, 1), (1, 1), (1, 1)), voz=True)


def f_chile_nicole():
    return chile(130, corte_blanco=(1, 1), corte_rojo=(1, 1), voz=True)


def f_japon_nicole():
    return japon([130, 130, 130], [130, 130], voz=True)


def f_argentina_nicole():
    return argentina(270, cortes=[(1, 1)] * 3, voz=True)


def f_alemania_nicole():
    return tricolor_horizontal(400, 240, ALEMANIA, cortes=[(1, 1)] * 3, voces=_voces(ALEMANIA))


def f_brasil_nicole():
    return brasil(400, ((1, 1), (1,)), voz=True)


def f_bolivia_nicole():
    return tricolor_horizontal(440, 300, BOLIVIA, cortes=[(1, 1)] * 3, voces=_voces(BOLIVIA))


# Sofía: más piezas, trozos de largos parecidos (hay que mirar bien la tarjeta).
def f_chile_sofia():
    return chile(160, corte_blanco=(7, 8, 8, 9), corte_rojo=(7, 9, 8, 8, 7, 9))


def f_argentina_sofia():
    return argentina(270, cortes=[(10, 11, 10, 11), (11, 12, 11), (11, 10, 11, 10)])


def f_peru_sofia():
    return tricolor_vertical(420, 280, PERU, cortes=[(6, 8, 7, 7), (7, 6, 8), (8, 7, 7, 6)])


def f_bolivia_sofia():
    return tricolor_horizontal(440, 300, BOLIVIA, cortes=[(10, 12, 11, 11), (11, 10, 12), (12, 11, 10, 11)])


def f_brasil_sofia():
    return brasil(420, ((6, 7, 7), (1, 1)))


def f_colombia_sofia():
    return colombia(420, 280, cortes=((13, 15, 14), (10, 11, 10, 11), (11, 10, 11, 10)))


def f_ecuador_sofia():
    return colombia(420, 280, cortes=((14, 13, 15), (11, 10, 11, 10), (10, 11, 10, 11)), escudo=True)


def f_japon_sofia():
    return japon([120, 150, 150], [90, 100, 90])


def f_francia_sofia():
    return tricolor_vertical(420, 280, FRANCIA, cortes=[(6, 8, 7, 7), (8, 6, 7, 7), (7, 7, 8, 6)])


def f_alemania_sofia():
    return tricolor_horizontal(450, 270, ALEMANIA, cortes=[(10, 12, 11, 12), (12, 11, 12, 10), (11, 10, 12, 12)])


def f_rusia_sofia():
    return tricolor_horizontal(420, 280, RUSIA, cortes=[(10, 12, 11, 12), (12, 10, 12, 11), (11, 12, 10, 12)])


# ---------------------------------------------------------------------------
# Maxi (Semilla): figuras nuevas de 3-4 piezas gigantes (lado >= 96 px)
# ---------------------------------------------------------------------------

def helado():
    return [T(60, 250, 180, 230, "#E8A15A", abajo=True), C(55, 60, 190, ROSADO, cara=True), C(80, -80, 140, "#FFC2DC")]


def pez():
    return [O(0, 0, 260, 160, NARANJO, cara=True), P("triangulo", -55, 80, 140, 110, AMARILLO, 90),
            T(75, -96, 110, 96, AMARILLO)]


def tortuga():
    return [SC(0, 0, 300, 150, VERDE), R(30, 150, 96, 96, "#B8E07A"), R(174, 150, 96, 96, "#B8E07A"),
            C(270, 150, 100, "#B8E07A", cara=True)]


def micro_maxi():
    return [R(0, 0, 320, 150, AZUL, decoracion="ventanas", cara=True), C(40, 150, 100, NOCHE, decoracion="rueda"),
            C(180, 150, 100, NOCHE, decoracion="rueda")]


def pato():
    return [O(0, 60, 260, 150, AMARILLO), C(160, -46.3, 120, AMARILLO, cara=True), P("triangulo", 328, 13.7, 96, 96, NARANJO, 90)]


def ballena():
    return [SC(0, 60, 300, 150, AZUL, cara=True), TR(300, 110, 96, 100, AZUL, "◣"), T(102, -36, 96, 96, CELESTE, abajo=True)]


def cohete_maxi():
    return [T(100, 0, 120, 110, ROJO), R(100, 110, 120, 200, CELESTE, cara=True),
            TR(4, 210, 96, 100, ROJO, "◢"), TR(220, 210, 96, 100, ROJO, "◣")]


def volcan_osorno():
    return [T(60, 0, 180, 160, BLANCO), TP(0, 160, 300, 107, "#8C7BB8"), R(-10, 267, 320, 96, AZUL)]


def camion_bomberos():
    return [R(200, 0, 100, 100, ROJO, cara=True), R(0, 100, 300, 110, ROJO),
            C(20, 210, 100, NOCHE, decoracion="rueda"), C(180, 210, 100, NOCHE, decoracion="rueda")]


def arbol():
    return [C(0, 0, 260, VERDE, cara=True), R(82, 260, 96, 150, CAFE), R(-20, 410, 300, 96, "#8FD989")]


def avion():
    return [TR(0, 0, 110, 100, ROJO, "◣"), R(0, 100, 320, 100, CELESTE, cara=True), TR(120, 200, 130, 96, ROJO, "◤")]


def torres_paine_maxi():
    gris = "#8E9BB5"
    return [T(0, 60, 106, 240, gris), T(107, 0, 106, 300, gris), T(214, 40, 106, 260, gris),
            R(0, 300, 320, 96, TURQUESA)]


def robot():
    return [R(90, 0, 140, 110, GRIS, cara=True), R(40, 110, 240, 170, AZUL), R(60, 280, 96, 110, GRIS),
            R(164, 280, 96, 110, GRIS)]


def pollito():
    return [C(0, 100, 220, AMARILLO), C(133.6, -6, 130, AMARILLO, cara=True), P("triangulo", 313, 59, 96, 96, NARANJO, 90)]


def casita_perro():
    return [T(0, 0, 260, 110, ROJO), R(30, 110, 200, 150, CAFE), SC(75, 160, 110, 100, NOCHE, capa=1)]


def platillo():
    return [SC(60, 0, 200, 100, CELESTE, cara=True), O(0, 100, 320, 110, LILA), TP(70, 212, 180, 110, AMARILLO)]


def braquiosaurio():
    return [R(0, 150, 260, 120, VERDE), R(164, 0, 96, 150, VERDE), O(260, 0, 130, 96, VERDE, cara=True)]


def auto_carrera():
    return [SC(60, -10, 200, 100, AZUL), R(0, 90, 320, 100, ROJO, cara=True),
            C(10, 190, 100, NOCHE, decoracion="rueda"), C(210, 190, 100, NOCHE, decoracion="rueda")]


def autito():
    """Figura hecha a mano antes de "Arma la figura" (zona 5): se conserva tal cual."""
    return [P("rectangulo", 0, 0, 320, 120, ROJO, decoracion="ventanas"),
            P("circulo", -95, 115, 110, 110, AMARILLO, decoracion="rueda"),
            P("circulo", 95, 115, 110, 110, AMARILLO, decoracion="rueda")]


def dino():
    return [P("ovalo", 0, 0, 260, 150, VERDE, decoracion="manchas"), P("circulo", 150, -95, 120, 120, VERDE, cara=True),
            P("triangulo", -182, 10, 160, 104, VERDE, 270)]


# ---------------------------------------------------------------------------
# Nicole (Brote): figuras nuevas de 6-8 piezas (lado >= 52 px), Coco nombra la forma
# ---------------------------------------------------------------------------

def gatito():
    rosa = "#F9B8D4"
    return [T(60, 0, 70, 60, rosa, nombre_voz="triangulo"), T(170, 0, 70, 60, rosa, nombre_voz="triangulo"),
            R(60, 60, 180, 140, rosa, nombre_voz="rectangulo", cara=True),
            TP(40, 200, 220, 160, rosa, nombre_voz="trapecio"),
            R(258, 300, 110, 52, rosa, nombre_voz="rectangulo_chico"),
            P("triangulo", 150, 86, 52, 52, ROJO, 270, capa=1, nombre_voz="triangulo_chico"),
            P("triangulo", 202, 86, 52, 52, ROJO, 90, capa=1, nombre_voz="triangulo_chico")]


def corazon():
    rosa = "#FF6FA8"
    a = 110
    return [TR(0, 40, a, a, rosa, "◢", nombre_voz="triangulo"), TR(a, 40, a, a, rosa, "◣", nombre_voz="triangulo"),
            TR(0, 40 + a, a, a, rosa, "◥", nombre_voz="triangulo"), TR(a, 40 + a, a, a, rosa, "◤", nombre_voz="triangulo"),
            P("semicirculo", 27.5, 67.5, a * math.sqrt(2), a * math.sqrt(2) / 2, rosa, -45, nombre_voz="semicirculo"),
            P("semicirculo", 192.5, 67.5, a * math.sqrt(2), a * math.sqrt(2) / 2, rosa, 45, nombre_voz="semicirculo")]


def torta():
    rosa, crema = "#F7A8C8", "#FFF1C2"
    return [C(196, -2, 52, ROJO, nombre_voz="circulo_chico"),
            T(134, -90, 52, 60, AMARILLO, nombre_voz="triangulo"), R(134, -30, 52, 80, CELESTE, nombre_voz="rectangulo_chico"),
            R(60, 50, 200, 70, rosa, nombre_voz="rectangulo"), R(30, 120, 260, 80, crema, nombre_voz="rectangulo"),
            R(0, 200, 320, 90, rosa, nombre_voz="rectangulo_grande"), R(0, 290, 320, 52, GRIS, nombre_voz="rectangulo")]


def pony():
    lila, rosa = "#D9A6F2", ROSADO
    return [R(60, 110, 220, 100, lila, nombre_voz="rectangulo_grande"), R(224, 30, 56, 80, lila, nombre_voz="rectangulo"),
            R(250, -30, 100, 60, lila, nombre_voz="rectangulo", cara=True), TR(170, 30, 54, 80, rosa, "◢", nombre_voz="triangulo"),
            TR(0, 110, 60, 90, rosa, "◥", nombre_voz="triangulo"), R(70, 210, 52, 100, lila, nombre_voz="rectangulo_chico"),
            R(218, 210, 52, 100, lila, nombre_voz="rectangulo_chico")]


def jirafa():
    amarillo, mancha = "#FFCB3D", "#C98A3C"
    return [R(40, 150, 200, 100, amarillo, nombre_voz="rectangulo_grande"), R(184, 0, 56, 150, amarillo, nombre_voz="rectangulo"),
            R(240, -10, 90, 60, amarillo, nombre_voz="rectangulo_chico", cara=True),
            R(40, 250, 52, 120, amarillo, nombre_voz="rectangulo"), R(188, 250, 52, 120, amarillo, nombre_voz="rectangulo"),
            C(70, 170, 56, mancha, capa=1, nombre_voz="circulo"), C(130, 184, 56, mancha, capa=1, nombre_voz="circulo")]


def corona():
    oro = "#FFCB3D"
    return [T(0, 0, 100, 120, oro, nombre_voz="triangulo"), T(100, 0, 100, 120, oro, nombre_voz="triangulo"),
            T(200, 0, 100, 120, oro, nombre_voz="triangulo"), R(0, 120, 300, 80, oro, nombre_voz="rectangulo_grande"),
            C(34, 134, 52, ROSADO, capa=1, nombre_voz="circulo"), E(118, 128, 64, CELESTE, capa=1, nombre_voz="estrella"),
            C(214, 134, 52, ROSADO, capa=1, nombre_voz="circulo")]


def castillo_princesa():
    rosa, crema = "#F7A8C8", "#FFD6E8"
    return [T(-10, 20, 90, 80, LILA, nombre_voz="triangulo"), T(250, 20, 90, 80, LILA, nombre_voz="triangulo"),
            R(0, 100, 70, 220, rosa, nombre_voz="rectangulo"), R(260, 100, 70, 220, rosa, nombre_voz="rectangulo"),
            R(70, 160, 190, 160, crema, nombre_voz="rectangulo_grande"),
            SC(125, 250, 80, 70, LILA, capa=1, nombre_voz="semicirculo"), C(139, 180, 52, CELESTE, capa=1, nombre_voz="circulo")]


def torres_paine_nicole():
    gris, nieve = "#8E9BB5", BLANCO
    p = []
    for x, alto_t, nieve_h in ((0, 240, 125), (107, 300, 150), (214, 260, 130)):
        y0 = 300 - alto_t
        w_nieve = 106 * nieve_h / alto_t
        p.append(T(x, y0, 106, alto_t, gris, nombre_voz="triangulo_grande"))
        p.append(T(x + 53 - w_nieve / 2, y0, w_nieve, nieve_h, nieve, capa=1, nombre_voz="triangulo_chico"))
    p.append(R(0, 300, 320, 80, TURQUESA, nombre_voz="rectangulo_grande"))
    return p


def morro_nicole():
    arena, roca = "#D8B07A", "#B98A5A"
    return [TR(0, 100, 120, 150, arena, "◢", nombre_voz="triangulo"), R(120, 100, 180, 150, roca, nombre_voz="rectangulo_grande"),
            R(120, 60, 120, 40, arena, nombre_voz="rectangulo_chico"), C(240, 30, 70, AMARILLO, nombre_voz="circulo"),
            R(0, 250, 160, 60, AZUL, nombre_voz="rectangulo"), R(160, 250, 160, 60, AZUL, nombre_voz="rectangulo"),
            T(40, 250, 70, 52, BLANCO, capa=1, nombre_voz="triangulo_chico")]


# ---------------------------------------------------------------------------
# Sofía (Estrella): monumentos nuevos de Chile (20-30 piezas)
# ---------------------------------------------------------------------------

def la_moneda():
    """La Moneda (zona 1, sin giro): fachada neoclásica blanca, alas con ventanas, pórtico de columnas
    y la bandera de Chile en el techo."""
    muro, cornisa, ventana, columna, grada = "#F3EBDD", "#D9CDB8", NOCHE, BLANCO, GRIS
    p = []
    for x0 in (0, 270):                                            # alas izquierda y derecha
        p.append(R(x0, 110, 150, 16, cornisa))
        x = x0
        for i, w in enumerate((20, 45, 20, 45, 20)):
            p.append(R(x, 126, w, 56, muro if i % 2 == 0 else ventana))
            x += w
        p.append(R(x0, 182, 150, 118, muro))
    p += [R(150, 90, 120, 36, cornisa)]                            # ático del cuerpo central
    x = 150
    for i, w in enumerate((22, 27, 22, 27, 22)):                   # pórtico: 3 columnas y 2 vanos
        p.append(R(x, 126, w, 174, columna if i % 2 == 0 else ventana))
        x += w
    p += [R(0, 300, 140, 22, grada), R(140, 300, 140, 22, grada), R(280, 300, 140, 22, grada)]
    # Bandera en el techo: asta y la bandera de Chile (azul, blanco, rojo y su estrella).
    p += [R(199, 0, 22, 90, GRIS), R(221, 0, 24, 24, CHILE_AZUL), R(245, 0, 48, 24, BLANCO_B),
          R(221, 24, 72, 24, CHILE_ROJO), E(222, 1, 22, BLANCO_B, capa=1)]
    return p


def valparaiso():
    """Valparaíso (zona 2, con giro): casas de colores en tres terrazas del cerro, el ascensor sobre su
    riel y el mar. Casas iguales de distinto color: la ronda pide `exigir_color`."""
    colores = [("#FF6B6B", "#FFCB3D"), ("#45C6C0", "#FF9F4A"), ("#FFCB3D", "#4A8BE0"), ("#B48CE8", "#FF6B6B"),
               ("#7DD87A", "#B48CE8"), ("#F26CA8", "#45C6C0"), ("#4A8BE0", "#F26CA8"), ("#FF9F4A", "#7DD87A"),
               ("#6FD6E8", "#FF6B6B")]
    p = [R(0, 440, 210, 26, AZUL), R(210, 440, 210, 26, AZUL)]    # el mar
    k = 0
    for fila, (y_base, x0, n) in enumerate(((440, 0, 4), (320, 70, 3), (200, 140, 2))):
        if fila:
            p.append(R(x0, y_base, 280 - x0, 20, "#A8744F"))           # terraza del cerro
        for i in range(n):
            pared, techo = colores[k]
            k += 1
            x = x0 + i * 70
            p += [T(x, y_base - 100, 70, 40, techo), R(x, y_base - 60, 70, 60, pared)]
    # Ascensor: riel en pendiente, el carro (con la misma pendiente) y la estación de arriba.
    p.append(TR(280, 140, 140, 300, "#8C6A4F", "◣"))
    y_riel = lambda x: 140 + (x - 280) * 300 / 140
    p.append(TR(320, y_riel(320), 56, y_riel(376) - y_riel(320), ROJO, "◥"))
    p.append(R(280, 100, 60, 40, "#FFF1C2"))
    return p


def torres_paine_sofia():
    """Torres del Paine (zona 3, con giro): tres torres de granito con nieve, el macizo y la laguna."""
    granito, granito2, nieve, roca, laguna, pasto = "#8E9BB5", "#737F99", BLANCO, "#9A938C", TURQUESA, VERDE
    p = []
    for x, cima, tono in ((40, 70, granito), (130, 0, granito), (220, 40, granito)):
        resto = 270 - (cima + 120)
        p += [T(x, cima, 60, 60, nieve), R(x, cima + 60, 60, 60, tono),
              R(x, cima + 120, 60, resto * 0.45, tono), R(x, cima + 120 + resto * 0.45, 60, resto * 0.55, tono)]
    p += [TP(0, 270, 320, 60, roca)]                                   # macizo bajo las torres
    p += [TR(-60, 270, 60, 60, roca, "◢"), TR(320, 270, 60, 60, roca, "◣")]
    p += [R(-60, 330, 110, 50, laguna), R(50, 330, 110, 50, laguna), R(160, 330, 110, 50, laguna), R(270, 330, 110, 50, laguna)]
    p += [R(-60, 380, 146, 30, pasto), R(86, 380, 148, 30, pasto), R(234, 380, 146, 30, pasto)]
    return p


def morro_arica():
    """Morro de Arica (zona 4, con giro): capas de roca del cerro, la gran bandera de Chile en la cima y
    el mar con olas. Capas iguales de distinto color: la ronda pide `exigir_color`."""
    capas = ["#E3C08A", "#D6A86E", "#C8955C", "#B7824E", "#A06F42"]
    p = []
    for i, color in enumerate(capas):                                 # el cerro, capa por capa
        y = 120 + i * 50
        x_ini = 150 - (i + 1) * 30
        largo = 400 - (x_ini + 30)
        corte = round(largo * (0.42 + 0.04 * i))
        p += [TR(x_ini, y, 30, 50, color, "◢"), R(x_ini + 30, y, corte, 50, color), R(x_ini + 30 + corte, y, largo - corte, 50, color)]
    # Bandera grande en la cima: asta y la bandera de Chile con su estrella.
    p += [R(330, 0, 22, 120, GRIS), R(240, 0, 30, 30, CHILE_AZUL), R(270, 0, 60, 30, BLANCO_B), R(240, 30, 90, 30, CHILE_ROJO),
          E(244, 4, 22, BLANCO_B, capa=1)]
    p += [R(0, 370, 140, 44, AZUL), R(140, 370, 130, 44, AZUL), R(270, 370, 130, 44, AZUL)]    # el mar
    p += [T(30, 384, 44, 24, BLANCO, capa=1), T(300, 384, 44, 24, BLANCO, capa=1)]           # olas
    return p


def san_cristobal():
    """Cerro San Cristóbal (zona 5, con giro): la Virgen blanca en la cima sobre su pedestal, el cerro
    verde con árboles, el santuario, el funicular y la ciudad a sus pies."""
    verde, verde2, blanco, piedra = VERDE, "#5DBB63", BLANCO, "#D9CFC1"
    p = [C(175, 0, 30, blanco), TP(170, 30, 40, 22, blanco, invertido=True), TP(165, 52, 50, 90, blanco),
         R(140, 30, 30, 22, blanco), R(210, 30, 30, 22, blanco)]          # la Virgen: cabeza, hombros, manto y brazos
    p += [R(172, 142, 36, 40, piedra), R(160, 182, 60, 30, piedra)]     # pedestal
    p += [T(140, 212, 100, 60, verde)]                                  # cumbre
    p += [TP(80, 272, 220, 70, verde), TR(10, 342, 72, 70, verde2, "◢"), R(82, 342, 216, 70, verde2),
          TR(298, 342, 72, 70, verde2, "◣")]                            # laderas
    p += [T(60, 356, 28, 40, "#2E8B57", capa=1), T(290, 356, 28, 40, "#2E8B57", capa=1)]   # árboles
    p += [R(244, 246, 36, 26, ROJO)]                                    # carro del funicular
    p += [R(90, 242, 44, 30, "#FFF1C2"), T(85, 212, 54, 30, ROJO)]      # santuario
    p += [R(10 + 72 * i, 412, 72, 26, GRIS) for i in range(5)]   # la ciudad
    return p


# ---------------------------------------------------------------------------
# Cortar y validar
# ---------------------------------------------------------------------------

def piezas_de(figura, escala=1.0):
    """Piezas con x, y relativos al centro de la caja de la figura (como las espera el motor).
    `escala` agranda la figura entera para aprovechar el tablero (piezas más grandes = más fáciles)."""
    piezas = figura()
    for p in piezas:
        for k in ("cx", "cy", "ancho", "alto"):
            p[k] = round(p[k] * escala, 2)
    polys = [poligono(p) for p in piezas]
    x0, y0, x1, y1 = caja([pt for P in polys for pt in P])
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    salida = []
    for p in piezas:
        q = {k: v for k, v in p.items() if k not in ("cx", "cy")}
        q["x"] = round(p["cx"] - cx, 2)
        q["y"] = round(p["cy"] - cy, 2)
        salida.append(q)
    return piezas, salida, (x1 - x0, y1 - y0)


def validar(nombre, piezas, perfil, cfg):
    errores, avisos = [], []
    polys = [poligono(p) for p in piezas]
    x0, y0, x1, y1 = caja([pt for P in polys for pt in P])
    if x1 - x0 > TABLERO[0] - 20 or y1 - y0 > TABLERO[1] - 20:
        errores.append("no cabe en el tablero: %dx%d" % (x1 - x0, y1 - y0))
    # Solapes y contacto, por muestreo en una grilla de 2 px.
    # Las muestras caen a 0,37 px de la grilla entera para no pisar justo un borde compartido.
    # Los emblemas (`capa` > 0) van ENCIMA de otras piezas: solo se prohíben solapes dentro de una misma
    # capa, y todo emblema debe quedar entero sobre piezas de capas más bajas.
    paso = 2.0
    celdas = {}
    solapes = {}
    fuera = {}
    capas = [p.get("capa", 0) for p in piezas]
    vecinos = {i: set() for i in range(len(piezas))}
    y = y0 + 0.37
    while y < y1:
        x = x0 + 0.37
        while x < x1:
            dentro = [i for i, P in enumerate(polys) if adentro(x, y, P)]
            for c in set(capas[i] for i in dentro):
                misma = [i for i in dentro if capas[i] == c]
                if len(misma) > 1:
                    solapes[tuple(misma[:2])] = solapes.get(tuple(misma[:2]), 0) + 1
            for i in dentro:
                if capas[i] > 0 and not any(capas[j] < capas[i] for j in dentro):
                    fuera[i] = fuera.get(i, 0) + 1
                for j in dentro:
                    if j != i:
                        vecinos[i].add(j)
            if dentro:
                celdas[(round(x / paso), round(y / paso))] = dentro[0]
            x += paso
        y += paso
    for (a, b), n in sorted(solapes.items()):
        errores.append("solape entre pieza %d y %d (%d muestras)" % (a, b, n))
    for i, n in sorted(fuera.items()):
        if n > 3:
            errores.append("emblema %d (capa %d) se sale de las piezas de abajo (%d muestras)" % (i, capas[i], n))
    # Piezas conectadas (vecinas a 2 celdas de distancia, o encimadas).
    for (cx, cy), i in celdas.items():
        for dx, dy in ((2, 0), (0, 2), (2, 2), (2, -2)):
            j = celdas.get((cx + dx, cy + dy))
            if j is not None and j != i:
                vecinos[i].add(j)
                vecinos[j].add(i)
    visto, pila = {0}, [0]
    while pila:
        for j in vecinos[pila.pop()]:
            if j not in visto:
                visto.add(j)
                pila.append(j)
    if len(visto) < len(piezas) and not cfg.get("permitir_sueltas"):
        errores.append("piezas sueltas (no tocan la figura): %s" % sorted(set(range(len(piezas))) - visto))
    # Tamaños: lado mínimo y que cada pieza quepa en la bandeja a tamaño real.
    for i, (p, P) in enumerate(zip(piezas, polys)):
        bx0, by0, bx1, by1 = caja(P)
        minimo = min(LADO_MINIMO[perfil], 52) if p.get("emblema") else LADO_MINIMO[perfil]
        if min(bx1 - bx0, by1 - by0) < minimo - 0.01:
            errores.append("pieza %d muy chica para %s: %dx%d" % (i, perfil, bx1 - bx0, by1 - by0))
        if bx1 - bx0 + 12 > BANDEJA_UTIL[0] or by1 - by0 + 12 > BANDEJA_UTIL[1]:
            errores.append("pieza %d no cabe en la bandeja: %dx%d" % (i, bx1 - bx0, by1 - by0))
    # Geometrías iguales con distinto color (intercambiables) y casi iguales (confundibles).
    giros = [0, 90, 180, 270] if cfg.get("rotacion_por_toque") else [None]
    for i in range(len(piezas)):
        for j in range(i + 1, len(piezas)):
            a, b = piezas[i], piezas[j]
            if a["forma"] != b["forma"]:
                continue
            rot = [a.get("rotacion", 0) if g is None else g for g in giros]
            d = diferencia_formas(a, b, rot)
            if d <= TOLERANCIA_CALCE and a["color"] != b["color"] and not cfg.get("exigir_color"):
                errores.append("piezas %d y %d son intercambiables pero de distinto color" % (i, j))
            elif TOLERANCIA_CALCE < d < 0.2 and (a["color"] == b["color"] or not cfg.get("exigir_color")):
                avisos.append("piezas %d y %d casi iguales (diferencia %.2f): confundibles" % (i, j, d))
    return errores, avisos



# ---------------------------------------------------------------------------
# Niveles: estaciones con rondas (PO 27-Sep-2026)
# ---------------------------------------------------------------------------

VOCES = "voces/arcoiris/formas/"
BANDA_TRAY = (BANDEJA_UTIL[0] - 12, BANDEJA_UTIL[1] - 12)   # lo que mide por dentro, con el margen de la pieza
ESCALA_MAXIMA = {"semilla": 1.3, "brote": 1.4, "estrella": 1.5}


def voces_estrella(intro):
    return {
        "intro": VOCES + "estrella/" + intro,
        "pista": VOCES + "estrella/pista_arma_01.wav",
        "acierto": [VOCES + "estrella/acierto_0%d.wav" % i for i in (1, 2, 3)],
        "no_es_este": [VOCES + "estrella/no_es_este_0%d.wav" % i for i in (1, 2)],
        "girar": VOCES + "estrella/girar_01.wav",
        "derrota_gag": VOCES + "estrella/derrota_gag_01.wav",
        "victoria_final": [VOCES + "estrella/victoria_0%d.wav" % i for i in (1, 2)],
        "pista_usada": VOCES + "estrella/pista_usada_01.wav",
        "regalo": VOCES + "estrella/regalo_01.wav",
        "prueba_superada": [VOCES + "estrella/prueba_superada_0%d.wav" % i for i in (1, 2)],
    }


def voces_brote(intro):
    return {
        "intro": VOCES + "brote/" + intro,
        "pista": VOCES + "brote/pista_01.wav",
        "acierto": [VOCES + "brote/acierto_0%d.wav" % i for i in (1, 2, 3)],
        "no_es_este": [VOCES + "brote/no_es_este_0%d.wav" % i for i in (1, 2)],
        "derrota_gag": VOCES + "brote/derrota_gag_01.wav",
        "victoria_final": [VOCES + "brote/victoria_0%d.wav" % i for i in (1, 2)],
        "objetivo_prefijo": VOCES + "nombres/",
        "ronda_siguiente": [VOCES + "brote/ronda_0%d.wav" % i for i in (1, 2)],
        "intro_generica": VOCES + "brote/intro_ronda.wav",
    }


def voces_semilla(intro, risa=False):
    v = {
        "intro": VOCES + "semilla/" + intro,
        "pista": VOCES + "semilla/pista_01.wav",
        "acierto": [VOCES + "semilla/acierto_0%d.wav" % i for i in (1, 2, 3)],
        "victoria_final": [VOCES + "semilla/victoria_0%d.wav" % i for i in (1, 2)],
        "ronda_siguiente": [VOCES + "semilla/ronda_0%d.wav" % i for i in (1, 2)],
        "intro_generica": VOCES + "semilla/intro_ronda.wav",
    }
    if risa:
        v["risa"] = [VOCES + "semilla/risa_0%d.wav" % i for i in (1, 2)]
    return v


ROT = {"rotacion_por_toque": True, "rotacion_inicial_aleatoria": True}

COMUN_ESTRELLA = {"caras": False, "guia_color": False, "modelo_mini": True, "bandeja_escala_real": True,
                  "piezas_en_bandeja": 6, "pistas_cuestan_estrellita": True, "regalo_tras_derrotas": True,
                  "iman_tolerancia_px": 70, "paso_rotacion": 90,
                  # PO 27-Sep-2026: sin lineas guia. Sofia solo ve el contorno exterior de la figura y se
                  # guia por la tarjeta del modelo; las piezas siempre se giran con un toque.
                  "silueta_unida": True,
                  # disenador-mecanicas HE-40 (#5): acertar el lugar con la pieza chueca no es fallo; la
                  # pieza queda flotando sobre el hueco y un toque la gira ahi mismo.
                  "giro_cuenta_fallo": False, **ROT}
COMUN_BROTE = {"objetivo_guiado": True, "caras": False, "modelo_mini": True, "bandeja_escala_real": True,
               "iman_tolerancia_px": 110}
COMUN_SEMILLA = {"sin_error": True, "toque_lleva_a_casa": True, "ayuda_idle_s": 7, "caras": False, "guia_color": True,
                 "modelo_mini": True, "bandeja_escala_real": True, "iman_tolerancia_px": 5000, "limite_intentos": None}


def fig(id_figura, funcion, voz=None, escala="auto", fija=False, grupo=None, config=None, bandera=False, **validacion):
    """Una figura del pool. `voz` = nombre del WAV en voces/.../figuras/ (por defecto, su id).
    `config` sobrescribe campos del nivel en su ronda; `bandera` pide cada franja en su color."""
    config = dict(config or {})
    if bandera:
        config["exigir_color"] = True
    return {"id": id_figura, "funcion": funcion, "voz": voz or id_figura, "escala": escala, "fija": fija,
            "grupo": grupo, "config": config, "validacion": validacion}


# Umbrales de estrellitas por ronda (disenador-niveles HE-40 §2.2, PROVISIONAL): fallos <= tres -> 3,
# <= dos -> 2, si no 1. Vale la peor ronda. La bandera va PRIMERO (calienta) y el monumento cierra.
def bandera_sofia(pais, funcion, limite, giro, tres=3):
    config = {"limite_intentos": limite, "rotacion_por_toque": giro, "rotacion_inicial_aleatoria": giro,
              "umbrales_estrellitas": {"tres": tres, "dos": limite},
              "lineas_voz": {"intro": VOCES + "estrella/intro_bandera_primero.wav",
                             "intro_ronda": VOCES + "estrella/intro_bandera.wav"}}
    return fig("bandera_" + pais, funcion, voz="bandera_%s_dato" % pais, grupo="bandera", config=config, bandera=True)


def monumento(id_figura, funcion, intro, escala="auto", voz=None, limite=12, **extra):
    config = {"limite_intentos": limite, "umbrales_estrellitas": {"tres": limite // 2, "dos": limite},
              "lineas_voz": {"intro": VOCES + "estrella/" + intro, "intro_ronda": VOCES + "estrella/" + intro}}
    config.update(extra.pop("config", {}))
    return fig(id_figura, funcion, voz=voz, escala=escala, grupo="monumento", config=config, **extra)


ESTACIONES = {
    # ---------------- Maxi · Semilla: 4 rondas por estación ----------------
    ("zona1_claro", "semilla"): {"nivel": dict(COMUN_SEMILLA, lineas_voz=voces_semilla("intro_arma_z1.wav")), "rondas": 4, "pool": [
        fig("casita_sol", casita_maxi, voz="casa", escala=1.0, fija=True, permitir_sueltas=True),
        fig("bandera_japon", f_japon_maxi, bandera=True),
        fig("bandera_francia", f_francia_maxi, bandera=True),
        fig("helado", helado),
        fig("pez", pez),
        # disenador-niveles HE-40 (#10): su primer contacto trae uno de sus temas fuertes (autos).
        fig("autito", autito, escala=1.0),
    ]},
    ("zona2_charcos", "semilla"): {"nivel": dict(COMUN_SEMILLA, risa_al_encajar=True, lineas_voz=voces_semilla("intro_arma_z2.wav", risa=True)), "rondas": 4, "pool": [
        fig("barquito", barquito, voz="barco", escala=1.0, fija=True),
        fig("bandera_peru", f_peru_maxi, bandera=True),
        fig("tortuga", tortuga),
        fig("micro_maxi", micro_maxi, voz="bus"),
        fig("pato", pato),
        fig("ballena", ballena),
    ]},
    ("zona3_chupetines", "semilla"): {"nivel": dict(COMUN_SEMILLA, lineas_voz=voces_semilla("intro_arma_z3.wav")), "rondas": 4, "pool": [
        fig("pino", pino, voz="abeto", escala=1.0, fija=True, permitir_sueltas=True),
        fig("bandera_chile", f_chile_maxi, bandera=True),
        fig("volcan_osorno", volcan_osorno),
        fig("camion_bomberos", camion_bomberos),
        fig("arbol", arbol),
        fig("avion", avion),
    ]},
    ("zona4_islotes", "semilla"): {"nivel": dict(COMUN_SEMILLA, lineas_voz=voces_semilla("intro_arma_z4.wav")), "rondas": 4, "pool": [
        fig("monito_nieve", monito_nieve, escala=1.0, fija=True),
        fig("torres_paine", torres_paine_maxi),
        fig("robot", robot),
        fig("pollito", pollito),
        fig("casita_perro", casita_perro),
    ]},
    ("zona5_cima", "semilla"): {"nivel": dict(COMUN_SEMILLA, lineas_voz=voces_semilla("intro_z5.wav")), "rondas": 4, "pool": [
        fig("autito", autito, escala=1.0),
        fig("dino", dino, escala=1.0, permitir_sueltas=True),
        fig("platillo", platillo),
        fig("braquiosaurio", braquiosaurio),
        fig("auto_carrera", auto_carrera),
        fig("cohete", cohete_maxi),
    ]},
    # ---------------- Nicole · Brote: 3 rondas por estación ----------------
    ("zona1_claro", "brote"): {"nivel": dict(COMUN_BROTE, guia_color=True, limite_intentos=None, lineas_voz=voces_brote("intro_arma_z1.wav")), "rondas": 3, "pool": [
        fig("casita", casita_nicole, voz="casa", escala=1.2, fija=True),
        fig("bandera_francia", f_francia_nicole, bandera=True),
        fig("bandera_italia", f_italia_nicole, bandera=True),
        fig("gatito", gatito),
        fig("corazon", corazon),
    ]},
    ("zona2_charcos", "brote"): {"nivel": dict(COMUN_BROTE, guia_color=True, limite_intentos=None, lineas_voz=voces_brote("intro_arma_z2.wav")), "rondas": 3, "pool": [
        fig("micro", micro, escala=1.0, fija=True),
        fig("bandera_peru", f_peru_nicole, bandera=True),
        fig("bandera_colombia", f_colombia_nicole, bandera=True),
        fig("torta", torta),
        fig("pony", pony),
    ]},
    ("zona3_chupetines", "brote"): {"nivel": dict(COMUN_BROTE, guia_color=False, limite_intentos=None, lineas_voz=voces_brote("intro_arma_z3.wav")), "rondas": 3, "pool": [
        fig("faro", faro, escala=1.25, fija=True),
        fig("bandera_chile", f_chile_nicole, bandera=True, config={"guia_color": True}),
        fig("bandera_japon", f_japon_nicole, bandera=True, config={"guia_color": True}),
        # HE-40 R1 (bloqueante): sin bichos; el pony es tema confirmado de Nicole.
        fig("pony", pony),
        fig("jirafa", jirafa),
    ]},
    ("zona4_islotes", "brote"): {"nivel": dict(COMUN_BROTE, guia_color=False, limite_intentos=12, lineas_voz=voces_brote("intro_arma_z4.wav")), "rondas": 3, "pool": [
        fig("tren", tren, escala=1.25, fija=True),
        fig("bandera_argentina", f_argentina_nicole, bandera=True),
        fig("bandera_alemania", f_alemania_nicole, bandera=True),
        fig("bandera_brasil", f_brasil_nicole, bandera=True),
        fig("corona", corona),
    ]},
    ("zona5_cima", "brote"): {"nivel": dict(COMUN_BROTE, guia_color=False, limite_intentos=12, lineas_voz=voces_brote("intro_z5.wav")), "rondas": 3, "pool": [
        "jardin",   # la escena del jardín (con el corazón dorado) se conserva tal cual: ver jardin_legado()
        fig("bandera_bolivia", f_bolivia_nicole, bandera=True),
        fig("torres_paine", torres_paine_nicole),
        fig("morro_arica", morro_nicole),
        fig("castillo_princesa", castillo_princesa),
    ]},
    # ---------------- Sofía · Estrella: un monumento y una bandera ----------------
    ("zona1_claro", "estrella"): {"nivel": dict(COMUN_ESTRELLA, limite_intentos=14, piezas_en_bandeja=4, lineas_voz=voces_estrella("intro_arma_z1.wav")),
                                  "rondas": ["bandera", "monumento"], "pool": [
        monumento("iglesia_chiloe", iglesia_chiloe, "intro_arma_z1.wav", escala=1.15, limite=14,
                  config={"exigir_color": True}),  # con giro, sus rectangulos de distinto color calzan cruzados
        monumento("la_moneda", la_moneda, "intro_moneda.wav", limite=14),
        bandera_sofia("chile", f_chile_sofia, 8, True),
        bandera_sofia("argentina", f_argentina_sofia, 8, True),
        bandera_sofia("peru", f_peru_sofia, 8, True),
        bandera_sofia("bolivia", f_bolivia_sofia, 8, True),
    ]},
    ("zona2_charcos", "estrella"): {"nivel": dict(COMUN_ESTRELLA, limite_intentos=12, piezas_en_bandeja=5, lineas_voz=voces_estrella("intro_arma_z2.wav")),
                                    "rondas": ["bandera", "monumento"], "pool": [
        monumento("palafitos", palafitos, "intro_arma_z2.wav", escala=1.4),
        monumento("valparaiso", valparaiso, "intro_valparaiso.wav", bandera=True),
        bandera_sofia("brasil", f_brasil_sofia, 9, True),
        bandera_sofia("uruguay", uruguay, 9, True),
        bandera_sofia("paraguay", paraguay, 9, True),
        bandera_sofia("colombia", f_colombia_sofia, 9, True),
        bandera_sofia("venezuela", venezuela, 9, True),
        bandera_sofia("ecuador", f_ecuador_sofia, 9, True),
    ]},
    ("zona3_chupetines", "estrella"): {"nivel": dict(COMUN_ESTRELLA, limite_intentos=12, piezas_en_bandeja=5, lineas_voz=voces_estrella("intro_arma_z3.wav")),
                                       "rondas": ["bandera", "monumento"], "pool": [
        monumento("santiago", santiago, "intro_arma_z3.wav", escala=1.2),
        monumento("torres_paine", torres_paine_sofia, "intro_torres_paine.wav", voz="torres_paine_dato"),
        bandera_sofia("japon", f_japon_sofia, 9, True),
        bandera_sofia("francia", f_francia_sofia, 9, True),
        bandera_sofia("alemania", f_alemania_sofia, 9, True),
    ]},
    ("zona4_islotes", "estrella"): {"nivel": dict(COMUN_ESTRELLA, limite_intentos=14, piezas_en_bandeja=6, lineas_voz=voces_estrella("intro_arma_z4.wav")),
                                    "rondas": ["bandera", "monumento"], "pool": [
        monumento("moais", moais, "intro_arma_z4.wav", escala=1.5, limite=14),
        monumento("morro_arica", morro_arica, "intro_morro.wav", voz="morro_arica_dato", bandera=True, limite=14),
        bandera_sofia("rusia", f_rusia_sofia, 10, True, tres=4),
        bandera_sofia("china", china, 10, True, tres=4),
        bandera_sofia("india", india, 10, True, tres=4),
    ]},
    ("zona5_cima", "estrella"): {"nivel": dict(COMUN_ESTRELLA, limite_intentos=16, piezas_en_bandeja=6, lineas_voz=voces_estrella("intro_arma_z5.wav")),
                                 "rondas": ["bandera", "monumento"], "pool": [
        monumento("castillo_santa_lucia", castillo, "intro_arma_z5.wav", escala=1.35, limite=16),
        monumento("san_cristobal", san_cristobal, "intro_san_cristobal.wav", limite=16),
        bandera_sofia("eeuu", eeuu, 14, True, tres=5),
        bandera_sofia("mexico", mexico, 10, True, tres=4),
    ]},
}

# Voz de nombre de cada forma para el objetivo guiado de Nicole (si la pieza no trae `nombre_voz`).
NOMBRE_FORMA = {"triangulo_rect": "triangulo"}


def escala_automatica(funcion, perfil):
    """La escala más grande (hasta ESCALA_MAXIMA) con que la figura cabe en el tablero y cada pieza, a
    tamaño real, en la bandeja: piezas más grandes = más fáciles de tomar."""
    piezas = funcion()
    polys = [poligono(p) for p in piezas]
    x0, y0, x1, y1 = caja([pt for P in polys for pt in P])
    escala = min(ESCALA_MAXIMA[perfil], (TABLERO[0] - 24) / (x1 - x0), (TABLERO[1] - 24) / (y1 - y0))
    for P in polys:
        bx0, by0, bx1, by1 = caja(P)
        escala = min(escala, (BANDA_TRAY[0] - 1) / (bx1 - bx0), (BANDA_TRAY[1] - 1) / (by1 - by0))
    return max(1.0, math.floor(escala * 100) / 100) if escala >= 1.0 else math.floor(escala * 100) / 100


def jardin_legado():
    """La escena del jardín de Nicole (zona 5) se hizo a mano antes de las rondas: se toma del nivel
    actual (formato antiguo o ya convertido a ronda) para no perderla al reescribir."""
    ruta = os.path.join(NIVELES, "zona5_cima", "formas_brote.json")
    with open(ruta, encoding="utf-8") as f:
        viejo = json.load(f)
    if "rondas" in viejo:
        return next(f for f in viejo["figuras"] if f["id"] == "jardin")
    config = {k: viejo[k] for k in ("escena", "iman_tolerancia_px", "limite_intentos") if k in viejo}
    config.update({"modo": "escena", "guia_color": False, "bandeja_escala_real": False, "modelo_mini": False,
                   "lineas_voz": {"especial": viejo["lineas_voz"]["especial"]}})
    voces = {"casa": "casa", "sol": "sol", "arbol": "arbol", "jirafa": "jirafa"}
    figuras = []
    for figura in viejo["figuras"]:
        if figura["id"] in voces:
            figura["voz_completa"] = VOCES + "figuras/%s.wav" % voces[figura["id"]]
        figuras.append(figura)
    config["figuras"] = figuras
    requeridas = sum(1 for f in figuras for p in f["piezas"] if not p.get("opcional"))
    return {"id": "jardin", "fija": True, "dificultad": requeridas, "config": config,
            "voz_completa": VOCES + "figuras/jardin.wav", "piezas": []}


def piezas_json_de(entrada, perfil):
    escala = entrada["escala"]
    if escala == "auto":
        escala = escala_automatica(entrada["funcion"], perfil)
    piezas, salida, medida = piezas_de(entrada["funcion"], escala)
    for q in salida:
        q.pop("emblema", None)
        if perfil == "brote" and "nombre_voz" not in q:
            q["nombre_voz"] = NOMBRE_FORMA.get(q["forma"], q["forma"])
    return piezas, salida, medida, escala


def dibujar_previa(ruta, titulo, piezas):
    from PIL import Image, ImageDraw
    polys = [poligono(p) for p in piezas]
    x0, y0, x1, y1 = caja([pt for P in polys for pt in P])
    margen = 20
    ancho_fig = int(x1 - x0) + margen * 2
    alto = int(y1 - y0) + margen * 2 + 30
    # Piezas sueltas a la derecha, en filas, al mismo tamaño.
    colocadas, fila_x, fila_y, fila_alto, max_x = [], 0, 0, 0, 0
    limite = 420
    for P in polys:
        bx0, by0, bx1, by1 = caja(P)
        w, h = bx1 - bx0, by1 - by0
        if fila_x + w > limite and fila_x > 0:
            fila_y += fila_alto + 14
            fila_x, fila_alto = 0, 0
        colocadas.append((fila_x - bx0, fila_y - by0))
        fila_x += w + 14
        fila_alto = max(fila_alto, h)
        max_x = max(max_x, fila_x)
    alto = max(alto, int(fila_y + fila_alto) + margen * 2 + 30)
    im = Image.new("RGB", (ancho_fig + int(max_x) + margen * 2, alto), "#F4EEF8")
    d = ImageDraw.Draw(im)
    d.text((margen, 6), titulo, fill="black")
    orden = sorted(range(len(piezas)), key=lambda i: piezas[i].get("capa", 0))
    for i in orden:
        d.polygon([(x - x0 + margen, y - y0 + margen + 24) for x, y in polys[i]], fill=piezas[i]["color"], outline="#2B3350")
    for p, P, (dx, dy) in zip(piezas, polys, colocadas):
        d.polygon([(x + dx + ancho_fig + margen, y + dy + margen + 24) for x, y in P], fill=p["color"], outline="#2B3350")
    im.save(ruta)


def escribir_nivel(zona, perfil, estacion, pool_json):
    ruta = os.path.join(NIVELES, zona, "formas_%s.json" % perfil)
    with open(ruta, encoding="utf-8") as f:
        viejo = json.load(f)
    nivel = {k: viejo[k] for k in ("id_nivel", "motor", "perfil", "planeta", "zona", "tema", "anfitrion_id", "fondo_id") if k in viejo}
    nivel["modo"] = "arma_figura"
    nivel["diseno"] = "figura primero y rondas (PO 27-Sep-2026): herramientas/figuras_formas.py"
    nivel.update(estacion["nivel"])
    nivel["rondas"] = estacion["rondas"]
    nivel["figuras"] = pool_json
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        json.dump(nivel, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return ruta


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--previas", help="carpeta donde dibujar las vistas previas PNG")
    parser.add_argument("--escribir", action="store_true", help="reescribe los niveles JSON")
    parser.add_argument("--solo", help="solo las figuras cuyo id contenga este texto")
    args = parser.parse_args()
    total_errores = 0
    for (zona, perfil), estacion in ESTACIONES.items():
        pool_json = []
        errores_estacion = 0
        for entrada in estacion["pool"]:
            if entrada == "jardin":
                pool_json.append(jardin_legado())
                continue
            if args.solo and args.solo not in entrada["id"]:
                continue
            piezas, salida, medida, escala = piezas_json_de(entrada, perfil)
            cfg = dict(estacion["nivel"], **entrada["config"])
            cfg.update(entrada["validacion"])
            errores, avisos = validar(entrada["id"], piezas, perfil, cfg)
            nombres = (entrada["id"] + " " + str(entrada["voz"])).lower()
            errores += ["figura prohibida (bicho): %s" % b for b in PROHIBIDOS if b in nombres]
            estado = "OK" if not errores else "ERROR"
            print("%-6s %-16s %-9s %-24s %2d piezas  %dx%d  escala %.2f" % (estado, zona, perfil, entrada["id"], len(piezas), medida[0], medida[1], escala))
            for e in errores:
                print("         x " + e)
            for a in avisos:
                print("         ! " + a)
            errores_estacion += len(errores)
            if args.previas:
                os.makedirs(args.previas, exist_ok=True)
                dibujar_previa(os.path.join(args.previas, "%s_%s_%s.png" % (zona[:5], perfil, entrada["id"])),
                               "%s - %s - %s (%d piezas)" % (zona, perfil, entrada["id"], len(piezas)), piezas)
            figura = {"id": entrada["id"], "voz_completa": VOCES + "figuras/%s.wav" % entrada["voz"], "dificultad": len(piezas)}
            if entrada["fija"]:
                figura["fija"] = True
            if entrada["grupo"]:
                figura["grupo"] = entrada["grupo"]
            if entrada["config"]:
                figura["config"] = entrada["config"]
            figura["piezas"] = salida
            pool_json.append(figura)
        total_errores += errores_estacion
        if args.escribir and not errores_estacion and not args.solo:
            escribir_nivel(zona, perfil, estacion, pool_json)
    if total_errores:
        print("\n%d errores: no se escribieron las estaciones con error." % total_errores)
        sys.exit(1)


if __name__ == "__main__":
    main()
