"""Rig de POSE de celebración (HE-143): corta una pose dibujada en 3 piezas animables.

Por qué así: girar 125° un brazo dibujado colgando quiebra hombro y codo (decisión del PO,
21-Nov-2026: poses dibujadas + giros chicos). Cada pose de victoria ya viene dibujada
entera; el rig solo agrega vida con giros pequeños, sin volver a romper articulaciones:

  cuerpo        fijo (z 0) — sin la cabeza ni el gesto; los huecos se rellenan pintando
  cabeza_casco  pivote en el cuello (z 1) — ladeos de ±3-4°
  gesto         pivote en el codo o la muñeca (z 2) — puño que se agita, paz que se mece,
                corazón que late (giro de ±8° y/o escala 1,08)

Todas las piezas son PNG del tamaño del lienzo completo con la pieza en su lugar (mismo
formato que assets/sprites/preview_*_rig/), así el rig solo necesita pivotes.

Uso:  python herramientas/armar_rig_poses.py
      (lee assets/generadas/poses_rig/<pose>_sin_fondo.png, que sale de
       herramientas/quitar_fondo_blanco.py)
Salida: assets/generadas/poses_rig/<pose>/{cuerpo,cabeza_casco,gesto}.png, pivotes.json
        y una hoja de vista previa con 5 cuadros de la animación en <pose>/vista_previa.png
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "assets/generadas/poses_rig"
BANDA = 22  # px que el cuerpo conserva sobre el corte del cuello (tapa la unión al ladear)
MARGEN = 90  # borde transparente alrededor de las piezas (giros y balanceo sin cortes)

# Coordenadas en el lienzo de <pose>_sin_fondo.png. Medidas sobre grilla (21-Nov-2026).
POSES = {
    "maxi_victoria_v1": {
        "cuello_y": 385, "pivote_cabeza": (265, 392),
        # antebrazo + puño, sin el vidrio del casco (círculo que se descuenta)
        "gesto": [(470, 55), (579, 55), (579, 275), (485, 372), (402, 342), (438, 250)],
        "pivote_gesto": (445, 350), "radio_union": 38, "sin_circulo": (251, 211, 213),
        # animación: (giro cabeza °, giro gesto °, escala gesto, salto px)
        "cuadros": [(0, 0, 1, 0), (-3, -9, 1, -40), (0, 6, 1, -60), (3, -6, 1, -40), (0, 0, 1, 0)],
    },
    "nicole_victoria_v2": {
        "cuello_y": 360, "pivote_cabeza": (215, 366),
        "gesto": [(0, 288), (112, 288), (118, 380), (108, 445), (60, 455), (0, 448)],
        "pivote_gesto": (58, 447), "radio_union": 26, "solo_guante": True,
        "casco_detras": (208, 224, 190),  # vidrio que la mano tapa: se rellena en la cabeza
        "cuadros": [(0, 0, 1, 0), (-3, 0, 1.08, 0), (-4, 4, 1.0, 0), (-3, 0, 1.08, 0), (0, 0, 1, 0)],
    },
    "sofia_victoria_v1": {
        "cuello_y": 330, "pivote_cabeza": (290, 336),
        "gesto": [(478, 268), (586, 268), (586, 335), (548, 420), (522, 482), (492, 528),
                  (440, 508), (452, 440), (488, 380)],
        "pivote_gesto": (470, 505), "radio_union": 34,
        "cuadros": [(0, 0, 1, 0), (-3, -8, 1, 0), (-4, 0, 1, 0), (-3, 8, 1, 0), (0, 0, 1, 0)],
    },
}


def poligono(forma, puntos) -> np.ndarray:
    img = Image.new("L", (forma[1], forma[0]), 0)
    ImageDraw.Draw(img).polygon(puntos, fill=1)
    return np.array(img, bool)


def rellenar(img: np.ndarray, hueco: np.ndarray, con_alfa: bool = False) -> np.ndarray:
    """Pinta el hueco con los colores vecinos (inpainting) y lo deja opaco; con_alfa también
    rellena la transparencia desde los vecinos (vidrio del casco)."""
    salida = img.copy()
    if con_alfa:
        a = cv2.inpaint(img[..., 3].copy(), hueco.astype(np.uint8) * 255, 9, cv2.INPAINT_TELEA)
    bgr = cv2.cvtColor(img[..., :3], cv2.COLOR_RGB2BGR)
    pintado = cv2.inpaint(bgr, hueco.astype(np.uint8) * 255, 9, cv2.INPAINT_TELEA)
    salida[..., :3] = np.where(hueco[..., None], cv2.cvtColor(pintado, cv2.COLOR_BGR2RGB), img[..., :3])
    salida[..., 3] = np.where(hueco, a if con_alfa else 255, img[..., 3])
    return salida


def con_margen(cfg: dict) -> dict:
    """Corre todas las coordenadas MARGEN px: el lienzo de las piezas lleva un borde
    transparente para que al girar la mano o balancear el cuerpo nada se corte en el borde."""
    m = MARGEN
    mover = lambda p: (p[0] + m, p[1] + m)  # noqa: E731
    out = dict(cfg)
    out["cuello_y"] = cfg["cuello_y"] + m
    out["pivote_cabeza"] = mover(cfg["pivote_cabeza"])
    out["pivote_gesto"] = mover(cfg["pivote_gesto"])
    out["gesto"] = [mover(p) for p in cfg["gesto"]]
    for k in ("sin_circulo", "casco_detras"):
        if k in cfg:
            cx, cy, r = cfg[k]
            out[k] = (cx + m, cy + m, r)
    return out


def cortar(nombre: str, cfg: dict) -> dict:
    base = np.array(Image.open(CARPETA / f"{nombre}_sin_fondo.png").convert("RGBA"))
    base = np.pad(base, ((MARGEN, MARGEN), (MARGEN, MARGEN), (0, 0)))
    forma = base.shape[:2]
    yy, xx = np.indices(forma)
    visible = base[..., 3] > 0

    # el polígono se ensancha 4 px para llevarse también el contorno y el antialias de la
    # pieza (si no, queda un trazo suelto pegado al cuerpo o al casco)
    gesto = ndimage.binary_dilation(poligono(forma, cfg["gesto"]), iterations=4) & visible
    if cfg.get("solo_guante"):
        # mano delante del casco: el polígono atrapa vidrio, pelo y oreja. Se queda solo con
        # el guante (claro y opaco, la mancha más grande) + su contorno (5 px alrededor)
        rgb = base[..., :3].astype(int)
        guante = gesto & (base[..., 3] > 230) & (rgb.min(-1) > 175) & (rgb[..., 0] >= rgb[..., 2] - 4)  # rosado, no el borde celeste del casco
        partes, n = ndimage.label(guante)
        if n:  # todas las manchas de guante de buen tamaño (el pulgar queda separado por su línea)
            tam = ndimage.sum(guante, partes, range(1, n + 1))
            guante = np.isin(partes, [i + 1 for i, t in enumerate(tam) if t > 150])
        guante = ndimage.binary_fill_holes(guante)
        gesto = ndimage.binary_dilation(guante, iterations=5) & gesto & (base[..., 3] > 230) | guante
    # UNIÓN redonda en el pivote (mismo principio que herramientas/articulaciones.py): el
    # gesto termina en un disco centrado en su pivote y el cuerpo CONSERVA ese disco debajo.
    # Al girar, el arco vuelve sobre sí mismo: no se abre grieta en el codo.
    px, py = cfg["pivote_gesto"]
    union = ((xx - px) ** 2 + (yy - py) ** 2 <= cfg["radio_union"] ** 2) & visible
    gesto |= union
    if "sin_circulo" in cfg:
        cx, cy, r = cfg["sin_circulo"]
        gesto &= (xx - cx) ** 2 + (yy - cy) ** 2 > r ** 2
    cabeza = visible & (yy < cfg["cuello_y"]) & ~gesto
    cuerpo_m = visible & ~(gesto & ~union) & ~(yy < cfg["cuello_y"] - BANDA)

    piezas = {}
    for n, m in (("gesto", gesto), ("cabeza_casco", cabeza)):
        img = base.copy()
        img[..., 3] = np.where(m, base[..., 3], 0)
        piezas[n] = img

    cuerpo = base.copy()
    cuerpo[..., 3] = np.where(cuerpo_m, base[..., 3], 0)
    # hueco tras el gesto: solo donde el cuerpo "sigue" (cierre morfológico), no hacia afuera
    solido = cuerpo[..., 3] > 200
    cerrado = ndimage.binary_closing(solido | (cabeza & (base[..., 3] > 200)), iterations=14)
    hueco = cerrado & gesto & ~union & ~solido & (yy >= cfg["cuello_y"] - BANDA)
    piezas["cuerpo"] = rellenar(cuerpo, hueco)
    # bajo la cabeza, el cuerpo también rellena lo que el gesto tapaba (p. ej. la mano de
    # Nicole delante del casco): así al latir no asoma un agujero
    cab_hueco = ndimage.binary_closing(cabeza & (base[..., 3] > 200), iterations=10) & gesto
    con_alfa = False
    if "casco_detras" in cfg:
        cx, cy, r = cfg["casco_detras"]
        cab_hueco = gesto & ((xx - cx) ** 2 + (yy - cy) ** 2 <= r ** 2) & (yy < cfg["cuello_y"])
        con_alfa = True
    if cab_hueco.any():
        piezas["cabeza_casco"] = rellenar(piezas["cabeza_casco"], cab_hueco, con_alfa)
    return piezas


def girar(img: Image.Image, grados: float, centro, escala: float = 1.0) -> Image.Image:
    if abs(grados) < 1e-6 and abs(escala - 1) < 1e-6:
        return img
    cx, cy = centro
    # PIL: rotate es antihorario en pantalla con ángulo positivo; usamos el signo de Godot
    a = np.radians(grados)
    cos, sin = np.cos(a) / escala, np.sin(a) / escala
    # transformación inversa (destino -> origen) alrededor del centro
    m = (cos, sin, cx - cos * cx - sin * cy, -sin, cos, cy + sin * cx - cos * cy)
    return img.convert("RGBa").transform(img.size, Image.AFFINE, m, resample=Image.BICUBIC).convert("RGBA")


def componer(piezas: dict, cfg: dict, cuadro) -> Image.Image:
    g_cab, g_ges, esc, salto = cuadro
    pc = cfg["pivote_cabeza"]
    lienzo = Image.fromarray(piezas["cuerpo"])
    cab = girar(Image.fromarray(piezas["cabeza_casco"]), g_cab, pc)
    lienzo.alpha_composite(cab)
    ges = Image.fromarray(piezas["gesto"])
    ges = girar(ges, g_ges, cfg["pivote_gesto"], esc)
    lienzo.alpha_composite(ges)
    # el salto mueve la figura entera (en Godot: position.y del nodo raíz); se deja margen
    # arriba para que el casco no se corte en la vista previa
    movido = Image.new("RGBA", (lienzo.width, lienzo.height + 80), (0, 0, 0, 0))
    movido.paste(lienzo, (0, 80 + salto), lienzo)
    return movido


def main() -> None:
    for nombre, cfg in POSES.items():
        cfg = con_margen(cfg)  # pivotes.json queda en coordenadas del lienzo con margen
        destino = CARPETA / nombre
        destino.mkdir(exist_ok=True)
        piezas = cortar(nombre, cfg)
        for n, img in piezas.items():
            Image.fromarray(img).save(destino / f"{n}.png")
        pivotes = {"cabeza_casco": list(cfg["pivote_cabeza"]), "gesto": list(cfg["pivote_gesto"]),
                   "cuerpo": [0, 0]}
        (destino / "pivotes.json").write_text(json.dumps(pivotes, indent=2), encoding="utf-8")

        # vista previa: los cuadros de la animación sobre fondo violeta del juego
        cuadros = [componer(piezas, cfg, c) for c in cfg["cuadros"]]
        w, h = cuadros[0].size
        margen = 90
        hoja = Image.new("RGBA", (w * len(cuadros), h + margen), (60, 40, 110, 255))
        for i, c in enumerate(cuadros):
            hoja.alpha_composite(c, (i * w, margen))
        hoja.thumbnail((2400, 900))
        hoja.convert("RGB").save(destino / "vista_previa.png")
        print(f"{nombre}: piezas + pivotes -> {destino}")


if __name__ == "__main__":
    main()
