"""Lectura/escritura mínima de archivos Krita (.kra/.krz) sin abrir Krita.

Permite al agente "ver" cada capa de un .kra (hoja de contacto) y exportar las
capas como PNG a tamaño de lienzo — el mismo formato que usan las piezas de
cutout (assets/generadas/<personaje>_piezas/<pieza>.png) — y también construir un
.kra nuevo con una capa por pieza para que el PO lo retoque en Krita.

Uso:
    python herramientas/kra.py ver <archivo.kra> <hoja.png>
    python herramientas/kra.py exportar <archivo.kra> <carpeta_salida> [--prefijo X]
    python herramientas/kra.py crear <salida.kra> <pieza1.png> [pieza2.png ...]
        (la primera pieza queda ARRIBA en el panel de capas = más al frente)

Formato de capa (Krita "VERSION 2"): tiles de 64x64, cada tile comprimido LZF
con los canales en planos separados (B, G, R, A) — ver kis_tile_compressor_2.cpp.
"""

from __future__ import annotations

import io
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

TILE = 64


# --- LZF (liblzf) --------------------------------------------------------------

def lzf_descomprimir(datos: bytes, largo_salida: int) -> bytes:
    salida = bytearray()
    i = 0
    while i < len(datos):
        ctrl = datos[i]
        i += 1
        if ctrl < 32:  # literal de ctrl+1 bytes
            salida += datos[i:i + ctrl + 1]
            i += ctrl + 1
        else:  # referencia hacia atrás
            largo = ctrl >> 5
            if largo == 7:
                largo += datos[i]
                i += 1
            ref = len(salida) - ((ctrl & 0x1F) << 8) - datos[i] - 1
            i += 1
            for _ in range(largo + 2):
                salida.append(salida[ref])
                ref += 1
    return bytes(salida[:largo_salida])


def lzf_comprimir_literal(datos: bytes) -> bytes:
    """'Compresión' LZF válida solo con literales: simple y siempre legible por Krita."""
    salida = bytearray()
    for i in range(0, len(datos), 32):
        trozo = datos[i:i + 32]
        salida.append(len(trozo) - 1)
        salida += trozo
    return bytes(salida)


# --- lectura -------------------------------------------------------------------

def _capa_a_imagen(binario: bytes, ancho: int, alto: int, dx: int, dy: int) -> Image.Image:
    lienzo = np.zeros((alto, ancho, 4), dtype=np.uint8)
    flujo = io.BytesIO(binario)
    cabecera = {}
    while True:
        linea = flujo.readline().decode().strip()
        clave, _, valor = linea.partition(" ")
        cabecera[clave] = valor
        if clave == "DATA":
            break
    tamano_pixel = int(cabecera.get("PIXELSIZE", 4))
    bytes_tile = TILE * TILE * tamano_pixel
    for _ in range(int(cabecera["DATA"])):
        x, y, _metodo, largo = flujo.readline().decode().strip().split(",")
        x, y, largo = int(x), int(y), int(largo)
        bloque = flujo.read(largo)
        crudo = lzf_descomprimir(bloque[1:], bytes_tile) if bloque[0] == 1 else bloque[1:]
        # planos por canal: BBBB...GGGG...RRRR...AAAA
        planos = np.frombuffer(crudo, dtype=np.uint8).reshape(tamano_pixel, TILE, TILE)
        tile = np.stack([planos[2], planos[1], planos[0], planos[3]], axis=-1)
        x0, y0 = x + dx, y + dy
        xa, ya = max(x0, 0), max(y0, 0)
        xb, yb = min(x0 + TILE, ancho), min(y0 + TILE, alto)
        if xa < xb and ya < yb:
            lienzo[ya:yb, xa:xb] = tile[ya - y0:yb - y0, xa - x0:xb - x0]
    return Image.fromarray(lienzo)


def leer_capas(ruta: Path) -> tuple[tuple[int, int], list[dict]]:
    """Devuelve (tamaño, capas) con capas en orden del panel de Krita (arriba = frente)."""
    z = zipfile.ZipFile(ruta)
    raiz = ET.fromstring(z.read("maindoc.xml"))
    imagen = next(e for e in raiz.iter() if e.tag.endswith("IMAGE"))
    ancho, alto = int(imagen.attrib["width"]), int(imagen.attrib["height"])
    nombre_doc = imagen.attrib["name"]
    capas = []
    for e in raiz.iter():
        if e.tag.endswith("layer") and e.attrib.get("nodetype") == "paintlayer":
            a = e.attrib
            binario = z.read(f"{nombre_doc}/layers/{a['filename']}")
            capas.append({
                "nombre": a["name"],
                "visible": a.get("visible") == "1",
                "imagen": _capa_a_imagen(binario, ancho, alto, int(a.get("x", 0)), int(a.get("y", 0))),
            })
    return (ancho, alto), capas


# --- escritura -----------------------------------------------------------------

def _imagen_a_capa(img: Image.Image) -> bytes:
    arr = np.array(img.convert("RGBA"))
    alto, ancho = arr.shape[:2]
    tiles = []
    for ty in range(0, alto, TILE):
        for tx in range(0, ancho, TILE):
            t = np.zeros((TILE, TILE, 4), dtype=np.uint8)
            parte = arr[ty:ty + TILE, tx:tx + TILE]
            t[:parte.shape[0], :parte.shape[1]] = parte
            if not t[..., 3].any():
                continue
            planos = np.stack([t[..., 2], t[..., 1], t[..., 0], t[..., 3]]).tobytes()
            bloque = b"\x01" + lzf_comprimir_literal(planos)
            tiles.append(f"{tx},{ty},LZF,{len(bloque)}\n".encode() + bloque)
    cab = f"VERSION 2\nTILEWIDTH {TILE}\nTILEHEIGHT {TILE}\nPIXELSIZE 4\nDATA {len(tiles)}\n".encode()
    return cab + b"".join(tiles)


def crear_kra(salida: Path, piezas: list[Path]) -> None:
    imagenes = [(p.stem, Image.open(p).convert("RGBA")) for p in piezas]
    ancho, alto = imagenes[0][1].size
    doc = "piezas"
    capas_xml = []
    z = zipfile.ZipFile(salida, "w")
    z.writestr(zipfile.ZipInfo("mimetype"), "application/x-krita")  # sin comprimir y primero
    for i, (nombre, img) in enumerate(imagenes):
        archivo = f"layer{i + 2}"
        z.writestr(f"{doc}/layers/{archivo}", _imagen_a_capa(img), zipfile.ZIP_DEFLATED)
        z.writestr(f"{doc}/layers/{archivo}.defaultpixel", b"\x00\x00\x00\x00", zipfile.ZIP_DEFLATED)
        capas_xml.append(
            f'<layer channelflags="" collapsed="0" colorlabel="0" colorspacename="RGBA" compositeop="normal" '
            f'filename="{archivo}" intimeline="0" locked="0" name="{nombre}" nodetype="paintlayer" '
            f'onionskin="0" opacity="255" selected="{"true" if i == 0 else "false"}" uuid="{{00000000-0000-0000-0000-{i + 1:012d}}}" '
            f'visible="1" x="0" y="0"/>')
    maindoc = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE DOC PUBLIC \'-//KDE//DTD krita 2.0//EN\' '
        '\'http://www.calligra.org/DTD/krita-2.0.dtd\'>\n'
        '<DOC xmlns="http://www.calligra.org/DTD/krita" kritaVersion="5.2.0" syntaxVersion="2.0" editor="Krita">\n'
        f' <IMAGE width="{ancho}" height="{alto}" name="{doc}" mime="application/x-kra" colorspacename="RGBA" '
        'profile="sRGB-elle-V2-srgbtrc.icc" x-res="100" y-res="100" description="">\n'
        f'  <layers>\n   {"".join(capas_xml)}\n  </layers>\n </IMAGE>\n</DOC>\n')
    z.writestr("maindoc.xml", maindoc, zipfile.ZIP_DEFLATED)
    fusion = Image.new("RGBA", (ancho, alto))
    for _, img in reversed(imagenes):
        fusion.alpha_composite(img)
    buf = io.BytesIO(); fusion.save(buf, "PNG")
    z.writestr("mergedimage.png", buf.getvalue(), zipfile.ZIP_DEFLATED)
    fusion.thumbnail((256, 256)); buf = io.BytesIO(); fusion.save(buf, "PNG")
    z.writestr("preview.png", buf.getvalue(), zipfile.ZIP_DEFLATED)
    z.close()


# --- hoja de contacto ----------------------------------------------------------

def hoja_capas(tamano, capas, salida: Path, columnas: int = 6) -> None:
    ancho, alto = tamano
    celda_w, rotulo = 260, 26
    celda_h = int(alto * celda_w / ancho)
    items = [("FUSION visible", None)] + [(f'{c["nombre"]}{"" if c["visible"] else " (oculta)"}', c) for c in capas]
    filas = -(-len(items) // columnas)
    hoja = Image.new("RGB", (columnas * (celda_w + 8) + 8, filas * (celda_h + rotulo + 8) + 8), "#1b1433")
    d = ImageDraw.Draw(hoja)
    try:
        fuente = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        fuente = ImageFont.load_default()
    for i, (texto, capa) in enumerate(items):
        x = 8 + (i % columnas) * (celda_w + 8)
        y = 8 + (i // columnas) * (celda_h + rotulo + 8)
        fondo = Image.new("RGBA", (ancho, alto), "#d9d9dc")
        # damero sutil: deja ver qué es transparente
        dam = np.array(fondo)
        dam[((np.indices((alto, ancho)).sum(0) // 16) % 2) == 1] = (200, 200, 205, 255)
        fondo = Image.fromarray(dam)
        if capa is None:
            for c in reversed(capas):
                if c["visible"] and c["nombre"].lower() != "fondo":
                    fondo.alpha_composite(c["imagen"])
        else:
            fondo.alpha_composite(capa["imagen"])
        hoja.paste(fondo.convert("RGB").resize((celda_w, celda_h)), (x, y + rotulo))
        d.text((x, y + 4), f"{i} · {texto}", fill="#ffce3d", font=fuente)
    hoja.save(salida)


def main() -> None:
    orden, *args = sys.argv[1:]
    if orden == "ver":
        tamano, capas = leer_capas(Path(args[0]))
        hoja_capas(tamano, capas, Path(args[1]))
        print(f"kra: {len(capas)} capas {tamano} -> {args[1]}")
    elif orden == "exportar":
        prefijo = args[args.index("--prefijo") + 1] if "--prefijo" in args else ""
        tamano, capas = leer_capas(Path(args[0]))
        carpeta = Path(args[1]); carpeta.mkdir(parents=True, exist_ok=True)
        for c in capas:
            c["imagen"].save(carpeta / f"{prefijo}{c['nombre']}.png")
        print(f"kra: exportadas {len(capas)} capas a {carpeta}")
    elif orden == "crear":
        crear_kra(Path(args[0]), [Path(p) for p in args[1:]])
        print(f"kra: creado {args[0]} con {len(args) - 1} capas")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
