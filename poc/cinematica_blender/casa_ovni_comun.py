"""Escenario y personajes compartidos por las cinemáticas de la intro hechas en Blender
(presentacion_coleccionauta.py, cometa_llega_tarde.py): la casa de los niños al atardecer, el ovni del
Coleccionauta (copia 3D del sprite assets/sprites/viaje/coleccionauta_nave.png) y los "títeres": los
sprites 2D del juego puestos como cartón recortado dentro del 3D, así se ven igual que en el juego.

Se importa después de nave_comun:  from casa_ovni_comun import *
"""
import math
import os
import random
from types import SimpleNamespace

import bmesh
import bpy
from mathutils import Matrix, Vector

from nave_comun import *  # noqa: F401,F403

REPO = os.path.abspath(os.path.join(AQUI, "..", ".."))
OVNI = Vector((1.3, 0.0, 6.2))          # dónde flota el ovni sobre la casa
CAM_INICIO = Vector((-0.5, -15.0, 4.2))  # plano general de la casa
CASA = SimpleNamespace(x0=-8.2, x1=-1.6, y0=3.5, y1=8.0, alto=4.6, ventanas=(-6.5, -3.3))


def _estrella(bm, mtx, radio, puntas=5, hundir=0.55):
    n = puntas * 2
    vs = []
    for k in range(n):
        r = radio if k % 2 == 0 else radio * hundir
        a = math.pi / 2 + k * 2 * math.pi / n
        vs.append(bm.verts.new(mtx @ Vector((r * math.cos(a), r * math.sin(a), 0))))
    bm.faces.new(vs)



def escenario(cam=CAM_INICIO):
    """Cielo de atardecer (como despegue_tierra.py), estrellas, nubes, cerros, árboles y la casa."""
    CAM_INICIO = cam
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

    m_estrella = brillante("estrella", "#FFD86B", 1.6)


    def _estrellas(bm):
        for i in range(110):
            az, el = random.uniform(-1.4, 1.4), random.uniform(0.32, 1.4)
            p = Vector((math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el))) * 260
            giro = (CAM_INICIO - p).to_track_quat("Z", "Y").to_matrix().to_4x4()
            mtx = Matrix.Translation(p) @ giro @ Matrix.Rotation(random.uniform(-0.3, 0.3), 4, "Z")
            if i < 14:
                _estrella(bm, mtx, random.uniform(1.6, 3.0))
            else:
                _estrella(bm, mtx, random.uniform(0.25, 0.6), 4, 0.9)


    objeto("estrellas", malla_bm("estrellas", _estrellas), m_estrella, suave=False, sombra=False)

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
        for _ in range(18):
            az = random.uniform(-1.2, 1.2)
            el = random.uniform(0.06, 0.7) ** 1.3
            d = 170
            c = Vector((d * math.sin(az) * math.cos(el), d * math.cos(az) * math.cos(el), d * math.sin(el)))
            lado = Vector((math.cos(az), -math.sin(az), 0))
            tam = random.uniform(5, 10) * (1.0 - 0.35 * el)
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

    # ----------------------------------------------------------------------------- suelo, cerros y la casa de los niños
    caja("suelo", (-150, -60, -1), (150, 150, 0), toon("pasto", "#5E9A55"))
    m_cerro, m_cerro2 = brillante("cerro", "#8273AE"), brillante("cerro2", "#9A82B8")
    for i, (x, y, sx, sz) in enumerate(((-55, 95, 45, 11), (-5, 120, 60, 15), (60, 100, 50, 12), (-110, 110, 50, 9))):
        esfera("cerro", 1.0, (x, y, -1.5), (m_cerro, m_cerro2)[i % 2], escala=(sx, 22, sz))

    m_hojas = [toon("hojas1", "#4F9160"), toon("hojas2", "#63A86A")]
    m_tronco = toon("tronco", "#7A5540")
    for x, y, alto, copa in ((10.5, 14.0, 2.2, 1.3), (15.5, 17.0, 2.6, 1.5)):
        cilindro("tronco", 0.22 * copa, alto, (x, y, 0), m_tronco, radio2=0.15 * copa, linea=0.04)
        for k in range(5):
            esfera("copa", random.uniform(0.9, 1.4) * copa,
                   (x + random.uniform(-0.9, 0.9) * copa, y + random.uniform(-0.6, 0.6) * copa,
                    alto + random.uniform(-0.2, 1.0) * copa), m_hojas[k % 2], u=16, v=10, linea=0.05)

    m_muro, m_techo, m_marco = toon("muro", "#F0D2B4"), toon("techo", "#B5616B"), toon("marco", "#FFF4E2")
    m_vidrio = brillante("vidrio_ventana", "#FFDF8F", 1.25)
    CX0, CX1, CY0, CY1, CH = -8.2, -1.6, 3.5, 8.0, 4.6
    caja("casa", (CX0, CY0, 0), (CX1, CY1, CH), m_muro, linea=0.04)
    caja("zocalo", (CX0 - 0.05, CY0 - 0.05, 0), (CX1 + 0.05, CY1, 0.35), toon("zocalo", "#B99782"), linea=0.03)
    caja("alero", (CX0 - 0.6, CY0 - 0.6, CH), (CX1 + 0.6, CY1 + 0.6, CH + 0.3), m_techo, linea=0.04)
    caja("techo", (CX0 - 0.2, CY0 - 0.2, CH + 0.3), (CX1 + 0.2, CY1 + 0.2, CH + 1.1), m_techo, linea=0.04)
    for vx in (-6.5, -3.3):   # dos ventanas encendidas: adentro están los niños jugando
        caja("vidrio", (vx - 1.0, CY0 - 0.04, 1.4), (vx + 1.0, CY0 - 0.01, 3.2), m_vidrio)
        caja("marco_inf", (vx - 1.15, CY0 - 0.2, 1.26), (vx + 1.15, CY0, 1.4), m_marco, linea=0.02)
        caja("marco_sup", (vx - 1.1, CY0 - 0.12, 3.2), (vx + 1.1, CY0, 3.32), m_marco, linea=0.02)
        caja("cruz_v", (vx - 0.04, CY0 - 0.08, 1.4), (vx + 0.04, CY0 - 0.02, 3.2), m_marco)


def construir_ovni():
    """raiz: posición y tambaleo. giro: el disco que da vueltas (las ampolletas lo delatan).
    bisagra: la tapa de la cúpula (rotación Y positiva = abierta hacia la derecha)."""
    # raiz: posición y tambaleo. giro: el disco que da vueltas (las ampolletas lo delatan).
    raiz = vacio("ovni")
    giro = vacio("giro", raiz)
    R = 1.7
    m_disco = toon("disco", "#6A4FC4", brillo=0.5)
    m_panza = toon("panza", "#5038A6")
    m_oro = toon("oro", "#F2B84B", brillo=0.7)
    perfil = [(0.0, -0.36), (0.55, -0.36), (1.15, -0.27), (1.55, -0.12), (R, 0.0), (R - 0.02, 0.07),
              (1.45, 0.17), (0.95, 0.26), (0.0, 0.28)]
    torno("disco", perfil, [m_panza, m_disco], giro, subdiv=1, mats_seg=[0, 0, 0, 0, 1, 1, 1, 1], linea=0.035)
    aro = [(R + 0.05 + 0.05 * math.cos(t), 0.01 + 0.05 * math.sin(t))
           for t in [2 * math.pi * k / 10 for k in range(11)]]
    torno("aro", aro, m_oro, giro)
    m_ampolleta = brillante("ampolleta", "#FFE58A", 2.2)
    for k in range(12):
        a = 2 * math.pi * k / 12
        esfera("ampolleta", 0.075, (math.cos(a) * 1.3, math.sin(a) * 1.3, 0.21), m_ampolleta, padre=giro,
               u=10, v=6, sombra=False, linea=0.015)
    # patitas cortas abajo (cómico) y un haz suave apagado
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.5
        esfera("patita", 0.12, (math.cos(a) * 0.7, math.sin(a) * 0.7, -0.38), m_oro, padre=giro, u=10, v=6, linea=0.02)

    # cúpula verde de vidrio con bisagra a la derecha: se abre como tapa de frasco, hacia el lado
    m_cupula = halo("cupula", "#8BE06A", centro=0.35, borde=0.95, fuerza=1.1)
    bisagra = vacio("bisagra", raiz, (0.82, 0, 0.26))
    cupula = esfera("cupula", 0.82, (-0.82, 0, 0), m_cupula, escala=(1, 1, 0.92), padre=bisagra, u=32, v=16,
                    sombra=False)
    cupula.color = (1, 1, 1, 1)
    # deja solo la mitad de arriba (hemisferio)
    bm = bmesh.new()
    bm.from_mesh(cupula.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context="VERTS")
    bm.to_mesh(cupula.data)
    bm.free()
    m_tapa_aro = toon("tapa_aro", "#4CA845")
    aro_tapa = [(0.84 + 0.04 * math.cos(t), 0.04 * math.sin(t)) for t in [2 * math.pi * k / 8 for k in range(9)]]
    o_aro_tapa = torno("aro_tapa", aro_tapa, m_tapa_aro, bisagra)
    o_aro_tapa.location = (-0.82, 0, 0)

    return SimpleNamespace(raiz=raiz, giro=giro, bisagra=bisagra, cupula=cupula)


def titere(nombre, ruta, alto, padre, pos=(0, 0, 0), mirar=None):
    """Sprite 2D (PNG con alfa) como cartón recortado. Devuelve el vacío de los pies (pivote para
    estirar, rebotar y mecer). mirar=cámara: el cartón siempre de frente a ella (vía un vacío intermedio)."""
    img = bpy.data.images.load(os.path.join(REPO, ruta))
    ancho = alto * img.size[0] / img.size[1]
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Cubic"
    emi = nt.nodes.new("ShaderNodeEmission")
    tra = nt.nodes.new("ShaderNodeBsdfTransparent")
    mez = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(tex.outputs["Color"], emi.inputs["Color"])
    nt.links.new(tex.outputs["Alpha"], mez.inputs[0])
    nt.links.new(tra.outputs[0], mez.inputs[1])
    nt.links.new(emi.outputs[0], mez.inputs[2])
    nt.links.new(mez.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([(-ancho / 2, 0, 0), (ancho / 2, 0, 0), (ancho / 2, 0, alto), (-ancho / 2, 0, alto)], [],
                   [(0, 1, 2, 3)])
    uv = me.uv_layers.new(name="uv")
    for i, c in enumerate(((0, 0), (1, 0), (1, 1), (0, 1))):
        uv.data[i].uv = c
    base = vacio(nombre + "_base", padre, pos)
    if mirar is not None:
        r = base.constraints.new("TRACK_TO")
        r.target, r.track_axis, r.up_axis = mirar, "TRACK_NEGATIVE_Y", "UP_Z"
    pies = vacio(nombre + "_pies", base)
    objeto(nombre, me, m, pies, suave=False, sombra=False)
    return pies


def chispas(padre, origen, f0, n=9, color="#FFE27A", alcance=(1.6, 2.4), abanico=(0.1, 0.9), vida=22):
    """Abanico de estrellitas que salen de `origen` (local al padre) en el cuadro f0 y se apagan."""
    m = mat("chispa_" + color, con_alfa, color, 2.4)
    for k in range(n):
        a = math.pi * (abanico[0] + (abanico[1] - abanico[0]) * k / max(1, n - 1))
        d = random.uniform(*alcance)
        o = objeto("chispa", malla_bm("chispa", lambda bm: _estrella(
            bm, Matrix.Rotation(math.pi / 2, 4, "X"), 0.16 if k % 3 else 0.24)), m, padre, suave=False, sombra=False)
        o0 = Vector(origen)
        destino = o0 + Vector((math.cos(a) * d, -0.2, math.sin(a) * d * 0.8))
        fi = f0 + k % 3
        for f, p, s, al in ((1, o0, 0.0, 0.0), (fi, o0, 0.2, 1.0), (fi + vida // 2, destino, 1.0, 1.0),
                            (fi + vida, destino + Vector((0, 0, -0.25)), 0.5, 0.0)):
            clave(o, "location", f, tuple(p))
            clave(o, "scale", f, (s, s, s))
            clave(o, "color", f, (1, 1, 1, al))
        for f, r in ((fi, 0.0), (fi + vida, random.choice((-1, 1)) * 3.0)):
            clave(o, "rotation_euler", f, (0, r, 0))


def camara(lente=32):
    sol = bpy.data.lights.new("sol", "SUN")
    sol.energy, sol.angle = 1.6, 0.02
    o_sol = bpy.data.objects.new("sol", sol)
    COL.objects.link(o_sol)
    apuntar(o_sol, (0.55, 0.55, -0.62))
    cam = bpy.data.cameras.new("camara")
    cam.lens, cam.clip_end = lente, 800
    o_cam = bpy.data.objects.new("camara", cam)
    COL.objects.link(o_cam)
    ESC.camera = o_cam
    mira = vacio("mira")
    seguir = o_cam.constraints.new("TRACK_TO")
    seguir.target, seguir.track_axis, seguir.up_axis = mira, "TRACK_NEGATIVE_Z", "UP_Y"
    return o_cam, cam, mira


# ----------------------------------------------------------------------------- la navecita de Cometa
# Ancla aprobada: assets/anclas/cometa_navecita.png. NO es la nave-estrella de los niños (nave_comun):
# es una cápsula chiquita de peluche pintado, turquesa, con una gran burbuja de vidrio adelante-arriba,
# franja amarilla abajo, parches cosidos (rosado, amarillo, turquesa oscuro), lunares crema, cinta
# dorada en X, tres propulsores atrás apilados y una antenita con estrella amarilla.
# En su espacio: +X es la nariz, -X los propulsores, +Z arriba.
NAVECITA_LARGO = 1.7
C_BURBUJA = Vector((0.26, 0.0, 0.27))


def _color_casco_navecita(co):
    x, y, z = co
    teal, amarillo = lin("#6CCBC0"), lin("#F3DC82")
    if x < -0.38 and z > 0.06:
        return lin("#F2AFC0")                      # parche rosado atrás-arriba
    if x > 0.5 and z < -0.12:
        return lin("#4FB0AE")                      # parche turquesa oscuro en la nariz-abajo
    if -0.3 < z < -0.07:
        return amarillo                            # franja amarilla alrededor
    if z <= -0.3 and -0.45 < x < 0.35:
        ang = math.atan2(y, -z)
        if math.sin(x * 38) * math.sin(ang * 13) > 0.55:
            return lin("#FFF1C9")                  # lunares crema abajo
    if x < -0.25 and z <= -0.07 and y < -0.2:
        return lin("#F6D38A")                      # parche amarillo del costado
    return teal


def construir_navecita(mirar):
    n = SimpleNamespace()
    n.raiz = vacio("navecita_raiz")
    n.nave = vacio("navecita", n.raiz)

    # casco: huevo algo achatado, colores pintados por vértice
    def _casco(bm):
        bmesh.ops.create_uvsphere(bm, u_segments=128, v_segments=80, radius=1.0,
                                  matrix=Matrix.Diagonal((0.85, 0.6, 0.5, 1.0)))
        capa = bm.verts.layers.float_color.new("col")
        for v in bm.verts:
            v[capa] = _color_casco_navecita(v.co)
    me = malla_bm("navecita_casco", _casco)
    m_casco = toon("navecita_casco", atributo="col", brillo=0.35)
    n.casco = objeto("navecita_casco", me, m_casco, n.nave)
    contorno(n.casco, 0.022)
    # cráteres suaves (como la ficha)
    m_crater = toon("crater", "#56B5AA")
    for x, ang in ((0.05, 0.9), (0.55, 0.5), (-0.55, -0.6), (0.3, -2.3)):
        parche("crater", 0.09, 0.07, m_crater, (x, 0, 0), (0, -math.cos(ang), math.sin(ang)), n.casco, n.nave,
               elipse=True, n=6, dist=1.2)
    # cinta dorada en X, a cada lado
    m_cinta = toon("cinta", "#E6B95A", brillo=0.3)
    for lado, x in ((-1, -0.2), (1, 0.25)):
        for g in (0.6, -0.6):
            parche("cinta", 0.36, 0.09, m_cinta, (x, 0, -0.05), (0, lado, 0.25), n.casco, n.nave, giro=g,
                   dist=1.2)

    # burbuja de vidrio adelante-arriba, con su brillo pintado
    m_vidrio = halo("vidrio_navecita", "#E8F7FF", centro=0.12, borde=0.85, fuerza=1.05)
    n.burbuja = esfera("burbuja", 0.56, C_BURBUJA, m_vidrio, escala=(1.08, 1.0, 1.0), padre=n.nave, u=40, v=24,
                       sombra=False)
    n.burbuja.color = (1, 1, 1, 1)
    parche("destello", 0.08, 0.26, brillante("destello_navecita", "#FFFFFF", 1.0), C_BURBUJA, (0.2, -0.75, 0.6),
           n.burbuja, n.nave, giro=0.6, elipse=True, n=6, dist=1.0)

    # Cometa adentro (títere 2D siempre de frente a la cámara)
    n.cometa = titere("cometa", "assets/sprites/personajes/cometa_saludo.png", 0.95, n.nave,
                      (C_BURBUJA.x - 0.02, 0, 0.06), mirar=mirar)

    # tres propulsores apilados atrás, con llamita
    m_prop = toon("propulsor", "#F2A3C2", brillo=0.3)
    m_prop2 = toon("propulsor2", "#5FC2BA", brillo=0.3)
    n.m_llama = con_alfa("llama_navecita", "#FFC94A", 2.2)
    n.llamas = []
    for i, z in enumerate((0.24, 0.0, -0.24)):
        c = cilindro("propulsor", 0.085, 0.2, (-0.72, 0, z), (m_prop, m_prop2)[i % 2], n.nave, seg=20, linea=0.015)
        c.rotation_euler = (0, -math.pi / 2, 0)
        llama = objeto("llama", malla_bm("llama", lambda bm: bmesh.ops.create_cone(
            bm, cap_ends=False, segments=14, radius1=0.07, radius2=0.0, depth=0.4,
            matrix=Matrix.Translation((0, 0, 0.2)))), n.m_llama, n.nave, sombra=False)
        llama.location = (-0.9, 0, z)
        llama.rotation_euler = (0, -math.pi / 2, 0)
        llama.color = (1, 1, 1, 1)
        n.llamas.append(llama)

    # antenita con estrella
    esfera("antena_base", 0.06, (-0.47, 0, 0.4), toon("antena_base", "#F2A3C2"), padre=n.nave, u=12, v=8,
           linea=0.012)
    cilindro("antena", 0.022, 0.26, (-0.47, 0, 0.41), toon("antena", "#5FC2BA"), n.nave, seg=10, linea=0.01)
    estrella = figura_plana("estrella", [(x * 0.17, z * 0.17) for x, z in ESTRELLA5],
                            toon("estrella_antena", "#FFD34D", brillo=0.6), n.nave, grosor=0.05)
    estrella.location = (-0.47, 0, 0.73)
    contorno(estrella, 0.012)
    r = estrella.constraints.new("TRACK_TO")   # de frente a la cámara: nunca se ve de canto
    r.target, r.track_axis, r.up_axis = mirar, "TRACK_NEGATIVE_Y", "UP_Z"
    n.estrella = estrella
    return n
