"""Genera el arte SVG del mapa del Planeta Animalia visto desde el suelo (HE-120, 05-Nov-2026).

Pedido del PO (05-Nov-2026): "El mapa de animalia debe ser similar al que hicimos en planeta arcoiris
con las tematicas de animalia". Mismo sistema que `generar_mapa_arcoiris.py` (maqueta aprobada el
17-Oct-2026: el planeta visto desde el suelo, volumen con brillo, lo dormido a medio tono) con el
ambiente aprobado de Animalia (HE-A7b, `assets/anclas/planeta_animalia_referencia.png`): cielo tibio
de la tarde, montañas lejanas, selva de copas redondas, laguna, pradera dorada, hongos y flores.
Sin mariposas ni bichos (ficha de zonas §2.0 y §3).

Capas (las dibuja `scripts/planetas/animalia/paisaje_animalia.gd`):
  cielo.svg   degradado celeste -> durazno con resplandor de sol
  nubes.svg   nubes gorditas (se mecen despacio)
  tierra.svg  montañas, cerro del valle, selva, colinas, laguna, riachuelo, pradera, primer plano
Hitos de cada zona (caja de 180x180, el centro es la `posicion` de la zona en mapa.json), sin carita
(la pone el núcleo para poder dormirla) y sin animales (los dibuja el paisaje en código, porque
duermen, despiertan y bailan). Cada uno en `suelo` (quieto) y `hito` (se mece), y su versión
`_gris` (la siesta: colores a medio tono).

Además, los 4 iconos de las estaciones de Animalia (esferas como los de `generar_iconos_juegos.py`,
con prefijo `animalia_` para no chocar con otros planetas).

Salida: assets/sprites/planetas/animalia/mapa/*.svg y assets/sprites/ui/iconos_juegos/animalia_*.svg
Uso: python herramientas/generar_mapa_animalia.py
"""
import colorsys
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets/sprites/planetas/animalia/mapa"
SALIDA_ICONOS = RAIZ / "assets/sprites/ui/iconos_juegos"

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generar_iconos_juegos as iconos  # noqa: E402  (mismo estilo de esfera que los iconos de Arcoíris)

# ---------------------------------------------------------------------------
# Degradados compartidos
# ---------------------------------------------------------------------------


def radial(id_, paradas, fx="34%", fy="28%", r="60%", cx="50%", cy="50%"):
    stops = ""
    for offset, color, opacidad in paradas:
        extra = "" if opacidad is None else f' stop-opacity="{opacidad}"'
        stops += f'<stop offset="{offset}" stop-color="{color}"{extra}/>'
    return f'<radialGradient id="{id_}" cx="{cx}" cy="{cy}" r="{r}" fx="{fx}" fy="{fy}">{stops}</radialGradient>'


def lineal(id_, arriba, abajo):
    return (f'<linearGradient id="{id_}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{arriba}"/>'
            f'<stop offset="1" stop-color="{abajo}"/></linearGradient>')


DEGRADADOS = {
    "g-cielo": ('<linearGradient id="g-cielo" x1="0" y1="0" x2="0" y2="1">'
                '<stop offset="0" stop-color="#7fcbe6"/><stop offset=".28" stop-color="#a9def0"/>'
                '<stop offset=".5" stop-color="#d8f0e2"/><stop offset=".66" stop-color="#fff2c9"/>'
                '<stop offset="1" stop-color="#ffe0a6"/></linearGradient>'),
    "g-sol": radial("g-sol", [(0, "#fffbe6", .95), (.4, "#fff2c2", .55), (1, "#ffe6a6", 0)], r="50%", fx="50%", fy="50%"),
    "g-sombra": radial("g-sombra", [(0, "#2f5a2a", .32), (1, "#2f5a2a", 0)], r="50%", fx="50%", fy="50%"),
    "g-brillo": radial("g-brillo", [(0, "#ffffff", .55), (.45, "#ffffff", 0), (1, "#1d3a1a", .28)], r="50%", fx="30%", fy="25%"),
    "g-niebla": radial("g-niebla", [(0, "#ffffff", .7), (1, "#ffffff", 0)], r="50%", fx="50%", fy="50%"),
    "g-montana": lineal("g-montana", "#c3e2d2", "#a6cfc0"),
    "g-montana-2": lineal("g-montana-2", "#acd6c0", "#93c4b0"),
    "g-valle": lineal("g-valle", "#b5dcae", "#8cc48e"),
    "g-selva": lineal("g-selva", "#7cc477", "#4f9a5a"),
    "g-colina-1": lineal("g-colina-1", "#b8e68e", "#86c866"),
    "g-colina-2": lineal("g-colina-2", "#a8dc84", "#74b85c"),
    "g-pradera": lineal("g-pradera", "#f6eb9e", "#d6d474"),
    "g-pasto": lineal("g-pasto", "#9fd87a", "#6fb85a"),
    "g-frente": lineal("g-frente", "#8fcf6e", "#5fa650"),
    "g-agua": lineal("g-agua", "#c6eef8", "#6cc3e0"),
    "g-rio": lineal("g-rio", "#b8e8f6", "#7ccbe6"),
    "g-hoja": radial("g-hoja", [(0, "#bff0a0", None), (.55, "#6fc463", None), (1, "#3f9050", None)], fx="35%", fy="25%", r="70%"),
    "g-hoja-osc": radial("g-hoja-osc", [(0, "#9fdc88", None), (.55, "#58a85a", None), (1, "#367a44", None)], fx="35%", fy="25%", r="70%"),
    "g-tronco": lineal("g-tronco", "#c08a5a", "#8a5a36"),
    "g-carpa": radial("g-carpa", [(0, "#fffaf0", None), (.6, "#fbe7c6", None), (1, "#e0bf8c", None)], fx="38%", fy="30%", r="70%"),
    "g-techo": radial("g-techo", [(0, "#b8ec9a", None), (.55, "#5fbf6a", None), (1, "#3a8f4c", None)], fx="40%", fy="30%", r="70%"),
    "g-nenufar": radial("g-nenufar", [(0, "#d8f7b6", None), (.6, "#7fd06a", None), (1, "#4aa255", None)], fx="40%", fy="35%", r="65%"),
    "g-volcan": radial("g-volcan", [(0, "#f2c08a", None), (.55, "#d08a58", None), (1, "#9a5a3a", None)], fx="38%", fy="30%", r="70%"),
    "g-lava": radial("g-lava", [(0, "#fff2b0", None), (.6, "#ffb24a", None), (1, "#ff7a3a", None)], r="60%", fx="50%", fy="40%"),
    "g-barro": lineal("g-barro", "#d9b07a", "#b8875a"),
    "g-hongo": radial("g-hongo", [(0, "#ffb0a0", None), (.55, "#f05a4a", None), (1, "#c03a32", None)], fx="35%", fy="25%", r="70%"),
    "g-hongo-am": radial("g-hongo-am", [(0, "#fff0a0", None), (.55, "#ffc23a", None), (1, "#e08a22", None)], fx="35%", fy="25%", r="70%"),
    "g-roca": radial("g-roca", [(0, "#f0eadc", None), (.6, "#cfc4ae", None), (1, "#a89a82", None)], fx="35%", fy="25%", r="70%"),
}

CONTORNO = "#3a4a2e"


def svg(ancho, alto, cuerpo):
    usados = sorted(set(re.findall(r"url\(#([\w-]+)\)", cuerpo)))
    defs = "".join(DEGRADADOS[u] for u in usados)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">'
            f'<defs>{defs}</defs>{cuerpo}</svg>\n')


def colocar(contenido, vb_ancho, vb_alto, x, y, ancho, alto):
    return f'<g transform="translate({x} {y}) scale({ancho / vb_ancho:.4f} {alto / vb_alto:.4f})">{contenido}</g>'


def borde(d, opacidad=.55, color="#fff"):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-opacity="{opacidad}" stroke-width="3"/>'


# ---------------------------------------------------------------------------
# Piezas reutilizables
# ---------------------------------------------------------------------------

def nube(x, y, ancho, alto):
    c = ('<ellipse cx="100" cy="74" rx="88" ry="14" fill="#e8efd8"/><circle cx="58" cy="54" r="30" fill="#fff"/>'
         '<circle cx="100" cy="38" r="38" fill="#fff"/><circle cx="144" cy="52" r="28" fill="#fff"/>'
         '<rect x="28" y="46" width="146" height="30" rx="15" fill="#fff"/>'
         '<ellipse cx="100" cy="72" rx="74" ry="7" fill="#f3f6e6"/><ellipse cx="84" cy="26" rx="18" ry="8" fill="#fff" opacity=".9"/>')
    return colocar(c, 200, 90, x, y, ancho, alto)


def arbol_selva(x, y, ancho, alto, tono="g-hoja"):
    """Árbol de copa redonda (tres bolas) con tronco corto; caja 100x140."""
    c = ('<path d="M44 136 L46 84 Q50 78 54 84 L56 136 Z" fill="url(#g-tronco)"/>'
         f'<circle cx="30" cy="66" r="26" fill="url(#{tono})"/><circle cx="70" cy="64" r="28" fill="url(#{tono})"/>'
         f'<circle cx="50" cy="40" r="32" fill="url(#{tono})"/>'
         '<ellipse cx="40" cy="26" rx="12" ry="7" fill="#fff" opacity=".3"/>')
    return colocar(c, 100, 140, x, y, ancho, alto)


def palmera(x, y, ancho, alto):
    """Palmera de selva; caja 100x160."""
    c = ('<path d="M50 156 Q44 110 52 52" stroke="#a87a4a" stroke-width="9" fill="none" stroke-linecap="round"/>'
         '<path d="M50 150 Q44 110 52 56" stroke="#c99a62" stroke-width="3" fill="none" stroke-dasharray="4 7"/>'
         '<g fill="url(#g-hoja)">'
         '<path d="M52 52 Q20 30 4 58 Q26 44 52 56 Z"/><path d="M52 52 Q84 28 98 58 Q76 44 52 56 Z"/>'
         '<path d="M52 50 Q30 12 12 22 Q34 26 52 54 Z"/><path d="M52 50 Q76 12 92 24 Q70 26 52 54 Z"/>'
         '<path d="M52 50 Q50 14 56 4 Q60 26 54 54 Z"/></g>'
         '<circle cx="48" cy="58" r="5" fill="#8a5a36"/><circle cx="57" cy="59" r="5" fill="#8a5a36"/>')
    return colocar(c, 100, 160, x, y, ancho, alto)


def helecho(x, y, ancho, alto, color="#5fae5e"):
    """Matita de hojas grandes de primer plano; caja 120x90."""
    c = (f'<g fill="{color}">'
         '<path d="M60 90 Q10 70 4 20 Q40 40 60 90 Z"/><path d="M60 90 Q110 70 116 18 Q80 40 60 90 Z"/>'
         '<path d="M60 90 Q36 40 60 0 Q84 40 60 90 Z"/></g>'
         '<path d="M60 88 Q30 60 10 26 M60 88 Q90 60 110 24 M60 88 L60 8" stroke="#fff" stroke-opacity=".35" stroke-width="2.5" fill="none"/>')
    return colocar(c, 120, 90, x, y, ancho, alto)


def hongo(x, y, ancho, alto, tono="g-hongo"):
    """Hongo redondo con lunares; caja 60x60."""
    c = ('<path d="M22 58 Q20 34 26 30 L34 30 Q40 34 38 58 Z" fill="#fff6e6"/>'
         f'<path d="M4 34 Q4 6 30 4 Q56 6 56 34 Q30 40 4 34 Z" fill="url(#{tono})"/>'
         '<circle cx="18" cy="20" r="4.5" fill="#fff" opacity=".9"/><circle cx="34" cy="13" r="4" fill="#fff" opacity=".9"/>'
         '<circle cx="44" cy="26" r="3.5" fill="#fff" opacity=".9"/><circle cx="26" cy="29" r="3" fill="#fff" opacity=".8"/>')
    return colocar(c, 60, 60, x, y, ancho, alto)


def flor(x, y, lado, color):
    c = (f'<g fill="{color}"><circle cx="0" cy="-6" r="5"/><circle cx="5.7" cy="-1.9" r="5"/><circle cx="3.5" cy="4.9" r="5"/>'
         '<circle cx="-3.5" cy="4.9" r="5"/><circle cx="-5.7" cy="-1.9" r="5"/></g><circle r="3.6" fill="#ffe066"/>')
    return f'<g transform="translate({x + lado / 2} {y + lado / 2}) scale({lado / 24:.4f})">{c}</g>'


def roca(x, y, ancho, alto):
    c = ('<path d="M4 38 Q2 14 24 8 Q46 2 56 22 Q62 38 52 40 Z" fill="url(#g-roca)"/>'
         '<ellipse cx="22" cy="16" rx="8" ry="4" fill="#fff" opacity=".45"/>')
    return colocar(c, 60, 42, x, y, ancho, alto)


def matas_pasto(puntos, color="#7cc463"):
    c = f'<g fill="{color}">'
    for x, y, s in puntos:
        c += (f'<path d="M{x} {y} Q{x - 3 * s} {y - 12 * s} {x - 5 * s} {y - 16 * s} Q{x} {y - 8 * s} {x + 1 * s} {y} Z"/>'
              f'<path d="M{x} {y} Q{x + 4 * s} {y - 14 * s} {x + 7 * s} {y - 18 * s} Q{x + 2 * s} {y - 8 * s} {x + 2 * s} {y} Z"/>')
    return c + '</g>'


# ---------------------------------------------------------------------------
# Capas del paisaje (1280x720)
# ---------------------------------------------------------------------------

def capa_cielo():
    c = '<rect width="1280" height="720" fill="url(#g-cielo)"/><circle cx="660" cy="330" r="320" fill="url(#g-sol)"/>'
    c += '<circle cx="660" cy="300" r="46" fill="#fffbe6" opacity=".7"/>'
    return svg(1280, 720, c)


def capa_nubes():
    c = nube(260, 120, 200, 90) + nube(560, 70, 150, 68) + nube(760, 150, 180, 81) + nube(-30, 200, 170, 77)
    return svg(1280, 720, c)


# Contornos de cada franja del paisaje (también los usa el paisaje para saber dónde está el suelo).
MONTANAS = ("M-20 372 C30 330 80 296 130 300 C170 302 190 330 220 322 C260 290 300 252 350 256 C400 260 430 300 470 304 "
            "C520 300 560 262 610 264 C660 266 690 300 730 306 C780 300 820 276 870 284")
MONTANAS_2 = ("M-20 410 C40 384 100 372 160 380 C220 388 260 360 320 352 C380 346 420 376 480 380 C540 384 580 356 640 352 "
              "C700 350 740 372 800 378 C840 382 860 376 880 372")
VALLE = "M820 470 C880 380 960 300 1060 286 C1140 276 1220 280 1300 296"
SELVA = ("M-20 452 C30 430 70 424 110 432 C150 412 200 410 240 428 C290 414 330 418 370 432 C410 420 450 420 490 434 "
         "C540 420 590 418 640 432 C690 420 740 418 790 434 C830 424 860 428 890 438")
COLINA_CAMPO = "M-20 520 C70 486 170 476 270 492 C340 504 390 512 440 508 C500 502 560 486 620 488"
COLINA_ARBOL = "M560 520 C640 470 740 410 860 392 C940 380 1010 384 1080 404 C1160 426 1230 452 1300 462"
PRADERA = "M600 610 C680 560 780 536 900 538 C1020 540 1130 560 1300 552"
FRENTE = "M-20 652 C140 628 330 632 520 660 C700 686 900 676 1080 650 C1180 636 1240 640 1300 644"


def capa_tierra():
    c = f'<path d="{MONTANAS} L870 720 L-20 720 Z" fill="url(#g-montana)"/>' + borde(MONTANAS, .5)
    # Nieve-crema en las puntas de las montañas lejanas (sin frío como zona: es solo luz).
    c += '<g fill="#ffffff" opacity=".55"><path d="M330 262 Q350 252 372 262 Q358 272 350 268 Q342 274 330 262 Z"/>'
    c += '<path d="M592 270 Q610 260 630 270 Q618 280 610 276 Q600 282 592 270 Z"/></g>'
    c += f'<path d="{MONTANAS_2} L880 720 L-20 720 Z" fill="url(#g-montana-2)"/>'
    # Palmeras lejanas en la línea de montañas, como en el ambiente aprobado.
    c += '<g opacity=".55">' + palmera(140, 316, 30, 50) + palmera(520, 318, 28, 46) + palmera(760, 320, 30, 50) + '</g>'
    # El cerro del Valle de los Dinosaurios (zona 5): verde antiguo, con helechos gigantes y huellas.
    c += f'<path d="{VALLE} L1300 720 L820 720 Z" fill="url(#g-valle)"/>' + borde(VALLE, .55)
    c += '<g opacity=".9">' + helecho(1222, 250, 70, 52, "#6fb07a") + helecho(1010, 268, 64, 48, "#6fb07a") + '</g>'
    c += palmera(1238, 214, 46, 74) + palmera(1050, 232, 40, 64)
    # Selva de copas redondas.
    c += f'<path d="{SELVA} L890 720 L-20 720 Z" fill="url(#g-selva)"/>'
    for x, y, a, tono in [(-10, 330, 96, "g-hoja-osc"), (70, 344, 84, "g-hoja"), (190, 336, 92, "g-hoja-osc"), (300, 348, 80, "g-hoja"),
                          (420, 344, 86, "g-hoja-osc"), (640, 340, 88, "g-hoja-osc"), (740, 350, 80, "g-hoja")]:
        c += arbol_selva(x, y, a * 0.72, a, tono)
    c += palmera(250, 312, 50, 82) + palmera(600, 316, 46, 76) + palmera(830, 318, 44, 72)
    # Colina del árbol de los nidos (zona 4) y su pradera alta.
    c += f'<path d="{COLINA_ARBOL} L1300 720 L560 720 Z" fill="url(#g-colina-2)"/>' + borde(COLINA_ARBOL, .55)
    # Colina del campamento (zona 1) con la laguna (zona 2).
    c += f'<path d="{COLINA_CAMPO} L620 720 L-20 720 Z" fill="url(#g-colina-1)"/>' + borde(COLINA_CAMPO, .6)
    c += ('<ellipse cx="560" cy="484" rx="170" ry="38" fill="#5aa8c8" opacity=".5"/>'
          '<ellipse cx="560" cy="480" rx="164" ry="34" fill="url(#g-agua)"/>'
          '<ellipse cx="520" cy="472" rx="70" ry="6" fill="#fff" opacity=".5"/><ellipse cx="640" cy="490" rx="40" ry="4" fill="#fff" opacity=".4"/>')
    # Juncos y piedras lisas en la orilla de la laguna.
    c += ('<g stroke="#5fa650" stroke-width="4" stroke-linecap="round" fill="none">'
          '<path d="M398 486 Q394 462 400 448"/><path d="M406 488 Q408 466 404 452"/><path d="M714 486 Q712 466 718 452"/><path d="M722 488 Q726 468 722 456"/></g>'
          '<g fill="#a8744a"><rect x="396" y="440" width="8" height="18" rx="4"/><rect x="714" y="446" width="8" height="16" rx="4"/></g>')
    c += roca(430, 494, 34, 22) + roca(668, 500, 30, 20)
    # Riachuelo que baja de la laguna (el puente de troncos lo dibuja el paisaje sobre el sendero).
    rio = "M452 504 C430 540 432 570 470 600 C510 632 520 670 506 740"
    c += f'<path d="{rio}" stroke="#5aa8c8" stroke-opacity=".5" stroke-width="40" fill="none" stroke-linecap="round"/>'
    c += f'<path d="{rio}" stroke="url(#g-rio)" stroke-width="32" fill="none" stroke-linecap="round"/>'
    c += '<path d="M446 530 C440 556 452 576 476 594" stroke="#fff" stroke-opacity=".55" stroke-width="4" fill="none" stroke-linecap="round"/>'
    # Pradera dorada de las jirafas (zona 3).
    c += f'<path d="{PRADERA} L1300 720 L600 720 Z" fill="url(#g-pradera)"/>' + borde(PRADERA, .6)
    c += matas_pasto([(640, 600, 1.4), (700, 576, 1.2), (930, 560, 1.3), (1010, 566, 1.1), (1180, 572, 1.3), (1250, 566, 1.2)], "#c9c860")
    c += ('<g opacity=".95"><ellipse cx="1000" cy="596" rx="30" ry="14" fill="#b6c95e"/><circle cx="990" cy="586" r="5" fill="#ff9ec4"/>'
          '<circle cx="1008" cy="584" r="5" fill="#fff"/><circle cx="1000" cy="592" r="4" fill="#ffd23d"/></g>')
    # Primer plano: pasto, hongos, flores grandes, piedras y hojas gigantes en las esquinas.
    c += f'<path d="{FRENTE} L1300 720 L-20 720 Z" fill="url(#g-frente)"/>' + borde(FRENTE, .45)
    c += helecho(-30, 600, 170, 128, "#4f9a52") + helecho(1170, 610, 150, 112, "#4f9a52")
    c += hongo(236, 640, 46, 46) + hongo(272, 664, 30, 30, "g-hongo-am") + hongo(690, 650, 40, 40) + hongo(1040, 640, 44, 44, "g-hongo-am")
    c += hongo(1078, 666, 28, 28) + hongo(80, 470, 30, 30) + hongo(866, 520, 26, 26, "g-hongo-am")
    c += roca(560, 668, 44, 28) + roca(900, 650, 38, 24) + roca(150, 520, 30, 20)
    for x, y, lado, color in [(170, 500, 20, "#ff9ec4"), (360, 520, 18, "#fff"), (600, 540, 20, "#ffb86b"), (210, 610, 22, "#fff"),
                              (420, 662, 24, "#ff9ec4"), (780, 690, 22, "#ffd23d"), (860, 640, 20, "#fff"), (1130, 676, 22, "#ff9ec4"),
                              (930, 600, 18, "#fff"), (1220, 560, 18, "#ff9ec4"), (40, 560, 18, "#ffd23d"), (330, 690, 20, "#b48ce8")]:
        c += flor(x, y, lado, color)
    # Sombra suave bajo el árbol grande (zona 4).
    c += '<ellipse cx="962" cy="392" rx="96" ry="14" fill="url(#g-sombra)"/>'
    return svg(1280, 720, c)


# ---------------------------------------------------------------------------
# Hitos de las zonas (caja 180x180)
# ---------------------------------------------------------------------------

CARPA = (
    # Cuerpo redondo de la carpa (las franjas verdes van en la lona).
    '<path d="M28 132 Q24 82 52 66 L128 66 Q156 82 152 132 Z" fill="url(#g-carpa)"/>'
    '<g fill="#7fcf74" opacity=".85"><path d="M46 132 Q44 96 58 70 L66 70 Q56 98 60 132 Z"/>'
    '<path d="M120 132 Q124 96 114 70 L122 70 Q136 98 134 132 Z"/></g>'
    # Techo cónico verde selva con borde festoneado.
    '<path d="M22 72 C40 50 70 12 90 12 C110 12 140 50 158 72 Z" fill="#5fbf6a"/><path d="M22 72 C40 50 70 12 90 12 C110 12 140 50 158 72 Z" fill="url(#g-techo)"/>'
    '<path d="M22 72 Q32 82 42 72 Q52 82 62 72 Q72 82 82 72 Q92 82 102 72 Q112 82 122 72 Q132 82 142 72 Q150 80 158 72 Z" fill="#4aa255"/>'
    '<ellipse cx="68" cy="40" rx="12" ry="6" fill="#fff" opacity=".35" transform="rotate(-30 68 40)"/>'
    # Entrada (cortinas recogidas) bajo la carita.
    '<path d="M74 132 Q74 116 90 112 Q106 116 106 132 Z" fill="#7a4a2a"/>'
    '<path d="M74 132 Q72 118 80 112 L84 132 Z M106 132 Q108 118 100 112 L96 132 Z" fill="#f2d3a0"/>'
    # Antenita con la estrellita dorada (la de la mochila de Toby).
    '<path d="M90 30 L90 10" stroke="#8a8fa8" stroke-width="3.5" stroke-linecap="round"/>'
    '<path d="M90 0 L93 7 L100 7.6 L94.6 12 L96.4 19 L90 15 L83.6 19 L85.4 12 L80 7.6 L87 7 Z" fill="#ffd23d" stroke="#e0a21a" stroke-width="1.5"/>'
)

CORRALITO = (
    '<g fill="#d9a066" stroke="#a8744a" stroke-width="1.5">'
    '<rect x="136" y="112" width="6" height="30" rx="2"/><rect x="160" y="114" width="6" height="28" rx="2"/>'
    '<rect x="132" y="120" width="40" height="5" rx="2"/><rect x="132" y="132" width="40" height="5" rx="2"/></g>'
)

NENUFAR = (
    '<path d="M90 132 C40 132 22 120 26 108 C30 96 60 90 90 90 C120 90 150 96 154 108 C158 120 140 132 98 132 L94 112 Z" fill="url(#g-nenufar)"/>'
    '<path d="M90 112 L56 104 M90 112 L124 104 M90 112 L70 126 M90 112 L114 126" stroke="#4aa255" stroke-width="2.5" stroke-linecap="round" opacity=".7"/>'
    '<ellipse cx="62" cy="100" rx="18" ry="4" fill="#fff" opacity=".4"/>'
    # Nenúfares chiquitos alrededor.
    '<ellipse cx="22" cy="138" rx="16" ry="6" fill="#7fd06a"/><ellipse cx="158" cy="140" rx="14" ry="5" fill="#7fd06a"/>'
)

ACACIA = (
    '<path d="M84 140 Q86 112 80 96 Q72 84 58 78 M88 112 Q96 96 112 84" stroke="#8a5a36" stroke-width="9" fill="none" stroke-linecap="round"/>'
    '<path d="M86 140 L84 100 L94 100 L96 140 Z" fill="url(#g-tronco)"/>'
    # Copa ancha y plana de acacia.
    '<path d="M12 78 Q16 52 50 48 Q70 30 100 38 Q130 30 154 50 Q176 58 168 78 Q140 88 90 86 Q36 88 12 78 Z" fill="url(#g-hoja)"/>'
    '<path d="M20 74 Q60 82 90 80 Q130 82 162 72" stroke="#3f9050" stroke-width="3" fill="none" opacity=".4"/>'
    '<ellipse cx="60" cy="52" rx="20" ry="6" fill="#fff" opacity=".35" transform="rotate(-8 60 52)"/>'
)

PASTO_ALTO = (
    '<g fill="#d6c85a"><path d="M14 142 Q10 112 6 100 Q18 116 22 142 Z"/><path d="M26 142 Q26 108 30 96 Q34 120 32 142 Z"/>'
    '<path d="M150 142 Q152 110 160 98 Q160 122 158 142 Z"/><path d="M164 142 Q170 116 176 108 Q172 128 170 142 Z"/></g>'
    '<g fill="#ff9ec4"><circle cx="40" cy="134" r="5"/><circle cx="140" cy="132" r="5"/></g><g fill="#fff"><circle cx="48" cy="138" r="4"/><circle cx="132" cy="138" r="4"/></g>'
)

ARBOL_NIDOS = (
    # Tronco ancho con raíces y lianas.
    '<path d="M60 150 Q70 140 72 110 L74 70 L108 70 L110 110 Q112 140 124 150 Q104 146 92 150 Q78 146 60 150 Z" fill="url(#g-tronco)"/>'
    '<path d="M84 140 Q82 110 86 80 M98 138 Q102 110 98 82" stroke="#7a4a2a" stroke-width="2.5" fill="none" opacity=".5"/>'
    # Copa grande de tres pisos.
    '<circle cx="46" cy="64" r="34" fill="url(#g-hoja-osc)"/><circle cx="136" cy="62" r="34" fill="url(#g-hoja-osc)"/>'
    '<circle cx="90" cy="40" r="42" fill="url(#g-hoja)"/>'
    '<ellipse cx="74" cy="20" rx="16" ry="8" fill="#fff" opacity=".3" transform="rotate(-20 74 20)"/>'
    # Ramas con nidos redondos en escalera.
    '<path d="M74 92 L40 96 M108 84 L146 88" stroke="#8a5a36" stroke-width="6" stroke-linecap="round"/>'
    '<g><ellipse cx="38" cy="94" rx="17" ry="9" fill="#b98a52"/><path d="M22 92 Q38 104 54 92" stroke="#8a5a36" stroke-width="2" fill="none"/>'
    '<ellipse cx="148" cy="86" rx="16" ry="8" fill="#b98a52"/><path d="M133 84 Q148 96 163 84" stroke="#8a5a36" stroke-width="2" fill="none"/>'
    '<ellipse cx="118" cy="34" rx="14" ry="7" fill="#b98a52"/><path d="M105 32 Q118 42 131 32" stroke="#8a5a36" stroke-width="2" fill="none"/></g>'
    '<g fill="#fff6e6"><circle cx="34" cy="89" r="3.5"/><circle cx="42" cy="88" r="3.5"/><circle cx="146" cy="81" r="3.2"/></g>'
    # Lianas con hojitas.
    '<path d="M20 70 Q16 100 24 124 M160 76 Q166 102 158 122" stroke="#5fa650" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
    '<g fill="#7fd06a"><ellipse cx="20" cy="104" rx="6" ry="3.5" transform="rotate(30 20 104)"/>'
    '<ellipse cx="162" cy="104" rx="6" ry="3.5" transform="rotate(-30 162 104)"/><ellipse cx="24" cy="122" rx="5" ry="3" transform="rotate(-20 24 122)"/></g>'
)

VOLCAN = (
    '<path d="M18 140 Q40 120 58 66 Q62 54 76 54 L104 54 Q118 54 122 66 Q140 120 162 140 Z" fill="url(#g-volcan)"/>'
    # Boca del cráter con brillito tibio (volcán dormilón, nada que asuste).
    '<ellipse cx="90" cy="56" rx="22" ry="7" fill="url(#g-lava)"/>'
    '<path d="M60 70 Q66 86 58 104 M118 70 Q114 90 124 108" stroke="#9a5a3a" stroke-width="3" fill="none" opacity=".5"/>'
    '<ellipse cx="70" cy="72" rx="7" ry="14" fill="#fff" opacity=".3" transform="rotate(20 70 72)"/>'
    # Musgo y helechos al pie.
    '<path d="M18 140 Q30 126 46 130 Q60 120 74 132 Q90 122 106 132 Q122 120 136 130 Q150 126 162 140 Z" fill="#7fbf6a"/>'
)

HUELLAS_GIGANTES = (
    '<g fill="#9a6a44" opacity=".55">'
    '<ellipse cx="30" cy="150" rx="11" ry="6"/><circle cx="20" cy="142" r="3.5"/><circle cx="30" cy="139" r="3.5"/><circle cx="40" cy="142" r="3.5"/>'
    '<ellipse cx="150" cy="156" rx="11" ry="6"/><circle cx="140" cy="148" r="3.5"/><circle cx="150" cy="145" r="3.5"/><circle cx="160" cy="148" r="3.5"/></g>'
)

HITOS = {
    "zona1": {
        "suelo": ('<ellipse cx="90" cy="140" rx="86" ry="18" fill="url(#g-sombra)"/>'
                  '<ellipse cx="90" cy="134" rx="80" ry="15" fill="#e8d39a"/><ellipse cx="90" cy="132" rx="72" ry="11" fill="#f4e2b0"/>'
                  + CORRALITO + '<g fill="#d9a066"><circle cx="22" cy="134" r="5"/><circle cx="30" cy="140" r="4"/></g>'),
        "hito": CARPA,
    },
    "zona2": {
        "suelo": ('<ellipse cx="90" cy="134" rx="84" ry="16" fill="#5aa8c8" opacity=".35"/>'
                  '<ellipse cx="90" cy="130" rx="60" ry="9" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="2.5"/>'
                  '<ellipse cx="90" cy="130" rx="80" ry="13" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="2"/>'),
        "hito": NENUFAR,
    },
    "zona3": {
        "suelo": '<ellipse cx="90" cy="140" rx="84" ry="16" fill="url(#g-sombra)"/>' + PASTO_ALTO,
        "hito": ACACIA,
    },
    "zona4": {
        "suelo": ('<ellipse cx="92" cy="150" rx="80" ry="14" fill="url(#g-sombra)"/>'
                  '<path d="M44 152 Q56 140 66 150 M120 150 Q132 140 142 152" stroke="#8a5a36" stroke-width="7" fill="none" stroke-linecap="round"/>'),
        "hito": ARBOL_NIDOS,
    },
    "zona5": {
        "suelo": ('<ellipse cx="90" cy="144" rx="86" ry="16" fill="url(#g-barro)"/>' + HUELLAS_GIGANTES),
        "hito": VOLCAN,
    },
}


def dormir(texto):
    """Versión de la siesta: colores a medio tono, un poco más claros y tibios (ficha de zonas §2.0)."""
    def medio(m):
        h = m.group(1)
        if len(h) == 3:
            h = "".join(ch * 2 for ch in h)
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
        hue, luz, sat = colorsys.rgb_to_hls(r, g, b)
        sat *= 0.35
        luz = 0.25 + luz * 0.72
        rr, gg, bb = colorsys.hls_to_rgb(hue, luz, sat)
        return "#%02x%02x%02x" % (round(rr * 255), round(gg * 255), round(bb * 255))
    return re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", medio, texto)


# ---------------------------------------------------------------------------
# Iconos de las estaciones de Animalia (esfera + dibujo en caja de 100x100)
# ---------------------------------------------------------------------------

ICONOS = {
    # ¿Quién habla?: un perrito asomado de su madriguera con ondas de sonido.
    "animalia_quien_habla": (("#e6f7d0", "#7fcf6a", "#3f9a49"),
        '<ellipse cx="50" cy="80" rx="34" ry="11" fill="#6a4a2a"/><ellipse cx="50" cy="78" rx="28" ry="7" fill="#3a2a1a"/>'
        '<path d="M28 78 Q26 44 50 40 Q74 44 72 78 Z" fill="#f4dcb0"/>'
        '<path d="M30 52 Q20 56 22 74 Q32 70 34 56 Z M70 52 Q80 56 78 74 Q68 70 66 56 Z" fill="#b9773f"/>'
        '<circle cx="42" cy="58" r="3.5" fill="#2B2150"/><circle cx="58" cy="58" r="3.5" fill="#2B2150"/>'
        '<ellipse cx="50" cy="66" rx="5" ry="3.5" fill="#2B2150"/><path d="M46 71 Q50 75 54 71" stroke="#2B2150" stroke-width="2" fill="none"/>'
        '<g fill="none" stroke="#fff" stroke-width="4.5" stroke-linecap="round"><path d="M80 34 Q88 42 80 50"/><path d="M86 24 Q100 42 86 60"/>'
        '<path d="M20 34 Q12 42 20 50"/><path d="M14 24 Q0 42 14 60"/></g>'),
    # Cada quien a su casa: camino de huellitas que llega a una casita.
    "animalia_casa": (("#ffe8cc", "#ffa95a", "#d0702c"),
        '<path d="M14 84 Q30 60 52 64 Q74 68 80 46" stroke="#fff3dd" stroke-width="9" fill="none" stroke-linecap="round" stroke-dasharray="1 13"/>'
        '<rect x="58" y="26" width="34" height="26" rx="4" fill="#fff6e8"/><path d="M54 30 L75 12 L96 30 Z" fill="#ff5470" stroke="#ff5470" stroke-width="5" stroke-linejoin="round"/>'
        '<rect x="70" y="36" width="10" height="16" rx="5" fill="#b9773f"/>'
        '<g fill="#6a3a1a"><ellipse cx="22" cy="80" rx="7" ry="5.5"/><circle cx="15" cy="72" r="2.6"/><circle cx="21" cy="70" r="2.6"/><circle cx="27" cy="71" r="2.6"/>'
        '<ellipse cx="44" cy="68" rx="6" ry="5"/><circle cx="38" cy="61" r="2.3"/><circle cx="44" cy="59" r="2.3"/><circle cx="50" cy="61" r="2.3"/></g>'),
    # Escondite animal: lupa sobre un arbusto con dos orejitas asomando.
    "animalia_escondite": (("#e0f4ff", "#5fb8ea", "#2a74c0"),
        '<path d="M8 86 Q10 56 34 56 Q42 40 60 46 Q80 44 84 64 Q96 70 92 86 Z" fill="#5fbf6a"/>'
        '<path d="M44 56 L40 38 L52 50 Z M62 52 L68 36 L72 52 Z" fill="#ffad5c" stroke="#d0702c" stroke-width="2" stroke-linejoin="round"/>'
        '<circle cx="38" cy="38" r="22" fill="#e8f8ff" fill-opacity=".55" stroke="#fff" stroke-width="7"/>'
        '<path d="M54 54 L74 74" stroke="#fff" stroke-width="10" stroke-linecap="round"/>'
        '<ellipse cx="30" cy="30" rx="6" ry="9" fill="#fff" opacity=".7" transform="rotate(-35 30 30)"/>'),
    # Carrera de Toby: un dinito saltando un tronco con líneas de velocidad.
    "animalia_carrera": (("#fff4c4", "#ffcb3d", "#e0952a"),
        '<g stroke="#fff" stroke-width="4.5" stroke-linecap="round"><path d="M6 40 L22 40"/><path d="M2 52 L20 52"/><path d="M8 64 L22 64"/></g>'
        '<path d="M34 66 Q30 44 50 38 Q60 22 76 28 Q90 34 84 46 Q76 50 70 48 Q72 62 64 70 Z" fill="#6fcf7a"/>'
        '<path d="M34 64 L16 70 L36 56 Z" fill="#6fcf7a"/><path d="M44 70 L44 82 M60 70 L62 82" stroke="#4aa255" stroke-width="7" stroke-linecap="round"/>'
        '<circle cx="76" cy="36" r="3.5" fill="#2B2150"/><path d="M80 44 Q84 46 86 43" stroke="#2B2150" stroke-width="2" fill="none"/>'
        '<path d="M54 30 L56 22 L60 30 L64 21 L66 30" fill="#ff8a6a"/>'
        '<rect x="36" y="86" width="44" height="12" rx="6" fill="#a8744a"/><circle cx="42" cy="92" r="4" fill="#d9a066"/>'),
}


def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    archivos = {"cielo": capa_cielo(), "nubes": capa_nubes(), "tierra": capa_tierra()}
    for zona, partes in HITOS.items():
        for parte, cuerpo in partes.items():
            archivos[f"{zona}_{parte}"] = svg(180, 180, cuerpo)
    for nombre in [n for n in archivos if n.startswith("zona")]:
        archivos[f"{nombre}_gris"] = dormir(archivos[nombre])
    for nombre, texto in archivos.items():
        (SALIDA / f"{nombre}.svg").write_text(texto, encoding="utf-8")
    print(f"{len(archivos)} SVG -> {SALIDA.relative_to(RAIZ)}")
    for nombre, (esfera, dibujo) in ICONOS.items():
        iconos.ESFERAS[nombre] = esfera
        iconos.DIBUJOS[nombre] = dibujo
        (SALIDA_ICONOS / f"{nombre}.svg").write_text(iconos.icono(nombre), encoding="utf-8")
    print(f"{len(ICONOS)} iconos -> {SALIDA_ICONOS.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
