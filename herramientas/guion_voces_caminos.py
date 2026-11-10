"""Escribe assets/audio/voces/animalia/caminos/lineas_tts.tsv con TODAS las líneas que usan los niveles de
«Cada quien a su casa» (motor caminos). Formato de los TSV del proyecto: ruta relativa a assets/audio/ <TAB>
texto, con la directiva '# personaje: <id>'. Toby es la voz de los juegos de Animalia.

Textos PROVISIONALES de dev-godot (HE-117) hasta que `guionista` los revise (HE-112). El juego funciona sin los
archivos de audio: el motor solo reproduce los que existen.

Uso: python3 herramientas/guion_voces_caminos.py
"""

import glob
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ZONA = {"zona1": "el campamento", "zona2": "la laguna", "zona3": "la pradera", "zona4": "el árbol de los nidos",
        "zona5": "el valle de los dinosaurios"}

INTRO = {
    "semilla": "¡Guau! Los animalitos de {zona} se perdieron. ¡Llévalos a su casita!",
    "brote": "¡Guau, guau! En {zona} cada animal quiere volver a su casa del mismo color. ¡Ayúdalos, Nicole!",
    "estrella": "¡Guau! Sofía, en {zona} cada animal tiene que llegar a su casa sin cruzar caminos. ¡Y que florezcan todas las baldosas!",
}
INSTRUCCION = {
    "semilla": "Toca un animalito y arrástralo hasta su casita.",
    "brote": "Arrastra desde cada animal hasta su casa. Los caminos no se pueden cruzar.",
    "estrella": "Une cada animal con su casa sin cruzar caminos y llena todo el tablero. Los puentes se cruzan derechito.",
}
INSTRUCCION_HABITAT = "Une cada animal con su hogar de verdad: ¿dónde vive cada uno? No se cruzan los caminos y se llena todo el tablero."
INSTRUCCION_LLENAR_BROTE = "Lleva a cada animal a su casa y haz que florezcan todas las baldosas."

FIJAS = {
    "comun/tablero_listo_01": "¡Todos en casa!",
    "comun/tablero_listo_02": "¡Guau, qué bien!",
    "comun/tablero_listo_03": "¡Otro más! ¡Vamos!",
    "comun/victoria_semilla_01": "¡Bravo, Maxi! ¡Todos los animalitos están en su casita!",
    "comun/victoria_semilla_02": "¡Guau, guau! ¡Lo lograste, Maxi!",
    "comun/victoria_brote_01": "¡Bravísimo, Nicole! ¡Cada quien llegó a su casa!",
    "comun/victoria_brote_02": "¡Qué caminos tan lindos, Nicole!",
    "comun/victoria_estrella_01": "¡Increíble, Sofía! ¡Resolviste todos los tableros!",
    "comun/victoria_estrella_02": "¡Guau! ¡Eres una experta en caminos, Sofía!",
    "comun/tormenta_semilla": "¡Uy, llovieron burbujas! ¡Plop, plop! ¡Juguemos otra vez!",
    "comun/tormenta_brote": "¡Ay, la tormenta de risa! ¡Nos mojamos todos! ¡Ja, ja!",
    "comun/tormenta_estrella": "¡La tormenta de risa! ¡Quedé empapado! Otra vez, ¡tú puedes!",
    "comun/otra_vez": "¡Otra vez!",
    "comun/regalo": "¡Te regalo un camino! Olfateé por dónde va.",
    "comun/ayuda_fuerte": "¡Hagámoslo juntos! Yo llevé a casi todos. ¡Falta uno!",
    "comun/descansar": "¿Descansamos un ratito? Puedes volver cuando quieras.",
    "comun/nube_presenta_semilla": "Mira la nubecita dormilona. ¡Llevemos a los animalitos antes de que despierte!",
    "comun/nube_presenta_brote": "¿Ves la nube? ¡Lleva a todos a su casa antes de que llegue la lluvia!",
    "comun/nube_presenta_estrella": "La nube trae una tormenta de risa. ¡Termina el tablero antes de que llegue!",
    "comun/guia_semilla": "¡Por aquí! Llévalo a su casita.",
    "comun/valvula_sopla": "¡Fuuu! Te abrí el camino.",
    "comun/faltan_flores": "¡Faltan flores! Haz que el camino pase por todas las baldosas.",
    "comun/record": "¡Récord nuevo! ¡Guau, guau!",
    "comun/primer_record": "¡Tu primer récord! Aquí queda tu banderita.",
    "comun/sin_borrones": "¡Sin borrones!",
    "comun/casa_late": "Mira la casita que brilla.",
    "comun/casa_ajena_01": "¡Aquí no vivo yo!",
    "comun/casa_ajena_02": "¡Esa no es mi casa!",
    "comun/pista_usada": "¡Sniff, sniff! El camino va por aquí.",
    "equipo/intro": "¡Juntos! Un solo tablero para todos. Cada uno lleva animales a su casa, ¡sin estorbarse!",
    "equipo/maxi_regalito": "¡Mira, Maxi, tu animalito se fue solito a su casa!",
    "equipo/maxi_brilla": "Maxi, lleva al que brilla.",
    "equipo/victoria": "¡Lo hicieron juntos! ¡Todos los animales en casa!",
    "equipo/coleccionauta_aspira": "¡Sluuurp! ¡Huellitas para mi colección!",
    "equipo/coleccionauta_estornuda": "¡Achís! ¡Uy, se me escaparon!",
    "equipo/toby_otra_vez": "¡No importa! ¡Otra vez, todos juntos!",
}

HABITAT_DATO = {
    "roquerio": "El roquerío: rocas junto al mar donde los lobos marinos toman sol.",
    "cueva_costa": "La cueva de la costa: un hueco fresquito en las rocas junto al mar.",
    "salar": "El salar: un lago blanco de sal en el desierto del norte de Chile.",
    "humedal": "El humedal: agua tranquila con juncos donde nadan aves elegantes.",
    "rio_bosque": "El río del bosque: agua fría que corre entre árboles del sur de Chile.",
    "tempano": "El témpano: un pedazo grande de hielo que flota en el mar helado.",
    "mar": "El mar abierto: agua profunda y azul, ¡lejos, lejos de la orilla!",
    "cordillera_nevada": "La cordillera nevada: montañas altas con nieve, en el sur de Chile.",
    "bosque_lluvioso": "El bosque lluvioso: árboles muy verdes donde llueve casi todo el año.",
    "estepa": "La estepa patagónica: pasto seco y mucho viento en el sur.",
    "bofedal": "El bofedal: un pasto mojadito y verde, arriba en el altiplano.",
    "cumbre": "La cumbre: la punta más alta de la montaña, donde el viento sopla fuerte.",
    "desierto": "El desierto: arena caliente y casi nada de lluvia.",
    "bambu": "El bambú: tallos largos y verdes que crecen muy rápido.",
    "acacia": "La acacia: un árbol de copa plana en la sabana de África.",
    "selva_tropical": "La selva tropical: calor, lluvia y árboles gigantes llenos de frutas.",
    "barranco": "El barranco: una pared de tierra con hoyitos para hacer nidos.",
    "nido_musgo": "El nido de musgo: una camita suave y redonda escondida en el bosque.",
    "tronco_roble": "El tronco de roble: un árbol viejo y duro del bosque del sur.",
    "eucalipto": "El eucalipto: un árbol de hojas que huelen fuerte, de Australia.",
    "bananero": "El bananero: una planta de hojas enormes que da plátanos.",
    "represa": "La represa: una pared de palitos y troncos que frena el agua del río.",
    "cueva_milodon": "La cueva del milodón: una cueva enorme de la Patagonia donde encontraron sus huellas.",
    "carpa_toby": "¡La carpa de Toby! Mi casita del campamento.",
}


def texto_para(ruta_rel, catalogo):
    clave = ruta_rel.replace("voces/animalia/caminos/", "").replace(".wav", "")
    if clave in FIJAS:
        return FIJAS[clave]
    if ruta_rel.startswith("voces/animalia/nombres/"):
        animal = os.path.basename(ruta_rel)[:-4]
        nombre = catalogo.get(animal, {}).get("nombre", animal.replace("_", " "))
        return "¡%s!" % (nombre[0].upper() + nombre[1:])
    if clave.startswith("habitats/"):
        casa = clave.split("/")[1]
        return HABITAT_DATO.get(casa, "¡%s!" % catalogo.get(casa, {}).get("nombre", casa))
    if clave.startswith("equipo/logro_"):
        n = clave.split("_")[-1]
        return "¡Igual llevamos a %s animales a su casa!" % n if n != "1" else "¡Igual llevamos a un animal a su casa!"
    if clave.startswith("zona"):
        zona, resto = clave.split("/")
        perfil, tipo = resto.split("_", 1)
        if tipo == "intro":
            return INTRO[perfil].format(zona=ZONA[zona])
        return None
    return None


def main():
    lineas = {}
    for ruta in sorted(glob.glob(os.path.join(RAIZ, "datos/niveles/animalia/*/caminos_*.json"))):
        nivel = json.load(open(ruta, encoding="utf-8"))
        cat = nivel.get("catalogo", {})
        perfil = nivel.get("perfil")
        habitat = nivel.get("casas") == "habitat"
        llenar = nivel.get("llenar")

        def visitar(v):
            if isinstance(v, str) and v.startswith("voces/animalia/"):
                t = texto_para(v, cat)
                if t is None and v.endswith("_instruccion.wav"):
                    t = INSTRUCCION_HABITAT if habitat else (INSTRUCCION_LLENAR_BROTE if perfil == "brote" and llenar else INSTRUCCION[perfil])
                if t is None:
                    raise SystemExit("sin texto: " + v)
                lineas[v] = t
            elif isinstance(v, list):
                for x in v:
                    visitar(x)
            elif isinstance(v, dict):
                for x in v.values():
                    visitar(x)
        visitar(nivel.get("lineas_voz", {}))
    salida = os.path.join(RAIZ, "assets/audio/voces/animalia/caminos/lineas_tts.tsv")
    os.makedirs(os.path.dirname(salida), exist_ok=True)
    with open(salida, "w", encoding="utf-8") as f:
        f.write("# Voces de «Cada quien a su casa» (motor caminos, Planeta Animalia; HE-117). Toby es la voz de los juegos.\n")
        f.write("# Textos PROVISIONALES de dev-godot hasta la revisión de guionista (HE-112). Generado por herramientas/guion_voces_caminos.py.\n")
        f.write("# Formato: ruta relativa a assets/audio/ <TAB> texto. La directiva '# personaje: <id>' elige la voz.\n")
        f.write("# Los nombres (voces/animalia/nombres/) son compartidos con los otros juegos de Animalia: no duplicar al grabar.\n")
        f.write("# personaje: toby\n")
        for ruta in sorted(lineas):
            f.write("%s\t%s\n" % (ruta, lineas[ruta]))
    print("escrito", os.path.relpath(salida, RAIZ), len(lineas), "lineas")


if __name__ == "__main__":
    main()
