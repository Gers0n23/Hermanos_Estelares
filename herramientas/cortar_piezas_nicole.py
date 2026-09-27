"""Corta las 11 piezas de cutout de Nicole desde su base (misma estructura que Sofía:
Nicole también lleva túnica, así que tiene pieza `cinturon` = cinturón + faldones).

La base sale de la hoja de referencia aprobada:
    python herramientas/extraer_base.py assets/anclas/nicole_referencia.png 355,35,700,745 \\
        assets/generadas/nicole_piezas/00_base_nicole.png --piso 690 --cuello 262

Uso:
    python herramientas/cortar_piezas_nicole.py
Revisión visual:
    python herramientas/kra.py ver assets/generadas/nicole_piezas/01_piezas_nicole.kra .ojos/nicole_piezas.png

Método:
  1. los cortes "a mano" (los que el PO hizo en Krita para Maxi y Sofía: torso, cinturón,
     brazos) son polígonos trazados sobre una grilla ampliada de la base; lo que queda
     arriba es cabeza+pelo+burbuja y lo que queda abajo son piernas;
  2. brazos: corte perpendicular al eje en el CODO; piernas: mitad por el centro y corte
     en la RODILLA; en cada articulación ambas piezas comparten un disco que cubre todo
     el ancho del miembro (así la pieza de atrás termina en arco y no asoman esquinas);
  3. articulaciones redondeadas y pintadas bajo la pieza de adelante como el PO hizo con
     Sofía (herramientas/articulaciones.py), incluido pelo detrás de los brazos.
"""

from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import articulaciones  # noqa: E402
import kra  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "assets/generadas/nicole_piezas"
BASE = CARPETA / "00_base_nicole.png"
KRA_SALIDA = CARPETA / "01_piezas_nicole.kra"

ANCHO = 302             # la figura es casi simétrica: lado der = espejo (ANCHO - x)
CENTRO_X = 151

# Articulaciones (también son los pivotes del rig), lado izquierdo de la imagen
# CODO y RODILLA son aproximados: se centran en el miembro con articulaciones.centrar()
# y el radio del disco de la articulación = medio ancho medido (+1).
HOMBRO = (76, 258)
CODO = (58, 322)        # a media manga, sobre el brazalete (el brazalete es antebrazo)
MUNECA = (32, 400)
CADERA = (122, 420)
RODILLA = (104, 508)
CUELLO = (151, 215)
CASQUETE = {"hombro": 26, "cadera": 52}

# --- cortes "a mano" (lado izquierdo; el derecho es su espejo) ---------------------
# Brazo: borde externo generoso (afuera hay pelo o fondo: lo decide la base), borde
# interno siguiendo la línea del chaleco y el bolsillo del cinturón.
BRAZO = [(80, 244), (81, 265), (86, 285), (91, 300), (93, 320), (92, 340),
         (82, 348), (79, 362), (76, 376), (68, 392), (54, 404), (50, 430), (44, 452),
         (0, 456), (0, 380), (14, 350), (36, 342), (41, 332), (46, 322), (52, 312),
         (57, 302), (61, 292), (65, 282), (70, 270), (74, 258), (78, 246)]
# Torso (cuello del traje + chaleco), hasta bajo el cinturón (escondido por él)
TORSO = [(92, 214), (151, 212), (151, 392), (100, 392), (92, 344), (92, 340), (93, 320),
         (91, 300), (86, 285), (81, 265), (80, 244)]
# Espalda de la túnica que asoma entre las piernas (va con el torso, detrás de ellas)
TUNICA_ESPALDA = [(143, 434), (151, 430), (151, 476), (138, 476)]
# Cinturón + bolsillo + faldón de la túnica (delante de las piernas)
CINTURON = [(78, 342), (151, 342), (151, 392), (112, 390), (104, 386), (96, 402),
            (86, 426), (80, 446), (78, 468), (50, 466), (54, 440), (66, 414), (76, 390)]
# Nacimiento del muslo, escondido bajo cinturón y faldón (se duplica ahí, tapado)
CADERA_OCULTA = [(96, 360), (151, 360), (151, 440), (90, 440)]

# Orden de dibujo = el de Sofía (primero = más al frente, como el panel de Krita)
ORDEN = [
    "cinturon",
    "pierna_inf_pie_izq", "pierna_sup_izq", "pierna_inf_pie_der", "pierna_sup_der",
    "torso",
    "brazo_sup_der", "brazo_sup_izq", "antebrazo_mano_der", "antebrazo_mano_izq",
    "cabeza_casco",
]
Z = {n: len(ORDEN) - i for i, n in enumerate(ORDEN)}


def espejo(p):
    return (ANCHO - p[0], p[1])


def lado(punto, cual):
    return punto if cual == "izq" else espejo(punto)


def poligono(forma, puntos, espejar=False):
    img = Image.new("L", (forma[1], forma[0]), 0)
    d = ImageDraw.Draw(img)
    d.polygon(puntos, fill=1)
    if espejar:
        d.polygon([espejo(p) for p in puntos], fill=1)
    return np.array(img).astype(bool)


def disco(forma, centro, radio):
    yy, xx = np.indices(forma)
    return (xx - centro[0]) ** 2 + (yy - centro[1]) ** 2 <= radio ** 2


def semiplano(forma, punto, direccion):
    yy, xx = np.indices(forma)
    return (xx - punto[0]) * direccion[0] + (yy - punto[1]) * direccion[1] >= 0


def color_pelo(base):
    """Castaño del pelo: mediana de lo oscuro y cálido en la melena junto al brazo."""
    zona = base[240:330, 20:60, :3].reshape(-1, 3).astype(int)
    a = base[240:330, 20:60, 3].reshape(-1)
    oscuro = zona[(a > 250) & (zona.sum(1) < 260) & (zona.sum(1) > 60)]
    return tuple(np.median(oscuro, axis=0).astype(int))


def main() -> None:
    base = np.array(Image.open(BASE).convert("RGBA"))
    forma = base.shape[:2]
    visible = base[..., 3] > 0
    yy = np.indices(forma)[0]
    xx = np.indices(forma)[1]

    brazo = {c: poligono(forma, BRAZO if c == "izq" else [espejo(p) for p in BRAZO]) & visible
             for c in ("izq", "der")}
    cinturon = poligono(forma, CINTURON, True) & visible
    # el torso sigue escondido bajo el cinturón (comparten esa franja): al girar el
    # cinturón no se abre un hueco entre chaleco y cinturón
    torso = (poligono(forma, TORSO, True) | poligono(forma, TUNICA_ESPALDA, True)) & visible
    for c in brazo:
        brazo[c] &= ~torso & ~cinturon
    asignado = torso | cinturon | brazo["izq"] | brazo["der"]
    resto = visible & ~asignado
    # arriba (pelo, cabeza, burbuja) / abajo (piernas): el límite es el cinturón
    cabeza = resto & (yy < 380)
    piernas = resto & (yy >= 380)

    mascaras = {"torso": torso, "cinturon": cinturon, "cabeza_casco": cabeza}
    pivotes = {"cabeza_casco": CUELLO, "torso": (CENTRO_X, CADERA[1]), "cinturon": (CENTRO_X, CADERA[1])}
    radio_codo, radio_rodilla = {}, {}
    for c in ("izq", "der"):
        pivotes[f"brazo_sup_{c}"] = lado(HOMBRO, c)
        pivotes[f"pierna_sup_{c}"] = lado(CADERA, c)
    for c in ("izq", "der"):
        m = brazo[c]
        eje = np.subtract(lado(MUNECA, c), lado(HOMBRO, c)).astype(float)
        eje /= np.linalg.norm(eje)
        codo, medio = articulaciones.centrar(m, lado(CODO, c), eje)
        pivotes[f"antebrazo_mano_{c}"] = codo
        radio_codo[c] = medio + 1
        abajo = semiplano(forma, codo, eje)
        union = disco(forma, codo, radio_codo[c]) & m
        mascaras[f"brazo_sup_{c}"] = (m & ~abajo) | union
        mascaras[f"antebrazo_mano_{c}"] = (m & abajo) | union

        mitad = (xx < CENTRO_X) if c == "izq" else (xx >= CENTRO_X)
        pierna = piernas & mitad
        # el muslo sube escondido bajo el cinturón (hasta su borde superior)
        cadera_oculta = [lado(p, c) for p in CADERA_OCULTA]
        pierna |= cinturon & poligono(forma, cadera_oculta)
        rodilla, medio = articulaciones.centrar(pierna, lado(RODILLA, c), (0, 1))
        pivotes[f"pierna_inf_pie_{c}"] = rodilla
        radio_rodilla[c] = medio + 1
        bajo = yy >= rodilla[1]
        union = disco(forma, rodilla, radio_rodilla[c]) & pierna
        mascaras[f"pierna_sup_{c}"] = (pierna & ~bajo) | union
        mascaras[f"pierna_inf_pie_{c}"] = (pierna & bajo) | union

    # limpieza de flecos y píxeles sin dueño (igual que Maxi)
    for nombre, m in mascaras.items():
        radio = 3 if "brazo" in nombre else 1
        limpia = ndimage.binary_opening(m, structure=disco((2 * radio + 1,) * 2, (radio, radio), radio))
        partes, n = ndimage.label(limpia)
        if n > 1:
            limpia = partes == (np.argmax(ndimage.sum(limpia, partes, range(1, n + 1))) + 1)
        if nombre != "cabeza_casco":  # la burbuja es semitransparente y fina: no se abre
            mascaras[nombre] = m & ndimage.binary_dilation(limpia, iterations=1)
    fijas = [n for n in mascaras if "brazo" not in n]
    etiqueta = np.zeros(forma, np.int32)
    for i, nombre in enumerate(fijas, start=1):
        etiqueta[mascaras[nombre] & (etiqueta == 0)] = i
    sin_dueno = visible & ~np.logical_or.reduce(list(mascaras.values()))
    _, (iy, ix) = ndimage.distance_transform_edt(etiqueta == 0, return_indices=True)
    for i, nombre in enumerate(fijas, start=1):
        mascaras[nombre] |= sin_dueno & (etiqueta[iy, ix] == i)

    imagenes = {}
    for nombre in ORDEN:
        img = base.copy()
        img[..., 3] = np.where(mascaras[nombre], base[..., 3], 0)
        imagenes[nombre] = img
    pelo = color_pelo(base)
    extensiones = {
        # melena detrás de los hombros: al levantar el brazo no queda un hueco en el pelo
        "cabeza_casco": [(lado((72, 284), c), 38, {"color": pelo, "linea": False}) for c in ("izq", "der")]
                        + [(CUELLO, 30, {"repintar": False, "color": (224, 160, 130)})],
        # bajo la túnica el pantalón es continuo: casquetes de cadera sin línea
        "torso": [(lado(CADERA, c), 30, {"repintar": False, "linea": False}) for c in ("izq", "der")],
    }
    for c in ("izq", "der"):
        extensiones[f"brazo_sup_{c}"] = [(lado(HOMBRO, c), CASQUETE["hombro"])]
        extensiones[f"antebrazo_mano_{c}"] = [(pivotes[f"antebrazo_mano_{c}"], radio_codo[c])]
        extensiones[f"pierna_sup_{c}"] = [(lado(CADERA, c), CASQUETE["cadera"], {"linea": False}),
                                          (pivotes[f"pierna_inf_pie_{c}"], radio_rodilla[c])]
    imagenes = articulaciones.redondear(imagenes, Z, extensiones)

    rutas = []
    for nombre in ORDEN:
        ruta = CARPETA / f"{nombre}.png"
        Image.fromarray(imagenes[nombre]).save(ruta)
        rutas.append(ruta)
    kra.crear_kra(KRA_SALIDA, rutas)
    articulaciones.guardar_pivotes(CARPETA / "pivotes.json", pivotes)
    print("codo", {c: (pivotes[f"antebrazo_mano_{c}"], radio_codo[c]) for c in radio_codo},
          "rodilla", {c: (pivotes[f"pierna_inf_pie_{c}"], radio_rodilla[c]) for c in radio_rodilla})
    print(f"pelo {pelo}\npiezas -> {CARPETA}\nkra    -> {KRA_SALIDA}")


if __name__ == "__main__":
    main()
