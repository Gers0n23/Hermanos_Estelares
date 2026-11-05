# Ficha de motor — `topos` («¿Quién habla?», tipo Whac-a-Mole)

- **Autor**: `disenador-mecanicas`, 05-Nov-2026 (tarjeta HE-106).
- **Estado**: PROPUESTA. Falta: maqueta HTML (HE-110) y aprobación del PO, auditoría de `experto-ux-parvulo`
  (HE-111), calibración de `disenador-niveles` (HE-D6) con el simulador de la maqueta, y voces de `guionista`
  (HE-112). La implementación (HE-116) espera al playtest del capítulo 1 (HE-18).
- **Fuentes**: GDD §1, §4 (Animalia), §5 ("Mecánicas probadas y reto real"), §6 y §8;
  `docs/perfil-jugadores.md`; `docs/stack-tecnico.md`; `scripts/base/minijuego_base.gd`;
  `scripts/base/gestor_turnos.gd`; `docs/fichas/modo-equipo.md` §11.4; patrón de `motor-rio.md` y
  `motor-emparejar.md` §10 (racha, récord, estrellitas de Nicole por puntaje); Toby en
  `docs/guia-estilo-generacion.md` §3 (HE-A4b) y el ambiente de Animalia (HE-A7b).

**Marcas**: **[PO]** decisión del PO (05-Nov-2026) · **[Ref]** tomado tal cual del juego de referencia ·
**[Propuesta]** decisión de `disenador-mecanicas`, reversible · **[Abierta]** necesita al PO (§16).

---

## 1. La mecánica en una frase y la referencia

**Los animales asoman de sus madrigueras en el claro de la selva; suena la voz de uno ("¡muuu!") y hay que
tocar al que habló antes de que se vuelva a esconder.**

| Whac-a-Mole (arcade de 1976 y sus versiones móviles) | Qué tomamos | Qué no |
|---|---|---|
| Madrigueras fijas; los topos suben y bajan solos | Igual: entre 3 y 9 madrigueras según la edad. Suben con estiramiento y bajan con aplastamiento | El mazo: aquí se **toca** con el dedo. Los animales nunca reciben golpes: se les hace **cosquillas** y se ríen (L8 de `motor-lanzar.md`: nada de dolor) |
| La partida dura un tiempo fijo (~30-60 s) y el puntaje es la cantidad de aciertos | Ronda de 60 s con meta, puntaje y récord para Brote y Estrella | En Semilla no hay reloj (§8) |
| Al avanzar la partida, cada topo **queda menos tiempo arriba** y salen **más a la vez** | Es nuestra escala principal: `t_arriba_s` y `asomados` (§8) | — |
| Las versiones móviles agregan el **topo dorado** (bonus) y la **bomba** (no se toca) | **Toby dorado** asoma y vale un bonus; en Sofía z5, el **Coleccionauta disfrazado** es el "no lo toques" | La bomba que te quita puntos: aquí solo corta la racha (§10) |
| Combo por aciertos seguidos | Racha ×1-×5 con la colita de Toby (§9) | — |

**Lo propio de Animalia**: no se toca a cualquiera que asoma, sino **al que sonó** (discriminación auditiva:
el tema "animales y sus sonidos" del GDD §4). Los demás asomados son los señuelos naturales.

**Escala por edad sacada de Whac-a-Mole** [Ref + Propuesta]: el arcade sube la dificultad bajando el tiempo
arriba (de ~1,5 s a ~0,6 s para un adulto, valores aproximados de las versiones populares) y subiendo los
topos simultáneos (de 1 a 3). Nuestros tiempos parten de esos valores y los alargan con el tiempo de
reacción de cada edad: **× 1,3 para 8 años y × 1,7 para 5 años** sobre el adulto. A eso se suma la
discriminación del sonido. En Maxi no hay tiempo: el animal espera.

**Choques con otras mecánicas del juego** (GDD §5: cada referencia en un solo lugar):

- **No es ritmo** (Sigue el ritmo, Melodía): los animales asoman a intervalos irregulares, **nunca al compás**
  de la música. La música de fondo no marca los asomos.
- **No es Simon** (La banda de Octavio): nunca se pide **repetir una secuencia en orden**. El pedido doble
  de Sofía (§8.3) admite cualquier orden.
- **Riesgo con "Sopa de burbujas"** (Letralandia: "tocar la burbuja con la letra que dice Lila"): esa idea,
  todavía sin juego de referencia, es este mismo esqueleto con letras. Ver §16, pregunta 1.

## 2. Reglas que no se rompen

1. **Solo tocar** (GDD §6.4). Responde **al presionar**, no al soltar: en un juego de reflejos, el
   presionado es el momento justo.
2. **Todo responde en < 100 ms**, también lo "incorrecto": cualquier animal tocado hace su sonido y su
   cara; una madriguera vacía tocada echa tierrita y suena "puf".
3. **Nadie recibe golpes**: tocar es hacer cosquillas. El animal se ríe y se encoge.
4. **Sin voces durante la ronda** (GDD §5, ritmo rápido): la voz de Toby da la instrucción al inicio y en
   las pistas. Los sonidos de animales **son** el juego, no interrumpen.
5. **Nunca se resta puntaje**: un error solo corta la racha.
6. La lógica (`LogicaTopos`) va sin pantalla y es determinista con semilla, para el arnés (patrón de
   `LogicaRio`).
7. El motor no conoce el tema: animales, sonidos, madrigueras y fondo llegan del nivel.
8. **Nada de bichos** en ninguna ruta (perfiles de Nicole y Sofía): ni insectos ni arañas como animales,
   señuelos o decorado. Ranas y sapos quedan a decisión del PO (§16, pregunta 5).

## 3. ¿Se puede reutilizar un motor existente? (respuesta honesta)

- **`clasificar` con `nombrar_color_por_voz`** ("Coco nombra un color y se elige la gota entre 3") es el
  pariente más cercano: voz → elegir entre opciones. Pero no tiene asomos con tiempo, ni madrigueras, ni
  modo continuo, ni reloj de ronda. Meter todo eso deformaría un motor que ya está implementado y
  calibrado. **No se reutiliza.**
- **`emparejar`** no aplica (memoria, sin tiempo arriba).
- **Sí se reutilizan piezas de UI**, que ya son genéricas: `barra_record.gd` (barra con la banderita del
  récord), `pista_con_costo.gd` (pista que cuesta una estrellita), `celebracion.tscn`,
  `figura_vectorial.gd` y todo el modo equipo (`GestorTurnos`).
- **Pieza nueva, genérica**: `racha_toby.gd`, el equivalente de `racha_cresta.gd` (que está atada al sprite
  de Coco). Muestra la racha con las orejas paradas y la colita de Toby. La usan también `caminos`, `buscar`
  y `runner`.

**Conclusión**: motor nuevo `topos` (`scripts/motores/topos/`), con la UI común de siempre.

## 4. La escena (1280 × 720)

| Elemento | Dónde | Notas |
|---|---|---|
| Fondo | claro de la selva (HE-A7b), con el sendero de huellitas | sin personajes; las madrigueras son montículos de tierra con pasto |
| Botón casa (salir) | arriba a la izquierda, 96 px | como en todos los motores |
| Cometa | junto a la casa, arriba a la izquierda | tocarlo repite la instrucción (GDD §6.2) |
| **Collar de la meta** | arriba al centro (430-850, 20-90) | un hueso por acierto pedido por la meta. Se llena sin números (§9) |
| Barra de récord | a la derecha (x 1200-1260, y 120-600) | solo Brote y Estrella (`barra_record.gd`) |
| **Solcito de la ronda** | arriba a la derecha, sobre la barra (≤ 80 px) | cruza un arco pequeño; sin tic-tac (§9.3) |
| **Toby** | abajo a la izquierda (40-250, 460-720) | reacciona a todo; su antena es el botón de pista de Sofía (zona de toque de 96 px) |
| **Madrigueras** | zona útil x 300-1180, y 190-690 | grillas de la tabla de abajo |

| Madrigueras | Disposición | Ancho del hoyo | Animal | Zona de toque (animal + hoyo) |
|---|---|---|---|---|
| 3 | 1 fila, y 520; x 440 / 740 / 1040 | 240 px | 220 px | 270 × 320 px |
| 4 | 1 fila, y 500; x 380 / 620 / 860 / 1100 | 200 px | 190 px | 230 × 290 px |
| 6 | 2 × 3; y 380 / 600; x 440 / 740 / 1040 | 190 px | 170 px | 230 × 220 px |
| 9 | 3 × 3; y 300 / 470 / 640; x 470 / 720 / 970 | 150 px | 140 px | 200 × 165 px |

Todas las zonas de toque superan los 96 px (GDD §6.1), también la de 9. **La zona de toque cubre el hoyo
entero aunque el animal todavía esté subiendo**: tocar "justo cuando sale" vale.

## 5. Bucle de juego

### 5.1 Modo `tandas` (Semilla, Brote y Sofía z1-z2)

1. **Aviso** (0,15 s; 0,08 s en Estrella): sale tierrita de las madrigueras que van a abrirse.
2. **Asomo**: `asomados` animales suben a la vez en 0,12 s. Uno es el **pedido**; los otros son **distintos
   entre sí** y distintos del pedido.
3. **Sonido**: el pedido "habla" al terminar de subir. En Semilla, el sonido se repite cada 3 s desde su
   madriguera, y en Brote z1-z2 una vez más a la mitad de `t_arriba_s` (`repetir_sonido`).
4. **Toque**:
   - **Al pedido**: acierto (§7.2). Los demás bajan en 0,15 s.
   - **A otro animal**: hace **su propio** sonido (así se aprende cuál era cuál), pone cara de "¿yo?" y
     baja. El pedido sigue arriba hasta su tiempo.
   - **A una madriguera vacía**: tierrita y "puf".
5. **Escape** (solo Brote y Estrella): si se acaba `t_arriba_s`, el pedido baja con una risita desde
   adentro ("¡jiji!"), corta la racha y pasa el siguiente.
6. **Pausa** de `pausa_entre_pedidos` (0,5-0,9 s) y vuelta al paso 1.

### 5.2 Modo `continuo` (Sofía z3+): el Whac-a-Mole de verdad

- Los animales suben y bajan **cada uno a su ritmo**, escalonados: entre `asomados_min` y `asomados_max` arriba
  a la vez. Cada uno queda `t_arriba_s` ± 25 %.
- Cada `intervalo_pedido_s` suena uno de los que **están arriba y les queda al menos el 60 % de su tiempo**
  (así siempre hay tiempo justo para reaccionar).
- Tocar a uno que está arriba pero no sonó es un error (corta la racha). No hay que tocar a todos: solo a los
  que hablan.

### 5.3 Fin de la ronda

- **Semilla**: al completar `pedidos` (8 por defecto), fiesta y `completado`.
- **Brote y Estrella**: al terminar el solcito (60 s). **Con la meta llena → victoria; si no, derrota-gag
  (§10)**. Si la meta se llena antes, la ronda **sigue** hasta el final para sumar puntaje: el collar brilla
  dorado y suena "¡meta!", sin pausa.

## 6. Interacciones (tiempos y feedback)

| Acción | Respuesta | Tiempo | Feedback |
|---|---|---|---|
| Presionar sobre el pedido | Acierto | inmediato (en el mismo cuadro) | §7.2 |
| Presionar sobre otro animal | Error suave | inmediato | su sonido, ojos grandes "¿yo?", se encoge y baja en 0,2 s. **Nunca zumbido de error** |
| Presionar sobre una madriguera vacía | Nada | inmediato | tierrita (8 partículas) y "puf" suave |
| Presionar en el pasto | Nada | inmediato | se mecen 3 hojitas del pasto bajo el dedo |
| Tocar a Toby | — | inmediato | ladra feliz y menea la colita; en Semilla repite el sonido del pedido |
| Tocar la antena de Toby (Sofía) | Pista con costo (§10.4) | inmediato | `pista_con_costo.gd` |
| Tocar a Cometa | Repite la instrucción | inmediato | voz `instruccion` |
| Dos dedos a la vez | Cada uno cuenta por separado | — | permite los pedidos dobles de Sofía con dos manos; nunca se exige |

**Antirrebote** [Propuesta]: un mismo animal no se puede acertar dos veces (desde el primer toque hasta que
baja ignora toques). Un toque sobre un animal que está bajando (en sus 0,15 s) **todavía vale**: el ojo del
niño lo vio arriba.

## 7. Game feel

### 7.1 Animación de cada animal

- **Subir**: 0,12 s, ease-out-back: se estira a 1,15 de alto y se asienta en 0,08 s. Tierrita al salir.
- **Arriba**: respira (escala 1,00-1,03 a 1,5 Hz) y parpadea; mira hacia Toby.
- **Hablar**: al sonar, abre la boca grande y rebota una vez (0,2 s); un **anillo de ondas de sonido** (3
  arcos) sale de su cabeza. Así se **ve** quién habló, aunque el sonido no se oiga bien (tablet bajita).
  [Propuesta] En Estrella z3+ el anillo es mínimo (1 arco tenue): ahí oír es el reto.
- **Bajar**: 0,15 s, ease-in con aplastamiento (1,2 de ancho, 0,8 de alto).

### 7.2 El acierto

- El animal **salta fuera del hoyo** (0,35 s, arco de 60 px), gira, se ríe con su sonido en tono alto y un
  "¡pling!" que **sube un semitono por eslabón de racha** (tope 12), como el reventón del Río.
- Una estrellita y un hueso salen del animal y vuelan al collar (0,5 s). "+100" (o lo que valga) sube
  flotando 0,6 s desde el animal, del color de su pelaje.
- Toby da un saltito y menea la colita más rápido (§9.2).
- Con **"¡rapidito!"** (§9.1), estela dorada corta y doble campanita.

### 7.3 Toby, el anfitrión que reacciona

| Momento | Toby |
|---|---|
| Acierto | saltito, orejas arriba, colita |
| Racha ×3+ | ojos de estrella y la antena brilla |
| Error | ladea la cabeza y hace "¿mm?" (nunca triste) |
| Escape | se tapa los ojos con las patitas y se ríe |
| Toby dorado (§8.4) | aplaude con las patitas delanteras |
| Victoria | su celebración orgullosa (sentado, patitas arriba, ficha HE-A4b) |

### 7.4 SFX (lista para `guionista` y producción de audio)

Sonidos reales de animales (CC0) cortos: **≤ 0,9 s** y con un ataque claro; los largos se recortan. Además:
`tierrita`, `puf`, `pling` (con tono), `risita_hoyo`, `cosquillas`, `meta_llena`, `hueso_collar`,
`toby_ladrido_feliz`, `toby_dorado`, `fanfarria_selva`. Ningún sonido de error.

### 7.5 Celebración final

- Todos los animales de la ronda salen **a la vez** de sus madrigueras y hacen un **coro** con sus sonidos,
  en escalera (0,12 s cada uno) y afinados a un acorde mayor [Propuesta: los sonidos se transponen para que
  el coro suene bonito].
- Confeti de hojitas y estrellas (140 papelitos), Toby en su pose orgullosa y después
  `celebrar()` con el gesto real del hermano.
- Récord nuevo: "¡Nuevo récord!" con Toby sosteniendo un **hueso-trofeo** (equivalente al trofeo-cupcake).

## 8. Escala Semilla / Brote / Estrella

### 8.1 Tabla por perfil (zona 1 → zona 5)

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| `madrigueras` | 3 (z1-z3) → 4 (z4-z5) | 4 (z1-z2) → 6 (z3-z5) | 6 (z1-z2) → 9 (z3-z5) |
| `asomados` | 2 (GDD §4) → 3 en z4-z5 | 3 → 4 (GDD §4) | 4 → 6 (GDD §4) |
| `t_arriba_s` | **sin límite** | 2,6 → 1,8 | 1,6 → 1,0 |
| `modo` | tandas | tandas | tandas (z1-z2) → continuo (z3-z5) |
| `asomados_min` / `max` (continuo) | — | — | z3: 2 / 4 · z5: 3 / 6 |
| `intervalo_pedido_s` (continuo) | — | — | 1,4 → 1,1 |
| `pausa_entre_pedidos` | 0,9 | 0,7 → 0,6 | 0,5 |
| Duración | `pedidos`: 8 (≈ 1,5-2 min) | 60 s | 60 s |
| `meta` (aciertos) | — | 12 → 16 | 18 → 26 |
| `repetir_sonido` | cada 3 s | z1-z2 una vez | no |
| `ondas_visibles` | completas | completas | completas (z1-z2) → mínimas (z3+) |
| Sonidos parecidos (`similares`) | no | z4-z5: 1 par | desde z2 (pato/ganso, burro/caballo, perro/lobo, oveja/cabra) |
| Pedido escrito | no | z5, opcional: letra inicial (§8.3) | desde z3: 25 % de los pedidos con la palabra (§8.3) |
| Pedido doble | no | no | desde z4: 20 % |
| Toby dorado | sí (solo fiesta) | 1 cada ~15 s | 1 cada ~12 s |
| Coleccionauta disfrazado | no | no | z5: 1 cada ~15 s |
| Pista con costo | — | — | antena de Toby |
| Ayuda quieto | 4 s: el pedido salta y vuelve a sonar; 8 s: mano fantasma | — (hay reloj) | — |

**De dónde salen las metas** [Propuesta]: un ciclo de pedido dura ~2,6 s para Nicole (subir 0,12 + reacción
~1,3 + celebración 0,5 + pausa 0,7) → ~23 pedidos en 60 s; con ~80 % de acierto hace ~18. La meta de 12 es
cercana al **percentil 10** de una jugadora simulada de 5 años (~90 % gana al primer intento). Para Sofía,
~1,9 s por ciclo → ~31 pedidos; con ~85 % hace ~26; la meta de 18 es cercana al **percentil 30** (~70 % al
primer intento, como el reto alto de la v3). **Son estimaciones**: las fija `disenador-niveles` con el
jugador simulado de la maqueta.

### 8.2 Contenido por hermano (lo define HE-D6; aquí solo lo que el motor debe soportar)

- **Maxi**: granja grande y clara (vaca, perro, gato, pato, caballo) y su variante de **dinosaurios** [PO]:
  cada dino con un sonido cómico **muy distinto** (T-rex: rugido grave; spinosaurio: "glu-glu" con
  chapuzón; carnotauro: bufido; triceratops: "muuu" grave). No sirven rugidos parecidos entre sí.
- **Nicole**: caballos, ponys, jirafas (zumbido suave, el sonido real de la jirafa) y gatitos.
- **Sofía**: animales menos comunes (GDD §4) con sus sonidos reales: pudú, huemul, cóndor, lobo marino,
  ballena, búho, tucán, mono, hiena (se ríe), alpaca; y cachorros y ponys en sus variantes.

### 8.3 Pedidos especiales

- **Escrito (Sofía)**: en vez de un sonido, sobre el claro aparece un cartel de madera con la palabra en
  mayúsculas ("OVEJA", 64 px, máximo 8 letras). Tocar el **ícono de oreja** del cartel dice la palabra (apoyo
  de voz, GDD §2) y quita el bonus "¡rapidito!" de ese pedido.
- **Letra inicial (Nicole z5, opcional)** [Propuesta]: el cartel muestra **una letra** grande ("V") y Toby
  dice su sonido ("vvv…"). Se toca al animal que empieza con esa letra (vaca). Refuerzo de lectura (GDD §5),
  nunca obligatorio: si falla, el animal correcto salta y dice su nombre ("¡vvvaca!"). Va en un máximo del
  25 % de los pedidos.
- **Doble (Sofía z4+)**: suenan dos animales seguidos (0,4 s entre ambos). Hay que tocar **los dos, en
  cualquier orden** (no es Simon). Bonus +200. Si toca uno solo, ese cuenta como acierto normal.

### 8.4 Toby dorado y el Coleccionauta disfrazado

- **Toby dorado** [Ref: el topo dorado]: Toby asoma de una madriguera con el casco brillando, **sin sonido de
  pedido**. Tocarlo vale +300 y no corta ni suma racha. Si no se lo toca, baja guiñando el ojo. En Semilla
  aparece una vez por ronda, como sorpresa, y solo hace fiesta.
- **Coleccionauta disfrazado** [Ref: la bomba] (Sofía z5): asoma con orejas de cartón y bigotes pintados
  de un animal que **no** sonó. Tocarlo: se le cae el disfraz, le dan cosquillas y se ríe a carcajadas
  ("¡me descubriste!"), corta la racha. **Gag, no castigo**: nunca resta puntos.

## 9. Puntaje, estrellitas y récord

### 9.1 Puntaje (Brote y Estrella)

| Evento | Puntos |
|---|---|
| Acierto | 100 × racha (×1 a ×5) |
| "¡Rapidito!" (tocar en el primer 40 % de `t_arriba_s`) | +50, sin multiplicador |
| Toby dorado | +300 |
| Pedido doble completo | +200 |
| Meta llena | +500 una vez |

**Racha**: sube con cada acierto; se corta con un error, un escape o el Coleccionauta. Un Toby dorado no la
toca.

### 9.2 Cómo se ve la racha (sin leer)

`racha_toby.gd` (§3): la colita de Toby menea más rápido por eslabón; en ×2 se le paran las orejas, en ×3 ojos
de estrella, en ×5 la antena echa chispitas. Al cortarse, la colita vuelve despacio a su ritmo, con un "fiuu"
suave. **En Semilla** solo sonido y colita, sin número; **en Brote y Estrella**, además, "×3" grande junto a
Toby.

### 9.3 El solcito

Un sol de 70 px recorre un arco corto arriba a la derecha en 60 s. **Sin tic-tac, sin parpadeo, sin cambiar de
color y sin acelerar** (UX M7 de Parejas). Al final se pone detrás de una hoja.

### 9.4 Estrellitas y récord

- **Nicole**: 1-3 estrellitas por puntaje con `umbrales_puntaje` (`dos` = p50, `tres` = p80 de la
  jugadora simulada), la regla de Parejas (`motor-emparejar.md` §10.1.1). Sin huecos vacíos.
- **Sofía**: 1-3 por puntaje con `umbrales_puntaje` (p50 y p80 de su jugadora simulada); cada pista resta
  una; tras una derrota, la victoria siguiente da como máximo 2.
- **Récord personal** por estación y hermano (`registrar_record`), con la banderita de `barra_record.gd`.
  Nunca se muestra el récord de otro hermano.
- **Maxi**: sin puntaje ni récord.

## 10. El fallo

### 10.1 Semilla: el fallo no existe

- **Ambos animales celebran** (GDD §4): el que no sonó también hace su sonido y baila un poquito; el pedido,
  de inmediato, salta y vuelve a llamar ("¡muu, aquí!"). Solo el pedido avanza la ronda.
- El pedido **nunca se esconde** y la ayuda (4 s / 8 s) asegura que nunca se trabe.
- Tocar varias veces a cualquier animal siempre hace algo (sonido, cosquillas, risa).

### 10.2 Derrota-gag (Brote y Estrella): "¡Nos escondimos todos!"

- Se pone el sol con la meta sin llenar → **todos** los animales salen a la vez y hacen sus sonidos al mismo
  tiempo, desafinados y a todo volumen; a Toby se le **empaña el casco** del susto-risa, se le vuelan las
  orejas dentro del vidrio y estornuda ("¡achís!"), y los animales se caen de risa dentro de sus hoyos.
- 2,5 s. Cartel con el puntaje, el récord y la flecha circular grande; **tocar en cualquier parte del
  cartel** reintenta (≥ 160 × 160 px el botón).
- **Cero progreso perdido**: nada guardado se toca; la ronda vuelve a empezar desde cero.

### 10.3 Ayudas que evitan quedar trabado

- **Tras 2 derrotas seguidas** [Propuesta, patrón "Coco regala"]: Toby "ayuda olfateando" la ronda
  siguiente: la meta baja un 20 % y el pedido tiene las ondas completas.
- **Tras 3 derrotas**, Toby propone descansar ("¿vamos a jugar a otra cosa y volvemos?"), sin obligar.

### 10.4 Pista de Sofía (cuesta una estrellita)

Tocar la antena de Toby (`pista_con_costo.gd`): durante los **3 pedidos siguientes**, la madriguera del
pedido brilla 0,4 s antes de que suba. Con 1 sola estrellita, la pista es gratis ("¡esta va de regalo!").

## 11. Esquema JSON del nivel

`datos/niveles/animalia/<zona>/topos_<perfil>.json` (los nombres de zona los fija HE-D6).

```jsonc
{
  "id_nivel": "animalia_z1_topos_brote",
  "motor": "topos",
  "perfil": "brote",                       // semilla | brote | estrella
  "planeta": "animalia", "zona": "zona1_...",
  "fondo": "res://assets/.../claro_selva.png",
  "madrigueras": 4,                        // 3 | 4 | 6 | 9 (disposiciones de §4)
  "modo": "tandas",                        // tandas | continuo
  "asomados": 3,                           // tandas: cuántos suben por pedido
  "asomados_min": 2, "asomados_max": 4,    // continuo
  "intervalo_pedido_s": 1.4,               // continuo
  "t_arriba_s": 2.6,                       // null = sin límite (Semilla)
  "variacion_t_arriba": 0.25,              // continuo: ± fracción
  "aviso_s": 0.15,
  "pausa_entre_pedidos": 0.7,
  "pedidos": null,                         // Semilla: cantidad (defecto 8); null con duración
  "duracion_s": 60,                        // null en Semilla
  "meta": 12,                              // aciertos para ganar; null en Semilla
  "repetir_sonido": "una_vez",             // cada_3s | una_vez | no
  "ondas_visibles": "completas",           // completas | minimas
  "animales": [                            // pool del nivel
    { "id": "vaca", "sprite": "res://...", "sonido": "sfx/animales/vaca.ogg",
      "nombre_voz": "voces/animalia/nombres/vaca.wav", "inicial": "V" }
  ],
  "similares": [["pato", "ganso"]],        // pares que pueden asomar juntos como señuelo difícil
  "p_similar": 0.0,                        // probabilidad de usar un par similar en un pedido
  "pedido_escrito": { "p": 0.0, "tipo": "palabra" },   // palabra (Sofía) | letra (Nicole)
  "pedido_doble": { "p": 0.0, "separacion_s": 0.4 },
  "toby_dorado": { "cada_s": 15, "puntos": 300 },       // null = no aparece
  "impostor": null,                        // { "cada_s": 15 } Sofía z5
  "puntos": { "acierto": 100, "racha_max": 5, "rapidito": 50, "rapidito_fraccion": 0.4,
              "doble": 200, "meta": 500 },
  "umbrales_puntaje": { "dos": 1800, "tres": 2600 },    // Brote y Estrella
  "ayuda_idle_s": [4, 8],                  // Semilla: salto + sonido; mano fantasma
  "regalo_tras_derrotas": { "derrotas": 2, "meta_factor": 0.8 },
  "pistas_cuestan_estrellita": false,      // true en Estrella
  "pista_pedidos": 3,
  "lineas_voz": {
    "intro": "…", "instruccion": "…", "meta_llena": "…", "victoria": ["…"],
    "derrota_gag": "…", "regalo": "…", "descansar": "…", "pista_usada": "…",
    "record": "…", "primer_record": "…", "impostor": ["…"], "toby_dorado": ["…"]
  }
}
```

- Validación al cargar (`push_warning` y valor por defecto): `asomados ≤ madrigueras`; el pool tiene al menos
  `asomados` animales **con sonidos distintos**; `meta` alcanzable con el ciclo mínimo (§8.1).
- Rejugar: el orden de pedidos se baraja (nunca el mismo animal 2 veces seguidas como pedido) y las
  madrigueras se asignan al azar.

## 12. Contrato con el núcleo y con el modo equipo

### 12.1 Solitario

- `MotorTopos extends MinijuegoBase`. Lee `nivel`, nunca navega, emite `completado` vía `celebrar()`.
- **`asegurar_victoria(destellos, estrellitas)` en el instante en que suena el final del sol con la meta
  llena** (o el último pedido de Semilla), antes de la fiesta.
- `registrar_record(puntaje)` y `obtener_record()` para la banderita; `presentacion_vista("toby_dorado")`
  para la presentación de una sola vez.
- Señales de `LogicaTopos` (sin pantalla): `asomo(id_madriguera, id_animal, es_pedido)`,
  `sono(id_animal)`, `acierto(id_madriguera, puntos, racha, rapidito)`, `error(id_madriguera, id_animal)`,
  `escape(id_madriguera)`, `meta_llena()`, `ronda_terminada(gano, puntaje)`.

### 12.2 Modo equipo (`"modo_juego": "equipo"`, `modo-equipo.md` §11.4)

- **Ronda compartida**: un solo claro; el turno se mide en **pedidos**, no en tiempo.
- **Tope por turno** (`aciertos_max_turno`): semilla 1, brote 3, estrella 4. Cada acierto llama
  `turnos.notificar_acierto()`. Al llegar al tope, el gestor emite `tope_alcanzado`; el motor espera que el
  animal termine su salto y llama `confirmar_turno_estable()`.
- **Fallo que corta el turno**: el **escape** del pedido → `terminar_turno(true)` cuando el animal terminó
  de bajar. El **error** (tocar a otro) → `notificar_fallo_suave()`, no corta.
- **Maxi**: su capa de Semilla (el pedido no se esconde y las ondas son completas). Con `semilla_auto_s`,
  `jugada_automatica_pedida` hace que el pedido salte solo hacia la barra del equipo como un acierto.
- `aplicar_perfil_turno(perfil)` al recibir `turno_iniciado`: cambia `t_arriba_s`, `asomados` y las ondas
  según quien juega (cada uno con su dificultad).
- **Pase**: durante el pase no asoma nadie (todos abajo).
- **Derrota del equipo**: `gag_derrota_aspirar(destino)` hace volar a los animales asomados, en espiral, a la
  boca de la mochila-torre; `gag_derrota_devolver(perfil)` los estornuda de vuelta y caen en sus hoyos con un
  "¡plop!"; `gag_derrota_terminar_ya` deja todo abajo al instante; `reintentar_equipo()` no hace nada;
  `contar_logro_equipo()` = aciertos de la ronda.
- `ancla_meta_turno()`: borde izquierdo de la zona de madrigueras (x 290, centro y).
- Sin `puntaje` en equipo (M1 de Parejas): la racha va solo con sonido y la colita.

## 13. Maqueta HTML jugable (HE-110): `docs/maquetas/topos-v1.html`

Debe demostrar, en un solo archivo sin dependencias:

1. Los **3 perfiles** y la **zona** elegibles desde un panel (z1 y z5 de cada uno como mínimo), con las
   disposiciones de 3, 4, 6 y 9 madrigueras.
2. Los modos **tandas** y **continuo**, con aviso, subir, hablar (ondas) y bajar con los tiempos de §7.1.
3. Respuesta al **presionar**, el acierto con tono por racha, el error con el sonido del otro animal y el
   escape con risita (sonidos de animales provisionales con síntesis o CC0).
4. Meta, solcito, puntaje, racha con una colita dibujada, récord en `localStorage` y la derrota-gag.
5. Toby dorado, pedido escrito, pedido doble y el Coleccionauta disfrazado.
6. Un **jugador simulado** por edad (tiempo de reacción y tasa de error configurables) que juegue 1.000 rondas
   y dé el % de victorias y los percentiles de puntaje: es lo que `disenador-niveles` usa para fijar `meta`
   y `umbrales_puntaje`.

## 14. Riesgos de usabilidad (para `experto-ux-parvulo`)

| # | Riesgo | Propuesta / qué mirar |
|---|---|---|
| R1 | **El sonido no se oye** (tablet con volumen bajo, living ruidoso) y el juego se vuelve azar | Ondas visibles en Semilla y Brote; en Sofía z3+ las mínimas se pueden subir a completas desde la zona de padres si hace falta |
| R2 | Maxi **toca todo lo que se mueve** (es su edad) | No pasa nada malo: todos celebran. Medir si entiende "el que sonó" o solo disfruta; ambas cosas valen |
| R3 | **Presionar** en vez de soltar puede hacer que un dedo que se apoya sin querer cuente | En Semilla no importa; en Brote y Estrella un toque accidental es un error suave. Observar en el playtest |
| R4 | **Frustración de Sofía** con el modo continuo z5 (1,0 s arriba) | Meta al p30, regalo tras 2 derrotas, pista con costo; medir en el simulador y en el playtest |
| R5 | **Sonidos parecidos** que ni un adulto distingue en el parlante de la tablet | Escuchar cada par en la tablet real antes de aprobar el pool (lo valida `tester-qa` con el PO) |
| R6 | La **palabra escrita** para Sofía con fuente chica o letras de molde confusas | 64 px, mayúsculas, máximo 8 letras, fuente del juego |
| R7 | El Coleccionauta disfrazado **da miedo** o confunde ("¿es malo?") | Siempre ridículo y torpe, el disfraz se le cae solo; validar con el guion |
| R8 | **Dos dedos** en pedidos dobles: un dedo apoyado en el borde de la tablet cuenta | Los toques fuera de la zona útil se ignoran |
| R9 | Con 9 madrigueras, el animal de arriba queda tapado por la **mano** del niño al tocar el de abajo | Fila de arriba en y 300 deja aire; mirar en la tablet |

## 15. Qué debe probar el arnés (`herramientas/qa_test_topos.gd`, para `tester-qa`)

1. Generador con semilla: en 3.000 pedidos, nunca dos asomados iguales, nunca el mismo pedido dos veces
   seguidas, `p_similar` y `pedido_escrito.p` dentro de ± 5 puntos.
2. Modo continuo: nunca menos de `asomados_min` ni más de `asomados_max` arriba; un pedido siempre sale con
   ≥ 60 % de su tiempo por delante.
3. Acierto, error, escape y madriguera vacía con sus señales; un animal no se acierta dos veces; un toque en
   la bajada vale.
4. Racha y puntaje: tabla de §9.1; el error no resta; el Toby dorado no toca la racha.
5. Semilla: el pedido nunca se esconde; la ayuda salta a los 4 s y la mano a los 8 s; `completado` tras
   `pedidos`.
6. Fin de ronda: meta llena → victoria con `asegurar_victoria` antes de la fiesta; sin meta → derrota-gag y
   reintento; el regalo tras 2 derrotas baja la meta.
7. Equipo: tope por perfil, escape → `terminar_turno(true)`, error → `notificar_fallo_suave`, jugada
   automática de Maxi, gag aspirar y devolver.
8. Escena: presionar sobre cada disposición de madrigueras con `push_input`, zona de toque ≥ 96 px.

## 16. Preguntas abiertas para el PO

1. **[Abierta] "Sopa de burbujas" (Letralandia)**: es este mismo esqueleto con letras. ¿Lo dejamos como
   **otro nivel del motor `topos`** (mismo motor y misma referencia, otro tema: no repite mecánica en otro
   *juego*, sino que reutiliza el motor) o, cuando se diseñe, toma otra referencia? Recomiendo lo primero:
   es la regla de oro 3 aplicada (un motor, N niveles).
2. **[Abierta] ¿Nicole puede perder en este juego?** Propongo que sí, con meta muy generosa (p10, ~90 % al
   primer intento), porque el reto es la velocidad. La alternativa es la de Parejas: nunca pierde y solo
   gana estrellitas por puntaje.
3. **[Abierta] Letra inicial para Nicole en z5**: ¿la quieren como refuerzo de lectura (opcional, 25 % de los
   pedidos) o mejor dejar el juego solo con sonidos?
4. **[Abierta] Dinosaurios de Maxi**: ¿en qué zonas? Propongo la granja en z1-z2 y los dinos en z3-z5 (es
   su gusto más fuerte; mejor que llegue como sorpresa que crece).
5. **[Abierta] Ranas y sapos**: ¿cuentan como "bichos" para Nicole y Sofía? Hasta que se decida, no se usan.
