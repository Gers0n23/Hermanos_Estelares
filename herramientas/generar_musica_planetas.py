#!/usr/bin/env python3
"""Genera la musica instrumental de cada planeta con MiniMax Music 2.6 (fal.ai).

Decision del PO (21-Nov-2026): una pista base comun para el viaje, el taller, la llegada
y el minijuego arcade (ya existe: poc/cinematica_blender/salida/musica_minimax_viaje.mp3)
y una variante por planeta. Costo: USD 0,15 por pista (sin reintentos).

Las pistas que ya existan en la carpeta de salida no se vuelven a pagar.

Uso:
  python herramientas/generar_musica_planetas.py --estimar
  python herramientas/generar_musica_planetas.py
Salida: assets/audio/musica/planetas/<id>.mp3 (se convierte a .ogg con --ogg despues)
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import obtener_key  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets" / "audio" / "musica" / "planetas"
MODELO = "fal-ai/minimax-music/v2.6"
QUEUE_BASE = "https://queue.fal.run/{modelo}"
PRECIO_USD_POR_PISTA = 0.15
INTERVALO_SONDEO_S = 5
TIMEOUT_TOTAL_S = 15 * 60

BASE = (
    "bright playful kids' space adventure, friendly orchestral and synth, "
    "light bouncy rhythm, major key, instrumental, no vocals, "
)

PLANETAS = {
    "arcoiris": BASE + "rainbow colors, glockenspiel and soft plucked strings, around 110 BPM",
    "animalia": BASE + "jungle animals, marimba, bongos and tropical flute, around 104 BPM",
    "melodia": BASE + "funky dance groove, synth bass, handclaps and a DJ vibe, around 118 BPM",
    "cuenta_cuentas": BASE + "counting game, music box and pizzicato strings, walking rhythm, around 100 BPM",
    "letralandia": BASE + "storybook letters, xylophone and whimsical woodwinds, gentle, around 92 BPM",
    "corazon": BASE + "warm and tender, harp and soft strings, lullaby feel, around 84 BPM",
}


def _json(url: str, cuerpo: dict | None, headers: dict) -> dict:
    datos = json.dumps(cuerpo).encode("utf-8") if cuerpo is not None else None
    req = urllib.request.Request(
        url,
        data=datos,
        headers={"Content-Type": "application/json", **headers},
        method="POST" if cuerpo is not None else "GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"ERROR HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:1500]}")


def _generar(planeta: str, prompt: str, headers: dict) -> Path:
    destino = SALIDA / f"{planeta}.mp3"
    envio = _json(QUEUE_BASE.format(modelo=MODELO), {"prompt": prompt, "is_instrumental": True}, headers)
    url_status, url_result = envio.get("status_url"), envio.get("response_url")
    if not url_status or not url_result:
        sys.exit(f"ERROR: la cola no devolvio status_url/response_url: {json.dumps(envio)[:1500]}")
    print(f"En cola: {planeta} (request_id={envio.get('request_id')})")

    inicio = time.monotonic()
    while True:
        if time.monotonic() - inicio > TIMEOUT_TOTAL_S:
            sys.exit(f"ERROR: timeout esperando {planeta}")
        estado = _json(url_status, None, headers)
        if estado.get("status") == "COMPLETED":
            break
        if estado.get("status") in ("ERROR", "FAILED"):
            sys.exit(f"ERROR: fallo {planeta}: {json.dumps(estado)[:1500]}")
        time.sleep(INTERVALO_SONDEO_S)

    resultado = _json(url_result, None, headers)
    with urllib.request.urlopen(urllib.request.Request(resultado["audio"]["url"]), timeout=300) as resp:
        destino.write_bytes(resp.read())
    print(f"OK  {destino}  ({destino.stat().st_size / 1024:.0f} KB)")
    return destino


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--estimar", action="store_true", help="solo calcula el costo, no llama a fal")
    args = parser.parse_args()

    SALIDA.mkdir(parents=True, exist_ok=True)
    pendientes = [p for p in PLANETAS if not (SALIDA / f"{p}.mp3").exists()]
    print(f"{len(pendientes)} pistas por generar de {len(PLANETAS)} -> costo estimado USD {len(pendientes) * PRECIO_USD_POR_PISTA:.2f}")
    if args.estimar or not pendientes:
        return

    headers = {"Authorization": f"Key {obtener_key('FAL_KEY')}"}
    for planeta in pendientes:
        _generar(planeta, PLANETAS[planeta], headers)


if __name__ == "__main__":
    main()
