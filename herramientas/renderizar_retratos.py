"""Retratos oficiales de los hermanos y de Cometa a partir del arte RECORTADO (decisión del
PO 27-Sep-2026: los personajes oficiales son los cortados en Krita, no los SVG dibujados).

Hermanos: compone las piezas del rig cutout (assets/sprites/preview_<p>_rig/) con los
mismos pivotes y z_index que el rig de Godot:
  <p>_base.png        pose de reposo (idéntica a la base recortada)
  <p>_celebracion.png brazos arriba en V, girando cada pieza en sus articulaciones
Cometa: recortes de su hoja de referencia (herramientas/extraer_base.py) en
assets/generadas/cometa_recortes/ -> cometa_base.png (frente) y cometa_saludo.png.

Todos van a un lienzo fijo (hermanos 512x768 con los pies en y=720 y 649 px de alto en
reposo; Cometa 480x560), así las escenas que ya usan esas rutas no cambian. Las
diferencias de estatura por edad las da cada escena con su escala.

Uso:  python herramientas/renderizar_retratos.py
Ojo: herramientas/exportar_sprites.gd rasteriza assets/fuentes_svg/personajes/*.svg al
mismo destino y pisaría estos retratos; no lo corras sobre esa carpeta.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "assets/sprites/personajes"
ANCHO, ALTO, PIES, ALTURA = 512, 768, 720, 649
MARGEN = 300  # alrededor de cada pieza, para que lo girado no se corte en su lienzo

PADRES = {
    "cabeza_casco": "torso", "cinturon": "torso",
    "brazo_sup_izq": "torso", "brazo_sup_der": "torso",
    "antebrazo_mano_izq": "brazo_sup_izq", "antebrazo_mano_der": "brazo_sup_der",
    "pierna_sup_izq": None, "pierna_sup_der": None, "torso": None,
    "pierna_inf_pie_izq": "pierna_sup_izq", "pierna_inf_pie_der": "pierna_sup_der",
}

# z_index de cada rig (herramientas/armar_rig_<p>_preview.gd)
Z_MAXI = {"cabeza_casco": 10, "torso": 9, "brazo_sup_izq": 8, "brazo_sup_der": 7,
          "antebrazo_mano_izq": 6, "antebrazo_mano_der": 5, "pierna_inf_pie_izq": 4,
          "pierna_inf_pie_der": 3, "pierna_sup_izq": 2, "pierna_sup_der": 1}
Z_CON_CINTURON = {"cinturon": 11, "pierna_inf_pie_izq": 10, "pierna_sup_izq": 9,
                  "pierna_inf_pie_der": 8, "pierna_sup_der": 7, "torso": 6,
                  "brazo_sup_der": 5, "brazo_sup_izq": 4, "antebrazo_mano_der": 3,
                  "antebrazo_mano_izq": 2, "cabeza_casco": 1}
PIVOTES_SOFIA = {  # herramientas/armar_rig_sofia_preview.gd
    "cabeza_casco": (166, 262), "antebrazo_mano_izq": (68, 392), "antebrazo_mano_der": (254, 392),
    "brazo_sup_izq": (102, 298), "brazo_sup_der": (226, 298), "torso": (166, 470),
    "cinturon": (166, 470), "pierna_inf_pie_izq": (118, 550), "pierna_inf_pie_der": (202, 550),
    "pierna_sup_izq": (118, 462), "pierna_sup_der": (202, 462),
}

# Celebración, en radianes con el signo de Godot (positivo = horario en pantalla):
# el brazo izquierdo (lado izquierdo de la pantalla) sube girando en sentido horario.
CELEBRACION = {"brazo_sup_izq": 2.2, "antebrazo_mano_izq": 0.4,
               "brazo_sup_der": -2.2, "antebrazo_mano_der": -0.4,
               "cabeza_casco": 0.05}


def _pivotes(p: str) -> dict:
    if p == "sofia":
        return PIVOTES_SOFIA
    datos = json.loads((RAIZ / f"assets/generadas/{p}_piezas/pivotes.json").read_text(encoding="utf-8"))
    return {k: tuple(v) for k, v in datos.items()}


def _girar(img: Image.Image, angulo: float, centro) -> Image.Image:
    if abs(angulo) < 1e-6:
        return img
    # premultiplicado para que el antialias del giro no deje bordes oscuros
    return img.convert("RGBa").rotate(-math.degrees(angulo), resample=Image.BICUBIC,
                                      center=centro).convert("RGBA")


def componer(p: str, pose: dict) -> Image.Image:
    carpeta = RAIZ / f"assets/sprites/preview_{p}_rig"
    z = Z_MAXI if p == "maxi" else Z_CON_CINTURON
    piv = {k: (v[0] + MARGEN, v[1] + MARGEN) for k, v in _pivotes(p).items()}
    lienzo = None
    for nombre in sorted(z, key=z.get):
        pieza = Image.open(carpeta / f"{nombre}.png").convert("RGBA")
        img = Image.new("RGBA", (pieza.width + 2 * MARGEN, pieza.height + 2 * MARGEN), (0, 0, 0, 0))
        img.paste(pieza, (MARGEN, MARGEN))
        if lienzo is None:
            lienzo = Image.new("RGBA", img.size, (0, 0, 0, 0))
        # primero el giro propio, después el de cada ancestro (como en el árbol de nodos)
        actual = nombre
        while actual is not None:
            img = _girar(img, pose.get(actual, 0.0), piv[actual])
            actual = PADRES[actual]
        lienzo.alpha_composite(img)
    return lienzo


def colocar(fig: Image.Image, escala: float, caja_reposo) -> Image.Image:
    """Escala y ubica la figura con los pies (fondo de la caja en reposo) en y=PIES."""
    x0, _, x1, y1 = caja_reposo
    fig = fig.resize((round(fig.width * escala), round(fig.height * escala)), Image.LANCZOS)
    salida = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
    dx = round(ANCHO / 2 - (x0 + x1) / 2 * escala)
    dy = round(PIES - y1 * escala)
    salida.paste(fig, (dx, dy), fig)
    return salida


def hermano(p: str) -> None:
    reposo = componer(p, {})
    caja = reposo.getchannel("A").point(lambda a: 255 if a > 20 else 0).getbbox()
    escala = ALTURA / (caja[3] - caja[1])
    for sufijo, pose in (("base", {}), ("celebracion", CELEBRACION)):
        fig = reposo if not pose else componer(p, pose)
        img = colocar(fig, escala, caja)
        img.save(DESTINO / f"{p}_{sufijo}.png")
        cortes = img.getchannel("A").point(lambda a: 255 if a > 20 else 0).getbbox()
        print(f"  {p}_{sufijo}.png  escala {escala:.3f}  caja {cortes}")


def cometa() -> None:
    carpeta = RAIZ / "assets/generadas/cometa_recortes"
    frente = Image.open(carpeta / "cometa_frente.png").convert("RGBA")
    escala = 470 / frente.height
    for origen, destino in (("cometa_frente", "cometa_base"), ("cometa_saludo", "cometa_saludo")):
        fig = Image.open(carpeta / f"{origen}.png").convert("RGBA")
        fig = fig.resize((round(fig.width * escala), round(fig.height * escala)), Image.LANCZOS)
        salida = Image.new("RGBA", (480, 560), (0, 0, 0, 0))
        salida.alpha_composite(fig, ((480 - fig.width) // 2, 500 - fig.height))
        salida.save(DESTINO / f"{destino}.png")
        print(f"  {destino}.png  {fig.size}")


if __name__ == "__main__":
    for p in ("maxi", "nicole", "sofia"):
        hermano(p)
    cometa()
