"""Busca y descarga modelos 3D libres de Poly Pizza (https://poly.pizza) para las cinemáticas de Blender.

Regla del proyecto (assets/terceros/LICENCIAS.md): solo CC0, o CC-BY con la atribución anotada.
Este script anota la atribución solo: cada descarga agrega una fila a
assets/terceros/polypizza/ATRIBUCIONES.md (título, autor, licencia y URL).

  python bajar_modelo.py --buscar piano              lista id, título y autor
  python bajar_modelo.py --bajar afr6GCpce_I --nombre guitarra
  python bajar_modelo.py --bajar afr6GCpce_I --nombre guitarra --solo-cc0   (no baja si no es CC0)

Python normal (no Blender). Los .glb quedan en assets/terceros/polypizza/modelos/.
"""
import argparse
import json
import os
import re
import urllib.parse
import urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))
DESTINO = os.path.abspath(os.path.join(AQUI, "..", "..", "assets", "terceros", "polypizza"))
AGENTE = {"User-Agent": "Mozilla/5.0"}


def leer(url, binario=False):
    with urllib.request.urlopen(urllib.request.Request(url, headers=AGENTE), timeout=60) as r:
        datos = r.read()
    return datos if binario else datos.decode("utf-8", "ignore")


def buscar(texto):
    pagina = leer("https://poly.pizza/search/" + urllib.parse.quote(texto))
    vistos = []
    for ident, titulo in re.findall(r'<a href="/m/([\w-]+)"><div class="MuiCardMedia-root" title="([^"]*)"', pagina):
        if ident not in vistos:
            vistos.append(ident)
            autor = re.search(r'href="/m/%s">[^<]*</a></span><span[^>]*><a[^>]*href="/u/([^"]*)"' % re.escape(ident),
                              pagina)
            print(f"{ident:14} {titulo:40} {autor.group(1) if autor else '?'}")
    print(f"{len(vistos)} resultados")


def bajar(ident, nombre, solo_cc0):
    pagina = leer("https://poly.pizza/m/" + ident)
    glb = re.search(r'static\.poly\.pizza/[\w-]+\.glb', pagina)
    licencia = re.search(r'"Licence":"([^"]*)"', pagina)
    titulo = re.search(r'"Title":"([^"]*)"', pagina)
    autor = re.search(r'"Creator":\{"Username":"([^"]*)"', pagina)
    licencia = licencia.group(1) if licencia else "?"
    titulo = json.loads('"%s"' % titulo.group(1)) if titulo else ident
    autor = json.loads('"%s"' % autor.group(1)) if autor else "?"
    if not glb:
        raise SystemExit("No se encontró el .glb en la página del modelo")
    if not (licencia.startswith("CC0") or licencia.startswith("CC-BY")):
        raise SystemExit(f"Licencia no permitida ({licencia}): no se descarga")
    if solo_cc0 and not licencia.startswith("CC0"):
        raise SystemExit(f"{titulo} es {licencia}, no CC0: no se descarga")
    os.makedirs(os.path.join(DESTINO, "modelos"), exist_ok=True)
    ruta = os.path.join(DESTINO, "modelos", nombre + ".glb")
    with open(ruta, "wb") as f:
        f.write(leer("https://" + glb.group(0), binario=True))
    tabla = os.path.join(DESTINO, "ATRIBUCIONES.md")
    if not os.path.exists(tabla):
        with open(tabla, "w", encoding="utf-8") as f:
            f.write("# Modelos de Poly Pizza\n\nDescargados con `poc/cinematica_blender/bajar_modelo.py`. "
                    "Los CC-BY exigen nombrar al autor en los créditos del juego.\n\n"
                    "| Archivo | Título | Autor | Licencia | Origen |\n|---|---|---|---|---|\n")
    fila = f"| `modelos/{nombre}.glb` | {titulo} | {autor} | {licencia} | https://poly.pizza/m/{ident} |\n"
    with open(tabla, encoding="utf-8") as f:
        ya = f"`modelos/{nombre}.glb`" in f.read()
    if not ya:
        with open(tabla, "a", encoding="utf-8") as f:
            f.write(fila)
    print(f"OK {ruta} ({os.path.getsize(ruta) // 1024} KB) — {titulo}, {autor}, {licencia}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--buscar")
    p.add_argument("--bajar")
    p.add_argument("--nombre")
    p.add_argument("--solo-cc0", action="store_true")
    a = p.parse_args()
    if a.buscar:
        buscar(a.buscar)
    if a.bajar:
        bajar(a.bajar, a.nombre or a.bajar, a.solo_cc0)
