# Ficha de motor — `topos` («¿Quién habla?», tipo Whac-a-Mole)

- **Autor**: `disenador-mecanicas`, 05-Nov-2026 (tarjeta HE-106).
- **Estado**: PROPUESTA. Falta: maqueta HTML (HE-110) y aprobación del PO, auditoría de `experto-ux-parvulo`
  (HE-111), calibración de `disenador-niveles` (HE-D6) con el simulador de la maqueta, y voces de `guionista`
  (HE-112). La implementación (HE-116) espera al playtest del capítulo 1 (HE-18).
- **Actualización HE-124 (05-Nov-2026, política de derrota)**: los tres perfiles pueden perder (GDD §6 regla
  11). Cambian metas, Semilla pasa a tener reloj y escape, y el regalo de Sofía llega tras 3 derrotas. Las
  preguntas de §16 quedan **cerradas** (el PO delegó la decisión). Los cambios van marcados **[HE-124]**.
- **Fuentes**: GDD §1, §4 (Animalia), §5 ("Mecánicas probadas y reto real"), §6 y §8;
  `docs/perfil-jugadores.md`; `docs/stack-tecnico.md`; `scripts/base/minijuego_base.gd`;
  `scripts/base/gestor_turnos.gd`; `docs/fichas/modo-equipo.md` §11.4; patrón de `motor-rio.md` y
  `motor-emparejar.md` §10 (racha, récord, estrellitas de Nicole por puntaje); Toby en
  `docs/guia-estilo-generacion.md` §3 (HE-A4b) y el ambiente de Animalia (HE-A7b).

**Marcas**: **[PO]** decisión del PO (05-Nov-2026) · **[Ref]** tomado tal cual del juego de referencia ·
**[Propuesta]** decisión de `disenador-mecanicas`, reversible · **[HE-124]** [Decisión 05-Nov, HE-124]:
política de derrota del PO y decisiones que el PO delegó en `disenador-mecanicas`.

---

## 1. La mecánica en una frase y la referencia

**Los animales asoman de sus madrigueras en el claro de la selva; suena la voz de uno ("¡muuu!") y hay que
tocar al que habló antes de que se vuelva a esconder.**

| Whac-a-Mole (arcade de 1976 y sus versiones móviles) | Qué tomamos | Qué no |
|---|---|---|
| Madrigueras fijas; los topos suben y bajan solos | Igual: entre 3 y 9 madrigueras según la edad. Suben con estiramiento y bajan con aplastamiento | El mazo: aquí se **toca** con el dedo. Los animales nunca reciben golpes: se les hace **cosquillas** y se ríen (L8 de `motor-lanzar.md`: nada de dolor) |
| La partida dura un tiempo fijo (~30-60 s) y el puntaje es la cantidad de aciertos | Ronda de 60 s con meta, puntaje y récord para Brote y Estrella; ronda de 45-60 s con meta para Semilla [HE-124] | En Semilla no hay puntaje ni récord (§8) |
| Al avanzar la partida, cada topo **queda menos tiempo arriba** y salen **más a la vez** | Es nuestra escala principal: `t_arriba_s` y `asomados` (§8) | — |
| Las versiones móviles agregan el **topo dorado** (bonus) y la **bomba** (no se toca) | **Toby dorado** asoma y vale un bonus; en Sofía z5, el **Coleccionauta disfrazado** es el "no lo toques" | La bomba que te quita puntos: aquí solo corta la racha (§10) |
| Combo por aciertos seguidos | Racha ×1-×5 con la colita de Toby (§9) | — |

**Lo propio de Animalia**: no se toca a cualquiera que asoma, sino **al que sonó** (discriminación auditiva:
el tema "animales y sus sonidos" del GDD §4). Los demás asomados son los señuelos naturales.

**Escala por edad sacada de Whac-a-Mole** [Ref + Propuesta]: el arcade sube la dificultad bajando el tiempo
arriba (de ~1,5 s a ~0,6 s para un adulto, valores aproximados de las versiones populares) y subiendo los
topos simultáneos (de 1 a 3). Nuestros tiempos parten de esos valores y los alargan con el tiempo de
reacción de cada edad: **× 1,3 para 8 años y × 1,7 para 5 años** sobre el adulto. A eso se suma la
discriminación del sonido. En Maxi el animal espera **el triple** de su tiempo de reacción (6 s) antes de
esconderse [HE-124; antes esperaba sin límite].

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
5. **Escape** (los tres perfiles [HE-124]): si se acaba `t_arriba_s`, el pedido baja con una risita desde
   adentro ("¡jiji!"), corta la racha y pasa el siguiente. En Semilla el escape es más lento y amable: el
   animal saluda con la patita antes de bajar (0,3 s) y no hay racha que cortar.
6. **Pausa** de `pausa_entre_pedidos` (0,5-0,9 s) y vuelta al paso 1.

### 5.2 Modo `continuo` (Sofía z3+): el Whac-a-Mole de verdad

- Los animales suben y bajan **cada uno a su ritmo**, escalonados: entre `asomados_min` y `asomados_max` arriba
  a la vez. Cada uno queda `t_arriba_s` ± 25 %.
- Cada `intervalo_pedido_s` suena uno de los que **están arriba y les queda al menos el 60 % de su tiempo**
  (así siempre hay tiempo justo para reaccionar).
- Tocar a uno que está arriba pero no sonó es un error (corta la racha). No hay que tocar a todos: solo a los
  que hablan.

### 5.3 Fin de la ronda

- **Los tres perfiles** [HE-124]: al terminar el solcito (`duracion_s`: Semilla 45-60 s, Brote y Estrella 60
  s). **Con la meta llena → victoria; si no, derrota-gag (§10)**. Si la meta se llena antes, la ronda
  **sigue** hasta el final para sumar puntaje (en Semilla, para seguir jugando: a Maxi le encanta que los
  animales sigan saliendo; el collar lleno ya no puede vaciarse): el collar brilla dorado y suena "¡meta!",
  sin pausa.
- **Rondas** [HE-124, cierra la pregunta 4 de `planeta-animalia-zonas.md`]: Brote y Estrella juegan
  `rondas: 2` de 60 s con mini-fiesta entre ellas (meta por ronda, puntaje sumado; si pierde la 2.ª, reintenta
  **solo la 2.ª**). Semilla juega `rondas: 1`.
- `pedidos` (cantidad fija sin reloj) queda en el esquema solo para el modo **ayuda fuerte** de Semilla
  (§10.3) y para el modo equipo.

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
| `t_arriba_s` | **6,0 → 5,0** [HE-124] (`null` solo con la ayuda fuerte, §10.3) | 2,6 → 1,8 | 1,6 → 1,0 |
| `modo` | tandas | tandas | tandas (z1-z2) → continuo (z3-z5) |
| `asomados_min` / `max` (continuo) | — | — | z3: 2 / 4 · z5: 3 / 6 |
| `intervalo_pedido_s` (continuo) | — | — | 1,4 → 1,1 |
| `pausa_entre_pedidos` | 0,9 | 0,7 → 0,6 | 0,5 |
| Duración [HE-124] | `duracion_s` 45 → 60, `rondas: 1` | `rondas: 2` × 60 s | `rondas: 2` × 60 s |
| `meta` (aciertos por ronda) [HE-124] | **5 → 7** (≈ p10) | **14 → 18** (≈ p25; antes 12 → 16) | **20 → 28** (≈ p40; antes 18 → 26) |
| `repetir_sonido` | cada 3 s | z1-z2 una vez | no |
| `ondas_visibles` | completas | completas | completas (z1-z2) → mínimas (z3+) |
| Sonidos parecidos (`similares`) | no | z4-z5: 1 par | desde z2 (pato/ganso, burro/caballo, oveja/cabra, alpaca/jirafa; búho/lechuza y tricahue/choroy en z4-z5) [HE-124: sin perro/lobo] |
| Pedido escrito | no | z5, opcional: letra inicial (§8.3) | desde z3: 25 % de los pedidos con la palabra (§8.3) |
| Pedido doble | no | no | desde z4: 20 % |
| Toby dorado | sí (solo fiesta) | 1 cada ~15 s | 1 cada ~12 s |
| Coleccionauta disfrazado | no | no | z5: 1 cada ~15 s |
| Pista con costo | — | — | antena de Toby |
| Ayuda quieto | **3 s**: el pedido salta y vuelve a sonar; **5 s**: mano fantasma [HE-124: antes 4 / 8 s, que no caben en 6 s arriba] | — (hay reloj) | — |
| Derrota [HE-124] | sí, suave (§10.2) | sí, desde z1 | sí |
| `regalo_tras_derrotas` [HE-124] | 2 → meta × 0,7 | 2 → meta × 0,8 | **3** → meta × 0,85 |
| `ayuda_fuerte_tras_derrotas` [HE-124] | 3 (§10.3) | — | — |

**De dónde salen las metas** [HE-124; antes Propuesta con p10/p30]: un ciclo de pedido dura ~2,6 s para
Nicole (subir 0,12 + reacción ~1,3 + celebración 0,5 + pausa 0,7) → ~23 pedidos en 60 s; con ~80 % de acierto
hace ~18 (media) y su p10 está cerca de 12. La meta nueva de **14** es cercana al **percentil 25** (~75 % gana
al primer intento). Para Sofía, ~1,9 s por ciclo → ~31 pedidos; con ~85 % hace ~26; la meta nueva de **20**
es cercana al **percentil 40** (~60 % al primer intento). Para Maxi, ~4 s por ciclo (reacción de 2 años ~2,5
s + celebración + pausa 0,9) → ~11 pedidos en 45 s; con ~70 % de acierto antes del escape hace ~8 y su p10
ronda 5: la meta de **5** deja ~90 % de victorias al primer intento. **Son estimaciones**: las ajusta
`disenador-niveles` con el jugador simulado de la maqueta **manteniendo los percentiles** (p10 / p25 / p40),
que son la regla del PO; los números concretos pueden moverse.

### 8.2 Contenido por hermano (lo define HE-D6; aquí solo lo que el motor debe soportar)

- **Maxi**: granja grande y clara (vaca, perro, gato, pato, caballo) y su variante de **dinosaurios** [PO]:
  cada dino con un sonido cómico **muy distinto** (T-rex: rugido grave; spinosaurio: "glu-glu" con
  chapuzón; carnotauro: bufido; triceratops: "muuu" grave). No sirven rugidos parecidos entre sí.
- **Nicole**: caballos, ponys, jirafas (zumbido suave, el sonido real de la jirafa) y gatitos.
- **Sofía**: animales menos comunes (GDD §4) con sus sonidos reales: pudú, huemul, cóndor, lobo marino,
  ballena, búho, tucán, mono, alpaca; y cachorros y ponys en sus variantes. **[HE-124] Sin depredadores que
  asusten** (cierra la pregunta 6 de `planeta-animalia-zonas.md`): fuera la hiena y el lobo; el par
  perro/lobo de §8.1 sale; quedan **pato/ganso, oveja/cabra, burro/caballo y alpaca/jirafa**, y se suman
  **búho/lechuza y tricahue/choroy** en z4-z5 (como en `planeta-animalia-zonas.md` §4.1).

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
- **Destellos y estrellitas solo al ganar** [HE-124]: una ronda perdida da 0 y no resta nada.

## 10. El fallo

### 10.1 Semilla: equivocarse sigue siendo bonito, perder es posible pero suave [HE-124]

- **Ambos animales celebran** (GDD §4): el que no sonó también hace su sonido y baila un poquito; el pedido,
  de inmediato, salta y vuelve a llamar ("¡muu, aquí!"). Solo el pedido avanza la ronda. Tocar al
  equivocado **no** es un fallo en Semilla: lo único que hace perder es que el sol se ponga sin la meta.
- El pedido ahora **sí se esconde** si nadie lo toca en `t_arriba_s` (6,0 → 5,0 s, el triple de lo que tarda
  Maxi en reaccionar), con el escape amable de §5.1. La ayuda (3 s salto y sonido; 5 s mano fantasma) llega
  **antes** del escape: un Maxi que está jugando casi nunca deja escapar a nadie.
- Tocar varias veces a cualquier animal siempre hace algo (sonido, cosquillas, risa).

### 10.2 Derrota-gag: "¡Nos escondimos todos!"

- Se pone el sol con la meta sin llenar → **todos** los animales salen a la vez y hacen sus sonidos al mismo
  tiempo, desafinados y a todo volumen; a Toby se le **empaña el casco** del susto-risa, se le vuelan las
  orejas dentro del vidrio y estornuda ("¡achís!"), y los animales se caen de risa dentro de sus hoyos.
- 2,5 s. Cartel con el puntaje, el récord y la flecha circular grande; **tocar en cualquier parte del
  cartel** reintenta (≥ 160 × 160 px el botón).
- **Variante Semilla** [HE-124]: 1,5 s, volumen normal (no "a todo volumen") y **afinado** como el coro de la
  victoria pero con un estornudo final de Toby que tira a todos de espaldas de risa. Sin puntaje en el cartel:
  solo la flecha circular gigante con la carita de Toby. La voz `derrota_gag` de Semilla invita
  ("¡otra vez, otra vez!"), nunca dice "perdiste".
- **Cero progreso perdido**: nada guardado se toca; la ronda vuelve a empezar desde cero (con 2 rondas, la
  ronda ya ganada queda ganada). Nunca hay pantalla roja, zumbido ni cara triste.

### 10.3 Regalo, ayuda fuerte y descanso [HE-124]

| | Sofía · Estrella | Nicole · Brote | Maxi · Semilla |
|---|---|---|---|
| **Regalo** (Toby "ayuda olfateando" la ronda siguiente: meta × `meta_factor` y ondas completas) | tras **3** derrotas seguidas, × 0,85 | tras **2**, × 0,8 | tras **2**, × 0,7 |
| **Ayuda fuerte** (victoria asegurada en el intento siguiente) | — | — | tras **3**: el modo de antes — `t_arriba_s: null` (el animal **espera**), `pedidos: 6` sin reloj y la mano fantasma a los 4 s. Toby lo anuncia como un juego nuevo ("¡ahora yo te ayudo a buscar!"), nunca como "más fácil" |
| **Ofrecer descansar** ("¿vamos a jugar a otra cosa y volvemos?"), sin obligar | tras 4 | tras 3 | — (la ayuda fuerte ya resuelve) |

Las derrotas se cuentan **seguidas y por estación** (una victoria las reinicia). Salir al mapa no las borra
durante la sesión, para que el regalo no se "pierda" por salir.

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
  "t_arriba_s": 2.6,                       // null = sin límite (solo ayuda fuerte de Semilla). [Decisión 05-Nov, HE-124] Semilla 6.0 → 5.0
  "variacion_t_arriba": 0.25,              // continuo: ± fracción
  "aviso_s": 0.15,
  "pausa_entre_pedidos": 0.7,
  "pedidos": null,                         // cantidad sin reloj: solo ayuda fuerte de Semilla y equipo. [Decisión 05-Nov, HE-124]
  "duracion_s": 60,                        // por ronda. [Decisión 05-Nov, HE-124] Semilla 45 → 60 (ya no null)
  "rondas": 2,                             // [Decisión 05-Nov, HE-124] clave nueva: semilla 1 · brote 2 · estrella 2
  "meta": 14,                              // aciertos por ronda. [Decisión 05-Nov, HE-124] semilla 5→7 (p10) · brote 14→18 (p25) · estrella 20→28 (p40)
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
  "ayuda_idle_s": [3, 5],                  // Semilla: salto + sonido; mano fantasma. [Decisión 05-Nov, HE-124] antes [4, 8]
  "regalo_tras_derrotas": { "derrotas": 2, "meta_factor": 0.8 },   // [Decisión 05-Nov, HE-124] semilla {2, 0.7} · brote {2, 0.8} · estrella {3, 0.85}
  "ayuda_fuerte_tras_derrotas": null,      // [Decisión 05-Nov, HE-124] clave nueva. Semilla: { "derrotas": 3, "t_arriba_s": null, "pedidos": 6, "ayuda_idle_s": [2, 4] }
  "descanso_tras_derrotas": 3,             // [Decisión 05-Nov, HE-124] clave nueva: semilla null · brote 3 · estrella 4
  "pistas_cuestan_estrellita": false,      // true en Estrella
  "pista_pedidos": 3,
  "lineas_voz": {
    "intro": "…", "instruccion": "…", "meta_llena": "…", "victoria": ["…"],
    "derrota_gag": "…", "regalo": "…", "ayuda_fuerte": "…", "descansar": "…", "pista_usada": "…",
    "record": "…", "primer_record": "…", "impostor": ["…"], "toby_dorado": ["…"]
  }
}
```

- Validación al cargar (`push_warning` y valor por defecto): `asomados ≤ madrigueras`; el pool tiene al menos
  `asomados` animales **con sonidos distintos**; `meta` alcanzable con el ciclo mínimo (§8.1).
- Retrocompatibilidad [HE-124]: sin `rondas` → 1; sin `ayuda_fuerte_tras_derrotas` → no hay; sin
  `descanso_tras_derrotas` → 3; si un nivel de Semilla viejo trae `t_arriba_s: null` y `duracion_s: null`, se
  juega con `pedidos` y sin derrota (comportamiento anterior) y se avisa con `push_warning`.
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
- **Maxi**: su capa de Semilla (en equipo el pedido **no** se esconde y las ondas son completas: HE-124 no
  cambia el modo equipo, que tiene su propia regla de derrota compartida). Con `semilla_auto_s`,
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
| R4 | **Frustración de Sofía** con el modo continuo z5 (1,0 s arriba) y la meta al p40 [HE-124] | El PO acepta "que se frustren un poco"; la red es la pista con costo, el regalo tras 3 y el descanso tras 4. Medir en el playtest cuántas derrotas seguidas tolera antes de dejar el juego: si abandona antes de la 3.ª, bajar a p35 |
| R10 | **Maxi y el escape** [HE-124]: ¿entiende que el animal se fue o lo vive como "se rompió"? | Escape lento con saludo; la derrota de Semilla es corta, afinada y sin puntaje. Observar si después de una derrota vuelve a tocar la flecha solo (es la señal de que fue gracioso) |
| R11 | **Ayuda fuerte de Maxi** se nota como "modo bebé" para sus hermanos que miran | Se presenta como juego nuevo de Toby y solo dura un intento; no se ve en el mapa |
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
5. Semilla [HE-124]: el pedido se esconde a los `t_arriba_s`; la ayuda salta a los 3 s y la mano a los 5 s;
   tocar al equivocado no cuenta como fallo; tras 3 derrotas seguidas la ayuda fuerte juega con
   `t_arriba_s: null` y `pedidos` y siempre termina en victoria.
6. Fin de ronda: meta llena → victoria con `asegurar_victoria` antes de la fiesta; sin meta → derrota-gag y
   reintento de un toque; con 2 rondas, la ganada no se repite; el regalo baja la meta tras 2 derrotas
   (Semilla y Brote) o tras 3 (Estrella); una derrota da 0 destellos y 0 estrellitas y no toca nada guardado.
7. Equipo: tope por perfil, escape → `terminar_turno(true)`, error → `notificar_fallo_suave`, jugada
   automática de Maxi, gag aspirar y devolver.
8. Escena: presionar sobre cada disposición de madrigueras con `push_input`, zona de toque ≥ 96 px.

## 16. Decisiones (antes preguntas abiertas) [HE-124: el PO delegó, 05-Nov-2026]

1. **"Sopa de burbujas" (Letralandia)** → **será otro nivel del motor `topos`** (mismo motor y misma
   referencia, otro tema). Es la regla de oro 3 aplicada: un motor, N niveles; no repite la mecánica en otro
   juego.
2. **¿Nicole puede perder?** → **Sí, y los tres perfiles** (política del PO, GDD §6 regla 11): meta al p25
   para Nicole, p40 para Sofía y p10 para Maxi (§8.1, §10).
3. **Letra inicial para Nicole en z5** → **sí**, opcional, en el 25 % de los pedidos y nunca requisito (si
   falla, el animal correcto dice su nombre).
4. **Dinosaurios de Maxi** → **granja en z1-z2, el triceratops asoma en z3 y los dinos protagonizan z4-z5**
   (tabla de `planeta-animalia-zonas.md` §4.1).
5. **Ranas y sapos** → **no se usan en Animalia v1** en ninguna ruta (el mapa y el modo equipo son
   compartidos). Se revisa solo si en un playtest Nicole o Sofía las piden.
