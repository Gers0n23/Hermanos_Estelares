"""Corta los videos de viaje (B4, HE-130) en dos para meter el viaje arcade (HE-136) en medio.

Cada `assets/video/viaje/viaje_<origen>_a_<destino>.ogv` (despegue_viaje.py) tiene: despegue en la
superficie, corte en blanco en F_CORTE y vuelo por el espacio hacia el planeta destino. En el cuadro
F_CORTE + 15 la nave ya está en el espacio, a la izquierda, mirando al destino pequeño: ese es el
cuadro de EMPALME.

  <nombre>_despegue.ogv  cuadros 0 .. EMPALME      (el arcade arranca desde esa composición)
  <nombre>_llegada.ogv   cuadros EMPALME .. final  (el arcade termina en esa composición y sigue el video,
                                                    cuyo último cuadro es el primero de la presentación)
  empalme/<origen>_<destino>.png  el cuadro de empalme (para el fundido entre video y juego)

Tierra -> Arcoíris (herramientas/armar_viaje_tierra.py) tiene el mismo acto 2, con F_CORTE = 160.

Los originales no se tocan. Uso:  python herramientas/cortar_videos_viaje.py [tierra_arcoiris,arcoiris_animalia]
"""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "assets" / "video" / "viaje"
FPS = 24
CALIDAD_THEORA = "6"


def empalme(origen: str) -> int:
    f_corte = {"tierra": 160, "arcoiris": 150}.get(origen, 112)     # mismo valor que despegue_viaje.py
    return f_corte + 15


def ffmpeg(*args: str) -> None:
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-y", *args], check=True)


def tiene_audio(video: Path) -> bool:
    salida = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-hide_banner", "-i", str(video)],
                            capture_output=True, text=True).stderr
    return "Audio:" in salida


def main() -> None:
    (CARPETA / "empalme").mkdir(exist_ok=True)
    solo = sys.argv[1].split(",") if len(sys.argv) > 1 else []
    for video in sorted(CARPETA.glob("viaje_*_a_*.ogv")):
        if video.stem.endswith(("_despegue", "_llegada")):
            continue
        origen, destino = video.stem.removeprefix("viaje_").split("_a_")
        if solo and f"{origen}_{destino}" not in solo:
            continue
        audio = tiene_audio(video)
        n = empalme(origen)
        t = n / FPS
        a_despegue = ["-af", f"atrim=end={t + 1 / FPS},asetpts=PTS-STARTPTS", "-c:a", "libvorbis", "-q:a", "5"]
        a_llegada = ["-af", f"atrim=start={t},asetpts=PTS-STARTPTS", "-c:a", "libvorbis", "-q:a", "5"]
        ffmpeg("-i", str(video), "-vf", f"trim=end_frame={n + 1},setpts=PTS-STARTPTS",
               *(a_despegue if audio else ["-an"]), "-c:v", "libtheora", "-q:v", CALIDAD_THEORA,
               str(CARPETA / f"{video.stem}_despegue.ogv"))
        ffmpeg("-i", str(video), "-vf", f"trim=start_frame={n},setpts=PTS-STARTPTS",
               *(a_llegada if audio else ["-an"]), "-c:v", "libtheora", "-q:v", CALIDAD_THEORA,
               str(CARPETA / f"{video.stem}_llegada.ogv"))
        ffmpeg("-i", str(video), "-vf", f"select=eq(n\\,{n})", "-frames:v", "1",
               str(CARPETA / "empalme" / f"{origen}_{destino}.png"))
        print(f"{video.name}: empalme en el cuadro {n} ({t:.2f} s)")


if __name__ == "__main__":
    main()
