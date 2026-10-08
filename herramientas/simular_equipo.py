"""HE-66 / HE-69 / HE-59: simulador de la Batalla final de Arcoiris y de Parejas en equipo.

Autor: disenador-niveles, 07-Oct-2026. Ficha de calibracion:
docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md

Que mide (3.000 partidas por escenario):
- % de partidas ganadas AL PRIMER INTENTO para cada valor de pasos_rival (3 a 10);
- duracion de la ronda sin derrotas (p50 y p80), con pases reales de tablet de 8-12 s (M1 UX HE-66);
- turnos por hermano y % de partidas en que CADA hermano juega >= 2 turnos (B2.3 UX HE-66).

Reglas modeladas (docs/fichas/modo-equipo.md §4.2, §4.3, §5.2, §14.3):
- orden maxi_intercalado (M N M S con los tres); el rival salta en el pase despues de un turno de Nicole o
  Sofia (nunca tras Maxi); cada 3 aciertos en un mismo turno retrocede una galleta (minimo 0);
- Parejas: Maxi forma 1 par con halo (prefiere uno que nadie vio); Nicole memoria ~3 cartas y segunda
  oportunidad; Sofia memoria ~5 y pasa con el primer fallo; todos ven las cartas que se dan vuelta; vistazo
  de pares completos; lupa = cada uno recuerda tantas cartas como su memoria. NO modela el comodin ni la
  ayuda de Nicole tras 2 turnos sin par (ambos ayudan: el resultado es conservador);
- Rio: cadena de gotas en tramos; Maxi revienta siempre el tramo mas largo (N2: umbral 2); Nicole y Sofia
  3 disparos, eligen entre la gota de la boca y la de reserva, apuntan al tramo mas largo de ese color
  (acierto 65 % Nicole con guia, 85 % Sofia); fallo = gota suelta en un borde al azar; cadena = 2 aciertos;
- Formas: tope {1, 2, 3}; Nicole acierta 85 % y tiene segunda oportunidad; Sofia 82 % (piezas giradas) y
  pasa con el primer fallo.

Los porcentajes de acierto y los segundos por jugada son ESTIMACIONES (los mismos criterios que
herramientas/agregar_reto_parejas.py); el playtest manda.

v2 (07-Oct-2026, tras la primera corrida): agrega el TOPE DE PARES POR TURNO propuesto para Parejas en
equipo (campo `pares_max_turno_propuesta` de cada composicion: al llegar al tope el turno termina en
celebracion, como en Formas), el retroceso por "turno perfecto" (opcional) y la recomendacion automatica
del menor pasos_rival que cumple la meta (Rio y Formas 85 %, Parejas 80 %, nicole+sofia 75 %).

v3 (07-Oct-2026, modo-equipo.md v6.1 §5.2): modela `resbalon_tras_racha` en el Rio (si el turno hizo
retroceder al rival por la racha de 3, en el pase se resbala y no avanza) y corre el Rio SIN y CON resbalon
para comparar; lee gotas, colores y pasos_rival de batalla/rio_equipo.json. Corrige un error de la v2: la
cadena de Maxi en el Rio (3 aciertos) hacia retroceder al rival, pero `maxi_mueve_rival` es false; por eso
el Rio "sin resbalon" de la v3 puede quedar 1-2 puntos bajo el 86 % de la v2.

Uso: python herramientas/simular_equipo.py               (batalla + los 5 parejas_equipo.json)
     python herramientas/simular_equipo.py --batalla     (solo la batalla)
     ... --sin-tope     ignora el tope propuesto (regla vigente de la ficha)
     ... --racha3       retroceso por racha de 3 (regla anterior); por defecto, "turno perfecto" (PO 07-Oct-2026)
     ... --sin-resbalon tras un turno perfecto el rival igual avanza en ese pase (regla anterior a UX N10)
No escribe ningun archivo.
"""
import json
import random
import statistics
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
NIVELES = RAIZ / "datos" / "niveles" / "arcoiris"
ZONAS = ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
PARTIDAS = 3000
PASE_S = (8.0, 12.0)
RITUAL_MAXI_S = 1.2
PERFIL = {"maxi": "semilla", "nicole": "brote", "sofia": "estrella"}


def ciclo(equipo):
    e = sorted(equipo)
    if e == ["maxi", "nicole", "sofia"]:
        return ["maxi", "nicole", "maxi", "sofia"]
    return e  # el orden alfabetico coincide con el de edad (§8)


def recordar(memoria, pos, capacidad):
    if pos in memoria:
        memoria.remove(pos)
    memoria.append(pos)
    while len(memoria) > capacidad:
        memoria.pop(0)


# ---------------------------------------------------------------------------------------------
# Juegos: cada uno expone turno(hermano) -> (aciertos, segundos, termino_con_fallo, revela_s) y terminado()
# ---------------------------------------------------------------------------------------------

class Parejas:
    CAP = {"nicole": 3, "sofia": 5}
    DESPISTE = {"nicole": 0.15, "sofia": 0.08}
    T = {"nicole": (3.0, 1.0), "sofia": (2.0, 0.9)}  # (segundos por jugada, extra si falla)

    def __init__(self, rng, pares, equipo, vistazo_pares, lupa, tope=None):
        self.rng = rng
        self.tope = tope or {}  # PROPUESTA 07-Oct: pares maximos por turno {"nicole": 2, "sofia": 3}
        self.cartas = [g for g in range(pares) for _ in range(2)]
        rng.shuffle(self.cartas)
        self.pend = set(range(len(self.cartas)))
        self.vistas = set()
        self.mem = {h: [] for h in equipo if h != "maxi"}
        self.lupa = rng.randrange(pares) if lupa else None
        for g in rng.sample(range(pares), min(vistazo_pares, pares)):
            for p in self._pos(g):
                self._ver(p)

    def _pos(self, g):
        return [p for p in range(len(self.cartas)) if self.cartas[p] == g]

    def _ver(self, pos):
        self.vistas.add(pos)
        for h, m in self.mem.items():
            recordar(m, pos, self.CAP[h])

    def terminado(self):
        return not self.pend

    def _formar(self, g):
        for p in self._pos(g):
            self.pend.discard(p)
            for m in self.mem.values():
                if p in m:
                    m.remove(p)
        if g == self.lupa and self.pend:
            for h, m in self.mem.items():
                for p in self.rng.sample(sorted(self.pend), min(self.CAP[h], len(self.pend))):
                    recordar(m, p, self.CAP[h])

    def turno(self, h):
        if h == "maxi":
            grupos = sorted({self.cartas[p] for p in self.pend})
            nuevos = [g for g in grupos if not any(p in self.vistas for p in self._pos(g))]
            self._formar(self.rng.choice(nuevos or grupos))
            return 1, 5.0, False, 0.0
        rng, m, cap = self.rng, self.mem[h], self.CAP[h]
        if m and rng.random() < self.DESPISTE[h]:
            m.pop(rng.randrange(len(m)))
        t_jugada, t_fallo = self.T[h]
        permitidos = 2 if h == "nicole" else 1
        aciertos, fallos, seg = 0, 0, 1.0
        while self.pend:
            conocidos = {}
            for p in m:
                if p in self.pend:
                    conocidos.setdefault(self.cartas[p], []).append(p)
            completo = next((g for g, ps in conocidos.items() if len(ps) == 2), None)
            if completo is not None:
                ok, g = True, completo
            else:
                sin_ver = [p for p in self.pend if p not in self.vistas]
                otras = [p for p in self.pend if p not in m] or sorted(self.pend)
                primera = rng.choice(sin_ver or otras)
                g = self.cartas[primera]
                companera = [p for p in m if p in self.pend and p != primera and self.cartas[p] == g]
                self._ver(primera)
                if companera:
                    ok = True
                else:
                    libres = [p for p in self.pend if p != primera and p not in self.vistas]
                    libres = libres or [p for p in self.pend if p != primera and p not in m] or [p for p in self.pend if p != primera]
                    segunda = rng.choice(libres)
                    self._ver(segunda)
                    ok = self.cartas[segunda] == g
            if ok:
                self._formar(g)
                aciertos += 1
                seg += t_jugada
                if aciertos >= self.tope.get(h, 99):
                    return aciertos, seg + 1.0, False, 0.0  # "turno perfecto!": termina en celebracion
            else:
                fallos += 1
                seg += t_jugada + t_fallo
                if fallos >= permitidos:
                    return aciertos, seg, True, 1.5
        return aciertos, seg, False, 0.0


class Rio:
    ACIERTA = {"nicole": 0.65, "sofia": 0.85}
    SEG_DISPARO = {"nicole": 4.0, "sofia": 2.5}

    def __init__(self, rng, gotas, colores):
        self.rng = rng
        self.tramos = []
        anterior = None
        for _ in range(gotas):
            if anterior is not None and self.tramos[-1][1] < 2 and rng.random() < 0.35:
                c = anterior
            else:
                c = rng.choice([x for x in range(colores) if x != anterior])
            if self.tramos and self.tramos[-1][0] == c:
                self.tramos[-1][1] += 1
            else:
                self.tramos.append([c, 1])
            anterior = c

    def terminado(self):
        return not self.tramos

    def _reventar(self, i):
        del self.tramos[i]
        aciertos = 1
        while 0 < i < len(self.tramos) and self.tramos[i - 1][0] == self.tramos[i][0]:
            self.tramos[i - 1][1] += self.tramos[i][1]
            del self.tramos[i]
            if self.tramos[i - 1][1] >= 3:
                del self.tramos[i - 1]
                i -= 1
                aciertos += 2  # la cadena vale 2 aciertos de racha
            else:
                break
        return aciertos

    def turno(self, h):
        rng = self.rng
        if h == "maxi":
            i = max(range(len(self.tramos)), key=lambda k: self.tramos[k][1])
            return self._reventar(i), 5.0, False, 0.0  # N2: su bala revienta con umbral 2
        aciertos, seg = 0, 1.0
        for _ in range(3):
            if not self.tramos:
                break
            seg += self.SEG_DISPARO[h]
            presentes = sorted({c for c, _ in self.tramos})
            mano = {rng.choice(presentes), rng.choice(presentes)}  # boca + reserva (intercambio permitido)
            candidatos = [k for k in range(len(self.tramos)) if self.tramos[k][0] in mano]
            objetivo = max(candidatos, key=lambda k: self.tramos[k][1])
            if rng.random() < self.ACIERTA[h]:
                self.tramos[objetivo][1] += 1
                if self.tramos[objetivo][1] >= 3:
                    aciertos += self._reventar(objetivo)
                    seg += 0.5
            else:
                c = self.tramos[objetivo][0]
                j = rng.randrange(len(self.tramos) + 1)
                vecino = next((k for k in (j - 1, j) if 0 <= k < len(self.tramos) and self.tramos[k][0] == c), None)
                if vecino is None:
                    self.tramos.insert(j, [c, 1])
                else:
                    self.tramos[vecino][1] += 1
                    if self.tramos[vecino][1] >= 3:
                        aciertos += self._reventar(vecino)
        return aciertos, seg, False, 0.0


class Formas:
    TOPE = {"maxi": 1, "nicole": 2, "sofia": 3}
    ACIERTA = {"nicole": 0.85, "sofia": 0.82}
    SEG = {"nicole": 5.5, "sofia": 6.5}

    def __init__(self, rng, piezas):
        self.rng, self.quedan = rng, piezas

    def terminado(self):
        return self.quedan <= 0

    def turno(self, h):
        if h == "maxi":
            self.quedan -= 1
            return 1, 4.5, False, 0.0
        permitidos = 2 if h == "nicole" else 1
        aciertos, fallos, seg = 0, 0, 1.0
        while self.quedan > 0 and aciertos < self.TOPE[h]:
            seg += self.SEG[h]
            if self.rng.random() < self.ACIERTA[h]:
                aciertos += 1
                self.quedan -= 1
            else:
                fallos += 1
                if fallos >= permitidos:
                    return aciertos, seg, True, 0.0
        return aciertos, seg + (1.0 if aciertos == self.TOPE[h] else 0.0), False, 0.0


# ---------------------------------------------------------------------------------------------

def jugar_ronda(rng, equipo, juego, retrocede=3, perfecto=None, resbalon_racha=False):
    """Juega hasta terminar SIN reiniciar al rival; devuelve la posicion maxima que alcanzo (se pierde al
    primer intento si max_pos >= pasos_rival), los segundos y los turnos de cada hermano.
    perfecto = {"nicole": 2, "sofia": 3}: PROPUESTA de retroceso por "turno perfecto" (llegar al tope
    sin fallo) en vez de "cada 3 aciertos"; con None se usa la regla vigente (racha de 3).
    resbalon_racha (v3, modo-equipo.md v6.1 §5.2): si en el turno hubo al menos un retroceso por la racha
    de 3, en el pase el rival se resbala y no avanza (una sola vez por pase). Como con el turno perfecto,
    cuenta aunque el rival este en la galleta 0 (ahi solo trastabilla)."""
    orden = ciclo(equipo)
    pos = max_pos = 0
    turnos = {h: 0 for h in equipo}
    seg, i = 4.0, 0  # intro de la ronda (<= 4 s)
    while not juego.terminado():
        h = orden[i % len(orden)]
        i += 1
        turnos[h] += 1
        aciertos, s, _con_fallo, revela = juego.turno(h)
        seg += s
        fue_perfecto = perfecto is not None and h != "maxi" and aciertos >= perfecto.get(h, 99)
        retrocesos_racha = 0
        if perfecto is not None:
            pos = max(0, pos - (1 if fue_perfecto else 0))
        elif retrocede and h != "maxi":
            # v3: Maxi nunca mueve al rival (maxi_mueve_rival: false). La v2 contaba su cadena del Rio
            # (1 + 2 = 3 aciertos) como racha: era un error del modelo.
            retrocesos_racha = aciertos // retrocede
            pos = max(0, pos - retrocesos_racha)
        if juego.terminado():
            break
        seg += revela + (RITUAL_MAXI_S if h == "maxi" else 0.0) + rng.uniform(*PASE_S) + 0.8
        resbala = (fue_perfecto and RESBALON) or (resbalon_racha and retrocesos_racha > 0)
        if PERFIL[h] != "semilla" and not resbala:
            pos += 1  # tras un turno perfecto el rival intenta saltar y se resbala (PO 07-Oct-2026, UX N10)
            max_pos = max(max_pos, pos)
    return max_pos, seg, turnos


PERFECTO = "--racha3" not in sys.argv  # retroceso por "turno perfecto" donde hay tope (PO 07-Oct-2026); --racha3 = regla anterior
RESBALON = "--sin-resbalon" not in sys.argv  # tras turno perfecto no avanza en ese pase (PO 07-Oct-2026)
SIN_TOPE = "--sin-tope" in sys.argv      # ignora el tope de pares propuesto (regla vigente)


def escenario(nombre, equipo, fabrica, pasos_config, semilla, objetivo=0.80, tope=None, resbalon_racha=False):
    rng = random.Random(semilla)
    maximos, segundos, todos_dos, turnos_h = [], [], 0, {h: [] for h in equipo}
    perfecto = tope if (PERFECTO and tope) else None
    for _ in range(PARTIDAS):
        juego = fabrica(rng)
        max_pos, seg, turnos = jugar_ronda(rng, equipo, juego, perfecto=perfecto, resbalon_racha=resbalon_racha)
        maximos.append(max_pos)
        segundos.append(seg)
        todos_dos += all(t >= 2 for t in turnos.values())
        for h, t in turnos.items():
            turnos_h[h].append(t)
    gana = {p: sum(m < p for m in maximos) / PARTIDAS for p in range(3, 13)}
    orden = sorted(segundos)
    p50, p80 = statistics.median(segundos), orden[int(0.8 * (len(orden) - 1))]
    recomendado = next((p for p in gana if gana[p] >= objetivo), None)
    print(f"\n{nombre}  [{'+'.join(sorted(equipo))}]  pasos_rival configurado: {pasos_config}"
          + (f"  tope {tope}" if tope else "") + ("  retroceso=turno perfecto" if perfecto else "")
          + ("  resbalon_tras_racha" if resbalon_racha else ""))
    print("  gana al primer intento: " + "  ".join(f"{p}:{gana[p]:.0%}" + ("*" if p == pasos_config else "") for p in gana))
    print(f"  -> menor pasos_rival con >= {objetivo:.0%}: {recomendado}")
    print(f"  duracion sin derrota: p50 {p50 / 60:.1f} min, p80 {p80 / 60:.1f} min")
    print("  turnos (mediana): " + ", ".join(f"{h} {statistics.median(v):.0f}" for h, v in turnos_h.items())
          + f" | cada hermano >= 2 turnos: {todos_dos / PARTIDAS:.0%}")
    return gana


def leer_tope(bloque):
    """Tope de pares por turno PROPUESTO (pares_max_turno_propuesta: {"semilla": 1, "brote": 2, "estrella": 3})
    convertido a {hermano: tope}. Maxi ya forma 1 por regla, asi que solo importan Nicole y Sofia."""
    t = bloque.get("pares_max_turno", bloque.get("pares_max_turno_propuesta"))
    if SIN_TOPE or not t:
        return None
    return {h: int(t[p]) for h, p in PERFIL.items() if p in t and h != "maxi"}


def batalla():
    tres = ["maxi", "nicole", "sofia"]
    tope_formas = {"nicole": 2, "sofia": 3}
    rio = json.loads((NIVELES / "batalla" / "rio_equipo.json").read_text(encoding="utf-8"))
    gotas, colores = int(rio["gotas"]), len(rio["colores"])
    pasos_rio = int(rio["equipo"]["composiciones"]["maxi+nicole+sofia"]["pasos_rival"])
    en_datos = bool(rio["equipo"].get("resbalon_tras_racha", False))
    # v3 (modo-equipo.md v6.1 §5.2): el Rio se corre SIN y CON resbalon tras racha, con la misma semilla, para
    # comparar antes/despues. Decision: true si con resbalon da >= 85 %; si pasa del 95 %, se propone al PO
    # subir pasos_rival o sumar gotas.
    rio_sin = escenario(f"BATALLA ronda 1 - Rio ({gotas} gotas, {colores} colores) SIN resbalon tras racha", tres,
                        lambda r: Rio(r, gotas, colores), pasos_rio, "rio20", objetivo=0.85)
    rio_con = escenario(f"BATALLA ronda 1 - Rio ({gotas} gotas, {colores} colores) CON resbalon tras racha", tres,
                        lambda r: Rio(r, gotas, colores), pasos_rio, "rio20", objetivo=0.85, resbalon_racha=True)
    escenario("  (referencia) Rio con 18 gotas, con resbalon", tres, lambda r: Rio(r, 18, 4), pasos_rio, "rio18",
              objetivo=0.85, resbalon_racha=True)
    formas = escenario("BATALLA ronda 2 - Formas (12 piezas, tope 1/2/3)", tres, lambda r: Formas(r, 12), 5, "formas12",
                       objetivo=0.85, tope=tope_formas)
    nivel = json.loads((NIVELES / "batalla" / "parejas_equipo.json").read_text(encoding="utf-8"))
    comp = nivel["equipo"]["composiciones"]["maxi+nicole+sofia"]
    tope = leer_tope(comp)
    pares = int(comp["cantidad"])
    pasos_parejas = int(comp["pasos_rival"])
    parejas = escenario(f"BATALLA ronda 3 - Parejas ({pares} pares, vistazo 3, lupa)", tres,
                        lambda r: Parejas(r, pares, tres, 3, True, tope), pasos_parejas, "parejas-batalla",
                        objetivo=0.80, tope=tope)
    print("\nRESUMEN Rio (pasos_rival %d, en datos resbalon_tras_racha=%s):" % (pasos_rio, en_datos))
    print(f"  sin resbalon {rio_sin[pasos_rio]:.1%} -> con resbalon {rio_con[pasos_rio]:.1%}")
    if rio_con[pasos_rio] < 0.85:
        print("  -> recomendacion: dejar resbalon_tras_racha en false (no llega al 85 %)")
    elif rio_con[pasos_rio] <= 0.95:
        print("  -> recomendacion: resbalon_tras_racha = true (entre 85 % y 95 %)")
    else:
        alt = next((p for p in sorted(rio_con) if rio_con[p] <= 0.95 and rio_con[p] >= 0.85), None)
        print(f"  -> recomendacion: true, pero pasa del 95 %: proponer al PO pasos_rival {alt} o mas gotas")
    for nombre_rio, g in (("sin", rio_sin), ("con", rio_con)):
        total = g[pasos_rio] * formas[5] * parejas[pasos_parejas]
        print(f"  batalla sin ningun estornudo ({nombre_rio} resbalon en el Rio): {total:.1%}")
    escenario("  (referencia) Parejas 10 pares con tope {N 2, S 3}", tres,
              lambda r: Parejas(r, 10, tres, 3, True, {"nicole": 2, "sofia": 3}), 5, "parejas10t", tope={"nicole": 2, "sofia": 3})
    escenario("  (referencia) Parejas 10 pares con tope {N 2, S 2}", tres,
              lambda r: Parejas(r, 10, tres, 3, True, {"nicole": 2, "sofia": 2}), 5, "parejas10t22", tope={"nicole": 2, "sofia": 2})


def zonas():
    for zona in ZONAS:
        ruta = NIVELES / zona / "parejas_equipo.json"
        if not ruta.exists():
            continue
        nivel = json.loads(ruta.read_text(encoding="utf-8"))
        eq = nivel["equipo"]
        lupa = any(e.get("tipo") == "lupa" for e in nivel.get("especiales", []))
        vistazo = int(eq.get("vistazo", {}).get("pares", 0))
        for clave, comp in eq["composiciones"].items():
            equipo = clave.split("+")
            pares = int(comp["cantidad"])
            tope = leer_tope(comp)
            objetivo = 0.75 if clave == "nicole+sofia" else 0.80
            escenario(f"{zona} parejas_equipo ({pares} pares)", equipo,
                      lambda r, p=pares, e=equipo, t=tope: Parejas(r, p, e, vistazo, lupa, t),
                      int(comp["pasos_rival"]), f"{zona}-{clave}", objetivo=objetivo, tope=tope)


if __name__ == "__main__":
    batalla()
    if "--batalla" not in sys.argv:
        zonas()
