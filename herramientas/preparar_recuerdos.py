"""Prepara las fotos y voces reales del album "Las migas de papa" (docs/fichas/album-recuerdos.md §8).

Todo local, sin APIs ni costo. Las fotos y voces de la familia quedan en carpetas ignoradas por git
(assets/recuerdos/fotos/ y assets/recuerdos/voces/): nunca se suben a GitHub.

Subcomandos:
  estado        Lista el catalogo y marca que fotos/voces reales ya estan (y cuales faltan).
  fotos         Redimensiona fotos a 1280 px en el lado largo, JPG calidad 85, girando segun EXIF.
                  python herramientas/preparar_recuerdos.py fotos --origen "C:/Users/yo/Fotos album"
                El nombre del archivo de origen debe ser el id del recuerdo (maxi_01.jpg, familia_03.png...).
  voces         Convierte audios a OGG Vorbis mono (WAV/FLAC directo; m4a/mp3/aac/opus via el ffmpeg de
                imageio-ffmpeg si esta instalado) y nivela el volumen.
                  python herramientas/preparar_recuerdos.py voces --origen "C:/Users/yo/Audios album"
  placeholders  Regenera assets/recuerdos/placeholders/*.png desde assets/anclas/ (versionados).

Opciones comunes: --simular (no escribe nada), --forzar (sobrescribe lo ya preparado).
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CATALOGO = RAIZ / "datos" / "recuerdos" / "catalogo.json"
FOTOS = RAIZ / "assets" / "recuerdos" / "fotos"
VOCES = RAIZ / "assets" / "recuerdos" / "voces"
PLACEHOLDERS = RAIZ / "assets" / "recuerdos" / "placeholders"
ANCLAS = RAIZ / "assets" / "anclas"

LADO_MAXIMO = 1280
CALIDAD_JPG = 85
EXT_FOTO = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".bmp", ".tif", ".tiff"}
EXT_VOZ_DIRECTA = {".wav", ".flac", ".ogg"}
EXT_VOZ_FFMPEG = {".m4a", ".mp3", ".aac", ".opus", ".amr", ".3gp", ".mp4", ".wma"}
PICO_DB = -1.5

# Recortes de los placeholders (x, y, ancho, alto) sobre las hojas de referencia de assets/anclas/.
RECORTES = {
    "maxi": ("maxi_referencia.png", (360, 40, 340, 340)),
    "nicole": ("nicole_referencia.png", (360, 40, 340, 340)),
    "sofia": ("sofia_referencia.png", (360, 40, 340, 340)),
    "familia": ("hermanos_alturas.png", (270, 20, 860, 740)),
}


def ids_catalogo() -> list[str]:
    datos = json.loads(CATALOGO.read_text(encoding="utf-8"))
    return [r["id"] for r in datos["recuerdos"]]


def buscar(carpeta: Path, id_recuerdo: str, extensiones: set[str]) -> Path | None:
    for ext in sorted(extensiones):
        ruta = carpeta / f"{id_recuerdo}{ext}"
        if ruta.exists():
            return ruta
    return None


def cmd_estado(_args) -> None:
    ids = ids_catalogo()
    con_foto = con_voz = 0
    for id_recuerdo in ids:
        foto = buscar(FOTOS, id_recuerdo, {".jpg", ".jpeg", ".png", ".webp"})
        voz = buscar(VOCES, id_recuerdo, {".ogg", ".wav", ".mp3"})
        con_foto += foto is not None
        con_voz += voz is not None
        print(f"  {id_recuerdo:12s} foto: {'SI ' + foto.name if foto else '-':22s} voz: {'SI ' + voz.name if voz else '-'}")
    print(f"\n{len(ids)} recuerdos | {con_foto} fotos reales | {con_voz} voces reales")


def cmd_fotos(args) -> None:
    from PIL import Image, ImageOps

    try:  # fotos de iPhone (.heic), si el paquete esta instalado
        from pillow_heif import register_heif_opener  # type: ignore

        register_heif_opener()
    except ImportError:
        pass
    origen = Path(args.origen)
    validos = set(ids_catalogo())
    FOTOS.mkdir(parents=True, exist_ok=True)
    hechas = 0
    for ruta in sorted(origen.iterdir()):
        if ruta.suffix.lower() not in EXT_FOTO:
            continue
        id_recuerdo = ruta.stem.lower()
        if id_recuerdo not in validos:
            print(f"  (salto) {ruta.name}: el nombre no es un id del catalogo")
            continue
        destino = FOTOS / f"{id_recuerdo}.jpg"
        if destino.exists() and not args.forzar:
            print(f"  (ya esta) {destino.name}  -- usa --forzar para rehacerla")
            continue
        with Image.open(ruta) as imagen:
            imagen = ImageOps.exif_transpose(imagen).convert("RGB")
            imagen.thumbnail((LADO_MAXIMO, LADO_MAXIMO), Image.LANCZOS)
            print(f"  {ruta.name} -> {destino.relative_to(RAIZ).as_posix()} ({imagen.width}x{imagen.height})")
            if not args.simular:
                imagen.save(destino, "JPEG", quality=CALIDAD_JPG, optimize=True, progressive=True)
                # si habia una version .png vieja con el mismo id, el juego podria tomar esa: se avisa
                for otra in FOTOS.glob(f"{id_recuerdo}.*"):
                    if otra != destino and otra.suffix.lower() in {".png", ".jpeg", ".webp"}:
                        print(f"    aviso: tambien existe {otra.name}; borrala para que se use la nueva")
            hechas += 1
    print(f"\n{hechas} fotos preparadas en {FOTOS.relative_to(RAIZ).as_posix()}/")


def leer_audio(ruta: Path):
    import numpy as np
    import soundfile as sf

    if ruta.suffix.lower() in EXT_VOZ_DIRECTA:
        datos, sr = sf.read(ruta, dtype="float32", always_2d=True)
        return datos.mean(axis=1), sr
    try:
        import imageio_ffmpeg  # type: ignore
    except ImportError:
        raise RuntimeError(f"{ruta.name}: para {ruta.suffix} hace falta 'pip install imageio-ffmpeg' (o conviertelo a WAV)")
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "voz.wav"
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-i", str(ruta), "-ac", "1", str(wav)], check=True)
        datos, sr = sf.read(wav, dtype="float32", always_2d=True)
        return np.asarray(datos.mean(axis=1)), sr


def cmd_voces(args) -> None:
    import numpy as np
    import soundfile as sf

    origen = Path(args.origen)
    validos = set(ids_catalogo())
    VOCES.mkdir(parents=True, exist_ok=True)
    hechas = 0
    for ruta in sorted(origen.iterdir()):
        if ruta.suffix.lower() not in EXT_VOZ_DIRECTA | EXT_VOZ_FFMPEG:
            continue
        id_recuerdo = ruta.stem.lower()
        if id_recuerdo not in validos:
            print(f"  (salto) {ruta.name}: el nombre no es un id del catalogo")
            continue
        destino = VOCES / f"{id_recuerdo}.ogg"
        if destino.exists() and not args.forzar:
            print(f"  (ya esta) {destino.name}  -- usa --forzar para rehacerla")
            continue
        try:
            datos, sr = leer_audio(ruta)
        except Exception as error:  # noqa: BLE001 - se informa y se sigue con el resto
            print(f"  ERROR {ruta.name}: {error}")
            continue
        pico = float(np.max(np.abs(datos))) if len(datos) else 0.0
        if pico > 0:
            datos = datos * (10 ** (PICO_DB / 20) / pico)
        segundos = len(datos) / sr
        aviso = "  (largo: la ficha sugiere 3-10 s)" if segundos > 12 else ""
        print(f"  {ruta.name} -> {destino.relative_to(RAIZ).as_posix()} ({segundos:.1f} s){aviso}")
        if not args.simular:
            with sf.SoundFile(destino, "w", sr, 1, format="OGG", subtype="VORBIS") as archivo:
                for i in range(0, len(datos), 4096):  # por bloques: libsndfile falla con Vorbis largo de una vez
                    archivo.write(datos[i: i + 4096].astype(np.float32))
            for otra in VOCES.glob(f"{id_recuerdo}.*"):
                if otra != destino and otra.suffix.lower() in {".wav", ".mp3"}:
                    print(f"    aviso: tambien existe {otra.name}; borrala para que se use la nueva")
        hechas += 1
    print(f"\n{hechas} voces preparadas en {VOCES.relative_to(RAIZ).as_posix()}/")


def cmd_placeholders(args) -> None:
    from PIL import Image

    PLACEHOLDERS.mkdir(parents=True, exist_ok=True)
    for album, (archivo, (x, y, ancho, alto)) in RECORTES.items():
        with Image.open(ANCLAS / archivo) as imagen:  # las anclas son JPEG aunque digan .png
            recorte = imagen.convert("RGB").crop((x, y, x + ancho, y + alto))
            recorte.thumbnail((640, 640), Image.LANCZOS)
            destino = PLACEHOLDERS / f"{album}.png"
            print(f"  {archivo} -> {destino.relative_to(RAIZ).as_posix()} ({recorte.width}x{recorte.height})")
            if not args.simular:
                recorte.save(destino, "PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="comando", required=True)
    sub.add_parser("estado", help="que fotos y voces reales ya estan")
    for nombre in ("fotos", "voces"):
        p = sub.add_parser(nombre, help=f"prepara las {nombre} desde una carpeta")
        p.add_argument("--origen", required=True, help="carpeta con archivos nombrados por id (maxi_01.jpg...)")
        p.add_argument("--simular", action="store_true", help="muestra lo que haria sin escribir")
        p.add_argument("--forzar", action="store_true", help="rehace las que ya estan")
    p = sub.add_parser("placeholders", help="regenera los placeholders versionados")
    p.add_argument("--simular", action="store_true")
    args = parser.parse_args()
    {"estado": cmd_estado, "fotos": cmd_fotos, "voces": cmd_voces, "placeholders": cmd_placeholders}[args.comando](args)


if __name__ == "__main__":
    sys.exit(main())
