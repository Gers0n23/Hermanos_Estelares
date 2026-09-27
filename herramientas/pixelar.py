"""Convierte arte aprobado (PNG con transparencia) en sprite pixel art coherente.

Pasos: recorte al contenido -> reducción por promedio de área (BOX, no nearest:
conserva la forma) -> alfa binario (sin semitransparencias, como el pixel art real)
-> paleta limitada común (k-means sobre todos los sprites juntos, para que el elenco
comparta colores) -> contorno exterior de 1 px con el tono más oscuro de la paleta.

Uso:
    python herramientas/pixelar.py <alto_px> <n_colores> <salida_dir> img1.png [img2.png ...]
      (una entrada puede ser  ruta.png@x,y,ancho,alto  para recortar una zona antes)
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def cargar(entrada: str) -> tuple[str, Image.Image]:
    ruta, _, zona = entrada.partition("@")
    img = Image.open(ruta).convert("RGBA")
    if zona:
        x, y, w, h = map(int, zona.split(","))
        img = img.crop((x, y, x + w, y + h))
    if img.getextrema()[3][0] == 255:  # sin transparencia: fondo por color de esquina
        arr = np.array(img).astype(int)
        esquina = arr[2, 2, :3]
        fondo = np.abs(arr[..., :3] - esquina).sum(-1) < 40
        arr[fondo, 3] = 0
        img = Image.fromarray(arr.astype(np.uint8))
    return Path(ruta).stem, img.crop(img.getbbox())


def reducir(img: Image.Image, alto: int) -> np.ndarray:
    ancho = max(1, round(img.width * alto / img.height))
    # premultiplicar alfa para que el borde no se ensucie con el color del fondo
    arr = np.array(img).astype(float)
    arr[..., :3] *= arr[..., 3:] / 255
    pre = Image.fromarray(arr.astype(np.uint8)).resize((ancho, alto), Image.BOX)
    chico = np.array(pre).astype(float)
    a = chico[..., 3:]
    chico[..., :3] = np.where(a > 0, chico[..., :3] * 255 / np.maximum(a, 1), 0)
    chico[..., 3] = np.where(chico[..., 3] >= 110, 255, 0)
    return chico.astype(np.uint8)


def kmeans(pixeles: np.ndarray, k: int, iteraciones: int = 25) -> np.ndarray:
    rng = np.random.default_rng(7)
    centros = pixeles[rng.choice(len(pixeles), k, replace=False)].astype(float)
    for _ in range(iteraciones):
        d = ((pixeles[:, None, :] - centros[None]) ** 2).sum(-1)
        grupo = d.argmin(1)
        for i in range(k):
            if (grupo == i).any():
                centros[i] = pixeles[grupo == i].mean(0)
    return centros.round().astype(np.uint8)


def main() -> None:
    alto, n_colores, salida = int(sys.argv[1]), int(sys.argv[2]), Path(sys.argv[3])
    salida.mkdir(parents=True, exist_ok=True)
    sprites = [(n, reducir(img, alto)) for n, img in map(cargar, sys.argv[4:])]
    todos = np.concatenate([s[s[..., 3] > 0][:, :3] for _, s in sprites]).astype(float)
    paleta = kmeans(todos, n_colores)
    oscuro = paleta[paleta.astype(int).sum(1).argmin()]
    for nombre, s in sprites:
        opaco = s[..., 3] > 0
        d = ((s[..., :3][..., None, :].astype(float) - paleta[None, None]) ** 2).sum(-1)
        s[..., :3] = paleta[d.argmin(-1)]
        # contorno exterior de 1 px (lienzo con margen para que no se corte)
        lienzo = np.zeros((s.shape[0] + 2, s.shape[1] + 2, 4), np.uint8)
        lienzo[1:-1, 1:-1] = s
        o = np.pad(opaco, 1)
        borde = ndimage.binary_dilation(o, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~o
        lienzo[borde] = (*oscuro, 255)
        Image.fromarray(lienzo).save(salida / f"{nombre}.png")
        print(f"  {nombre}: {lienzo.shape[1]}x{lienzo.shape[0]}")
    print(f"paleta de {n_colores} colores -> {salida}")


if __name__ == "__main__":
    main()
