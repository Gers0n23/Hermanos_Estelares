"""Calcula TODAS las soluciones de cada marco de pentominós y las guarda en el nivel (`soluciones_marco`).

Mecánicas HE-40 #8 (03-Oct-2026, PROVISIONAL): la pista del marco busca una solución compatible con
todas las piezas que Sofía ya puso, en vez de comparar contra una sola `solucion`. Así nunca le
devuelve (ni le cobra) una pieza bien puesta de otra solución válida.

Formato: una cadena por solución, de ancho×alto letras en orden fila a fila (índice = fila*ancho+col),
con la letra del pentominó que cubre cada celda y "." fuera del marco. Se guarda una sola solución por
cada familia de simetrías del tablero (espejo horizontal, vertical y giro de 180°): el motor genera las
demás al cargar. El 6×10 tiene 2.339 familias (9.356 soluciones en total).

Recorre `datos/niveles/**/*.json` y completa cada nivel o prueba que tenga `marco` + `piezas_marco`.
`generar_niveles_sofia.py` lo llama al final para que regenerar no borre el campo.

Uso: python herramientas/soluciones_marco.py
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import disenar_retos_sofia as D  # noqa: E402

NIVELES = D.RAIZ / "datos" / "niveles"


def cadena(solucion, ancho: int, alto: int, filas) -> str:
    """Una solución de `D.resolver_marco` como cadena (la usa el chequeo cruzado)."""
    letras = ["."] * (ancho * alto)
    for nombre, celdas in solucion:
        for x, y in celdas:
            letras[y * ancho + x] = nombre
    for y, fila in enumerate(filas):
        for x in range(ancho):
            if x >= len(fila) or fila[x] != "#":
                letras[y * ancho + x] = "."
    return "".join(letras)


def simetrias(filas, ancho: int, alto: int):
    """Transformaciones (espejo x, espejo y) que dejan el marco igual a sí mismo."""
    celdas = {(x, y) for y, f in enumerate(filas) for x, c in enumerate(f) if c == "#"}
    salida = []
    for ex in (False, True):
        for ey in (False, True):
            imagen = {((ancho - 1 - x) if ex else x, (alto - 1 - y) if ey else y) for x, y in celdas}
            if imagen == celdas:
                salida.append((ex, ey))
    return salida


def transformar(texto: str, ancho: int, alto: int, ex: bool, ey: bool) -> str:
    letras = [""] * len(texto)
    for i, letra in enumerate(texto):
        x, y = i % ancho, i // ancho
        letras[((alto - 1 - y) if ey else y) * ancho + ((ancho - 1 - x) if ex else x)] = letra
    return "".join(letras)


def enumerar(filas, piezas) -> list[str]:
    """Todas las soluciones (como cadenas) con bitmasks: siempre se llena la primera celda libre en
    orden columna a columna, y solo se prueban las colocaciones cuya primera celda es esa. Es la misma
    búsqueda que `D.resolver_marco`, pero indexada: el 6×10 completo tarda segundos, no horas."""
    ancho = max(len(f) for f in filas)
    alto = len(filas)
    bit = lambda x, y: x * alto + y  # columna a columna, como el "primero" de resolver_marco
    objetivo = D.celdas_marco(filas)
    lleno_inicial = 0
    for x in range(ancho):
        for y in range(alto):
            if (x, y) not in objetivo:
                lleno_inicial |= 1 << bit(x, y)
    total = (1 << (ancho * alto)) - 1
    por_celda = [[] for _ in range(ancho * alto)]
    for i, nombre in enumerate(piezas):
        for ori in D.orientaciones_celdas(D.PENTOMINOS[nombre]):
            for dx in range(ancho):
                for dy in range(alto):
                    celdas = [(x + dx, y + dy) for x, y in ori]
                    if not all(c in objetivo for c in celdas):
                        continue
                    mascara = 0
                    for x, y in celdas:
                        mascara |= 1 << bit(x, y)
                    primera = (mascara & -mascara).bit_length() - 1
                    por_celda[primera].append((i, mascara))
    soluciones = []
    elegidas = []
    usadas = [False] * len(piezas)

    def buscar(lleno):
        if lleno == total:
            letras = ["."] * (ancho * alto)
            for i, mascara in elegidas:
                for x in range(ancho):
                    for y in range(alto):
                        if mascara >> bit(x, y) & 1:
                            letras[y * ancho + x] = piezas[i]
            soluciones.append("".join(letras))
            return
        libre = (~lleno & (lleno + 1)).bit_length() - 1
        for i, mascara in por_celda[libre]:
            if not usadas[i] and not (mascara & lleno):
                usadas[i] = True
                elegidas.append((i, mascara))
                buscar(lleno | mascara)
                elegidas.pop()
                usadas[i] = False

    buscar(lleno_inicial)
    return soluciones


def todas(filas, piezas) -> list[str]:
    ancho = max(len(f) for f in filas)
    alto = len(filas)
    sims = simetrias(filas, ancho, alto)
    familias = set()
    for texto in enumerar(filas, piezas):
        familias.add(min(transformar(texto, ancho, alto, ex, ey) for ex, ey in sims))
    return sorted(familias)


def completar(datos) -> int:
    """Completa `soluciones_marco` en el nivel y en sus pruebas. Devuelve cuántos marcos tocó."""
    tocados = 0
    for bloque in [datos] + list(datos.get("pruebas", []) or []):
        if not isinstance(bloque, dict) or "marco" not in bloque or "piezas_marco" not in bloque:
            continue
        inicio = time.time()
        piezas = [str(p["id"]) for p in bloque["piezas_marco"]]
        bloque["soluciones_marco"] = todas(bloque["marco"], piezas)
        print(f"  marco {len(bloque['marco'][0])}x{len(bloque['marco'])}: {len(bloque['soluciones_marco'])} familias "
              f"({time.time() - inicio:.0f} s)")
        tocados += 1
    return tocados


def main():
    for ruta in sorted(NIVELES.rglob("*.json")):
        texto = ruta.read_text(encoding="utf-8")
        if '"piezas_marco"' not in texto:
            continue
        print(ruta.relative_to(D.RAIZ).as_posix())
        datos = json.loads(texto)
        if completar(datos):
            ruta.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
