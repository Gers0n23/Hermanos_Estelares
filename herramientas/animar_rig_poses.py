"""Prueba de animación del rig de pose (HE-143): video en loop de las tres celebraciones.

Usa las piezas que deja herramientas/armar_rig_poses.py (cuerpo, cabeza_casco, gesto) y las
mueve con curvas continuas (no cuadros sueltos), como lo haría un AnimationPlayer en Godot:

  Maxi    saltitos con estirón al despegar y aplastón al caer; el puño se agita en el codo
  Nicole  la mano del corazón late (escala) y la cabeza se ladea con ternura
  Sofía   el signo de la paz se mece en el codo y la cabeza se ladea; leve balanceo

Es solo una vista previa para el PO: la animación real se arma en Godot (HE-133).

Uso:    python herramientas/animar_rig_poses.py [--segundos 4] [--fps 30]
Salida: assets/generadas/poses_rig/animacion_rig_poses.mp4 (+ .gif liviano)
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from armar_rig_poses import CARPETA, POSES, con_margen, girar  # noqa: E402

ANCHO, ALTO = 1280, 720
FONDO = (60, 40, 110, 255)  # violeta del juego
ALTO_FIGURA = 560           # alto en pantalla de cada hermano (sin el salto)
SUELO = 680


def cargar(nombre: str) -> dict:
    d = CARPETA / nombre
    return {n: Image.open(d / f"{n}.png").convert("RGBA") for n in ("cuerpo", "cabeza_casco", "gesto")}


def suave(x: float) -> float:
    """onda 0..1..0 con entrada y salida suaves (como ease in-out)."""
    return 0.5 - 0.5 * math.cos(2 * math.pi * x)


# cada función recibe la fase t en [0, 1) y devuelve
# (giro cabeza °, giro gesto °, escala gesto, salto px, estira_y, balanceo °)
def mov_maxi(t: float):
    ciclo = (t * 2) % 1  # dos saltitos por loop
    # 0-0.15 se agacha, 0.15-0.75 en el aire, 0.75-0.9 aterriza (aplastón), 0.9-1 quieto
    if ciclo < 0.15:
        k = ciclo / 0.15
        salto, estira = 0, 1 - 0.06 * math.sin(math.pi * k)
    elif ciclo < 0.75:
        k = (ciclo - 0.15) / 0.6
        salto = -70 * math.sin(math.pi * k)
        estira = 1 + 0.05 * math.sin(math.pi * k) * (1 - k)  # se estira al despegar
    elif ciclo < 0.9:
        k = (ciclo - 0.75) / 0.15
        salto, estira = 0, 1 - 0.07 * math.sin(math.pi * k)
    else:
        salto, estira = 0, 1
    puno = -10 * math.sin(2 * math.pi * t * 4)  # el puño se agita rápido: «¡siii!»
    cabeza = 3 * math.sin(2 * math.pi * t * 2)
    return cabeza, puno, 1.0, salto, estira, 0


def mov_nicole(t: float):
    # latido doble (pum-pum) dos veces por loop
    ciclo = (t * 2) % 1
    latido = math.exp(-((ciclo - 0.10) / 0.06) ** 2) + 0.7 * math.exp(-((ciclo - 0.30) / 0.06) ** 2)
    escala = 1 + 0.08 * latido
    cabeza = -2 - 2.5 * suave(t)  # ladeo tierno, de ida y vuelta lento
    gesto = 3 * math.sin(2 * math.pi * t)
    return cabeza, gesto, escala, 0, 1, 1.2 * math.sin(2 * math.pi * t)


def mov_sofia(t: float):
    paz = 8 * math.sin(2 * math.pi * t * 2)
    cabeza = -2 - 2 * math.sin(2 * math.pi * t)
    return cabeza, paz, 1.0, 0, 1, 1.5 * math.sin(2 * math.pi * t)


MOVIMIENTOS = {
    "maxi_victoria_v1": mov_maxi,
    "sofia_victoria_v1": mov_sofia,
    "nicole_victoria_v2": mov_nicole,
}


def pose_en(piezas: dict, cfg: dict, mov) -> tuple[Image.Image, float, float, float]:
    g_cab, g_ges, esc, salto, estira, balanceo = mov
    lienzo = piezas["cuerpo"].copy()
    lienzo.alpha_composite(girar(piezas["cabeza_casco"], g_cab, cfg["pivote_cabeza"]))
    lienzo.alpha_composite(girar(piezas["gesto"], g_ges, cfg["pivote_gesto"], esc))
    return lienzo, salto, estira, balanceo


def recortar_pies(img: Image.Image) -> int:
    """fila más baja con figura (los pies), para apoyar a todos en el mismo suelo."""
    a = np.array(img)[..., 3]
    filas = np.where(a.max(1) > 20)[0]
    return int(filas[-1]) if len(filas) else img.height


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--segundos", type=float, default=4.0)
    ap.add_argument("--fps", type=int, default=30)
    args = ap.parse_args()

    datos = []
    for nombre in MOVIMIENTOS:
        piezas = cargar(nombre)
        pies = recortar_pies(piezas["cuerpo"])
        a = np.array(piezas["cabeza_casco"])[..., 3]
        tope = int(np.where(a.max(1) > 20)[0][0])  # borde de arriba del casco
        escala = ALTO_FIGURA / (pies - tope)
        datos.append((nombre, piezas, con_margen(POSES[nombre]), pies, escala))

    n = int(args.segundos * args.fps)
    salida = CARPETA / "animacion_rig_poses.mp4"
    video = cv2.VideoWriter(str(salida), cv2.VideoWriter_fourcc(*"mp4v"), args.fps, (ANCHO, ALTO))
    gif = []
    columnas = [ANCHO * (i + 0.5) / len(datos) for i in range(len(datos))]
    for f in range(n):
        t = f / n
        cuadro = Image.new("RGBA", (ANCHO, ALTO), FONDO)
        for (nombre, piezas, cfg, pies, escala), cx in zip(datos, columnas):
            img, salto, estira, balanceo = pose_en(piezas, cfg, MOVIMIENTOS[nombre](t))
            w = int(img.width * escala * (2 - estira) ** 0.5)  # conserva el volumen al aplastar
            h = int(img.height * escala * estira)
            img = img.resize((w, h), Image.LANCZOS)
            pies_px = pies * escala * estira
            if balanceo:
                # balanceo de todo el cuerpo apoyado en los pies
                img = girar(img, balanceo, (w / 2, pies_px))
            # sombra en el suelo que se achica con el salto
            sombra = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
            rx = 110 * (1 + salto / 250)
            from PIL import ImageDraw
            ImageDraw.Draw(sombra).ellipse(
                (cx - rx, SUELO - 14, cx + rx, SUELO + 14), fill=(25, 15, 50, 110))
            cuadro.alpha_composite(sombra)
            x = int(cx - w / 2)
            y = int(SUELO - pies_px + salto * escala * 1.6)
            cuadro.alpha_composite(img, (max(x, 0), y)) if x >= 0 else cuadro.paste(img, (x, y), img)
        rgb = np.array(cuadro.convert("RGB"))
        video.write(cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
        if f % 2 == 0:
            gif.append(cuadro.convert("RGB").resize((ANCHO // 2, ALTO // 2), Image.LANCZOS))
    video.release()
    gif[0].save(CARPETA / "animacion_rig_poses.gif", save_all=True, append_images=gif[1:],
                duration=int(2000 / args.fps), loop=0, optimize=True)
    print(f"{n} cuadros -> {salida} y animacion_rig_poses.gif")


if __name__ == "__main__":
    main()
