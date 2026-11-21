#!/usr/bin/env python3
"""Convierte la musica y las cinematicas al formato que Godot 4 reproduce.

- Musica: MP3 crudos de MiniMax (assets/generadas/audio/musica/, staging con .gdignore)
  -> OGG Vorbis en assets/audio/musica/ (Godot: OGG para musica, guia audio-system).
- Cinematicas: video de poc/cinematica_blender/salida (mp4 maestro) + audio de MMAudio
  (<stem>_mmaudio.mp4) -> Ogg Theora q5 con audio Vorbis en assets/video/<tipo>/
  (taller, presentacion, viaje, llegada). Godot 4 solo reproduce .ogv en
  VideoStreamPlayer; el audio va en el mismo contenedor, asi queda sincronizado.
  Si no hay audio de MMAudio para un clip, se usa solo el video (sin audio).

Sin costo: todo es local (ffmpeg). Los mp4 maestros no se tocan.

Uso:
  python herramientas/convertir_audio_cinematicas.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
FFMPEG = Path(
    "C:/Users/gcordero/AppData/Local/Programs/Python/Python313/Lib/site-packages/"
    "imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe"
)
ORIGEN = RAIZ / "poc" / "cinematica_blender" / "salida"
SONIDOS = ORIGEN / "audio_mmaudio"
MUSICA_CRUDA = RAIZ / "assets" / "generadas" / "audio" / "musica"
MUSICA_PLANETAS = RAIZ / "assets" / "audio" / "musica" / "planetas"
MUSICA_BASE = RAIZ / "assets" / "audio" / "musica" / "viaje_minimax.ogg"
CINEMATICAS = RAIZ / "assets" / "video"  # videos Godot (.ogv); docs/cinematicas/cierre_arcoiris.md usa assets/video/<bloque>/
TIPOS_CINEMATICA = ("taller", "presentacion", "viaje", "llegada")
CALIDAD_THEORA = "5"
CALIDAD_VORBIS = "5"


def _ffmpeg(*args: str) -> None:
    cmd = [str(FFMPEG), "-hide_banner", "-loglevel", "error", "-y", *args]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(f"ERROR ffmpeg {' '.join(args)}\n{res.stderr[-1500:]}")


def _tipo_cinematica(nombre: str) -> str:
    for tipo in TIPOS_CINEMATICA:
        if nombre.startswith(tipo if tipo != "llegada" else "llegada_nave"):
            return tipo
    raise SystemExit(f"ERROR: no reconozco el tipo de {nombre}")


def convertir_musica() -> None:
    MUSICA_PLANETAS.mkdir(parents=True, exist_ok=True)
    _ffmpeg("-i", str(MUSICA_CRUDA / "viaje_minimax.mp3"), "-vn", "-c:a", "libvorbis", "-q:a", CALIDAD_VORBIS, str(MUSICA_BASE))
    print(f"OK  {MUSICA_BASE.relative_to(RAIZ)}")
    for mp3 in sorted((MUSICA_CRUDA / "planetas").glob("*.mp3")):
        destino = MUSICA_PLANETAS / (mp3.stem + ".ogg")
        _ffmpeg("-i", str(mp3), "-vn", "-c:a", "libvorbis", "-q:a", CALIDAD_VORBIS, str(destino))
        print(f"OK  {destino.relative_to(RAIZ)}")


def convertir_cinematicas() -> None:
    for ruta in sorted(ORIGEN.glob("*.mp4")):
        nombre = ruta.name
        if nombre.endswith("_foto_0270.png") or "_mmaudio" in nombre or nombre.startswith("prueba"):
            continue
        if not nombre.startswith(("taller_pieza", "presentacion", "viaje", "llegada_nave_v2")):
            continue
        carpeta = CINEMATICAS / _tipo_cinematica(nombre)
        carpeta.mkdir(parents=True, exist_ok=True)
        destino = carpeta / (ruta.stem + ".ogv")
        sonido = SONIDOS / (ruta.stem + "_mmaudio.mp4")
        if sonido.exists():
            # Video del maestro + audio de MMAudio; -shortest evita colas de silencio.
            _ffmpeg(
                "-i", str(ruta), "-i", str(sonido),
                "-map", "0:v:0", "-map", "1:a:0",
                "-c:v", "libtheora", "-q:v", CALIDAD_THEORA,
                "-c:a", "libvorbis", "-q:a", CALIDAD_VORBIS,
                "-shortest", str(destino),
            )
        else:
            _ffmpeg("-i", str(ruta), "-map", "0:v:0", "-c:v", "libtheora", "-q:v", CALIDAD_THEORA, "-an", str(destino))
        print(f"OK  {destino.relative_to(RAIZ)}  ({destino.stat().st_size / 1024 / 1024:.1f} MB, audio: {'si' if sonido.exists() else 'no'})")


if __name__ == "__main__":
    convertir_musica()
    convertir_cinematicas()
