# Storyboard y spec — Cinemáticas de la batalla final del Planeta Arcoíris (HE-68)

> Entregable de `director-cinematicas` para HE-68. Escrito el 07-Oct-2026.
>
> **Insumos**:
>
> - `docs/fichas/modo-equipo.md` §14, sobre todo el §14.10 (qué cinemáticas hacen falta y sus topes), el
>   §14.4 (el interludio), el §14.5 (los gags de derrota), el §5.5 y el §5.6 (el gag de Parejas y la
>   fiesta).
> - La "Re-auditoría HE-66" de `docs/validaciones/2026-10-06_ux-HE-66-batalla-arcoiris.md`, sobre todo el
>   N7, y el M1 (tope de 15 min).
> - El guion `docs/guiones/voces-batalla-arcoiris.md` (HE-67). **Todas las claves de voz de este
>   documento salen de ahí** o de las líneas que ese guion reutiliza (su §9).
> - `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md`, por los momentos memorables y el
>   presupuesto de duración.
> - GDD §1 (tono), §6 (UX infantil) y §7 (cutout), `docs/stack-tecnico.md` §5 (rig por partes) y el
>   ancla `assets/anclas/coleccionauta_referencia.png`.
>
> **No toca** el tablero, las fichas ni el guion. Lo que este storyboard necesita de otros roles queda en
> §13 y §14.

## 0. Reglas de dirección de este documento

1. **Cutout 2D dentro de Godot, no video.** Estas cinemáticas viven **dentro** de `batalla.tscn` y de
   la escena del ala, entre turnos y sobre el estado del juego: qué bandas del cielo hay, cuántos pisos
   le quedan a la mochila-torre y qué rondas se ganaron. Por eso las anima un `AnimationPlayer` sobre
   piezas, y no un clip pregenerado. Esto es una excepción al criterio de `docs/cinematicas/escena_intro.md`
   ("las escenas narrativas no van en cutout"); ver la duda 1 para el PO (§15).
2. **Un foco por momento.** Si el Coleccionauta habla, Coco solo respira, y al revés. Las voces
   **nunca** se pisan: entre dos voces hay de 0,15 a 0,3 s de aire.
3. **Cámara fija.** No hay cortes dentro de una cinemática. Solo hay fundidos, cortinas de iris y, una
   vez, un acercamiento suave (zoom 1,0 → 1,1). Todo pasa en planos frontales, con los personajes
   grandes.
4. **Aire después de cada chiste** (0,3 a 0,5 s), para que se rían antes de la frase siguiente.
5. **El Coleccionauta nunca da miedo.** No hay ojos gigantes en primer plano, ni oscurecimiento de
   pantalla, ni sonido de motor o aspiradora. El aspirado es un sorbete con bombilla (≤ 1,5 s), y el
   estornudo siempre tiene **0,6 s de anticipación** (tiembla e infla), así nunca es un susto. Su canon:
   **gafas-lupa y mochila-torre**, sin monóculo, sin caja, sin nave aspiradora y sin red. **No menciona
   a papá.**
6. **Se saltan con un toque desde la segunda vez.** La primera vez, un toque solo da una chispita en el
   dedo (< 100 ms, GDD §6.5) y no salta nada. Desde la segunda vez, un toque en cualquier parte salta al
   **estado final** de esa cinemática (§12.3). Esto vale para todas las cinemáticas de este documento,
   también para los interludios y los gags de derrota (en estos, el botón "¡otra vez!" corta desde la
   primera vez, por el §5.5).
7. **Los tiempos son estimados** con las duraciones del guion. La duración real la marca el audio. Si
   una voz real dura más, se acortan primero las transiciones y el aire; las voces nunca se solapan.

## 1. Composición base de la batalla (1280×720)

Así se ven las cinemáticas a pantalla completa. Las rondas usan el layout del §14.15 de la ficha.

| Elemento | Posición y tamaño | Nota |
|---|---|---|
| Cielo con el **arcoíris de 3 bandas** (rojo, amarillo y azul, de afuera hacia adentro) | Arco centrado en (640, 760), radios ≈ 560, 520 y 480 px, grosor 40 px | **Dibujado por código** (`draw_arc`), como el resto del paisaje de Arcoíris (`paisaje_arcoiris.gd`). Cada banda tiene `saturacion` de 0 a 1. Agrisada = gris claro `#C9C9D2` al 60 %, **sin oscurecer el resto de la pantalla** (m7) |
| Suelo: el **Claro del Trébol** | Tercio inferior, y de 430 a 610 | Reutiliza el dibujo de la región de la zona 1 |
| **Coleccionauta** | Pies en (840, 560), alto ≈ 340 px con la mochila | Mira de frente, con la mochila-torre asomando por sobre el hombro izquierdo |
| **Mochila-torre de batalla** | Detrás del Coleccionauta, desde (760, 300) hasta (900, 540) | Modular: base, 3 pisos transparentes y tapa (§11) |
| **Coco** | Pies en (380, 560), alto ≈ 200 px | Mira hacia el Coleccionauta |
| **Cometa** | Arriba a la izquierda, `Rect2(8, 4, 110, 96)` | El mismo de la pista. En las cinemáticas solo reacciona y habla |
| **Barra del equipo** | `Rect2(0, 610, 1280, 110)` | Siempre visible, con los tres retratos en la nave de juguete. En las cinemáticas reaccionan (aplauden, se ríen), pero no son tocables, salvo para saltar |

## 2. Teaser: el Coleccionauta se cuela en la video-llamada (escena del ala, zona 3)

- **Dónde**: extiende el Beat 4 de `docs/guiones/escena_planeta_arcoiris.md`, **después de
  `arcoiris_016` y antes de que se corte la llamada**.
- **Formato**: el mismo de la video-llamada del Beat 4. La pantalla de la nave muestra a papá, y el
  Coleccionauta en cutout entra **por encima** de ese cuadro. Si el Beat 4 se resuelve con una imagen
  fija de papá (motion comic), el teaser usa esa misma imagen más una segunda imagen de "papá riéndose"
  (asset A9).
- **Duración**: **≈ 10 s** (tope del §14.10: de 8 a 10 s).
- **Tono**: papá se ríe todo el tiempo (m7). Nadie lee "papá está en peligro".

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| T1 | 0,0-0,8 | La video-llamada, igual que al final de `arcoiris_016`. Papá sonríe | Por el borde derecho del cuadro **asoman primero las dos antenas** del Coleccionauta (0,3 s, rebote "boing"). Después entra la cara entera, de lado, con las gafas-lupa | — | "Boing" suave. La música del Beat 4 sigue, a −6 dB |
| T2 | 0,8-5,8 | El Coleccionauta ocupa la mitad derecha del cuadro, junto a papá, **más chico que papá** | Ojos brillantes en "¿Un planeta que recupera colores?", manos juntas. En "¡Para mi colección!" sube un dedo, grandioso. En "Permiso, permiso" retrocede de a saltitos y **la mochila-torre choca con el borde del cuadro**: el marco se ladea 6° y vuelve (0,4 s). En "¡voy saliendo!" tropieza y sale de cuadro hacia abajo. Un **patito de goma** de su mochila rebota y cruza el cuadro | `arcoiris_batalla_teaser_coleccionauta` (5 s) | Entra el **motivo del Coleccionauta** (tuba y kazoo, 2 compases). Choque con el borde ("bonk" acolchado), tropiezo ("pum" suave) y patito ("cuac") |
| T3 | 5,9-10,9 | Papá solo, riéndose (imagen "papá riéndose") | Motion comic: la imagen rebota con la risa (escala 1,0 ↔ 1,03 cada 0,25 s, 4 veces). En "¡Allá va, con su mochila!" papá mira hacia abajo a la derecha, por donde se cayó | `arcoiris_batalla_teaser_papa` (5 s) | La música vuelve a 0 dB. Al terminar, el cierre de llamada que ya tenga el Beat 4 |

**Después del teaser** (fuera del cronómetro, ya en el mapa del planeta): la primera vez que se ve el
mapa tras la escena del ala, **aparece el hito** (§3.1).

## 3. El hito en el mapa y "¡todos a la nave!"

### 3.1 Aparición del hito (una sola vez, 2,5 s, sin voz)

En el Claro del Trébol, junto a la nave estacionada (`posicion` [260, 380] de `mapa.json`):

| # | Tiempo | Acción | SFX |
|---|---|---|---|
| H1 | 0,0-1,2 | La mochila-torre baja desde arriba del cuadro **colgando de un paraguas** de colores (asset A7), meciéndose como una hoja | Silbido suave que baja |
| H2 | 1,2-1,8 | Aterriza con un rebote (squash 0,85 / stretch 1,1). El paraguas se cierra solo, "flop" | "Puf" de cojín |
| H3 | 1,8-2,5 | Por detrás de la mochila asoma el Coleccionauta y **saluda con la mano** | "Tilín" |

Si el PO no quiere el paraguas, la alternativa sin arte nuevo es que la mochila entre rebotando desde el
borde izquierdo (3 rebotes). El mapa **nunca pierde color** (M3).

### 3.2 El hito en reposo (bucle)

- La mochila-torre gris respira (escala 1,0 ↔ 1,02, 2 s).
- Cada 6-8 s el Coleccionauta asoma, saluda y se esconde (1,5 s).
- Sin signos de alerta y sin parpadeo (M7.3). Con rondas ganadas, la mochila muestra **solo los pisos que
  le quedan**, plegados (§11), sin números.
- `voz_hito`: `arcoiris_batalla_hito_01` o `_02`, al azar, **como máximo una vez por visita**, sincronizada
  con un asomo.

### 3.3 Tocar el hito → "¡todos a la nave!" (pantalla interactiva)

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| N1 | 0,0-0,1 | El hito se menea (< 100 ms) | — | "Boing" |
| N2 | 0,1-4,1 | El Coleccionauta saluda, y Cometa se asoma en la esquina, emocionado | `nucleo_batalla_hito` (4 s) | — |
| N3 | 4,1-4,6 | Cortina de iris hacia la pantalla "¡todos a la nave!" (la nave de juguete con tres ventanitas vacías y los tres retratos grandes abajo) | — | "Fiuu" |
| N4 | 4,6-7,1 | Pantalla quieta, esperando | `nucleo_batalla_todos_nave` (2,5 s) | Música del mapa, a −6 dB |
| N5 | Interactivo | Cada retrato tocado **salta en arco a su ventanita** (0,5 s, pop y destello del color del hermano: Maxi `#3E77CC`, Nicole `#E8589C`, Sofía `#2FB3AD`) | `nucleo_equipo_sube_nave_<hermano>` (+ `yo_tambien_<hermano>` si existe) | "Pop" con una nota distinta por hermano (do, mi, sol) |
| N6 | Al tener los 3 | "¡Despegar!" se enciende y respira, en el mismo rectángulo que "¡Juntos!" (M5.4) | — | Acorde do-mi-sol |
| N7 | Al tocar "¡Despegar!", 0,0-3,5 | **Cuenta regresiva sin números**: 3 estrellas grandes se encienden una por una sobre la nave (0,5 s cada una). La nave tiembla y sale volando en diagonal hacia arriba a la derecha, con estela de confeti | `nucleo_equipo_despegar` (≈ 3 s) | "Brrr" de juguete y "fiuuu" largo |
| N8 | 3,5-4,0 | Cortina de iris hacia la escena de la batalla | — | — |

- **Falta uno**: si alguien intenta seguir sin los tres retratos, suena `nucleo_batalla_falta_uno` y la
  ventanita vacía respira. La casa siempre está a la vista.
- **Retomar** (§10): la nave despega igual, pero con la versión corta (§10).

## 4. Entrada de la batalla (≤ 12 s)

**El robo de colores existe solo aquí**, en la escena de la batalla. Es **un rescate, no una pérdida**:
los colores quedan contentos y saludando en los pisos.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| E1 | 0,0-0,5 | La composición base (§1): cielo con las 3 bandas brillantes, Claro, Coco a la izquierda y la mochila-torre con sus **3 pisos de vidrio vacíos** | El Coleccionauta **salta desde detrás de un trébol gigante** y aterriza con squash | — | "Boing". Arranca el **tema de la batalla** (§12.4) |
| E2 | 0,5-5,0 | El Coleccionauta mira el cielo, encantado | "¡Ooh, qué colores más lindos!": manos juntas en la mejilla y ojos brillantes (ojos con estrellita). "¡Para mi colección!": gira la **bombilla doblada** de la tapa hacia el cielo. **En "Sluurp"** (≈ 2,8 s de la línea) las tres bandas **se despegan del cielo como cintas**, una tras otra (rojo, amarillo y azul, 0,3 s cada una), y entran por la bombilla: rojo al piso de abajo, amarillo al del medio y azul al de arriba. En el cielo queda el **dibujo gris de cada banda** (no un hueco). "¡Je, me hizo cosquillas!": la mochila se menea y él se ríe con los hombros arriba | `arcoiris_batalla_entrada_aspira` (4,5 s) | **Sorbete con bombilla** (≤ 1,5 s). Si la voz ya trae el "sluurp", el SFX se baja a −10 dB o no suena (nota 8 del guion). Risita "ji ji" |
| E3 | 5,15-8,15 | Acercamiento suave (zoom 1,0 → 1,1, 0,6 s) a la mochila | Dentro de cada piso, **una gotita del color con carita** rebota y **saluda** con la mano (asset A3). Coco salta al frente, en el centro, y **señala los pisos con la lengua** (la lengua del motor del Río) | `arcoiris_batalla_entrada_guardados` (3 s) | Tres "tilín" (uno por gotita). La música sube un tono |
| E4 | 8,3-11,8 | Zoom de vuelta a 1,0. El Coleccionauta, al centro | "¿Los quieren de vuelta?": se agacha hacia la cámara, pícaro. "¡Gánenme tres juegos!": **levanta 3 dedos**. "...¿O eran dos?": se mira los dedos, baja uno y queda bizco contándolos (mano A1-m) | `arcoiris_batalla_entrada_reto` (3,5 s) | Motivo del Coleccionauta (kazoo "¿uh?") |
| E5 | 11,8-12,0 | Cortina de iris al **mapa de batalla** | — | "Fiuu" |

**Al llegar al mapa de batalla, la primera vez** (fuera de los 12 s): Coco aterriza sobre el hito del
Río, que brilla (0,6 s), y suena `arcoiris_batalla_juego_rio` (1,2 s). Después **la ronda 1 arranca
sola**, con iris (0,4 s). Propuesta: no se pide un toque, porque acaban de tocar "¡Despegar!" y otro
toque más sería esperar sin motivo. Las pausas que esperan un toque son las de después de las rondas 1 y
2 (M1.2).

## 5. Intros de ronda (≤ 4 s cada una, N7)

**N7 resuelto así** (lo mismo que decidió el guion): una sola **frase**, la de Coco, de ≤ 2,5 s. Antes va
un gag del Coleccionauta de **una sola palabra** (≤ 1,5 s) que no se solapa con Coco. La regla completa la
repite Cometa al tocarlo (M6).

**Puesta en escena común**: el Coleccionauta **salta de la galleta 0 de la pista a la zona de juego**,
hace su gag y **vuelve de un salto a la galleta 0** justo cuando empieza Coco. Así hay un solo
Coleccionauta y un solo foco. Coco habla desde su lugar en la ronda, con un brillo suave que la
destaca. Mientras dura la intro, los toques en la zona de juego solo hacen el pulso.

**Entrar a una ronda desde el mapa de batalla**: al tocar el hito que brilla, se menea (< 100 ms) y Coco
dice el nombre del juego (`arcoiris_batalla_juego_rio`, `arcoiris_mapa_juego_formas` o
`arcoiris_mapa_juego_parejas`) **mientras se cierra el iris** (0,6 s). Después viene la intro. Antes de
jugar hay ≈ 5 s en total.

### 5.1 Ronda 1, Río (rojo): ≈ 4,0 s

| # | Tiempo | Acción | Voz | SFX |
|---|---|---|---|---|
| R1a | 0,0-0,3 | Salta de la galleta 0 a la orilla del río (abajo a la izquierda de la zona, junto a la entrada del cauce en y ≈ 560) | — | "Boing" |
| R1b | 0,3-1,5 | Se baja las gafas-lupa, mira el río de muy cerca, mete un dedo en una gota y **se pinta la nariz de rojo** (sprite de nariz roja, A1-n) | `arcoiris_batalla_rio_intro_coleccionauta` «¡Pintuuura!» (1,2 s) | "Plic" |
| R1c | 1,5-1,85 | Vuelve de un salto a la galleta 0, con la nariz roja (le queda toda la ronda) | — | "Boing" más agudo |
| R1d | 1,5-4,0 | Coco brilla y hace su gesto de "una gota cada uno": muestra la gota en la boca | `arcoiris_batalla_rio_intro` (2,5 s) | — |

### 5.2 Ronda 2, Formas (amarillo): ≈ 3,9 s

| # | Tiempo | Acción | Voz | SFX |
|---|---|---|---|---|
| R2a | 0,0-0,3 | Salta a la silueta de la nave de juguete (zona de figuras) | — | "Boing" |
| R2b | 0,3-1,4 | **Se mete en un hueco de la silueta** como si fuera una pieza, se atora (tiembla 0,3 s) y sale disparado con un "pop" | `arcoiris_batalla_formas_intro_coleccionauta` «¡Piecitas!» (1,1 s) | "Ñiii" de atorado y "pop" de corcho |
| R2c | 1,4-1,75 | Del "pop" sale volando de vuelta a la galleta 0 | — | "Fiu" |
| R2d | 1,4-3,9 | Coco brilla y apunta con la lengua a la bandeja | `arcoiris_batalla_formas_intro` (2,5 s) | — |

### 5.3 Ronda 3, Parejas (azul): ≈ 4,0 s

| # | Tiempo | Acción | Voz | SFX |
|---|---|---|---|---|
| R3a | 0,0-0,3 | Salta frente al tablero de cartas | — | "Boing" |
| R3b | 0,3-1,4 | Asoma la cara entre dos cartas y, al mirarlas por las gafas-lupa, **queda bizco** (ojos A1-o, bizcos) | `arcoiris_batalla_parejas_intro_coleccionauta` «¡Cartitas!» (1,1 s) | "Uiuiui" de mareo |
| R3c | 1,4-1,75 | Vuelve a la galleta 0, todavía bizco, y se le pasa con una sacudida de cabeza | — | "Boing" |
| R3d | 1,4-4,0 | Coco brilla | `arcoiris_batalla_parejas_intro` (2,6 s) | — |

En la ronda 3 de la batalla **no suenan** las intros de Parejas en equipo (nota 3 del guion).

## 6. Momentos memorables dentro de las rondas (motor, cortos)

No son cinemáticas: son animaciones del rival o del motor que **no detienen el juego** (salvo la de
Formas, que es el final de la ronda).

| Momento | Disparador | Animación | Duración | Voz | SFX |
|---|---|---|---|---|---|
| **Gafas rojas** (Río) | El **primer reventón de un tramo rojo** de la ronda (una vez por ronda) | Una gota roja sale disparada en arco desde el reventón hasta la pista y **salpica las gafas-lupa**: aparece la mancha roja sobre los dos lentes (A1-g). El Coleccionauta se tambalea 1 s "viendo rojo" y se limpia con la manga (las manchas se van en 0,3 s) | 1,6 s | `arcoiris_batalla_rio_coleccionauta_reacciona_02` («¡Qué salpicón! ¡Me pintaron las gafas-lupa!»), **solo si la cola de voces está libre** en 1 s. Si no, sin voz. Cuenta como su reacción de "1 de cada 3" | "Splat" suave |
| **Caritas en las ventanitas** (Formas) | Se encaja **la última pieza** de la silueta | La nave de juguete se arma completa con un destello. A los 0,3 s, **las caritas de los tres asoman por sus ventanitas** una por una (0,25 s entre cada una, en el orden Maxi, Nicole y Sofía), con un pop y un borde del color de cada uno. Las caritas saludan (rebote de 0,2 s) y se quedan 1,0 s. Después viene el interludio amarillo | 1,8 s | Sin voz (ver §14, punto 3) | Tres pops (do, mi, sol) y un "¡tadá!" corto |
| **La lupa caída** (Parejas) | Se forma la pareja lupa (`variante: "lupa_coleccionauta"`) | Al Coleccionauta **se le resbalan las gafas-lupa** de la frente a la boca (0,3 s), los ojos se vuelven espirales borrosas (A1-o) mientras el motor muestra las cartas 1,5 s, y después se sube las gafas con un dedo | 2,1 s | Si la formó Maxi, `arcoiris_emparejar_equipo_maxi_lupa` (reutilizada). Si no, sin voz (ver §14, punto 3) | "Fiuuu" que baja y "plink" al subirse las gafas |
| **Confeti de la mochila** (epílogo) | Termina la última franja de la tapa ("¡todos juntos!") | La mochila pintada tiembla (0,4 s), se infla y **estornuda confeti de los colores que eligieron los niños** (las partículas toman el color de cada parte pintada). El Coleccionauta se ríe tapándose la boca | 2,0 s | Sin voz | Estornudito "¡achís!" agudo (SFX, no voz) y "fssh" de confeti. **Abre el cierre, parte A** |

## 7. Interludio entre rondas (×3): cómo se resolvió el de 7 s

### 7.1 El problema

La ficha (§14.10, punto 3) pide de 3 a 4 s. El guion (§10, nota 6) muestra que, con voz, el interludio
suma el estornudo, `livianita_<n>` (2,5 a 3 s) y `zona_<n>_completada` (3 a 4,5 s): **≈ 7 s**.

### 7.2 Decisión: se queda en ≈ 7-8 s, sin tiempo muerto, y se justifica

**No se acorta a 3-4 s**, por estas razones:

1. **Los 3-4 s de la ficha eran una estimación sin voces.** Las dos voces son lo que hace que el
   interludio se entienda y dé risa, y suman 6-7,5 s solas. Para llegar a 4 s habría que sacar una, y
   las dos cumplen una función: Coco le cuenta a Maxi **qué color volvió** (contenido educativo, con su
   tic de color), y el Coleccionauta pone **el chiste**, que es el premio.
2. **No es espera: es la celebración de una ronda ganada** (GDD §6.9, "celebración generosa"). Es el
   momento en que el equipo ve el resultado de su trabajo, y los niños miran sin tener que hacer nada.
3. **Cabe en el presupuesto.** La calibración reserva 0,6 min (36 s) para los interludios y los toques
   del hito. Con este diseño, los 3 interludios más las 2 pausas habladas suman ≈ 31 s (§16).
4. **Cero tiempo muerto**: la voz de Coco **arranca en el mismo cuadro en que sale el chorro de color**
   (nota 6 del guion), así el vuelo del color hacia el cielo ocurre mientras ella habla. El piso que se
   pliega cae al empezar la línea del Coleccionauta. Solo hay 0,15 s entre voces.
5. **Desde la segunda vez se salta con un toque** (§0, regla 6), y el salto deja el estado final: color en
   el cielo, un piso menos y el mapa de batalla.

**Orden de las voces**: estornudo → `zona_<n>_completada` (Coco) → `livianita_<n>` (Coleccionauta). Es el
orden de la nota 6 del guion, **invertido respecto del orden del §7 del guion**, y no cambia ningún
texto. Así hay un solo foco a la vez, con causa y efecto: **el color** (vuela y llega al cielo) → **Coco**
(lo nombra y cambia de color) → **el Coleccionauta** (siente que la mochila pesa menos: chiste y aire
para reírse). Además, así no suenan dos líneas de Coco seguidas (su `zona_completada` y, en el mapa, su
`pausa_<color>`).

### 7.3 Plano a plano (ronda 1, rojo): ≈ 7,7 s

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| I1 | 0,0-0,2 | La ronda se funde a la composición base (§1): banda roja gris en el cielo y piso rojo lleno, con su gotita saludando | Fundido cruzado | — | La música de la ronda se funde con un "¡tadá!" corto |
| I2 | 0,2-0,8 | El piso rojo, con el Coleccionauta de frente | **Anticipación**: el piso rojo tiembla como gelatina (0,3 s) y se infla al 130 % (0,3 s). El Coleccionauta mira hacia atrás por sobre el hombro, preocupado de mentira | — | "Glu-glu" de temblor que sube |
| I3 | 0,8-0,9 | — | **¡Achís!** El piso se desinfla de golpe | — | Estornudo de SFX (volumen moderado, después de la anticipación) |
| I4 | 0,85-2,1 | **El color** | Sale un **chorro-cinta roja** por la bombilla y vuela en arco hasta su lugar en el cielo, con estela de chispitas. La gotita con carita viaja en la punta, saludando | `arcoiris_mapa_zona_1_completada` empieza en 0,85: «¡Volvió el rojo!...» | "Fiuuuu" ascendente |
| I5 | 2,1-2,4 | — | La banda roja **se repinta de un lado al otro** (saturación 0 → 1 en 0,3 s), y la gotita se funde en ella con un destello | (sigue la voz) | Campanita |
| I6 | 2,4-4,35 | **Coco** | "Mírenme, mírenme...": Coco salta al centro y gira. "¡ahora soy rojo frutilla!": **cambia a rojo** (modulate con un barrido de abajo hacia arriba, 0,3 s) y posa | (termina en 4,35) | Chispitas al cambiar de color |
| I7 | 4,5-7,0 | **El Coleccionauta** | Al empezar la línea, el piso vacío **se pliega como un telescopio** dentro del de arriba (0,25 s, "plop"), y la mochila queda un piso más baja. "¡Uy!": se agarra las tiras de la mochila. "¡Mi mochila está más livianita!": **da un saltito**, más alto de lo que esperaba, y aterriza con las antenas rebotando | `arcoiris_batalla_livianita_1` (2,5 s) | "Plop" y "boing" |
| I8 | 7,0-7,4 | — | Aire para la risa: los retratos de la barra se ríen | — | — |
| I9 | 7,4-7,7 | Cortina de iris al mapa de batalla | — | — | — |

**En el mapa de batalla** (fuera del interludio): el hito del Río queda pintado de rojo, Coco **salta al
hito siguiente** (0,6 s) y suena `arcoiris_batalla_pausa_amarillo` (3,5 s). El hito siguiente brilla y
**no avanza solo** (M1.2). La casa está a la vista.

### 7.4 Ronda 2 (amarillo): ≈ 9,2 s (≈ 7,9 s con el recorte)

Igual que la 7.3, con el piso del medio, la banda amarilla y estas diferencias:

- La voz de Coco es `arcoiris_mapa_zona_2_completada` (≈ 4,5 s). En "¡Brillo como un sol!", Coco brilla
  con unos rayos (partículas).
- La del Coleccionauta es `arcoiris_batalla_livianita_2` (3 s). En "Boing...", **salta tan alto que se
  pega en la cabeza con algo invisible** arriba del cuadro (estrellitas girando, 0,5 s) y baja sobándose.
- Después, en el mapa, suena `arcoiris_batalla_pausa_azul`.
- **Opción para recortar 1,3 s** (necesita el OK del `guionista`, §14, punto 2): en la batalla, cortar la
  reproducción de `zona_2_completada` después de "¡amarillo limón!".

### 7.5 Ronda 3 (azul): ≈ 7,0 s, enlazado con "antes del epílogo"

Igual que la 7.3, con el piso de arriba y la banda azul (`arcoiris_mapa_zona_3_completada`, 3 s).
Diferencias:

- No hay iris ni mapa al final: el interludio **sigue de corrido** a "antes del epílogo" (§8).
- `arcoiris_batalla_livianita_3` (2,8 s): «¡Uy, uy, uy! ¡Mi mochila ya no pesa nada!». La mochila,
  ahora con los 3 pisos plegados, **lo levanta del suelo**: flota 40 px meciéndose, desconcertado, y en
  el aire que sigue **cae sentado** en el pasto ("puf"). Esa caída es la pose de partida del §8.
- El cielo queda con el arcoíris de 3 bandas completo y la mochila, gris y vacía.

## 8. Antes del epílogo (≤ 5 s): ≈ 4,8 s

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| P1 | 0,0-2,8 | El Coleccionauta **sentado** en el pasto, con la mochila gris plegada en el regazo | Mira dentro de la mochila con las gafas-lupa (se agacha sobre ella) y suelta un suspiro de teleserie, con la mano en la frente. **Chistoso, no triste**: una mosquita de dibujo sale volando de la mochila vacía (gag) | `arcoiris_batalla_epilogo_antes_coleccionauta` (2,8 s) | Un "fiu-fiu" de violín de teleserie, cómico (1 s) |
| P2 | 2,95-4,8 | **Coco** | **Ampolleta**: sobre la cabeza de Coco aparece una chispita grande que brilla. Coco da un salto | `arcoiris_batalla_epilogo_antes_coco` (1,8 s) | "¡Ding!" |
| — | 4,8 | Corte al epílogo: la mochila se **estira** de nuevo hasta sus 3 pisos grises, como un telescopio (0,4 s, "ñiiiic"), lista para pintar. Suena `arcoiris_batalla_epilogo_maxi_ven` y el retrato de Maxi salta en la barra (M1.4) | — | — |

## 9. Epílogo: Pinta la mochila (interactivo; solo la puesta en escena)

- **Plano fijo**: la mochila-torre grande al centro (alto ≈ 380 px), con sus **3 pisos y la tapa como
  regiones pintables** (el piso de abajo, el más grande, es para Maxi). El Coleccionauta, sentado a la
  derecha, mira y reacciona. Coco está a la izquierda.
- Por cada parte pintada: `parte_coco_0X` y después `parte_coleccionauta_<n>` **en orden** (1, 2 y 3).
  Reacciones del Coleccionauta:
  - n = 1: se le agrandan los ojos y aplaude con las puntas de los dedos;
  - n = 2: se pone de pie de un salto;
  - n = 3: "Nadie me había regalado nada...", y se le humedecen los ojos (un brillo, **sin lágrimas que
    caigan**). En "...Bueno, una vez un calcetín", saca un calcetín de un bolsillo del chaleco (gag,
    asset A1-c).
- Los "¡Para ti!" de los niños (opcionales) van justo después de pintar cada parte.
- **Tapa "¡todos juntos!"**: `arcoiris_batalla_epilogo_tapa` → cada ventanita tocada agrega una franja
  del color del hermano a la tapa (0,3 s, pop) → al terminar la tercera franja, **estornudo de confeti**
  (§6) → **cierre, parte A**.

## 10. Retomar una batalla guardada (≈ 3 s de recordatorio)

- **Al tocar el hito**: no se repite la entrada.
- **Si "¡todos a la nave!" se repite al retomar** (lo decide `disenador-mecanicas`, §14, punto 6): la
  nave despega con la versión corta, sin estrellas de cuenta regresiva (1,2 s), mientras suena
  `nucleo_batalla_retomar` (1,5 s).
- **Si no se repite**: el hito se menea, suena `nucleo_batalla_retomar` y hay iris directo a la ronda.
- Después, la **intro de la ronda pendiente** (§5), que hace de recordatorio, y `le_toca_maxi_0X`. **Siempre
  empieza Maxi** (N6).
- **En el epílogo**: en vez de la intro, suena `arcoiris_batalla_epilogo_maxi_ven`.
- La mochila aparece con el estado guardado: las bandas recuperadas y los pisos que quedan.

## 11. Gags de derrota de Río y Formas (motor)

Plantilla común, que hereda el §5.5 de la ficha (Parejas ya está diseñada ahí y se reutiliza):

- Empieza con **el retrato del siguiente ya al centro**, al 80 % del tamaño de la puerta (≈ 210 px),
  levantado a y ≈ 250 para dejar ver el gag. El tablero se oscurece **solo al 20 %**.
- El gag ocurre en la mitad derecha, donde llegó el Coleccionauta.
- El botón **"¡otra vez!" (≥ 160 × 160 px)** aparece **desde el segundo 0**, al centro abajo, en (640,
  480). Tocarlo corta la secuencia, y entonces suena `nucleo_equipo_coleccionauta_vuelve` mientras el
  Coleccionauta vuelve silbando a la galleta 0.
- Los retratos de la barra **se ríen juntos** cuando él cae sentado. Nadie queda señalado.

### 11.1 Río: ≈ 16,7 s si nadie toca el botón

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| DR1 | 0,0-3,5 | Salta de la mesa a la orilla del río (el final del cauce). Apunta la bombilla al cauce y **las gotas que quedan entran en fila por la bombilla**, como fideos sorbidos | `arcoiris_batalla_rio_coleccionauta_aspira` (3,5 s) | Sorbete (≤ 1,5 s) |
| DR2 | 3,65-7,15 | "¡Hip!": la mochila hipa y suelta una burbujita de pintura (×2, 0,3 s cada una). "A... a...": se infla (0,6 s de anticipación). "¡ACHÚU!": **las gotas salen en arcos y vuelven a caer al cauce**, en su orden, con salpicones. Él cae sentado, con manchas de pintura en las antenas | `arcoiris_batalla_rio_coleccionauta_estornuda` (3,5 s) | "Hip" ×2 y salpicones "plic-plic-plic" |
| DR3 | 7,3-9,8 | Sentado, se abanica con una mano | `arcoiris_emparejar_equipo_coleccionauta_cansado` (≈ 2,5 s) | — |
| DR4 | 9,95-12,75 | Coco se ríe y lo señala con la lengua. **Le sale pintura por las bolitas de las antenas** como dos fuentecitas (ver §14, punto 1) | `arcoiris_batalla_rio_coco_risa` (2,8 s) | Dos "pssst" de fuentecita |
| DR5 | 12,9-16,9 | Cometa brilla en la pista. **El cauce, ya más corto, destella de punta a punta** (0,5 s): se ve lo que el equipo ya logró | `nucleo_equipo_gotas_reventadas_01` o `_02` (4 s) | Campanitas en escalera |

### 11.2 Formas: ≈ 15,8 s

Igual que el Río, con estas diferencias:

- **Aspira las piezas sueltas de la bandeja**: las piezas se estiran hacia la bombilla, como chicle.
  Voz: `arcoiris_batalla_formas_coleccionauta_aspira` (3,2 s).
- **Estornuda**: `arcoiris_batalla_formas_coleccionauta_estornuda` (3,2 s). En "me pica una esquina" se
  rasca la espalda con la bombilla. Las piezas salen **girando como trompos** (720°, 0,8 s) y caen en la
  bandeja **en el estado del perfil del turno siguiente** (m2): derechas si le toca a Maxi o a Nicole, y
  giradas solo si le toca a Sofía.
- Después vienen `cansado`, `arcoiris_batalla_formas_coco_risa` (2,8 s, con las piezas todavía girando
  en la bandeja) y `nucleo_equipo_piezas_puestas_<n>` (3,6 s). Mientras suena esta última, **la
  silueta destella sobre las piezas ya encajadas**.

### 11.3 Para acortar las derrotas repetidas (propuesta)

En la **segunda derrota y las siguientes de la misma ronda**, se omite `coco_risa`: la derrota baja de
16,7 a 13,8 s en el Río y de 15,8 a 13 s en Formas. El chiste ya se vio, y el botón corta igual.

## 12. Cierre de temporada

### 12.1 Parte A (≤ 20 s): ≈ 19,8 s, el arco del Coleccionauta

Empieza justo después del estornudo de confeti (§6). Fondo: el cielo con su arcoíris de 3 bandas
brillando y confeti que todavía cae.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| A1 | 0,0-5,3 | El Coleccionauta de pie, con la mochila pintada | Para verse la mochila, **gira persiguiéndola como un perrito que persigue su cola** (2 vueltas, 1,2 s) y se marea un poquito. "Es la cosa más incre... incre...": se le traba la lengua y abre los brazos. "¡ay, no me sale de lo linda que está!": abraza las tiras de su mochila, feliz | `arcoiris_batalla_cierre_mira` (5 s, desde 0,3) | El **tema de Arcoíris en versión fiesta** entra suave. "Fiu-fiu" al girar |
| A2 | 5,5-8,5 | El Coleccionauta, más la barra de los tres | Mira la mochila, después a los tres de la barra (que lo saludan) y otra vez la mochila. Se rasca la cabeza. **Compara con las manos**: una mano chiquita a la altura de la mochila y los brazos abiertos de par en par hacia los tres. Asiente, como quien descubrió algo | `arcoiris_batalla_cierre_equipo` (3 s) | — (la música baja a −8 dB) |
| A3 | 8,8-16,0 | El Coleccionauta se despide | "¡Me voy, me voy!": saluda con las dos manos. "Pero un día vuelvo... ¡con una mochila más grande!": se pone las manos en la cintura, orgulloso, y estira los brazos para mostrar "grande". "¡Chao!": sale caminando por la **izquierda**. "...¿Para qué lado era la salida?": **vuelve a entrar por la derecha**, despistado, mira para los dos lados, Coco le apunta a la izquierda con la lengua, él asiente, cruza todo el cuadro y sale por la izquierda **tropezando** con un trébol (el patito de goma rebota detrás de él) | `arcoiris_batalla_cierre_despedida` (6 s) + 1,2 s de gag sin voz | Motivo del Coleccionauta (kazoo), "pum" del tropiezo y "cuac" del patito |
| A4 | 16,0-16,2 | — | Aire para la risa | — | — |
| A5 | 16,2-19,8 | **Coco** al centro | "¡Lo logramos juntos!": salta. "Ahora soy...": pausa con los ojos cerrados (su tic). "¡arcoíris de equipo!": **se pinta de arcoíris de abajo hacia arriba** (shader de degradé, 0,4 s) y el arcoíris del cielo **destella completo** al mismo tiempo. Posa y queda 0,4 s | `arcoiris_batalla_cierre_coco` (3,2 s) | La música sube a 0 dB y suena un acorde final. Chispitas |

**Respaldo** si el audio real pasa de 20 s: primero se acorta el giro de A1 (1 vuelta) y después el aire.
Nunca se recorta el gag de A3, que es el gancho de HE-39.

### 12.2 Parte B: fiesta, foto y video-llamada opcional

**Por qué la fiesta de los tres va en la parte B** (la sugerencia del guion): la parte A ya llega a ≈ 19,8
s solo con el arco del Coleccionauta. La fiesta en la parte B mantiene la A en ≤ 20 s. Como la parte B
**empieza en el mismo cuadro en que termina la A**, la primera vez se ven seguidas, sin corte.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| B1 | 0,0-1,6 | Los tres retratos **salen juntos al frente** desde la barra (rigs de cuerpo entero, tamaño natural) | Corren al centro (0,5 s) | `nucleo_equipo_al_frente` | "Fiuu" ×3 |
| B2 | 1,8-4,6 | Los tres en fila | **Gestos canon por turnos** (0,8 s cada uno, con el mismo foco y el mismo volumen): Maxi da tres saltitos con el puño arriba, Nicole hace el corazón coreano y Sofía pone la mano en la cintura, el signo de la paz y un guiño (§5.6) | `nucleo_equipo_fiesta_<hermano>` (opcionales) | Un "tilín" del color de cada uno |
| B3 | 4,8-7,8 | Manos al centro | Las manos se juntan en el centro → **choque** → explosión de **confeti arcoíris** | `nucleo_equipo_choca` → `nucleo_equipo_equipo_estelar` | Aplausos y "pum" de confeti |
| B4 | 7,9-9,4 | Los tres posan | Aparece **"+100" bajo cada retrato, todos del mismo tamaño** (m6) | `nucleo_equipo_destellos` (solo si **todos** reciben) | Tintineo único (suena una sola vez, m6) |
| B5 | 9,6-12,6 | Cometa al centro | Cometa sorprendido. Detrás, la "nave" de los tres se va desvaneciendo | `arcoiris_batalla_cierre_foto` (3 s) | — |
| B6 | 12,6-≈ 22,8 | **Entrega de la foto con el flujo del álbum** (`album-recuerdos.md` §6) | El sobre-estrella baja girando (1,2 s), se abre con un toque o solo a los 3 s, sale la foto de los tres en la polaroid estelar al 70 %, suena **el audio que elige el PO** (≈ 5 s estimados) y la foto vuela al ícono del álbum (1 s) | El audio familiar (PO) | Confeti suave y "clic" de polaroid |
| **B7 (OPCIONAL)** | ≈ 22,8-40,8 | **Video-llamada de papá, extra familiar** (M7.2). **Solo si el PO la aprueba** (§15, duda 2) | Se enciende la pantalla de la nave (0,6 s, "tin"). Papá ve la foto, motion comic con la imagen de papá del Beat 4: rebota al reírse, y durante `papa_03` se abraza a sí mismo en "Los quiero mucho". Al final, la pantalla se cierra en destellos (0,8 s) | `arcoiris_batalla_cierre_papa_01` (4 s) → `_02` (5 s) → `_03` (7 s), con 0,3 s entre cada una | El tema del mapa, suave |
| B8 | Al volver a la selección (≈ 4,3 s) | La nave **"¡Juntos!" entra volando** a la pantalla de selección y se estaciona (M5.2) | Vuelo en curva desde arriba a la derecha (1,8 s), aterrizaje con rebote y luces encendidas | `nucleo_equipo_presenta` (≈ 2,5 s) | "Fiuuu" y "tadá" |

- **Sin la video-llamada**, la parte B dura ≈ 22,8 s más los 4,3 s de la nave = **≈ 27 s**. **Con la
  video-llamada**, ≈ **45 s**.
- La video-llamada **no lleva el gancho del planeta 2**: ese sigue en la escena del ala (M7.2).
- El Coleccionauta **no aparece** en la video-llamada: solo lo nombra papá en `papa_02`, porque esa voz es
  de papá y no del Coleccionauta.

### 12.3 Qué deja el salto (estado final de cada cinemática)

| Cinemática | Al saltar (desde la 2.ª vez) queda… |
|---|---|
| Teaser | La llamada en su cierre normal del Beat 4 |
| Entrada | Las 3 bandas grises en el cielo, los 3 pisos llenos y el mapa de batalla con el Río brillando |
| Intro de ronda | La ronda lista y el rival en la galleta 0 (la nariz roja en el Río). Empieza el "le toca a Maxi" |
| Interludio | La banda pintada, un piso menos y el mapa con el hito siguiente brillando, más la voz `pausa_<color>`. En la ronda 3, el estado de "antes del epílogo" |
| Antes del epílogo | El epílogo, con `maxi_ven` |
| Gag de derrota | Igual que "¡otra vez!" |
| Cierre A | El primer cuadro de la parte B |
| Cierre B | La foto ya está en el álbum (el registro se hace **antes**, B1 de HE-10). Se vuelve a la selección con la nave "¡Juntos!" estacionada. La presentación única de la nave, si se salta, deja la nave estacionada y suena `presenta` |

### 12.4 Música y SFX (todo CC0: Kenney o FreePD)

- **Tema de la batalla**: marcha chistosa y liviana a ≈ 100 BPM (ukelele, pizzicato y percusión de
  juguete). **Nada épico ni con tensión.** Durante las rondas va a −10 dB.
- **Motivo del Coleccionauta**: 2 compases de tuba y kazoo, que suenan cada vez que hace un gag grande
  (entrada, intro, despedida).
- **Interludio**: un "¡tadá!" corto y el motivo de Coco (marimba) cuando cambia de color.
- **Cierre**: el tema de Arcoíris en versión fiesta.
- **Ducking**: la música baja 8 dB mientras suena cualquier voz.
- **Volúmenes**: el estornudo y el "pum" van al 70 % del volumen de un pop de acierto. Nunca suena un
  golpe sin anticipación.

## 13. Assets

### 13.1 Existentes (se reutilizan)

| Asset | Dónde está | Uso |
|---|---|---|
| Rigs de los tres hermanos (piezas de cutout) | `assets/sprites/preview_*_rig/` | Fiesta B1-B3 y **caritas en las ventanitas** (§6), con la pieza `cabeza_casco` reducida y recortada por la ventanita |
| Retratos y barra del equipo, y nave de juguete con ventanitas | Modo equipo (HE-58 / HE-59) | Barra, "¡todos a la nave!" y B8 |
| Coco (`assets/sprites/personajes/coco_base.png`) y su lengua del motor del Río | Motor `rio` | Todas las cinemáticas. El cambio de color es un `modulate` con barrido. El "arcoíris de equipo" es un shader de degradé: **no lleva arte nuevo** |
| Cometa (`cometa_base.png`, `cometa_saludo.png`) | `assets/sprites/personajes/` | Hito, nave y B5 |
| Paisaje de Arcoíris (Claro, tréboles) | `scripts/planetas/arcoiris/paisaje_arcoiris.gd` (dibujo por código) | Fondo de la batalla. El **arcoíris del cielo** también va dibujado por código, sin asset |
| Sobre-estrella y polaroid | `assets/sprites/ui/recuerdos/` | Entrega de la foto (B6) |
| Video-llamada del Beat 4 (marco e imagen de papá) | Escena del ala (por implementar) | Teaser y B7 |
| Estrella UI, confeti y chispitas | Partículas de Godot | Cuenta regresiva, confeti y destellos |

### 13.2 Nuevos (para `disenador-personajes`)

Por orden de prioridad. Todos son **frontales**, con el pipeline del rig del stack §5.4 y el ancla
`assets/anclas/coleccionauta_referencia.png`.

| Id | Asset | Detalle | Lo usan |
|---|---|---|---|
| **A1** | **Rig de cutout del Coleccionauta** (frontal) | Las 10 piezas estándar, más: **antenas sueltas** (2, con pivote en la base, para el rebote); **gafas-lupa como pieza aparte** (se bajan a los ojos, resbalan a la boca y se suben a la frente); **bocas intercambiables** (sonrisa, "O" de sorbete, "achú" con los ojos cerrados, risa y pensativa de lado); **ojos intercambiables** (normales, con estrellitas, bizcos y espirales borrosas, A1-o); **manos contando** (3 y 2 dedos, A1-m); y la **pose sentada** (piernas sentadas, 1 pieza). Pantufla de conejo y crocs como en el ancla. **El chaleco no cambia** | Todo. También la pista de galletas y los gags de derrota, porque es el mismo rig que necesita HE-69 |
| A1-g | Mancha roja para los dos lentes | Sobrepuesta sobre las gafas, con forma de salpicón y bordes redondos | Gafas rojas (§6) |
| A1-n | Nariz pintada de rojo | Sobrepuesta | Intro del Río |
| A1-c | Calcetín (prop chico) | A rayas, chistoso | Epílogo, n = 3 |
| **A2** | **Mochila-torre de batalla, modular** | **Base** (el saco con cuerdas del ancla) + **3 pisos de vidrio transparente**, que se pliegan uno dentro del otro como un telescopio, cada uno con un **estado gris pintable** (región para `lienzo_libre`, encargo `colorear_zonas`, a coordinar con `disenador-niveles`) + **tapa** con 3 franjas pintables y una **bombilla doblada** de sorbete. El **cono y el patito de goma** van arriba de la tapa, para que se reconozca su canon. **Sin patas, sin antenas, sin cara y sin nada parecido a un bicho** (m7). También sirve para el hito del mapa | Entrada, interludios, epílogo, cierre y hito |
| **A3** | **Gotitas de color con carita** (roja, amarilla y azul) | 2 cuadros: la mano arriba y la mano abajo, saludando. Felices, nunca tristes ni atrapadas | Entrada E3 e interludios |
| A4 | Patito de goma suelto (prop) | Puede salir del mismo arte de A2 | Teaser y despedida |
| A5 | Mosquita de dibujo (prop chico) | Simpática, de 2 cuadros de aleteo | "Antes del epílogo" P1 |
| A6 | Máscara de ventanita | Círculo con borde de color, para recortar la `cabeza_casco` dentro de la nave de juguete de Formas. Coordinar con la figura de `disenador-niveles` (3 ventanitas en los colores de turno) | Caritas en las ventanitas |
| A7 | **Paraguas de colores** (opcional) | Abierto y cerrado | Aparición del hito en el mapa (§3.1) |
| A8 | Trébol gigante del Claro (si el paisaje por código no alcanza) | Un trébol a escala de personaje para esconderse y tropezar | Entrada E1 y despedida A3 |
| A9 | **Papá riéndose** (imagen fija) | Mismo encuadre que la imagen de la video-llamada del Beat 4. Imagen generada con anclas (`guia-estilo-generacion.md`), **no** cutout | Teaser T3 y B7 |

**Mientras no exista el rig A1**: Dev puede implementar todo con un **sprite único** recortado del ancla
(la pose frontal) y squash and stretch con `Tween`, y cambiar al rig cuando llegue. Los tiempos no
cambian.

## 14. Lo que este storyboard necesita de otros roles

**Para `guionista`** (dueño del texto; yo no lo edito):

1. **`arcoiris_batalla_rio_coco_risa`** dice "¡Le salió pintura hasta por las **orejas**!", y el
   Coleccionauta **no tiene orejas visibles** en su canon (tiene antenas con bolitas). Propuesta: "¡hasta
   por las **antenas**!". La animación DR4 ya está pensada para las antenas.
2. **`arcoiris_mapa_zona_2_completada`** en el interludio amarillo dura ≈ 4,5 s. ¿Se puede cortar en la
   batalla después de "¡amarillo limón!"? Ahorra 1,3 s. Si no, queda entera.
3. **Momentos memorables**: la calibración pide voces (`gafas_rojas` "¡veo todo rojo!", `caritas_ventanitas`
   "¡es nuestra nave!", `lupa_coleccionauta` "¡mis gafas!" y `mochila_estornuda_confeti`) que el guion no
   trae. Mi propuesta es **no agregar líneas**:
   - en las gafas rojas, reutilizar `rio_coleccionauta_reacciona_02` (ya dice "¡me pintaron las
     gafas-lupa!"), solo si la cola de voces está libre;
   - las caritas en las ventanitas, la lupa y el confeti van **sin voz**: son gags visuales y no
     necesitan palabras.

   Si el guionista prefiere voz en las caritas, que sea de **una palabra y ≤ 1 s**, porque ya hay muchas
   voces antes del interludio.
4. **Orden del interludio**: uso el de la nota 6 (Coco cuando sale el chorro y después `livianita`), que
   invierte el del §7 del guion. No cambia ningún texto. Conviene alinear el §7 del guion.

**Para `disenador-mecanicas` y `dev-godot`**:

5. **Entrada → ronda 1 sin toque** (§4): propongo que, tras la entrada, Coco aterrice en el hito del Río y
   la ronda arranque sola.
6. **Retomar**: ¿se repite la pantalla "¡todos a la nave!"? El §10 cubre los dos casos.
7. **Rondas de batalla vistas varias veces**: el salto "desde la segunda vez" se guarda **por familia**,
   no por perfil (§14.1).
8. **El gag de derrota necesita del motor**, para que el núcleo siga sin conocer minijuegos: que
   aspire sus elementos (gotas o piezas) hacia un punto y los devuelva en un estado dado. Propuesta
   en §14.1.

**Para `experto-ux-parvulo`** (auditoría del build): mirar con Maxi la **entrada** (si el aspirado de
las bandas le provoca algo parecido a "nos robaron"), el estornudo (que no lo asuste) y el enlace
interludio 3 + "antes del epílogo" (≈ 12 s seguidos): si se distrae ahí, se quita `livianita_3`
(−2,8 s).

### 14.1 Notas de implementación (AnimationPlayer)

- **Dónde**:
  - `escenas/nucleo/batalla.tscn` tiene un nodo `CinematicasBatalla` (`Node2D`) con un `AnimationPlayer`
    y una animación por id: `entrada`, `intro_rio`, `intro_formas`, `intro_parejas`, `interludio_rojo`,
    `interludio_amarillo`, `interludio_azul`, `antes_epilogo`, `cierre_a` y `cierre_b`.
  - El teaser va en la escena del ala; la aparición del hito, en `mapa_planeta.gd`; y B8, en la
    selección.
  - Las ids de las animaciones (`intro_rio`, etc.) son genéricas por ronda, así que HE-39 las reutiliza
    con su propio JSON. En `datos/batallas/arcoiris_final.json`, `cinematica_entrada: "entrada"` y
    `cinematica_cierre: ["cierre_a", "cierre_b"]`.
- **Sincronía con la voz: por pasos, no por segundos fijos.** Los tiempos de este documento son
  estimados. Implementar cada cinemática como una lista de **pasos**:
  `{animacion, voz, solape_s, aire_s}`. Cada paso reproduce su tramo de animación y su voz
  (`Audio.reproducir_voz(id)`), y el siguiente arranca cuando termina el audio + `aire_s`, o en
  `solape_s` si el paso lo pide (por ejemplo, la voz de Coco en I4 arranca en el estornudo). Las
  animaciones de "mientras habla" (bocas, gestos) van en bucle hasta que termina la voz. **No hay
  lip-sync**: hay una boca "hablando" de 2 cuadros, cada 0,12 s.
- **Estado por propiedades**: `banda_saturacion[3]`, `pisos_llenos` (0-3), `pisos_plegados` y
  `mochila_pintada[4]` son propiedades del nodo, que se animan con pistas de propiedad. Al cargar o
  retomar, se fijan desde `Progreso` (`rondas_ganadas`). Así, saltar una cinemática (`seek` al final +
  `estado_final_<id>()`) nunca desincroniza el cielo ni la mochila.
- **Saltar**:
  - en `Progreso`, a nivel de familia: `cinematica_vista(id) -> bool` y
    `marcar_cinematica_vista(id)`, que se marca **al terminar** la cinemática, no al empezarla;
  - con `vista == false`, un toque solo da una chispita;
  - con `vista == true`, un toque detiene la voz con un fundido de 0,15 s y aplica el estado final;
  - los gags de derrota usan su propio botón "¡otra vez!" desde la primera vez.
- **Rival**: un `coleccionauta.tscn` reutilizable (el rig A1 o el sprite provisional), con animaciones
  con nombre: `idle`, `saltar_a(pos)`, `aspirar`, `hipo`, `estornudar`, `sentarse`, `cansado`, `saltito`,
  `flotar`, `bizco`, `gafas_resbalan`, `gafas_rojas`, `girar_mochila`, `despedida`, `aplaudir` y
  `contar_dedos(n)`. La misma escena sirve para la pista de galletas.
- **Gags de derrota sin romper la regla de oro 4**:
  - `minijuego_base` orquesta la secuencia y llama a dos métodos virtuales del motor:
    `gag_derrota_aspirar(destino: Vector2) -> float` (devuelve cuánto dura) y
    `gag_derrota_devolver(perfil_siguiente: String) -> float`;
  - el núcleo solo sabe del rival y de las voces que trae el nivel (`equipo.voces_batalla`);
  - es una propuesta para `disenador-mecanicas`, que decide las firmas.
- **Cámara**: `Camera2D` fija. El único zoom es el de E3 (1,0 → 1,1 → 1,0). Las transiciones son una
  cortina de iris (shader circular, 0,3-0,5 s) o un fundido cruzado.
- **Capas (`z_index`)**: cielo 0, suelo 10, mochila 20, Coleccionauta 30, Coco 40, partículas 50, barra
  60 y botón "¡otra vez!" 70.
- **Entrada bloqueada** durante cada cinemática, salvo el salto, la casa (≥ 96 px, siempre activa: salir
  es seguro, GDD §6.8) y "¡otra vez!".

## 15. Dudas para el PO

1. **¿El Coleccionauta en cutout?** `escena_intro.md` (revisión del 07-Ago) sacó las cinemáticas
   narrativas del cutout, porque el rig no estaba a la altura del arte pintado. Estas cinemáticas
   **tienen que** ser cutout: están dentro del juego, dependen del estado y se saltan al estado final.
   Además, el rig del Coleccionauta (A1) **ya hace falta para jugar** (la pista y los gags de HE-69).
   ¿Aprobamos la excepción y el rig A1 con el pipeline de despiece?
2. **La video-llamada final de papá (B7) es opcional.** Suma ≈ 18 s, y papá tiene que grabar 3 líneas.
   Con ella, el cierre pasa de ≈ 47 s a ≈ 65 s (A + B). Una batalla p80 con una derrota queda en ≈ 14,8
   min, apenas bajo el tope de 15. ¿La incluimos?
3. **La fiesta de los tres en la parte B** (no en la A), para que la A quede en ≤ 20 s. La primera vez se
   ven seguidas.
4. **El paraguas** en el aterrizaje del hito (A7), o la alternativa sin arte nuevo (la mochila entra
   rebotando).
5. **La ronda 1 arranca sola después de la entrada**, sin pedir un toque en el mapa de batalla.

## 16. Tabla resumen de duraciones

Estimadas con las duraciones del guion, la primera vez y sin derrotas. "En M1" indica si suma a los 15
min de la batalla.

| Cinemática | Duración | Tope | Veces por batalla | Total | En M1 | Se salta |
|---|---|---|---|---|---|---|
| Teaser (escena del ala) | ≈ 10 s | 8-10 s | 1 (antes de la batalla) | 10 s | No | Desde la 2.ª vez |
| Aparición del hito en el mapa | 2,5 s | — | 1 | 2,5 s | No | Desde la 2.ª vez |
| Hito: tocar y voz de Cometa | 4,1 s | — | 1 | 4,1 s | Sí | — |
| "¡Todos a la nave!" (sin la espera de toques) | 2,5 s de voz + 4 s de despegue | — | 1 | 6,5 s | Sí | Despegue: desde la 2.ª vez |
| Entrada | 12,0 s | ≤ 12 s | 1 | 12,0 s | Sí | Desde la 2.ª vez |
| Llegada al mapa y arranque de la ronda 1 | 1,8 s | — | 1 | 1,8 s | Sí | — |
| Entrar a las rondas 2 y 3 desde el mapa (nombre + iris) | ≈ 1,2 s | — | 2 | 2,4 s | Sí | — |
| Intro de ronda | 4,0 / 3,9 / 4,0 s | ≤ 4 s (N7) | 3 | 11,9 s | Sí | Desde la 2.ª vez |
| Momentos memorables (gafas, caritas, lupa y confeti) | 1,6 / 1,8 / 2,1 / 2,0 s | — | 1 c/u | 7,5 s (las gafas no detienen el juego) | Sí | No |
| Interludio | 7,7 / 9,2 (7,9 con el recorte) / 7,0 s | 3-4 s en la ficha; **justificado en §7** | 3 | 23,9 s | Sí | Desde la 2.ª vez |
| Mapa de batalla: salto de Coco + `pausa_<color>` | 4,1 / 3,9 s | — | 2 | 8,0 s | Sí | — |
| Antes del epílogo | 4,8 s | ≤ 5 s | 1 | 4,8 s | Sí | Desde la 2.ª vez |
| Cierre, parte A | 19,8 s | ≤ 20 s | 1 | 19,8 s | Sí | Desde la 2.ª vez |
| Cierre, parte B (fiesta + foto + nave "¡Juntos!") | ≈ 27 s | — | 1 | 27,0 s | Sí | Desde la 2.ª vez |
| **Video-llamada de papá (OPCIONAL)** | ≈ 18 s | — | 0-1 | (18 s) | Sí | Desde la 2.ª vez |
| Gag de derrota (Río / Formas / Parejas §5.5) | 16,7 / 15,8 / ≈ 15 s (≈ 13-14 s desde la 2.ª derrota de la ronda) | — | 0-n | (≈ 1 de cada 3 batallas tiene una) | Sí | "¡Otra vez!" corta |

**Totales que suman a M1** (sin derrotas):

- **Sin la video-llamada**: ≈ **130 s (≈ 2,2 min)**. De esos, lo que la calibración presupuestó como
  "entrada, interludios y toques, antes del epílogo y cierre A + B" (1,75 min = 105 s) cuesta aquí ≈ 100
  s (entrada 12 + interludios 23,9 + mapa 8 + entradas a ronda 4,2 + antes 4,8 + cierre 46,8). **Cabe.**
  Las intros, los memorables y la entrada a la batalla (≈ 30 s) caen dentro de los minutos por ronda y del
  arranque que la calibración ya contaba.
- **Con la video-llamada**: ≈ **148 s (≈ 2,5 min)**, +18 s sobre el presupuesto del cierre. La batalla
  típica (≈ 10,8 min) queda en ≈ 11,1 min. La p80 con una derrota (≈ 14,6 min) queda en ≈ 14,9 min:
  **todavía bajo los 15**, pero sin margen (duda 2).
- **Con la pausa natural del mapa** (dos sesiones como caso normal, M1.2), ninguna sesión se acerca al
  tope.
