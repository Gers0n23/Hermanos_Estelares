"""Piezas compartidas por las cinemáticas de planetas (presentación, despegue y viaje): el planeta
visto desde el espacio, cielos, estrellas, nubes, colinas, islas flotantes, modelos descargados
(Kenney, CC0) pasados al look pintado, llamas de la nave, velo de fundido, cámara y sol.

Se importa DESPUÉS de nave_comun (que vacía la escena):
    from nave_comun import *
    from planeta_comun import *
Los colores de cada planeta salen de scripts/nucleo/planeta_dibujado.gd (ESTILOS), para que el
planeta 3D sea el mismo que el niño toca en el Mapa Estelar.
"""
import math
import os
import random
from types import SimpleNamespace

import bmesh
import bpy
from mathutils import Matrix, Vector

from nave_comun import *  # noqa: F401,F403
from nave_comun import _MATS

REPO = os.path.abspath(os.path.join(AQUI, "..", ".."))
TERCEROS = os.path.join(REPO, "assets", "terceros")
DULCES = os.path.join(TERCEROS, "kenney", "food-kit", "modelos")
NATURALEZA = os.path.join(TERCEROS, "kenney", "nature-kit", "modelos")
MASCOTAS = os.path.join(TERCEROS, "kenney", "cube-pets", "modelos")

ARCOIRIS = ["#FF6B6B", "#FF9F4A", "#FFCB3D", "#7DD87A", "#6FD6E8", "#B48CE8"]
PLANETAS = {
    "arcoiris": {"nombre": "Arcoíris", "colores": ["#FF9EC7", "#FFB86B", "#FFE66B", "#8FE39A", "#7FD3FF", "#B69BFF"],
                 "atmosfera": "#FFF0FB"},
    "animalia": {"nombre": "Animalia", "colores": ["#C9DC6A", "#6FC24A", "#2F8A3E", "#6FC24A", "#C9DC6A", "#3F8FE0"],
                 "atmosfera": "#D5FFB8"},
    "melodia": {"nombre": "Melodía", "colores": ["#A06BFF", "#FF6BD6", "#FFF2FF", "#FF6BD6", "#A06BFF", "#7CF0DC"],
                "atmosfera": "#FF9EF0"},
    "cuenta_cuentas": {"nombre": "Cuenta-Cuentas", "colores": ["#26307A", "#4A6AE0", "#8FB0FF", "#FFF6B0", "#4A6AE0",
                                                             "#26307A"], "atmosfera": "#8FB8FF"},
    "letralandia": {"nombre": "Letralandia", "colores": ["#FFB35C", "#FF8A3D", "#FFE0A0", "#6FD6A0", "#FFB35C",
                                                         "#FF8A3D"], "atmosfera": "#FFD9A0"},
    "corazon": {"nombre": "Corazón", "colores": ["#FFB3D6", "#9FDCFF", "#FF5F9E", "#FFB3D6", "#9FDCFF", "#FF5F9E"],
                "atmosfera": "#FFE0F0"},
    # provisional (no está en planeta_dibujado.gd): el destino final, hasta que HE-131 le dé su forma
    "coleccionauta": {"nombre": "Planeta del Coleccionauta", "colores": ["#3F2F7A", "#6B4FC0", "#8FE36B", "#6B4FC0",
                                                                         "#3F2F7A", "#FFD35C"], "atmosfera": "#B8FF9A"},
}
ORDEN = ["arcoiris", "animalia", "melodia", "cuenta_cuentas", "letralandia", "corazon", "coleccionauta"]
ESPACIO = Vector((4000.0, 0.0, 0.0))     # el decorado del espacio vive lejos del de la superficie


# ----------------------------------------------------------------------------- cielo
def _rampa(nt, paradas):
    r = nt.nodes.new("ShaderNodeValToRGB")
    r.color_ramp.elements[0].position, r.color_ramp.elements[0].color = paradas[0][0], lin(paradas[0][1])
    r.color_ramp.elements[1].position, r.color_ramp.elements[1].color = paradas[-1][0], lin(paradas[-1][1])
    for pos, col in paradas[1:-1]:
        r.color_ramp.elements.new(pos).color = lin(col)
    return r


def cielo(paradas_superficie, paradas_espacio=((0.0, "#3B2F78"), (0.5, "#2A2260"), (1.0, "#17133F"))):
    """Mundo con dos cielos (espacio y superficie). Devuelve el zócalo que elige cuál se ve
    (0 = espacio, 1 = superficie); se anima con `escalon`."""
    mundo = bpy.data.worlds.new("cielo")
    ESC.world = mundo
    mundo.use_nodes = True
    nt = mundo.node_tree
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Generated"], sep.inputs[0])
    media = nt.nodes.new("ShaderNodeMath")          # el espacio usa toda la esfera: -1..1 → 0..1
    media.operation = "MULTIPLY_ADD"
    media.inputs[1].default_value, media.inputs[2].default_value = 0.5, 0.5
    nt.links.new(sep.outputs["Z"], media.inputs[0])
    r_esp, r_sup = _rampa(nt, paradas_espacio), _rampa(nt, paradas_superficie)
    nt.links.new(media.outputs[0], r_esp.inputs[0])
    nt.links.new(sep.outputs["Z"], r_sup.inputs[0])
    mez = nt.nodes.new("ShaderNodeMix")
    mez.data_type = "RGBA"
    nt.links.new(r_esp.outputs[0], mez.inputs[6])
    nt.links.new(r_sup.outputs[0], mez.inputs[7])
    nt.links.new(mez.outputs[2], nt.nodes["Background"].inputs["Color"])
    return mez.inputs[0]


def escalon(zocalo, cuadro, antes, despues):
    """Cambia un valor de golpe en `cuadro` (para los cortes escondidos tras el velo)."""
    clave_nodo(zocalo, cuadro - 1, antes)
    clave_nodo(zocalo, cuadro, despues)
    for fc in zocalo.id_data.animation_data.action.fcurves:
        for k in fc.keyframe_points:
            k.interpolation = "CONSTANT"


def estrellas(nombre, centro, mirando_desde, n=140, grandes=14, radio=220, az=(-1.5, 1.5), el=(-0.6, 0.9),
              mat=None, tam=1.0):
    """Estrellas gorditas de cinco puntas más puntitos, en un casquete alrededor de `centro`."""
    centro, mirando_desde = Vector(centro), Vector(mirando_desde)
    mat = mat or mat_estrella()

    def _malla(bm):
        for i in range(n):
            a, e = random.uniform(*az), random.uniform(*el)
            p = centro + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * radio
            puntas = 5 if i < grandes else 4
            r = (random.uniform(1.8, 3.4) if i < grandes else random.uniform(0.3, 0.8)) * tam
            giro = (mirando_desde - p).to_track_quat("Z", "Y").to_matrix().to_4x4()
            mtx = Matrix.Translation(p) @ giro @ Matrix.Rotation(random.uniform(-0.3, 0.3), 4, "Z")
            vs = []
            for k in range(puntas * 2):
                rr = r if k % 2 == 0 else r * (0.55 if puntas == 5 else 0.9)
                ang = math.pi / 2 + k * math.pi / puntas
                vs.append(bm.verts.new(mtx @ Vector((rr * math.cos(ang), rr * math.sin(ang), 0))))
            bm.faces.new(vs)

    return objeto(nombre, malla_bm(nombre, _malla), mat, suave=False, sombra=False)


def mat_estrella():
    return mat("estrella", brillante, "#FFD86B", 1.6)


# ----------------------------------------------------------------------------- nubes, colinas, islas
def mat_nube(nombre="nube", color="#FFFFFF", tinte="#E3D3F2"):
    return mat(nombre, toon, color, tinte=tinte, umbral=(0.38, 0.46))


def nube(pos, tam, material=None, padre=None, bolas=4, sombra=False):
    """Nube gordita de base plana, como las del mapa del juego. Mira hacia -Y."""
    material = material or mat_nube()

    def _malla(bm):
        for k in range(bolas):
            t = (k - (bolas - 1) / 2) / max(1, (bolas - 1) / 2)
            r = tam * (1.0 - 0.42 * abs(t)) * random.uniform(0.9, 1.08)
            p = Vector((t * tam * 1.35, random.uniform(-0.1, 0.1) * tam, r * 0.62))
            bmesh.ops.create_uvsphere(bm, u_segments=28, v_segments=16, radius=r, matrix=Matrix.Translation(p))
        bmesh.ops.create_uvsphere(bm, u_segments=28, v_segments=12, radius=tam,     # base aplastada
                                  matrix=Matrix.Translation((0, 0, tam * 0.18)) @ Matrix.Diagonal((2.3, 1.0, 0.34, 1)))

    o = objeto("nube", malla_bm("nube", _malla), material, padre, sombra=sombra)
    o.location = pos
    return o


class Terreno:
    """Colinas redondas (esferas aplastadas). Sabe la altura del suelo en cada punto para posar cosas."""

    def __init__(self):
        self.colinas = []

    def colina(self, x, y, z, radio, aplastado, color, tinte="#C9B8E8", linea=0.0):
        m = mat("colina_" + color, toon, color, tinte=tinte, umbral=(0.30, 0.42))
        o = esfera("colina", radio, (x, y, z), m, escala=(1, 1, aplastado), u=96, v=48, linea=linea)
        self.colinas.append((x, y, z, radio, aplastado))
        return o

    def altura(self, x, y):
        mejor = -1e9
        for cx, cy, cz, r, s in self.colinas:
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 < r * r:
                mejor = max(mejor, cz + s * math.sqrt(r * r - d2))
        return mejor

    def sobre(self, x, y, extra=0.0):
        return Vector((x, y, self.altura(x, y) + extra))


def isla_flotante(pos, radio, color_pasto="#9ADF8A", color_tierra="#A9683F", padre=None):
    """Islote flotante: tapa de pasto con borde ondulado y cono de tierra debajo."""
    r = radio
    e = vacio("isla", padre, pos)
    torno("isla_tierra", [(0, -1.25 * r), (0.30 * r, -1.0 * r), (0.62 * r, -0.55 * r), (0.86 * r, -0.12 * r),
                          (0.90 * r, 0.0)], mat("tierra_" + color_tierra, toon, color_tierra), e, seg=28, linea=0.05)
    torno("isla_pasto", [(0.93 * r, -0.16 * r), (1.04 * r, -0.05 * r), (1.02 * r, 0.10 * r), (0.80 * r, 0.20 * r),
                         (0, 0.24 * r)], mat("pasto_" + color_pasto, toon, color_pasto, brillo=0.2), e, seg=28,
          linea=0.05)
    return e


def arco_bandas(nombre, r_ext, ancho, colores, a0=0.0, a1=math.pi, padre=None, seg=48, grosor=0.0, fuerza=None):
    """Arco de bandas de color (arcoíris, anillos) en el plano XZ, de cara a -Y. Ángulos desde +X."""
    if fuerza is None:
        mats = [mat("banda_" + c, toon, c) for c in colores]
    else:
        mats = [mat(f"banda_luz_{c}_{fuerza}", brillante, c, fuerza) for c in colores]
    n = len(colores)
    verts, caras, indices = [], [], []
    for i in range(n + 1):
        r = r_ext - ancho * i / n
        for s in range(seg + 1):
            a = a0 + (a1 - a0) * s / seg
            verts.append((r * math.cos(a), 0.0, r * math.sin(a)))
    for i in range(n):
        for s in range(seg):
            a = i * (seg + 1) + s
            caras.append((a, a + 1, a + seg + 2, a + seg + 1))
            indices.append(i)
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], caras)
    for p, i in zip(me.polygons, indices):
        p.material_index = i
    o = objeto(nombre, me, mats, padre, suave=False, sombra=False)
    for m in mats:
        m.use_backface_culling = False
    if grosor:
        so = o.modifiers.new("grosor", "SOLIDIFY")
        so.thickness, so.offset = grosor, 0.0
    return o


# ----------------------------------------------------------------------------- modelos descargados
def _toon_desde(original, matiz=None, brillo=0.25, colores=None):
    """Convierte un material importado (glTF) al sombreado toon, conservando su color o su textura.
    matiz=(tono, saturación, valor) lo retoca (0.5, 1, 1 = sin cambio)."""
    base = original.name.split(".")[0]
    fijo = (colores or {}).get(base)
    llave = f"imp_{base if fijo else original.name}_{matiz}_{fijo}"
    if llave in _MATS:
        return _MATS[llave]
    color, imagen = (0.8, 0.8, 0.8, 1.0), None
    bsdf = next((n for n in original.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None) \
        if original.use_nodes else None
    if bsdf:
        zoc = bsdf.inputs["Base Color"]
        color = tuple(zoc.default_value)
        if zoc.is_linked and zoc.links[0].from_node.type == "TEX_IMAGE":
            imagen = zoc.links[0].from_node.image
    m = toon(llave, "#FFFFFF", brillo=brillo)
    nt = m.node_tree
    rgb = nt.nodes["color"]
    rgb.outputs[0].default_value = lin(fijo) if fijo else color
    if fijo:
        imagen = None
    fuente = rgb.outputs[0]
    if imagen:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image, tex.interpolation = imagen, "Closest"
        fuente = tex.outputs["Color"]
    if matiz:
        hsv = nt.nodes.new("ShaderNodeHueSaturation")
        hsv.inputs["Hue"].default_value, hsv.inputs["Saturation"].default_value = matiz[0], matiz[1]
        hsv.inputs["Value"].default_value = matiz[2]
        nt.links.new(fuente, hsv.inputs["Color"])
        fuente = hsv.outputs["Color"]
    if fuente is not rgb.outputs[0]:
        for enlace in list(rgb.outputs[0].links):
            if enlace.to_node.type != "HUE_SAT":        # el propio retoque de matiz se alimenta del color
                nt.links.new(fuente, enlace.to_socket)
    _MATS[llave] = m
    return m


def modelo(ruta, alto=1.0, pos=(0, 0, 0), padre=None, giro=0.0, linea=0.03, matiz=None, sombra=True,
           por="alto", redondear=0, colores=None):
    """Importa un .glb (p. ej. del Food Kit de Kenney), lo deja de pie sobre `pos` con altura `alto`
    (por="mayor": `alto` es su dimensión más grande), lo pasa al look pintado y le pone contorno.
    redondear=N suelda los vértices y lo suaviza N niveles: el low-poly anguloso queda gordito,
    como los dulces del mapa. Devuelve el vacío que lo contiene."""
    if not os.path.isabs(ruta):
        ruta = os.path.join(DULCES, ruta)
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ruta)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    bpy.context.view_layer.update()
    mallas = [o for o in nuevos if o.type == "MESH"]
    pts = [o.matrix_world @ Vector(c) for o in mallas for c in o.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    s = alto / max(1e-6, max(mx - mn) if por == "mayor" else mx.z - mn.z)
    # escala real de cada malla (los modelos con esqueleto traen padres escalados ×100 o ×0,01)
    escala_mundo = {o: max(1e-9, max(abs(c) for c in o.matrix_world.to_scale())) for o in mallas}
    nombre = os.path.splitext(os.path.basename(ruta))[0]
    raiz = vacio(nombre, padre, pos)
    raiz.rotation_euler = (0, 0, giro)
    cont = vacio(nombre + "_escala", raiz, (-(mn.x + mx.x) / 2 * s, -(mn.y + mx.y) / 2 * s, -mn.z * s))
    cont.scale = (s, s, s)
    for o in nuevos:
        if o.parent is None:
            o.parent = cont
    for o in mallas:
        ranuras = [_toon_desde(r.material, matiz, colores=colores) if r.material else None for r in o.material_slots]
        o.data.materials.clear()
        for m in ranuras:
            o.data.materials.append(m or mat("gris", toon, "#CCCCCC"))
        o.visible_shadow = sombra
        if redondear:
            bm = bmesh.new()
            bm.from_mesh(o.data)
            bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
            bm.to_mesh(o.data)
            bm.free()
            o.data.polygons.foreach_set("use_smooth", [True] * len(o.data.polygons))
            sub = o.modifiers.new("redondear", "SUBSURF")
            sub.levels = sub.render_levels = redondear
        if linea:
            contorno(o, linea / (s * escala_mundo[o]))
            o.modifiers["contorno"].use_even_offset = False     # evita picos en las puntas del low-poly
    raiz["alto"] = alto
    return raiz


# ----------------------------------------------------------------------------- el planeta desde el espacio
def planeta_orbita(ident, radio, pos, inclinacion=0.32):
    """El planeta como bola de franjas con su atmósfera y sus adornos. Devuelve (raíz, bola):
    la raíz no gira (lleva los adornos), la bola sí."""
    datos = PLANETAS[ident]
    colores = datos["colores"]
    raiz = vacio("planeta_" + ident, None, pos)
    n_pts, por_banda = 37, 3
    perfil = [(radio * math.sin(math.pi * k / (n_pts - 1)), -radio * math.cos(math.pi * k / (n_pts - 1)))
              for k in range(n_pts)]
    perfil[0], perfil[-1] = (0.0, -radio), (0.0, radio)
    mats = [mat(f"planeta_{ident}_{i}", toon, c, tinte="#C4B2EC", umbral=(0.14, 0.22)) for i, c in enumerate(colores)]
    franjas = [((n_pts - 2 - k) // por_banda) % len(colores) for k in range(n_pts - 1)]
    eje = vacio("planeta_eje", raiz)
    eje.rotation_euler = (inclinacion * 0.5, inclinacion, 0)
    bola = torno("planeta_bola", perfil, mats, eje, seg=72, mats_seg=franjas, linea=radio * 0.012)
    bola.visible_shadow = False
    m_atm = mat("atmosfera_" + ident, halo, datos["atmosfera"], 0.0, 0.55, 1.1)
    esfera("atmosfera", radio * 1.07, (0, 0, 0), m_atm, padre=raiz, u=48, v=24, sombra=False)
    # nubecitas pegadas a la bola: hacen visible el giro
    m_n = mat_nube("nube_planeta", "#FFFFFF", "#D9C8F0")
    for k in range(7):
        lat, lon = random.uniform(-0.75, 0.75), 2 * math.pi * k / 7 + random.uniform(-0.3, 0.3)
        d = Vector((math.cos(lat) * math.cos(lon), math.cos(lat) * math.sin(lon), math.sin(lat)))
        o = esfera("nubecita_planeta", radio * random.uniform(0.10, 0.16), d * radio * 0.99, m_n,
                   escala=(1.7, 1.0, 0.55), padre=bola, u=16, v=10, sombra=False)
        o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    if ident == "arcoiris":     # su arcoíris por detrás y dos nubes a los pies del arco
        arco = arco_bandas("arcoiris_planeta", radio * 1.42, radio * 0.45, ARCOIRIS, padre=raiz, fuerza=1.0)
        arco.location = (0, radio * 0.05, 0)
        for lado in (-1, 1):
            nube((lado * radio * 1.22, -radio * 0.1, -radio * 0.16), radio * 0.2, padre=raiz)
    if ident == "animalia":     # animalitos asomados por arriba
        for i, (animal, alto) in enumerate((("giraffe", 0.62), ("cat", 0.36), ("dog", 0.42), ("lion", 0.40),
                                            ("bunny", 0.34))):
            ang = math.radians(144 - i * 27)
            o = modelo(os.path.join(MASCOTAS, f"animal-{animal}.glb"), alto=radio * alto, padre=raiz, redondear=1,
                       pos=(radio * 0.93 * math.cos(ang), radio * 0.12, radio * 0.93 * math.sin(ang)),
                       linea=radio * 0.012, sombra=False)
            o.rotation_euler = (0, math.pi / 2 - ang, 0)
    if ident == "melodia":      # anillo de neón, como un disco, y notas alrededor
        anillo = arco_bandas("anillo_melodia", radio * 1.75, radio * 0.42, ["#FF6BD6", "#FFF2FF", "#7CF0DC", "#A06BFF"],
                             a0=0.0, a1=2 * math.pi, padre=raiz, seg=96, fuerza=1.0)
        anillo.rotation_euler = (1.25, 0.28, 0)
        for i, ang in enumerate((2.5, 1.9, 1.2, 0.6)):
            nota_musical((radio * 1.3 * math.cos(ang), -radio * 0.3, radio * 1.3 * math.sin(ang)), radio * 0.13,
                         NEON[i], padre=raiz, doble=i % 2 == 1)
    if ident == "cuenta_cuentas":       # números que le dan la vuelta, y su lunita
        for i, (txt, ang) in enumerate((("1", 2.55), ("2", 1.95), ("3", 1.25), ("+", 0.6))):
            texto_3d(txt, radio * 0.34, (radio * 1.32 * math.cos(ang), -radio * 0.3, radio * 1.32 * math.sin(ang)
                                         - radio * 0.15), CUENTA[i], padre=raiz, linea=0.0, fondo=0.08, luz=1.2)
        esfera("lunita", radio * 0.2, (radio * 1.45, -radio * 0.2, -radio * 0.55), mat("luna", brillante, "#FFF6B0",
                                                                                       1.25), padre=raiz, sombra=False)
    if ident == "letralandia":      # letras que le dan la vuelta
        for i, (txt, ang) in enumerate((("A", 2.55), ("B", 1.95), ("C", 1.25), ("a", 0.6))):
            texto_3d(txt, radio * 0.34, (radio * 1.32 * math.cos(ang), -radio * 0.3, radio * 1.32 * math.sin(ang)
                                         - radio * 0.15), LETRAS[i], padre=raiz, linea=0.0, fondo=0.08, luz=1.2)
    if ident == "corazon":          # corazones alrededor y una nubecita
        for i, (ang, tam) in enumerate(((2.6, 0.26), (1.9, 0.36), (1.2, 0.28), (0.5, 0.22))):
            o = _suelto("corazon", radio * tam, (radio * 1.3 * math.cos(ang), -radio * 0.3, radio * 1.3 * math.sin(ang)
                                                 - radio * 0.2), padre=raiz, redondear=2, linea=radio * 0.01,
                        sombra=False, colores={"Red": ROSAS[i]})
            o.rotation_euler = (0, (math.pi / 2 - ang) * 0.4, 0)
            for malla in mallas_de(o):          # en el espacio brillan, como los números y las letras
                malla.data.materials[0] = mat("corazon_luz_" + ROSAS[i], brillante, ROSAS[i], 1.15)
        nube((radio * 1.3, -radio * 0.2, -radio * 0.62), radio * 0.17, padre=raiz)
    return raiz, bola


# ----------------------------------------------------------------------------- la nave en vuelo
def llamas_nave(n, radio=0.25):
    """Tres llamas de dibujo animado en las toberas. Devuelve la lista: se animan por `scale`
    (x = y = ancho, z = largo) y se apagan con `apagar`."""
    if "llama" not in _MATS:
        m = bpy.data.materials.new("llama")
        m.use_nodes = True
        m.surface_render_method = "BLENDED"
        nt = m.node_tree
        nt.nodes.remove(nt.nodes["Principled BSDF"])
        coord = nt.nodes.new("ShaderNodeTexCoord")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        r_col = nt.nodes.new("ShaderNodeValToRGB")
        r_col.color_ramp.interpolation = "CONSTANT"
        r_col.color_ramp.elements[0].color = lin("#FF8A3C")
        r_col.color_ramp.elements[1].position, r_col.color_ramp.elements[1].color = 0.84, lin("#FFF6C8")
        r_col.color_ramp.elements.new(0.50).color = lin("#FFC94A")
        r_alf = nt.nodes.new("ShaderNodeValToRGB")
        r_alf.color_ramp.elements[0].position, r_alf.color_ramp.elements[1].position = 0.0, 0.12
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
        nt.links.new(mez.outputs[0], m.node_tree.nodes["Material Output"].inputs["Surface"])
        _MATS["llama"] = m
    llamas = []
    for y, z in TOBERAS:
        me = malla_bm("llama", lambda bm: bmesh.ops.create_cone(
            bm, cap_ends=False, segments=20, radius1=0.0, radius2=radio, depth=1.0,
            matrix=Matrix.Translation((0, 0, -0.5))))
        o = objeto("llama", me, _MATS["llama"], n.nave, sombra=False)
        o.location = (-1.92, y, z)
        o.rotation_euler = (0, math.pi / 2, 0)      # su -Z local apunta hacia atrás de la nave
        llamas.append(o)
    return llamas


def animar_llamas(llamas, claves, temblor_hasta):
    """claves: [(cuadro, largo, ancho), ...]; largo 0 = apagada."""
    for o in llamas:
        for f, largo, ancho in claves:
            clave(o, "scale", f, (ancho, ancho, largo))
        ruido(o, "scale", 2, 0.35, 1.6, temblor_hasta)
        ruido(o, "scale", 0, 0.12, 1.3, temblor_hasta)


def visible(o, desde=None, hasta=None, hijos=True):
    """El objeto (y sus hijos) solo se ve entre `desde` y `hasta` (cuadros, inclusive / exclusive)."""
    for h in [o] + (list(o.children_recursive) if hijos else []):
        if desde is not None:
            clave(h, "hide_render", desde - 1, True)
            clave(h, "hide_render", desde, False)
        if hasta is not None:
            clave(h, "hide_render", hasta - 1, False)
            clave(h, "hide_render", hasta, True)


# ----------------------------------------------------------------------------- cámara, sol y velo
def camara(lente=32, alcance=900):
    cam = bpy.data.cameras.new("camara")
    cam.lens, cam.clip_start, cam.clip_end = lente, 0.05, alcance
    o_cam = bpy.data.objects.new("camara", cam)
    COL.objects.link(o_cam)
    ESC.camera = o_cam
    mira = vacio("mira")
    seguir = o_cam.constraints.new("TRACK_TO")
    seguir.target, seguir.track_axis, seguir.up_axis = mira, "TRACK_NEGATIVE_Z", "UP_Y"
    return o_cam, mira, cam


def sol(direccion=(0.62, 0.50, -0.60), energia=1.6):
    luz = bpy.data.lights.new("sol", "SUN")
    luz.energy, luz.color, luz.angle = energia, (1.0, 1.0, 1.0), 0.02
    o = bpy.data.objects.new("sol", luz)
    COL.objects.link(o)
    apuntar(o, direccion)
    return o


def velo(o_cam, color="#FFFFFF"):
    """Plano pegado a la cámara para fundir a blanco (nubes) y esconder un corte.
    Se anima con `fundido`."""
    me = malla_bm("velo", lambda bm: bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=1.0))
    o = objeto("velo", me, con_alfa("velo", color, 1.0), o_cam, suave=False, sombra=False)
    o.location = (0, 0, -0.2)
    o.color = (1, 1, 1, 0)
    return o


def fundido(o_velo, claves):
    """claves: [(cuadro, opacidad), ...]"""
    for f, a in claves:
        clave(o_velo, "color", f, (1, 1, 1, a))
    visible(o_velo, desde=claves[0][0], hasta=claves[-1][0] + 1, hijos=False)


# ----------------------------------------------------------------------------- superficies (un kit por planeta)
# Cada kit construye el decorado de la superficie alrededor del origen y devuelve:
#   cielo (paradas del degradado), cam / mira / lente (encuadre final, el del mapa del planeta),
#   posar (x, y), giro_nave y escala_nave (dónde queda estacionada la nave), terreno.
def chupetin(t, x, y, alto, tono, giro=0.0):
    giro += math.pi / 2 + math.atan2(-x, y + 26.0)        # el disco mira a +X: de cara a la cámara del encuadre final
    return modelo("lollypop.glb", alto=alto, pos=t.sobre(x, y, -0.05), giro=giro, redondear=2,
                  matiz=(tono, 1.0, 1.1), linea=0.035)


def superficie_arcoiris():
    """La Isla de los Dulces vista desde el suelo, como el mapa del planeta
    (assets/sprites/planetas/arcoiris/mapa): colinas pastel, frutilla, gelatina, chupetines,
    islotes flotantes y la torta con su arcoíris en la cima."""
    k = SimpleNamespace()
    k.cielo = [(0.0, "#FFE9D6"), (0.06, "#FFDCC9"), (0.12, "#F2BFD3"), (0.19, "#C39DD6"), (0.28, "#8F78C4"),
               (0.42, "#6A58AC"), (1.0, "#4A3F82")]
    k.cam, k.mira, k.lente = (0.0, -26.0, 4.2), (0.0, 10.0, 5.6), 32
    t = k.terreno = Terreno()
    t.colina(10, 78, -16, 62, 0.40, "#DCCBEF")      # lomas lejanas lilas
    t.colina(-10, 44, -12, 40, 0.46, "#CFE0F6")     # loma celeste
    t.colina(-27, 17, -10, 26, 0.62, "#FFC6DD")     # loma rosa
    t.colina(27, 30, -7, 17, 0.95, "#DACDF2")       # la cima (crema lila)
    t.colina(-3, 8, -8, 16, 0.76, "#FFEBAA")        # loma amarilla (gelatina)
    t.colina(18, 6, -10, 26, 0.50, "#BFECDA")       # loma menta
    t.colina(-4, -6, -10, 34, 0.36, "#D8F0B6")      # prado
    t.colina(0, -18, -9.6, 30, 0.35, "#FFE4D0")     # primer plano durazno

    # zona 1: la frutilla gigante sobre su trébol de gomita
    px, py = -4.0, -12.0
    for a in range(3):
        ang = math.pi / 2 + a * 2 * math.pi / 3
        esfera("trebol", 0.95, t.sobre(px + 0.85 * math.cos(ang), py + 0.85 * math.sin(ang), 0.05),
               mat("trebol", toon, "#8FD98A", brillo=0.3), escala=(1, 1, 0.28), u=20, v=10, linea=0.03)
    modelo("strawberry.glb", alto=2.7, pos=t.sobre(px, py, 0.2), redondear=2, matiz=(0.475, 1.0, 1.02),
           linea=0.02, giro=0.4)
    # zona 2: la gelatina de limón en su plato
    gx, gy = -3.4, 5.0
    cilindro("plato", 2.6, 0.22, t.sobre(gx, gy, -0.1), mat("plato", toon, "#FF9EC7", brillo=0.3), seg=40,
             linea=0.04)
    k.gelatina = modelo("pudding.glb", alto=3.3, pos=t.sobre(gx, gy, 0.1), redondear=2,
                        matiz=(0.57, 1.25, 1.75), linea=0.04)
    # zona 3: tres chupetines de espiral
    chupetin(t, 3.2, -8.5, 3.3, 0.18, 0.2)
    chupetin(t, 1.6, -9.6, 2.1, 0.30, -0.3)
    chupetin(t, 4.9, -9.4, 2.2, 0.40, 0.4)
    # chupetines, helados y casitas-cupcake repartidos por las lomas
    for x, y, alto, tono in ((-13, -2, 3.6, 0.50), (-9.5, 6, 2.6, 0.62), (-17, 8, 4.2, 0.30), (9, 2, 3.0, 0.75),
                             (14, 8, 4.0, 0.50), (22, 2, 4.6, 0.56), (-22, 14, 4.4, 0.66), (3.5, 14, 2.6, 0.22),
                             (11, 22, 3.4, 0.40), (-6, 24, 3.2, 0.50)):
        chupetin(t, x, y, alto, tono, random.uniform(-0.25, 0.25))
    for x, y, alto in ((-15.5, 4, 2.2), (2.0, 6.5, 1.9), (-10, 14, 2.4)):
        modelo("ice-cream.glb", alto=alto, pos=t.sobre(x, y, alto * 0.98), redondear=2,
               linea=0.03).rotation_euler = (math.pi, 0, 0)       # cono al revés: gorrito de rayas
    for x, y, alto, tono in ((-8.5, 1.5, 1.7, 0.5), (6.5, 9, 1.6, 0.42), (17, 12, 2.4, 0.36)):
        modelo("cupcake.glb", alto=alto, pos=t.sobre(x, y, -0.05), redondear=2, matiz=(tono, 1.0, 1.15),
               linea=0.03, giro=random.uniform(-0.6, 0.6))
    for x, y, alto in ((5.6, -12.5, 0.36), (-7.2, -10.5, 0.40), (9.0, -8.0, 0.36)):
        modelo("donut-sprinkles.glb", alto=alto, pos=t.sobre(x, y, -0.1), redondear=2, linea=0.025)
    esfera("laguna", 3.4, t.sobre(9.5, -3.0, 0.02), mat("laguna", toon, "#A9DBF7", brillo=0.5),
           escala=(1.25, 0.8, 0.03), u=40, v=8, sombra=False)

    # zona 4: los islotes flotantes
    k.islas = []
    isla = isla_flotante((10.5, 14.0, 10.2), 4.0)
    modelo("whipped-cream.glb", alto=2.6, pos=(0, 0, 0.75), padre=isla, redondear=2, linea=0.04,
           matiz=(0.5, 0.6, 1.25))
    modelo("orange.glb", alto=1.3, pos=(3.4, -1.0, 3.6), padre=isla, redondear=2, linea=0.03)
    k.islas.append(isla)
    isla = isla_flotante((-17.5, 19.0, 9.6), 2.6)
    modelo("lollypop.glb", alto=2.6, pos=(0.4, 0, 0.5), padre=isla, redondear=2, matiz=(0.5, 1.0, 1.1),
           giro=math.pi / 2 + 0.5)
    k.islas.append(isla)
    isla = isla_flotante((-9.0, 32.0, 17.5), 1.9)
    modelo("cupcake.glb", alto=1.7, pos=(0, 0, 0.35), padre=isla, redondear=2, matiz=(0.42, 1.0, 1.15))
    k.islas.append(isla)

    # zona 5: la torta de tres pisos con cereza y su arcoíris, en la cima
    cima = t.sobre(27, 30, -0.1)
    arco = arco_bandas("arcoiris_cima", 8.0, 2.4, ARCOIRIS, fuerza=1.0)
    arco.location = cima + Vector((0, 1.6, -0.6))
    z = 0.0
    for ancho, tono in ((6.6, 0.42), (4.9, 0.50), (3.3, 0.42)):
        piso = modelo("cake.glb", alto=ancho, pos=cima + Vector((0, 0, z)), por="mayor", matiz=(tono, 0.9, 1.3),
                      linea=0.04, giro=0.5)
        z += ancho * 0.36
    modelo("cherries.glb", alto=1.9, pos=cima + Vector((0, 0, z - 0.1)), redondear=2, matiz=(0.5, 1.3, 1.2),
           linea=0.03)

    # nubes de algodón y estrellitas en lo alto
    k.nubes = [nube(p, tam) for p, tam in (((-20, 58, 21), 6.5), ((-4, 64, 15), 4.6), ((16, 60, 19.5), 5.2),
                                           ((41, 62, 20), 5.6), ((-44, 66, 26), 5.0))]
    estrellas("estrellas_cielo", (0, 0, 0), k.cam, n=70, grandes=5, radio=260, az=(-0.8, 0.8), el=(0.2, 0.75),
              mat=mat("estrella_cielo", brillante, "#FFF6E0", 1.3), tam=0.5)
    k.posar, k.giro_nave, k.escala_nave = (-0.4, -12.6), math.pi + 0.14, 0.62
    return k


# El Nature Kit viene en turquesa y salmón: se repinta con la paleta del mapa de Animalia.
PALETA_NAT = {"leafsGreen": "#5FBF55", "leafsDark": "#3F9A4A", "grass": "#7CCB5A", "woodBark": "#9B6B47",
              "wood": "#C9955F", "woodDark": "#8A5A3C", "woodInner": "#F2DDBB", "stone": "#C9C4CF", "dirt": "#B9B3C2",
              "colorRed": "#F0606A", "colorYellow": "#FFD35C", "colorPurple": "#B48CE8", "colorTan": "#F2B56B",
              "_defaultMat": "#FFF6E6"}


def _nat(nombre, alto, pos, **k):
    k.setdefault("colores", PALETA_NAT)
    return modelo(os.path.join(NATURALEZA, nombre + ".glb"), alto=alto, pos=pos, **k)


def _animal(nombre, alto, pos, giro=0.0, **k):
    k.setdefault("redondear", 1)
    return modelo(os.path.join(MASCOTAS, f"animal-{nombre}.glb"), alto=alto, pos=pos, giro=giro, **k)


def superficie_animalia():
    """La selva de Toby vista desde el suelo, como el mapa del planeta
    (assets/sprites/planetas/animalia/mapa): campamento, laguna de nenúfares, pradera con acacia,
    el árbol de los nidos y el volcán del valle de los dinosaurios."""
    k = SimpleNamespace()
    k.cielo = [(0.0, "#FFF6D8"), (0.07, "#E4F5EC"), (0.18, "#B4E2F3"), (0.40, "#7CC9EC"), (1.0, "#4FA8E0")]
    k.cam, k.mira, k.lente = (0.0, -26.0, 4.2), (0.0, 10.0, 5.6), 32
    t = k.terreno = Terreno()
    verde = "#B6D8C9"
    t.colina(-46, 84, -16, 44, 0.62, "#CDEBD6", tinte=verde)    # cerros lejanos
    t.colina(8, 96, -18, 60, 0.45, "#D6F0DC", tinte=verde)
    t.colina(52, 84, -16, 46, 0.58, "#C6E8D0", tinte=verde)
    t.colina(-8, 36, -12, 46, 0.40, "#8FCF6C", tinte="#9CC7B0")      # franja de selva
    t.colina(25, 22, -8, 22, 0.72, "#A9DE7A", tinte="#9CC7B0")       # loma del árbol de los nidos
    t.colina(13, -8, -10, 22, 0.52, "#F4ECA2", tinte="#D9C9A0")      # pradera
    t.colina(-13, -8, -10, 24, 0.50, "#C0E88C", tinte="#9CC7B0")     # claro del campamento
    t.colina(0, -20, -9.6, 30, 0.35, "#93D36C", tinte="#9CC7B0")     # primer plano

    # zona 2: la laguna de los nenúfares
    lx, ly = 0.5, 3.0
    lz = t.altura(lx, ly) + 0.55
    esfera("laguna", 6.0, (lx, ly, lz), mat("laguna_selva", toon, "#8FD2F2", brillo=0.5), escala=(1.35, 0.8, 0.03),
           u=48, v=8, sombra=False)
    _nat("lily_large", 3.0, (lx - 0.5, ly - 0.6, lz + 0.12), por="mayor", linea=0.03)
    _nat("lily_small", 1.3, (lx + 3.6, ly - 1.6, lz + 0.12), por="mayor", linea=0.03)
    _nat("lily_small", 1.1, (lx - 4.2, ly - 1.0, lz + 0.12), por="mayor", linea=0.03, giro=1.0)
    # zona 1: el campamento de Toby
    carpa = _nat("tent_detailedOpen", 2.3, t.sobre(-5.6, -8.5, -0.05), giro=0.5, linea=0.04)
    est = figura_plana("estrella_carpa", [(x * 0.42, z * 0.42) for x, z in ESTRELLA5], mat_estrella(), carpa,
                       grosor=0.08)
    est.location = (0, -0.3, 2.75)
    _nat("campfire_logs", 0.9, t.sobre(-3.9, -10.6, -0.03), linea=0.02, por="mayor")
    # zona 3: la pradera de las jirafas, con su acacia
    _nat("tree_detailed", 4.6, t.sobre(6.4, -6.0, -0.1), linea=0.04)
    # zona 4: el árbol de los nidos
    _nat("tree_oak", 9.5, t.sobre(16.0, 22.0, -0.3), linea=0.06)
    # zona 5: el volcán del valle de los dinosaurios
    volcan = torno("volcan", [(8.5, 0.0), (5.6, 4.4), (3.6, 7.6), (2.7, 9.0), (2.2, 8.7), (0, 8.4)],
                   [mat("volcan", toon, "#D9966E", tinte="#B48AC0", brillo=0.2),
                    mat("lava", brillante, "#FFB24A", 1.6)], seg=28, mats_seg=[0, 0, 0, 1, 1], linea=0.07)
    volcan.location = t.sobre(35, 44, -1.0)
    volcan.scale = (1.4, 1.4, 1.4)
    # la selva: fila de árboles redondos y palmeras
    for i, x in enumerate(range(-34, 20, 6)):
        y = 22 + (i % 3) * 3
        _nat(("tree_default", "tree_oak", "tree_detailed")[i % 3], random.uniform(4.6, 6.2),
             t.sobre(x + random.uniform(-1, 1), y, -0.2), giro=random.uniform(0, 6), linea=0.05)
    for x, y, alto in ((-30, 33, 7.0), (-17, 31, 6.0), (-4, 34, 7.5), (9, 32, 6.5), (-24, 14, 6.0), (31, 30, 6.5),
                       (44, 34, 7.0), (15, 14, 5.0)):
        _nat("tree_palmDetailedTall", alto, t.sobre(x, y, -0.2), giro=random.uniform(0, 6), linea=0.05)
    # primer plano: hongos, piedras, flores y hojas grandes
    for nombre, x, y, alto in (("mushroom_red", -6.0, -12.0, 0.9), ("mushroom_redGroup", 3.4, -12.6, 0.8),
                               ("mushroom_tan", 7.0, -11.5, 0.8), ("rock_largeA", -1.2, -12.8, 0.5),
                               ("rock_largeB", 8.6, -8.5, 0.6), ("rock_largeC", -9.5, -7.0, 0.7),
                               ("flower_redA", -3.8, -11.5, 0.6), ("flower_yellowA", 5.2, -10.5, 0.6),
                               ("flower_purpleA", -7.5, -10.5, 0.6), ("flower_yellowA", -2.0, -3.0, 0.6),
                               ("flower_redA", 10.5, -4.5, 0.6), ("flower_purpleA", 3.5, -1.5, 0.6),
                               ("plant_bush", -11.5, -5.0, 1.3), ("plant_bushLarge", 13.5, -2.0, 1.6)):
        _nat(nombre, alto, t.sobre(x, y, -0.04), giro=random.uniform(0, 6), linea=0.025)
    for x, giro in ((-9.2, 0.4), (9.4, 2.6)):
        _nat("plant_flatTall", 2.6, t.sobre(x * 0.8, -15.0, -0.2), giro=giro, linea=0.04)
    # los animales (dan saltitos): Toby es un perrito, así que un perrito recibe a la nave
    k.vivos = [_animal("dog", 1.25, t.sobre(-2.4, -8.6), 0.4), _animal("giraffe", 2.2, t.sobre(8.4, -5.5), -0.5),
               _animal("bunny", 0.8, t.sobre(5.0, -11.6), -0.3), _animal("cat", 0.95, t.sobre(-8.4, -9.2), 0.6),
               _animal("elephant", 2.3, t.sobre(-8.5, 5.5), 0.5), _animal("lion", 1.6, t.sobre(13.5, -4.5), -0.6),
               _animal("monkey", 1.5, t.sobre(12.5, 17.0), -0.4)]
    k.nubes = [nube(p, tam) for p, tam in (((-30, 70, 24), 6.5), ((2, 74, 30), 5.0), ((26, 70, 22), 5.6),
                                           ((-52, 74, 17), 5.2))]
    k.posar, k.giro_nave, k.escala_nave = (1.2, -8.2), math.pi + 0.14, 0.62
    return k


# ----------------------------------------------------------------------------- vida del decorado
def dar_vida(K, f_ini, f_fin, f_fiesta=None):
    """Anima lo que cada decorado tenga de vivo entre f_ini y f_fin. En f_fiesta (cuando la nave
    toca el suelo; None = sin ese momento, 0 = fiesta desde el principio) saltan todos de alegría."""
    fiesta = f_fin + 1 if f_fiesta is None else f_fiesta
    # los islotes, discos, notas y burbujas flotan
    for i, isla in enumerate(getattr(K, "islas", [])):
        z0 = isla.location.z
        for f in range(f_ini, f_fin + 24, 24):
            clave(isla, "location", f, (isla.location.x, isla.location.y, z0 + 0.22 * math.sin(f / 24 * 1.6 + i * 2)))
    # la gelatina tiembla cuando la nave toca el suelo
    if hasattr(K, "gelatina") and f_fiesta:
        for df, e in ((0, (1, 1, 1)), (4, (1.08, 1.08, 0.90)), (9, (0.94, 0.94, 1.08)), (15, (1.04, 1.04, 0.96)),
                      (21, (0.98, 0.98, 1.02)), (27, (1, 1, 1))):
            clave(K.gelatina, "scale", fiesta + df, e)
    # los animalitos dan saltitos, cada uno a su ritmo; en la fiesta saltan todos más alto y seguido
    for i, o in enumerate(getattr(K, "vivos", [])):
        z0 = o.location.z
        f = f_ini + 10 + i * 7
        while f < f_fin:
            salto = (0.9 if f > fiesta else 0.45) * o["alto"] * 0.3
            for df, dz in ((0, 0.0), (5, salto), (10, 0.0)):
                clave(o, "location", f + df, (o.location.x, o.location.y, z0 + dz))
            f += 16 if f > fiesta else 30 + (i * 5) % 11
    # lo que late con la música (barras del ecualizador) y las teclas que se hunden por turno
    for o in getattr(K, "late", []):
        for f in range(f_ini, f_fin + 8, 8):
            clave(o, "scale", f, (1, 1, random.uniform(0.4, 1.0)))
    for i, o in enumerate(getattr(K, "teclas", [])):
        z0 = o.location.z
        f = f_ini + i * 3
        while f < f_fin:
            for df, dz in ((0, 0.0), (3, 0.22), (8, 0.0)):
                clave(o, "location", f + df, (o.location.x, o.location.y, z0 + dz))
            f += 60
    # Mimi respira: se infla y se desinfla despacio
    if hasattr(K, "mimi"):
        for f in range(f_ini, f_fin + 30, 30):
            e = 1.0 + (0.10 if (f - f_ini) // 30 % 2 else 0.0)
            clave(K.mimi, "scale", f, (e, e, e))


# ----------------------------------------------------------------------------- Melodía
SUELTOS = os.path.join(TERCEROS, "polypizza", "modelos")      # modelos sueltos de Poly Pizza (ver ATRIBUCIONES.md)
NEON = ["#FF6BD6", "#7CF0DC", "#FFE66B", "#A06BFF", "#6FD6FF", "#FF9EC7"]


def _suelto(nombre, alto, pos, **k):
    return modelo(os.path.join(SUELTOS, nombre + ".glb"), alto=alto, pos=pos, **k)


def nota_musical(pos, tam, color, padre=None, doble=False):
    """Nota musical gordita y luminosa (corchea, o dos corcheas unidas). Mira hacia -Y."""
    m = mat("nota_" + color, brillante, color, 1.3)
    e = vacio("nota", padre, pos)
    for dx in ((0.0, 1.5) if doble else (0.0,)):
        c = esfera("nota_cabeza", tam * 0.5, (dx * tam, 0, 0), m, escala=(1.25, 0.6, 0.9), padre=e, sombra=False)
        c.rotation_euler = (0, -0.35, 0)
        caja("nota_palo", (dx * tam + tam * 0.42, -tam * 0.07, 0), (dx * tam + tam * 0.58, tam * 0.07, tam * 2.1), m, e)
    if doble:
        caja("nota_barra", (tam * 0.42, -tam * 0.07, tam * 1.75), (tam * 2.08, tam * 0.07, tam * 2.1), m, e)
    else:
        caja("nota_bandera", (tam * 0.5, -tam * 0.07, tam * 1.6), (tam * 1.2, tam * 0.07, tam * 2.1), m, e)
    for o in e.children:
        o.visible_shadow = False
    return e


def superficie_melodia():
    """El planeta de la música de Octavio, el pulpo DJ: noche morada con luces de neón, un camino de
    teclas de piano, instrumentos gigantes como árboles, discos que flotan y un ecualizador al fondo."""
    k = SimpleNamespace()
    k.cielo = [(0.0, "#FFB8E8"), (0.06, "#F08AE0"), (0.18, "#A866E8"), (0.42, "#5B3FC0"), (1.0, "#2A1F6E")]
    k.cam, k.mira, k.lente = (0.0, -26.0, 4.2), (0.0, 10.0, 5.6), 32
    t = k.terreno = Terreno()
    lila = "#7A5FD0"
    t.colina(-46, 84, -16, 44, 0.62, "#8E6FE0", tinte="#5B46B0")     # cerros lejanos
    t.colina(8, 96, -18, 60, 0.45, "#9C7BEA", tinte="#5B46B0")
    t.colina(52, 84, -16, 46, 0.58, "#8463D8", tinte="#5B46B0")
    t.colina(-8, 36, -12, 46, 0.40, "#B58BF5", tinte=lila)           # franja media
    t.colina(25, 22, -8, 22, 0.72, "#FF9EDC", tinte="#B070D0")       # loma del piano
    t.colina(13, -8, -10, 22, 0.52, "#C9A2FF", tinte=lila)
    t.colina(-13, -8, -10, 24, 0.50, "#E0A8FF", tinte=lila)          # el escenario de Octavio
    t.colina(0, -20, -9.6, 30, 0.35, "#B690F8", tinte=lila)          # primer plano

    # ecualizador gigante al fondo: barras de neón que suben y bajan con la música
    k.late = []
    for i, x in enumerate(range(-52, 56, 4)):
        alto = random.uniform(9, 22)
        o = caja("barra_eq", (-1.4, -1.0, 0), (1.4, 1.0, alto),
                 mat(f"neon_{NEON[i % 6]}", brillante, NEON[i % 6], 1.15))
        o.location, o.visible_shadow = (x, 62 + (i % 2) * 2, 4.0), False
        k.late.append(o)

    # camino de teclas de piano que cruza el valle
    m_blanca = mat("tecla_blanca", toon, "#FFFFFF", tinte="#D9C2FF", brillo=0.3)
    m_negra = mat("tecla_negra", toon, "#3B2A7A", tinte="#241A55")
    k.teclas = []
    n_teclas = 30
    for i in range(n_teclas):
        s = i / (n_teclas - 1)
        x = -15 + 31 * s
        y = 1.5 + 4.5 * math.sin(s * math.pi * 1.6 - 0.4)
        dy = 4.5 * math.pi * 1.6 / 31 * math.cos(s * math.pi * 1.6 - 0.4)
        giro = math.atan(dy)
        m = mat(f"tecla_{NEON[i // 4 % 6]}", brillante, NEON[i // 4 % 6], 1.0) if i % 4 == 2 else m_blanca
        o = caja("tecla", (-0.48, -1.5, 0), (0.48, 1.5, 0.3), m, linea=0.03)
        o.location, o.rotation_euler = t.sobre(x, y, -0.02), (0, 0, giro)
        k.teclas.append(o)
        if i % 7 not in (2, 6) and i < n_teclas - 1:
            n = caja("tecla_n", (-0.3, 0.1, 0.3), (0.3, 1.5, 0.55), m_negra, o)
            n.location = (0.52, 0, 0)

    # el escenario de Octavio: tornamesa, parlantes y el pulpo DJ encima
    c_parl = {"02___Default": "#5A3FB8", "03___Default": "#FFE66B", "07___Default": "#7CF0DC",
              "_crayfishdiffuse": "#FF6BD6", "_crayfishdiffuse-2": "#FF6BD6"}
    ex, ey = -6.4, -8.4
    _suelto("tocadiscos", 3.2, t.sobre(ex, ey, -0.05), por="mayor", giro=0.25, linea=0.04)
    for dx, alto in ((-3.0, 3.6), (3.0, 3.2)):
        _suelto("parlante", alto, t.sobre(ex + dx, ey + 1.6, -0.05), colores=c_parl, giro=-math.pi / 2 + (0.2 if dx < 0 else -0.2),
                linea=0.04)
    octavio = _suelto("pulpo", 2.5, t.sobre(ex, ey + 0.6, 0.9), giro=0.2, linea=0.035, matiz=(0.42, 1.05, 1.1))
    _suelto("microfono", 2.4, t.sobre(ex - 4.6, ey - 1.6, -0.05), linea=0.03)

    # instrumentos gigantes, como árboles
    c_piano = {"_crayfishdiffuse": "#9A5BF0", "02___Default": "#FFFFFF"}
    c_tambor = {"02___Default": "#FFF2FF", "_crayfishdiffuse": "#FF6BD6"}
    _suelto("piano", 6.5, t.sobre(21.0, 20.0, -0.3), colores=c_piano, giro=math.pi - 0.4, linea=0.06)
    _suelto("arpa", 11.0, t.sobre(-21.0, 21.0, -0.3), giro=0.4, linea=0.06)
    _suelto("saxofon", 5.0, t.sobre(9.4, -3.6, -0.1), giro=math.pi / 2 - 0.3, linea=0.045)
    _suelto("guitarra_electrica", 6.5, t.sobre(14.5, 2.5, -0.1), giro=math.pi / 2 - 0.2, linea=0.05,
            colores={"FFFFFF": "#FF5FC4", "F44336": "#7CF0DC"})
    _suelto("violin", 5.2, t.sobre(-12.5, 0.5, -0.1), giro=0.3, linea=0.045)
    _suelto("trompeta", 3.4, t.sobre(-1.5, 6.5, 0.6), por="mayor", giro=0.6, linea=0.04)
    _suelto("xilofono", 4.2, t.sobre(4.0, 9.5, -0.05), por="mayor", giro=-0.4, linea=0.04)
    for x, y, alto, giro in ((-33, 30, 9.0, 0.5), (-10, 33, 8.0, -0.3), (5, 31, 9.5, 0.2), (36, 32, 8.5, -0.4)):
        _suelto(("guitarra", "saxofon", "violin", "guitarra_electrica")[int(abs(x)) % 4], alto, t.sobre(x, y, -0.3),
                giro=giro, linea=0.06)
    # tambores como hongos del primer plano, y maracas
    for x, y, d in ((-2.6, -13.0, 1.5), (4.0, -12.4, 1.2), (9.2, -9.6, 1.7), (-10.6, -6.0, 1.9)):
        _suelto("tambor", d, t.sobre(x, y, -0.05), por="mayor", colores=c_tambor, linea=0.03)
    _suelto("maracas", 1.5, t.sobre(6.4, -11.6, -0.03), giro=0.4, linea=0.03)
    _suelto("maracas", 1.3, t.sobre(-9.0, -11.2, -0.03), giro=-0.6, linea=0.03)

    # discos de vinilo y notas que flotan
    c_vinilo = {"02___Default": "#3B2A7A", "_crayfishdiffuse": "#FF6BD6"}
    k.islas = []
    for x, y, z, d, inclin in ((-15.0, 12.0, 11.5, 4.2, 0.5), (16.5, 14.0, 13.0, 3.6, -0.4), (2.0, 22.0, 16.0, 3.0, 0.3)):
        o = _suelto("vinilo", d, (x, y, z), por="mayor", colores=c_vinilo, linea=0.05, sombra=False)
        o.rotation_euler = (1.1, inclin, 0)
        for r, c, z in ((d * 0.34, "#5A3FB8", 0.035), (d * 0.17, NEON[len(k.islas) % 6], 0.06)):
            esfera("etiqueta", r, (0, 0, d * z), mat("etiqueta_" + c, brillante, c, 1.0), escala=(1, 1, 0.06),
                   padre=o, sombra=False)
        k.islas.append(o)
    for i, (x, y, z, tam) in enumerate(((-8.5, 6, 8.5, 0.9), (7.5, 8, 9.5, 1.0), (-3.0, 14, 12.0, 1.1),
                                        (12.0, 4, 7.0, 0.8), (-17.0, 2, 6.5, 0.8), (20.0, 10, 9.0, 0.9),
                                        (-1.0, -4, 6.2, 0.6))):
        k.islas.append(nota_musical((x, y, z), tam, NEON[i % 6], doble=i % 3 == 1))

    k.vivos = [octavio]
    k.nubes = [nube(p, tam, mat_nube("nube_melodia", "#FFD6F5", "#C79BEA"))
               for p, tam in (((-30, 70, 26), 6.5), ((26, 70, 24), 5.6), ((-52, 74, 19), 5.2))]
    estrellas("estrellas_melodia", (0, 0, 0), k.cam, n=90, grandes=8, radio=200, az=(-1.0, 1.0), el=(0.22, 0.75))
    k.posar, k.giro_nave, k.escala_nave = (1.2, -8.2), math.pi + 0.14, 0.62
    return k


# ----------------------------------------------------------------------------- Cuenta-Cuentas
# La fuente del juego (Baloo 2 variable) tiene trazos superpuestos y al darle volumen deja huecos en
# M, N, 1, 6...; para los números y letras 3D se usa una redonda del sistema, y Baloo solo de respaldo.
FUENTE = next((f for f in (r"C:\Windows\Fonts\ARLRDBD.TTF",
                           os.path.join(REPO, "assets", "fuentes", "Baloo2-Variable.ttf")) if os.path.exists(f)))
CUENTA = ["#FFE66B", "#FF9F4A", "#7CF0DC", "#FF8FB8", "#FFFFFF", "#9FE38A"]


def texto_3d(texto, alto, pos, color, giro=0.0, padre=None, linea=0.04, fondo=0.18, luz=None):
    """Número o letra gordita de pie sobre `pos`, de cara a -Y, con la fuente del juego.
    luz=fuerza la hace luminosa (para el espacio o los carteles de neón)."""
    cu = bpy.data.curves.new("texto", "FONT")
    cu.body, cu.align_x = texto, "CENTER"
    cu.font = bpy.data.fonts.load(FUENTE, check_existing=True)
    cu.extrude, cu.bevel_depth, cu.bevel_resolution = fondo, 0.025, 2
    tmp = bpy.data.objects.new("texto_tmp", cu)
    COL.objects.link(tmp)
    me = bpy.data.meshes.new_from_object(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(tmp)
    bm = bmesh.new()                    # soldar y ordenar las caras: sin esto el contorno saca picos
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    xs, ys = [v.co.x for v in me.vertices], [v.co.y for v in me.vertices]
    s = alto / max(1e-6, max(ys) - min(ys))
    me.transform(Matrix.Rotation(math.pi / 2, 4, "X") @ Matrix.Diagonal((s, s, s, 1))
                 @ Matrix.Translation((-(min(xs) + max(xs)) / 2, -min(ys), 0)))
    m = mat(f"texto_luz_{color}_{luz}", brillante, color, luz) if luz else \
        mat("texto_" + color, toon, color, tinte="#8E86D8", brillo=0.25)
    o = objeto("texto_" + texto, me, m, padre, suave=False, sombra=not luz)
    o.location, o.rotation_euler = pos, (0, 0, giro)
    if linea:
        contorno(o, linea)
        o.modifiers["contorno"].use_even_offset = False
    return o


def _fruta(nombre, alto, pos, **k):
    k.setdefault("redondear", 1)
    return modelo(os.path.join(DULCES, nombre + ".glb"), alto=alto, pos=pos, **k)


def vagon(numero, color):
    """Vagón de juguete con su número pintado en el costado (mira a -Y)."""
    e = vacio("vagon")
    caja("vagon_caja", (-1.1, -0.7, 0.5), (1.1, 0.7, 1.9), mat("vagon_" + color, toon, color, tinte="#6F7FD8",
                                                                brillo=0.25), e, linea=0.04)
    caja("vagon_base", (-1.3, -0.75, 0.35), (1.3, 0.75, 0.55), mat("vagon_base", toon, "#3B4AA8"), e, linea=0.03)
    for x in (-0.7, 0.7):
        esfera("rueda", 0.42, (x, -0.78, 0.42), mat("rueda", toon, "#FFD86B", tinte="#C79A4A"), escala=(1, 0.3, 1),
               padre=e, linea=0.03)
    texto_3d(str(numero), 1.05, (0, -0.72, 0.68), "#3B4AA8", padre=e, linea=0.0, fondo=0.04)
    return e


def superficie_cuenta_cuentas():
    """El planeta de los números del Profesor Plumas, el búho: noche azul con luna, números gigantes,
    el tren numérico que llega con sus vagones 1 a 5, dados, ábaco y fruta para contar."""
    k = SimpleNamespace()
    k.cielo = [(0.0, "#A9CBFF"), (0.07, "#6F93EC"), (0.22, "#3F52B8"), (0.5, "#27308A"), (1.0, "#141A55")]
    k.cam, k.mira, k.lente = (0.0, -26.0, 4.2), (0.0, 10.0, 5.6), 32
    t = k.terreno = Terreno()
    noche = "#2C3A9A"
    t.colina(-46, 84, -16, 44, 0.62, "#4A62C8", tinte="#27308A")     # cerros lejanos
    t.colina(8, 96, -18, 60, 0.45, "#5570D4", tinte="#27308A")
    t.colina(52, 84, -16, 46, 0.58, "#4660C4", tinte="#27308A")
    t.colina(-8, 36, -12, 46, 0.40, "#6584E4", tinte=noche)          # franja media
    t.colina(25, 22, -8, 22, 0.72, "#7FA4F5", tinte=noche)           # loma del ábaco
    t.colina(13, -8, -10, 22, 0.52, "#86A8F8", tinte=noche)
    t.colina(-13, -8, -10, 24, 0.50, "#9BBBFF", tinte=noche)         # el claro del Profesor Plumas
    t.colina(0, -20, -9.6, 30, 0.35, "#7896F0", tinte=noche)         # primer plano

    # la luna y un cielo lleno de estrellas para contar
    esfera("luna", 11.0, (-34, 130, 52), mat("luna", brillante, "#FFF6B0", 1.25), u=32, v=16, sombra=False)
    esfera("luna_halo", 17.0, (-34, 133, 52), mat("luna_halo", halo, "#FFF6B0", 0.0, 0.9, 0.9), u=32, v=16,
           sombra=False)
    estrellas("estrellas_cuenta", (0, 0, 0), k.cam, n=150, grandes=14, radio=200, az=(-1.0, 1.0), el=(0.2, 0.8))

    # números gigantes, como monumentos
    for i, (txt, x, y, alto, giro) in enumerate((("1", -14.0, 13.0, 4.6, 0.25), ("2", -5.0, 15.0, 5.2, 0.1),
                                                 ("3", 7.5, 13.0, 4.6, -0.1), ("4", 17.5, 8.0, 4.2, -0.3),
                                                 ("5", -31, 30, 9.0, 0.3), ("6", -15, 33, 8.0, 0.1),
                                                 ("7", 1, 34, 9.5, 0.0), ("8", 17, 33, 8.0, -0.15),
                                                 ("9", 38, 31, 9.0, -0.3))):
        texto_3d(txt, alto, t.sobre(x, y, -0.1), CUENTA[i % 6], giro=giro, linea=0.012 * alto, fondo=0.22)

    # el tren numérico: llega desde la derecha y se detiene con los vagones 1 a 5 en fila
    k.tren_y, k.tren_x = 3.6, (23.0, -8.6)
    loco = _suelto("locomotora", 4.4, (0, 0, 0), por="mayor", linea=0.04,
                   colores={"Black": "#FF6B8A", "Grey": "#FFD86B"})
    k.tren = [(loco, 0.0)] + [(vagon(n, CUENTA[(n - 1) % 4]), 1.2 + n * 2.9) for n in range(1, 6)]
    for o, dx in k.tren:
        o.location = t.sobre(k.tren_x[1] + dx, k.tren_y)
    m_riel = mat("durmiente", toon, "#3B4AA8", tinte="#27308A")
    for i in range(46):
        x = -22 + i * 1.3
        d = caja("durmiente", (-0.25, -1.0, 0), (0.25, 1.0, 0.12), m_riel)
        d.location = t.sobre(x, k.tren_y, -0.02)

    # el Profesor Plumas sobre su dado, con el ábaco y más dados
    c_dado = {"01___Default": "#FFF6D8", "Material__26": "#FF6B8A", "Material__27": "#FF6B8A"}
    bx, by = -7.6, -9.4
    _suelto("dado", 1.9, t.sobre(bx, by, -0.05), giro=0.4, linea=0.04, colores=c_dado)
    plumas = _suelto("buho", 2.3, t.sobre(bx, by, 1.8), giro=0.2, linea=0.035, matiz=(0.5, 1.25, 1.3))
    _suelto("dado", 1.1, t.sobre(-4.6, -12.4, -0.03), giro=1.0, linea=0.03, colores=c_dado)
    _suelto("dado", 1.3, t.sobre(9.6, -9.4, -0.03), giro=-0.5, linea=0.03, colores=c_dado)
    abaco = _suelto("abaco", 7.0, t.sobre(21.0, 20.0, 3.4), por="mayor", linea=0.05)
    abaco.rotation_euler = (1.3, 0, -0.35)
    # fruta para contar: 1 manzana, 2 peras, 3 naranjas
    for nombre, n, x0, y in (("apple", 1, -1.6, -13.2), ("pear", 2, 2.6, -13.0), ("orange", 3, 6.0, -11.4)):
        for j in range(n):
            _fruta(nombre, 0.75, t.sobre(x0 + j * 0.95, y + (j % 2) * 0.3, -0.03), giro=random.uniform(0, 6),
                   linea=0.025)

    k.vivos = [plumas]
    k.nubes = [nube(p, tam, mat_nube("nube_noche", "#C9DBFF", "#7F92E0"))
               for p, tam in (((-30, 70, 24), 6.5), ((2, 74, 31), 5.0), ((28, 70, 22), 5.6), ((52, 74, 28), 5.2))]
    k.posar, k.giro_nave, k.escala_nave = (1.2, -8.2), math.pi + 0.14, 0.62
    return k


# ----------------------------------------------------------------------------- Letralandia
LETRAS = ["#FF6B6B", "#6FD6A0", "#6FB6FF", "#B48CE8", "#FFFFFF", "#FF8FB8"]
LIBRO_ROJO = {"Beige": "#FFF3D6", "Brown": "#E0546A", "DarkBrown": "#B83F5A", "DarkRed": "#E0546A",
              "Gold": "#FFD35C", "Golden": "#FFD35C"}
LIBRO_AZUL = dict(LIBRO_ROJO, Brown="#5FA8E8", DarkBrown="#3F82C8")
LIBRO_VERDE = dict(LIBRO_ROJO, Brown="#5FC79A", DarkBrown="#3FA07A")


def burbuja_letra(letra, pos, radio, color):
    """Burbuja de jabón con una letra luminosa adentro (la sopa de burbujas de Lila)."""
    e = vacio("burbuja", None, pos)
    esfera("burbuja_piel", radio, (0, 0, 0), mat("burbuja", halo, "#FFFFFF", 0.10, 0.85, 1.0), padre=e, u=32, v=16,
           sombra=False)
    texto_3d(letra, radio * 1.05, (0, 0, -radio * 0.52), color, padre=e, linea=0.0, fondo=0.06, luz=1.15)
    return e


def superficie_letralandia():
    """El planeta de las letras de Lila, la dragoncita lectora: atardecer naranja, letras gigantes
    (las vocales y las iniciales de Maxi, Nicole y Sofía), el castillo-biblioteca, libros como casas,
    bloques con letras y burbujas con letras que flotan."""
    k = SimpleNamespace()
    k.cielo = [(0.0, "#FFF6CF"), (0.07, "#FFDA94"), (0.22, "#FFB26A"), (0.5, "#FF8F62"), (1.0, "#E8667C")]
    k.cam, k.mira, k.lente = (0.0, -26.0, 4.2), (0.0, 10.0, 5.6), 32
    t = k.terreno = Terreno()
    calido = "#E89A6A"
    t.colina(-46, 84, -16, 44, 0.62, "#FFC98A", tinte="#F0A070")     # cerros lejanos
    t.colina(8, 96, -18, 60, 0.45, "#FFD49A", tinte="#F0A070")
    t.colina(52, 84, -16, 46, 0.58, "#FFC080", tinte="#F0A070")
    t.colina(-8, 36, -12, 46, 0.40, "#FFB86B", tinte=calido)         # franja media
    t.colina(25, 22, -8, 22, 0.72, "#9FE0B0", tinte="#6FB89A")       # loma verde del castillo
    t.colina(13, -8, -10, 22, 0.52, "#FFE3A6", tinte=calido)
    t.colina(-13, -8, -10, 24, 0.50, "#FFD088", tinte=calido)        # el rincón de lectura de Lila
    t.colina(0, -20, -9.6, 30, 0.35, "#FFC878", tinte=calido)        # primer plano

    esfera("sol_tarde", 12.0, (30, 130, 30), mat("sol_tarde", brillante, "#FFF3B0", 1.3), u=32, v=16, sombra=False)
    esfera("sol_halo", 19.0, (30, 133, 30), mat("sol_halo", halo, "#FFE9A0", 0.0, 0.9, 0.9), u=32, v=16, sombra=False)

    # letras gigantes: las iniciales de los tres hermanos y, al fondo, las vocales
    for i, (txt, x, y, alto, giro) in enumerate((("M", -6.5, 12.0, 4.8, 0.2), ("N", 1.0, 15.0, 5.2, 0.0),
                                                 ("S", 8.5, 12.0, 4.8, -0.15),
                                                 ("A", -33, 30, 9.0, 0.3), ("E", -18, 33, 8.0, 0.15),
                                                 ("O", 9, 36, 8.0, -0.1),
                                                 ("U", 40, 31, 9.0, -0.3))):
        texto_3d(txt, alto, t.sobre(x, y, -0.1), LETRAS[i % 6], giro=giro, linea=0.012 * alto, fondo=0.22)

    # el castillo-biblioteca y los libros gigantes
    _suelto("castillo", 13.0, t.sobre(22.0, 21.0, -0.3), por="mayor", giro=-0.35, linea=0.06,
            colores={"Stone": "#FFD9A6", "Stone_Light": "#FFF0D0", "Wood": "#C9744A"})
    for x, y, alto, giro, matiz in ((14.5, 2.5, 4.2, -0.4, None), (-13.0, 2.5, 4.8, 0.5, (0.72, 1.0, 1.0)),
                                    (-26, 23, 8.0, 0.4, (0.22, 1.0, 1.0)), (37, 24, 7.5, -0.6, (0.72, 1.0, 1.0))):
        _suelto("libros_pila", alto, t.sobre(x, y, -0.2), giro=giro, linea=0.012 * alto, matiz=matiz)
    # Lila leyendo su libro abierto
    lx, ly = -6.8, -9.2
    _suelto("libro_abierto", 3.4, t.sobre(lx + 0.4, ly - 1.6, -0.03), por="mayor", giro=0.2, linea=0.04,
            colores=LIBRO_ROJO)
    lila = _suelto("dragon", 3.4, t.sobre(lx, ly + 0.6), giro=0.3, linea=0.04,
                   colores={"Main": "#B48CE8", "Belly": "#FFE9B8", "Wings": "#FF9EC7", "Claws": "#FFF6E0",
                            "Eyes": "#3B2A7A"})
    # bloques con letras y lápices clavados como banderas
    for x, y, alto, giro, color in ((3.6, -12.6, 1.3, 0.4, "#6FB6FF"), (5.3, -12.2, 1.0, -0.3, "#6FD6A0"),
                                    (9.4, -9.0, 1.6, 0.2, "#FF8FB8"), (-11.0, -6.4, 1.5, -0.5, "#B48CE8")):
        _suelto("bloque_juguete", alto, t.sobre(x, y, -0.03), giro=giro, linea=0.03,
                colores={"Material": color})
    k.lapices = []
    for x, y, alto, inclin in ((10.5, -4.5, 4.6, 0.12), (17.5, 8.0, 5.0, 0.08)):
        o = _suelto("lapiz", alto, t.sobre(x, y, alto * 0.5), por="mayor", linea=0.04)
        o.rotation_euler = (math.pi / 2, inclin, 0)
        k.lapices.append(o)

    # la sopa de burbujas: letras que flotan
    k.islas = [burbuja_letra(letra, (x, y, z), r, LETRAS[i % 4])
               for i, (letra, x, y, z, r) in enumerate((("a", -8.0, 6, 9.0, 1.3), ("e", 8.5, 8, 10.5, 1.5),
                                                        ("i", -2.5, 14, 13.0, 1.4), ("o", 13.0, 3, 7.5, 1.1),
                                                        ("u", -16.0, 3, 7.5, 1.2), ("L", 2.0, -3, 6.6, 0.8)))]
    k.vivos = [lila]
    k.nubes = [nube(p, tam, mat_nube("nube_tarde", "#FFF1DC", "#FFB8A0"))
               for p, tam in (((-30, 70, 24), 6.5), ((2, 74, 31), 5.0), ((-52, 74, 17), 5.2))]
    k.posar, k.giro_nave, k.escala_nave = (1.2, -8.2), math.pi + 0.14, 0.62
    return k


# ----------------------------------------------------------------------------- Corazón
ROSAS = ["#FF5F9E", "#FF8FB8", "#FFB3D6", "#FF7A8A", "#C79BFF", "#9FDCFF"]


def _corazon(alto, pos, color, **k):
    k.setdefault("redondear", 2)
    return _suelto("corazon", alto, pos, colores={"Red": color}, **k)


def nube_mimi(pos, tam):
    """Mimi, la nube: gordita, con ojos, mejillas y sonrisa. Mira hacia -Y."""
    e = vacio("mimi", None, pos)
    nube((0, 0, -tam * 0.45), tam, mat_nube("mimi", "#FFFFFF", "#FFD0E6"), e, bolas=5)
    m_ojo = mat("mimi_ojo", toon, "#4A3A8A")
    for lado in (-1, 1):
        esfera("mimi_ojo", tam * 0.11, (lado * tam * 0.36, -tam * 0.86, tam * 0.16), m_ojo, escala=(1, 0.5, 1.25),
               padre=e, sombra=False)
        esfera("mimi_brillo", tam * 0.035, (lado * tam * 0.36 + tam * 0.03, -tam * 0.93, tam * 0.22),
               mat("blanco_luz", brillante, "#FFFFFF", 1.2), padre=e, sombra=False)
        esfera("mimi_mejilla", tam * 0.13, (lado * tam * 0.62, -tam * 0.80, -tam * 0.02),
               mat("mimi_mejilla", brillante, "#FF9EC7", 1.0), escala=(1.2, 0.4, 0.8), padre=e, sombra=False)
    boca = arco_bandas("mimi_boca", tam * 0.17, tam * 0.05, ["#4A3A8A"], a0=math.pi * 1.1, a1=math.pi * 1.9, padre=e,
                       seg=16)
    boca.location = (0, -tam * 0.97, tam * 0.08)
    return e


def superficie_corazon():
    """El planeta de las emociones de Mimi, la nube: cielo rosa y celeste, corazones gigantes como
    árboles, globos, un globo aerostático, un osito y Mimi flotando para recibir a la nave."""
    k = SimpleNamespace()
    k.cielo = [(0.0, "#FFF4FA"), (0.08, "#FFD3E8"), (0.25, "#E6D0FF"), (0.5, "#B8DEFF"), (1.0, "#86C6FF")]
    k.cam, k.mira, k.lente = (0.0, -26.0, 4.2), (0.0, 10.0, 5.6), 32
    t = k.terreno = Terreno()
    rosa = "#E8A0D0"
    t.colina(-46, 84, -16, 44, 0.62, "#E0CCFF", tinte="#B8A6E8")     # cerros lejanos
    t.colina(8, 96, -18, 60, 0.45, "#D3E6FF", tinte="#B8A6E8")
    t.colina(52, 84, -16, 46, 0.58, "#E6D0FF", tinte="#B8A6E8")
    t.colina(-8, 36, -12, 46, 0.40, "#FFBFDD", tinte=rosa)           # franja media
    t.colina(25, 22, -8, 22, 0.72, "#BFE6FF", tinte="#96C0EC")       # loma celeste
    t.colina(13, -8, -10, 22, 0.52, "#FFE3F0", tinte=rosa)
    t.colina(-13, -8, -10, 24, 0.50, "#FFC9E2", tinte=rosa)
    t.colina(0, -20, -9.6, 30, 0.35, "#FFB3D6", tinte=rosa)          # primer plano

    # laguna tranquila (para respirar con Mimi)
    lx, ly = 3.5, 4.0
    esfera("laguna", 6.0, (lx, ly, t.altura(lx, ly) + 0.5), mat("laguna_corazon", toon, "#B8E6FF", brillo=0.5),
           escala=(1.3, 0.75, 0.03), u=48, v=8, sombra=False)

    # corazones gigantes como árboles, y más chicos como flores
    for i, (x, y, alto, giro) in enumerate(((-12.5, 9.0, 5.2, 0.2), (15.0, 7.0, 4.6, -0.3), (22.0, 21.0, 8.5, -0.3),
                                            (-31, 30, 9.0, 0.3), (-16, 33, 7.5, 0.1), (0, 34, 9.5, 0.0),
                                            (38, 31, 8.5, -0.3), (-22.0, 16.0, 6.0, 0.4))):
        tronco = cilindro("tallo", alto * 0.035, alto * 0.5, t.sobre(x, y, -0.3),
                          mat("tallo", toon, "#8FD6B0", tinte="#6FB09A"), linea=0.03)
        tronco.visible_shadow = True
        _corazon(alto * 0.62, t.sobre(x, y, alto * 0.40), ROSAS[i % 4], giro=giro, linea=0.012 * alto)
    for i, (x, y, alto) in enumerate(((-3.4, -12.6, 0.9), (4.4, -12.8, 0.8), (9.6, -9.0, 1.1), (-10.6, -6.2, 1.2),
                                      (6.6, -10.8, 0.7), (-1.2, -3.5, 0.8))):
        _corazon(alto, t.sobre(x, y, -0.03), ROSAS[(i + 1) % 6], giro=random.uniform(-0.5, 0.5), linea=0.03)
    # el osito de los abrazos, con sus globos
    _suelto("oso", 2.5, t.sobre(8.8, -6.6, -0.05), giro=-0.5, linea=0.035)
    _suelto("globos", 4.4, t.sobre(11.4, -5.6, -0.05), giro=0.3, linea=0.035, matiz=(0.92, 0.9, 1.1))
    _suelto("globos", 3.8, t.sobre(-14.0, -3.0, -0.05), giro=1.2, linea=0.035, matiz=(0.62, 0.9, 1.1))

    # Mimi y el globo aerostático flotan
    k.mimi = nube_mimi((-5.6, -6.0, 4.9), 1.7)
    aero = _suelto("globo_aerostatico", 7.0, (15.0, 16.0, 11.0), giro=0.4, linea=0.05, matiz=(0.92, 1.0, 1.1),
                   sombra=False)
    k.islas = [k.mimi, aero]
    k.nubes = [nube(p, tam, mat_nube("nube_rosa", "#FFFFFF", "#FFC6E2"))
               for p, tam in (((-30, 70, 24), 6.5), ((2, 74, 31), 5.0), ((28, 70, 22), 5.6), ((-52, 74, 17), 5.2))]
    k.posar, k.giro_nave, k.escala_nave = (1.2, -8.2), math.pi + 0.14, 0.62
    return k


SUPERFICIES = {"arcoiris": superficie_arcoiris, "animalia": superficie_animalia, "melodia": superficie_melodia,
               "cuenta_cuentas": superficie_cuenta_cuentas, "letralandia": superficie_letralandia,
               "corazon": superficie_corazon}
