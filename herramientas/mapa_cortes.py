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

# --- Calibrado para maxi (306x697) --------------------------------------------
# Maxi tiene 2 años y su traje no tiene costura de codo ni tunica con vuelo: se
# simplifica a 8 piezas (brazo+antebrazo fusionados por lado, sin cinturon aparte
# porque el cinturon queda plano dentro del torso, sin faldon que lo tape).
# Lineas de corte rectas: (x1, y1, x2, y2, codigo, etiqueta, lado_etiqueta)
LINEAS = [
    (118, 233, 190, 233, "A", "cuello: corta aqui la cabeza", "der"),
    (90, 255, 90, 400, "B", "costura brazo/torso (izq)", "izq"),
    (216, 255, 216, 400, "C", "costura brazo/torso (der)", "der"),
    (55, 400, 250, 400, "D", "cintura: fin del torso (corte recto)", "izq"),
    (95, 378, 150, 378, "E", "cadera izq: el muslo sube HASTA AQUI", "izq"),
    (160, 378, 215, 378, "F", "cadera der: el muslo sube HASTA AQUI", "der"),
]

# Articulaciones a redondear: (cx, cy, radio, etiqueta)
# Sin codo: el brazo va fusionado en una sola pieza (brazo_mano_*), no hay corte ahi.
ARTICULACIONES = [
    (76, 283, 32, "hombro izq"),
    (230, 283, 32, "hombro der"),
    (122, 525, 30, "rodilla izq"),
    (192, 525, 30, "rodilla der"),
]

# Etiquetas de pieza: (x, y, texto, lado)  lado: "izq" | "der"
PIEZAS = [
    (154, 110, "1  cabeza_casco (con pelo)", "der", 110),
    (153, 320, "2  torso (con cinturon)", "der", 340),
    (55, 330, "3  brazo_mano_izq (fusionado)", "izq", 300),
    (250, 330, "4  brazo_mano_der (fusionado)", "der", 260),
    (122, 440, "5  pierna_sup_izq", "izq", 430),
    (192, 440, "6  pierna_sup_der", "der", 450),
    (110, 600, "7  pierna_inf_pie_izq", "izq", 580),
    (205, 600, "8  pierna_inf_pie_der", "der", 610),
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

    d.text((lienzo.width / 2, 20), "MAPA DE CORTES - maxi   (8 piezas)",
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
