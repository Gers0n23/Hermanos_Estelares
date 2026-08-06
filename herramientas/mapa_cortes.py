"""Dibuja el mapa de cortes de un personaje sobre su PNG con fondo transparente.

Genera una imagen guia con las lineas de corte, los circulos de articulacion y
las etiquetas de cada pieza, para seguirla a mano en Krita.

Uso:
    python herramientas/mapa_cortes.py <png_sin_fondo> <salida.png>

Las coordenadas viven en COORDENADAS del PNG original (no escaladas) dentro del
diccionario CORTES de abajo. Estan calibradas para Sofia (332x768). Para otro
personaje, ajusta los valores y vuelve a ejecutar.
"""

import sys
from PIL import Image, ImageDraw, ImageFont

ESCALA = 2
MARGEN_IZQ = 340
MARGEN_DER = 390
MARGEN_SUP = 80
MARGEN_INF = 60

ROJO = (220, 30, 60)
AZUL = (30, 110, 220)
GRIS = (120, 120, 130)

# --- Calibrado para sofia (332x768) ------------------------------------------
# Lineas de corte rectas: (x1, y1, x2, y2, codigo, etiqueta, lado_etiqueta)
LINEAS = [
    (132, 258, 202, 258, "A", "cuello: corta aqui la cabeza", "der"),
    (94, 296, 94, 470, "B", "costura brazo/torso (izq)", "izq"),
    (228, 296, 228, 470, "C", "costura brazo/torso (der)", "der"),
    (74, 490, 248, 490, "D", "ruedo de la tunica: fin del torso", "izq"),
    (84, 452, 152, 452, "E", "cadera izq: el muslo sube HASTA AQUI", "izq"),
    (170, 452, 242, 452, "F", "cadera der: el muslo sube HASTA AQUI", "der"),
]

# Articulaciones a redondear: (cx, cy, radio, etiqueta)
ARTICULACIONES = [
    (102, 298, 32, "hombro izq"),
    (226, 298, 32, "hombro der"),
    (68, 392, 26, "codo izq"),
    (254, 392, 26, "codo der"),
    (118, 550, 30, "rodilla izq"),
    (202, 550, 30, "rodilla der"),
]

# Etiquetas de pieza: (x, y, texto, lado)  lado: "izq" | "der"
PIEZAS = [
    (166, 150, "1  cabeza_casco (con pelo)", "der", 150),
    (166, 330, "2  torso", "der", 355),
    (63, 330, "3  brazo_sup_izq", "izq", 325),
    (257, 330, "4  brazo_sup_der", "der", 300),
    (60, 450, "5  antebrazo_mano_izq", "izq", 425),
    (262, 450, "6  antebrazo_mano_der", "der", 505),
    (118, 490, "7  pierna_sup_izq", "izq", 535),
    (202, 490, "8  pierna_sup_der", "der", 555),
    (110, 640, "9  pierna_inf_pie_izq", "izq", 650),
    (210, 640, "10 pierna_inf_pie_der", "der", 650),
]


def fuente(tam):
    for ruta in (r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf"):
        try:
            return ImageFont.truetype(ruta, tam)
        except OSError:
            continue
    return ImageFont.load_default()


def linea_punteada(d, p0, p1, color, ancho, trazo=10):
    x0, y0 = p0
    x1, y1 = p1
    largo = max(abs(x1 - x0), abs(y1 - y0))
    if largo == 0:
        return
    pasos = int(largo / trazo)
    for i in range(pasos + 1):
        if i % 2:
            continue
        t0, t1 = i / (pasos + 1), min((i + 1) / (pasos + 1), 1)
        d.line(
            [x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0,
             x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1],
            fill=color, width=ancho,
        )


def main(entrada, salida):
    base = Image.open(entrada).convert("RGBA")
    w, h = base.size
    base = base.resize((w * ESCALA, h * ESCALA), Image.LANCZOS)

    lienzo = Image.new("RGBA", (w * ESCALA + MARGEN_IZQ + MARGEN_DER,
                                h * ESCALA + MARGEN_SUP + MARGEN_INF),
                       (255, 255, 255, 255))
    lienzo.alpha_composite(base, (MARGEN_IZQ, MARGEN_SUP))
    d = ImageDraw.Draw(lienzo)
    f_chica = fuente(18)
    f_pieza = fuente(21)

    def T(x, y):
        return (x * ESCALA + MARGEN_IZQ, y * ESCALA + MARGEN_SUP)

    borde_izq = MARGEN_IZQ - 14
    borde_der = MARGEN_IZQ + w * ESCALA + 14

    for x1, y1, x2, y2, codigo, etiqueta, lado in LINEAS:
        d.line([T(x1, y1), T(x2, y2)], fill=ROJO, width=4)
        mx, my = T((x1 + x2) / 2, (y1 + y2) / 2)
        if lado == "izq":
            destino, ancla, punta = (borde_izq, my), "rm", T(x1, y1)
        else:
            destino, ancla, punta = (borde_der, my), "lm", T(x2, y2)
        d.line([destino, punta], fill=ROJO, width=1)
        d.text(destino, f"{codigo}  {etiqueta}", fill=ROJO, font=f_chica, anchor=ancla)

    for cx, cy, r, etiqueta in ARTICULACIONES:
        x0, y0 = T(cx - r, cy - r)
        x1, y1 = T(cx + r, cy + r)
        for k in range(0, 360, 20):
            d.arc([x0, y0, x1, y1], k, k + 10, fill=AZUL, width=3)
        d.text(((x0 + x1) / 2, y0 - 20), etiqueta, fill=AZUL, font=f_chica, anchor="ms")

    for px, py, texto, lado, ey in PIEZAS:
        cx, cy = T(px, py)
        _, ty = T(0, ey)
        if lado == "izq":
            destino, ancla = (borde_izq, ty), "rm"
        else:
            destino, ancla = (borde_der, ty), "lm"
        d.line([destino, (cx, cy)], fill=GRIS, width=1)
        d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=GRIS)
        d.text(destino, texto, fill=(20, 20, 30), font=f_pieza, anchor=ancla)

    d.text((lienzo.width / 2, 20), "MAPA DE CORTES - sofia   (10 piezas)",
           fill=(20, 20, 30), font=fuente(26), anchor="ma")
    d.text((lienzo.width / 2, 52),
           "rojo = por donde cortar        azul punteado = redondear la pieza aqui",
           fill=(90, 90, 100), font=f_pieza, anchor="ma")

    lienzo.convert("RGB").save(salida)
    print(f"escrito: {salida}  ({lienzo.width}x{lienzo.height})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
