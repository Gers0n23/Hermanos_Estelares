"""Redondea las articulaciones de un rig cutout como lo hizo el PO a mano con Sofía.

Técnica (ver assets/generadas/sofia_piezas/brazo_sup_der.png y pierna_sup_*.png): en cada
articulación la pieza de ATRÁS termina en un casquete redondeado pintado del color del
traje, escondido bajo la pieza de adelante en reposo. Así:
  - en reposo la fusión de las piezas es idéntica a la base (lo pintado queda tapado);
  - al rotar, lo que asoma bajo la pieza de adelante es traje liso con su propia línea
    de contorno, no un corte dentado ni un hueco — el cuerpo mantiene sus proporciones.

Lo que está tapado en reposo se puede repintar sin cambiar la base: por eso dentro de
cada casquete se reemplazan también los píxeles propios escondidos (restos de líneas,
halo, la copia del cinturón bajo el torso) por traje limpio. Y los píxeles de halo
semitransparente que dos piezas comparten quedan solo en la de ADELANTE: en la de atrás
giraban con ella y asomaban como flecos por los costados del codo o la rodilla.

Uso (desde un cortador de piezas):
    from articulaciones import redondear
    imagenes = redondear(imagenes, z, extensiones)
      imagenes    {nombre: RGBA uint8 HxWx4} — piezas a tamaño de lienzo
      z           {nombre: z_index del rig} — mayor = más al frente
      extensiones {nombre: [(centro_xy, radio[, opciones]), ...]} — casquetes en los
                  pivotes, solo bajo zona OPACA de adelante (bajo la burbuja
                  semitransparente del casco se vería). opciones: {"color": rgb} fija el
                  color cuando no es traje (piel del cuello, pelo), {"repintar": False}
                  conserva los píxeles propios escondidos (p. ej. el cuello del traje) y
                  {"linea": False} no traza contorno (pelo detrás de un brazo)
"""

from __future__ import annotations

import numpy as np
from scipy import ndimage

MARGEN = 3          # distancia mínima al borde de la pieza que tapa (antialias)
GROSOR_LINEA = 3    # contorno del casquete, como la línea del dibujo base
SUAVIZADO = 4       # radio de la apertura que redondea la silueta nueva
ALFA_HALO = 230     # por debajo de esto un píxel es halo/antialias, no cuerpo


def disco(forma, centro, radio):
    yy, xx = np.indices(forma)
    return (xx - centro[0]) ** 2 + (yy - centro[1]) ** 2 <= radio ** 2


def _elemento(radio):
    return disco((2 * radio + 1,) * 2, (radio, radio), radio)


def _color_linea(img: np.ndarray, mascara: np.ndarray) -> np.ndarray:
    """Tono del contorno exterior de la pieza (el trazo oscuro del dibujo)."""
    borde = mascara & ~ndimage.binary_erosion(mascara, _elemento(6))
    rgb = img[..., :3].astype(int)
    oscuro = borde & (rgb.sum(-1) < 150)
    if oscuro.sum() < 10:
        return np.array([40, 20, 20])
    return np.median(rgb[oscuro], axis=0).astype(int)


def _color_traje(img: np.ndarray, mascara: np.ndarray) -> np.ndarray:
    """Color PLANO del traje (como el rosado liso que pintó el PO en Sofía): mediana de
    los píxeles claros bien adentro de la pieza — lejos del halo y las líneas."""
    rgb = img[..., :3].astype(float)
    adentro = ndimage.distance_transform_edt(mascara) > 9
    claros = adentro & (rgb.sum(-1) > 330)
    if claros.sum() < 20:
        claros = adentro if adentro.sum() >= 20 else mascara
    return np.median(rgb[claros], axis=0)


def _sin_halo_duplicado(imagenes: dict, z: dict) -> dict:
    """Un píxel semitransparente compartido queda solo en la pieza de más adelante."""
    salida = {n: imagenes[n].copy() for n in imagenes}
    por_z = sorted(imagenes, key=lambda n: -z[n])
    visto = np.zeros(next(iter(imagenes.values())).shape[:2], bool)
    for n in por_z:
        a = salida[n][..., 3]
        halo = (a > 0) & (a < ALFA_HALO)
        a[halo & visto] = 0
        visto |= a > 0
    return salida


def redondear(imagenes: dict, z: dict, extensiones: dict) -> dict:
    imagenes = _sin_halo_duplicado(imagenes, z)
    nombres = list(imagenes)
    forma = next(iter(imagenes.values())).shape[:2]
    salida = {n: imagenes[n].copy() for n in nombres}
    for n in nombres:
        if n not in extensiones:
            continue
        propia = imagenes[n][..., 3] > 0
        # tapado = zona OPACA de las piezas de adelante, con margen contra su borde
        # exterior (no contra la propia pieza, para que el casquete nazca pegado a ella)
        delante = np.zeros(forma, bool)
        for otra in nombres:
            if otra != n and z[otra] > z[n]:
                delante |= imagenes[otra][..., 3] >= 250
        tapado = ndimage.binary_erosion(delante | propia, _elemento(MARGEN)) & delante

        casquete = np.zeros(forma, bool)
        fijos, conservar = [], np.zeros(forma, bool)
        sin_linea = np.zeros(forma, bool)
        for centro, radio, *extra in extensiones[n]:
            opciones = extra[0] if extra else {}
            area = disco(forma, centro, radio) & tapado
            casquete |= area
            if "color" in opciones:
                fijos.append((area, opciones["color"]))
            if not opciones.get("repintar", True):
                conservar |= area & propia
            if not opciones.get("linea", True):
                sin_linea |= area
        visible = propia & ~tapado
        nueva = propia | casquete
        # redondear la silueta sin tocar la parte visible en reposo
        nueva = ndimage.binary_opening(nueva, _elemento(SUAVIZADO)) | visible | (propia & ~casquete)
        pintar = nueva & casquete & ~conservar
        # solo parches pegados a la parte visible (nada de islas sueltas)
        partes, k = ndimage.label(pintar)
        if k:
            toca = ndimage.binary_dilation(propia & ~pintar, _elemento(2))
            vivas = [i for i in range(1, k + 1) if (toca & (partes == i)).any()]
            pintar = np.isin(partes, vivas)
        nueva = (nueva & ~casquete) | pintar | (casquete & conservar)
        if not pintar.any():
            continue

        img = salida[n]
        rgb = img[..., :3].astype(float)
        lleno = np.where(pintar[..., None], _color_traje(img, visible | propia), rgb)
        for area, color in fijos:
            lleno[pintar & area] = color
        # fundir 2 px con el dibujo para que la unión no marque escalón
        suave = np.stack([ndimage.gaussian_filter(lleno[..., c], 1.5) for c in range(3)], -1)
        lleno = np.where(pintar[..., None], suave, rgb)
        # línea de contorno solo en el borde exterior del casquete
        linea = pintar & ndimage.binary_dilation(~nueva, _elemento(GROSOR_LINEA - 1)) & ~sin_linea
        lleno[linea] = _color_linea(img, propia)
        img[..., :3] = np.where(pintar[..., None], lleno, rgb).astype(np.uint8)
        img[..., 3] = np.where(pintar, 255, np.where(nueva, img[..., 3], 0))
        print(f"  {n:20s} casquetes: {int(pintar.sum()):5d} px repintados bajo piezas de adelante")
    return salida


def centrar(mascara: np.ndarray, punto, eje, alcance: int = 90):
    """Centra una articulación en el miembro: recorre la perpendicular al `eje` que pasa
    por `punto`, toma el tramo de `mascara` que lo contiene y devuelve (centro, medio_ancho).
    Con el pivote centrado y un disco de radio = medio ancho, la pieza de atrás termina en
    un arco que al girar vuelve sobre sí mismo: no asoman esquinas ni flecos."""
    e = np.asarray(eje, float)
    e /= np.linalg.norm(e)
    p = np.array([-e[1], e[0]])
    dentro = []
    for t in range(-alcance, alcance + 1):
        x, y = np.round(np.asarray(punto) + p * t).astype(int)
        if 0 <= y < mascara.shape[0] and 0 <= x < mascara.shape[1] and mascara[y, x]:
            dentro.append(t)
    tramos = np.split(np.array(dentro), np.nonzero(np.diff(dentro) > 1)[0] + 1)
    tramo = min(tramos, key=lambda g: 0 if g.min() <= 0 <= g.max() else min(abs(g.min()), abs(g.max())))
    medio = (tramo.min() + tramo.max()) / 2
    centro = np.asarray(punto) + p * medio
    return (int(round(centro[0])), int(round(centro[1]))), (tramo.max() - tramo.min()) / 2


def guardar_pivotes(ruta, pivotes: dict) -> None:
    """pivotes.json junto a las piezas: el rig de Godot lee de aquí sus pivotes, así el
    cortador y el rig nunca quedan desincronizados."""
    import json
    lineas = [f"  {json.dumps(n)}: [{int(v[0])}, {int(v[1])}]" for n, v in sorted(pivotes.items())]
    ruta.write_text("{\n" + ",\n".join(lineas) + "\n}\n", encoding="utf-8")
