"""Piezas compartidas por las cinemáticas hechas en Blender: utilidades, look 2D pintado,
la nave-estrella del juego y sus 6 piezas modulares (una por planeta, guia-estilo-generacion.md §3).

Se importa desde cada guion de cinemática (llegada_nave.py, taller_piezas.py):
    sys.path.insert(0, carpeta_de_este_archivo)
    from nave_comun import *
Al importarse deja la escena de Blender vacía y lista para construir.
"""
import math
import os
import random
import sys
from types import SimpleNamespace

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
FPS = 24

bpy.ops.wm.read_factory_settings(use_empty=True)
ESC = bpy.context.scene
COL = ESC.collection


# ----------------------------------------------------------------------------- materiales
def lin(hexa, a=1.0):
    """Color sRGB '#RRGGBB' a lineal RGBA (lo que espera Blender)."""
    hexa = hexa.lstrip("#")
    canales = []
    for i in (0, 2, 4):
        c = int(hexa[i:i + 2], 16) / 255
        canales.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*canales, a)


def brillante(nombre, color, fuerza=1.0):
    """Material que solo emite (ventana, estrellas, luces): no recibe sombra."""
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    emi = nt.nodes.new("ShaderNodeEmission")
    emi.inputs["Color"].default_value = lin(color)
    emi.inputs["Strength"].default_value = fuerza
    nt.links.new(emi.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    return m


def toon(nombre, color=None, atributo=None, tinte="#A596D6", umbral=(0.47, 0.53), brillo=0.0):
    """Sombreado plano de dos tonos (luz / sombra teñida de lila) con el borde algo irregular,
    como una pincelada. La luz de la escena solo decide QUÉ tono toca; el color lo pone el arte.
    El color base queda en el nodo "color" (se puede animar)."""
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    dif = nt.nodes.new("ShaderNodeBsdfDiffuse")
    dif.inputs["Color"].default_value = (1, 1, 1, 1)
    a_rgb = nt.nodes.new("ShaderNodeShaderToRGB")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    grano = nt.nodes.new("ShaderNodeTexNoise")
    grano.inputs["Scale"].default_value = 1.6
    temblor = nt.nodes.new("ShaderNodeMath")
    temblor.operation = "MULTIPLY_ADD"
    temblor.inputs[1].default_value, temblor.inputs[2].default_value = 0.05, -0.025
    suma = nt.nodes.new("ShaderNodeMath")
    rampa = nt.nodes.new("ShaderNodeValToRGB")
    rampa.color_ramp.elements[0].position = umbral[0]
    rampa.color_ramp.elements[1].position = umbral[1]
    nt.links.new(dif.outputs[0], a_rgb.inputs[0])
    nt.links.new(coord.outputs["Object"], grano.inputs["Vector"])
    nt.links.new(grano.outputs[0], temblor.inputs[0])
    nt.links.new(a_rgb.outputs["Color"], suma.inputs[0])
    nt.links.new(temblor.outputs[0], suma.inputs[1])
    nt.links.new(suma.outputs[0], rampa.inputs[0])
    if atributo:
        fuente = nt.nodes.new("ShaderNodeAttribute")
        fuente.attribute_name = atributo
        s_color = fuente.outputs["Color"]
    else:
        fuente = nt.nodes.new("ShaderNodeRGB")
        fuente.name = "color"
        fuente.outputs[0].default_value = lin(color)
        s_color = fuente.outputs[0]

    def mezcla(tipo, a, b, factor):
        n = nt.nodes.new("ShaderNodeMix")
        n.data_type, n.blend_type = "RGBA", tipo
        for entrada, valor in ((0, factor), (6, a), (7, b)):
            if hasattr(valor, "node"):
                nt.links.new(valor, n.inputs[entrada])
            else:
                n.inputs[entrada].default_value = valor
        return n.outputs[2]

    sombra = mezcla("MULTIPLY", s_color, lin(tinte), 1.0)
    final = mezcla("MIX", sombra, s_color, rampa.outputs[0])
    if brillo:
        rampa2 = nt.nodes.new("ShaderNodeValToRGB")
        rampa2.color_ramp.elements[0].position = 0.86
        rampa2.color_ramp.elements[1].position = 0.94
        nt.links.new(suma.outputs[0], rampa2.inputs[0])
        claro = mezcla("MIX", s_color, (1, 1, 1, 1), brillo)
        final = mezcla("MIX", final, claro, rampa2.outputs[0])
    emi = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(final, emi.inputs["Color"])
    nt.links.new(emi.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    return m


def halo(nombre, color, centro=0.2, borde=0.85, fuerza=1.2):
    """Burbuja / silueta fantasma: luz translúcida, más marcada en el borde. La opacidad total
    se multiplica por el alfa del color del objeto (para desvanecerla animando `color`)."""
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    cara = nt.nodes.new("ShaderNodeLayerWeight")
    cara.inputs["Blend"].default_value = 0.5
    rampa = nt.nodes.new("ShaderNodeValToRGB")
    rampa.color_ramp.elements[0].position, rampa.color_ramp.elements[0].color = 0.35, (centro,) * 3 + (1,)
    rampa.color_ramp.elements[1].position, rampa.color_ramp.elements[1].color = 0.80, (borde,) * 3 + (1,)
    info = nt.nodes.new("ShaderNodeObjectInfo")
    mult = nt.nodes.new("ShaderNodeMath")
    mult.operation = "MULTIPLY"
    emi = nt.nodes.new("ShaderNodeEmission")
    emi.inputs["Color"].default_value = lin(color)
    emi.inputs["Strength"].default_value = fuerza
    tra = nt.nodes.new("ShaderNodeBsdfTransparent")
    mez = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(cara.outputs["Facing"], rampa.inputs[0])
    nt.links.new(rampa.outputs[0], mult.inputs[0])
    nt.links.new(info.outputs["Alpha"], mult.inputs[1])
    nt.links.new(mult.outputs[0], mez.inputs[0])
    nt.links.new(tra.outputs[0], mez.inputs[1])
    nt.links.new(emi.outputs[0], mez.inputs[2])
    nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    return m


def con_alfa(nombre, color, fuerza=1.0):
    """Color plano cuya opacidad es el alfa del color del objeto (polvo, ondas, destellos)."""
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    info = nt.nodes.new("ShaderNodeObjectInfo")
    emi = nt.nodes.new("ShaderNodeEmission")
    emi.inputs["Color"].default_value = lin(color)
    emi.inputs["Strength"].default_value = fuerza
    tra = nt.nodes.new("ShaderNodeBsdfTransparent")
    mez = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(info.outputs["Alpha"], mez.inputs[0])
    nt.links.new(tra.outputs[0], mez.inputs[1])
    nt.links.new(emi.outputs[0], mez.inputs[2])
    nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    return m


_MATS = {}


def mat(nombre, fabrica=toon, *a, **k):
    """Material con nombre, creado una sola vez (las piezas se construyen varias veces)."""
    if nombre not in _MATS:
        _MATS[nombre] = fabrica(nombre, *a, **k)
    return _MATS[nombre]


# Contorno: una cáscara un poco más grande que solo se ve por su cara interior (casco invertido)
m_linea = brillante("linea", "#4B3247", 1.0)
m_linea.use_backface_culling = True
m_linea.use_backface_culling_shadow = True   # la cáscara no debe darle sombra al objeto
INVERTIR_CASCARA = True


def contorno(o, grosor=0.03):
    n = len(o.data.materials)
    for _ in range(n):
        o.data.materials.append(m_linea)
    so = o.modifiers.new("contorno", "SOLIDIFY")
    so.thickness, so.offset = grosor, 1.0
    so.use_rim, so.use_even_offset = False, True
    so.use_flip_normals = INVERTIR_CASCARA
    so.material_offset = n
    return o


# ----------------------------------------------------------------------------- mallas
def vacio(nombre, padre=None, pos=(0, 0, 0)):
    o = bpy.data.objects.new(nombre, None)
    COL.objects.link(o)
    o.parent = padre
    o.location = pos
    return o


def objeto(nombre, malla, mat=None, padre=None, suave=True, sombra=True):
    if suave:
        malla.polygons.foreach_set("use_smooth", [True] * len(malla.polygons))
    o = bpy.data.objects.new(nombre, malla)
    COL.objects.link(o)
    for m in (mat if isinstance(mat, (list, tuple)) else [mat] if mat else []):
        malla.materials.append(m)
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


def caja(nombre, minimo, maximo, mat, padre=None, linea=0.0):
    mn, mx = Vector(minimo), Vector(maximo)
    mtx = Matrix.Translation((mn + mx) / 2) @ Matrix.Diagonal((*(mx - mn), 1.0))
    me = malla_bm(nombre, lambda bm: bmesh.ops.create_cube(bm, size=1.0, matrix=mtx))
    o = objeto(nombre, me, mat, padre, suave=False)
    return contorno(o, linea) if linea else o


def esfera(nombre, radio, pos, mat, escala=(1, 1, 1), padre=None, u=24, v=14, sombra=True, linea=0.0):
    me = malla_bm(nombre, lambda bm: bmesh.ops.create_uvsphere(
        bm, u_segments=u, v_segments=v, radius=radio, matrix=Matrix.Diagonal((*escala, 1.0))))
    o = objeto(nombre, me, mat, padre, sombra=sombra)
    o.location = pos
    return contorno(o, linea) if linea else o


def cilindro(nombre, radio, alto, pos, mat, padre=None, radio2=None, seg=20, linea=0.0):
    mtx = Matrix.Translation((0, 0, alto / 2))
    me = malla_bm(nombre, lambda bm: bmesh.ops.create_cone(
        bm, cap_ends=True, segments=seg, radius1=radio,
        radius2=radio if radio2 is None else radio2, depth=alto, matrix=mtx))
    o = objeto(nombre, me, mat, padre)
    o.location = pos
    return contorno(o, linea) if linea else o


def torno(nombre, perfil, mat, padre=None, seg=48, subdiv=0, eje="Z", mats_seg=None, linea=0.0):
    """Sólido de revolución a partir de un perfil [(radio, altura), ...]. eje='X' lo acuesta.
    mats_seg: índice de material por tramo del perfil (para franjas de color)."""
    verts, caras = [], []
    for r, z in perfil:
        for s in range(seg):
            a = 2 * math.pi * s / seg
            x, y = r * math.cos(a), r * math.sin(a)
            verts.append((z, y, -x) if eje == "X" else (x, y, z))
    for i in range(len(perfil) - 1):
        for s in range(seg):
            s2 = (s + 1) % seg
            caras.append((i * seg + s, i * seg + s2, (i + 1) * seg + s2, (i + 1) * seg + s))
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], caras)
    if mats_seg:
        for i, p in enumerate(me.polygons):
            p.material_index = mats_seg[i // seg]
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = objeto(nombre, me, mat, padre)
    if subdiv:
        o.modifiers.new("suavizado", "SUBSURF").levels = subdiv
        o.modifiers["suavizado"].render_levels = subdiv
    return contorno(o, linea) if linea else o


ESTRELLA5 = [((1.0 if k % 2 == 0 else 0.5) * math.cos(math.pi / 2 + k * math.pi / 5),
              (1.0 if k % 2 == 0 else 0.5) * math.sin(math.pi / 2 + k * math.pi / 5)) for k in range(10)]


def figura_plana(nombre, puntos, mat, padre=None, grosor=0.0):
    """Polígono plano en el plano XZ (de cara a -Y) a partir de [(x, z), ...]."""
    def _f(bm):
        bm.faces.new([bm.verts.new((x, 0, z)) for x, z in puntos])
    o = objeto(nombre, malla_bm(nombre, _f), mat, padre, suave=False, sombra=False)
    if grosor:
        so = o.modifiers.new("grosor", "SOLIDIFY")
        so.thickness, so.offset = grosor, 0.0
    return o


# ----------------------------------------------------------------------------- animación
def clave(dato, prop, cuadro, valor=None, indice=-1):
    if valor is not None:
        setattr(dato, prop, valor)
    dato.keyframe_insert(prop, frame=cuadro, index=indice)


def clave_nodo(zocalo, cuadro, valor):
    zocalo.default_value = valor
    zocalo.keyframe_insert("default_value", frame=cuadro)


def curva(obj, ruta, indice=0):
    return obj.animation_data.action.fcurves.find(ruta, index=indice)


def ruido(obj, ruta, indice, fuerza, escala, hasta):
    fc = curva(obj, ruta, indice)
    m = fc.modifiers.new("NOISE")
    m.strength, m.scale, m.phase = fuerza, escala, random.uniform(0, 100)
    m.use_restricted_range = True
    m.frame_start, m.frame_end, m.blend_out = 1, hasta, 8
    return m


def lineal(obj):
    """Pasa todas las claves del objeto a interpolación lineal (caídas, confeti)."""
    for fc in obj.animation_data.action.fcurves:
        for k in fc.keyframe_points:
            k.interpolation = "LINEAR"


def apuntar(obj, direccion):
    obj.rotation_euler = Vector(direccion).to_track_quat("-Z", "Y").to_euler()


# ----------------------------------------------------------------------------- la nave-estrella (la del juego)
# raiz: posición, giro sobre la vertical y rebote. nave: cabeceo.
# En el espacio de la nave: +X es la nariz, -X las toberas, +Z la cúpula, +Y su lado izquierdo.
CX, CZ = 0.15, 1.06                      # centro del aro de la cúpula
C_CUP = Vector((CX, 0, CZ + 0.16))       # centro del vidrio
TOBERAS = [(0.47 * math.cos(a), 0.47 * math.sin(a)) for a in (math.radians(g) for g in (90, 210, 330))]
PERFIL_CASCO = [(0, -1.60), (0.62, -1.60), (0.88, -1.45), (1.02, -1.10), (1.08, -0.75), (1.10, -0.3),
                (1.10, 0.25), (1.04, 0.75), (0.90, 1.15), (0.66, 1.50), (0.36, 1.72), (0, 1.80)]


def parche(nombre, ancho, alto, mat, centro, direccion, objetivo, padre, giro=0.0, elipse=False, n=10,
           dist=1.7, forma=None):
    """Calcomanía que se adhiere a una superficie curva (shrinkwrap). Se coloca fuera, en
    `direccion` desde `centro`, y se proyecta hacia adentro. forma: lista de (u, v) para un contorno."""
    verts, caras = [], []
    if forma:
        verts = [(0.0, 0.0, 0.0)] + [(u * ancho / 2, 0.0, v * alto / 2) for u, v in forma]
        k = len(forma)
        caras = [(0, 1 + i, 1 + (i + 1) % k) for i in range(k)]
    else:
        for j in range(n + 1):
            for i in range(n + 1):
                u, v = i / n * 2 - 1, j / n * 2 - 1
                if elipse:
                    u, v = u * math.sqrt(1 - v * v / 2), v * math.sqrt(1 - u * u / 2)
                verts.append((u * ancho / 2, 0.0, v * alto / 2))
        for j in range(n):
            for i in range(n):
                a = j * (n + 1) + i
                caras.append((a, a + 1, a + n + 2, a + n + 1))
    rot = Matrix.Rotation(giro, 4, "Y")
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([tuple(rot @ Vector(v)) for v in verts], [], caras)
    o = objeto(nombre, me, mat, padre, sombra=False)
    d = Vector(direccion).normalized()
    o.location = Vector(centro) + d * dist
    o.rotation_euler = (-d).to_track_quat("Y", "Z").to_euler()
    sw = o.modifiers.new("pegar", "SHRINKWRAP")
    sw.target, sw.wrap_method = objetivo, "PROJECT"
    sw.use_project_x, sw.use_project_y, sw.use_project_z = False, True, False
    sw.use_positive_direction, sw.use_negative_direction = True, False
    sw.offset = 0.012
    so = o.modifiers.new("grosor", "SOLIDIFY")
    so.thickness, so.offset = 0.02, 1.0
    return o


def _en_casco(n, nombre, ancho, alto, mat, x, ang, giro=0.0, **kw):
    """ang=0 es el costado derecho (-Y); positivo sube hacia la cúpula; pi es el costado izquierdo."""
    return parche(nombre, ancho, alto, mat, (x, 0, 0), (0, -math.cos(ang), math.sin(ang)), n.casco,
                  n.nave, giro, **kw)


def construir_nave(completa=False):
    """Arma la nave en su estado básico (el del hangar: curitas, parches y pompón, sin piezas).
    completa=True la viste como el sprite final. Devuelve sus partes para animarlas."""
    n = SimpleNamespace()
    n.raiz = vacio("nave_raiz")
    n.nave = vacio("nave", n.raiz)

    m_casco = toon("casco", "#8EDCC4", brillo=0.45)
    m_crema = toon("crema", "#FFF1D8", brillo=0.3)
    m_rosa = toon("banda_rosa", "#F7B4D4", brillo=0.4)
    n.m_aro = toon("aro", "#F2C25C" if completa else "#FFF1D8", brillo=0.4)
    n.m_tobera = toon("tobera", "#F4E3C0" if completa else "#C9B6E8", brillo=0.4)
    n.m_fuego = brillante("tobera_dentro", "#FFE9A0" if completa else "#B98AE0", 1.0)

    # cuerpo: huevo gordito, extremos crema (estado básico) o banda rosa atrás (completa)
    if completa:
        franjas, mats_casco = [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0], [m_casco, m_rosa]
    else:
        franjas, mats_casco = [1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1], [m_casco, m_crema]
    n.casco = torno("casco", PERFIL_CASCO, mats_casco, n.nave, subdiv=2, eje="X", mats_seg=franjas, linea=0.035)

    # cúpula con su aro, arriba
    aro = torno("aro", [(0.66, -0.50), (0.72, -0.05), (0.83, -0.01), (0.88, 0.08), (0.84, 0.18), (0.70, 0.22),
                        (0, 0.22)], n.m_aro, n.nave, linea=0.03)
    aro.location = (CX, 0, CZ)

    m_cupula = bpy.data.materials.new("cupula")
    m_cupula.use_nodes = True
    m_cupula.surface_render_method = "BLENDED"
    nt = m_cupula.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    borde = nt.nodes.new("ShaderNodeLayerWeight")
    borde.inputs["Blend"].default_value = 0.5
    r_cup = nt.nodes.new("ShaderNodeValToRGB")
    palido, trazo = lin("#EAF6FF"), lin("#4B3247")
    r_cup.color_ramp.elements[0].position, r_cup.color_ramp.elements[0].color = 0.0, (*palido[:3], 0.07)
    r_cup.color_ramp.elements[1].position, r_cup.color_ramp.elements[1].color = 0.80, (*trazo[:3], 1.0)
    r_cup.color_ramp.elements.new(0.76).color = (*palido[:3], 0.34)
    encendido = nt.nodes.new("ShaderNodeValue")          # 0 = apagada, 1 = luz cálida adentro
    dentro = nt.nodes.new("ShaderNodeMath")
    dentro.operation = "LESS_THAN"
    dentro.inputs[1].default_value = 0.76
    calor = nt.nodes.new("ShaderNodeMath")
    calor.operation = "MULTIPLY"
    tibio = nt.nodes.new("ShaderNodeMix")
    tibio.data_type = "RGBA"
    tibio.inputs[7].default_value = lin("#FFD9A0")
    f_tibio = nt.nodes.new("ShaderNodeMath")
    f_tibio.operation = "MULTIPLY"
    f_tibio.inputs[1].default_value = 0.75
    alfa = nt.nodes.new("ShaderNodeMath")
    alfa.operation = "MULTIPLY_ADD"
    alfa.inputs[1].default_value = 0.38
    emi = nt.nodes.new("ShaderNodeEmission")
    tra = nt.nodes.new("ShaderNodeBsdfTransparent")
    mez = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(borde.outputs["Facing"], r_cup.inputs[0])
    nt.links.new(borde.outputs["Facing"], dentro.inputs[0])
    nt.links.new(dentro.outputs[0], calor.inputs[0])
    nt.links.new(encendido.outputs[0], calor.inputs[1])
    nt.links.new(calor.outputs[0], f_tibio.inputs[0])
    nt.links.new(f_tibio.outputs[0], tibio.inputs[0])
    nt.links.new(r_cup.outputs["Color"], tibio.inputs[6])
    nt.links.new(calor.outputs[0], alfa.inputs[0])
    nt.links.new(r_cup.outputs["Alpha"], alfa.inputs[2])
    nt.links.new(tibio.outputs[2], emi.inputs["Color"])
    nt.links.new(alfa.outputs[0], mez.inputs[0])
    nt.links.new(tra.outputs[0], mez.inputs[1])
    nt.links.new(emi.outputs[0], mez.inputs[2])
    nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    n.encendido = encendido.outputs[0]
    n.cupula = esfera("cupula", 0.62, C_CUP, m_cupula, escala=(1, 1, 1.12), padre=n.nave, u=40, v=24, sombra=False)

    # tres toberas grandes atrás, en triángulo
    for y, z in TOBERAS:
        t = torno("tobera", [(0, -0.14), (0.20, -0.14), (0.28, -0.50), (0.35, -0.50), (0.36, -0.40),
                             (0.27, 0.0), (0, 0.0)], [n.m_tobera, n.m_fuego], n.nave, seg=28, eje="X",
                  mats_seg=[1, 1, 0, 0, 0, 0], linea=0.03)
        t.location = (-1.50, y, z)

    n.remiendos, n.gala = [], []
    if completa:
        # como el sprite final: franja dorada, estrellas, placa, alas con los colores de los hermanos y corazón
        vestir_gala(n)
        pieza("ala_izquierda", n.nave, final=True)
        pieza("ala_derecha", n.nave, final=True)
        pieza("nucleo", n.nave)
    else:
        # estado básico, como en el hangar: curitas en X, parches cosidos y un pompón
        m_curita = toon("curita", "#F5C542")
        m_parches = [toon("parche_lila", "#B58AD8"), toon("parche_rosa", "#F29AB8"), toon("parche_verde", "#9CCB6B")]

        def curita(x, ang, giro, largo=0.52):
            for g in (giro, giro + math.pi / 2):
                n.remiendos.append(_en_casco(n, "curita", largo, 0.15, m_curita, x, ang, giro=g))

        curita(0.72, 0.52, 0.5)
        curita(-0.42, -0.38, 0.75)
        curita(0.35, math.pi - 0.2, 0.4)
        for ancho, alto, i, x, ang, giro in ((0.34, 0.30, 0, -0.38, 0.62, 0.2), (0.30, 0.34, 1, 0.18, 0.02, -0.15),
                                             (0.26, 0.26, 2, -0.02, 0.30, 0.35), (0.30, 0.24, 0, 0.80, -0.42, -0.3),
                                             (0.30, 0.30, 1, -0.45, math.pi + 0.4, 0.2),
                                             (0.28, 0.26, 2, 0.75, math.pi - 0.55, -0.2)):
            n.remiendos.append(_en_casco(n, "parche", ancho, alto, m_parches[i], x, ang, giro=giro))
        n.remiendos.append(esfera("pompon", 0.10, (-0.62, -0.93, 0.56), toon("pompon", "#7FB6D9"),
                                  padre=n.nave, u=12, v=8, linea=0.015))

    # destello pintado sobre el vidrio de la cúpula
    parche("destello", 0.10, 0.34, brillante("destello", "#FFFFFF", 1.0), C_CUP, (-0.55, -0.72, 0.42),
           n.cupula, n.nave, giro=0.55, elipse=True, n=6, dist=1.2)
    return n


def vestir_gala(n):
    """Acabado de la nave terminada: franja dorada, estrellas celestes y placa a cada lado.
    Deja las piezas en n.gala (para hacerlas aparecer cuando el núcleo le da vida a la nave)."""
    m_oro = mat("oro", toon, "#F2C25C", brillo=0.5)
    m_est = mat("estrella_nave", toon, "#6FC3E8")
    n.gala.append(torno("franja", [(1.03, -1.16), (1.07, -1.13), (1.08, -1.03), (1.06, -1.00)], m_oro,
                        n.nave, eje="X"))
    for ang in (0.05, math.pi - 0.05):
        n.gala.append(_en_casco(n, "estrella", 0.40, 0.40, m_est, -0.72, ang, forma=ESTRELLA5))
    for ang in (0.42, math.pi - 0.42):
        n.gala.append(_en_casco(n, "placa", 0.95, 0.36, m_oro, 0.55, ang, elipse=True))
    return n.gala


# ----------------------------------------------------------------------------- las 6 piezas (una por planeta)
PIEZAS = [("ala_izquierda", "Arcoíris"), ("ala_derecha", "Animalia"), ("motor_izquierdo", "Melodía"),
          ("motor_derecho", "Cuenta-Cuentas"), ("antena", "Letralandia"), ("nucleo", "Corazón")]
RADIO_PIEZA = {"ala_izquierda": 1.0, "ala_derecha": 1.0, "motor_izquierdo": 0.8, "motor_derecho": 0.8,
               "antena": 0.85, "nucleo": 0.6}        # tamaño de la burbuja que la envuelve
CENTRO_PIEZA = {"antena": (0, 0, 0.62)}              # centro visual respecto de su punto de encaje


def _ala(e, lado, colores, cortes, huella=False):
    mats = [mat("ala_" + c, toon, c, brillo=0.3) for c in colores]

    def _malla(bm):
        bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=16, radius=1.0,
                                  matrix=Matrix.Diagonal((0.95, 0.50, 0.09, 1.0)))
        for f in bm.faces:  # franjas a lo largo del ala
            t = f.calc_center_median().x / 0.95
            f.material_index = sum(1 for c in cortes if t > c)
    contorno(objeto("ala", malla_bm("ala", _malla), mats, e), 0.03)
    if huella:  # huellita pintada sobre el lomo del ala
        m_h = mat("huella", toon, "#2F6B45")
        esfera("huella", 0.14, (-0.10, 0, 0.088), m_h, escala=(1.15, 1.0, 0.22), padre=e, u=14, v=8, sombra=False)
        for x, y in ((0.07, -0.17), (0.15, -0.06), (0.15, 0.06), (0.07, 0.17)):
            esfera("dedo", 0.055, (x, y, 0.086), m_h, escala=(1, 1, 0.3), padre=e, u=10, v=6, sombra=False)
    e.location = (-0.10, lado * 1.45, -0.18)
    e.rotation_euler = (lado * -0.48, 0, lado * -0.30)


def _motor(e, lado, cuerpo, aro, luz, ventanitas=False):
    m_c = mat("motor_" + cuerpo, toon, cuerpo, brillo=0.4)
    m_a = mat("motor_aro_" + aro, toon, aro, brillo=0.5)
    m_l = mat("motor_luz_" + luz, brillante, luz, 1.5)
    torno("motor", [(0, -0.25), (0.22, -0.25), (0.33, -0.62), (0.40, -0.62), (0.41, -0.52), (0.26, -0.22),
                    (0.28, 0.10), (0.22, 0.34), (0.10, 0.44), (0, 0.44)], [m_c, m_l, m_a], e, seg=32, eje="X",
          mats_seg=[1, 1, 2, 2, 0, 0, 0, 0, 0], linea=0.03)
    if ventanitas:  # hilera de ventanitas redondas encendidas (guiño al conteo)
        m_v = mat("ventanita", brillante, "#FFE38A", 1.3)
        for k, x in enumerate((0.20, 0.02, -0.16)):
            r = 0.262 + 0.02 * (k == 1)
            esfera("ventanita", 0.058, (x, lado * r * 0.94, r * 0.34), m_v, padre=e, u=12, v=8,
                   sombra=False, linea=0.012)
    e.location = (-0.95, lado * 1.13, 0.50)


def _antena(e):
    m_oro = mat("oro", toon, "#F2C25C", brillo=0.5)
    m_palo = mat("mastil", toon, "#FFF1D8")
    m_band = [mat("banderin_a", toon, "#F59A4A"), mat("banderin_b", toon, "#FFB866")]
    esfera("base", 0.11, (0, 0, 0.02), m_oro, padre=e, u=14, v=8, linea=0.02)
    cilindro("mastil", 0.028, 1.25, (0, 0, 0), m_palo, e, seg=10, linea=0.015)
    esfera("punta", 0.07, (0, 0, 1.28), m_oro, padre=e, u=12, v=8, linea=0.015)
    for k, z in enumerate((1.18, 0.82)):
        b = figura_plana("banderin", [(0, 0), (0, -0.28), (-0.46, -0.14)], m_band[k], e, grosor=0.03)
        b.location = (-0.02, 0, z)
        contorno(b, 0.02)
    e.location = (-0.98, 0, 1.00)
    e.rotation_euler = (0, -0.12, 0)


def _nucleo(e):
    # corazón rosado-celeste que brilla dentro de la cúpula
    if "corazon" not in _MATS:
        m = bpy.data.materials.new("corazon")
        m.use_nodes = True
        nt = m.node_tree
        nt.nodes.remove(nt.nodes["Principled BSDF"])
        coord = nt.nodes.new("ShaderNodeTexCoord")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        rampa = nt.nodes.new("ShaderNodeValToRGB")
        rampa.color_ramp.elements[0].position, rampa.color_ramp.elements[0].color = -0.02, lin("#FF7FB0")
        rampa.color_ramp.elements[1].position, rampa.color_ramp.elements[1].color = 0.22, lin("#8FD8F5")
        emi = nt.nodes.new("ShaderNodeEmission")
        emi.inputs["Strength"].default_value = 2.0
        nt.links.new(coord.outputs["Object"], sep.inputs[0])
        nt.links.new(sep.outputs["X"], rampa.inputs[0])
        nt.links.new(rampa.outputs[0], emi.inputs["Color"])
        nt.links.new(emi.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
        _MATS["corazon"] = m
    puntos = []
    for k in range(40):
        t = 2 * math.pi * k / 40
        x = 16 * math.sin(t) ** 3
        z = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        puntos.append((x * 0.019, z * 0.019 + 0.05))
    figura_plana("corazon", puntos, _MATS["corazon"], e, grosor=0.16)
    e.location = (CX, 0, CZ + 0.50)


def pieza(ident, padre, final=False):
    """Construye una pieza bajo un vacío colocado en su punto de encaje (coordenadas de la nave).
    final=True pinta las alas con los colores de los tres hermanos (sprite de la nave terminada)."""
    e = vacio("pieza_" + ident, padre)
    if ident in ("ala_izquierda", "ala_derecha"):
        lado = 1 if ident == "ala_izquierda" else -1
        if final:
            _ala(e, lado, ["#F3A8C8", "#F7F3EC", "#7FA8DC", "#F7F3EC"], (-0.45, -0.15, 0.35))
        elif lado == 1:     # Arcoíris: franjas multicolor pastel
            _ala(e, lado, ["#F7A8C8", "#FBE08A", "#8FD3F0", "#C3A6E8"], (-0.5, 0.0, 0.5))
        else:               # Animalia: verde selva con huellita
            _ala(e, lado, ["#63B06C"], (), huella=True)
    elif ident == "motor_izquierdo":    # Melodía: bocina morada con borde neón
        _motor(e, 1, "#A77BE0", "#7CF0DC", "#F3B8FF")
    elif ident == "motor_derecho":      # Cuenta-Cuentas: azul noche con ventanitas
        _motor(e, -1, "#3F4F96", "#F2C25C", "#A9CCFF", ventanitas=True)
    elif ident == "antena":             # Letralandia: mástil con banderines naranjas
        _antena(e)
    elif ident == "nucleo":             # Corazón: el núcleo que le da vida a la nave
        _nucleo(e)
    else:
        raise ValueError("pieza desconocida: " + ident)
    return e


def mallas_de(o):
    for h in o.children_recursive:
        if h.type == "MESH":
            yield h


def fantasmear(e, material):
    """Convierte una pieza ya construida en su silueta fantasma (hueco que espera a la pieza)."""
    for o in mallas_de(e):
        for m in list(o.modifiers):
            if m.name == "contorno":
                o.modifiers.remove(m)
        o.data.materials.clear()
        o.data.materials.append(material)
        o.data.polygons.foreach_set("material_index", [0] * len(o.data.polygons))
        o.visible_shadow = False
    return e


# ----------------------------------------------------------------------------- render, compositor y salidas
def preparar_render(f_fin):
    ESC.render.engine = "BLENDER_EEVEE_NEXT"
    ESC.render.resolution_x, ESC.render.resolution_y = 1280, 720
    ESC.render.resolution_percentage = int(arg("--escala", 100))
    ESC.render.fps = FPS
    ESC.frame_start, ESC.frame_end = 1, f_fin
    ESC.eevee.taa_render_samples = int(arg("--muestras", 32))
    ESC.view_settings.view_transform = "Standard"
    ESC.view_settings.look = "None"


def compositor():
    """Filtro de pincel (Kuwahara) + brillo suave. --sin-pincel lo quita, --pincel N cambia el tamaño."""
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


def salidas(nombre):
    """--blend guarda la escena, --fotos 1,80 saca cuadros sueltos, --video el mp4 completo."""
    if arg("--blend"):
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SALIDA, nombre + ".blend"))
        print("GUARDADO", os.path.join(SALIDA, nombre + ".blend"))
    if arg("--fotos"):
        ESC.render.image_settings.file_format = "PNG"
        for f in (int(x) for x in str(arg("--fotos")).split(",")):
            ESC.frame_set(f)
            ESC.render.filepath = os.path.join(SALIDA, f"{nombre}_foto_{f:04d}.png")
            bpy.ops.render.render(write_still=True)
            print("FOTO", ESC.render.filepath)
    if arg("--video"):
        ESC.render.image_settings.file_format = "FFMPEG"
        ESC.render.ffmpeg.format = "MPEG4"
        ESC.render.ffmpeg.codec = "H264"
        ESC.render.ffmpeg.constant_rate_factor = "HIGH"
        ESC.render.ffmpeg.gopsize = 12
        ESC.render.use_file_extension = False
        ESC.render.filepath = os.path.join(SALIDA, nombre + ".mp4")
        bpy.ops.render.render(animation=True)
        print("VIDEO", ESC.render.filepath)
