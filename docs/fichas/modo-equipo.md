# Ficha de modo — Juego en equipo (y su primera aplicación: Parejas de Coco)

> **Decisión del PO (06-Oct-2026)**: se agrega un **modo "juego en equipo"** como opción nueva en la
> pantalla de selección de hermanos. Concreta y adelanta lo que el GDD llamaba "Modo misión familiar"
> (§3 y P6 del §9), que antes estaba previsto solo para HE-39. El primer minijuego con modo equipo es
> **Parejas de Coco** (motor `emparejar`); los demás se suman después.

- **Autor**: `disenador-mecanicas`
- **Estado**: **v2, 06-Oct-2026**. Incorpora las decisiones del PO del 06-Oct-2026 y la validación UX de
  HE-58 (`docs/validaciones/2026-10-06_ux-HE-58-modo-equipo-parejas.md`):
  - bloqueantes **B1, B2 y B3**;
  - mayores **M1 a M10**;
  - menores **m1 a m11**, que van en el §13, "Para Dev".
  
  La ficha queda lista para implementar el modo equipo (HE-59, según la validación UX). Los números
  marcados como estimados se calibran con el simulador y el playtest.
- **Referencias**:
  - GDD §1 (tono y derrota-gag), §3 (modo misión familiar), §5 ("Mecánicas probadas y reto real"), §6
    (UX obligatoria) y §8 (alcance negativo);
  - `docs/fichas/motor-emparejar.md` (§10: mejoras del motor);
  - `docs/fichas/planeta-arcoiris-zonas.md` §3.3;
  - `docs/roadmap-rio-de-pintura.md` (lenguaje visual de combos y récords);
  - `docs/perfil-jugadores.md` (gestos y equidad entre Nicole y Sofía).

**Marcas**:

- **[PO]**: decisión del PO.
- **[UX]**: corrección exigida por la validación UX de HE-58.
- **[Propuesta]**: de `disenador-mecanicas`.
- **[Propuesta UX, por confirmar con el PO]**: recomendación de UX que cambia algo marcado [PO].

---

## 1. La idea en una frase

Los hermanos que juegan se turnan con la misma tablet sobre **un mismo tablero**, cada uno con las reglas
de su edad, para ganarle juntos a un rival común que avanza con el paso de los turnos. Nadie le gana a
nadie: gana o pierde el equipo.

---

## 2. Reglas que no se rompen

| # | Regla | Marca |
|---|---|---|
| R1 | **Cooperativo puro**: los hermanos juegan contra un rival común, nunca entre ellos. **En Parejas, el rival es el Coleccionauta** | [PO] |
| R2 | **Sin rankings entre hermanos**: ni en pantalla ni en el guardado existe cuántos pares hizo cada uno. Tampoco hay "jugador del partido", número individual, racha con número ni marcador de fallos con nombre | [PO] + [UX B2, M1] |
| R3 | Por turnos en la misma tablet, 2 o 3 hermanos que eligen quiénes juegan | [PO] |
| R4 | Cada uno juega su turno con **su propia dificultad** (Semilla, Brote o Estrella) | [PO] |
| R5 | **Maxi juega su turno con ayuda**: su turno **siempre aporta** un par real al equipo | [PO] |
| R6 | El rival avanza con **el paso del tiempo (los turnos)**, nunca por el error de alguien con nombre. Además, **su movimiento ocurre durante el pase de turno**, cuando el siguiente hermano ya está en el centro (B3) | [Propuesta] + [UX B3] |
| R7 | Las celebraciones del equipo dan **el mismo protagonismo** a cada hermano: foco, duración y volumen de voz iguales. No se iguala el tamaño del sprite (m7) | [Propuesta] + [UX m7] |
| R8 | Los hermanos de la barra **nunca reaccionan con decepción**: solo dan ánimo y celebran (B2) | [UX B2] |
| R9 | Arquitectura: el modo equipo es una **capa genérica** (gestor de turnos en `scripts/base/`, UI en `scripts/ui/`, campo `equipo` en `minijuego_base`). El núcleo no conoce Parejas, y cada motor declara en sus datos si admite equipo (regla de oro 4). Detalle en §11 | [Propuesta] |

---

## 3. Elegir el equipo en la pantalla de selección

### 3.1 El botón "¡Juntos!" [PO: opción nueva en la selección; UX M5: lugar y presentación]

- En modo normal la selección no cambia: tocar una tarjeta lleva directo al mapa con ese hermano.
- **Ubicación exacta**: `RECT_JUNTOS := Rect2(640, 598, 240, 110)`, en `seleccion_personaje.gd`.
  Medida actual de la escena:
  - globo `burbuja_ayuda`: x 186-596, y 598-670;
  - álbum: `Rect2(930, 596, 140, 120)`;
  - tarjetas: y 134-560.
  
  Quedan 44 px de aire con el globo, 50 px con el álbum y 38 px con la tarjeta de Nicole.
- **Ícono, sin texto**: las tres caritas de los hermanos asomadas por las ventanitas de la **nave de
  juguete** del living. En reposo hace un **vaivén suave** (±3°, 2,4 s) y **nunca parpadea**.
- Debajo del ícono, dentro del mismo rectángulo, van **5 estrellitas de equipo** (una por zona de
  Arcoíris ganada en equipo, §7.3). Parten apagadas, nunca con candado. **[PO: se mantienen.]**
- **Presentación única** (M5.2): la primera vez que la selección se abre con el modo disponible, la nave
  entra volando desde la derecha, se estaciona en su lugar (1,5 s) y Cometa dice "¡Ahora pueden jugar
  juntos! Toquen la nave". Se guarda con `Progreso.marcar_modo_equipo_presentado()` (§11.4).
  - Si en esa misma apertura toca entregar la foto de primera apertura del álbum, la presentación de la
    nave espera a que la entrega termine. Las dos no se superponen.
- **Invitación alternada** (M5.3): el recordatorio de 12 s alterna entre dos voces: una vez
  `seleccion_invitacion_01` ("¡Toca tu foto para empezar!") y la siguiente `seleccion_invitacion_equipo`
  ("…¡o toquen la nave para jugar juntos!"), mientras la nave da un saltito.
- **Al tocar "¡Juntos!"**: la nave salta, suena "¡vamos juntos!" (Cometa) y la pantalla pasa al modo de
  armar equipo.

### 3.2 Armar el equipo [Propuesta + UX M4, M5.4, m2]

1. **Se ocultan el álbum y el globo de texto** (M5.4), para que no compitan. Cometa sigue a la vista y
   **se puede tocar** (≥ 96 px, en su lugar de siempre): repite la consigna (M4).
2. Las tres tarjetas **parten adentro del equipo**: cada una muestra un asiento de nave encendido bajo
   el retrato, y el hermano saluda.
3. **Tocar una tarjeta la saca o la mete** (alterna):
   - **Al salir**, el hermano se sienta en un puf del living con cara de "yo miro" y la tarjeta queda al
     60 % de brillo. **Nunca gris ni tachada.** La voz confirma: "¡Nicole va a mirar desde el puf!"
     (m2).
   - **Al volver**, salta al asiento: "¡Nicole se sube a la nave!" (m2).
4. **Mínimo 2 hermanos**. Si se intenta sacar a uno cuando quedan dos, la tarjeta se mece con cariño y
   Cometa dice "¡para jugar en equipo se necesitan al menos dos!". No pasa nada más.
5. **"¡Despegar!"** (la nave con fuego de cohete) ocupa **el mismo rectángulo que "¡Juntos!"**,
   `Rect2(640, 598, 240, 110)` (M5.4): "toqué la nave y ahora toco la nave con fuego".
6. La flecha de volver sale del modo equipo y regresa a la selección normal: reaparecen el álbum y el
   globo, y el equipo queda vacío.
7. Voz de Cometa al entrar, la línea reescrita por el `guionista`, que nombra el puf
   (`nucleo_equipo_armar`): "¿Quiénes juegan juntos hoy? Si alguien quiere mirar, tócalo... ¡y se
   sienta en el puf! Después, ¡a despegar!". Tocar a Cometa la repite.

Solo toques simples. El equipo vive en `Progreso.equipo_activo` (§11.4), en memoria, nunca en disco.

### 3.3 Adónde lleva "¡Despegar!" [PO: zonas]

- **v1**: va directo al **mapa del Planeta Arcoíris en modo equipo**. En `seleccion_personaje.gd` se
  usa la constante `RUTA_MAPA_EQUIPO := "res://escenas/planetas/arcoiris/mapa_arcoiris.tscn"`, igual que
  hoy existe `RUTA_MAPA`. Cuando un segundo planeta tenga estaciones de equipo, "¡Despegar!" pasará por
  el mapa estelar.
- En modo equipo, `mapa_planeta.gd` funciona así:
  - **Todas las zonas de Arcoíris están abiertas [PO]**, incluida la secreta. Cada turno usa la
    dificultad de quien juega.
  - Las zonas no se pintan según el avance de nadie: se ven todas a color (es el "mapa del equipo").
  - **Solo despiertan las estaciones que traen `nivel_equipo`** en `mapa.json` (§11.2). Las demás se ven
    "pintándose", igual que las estaciones sin minijuego, y Coco dice "¡este juego todavía lo estoy
    preparando para jugar en equipo!" (voz `estacion_sin_equipo`).
  - Arriba, en vez del retrato de un hermano, se ven los retratos del equipo en su nave.
  - La flecha de volver lleva a la selección y vacía el equipo.
- **Una partida en equipo no marca completada la estación individual de nadie [PO]**, y no cambia la
  apertura de zonas de ninguna ruta.

---

## 4. "Le toca a…": cómo se ven los turnos

### 4.1 Pantalla de juego (layout fijo, 1280×720) [Propuesta + UX M4, M3, m1, m3]

| Zona | Rect | Contenido |
|---|---|---|
| Pista del rival | `Rect2(0, 0, 1280, 100)` | **Coco a la izquierda**, tocable con hitbox `Rect2(8, 4, 110, 110)` (M4). Después, la pista de galletas, el Coleccionauta en su nave-aspiradora y, a la derecha, la mesa del equipo con la **cinta arcoíris** de la meta compartida |
| Botón casa | `Rect2(1172, 8, 100, 96)` (≥ 96 px) | Salir al mapa en modo equipo. Salir no pierde nada (m3) |
| Tablero | `Rect2(40, 110, 1200, 490)` | Las cartas |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` | La nave de juguete de perfil con los retratos en sus ventanitas, en el orden de los turnos |

- **Colores de turno (m1)**: Maxi azul `#3E77CC`, Nicole rosa `#E8589C` y Sofía turquesa `#2FB3AD` (los
  de las tarjetas de selección). **El aura de Sofía nunca es rosa.**
- **Quien juega**: retrato al 130 %, aura de su color, un foco suave encima y respiración lenta. El marco
  del tablero (6 px) se tiñe de su color.
- **Quienes miran**: retrato al 100 %, despiertos, y **se pueden tocar: "ventanita de porra" (M3.1)**:
  - Hitbox ≥ 96 × 96 px.
  - Al tocarlo, ese hermano aplaude o hace su **gesto corto** (0,6 s) con un sonido suave.
  - **No afecta el tablero.**
  - Enfriamiento de 1 s por retrato.
  - Se silencia mientras suena la voz "le toca a…".
  - El retrato de **quien juega** no es tocable (evita que confunda su turno).
- **Reacciones automáticas de quienes miran (B2)**:
  - Con cada par aplauden.
  - Con cada "no es este", **solo ánimo**: cruzan los dedos, dicen "¡casi!" o "¡tú puedes!", o aplauden
    suave. El sonido es tan amistoso como el "no es este" del motor.
  - **Nunca** "¡uuuh!", suspiros ni caras de decepción.
- **No hay números, gotitas ni marcadores bajo los retratos** (R2).

### 4.2 El orden de los turnos [PO: del menor al mayor, ajustado por M3]

- Parámetro `orden`, con **`"maxi_intercalado"` por defecto**:

| Equipo | Ciclo de turnos |
|---|---|
| Maxi + Nicole + Sofía | Maxi → Nicole → Maxi → Sofía → (repite) |
| Maxi + Nicole | Maxi → Nicole → (repite) |
| Maxi + Sofía | Maxi → Sofía → (repite) |
| Nicole + Sofía | Nicole → Sofía → (repite) |

- `"menor_a_mayor"` queda como alternativa de datos (sin intercalar).
- Con los tres, la espera de Maxi baja de 30-60 s a unos 15-25 s. Su turno es corto (≈ 5 s) y no mueve
  al rival, así que la partida apenas se alarga.
- La partida **siempre empieza con Maxi**, si juega: así arranca con un par y una celebración.

### 4.3 El pase de turno (la tablet cambia de manos) [Propuesta + UX B1, B3, m5]

| Paso | Qué pasa | Tiempo | Toques |
|---|---|---|---|
| 0 | **Solo si terminó un turno de Maxi (M3.3, ritual)**: su par vuela a la cinta, su retrato vuelve a su ventanita (que destella) y Coco dice "¡ahora a echarle porras!" | 1,2 s | Las cartas solo hacen el pulso |
| 1 | **Solo si terminó con "no es este"**: las dos cartas quedan a la vista `ms_volteo_equipo` (1500 ms), **para que todo el equipo las vea y se acuerde**, y se tapan en cascada | 1,5 s | Las cartas solo hacen el pulso |
| 2 | El retrato de quien sigue **vuela de la barra al centro**, grande (≈ 260 px), sobre el tablero oscurecido al 40 %. Suena un "fiuu" y la voz "¡Le toca a Nicole!". **En este mismo momento, si corresponde, el Coleccionauta salta una galleta (B3)**: la nave gira y "pasa el tiempo" | 0,6 s | Las cartas solo hacen el pulso |
| 3 | **Puerta de turno** (B1, abajo) | hasta que se abra | Ver B1 |
| 4 | El retrato vuelve a su ventanita, el tablero se aclara y empieza el turno | 0,4 s | Las cartas solo hacen el pulso |
| 5 | **Bloqueo obligatorio de 400 ms** después de abrir la puerta (B1.3) | 0,4 s | Las cartas solo hacen el pulso |

En todos los pasos, una carta tocada responde con el **pulso en menos de 100 ms**, pero no se da vuelta
(B1.4).

**La puerta de turno (B1)**:

- **Toque**: la puerta se abre **solo tocando el retrato grande**, con hitbox = dibujo de 260 px + 20 px
  de margen por lado. Un toque fuera del retrato hace que el retrato salte y repita "¡Le toca a Nicole!".
  Esa repetición tiene un enfriamiento de 2 s, para que un manotazo no la dispare en bucle.
- **Arrastre, después de un turno de Maxi**: con `puerta_tras_semilla: "arrastre"` (por defecto), la
  puerta pide **arrastrar el retrato hasta su ventanita** de la barra.
  - El recorrido es de ≈ 200-250 px, con un imán de 80 px alrededor de la ventanita.
  - La ventanita vacía brilla, y una flechita de estrellitas animada va del retrato a la ventanita.
  - Voz: "¡Nicole, sube a tu ventanita!".
  - Si el dedo se suelta lejos, el retrato vuelve blandito al centro (0,3 s), sin sonido de error.
  - Con `"toque"`, se abre igual que en el punto anterior.
- **Recordatorio (m5)**: si nadie abre la puerta en 10 s, Cometa repite "¡Nicole, te toca!", **como
  máximo 2 veces**. Después el retrato solo respira.
- **Si Maxi no está** (se fue a jugar con sus autitos), un hermano mayor abre su puerta y juega su turno
  guiado: el equipo sigue sin esperar.

**Cuándo salta el rival en el paso 2 (B3)**:

- Salta solo si el turno que terminó fue de Nicole o de Sofía (`maxi_mueve_rival: false`).
- El salto ocurre **mientras el retrato del siguiente vuela al centro**, nunca al final del turno
  anterior.
- Si ese salto lo hace llegar, la derrota-gag (§5.5) empieza **cuando el retrato del siguiente ya está en
  el centro**, sin abrir la puerta. Así perder "le pasa a todos".

---

## 5. Aplicación a Parejas de Coco

### 5.1 Alternativas evaluadas

| Alternativa | Referencia | Estado |
|---|---|---|
| **A. Memorice de mesa, tablero compartido y reglas por edad en cada turno** | Memorice de mesa ("si aciertas, sigues jugando") más los cooperativos de HABA *Mi primer frutal* y Peaceable Kingdom *Hoot Owl Hoot!* (el rival avanza por turnos) | **Elegida para la v1** |
| B. Mesa de tres colores: cada hermano con sus propias parejas en la mesa | Memorice con mazos mezclados | **[PO] Solo respaldo**, por si en el playtest Sofía se aburre "llevando" al equipo |
| C. Carrera cooperativa tipo *Zicke Zacke Hühnerkacke* | *Zicke Zacke Hühnerkacke* (Zoch) | **[PO] Para después**. Queda reservada como `regla: "carrera"` del motor |

Las tres son de memorice, así que todas viven en Parejas (regla de oro 3).

### 5.2 Reglas del turno según la edad [Propuesta sobre R4 y R5 del PO; UX B2, M1, M2, M10]

Regla común: **si formas una pareja, sigues jugando; con el "no es este" que corresponda, pasa el turno**
(memorice de mesa).

| | **Maxi · Semilla (turno guiado)** | **Nicole · Brote** | **Sofía · Estrella** |
|---|---|---|---|
| Al empezar el turno | Coco elige **una pareja pendiente** y sus dos cartas **respiran con halo dorado** (`halo_idle`) | Nada especial | Nada especial |
| Qué pareja recibe el halo | En este orden de preferencia: 1) una pareja **que nadie ha visto** y **de sus gustos** (`gustos: ["maxi"]` en el pool); 2) una que nadie ha visto; 3) cualquiera pendiente. **Nunca el comodín** (es una carta sola). **Puede ser la pareja lupa**, y si la forma: "¡Maxi encontró la lupa para todo el equipo!" | — | — |
| Si toca una carta con halo | Se da vuelta, y la compañera **brilla más fuerte** y se mece | — | — |
| Si toca una carta normal sin halo | Se da vuelta 700 ms, Coco **dice qué es** ("¡un pony!") y se tapa sola. Su turno **no termina** y las cartas con halo saltan para llamarlo | — | — |
| Si toca una carta especial sin halo (comodín o lupa) (M10) | **No se da vuelta**: solo hace el pulso con un sonido amable, y las cartas con halo saltan para llamarlo | — | — |
| Si sigue sin acertar | Tras 2 toques fuera del halo, o 6 s sin tocar, las dos cartas del halo **se quedan a la vista** y solo falta tocarlas | — | — |
| Pares por turno | `pares_turno_semilla` (**1**), y después viene el ritual de fin de turno (§4.3, paso 0) | Ilimitados mientras acierte | Ilimitados mientras acierte |
| "No es este" | **No existe** para Maxi | **Segunda oportunidad**: el primer "no es este" del turno **no** lo termina. Se comunica **solo** con la voz de Coco ("¡uy, otra!") y un gesto de Coco (guiño y besito soplado). **Nada queda en pantalla para contar** (B2). El segundo fallo pasa el turno | Pasa el turno en el acto |
| Ayuda extra | — | Si pasa **2 turnos seguidos sin par**, al empezar el siguiente, una carta de una pareja **ya vista** brilla tenue | Ninguna |
| Su truco (M2) | "Cartas que brillan" | "El besito de Coco" (la segunda oportunidad) | "Hacer retroceder al Coleccionauta" (§5.3, racha de 3), que vale para Nicole también, pero es su gran momento |
| ¿Mueve al rival? | **No**. El Coleccionauta **se queda embobado mirándolo** y aplaude su fiesta | Sí, un salto durante el pase siguiente | Sí, un salto durante el pase siguiente |

**Racha en equipo (M1)**:

- **En equipo no existe el bloque `puntaje`**: ni número de racha, ni "+puntos", ni "¡a la primera!", ni
  vela, ni récord individual. Si el nivel de equipo trae `puntaje`, el motor lo ignora.
- La racha suena igual que en Semilla (`"solo_sonido"`): el tono sube un semitono por par seguido y se
  encienden los nuditos de la cresta de Coco, siempre en **arcoíris**, nunca del color de quien juega.
- **Un buen turno hace retroceder al rival** (`racha_retrocede_rival: 3`):
  - al formar **3 pares seguidos en un mismo turno**, el Coleccionauta tropieza y **retrocede una
    galleta**, y lo celebra todo el equipo;
  - con 6 seguidos, otra galleta, y así cada 3;
  - nunca retrocede antes de la galleta de partida;
  - el comodín cuenta como un par de la racha.
  - Maxi no llega a 3 (forma 1 par por turno).

**Cartas especiales en equipo** (motor §10.3):

| Carta | En equipo |
|---|---|
| Lupa | Sí. Se celebra como del equipo |
| Comodín arcoíris | Solo si Nicole está en el equipo. Lo juegan Nicole y Sofía; en el turno de Maxi está inerte (M10) |
| Carta dorada | **No** (puntos individuales, R2) |
| Carta del Coleccionauta | **No** (él ya es el rival) |

**Presentación del modo (M2)**: la primera partida en equipo de cada combinación de hermanos empieza con
Coco (voz `intro_equipo_trucos`): "¡Cada uno juega con su propio truco! Maxi tiene cartas que brillan,
Nicole tiene un besito mío, y Sofía puede hacer retroceder al Coleccionauta". La línea se arma según
quiénes juegan, con tres variantes. Las partidas siguientes usan la intro corta `intro_equipo`.

### 5.3 El rival: el Coleccionauta y la pista de galletas [PO: el Coleccionauta; Propuesta: forma]

- **El Coleccionauta es el de su canon** (`docs/guia-estilo-generacion.md` y la intro): **gafas-lupa y
  mochila-torre**. No lleva monóculo, ni "caja de colección", ni nave-aspiradora: **su mochila-torre es
  la que aspira y estornuda**. Corrección del `guionista`, 06-Oct-2026.
- **La pista**: a la izquierda está Coco (tocable, M4). El Coleccionauta, a pie y con su mochila-torre
  a la espalda, parte en la **galleta 0**. Hay `pasos_rival` galletas hasta la mesa del
  equipo, a la derecha. Junto a la mesa, la **cinta arcoíris** se llena con cada par del equipo: es la
  meta compartida que se ve.
- **Cómo avanza**: salta una galleta en el paso 2 del pase (§4.3), después de un turno de Nicole o de
  Sofía, con un "boing" y una risa tonta ("¡jo, jo!").
  - Con cada par del equipo pone cara de "¡ay, no!" y se le resbalan las gafas-lupa.
  - **Su voz reacciona como máximo a 1 de cada 3 pares** (`rival_par`), y nunca encima de una línea de
    Coco. Las otras veces basta la cara.
  - Con la racha de 3, tropieza y retrocede.
  - **Nunca da miedo.**
- **El equipo gana** si forma todas las parejas antes de que llegue.
- **Calibración**: meta de **~8 de cada 10 partidas ganadas** (percentil 80 de turnos), con el simulador
  de la ficha del motor:
  - memoria de ~3 cartas para Nicole y de ~5 para Sofía;
  - segunda oportunidad para Nicole;
  - Maxi intercalado, con 1 par nuevo por turno;
  - retroceso con racha de 3;
  - vistazo de equipo.

  Valores **estimados** para la zona 1, que `disenador-niveles` recalcula:

| Equipo (`clave_equipo`) | Tablero z1 | `pasos_rival` z1 (estimado) | Tablero z5 |
|---|---|---|---|
| `maxi+nicole` | 6 pares, 3×4 | 7 | 8 pares, 4×4 |
| `maxi+sofia` | 8 pares, 4×4 | 6 | 10 pares, 4×5 |
| `nicole+sofia` | 10 pares, 4×5 | 9 | 12 pares, 4×6 |
| `maxi+nicole+sofia` | 10 pares, 4×5 | 6 | 10 pares, 4×5, con lupa y comodín |

- **Con Maxi en el equipo**, las cartas miden **≥ 110 px** y el máximo es 4×5 = 20 cartas (el tablero
  mide 1200 × 490). Sin Maxi, el máximo es 4×6, con cartas ≥ 100 px.
- **Contenido**: un mazo mixto con los gustos de los tres (dinos y vehículos de Maxi; jirafa, pony,
  gatito y ropa de Nicole; cachorros y ponys de Sofía), figuras del planeta y banderas (Chile con
  `fijo: true`). Va en estilo Semilla ("peluche pintado", grande). Lo arma `disenador-niveles`.

### 5.4 El vistazo al repartir en equipo [Propuesta UX M6, por confirmar con el PO]

- Siempre en el formato de Brote: **parejas completas**, con **como máximo 3 pares (6 cartas)**, durante
  **3 s**, sea cual sea el tablero y el equipo.
- Regla general: ≈ 1 s por par mostrado, mínimo 2 s.
- Voz corta: "¡mírenlas bien, equipo!".
- Durante el vistazo, los toques solo hacen el pulso.

### 5.5 Fallo del equipo: derrota-gag [Propuesta + UX B3, m4]

1. Ocurre cuando el Coleccionauta llega a la mesa (siempre en el paso 2 del pase, §4.3). El retrato del
   siguiente ya está en el centro, y entonces empieza el gag:
   - el Coleccionauta **aspira con su mochila-torre las cartas que quedan**, con un "¡a mi colección!"
     y un "sluuurp";
   - la mochila-torre se infla y **estornuda**, y las cartas salen volando como cabritas de vuelta a la
     mesa;
   - él cae sentado con las cartas en la cabeza.
2. Las líneas de la derrota **nunca nombran a un hermano y siempre hablan en plural** (B3.3):
   - el Coleccionauta: "¡uf, cuesta guardar tantas cosas solo!";
   - Cometa: "¡nos alcanzó! ¡Otra vez, equipo!";
   - Cometa cierra con un logro común, contando los pares ya formados: "¡igual juntamos 7 parejas!".
   - Para esto hace falta una voz por número, del 1 al 12 (encargo al `guionista`).
3. Los hermanos de la barra **se ríen juntos**. Nadie queda señalado.
4. **Botón "¡otra vez!" de ≥ 160 × 160 px** (m4), centrado sobre el gag.
5. Al reintentar:
   - **las parejas ya formadas quedan formadas**;
   - se reparten de nuevo solo las pendientes, con un vistazo nuevo;
   - el Coleccionauta vuelve caminando a la galleta 0, silbando, con `pasos_rival` completo;
   - la puerta se abre para **el hermano que ya estaba en el centro**, porque el turno siguiente ya
     estaba anunciado.

### 5.6 La victoria del equipo [Propuesta + UX R7/m7]

- **Por cada par**: la micro-celebración del motor, y el retrato de quien jugó hace su **gesto corto**
  (0,6 s) mientras los demás aplauden. El par vuela a la **cinta arcoíris del equipo**.
- **Fiesta final** (celebración multihermano, §11.3):
  1. El Coleccionauta frena y **aplaude también** (`rival_aplaude`: "¡qué buen equipo! ¿Dónde venden
     uno?"). Le cae confeti en las gafas-lupa. **No sale ninguna red**, porque suena a captura.
  2. **Todos los del equipo salen juntos al frente**, y cada uno hace **su gesto canon** por turnos
     (0,8 s cada uno, en el orden de los turnos, sin repetir a Maxi):
     - Maxi: tres saltitos, el puño arriba y el "¡síiii!";
     - Nicole: el corazón coreano y la carita tierna;
     - Sofía: la mano en la cintura, el signo de la paz y el guiño.
     
     El foco, la duración y el volumen de cada uno son iguales. El tamaño del sprite es el natural de
     cada uno (m7).
  3. **Choque de manos de todos** al centro, confeti arcoíris y la voz "¡Equipo estelar!" (Cometa).
  4. **Destellos**: si es la primera victoria de alguno de ellos en este nivel de equipo, aparece
     "+50" **bajo cada retrato premiado, todos con el mismo tamaño** (§7.1). Si ninguno recibe
     destellos, no se muestra conteo: solo la fiesta.
  5. **Récord del equipo** (§7.2) y, si es la primera victoria de este nivel en equipo, se enciende la
     **estrellita de equipo**, que vuela hacia un ícono de la nave en la esquina.

---

## 6. Por qué el rival avanza por turnos y durante el pase

- Si cada "no es este" de Nicole moviera al Coleccionauta, Sofía (que se frustra rápido, según su ficha)
  podría culparla.
- Incluso con un avance por turno, si el salto ocurre justo al terminar el turno de Nicole, los niños
  leen "perdimos por Nicole" (B3). Por eso el salto pertenece a **la transición**, cuando la nave gira y
  el siguiente ya está al centro.
- El reto real sigue: **un buen turno, de 3 pares seguidos, hace retroceder al rival**. Eso premia la
  memoria sin señalar a nadie.

---

## 7. Cómo se reparte el avance [PO]

### 7.1 Destellos [PO]

- **50 destellos para cada hermano participante, solo la primera vez** que ese hermano gana ese nivel de
  equipo.
  - Si después el mismo nivel se gana con otro equipo, solo reciben los que todavía no habían cobrado.
  - Nunca dependen de cuántos pares hizo cada uno.
- El monto viene de `mapa.json` (`destellos_equipo_por_hermano: 50`, §11.2), igual que hoy
  `destellos_por_estacion`.
- **Una victoria en equipo no marca completada la estación individual de nadie [PO]**, ni cuenta para
  abrir zonas.

### 7.2 Récord del equipo [Propuesta + UX m6]

- Hay un récord **por combinación de hermanos y nivel**: los **pasos que usó el Coleccionauta** al ganar
  (menos es mejor). Si ganan con el Coleccionauta en la galleta 3, el récord es 3.
- **Se ve sin leer**: una **banderita del equipo** en la galleta del récord ("la última vez lo dejamos
  aquí"). Si el equipo gana con el Coleccionauta **antes** de la banderita, la banderita salta y suena
  "¡nuevo récord del equipo!" (Coco con el trofeo-cupcake del Río).
- **Sin récord previo**: no hay banderita. Al ganar suena "¡su primer récord de equipo!" (m6).
- Los récords **parten en cero [PO]**.

### 7.3 Meta compartida: las 5 estrellitas del equipo [PO]

- Cada zona de Arcoíris cuyo nivel de Parejas en equipo haya ganado **cualquier** combinación de
  hermanos enciende **una estrellita** en el botón "¡Juntos!". Son 5 en total.
- Cuando se sume un segundo minijuego en equipo, el PO decide si cada juego agrega su fila o si la
  estrellita pide ganar todos los juegos en equipo de la zona.

---

## 8. Contrato de datos del nivel de equipo de Parejas (exacto)

Archivo: `datos/niveles/arcoiris/<zona>/parejas_equipo.json`.

- Usa los campos normales del motor que aplican: `pool` con `fijo` y `voz` por pareja, `especiales`,
  `oculto`, `id_coleccion` y `lineas_voz` del motor.
- **No usa** `perfil`, `rondas`, `limite_intentos`, `puntaje` ni `umbrales_*`. Si los trae, el motor los
  ignora en equipo.

```jsonc
{
  "id_nivel": "arcoiris_z1_parejas_equipo",
  "motor": "emparejar",
  "modo_juego": "equipo",               // obligatorio en niveles de equipo
  "regla": "parejas",                   // v1: solo "parejas"
  "oculto": true,
  "modo": "identico",
  "tiempo_volteo_ms": 1500,             // en equipo es el mismo ms_volteo_equipo
  "pool": [
    { "id_pareja": "trex", "gustos": ["maxi"], "elemento_a": { "figura": "trex" }, "elemento_b": { "figura": "trex" } },
    { "id_pareja": "bandera_chile", "fijo": true, "voz": "voces/arcoiris/emparejar/banderas/chile.wav",
      "elemento_a": { "figura": "bandera_chile" }, "elemento_b": { "figura": "bandera_chile" } }
    // …
  ],
  "especiales": [ { "tipo": "lupa", "ms": 1500 } ],   // solo "lupa" y "comodin" en equipo
  "equipo": {
    "rival": "coleccionauta",           // id de rival para pista_rival.gd: "coleccionauta" | "nube_gris" | "reloj"
    "orden": "maxi_intercalado",        // "maxi_intercalado" | "menor_a_mayor"
    "puerta_tras_semilla": "arrastre",  // "arrastre" | "toque" (B1)
    "bloqueo_tras_puerta_ms": 400,      // B1.3, obligatorio (> 0)
    "ms_volteo_equipo": 1500,
    "pares_turno_semilla": 1,
    "segunda_oportunidad_brote": true,
    "ayuda_brote_tras_turnos_sin_par": 2,
    "maxi_mueve_rival": false,
    "racha_retrocede_rival": 3,         // M1; 0 = desactivado
    "vistazo": { "pares": 3, "ms": 3000 },  // M6 (Propuesta UX, por confirmar con el PO)
    "composiciones": {                  // clave_equipo: ids en orden alfabético unidos por "+"
      "maxi+nicole":       { "filas": 3, "columnas": 4, "cantidad": 6,  "pasos_rival": 7 },
      "maxi+sofia":        { "filas": 4, "columnas": 4, "cantidad": 8,  "pasos_rival": 6 },
      "nicole+sofia":      { "filas": 4, "columnas": 5, "cantidad": 10, "pasos_rival": 9 },
      "maxi+nicole+sofia": { "filas": 4, "columnas": 5, "cantidad": 10, "pasos_rival": 6 }
    }
  },
  "lineas_voz": {
    // Rutas relativas a assets/audio/ (ids del guion docs/guiones/voces-modo-equipo-parejas.md).
    // Arreglo = variantes: el motor elige al azar sin repetir la anterior.
    // "voces/nucleo/equipo/…": las lee la capa genérica (GestorTurnos, barra_equipo, pista_rival).
    // El resto las lee el motor emparejar.

    // Inicio (§3.1 del guion)
    "intro_equipo": [
      "voces/arcoiris/emparejar/equipo/intro.wav",
      "voces/arcoiris/emparejar/equipo/intro_ayudan.wav"
    ],                                  // secuencia, no variantes
    "rival_entra": "voces/arcoiris/emparejar/equipo/coleccionauta_entra.wav",
    "coco_juntemos": "voces/arcoiris/emparejar/equipo/coco_juntemos.wav",
    "intro_equipo_trucos": { "maxi": "PENDIENTE", "nicole": "PENDIENTE", "sofia": "PENDIENTE" },  // M2: falta en el guion
    "vistazo": "voces/arcoiris/emparejar/equipo/vistazo.wav",

    // Pase de turno (§2 del guion; capa genérica)
    "le_toca": {
      "maxi":   ["voces/nucleo/equipo/le_toca_maxi_01.wav",   "voces/nucleo/equipo/le_toca_maxi_02.wav",   "voces/nucleo/equipo/le_toca_maxi_03.wav"],
      "nicole": ["voces/nucleo/equipo/le_toca_nicole_01.wav", "voces/nucleo/equipo/le_toca_nicole_02.wav", "voces/nucleo/equipo/le_toca_nicole_03.wav"],
      "sofia":  ["voces/nucleo/equipo/le_toca_sofia_01.wav",  "voces/nucleo/equipo/le_toca_sofia_02.wav",  "voces/nucleo/equipo/le_toca_sofia_03.wav"]
    },
    "te_toca_recordatorio": {           // m5: como máximo 2 veces (el texto se ajusta a B1, ver nota)
      "maxi": "voces/nucleo/equipo/te_toca_maxi.wav",
      "nicole": "voces/nucleo/equipo/te_toca_nicole.wav",
      "sofia": "voces/nucleo/equipo/te_toca_sofia.wav"
    },
    "maxi_ayuda": "voces/nucleo/equipo/maxi_ayuda.wav",
    "sube_ventanita": { "maxi": "PENDIENTE", "nicole": "PENDIENTE", "sofia": "PENDIENTE" },  // B1.2: falta en el guion
    "porras_fin_maxi": "PENDIENTE",     // M3.3: falta en el guion

    // Turno guiado de Maxi (§3.2 del guion)
    "maxi_brillan": [
      "voces/arcoiris/emparejar/equipo/maxi_brillan_01.wav",
      "voces/arcoiris/emparejar/equipo/maxi_brillan_02.wav"
    ],
    "maxi_aqui": "voces/arcoiris/emparejar/equipo/maxi_aqui.wav",
    "maxi_par": "voces/arcoiris/emparejar/equipo/maxi_par.wav",
    "maxi_lupa": "PENDIENTE",           // Maxi forma la pareja lupa: falta en el guion

    // Acierto y fallo de Nicole y Sofía (§3.3 del guion), sin nombre
    "acierto_equipo": [
      "voces/arcoiris/emparejar/equipo/acierto_01.wav", "voces/arcoiris/emparejar/equipo/acierto_02.wav",
      "voces/arcoiris/emparejar/equipo/acierto_03.wav", "voces/arcoiris/emparejar/equipo/acierto_04.wav"
    ],
    "fallo_equipo": [                   // solo el "no es este" que termina el turno
      "voces/arcoiris/emparejar/equipo/fallo_01.wav", "voces/arcoiris/emparejar/equipo/fallo_02.wav",
      "voces/arcoiris/emparejar/equipo/fallo_03.wav", "voces/arcoiris/emparejar/equipo/fallo_04.wav"
    ],
    "segunda_oportunidad": "voces/arcoiris/emparejar/equipo/nicole_otra.wav",  // B2: solo voz, nada en pantalla
    "brote_ayuda": "voces/arcoiris/emparejar/equipo/brote_ayuda.wav",
    "animo_hermanos": "PENDIENTE",      // B2: voces de los niños opcionales; si no hay, solo animación y SFX

    // Rival (§4 del guion; capa genérica salvo lo de cartas)
    "rival_avanza": [
      "voces/nucleo/equipo/coleccionauta/avanza_01.wav", "voces/nucleo/equipo/coleccionauta/avanza_02.wav",
      "voces/nucleo/equipo/coleccionauta/avanza_03.wav", "voces/nucleo/equipo/coleccionauta/avanza_04.wav"
    ],
    "rival_par": [                      // como máximo 1 de cada 3 pares, nunca sobre Coco
      "voces/nucleo/equipo/coleccionauta/par_01.wav", "voces/nucleo/equipo/coleccionauta/par_02.wav",
      "voces/nucleo/equipo/coleccionauta/par_03.wav"
    ],
    "rival_embobado": [
      "voces/nucleo/equipo/coleccionauta/embobado_01.wav", "voces/nucleo/equipo/coleccionauta/embobado_02.wav",
      "voces/nucleo/equipo/coleccionauta/embobado_03.wav"
    ],
    "rival_retrocede": "PENDIENTE",     // M1, racha de 3: falta en el guion
    "rival_aplaude": [
      "voces/nucleo/equipo/coleccionauta/aplaude_01.wav", "voces/nucleo/equipo/coleccionauta/aplaude_02.wav"
    ],
    "rival_vuelve": "voces/nucleo/equipo/coleccionauta/vuelve.wav",

    // Derrota-gag (§4.3 del guion), secuencia en este orden
    "derrota_gag_equipo": [
      "voces/arcoiris/emparejar/equipo/coleccionauta_aspira.wav",
      "voces/arcoiris/emparejar/equipo/coleccionauta_estornuda.wav",
      "voces/arcoiris/emparejar/equipo/coleccionauta_cansado.wav",
      "voces/arcoiris/emparejar/equipo/coco_otra_vez.wav"
    ],
    "pares_juntados": {},               // B3.3 "¡igual juntamos N parejas!": falta en el guion (1-12)

    // Victoria (§5 del guion), secuencia
    "victoria_equipo": "voces/arcoiris/emparejar/equipo/coco_victoria.wav",
    "fiesta": {
      "al_frente": "voces/nucleo/equipo/al_frente.wav",
      "gesto": { "maxi": "voces/nucleo/equipo/fiesta_maxi.wav", "nicole": "voces/nucleo/equipo/fiesta_nicole.wav", "sofia": "voces/nucleo/equipo/fiesta_sofia.wav" },  // o las tres o ninguna
      "choca": "voces/nucleo/equipo/choca.wav",
      "equipo_estelar": "voces/nucleo/equipo/equipo_estelar.wav",
      "destellos": "voces/nucleo/equipo/destellos.wav",
      "estrellita": "voces/nucleo/equipo/estrellita.wav"
    },
    "record_equipo": "voces/arcoiris/emparejar/equipo/record.wav",
    "primer_record_equipo": "PENDIENTE" // m6: falta en el guion
  }
}
```

**Voces de la selección y del mapa** (no van en el nivel, las leen directamente la selección y
`mapa_planeta.gd`):

- `nucleo_equipo_juntos`, `nucleo_equipo_armar`, `nucleo_equipo_al_puf_01/02`, `nucleo_equipo_vuelve`,
  `nucleo_equipo_yo_tambien_<hermano>`, `nucleo_equipo_minimo_dos` y `nucleo_equipo_despegar`;
- `arcoiris_mapa_equipo_llegada` y `arcoiris_mapa_equipo_estacion_pronto`.

**Reglas de mezcla de voces**:

- Las voces nunca se pisan: la voz de Coco tiene prioridad y la del rival se omite si Coco está
  hablando.
- **La voz del rival al formarse un par**: como máximo 1 de cada 3 pares.
- **En Maxi**, `maxi_par` reemplaza a `acierto_equipo`.

**Líneas que faltan, encargo de vuelta al `guionista`** (marcadas `"PENDIENTE"`: si falta el archivo,
el motor sigue sin voz y nunca falla):

- `intro_equipo_trucos` (M2);
- `sube_ventanita` (B1);
- `porras_fin_maxi` (M3);
- `maxi_lupa`;
- `rival_retrocede` (M1);
- `pares_juntados` 1-12 (B3);
- `primer_record_equipo` (m6).

**Conflictos del guion con la validación UX** (el `guionista` debe corregirlos):

- `te_toca_<hermano>` dice "Toca la pantalla", pero con B1 la puerta se abre **solo tocando el
  retrato**: debe decir "¡toca tu carita!", o, después de un turno de Maxi, "¡sube a tu ventanita!".
- `nucleo_equipo_coleccionauta_avanza_*` tiene como disparador "fin de turno", pero según B3 suena
  **durante el pase** (paso 2 del §4.3).

**Reglas de lectura del contrato**:

- `clave_equipo` = los ids de `Progreso.equipo_activo` **ordenados alfabéticamente** y unidos con `+`.
  El orden alfabético coincide con el de edad.
- Si una composición no está en `composiciones`, el motor usa la de más pares que quepa, con aviso en
  consola. Nunca falla en silencio.
- Las parejas de cada partida se sortean del `pool` según `cantidad`, y las `fijo` siempre entran.
- `tiempo_volteo_ms` y `ms_volteo_equipo` deben valer lo mismo. Si difieren, manda `ms_volteo_equipo`.

---

## 9. Riesgos de usabilidad que siguen abiertos para el build (HE-64)

Lo que el diseño ya corrigió (B1-B3 y M1-M10) se verifica sobre el build real, con foco en:

1. **B1**: los manotazos de Maxi y si el arrastre a la ventanita les cuesta a Nicole y a Sofía.
2. **M3**: si Maxi se queda con la ventanita de porra o se va.
3. **B3 y R6**: si alguien igual dice "perdimos por tu culpa".
4. **Duración**: con los tres, la meta es de 4 a 6 min. Si pasa de 7 min, achicar los tableros.
5. **Sofía**: si "llevar" al equipo se le vuelve aburrido (si pasa, se activa la alternativa B).

---

## 10. Qué debe hacer cada rol

- **`dev-godot`**: §3, §4, §5 y §11 tal como están, más los menores del §13.
- **`tester-qa`**: un arnés `herramientas/qa_test_equipo_parejas.gd`, con semilla fija, que respalde y
  restaure `progreso.json` (memoria del proyecto). Debe cubrir:
  - las 4 composiciones y los dos valores de `orden`;
  - el turno de Maxi: siempre forma un par, no mueve al rival y en su turno el comodín y la lupa están
    inertes;
  - la segunda oportunidad de Nicole, sin nada que se dibuje en pantalla;
  - la regla de mesa de Sofía;
  - el salto del rival **solo en el paso 2 del pase**;
  - el retroceso con racha de 3;
  - la derrota-gag, que conserva los pares formados;
  - la puerta (toque y arrastre) y el bloqueo de 400 ms;
  - los 50 destellos una sola vez por hermano y nivel de equipo;
  - que la victoria en equipo **no** marca completados los niveles individuales;
  - el récord por clave de equipo y las 5 estrellitas;
  - que **el guardado no tenga ningún dato de pares por hermano**.
- **`disenador-niveles`**: los 5 `parejas_equipo.json`, el mazo mixto con `gustos` y la calibración de
  `pasos_rival` con el simulador.
- **`guionista`**: las voces del §8 (en plural y sin nombres en la derrota), la intro de los trucos y
  las del Coleccionauta según su arco. **Hay que estimar el costo del TTS y pedir el OK del PO antes de
  generar.**
- **`disenador-personajes`**:
  - el gesto corto de cada hermano (0,6 s);
  - el puf de "yo miro";
  - la nave de juguete con ventanitas (ícono y barra);
  - para el Coleccionauta, de su canon (gafas-lupa y mochila-torre): las poses de saltar galleta,
    tropezar, embobado, aplaudir, la mochila-torre que aspira, se infla y estornuda, y caer sentado.
    En el gag de embobado **no estira los brazos hacia Maxi**, por pedido del `guionista`.

---

## 11. Arquitectura: cómo se respeta "el núcleo no conoce minijuegos"

### 11.1 Piezas y responsabilidades

| Pieza | Dónde | Sabe de… | No sabe de… |
|---|---|---|---|
| `Progreso` (autoload) | `scripts/autoloads/progreso.gd` | El equipo activo, los destellos, el récord y las estrellitas de equipo | Cartas, turnos |
| Selección | `scripts/nucleo/seleccion_personaje.gd` | Armar el equipo y fijar `Progreso.equipo_activo` | Qué juegos admiten equipo |
| Mapa del planeta | `scripts/nucleo/mapa_planeta.gd` | Leer `nivel_equipo` de `mapa.json` e instanciar la escena del motor con `equipo` | Parejas |
| **`GestorTurnos`** (nuevo, genérico) | `scripts/base/gestor_turnos.gd` | El orden, el turno actual, el pase (pasos 0-5), la puerta, el bloqueo, los pasos del rival, la racha y el retroceso | Cartas, qué es un "par" |
| `minijuego_base.gd` | `scripts/base/` | Crear el `GestorTurnos` si hay equipo, `perfil_de()` y el registro del resultado del equipo en `Progreso` | Las reglas de un juego concreto |
| `barra_equipo.gd` y `pista_rival.gd` (nuevos) | `scripts/ui/` | Dibujar y animar lo que el gestor les dice, más la ventanita de porra | Cartas |
| `celebracion.tscn` | `escenas/ui/` | La fiesta multihermano | Cartas |
| Motor `emparejar` | `scripts/motores/emparejar/` | **Qué termina un turno** y las capas por edad (§5.2) | El guardado, la navegación |

### 11.2 `mapa.json` (datos del planeta)

- **Raíz**: un campo nuevo, junto a `destellos_por_estacion`:

  ```jsonc
  "destellos_equipo_por_hermano": 50
  ```

- **Estación**: un campo nuevo, opcional, que en v1 solo llevan las 5 estaciones de Parejas:

  ```jsonc
  {
    "juego": "parejas",
    "escena": "res://escenas/minijuegos/emparejar/motor_emparejar.tscn",
    "niveles": { "maxi": "…", "nicole": "…", "sofia": "…" },
    "nivel_equipo": "res://datos/niveles/arcoiris/zona1_claro/parejas_equipo.json"
  }
  ```

- **Sin `nivel_equipo`**, la estación está dormida en modo equipo.
- **En modo equipo**, `mapa_planeta.gd` instancia la `escena` de la estación con estos valores:
  - `ruta_nivel = nivel_equipo`;
  - `planeta_id`;
  - `equipo = Progreso.equipo_activo`;
  - `id_perfil = ""`;
  - `destellos_fijos = destellos_equipo_por_hermano`.

### 11.3 Extensión de `minijuego_base.gd` (firmas exactas)

```gdscript
## Vacío = juego en solitario (todo igual que hoy). 2 o 3 ids = modo equipo.
@export var equipo: Array[String] = []

## Lo crea _ready() si es_modo_equipo(); null en solitario.
var turnos: GestorTurnos = null

func es_modo_equipo() -> bool:
	# equipo.size() >= 2 y el nivel trae "modo_juego": "equipo"

func perfil_de(id_hermano: String) -> String:
	# Progreso.obtener_perfil_dificultad(id_hermano): respeta el ajuste de la zona de padres

## Reemplaza a celebrar() en equipo: registra (11.4) ANTES de la fiesta (B1 de HE-10) y monta la
## celebración multihermano. pasos_usados = posición del rival al ganar.
func celebrar_equipo(pasos_usados: int, linea_voz: String = "") -> void
```

- `_registrar_progreso()` **no se llama en modo equipo**: en su lugar, `celebrar_equipo()` llama a
  `Progreso.registrar_victoria_equipo(...)`.
- `obtener_id_personaje()` en equipo devuelve `turnos.hermano_actual()` (lo usan las voces y los gestos
  del turno).
- **Celebración multihermano** (`escenas/ui/celebracion.tscn`): una propiedad nueva
  `ids_personajes: Array[String]`.
  - Con 2 o más, hace la fiesta del §5.6: gestos por turno, choque de manos, sin estrellitas, y "+50"
    bajo cada uno de los ids de `premiados`.
  - Recibe `premiados: Array[String]`, `record_nuevo: bool` y `primer_record: bool`.

### 11.4 `GestorTurnos` (genérico, `scripts/base/gestor_turnos.gd`)

```gdscript
class_name GestorTurnos
extends Node

signal turno_iniciado(id_hermano: String, perfil: String)   # tras la puerta y el bloqueo de 400 ms
signal rival_movido(posicion: int)                          # +1 en el pase; -1 en el retroceso
signal rival_llego()                                        # el motor lanza la derrota-gag
signal entrada_bloqueada_cambio(bloqueada: bool)            # el motor solo muestra el pulso si está bloqueada

func configurar(equipo: Array[String], config: Dictionary, perfiles: Dictionary, capa_ui: CanvasLayer) -> void
	# config = nivel["equipo"]; perfiles = {id: "semilla"|"brote"|"estrella"}; crea barra_equipo y pista_rival
func empezar() -> void                 # primer turno (Maxi si juega), con su puerta
func hermano_actual() -> String
func perfil_actual() -> String
func entrada_bloqueada() -> bool
func notificar_acierto() -> void       # suma a la racha del turno; cada racha_retrocede_rival → rival -1 (mínimo 0)
func terminar_turno(con_fallo: bool) -> void
	# pasos 0/1 según perfil y con_fallo → paso 2 (+1 rival si el perfil saliente != semilla o maxi_mueve_rival)
	# → si llegó: rival_llego() con el retrato del siguiente en el centro; si no: puerta → bloqueo → turno_iniciado
func pasos_usados() -> int             # posición actual del rival (para el récord)
func reiniciar_rival() -> void         # tras "¡otra vez!": vuelve a 0 y abre la puerta del hermano en el centro
```

**Contrato con el motor**:

- El motor **solo** llama `notificar_acierto()` y `terminar_turno(con_fallo)`.
- El motor escucha `turno_iniciado`, para aplicar la capa del perfil (halo de Maxi, segunda oportunidad
  de Nicole), y `rival_llego`.
- Todo lo demás (barra, pista, puerta, porras, voces de "le toca") vive en el gestor y su UI. Así otro
  motor (el Río en equipo, por ejemplo) solo decide cuándo termina un turno.

### 11.5 `Progreso` (guardado)

**Subida de versión: 2 → 3** (stack técnico, guardado versionado). La migración `_migrar_v2_a_v3` solo
**agrega** estructuras vacías y no toca nada existente:

```jsonc
{
  "version": 3,
  "perfiles": {
    "nicole": {
      // … lo de hoy …
      "planetas": { "arcoiris": {
        "destellos": 0, "niveles": {}, "parciales": {}, "records": {},
        "coleccion": [],                        // motor §10.5: ids de colección (solitario y equipo)
        "equipo_premiado": []                   // ids de niveles de equipo en que ESTE hermano ya cobró sus 50
      } },
      "especiales_conocidos": []                // motor §10.3: presentaciones ya vistas ("lupa", "comodin"…)
    }
  },
  "recuerdos_encontrados": {},
  "equipo": {
    "presentado": false,                        // M5.2
    "trucos_presentados": [],                   // claves de equipo que ya oyeron la intro de trucos (M2)
    "planetas": { "arcoiris": {
      "ganados": [],                            // ids de nivel de equipo ganados por cualquier equipo → estrellitas del botón
      "records": {                              // pasos usados (menos es mejor); sin clave = sin récord
        "arcoiris_z1_parejas_equipo": { "maxi+nicole+sofia": 4 }
      }
    } }
  }
}
```

- **En el guardado no existe ningún dato de pares, aciertos o fallos por hermano en equipo** (R2). `tester-qa`
  lo verifica.
- `"equipo_activo"` **no** se guarda: es una variable en memoria.

**API nueva de `Progreso`** (firmas exactas):

```gdscript
var equipo_activo: Array[String] = []          # en memoria; la selección lo fija y lo vacía

func fijar_equipo(ids: Array[String]) -> void   # valida ids, 2-3, sin repetidos
func limpiar_equipo() -> void
func clave_equipo(ids: Array[String]) -> String # ordena alfabéticamente y une con "+"

## Una llamada al ganar. Suma destellos_por_hermano a cada id que no tenga id_nivel en su
## "equipo_premiado" (con agregar_destellos, SIN marcar_nivel_completado), agrega id_nivel a
## "ganados" y guarda el récord si pasos_usados es menor (o si no había). Guarda una sola vez.
## Devuelve {"premiados": Array[String], "record_nuevo": bool, "primer_record": bool, "primera_victoria_nivel": bool}
func registrar_victoria_equipo(planeta_id: String, id_nivel: String, ids: Array[String], destellos_por_hermano: int, pasos_usados: int) -> Dictionary

func obtener_record_equipo(planeta_id: String, id_nivel: String, clave: String) -> int   # -1 = sin récord
func contar_niveles_equipo_ganados(planeta_id: String) -> int                         # 0-5 → estrellitas del botón
func modo_equipo_presentado() -> bool
func marcar_modo_equipo_presentado() -> void
func trucos_presentados(clave: String) -> bool
func marcar_trucos_presentados(clave: String) -> void

# Del motor §10 (sirven también en solitario):
func registrar_coleccionable(id_perfil: String, planeta_id: String, id_coleccion: String) -> bool  # true si es nueva
func obtener_coleccion(id_perfil: String, planeta_id: String) -> Array
func especial_conocido(id_perfil: String, tipo: String) -> bool
func marcar_especial_conocido(id_perfil: String, tipo: String) -> void
```

- **El récord del equipo es "menos es mejor"**, al revés que `registrar_puntaje_nivel`. Por eso vive en
  su propia función y no reutiliza `records` del hermano.
- **La selección** llama `limpiar_equipo()` en `_ready()` y `fijar_equipo()` al tocar "¡Despegar!".
- `perfil_seleccionado` queda con el id del menor del equipo, solo para lo que el mapa ya usa (volumen,
  música). La lógica de equipo usa siempre `equipo_activo`.

---

## 12. Decisiones del PO registradas en esta ficha (06-Oct-2026)

| # | Decisión | Dónde |
|---|---|---|
| 1 | En equipo se juegan **todas las zonas de Arcoíris**, cada uno con su dificultad | §3.3 |
| 2 | **50 destellos iguales para cada hermano, solo la primera vez**. La partida en equipo no marca completada la estación individual. Se mantienen las 5 estrellitas del botón | §3.1, §7 |
| 3 | El rival de Parejas es **el Coleccionauta** | §5.3 |
| 4 | Turnos del menor al mayor, ajustados con M3 (Maxi intercalado) | §4.2 |
| 5 | Los récords parten en cero | §7.2 |
| 6 | La carrera tipo *Zicke Zacke* queda para después | §5.1 |
| 7 | La mesa con parejas propias de cada hermano queda solo de respaldo | §5.1 |

**Pendiente de confirmar por el PO**: el vistazo de equipo con como máximo 3 pares en 3 s (M6, §5.4).

---

## 13. Para Dev: menores de la validación UX de HE-58 (aplicar directo)

| Id | Qué hacer | Dónde quedó |
|---|---|---|
| m1 | Colores de turno: Maxi `#3E77CC`, Nicole `#E8589C`, Sofía `#2FB3AD`. El aura de Sofía nunca es rosa | §4.1 |
| m2 | Voz de confirmación al sacar o meter un hermano en armar equipo | §3.2 |
| m3 | La pantalla de juego en equipo conserva el botón casa (≥ 96 px). Salir no pierde nada: en equipo no hay guardado parcial, y la partida simplemente no cuenta | §4.1 |
| m4 | "¡Otra vez!" en equipo de ≥ 160 × 160 px | §5.5 |
| m5 | El recordatorio "¡te toca!" suena como máximo 2 veces, y después el retrato solo respira | §4.3 |
| m6 | Sin récord previo, no hay banderita: "¡su primer récord!" (en equipo y en solitario) | §7.2; motor §10.1 |
| m7 | "Mismo tamaño" en la fiesta = mismo foco, duración y volumen. No achicar a Sofía | §5.6 |
| m8 | Gomita del tablero impar: redonda, 60 % del tamaño de una carta, sin dorso. Al tocarla se menea y hace "boing" | motor §10.3 |
| m9 | Colección sin contadores ("23/60"). Cada hermano ve solo la suya, desde su mapa | motor §10.5 |
| m10 | El texto flotante ("+200", "×3") nunca se dibuja sobre cartas tapadas, y en equipo no aparece | motor §10.1; §5.2 |
| m11 | UX recomendaba abrir solo las zonas del hermano más avanzado; **el PO decidió todas las zonas** | §3.3 |
