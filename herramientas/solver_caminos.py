"""Solver y validador de tableros de «Cada quien a su casa» (motor caminos, tipo Flow Free).

docs/fichas/motor-caminos.md §11.2. Sin dependencias: lo usan `generar_niveles_caminos.py` (para fabricar y
verificar los tableros) y se puede correr solo para revisar los niveles ya escritos:

    python3 herramientas/solver_caminos.py            # valida todos los caminos_*.json de Animalia

Formato del tablero (igual que el JSON del nivel): filas de texto; `A-Z` animal, `a-z` su casa, `#` roca,
`+` puente (dos caminos que se cruzan en recto: uno horizontal y otro vertical), `.` vacía.

Reglas:
- Los caminos van de celda vecina a celda vecina (sin diagonales) y no se cruzan ni se tocan, salvo en un
  puente, que se atraviesa siempre en recto (nunca se dobla encima).
- Con `llenar`, todas las celdas (y las dos direcciones de cada puente) deben quedar cubiertas.

`contar_soluciones(..., limite=2)` cuenta hasta `limite` soluciones (para saber si es única).
`solucion_minima(...)` (sin llenar): la solución de menor largo total y si esa mínima es única (lo que dibujan
la guía y la mano fantasma, `planeta-animalia-zonas.md` §12.2).
"""

from __future__ import annotations

import glob
import json
import os
import sys
from collections import deque

DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1)]


class Tablero:
    def __init__(self, filas: list[str]):
        self.filas = filas
        self.alto = len(filas)
        self.ancho = len(filas[0])
        self.n = self.ancho * self.alto
        self.rocas = set()
        self.puentes = set()
        self.animales = {}
        self.casas = {}
        for y, fila in enumerate(filas):
            assert len(fila) == self.ancho, "filas de distinto largo"
            for x, c in enumerate(fila):
                i = y * self.ancho + x
                if c == "#":
                    self.rocas.add(i)
                elif c == "+":
                    self.puentes.add(i)
                elif c.isupper():
                    self.animales[c] = i
                elif c.islower():
                    self.casas[c.upper()] = i
        self.pares = sorted(self.animales)
        for p in self.pares:
            assert p in self.casas, "el animal %s no tiene casa" % p

    def xy(self, i):
        return i % self.ancho, i // self.ancho

    def idx(self, x, y):
        return y * self.ancho + x

    def vecino(self, i, d):
        x, y = self.xy(i)
        nx, ny = x + d[0], y + d[1]
        if 0 <= nx < self.ancho and 0 <= ny < self.alto:
            return self.idx(nx, ny)
        return -1


def _eje(d):
    return 0 if d[1] == 0 else 1  # 0 horizontal, 1 vertical


class _Busqueda:
    """DFS que hace crecer un camino a la vez desde su animal (cada solución se cuenta una sola vez)."""

    def __init__(self, t: Tablero, llenar: bool, limite: int, max_nodos: int, minimizar: bool = False):
        self.t = t
        self.llenar = llenar
        self.limite = limite
        self.max_nodos = max_nodos
        self.minimizar = minimizar
        self.nodos = 0
        self.agotado = False
        self.soluciones = []
        self.mejor_largo = 10 ** 9
        self.n_mejor = 0
        # ocupación: celdas normales -> par o None; puentes -> [h, v]
        self.occ = [None] * t.n
        self.occ_p = {i: [None, None] for i in t.puentes}
        for i in t.rocas:
            self.occ[i] = "#"
        for p in t.pares:
            self.occ[t.animales[p]] = p
            self.occ[t.casas[p]] = p
        self.cabeza = {p: t.animales[p] for p in t.pares}
        self.hecho = {p: False for p in t.pares}
        self.caminos = {p: [t.animales[p]] for p in t.pares}

    # --- movimientos ---
    def movidas(self, p):
        t = self.t
        h = self.cabeza[p]
        meta = t.casas[p]
        res = []
        for d in DIRS:
            n = t.vecino(h, d)
            if n < 0:
                continue
            pasos = []
            # atravesar puentes en recto
            while n in t.puentes:
                if self.occ_p[n][_eje(d)] is not None:
                    n = -1
                    break
                pasos.append(n)
                n = t.vecino(n, d)
                if n < 0:
                    break
            if n < 0:
                continue
            if n == meta:
                res.append((pasos, n, d, True))
            elif self.occ[n] is None:
                res.append((pasos, n, d, False))
        return res

    def aplicar(self, p, mov):
        pasos, n, d, fin = mov
        for b in pasos:
            self.occ_p[b][_eje(d)] = p
            self.caminos[p].append(b)
        if not fin:
            self.occ[n] = p
        self.caminos[p].append(n)
        self.cabeza[p] = n
        self.hecho[p] = fin

    def deshacer(self, p, mov, cabeza_prev):
        pasos, n, d, fin = mov
        for b in pasos:
            self.occ_p[b][_eje(d)] = None
            self.caminos[p].pop()
        if not fin:
            self.occ[n] = None
        self.caminos[p].pop()
        self.cabeza[p] = cabeza_prev
        self.hecho[p] = False

    # --- poda ---
    def _libre(self, i):
        return self.occ[i] is None

    def _vecinos_libres(self, i):
        """Nodos libres alcanzables desde la celda normal i (atravesando puentes libres en recto)."""
        t = self.t
        for d in DIRS:
            n = t.vecino(i, d)
            ok = True
            while n >= 0 and n in t.puentes:
                if self.occ_p[n][_eje(d)] is not None:
                    ok = False
                    break
                n = t.vecino(n, d)
            if ok and n >= 0:
                yield n

    def poda(self):
        t = self.t
        pendientes = [p for p in t.pares if not self.hecho[p]]
        # componentes de celdas libres (normales); los puentes se atraviesan
        comp = [-1] * t.n
        ncomp = 0
        for i in range(t.n):
            if i in t.puentes or comp[i] >= 0 or not self._libre(i):
                continue
            cola = deque([i])
            comp[i] = ncomp
            while cola:
                c = cola.popleft()
                for n in self._vecinos_libres(c):
                    if self._libre(n) and n not in t.puentes and comp[n] < 0:
                        comp[n] = ncomp
                        cola.append(n)
            ncomp += 1

        def comps_de(i, incluir=True):
            s = set()
            if incluir and comp[i] >= 0:
                s.add(comp[i])
            for n in self._vecinos_libres(i):
                if comp[n] >= 0:
                    s.add(comp[n])
            return s

        tocadas = set()
        for p in pendientes:
            h = self.cabeza[p]
            meta = t.casas[p]
            # ¿cabeza vecina directa de la casa (o por puentes libres)?
            directo = meta in set(self._vecinos_libres(h))
            ch = comps_de(h, False)
            cm = comps_de(meta, False)
            comun = ch & cm
            if not directo and not comun:
                return False
            tocadas |= comun
        if self.llenar:
            for c in range(ncomp):
                if c not in tocadas:
                    return False
            # callejones: una celda libre necesita 2 salidas (libres, cabezas o casas pendientes)
            especiales = set()
            for p in pendientes:
                especiales.add(self.cabeza[p])
                especiales.add(t.casas[p])
            for i in range(t.n):
                if i in t.puentes or not self._libre(i):
                    continue
                salidas = 0
                for n in self._vecinos_libres(i):
                    if self._libre(n) or n in especiales:
                        salidas += 1
                if salidas < 2:
                    return False
            # direcciones libres de puentes: deben poder recorrerse
            for b in t.puentes:
                for eje, (d1, d2) in enumerate((((1, 0), (-1, 0)), ((0, 1), (0, -1)))):
                    if self.occ_p[b][eje] is not None:
                        continue
                    for d in (d1, d2):
                        n = t.vecino(b, d)
                        while n >= 0 and n in t.puentes:
                            n = t.vecino(n, d)
                        if n < 0 or not (self._libre(n) or n in especiales):
                            return False
        return True

    def completo(self):
        if not self.llenar:
            return True
        if any(o is None for i, o in enumerate(self.occ) if i not in self.t.puentes):
            return False
        return all(v[0] is not None and v[1] is not None for v in self.occ_p.values())

    def largo_total(self):
        return sum(len(c) for c in self.caminos.values())

    def resolver(self):
        self.nodos += 1
        if self.nodos > self.max_nodos:
            self.agotado = True
            return
        pendientes = [p for p in self.t.pares if not self.hecho[p]]
        if not pendientes:
            if self.completo():
                if self.minimizar:
                    largo = self.largo_total()
                    if largo < self.mejor_largo:
                        self.mejor_largo = largo
                        self.n_mejor = 1
                        self.soluciones = [{p: list(c) for p, c in self.caminos.items()}]
                    elif largo == self.mejor_largo:
                        self.n_mejor += 1
                else:
                    self.soluciones.append({p: list(c) for p, c in self.caminos.items()})
            return
        if self.minimizar:
            # cota: largo actual + distancia manhattan de cada pendiente
            cota = self.largo_total()
            for p in pendientes:
                hx, hy = self.t.xy(self.cabeza[p])
                mx, my = self.t.xy(self.t.casas[p])
                cota += abs(hx - mx) + abs(hy - my)
            if cota > self.mejor_largo:
                return
        mejor = None
        mejor_movs = None
        for p in pendientes:
            movs = self.movidas(p)
            if not movs:
                return
            if mejor is None or len(movs) < len(mejor_movs):
                mejor, mejor_movs = p, movs
                if len(movs) == 1:
                    break
        p = mejor
        meta = self.t.casas[p]
        mx, my = self.t.xy(meta)

        def dist(m):
            x, y = self.t.xy(m[1])
            return abs(x - mx) + abs(y - my)

        mejor_movs.sort(key=lambda m: (not m[3], dist(m)))
        for mov in mejor_movs:
            prev = self.cabeza[p]
            self.aplicar(p, mov)
            if self.poda():
                self.resolver()
            self.deshacer(p, mov, prev)
            if not self.minimizar and len(self.soluciones) >= self.limite:
                return
            if self.agotado:
                return


def contar_soluciones(filas, llenar=True, limite=2, max_nodos=400000):
    """Devuelve (cantidad hasta `limite`, soluciones, agotado). Soluciones: {par: [índices de celda]}."""
    t = Tablero(filas)
    b = _Busqueda(t, llenar, limite, max_nodos)
    if b.poda():
        b.resolver()
    return len(b.soluciones), b.soluciones, b.agotado


def solucion_minima(filas, max_nodos=400000):
    """Sin llenar: (solución de largo total mínimo, cantidad de mínimas, agotado)."""
    t = Tablero(filas)
    b = _Busqueda(t, False, 1, max_nodos, minimizar=True)
    if b.poda():
        b.resolver()
    return (b.soluciones[0] if b.soluciones else None), b.n_mejor, b.agotado


def a_xy(t: Tablero, sol):
    return {p: [list(t.xy(i)) for i in c] for p, c in sol.items()}


def validar_solucion(filas, solucion, llenar):
    """Comprueba que `solucion` ({par: [[x,y],...]}) cumple las reglas. Devuelve lista de errores."""
    t = Tablero(filas)
    errores = []
    usadas = {}
    usos_puente = {}
    for p in t.pares:
        camino = solucion.get(p)
        if not camino:
            errores.append("falta el camino de %s" % p)
            continue
        celdas = [t.idx(x, y) for x, y in camino]
        if celdas[0] != t.animales[p] or celdas[-1] != t.casas[p]:
            errores.append("%s no va de su animal a su casa" % p)
        for k, c in enumerate(celdas):
            if c in t.rocas:
                errores.append("%s pisa una roca" % p)
            if k > 0:
                ax, ay = t.xy(celdas[k - 1])
                bx, by = t.xy(c)
                if abs(ax - bx) + abs(ay - by) != 1:
                    errores.append("%s salta celdas" % p)
            if c in t.puentes:
                if k == 0 or k == len(celdas) - 1:
                    errores.append("%s empieza o termina en un puente" % p)
                    continue
                ax, ay = t.xy(celdas[k - 1])
                bx, by = t.xy(celdas[k + 1])
                if not (ax == bx or ay == by):
                    errores.append("%s dobla sobre un puente" % p)
                eje = 0 if ay == by else 1
                clave = (c, eje)
                if clave in usos_puente:
                    errores.append("puente usado dos veces en la misma direccion")
                usos_puente[clave] = p
            else:
                if c in usadas and usadas[c] != p:
                    errores.append("%s cruza a %s" % (p, usadas[c]))
                if c in usadas and usadas[c] == p:
                    errores.append("%s pasa dos veces por la misma celda" % p)
                usadas[c] = p
    if llenar:
        for i in range(t.n):
            if i in t.rocas:
                continue
            if i in t.puentes:
                if (i, 0) not in usos_puente or (i, 1) not in usos_puente:
                    errores.append("puente sin cubrir en %s" % str(t.xy(i)))
            elif i not in usadas:
                errores.append("celda sin cubrir en %s" % str(t.xy(i)))
    return errores


def validar_nivel(ruta):
    with open(ruta, encoding="utf-8") as f:
        nivel = json.load(f)
    llenar = bool(nivel.get("llenar", False))
    problemas = []
    for tab in nivel.get("tableros", []):
        filas = tab["celdas"]
        errores = validar_solucion(filas, tab.get("solucion", {}), llenar)
        if errores:
            problemas.append("%s: %s" % (tab["id"], "; ".join(errores[:3])))
            continue
        if llenar and tab.get("solucion_unica", True):
            n, _, agotado = contar_soluciones(filas, True, 2, 2_000_000)
            if n != 1 or agotado:
                problemas.append("%s: %s" % (tab["id"], "sin agotar: %d soluciones" % n if not agotado else "busqueda agotada"))
    return problemas


if __name__ == "__main__":
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    rutas = sorted(glob.glob(os.path.join(raiz, "datos/niveles/animalia/*/caminos_*.json")))
    total = 0
    for ruta in rutas:
        problemas = validar_nivel(ruta)
        rel = os.path.relpath(ruta, raiz)
        if problemas:
            total += len(problemas)
            for p in problemas:
                print("FALLA %s %s" % (rel, p))
        else:
            print("ok    %s" % rel)
    print("RESULTADO:", "OK" if total == 0 else "%d problemas" % total)
    sys.exit(0 if total == 0 else 1)
