"""Genera las voces de personaje con Qwen3-TTS en fal.ai (decisión del PO, 14-Sep-2026).

Reemplaza a `generar_voces_tts.ps1` (TTS de Windows) para los personajes que ya tienen voz
elegida. Cada personaje vive en `herramientas/voces_personajes/<id>/`:

- `voz.json`: modelo, idioma, texto de referencia y descripción con que se diseñó la voz.
- `embedding.safetensors`: la "huella" de la voz (clonada de `referencia.mp3`). Se envía en cada
  pedido, así que todas las líneas suenan al mismo personaje.

Lee los mismos TSV de siempre ("ruta<TAB>texto", ruta relativa a `assets/audio/`). Solo genera las
líneas bajo una directiva `# personaje: <id>`, que vale hasta la siguiente directiva; las líneas
sin personaje se saltan (siguen con su voz anterior). `--personaje` fuerza uno para todo el TSV.

El MP3 que devuelve fal se recorta (silencios de los bordes), se normaliza y se guarda en el
formato de la ruta de destino (`.wav` PCM 16 bits u `.ogg` Vorbis).

Uso:
  python herramientas/generar_voces_fal.py --lista assets/audio/voces/nucleo/lineas_tts.tsv
  python herramientas/generar_voces_fal.py --lista <tsv> --solo cometa_vamos --personaje cometa

La key se lee de `.env` (FAL_KEY), ver herramientas/config.py.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

import numpy as np
import soundfile as sf

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import RAIZ, obtener_key  # noqa: E402

CARPETA_VOCES = RAIZ / "herramientas" / "voces_personajes"
ENDPOINT_TTS = "https://fal.run/fal-ai/qwen-3-tts/text-to-speech/1.7b"

UMBRAL_SILENCIO = 0.02   # amplitud bajo la cual se considera silencio al recortar bordes
MARGEN_S = 0.08          # aire que se deja antes y después de la voz
PICO = 0.89              # normalización (~ -1 dBFS)
INTENTOS = 3
## Precio de Qwen3-TTS text-to-speech en fal.ai (revisado el 14-Sep-2026). Solo para mostrar el costo
## estimado antes de generar: revisa el precio vigente antes de una tanda grande.
PRECIO_USD_POR_1000 = 0.09


ARCHIVO_PENDIENTES = RAIZ / "assets" / "audio" / "voces" / "pendientes_fal.txt"


def leer_pendientes() -> set[str]:
    """Rutas que todavía tienen voz de relleno (TTS de Windows) y esperan su voz oficial."""
    if not ARCHIVO_PENDIENTES.exists():
        return set()
    return {l.strip() for l in ARCHIVO_PENDIENTES.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")}


def escribir_pendientes(pendientes: set[str]) -> None:
    cabecera = [l for l in ARCHIVO_PENDIENTES.read_text(encoding="utf-8").splitlines() if l.startswith("#")]
    ARCHIVO_PENDIENTES.write_text("\n".join(cabecera + sorted(pendientes)) + "\n", encoding="utf-8")


def cargar_voz(personaje: str) -> dict:
    carpeta = CARPETA_VOCES / personaje
    ficha = carpeta / "voz.json"
    if not ficha.exists():
        sys.exit(f"ERROR: no hay voz para '{personaje}' ({ficha})")
    voz = json.loads(ficha.read_text(encoding="utf-8"))
    embedding = (carpeta / voz["embedding"]).read_bytes()
    voz["embedding_uri"] = "data:application/octet-stream;base64," + base64.b64encode(embedding).decode()
    return voz


def leer_lista(tsv: Path, personaje_forzado: str | None) -> list[tuple[str, str, str]]:
    """Devuelve (ruta, texto, personaje) de las líneas que tienen personaje asignado."""
    lineas: list[tuple[str, str, str]] = []
    actual = personaje_forzado
    for cruda in tsv.read_text(encoding="utf-8-sig").splitlines():
        linea = cruda.strip()
        if not linea:
            continue
        if linea.startswith("#"):
            cuerpo = linea.lstrip("#").strip()
            if cuerpo.lower().startswith("personaje:") and personaje_forzado is None:
                actual = cuerpo.split(":", 1)[1].strip() or None
            continue
        ruta, _, texto = cruda.partition("\t")
        if actual and texto.strip():
            lineas.append((ruta.strip(), texto.strip(), actual))
    return lineas


def sintetizar(texto: str, voz: dict, key: str) -> bytes:
    cuerpo = {
        "text": texto,
        "language": voz.get("idioma", "Spanish"),
        "speaker_voice_embedding_file_url": voz["embedding_uri"],
        "reference_text": voz["texto_referencia"],
        "temperature": voz.get("temperatura", 0.8),
        "max_new_tokens": 1500,
    }
    req = urllib.request.Request(
        ENDPOINT_TTS, data=json.dumps(cuerpo).encode("utf-8"),
        headers={"Authorization": f"Key {key}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        url = json.loads(r.read())["audio"]["url"]
    with urllib.request.urlopen(url, timeout=300) as r:
        return r.read()


def limpiar(mp3: bytes) -> tuple[np.ndarray, int]:
    datos, sr = sf.read(io.BytesIO(mp3), dtype="float32")
    if datos.ndim > 1:
        datos = datos.mean(axis=1)
    voz = np.flatnonzero(np.abs(datos) > UMBRAL_SILENCIO)
    if voz.size:
        margen = int(MARGEN_S * sr)
        datos = datos[max(0, voz[0] - margen): voz[-1] + margen]
    pico = float(np.abs(datos).max()) if datos.size else 0.0
    if pico > 0:
        datos = datos * (PICO / pico)
    return datos, sr


def duracion_razonable(segundos: float, texto: str) -> bool:
    # Los modelos generativos a veces "alargan" (balbuceo, repeticiones): se reintenta.
    return segundos <= 2.5 + len(texto) * 0.12


def guardar(destino: Path, datos: np.ndarray, sr: int) -> None:
    destino.parent.mkdir(parents=True, exist_ok=True)
    if destino.suffix.lower() == ".ogg":
        sf.write(destino, datos, sr, format="OGG", subtype="VORBIS")
    else:
        sf.write(destino, datos, sr, subtype="PCM_16")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--lista", required=True, help="TSV relativo a la raíz del repo")
    parser.add_argument("--personaje", help="usa este personaje para todas las líneas del TSV")
    parser.add_argument("--solo", help="genera solo las rutas que contienen este texto")
    parser.add_argument("--solo-personaje", help="genera solo las líneas de este personaje")
    parser.add_argument("--excluir", action="append", default=[], help="salta las rutas que contienen este texto (repetible)")
    parser.add_argument("--omitir-desde", help="salta las líneas cuyo archivo ya fue generado desde esta fecha local (AAAA-MM-DDTHH:MM); evita pagar dos veces")
    parser.add_argument("--estimar", action="store_true", help="solo cuenta líneas y costo estimado, sin llamar a fal")
    parser.add_argument("--solo-pendientes", action="store_true",
                        help=f"genera solo las rutas de {ARCHIVO_PENDIENTES.relative_to(RAIZ).as_posix()} y las saca de la lista al generarlas")
    args = parser.parse_args()

    lineas = leer_lista(RAIZ / args.lista, args.personaje)
    pendientes = leer_pendientes()
    if args.solo_pendientes:
        lineas = [l for l in lineas if l[0] in pendientes]
    if args.solo:
        lineas = [l for l in lineas if args.solo in l[0]]
    if args.solo_personaje:
        lineas = [l for l in lineas if l[2] == args.solo_personaje]
    for texto in args.excluir:
        lineas = [l for l in lineas if texto not in l[0]]
    if args.omitir_desde:
        limite = datetime.fromisoformat(args.omitir_desde).timestamp()
        destino = lambda ruta: RAIZ / "assets" / "audio" / ruta
        lineas = [l for l in lineas if not (destino(l[0]).exists() and destino(l[0]).stat().st_mtime >= limite)]
    caracteres = sum(len(l[1]) for l in lineas)
    print(f"{len(lineas)} líneas, {caracteres} caracteres (~USD {caracteres / 1000 * PRECIO_USD_POR_1000:.2f} sin reintentos)")
    if args.estimar:
        return
    if not lineas:
        sys.exit("No hay líneas con personaje asignado en esa lista.")

    key = obtener_key("FAL_KEY")
    voces: dict[str, dict] = {}
    fallas = 0
    for ruta, texto, personaje in lineas:
        voz = voces.setdefault(personaje, cargar_voz(personaje))
        destino = RAIZ / "assets" / "audio" / ruta
        for intento in range(1, INTENTOS + 1):
            try:
                datos, sr = limpiar(sintetizar(texto, voz, key))
                segundos = len(datos) / sr
                if not duracion_razonable(segundos, texto) and intento < INTENTOS:
                    print(f"  reintento ({segundos:.1f} s es demasiado largo): {ruta}")
                    continue
                guardar(destino, datos, sr)
                print(f"voz [{personaje}] {segundos:4.1f} s  {ruta}")
                if ruta in pendientes:
                    pendientes.discard(ruta)
                    escribir_pendientes(pendientes)
                break
            except (urllib.error.URLError, KeyError, RuntimeError) as e:
                if isinstance(e, urllib.error.HTTPError) and e.code in (401, 403):
                    sys.exit(f"fal.ai rechazó el pedido ({e.code}): revisa saldo o key. Detenido en {ruta}.")
                if intento == INTENTOS:
                    fallas += 1
                    print(f"ERROR {ruta}: {e}")
                else:
                    time.sleep(2 * intento)
    if fallas:
        sys.exit(f"{fallas} línea(s) sin generar.")


if __name__ == "__main__":
    main()
