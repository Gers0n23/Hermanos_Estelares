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
- **v3, 06-Oct-2026**:
  - incorpora las correcciones del `guionista` (`docs/guiones/voces-modo-equipo-parejas.md`): el canon
    del Coleccionauta, el límite de su voz y las claves de voz del §8;
  - incorpora la decisión del PO de que **el modo equipo debuta como la Batalla final de Arcoíris**
    (§14, diseño nuevo, todavía sin auditar por UX).
- **v4, 06-Oct-2026**:
  - decisiones del PO: M6 aceptado; la batalla se abre con el primer hermano que recibe el ala y se
    juega solo con los tres;
  - ajustes del guion v2: las claves de voz completas, la equidad de los trucos y las confirmaciones
    del puf con nombre;
  - la validación UX de la batalla (`docs/validaciones/2026-10-06_ux-HE-66-batalla-arcoiris.md`): B1-B3
    y M1-M9 en el §14, los menores en el §14.15, y m5 en el §13, para HE-59.
- **v5, 07-Oct-2026**: re-auditoría UX de HE-66 (misma validación, sección "Re-auditoría HE-66"):
  - **N2** (mayor): regla "Reventón de Maxi en el Río" en el §14.3, más trabajo de motor (§14.15) y
    casos de QA (§14.9);
  - **N3** (mayor): zonas de Formas en y 128-584 (§14.9 y §14.15), con medición de QA;
  - **N5**: firmas exactas del `GestorTurnos` y contrato con el motor (§11.4);
  - **N6**: al retomar una ronda guardada empieza Maxi (§14.6); el §13 m3 se precisa "fuera de la
    batalla";
  - **N1**: las 8 piezas de Formas quedan sujetas a la calibración de `disenador-niveles` (§14.3);
  - **N4**: §14.11 ya no pide la línea descartada. **N7** queda para HE-67 y HE-68 (sin cambios aquí).
- **v6, 07-Oct-2026**: decisiones del PO tomadas con el simulador (`herramientas/simular_equipo.py`) y
  cierre de lo que la calibración y el storyboard HE-68 dejaron pendiente para `disenador-mecanicas`:
  - **[PO] tope de pares por turno en Parejas en equipo** (Maxi 1, Nicole 2, Sofía 3) en la batalla y en
    "los tres" y maxi+nicole; termina en "¡turno perfecto!", nunca como fallo (§5.2, §8, §11.4);
  - **[PO] el rival retrocede por "turno perfecto"**, no por racha de 3, en Formas y en Parejas con
    tope. **En el Río se mantiene la racha de 3** (justificado en §5.2) (§4.3, §5.2, §6, §14.3);
  - **[PO] tableros 4×6 permitidos con Maxi**; corregido el error de la zona 5 (21 cartas en 4×5)
    (§5.3);
  - cifras actualizadas a los datos calibrados (Río 20 gotas, Formas 12 piezas, Parejas 12 pares en
    4×6) con remisión a `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md` (§5.3, §8,
    §14.3, §14.9);
  - del storyboard (`docs/cinematicas/batalla_arcoiris.md` §14): "¡todos a la nave!" **sí** se repite al
    retomar (§14.6); firmas del gag de derrota en el motor (§11.4, §14.15); "cinemática ya vista" **por
    familia** (§11.5, §14.9); "¡turno perfecto!" es de **Cometa** (§14.15); la entrada pasa sola a la
    ronda 1 (§14.7);
  - campos de datos nuevos de la calibración, aceptados (§14.9);
  - derrota-gag orquestada por `minijuego_base` con virtuales del motor (`gag_derrota_aspirar`,
    `gag_derrota_devolver`, `gag_derrota_terminar_ya`, `reintentar_equipo`, `contar_logro_equipo`);
    las voces de la batalla quedan en `lineas_voz`, no en `equipo.voces_batalla` (§11.4);
  - se retira `arcoiris_batalla_formas_retrocede_celebra` (§14.3, §14.15);
  - riesgos 8-12 (§9), tareas por rol (§10), decisiones 15-18 (§12) y estado de la batalla (§14.14).
  - **[PO, 07-Oct-2026] confirmado**: el besito de Coco no rompe el turno perfecto (§5.2), y la ronda 1 arranca sola tras la entrada (§14.7).
- **v6.1, 07-Oct-2026**: verificación UX N2/N3/N6 (misma validación, sección "Verificación N2/N3/N6",
  hallazgos N8 a N13) y una decisión del PO:
  - **[PO, 07-Oct-2026] UX N10, "se resbala y no avanza"**: en el pase que sigue a un turno perfecto, el
    Coleccionauta intenta saltar, se resbala y se queda sentado: **ese pase no avanza**. Reemplaza el
    "el salto del paso 2 ocurre igual" de la v6 (§4.3 pasos 0b y 2, §5.2, §5.3, §6, §11.4, §12 n.º 19,
    QA en §10 y §14.9). Simulador (`herramientas/simular_equipo.py`, el resbalón es el modelo por
    defecto; `--sin-resbalon` = regla anterior), **sin cambiar ningún `pasos_rival`**: batalla Parejas
    91 %, Formas 100 %, Río 86 %; "los tres" por zona z1 82 %, z2 86 %, z3 85 %, z4 96 %, z5 96 %;
  - **Río**: `disenador-mecanicas` decide que **también corresponde** cuando el turno hizo retroceder al
    rival por la racha de 3, con un parámetro nuevo `resbalon_tras_racha` (solo `true` en
    `rio_equipo.json` de la batalla). Queda sujeto a que `disenador-niveles` lo simule (§5.2);
  - **N9**: la meta del turno se ve en la **guirnalda de lucecitas**, pegada al lado izquierdo del
    marco del tablero; reemplaza a los "nuditos de la cresta de Coco", que no tenían lugar en el
    layout de equipo (§4.1, §5.2, §11.4, §14.15);
  - **N12**: aceptada por escrito la fila inferior de 4×6 a 10 px de la barra, con dos condiciones de
    hitbox; y corrección de la medida real de las cartas (107,5 px con la separación de 14 px → 10 px
    de separación en equipo con 4 filas, 110,5 px) (§4.1, §5.3);
  - **N13**: tocar una carta durante la fiesta del turno perfecto suma "¡guárdala para tu próximo
    turno!" de Coco, una vez por partida (§4.3, §8);
  - **N8**: la intro de las rondas con tope **debe explicar el tope por voz** (§5.2, §14.11). El texto es
    del `guionista` (HE-67), que ya trabaja N8, N11 y N13. Se suma la presentación única del turno
    perfecto por familia (`turno_perfecto_presenta`, §5.2, §8, §11.5);
  - de arrastre: riesgos 6, 7 y 9 actualizados y 13-15 nuevos (§9); tareas y QA por rol (§10, §14.9);
    `GestorTurnos` con `rival_resbalo()`, `turno_cerrado(id, perfecto)`, `resbalon_tras_racha` y
    `ancla_meta_turno()` (§11.1, §11.4); estado de decisiones (§14.14) y "Para Dev" (§14.15);
  - voz opcional del rival al resbalarse, `rival_resbala` (guion de la batalla, nota 10 del §10):
    suena después de "¡le toca a…!" y solo con la cola libre en ≤ 1 s, con la puerta cerrada y sin
    `guardala_proximo_turno` en ese pase. Reemplaza el "sin voz del rival" de la primera redacción
    (§4.3, §8, §11.4, riesgo 14).
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

> **Decisión del PO (06-Oct-2026, posterior)**: el modo equipo **debuta como la Batalla final de
> Arcoíris** (§14). El botón "¡Juntos!" **no está disponible desde el inicio**:
>
> - **aparece como premio al ganar la batalla**, y desde ahí permite repetir en equipo cualquier zona
>   de Arcoíris;
> - antes de la batalla, la selección es exactamente la de hoy;
> - la "presentación única" (M5.2) ocurre **al volver a la selección después de ganar la batalla**;
> - la selección lo muestra si `Progreso.modo_equipo_desbloqueado()` (§14.9).

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
- **Presentación única** (M5.2): la primera vez que la selección se abre con el modo disponible (o sea,
  después de ganar la batalla), la nave
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
| Pista del rival | `Rect2(0, 0, 1280, 100)` | **Cometa a la izquierda**, tocable con hitbox `Rect2(8, 4, 110, 96)`: repite la regla y de quién es el turno (M4 de HE-58; **unificado con Cometa** según M6 de HE-66 y GDD §6.2, también fuera de la batalla). Después, las galletas (x 130-930) con el Coleccionauta y su mochila-torre en la espalda, y la mesa del equipo con la **cinta arcoíris** (x 940-1150, no tocable) |
| Botón casa | `Rect2(1172, 8, 100, 96)` (≥ 96 px) | Salir al mapa en modo equipo. Salir no pierde nada (m3) |
| Tablero | **`Rect2(40, 128, 1200, 472)`** | Las cartas. Empieza en y 128 para dejar **≥ 24 px** bajo Cometa y la casa (m5 de HE-66, residuo de HE-58) |
| **Meta del turno** (guirnalda de lucecitas) **[v6.1, UX N9]** | Columna de 64 px de ancho, **pegada 16 px a la izquierda de la mesa de cartas** y centrada en su alto (detalle abajo) | 2 o 3 lucecitas, solo en los turnos con tope de Nicole y de Sofía. No es tocable |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` | La nave de juguete de perfil con los retratos en sus ventanitas, en el orden de los turnos |

**La guirnalda de lucecitas: la meta del turno (v6.1, UX N9)** [Propuesta sobre la de UX]:

- **Qué es**: una regleta vertical con esquinas redondas, **del mismo color del marco** (el de quien
  juega, m1), como si fuera una pestaña del marco del tablero. Lleva tantas **lucecitas redondas de
  48 px** (≥ 32 px) como el tope del perfil que juega: **2 para Nicole y 3 para Sofía**, separadas
  16 px.
  - Medidas: con 3 lucecitas, 64 × 208 px; con 2, 64 × 144 px.
  - **Se llenan de abajo hacia arriba**, como un termómetro: "subir" se lee como avanzar.
- **Dónde**: 16 px a la izquierda de la **mesa** de cartas (el fondo que el motor dibuja 22 px
  alrededor de la grilla) y centrada en el alto del tablero (y ≈ 364). La posición sale del motor
  (`ancla_meta_turno()`, §11.4), porque el ancho de la grilla cambia con la composición:
  - 4×6 (la batalla y "los tres"): mesa en x ≈ 260-1020, guirnalda en x ≈ 180-244;
  - 3×6 (el caso más angosto, maxi+nicole en la zona 4): mesa en x ≈ 139-1141, guirnalda en
    x ≈ 59-123. Sigue dentro de la pantalla y a ≥ 38 px de la carta más cercana;
  - nunca queda a menos de 40 px del borde izquierdo de la pantalla; si no cabe, el gestor la pega al
    borde de x 40 (no pasa con ninguna composición vigente).
- **Por qué al costado y no arriba, como proponía UX**:
  - arriba no hay lugar: entre la pista (termina en y 100) y la primera fila de cartas (y 128) hay
    28 px, y una lucecita de ≥ 32 px taparía la fila 1 o se metería en la pista;
  - pegada a la pista, se leería como **parte del camino de galletas del rival**, que es justo lo
    contrario de lo que significa;
  - el costado izquierdo está libre en todas las composiciones (la grilla la define el alto, no el
    ancho) y es donde estaba Coco en solitario: los niños ya miran ahí para ver la racha.
  - Cumple los puntos 2 a 5 de UX: no va bajo los retratos (R2), la última respira, no se ve en el
    turno de Maxi, y sirve igual en Formas.
- **Cuándo se ve**:
  - **solo en los turnos de Nicole y de Sofía que tienen tope** (`aciertos_max_turno` con clave para su
    perfil). **Nunca en el turno de Maxi** (su turno es guiado: sin meta y sin presión), ni en las
    composiciones sin tope (`maxi+sofia`, `nicole+sofia`), ni en el Río (se mide en gotas, que ya se ven
    en la mano de Coco);
  - **aparece** en el paso 4 del pase, cuando el tablero se aclara: sale del marco con un pop blandito
    (0,3 s, *squash* 1,15 → 1,0) y las lucecitas apagadas;
  - **se retira** dentro del marco en el paso 2 del pase siguiente (0,2 s). No se guarda nada.
- **Apagadas**: bombillitas de vidrio blanco translúcido con un brillo suave, **nunca negras, grises ni
  con candado**. Se ven como "por prender", no como "vacías".
- **Con cada acierto** (par formado o pieza encajada): se enciende la siguiente, de abajo hacia arriba,
  **en los colores del arcoíris en orden** (rojo, amarillo, azul), **nunca del color de quien juega**.
  - Responde en **menos de 100 ms desde el acierto** (cuando se forma el par, no cuando vuela a la
    cinta), con un pop 1,0 → 1,3 → 1,0 (0,25 s), 4-6 chispitas y un "tin" que **sube un semitono** por
    lucecita (es el mismo sonido de racha en equipo, M1, ahora con algo que mirar).
- **Con una menos que el tope** (Nicole con 1 encendida, Sofía con 2): **la última lucecita respira**
  (escala 1,0 ↔ 1,12 y brillo, ciclo de 1,2 s), sin sonido ni voz. Dice "¡una más y es perfecto!" sin
  palabras.
- **Al llegar al tope**: se enciende la última, la guirnalda entera destella en arcoíris 2 veces
  (0,5 s) y **suelta una chispa que vuela hasta los pies del Coleccionauta** (0,4 s), justo cuando
  tropieza en el paso 0b (§4.3). Así se ve la causa: "prendí mis luces y lo hice resbalar".
- **Si el turno termina con fallo**: en el paso 1 las lucecitas encendidas **se apagan despacito**
  (0,3 s, *fade*), sin sonido, sin rojo y sin "apagón". El primer fallo de Nicole (el besito) **no
  cambia nada** en la guirnalda (B2).
- **Si el acierto del tope es el último del tablero**: la guirnalda destella y manda la victoria (sin
  chispa al rival).
- **No es tocable**: un toque encima solo hace titilar las lucecitas encendidas (0,2 s, sin sonido),
  para que nada quede "muerto" pero sin volverla un juguete. No se cuenta como toque fuera de halo ni
  reinicia nada del turno.

**La fila inferior de 4×6 y la barra (v6.1, UX N12): aceptada como excepción** [Propuesta]:

- Con 4 filas, la última fila de cartas termina en y 600 y la barra empieza en y 610: **10 px**, contra
  los 24 px que pide la regla. **Se acepta como excepción explícita** a los 24 px hacia la barra,
  porque el error en la dirección probable es inocuo:
  - tocar una ventanita de porra por error solo hace aplaudir a ese hermano: **no cambia el tablero**
    (§4.1);
  - el retrato de quien juega no es tocable, así que quien juega nunca "pierde" un toque por esa vía;
  - achicar el tablero a y 128-586 deja las cartas en ≈ 104 px, bajo la regla de ≥ 110 px con Maxi
    (§5.3), y él es quien más necesita la carta grande.
- **Dos condiciones para Dev** (cuidan la dirección que **no** es inocua: un hermano que mira, apunta a
  su ventanita y da vuelta una carta del turno de otro):
  1. el área tocable de las cartas de la fila inferior **no pasa de y 604** (si el motor agranda las
     hitbox respecto del dibujo, en equipo se recorta por abajo);
  2. el área tocable de las ventanitas **empieza en y ≥ 614** (≥ 96 px de alto, hasta y 710 o más).
  
  Entre y 604 y y 614 queda una franja muerta de 10 px: un toque ahí no hace nada.
- **La mesa** (el fondo que el motor dibuja 22 px alrededor de la grilla) llega hasta y 622 con 4 filas:
  en equipo **se dibuja bajo la barra** (la barra va encima), para que la nave de juguete no se vea
  tapada.
- **Corrección de la medida real de las cartas (v6.1)**: con la `SEPARACION` de 14 px del motor, 4 filas
  en 472 px dan **107,5 px** por carta, no los ≈ 110 de la v6. Para cumplir la regla de ≥ 110 px con
  Maxi (§5.3), **en equipo y con 4 filas la separación es de 10 px**, y las cartas miden **110,5 px**.
  El hueco de 10 px no molesta: un toque entre dos cartas cae en una de las dos, y cualquiera responde.

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
| 0b | **Solo si Nicole o Sofía terminaron en "turno perfecto"** (llegaron a su tope, §5.2) **[PO, 07-Oct-2026]**: la guirnalda destella y suelta su chispa (§4.1), Cometa dice "¡turno perfecto!" (la primera vez por familia, `turno_perfecto_presenta`, §5.2), el hermano hace su gesto corto y la barra aplaude. Enseguida el Coleccionauta **tropieza y retrocede una galleta** ("¡me resbalé para atrás!", `rival_retrocede`): trastabilla hacia atrás braceando y **termina de pie**, para que la caída sentado quede para el paso 2. Si ya estaba en la galleta 0, trastabilla en su lugar, sin voz. **Una carta tocada aquí**: pulso y, una vez por partida, "¡guárdala para tu próximo turno!" (N13, abajo) | 2,5-3,5 s | Pulso (y N13) |
| 1 | **Solo si terminó con "no es este"**: las dos cartas quedan a la vista `ms_volteo_equipo` (1500 ms), **para que todo el equipo las vea y se acuerde**, y se tapan en cascada | 1,5 s | Las cartas solo hacen el pulso |
| 2 | El retrato de quien sigue **vuela de la barra al centro**, grande (≈ 260 px), sobre el tablero oscurecido al 40 %. Suena un "fiuu" y la voz "¡Le toca a Nicole!". **En este mismo momento, si corresponde, el Coleccionauta salta una galleta (B3)**: la nave gira y "pasa el tiempo". **[PO, 07-Oct-2026, UX N10] Si el turno que terminó fue perfecto, en vez del salto viene el resbalón: intenta saltar, se resbala y queda sentado en la misma galleta (no avanza)**; detalle abajo | 0,6 s (el resbalón dura 1,1 s y termina durante la puerta) | Las cartas solo hacen el pulso |
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

- Salta solo si el turno que terminó fue de Nicole o de Sofía (`maxi_mueve_rival: false`) **y no fue
  un turno perfecto** (abajo).
- El salto ocurre **mientras el retrato del siguiente vuela al centro**, nunca al final del turno
  anterior.
- Si ese salto lo hace llegar, la derrota-gag (§5.5) empieza **cuando el retrato del siguiente ya está en
  el centro**, sin abrir la puerta. Así perder "le pasa a todos".

**Después de un turno perfecto: "se resbala y no avanza" [PO, 07-Oct-2026, UX N10]**

> Reemplaza la regla de la v6 ("el salto del paso 2 ocurre igual"). Con esa regla, la última imagen del
> pase era el rival avanzando, y a los 5 años manda lo último que se vio: "lo hicimos resbalar… y avanzó
> igual". Ahora la última imagen es una victoria, y "lo hace retroceder" es literal.

- **Regla**: en el pase que sigue a un turno perfecto (paso 0b), el Coleccionauta **intenta saltar en el
  paso 2, se resbala y se queda en su galleta**. Ese pase **no avanza**. El efecto neto del turno
  perfecto es **−1 galleta** (o 0 si ya estaba en la galleta 0).
- **Nunca hay derrota después de un turno perfecto**: como el pase no avanza, `rival_llego` no puede
  ocurrir ahí.
- **Animación del resbalón** (`pista_rival`, pose nueva `resbalar`; arranca junto con el vuelo del
  retrato y dura **1,1 s**, terminando ya con la puerta abierta a la espera):
  1. **Impulso** (0-0,15 s): se agacha para saltar (*squash* 0,85 en alto) y mira la galleta siguiente
     con cara de "¡ahora sí!".
  2. **Saltito corto** (0,15-0,35 s): se eleva apenas, como un tercio del salto normal.
  3. **Patina** (0,35-0,7 s): cae sobre el glaseado de **su misma galleta**, los pies giran en el aire
     como ruedita (estilo dibujo animado) y las gafas-lupa se le resbalan a la punta de la nariz.
  4. **Plof** (0,7-0,9 s): cae sentado en su galleta, *squash* 1,2 a lo ancho, y la mochila-torre rebota
     dos veces.
  5. **Sentado** (0,9-1,1 s): tres estrellitas le giran sobre la cabeza y pone **cara de risa
     avergonzada** ("je"), nunca de dolor ni de llanto.
  
  **Se queda sentado** mientras dura la puerta. En el paso 4, cuando empieza el turno, se para, se
  sacude y se acomoda las gafas (0,4 s, sin sonido). Nadie mira la pista en ese momento: lo que queda
  en la memoria es el "plof".
- **Sonido**: un silbato de resbalón descendente "fiuuu" (0,4 s), un "plof" de cojín (blando, sin
  golpe) y un "tilín" de las estrellitas. Va en el bus de SFX, **bajo la voz "¡Le toca a…!"** (que suena
  en ese mismo instante), con *ducking* de −6 dB.
- **Voz opcional del rival al resbalarse (`rival_resbala`, guion de la batalla, nota 10 del §10)**:
  «¡Uuuy! ¡Galleta resbalosa!» o «¡Ups!... Me senté. Je, je.» (≤ 1,5 s). Nunca pisa el "¡le toca a…!":
  - suena **después** de "¡le toca a…!" (o de `sube_ventanita`, si la puerta es de arrastre), con el
    rival ya sentado;
  - **solo si la cola de voces queda libre dentro de 1 s** después de esa voz; si no, se omite;
  - **también se omite si la puerta ya se abrió** (el turno empezó y nadie mira la pista) y si en ese
    pase sonó `guardala_proximo_turno` (N13), para no apilar tres voces en un pase;
  - nunca reemplaza a `rival_retrocede` del 0b, que sigue siendo la voz del retroceso.
  
  Por qué entra: después del "le toca" queda un silencio mientras el hermano abre la puerta, y la
  risa del rival sentado remata el gag sin competir con el nombre de quien juega. Riesgo 14 del §9.
- **Se distingue del tropiezo del 0b**: en el 0b trastabilla **hacia atrás** y queda de pie; en el
  paso 2 patina **en su lugar** y queda sentado. Dos gags distintos, en el orden en que más risa dan.
- **En la galleta 0**: en el 0b solo trastabilla (sin retroceder) y en el paso 2 se resbala igual. El
  neto es 0, y se ve igual de bien.
- **En el Río también hay resbalón** cuando el turno hizo retroceder al rival por la racha de 3, con el
  parámetro `resbalon_tras_racha` (decisión y motivos en el §5.2, "En el Río rige la racha de 3").
- **Turno de Maxi**: no cambia nada (no mueve al rival; se queda embobado).

**Toque de una carta durante la fiesta del turno perfecto (v6.1, UX N13)** [Propuesta]:

- Durante el paso 0b, el hermano que llegó al tope todavía tiene la tablet. Si toca una carta tapada
  (el "¡yo sabía otra!"):
  - **la carta responde en menos de 100 ms con el pulso** y un **guiño**: se inclina 6° hacia el dedo y
    le sale una chispita, como diciendo "aquí estoy". No se da vuelta (B1.4);
  - **la primera vez en la partida**, Coco dice "¡guárdala para tu próximo turno!" (clave
    `guardala_proximo_turno`; el texto final es del `guionista`). Convierte el reclamo en un plan: la
    memoria sigue sirviendo después;
  - las veces siguientes, solo el pulso y el guiño.
- **Orden de las voces**: la línea de Coco espera a que termine "¡turno perfecto!" de Cometa y, si
  suena, **reemplaza esa vez a `rival_retrocede`** (el rival igual hace su animación). Las voces nunca
  se pisan (§8), y el paso 2 empieza cuando el bus de voz queda libre (espera de 1,5 s como máximo).
- **Solo en Parejas**: lo hace el motor `emparejar` (es contenido del juego de memoria), escuchando
  `turno_cerrado(id, perfecto)` del gestor (§11.4). En Formas no hay nada escondido que "guardar".
- **"Una vez por partida"** se lleva en memoria del motor (no se guarda en disco): una partida de
  Parejas en equipo, o la ronda 3 de la batalla, incluido su reintento.

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
| Pares por turno **[PO, 07-Oct-2026]** | `pares_turno_semilla` (**1**), y después viene el ritual de fin de turno (§4.3, paso 0) | **Tope 2** con "los tres" y con maxi+nicole (y en la batalla). Sin tope con nicole+sofia | **Tope 3** con "los tres" (y en la batalla). Sin tope con maxi+sofia y nicole+sofia |
| "No es este" | **No existe** para Maxi | **Segunda oportunidad**: el primer "no es este" del turno **no** lo termina. Se comunica **solo** con la voz de Coco ("¡uy, otra!") y un gesto de Coco (guiño y besito soplado). **Nada queda en pantalla para contar** (B2). El segundo fallo pasa el turno | Pasa el turno en el acto |
| Ayuda extra | — | Si pasa **2 turnos seguidos sin par**, al empezar el siguiente, una carta de una pareja **ya vista** brilla tenue | Ninguna |
| Su truco (M2) | "Cartas que brillan" | "El besito de Coco" (la segunda oportunidad) | **"Juega como en la mesa de verdad, como los grandes"**: su regla sin ayudas se presenta como un rango, no como una desventaja. El retroceso (por turno perfecto o por racha de 3) **no es su truco**: es **del equipo**, porque Nicole también puede lograrlo (equidad) |
| ¿Mueve al rival? | **No**. El Coleccionauta **se queda embobado mirándolo** y aplaude su fiesta | Sí, un salto durante el pase siguiente. **Tras un turno perfecto, no**: retrocede en el 0b y en el pase se resbala (v6.1) | Sí, un salto durante el pase siguiente. **Tras un turno perfecto, no**: retrocede en el 0b y en el pase se resbala (v6.1) |

**Racha en equipo (M1)**:

- **En equipo no existe el bloque `puntaje`**: ni número de racha, ni "+puntos", ni "¡a la primera!", ni
  vela, ni récord individual. Si el nivel de equipo trae `puntaje`, el motor lo ignora.
- La racha suena igual que en Semilla (`"solo_sonido"`): el tono sube un semitono por par seguido,
  siempre en **arcoíris**, nunca del color de quien juega. **[v6.1, UX N9]** En los turnos con tope, ese
  mismo "tin" enciende la **guirnalda de lucecitas** (§4.1). En los turnos sin tope (`maxi+sofia`,
  `nicole+sofia`) no hay guirnalda: la racha es solo sonido, como en Semilla. Ya no se usan los
  "nuditos de la cresta de Coco": en el layout de equipo Coco no tiene lugar fijo (el tablero ocupa
  todo el ancho).

**Tope de pares por turno [PO, 07-Oct-2026]** (`composiciones.<clave>.pares_max_turno`,
`{"semilla": 1, "brote": 2, "estrella": 3}`):

- **Dónde rige**: en la batalla y en las composiciones `maxi+nicole+sofia` y `maxi+nicole` de todas las
  zonas. **No rige** en `maxi+sofia` ni en `nicole+sofia` (la composición no trae el campo).
- **Al formar el par que llega al tope, el turno termina en celebración** ("¡turno perfecto!", §4.3
  paso 0b), **nunca como fallo**: las cartas quedan como están y nadie oye "se acabó tu turno". Es la
  misma forma y la misma voz que en Formas (§14.3): una sola regla de tope para todas las rondas.
- **Qué cuenta para el tope**: cada pareja formada, incluidas la pareja lupa y el comodín (vale un par).
- **Si el par del tope es el último del tablero**, gana el equipo: manda la victoria, sin "¡turno
  perfecto!" ni retroceso.
- **Se ve sin números** (R2) **[v6.1, UX N9]**: en los turnos con tope, la **guirnalda de lucecitas**
  pegada al marco del tablero (§4.1) muestra **tantas lucecitas apagadas como el tope** (2 para Nicole,
  3 para Sofía), que se encienden en arcoíris con cada par. Con una menos que el tope, la última
  respira. Al encenderse la última, es el turno perfecto. Se apagan en cada pase y no se guardan. En el
  turno de Maxi no se ve.
- **Se explica por voz** **[v6.1, UX N8]** (GDD §6.2: toda regla se dice). Con el tope, la regla "si hay
  pareja, sigues jugando" **ya no es verdad a secas**, así que ninguna voz de una partida con tope puede
  decirla sin la meta:
  1. **la intro de cada ronda con tope** (Formas y Parejas de la batalla) y la **intro de Parejas en
     equipo** con tope (el cierre `intro_equipo_trucos.equipo` en la primera partida, y `intro_equipo`
     en las siguientes) **nombran la meta**, sin números y apuntando a la guirnalda: "sigues… ¡hasta
     prender tus luces!". Se mantienen en ≤ 4 s (N7 de UX);
  2. la **`repetir` de Cometa** (tocar a Cometa) en esas rondas suma la meta: "…y si prendes todas tus
     lucecitas, ¡turno perfecto!";
  3. **presentación única del turno perfecto, por familia**: el **primer** turno perfecto que la
     familia logra suena con una variante de Cometa que dice qué pasó ("¡Turno perfecto! ¡Prendiste
     todas tus luces y el Coleccionauta se resbaló!", clave `turno_perfecto_presenta`). Se marca con
     `Progreso.marcar_cinematica_vista("nucleo:turno_perfecto")` (§11.5; el prefijo `nucleo:` dice que
     no es de una batalla concreta) y, desde ahí, suenan las variantes cortas de `turno_perfecto`. Lo
     hace el `GestorTurnos` en el paso 0b; si falta la clave, usa `turno_perfecto`.
  
  Los textos son del `guionista` (HE-67). Las composiciones **sin** tope conservan "si hay pareja,
  sigues jugando".
- **Motivo (simulador)**: sin tope, Sofía vaciaba el tablero y jugaba un solo turno en el 68 % de las
  partidas; con el tope, cada hermano juega al menos 2 turnos en el 97-100 %. Ver
  `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md` §9.

**Un buen turno hace retroceder al rival [PO, 07-Oct-2026: reemplaza la racha de 3 donde hay tope]**:

- **Con tope (turno perfecto)**: el Coleccionauta **retrocede una galleta cuando Nicole o Sofía llegan
  a su tope sin que un fallo termine su turno** (Nicole 2 pares, Sofía 3). Ocurre en el paso 0b del
  pase (§4.3), con "¡turno perfecto!" de Cometa.
  - **Maxi nunca**: su turno ya es un acierto seguro (R5) y no mueve al rival en ningún sentido.
  - **El besito de Coco no rompe el turno perfecto**: si Nicole usa su segunda oportunidad y después
    forma sus 2 pares, es turno perfecto. Motivos: B2 exige que ese primer fallo no deje rastro (contarlo
    sería un marcador de fallos escondido), y así lo calibró el simulador (`--perfecto` cuenta los
    aciertos del turno, no los fallos). **[PO, 07-Oct-2026: confirmado. "Sin fallar" se lee como "sin que un fallo termine el
    turno"; vale igual en Formas.]**
  - **Una vez por turno**, porque el turno termina al llegar al tope. Nunca retrocede antes de la
    galleta 0.
  - **[PO, 07-Oct-2026, UX N10] Y en ese pase no avanza**: en el paso 2 el Coleccionauta intenta
    saltar, **se resbala y se queda sentado** en su galleta (§4.3, "se resbala y no avanza"). El efecto
    neto del turno perfecto es **−1 galleta** (0 si ya estaba en la galleta 0), y la última imagen del
    pase es el rival en el suelo: "lo hace retroceder" se ve literal. Simulador, sin cambiar ningún
    `pasos_rival`: batalla Parejas 91 % y Formas 100 %; "los tres" por zona 82 / 86 / 85 / 96 / 96 %
    (z1 a z5). Todo sigue en la meta de ~8 de cada 10 o por encima; si el playtest muestra que "los
    tres" de las zonas 4 y 5 se ganan sin tensión, `disenador-niveles` puede subir ahí `pasos_rival`
    (decisión del PO).
  - **Motivo**: con tope 2, Nicole nunca llegaba a una racha de 3 y solo Sofía podía frenar al rival. Con
    el turno perfecto, las dos pueden, cada una con su meta (equidad del §5.2).
- **Sin tope** (`maxi+sofia` y `nicole+sofia`): sigue la **racha de 3** (`racha_retrocede_rival: 3`):
  - al formar 3 pares seguidos en un mismo turno, el Coleccionauta tropieza y retrocede una galleta, y
    lo celebra todo el equipo; con 6 seguidos, otra, y así cada 3;
  - el comodín cuenta como un par de la racha;
  - en `nicole+sofia` las dos llegan a 3 (equidad intacta); en `maxi+sofia`, Maxi forma 1 par por
    turno y el retroceso queda en manos de Sofía, que es la única que puede jugar sin ayuda (no hay a
    quién comparar).
- **Regla para el gestor (genérica)**: si `aciertos_max_turno` trae clave para el perfil de quien juega
  y ese perfil no es `semilla`, el retroceso es por turno perfecto y `racha_retrocede_rival` **se
  ignora** en ese turno; si no trae clave, rige la racha. Así los datos que ya traen
  `racha_retrocede_rival: 3` funcionan sin cambios (§11.4).
- **Maxi (semilla) nunca mueve al rival, tampoco por racha**: con `maxi_mueve_rival: false`, el gestor
  no cuenta racha en los turnos semilla. Importa en el Río, donde el reventón de Maxi puede desatar una
  cadena que valga 3 aciertos (§14.3).

**En el Río rige la racha de 3, no el turno perfecto [decisión de `disenador-mecanicas` dentro del
marco del PO, 07-Oct-2026]**:

- **Por qué no hace falta el turno perfecto**: en el Río el turno no se corta por aciertos sino por
  gotas (`gotas_por_turno`: Nicole 3, Sofía 3) y **no existe el fallo** (B1). Nicole y Sofía tienen
  **la misma meta con los mismos medios**: 3 reventones con 3 gotas. La racha de 3 en el Río ya es, en
  la práctica, "el turno perfecto" del Río, y la equidad que el PO pidió para Formas y Parejas se
  cumple sin cambiar nada. El problema que motivó el cambio (con tope 2, Nicole nunca llegaba a 3) no
  existe aquí.
- **Por qué no conviene un tope**: cortar el turno del Río al tercer reventón dejaría gotas sin tirar y
  rompería la cuenta de gotas por turno que los niños ven en la mano de Coco. Además, con 20 gotas y 7
  pasos el simulador ya da **86 % de victorias al primer intento** con la racha.
- **Cómo funciona**: el retroceso ocurre **en el momento** del tercer acierto del turno, no en el pase;
  una cadena vale 2 (`cadena_vale_aciertos: 2`), así que con una cadena el retroceso puede llegar con 2
  gotas, y con 6 aciertos en un turno retrocede dos veces. Suena `rival_retrocede` y la barra aplaude;
  **no suena "¡turno perfecto!"**, porque el turno sigue hasta gastar la última gota.
- **En los datos**: `rio_equipo.json` no trae `aciertos_max_turno` y sí `racha_retrocede_rival: 3`, así
  que la regla genérica del gestor (punto anterior) ya produce este comportamiento sin código especial.
- **El resbalón también corresponde en el Río [v6.1, decisión de `disenador-mecanicas` dentro de la
  decisión del PO sobre UX N10]**: si en el turno el rival retrocedió al menos una vez por la racha de
  3, en el pase siguiente **intenta saltar y se resbala** (la misma animación del §4.3), sin avanzar.
  - **Por qué sí**: el problema de recencia de N10 es **igual o peor** en el Río. El retroceso ocurre
    en el momento, pero el turno de Nicole o Sofía termina enseguida (con 3 gotas, el tercer reventón
    suele ser la última gota, o la penúltima si hubo cadena), y la última imagen sería el rival
    saltando hacia adelante en el pase: "lo hicimos tropezar… y avanzó igual". Además, con el resbalón
    la regla visible queda **una sola en toda la batalla**: "si lo haces retroceder, en el pase se
    resbala". Eso achica el riesgo 9 del §9 (dos reglas de retroceso): cambia la meta (3 reventones o
    las lucecitas), pero no lo que se ve.
  - **Por qué con parámetro y no por defecto**: la regla del PO nombra el turno perfecto; extenderla a
    la racha es mía, el simulador todavía **no** la modela en el Río (las cifras de arriba, 86 %,
    son con la regla anterior en esa ronda), y Parejas en equipo sin tope (`maxi+sofia`,
    `nicole+sofia`) ya está calibrado con la racha y sin resbalón. Por eso es un campo del bloque
    `equipo`: **`resbalon_tras_racha: bool`** (por defecto `false`).
    - **Batalla, Río**: `true` en `batalla/rio_equipo.json`. Lo agrega `disenador-niveles` después de
      simularlo; solo puede **subir** el 86 % (el pase deja de avanzar en algunos turnos), así que no
      pone en riesgo la meta del 85 %. Si con el resbalón el Río pasa del 95 %, `disenador-niveles`
      propone al PO bajar `pasos_rival` (deja menos margen al equipo) o sumar gotas (más gotas = ronda más larga y más difícil).
    - **Parejas sin tope** (`maxi+sofia`, `nicole+sofia`): queda en `false` hasta el playtest, porque
      esas composiciones ya están en la meta (≈ 75-80 %) y con el resbalón quedarían más fáciles.
  - **Una sola vez por pase**: con 6 aciertos el rival retrocede dos veces en el turno, pero en el
    pase se resbala una sola vez (no avanza, y nada más).
  - **Turno de Maxi**: su reventón nunca cuenta para la racha (`maxi_mueve_rival: false`), así que
    nunca produce resbalón.

**Cartas especiales en equipo** (motor §10.3):

| Carta | En equipo |
|---|---|
| Lupa | Sí. Se celebra como del equipo |
| Comodín arcoíris | Solo si Nicole está en el equipo. Lo juegan Nicole y Sofía; en el turno de Maxi está inerte (M10) |
| Carta dorada | **No** (puntos individuales, R2) |
| Carta del Coleccionauta | **No** (él ya es el rival) |

**Presentación del modo (M2)**: la primera partida en equipo de cada combinación de hermanos empieza con
Coco. La frase se arma con fragmentos, según quiénes juegan:

1. `intro_equipo_trucos_apertura`: "¡Cada uno juega con su propio truco!".
2. Un fragmento por cada hermano que juega:
   - Maxi: "Maxi tiene cartas que brillan";
   - Nicole: "Nicole tiene un besito mío: ¡una oportunidad extra!";
   - Sofía: "Sofía juega como en la mesa de verdad, ¡como los grandes!". Este fragmento hay que
     reescribirlo en el guion.
3. Cierre común, según la composición **[07-Oct-2026]**:
   - **con tope** (`intro_equipo_trucos.equipo`): la idea "quien termine su turno sin fallar, hace
     retroceder al Coleccionauta" (texto del `guionista`);
   - **sin tope** (`intro_equipo_trucos.equipo_racha`): "¡Y quien haga tres parejas seguidas, hace
     retroceder al Coleccionauta!".

   El motor elige el cierre según si la composición trae `pares_max_turno`.

**Equidad**: el retroceso no se atribuye a ningún hermano, porque lo puede lograr cualquiera de los
mayores. Las partidas siguientes usan la intro corta `intro_equipo`.

### 5.3 El rival: el Coleccionauta y la pista de galletas [PO: el Coleccionauta; Propuesta: forma]

- **El Coleccionauta es el de su canon** (`docs/guia-estilo-generacion.md` y la intro): **gafas-lupa y
  mochila-torre**. No lleva monóculo, ni "caja de colección", ni nave-aspiradora: **su mochila-torre es
  la que aspira y estornuda**. Corrección del `guionista`, 06-Oct-2026.
- **La pista**: a la izquierda está Cometa (tocable, M4 de HE-58 y M6 de HE-66). El Coleccionauta, a pie y con su mochila-torre
  a la espalda, parte en la **galleta 0**. Hay `pasos_rival` galletas hasta la mesa del
  equipo, a la derecha. Junto a la mesa, la **cinta arcoíris** se llena con cada par del equipo: es la
  meta compartida que se ve.
- **Cómo avanza**: salta una galleta en el paso 2 del pase (§4.3), después de un turno de Nicole o de
  Sofía, con un "boing" y una risa tonta ("¡jo, jo!").
  - Con cada par del equipo pone cara de "¡ay, no!" y se le resbalan las gafas-lupa.
  - **Su voz reacciona como máximo a 1 de cada 3 pares** (`rival_par`), y nunca encima de una línea de
    Coco. Las otras veces basta la cara.
  - Con un turno perfecto (o con la racha de 3 donde no hay tope), tropieza y retrocede (§5.2).
  - **[v6.1, PO, UX N10]** En el pase que sigue a un turno perfecto **no salta**: intenta saltar, se
    resbala y queda sentado con cara de risa avergonzada (§4.3). Con la racha del Río, igual si
    `resbalon_tras_racha` (§5.2).
  - **Nunca da miedo.**
- **El equipo gana** si forma todas las parejas antes de que llegue.
- **Calibración [actualizada 07-Oct-2026]**: meta de **~8 de cada 10 partidas ganadas** (≈ 75 % en
  `nicole+sofia`), medida con `herramientas/simular_equipo.py` (3.000 partidas por escenario):
  - memoria de ~3 cartas para Nicole y de ~5 para Sofía;
  - segunda oportunidad para Nicole;
  - Maxi intercalado, con 1 par nuevo por turno;
  - tope de pares y retroceso por turno perfecto donde rige; racha de 3 donde no;
  - **[v6.1]** el resbalón tras un turno perfecto (el pase no avanza), modelo por defecto del simulador
    (`--sin-resbalon` = regla anterior). Con él, "los tres" queda en z1 82 %, z2 86 %, z3 85 %, z4 96 %
    y z5 96 %, **con los mismos `pasos_rival`**;
  - vistazo de equipo.

  **Valores vigentes, ya fijados en los datos** (`datos/niveles/arcoiris/zona*/parejas_equipo.json`).
  El cálculo, las corridas y los porcentajes por escenario están en
  `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md` §5; esta tabla es un resumen y, si
  difieren, **mandan los datos**. Formato: pares, grilla y `pasos_rival`; "T" = con tope; "+C" = más el
  comodín.

| Zona | `maxi+nicole` (T 1/2) | `maxi+sofia` | `nicole+sofia` | `maxi+nicole+sofia` (T 1/2/3) |
|---|---|---|---|---|
| 1 | 6, 3×4, 7 | 8, 4×4, 5 | 10, 4×5, 8 | 12, 4×6, **5** |
| 2 | 8, 4×4, 7 | 10, 4×5, 6 | 12, 4×6, **11** | 12, 4×6, **5** |
| 3 | 8, 4×4, 7 | 10, 4×5, 6 | 12, 4×6, **11** | 12, 4×6, **5** |
| 4 | 8 + C, 3×6, 7 | 10, 4×5, 6 | 11 + C, 4×6, 8 | 11 + C, 4×6, **5** |
| 5 | 9 + C, 4×5, 7 | 10, 4×5, 5 | 11 + C, 4×6, 8 | 11 + C, 4×6, **5** |

- **[PO, 07-Oct-2026]** "Los tres": **5 pasos en todas las zonas** (se gana el 79-96 % sin resbalón;
  **82-96 % con el resbalón de la v6.1**).
- **[PO, 07-Oct-2026]** `nicole+sofia` en las zonas 2 y 3: **11 pasos** (76-77 %), para conservar los
  12 pares, que son el escalón de reto de memoria de las dos mayores.

- **Tamaño de tablero [PO, 07-Oct-2026: se levanta el límite de 4×5 con Maxi]**:
  - **Máximo para todas las composiciones: 4 filas × 6 columnas = 24 cartas.** En el tablero
    `Rect2(40, 128, 1200, 472)` **manda el alto**: con 4 filas, las cartas miden **≈ 110 px** con 5 o
    con 6 columnas (el ancho sobra). Con 3 filas son más grandes.
  - Con Maxi, la regla de **cartas ≥ 110 px se mantiene**: lo que la garantiza es el máximo de 4 filas,
    no el de columnas.
  - Una casilla que sobra (por ejemplo, 11 pares + comodín = 23 cartas en 4×6) lleva la gomita del
    tablero impar (m8 del §13).
- **Corrección [07-Oct-2026]**: la versión anterior de este párrafo pedía para la zona 5 "10 pares en
  4×5 con lupa y comodín", que **no cabe** (21 cartas en 20 casillas; lo encontró `disenador-niveles`).
  Quedó en **11 pares + comodín en 4×6** para los tres, como en la zona 4.
- **Contenido**: un mazo mixto con los gustos de los tres (dinos y vehículos de Maxi; jirafa, pony,
  gatito y ropa de Nicole; cachorros y ponys de Sofía), figuras del planeta y banderas (Chile con
  `fijo: true`). Va en estilo Semilla ("peluche pintado", grande). Lo arma `disenador-niveles`.

### 5.4 El vistazo al repartir en equipo [PO: acepta M6 de UX, 06-Oct-2026]

- Siempre en el formato de Brote: **parejas completas**, con **como máximo 3 pares (6 cartas)**, durante
  **3 s**, sea cual sea el tablero y el equipo.
- Regla general: ≈ 1 s por par mostrado, mínimo 2 s. **[07-Oct-2026]** Los datos usan 2 pares en las
  zonas 1-3 y 3 en las zonas 4-5 y en la batalla, siempre en 3 s: dentro del máximo, aceptado (2 pares
  en 3 s es más generoso que la regla general, y conviene en las zonas de entrada).
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
- El reto real sigue: **un buen turno hace retroceder al rival**. Desde el 07-Oct-2026 [PO], donde hay
  tope, "buen turno" es el **turno perfecto** (llegar al tope sin que un fallo lo termine: Nicole 2,
  Sofía 3); donde no hay tope, son 3 pares seguidos. Eso premia la memoria sin señalar a nadie, y cada
  una de las mayores tiene una meta a su alcance.
- **Lo último que se ve tiene que ser lo que pasó [v6.1, PO, UX N10]**: a los 5 años manda la última
  imagen. Si después de un turno perfecto el rival saltara hacia adelante en el pase, el niño se
  quedaría con "avanzó igual" aunque el neto fuera cero. Por eso, tras un turno perfecto, el pase
  termina con el Coleccionauta **resbalado y sentado en su galleta**: el buen turno se ve como lo que
  es, un freno de verdad.

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
    "racha_retrocede_rival": 3,         // M1; 0 = desactivado. Solo rige en turnos SIN tope (§5.2, 07-Oct-2026)
    "semilla_auto_s": 20,               // M2 de HE-66
    "vistazo": { "pares": 2, "ms": 3000 },  // M6, aceptado por el PO: máximo 3 pares, 3 s
    "composiciones": {                  // clave_equipo: ids en orden alfabético unidos por "+"
      // Valores de la zona 1 (datos vigentes, 07-Oct-2026). pares_max_turno [PO 07-Oct-2026]: tope de
      // pares por turno; presente = tope + retroceso por turno perfecto; ausente = sin tope + racha.
      "maxi+nicole":       { "filas": 3, "columnas": 4, "cantidad": 6,  "pasos_rival": 7,
                             "pares_max_turno": { "semilla": 1, "brote": 2 } },
      "maxi+sofia":        { "filas": 4, "columnas": 4, "cantidad": 8,  "pasos_rival": 5 },
      "nicole+sofia":      { "filas": 4, "columnas": 5, "cantidad": 10, "pasos_rival": 8 },
      "maxi+nicole+sofia": { "filas": 4, "columnas": 6, "cantidad": 12, "pasos_rival": 5,
                             "pares_max_turno": { "semilla": 1, "brote": 2, "estrella": 3 } }
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
    "intro_equipo_trucos_apertura": "voces/arcoiris/emparejar/equipo/intro_trucos.wav",  // M2: "¡Cada uno juega con su propio truco!"
    "intro_equipo_trucos": {            // un fragmento por hermano que juega, en el orden de los turnos
      "maxi": "voces/arcoiris/emparejar/equipo/intro_trucos_maxi.wav",
      "nicole": "voces/arcoiris/emparejar/equipo/intro_trucos_nicole.wav",
      "sofia": "voces/arcoiris/emparejar/equipo/intro_trucos_sofia.wav",  // EQUIDAD: hay que reescribirla (ver nota)
      "equipo": "PENDIENTE",            // cierre CON tope (07-Oct-2026): "quien termine su turno sin fallar, hace retroceder…"
      "equipo_racha": "PENDIENTE"       // cierre SIN tope: "¡y quien haga tres parejas seguidas, hace retroceder al Coleccionauta!"
    },
    "vistazo": "voces/arcoiris/emparejar/equipo/vistazo.wav",

    // Pase de turno (§2 del guion; capa genérica)
    "le_toca": {
      "maxi":   ["voces/nucleo/equipo/le_toca_maxi_01.wav",   "voces/nucleo/equipo/le_toca_maxi_02.wav",   "voces/nucleo/equipo/le_toca_maxi_03.wav"],
      "nicole": ["voces/nucleo/equipo/le_toca_nicole_01.wav", "voces/nucleo/equipo/le_toca_nicole_02.wav", "voces/nucleo/equipo/le_toca_nicole_03.wav"],
      "sofia":  ["voces/nucleo/equipo/le_toca_sofia_01.wav",  "voces/nucleo/equipo/le_toca_sofia_02.wav",  "voces/nucleo/equipo/le_toca_sofia_03.wav"]
    },
    "te_toca_recordatorio": {           // m5: como máximo 2 veces; puerta de TOQUE (texto ajustado a B1 en el guion v2)
      "maxi": "voces/nucleo/equipo/te_toca_maxi.wav",
      "nicole": "voces/nucleo/equipo/te_toca_nicole.wav",
      "sofia": "voces/nucleo/equipo/te_toca_sofia.wav"
    },
    "te_toca_recordatorio_ventanita": { // m5: como máximo 2 veces; puerta de ARRASTRE (tras un turno de Maxi). Sin "maxi": Maxi nunca sigue a Maxi
      "nicole": "voces/nucleo/equipo/te_toca_nicole_ventanita.wav",
      "sofia": "voces/nucleo/equipo/te_toca_sofia_ventanita.wav"
    },
    "maxi_ayuda": "voces/nucleo/equipo/maxi_ayuda.wav",
    "sube_ventanita": {                 // B1.2: reemplaza a le_toca cuando la puerta es de arrastre. Sin "maxi"
      "nicole": "voces/nucleo/equipo/sube_ventanita_nicole.wav",
      "sofia": "voces/nucleo/equipo/sube_ventanita_sofia.wav"
    },
    "porras_fin_maxi": "voces/arcoiris/emparejar/equipo/porras_fin_maxi.wav",  // M3.3

    // Turno guiado de Maxi (§3.2 del guion)
    "maxi_brillan": [
      "voces/arcoiris/emparejar/equipo/maxi_brillan_01.wav",
      "voces/arcoiris/emparejar/equipo/maxi_brillan_02.wav"
    ],
    "maxi_aqui": "voces/arcoiris/emparejar/equipo/maxi_aqui.wav",
    "maxi_par": "voces/arcoiris/emparejar/equipo/maxi_par.wav",
    "maxi_lupa": "voces/arcoiris/emparejar/equipo/maxi_lupa.wav",

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
    "animo_hermanos": {                 // B2: grabación opcional de los niños. Por cada "no es este", suena UNO solo:
                                        // un hermano al azar entre los que miran (nunca el que juega). Si no hay grabación, solo animación y SFX
      "maxi":   ["voces/nucleo/equipo/animo_maxi_01.wav",   "voces/nucleo/equipo/animo_maxi_02.wav"],
      "nicole": ["voces/nucleo/equipo/animo_nicole_01.wav", "voces/nucleo/equipo/animo_nicole_02.wav"],
      "sofia":  ["voces/nucleo/equipo/animo_sofia_01.wav",  "voces/nucleo/equipo/animo_sofia_02.wav"]
    },

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
    "rival_retrocede": [                // M1: turno perfecto (con tope) o racha de 3 (sin tope)
      "voces/nucleo/equipo/coleccionauta/retrocede_01.wav", "voces/nucleo/equipo/coleccionauta/retrocede_02.wav"
    ],
    "turno_perfecto": [                 // 07-Oct-2026: Cometa; la lee el GestorTurnos (paso 0b del §4.3)
      "voces/nucleo/equipo/turno_perfecto_01.wav", "voces/nucleo/equipo/turno_perfecto_02.wav"
    ],
    "turno_perfecto_presenta": "PENDIENTE",  // v6.1, UX N8: Cometa, SOLO el primer turno perfecto de la familia
                                        // (Progreso.cinematica_vista("nucleo:turno_perfecto")); dice qué pasó: luces + resbalón
    "rival_resbala": [                  // v6.1 (N10): Coleccionauta sentado tras el resbalón del paso 2. Opcional.
                                        // DESPUÉS de le_toca/sube_ventanita, solo si la cola queda libre en ≤ 1 s;
                                        // si no, si la puerta ya se abrió o si sonó guardala_proximo_turno: se omite (§4.3)
      "voces/nucleo/equipo/coleccionauta/resbala_01.wav", "voces/nucleo/equipo/coleccionauta/resbala_02.wav"
    ],
    "guardala_proximo_turno": "PENDIENTE",   // v6.1, UX N13: Coco; carta tocada durante el paso 0b, 1 vez por partida.
                                        // La lee el motor emparejar (§4.3). Texto del guionista
    "rival_retrocede_celebra": "voces/arcoiris/emparejar/equipo/retrocede_celebra.wav",  // Coco, justo después; sin nombre.
                                        // SOLO con la racha de 3 (sin tope). Con turno perfecto no suena: dos fiestas seguidas tapan el pase
    "rival_aplaude": [
      "voces/nucleo/equipo/coleccionauta/aplaude_01.wav", "voces/nucleo/equipo/coleccionauta/aplaude_02.wav"
    ],
    "rival_vuelve": "voces/nucleo/equipo/coleccionauta/vuelve.wav",

    // Derrota-gag (§4.3 del guion), secuencia en este orden. AL FINAL, después de coco_otra_vez, suena
    // pares_juntados[N], con N = parejas ya formadas, o nos_alcanzo si N = 0 (B3.3)
    "derrota_gag_equipo": [
      "voces/arcoiris/emparejar/equipo/coleccionauta_aspira.wav",
      "voces/arcoiris/emparejar/equipo/coleccionauta_estornuda.wav",
      "voces/arcoiris/emparejar/equipo/coleccionauta_cansado.wav",
      "voces/arcoiris/emparejar/equipo/coco_otra_vez.wav"
    ],
    "pares_juntados": {                 // Cometa, "¡igual juntamos N parejas!"
      "1": "voces/nucleo/equipo/pares_juntados_1.wav"
      // … "2" a "12": voces/nucleo/equipo/pares_juntados_<N>.wav
    },
    "nos_alcanzo": "voces/nucleo/equipo/nos_alcanzo.wav",  // si N = 0

    // Victoria (§5 del guion), secuencia
    "victoria_equipo": "voces/arcoiris/emparejar/equipo/coco_victoria.wav",
    "fiesta": {
      "al_frente": "voces/nucleo/equipo/al_frente.wav",
      "gesto": { "maxi": "voces/nucleo/equipo/fiesta_maxi.wav", "nicole": "voces/nucleo/equipo/fiesta_nicole.wav", "sofia": "voces/nucleo/equipo/fiesta_sofia.wav" },  // o las tres o ninguna
      "choca": "voces/nucleo/equipo/choca.wav",
      "equipo_estelar": "voces/nucleo/equipo/equipo_estelar.wav",
      "destellos": "voces/nucleo/equipo/destellos.wav",  // "¡Destellos para todos!": SOLO si TODOS los del equipo reciben; si no, solo tintineo
      "estrellita": "voces/nucleo/equipo/estrellita.wav"
    },
    "record_equipo": "voces/arcoiris/emparejar/equipo/record.wav",
    "primer_record_equipo": "voces/arcoiris/emparejar/equipo/primer_record.wav"  // m6
  }
}
```

**Voces de la selección y del mapa** (no van en el nivel, las leen directamente la selección y
`mapa_planeta.gd`):

- `nucleo_equipo_presenta` (presentación única, M5.2) y `nucleo_seleccion_invitacion_equipo` (invitación
  alternada, M5.3);
- `nucleo_equipo_juntos`, `nucleo_equipo_armar`, `nucleo_equipo_minimo_dos` y `nucleo_equipo_despegar`;
- **confirmaciones del puf con nombre (m2)**:
  - `nucleo_equipo_al_puf_<hermano>`, cuando el hermano sale del equipo;
  - `nucleo_equipo_sube_nave_<hermano>`, cuando vuelve;
  - si existe la grabación del niño, `nucleo_equipo_yo_tambien_<hermano>` suena después de
    `sube_nave`.
  
  Las líneas genéricas `al_puf_01/02` y `vuelve` de la v1 del guion **ya no se usan**.
- `arcoiris_mapa_equipo_llegada` y `arcoiris_mapa_equipo_estacion_pronto`.

**Reglas de mezcla de voces**:

- Las voces nunca se pisan: la voz de Coco tiene prioridad y la del rival se omite si Coco está
  hablando.
- **La voz del rival al formarse un par**: como máximo 1 de cada 3 pares.
- **En Maxi**, `maxi_par` reemplaza a `acierto_equipo`.

**Estado de las voces** (guion v2, §10): todas las claves tienen sus ids, salvo las marcadas
`"PENDIENTE"` (los dos cierres de la intro de trucos y, desde la v6.1, `turno_perfecto_presenta` y
`guardala_proximo_turno`). Si falta un archivo, el motor sigue sin voz y nunca falla.

- **Pendiente 1** (ampliado 07-Oct-2026): los dos cierres comunes, `intro_equipo_trucos.equipo` (con
  tope: "quien termine su turno sin fallar…", sin contar pares, para que sirva a Nicole y a Sofía) y
  `intro_equipo_trucos.equipo_racha` (sin tope: "¡y quien haga tres parejas seguidas…").
- **Pendiente 2**: reescribir `intro_equipo_trucos.sofia`. Hoy dice "Sofía, con tres parejas seguidas,
  ¡hace retroceder al Coleccionauta!", pero el retroceso es del equipo (ver la nota de equidad en §5.2).
- **Pendiente 3** (07-Oct-2026): `arcoiris_emparejar_equipo_retrocede_celebra` dice "¡Tres parejas
  seguidas!". Sigue sirviendo, pero **solo** con la racha de 3 (sin tope).
- `turno_perfecto` ya existe en el guion de la batalla (`nucleo_equipo_turno_perfecto_01/02`, Cometa).
- **Pendiente 4** (v6.1, UX N8): con tope, las intros (`intro_equipo`, el cierre
  `intro_equipo_trucos.equipo`) y la `repetir` de Cometa **nombran la meta** ("¡hasta prender tus
  luces!"), y `turno_perfecto_presenta` (§5.2). Ninguna línea de una partida con tope dice "si hay
  pareja, sigues jugando" a secas.
- **Pendiente 5** (v6.1, UX N13): `guardala_proximo_turno` (Coco, "¡guárdala para tu próximo turno!").
- **Resbalón** (v6.1, N10): SFX siempre, y la voz opcional `rival_resbala`
  (`nucleo_equipo_coleccionauta_resbala_01/02`, ya en el guion) con la regla de cola del §4.3.
- `te_toca` ya quedó corregido en la v2 del guion.
- El avance del rival suena durante el pase (B3).

**Reglas de lectura del contrato**:

- `clave_equipo` = los ids de `Progreso.equipo_activo` **ordenados alfabéticamente** y unidos con `+`.
  El orden alfabético coincide con el de edad.
- Si una composición no está en `composiciones`, el motor usa la de más pares que quepa, con aviso en
  consola. Nunca falla en silencio.
- Las parejas de cada partida se sortean del `pool` según `cantidad`, y las `fijo` siempre entran.
- `tiempo_volteo_ms` y `ms_volteo_equipo` deben valer lo mismo. Si difieren, manda `ms_volteo_equipo`.
- **Tope hacia el gestor [07-Oct-2026]**: el motor resuelve la composición y le pasa al `GestorTurnos`
  `config["aciertos_max_turno"]` = `pares_max_turno` de la composición, **siempre con
  `"semilla": pares_turno_semilla`** aunque la composición no traiga tope (así el turno de Maxi cierra
  siempre por el mismo camino, §11.4). Si `pares_max_turno.semilla` y `pares_turno_semilla` difieren,
  manda `pares_turno_semilla` (R5), con aviso en consola. El gestor solo conoce `aciertos_max_turno`: no
  sabe qué es un par.

---

## 9. Riesgos de usabilidad que siguen abiertos para el build (HE-64)

Lo que el diseño ya corrigió (B1-B3 y M1-M10) se verifica sobre el build real, con foco en:

1. **B1**: los manotazos de Maxi y si el arrastre a la ventanita les cuesta a Nicole y a Sofía.
2. **M3**: si Maxi se queda con la ventanita de porra o se va.
3. **B3 y R6**: si alguien igual dice "perdimos por tu culpa".
4. **Duración**: con los tres, la meta es de 4 a 6 min. Si pasa de 7 min, achicar los tableros.
5. **Sofía**: si "llevar" al equipo se le vuelve aburrido (si pasa, se activa la alternativa B).
6. **[07-Oct-2026] El tope corta a Sofía**: si al llegar a 3 dice "¡pero yo sabía otra!" con frustración
   en vez de orgullo. Mirar si la guirnalda con 3 lucecitas (v6.1, §4.1) se lee como meta ("¡lo
   completé!") y no como límite, y si la intro y la `repetir` con la meta (N8, §5.2) llegan a
   escucharse. Respaldo ya diseñado: si toca una carta en la fiesta, Coco le dice "¡guárdala para tu
   próximo turno!" (N13, §4.3); la memoria sigue sirviendo.
7. **[Cerrado en la v6.1, PO, UX N10] Turno perfecto con efecto neto cero**: la v6 dejaba que el rival
   retrocediera en la fiesta y avanzara en el pase. Ahora, en ese pase, **se resbala y no avanza**
   (§4.3). Lo que se mira en el playtest es lo contrario: qué dicen cuando se resbala ("¡lo frenamos!"
   o "¡avanzó igual!") y si el "plof" les da risa. Si alguien igual dice "avanzó", el problema es de
   animación (que no se lea el saltito como avance), no de regla.
8. **[07-Oct-2026] 4×6 con Maxi (24 cartas)**: las cartas siguen midiendo ≈ 110 px, pero el tablero se
   ve más lleno. Mirar si Maxi encuentra las dos cartas del halo en menos de 6 s (antes de que se
   queden a la vista) y si toca cartas sin halo más que en 4×4. Respaldo: el halo dorado más grueso en
   4×6, o volver a 10 pares en 4×5 con el tope (la referencia que trae el simulador).
9. **[07-Oct-2026] Dos reglas de retroceso en la misma batalla**: en el Río retrocede "en el momento",
   con 3 reventones; en Formas y Parejas, "al final", con el turno perfecto. Para Sofía la meta es
   siempre 3; para Nicole cambia (3 en el Río, 2 en Formas y Parejas). Mirar si a alguno le extraña
   ("¿por qué ahora no retrocedió?"). La forma es la misma (tropieza y retrocede); solo cambia la meta.
   **[v6.1]** Ya no es un respaldo: la intro de cada ronda con tope dice la meta (N8, §5.2), y con
   `resbalon_tras_racha` en el Río el pase se ve igual en las tres rondas (§5.2).
10. **[07-Oct-2026] El besito de Coco cuenta como turno perfecto** (si el PO lo confirma): mirar si
    Sofía lo vive como injusto ("¡ella se equivocó!"). Como el fallo de Nicole no deja nada en pantalla
    (B2), lo esperable es que nadie lo note; si Sofía lo nota y reclama, el respaldo es que el besito sí
    rompa el turno perfecto, a costa de que Nicole frene menos al rival (habría que recalibrar).
11. **[07-Oct-2026] Repetición de "¡turno perfecto!"**: en una ronda típica suena 3-5 veces. Con 2
    variantes puede cansar; mirar si los niños la corean (bien) o la ignoran (sumar 1-2 variantes).
12. **[07-Oct-2026] Partidas largas de nicole+sofia en las zonas 2 y 3** (12 pares y 11 pasos): mirar si
    pasan de 7 min. Respaldo: la alternativa de la calibración (10 pares en 4×5 con 8 pasos).
13. **[v6.1] La guirnalda al costado**: mirar si Nicole y Sofía la miran durante el turno (o solo
    cuando suena el "tin"), y si Maxi intenta tocarla en el turno de ellas. Respaldo: agrandar las
    lucecitas a 56 px, o moverla al lado derecho de la mesa si la mano que sostiene la tablet la tapa.
14. **[v6.1] El resbalón y la voz "¡le toca a…!"**: suenan juntos (el SFX va bajo la voz, con
    *ducking*). Mirar si el "plof" tapa el nombre de quien sigue. Respaldo: atrasar el resbalón 0,4 s.
    Mirar también la voz opcional `rival_resbala` (§4.3), que suena después del "le toca": si quien
    sigue espera a que termine para abrir la puerta, o si la risa del rival distrae del "¡te toca!".
    Respaldo: dejarla solo en la presentación única del turno perfecto, o quitarla (la clave es
    opcional; sin ella queda solo el SFX).
15. **[v6.1] La fila inferior de 4×6 a 10 px de la barra** (N12, aceptada): mirar si algún hermano que
    mira da vuelta una carta al tocar su ventanita. Si pasa, el respaldo es el tablero en y 128-586,
    con cartas de ≈ 104 px (bajo la regla de 110 con Maxi: lo decide el PO).

---

## 10. Qué debe hacer cada rol

Vale para HE-59 (Parejas en equipo suelto) y HE-69 (la batalla, §14). Lo nuevo de la v6 va marcado
**[v6]**, y lo de la v6.1, **[v6.1]**.

- **`dev-godot`**: §3, §4, §5 y §11 tal como están, más los menores del §13 y el §14.15 (para HE-69).
  **[v6]** En particular:
  - `GestorTurnos`: el paso 0b del pase (turno perfecto → retroceso), la regla genérica tope/racha del
    §5.2, la racha que no cuenta en turnos semilla y `posicion_boca_rival()` (§11.4);
  - `emparejar`: leer `pares_max_turno` de la composición y pasarlo como `aciertos_max_turno` con
    `"semilla": pares_turno_semilla` (§8) y responder `tope_alcanzado`;
  - `minijuego_base`: orquestar la derrota-gag con los virtuales del §11.4 (implementación vacía por
    defecto);
  - **[v6.1]** `GestorTurnos` y `pista_rival`: **el resbalón tras un turno perfecto** (pose
    `resbalar`, 1,1 s, SFX "fiuuu-plof-tilín" bajo la voz con *ducking*, y la voz opcional `rival_resbala` con su regla de cola; el pase no
    suma +1), el flag `perfecto` en `turno_cerrado`, la señal `rival_resbalo()` y
    `resbalon_tras_racha` para el Río (§4.3, §5.2, §11.4);
  - **[v6.1]** la **guirnalda de lucecitas** (`scripts/ui/meta_turno.gd`, de la capa del gestor) y el
    virtual `ancla_meta_turno()` de cada motor con tope (`emparejar`, `encajar`) (§4.1, §11.4);
  - **[v6.1]** `turno_perfecto_presenta` la primera vez por familia (`"nucleo:turno_perfecto"`,
    §5.2);
  - **[v6.1]** `emparejar` en equipo: separación de 10 px con 4 filas, las dos condiciones de hitbox de
    la fila inferior (≤ y 604 en cartas, ≥ y 614 en ventanitas) y la mesa dibujada bajo la barra (N12,
    §4.1); el guiño de la carta y `guardala_proximo_turno` durante el 0b (N13, §4.3);
  - `Progreso`: `cinematica_vista` / `marcar_cinematica_vista` por familia (§11.5);
  - `batalla.gd`: "¡todos a la nave!" corto al retomar (§14.6) y la ronda 1 sin pausa
    (`pausa_antes_ronda_1`, §14.7);
  - **no** usar la clave `pares_max_turno_propuesta`: la clave es `pares_max_turno`.
- **`tester-qa`**: un arnés `herramientas/qa_test_equipo_parejas.gd`, con semilla fija, que respalde y
  restaure `progreso.json` (memoria del proyecto). Debe cubrir:
  - las 4 composiciones y los dos valores de `orden`;
  - el turno de Maxi: siempre forma un par, no mueve al rival y en su turno el comodín y la lupa están
    inertes;
  - la segunda oportunidad de Nicole, sin nada que se dibuje en pantalla;
  - la regla de mesa de Sofía;
  - el salto del rival **solo en el paso 2 del pase**;
  - **[07-Oct-2026]** el tope de pares por turno: rige en `maxi+nicole+sofia` y `maxi+nicole`, no en
    `maxi+sofia` ni `nicole+sofia`; al llegar al tope el turno termina con "¡turno perfecto!" y sin
    voz ni animación de fallo; si el par del tope es el último, manda la victoria;
  - **[07-Oct-2026]** el retroceso: por turno perfecto con tope (Nicole 2, Sofía 3, también tras el
    besito de Coco; Maxi nunca; nunca bajo la galleta 0) y por racha de 3 sin tope (con
    `racha_retrocede_rival: 3` en los datos, que se ignora en turnos con tope);
  - **[v6.1, PO, UX N10] el resbalón**, con semilla fija:
    - turno perfecto de Nicole con el rival en la galleta 3 → en el 0b queda en 2, y en el paso 2
      **sigue en 2** (se emite `rival_resbalo()`, no `rival_movido(+1)`); el turno siguiente de Nicole
      o Sofía **sin** turno perfecto sí lo hace avanzar a 3;
    - turno perfecto con el rival en la galleta 0 → queda en 0 en el 0b y en el paso 2 (neto 0);
    - turno perfecto con el rival en `pasos_rival − 1` → **nunca** hay `rival_llego` en ese pase;
    - turno de Nicole terminado con fallo, o con menos aciertos que el tope → el pase avanza +1 como
      siempre (el resbalón es solo tras un turno perfecto);
    - turno de Maxi → ni salto ni resbalón (sigue embobado);
    - turno perfecto que gana la partida → manda la victoria, sin 0b ni resbalón;
    - `turno_cerrado(id, perfecto)` llega con `perfecto = true` solo en el cierre por
      `confirmar_turno_estable()` de Nicole o Sofía;
    - composiciones sin tope (`maxi+sofia`, `nicole+sofia`) con `resbalon_tras_racha` ausente → la
      racha de 3 hace retroceder y el pase **sí** avanza (comportamiento de la v6);
  - **[v6.1, N9] la guirnalda**: aparece solo en turnos con tope de Nicole (2 lucecitas) y Sofía (3);
    nunca en el turno de Maxi ni sin tope; se enciende una por par en < 100 ms; con tope − 1 la última
    respira; con fallo se apaga; el besito de Nicole no la cambia; un toque encima no altera el turno.
    Medir: queda a 16 px de la mesa y a ≥ 40 px del borde izquierdo en todas las composiciones;
  - **[v6.1, N12]** con 4 filas: separación de 10 px, cartas ≥ 110 px, hitbox de la fila inferior
    ≤ y 604 y de las ventanitas ≥ y 614 (un toque en y 604-614 no hace nada);
  - **[v6.1, N13]** carta tocada durante el 0b: pulso + guiño en < 100 ms, no se da vuelta, y
    `guardala_proximo_turno` suena **una sola vez por partida** (incluido el reintento);
  - la derrota-gag, que conserva los pares formados; **[v6]** con "¡otra vez!" tocado a mitad del gag
    (`gag_derrota_terminar_ya`) el resultado es el mismo;
  - **[v6]** que cada `parejas_equipo.json` respete la tabla del §5.3 (pares, grilla, `pasos_rival`,
    `pares_max_turno` solo en `maxi+nicole` y `maxi+nicole+sofia`) y que las cartas quepan en la grilla
    (pares × 2 + especiales ≤ filas × columnas);
  - la puerta (toque y arrastre) y el bloqueo de 400 ms;
  - los 50 destellos una sola vez por hermano y nivel de equipo;
  - que la victoria en equipo **no** marca completados los niveles individuales;
  - el récord por clave de equipo y las 5 estrellitas;
  - que **el guardado no tenga ningún dato de pares por hermano**.
  - La batalla tiene su propio arnés, `qa_test_batalla_arcoiris.gd` (§14.9).
- **`disenador-niveles`**: los 5 `parejas_equipo.json`, el mazo mixto con `gustos` y la calibración de
  `pasos_rival` con el simulador. **[07-Oct-2026] Hecho** (calibración en
  `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md`, valores fijados por el PO con el
  simulador); falta el playtest. **[v6]** Pendientes de coherencia:
  - actualizar las `nota` de `batalla/parejas_equipo.json` y de `zona4_islotes` / `zona5_cima`
    `parejas_equipo.json`, que todavía hablan de "PROPUESTA", `pares_max_turno_propuesta`, "pasos_rival
    7" y "levantar el límite 4×5 con Maxi" (todo eso ya es decisión del PO);
  - actualizar la calibración (§5, §9 y §10), que todavía muestra los pasos de la v2 (7 en "los tres",
    10 en nicole+sofia z2-z3, 7 en Parejas de la batalla) y la clave `pares_max_turno_propuesta`;
  - en `arcoiris_final.json`, `ganar_al_primer_intento_estimado` de Formas dice 0,95 (el PO fijó con el
    simulador 100 %) y el Río 0,87 (86 %); y los `cinematica_*` siguen en `"PENDIENTE"` (ids en §14.9);
  - la nota de `rio_equipo.json` ("3 reventones lo hacen tropezar") ya coincide con la v6.
  - **[v6.1]** simular el resbalón en el Río (que el simulador lo aplique tras un turno con retroceso
    por racha) y, si da ≥ 85 %, agregar `"resbalon_tras_racha": true` al bloque `equipo` de
    `batalla/rio_equipo.json` (§5.2); actualizar `ganar_al_primer_intento_estimado` y la calibración
    con las cifras con resbalón (Parejas de la batalla 91 %, "los tres" 82-96 %).
- **`guionista`**: las voces del §8 (en plural y sin nombres en la derrota), la intro de los trucos y
  las del Coleccionauta según su arco. **Hay que estimar el costo del TTS y pedir el OK del PO antes de
  generar.** **[v6]**:
  - los dos cierres de la intro de trucos (`intro_equipo_trucos.equipo`, con tope, y `.equipo_racha`,
    sin tope) y reescribir `intro_equipo_trucos.sofia` (§8, pendientes 1 y 2);
  - retirar `arcoiris_batalla_formas_retrocede_celebra` y la nota 2 del §10 del guion de la batalla: en
    Formas suena "¡turno perfecto!" (Cometa) + `rival_retrocede` (§14.3);
  - las voces de la derrota-gag y del logro común van en `lineas_voz` (`derrota_gag_equipo`,
    `logro_comun`), no en `equipo.voces_batalla` (§11.4);
  - en el Río, Cometa no dice "¡turno perfecto!": el retroceso por racha usa `rival_retrocede` y, si se
    quiere, una celebración corta de Coco sin número ni nombre.
  - **[v6.1]** (ya en curso en el guion, N8, N11 y N13): la meta del tope en las intros y en la
    `repetir` de las rondas con tope, `turno_perfecto_presenta` y `guardala_proximo_turno` (§5.2, §8
    pendientes 4 y 5, §14.11). `rival_retrocede` puede decir "¡me resbalé!", pero **no** puede
    anunciar que después avanza. El resbalón del paso 2 usa `rival_resbala` (ya escrita, opcional,
    después de "¡le toca a…!", §4.3).
- **`director-cinematicas`** **[v6]**: respuestas a las preguntas de su §14 (puntos 5 a 8): la ronda 1
  arranca sola (§14.7, y sigue como duda 5 al PO), "¡todos a la nave!" **sí** se repite al retomar en
  versión corta (§14.6), "ya vista" es **por familia** con ids `"<id_batalla>:<id_animacion>"` (§11.5),
  y las firmas del gag de derrota quedan aceptadas y ampliadas (`gag_derrota_terminar_ya`,
  `reintentar_equipo`, `contar_logro_equipo`, §11.4). "¡Turno perfecto!" es de Cometa.
- **`experto-ux-parvulo`** **[v6]**: auditar en papel el tope de pares y el turno perfecto (§5.2, §4.3
  paso 0b), la regla distinta del Río y el 4×6 con Maxi; en el build, los riesgos 6 a 12 del §9.
  **[v6.1]** Verificar en papel N8 a N13 (guirnalda al costado en vez de arriba, resbalón, excepción de
  10 px, guiño + "¡guárdala…!", intros con la meta) y la extensión del resbalón al Río; en el build, los
  riesgos 13 a 15.
- **`disenador-personajes`**:
  - el gesto corto de cada hermano (0,6 s);
  - el puf de "yo miro";
  - la nave de juguete con ventanitas (ícono y barra);
  - para el Coleccionauta, de su canon (gafas-lupa y mochila-torre): las poses de saltar galleta,
    tropezar, embobado, aplaudir, la mochila-torre que aspira, se infla y estornuda, y caer sentado.
    En el gag de embobado **no estira los brazos hacia Maxi**, por pedido del `guionista`.
    **[v6.1]** La pose `resbalar` (§4.3: impulso, saltito corto, pies en ruedita, plof sentado,
    estrellitas y cara de risa avergonzada, nunca de dolor) y la de pararse y sacudirse. El "tropezar"
    del 0b es **hacia atrás y de pie**; el resbalón es **en su lugar y sentado**: se tienen que
    distinguir;
  - **[v6.1]** la guirnalda de lucecitas (regleta del color del marco, bombillitas de 48 px apagadas
    "por prender", nunca grises).

---

## 11. Arquitectura: cómo se respeta "el núcleo no conoce minijuegos"

### 11.1 Piezas y responsabilidades

| Pieza | Dónde | Sabe de… | No sabe de… |
|---|---|---|---|
| `Progreso` (autoload) | `scripts/autoloads/progreso.gd` | El equipo activo, los destellos, el récord y las estrellitas de equipo | Cartas, turnos |
| Selección | `scripts/nucleo/seleccion_personaje.gd` | Armar el equipo y fijar `Progreso.equipo_activo` | Qué juegos admiten equipo |
| Mapa del planeta | `scripts/nucleo/mapa_planeta.gd` | Leer `nivel_equipo` de `mapa.json` e instanciar la escena del motor con `equipo` | Parejas |
| **`GestorTurnos`** (nuevo, genérico) | `scripts/base/gestor_turnos.gd` | El orden, el turno actual, el pase (pasos 0-5, con el 0b del turno perfecto), la puerta, el bloqueo, los pasos del rival, el tope, la racha y el retroceso | Cartas, qué es un "par" |
| `minijuego_base.gd` | `scripts/base/` | Crear el `GestorTurnos` si hay equipo, `perfil_de()`, el registro del resultado del equipo en `Progreso` y **orquestar la derrota-gag** (§11.4, 07-Oct-2026) | Las reglas de un juego concreto |
| `barra_equipo.gd`, `pista_rival.gd` y `meta_turno.gd` (nuevos; la guirnalda es v6.1) | `scripts/ui/` | Dibujar y animar lo que el gestor les dice, más la ventanita de porra, el resbalón y la guirnalda de lucecitas | Cartas |
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
signal rival_resbalo()                                      # v6.1 (PO, UX N10): paso 2 tras un turno perfecto (o tras
                                                            # retroceso por racha si resbalon_tras_racha); posición SIN cambio
signal rival_llego()                                        # minijuego_base orquesta la derrota-gag (ver abajo, 07-Oct-2026)
signal entrada_bloqueada_cambio(bloqueada: bool)            # el motor solo muestra el pulso si está bloqueada

func configurar(equipo: Array[String], config: Dictionary, perfiles: Dictionary, capa_ui: CanvasLayer) -> void
	# config = nivel["equipo"]; perfiles = {id: "semilla"|"brote"|"estrella"}; crea barra_equipo y pista_rival
func empezar() -> void                 # primer turno (Maxi si juega), con su puerta
func hermano_actual() -> String        # tras rival_llego(), ya devuelve al hermano cuyo retrato está en el centro
func perfil_actual() -> String         # ídem
func entrada_bloqueada() -> bool
func notificar_acierto() -> void
	# suma a la racha del turno. [07-Oct-2026] Si el perfil actual NO tiene clave en aciertos_max_turno:
	# cada racha_retrocede_rival → rival -1 (mínimo 0). Si la tiene: al llegar al tope bloquea la entrada
	# y emite tope_alcanzado(); la racha no mueve al rival (el retroceso es por turno perfecto).
	# En turnos semilla con maxi_mueve_rival = false la racha no cuenta (Maxi nunca mueve al rival).
	# Una cadena del Río que vale N aciertos (cadena_vale_aciertos) = N llamadas seguidas.
func terminar_turno(con_fallo: bool) -> void
	# pasos 0/1 según perfil y con_fallo → paso 2 (+1 rival si el perfil saliente != semilla o maxi_mueve_rival)
	# → si llegó: rival_llego() con el retrato del siguiente en el centro; si no: puerta → bloqueo → turno_iniciado
	# v6.1: si resbalon_tras_racha y en este turno hubo al menos un retroceso por racha, el paso 2 emite
	# rival_resbalo() en vez de +1 (y entonces nunca hay rival_llego()). Por defecto false (§5.2).
func pasos_usados() -> int             # posición actual del rival (para el récord)
func reiniciar_rival() -> void         # tras "¡otra vez!": vuelve a 0 y abre la puerta del hermano en el centro

# --- Batalla (UX HE-66: M2, B2.1, M9, M4, N5, N6) [07-Oct-2026] ---------------------------------
signal jugada_automatica_pedida()     # M2: turno Semilla con semilla_auto_s sin ningún toque → el motor
                                      # hace su jugada automática y la cierra como cualquier acierto
signal tope_alcanzado()               # B2.1: la racha del turno llegó a aciertos_max_turno[perfil]; la
                                      # entrada ya quedó bloqueada; el gestor espera confirmar_turno_estable().
                                      # [07-Oct-2026] Formas y Parejas (con o sin pares_max_turno: semilla
                                      # siempre trae tope 1, §8)
signal turno_cerrado(id_hermano: String, perfecto: bool)  # M4: emitido con el turno cerrado y el estado
                                      # estable, ANTES del pase; minijuego_base guarda el parcial en ese momento
                                      # (ver abajo). v6.1: perfecto = true solo si el turno cerró por
                                      # confirmar_turno_estable() de un perfil != semilla (turno perfecto). Lo
                                      # usan el motor (N13: guiño y "¡guárdala…!" durante el 0b) y quien quiera
                                      # saberlo; el gestor ya lo sabe por sí mismo para el resbalón

# configurar() lee además, de config (= nivel["equipo"]):
#   "semilla_auto_s": int        (0 o ausente = apagado). El conteo parte en turno_iniciado de un perfil
#                                 semilla y se reinicia con CUALQUIER pulsación (táctil o mouse) en la
#                                 pantalla, que el gestor escucha en _input() sin consumirla. Con la
#                                 entrada bloqueada (puerta, pase, pausa) no cuenta.
#   "aciertos_max_turno": {perfil: int}  (ausente o perfil sin clave = sin tope, como Parejas)
#   "confirmar_turno": bool       (false = modo sin puerta, ver abajo)
#   "rival": null                 (sin pista ni rival_*; obligatorio junto a confirmar_turno: false)
#   "resbalon_tras_racha": bool   (v6.1; false o ausente = tras un retroceso por racha el pase avanza como
#                                 siempre. El resbalón tras turno perfecto NO depende de esto: siempre ocurre)
#
# v6.1, UX N9: la guirnalda de lucecitas (meta_turno.gd) la crea el gestor junto con barra y pista, y la
# maneja solo: aparece en turno_iniciado si el perfil tiene clave en aciertos_max_turno y no es semilla;
# se enciende en notificar_acierto(); respira con tope − 1; se apaga despacito en terminar_turno(true);
# destella y lanza su chispa a los pies del rival en confirmar_turno_estable(); se retira en el paso 2.
# La POSICIÓN se la pide al motor, que es el único que sabe dónde está su mesa:
#
# minijuego_base.gd (virtual; implementación vacía = Vector2.INF → el gestor la pega a x 40, centrada en
# y 364):
## Punto global donde va el borde DERECHO-centro de la guirnalda: 16 px a la izquierda de la mesa del
## motor, centrado en su alto. emparejar: mesa de cartas; encajar: zona_figuras. El gestor nunca la deja
## a menos de 40 px del borde izquierdo de la pantalla.
#   func ancla_meta_turno() -> Vector2
func confirmar_turno_estable() -> void
	# B2.1: el motor la llama tras tope_alcanzado cuando no queda nada en vuelo (pieza chueca resuelta,
	# bala o retroceso terminados). El gestor emite turno_cerrado, hace "¡turno perfecto!" (Cometa,
	# lineas_voz.turno_perfecto) con el gesto corto del hermano y, [07-Oct-2026, PO] si el perfil no es
	# semilla, el RETROCESO POR TURNO PERFECTO: rival_movido(-1) con rival_retrocede (mínimo 0; en la
	# galleta 0 solo tropieza, sin voz). Es el paso 0b del §4.3. En semilla: su celebración normal de
	# acierto, sin esa voz extra y sin retroceso. Después pasa el turno como terminar_turno(false), sin
	# fallo, con UNA diferencia [v6.1, PO 07-Oct-2026, UX N10]: si fue turno perfecto (perfil != semilla),
	# el paso 2 NO suma +1: emite rival_resbalo() y pista_rival anima "resbalar" (1,1 s, en paralelo con
	# el vuelo del retrato; §4.3). En semilla, la regla de siempre (maxi_mueve_rival: false → sin salto).
	# Orden exacto: turno_cerrado(id, true) → voz turno_perfecto (o turno_perfecto_presenta la 1.ª vez por
	# familia, §5.2) + gesto + guirnalda destella → rival_movido(-1) + rival_retrocede → (espera bus de voz
	# libre, máx. 1,5 s) → paso 2 con rival_resbalo() + SFX bajo le_toca → (si la cola queda libre en ≤ 1 s,
	# la puerta sigue cerrada y no sonó guardala_proximo_turno) rival_resbala; si no, se omite.
	# Si el acierto del tope ganó la ronda, el motor no llama esto: emite completado (manda la victoria).
func sin_puerta() -> bool              # M9: true en el epílogo; no hay puerta, ni pista, ni rival_*, ni
	# semilla_auto_s. terminar_turno(false) solo hace volar el retrato del siguiente a la barra con
	# "¡ahora Nicole!" y emite turno_iniciado de inmediato (sin bloqueo de 400 ms). con_fallo se ignora.
func empezar_retomando() -> void
	# M4/N6: igual que empezar(), pero tras restaurar un parcial. Rival en 0, racha en 0 y orden
	# maxi_intercalado desde su primer puesto: el primer turno es SIEMPRE de Maxi (con su puerta),
	# sin importar a quién le tocaba al salir. Ver §14.6.
```

**Contrato con el motor** (actualizado 07-Oct-2026, UX HE-66 N5):

- El motor llama `notificar_acierto()` y `terminar_turno(con_fallo)` como siempre. **En la batalla
  suma una sola llamada más**: `confirmar_turno_estable()`, únicamente como respuesta a
  `tope_alcanzado`.
- **Quién corta el turno**:
  - **por fallo** (Parejas, Formas), o **porque se gastaron las gotas del turno** (Río): el motor, con
    `terminar_turno(...)`, siempre en estado estable (§14.15, punto 3);
  - **por tope de aciertos** (Formas, y Parejas desde el 07-Oct-2026 [PO]): **el gestor**. Al llegar al
    tope, bloquea la entrada, emite `tope_alcanzado` y espera a que el motor confirme el estado estable
    con `confirmar_turno_estable()`. Tras `tope_alcanzado` el motor **no** llama `terminar_turno`. En
    Parejas, "estable" = el par ya voló a la cinta y no queda ninguna carta girando.
- **Jugada automática** (M2): el gestor cuenta los `semilla_auto_s` y emite `jugada_automatica_pedida`;
  el motor la ejecuta (§14.3) y la cierra con las mismas llamadas que una jugada de Maxi (acierto →
  tope 1 en Formas, gota gastada en el Río, pareja formada en Parejas). El gestor no sabe qué juego es.
- El motor escucha `turno_iniciado`, para aplicar la capa del perfil (`aplicar_perfil_turno`, §14.15).
  **`rival_llego` lo escucha `minijuego_base`, no el motor** [07-Oct-2026]: la derrota-gag la orquesta
  la base (abajo).
- **Derrota-gag, orquestada por `minijuego_base` [07-Oct-2026; responde al storyboard HE-68 §14.1]**.
  El núcleo no sabe qué elementos aspira el rival; el motor no sabe del rival. La base llama a tres
  métodos **virtuales** del motor, con implementación vacía en `minijuego_base` (devuelven 0.0 y no
  hacen nada), así un motor sin gag propio igual completa la secuencia:

  ```gdscript
  # minijuego_base.gd (virtuales; el motor los sobreescribe)
  ## Hace volar los elementos pendientes del juego (cartas, gotas, piezas sueltas) hacia `destino`
  ## (coordenadas globales de la boca de la mochila-torre) y los oculta. Devuelve la duración en s.
  func gag_derrota_aspirar(destino: Vector2) -> float
  ## Los devuelve "estornudados" a su lugar, ya en el estado del perfil que jugará después
  ## (m2 de HE-66: Formas derechas para semilla/brote, giradas para estrella). Devuelve la duración.
  func gag_derrota_devolver(perfil_siguiente: String) -> float
  ## Corta lo que esté en vuelo y deja el estado final de "devolver" al instante (toque en "¡otra vez!"
  ## a mitad del gag). Después la base llama a reintentar_equipo().
  func gag_derrota_terminar_ya(perfil_siguiente: String) -> void
  ## Lo propio del reintento: Parejas revuelve solo las pendientes y hace un vistazo nuevo (§5.5);
  ## Río y Formas no hacen nada. Lo conservado en la ronda nunca se toca.
  func reintentar_equipo() -> void
  ## Cuánto se conservó en ESTA ronda (pares, piezas, gotas reventadas) para el logro común de Cometa.
  func contar_logro_equipo() -> int

  # GestorTurnos (dato para la base)
  func posicion_boca_rival() -> Vector2   # global; pista_rival la conoce
  ```

  **Secuencia** (la base, tras `rival_llego`; la entrada ya está bloqueada y el retrato del siguiente
  ya está al centro, achicado a ≈ 210 px en y ≈ 250 en Río y Formas según el storyboard §11):
  1. aparece "¡otra vez!" (≥ 160 × 160 px) **desde el segundo 0** (storyboard §11);
  2. `pista_rival` anima `aspirar` y la base espera `gag_derrota_aspirar(turnos.posicion_boca_rival())`;
  3. `pista_rival` anima `estornudar` y la base espera `gag_derrota_devolver(turnos.perfil_actual())`;
  4. `pista_rival` anima `sentarse`; voces `derrota_gag_equipo` en secuencia y, al final, el logro
     común de Cometa con `contar_logro_equipo()` (`nos_alcanzo` si es 0, §8);
  5. al tocar "¡otra vez!" (en cualquier momento): si el gag no terminó,
     `gag_derrota_terminar_ya(turnos.perfil_actual())`; después `reintentar_equipo()` y
     `turnos.reiniciar_rival()` (vuelve a 0 y abre la puerta del que ya estaba al centro).
  - **Voces**: la base lee `lineas_voz.derrota_gag_equipo` (secuencia) y el logro común de
    `lineas_voz.logro_comun` (mapa "N" → ruta); si no hay `logro_comun`, usa `pares_juntados` (compat.
    con Parejas). Se descarta el bloque `equipo.voces_batalla` que propuso el guion de la batalla (§10.5
    de `voces-batalla-arcoiris.md`): las voces de un nivel viven en un solo lugar, `lineas_voz`.
- **Parcial de la ronda** (M4): el gestor **no guarda nada** ni conoce el estado del juego. Al
  emitir `turno_cerrado`, `minijuego_base` llama a su propio `obtener_parcial_equipo()` y lo emite
  hacia afuera con una señal nueva, `signal parcial_equipo_listo(estado: Dictionary)`; `batalla.gd` la
  escucha y llama `Progreso.guardar_parcial_batalla(...)` (§14.9). Al volver, `batalla.gd` llama
  `restaurar_parcial_equipo(estado)` en el motor **antes** de que el motor llame
  `turnos.empezar_retomando()` en lugar de `empezar()`. Fuera de la batalla nadie escucha
  `parcial_equipo_listo` (m3, §13).
- **Resbalón y carta tocada en el 0b [v6.1]**: el gestor decide el resbalón solo (sabe si el turno cerró
  por tope), y el motor **no hace nada** para que ocurra. El motor de Parejas escucha
  `turno_cerrado(id, perfecto)` solo para N13: con `perfecto = true`, hasta el `turno_iniciado`
  siguiente, una carta tocada hace pulso + guiño y, la primera vez en la partida, pide
  `guardala_proximo_turno` (§4.3). Para no pisar voces, el motor la encola en el bus de voz y el gestor
  espera el bus libre antes del paso 2.
- Todo lo demás (barra, pista, puerta, porras, voces de "le toca", "¡turno perfecto!", el resbalón y la
  guirnalda) vive en el gestor y su UI. Así otro motor (el Río en equipo, por ejemplo) solo decide cuándo termina un turno.

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
    "cinematicas_vistas": [],                   // 07-Oct-2026: POR FAMILIA, "<id_batalla>:<id_animacion>" (storyboard HE-68 §14.1)
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
- **"Cinemática ya vista" por familia [07-Oct-2026]**: la batalla solo se juega con los tres, así que el
  "ya la vimos" es de los tres a la vez; además, dentro de la batalla no hay un perfil activo
  (`id_perfil = ""`, §11.2) al que colgarlo. Vive en
  `equipo.cinematicas_vistas` (agrega una estructura vacía en la migración v2 → v3; si el guardado ya
  está en v3 sin la clave, se crea al leer).

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
## 07-Oct-2026 (storyboard HE-68): "ya vista" es de la FAMILIA, no de un perfil. id = "<id_batalla>:<id_animacion>"
## (p. ej. "arcoiris_batalla_final:entrada"), para que HE-39 reutilice los ids de animación sin heredar el "visto".
## Se marca al TERMINAR la cinemática, no al empezarla.
## v6.1 (UX N8): también "nucleo:turno_perfecto" = la familia ya oyó la presentación del turno perfecto (§5.2).
func cinematica_vista(id: String) -> bool
func marcar_cinematica_vista(id: String) -> void

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

## 12. Decisiones del PO registradas en esta ficha (06 y 07-Oct-2026)

| # | Decisión | Dónde |
|---|---|---|
| 1 | En equipo se juegan **todas las zonas de Arcoíris**, cada uno con su dificultad | §3.3 |
| 2 | **50 destellos iguales para cada hermano, solo la primera vez**. La partida en equipo no marca completada la estación individual. Se mantienen las 5 estrellitas del botón | §3.1, §7 |
| 3 | El rival de Parejas es **el Coleccionauta** | §5.3 |
| 4 | Turnos del menor al mayor, ajustados con M3 (Maxi intercalado) | §4.2 |
| 5 | Los récords parten en cero | §7.2 |
| 6 | La carrera tipo *Zicke Zacke* queda para después | §5.1 |
| 7 | La mesa con parejas propias de cada hermano queda solo de respaldo | §5.1 |
| 8 | El modo equipo **debuta como la Batalla final de Arcoíris** (final de temporada del planeta 1): la primera batalla de los tres contra el Coleccionauta | §14 |
| 9 | El botón "¡Juntos!" **aparece como premio al ganar la batalla** | §3.1, §14.7 |
| 10 | La batalla tiene **varias rondas (3 o 4)**: cada una es un minijuego distinto de Arcoíris por turnos, y **la última es Parejas en equipo** | §14.3 |
| 11 | El Coleccionauta aparece en Arcoíris (la licencia de historia queda aprobada) | §14.2 |
| 12 | **M6 aceptado**: en equipo, el vistazo muestra como máximo 3 pares en 3 s, y Nicole sola ve 1 o 2 pares según el tablero | §5.4; motor §10.2 |
| 13 | La batalla se desbloquea cuando **el primer hermano recibe el ala** | §14.7 |
| 14 | La batalla se juega **solo con los tres hermanos** | §14.7 |
| 15 | **(07-Oct-2026)** Tope de pares por turno en Parejas en equipo (Maxi 1, Nicole 2, Sofía 3), solo en "los tres", maxi+nicole y la batalla | §5.2, §8 |
| 16 | **(07-Oct-2026)** El rival retrocede por **turno perfecto** en Formas y en Parejas con tope; sin tope sigue la racha de 3 | §5.2, §14.3 |
| 17 | **(07-Oct-2026)** Tableros **4×6 permitidos con Maxi** | §5.3 |
| 18 | **(07-Oct-2026)** Cifras del simulador: Río 20 gotas / 7 pasos, Formas 12 piezas / 5, Parejas 12 pares 4×6 / 5; "los tres" 5 pasos en todas las zonas; nicole+sofia 11 pasos en z2 y z3 | §5.3, §14.3 |
| 19 | **(07-Oct-2026, UX N10) "Se resbala y no avanza"**: en el pase que sigue a un turno perfecto, el Coleccionauta intenta saltar, se resbala y se queda: ese pase no avanza. Reemplaza "el salto del paso 2 ocurre igual". **Sin cambiar ningún `pasos_rival`** (simulador con resbalón: batalla Parejas 91 %, Formas 100 %, Río 86 %; "los tres" z1 82 %, z2 86 %, z3 85 %, z4 96 %, z5 96 %). Su extensión al Río por la racha de 3 (`resbalon_tras_racha`) es de `disenador-mecanicas`, pendiente de simular | §4.3, §5.2, §5.3, §6, §11.4, §14.3 |

---

## 13. Para Dev: menores de la validación UX de HE-58 (aplicar directo)

| Id | Qué hacer | Dónde quedó |
|---|---|---|
| m1 | Colores de turno: Maxi `#3E77CC`, Nicole `#E8589C`, Sofía `#2FB3AD`. El aura de Sofía nunca es rosa | §4.1 |
| m2 | Voz de confirmación al sacar o meter un hermano en armar equipo | §3.2 |
| m3 | La pantalla de juego en equipo conserva el botón casa (≥ 96 px). Salir no pierde nada: **en equipo fuera de la batalla** no hay guardado parcial, y la partida simplemente no cuenta. **[07-Oct-2026, UX HE-66 N6]** La excepción es la batalla: ahí sí se guarda el avance de la ronda en curso (§14.6, M4). Dev no activa el parcial en el modo equipo suelto (botón "¡Juntos!") | §4.1; §14.6 |
| m4 | "¡Otra vez!" en equipo de ≥ 160 × 160 px | §5.5 |
| m5 | El recordatorio "¡te toca!" suena como máximo 2 veces, y después el retrato solo respira | §4.3 |
| m6 | Sin récord previo, no hay banderita: "¡su primer récord!" (en equipo y en solitario) | §7.2; motor §10.1 |
| m7 | "Mismo tamaño" en la fiesta = mismo foco, duración y volumen. No achicar a Sofía | §5.6 |
| m8 | Gomita del tablero impar: redonda, 60 % del tamaño de una carta, sin dorso. Al tocarla se menea y hace "boing" | motor §10.3 |
| m9 | Colección sin contadores ("23/60"). Cada hermano ve solo la suya, desde su mapa | motor §10.5 |
| m10 | El texto flotante ("+200", "×3") nunca se dibuja sobre cartas tapadas, y en equipo no aparece | motor §10.1; §5.2 |
| m11 | UX recomendaba abrir solo las zonas del hermano más avanzado; **el PO decidió todas las zonas** | §3.3 |
| m5 (HE-66), para HE-59 | Cometa (`Rect2(8, 4, 110, 96)`) y el botón casa deben quedar **a 24 px o más del tablero**: el tablero de Parejas en equipo va en `Rect2(40, 128, 1200, 472)`. Con 4 filas en 472 px, las cartas siguen midiendo ≥ 110 px. Hay que revisar que las composiciones del §5.3 caben | §4.1 |

---

## 14. Batalla final de Arcoíris (final de temporada del planeta 1)

> **Decisión del PO (06-Oct-2026)**:
>
> - el modo equipo **debuta como el final de temporada del Planeta Arcoíris**: es **la primera batalla
>   de los tres hermanos contra el Coleccionauta**;
> - los tres tienen que aportar para ganarle, y la batalla **cierra el primer planeta**;
> - tiene **3 o 4 rondas**: cada una es **un minijuego distinto de Arcoíris jugado por turnos**, y **la
>   última es Parejas en equipo**;
> - **el botón "¡Juntos!" es el premio**;
> - **el Coleccionauta aparece en Arcoíris** (la licencia de historia queda aprobada).
>
> El resto de esta sección es **[Propuesta]** de `disenador-mecanicas`, salvo lo marcado [PO] o [UX].
> Todo lo que la validación UX de HE-58 exige para el modo equipo (B1-B3 y M1-M10) **vale también en
> cada ronda de la batalla**.

### 14.1 La idea en una frase

Justo cuando los hermanos le devolvieron al planeta sus tres primeros colores, el Coleccionauta aterriza
en Arcoíris y **se los aspira con su mochila-torre** "para su colección". Los tres hermanos, por turnos,
le ganan tres rondas de los juegos del planeta, y con cada ronda **un piso de la mochila-torre estornuda
un color de vuelta al cielo**.

### 14.2 La historia y el arco del Coleccionauta [PO: aparece en Arcoíris; Propuesta: cómo]

- **Por qué viene**: se entera, por la video-llamada de papá en la escena del ala, de que existe un
  "planeta que recupera sus colores" y quiere esos colores para su colección.
- **Qué hace**: con su **mochila-torre** (su canon) aspira las tres bandas que el equipo devolvió:
  - **rojo** (zona 1);
  - **amarillo** (zona 2);
  - **azul** (zona 3).
  
  La mochila-torre queda con **tres pisos transparentes**, uno por color.

  **[UX HE-66, M3]** El robo existe **solo dentro de la escena de la batalla** (`batalla.tscn` y sus
  cinemáticas):

  - **el mapa de cada hermano nunca pierde color**; ahí solo aparece el hito chistoso de la
    mochila-torre;
  - en la escena se agrisa **solo la franja del arcoíris**, sin oscurecer la pantalla (m7);
  - dentro de los pisos, los colores **se ven intactos y contentos**: rebotan y saludan, no están
    atrapados ni llorando. Coco dice de inmediato "¡están guardados ahí! ¡Los vamos a sacar juntos!". Es
    un rescate, no una pérdida;
  - el aspirado suena a **sorbete con bombilla** (un "sluuurp" corto de 1,5 s o menos), nunca a motor
    de aspiradora (m7);
  - la mochila-torre no tiene patas, antenas ni nada parecido a un bicho (m7);
  - si en el playtest alguien dice "¡nos robó lo que ganamos!", el respaldo es que el Coleccionauta
    traiga colores robados de otro lado.
- **Qué aprende** (la semilla del final del juego, sin decirla):
  - en la batalla descubre que "un equipo no cabe en una mochila" (el guion ya lo siembra en
    `coleccionauta_aplaude_02`);
  - al final, los hermanos **le regalan colores** pintando su mochila (§14.3, epílogo): los colores se
    comparten, no se guardan.
  - No se lleva nada. Se va contento y con la promesa chistosa de volver "con una mochila más grande",
    que es el gancho de HE-39.
- **Nunca menciona a papá** durante la batalla (decisión 4 del guion). Papá aparece solo en la
  video-llamada del cierre (§14.8).
- **Coherencia**: el Coleccionauta se ve **siempre** como en su canon (`guia-estilo-generacion.md` y la
  intro): **gafas-lupa y mochila-torre**. Sin monóculo, sin nave-aspiradora y sin red. Las preguntas del
  roadmap del Río sobre la Nube Gris (§8 del roadmap) no cambian: en la batalla, el gris es el que sale
  de la mochila-torre.

### 14.3 Rondas: qué minijuegos entran y cómo aporta cada uno

**Regla común a todas las rondas**. Está validada para Parejas; **en el Río y en Formas, el turno se
define en la tabla de abajo** (UX HE-66, B1.6):

- Por turnos, en el orden `maxi_intercalado`, con la puerta de turno (B1 de HE-58) y el pase con el salto
  del rival (B3 de HE-58).
- **Cuándo termina un turno, según la ronda**:
  - **Parejas**: "si aciertas, sigues; con el fallo, pasa el turno", con la segunda oportunidad de
    Nicole (§5.2).
  - **Formas**: lo mismo, pero **con un tope de aciertos por turno** (B2).
  - **Río**: **se miden gotas, no fallos** (B1).
- **Cuándo retrocede el Coleccionauta [PO, 07-Oct-2026]**:
  - **Formas y Parejas**: por **turno perfecto** (Nicole o Sofía llegan a su tope sin que un fallo
    termine el turno, §5.2), en el paso 0b del pase, con "¡turno perfecto!" de Cometa;
  - **Río**: por **racha de 3** reventones en un turno, en el momento (§5.2, "En el Río rige la racha
    de 3").
  - **[v6.1, PO, UX N10] Y en el pase siguiente se resbala y no avanza**: siempre tras un turno
    perfecto (Formas y Parejas); en el Río, tras un turno con retroceso por racha, con
    `resbalon_tras_racha: true` (§5.2, pendiente de simular).
- **Regla general de las batallas, también para HE-39 (UX HE-66, B3.3)**: **el turno de Maxi en una
  ronda de batalla nunca le exige más que su ruta Semilla del mismo motor.**
- **Maxi nunca deja la partida esperando (UX HE-66, M2)**: si en su turno pasan **20 s sin ningún
  toque**, el turno se resuelve solo y Coco dice "¡Maxi nos dejó un regalito!":
  - **Parejas**: las cartas del halo quedan a la vista y se forman solas a los 3 s.
  - **Formas**: la pieza del halo vuela sola a su lugar.
  - **Río**: la gota sale sola hacia el grupo con halo.
  
  Es el parámetro genérico `semilla_auto_s: 20` del `GestorTurnos`.
- **El reloj de la ronda es la pista de galletas** (§5.3). Es la única forma de perder una ronda, y
  ningún juego tiene derrota propia dentro de la batalla: ni remolino, ni límite de fallos.
- **Sin puntaje, racha con número, estrellitas ni récords individuales en la batalla** (R2 y M1).
- Solo se usan **motores que ya existen**: `rio`, `encajar`, `lienzo_libre` y `emparejar`. Los
  motores `clasificar` y `mezclar` quedan fuera, porque el Río los reemplazó (roadmap del Río).

| Ronda | Juego (motor) | Color que recupera | Qué es un "acierto" | Turno de Maxi (aporte real) | Turno de Nicole | Turno de Sofía |
|---|---|---|---|---|---|---|
| **1** | **Río de pintura** (`rio`) | Rojo | Un disparo que **revienta** un grupo. **No existe el fallo**: un disparo que no revienta es neutro (el "plop" de inserción, sin voz de fallo) [UX B1] | **1 gota por turno (B3.2)**. (1) Antes de su toque, el grupo objetivo **ya brilla con halo dorado**. (2) **Toda la pantalla dispara**, también un toque sobre Coco, porque **en su turno el intercambio está desactivado**. (3) La lengua sale **primero hacia su dedo** (0,1 s) y la gota curva con estela hacia el grupo, que **siempre revienta** (garantizado por la regla "Reventón de Maxi" de abajo, 07-Oct-2026, N2). (4) Si tocó a menos de 150 px del halo, suena "¡justo ahí!" | **3 gotas por turno** [UX B1], que se ven sin números como **3 gotas en la mano de Coco** (la de la boca y dos de reserva) y se gastan una por disparo. Línea de guía completa. **La segunda oportunidad no aplica en esta ronda**, porque no hay fallo. Con 3 reventones en un turno, el Coleccionauta retrocede (igual que Sofía) | **3 gotas por turno**, sin guía. Una **cadena** (retroceso que revienta) vale **2 aciertos** de racha. Con 3 reventones en un turno, el Coleccionauta retrocede (racha de 3, §5.2) |
| **2** | **Formas traviesas** (`encajar`) | Amarillo | Una pieza **bien encajada** en la silueta compartida. **Fallo** = soltar la pieza sobre un hueco equivocado. **Soltarla en el vacío no es fallo**: vuelve a la bandeja (el resultado `"nada"` del motor) [UX B2.2] | **1 pieza por turno, con las mismas reglas de su ruta (B3.1)**: la pieza con halo es la más grande que queda (lado corto ≥ 110 px) y funciona con **`toque_lleva_a_casa`** (al tocarla vuela a su lugar con estela, en 0,5 s), **`iman_tolerancia_px: 5000`** si la arrastra, y **`sin_error`**. Su hueco respira, y Coco dice "¡Maxi, la pieza que brilla!". Las otras piezas de la bandeja solo hacen el pulso con un sonido amable: no se pueden tomar | **Tope de 2 aciertos por turno** [UX B2.1]. Piezas sin rotación y con silueta interior visible (como su ruta). Al empezar su turno, las piezas **se enderezan con un "fiu" visible**. Segunda oportunidad con el primer fallo | **Tope de 3 aciertos por turno** [UX B2.1]. Al empezar su turno, las piezas **giran a un ángulo al azar con un "fiu" visible**, y hay que girarlas (`rotacion_por_toque`). Pasa el turno con el primer fallo. Su "turno perfecto" de 3 piezas hace retroceder al Coleccionauta, igual que el de 2 piezas de Nicole [PO, 07-Oct-2026] |
| **3 (final) [PO]** | **Parejas en equipo** (`emparejar`) | Azul | Una pareja | §5.2, más el turno que se resuelve solo a los 20 s (M2) | §5.2 | §5.2 |
| **Epílogo** (no se pierde) | **Pinta con Coco** (`lienzo_libre`, encargo `colorear_zonas`) | — (se **regalan** colores) | — | **Un toque rellena una parte grande** de la mochila-torre gris (el modo "Pinta a Coco" de su ruta) | Rellena una parte con el color que elige (muestras de la paleta ≥ 96 px) | Igual que Nicole |

- **Al llegar al tope de aciertos en Formas**, el turno termina **en celebración** ("¡turno perfecto!",
  con el gesto corto del hermano), nunca como fallo (UX B2.1). Parámetro:
  `aciertos_max_turno: {"semilla": 1, "brote": 2, "estrella": 3}`.
  - **[PO, 07-Oct-2026]** En Nicole y Sofía, ese turno perfecto **hace retroceder al Coleccionauta**
    (paso 0b del §4.3); la `racha_retrocede_rival: 3` que trae `formas_equipo.json` se ignora, porque
    todos los perfiles tienen tope (§5.2, regla para el gestor).
  - **Voz**: "¡turno perfecto!" (Cometa) + `rival_retrocede`. **Ya no se usa
    `arcoiris_batalla_formas_retrocede_celebra`** ("¡Tres piezas seguidas!"), que el guion ponía en
    lugar de `turno_perfecto` cuando coincidían (§10.2 del guion): con el retroceso por turno perfecto
    coinciden siempre, y "tres piezas" sería falso para el turno perfecto de Nicole (2 piezas).
  - **Ronda 3 (Parejas)**: igual, con `pares_max_turno` {1, 2, 3} en la composición de la batalla
    (§5.2). Es la misma regla de tope para todas las rondas con aciertos.
  - **[v6.1, UX N9] La meta se ve**: en los turnos de Nicole y Sofía, la guirnalda de lucecitas (§4.1)
    con 2 o 3 lucecitas, que se encienden con cada pieza encajada. En Formas, `ancla_meta_turno()`
    devuelve el borde izquierdo de `zona_figuras` (x 150): guirnalda en x 70-134, centrada en y 356
    (entre y 252 y 460 con 3 lucecitas), a ≥ 24 px de Cometa y de la barra. No es tocable, así que
    una pieza soltada encima vuelve a la bandeja como cualquier "soltar en el vacío" (no es fallo).
  - **[v6.1, UX N13] En Formas no hay "¡guárdala…!"**: no hay nada escondido que recordar. Una pieza
    tocada durante el 0b solo hace el pulso.
- **Carga de Coco en la batalla (UX B1.4)**: Coco **nunca carga un color sin pareja en el río**. Siempre
  carga uno que ya tenga al menos 1 gota en el cauce. Solo en los turnos de Nicole y Sofía se puede
  cambiar la gota con Coco (la regla normal). En el turno de Maxi la carga no es al azar: la fija la
  regla siguiente.
- **Reventón de Maxi en el Río [07-Oct-2026, UX HE-66 N2]**. Hoy `LogicaRio._reventar_en()` solo
  revienta tramos de 3 o más (`if n < 3: return 0`) y `tramo()` cuenta solo gotas **contiguas que se
  tocan** (`tocan()`). Una sola gota en el cauce no basta: si la bala de Maxi cae en un tramo de 1, queda
  un tramo de 2 y no pasa nada. Para que su turno **siempre** aporte (R5 [PO], B3):
  1. **Elegir el objetivo** al empezar su turno (en `aplicar_perfil_turno("semilla")`, y otra vez solo
     si el objetivo desaparece):
     - entre los tramos **visibles** del cauce (todas sus gotas con `0 < s < recorrido.largo`, el mismo
       filtro de `gota_en()`), el **más largo**;
     - si hay empate, el **más cercano a la cabeza** (el que más alivia el río);
     - el objetivo se recuerda por los `id` de sus gotas, no por índice (los índices cambian al
       insertar). Si mientras Maxi piensa otro tramo crece más, **el halo no salta**: un halo que se mueve
       confunde más que un tramo corto;
     - si todavía no hay gotas visibles (inicio de la ronda, entrada rápida), el halo espera a la primera,
       y el reloj de `semilla_auto_s` parte cuando aparece el halo.
  2. **Cargar a Coco con el color exacto de ese tramo** (`actual`). Vale aunque sea un secundario (si el
     nivel trae `mezclas`): la regla de munición de primarios no aplica a la bala de Maxi. La gota de
     reserva (`siguiente`) no cambia.
  3. **Su bala va al tramo objetivo, no a la primera gota que cruce**: la curva con estela es solo
     visual; al llegar, se inserta **pegada al tramo objetivo** (en el extremo más cercano a donde tocó),
     aunque en el camino pase sobre otra gota.
  4. **Umbral de su bala = 2**: la inserción de la bala de Maxi revienta con 2 o más iguales contiguas
     (tramo de 1 + su gota). Si el tramo ya medía 2 o más, el resultado es el de siempre (3 o más).
     - Es **solo para su bala y solo en la batalla**. Los retrocesos y cadenas que dispare su reventón
       siguen con el umbral normal de 3; en solitario nada cambia.
     - Lo más chico que puede pasar es que revienten 2 gotas: es su reventón, chico pero real, con la
       misma explosión, sonido y "¡justo ahí!" que uno grande.
     - Si su reventón desata una cadena, se celebra como suya y suma a la cinta; el turno se cierra
       cuando la cadena termina (estado estable, §14.15 punto 3).
     - Si la gota de Maxi era la última del cauce, gana la ronda: es el mejor final posible.
  5. **Cambio de lógica que pide** (para HE-69; esta ficha no toca el motor): un umbral por inserción,
     por ejemplo `insertar(j, posicion_bala, color, umbral := 3)` → `_reventar_en(idx, false, umbral)`,
     y un modo de inserción dirigida al tramo objetivo. `logica_rio.gd` sigue sin saber de perfiles: el
     motor pasa `umbral = 2` solo en la bala de un turno Semilla de equipo. La jugada automática de los
     20 s (M2) usa exactamente este mismo camino.
- **Cada hermano juega al menos 2 turnos por ronda (UX B2.3)** en una partida típica. `disenador-niveles`
  dimensiona las rondas con esa regla.
  - Ejemplo en Formas: con el tope, un ciclo M → N → M → S encaja hasta 7 piezas (1 + 2 + 1 + 3).
  - Si no alcanza, se suben las piezas o se baja el tope. **[07-Oct-2026, N1]** Ojo: un ciclo no
    basta; para 2 turnos de cada uno hacen falta 2 ciclos menos el último turno de Sofía más 1 pieza
    para ella (12 piezas con {1, 2, 3}). Ver "Duración", abajo.
  - En el Río: Maxi revienta 1 grupo por turno y Nicole y Sofía tiran 3 gotas.
  - **[07-Oct-2026]** En Parejas vale la misma cuenta que en Formas gracias al tope de pares: los turnos
    1-7 forman como máximo 11 pares, así que con 12 pares Sofía siempre juega su segundo turno.
- **El epílogo no usa puerta ni pista (UX M9)**:
  - el retrato de quien sigue vuela a la barra con "¡ahora Nicole!", y el siguiente toque pinta por
    ella; si pinta otro, no pasa nada;
  - son **3 partes grandes, una por hermano**, más un **cierre "¡todos juntos!"**: la tapa de la
    mochila se rellena con los tres tocando por turno su ventanita de la barra, y cada toque agrega una
    franja de su color. Nunca hay toque simultáneo (GDD §6.4);
  - **al empezar, Coco llama "¡Maxi, ven a pintar!"** y su retrato salta en la barra (M1.4). Si Maxi no
    está, un hermano pinta su parte (§4.3).

- **Por qué 3 rondas y un epílogo** [Propuesta; el PO pidió 3 o 4]:
  - 3 rondas que se pueden perder son 3 colores, que es la cuenta que el planeta ya enseña (zonas 1 a
    3).
  - El cuarto juego del planeta (Pinta) no se puede perder en ningún perfil (zonas §3.4). Por eso entra
    como **epílogo**, para no forzarle una derrota.
  - **Se pinta la mochila del Coleccionauta para regalarle colores**: es la lección del arco hecha
    juego, y la celebración más larga es justo una donde **Maxi es el mejor**.
  - Si el PO prefiere 4 rondas "de verdad", el epílogo pasa a ser la ronda 3 (sin pista de galletas,
    con una ronda de respiro) y Parejas sigue siendo la última.
- **Duración (UX HE-66, M1)**: la meta es **15 min o menos en total y 5 min o menos por ronda**, sin
  derrotas, contando pases reales de 8 a 12 s. **Tamaños vigentes [PO, 07-Oct-2026, con el simulador
  `herramientas/simular_equipo.py`]**, ya fijados en `datos/niveles/arcoiris/batalla/` (si difieren de
  esta lista, **mandan los datos**; la cuenta está en
  `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md` §4):

  | Ronda | Tamaño | Tope por turno | `pasos_rival` | Se gana al 1er intento |
  |---|---|---|---|---|
  | Río | **20 gotas**, 4 colores, 13 px/s | gotas: M 1, N 3, S 3 (racha de 3) | **7** | 86 % (sin resbalón tras racha; con él, ≥ 86 %, por simular) |
  | Formas | **12 piezas** (la nave de juguete) | {1, 2, 3} + turno perfecto + resbalón | **5** | 100 % |
  | Parejas | **12 pares en 4×6**, lupa, vistazo de 3 pares | {1, 2, 3} + turno perfecto + resbalón | **5** | **91 %** (89 % sin resbalón) |

  **[v6.1]** Cifras con el resbalón de N10, que es el modelo por defecto del simulador
  (`--sin-resbalon` = regla de la v6). Ningún `pasos_rival` cambió.

  - **Río**: el río avanza solo durante los turnos, **se detiene en el pase** y **nunca pasa del 70 %**:
    en la batalla no hay remolino que se lo trague.
  - **Formas**: 12 piezas cierran N1 (con 8, Nicole y Sofía jugaban un solo turno). El tope de Sofía
    se mantiene en 3; la alternativa {1, 2, 2} con 11 piezas queda solo como respaldo de playtest.
  - **Parejas**: 12 pares en 4×6 (no los 8 en 4×4 de la v5): el tope de pares obliga a más cartas para
    que cada uno juegue 2 turnos, y el 4×6 con Maxi ya está permitido (§5.3).
  - **Epílogo: 3 partes y el cierre "¡todos juntos!"** (M9).
  - **Curva**: Río (enseña al rival) → Formas (respiro) → Parejas (clímax). La duración estimada es
    ≈ 12 min típica y ≈ 14 min p80 (`arcoiris_final.json`, `duracion`); con una derrota, el p80 toca
    el tope de 15 min y la pausa entre rondas lo absorbe.
  - **Criterio para el playtest**: medir la duración de cada ronda y en qué ronda se va Maxi. Si se va
    antes de terminar la ronda 1, se acorta el Río.
- **Pausas naturales (M1.2)**: después del interludio de la ronda 1 y del de la ronda 2, la pantalla
  queda en el **mapa de batalla** con el hito siguiente brillando, y **no avanza sola**: para seguir, hay
  que tocar el hito.
  - Coco dice "¡ya volvió el rojo! ¿Vamos por el amarillo, o descansamos y volvemos después?".
  - La casa está a la vista. **Jugar la batalla en dos sesiones es el caso normal.**
- **Trabajo de motor**: está todo en el §14.15 (UX HE-66, M8).

### 14.4 Cómo se ve el avance de la batalla (sin números) [Propuesta]

- **Un solo indicador de batalla, sobre el propio Coleccionauta (UX HE-66, M5.4)**: la mochila-torre de
  tres pisos (rojo, amarillo y azul, de abajo hacia arriba) va **en su espalda, en la pista de galletas**.
  No hay un widget aparte. El avance **dentro** de la ronda lo muestra la cinta de la mesa del equipo, que
  se llena con gotas, piezas o pares.
- **Al ganar una ronda**:
  1. En el interludio, a pantalla completa, el piso de ese color tiembla, se infla y **estornuda**.
  2. El color sale en chorro de arcoíris y **vuelve a su banda del cielo**: el arcoíris del fondo
     recupera esa franja.
  3. La mochila-torre queda **un piso más baja**, y el Coleccionauta, más liviano, da un saltito
     ("¡uy, mi mochila está más livianita!").
  
  Es el mismo gag del estornudo de Parejas (§5.5), pero esta vez a favor del equipo.
- **Entre rondas**, un **mapa de batalla** de 3 hitos (los íconos de Río, Formas y Parejas sobre el
  camino de la isla):
  - las rondas ganadas se ven pintadas con su color;
  - la siguiente brilla;
  - Coco salta a la siguiente;
  - todos los hitos responden al toque en menos de 100 ms (se menean y Coco nombra el juego), pero
    **solo el hito que brilla lleva a jugar**. Los otros nunca saltan rondas (m3).
  
  No hay "1/3" ni barras.
- **Al final** (antes del epílogo), la mochila-torre queda **gris y vacía**, y el arcoíris del cielo,
  completo con sus tres primeras bandas.

### 14.5 Si pierden una ronda [Propuesta + UX B3, m4]

- Es la derrota-gag del §5.5, con el retrato del siguiente ya en el centro, sin nombres y con voces en
  plural. Hay una **variante por ronda**:
  - **Río**: el Coleccionauta llega a la orilla y **aspira las gotas** que quedan con su mochila-torre,
    que se atora, estornuda y las devuelve al cauce.
  - **Formas**: **aspira las piezas sueltas** de la bandeja, y salen estornudadas de vuelta, girando como
    trompos. **Caen en el estado del perfil del turno siguiente** (m2): derechas si le toca a Maxi o a
    Nicole, y giradas solo si le toca a Sofía.
  - **Parejas**: aspira las cartas (§5.5).
- **Botón "¡otra vez!" de ≥ 160 × 160 px** (m4). Al reintentar:
  - **todo lo logrado en la ronda se conserva**: gotas reventadas, piezas encajadas y parejas formadas;
  - el Coleccionauta vuelve a la galleta 0 con `pasos_rival` completo.
  
  Siempre se termina ganando.
- **Las rondas ganadas nunca se pierden**: perder la ronda 3 no devuelve el rojo ni el amarillo.
- **Cometa cierra el gag con un logro común sobre lo que se conservó en esa ronda** (m1), como "¡igual
  reventamos un montón de gotas!", "¡ya pusimos 5 piezas!" o "¡igual juntamos 6 parejas!". No sirve
  "¡igual le sacamos el rojo!", porque en la ronda 1 todavía no hay ningún color.

### 14.6 Si abandonan la batalla a la mitad [Propuesta + GDD §6.8]

- **Siempre se puede salir** con el botón casa (≥ 96 px), en cualquier momento.
- **Lo que se guarda**: las **rondas ganadas** (`Progreso`, §14.9) y si el epílogo se completó.
- **También se guarda el avance de la ronda en curso (UX HE-66, M4)**: la salida más probable es
  accidental (Maxi toca la casa o se acaba el tiempo de tablet).
  - Se guarda en `equipo.batallas.<id>.parcial`:
    - Río: las gotas que quedan y su orden;
    - Formas: los huecos llenos;
    - Parejas: los pares formados;
    - epílogo: las partes pintadas.
  - Se guarda **al terminar cada turno**, no en cada toque.
  - Al volver, el Coleccionauta parte en la galleta 0, que es lo generoso.
  - El motor lo recibe a través de `batalla.gd` con `restaurar_parcial_equipo(estado)` y lo entrega con
    `obtener_parcial_equipo()` (§14.15). El núcleo no sabe qué juego es.
  - **No se agrega confirmación para salir**, porque sería un menú (GDD §6.4).
  - **[07-Oct-2026, UX HE-66 N6] Al retomar la ronda guardada, empieza Maxi**, sea a quien sea que le
    tocaba al salir (`GestorTurnos.empezar_retomando()`, §11.4):
    - es coherente con el §4.2 ("la partida siempre empieza con Maxi");
    - el primer turno es un acierto seguro con celebración, que vuelve a encender a todos;
    - nadie discute "me tocaba a mí": la regla es fija y se ve igual cada vez;
    - el turno que se pierde es como mucho uno (el guardado es al cerrar cada turno), y el rival parte
      en la galleta 0, así que a nadie le cuesta nada.
    - Se descartó "retomar con quien le tocaba": exige guardar el puesto en el orden, y si el que
      tocaba no está sentado, el regreso arranca con un "¡esperemos a Nicole!".
    - En el epílogo vale lo mismo: se retoma con "¡Maxi, ven a pintar!", y su toque pinta la siguiente
      parte que falte, aunque la suya ya esté pintada (en el epílogo no importa quién pinta, M9).
- **Al volver**:
  - el hito de la batalla en el mapa muestra la mochila-torre con los pisos que le quedan (sin números);
  - al tocarlo, **no** se repite la cinemática de entrada;
  - **[07-Oct-2026, responde al storyboard HE-68 §10 y §14 punto 6] la pantalla "¡todos a la nave!" SÍ
    se repite al retomar**, en versión corta:
    - lo interactivo es igual (§14.7): cada hermano toca su retrato y salta a su asiento; con los tres,
      se enciende "¡Despegar!". Suena `nucleo_batalla_todos_nave` solo si nadie toca en 4 s (ya la
      conocen);
    - al tocar "¡Despegar!", la nave despega en la **versión corta, sin estrellas de cuenta regresiva
      (1,2 s)**, mientras **Cometa** dice "¡seguimos donde quedamos!" (`nucleo_batalla_retomar`), y
      sigue la intro de la ronda pendiente, que hace de recordatorio;
    - **por qué se repite**: la batalla es de los tres [PO], y volver otro día es justo el momento de
      reunirlos; el gesto de "cada uno toca su carita" es el ritual que dice "empezamos juntos" y cuesta
      3-5 s. Saltarlo haría que un toque suelto en el hito (por ejemplo, de Maxi solo) metiera a la
      familia directo en la ronda, sin la invitación a reunirse (ver m4). También mantiene una sola entrada a la batalla, siempre igual (más fácil de
      aprender para Maxi).
- **Si un hermano tiene que irse a la mitad**:
  - se sale con la casa;
  - las rondas ganadas quedan, y la batalla sigue otro día con los tres;
  - mientras tanto, cada uno sigue jugando su ruta normal: la batalla nunca bloquea nada.

### 14.7 Cuándo se desbloquea y cómo se entra [PO: primer hermano con el ala, solo los tres; Propuesta: lo demás]

**Cómo se cierra hoy el planeta** (revisado):

- **GDD §3**: la pieza llega al completar la zona 3, y las zonas 4-5 son expedición extra.
- **`mapa.json`**: `pieza_nave.zonas: [1, 2, 3]`, con la nota "la pieza llega al completar la zona 3".
- **Ficha de zonas §2.1-2.2**: escena del ala más video-llamada de papá en la zona 3, y "planeta
  completo" al terminar la zona 5.
- **Progreso**: la pieza y las zonas son **por hermano**.

**Diseño** (el momento del desbloqueo es [PO]; el resto, aceptado con la validación UX de HE-66):

- **Aparece cuando el primer hermano recibe el ala**, al completar su zona 3. Es el momento en que la
  historia del planeta llega a su clímax.
- La escena del ala **termina con un teaser**: en la video-llamada de papá se cuela el Coleccionauta
  ("¿un planeta que recupera colores? ¡Para mi colección!"), y en el mapa aterriza su mochila-torre.
- **No espera a que los otros dos completen su zona 3**: con desbloqueo generoso, la batalla usa
  niveles propios con la dificultad de cada uno, así que Maxi puede jugarla aunque vaya en la zona 1.
- **Las zonas 4 y 5 siguen siendo expedición extra**: la batalla no las bloquea ni depende de ellas.
  Después de la batalla, el planeta sigue jugable entero.
- **[PO]**: se abre con **el primer hermano que recibe el ala**.

**La batalla no condiciona nada (UX HE-66, M7)**. Es una regla de capítulos: la batalla pide a los tres
juntos, que es una condición social, y entonces no puede trabar a nadie.

1. **El viaje al planeta 2 depende solo de la pieza** (la zona 3 de cada hermano), nunca de la batalla.
2. **El gancho canónico del planeta 2 sigue en la video-llamada de la escena del ala**, que cada hermano
   ve por su cuenta. La video-llamada del cierre de la batalla es un **extra familiar** (papá ve la foto
   de los tres), no el único cierre del capítulo.
3. Hasta que se gane, **el hito de la batalla es una invitación, no un pendiente**: no tiene signos de
   alerta, no parpadea y su voz suena como máximo una vez por visita al mapa.
4. **El ala no se gana en la batalla** (nota para HE-17).

**El hito en el mapa**:

- En el **Claro del Trébol** (zona 1, abierta para todos), junto a la nave estacionada de los
  hermanos, aparece la **mochila-torre gris** con el Coleccionauta, que asoma y saluda.
- Está a la vista en el mapa de **cualquier** hermano.
- Es tocable (≥ 120 px), respira y se ve chistosa, no amenazante. Lo describe el bloque `batalla` de
  `mapa.json` (§14.9).

**Entrar a la batalla**:

1. Al tocar el hito, Cometa dice "¡Es el Coleccionauta! Para ganarle necesitamos a los tres. ¿Están
   todos?".
2. **Pantalla "¡todos a la nave!"**: los tres retratos en grande. **Cada hermano toca el suyo** y salta a
   su asiento (como en "armar equipo", pero sin poder sacar a nadie). Cuando están los tres, se enciende
   "¡Despegar!", en el mismo rectángulo que "¡Juntos!" (M5.4).
3. La batalla **es de los tres [PO: "los tres tienen que aportar"]**. Si falta uno, Cometa dice "¡lo
   esperamos! La batalla es de los tres", y se puede volver al mapa sin perder nada.
   - **[PO]**: la batalla se juega **solo con los tres hermanos**. No hay opción de jugarla con dos
     (`minimo_hermanos: 3`, fijo).
   - **Qué significa "los tres" (m8)**: juegan **los tres retratos**. El juego no puede verificar
     quién está físicamente, así que `minimo_hermanos` se refiere solo a los retratos. Si Maxi se duerme
     a la mitad, un hermano mayor juega su turno guiado (§4.3), sin cambiar la decisión del PO.
   - **Arranque de Maxi solo (m4)**: nada impide que Maxi toque los tres retratos y entre solo. Si en el
     turno de un hermano mayor nadie abre la puerta después de los 2 recordatorios (m5 de HE-58), Coco
     dice "¡esperemos a Nicole!", y **la casa se agranda un 10 % y respira**. Salir no cuesta nada
     (M4).
4. **Después de "¡Despegar!" va la cinemática de entrada** (≤ 12 s; se puede saltar desde la segunda
   vez, por familia, §11.5) y **la ronda 1 arranca sola**, sin pedir un toque en el mapa de batalla
   **[07-Oct-2026; responde al storyboard HE-68 §14 punto 5]**: al terminar la entrada, Coco aterriza
   en el hito del Río y empieza la intro de la ronda. Motivo: acaban de tocar "¡Despegar!"; pedir otro
   toque en el mapa sería una pausa sin decisión. **Las pausas del M1.2 se mantienen entre la ronda 1 y
   la 2, y entre la 2 y la 3**: ahí sí hay una decisión real (seguir o descansar). El storyboard (§15.5)
   también la llevaba al PO como duda: **[PO, 07-Oct-2026] confirmado, arranca sola**. Si el playtest
   pide el toque, basta con poner `"pausa_antes_ronda_1": true` en `arcoiris_final.json` (por defecto `false`).

### 14.8 El premio [PO: "¡Juntos!"; Propuesta: lo demás]

| Premio | Para quién | Por qué es coherente |
|---|---|---|
| **El botón "¡Juntos!"** en la selección, con su presentación única (M5.2) [PO] | La familia | Ganaron juntos, y desde ahora pueden jugar juntos cuando quieran (cualquier zona, §3.3) |
| **El arcoíris del cielo vuelve, y el Coleccionauta se va con la mochila pintada de colores** | El planeta | Cierra el arco del planeta: se ve, sin palabras |
| **Una "miga de papá" familiar**: una foto de **los tres hermanos juntos** (álbum familiar) | Los tres (los recuerdos familiares son de todos, `album-recuerdos.md` §3) | El álbum familiar admite fotos "de a dos o tres hermanos". Premia **lo que hicieron juntos**, y no compite con la pieza (el ala ya trajo su foto familiar en la zona 3). Agrega un momento `batalla` al catálogo; los familiares pasan de 9 a 10, dentro del rango de la ficha (8-10). **El PO elige y graba la foto y su audio** (privacidad: fuera del repo) |
| **100 destellos** para cada hermano, una sola vez | Cada uno, por igual | Igual que una estación (economía HE-40 §7.3). **[Propuesta]**, aceptada por ahora por el PO |
| **No hay pieza de la nave** | — | La pieza del planeta ya llegó con el ala (zona 3). Darla de nuevo rompería la regla de "una pieza por planeta" de la nave aprobada (HE-A6) |

### 14.9 Datos y guardado (para `dev-godot`)

**`mapa.json`**: bloque nuevo `batalla`.

```jsonc
"batalla": {
  "id": "arcoiris_batalla_final",
  "datos": "res://datos/batallas/arcoiris_final.json",
  "escena": "res://escenas/nucleo/batalla.tscn",
  "aparece_tras_zona": 3,              // número de zona
  "condicion": "primer_hermano",       // [PO]
  "posicion": [260, 380],              // junto a la nave estacionada en el Claro
  "voz_hito": "PENDIENTE"
}
```

**`datos/batallas/arcoiris_final.json`** (nuevo):

```jsonc
{
  "id": "arcoiris_batalla_final",
  "planeta_id": "arcoiris",
  "minimo_hermanos": 3,                // [PO] solo con los tres
  "destellos_por_hermano": 100,        // [Propuesta]
  "recuerdo_momento": { "tipo": "batalla", "planeta": "arcoiris" },
  "orden": "maxi_intercalado",
  "cinematica_entrada": "entrada",     // ids de animación del storyboard HE-68 §14.1 (hoy "PENDIENTE" en datos)
  "cinematica_antes_epilogo": "antes_epilogo",
  "cinematica_cierre": ["cierre_a", "cierre_b"],
  "pausa_antes_ronda_1": false,        // 07-Oct-2026: la ronda 1 arranca sola tras la entrada (§14.7)
  "pausa_entre_rondas": true,          // M1.2: entre rondas hay que tocar el hito
  "retomar_empieza": "maxi",           // N6: informativo; el gestor siempre retoma con Maxi (§11.4)
  "rondas": [
    { "id": "rio",     "color": "rojo",     "escena": "res://escenas/minijuegos/rio/motor_rio.tscn",
      "nivel": "res://datos/niveles/arcoiris/batalla/rio_equipo.json" },
    { "id": "formas",  "color": "amarillo", "escena": "res://escenas/minijuegos/encajar/motor_encajar.tscn",
      "nivel": "res://datos/niveles/arcoiris/batalla/formas_equipo.json" },
    { "id": "parejas", "color": "azul",     "escena": "res://escenas/minijuegos/emparejar/motor_emparejar.tscn",
      "nivel": "res://datos/niveles/arcoiris/batalla/parejas_equipo.json" }
  ],
  "epilogo": { "escena": "res://escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn",
               "nivel": "res://datos/niveles/arcoiris/batalla/pinta_mochila_equipo.json" }
}
```

- Cada nivel de ronda lleva `"modo_juego": "equipo"` y el bloque `equipo` del §8, con `pasos_rival`
  propio. El del epílogo lleva `"rival": null` y `"confirmar_turno": false` (sin puerta, M9).
- **Campos de equipo nuevos por ronda** (UX HE-66):
  - **Río**:
    - `"gotas_por_turno": {"semilla": 1, "brote": 3, "estrella": 3}`;
    - `"sin_fallo": true`;
    - `"carga_con_pareja": true`;
    - `"intercambio_semilla": false`;
    - `"tope_avance": 0.7`;
    - `"recorrido": "res://datos/recorridos/arcoiris/batalla_espiral.json"` (§14.15, M5.2);
    - **[v6.1]** `"resbalon_tras_racha": true` en el bloque `equipo`, **cuando `disenador-niveles` lo
      haya simulado** (§5.2). Hasta entonces, ausente (= `false`).
  - **Formas**:
    - `"aciertos_max_turno": {"semilla": 1, "brote": 2, "estrella": 3}`;
    - `"zona_figuras": [150, 128, 700, 456]`;
    - `"zona_bandeja": [880, 128, 360, 456]` (y 128-584; corregidas el 07-Oct-2026, UX HE-66 N3, ver
      §14.15);
    - la capa Semilla con las reglas de su ruta: `toque_lleva_a_casa`, `iman_tolerancia_px: 5000` y
      `sin_error`.
  - **Todas**: `"semilla_auto_s": 20` (M2), en el bloque `equipo`.
- **Campos que agregó la calibración (07-Oct-2026), aceptados por `disenador-mecanicas`**:
  - **Río**: `guia_por_perfil` (lo lee `aplicar_perfil_turno`), `carga_semilla: "tramo_mas_largo"` y
    `umbral_reventon_semilla: 2` (N2, §14.3), `cadena_vale_aciertos: 2`, `justo_ahi_px: 150` (B3.2) y
    `rio_se_detiene_en_pase: true` (punto 4 del trabajo de motor, §14.15);
  - **Formas**: `capas_perfil` (una capa por perfil con las reglas de su ruta; reemplaza la lista suelta
    de arriba), `soltar_en_vacio_es_fallo: false` (B2.2) e `id` por pieza (lo usa el parcial M4);
  - **Parejas**: `especiales[].variante` (p. ej. `"lupa_coleccionauta"`, solo arte y voz; la regla de la
    lupa no cambia) y **`composiciones.<clave>.pares_max_turno`** [PO] (§5.2, §8);
  - **Epílogo**: `orden_fijo`, `parte_por_hermano`, `cierre_todos_juntos` y `color_inicial_por_perfil`;
  - **Batalla**: `retomar_empieza` (N6), `pausa_entre_rondas` (M1.2) y los informativos `motor`,
    `resumen`, `duracion` y `premio`, que `batalla.gd` ignora (la fuente de verdad de cantidades, topes
    y pasos es el nivel de cada ronda).
- **`pasos_rival` en las rondas** va dentro de `equipo.composiciones["maxi+nicole+sofia"]`, igual que en
  Parejas. Como la batalla es solo de los tres, es la única composición.

**Escena genérica `escenas/nucleo/batalla.tscn` + `scripts/nucleo/batalla.gd`**:

- Lee el JSON de la batalla, muestra el mapa de batalla y la mochila-torre (§14.4), e **instancia la
  `escena` de cada ronda** con `ruta_nivel`, `planeta_id`, `equipo = ["maxi", "nicole", "sofia"]` y
  `destellos_fijos = 0`. Las rondas sueltas no dan destellos: el premio es de la batalla.
- Escucha `completado` (ronda ganada) y `salir_solicitado`.
- Reproduce las interludios y las cinemáticas.
- **No sabe qué juego es cada ronda**: solo rutas. El núcleo sigue sin conocer minijuegos (regla de
  oro 4).
- Las rondas ganadas en la batalla **no** cuentan como victorias de "nivel de equipo" (`ganados`, §7.3),
  ni encienden las estrellitas del botón. Son contenido aparte.

**`Progreso`**: se suma al bloque `equipo` de la v3 (§11.5), sin otra migración.

```jsonc
"equipo": {
  // … §11.5 …
  "batallas": {
    "arcoiris_batalla_final": {
      "rondas_ganadas": ["rio"],        // ids de ronda; nunca se borran
      "epilogo": false,
      "ganada": false,                  // true al terminar el epílogo
      "premiados": [],                  // hermanos que ya cobraron sus destellos
      "parcial": {                      // M4: ronda en curso; se escribe al terminar cada turno y se borra al ganarla
        "ronda": "formas",
        "estado": {}                    // lo que entregó el motor con obtener_parcial_equipo(); el núcleo no lo interpreta
      }
    }
  }
}
```

```gdscript
func registrar_ronda_batalla(id_batalla: String, id_ronda: String) -> void
func obtener_rondas_batalla(id_batalla: String) -> Array
## Marca ganada, paga destellos_por_hermano a quien no esté en "premiados" y devuelve los premiados.
func registrar_batalla_ganada(id_batalla: String, planeta_id: String, ids: Array[String], destellos_por_hermano: int) -> Array[String]
func batalla_ganada(id_batalla: String) -> bool
func guardar_parcial_batalla(id_batalla: String, id_ronda: String, estado: Dictionary) -> void   # M4
func obtener_parcial_batalla(id_batalla: String) -> Dictionary                                  # {} si no hay
func borrar_parcial_batalla(id_batalla: String) -> void
## true si hay al menos una batalla ganada: la selección muestra "¡Juntos!" (§3.1).
func modo_equipo_desbloqueado() -> bool
```

- **La foto**: `batalla.gd` llama a `Recuerdos.desbloquear({"tipo": "batalla", "planeta": "arcoiris"},
  "")` al ganar, igual que hace hoy la selección con `primera_apertura`. Hay que agregar el tipo
  `batalla` a la ficha del álbum §8.
- **Arnés de QA** (`tester-qa`): `qa_test_batalla_arcoiris.gd`, que respalde `progreso.json` y
  verifique:
  - la aparición tras la zona 3;
  - las rondas guardadas y retomadas;
  - el reintento que conserva lo logrado;
  - los destellos una sola vez;
  - la foto;
  - "¡Juntos!" visible solo después de ganar;
  - que las zonas 4-5 nunca se bloquean;
  - el parcial por turno: salir y volver restaura la ronda (M4);
  - **que con un nivel de batalla cargado ningún texto con dígitos se dibuja en la escena del motor**
    (M8.5, R2);
  - que el mapa de cada hermano no pierde color (M3);
  - que la batalla no condiciona el viaje al planeta 2 (M7);
  - el tope de aciertos y los ≥ 2 turnos por hermano (B2);
  - que en el Río no hay fallo y Coco nunca carga un color sin pareja (B1);
  - el turno de Maxi con las reglas de su ruta y el turno resuelto solo a los 20 s (B3 y M2);
  - **[07-Oct-2026, UX HE-66 N2] el reventón de Maxi en el Río**, con `LogicaRio` determinista
    (semilla fija), en estos casos:
    - **cauce sin ningún tramo de 2** (solo gotas sueltas de colores alternados), turno de Maxi → Coco
      carga el color del objetivo y su bala **revienta 2 gotas**;
    - cauce con un tramo de 2 y otros de 1 → el halo va al de 2 y revientan 3;
    - empate de tramos más largos → gana el más cercano a la cabeza;
    - una sola gota en el cauce → revienta y la ronda se gana;
    - la bala pasa sobre otra gota en el camino → igual se inserta en el tramo objetivo;
    - la jugada automática de los 20 s → mismo resultado que el toque;
    - **contraprueba**: en el turno de Nicole o de Sofía, y en el Río en solitario, un tramo de 1 + una
      gota **no** revienta (umbral 3 intacto);
  - **[07-Oct-2026, N3]** las separaciones de 24 px o más entre lo tocable del motor (zonas de Formas,
    cauce y reserva de Coco del Río) y la casa, Cometa y la barra del equipo (§14.15);
  - **[07-Oct-2026, PO]** el retroceso: turno perfecto en Formas y Parejas (Nicole 2, Sofía 3, también
    tras el besito; nunca Maxi; mínimo galleta 0; la `racha_retrocede_rival` de esos niveles se ignora)
    y racha de 3 en el Río (una cadena vale 2; un reventón de Maxi con cadena **no** mueve al rival);
  - **[v6.1, PO, UX N10] el resbalón en la batalla**:
    - Formas y Parejas: después de un turno perfecto de Nicole o de Sofía, el paso 2 emite
      `rival_resbalo()` y la posición del rival **no cambia** (neto del turno: −1, o 0 en la galleta 0);
      después de un turno sin perfecto, +1 como siempre; nunca `rival_llego` tras un turno perfecto;
    - Río con `resbalon_tras_racha: true`: un turno con al menos un retroceso por racha → resbalón en
      el pase (uno solo, aunque haya retrocedido dos veces); un turno sin retroceso → +1; el turno de
      Maxi con cadena → ni retroceso ni resbalón. **Contraprueba**: sin el campo, el pase avanza +1;
    - la animación `resbalar` dura 1,1 s, empieza junto con el vuelo del retrato y no retrasa la
      puerta (la puerta se puede abrir mientras él sigue sentado); si el turno empieza antes de que
      termine (puerta abierta muy rápido), el resbalón termina igual hasta el "plof" y recién después
      se para y se sacude: el "plof" nunca se corta;
  - **[v6.1, N9]** la guirnalda en Formas y en Parejas (casos del arnés de Parejas, §10) y su ausencia
    en el Río y en el epílogo;
  - **[07-Oct-2026]** la derrota-gag de cada ronda, con "¡otra vez!" tocado al principio, a la mitad y
    al final del gag: el estado final es el mismo y lo conservado no cambia;
  - **[07-Oct-2026]** retomar: "¡todos a la nave!" corto, sin cinemática de entrada, y primer turno de
    Maxi; la cinemática vista se guarda en `equipo.cinematicas_vistas` (por familia) al terminarla.

### 14.10 Qué hace falta de cinemáticas (para `director-cinematicas`)

Solo se enumeran; el storyboard es de `director-cinematicas`.

**Duraciones topes (UX HE-66, M1.3)**:

- entrada: 12 s o menos;
- antes del epílogo: 5 s o menos;
- cierre partido en dos, y cada parte se puede saltar con un toque desde la segunda vez;
- intros de ronda de **una frase** (4 s o menos).

1. **Teaser** al final de la escena del ala (zona 3): el Coleccionauta se cuela en la video-llamada de
   papá y su mochila-torre aterriza en el Claro. Unos 8 a 10 s, y extiende la escena existente.
   **Papá se ríe** cuando el Coleccionauta se cuela, así nadie lee "papá está en peligro" (m7).
2. **Entrada de la batalla**: el Coleccionauta aspira las tres bandas del cielo **de la escena** (nunca
   las del mapa, M3) con su mochila-torre, y los colores quedan contentos en los pisos transparentes. Coco
   dice "¡los vamos a sacar juntos!". **12 s o menos**. Se puede saltar con un toque desde la segunda
   vez.
3. **Interludio entre rondas** (motor, no video): el piso estornuda, el color vuelve al cielo y Coco
   salta al hito siguiente en el mapa de batalla. 3 a 4 s, tres veces.
4. **Gags de derrota por ronda** (motor): aspira y estornuda gotas, piezas o cartas (§14.5).
5. **Antes del epílogo**: la mochila-torre gris y vacía, el Coleccionauta sentado con cara de "¿y ahora
   qué colecciono?", y Coco con la idea de pintarle la mochila. **5 s o menos.**
6. **Cierre de temporada, en dos partes que se pueden saltar** (M1.3):
   - **Parte A (20 s o menos)**:
     - el Coleccionauta, con la mochila pintada, se mira encantado, dice que "un equipo no cabe en una
       mochila" y se despide prometiendo volver "con una mochila más grande" (gancho de HE-39);
     - la fiesta de los tres (§5.6).
   - **Parte B**:
     - la entrega de la foto (ficha del álbum §6);
     - una **video-llamada de papá como extra familiar**: papá ve la foto de los tres. **El gancho
       canónico del planeta 2 sigue en la escena del ala** (M7.2);
     - al volver a la selección, la nave "¡Juntos!" entra volando (M5.2).

### 14.11 Qué hace falta de voces (para `guionista`)

Solo se enumeran, y todas van **en plural y sin nombres en los fallos** (B2, B3):

- Cometa en el hito y en "¡todos a la nave!": "¿Están todos?", "¡Lo esperamos!" y "¡seguimos donde
  quedamos!".
- El Coleccionauta (grabación casera de papá):
  - el teaser;
  - la entrada (aspira los colores);
  - una presentación por ronda;
  - un "¡uy, mi mochila está más livianita!" por piso;
  - los gags de derrota de Río y Formas (los de Parejas ya existen);
  - el antes del epílogo;
  - la despedida con el gancho de HE-39.
- Coco:
  - la intro corta de cada ronda (la regla de turno de ese juego, en una frase). **[v6.1, UX N8] En
    las rondas con tope (Formas y Parejas), esa frase explica el tope por voz**: dice que el turno
    sigue con cada acierto **hasta prender las lucecitas** (sin números, ≤ 4 s), y nunca "si hay
    pareja, sigues jugando" a secas. La `repetir` de Cometa de esas rondas suma "…y si prendes todas
    tus lucecitas, ¡turno perfecto!". En el Río la intro no nombra lucecitas (no hay guirnalda);
  - **[v6.1, UX N13]** "¡guárdala para tu próximo turno!" (`guardala_proximo_turno`, solo Parejas);
  - un "¡volvió el rojo!", "¡volvió el amarillo!" y "¡volvió el azul!" por color (con su tic de color);
  - la idea del epílogo ("¡regalémosle colores!");
  - la celebración final.
- Cometa, **[v6.1, UX N8]**: `turno_perfecto_presenta`, la variante del primer turno perfecto de la
  familia, que dice qué pasó ("¡prendiste todas tus luces y el Coleccionauta se resbaló!") (§5.2).
- Cometa: tras cada derrota de ronda, **un logro común sobre lo conservado en esa ronda (gotas, piezas
  o parejas), ver §14.5**, y "¡Equipo estelar!" (ya existe). **[Corregido 07-Oct-2026, UX HE-66 N4]**:
  aquí se pedía "¡igual le sacamos el rojo!", línea descartada por m1 (en la ronda 1 todavía no hay
  ningún color); **no se graba**.
- Las líneas de turno de Maxi en Río y en Formas ("¡Maxi, toca donde quieras!" y "¡Maxi, la pieza que
  brilla!").
- La video-llamada de cierre de papá: **grabación familiar**, si el PO lo decide (backlog del álbum §9,
  idea 4).

**Antes de generar cualquier TTS: `--estimar` y OK del PO sobre el costo.**

### 14.12 Cómo encaja con HE-39 (la prueba final cooperativa)

| | **Batalla de Arcoíris** (la primera) | **Prueba final, HE-39** (la última) |
|---|---|---|
| Dónde | Planeta 1, al cerrar el capítulo 1 | Planeta del Coleccionauta, al reunir las 6 piezas |
| Qué establece | El idioma de las batallas: pista de galletas, mochila-torre, turnos con puerta, gags de estornudo, rondas que se conservan y "nadie tiene la culpa" | Lo reutiliza todo (`batalla.gd` y un JSON propio) con una ronda por planeta visitado, y suma lo que el GDD §1 le reserva: "Sofía lee la pista y arma el plan" y "Nicole se gana la confianza" del Coleccionauta |
| El Coleccionauta | Aprende que "un equipo no cabe en una mochila" y se va con colores regalados | Cierra el arco: aprende que los amigos no se coleccionan, se hacen, y devuelve a papá |
| Premio | "¡Juntos!" y una foto de los tres | El rescate y la última foto familiar (álbum §4) |

- **Capítulos 2 a 6** [Propuesta, aceptada por ahora por el PO]: **solo hay batalla en Arcoíris y en
  HE-39**. `batalla.gd` y sus datos dejan abierta la puerta de sumar otras batallas si un capítulo lo
  pide, pero eso sería una decisión nueva.

### 14.13 Riesgos para UX: estado tras la validación de HE-66

La validación `docs/validaciones/2026-10-06_ux-HE-66-batalla-arcoiris.md` revisó los seis riesgos del
diseño, y sus correcciones están incorporadas:

| Riesgo | Corrección |
|---|---|
| 1. Duración | M1 y M2 |
| 2. La batalla es de los tres | m8 |
| 3. "El juego jugó por mí" en el Río | B3 |
| 4. La pista tapa el río | M5 |
| 5. Tono del Coleccionauta | m7 |
| 6. El cielo gris | M3 |

**Foco de la auditoría sobre el build**:

- la duración real por ronda y en qué momento se va Maxi (M1);
- si Maxi siente suyo el reventón del Río (B3);
- si alguien dice "nos robó lo que ganamos" (M3);
- que no se vea ningún número en las rondas (M5.5 y M8.5).

### 14.14 Estado de las decisiones de la batalla (actualizado 07-Oct-2026)

| Tema | Estado |
|---|---|
| Desbloqueo con el primer hermano que recibe el ala | **[PO]** |
| Solo con los tres hermanos | **[PO]** |
| Tope de aciertos {1, 2, 3} también en Parejas; retroceso por turno perfecto en Formas y Parejas | **[PO, 07-Oct-2026]** |
| En el Río sigue la racha de 3 | `disenador-mecanicas`, dentro del marco del PO (§5.2) |
| "Se resbala y no avanza" en el pase que sigue a un turno perfecto (UX N10) | **[PO, 07-Oct-2026]**, sin cambiar `pasos_rival` |
| El resbalón también tras un retroceso por racha en el Río (`resbalon_tras_racha`) | `disenador-mecanicas` (v6.1); pendiente de simular por `disenador-niveles` |
| La meta del turno en pantalla: guirnalda de lucecitas al costado de la mesa (UX N9) | `disenador-mecanicas` (v6.1), sobre la propuesta de UX; la audita UX |
| Fila inferior de 4×6 a 10 px de la barra (UX N12) | Aceptada como excepción por `disenador-mecanicas` (v6.1), con dos condiciones de hitbox; la audita UX |
| Carta tocada en la fiesta: guiño + "¡guárdala…!" una vez por partida (UX N13) | `disenador-mecanicas` (v6.1); texto del `guionista` |
| La intro de las rondas con tope explica el tope por voz (UX N8) | `disenador-mecanicas` (v6.1); textos del `guionista` (HE-67) |
| Tamaños: Río 20 gotas / 7 pasos, Formas 12 piezas / 5 pasos, Parejas 12 pares 4×6 / 5 pasos | **[PO, 07-Oct-2026]**, con el simulador |
| El besito de Coco no rompe el turno perfecto | [PO, 07-Oct-2026] confirmado |
| "¡Todos a la nave!" se repite al retomar; "cinemática vista" por familia; la ronda 1 arranca sola | `disenador-mecanicas` (07-Oct-2026); la última también es la duda 5 del storyboard al PO |
| 100 destellos por hermano | [Propuesta], aceptada por ahora |
| Solo hay batalla en Arcoíris y en HE-39 | [Propuesta], aceptada por ahora |
| 3 rondas más el epílogo de Pinta | [Propuesta], aceptada por ahora |
| La foto familiar de los tres (el PO la elige y la graba) | [Propuesta], aceptada por ahora |
| El Coleccionauta aspira las bandas del cielo | [Propuesta], aceptada por ahora. **UX lo aprueba con M3**: el robo es solo dentro de la escena y el mapa nunca pierde color. El respaldo es que traiga colores de otro lado |

### 14.15 Correcciones de UX HE-66: layout, trabajo de motor, voces y "Para Dev"

#### Layout de las rondas de batalla, con las medidas reales (M5)

| Zona | Rect | Contenido |
|---|---|---|
| Pista | `Rect2(0, 0, 1280, 100)` | Cometa `Rect2(8, 4, 110, 96)` (repite, M6); galletas x 130-930 con el Coleccionauta y su **mochila-torre en la espalda** (el único indicador de batalla, M5.4); mesa con la cinta x 940-1150 (no tocable); casa `Rect2(1172, 8, 100, 96)` |
| **Zona de juego común** | **`Rect2(0, 110, 1280, 490)`** (y 110-600) | La ronda. Con m5: cualquier elemento tocable del motor queda a 24 px o más de Cometa y de la casa |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` | Los retratos (§4.1) |

- **Río**: usa un **recorrido propio**, `datos/recorridos/arcoiris/batalla_espiral.json`.
  - El de la zona 1 (`z1_espiral.json`) sube hasta y ≈ 72, baja hasta y ≈ 696 y entra desde (160,
    800): lo taparían la pista y la barra.
  - Punto de partida: centro (640, 355), `radio_inicio` 230, `radio_fin` 120, `escala` [2.0, 0.9],
    radio de gota 22, y **entrada desde la izquierda en y ≈ 560**.
  - QA verifica que el cauce, con su glaseado, quede entre y 112 y y 598.
- **Formas** **[corregido 07-Oct-2026, UX HE-66 N3]**: `zona_figuras: [150, 128, 700, 456]` y
  `zona_bandeja: [880, 128, 360, 456]`, las dos en y 128-584.
  - Las cifras anteriores (y 118-592) dejaban la bandeja a **14 px** de la casa (que termina en y 104)
    y las dos zonas a **18 px** de las ventanitas de la barra (que empiezan en y 610), contra la regla
    de 24 px de esta misma tabla. Justo ahí Maxi toca la pieza con halo en su turno.
  - Ahora quedan **24 px** bajo la casa y Cometa (104 → 128) y **26 px** sobre la barra (584 → 610).
  - La pieza de Maxi con lado corto ≥ 110 px sigue cabiendo de sobra en 456 px de alto.
  - **QA mide** las dos separaciones en Formas, y en el Río verifica que **ningún punto del cauce ni
    de la reserva de Coco** quede a menos de 24 px de la casa o de Cometa (el disparo cubre toda la zona
    común, así que el toque de Maxi puede caer en cualquier parte).
- **En las rondas de batalla no se dibuja el HUD propio de cada motor** (M5.5, R2):
  - Río: ni la píldora de puntos y récord, ni la barra de río, ni "+N", ni "¡Cadena x3!", ni el cartel
    "¡Glu glu glu!";
  - Formas: ni las ranuras, ni las medallas, ni los destellos por pieza.
- **Repite la instrucción: Cometa** (M6), en todas las rondas y también en Parejas en equipo fuera de la
  batalla. El Coco de cada motor conserva su función: en el Río dispara o cambia la gota, y en Formas
  reacciona.

#### Trabajo de motor que falta (M8, para estimar HE-69)

**Comunes a `rio` y `encajar`**:

1. **`aplicar_perfil_turno(perfil)`**, llamado en `turno_iniciado`. Hoy los dos motores leen la
   configuración por perfil **una sola vez**.
   - **Río** (`_configurar_desde_nivel` lee `_guia`):
     - la guía;
     - el intercambio permitido (apagado en Semilla);
     - la carga con pareja (B1.4);
     - las gotas del turno (B1.1);
     - el halo sobre el grupo objetivo y la "lengua hacia el dedo" de Maxi (B3.2);
     - **[07-Oct-2026, N2]** el reventón de Maxi: objetivo = tramo visible más largo, carga del color
       exacto, inserción dirigida y umbral 2 solo para su bala (§14.3, "Reventón de Maxi en el Río").
   - **Formas**:
     - `_sin_error`, `_iman` y `toque_lleva_a_casa`;
     - `_rotacion_por_toque` y `_enderezar`;
     - `_objetivo_guiado`, `_lado_minimo_bandeja` y `_giro_cuenta_fallo`;
     - el resaltado del hueco cercano en `_al_mover`;
     - el **"fiu" visible** que endereza (Nicole y Maxi) o gira al azar (Sofía) las piezas de la
       bandeja al empezar el turno. Las piezas nunca cambian sin animación.
2. **`obtener_perfil_dificultad()` devuelve el perfil del turno en equipo**, igual que
   `obtener_id_personaje()` (§11.3). Va en `minijuego_base`.
3. **El turno termina en un estado estable**:
   - en el Río, `terminar_turno()` se llama solo **sin balas en vuelo ni retroceso en curso**. Si no,
     la cadena se le acredita al hermano siguiente;
   - en Formas, una pieza "flotando chueca" (Sofía, 2,5 s) se resuelve antes de cerrar el turno.
4. **Pausa real**: con `entrada_bloqueada_cambio(true)`, el Río detiene `logica.avanzar()` y las balas,
   también durante el ritual de Maxi y el pase.
5. **En equipo se apaga todo lo individual**:
   - el récord, las estrellitas y los destellos por pieza;
   - la derrota propia (el remolino del Río y `limite_intentos` de Formas);
   - el guardado parcial por perfil (`_guardar_piezas_ronda` usa `id_perfil`, que en equipo está
     vacío), que se reemplaza por el parcial de equipo de M4;
   - `celebrar()`.

   Al ganar, el motor **solo emite `completado`** y `batalla.gd` hace el interludio. En el Río, el
   remolino no pulsa en rojo y Coco no suda ni tiembla: con el tope del 70 %, esa señal de peligro no
   corresponde.
6. **Parcial de equipo (M4)**: `obtener_parcial_equipo() -> Dictionary` (al terminar cada turno) y
   `restaurar_parcial_equipo(estado: Dictionary)`, en los dos motores y también en `emparejar` y en
   `lienzo_libre`.
7. **Turno resuelto solo** (`semilla_auto_s`, M2): cada motor implementa la "jugada automática" de
   Maxi, y el `GestorTurnos` la dispara.
8. **QA obligatoria**: con un nivel de batalla cargado, **ningún texto con dígitos** se dibuja en la
   escena del motor.
9. **Derrota-gag [07-Oct-2026]**: cada motor implementa los virtuales `gag_derrota_aspirar(destino)`,
   `gag_derrota_devolver(perfil_siguiente)`, `gag_derrota_terminar_ya(perfil_siguiente)`,
   `reintentar_equipo()` y `contar_logro_equipo()`; la secuencia la orquesta `minijuego_base` (firmas y
   orden en el §11.4). Río: aspira las gotas que quedan y las devuelve al cauce en su orden. Formas:
   aspira las piezas sueltas de la bandeja y las devuelve en el estado de `perfil_siguiente` (m2).
   Parejas: aspira las cartas pendientes y las devuelve tapadas; `reintentar_equipo()` las revuelve y
   hace el vistazo (§5.5).
10. **Tope en Parejas [PO, 07-Oct-2026]**: `emparejar` pasa `pares_max_turno` al gestor como
    `aciertos_max_turno` (§8) y responde `tope_alcanzado` con `confirmar_turno_estable()` cuando el par
    ya voló a la cinta. **[v6.1, UX N9]** La meta del turno se ve en la guirnalda de lucecitas del
    gestor (§4.1), no en la cresta de Coco: `emparejar` y `encajar` solo implementan
    `ancla_meta_turno()` (§11.4).
11. **[v6.1, UX N12 y N13] `emparejar` en equipo con 4 filas**: separación de 10 px (cartas de
    110,5 px), hitbox de la fila inferior recortada a y ≤ 604, mesa dibujada bajo la barra (§4.1); y,
    tras `turno_cerrado(id, true)`, el guiño de carta y `guardala_proximo_turno` (§4.3).

**Además**:

- `lienzo_libre`: turnos de una parte por turno, **sin puerta ni pista** (`confirmar_turno: false`,
  `rival: null`) y la paleta con muestras ≥ 96 px (M9).
- `GestorTurnos` (§11.4) suma cuatro cosas, con sus **firmas exactas en el §11.4** (07-Oct-2026,
  UX HE-66 N5):
  - `semilla_auto_s` → `signal jugada_automatica_pedida()`;
  - `aciertos_max_turno`: al llegar al tope, el gestor bloquea la entrada y emite `tope_alcanzado()`;
    el motor responde `confirmar_turno_estable()` y el turno termina con "¡turno perfecto!", sin fallo;
  - un modo sin puerta, para el epílogo (`confirmar_turno: false` + `rival: null` → `sin_puerta()`);
  - el parcial: `signal turno_cerrado(id_hermano, perfecto)` (que `minijuego_base` convierte en
    `parcial_equipo_listo(estado)` para `batalla.gd`) y `empezar_retomando()`, que siempre abre con
    Maxi (N6, §14.6);
  - **[v6.1]** el resbalón (`rival_resbalo()`, sin +1 en el pase tras un turno perfecto, y
    `resbalon_tras_racha` para el Río) y la guirnalda de lucecitas (`meta_turno.gd`, posición por
    `ancla_meta_turno()` del motor).

#### Voces nuevas que piden estas correcciones (para `guionista`)

- Coco:
  - "¡justo ahí!" (B3.2) y "¡Maxi, la pieza que brilla!" (B3.1);
  - "¡Maxi nos dejó un regalito!" (M2);
  - "¡están guardados ahí! ¡Los vamos a sacar juntos!" (M3.2);
  - la pausa entre rondas, "¿vamos por el amarillo, o descansamos y volvemos después?" (M1.2);
  - "¡Maxi, ven a pintar!" (M1.4) y "¡esperemos a Nicole!" (m4).
- Cometa:
  - **"¡turno perfecto!" (B2.1) [corregido 07-Oct-2026: es de Cometa, no de Coco]**: lo dispara el
    `GestorTurnos`, que es genérico, igual que "¡le toca a…!". Ya está en el guion
    (`nucleo_equipo_turno_perfecto_01/02`, `voces/nucleo/equipo/`) y sirve en Formas, en Parejas y en
    cualquier planeta;
  - los logros comunes de cada ronda: gotas, piezas y parejas (m1);
  - "¡ahora Nicole!" para el epílogo (M9);
  - **[v6.1]** `turno_perfecto_presenta` (N8) y la meta del tope en la `repetir` de Formas y Parejas
    (§14.11).
- **[v6.1]** Coco: `guardala_proximo_turno` (N13). Coleccionauta: `rival_resbala` (N10), opcional, después de "¡le toca a…!" y solo con la cola libre
  en ≤ 1 s (§4.3).
- **Ya no se usa** `arcoiris_batalla_formas_retrocede_celebra` (Coco, "¡Tres piezas seguidas!"): ver
  §14.3. Tampoco suena `rival_retrocede_celebra` de Parejas después de un turno perfecto (§8).

#### Para Dev: menores de HE-66

| Id | Qué hacer | Dónde quedó |
|---|---|---|
| m1 | Los logros comunes después de una derrota hablan de lo conservado en esa ronda | §14.5 |
| m2 | En el gag de Formas, las piezas caen en el estado del perfil del turno siguiente | §14.5 |
| m3 | Los hitos del mapa de batalla responden en menos de 100 ms; solo el que brilla lleva a jugar | §14.4 |
| m4 | Si Maxi arrancó solo: "¡esperemos a Nicole!" y la casa se agranda un 10 % y respira | §14.7 |
| m5 | Cometa y la casa quedan a 24 px o más del tablero; Parejas en equipo va en `Rect2(40, 128, 1200, 472)` | §4.1, §13 (para HE-59) |
| m6 | El "+100" tiene el mismo tamaño bajo cada retrato y suena una sola vez | §5.6, §14.8 |
| m7 | El aspirado suena a sorbete (≤ 1,5 s); solo se agrisa la franja del arcoíris; la mochila-torre no parece un bicho; papá se ríe en el teaser | §14.2, §14.10 |
| m8 | `minimo_hermanos` se refiere a los retratos | §14.7 |
| m9 | `condicion: "primer_hermano"` (coincide con la decisión del PO) | §14.7, §14.9 |
