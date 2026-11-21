"""Catastro de voces: cruza cada ruta voces/... que pide el juego (datos/, scripts/, escenas/) con el disco y con
pendientes_fal.txt. Uso: python herramientas/catastro_voces.py [-v]. Escribe herramientas/salidas/catastro_voces.json."""
import re, os, sys, json, collections
from pathlib import Path
RAIZ = Path(__file__).resolve().parent.parent
os.chdir(RAIZ)
pat = re.compile(r'(?:res://assets/audio/)?(voces/[A-Za-z0-9_/%\-\.]+?\.(?:wav|ogg))')
refs = collections.defaultdict(set)
for base in ["datos", "scripts", "escenas"]:
    for d, _, fs in os.walk(base):
        for f in fs:
            if f.endswith((".gd", ".json", ".tscn")):
                p = os.path.join(d, f)
                t = open(p, encoding="utf-8", errors="ignore").read()
                for m in pat.findall(t):
                    refs[m].add(p.replace("\\", "/"))
pend = {l.strip() for l in open("assets/audio/voces/pendientes_fal.txt", encoding="utf-8") if l.strip() and not l.startswith("#")}
LEJOS = ("melodia", "cuenta_cuentas", "letralandia", "corazon")
def ambito(r):
    partes = r.split("/")
    return "/".join(partes[1:3]) if partes[1] in ("arcoiris", "animalia", "historia", "planetas") else "/".join(partes[1:2] + ([partes[2]] if len(partes) > 3 else []))
res = collections.defaultdict(lambda: {"ok": 0, "falta": [], "relleno": []})
for r, quien in sorted(refs.items()):
    if any(x in r for x in LEJOS) or "%" in r:
        continue
    a = ambito(r)
    if not os.path.exists("assets/audio/" + r):
        res[a]["falta"].append(r)
    elif r in pend:
        res[a]["relleno"].append(r)
    else:
        res[a]["ok"] += 1
tot = [0, 0, 0]
for a in sorted(res):
    v = res[a]
    tot[0] += v["ok"]; tot[1] += len(v["falta"]); tot[2] += len(v["relleno"])
    print(f"{a:40s} ok {v['ok']:4d}  falta {len(v['falta']):4d}  relleno {len(v['relleno']):4d}")
print("TOTAL ok %d falta %d relleno %d" % tuple(tot))
if "-v" in sys.argv:
    for a in sorted(res):
        for r in res[a]["falta"]:
            print("FALTA", r, sorted(refs[r])[:1])
json.dump({a: {"falta": v["falta"], "relleno": v["relleno"]} for a, v in res.items()},
          open(RAIZ / "herramientas" / "salidas" / "catastro_voces.json", "w", encoding="utf-8"), indent=1, ensure_ascii=False)
# pendientes fuera de referencias
print("pendientes no referenciados:", len([p for p in pend if p not in refs]))
