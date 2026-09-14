#!/usr/bin/env python3
"""Genera clips de video para las cinematicas de Los Hermanos Estelares.

Proveedores (decision del PO, 07-Ago-2026 — ver docs/stack-tecnico.md y
docs/cinematicas/escena_intro.md, "Eleccion de modelo de video"), ambos via fal.ai
con la misma FAL_KEY que ya usan las imagenes:

    seedance -> Seedance 2.0 (bytedance/seedance-2.0/reference-to-video)
                Por defecto para planos con 3+ personajes en cuadro (mejor techo
                de consistencia de elenco). Hasta 9 imagenes de referencia en
                --imagen/--ancla, referenciables en el prompt como @Image1,
                @Image2... (el schema real de fal.ai en Ago-2026 tope en 9; la
                guia de estilo menciona 12 de forma imprecisa, verificar si hace
                falta mas de 9 anclas en un plano puntual).
    kling    -> Kling v3 standard (fal-ai/kling-video/v3/standard/image-to-video)
                Planos de 1-2 personajes, mejor acabado cinematografico. Una sola
                imagen de arranque obligatoria (--imagen) + personajes opcionales
                via --ancla, que se mandan como "elements" (@Element1, @Element2...
                en el prompt).

Los endpoints de video son asincronos (cola de fal.ai): se envia el pedido, se
sondea el estado hasta COMPLETED y recien ahi se descarga el resultado — a
diferencia de generar_imagen.py (sync_mode), esto puede tardar varios minutos.

Se genera siempre MUDO (regla del proyecto: las voces se graban aparte y se
montan encima en Godot) — generate_audio queda forzado a false en ambos
proveedores, no es parametro de linea de comandos.

Las keys se leen de `.env` (o de la variable de entorno). Ver herramientas/config.py.

Uso (Seedance, plano con varios personajes):
    python herramientas/generar_video.py \\
        --prompt-file assets/prompts/cinematicas/intro/06_trajes_estelares_video.txt \\
        --salida assets/generadas/cinematicas/intro/06_trajes_estelares.mp4 \\
        --proveedor seedance \\
        --imagen assets/generadas/cinematicas/intro/06_trajes_estelares.png \\
        --ancla assets/anclas/cometa_referencia.png \\
        --ancla assets/anclas/hermanos_alturas.png

Uso (Kling, plano sin keyframe nuevo, ej. plano 07 — nave revelada):
    python herramientas/generar_video.py \\
        --prompt-file assets/prompts/cinematicas/intro/07_nave_revelada_video.txt \\
        --salida assets/generadas/cinematicas/intro/07_nave_revelada.mp4 \\
        --proveedor kling \\
        --imagen assets/anclas/nave_estrella_referencia.png
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

MODELOS = {
    "seedance": "bytedance/seedance-2.0/reference-to-video",
    "kling": "fal-ai/kling-video/v3/standard/image-to-video",
}

QUEUE_BASE = "https://queue.fal.run/{modelo}"

ASPECTOS_SEEDANCE = {"auto", "21:9", "16:9", "4:3", "1:1", "3:4", "9:16"}
RESOLUCIONES_SEEDANCE = {"480p", "720p", "1080p", "4k"}

INTERVALO_SONDEO_S = 5
TIMEOUT_TOTAL_S = 20 * 60  # los clips de ~5 s suelen tardar 1-4 min, se deja margen


def _data_uri(ruta: Path) -> str:
    mime = mimetypes.guess_type(ruta.name)[0] or "image/png"
    return f"data:{mime};base64,{base64.b64encode(ruta.read_bytes()).decode('ascii')}"


def _post_json(url: str, cuerpo: dict, headers: dict) -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(cuerpo).encode("utf-8"),
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"ERROR HTTP {e.code} al enviar el pedido: {e.read().decode('utf-8', 'replace')[:2000]}")


def _get_json(url: str, headers: dict) -> dict:
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"ERROR HTTP {e.code} al consultar el pedido: {e.read().decode('utf-8', 'replace')[:2000]}")


def _guardar(salida: Path, datos: bytes) -> Path:
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_bytes(datos)
    print(f"OK  {salida}  ({salida.stat().st_size / 1024:.0f} KB)")
    return salida


def _enviar_y_esperar(modelo: str, cuerpo: dict) -> dict:
    headers = {"Authorization": f"Key {obtener_key('FAL_KEY')}"}

    envio = _post_json(QUEUE_BASE.format(modelo=modelo), cuerpo, headers)
    request_id = envio.get("request_id")
    # Usar las URLs que devuelve la cola, no reconstruirlas: para modelos con id
    # anidado (ej. fal-ai/kling-video/v3/standard/...) la URL de status construida
    # a mano da 405 -- fal.ai resuelve el alias de app internamente y solo estas
    # URLs de la respuesta de envio son confiables.
    url_status = envio.get("status_url")
    url_result = envio.get("response_url")
    if not request_id or not url_status or not url_result:
        sys.exit(f"ERROR: la cola no devolvio request_id/status_url/response_url: {json.dumps(envio)[:2000]}")
    print(f"En cola (request_id={request_id})...")

    inicio = time.monotonic()
    ultimo_estado = None
    while True:
        if time.monotonic() - inicio > TIMEOUT_TOTAL_S:
            sys.exit(f"ERROR: timeout de {TIMEOUT_TOTAL_S}s esperando el video (request_id={request_id})")

        estado = _get_json(url_status, headers)
        status = estado.get("status")
        if status != ultimo_estado:
            extra = ""
            if status == "IN_QUEUE" and "queue_position" in estado:
                extra = f" (posicion {estado['queue_position']})"
            print(f"  estado: {status}{extra}")
            ultimo_estado = status

        if status == "COMPLETED":
            break
        if status in ("ERROR", "FAILED"):
            sys.exit(f"ERROR: la generacion fallo: {json.dumps(estado)[:2000]}")

        time.sleep(INTERVALO_SONDEO_S)

    return _get_json(url_result, headers)


def _descargar_video(resultado: dict, salida: Path) -> Path:
    video = resultado.get("video") or {}
    url = video.get("url")
    if not url:
        sys.exit(f"ERROR: la respuesta no trae video: {json.dumps(resultado)[:2000]}")
    with urllib.request.urlopen(url, timeout=300) as r:
        return _guardar(salida, r.read())


# ── Seedance 2.0 ────────────────────────────────────────────────────────────

def _generar_seedance(prompt, salida, imagen, anclas, duracion, resolucion, aspecto) -> Path:
    imagenes = [imagen, *anclas]
    if len(imagenes) > 9:
        sys.exit("ERROR: Seedance 2.0 acepta un maximo de 9 imagenes de referencia (--imagen + --ancla)")
    if resolucion not in RESOLUCIONES_SEEDANCE:
        sys.exit(f"ERROR: resolucion '{resolucion}' invalida. Usa una de: {', '.join(sorted(RESOLUCIONES_SEEDANCE))}")
    if aspecto not in ASPECTOS_SEEDANCE:
        sys.exit(f"ERROR: aspecto '{aspecto}' invalido para seedance. Usa uno de: {', '.join(sorted(ASPECTOS_SEEDANCE))}")

    cuerpo = {
        "prompt": prompt,
        "image_urls": [_data_uri(a) for a in imagenes],
        "duration": duracion,
        "resolution": resolucion,
        "aspect_ratio": aspecto,
        "generate_audio": False,
    }
    resultado = _enviar_y_esperar(MODELOS["seedance"], cuerpo)
    return _descargar_video(resultado, salida)


# ── Kling v3 ─────────────────────────────────────────────────────────────────

def _generar_kling(prompt, salida, imagen, anclas, duracion, negativo, cfg_scale) -> Path:
    cuerpo = {
        "start_image_url": _data_uri(imagen),
        "prompt": prompt,
        "duration": duracion,
        "generate_audio": False,
        "negative_prompt": negativo,
        "cfg_scale": cfg_scale,
    }
    if anclas:
        # Un elemento simple por ancla (una sola imagen de referencia cada uno).
        # Referenciarlos en el prompt de movimiento como @Element1, @Element2...
        cuerpo["elements"] = [{"frontal_image_url": _data_uri(a)} for a in anclas]

    resultado = _enviar_y_esperar(MODELOS["kling"], cuerpo)
    return _descargar_video(resultado, salida)


PROVEEDORES = {"seedance": _generar_seedance, "kling": _generar_kling}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--prompt", help="Prompt literal de movimiento")
    g.add_argument("--prompt-file", type=Path, help="Archivo de texto con el prompt de movimiento")
    p.add_argument("--salida", type=Path, required=True, help="MP4 de salida")
    p.add_argument("--proveedor", choices=sorted(PROVEEDORES), required=True)
    p.add_argument("--imagen", type=Path, required=True,
                   help="Keyframe/imagen de arranque ya aprobada (frame ancla del clip)")
    p.add_argument("--ancla", type=Path, action="append", default=[],
                   help="Imagen de referencia adicional de personaje (repetible)")
    p.add_argument("--duracion", default="5", help="Segundos del clip (string, ej. '5')")
    p.add_argument("--resolucion", default="720p", choices=sorted(RESOLUCIONES_SEEDANCE),
                   help="Solo seedance")
    p.add_argument("--aspecto", default="16:9", choices=sorted(ASPECTOS_SEEDANCE),
                   help="Solo seedance (en kling el aspecto lo define --imagen)")
    p.add_argument("--negativo", default="blur, distort, and low quality",
                   help="Solo kling: negative_prompt")
    p.add_argument("--cfg-scale", type=float, default=0.5, help="Solo kling: adherencia al prompt (0-1)")
    args = p.parse_args()

    if not args.imagen.exists():
        sys.exit(f"ERROR: --imagen {args.imagen} no existe")
    for a in args.ancla:
        if not a.exists():
            sys.exit(f"ERROR: el ancla {a} no existe")

    prompt = args.prompt if args.prompt else args.prompt_file.read_text(encoding="utf-8")

    if args.proveedor == "seedance":
        _generar_seedance(prompt, args.salida, args.imagen, args.ancla,
                          args.duracion, args.resolucion, args.aspecto)
    else:
        _generar_kling(prompt, args.salida, args.imagen, args.ancla,
                       args.duracion, args.negativo, args.cfg_scale)


if __name__ == "__main__":
    main()
