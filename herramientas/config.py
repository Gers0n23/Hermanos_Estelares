"""Lectura de credenciales para las herramientas de generación de assets.

Orden de precedencia:
  1. Variable de entorno (permite sobrescribir puntualmente sin tocar archivos)
  2. Archivo `.env` en la raíz del repo (ignorado por git)
"""

from __future__ import annotations

import os
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ARCHIVO_ENV = RAIZ / ".env"


def _leer_env() -> dict[str, str]:
    """Parsea el .env. Formato CLAVE=valor, una por línea; # inicia comentario."""
    if not ARCHIVO_ENV.exists():
        return {}

    valores: dict[str, str] = {}
    for linea in ARCHIVO_ENV.read_text(encoding="utf-8").splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#") or "=" not in linea:
            continue
        clave, _, valor = linea.partition("=")
        # Se quitan comillas por si se pegó la key entrecomillada.
        valores[clave.strip()] = valor.strip().strip("\"'")
    return valores


def obtener_key(nombre: str) -> str:
    """Devuelve la credencial [nombre] o termina con un mensaje accionable."""
    valor = os.environ.get(nombre) or _leer_env().get(nombre, "")

    # El placeholder del .env de ejemplo no cuenta como key configurada.
    if valor and not valor.upper().startswith("PEGA_"):
        return valor

    raise SystemExit(
        f"ERROR: falta la credencial {nombre}.\n"
        f"  Edita {ARCHIVO_ENV} y reemplaza el placeholder por tu key.\n"
        f"  (ese archivo esta en .gitignore, no se sube al repo)"
    )
