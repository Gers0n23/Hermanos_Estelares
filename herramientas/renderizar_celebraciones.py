"""Celebraciones oficiales de los hermanos (HE-143) a partir de las poses de victoria aprobadas.

Cada pose sale de herramientas/armar_rig_poses.py: cuerpo.png, cabeza_casco.png y gesto.png, con
un margen transparente de 90 px y pivotes.json. Sin girar las piezas, cuerpo + cabeza_casco +
gesto forman la pose de victoria completa (brazos arriba, casco delante).

Salida (mismo formato que los *_base.png de herramientas/renderizar_retratos.py):
  assets/sprites/personajes/<p>_celebracion.png  lienzo 512x768, pies en y=720,
  649 px de alto desde la punta del casco hasta los pies (la estatura por edad la pone cada escena).

Uso:  python herramientas/renderizar_celebraciones.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
POSES = RAIZ / "assets/generadas/poses_rig"
DESTINO = RAIZ / "assets/sprites/personajes"
ANCHO, ALTO, PIES, ALTURA = 512, 768, 720, 649
POSES_APROBADAS = {"maxi": "maxi_victoria_v1", "nicole": "nicole_victoria_v2", "sofia": "sofia_victoria_v1"}


def _cajas(img: Image.Image) -> tuple:
    return img.getchannel("A").point(lambda a: 255 if a > 20 else 0).getbbox()


def componer(carpeta: Path) -> tuple[Image.Image, tuple]:
    """Pose completa sin girar y caja de referencia (cuerpo: torso y pies)."""
    cuerpo = Image.open(carpeta / "cuerpo.png").convert("RGBA")
    lienzo = cuerpo.copy()
    for pieza in ("cabeza_casco", "gesto"):  # orden de z: cabeza encima del cuerpo, gesto al final
        lienzo.alpha_composite(Image.open(carpeta / f"{pieza}.png").convert("RGBA"))
    return lienzo, _cajas(cuerpo)


def celebracion(p: str) -> None:
    carpeta = POSES / POSES_APROBADAS[p]
    figura, caja_cuerpo = componer(carpeta)
    # estatura de reposo = punta del casco (cabeza_casco) hasta los pies (cuerpo), como en renderizar_retratos.py
    cabeza = _cajas(Image.open(carpeta / "cabeza_casco.png").convert("RGBA"))
    cuerpo = _cajas(Image.open(carpeta / "cuerpo.png").convert("RGBA"))
    escala = ALTURA / (cuerpo[3] - cabeza[1])
    figura = figura.resize((round(figura.width * escala), round(figura.height * escala)), Image.LANCZOS)
    x0, _, x1, y1 = caja_cuerpo
    dx = round(ANCHO / 2 - (x0 + x1) / 2 * escala)
    dy = round(PIES - y1 * escala)
    salida = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
    salida.paste(figura, (dx, dy), figura)
    destino = DESTINO / f"{p}_celebracion.png"
    salida.save(destino)
    print(f"  {destino.name}  escala {escala:.3f}  caja {_cajas(salida)}")


if __name__ == "__main__":
    for p in POSES_APROBADAS:
        celebracion(p)
