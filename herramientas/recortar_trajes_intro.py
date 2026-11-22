"""Recorta a los tres hermanos de las dos láminas de alturas (ropa de casa y traje estelar) para la
transformación de los trajes de la intro (Beat 5, escenas/nucleo/intro_trajes.tscn). Sin costo.

Las dos láminas tienen la misma composición (mismo lugar y altura de cada niño), así que cada par
casa/traje se exporta en un lienzo del MISMO tamaño y alineado por los pies: en Godot el shader de
la transformación barre de uno a otro sin que el niño "salte".

Matte por diferencia (como herramientas/extraer_base.py): el fondo es un degradé gris que solo
varía con la altura, así que el gris de cada fila se mide en los bordes de la lámina. Lo conectado
al borde y parecido a ese gris es fondo; lo encerrado por la silueta es niño (opaco), salvo dentro
del casco, donde la burbuja conserva transparencia. El piso de tierra café se descarta.

Uso:  python herramientas/recortar_trajes_intro.py
Sale: assets/cinematicas/intro/trajes/{maxi,nicole,sofia}_{casa,traje}.png
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

RAIZ = Path(__file__).resolve().parent.parent
LAMINAS = {
    "casa": RAIZ / "assets/generadas/cinematicas/intro/ropa_casa_lineup_v2.png",
    "traje": RAIZ / "assets/anclas/hermanos_alturas.png",
}
SALIDA = RAIZ / "assets/cinematicas/intro/trajes"
# Columna central aproximada de cada niño en ambas láminas (1376 px de ancho).
CENTROS = {"maxi": 410, "nicole": 672, "sofia": 965}
UMBRAL_FONDO = 13      # distancia al gris de la fila por debajo de la cual un pixel "parece fondo"
UMBRAL_OPACO = 40
MARGEN = 16


def es_tierra(img: np.ndarray) -> np.ndarray:
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    rf = np.maximum(r, 1.0)
    # café/anaranjado: el azul no supera al verde (así las botas rosadas, con más azul que verde, no son tierra)
    return (g / rf < 0.66) & (b / rf < 0.58) & (r < 236) & (r - b > 35) & (b < g * 1.12)


def matte(img: np.ndarray, con_casco: bool) -> tuple[np.ndarray, np.ndarray]:
    alto, ancho, _ = img.shape
    bordes = np.concatenate([img[:, 2:40], img[:, ancho - 40:ancho - 2]], axis=1)
    fondo = np.median(bordes, axis=1)[:, None, :]  # (alto, 1, 3)
    dist = np.abs(img - fondo).max(axis=2)
    tierra = es_tierra(img)
    tierra[: int(alto * 0.83)] = False  # solo el disco de tierra bajo los pies
    pasable = (dist < UMBRAL_FONDO) | tierra
    etiquetas, _ = ndimage.label(pasable)
    ids_borde = np.unique(np.concatenate([etiquetas[0], etiquetas[-1], etiquetas[:, 0], etiquetas[:, -1]]))
    exterior = np.isin(etiquetas, ids_borde[ids_borde > 0]) | tierra
    # Alfa suave en el contorno exterior; opaco dentro de la silueta.
    suave = np.clip((dist - 6.0) / (UMBRAL_OPACO - 6.0), 0.0, 1.0)
    alfa = np.where(exterior, np.where(tierra, 0.0, suave * (dist >= UMBRAL_FONDO)), 1.0)
    # Huecos grises grandes encerrados por la silueta: a la altura del casco son la burbuja
    # (vidrio semitransparente); más abajo son fondo visto entre piernas o brazos (transparente).
    gris_encerrado = (~exterior) & (dist < UMBRAL_FONDO + 6)
    lab_g, n = ndimage.label(gris_encerrado)
    if n:
        indices = np.arange(1, n + 1)
        tam = ndimage.sum(np.ones_like(lab_g), lab_g, index=indices)
        centros = ndimage.center_of_mass(np.ones_like(lab_g), lab_g, indices)
        dist_media = ndimage.mean(dist, lab_g, index=indices)
        for i, t, (cy, _), dm in zip(indices, tam, centros, dist_media):
            if t <= 400:
                continue
            # Estampado claro (shorts de Maxi) se parece algo al gris; el hueco entre piernas, casi nada.
            if not (con_casco and cy < alto * 0.45) and dm > (9.0 if con_casco else 5.0):
                continue
            zona = lab_g == i
            if con_casco and cy < alto * 0.45:
                alfa = np.where(zona, np.maximum(0.28, suave), alfa)
            else:
                alfa = np.where(zona, 0.0, alfa)
    # El contorno fino del disco de tierra (1-3 px) une a los tres niños: una apertura en la
    # franja del piso lo borra y deja los zapatos.
    piso = int(alto * 0.84)
    banda = ndimage.binary_opening(alfa[piso:] > 0.3, structure=np.ones((7, 7)))
    alfa[piso:] = np.where(banda, alfa[piso:], 0.0)
    # Des-mezcla del color para que el borde y el vidrio no arrastren gris.
    a = np.maximum(alfa, 1e-3)[..., None]
    color = np.clip((img - (1.0 - a) * fondo) / a, 0, 255)
    return color, alfa


def recortar(color: np.ndarray, alfa: np.ndarray, centro: int) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """Se queda con la figura (componente) que pasa por la columna del niño."""
    lab, _ = ndimage.label(alfa > 0.05)
    columna = lab[:, centro - 20:centro + 20]
    ids, cuentas = np.unique(columna[columna > 0], return_counts=True)
    figura = lab == ids[np.argmax(cuentas)]
    alfa = np.where(figura, alfa, 0.0)
    ys, xs = np.nonzero(alfa > 0.05)
    caja = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    rgba = np.dstack([color, alfa * 255.0]).astype(np.uint8)
    return rgba, caja


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    piezas: dict[str, dict[str, tuple[np.ndarray, tuple]]] = {n: {} for n in CENTROS}
    for clave, ruta in LAMINAS.items():
        img = np.asarray(Image.open(ruta).convert("RGB")).astype(np.float32)
        color, alfa = matte(img, con_casco=clave == "traje")
        for nino, cx in CENTROS.items():
            piezas[nino][clave] = recortar(color, alfa, cx)
    for nino, par in piezas.items():
        # Lienzo común: mismo ancho/alto para casa y traje, ambos apoyados en los pies (abajo) y
        # centrados en su propia caja -> el barrido del shader los superpone sin salto.
        anchos = [c[2] - c[0] for _, c in par.values()]
        altos = [c[3] - c[1] for _, c in par.values()]
        ancho, alto = max(anchos) + 2 * MARGEN, max(altos) + 2 * MARGEN
        for clave, (rgba, (x0, y0, x1, y1)) in par.items():
            lienzo = np.zeros((alto, ancho, 4), np.uint8)
            w, h = x1 - x0, y1 - y0
            ox = (ancho - w) // 2
            oy = alto - MARGEN - h
            lienzo[oy:oy + h, ox:ox + w] = rgba[y0:y1, x0:x1]
            Image.fromarray(lienzo).save(SALIDA / f"{nino}_{clave}.png")
            print(f"{nino}_{clave}.png  {ancho}x{alto}  caja={x0},{y0},{x1},{y1}")


if __name__ == "__main__":
    main()
