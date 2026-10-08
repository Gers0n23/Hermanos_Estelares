"""HE-60 "Parejas con reto real": agrega a los niveles de Parejas de Coco los campos del reto en solitario
(docs/fichas/motor-emparejar.md §10.1, §10.1.1 y §10.2): `puntaje`, `umbrales_puntaje` (Nicole), `vistazo`
y las voces de racha, récord, vela, vistazo y estrellitas (docs/guiones/voces-modo-equipo-parejas.md §6).

Es un POST-PROCESO idempotente: se corre despues de `generar_parejas.py` y `generar_niveles_sofia.py`
(que reescriben los JSON desde cero) y solo agrega/pisa estos campos.

Los valores de `tiempo_par_s` y `umbrales_puntaje` salen de un simulador simple (abajo) con el metodo de
la ficha (§5 y §10.1.1): jugadora que recuerda las ultimas N cartas vistas (Nicole 3, Sofia 5), con el
vistazo de M6 y la ayuda de su nivel, 3.000 partidas por nivel. Son PROVISIONALES: `disenador-niveles`
los reemplaza con su simulador y el playtest.

Uso: python herramientas/agregar_reto_parejas.py [--solo-simular]
"""
import json
import random
import statistics
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
NIVELES = RAIZ / "datos" / "niveles" / "arcoiris"
ZONAS = ["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
R = "voces/arcoiris/emparejar/reto/"
PARTIDAS = 3000
NOTA = "HE-60 PROVISIONAL: tiempo_par_s y umbrales_puntaje del simulador de herramientas/agregar_reto_parejas.py; los afina disenador-niveles"

# Segundos por jugada (dos toques, o tres en trios) de cada perfil: acierto y "no es este" (incluye
# el tiempo que el par fallido queda a la vista). Estimaciones para el simulador, no medidas.
TIEMPOS = {
    "brote": {"acierto": 3.0, "fallo_extra": 1.0, "visible_acierto": 2.4, "visible_fallo": 3.1},
    "estrella": {"acierto": 2.0, "fallo_extra": 0.9, "traviesas": 0.8},
}


def voces(perfil, con_vela):
    v = {
        "racha": {str(n): R + f"racha_{n}.wav" for n in range(2, 6)} | {"sigue": R + "racha_sigue.wav"},
        "a_la_primera": [R + "a_la_primera_01.wav", R + "a_la_primera_02.wav"],
        "record_pasa": R + "record_pasa.wav",
        "record_nuevo": [R + "record_nuevo_01.wav", R + "record_nuevo_02.wav"],
        "primer_record": R + "primer_record.wav",
        "vistazo": R + "vistazo_mira.wav",
        "vistazo_presenta": R + "vistazo_presenta.wav",
    }
    if con_vela:
        v |= {"vela_presenta": R + "vela_presenta.wav", "vela_encendida": R + "vela_encendida.wav",
              "vela_dormida": R + "vela_dormida.wav"}
    if perfil == "brote":
        v["estrellitas_brote"] = {str(n): R + f"estrellitas_brote_{n}.wav" for n in (1, 2, 3)}
        v["otra_estrellita"] = R + "otra_estrellita.wav"
    return v


# ---------------------------------------------------------------------------------------------
# Simulador
# ---------------------------------------------------------------------------------------------

def cartas_vistazo(perfil, n_cartas, tam):
    """Cartas que muestra el vistazo (M6): Nicole 1 par con <= 10 cartas y 2 pares con 12-16; Sofia
    round(cartas / 4) sueltas."""
    if perfil == "brote":
        return ("pares", 1 if n_cartas <= 10 else 2)
    return ("sueltas", round(n_cartas / 4))


def jugar_tablero(rng, grupos, tam, oculto, memoria, perfil, ayuda, intercambios, estado):
    """Juega un tablero. `estado` lleva la racha entre rondas y acumula puntos y segundos."""
    t = TIEMPOS[perfil]
    cartas = [g for g in range(grupos) for _ in range(tam)]
    rng.shuffle(cartas)
    pendientes = set(range(len(cartas)))
    vistas = set()
    recuerdo = []  # posiciones recordadas, la mas nueva al final

    def recordar(pos):
        if pos in recuerdo:
            recuerdo.remove(pos)
        recuerdo.append(pos)
        while len(recuerdo) > memoria:
            recuerdo.pop(0)

    if oculto:
        tipo, cantidad = cartas_vistazo(perfil, len(cartas), tam)
        if tipo == "pares":
            for g in rng.sample(range(grupos), min(cantidad, grupos)):
                for pos in [p for p in range(len(cartas)) if cartas[p] == g]:
                    vistas.add(pos)
                    recordar(pos)
        else:
            elegidas, usados = [], set()
            for pos in rng.sample(range(len(cartas)), len(cartas)):
                if cartas[pos] not in usados and len(elegidas) < cantidad:
                    usados.add(cartas[pos])
                    elegidas.append(pos)
            for pos in elegidas:
                vistas.add(pos)
                recordar(pos)

    fallos_seguidos = 0
    while pendientes:
        if not oculto:
            # A la vista: reconocimiento, casi siempre acierta.
            ok = rng.random() < 0.92
            if ok:
                g = cartas[next(iter(pendientes))]
                pendientes -= {p for p in pendientes if cartas[p] == g}
                _sumar_acierto(estado, False)
                estado["segundos"] += t["visible_acierto"]
            else:
                _cortar(estado)
                estado["segundos"] += t["visible_fallo"]
            continue
        conocidos = {}
        for pos in recuerdo:
            if pos in pendientes:
                conocidos.setdefault(cartas[pos], []).append(pos)
        completo = next((g for g, ps in conocidos.items() if len(ps) >= tam), None)
        if completo is not None:
            elegidas = conocidos[completo][:tam]
        else:
            sin_ver = [p for p in pendientes if p not in vistas]
            primera = rng.choice(sin_ver) if sin_ver else rng.choice([p for p in pendientes if p not in recuerdo] or list(pendientes))
            elegidas = [primera]
            while len(elegidas) < tam:
                g = cartas[elegidas[0]]
                companera = [p for p in conocidos.get(g, []) if p not in elegidas]
                if companera:
                    elegidas.append(companera[0])
                    continue
                libres = [p for p in pendientes if p not in elegidas and p not in vistas]
                if not libres:
                    libres = [p for p in pendientes if p not in elegidas and p not in recuerdo] or [p for p in pendientes if p not in elegidas]
                siguiente = rng.choice(libres)
                elegidas.append(siguiente)
                if cartas[siguiente] != g:
                    break
        a_la_primera = all(p not in vistas for p in elegidas)
        for pos in elegidas:
            vistas.add(pos)
            recordar(pos)
        ok = len(elegidas) == tam and len({cartas[p] for p in elegidas}) == 1
        extra_trio = 0.6 * (len(elegidas) - 2)
        if ok:
            pendientes -= set(elegidas)
            for pos in elegidas:
                if pos in recuerdo:
                    recuerdo.remove(pos)
            _sumar_acierto(estado, a_la_primera)
            estado["segundos"] += t["acierto"] + extra_trio
            fallos_seguidos = 0
            if intercambios and pendientes:
                estado["segundos"] += t.get("traviesas", 0.0)
                tapadas = list(pendientes)
                for _ in range(intercambios):
                    if len(tapadas) < 2:
                        break
                    a, b = rng.sample(tapadas, 2)
                    cartas[a], cartas[b] = cartas[b], cartas[a]
                    for pos in (a, b):
                        if pos in recuerdo and rng.random() < 0.5:
                            recuerdo.remove(pos)
        else:
            _cortar(estado)
            estado["fallos"] += 1
            estado["segundos"] += t["acierto"] + t["fallo_extra"] + extra_trio
            fallos_seguidos += 1
            if ayuda and fallos_seguidos >= ayuda:
                fallos_seguidos = 0
                g = cartas[rng.choice(list(pendientes))]
                for pos in [p for p in pendientes if cartas[p] == g]:
                    vistas.add(pos)
                    recordar(pos)


def _sumar_acierto(estado, a_la_primera):
    estado["racha"] = min(estado["racha"] + 1, 5)
    estado["puntos"] += 100 * estado["racha"]
    if a_la_primera:
        estado["puntos"] += 200


def _cortar(estado):
    estado["racha"] = 0


def simular(nivel, rng):
    perfil = nivel["perfil"]
    memoria = 3 if perfil == "brote" else 5
    tableros = []
    if nivel.get("rondas"):
        for r in nivel["rondas"]:
            tableros.append({"grupos": int(r["cantidad"]), "tam": 2, "oculto": bool(r.get("oculto", nivel.get("oculto"))),
                             "ayuda": r.get("ayuda_tras_fallos", nivel.get("ayuda_tras_fallos")) or 0, "intercambios": 0})
    else:
        tam = int(nivel.get("tamano_grupo", 2))
        grupos = len(nivel.get("grupos", nivel.get("pares", [])))
        tableros.append({"grupos": grupos, "tam": tam, "oculto": bool(nivel.get("oculto")), "ayuda": 0,
                         "intercambios": int(nivel.get("intercambios_tras_acierto", 0))})
    puntos, segundos = [], []
    for _ in range(PARTIDAS):
        estado = {"racha": 0, "puntos": 0, "segundos": 0.0, "fallos": 0}
        for tb in tableros:
            jugar_tablero(rng, tb["grupos"], tb["tam"], tb["oculto"], memoria, perfil, tb["ayuda"], tb["intercambios"], estado)
        puntos.append(estado["puntos"])
        segundos.append(estado["segundos"])
    total_pares = sum(tb["grupos"] for tb in tableros)
    return puntos, segundos, total_pares


def percentil(valores, p):
    orden = sorted(valores)
    return orden[min(len(orden) - 1, int(round(p * (len(orden) - 1))))]


def redondear(valor, paso):
    return int(round(valor / paso) * paso)


# ---------------------------------------------------------------------------------------------

def procesar(ruta, zona_num, solo_simular):
    nivel = json.loads(ruta.read_text(encoding="utf-8"))
    perfil = nivel["perfil"]
    if perfil == "semilla":
        # Maxi: la racha solo con sonido y la cresta (ficha §10.1). Sin puntaje, record ni vistazo.
        nivel["puntaje"] = {"racha_tope": 5, "mostrar": "solo_sonido"}
        print(f"{ruta.relative_to(NIVELES)}: semilla, racha solo sonido")
    else:
        rng = random.Random(f"he60-{ruta.name}-{zona_num}")
        puntos, segundos, total_pares = simular(nivel, rng)
        mediana_t = statistics.median(segundos)
        if perfil == "brote":
            # Holgada: 1,5 veces lo que tarda una nina de 5 anos que juega bien. La vela entra desde la
            # zona 2 (M7.4) y solo cuando ya hay record (M7.1, lo resuelve el motor).
            tiempo_par = None if zona_num == 1 else redondear(1.5 * mediana_t + 2.5, 5)
            dos, tres = redondear(percentil(puntos, 0.5), 50), redondear(percentil(puntos, 0.8), 50)
            if tres <= dos:
                tres = dos + 50
            nivel["umbrales_puntaje"] = {"dos": dos, "tres": tres}
            nivel["vistazo"] = {"cartas": "auto", "ms": 3000, "pares_completos": True}
        else:
            # Ajustada: 1,1 veces la mediana del jugador simulado; desde la primera partida.
            tiempo_par = redondear(1.1 * mediana_t + 2.5, 5)
            nivel["vistazo"] = {"cartas": "auto", "ms": 2000, "pares_completos": False}
        nivel["puntaje"] = {
            "por_par": 100, "racha_tope": 5, "bono_a_la_primera": 200, "tiempo_par_s": tiempo_par,
            "vela_desde_primera": perfil == "estrella", "bono_por_segundo": 10, "mostrar": "barra",
        }
        nivel["calibracion_reto"] = NOTA
        nivel.setdefault("lineas_voz", {}).update(voces(perfil, tiempo_par is not None))
        print(f"{ruta.relative_to(NIVELES)}: {perfil}, {total_pares} pares | puntos p50 {percentil(puntos, 0.5)} "
              f"p80 {percentil(puntos, 0.8)} | segundos p50 {mediana_t:.0f} -> tiempo_par_s {tiempo_par}"
              + (f" | umbrales {nivel['umbrales_puntaje']} (por defecto {150 * total_pares}/{230 * total_pares})" if perfil == "brote" else ""))
    if not solo_simular:
        ruta.write_text(json.dumps(nivel, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    solo_simular = "--solo-simular" in sys.argv
    for i, zona in enumerate(ZONAS, start=1):
        for archivo in sorted((NIVELES / zona).glob("parejas_*.json")):
            procesar(archivo, i, solo_simular)


if __name__ == "__main__":
    main()
