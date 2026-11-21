"""Despegue y viaje entre planetas (B4 del plan de cinemáticas): la nave, posada en el planeta
(mismo encuadre con que termina su presentación), enciende motores, despega, sale al espacio y
viaja hasta el planeta siguiente. El último cuadro es el primero de la presentación de ese planeta,
para que los dos videos empalmen.

En Arcoíris el despegue es por el puente de 3 bandas (rojo, amarillo y azul;
docs/cinematicas/cierre_arcoiris.md §12.2): la nave lo recorre y la punta la lanza al cielo.

Con --planeta tierra (viaje Tierra -> Arcoíris) no hay superficie en Blender: el despegue es el del patio
(despegue_tierra.py) y este script renderiza solo el acto 2 (de F_CORTE a F_FIN, saliendo del blanco).
herramientas/armar_viaje_tierra.py pega los dos actos en viaje_tierra_a_arcoiris.mp4.

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P despegue_viaje.py -- --planeta arcoiris --fotos 1,60,100,140,200,260
  blender -b -P despegue_viaje.py -- --planeta arcoiris --video
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
TIERRA = PLANETA == "tierra"         # solo el acto 2: el despegue del patio es otro video
assert TIERRA or PLANETA in SUPERFICIES, f"--planeta: tierra, {', '.join(SUPERFICIES)}"
DESTINO = "arcoiris" if TIERRA else ORDEN[ORDEN.index(PLANETA) + 1]
NOMBRE = arg("--nombre", f"viaje_{PLANETA}_a_{DESTINO}")
random.seed(sum(ord(c) for c in PLANETA) + 7)
PUENTE = PLANETA == "arcoiris"

# ----------------------------------------------------------------------------- línea de tiempo (24 fps)
F_MOTOR = 20                         # los motores ya rugen: empieza a subir
F_CORTE = 160 if TIERRA else 150 if PUENTE else 112     # todo blanco: se cambia al espacio
F_FIN = F_CORTE + 132                # ≈ 10,2 s (11,75 s con el puente, 12,2 s desde el patio)
preparar_render(F_FIN)
if TIERRA:
    ESC.frame_start = F_CORTE        # el acto 1 es despegue_tierra_v1.mp4

# ----------------------------------------------------------------------------- decorados
if TIERRA:
    # sin superficie: el acto 1 (que no se renderiza) se anima sobre un suelo vacío en el origen
    from types import SimpleNamespace
    K = SimpleNamespace(escala_nave=1.0, terreno=SimpleNamespace(sobre=lambda *a: Vector((0.0, 0.0, 0.0))),
                        posar=(0.0, 0.0), giro_nave=0.0, cam=(0.0, -14.0, 3.0), mira=(0.0, 0.0, 2.0), lente=32)
    cual_cielo = cielo(((0.0, "#FFC08A"), (1.0, "#4A3F82")))
    escalon(cual_cielo, F_CORTE, 1.0, 0.0)
else:
    K = SUPERFICIES[PLANETA]()
    cual_cielo = cielo(K.cielo)
    escalon(cual_cielo, F_CORTE, 1.0, 0.0)
    dar_vida(K, 1, F_CORTE, 0)       # todos despiden a la nave saltando

E = ESPACIO
C0 = E + Vector((0.0, -14.0, 0.0))                    # cámara al salir del planeta
P_ORIGEN, R_PLANETA = E + Vector((-10.0, 18.0, -2.5)), 9.0
P_DESTINO = E + Vector((70.0, 210.0, 14.0))
C1 = P_DESTINO - Vector((3.0, 58.0, 1.0))             # desde aquí se ve igual que al empezar la presentación
estrellas("estrellas_viaje", (C0 + C1) / 2 + Vector((0, 200, 0)), (C0 + C1) / 2, n=260, grandes=22, radio=1500,
          az=(-1.3, 1.3), el=(-0.6, 0.6), tam=6.0)
origen, bola_o = planeta_orbita(PLANETA, R_PLANETA, P_ORIGEN)
destino, bola_d = planeta_orbita(DESTINO, R_PLANETA, P_DESTINO)
for bola in (bola_o, bola_d):
    clave(bola, "rotation_euler", F_CORTE, (0, 0, 0))
    clave(bola, "rotation_euler", F_FIN, (0, 0, 0.9))
    lineal(bola)

# ----------------------------------------------------------------------------- la nave
N = construir_nave(completa=bool(arg("--completa")))
raiz, nave = N.raiz, N.nave
llamas = llamas_nave(N)
ESC_N = K.escala_nave
suelo = K.terreno.sobre(*K.posar)
P_POSADA = suelo + Vector((0, 0, 1.10 * ESC_N - 0.05))
giro0 = K.giro_nave


def pose(f, p, giro, cabeceo=0.0, alabeo=0.0):
    clave(raiz, "location", f, tuple(p))
    clave(raiz, "rotation_euler", f, (0, 0, giro))
    clave(nave, "rotation_euler", f, (alabeo, cabeceo, 0))


# acto 1: tiembla de emoción, sube tambaleándose y sale disparada
pose(1, P_POSADA, giro0)
for f in range(4, F_MOTOR, 3):       # temblor de motores
    clave(raiz, "location", f, tuple(P_POSADA + Vector((random.uniform(-0.04, 0.04), 0, random.uniform(0, 0.06)))))
pose(F_MOTOR, P_POSADA, giro0)
pose(F_MOTOR + 14, P_POSADA + Vector((0.3, 0, 1.4)), giro0 + 0.10, -0.10, 0.18)
pose(F_MOTOR + 28, P_POSADA + Vector((-0.3, 0.2, 2.6)), giro0 - 0.10, -0.16, -0.18)
if PUENTE:
    # el puente de 3 bandas: un arco grande al fondo del valle; la nave lo recorre de izquierda a derecha
    centro = K.terreno.sobre(0.0, 5.0, -1.5)
    R_ARCO = 10.0
    puente = arco_bandas("puente_3_bandas", R_ARCO + 0.9, 2.4, ["#FF5A5A", "#FFD23D", "#4FA8FF"], padre=None,
                         seg=64, grosor=0.5, fuerza=1.05)
    puente.location = centro
    visible(puente, desde=F_MOTOR + 8, hijos=False)
    for f, e in ((F_MOTOR + 8, 0.0), (F_MOTOR + 30, 1.0)):      # el arco crece desde el suelo
        clave(puente, "scale", f, (1, 1, e))
    f_pie, f_punta = F_MOTOR + 46, F_CORTE - 22
    pasos = 9
    for i in range(pasos + 1):
        u = i / pasos
        u = u * u * (3 - 2 * u)                                 # arranca y frena suave
        ang = math.radians(172 - 164 * u)
        p = centro + Vector((R_ARCO * math.cos(ang), -0.6, R_ARCO * math.sin(ang) + 0.75 * ESC_N))
        tangente = max(-0.6, min(0.6, ang - math.pi / 2))       # se inclina con el arco, con tope
        pose(f_pie + round((f_punta - f_pie) * i / pasos), p, 0.0, -tangente)
    pose(f_punta + 8, centro + Vector((R_ARCO + 3.5, -0.6, 4.5)), 0.0, -0.75)       # la punta es una rampa
    pose(F_CORTE - 1, centro + Vector((R_ARCO + 9.0, 4.0, 34.0)), 0.0, -1.1)
else:
    pose(F_MOTOR + 44, P_POSADA + Vector((0.2, 0.6, 4.6)), giro0 + 0.25, -0.30, 0.10)
    pose(F_CORTE - 22, P_POSADA + Vector((3.0, 4.0, 11.0)), giro0 + 0.7, -0.75)
    pose(F_CORTE - 1, P_POSADA + Vector((12.0, 12.0, 40.0)), giro0 + 0.9, -1.0)
clave(raiz, "scale", 1, (ESC_N,) * 3)
for f, e in ((F_MOTOR - 6, (1, 1, 1)), (F_MOTOR - 2, (1.06, 1.06, 0.88)), (F_MOTOR + 4, (0.95, 0.95, 1.10)),
             (F_MOTOR + 12, (1, 1, 1)), (F_CORTE - 1, (1, 1, 1))):     # se agacha y salta
    clave(raiz, "scale", f, tuple(c * ESC_N for c in e))

# acto 2: el viaje. La nave va delante de la cámara y termina donde empieza la presentación siguiente
F_V = F_CORTE
DESF = [(0.00, Vector((-5.0, 24.0, -1.2))), (0.30, Vector((1.8, 13.0, 0.6))), (0.65, Vector((-1.0, 9.0, -0.6))),
        (1.00, Vector((-5.6, 4.5, -2.7)))]                      # posición respecto de la cámara


def suave(u):
    return u * u * (3 - 2 * u)


def camara_en(u):
    return C0.lerp(C1, suave(u))


RUMBO_FIN = math.atan2(39.5, 8.0)                               # el rumbo con que arranca la presentación
anterior = None
for i in range(12):
    u = i / 11
    f = F_V + round((F_FIN - F_V) * u)
    k = max(j for j in range(len(DESF)) if DESF[j][0] <= u)
    if k == len(DESF) - 1:
        desf = DESF[-1][1]
    else:
        (u0, d0), (u1, d1) = DESF[k], DESF[k + 1]
        desf = d0.lerp(d1, suave((u - u0) / (u1 - u0)))
    p = camara_en(u) + desf
    giro = RUMBO_FIN if anterior is None or i == 11 else math.atan2(p.y - anterior.y, p.x - anterior.x)
    alabeo = 0.35 * math.sin(u * math.pi * 3)
    pose(f, p, giro, -0.08, alabeo if i < 11 else 0.35)
    anterior = p
clave(raiz, "scale", F_CORTE, (1, 1, 1))

animar_llamas(llamas, [(1, 0.0, 0.3), (F_MOTOR - 8, 0.5, 0.8), (F_MOTOR, 1.6, 1.0), (F_CORTE - 22, 2.2, 1.0),
                       (F_CORTE, 2.8, 1.0), (F_FIN, 2.4, 1.0)], F_FIN)
fuerza_tobera = N.m_fuego.node_tree.nodes["Emission"].inputs["Strength"]
for f, v in ((1, 1.0), (F_MOTOR - 8, 1.6), (F_MOTOR, 2.6), (F_FIN, 2.4)):
    clave_nodo(fuerza_tobera, f, v)
for f, v in ((1, 0.85), (F_MOTOR, 1.0), (F_FIN, 0.9)):
    clave_nodo(N.encendido, f, v)

# chispitas al despegar
m_chispa = mat_estrella()
molde = figura_plana("chispa_molde", ESTRELLA5, m_chispa)
molde.hide_render = True
for i in range(12):
    a = math.pi * (i + 0.5) / 12
    o = objeto("chispa", molde.data, None, suave=False, sombra=False)
    d, s = random.uniform(1.4, 2.8), random.uniform(0.16, 0.30)
    direccion = Vector((math.cos(a), -0.15, math.sin(a) * 0.5))
    base = suelo + Vector((0, -0.8, 0.3))
    for f, t, e in ((1, 0.0, 0.0), (F_MOTOR - 2, 0.1, 0.0), (F_MOTOR + 5, 0.6, s), (F_MOTOR + 15, 0.92, s * 0.8),
                    (F_MOTOR + 25, 1.0, 0.0)):
        clave(o, "location", f, tuple(base + direccion * d * t))
        clave(o, "scale", f, (e, e, e))
    clave(o, "rotation_euler", F_MOTOR, (0, random.uniform(-1, 1), 0))
    clave(o, "rotation_euler", F_MOTOR + 25, (0, random.uniform(-3, 3), 0))

# ----------------------------------------------------------------------------- luz, cámara y fundido
sol()
o_cam, mira, cam = camara(K.lente, alcance=900)
cam_ini, mira_ini = Vector(K.cam), Vector(K.mira)
f_sigue = F_MOTOR + 40 if not PUENTE else F_CORTE - 26          # la cámara se queda en el mapa y luego mira arriba
for f, p in ((1, cam_ini), (f_sigue, cam_ini), (F_CORTE - 1, cam_ini + Vector((0, -3, 4)))):
    clave(o_cam, "location", f, tuple(p))
claves_mira = [(1, mira_ini), (f_sigue, mira_ini)]          # después la mirada sube detrás de la nave
curvas_nave = [fc for fc in raiz.animation_data.action.fcurves if fc.data_path == "location"]
for f in list(range(f_sigue + 2, F_CORTE - 1, 2)) + [F_CORTE - 1]:
    donde = Vector([fc.evaluate(f) for fc in sorted(curvas_nave, key=lambda c: c.array_index)])
    claves_mira.append((f, mira_ini.lerp(donde, suave(min(1.0, (f - f_sigue) / 14)))))   # la alcanza y no la suelta
for f, p in claves_mira:
    clave(mira, "location", f, tuple(p))
for i in range(12):
    u = i / 11
    f = F_V + round((F_FIN - F_V) * u)
    clave(o_cam, "location", f, tuple(camara_en(u)))
    hacia = (P_ORIGEN + Vector((3.5, 0, 1.0))).lerp(P_DESTINO + Vector((-3.0, 0, 0)), suave(min(1.0, u / 0.45)))
    clave(mira, "location", f, tuple(hacia))
for f, lente, lejos in ((1, K.lente, 900), (F_CORTE - 1, K.lente, 900), (F_CORTE, 35, 3200), (F_FIN, 35, 3200)):
    clave(cam, "lens", f, lente)
    clave(cam, "clip_end", f, lejos)
for obj in (o_cam, mira, raiz, nave):    # el corte entre decorados no se interpola
    for fc in obj.animation_data.action.fcurves:
        for kf in fc.keyframe_points:
            if int(kf.co.x) in (F_CORTE - 1, F_CORTE):
                kf.handle_left_type = kf.handle_right_type = "VECTOR"

fundido(velo(o_cam), [(F_CORTE - 14, 0.0), (F_CORTE - 3, 1.0), (F_CORTE + 3, 1.0), (F_CORTE + 18, 0.0)])

compositor()
salidas(NOMBRE)
