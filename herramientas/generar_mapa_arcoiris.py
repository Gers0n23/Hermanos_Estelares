"""Genera el arte SVG del mapa del Planeta Arcoíris visto desde el suelo (pedido del PO 17-Oct-2026).

Replica la maqueta aprobada por el PO: el paisaje del planeta como en los conceptos
(`assets/generadas/conceptos_planeta1/`: colinas pastel, árboles-chupetín, islotes-trébol con tierra
de chocolate, cielo lila con nubes) con el lenguaje visual del menú de planetas (volumen con brillo,
píldoras, ruta de puntitos dorados, lo dormido en gris).

Capas (las dibuja `scripts/planetas/arcoiris/paisaje_arcoiris.gd`; el arcoíris va entre el cielo y
las nubes y lo pinta el núcleo):
  cielo.svg   degradado lila -> durazno, resplandor de sol, estrellitas
  nubes.svg   nubes y dos islotes de adorno (se mecen despacio)
  tierra.svg  colinas, la Cima con neblina, árboles de dulce, estanque, flores (fondo transparente)
Hitos de cada zona (caja de 180x180, mismo sistema que la maqueta), sin carita: la pone el núcleo
para poder dormirla. Cada uno en `suelo` (quieto) y `hito` (se mece), y su versión `_gris` (dormida).

Salida: assets/sprites/planetas/arcoiris/mapa/*.svg
Uso: python herramientas/generar_mapa_arcoiris.py
"""
import colorsys
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets/sprites/planetas/arcoiris/mapa"

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
    "g-rojo": radial("g-rojo", [(0, "#ffb3bf", None), (.5, "#ff5470", None), (1, "#c92c4c", None)]),
    "g-amarillo": radial("g-amarillo", [(0, "#fff6c2", None), (.5, "#ffd23d", None), (1, "#eb9a22", None)]),
    "g-azul": radial("g-azul", [(0, "#cfe2ff", None), (.5, "#4f8fe6", None), (1, "#2a56b0", None)]),
    "g-cian": radial("g-cian", [(0, "#e0fbff", None), (.55, "#5fd4ea", None), (1, "#2a9fc0", None)]),
    "g-violeta": radial("g-violeta", [(0, "#e6dcff", None), (.55, "#9580f2", None), (1, "#5e48c0", None)]),
    "g-menta": radial("g-menta", [(0, "#dcffd2", None), (.55, "#7dd87a", None), (1, "#46a552", None)], fy="24%"),
    "g-malva": radial("g-malva", [(0, "#ffffff", None), (.6, "#ffeef6", None), (1, "#efc6da", None)], fx="36%", fy="26%", r="65%"),
    "g-naranja": radial("g-naranja", [(0, "#ffe2b8", None), (.55, "#ff9f4a", None), (1, "#e0702a", None)], cy="80%", r="70%", fx="40%", fy="40%"),
    "g-lila": radial("g-lila", [(0, "#efe4ff", None), (.55, "#b48ce8", None), (1, "#8460c4", None)], r="65%", fy="26%"),
    "g-rosa": radial("g-rosa", [(0, "#ffe0ee", None), (.55, "#f59ac4", None), (1, "#d06a9c", None)], r="65%", fy="26%"),
    "g-charco": radial("g-charco", [(0, "#fff0f6", None), (.5, "#ff9cc6", None), (1, "#e06aa0", None)], fx="40%", fy="35%"),
    "g-brillo": radial("g-brillo", [(0, "#ffffff", .6), (.45, "#ffffff", 0), (1, "#4a1d6e", .3)], r="50%", fx="30%", fy="25%"),
    "g-sol": radial("g-sol", [(0, "#fff6e6", .95), (.4, "#ffe6d6", .5), (1, "#ffd6e0", 0)], r="50%", fx="50%", fy="50%"),
    "g-sombra": radial("g-sombra", [(0, "#6a3a7a", .3), (1, "#6a3a7a", 0)], r="50%", fx="50%", fy="50%"),
    "g-niebla": radial("g-niebla", [(0, "#ffffff", .75), (1, "#ffffff", 0)], r="50%", fx="50%", fy="50%"),
    "g-choco": lineal("g-choco", "#b47a56", "#5e3424"),
    "g-pasto-0": lineal("g-pasto-0", "#d6fac6", "#7fcf6a"),
    "g-pasto-3": lineal("g-pasto-3", "#e2fbd2", "#94d47c"),
    "g-pasto-4": lineal("g-pasto-4", "#f1e8ff", "#b99cf6"),
    "g-lejos": lineal("g-lejos", "#e8d6f2", "#d2bce8"),
    "g-lejos-2": lineal("g-lejos-2", "#d4e6f6", "#c2cdec"),
    "g-cima": lineal("g-cima", "#e6dcf6", "#c0b0e2"),
    "g-c-rosa": lineal("g-c-rosa", "#ffd6e6", "#f4a2c6"),
    "g-c-amarilla": lineal("g-c-amarilla", "#fff4c4", "#fbcf72"),
    "g-c-menta": lineal("g-c-menta", "#d4f6e6", "#8fd6c2"),
    "g-suelo": lineal("g-suelo", "#fff2e6", "#ffd8c6"),
    "g-suelo-verde": lineal("g-suelo-verde", "#e6f7c8", "#bfe39a"),
    "g-estanque": lineal("g-estanque", "#d2f0ff", "#7cc4ec"),
    "g-cielo": ('<linearGradient id="g-cielo" x1="0" y1="0" x2="0" y2="1">'
                '<stop offset="0" stop-color="#6a58ac"/><stop offset=".2" stop-color="#8f78c4"/>'
                '<stop offset=".4" stop-color="#c39dd6"/><stop offset=".56" stop-color="#f2bfd3"/>'
                '<stop offset=".68" stop-color="#ffdcc9"/><stop offset="1" stop-color="#ffe9d6"/></linearGradient>'),
}

ESTRELLA = "M12 1.5 L15 8.6 L22.6 9.2 L16.8 14.2 L18.6 21.6 L12 17.6 L5.4 21.6 L7.2 14.2 L1.4 9.2 L9 8.6 Z"


def svg(ancho, alto, cuerpo):
    usados = sorted(set(re.findall(r"url\(#([\w-]+)\)", cuerpo)))
    defs = "".join(DEGRADADOS[u] for u in usados)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">'
            f'<defs>{defs}</defs>{cuerpo}</svg>\n')


# ---------------------------------------------------------------------------
# Piezas reutilizables (equivalen a los <symbol> de la maqueta)
# ---------------------------------------------------------------------------

def colocar(contenido, vb_ancho, vb_alto, x, y, ancho, alto):
    return f'<g transform="translate({x} {y}) scale({ancho / vb_ancho:.4f} {alto / vb_alto:.4f})">{contenido}</g>'


def nube(x, y, ancho, alto):
    c = ('<ellipse cx="100" cy="74" rx="88" ry="14" fill="#e6d2f0"/><circle cx="58" cy="54" r="30" fill="#fff"/>'
         '<circle cx="100" cy="38" r="38" fill="#fff"/><circle cx="144" cy="52" r="28" fill="#fff"/>'
         '<rect x="28" y="46" width="146" height="30" rx="15" fill="#fff"/>'
         '<ellipse cx="100" cy="72" rx="74" ry="7" fill="#efe0f6"/><ellipse cx="84" cy="26" rx="18" ry="8" fill="#fff" opacity=".9"/>')
    return colocar(c, 200, 90, x, y, ancho, alto)


def chupetin(x, y, ancho, alto):
    c = ('<rect x="37" y="64" width="6" height="104" rx="3" fill="#fff8ee"/><circle cx="40" cy="40" r="36" fill="#ff9ec4"/>'
         '<circle cx="40" cy="40" r="28" fill="#ffe58a"/><circle cx="40" cy="40" r="20" fill="#8fd0ff"/>'
         '<circle cx="40" cy="40" r="12" fill="#c5a8ff"/><circle cx="40" cy="40" r="5" fill="#fff"/>'
         '<circle cx="40" cy="40" r="36" fill="url(#g-brillo)"/>'
         '<path d="M40 150 C24 142 18 128 24 122 C32 128 38 138 40 150 Z" fill="#7dd87a"/>'
         '<path d="M40 158 C56 150 62 136 56 130 C48 136 42 146 40 158 Z" fill="#5bbf62"/>')
    return colocar(c, 80, 170, x, y, ancho, alto)


def arbolito(x, y, ancho, alto, color):
    c = (f'<path d="M40 70 L40 166" stroke="#d6a886" stroke-width="5" stroke-linecap="round"/>'
         f'<circle cx="40" cy="40" r="34" fill="{color}"/><circle cx="40" cy="40" r="34" fill="url(#g-brillo)"/>'
         f'<path d="M40 146 C26 138 22 126 27 121 C34 127 38 136 40 146 Z" fill="#7dd87a"/>')
    return colocar(c, 80, 170, x, y, ancho, alto)


def cono(x, y, ancho, alto, color):
    forma = "M30 4 Q34 4 36 10 L54 100 Q30 112 6 100 L24 10 Q26 4 30 4 Z"
    c = (f'<path d="{forma}" fill="{color}"/>'
         '<path d="M20 30 L41 24 L43 34 L18 41 Z M14 58 L47 50 L49 61 L12 69 Z M9 84 L52 76 L54 88 L7 96 Z" fill="#fff" opacity=".75"/>'
         f'<path d="{forma}" fill="url(#g-brillo)"/>')
    return colocar(c, 60, 120, x, y, ancho, alto)


def casita(x, y, ancho, alto, color):
    c = (f'<rect x="9" y="24" width="42" height="32" rx="5" fill="#fff4ea"/>'
         f'<path d="M4 28 L30 6 L56 28 Z" fill="{color}" stroke="{color}" stroke-width="5" stroke-linejoin="round"/>'
         '<rect x="24" y="38" width="12" height="18" rx="6" fill="#9ad6e8"/>'
         '<circle cx="16" cy="36" r="4" fill="#ffe58a"/><circle cx="44" cy="36" r="4" fill="#ffe58a"/>')
    return colocar(c, 60, 58, x, y, ancho, alto)


def flor(x, y, lado, color):
    c = (f'<g fill="{color}"><circle cx="0" cy="-6" r="5"/><circle cx="5.7" cy="-1.9" r="5"/><circle cx="3.5" cy="4.9" r="5"/>'
         '<circle cx="-3.5" cy="4.9" r="5"/><circle cx="-5.7" cy="-1.9" r="5"/></g><circle r="3.6" fill="#ffe066"/>')
    return f'<g transform="translate({x + lado / 2} {y + lado / 2}) scale({lado / 24:.4f})">{c}</g>'


def caramelo(x, y, ancho, alto, color):
    c = ('<path d="M2 32 A28 28 0 0 1 58 32 Z" fill="#fff"/>'
         f'<path d="M10 32 A20 28 0 0 1 22 8 L28 4 A20 30 0 0 0 20 32 Z M34 4 L40 6 A22 30 0 0 1 52 32 L42 32 A22 30 0 0 0 34 4 Z" fill="{color}"/>'
         '<path d="M2 32 A28 28 0 0 1 58 32 Z" fill="url(#g-brillo)"/>')
    return colocar(c, 60, 34, x, y, ancho, alto)


ISLOTE = ('<path d="M14 40 Q22 106 80 108 Q138 106 146 40 Z" fill="url(#g-choco)"/>'
          '<path d="M30 64 Q80 78 130 64" stroke="#4a2818" stroke-width="3" fill="none" opacity=".4"/>'
          '<circle cx="60" cy="80" r="3" fill="#ff9ec4"/><circle cx="96" cy="88" r="3" fill="#8fd0ff"/>'
          '<g fill="#6fae58"><ellipse cx="36" cy="44" rx="28" ry="13"/><ellipse cx="124" cy="44" rx="28" ry="13"/><ellipse cx="80" cy="50" rx="56" ry="14"/></g>'
          '<g fill="url(#g-pasto-3)"><ellipse cx="36" cy="38" rx="28" ry="13"/><ellipse cx="124" cy="38" rx="28" ry="13"/>'
          '<ellipse cx="80" cy="28" rx="34" ry="13"/><ellipse cx="80" cy="42" rx="56" ry="14"/></g>'
          '<ellipse cx="70" cy="32" rx="34" ry="5" fill="#fff" opacity=".35"/>')


def islote(x, y, ancho, alto):
    return colocar(ISLOTE, 160, 110, x, y, ancho, alto)


def estrella(x, y, escala, relleno="#fff", extra=""):
    return f'<path d="{ESTRELLA}" transform="translate({x} {y}) scale({escala})" fill="{relleno}"{extra}/>'


def borde(d, opacidad=.6):
    return f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity="{opacidad}" stroke-width="3"/>'


# ---------------------------------------------------------------------------
# Capas del paisaje (1280x720)
# ---------------------------------------------------------------------------

def capa_cielo():
    puntos = [(560, 34, 2), (700, 60, 1.6), (820, 26, 2.2), (960, 70, 1.6), (1040, 30, 1.8), (620, 110, 1.4),
              (40, 150, 1.8), (250, 130, 1.5), (380, 40, 1.6), (150, 30, 1.4)]
    c = '<rect width="1280" height="720" fill="url(#g-cielo)"/><circle cx="760" cy="360" r="300" fill="url(#g-sol)"/>'
    c += "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff" opacity=".8"/>' for x, y, r in puntos)
    c += estrella(470, 120, .7, extra=' opacity=".8"') + estrella(1190, 150, .6, extra=' opacity=".8"')
    return svg(1280, 720, c)


def capa_nubes():
    c = nube(20, 60, 230, 104) + nube(690, 150, 170, 77) + nube(380, 190, 150, 68) + nube(1010, 140, 210, 95)
    c += islote(88, 250, 96, 66) + arbolito(128, 216, 22, 46, "#ffb3d1")
    c += islote(292, 168, 58, 40) + casita(308, 152, 24, 23, "#ff9ec4")
    return svg(1280, 720, c)


def capa_tierra():
    lejos = "M-20 392 C80 352 180 350 290 376 C380 398 450 360 560 352 C680 344 760 380 880 386 C960 390 1000 380 1040 372"
    lejos2 = "M-20 440 C40 424 80 420 120 420 C200 390 300 392 380 408 C460 424 560 396 660 398 C760 400 840 420 940 418"
    cima = "M920 470 C980 400 1050 300 1150 294 C1250 300 1290 360 1310 390"
    rosa = "M-20 470 C70 410 180 398 290 420 C380 438 430 468 480 480"
    amarilla = "M330 476 C390 410 460 378 530 376 C620 374 700 420 790 470 C830 494 860 520 880 540"
    menta = "M600 640 C680 570 760 470 870 438 C930 424 1000 430 1080 448 C1150 462 1220 472 1300 462"
    pradera = "M-20 560 C120 520 260 516 420 534 C560 550 640 556 760 548 C900 540 1040 556 1160 584 C1220 598 1260 600 1300 596"
    c = f'<path d="{lejos} L1040 720 L-20 720 Z" fill="url(#g-lejos)"/>' + borde(lejos, .55)
    c += f'<path d="{lejos2} L940 720 L-20 720 Z" fill="url(#g-lejos-2)"/>'
    c += '<g opacity=".85">' + cono(58, 318, 26, 52, "#a8e6c8") + chupetin(196, 300, 30, 64) + casita(250, 352, 34, 33, "#ff9ec4")
    c += arbolito(430, 318, 26, 56, "#ffd6a0") + cono(600, 306, 24, 50, "#ffc2d8") + casita(660, 352, 30, 29, "#8fd0ff")
    c += arbolito(790, 330, 24, 52, "#c5a8ff") + '</g>'
    # La Cima del Arcoiris (zona secreta): cerro lejano con franjas tenues y neblina.
    c += f'<path d="{cima} L1310 720 L920 720 Z" fill="url(#g-cima)"/>'
    c += ('<g fill="none" stroke-width="9" stroke-linecap="round" opacity=".55">'
          '<path d="M1000 400 C1060 330 1100 306 1150 304" stroke="#e8c8dc"/>'
          '<path d="M1006 424 C1070 350 1110 326 1160 324" stroke="#dce0ec"/>'
          '<path d="M1014 450 C1080 372 1120 348 1172 346" stroke="#d6d0ec"/></g>')
    c += borde(cima)
    c += ('<ellipse cx="1060" cy="350" rx="110" ry="34" fill="url(#g-niebla)"/>'
          '<ellipse cx="1220" cy="330" rx="100" ry="32" fill="url(#g-niebla)"/>'
          '<ellipse cx="1150" cy="382" rx="150" ry="34" fill="url(#g-niebla)"/>')
    c += f'<path d="{rosa} L480 720 L-20 720 Z" fill="url(#g-c-rosa)"/>' + borde(rosa)
    c += f'<path d="{amarilla} L880 720 L330 720 Z" fill="url(#g-c-amarilla)"/>' + borde(amarilla, .7)
    c += f'<path d="{menta} L1300 720 L600 720 Z" fill="url(#g-c-menta)"/>' + borde(menta)
    c += arbolito(30, 356, 40, 86, "#ffd36e") + chupetin(96, 330, 48, 102) + cono(252, 362, 30, 60, "#c5a8ff")
    c += arbolito(620, 350, 34, 74, "#8fd0ff") + cono(580, 370, 26, 52, "#ff9ec4") + chupetin(1010, 350, 44, 94)
    c += arbolito(1220, 366, 44, 96, "#ff9ec4") + casita(1110, 420, 46, 44, "#c5a8ff")
    c += f'<path d="{pradera} L1300 720 L-20 720 Z" fill="url(#g-suelo-verde)"/>' + borde(pradera)
    c += '<path d="M-20 650 C160 620 380 628 600 650 C820 672 1060 660 1300 640 L1300 720 L-20 720 Z" fill="url(#g-suelo)"/>'
    c += ('<ellipse cx="1000" cy="612" rx="96" ry="20" fill="#b3dcef"/><ellipse cx="1000" cy="608" rx="90" ry="17" fill="url(#g-estanque)"/>'
          '<ellipse cx="984" cy="602" rx="44" ry="5" fill="#fff" opacity=".55"/>')
    c += caramelo(210, 606, 56, 32, "#ff9ec4") + caramelo(842, 582, 40, 23, "#8fd0ff") + caramelo(1170, 566, 44, 25, "#c5a8ff")
    for x, y, lado, color in [(170, 560, 22, "#ff9ec4"), (520, 584, 18, "#fff"), (560, 606, 22, "#c5a8ff"), (300, 666, 26, "#ff9ec4"),
                              (640, 676, 24, "#ffb86b"), (880, 640, 22, "#fff"), (1110, 616, 20, "#ff9ec4"), (460, 470, 14, "#fff"),
                              (140, 452, 14, "#fff"), (900, 470, 14, "#ff9ec4"), (1240, 520, 16, "#fff")]:
        c += flor(x, y, lado, color)
    # Sombra del islote flotante (zona 4) sobre la colina menta.
    c += '<ellipse cx="930" cy="470" rx="70" ry="12" fill="url(#g-sombra)"/>'
    return svg(1280, 720, c)


# ---------------------------------------------------------------------------
# Hitos de las zonas (caja 180x180; el centro de la caja es la `posicion` de la zona en mapa.json)
# ---------------------------------------------------------------------------

HITOS = {
    "zona1": {
        "suelo": ('<ellipse cx="90" cy="138" rx="84" ry="20" fill="url(#g-sombra)"/>'
                  '<g fill="#5fae58"><ellipse cx="50" cy="130" rx="32" ry="14"/><ellipse cx="130" cy="130" rx="32" ry="14"/>'
                  '<ellipse cx="90" cy="140" rx="36" ry="13"/><ellipse cx="90" cy="120" rx="34" ry="12"/></g>'
                  '<g fill="url(#g-pasto-0)"><ellipse cx="50" cy="125" rx="32" ry="14"/><ellipse cx="130" cy="125" rx="32" ry="14"/>'
                  '<ellipse cx="90" cy="135" rx="36" ry="13"/><ellipse cx="90" cy="114" rx="34" ry="12"/></g>'
                  '<path d="M90 124 L60 125 M90 124 L120 125 M90 124 L90 114 M90 124 L90 136" stroke="#8fd27a" stroke-width="2.5" stroke-linecap="round"/>'
                  '<ellipse cx="60" cy="120" rx="16" ry="4" fill="#fff" opacity=".4"/>'),
        "hito": ('<path d="M90 128 C58 120 42 92 48 68 C54 46 74 42 90 50 C106 42 126 46 132 68 C138 92 122 120 90 128 Z" fill="url(#g-rojo)"/>'
                 '<g fill="#ffe38a"><ellipse cx="66" cy="76" rx="2.2" ry="3.2"/><ellipse cx="114" cy="76" rx="2.2" ry="3.2"/>'
                 '<ellipse cx="60" cy="96" rx="2.2" ry="3.2"/><ellipse cx="120" cy="96" rx="2.2" ry="3.2"/>'
                 '<ellipse cx="76" cy="112" rx="2.2" ry="3.2"/><ellipse cx="104" cy="112" rx="2.2" ry="3.2"/><ellipse cx="90" cy="118" rx="2.2" ry="3.2"/></g>'
                 '<ellipse cx="66" cy="62" rx="7" ry="11" fill="#fff" opacity=".45" transform="rotate(-30 66 62)"/>'
                 '<path d="M90 54 L70 46 L82 41 L76 30 L90 38 L104 30 L98 41 L110 46 Z" fill="#5bbf62" stroke="#3f9a49" stroke-width="2" stroke-linejoin="round"/>'
                 '<rect x="88" y="22" width="5" height="14" rx="2.5" fill="#3f9a49"/>'),
    },
    "zona2": {
        "suelo": ('<ellipse cx="88" cy="132" rx="72" ry="19" fill="#e8a24a" opacity=".45"/>'
                  '<ellipse cx="88" cy="128" rx="68" ry="17" fill="url(#g-charco)"/>'
                  '<ellipse cx="88" cy="129" rx="50" ry="11" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width="2.5"/>'
                  '<ellipse cx="156" cy="140" rx="20" ry="6.5" fill="#d29a4a" opacity=".45"/>'
                  '<ellipse cx="156" cy="138" rx="18" ry="5.5" fill="url(#g-estanque)"/>'),
        "hito": ('<ellipse cx="90" cy="122" rx="52" ry="9" fill="#eef6ff" stroke="#cfe0f5" stroke-width="2"/>'
                 '<path d="M48 118 L54 68 Q56 50 70 52 Q76 38 90 42 Q104 38 110 52 Q124 50 126 68 L132 118 Q90 126 48 118 Z" fill="url(#g-amarillo)"/>'
                 '<path d="M50 104 Q90 112 130 104 L132 118 Q90 126 48 118 Z" fill="#eb9a22" opacity=".45"/>'
                 '<rect x="60" y="60" width="7" height="40" rx="3.5" fill="#fff" opacity=".55"/><circle cx="76" cy="50" r="3.5" fill="#fff" opacity=".7"/>'
                 '<path d="M28 92 Q22 104 28 108 Q34 104 28 92 Z" fill="#ff9cc6"/><path d="M148 100 Q143 110 148 114 Q153 110 148 100 Z" fill="#8fd0ff"/>'),
    },
    "zona3": {
        "suelo": ('<ellipse cx="90" cy="128" rx="80" ry="18" fill="url(#g-sombra)"/>'
                  '<g fill="#9fd88a"><path d="M30 126 Q33 114 36 126 Z"/><path d="M150 128 Q153 116 156 128 Z"/>'
                  '<path d="M66 130 Q69 120 72 130 Z"/><path d="M112 130 Q115 120 118 130 Z"/></g>'),
        "hito": ('<rect x="34" y="88" width="6" height="38" rx="3" fill="#fff8ee"/><circle cx="37" cy="84" r="16" fill="url(#g-cian)"/>'
                 '<circle cx="37" cy="84" r="9" fill="none" stroke="#fff" stroke-width="3.5" opacity=".9"/>'
                 '<rect x="140" y="92" width="6" height="34" rx="3" fill="#fff8ee"/><circle cx="143" cy="88" r="15" fill="url(#g-violeta)"/>'
                 '<circle cx="143" cy="88" r="8" fill="none" stroke="#fff" stroke-width="3.5" opacity=".9"/>'
                 '<rect x="86" y="96" width="8" height="32" rx="4" fill="#fff8ee"/>'
                 '<circle cx="90" cy="66" r="40" fill="url(#g-azul)"/>'
                 '<circle cx="90" cy="66" r="30" fill="none" stroke="#fff" stroke-width="7" opacity=".95"/>'
                 '<circle cx="90" cy="66" r="19" fill="none" stroke="#bcd6ff" stroke-width="4"/>'
                 '<ellipse cx="70" cy="44" rx="7" ry="11" fill="#fff" opacity=".5" transform="rotate(-35 70 44)"/>'),
    },
    "zona4": {
        "suelo": colocar(ISLOTE, 160, 110, 10, 86, 160, 110),
        "hito": ('<path d="M50 112 A40 36 0 0 1 130 112 Z" fill="url(#g-menta)"/>'
                 '<g fill="#fff" opacity=".9"><circle cx="72" cy="92" r="2.6"/><circle cx="92" cy="82" r="2.6"/><circle cx="110" cy="94" r="2.6"/><circle cx="84" cy="102" r="2"/></g>'
                 '<rect x="40" y="106" width="100" height="34" rx="17" fill="url(#g-malva)" stroke="#efc6da" stroke-width="2"/>'
                 '<rect x="126" y="56" width="34" height="11" rx="5.5" fill="url(#g-malva)" stroke="#efc6da" stroke-width="1.5"/>'
                 '<path d="M124 57 A19 19 0 0 1 162 57 Z" fill="url(#g-naranja)"/><path d="M128 57 A15 15 0 0 1 158 57 Z" fill="#ffd6a0"/>'
                 '<g stroke="#ff9f4a" stroke-width="2"><line x1="143" y1="57" x2="143" y2="43"/><line x1="143" y1="57" x2="132" y2="48"/><line x1="143" y1="57" x2="154" y2="48"/></g>'),
    },
    "zona5": {
        "suelo": '<ellipse cx="90" cy="124" rx="62" ry="15" fill="url(#g-pasto-4)"/>',
        "hito": ('<g fill="none" stroke-width="5"><path d="M26 118 A64 64 0 0 1 154 118" stroke="#ff7f9f"/><path d="M31 118 A59 59 0 0 1 149 118" stroke="#ffb86b"/>'
                 '<path d="M36 118 A54 54 0 0 1 144 118" stroke="#ffe66b"/><path d="M41 118 A49 49 0 0 1 139 118" stroke="#8fe39a"/>'
                 '<path d="M46 118 A44 44 0 0 1 134 118" stroke="#6bc7ff"/></g>'
                 '<rect x="46" y="96" width="88" height="28" rx="7" fill="url(#g-lila)"/>'
                 '<rect x="56" y="74" width="68" height="24" rx="7" fill="url(#g-rosa)"/>'
                 '<rect x="68" y="56" width="44" height="20" rx="7" fill="url(#g-lila)"/>'
                 '<path d="M46 102 Q52 108 58 102 Q64 108 70 102 Q76 108 82 102 Q88 108 94 102 Q100 108 106 102 Q112 108 118 102 Q124 108 134 102 L134 100 L46 100 Z" fill="#fff8ee"/>'
                 '<circle cx="90" cy="50" r="7" fill="#ff3d5a"/>'),
    },
}


def dormir(texto):
    """Versión 'dormida' (gris lila, clarita): el planeta perdió sus colores (ficha de zonas §1)."""
    def gris(m):
        h = m.group(1)
        if len(h) == 3:
            h = "".join(ch * 2 for ch in h)
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
        lum = 0.3 * r + 0.59 * g + 0.11 * b
        lum = 0.55 + lum * 0.42
        rr, gg, bb = colorsys.hls_to_rgb(0.72, lum, 0.16)
        return "#%02x%02x%02x" % (round(rr * 255), round(gg * 255), round(bb * 255))
    return re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", gris, texto)


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


if __name__ == "__main__":
    main()
