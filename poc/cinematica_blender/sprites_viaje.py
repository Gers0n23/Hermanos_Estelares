"""Sprites del viaje arcade (HE-136): la MISMA nave, los mismos planetas y el mismo look toon de las
cinemáticas de viaje (despegue_viaje.py), renderizados con fondo transparente para que el juego
empalme con los videos sin que se note el cambio de técnica.

Todo se renderiza con cámara ortográfica de lado (la nave vuela hacia +X = derecha de la pantalla),
cada objeto en su propio rincón del mundo para no taparse.

Uso (Blender 4.5 LTS, sin interfaz):
  blender -b -P sprites_viaje.py -- [--solo nave,planetas,...] [--sin-pincel] [--muestras 16]
Salida: assets/sprites/viaje/*.png
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403
from planeta_comun import *  # noqa: E402,F401,F403
import planeta_comun  # noqa: E402

DESTINO_SPRITES = os.path.join(REPO, "assets", "sprites", "viaje")
os.makedirs(DESTINO_SPRITES, exist_ok=True)
SOLO = set(str(arg("--solo", "")).split(",")) - {""}
random.seed(42)

# La Tierra no tiene superficie en Blender (su despegue es otra cinemática): planeta provisional azul y verde.
planeta_comun.PLANETAS.setdefault("tierra", {"nombre": "La Tierra",
                                             "colores": ["#4FA8FF", "#7DD87A", "#4FA8FF", "#8FE39A", "#6FD6E8",
                                                         "#4FA8FF"], "atmosfera": "#D8F2FF"})

ESC.render.engine = "BLENDER_EEVEE_NEXT"
ESC.render.film_transparent = True
ESC.render.fps = FPS
ESC.eevee.taa_render_samples = int(arg("--muestras", 24))
ESC.view_settings.view_transform = "Standard"
ESC.view_settings.look = "None"
ESC.render.image_settings.file_format = "PNG"
ESC.render.image_settings.color_mode = "RGBA"

sol((0.45, 0.62, -0.55), 1.6)
o_cam, mira, cam = camara(35, alcance=400)
cam.type = "ORTHO"
o_cam.constraints.clear()
o_cam.rotation_euler = (math.radians(90), 0, 0)     # mira hacia +Y: X a la derecha, Z arriba


def pincel():
    """Mismo filtro de témpera que los videos (Kuwahara suave), respetando el alfa."""
    if arg("--sin-pincel"):
        return
    try:
        ESC.use_nodes = True
        nt = ESC.node_tree
        capas, comp = nt.nodes["Render Layers"], nt.nodes["Composite"]
        k = nt.nodes.new("CompositorNodeKuwahara")
        k.variation = "ANISOTROPIC"
        if "Size" in k.inputs:
            k.inputs["Size"].default_value = 2
        else:
            k.size = 2
        sep = nt.nodes.new("CompositorNodeSetAlpha")
        sep.mode = "REPLACE_ALPHA"
        nt.links.new(capas.outputs["Image"], k.inputs["Image"])
        nt.links.new(k.outputs["Image"], sep.inputs["Image"])
        nt.links.new(capas.outputs["Alpha"], sep.inputs["Alpha"])
        nt.links.new(sep.outputs["Image"], comp.inputs["Image"])
    except Exception as e:
        print("AVISO: sin pincel:", e)
        ESC.use_nodes = False


pincel()
_ocupado = [0]


def lugar():
    """Cada sprite vive lejos de los demás (cámara ortográfica con clip corto)."""
    _ocupado[0] += 1
    return Vector((_ocupado[0] * 200.0, 0.0, 0.0))


def foto(nombre, centro, ancho_mundo, px_ancho, px_alto, giro_cam=0.0):
    th = math.radians(90 - giro_cam)
    mirada = Vector((0.0, math.sin(th), -math.cos(th)))    # la cámara mira un poquito hacia abajo
    o_cam.location = centro - mirada * 60.0
    o_cam.rotation_euler = (th, 0, 0)
    cam.ortho_scale = ancho_mundo
    cam.clip_start, cam.clip_end = 1.0, 140.0
    ESC.render.resolution_x, ESC.render.resolution_y = px_ancho, px_alto
    ESC.render.resolution_percentage = 100
    ESC.render.filepath = os.path.join(DESTINO_SPRITES, nombre + ".png")
    bpy.ops.render.render(write_still=True)
    print("SPRITE", ESC.render.filepath)


def quiere(grupo):
    return not SOLO or grupo in SOLO


def tono(nombre, color, **k):
    k.setdefault("umbral", (0.22, 0.28))     # casi todo iluminado: se lee sobre el fondo oscuro
    k.setdefault("tinte", "#C4B2EC")
    return mat(nombre, toon, color, **k)


# ----------------------------------------------------------------------------- la nave (igual que en el video)
if quiere("nave"):
    p = lugar()
    N = construir_nave()
    N.raiz.location = p
    N.nave.rotation_euler = (0.10, 0.0, 0.32)       # 3/4 de atrás, como la ve la cámara del viaje
    llamas = llamas_nave(N)
    for i, largo in enumerate((2.3, 2.8, 2.5)):
        for o in llamas:
            o.scale = (1.0 + 0.08 * i, 1.0 + 0.08 * i, largo)
        foto(f"nave_{i}", p + Vector((-1.0, 0, 0.25)), 7.6, 480, 300, giro_cam=6)
    for o in llamas:
        o.scale = (0.6, 0.6, 0.7)
    foto("nave_quieta", p + Vector((-1.0, 0, 0.25)), 7.6, 480, 300, giro_cam=6)
    N.raiz.hide_render = True
    for h in N.raiz.children_recursive:
        h.hide_render = True

# ----------------------------------------------------------------------------- los planetas (los del video)
if quiere("planetas"):
    for ident in ["tierra"] + ORDEN:
        p = lugar()
        raiz, bola = planeta_orbita(ident, 1.0, p)
        foto("planeta_" + ident, p, 4.4, 560, 560, giro_cam=4)
        for h in [raiz] + list(raiz.children_recursive):
            h.hide_render = True


# ----------------------------------------------------------------------------- piezas sueltas
def roca(nombre, radio, color, p, semilla, abolladura=0.22, padre=None):
    random.seed(semilla)

    def _m(bm):
        bmesh.ops.create_icosphere(bm, subdivisions=3, radius=radio)
        for v in bm.verts:
            v.co *= 1.0 + random.uniform(-abolladura, abolladura) * 0.5
    o = objeto(nombre, malla_bm(nombre, _m), tono("roca_" + color, color), padre)
    o.location = p
    o.modifiers.new("suave", "SUBSURF").levels = 1
    contorno(o, radio * 0.035)
    m_crater = tono("crater_" + color, "#A08C9A")
    for k in range(4):
        a = random.uniform(0.3, 2.8)
        b = random.uniform(-0.8, 0.8)
        d = Vector((math.cos(a) * math.cos(b), -abs(math.sin(a)) * math.cos(b), math.sin(b))).normalized()
        esfera("crater", radio * random.uniform(0.14, 0.24), d * radio * 0.92, m_crater, escala=(1, 1, 0.45),
               padre=o, u=14, v=8, sombra=False).rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    return o


def ojos(padre, radio, y, z_ojo, dormido, separacion=0.38):
    m_neg = mat("ojo_negro", brillante, "#3A2A40", 1.0)
    m_bla = mat("ojo_blanco", brillante, "#FFFFFF", 1.0)
    m_mej = mat("mejilla", brillante, "#FF9EC0", 1.0)
    for lado in (-1, 1):
        x = lado * radio * separacion
        if dormido:   # ojitos cerrados: una rayita curva
            esfera("parpado", radio * 0.16, (x, y, z_ojo), m_neg, escala=(1.0, 0.25, 0.28), padre=padre, u=16, v=8,
                   sombra=False)
        else:
            esfera("ojo", radio * 0.17, (x, y, z_ojo), m_bla, escala=(1, 0.4, 1.15), padre=padre, u=16, v=10,
                   sombra=False, linea=radio * 0.02)
            esfera("pupila", radio * 0.09, (x + radio * 0.03, y - radio * 0.06, z_ojo - radio * 0.02), m_neg,
                   escala=(1, 0.4, 1.1), padre=padre, u=12, v=8, sombra=False)
        esfera("mejilla", radio * 0.11, (x * 1.45, y + radio * 0.02, z_ojo - radio * 0.28), m_mej,
               escala=(1.2, 0.3, 0.7), padre=padre, u=12, v=8, sombra=False)


if quiere("enemigos"):
    for i, (col, sem) in enumerate((("#D2B9A4", 3), ("#C4B0E0", 7), ("#E0C08E", 11))):
        p = lugar()
        roca("meteorito", 1.0, col, p, sem)
        foto(f"meteorito_{i}", p, 2.8, 220, 220)
    p = lugar()
    roca("meteorito_chico", 0.5, "#DCC4B0", p, 19)
    foto("meteorito_chico", p, 1.4, 120, 120)

    # basura espacial: un satélite viejito y un barril
    p = lugar()
    e = vacio("satelite", None, p)
    e.rotation_euler = (0.2, 0.3, 0.5)
    caja("cuerpo", (-0.45, -0.45, -0.45), (0.45, 0.45, 0.45), tono("sat_cuerpo", "#D6D6E6", brillo=0.4), e, 0.03)
    for lado in (-1, 1):
        caja("panel", (lado * 0.55, -0.05, -0.32), (lado * 1.55, 0.05, 0.32), tono("sat_panel", "#4AA8FF"), e, 0.03)
    cilindro("plato", 0.42, 0.25, (0, 0, 0.45), tono("sat_plato", "#FFCD3C"), e, radio2=0.05, linea=0.03)
    foto("basura_satelite", p, 3.6, 260, 200)
    p = lugar()
    e = vacio("barril", None, p)
    e.rotation_euler = (0.4, 0.0, 0.9)
    cilindro("barril", 0.5, 1.2, (0, 0, -0.6), tono("barril", "#FF5F7A", brillo=0.4), e, linea=0.03)
    for z in (-0.35, 0.35):
        cilindro("aro", 0.53, 0.12, (0, 0, z - 0.06), tono("barril_aro", "#FFD23F"), e, linea=0.02)
    foto("basura_barril", p, 2.2, 180, 180)

    # recolector del Coleccionauta: platillo morado con cúpula verde y una manito-pinza
    def platillo(nombre, escala, p):
        e = vacio(nombre, None, p)
        e.scale = (escala,) * 3
        e.rotation_euler = (0.25, 0, 0)
        esfera("plato", 1.0, (0, 0, 0), tono("col_plato", "#6B4FC0", brillo=0.4), escala=(1.0, 1.0, 0.34), padre=e,
               u=40, v=16, linea=0.04)
        esfera("borde", 1.02, (0, 0, -0.02), tono("col_borde", "#FFD35C", brillo=0.4), escala=(1.0, 1.0, 0.1),
               padre=e, u=40, v=8, linea=0.03)
        esfera("cupula", 0.5, (0, 0, 0.22), tono("col_cupula", "#8FE36B", brillo=0.5), escala=(1, 1, 0.9), padre=e,
               u=24, v=14, linea=0.03)
        for k in range(5):
            a = 2 * math.pi * k / 5
            esfera("luz", 0.09, (0.78 * math.cos(a), 0.78 * math.sin(a) - 0.05, -0.04),
                   mat("col_luz", brillante, "#FFF2A8", 1.4), padre=e, u=10, v=6, sombra=False)
        return e

    p = lugar()
    platillo("recolector", 1.0, p)
    foto("recolector", p, 2.6, 220, 170)

    # torreta-boya: bolita rosada con aro y antenita que hace burbujas
    p = lugar()
    e = vacio("boya", None, p)
    esfera("boya", 0.7, (0, 0, 0), tono("boya", "#FF9EC7", brillo=0.4), padre=e, u=32, v=16, linea=0.03)
    esfera("aro", 0.95, (0, 0, -0.05), tono("boya_aro", "#7FD3FF", brillo=0.4), escala=(1, 1, 0.12), padre=e,
           u=32, v=8, linea=0.03)
    cilindro("tubo", 0.08, 0.5, (0, 0, 0.6), tono("boya_tubo", "#FFF1D8"), e, linea=0.02)
    esfera("pompa", 0.17, (0, 0, 1.15), mat("boya_pompa", brillante, "#BFF0FF", 1.2), padre=e, u=14, v=8,
           linea=0.02)
    foto("boya", p + Vector((0, 0, 0.2)), 2.8, 200, 200)

    # bolsa de la colección
    p = lugar()
    e = vacio("bolsa", None, p)
    esfera("saco", 0.7, (0, 0, -0.1), tono("bolsa", "#E8C79A", brillo=0.3), escala=(1, 0.9, 1.05), padre=e,
           u=28, v=14, linea=0.03)
    cilindro("nudo", 0.18, 0.3, (0, 0, 0.75), tono("bolsa_nudo", "#C99A66"), e, radio2=0.08, linea=0.02)
    esfera("parche", 0.2, (0.25, -0.62, 0.0), tono("bolsa_parche", "#8FE36B"), escala=(1, 0.2, 1), padre=e,
           u=14, v=8, sombra=False)
    foto("bolsa", p + Vector((0, 0, 0.12)), 2.3, 170, 170)

# ----------------------------------------------------------------------------- jefes (artefactos del Coleccionauta)
if quiere("jefes"):
    # Tierra -> Arcoíris: el Meteorito Dormilón (dormido y despierto)
    for estado in ("dormido", "despierto"):
        p = lugar()
        r = roca("dormilon", 1.0, "#D2B9A4", p, 5, abolladura=0.12)
        ojos(r, 1.0, -0.93, 0.12, estado == "dormido")
        if estado == "dormido":     # gorrito de dormir
            g = cilindro("gorro", 0.55, 0.9, (0.1, 0, 0.78), tono("gorro", "#7FB6D9"), r, radio2=0.06, linea=0.03)
            g.rotation_euler = (0, 0.5, 0)
            esfera("pompon_gorro", 0.14, (0.55, 0, 1.55), tono("gorro_pompon", "#FFFFFF"), padre=r, u=12, v=8,
                   linea=0.02)
        foto(f"jefe_tierra_arcoiris_{estado}", p + Vector((0, 0, 0.3)), 3.5, 300, 300)

    # Arcoíris -> Animalia: la aspiradora gigante
    p = lugar()
    e = vacio("aspiradora", None, p)
    esfera("tanque", 1.0, (0.3, 0, 0), tono("asp_tanque", "#B69BFF", brillo=0.4), escala=(1.15, 0.9, 0.85), padre=e,
           u=36, v=16, linea=0.04)
    cilindro("tubo", 0.28, 1.4, (-0.6, 0, -0.1), tono("asp_tubo", "#FFE66B"), e, linea=0.03).rotation_euler = (0, -1.4, 0)
    cilindro("boca", 0.62, 0.45, (-1.95, 0, -0.25), tono("asp_boca", "#FF9EC7"), e, radio2=0.3,
             linea=0.03).rotation_euler = (0, 1.57, 0)
    for k, c in enumerate(("#FF6B6B", "#FFCB3D", "#7DD87A")):
        esfera("boton", 0.12, (0.6 + 0.25 * k, -0.78, 0.35), mat("asp_luz_" + c, brillante, c, 1.2), padre=e,
               u=10, v=6, sombra=False)
    ojos(e, 0.9, -0.8, 0.1, False, separacion=0.25)
    foto("jefe_arcoiris_animalia", p + Vector((-0.3, 0, 0)), 4.6, 360, 260)

    # Animalia -> Melodía: el tocadiscos-ovni
    p = lugar()
    e = vacio("tocadiscos", None, p)
    e.rotation_euler = (0.35, 0, 0)
    esfera("base", 1.3, (0, 0, -0.1), tono("toca_base", "#A06BFF", brillo=0.4), escala=(1, 1, 0.3), padre=e,
           u=40, v=14, linea=0.04)
    cilindro("disco", 1.0, 0.08, (0, 0, 0.25), tono("toca_disco", "#3A2A40"), e, seg=40, linea=0.02)
    cilindro("etiqueta", 0.35, 0.1, (0, 0, 0.26), tono("toca_etiqueta", "#FF6BD6"), e, seg=24)
    b = cilindro("brazo", 0.07, 1.1, (0.95, 0.3, 0.3), tono("toca_brazo", "#7CF0DC"), e, linea=0.02)
    b.rotation_euler = (0, -1.1, 0.4)
    foto("jefe_animalia_melodia", p, 3.6, 340, 250)

    # Melodía -> Cuenta-Cuentas: la grúa de cubos
    p = lugar()
    e = vacio("grua", None, p)
    caja("cabina", (-0.6, -0.5, -1.0), (0.6, 0.5, 0.0), tono("grua_cab", "#FFCB3D", brillo=0.4), e, 0.04)
    caja("brazo", (-2.0, -0.12, 0.0), (0.4, 0.12, 0.24), tono("grua_brazo", "#FF9F4A"), e, 0.03)
    cilindro("cable", 0.03, 0.9, (-1.8, 0, -0.85), tono("grua_cable", "#4B3247"), e)
    for k, c in enumerate(("#4A6AE0", "#7DD87A", "#FF6B6B")):
        caja("cubo", (-2.15 + 0.0, -0.3, -1.45 - k * 0.62), (-1.55, 0.3, -0.87 - k * 0.62), tono("cubo_" + c, c), e,
             0.03)
    ojos(e, 0.8, -0.52, -0.45, False, separacion=0.3)
    foto("jefe_melodia_cuenta_cuentas", p + Vector((-0.7, 0, -0.9)), 4.2, 300, 320)

    # Cuenta-Cuentas -> Letralandia: torre de bloques
    p = lugar()
    e = vacio("torre", None, p)
    for k, c in enumerate(("#FFB35C", "#6FD6A0", "#FF8A3D", "#7FD3FF", "#B69BFF")):
        caja("bloque", (-0.55, -0.55, -2.0 + k * 0.8), (0.55, 0.55, -1.22 + k * 0.8), tono("bloque_" + c, c,
                                                                                            brillo=0.3), e, 0.03)
    ojos(e, 0.9, -0.57, 1.0, False, separacion=0.28)
    foto("jefe_cuenta_cuentas_letralandia", p, 4.6, 230, 380)

    # Letralandia -> Corazón: el globo-caritas (la carita la pinta el juego encima)
    p = lugar()
    e = vacio("globo", None, p)
    esfera("globo", 1.25, (0, 0, 0.4), tono("globo", "#FFB3D6", brillo=0.5), escala=(1, 1, 1.1), padre=e, u=40,
           v=20, linea=0.04)
    cilindro("cuerda", 0.03, 0.9, (0, 0, -1.6), tono("globo_cuerda", "#4B3247"), e)
    caja("canasta", (-0.4, -0.4, -2.1), (0.4, 0.4, -1.6), tono("canasta", "#C99A66"), e, 0.03)
    foto("jefe_letralandia_corazon", p + Vector((0, 0, -0.16)), 4.4, 260, 340)

    # Corazón -> Coleccionauta: su propia nave (provisional hasta HE-131)
    p = lugar()
    e = platillo("nave_coleccionauta", 1.6, p)
    foto("jefe_corazon_coleccionauta", p, 4.0, 340, 250)
    foto("coleccionauta_nave", p, 4.0, 340, 250)

print("LISTO sprites_viaje")
