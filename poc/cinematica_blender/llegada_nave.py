"""POC v2: cinemática 3D en Blender con look 2D pintado — la nave-estrella llega al patio.

Todo se construye por código (sin modelar a mano): escenario, nave, luces, cámara y animación.
La nave y las utilidades viven en nave_comun.py (las comparte taller_piezas.py).
Cambios frente a la v1 (llegada_nave_v1.py):
  - La nave es la DEL JUEGO en su estado básico (assets/anclas/nave_estrella_hangar_referencia.png):
    cuerpo de huevo menta acostado, extremos crema, cúpula arriba con aro, tres toberas atrás,
    curitas amarillas y parches. Con --completa se viste como el sprite final (alas, corazón, aro dorado).
  - Look 2D: sombreado plano de dos tonos con borde pintado, contornos oscuros (casco invertido),
    estrellas gorditas doradas y filtro de pincel (Kuwahara) en el compositor.
  - Puesta en escena: baja de cola con quema de frenado y, a ras de suelo, se acuesta sobre la panza.

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P llegada_nave.py -- --fotos 1,80,150,170,252   # cuadros sueltos de revisión
  blender -b -P llegada_nave.py -- --video                    # mp4 completo
  blender -b -P llegada_nave.py -- --blend                    # guarda el .blend para abrirlo
Opciones: --salida CARPETA, --escala 50, --muestras 32, --completa, --sin-pincel, --nombre BASE
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403 — utilidades, look 2D y la nave del juego (escena vacía al importar)

COMPLETA = bool(arg("--completa"))
NOMBRE = arg("--nombre", "llegada_nave_v2" + ("_completa" if COMPLETA else ""))
random.seed(7)

# ----------------------------------------------------------------------------- línea de tiempo
FPS = 24
F_FRENADO = 108      # empieza la quema de frenado
F_VUELCO = 140       # a ras de suelo: apaga motores y se acuesta
F_TOQUE = 166        # la panza toca el pasto
F_FIN = 252          # 10,5 s
NX = -2.2            # x del punto de aterrizaje
R_NAVE = 1.10        # radio del cuerpo: altura del centro cuando descansa acostada
CAM_INICIO = Vector((-3.0, -10.0, 1.3))

# ----------------------------------------------------------------------------- render
ESC.render.engine = "BLENDER_EEVEE_NEXT"
ESC.render.resolution_x, ESC.render.resolution_y = 1280, 720
ESC.render.resolution_percentage = int(arg("--escala", 100))
ESC.render.fps = FPS
ESC.frame_start, ESC.frame_end = 1, F_FIN
ESC.eevee.taa_render_samples = int(arg("--muestras", 32))
ESC.view_settings.view_transform = "Standard"
ESC.view_settings.look = "None"

# ----------------------------------------------------------------------------- cielo (mundo)
mundo = bpy.data.worlds.new("atardecer")
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
paradas = [(0.0, "#FFC08A"), (0.10, "#F79A93"), (0.34, "#A878B4"), (1.0, "#4A3F82")]
rampa.color_ramp.elements[0].position, rampa.color_ramp.elements[0].color = 0.0, lin(paradas[0][1])
rampa.color_ramp.elements[1].position, rampa.color_ramp.elements[1].color = 1.0, lin(paradas[3][1])
for pos, col in paradas[1:3]:
    rampa.color_ramp.elements.new(pos).color = lin(col)
fondo.inputs["Strength"].default_value = 1.0

# estrellas gorditas de cinco puntas (como las del arte del juego) + puntitos
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

    for i in range(120):
        az, el = random.uniform(-1.5, 1.5), random.uniform(0.36, 1.5)
        p = Vector((math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el))) * 260
        if i < 16:
            una(p, random.uniform(1.6, 3.2), 5)
        else:
            una(p, random.uniform(0.25, 0.6), 4)


objeto("estrellas", malla_bm("estrellas", _estrellas), m_estrella, suave=False, sombra=False)

# nubes: dos tonos planos, panza durazno por el sol bajo y lomo lila
m_nube = bpy.data.materials.new("nube")
m_nube.use_nodes = True
nt = m_nube.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
alt = nt.nodes.new("ShaderNodeAttribute")
alt.attribute_name = "h"
rampa = nt.nodes.new("ShaderNodeValToRGB")
emi = nt.nodes.new("ShaderNodeEmission")
rampa.color_ramp.elements[0].position, rampa.color_ramp.elements[0].color = 0.50, lin("#FFD3B4")
rampa.color_ramp.elements[1].position, rampa.color_ramp.elements[1].color = 0.58, lin("#C79DC6")
nt.links.new(alt.outputs["Fac"], rampa.inputs[0])
nt.links.new(rampa.outputs[0], emi.inputs["Color"])
nt.links.new(emi.outputs[0], nt.nodes["Material Output"].inputs["Surface"])


def _nubes(bm):
    capa_h = bm.verts.layers.float_color.new("h")
    for _ in range(22):
        az = random.uniform(-1.35, 1.35)
        el = random.uniform(0.07, 1.0) ** 1.4
        d = 170
        c = Vector((d * math.sin(az) * math.cos(el), d * math.cos(az) * math.cos(el), d * math.sin(el)))
        lado = Vector((math.cos(az), -math.sin(az), 0))
        tam = random.uniform(5, 11) * (1.0 - 0.35 * el)
        n_bolas = random.randint(4, 6)
        for k in range(n_bolas):
            t = (k - (n_bolas - 1) / 2) / (n_bolas / 2)
            p = c + lado * t * tam * 2.4 + Vector((0, 0, (1 - abs(t)) * random.uniform(0.2, 0.7) * tam))
            r = tam * (1.3 - 0.6 * abs(t)) * random.uniform(0.85, 1.15)
            nuevos = bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=18, radius=r,
                                               matrix=Matrix.Translation(p) @ Matrix.Diagonal((1.3, 1.3, 0.62, 1)))
            for v in nuevos["verts"]:
                h = (v.co.z - c.z) / tam + 0.12 * math.sin(v.co.x * 0.35 + v.co.y * 0.35)
                v[capa_h] = (h, h, h, 1.0)


objeto("nubes", malla_bm("nubes", _nubes), m_nube, sombra=False)

# ----------------------------------------------------------------------------- patio
m_pasto = toon("pasto", "#5E9A55")
caja("suelo", (-150, -60, -1), (150, 150, 0), m_pasto)

# matas de pasto (una malla, color por vértice: base oscura, punta clara)
m_brizna = toon("brizna", atributo="col")
m_brizna.use_backface_culling = False
verts, caras, colores = [], [], []
base_c, punta_c = lin("#4C8A4C"), lin("#8CC466")
for _ in range(2600):
    x, y = random.uniform(-16, 12), random.uniform(-10.5, 6.8)
    if x > 3.0 and y > 1.8:
        continue
    for _ in range(3):  # tres hojas por mata
        alto = random.uniform(0.14, 0.32)
        ang = random.uniform(0, math.pi)
        dx, dy = math.cos(ang) * 0.045, math.sin(ang) * 0.045
        lx, ly = random.uniform(-0.12, 0.12), random.uniform(-0.12, 0.12)
        n = len(verts)
        verts += [(x - dx, y - dy, 0), (x + dx, y + dy, 0), (x + lx, y + ly, alto)]
        caras.append((n, n + 1, n + 2))
        colores += [base_c, base_c, punta_c]
me = bpy.data.meshes.new("briznas")
me.from_pydata(verts, [], caras)
capa = me.color_attributes.new(name="col", type="FLOAT_COLOR", domain="POINT")
for i, c in enumerate(colores):
    capa.data[i].color = c
objeto("briznas", me, m_brizna, suave=False, sombra=False)

# cerca de madera al fondo
m_madera = toon("madera", "#B07A52")
for i in range(13):
    x = -21 + i * 2.0
    caja(f"poste{i}", (x - 0.09, 6.90, 0), (x + 0.09, 7.10, 1.2), m_madera, linea=0.025)
for z in (0.45, 0.9):
    caja("riel", (-21, 6.96, z - 0.08), (3.2, 7.04, z + 0.08), m_madera, linea=0.025)

# árboles y arbustos
m_tronco = toon("tronco", "#7A5540")
m_hojas = [toon("hojas1", "#4F9160"), toon("hojas2", "#63A86A")]


def arbol(x, y, alto, copa):
    cilindro("tronco", 0.22 * copa, alto, (x, y, 0), m_tronco, radio2=0.15 * copa, linea=0.04)
    for k in range(5):
        p = (x + random.uniform(-0.9, 0.9) * copa, y + random.uniform(-0.6, 0.6) * copa,
             alto + random.uniform(-0.2, 1.0) * copa)
        esfera("copa", random.uniform(0.9, 1.4) * copa, p, m_hojas[k % 2], u=16, v=10, linea=0.05)


arbol(-6.5, 9.5, 2.2, 1.3)
arbol(-12.5, 12.0, 2.8, 1.6)
arbol(-17.0, 10.0, 2.0, 1.2)
for x in (-9.5, -3.8, -1.5, 1.6):
    esfera("arbusto", random.uniform(0.5, 0.8), (x, 7.6, 0.25), m_hojas[1], escala=(1.4, 1, 0.9),
           u=16, v=10, linea=0.04)

# cerros lejanos (planos, sin contorno: quedan como telón)
m_cerro = brillante("cerro", "#8273AE")
m_cerro2 = brillante("cerro2", "#9A82B8")
for i, (x, y, sx, sz) in enumerate(((-55, 95, 45, 11), (-5, 120, 60, 15), (60, 100, 50, 12), (-110, 110, 50, 9))):
    esfera("cerro", 1.0, (x, y, -1.5), (m_cerro, m_cerro2)[i % 2], escala=(sx, 22, sz))

# ----------------------------------------------------------------------------- la casa
m_muro = toon("muro", "#F0D2B4")
m_zocalo = toon("zocalo", "#B99782")
m_techo = toon("techo", "#B5616B")
m_marco = toon("marco", "#FFF4E2")
m_vidrio = brillante("vidrio_ventana", "#FFDF8F", 1.25)
m_cortina = brillante("cortina", "#FFF3D6", 1.05)

caja("casa", (3.2, 2.0, 0), (13, 6.5, 5.2), m_muro, linea=0.04)  # poco profunda: su techo no asoma tras la cúpula
caja("zocalo", (3.15, 1.95, 0), (13, 6.5, 0.35), m_zocalo, linea=0.03)
caja("alero", (2.6, 1.4, 5.2), (13.6, 7.1, 5.5), m_techo, linea=0.04)
caja("techo", (3.0, 1.8, 5.5), (13.2, 6.7, 6.3), m_techo, linea=0.04)
VX, VZ, VA, VH = 6.4, 2.55, 2.5, 2.0  # centro x, centro z, ancho, alto de la ventana del living
caja("vidrio", (VX - VA / 2, 1.96, VZ - VH / 2), (VX + VA / 2, 1.99, VZ + VH / 2), m_vidrio)
for dx in (-1, 1):  # cortinas recogidas a los lados
    caja("cortina", (VX + dx * VA / 2 - (0.55 if dx > 0 else 0), 1.94, VZ - VH / 2),
         (VX + dx * VA / 2 + (0.55 if dx < 0 else 0), 1.96, VZ + VH / 2), m_cortina)
g = 0.11
caja("marco_izq", (VX - VA / 2 - g, 1.86, VZ - VH / 2 - g), (VX - VA / 2, 2.0, VZ + VH / 2 + g), m_marco, linea=0.02)
caja("marco_der", (VX + VA / 2, 1.86, VZ - VH / 2 - g), (VX + VA / 2 + g, 2.0, VZ + VH / 2 + g), m_marco, linea=0.02)
caja("marco_sup", (VX - VA / 2 - g, 1.86, VZ + VH / 2), (VX + VA / 2 + g, 2.0, VZ + VH / 2 + g), m_marco, linea=0.02)
caja("marco_inf", (VX - VA / 2 - 0.2, 1.74, VZ - VH / 2 - 0.14), (VX + VA / 2 + 0.2, 2.0, VZ - VH / 2), m_marco, linea=0.02)
caja("cruz_v", (VX - 0.04, 1.9, VZ - VH / 2), (VX + 0.04, 1.97, VZ + VH / 2), m_marco)
caja("cruz_h", (VX - VA / 2, 1.9, VZ - 0.04), (VX + VA / 2, 1.97, VZ + 0.04), m_marco)

# macetero con flores bajo la ventana
m_maceta = toon("maceta", "#D9705A")
m_flor = toon("flor", "#F58BB4")
cilindro("maceta", 0.24, 0.45, (4.6, 1.2, 0), m_maceta, radio2=0.32, linea=0.025)
for k in range(6):
    a = k * 1.05
    p = (4.6 + math.cos(a) * 0.2, 1.2 + math.sin(a) * 0.2, 0.75 + (k % 3) * 0.22)
    cilindro("tallo", 0.015, p[2] - 0.4, (p[0], p[1], 0.4), m_hojas[1], seg=6)
    esfera("flor", 0.085, p, m_flor, escala=(1, 1, 1.5), u=10, v=6, linea=0.015)
esfera("mata", 0.3, (4.6, 1.2, 0.55), m_hojas[1], escala=(1.1, 1.1, 0.7), u=12, v=8, linea=0.02)

# ----------------------------------------------------------------------------- la nave-estrella (nave_comun.py)
# raiz: posición, giro sobre la vertical y rebote. nave: cabeceo (de cola → acostada).
N = construir_nave(completa=COMPLETA)
raiz, nave, encendido, m_fuego = N.raiz, N.nave, N.encendido.node, N.m_fuego

# --- llamas de dibujo animado: tres franjas planas de color
m_llama = bpy.data.materials.new("llama")
m_llama.use_nodes = True
m_llama.surface_render_method = "BLENDED"
nt = m_llama.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
coord = nt.nodes.new("ShaderNodeTexCoord")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
r_col = nt.nodes.new("ShaderNodeValToRGB")
r_col.color_ramp.interpolation = "CONSTANT"
r_col.color_ramp.elements[0].color = lin("#FF8A3C")
r_col.color_ramp.elements[1].position, r_col.color_ramp.elements[1].color = 0.84, lin("#FFF6C8")
r_col.color_ramp.elements.new(0.50).color = lin("#FFC94A")
r_alf = nt.nodes.new("ShaderNodeValToRGB")
r_alf.color_ramp.elements[0].position = 0.0
r_alf.color_ramp.elements[1].position = 0.12
emi = nt.nodes.new("ShaderNodeEmission")
emi.inputs["Strength"].default_value = 1.4
tra = nt.nodes.new("ShaderNodeBsdfTransparent")
mez = nt.nodes.new("ShaderNodeMixShader")
nt.links.new(coord.outputs["Generated"], sep.inputs[0])
nt.links.new(sep.outputs["Z"], r_col.inputs[0])
nt.links.new(sep.outputs["Z"], r_alf.inputs[0])
nt.links.new(r_col.outputs[0], emi.inputs["Color"])
nt.links.new(r_alf.outputs[0], mez.inputs[0])
nt.links.new(tra.outputs[0], mez.inputs[1])
nt.links.new(emi.outputs[0], mez.inputs[2])
nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])


def llama(y, z, radio, largo_base):
    # gota: punta abajo (lejos de la tobera), panza cerca de la boca
    me = malla_bm("llama", lambda bm: bmesh.ops.create_cone(
        bm, cap_ends=False, segments=20, radius1=0.0, radius2=radio, depth=1.0,
        matrix=Matrix.Translation((0, 0, -0.5))))
    o = objeto("llama", me, m_llama, nave, sombra=False)
    o.location = (-1.92, y, z)
    o.rotation_euler = (0, math.pi / 2, 0)   # su -Z local apunta hacia -X de la nave (atrás)
    for f, largo, ancho in ((1, 1.6, 1.0), (F_FRENADO, 1.8, 1.0), (F_FRENADO + 20, 2.9, 1.08),
                            (F_VUELCO, 1.5, 1.0), (F_VUELCO + 9, 0.0, 0.3)):
        clave(o, "scale", f, (ancho, ancho, largo * largo_base))
    ruido(o, "scale", 2, 0.35 * largo_base, 1.6, F_VUELCO + 4)
    ruido(o, "scale", 0, 0.12, 1.3, F_VUELCO + 4)
    clave(o, "hide_render", F_VUELCO + 9, False)
    clave(o, "hide_render", F_VUELCO + 10, True)


for y, z in TOBERAS:
    llama(y, z, 0.25, 1.0)

luz_llama = bpy.data.lights.new("luz_llama", "POINT")
luz_llama.color = (1.0, 0.6, 0.25)
luz_llama.shadow_soft_size = 0.6
luz_llama.use_shadow = False
o_luz_llama = bpy.data.objects.new("luz_llama", luz_llama)
COL.objects.link(o_luz_llama)
o_luz_llama.parent = nave
o_luz_llama.location = (-2.3, 0, 0)
for f, e in ((1, 300), (F_FRENADO, 300), (F_FRENADO + 20, 900), (F_VUELCO, 600), (F_VUELCO + 10, 0)):
    clave(luz_llama, "energy", f, e)
ruido(luz_llama, "energy", 0, 120, 1.5, F_VUELCO + 4)

# al quedar acostada: la cúpula se enciende tibia y las toberas laten ("¡llegamos!")
for f, v in ((1, 0.0), (F_TOQUE + 16, 0.0), (F_TOQUE + 36, 1.0), (F_TOQUE + 52, 0.7), (F_FIN, 0.9)):
    clave_nodo(encendido.outputs[0], f, v)
fuerza_tobera = m_fuego.node_tree.nodes["Emission"].inputs["Strength"]
for f, e in ((1, 2.2), (F_VUELCO, 2.2), (F_VUELCO + 12, 0.8), (F_TOQUE + 16, 0.8), (F_TOQUE + 30, 2.4),
             (F_TOQUE + 46, 1.1), (F_TOQUE + 62, 2.0), (F_FIN, 1.4)):
    clave_nodo(fuerza_tobera, f, e)

# --- animación: baja de cola girando, frena, se acuesta y rebota blandito
Z_FLOTA = 3.0
for f, z in ((1, 52.0), (36, 38.0), (F_FRENADO, 9.5), (F_VUELCO, Z_FLOTA), (F_TOQUE, R_NAVE - 0.04),
             (F_TOQUE + 7, R_NAVE + 0.20), (F_TOQUE + 14, R_NAVE - 0.04), (F_FIN, R_NAVE - 0.04)):
    clave(raiz, "location", f, (NX, 0, z))
for f, giro in ((1, -2.6), (F_VUELCO - 6, 0.0), (F_FIN, 0.0)):
    clave(raiz, "rotation_euler", f, (0, 0, giro))
ruido(raiz, "location", 0, 0.10, 22, F_VUELCO - 4)
for f, s in ((F_TOQUE - 1, (1, 1, 1)), (F_TOQUE + 3, (1.07, 1.07, 0.84)), (F_TOQUE + 8, (0.96, 0.96, 1.07)),
             (F_TOQUE + 14, (1.03, 1.03, 0.95)), (F_TOQUE + 20, (1, 1, 1))):
    clave(raiz, "scale", f, s)
VERTICAL = -math.pi / 2  # nariz arriba, toberas abajo
for f, cab in ((1, VERTICAL), (F_VUELCO, VERTICAL), (F_TOQUE - 2, 0.0), (F_TOQUE + 6, 0.07),
               (F_TOQUE + 14, -0.03), (F_TOQUE + 22, 0.0), (F_FIN, 0.0)):
    clave(nave, "rotation_euler", f, (0, cab, 0))
ruido(nave, "rotation_euler", 0, 0.04, 14, F_VUELCO - 4)
ruido(nave, "rotation_euler", 1, 0.04, 17, F_VUELCO - 4)

# ----------------------------------------------------------------------------- polvo y resplandor del suelo
m_polvo = bpy.data.materials.new("polvo")
m_polvo.use_nodes = True
m_polvo.surface_render_method = "BLENDED"
nt = m_polvo.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
info = nt.nodes.new("ShaderNodeObjectInfo")
emi = nt.nodes.new("ShaderNodeEmission")
emi.inputs["Color"].default_value = lin("#FFF0D8")
tra = nt.nodes.new("ShaderNodeBsdfTransparent")
mez = nt.nodes.new("ShaderNodeMixShader")
nt.links.new(info.outputs["Alpha"], mez.inputs[0])
nt.links.new(tra.outputs[0], mez.inputs[1])
nt.links.new(emi.outputs[0], mez.inputs[2])
nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
for k in range(18):
    a = 2 * math.pi * k / 18 + random.uniform(-0.15, 0.15)
    o = esfera("polvo", 0.3, (0, 0, 0), m_polvo, u=14, v=8, sombra=False)
    f0 = F_FRENADO + 14 + random.randint(0, 10)
    alcance = random.uniform(3.0, 4.4)
    for f, d, z, s, al in ((f0, 0.4, 0.05, 0.3, 0.0), (f0 + 10, 1.3, 0.2, 1.0, 0.55),
                           (F_TOQUE + 2, alcance * 0.6, 0.3, 1.3, 0.35),
                           (F_TOQUE + 10, alcance * 0.85, 0.4, 1.8, 0.6),
                           (F_TOQUE + 48, alcance, 0.65, 2.3, 0.0)):
        clave(o, "location", f, (NX + math.cos(a) * d * 1.25, math.sin(a) * d * 0.8, z))
        clave(o, "scale", f, (s * 0.8, s * 0.8, s * 0.5))
        clave(o, "color", f, (1, 1, 1, al))

m_res = bpy.data.materials.new("resplandor")
m_res.use_nodes = True
m_res.surface_render_method = "BLENDED"
nt = m_res.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
coord = nt.nodes.new("ShaderNodeTexCoord")
largo = nt.nodes.new("ShaderNodeVectorMath")
largo.operation = "LENGTH"
r_alf = nt.nodes.new("ShaderNodeValToRGB")
r_alf.color_ramp.interpolation = "CONSTANT"
r_alf.color_ramp.elements[0].color = (0.85, 0.85, 0.85, 1)
r_alf.color_ramp.elements[1].position, r_alf.color_ramp.elements[1].color = 0.97, (0, 0, 0, 1)
r_alf.color_ramp.elements.new(0.55).color = (0.4, 0.4, 0.4, 1)
info = nt.nodes.new("ShaderNodeObjectInfo")
mult = nt.nodes.new("ShaderNodeMath")
mult.operation = "MULTIPLY"
emi = nt.nodes.new("ShaderNodeEmission")
emi.inputs["Color"].default_value = lin("#FFD27A")
emi.inputs["Strength"].default_value = 1.1
tra = nt.nodes.new("ShaderNodeBsdfTransparent")
mez = nt.nodes.new("ShaderNodeMixShader")
nt.links.new(coord.outputs["Object"], largo.inputs[0])
nt.links.new(largo.outputs["Value"], r_alf.inputs[0])
nt.links.new(r_alf.outputs[0], mult.inputs[0])
nt.links.new(info.outputs["Alpha"], mult.inputs[1])
nt.links.new(mult.outputs[0], mez.inputs[0])
nt.links.new(tra.outputs[0], mez.inputs[1])
nt.links.new(emi.outputs[0], mez.inputs[2])
nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
res = objeto("resplandor", malla_bm("resplandor", lambda bm: bmesh.ops.create_circle(
    bm, cap_ends=True, cap_tris=True, segments=40, radius=1.0)), m_res, sombra=False)
res.location = (NX, 0, 0.03)
for f, s, al in ((F_FRENADO, 0.6, 0.0), (F_FRENADO + 20, 1.8, 0.7), (F_VUELCO, 2.8, 1.0), (F_VUELCO + 12, 3.2, 0.0)):
    clave(res, "scale", f, (s, s, 1))
    clave(res, "color", f, (1, 1, 1, al))

# ----------------------------------------------------------------------------- luces
# En este look la luz no colorea: solo decide dónde cae la sombra pintada.
sol = bpy.data.lights.new("sol", "SUN")
sol.energy, sol.color, sol.angle = 1.6, (1.0, 1.0, 1.0), 0.02
o_sol = bpy.data.objects.new("sol", sol)
COL.objects.link(o_sol)
apuntar(o_sol, (0.62, 0.50, -0.60))  # desde arriba a la izquierda, del lado de la cámara

# ----------------------------------------------------------------------------- cámara
cam = bpy.data.cameras.new("camara")
cam.lens, cam.clip_end = 30, 800
o_cam = bpy.data.objects.new("camara", cam)
COL.objects.link(o_cam)
ESC.camera = o_cam
mira = bpy.data.objects.new("mira", None)
COL.objects.link(mira)
seguir = o_cam.constraints.new("TRACK_TO")
seguir.target, seguir.track_axis, seguir.up_axis = mira, "TRACK_NEGATIVE_Z", "UP_Y"

for f, p in ((1, tuple(CAM_INICIO)), (F_TOQUE, (-3.2, -9.8, 1.35)), (F_FIN, (-4.2, -8.4, 1.5))):
    clave(o_cam, "location", f, p)
for f, p in ((1, (NX + 0.2, 0, 24.0)), (30, (NX + 0.2, 0, 23.0)), (F_FRENADO, (NX + 0.6, 0, 9.6)),
             (F_VUELCO, (NX + 1.2, 0, 3.3)), (F_TOQUE, (NX + 1.7, 0, 2.0)), (F_FIN, (NX + 1.5, 0, 1.9))):
    clave(mira, "location", f, p)
for f, lente in ((1, 30), (F_TOQUE, 30), (F_FIN, 32)):
    clave(cam, "lens", f, lente)

# ----------------------------------------------------------------------------- compositor: pincel + brillo
try:
    ESC.use_nodes = True
    nt = ESC.node_tree
    capas = nt.nodes["Render Layers"]
    comp = nt.nodes["Composite"]
    imagen = capas.outputs["Image"]
    if not arg("--sin-pincel"):
        pincel = nt.nodes.new("CompositorNodeKuwahara")   # aplana el color en manchas, como témpera
        pincel.variation = "ANISOTROPIC"
        tam = float(arg("--pincel", 3))
        if "Size" in pincel.inputs:
            pincel.inputs["Size"].default_value = tam
        else:
            pincel.size = int(tam)
        nt.links.new(imagen, pincel.inputs["Image"])
        imagen = pincel.outputs["Image"]
    brillo = nt.nodes.new("CompositorNodeGlare")
    brillo.glare_type = "BLOOM"
    for nombre, valor in (("Threshold", 1.0), ("Strength", 0.3), ("Size", 0.4)):
        if nombre in brillo.inputs:
            brillo.inputs[nombre].default_value = valor
    nt.links.new(imagen, brillo.inputs["Image"])
    nt.links.new(brillo.outputs["Image"], comp.inputs["Image"])
except Exception as e:  # son adornos: si la API cambió, se sigue sin ellos
    print("AVISO: compositor sin efectos:", e)
    ESC.use_nodes = False

# ----------------------------------------------------------------------------- salidas
if arg("--blend"):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SALIDA, NOMBRE + ".blend"))
    print("GUARDADO", os.path.join(SALIDA, NOMBRE + ".blend"))

if arg("--fotos"):
    ESC.render.image_settings.file_format = "PNG"
    for f in (int(x) for x in str(arg("--fotos")).split(",")):
        ESC.frame_set(f)
        ESC.render.filepath = os.path.join(SALIDA, f"{NOMBRE}_foto_{f:04d}.png")
        bpy.ops.render.render(write_still=True)
        print("FOTO", ESC.render.filepath)

if arg("--video"):
    ESC.render.image_settings.file_format = "FFMPEG"
    ESC.render.ffmpeg.format = "MPEG4"
    ESC.render.ffmpeg.codec = "H264"
    ESC.render.ffmpeg.constant_rate_factor = "HIGH"
    ESC.render.ffmpeg.gopsize = 12
    ESC.render.use_file_extension = False
    ESC.render.filepath = os.path.join(SALIDA, NOMBRE + ".mp4")
    bpy.ops.render.render(animation=True)
    print("VIDEO", ESC.render.filepath)
