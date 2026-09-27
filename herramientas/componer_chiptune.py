"""Música chiptune (estilo consola de 8 bits) del viaje estelar, compuesta y sintetizada
en código: sin costo, sin APIs y 100% original (pedido del PO 27-Sep-2026: "falta música
pixel art para acompañar el viaje").

Genera en assets/audio/musica/:
  viaje_estelar.ogg      loop de 24 compases a 132 bpm (~44 s), empalme sin corte
  llegada_planeta.ogg    fanfarria corta del aterrizaje (~3 s)

Voces (como una consola clásica): pulso 25 % = melodía, pulso 12,5 % = arpegios,
triángulo = bajo, ruido = batería suave. Tonalidad de Do mayor, alegre y sin
disonancias; volumen contenido para que la voz de Cometa se escuche encima.

Uso:  python herramientas/componer_chiptune.py
"""
from pathlib import Path

import numpy as np
import soundfile as sf

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets" / "audio" / "musica"
FS = 32000
BPM = 132
OCTAVO = 60.0 / BPM / 2  # duración de una corchea

# --- partitura ---------------------------------------------------------------------
# Cada compás = 8 corcheas; número = nota MIDI, "-" = mantener, "." = silencio.
MELODIA = [
    # A: C G Am F | C G F G
    "72 76 79 76 84 - 79 -", "79 81 83 81 79 - 74 -", "76 - 72 76 81 - 79 76", "77 - 81 - 79 77 76 74",
    "72 76 79 76 84 - 83 84", "86 - 83 - 79 - 81 83", "84 - 81 77 79 - 76 74", "74 76 77 79 - - . .",
    # A': C G Am F | C G F C
    "72 76 79 76 84 - 79 -", "79 81 83 81 79 - 74 -", "76 - 72 76 81 - 79 76", "77 - 81 - 79 77 76 74",
    "72 76 79 76 84 - 83 84", "86 - 83 - 79 - 81 83", "84 - 81 77 79 - 74 -", "72 - - - . . 79 81",
    # B: F G Em Am | F G C G
    "81 - 77 - 81 84 81 77", "79 - 83 - 86 - 83 79", "76 - 79 - 83 - 79 76", "81 - 76 - 72 76 81 -",
    "77 81 84 81 77 - 81 -", "79 83 86 83 79 - 86 -", "84 - 79 - 76 - 79 -", "83 - 86 - 79 - 74 -",
]
ACORDES = ("C G Am F C G F G " "C G Am F C G F C " "F G Em Am F G C G").split()
TONOS = {"C": [0, 4, 7], "G": [7, 11, 14], "Am": [9, 12, 16], "F": [5, 9, 12], "Em": [4, 7, 11]}
RAIZ_BAJO = {"C": 36, "G": 43, "Am": 45, "F": 41, "Em": 40}


def frecuencia(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


def envolvente(n: int, ataque=0.004, caida=0.08, sostén=0.7, relajo=0.03) -> np.ndarray:
    t = np.arange(n) / FS
    env = np.minimum(1.0, t / ataque)
    env *= sostén + (1 - sostén) * np.exp(-t / caida)
    cola = int(relajo * FS)
    if n > cola:
        env[-cola:] *= np.linspace(1, 0, cola)
    return env


def pulso(midi, n, ciclo, vibrato=0.0):
    t = np.arange(n) / FS
    f = frecuencia(midi) * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.25 - 0.4, 0, 1))
    fase = np.cumsum(f) / FS
    return np.where(np.mod(fase, 1.0) < ciclo, 1.0, -1.0)


def triangulo(midi, n):
    fase = np.mod(np.arange(n) * frecuencia(midi) / FS, 1.0)
    onda = 4 * np.abs(fase - 0.5) - 1
    return np.round(onda * 8) / 8  # escalones de 4 bits, como el triángulo de una consola


def ruido(n, semilla, filtro=0.0):
    r = np.random.default_rng(semilla).choice([-1.0, 1.0], n)
    if filtro > 0:  # ruido más "sordo" para el bombo/caja
        for i in range(1, n):
            r[i] = r[i - 1] * filtro + r[i] * (1 - filtro)
    return r


def poner(pista, inicio, sonido):
    """Suma `sonido` en la pista circular (lo que se pasa del final vuelve al inicio:
    así el loop empalma sin corte)."""
    n = len(pista)
    fin = inicio + len(sonido)
    if fin <= n:
        pista[inicio:fin] += sonido
    else:
        corte = n - inicio
        pista[inicio:] += sonido[:corte]
        pista[: fin - n] += sonido[corte:]


def notas_de(compas: str):
    """[(paso, nota, duración_en_pasos)] a partir de '72 - 76 . ...'."""
    tokens = compas.split()
    notas = []
    for i, tk in enumerate(tokens):
        if tk in "-.":
            continue
        dur = 1
        while i + dur < len(tokens) and tokens[i + dur] == "-":
            dur += 1
        notas.append((i, int(tk), dur))
    return notas


def componer_loop() -> np.ndarray:
    pasos = len(MELODIA) * 8
    n = int(round(pasos * OCTAVO * FS))
    pista = np.zeros(n)
    muestra = lambda paso: int(round(paso * OCTAVO * FS))
    for c, (compas, acorde) in enumerate(zip(MELODIA, ACORDES)):
        base = c * 8
        # melodía (pulso 25 %), un pelín de vibrato en las notas largas
        for paso, nota, dur in notas_de(compas):
            largo = muestra(dur) - int(0.02 * FS)
            poner(pista, muestra(base + paso), 0.22 * pulso(nota, largo, 0.25, 0.006) * envolvente(largo))
        # arpegio en semicorcheas (pulso 12,5 %), bajito
        tonos = TONOS[acorde]
        for s in range(16):
            nota = 60 + tonos[s % 3] + (12 if s % 6 >= 3 else 0)
            largo = muestra(0.5) - int(0.01 * FS)
            poner(pista, muestra(base + s * 0.5), 0.06 * pulso(nota, largo, 0.125) * envolvente(largo, caida=0.03, sostén=0.3))
        # bajo (triángulo): raíz, octava, quinta
        r = RAIZ_BAJO[acorde]
        for paso, nota in enumerate([r, None, r + 12, None, r + 7, None, r + 12, r]):
            if nota is None:
                continue
            largo = muestra(1.6 if paso % 2 == 0 else 0.9)
            poner(pista, muestra(base + paso), 0.30 * triangulo(nota, largo) * envolvente(largo, caida=0.12, sostén=0.6))
        # batería suave: bombo en 1 y 3, caja en 2 y 4, platillito en cada corchea
        for paso in range(8):
            inicio = muestra(base + paso)
            if paso in (0, 4):
                largo = int(0.12 * FS)
                t = np.arange(largo) / FS
                bombo = np.sin(2 * np.pi * np.cumsum(150 * np.exp(-t * 30) + 45) / FS)
                poner(pista, inicio, 0.35 * bombo * np.exp(-t * 22))
            if paso in (2, 6):
                largo = int(0.1 * FS)
                poner(pista, inicio, 0.10 * ruido(largo, c * 8 + paso, 0.5) * np.exp(-np.arange(largo) / FS * 30))
            largo = int(0.03 * FS)
            poner(pista, inicio, (0.035 if paso % 2 else 0.05) * ruido(largo, 99 + paso) * np.exp(-np.arange(largo) / FS * 120))
    return pista


def componer_llegada() -> np.ndarray:
    n = int(3.2 * FS)
    pista = np.zeros(n + FS)
    muestra = lambda seg: int(seg * FS)
    # arpegio que sube y acorde final con redoble
    for i, nota in enumerate([72, 76, 79, 84, 88]):
        largo = muestra(0.13)
        pista[muestra(i * 0.12): muestra(i * 0.12) + largo] += 0.22 * pulso(nota, largo, 0.25) * envolvente(largo)
    inicio = muestra(0.62)
    largo = muestra(2.2)
    for nota, ciclo, vol in [(84, 0.25, 0.2), (88, 0.125, 0.1), (91, 0.5, 0.08)]:
        pista[inicio: inicio + largo] += vol * pulso(nota, largo, ciclo, 0.01) * envolvente(largo, caida=0.6, sostén=0.5, relajo=0.8)
    pista[inicio: inicio + largo] += 0.3 * triangulo(48, largo) * envolvente(largo, caida=0.5, sostén=0.4, relajo=0.8)
    for i in range(8):  # redoble de caja
        l = muestra(0.06)
        a = muestra(0.14 + i * 0.06)
        pista[a: a + l] += 0.05 * (1 + i / 4) * ruido(l, i, 0.4) * np.exp(-np.arange(l) / FS * 40)
    return pista[:n]


def pulir(pista: np.ndarray, pico=0.6) -> np.ndarray:
    # paso bajo suave (1 polo) para quitar lo chillón del cuadrado sin perder el carácter
    salida = np.empty_like(pista)
    a = 0.55
    previo = pista[-1]
    for i, x in enumerate(pista):
        previo = previo + a * (x - previo)
        salida[i] = previo
    return salida / np.max(np.abs(salida)) * pico


def escribir_ogg(ruta: Path, pista: np.ndarray) -> None:
    # por bloques: libsndfile se cae al codificar Vorbis largo de una sola vez
    with sf.SoundFile(ruta, "w", FS, 1, format="OGG", subtype="VORBIS") as archivo:
        for i in range(0, len(pista), 4096):
            archivo.write(pista[i: i + 4096].astype(np.float32))


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    loop = pulir(componer_loop())
    escribir_ogg(SALIDA / "viaje_estelar.ogg", loop)
    llegada = pulir(componer_llegada(), 0.55)
    escribir_ogg(SALIDA / "llegada_planeta.ogg", llegada)
    print(f"viaje_estelar.ogg  {len(loop) / FS:.1f} s")
    print(f"llegada_planeta.ogg  {len(llegada) / FS:.1f} s")


if __name__ == "__main__":
    main()
