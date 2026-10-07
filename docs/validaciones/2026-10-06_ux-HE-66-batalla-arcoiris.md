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
