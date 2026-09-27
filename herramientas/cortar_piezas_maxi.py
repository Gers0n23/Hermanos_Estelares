"""Corta las 10 piezas de cutout de Maxi a partir de su base y de las capas ya
terminadas a mano por el PO en Krita (cabeza_casco y torso).

Mismo formato que las piezas de Sofía (assets/generadas/sofia_piezas/): un PNG por
pieza del tamaño del lienzo completo (306x697), con la pieza en su lugar, para que
el rig solo necesite pivotes. También arma un .kra nuevo con una capa por pieza
(orden de dibujo final) para retocar en Krita sin tocar el .kra original del PO.

Uso:
    python herramientas/cortar_piezas_maxi.py
Revisión visual:
    python herramientas/kra.py ver assets/generadas/maxi_piezas/01_piezas_maxi.kra .ojos/maxi_piezas.png

Método (ver mapa assets/generadas/maxi_piezas/00_mapa_cortes.png):
  1. brazos y piernas = base − torso − cabeza (quedan 3 regiones conexas separadas);
  2. cada brazo se divide en el CODO con un corte perpendicular al eje del brazo;
     cada pierna se divide al centro (x del torso) y en la RODILLA (sobre la rodillera);
  3. en cada articulación ambas piezas comparten un disco (el "redondear aquí" azul del
     mapa): al rotar, la pieza de adelante tapa la unión y no aparece un hueco;
  4. como hizo el PO a mano con Sofía, cada pieza se prolonga redondeada y pintada bajo
     la pieza que la tapa (herramientas/articulaciones.py): al levantar el brazo asoma
     traje con su línea de contorno, no un borde dentado.
"""

from pathlib import Path
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import articulaciones  # noqa: E402
import kra  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "assets/generadas/maxi_piezas"
BASE = CARPETA / "00_base_maxi.png"
KRA_PO = CARPETA / "00_base_maxi.kra"
KRA_SALIDA = CARPETA / "01_piezas_maxi.kra"

CENTRO_X = 153          # eje del cuerpo (centro del torso del PO)
CINTURA_OCULTA_Y = 385  # los muslos suben hasta aquí, escondidos tras el cinturón

# Articulaciones en coordenadas del lienzo 306x697 (también son los pivotes del rig)
HOMBRO = {"izq": (74, 272), "der": (232, 272)}
CODO = {"izq": (52, 340), "der": (254, 340)}
MUNECA = {"izq": (35, 390), "der": (271, 390)}
CADERA = {"izq": (112, 410), "der": (194, 410)}
RODILLA = {"izq": (105, 500), "der": (200, 500)}
CUELLO = (153, 240)
PIEL_CUELLO = (214, 146, 143)  # piel en sombra bajo el mentón (muestreada de la base)
# casquetes pintados (escondidos en reposo) en cada pivote: ~ medio ancho del miembro
# CODO y RODILLA son aproximados: se centran en el miembro con articulaciones.centrar() y
# el disco de la articulación tiene radio = medio ancho medido (+1): la pieza de atrás
# termina en un arco que al girar vuelve sobre sí mismo (no asoman esquinas ni flecos).
CASQUETE = {"hombro": 26, "cadera": 48, "cuello": 34}

# Orden de dibujo: primero = más al frente (igual que el panel de capas de Krita). Mismo
# criterio que Sofía: el torso tapa el hombro, el brazo tapa el codo, la rodillera tapa
# el muslo — lo pintado de cada articulación queda siempre debajo de su vecina.
ORDEN = [
    "cabeza_casco", "torso",
    "brazo_sup_izq", "brazo_sup_der",
    "antebrazo_mano_izq", "antebrazo_mano_der",
    "pierna_inf_pie_izq", "pierna_inf_pie_der",
    "pierna_sup_izq", "pierna_sup_der",
]
Z = {n: len(ORDEN) - i for i, n in enumerate(ORDEN)}


def disco(forma, centro, radio):
    yy, xx = np.indices(forma)
    return (xx - centro[0]) ** 2 + (yy - centro[1]) ** 2 <= radio ** 2


def semiplano(forma, punto, direccion):
    """True donde (p - punto)·direccion >= 0."""
    yy, xx = np.indices(forma)
    return (xx - punto[0]) * direccion[0] + (yy - punto[1]) * direccion[1] >= 0


def main() -> None:
    base = np.array(Image.open(BASE).convert("RGBA"))
    forma = base.shape[:2]
    _, capas = kra.leer_capas(KRA_PO)
    del_po = {c["nombre"]: np.array(c["imagen"]) for c in capas}
    alfa = {n: del_po[n][..., 3] > 0 for n in ("torso", "cabeza_casco")}

    visible = base[..., 3] > 0
    resto = visible & ~alfa["torso"] & ~alfa["cabeza_casco"]
    etiquetas, _ = ndimage.label(resto)
    tamanos = ndimage.sum(resto, etiquetas, range(etiquetas.max() + 1))
    regiones = [i for i in np.argsort(tamanos)[::-1] if tamanos[i] > 1000][:3]
    por_x = {}
    for i in regiones:
        xs = np.nonzero(etiquetas == i)[1]
        por_x[i] = (xs.min(), xs.max())
    # Píxeles sueltos (astillas entre el corte a mano del torso y los brazos): se asignan a
    # la región grande más cercana; si no, aparecen rendijas de fondo en la pose de reposo.
    grandes = np.isin(etiquetas, regiones)
    _, (iy, ix) = ndimage.distance_transform_edt(~grandes, return_indices=True)
    sueltos = resto & ~grandes
    etiquetas[sueltos] = etiquetas[iy[sueltos], ix[sueltos]]

    piernas = max(regiones, key=lambda i: tamanos[i])
    brazos = [i for i in regiones if i != piernas]
    brazo = {"izq": min(brazos, key=lambda i: por_x[i][0]), "der": max(brazos, key=lambda i: por_x[i][0])}

    mascaras = {"torso": alfa["torso"], "cabeza_casco": alfa["cabeza_casco"]}
    pivotes = {"cabeza_casco": CUELLO, "torso": (CENTRO_X, CADERA["izq"][1])}
    radio_codo, radio_rodilla = {}, {}
    for lado in ("izq", "der"):
        pivotes[f"brazo_sup_{lado}"] = HOMBRO[lado]
        pivotes[f"pierna_sup_{lado}"] = CADERA[lado]

    for lado in ("izq", "der"):
        # --- brazo: corte perpendicular al eje hombro→muñeca, en el codo ---
        m = etiquetas == brazo[lado]
        eje = np.subtract(MUNECA[lado], HOMBRO[lado]).astype(float)
        eje /= np.linalg.norm(eje)
        codo, medio = articulaciones.centrar(m, CODO[lado], eje)
        pivotes[f"antebrazo_mano_{lado}"] = codo
        radio_codo[lado] = medio + 1
        abajo = semiplano(forma, codo, eje)
        union = disco(forma, codo, radio_codo[lado]) & m
        mascaras[f"brazo_sup_{lado}"] = (m & ~abajo) | union
        mascaras[f"antebrazo_mano_{lado}"] = (m & abajo) | union

        # --- pierna: mitad del cuerpo, muslo escondido bajo el cinturón, rodilla ---
        mitad = (np.indices(forma)[1] < CENTRO_X) if lado == "izq" else (np.indices(forma)[1] >= CENTRO_X)
        pierna = (etiquetas == piernas) & mitad
        # extensión oculta del muslo: píxeles de la base tras el cinturón (tapados por el torso)
        yy = np.indices(forma)[0]
        columnas = np.nonzero(pierna.any(axis=0))[0]
        oculta = visible & mitad & (yy >= CINTURA_OCULTA_Y) & alfa["torso"]
        oculta[:, : columnas.min()] = False
        oculta[:, columnas.max() + 1:] = False
        pierna |= oculta
        rodilla, medio = articulaciones.centrar(pierna, RODILLA[lado], (0, 1))
        pivotes[f"pierna_inf_pie_{lado}"] = rodilla
        radio_rodilla[lado] = medio + 1
        bajo_rodilla = yy >= rodilla[1]
        union = disco(forma, rodilla, radio_rodilla[lado]) & pierna
        mascaras[f"pierna_sup_{lado}"] = (pierna & ~bajo_rodilla) | union
        mascaras[f"pierna_inf_pie_{lado}"] = (pierna & bajo_rodilla) | union

    # Limpieza de flecos: el halo claro del dibujo original, cortado, deja hilachas que se
    # notan al rotar la pieza. Apertura morfológica + quedarse con la parte principal.
    for nombre, m in mascaras.items():
        if nombre in ("torso", "cabeza_casco"):
            continue  # cortes a mano del PO: se respetan tal cual
        # brazos: redondeo más fuerte (el halo entre brazo y torso es lo que se ve al levantarlos)
        radio = 3 if "brazo" in nombre else 1
        limpia = ndimage.binary_opening(m, structure=disco((2 * radio + 1,) * 2, (radio, radio), radio))
        partes, n = ndimage.label(limpia)
        if n > 1:
            limpia = partes == (np.argmax(ndimage.sum(limpia, partes, range(1, n + 1))) + 1)
        # se devuelven los píxeles de borde que tocan la pieza (antialias), no las hilachas
        mascaras[nombre] = m & ndimage.binary_dilation(limpia, iterations=1)

    # Ningún píxel de la base puede quedar sin dueño (en reposo se vería una rendija). Los
    # sueltos van a la pieza FIJA más cercana (torso/cabeza/piernas), nunca a un brazo: así el
    # halo que queda entre brazo y torso se queda quieto con el torso y no viaja con el brazo.
    fijas = [n for n in mascaras if "brazo" not in n]
    etiqueta_fija = np.zeros(forma, dtype=np.int32)
    for i, nombre in enumerate(fijas, start=1):
        etiqueta_fija[mascaras[nombre] & (etiqueta_fija == 0)] = i
    cubierto = np.logical_or.reduce(list(mascaras.values()))
    sin_dueno = visible & ~cubierto
    _, (iy, ix) = ndimage.distance_transform_edt(etiqueta_fija == 0, return_indices=True)
    for i, nombre in enumerate(fijas, start=1):
        mascaras[nombre] = mascaras[nombre] | (sin_dueno & (etiqueta_fija[iy, ix] == i))

    imagenes = {}
    for nombre in ORDEN:
        img = base.copy()
        img[..., 3] = np.where(mascaras[nombre], base[..., 3], 0)
        imagenes[nombre] = img
    extensiones = {"torso": [(CUELLO, CASQUETE["cuello"], {"color": PIEL_CUELLO, "repintar": False})]}
    for lado in ("izq", "der"):
        extensiones[f"brazo_sup_{lado}"] = [(HOMBRO[lado], CASQUETE["hombro"])]
        extensiones[f"antebrazo_mano_{lado}"] = [(pivotes[f"antebrazo_mano_{lado}"], radio_codo[lado])]
        # bajo el cinturón el pantalón es continuo: casquete de cadera sin línea
        extensiones[f"pierna_sup_{lado}"] = [(CADERA[lado], CASQUETE["cadera"], {"linea": False}),
                                             (pivotes[f"pierna_inf_pie_{lado}"], radio_rodilla[lado])]
    imagenes = articulaciones.redondear(imagenes, Z, extensiones)

    rutas = []
    for nombre in ORDEN:
        ruta = CARPETA / f"{nombre}.png"
        Image.fromarray(imagenes[nombre]).save(ruta)
        rutas.append(ruta)
        print(f"  {nombre:20s} {int(mascaras[nombre].sum()):6d} px")
    kra.crear_kra(KRA_SALIDA, rutas)
    articulaciones.guardar_pivotes(CARPETA / "pivotes.json", pivotes)
    print("codo", {k: (pivotes[f"antebrazo_mano_{k}"], radio_codo[k]) for k in radio_codo},
          "rodilla", {k: (pivotes[f"pierna_inf_pie_{k}"], radio_rodilla[k]) for k in radio_rodilla})
    print(f"piezas -> {CARPETA}\nkra    -> {KRA_SALIDA}")


if __name__ == "__main__":
    main()
