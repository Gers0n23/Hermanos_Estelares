# Ficha de motor — `caminos` («Cada quien a su casa», tipo Flow Free)

- **Autor**: `disenador-mecanicas`, 05-Nov-2026 (tarjeta HE-107).
- **Estado**: PROPUESTA. Falta: maqueta HTML (HE-110) y aprobación del PO, auditoría de `experto-ux-parvulo`
  (HE-111), tableros y calibración de `disenador-niveles` (HE-D6), voces de `guionista` (HE-112). La
  implementación (HE-117) espera al playtest del capítulo 1 (HE-18).
- **Actualización HE-124 (05-Nov-2026, política de derrota)**: la tormenta llega a los tres perfiles (Sofía
  1,6 × par, Nicole 2,2 × par desde z1, Maxi 3 × par) y el regalo de Sofía pasa a 3 derrotas. Las preguntas
  de §16 quedan **cerradas** (el PO delegó). Cambios marcados **[HE-124]** ([Decisión 05-Nov, HE-124]).
- **Fuentes**: GDD §1, §4 (Animalia), §5, §6 y §8; `docs/perfil-jugadores.md`; `docs/stack-tecnico.md`;
  `scripts/base/minijuego_base.gd`; `scripts/base/gestor_turnos.gd`; `docs/fichas/modo-equipo.md` §11.4;
  `docs/fichas/motor-clasificar.md` §1; `docs/fichas/lienzo-escenas-retos.md` §1.2 (caminos de Pinta v2);
  `docs/fichas/motor-topos.md` §3 (`racha_toby.gd`).

**Marcas**: **[PO]** decisión del PO (05-Nov-2026) · **[Ref]** tomado tal cual de Flow Free · **[Propuesta]**
de `disenador-mecanicas`, reversible · **[HE-124]** [Decisión 05-Nov, HE-124] (§16 ya no tiene preguntas
abiertas).

---

## 1. La mecánica en una frase y la referencia

**En una cuadrícula del claro, cada animal tiene que llegar a su casa dejando un camino de huellitas; los
caminos no se pueden cruzar, y en los niveles difíciles hay que cubrir todas las baldosas.**

| Flow Free (Big Duck Games, 2012) | Qué tomamos | Qué no / qué cambia |
|---|---|---|
| Pares de puntos del mismo color en una cuadrícula; se unen arrastrando un "tubo" | Animal + su casa; el tubo es su **camino de huellitas** (pezuñas, patitas de pato, huellas de dino…) | — |
| Los tubos no se cruzan | Igual | — |
| Pasar sobre otro tubo **lo corta** | Igual en Brote y Estrella [Ref]. En Semilla, **bloquea** en vez de cortar (§10.1) | — |
| El nivel se resuelve solo con el tablero **100 % lleno** ("Pipe 100 %") | En Estrella siempre; en Brote desde z3. Las baldosas cubiertas **florecen** | En Semilla no se pide llenar |
| Tamaños: 5 × 5 (Regular, el más fácil) hasta 9 × 9 y más; ~N pares en un N × N | Brote 5 × 5 → 6 × 6; Estrella 7 × 7 → 9 × 9 (§8) | Más de 9 × 9 no cabe con celdas de ≥ 64 px |
| "Perfecto" = tantos trazos como pares (sin rehacer) | Bono "¡sin borrones!" y parte de las estrellitas de Sofía | — |
| Pistas (revelan un tubo) | Toby olfatea y dibuja un camino; a Sofía le cuesta una estrellita | — |
| Variante **Bridges**: celdas puente donde dos tubos se cruzan | Puentecitos de madera (Sofía z3+) | Hexes y Warps: no |
| Modo **Time Trial** | Tiempo par y récord; la tormenta de los tres perfiles (§10.2) [HE-124] | — |

**Lo propio de Animalia**: en Sofía desde z2, las casas **no tienen el color del animal**: son su hábitat
real (pingüino → hielo, rana → nenúfar, pudú → bosque). Antes de trazar hay que **saber** de quién es cada
casa. Es el tema "hábitats" del GDD §4 y un reto real para 8 años.

**Escala por edad sacada de Flow Free** [Ref + Propuesta]: Flow Free escala con el tamaño de la cuadrícula,
la cantidad de pares y la exigencia de llenar. Maxi juega **por debajo del pack más fácil** (2-3 pares en
4 × 3), Nicole juega el **pack Regular 5 × 5-6 × 6 con menos pares de los habituales** y Sofía, el
**Regular de 7 × 7 a 9 × 9 con pares completos**, puentes y hábitats.

**Choques con otras mecánicas del juego**:

- **Pinta con Coco v2** (`lienzo-escenas-retos.md`, referencia **Labo Train**) ya tiene caminos trazados por
  donde los "vivos" llegan a un lugar (`llegadas`). **No es la misma mecánica**: allá es dibujo libre sin
  reglas (sandbox), aquí es un **puzle con restricciones** en cuadrícula (no cruzar, llenar). El riesgo es
  temático: "trazar un camino para que un animal llegue" suena igual. Ver §16, pregunta 2.
- No usa recorridos del Río ni nada de Zuma.

## 2. Reglas que no se rompen

1. **Solo tocar y arrastrar** (GDD §6.4). Se traza arrastrando desde el animal; no hay doble toque.
2. **Todo responde en < 100 ms**: el camino avanza en el mismo cuadro en que el dedo entra a la celda; un
   toque sobre una casa equivocada la hace sacudirse con "boing".
3. **Soltar nunca es un error**: el camino a medias queda dibujado, como en Flow Free.
4. **Nada procedural** (GDD §8): los tableros se diseñan a mano y viven en el nivel; para rejugar se
   aplican giros y espejos (§11.2). Un validador comprueba que cada tablero tenga **solución única**.
5. **Sin física**: es una cuadrícula y animaciones.
6. La lógica (`LogicaCaminos`) va sin pantalla y es determinista, para el arnés.
7. El motor no conoce el tema: animales, casas, huellas y fondo llegan del nivel.
8. Nada de bichos en ninguna ruta.

## 3. ¿Se puede reutilizar un motor existente? (respuesta honesta)

- **`clasificar`** se escribió pensando en "cada animal a su casa" (su ficha §1 lo dice): arrastrar un
  elemento a un destino con imán. **Es exactamente el diseño viejo de este juego** (GDD §4: "arrastrar
  animales a su hábitat"). Con la decisión del PO de usar Flow Free, la mecánica cambia de fondo
  (cuadrícula, caminos, no cruzar, llenar) y `clasificar` **no sirve como base**.
  - **Pero queda como red de seguridad para Maxi**: si el playtest muestra que a los 2 años trazar en
    cuadrícula le cuesta, su estación puede abrir `clasificar` en modo `libre` con animales y casas (cero
    código nuevo, solo un nivel). Ver §16, pregunta 3.
- **`lienzo_libre`** tiene trazo de caminos con imán a lugares (R1-R3 de Pinta v2), pero es trazo libre en
  píxeles, sin cuadrícula. Se puede compartir, a lo sumo, el dibujo de las huellitas.
- **UI que sí se reutiliza**: `barra_record.gd`, `pista_con_costo.gd`, `celebracion.tscn`,
  `racha_toby.gd` (nueva, de `motor-topos.md` §3) y el modo equipo.

**Conclusión**: motor nuevo `caminos` (`scripts/motores/caminos/`).

## 4. La escena (1280 × 720)

| Elemento | Dónde | Notas |
|---|---|---|
| Botón casa y Cometa | arriba a la izquierda | como en todos los motores |
| **Tablero** | centrado en x 640, y 380; alto máximo 620 px | celdas cuadradas, tamaño según la tabla |
| Toby | abajo a la izquierda (20-220, 500-720) | reacciona; su antena es la pista de Sofía |
| Botón **barrer** (reiniciar el tablero) | abajo a la izquierda, sobre Toby, 96 px, ícono de escobita de hojas | §6 |
| Avance de la estación | arriba al centro: una huellita por tablero | se llena sin números |
| Barra de récord y relojito | a la derecha | Brote (desde z2, con récord) y Estrella |

| Cuadrícula | Celda | Tablero | Perfil |
|---|---|---|---|
| 4 × 3 | 170 px | 680 × 510 | Semilla z1-z3 |
| 5 × 4 | 140 px | 700 × 560 | Semilla z4-z5 |
| 5 × 5 | 110 px | 550 × 550 | Brote z1-z2 |
| 6 × 6 | 95 px | 570 × 570 | Brote z3-z5 |
| 7 × 7 | 86 px | 602 × 602 | Estrella z1-z2 |
| 8 × 8 | 76 px | 608 × 608 | Estrella z3-z4 |
| 9 × 9 | 68 px | 612 × 612 | Estrella z5 |

Todas las celdas superan los 64 px (GDD §6.1). Animales y casas se dibujan a 0,9 de la celda; las de Maxi
superan los 96 px.

## 5. Bucle de juego

1. Entra el tablero: las baldosas caen en cascada (0,02 s por celda) y los animales saltan a su lugar,
   cada uno con su sonido. Las casas se abren.
2. El niño **arrastra desde un animal** (o desde la punta de su camino a medias) y el camino avanza celda a
   celda bajo el dedo (§6.1).
3. Al **entrar a su casa**, el camino se cierra: el animal **camina** por sus huellas hasta la casa (0,6-1,2
   s), entra y la casa se ilumina (§7.2). Mientras camina, se puede seguir trazando otros.
4. Cuando todos llegaron (y, si se pide, el tablero está lleno): fiesta del tablero y entra el siguiente.
5. Al terminar los `tableros` de la estación: celebración y `completado`.

**"¡Casi!" (todos llegaron pero faltan baldosas)** [Ref: Flow Free no termina hasta el 100 %]: las baldosas
vacías brillan con un latido suave y Toby dice una sola vez "¡faltan flores!". No hay error ni costo.

## 6. Interacciones (tiempos y feedback)

### 6.1 El trazo

| Regla | Detalle |
|---|---|
| Empezar | Presionar sobre un **animal** (o su casa, en Brote y Estrella [Ref]) empieza su camino desde ahí y **borra** el que tenía. Presionar sobre **la punta** de su camino lo continúa. Presionar **en medio** de su camino lo corta desde ese punto y continúa desde ahí [Ref] |
| Avanzar | El camino entra a la celda vecina (no en diagonal) cuando el dedo pasa el **35 % de esa celda** (histéresis, evita temblores en el borde) |
| Dedo rápido | Si el dedo salta celdas, el motor rellena el tramo con el camino ortogonal más corto que no choque (hasta 3 celdas de atraso). Si no hay, el camino espera en la última celda válida |
| Volver | Arrastrar hacia atrás sobre el propio camino lo **borra** celda a celda, con un "fiu" que baja de tono |
| Otro camino (B/E) | Entrar a una celda de otro camino **lo corta** desde ahí [Ref]: la parte cortada se desvanece en hojitas (0,25 s) y ese animal pone cara de "¡ey!" cómica. **Un camino ya llegado a casa también se corta** (Flow Free). **El corte es provisional mientras dure el trazo** [Ref]: si el dedo retrocede y sale de esas celdas sin soltar, el camino cortado vuelve entero; recién al soltar queda cortado |
| Otro camino (S) | **Bloquea**: el dedo sigue, el camino espera en la última celda (§10.1) |
| Roca o charco | Bloquea siempre; la roca hace "toc" y se mueve un pixel |
| Puente (E) | Una celda puente acepta **dos caminos que se cruzan en recto** (uno horizontal y otro vertical); nunca un giro sobre el puente [Ref Bridges] |
| Casa equivocada | S y B: la casa de otro color **bloquea** con "boing" y una sacudida. E (casas neutras): entrar a una casa ajena la hace sacudirse "¡aquí no vivo yo!" con boing; el camino se detiene en la celda anterior y suma un **intento fallido** (solo para las estrellitas, §9) |
| Soltar | El camino queda como está. Nada se pierde |

### 6.2 Otros toques

| Acción | Respuesta | Feedback |
|---|---|---|
| Tocar un animal sin arrastrar | Su sonido y un saltito | en Semilla, además, la **guía**: huellitas fantasma hasta su casa durante 2 s |
| Tocar una casa | Se abre y cierra la puertita, y suena | — |
| Tocar una baldosa vacía | Brota y se cierra una florcita | — |
| Barrer | Todos los caminos del tablero se borran con un viento de hojas (0,4 s) | sin confirmación: es instantáneo y no cuesta nada [Propuesta] |
| Tocar la antena de Toby (E) | Pista con costo (§10.4) | `pista_con_costo.gd` |

### 6.3 Respuesta y tiempos

- El camino avanza en el mismo cuadro del movimiento; cada huellita nueva se "estampa" con un pop de 0,08 s
  y un "tap" suave que sube de tono con el largo del camino (máximo una octava).
- El animal que se está trazando **mira hacia el dedo** y sus orejas se paran.

## 7. Game feel

### 7.1 El camino

- Huellas propias de cada animal (del nivel), alternadas izquierda-derecha, del color del animal en Semilla y
  Brote. En Estrella desde z2, huellas en tierra cálida y el color solo en un borde fino.
- Las esquinas del camino se redondean (no zigzag duro).
- Mientras se arrastra, la punta lleva una **huellita grande brillante** bajo el dedo (en Semilla, el
  **animal mismo** viaja bajo el dedo: §8.3).

### 7.2 Llegar a casa

- La casa "llama" cuando la punta está a una celda: se ilumina y su puertita se entreabre.
- Al entrar: el animal camina sus huellas (rebotando, squash al pisar) y entra; la casa se infla (1,15) y
  suelta 12 estrellitas; suena su sonido + una campanita. Cada camino cerrado sube la **racha** (§9.2).
- Las baldosas del camino **florecen** en cadena desde el animal hasta la casa (0,03 s por celda).

### 7.3 Tablero completo

- Todas las baldosas terminan de florecer, los animales se asoman de sus casas y hacen un coro corto (como el
  de `topos`, afinado), y Toby da una vuelta de carro. 1,5 s y entra el siguiente tablero. **Sin voz larga**.

### 7.4 Celebración final de la estación

Confeti de pétalos, todos los animales de la estación desfilan por el claro en sus caminos, Toby en su pose
orgullosa y `celebrar()` con el gesto real del hermano. Récord nuevo con el hueso-trofeo.

### 7.5 SFX

`huellita` (con tono), `borrar`, `corte_hojitas`, `ey_animal`, `boing_casa`, `casa_llama`, `llegada`
(campanita), `florecer`, `barrer_viento`, `tablero_completo`, `trueno_suave` y `lluvia` (tormenta de §10.2),
más los sonidos de cada animal. Ningún sonido de error.

## 8. Escala Semilla / Brote / Estrella

### 8.1 Tabla por perfil (zona 1 → zona 5)

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| `cuadricula` | 4 × 3 (z1-z3) → 5 × 4 (z4-z5) | 5 × 5 (z1-z2) → 6 × 6 (z3-z5) | 7 × 7 (z1-z2) → 8 × 8 (z3-z4) → 9 × 9 (z5) |
| `pares` | 2 (GDD §4) → 3 en z4-z5 | 3 (z1) → 4 (z2-z3) → 5 (z4-z5, GDD §4) | 6 (z1) → 7 → 8 (z4, GDD §4) → 9 (z5) |
| `llenar` | no | no (z1-z2) → **sí** (z3-z5) | sí |
| `casas` | color del animal | color del animal | color (z1) → **hábitat neutro** (z2-z5) |
| `rocas` | 0 | 0 (z1-z3) → 1-2 (z4-z5) | 0 (z1) → 2-4 (z2-z5) |
| `puentes` | 0 | 0 | 0 (z1-z2) → 1 (z3-z4) → 2 (z5) |
| `cortar_ajenos` | no (bloquea) | sí | sí |
| `animal_bajo_dedo` | sí | no | no |
| `iman_casa` | 1 celda (la casa "chupa" el camino) | 0 | 0 |
| `tableros` por estación | 5 | 4 | 4 (z1-z3) → 3 (z4-z5) |
| Forma de los tableros | caminos casi rectos (z1), con una curva (z3+) | con 1-2 curvas | serpenteantes; con llenado, la solución única obliga a rodeos |
| `tiempo_par_s` por tablero [HE-124] | 15 → 25 s (solo para la tormenta; no se muestra) | 35 → 80 s (desde z1; el **bono** y el relojito de récord, solo con récord previo) | 60 → 120 s |
| Tormenta (derrota) [HE-124] | **sí: 3 × tiempo par** | **sí, desde z1: 2,2 × tiempo par** | **sí: 1,6 × tiempo par** (antes 2 ×) |
| `regalo_tras_derrotas` (en el mismo tablero) [HE-124] | 2 | 2 | **3** |
| `ayuda_fuerte_tras_derrotas` [HE-124] | 3 (§10.1) | — | — |
| Ayuda quieto | 6 s: el animal salta y aparece la guía; 10 s: mano fantasma que traza | 15 s: la casa del siguiente par sin cerrar late | — (pista con costo) |

**De dónde salen los números**: Flow Free empieza en 5 × 5 con ~5 pares y en el pack Regular sube a ~N pares
en N × N. Nicole arranca con **3 pares en 5 × 5** (más aire, menos restricciones: más fácil que el nivel 1 de
Flow Free) y termina en el equivalente al pack Regular 6 × 6 (5 pares, con llenado). Sofía juega el pack
Regular de 7 × 7 a 9 × 9 con pares completos, más los hábitats neutros, que suman una capa de conocimiento
que Flow Free no tiene. **Duración estimada**: Maxi ~15-20 s por tablero (~1,5 min); Nicole 30-60 s (~3
min); Sofía 50-90 s (~4 min). Se confirma en la maqueta y el playtest.

### 8.2 Contenido (lo define HE-D6; lo que el motor debe soportar)

- **Maxi**: animales de granja y su variante de **dinos** [PO]: T-rex → volcán, spinosaurio → río,
  carnotauro → cueva, braquiosaurio → árboles altos.
- **Nicole**: pony → establo, jirafa → acacia, gatito → canasto, caballo → pradera, pato → laguna.
- **Sofía**: hábitats menos obvios (GDD §4): pingüino → hielo, pudú → bosque, cóndor → montaña, lobo marino
  → roquerío, rana → nenúfar (si el PO lo acepta), camello → desierto, oso polar → témpano; cachorros y
  ponys en sus variantes.

### 8.3 Maxi: el animal viaja con el dedo

- En Semilla **se arrastra al animal mismo**: deja sus huellas detrás y en su lugar queda su camita. Es el
  causa-efecto más directo (como mover un juguete) y no hace falta entender "tubo".
- **Imán de casa** de 1 celda: si el animal queda a una celda de su casa (en recto), al soltar **salta
  solo** adentro. Si se suelta lejos, se queda donde está, mirando su casa y llamándola; tocarlo de nuevo
  sigue el camino.
- Si se cruza con otro camino, **no lo corta**: el animal se frena, mira al otro y le "saluda" con su
  sonido. Nada se rompe.

## 9. Puntaje, estrellitas y récord

### 9.1 Puntaje (Brote y Estrella)

| Evento | Puntos |
|---|---|
| Animal en casa | 100 × racha (×1 a ×5) |
| Tablero completo | +300 |
| **"¡Sin borrones!"** (tablero con tantos trazos como pares [Ref "perfect"]) | +300 |
| Tiempo par (por tablero) | +10 por segundo que sobra |

- **Trazo**: cada vez que se empieza o retoma un camino (presionar sobre animal, casa o punta). Cortar un
  camino ajeno no suma trazos al ajeno.
- **Racha**: caminos cerrados seguidos sin cortar ni borrar ninguno. Se corta al borrar o al cortar otro.
  Se ve con `racha_toby.gd` (§3).

### 9.2 Estrellitas y récord

- **Nicole**: 1-3 por puntaje (`umbrales_puntaje`, p50 y p80 de la jugadora simulada), sin huecos vacíos
  (regla de Parejas, `motor-emparejar.md` §10.1.1).
- **Sofía**: 3 si todos los tableros salen "sin borrones o con un trazo de más", **sin intentos fallidos de
  casa** y con el tiempo dentro del par; 2 si falla una de esas tres; 1 si falla más. Cada pista resta una;
  tras una derrota, máximo 2. Los umbrales exactos van en `umbrales_estrellitas` y los calibra
  `disenador-niveles`.
- **Récord personal** por estación y hermano (`registrar_record`), con la banderita de `barra_record.gd`.
- **Maxi**: sin puntaje ni récord.

## 10. El fallo

### 10.1 Semilla: equivocarse no existe, perder es posible pero suave [HE-124]

- No se puede cortar nada, no hay casas equivocadas que acepten, soltar no rompe nada y el imán completa
  los caminos casi hechos. **Lo único que hace perder es la tormenta** (3 × tiempo par: ~45-75 s por tablero
  de 15-25 s): solo la ve un Maxi que se distrajo mucho rato.
- **Válvula contra trabarse** [Propuesta]: si dos caminos se encierran mutuamente (en 4 × 3 es raro pero
  posible), a los 6 s sin avance Toby **sopla** el camino que estorba (se va en hojitas) y aparece la guía del
  que falta.
- La mano fantasma (10 s) sigue mostrando la solución: con ella, todo tablero se termina dentro del tiempo.
- **Nube de Maxi**: una nubecita **blanca con carita dormida** (no gris), que bosteza al llegar. Su lluvia
  es de **burbujas**, no de gotas: los animales sin casa juegan a reventarlas y se sacuden como perritos.
  1,5 s, sin cartel de puntaje: solo la flecha circular gigante con la carita de Toby.
- **Regalo tras 2 derrotas** en el mismo tablero: Toby traza un camino. **Ayuda fuerte tras 3**: Toby traza
  todos menos uno, y ese tablero **no tiene nube** (victoria asegurada). Toby lo presenta como "¡hagámoslo
  juntos!".

### 10.2 Derrota-gag: "¡La tormenta de risa!" (los tres perfiles [HE-124])

- Sobre el tablero, una **nubecita gris** avanza por un riel corto arriba (es el relojito:
  `tormenta.factor_par` × tiempo par; Sofía 1,6, Nicole 2,2, Maxi 3 con la nube blanca de §10.1).
  No acelera, no parpadea y no suena hasta llegar.
- Si llega con caminos sin cerrar: **llueve sobre el tablero**, los animales que no llegaron abren
  paraguas de hoja, saltan a los charquitos y se sacuden **como perritos** salpicando la pantalla (gotitas
  que caen por el vidrio y se limpian solas en 1 s); Toby queda empapado con el casco lleno de gotas y se
  ríe. 2,5 s.
- "¡Otra vez!" grande (≥ 160 px; tocar en cualquier parte del cartel). **Los tableros ya resueltos se
  quedan resueltos**: se reintenta solo el tablero en curso, con la nube de vuelta al inicio y el mismo
  tablero (un puzle de solución única se aprende al reintentar: es parte del reto).
- **Regalo** [HE-124]: Toby regala un camino (lo traza él, como una pista gratis) **tras 3 derrotas en el
  mismo tablero** en Sofía y **tras 2** en Nicole y Maxi. Se ofrece descansar tras 4 (Sofía) o 3 (Nicole).
- **Destellos y estrellitas solo al ganar** la estación; los tableros ya resueltos quedan resueltos.

### 10.3 Brote: con derrota desde z1 [HE-124; reemplaza "sin derrota"]

Nicole también puede perder, desde el primer tablero: tormenta de 2,2 × tiempo par (35 s de par en z1 → 77
s de nube para 3 caminos en 5 × 5). Flow Free no tiene derrota, pero su Time Trial es el reto popular que
toma la tormenta; con 2,2 × par, una niña de 5 años que juega concentrada casi siempre llega (~75 % al primer
intento, p25), y la que se queda pegada en un camino ve una tormenta que da risa y reintenta el mismo
tablero. El corte de caminos ajenos sigue siendo provisional mientras no suelte (R2).

### 10.4 Pista de Sofía (cuesta una estrellita)

Toby olfatea (nariz arrugada, antena girando) y **traza él** el camino correcto de un par que no esté bien
(como la pista de Flow Free). Si ese camino corta otros caminos de Sofía, los corta. Con 1 sola estrellita, es
gratis.

## 11. Esquema JSON del nivel

### 11.1 Archivo de nivel

`datos/niveles/animalia/<zona>/caminos_<perfil>.json`

```jsonc
{
  "id_nivel": "animalia_z1_caminos_estrella",
  "motor": "caminos",
  "perfil": "estrella",
  "planeta": "animalia", "zona": "zona1_...",
  "fondo": "res://assets/.../claro_selva.png",
  "llenar": true,
  "casas": "color",                        // color | habitat
  "cortar_ajenos": true,
  "animal_bajo_dedo": false,
  "iman_casa": 0,                          // celdas
  "histeresis": 0.35,
  "atraso_max_celdas": 3,
  "transformar": true,                     // giros y espejos al rejugar (§11.2)
  "orden_tableros": "fijo",                // fijo | barajado (dentro de la estación)
  "tableros": [
    {
      "id": "t1",
      "celdas": [                          // A-Z animal, a-z su casa, # roca, + puente, . vacía
        "A...b..",
        ".#.....",
        "..B....",
        "....c..",
        "C......",
        "......a",
        "......."
      ],
      "pares": {
        "A": { "animal": "pinguino", "casa": "hielo" },
        "B": { "animal": "pudu", "casa": "bosque" },
        "C": { "animal": "condor", "casa": "montana" }
      },
      "tiempo_par_s": 70,                  // [Decisión 05-Nov, HE-124] obligatorio en los tres perfiles (la tormenta lo usa siempre)
      "solucion": ["…"]                    // la escribe el validador; la usan la pista y la mano fantasma
    }
  ],
  "catalogo": {                            // sprites, huellas y sonidos por id
    "pinguino": { "sprite": "res://...", "huella": "res://...", "sonido": "sfx/animales/pinguino.ogg", "color": "#2B3350" },
    "hielo": { "sprite": "res://...", "sonido": "sfx/casas/hielo.ogg" }
  },
  "puntos": { "llegada": 100, "racha_max": 5, "tablero": 300, "sin_borrones": 300, "por_segundo": 10 },
  "umbrales_puntaje": null,                // Brote: { "dos": X, "tres": Y }
  "umbrales_estrellitas": { "trazos_de_mas": 1, "intentos_casa": 0 },   // Estrella
  "tiempo_par": true,                      // bono y relojito de récord. Brote: solo con récord previo; Semilla: false
  "tormenta": { "factor_par": 1.6 },       // null = sin derrota. [Decisión 05-Nov, HE-124] estrella 1.6 (antes 2.0) · brote 2.2 desde z1 · semilla 3.0 (nube blanca)
  "regalo_tras_derrotas": 3,               // [Decisión 05-Nov, HE-124] en el mismo tablero: estrella 3 (antes 2) · brote 2 · semilla 2
  "ayuda_fuerte_tras_derrotas": null,      // [Decisión 05-Nov, HE-124] clave nueva. Semilla: { "derrotas": 3, "caminos_regalados": "todos_menos_uno", "sin_tormenta": true }
  "descanso_tras_derrotas": 4,             // [Decisión 05-Nov, HE-124] clave nueva: estrella 4 · brote 3 · semilla null
  "ayuda_idle_s": [6, 10],                 // Semilla: guía; mano fantasma
  "pistas_cuestan_estrellita": true,
  "lineas_voz": {
    "intro": "…", "instruccion": "…", "faltan_flores": "…", "casa_ajena": ["…"],
    "tablero_listo": ["…"], "victoria": ["…"], "derrota_gag": "…", "regalo": "…",
    "pista_usada": "…", "record": "…", "primer_record": "…", "ayuda_fuerte": "…", "descansar": "…"
  }
}
```

- Retrocompatibilidad [HE-124]: sin `ayuda_fuerte_tras_derrotas` → no hay; sin `descanso_tras_derrotas` → 3;
  un tablero sin `tiempo_par_s` con `tormenta` activa → `push_warning` y la tormenta no sale en ese tablero.

### 11.2 Rejugabilidad sin generar tableros

- Cada tablero admite **8 transformaciones** (4 giros × espejo) que conservan la solución única: con
  `transformar: true` se elige una al azar en cada partida. 4 tableros dan 32 variantes por estación.
- Los tableros que no son cuadrados (Semilla 4 × 3 y 5 × 4) solo admiten giro de 180° y espejos (4).
- **Validador** (`herramientas/validar_caminos.py` o `.gd`, para `disenador-niveles`): comprueba que cada
  tablero tiene **una sola solución** con las reglas del nivel (con y sin llenado), que las casas neutras no
  sean ambiguas y que la mano fantasma pueda resolverlo; escribe `solucion`.

## 12. Contrato con el núcleo y con el modo equipo

### 12.1 Solitario

- `MotorCaminos extends MinijuegoBase`. `asegurar_victoria()` en el instante en que el último animal del
  último tablero entra a su casa (con llenado, cuando florece la última baldosa), antes de la fiesta.
- `registrar_record`, `obtener_record`; `guardar_estado_parcial({tablero_actual, resueltos})` al terminar
  cada tablero (las estaciones de Sofía duran ~4 min; salir siempre es seguro).
- Señales de `LogicaCaminos`: `camino_cambio(par, celdas)`, `camino_cortado(par, desde)`,
  `llego(par, trazos)`, `casa_rechazo(par, casa)`, `tablero_completo(sin_borrones)`, `falta_llenar(n)`.

### 12.2 Modo equipo (`modo-equipo.md` §11.4)

- **Un tablero compartido** de 6 × 6 con 5 pares y sin llenado [Propuesta]: lo que traza uno lo ve y lo
  aprovecha el siguiente. Es cooperación de verdad: un camino mal puesto estorba al hermano.
- **Los caminos llegados quedan fijos en equipo**: nadie puede cortar el camino terminado de otro hermano
  (evita peleas). Sí se pueden cortar los caminos a medias.
- **Tope por turno** (`aciertos_max_turno`): semilla 1, brote 1, estrella 2 animales en casa. Cada llegada
  llama `notificar_acierto()`; tras `tope_alcanzado`, el motor espera a que el animal entre a su casa y
  llama `confirmar_turno_estable()`.
- **Fallo que corta el turno**: `segundos_por_turno` (brote 45, estrella 40) sin llegar ninguno →
  `terminar_turno(true)` (el animal "se sienta a esperar"). En Estrella, una casa ajena → `notificar_fallo_suave()`.
- **Maxi**: su capa de Semilla sobre **un par elegido** por el motor (el más corto que quede); ese animal brilla
  y viaja bajo el dedo, con guía. Con `semilla_auto_s`, `jugada_automatica_pedida` hace que el animal camine
  solo a su casa.
- `aplicar_perfil_turno(perfil)`: guía, imán y "animal bajo el dedo" según quien juega.
- **Derrota del equipo**: `gag_derrota_aspirar` aspira los caminos **a medias** (las huellitas vuelan en fila a
  la mochila-torre); `gag_derrota_devolver` no devuelve huellas: los animales sin casa se sacuden y vuelven a
  su punto de partida; `contar_logro_equipo()` = animales en casa.
- `ancla_meta_turno()`: borde izquierdo del tablero, centro vertical.

## 13. Maqueta HTML jugable (HE-110): `docs/maquetas/caminos-v1.html`

Debe demostrar:

1. El **trazo** en cuadrícula con dedo y mouse: histéresis del 35 %, relleno de dedo rápido, borrar hacia
   atrás, cortar desde el medio y el corte de un camino ajeno (B/E) frente al bloqueo (S).
2. **Maxi**: el animal bajo el dedo, el imán de casa y la válvula de Toby que sopla.
3. **Llenado** con "¡faltan flores!", puentes, rocas y casas neutras con el rechazo "¡aquí no vivo yo!".
4. Llegada a casa con el animal caminando sus huellas y el florecer en cadena.
5. Trazos y "¡sin borrones!", racha, tiempo par, récord en `localStorage`, la tormenta de los tres perfiles
   (con la nube blanca de Maxi) y su reintento; un jugador simulado por edad que dé el % de tableros
   terminados antes de la nube, para fijar `tiempo_par_s` (meta: p40 / p25 / p10) [HE-124].
6. Un **validador de solución única** en la propia maqueta (botón "validar tablero") y 3 tableros de muestra por
   perfil, con giros y espejos.

## 14. Riesgos de usabilidad (para `experto-ux-parvulo`)

| # | Riesgo | Propuesta / qué mirar |
|---|---|---|
| R1 | **El dedo tapa el camino** en 9 × 9 (celda 68 px y el dedo de 8 años mide ~12 mm ≈ 60 px) | La huellita grande de la punta va 40 px **arriba** del dedo en Estrella [Propuesta]; mirar en la tablet |
| R2 | **Cortar el camino ajeno sin querer** frustra a Nicole | El corte se ve claro (0,25 s de hojitas y el "¡ey!") y es provisional mientras no se suelte: retroceder lo restaura (§6.1, como Flow Free) |
| R3 | **Maxi no sabe trazar** en cuadrícula a los 2 años | Animal bajo el dedo, imán y válvula; si no alcanza, red de seguridad con `clasificar` (§3) |
| R4 | **El llenado** no se entiende ("¡pero si todos llegaron!") | Baldosas vacías que laten y una sola voz; en Nicole recién desde z3, después de haber jugado sin llenar |
| R5 | **Casas neutras** que Sofía no conoce (¿dónde vive un pudú?) | La primera vez de cada hábitat, Toby lo presenta (voz corta y dato curioso); validar el pool con el PO |
| R6 | **Barrer sin querer** borra todo | Está en la esquina, lejos del tablero; es reversible solo rehaciendo. Si el playtest muestra toques accidentales, mantener presionado 0,5 s (pregunta a UX) |
| R7 | **El puente** no se lee como "aquí se puede cruzar" | Puente de madera visible con baranda; la primera vez, un animal cruza por él solo como demostración |
| R8 | **Confusión con Pinta v2** (también hay caminos que llevan animales a lugares) | Lenguaje visual distinto: aquí baldosas y cuadrícula; allá lienzo libre |
| R9 | **La nube apura a Nicole** y la hace trazar peor (un puzle con reloj) [HE-124] | La nube no acelera, no parpadea ni suena; 2,2 × par. Medir si sus trazos por tablero suben con la nube respecto de una partida sin ella |
| R10 | **Maxi no entiende la nube** y la derrota lo sorprende [HE-124] | Nube blanca con carita dormida, lluvia de burbujas que se pueden reventar; observar si ríe o se queda quieto |

## 15. Qué debe probar el arnés (`herramientas/qa_test_caminos.gd`)

1. Cada tablero de cada nivel: solución única (con el validador) y resoluble por la mano fantasma; las 8 (o 4)
   transformaciones conservan la solución.
2. Trazo: avanzar, histéresis, relleno de hasta 3 celdas, borrar hacia atrás, cortar desde el medio, empezar desde
   la casa (B/E).
3. Choques: cortar ajeno (B/E) y bloquear (S); rocas; puente solo en recto; casa ajena con `casa_rechazo`.
4. Llenado: con todos llegados y baldosas vacías no termina y emite `falta_llenar`; sin llenado, termina.
5. Trazos, "¡sin borrones!", racha y puntaje según §9.1.
6. Semilla: imán de 1 celda, válvula a los 6 s, mano fantasma a los 10 s; nunca queda sin salida; con la mano
   fantasma seguida al pie de la letra, todo tablero termina antes de la nube.
7. Tormenta [HE-124]: en los tres perfiles con su `factor_par`; derrota, reintento del tablero en curso con los
   resueltos intactos, regalo tras 3 (Estrella) o 2 (Brote y Semilla), ayuda fuerte de Semilla tras 3 (sin
   nube, victoria asegurada); 0 destellos y 0 estrellitas al perder.
8. Equipo: tope por perfil, caminos llegados fijos, `segundos_por_turno` → `terminar_turno(true)`, jugada
   automática de Maxi.
9. Escena: arrastres con `push_input` en 4 × 3 y 9 × 9; ninguna celda bajo 64 px.

## 16. Decisiones (antes preguntas abiertas) [HE-124: el PO delegó, 05-Nov-2026]

1. **¿Nicole puede perder?** → **Sí, desde z1, con tormenta de 2,2 × par**; Sofía 1,6 ×; Maxi 3 × con nube
   blanca (§8.1, §10). Política del PO: GDD §6 regla 11.
2. **Convivencia con Pinta v2** → **se acepta**: son mecánicas distintas (dibujo libre frente a puzle en
   cuadrícula) y lenguajes visuales distintos (R8). Ningún encargo de Pinta pide "llevar un animal a su casa"
   en una cuadrícula; Animalia no tiene Pinta, así que no hay choque en el mismo planeta.
3. **Red de seguridad de Maxi** → **sí**: si la maqueta (HE-110) o el playtest muestran que Maxi no logra
   trazar ni con el animal bajo el dedo, su estación abre `clasificar` en modo `libre` con animales y casas
   (solo un nivel, sin código nuevo). La decide `disenador-niveles` con la evidencia, sin volver al PO.
4. **Casas neutras de Sofía** → **desde z2** (tabla §8.1): en z1 domina el puzle con colores.
5. **Tablero en equipo** → **compartido**, con los caminos llegados fijos (§12.2).

## 17. Estado de implementación (HE-117, 09-Nov-2026)

**Hecho y verificado** (arnés `herramientas/qa_test_caminos.gd`: 971 OK, 0 fallos, headless Godot 4.7.1):

- Código: `scripts/motores/caminos/` (lógica, dibujo, motor) y `escenas/minijuegos/caminos/motor_caminos.tscn`.
- Niveles: 17 archivos `caminos_*.json` en `datos/niveles/animalia/zona*/`, generados con
  `herramientas/generar_niveles_caminos.py` (el solver `herramientas/solver_caminos.py` garantiza solución
  única y que se llene todo el tablero). No se editan a mano.
- Derrota real (política del PO del 05-Nov, §16.1): la nube de tormenta llega a los
  3 × / 2,2 × / 1,6 × el tiempo par del tablero (Semilla / Brote / Estrella). Perder solo repite el tablero
  y deja intactos los ya resueltos. Ayudas: regalo de un camino tras 2/2/3 derrotas; Maxi recibe ayuda
  fuerte tras 3 (todos los caminos menos uno, sin tormenta); Nicole y Sofía, descanso tras 3/4.
- Presentación de la nube la primera vez de cada hermano (`caminos_nube`, HE-124). En Semilla la nube es
  "dormilona" (ojos cerrados, nunca se pone gris): el reloj existe, pero sin amenaza visual.
- El contador de racha (×N) pasó de abajo a arriba a la derecha del HUD.
- Voces: `herramientas/guion_voces_caminos.py` escribe `assets/audio/voces/animalia/caminos/lineas_tts.tsv`
  (148 líneas, Toby). Textos provisionales hasta la revisión del guionista (HE-112). El motor solo
  reproduce los archivos que existen, así que funciona sin los OGG.

**Sin verificar todavía:**

- No hay simulación de jugador humano para este motor (es un puzle, no reflejos): la tasa de victoria al
  primer intento (meta HE-124: 90 / 75 / 60 %) no está medida. Los factores de tormenta son una estimación
  y se ajustan en el playtest. Si Sofía pierde más de 1 de cada 3 tableros de z4–z5, sube a 1,8 ×.
- Falta grabar las voces (TTS local).
