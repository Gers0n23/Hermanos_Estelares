"""Efectos de interfaz sintetizados en código (sin costo, sin APIs, 100% originales).

UX HE-40 R16 (03-Oct-2026, PROVISIONAL): la zona dormida del mapa sonaba con `no_es_este.ogg`, que
viene del `error_002` de Kenney. El GDD pide que un "todavía no" nunca suene feo. La auditoría pide
"unas campanitas de sueño, que calzan con los 'zzz' de la carita dormida".

Genera en assets/audio/sfx/ui/:
  zona_dormida.ogg   tres campanitas de cajita de música (mi-sol-mi), suaves y con eco, como un
                     arrullo. No bajan en seco ni zumban: dicen "shhh, está durmiendo".
  puf.ogg            (UX HE-60 m2) soplido de vela: aire suave y corto, sin tono grave. La vela de
                     Parejas se "va a dormir"; antes sonaba soltar.ogg a pitch 0,6 (se leía "wah-wah").
  fiuu.ogg           (UX HE-60 m2) silbidito agudo que baja apenas, muy suave: la racha se corta sin
                     sonido de error. Antes, soltar.ogg a pitch 0,75.
  blup.ogg           (UX HE-60 M1) burbuja alegre que sube: la barra del récord rebalsa.
  polvo.ogg          (lienzo §10.1) "¡puff!" de aterrizaje: golpecito blando y grave + soplido de polvo.
  polvo_boing.ogg    (lienzo §10.1, Maxi) aterrizaje gracioso: "boing" de resorte que tiembla + polvo.
  chisporroteo.ogg   (lienzo §10.2) el sol se quema fuera del cielo: chispitas crepitantes, cortas y suaves.
  rebobinar.ogg      (lienzo §10.3) deshacer: "bwip" que sube rapido, como rebobinar una cinta.
  fuuush.ogg         (lienzo §10.4) la escoba barre la hoja: soplido que sube y baja.
  estrella_vuela.ogg (intro, Beat 5) una estrella de poder cruza volando: brillo que sube + campanita.
  transformacion.ogg (intro, Beat 5) el traje se arma sobre el niño: escalera de campanitas que sube
                     con un brillo de aire, ~1,8 s (lo que dura el barrido de luz de pies a cabeza).
  fanfarria_trajes.ogg (intro, Beat 5) "¡ta-chán!" de los tres con traje: acorde mayor brillante.

Uso:  python herramientas/componer_sfx_ui.py            (solo escribe los que faltan)
      python herramientas/componer_sfx_ui.py --forzar   (reescribe todos)
"""
import sys
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


def sfx_puf() -> np.ndarray:
    """Soplido: ruido blanco filtrado (paso bajo de un polo) con ataque corto y caída suave."""
    rng = np.random.default_rng(7)
    n = int(0.42 * FS)
    t = np.arange(n) / FS
    ruido = rng.standard_normal(n)
    filtrado = np.zeros(n)
    k = 0.12
    for i in range(1, n):
        filtrado[i] = filtrado[i - 1] + k * (ruido[i] - filtrado[i - 1])
    env = np.minimum(1.0, t / 0.025) * np.exp(-t / 0.11)
    pista = filtrado * env
    return pista / np.max(np.abs(pista)) * 0.32


def sfx_fiuu() -> np.ndarray:
    """Silbidito: seno que baja una cuarta (la6 -> mi6) en registro agudo, con vibrato leve."""
    n = int(0.34 * FS)
    t = np.arange(n) / FS
    midi = 93 - 5 * (t / t[-1]) ** 0.8
    f = 440.0 * 2 ** ((midi - 69) / 12) * (1.0 + 0.004 * np.sin(2 * np.pi * 7.0 * t))
    fase = 2 * np.pi * np.cumsum(f) / FS
    env = np.minimum(1.0, t / 0.03) * np.exp(-t / 0.16)
    cola = int(0.03 * FS)
    env[-cola:] *= np.linspace(1, 0, cola)
    return np.sin(fase) * env * 0.26


def sfx_blup() -> np.ndarray:
    """Burbuja: seno que sube rápido (sol4 -> si5) y se apaga corto, como una pompa que revienta."""
    n = int(0.16 * FS)
    t = np.arange(n) / FS
    midi = 67 + 16 * (1.0 - np.exp(-t / 0.035))
    f = 440.0 * 2 ** ((midi - 69) / 12)
    fase = 2 * np.pi * np.cumsum(f) / FS
    env = np.minimum(1.0, t / 0.004) * np.exp(-t / 0.05)
    return np.sin(fase) * env * 0.4


def _soplido(segundos: float, k: float, semilla: int) -> np.ndarray:
    rng = np.random.default_rng(semilla)
    n = int(segundos * FS)
    ruido = rng.standard_normal(n)
    filtrado = np.zeros(n)
    for i in range(1, n):
        filtrado[i] = filtrado[i - 1] + k * (ruido[i] - filtrado[i - 1])
    return filtrado / np.max(np.abs(filtrado))


def sfx_polvo() -> np.ndarray:
    """Golpecito blando (seno que cae 180 -> 70 Hz) mas un soplido corto de polvo."""
    n = int(0.45 * FS)
    t = np.arange(n) / FS
    f = 70 + 110 * np.exp(-t / 0.03)
    golpe = np.sin(2 * np.pi * np.cumsum(f) / FS) * np.exp(-t / 0.06)
    polvo = _soplido(0.45, 0.18, 11) * np.minimum(1.0, t / 0.02) * np.exp(-t / 0.12)
    pista = 0.9 * golpe + 0.6 * polvo
    return pista / np.max(np.abs(pista)) * 0.45


def sfx_polvo_boing() -> np.ndarray:
    """Boing de resorte: tono que baja con vibrato ancho que se calma, y polvo al final."""
    n = int(0.7 * FS)
    t = np.arange(n) / FS
    midi = 62 - 10 * (t / t[-1]) + 1.6 * np.sin(2 * np.pi * 11.0 * t) * np.exp(-t / 0.25)
    f = 440.0 * 2 ** ((midi - 69) / 12)
    boing = np.sin(2 * np.pi * np.cumsum(f) / FS) * np.minimum(1.0, t / 0.01) * np.exp(-t / 0.22)
    polvo = np.zeros(n)
    base = sfx_polvo()
    polvo[: len(base)] = base[: n]
    pista = 0.75 * boing + 0.8 * polvo
    return pista / np.max(np.abs(pista)) * 0.45


def sfx_chisporroteo() -> np.ndarray:
    """Chispitas: clics de ruido muy cortos al azar sobre un siseo suave que se apaga."""
    rng = np.random.default_rng(5)
    n = int(0.6 * FS)
    t = np.arange(n) / FS
    siseo = rng.standard_normal(n)
    siseo = np.diff(np.concatenate([[0.0], siseo])) * 0.25 * np.exp(-t / 0.25)
    clics = np.zeros(n)
    for _ in range(26):
        i = int(rng.uniform(0, 0.5) * FS)
        largo = int(0.004 * FS)
        clics[i: i + largo] += rng.standard_normal(min(largo, n - i)) * np.exp(-np.arange(min(largo, n - i)) / 40.0) * rng.uniform(0.4, 1.0)
    pista = siseo + clics
    cola = int(0.05 * FS)
    pista[-cola:] *= np.linspace(1, 0, cola)
    return pista / np.max(np.abs(pista)) * 0.35


def sfx_rebobinar() -> np.ndarray:
    """Bwip: seno que sube una octava muy rapido, con un eco cortito."""
    n = int(0.22 * FS)
    t = np.arange(n) / FS
    midi = 72 + 12 * (t / 0.12).clip(0, 1) ** 0.7
    f = 440.0 * 2 ** ((midi - 69) / 12)
    tono = np.sin(2 * np.pi * np.cumsum(f) / FS) * np.minimum(1.0, t / 0.006) * np.exp(-t / 0.07)
    eco = int(0.06 * FS)
    tono[eco:] += 0.3 * tono[:-eco].copy()
    return tono / np.max(np.abs(tono)) * 0.32


def sfx_fuuush() -> np.ndarray:
    """Soplido de escoba: ruido cuyo filtro se abre y se cierra (fuu-uush), 0,7 s."""
    rng = np.random.default_rng(3)
    n = int(0.7 * FS)
    t = np.arange(n) / FS
    ruido = rng.standard_normal(n)
    k = 0.04 + 0.3 * np.sin(np.pi * t / t[-1]) ** 2
    filtrado = np.zeros(n)
    for i in range(1, n):
        filtrado[i] = filtrado[i - 1] + k[i] * (ruido[i] - filtrado[i - 1])
    env = np.sin(np.pi * t / t[-1]) ** 1.5
    pista = filtrado * env
    return pista / np.max(np.abs(pista)) * 0.38


def _brillo(segundos: float, desde: float, hasta: float, semilla: int) -> np.ndarray:
    """Aire agudo filtrado que sube de brillo (pasa-bajos que se abre de `desde` a `hasta`)."""
    n = int(segundos * FS)
    t = np.arange(n) / FS
    ruido = np.random.default_rng(semilla).normal(0, 1, n)
    corte = np.linspace(desde, hasta, n)
    k = 1 - np.exp(-2 * np.pi * corte / FS)
    filtrado = np.zeros(n)
    for i in range(1, n):
        filtrado[i] = filtrado[i - 1] + k[i] * (ruido[i] - filtrado[i - 1])
    agudo = ruido - filtrado  # nos quedamos con lo agudo: "shhhiiing"
    return agudo * np.sin(np.pi * t / t[-1]) ** 2


def _mezclar(largo: float, piezas: list[tuple[np.ndarray, float, float]]) -> np.ndarray:
    pista = np.zeros(int(largo * FS))
    for sonido, inicio, vol in piezas:
        i = int(inicio * FS)
        fin = min(len(pista), i + len(sonido))
        pista[i:fin] += vol * sonido[: fin - i]
    return pista


def sfx_estrella_vuela() -> np.ndarray:
    piezas = [(_brillo(0.6, 9000, 2500, 11), 0.0, 0.25)]
    piezas += [(campanita(m, 0.6), 0.08 * i + 0.1, 0.5) for i, m in enumerate([84, 88, 91])]
    pista = _mezclar(0.9, piezas)
    return pista / np.max(np.abs(pista)) * 0.42


def sfx_transformacion() -> np.ndarray:
    escala = [72, 74, 76, 79, 81, 84, 86, 88, 91, 93, 96, 98]  # pentatónica que sube
    piezas = [(_brillo(1.7, 8000, 1500, 7), 0.0, 0.35)]
    piezas += [(campanita(m, 0.9), 0.12 * i, 0.55) for i, m in enumerate(escala)]
    piezas += [(campanita(m, 1.4), 1.45, 0.5) for m in (84, 88, 91)]  # ¡listo!: acorde final
    pista = _mezclar(2.6, piezas)
    eco = int(0.09 * FS)
    pista[eco:] += 0.25 * pista[:-eco].copy()
    cola = int(0.3 * FS)
    pista[-cola:] *= np.linspace(1, 0, cola)
    return pista / np.max(np.abs(pista)) * 0.5


def _metal(midi: float, segundos: float) -> np.ndarray:
    """Tono de fanfarria suave (armónicos impares que se abren), sin estridencia."""
    n = int(segundos * FS)
    t = np.arange(n) / FS
    f = frecuencia(midi)
    apertura = np.minimum(1.0, t / 0.08)
    tono = sum((apertura ** (h / 3)) * np.sin(2 * np.pi * f * h * t) / h for h in (1, 2, 3, 4, 5))
    env = np.minimum(1.0, t / 0.02) * np.exp(-t / 0.9)
    return tono * env


def sfx_fanfarria_trajes() -> np.ndarray:
    piezas = [(_metal(m, 0.25), 0.13 * i, 0.5) for i, m in enumerate([67, 72, 76])]  # sol-do-mi
    piezas += [(_metal(m, 1.8), 0.42, 0.45) for m in (72, 76, 79, 84)]               # ¡do mayor!
    piezas += [(campanita(m, 1.3), 0.42 + 0.06 * i, 0.4) for i, m in enumerate([88, 91, 96])]
    piezas += [(_brillo(1.2, 9000, 3000, 5), 0.4, 0.2)]
    pista = _mezclar(2.5, piezas)
    cola = int(0.4 * FS)
    pista[-cola:] *= np.linspace(1, 0, cola)
    return pista / np.max(np.abs(pista)) * 0.5


EFECTOS = {
    "zona_dormida.ogg": sfx_zona_dormida,
    "puf.ogg": sfx_puf,
    "fiuu.ogg": sfx_fiuu,
    "blup.ogg": sfx_blup,
    "polvo.ogg": sfx_polvo,
    "polvo_boing.ogg": sfx_polvo_boing,
    "chisporroteo.ogg": sfx_chisporroteo,
    "rebobinar.ogg": sfx_rebobinar,
    "fuuush.ogg": sfx_fuuush,
    "estrella_vuela.ogg": sfx_estrella_vuela,
    "transformacion.ogg": sfx_transformacion,
    "fanfarria_trajes.ogg": sfx_fanfarria_trajes,
}


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    forzar = "--forzar" in sys.argv
    for nombre, generar in EFECTOS.items():
        ruta = SALIDA / nombre
        if ruta.exists() and not forzar:
            continue
        escribir_ogg(ruta, generar())
        print(f"escrito assets/audio/sfx/ui/{nombre}")


if __name__ == "__main__":
    main()
