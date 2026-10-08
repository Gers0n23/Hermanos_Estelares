"""HE-60, QA M3 (07-Oct-2026): recalibra `limite_intentos` y `umbrales_estrellitas` de Sofia (Estrella) en
Parejas de Coco despues de agregar el vistazo al repartir (docs/fichas/motor-emparejar.md §10.2).

Autor: disenador-niveles, 07-Oct-2026. Razonamiento y resultados:
docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md §11.

Metodo (el mismo jugador simulado de motor-emparejar.md §5, que fijo los limites de HE-40):
- jugadora de 8 anos que juega bien, memoria visual de ~5 cartas (olvida la mas antigua);
- sombras con 8 % de confusion al elegir una compañera "recordada"; traviesas con 50 % de olvido de cada
  carta movida; trios: el intento termina en la primera carta que no coincide (1 fallo);
- 3.000 partidas por nivel, DOS veces con la misma semilla: sin vistazo y con el vistazo del nivel
  (Estrella: round(cartas / 4) sueltas, nunca dos del mismo grupo; parten "vistas" y en la memoria).

Regla de recalibracion ("metodo del corrimiento"): el vistazo no cambia el criterio de HE-40 (3 estrellitas
en ~1 de cada 4 partidas bien jugadas = p25 de fallos; limite ~ p80, derrota-gag en ~1 de cada 5; dos =
limite), solo regala informacion. Entonces a cada valor vigente se le resta lo que el vistazo corre su
percentil:
    limite_nuevo = limite_vigente + (p80_con - p80_sin)
    tres_nuevo   = tres_vigente   + (p25_con - p25_sin)
    dos_nuevo    = limite_nuevo
Asi se conserva la calibracion de HE-40 aunque este modelo no reproduzca al fallo exacto el de entonces.
Ademas imprime el % de 3 estrellitas y de derrota-gag con los valores vigentes (el problema de M3) y con
los nuevos.

Uso: python herramientas/calibrar_parejas_sofia.py             (solo imprime)
     python herramientas/calibrar_parejas_sofia.py --escribir  (escribe limite_intentos, umbrales_estrellitas
                                                                 y calibracion_estrellitas en los JSON Estrella)
Ojo: la recalibracion ya se aplico (07-Oct-2026) y generar_niveles_sofia.py tiene los valores nuevos.
NO vuelvas a correr --escribir tras regenerar: aplicaria el corrimiento dos veces. Usalo solo si cambia
el vistazo u otra regla, partiendo de JSON con los valores de HE-40.
"""
import json
import random
import statistics
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
NIVELES = RAIZ / "datos" / "niveles" / "arcoiris"
PARTIDAS = 3000
MEMORIA = 5
CONFUSION = {"sombras": 0.08}
NOTA = ("HE-60 M3 (disenador-niveles 07-Oct-2026): limite_intentos y umbrales_estrellitas recalibrados con el "
        "vistazo por herramientas/calibrar_parejas_sofia.py (corrimiento de p25/p80 de fallos sobre los valores "
        "de HE-40). Provisional hasta el playtest; ver calibracion-batalla-arcoiris-y-parejas-equipo.md §11")


def jugar(rng, grupos, tam, intercambios, confusion, con_vistazo):
    """Devuelve los fallos de una partida completa (sin cortar en el limite)."""
    cartas = [g for g in range(grupos) for _ in range(tam)]
    rng.shuffle(cartas)
    pend = set(range(len(cartas)))
    vistas = set()
    rec = []

    def recordar(p):
        if p in rec:
            rec.remove(p)
        rec.append(p)
        while len(rec) > MEMORIA:
            rec.pop(0)

    if con_vistazo:
        cantidad = round(len(cartas) / 4)
        usados, elegidas = set(), []
        for p in rng.sample(range(len(cartas)), len(cartas)):
            if cartas[p] not in usados and len(elegidas) < cantidad:
                usados.add(cartas[p])
                elegidas.append(p)
        for p in elegidas:
            vistas.add(p)
            recordar(p)

    fallos = 0
    while pend:
        conocidos = {}
        for p in rec:
            if p in pend:
                conocidos.setdefault(cartas[p], []).append(p)
        completo = next((g for g, ps in conocidos.items() if len(ps) >= tam), None)
        de_memoria = False
        if completo is not None:
            elegidas = conocidos[completo][:tam]
            de_memoria = True
        else:
            sin_ver = [p for p in pend if p not in vistas]
            primera = rng.choice(sin_ver) if sin_ver else rng.choice([p for p in pend if p not in rec] or list(pend))
            elegidas = [primera]
            while len(elegidas) < tam:
                g = cartas[elegidas[0]]
                companera = [p for p in conocidos.get(g, []) if p not in elegidas]
                if companera:
                    elegidas.append(companera[0])
                    de_memoria = True
                    continue
                libres = [p for p in pend if p not in elegidas and p not in vistas]
                if not libres:
                    libres = [p for p in pend if p not in elegidas and p not in rec] or [p for p in pend if p not in elegidas]
                siguiente = rng.choice(libres)
                elegidas.append(siguiente)
                if cartas[siguiente] != g:
                    break
        if de_memoria and confusion and rng.random() < confusion:
            # Sombras: confunde la compañera recordada con otra carta pendiente de otro grupo.
            g = cartas[elegidas[0]]
            otras = [p for p in pend if p not in elegidas and cartas[p] != g]
            if otras:
                elegidas[-1] = rng.choice(otras)
        for p in elegidas:
            vistas.add(p)
            recordar(p)
        ok = len(elegidas) == tam and len({cartas[p] for p in elegidas}) == 1
        if ok:
            pend -= set(elegidas)
            for p in elegidas:
                if p in rec:
                    rec.remove(p)
            if intercambios and pend:
                tapadas = list(pend)
                for _ in range(intercambios):
                    if len(tapadas) < 2:
                        break
                    a, b = rng.sample(tapadas, 2)
                    cartas[a], cartas[b] = cartas[b], cartas[a]
                    for p in (a, b):
                        if p in rec and rng.random() < 0.5:
                            rec.remove(p)
        else:
            fallos += 1
    return fallos


def percentil(valores, p):
    orden = sorted(valores)
    return orden[min(len(orden) - 1, int(round(p * (len(orden) - 1))))]


def tasa(valores, cond):
    return sum(1 for v in valores if cond(v)) / len(valores)


def procesar(ruta, escribir):
    nivel = json.loads(ruta.read_text(encoding="utf-8"))
    tam = int(nivel.get("tamano_grupo", 2))
    grupos = len(nivel.get("grupos") or nivel.get("pares") or [])
    intercambios = int(nivel.get("intercambios_tras_acierto", 0))
    confusion = CONFUSION.get(nivel.get("modo", ""), 0.0)
    limite = int(nivel["limite_intentos"])
    tres = int(nivel["umbrales_estrellitas"]["tres"])
    sin = [jugar(random.Random(f"m3-{ruta.name}-{i}"), grupos, tam, intercambios, confusion, False) for i in range(PARTIDAS)]
    con = [jugar(random.Random(f"m3-{ruta.name}-{i}"), grupos, tam, intercambios, confusion, True) for i in range(PARTIDAS)]
    p = {k: (percentil(sin, q), percentil(con, q)) for k, q in (("p25", 0.25), ("p50", 0.5), ("p80", 0.8))}
    limite_n = limite + (p["p80"][1] - p["p80"][0])
    tres_n = max(1, min(tres + (p["p25"][1] - p["p25"][0]), limite_n - 1))
    rel = ruta.relative_to(NIVELES).as_posix()
    print(f"\n{rel}: {grupos} {'trios' if tam == 3 else 'pares'}, modo {nivel.get('modo')}, "
          f"vistazo {round(grupos * tam / 4)} cartas")
    print("  fallos sin vistazo  p25 %d  p50 %d  p80 %d  (media %.1f)" % (p["p25"][0], p["p50"][0], p["p80"][0], statistics.mean(sin)))
    print("  fallos con vistazo  p25 %d  p50 %d  p80 %d  (media %.1f)" % (p["p25"][1], p["p50"][1], p["p80"][1], statistics.mean(con)))
    print(f"  vigente   limite {limite:2d}  tres {tres:2d}  dos {limite:2d} | sin vistazo: 3* {tasa(sin, lambda f: f <= tres):.0%}, "
          f"derrota {tasa(sin, lambda f: f > limite):.0%} | con vistazo: 3* {tasa(con, lambda f: f <= tres):.0%}, "
          f"derrota {tasa(con, lambda f: f > limite):.0%}")
    print(f"  NUEVO     limite {limite_n:2d}  tres {tres_n:2d}  dos {limite_n:2d} | con vistazo: 3* {tasa(con, lambda f: f <= tres_n):.0%}, "
          f"derrota {tasa(con, lambda f: f > limite_n):.0%}")
    if escribir:
        nivel["limite_intentos"] = limite_n
        nivel["umbrales_estrellitas"] = {"tres": tres_n, "dos": limite_n}
        nivel["calibracion_estrellitas"] = NOTA
        ruta.write_text(json.dumps(nivel, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("  escrito")


def main():
    escribir = "--escribir" in sys.argv
    for ruta in sorted(NIVELES.glob("zona*/parejas_estrella*.json")):
        nivel = json.loads(ruta.read_text(encoding="utf-8"))
        if nivel.get("regla") == "camino" or not nivel.get("vistazo") or nivel.get("limite_intentos") is None:
            print(f"\n{ruta.relative_to(NIVELES).as_posix()}: sin vistazo o sin limite, no se toca")
            continue
        procesar(ruta, escribir)


if __name__ == "__main__":
    main()
