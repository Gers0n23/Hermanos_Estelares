#!/usr/bin/env python3
"""Prueba de musica instrumental con MiniMax Music 2.6 (fal.ai) para el viaje estelar.

Costo: USD 0,15 por pista (una sola pista en esta prueba; la duracion no se controla,
el modelo devuelve una pista completa que luego se recorta al video).
MiniMax no genera efectos de sonido; los sonidos de la prueba salen de MMAudio.

Uso:
  python herramientas/probar_musica_minimax.py --estimar   # solo muestra el costo
  python herramientas/probar_musica_minimax.py             # genera (cobra)

Salida: <scratchpad>/audio_prueba/musica_minimax_viaje.mp3
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

SALIDA = Path(
    "C:/Users/gcordero/AppData/Local/Temp/claude/fcd0c04074dcdf66/"
    "95ebbf13-e080-4a76-b271-b92719695e89/scratchpad/audio_prueba"
)
MODELO = "fal-ai/minimax-music/v2.6"
QUEUE_BASE = "https://queue.fal.run/{modelo}"
PRECIO_USD_POR_PISTA = 0.15
INTERVALO_SONDEO_S = 5
TIMEOUT_TOTAL_S = 15 * 60

PROMPT = (
    "Cheerful kids' space adventure theme, bright orchestral and playful synth, "
    "a friendly spaceship flying through the stars, light and bouncy rhythm, "
    "around 120 BPM, major key, instrumental, no vocals"
)


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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--estimar", action="store_true", help="solo calcula el costo, no llama a fal")
    args = parser.parse_args()

    print(f"1 pista -> costo estimado USD {PRECIO_USD_POR_PISTA:.2f} (sin reintentos)")
    if args.estimar:
        return

    headers = {"Authorization": f"Key {obtener_key('FAL_KEY')}"}
    envio = _json(QUEUE_BASE.format(modelo=MODELO), {"prompt": PROMPT, "is_instrumental": True}, headers)
    url_status, url_result = envio.get("status_url"), envio.get("response_url")
    if not url_status or not url_result:
        sys.exit(f"ERROR: la cola no devolvio status_url/response_url: {json.dumps(envio)[:1500]}")
    print(f"En cola (request_id={envio.get('request_id')})")

    inicio = time.monotonic()
    while True:
        if time.monotonic() - inicio > TIMEOUT_TOTAL_S:
            sys.exit("ERROR: timeout esperando la musica")
        estado = _json(url_status, None, headers)
        if estado.get("status") == "COMPLETED":
            break
        if estado.get("status") in ("ERROR", "FAILED"):
            sys.exit(f"ERROR: fallo la generacion: {json.dumps(estado)[:1500]}")
        time.sleep(INTERVALO_SONDEO_S)

    resultado = _json(url_result, None, headers)
    url_audio = resultado["audio"]["url"]
    SALIDA.mkdir(parents=True, exist_ok=True)
    destino = SALIDA / "musica_minimax_viaje.mp3"
    with urllib.request.urlopen(urllib.request.Request(url_audio), timeout=300) as resp:
        destino.write_bytes(resp.read())
    print(f"OK  {destino}  ({destino.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
