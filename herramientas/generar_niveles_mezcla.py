"""Genera los 5 niveles de Sofia del "Taller de pinturas de Coco" (motor mezclar) y su lista de voces.

Pedido del PO 27-Sep-2026: la mezcla de Sofia pasa a recetas con proporciones, memoria, frasco que
atrapa gotas, agitado y 3 latas por mural (docs/fichas/motor-mezclar.md). Escribe:
- datos/niveles/arcoiris/<zona>/mezcla_estrella.json
- assets/audio/voces/arcoiris/mezclar/lineas_tts.tsv (voces PROVISIONALES, TTS de Windows)

Los niveles reutilizan el id_nivel de la antigua "lluvia_estrella" para que Sofia no pierda el
avance del mapa (la estacion es la misma; solo cambia el juego que abre).

Uso: python herramientas/generar_niveles_mezcla.py
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
VOZ = "voces/arcoiris/mezclar/"

# Una fila por zona: curva de dificultad de Sofia (8 anos).
ZONAS = [
    {
        "zona": "zona1_claro", "n": 1,
        "variante": "primeras recetas: tres de 1+1 y la primera de proporciones (verde limon 2+1); el frasco muestra cuantas gotas lleva; la receta queda a la vista hasta que Sofia toca el visto bueno",
        "pedidos": ["verde", "naranja", "violeta", "verde_limon"],
        "velocidad_caida": 105, "variacion_velocidad": 0.0, "elementos_simultaneos": 2, "intervalo_gotas_s": 1.3,
        "probabilidad_util": 0.65, "ranuras_visibles": True, "memorizar_s": 0, "murales": 2,
        "dibujos_mural": ["flor", "casa"], "umbrales_estrellitas": {"tres": 2, "dos": 5},
    },
    {
        "zona": "zona2_charcos", "n": 2,
        "variante": "proporciones 2+1: verde limon, verde azulado, mango, tomate, fucsia y anil (el orden de cantidades cambia el color)",
        "pedidos": ["verde_limon", "verde_azulado", "mango", "tomate", "fucsia", "anil"],
        "velocidad_caida": 120, "variacion_velocidad": 0.15, "elementos_simultaneos": 3, "intervalo_gotas_s": 1.1,
        "probabilidad_util": 0.55, "ranuras_visibles": True, "memorizar_s": 0, "murales": 2,
        "dibujos_mural": ["pez", "pony"], "umbrales_estrellitas": {"tres": 3, "dos": 6},
    },
    {
        "zona": "zona3_chupetines", "n": 3,
        "variante": "llega el blanco (rosado 1+2, celeste 1+2, durazno) y la gota gris que ensucia: hay que dejarla pasar; velocidades distintas",
        "pedidos": ["rosado", "celeste", "durazno", "fucsia", "verde_azulado", "mango"],
        "velocidad_caida": 130, "variacion_velocidad": 0.35, "elementos_simultaneos": 3, "intervalo_gotas_s": 1.0,
        "probabilidad_util": 0.5, "ranuras_visibles": True, "memorizar_s": 0, "murales": 2,
        "gota_distractora": {"probabilidad": 0.2},
        "dibujos_mural": ["cohete", "arcoiris"], "umbrales_estrellitas": {"tres": 3, "dos": 7},
    },
    {
        "zona": "zona4_islotes", "n": 4,
        "variante": "recetas de 3 y 4 gotas (cafe, lila, verde clarito, turquesa, verde oliva, chocolate) y el frasco ya no muestra cuantas faltan: memoria pura",
        "pedidos": ["cafe", "lila", "verde_claro", "turquesa", "verde_oliva", "chocolate", "durazno"],
        "velocidad_caida": 135, "variacion_velocidad": 0.3, "elementos_simultaneos": 3, "intervalo_gotas_s": 1.0,
        "probabilidad_util": 0.5, "ranuras_visibles": False, "memorizar_s": 0, "murales": 2,
        "gota_distractora": {"probabilidad": 0.12},
        "dibujos_mural": ["casa", "pez"], "umbrales_estrellitas": {"tres": 4, "dos": 8},
    },
    {
        "zona": "zona5_cima", "n": 5,
        "variante": "tres murales con todo el recetario: la receta se ve solo un ratito (solcito de 6 s despues de que Coco la lee), gota gris y caida mas rapida",
        "pedidos": ["verde_limon", "verde_azulado", "mango", "tomate", "fucsia", "anil", "rosado", "celeste",
                    "durazno", "cafe", "lila", "verde_claro", "turquesa", "verde_oliva", "chocolate"],
        "velocidad_caida": 145, "variacion_velocidad": 0.35, "elementos_simultaneos": 3, "intervalo_gotas_s": 0.9,
        "probabilidad_util": 0.5, "ranuras_visibles": False, "memorizar_s": 6, "murales": 3,
        "gota_distractora": {"probabilidad": 0.15},
        "dibujos_mural": ["pony", "cohete", "arcoiris"], "umbrales_estrellitas": {"tres": 5, "dos": 10},
    },
]

# Sin bichos en ningun nivel donde juegue Nicole o Sofia (perfil-jugadores; auditoria UX HE-40 R1/R2).
PROHIBIDOS = ("mariposa", "abeja", "arana", "araña", "bicho", "insecto", "catarina", "gusano", "hormiga", "mosca", "libelula")

# Parametros comunes (disenador-mecanicas HE-40 #13, 28-Sep-2026, PROVISIONAL): las gotas nuevas
# nunca caen a menos de 190 px en x de otra que siga arriba, y la 1.a gota equivocada de una lata solo
# sale escupida (las capas buenas se quedan); recien la 2.a vacia el frasco.
COMUNES = {"separacion_min_gotas_px": 190, "fallos_para_reiniciar_lata": 2}

RECETAS_VOZ = {
    "verde": "Verde: una gota amarilla y una gota azul.",
    "naranja": "Naranja: una gota roja y una gota amarilla.",
    "violeta": "Violeta: una gota roja y una gota azul.",
    "verde_limon": "Verde limón: dos gotas amarillas y una azul.",
    "verde_azulado": "Verde azulado: dos gotas azules y una amarilla.",
    "mango": "Color mango: dos gotas amarillas y una roja.",
    "tomate": "Rojo tomate: dos gotas rojas y una amarilla.",
    "fucsia": "Fucsia: dos gotas rojas y una azul.",
    "anil": "Añil: dos gotas azules y una roja.",
    "rosado": "Rosado: una gota roja y dos blancas.",
    "celeste": "Celeste: una gota azul y dos blancas.",
    "durazno": "Color durazno: una roja, una amarilla y una blanca.",
    "cafe": "Café: una roja, una amarilla y una azul.",
    "lila": "Lila: una roja, una azul y una blanca.",
    "verde_claro": "Verde clarito: una amarilla, una azul y una blanca.",
    "turquesa": "Turquesa: dos azules, una amarilla y una blanca.",
    "verde_oliva": "Verde oliva: dos amarillas, una azul y una roja.",
    "chocolate": "Chocolate: dos rojas, una amarilla y una azul.",
}

# Textos reescritos por el guionista (docs/guiones/zonas_arcoiris.md §3 y §4.5, 28-Sep-2026).
INTROS = {
    1: "¡Sofía, ayúdame a pintar mi mural! Mira la receta y memorízala. Después mueve el frasco, atrapa solo esas gotas... ¡y agítalo para mezclar!",
    2: "Ahora las recetas llevan más de una gota del mismo color. ¡Cuenta bien! Si entra una gota de más, la mezcla se ensucia.",
    3: "¡Llegó el blanco, que aclara los colores! Y cuidado con la gota gris: déjala pasar, que ensucia la pintura.",
    4: "Recetas de tres y cuatro gotas, y el frasco ya no te dice cuántas faltan. ¡Usa tu memoria!",
    5: "¡Tres murales en la cima! Esta vez la receta se ve solo un ratito. ¡Mírala bien, maestra pintora!",
}

PISTAS_ZONA = {
    2: "Mira cuántas gotas de cada color lleva la receta. ¡A veces son dos iguales!",
    3: "La gota gris es tramposa: déjala pasar y atrapa solo las de la receta.",
    4: "Cuenta las gotas con los dedos mientras miras la receta. ¡Así no se te olvida ninguna!",
    5: "Di los colores en voz alta mientras se ve la receta. ¡Así se te quedan en la cabeza!",
}

LINEAS = {
    "pista": "Mueve el frasco con el dedo y atrapa solo las gotas de la receta. Si no te acuerdas, toca la libreta, pero cuesta una estrellita.",
    "pista_agitar": "¡Agita el frasco de un lado a otro, o déjalo apretado, hasta que se llene el círculo dorado!",
    "memoriza": "¡Memorízala bien! Cuando estés lista, toca el visto bueno.",
    "memoriza_rapido": "¡Mírala bien, que se esconde en un ratito!",
    "a_atrapar_01": "¡Ahí vienen las gotas!",
    "a_atrapar_02": "¡A atrapar gotas!",
    "bien_01": "¡Esa sí!",
    "bien_02": "¡Bien atrapada!",
    "bien_03": "¡Justo!",
    "sucio_01": "¡Puaj! Esa gota no iba. Vaciamos el frasco y empezamos esta lata otra vez.",
    "sucio_02": "¡Uy, se ensució la mezcla! No importa: frasco limpio y a intentarlo de nuevo.",
    "sucio_03": "¡Glup! Esa no era de la receta. ¡Otra vez, que tú puedes!",
    "gris_01": "¡Pfff, se coló la gota gris! La muy tramposa... la próxima la dejamos pasar.",
    "escupe_01": "¡Puaj! Esa no va. ¡Fuera, gotita! Lo demás sigue bien.",
    "escupe_02": "¡Ptui! Esa no era de la receta. Tu mezcla sigue a salvo.",
    "a_mezclar": "¡Receta completa! Ahora agita el frasco de un lado a otro para mezclar.",
    "lata_01": "¡Una lata lista!",
    "lata_02": "¡Qué color más lindo!",
    "lata_03": "¡Perfecto! Otra lata para mi mural.",
    "revisar": "Aquí está la receta otra vez. Esta vez te cuesta una estrellita.",
    "mural_pedido_01": "¡Quiero pintar un mural nuevo! Mira: necesito estas tres latas.",
    "mural_pedido_02": "¡Otra pared para pintar! Estos son los colores que necesito.",
    "entregar": "¡Tres latas! Pásamelas, ¡voy a pintar!",
    "mural_listo_01": "¡Mira mi mural! ¡Quedó precioso gracias a ti, Sofía!",
    "mural_listo_02": "¡Qué obra de arte! ¡Eres una pintora increíble!",
}


def lineas_voz(z: dict) -> dict:
    n = z["n"]
    return {
        "intro": f"{VOZ}intro_z{n}.wav",
        "pista": f"{VOZ}pista_z{n}.wav" if n in PISTAS_ZONA else f"{VOZ}pista.wav",
        "pista_agitar": f"{VOZ}pista_agitar.wav",
        "memoriza": f"{VOZ}{'memoriza_rapido' if z['memorizar_s'] else 'memoriza'}.wav",
        "a_atrapar": [f"{VOZ}a_atrapar_01.wav", f"{VOZ}a_atrapar_02.wav"],
        "bien": [f"{VOZ}bien_01.wav", f"{VOZ}bien_02.wav", f"{VOZ}bien_03.wav"],
        "sucio": [f"{VOZ}sucio_01.wav", f"{VOZ}sucio_02.wav", f"{VOZ}sucio_03.wav"],
        "gris": [f"{VOZ}gris_01.wav"],
        "escupe": [f"{VOZ}escupe_01.wav", f"{VOZ}escupe_02.wav"],
        "a_mezclar": f"{VOZ}a_mezclar.wav",
        "lata_lista": [f"{VOZ}lata_01.wav", f"{VOZ}lata_02.wav", f"{VOZ}lata_03.wav"],
        "revisar": f"{VOZ}revisar.wav",
        "mural_pedido": [f"{VOZ}mural_pedido_01.wav", f"{VOZ}mural_pedido_02.wav"],
        "entregar": f"{VOZ}entregar.wav",
        "mural_listo": [f"{VOZ}mural_listo_01.wav", f"{VOZ}mural_listo_02.wav"],
        "victoria_final": ["voces/arcoiris/lluvia/estrella/victoria_01.wav", "voces/arcoiris/lluvia/estrella/victoria_02.wav"],
        "prefijo_recetas": f"{VOZ}recetas/",
        "prefijo_datos": "voces/arcoiris/lluvia/datos/",
    }


def main() -> None:
    for z in ZONAS:
        malos = [d for d in z["dibujos_mural"] if any(b in d for b in PROHIBIDOS)]
        if malos:
            raise SystemExit(f"ERROR: {z['zona']} tiene dibujos prohibidos (bichos): {malos}")
        nivel = {
            "id_nivel": f"arcoiris_z{z['n']}_lluvia_estrella",
            "motor": "mezclar",
            "perfil": "estrella",
            "planeta": "arcoiris",
            "zona": z["zona"],
            "tema": "taller de pinturas de Coco",
            "variante": z["variante"],
            "anfitrion_id": "coco",
            "fondo_id": "planeta_arcoiris",
        }
        for clave in ["pedidos", "velocidad_caida", "variacion_velocidad", "elementos_simultaneos", "intervalo_gotas_s",
                      "probabilidad_util", "ranuras_visibles", "memorizar_s", "murales", "gota_distractora",
                      "dibujos_mural", "umbrales_estrellitas"]:
            if clave in z:
                nivel[clave] = z[clave]
        nivel.update(COMUNES)
        nivel["tamano_gota"] = 84
        nivel["libreta_cuesta_estrellita"] = True
        nivel["lineas_voz"] = lineas_voz(z)
        ruta = RAIZ / "datos/niveles/arcoiris" / z["zona"] / "mezcla_estrella.json"
        ruta.write_text(json.dumps(nivel, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("nivel:", ruta.relative_to(RAIZ))

    filas = [
        "# Voces PROVISIONALES del \"Taller de pinturas de Coco\" (motor mezclar, Sofia), TTS de Windows (Sabina).",
        "# Pasan a la voz oficial de Coco (fal.ai) cuando el PO apruebe el costo. Regenerar:",
        "# powershell -NoProfile -File herramientas/generar_voces_tts.ps1 -Lista assets/audio/voces/arcoiris/mezclar/lineas_tts.tsv",
    ]
    for n, texto in INTROS.items():
        filas.append(f"{VOZ}intro_z{n}.wav\t{texto}")
    for clave, texto in LINEAS.items():
        filas.append(f"{VOZ}{clave}.wav\t{texto}")
    for n, texto in PISTAS_ZONA.items():
        filas.append(f"{VOZ}pista_z{n}.wav\t{texto}")
    for color, texto in RECETAS_VOZ.items():
        filas.append(f"{VOZ}recetas/{color}.wav\t{texto}")
    tsv = RAIZ / "assets/audio" / VOZ / "lineas_tts.tsv"
    tsv.parent.mkdir(parents=True, exist_ok=True)
    tsv.write_text("\n".join(filas) + "\n", encoding="utf-8")
    print("voces:", tsv.relative_to(RAIZ), len(filas) - 3, "lineas")


if __name__ == "__main__":
    main()
