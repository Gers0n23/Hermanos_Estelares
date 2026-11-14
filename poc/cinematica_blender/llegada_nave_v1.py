"""POC: cinemática 3D en Blender — la nave-estrella básica llega al patio (intro, plano 07).

Todo se construye por código (sin modelar a mano): escenario, nave, luces, cámara y animación.
Respeta la puesta en escena aprobada del plano 07 (docs/cinematicas/escena_intro.md): nave
vertical, sin alas, cúpula arriba y propulsores abajo, descenso propulsado con quema de frenado
y aterrizaje suave en el patio al atardecer, junto a la ventana del living.

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P llegada_nave.py -- --fotos 1,80,150,170,252   # cuadros sueltos de revisión
  blender -b -P llegada_nave.py -- --video                    # mp4 completo
  blender -b -P llegada_nave.py -- --blend                    # guarda el .blend para abrirlo
Opciones: --salida CARPETA, --escala 50 (porcentaje de 1280x720), --muestras 32
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

# ----------------------------------------------------------------------------- argumentos
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(nombre, defecto=None):
    if nombre in ARGS:
        i = ARGS.index(nombre)
        return ARGS[i + 1] if i + 1 < len(ARGS) and not ARGS[i + 1].startswith("--") else True
    return defecto


AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.abspath(arg("--salida", os.path.join(AQUI, "salida")))
os.makedirs(SALIDA, exist_ok=True)
random.seed(7)

# ----------------------------------------------------------------------------- línea de tiempo
FPS = 24
F_FRENADO = 110      # empieza la quema de frenado
F_TOQUE = 165        # la nave toca el pasto
F_FIN = 252          # 10,5 s
NX = -2.2            # x del punto de aterrizaje (lejos del alero: la cúpula queda contra el cielo)

# ----------------------------------------------------------------------------- utilidades
bpy.ops.wm.read_factory_settings(use_empty=True)
ESC = bpy.context.scene
COL = ESC.collection


def lin(hexa, a=1.0):
    """Color sRGB '#RRGGBB' a lineal RGBA (lo que espera Blender)."""
    hexa = hexa.lstrip("#")
    canales = []
    for i in (0, 2, 4):
        c = int(hexa[i:i + 2], 16) / 255
        canales.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*canales, a)


def material(nombre, color, rugosidad=0.75, metal=0.0, emision=None, fuerza=0.0, alfa=1.0):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = lin(color)
    p.inputs["Roughness"].default_value = rugosidad
    p.inputs["Metallic"].default_value = metal
    p.inputs["Specular IOR Level"].default_value = 0.25
    if emision:
        p.inputs["Emission Color"].default_value = lin(emision)
        p.inputs["Emission Strength"].default_value = fuerza
    if alfa < 1.0:
        p.inputs["Alpha"].default_value = alfa
        m.surface_render_method = "BLENDED"
    return m


def objeto(nombre, malla, mat=None, padre=None, suave=True, sombra=True):
    if suave:
        malla.polygons.foreach_set("use_smooth", [True] * len(malla.polygons))
    o = bpy.data.objects.new(nombre, malla)
    COL.objects.link(o)
    if mat:
        malla.materials.append(mat)
    if padre:
        o.parent = padre
    o.visible_shadow = sombra
    return o


def malla_bm(nombre, constructor):
    bm = bmesh.new()
    constructor(bm)
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    return me


def caja(nombre, minimo, maximo, mat, padre=None):
    mn, mx = Vector(minimo), Vector(maximo)
    mtx = Matrix.Translation((mn + mx) / 2) @ Matrix.Diagonal((*(mx - mn), 1.0))
    me = malla_bm(nombre, lambda bm: bmesh.ops.create_cube(bm, size=1.0, matrix=mtx))
    return objeto(nombre, me, mat, padre, suave=False)


def esfera(nombre, radio, pos, mat, escala=(1, 1, 1), padre=None, u=24, v=14, sombra=True):
    me = malla_bm(nombre, lambda bm: bmesh.ops.create_uvsphere(
        bm, u_segments=u, v_segments=v, radius=radio))
    o = objeto(nombre, me, mat, padre, sombra=sombra)
    o.location, o.scale = pos, escala
    return o


def cilindro(nombre, radio, alto, pos, mat, padre=None, radio2=None, seg=20):
    mtx = Matrix.Translation((0, 0, alto / 2))
    me = malla_bm(nombre, lambda bm: bmesh.ops.create_cone(
        bm, cap_ends=True, segments=seg, radius1=radio,
        radius2=radio if radio2 is None else radio2, depth=alto, matrix=mtx))
    o = objeto(nombre, me, mat, padre)
    o.location = pos
    return o


def torno(nombre, perfil, mat, padre=None, seg=48, subdiv=0):
    """Sólido de revolución a partir de un perfil [(radio, z), ...] de abajo hacia arriba."""
    verts, caras = [], []
    for r, z in perfil:
        for s in range(seg):
            a = 2 * math.pi * s / seg
            verts.append((r * math.cos(a), r * math.sin(a), z))
    for i in range(len(perfil) - 1):
        for s in range(seg):
            s2 = (s + 1) % seg
            caras.append((i * seg + s, i * seg + s2, (i + 1) * seg + s2, (i + 1) * seg + s))
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], caras)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(me)
    bm.free()
    o = objeto(nombre, me, mat, padre)
    if subdiv:
        o.modifiers.new("suavizado", "SUBSURF").levels = subdiv
        o.modifiers["suavizado"].render_levels = subdiv
    return o


def clave(dato, prop, cuadro, valor=None, indice=-1):
    if valor is not None:
        setattr(dato, prop, valor)
    dato.keyframe_insert(prop, frame=cuadro, index=indice)


def curva(obj, ruta, indice=0):
    return obj.animation_data.action.fcurves.find(ruta, index=indice)


def ruido(obj, ruta, indice, fuerza, escala, hasta):
    fc = curva(obj, ruta, indice)
    m = fc.modifiers.new("NOISE")
    m.strength, m.scale, m.phase = fuerza, escala, random.uniform(0, 100)
    m.use_restricted_range = True
    m.frame_start, m.frame_end, m.blend_out = 1, hasta, 8


def apuntar(obj, direccion):
    obj.rotation_euler = Vector(direccion).to_track_quat("-Z", "Y").to_euler()


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
paradas = [(0.0, "#F4A777"), (0.12, "#EE8F92"), (0.38, "#9670AC"), (1.0, "#33346B")]
rampa.color_ramp.elements[0].position, rampa.color_ramp.elements[0].color = 0.0, lin(paradas[0][1])
rampa.color_ramp.elements[1].position, rampa.color_ramp.elements[1].color = 1.0, lin(paradas[3][1])
for pos, col in paradas[1:3]:
    rampa.color_ramp.elements.new(pos).color = lin(col)
fondo.inputs["Strength"].default_value = 0.85

# estrellas (una sola malla)
m_estrella = material("estrella", "#FFF6D8", emision="#FFF2C4", fuerza=4.0)


def _estrellas(bm):
    for _ in range(170):
        az = random.uniform(-1.5, 1.5)
        el = random.uniform(0.38, 1.5)
        d = 260
        p = Vector((d * math.sin(az) * math.cos(el), d * math.cos(az) * math.cos(el), d * math.sin(el)))
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=random.uniform(0.18, 0.5),
                                   matrix=Matrix.Translation(p))


objeto("estrellas", malla_bm("estrellas", _estrellas), m_estrella, sombra=False)

# nubes pintadas: panza cálida por el sol bajo, lomo morado
m_nube = bpy.data.materials.new("nube")
m_nube.use_nodes = True
nt = m_nube.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
geo = nt.nodes.new("ShaderNodeNewGeometry")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
rango = nt.nodes.new("ShaderNodeMapRange")
rampa = nt.nodes.new("ShaderNodeValToRGB")
emi = nt.nodes.new("ShaderNodeEmission")
rango.inputs["From Min"].default_value = -1.0
rampa.color_ramp.elements[0].color = lin("#F7B08C")
rampa.color_ramp.elements[1].color = lin("#8A6FA6")
nt.links.new(geo.outputs["Normal"], sep.inputs[0])
nt.links.new(sep.outputs["Z"], rango.inputs["Value"])
nt.links.new(rango.outputs[0], rampa.inputs[0])
nt.links.new(rampa.outputs[0], emi.inputs["Color"])
nt.links.new(emi.outputs[0], nt.nodes["Material Output"].inputs["Surface"])


def _nubes(bm):
    for _ in range(26):
        az = random.uniform(-1.35, 1.35)
        el = random.uniform(0.07, 1.0) ** 1.4
        d = 170
        c = Vector((d * math.sin(az) * math.cos(el), d * math.cos(az) * math.cos(el), d * math.sin(el)))
        lado = Vector((math.cos(az), -math.sin(az), 0))
        tam = random.uniform(5, 11) * (1.0 - 0.35 * el)
        n_bolas = random.randint(5, 8)
        for k in range(n_bolas):
            t = (k - (n_bolas - 1) / 2) / (n_bolas / 2)
            p = c + lado * t * tam * 2.6 + Vector((0, 0, (1 - abs(t)) * random.uniform(0.1, 0.6) * tam))
            r = tam * (1.25 - 0.6 * abs(t)) * random.uniform(0.85, 1.15)
            bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=r,
                                      matrix=Matrix.Translation(p) @ Matrix.Diagonal((1.3, 1.3, 0.5, 1)))


objeto("nubes", malla_bm("nubes", _nubes), m_nube, sombra=False)

# ----------------------------------------------------------------------------- patio
m_pasto = material("pasto", "#3E6B3C", rugosidad=0.95)
caja("suelo", (-150, -60, -1), (150, 150, 0), m_pasto)

# briznas de pasto (una malla, color por vértice: base oscura, punta clara)
m_brizna = bpy.data.materials.new("brizna")
m_brizna.use_nodes = True
nt = m_brizna.node_tree
atr = nt.nodes.new("ShaderNodeAttribute")
atr.attribute_name = "col"
nt.links.new(atr.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
m_brizna.use_backface_culling = False

verts, caras, colores = [], [], []
base_c, punta_c = lin("#2F5A33"), lin("#6FA24E")
for _ in range(9000):
    x, y = random.uniform(-16, 12), random.uniform(-10.5, 6.8)
    if x > 3.0 and y > 1.8:
        continue
    alto = random.uniform(0.10, 0.26)
    ang = random.uniform(0, math.pi)
    dx, dy = math.cos(ang) * 0.03, math.sin(ang) * 0.03
    lx, ly = random.uniform(-0.06, 0.06), random.uniform(-0.06, 0.06)
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
m_madera = material("madera", "#8B5E3F", rugosidad=0.85)
for i in range(13):
    x = -21 + i * 2.0
    caja(f"poste{i}", (x - 0.08, 6.92, 0), (x + 0.08, 7.08, 1.15), m_madera)
for z in (0.45, 0.9):
    caja("riel", (-21, 6.97, z - 0.07), (3.2, 7.03, z + 0.07), m_madera)

# árboles y arbustos
m_tronco = material("tronco", "#5C4033")
m_hojas = [material("hojas1", "#2E5B3B", rugosidad=0.9), material("hojas2", "#3B7045", rugosidad=0.9)]


def arbol(x, y, alto, copa):
    cilindro("tronco", 0.22 * copa, alto, (x, y, 0), m_tronco, radio2=0.15 * copa)
    for k in range(5):
        p = (x + random.uniform(-0.9, 0.9) * copa, y + random.uniform(-0.6, 0.6) * copa,
             alto + random.uniform(-0.2, 1.0) * copa)
        esfera("copa", random.uniform(0.9, 1.4) * copa, p, m_hojas[k % 2], u=16, v=10)


arbol(-6.5, 9.5, 2.2, 1.3)
arbol(-12.5, 12.0, 2.8, 1.6)
arbol(-17.0, 10.0, 2.0, 1.2)
for x in (-9.5, -3.8, -1.5, 1.6):
    esfera("arbusto", random.uniform(0.5, 0.8), (x, 7.6, 0.25), m_hojas[1], escala=(1.4, 1, 0.9), u=16, v=10)

# cerros lejanos
m_cerro = material("cerro", "#55507F", rugosidad=1.0)
for x, y, sx, sz in ((-55, 95, 45, 11), (-5, 120, 60, 15), (60, 100, 50, 12), (-110, 110, 50, 9)):
    esfera("cerro", 1.0, (x, y, -1.5), m_cerro, escala=(sx, 22, sz))

# ----------------------------------------------------------------------------- la casa
m_muro = material("muro", "#C2A88F", rugosidad=0.9)
m_zocalo = material("zocalo", "#8E7868", rugosidad=0.9)
m_techo = material("techo", "#5E4747", rugosidad=0.8)
m_marco = material("marco", "#EFE3CF", rugosidad=0.6)
m_vidrio = material("vidrio_ventana", "#FFD98A", emision="#FFC873", fuerza=1.25)
m_cortina = material("cortina", "#FFF1D2", emision="#FFE2AE", fuerza=0.9)

caja("casa", (3.2, 2.0, 0), (13, 6.5, 5.2), m_muro)  # poco profunda: su techo no debe verse tras la cúpula
caja("zocalo", (3.15, 1.95, 0), (13, 6.5, 0.35), m_zocalo)
caja("alero", (2.6, 1.4, 5.2), (13.6, 7.1, 5.5), m_techo)
caja("techo", (3.0, 1.8, 5.5), (13.2, 6.7, 6.3), m_techo)
VX, VZ, VA, VH = 6.4, 2.55, 2.5, 2.0  # centro x, centro z, ancho, alto de la ventana del living
caja("vidrio", (VX - VA / 2, 1.96, VZ - VH / 2), (VX + VA / 2, 1.99, VZ + VH / 2), m_vidrio)
for dx in (-1, 1):  # cortinas recogidas a los lados
    caja("cortina", (VX + dx * VA / 2 - (0.55 if dx > 0 else 0), 1.94, VZ - VH / 2),
         (VX + dx * VA / 2 + (0.55 if dx < 0 else 0), 1.96, VZ + VH / 2), m_cortina)
g = 0.09
caja("marco_izq", (VX - VA / 2 - g, 1.86, VZ - VH / 2 - g), (VX - VA / 2, 2.0, VZ + VH / 2 + g), m_marco)
caja("marco_der", (VX + VA / 2, 1.86, VZ - VH / 2 - g), (VX + VA / 2 + g, 2.0, VZ + VH / 2 + g), m_marco)
caja("marco_sup", (VX - VA / 2 - g, 1.86, VZ + VH / 2), (VX + VA / 2 + g, 2.0, VZ + VH / 2 + g), m_marco)
caja("marco_inf", (VX - VA / 2 - 0.2, 1.74, VZ - VH / 2 - 0.12), (VX + VA / 2 + 0.2, 2.0, VZ - VH / 2), m_marco)
caja("cruz_v", (VX - 0.035, 1.9, VZ - VH / 2), (VX + 0.035, 1.97, VZ + VH / 2), m_marco)
caja("cruz_h", (VX - VA / 2, 1.9, VZ - 0.035), (VX + VA / 2, 1.97, VZ + 0.035), m_marco)

# macetero con flores bajo la ventana
m_maceta = material("maceta", "#B5533C")
m_flor = material("flor", "#E86FA0", emision="#E86FA0", fuerza=0.25)
cilindro("maceta", 0.24, 0.45, (4.6, 1.2, 0), m_maceta, radio2=0.32)
for k in range(6):
    a = k * 1.05
    p = (4.6 + math.cos(a) * 0.2, 1.2 + math.sin(a) * 0.2, 0.75 + (k % 3) * 0.22)
    cilindro("tallo", 0.015, p[2] - 0.4, (p[0], p[1], 0.4), m_hojas[1], seg=6)
    esfera("flor", 0.085, p, m_flor, escala=(1, 1, 1.5), u=10, v=6)
esfera("mata", 0.3, (4.6, 1.2, 0.55), m_hojas[1], escala=(1.1, 1.1, 0.7), u=12, v=8)

# ----------------------------------------------------------------------------- la nave-estrella básica
nave = bpy.data.objects.new("nave", None)
COL.objects.link(nave)

m_casco = material("casco", "#45B5A6", rugosidad=0.45)
m_panel = material("panel", "#DCD5C5", rugosidad=0.5)
m_collar = material("collar", "#3F5F78", rugosidad=0.4, metal=0.3)
m_aro = material("aro", "#D8C6A4", rugosidad=0.35, metal=0.4)
m_tobera = material("tobera", "#BDB6CF", rugosidad=0.35, metal=0.5)
m_luz = material("luz_collar", "#7CEFF0", emision="#6FE8EA", fuerza=2.0)
m_curita = material("curita", "#E3AA3E", rugosidad=0.7)
m_parche_a = material("parche_morado", "#9A62B6", rugosidad=0.8)
m_parche_b = material("parche_rosa", "#D76D9C", rugosidad=0.8)
m_cupula = bpy.data.materials.new("cupula")
m_cupula.use_nodes = True
m_cupula.surface_render_method = "BLENDED"
nt = m_cupula.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
borde = nt.nodes.new("ShaderNodeLayerWeight")
borde.inputs["Blend"].default_value = 0.35
r_bor = nt.nodes.new("ShaderNodeValToRGB")
r_bor.color_ramp.elements[0].color = (0.06, 0.06, 0.06, 1)
r_bor.color_ramp.elements[1].color = (0.45, 0.45, 0.45, 1)
tra = nt.nodes.new("ShaderNodeBsdfTransparent")
bri = nt.nodes.new("ShaderNodeEmission")
bri.inputs["Color"].default_value = lin("#DDF3FF")
bri.inputs["Strength"].default_value = 0.9
mez = nt.nodes.new("ShaderNodeMixShader")
nt.links.new(borde.outputs["Facing"], r_bor.inputs[0])
nt.links.new(r_bor.outputs[0], mez.inputs[0])
nt.links.new(tra.outputs[0], mez.inputs[1])
nt.links.new(bri.outputs[0], mez.inputs[2])
nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])

casco = torno("casco", [(0, 0.30), (0.36, 0.31), (0.70, 0.52), (0.93, 0.92), (1.06, 1.45),
                        (1.10, 2.0), (1.06, 2.36), (0, 2.36)], m_casco, nave, subdiv=2)
torno("collar", [(1.0, 2.24), (1.17, 2.27), (1.19, 2.45), (1.16, 2.62), (1.0, 2.67), (0.9, 2.67)],
      m_collar, nave, subdiv=1)
torno("aro", [(0.9, 2.64), (0.99, 2.65), (0.99, 2.74), (0.9, 2.77), (0, 2.77)], m_aro, nave)
cupula = esfera("cupula", 0.9, (0, 0, 2.72), m_cupula, escala=(1, 1, 1.18), padre=nave, u=32, v=20, sombra=False)
for k in range(14):
    a = 2 * math.pi * k / 14
    esfera("luz", 0.05, (1.19 * math.cos(a), 1.19 * math.sin(a), 2.45), m_luz, padre=nave, u=10, v=6, sombra=False)

TOBERAS = [(0.37 * math.cos(a), 0.37 * math.sin(a)) for a in (math.radians(g) for g in (90, 210, 330))]
for x, y in TOBERAS:
    t = torno("tobera", [(0, 0.25), (0.13, 0.25), (0.21, 0.0), (0.25, 0.0), (0.16, 0.40), (0, 0.40)],
              m_tobera, nave, seg=28)
    t.location = (x, y, 0)


def parche(nombre, ancho, alto, mat, angulo, z, giro=0.0, elipse=False, n=10):
    """Calcomanía que se adhiere al casco curvo (shrinkwrap). angulo=0 es el frente (hacia cámara)."""
    verts, caras = [], []
    for j in range(n + 1):
        for i in range(n + 1):
            u, v = i / n * 2 - 1, j / n * 2 - 1
            if elipse:
                u, v = u * math.sqrt(1 - v * v / 2), v * math.sqrt(1 - u * u / 2)
            px, pz = u * ancho / 2, v * alto / 2
            verts.append((px * math.cos(giro) - pz * math.sin(giro), 0,
                          px * math.sin(giro) + pz * math.cos(giro)))
    for j in range(n):
        for i in range(n):
            a = j * (n + 1) + i
            caras.append((a, a + 1, a + n + 2, a + n + 1))
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], caras)
    o = objeto(nombre, me, mat, nave, sombra=False)
    o.location = (1.7 * math.sin(angulo), -1.7 * math.cos(angulo), z)
    o.rotation_euler = (0, 0, angulo)
    sw = o.modifiers.new("pegar", "SHRINKWRAP")
    sw.target, sw.wrap_method = casco, "PROJECT"
    sw.use_project_x, sw.use_project_y, sw.use_project_z = False, True, False
    sw.use_positive_direction, sw.use_negative_direction = True, False
    sw.offset = 0.008
    so = o.modifiers.new("grosor", "SOLIDIFY")
    so.thickness, so.offset = 0.022, 1.0
    return o


parche("panel_frente", 1.0, 1.15, m_panel, 0.0, 1.38, elipse=True, n=16)
for giro in (0.6, 0.6 + math.pi / 2):                            # curita en X arriba a la izquierda
    parche("curita", 0.50, 0.13, m_curita, -0.62, 1.95, giro=giro)
for giro in (0.75, 0.75 + math.pi / 2):                          # curita en X abajo a la derecha
    parche("curita", 0.46, 0.12, m_curita, 0.72, 1.45, giro=giro)
parche("parche", 0.24, 0.24, m_parche_a, 0.80, 2.0, giro=0.15)
parche("parche", 0.20, 0.20, m_parche_b, 1.02, 1.93, giro=-0.2)
parche("parche", 0.26, 0.22, m_parche_b, -1.15, 1.35, giro=0.3)
parche("parche", 0.22, 0.24, m_parche_a, 2.4, 1.7, giro=0.1)
for giro in (0.4, 0.4 + math.pi / 2):
    parche("curita", 0.46, 0.12, m_curita, 3.4, 1.6, giro=giro)

# --- llamas de los propulsores
m_llama = bpy.data.materials.new("llama")
m_llama.use_nodes = True
m_llama.surface_render_method = "BLENDED"
nt = m_llama.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
coord = nt.nodes.new("ShaderNodeTexCoord")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
r_col = nt.nodes.new("ShaderNodeValToRGB")
r_alf = nt.nodes.new("ShaderNodeValToRGB")
emi = nt.nodes.new("ShaderNodeEmission")
tra = nt.nodes.new("ShaderNodeBsdfTransparent")
mez = nt.nodes.new("ShaderNodeMixShader")
r_col.color_ramp.elements[0].color = lin("#FF5A1E")
r_col.color_ramp.elements[1].color = lin("#FFF3B8")
r_col.color_ramp.elements.new(0.55).color = lin("#FFB52E")
r_alf.color_ramp.elements[0].color = (0, 0, 0, 1)
r_alf.color_ramp.elements[1].position = 0.85
emi.inputs["Strength"].default_value = 1.7
nt.links.new(coord.outputs["Generated"], sep.inputs[0])
nt.links.new(sep.outputs["Z"], r_col.inputs[0])
nt.links.new(sep.outputs["Z"], r_alf.inputs[0])
nt.links.new(r_col.outputs[0], emi.inputs["Color"])
nt.links.new(r_alf.outputs[0], mez.inputs[0])
nt.links.new(tra.outputs[0], mez.inputs[1])
nt.links.new(emi.outputs[0], mez.inputs[2])
nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])


def llama(x, y, radio, largo_base):
    me = malla_bm("llama", lambda bm: bmesh.ops.create_cone(
        bm, cap_ends=False, segments=20, radius1=0.0, radius2=radio, depth=1.0,
        matrix=Matrix.Translation((0, 0, -0.5))))
    o = objeto("llama", me, m_llama, nave, sombra=False)
    o.location = (x, y, 0.06)
    for f, largo, ancho in ((1, 1.5, 1.0), (F_FRENADO, 1.7, 1.0), (F_FRENADO + 30, 2.6, 1.05),
                            (F_TOQUE, 1.8, 1.0), (F_TOQUE + 7, 0.0, 0.3)):
        clave(o, "scale", f, (ancho, ancho, largo * largo_base))
    ruido(o, "scale", 2, 0.35 * largo_base, 1.6, F_TOQUE + 2)
    ruido(o, "scale", 0, 0.12, 1.3, F_TOQUE + 2)
    clave(o, "hide_render", F_TOQUE + 7, False)
    clave(o, "hide_render", F_TOQUE + 8, True)


for x, y in TOBERAS:
    llama(x, y, 0.2, 1.0)
llama(0, 0, 0.30, 1.4)

luz_llama = bpy.data.lights.new("luz_llama", "POINT")
luz_llama.color = (1.0, 0.55, 0.2)
luz_llama.shadow_soft_size = 0.6
luz_llama.use_shadow = False
o_luz_llama = bpy.data.objects.new("luz_llama", luz_llama)
COL.objects.link(o_luz_llama)
o_luz_llama.parent = nave
o_luz_llama.location = (0, 0, 0.2)
for f, e in ((1, 500), (F_FRENADO, 500), (F_FRENADO + 30, 1500), (F_TOQUE, 1000), (F_TOQUE + 8, 0)):
    clave(luz_llama, "energy", f, e)
ruido(luz_llama, "energy", 0, 180, 1.5, F_TOQUE + 2)

# luz cálida dentro de la cúpula: se enciende al aterrizar ("¡llegamos!")
luz_cupula = bpy.data.lights.new("luz_cupula", "POINT")
luz_cupula.color = (1.0, 0.72, 0.62)
luz_cupula.shadow_soft_size = 0.3
luz_cupula.use_shadow = False
o_lc = bpy.data.objects.new("luz_cupula", luz_cupula)
COL.objects.link(o_lc)
o_lc.parent = nave
o_lc.location = (0, 0, 3.0)
for f, e in ((1, 0), (F_TOQUE + 18, 0), (F_TOQUE + 40, 70), (F_TOQUE + 55, 45), (F_FIN, 55)):
    clave(luz_cupula, "energy", f, e)
fuerza_luz = m_luz.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"]
for f, e in ((1, 2.0), (F_TOQUE + 18, 2.0), (F_TOQUE + 34, 9.0), (F_TOQUE + 50, 4.0),
             (F_TOQUE + 66, 8.0), (F_FIN, 5.0)):
    fuerza_luz.default_value = e
    fuerza_luz.keyframe_insert("default_value", frame=f)

# --- animación de la nave: descenso, frenado, toque con rebote blandito
for f, z in ((1, 50.0), (36, 36.0), (F_FRENADO, 7.0), (F_TOQUE, 0.0), (F_FIN, 0.0)):
    nave.location = (NX, 0, z)
    nave.keyframe_insert("location", frame=f)
for f, giro in ((1, -1.3), (F_TOQUE, 0.0), (F_FIN, 0.0)):
    nave.rotation_euler = (0, 0, giro)
    nave.keyframe_insert("rotation_euler", frame=f)
ruido(nave, "rotation_euler", 0, 0.035, 14, F_TOQUE - 6)
ruido(nave, "rotation_euler", 1, 0.035, 17, F_TOQUE - 6)
ruido(nave, "location", 0, 0.10, 22, F_TOQUE - 10)
for f, s in ((F_TOQUE - 1, (1, 1, 1)), (F_TOQUE + 4, (1.09, 1.09, 0.85)), (F_TOQUE + 10, (0.96, 0.96, 1.06)),
             (F_TOQUE + 16, (1.02, 1.02, 0.98)), (F_TOQUE + 22, (1, 1, 1))):
    clave(nave, "scale", f, s)

# ----------------------------------------------------------------------------- polvo y resplandor del suelo
m_polvo = bpy.data.materials.new("polvo")
m_polvo.use_nodes = True
m_polvo.surface_render_method = "BLENDED"
nt = m_polvo.node_tree
p = nt.nodes["Principled BSDF"]
p.inputs["Base Color"].default_value = lin("#F0DFC6")
p.inputs["Roughness"].default_value = 1.0
info = nt.nodes.new("ShaderNodeObjectInfo")
nt.links.new(info.outputs["Alpha"], p.inputs["Alpha"])
for k in range(16):
    a = 2 * math.pi * k / 16 + random.uniform(-0.15, 0.15)
    o = esfera("polvo", 0.3, (0, 0, 0), m_polvo, u=14, v=8, sombra=False)
    f0 = F_TOQUE - 16 + random.randint(0, 8)
    alcance = random.uniform(2.4, 3.6)
    for f, d, z, s, alfa in ((f0, 0.5, 0.05, 0.3, 0.0), (f0 + 10, 1.3, 0.2, 1.0, 0.55),
                             (F_TOQUE + 6, alcance * 0.75, 0.35, 1.5, 0.5),
                             (F_TOQUE + 45, alcance, 0.6, 2.1, 0.0)):
        clave(o, "location", f, (NX + math.cos(a) * d, math.sin(a) * d, z))
        clave(o, "scale", f, (s * 0.75, s * 0.75, s * 0.4))
        clave(o, "color", f, (1, 1, 1, alfa * 0.7))

m_res = bpy.data.materials.new("resplandor")
m_res.use_nodes = True
m_res.surface_render_method = "BLENDED"
nt = m_res.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
coord = nt.nodes.new("ShaderNodeTexCoord")
largo = nt.nodes.new("ShaderNodeVectorMath")
largo.operation = "LENGTH"
r_alf = nt.nodes.new("ShaderNodeValToRGB")
r_alf.color_ramp.elements[0].color = (1, 1, 1, 1)
r_alf.color_ramp.elements[1].color = (0, 0, 0, 1)
info = nt.nodes.new("ShaderNodeObjectInfo")
mult = nt.nodes.new("ShaderNodeMath")
mult.operation = "MULTIPLY"
emi = nt.nodes.new("ShaderNodeEmission")
emi.inputs["Color"].default_value = lin("#FFC257")
emi.inputs["Strength"].default_value = 1.2
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
for f, s, alfa in ((F_FRENADO, 0.6, 0.0), (F_FRENADO + 30, 1.6, 0.6), (F_TOQUE, 2.6, 1.0), (F_TOQUE + 12, 3.0, 0.0)):
    clave(res, "scale", f, (s, s, 1))
    clave(res, "color", f, (1, 1, 1, alfa))

# ----------------------------------------------------------------------------- luces del atardecer
sol = bpy.data.lights.new("sol", "SUN")
sol.energy, sol.color, sol.angle = 2.6, (1.0, 0.62, 0.45), 0.06
o_sol = bpy.data.objects.new("sol", sol)
COL.objects.link(o_sol)
apuntar(o_sol, (0.75, -0.45, -0.32))  # sol bajo, atrás a la izquierda: contraluz cálido

relleno = bpy.data.lights.new("relleno", "AREA")
relleno.energy, relleno.color, relleno.size = 900, (0.75, 0.7, 1.0), 8
o_rel = bpy.data.objects.new("relleno", relleno)
COL.objects.link(o_rel)
o_rel.location = (-7, -9, 5)
apuntar(o_rel, (7, 9, -3.5))

ventana = bpy.data.lights.new("luz_ventana", "AREA")
ventana.energy, ventana.color, ventana.size = 300, (1.0, 0.78, 0.45), 2.2
o_ven = bpy.data.objects.new("luz_ventana", ventana)
COL.objects.link(o_ven)
o_ven.location = (VX, 1.7, VZ)
apuntar(o_ven, (-0.25, -1, -0.45))

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

for f, p in ((1, (-3.0, -10.0, 1.3)), (F_TOQUE, (-3.2, -9.8, 1.35)), (F_FIN, (-4.2, -8.2, 1.55))):
    clave(o_cam, "location", f, p)
for f, p in ((1, (NX + 0.2, 0, 24.0)), (30, (NX + 0.2, 0, 23.0)), (F_FRENADO, (NX + 0.8, 0, 7.6)),
             (F_TOQUE, (NX + 2.2, 0, 2.0)), (F_FIN, (NX + 2.0, 0, 1.95))):
    clave(mira, "location", f, p)
for f, lente in ((1, 30), (F_TOQUE, 30), (F_FIN, 34)):
    clave(cam, "lens", f, lente)

# ----------------------------------------------------------------------------- brillo (compositor)
try:
    ESC.use_nodes = True
    nt = ESC.node_tree
    capas = nt.nodes["Render Layers"]
    comp = nt.nodes["Composite"]
    brillo = nt.nodes.new("CompositorNodeGlare")
    brillo.glare_type = "BLOOM"
    for nombre, valor in (("Threshold", 1.0), ("Strength", 0.35), ("Size", 0.4)):
        if nombre in brillo.inputs:
            brillo.inputs[nombre].default_value = valor
    nt.links.new(capas.outputs["Image"], brillo.inputs["Image"])
    nt.links.new(brillo.outputs["Image"], comp.inputs["Image"])
except Exception as e:  # el brillo es un adorno: si la API cambió, se sigue sin él
    print("AVISO: sin brillo de compositor:", e)
    ESC.use_nodes = False

# ----------------------------------------------------------------------------- salidas
if arg("--blend"):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SALIDA, "llegada_nave.blend"))
    print("GUARDADO", os.path.join(SALIDA, "llegada_nave.blend"))

if arg("--fotos"):
    ESC.render.image_settings.file_format = "PNG"
    for f in (int(x) for x in str(arg("--fotos")).split(",")):
        ESC.frame_set(f)
        ESC.render.filepath = os.path.join(SALIDA, f"foto_{f:04d}.png")
        bpy.ops.render.render(write_still=True)
        print("FOTO", ESC.render.filepath)

if arg("--video"):
    ESC.render.image_settings.file_format = "FFMPEG"
    ESC.render.ffmpeg.format = "MPEG4"
    ESC.render.ffmpeg.codec = "H264"
    ESC.render.ffmpeg.constant_rate_factor = "HIGH"
    ESC.render.ffmpeg.gopsize = 12
    ESC.render.use_file_extension = False
    ESC.render.filepath = os.path.join(SALIDA, "llegada_nave.mp4")
    bpy.ops.render.render(animation=True)
    print("VIDEO", ESC.render.filepath)
