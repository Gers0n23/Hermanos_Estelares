"""Arma el video de viaje Tierra -> Arcoíris (B4 que faltaba) con la misma estructura que los otros 6.

  acto 1  poc/cinematica_blender/salida/despegue_tierra_v1.mp4 (despegue_tierra.py): la nave se levanta del
          patio y sube al cielo. Se usan los cuadros 1..F_CORTE-1 y se funde a blanco igual que en
          despegue_viaje.py (de F_CORTE-14 a F_CORTE-3).
  acto 2  poc/cinematica_blender/salida/partes/viaje_tierra_a_arcoiris_espacio.mp4
          (despegue_viaje.py --planeta tierra): cuadros F_CORTE..F_FIN, sale del blanco al espacio, con la
          Tierra a la izquierda, y vuela hasta Arcoíris. Su último cuadro es el primero de presentacion_arcoiris.

Resultado: poc/cinematica_blender/salida/viaje_tierra_a_arcoiris.mp4 (maestro) y
assets/video/viaje/viaje_tierra_a_arcoiris.ogv (Theora q5). Sonido: si existe
salida/audio_mmaudio/viaje_tierra_a_arcoiris_mmaudio.mp4 se usa ese; si no, se presta el de
viaje_arcoiris_a_animalia (decisión del PO, 21-Nov-2026: no pagar MMAudio para este clip), atrasado
10 cuadros para que su corte en blanco (F_CORTE 150) caiga en el de este video (160) y terminen juntos. Después se corta con
`python herramientas/cortar_videos_viaje.py tierra_arcoiris` para el viaje arcade.

Sin costo: todo local (ffmpeg). Uso:  python herramientas/armar_viaje_tierra.py
"""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "poc" / "cinematica_blender" / "salida"
ACTO1 = SALIDA / "despegue_tierra_v1.mp4"
ACTO2 = SALIDA / "partes" / "viaje_tierra_a_arcoiris_espacio.mp4"
MAESTRO = SALIDA / "viaje_tierra_a_arcoiris.mp4"
SONIDO = SALIDA / "audio_mmaudio" / "viaje_tierra_a_arcoiris_mmaudio.mp4"
OGV = RAIZ / "assets" / "video" / "viaje" / "viaje_tierra_a_arcoiris.ogv"
PRESTADO = SALIDA / "audio_mmaudio" / "viaje_arcoiris_a_animalia_mmaudio.mp4"
F_CORTE = 160          # mismo valor que despegue_viaje.py con --planeta tierra
F_CORTE_PRESTADO = 150


def ffmpeg(*args: str) -> None:
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-y", *args], check=True)


def main() -> None:
    for falta in (ACTO1, ACTO2):
        if not falta.exists():
            sys.exit(f"falta {falta}")
    n1 = F_CORTE - 1                    # cuadros 1..F_CORTE-1 de Blender = índices 0..F_CORTE-2
    inicio_fundido = F_CORTE - 15       # índice del cuadro F_CORTE-14
    ffmpeg("-i", str(ACTO1), "-i", str(ACTO2), "-filter_complex",
           f"[0:v]trim=end_frame={n1},setpts=PTS-STARTPTS,"
           f"fade=t=out:start_frame={inicio_fundido}:nb_frames=12:color=white,format=yuv420p[a];"
           f"[1:v]setpts=PTS-STARTPTS,format=yuv420p[b];[a][b]concat=n=2:v=1:a=0[v]",
           "-map", "[v]", "-r", "24", "-c:v", "libx264", "-crf", "16", "-pix_fmt", "yuv420p", str(MAESTRO))
    print("maestro", MAESTRO.relative_to(RAIZ))
    if SONIDO.exists():
        ffmpeg("-i", str(MAESTRO), "-i", str(SONIDO), "-map", "0:v:0", "-map", "1:a:0", "-c:v", "libtheora",
               "-q:v", "5", "-c:a", "libvorbis", "-q:a", "5", "-shortest", str(OGV))
        audio = SONIDO.name
    elif PRESTADO.exists():
        atraso = round((F_CORTE - F_CORTE_PRESTADO) / 24 * 1000)
        ffmpeg("-i", str(MAESTRO), "-i", str(PRESTADO), "-filter_complex",
               f"[1:a]adelay={atraso}:all=1,apad,afade=t=in:d=0.4[a]", "-map", "0:v:0", "-map", "[a]",
               "-c:v", "libtheora", "-q:v", "5", "-c:a", "libvorbis", "-q:a", "5", "-shortest", str(OGV))
        audio = PRESTADO.name + " (prestado)"
    else:
        ffmpeg("-i", str(MAESTRO), "-map", "0:v:0", "-c:v", "libtheora", "-q:v", "5", "-an", str(OGV))
        audio = "sin audio"
    print("ogv", OGV.relative_to(RAIZ), "audio:", audio)


if __name__ == "__main__":
    main()
