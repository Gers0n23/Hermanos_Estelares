#!/usr/bin/env python3
"""Genera imágenes para los assets de Los Hermanos Estelares.

Proveedor por defecto: **fal.ai / FLUX.2** (decisión del PO, 06-Ago-2026 — ver
docs/stack-tecnico.md, tabla de decisiones). Soporta también Gemini por si hace
falta comparar o para casos puntuales (Veo 3.1, cinemáticas, sigue usando la
misma GEMINI_API_KEY por separado).

    fal    -> FLUX.2 [pro] via fal.ai          (hasta 9 anclas de referencia)
    gemini -> Nano Banana Pro / Gemini Image   (proveedor anterior, en desuso para arte)

Las keys se leen de `.env` (o de la variable de entorno). Ver herramientas/config.py.

Uso:
    python herramientas/generar_imagen.py \\
        --prompt-file assets/prompts/<algo>.txt \\
        --salida assets/generadas/<algo>.png \\
        --aspecto 3:4 --proveedor fal \\
        --ancla assets/anclas/hermanosestelares.jpeg

El prompt puede venir de --prompt-file o de --prompt. Se pueden pasar varias
--ancla (imágenes de referencia de las que el modelo hereda el estilo).
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import mimetypes
import sys
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import obtener_key  # noqa: E402

MODELOS = {
    "gemini": {
        # Nano Banana Pro: 1K y 2K cuestan lo mismo ($0,134), asi que siempre 2K.
        "pro": "gemini-3-pro-image",
        # Solo conviene a 1K ($0,067); a 2K casi no ahorra.
        "flash": "gemini-3.1-flash-image",
    },
    # Solo se lista lo verificado contra el OpenAPI de fal. Otros modelos de la
    # familia (max, flex, klein) existen pero no se han comprobado aqui.
    "fal": {"pro": "fal-ai/flux-2-pro"},
    # Inpainting con mascara: el negro se preserva pixel a pixel y solo se regenera el
    # blanco. Util para retocar una sola zona (p. ej. limpiar un parche puntual) sin
    # regenerar toda la imagen.
    "fal-fill": {"pro": "fal-ai/flux-pro/v1/fill"},
    # GPT Image 2 tambien admite mascara y sigue instrucciones bastante mejor que FLUX.
    # Ojo con la polaridad: aqui lo TRANSPARENTE es lo que se repinta, al reves que en
    # FLUX Fill. La conversion la hace la herramienta, se le pasa la misma mascara.
    "fal-gpt2": {"pro": "openai/gpt-image-2/edit"},
    # Nano Banana Pro servido por fal, pagado por fal en vez de facturacion directa de
    # Google. No acepta mascara.
    "fal-nano": {"pro": "fal-ai/nano-banana-pro/edit"},
}

ENDPOINT_GEMINI = "https://generativelanguage.googleapis.com/v1beta/models/{modelo}:generateContent"
ENDPOINT_FAL = "https://fal.run/{modelo}"

ASPECTOS = {"1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"}
TAMANOS = {"1K", "2K", "4K"}

# FLUX.2 cobra por megapixel, asi que se apunta a ~1 MP (la tarifa base de $0,03).
# Los assets finales no pasan de 1080 px, de modo que 1 MP sobra. Dimensiones
# multiplos de 32, que es lo que prefieren los modelos de difusion.
DIMENSIONES_FAL = {
    "1:1": (1024, 1024),
    "3:4": (864, 1152),
    "4:3": (1152, 864),
    "2:3": (832, 1248),
    "3:2": (1248, 832),
    "4:5": (896, 1120),
    "5:4": (1120, 896),
    "9:16": (768, 1344),
    "16:9": (1344, 768),
    "21:9": (1536, 640),
}


def _data_uri(ruta: Path) -> str:
    mime = mimetypes.guess_type(ruta.name)[0] or "image/png"
    return f"data:{mime};base64,{base64.b64encode(ruta.read_bytes()).decode('ascii')}"


def _post(url: str, cuerpo: dict, headers: dict) -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(cuerpo).encode("utf-8"),
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"ERROR HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:2000]}")


def _guardar(salida: Path, datos: bytes) -> Path:
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_bytes(datos)
    print(f"OK  {salida}  ({salida.stat().st_size / 1024:.0f} KB)")
    return salida


# ── Gemini ────────────────────────────────────────────────────────────────────

def _generar_gemini(prompt, salida, anclas, modelo, aspecto, tamano) -> Path:
    # Las anclas van ANTES del texto: el modelo las trata como el estilo a heredar
    # y el texto como la instruccion sobre ellas.
    partes: list[dict] = []
    for a in anclas:
        mime = mimetypes.guess_type(a.name)[0] or "image/png"
        partes.append({"inline_data": {
            "mime_type": mime,
            "data": base64.b64encode(a.read_bytes()).decode("ascii"),
        }})
    partes.append({"text": prompt})

    payload = _post(
        ENDPOINT_GEMINI.format(modelo=MODELOS["gemini"][modelo]),
        {
            "contents": [{"parts": partes}],
            "generationConfig": {
                "responseModalities": ["IMAGE"],
                "imageConfig": {"aspectRatio": aspecto, "imageSize": tamano},
            },
        },
        {"x-goog-api-key": obtener_key("GEMINI_API_KEY")},
    )

    candidatos = payload.get("candidates") or []
    if not candidatos:
        sys.exit(f"ERROR: respuesta sin candidatos: {json.dumps(payload)[:2000]}")

    # El modelo puede devolver texto (una negativa o aclaracion) mezclado con la
    # imagen; se recorren todas las partes y se toma la primera imagen.
    for parte in candidatos[0].get("content", {}).get("parts", []):
        blob = parte.get("inlineData") or parte.get("inline_data")
        if blob and blob.get("data"):
            return _guardar(salida, base64.b64decode(blob["data"]))

    texto = " ".join(p.get("text", "") for p in candidatos[0].get("content", {}).get("parts", []))
    sys.exit(f"ERROR: no vino imagen (finishReason={candidatos[0].get('finishReason','?')}). "
             f"Texto: {texto[:1000]}")


# ── fal.ai / FLUX.2 ───────────────────────────────────────────────────────────

def _generar_fal(prompt, salida, anclas, modelo, aspecto, _tamano) -> Path:
    endpoint = MODELOS["fal"][modelo]
    ancho, alto = DIMENSIONES_FAL[aspecto]

    cuerpo = {
        "prompt": prompt,
        "image_size": {"width": ancho, "height": alto},
        "output_format": "png",
        # Devuelve la imagen como data URI en la misma respuesta, evitando una
        # segunda descarga (y que el enlace temporal expire).
        "sync_mode": True,
    }

    if anclas:
        # El endpoint /edit es el que acepta imagenes de referencia (hasta 9).
        endpoint += "/edit"
        cuerpo["image_urls"] = [_data_uri(a) for a in anclas]

    payload = _post(
        ENDPOINT_FAL.format(modelo=endpoint),
        cuerpo,
        {"Authorization": f"Key {obtener_key('FAL_KEY')}"},
    )

    imagenes = payload.get("images") or []
    if not imagenes or not imagenes[0].get("url"):
        sys.exit(f"ERROR: respuesta sin imagen: {json.dumps(payload)[:2000]}")

    url = imagenes[0]["url"]
    if url.startswith("data:"):
        return _guardar(salida, base64.b64decode(url.split(",", 1)[1]))

    with urllib.request.urlopen(url, timeout=300) as r:  # sync_mode desactivado
        return _guardar(salida, r.read())


def _generar_fal_fill(prompt, salida, anclas, modelo, _aspecto, _tamano, mascara) -> Path:
    """Inpainting: se repinta solo la zona blanca de la mascara."""
    if len(anclas) != 1:
        sys.exit("ERROR: fal-fill necesita exactamente una --ancla (la imagen base)")
    if mascara is None:
        sys.exit("ERROR: fal-fill necesita --mascara")

    base, masc = Image.open(anclas[0]).size, Image.open(mascara).size
    if base != masc:
        sys.exit(f"ERROR: la mascara {masc} no coincide con la imagen base {base}")

    payload = _post(
        ENDPOINT_FAL.format(modelo=MODELOS["fal-fill"][modelo]),
        {
            "prompt": prompt,
            "image_url": _data_uri(anclas[0]),
            "mask_url": _data_uri(mascara),
            "output_format": "png",
            "sync_mode": True,
        },
        {"Authorization": f"Key {obtener_key('FAL_KEY')}"},
    )

    imagenes = payload.get("images") or []
    if not imagenes or not imagenes[0].get("url"):
        sys.exit(f"ERROR: respuesta sin imagen: {json.dumps(payload)[:2000]}")

    url = imagenes[0]["url"]
    if url.startswith("data:"):
        return _guardar(salida, base64.b64decode(url.split(",", 1)[1]))
    with urllib.request.urlopen(url, timeout=300) as r:
        return _guardar(salida, r.read())


def _mascara_a_alfa(mascara: Path) -> str:
    """Pasa una mascara blanco=repintar al formato de OpenAI, donde repinta lo transparente."""
    m = Image.open(mascara).convert("L")
    rgba = Image.new("RGBA", m.size, (0, 0, 0, 255))
    rgba.putalpha(Image.eval(m, lambda v: 255 - v))
    buf = io.BytesIO()
    rgba.save(buf, format="PNG")
    return f"data:image/png;base64,{base64.b64encode(buf.getvalue()).decode('ascii')}"


_CALIDAD_GPT2 = "high"


def _generar_fal_gpt2(prompt, salida, anclas, modelo, _aspecto, _tamano, mascara) -> Path:
    if not anclas:
        sys.exit("ERROR: fal-gpt2 necesita al menos una --ancla")
    cuerpo = {
        "prompt": prompt,
        "image_urls": [_data_uri(a) for a in anclas],
        "quality": _CALIDAD_GPT2,
        "output_format": "png",
        "sync_mode": True,
    }
    if mascara:
        cuerpo["mask_url"] = _mascara_a_alfa(mascara)
    return _recoger_imagen(MODELOS["fal-gpt2"][modelo], cuerpo, salida)


def _generar_fal_nano(prompt, salida, anclas, modelo, aspecto, _tamano) -> Path:
    if not anclas:
        sys.exit("ERROR: fal-nano necesita al menos una --ancla")
    return _recoger_imagen(MODELOS["fal-nano"][modelo], {
        "prompt": prompt,
        "image_urls": [_data_uri(a) for a in anclas],
        "aspect_ratio": aspecto,
        "resolution": "2K",
        "output_format": "png",
        "sync_mode": True,
    }, salida)


def _recoger_imagen(endpoint: str, cuerpo: dict, salida: Path) -> Path:
    payload = _post(ENDPOINT_FAL.format(modelo=endpoint), cuerpo,
                    {"Authorization": f"Key {obtener_key('FAL_KEY')}"})
    imagenes = payload.get("images") or []
    if not imagenes or not imagenes[0].get("url"):
        sys.exit(f"ERROR: respuesta sin imagen: {json.dumps(payload)[:2000]}")
    url = imagenes[0]["url"]
    if url.startswith("data:"):
        return _guardar(salida, base64.b64decode(url.split(",", 1)[1]))
    with urllib.request.urlopen(url, timeout=300) as r:
        return _guardar(salida, r.read())


PROVEEDORES = {
    "gemini": _generar_gemini,
    "fal": _generar_fal,
    "fal-fill": _generar_fal_fill,
    "fal-gpt2": _generar_fal_gpt2,
    "fal-nano": _generar_fal_nano,
}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--prompt", help="Prompt literal")
    g.add_argument("--prompt-file", type=Path, help="Archivo de texto con el prompt")
    p.add_argument("--salida", type=Path, required=True, help="PNG de salida")
    p.add_argument("--ancla", type=Path, action="append", default=[],
                   help="Imagen de referencia (repetible, hasta 9 en fal)")
    p.add_argument("--calidad", choices=["low", "medium", "high"], default="high",
                   help="Solo fal-gpt2: high ~$0,15-0,22; medium ~$0,06; low ~$0,015")
    p.add_argument("--mascara", type=Path,
                   help="Solo fal-fill/fal-gpt2: PNG donde el blanco marca lo que se repinta")
    p.add_argument("--proveedor", choices=sorted(PROVEEDORES), default="fal")
    p.add_argument("--modelo", default="pro")
    p.add_argument("--aspecto", default="1:1", help=f"Uno de: {', '.join(sorted(ASPECTOS))}")
    p.add_argument("--tamano", default="2K", choices=sorted(TAMANOS),
                   help="Solo aplica a gemini; en fal el tamano sale del aspecto (~1 MP)")
    args = p.parse_args()

    if args.aspecto not in ASPECTOS:
        sys.exit(f"ERROR: aspecto '{args.aspecto}' no soportado. "
                 f"Usa uno de: {', '.join(sorted(ASPECTOS))}")
    if args.modelo not in MODELOS[args.proveedor]:
        sys.exit(f"ERROR: modelo '{args.modelo}' no existe para {args.proveedor}. "
                 f"Opciones: {', '.join(sorted(MODELOS[args.proveedor]))}")
    if args.proveedor == "fal" and len(args.ancla) > 9:
        sys.exit("ERROR: FLUX.2 acepta un maximo de 9 imagenes de referencia")

    for a in args.ancla:
        if not a.exists():
            sys.exit(f"ERROR: el ancla {a} no existe")

    if args.mascara and not args.mascara.exists():
        sys.exit(f"ERROR: la mascara {args.mascara} no existe")

    globals()['_CALIDAD_GPT2'] = args.calidad
    prompt = args.prompt if args.prompt else args.prompt_file.read_text(encoding="utf-8")

    if args.proveedor in ("fal-fill", "fal-gpt2"):
        PROVEEDORES[args.proveedor](prompt, args.salida, args.ancla, args.modelo,
                                    args.aspecto, args.tamano, args.mascara)
    else:
        PROVEEDORES[args.proveedor](
            prompt, args.salida, args.ancla, args.modelo, args.aspecto, args.tamano
        )


if __name__ == "__main__":
    main()
