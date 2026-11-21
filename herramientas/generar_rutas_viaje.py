"""Genera datos/viaje/rutas/<origen>_<destino>.json: las oleadas, checkpoints, jefe y encuentro del
Coleccionauta de cada ruta del viaje arcade (ficha docs/fichas/viaje-arcade.md §3, §5, §8, §11).

Es un PUNTO DE PARTIDA para `disenador-niveles` (HE-136 datos): estructura y conteos según la ficha
(Maxi 2 sectores de 5-6 oleadas; Nicole 3 de 7; Sofía 3 de 8, o 4 sectores desde Animalia→Melodía),
con una semilla fija por ruta para que cada viaje se sienta distinto. Se calibra con el bot (V7).

Uso:  python herramientas/generar_rutas_viaje.py
"""
import json
import random
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "datos" / "viaje" / "rutas"

# ruta, artefacto (jefe), proyectil del jefe, patrones por perfil (fase 1 / fase 2 de Sofía)
RUTAS = [
    ("tierra", "arcoiris", "meteorito_dormilon", "piedrita",
     {"brote": ["lanza_fila", "rebota"], "estrella": ["lanza_fila", "rebota"], "estrella_2": ["abanico", "embiste"]}),
    ("arcoiris", "animalia", "aspiradora", "cajita",
     {"brote": ["empuje", "lanza_fila"], "estrella": ["empuje", "lanza_fila"], "estrella_2": ["abanico", "empuje"]}),
    ("animalia", "melodia", "tocadiscos", "nota",
     {"brote": ["abanico", "rebota"], "estrella": ["abanico", "rebota"], "estrella_2": ["abanico", "embiste"]}),
    ("melodia", "cuenta_cuentas", "grua_cubos", "cubo",
     {"brote": ["lanza_fila", "embiste"], "estrella": ["lanza_fila", "embiste"], "estrella_2": ["lluvia", "abanico"]}),
    ("cuenta_cuentas", "letralandia", "torre_bloques", "bloque",
     {"brote": ["lluvia", "rebota"], "estrella": ["lluvia", "rebota"], "estrella_2": ["lluvia", "abanico"]}),
    ("letralandia", "corazon", "globo_caritas", "globito",
     {"brote": ["abanico", "embiste"], "estrella": ["abanico", "embiste"], "estrella_2": ["abanico", "lluvia"]}),
    ("corazon", "coleccionauta", "nave_coleccionauta", "bolsita",
     {"brote": ["embiste", "lluvia"], "estrella": ["embiste", "lluvia"], "estrella_2": ["abanico", "embiste"]}),
]
ORDEN = [r[1] for r in RUTAS]
VIDA_JEFE = {"semilla": 230, "brote": 300, "estrella": 460}       # §5.3: calibrar para 20-30 / 30-45 / 40-60 s
CAPSULAS = ["arma", "minicometas", "iman"]


def oleadas_sector(rng, perfil, s, n):
    """Lista de oleadas de un sector. La primera y la del medio llevan checkpoint (§3)."""
    tipos_base = ["meteoritos", "formacion", "basura", "formacion", "meteoritos", "torretas", "formacion",
                  "basura", "formacion", "torretas"]
    if perfil == "semilla":
        tipos_base = ["meteoritos", "formacion", "basura", "meteoritos", "formacion", "basura"]
    rng.shuffle(tipos_base)
    lista = []
    repetidos = 0
    for i in range(n):
        tipo = tipos_base[i % len(tipos_base)]
        if lista and lista[-1]["tipo"] == tipo:
            repetidos += 1
            if repetidos >= 2:      # §5.2: máximo 2 del mismo tipo seguidos
                tipo = "basura" if tipo != "basura" else "meteoritos"
                repetidos = 0
        else:
            repetidos = 0
        o = {"tipo": tipo, "espera": round(rng.uniform(1.6, 2.4) if perfil != "estrella" else rng.uniform(1.0, 1.7), 2)}
        if tipo == "meteoritos":
            o["n"] = {"semilla": 4, "brote": 6, "estrella": 8}[perfil] + s
        elif tipo == "formacion":
            o["n"] = {"semilla": 4, "brote": 5, "estrella": 6}[perfil]
            o["forma"] = rng.choice(["onda", "onda", "v"])
        elif tipo == "basura":
            o["n"] = {"semilla": 2, "brote": 3, "estrella": 4}[perfil]
        elif tipo == "torretas":
            o["n"] = 1 if perfil != "estrella" else 2
            o["abanico"] = perfil == "estrella" and s >= 2
        lista.append(o)
    lista[0]["checkpoint"] = "inicio"
    lista[n // 2]["checkpoint"] = "mitad"
    # una cápsula de arma en cada sector y una especial (mini-Cometas o imán) a mitad (§5.4)
    lista[1]["capsula"] = "arma"
    lista[n // 2 + 1]["capsula"] = CAPSULAS[1 + (s % 2)]
    if s == 1:
        lista[-2]["capsula"] = "supernova"   # muy rara: una por ruta como máximo
    lista[-1]["destello"] = True            # §9.2: el destello suelto viaja con la oleada final
    lista[-1]["espera"] = max(lista[-1]["espera"], 2.0)
    return lista


def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    for i, (origen, destino, jefe, proyectil, patrones) in enumerate(RUTAS):
        rng = random.Random(1000 + i * 37)
        id_ruta = f"{origen}_{destino}"
        tercera_etapa = ORDEN.index(destino) >= ORDEN.index("melodia")    # §12: por orden del mapa
        perfiles = {}
        for perfil, sectores, por_sector in (("semilla", 2, 6), ("brote", 3, 7),
                                             ("estrella", 4 if tercera_etapa else 3, 8)):
            fases = [["rebota", "abre"]] if perfil == "semilla" else [patrones[perfil]]
            if perfil == "estrella":
                fases.append(patrones["estrella_2"])
            perfiles[perfil] = {
                "sectores": [{"oleadas": oleadas_sector(rng, perfil, s, por_sector)} for s in range(sectores)],
                "jefe": {"id": jefe, "vida": VIDA_JEFE[perfil], "fases": fases, "proyectil": proyectil},
                "coleccionauta": {"provoca": f"viaje_provoca_{id_ruta}", "huye": f"viaje_huye_{destino}", "bolsas": 3},
            }
        video = RAIZ / "assets" / "video" / "viaje" / f"viaje_{origen}_a_{destino}_despegue.ogv"
        datos = {
            "_fuente": "Generado por herramientas/generar_rutas_viaje.py (punto de partida para disenador-niveles).",
            "id_ruta": id_ruta, "origen": origen, "destino": destino,
            "video": {
                "despegue": f"res://assets/video/viaje/viaje_{origen}_a_{destino}_despegue.ogv" if video.exists() else "",
                "llegada": f"res://assets/video/viaje/viaje_{origen}_a_{destino}_llegada.ogv" if video.exists() else "",
                "empalme": f"res://assets/video/viaje/empalme/{id_ruta}.png" if video.exists() else "",
                "presentacion": f"res://assets/video/presentacion/presentacion_{destino}.ogv"
                if (RAIZ / "assets" / "video" / "presentacion" / f"presentacion_{destino}.ogv").exists() else "",
            },
            "perfiles": perfiles,
        }
        (SALIDA / f"{id_ruta}.json").write_text(json.dumps(datos, ensure_ascii=False, indent="\t"), encoding="utf-8")
        print("ruta", id_ruta, {p: len(v["sectores"]) for p, v in perfiles.items()})


if __name__ == "__main__":
    main()
