# Validación UX — HE-66: Batalla final de Arcoíris (y cierre de HE-58)

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 06-Oct-2026
- **Objeto auditado** (diseño, sin código de la batalla todavía):
  - `docs/fichas/modo-equipo.md` §14, "Batalla final de Arcoíris" (v3, `disenador-mecanicas`).
  - Verificación de HE-58: `modo-equipo.md` §1-§13 y `docs/fichas/motor-emparejar.md` §10, contra
    `docs/validaciones/2026-10-06_ux-HE-58-modo-equipo-parejas.md`.
  - Motores reales que la batalla reutiliza: `scripts/motores/rio/motor_rio.gd`,
    `datos/recorridos/arcoiris/z1_espiral.json`, `datos/niveles/arcoiris/zona1_claro/rio_semilla.json`,
    `scripts/motores/encajar/motor_encajar.gd` y `datos/niveles/arcoiris/zona1_claro/formas_semilla.json`.
- **Contra qué**: GDD §1 (tono), §3 (capítulos), §5 (reglas por perfil y reto real), §6 (10 reglas);
  `docs/perfil-jugadores.md`; desarrollo típico de 2 a 8 años.

---

## Parte 1. Cierre de HE-58: APROBADA

Revisé uno por uno los hallazgos de la validación de HE-58 en las fichas corregidas:

| Hallazgo | Dónde quedó | Estado |
|---|---|---|
| **B1** Puerta de turno (retrato, arrastre tras Maxi, bloqueo 400 ms obligatorio, pulso < 100 ms, parámetro `puerta_tras_semilla`) | `modo-equipo.md` §4.3 y §8 (`bloqueo_tras_puerta_ms` obligatorio > 0) | Incorporado completo |
| **B2** Sin gotita de Nicole y sin "¡uuuh!" | §2 R2 y R8, §4.1, §5.2 | Incorporado completo |
| **B3** El rival se mueve durante el pase; derrota con el siguiente al centro; voces en plural | §2 R6, §4.3, §5.5, §6, §11.4 | Incorporado completo |
| **M1** Sin `puntaje` en equipo; racha en arcoíris; retroceso con 3 | §5.2, §8; motor §10.1 | Incorporado |
| **M2** "Cada uno con su truco" | §5.2 y `intro_equipo_trucos` | Incorporado (voz PENDIENTE del guionista) |
| **M3** Ventanita de porra, Maxi intercalado, ritual de fin de turno | §4.1, §4.2, §4.3 paso 0 | Incorporado |
| **M4** Cometa/Coco tocables que repiten | §3.2 y §4.1 | Incorporado |
| **M5** "¡Juntos!" en `Rect2(640, 598, 240, 110)`, presentación única, invitación alternada, "¡Despegar!" en el mismo rect | §3.1, §3.2 | Incorporado |
| **M6** Vistazo (Brote 1-2 pares, equipo ≤ 3 pares) | §5.4; motor §10.2 | Escrito como "por confirmar con el PO" (correcto: cambia una cifra [PO]) |
| **M7** Vela solo con récord, sin urgencia, `vela_dormida`, desde zona 2 | Motor §10.1 y calendario §10.3 | Incorporado |
| **M8** Revancha contra la carta del Coleccionauta | Motor §10.3 | Incorporado |
| **M9** Tramos horneados, ficha "busca", demostración, 1 s a la vista | Motor §10.4 | Incorporado |
| **M10** Comodín y lupa inertes en el turno de Maxi (se eligió la opción 1) | §5.2; motor §10.3 | Incorporado |
| **m1-m11** | §13 de `modo-equipo.md` | Listados para Dev |

**Veredicto: HE-58 queda aprobada y se puede cerrar.** Las correcciones están bien incorporadas, sin
desvirtuarlas. Quedan tres pendientes que **no** bloquean el cierre de la validación, pero sí deben estar
resueltos antes de que termine HE-59 o HE-60:

1. **El PO tiene que confirmar M6** (cantidades del vistazo). Está bien marcado como pendiente en ambas
   fichas; sin su OK, `disenador-niveles` no puede calibrar `pasos_rival`.
2. **Voces `PENDIENTE` y conflictos del guion** (§8 de `modo-equipo.md`): `sube_ventanita`,
   `porras_fin_maxi`, `pares_juntados`, etc., y el `te_toca_*` que todavía dice "toca la pantalla". Si el
   build sale con el texto viejo, B1 queda roto por la voz. Eso es tarea del `guionista`.
3. **Residuo de medidas para HE-59** (menor nuevo, ver m5 más abajo): el hitbox de Coco y el botón casa
   quedan a 4-6 px del tablero.

---

## Parte 2. HE-66, Batalla final de Arcoíris

## Veredicto: APROBADA CON CAMBIOS (3 bloqueantes)

La idea es muy buena para esta familia. La mochila-torre que "estornuda" un color por ronda es un
indicador de avance sin números que hasta Maxi entiende. Las rondas ganadas nunca se pierden, el
reintento conserva lo logrado, el epílogo no se puede perder y en él Maxi es el mejor, y el Coleccionauta
termina recibiendo colores de regalo. Todo eso está en el tono del GDD §1. Que solo se usen motores que ya
existen es correcto.

El problema central es que el §14.3 dice que la regla de turno "ya está validada por UX", y **eso es
cierto solo para Parejas**. "Si aciertas, sigues; si fallas, pasa el turno" funciona en un memorice de
mesa. En un Zuma y en un encaje, tal cual está, produce tres problemas que frustran justo a quienes el
PO marcó como sensibles:

- en el Río, pierdes el turno por mala suerte;
- en Formas, puede que Sofía no llegue a jugar;
- en Formas, el turno de Maxi es más difícil que su propia ruta.

**HE-69 no puede implementarse hasta que `disenador-mecanicas` incorpore B1, B2 y B3 en el §14.
HE-66 no se cierra sin eso.** Los mayores tienen que quedar resueltos en la ficha o aceptados de forma
explícita por el PO para el playtest.

Conteo: **3 bloqueantes, 9 mayores y 9 menores.**

### Respuesta a los puntos pedidos

| Punto | Diagnóstico | Hallazgo |
|---|---|---|
| Duración y fatiga | Mi estimación realista es de **17 a 22 min** sin derrotas y de **22 a 25 min** con una. Hay que sumar los pases de tablet de verdad (8-12 s cada uno con niños, no 3 s), una intro por ronda, las cinemáticas y el epílogo con 6 pases. Maxi sostiene una actividad por turnos unos 5-8 min y "se aburre con historias donde hablan mucho" (`perfil-jugadores.md`). **No aguanta tres rondas seguidas**, y su mejor momento (el epílogo) queda al final, cuando probablemente ya se fue | **M1**, M2 |
| Aporte de Maxi | En el Río es real y factible (un toque, un reventón que saca gotas del río común), con dos ajustes. En Formas, **no**: la ficha le pide arrastrar con imán de 140 px, pero su ruta real usa `toque_lleva_a_casa: true` e `iman_tolerancia_px: 5000` | **B3** |
| Miedo al Coleccionauta | Riesgo **bajo** de miedo: Maxi "nada lo asusta". El riesgo real es otro: que "nos quitó los colores que ganamos" se lea como **perder lo ganado**, y Sofía "se frustra rápido". Además, si el robo se ve en el mapa, rompe la coherencia entre hermanos que van en zonas distintas | **M3**, m7 |
| Derrota sin culpa en cada ronda | Los tres gags están bien y heredan B3 (sin nombres, siguiente al centro). Solo falla la línea de logro común de ejemplo | m1, m2 |
| Abandono a la mitad | Se guardan las rondas, pero no el avance dentro de la ronda. Con un botón casa que Maxi puede tocar sin querer, se pierden hasta 5 min de trabajo de las hermanas | **M4** |
| Se entiende sin leer | Sí: la mochila de 3 pisos, el estornudo y el mapa de 3 hitos funcionan. Pero en pantalla compiten **tres indicadores** arriba (pista, mochila y HUD del motor, con números en el Río) | **M5** |
| Regla de capítulos | Que "¡Juntos!" sea invisible antes de ganar **cumple**: no es candado. Lo que falta escribir es que la batalla **no condiciona** el planeta 2 ni el cierre del capítulo de cada hermano | **M7** |
| Riesgos del §14.13 | 1 → M1; 2 → m8; 3 → B3; 4 → **confirmado y medido**, M5; 5 → m7; 6 → M3 | — |
| Contrato de turnos en motores reales | **Viable**, pero cuesta más que lo que estima el §14.3: los dos motores leen la configuración del perfil una sola vez y muestran números y récords propios | **M8** |

---

## Hallazgos bloqueantes

### B1. En el Río, "el disparo que no revienta pasa el turno" convierte la mala suerte en turno perdido

**Dónde**: §14.3, fila Ronda 1 ("el disparo que no revienta gasta su segunda oportunidad"; Sofía, "pasa
el turno en el acto" por la regla común).

**Problema**:

- En un Zuma, **la mayoría de los disparos no revientan, y no son errores**: son jugadas de preparación
  (poner una gota junto a otra de su color para armar el trío). Una niña de 5 años con guía revienta, a
  ojo, en 1 de cada 3 disparos.
- Peor todavía: a veces Coco carga un color que **no tiene pareja en el río alcanzable**. Ahí ningún
  disparo puede reventar, y el turno se pierde **por azar**. Para Sofía ("se frustra rápido") eso es
  "¡no es justo, me tocó un color malo!", y como la pierde ella, la culpa vuelve a tener nombre.
- El ritmo también se rompe: los turnos de Nicole y Sofía serían de 1 o 2 disparos, y habría 15 o más
  pases de tablet en una ronda. Son unos 3 min solo pasando la tablet.

**Corrección** (`disenador-mecanicas` en la ficha; `disenador-niveles` calibra):

1. En el Río, **el turno se mide en gotas, no en fallos**: Nicole y Sofía tienen **3 gotas por turno**
   (`gotas_por_turno: {"brote": 3, "estrella": 3}`) y Maxi, 1. Se ven sin números: **3 gotas en la mano
   de Coco** (la de la boca y dos de reserva) que se gastan una por disparo.
2. **No existe el "fallo" en el Río.** Un disparo que no revienta es neutro: suena el "plop" de
   inserción normal y no hay voz de fallo. Así la segunda oportunidad de Nicole no aplica en esta ronda,
   y queda escrito.
3. **Acierto = reventón** (alimenta la racha de M1). La cadena de Sofía vale 2, como propone la ficha.
   Con 3 reventones en un turno, el Coleccionauta retrocede.
4. **Coco nunca carga un color sin pareja en el río** en la batalla (equipo): siempre uno que ya tenga
   al menos 1 gota en el cauce. Se puede cambiar con Coco (regla normal) solo en los turnos de Nicole y
   Sofía.
5. El rival avanza en el pase, igual que en Parejas (B3 de HE-58).
6. Corregir la frase del §14.3 "la misma del modo equipo, ya validada por UX". Debe decir: "validada
   para Parejas. En el Río y en Formas, el turno se define en §14.3".

### B2. Sin tope por turno, Sofía puede quedarse sin jugar una ronda de la batalla "de los tres"

**Dónde**: §14.3, regla común "si aciertas, sigues" aplicada a Formas (y al Río si no se corrige B1).

**Problema**: el orden es Maxi → Nicole → Maxi → Sofía. En Formas, Nicole juega sin rotación, con la
silueta interior visible y su `objetivo_guiado`, y falla muy poco. En su primer turno puede encajar las 8
piezas que quedan de una silueta de 9 o 10, y **Sofía no llega a tocar la ronda**. En el Río sin B1 pasa
lo mismo al revés: una buena racha de Sofía limpia el río. Eso contradice la decisión del PO ("los tres
tienen que aportar"). Además, Sofía es la hermana celosa de Nicole: "Nicole hizo todo" es el conflicto
más fácil de anticipar.

**Corrección**:

1. **Tope de aciertos por turno en Formas**: `aciertos_max_turno: {"semilla": 1, "brote": 2,
   "estrella": 3}`. Al llegar al tope, el turno termina **en celebración** ("¡turno perfecto!", con el
   gesto corto del hermano), no como fallo. En Formas, un turno de Sofía con 3 piezas seguidas es
   además su racha de retroceso (M1): su "turno perfecto" empuja al Coleccionauta hacia atrás.
2. Un fallo ("no es este", pieza soltada sobre un hueco equivocado) pasa el turno: Nicole tiene su
   segunda oportunidad y Sofía pasa en el acto. **Soltar una pieza en el vacío no es fallo**: vuelve a la
   bandeja, que es lo que el motor ya hace con el resultado `"nada"`. Hay que escribirlo.
3. **Regla de diseño de la batalla**: `disenador-niveles` dimensiona cada ronda para que **cada hermano
   tenga al menos 2 turnos** en una partida típica. Con el tope, una silueta de 9 piezas da unos 7 por
   ciclo (1+2+1+3), así que alcanza para un ciclo y medio. Si no alcanza, se suben las piezas o se baja el
   tope.
4. El Río queda cubierto con B1 (3 gotas por turno).

### B3. El turno de Maxi en Formas es más difícil que su propia ruta, y en el Río un toque a Coco le roba el disparo

**Dónde**: §14.3, columna "Turno de Maxi" de las rondas 1 y 2.

**Problema**:

- **Formas**: la ficha pide "imán de 140 px; si la suelta lejos, vuelve; a los 2 intentos o 6 s se
  acerca a medio camino". Pero el nivel real de Maxi (`formas_semilla.json`) usa **`toque_lleva_a_casa:
  true`** (un toque y la pieza vuela sola a su lugar) e **`iman_tolerancia_px: 5000`** (soltarla en
  cualquier parte la encaja), además de `sin_error: true`. Tal como está, la batalla le exige a un niño de
  2 años un arrastre dirigido que **su ruta ya descartó**, delante de sus hermanas y sobre una silueta
  llena de huecos. Es la trampa de interacción que el GDD §6.4 y el §5 (Semilla) prohíben.
- **Río**: en `motor_rio.gd`, tocar dentro de `RADIO_TOQUE_COCO` (72 px) alrededor del centro **cambia
  la gota** en vez de disparar. Coco está al centro de la pantalla, justo donde un niño de 2 años toca
  primero. Con eso puede perder la gota "buena" que Coco le preparó.
- **Riesgo 3 del §14.13** ("el juego jugó por mí"): si la gota sale hacia el grupo sin relación con el
  dedo, Maxi no conecta su toque con el reventón.

**Corrección**:

1. **Formas, turno de Maxi**: la pieza con halo (la más grande que quede, con su lado corto ≥ 110 px)
   funciona con **las mismas reglas de su ruta**: `toque_lleva_a_casa` (al tocarla vuela a su lugar con
   estela, 0,5 s), `iman_tolerancia_px: 5000` si la arrastra y `sin_error`. El "medio camino tras 6 s" se
   reemplaza por que su hueco respire y por la voz "¡Maxi, la pieza que brilla!". Las otras piezas de la
   bandeja, en su turno, solo hacen el pulso, con sonido amable. No se pueden tomar.
2. **Río, turno de Maxi**:
   - toda la pantalla de juego dispara: el intercambio con Coco **se desactiva** en su turno, y un
     toque sobre Coco también dispara;
   - antes de su toque, el grupo objetivo **ya brilla con halo dorado** (`halo_idle`, como en Parejas),
     para que tenga algo a qué "apuntar";
   - la lengua **sale primero hacia su dedo** (0,1 s) y la gota curva con estela hacia el grupo. Si su
     toque cayó a menos de 150 px del halo, suena además "¡justo ahí!". Así el reventón es suyo, y se
     mantiene "siempre revienta".
3. Escribir en el §14.3: **"el turno de Maxi en una ronda de batalla nunca exige más que su ruta Semilla
   del mismo motor"**. Es la regla general para las batallas futuras (HE-39).

---

## Hallazgos mayores

### M1. Duración: 20 minutos seguidos superan a Maxi, y su mejor momento queda al final

**Dónde**: §14.3 ("15 a 18 min", "no pase de unos 20 min"), §14.10 y riesgo 1 del §14.13.

**Problema**: el cálculo de la ficha no cuenta lo que tarda pasar la tablet entre niños reales, las
intros por ronda, la pantalla "¡todos a la nave!" ni los 6 pases del epílogo. Maxi se aburre con
"historias donde hablan mucho", y la batalla suma 15-20 s de entrada, 6-8 s antes del epílogo, 30-45 s
de cierre más la foto y la video-llamada, y una intro de Coco por ronda.

**Corrección**:

1. **Meta: ≤ 15 min en total y ≤ 5 min por ronda** sin derrotas. Tamaños de partida que propongo
   (`disenador-niveles` calibra):
   - Río: **24 gotas** (no 30);
   - Formas: **8 piezas**;
   - Parejas: **8 pares** (4×4), no los 10 del §5.3, porque es la tercera ronda y el cansancio es
     mayor;
   - epílogo: ver M9.
2. **Pausas naturales**: al terminar el interludio de la ronda 1 y de la ronda 2, la pantalla queda en el
   **mapa de batalla** con el hito siguiente brillando. Para seguir, hay que **tocar el hito**; no
   avanza solo. Coco dice "¡ya volvió el rojo! ¿Vamos por el amarillo, o descansamos y volvemos
   después?". La casa está a la vista y salir ahí no cuesta nada. Así se diseña para **dos sesiones
   como caso normal**, no como excepción.
3. **Cinemáticas cortas**:
   - entrada ≤ 12 s, y desde la segunda vez se salta con un toque (ya está así);
   - antes del epílogo ≤ 5 s;
   - el cierre se parte en dos: la fiesta y el Coleccionauta pintado (≤ 20 s), y después la foto y la
     video-llamada. **Cada parte se puede saltar con un toque desde la segunda vez**.
   - Las intros de ronda tienen **una frase** (≤ 4 s).
4. **Maxi vuelve para el epílogo**: al empezar, Coco llama "¡Maxi, ven a pintar!" y su retrato salta en
   la barra. Si Maxi se fue, un hermano juega su parte (la regla del §4.3 de "si Maxi no está").
5. Criterio para el playtest de HE-64 y `tester-qa`: medir la duración por ronda y en qué ronda se va
   Maxi. Si se va antes del final de la ronda 1, se acorta el Río.

### M2. El turno de Maxi en Parejas, tercera ronda, sin salvaguarda de cansancio

**Dónde**: §14.3, ronda 3, que remite a §5.2.

**Problema**: en el modo equipo suelto, Maxi llega descansado a Parejas. En la batalla, Parejas llega
después de 10 a 12 minutos. El turno guiado está bien diseñado, pero con Maxi cansado la puerta de
**arrastre** después de su turno (B1 de HE-58), que hacen Nicole o Sofía, se repite muchas veces, y el
recordatorio de 10 s se dispara si Maxi deja la tablet y se va.

**Corrección**:

1. En la batalla, si en un turno de Maxi pasan **20 s sin ningún toque**, el turno se resuelve solo con la
   regla "Si sigue sin acertar" (las cartas del halo quedan a la vista y se forman solas a los 3 s). Coco
   dice "¡Maxi nos dejó un regalito!" y el equipo sigue. La partida nunca queda esperando a un niño de 2
   años que se fue.
2. Dejarlo como parámetro genérico del `GestorTurnos` (`semilla_auto_s: 20`), así sirve para las tres
   rondas.

### M3. "Nos quitó los colores que ganamos": no puede leerse como perder progreso, y el robo no puede salir de la batalla

**Dónde**: §14.1, §14.2 ("el cielo del planeta vuelve a quedar gris arriba"), §14.7 (la batalla
aparece cuando el **primer** hermano completa la zona 3) y riesgo 6 del §14.13.

**Problema**:

- Deshacer algo ganado es el disparador clásico del "ya no quiero jugar" a los 8 años, y Sofía se
  frustra rápido.
- **Coherencia**: si el cielo del **mapa** queda gris, ¿qué ve Maxi, que va en la zona 1 y solo devolvió
  el rojo? ¿Y Nicole, que en la zona 2 sigue devolviendo amarillo a un cielo que "ya le robaron"? El robo
  global choca con el progreso por hermano (`Progreso`, por hermano).

**Corrección**:

1. **El robo existe solo dentro de la escena de la batalla**: el cielo gris y la mochila con tres pisos se
   ven en `batalla.tscn` y en sus cinemáticas. **El mapa de cada hermano nunca pierde color**. Ahí solo
   aparece el hito de la mochila-torre, chistoso.
2. En la entrada, los colores **se ven intactos y contentos** dentro de los pisos transparentes de la
   mochila: rebotan y saludan, no están atrapados ni llorando. Coco dice de inmediato: "¡están guardados
   ahí! ¡Los vamos a sacar juntos!". Es un rescate, no una pérdida.
3. Respuesta de UX a la **Pregunta PO 14**: este híbrido (aspira el arcoíris del cielo de la escena de
   batalla, no el del mapa) es aceptable. La alternativa de "trae colores robados de otro lado" queda como
   **respaldo para el playtest** si alguien reacciona con "¡nos robó lo que ganamos!".

### M4. Salir a la mitad de una ronda pierde hasta 5 minutos de trabajo, y la casa la puede tocar Maxi

**Dónde**: §14.6 ("Lo que no se guarda: el avance dentro de una ronda sin terminar… perderlo no duele").

**Problema**: el GDD §6.8 dice que salir siempre es seguro. En una batalla de tres, la salida más
probable es **accidental**: Maxi toca la casa (100 × 96 px, arriba a la derecha) o se acaba el tiempo de
la tablet. Perder 4 o 5 minutos de una silueta casi terminada, delante de Sofía, sí duele. Además,
`motor_encajar.gd` **ya guarda el avance pieza a pieza** (`_guardar_piezas_ronda`), pero lo hace por
`id_perfil`, que en equipo está vacío.

**Corrección**:

1. Guardar el estado de la ronda en curso en el bloque de la batalla (`equipo.batallas.<id>.parcial`):
   - Río: las gotas que quedan y su orden;
   - Formas: los huecos llenos;
   - Parejas: los pares formados.

   Se guarda **al terminar cada turno**, no en cada toque. Al volver, el Coleccionauta parte en la
   galleta 0, que es lo generoso.
2. El motor recibe el parcial a través de `batalla.gd` con un método genérico
   (`restaurar_parcial_equipo(estado)`). El núcleo sigue sin saber qué juego es.
3. No se agrega confirmación para salir (sería un menú, GDD §6.4). Basta con que salir no cueste nada.

### M5. La pantalla de batalla no cabe: la pista y la barra tapan el Río y Formas, y hay tres indicadores arriba

**Dónde**: §14.3 ("hay que verificar que no tape el cauce"), §14.4 ("mochila-torre siempre a la vista,
arriba a la derecha") y layout del §4.1 (pista `Rect2(0, 0, 1280, 100)`, barra `Rect2(0, 610, 1280,
110)`).

**Medido en los datos reales**:

- **Río** (`z1_espiral.json`: centro (640, 372), radio de 300 a 150, escala [1.6, 0.95], gota de radio
  26): el cauce sube hasta **y ≈ 72** en la parte de arriba de la espiral (se mete 28 px en la pista) y
  baja hasta **y ≈ 696**, mientras la entrada viene de (160, 800). **La barra del equipo (y 610-720) tapa
  la entrada y la vuelta inferior del río.** Además, el HUD del motor está en `Rect2(470, 14, 340, 74)`
  (puntos y récord) y `Rect2(1040, 34, 200, 20)` (barra de río), dentro de la pista.
- **Formas** (`motor_encajar.gd`): `ZONA_FIGURAS = Rect2(236, 118, 640, 590)` llega hasta **y 708**, y se
  mete 98 px en la barra del equipo. La barra de progreso de ranuras y las medallas están arriba
  (y ≈ 18-110), en la pista. El botón de Cometa está abajo a la derecha, en la barra.
- **Arriba a la derecha** se juntan el botón casa (`1172-1272`), la mesa del equipo con su cinta y,
  según el §14.4, la mochila-torre.

**Corrección**:

1. **Zona de juego común a todas las rondas de batalla**: `Rect2(0, 110, 1280, 490)` (y 110-600).
2. **Río**: un recorrido propio, `datos/recorridos/arcoiris/batalla_espiral.json`, que quepa ahí. Punto
   de partida: centro (640, 355), `radio_inicio` 230, `radio_fin` 120, `escala` [2.0, 0.9], radio de gota
   22, y entrada desde la izquierda en y ≈ 560, no desde abajo. Hay que verificar que el cauce más su
   glaseado quede entre y 112 y y 598.
3. **Formas**: `zona_figuras: [150, 118, 700, 474]` y `zona_bandeja: [880, 118, 360, 474]`.
4. **Un solo indicador de batalla, sobre el propio Coleccionauta**: la mochila-torre de tres pisos va **en
   su espalda, en la pista** (es su canon). Pierde un piso cuando se gana una ronda. No hay un widget
   aparte de mochila arriba a la derecha. El estornudo grande del §14.4 ocurre en el interludio, a
   pantalla completa.
5. **En las rondas de batalla, el HUD propio de cada motor no se dibuja**:
   - en el Río no se ven la píldora de puntos y récord, la barra de río, "+N", "¡Cadena x3!" ni el cartel
     "¡Glu glu glu!" con puntaje;
   - en Formas no se ven las ranuras, las medallas ni los destellos por pieza.

   Así se cumple R2 y M1 de HE-58: en equipo no hay números. **El avance de la ronda** lo muestra la cinta
   de la mesa del equipo, a la derecha de la pista. Es la misma pieza de UI en las tres rondas, y se llena
   con gotas, piezas o pares.
6. En la pista quedan, de izquierda a derecha: Cometa (M6), x 8-118; las galletas, x 130-930; la mesa con
   la cinta, x 940-1150; la casa, x 1172-1272. Hay ≥ 22 px entre la mesa y la casa. Como la mesa no es
   tocable, alcanza.

### M6. ¿A quién se toca para repetir la instrucción? En el Río, tocar a Coco cambia la gota

**Dónde**: M4 de HE-58 puso a **Coco** a la izquierda de la pista como objetivo para "repite". En la
batalla eso choca con el Río y con Formas.

**Problema**:

- En el Río, Coco está en el centro y **tocarlo intercambia la gota** (`intercambiar()`).
- En Formas, Coco es la anfitriona de la izquierda.
- Con un segundo Coco en la pista, hay dos Cocos en pantalla, y uno de ellos no repite nada. El GDD §6.2
  dice "**tocar a Cometa repite la instrucción**".

**Corrección**: en **todas las rondas de batalla**, el objetivo de "repite" en la pista es **Cometa**
(hitbox `Rect2(8, 4, 110, 96)`). Repite la regla de la ronda en una frase y de quién es el turno. El Coco
del motor sigue con su función propia (disparar o cambiar la gota en el Río; reaccionar en Formas). Para
Parejas en equipo fuera de la batalla, `disenador-mecanicas` decide si unificar también con Cometa. Yo lo
recomiendo, por consistencia.

### M7. Regla de capítulos: la batalla no puede condicionar el planeta 2 ni el cierre del capítulo de cada hermano

**Dónde**: §14 ("la batalla **cierra el primer planeta**"), §14.10 punto 6 (la video-llamada de papá con
el gancho del planeta 2 va en el cierre de la batalla) y GDD §3 ("cada capítulo cierra en celebración";
la pieza llega con la zona 3; "sin bloquear el capítulo siguiente").

**Problema**: la batalla exige a los tres juntos, que es una condición **social**, no de habilidad. Si
el gancho del planeta 2 o el viaje dependen de ella, Sofía puede quedar trabada por el humor de Maxi.
Eso es un candado aunque no se dibuje un candado. Que "¡Juntos!" sea invisible antes de ganar **está
bien**: no es candado, porque no se ve nada bloqueado.

**Corrección** (escribirlo como regla en el §14.7):

1. **El viaje al planeta 2 depende solo de la pieza** (zona 3, por hermano), nunca de la batalla.
2. **El gancho canónico del planeta 2** sigue en la video-llamada de la escena del ala, que cada hermano
   ve por su cuenta. La video-llamada del cierre de la batalla es un **extra familiar**: papá ve la foto
   de los tres. No es el único cierre del capítulo.
3. Hasta que se gane, el hito de la batalla en el mapa es una **invitación**, no un pendiente: no tiene
   signos de alerta, no parpadea y no tiene voz que insista más de una vez por visita al mapa.
4. Para HE-17: UX recomienda que **el ala no se gane en la batalla**, por la misma razón.

### M8. El contrato de turnos es viable en los motores reales, pero falta trabajo que, si se omite, aparece como fallas de UX

**Dónde**: §14.3, "Trabajo de motor", que solo enumera `notificar_acierto`, `terminar_turno`, la pausa y
la capa de Maxi.

**Lo que muestran los motores**:

- Los dos leen la configuración que depende del perfil **una sola vez**:
  - `motor_rio.gd` lee `_guia` en `_configurar_desde_nivel`;
  - `motor_encajar.gd` lee `_sin_error`, `_iman`, `_rotacion_por_toque`, `_enderezar`,
    `_objetivo_guiado`, `_lado_minimo_bandeja` y `_giro_cuenta_fallo`, y además usa
    `obtener_perfil_dificultad()` en `_al_mover` para decidir si resalta el hueco cercano.
- El Río es **en tiempo real**: después del disparo, la bala vuela, se inserta y puede venir un
  retroceso en cadena (`logica.reventaron` con `cadena`).
- Los dos tienen **derrota, récord y celebración propios**:
  - Río: `_al_terminar`, `_guardar_record`, `celebrar(10 + ...)`;
  - Formas: `limite_intentos`, `_disparar_derrota_gag`, destellos por pieza y guardado parcial por
    `id_perfil`.

**Corrección** (lista para `disenador-mecanicas` en el §14.3 y para estimar HE-69):

1. **Capa de perfil por turno**: cada motor expone `aplicar_perfil_turno(perfil)`, que se llama en
   `turno_iniciado`.
   - Río: la guía, el intercambio permitido y la regla de carga de B1.4.
   - Formas: `sin_error`, imán, `toque_lleva_a_casa`, el resaltado del hueco cercano, `enderezar` y la
     rotación. Al empezar el turno de Sofía, las piezas de la bandeja **giran a un ángulo al azar** con un
     "fiu" visible; al empezar el de Nicole, **se enderezan**. Nunca cambian sin animación.
   - `obtener_perfil_dificultad()` debe devolver el perfil **del turno** en equipo, igual que
     `obtener_id_personaje()` en el §11.3.
2. **El turno termina en un estado estable**: en el Río, `terminar_turno()` se llama solo cuando no hay
   balas en vuelo ni retroceso en curso. Si no, el reventón en cadena ocurre ya en el turno siguiente y
   se le acredita a otro hermano. En Formas, una pieza "flotando chueca" (Sofía, 2,5 s) se resuelve antes
   de cerrar el turno.
3. **Pausa real**: con `entrada_bloqueada_cambio(true)`, el Río detiene `logica.avanzar()` y las balas.
   La ficha ya lo pide; lo nuevo es que también se detenga durante el ritual de Maxi y el pase.
4. **En equipo se apaga lo individual**: récord, estrellitas, derrota propia (el remolino del Río y
   `limite_intentos` de Formas), destellos por pieza, guardado parcial por perfil y `celebrar()`. Al
   ganar, el motor solo emite `completado`, y `batalla.gd` hace el interludio. En el Río, además, el
   remolino no pulsa en rojo y Coco no suda ni tiembla (con el tope del 70 % esa señal de peligro no
   corresponde).
5. Prueba de QA obligatoria: con un nivel de batalla cargado, **ningún texto con dígitos se dibuja** en la
   escena del motor (R2).

### M9. El epílogo con 6 pases y puerta es largo para un juego que no se puede perder

**Dónde**: §14.3, epílogo ("6 partes, 2 por hermano, una por turno").

**Problema**: son 6 pases con puerta (y arrastre después de Maxi) para 6 toques de relleno, al final de
la sesión y con el cansancio más alto. La puerta existe para que no se roben turnos que importan, y aquí
nada se puede perder.

**Corrección**:

1. **El epílogo no usa puerta ni pista**: el retrato de quien sigue vuela a la barra con "¡ahora
   Nicole!" y el siguiente toque pinta por ella. Si pinta otro, no pasa nada.
2. **3 partes grandes, una por hermano**, y un cierre "**¡todos juntos!**": la última parte (la tapa de
   la mochila) la rellenan los tres tocando por turno su ventanita de la barra, y cada toque agrega una
   franja de su color. Nada de toque simultáneo (GDD §6.4).
3. La paleta de Nicole y Sofía tiene muestras de ≥ 96 px, porque Maxi está mirando y va a querer tocar.

---

## Hallazgos menores

- **m1. Logro común después de una derrota de ronda**: "¡igual le sacamos el rojo!" no sirve si se
  pierde la ronda 1, porque todavía no se sacó ningún color. La línea debe hablar de **lo conservado en
  esa ronda**: "¡igual reventamos un montón de gotas!", "¡ya pusimos 5 piezas!" o "¡igual juntamos 6
  parejas!". Encargo al `guionista`.
- **m2. El gag de Formas** ("salen girando como trompos"): las piezas tienen que caer **en el estado del
  perfil del turno siguiente**, derechas si le toca a Nicole o a Maxi, para que el gag no le deje a Nicole
  piezas giradas que ella no sabe enderezar.
- **m3. Los hitos del mapa de batalla** responden al toque en menos de 100 ms (se menean y Coco nombra el
  juego), pero solo el hito que brilla lleva a jugar. Los otros nunca saltan rondas.
- **m4. Arranque solitario**: nada impide que Maxi toque solo los tres retratos de "¡todos a la nave!" y
  entre. Si en el turno de un hermano mayor nadie abre la puerta después de los 2 recordatorios (m5 de
  HE-58), Coco dice "¡esperemos a Nicole!" y **la casa se agranda un 10 % y respira**. Salir no cuesta
  nada (M4).
- **m5. Residuo de HE-58** (aplicar en HE-59): el hitbox de Coco o Cometa `Rect2(8, 4, 110, 110)` llega a
  y 114 y el tablero empieza en y 110, así que se superponen 4 px. La casa termina en y 104, a 6 px del
  tablero. Hay que dejar **≥ 24 px**: el tablero empieza en **y 128** (`Rect2(40, 128, 1200, 472)`) o el
  hitbox de Cometa baja a 96 px de alto.
- **m6. Destellos de la batalla (Pregunta PO 10)**: desde UX da lo mismo 100 o 50. Lo que importa es que
  el "+N" tenga el mismo tamaño bajo cada retrato y que suene una sola vez. 100 marca bien que es "más
  grande que una estación".
- **m7. Tono del Coleccionauta** (riesgo 5 del §14.13): el riesgo de miedo es bajo según el perfil de
  Maxi, pero hay tres salvaguardas baratas:
  - el aspirado suena a **sorbete con bombilla** ("sluuurp" corto, ≤ 1,5 s), nunca a motor de aspiradora,
    que es un sonido que asusta a muchos niños de 1 a 3 años;
  - el cielo de la escena se agrisa **solo en la franja del arcoíris**, sin oscurecer toda la pantalla;
  - la mochila-torre no tiene patas, antenas ni nada parecido a un bicho, porque Nicole les tiene miedo
    a los bichos y Sofía los rechaza.
  - En el teaser de la video-llamada, **papá se ríe** cuando se cuela el Coleccionauta, así nadie lee
    "papá está en peligro".
- **m8. Pregunta PO 9 ("¿con dos?")**: la regla del §4.3 ("si Maxi no está, un hermano mayor juega su
  turno guiado") ya resuelve el caso de Maxi dormido sin cambiar la decisión del PO, porque los **tres
  retratos** juegan y uno de ellos es jugado por otro. UX recomienda escribirlo así en el §14.7. Hay que
  agregar que la batalla **no puede verificar quién está físicamente**, así que `minimo_hermanos` se
  refiere solo a los retratos.
- **m9. Respuesta a la Pregunta PO 8**: UX recomienda `"primer_hermano"`. Es generoso, cada uno juega con
  su dificultad y, con M3.1, no genera incoherencias entre los mapas.

---

## Qué sí está bien (no tocar)

- La mochila-torre que estornuda un color por ronda, sin "1/3" ni barras, y el mapa de 3 hitos.
- Las rondas ganadas nunca se pierden, el reintento conserva lo logrado y el Coleccionauta vuelve a la
  galleta 0: el equipo siempre termina ganando.
- Que el epílogo no se pueda perder, y que la lección del arco (regalar colores) se viva como juego, con
  Maxi como protagonista.
- Parejas como ronda final [PO]: es la mecánica que Maxi ya conoce y ama.
- Que no haya pieza de la nave en la batalla, y que la foto de los tres hermanos sea el premio familiar.
- "¡Juntos!" invisible hasta ganar y la presentación única al volver a la selección.
- La arquitectura de `batalla.gd` que no conoce minijuegos y que es reutilizable para HE-39.

## Para cerrar HE-66

1. `disenador-mecanicas` incorpora **B1, B2 y B3** en `modo-equipo.md` §14. Sin eso, HE-69 no arranca.
2. M1 a M9 quedan resueltos en la ficha o con aceptación explícita del PO para el playtest. M3.3 y M7
   tocan preguntas del PO (14, y HE-17).
3. `disenador-niveles` recibe los tamaños de M1.1, el recorrido de batalla de M5.2 y la regla "cada
   hermano ≥ 2 turnos por ronda" de B2.3.
4. Los menores van directo a la implementación (HE-69) o a voces y cinemáticas (HE-67 y HE-68).
5. La auditoría del build (HE-64 o la de HE-69) se enfoca en:
   - la duración real por ronda y el momento en que se va Maxi (M1);
   - si Maxi siente suyo el reventón del Río (B3);
   - si alguien dice "nos robó lo que ganamos" (M3);
   - que no se vea ningún número en las rondas (M5.5 y M8.5).

---

## Re-auditoría HE-66

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 07-Oct-2026
- **Objeto**: `docs/fichas/modo-equipo.md` v4 (06-Oct-2026), §14 completo (14.1-14.15) y los cambios
  relacionados en §4.1, §5.3, §11, §12 y §13.
- **Contra qué**: los hallazgos de la Parte 2 de este documento, GDD §6, `docs/perfil-jugadores.md` y
  los motores reales (`scripts/motores/rio/logica_rio.gd`, `motor_rio.gd`).
- **Corrección del conteo**: la auditoría anterior tiene **3 bloqueantes, 9 mayores (M1 a M9) y 9
  menores (m1 a m9)**. Cualquier referencia a "8 mayores" (en resúmenes o en el tablero) está mal: son
  nueve.

## Veredicto: APROBADA CON CAMBIOS (0 bloqueantes)

Los 3 bloqueantes y los 9 mayores están incorporados en la ficha, completos y sin desvirtuarlos. El §14
es ahora una especificación sólida: el Río mide gotas y no fallos, Formas tiene tope por turno, el turno
de Maxi nunca exige más que su ruta, la batalla dura lo que aguanta Maxi y nada condiciona el capítulo.

Las correcciones introdujeron **dos mayores nuevos**: una contradicción aritmética entre M1.1 (8 piezas)
y B2.3 (≥ 2 turnos por hermano), y un hueco del Río (el reventón "siempre" de Maxi no está garantizado
por la lógica real). También introdujeron **un mayor de layout** (Formas queda a 14 px de la casa) y
cuatro menores. **Ninguno es bloqueante.** Se corrigen en la ficha, o en la calibración de
`disenador-niveles`, antes de que HE-69 implemente las rondas 1 y 2.

### Verificación punto por punto

| Hallazgo | ¿Resuelto? | Dónde quedó en `modo-equipo.md` |
|---|---|---|
| **B1** Río: turno en gotas, sin fallo | **Sí** | §14.3, regla común (l. 982-991), con la frase corregida "validada para Parejas" (B1.6). Tabla, fila Ronda 1 (l. 1010): 3 gotas por turno, visibles en la mano de Coco, disparo neutro con "plop", sin segunda oportunidad, cadena de Sofía = 2. Carga con pareja (l. 1018-1020). Datos `gotas_por_turno`, `sin_fallo`, `carga_con_pareja` (l. 1247-1249). El rival avanza en el pase por la regla común (l. 985-986). QA (l. 1324) |
| **B2** Formas: tope por turno y ≥ 2 turnos | **Sí** (ver N1) | Tabla, fila Ronda 2 (l. 1011): fallo = hueco equivocado; vacío = no es fallo (`"nada"`); tope 2 para Nicole y 3 para Sofía. "Turno perfecto" en celebración (l. 1015-1017). Regla ≥ 2 turnos (l. 1021-1025). Datos `aciertos_max_turno` (l. 1254). Gestor (l. 1511). QA (l. 1323) |
| **B3** Maxi: nunca más que su ruta | **Sí** (ver N2) | Regla general (l. 993-994). Formas: `toque_lleva_a_casa`, `iman_tolerancia_px: 5000`, `sin_error`, pieza ≥ 110 px y las otras inertes (l. 1011, 1257-1258). Río: intercambio apagado, toque sobre Coco dispara, halo previo, lengua al dedo, "¡justo ahí!" a < 150 px (l. 1010, 1250). QA (l. 1325) |
| **M1** Duración ≤ 15 min | **Sí** | §14.3 (l. 1044-1059): metas, 24 gotas, 8 piezas, 8 pares 4×4, río que se detiene en el pase y tope del 70 %, pausas en el mapa de batalla que no avanzan solas, y el criterio para el playtest. Cinemáticas con topes (§14.10, l. 1331-1336 y 1350-1359). Maxi llamado al epílogo (l. 1032-1033) |
| **M2** Turno de Maxi que se resuelve solo a los 20 s | **Sí** | §14.3 (l. 995-1001), con la jugada automática de cada ronda. `semilla_auto_s: 20` (l. 1259, 1510). Fila Ronda 3 (l. 1012) |
| **M3** El robo solo en la escena | **Sí** | §14.2 (l. 952-965): el mapa nunca pierde color, colores contentos, "¡están guardados ahí!", sorbete, sin bicho y el respaldo para el playtest. §14.10 punto 2 (l. 1341-1342). §14.14 (l. 1433). QA (l. 1321) |
| **M4** Parcial de la ronda en curso | **Sí** (ver N6) | §14.6 (l. 1112-1123), incluido el epílogo. Guardado `parcial` (l. 1284-1287) y API `guardar/obtener/borrar_parcial_batalla` (l. 1299-1301). Motores con `obtener/restaurar_parcial_equipo` (l. 1497-1499). Sin confirmación al salir. QA (l. 1318) |
| **M5** Layout y un solo indicador | **Sí** (ver N3) | §14.15, layout (l. 1437-1451): zona común `Rect2(0, 110, 1280, 490)`, `batalla_espiral.json` con entrada por la izquierda, zonas de Formas. Mochila-torre en la espalda como único indicador (§14.4, l. 1064-1067). Sin HUD del motor (l. 1452-1455). Avance en la cinta de la mesa |
| **M6** Cometa repite | **Sí** | §4.1 (l. 156), unificado también fuera de la batalla. §5.3 (l. 310). §14.15 (l. 1441, 1456-1458). No queda ninguna mención a "tocar a Coco para repetir" |
| **M7** La batalla no condiciona nada | **Sí** | §14.7 (l. 1155-1164): viaje solo por la pieza, gancho canónico en la escena del ala, hito-invitación sin alerta y "el ala no se gana en la batalla". §14.10 punto 6 (l. 1357-1358). QA (l. 1322) |
| **M8** Trabajo de motor | **Sí** (ver N5) | §14.15, "Trabajo de motor que falta" (l. 1460-1512): `aplicar_perfil_turno`, perfil del turno en `obtener_perfil_dificultad()`, turno cerrado en estado estable, pausa real, todo lo individual apagado, parcial, jugada automática y QA sin dígitos (también en l. 1319) |
| **M9** Epílogo sin puerta, 3 partes y "¡todos juntos!" | **Sí** | §14.3 (l. 1026-1033). Datos `confirmar_turno: false` y `rival: null` (l. 1244). `lienzo_libre` con muestras ≥ 96 px (l. 1507-1508). Modo sin puerta del gestor (l. 1512) |
| **m1-m9** | **Sí**, salvo un residuo (N4) | Tabla "Para Dev: menores de HE-66" (l. 1527-1539). m5 también en §4.1 (l. 158) y §13 (l. 914) |

### Hallazgos nuevos introducidos por las correcciones

#### Mayores

**N1. Formas con 8 piezas no alcanza para "cada hermano ≥ 2 turnos" (choque entre M1.1 y B2.3).**

- **Dónde**: §14.3, l. 1023 ("un ciclo encaja hasta 7 piezas") y l. 1049 ("Formas: 8 piezas").
- **Problema**: con el tope {1, 2, 3} y el orden M → N → M → S, una partida sin fallos se juega así: M1,
  N2, M1, S3 (7 piezas) y M1 (8). **Nicole y Sofía juegan un solo turno cada una**, y es exactamente el
  "¿y yo cuándo?" que B2 quería evitar. Nicole casi no falla en Formas, así que este es el caso típico, no
  el extremo. La ficha delega la solución ("si no alcanza, se suben las piezas o se baja el tope"), pero
  el número que entrega a `disenador-niveles` ya la incumple. El error de origen es mío: propuse las dos
  cifras en la auditoría anterior sin cruzarlas.
- **Corrección**: el mínimo para que cada uno tenga 2 turnos sin fallos es **2 ciclos menos el último
  turno de Sofía, más al menos 1 pieza para ella**. Con el tope {1, 2, 3}, son **12 piezas**
  (7 + 1 + 2 + 1 + 1). Mi recomendación es **Formas = 12 piezas manteniendo el tope de Sofía en 3**: es
  su racha de retroceso y su reto real (Sofía necesita reto, no "dificultad de bebé"). Encajar es rápido,
  así que se mantiene la meta de ≤ 5 min por ronda. Si el playtest dice que se alarga, la alternativa es
  {1, 2, 2} con 11 piezas, sabiendo que en Formas Sofía pierde el retroceso. `disenador-niveles` hace la
  misma cuenta para el Río y para Parejas (8 pares) con el simulador, y la escribe en la ficha de nivel.

**N2. En el Río, el "siempre revienta" de Maxi no está garantizado: la lógica real necesita 3 gotas.**

- **Dónde**: §14.3, fila Ronda 1, turno de Maxi (l. 1010) y carga con pareja (l. 1018-1020).
- **Problema**: `logica_rio.gd`, `_reventar_en()`, solo revienta tramos de **3 o más** (`if n < 3:
  return 0`). Para que la única gota de Maxi reviente, en el cauce tiene que existir un tramo de **2**
  del mismo color. La regla `carga_con_pareja` solo garantiza **1** gota en el cauce. Al final de la
  ronda, cuando quedan gotas sueltas, puede no haber ningún tramo de 2, y entonces el turno de Maxi no
  aporta. Eso rompe R5 [PO] ("su turno siempre aporta") y el B3 que esta misma ficha declara resuelto. Si
  no se escribe, Dev lo va a resolver de cualquier forma.
- **Corrección** (escribirla en §14.3 y en `aplicar_perfil_turno` del Río): en el turno de Maxi, Coco
  carga el color del **tramo más largo** del cauce y el halo va sobre ese tramo. **Si no hay ningún tramo
  de 2 o más, la bala de Maxi revienta con su tramo aunque mida 1** (umbral Semilla = 2, solo para su
  bala y solo en la batalla). Así revientan 2 gotas: es su reventón, chico pero real. QA agrega el caso
  "cauce sin tramos de 2, turno de Maxi → revienta".

**N3. Formas queda a 14 px de la casa y a 18 px de la barra: rompe la regla de 24 px que la misma ficha
fijó.**

- **Dónde**: §14.15, l. 1451 y §14.9, l. 1255-1256 (`zona_figuras: [150, 118, 700, 474]` y
  `zona_bandeja: [880, 118, 360, 474]`), contra l. 1442 ("cualquier elemento tocable del motor queda a
  24 px o más de Cometa y de la casa").
- **Problema**: las cifras son mías (M5.3) y no respetan el m5 que pedí en la misma auditoría. La
  bandeja (x 880-1240) queda debajo de la casa (x 1172-1272, que termina en y 104), con su borde superior
  en y 118: **14 px**. Justo ahí Maxi toca la pieza con halo en su turno, y tocar la casa por accidente es
  la salida más probable (M4). Abajo, las dos zonas terminan en y 592 y las ventanitas de porra
  (tocables, ≥ 96 px) empiezan en y 610: **18 px**. Con el parcial de M4 no se pierde nada, por eso no es
  bloqueante, pero sí es una fricción evitable cada vez.
- **Corrección**: `zona_figuras: [150, 128, 700, 456]` y `zona_bandeja: [880, 128, 360, 456]` (y 128-584:
  24 px arriba y 26 px abajo). Con eso, la regla de "pieza de Maxi con lado corto ≥ 110 px" sigue
  cabiendo. Además, que QA mida la separación en el Río (el disparo cubre toda la zona: ningún punto del
  cauce ni de la reserva de Coco a menos de 24 px de la casa).

#### Menores

- **N4. Residuo de m1 en el encargo al guionista.** El §14.11 (l. 1380) todavía pide "¡igual le sacamos
  el rojo!", la línea que m1 descartó y que el §14.5 (l. 1104-1106) prohíbe. Si el `guionista` trabaja
  desde el §14.11, se graba la línea mala. **Corrección**: reemplazarla por "un logro común sobre lo
  conservado en la ronda (gotas, piezas o parejas), ver §14.5", igual que en §14.15 (l. 1524).
- **N5. Las "firmas exactas" del `GestorTurnos` (§11.4) no se actualizaron.** El §11.4 (l. 773-802) dice
  que el motor "solo" llama `notificar_acierto()` y `terminar_turno()`. Pero el §14.15 suma
  `semilla_auto_s`, `aciertos_max_turno`, el modo sin puerta, la jugada automática del motor,
  `aplicar_perfil_turno` y el parcial. Dev implementa desde las firmas exactas. **Corrección**: agregar al
  §11.4 la señal o callback de la jugada automática (por ejemplo, `signal jugada_automatica_pedida()`),
  quién corta el turno al llegar al tope (el gestor, después de que el motor confirme el estado estable)
  y el parámetro del modo sin puerta. También hay que ajustar el texto del "Contrato con el motor".
- **N6. No se dice con quién se retoma una ronda guardada.** El §14.6 restaura el parcial, pero no dice
  qué turno abre. **Corrección**: al retomar, **empieza Maxi** (coherente con el §4.2, "la partida siempre
  empieza con Maxi"): arranca con un acierto y una celebración, y nadie discute "me tocaba a mí". Además,
  el §13 m3 (l. 906) dice "en equipo no hay guardado parcial". Hay que precisar **"fuera de la batalla"**,
  para que Dev no active el parcial en el modo equipo suelto.
- **N7. Dos voces por intro de ronda contra "una frase de 4 s o menos".** El §14.11 pide "una
  presentación por ronda" del Coleccionauta **y** "la intro corta de cada ronda" de Coco, y el §14.10 fija
  intros de una frase (≤ 4 s). Son dos frases. **Corrección**: la presentación del Coleccionauta es un gag
  sin palabras (o de una sola palabra, ≤ 1,5 s) dentro de los 4 s, o la frase de Coco la absorbe. Dentro
  de la ronda, tocar a Cometa repite la regla.

### Puede HE-66 pasar a Hecho

**Sí, desde UX, porque no queda ningún bloqueante.** Las correcciones de la auditoría anterior están
todas en la ficha. Para que HE-66 no se cierre con deuda escondida, propongo estas condiciones:

1. **N1, N2 y N3 son condición de entrada de HE-69 para las rondas 1 y 2.** `disenador-mecanicas` los
   corrige en el §14 (N2 y N3, son cifras y una regla). `disenador-niveles` cierra N1 al calibrar. Se
   pueden incorporar sin otra auditoría completa: alcanza con que UX verifique esos tres puntos.
2. N4 va al `guionista` (HE-67) antes de grabar. N5 y N6 van a `disenador-mecanicas`. N7 va a HE-67 y
   HE-68.
3. Sigue igual el foco de la auditoría del build (Parte 2, "Para cerrar HE-66", punto 5). Suma esto: en
   qué turno se aburre Sofía en Formas (N1) y si el reventón de Maxi al final del Río ocurre siempre (N2).

---

## Verificación N2/N3/N6 (07-Oct-2026)

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 07-Oct-2026
- **Objeto**:
  - `docs/fichas/modo-equipo.md` v6 (decisiones del PO del 07-Oct: tope de pares 1/2/3, retroceso por
    "turno perfecto" y tableros 4×6 con Maxi). `disenador-mecanicas` puede estar cerrando el §9 y el §10
    en paralelo: esta verificación vale para el texto que leí hoy.
  - `docs/guiones/voces-batalla-arcoiris.md` y `docs/cinematicas/batalla_arcoiris.md`.
  - Datos `datos/niveles/arcoiris/batalla/{rio,formas,parejas}_equipo.json`.
- **Nota**: los números de línea de la re-auditoría ya no coinciden con la v6. Abajo cito por sección.

### Estado de cada hallazgo

| Hallazgo | Estado | Evidencia |
|---|---|---|
| **N2** Reventón de Maxi en el Río | **Resuelto** | §14.3, regla "Reventón de Maxi en el Río", en 5 puntos: (1) objetivo = tramo visible más largo, desempate por el más cercano a la cabeza, recordado por `id` de gota y halo que no salta; (2) Coco carga el color exacto del tramo; (3) inserción dirigida al tramo objetivo; (4) umbral 2 **solo para su bala y solo en la batalla**, con retrocesos y cadenas en umbral 3; (5) cambio de `LogicaRio` por parámetro (`umbral`), sin que la lógica sepa de perfiles, y jugada automática por el mismo camino. Está en el trabajo de motor del §14.15 y en QA, con 6 casos y la contraprueba "Nicole, Sofía y el Río en solitario no cambian". Es mejor que lo que pedí: resuelve el halo que salta y la bala que cruza otra gota |
| **N3** Formas a 24 px | **Resuelto** | §14.9 y §14.15: `zona_figuras: [150, 128, 700, 456]` y `zona_bandeja: [880, 128, 360, 456]` (y 128-584), con la explicación de por qué. **Los datos ya están corregidos** (`batalla/formas_equipo.json`, l. 12-13). QA mide las separaciones de 24 px, también en el Río |
| **N6** Con quién se retoma | **Resuelto** | §14.6: "al retomar, empieza Maxi", con motivos y la alternativa descartada; en el epílogo, "¡Maxi, ven a pintar!". §11.4: `empezar_retomando()` (rival en 0, racha en 0, primer turno siempre de Maxi con su puerta). §13 m3: "en equipo **fuera de la batalla** no hay guardado parcial" y "Dev no activa el parcial en el modo equipo suelto". El guion (§2.1, `nucleo_batalla_retomar` + `le_toca_maxi_0X`) y el storyboard (§10, "siempre empieza Maxi") coinciden. Queda un desfase de momento en el guion (ver N11.d) |

**Los tres quedan cerrados.** Para HE-69, N1 depende ahora solo de la calibración de
`disenador-niveles`: la ficha marca "Formas: 8 piezas" como cifra provisional y propone 12.

### Evaluación UX del tope de pares y del retroceso por "turno perfecto" (decisiones del PO, 07-Oct)

**¿Se entiende que el turno termina en fiesta y no en fallo?** El diseño del pase lo hace bien:

- llegar al tope nunca dispara voz ni animación de fallo;
- Cometa dice "¡turno perfecto!", el hermano hace su gesto, la barra aplaude y el Coleccionauta tropieza
  hacia atrás (paso 0b del §4.3);
- las cartas solo hacen el pulso;
- el tope se alcanza al **formar** un par, así que nunca queda una carta a medio dar vuelta.

Además:

- **Equidad**: Nicole (2) y Sofía (3) tienen cada una su meta y las dos pueden hacer retroceder al rival.
  Corrige un problema real: con tope 2 y racha de 3, Nicole nunca podía frenarlo.
- **"El besito de Coco no rompe el turno perfecto"**: **UX respalda esta lectura** ("sin que un fallo
  termine el turno"). Es la consecuencia directa de B2 de HE-58: si el primer fallo de Nicole no deja
  rastro visible, tampoco puede dejar rastro en la regla. Recomiendo que el PO la confirme así.
- **Sacar a Maxi del retroceso** (y el umbral de semilla siempre en 1): correcto, R5.
- **Que en el Río no haya tope**: correcto. Las 3 gotas ya son su "turno perfecto", y cortar el turno
  dejaría gotas sin tirar en la mano de Coco.
- **4×6 con Maxi**: con el tablero `Rect2(40, 128, 1200, 472)` y 4 filas, las cartas miden ≈ 110 px
  (≥ 96, GDD §6.1). En su turno, Maxi solo toca las cartas con halo. Es aceptable.

Pero hay tres condiciones para que esto **se entienda** de verdad, y hoy no están cumplidas:

#### Mayores nuevos

**N8. Nadie explica el tope por voz, y las frases de la batalla lo contradicen.**

- **Dónde**: guion §6, `arcoiris_batalla_parejas_intro` («¡Por turnos! Si hay pareja, sigues jugando.») y
  `nucleo_equipo_parejas_repetir` («…Si son pareja, sigues jugando. Si no, le toca al siguiente.»). En
  Formas pasa lo mismo: `formas_intro` y su `repetir` no nombran el tope. El cierre "con tope" de
  `intro_equipo_trucos.equipo` sigue `PENDIENTE` (§8, Pendiente 1), y además en la batalla no suena,
  porque la intro N7 lo reemplaza.
- **Problema**: la regla que los niños escuchan ("si hay pareja, sigues") es **falsa** justo en el
  momento clave. Sofía forma su tercera pareja, sabe dónde está otra y el turno se corta. Si nadie le
  explicó que 3 es la meta, el corte se lee como "me quitaron el turno" aunque después suene
  "¡turno perfecto!". Es el riesgo 6 del §9 ("¡pero yo sabía otra!"), y hoy está diseñado para pasar.
  Viola GDD §6.2: toda regla se explica por voz.
- **Corrección** (`guionista` en HE-67, `disenador-mecanicas` en el §14.11):
  1. La `repetir` de Cometa en Formas y en Parejas de la batalla suma la meta: "…y si prendes todas tus
     lucecitas, ¡turno perfecto!".
  2. **Presentación única por familia**: el primer turno perfecto de la batalla lleva una variante de
     Cometa que dice qué pasó. Por ejemplo: "¡Turno perfecto! ¡Prendiste todas tus luces y el
     Coleccionauta se resbaló!". Se guarda en `cinematicas_vistas` o en `especial_conocido`, por familia.
  3. La intro de Parejas de la batalla no puede decir "sigues jugando" a secas. Por ejemplo: "¡Por turnos!
     Si hay pareja, sigues… ¡hasta prender tus luces!". Se mantiene en ≤ 4 s (N7).

**N9. La meta del turno no tiene lugar en la pantalla de la batalla.**

- **Dónde**: §5.2 ("en los turnos con tope, la cresta de Coco muestra tantos nuditos apagados como el
  tope") y §14.15 punto 10. Pero el layout de equipo (§4.1) y el de batalla (§14.15) **no ubican a Coco**:
  el tablero de Parejas ocupa `Rect2(40, 128, 1200, 472)`, todo el ancho, donde en solitario está Coco
  (x 30-210).
- **Problema**: sin un lugar definido, Dev va a dibujar la cresta encima de las cartas o no la va a
  dibujar. Sin ese indicador, el niño **no puede anticipar** el final del turno, y el corte se vive como
  sorpresa. La anticipación es lo que convierte "se acabó" en "¡lo logré!".
- **Corrección** (`disenador-mecanicas`):
  1. Fijar un `Rect2` para la "meta del turno" en la batalla y en Parejas en equipo. Propuesta: 2 o 3
     **lucecitas** de ≥ 32 px, no tocables, centradas sobre el borde superior del marco del tablero (que
     ya se tiñe del color de quien juega). Se encienden en arcoíris con cada acierto, se apagan en cada
     pase y no se guardan.
  2. No van bajo los retratos: así se respeta R2, porque no queda ninguna marca por hermano para comparar.
  3. Con tope − 1, **la última lucecita respira**, para que el niño sepa "una más y es perfecto".
  4. En el turno de Maxi no se muestran (su turno es guiado: sin meta y sin presión).
  5. El mismo indicador sirve en Formas.

**N10. El "efecto neto cero" deja como última imagen al rival avanzando.**

- **Dónde**: §4.3, "Después de un turno perfecto (paso 0b) el salto del paso 2 ocurre igual", y riesgo 7
  del §9.
- **Problema**: el Coleccionauta retrocede en 0b y, 1-2 s después, salta hacia adelante en el paso 2. A
  los 5 años manda **lo último que se vio** (efecto de recencia): "lo hicimos resbalar… y avanzó igual",
  o sea, "no sirvió". Además contradice la frase que van a escuchar en la intro ("hace retroceder al
  Coleccionauta"). La ficha lo deja para el playtest, pero el riesgo es previsible y la alternativa es
  barata.
- **Corrección** (decisión del PO, con cifras de `disenador-niveles`):
  1. **Recomendado**: después de un turno perfecto, en el paso 2 el Coleccionauta **intenta saltar y se
     resbala**, sin avanzar. El retroceso de 0b se mantiene. El neto queda en −1 galleta, la última
     imagen es el rival sentado en el suelo y la frase "lo hace retroceder" es literal. Como hace la
     batalla más fácil, `disenador-niveles` recalibra `pasos_rival` con el simulador (probablemente
     5 → 4 en "los tres") para conservar la meta de ~8 de cada 10 partidas ganadas.
  2. **Si el PO prefiere no tocar la calibración**: la alternativa de la propia ficha (sin retroceso y
     sin avance: "intenta saltar y se resbala") con el lenguaje cambiado a "¡lo frenaste!" en la intro,
     en la `repetir` y en `rival_retrocede`. Lo que no puede quedar es "retrocede" y que se vea avanzar.

#### Menores nuevos

- **N11. El guion de la batalla quedó en la v5 y choca con la v6** (`guionista`, antes de pedir el costo
  del TTS):
  - a. §5.3 (fila `arcoiris_batalla_formas_retrocede_celebra`) y §10 punto 2 todavía dicen que «¡Tres
    piezas seguidas!» **reemplaza** a `turno_perfecto`. La ficha v6 la da de baja: con el turno perfecto
    de Nicole (2 piezas) sería falsa. **No generarla.**
  - b. §6 reutiliza `pares_juntados_1..7` "(8 pares, 4×4)", pero la ronda de Parejas de la batalla es de
    **12 pares en 4×6** (`batalla/parejas_equipo.json`). Hacen falta `pares_juntados_1..11`.
  - c. §6 reutiliza "el retroceso" de Parejas en equipo: hay que marcar que
    `arcoiris_emparejar_equipo_retrocede_celebra` («¡Tres parejas seguidas!») **no suena** en la batalla,
    porque ahí siempre hay tope (§14.15).
  - d. §2.1 dispara `nucleo_batalla_retomar` "al tocar el hito". La ficha v6 (§14.6) lo pone al tocar
    "¡Despegar!" en la pantalla corta de "¡todos a la nave!", que ahora sí se repite. Hay que alinear el
    guion con la ficha y con el storyboard §10.
- **N12. En Parejas 4×6, la última fila queda a 10 px de las ventanitas de porra.** El tablero termina en
  y 600 y la barra de retratos empieza en y 610. N3 pidió 24 px en Formas. En Parejas el riesgo es menor:
  tocar una ventanita solo hace aplaudir y no cambia el tablero, y el retrato de quien juega no es
  tocable. **Corrección**: dejarlo **aceptado de forma explícita** en el §4.1 ("excepción a los 24 px
  hacia la barra: el toque erróneo es inocuo"), para no perder el ≈ 110 px de las cartas de Maxi. La
  otra opción es el tablero en y 128-586, con cartas de ≈ 106 px, que siguen siendo ≥ 96 pero quedan bajo
  la regla de 110 del §5.3.
- **N13. Cartas a la vista en el pase de un turno perfecto.** Cuando el turno termina con fallo, las dos
  cartas quedan 1,5 s a la vista (paso 1). Con un turno perfecto no hay cartas que mostrar, y eso está
  bien. Lo que falta: si Sofía toca una carta durante 0b ("¡yo sabía otra!"), recibe solo el pulso.
  **Corrección**: en 0b, el pulso suma un "¡guárdala para tu próximo turno!" de Coco, una vez por
  partida. Convierte el reclamo en plan y responde directamente al riesgo 6 del §9.

### Veredicto de la verificación

- **N2, N3 y N6: resueltos.** Su condición de entrada a HE-69 queda cumplida. N1 sigue en manos de la
  calibración de `disenador-niveles` (Formas, 12 piezas propuestas).
- **Tope y turno perfecto: aprobados en su principio** (fiesta, sin fallo, equidad Nicole/Sofía, Maxi
  fuera), **con 3 mayores nuevos (N8, N9 y N10) y 3 menores (N11, N12 y N13). Ninguno es bloqueante.**
- **N8, N9 y N10 son condición de entrada de HE-69 para las rondas 2 y 3** (Formas y Parejas), porque
  sin ellos el tope se vive como un corte arbitrario. N8 va a `guionista` y `disenador-mecanicas`, N9 a
  `disenador-mecanicas`, y N10 al PO con `disenador-niveles`. N11 va a HE-67 antes de estimar el TTS.
  N12 y N13 van a `disenador-mecanicas`.
- **Para el playtest** (se suma a lo anterior): mirar la cara de Sofía cuando llega al tope (¿orgullo o
  "¡pero yo sabía otra!"?) y qué dicen los niños cuando el Coleccionauta se resbala (¿"¡lo frenamos!" o
  "¡avanzó igual!"?).
