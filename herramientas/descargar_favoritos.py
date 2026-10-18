"""Biblioteca de "favoritos" para Parejas (memorice): imagenes de lo que les gusta a los ninos.

Pedido del PO (17-Oct-2026): pares especiales con cosas que les encantan (KATSEYE y las guerreras
K-pop para Nicole y Sofia; Sonic y Tayo para Maxi) que aparezcan al azar en el memorice. Uso
familiar, no comercial: las imagenes se BAJAN de las wikis de fans (API MediaWiki de Fandom), no se
recrean. Sin costo (APIs publicas gratuitas).

Que hace:
  1. Por cada tema, toma la imagen principal de la pagina de cada personaje (pageimages) y, si existe,
     algunas de su galeria (`<Pagina>/Gallery`) cuyo nombre de archivo menciona al personaje.
  2. Las recorta cuadradas (sesgo hacia arriba, donde suelen estar las caras), las achica a 256 px y
     las guarda en WebP liviano en `assets/sprites/favoritos/<tema>/`.
  3. Escribe `datos/favoritos/catalogo.json` (tema -> hermanos + lista de imagenes).

Para agregar mas: sumar personajes/temas en TEMAS y volver a correr. Lo ya bajado no se repite.
Las imagenes que no sirvan se borran a mano y se agregan a `descartadas` del catalogo (no vuelven).

Uso:  python -I herramientas/descargar_favoritos.py [--tema sonic] [--por-personaje 4] [--bruto DIR]
"""
from __future__ import annotations

import argparse
import io
import json
import re
import subprocess
import sys
import tempfile
import time
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
DIR_SALIDA = RAIZ / "assets" / "sprites" / "favoritos"
RUTA_CATALOGO = RAIZ / "datos" / "favoritos" / "catalogo.json"
AGENTE = "HermanosEstelares/1.0 (juego familiar sin fines comerciales)"
LADO = 256
CALIDAD_WEBP = 72
EXTENSIONES = (".jpg", ".jpeg", ".png", ".webp")
# Palabras en nombres de archivo que casi nunca son una buena carta (logos, iconos, capturas de texto).
RUIDO = re.compile(r"logo|icon|sprite|signature|firma|title|titulo|map|screenshot|cover|album|poster|"
                   r"banner|card|tracklist|teaser.*text|\.svg|wordmark|button", re.I)

# Cada tema: wiki de Fandom, hermanos que lo ven y personajes (pagina, palabra clave para la galeria).
TEMAS: dict[str, dict] = {
    "katseye": {
        "wiki": "kpop",
        "hermanos": ["nicole", "sofia"],
        "personajes": [
            ("KATSEYE", "katseye"),
            ("Sophia (KATSEYE)", "sophia"),
            ("Lara (KATSEYE)", "lara"),
            ("Megan (KATSEYE)", "megan"),
            ("Yoonchae (KATSEYE)", "yoonchae"),
            ("Daniela", "daniela"),
            ("Manon (KATSEYE)", "manon"),
        ],
    },
    "guerreras_kpop": {
        "wiki": "kpop-demon-hunters",
        "hermanos": ["nicole", "sofia"],
        "personajes": [
            ("Rumi", "rumi"), ("Mira", "mira"), ("Zoey", "zoey"), ("HUNTRIX", "huntr"),
            ("Jinu", "jinu"), ("Derpy and Sussie", "derpy"), ("Celine", "celine"),
            ("Abby Saja", "abby"), ("Baby Saja", "baby"), ("Mystery Saja", "mystery"),
            ("Romance Saja", "romance"), ("Bobby", "bobby"),
        ],
    },
    "sonic": {
        "wiki": "sonic",
        "hermanos": ["maxi"],
        "personajes": [
            ("Sonic the Hedgehog", "sonic"), ("Miles \"Tails\" Prower", "tails"),
            ("Knuckles the Echidna", "knuckles"), ("Amy Rose", "amy"),
            ("Shadow the Hedgehog", "shadow"), ("Cream the Rabbit", "cream"),
            ("Doctor Eggman", "eggman"), ("Silver the Hedgehog", "silver"),
            ("Big the Cat", "big"), ("Blaze the Cat", "blaze"), ("Rouge the Bat", "rouge"),
            ("Chao", "chao"), ("Metal Sonic", "metal"), ("Super Sonic", "super"),
        ],
    },
    "tayo": {
        "wiki": "tayothelittlebus",
        "hermanos": ["maxi"],
        "personajes": [
            ("Tayo", "tayo"), ("Rogi", "rogi"), ("Lani", "lani"), ("Gani", "gani"),
            ("Citu", "citu"), ("Hana", "hana"), ("Frank", "frank"), ("Heart", "heart"),
            ("Alice", "alice"), ("Big", "big"), ("Bong Bong", "bong"), ("Champ", "champ"),
            ("Cargo", "cargo"), ("Duri", "duri"), ("Air", "air"),
        ],
    },
    # Pedido del PO (17-Oct-2026, misma sesion): mas gustos de Maxi y de las ninas.
    "backrooms": {
        "wiki": "backrooms",
        "hermanos": ["maxi"],
        "personajes": [
            ("Level 0", "level_0"), ("Level 1", "level_1"), ("Level 2", "level_2"),
            ("Level 3", "level_3"), ("Level 4", "level_4"), ("Level 6", "level_6"),
            ("Level 37", "level_37"), ("Level Fun", "fun"), ("Level 188", "level_188"),
            ("Level 974", "level_974"), ("Smilers", "smiler"), ("Partygoers", "partygoer"),
            ("Hounds", "hound"), ("Facelings", "faceling"), ("Bacteria", "bacteria"),
            ("Death Moths", "moth"), ("Skin-Stealers", "skin"), ("Window", "window"),
        ],
    },
    "backrooms_kane": {
        "wiki": "kane-pixels-backrooms",
        "hermanos": ["maxi"],
        "personajes": [
            ("The Backrooms", "backrooms"), ("Async Research Institute", "async"),
            ("The Entity", "entity"), ("Howler", "howler"), ("Kate Hall", "kate"),
        ],
    },
    "roblox": {
        "wiki": "roblox",
        "hermanos": ["maxi"],
        "personajes": [
            ("Noob", "noob"), ("Bacon Hair", "bacon"), ("Builderman", "builderman"),
            ("Guest", "guest"), ("Doors", "doors"), ("Adopt Me!", "adopt"),
            ("Brookhaven RP", "brookhaven"), ("Grow a Garden", "garden"), ("Dandy's World", "dandy"),
            ("99 Nights in the Forest", "nights"), ("Blox Fruits", "blox"), ("Piggy", "piggy"),
            ("Natural Disaster Survival", "disaster"), ("Tower of Hell", "tower"),
            ("Steal a Brainrot", "brainrot"), ("Pressure", "pressure"), ("Rainbow Friends", "rainbow"),
            ("Work at a Pizza Place", "pizza"), ("Jailbreak", "jailbreak"), ("Bloxy Award", "bloxy"),
        ],
    },
    "verity": {
        "wiki": "verity",
        "hermanos": ["maxi"],
        "toda_la_wiki": True,
        "personajes": [("Verity", "verity"), ("Falsity", "falsity")],
    },
    "spiderman": {
        "wiki": "spiderman",
        "hermanos": ["maxi"],
        "personajes": [
            ("Peter Parker (Earth-616)", "spider"), ("Miles Morales", "miles"),
            ("Gwen Stacy (Spider-Verse)", "gwen"), ("Spidey and His Amazing Friends", "spidey"),
            ("Venom", "venom"), ("Spider-Ham", "ham"), ("Spider-Man 2099", "2099"),
            ("Iron Spider", "iron"), ("Ghost-Spider", "ghost"), ("Green Goblin", "goblin"),
            ("Doctor Octopus", "octopus"), ("Spider-Man (Tom Holland)", "holland"),
        ],
    },
    # La Spider-Man Wiki trae mucho comic adulto: Spidey infantil desde la wiki de Disney.
    "spidey": {
        "wiki": "disney",
        "hermanos": ["maxi"],
        "personajes": [
            ("Spider-Man", "spider"), ("Miles Morales", "miles"), ("Gwen Stacy", "gwen"),
            ("Spidey and His Amazing Friends", "spidey"), ("Hulk", "hulk"), ("Venom", "venom"),
            ("Ms. Marvel", "marvel"), ("Black Panther", "panther"),
        ],
    },
    "disney": {
        "wiki": "disney",
        "hermanos": ["nicole", "sofia"],
        "personajes": [
            ("Elsa", "elsa"), ("Anna", "anna"), ("Olaf", "olaf"), ("Moana", "moana"),
            ("Maui", "maui"), ("Mirabel Madrigal", "mirabel"), ("Isabela Madrigal", "isabela"),
            ("Luisa Madrigal", "luisa"), ("Bruno Madrigal", "bruno"), ("Asha", "asha"),
            ("Raya", "raya"), ("Rapunzel", "rapunzel"), ("Joy", "joy"), ("Anxiety", "anxiety"),
            ("Stitch", "stitch"), ("Judy Hopps", "judy"), ("Ember Lumen", "ember"),
            ("Meilin Lee", "mei"), ("Ariel", "ariel"), ("Belle", "belle"), ("Tiana", "tiana"),
            ("Bluey", "bluey"), ("Wonder Wall", "wonder"), ("Elio", "elio"),
        ],
    },
    "harry_potter": {
        "wiki": "harrypotter",
        "hermanos": ["nicole", "sofia"],
        "personajes": [
            ("Harry Potter", "harry"), ("Hermione Granger", "hermione"), ("Ronald Weasley", "ron"),
            ("Hedwig", "hedwig"), ("Dobby", "dobby"), ("Hogwarts Castle", "hogwarts"),
            ("Albus Dumbledore", "dumbledore"), ("Rubeus Hagrid", "hagrid"),
            ("Luna Lovegood", "luna"), ("Golden Snitch", "snitch"), ("Sorting Hat", "sorting"),
            ("Fawkes", "fawkes"), ("Buckbeak", "buckbeak"), ("Hogwarts Express", "express"),
            ("Ginevra Weasley", "ginny"), ("Neville Longbottom", "neville"), ("Crookshanks", "crookshanks"),
        ],
    },
    "sanrio": {
        "wiki": "hellokitty",
        "hermanos": ["nicole", "sofia"],
        "personajes": [
            ("Hello Kitty", "kitty"), ("My Melody", "melody"), ("Kuromi", "kuromi"),
            ("Cinnamoroll", "cinnamoroll"), ("Pompompurin", "purin"), ("Pochacco", "pochacco"),
            ("Keroppi", "keroppi"), ("Badtz-Maru", "badtz"), ("Little Twin Stars", "twin"),
            ("Hangyodon", "hangyodon"), ("Gudetama", "gudetama"), ("Wish me mell", "mell"),
            ("Tuxedosam", "tuxedo"), ("My Sweet Piano", "piano"), ("Kiki and Lala", "kiki"),
        ],
    },
}


def _api(wiki: str, **params) -> dict:
    params.setdefault("format", "json")
    url = f"https://{wiki}.fandom.com/api.php?" + urllib.parse.urlencode(params)
    for intento in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": AGENTE}), timeout=30) as r:
                return json.load(r)
        except Exception as e:  # red intermitente: reintento corto
            if intento == 2:
                print(f"  ! API {wiki}: {e}", file=sys.stderr)
            time.sleep(1.5)
    return {}


## Las imagenes se bajan con curl: en Windows usa el almacen de certificados del sistema, y el de
## Python rechaza el CDN de Fandom (static.wikia.nocookie.net). No se desactiva la verificacion.
## Si la miniatura pedida es mas grande que el original, Fandom responde 404: se reintenta sin escalar.
def _bajar(url: str) -> bytes | None:
    for intento in (url, re.sub(r"/scale-to-width-down/\d+", "", url)):
        r = subprocess.run(["curl", "-sfL", "-m", "40", "-A", AGENTE, intento], capture_output=True)
        if r.returncode == 0 and r.stdout:
            return r.stdout
    print(f"  ! descarga ({r.returncode}): {url[:90]}", file=sys.stderr)
    return None


## Titulo real de la pagina: el pedido tal cual (con redirecciones) o, si no existe, el primer
## resultado de la busqueda de la wiki. Asi los personajes se anotan con su nombre comun.
def _resolver_titulo(wiki: str, pagina: str) -> str:
    d = _api(wiki, action="query", titles=pagina, redirects=1)
    for p in d.get("query", {}).get("pages", {}).values():
        if "missing" not in p:
            return p["title"]
    d = _api(wiki, action="query", list="search", srsearch=pagina, srlimit=1)
    resultados = d.get("query", {}).get("search", [])
    return resultados[0]["title"] if resultados else ""


## Para wikis chicas (p. ej. Verity): todas sus imagenes subidas.
def _todas_las_imagenes(wiki: str) -> list[tuple[str, str]]:
    d = _api(wiki, action="query", list="allimages", ailimit=200, aiprop="size")
    titulos = [i["title"] for i in d.get("query", {}).get("allimages", [])
               if i["title"].lower().endswith(EXTENSIONES) and not RUIDO.search(i["title"])]
    return _miniaturas(wiki, titulos)


def _miniaturas(wiki: str, archivos: list[str]) -> list[tuple[str, str]]:
    salida = []
    for i in range(0, len(archivos), 40):
        d = _api(wiki, action="query", titles="|".join(archivos[i:i + 40]), prop="imageinfo",
                 iiprop="url|size", iiurlwidth=LADO * 2)
        for p in d.get("query", {}).get("pages", {}).values():
            info = (p.get("imageinfo") or [{}])[0]
            if info.get("thumburl") and min(info.get("width", 0), info.get("height", 0)) >= 180:
                salida.append((p["title"], info["thumburl"]))
    return salida


def _slug(texto: str) -> str:
    texto = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", texto.lower()).strip("_")[:48]


def _imagen_principal(wiki: str, pagina: str) -> list[tuple[str, str]]:
    d = _api(wiki, action="query", titles=pagina, prop="pageimages", piprop="thumbnail|name",
             pithumbsize=LADO * 2, redirects=1)
    salida = []
    for p in d.get("query", {}).get("pages", {}).values():
        if "thumbnail" in p:
            salida.append((p.get("pageimage", p["title"]), p["thumbnail"]["source"]))
    return salida


def _imagenes_galeria(wiki: str, pagina: str, clave: str, maximo: int) -> list[tuple[str, str]]:
    d = _api(wiki, action="query", titles=f"{pagina}/Gallery", prop="images", imlimit=500, redirects=1)
    archivos = []
    for p in d.get("query", {}).get("pages", {}).values():
        for img in p.get("images", []):
            t = img["title"]
            if clave in t.lower() and t.lower().endswith(EXTENSIONES) and not RUIDO.search(t):
                archivos.append(t)
    # Repartidas a lo largo de la galeria (distintas epocas/estilos), no solo las primeras.
    if len(archivos) > maximo:
        paso = len(archivos) / maximo
        archivos = [archivos[int(i * paso)] for i in range(maximo)]
    return _miniaturas(wiki, archivos)


def _a_carta(datos: bytes) -> Image.Image | None:
    try:
        im = Image.open(io.BytesIO(datos))
        im.load()
    except Exception:
        return None
    if im.mode in ("P", "LA", "RGBA") or "transparency" in im.info:
        im = im.convert("RGBA")
        fondo = Image.new("RGBA", im.size, (255, 255, 255, 255))
        fondo.alpha_composite(im)
        im = fondo
    im = im.convert("RGB")
    an, al = im.size
    if min(an, al) < 120:
        return None
    lado = min(an, al)
    x = (an - lado) // 2
    # Retrato: desde casi arriba (caras); resto: centrado.
    y = min(int(al * 0.04), al - lado) if al > an * 1.15 else (al - lado) // 2
    return im.crop((x, y, x + lado, y + lado)).resize((LADO, LADO), Image.LANCZOS)


def _descartar(catalogo: dict, rutas: list[str]) -> None:
    for ruta in rutas:
        ruta = ruta.strip().replace("\\", "/").split("assets/", 1)[-1]
        for entrada in catalogo["temas"].values():
            entrada["imagenes"] = [i for i in entrada["imagenes"] if i["archivo"] != ruta]
        if ruta not in catalogo["descartadas"]:
            catalogo["descartadas"].append(ruta)
        (RAIZ / "assets" / ruta).unlink(missing_ok=True)
        (RAIZ / "assets" / (ruta + ".import")).unlink(missing_ok=True)
        print(f"  - {ruta}")


def _guardar_imagen(tema: str, entrada: dict, wiki: str, personaje: str, clave: str, titulo: str,
                    url: str, ya: set, bruto: Path) -> None:
    nombre = f"{_slug(clave)}_{_slug(titulo.split(':', 1)[-1].rsplit('.', 1)[0])}"[:60] + ".webp"
    ruta_res = f"sprites/favoritos/{tema}/{nombre}"
    if ruta_res in ya:
        return
    datos = _bajar(url)
    if not datos:
        return
    (bruto / f"{tema}_{nombre}.bin").write_bytes(datos)
    carta = _a_carta(datos)
    if carta is None:
        return
    carta.save(DIR_SALIDA / tema / nombre, "WEBP", quality=CALIDAD_WEBP, method=6)
    entrada["imagenes"].append({"archivo": ruta_res, "personaje": personaje,
                                "fuente": f"https://{wiki}.fandom.com/wiki/"
                                          + urllib.parse.quote(titulo.replace(" ", "_"))})
    ya.add(ruta_res)
    print(f"  + {nombre}")
    time.sleep(0.2)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tema", action="append", help="solo estos temas (repetible)")
    ap.add_argument("--por-personaje", type=int, default=4, help="imagenes de galeria por personaje")
    ap.add_argument("--bruto", default="", help="carpeta para guardar las descargas originales (opcional)")
    ap.add_argument("--descartar", nargs="+", default=[],
                    help="borra estas imagenes (ruta o sprites/favoritos/...) y no las vuelve a bajar")
    args = ap.parse_args()

    catalogo = json.loads(RUTA_CATALOGO.read_text(encoding="utf-8")) if RUTA_CATALOGO.exists() else {}
    catalogo.setdefault("version", 1)
    catalogo.setdefault("descartadas", [])
    temas_cat = catalogo.setdefault("temas", {})
    if args.descartar:
        _descartar(catalogo, args.descartar)
    else:
        bruto = Path(args.bruto) if args.bruto else Path(tempfile.mkdtemp(prefix="favoritos_"))
        bruto.mkdir(parents=True, exist_ok=True)
        for tema, conf in TEMAS.items():
            if args.tema and tema not in args.tema:
                continue
            print(f"== {tema}")
            (DIR_SALIDA / tema).mkdir(parents=True, exist_ok=True)
            entrada = temas_cat.setdefault(tema, {"hermanos": conf["hermanos"], "imagenes": []})
            entrada["hermanos"] = conf["hermanos"]
            ya = {img["archivo"] for img in entrada["imagenes"]} | set(catalogo["descartadas"])
            wiki = conf["wiki"]
            if conf.get("toda_la_wiki"):
                for titulo, url in _todas_las_imagenes(wiki):
                    _guardar_imagen(tema, entrada, wiki, tema, tema, titulo, url, ya, bruto)
            for pedido, clave in conf.get("personajes", []):
                pagina = _resolver_titulo(wiki, pedido)
                if pagina == "":
                    print(f"  ? sin pagina: {pedido}")
                    continue
                candidatos = _imagen_principal(wiki, pagina)
                candidatos += _imagenes_galeria(wiki, pagina, clave, args.por_personaje)
                vistos = set()
                for titulo, url in candidatos:
                    if titulo not in vistos:
                        vistos.add(titulo)
                        _guardar_imagen(tema, entrada, wiki, pedido, clave, titulo, url, ya, bruto)

    RUTA_CATALOGO.parent.mkdir(parents=True, exist_ok=True)
    RUTA_CATALOGO.write_text(json.dumps(catalogo, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    total = sum(len(t["imagenes"]) for t in temas_cat.values())
    print(f"Catalogo: {total} imagenes en {len(temas_cat)} temas -> {RUTA_CATALOGO.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
