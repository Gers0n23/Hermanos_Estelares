# Ficha de motor — `lanzar` (y su primera aplicación: la Torre de la Colección)

> **Decisión del PO (12-Oct-2026)**: la Batalla final de Arcoíris suma una **4ª etapa de jefe, "La Torre
> de la Colección"**, con la mecánica de **Angry Birds**. Las 3 rondas actuales (Río, Formas, Parejas)
> pasan a ser las rondas de "recuperar los colores"; **Parejas deja de ser la ronda final** (reemplaza la
> decisión 10 del 06-Oct-2026). El epílogo de pintar la mochila va **después** de la Torre. El ala se
> instala en la ceremonia de preparativos después de la batalla, y de ahí sale el viaje al planeta 2
> (**anula UX M7**). Resumen de los cambios al §14 en `docs/fichas/modo-equipo.md` §14.16.
>
> **Decisiones del PO (13-Oct-2026), incorporadas en esta v2**:
>
> 1. **Física 2D aceptada** como excepción al GDD §8, **solo para el motor `lanzar`**: torre congelada
>    entre tiros y determinista (§2, §6). La registra `scrum-master` en el GDD.
> 2. **El ala instalada es un estado familiar.** Basta con que un hermano tenga el ala y que la batalla
>    esté ganada: la ceremonia instala el ala y la nave queda lista para todos. Quien todavía no gana su
>    ala puede ir al planeta 2 igual y completar Arcoíris después. Hay una llave en la zona de padres
>    (§13.4).
> 3. **La caída es la del guion y el storyboard**: cae sentado en un **charco de pintura**, queda pintado
>    de lunares y la mochila sigue **gris y limpia**, porque solo quiso salvarla. **Se eliminan el tobogán
>    y los malvaviscos** (§9).
> 4. **Hay 4 derrotas-gag**, alineadas con `docs/guiones/cierre-arcoiris.md` T.7: el baile con pintura
>    rosada, el estornudo con calcetín de sombrero, "¡ningún globo me alcan…!" y el chicle que explota
>    (§10.1).
> 5. Se responde al §18 del storyboard `docs/cinematicas/cierre_arcoiris.md` (§23.2) y a los [CONCILIAR]
>    del §11 del guion (§23.1).

- **Autor**: `disenador-mecanicas`
- **Versiones**:
  - **v1** (12-Oct-2026);
  - **v2** (13-Oct-2026): decisiones del PO del 13-Oct y conciliación con el guion y el storyboard.
- **Estado**: **sin auditar por UX**. Las cifras son **estimaciones a mano** hasta que corran el arnés de
  tiros (§15.3) y el simulador (§15.4).
- **Tarjetas relacionadas**: HE-66 (diseño de la batalla), HE-69 (implementación), HE-17 (pieza/ala),
  HE-39 (prueba final cooperativa).
- **Fuentes**:
  - GDD §1, §5, §6 y §8;
  - `docs/fichas/modo-equipo.md` §2, §4, §5.2-5.6, §11 y §14;
  - `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md`;
  - `herramientas/simular_equipo.py`;
  - `docs/perfil-jugadores.md`;
  - `docs/guiones/cierre-arcoiris.md` v1 (manda en los textos y en los ids de voz);
  - `docs/cinematicas/cierre_arcoiris.md` (manda en la coreografía de la anticipación y de la caída).

**Marcas**:

- **[PO]**: decisión del PO.
- **[PO-base]**: propuesta base aprobada por el PO el 12-Oct-2026 (aquí se refina).
- **[Propuesta]**: de `disenador-mecanicas`.
- **[Abierta]**: necesita una decisión del PO.

## 0. Cambios de la v2 respecto de la v1

| Tema | v1 | v2 |
|---|---|---|
| Física | Excepción pendiente | **[PO, 13-Oct]** Aceptada, solo en `lanzar` |
| Viaje al planeta 2 | Cada hermano con su ala + la batalla | **[PO, 13-Oct]** Estado familiar `equipo.partidas.arcoiris` + la llave de padres (§13.4) |
| Caída | Tobogán de regaliz y malvaviscos | **[PO, 13-Oct]** Charco de pintura, lunares y la mochila gris en alto. Es una coreografía animada, no simulada (§9) |
| Derrotas-gag | 3 propias | **4, las del guion** (§10.1) |
| Globo gigante | Lo inflaban los tres por ventanitas, lo lanzaba Coco y aseguraba la victoria | Coco lo infla tras la 2ª derrota (guion). Es **el primer globo de cada intento desde el 3º**, y lo tira **Maxi** con su tiro guiado. **No asegura la victoria**: la quita como mínimo `agarre_min` (§10.3). Se elimina la ronda de ventanitas |
| Reloj | Un racimo en un poste | **La canasta de globos de Coco** (como el guion), con los globos atados flotando encima (§8.2) |
| Gesto de Maxi | Solo el toque | El toque **o** arrastrar en cualquier dirección: al soltar, sale el tiro guiado (§5.3). Vale "¡tira para atrás… y suelta!" |
| Al reintentar | Las piezas no reparadas desaparecían con un "puf" | **Las piezas que no se reparan quedan en el suelo** como decorado, alrededor del charco (§10.2) |
| Charco | — | **Crece con cada tiro** que no bota nada (§6.9) |
| Logro común | 3 niveles por agarre | **2 tramos por piezas botadas**, como el guion (§10.1) |
| Señales para la cinemática | — | `derribo_inminente`, `saltar_derribo()` y el estado del derribo (§13.2) |
| Revancha | Por el hito de la batalla | **Solo la Torre**; la batalla completa no se rejuega (§11) |
| `lineas_voz` | Claves propias | **Las claves y los ids del guion** (§14) |

---

## 1. La idea en una frase y la referencia

**Por turnos, cada hermano estira la resortera de regaliz y lanza un globo de pintura contra la torre
tambaleante donde el Coleccionauta se subió con su colección "para alcanzar el arcoíris con la mano".
Con cada derribo pierde agarre, y cuando se suelta, la torre se viene abajo y él cae sentado en un charco
de pintura.**

### 1.1 Angry Birds: qué tomamos y cómo escala su dificultad

| Lo que hace Angry Birds | Cómo lo usamos |
|---|---|
| Resortera: arrastrar hacia atrás, apuntar con el ángulo y la fuerza, soltar | Igual para Nicole y Sofía. Maxi toca o arrastra hacia donde sea, y el tiro sale guiado (§5.3) |
| Pocos pájaros por nivel: el stock es el reloj | **La canasta de globos del equipo** (10 de base). Es el único reloj de la etapa (§8.2) |
| Estructuras de materiales con distinta resistencia (vidrio, madera, piedra) | **Caramelo** (frascos, frágil), **cartón** (cajas, medio) y **lata** (latas de galletas, duro) (§6.4) |
| Cerdos como objetivo; el nivel termina cuando caen todos | **Un solo objetivo visible**: bajar al Coleccionauta. Su **agarre** baja con cada derribo (§6.6) |
| Pájaros especiales: el azul se divide en 3 con un toque en vuelo; los pesados atraviesan | Sofía elige entre el **globo triple** (toque en vuelo) y el **globo pesado** (atraviesa caramelo) (§5.5) |
| La línea de puntos del tiro anterior queda dibujada para corregir | Nicole y Sofía ven el **rastro de su tiro anterior** (§5.4) |
| Estrellas por pájaros sobrantes; los primeros niveles muestran la trayectoria y los avanzados no | Estrellitas por globos sobrantes, **solo en la revancha** (§11). Guía completa para Nicole y solo el arranque del arco para Sofía |
| Derrota sin castigo y reintento inmediato | Derrota-gag que da risa, "¡otra vez!" y ayudas escalonadas (§10) |

**Escala por edad, sacada de las dificultades del propio Angry Birds**:

- **Maxi = los niveles tutoriales**: el juego muestra dónde pegar y cualquier tiro razonable sirve.
- **Nicole = los episodios tempranos**: trayectoria visible y puntos débiles evidentes.
- **Sofía = los episodios avanzados**: sin trayectoria, elegir el pájaro según el material y puntos
  débiles chicos.

**Regla de una mecánica por lugar (GDD §5)**: Angry Birds vive **solo** en las batallas contra el
Coleccionauta. La torre es su "firma" (§17).

---

## 2. Reglas que no se rompen

| # | Regla | Marca |
|---|---|---|
| L1 | Cooperativo puro. **En pantalla y en el guardado no existe "quién derribó cuánto"** (R2 de `modo-equipo.md`) | [PO] |
| L2 | Solo **tocar y arrastrar**. El toque en vuelo del globo triple es un toque simple (GDD §6.4) | [PO] + [Propuesta] |
| L3 | **La torre nunca se mueve sola**: entre tiros está congelada y solo despierta con un golpe. Nada se cae durante el pase ni por azar (§6) | [PO, 13-Oct] |
| L4 | El turno de Maxi **siempre bota algo** y nunca le exige más que su ruta Semilla (B3.3 de HE-66) | [PO-base] |
| L5 | La derrota solo llega **en el pase**, con el retrato del siguiente ya al centro, en plural y sin nombres (B3 de HE-58) | [Propuesta] |
| L6 | Nunca se traba nada: las ayudas escalonadas llevan el "≤ 3 intentos" a ≥ 95 %, y desde la 3ª derrota se ofrece descansar sin perder lo ganado (§10) | [PO-base] |
| L7 | El motor no conoce la batalla, y el núcleo no conoce el motor (regla de oro 4, §13) | [PO] |
| L8 | Nada de bichos, vidrio filoso, dolor ni miedo. Los frascos son de **caramelo** y se rompen en **confeti dulce**. El Coleccionauta nunca se hace daño: solo queda **pintado**, y todo cae acolchado | [Propuesta] + guion |
| L9 | **La caída final no es física**: es una coreografía animada a mano que parte de la pose congelada de la torre (storyboard §4 y §17) | [PO, 13-Oct] + storyboard |

**Física 2D: excepción al GDD §8 [PO, 13-Oct-2026]**. Aceptada **solo para el motor `lanzar`**, con las
condiciones de esta ficha:

- la torre está congelada entre tiros;
- el asentamiento dura como máximo 3,5 s;
- hay ≤ 40 cuerpos, sin uniones;
- el resultado es determinista en la misma build y el mismo dispositivo;
- la caída final es animada.

Ningún otro motor puede usar física por esta excepción. **La registra `scrum-master` en el GDD** (esta
ficha no edita el GDD).

---

## 3. La escena

- **Dónde**: el claro de la batalla, con el arcoíris del cielo completo (las 3 rondas ya devolvieron los
  colores).
- **Por qué hay torre** (guion, decisión de tono 1): con la mochila vacía, el Coleccionauta apila su
  colección **para alcanzar el arcoíris con la mano**. Es un capricho chistoso, no un ataque.
- **La torre**:
  - está sobre una **galleta gigante** que hace de plataforma;
  - cajas de cartón con estampillas, piedritas y **calcetines sin pareja** (lo nombra
    `reacciona_02`);
  - frascos de caramelo con tapa, cuyo contenido es el del canon del storyboard (N1): patito de goma,
    guante, globo de nieve, cuchara de palo y cono;
  - latas de galletas;
  - **nada de bichos**.
- **Arriba**: el Coleccionauta, de puntillas o sentado con las piernas colgando (storyboard N2-a), con la
  mochila-torre **vacía y plegada a la espalda** y las gafas-lupa.
- **La resortera de regaliz**: una horquilla de bastón de caramelo con una goma de regaliz rojo. **Coco
  carga los globos de pintura** de su canasta (§8.2).
- **Globos de pintura**: rojo frutilla, amarillo limón y azul chupetín (los colores recuperados), **en
  orden fijo**. Nunca del color de un hermano.
- **Lo que deja la pintura**:
  - cada globo deja **manchas** que no se borran;
  - los tiros que no botan nada agrandan **el charco** al pie de la torre (§6.9).
  
  Las dos cosas son la memoria visible del avance.

---

## 4. Layout (1280 × 720)

Usa el layout común de las rondas de batalla (`modo-equipo.md` §14.15), **sin pista de galletas**.
**Manda esta tabla** sobre la composición supuesta del storyboard §3 (respuesta en §23.2).

| Zona | Rect / posición | Contenido |
|---|---|---|
| Franja superior | `Rect2(0, 0, 1280, 100)` | Cometa `Rect2(8, 4, 110, 96)` (tocable, repite) y casa `Rect2(1172, 8, 100, 96)`. Sin galletas: el centro queda libre |
| Zona de juego | `Rect2(0, 110, 1280, 490)` | Todo lo de abajo |
| Canasta de globos (stock) | Canasta en `Rect2(30, 470, 120, 114)`; globos atados flotando encima, en `Rect2(30, 140, 150, 300)` | No es tocable: con un toque, los globos se mecen (§5.6) |
| Coco | Pies en (170, 584), ≈ 110 × 130 | Carga los globos y reacciona |
| Resortera | Base en (260, 584); **bolsa en reposo en (260, 430)** | — |
| **Área de agarre** (Nicole y Sofía) | Círculo de **radio 120 px** centrado en la bolsa (x 140-380, y 310-550) | Empezar el arrastre aquí |
| Bandeja de Sofía ("globos de experta") | 3 globos de **104 × 104 px**, separados 16 px, en `Rect2(410, 480, 344, 104)` | Solo en su turno (§5.5) |
| Torre | Galleta-plataforma en x 800-1180, **centro x 990, sobre el suelo en y 584**. Cima del trono en y ≥ 150 (torre de ≤ 434 px) y cabeza del Coleccionauta en y ≥ 120 | — |
| **Charco** | Elipse por código centrada en **(990, 580)**: de 120 × 24 px al empezar hasta **520 × 60 px** como máximo (y 550-610) | Crece (§6.9). La barra se dibuja encima |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` | Retratos y ventanitas de porra |

**Separaciones (regla de 24 px de HE-66)**:

- el área de agarre termina en y 550: 60 px sobre la barra;
- la bandeja termina en y 584: 26 px sobre la barra, y está a 30 px del área de agarre;
- la cima de la torre queda a ≥ 46 px de la casa;
- los globos de la canasta empiezan en y 140: 36 px bajo Cometa.

El charco no se toca (§5.6).

**El cielo es de los globos**: un globo puede salir por arriba de la pantalla. Mientras está fuera, una
flechita con su color lo sigue pegada al borde superior, y el globo vuelve a caer.

---

## 5. Game feel táctil

### 5.1 Entrada unificada

- Táctil y mouse usan el mismo código.
- **Solo cuenta el primer dedo**: mientras dura un arrastre, se ignora cualquier otro toque.
- **Captura del arrastre**: un arrastre que empezó en el área de agarre es de la resortera hasta que se
  suelta, aunque pase sobre la barra o la bandeja. Las ventanitas de porra **solo responden a un toque
  que empezó sobre ellas** (Dev: `barra_equipo` ignora un `release` sin `press` propio).

### 5.2 La resortera (Nicole y Sofía): arrastrar hacia atrás y soltar

| Momento | Qué pasa | Tiempo | Sonido |
|---|---|---|---|
| Dedo abajo dentro del área de agarre | La bolsa **salta al dedo** (imán: el área de agarre es de 240 px), *squash* 0,9; Coco levanta la cresta | **< 50 ms** | "ñic" de goma |
| Arrastre | La goma se estira cuadro a cuadro, sin retraso, y el globo se deforma en la dirección del tiro. Se dibuja la línea o el arranque del arco (§5.4) | Cada cuadro | Tensión de goma que **sube de tono** |
| Estiramiento máximo | La bolsa se detiene en el radio máximo y la goma tiembla apenas | — | "tic" suave, una vez |
| Arrastre hacia la torre (al revés) | Con **40 px o más hacia la torre**, la bolsa no sigue: se queda en reposo y una flechita fantasma muestra "hacia atrás". La primera vez de cada turno suena `lanzar_repetir` | < 100 ms | "boing" amable |
| Soltar con estiramiento **< 40 px** | **Se cancela**: la bolsa vuelve con rebote. **No se gasta el globo** | < 100 ms | "plop" suave |
| Soltar con estiramiento ≥ 40 px | **Disparo**. El vector de tiro es el **promedio de la posición de la bolsa en los últimos 80 ms** (estabilizador). El globo sale con *stretch* 1,3 | **< 16 ms** | "fwiiip" |
| Toque sin arrastre dentro del área | La bolsa se mece y Coco hace el gesto de "estírala" | < 100 ms | "ñic" |

- **Fuerza**: `v = v_max × (estiramiento / estiramiento_max_perfil)`, lineal.
- **Ángulo**: el contrario al arrastre, recortado a **[−15°, 75°]** sobre la horizontal.
- **Sensibilidad**: con 220 px de estiramiento máximo (Nicole), 1 px de error corre el impacto ≈ 11 px a
  800 px de distancia.

### 5.3 Maxi: toca (o tira) donde quieras, y el globo da en el blanco

| Momento | Qué pasa | Tiempo |
|---|---|---|
| Al empezar su turno | El punto débil elegido (§7.1) **respira con halo dorado**, y Coco dice `maxi_globo_0X` («¡Un globo para Maxi! Tira para atrás... ¡y suelta!») | — |
| **Dedo abajo en cualquier parte** de la zona de juego (menos Cometa, la casa y la barra) | Chispita en el dedo, y la bolsa **se estira sola hacia atrás** con "ñiiic". Si arrastra, la goma se tensa más con su movimiento (sea cual sea la dirección), solo como efecto: "lo está haciendo él" | **< 50 ms** |
| **Al soltar** (toque corto o arrastre de cualquier largo y dirección) | Sale el tiro. El globo mira primero hacia el dedo (0,1 s) y sigue un **arco calculado de antemano** hasta el punto débil, con estela de chispas. Va cinemático, nunca falla. Dura ≈ 0,9 s | — |
| Impacto | El punto débil **se rompe siempre** (rotura forzada, §6.5) y salpica; después el globo pasa a la física para empujar a los vecinos. Coco: `maxi_le_dio_0X` | — |
| Si soltó a ≤ 150 px del halo | Reacción extra de Coco (como el "¡justo ahí!" del Río; voz opcional, ver §14) | — |
| 20 s sin ningún toque | El globo sale solo por el mismo camino y suena `arcoiris_equipo_maxi_regalito` (`semilla_auto_s: 20`) | — |

En su turno **no hay bandeja** y **no existe el fallo** (`fallo_0X` nunca suena en el turno de Maxi).

### 5.4 La guía de la trayectoria

- **Nicole (guía completa)**:
  - puntos cada 0,06 s de vuelo hasta el **primer choque**, con un **anillo de 40 px** en el punto de
    impacto. La parábola es analítica, cortada con `intersect_ray` contra los cuerpos dormidos;
  - **imán de objetivo** [Propuesta, `iman_objetivo_px`: 28]: si el anillo queda a ≤ 28 px del centro de
    un punto débil de Brote, se pega, el punto débil brilla y suena un "tic". Con 0 se apaga.
- **Sofía (arranque del arco)**: solo los **primeros 4 puntos** (0,24 s), sin anillo y sin imán.
- **Rastro del tiro anterior** (las dos): la línea real de **su** último tiro queda tenue (opacidad 35 %)
  durante su siguiente turno. **El de una nunca se ve en el turno de la otra.**

### 5.5 Los globos de experta de Sofía y el toque en vuelo

- **Al empezar su turno**, la bandeja muestra 3 globos: **normal**, **triple** (tres globitos pegados) y
  **pesado** (con cara de "uf"). Viene cargado el normal.
- **Tocar uno** lo pasa a la resortera (pop en < 50 ms, vuela en 0,2 s). Se puede cambiar **antes de
  empezar a estirar**; durante el arrastre, la bandeja se apaga al 60 %.
- **Elegir no gasta nada**: el tiro gasta un globo de la canasta, sea del tipo que sea.
- **Color**: el globo de experta toma el color que le tocaba en el orden (§6.8). Así, `carga_0X` siempre
  dice el color real.
- **Triple**: **un toque en cualquier parte mientras vuela** lo divide en 3, en abanico de ±7°. Sin el
  toque, cae entero. Coco recuerda `toca_en_el_aire` solo la primera vez por familia.
- **Pesado**: sale más lento, atraviesa hasta 3 piezas de caramelo y le hace doble daño al cartón y a la
  lata.

### 5.6 Lo demás que se toca (todo responde, nada queda muerto)

| Qué se toca | Respuesta (< 100 ms) | ¿Cambia el juego? |
|---|---|---|
| Un bloque (fuera del turno de Maxi) | *Squash* del dibujo de 0,12 s y el sonido del material. La física no se entera | No |
| El Coleccionauta | Se acomoda las gafas (reacción de cara; voz como mucho 1 de cada 3 veces, de `reacciona_0X`) | No |
| La canasta o sus globos | Los globos se mecen y chocan ("cuic") | No |
| El charco | "Plip" y una ondita en el charco | No |
| Coco | Salta y señala la resortera | No |
| Durante el vuelo y el asentamiento | Todo lo de arriba sigue respondiendo; la resortera solo hace "ñic" | No (salvo el toque en vuelo del triple) |

---

## 6. Física y estabilidad de la torre

> **Principio**: la física pone el **espectáculo** de cada tiro. La **justicia** la ponen reglas
> deterministas: la torre duerme, solo despierta por un golpe, se vuelve a dormir sola y el avance se
> mide con un contador (el agarre). **El desenlace (la caída) no es física: es animación** (L9).

### 6.1 Cuerpos

- **Bloques**: `RigidBody2D`, rectángulos o cápsulas (frascos), con `contact_monitor = true`,
  `max_contacts_reported = 4`, `linear_damp` 0,6 y `angular_damp` 1,5. Fricción y rebote del material.
- **Globos**: `RigidBody2D` circular con `continuous_cd = CCD_MODE_CAST_SHAPE`, `linear_damp` 0 y rebote
  0,15. **Revientan al primer choque** (mancha y desaparecen en 0,1 s), salvo el pesado.
- **Trono**: un bloque más, de cartón, con `peso_agarre` alto.
- **El Coleccionauta**: **no es un cuerpo físico**. Es un `Area2D` (círculo de 56 px) pegado al trono
  que detecta los golpes directos. Usa la escena compartida `coleccionauta.tscn` (storyboard §17).
- **Suelo**: `StaticBody2D` en y 584.
- **Tope**: ≤ 40 cuerpos.

### 6.2 La torre duerme (nada se cae solo)

1. **Al cargar**, todos los bloques quedan con `freeze = true` y `FREEZE_MODE_STATIC`, en la pose exacta
   del JSON.
2. **Tambaleo de mentira**: el balanceo es **solo del sprite** (±1,5°, tween lento). El cuerpo no se
   mueve.
3. **Despertar**:
   - **por golpe**: un globo o un bloque despierto lo toca con un impulso ≥ `despertar.impulso_min`;
   - **por apoyo**: si se despierta un bloque, también los que se apoyan en él. El grafo lo calcula el
     motor al cargar: B se apoya en A si el borde inferior de B está a ≤ 3 px del superior de A y se
     superponen ≥ 20 % en horizontal.
4. **Volver a dormir**: un bloque con `|v| < 8 px/s` y `|ω| < 0,1 rad/s` durante 0,4 s se congela en su
   pose actual.
5. **Asentamiento con tope**: desde que sale el globo, la física corre como máximo
   `asentamiento_max_s` (**3,5 s**), y después **todo** se congela.
   - **Fin del tiro** = no hay globos en vuelo y todo está dormido.
   - Recién ahí se cuentan los derribos y se cierra el turno. **Excepción**: el derribo final (§6.6),
     que congela todo al instante.
6. **Durante el pase, la puerta, la derrota-gag y la caída, la torre está congelada.**

### 6.3 Determinismo y semillas

- **Paso fijo**: la física corre a 60 Hz. El espacio sube las iteraciones del solver a 24
  (`PhysicsServer2D.space_set_param`, si la versión lo expone), **sin tocar `project.godot`**.
- **Sin azar en la física**: las mismas poses más el mismo vector de tiro dan el mismo resultado en la
  misma build y el mismo dispositivo. El arnés de QA lo usa (§20).
- **El azar con semilla** (`semilla` del nivel, con su `RandomNumberGenerator` propio) solo decide lo
  cosmético: las partículas, el tono de los sonidos y la variante de voz cuando no la fija el estado.
- **Entre dispositivos** puede haber diferencias chicas; por eso la calibración usa distribuciones
  (§15).
- **Restaurar es exacto**: entre tiros todo está congelado (§12).

### 6.4 Materiales y daño

| Material | Qué es | `resistencia` | `impulso_por_punto` | Densidad | Fricción | Rebote | Al romperse |
|---|---|---|---|---|---|---|---|
| `caramelo` | Frascos con tapa | 1 | 60 | 0,6 | 0,6 | 0,05 | Se destapa con un "pop", sale su objeto del canon y suelta **confeti dulce**. Nunca vidrio filoso |
| `carton` | Cajas de colección | 3 | 60 | 1,0 | 0,9 | 0,05 | Se abre como una tapa; caen estampillas y calcetines en espiral |
| `lata` | Latas de galletas | 6 | 60 | 1,6 | 0,7 | 0,1 | Rueda y se abolla ("doing") |

- **Daño por contacto** = `floor(impulso / impulso_por_punto)`, como máximo 3 por contacto. Los impulsos
  salen de `_integrate_forces`, o de la velocidad relativa por la masa. **Dev elige** cómo.
- **Pesado**: daño ×2 y `atraviesa: ["caramelo"]` (hasta 3, sale con el 80 % de su velocidad).
- **Los valores son iniciales**: los ajusta el arnés (§15.3).

### 6.5 Qué cuenta como "botado" (derribado)

Un bloque queda **botado** (una sola vez en el intento) si:

- está **roto**; o
- se **desplazó ≥ 40 px** de su pose original; o
- **giró ≥ 35°**; o
- salió de la zona de juego.

Se mide **en vivo**, cuadro a cuadro, para poder detectar el derribo final (§6.6) y el conteo de
`acierto_grande`. Cada botado suma su `peso_agarre`. **Rotura forzada de Maxi y del gigante**: el
objetivo de su tiro se marca roto al impactar, sin importar el impulso.

### 6.6 El agarre del Coleccionauta: el único contador de la etapa

- **`agarre`** (25 de inicio, a calibrar) baja con:
  - el `peso_agarre` de cada bloque botado (caramelo 1, cartón 1-2, lata 2, trono 6);
  - los **resbalones** de Nicole y Sofía (§7.2);
  - el **golpe directo** de Nicole o Sofía al Coleccionauta: +1, una vez por tiro;
  - el **mínimo garantizado del gigante** (§10.3).
- **Tope de bonificación por tiro**: `bonus_max_por_tiro` 3.
- **Se ve sin números**:
  - el Coleccionauta **se corre hacia el borde** (hasta 60 px) y **el trono se inclina** (hasta 18°),
    solo en el sprite;
  - su cara pasa por 4 estados: orgulloso → "¡uy!" → agarrado con las dos manos → colgando de un dedo;
  - la torre se balancea más (el tambaleo del sprite crece de ±1,5° a ±4°).
- **Derribo final** (lo que pase primero, **detectado en vivo durante el tiro**):
  1. el agarre llega a 0;
  2. el trono queda botado.
  
  En ese cuadro, el motor **congela todos los cuerpos en su pose**, emite
  `derribo_inminente(punto_impacto, false)` y empieza la anticipación desde el salpicón (storyboard §3,
  variante B). **Variante A** (`desde_soltar = true`): si **al soltar** ya se sabe que el tiro gana,
  porque el mínimo garantizado del tiro (la rotura forzada de Maxi o el `agarre_min` del gigante, más
  sus bonos) es ≥ al agarre que queda, la señal sale al soltar y el vuelo entero va en cámara lenta
  (§13.2).

### 6.7 Rendimiento (tablet Android, renderer Mobile)

- ≤ 40 cuerpos, sin `Joint2D` ni polígonos cóncavos.
- `CPUParticles2D` con ≤ 40 partículas por estallido.
- Manchas como decals: ≤ 6 por bloque, después se reutiliza la más vieja.
- **Meta**: 60 fps en el tiro más grande.

### 6.8 Orden y color de los globos

- **Color**: el globo n.º k del intento es `["rojo", "amarillo", "azul"][k % 3]`. Es fijo y lo anuncia
  `carga_01/02/03` («¡Rojo frutilla!», «¡Amarillo limón!», «¡Azul chupetín!»), **según el globo real**.
  **El color no cambia la mecánica**: solo da el anuncio y el color de las manchas y del charco.
- **El gigante** es dorado-arcoíris y tiene su propia línea (`gigante_turno`).

### 6.9 El charco (crece con cada tiro que no bota nada) [respuesta al storyboard §4]

- **Al empezar la etapa**: una elipse chica (120 × 24 px) al pie de la torre, centrada en (990, 580).
  Se dibuja por código, con remolinos de los colores que cayeron.
- **Crece**:
  - **un escalón (+50 px de ancho y +4 de alto) por cada tiro que no bota ninguna pieza**: ningún tiro
    se pierde, todos "aportan pintura";
  - **medio escalón por cada globo que revienta en el suelo**.
  - Máximo 520 × 60 px.
  - Cada crecida hace "chof" y una ondita.
- **No se borra nunca**: sigue igual en los reintentos y se guarda en el parcial. En la revancha
  empieza chico de nuevo.
- **En el derribo final**:
  - si mide menos de 360 px, **el salpicón del último globo lo agranda de golpe** hasta 360 (el respaldo
    del storyboard);
  - la caída siempre aterriza en el **centro del charco** (990, 578).

---

## 7. Reglas por perfil

| | **Maxi · Semilla** | **Nicole · Brote** | **Sofía · Estrella** |
|---|---|---|---|
| Control | **Toque o arrastre en cualquier dirección**: al soltar, sale el tiro guiado (§5.3) | Arrastrar la resortera hacia atrás y soltar (§5.2) | Igual que Nicole |
| Estiramiento máximo | — | **220 px** | **200 px** |
| Guía | Arco calculado | **Completa**, con anillo de impacto e imán de 28 px | **Arranque del arco** (4 puntos) |
| Rastro del tiro anterior | — | El suyo | El suyo |
| Globos | Normal (y el **gigante**, desde el 3er intento, §10.3) | Normal | **A elección**: normal, triple o pesado |
| Puntos débiles | Halo dorado grande sobre **uno** de `puntos_debiles.semilla` | Halo **medio** (⌀ ≥ 72 px) | Halo **chico** (⌀ ≈ 40 px, destello cada 3 s) |
| Resultado mínimo | **Siempre bota algo** | Puede no botar nada (agranda el charco) | Ídem |
| Su truco | "Globos que siempre dan en el blanco" | **"El resbalón"**: un tiro que bota **2 o más** de peso → **−1** de agarre extra | **"Tiros que valen doble"**: un tiro que bota **3 o más** de peso → **doble resbalón**, **−2** extra. Además elige el globo |
| Ayuda si se traba | Nunca se traba | Tras **2 turnos seguidos sin botar nada**, el halo de su punto débil crece al doble y respira | Ninguna (reto real). Le queda el rastro de su tiro |
| ¿Se pierde en su tiro? | Nunca | Solo en el pase, si se acaban los globos | Ídem |

### 7.1 El objetivo de Maxi

- Es el **primero que siga en pie** de `puntos_debiles.semilla`: frascos de caramelo "de repisa",
  vistosos, cuya caída arrastra poco (1-2 de peso en promedio).
- Si se acaba la lista, usa `semilla_respaldo`. **Nunca apunta al Coleccionauta ni al trono.**
- El halo no salta mientras Maxi piensa.
- **El gigante** tiene su propio objetivo: `gigante_objetivo`, la base del trono o una columna clave.

### 7.2 El resbalón (Nicole y Sofía)

- **Cuándo**: al final del tiro, si el peso botado en ese tiro llega a `resbalon.derribo_min` (Brote 2,
  Estrella 3).
- **Qué se ve**: el Coleccionauta **patina hacia el borde del trono**, con los pies como ruedita y las
  gafas en la punta de la nariz. El doble resbalón de Sofía son dos patinadas seguidas. Es la animación
  `resbalar` adaptada al trono (1,1 s).
- **Voz**: le sirve `reacciona_01` («¡Uy, uy, uy! ¡Quieta, torrecita, quieta!»), con su regla de 1 de
  cada 3. **No se atribuye a nadie.**
- **Equidad**:
  - las dos tienen su meta (2 y 3, como su turno perfecto);
  - Maxi nunca lo produce (`maxi_mueve_rival: false`);
  - "sus tiros valen más" (Sofía) = el doble resbalón y los globos de experta. Nada se ve más grande en la
    celebración (R7).

---

## 8. El turno de equipo

### 8.1 Reglas

- **1 globo por turno**, orden `maxi_intercalado` (M → N → M → S), **con puerta de turno**, bloqueo de
  400 ms, porras y "¡le toca a…!" (`modo-equipo.md` §4.2-4.3) [PO-base].
  - Se reutilizan las líneas de turno del núcleo (guion §9.1).
  - Al terminar el turno de Maxi suena `arcoiris_emparejar_equipo_porras_fin_maxi`.
- **Sin pista de galletas**: el reloj es la canasta (§8.2). Para el `GestorTurnos` es el **modo sin
  pista** (§13.2).
- **Fin del turno** = fin del tiro + la reacción del tiro (≤ 1,5 s). El motor llama
  `terminar_turno(false)`. **No existe el fallo**: un tiro que no bota nada es neutro y agranda el
  charco.
- **Voces por tiro** (guion T.4; sin nombre para Nicole y Sofía):

  | Resultado del tiro | Voz |
  |---|---|
  | Maxi (siempre bota) | `maxi_le_dio_0X` |
  | Bota 1-2 piezas | `acierto_01` («¡Cayó una caja!») o `acierto_02` («¡Justo en un frasco!», si una de las botadas es un frasco) |
  | Bota **3 o más piezas** | `acierto_grande` («¡Cataplum! ¡Se cayeron varias!») |
  | Pega en la torre, no cae nada | `acierto_03` («¡La torre se tambalea!») |
  | No toca la torre | `fallo_0X`, **como máximo 1 de cada 2 veces** (las otras, solo el "plop") |
  | Reacción del Coleccionauta | `reacciona_0X`, como máximo 1 de cada 3 tiros, nunca encima de Coco |

- **El derribo final interrumpe el turno**: congela todo, viene la anticipación y la caída (§9) y
  después el motor emite `completado`. Sin pase.
- **Sin guirnalda de lucecitas**: la meta del resbalón no se muestra con luces. El guion la dejó fuera
  de la intro corta (≤ 4 s); queda para la `repetir` de Cometa (§23.1, fila 1).

### 8.2 La canasta: el reloj que se ve

- **Qué es**: la canasta de Coco tiene `globos_base` globos de 44 px atados, flotando encima en un ramo.
  **Sin números.**
- **Cuándo se gasta un globo**: Coco saca uno **en el paso 4 del pase**, cuando empieza el turno
  siguiente, y lo carga con `carga_0X` (o `maxi_globo_0X`). Así la canasta baja como "pasa el tiempo",
  no como "Nicole gastó uno" (B3).
- **Último globo**: la canasta queda vacía y Coco abraza el globo, con `ultimo_globo` («¡El último
  globo... con todo el cariño!»).
  - Es **opcional**, con un interruptor en los datos (`voz_ultimo_globo`);
  - si en el playtest suena a presión, se apaga.
- **Récord en la revancha**: una **banderita** en la canasta marca "aquí nos sobraban la última vez"
  (§11).

### 8.3 Sin globos y con la torre en pie

Al terminar el tiro del último globo con el agarre > 0:

1. el motor llama `turnos.terminar_turno_sin_recursos()`;
2. el gestor hace el pase hasta el paso 2 (el retrato del siguiente al centro);
3. recién entonces emite la derrota (§10).

**La derrota nunca aparece pegada al tiro de alguien.**

---

## 9. Victoria: anticipación y caída en el charco [PO, 13-Oct; la coreografía es del storyboard]

**La coreografía, los tiempos y los SFX los manda el storyboard** (`docs/cinematicas/cierre_arcoiris.md`
§3 y §4). Esta ficha fija **quién la dispara, desde qué estado y qué queda al final**.

1. **Derribo detectado** (§6.6): todo se congela en el cuadro del derribo.
2. **Anticipación** (storyboard §3, ≈ 4,3 s; **no se salta** y **no se marca vista**):
   - **variante A** (`desde_soltar`): K1-K5 completos;
   - **variante B** (el caso normal): desde K2, con la cámara lenta en el salpicón.
   - El tambaleo K3-K4 parte **de la pose congelada** y la torre queda inclinada 11°.
   - Voz `torre_ups`.
3. **Caída** (storyboard §4, ≈ 10,5 s; **se salta desde la 2ª vez, por familia**:
   `arcoiris_batalla_final:caida_torre`):
   - cajas y frascos se abren en cámara lenta, **animados a mano** desde su pose congelada (cada bloque
     interpola de su pose real a su pose de la coreografía);
   - el Coleccionauta **levanta la mochila sobre la cabeza**;
   - cae **sentado en el centro del charco** (990, 578) con un ¡SPLASH! y queda **pintado de lunares**;
   - **la mochila, en alto, queda gris y limpia**;
   - la tapa de un frasco le cae como sombrerito;
   - se ríe.
   - Voces del guion, paso 1: `cae_lenta` → `cae_charco` → `cae_risa`, más `arcoiris_batalla_cierre_coco`
     y la fiesta.
   - **El guion y el storyboard concilian entre ellos** los ids y el orden finales (`torre_camara_lenta`,
     `torre_risa`, `torre_cometa`).
4. **Estado final** (el mismo que deja `saltar_derribo()`):
   - el Coleccionauta sentado en el charco, pintado y con el sombrerito, y la mochila gris en alto;
   - las cajas desparramadas alrededor del charco;
   - confeti cayendo y la música de fiesta en bucle.
   
   Ahí el motor emite `completado(0)`, y `batalla.gd` sigue con la fiesta y "antes del epílogo" (guion
   paso 1-2, storyboard §5.2).
5. **Nunca cae nada encima de él** salvo la tapa-sombrerito, que es blandita. Todo aterriza alrededor.

**Sin destellos aquí**: el premio es de la batalla.

**Celebración de cada tiro** (siempre, sin números): las voces del §8.1, más pop y confeti (1-2
piezas), la cámara que tiembla 0,15 s con la barra que aplaude (≥ 3 piezas) y la mancha en la cara del
Coleccionauta con un golpe directo.

---

## 10. Derrota-gag, reintento y ayudas

### 10.1 Las 4 derrotas-gag (guion T.7) [PO, 13-Oct]

**Secuencia** (la orquesta `minijuego_base`, §13.2):

- "¡otra vez!" de ≥ 160 × 160 px **desde el segundo 0** (tocarlo corta la secuencia);
- el retrato del siguiente ya está al centro;
- todo en plural, sin nombres.

Por orden:

1. `derrota_<n>_coleccionauta` (él celebra y le sale mal);
2. `derrota_<n>_coco_risa`;
3. el logro común de Cometa (`cajas_botadas_0X`);
4. la ayuda o la pausa de Coco (§10.3);
5. al tocar "¡otra vez!": `rearma_0X` y la intro corta.

| n | Gag (`variante_derrota()`) | Qué pasa |
|---|---|---|
| 1 | `baile` | «¡No me botaron! ¡Baile de la victoria!…»: baila en la cima, la torre se balancea y **un frasco de pintura rosada se le da vuelta en la cabeza** |
| 2 | `estornudo` | «¡Nadie me tumba!… ¡ACHÚU!»: estornuda, salen volando calcetines de la torre y **uno le queda de sombrero** |
| 3 | `globo_que_vuelve` | «¡Gané, gané! ¡Ningún globo me alcan…» *(1 s de silencio)* «…zó.»: **un globo cae del cielo justo sobre él** (es por guion: si en el intento un globo salió por arriba, usa su color; si no, uno azul) |
| 4 | `chicle` | «¡Me salvé! Esto merece un chicle de premio... ¡PLOP!»: el globo de chicle le explota en la cara |

**Cuándo sale cada uno**:

- las derrotas 1, 2 y 3 usan los gags 1, 2 y 3;
- desde la 4ª, **rotan los 4 sin repetir el anterior**;
- desde la 3ª derrota, en vez de la ayuda suena **la oferta de descansar** (`pausa`). El chicle es el gag
  de esa fase de "¿descansamos?": la 4ª derrota y las siguientes, en rotación;
- **el conteo es por familia y por batalla, y se guarda**: al retomar otro día sigue donde iba (parcial,
  §12).

**Lo que hacen los virtuales del motor** (firmas en `modo-equipo.md` §11.4):

- `gag_derrota_aspirar(destino)`: la primera parte del gag;
- `gag_derrota_devolver(perfil_siguiente)`: **el rearmado parcial** (§10.2) con `rearma_0X`;
- `gag_derrota_terminar_ya(...)`: deja el estado rearmado.

**Logro común** (guion T.8): `contar_logro_equipo()` devuelve **las piezas botadas en el intento**; la
base usa `logro_comun` con **2 tramos**:

- `"1"`: menos de la mitad de las piezas de la torre;
- `"2"`: la mitad o más (`logro_comun_corte` 0,5 sobre `total_piezas`, §14).

Con Maxi nunca es 0; si lo fuera, suena `nucleo_equipo_nos_alcanzo`.

**La revancha** reinicia el conteo de gags (1, 2, 3, 4…).

### 10.2 Al reintentar: la torre conserva parte del daño [PO-base]

- **Agarre conservado** = `round(conservar_dano × agarre_perdido)`, con `conservar_dano` 0,30 de inicio.
- **El rearmado** (`rearma_01`: «¡A rearmar! Caja, frasco, caja… ¡y yo arriba!»):
  - él vuelve a subir algunas piezas botadas, en el orden de `orden_reparacion`, hasta que el peso que
    queda botado iguale el agarre conservado. Vuelven congeladas a su pose original;
  - **las piezas que no vuelve a subir quedan en el suelo**, alrededor del charco, como **decorado**:
    sin colisión y sin física, en la pose en que cayeron. Se ven: "esas ya no suben" (§23.1, fila 5);
  - **las manchas y el charco quedan todos**;
  - él vuelve a la cima, en el estado de cara que corresponde al agarre conservado.
- **El orden de turnos sigue**: la puerta se abre para el hermano que ya estaba al centro. Con 10 y 12
  globos, **cada intento empieza con Maxi** (las cuentas en el §10.3).

### 10.3 Ayudas escalonadas [PO-base, conciliadas con el guion T.6 y T.9]

| Derrota | Lo que dice Coco | El próximo intento trae |
|---|---|---|
| 1ª | `ayuda_globos_extra`: «¡Dos globos más… estaban camuflados en el pasto, como yo!» | **10 + 2 globos** en la canasta. **Los +2 son del equipo**, no de un hermano: se gastan en el orden de turnos (M S M N M S M N M S M N → Maxi 6, Nicole 3, Sofía 3). **Se quedan** en todos los intentos siguientes |
| 2ª | `ayuda_globo_gigante`: «Fuuu… ¡Les inflé mi globo gigante! … ¡morado de soplar!» | 10 + 2 **+ el globo gigante**, que se queda en todos los intentos siguientes |
| 3ª y siguientes | `pausa`: «¿Vamos otra vez, o descansamos y volvemos después? ¡La torre no se va a ninguna parte!» | Lo mismo (10 + 2 + gigante). "Descansar" = salir con la casa: se guarda todo (§12) |

**El globo gigante de Coco** [conciliado con el guion]:

- **Cuándo sale**: es **el primer globo de cada intento, desde el 3º**. La primera vez que aparece
  suena `gigante_coleccionauta` («¿Y ese globo tan grande? ¡Eso no es justo!… Bueno, sí es justo.»).
- **Quién lo tira: Maxi**. Cada intento empieza con él:
  - el 1er intento empieza en el turno 0 (Maxi);
  - el 2º, en el turno 10 (10 mod 4 = 2: Maxi);
  - el 3º, en el 22 (22 mod 4 = 2: Maxi);
  - el 4º, en el 34, y así: los intentos perdidos gastan 10, 12, 12… globos, y el orden siempre vuelve
    a Maxi;
  - y al retomar también empieza Maxi (N6).
  
  Si alguien cambia `globos_base` o las ayudas, la regla se mantiene igual: **el primer turno de cada
  intento ≥ 3 es de Maxi**, y el gestor lo fuerza con `reiniciar_rival()` abriendo la puerta de Maxi.
- **Por qué Maxi**:
  - el gigante es la ayuda más grande, y dársela a Nicole o a Sofía la vuelve "de una" (Sofía siente
    celos de Nicole, no de Maxi: `perfil-jugadores.md`);
  - su tiro guiado garantiza que pegue;
  - es su gran momento sin quitarle reto a las mayores.
- **Voz**: `gigante_turno` no lleva nombre; el guion pide una variante con el nombre de Maxi (§23.1,
  fila 7). Al impactar suena `gigante_impacto`.
- **Efecto**:
  - vuela con su control de Semilla al `gigante_objetivo`;
  - al impactar **quita como mínimo `gigante.agarre_min` (12)** de agarre (rotura forzada del objetivo
    + bono hasta el mínimo), y la física hace el resto (radio 72 px, masa 8);
  - **no gana por sí solo**: deja la torre "colgando de un dedo" y los demás globos terminan el trabajo.
  - Si con eso ya llega a 0, es variante A de la anticipación.
- **Resultado**: con el gigante y el daño conservado, el 3er intento se gana casi siempre (§15.2). El
  ≥ 95 % en ≤ 3 intentos se demuestra con el simulador, **no** se fuerza por guion. **Puede haber un 4º
  intento** (raro, ≈ 1 %), y por eso existen la pausa y el 4º gag.

---

## 11. Revancha: estrellitas y récord familiar [PO-base]

- **Solo después de que la partida está hecha** (el ala instalada, §13.4). La primera vez, la meta es
  **solo bajarlo**: no hay estrellitas ni récord.
- **Qué se rejuega: solo la Torre.** La batalla completa (Río, Formas, Parejas, epílogo y cierres) **no**
  se rejuega (respuesta al storyboard §13.2, en §23.2).
- **Cómo se entra**:
  - el hito de la batalla en el mapa (la mochila pintada, en `posicion` [260, 380]) ofrece **"la Torre
    otra vez"**;
  - "¡todos a la nave!" en versión corta, con los tres;
  - después, directo a la Torre, **sin presentación T.1** (una vez vista), con la intro corta.
- **La torre parte nueva**, igual que el charco y la canasta (`globos_base`). Las ayudas (§10.3) también
  rigen en la revancha: nunca se traba.
- **Al ganar una revancha**:
  - anticipación (no se salta) → caída (se salta, ya vista);
  - **sin** antes del epílogo, epílogo, cierres, parte C ni foto;
  - después: una mini fiesta (los tres saltan, confeti), las **estrellitas** y el **récord**, y vuelta
    al mapa del planeta.
- **Estrellitas de equipo** (1-3, tres estrellas grandes que se encienden):

  | Estrellitas | Cuándo |
  |---|---|
  | 1 | Ganar (con ayudas) |
  | 2 | Ganar **en el primer intento** de esa revancha |
  | 3 | Ganar en el primer intento **con al menos `sobrantes_tres` globos sobrantes** (1 de inicio) |

  Los globos sobrantes vuelan al cielo uno por uno, con un "pop" de estrella. Sin números.
- **Récord familiar**: **los menos globos usados** en una victoria sin ayudas. Se ve como la banderita en
  la canasta. Voces que ya existen: "¡nuevo récord del equipo!" y "¡su primer récord!" (m6).
- **Nunca hay comparación entre hermanos.** 0 destellos [Propuesta]. Sin parcial: salir no cuesta nada y
  no cuenta.

---

## 12. Guardado parcial (batalla, §14.6 de `modo-equipo.md`)

- **Cuándo**:
  - en `turno_cerrado`, con todo congelado;
  - **y al terminar cada derrota-gag** (para que "descansar" guarde el intento nuevo con sus ayudas).
- **Qué entrega el motor** (`obtener_parcial_equipo()`; el núcleo no lo interpreta):

  ```jsonc
  {
    "intento": 3,                          // fija las ayudas y el gag de la próxima derrota
    "derrotas": 2,                          // conteo de gags (por familia y por batalla)
    "ultimo_gag": "estornudo",              // para la rotación "sin repetir el anterior"
    "globos_restantes": 9,
    "gigante_usado": true,                  // en este intento
    "agarre_perdido": 11,
    "bloques": {                            // solo los que cambiaron respecto del JSON
      "c07": { "estado": "suelo", "pos": [1120.0, 570.0], "rot": 1.2 },   // botada y no rearmada: decorado
      "c03": { "estado": "en_pie", "pos": [905.5, 470.0], "rot": 0.21 },
      "f02": { "estado": "roto" }
    },
    "manchas": [ { "bloque": "c03", "pos": [12, -8], "color": "azul" } ],
    "charco": { "ancho": 270, "alto": 36, "colores": ["rojo", "azul"] },
    "rastros": { "brote": [[...]], "estrella": [[...]] },
    "ayuda_brote_turnos_sin_derribo": 1,
    "presentacion_vista": true
  }
  ```

- **Al retomar** (`restaurar_parcial_equipo`):
  - la torre, el charco, las manchas y la cara del Coleccionauta quedan **exactamente** igual;
  - **las ayudas ganadas se conservan** (+2 y el gigante);
  - el conteo de gags sigue;
  - **empieza Maxi** (N6). Si el gigante de este intento todavía no salió, es su globo;
  - suena la intro corta (guion T.2: también al retomar).
- **Globos al retomar** [Propuesta]: los `globos_restantes`, **con un mínimo de 4** (Coco «¡encontré unos
  más!», línea nueva para el guionista, §14).
  - **Por qué no se rellena la canasta entera**: el daño se conserva entero al retomar (al reintentar,
    solo el 30 %). Rellenar haría que salir convenga más que perder.
  - Si salieron en la pausa de una derrota, el intento nuevo ya está guardado con la canasta llena.
  - Decisión abierta 1 (§21).
- **Al ganar la Torre**, `batalla.gd` registra la ronda `torre` y borra el parcial.

---

## 13. Contrato con el núcleo

### 13.1 Dónde vive

| Pieza | Ruta | Sabe de… | No sabe de… |
|---|---|---|---|
| Motor `lanzar` | `scripts/motores/lanzar/motor_lanzar.gd` + `escenas/minijuegos/lanzar/motor_lanzar.tscn` | Resortera, física, torre, agarre, charco, perfiles, gags, anticipación y caída | Batalla, guardado, navegación |
| Lógica pura | `scripts/motores/lanzar/logica_agarre.gd` (sin nodos) | Agarre, resbalones, conservación, estrellitas, rotación de gags | Física (la usan el motor y el arnés) |
| Rival compartido | `coleccionauta.tscn` (componente compartido, storyboard §17) | Poses y animaciones | Reglas |
| `GestorTurnos` | `scripts/base/gestor_turnos.gd` | El modo sin pista (§13.2) | La torre |
| `batalla.gd` | `scripts/nucleo/batalla.gd` | Rondas `jefe`, la revancha y los momentos que se saltan | Qué juego es cada ronda |

- El motor extiende `minijuego_base.gd`, recibe `nivel` y emite `completado(0)` en la batalla.
- **En solitario** funciona (para probarlo y para el arnés), pero **ninguna estación lo usa** (§17).

### 13.2 Firmas exactas (se suman a `modo-equipo.md` §11.4)

> Hoy `rival: null` exige `confirmar_turno: false` (el epílogo). La combinación nueva `rival: null` +
> `confirmar_turno: true` es el **modo sin pista**.

```gdscript
# GestorTurnos ---------------------------------------------------------------------------------
## true si config trae "rival": null y "confirmar_turno": true: puerta, pase (pasos 0, 2, 3, 4 y 5),
## porras, "¡le toca a…!" y semilla_auto_s como siempre. Sin pista, salto, retroceso, resbalón ni guirnalda.
func sin_pista() -> bool

## En vez de terminar_turno(false) cuando el turno gastó el último recurso del equipo y no ganó.
## Paso 0 (si el saliente era semilla) → paso 2 (retrato del siguiente al centro, sin salto) → rival_llego()
## (sin pista significa "el equipo perdió este intento").
func terminar_turno_sin_recursos() -> void

## Sin pista devuelve Vector2.INF (la base usa ancla_rival_motor()).
func posicion_boca_rival() -> Vector2

## Sin pista: no mueve a nadie; abre la puerta del hermano que está al centro. Con forzar_id != "",
## lleva antes a ese hermano al centro (lo usa lanzar para que el intento ≥ 3 empiece con el semilla).
func reiniciar_rival(forzar_id: String = "") -> void

# minijuego_base.gd ----------------------------------------------------------------------------
## Virtuales nuevas (implementación vacía)
func ancla_rival_motor() -> Vector2          # boca del rival en la escena del motor (sin pista). Vacía = centro
func variante_derrota() -> String            # "" = lineas_voz.derrota_gag_equipo es un Array (lo de hoy);
                                             # si no, la base lee derrota_gag_equipo[clave] (un Array)

## Momentos que se saltan desde la 2.ª vez (genérico; el núcleo no sabe qué hay dentro)
signal momento_saltable_iniciado(id_animacion: String)    # p. ej. "caida_torre"
signal momento_saltable_terminado(id_animacion: String)   # batalla.gd marca la cinemática vista aquí
func saltar_momento(id_animacion: String) -> void         # virtual: deja el estado final de ese momento

## Revancha (§11). batalla.gd la pone antes de añadir el motor al árbol.
var revancha: bool = false
signal resultado_revancha(estrellitas: int, record: int)  # antes de completado; record = globos usados (-1 si hubo ayudas)

# motor_lanzar.gd (propias del motor; respuesta al storyboard §18.7) ---------------------------
## Se emite UNA vez, en el cuadro del derribo final (agarre 0 o trono botado), con toda la física ya congelada.
## desde_soltar = true: se supo al soltar (el mínimo garantizado del tiro ≥ el agarre restante) → variante A;
## false → variante B (la anticipación arranca en el salpicón).
signal derribo_inminente(punto_impacto: Vector2, desde_soltar: bool)

## La implementación de saltar_momento("caida_torre"): corta la coreografía y deja el estado final del §9.4.
## La anticipación (§9.2) NUNCA se salta: si se llama durante la anticipación, el salto se encola para la caída.
func saltar_derribo() -> void

## El estado de la torre en el cuadro del derribo, para que la coreografía parta de él.
## {"bloques": {id: {"pos": Vector2, "rot": float, "estado": String}}, "inclinacion_trono": float,
##  "charco": {"ancho": float, "alto": float}, "punto_impacto": Vector2}
func estado_derribo() -> Dictionary
```

- **Secuencia de derrota en modo sin pista**: la del §11.4 de `modo-equipo.md`, **sin** las animaciones
  de `pista_rival`, con destino `ancla_rival_motor()` y la voz de `variante_derrota()`.
- **Secuencia de victoria**:
  1. `derribo_inminente` → anticipación (§9.2);
  2. `momento_saltable_iniciado("caida_torre")` → caída;
  3. `momento_saltable_terminado("caida_torre")` → estado final;
  4. `completado(0)`.
- **Lo que hace `batalla.gd`**: escucha `momento_saltable_iniciado`.
  - Si `Progreso.cinematica_vista("<id_batalla>:caida_torre")`, un toque llama
    `motor.saltar_momento("caida_torre")`.
  - Al recibir `momento_saltable_terminado`, marca la cinemática vista.
  - **Nunca conoce `derribo_inminente`**: es del motor y de quien lo instancie.

### 13.3 `batalla.gd` y los datos de la batalla

- **`rondas[]` admite campos opcionales nuevos**:
  - `"jefe": true`: sin interludio de estornudo de color; al ganar, la fiesta y `antes_epilogo`;
  - `"color": null`;
  - `"voz_pausa"`;
  - `"presentacion"`: el id de la cinemática T.1, `"presenta_torre"`, que se salta desde la 2ª vez por
    familia;
  - `"revancha": true`.
- **Mapa de batalla con 4 hitos**: el de la Torre es el último y el más grande.
- **Orden de entrada**:
  1. el interludio azul (`livianita_3`);
  2. el mapa de batalla con el hito de la Torre brillando (**pausa natural**, `pausa_entre_rondas`);
  3. el toque;
  4. la presentación T.1 (≤ 12 s, el motor la anima: apila, trepa y estira la mano al arcoíris);
  5. la intro T.2;
  6. el juego.
  
  El puente del storyboard §5.1 (cae sentado arriba de su colección) es compatible: puede ser el final
  del interludio azul o el principio de T.1, y lo deciden `director-cinematicas` y el `guionista`.
- **Modo revancha**:
  - solo la ronda con `"revancha": true`, con `motor.revancha = true`;
  - escucha `resultado_revancha` → `Progreso.registrar_revancha_batalla(...)`;
  - sin parcial, sin destellos y sin cinemáticas de cierre.
- **`Progreso`** (dentro de `equipo.batallas.<id>`, sin subir versión; se crea al leer si falta):

  ```jsonc
  "revanchas": { "torre": { "estrellitas": 0, "record": -1 } }   // record = globos usados; -1 = sin récord
  ```

  ```gdscript
  ## Guarda el máximo de estrellitas y el récord si mejora (menor y >= 0). Guarda una sola vez.
  ## Devuelve {"estrellitas_nuevas": bool, "record_nuevo": bool, "primer_record": bool}
  func registrar_revancha_batalla(id_batalla: String, id_ronda: String, estrellitas: int, record: int) -> Dictionary
  func obtener_revancha_batalla(id_batalla: String, id_ronda: String) -> Dictionary
  ```

### 13.4 Estado familiar de la partida y del ala [PO, 13-Oct-2026; responde al storyboard §17 y §18.11]

**Regla del PO**:

- el ala instalada es **de la familia**;
- con **un hermano con el ala** (zona 3) **y la batalla ganada**, la ceremonia de preparativos (bloque 2
  del storyboard) instala el ala y **la nave queda lista para todos**;
- quien todavía no ganó su ala **puede viajar al planeta 2** y completar Arcoíris después: su zona 3 y
  su escena del ala siguen ahí (con la línea que ajusta el `guionista`, `arcoiris_009`).

**Guardado** (dentro de `equipo`, sin subir versión; se crea al leer si falta):

```jsonc
"equipo": {
  // … §11.5 de modo-equipo …
  "partidas": {
    "arcoiris": {
      "pasos": ["tanque", "ala"],       // pasos hechos de la ceremonia (storyboard §13.3): tanque, ala, ruta, despedida, llamada
      "hecha": false,                   // true = el ala está instalada y la nave lista PARA TODOS
      "ceremonia": false,               // true = la ceremonia se vio completa (bloque 2)
      "forzada": false                  // true = la llave de padres la marcó hecha sin batalla (§ abajo)
    }
  },
  "rumbos": ["arcoiris>animalia"]       // caminos encendidos del Mapa Estelar
}
```

**API de `Progreso`** (genérica, por id de planeta):

```gdscript
func pasos_partida(planeta_id: String) -> Array
func marcar_paso_partida(planeta_id: String, paso: String) -> void      # guarda al terminar cada paso
func partida_hecha(planeta_id: String) -> bool                         # la nave se dibuja con la pieza de ese planeta
## Al terminar la ceremonia: hecha = true, ceremonia = true y agrega el rumbo. Guarda una vez.
func completar_partida(planeta_id: String, rumbo: String) -> void
## Llave de la zona de padres: hecha = true, forzada = true y agrega el rumbo, SIN batalla ni ceremonia.
func forzar_partida(planeta_id: String, rumbo: String) -> void
func rumbos() -> Array
```

**Datos** (`datos/planetas/arcoiris/mapa.json`):

```jsonc
"viaje_siguiente_requiere": { "partida": "arcoiris" },   // reemplaza el {"pieza", "batalla"} de la v1
"batalla": {
  // … §14.9 de modo-equipo …
  "tras_ganar": {
    "partida": { "escena": "res://escenas/planetas/arcoiris/partida_arcoiris.tscn", "rumbo": "arcoiris>animalia" },
    "revancha": true
  }
}
```

**El hito del Claro** (en `posicion` [260, 380]; el núcleo lo decide con datos, sin saber de Arcoíris):

| Estado | Hito |
|---|---|
| Batalla no ganada | La mochila-torre gris (lo de hoy) |
| Batalla ganada y `partida_hecha` en `false` | **Hito de partida**: la nave estacionada brillando, con el mapa encima (storyboard §7.1). Al tocarlo, la escena de `tras_ganar.partida`, que retoma en el primer paso que falte |
| `partida_hecha` en `true` | La mochila pintada: **"la Torre otra vez"** (revancha, §11) |

**El viaje**: el Mapa Estelar permite viajar al planeta siguiente si `partida_hecha("arcoiris")`, **para
cualquier hermano**, tenga o no su ala.

**La nave con el ala**: se dibuja si `partida_hecha`. Antes, quien ya ganó la pieza ve el ala envuelta
junto a la nave (storyboard §17).

**Llave de la zona de padres** (para el caso raro en que nunca se juntan los tres):

- "Instalar el ala sin la batalla" → `forzar_partida("arcoiris", "arcoiris>animalia")`, detrás del candado
  adulto (GDD §6.7);
- **no consume la ceremonia**: si después ganan la batalla, el bloque 2 se juega igual una vez
  (`ceremonia` sigue en `false`), sin volver a "instalar" nada que ya se vea puesto;
- la batalla sigue disponible.

**La regla anterior (M7) queda anulada por el PO**: la batalla **sí** condiciona el viaje, con la llave
como respaldo. El arnés de QA verifica lo nuevo (§20).

---

## 14. Contrato de datos (exacto)

**Archivo**: `datos/niveles/arcoiris/batalla/torre_equipo.json`.

- Coordenadas en píxeles de 1280 × 720.
- `rect` = `[x, y, ancho, alto]`, donde x, y es el **punto medio del borde inferior** del bloque.
- Lo arma `disenador-niveles`.

```jsonc
{
  "id_nivel": "arcoiris_batalla_torre_equipo",
  "motor": "lanzar",
  "modo_juego": "equipo",
  "planeta": "arcoiris",
  "zona": "batalla",
  "tema": "Etapa de jefe: la Torre de la Colección",
  "semilla": 1207,

  "mundo": {
    "gravedad_px_s2": 980,
    "fisica_hz": 60,
    "iteraciones_solver": 24,
    "suelo_y": 584,
    "zona_juego": [0, 110, 1280, 490],
    "techo_virtual_y": -400,
    "asentamiento_max_s": 3.5,
    "reposo": { "v_px_s": 8, "w_rad_s": 0.1, "durante_s": 0.4 },
    "despertar": { "impulso_min": 40, "por_apoyo": true, "apoyo_tolerancia_px": 3, "apoyo_superposicion": 0.2 },
    "derribo": { "desplazamiento_px": 40, "giro_grados": 35 },
    "max_cuerpos": 40
  },

  "resortera": {
    "bolsa_reposo": [260, 430],
    "base": [260, 584],
    "radio_agarre_px": 120,
    "estiramiento_min_px": 40,
    "estiramiento_max_px": { "brote": 220, "estrella": 200 },
    "velocidad_max_px_s": 1300,
    "angulo_grados": [-15, 75],
    "estabilizador_ms": 80,
    "reves_tolerancia_px": 40
  },

  "proyectiles": {
    "normal":  { "radio_px": 26, "masa": 1.0, "rebote": 0.15, "multiplicador_dano": 1.0 },
    "triple":  { "radio_px": 22, "masa": 0.6, "rebote": 0.15, "multiplicador_dano": 1.0,
                 "division": { "cantidad": 3, "abanico_grados": 7, "masa_cada_uno": 0.5, "radio_cada_uno_px": 18 } },
    "pesado":  { "radio_px": 28, "masa": 3.0, "rebote": 0.05, "multiplicador_dano": 2.0,
                 "atraviesa": ["caramelo"], "atraviesa_max": 3, "velocidad_tras_atravesar": 0.8 },
    "gigante": { "radio_px": 72, "masa": 8.0, "duracion_vuelo_s": 1.6, "agarre_min": 12 }
  },

  "materiales": {
    "caramelo": { "resistencia": 1, "impulso_por_punto": 60, "densidad": 0.6, "friccion": 0.6, "rebote": 0.05, "rotura": "destapa" },
    "carton":   { "resistencia": 3, "impulso_por_punto": 60, "densidad": 1.0, "friccion": 0.9, "rebote": 0.05, "rotura": "tapa" },
    "lata":     { "resistencia": 6, "impulso_por_punto": 60, "densidad": 1.6, "friccion": 0.7, "rebote": 0.10, "rotura": "abolla" }
  },

  "torre": {
    "plataforma": { "rect": [990, 584, 380, 36], "arte": "res://assets/sprites/batalla/torre/galleta_plataforma.png" },
    "bloques": [
      { "id": "c01", "material": "carton",   "forma": "rect",    "rect": [860, 584, 90, 70], "rot": 0.0, "peso_agarre": 2,
        "arte": "res://assets/sprites/batalla/torre/caja_calcetines.png" },
      { "id": "l01", "material": "lata",     "forma": "rect",    "rect": [960, 584, 70, 90], "rot": 0.0, "peso_agarre": 2,
        "arte": "res://assets/sprites/batalla/torre/lata_galletas.png" },
      { "id": "f01", "material": "caramelo", "forma": "capsula", "rect": [905, 514, 52, 68], "rot": 0.0, "peso_agarre": 1,
        "contenido": "patito", "arte": "res://assets/sprites/batalla/torre/frasco_patito.png" }
      // … ≤ 38 bloques en total (con trono y plataforma, ≤ 40 cuerpos)
    ],
    "trono": { "id": "trono", "material": "carton", "rect": [990, 230, 150, 40], "peso_agarre": 6,
               "arte": "res://assets/sprites/batalla/torre/cojin_trono.png" },
    "coleccionauta": { "escena": "res://escenas/compartidas/coleccionauta.tscn", "offset_en_trono": [0, -40],
                       "radio_golpe_px": 56, "deslizamiento_max_px": 60, "inclinacion_max_grados": 18 },
    "puntos_debiles": {
      "semilla":  ["f01", "f04", "f02", "f05", "f03", "f06"],
      "semilla_respaldo": ["c05", "c06", "l03"],
      "gigante_objetivo": ["c08", "l04"],
      "brote":    { "ids": ["c03", "l02", "c06"], "halo_px": 72 },
      "estrella": { "ids": ["c02", "l04"], "halo_px": 40, "destello_cada_s": 3.0 }
    },
    "orden_reparacion": ["c07", "c06", "l03", "c05", "c04", "l02", "c03", "f06", "f05", "f04", "f03", "f02", "f01"]
  },

  "charco": {
    "centro": [990, 580],
    "inicial": [120, 24],
    "maximo": [520, 60],
    "escalon_tiro_neutro": [50, 4],
    "escalon_globo_al_suelo": [25, 2],
    "minimo_al_derribo": [360, 44]
  },

  "agarre": {
    "inicial": 25,
    "bonus_max_por_tiro": 3,
    "golpe_directo": { "bonus": 1, "perfiles": ["brote", "estrella"] },
    "estados_cara": [0.25, 0.5, 0.75]
  },

  "perfiles": {
    "semilla":  { "control": "toque_o_arrastre_dirigido", "proyectiles": ["normal"], "justo_ahi_px": 150, "rotura_forzada": true },
    "brote":    { "control": "arrastre", "guia": "completa", "iman_objetivo_px": 28, "rastro_tiro_anterior": true,
                  "proyectiles": ["normal"], "resbalon": { "derribo_min": 2, "bonus": 1 }, "ayuda_tras_turnos_sin_derribo": 2 },
    "estrella": { "control": "arrastre", "guia": "arranque", "guia_arranque_puntos": 4, "rastro_tiro_anterior": true,
                  "proyectiles": ["normal", "triple", "pesado"], "resbalon": { "derribo_min": 3, "bonus": 2 } }
  },

  "colores_globos": ["rojo", "amarillo", "azul"],
  "acierto_grande_piezas": 3,

  "intentos": {
    "globos_base": 10,
    "ayudas": [
      { "desde_derrota": 1, "globos_extra": 2, "voz": "ayuda_intento_1" },
      { "desde_derrota": 2, "globo_gigante": true, "voz": "ayuda_intento_2" }
    ],
    "pausa_desde_derrota": 3,
    "gigante_turno_perfil": "semilla",
    "conservar_dano": 0.30,
    "botadas_no_rearmadas": "suelo_decorado",
    "globos_minimos_al_retomar": 4,
    "variantes_gag": ["baile", "estornudo", "globo_que_vuelve", "chicle"],
    "gags_por_derrota": [1, 2, 3],
    "gags_rotacion_desde": 4,
    "logro_comun_corte": 0.5,
    "voz_ultimo_globo": true
  },

  "revancha": { "sobrantes_tres": 1, "record": "globos_usados_menor" },

  "equipo": {
    "rival": null,
    "confirmar_turno": true,
    "orden": "maxi_intercalado",
    "puerta_tras_semilla": "arrastre",
    "bloqueo_tras_puerta_ms": 400,
    "maxi_mueve_rival": false,
    "semilla_auto_s": 20,
    "composiciones": { "maxi+nicole+sofia": {} }
  },

  "lineas_voz": {                                    // ids del guion cierre-arcoiris.md; rutas en assets/audio/voces/
    "presentacion": ["arcoiris/batalla/torre/presenta_coleccionauta.wav", "arcoiris/batalla/torre/presenta_alcanzo.wav",
                     "arcoiris/batalla/torre/presenta_coco.wav"],
    "intro_ronda": ["arcoiris/batalla/torre/intro_coleccionauta.wav", "arcoiris/batalla/torre/intro.wav"],
    "repetir": { "semilla": "nucleo/equipo/lanzar_repetir_maxi.wav", "brote": "nucleo/equipo/lanzar_repetir.wav",
                 "estrella": "nucleo/equipo/lanzar_repetir.wav" },
    "carga": { "rojo": "arcoiris/batalla/torre/carga_01.wav", "amarillo": "arcoiris/batalla/torre/carga_02.wav",
               "azul": "arcoiris/batalla/torre/carga_03.wav" },
    "maxi_carga": ["arcoiris/batalla/torre/maxi_globo_01.wav", "arcoiris/batalla/torre/maxi_globo_02.wav"],
    "maxi_acierto": ["arcoiris/batalla/torre/maxi_le_dio_01.wav", "arcoiris/batalla/torre/maxi_le_dio_02.wav"],
    "acierto_equipo": { "caja": "arcoiris/batalla/torre/acierto_01.wav", "frasco": "arcoiris/batalla/torre/acierto_02.wav",
                        "tambalea": "arcoiris/batalla/torre/acierto_03.wav" },
    "acierto_grande": "arcoiris/batalla/torre/acierto_grande.wav",
    "fallo_equipo": ["arcoiris/batalla/torre/fallo_01.wav", "arcoiris/batalla/torre/fallo_02.wav"],
    "ultimo_globo": "arcoiris/batalla/torre/ultimo_globo.wav",
    "rival_reacciona": ["arcoiris/batalla/torre/reacciona_01.wav", "arcoiris/batalla/torre/reacciona_02.wav",
                        "arcoiris/batalla/torre/reacciona_03.wav"],
    "gigante_aparece": "arcoiris/batalla/torre/gigante_coleccionauta.wav",
    "gigante_turno": "arcoiris/batalla/torre/gigante_turno.wav",
    "gigante_turno_maxi": "PENDIENTE",
    "gigante_impacto": "arcoiris/batalla/torre/gigante_impacto.wav",
    "derrota_gag_equipo": {
      "baile":            ["arcoiris/batalla/torre/derrota_1_coleccionauta.wav", "arcoiris/batalla/torre/derrota_1_coco_risa.wav"],
      "estornudo":        ["arcoiris/batalla/torre/derrota_2_coleccionauta.wav", "arcoiris/batalla/torre/derrota_2_coco_risa.wav"],
      "globo_que_vuelve": ["arcoiris/batalla/torre/derrota_3_coleccionauta.wav", "arcoiris/batalla/torre/derrota_3_coco_risa.wav"],
      "chicle":           ["arcoiris/batalla/torre/derrota_4_coleccionauta.wav", "arcoiris/batalla/torre/derrota_4_coco_risa.wav"]
    },
    "logro_comun": { "1": "nucleo/equipo/cajas_botadas_01.wav", "2": "nucleo/equipo/cajas_botadas_02.wav" },
    "nos_alcanzo": "nucleo/equipo/nos_alcanzo.wav",
    "ayuda_intento_1": "arcoiris/batalla/torre/ayuda_globos_extra.wav",
    "ayuda_intento_2": "arcoiris/batalla/torre/ayuda_globo_gigante.wav",
    "pausa_desde_intento_3": "arcoiris/batalla/torre/pausa.wav",
    "rival_rearma": ["arcoiris/batalla/torre/rearma_01.wav", "arcoiris/batalla/torre/rearma_02.wav"],
    "maxi_regalito": "arcoiris/equipo/maxi_regalito.wav",
    "porras_fin_maxi": "arcoiris/emparejar/equipo/porras_fin_maxi.wav",
    "anticipacion": "PENDIENTE",                      // storyboard: torre_ups (lo fija el guion)
    "caida": ["arcoiris/batalla/torre/cae_lenta.wav", "arcoiris/batalla/torre/cae_charco.wav", "arcoiris/batalla/torre/cae_risa.wav"],
    "justo_ahi_maxi": "PENDIENTE",                    // opcional; si no existe, solo la chispa
    "elige_globo_presenta": "PENDIENTE",              // nuevas, para el guionista (§18.2)
    "toca_en_el_aire": "PENDIENTE",
    "encontre_globos": "PENDIENTE",
    "intro_revancha": "PENDIENTE",
    "estrellitas_equipo": { "1": "PENDIENTE", "2": "PENDIENTE", "3": "PENDIENTE" }
    // + las comunes del núcleo (le_toca, te_toca_recordatorio, sube_ventanita, maxi_ayuda, animo_hermanos) como en rio_equipo.json;
    //   "¡nuevo récord del equipo!" y "¡su primer récord!" ya existen (§7.2 de modo-equipo)
  },

  "calibracion": {
    "estado": "ESTIMADO A MANO (13-Oct-2026). Reemplazar con la salida de herramientas/qa_torre_tiros.gd",
    "total_piezas": 28,                              // lo recalcula el motor al cargar (bloques sin plataforma ni trono)
    "duracion_s": { "pase": [8, 12], "ritual_maxi": 1.2, "tiro": { "semilla": 6.5, "brote": 10.5, "estrella": 12.0 },
                    "gag": 9, "presentacion": 12, "anticipacion_y_caida": 15 },
    "eleccion_sofia": { "normal": 0.30, "triple": 0.35, "pesado": 0.35 },
    "p_golpe_directo": { "brote": 0.05, "estrella": 0.08 },
    "distribuciones": {
      "fresca": {
        "semilla":          [[1, 0.65], [2, 0.30], [3, 0.05]],
        "gigante":          [[12, 0.5], [15, 0.3], [19, 0.2]],
        "brote":            [[0, 0.20], [1, 0.25], [2, 0.25], [3, 0.20], [5, 0.10]],
        "brote_ayuda":      [[0, 0.12], [1, 0.25], [2, 0.28], [3, 0.23], [5, 0.12]],
        "estrella_normal":  [[0, 0.25], [1, 0.15], [3, 0.30], [5, 0.20], [7, 0.10]],
        "estrella_triple":  [[0, 0.10], [1, 0.25], [2, 0.30], [4, 0.25], [6, 0.10]],
        "estrella_pesado":  [[0, 0.30], [2, 0.15], [4, 0.25], [6, 0.20], [9, 0.10]]
      }
      // "media" (agarre perdido 8-15) y "alta" (> 15): las llena el arnés
    },
    "metas": {
      "gana_intento_1": [0.30, 0.40],
      "gana_intento_2_si_perdio_1": [0.80, 0.92],
      "gana_en_3_o_menos": 0.95,
      "duracion_tipica_min": [5, 7],
      "sofia_2_turnos_intento_1": 0.90,
      "tres_estrellitas_revancha": [0.15, 0.25]
    }
  }
}
```

**Validaciones al cargar** (con `push_error`, sin colgarse):

- ids únicos;
- los ids de `puntos_debiles.*` y de `orden_reparacion` existen;
- ≤ 40 cuerpos;
- ningún bloque flotando en el grafo de apoyos;
- el trono es el más alto;
- el charco no se sale de y 550-610;
- `variantes_gag` tiene 4 entradas;
- cada `lineas_voz.carga` tiene los 3 colores.

**Torre de referencia** (para el arnés; no es el nivel final):

- 3 pisos de 2 columnas (cartón y lata) con tablones;
- 6 frascos de caramelo en repisas laterales (los objetivos de Maxi);
- el trono sobre una tapa ancha;
- **28 piezas** (más el trono y la plataforma), con un `peso_agarre` total de 34-38.

**Reglas de diseño del nivel**:

- **el trono no puede caerse con menos de ~60 % del agarre perdido**;
- todo punto débil y `gigante_objetivo` se puede alcanzar;
- la torre mide ≤ 440 px de alto (la composición del storyboard).

---

## 15. Calibración

### 15.1 Metas [PO]

| Meta | Valor |
|---|---|
| 1er intento | **30-40 %** |
| 2º intento, si se perdió el 1º | 80-92 % [Propuesta] |
| ≤ 3 intentos | **≥ 95 %** (por calibración: el gigante no gana solo) |
| Duración típica de la etapa | 5-7 min |
| Sofía juega ≥ 2 turnos en el 1er intento | ≥ 90 % |
| Aporte de cada perfil (se mide, **nunca se muestra**) | Entre 25 y 45 % cada uno |
| 3 estrellitas en una revancha | 15-25 % |

### 15.2 Estimación a mano (no es resultado)

| Perfil | Tiros en el 1er intento (M N M S M N M S M N) | Agarre medio por tiro | Total |
|---|---|---|---|
| Maxi | 5 | 1,4 | 7,0 |
| Nicole | 3 | ≈ 2,45 (con el resbalón y el golpe directo) | 7,35 |
| Sofía | 2 | ≈ 3,94 (mezcla de globos y doble resbalón) | 7,9 |
| **Equipo** | 10 | — | **≈ 22,3** (desviación ≈ 5,5) |

**Por intento** (conservando ≈ 6 de agarre entre intentos):

- **1er intento**: con agarre 25, ≈ **34 %**.
- **2º intento**: 12 globos y faltan ≈ 19. El equipo quita ≈ 27,5 → ≈ **91 %**. En ≤ 2: ≈ **94 %**.
- **3er intento**: el gigante quita ≥ 12 (media ≈ 14,7), más 11 globos (≈ 25), y faltan ≈ 19 → ≈ **99,9 %**.
  En ≤ 3: ≈ **99,9 %**. El 4º intento es casi inexistente.

**Lo demás**:

- **Equidad**: Maxi 31 %, Nicole 33 % y Sofía 36 % en el 1er intento. El gigante le suma a Maxi solo en
  el 3er intento (raro).
- **Sofía**: juega 2 turnos en ≈ 98 % de los casos.
- **Revancha**: 3★ ≈ **18 %**.

### 15.3 Arnés de tiros: `herramientas/qa_torre_tiros.gd` (`dev-godot` con `tester-qa`)

- **No toca `progreso.json`**. Corre headless, con la física activa, y su salida es resumida.
- **Modelo de tirador**: apunta al centro de un punto débil de su perfil, con error gaussiano:
  - Brote: σ de 2,5° y 4 %, con el imán;
  - Estrella: σ de 4° y 6 %; en el triple, el toque cae entre el 40 y el 80 % del vuelo, y en el 15 % de
    los tiros no toca;
  - Semilla y gigante: su camino real.
- **Bandas de daño**: 300 tiros por perfil y globo, en tres bandas: **fresca**, **media** y **alta**.
  Registra:
  - el peso botado;
  - las piezas botadas;
  - los resbalones y los golpes directos;
  - si el trono cayó;
  - y si el tiro fue "neutro", para el crecimiento del charco.
- **Escribe** `herramientas/salidas/torre_distribuciones.json` con:
  - `p_trono_cae` por banda;
  - el alcance de los puntos débiles;
  - la **prueba de reposo**: 10 s de física despierta sin tiros dan 0 botados;
  - la **prueba de la variante A**: el % de tiros ganadores que se supieron al soltar.
- **Validación cruzada**: 200 partidas completas en física real. Si difieren del simulador Python en más
  de 5 puntos, se agrega una banda.

### 15.4 Extensión de `herramientas/simular_equipo.py` (v4; la hace `disenador-niveles`, la corre el coordinador)

- **Opción `--torre`**: lee `torre_equipo.json` (y, con `--desde-arnes`, las distribuciones del arnés).
- **Clase `Torre`**, con `turno(h)`:
  - Maxi sortea de `semilla`, o de `gigante` si es el primer turno de un intento ≥ 3 (en ese caso, como
    mínimo `agarre_min`). **Afirma aporte ≥ 1**;
  - Nicole y Sofía, como en la v1: sus distribuciones, el resbalón, el golpe directo y el tope de bonos;
  - la banda sale del agarre perdido;
  - **victoria** si el agarre perdido ≥ `agarre.inicial`, o por `p_trono_cae`.
- **`jugar_torre()`**:
  - intentos sin tope (corta en 10 por seguridad);
  - las ayudas por número de derrota;
  - `conservar_dano`;
  - el orden continuo, con la verificación de que cada intento empieza con Maxi;
  - segundos: tiro + pase + ritual + gag + presentación + anticipación y caída.
- **`--revancha`** y **`--barrido`** (agarre 20-30 × globos 9-12; `conservar_dano` 0,2-0,5;
  `gigante.agarre_min` 8-16).
- **Imprime**:
  - % por intento (1, 2, 3, 4+) y acumulado en ≤ 3;
  - duración p50 y p80;
  - turnos por hermano y aporte por perfil;
  - estrellitas;
  - la recomendación (§15.5).
- **No escribe archivos.**

### 15.5 Reglas de decisión (fijadas antes de correr)

| Si… | Entonces… (en este orden) |
|---|---|
| 1er intento < 30 % | `agarre` −1 hasta entrar; con 22, `globos_base` +1 (**manteniendo** que cada intento empiece con Maxi: si no, `reiniciar_rival(forzar_id)`) |
| 1er intento > 40 % | `agarre` +1; con 28, achicar los halos de Brote o `globos_base` −1 (propuesta al PO) |
| 2º intento < 80 % / > 92 % | `conservar_dano` ±0,1 (entre 0,1 y 0,5) |
| ≤ 3 intentos < 95 % | `gigante.agarre_min` +2 (máximo 16); después, `conservar_dano` +0,1 |
| 3er intento > 99,5 % **y** 2º > 92 % | Bajar `gigante.agarre_min` a 10: la ayuda es tan grande que no se siente el reto |
| Algún perfil fuera del 25-45 % | Se toca el perfil (los pesos de Maxi, el imán, los halos), no el agarre |
| Duración típica > 7 min | `asentamiento_max_s` 3,0; después, `globos_base` −1 con `agarre` −2 |
| Sofía con ≥ 2 turnos < 90 % | `agarre` +1 |
| 3★ fuera de 15-25 % | `sobrantes_tres` ±1 |

### 15.6 Playtest

- **Registro de tiros**, solo en builds de depuración: `user://registro_tiros_torre.jsonl`, local y
  **sin nombres**, solo con el perfil. Sirve para reemplazar los σ del arnés por los reales.
- **Qué mirar**:
  - si Nicole entiende "hacia atrás";
  - si Sofía usa los especiales con intención;
  - si Maxi siente suyo el tiro (y el gigante);
  - si alguien dice "perdimos por…";
  - cuánto tarda Sofía en apuntar.

---

## 16. Duración (estimación)

| Tramo | Minutos |
|---|---|
| Pausa (ya tomada) + presentación T.1 (≤ 12 s, solo la 1ª vez) + intro | 0,3 |
| 1er intento (10 tiros × ≈ 19,4 s) | ≈ 3,3 |
| Derrota-gag + ayuda + rearmado | ≈ 0,25 |
| 2º intento (≈ 8 tiros hasta ganar) | ≈ 2,6 |
| Anticipación + caída | 0,25 |
| **Típica** | **≈ 5,8** |
| p80 | ≈ 7,6 |
| Con el 3er intento (≈ 6 %) | ≈ 10 |

La batalla completa pasa a **≈ 18-20 min**, **en dos sesiones o más**. Después viene el cierre del
storyboard (bloque 1 ≈ 2,7 min y bloque 2 ≈ 5 min, con su propia pausa).

---

## 17. Reutilización y regla de una mecánica por lugar

- El motor es genérico: la torre, los materiales, los globos, el agarre, el charco y los gags salen del
  JSON.
- **Se usa solo en las batallas contra el Coleccionauta.**
- **HE-39** [Abierta, decisión 4]: puede volver como la última ronda, con una torre más alta. Se
  considera "el mismo lugar" (la firma del Coleccionauta). **No se usa en ninguna estación de planeta.**
- **Para HE-39 ya sirve**:
  - el modo sin pista y `terminar_turno_sin_recursos()`;
  - `variante_derrota()`;
  - los momentos que se saltan;
  - la revancha;
  - el estado familiar de las partidas (genérico por planeta).

---

## 18. Qué hace falta de arte, voces y cinemáticas

### 18.1 Arte (`disenador-personajes` y pipeline; conciliado con el storyboard §16.2)

- **La Torre (N1 del storyboard; esta ficha manda en la forma)**:
  - cajas de cartón (calcetines sin pareja, estampillas, piedritas);
  - latas de galletas;
  - frascos de caramelo **con tapa suelta** (estados tapado y destapado; la tapa sirve de sombrerito) y
    su contenido del canon;
  - tablones, la galleta-plataforma y el cojín-trono;
  - estados abollado y abierto;
  - **piezas "en el suelo"** (las mismas piezas, que se apoyan bien de costado).
- **La resortera y los globos**:
  - la resortera de regaliz (la goma, por código);
  - la canasta de Coco con los globos flotando (rojo frutilla, amarillo limón y azul chupetín);
  - los globos de experta (triple y pesado);
  - el **gigante** dorado-arcoíris;
  - las manchas.
- **Por código**: el charco (N4), el confeti, la flechita de fuera de pantalla, la flecha fantasma y la
  banderita del récord.
- **El Coleccionauta** (N2 y N3 del storyboard, más las de la Torre):
  - sentado arriba, de puntillas estirando la mano;
  - los 4 estados de agarre;
  - `resbalar` en el trono;
  - **los 4 gags**: el baile con la pintura rosada, el calcetín de sombrero, la cara pintada por el
    globo que vuelve y el chicle que explota;
  - rearmando;
  - "mochila en alto" y la capa de **lunares**.
- **Coco**:
  - sacar el globo de la canasta y cargar la resortera;
  - abrazar el último globo;
  - camuflarse de verde pasto (la ayuda 1);
  - inflar el gigante hasta quedar morada (la ayuda 2).
- **Mapa de batalla**: el 4º hito (la torrecita).

### 18.2 Voces (`guionista`)

- **Las de la Torre ya están en `docs/guiones/cierre-arcoiris.md` T.1-T.10** y los ids van en el §14.
- **Faltan** (pedido de esta ficha):
  - `gigante_turno_maxi`: «¡Maxi, el globo gigante!…», con la instrucción de Maxi;
  - `elige_globo_presenta`: Coco presenta a Sofía sus globos de experta, como un rango, la primera vez
    por familia;
  - `toca_en_el_aire`: «¡toca en el aire para dividirlo!»;
  - `encontre_globos`: al retomar con la canasta en 4;
  - `intro_revancha` y `estrellitas_equipo` 1-3;
  - opcional, `justo_ahi_maxi`.
- **Ajustes sugeridos al guion** (no los edito; ver §23.1):
  - "y esas ya no suben" → «¡y algunas ya no suben!» (§23.1, fila 5);
  - sumar la meta del resbalón a `lanzar_repetir`, sin números: «…si botas muchas de un tiro, ¡se
    resbala!».
- **Antes de cualquier TTS: `--estimar` y el OK del PO sobre el costo.**

### 18.3 Cinemáticas (`director-cinematicas`)

- **Ya resuelto en el storyboard `cierre_arcoiris.md`**: la anticipación (§3), la caída (§4) y todo el
  cierre y la partida.
- **Falta storyboardear** (dentro del motor):
  - la **presentación T.1** (≤ 12 s) y su relación con el puente del storyboard §5.1;
  - **los 4 gags** (6-8 s cada uno, con el rearmado);
  - **el gigante**: Coco lo infla (la ayuda 2) y Maxi lo tira;
  - el crecimiento del charco.
- **Ajustar en el storyboard**: la composición supuesta del §3 por el layout del §4 (la torre centrada en
  x 990, la base en y 584 y el charco centrado en (990, 580)).

---

## 19. Riesgos de usabilidad para `experto-ux-parvulo`

| # | Riesgo | Mitigación | Qué observar |
|---|---|---|---|
| R1 | Nicole arrastra hacia la torre | Flechita fantasma + `lanzar_repetir`; al revés no dispara | ¿Al segundo tiro ya lo hace solo? |
| R2 | Sueltas accidentales | Cancela con < 40 px; estabilizador | Tiros "que se escaparon" |
| R3 | Precisión fina | Línea, imán y 220 px para Nicole; en Sofía es su reto a propósito | ¿Nicole le pega a algo en ≥ 60 % de sus tiros? |
| R4 | "Perdimos por…" en el último globo | La derrota llega en el pase; plural; `ultimo_globo` se puede apagar | Frases de culpa |
| R5 | Salir y volver como truco | Mínimo 4 globos, no la canasta entera | ¿Sofía lo usa a propósito? |
| R6 | Maxi toca durante el tiro de otro | Solo el primer dedo y la captura del arrastre | Tiros arruinados |
| R7 | El toque en vuelo del triple | Es opcional; sin él, el tiro no se pierde | ¿Lo disfruta o la frustra? |
| R8 | La física sorprende | Torre dormida, el agarre como contador, el charco y las manchas que se quedan | "¡No es justo!" |
| R9 | La batalla completa dura ≈ 18-20 min, más el cierre | Pausas antes de la Torre y entre los bloques del cierre | ¿Llegan a la Torre en la misma sesión? |
| R10 | **El viaje depende de la batalla** (M7 anulado) | Estado familiar: un ala basta; la llave de padres | ¿Alguien queda esperando a los demás? |
| R11 | El Coleccionauta pintado o golpeado | Pintura, nunca daño; él se ríe; todo acolchado | Caras de pena en Nicole |
| R12 | Sofía tira 2 de 10 en el 1er intento | Sus tiros valen más; tira 3 de 12 en el 2º | ¿Se aburre esperando? |
| R13 | **El gigante siempre es de Maxi**: ¿las mayores lo sienten injusto? | Lo dice el Coleccionauta («¡no es justo! …bueno, sí es justo»); solo sale tras 2 derrotas | Reclamos de "¡yo quería el gigante!" |
| R14 | La anticipación congela la torre en pleno derrumbe | Es la coreografía del storyboard (el "equilibrio imposible") | ¿Se lee como pausa a propósito o como cuelgue? |

---

## 20. Para `tester-qa` (`herramientas/qa_test_lanzar.gd` + casos en `qa_test_batalla_arcoiris.gd`)

**Como siempre en los arneses**: respaldo de `progreso.json` + md5, nunca con el juego abierto, y solo
el arnés afectado.

- **Estabilidad**:
  - 0 botados en 30 s sin tiros;
  - la prueba de reposo (§15.3);
  - las poses no cambian durante el pase, la puerta, el gag ni la anticipación.
- **Determinismo**: el mismo vector sobre la misma torre → el mismo resultado (±0,5 px).
- **Maxi**:
  - aporte ≥ 1 en 50 turnos;
  - el toque y el arrastre en cualquier dirección dan el mismo tiro guiado;
  - el halo es fijo;
  - `semilla_auto_s` funciona;
  - nunca apunta al Coleccionauta ni al trono;
  - `fallo_0X` nunca suena en su turno.
- **Resortera**:
  - cancelar con < 40 px no gasta;
  - al revés no dispara;
  - solo cuenta el primer dedo;
  - la captura del arrastre funciona sobre la barra.
- **Voces por tiro** (§8.1):
  - `acierto_grande` con ≥ 3 piezas;
  - `fallo` como máximo 1 de cada 2;
  - `reacciona` como máximo 1 de cada 3;
  - `carga_0X` coincide con el color real del globo.
- **Charco**:
  - crece con los tiros neutros y con los globos que caen al suelo, hasta el máximo;
  - se conserva al reintentar y al retomar;
  - en el derribo mide ≥ 360 px;
  - en la revancha arranca chico.
- **Resbalón y golpe directo**: los umbrales, Semilla nunca y el tope de bonos.
- **Derribo**:
  - por agarre 0 y por trono botado, detectado en vivo;
  - la física se congela en ese cuadro;
  - `derribo_inminente` se emite una vez, con `desde_soltar` correcto (caso de Maxi con agarre 1 → `true`;
    caso normal → `false`);
  - la anticipación no se salta;
  - `saltar_derribo()` deja el estado final del §9.4;
  - `completado` sale después.
- **Derrota**:
  - solo en el pase;
  - los gags 1, 2 y 3 en las derrotas 1, 2 y 3; desde la 4ª, rotan sin repetir el anterior;
  - `pausa` desde la 3ª;
  - el conteo persiste al retomar;
  - "¡otra vez!" tocado al principio, a la mitad o al final da el mismo estado.
- **Rearmado**:
  - el agarre perdido = `round(conservar_dano × perdido)`;
  - las botadas no rearmadas quedan en el suelo sin colisión;
  - las manchas se quedan.
- **Ayudas**:
  - 10 → 12 → 12 + gigante, que se quedan;
  - el gigante es el primer globo de cada intento ≥ 3, siempre de Maxi;
  - quita ≥ `agarre_min`.
- **Parcial**: todo el estado del §12; empieza Maxi; globos `max(restantes, 4)`; descansar tras un gag
  guarda el intento nuevo.
- **Revancha**:
  - solo la Torre;
  - estrellitas y récord;
  - sin parcial, destellos ni cierre;
  - el conteo de gags reinicia.
- **Estado familiar** (§13.4):
  - con un solo hermano con el ala y la batalla ganada → el hito de partida;
  - `completar_partida` → **cualquier** hermano puede viajar, incluso el que no tiene el ala;
  - la llave de padres → viaje sin batalla, y la ceremonia sigue pendiente;
  - el hito del Claro pasa por sus 3 estados;
  - la nave con el ala solo si `partida_hecha`.
- **R2**: ningún dígito en la escena del motor; nada por hermano en `revanchas`, en el parcial ni en
  `partidas`.
- **Layout**: separaciones de ≥ 24 px y targets ≥ 96 px. **Rendimiento**: 60 fps en la tablet.

---

## 21. Decisiones abiertas para el PO

| # | Decisión | Estado |
|---|---|---|
| — | Excepción a la física del GDD §8 | **Resuelta [PO, 13-Oct]**: aceptada solo para `lanzar` |
| — | El ala y el viaje al planeta 2 | **Resuelta [PO, 13-Oct]**: estado familiar + llave (§13.4) |
| — | El gancho del planeta 2 | **Resuelta por el guion y el storyboard**: el mapa del Coleccionauta (parte C) y la llamada de papá en la partida |

**Siguen abiertas**:

1. **Globos al retomar el parcial**: el mínimo de 4 (propuesta) o rellenar la canasta entera.
2. **Destellos en la revancha**: 0 (propuesta) o un monto chico la primera vez que se logran 3★.
3. **El gigante siempre de Maxi** (§10.3): es mi propuesta. ¿O prefiere que sea del primer turno de
   Nicole o de Sofía del intento? Eso arriesga los celos entre las dos.
4. **HE-39**: ¿la Torre vuelve como última ronda?
5. **El orden de turnos en la Torre**: mantener `maxi_intercalado` (recomendado) o `ronda_completa`.
6. **La revancha con 2 hermanos** (por "¡Juntos!"): hoy, solo con los tres.

---

## 22. Tarjetas sugeridas para el tablero (las crea y numera `scrum-master`)

| Tarjeta | Rol | Depende de |
|---|---|---|
| Auditoría UX de `motor-lanzar.md` v2 y del §14.16 (R1-R14) | `experto-ux-parvulo` | — |
| Registrar en el GDD §8 la excepción de la física (PO, 13-Oct) y la anulación de M7 | `scrum-master` | — |
| `GestorTurnos` sin pista + `terminar_turno_sin_recursos()` + `reiniciar_rival(forzar_id)` + virtuales de la base (momentos que se saltan, `variante_derrota`, revancha) | `dev-godot` | Auditoría UX |
| Motor `lanzar`: física dormida, resortera, perfiles, agarre, charco, gags, gigante, parcial, `derribo_inminente` / `saltar_derribo` | `dev-godot` | Lo anterior |
| Anticipación y caída en el motor (T2 del storyboard) | `dev-godot` | El motor + el arte N1-N3 |
| Arnés `qa_torre_tiros.gd` | `dev-godot` + `tester-qa` | El motor + la torre de referencia |
| Nivel `torre_equipo.json` + simulador v4 + calibración (§15.5) | `disenador-niveles` (corre el coordinador) | El arnés |
| `batalla.gd` (4º hito, `jefe`, presentación, revancha) + estado familiar de la partida, el hito del Claro, el viaje y la llave de padres (§13.4) | `dev-godot` | — |
| Arte de la Torre y de los gags (§18.1) | `disenador-personajes` | — |
| Voces que faltan (§18.2) y ajustes al guion | `guionista` | — |
| Storyboard de T.1, de los 4 gags y del gigante; ajuste del layout del storyboard §3 | `director-cinematicas` | — |
| QA (§20) | `tester-qa` | Motor + batalla |
| Playtest de la Torre y del cierre con los tres | PO | Todo lo anterior |

---

## 23. Conciliación con el guion y el storyboard

### 23.1 Respuestas a los [CONCILIAR] del guion (`docs/guiones/cierre-arcoiris.md` §11) que son de `disenador-mecanicas`

| # del guion | Pregunta | Respuesta de la ficha | ¿Cambia el guion? |
|---|---|---|---|
| 1 | Gesto de la resortera y si Brote ve la trayectoria | **Nicole y Sofía**: arrastrar la goma **hacia atrás** y soltar (§5.2). **Brote ve la trayectoria completa** con el punto de impacto; Estrella ve solo el arranque del arco (§5.4) | No. `lanzar_repetir` sirve tal cual. Sugerencia: sumarle la meta del resbalón sin números («…si botas muchas de un tiro, ¡se resbala!»), porque la intro corta no la dice |
| 2 | Puntería de Maxi: ¿su globo siempre pega? | **Sí**: su tiro va guiado al punto débil y lo rompe siempre (§5.3, §6.5). **Su gesto**: tocar o arrastrar en cualquier dirección; al soltar, sale. Por eso «tira para atrás… ¡y suelta!» es verdad para él | No. `maxi_le_dio_0X` siempre; `fallo_0X` nunca en Maxi; `cajas_botadas` nunca en 0 |
| 3 | ¿Importa el color del globo? | **No para la mecánica.** El orden es fijo, rojo → amarillo → azul, y **`carga_0X` se elige por el color real** (no al azar) | Sí, una nota: "variantes al azar" pasa a ser "variante según el color del globo" en `carga_0X` |
| 4 | Globos por intento, orden y último globo | 10 de base (12 desde la 1ª derrota). `maxi_intercalado` con puerta. `ultimo_globo` al cargar el último, con interruptor `voz_ultimo_globo` | No |
| 5 | ¿Las piezas botadas siguen en el suelo al reintentar? | **En parte.** Se conserva el 30 % del daño: él vuelve a subir algunas piezas, y **las que no rearma quedan en el suelo** alrededor del charco, a la vista (§10.2) | **Sí**: "y esas ya no suben" no es verdad para todas. Propuesta: «¡Igual botamos cajas, y **algunas** ya no suben!» (y lo mismo en `_02`) |
| 6 | Total de piezas y umbral de `acierto_grande` | Torre de referencia de **28 piezas** (sin plataforma ni trono; el motor recalcula `total_piezas` del nivel real). Tramos: `_01` < 50 %, `_02` ≥ 50 % de las piezas botadas en el intento. **`acierto_grande` con 3 o más piezas en un tiro** | No |
| 7 | +2 globos: ¿para quién? Gigante: ¿en qué turno y para quién? | **Los +2 son del equipo** (van a la canasta, se gastan en el orden de turnos y se quedan). **El gigante** lo infla Coco tras la 2ª derrota, es **el primer globo de cada intento desde el 3º** y **lo tira Maxi**, que es quien abre cada intento (§10.3). No gana solo: quita ≥ 12 de agarre | **Sí**: falta `gigante_turno_maxi` con su nombre y su instrucción. `gigante_turno` queda de respaldo (si el PO elige otra regla, decisión abierta 3) |
| 8 | ¿Las ayudas y el conteo se guardan al retomar? | **Sí, las dos**: las ayudas ganadas (+2 y el gigante) y el conteo de derrotas (la rotación de gags sigue donde iba). "Descansar" tras un gag guarda el intento nuevo con la canasta llena (§12) | No. `pausa` es cierta tal cual |
| 9 | ¿Puerta de turno y `maxi_regalito` en la Torre? | **Sí, las dos**: puerta y pase del modo equipo (modo sin pista), y a los 20 s sin toque el globo de Maxi sale solo con `maxi_regalito` | No |

Los puntos 10-16 del guion son de los preparativos y de otros roles. Esta ficha solo fija el estado
familiar donde se guardan (§13.4).

### 23.2 Respuestas al storyboard (`docs/cinematicas/cierre_arcoiris.md` §18, puntos 7-12)

| # | Pide | Respuesta |
|---|---|---|
| 7 | `derribo_inminente`, `saltar_derribo()` y el estado al derribar | **Variante B por defecto** (se sabe en el cuadro del derribo, detectado en vivo) y **variante A** cuando se sabe al soltar: el mínimo garantizado del tiro de Maxi o del gigante ≥ el agarre que queda. La física se congela en ese cuadro. Firmas en el §13.2: `derribo_inminente(punto_impacto, desde_soltar)`, `saltar_derribo()` (la implementación de `saltar_momento("caida_torre")`) y `estado_derribo()`. La anticipación y la caída son **del motor** (de acuerdo con el storyboard §17); la caída es **animada** desde la pose congelada. `batalla.gd` solo usa las señales genéricas `momento_saltable_*` y marca `arcoiris_batalla_final:caida_torre` al terminar |
| 8 | Layout y colores de los globos | El §4 manda: la resortera con la bolsa en (260, 430) y la base en (260, 584); **la torre centrada en x 990, con la base en y 584 y ≤ 434 px de alto**; el charco centrado en (990, 580); Coco y la canasta a la izquierda. **El storyboard corre su composición supuesta** (base en (900, 560), aterrizaje en (900, 575)) a **x 990** y al aterrizaje en **(990, 578)**. Colores: rojo frutilla → amarillo limón → azul chupetín, en orden fijo |
| 9 | El charco que crece con cada tiro fallado | **Aceptado** (§6.9): +1 escalón por tiro que no bota nada y medio por globo que cae al suelo, hasta 520 × 60. No se borra; en el derribo mide ≥ 360. Se dibuja por código |
| 10 | ¿La batalla se puede volver a jugar después de ganada? | **Solo la Torre (revancha)**, cuando la partida ya está hecha (§11). Se ven la anticipación y la caída (que se salta); **sin** epílogo, cierres, parte C ni foto. Ver §13.2 del storyboard: su propuesta de rejugar toda la batalla **no aplica** |
| 11 | El estado familiar de la partida y del rumbo, y el hito de partida en `mapa.json` | **Aceptado el formato del storyboard, con dos campos más** (`ceremonia` y `forzada`) y la API genérica (§13.4). El hito del Claro pasa por 3 estados (batalla → partida → revancha) con `batalla.tras_ganar` en `mapa.json`. El viaje pide `partida_hecha`, que es **familiar** [PO, 13-Oct]; la llave de padres está en el §13.4 |
| 12 | El gag de derrota de la torre | **Son los 4 del guion** (§10.1), no la propuesta del sombrero en el charco. Falta su storyboard (§18.3) |
