"""Genera varias líneas de voz en UN solo pedido a fal.ai y después corta el audio por línea.

Por qué existe (21-Nov-2026): fal cobra Qwen3-TTS por PEDIDO, con un mínimo de 1 bloque de 1.000 caracteres
(USD 0,09), aunque la línea sea corta. Una línea por pedido = USD 0,09 por línea. Juntando ~6 líneas
(~500 caracteres) en un pedido, el costo baja unas 6 veces.

Cómo corta: sabe cuántas líneas hay en el bloque, así que busca un silencio por cada cambio de línea, cerca
de donde debería caer según el largo de cada texto (Cometa habla ~13,8 caracteres/s). Después valida que
cada pedazo dure lo razonable para su texto. Si un bloque no pasa la validación, NO guarda los pedazos
(guarda solo el audio completo, para escucharlo) y lo informa.

Sin reintentos automáticos: cada pedido cuesta USD 0,09 y se revisa de oído.

Uso:
  python herramientas/generar_voces_fal_agrupado.py --lista <tsv> --estimar
  python herramientas/generar_voces_fal_agrupado.py --lista <tsv> --max-pedidos 1 --carpeta-prueba voces/prueba_agrupado
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import RAIZ, obtener_key  # noqa: E402
from generar_voces_fal import (PICO, PRECIO_USD_POR_1000, cargar_voz, escribir_pendientes,  # noqa: E402
                               guardar, leer_lista, leer_pendientes, limpiar, realzar_agudos, sintetizar)

LIMITE_CARACTERES = 500
CARACTERES_POR_SEGUNDO = 13.8
VENTANA_S = 0.02          # análisis de energía en ventanas de 20 ms
SILENCIO_DB = -38.0       # bajo esto (respecto del pico) es silencio
SILENCIO_MIN_S = 0.12     # pausa mínima que se considera corte posible
MARGEN_S = 0.08
TOLERANCIA = (0.45, 2.2)  # duración real / esperada aceptable por pedazo


def agrupar(lineas: list[tuple[str, str, str]], limite: int) -> list[list[tuple[str, str, str]]]:
    """Bloques consecutivos del mismo personaje de hasta `limite` caracteres (respeta el orden del guion)."""
    bloques: list[list[tuple[str, str, str]]] = []
    actual: list[tuple[str, str, str]] = []
    largo = 0
    for linea in lineas:
        cambia = actual and (largo + len(linea[1]) + 2 > limite or actual[-1][2] != linea[2])
        if cambia:
            bloques.append(actual)
            actual, largo = [], 0
        actual.append(linea)
        largo += len(linea[1]) + 2
    if actual:
        bloques.append(actual)
    return bloques


def silencios(datos: np.ndarray, sr: int) -> list[tuple[float, float]]:
    """Tramos de silencio (inicio, fin) en segundos."""
    n = int(VENTANA_S * sr)
    cuadros = len(datos) // n
    rms = np.sqrt((datos[: cuadros * n].reshape(cuadros, n) ** 2).mean(axis=1) + 1e-12)
    db = 20 * np.log10(rms / (rms.max() + 1e-12))
    callado = db < SILENCIO_DB
    tramos, inicio = [], None
    for i, c in enumerate(callado):
        if c and inicio is None:
            inicio = i
        elif not c and inicio is not None:
            if (i - inicio) * VENTANA_S >= SILENCIO_MIN_S:
                tramos.append((inicio * VENTANA_S, i * VENTANA_S))
            inicio = None
    return tramos


def elegir_cortes(tramos: list[tuple[float, float]], textos: list[str], total: float) -> list[float] | None:
    """Un corte por cambio de línea. Prueba todas las combinaciones de pausas y elige la que deja a todas las
    líneas a la misma velocidad de habla (caracteres/segundo). No basta con "la pausa más larga": las pausas
    de los "..." dentro de una línea duran casi lo mismo que las pausas entre líneas (prueba del 21-Nov-2026)."""
    from itertools import combinations
    necesarios = len(textos) - 1
    if len(tramos) < necesarios:
        return None
    largos = np.array([len(t) for t in textos], dtype=float)
    ritmo = largos.sum() / total
    medios = [(a + b) / 2 for a, b in tramos]
    pausas = [b - a for a, b in tramos]
    mejor, mejor_puntaje = None, None
    combos = combinations(range(len(tramos)), necesarios)
    for n, combo in enumerate(combos):
        if n > 300_000:
            break
        limites = [0.0] + [medios[i] for i in combo] + [total]
        duraciones = np.diff(limites)
        if (duraciones < 0.3).any():
            continue
        # error de velocidad de cada línea (en escala log) y un pequeño premio por cortar en pausas largas
        error = float((np.log(duraciones * ritmo / largos) ** 2).sum()) - 0.5 * sum(pausas[i] for i in combo)
        if mejor_puntaje is None or error < mejor_puntaje:
            mejor, mejor_puntaje = combo, error
    return None if mejor is None else [medios[i] for i in mejor]


def recortar(pedazo: np.ndarray, sr: int, realce: float) -> np.ndarray:
    voz = np.flatnonzero(np.abs(pedazo) > 0.02)
    if voz.size:
        m = int(MARGEN_S * sr)
        pedazo = pedazo[max(0, voz[0] - m): voz[-1] + m]
    pico = float(np.abs(pedazo).max()) if pedazo.size else 0.0
    if pico > 0:
        pedazo = pedazo * (PICO / pico)
    return realzar_agudos(pedazo, sr, realce)


def main() -> None:
    global SILENCIO_DB, SILENCIO_MIN_S
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lista", required=True)
    ap.add_argument("--limite", type=int, default=LIMITE_CARACTERES, help="caracteres por pedido")
    ap.add_argument("--max-pedidos", type=int, help="hace solo los primeros N pedidos (tope de gasto)")
    ap.add_argument("--desde-pedido", type=int, default=1, help="empieza en este número de pedido (1 = el primero)")
    ap.add_argument("--carpeta-prueba", help="guarda en assets/audio/<carpeta> con el nombre de cada archivo, en vez de su ruta final")
    ap.add_argument("--estimar", action="store_true")
    ap.add_argument("--solo-cortar", action="store_true",
                    help="no llama a fal: vuelve a cortar los _pedido_NN_completo.wav ya guardados (costo 0)")
    ap.add_argument("--solo-pedidos", help="con --solo-cortar: solo estos pedidos, p. ej. 4,5,6")
    ap.add_argument("--silencio-db", type=float, help=f"umbral de pausa en dB bajo el pico (por defecto {SILENCIO_DB}); "
                    "Coco tiene más ruido de fondo y necesita -32 (prueba del 21-Nov-2026)")
    ap.add_argument("--silencio-min", type=float, help=f"pausa mínima en s (por defecto {SILENCIO_MIN_S})")
    args = ap.parse_args()
    if args.silencio_db is not None:
        SILENCIO_DB = args.silencio_db
    if args.silencio_min is not None:
        SILENCIO_MIN_S = args.silencio_min

    bloques = agrupar(leer_lista(RAIZ / args.lista, None), args.limite)
    elegidos = bloques[args.desde_pedido - 1:]
    if args.max_pedidos:
        elegidos = elegidos[: args.max_pedidos]
    lineas = sum(len(b) for b in elegidos)
    # 1 pedido = 1 bloque cobrado (cada bloque < 1.000 caracteres); --solo-cortar no llama a fal
    costo = 0.0 if args.solo_cortar else len(elegidos) * PRECIO_USD_POR_1000
    print(f"{lineas} líneas en {len(elegidos)} pedidos (de {len(bloques)} en total) -> USD {costo:.2f}, sin reintentos")
    for i, b in enumerate(elegidos, args.desde_pedido):
        print(f"  pedido {i}: {len(b)} líneas, {sum(len(t) for _, t, _ in b)} car., ~{sum(len(t) for _, t, _ in b) / CARACTERES_POR_SEGUNDO:.0f} s")
    if args.estimar:
        return

    key = None if args.solo_cortar else obtener_key("FAL_KEY")
    voces: dict[str, dict] = {}
    solo = {int(x) for x in args.solo_pedidos.split(",")} if args.solo_pedidos else None
    for i, bloque in enumerate(elegidos, args.desde_pedido):
        if solo is not None and i not in solo:
            continue
        voz = voces.setdefault(bloque[0][2], cargar_voz(bloque[0][2]))
        textos = [t for _, t, _ in bloque]
        base = RAIZ / "assets" / "audio" / (args.carpeta_prueba or "voces/_crudos_fal")
        # el audio completo de cada pedido se archiva en _crudos_fal (con .gdignore: no entra al build)
        completo = RAIZ / "assets" / "audio" / "voces" / "_crudos_fal" / f"{Path(args.lista).stem}_pedido_{i:02d}_completo.wav"
        if args.solo_cortar:
            if not completo.exists():
                print(f"pedido {i}: no hay {completo.name}, se salta")
                continue
            import soundfile as sf
            datos, sr = sf.read(completo, dtype="float32")
        else:
            datos, sr = limpiar(sintetizar("\n\n".join(textos), voz, key), 1.0)  # el realce va por pedazo
            guardar(completo, datos, sr)
        total = len(datos) / sr
        esperado = sum(len(t) for t in textos) / CARACTERES_POR_SEGUNDO
        print(f"pedido {i}: {total:.1f} s de audio (esperado ~{esperado:.0f} s)")
        cortes = elegir_cortes(silencios(datos, sr), textos, total) if len(textos) > 1 else []
        if cortes is None:
            print(f"  NO SE CORTÓ: no hay suficientes pausas. Quedó solo el audio completo.")
            continue
        limites = [0.0] + cortes + [total]
        pedazos = [datos[int(a * sr): int(b * sr)] for a, b in zip(limites, limites[1:])]
        razones = [(len(p) / sr) / (len(t) / CARACTERES_POR_SEGUNDO) for p, t in zip(pedazos, textos)]
        malos = [k for k, r in enumerate(razones) if not TOLERANCIA[0] <= r <= TOLERANCIA[1]]
        if malos:
            print(f"  NO SE GUARDÓ: los pedazos {[k + 1 for k in malos]} no calzan con su texto "
                  f"(duración/esperada {[round(razones[k], 2) for k in malos]}). Quedó solo el audio completo.")
            continue
        pendientes = leer_pendientes()
        for (ruta, texto, _), pedazo in zip(bloque, pedazos):
            limpio = recortar(pedazo, sr, voz.get("realce_agudos", 1.0))
            destino = (base / Path(ruta).name) if args.carpeta_prueba else RAIZ / "assets" / "audio" / ruta
            guardar(destino, limpio, sr)
            if not args.carpeta_prueba and ruta in pendientes:  # ya tiene su voz oficial
                pendientes.discard(ruta)
                escribir_pendientes(pendientes)
            print(f"  {len(limpio) / sr:4.1f} s  {destino.relative_to(RAIZ).as_posix()}  «{texto[:50]}»")


if __name__ == "__main__":
    main()
