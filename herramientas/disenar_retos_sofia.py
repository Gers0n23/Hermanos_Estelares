"""Diseño y verificación de los retos de Sofía (dificultad v3, decisión del PO 14-Sep-2026).

Tangram en red: con `a` = cateto del triángulo chico, las 7 piezas del tangram tienen una
orientación "de red" en la que todos sus vértices caen en múltiplos enteros de `a`. Cada celda
unitaria se divide en 4 cuartos triangulares (por sus dos diagonales) y toda pieza en orientación
de red es una unión de cuartos. Así, armar una silueta es un problema de cobertura exacta sobre
cuartos, que se resuelve por backtracking en milisegundos. Sirve para:

- verificar que cada silueta diseñada tiene solución y contar cuántas tiene;
- comprobar si el espejo es obligatorio (sin solución con el paralelogramo de la bandeja);
- convertir una solución en los campos que lee el motor `encajar` (forma, ancho, alto,
  rotacion, espejo, x, y), con la misma convención de giro que Godot;
- lo mismo para marcos de pentominós (cobertura exacta sobre celdas).

Uso:
  python herramientas/disenar_retos_sofia.py tangram   # verifica siluetas y dibuja vista previa
  python herramientas/disenar_retos_sofia.py marcos
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent

# ---------------------------------------------------------------------------
# Tangram
# ---------------------------------------------------------------------------

BASES = {  # piezas en orientación de red (a = 1), y abajo
    "L": [(0, 0), (2, 0), (0, 2)],
    "M": [(0, 0), (2, 0), (1, 1)],
    "S": [(0, 0), (1, 0), (0, 1)],
    "Q": [(0, 0), (1, 0), (1, 1), (0, 1)],
    "P": [(0, 0), (1, 0), (2, 1), (1, 1)],
}
JUEGO_TANGRAM = ["L", "L", "M", "S", "S", "Q", "P"]


def _normalizar(puntos):
    mx = min(p[0] for p in puntos)
    my = min(p[1] for p in puntos)
    return [(p[0] - mx, p[1] - my) for p in puntos]


def _dentro(p, poligono) -> bool:
    x, y = p
    dentro = False
    n = len(poligono)
    for i in range(n):
        x1, y1 = poligono[i]
        x2, y2 = poligono[(i + 1) % n]
        if (y1 > y) != (y2 > y):
            corte = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
            if x < corte:
                dentro = not dentro
    return dentro


CENTROS_CUARTO = [(0.5, 1 / 6), (5 / 6, 0.5), (0.5, 5 / 6), (1 / 6, 0.5)]


def cuartos(poligono) -> frozenset:
    xs = [p[0] for p in poligono]
    ys = [p[1] for p in poligono]
    salida = set()
    for i in range(math.floor(min(xs)), math.ceil(max(xs))):
        for j in range(math.floor(min(ys)), math.ceil(max(ys))):
            for q, (cx, cy) in enumerate(CENTROS_CUARTO):
                if _dentro((i + cx, j + cy), poligono):
                    salida.add((i, j, q))
    return frozenset(salida)


def orientaciones(tipo: str):
    """Lista de (poligono_normalizado, quiral) distintos: giros de 90° y espejo."""
    vistos = {}
    for espejo in (False, True):
        for k in range(4):
            pts = BASES[tipo]
            if espejo:
                pts = [(-x, y) for x, y in pts]
            for _ in range(k):
                pts = [(-y, x) for x, y in pts]  # 90° horario en pantalla (y abajo)
            pts = _normalizar(pts)
            clave = cuartos(pts)
            if clave not in vistos:
                vistos[clave] = (pts, espejo)
    return list(vistos.values())


def resolver_tangram(silueta, piezas, max_soluciones=200, quiralidad_p=None):
    """Cobertura exacta. `quiralidad_p`: None = libre, False/True = solo esa quiralidad de P."""
    objetivo = cuartos(silueta)
    xs = [p[0] for p in silueta]
    ys = [p[1] for p in silueta]
    colocaciones = {}
    for tipo in set(piezas):
        lista = []
        for pts, espejo in orientaciones(tipo):
            if tipo == "P" and quiralidad_p is not None and espejo != quiralidad_p:
                continue
            w = max(p[0] for p in pts)
            h = max(p[1] for p in pts)
            for dx in range(math.floor(min(xs)), math.ceil(max(xs)) - w + 1):
                for dy in range(math.floor(min(ys)), math.ceil(max(ys)) - h + 1):
                    movido = [(x + dx, y + dy) for x, y in pts]
                    c = cuartos(movido)
                    if c <= objetivo:
                        lista.append((c, movido))
        colocaciones[tipo] = lista
    soluciones = []
    restantes = list(piezas)

    def buscar(libres: frozenset, elegidas):
        if len(soluciones) >= max_soluciones:
            return
        if not libres:
            soluciones.append(list(elegidas))
            return
        primero = min(libres)
        probados = set()
        for idx, tipo in enumerate(restantes):
            if tipo is None or tipo in probados:
                continue
            probados.add(tipo)
            for c, movido in colocaciones[tipo]:
                if primero in c and c <= libres:
                    restantes[idx] = None
                    elegidas.append((tipo, movido))
                    buscar(libres - c, elegidas)
                    elegidas.pop()
                    restantes[idx] = tipo
        return

    if sum(len(cuartos(BASES[t])) for t in piezas) != len(objetivo):
        return []
    buscar(objetivo, [])
    return soluciones


# Formas del motor (geometria_formas.gd) centradas en el origen, sin girar.
RAIZ2 = math.sqrt(2)


def contorno_godot(forma: str, ancho: float, alto: float):
    mx, my = ancho / 2, alto / 2
    if forma == "cuadrado":
        return [(-mx, -my), (mx, -my), (mx, my), (-mx, my)]
    if forma == "triangulo_rect":
        return [(-mx, -my), (mx, my), (-mx, my)]
    if forma == "paralelogramo":
        inc = min(alto, mx)
        return [(-mx + inc, -my), (mx, -my), (mx - inc, my), (-mx, my)]
    raise ValueError(forma)


FORMA_GODOT = {  # tipo -> (forma, ancho, alto) en unidades a
    "L": ("triangulo_rect", 2, 2),
    "M": ("triangulo_rect", RAIZ2, RAIZ2),
    "S": ("triangulo_rect", 1, 1),
    "Q": ("cuadrado", 1, 1),
    "P": ("paralelogramo", 2, 1),
}


def _girar(p, grados):
    ang = math.radians(grados)
    return (p[0] * math.cos(ang) - p[1] * math.sin(ang), p[0] * math.sin(ang) + p[1] * math.cos(ang))


def _centroide(pts):
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def a_godot(tipo: str, poligono):
    """Busca rotacion (múltiplo de 45) y espejo con que la forma del motor coincide con el polígono."""
    forma, ancho, alto = FORMA_GODOT[tipo]
    base = contorno_godot(forma, ancho, alto)
    objetivo = sorted((round(x, 4), round(y, 4)) for x, y in poligono)
    cx, cy = _centroide(poligono)
    for espejo in (False, True):
        for k in range(8):
            pts = [(-x, y) for x, y in base] if espejo else base
            pts = [_girar(p, 45 * k) for p in pts]
            bx, by = _centroide(pts)
            tx, ty = cx - bx, cy - by
            movidos = sorted((round(x + tx, 4), round(y + ty, 4)) for x, y in pts)
            if all(abs(a[0] - b[0]) < 1e-3 and abs(a[1] - b[1]) < 1e-3 for a, b in zip(movidos, objetivo)):
                return {"forma": forma, "ancho": ancho, "alto": alto, "rotacion": 45 * k, "espejo": espejo, "x": tx, "y": ty}
    raise RuntimeError(f"no calza {tipo} {poligono}")


# ---------------------------------------------------------------------------
# Pentominós
# ---------------------------------------------------------------------------

PENTOMINOS = {
    "F": [(1, 0), (2, 0), (0, 1), (1, 1), (1, 2)],
    "I": [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)],
    "L": [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)],
    "N": [(1, 0), (1, 1), (0, 2), (1, 2), (0, 3)],
    "P": [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)],
    "T": [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2)],
    "U": [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1)],
    "V": [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)],
    "W": [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)],
    "X": [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)],
    "Y": [(1, 0), (0, 1), (1, 1), (1, 2), (1, 3)],
    "Z": [(0, 0), (1, 0), (1, 1), (1, 2), (2, 2)],
}


def orientaciones_celdas(celdas):
    vistas = set()
    salida = []
    for espejo in (False, True):
        for k in range(4):
            pts = [(-x, y) for x, y in celdas] if espejo else list(celdas)
            for _ in range(k):
                pts = [(-y, x) for x, y in pts]
            mx = min(p[0] for p in pts)
            my = min(p[1] for p in pts)
            clave = frozenset((x - mx, y - my) for x, y in pts)
            if clave not in vistas:
                vistas.add(clave)
                salida.append(clave)
    return salida


def celdas_marco(filas):
    return frozenset((c, r) for r, fila in enumerate(filas) for c, ch in enumerate(fila) if ch == "#")


def resolver_marco(filas, piezas, max_soluciones=1, sin_espejo=False):
    objetivo = celdas_marco(filas)
    ancho = max(len(f) for f in filas)
    alto = len(filas)
    colocaciones = {}
    for nombre in set(piezas):
        lista = []
        oris = orientaciones_celdas(PENTOMINOS[nombre])
        if sin_espejo:
            oris = [o for o in oris if o in orientaciones_celdas_sin_espejo(PENTOMINOS[nombre])]
        for ori in oris:
            for dx in range(ancho):
                for dy in range(alto):
                    c = frozenset((x + dx, y + dy) for x, y in ori)
                    if c <= objetivo:
                        lista.append(c)
        colocaciones[nombre] = lista
    soluciones = []
    restantes = list(piezas)

    def buscar(libres, elegidas):
        if len(soluciones) >= max_soluciones:
            return
        if not libres:
            soluciones.append(list(elegidas))
            return
        primero = min(libres, key=lambda p: (p[0], p[1]))
        for idx, nombre in enumerate(restantes):
            if nombre is None:
                continue
            for c in colocaciones[nombre]:
                if primero in c and c <= libres:
                    restantes[idx] = None
                    elegidas.append((nombre, sorted(c)))
                    buscar(libres - c, elegidas)
                    elegidas.pop()
                    restantes[idx] = nombre

    buscar(objetivo, [])
    return soluciones


def orientaciones_celdas_sin_espejo(celdas):
    salida = []
    pts0 = list(celdas)
    for k in range(4):
        pts = pts0
        for _ in range(k):
            pts = [(-y, x) for x, y in pts]
        mx = min(p[0] for p in pts)
        my = min(p[1] for p in pts)
        salida.append(frozenset((x - mx, y - my) for x, y in pts))
    return salida


if __name__ == "__main__":
    print("ver herramientas/disenar_retos_sofia.py: importar desde un script de diseño")
