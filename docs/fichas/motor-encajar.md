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
y `flor`. Todas se definen por `ancho` × `alto` sin girar, centradas. Toda pieza acepta `espejo`
(volteada en x antes de girar). Los poliominós del marco se definen por `celdas` y el lado de celda.

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

> **Columna de Sofía reemplazada (dificultad v3, 14-Sep-2026)**: ver §8 y la ficha de zonas §3.2.
>
> **Tabla entera reemplazada por "Arma la figura" (PO, 27-Sep-2026)**: ver §9. Las zonas 1 a 4 de Maxi
> y Nicole y las 5 de Sofía son ahora figuras reconocibles en Chile, cortadas en piezas.

## 8. Mecánicas de Sofía (dificultad v3, decisión del PO del 14-Sep-2026)

Campo `mecanica` del nivel (por defecto `huecos`, todo lo de arriba):

| Mecánica | Qué hace | Campos |
|---|---|---|
| `tangram_libre` | La silueta unida se llena con **cualquier** solución. Las medidas y posiciones de las piezas vienen en unidades de la red del tangram (`lado_red` px = cateto del triángulo chico). Al soltar, la pieza se ajusta a la red probando cada vértice y vale si queda dentro de la silueta sin pisar otras (tolerancia 5 % de su área). Se gana con el 97 % de la silueta cubierta. Las piezas puestas se pueden volver a tomar, y tocarlas solo da un saltito: para girarlas hay que sacarlas. | `lado_red`, `figuras` (la solución del generador sirve para las pistas), `piezas_distractoras` (intrusas) |
| `memoria` | Se ve el modelo a color (`segundos_modelo`), baja una cortina arcoíris y queda el contorno. Cada pieza va en su lugar exacto (`exigir_color`). El botón ojo muestra el modelo 2 s y cuesta una estrellita. | `segundos_modelo`, `exigir_color` |
| `marco` | Tablero de cuadraditos (`marco`: filas con `#`) y piezas poliominó (`piezas_marco`: `id`, `celdas`, `color`). Al soltar, la pieza se ajusta a la cuadrícula y vale si todas sus celdas caen dentro del marco y libres. Sobran piezas. | `marco`, `lado_celda`, `piezas_marco`, `piezas_necesarias`, `solucion` (para pistas) |

Reglas comunes (activadas por campos):

- `pruebas`: lista de partidas seguidas en un nivel. Cada una sobrescribe campos del nivel, y sus
  `lineas_voz` se mezclan con las del nivel. Entre pruebas: confeti y voz `prueba_superada`; la señal es
  `prueba_completada(indice)`. Los destellos se suman.
- `boton_espejo`: botón de 110 px bajo la bandeja (o en `boton_espejo_rect`). Voltea en espejo la
  última pieza tocada (borde dorado punteado). Las piezas llegan sin voltear, así que si su lugar las
  pide volteadas hay que usarlo. Sin pieza elegida suena la voz `espejo_sin_pieza`.
- `pistas_cuestan_estrellita`: botón de estrella dorada de 96 px arriba a la derecha.
  - Huecos o memoria: pone una pieza correcta.
  - Tangram libre y marco: pone una pieza de la solución o, si no cabe ninguna, devuelve a la bandeja una
    pieza mal puesta.
  - Cada pista (o vistazo al modelo) resta una estrellita, sin bajar de 1. Una estrellita cae del botón
    como feedback.
- `regalo_tras_derrotas`: desde la 2.ª derrota-gag, al tocar "¡otra vez!" Coco pone una pieza. No
  cuesta estrellita y es una vez por prueba.
- `guardar_avance`: guarda las piezas puestas del marco en `Progreso` a cada movimiento y las repone
  al volver (reto dorado). Se borra al ganar.
- `zona_figuras` y `zona_bandeja` (`[x, y, ancho, alto]`): cambian la distribución de la pantalla
  (reto dorado: tablero arriba y bandeja ancha abajo).

Verificación: `herramientas/qa_test_retos_sofia.gd` y `herramientas/capturar_retos_sofia.gd`
(pantallazos en ventana real).

## 9. "Arma la figura": primero la figura, después las piezas (PO, 27-Sep-2026)

El PO encontró errado el concepto de las figuras complejas: "con las formas separadas de la derecha no
se puede armar la forma final de la izquierda". Desde ahora, **toda figura se diseña primero** y sus
piezas salen de cortarla. Así, por construcción, la bandeja siempre arma la silueta.

- **Diseño**: `herramientas/figuras_formas.py`. Cada figura se escribe en px con las formas del motor
  (`R`, `T`, `TR`, `TP`, `C`, `E`) y un factor `escala`.
- **Validación**: sin solapes, sin piezas sueltas (salvo `permitir_sueltas`), cabe en el tablero,
  cada pieza cabe en la bandeja a tamaño real, lado mínimo por perfil (Semilla 96, Brote 52,
  Estrella 22 px), y dos piezas con la misma geometría deben tener el mismo color. El motor calza por
  geometría, así que serían intercambiables. También avisa de piezas "casi iguales".
- **Generación**: `--previas <carpeta>` dibuja cada figura armada y desarmada. `--escribir` genera los
  niveles (`modo: arma_figura`).

Campos nuevos del nivel:

| Campo | Qué hace |
|---|---|
| `bandeja_escala_real` | Las piezas de la bandeja no se achican: miden lo mismo que su silueta. |
| `piezas_en_bandeja` | Tope de piezas a la vista; las demás esperan en una cola y entran al encajar. Con escala real, además, solo entran las que caben. Siempre hay al menos una. Toda pieza ofrecida tiene un lugar libre donde calza. |
| `modelo_mini` | Tarjeta arriba a la izquierda con la figura terminada a color (la foto de la caja del rompecabezas). |

Otros cambios del motor:

- Con más de 14 piezas requeridas (`MAX_RANURAS`), el progreso es una barra arcoíris continua.
- Las siluetas de piezas chicas (lado < 90 px) llevan línea fina continua en vez del punteado grueso.
- La pista que coloca una pieza (`colocar_pista`) elige por geometría (forma, tamaño y espejo), no por
  nombre y color. Antes podía poner un rectángulo del mismo color pero de otro tamaño.

## 10. Rondas, banderas y emblemas encima (PO, 27-Sep-2026)

El PO pidió que el Planeta Arcoíris dure al menos una hora por hermano. Con una sola figura por estación,
Maxi terminaba en unos 30 segundos. Ahora **cada estación es una serie de rondas: una figura a la vez**.

| Campo | Qué hace |
|---|---|
| `rondas` (nivel) | Un número, N figuras sorteadas del pool `figuras`, o una lista de grupos (`["monumento", "bandera"]`): una ronda por grupo, sorteada entre las figuras con ese `grupo`. |
| `fija` (figura) | Va siempre primera (así la intro de zona, que la nombra, sigue calzando). |
| `dificultad` (figura) | Las rondas sorteadas se ordenan de menor a mayor: la estación sube suave. El generador pone el número de piezas. |
| `grupo` (figura) | Para `rondas` en lista (Sofía). |
| `config` (figura) | Sobrescribe campos del nivel en su ronda (límite, giro, `exigir_color`, `lineas_voz`). Si trae `figuras`, la ronda es una escena de varias figuras (el jardín de Nicole). |
| `exigir_color` | Una pieza solo calza donde además coincide el color. Las franjas iguales de las banderas se distinguen así. Semilla: la pieza rebota y su casita brilla. |
| `capa` (pieza) | Emblema **encima** de otras piezas: la estrella de Chile, el disco de Japón, el sol de Argentina, el rombo y el globo de Brasil. Su silueta se dibuja sobre las piezas ya puestas de las capas de abajo. Las piezas puestas de la capa k van en z 2k, y la pieza tomada en z 20. |
| `lineas_voz.ronda_siguiente` | Voz entre rondas ("¡Vamos con otra figura!"). Si falta, se usa `prueba_superada`. |
| `lineas_voz.intro_ronda` | Intro propia de una ronda que no es la primera (Sofía: "¡Ahora, una bandera!"). |
| `lineas_voz.intro_generica` | La dice Coco al tocarlo desde la 2.ª ronda, o al retomar una partida a medias. |

Flujo:

1. Se encaja la última pieza de la ronda y empieza la **mini-fiesta**. La figura baila en ola (`PiezaEncajar.bailar`), Coco baila, cae confeti y la medalla de la ronda se llena con la figura en chiquito. Coco dice `voz_completa`: el nombre de la figura y, para Sofía, un dato breve.
2. Suena `ronda_siguiente` y entra la figura siguiente.
3. `completado`, con los destellos de todas las rondas sumados, llega **solo al final**, con la celebración grande.
4. Estrellitas de Sofía: cuenta la peor ronda, y cada pista resta una.

- **Medallas**: arriba a la derecha, una por ronda y sin números. La ronda en juego late, las terminadas muestran su figura y las que faltan esperan con una estrellita.
- **Avance a medio jugar**: al terminar cada ronda se guarda con `guardar_estado_parcial` qué figuras tocaron, en qué ronda va la serie, los destellos, las estrellitas, las pistas y si hubo derrota. Al volver se retoma en la misma ronda, con las mismas figuras y las medallas llenas. Se borra al ganar (contrato base).
- **Compatibilidad**: los niveles sin `rondas` y el reto dorado (`pruebas`, marco) funcionan igual que antes.

**Generador** (`herramientas/figuras_formas.py`, tabla `ESTACIONES`):

- Primitivas nuevas: `O` (óvalo), `RB` (rombo), `SC` (semicírculo) y `P` (pieza por su centro, con cualquier giro).
- Validación por capas: solo se prohíben los solapes dentro de una misma capa, y todo emblema debe quedar entero sobre piezas de capas más bajas.
- `exigir_color` permite piezas iguales de distinto color.
- Los emblemas de Maxi pueden bajar a 52 px de lado; su zona tocable sigue siendo de 96 px.
- Escala automática: la figura se agranda todo lo que dejan el tablero y la bandeja a tamaño real.
- Nicole: `nombre_voz` automático según la forma, o según el color en las banderas ("¡Busca el color rojo!").
- El jardín de Nicole (zona 5) se conserva tal cual, como una ronda-escena.

## 7. Pendientes

- Arte final (HE-13): hoy las formas son vectoriales por código con el estilo "peluche pintado".
- Umbrales de estrellitas y límites definitivos por nivel (`disenador-niveles`).
- Voz real de la familia (HE-28); hoy TTS.
- Auditoría UX sobre build: tolerancia de imán para Nicole y el giro por toque de Sofía.

## Validación HE-40 — disenador-mecanicas (28-Sep-2026, PROPUESTA)

**Aprobado con cambios, sin bloqueantes.** El detalle está en
`docs/validaciones/HE-40_disenador-mecanicas.md`. Los cambios mayores son:

- **Pista**: medidor visible de 3 estrellitas y confirmación con un globo de 150 px (un segundo
  objetivo, no un doble toque). En el piso de 1 estrellita, la pista es gratis.
- **Giro en Sofía**: `giro_cuenta_fallo: false`. La pieza chueca se queda 2,5 s sobre su hueco y se
  gira con un toque.
- **Regalo**: `_derrotas` se reinicia en cada ronda y el regalo pone el 15 % de las piezas pendientes
  (entre 1 y 4).
- **Reto dorado**:
  - `lado_celda` 50, `escala_bandeja_fija` 0,64, `bandeja_acostadas`, `relleno_bandeja` 24.
  - Zona tocable del polígono agrandada 16 px.
  - Botón espejo en [1120, 470, 120, 120].
  - La pista busca entre todas las soluciones compatibles (`soluciones_marco`).

## Implementación dev-godot 28-Sep-2026 (validaciones HE-40, PROVISIONAL)

- `umbrales_estrellitas {tres, dos}` en fallos, a nivel del archivo o en el `config` de cada figura/ronda (vale la peor ronda): ≤ tres → 3, ≤ dos → 2, si no 1; derrota-gag → 1; cada pista resta 1 (mínimo 1). Sin el campo, la regla vieja.
- `giro_cuenta_fallo` (por defecto `false` en Estrella): lugar correcto con la pieza chueca no cuenta fallo; la pieza flota 2,5 s sobre el hueco (alfa 0,7, meciéndose ±4°) y un toque la gira ahí mismo.
- Regalo tras 2 derrotas **de la ronda** (`_derrotas` se reinicia por ronda): 15 % de las piezas que faltan (1-4), una cada 0,35 s, empezando por los huecos con más "no es este" y luego los más grandes.
- Pista con costo: medidor de 3 estrellitas bajo el botón y globo de confirmación (componente `scripts/ui/pista_con_costo.gd`); con 1 estrellita, gratis.
- Marco (reto dorado 6×10): `lado_celda` 50, `escala_bandeja_fija` 0,64, `bandeja_acostadas`, `relleno_bandeja` 24, zona tocable por la forma +16 px, espejo en [1110, 440, 120, 120]. Tocar una pieza puesta solo da un saltito (sale del marco recién al arrastrarla); con espejo, el 1.er toque solo elige la pieza.
- Bandeja: el círculo tocable de 96 px ya no le roba el toque a la forma de una pieza vecina.
- Rondas "Arma la figura": avance guardado pieza a pieza dentro de la ronda (`huecos_hechos`).
- Pendiente: pista del marco contra todas las soluciones (hallazgo 8 de mecánicas).
