"""Recorta la nave-estrella del diseño final aprobado (assets/anclas/nave_estrella_completa_referencia.png)
para usarla como sprite (pantalla de carga, mapa estelar). El fondo pintado (cielo, nubes, pedestal)
no se puede separar por color, así que se parte de una silueta aproximada trazada a mano sobre una
cuadrícula y GrabCut (OpenCV) ajusta el borde al contorno real del dibujo.

Uso: python herramientas/recortar_nave.py
  -> assets/generadas/nave_recortes/nave_final.png          (como el diseño: mira a la izquierda)
  -> assets/generadas/nave_recortes/nave_final_derecha.png  (espejada para viajar a la derecha,
     con la placa "Hermanos Estelares" re-pegada SIN espejar para que se pueda leer)
"""
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

RAIZ = Path(__file__).resolve().parent.parent
REF = RAIZ / "assets/anclas/nave_estrella_completa_referencia.png"
SALIDA = RAIZ / "assets/generadas/nave_recortes/nave_final.png"
SALIDA_DERECHA = RAIZ / "assets/generadas/nave_recortes/nave_final_derecha.png"

# Silueta aproximada (px de la referencia 1376x768), en sentido horario desde la cúpula.
SILUETA = [
    (670, 84), (740, 95), (790, 135), (820, 200), (842, 248), (880, 245), (920, 238),
    (1105, 250), (1108, 256), (1098, 278), (1040, 310), (1025, 330), (1030, 380),
    (1060, 415), (1080, 450), (1078, 510), (1050, 555), (1000, 560), (975, 585),
    (930, 600), (880, 590), (850, 585), (760, 612), (640, 615), (480, 615), (340, 608),
    (308, 590), (302, 565), (320, 540), (300, 500), (292, 440), (295, 390), (320, 330),
    (370, 285), (440, 255), (502, 243), (525, 210), (560, 140), (610, 100),
]
BANDA = 22  # px de duda a cada lado de la silueta: GrabCut decide ahí


def main() -> None:
    img = np.array(Image.open(REF).convert("RGB"))
    alto, ancho = img.shape[:2]
    poli = np.zeros((alto, ancho), np.uint8)
    cv2.fillPoly(poli, [np.array(SILUETA, np.int32)], 1)
    dentro = ndimage.binary_erosion(poli, iterations=BANDA)
    cerca = ndimage.binary_dilation(poli, iterations=BANDA)
    mascara = np.full((alto, ancho), cv2.GC_BGD, np.uint8)
    mascara[cerca] = cv2.GC_PR_BGD
    mascara[poli.astype(bool)] = cv2.GC_PR_FGD
    mascara[dentro] = cv2.GC_FGD
    bgd, fgd = np.zeros((1, 65)), np.zeros((1, 65))
    cv2.grabCut(cv2.cvtColor(img, cv2.COLOR_RGB2BGR), mascara, None, bgd, fgd, 8, cv2.GC_INIT_WITH_MASK)
    frente = np.isin(mascara, (cv2.GC_FGD, cv2.GC_PR_FGD))
    # una sola pieza, sin agujeros, borde suave
    etiquetas, n = ndimage.label(frente)
    if n > 1:
        tam = ndimage.sum(frente, etiquetas, range(1, n + 1))
        frente = etiquetas == (np.argmax(tam) + 1)
    frente = ndimage.binary_fill_holes(frente)
    frente = ndimage.binary_opening(frente, iterations=3)
    alfa = ndimage.gaussian_filter(frente.astype(float), 1.0)
    alfa = np.clip((alfa - 0.5) * 2.2 + 0.5, 0, 1)
    rgba = np.dstack([img, (alfa * 255).astype(np.uint8)])
    y0, y1 = np.nonzero(alfa.any(1))[0][[0, -1]]
    x0, x1 = np.nonzero(alfa.any(0))[0][[0, -1]]
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba[y0:y1 + 1, x0:x1 + 1]).save(SALIDA)
    print(f"nave: {x1 - x0 + 1}x{y1 - y0 + 1} -> {SALIDA.relative_to(RAIZ)}")
    espejar(rgba[y0:y1 + 1, x0:x1 + 1])


def espejar(nave: np.ndarray) -> None:
    """Espeja la nave y vuelve a pegar la placa dorada del nombre sin espejar."""
    r, g, b = (nave[..., i].astype(int) for i in range(3))
    zona = np.zeros(r.shape, bool)
    zona[150:350, 120:480] = True  # alrededor de la placa, en coordenadas del recorte
    oro = zona & (r > 190) & (g > 120) & (g < 220) & (b < 140) & (r - b > 90)
    oro = ndimage.binary_closing(oro, iterations=4)
    etiquetas, n = ndimage.label(oro)
    tam = ndimage.sum(oro, etiquetas, range(1, n + 1))
    placa = ndimage.binary_fill_holes(etiquetas == (np.argmax(tam) + 1))
    placa = ndimage.binary_dilation(placa, iterations=7)
    espejo = nave[:, ::-1].copy()
    # borrar la placa espejada con el verde del casco que la rodea (si no, asoman letras al revés)
    reflejada = placa[:, ::-1]
    anillo = ndimage.binary_dilation(reflejada, iterations=10) & ~reflejada
    verde = np.median(espejo[anillo][:, :3], axis=0)
    capa = np.where(reflejada[..., None], verde, espejo[..., :3]).astype(float)
    borde = ndimage.gaussian_filter(reflejada.astype(float), 3.0)[..., None]
    espejo[..., :3] = (capa * borde + espejo[..., :3] * (1 - borde)).astype(np.uint8)
    ys, xs = np.nonzero(placa)
    ancho = nave.shape[1]
    # misma caja, reflejada: la placa queda donde cae en el espejo pero con el texto al derecho
    dx = (ancho - 1 - xs.max()) - xs.min()
    suave = ndimage.gaussian_filter(placa.astype(float), 2.0)[..., None]
    destino = espejo[ys.min():ys.max() + 1, xs.min() + dx:xs.max() + dx + 1].astype(float)
    origen = nave[ys.min():ys.max() + 1, xs.min():xs.max() + 1].astype(float)
    peso = suave[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    mezcla = destino * (1 - peso) + origen * peso
    mezcla[..., 3] = destino[..., 3]
    espejo[ys.min():ys.max() + 1, xs.min() + dx:xs.max() + dx + 1] = mezcla.astype(np.uint8)
    Image.fromarray(espejo).save(SALIDA_DERECHA)
    print(f"nave espejada (placa legible) -> {SALIDA_DERECHA.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
