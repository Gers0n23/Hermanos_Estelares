"""Cinemáticas de cierre de planeta: la nave-estrella se va armando en el taller (nido-hangar).

Un solo escenario para los 6 planetas: la nave sobre su pedestal de nubes, con las piezas ya ganadas
puestas. La pieza del planeta recién terminado llega en una burbuja dorada, encaja en su hueco
fantasma y la nave lo celebra con una vuelta completa (así se ven todas las piezas que lleva).

  1 ala izquierda (Arcoíris)   2 ala derecha (Animalia)      3 motor izquierdo (Melodía)
  4 motor derecho (Cuenta-Cuentas)   5 antena con banderines (Letralandia)   6 núcleo-corazón (Corazón)

Con la pieza 6 la nave "cobra vida": se van los remiendos, aparecen la franja dorada, las estrellas
y la placa, y la cúpula queda encendida.

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P taller_piezas.py -- --pieza 3 --fotos 1,80,112,150,216
  blender -b -P taller_piezas.py -- --pieza 3 --video
Opciones: --salida CARPETA, --escala 50, --muestras 32, --sin-pincel, --blend, --nombre BASE
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403 — utilidades, look 2D, la nave y sus piezas

NUM = int(arg("--pieza", 1))
assert 1 <= NUM <= 6, "--pieza va de 1 a 6"
IDENT = PIEZAS[NUM - 1][0]
NOMBRE = arg("--nombre", f"taller_pieza_{NUM}_{IDENT}")
random.seed(20 + NUM)

# ----------------------------------------------------------------------------- línea de tiempo
F_ENTRA = 16         # la burbuja entra en cuadro
F_FLOTA = 62         # queda flotando frente a la nave
F_POP = 90           # la burbuja revienta
F_ENCAJE = 110       # la pieza encaja
F_GIRO0, F_GIRO1 = 126, 196   # vuelta completa de celebración
F_FIN = 216          # 9 s
Z_NAVE = 1.25        # altura del centro de la nave sobre el pedestal
# giro de la nave en reposo: el lado donde va la pieza queda hacia la cámara
ANGULO = {1: math.pi - 0.35, 2: 0.35, 3: math.pi - 0.60, 4: 0.60, 5: math.pi - 0.45, 6: math.pi - 0.45}[NUM]
CAM_INICIO = Vector((0.6, -11.6, 3.2))

preparar_render(F_FIN)

# ----------------------------------------------------------------------------- cielo del nido-hangar
mundo = bpy.data.worlds.new("hangar")
ESC.world = mundo
mundo.use_nodes = True
nt = mundo.node_tree
fondo = nt.nodes["Background"]
coord = nt.nodes.new("ShaderNodeTexCoord")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
rampa = nt.nodes.new("ShaderNodeValToRGB")
nt.links.new(coord.outputs["Generated"], sep.inputs[0])
nt.links.new(sep.outputs["Z"], rampa.inputs[0])
nt.links.new(rampa.outputs[0], fondo.inputs["Color"])
paradas = [(0.0, "#E2A96C"), (0.12, "#C98A5C"), (0.40, "#A9665C"), (1.0, "#7C4856")]
rampa.color_ramp.elements[0].position, rampa.color_ramp.elements[0].color = 0.0, lin(paradas[0][1])
rampa.color_ramp.elements[1].position, rampa.color_ramp.elements[1].color = 1.0, lin(paradas[3][1])
for pos, col in paradas[1:3]:
    rampa.color_ramp.elements.new(pos).color = lin(col)

m_estrella = brillante("estrella", "#FFD86B", 1.6)


def _estrellas(bm):
    def una(p, radio, puntas):
        giro = (CAM_INICIO - p).to_track_quat("Z", "Y").to_matrix().to_4x4()
        mtx = Matrix.Translation(p) @ giro @ Matrix.Rotation(random.uniform(-0.3, 0.3), 4, "Z")
        n = puntas * 2
        vs = []
        for k in range(n):
            r = radio if k % 2 == 0 else radio * (0.55 if puntas == 5 else 0.9)
            a = math.pi / 2 + k * 2 * math.pi / n
            vs.append(bm.verts.new(mtx @ Vector((r * math.cos(a), r * math.sin(a), 0))))
        bm.faces.new(vs)

    for i in range(150):
        az, el = random.uniform(-0.75, 0.75), random.uniform(-0.05, 0.62)
        p = Vector((math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el))) * 200
        if i < 14:
            una(p, random.uniform(2.0, 3.6), 5)
        else:
            una(p, random.uniform(0.3, 0.8), 4)


objeto("estrellas", malla_bm("estrellas", _estrellas), m_estrella, suave=False, sombra=False)

# ----------------------------------------------------------------------------- pedestal y nubes
m_nube = toon("nube", "#FFF1DC", tinte="#F8CDCB", umbral=(0.40, 0.48))
m_nube_lejos = toon("nube_lejos", "#F6D2B0", tinte="#E0A0A8", umbral=(0.40, 0.48))
m_pedestal = toon("pedestal", "#BDB4DA", brillo=0.3)
m_pedestal2 = toon("pedestal_borde", "#D9D2EE", brillo=0.3)

torno("pedestal", [(0, 0.0), (4.3, 0.0), (4.45, -0.12), (4.45, -0.42), (4.2, -0.55), (2.4, -0.75),
                   (1.5, -1.6), (1.5, -6.0)], [m_pedestal2, m_pedestal], seg=64,
      mats_seg=[0, 0, 1, 1, 1, 1, 1], linea=0.04)

# nido de nubecitas: bajas junto a la nave (para que pueda girar) y gorditas hacia el borde
for k in range(26):
    a = 2 * math.pi * k / 26 + random.uniform(-0.1, 0.1)
    d = random.uniform(1.5, 2.3)
    esfera("nubecita", random.uniform(0.42, 0.6), (math.cos(a) * d, math.sin(a) * d, -0.12), m_nube,
           escala=(1.2, 1.2, 0.75), u=18, v=10)
for k in range(22):
    a = 2 * math.pi * k / 22 + random.uniform(-0.12, 0.12)
    d = random.uniform(2.9, 3.7)
    esfera("nube_borde", random.uniform(0.5, 0.72), (math.cos(a) * d, math.sin(a) * d, -0.15), m_nube,
           escala=(1.25, 1.25, 0.8), u=18, v=10)
esfera("nube_centro", 2.0, (0, 0, -0.55), m_nube, escala=(1, 1, 0.35), u=24, v=10)

# bancos de nubes alrededor (el taller flota entre nubes)
for x, y, z, r in ((-8.5, -3.5, -1.8, 3.4), (8.8, -3.0, -1.9, 3.6), (-11, 6, -0.5, 4.5), (11.5, 7, -0.8, 4.8),
                   (-5.5, -5.5, -2.6, 2.6), (5.2, -5.8, -2.7, 2.6), (0, 14, -2.5, 6.0), (-19, 16, 0.5, 6.5),
                   (19, 18, 0.2, 7.0), (-14, -1, -2.2, 3.6), (14.5, 0, -2.3, 3.8)):
    m = m_nube if y < 5 else m_nube_lejos
    for k in range(4):
        esfera("banco", r * random.uniform(0.6, 1.0),
               (x + random.uniform(-1, 1) * r * 0.9, y + random.uniform(-0.4, 0.4) * r, z + random.uniform(-0.2, 0.3) * r),
               m, escala=(1.3, 1.1, 0.7), u=28, v=14, sombra=False)

# rincón de taller: caja de herramientas, cajón con estrella y un tarro de pintura
m_caja = toon("caja_roja", "#E26D6D", brillo=0.3)
m_madera = toon("madera", "#C99363")
m_oro = mat("oro", toon, "#F2C25C", brillo=0.5)
caja("cajon", (2.75, 1.9, 0.0), (3.55, 2.7, 0.75), m_madera, linea=0.03)
figura_plana("estrella_cajon", [(x * 0.24, z * 0.24) for x, z in ESTRELLA5], m_oro).location = (3.15, 1.88, 0.38)
caja("herramientas", (2.95, 2.05, 0.75), (3.5, 2.5, 1.02), m_caja, linea=0.025)
caja("asa", (3.1, 2.24, 1.02), (3.35, 2.31, 1.12), m_oro, linea=0.02)
cilindro("tarro", 0.2, 0.36, (2.35, 1.5, 0.0), toon("tarro", "#8FD3F0", brillo=0.3), linea=0.025)
cilindro("pintura", 0.17, 0.03, (2.35, 1.5, 0.36), toon("pintura", "#F7A8C8"))

# ----------------------------------------------------------------------------- la nave y las piezas ya ganadas
N = construir_nave()
raiz, nave = N.raiz, N.nave
raiz.location = (0, 0, Z_NAVE)
raiz.rotation_euler = (0, 0, ANGULO)
for ident, _ in PIEZAS[:NUM - 1]:
    pieza(ident, nave)

# hueco fantasma: la silueta dorada de la pieza, latiendo en su lugar hasta que llega
m_fantasma = halo("fantasma", "#FFD86B", centro=0.30, borde=0.95, fuerza=1.3)
hueco = fantasmear(pieza(IDENT, nave), m_fantasma)
escala0 = hueco.scale.copy()
for f in range(1, F_ENCAJE, 12):
    clave(hueco, "scale", f, escala0 * (1.06 if (f // 12) % 2 else 1.0))
clave(hueco, "scale", F_ENCAJE - 1, escala0)
clave(hueco, "scale", F_ENCAJE + 3, (0, 0, 0))
clave(hueco, "hide_render", F_ENCAJE + 3, False)
clave(hueco, "hide_render", F_ENCAJE + 4, True)

# ----------------------------------------------------------------------------- la pieza nueva llega en su burbuja
nueva = pieza(IDENT, nave)
encaje, giro0 = nueva.location.copy(), Vector(nueva.rotation_euler)
centro = Vector(CENTRO_PIEZA.get(IDENT, (0, 0, 0)))


def a_nave(p):
    """Punto del mundo → coordenadas de la nave en reposo (antes de la vuelta de celebración)."""
    return Matrix.Rotation(-ANGULO, 3, "Z") @ (Vector(p) - Vector((0, 0, Z_NAVE)))


P_FUERA, P_FLOTA = Vector((-9.5, -3.0, 8.5)), Vector((-3.3, -3.0, 2.7))
for f, p in ((1, P_FUERA), (F_ENTRA, P_FUERA), (F_FLOTA, P_FLOTA), (F_FLOTA + 14, P_FLOTA + Vector((0.1, 0, 0.22))),
             (F_POP, P_FLOTA), (F_POP + 9, P_FLOTA + Vector((-0.45, -0.3, 0.35)))):
    clave(nueva, "location", f, a_nave(p))
clave(nueva, "location", F_ENCAJE, encaje)
for f, r in ((1, (0.5, 0.3, -2 * math.pi - 0.6)), (F_FLOTA, (0.25, -0.2, -2 * math.pi)),
             (F_POP + 9, (0.1, 0.25, -2 * math.pi + 0.3)), (F_ENCAJE, (0, 0, 0))):
    clave(nueva, "rotation_euler", f, tuple(giro0 + Vector(r)))
for f, s in ((1, 0.8), (F_POP, 0.8), (F_POP + 6, 1.25), (F_ENCAJE - 2, 1.15), (F_ENCAJE + 3, 0.92),
             (F_ENCAJE + 8, 1.06), (F_ENCAJE + 14, 1.0)):
    clave(nueva, "scale", f, (s, s, s))

m_burbuja = halo("burbuja", "#FFE9A8", centro=0.10, borde=0.85, fuerza=1.3)
burbuja = esfera("burbuja", RADIO_PIEZA[IDENT] * 1.25, centro, m_burbuja, padre=nueva, u=40, v=24, sombra=False)
brillo_b = esfera("burbuja_brillo", 0.10, centro + Vector((-0.3, -0.75, 0.45)) * RADIO_PIEZA[IDENT] * 1.25,
                  brillante("blanco", "#FFFFFF", 1.2), escala=(0.6, 0.6, 1.6), padre=nueva, u=10, v=6, sombra=False)
for o in (burbuja, brillo_b):
    for f, s in ((1, 1.0), (F_POP, 1.0), (F_POP + 4, 1.45)):
        clave(o, "scale", f, (s, s, s))
    clave(o, "hide_render", F_POP + 4, False)
    clave(o, "hide_render", F_POP + 5, True)
for f, al in ((1, 1.0), (F_POP, 1.0), (F_POP + 4, 0.0)):
    clave(burbuja, "color", f, (1, 1, 1, al))

# ----------------------------------------------------------------------------- la nave reacciona
E = F_ENCAJE
for f, s in ((E - 1, (1, 1, 1)), (E + 3, (1.06, 1.06, 0.92)), (E + 8, (0.97, 0.97, 1.05)), (E + 14, (1, 1, 1)),
             (F_GIRO1, (1, 1, 1)), (F_GIRO1 + 4, (1.05, 1.05, 0.93)), (F_GIRO1 + 10, (1, 1, 1))):
    clave(raiz, "scale", f, s)
for f, z in ((1, Z_NAVE), (F_GIRO0 - 4, Z_NAVE), (F_GIRO0 + 14, Z_NAVE + 0.8), (F_GIRO1 - 22, Z_NAVE + 0.8),
             (F_GIRO1, Z_NAVE), (F_FIN, Z_NAVE)):
    clave(raiz, "location", f, (0, 0, z))
for f, g in ((1, ANGULO), (F_GIRO0, ANGULO), (F_GIRO1, ANGULO + 2 * math.pi), (F_FIN, ANGULO + 2 * math.pi)):
    clave(raiz, "rotation_euler", f, (0, 0, g))
for f, cab in ((F_GIRO0 - 4, 0.0), (F_GIRO0 + 14, 0.10), (F_GIRO1 - 22, -0.08), (F_GIRO1, 0.0)):
    clave(nave, "rotation_euler", f, (0, cab, 0))

es_nucleo = IDENT == "nucleo"
for f, v in ((1, 0.12), (E, 0.12), (E + 6, 1.0), (E + 34, 0.45 if es_nucleo else 0.3),
             (F_FIN, 0.4 if es_nucleo else 0.3)):
    clave_nodo(N.encendido, f, v)
fuerza_tobera = N.m_fuego.node_tree.nodes["Emission"].inputs["Strength"]
for f, v in ((1, 0.9), (E, 0.9), (E + 5, 2.8), (E + 22, 1.2), (F_GIRO0 + 14, 2.4), (F_GIRO1, 1.3),
             (F_GIRO1 + 8, 2.2), (F_FIN, 1.5)):
    clave_nodo(fuerza_tobera, f, v)

if es_nucleo:
    # la nave cobra vida: los remiendos saltan y se van, aparecen la franja, las estrellas y la placa
    for k, o in enumerate(N.remiendos):
        f0 = E + 8 + (k * 5) % 22
        s0 = o.scale.copy()
        clave(o, "scale", f0, s0)
        clave(o, "scale", f0 + 3, s0 * 1.35)
        clave(o, "scale", f0 + 8, (0, 0, 0))
        clave(o, "hide_render", f0 + 8, False)
        clave(o, "hide_render", f0 + 9, True)
    for k, o in enumerate(vestir_gala(N)):
        f0 = E + 26 + k * 4
        clave(o, "scale", 1, (0, 0, 0))
        clave(o, "scale", f0, (0, 0, 0))
        clave(o, "scale", f0 + 6, (1.2, 1.2, 1.2))
        clave(o, "scale", f0 + 11, (1, 1, 1))
        clave(o, "hide_render", f0, True)
        clave(o, "hide_render", f0 + 1, False)
    for m, hasta in ((N.m_aro, "#F2C25C"), (N.m_tobera, "#F4E3C0")):
        z = m.node_tree.nodes["color"].outputs[0]
        clave_nodo(z, E + 10, tuple(z.default_value))
        clave_nodo(z, E + 30, lin(hasta))

# ----------------------------------------------------------------------------- destellos del encaje
m_dorado = con_alfa("onda", "#FFE08A", 1.4)
p_encaje = raiz.matrix_basis @ (encaje + centro)       # punto del encaje en el mundo
p_encaje = Vector((p_encaje.x, min(p_encaje.y, 0.0) - 1.3, p_encaje.z))
onda = torno("onda", [(0.84, 0.0), (1.0, 0.0)], m_dorado, seg=48)
onda.visible_shadow = False
onda.location = p_encaje
onda.rotation_euler = (math.pi / 2, 0, 0)
for f, s, al in ((1, 0.0, 0.0), (E, 0.2, 1.0), (E + 16, 2.6, 0.5), (E + 26, 3.4, 0.0)):
    clave(onda, "scale", f, (s, s, s))
    clave(onda, "color", f, (1, 1, 1, al))

molde = figura_plana("chispa_molde", ESTRELLA5, m_estrella)
molde.hide_render = True
me_chispa = molde.data
for k in range(14):
    a = 2 * math.pi * k / 14 + random.uniform(-0.2, 0.2)
    o = objeto("chispa", me_chispa, None, suave=False, sombra=False)
    d, s = random.uniform(1.5, 2.9), random.uniform(0.16, 0.34)
    direccion = Vector((math.cos(a), 0, math.sin(a)))
    for f, t, e in ((1, 0.0, 0.0), (E, 0.1, 0.0), (E + 6, 0.55, s), (E + 16, 0.9, s * 0.8), (E + 26, 1.0, 0.0)):
        clave(o, "location", f, p_encaje + direccion * d * t + Vector((0, -0.2, 0)))
        clave(o, "scale", f, (e, e, e))
    clave(o, "rotation_euler", E, (0, random.uniform(-1, 1), 0))
    clave(o, "rotation_euler", E + 26, (0, random.uniform(-3, 3), 0))

# confeti que cae durante la celebración
m_confeti = [brillante("confeti_" + c, c, 1.0) for c in ("#F7A8C8", "#FBE08A", "#8FD3F0", "#C3A6E8", "#9CE0B0")]
for m in m_confeti:
    m.use_backface_culling = False
me_confeti = [malla_bm("confeti", lambda bm: bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.07,
                                                                   matrix=Matrix.Diagonal((1.6, 1, 1, 1))))
              for _ in m_confeti]
for me, m in zip(me_confeti, m_confeti):
    me.materials.append(m)
for k in range(90):
    o = objeto("confeti", me_confeti[k % 5], None, suave=False, sombra=False)
    x, y = random.uniform(-6.0, 6.0), random.uniform(-4.0, 2.0)
    f0, dur = E + 2 + random.randint(0, 60), random.randint(60, 90)
    clave(o, "location", 1, (x, y, 8.0))
    clave(o, "location", f0, (x, y, 8.0))
    clave(o, "location", f0 + dur, (x + random.uniform(-1.2, 1.2), y, -1.5))
    clave(o, "rotation_euler", f0, tuple(random.uniform(0, 6) for _ in range(3)))
    clave(o, "rotation_euler", f0 + dur, tuple(random.uniform(-14, 14) for _ in range(3)))
    lineal(o)

# ----------------------------------------------------------------------------- guirnalda: las 6 piezas del viaje
m_medalla_aro = brillante("medalla_aro", "#FFD27A", 1.25)
m_medalla_si = brillante("medalla_si", "#8FD9C6", 1.0)
m_medalla_no = brillante("medalla_no", "#8A5560", 1.0)
m_fantasma_mini = halo("fantasma_mini", "#FFD86B", centro=0.45, borde=1.0, fuerza=1.2)
POSE_MINI = {"ala_izquierda": ((math.pi / 2, 0.9, 0), 0.42), "ala_derecha": ((math.pi / 2, 0.9, 0), 0.42),
             "motor_izquierdo": ((0, 0.45, 0), 0.62), "motor_derecho": ((0, 0.45, 0.5), 0.62),
             "antena": ((0, 0.12, 0), 0.52), "nucleo": ((0, 0, 0), 0.62)}


def mini(ident, medalla, fantasma):
    e = pieza(ident, None)
    if fantasma:
        fantasmear(e, m_fantasma_mini)
    for o in mallas_de(e):
        o.visible_shadow = False
    giro, escala = POSE_MINI[ident]
    e.parent = medalla
    c = Vector(CENTRO_PIEZA.get(ident, (0, 0, 0))) * escala
    e.location = (-c.x, -0.16, -c.z)
    e.rotation_euler = giro
    e.scale = (escala, escala, escala)
    return e


def alternar(o, cuadro, visible_despues):
    """El objeto (y sus hijos) se ve solo antes o solo después de `cuadro`."""
    for h in [o] + list(o.children_recursive):
        clave(h, "hide_render", cuadro - 1, visible_despues)
        clave(h, "hide_render", cuadro, not visible_despues)


F_MEDALLA = E + 8
for i, (ident, _) in enumerate(PIEZAS):
    t = (i - 2.5) / 2.5
    med = vacio("medalla", None, (i * 1.84 - 4.6, 2.0, 4.55 - 0.85 * t * t))
    aro = cilindro("medalla_aro", 0.56, 0.04, (0, 0, 0), m_medalla_aro, med, seg=40)
    aro.rotation_euler = (math.pi / 2, 0, 0)
    aro.visible_shadow = False
    discos = {}
    for clave_d, m in (("si", m_medalla_si), ("no", m_medalla_no)):
        d = cilindro("medalla_" + clave_d, 0.48, 0.04, (0, -0.03, 0), m, med, seg=40)
        d.rotation_euler = (math.pi / 2, 0, 0)
        d.visible_shadow = False
        discos[clave_d] = d
    if i + 1 < NUM:
        discos["no"].hide_render = True
        mini(ident, med, False)
    elif i + 1 > NUM:
        discos["si"].hide_render = True
        mini(ident, med, True)
    else:   # la de este planeta: se enciende al encajar la pieza
        alternar(discos["no"], F_MEDALLA, False)
        alternar(mini(ident, med, True), F_MEDALLA, False)
        alternar(discos["si"], F_MEDALLA, True)
        alternar(mini(ident, med, False), F_MEDALLA, True)
        for f, s in ((F_MEDALLA - 2, 1.0), (F_MEDALLA + 3, 1.45), (F_MEDALLA + 9, 0.95), (F_MEDALLA + 14, 1.12),
                     (F_MEDALLA + 20, 1.0)):
            clave(med, "scale", f, (s, s, s))

# ----------------------------------------------------------------------------- luz y cámara
sol = bpy.data.lights.new("sol", "SUN")
sol.energy, sol.color, sol.angle = 1.6, (1.0, 1.0, 1.0), 0.02
o_sol = bpy.data.objects.new("sol", sol)
COL.objects.link(o_sol)
apuntar(o_sol, (0.62, 0.50, -0.60))  # desde arriba a la izquierda, del lado de la cámara

cam = bpy.data.cameras.new("camara")
cam.lens, cam.clip_end = 38, 800
o_cam = bpy.data.objects.new("camara", cam)
COL.objects.link(o_cam)
ESC.camera = o_cam
mira = vacio("mira")
seguir = o_cam.constraints.new("TRACK_TO")
seguir.target, seguir.track_axis, seguir.up_axis = mira, "TRACK_NEGATIVE_Z", "UP_Y"
for f, p in ((1, tuple(CAM_INICIO)), (F_ENCAJE, (0.2, -10.6, 3.0)), (F_FIN, (-0.3, -10.9, 3.1))):
    clave(o_cam, "location", f, p)
for f, p in ((1, (0, 0, 2.0)), (F_ENCAJE, (0, 0, 1.95)), (F_FIN, (0, 0, 2.05))):
    clave(mira, "location", f, p)

compositor()
salidas(NOMBRE)
