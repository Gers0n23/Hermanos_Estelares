"""Genera los iconos SVG de las estaciones del mapa de planeta (pedido del PO 27-Sep-2026).

Reemplazan a los iconos planos dibujados con primitivas en mapa_planeta.gd: mismo lenguaje del
juego (contorno azul noche #2B3350, volumen con degradado, brillo, sombra suave y caritas kawaii),
sin texto (GDD §6 regla 3). Godot importa el SVG directo.

Salida: assets/sprites/ui/iconos_juegos/<icono>.svg (rio, lluvia, taller, formas, parejas, pinta).
Uso: python herramientas/generar_iconos_juegos.py
"""
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets/sprites/ui/iconos_juegos"
TINTA = "#2B3350"
TRAZO = 8

# (claro, base, oscuro) por color: el degradado va de claro (arriba-izquierda) a oscuro.
TONOS = {
    "rojo": ("#FF9A9A", "#FF5A5A", "#E03A4A"),
    "amarillo": ("#FFF1A6", "#FFD23F", "#F2A92C"),
    "azul": ("#9CC4FF", "#4A8BE0", "#2F63C4"),
    "verde": ("#B8F0A0", "#6CCF63", "#3FA24D"),
    "turquesa": ("#A8F0EA", "#45C6C0", "#2A9C9A"),
    "violeta": ("#D9C2FF", "#A57BE8", "#7A52C9"),
    "rosado": ("#FFC4DE", "#FF8CC6", "#E25E9F"),
    "naranja": ("#FFD0A0", "#FF9A3C", "#E0702A"),
    "crema": ("#FFFFFF", "#FFF8EE", "#F1E2CC"),
    "madera": ("#F8DDB4", "#E9B97E", "#C98E55"),
}


def degradados(nombres) -> str:
    salida = []
    for n in nombres:
        claro, base, oscuro = TONOS[n]
        salida.append(
            f'<linearGradient id="g_{n}" x1="0.2" y1="0" x2="0.8" y2="1">'
            f'<stop offset="0" stop-color="{claro}"/><stop offset="0.45" stop-color="{base}"/>'
            f'<stop offset="1" stop-color="{oscuro}"/></linearGradient>')
    return "".join(salida)


def svg(cuerpo: str, colores) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'
            f'<defs>{degradados(colores)}</defs>{cuerpo}</svg>\n')


def sombra(cx, cy, rx, ry=None) -> str:
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry or rx * 0.22:.1f}" fill="{TINTA}" opacity="0.16"/>'


def brillo(cx, cy, rx, ry, giro=-25) -> str:
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#FFFFFF" opacity="0.7" transform="rotate({giro} {cx} {cy})"/>'


def cara(cx, cy, e=1.0, feliz=False) -> str:
    ojos = ""
    for lado in (-1, 1):
        x = cx + lado * 12 * e
        if feliz:
            ojos += (f'<path d="M{x - 6 * e:.1f} {cy + 1 * e:.1f} Q{x:.1f} {cy - 8 * e:.1f} {x + 6 * e:.1f} {cy + 1 * e:.1f}" '
                     f'fill="none" stroke="{TINTA}" stroke-width="{3.6 * e:.1f}" stroke-linecap="round"/>')
        else:
            ojos += (f'<ellipse cx="{x:.1f}" cy="{cy:.1f}" rx="{4.2 * e:.1f}" ry="{5.6 * e:.1f}" fill="{TINTA}"/>'
                     f'<circle cx="{x - 1.4 * e:.1f}" cy="{cy - 2.2 * e:.1f}" r="{1.7 * e:.1f}" fill="#FFFFFF"/>')
        ojos += f'<ellipse cx="{cx + lado * 21 * e:.1f}" cy="{cy + 8 * e:.1f}" rx="{5.5 * e:.1f}" ry="{3.2 * e:.1f}" fill="#FF6F9C" opacity="0.5"/>'
    boca = (f'<path d="M{cx - 6 * e:.1f} {cy + 7 * e:.1f} Q{cx:.1f} {cy + 13 * e:.1f} {cx + 6 * e:.1f} {cy + 7 * e:.1f}" '
            f'fill="none" stroke="{TINTA}" stroke-width="{3.4 * e:.1f}" stroke-linecap="round"/>')
    return ojos + boca


def gota(cx, cy, r, color, con_cara=True, feliz=True) -> str:
    punta = cy - 1.8 * r
    d = (f"M{cx} {punta:.1f} C{cx + 0.3 * r:.1f} {cy - 1.25 * r:.1f} {cx + r:.1f} {cy - 0.72 * r:.1f} {cx + r:.1f} {cy:.1f} "
         f"A{r} {r} 0 1 1 {cx - r:.1f} {cy:.1f} C{cx - r:.1f} {cy - 0.72 * r:.1f} {cx - 0.3 * r:.1f} {cy - 1.25 * r:.1f} {cx} {punta:.1f} Z")
    s = (f'<path d="{d}" fill="url(#g_{color})" stroke="{TINTA}" stroke-width="{TRAZO}" stroke-linejoin="round"/>'
         + brillo(cx - 0.42 * r, cy - 0.45 * r, 0.16 * r, 0.3 * r, 25))
    if con_cara:
        s += cara(cx, cy + 0.12 * r, r / 30.0, feliz)
    return s


def chispa(cx, cy, r, color="#FFFFFF") -> str:
    d = (f"M{cx} {cy - r} Q{cx + 0.18 * r:.1f} {cy - 0.18 * r:.1f} {cx + r} {cy} Q{cx + 0.18 * r:.1f} {cy + 0.18 * r:.1f} {cx} {cy + r} "
         f"Q{cx - 0.18 * r:.1f} {cy + 0.18 * r:.1f} {cx - r} {cy} Q{cx - 0.18 * r:.1f} {cy - 0.18 * r:.1f} {cx} {cy - r} Z")
    return f'<path d="{d}" fill="{color}" stroke="{TINTA}" stroke-width="3" stroke-linejoin="round"/>'


def estrella(cx, cy, r, color="amarillo") -> str:
    import math
    puntos = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.48
        puntos.append(f"{cx + math.cos(a) * rr:.1f},{cy + math.sin(a) * rr:.1f}")
    return f'<polygon points="{" ".join(puntos)}" fill="url(#g_{color})" stroke="{TINTA}" stroke-width="{TRAZO * 0.8:.1f}" stroke-linejoin="round"/>'


def nube(cx, cy) -> str:
    circulos = [(-48, 8, 30), (-18, -14, 38), (22, -10, 34), (50, 10, 26), (0, 14, 34)]
    borde = "".join(f'<circle cx="{cx + x}" cy="{cy + y}" r="{r + TRAZO / 2}" fill="{TINTA}"/>' for x, y, r in circulos)
    borde += f'<rect x="{cx - 50}" y="{cy + 8}" width="100" height="{36 + TRAZO / 2}" rx="18" fill="{TINTA}"/>'
    relleno = "".join(f'<circle cx="{cx + x}" cy="{cy + y}" r="{r - TRAZO / 2}" fill="url(#g_crema)"/>' for x, y, r in circulos)
    relleno += f'<rect x="{cx - 50}" y="{cy + 8}" width="100" height="{36 - TRAZO / 2}" rx="14" fill="url(#g_crema)"/>'
    return borde + relleno + brillo(cx - 30, cy - 18, 9, 5, -20) + cara(cx, cy + 12, 1.0, True)


def lluvia() -> str:
    cuerpo = (sombra(128, 238, 70)
              + nube(128, 64)
              + '<path d="M60 120 l-6 14 M120 118 l-6 14 M190 120 l-6 14" stroke="#9CC4FF" stroke-width="6" stroke-linecap="round"/>'
              + gota(64, 190, 24, "rojo", True, False)
              + gota(130, 206, 30, "azul", True, True)
              + gota(196, 186, 24, "amarillo", True, False)
              + chispa(34, 136, 10) + chispa(226, 132, 9))
    return svg(cuerpo, ["rojo", "azul", "amarillo", "crema"])


def taller() -> str:
    frasco = (
        # vidrio
        f'<rect x="64" y="104" width="128" height="128" rx="30" fill="#E8F6FF" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
        # pintura por capas que se mezclan (abajo el verde logrado, arriba azul y amarillo)
        '<path d="M72 170 Q100 158 128 170 T184 168 L184 202 Q184 224 162 224 L94 224 Q72 224 72 202 Z" fill="url(#g_verde)"/>'
        '<path d="M72 170 Q100 158 128 170 T184 168 L184 176 Q156 186 128 176 T72 178 Z" fill="#FFFFFF" opacity="0.35"/>'
        '<path d="M92 196 Q112 184 128 198 T168 196" fill="none" stroke="#DDF7C8" stroke-width="5" stroke-linecap="round"/>'
        # brillos del vidrio
        '<rect x="78" y="116" width="11" height="78" rx="5.5" fill="#FFFFFF" opacity="0.8"/>'
        '<rect x="95" y="116" width="5" height="46" rx="2.5" fill="#FFFFFF" opacity="0.7"/>'
        f'<rect x="64" y="104" width="128" height="128" rx="30" fill="none" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
        # aro de la boca
        f'<rect x="56" y="92" width="144" height="22" rx="11" fill="#DDF4FF" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
        + cara(128, 206, 1.0, True)
    )
    cuerpo = (sombra(128, 240, 74)
              + frasco
              + gota(98, 52, 20, "amarillo", False)
              + gota(158, 70, 22, "azul", False)
              + '<path d="M100 76 l0 10 M158 98 l0 8" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity="0.9"/>'
              + chispa(214, 118, 12, "#FFE38A") + chispa(40, 128, 9) + chispa(210, 40, 8))
    return svg(cuerpo, ["amarillo", "azul", "verde"])


def formas() -> str:
    triangulo = (f'<path d="M78 40 Q84 30 90 40 L134 118 Q138 128 126 128 L42 128 Q30 128 36 118 Z" fill="url(#g_verde)" '
                 f'stroke="{TINTA}" stroke-width="{TRAZO}" stroke-linejoin="round"/>' + brillo(70, 76, 6, 14, 30) + cara(84, 104, 0.8))
    cuadrado = (f'<rect x="138" y="58" width="84" height="84" rx="20" fill="url(#g_azul)" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
                + brillo(160, 80, 7, 13, 35) + cara(180, 104, 0.9, True))
    circulo = (f'<circle cx="118" cy="176" r="50" fill="url(#g_rojo)" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
               + brillo(96, 152, 9, 16, 35) + cara(118, 180, 1.15))
    cuerpo = sombra(128, 238, 78) + triangulo + cuadrado + circulo + chispa(214, 190, 13, "#FFE38A") + chispa(40, 170, 9)
    return svg(cuerpo, ["verde", "azul", "rojo"])


def parejas() -> str:
    def carta(cx, cy, giro, fondo, contenido):
        return (f'<g transform="rotate({giro} {cx} {cy})">'
                f'<rect x="{cx - 50}" y="{cy - 68}" width="100" height="136" rx="20" fill="{TINTA}" opacity="0.18" transform="translate(4 8)"/>'
                f'<rect x="{cx - 50}" y="{cy - 68}" width="100" height="136" rx="20" fill="url(#g_{fondo})" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
                f'<rect x="{cx - 38}" y="{cy - 56}" width="76" height="112" rx="12" fill="none" stroke="#FFFFFF" stroke-width="4" opacity="0.6"/>'
                + contenido + '</g>')
    corazon = (f'<path d="M92 140 C60 118 58 92 76 86 C86 82 92 90 92 96 C92 90 98 82 108 86 C126 92 124 118 92 140 Z" '
               f'fill="url(#g_rosado)" stroke="{TINTA}" stroke-width="6" stroke-linejoin="round"/>' + brillo(78, 98, 4, 7, 30))
    cuerpo = (sombra(128, 236, 80)
              + carta(92, 124, -12, "violeta", corazon)
              + carta(164, 128, 10, "crema", estrella(164, 128, 34))
              + chispa(128, 40, 13, "#FFE38A") + chispa(222, 58, 9) + chispa(34, 60, 8))
    return svg(cuerpo, ["violeta", "crema", "rosado", "amarillo"])


def pinta() -> str:
    paleta = (f'<path d="M40 142 C34 92 86 60 142 64 C196 68 226 104 214 140 C206 164 178 160 170 176 C160 196 176 214 146 220 '
              f'C92 230 46 196 40 142 Z" fill="url(#g_madera)" stroke="{TINTA}" stroke-width="{TRAZO}" stroke-linejoin="round"/>'
              f'<ellipse cx="174" cy="198" rx="14" ry="11" fill="#FFF8EE" stroke="{TINTA}" stroke-width="6"/>'
              + brillo(70, 104, 8, 18, 50))
    manchas = ""
    for (x, y, c) in [(78, 142, "rojo"), (104, 102, "amarillo"), (148, 96, "verde"), (186, 124, "azul"), (104, 184, "violeta")]:
        manchas += f'<circle cx="{x}" cy="{y}" r="17" fill="url(#g_{c})" stroke="{TINTA}" stroke-width="5"/>' + brillo(x - 6, y - 6, 3.5, 6, 30)
    pincel = (f'<g transform="rotate(38 150 150)">'
              f'<rect x="138" y="96" width="24" height="130" rx="12" fill="url(#g_naranja)" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
              f'<rect x="136" y="72" width="28" height="30" rx="6" fill="#DCE3F0" stroke="{TINTA}" stroke-width="{TRAZO}"/>'
              f'<path d="M138 74 Q150 18 162 74 Z" fill="url(#g_rosado)" stroke="{TINTA}" stroke-width="{TRAZO}" stroke-linejoin="round"/>'
              f'<rect x="143" y="110" width="6" height="96" rx="3" fill="#FFFFFF" opacity="0.5"/></g>')
    cuerpo = sombra(128, 236, 84) + paleta + manchas + pincel + chispa(38, 58, 11, "#FFE38A") + chispa(222, 214, 9)
    return svg(cuerpo, ["madera", "rojo", "amarillo", "verde", "azul", "violeta", "naranja", "rosado"])


def rio() -> str:
    """Río de pintura (PO 06-Oct-2026): cauce de galleta en espiral con gotas que van al remolino gris."""
    import math
    puntos = []
    for k in range(0, 181):
        t = math.pi * 0.9 + k / 180 * math.pi * 2.6
        r = 92 - 58 * k / 180
        puntos.append((128 + r * 1.12 * math.cos(t), 132 + r * 0.9 * math.sin(t)))
    d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in puntos)
    cauce = (f'<path d="{d}" fill="none" stroke="{TINTA}" stroke-width="40" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<path d="{d}" fill="none" stroke="#E9C58F" stroke-width="30" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<path d="{d}" fill="none" stroke="#FFF6E8" stroke-width="20" stroke-linecap="round" stroke-linejoin="round"/>')
    cx, cy = puntos[-1]
    remolino = (f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="20" fill="#7C7890" stroke="{TINTA}" stroke-width="6"/>'
                f'<path d="M{cx - 10:.1f} {cy:.1f} A10 10 0 1 1 {cx + 4:.1f} {cy + 8:.1f}" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>')
    gotas = ""
    for indice, color in [(8, "rojo"), (34, "amarillo"), (60, "azul"), (86, "rosado"), (112, "verde")]:
        x, y = puntos[indice]
        gotas += gota(x, y, 17, color, con_cara=False)
    cuerpo = sombra(128, 236, 84) + cauce + remolino + gotas + chispa(222, 46, 11, "#FFE38A") + chispa(34, 214, 9)
    return svg(cuerpo, ["rojo", "amarillo", "azul", "rosado", "verde", "crema"])


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    for nombre, generador in {"rio": rio, "lluvia": lluvia, "taller": taller, "formas": formas, "parejas": parejas, "pinta": pinta}.items():
        ruta = SALIDA / f"{nombre}.svg"
        ruta.write_text(generador(), encoding="utf-8")
        print("icono:", ruta.relative_to(RAIZ))


if __name__ == "__main__":
    main()
