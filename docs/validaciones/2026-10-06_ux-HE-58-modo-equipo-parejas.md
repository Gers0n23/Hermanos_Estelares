# Validación UX — HE-58: modo equipo y mejoras de Parejas de Coco

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 06-Oct-2026
- **Objeto auditado** (diseño, sin código todavía):
  - `docs/fichas/modo-equipo.md` (completa).
  - `docs/fichas/motor-emparejar.md` §10, "Mejoras 1-5": racha y puntaje, vistazo al repartir, cartas
    especiales, Camino de colores y colección.
  - Estado actual de la selección: `scripts/nucleo/seleccion_personaje.gd` y
    `escenas/nucleo/seleccion_personaje.tscn`, para ubicar el botón "¡Juntos!".
- **Contra qué**: GDD §6 (10 reglas), GDD §1 y §5 ("Mecánicas probadas y reto real", reglas por perfil),
  `docs/perfil-jugadores.md` y el desarrollo típico de 2 a 8 años.

## Veredicto: APROBADA CON CAMBIOS

La base es buena. Elegir un cooperativo de mesa probado (*Mi primer frutal*, *Hoot Owl Hoot!*) es
correcto para 2 a 8 años. Que el rival avance por turnos y no por errores, que no haya números
individuales, que Maxi tenga un turno guiado que siempre aporta y que la derrota sea un gag que conserva
los pares son decisiones acertadas. Las mejoras de §10 dan reto real a Nicole y Sofía sin castigar.

Aun así hay **3 hallazgos bloqueantes**. Los tres caen sobre los puntos que el PO marcó como sensibles:
los manotazos de Maxi, la culpa entre hermanos y los celos. **HE-59 no se puede implementar tal como
está la ficha hasta que `disenador-mecanicas` incorpore B1, B2 y B3 en `modo-equipo.md`.** HE-58 queda
cerrada cuando la ficha corregida tenga esos tres cambios. Los mayores deben quedar resueltos en la
ficha o, si alguno queda para el playtest, el PO tiene que aceptarlo de forma explícita.

Conteo: **3 bloqueantes, 10 mayores y 11 menores**.

---

## Respuesta a los 10 puntos del PO

| # | Punto | Diagnóstico | Hallazgo |
|---|---|---|---|
| 1 | Pausa entre turnos y manotazos de Maxi | La puerta de turno es la idea correcta, pero "lo toca cualquiera, en cualquier parte" no protege del caso más probable: Maxi sigue tocando cuando termina su propio turno | **B1**, M3 |
| 2 | ¿Se entiende de quién es el turno sin leer? | Sí. Retrato de 260 px, voz con el nombre, marco del color y foco en la barra: es redundante, como debe ser. Solo hay que cuidar que el color de Sofía no se confunda con el rosa de Nicole | m1 |
| 3 | Espera de Maxi | Con los tres, Maxi espera 30 a 60 s sin nada que hacer. A los 2 años eso es irse o manotear. Hay que darle algo que hacer mientras mira y acortar la espera | **M3** |
| 4 | Que nadie culpe a otro | El rival avanza por turnos, pero el paso que hace perder ocurre justo después del turno de alguien con nombre. Además, la gotita de Nicole y el "¡uuuh!" de los hermanos señalan fallos individuales | **B2**, **B3** |
| 5 | Celos Nicole/Sofía | Están bien cubiertos en la fiesta. Quedan dos fuentes de comparación: la racha con el color y el número de quien juega, y la segunda oportunidad visible de Nicole | **B2**, **M1**, m7 |
| 6 | ¿La vela pone ansiosa a Nicole? | Es un riesgo real si llega en la zona 1 junto con otras tres novedades y con señales de urgencia. Se corrige con forma y calendario, sin quitarla | **M7** |
| 7 | ¿Un vistazo de 8 cartas satura a Nicole? | En solitario Nicole nunca ve 8 cartas: sus tableros tapados son de 8 a 12. El problema es el contrario, porque 4 de 8 cartas le resuelven medio tablero. En equipo, la fórmula da 12 de 20 cartas (6 pares en 3 s), y eso satura a cualquiera de los tres | **M6** |
| 8 | ¿La carta del Coleccionauta da risa o rabia a Sofía? | Puede dar rabia: "prefiere cartas ya vistas" ataca justo lo que ella memorizó, y Sofía se frustra rápido. Hay que darle una revancha | **M8** |
| 9 | ¿Se entiende "comparte color o figura"? | La regla la entiende una niña de 8 años: la clasificación flexible por dos dimensiones se domina hacia los 6-7. Lo que va a frustrar no es la regla, sino que un fallo borre un camino de 10 cartas | **M9** |
| 10 | ¿Se encuentra y se entiende el botón "¡Juntos!"? | Cabe bien en la franja inferior, pero nada invita a tocarlo. Además, "¡Despegar!" centrado abajo choca con el globo de Cometa | **M5**, m2 |

---

## Hallazgos bloqueantes

### B1. La puerta de turno no frena los toques de Maxi después de su propio turno

**Dónde**: `modo-equipo.md` §4.3, paso 3: "Lo toca cualquiera, y en cualquier parte de la pantalla".

**Problema**: el riesgo principal no es un toque suelto al pasar la tablet. Es Maxi, que a los 2 años
no entiende que su turno terminó y **sigue tocando** con la tablet en las manos. La secuencia probable
es esta: forma su par, viene su fiesta, aparece "¡Le toca a Nicole!" y Maxi toca la cara grande, que
respira en el centro y es justo lo que más le atrae tocar. La puerta se abre y su toque siguiente da
vuelta una carta **en el turno de Nicole**. Eso gasta la segunda oportunidad de Nicole, o el turno
entero si es el de Sofía. Para Sofía, que se frustra rápido, "Maxi me hizo perder el turno" es el
conflicto más fácil de anticipar de todo el modo.

**Corrección** (`disenador-mecanicas` en la ficha, `dev-godot` en HE-59):

1. La puerta se abre **solo tocando el retrato grande** (≥ 260 px, hitbox = dibujo + 20 px), no
   cualquier parte de la pantalla. Un toque fuera del retrato hace que el retrato salte y repita "¡Le
   toca a Nicole!".
2. **Después de un turno de Maxi**, la puerta pide **arrastrar el retrato hasta su ventanita** de la
   barra (≈ 200-250 px de recorrido, imán de 80 px). Arrastrar está permitido (GDD §6.4) y un
   manotazo al azar casi nunca produce un arrastre dirigido de 200 px. Nicole y Sofía lo hacen sin
   esfuerzo. Visual: la ventanita vacía brilla y una flechita de estrellas va del retrato a la
   ventanita. Voz: "¡Nicole, sube a tu ventanita!".
3. El bloqueo de 400 ms después de abrir la puerta (§10.1 de la ficha) pasa a ser **obligatorio**, no
   una opción si el problema "pasa seguido".
4. Durante los pasos 1, 2 y 4 se mantiene lo que ya dice la ficha: la carta tocada solo hace el pulso,
   con respuesta en menos de 100 ms.
5. Parámetro de datos `puerta_tras_semilla: "arrastre" | "toque"`, con `"arrastre"` por defecto, para
   poder ajustarlo en el playtest.

### B2. Hay señales de fallo con nombre: la gotita de Nicole y el "¡uuuh!" de los hermanos

**Dónde**: `modo-equipo.md` §5.2, fila "No es este" de Nicole ("una gotita verde se apaga junto a su
retrato"), y §4.1 ("hacen '¡uuuh!' con cada 'no es este'").

**Problema**:

- La gotita que se apaga **junto al retrato de Nicole** es un marcador individual de errores visible
  para todo el equipo. Contradice el §6 del motor ("cero marcador de errores visible") y el espíritu de
  R2 y R6. Además, funciona como una "vida", algo que el GDD §8 deja fuera del juego.
- Para un niño de 5 años, un coro de "¡uuuh!" de sus hermanos en pantalla ante **su** error se lee como
  burla, no como "uy, casi". Y le da a Sofía un modelo de reacción que después va a repetir en voz alta.

**Corrección**:

1. Quitar la gotita junto al retrato. La segunda oportunidad de Nicole se comunica **solo con la voz de
   Coco** ("¡uy, otra!") y con un gesto de Coco: le guiña un ojo y le sopla un besito. No queda nada
   persistente que se pueda contar.
2. Cambiar el "¡uuuh!" por **reacciones de ánimo**: cruzar los dedos, un "¡casi!" o "¡tú puedes!", o
   un aplauso suave. El sonido tiene que ser igual de amistoso que el "no es este" del motor (riesgo 6
   del §8 del motor). Los hermanos de la barra nunca reaccionan con decepción.

### B3. El paso que hace perder ocurre justo después del turno de alguien

**Dónde**: `modo-equipo.md` §5.3 ("Al terminar cada turno de Nicole o de Sofía, el Coleccionauta salta
una galleta") y §5.5.

**Problema**: R6 busca que nadie "nos haga perder", pero tal como está, la cadena visible es esta:
Nicole falla, se tapan sus cartas, salta el Coleccionauta, llega y viene la derrota. Los niños de 5 a 8
años leen causa y efecto por lo que ocurre seguido. Si el último paso cae inmediatamente después del
fallo de Nicole, **el equipo perdió "por Nicole"**, diga lo que diga la regla. Con Maxi + Nicole pasa
todavía más claro, porque Maxi nunca mueve al rival y entonces todos los pasos ocurren después de los
turnos de Nicole.

**Corrección**:

1. El rival **no se mueve al terminar el turno**. Se mueve **durante el pase**, junto con el "fiuu"
   del retrato que vuela (paso 2 del §4.3), como un reloj que avanza porque la nave gira: "pasa el
   tiempo", no "alguien falló". Así el movimiento pertenece a la transición y no a nadie.
2. Si ese paso hace llegar al rival, la derrota-gag empieza **después de que el retrato del siguiente
   ya está en el centro**, de modo que el momento de perder "le pasa a todos", no a quien acaba de
   jugar.
3. Las líneas de derrota del rival y de Cometa **nunca nombran a un hermano** y siempre hablan en
   plural ("¡nos alcanzó! ¡otra vez, equipo!"). Cometa cierra con un logro común: "¡igual juntamos 7
   parejas!". Esto se le pide al `guionista`.
4. En la v1 se mantiene "avanza por turno" y se descarta la idea de "avanza por ronda completa": con
   los tres, esa opción haría que la derrota siempre cayera después del turno de Sofía.

---

## Hallazgos mayores

### M1. En equipo, la racha y los puntos comparan a Nicole con Sofía

**Dónde**: `modo-equipo.md` §5.6 ("la racha es del turno y se ve con el color de quien juega") y
`motor-emparejar.md` §10.1, cuyo contador "×3" y los "+200" no aclaran si existen en equipo.

**Problema**: si turno por medio la pantalla muestra "×4" en turquesa y "×1" en rosa, eso es un ranking
encubierto, y Sofía es justamente la que siente celos (`perfil-jugadores.md`).

**Corrección**:

- En el modo equipo la racha va **solo como sonido y cresta**, igual que el modo `"solo_sonido"` de
  Semilla: sin número, sin "+puntos" y con nuditos **arcoíris**, no del color de quien juega. Decirlo
  explícito en la ficha: **en equipo no existe el bloque `puntaje`**.
- Para que un buen turno siga siendo una hazaña que premia la memoria (y le dé a Sofía su momento de
  líder): **con 3 pares seguidos en un turno, el Coleccionauta tropieza y retrocede una galleta**. Lo
  celebra todo el equipo, como logro común. Parámetro `racha_retrocede_rival: 3`. `disenador-niveles`
  recalibra `pasos_rival`.

### M2. Equidad visible de las reglas por edad (Nicole y Sofía)

**Problema**: Sofía, que es la celosa, ve que Nicole tiene dos oportunidades y ella una. A los 8 años
entiende la regla por edad en abstracto, pero no cuando le toca perder el turno.

**Corrección**:

- Ninguna regla por edad se muestra con un indicador; esto queda resuelto con B2.
- Al presentar el modo, la voz de Coco dice que **cada uno juega con su propio truco**: "Maxi tiene
  cartas que brillan, Nicole tiene un besito de Coco y Sofía puede hacer retroceder al Coleccionauta",
  esto último por M1. Así la regla de Sofía se siente como un superpoder, no como una desventaja.

### M3. La espera de Maxi y sus manos sin nada que hacer

**Dónde**: `modo-equipo.md` §4.1, §4.2 y riesgo 4 del §10.

**Problema**: entre dos turnos suyos Maxi espera 30 a 60 s. A los 2 años, con la tablet cerca, eso
termina en manotazos (B1) o en que se va. Su turno además dura unos 5 s, así que su relación con el
juego queda en 5 s de juego por cada 45 s de espera. Y cuando termina su turno no entiende que le
quiten la tablet.

**Corrección**:

1. **Ventanita de porra**: en la barra, los retratos de quienes miran son **tocables (≥ 96 px)**. Al
   tocarlos, ese hermano aplaude o hace su gesto corto, con sonido suave. No afectan el tablero, tienen
   un enfriamiento de 1 s y se silencian durante la voz de "le toca". Esto canaliza la necesidad de
   tocar de Maxi hacia un objetivo seguro y es la forma en pantalla de "los demás apoyan" (GDD §3).
   Le cuesta poco a `barra_equipo.gd`.
2. **Maxi intercalado**: nuevo parámetro `orden: "maxi_intercalado"`. Con los tres, el orden es Maxi →
   Nicole → Maxi → Sofía. La espera de Maxi baja a unos 15-25 s. Su turno es corto y no mueve al
   rival, así que la partida apenas se alarga. `disenador-niveles` recalibra `pasos_rival` y el tamaño
   del tablero, porque Maxi forma más pares.
3. **Fin del turno de Maxi con ritual**: su par vuela a la cinta, su retrato "se sube" a su ventanita
   (que destella) y Coco dice "¡ahora a echarle porras!". Así Maxi sabe adónde va su atención.

### M4. Falta el "tocar a Coco repite la instrucción" en las pantallas de equipo

**Dónde**: `modo-equipo.md` §3.2 (armar equipo) y §4 y §5 (partida). El layout nuevo (pista arriba,
barra abajo) no dice dónde queda Coco ni Cometa como objetivo tocable.

**Problema**: el GDD §6.2 es obligatorio en toda pantalla.

**Corrección**:

- En armar equipo, Cometa es tocable (≥ 96 px) y repite "¿Quiénes juegan juntos hoy?…".
- En la partida, Coco tiene una ubicación fija (por ejemplo, el extremo izquierdo de la pista del
  rival) con hitbox ≥ 96 px. Al tocarlo repite la regla de mesa **y de quién es el turno** ("¡le toca a
  Nicole! Si encuentras pareja, sigues jugando").

### M5. "¡Juntos!" se encuentra poco, y "¡Despegar!" choca con el globo de Cometa

**Dónde**: `modo-equipo.md` §3.1 y §3.2 frente a `seleccion_personaje.tscn`.

**Estado actual medido**: tarjetas en y 134-560 (sombra hasta 572); Cometa en (106, 628); globo
`burbuja_ayuda` en x 186-596, y 598-670; álbum en `Rect2(930, 596, 140, 120)`; volver en x 1148-1244,
y 590-686. El hueco libre entre el globo y el álbum es x 596-930 (334 px).

**Problemas**:

1. El botón cabe, pero **nada invita a tocarlo**. La voz de invitación (cada 12 s) y el globo dicen
   "¡Toca tu foto para empezar!", y Nicole no va a deducir el significado de tres caritas en una nave
   sin probar.
2. "¡Despegar!" (160 × 120) "centrado abajo" ocupa x 560-720 y se **superpone al globo** (que termina
   en x 596).

**Corrección**:

1. Ubicación concreta de "¡Juntos!": `Rect2(640, 598, 240, 110)`. Quedan 44 px de aire con el globo,
   50 px con el álbum y 38 px con el borde de la región táctil de la tarjeta de Nicole (y 560). Cumple
   los ≥ 24 px y supera los 200 × 110 de la ficha.
2. **Presentación única** la primera vez que el modo existe: la nave entra volando, se estaciona en su
   lugar y Cometa dice "¡Ahora pueden jugar juntos! Toquen la nave". Se guarda en `Progreso` que ya se
   presentó.
3. Después, la invitación de 12 s **alterna**: una vez "¡Toca tu foto!" y la siguiente "…¡o toquen la
   nave para jugar juntos!". La nave hace un vaivén suave en reposo (no parpadea).
4. En el modo armar equipo, **"¡Despegar!" ocupa el mismo rectángulo que "¡Juntos!"**: "toqué la nave
   y ahora toco la nave con fuego". Se ocultan el álbum y el globo de texto para que no compitan.
   Cometa queda tocable por M4.

### M6. El vistazo: satura en equipo y regala medio tablero en los tableros chicos de Nicole

**Dónde**: `motor-emparejar.md` §10.2 (fórmula `max(4, cartas − 8)`, pares completos, 3 s) y
`modo-equipo.md` §5.4.

**Problema**:

- **En solitario**, los tableros tapados de Nicole son de 8 a 12 cartas (`planeta-arcoiris-zonas.md`
  §3.3). Con 8 cartas, la fórmula muestra 4, o sea **la mitad del tablero**: 2 de sus 4 pares quedan
  resueltos de entrada. Eso vuelve a la "dificultad de bebé" que el playtest del 03-Oct rechazó.
- **En equipo**, con 20 cartas, la fórmula da **12 cartas, 6 pares en 3 s**. La memoria visoespacial
  típica es de unos 2-3 elementos a los 5 años y de unos 5 a los 8. Seis pares superan a los tres, y
  el vistazo pasa a ser ruido.

**Corrección** (las cantidades de la tabla son del PO, así que esto se le devuelve como recomendación):

- Brote solitario: **1 par (2 cartas) con 10 cartas o menos, 2 pares (4 cartas) con 12 a 16**, durante
  3 s. Se mantiene "pares completos", que es lo que le da a Nicole un acierto rápido y seguro.
- Equipo: **máximo 3 pares (6 cartas), 3 s**, sea cual sea el tablero.
- Regla general para la ficha: **≈ 1 s por par mostrado, mínimo 2 s**.

### M7. La vela del tiempo par para Nicole, y demasiadas novedades en su zona 1

**Dónde**: `motor-emparejar.md` §10.1 y el calendario del §10.3. Para Nicole, la zona 1 trae a la vez
racha, vistazo, récord y vela.

**Problema**: una vela que se consume es una cuenta regresiva. A los 5 años muchos niños se apuran ante
un reloj, fallan más y se frustran, y eso es lo contrario del reto. Además, cuatro sistemas nuevos de
golpe chocan con "un objetivo a la vez" de Brote (GDD §5) y con la regla propia de la ficha de
"presentar de a una".

**Corrección**:

1. **La vela aparece solo cuando ya hay récord en esa estación**. La primera partida es para aprender;
   desde la segunda hay algo que perseguir. Para Sofía puede estar desde la primera.
2. La vela no tiene sonido de tic-tac, no parpadea, no cambia de color ni acelera en los últimos
   segundos. Va fuera del área de juego y a menos de 80 px de alto.
3. Cuando se apaga: "puf" suave y Coco dice algo positivo ("¡la vela se fue a dormir, sigue
   tranquila!"). No basta con encoger los hombros, que puede leerse como decepción.
4. Calendario de Nicole: zona 1 con racha y récord (un solo sistema, "los puntos"), más el vistazo
   (pasivo, no hay regla que aprender); la vela entra desde la zona 2 y siempre con la regla del
   punto 1.
5. Criterio para el playtest (para `tester-qa` y el PO): si Nicole mira la vela más que el tablero, o
   comete más fallos cuando la vela está por terminarse, se pone `tiempo_par_s: null` en Brote.

### M8. La carta del Coleccionauta puede darle rabia a Sofía

**Dónde**: `motor-emparejar.md` §10.3 ("prefiere cartas ya vistas").

**Problema**: el intercambio ataca justo la memoria que Sofía invirtió, y no puede evitarlo. Con su
frustración rápida, la carta Bowser funciona solo si hay revancha. Sin ella, se siente como un castigo
al azar.

**Corrección**:

1. **Revancha**: las dos cartas movidas dejan una estela de brillitos durante 1,5 s. Si Sofía forma un
   par con alguna de ellas, suena "¡te pillé, Coleccionauta!", hay +300 puntos y el Coleccionauta se
   cae de la silla. Así la rabia se convierte en "le gané al villano".
2. Nunca aparece cuando quedan 3 pares o menos, ni en la partida que sigue a una derrota.
3. Como máximo, una por tablero.
4. Se mantiene la alternativa de la ficha ("las mira y las devuelve") si en el playtest igual hay
   llanto.

### M9. Camino de colores: un fallo borra todo el camino, y la regla necesita un ancla visual

**Dónde**: `motor-emparejar.md` §10.4.

**Problema**:

- La regla "color o figura" está al alcance de una niña de 8 años. Lo que la va a frustrar es que **un
  solo fallo con un camino de 10 cartas lo tape completo**. Es la pérdida más grande de todo Parejas, y
  va dirigida a la hermana que llora cuando algo no le sale.
- Para recordar los dos atributos de la última carta mientras busca entre 24 tapadas hay que tener dos
  cosas en la cabeza a la vez, además de las posiciones.

**Corrección**:

1. **Tramos horneados**: cada 4 cartas, el glaseado "se hornea" con un brillo y un "ding" de horno, y
   ese tramo ya no se desarma. Un fallo tapa solo el tramo en curso. La meta de 12 queda en 3 tramos.
   Sigue habiendo reto (el tramo se pierde) sin borrar el trabajo.
2. **Ficha "busca"** junto a Coco, sin texto: la mancha del color y la silueta de la figura de la última
   carta, con un "o" visual (dos burbujas separadas). La última carta del camino queda **agrandada al
   110 % y con borde**. Esto no regala posiciones: solo libera memoria para lo que sí es el reto.
3. **Demostración** de Coco con 3 cartas antes de la primera partida: una que comparte color, otra que
   comparte figura y una que no comparte nada ("¡esta no, no tiene nada igual!"). Mostrar también el
   caso negativo es lo que fija la regla.
4. Antes de taparse, las cartas del tramo que se desarma quedan **1 s a la vista**, para que Sofía
   pueda recordarlas como dice la ficha.

### M10. El turno guiado de Maxi no define qué pasa con las cartas especiales ni con el comodín

**Dónde**: `modo-equipo.md` §5.2 ("Comodín: solo si Nicole juega, en cualquier turno") y la fila "Si
toca una carta sin halo".

**Problema**: si Maxi toca el comodín o la lupa fuera del halo, la ficha no dice qué ocurre. Una
respuesta indefinida, o un "no es este" que para Maxi "no existe", es justo la trampa que Semilla tiene
que evitar.

**Corrección**:

- En el turno de Maxi, **el comodín y la lupa no se pueden tocar**: si los toca, solo hacen el pulso
  con un sonido amable y las cartas con halo saltan para llamarlo.
- Alternativa: si Maxi da vuelta el comodín, este completa **su par del halo** y se celebra como un
  par normal suyo.
- Elegir una de las dos y escribirla en la ficha.

---

## Hallazgos menores

- **m1. Colores de turno**: usar los colores de las tarjetas de selección (Maxi azul `#3E77CC`, Nicole
  rosa `#E8589C`, Sofía turquesa `#2FB3AD`). El aura de Sofía **nunca** puede ser rosa, aunque su traje
  lo sea, para que el color de turno no se confunda con el de Nicole.
- **m2. Armar equipo**: al tocar una tarjeta, la voz confirma el estado nuevo ("¡Nicole va a mirar
  desde el puf!" o "¡Nicole se sube a la nave!"). Así "tocar para sacar" no se confunde con "elegir a
  uno solo", que es el riesgo 7 de la ficha.
- **m3. Arranque accidental de Maxi**: si Maxi toca "¡Juntos!" y luego "¡Despegar!" sin que nadie más
  esté, la partida tiene que poder abandonarse con el ícono de casa de siempre. Confirmar que la
  pantalla de juego en equipo conserva la casa (≥ 96 px) y que salir no pierde nada (GDD §6.8).
- **m4. "¡Otra vez!" en equipo**: ≥ 160 × 160 px, porque Maxi puede estar mirando y querer tocarlo.
- **m5. Recordatorio de la puerta**: la repetición a los 10 s ("¡Nicole, te toca!") se hace como
  máximo 2 veces; después el retrato solo respira. Una voz que insiste en bucle cansa a todos.
- **m6. Primer récord**: si la estación no tiene récord, la barra no muestra banderita, y al final suena
  "¡tu primer récord!". Lo mismo vale para la banderita del equipo en la pista del rival.
- **m7. Fiesta final**: "mismo tamaño" significa **el mismo protagonismo en pantalla** (foco, duración
  y volumen de la voz normalizados), no la misma escala de sprite. Que Sofía se vea más alta es natural
  y no debe achicarse.
- **m8. Gomita del tablero impar**: el GDD §6.5 pide que todo lo tocado reaccione. Al tocarla, la gomita
  se menea y hace "boing" (no "no se puede tocar"). Debe ser redonda, del 60 % del tamaño de una carta
  y sin dorso, para que no se confunda con una carta.
- **m9. Colección sin números**: en la caja de Coco no se muestran contadores como "23/60". Las
  siluetas bastan. Cada hermano ve solo su colección desde su mapa, para que no haya comparación
  Nicole/Sofía.
- **m10. "+puntos" y contador de racha**: lo que ya pide el riesgo 1 del §10.6 queda como requisito: el
  texto flotante nunca se dibuja sobre cartas tapadas. Y por M1, en equipo no aparece.
- **m11. Pregunta PO 1 (zonas abiertas en equipo)**: desde UX, "las del hermano más avanzado" es lo
  correcto. Los niveles de equipo son archivos propios, así que no le arruinan a nadie su ruta
  solitaria.

---

## Qué sí está bien (no tocar)

- El rival chistoso que avanza por turnos, la derrota que conserva los pares y el rival que vuelve con
  todos sus pasos: el equipo siempre termina ganando.
- El turno guiado de Maxi que siempre aporta un par **nuevo** para el equipo, y el Coleccionauta
  "embobado" durante su turno.
- La pantalla de armar equipo que parte con los tres adentro, y el puf de "yo miro" sin gris ni tachado.
- Destellos iguales para todos, récord por composición de equipo y meta compartida visible (las 5
  estrellitas).
- Cartas de 110 px con Maxi en el equipo y tope de 5×4.
- El comodín que nunca produce "no es este", la presentación de cada especial de a una y las siluetas
  sin candado en la colección.

## Para cerrar HE-58

1. `disenador-mecanicas` incorpora B1, B2 y B3 en `docs/fichas/modo-equipo.md`. Sin eso, HE-59 no
   arranca.
2. M1 a M10 quedan resueltos en las fichas o con aceptación explícita del PO de dejarlos para el
   playtest (M6 necesita su decisión porque cambia cantidades marcadas [PO]).
3. Los menores pueden ir directo a la implementación de HE-59 a HE-63.
4. La auditoría sobre el build real va en HE-64, con foco en B1 (manotazos), M3 (espera) y M7 (vela).
