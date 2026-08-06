# despiece_a_svg.py — separa una hoja de despiece (piezas de personaje ya generadas
# aisladas entre si por Nano Banana Pro) en SVG individuales listos para riggear en Godot.
#
# Uso:
#   python herramientas/despiece_a_svg.py <hoja.png> <carpeta_salida> [--fondo R,G,B]
#
# Que hace, por cada pieza detectada en la hoja:
#   1. Detecta regiones separadas por fondo solido (componentes conexas).
#   2. Quita el fondo con descontaminacion de color (evita el halo gris en el borde).
#   3. Limpia la mascara con apertura/cierre morfologico (evita ruido en mechones/bordes finos).
#   4. Vectoriza con vtracer (parametros validados en la prueba de Sofia, HE-A2/HE-D2).
#
# Requiere (pip install pillow numpy scipy vtracer): pillow, numpy, scipy, vtracer
#
# Las piezas salen numeradas por posicion (pieza_01, pieza_02...), NO por nombre de
# parte del cuerpo: renombralas a mano (cabeza_casco, torso, brazo_sup_izq,
# antebrazo_mano_izq, pierna_sup_der, pierna_inf_pie_der...) despues de revisar
# visualmente cada .png, antes de pasarlas a dev-godot para el rig.

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage
import vtracer

AJUSTES_VTRACER = dict(
    colormode="color",
    hierarchical="stacked",
    mode="spline",
    filter_speckle=4,
    color_precision=6,
    layer_difference=24,
    corner_threshold=75,
    length_threshold=4.0,
    max_iterations=10,
    splice_threshold=50,
    path_precision=3,
)

AREA_MINIMA_PIEZA = 200  # px^2; descarta motas de ruido que no son piezas reales
MARGEN_RECORTE = 10  # px de aire alrededor de cada pieza detectada


def detectar_piezas(rgb: np.ndarray, fondo: np.ndarray, umbral: float = 15.0):
    dist = np.sqrt(((rgb.astype(float) - fondo) ** 2).sum(axis=2))
    mascara = dist > umbral
    mascara = ndimage.binary_opening(mascara, structure=np.ones((3, 3)))
    etiquetas, n = ndimage.label(mascara, structure=np.ones((3, 3)))
    cajas = ndimage.find_objects(etiquetas)
    h, w = mascara.shape
    piezas = []
    for i, caja in enumerate(cajas, start=1):
        if caja is None:
            continue
        area = int((etiquetas[caja] == i).sum())
        if area < AREA_MINIMA_PIEZA:
            continue
        y0 = max(0, caja[0].start - MARGEN_RECORTE)
        y1 = min(h, caja[0].stop + MARGEN_RECORTE)
        x0 = max(0, caja[1].start - MARGEN_RECORTE)
        x1 = min(w, caja[1].stop + MARGEN_RECORTE)
        piezas.append((x0, y0, x1, y1))
    # orden de lectura natural: filas de arriba a abajo, izquierda a derecha dentro de cada fila
    piezas.sort(key=lambda c: (round(c[1] / 100.0), c[0]))
    return piezas


def descontaminar(recorte_rgba: Image.Image, fondo: np.ndarray,
                   umbral_bajo: float = 10.0, umbral_alto: float = 15.0,
                   alpha_min: float = 0.35) -> Image.Image:
    arr = np.array(recorte_rgba).astype(float)
    rgb = arr[:, :, :3]
    dist = np.sqrt(((rgb - fondo) ** 2).sum(axis=2))
    alpha = np.clip((dist - umbral_bajo) / (umbral_alto - umbral_bajo), 0, 1)

    binaria = alpha > 0.4
    cerrada = ndimage.binary_closing(binaria, structure=np.ones((3, 3)), iterations=1)
    abierta = ndimage.binary_opening(cerrada, structure=np.ones((2, 2)), iterations=1)
    alpha_limpia = np.where(abierta, np.maximum(alpha, 0.6), 0.0)

    alpha_seguro = np.clip(alpha_limpia, alpha_min, 1.0)[:, :, None]
    fg = (rgb - (1 - alpha_seguro) * fondo) / alpha_seguro
    fg = np.clip(fg, 0, 255)

    salida = np.dstack([fg, alpha_limpia * 255]).astype("uint8")
    return Image.fromarray(salida)


def vectorizar(png_path: Path, svg_path: Path) -> None:
    vtracer.convert_image_to_svg_py(str(png_path), str(svg_path), **AJUSTES_VTRACER)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("hoja", help="Ruta a la hoja de despiece (PNG)")
    ap.add_argument("salida", help="Carpeta donde escribir las piezas (PNG+SVG)")
    ap.add_argument("--fondo", default=None,
                    help="Color de fondo 'R,G,B'; si se omite se toma de la esquina superior izquierda")
    args = ap.parse_args()

    hoja = Image.open(args.hoja).convert("RGBA")
    arr = np.array(hoja)

    if args.fondo:
        fondo = np.array([float(c) for c in args.fondo.split(",")])
    else:
        fondo = arr[2, 2, :3].astype(float)

    piezas = detectar_piezas(arr[:, :, :3], fondo)
    carpeta = Path(args.salida)
    carpeta.mkdir(parents=True, exist_ok=True)

    print(f"Fondo detectado/usado: {fondo.tolist()}")
    print(f"{len(piezas)} piezas detectadas en {args.hoja}")

    for i, (x0, y0, x1, y1) in enumerate(piezas, start=1):
        recorte = hoja.crop((x0, y0, x1, y1))
        limpio = descontaminar(recorte, fondo)
        nombre = f"pieza_{i:02d}"
        png_tmp = carpeta / f"{nombre}.png"
        svg_out = carpeta / f"{nombre}.svg"
        limpio.save(png_tmp)
        vectorizar(png_tmp, svg_out)
        print(f"  {nombre}: recorte ({x0},{y0})-({x1},{y1}), tamano {recorte.size} -> {svg_out.name}")

    print()
    print("Listo. Revisa cada pieza_NN.png a ojo y renombra segun la parte del cuerpo que sea")
    print("(cabeza_casco, torso, brazo_sup_izq, antebrazo_mano_izq, pierna_sup_der, ")
    print("pierna_inf_pie_der...) antes de pasarlas a dev-godot para el rig.")


if __name__ == "__main__":
    main()
