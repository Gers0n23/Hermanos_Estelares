"""Aísla un personaje de una hoja de referencia con fondo de degradé gris (las anclas de
assets/anclas/*_referencia.png) y lo deja como PNG con transparencia: la "base" desde la
que se cortan las piezas del rig cutout (como 00_base_sofia.png / 00_base_maxi.png).

Matte por diferencia: el fondo es un degradé que solo varía con la altura, así que para
cada fila se conoce el gris exacto de fondo. El alfa de un píxel es cuánto se aleja de ese
gris, y su color real se recupera "des-mezclándolo" — así la burbuja del casco queda
semitransparente de verdad (y no gris opaco). La sombra del piso (gris neutro bajo los
pies) se descarta.

Uso:
    python herramientas/extraer_base.py <referencia.png> x0,y0,x1,y1 <salida.png> [--piso Y] [--cuello Y]
      x0..y1   caja de la vista frontal en la hoja
      --piso   fila (coords de la hoja) desde la que el gris neutro es sombra, no personaje
      --cuello fila (coords de la hoja) del cuello del traje: por encima, lo casi-gris dentro
               de la silueta es la burbuja del casco y conserva su transparencia; por debajo
               todo lo que está dentro de la silueta es traje (rosa pálido ≈ gris) y va opaco
"""

import sys

import numpy as np
from PIL import Image
from scipy import ndimage

UMBRAL_OPACO = 42   # distancia al fondo desde la que el píxel es 100% personaje
UMBRAL_NULO = 7     # por debajo: fondo puro (ruido de compresión)
AGUJERO_MAX = 400   # px: un agujero más chico dentro de la silueta es traje, no fondo
CROMA_TRAJE = 9     # croma mediana desde la que un agujero es traje pálido (fondo ≈ 0)


def fondo_por_fila(img: np.ndarray, x0: int, x1: int) -> np.ndarray:
    """Gris de fondo de cada fila: mediana de las franjas a los costados de la caja."""
    franjas = np.concatenate([img[:, max(x0 - 12, 0):max(x0 - 2, 1)], img[:, x1 + 2:x1 + 12]], axis=1)
    return np.median(franjas, axis=1)  # (alto, 3)


def main() -> None:
    ruta, caja, salida = sys.argv[1], sys.argv[2], sys.argv[3]
    piso = int(sys.argv[sys.argv.index("--piso") + 1]) if "--piso" in sys.argv else None
    cuello = int(sys.argv[sys.argv.index("--cuello") + 1]) if "--cuello" in sys.argv else None
    x0, y0, x1, y1 = map(int, caja.split(","))
    hoja = np.array(Image.open(ruta).convert("RGB")).astype(float)
    fondo = fondo_por_fila(hoja, x0, x1)[y0:y1]
    rgb = hoja[y0:y1, x0:x1]
    bg = fondo[:, None, :]
    dist = np.abs(rgb - bg).max(-1)
    alfa = np.clip((dist - UMBRAL_NULO) / (UMBRAL_OPACO - UMBRAL_NULO), 0, 1)

    if piso is not None:
        # sombra del piso: gris neutro (sin croma) y más oscuro que el fondo
        croma = rgb.max(-1) - rgb.min(-1)
        sombra = (croma < 14) & (rgb.mean(-1) < bg.mean(-1)) & (rgb.mean(-1) > 110)
        sombra[: piso - y0] = False
        alfa[sombra] = 0

    # solo el personaje: la región conexa más grande (con su halo semitransparente)
    nucleo = alfa > 0.5
    partes, _ = ndimage.label(nucleo)
    tamanos = ndimage.sum(nucleo, partes, range(partes.max() + 1))
    principal = partes == np.argmax(tamanos[1:]) + 1
    cerrada = ndimage.binary_closing(principal, iterations=3)
    # un agujero dentro de la silueta es traje pálido (tiene algo de rosa) salvo que sea
    # gris neutro: fondo encerrado (entre las piernas) o la burbuja
    agujeros, n = ndimage.label(ndimage.binary_fill_holes(cerrada) & ~cerrada)
    croma_px = rgb.max(-1) - rgb.min(-1)
    croma = ndimage.median(croma_px, agujeros, range(1, n + 1))
    tam = ndimage.sum(np.ones_like(cerrada), agujeros, range(1, n + 1))
    traje = [i + 1 for i in range(n) if tam[i] < AGUJERO_MAX or croma[i] >= CROMA_TRAJE]
    silueta = cerrada | np.isin(agujeros, traje)
    cerca = ndimage.binary_dilation(silueta, iterations=4)
    alfa = np.where(cerca, alfa, 0)
    # dentro de la silueta es personaje opaco (salvo la burbuja, sobre el cuello)
    adentro = ndimage.binary_erosion(silueta, iterations=2)
    if cuello is not None:
        croma = rgb.max(-1) - rgb.min(-1)
        burbuja = (croma < 14) & (dist < UMBRAL_OPACO)
        burbuja[cuello - y0:] = False
        adentro &= ~burbuja
    alfa[adentro] = 1.0

    # des-mezclar: c = (p - (1-a)·fondo) / a
    a = np.maximum(alfa[..., None], 1e-3)
    color = np.clip((rgb - (1 - alfa[..., None]) * bg) / a, 0, 255)
    out = np.dstack([color, alfa * 255]).round().astype(np.uint8)
    out[alfa == 0] = 0
    ys, xs = np.nonzero(alfa > 0)
    out = out[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    Image.fromarray(out).save(salida)
    print(f"base: {out.shape[1]}x{out.shape[0]} -> {salida}  (origen en la hoja: {x0 + xs.min()},{y0 + ys.min()})")


if __name__ == "__main__":
    main()
