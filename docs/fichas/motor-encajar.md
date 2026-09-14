# Ficha de motor — `encajar` ("Formas traviesas")

- **Autor**: Dev (implementación del 14-Sep-2026, a pedido del PO). Formaliza el motor que
  `docs/fichas/planeta-arcoiris.md` §2 dejaba especificado dentro de la ficha de nivel, más los
  campos nuevos que pide `docs/fichas/planeta-arcoiris-zonas.md` §3.2 y §4.
- **Estado**: implementado y verificado en Godot 4.7.1. **Pendiente de validación** por
  `disenador-mecanicas` (reglas y game feel), `disenador-niveles` (los 15 niveles son una propuesta
  de Dev), `guionista` (79 voces TTS provisionales) y `experto-ux-parvulo` (auditoría sobre build).
- **Código**: `scripts/motores/encajar/` (`motor_encajar.gd`, `pieza_encajar.gd`,
  `siluetas_encajar.gd`, `geometria_formas.gd`) y `escenas/minijuegos/encajar/motor_encajar.tscn`.
- **Niveles**: `datos/niveles/arcoiris/<zona>/formas_<perfil>.json` (5 zonas × 3 perfiles).
- **Voces**: `assets/audio/voces/arcoiris/formas/` (lista en `lineas_tts.tsv`).
- **QA**: `herramientas/qa_test_encajar.gd` (headless, las 15 variantes) y
  `herramientas/capturar_encajar.gd` (ventana real, arrastre con `push_input` + pantallazos).

---

## 1. La mecánica en una frase

Piezas con forma se arrastran desde una **bandeja** hasta su **silueta**; al soltarlas cerca
("imán"), si calzan, se encajan con un clic, chispas y un saltito.

## 2. Modelo: figuras y huecos

- Una **figura** agrupa uno o más **huecos**. Cada hueco genera su pieza.
  - Formas sueltas (Maxi, Nicole): cada figura tiene un solo hueco.
  - Figuras compuestas (Sofía): casa = cuadrado + triángulo.
  - Escena (Nicole, zona 5): huecos en posiciones fijas sobre un jardín.
  - Tangram (Sofía, zona 5): silueta unida y piezas que hay que girar.
- **Calce por geometría, no por nombre**: una pieza calza en un hueco si sus polígonos (ya girados)
  se superponen en ≥ 90 % del área. Así se resuelven solas las simetrías (un cuadrado girado 90°,
  un rectángulo de 90×150 girado que equivale a uno de 150×90) y los tamaños ("grande y chico").
- Las figuras sin `centro` se reparten solas en la zona del tablero. La bandeja achica las piezas
  con un factor común (se conservan los tamaños relativos), sin bajar de `lado_minimo_bandeja`. Al
  tomar una pieza vuelve a su tamaño real.
- La zona tocable de una pieza siempre mide ≥ 96 px de diámetro, aunque la forma sea delgada
  (GDD §6.1).

## 3. Formas disponibles

`circulo`, `ovalo`, `cuadrado`, `rectangulo`, `triangulo` (isósceles), `triangulo_rect` (◣ con el
ángulo recto abajo a la izquierda; girado 90° ◤, 180° ◥ y 270° ◢), `rombo`, `trapecio` (lado de
arriba = 60 % del de abajo), `semicirculo`, `paralelogramo`, `estrella`, `corazon`, `gota`, `luna`
y `flor`. Todas se definen por `ancho` × `alto` sin girar, centradas.

Decoraciones (`decoracion`): `rueda`, `aleta` (púas de dino), `manchas`, `ventanas` (autito).

## 4. Contrato de datos del nivel

```jsonc
{
  "id_nivel": "arcoiris_z3_formas_estrella",
  "motor": "encajar",
  "perfil": "estrella",                 // semilla | brote | estrella
  "planeta": "arcoiris", "zona": "zona3_chupetines",
  "modo": "compuesto",                  // informativo: simple | compuesto | escena | tangram
  "iman_tolerancia_px": 55,             // distancia máxima del centro de la pieza a la silueta
  "limite_intentos": 8,                 // null = sin límite (derrota-gag + estrellitas si hay)
  "sin_error": false,                   // true (Semilla por defecto): soltar mal nunca es "no"
  "toque_lleva_a_casa": false,          // tocar una pieza la manda sola a su silueta (Maxi)
  "ayuda_idle_s": 0,                    // >0: tras N s quieto, brillan una pieza y su casita
  "objetivo_guiado": false,             // Brote: un hueco resaltado y nombrado por voz a la vez
  "enderezar_al_acercar": false,        // la pieza gira sola al acercarse a su silueta girada
  "rotacion_por_toque": true,           // tocar (sin arrastrar) gira la pieza `paso_rotacion`
  "paso_rotacion": 90,
  "rotacion_inicial_aleatoria": true,   // las piezas llegan giradas de una forma que no calza
  "risa_al_encajar": false,             // la pieza se ríe de cosquillas (Maxi, zona 2)
  "caras": false,                       // carita siempre visible en todas las piezas
  "guia_color": false,                  // la silueta muestra el color de su pieza
  "lado_minimo_bandeja": 0,             // por defecto: Semilla 96 px, Brote 56 px
  "figuras_por_partida": 2,             // se sortean N figuras del pool (rejugabilidad)
  "distractoras_por_partida": 3,
  "piezas_distractoras": [ { "forma": "circulo", "ancho": 100, "alto": 100, "color": "#F26CA8" } ],
  "escena": { "tipo": "jardin", "suelo_y": 430, "decorados": [ { "forma": "rectangulo", "ancho": 16, "alto": 30, "x": 455, "y": 418, "color": "#E8B53A" } ] },
  "lineas_voz": {
    "intro": "…", "pista": "…", "acierto": ["…"], "no_es_este": ["…"], "girar": "…",
    "figura_completa": ["…"], "risa": ["…"], "especial": "…", "derrota_gag": "…",
    "victoria_final": ["…"],
    "objetivo_prefijo": "voces/arcoiris/formas/nombres/"   // + nombre_voz + ".wav"
  },
  "figuras": [
    {
      "id": "pez", "silueta_unida": true, "especial": false,
      "voz_completa": "voces/arcoiris/formas/figuras/pez.wav",
      "centro": [0, 0],                 // solo en escena: relativo a la zona del tablero
      "piezas": [
        { "forma": "rombo", "ancho": 170, "alto": 110, "color": "#4A8BE0", "x": 20, "y": 0, "cara": true },
        { "forma": "triangulo", "ancho": 90, "alto": 80, "color": "#FF9F4A", "x": -95, "y": 0, "rotacion": 90 }
      ]
    }
  ]
}
```

Campos de pieza: `forma`, `ancho`, `alto`, `color`, `x`, `y` (relativos a la figura), `rotacion`
(grados, horario), `decoracion`, `cara` (carita al completar la figura), `nombre_voz` (Brote),
`opcional` (no hace falta para ganar: el corazón dorado) y `especial` (brillo + voz especial).

## 5. Reglas por perfil y resultado al soltar

| Al soltar… | Semilla (`sin_error`) | Brote / Estrella |
|---|---|---|
| lejos de toda silueta | vuelve a la bandeja, sin sonido de error | igual, **no cuenta intento** |
| sobre una silueta que calza | encaja | encaja |
| sobre una silueta que no calza | vuelve saltando y **su casita correcta brilla** (nunca un "no") | "no es este" amistoso, cuenta intento si hay límite |
| forma correcta pero girada (`rotacion_por_toque`) | — | voz "está chueca, tócala para girarla", cuenta intento |

- **Brote**: `objetivo_guiado` resalta una silueta y la nombra ("¡Busca el triángulo grande!").
  Cualquier pieza correcta en cualquier silueta vale; al llenarse el objetivo, pasa al siguiente.
- **Derrota-gag** (solo con límite): Brote, las piezas sueltas se apilan en una torre que se
  derrumba; Estrella, las piezas bailan por el tablero. Coco se ríe y aparece "¡otra vez!". Lo
  encajado se queda y el contador vuelve a cero (sin bono de intentos sobrantes, igual que emparejar).
- **Destellos**: 10 por pieza requerida + 2 por intento sobrante (si nunca hubo derrota-gag).
- **Estrellitas** (Estrella): regla PROVISIONAL de emparejar hasta que `disenador-niveles` fije
  umbrales. Sin límite: 3; tras derrota-gag: 1; con la mitad o más de los intentos sobrantes: 3; si
  no: 2.
- Tocar a **Cometa** repite la instrucción (en Brote, el objetivo actual; en Semilla además da
  pista). Tocar a **Coco** repite la intro. F3 (PC) muestra el panel de depuración.

## 6. Las 15 variantes implementadas

| Zona | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| 1 · Claro | 3 formas gigantes con color guía | 6 formas con sombra de color | casa, helado y árbol de 2 piezas con líneas internas (límite 6) |
| 2 · Charcos | rueda, aleta de dino y cuadrado que se ríen | 7 formas (suma corazón y rombo) | 2 de {cohete, gato, barco} de 3 piezas sin líneas internas (límite 6) |
| 3 · Chupetines | 4 formas (suma estrella) | 7 de 8 formas, sombras sin color | 2 de {pez, velero, pino}: las piezas llegan giradas, tocar gira (límite 8) |
| 4 · Islotes | círculos y cuadrados grandes y chicos | grandes y chicos con sombras giradas que enderezan solas (límite 12) | 2 figuras + 3 piezas distractoras, con giro (límite 9) |
| 5 · Cima | dinosaurio o autito gigante de 3 piezas con imán total | jardín: casa, sol, árbol y jirafa (8 huecos) + corazón dorado escondido (límite 16) | tangram: corona (especial, "te corono líder") o gato de 6 piezas, con giro (límite 10) |

## 7. Pendientes

- Arte final (HE-13): hoy las formas son vectoriales por código con el estilo "peluche pintado".
- Umbrales de estrellitas y límites definitivos por nivel (`disenador-niveles`).
- Voz real de la familia (HE-28); hoy TTS.
- Auditoría UX sobre build: tolerancia de imán para Nicole y el giro por toque de Sofía.
