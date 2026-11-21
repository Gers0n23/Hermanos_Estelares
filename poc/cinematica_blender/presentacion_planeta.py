"""Presentación de un planeta (B3 del plan de cinemáticas): la nave llega al planeta desde el espacio,
se zambulle entre las nubes y baja a posarse en la superficie. El último cuadro es el encuadre del
mapa del planeta, con la nave estacionada.

Un solo guion para los 6 planetas: lo que cambia es el "kit" de cada uno en planeta_comun.py
(colores del planeta en órbita y decorado de la superficie).

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P presentacion_planeta.py -- --planeta arcoiris --fotos 1,60,100,130,180,264
  blender -b -P presentacion_planeta.py -- --planeta arcoiris --video
Opciones: --salida CARPETA, --escala 50, --muestras 32, --sin-pincel, --blend, --nombre BASE,
          --completa (la nave terminada en vez de la del hangar)
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403
from planeta_comun import *  # noqa: E402,F401,F403

PLANETA = str(arg("--planeta", "arcoiris"))
assert PLANETA in SUPERFICIES, f"--planeta: {', '.join(SUPERFICIES)}"
NOMBRE = arg("--nombre", f"presentacion_{PLANETA}")
random.seed(sum(ord(c) for c in PLANETA))

# ----------------------------------------------------------------------------- línea de tiempo (24 fps)
F_CORTE = 106        # 4,4 s: todo blanco entre nubes; aquí se cambia de decorado
F_ENCUADRE = 204     # la cámara llega al encuadre del mapa
F_TOQUE = 228        # la nave toca el suelo
F_FIN = 270          # 11,25 s
preparar_render(F_FIN)

# ----------------------------------------------------------------------------- decorados
K = SUPERFICIES[PLANETA]()
cual_cielo = cielo(K.cielo)
escalon(cual_cielo, F_CORTE, 0.0, 1.0)

E = ESPACIO
P_PLANETA, R_PLANETA = E + Vector((3.0, 44.0, 1.0)), 9.0
CAM_ESPACIO = E + Vector((0.0, -14.0, 0.0))
estrellas("estrellas_espacio", E, CAM_ESPACIO, n=170, grandes=16, radio=230, az=(-1.2, 1.2), el=(-0.6, 0.6))
planeta, bola = planeta_orbita(PLANETA, R_PLANETA, P_PLANETA)
clave(bola, "rotation_euler", 1, (0, 0, 0))
clave(bola, "rotation_euler", F_CORTE, (0, 0, 0.9))
lineal(bola)

# ----------------------------------------------------------------------------- la nave
N = construir_nave(completa=bool(arg("--completa")))
raiz, nave = N.raiz, N.nave
llamas = llamas_nave(N)
ESC_N = K.escala_nave
suelo = K.terreno.sobre(*K.posar)
P_POSADA = suelo + Vector((0, 0, 1.10 * ESC_N - 0.05))

# acto 1: cruza el cuadro y se aleja hacia el planeta
A0, A1 = E + Vector((-5.6, -9.5, -2.7)), E + Vector((2.4, 30.0, 0.9))
rumbo = math.atan2(A1.y - A0.y, A1.x - A0.x)
for f, t in ((1, 0.0), (26, 0.16), (F_CORTE - 1, 1.0)):
    clave(raiz, "location", f, tuple(A0.lerp(A1, t)))
clave(raiz, "rotation_euler", 1, (0, 0, rumbo))
clave(raiz, "rotation_euler", F_CORTE - 1, (0, 0, rumbo))
clave(raiz, "scale", 1, (1, 1, 1))
clave(raiz, "scale", F_CORTE - 1, (1, 1, 1))
for f, r in ((1, (0.35, -0.10, 0)), (40, (-0.25, -0.10, 0)), (80, (0.15, -0.08, 0)), (F_CORTE - 1, (0, -0.08, 0))):
    clave(nave, "rotation_euler", f, r)

# acto 2: baja planeando desde arriba a la derecha y se posa
giro_final = K.giro_nave
B = [(F_CORTE, Vector((19.0, 12.0, 30.0)), giro_final + 0.9, -0.05),
     (F_ENCUADRE - 34, Vector((13.0, 6.0, 19.0)), giro_final + 0.8, 0.22),
     (F_ENCUADRE - 4, P_POSADA + Vector((4.6, 3.0, 5.6)), giro_final + 0.45, 0.20),
     (F_TOQUE - 12, P_POSADA + Vector((0.5, 0.2, 1.7)), giro_final + 0.05, -0.06),
     (F_TOQUE, P_POSADA, giro_final, 0.0)]
for f, p, giro, cabeceo in B:
    clave(raiz, "location", f, tuple(p))
    clave(raiz, "rotation_euler", f, (0, 0, giro))
    clave(nave, "rotation_euler", f, (0, cabeceo, 0))
clave(raiz, "scale", F_CORTE, (ESC_N,) * 3)
for f, s in ((F_TOQUE - 1, (1, 1, 1)), (F_TOQUE + 3, (1.07, 1.07, 0.84)), (F_TOQUE + 8, (0.96, 0.96, 1.07)),
             (F_TOQUE + 14, (1.03, 1.03, 0.95)), (F_TOQUE + 20, (1, 1, 1))):
    clave(raiz, "scale", f, tuple(c * ESC_N for c in s))
for f, dz in ((F_TOQUE + 7, 0.20), (F_TOQUE + 14, 0.0), (F_FIN, 0.0)):
    clave(raiz, "location", f, tuple(P_POSADA + Vector((0, 0, dz * ESC_N))))

animar_llamas(llamas, [(1, 2.4, 1.0), (F_CORTE - 1, 2.0, 1.0), (F_CORTE, 1.5, 1.0), (F_ENCUADRE - 4, 1.2, 1.0),
                       (F_TOQUE - 10, 0.6, 0.8), (F_TOQUE - 2, 0.0, 0.3)], F_TOQUE - 6)
for o in llamas:
    visible(o, hasta=F_TOQUE - 1, hijos=False)
fuerza_tobera = N.m_fuego.node_tree.nodes["Emission"].inputs["Strength"]
for f, v in ((1, 2.4), (F_TOQUE - 4, 2.2), (F_TOQUE + 6, 0.8), (F_TOQUE + 18, 2.4), (F_TOQUE + 30, 1.1), (F_FIN, 1.6)):
    clave_nodo(fuerza_tobera, f, v)
# al posarse la cúpula se enciende tibia: "¡llegamos!"
for f, v in ((1, 0.25), (F_TOQUE + 4, 0.25), (F_TOQUE + 18, 1.0), (F_TOQUE + 32, 0.7), (F_FIN, 0.85)):
    clave_nodo(N.encendido, f, v)

# destello de estrellitas al tocar el suelo
m_chispa = mat_estrella()
molde = figura_plana("chispa_molde", ESTRELLA5, m_chispa)
molde.hide_render = True
for i in range(12):
    a = math.pi * (i + 0.5) / 12
    o = objeto("chispa", molde.data, None, suave=False, sombra=False)
    d, s = random.uniform(1.6, 3.0), random.uniform(0.16, 0.32)
    direccion = Vector((math.cos(a), -0.15, math.sin(a) * 0.8))
    base = suelo + Vector((0, -0.8, 0.3))
    for f, t, e in ((1, 0.0, 0.0), (F_TOQUE, 0.1, 0.0), (F_TOQUE + 6, 0.6, s), (F_TOQUE + 16, 0.92, s * 0.8),
                    (F_TOQUE + 26, 1.0, 0.0)):
        clave(o, "location", f, tuple(base + direccion * d * t))
        clave(o, "scale", f, (e, e, e))
    clave(o, "rotation_euler", F_TOQUE, (0, random.uniform(-1, 1), 0))
    clave(o, "rotation_euler", F_TOQUE + 26, (0, random.uniform(-3, 3), 0))

# el decorado está vivo: islotes que flotan, animalitos que saltan, barras que laten...
dar_vida(K, F_CORTE, F_FIN, F_TOQUE)

# el tren numérico llega y frena justo cuando la nave se posa (sigue el relieve del suelo)
for o, dx in getattr(K, "tren", []):
    for f in list(range(F_CORTE, F_TOQUE, 6)) + [F_TOQUE]:
        u = 1 - (1 - (f - F_CORTE) / (F_TOQUE - F_CORTE)) ** 2
        x = K.tren_x[0] + (K.tren_x[1] - K.tren_x[0]) * u + dx
        clave(o, "location", f, tuple(K.terreno.sobre(min(x, 36.0), K.tren_y)))

# nubes que la cámara atraviesa al entrar
m_paso = mat_nube()
for x, y, z, tam in ((-9, -20, 27, 5.0), (10, -16, 23, 5.5), (-3, -10, 17, 4.0), (15, -4, 30, 6.0), (-16, -6, 21, 5.0)):
    nube((x, y, z), tam, m_paso)

# ----------------------------------------------------------------------------- luz, cámara y fundido
sol()
o_cam, mira, cam = camara(35)
for f, p in ((1, CAM_ESPACIO), (56, E + Vector((0.3, -12.0, 0.1))), (F_CORTE - 1, E + Vector((2.6, 20.0, 0.9)))):
    clave(o_cam, "location", f, tuple(p))
for f, p in ((1, P_PLANETA + Vector((-3.0, 0, 0))), (F_CORTE - 1, P_PLANETA)):
    clave(mira, "location", f, tuple(p))
cam_fin, mira_fin = Vector(K.cam), Vector(K.mira)
for f, p in ((F_CORTE, cam_fin + Vector((0, -8, 26))), (F_ENCUADRE, cam_fin), (F_FIN, cam_fin)):
    clave(o_cam, "location", f, tuple(p))
for f, p in ((F_CORTE, mira_fin + Vector((0, 0, 30))), (F_ENCUADRE, mira_fin), (F_FIN, mira_fin)):
    clave(mira, "location", f, tuple(p))
for f, lente in ((1, 35), (F_CORTE - 1, 35), (F_CORTE, K.lente), (F_FIN, K.lente)):
    clave(cam, "lens", f, lente)
# la zambullida acelera hacia el planeta; la bajada frena al llegar al encuadre
for obj in (o_cam, mira):
    for fc in obj.animation_data.action.fcurves:
        for k in fc.keyframe_points:
            if int(k.co.x) in (F_CORTE - 1, F_CORTE):
                k.interpolation = "LINEAR" if int(k.co.x) == F_CORTE - 1 else "BEZIER"
                k.handle_left_type = k.handle_right_type = "VECTOR"

fundido(velo(o_cam), [(F_CORTE - 16, 0.0), (F_CORTE - 4, 1.0), (F_CORTE + 3, 1.0), (F_CORTE + 20, 0.0)])

compositor()
salidas(NOMBRE)
