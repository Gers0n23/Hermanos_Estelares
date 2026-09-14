# Ficha de zonas — Mapa del Planeta Arcoíris (capítulo 1)

> **Decisión del PO (14-Sep-2026)**: cada planeta tiene **su propio mapa interno de zonas**, y en
> cada zona los minijuegos del planeta vuelven con una **variante más retadora que la anterior**,
> para que el juego dure muchas más horas sin volverse repetitivo. En el mismo acto el PO sumó
> **Parejas de Coco** (motor `emparejar`) como **cuarto minijuego** del Planeta Arcoíris.
>
> Esta ficha aplica ese modelo al planeta 1. El modelo general vive en `docs/diseno-juego.md` §3
> ("Mapa de cada planeta: zonas y estaciones"). Las mecánicas base de cada juego siguen en
> `docs/fichas/planeta-arcoiris.md` §1-§3 (y `docs/fichas/motor-emparejar.md` para Parejas);
> aquí solo se describe **cómo cambia cada juego zona a zona para cada hermano**.

- **Autor**: Dev a pedido del PO (propuesta de diseño) — **pendiente de validación** por
  `disenador-niveles` (curvas y parámetros), `disenador-mecanicas` (variantes que suman reglas
  nuevas: rotar piezas, simetría, mezcla en paleta), `guionista` (voces de zona) y
  `experto-ux-parvulo` (carga cognitiva por edad). Los números son un punto de partida para
  playtest, no valores cerrados.
- **Estado**: diseño propuesto, 14-Sep-2026.
- **Perfiles**: `docs/perfil-jugadores.md`. Reglas por perfil: GDD §5 (Maxi nunca pierde; Nicole
  un objetivo a la vez; Sofía reto real con estrellitas y derrota chistosa).

---

## 1. Idea en una frase

El Planeta Arcoíris **perdió sus colores**: cada zona que los hermanos completan le devuelve uno o
más colores al planeta (y a la cresta de Coco), hasta que en la última zona el arcoíris vuelve
entero. El viaje por las zonas es también la escalera de dificultad de los cuatro juegos.

---

## 2. Estructura del mapa del planeta

```
Mapa Estelar ──► Planeta Arcoíris (mapa del planeta)
                   │
                   ├─ Zona 1 · El Claro del Trébol ........ devuelve el ROJO
                   ├─ Zona 2 · Los Charcos Saltarines ...... devuelve el AMARILLO
                   ├─ Zona 3 · El Bosque de Chupetines ..... devuelve el AZUL
                   │     └─► escena de historia «El ala pintada de Coco» + pieza de la nave (ala)
                   ├─ Zona 4 · Los Islotes Flotantes ....... devuelve VERDE y NARANJA   (expedición extra)
                   └─ Zona 5 · La Cima del Arcoíris ........ devuelve VIOLETA y el BRILLO (zona secreta)
```

- **Zona** = un lugar del planeta (sale del arte ancla `assets/anclas/planeta_arcoiris_referencia.png`:
  claro en trébol, charcos de pintura, árboles-chupetín, formas flotantes, casita de Coco).
- **Estación** = una variante de uno de los 4 minijuegos dentro de una zona. Cada zona tiene
  **4 estaciones** (Lluvia de colores, Formas traviesas, Parejas de Coco, Pinta con Coco) →
  **20 estaciones por hermano** en el planeta.
- Cada estación carga **el nivel de la ruta del hermano que juega** (GDD §5). Cualquier hermano
  puede entrar a la ruta de otro sin penalidad.
- **Orden pedagógico de colores**: primero los primarios (zonas 1-3), después los secundarios y
  el brillo final (zonas 4-5). Coincide con la escalera de Sofía en Lluvia de colores (primero
  mezclas guiadas, después mezclas libres).

### 2.1 Reglas de apertura (desbloqueo generoso, GDD §3)

| Regla | Valor propuesto | Por qué |
|---|---|---|
| Zona 1 | Abierta al llegar al planeta | Primer contacto sin requisito |
| Abrir la zona siguiente | Completar **2 de las 4** estaciones de la zona actual (cualquiera) | Nunca se traba: si un juego no le gusta o se le hace difícil, sigue avanzando con otros |
| Estaciones pendientes | Siguen disponibles siempre, en cualquier orden | Se puede volver a completar la zona cuando quiera |
| Pieza de la nave (ala) | Al abrir la zona 4, es decir, con 2 estaciones completadas en la zona 3 | Mínimo para un hermano: **6 estaciones** (~20-30 min); la historia avanza sin exigir horas |
| Zonas 4-5 | Expedición extra: no bloquean el capítulo 2 | Suman horas y reto sin frenar la historia |
| Zona 5 (secreta) | Se revela al completar **las 4 estaciones de la zona 4** | Premio para quien exploró todo; antes se ve como un resplandor lejano en la cima, nunca con candado |
| Zonas no abiertas | Se ven **descoloridas y dormidas**, con el camino en gris | Tease en vez de muro (GDD §3): Coco explica que "a ese rincón todavía le falta color" |

### 2.2 Recompensas por zona

| Momento | Recompensa |
|---|---|
| Cada estación | Celebración estándar de HE-10 + destellos + (Sofía) 1-3 estrellitas |
| Zona completada (sus 4 estaciones) | El color de la zona vuelve al planeta y a la cresta de Coco, visible también en el disco del planeta en el mapa estelar; Coco regala un **recuerdo de zona** para el hangar (ver tabla) |
| Zona 3 (con la regla de pieza) | Escena de historia + **ala de la nave** + video-llamada de papá (`docs/guiones/escena_planeta_arcoiris.md`) |
| Zona 5 completada | El arcoíris del planeta queda entero y brillante; el dibujo de "Decora el ala" (§3.4, zona 5) queda pintado sobre el ala en el hangar; Coco le hace a cada hermano su gesto de celebración |
| Maestría (opcional, Sofía) | **Corona de colores** por zona si logra 3 estrellitas en todas las estaciones con puntaje de esa zona; puramente cosmética |

Recuerdos de zona (objetos que se ven en el hangar, a diseñar por `disenador-personajes`):
1. Pincel rojo de Coco · 2. Gota dorada saltarina · 3. Chupetín espiral azul · 4. Estrella flotante
verde-naranja · 5. Plumón arcoíris de la cima.

### 2.3 Rejugabilidad y duración estimada

- Toda estación completada se puede **rejugar**: el contenido se baraja (posición de cartas, orden
  de gotas y de piezas) y, dentro de la zona, cada nivel trae un **pool** de elementos mayor que
  los que usa por partida, así que no se juega dos veces igual.
- Rejugar nunca quita nada; da celebración y, para Sofía, la oportunidad de mejorar estrellitas.
- **Primera pasada**: 20 estaciones × 3-5 min ≈ **1 a 1,5 h por hermano** en el planeta.
- **Con rejugadas y estrellitas**: 2-3 h por hermano. Con tres hermanos y el modo misión familiar
  (GDD §3), el capítulo 1 pasa de ~30 min a varias tardes de juego.
- La meta de duración aplica igual a los planetas 2-6: cada uno define su mapa de zonas en su
  propia ficha (patrón de esta).

---

## 3. Variantes por juego, zona y hermano

Lectura: cada celda describe **qué cambia** respecto de la zona anterior. Los parámetros entre
corchetes son los campos del contrato de datos del motor. Todo lo que ya dicen las fichas base
(tamaños ≥96 px en Semilla, voz para toda instrucción, reintento de un toque) sigue valiendo.

### 3.1 Lluvia de colores — motor `clasificar`

| Zona | Maxi · Semilla (nunca pierde) | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| 1 · Claro | 1 gota quieta junto a 3 charcos grandes (rojo, azul, amarillo); tocar hace magia de color en cualquier charco [`modo: libre`, `velocidad_caida: 0`] | Llevar 1 gota a su charco entre 3 primarios, sin caída [`modo: directo`, 3 colores] | Mezclas guiadas: el charco muestra los dos colores de la receta; 2 mezclas (verde, naranja) [`modo: mezcla`, `guia_receta: true`] |
| 2 · Charcos | Las gotas caen muy lento, de a una; al tocarla salta sola al charco más cercano; suma rosa y verde (5 colores) | Caída lenta y pareja, 5 colores con rosa; charcos decorados (borde de florcita para el rosa, orejitas de jirafa para el amarillo) [`limite_intentos: null`] | Receta oculta (solo se ve el color resultado): verde, naranja y violeta; 2 gotas a la vez [`guia_receta: false`, `limite_intentos: 10`] |
| 3 · Chupetines | El charco del color de la gota **brilla y la llama**: tocarla ahí da doble fiesta, en otro charco igual salpica bonito (refuerza sin error); aparece el dino de pintura sorpresa | Los charcos **cambian de lugar** con una vuelta suave entre gota y gota (atención); límite holgado [`limite_intentos: 12`]; aparece la gota-jirafa bonus | Gotas a velocidades distintas y una **gota gris sin color** que no sirve para ninguna mezcla (hay que dejarla pasar); estrellitas por intentos |
| 4 · Islotes | Gotas gigantes que **se dividen en dos gotitas** al tocarlas (causa-efecto); 2 gotas en pantalla | **Claro y oscuro**: rosado vs rojo, celeste vs azul (discriminación fina), caída lenta | Colores con **blanco**: rosado (rojo+blanco), celeste (azul+blanco) y café (rojo+amarillo+azul, 3 componentes); Coco cuenta un dato curioso por mezcla |
| 5 · Cima | **Lluvia de fuegos artificiales**: cada gota tocada pinta una franja del arcoíris del cielo; al completarlo, arcoíris gigante | **Coco nombra el color por voz** y los charcos aparecen solo con contorno: hay que asociar el nombre oído con la gota (escucha y vocabulario de colores) | **Pedidos de Coco**: 5 pedidos encadenados de mezclas y tonos, con un reloj amable que **solo da estrellitas** (nunca termina el nivel ni presiona con la historia) |

### 3.2 Formas traviesas — motor `encajar`

| Zona | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| 1 · Claro | 3 formas gigantes (círculo, cuadrado, triángulo), imán enorme [`iman_tolerancia_px: 200`] | 6 formas con silueta de color (la silueta ayuda) [`modo: simple`] | Figura compuesta de **2 piezas**: casa (triángulo + cuadrado) con contornos internos marcados [`modo: compuesto`] |
| 2 · Charcos | Las formas tienen carita y **se ríen** al encajar; decoraciones de rueda y aleta de dino (GDD §4) | 7 formas: suma corazón y rombo | Figuras de **3 piezas** sin contornos internos: cohete y gato |
| 3 · Chupetines | 4 formas (suma estrella), cada una en su color de siempre | Siluetas **solo con contorno**, sin color guía | Piezas que **hay que girar**: un toque sobre la pieza la gira 45° (sigue siendo un solo toque, GDD §6.4) |
| 4 · Islotes | Formas en **dos tamaños** (grande y chico) con imán generoso: la chica va en el hueco chico | Formas en dos tamaños y **siluetas giradas**: la pieza se endereza sola al acercarse (sin exigir rotar) | **Piezas distractoras**: hay más piezas de las que la figura necesita |
| 5 · Cima | Arma su **dinosaurio o autito** gigante de 3 piezas, con imán total (su gusto más fuerte, ficha de Maxi) | **Completa una escena**: jardín con casa y jirafa con 8 huecos; el corazón dorado escondido | **Tangram de Coco**: silueta completa sin divisiones (pony o corona) con 5-7 piezas y rotación; límite holgado, estrellitas |

### 3.3 Parejas de Coco — motor `emparejar` (cuarto juego)

La demo jugable del 13-Sep-2026 ya cubre tres de estas celdas: Maxi zona 2
(`arcoiris_emparejar_semilla_01`), Nicole zona 3 (`arcoiris_emparejar_brote_01`) y Sofía zona 2
(`arcoiris_emparejar_estrella_01`).

| Zona | Maxi · Semilla (siempre a la vista, `oculto: false`) | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| 1 · Claro | 2 pares a la vista, cartas enormes, halo que respira [`halo_idle: true`] | 3 pares **a la vista** (calentamiento sin memoria) | 6 pares tapados, 4×3, tiempo generoso [`tiempo_volteo_ms: 1300`, `limite_intentos: null`] |
| 2 · Charcos | 3 pares a la vista ✅ **(demo actual)** | 4 pares **tapados** con tiempo generoso y ayuda tras 3 fallos [`tiempo_volteo_ms: 1600`, `ayuda_tras_fallos: 3`] | 8 pares 4×4 con límite ✅ **(demo actual)** [`limite_intentos: 16`] |
| 3 · Chupetines | 4 pares; suma figuras de sus gustos (dino, autito) | 5 pares tapados, corazón mágico ✅ **(demo actual)** | **Correspondencia**: cada mezcla con su receta (carta verde ↔ carta azul+amarillo) [`modo: correspondencia`], 8 pares |
| 4 · Islotes | **Mamá y bebé**: figura grande ↔ la misma figura chiquita [`modo: correspondencia`], 4 pares | **Color ↔ cosa de ese color** (mancha amarilla ↔ jirafa, mancha rosa ↔ flor), 5 pares tapados | 10 pares 5×4 con límite 20 y cartas **traviesas**: tras cada par encontrado, dos cartas tapadas intercambian lugar con una animación visible |
| 5 · Cima | 5 pares a la vista y las cartas **bailan** despacito de lugar entre jugada y jugada (atención, sin memoria) | 6 pares: **dibujo ↔ su letra inicial** con voz ("S de sol"), refuerzo de lectura inicial (decisión del PO del 06-Ago-2026, GDD §5) | **Sombras**: figura ↔ su silueta, 12 pares 6×4 (cartas ≥130 px en 1280×720), límite 26, arcoíris secreto |

### 3.4 Pinta con Coco — motor `lienzo_libre`

GDD §4 define este juego como expresión libre "igual para todos". Con el mapa de zonas, **la zona 1
se mantiene libre**. Desde la zona 2 cada estación agrega un **encargo creativo de Coco**:

- **No hay fallo en ningún perfil**, tampoco para Sofía.
- El destello siempre se gana al tocar "mostrar a Coco".
- Lo que crece zona a zona es la herramienta y la idea, **nunca una evaluación del dibujo**.

| Zona | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| 1 · Claro | Lienzo libre con 6 blobs gigantes y sellos de dino y auto (ficha base §3.3) | Lienzo libre, 12 colores, pinceles corazón y estrella (§3.4) | Lienzo libre con purpurina (§3.5) |
| 2 · Charcos | **Sellos sobre una escena**: estampar dinos, autos y estrellas en la pradera | **Colorear por zonas**: tocar partes de un pony o una jirafa las rellena del color elegido | **Colorear por código**: cada número del dibujo tiene su color (arma un mosaico secreto) |
| 3 · Chupetines | **Pinta a Coco**: cada toque rellena una parte grande de Coco, que cambia de color en vivo | **Coco pide**: pinta con los colores que Coco nombra por voz (escucha); cualquier resultado se celebra | **Mezcla en la paleta**: solo hay primarios y blanco; los demás colores se consiguen mezclando en la paleta |
| 4 · Islotes | **Dedo mágico**: cada trazo deja un arcoíris que suena | **Espejo mágico**: lo que pinta en un lado aparece al otro (mariposa, flor) | **Mandala arcoíris**: simetría de 6 ejes con patrones |
| 5 · Cima | **Decora el ala** (común a los tres, UI por perfil): pinta el ala de la nave recién ganada; el dibujo queda en el hangar | **Decora el ala** y además **viste a Coco** (juego de "vestir", gusto de Nicole): Coco usa ese traje en el mapa del planeta | **Decora el ala** con plantillas de brillos y su propia insignia de pony |

### 3.5 Resumen de la escalera por hermano

- **Maxi (Semilla)**: la escalera sube en **variedad, movimiento y sorpresa**, no en exigencia.
  Nunca aparece un "no". De la zona 3 en adelante hay pistas que refuerzan la respuesta correcta
  con doble fiesta, pero la otra respuesta también se celebra (mismo patrón que "¿Quién habla?"
  S en Animalia).
- **Nicole (Brote)**: más elementos, memoria con tiempos generosos, atención (cosas que se mueven)
  y escucha y lectura inicial (colores nombrados, letras iniciales). Siempre **un objetivo a la
  vez**. Derrota-gag suave solo donde hay límite.
- **Sofía (Estrella)**: reglas nuevas cada zona (receta oculta, girar piezas, distractores,
  correspondencias, cartas traviesas, tangram, pedidos encadenados). Estrellitas en todas las
  estaciones con puntaje. Siempre completable a los 8 años.

---

## 4. Contenido de datos (para `dev-godot` y `disenador-niveles`)

- **Mapa del planeta**: `datos/planetas/arcoiris/mapa.json`. Define las zonas (id, nombre, color
  devuelto, posición en el mapa, recuerdo), sus 4 estaciones (motor, escena y un nivel por
  hermano), la regla de apertura (`estaciones_para_abrir_siguiente: 2`), la zona tras la cual se
  entrega la pieza y la condición de la zona secreta.
- **Niveles**: `datos/niveles/arcoiris/<zona>/<juego>_<perfil>.json` (ejemplo:
  `datos/niveles/arcoiris/zona2_charcos/parejas_estrella.json`). Los tres niveles de la demo se
  mueven a sus zonas cuando exista el mapa del planeta.
- **Campos nuevos que piden estas variantes** (a formalizar en las fichas de motor):
  - `clasificar`: `guia_receta`, `gota_distractora`, `charcos_moviles`, `nombrar_color_por_voz`, `reloj_estrellitas`.
  - `encajar`: `rotacion_por_toque`, `enderezar_al_acercar`, `piezas_distractoras`, `tamanos`, `modo: escena|tangram`.
  - `emparejar`: `modo: correspondencia` (ya previsto), `cartas_bailan`, `intercambio_tras_par`.
  - `lienzo_libre`: `encargo` (`sellos_escena`, `colorear_zonas`, `colorear_codigo`, `coco_pide`, `mezcla_paleta`, `espejo`, `mandala`, `decora_ala`, `viste_a_coco`).
- **Progreso**: se guarda por hermano → planeta → estación: completada, mejores estrellitas y veces
  jugada. El estado de las zonas se deriva del mapa del planeta; no se guarda aparte.
  Requiere subir la `version` del guardado con migración (stack técnico, decisión del 18-Jul-2026).

---

## 5. Voces nuevas que pide el mapa de zonas (encargo para `guionista`)

| Clave | Quién | Momento |
|---|---|---|
| `zona_<n>_llegada` | Coco | Primera vez que se entra a la zona: la presenta y cuenta qué color le falta |
| `zona_<n>_abierta` | Cometa | Se abre la zona siguiente ("¡se despertó un rincón nuevo!") |
| `zona_<n>_completada` | Coco | Vuelve el color de la zona: Coco anuncia su nuevo color (su tic verbal) |
| `zona_dormida` | Coco | Tocar una zona aún no abierta: explica con cariño que le falta color, nunca "está bloqueada" |
| `zona_secreta_revelada` | Cometa | Se revela la Cima del Arcoíris |
| `estacion_repetida` | Coco | Se rejuega una estación ya completada (variantes breves: "¡otra vez!, ¡me encanta!") |
| Instrucciones por variante | Coco | Una intro por estación × perfil, como en las fichas base (§1.7, §2.7, §3.7 y ficha de nivel de Parejas) |

La escena de historia del ala cambia de disparador (zona 3; ver §2.1). La línea `arcoiris_001`
("terminaron todo mi arcoíris del claro") hay que ajustarla, porque en ese momento el planeta
tiene solo 3 de sus colores de vuelta.

---

## 6. Riesgos y validaciones pendientes

1. **Alcance del capítulo 1**: 20 estaciones × 3 rutas son muchos niveles y assets. Propuesta:
   el capítulo 1 se entrega con **zonas 1-3 completas** (incluye la pieza y la escena) y las
   **zonas 4-5 llegan como actualización "expedición extra"** antes del capítulo 2, si el tiempo
   aprieta. Decide el PO (GDD §9, P8).
2. **Economía de destellos**: la ficha base habla de "1 destello por minijuego" y el motor actual
   entrega ~50 por partida. Propuesta: **aperturas y pieza cuentan estaciones completadas, no
   destellos**; los destellos quedan como puntaje celebrado y energía acumulada del hangar.
   Valida `disenador-niveles`.
3. **Carga cognitiva de Nicole** en las zonas 4-5 (claro/oscuro, letras iniciales, siluetas
   giradas): auditar con `experto-ux-parvulo` y ajustar con la reacción real del playtest.
4. **Sofía y la frustración**: las reglas nuevas (tangram, cartas traviesas) deben tener un límite
   holgado y derrota-gag. Si en playtest llora, se baja la zona, nunca se quita la celebración.
5. **Maxi y la navegación del mapa**: el mapa del planeta debe ser tocable en grande y narrado
   (GDD §6). A los 2 años puede necesitar que Cometa **lo lleve solo a la siguiente estación**
   pendiente con un toque.
