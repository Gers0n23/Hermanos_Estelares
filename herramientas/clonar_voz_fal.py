"""Clona la voz de un personaje con Qwen3-TTS clone-voice en fal.ai y guarda su huella.

Crea `herramientas/voces_personajes/<personaje>/` con:
- `referencia.wav`: el audio de referencia (se extrae del video o audio que se le pase).
- `embedding.safetensors`: la huella de la voz que devuelve fal (speaker_embedding).
- `voz.json`: la ficha que lee `generar_voces_fal.py` (modelo, idioma, texto de referencia).

Precio verificado (fal.ai, clone-voice 1.7B): USD 0,0008 por minuto de audio de referencia.
Máximo 300 s de referencia. Con `--estimar` solo calcula el costo; sin él, hace UNA llamada.

Uso:
  python herramientas/clonar_voz_fal.py --personaje maxi --referencia assets/ejemplos/Maxi.mp4 --estimar
  python herramientas/clonar_voz_fal.py --personaje maxi --referencia assets/ejemplos/Maxi.mp4
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

import imageio_ffmpeg
import soundfile as sf

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import RAIZ, obtener_key  # noqa: E402

CARPETA_VOCES = RAIZ / "herramientas" / "voces_personajes"
ENDPOINT_CLONADO = "https://fal.run/fal-ai/qwen-3-tts/clone-voice/1.7b"
MODELO_TTS = "fal-ai/qwen-3-tts/text-to-speech/1.7b"
PRECIO_USD_POR_MINUTO = 0.0008
MAX_SEGUNDOS = 300


def extraer_wav(origen: Path, destino: Path) -> float:
    """Pasa el audio de `origen` (mp4, mp3, wav...) a WAV mono de 24 kHz. Devuelve segundos."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", str(origen), "-vn", "-ac", "1",
                    "-ar", "24000", str(destino)], check=True)
    return sf.info(destino).duration


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--personaje", required=True, help="id de la carpeta, p. ej. maxi")
    ap.add_argument("--referencia", required=True, type=Path, help="video o audio con la voz (mp4, mp3, wav)")
    ap.add_argument("--texto-referencia", default="", help="lo que dice el audio (opcional, mejora la calidad)")
    ap.add_argument("--estimar", action="store_true", help="solo muestra la duración y el costo, sin llamar a fal")
    args = ap.parse_args()

    carpeta = CARPETA_VOCES / args.personaje
    origen = args.referencia if args.referencia.is_absolute() else RAIZ / args.referencia
    wav = carpeta / "referencia.wav"
    segundos = extraer_wav(origen, wav)
    if segundos > MAX_SEGUNDOS:
        sys.exit(f"La referencia dura {segundos:.0f} s; el máximo es {MAX_SEGUNDOS} s.")
    costo = segundos / 60 * PRECIO_USD_POR_MINUTO
    print(f"referencia: {segundos:.1f} s -> costo clonado ~USD {costo:.4f} (una sola llamada)")
    if args.estimar:
        return

    key = obtener_key("FAL_KEY")
    audio_uri = "data:audio/wav;base64," + base64.b64encode(wav.read_bytes()).decode()
    cuerpo = {"audio_url": audio_uri}
    if args.texto_referencia:
        cuerpo["reference_text"] = args.texto_referencia
    req = urllib.request.Request(
        ENDPOINT_CLONADO, data=json.dumps(cuerpo).encode("utf-8"),
        headers={"Authorization": f"Key {key}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        respuesta = json.loads(r.read())
    with urllib.request.urlopen(respuesta["speaker_embedding"]["url"], timeout=300) as r:
        (carpeta / "embedding.safetensors").write_bytes(r.read())

    ficha = {
        "personaje": args.personaje,
        "estado": "PRUEBA: clonada de la referencia de la familia; pendiente de aprobación del PO.",
        "modelo": MODELO_TTS,
        "idioma": "Spanish",
        "temperatura": 0.8,
        "embedding": "embedding.safetensors",
        "referencia": "referencia.wav",
        "texto_referencia": args.texto_referencia,
        "diseno": {"clonado": "fal-ai/qwen-3-tts/clone-voice/1.7b", "fuente": str(args.referencia)},
    }
    (carpeta / "voz.json").write_text(json.dumps(ficha, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"voz de {args.personaje} guardada en {carpeta.relative_to(RAIZ).as_posix()}")


if __name__ == "__main__":
    main()
