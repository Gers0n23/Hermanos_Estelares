"""Cometa llega un segundito tarde (intro, entre la reacción de los niños y el choque): ~4,5 s.

El ovni del Coleccionauta se va de la casa con papá a bordo (contento, saludando: es un paseo, no da
miedo) y se pierde en el cielo con un destello. Justo entonces entra volando la nave de Cometa
(su navecita, la del ancla assets/anclas/cometa_navecita.png: casa_ovni_comun.construir_navecita), lo persigue,
frena tarde, se tambalea, petardea y cae dando vueltas hacia la ventana del living. Corta a la imagen
del choque (04_cometa_choque.png). Cometa, papá y el Coleccionauta son los sprites 2D del juego como
títeres de cartón (casa_ovni_comun.titere).

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P cometa_llega_tarde.py -- --fotos 1,20,40,56,70,90,108
  blender -b -P cometa_llega_tarde.py -- --video
Opciones: --salida CARPETA, --escala 50, --muestras 32, --sin-pincel, --blend, --nombre BASE
"""
import math
import os
import random
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403
from casa_ovni_comun import *  # noqa: E402,F401,F403
from casa_ovni_comun import _estrella  # noqa: E402

NOMBRE = arg("--nombre", "cometa_llega_tarde_v1")
random.seed(5)

# ----------------------------------------------------------------------------- línea de tiempo (24 fps)
F_SALTITO = 8       # el ovni se agacha para arrancar
F_ARRANCA = 15      # sale disparado hacia el cielo
F_PIERDE = 40       # se pierde en el cielo con un destello
F_ENTRA = 30        # la nave de Cometa entra por la izquierda
F_FRENA = 56        # frena (tarde) donde se perdió el ovni
F_CAE = 68          # petardea y cae dando vueltas
F_FIN = 108         # ≈ 4,5 s: a punto de entrar por la ventana
preparar_render(F_FIN)

escenario()
o_cam, cam, mira = camara()

# ----------------------------------------------------------------------------- el ovni se va con papá
O = construir_ovni()
raiz, giro = O.raiz, O.giro
clave(O.bisagra, "rotation_euler", 1, (0, 1.85, 0))   # la tapa quedó abierta desde que se presentó
LEJOS = Vector((34.0, 95.0, 34.0))
for f, p in ((1, OVNI), (F_SALTITO, OVNI + Vector((0, 0, 0.15))), (F_ARRANCA - 2, OVNI + Vector((0, 0, -0.3))),
             (F_ARRANCA + 6, OVNI + Vector((2.2, 4.0, 2.6))), (F_PIERDE, LEJOS)):
    clave(raiz, "location", f, tuple(p))
curva(raiz, "location", 0).keyframe_points[-1].interpolation = "LINEAR"
for k in curva(raiz, "location", 1).keyframe_points[-2:]:
    k.easing = "EASE_IN"
for f, s in ((1, 1.0), (F_PIERDE - 1, 1.0), (F_PIERDE, 0.0)):
    clave(raiz, "scale", f, (s, s, s))
for f, r in ((1, (0, 0, 0)), (F_ARRANCA - 2, (0.12, 0, 0)), (F_ARRANCA + 4, (-0.25, 0.3, 0)), (F_PIERDE, (-0.3, 0.3, 0))):
    clave(raiz, "rotation_euler", f, r)
for f, rz in ((1, 0.0), (F_ARRANCA, 1.2 * math.pi), (F_PIERDE, 9 * math.pi)):
    clave(giro, "rotation_euler", f, (0, 0, rz))

papa = titere("papa", "assets/sprites/personajes/papa_provisional.png", 2.45, raiz, (-0.62, 0.05, 0.05))
cole = titere("coleccionauta", "assets/sprites/personajes/coleccionauta_provisional.png", 2.35, raiz,
              (0.38, -0.1, 0.05))
# los dos se mecen contentos; al arrancar se aplastan del tirón
for i, f in enumerate(range(1, F_ARRANCA, 5)):
    clave(papa, "rotation_euler", f, (0, 0.07 if i % 2 else -0.07, 0))
    clave(cole, "rotation_euler", f, (0, -0.08 if i % 2 else 0.08, 0))
for p in (papa, cole):
    for f, (sx, sz) in ((F_ARRANCA - 3, (1.0, 1.0)), (F_ARRANCA, (1.12, 0.86)), (F_ARRANCA + 5, (0.92, 1.1)),
                        (F_ARRANCA + 10, (1.0, 1.0))):
        clave(p, "scale", f, (sx, 1, sz))

# destello donde se pierde: una estrella grande que guiña
m_guino = brillante("guino", "#FFF2B0", 3.0)
guino = objeto("guino", malla_bm("guino", lambda bm: _estrella(bm, Matrix.Rotation(math.pi / 2, 4, "X"), 1.0)),
               m_guino, suave=False, sombra=False)
guino.location = LEJOS + Vector((0, -2, 0))
for f, s, r in ((1, 0, 0), (F_PIERDE - 2, 0, 0), (F_PIERDE + 2, 3.2, 0.4), (F_PIERDE + 8, 0, 1.2)):
    clave(guino, "scale", f, (s, s, s))
    clave(guino, "rotation_euler", f, (0, r, 0))

# ----------------------------------------------------------------------------- la nave de Cometa
N = construir_navecita(o_cam)
N.raiz.scale = (1.6, 1.6, 1.6)
PUNTOS = [Vector(p) for p in ((-20, -9, 7.5), (-7, -5, 8.5), (1.5, -0.5, 9.6), (6, 5, 10.8), (8.5, 4, 10.0),
                              (6.5, -0.5, 8.4), (2.5, -1.5, 6.2), (-1.2, 0.8, 4.0), (-3.3, 2.6, 2.4))]
ruta_d = bpy.data.curves.new("ruta_cometa", "CURVE")
ruta_d.dimensions = "3D"
sp = ruta_d.splines.new("BEZIER")
sp.bezier_points.add(len(PUNTOS) - 1)
for bp, p in zip(sp.bezier_points, PUNTOS):
    bp.co = p
    bp.handle_left_type = bp.handle_right_type = "AUTO"
ruta = bpy.data.objects.new("ruta_cometa", ruta_d)
COL.objects.link(ruta)
seguir = N.raiz.constraints.new("FOLLOW_PATH")
seguir.target, seguir.use_curve_follow, seguir.use_fixed_location = ruta, True, True
seguir.forward_axis, seguir.up_axis = "FORWARD_X", "UP_Z"
largos = [0.0]
for a, b in zip(PUNTOS, PUNTOS[1:]):
    largos.append(largos[-1] + (b - a).length)
frac = [x / largos[-1] for x in largos]
for f, v in ((1, 0.0), (F_ENTRA, 0.0), (F_FRENA, frac[3] + 0.01), (F_CAE - 2, frac[4]), (F_FIN, 0.995)):
    seguir.offset_factor = v
    seguir.keyframe_insert("offset_factor", frame=f)
fc = N.raiz.animation_data.action.fcurves.find('constraints["Follow Path"].offset_factor')
for k in fc.keyframe_points:
    k.interpolation = "BEZIER"
fc.keyframe_points[1].easing = "EASE_OUT"
fc.keyframe_points[-1].interpolation = "QUAD"
fc.keyframe_points[-2].interpolation = "QUAD"
fc.keyframe_points[-2].easing = "EASE_IN"

# tambaleo al frenar ("¿dónde se fue?") y vueltas de trompo al caer
for f, rx in ((F_ENTRA, 0.0), (F_FRENA - 4, -0.25), (F_FRENA, 0.45), (F_FRENA + 4, -0.35), (F_FRENA + 8, 0.25),
              (F_CAE, -0.1), (F_FIN, 4.5 * math.pi)):
    clave(N.nave, "rotation_euler", f, (rx, 0, 0))
curva(N.nave, "rotation_euler", 0).keyframe_points[-2].interpolation = "QUAD"
# la cúpula tibia (Cometa adentro) y las toberas que petardean
for llama in N.llamas:    # llamitas encendidas; petardean y se apagan al caer
    for f, v in ((1, 1.0), (F_FRENA, 1.0), (F_CAE - 6, 0.2), (F_CAE - 4, 1.3), (F_CAE - 2, 0.1), (F_CAE, 1.2),
                 (F_CAE + 2, 0.15), (F_FIN, 0.1)):
        clave(llama, "scale", f, (1, 1, v))
    ruido(llama, "scale", 2, 0.25, 1.5, F_CAE - 8)
cometa = N.cometa
for i, f in enumerate(range(F_ENTRA, F_FIN + 1, 6)):
    clave(cometa, "rotation_euler", f, (0, 0.12 if i % 2 else -0.12, 0))


# --- estelas: se calculan con la nave ya animada (posición real en cada cuadro)
def mundo_de(f, local):
    ESC.frame_set(f)
    bpy.context.view_layer.update()
    return N.raiz.matrix_world @ Vector(local)


m_estela = mat("estela", con_alfa, "#FFE27A", 2.2)
for f in range(F_ENTRA + 2, F_CAE, 2):          # rastro de estrellitas mientras persigue
    o = objeto("estela", malla_bm("estela", lambda bm: _estrella(bm, Matrix.Rotation(math.pi / 2, 4, "X"),
                                                                    random.uniform(0.12, 0.22))),
               m_estela, suave=False, sombra=False)
    o.location = mundo_de(f, (-1.0, random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3)))
    for g, s, al in ((1, 0, 0), (f - 1, 0, 0), (f, 1, 1), (f + 12, 0.3, 0)):
        clave(o, "scale", g, (s, s, s))
        clave(o, "color", g, (1, 1, 1, al))
m_humo = mat("humo", con_alfa, "#B9A6CF", 1.0)
for f in (F_CAE - 4, F_CAE, F_CAE + 6, F_CAE + 12, F_CAE + 18, F_CAE + 24, F_CAE + 30):   # petardeo
    p = mundo_de(f, (-1.0, 0, 0))
    o = esfera("humo", 0.35, p, m_humo, u=12, v=8, sombra=False)
    for g, s, al in ((1, 0, 0), (f - 1, 0, 0), (f, 0.6, 0.9), (f + 14, 1.8, 0)):
        clave(o, "scale", g, (s, s, s))
        clave(o, "color", g, (1, 1, 1, al))
ESC.frame_set(1)

# ----------------------------------------------------------------------------- cámara
# primero el ovni con papá; luego abre al cielo para ver cómo se pierde; desde que entra Cometa la sigue
# (la mira va sobre la nave) con un acercamiento cuando frena, y termina pegada a la ventana.
for f, p in ((1, (1.1, -8.4, 6.9)), (F_ARRANCA, (1.0, -8.8, 6.8)), (F_PIERDE - 6, (-0.5, -15.0, 4.6)),
             (F_FRENA, (-1.0, -14.0, 5.0)), (F_CAE + 14, (-1.5, -13.0, 4.4)), (F_FIN, (-1.8, -9.8, 3.4))):
    clave(o_cam, "location", f, p)
for f, p in ((1, (1.2, 0, 7.3)), (F_ARRANCA, (1.4, 0, 7.4)), (F_PIERDE - 6, (5.0, 12.0, 9.0)),
             (F_PIERDE + 2, (4.0, 10.0, 9.0))):
    clave(mira, "location", f, p)
for f in list(range(F_PIERDE + 6, F_FIN - 3, 4)) + [F_FIN]:
    p = mundo_de(f, (0, 0, 0))
    if f == F_FIN:
        p = p.lerp(Vector((-3.3, 3.4, 2.6)), 0.4)
    clave(mira, "location", f, tuple(p))
ESC.frame_set(1)
for f, l in ((1, 32), (F_PIERDE + 6, 32), (F_FRENA - 2, 62), (F_CAE + 2, 58), (F_CAE + 18, 36), (F_FIN, 30)):
    clave(cam, "lens", f, l)
ruido(o_cam, "location", 2, 0.06, 2.5, F_FIN)

compositor()
salidas(NOMBRE)
