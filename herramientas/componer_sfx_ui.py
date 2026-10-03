"""Efectos de interfaz sintetizados en código (sin costo, sin APIs, 100% originales).

UX HE-40 R16 (03-Oct-2026, PROVISIONAL): la zona dormida del mapa sonaba con `no_es_este.ogg`, que
viene del `error_002` de Kenney. El GDD pide que un "todavía no" nunca suene feo. La auditoría pide
"unas campanitas de sueño, que calzan con los 'zzz' de la carita dormida".

Genera en assets/audio/sfx/ui/:
  zona_dormida.ogg   tres campanitas de cajita de música (mi-sol-mi), suaves y con eco, como un
                     arrullo. No bajan en seco ni zumban: dicen "shhh, está durmiendo".

Uso:  python herramientas/componer_sfx_ui.py
"""
from pathlib import Path

import numpy as np

from componer_chiptune import FS, escribir_ogg, frecuencia

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets" / "audio" / "sfx" / "ui"


def campanita(midi: float, segundos: float) -> np.ndarray:
    """Seno con un parcial inarmónico suave (cajita de música) y caída exponencial larga."""
    n = int(segundos * FS)
    t = np.arange(n) / FS
    f = frecuencia(midi)
    vibrato = 1.0 + 0.003 * np.sin(2 * np.pi * 5.0 * t)
    tono = np.sin(2 * np.pi * f * t * vibrato) + 0.25 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t / 0.08)
    ataque = np.minimum(1.0, t / 0.006)
    return tono * ataque * np.exp(-t / 0.35)


def sfx_zona_dormida() -> np.ndarray:
    notas = [(76, 0.0), (79, 0.16), (76, 0.32)]  # mi5 - sol5 - mi5: arrullo, no "error"
    largo = int(1.3 * FS)
    pista = np.zeros(largo)
    for midi, inicio in notas:
        nota = campanita(midi, 1.0) * (0.8 if midi == 79 else 1.0)
        i = int(inicio * FS)
        fin = min(largo, i + len(nota))
        pista[i:fin] += nota[: fin - i]
    # eco cortito y suave, como en una pieza dormida
    eco = int(0.12 * FS)
    pista[eco:] += 0.3 * pista[:-eco].copy()
    cola = int(0.05 * FS)
    pista[-cola:] *= np.linspace(1, 0, cola)
    return pista / np.max(np.abs(pista)) * 0.45


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    escribir_ogg(SALIDA / "zona_dormida.ogg", sfx_zona_dormida())
    print("escrito assets/audio/sfx/ui/zona_dormida.ogg")


if __name__ == "__main__":
    main()
