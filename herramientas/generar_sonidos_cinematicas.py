#!/usr/bin/env python3
"""Genera los efectos de sonido de las 19 cinematicas de Blender con MMAudio V2 (fal.ai).

Decision del PO (21-Nov-2026): sonidos sincronizados a cada clip, costo USD 0,001 por
segundo de video. Cada clip con sonido sale como <stem>_mmaudio.mp4 (video original +
audio generado) en poc/cinematica_blender/salida/audio_mmaudio/. Los que ya existan no
se vuelven a pagar. La musica NO sale de aqui (es MiniMax, otro script).

Uso:
  python herramientas/generar_sonidos_cinematicas.py --estimar
  python herramientas/generar_sonidos_cinematicas.py
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import obtener_key  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "poc" / "cinematica_blender" / "salida"
SALIDA = ORIGEN / "audio_mmaudio"
FFMPEG = Path(
    "C:/Users/gcordero/AppData/Local/Programs/Python/Python313/Lib/site-packages/"
    "imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe"
)
MODELO = "fal-ai/mmaudio-v2"
QUEUE_BASE = "https://queue.fal.run/{modelo}"
PRECIO_USD_POR_S = 0.001
INTERVALO_SONDEO_S = 5
TIMEOUT_TOTAL_S = 15 * 60
NEGATIVO = "speech, voices, music, human voice, singing"

PROMPTS = {
    "taller": (
        "spaceship part being assembled in a workshop: small mechanical clicks, gentle "
        "sparkle, a playful chime when it snaps in place"
    ),
    "presentacion": (
        "a colorful planet being shown off: soft wind, sparkly magical chimes, a light "
        "cheerful whoosh"
    ),
    "viaje": (
        "spaceship flying through outer space: friendly engine hum, soft whoosh, light "
        "sparkly chimes, cheerful sci-fi feel"
    ),
    "llegada": (
        "spaceship descending and landing gently: engine hum fading, soft thruster "
        "whoosh, a little landing thud and sparkly chime"
    ),
}


def _tipo(nombre: str) -> str:
    if nombre.startswith("taller_pieza"):
        return "taller"
    if nombre.startswith("presentacion"):
        return "presentacion"
    if nombre.startswith("viaje"):
        return "viaje"
    if nombre.startswith("llegada"):
        return "llegada"
    raise SystemExit(f"ERROR: no reconozco el tipo de {nombre}")


def _duracion(ruta: Path) -> float:
    salida = subprocess.run([str(FFMPEG), "-hide_banner", "-i", str(ruta)], capture_output=True, text=True).stderr
    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", salida)
    if not m:
        raise SystemExit(f"ERROR: no pude leer la duracion de {ruta.name}")
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))


def _clips() -> list[dict]:
    clips = []
    for ruta in sorted(ORIGEN.glob("*.mp4")):
        nombre = ruta.name
        if nombre.endswith("_foto_0270.png") or "_mmaudio" in nombre or nombre.startswith("prueba"):
            continue
        if not (nombre.startswith(("taller_pieza", "presentacion", "viaje", "llegada_nave_v2"))):
            continue
        clips.append({"ruta": ruta, "segundos": round(_duracion(ruta), 2), "prompt": PROMPTS[_tipo(nombre)]})
    return clips


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


def _generar(clip: dict, headers: dict) -> None:
    ruta: Path = clip["ruta"]
    destino = SALIDA / (ruta.stem + "_mmaudio.mp4")
    cuerpo = {
        "video_url": _data_uri(ruta),
        "prompt": clip["prompt"],
        "duration": clip["segundos"],
        "negative_prompt": NEGATIVO,
    }
    envio = _json(QUEUE_BASE.format(modelo=MODELO), cuerpo, headers)
    url_status, url_result = envio.get("status_url"), envio.get("response_url")
    if not url_status or not url_result:
        sys.exit(f"ERROR: la cola no devolvio status_url/response_url: {json.dumps(envio)[:1500]}")
    print(f"En cola: {ruta.name} ({clip['segundos']} s)")

    inicio = time.monotonic()
    while True:
        if time.monotonic() - inicio > TIMEOUT_TOTAL_S:
            sys.exit(f"ERROR: timeout esperando {ruta.name}")
        estado = _json(url_status, None, headers)
        if estado.get("status") == "COMPLETED":
            break
        if estado.get("status") in ("ERROR", "FAILED"):
            sys.exit(f"ERROR: fallo {ruta.name}: {json.dumps(estado)[:1500]}")
        time.sleep(INTERVALO_SONDEO_S)

    resultado = _json(url_result, None, headers)
    with urllib.request.urlopen(urllib.request.Request(resultado["video"]["url"]), timeout=300) as resp:
        destino.write_bytes(resp.read())
    print(f"OK  {destino.name}  ({destino.stat().st_size / 1024:.0f} KB)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--estimar", action="store_true", help="solo calcula el costo, no llama a fal")
    args = parser.parse_args()

    SALIDA.mkdir(parents=True, exist_ok=True)
    clips = _clips()
    pendientes = [c for c in clips if not (SALIDA / (c["ruta"].stem + "_mmaudio.mp4")).exists()]
    total_s = sum(c["segundos"] for c in pendientes)
    print(
        f"{len(pendientes)} clips por generar de {len(clips)} "
        f"({total_s:.2f} s) -> costo estimado USD {total_s * PRECIO_USD_POR_S:.3f} (sin reintentos)"
    )
    if args.estimar or not pendientes:
        return

    headers = {"Authorization": f"Key {obtener_key('FAL_KEY')}"}
    for clip in pendientes:
        _generar(clip, headers)


if __name__ == "__main__":
    main()
