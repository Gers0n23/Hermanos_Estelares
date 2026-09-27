"""Genera los 10 niveles de Parejas de Coco para Maxi (semilla) y Nicole (brote), zonas 1-5.
Tambien escribe las lineas de voz nuevas (TSV). Uso: python herramientas/generar_parejas.py
"""
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
V = 'voces/arcoiris/emparejar/'
ZONAS = ['zona1_claro', 'zona2_charcos', 'zona3_chupetines', 'zona4_islotes', 'zona5_cima']


def el(figura, color=None, **extra):
    d = {'figura': figura}
    if color:
        d['color'] = color
    d.update(extra)
    return d


def par(id_pareja, figura, color=None, voz=None, especial=False, fijo=False, a=None, b=None):
    ea = dict(a) if a else el(figura, color)
    eb = dict(b) if b else el(figura, color)
    ea['id'] = id_pareja + '_a'
    eb['id'] = id_pareja + '_b'
    p = {'id_pareja': id_pareja, 'elemento_a': ea, 'elemento_b': eb}
    if voz:
        p['voz'] = voz
    if especial:
        p['especial'] = True
    if fijo:
        p['fijo'] = True
    return p


# --- Pools -----------------------------------------------------------------------------------
FIGURAS = [
    par('estrella', 'estrella', '#FFCB3D'), par('corazon', 'corazon', '#F26CA8'),
    par('circulo_azul', 'circulo', '#4A8BE0'), par('triangulo_verde', 'triangulo', '#7DD87A'),
    par('flor_lila', 'flor', '#B48CE8'), par('luna_celeste', 'luna', '#6FD6E8'),
    par('gota_turquesa', 'gota', '#45C6C0'), par('cuadrado_naranjo', 'cuadrado', '#FF9F4A'),
    par('arcoiris', 'arcoiris'), par('rombo_rojo', 'rombo', '#FF6B6B'),
]
DINOS = [par('trex', 'trex'), par('spinosaurio', 'spinosaurio'), par('carnotauro', 'carnotauro'), par('huevo', 'huevo')]
VEHICULOS = [par('auto', 'auto'), par('bus', 'bus'), par('bomberos', 'bomberos'), par('cohete', 'cohete')]


def mama_bebe(id_pareja, figura, color=None):
    return par(id_pareja, figura, a=el(figura, color, escala=1.0), b=el(figura, color, escala=0.55))


MAMA_DINOS = [mama_bebe('trex', 'trex'), mama_bebe('spinosaurio', 'spinosaurio'), mama_bebe('carnotauro', 'carnotauro'), mama_bebe('huevo', 'huevo')]
MAMA_MIX = [mama_bebe('auto', 'auto'), mama_bebe('bus', 'bus'), mama_bebe('bomberos', 'bomberos'), mama_bebe('cohete', 'cohete'),
            mama_bebe('estrella', 'estrella', '#FFCB3D'), mama_bebe('corazon', 'corazon', '#F26CA8'), mama_bebe('trex', 'trex')]

PAISES = {
    'chile': '¡Chile! ¡Nuestro país!', 'argentina': '¡Argentina!', 'peru': '¡Perú!', 'brasil': '¡Brasil!',
    'colombia': '¡Colombia!', 'japon': '¡Japón!', 'china': '¡China!', 'corea_sur': '¡Corea del Sur!',
    'eeuu': '¡Estados Unidos!', 'alemania': '¡Alemania!', 'francia': '¡Francia!', 'italia': '¡Italia!',
    'espana': '¡España!', 'suecia': '¡Suecia!',
}


def bandera(pais, fijo=False):
    return par('bandera_' + pais, 'bandera_' + pais, voz=V + 'paises/%s.wav' % pais, fijo=fijo)


BANDERAS_MAXI = [bandera('chile', True), bandera('japon', True), bandera('francia'), bandera('italia')]
BANDERAS_NICOLE = [bandera('chile', True)] + [bandera(p) for p in PAISES if p != 'chile']

ANIMALES = [par('jirafa', 'jirafa'), par('pony_rosa', 'pony', '#F7A8D0'), par('pony_lila', 'pony', '#B48CE8'),
            par('gatito', 'gatito', '#FF9F4A'), par('gatito_gris', 'gatito', '#A9B4C8')]
ROPA = [par('vestido_rosa', 'vestido', '#F26CA8'), par('vestido_turquesa', 'vestido', '#45C6C0'),
        par('zapato_lila', 'zapato', '#B48CE8'), par('zapato_rosa', 'zapato', '#F26CA8'),
        par('corona', 'corona'), par('mono', 'mono', '#F26CA8')]
CORAZONES = [par('corazon_rosa', 'corazon', '#F26CA8'), par('corazon_lila', 'corazon', '#B48CE8')]
FIGURAS_NICOLE = [par('corazon_magico', 'corazon', '#F26CA8', especial=True, fijo=True),
                  par('estrella', 'estrella', '#FFCB3D'), par('flor_lila', 'flor', '#B48CE8'),
                  par('gota_turquesa', 'gota', '#45C6C0'), par('luna_celeste', 'luna', '#6FD6E8'),
                  par('arcoiris', 'arcoiris'), par('sol', 'sol'), par('rombo_rojo', 'rombo', '#FF6B6B')]

COLORES = [  # color <-> cosa de ese color (Nicole, zona 4)
    ('amarillo', '#FFCB3D', el('jirafa'), '¡Amarillo, como la jirafa!'),
    ('rosado', '#F7A8D0', el('pony', '#F7A8D0'), '¡Rosado, como el pony!'),
    ('naranjo', '#FF9F4A', el('gatito', '#FF9F4A'), '¡Naranjo, como el gatito!'),
    ('rojo', '#E8423F', el('corazon', '#E8423F'), '¡Rojo, como el corazón!'),
    ('lila', '#B48CE8', el('flor', '#B48CE8'), '¡Lila, como la flor!'),
    ('azul', '#4A8BE0', el('gota', '#4A8BE0'), '¡Azul, como la gota de agua!'),
    ('verde', '#7DD87A', el('hoja'), '¡Verde, como la hoja!'),
]
POOL_COLORES = [par('color_' + c, '', voz=V + 'colores/%s.wav' % c, a=el('mancha', hexa), b=cosa) for c, hexa, cosa, _ in COLORES]

LETRAS = [  # letra, nombre de la letra, cosa, color, texto del par
    ('S', 'ese', 'sol', None, 'sol'), ('L', 'ele', 'luna', '#6FD6E8', 'luna'), ('G', 'ge', 'gatito', '#FF9F4A', 'gato'),
    ('J', 'jota', 'jirafa', None, 'jirafa'), ('P', 'pe', 'pony', '#F7A8D0', 'pony'), ('E', 'e', 'estrella', '#FFCB3D', 'estrella'),
    ('C', 'ce', 'corazon', '#F26CA8', 'corazón'), ('F', 'efe', 'flor', '#B48CE8', 'flor'), ('A', 'a', 'arcoiris', None, 'arcoíris'),
    ('V', 've', 'vestido', '#F26CA8', 'vestido'), ('D', 'de', 'trex', None, 'dinosaurio'), ('Z', 'zeta', 'zapato', '#B48CE8', 'zapato'),
]
POOL_LETRAS = []
for letra, nombre, figura, color, palabra in LETRAS:
    clave = letra.lower()
    POOL_LETRAS.append(par('letra_' + clave, '', voz=V + 'letras/%s_%s.wav' % (clave, palabra.replace('í', 'i').replace('ó', 'o')),
                           a=el('', None, estilo='letra', letra=letra, voz_toque=V + 'letras/letra_%s.wav' % clave),
                           b=el(figura, color)))
for p in POOL_LETRAS:
    p['elemento_a'].pop('figura', None)


def disp(pares):
    return {2: (1, 4), 3: (2, 3), 4: (2, 4), 5: (2, 5), 6: (3, 4)}[pares]


def ronda(tema, pool, cantidad, intro=None, pista=None, extra=None, lineas=None):
    filas, columnas = disp(cantidad)
    r = {'tema': tema, 'cantidad': cantidad, 'disposicion': {'filas': filas, 'columnas': columnas}}
    voces = dict(lineas or {})
    if intro:
        voces['intro_ronda'] = intro
    if pista:
        voces['pista'] = pista
    if voces:
        r['lineas_voz'] = voces
    if extra:
        r.update(extra)
    r['pool'] = pool
    return r


# --- Voces nuevas ----------------------------------------------------------------------------
VOCES = []  # (ruta, texto, personaje)


def voz(ruta, texto, personaje='coco'):
    VOCES.append((ruta, texto, personaje))
    return ruta


S = V + 'semilla/'
B = V + 'brote/'
intro_s = {
    1: voz(S + 'intro_z1.wav', '¡Hola, Maxi! ¡Busca dos iguales y tócalas!'),
    2: S + 'intro_01.wav',
    3: voz(S + 'intro_z3.wav', '¡Maxi! ¡Hay dinosaurios y autos! ¡Toca dos iguales!'),
    4: voz(S + 'intro_z4.wav', '¡Maxi, mira! Una mamá grande y su bebé chiquitito. ¡Júntalos!'),
    5: voz(S + 'intro_z5.wav', '¡Las cartas bailan, Maxi! ¡Toca dos iguales!'),
}
r_s = {
    'dinos': voz(S + 'ronda_dinos.wav', '¡Ahora, dinosaurios! ¡Grrr!'),
    'autos': voz(S + 'ronda_autos.wav', '¡Ahora, autos! ¡Brum, brum!'),
    'todos': voz(S + 'ronda_todos.wav', '¡Dinosaurios y autos, todos juntos!'),
    'mama': voz(S + 'ronda_mama_bebe.wav', '¡Más mamás con sus bebés!'),
    'banderas': voz(S + 'ronda_banderas.wav', '¡Ahora, banderas de países! ¡Toca dos iguales!'),
    'bailan': voz(S + 'ronda_bailan.wav', '¡Más cartas bailarinas!'),
}
superada_s = [voz(S + 'ronda_superada_01.wav', '¡Siii! ¡Otra ronda!'), voz(S + 'ronda_superada_02.wav', '¡Bravo, Maxi! ¡Vienen más!'),
              voz(S + 'ronda_superada_03.wav', '¡Muy bien! ¡Vamos a otra!')]
victoria_s = voz(S + 'victoria_rondas_01.wav', '¡Terminaste todas las rondas, Maxi! ¡Eres un campeón!')
acierto_mama = [voz(S + 'acierto_mama_01.wav', '¡La mamá y su bebé!'), voz(S + 'acierto_mama_02.wav', '¡Juntitos!'),
                voz(S + 'acierto_mama_03.wav', '¡Siii! ¡Encontraste al bebé!')]
pista_mama = voz(S + 'pista_mama.wav', 'Busca una grande y una chiquitita que sean iguales.', 'cometa')
pista_bailan = voz(S + 'pista_bailan.wav', 'Las cartas bailan. ¡Toca dos iguales, Maxi!', 'cometa')
pista_banderas_s = voz(S + 'pista_banderas.wav', 'Mira los colores de las banderas. ¡Toca dos iguales!', 'cometa')

intro_b = {
    1: voz(B + 'intro_z1.wav', '¡Hola, Nicole! Hoy jugamos a las parejas. Primero, con las cartas a la vista. ¡Toca dos iguales!'),
    2: voz(B + 'intro_z2.wav', '¡Nicole! Ahora mis cartas se esconden. Da vuelta dos, y busca las que son iguales.'),
    3: B + 'intro_01.wav',
    4: voz(B + 'intro_z4.wav', '¡Nicole! Cada color busca una cosa de su mismo color. La mancha amarilla va con la jirafa amarilla.'),
    5: voz(B + 'intro_z5.wav', '¡Nicole, juguemos con letras! Cada dibujo busca la letra con que empieza. Sol empieza con la ese.'),
}
r_b = {
    'ropa': voz(B + 'ronda_ropa.wav', '¡Ahora, ropa linda para vestirse!'),
    'tapadas': voz(B + 'ronda_tapadas.wav', '¡Sorpresa! Ahora las cartas se esconden. ¡Recuerda dónde están!'),
    'mezcla': voz(B + 'ronda_mezcla.wav', '¡Ahora, un poco de todo!'),
    'figuras': voz(B + 'ronda_figuras.wav', '¡Mis figuras de colores! Y hay un corazón mágico escondido.'),
    'colores_tapadas': voz(B + 'ronda_colores_tapadas.wav', 'Ahora los colores se esconden. ¡Búscalos!'),
    'letras_tapadas': voz(B + 'ronda_letras_tapadas.wav', 'Ahora las letras se esconden. ¡Tú puedes, Nicole!'),
    'banderas': voz(B + 'ronda_banderas.wav', '¡Banderas de países! Busca las dos iguales, y te digo de qué país son.'),
}
superada_b = [voz(B + 'ronda_superada_01.wav', '¡Ronda lista! ¡Vamos por otra!'), voz(B + 'ronda_superada_02.wav', '¡Qué bien lo hiciste, Nicole!'),
              voz(B + 'ronda_superada_03.wav', '¡Increíble! ¡Viene la siguiente!')]
victoria_b = voz(B + 'victoria_rondas_01.wav', '¡Terminaste todas las rondas, Nicole! ¡Eres una campeona!')
pista_vista = voz(B + 'pista_vista.wav', 'Toca dos cartas que sean iguales. ¡Tú puedes, Nicole!', 'cometa')
pista_colores = voz(B + 'pista_colores.wav', 'Busca la cosa que tiene el mismo color de la mancha.', 'cometa')
pista_letras = voz(B + 'pista_letras.wav', 'Toca una letra y escucha cómo se llama. Después busca el dibujo que empieza así.', 'cometa')
pista_banderas_b = voz(B + 'pista_banderas.wav', 'Mira bien los colores de cada bandera, y busca su pareja.', 'cometa')

for pais, texto in PAISES.items():
    voz(V + 'paises/%s.wav' % pais, texto)
for c, hexa, cosa, texto in COLORES:
    voz(V + 'colores/%s.wav' % c, texto)
for letra, nombre, figura, color, palabra in LETRAS:
    clave = letra.lower()
    voz(V + 'letras/%s_%s.wav' % (clave, palabra.replace('í', 'i').replace('ó', 'o')), '¡%s de %s!' % (nombre.capitalize(), palabra))
    voz(V + 'letras/letra_%s.wav' % clave, 'La letra %s.' % nombre)

# --- Niveles ---------------------------------------------------------------------------------
TAPADAS_Z1 = {'oculto': True, 'tiempo_volteo_ms': 1800, 'ayuda_tras_fallos': 2}
TAPADAS = {'oculto': True, 'tiempo_volteo_ms': 1600, 'ayuda_tras_fallos': 3}
VISTA = {'oculto': False, 'ayuda_tras_fallos': None}

semilla = {
    1: ('figuras, dinos y autos', [
        ronda('figuras', FIGURAS, 2),
        ronda('dinos', DINOS[:3], 2, r_s['dinos']),
        ronda('autos', VEHICULOS, 3, r_s['autos'])]),
    2: ('figuras, dinos y autos', [
        ronda('figuras', FIGURAS, 3),
        ronda('dinos', DINOS, 3, r_s['dinos']),
        ronda('autos', VEHICULOS, 3, r_s['autos'])]),
    3: ('figuras con dinos y autos', [
        ronda('figuras y gustos', FIGURAS[:6] + [DINOS[0], VEHICULOS[0]], 3),
        ronda('dinos', DINOS, 4, r_s['dinos']),
        ronda('todos', DINOS + VEHICULOS, 4, r_s['todos'])]),
    4: ('mama y bebe, banderas', [
        ronda('mama y bebe: dinos', MAMA_DINOS, 3, None, pista_mama, {'modo': 'correspondencia'}, {'acierto_par': acierto_mama}),
        ronda('mama y bebe', MAMA_MIX, 4, r_s['mama'], pista_mama, {'modo': 'correspondencia'}, {'acierto_par': acierto_mama}),
        ronda('banderas', BANDERAS_MAXI, 3, r_s['banderas'], pista_banderas_s)]),
    5: ('cartas que bailan, banderas', [
        ronda('bailan: dinos y autos', DINOS + VEHICULOS, 4, None, pista_bailan, {'cartas_bailan': 1}),
        ronda('bailan: todo', DINOS + VEHICULOS + FIGURAS[:6], 5, r_s['bailan'], pista_bailan, {'cartas_bailan': 1}),
        ronda('banderas que bailan', BANDERAS_MAXI, 3, r_s['banderas'], pista_banderas_s, {'cartas_bailan': 1})]),
}
brote = {
    1: ('animales, ropa y primera memoria', [
        ronda('animales', ANIMALES, 3, None, pista_vista, VISTA),
        ronda('ropa', ROPA, 4, r_b['ropa'], pista_vista, VISTA),
        ronda('tapadas', ANIMALES + ROPA + CORAZONES, 4, r_b['tapadas'], None, TAPADAS_Z1)]),
    2: ('memoria: animales y ropa', [
        ronda('animales', ANIMALES, 3, None, None, TAPADAS),
        ronda('ropa', ROPA, 4, r_b['ropa'], None, TAPADAS),
        ronda('mezcla', ANIMALES + ROPA + CORAZONES, 4, r_b['mezcla'], None, TAPADAS)]),
    3: ('memoria: animales, corazon magico, banderas', [
        ronda('animales', ANIMALES + CORAZONES, 4, None, None, {'oculto': True, 'tiempo_volteo_ms': 1400, 'ayuda_tras_fallos': 3}),
        ronda('figuras', FIGURAS_NICOLE, 5, r_b['figuras'], None, {'oculto': True, 'tiempo_volteo_ms': 1400, 'ayuda_tras_fallos': 3}),
        ronda('banderas', BANDERAS_NICOLE, 4, r_b['banderas'], pista_banderas_b, {'oculto': True, 'tiempo_volteo_ms': 1500, 'ayuda_tras_fallos': 3})]),
    4: ('color y cosa de ese color, banderas', [
        ronda('color y cosa', POOL_COLORES, 4, None, pista_colores, dict(VISTA, modo='correspondencia')),
        ronda('color y cosa, tapadas', POOL_COLORES, 5, r_b['colores_tapadas'], pista_colores, dict(TAPADAS, modo='correspondencia')),
        ronda('banderas', BANDERAS_NICOLE, 5, r_b['banderas'], pista_banderas_b, {'oculto': True, 'tiempo_volteo_ms': 1500, 'ayuda_tras_fallos': 3})]),
    5: ('dibujo y su letra inicial, banderas', [
        ronda('letras', POOL_LETRAS, 4, None, pista_letras, dict(VISTA, modo='correspondencia')),
        ronda('letras, tapadas', POOL_LETRAS, 6, r_b['letras_tapadas'], pista_letras, dict(TAPADAS, modo='correspondencia')),
        ronda('banderas', BANDERAS_NICOLE, 6, r_b['banderas'], pista_banderas_b, {'oculto': True, 'tiempo_volteo_ms': 1500, 'ayuda_tras_fallos': 3})]),
}


def base_semilla(z, tema, rondas):
    return {
        'id_nivel': 'arcoiris_emparejar_semilla_01' if z == 2 else 'arcoiris_z%d_parejas_semilla' % z,
        'motor': 'emparejar', 'perfil': 'semilla', 'planeta': 'arcoiris', 'zona': ZONAS[z - 1], 'tema': tema,
        'anfitrion_id': 'coco', 'fondo_id': 'planeta_arcoiris', 'dificultad': 'rondas (PO 27-Sep-2026)',
        'modo': 'identico', 'oculto': False, 'limite_intentos': None, 'tiempo_volteo_ms': 700,
        'ayuda_tras_fallos': None, 'halo_idle': True,
        'lineas_voz': {
            'intro': intro_s[z], 'pista': S + 'pista_01.wav',
            'acierto_par': [S + 'acierto_par_01.wav', S + 'acierto_par_02.wav', S + 'acierto_par_03.wav'],
            'no_es_este': [S + 'no_es_este_01.wav'], 'ronda_superada': superada_s, 'victoria_final': victoria_s,
        },
        'rondas': rondas,
    }


def base_brote(z, tema, rondas):
    return {
        'id_nivel': 'arcoiris_emparejar_brote_01' if z == 3 else 'arcoiris_z%d_parejas_brote' % z,
        'motor': 'emparejar', 'perfil': 'brote', 'planeta': 'arcoiris', 'zona': ZONAS[z - 1], 'tema': tema,
        'anfitrion_id': 'coco', 'fondo_id': 'planeta_arcoiris', 'dificultad': 'rondas (PO 27-Sep-2026)',
        'modo': 'identico', 'oculto': False, 'limite_intentos': None, 'tiempo_volteo_ms': 1600,
        'ayuda_tras_fallos': None, 'halo_idle': False,
        'lineas_voz': {
            'intro': intro_b[z], 'pista': B + 'pista_01.wav', 'ayuda': B + 'ayuda_01.wav',
            'acierto_par': [B + 'acierto_par_01.wav', B + 'acierto_par_02.wav', B + 'acierto_par_03.wav'],
            'no_es_este': [B + 'no_es_este_01.wav', B + 'no_es_este_02.wav'],
            'acierto_especial': B + 'acierto_especial_01.wav',
            'ronda_superada': superada_b, 'victoria_final': victoria_b,
        },
        'rondas': rondas,
    }


for z in range(1, 6):
    for perfil, datos, base in (('semilla', semilla, base_semilla), ('brote', brote, base_brote)):
        tema, rondas = datos[z]
        nivel = base(z, tema, rondas)
        ruta = os.path.join(RAIZ, 'datos', 'niveles', 'arcoiris', ZONAS[z - 1], 'parejas_%s.json' % perfil)
        with open(ruta, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(nivel, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print('nivel:', ruta)

# TSV para el TTS de Windows (sin directivas de personaje, lo lee generar_voces_tts.ps1).
with open(os.path.join(RAIZ, 'assets', 'audio', 'voces', 'arcoiris', 'emparejar', 'tmp_windows.tsv'), 'w', encoding='utf-8') as f:
    for ruta, texto, _ in VOCES:
        f.write('%s\t%s\n' % (ruta, texto))
# Bloque para agregar a lineas_tts.tsv (con directivas de personaje, para fal.ai en el futuro).
with open(os.path.join(os.path.dirname(__file__), 'bloque_tsv.txt'), 'w', encoding='utf-8') as f:
    actual = None
    for ruta, texto, personaje in VOCES:
        if personaje != actual:
            f.write('# personaje: %s\n' % personaje)
            actual = personaje
        f.write('%s\t%s\n' % (ruta, texto))
print('voces nuevas:', len(VOCES))
