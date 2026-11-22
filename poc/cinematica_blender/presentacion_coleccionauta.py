"""Presentación del Coleccionauta en la intro (plano 01b, antes del living): ~3,5 s.

Su ovni (el MISMO del sprite assets/sprites/viaje/coleccionauta_nave.png, rehecho en 3D: disco morado,
aro dorado y cúpula verde) baja en picada girando sobre la casa al atardecer, frena con un tambaleo
cómico, la cúpula se abre como tapa y el Coleccionauta salta afuera como muñeco de caja sorpresa,
con estrellitas. Él es el sprite 2D (assets/sprites/personajes/coleccionauta_provisional.png) como
títere de cartón dentro del 3D: no se modela, se ve igual que en el resto del juego.
Para niños: chistoso y torpe, jamás amenazante (GDD §1 "el secuestro jamás da miedo").

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P presentacion_coleccionauta.py -- --fotos 1,20,34,46,60,84
  blender -b -P presentacion_coleccionauta.py -- --video
Opciones: --salida CARPETA, --escala 50, --muestras 32, --sin-pincel, --blend, --nombre BASE
"""
import math
import os
import random
import sys

from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403 — utilidades y look 2D pintado (escena vacía al importar)
from casa_ovni_comun import *  # noqa: E402,F401,F403 — casa al atardecer, ovni y títeres 2D

NOMBRE = arg("--nombre", "presentacion_coleccionauta_v1")
random.seed(11)

# ----------------------------------------------------------------------------- línea de tiempo (24 fps)
F_FRENA = 28        # el ovni llega a su lugar y frena de golpe
F_TAPA = 38         # la cúpula se abre
F_SALTA = 44        # el Coleccionauta salta afuera
F_POSE = 58         # quedó parado, saludando
F_FIN = 86          # ≈ 3,6 s
preparar_render(F_FIN)

escenario()
O = construir_ovni()
raiz, giro, bisagra = O.raiz, O.giro, O.bisagra
o_cam, cam, mira = camara()


# --- trayectoria: entra desde arriba a la derecha, lejos, haciendo una curva; frena con rebote
camino = [(1, (16.0, 34.0, 15.0)), (10, (10.0, 16.0, 10.5)), (20, (3.6, 3.0, 7.2)),
          (F_FRENA, tuple(OVNI + Vector((-0.35, 0, -0.25)))), (F_FRENA + 5, tuple(OVNI + Vector((0.12, 0, 0.12)))),
          (F_FRENA + 10, tuple(OVNI))]
for f, p in camino:
    clave(raiz, "location", f, p)
# el ovni "da un saltito" cuando el Coleccionauta sale
for f, dz in ((F_SALTA - 2, 0.0), (F_SALTA + 2, -0.22), (F_SALTA + 8, 0.06), (F_SALTA + 13, 0.0)):
    clave(raiz, "location", f, tuple(OVNI + Vector((0, 0, dz))))
# se balancea en la picada y se tambalea al frenar (como trompo que se detiene)
for f, (rx, ry) in ((1, (0.0, -0.35)), (14, (0.15, -0.45)), (22, (0.1, -0.3)), (F_FRENA, (-0.05, 0.38)),
                    (F_FRENA + 4, (0.08, -0.24)), (F_FRENA + 8, (-0.04, 0.13)), (F_FRENA + 12, (0.02, -0.05)),
                    (F_FRENA + 16, (0.0, 0.0))):
    clave(raiz, "rotation_euler", f, (rx, ry, 0.0))
for f, rz in ((1, 0.0), (F_FRENA, 5 * math.pi), (F_FRENA + 14, 5.6 * math.pi), (F_FIN, 6.3 * math.pi)):
    clave(giro, "rotation_euler", f, (0, 0, rz))
# ruido leve de flotación después de frenar
ruido(raiz, "location", 2, 0.05, 9, F_FIN)

# la tapa se abre con un saltito y queda atrás, abierta
for f, a in ((1, 0.0), (F_TAPA - 3, 0.0), (F_TAPA - 1, 0.12), (F_TAPA, 0.0), (F_TAPA + 5, 2.05), (F_TAPA + 9, 1.7),
             (F_TAPA + 13, 1.85)):
    clave(bisagra, "rotation_euler", f, (0, a, 0))

# ----------------------------------------------------------------------------- el Coleccionauta: títere de cartón
# pivote en los pies, dentro de la cúpula (no gira con el disco)
pies = titere("coleccionauta", "assets/sprites/personajes/coleccionauta_provisional.png", 2.35, raiz, (0, -0.05, 0.05))
# muñeco de caja sorpresa: aparece chiquito, se estira hacia arriba, rebota y se asienta
for f, (sx, sz) in ((1, (0.0, 0.0)), (F_SALTA - 1, (0.0, 0.0)), (F_SALTA, (0.25, 0.25)), (F_SALTA + 4, (0.8, 1.32)),
                    (F_SALTA + 8, (1.18, 0.82)), (F_SALTA + 12, (0.94, 1.08)), (F_SALTA + 16, (1.03, 0.97)),
                    (F_POSE, (1.0, 1.0))):
    clave(pies, "scale", f, (sx, 1.0, sz))
for f, z in ((F_SALTA, -0.25), (F_SALTA + 4, 0.5), (F_SALTA + 8, -0.05), (F_POSE, -0.05)):
    clave(pies, "location", f, (0, 0, z))
# después saluda meciéndose de lado a lado, como títere contento
for i, f in enumerate(range(F_POSE, F_FIN + 1, 7)):
    clave(pies, "rotation_euler", f, (0, (0.09 if i % 2 else -0.09) if i else 0.0, 0))
    if i:
        clave(pies, "scale", f, (1.0, 1.0, 0.97 if i % 2 else 1.03))

# estrellitas al salir
chispas(raiz, (0, -0.3, 1.1), F_SALTA + 2)

# ----------------------------------------------------------------------------- cámara

# plano general de la casa con el ovni bajando → se acerca al ovni → primer plano del Coleccionauta
for f, p in ((1, tuple(CAM_INICIO)), (F_FRENA, (-0.2, -14.0, 4.6)), (F_TAPA, (0.3, -11.5, 5.4)),
             (F_POSE, (1.1, -7.2, 6.9)), (F_FIN, (1.2, -6.6, 7.0))):
    clave(o_cam, "location", f, p)
for f, p in ((1, (2.0, 0, 7.6)), (14, (3.5, 0, 7.4)), (F_FRENA, (0.8, 0, 6.0)), (F_TAPA, (1.2, 0, 6.6)),
             (F_POSE, (1.3, 0, 7.25)), (F_FIN, (1.3, 0, 7.3))):
    clave(mira, "location", f, p)

compositor()
salidas(NOMBRE)
