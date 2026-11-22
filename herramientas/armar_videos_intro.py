"""Arma los videos de la intro hechos en Blender: sintetiza su pista de sonido (sin costo, sin APIs,
mismos ingredientes que herramientas/componer_sfx_ui.py), sincronizada a los cuadros de la animación,
y la mete con el video en un .ogv (Theora + Vorbis) que Godot reproduce sincronizado.

  01b_coleccionauta_llega.ogv  <- poc/cinematica_blender/salida/presentacion_coleccionauta_v1.mp4
      zumbido de ovni que baja en picada, frenazo, tambaleo, "pop" de la tapa, "boing" del salto,
      estrellitas y un "ta-ra-raaan" de villano chistoso (grave y torpe, nunca de miedo).
  03b_cometa_tarde.ogv         <- poc/cinematica_blender/salida/cometa_llega_tarde_v1.mp4
      el ovni arranca y se aleja silbando, "ding" del guiño, la nave de Cometa entra con un soplido y
      motorcito, frena con chirrido, petardea y cae con el silbato de caída de los dibujos animados
      (el golpe lo pone el plano siguiente, 04_choque).

Los tiempos salen de las constantes de cuadro de cada guion de Blender (24 fps, cuadro 1 = 0 s).

Uso:  python herramientas/armar_videos_intro.py
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import imageio_ffmpeg
import numpy as np
import soundfile as sf

sys.path.insert(0, str(Path(__file__).resolve().parent))
from componer_chiptune import FS, frecuencia  # noqa: E402
from componer_sfx_ui import _brillo, _metal, _mezclar, _soplido, campanita, sfx_fuuush, sfx_puf  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "poc" / "cinematica_blender" / "salida"
DESTINO = RAIZ / "assets" / "video" / "intro"


def t(cuadro: int) -> float:
    return (cuadro - 1) / 24


def _tono(midi: np.ndarray, env: np.ndarray, armonicos=(1.0, 0.35, 0.15)) -> np.ndarray:
    f = 440.0 * 2 ** ((midi - 69) / 12)
    fase = 2 * np.pi * np.cumsum(f) / FS
    return sum(a * np.sin((i + 1) * fase) for i, a in enumerate(armonicos)) * env


def zumbido_ovni(seg: float, desde: float, hasta: float, vibrato=7.0) -> np.ndarray:
    """Teremín de platillo volador: seno con vibrato ancho que se desliza de `desde` a `hasta`."""
    n = int(seg * FS)
    x = np.arange(n) / FS
    midi = desde + (hasta - desde) * (x / seg) + 0.8 * np.sin(2 * np.pi * vibrato * x)
    env = np.minimum(1, x / 0.05) * np.minimum(1, (seg - x) / 0.08)
    return _tono(midi, env, (1.0, 0.2))


def tambaleo(seg: float, midi=57.0) -> np.ndarray:
    """"Wob-wob-wob": zumbido grave con temblor que se calma."""
    n = int(seg * FS)
    x = np.arange(n) / FS
    am = 0.55 + 0.45 * np.sin(2 * np.pi * (9 - 5 * x / seg) * x)
    env = am * np.minimum(1, x / 0.03) * np.exp(-x / (seg * 0.6))
    return _tono(midi + 1.5 * np.sin(2 * np.pi * 6 * x), env, (1.0, 0.3))


def chirrido(seg=0.28) -> np.ndarray:
    """Frenazo de dibujo animado: chillido agudo que baja + raspado."""
    n = int(seg * FS)
    x = np.arange(n) / FS
    tono = _tono(94 - 8 * x / seg + 0.6 * np.sin(2 * np.pi * 30 * x), np.exp(-x / 0.15), (1.0, 0.25))
    raspa = _soplido(seg, 0.5, 4) * np.exp(-x / 0.1)
    return 0.7 * tono + 0.25 * raspa


def pop(seg=0.12) -> np.ndarray:
    """Tapón de frasco: golpecito que cae rápido."""
    n = int(seg * FS)
    x = np.arange(n) / FS
    f = 180 + 700 * np.exp(-x / 0.012)
    return np.sin(2 * np.pi * np.cumsum(f) / FS) * np.exp(-x / 0.03)


def boing_sube(seg=0.45) -> np.ndarray:
    n = int(seg * FS)
    x = np.arange(n) / FS
    midi = 55 + 26 * (x / seg) ** 0.6 + 1.5 * np.sin(2 * np.pi * 14 * x) * np.exp(-x / 0.2)
    return _tono(midi, np.minimum(1, x / 0.01) * np.exp(-x / 0.25), (1.0, 0.3))


def silbido_lejos(seg: float, desde: float, hasta: float) -> np.ndarray:
    """Silbato que sube (se aleja) o baja (cae), con vibrato y volumen que acompaña."""
    n = int(seg * FS)
    x = np.arange(n) / FS
    midi = desde + (hasta - desde) * (x / seg) + 0.35 * np.sin(2 * np.pi * 6 * x)
    return _tono(midi, np.minimum(1, x / 0.04), (1.0, 0.1))


def motorcito(seg: float) -> np.ndarray:
    """Motor de la nave de Cometa: "put-put" grave y redondo."""
    n = int(seg * FS)
    x = np.arange(n) / FS
    pulsos = (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 11 * x))) * 0.8 + 0.2
    env = pulsos * np.minimum(1, x / 0.1) * np.minimum(1, (seg - x) / 0.15)
    return _tono(np.full(n, 45.0), env, (1.0, 0.5, 0.25))


def villano_chistoso() -> np.ndarray:
    """"Ta-ra-raaan" de tuba torpe: grave pero en mayor, con el último tono temblón."""
    piezas = [(_metal(43, 0.2), 0.0, 0.6), (_metal(48, 0.2), 0.17, 0.6)]
    n = int(1.1 * FS)
    x = np.arange(n) / FS
    larga = _tono(52 + 0.5 * np.sin(2 * np.pi * 5.5 * x), np.minimum(1, x / 0.03) * np.exp(-x / 0.7),
                  (1.0, 0.6, 0.35, 0.2))
    piezas += [(larga, 0.34, 0.55), (campanita(84, 0.8), 0.36, 0.2)]
    return _mezclar(1.5, piezas)


def pista_coleccionauta() -> np.ndarray:
    largo = t(86) + 1 / 24
    piezas = [
        (zumbido_ovni(t(28), 86, 64), 0.0, 0.32),
        (_brillo(1.0, 7000, 2500, 3), 0.1, 0.08),
        (chirrido(), t(28) - 0.03, 0.35),
        (tambaleo(0.7), t(28) + 0.05, 0.4),
        (zumbido_ovni(largo - t(30), 57, 57, vibrato=4.0), t(30), 0.1),
        (pop(), t(37), 0.15),                  # la tapa da un saltito
        (pop(), t(38) + 0.05, 0.45),           # y se abre: ¡pop!
        (boing_sube(), t(44), 0.42),
        (_brillo(0.6, 9000, 3000, 8), t(46), 0.18),
    ]
    piezas += [(campanita(m, 0.6), t(46) + 0.06 * i, 0.3) for i, m in enumerate((88, 91, 96))]
    piezas += [(villano_chistoso(), t(58), 0.7)]
    return _mezclar(largo, piezas)


def pista_cometa() -> np.ndarray:
    largo = t(108) + 1 / 24
    piezas = [
        (zumbido_ovni(t(15), 57, 57, vibrato=4.0), 0.0, 0.18),
        (boing_sube(0.25), t(8), 0.2),
        (silbido_lejos(t(40) - t(15), 62, 96) * np.linspace(1, 0.15, int((t(40) - t(15)) * FS)), t(15), 0.3),
        (campanita(96, 0.9), t(40), 0.45), (campanita(100, 0.9), t(40) + 0.07, 0.35),
        (sfx_fuuush(), t(30) - 0.1, 0.9),
        (motorcito(t(62) - t(30)), t(30), 0.22),
        (chirrido(0.32), t(56) - 0.05, 0.4),
        (tambaleo(0.55, 62), t(56) + 0.2, 0.3),
    ]
    piezas += [(sfx_puf(), t(f), 0.9) for f in (62, 66, 68, 74, 80)]
    piezas += [(pop(0.1), t(f), 0.25) for f in (62, 68, 74)]
    caida = t(108) - t(70) + 1 / 24
    piezas += [(silbido_lejos(caida, 91, 67), t(70), 0.3)]
    pista = _mezclar(largo, piezas)
    cola = int(0.06 * FS)
    pista[-cola:] *= np.linspace(1, 0.3, cola)
    return pista


def armar(mp4: Path, pista: np.ndarray, ogv: Path) -> None:
    if not mp4.exists():
        sys.exit(f"falta {mp4.relative_to(RAIZ)}: renderízalo con Blender primero")
    pista = pista / max(1e-6, np.max(np.abs(pista))) * 0.8
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "pista.wav"
        sf.write(wav, pista.astype(np.float32), FS)
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-y", "-i", str(mp4), "-i", str(wav),
                        "-map", "0:v:0", "-map", "1:a:0", "-c:v", "libtheora", "-q:v", "7", "-c:a", "libvorbis",
                        "-q:a", "5", "-ac", "2", str(ogv)], check=True)
    print("ogv", ogv.relative_to(RAIZ), f"{len(pista) / FS:.2f} s de sonido")


def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    armar(ORIGEN / "presentacion_coleccionauta_v1.mp4", pista_coleccionauta(), DESTINO / "01b_coleccionauta_llega.ogv")
    armar(ORIGEN / "cometa_llega_tarde_v1.mp4", pista_cometa(), DESTINO / "03b_cometa_tarde.ogv")


if __name__ == "__main__":
    main()
