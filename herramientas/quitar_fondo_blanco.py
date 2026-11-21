"""Quita el fondo blanco plano de una pose generada y la deja con alfa.

1. Fondo = píxeles casi blancos conectados al borde de la imagen (relleno por inundación).
2. Borde antialias: se "desmezcla" del blanco (alfa y color recuperados), sin halo claro.
3. Sombra de piso suelta (manchita gris bajo los pies): se borra si queda separada del cuerpo.
4. Casco burbuja (opcional, --casco cx cy r): dentro del círculo, lo casi blanco es vidrio:
   se vuelve translúcido como en los sprites base (alfa ~0,35), conservando brillos.

Uso: python herramientas/quitar_fondo_blanco.py entrada.png salida.png [--casco cx cy r]
"""
from __future__ import annotations

import argparse

import numpy as np
from PIL import Image
from scipy import ndimage

UMBRAL_FONDO = 232      # min(r,g,b) por encima de esto y poca saturación = candidato a fondo
SAT_MAX = 18


def desmezclar(rgb: np.ndarray, alfa_min: float = 0.0):
    """Separa un color mezclado con blanco: c = a*f + (1-a)*255."""
    a = (255.0 - rgb.min(-1)) / 255.0
    a = np.clip(np.maximum(a * 1.6, alfa_min), 0, 1)
    f = (rgb - (1 - a[..., None]) * 255.0) / np.maximum(a[..., None], 1e-3)
    return np.clip(f, 0, 255), a


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("entrada"); p.add_argument("salida")
    p.add_argument("--casco", nargs=4, type=float, metavar=("CX", "CY", "R", "CUELLO_Y"),
                   help="círculo del casco y la altura del cuello (bajo ella no hay vidrio)")
    p.add_argument("--excluir", nargs=4, type=int, action="append", default=[],
                   metavar=("X0", "Y0", "X1", "Y1"),
                   help="rectángulo que nunca es vidrio (una mano delante del casco)")
    p.add_argument("--vidrio-sat", type=int, default=60,
                   help="saturación máxima del vidrio (subir para cascos teñidos, p. ej. rosados)")
    p.add_argument("--sombra", nargs=3, type=int, metavar=("R", "G", "B"),
                   help="color plano de la sombra de piso: se borra si toca el fondo")
    args = p.parse_args()

    rgb = np.array(Image.open(args.entrada).convert("RGB")).astype(float)
    h, w = rgb.shape[:2]
    claro = (rgb.min(-1) > UMBRAL_FONDO) & (rgb.max(-1) - rgb.min(-1) < SAT_MAX)
    etiquetas, _ = ndimage.label(claro)
    borde = np.unique(np.concatenate([etiquetas[0], etiquetas[-1], etiquetas[:, 0], etiquetas[:, -1]]))
    fondo = np.isin(etiquetas, borde[borde > 0])

    if args.casco:
        cx, cy, r, cuello = args.casco
        yy, xx = np.indices((h, w))
        dentro = (xx - cx) ** 2 + (yy - cy) ** 2 <= (r - 2) ** 2
        fondo &= ~dentro      # el interior del casco no es fondo: es vidrio

    if args.sombra:
        cerca = np.abs(rgb - np.array(args.sombra)).max(-1) < 16
        partes, _ = ndimage.label(cerca)
        toca = np.unique(partes[ndimage.binary_dilation(fondo, iterations=2) & cerca])
        fondo |= np.isin(partes, toca[toca > 0])

    alfa = np.where(fondo, 0.0, 1.0)
    color = rgb.copy()
    # anillo de 3 px alrededor del fondo: desmezclar para borde limpio
    anillo = ndimage.binary_dilation(fondo, iterations=3) & ~fondo
    f, a = desmezclar(rgb)
    color[anillo] = f[anillo]
    alfa[anillo] = a[anillo]

    if args.casco:
        # vidrio = zona clara DENTRO del círculo, sobre el cuello, conectada al borde del
        # casco (así no se vuelven translúcidos el blanco de los ojos ni los dientes)
        claro_c = dentro & (rgb.min(-1) > 190) & (rgb.max(-1) - rgb.min(-1) < args.vidrio_sat) & (yy < cuello)
        muy_blanco = (rgb.min(-1) > 246) & (rgb.max(-1) - rgb.min(-1) < 8)
        for x0, y0, x1, y1 in args.excluir:  # ahí solo es vidrio lo casi blanco puro
            claro_c[y0:y1, x0:x1] &= muy_blanco[y0:y1, x0:x1]
        partes, _ = ndimage.label(claro_c)
        dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        anillo_c = (dist > r - 25) & (dist <= r - 2)
        ids = np.unique(partes[anillo_c & claro_c])
        vidrio = np.isin(partes, ids[ids > 0])
        # sin granos: cerrar huecos chicos del vidrio (sin pasar a zonas excluidas)
        vidrio = ndimage.binary_closing(vidrio, iterations=3) & dentro & (yy < cuello)
        for x0, y0, x1, y1 in args.excluir:
            vidrio[y0:y1, x0:x1] &= ndimage.binary_erosion(muy_blanco, iterations=2)[y0:y1, x0:x1]
        f, a = desmezclar(rgb, alfa_min=0.35)
        a = ndimage.gaussian_filter(a, 1.2)
        color[vidrio] = f[vidrio]
        alfa[vidrio] = a[vidrio]

    # quedarse con la figura principal (borra la sombra de piso y motas sueltas)
    solido = alfa > 0.5
    partes, n = ndimage.label(ndimage.binary_dilation(solido, iterations=2))
    if n > 1:
        tam = ndimage.sum(solido, partes, range(1, n + 1))
        principal = partes == (np.argmax(tam) + 1)
        alfa[~principal] = 0
    # sombra de piso pegada a las botas: gris muy claro y desaturado bajo el cuerpo
    sombra = (rgb.min(-1) > 170) & (rgb.max(-1) - rgb.min(-1) < 30) & (np.indices((h, w))[0] > h * 0.85)
    alfa[sombra & ~ndimage.binary_erosion(alfa > 0.9, iterations=4)] = 0

    out = np.dstack([color, alfa * 255]).astype(np.uint8)
    img = Image.fromarray(out)
    img = img.crop(img.getbbox())
    img.save(args.salida)
    print(f"{args.salida}  {img.size}")


if __name__ == "__main__":
    main()
