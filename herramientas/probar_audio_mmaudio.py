#!/usr/bin/env python3
"""Prueba de sonido generado (MMAudio V2 en fal.ai) sobre dos cinematicas de Blender.

Costo: USD 0,001 por segundo de video pedido (sin reintentos). Se usa solo para
evaluar si el sonido sincronizado al video sirve para el juego (decision del PO,
21-Nov-2026: primero se prueba la musica gratis; esta prueba es solo de efectos).

Uso:
  python herramientas/probar_audio_mmaudio.py --estimar     # solo muestra el costo
  python herramientas/probar_audio_mmaudio.py               # genera (cobra)

Salida: <scratchpad>/audio_prueba/<clip>_mmaudio.mp4 (video + audio, sin tocar el original).
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import obtener_key  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "poc" / "cinematica_blender" / "salida"
SALIDA = Path(
    "C:/Users/gcordero/AppData/Local/Temp/claude/fcd0c04074dcdf66/"
    "95ebbf13-e080-4a76-b271-b92719695e89/scratchpad/audio_prueba"
)
MODELO = "fal-ai/mmaudio-v2"
QUEUE_BASE = "https://queue.fal.run/{modelo}"
PRECIO_USD_POR_S = 0.001
INTERVALO_SONDEO_S = 5
TIMEOUT_TOTAL_S = 15 * 60

# Duraciones medidas con ffmpeg (la facturación sigue la duración pedida).
CLIPS = [
    {
        "archivo": "viaje_arcoiris_a_animalia.mp4",
        "segundos": 11.75,
        "prompt": (
            "spaceship flying through outer space: friendly engine hum, soft whoosh, "
            "light sparkly chimes, cheerful kids sci-fi feel, no speech, no voices"
        ),
    },
    {
        "archivo": "taller_pieza_1_ala_izquierda.mp4",
        "segundos": 9.0,
        "prompt": (
            "spaceship part being assembled in a workshop: small mechanical clicks, "
            "gentle sparkle, a playful chime when it snaps in place, no speech, no voices"
        ),
    },
]


def _data_uri(ruta: Path) -> str:
    mime = mimetypes.guess_type(ruta.name)[0] or "video/mp4"
    return f"data:{mime};base64,{base64.b64encode(ruta.read_bytes()).decode('ascii')}"


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


def _generar(clip: dict, headers: dict) -> Path:
    ruta = ORIGEN / clip["archivo"]
    cuerpo = {
        "video_url": _data_uri(ruta),
        "prompt": clip["prompt"],
        "duration": clip["segundos"],
        "negative_prompt": "speech, voices, music, human voice",
    }
    envio = _json(QUEUE_BASE.format(modelo=MODELO), cuerpo, headers)
    url_status, url_result = envio.get("status_url"), envio.get("response_url")
    if not url_status or not url_result:
        sys.exit(f"ERROR: la cola no devolvio status_url/response_url: {json.dumps(envio)[:1500]}")
    print(f"En cola: {clip['archivo']} (request_id={envio.get('request_id')})")

    inicio = time.monotonic()
    while True:
        if time.monotonic() - inicio > TIMEOUT_TOTAL_S:
            sys.exit(f"ERROR: timeout esperando {clip['archivo']}")
        estado = _json(url_status, None, headers)
        if estado.get("status") == "COMPLETED":
            break
        if estado.get("status") in ("ERROR", "FAILED"):
            sys.exit(f"ERROR: fallo la generacion: {json.dumps(estado)[:1500]}")
        time.sleep(INTERVALO_SONDEO_S)

    resultado = _json(url_result, None, headers)
    url_video = resultado["video"]["url"]
    SALIDA.mkdir(parents=True, exist_ok=True)
    destino = SALIDA / (Path(clip["archivo"]).stem + "_mmaudio.mp4")
    req = urllib.request.Request(url_video)
    with urllib.request.urlopen(req, timeout=300) as resp:
        destino.write_bytes(resp.read())
    print(f"OK  {destino}  ({destino.stat().st_size / 1024:.0f} KB)")
    return destino


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--estimar", action="store_true", help="solo calcula el costo, no llama a fal")
    args = parser.parse_args()

    for clip in CLIPS:
        if not (ORIGEN / clip["archivo"]).exists():
            sys.exit(f"ERROR: no existe {ORIGEN / clip['archivo']}")
    total_s = sum(c["segundos"] for c in CLIPS)
    print(f"{len(CLIPS)} clips, {total_s:.2f} s de video -> costo estimado USD {total_s * PRECIO_USD_POR_S:.3f} (sin reintentos)")
    if args.estimar:
        return

    headers = {"Authorization": f"Key {obtener_key('FAL_KEY')}"}
    for clip in CLIPS:
        _generar(clip, headers)


if __name__ == "__main__":
    main()
