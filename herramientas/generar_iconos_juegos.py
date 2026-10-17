"""Genera los iconos SVG de las estaciones del mapa de planeta.

Estilo de la maqueta aprobada por el PO el 17-Oct-2026 (mapa visto desde el suelo, lenguaje del menú
de planetas): cada juego es una esfera de color con volumen y brillo, como los planetas del Mapa
Estelar, con el dibujo del juego encima. Sin texto (GDD §6 regla 3). Godot importa el SVG directo y
el mapa lo dibuja a 132 px. Reemplaza los iconos de tarjeta del 27-Sep-2026.

Salida: assets/sprites/ui/iconos_juegos/<icono>.svg (rio, lluvia, taller, formas, parejas, pinta).
Uso: python herramientas/generar_iconos_juegos.py
"""
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets/sprites/ui/iconos_juegos"
TINTA = "#2B2150"
ESTRELLA = "M12 1.5 L15 8.6 L22.6 9.2 L16.8 14.2 L18.6 21.6 L12 17.6 L5.4 21.6 L7.2 14.2 L1.4 9.2 L9 8.6 Z"

# (claro, base, oscuro) de la esfera de cada juego.
ESFERAS = {
    "rio": ("#ffd6e6", "#ff86b5", "#d4427c"),
    "formas": ("#d6e8ff", "#6fa6ff", "#3460c8"),
    "parejas": ("#eadcff", "#a882f2", "#6a42c4"),
    "pinta": ("#ffe6c4", "#ffa95a", "#e0732c"),
    "lluvia": ("#dcfaff", "#5fd4ea", "#2a9fc0"),
    "taller": ("#fff6c2", "#ffd23d", "#e0952a"),
}

# Dibujos en una caja de 100x100 (los mismos de la maqueta).
DIBUJOS = {
    "rio": ('<path d="M20 50 A30 30 0 1 1 80 50 A24 24 0 1 1 32 50 A18 18 0 1 1 68 50 A12 12 0 1 1 44 50" stroke="#7a3a5a" stroke-opacity=".25" stroke-width="13" fill="none" stroke-linecap="round" transform="translate(2 3)"/>'
            '<path d="M20 50 A30 30 0 1 1 80 50 A24 24 0 1 1 32 50 A18 18 0 1 1 68 50 A12 12 0 1 1 44 50" stroke="#fff3dd" stroke-width="12" fill="none" stroke-linecap="round"/>'
            '<circle cx="52" cy="52" r="7" fill="#8a84a6"/><circle cx="20" cy="50" r="8" fill="#ff5470"/><circle cx="50" cy="20" r="8" fill="#ffd23d"/>'
            '<circle cx="80" cy="50" r="8" fill="#4f8fe6"/><circle cx="56" cy="74" r="7" fill="#7dd87a"/>'
            '<circle cx="17" cy="47" r="2.4" fill="#fff"/><circle cx="47" cy="17" r="2.4" fill="#fff"/><circle cx="77" cy="47" r="2.4" fill="#fff"/>'),
    "formas": ('<path d="M31 16 L52 52 L10 52 Z" fill="#7dd87a" stroke="#7dd87a" stroke-width="7" stroke-linejoin="round"/>'
               '<path d="M24 30 L30 22" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".7"/>'
               '<rect x="54" y="20" width="34" height="34" rx="8" fill="#ffd23d"/><rect x="59" y="25" width="6" height="12" rx="3" fill="#fff" opacity=".7"/>'
               '<circle cx="46" cy="72" r="19" fill="#ff5470"/><ellipse cx="38" cy="64" rx="4" ry="6" fill="#fff" opacity=".6" transform="rotate(-30 38 64)"/>'
               f'<g transform="translate(47 74)"><circle cx="-6" cy="-2" r="2.6" fill="{TINTA}"/><circle cx="6" cy="-2" r="2.6" fill="{TINTA}"/>'
               f'<path d="M-4 4 Q0 8 4 4" stroke="{TINTA}" stroke-width="2.4" fill="none" stroke-linecap="round"/></g>'),
    "parejas": ('<g transform="rotate(-12 34 50)"><rect x="14" y="22" width="40" height="56" rx="9" fill="#fff6e8"/>'
                '<path d="M34 62 C22 54 22 42 29 40 C32 39 34 42 34 44 C34 42 36 39 39 40 C46 42 46 54 34 62 Z" fill="#ff6fa8"/></g>'
                f'<g transform="rotate(10 66 52)"><rect x="46" y="24" width="40" height="56" rx="9" fill="#ffffff"/>'
                f'<path d="{ESTRELLA}" transform="translate(54 40)" fill="#ffd23d"/></g>'),
    "pinta": ('<path d="M12 52 C10 30 32 16 54 18 C78 20 90 38 84 54 C80 66 68 62 64 70 C60 80 68 88 54 90 C32 94 14 76 12 52 Z" fill="#fff0d6"/>'
              '<circle cx="62" cy="77" r="6" fill="#ffa95a"/><circle cx="28" cy="48" r="7.5" fill="#ff5470"/><circle cx="38" cy="32" r="7.5" fill="#ffd23d"/>'
              '<circle cx="57" cy="30" r="7.5" fill="#7dd87a"/><circle cx="72" cy="44" r="7.5" fill="#4f8fe6"/><circle cx="34" cy="68" r="7" fill="#a882f2"/>'
              '<path d="M58 92 L88 60" stroke="#8a5a3c" stroke-width="7" stroke-linecap="round"/>'
              '<ellipse cx="90" cy="57" rx="5" ry="8" fill="#ff86b5" transform="rotate(45 90 57)"/>'),
    # Lluvia de colores: una nube con gotas de color que caen.
    "lluvia": ('<circle cx="34" cy="36" r="16" fill="#fff"/><circle cx="54" cy="28" r="20" fill="#fff"/><circle cx="72" cy="38" r="14" fill="#fff"/>'
               '<rect x="22" y="34" width="62" height="18" rx="9" fill="#fff"/><ellipse cx="54" cy="50" rx="30" ry="4" fill="#d9eef6"/>'
               '<path d="M30 60 Q24 72 30 78 Q36 72 30 60 Z" fill="#ff5470"/><path d="M52 64 Q45 78 52 85 Q59 78 52 64 Z" fill="#ffd23d"/>'
               '<path d="M74 58 Q68 70 74 76 Q80 70 74 58 Z" fill="#4f8fe6"/>'
               '<circle cx="28.5" cy="70" r="1.8" fill="#fff"/><circle cx="50" cy="75" r="2" fill="#fff"/><circle cx="72.5" cy="68" r="1.8" fill="#fff"/>'),
    # Taller de mezclas de Sofia: dos gotas que caen a un frasco y lo pintan de violeta.
    "taller": ('<path d="M30 14 Q22 28 30 34 Q38 28 30 14 Z" fill="#ff5470"/><path d="M70 14 Q62 28 70 34 Q78 28 70 14 Z" fill="#4f8fe6"/>'
               '<path d="M36 40 L64 40 L64 48 Q82 58 82 72 Q82 90 50 90 Q18 90 18 72 Q18 58 36 48 Z" fill="#fff"/>'
               '<path d="M21 68 Q50 60 79 68 Q80 88 50 88 Q20 88 21 68 Z" fill="#a882f2"/>'
               '<rect x="33" y="36" width="34" height="7" rx="3.5" fill="#f1e2cc"/>'
               '<ellipse cx="32" cy="58" rx="3" ry="7" fill="#fff" opacity=".7" transform="rotate(30 32 58)"/>'
               '<circle cx="62" cy="76" r="3" fill="#fff" opacity=".7"/>'),
}


def icono(nombre: str) -> str:
    claro, base, oscuro = ESFERAS[nombre]
    # Esfera de 248 px (r 124) en una caja de 256; el dibujo ocupa 96/132 del diametro, como en la maqueta.
    lado = 248 * 96 / 132
    origen = (256 - lado) / 2
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><defs>'
        f'<radialGradient id="g_esfera" cx="50%" cy="50%" r="50%" fx="34%" fy="28%"><stop offset="0" stop-color="{claro}"/>'
        f'<stop offset=".52" stop-color="{base}"/><stop offset="1" stop-color="{oscuro}"/></radialGradient>'
        '<radialGradient id="g_volumen" cx="50%" cy="50%" r="50%" fx="66%" fy="72%"><stop offset=".55" stop-color="#28104e" stop-opacity="0"/>'
        '<stop offset="1" stop-color="#28104e" stop-opacity=".38"/></radialGradient>'
        '</defs>'
        f'<circle cx="128" cy="128" r="124" fill="url(#g_esfera)"/><circle cx="128" cy="128" r="124" fill="url(#g_volumen)"/>'
        '<ellipse cx="84" cy="62" rx="30" ry="16" fill="#fff" opacity=".45" transform="rotate(-35 84 62)"/>'
        '<circle cx="128" cy="128" r="122" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="3"/>'
        f'<g transform="translate({origen:.1f} {origen:.1f}) scale({lado / 100:.4f})">{DIBUJOS[nombre]}</g>'
        '</svg>\n')


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    for nombre in ESFERAS:
        (SALIDA / f"{nombre}.svg").write_text(icono(nombre), encoding="utf-8")
    print(f"{len(ESFERAS)} iconos -> {SALIDA.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
