# Ficha de zonas — Mapa del Planeta Animalia (capítulo 2)

> **Decisión del PO (05-Nov-2026)**: el planeta 2 es **Animalia**, réplica completa de Arcoíris: 5 zonas ×
> 4 juegos × 3 rutas, batalla con jefe propio y ceremonia de partida. Se diseña ya, en paralelo y sin WIP
> de Dev. La implementación (HE-116 a HE-123) espera el playtest del capítulo 1 (HE-18).
>
> Esta ficha (tarjeta **HE-D6**) aplica a Animalia el modelo de zonas de `docs/diseno-juego.md` §3 con el
> mismo formato que `docs/fichas/planeta-arcoiris-zonas.md`. Las mecánicas, el bucle, el feedback y el
> esquema JSON de cada juego viven en sus fichas de motor:
>
> | Juego | Motor | Referencia | Ficha |
> |---|---|---|---|
> | ¿Quién habla? | `topos` | Whac-a-Mole | `docs/fichas/motor-topos.md` |
> | Cada quien a su casa | `caminos` | Flow Free | `docs/fichas/motor-caminos.md` |
> | Escondite animal | `buscar` | ¿Dónde está Wally? / Hidden Folks | `docs/fichas/motor-buscar.md` |
> | Carrera de Toby | `runner` | el dinosaurio de Chrome | `docs/fichas/motor-runner.md` |
>
> Aquí solo se describe **qué contenido lleva cada estación y cómo cambia zona a zona para cada hermano**,
> con números concretos para la maqueta y el playtest.

- **Autor**: `disenador-niveles`, 05-Nov-2026 (HE-D6).
- **Estado**: PROPUESTA. Faltan la aprobación del PO, la auditoría de `experto-ux-parvulo` (HE-111), la
  calibración con los jugadores simulados de las maquetas (HE-110), las voces de `guionista` (HE-112) y el
  arte de `disenador-personajes` (HE-114). **No se crea nada en `datos/` todavía**: el borrador del
  `mapa.json` va en §9.
- **Actualización HE-124 (05-Nov-2026, `disenador-mecanicas`, política de derrota del PO)**: los tres
  hermanos pueden perder en los 4 juegos (GDD §6 regla 11). Esta ficha recibe las metas, relojes, corazones
  y regalos nuevos por perfil y zona, y **todas sus preguntas abiertas y decisiones [Prov] quedan cerradas**
  (el PO delegó la decisión). Las celdas cambiadas van marcadas **[HE-124]** ([Decisión 05-Nov, HE-124]).
- **Fuentes**: GDD §1, §3, §4 (Animalia y "dinosaurios de Maxi"), §5, §6 y §8; `docs/perfil-jugadores.md`;
  Toby (HE-A4b) y el ambiente de Animalia (HE-A7b) en `docs/guia-estilo-generacion.md` §3; las 4 fichas de
  motor; `docs/fichas/hangar-nave.md` (ala derecha); `docs/fichas/album-recuerdos.md` §4-§5;
  `datos/planetas/arcoiris/mapa.json` (formato del mapa).

**Marcas**: **[PO]** decisión del PO · **[Prov]** opción que recomienda una ficha de motor ante una
pregunta abierta, que esta ficha asume como **provisional, falta el OK del PO** · **[Propuesta]** decisión
de `disenador-niveles`, reversible · **[HE-124]** [Decisión 05-Nov, HE-124] (§13 ya no tiene preguntas
abiertas).

---

## 1. Idea en una frase

**Toby prepara el Gran Desfile de Animalia para recibir a los hermanos, pero el planeta está durmiendo la
siesta**. Cada zona que completan **despierta un rincón**: sus animales abren los ojos, se sacuden y se suman
al desfile que recorre el sendero de huellitas. En la zona secreta despiertan los más grandes de todos, los
dinosaurios, y el desfile queda completo.

- Es el equivalente de "devolver los colores" de Arcoíris, pero con **sonido y movimiento**: las zonas
  dormidas están quietas y en silencio, con burbujitas "zzz" y colores apagados; las despiertas se mueven y
  suenan. Encaja con el tema del planeta: animales, sus sonidos y sus hábitats (GDD §4).
- No hay villano en el hilo de las zonas. El Coleccionauta llega recién en la batalla (HE-115).
- Para Maxi es causa-efecto puro (juego → el animal se despierta y baila); para Nicole, los animales son
  amigos nuevos que se suman a su fiesta; para Sofía, cada rincón trae datos curiosos y animales de Chile.

---

## 2. Estructura del mapa del planeta

```
Mapa Estelar ──► Planeta Animalia (mapa del planeta)
                   │
                   ├─ Zona 1 · El Campamento de Toby ....... despierta el corralito
                   ├─ Zona 2 · La Laguna de los Nenúfares .. despierta la laguna
                   ├─ Zona 3 · La Pradera de las Jirafas ... despierta la pradera
                   │     └─► escena de historia «La huellita de Toby» + pieza de la nave (ala derecha)
                   │     └─► aparece el hito de la batalla de Animalia (HE-115)
                   ├─ Zona 4 · El Árbol de los Nidos ....... despierta la selva alta     (expedición extra)
                   └─ Zona 5 · El Valle de los Dinosaurios . despiertan los gigantes    (zona secreta)
```

- Las zonas salen de los **rincones de hábitat del ambiente aprobado** (HE-A7b): la carpa de Toby en el claro,
  la laguna con nenúfares, la pradera de pasto alto, el árbol grande con el nido y la cueva prehistórica con
  huellas fósiles. No se agregan polo ni océano como zonas: no están en el ancla y encarecerían el arte. Los
  hábitats de frío y de mar (pingüino, oso polar, ballena) entran como **casas** de "Cada quien a su casa" y
  como animales de las listas de Sofía, sin necesitar una zona propia.
- **Orden pedagógico** [Propuesta]: de lo conocido a lo exótico. Granja y mascotas (z1), animales de agua
  (z2), sabana y altiplano (z3), selva alta y aves (z4) y prehistoria (z5).
- **Por qué los dinos en la zona secreta**: es el gusto más fuerte de Maxi (GDD §4). Que el último rincón sea
  un valle de dinosaurios escondido en la neblina, con rugidos que se oyen de lejos desde la zona 1, es su
  "secreto para Maxi" de todo el planeta. Igual los dinos aparecen antes en su ruta, de a poco (§4).
- Cada zona tiene **4 estaciones**, en este orden en la tarjeta de zona: ¿Quién habla?, Cada quien a su casa,
  Escondite animal y Carrera de Toby → **20 estaciones por hermano**. Se juegan en cualquier orden.

### 2.0 El mapa ilustrado: la selva vista desde el suelo

Mismo criterio que la maqueta aprobada de Arcoíris (PO, 17-Oct-2026: el mapa se ve **desde el suelo del
planeta**). Lo dibuja `scripts/planetas/animalia/paisaje_animalia.gd`. Cada zona es un **hito con carita**,
reconocible de lejos:

| Zona | Hito | Detalles |
|---|---|---|
| 1 · Campamento de Toby | La **carpa redonda de Toby** con su antenita y la estrellita dorada | Corralito con un portón que se abre; la nave de los hermanos estacionada al lado |
| 2 · Laguna de los Nenúfares | Un **nenúfar gigante** con una flor rosada que se abre y se cierra | Patitos en fila; piedras lisas |
| 3 · Pradera de las Jirafas | Una **acacia gigante** con una jirafa que asoma la cabeza por encima de la copa | Pasto alto que se mece; arbustos floridos |
| 4 · Árbol de los Nidos | Un **árbol enorme con nidos redondos** en escalera y lianas | Un tucán en la punta; hojas gigantes |
| 5 · Valle de los Dinosaurios | Un **volcán dormilón** que echa humito de nubecitas, con huellas gigantes en el barro | Cuello de un braquiosaurio que asoma entre los árboles; entrada de la cueva con fósiles (HE-A7b) |

Además: el **sendero de huellitas** de distintas formas que une las zonas (HE-A7b), un riachuelo con puente
de troncos, hongos redondos y flores grandes. **Sin mariposas** (el ambiente HE-A7b las trae como relleno,
pero el mapa lo ven Nicole y Sofía: se reemplazan por pájaros y hojas que caen; `motor-buscar.md` regla 8).

**Cómo se cuenta la historia en el mapa**:

- Zona **dormida**: animales acurrucados con burbujitas "zzz", colores a medio tono, todo quieto y en silencio.
- Zona **abierta**: los animales bostezan y se estiran de vez en cuando (invita a entrar).
- Zona **completada**: sus animales bailan en su hito y **un grupo nuevo se suma al desfile**, que camina en
  bucle por el sendero hacia el campamento. Con las 5 zonas, el desfile es largo y lo encabezan los dinos.
- Zona secreta **antes de revelarse**: una neblina tibia sobre el valle, las huellas gigantes que se pierden en
  ella y, al tocarla, un rugido lejano y simpático ("¿escucharon eso?", Cometa). Nunca candado.

### 2.1 Reglas de apertura (iguales a Arcoíris)

| Regla | Valor | Por qué |
|---|---|---|
| Zona 1 | Abierta al llegar al planeta | Primer contacto sin requisito |
| Abrir la zona siguiente | Completar **todas las estaciones jugables** de la zona actual [PO, 27-Sep-2026] | Nadie se salta pruebas; las estaciones sin nivel no cuentan, así nadie se traba |
| Estaciones ya jugadas | Disponibles siempre, en cualquier orden | Rejugar por récord y estrellitas |
| Pieza de la nave (ala derecha) | Al completar la zona 3 (12 estaciones) | La historia llega tras las zonas 1 a 3 completas |
| Batalla de Animalia | Su hito aparece tras la zona 3 del primer hermano que la complete (patrón de Arcoíris; diseño en HE-115) | — |
| Zonas 4-5 | Expedición extra: no bloquean el capítulo 3 | Más reto y recuerdos sin frenar la historia |
| Zona 5 (secreta) | Se revela al completar todas las estaciones de la zona 4 | Premio para quien exploró todo |
| Retos dorados | Opcionales, no cuentan para abrir nada | — |

### 2.2 Recompensas por zona

| Momento | Recompensa |
|---|---|
| Cada estación | Celebración del motor (coro, foto de grupo, desfile o confeti según el juego) + **100 destellos la primera vez** + (Nicole y Sofía) 1-3 estrellitas y récord personal |
| Zona completada | Los animales de la zona despiertan y se suman al desfile; Toby regala un **recuerdo de zona** para el rincón de regalos del hangar (`hangar-nave.md` §8.2); la silueta del ala derecha se pinta un tercio (zonas 1-3) |
| Zonas 2 y 4 completadas | Además, **1 foto personal** del álbum de recuerdos (`album-recuerdos.md` §5: zonas 2 y 4 de cada planeta), con la línea de entrega "¡otra foto de la billetera de papá!" |
| Zona 3 completada | Escena de historia «La huellita de Toby» + **ala derecha** (pieza 2 de HE-A6: panel curvo verde selva con una huellita pintada) + video-llamada de papá + **1 foto familiar** del álbum + hangar en modo `instalar`. Mientras el video esté postergado por presupuesto, la escena y la video-llamada son **ganchos saltables con tarjeta estática y voz** (decisión del PO, 05-Nov-2026) |
| Zona 5 completada | **El Gran Desfile** completo (§6.1) y la voz `planeta_completo` |
| Zona perfecta (Nicole y Sofía) | **Gema en el collar de explorador** de Toby (cosmético, se ve en el mapa cuando ese hermano juega) y marco dorado en la foto de la zona si la tiene. Ver §6.3 (decidido en §13.3) |

**Recuerdos de zona** (objetos del rincón de regalos del hangar; arte de `disenador-personajes`; al tocarlos,
Toby los nombra):

1. **Hueso-silbato de Toby** (suena "fiuu" con su ladrido) · 2. **Flor de nenúfar** que se abre ·
3. **Herradura dorada** · 4. **Pluma de tucán** de colores · 5. **Huevito de dino brillante** que se mece.

### 2.3 Rejugabilidad y duración estimada

- **Rejugar** baraja todo lo que los motores permiten: orden de pedidos y madrigueras (`topos`), giros y
  espejos de los tableros (`caminos`, 8 o 4 variantes por tablero), escondites sorteados de 2-3 posibles
  (`buscar`) y la secuencia de obstáculos con semilla nueva (`runner`). Cada nivel trae un **pool** mayor que
  lo que usa por partida.
- Rejugar nunca quita nada: da celebración, y a Nicole y Sofía la chance de mejorar récord y estrellitas.

| Hermano | Por zona (primera pasada) | Planeta (primera pasada) | Con rejugadas |
|---|---|---|---|
| Maxi | ~9-10 min (topos 2,5 · caminos 2 · escondite 3 · carrera 2) | **~45-50 min** | 1,5-2 h (rejuega mucho lo que le gusta) |
| Nicole | ~12-14 min (topos 3 · caminos 3-4 · escondite 3 · carrera 3, con algún reintento) | **~1-1,2 h** | 2-3 h |
| Sofía | ~15-18 min (topos 3 · caminos 4-5 · escondite 4-5 · carrera 3,5, con reintentos) | **~1,3-1,5 h** | 2,5-3 h con estrellitas y dorados |

Maxi queda por debajo de la meta de 1 h en la primera pasada. Se acepta [Propuesta]: alargarle las
estaciones con más rondas bajaría el ritmo a los 2 años, y en el playtest de Arcoíris rejuega por gusto.

### 2.4 Lo que esta ficha asume de las preguntas abiertas de las fichas de motor

**[HE-124] Todas quedan decididas** (el PO delegó, 05-Nov-2026): se confirma la opción asumida, salvo las
tres de "¿Nicole puede perder?", que la política de derrota del PO resuelve con **sí, en los 4 juegos** (y
también Maxi, con derrota suave). Las marcas [Prov] que quedan en el texto se leen como **decididas**.

| Ficha | Pregunta | Decisión |
|---|---|---|
| `motor-topos` §16.1 | "Sopa de burbujas" de Letralandia | Será otro nivel del motor `topos` (no afecta a Animalia) |
| `motor-topos` §16.2 | ¿Nicole puede perder en ¿Quién habla? | **Sí** [HE-124], meta al percentil 25 (~75 % gana al primer intento); Sofía p40, Maxi p10 |
| `motor-topos` §16.3 | Letra inicial para Nicole en z5 | **Sí**, opcional, en el 25 % de los pedidos y nunca requisito |
| `motor-topos` §16.4 | Dinos de Maxi | **Granja en z1-z2; dinos desde z3**, creciendo hasta z5 |
| `motor-topos` §16.5 | Ranas y sapos | **No se usan** en ninguna ruta mientras no se decida |
| `motor-caminos` §16.1 | ¿Nicole puede perder en Cada quien a su casa? | **Sí** [HE-124], tormenta de 2,2 × par desde z1 (Sofía 1,6 ×, Maxi 3 ×) |
| `motor-caminos` §16.2 | Convivencia con Pinta v2 | Sin efecto aquí: Animalia no tiene Pinta |
| `motor-caminos` §16.3 | Red de seguridad de Maxi con `clasificar` | **Sí, solo si la maqueta o el playtest muestran que no logra trazar** |
| `motor-caminos` §16.4 | Casas neutras de Sofía | **Desde z2** (tabla del motor) |
| `motor-caminos` §16.5 | Tablero compartido en equipo | **Compartido**, con los caminos llegados fijos |
| `motor-buscar` §16.1 | ¿Nicole puede perder en Escondite animal? | **Sí** [HE-124], sol de 2,2 × par desde z1 sobre la escena entera (Sofía 1,6 ×, Maxi 3 ×) |
| `motor-buscar` §16.2 | Lupa compartida con Pinta | **Sí**, la misma pieza extraída |
| `motor-buscar` §16.3 | Arte de escenas | **Compuestas con piezas SVG reutilizables** |
| `motor-buscar` §16.4 | Sonidos "hechos con la boca" | **Sí, los graban los niños** cuando se pueda; CC0 mientras tanto |
| `motor-buscar` §16.5 | Foto de grupo al final | **Solo celebración** (el álbum queda reservado a las fotos de la familia) |
| `motor-runner` §16.1 | Meta + tramo del récord | **Sí**: se gana en la meta y se sigue por el récord |
| `motor-runner` §16.2 | Corredor de Nicole | **Uno por zona**: pony, pony, jirafa, gatito y pony estelar (§4.4) |
| `motor-runner` §16.3 | Salto variable de Sofía | **Activado en z4-z5** [HE-124]; se apaga en datos si la maqueta muestra saltos largos sin querer |
| `motor-runner` §16.4 | Banderita a la mitad para Nicole | **Sí**, y también para Maxi [HE-124] |
| `motor-runner` §16.5 | Carrera de Toby en el GDD §4 | **Hecho** [HE-124]: nota en el GDD §4 |
| (nueva, HE-124) | ¿Nicole puede perder en la Carrera? | **Sí**: 2 corazones (sin burbujas); Sofía 1 corazón + burbuja rara; Maxi 3 corazones |

---

## 3. Contenido por hermano (gustos reales)

Fuente: `docs/perfil-jugadores.md`. Regla: cada estación de cada hermano tiene **al menos un animal de sus
favoritos**. Ningún hermano juega "el mismo nivel con más animales": cada ruta tiene su propio elenco.

| Hermano | Gustos que se usan | Elenco que recorre todo el planeta | Sorpresas propias |
|---|---|---|---|
| **Maxi** (Semilla) | Dinosaurios (T-rex, spinosaurio, carnotauro), animales, autos, **bomberos** | Granja (vaca, perro, gato, pato, caballo, gallina) → laguna → pradera → **dinos** desde z3 (triceratops y braquiosaurio primero; T-rex, spinosaurio y carnotauro en z4-z5) | **Perrito bombero** (dálmata con casco y sirena "¡uiu-uiu!") en z2-z3; **Dinito**, un huevo escondido en cada zona que nace en el valle (§7); en la carrera corre él mismo como dino |
| **Nicole** (Brote) | Caballos, **ponys**, **gatitos**, **jirafas**, rosa; aprende a leer; **nada de bichos** | Gatito y pony en todas las zonas; jirafas protagonistas en z3; caballo como amigo fijo | **Jirafita** que busca a su mamá (z3), el **loro que dice su nombre** (z4), el **pony estelar** de crin de estrellas (z5); palabras cortas en mayúsculas en Escondite animal |
| **Sofía** (Estrella) | **Ponys**, **gerbos**, **perritos** (Toby es su favorito), **gatitos cachorros**, datos curiosos, reto real, **nada de bichos** | Cachorros en z1 (perrito, gatito, gerbo, pony, cuy), y desde z2 **animales de Chile** (pingüino de Humboldt, huillín, cisne de cuello negro, huemul, pudú, cóndor, tricahue, carpintero negro, monito del monte, chucao) y del mundo | El **hermanito de Toby** escondido (z1), el pingüino que rebuzna como burro (z2), el Coleccionauta disfrazado (z5), el **milodón** de la Patagonia (z5), la carrera de noche |

**Reglas de contenido** [Propuesta, a validar por el PO y UX]:

- **Sin bichos** en ninguna ruta (tampoco la de Maxi, porque el mapa y el modo equipo son compartidos): ni
  insectos, ni arañas, ni mariposas, ni ranas o sapos mientras el PO no decida.
- **Sin depredadores que asusten**: no hay leones, tigres, lobos, hienas, cocodrilos ni tiburones. Los dinos
  carnívoros de Maxi (T-rex, carnotauro, spinosaurio) sí, porque son su gusto explícito: siempre redondos,
  sonrientes y torpes. La **hiena** y el **lobo** salen también de `motor-topos.md` §8.2 [HE-124, decidido].
- **Datos curiosos verdaderos**: cada dato de Sofía lo revisa `guionista` contra una fuente antes de grabar.
  Los de esta ficha son de conocimiento general (pingüino de Humboldt que rebuzna, huemul en el escudo de
  Chile, pudú entre los ciervos más chicos del mundo, flamenco rosado por lo que come, milodón en la cueva
  de la Patagonia).
- **Nada de IP**: Toby, el pony estelar y Dinito son personajes propios.

---

## 4. Variantes por juego, zona y hermano

Lectura: cada juego tiene una **tabla de temas** (qué se juega en cada zona, por hermano) y una **tabla de
parámetros por perfil** con los campos del esquema JSON del motor. Lo que no se nombra toma el valor por
defecto de la ficha de motor. Todos los números son **valores de partida para la maqueta (HE-110)**: los
umbrales de victoria y de estrellitas se fijan con sus jugadores simulados (**[HE-124]** p10 para la meta de
Maxi, **p25** para la de Nicole, **p40** para la de Sofía; p50 y p80 para las estrellitas), como se hizo en
Arcoíris (HE-40 §7.2). Relojes de derrota: Sofía 1,6 × par, Nicole 2,2 ×, Maxi 3 ×. Regalo tras 3 derrotas
(Sofía) o 2 (Nicole y Maxi); ayuda fuerte de Maxi tras 3 (GDD §6 regla 11).

### 4.1 ¿Quién habla? — motor `topos`

**Temas**

| Zona | Maxi · Semilla (el animal espera 6 s; derrota suave [HE-124]) | Nicole · Brote (meta p25, un pedido a la vez) | Sofía · Estrella (meta p40, estrellitas) |
|---|---|---|---|
| 1 · Campamento | **El corralito**: vaca, perro, gato, pato, caballo y gallo, todos con sonidos muy distintos. Primera victoria fácil | **Los amigos del campamento**: gatito, caballo, vaca, perro, pato y oveja | **Cachorros**: perrito, gatito cachorro, gerbo (chillido), pony, cabrita, pollito y cuy ("cui-cui") |
| 2 · Laguna | **Chapuzones**: pato, lobo marino, hipopótamo, elefante echándose agua, chancho en el barro y el **perrito bombero** (sirena "¡uiu!") | **La orilla**: pato, flamenco, hipopótamo, lobo marino, gatito y caballo bebiendo | **Laguna y costa de Chile**: lobo marino, pingüino de Humboldt (rebuzna), pato, ganso, flamenco, huillín y ballena; primeros pares parecidos (pato/ganso) |
| 3 · Pradera | **¡Llega un dino!** caballo, vaca, oveja, elefante, burro y el **triceratops** ("muuu" grave), que asoma una vez por ronda como sorpresa | **Las jirafas**: jirafa (su zumbido suave real), cebra, elefante, caballo, gatito y burro; 6 madrigueras | **Pradera y altiplano**: caballo, burro, pony, cebra, jirafa, alpaca, guanaco, huemul, pudú, ñandú, oveja y cabra. Empieza el **modo continuo** y el **pedido escrito** |
| 4 · Árbol | **Dinos del bosque alto**: T-rex (rugido grave), spinosaurio ("glu-glu" con chapuzón), carnotauro (bufido), triceratops, braquiosaurio (**estornudo gigante "¡aaa-chú!"**) y el perro; 4 madrigueras, 3 asoman | **Arriba en los nidos**: mono, tucán, **loro (dice "¡hola, Nicole!")**, búho, gatito, caballo y pony; primer par parecido: **pony/caballo** (relincho agudo y grave) | **Aves y selva**: búho, lechuza, tucán, tricahue, choroy, carpintero negro (tamborileo), mono aullador, perezoso y chucao; **pedido doble** |
| 5 · Valle | **Todos los dinos**: T-rex, spinosaurio, carnotauro, triceratops, braquiosaurio y **Dinito** ("¡pío-grrr!" chiquitito) | **El valle mágico**: jirafa, pony, caballo, gatito, vaca, oveja, mono y el **pony estelar** (campanitas); **letra inicial** opcional | **El gran coro**: 14 animales de todo el planeta y el **Coleccionauta disfrazado** (el "no lo toques"); el desafío final |

Pares parecidos de Sofía (`similares`): pato/ganso (z2+), burro/caballo, oveja/cabra y **alpaca/jirafa** (las
dos zumban) desde z3, tricahue/choroy y búho/lechuza en z4-z5. Se escucha cada par en la tablet real antes de
aprobarlo (R5 de `motor-topos.md`).

**Parámetros — Maxi (Semilla)**

| Campo | z1 | z2 | z3 | z4 | z5 |
|---|---|---|---|---|---|
| `madrigueras` | 3 | 3 | 3 | 4 | 4 |
| `asomados` | 2 | 2 | 2 | 3 | 3 |
| `rondas` × `duracion_s` [HE-124] | 1 × 45 | 1 × 45 | 1 × 50 | 1 × 55 | 1 × 60 |
| `meta` [HE-124] (≈ p10) | 5 | 5 | 6 | 6 | 7 |
| `t_arriba_s` [HE-124] (antes null) | 6,0 | 6,0 | 5,5 | 5,5 | 5,0 |
| `pedidos` | null (solo la ayuda fuerte usa 6) | null | null | null | null |
| `repetir_sonido` / `ondas_visibles` | cada_3s / completas | igual | igual | igual | igual |
| Toby dorado | 1 por ronda (fiesta) | 1 | 1 | 1 | 1 |
| `ayuda_idle_s` [HE-124] | [3, 5] | [3, 5] | [3, 5] | [3, 5] | [3, 5] |
| `regalo_tras_derrotas` / ayuda fuerte [HE-124] | 2 → meta × 0,7 / 3 → el animal espera (`t_arriba_s: null`, 6 pedidos sin reloj) | igual | igual | igual | igual |

Duración: ~1,5-2 min (antes 2-3). Con 2 asomados, el que no sonó **también celebra** (GDD §4) y tocarlo no es
fallo; solo el pedido avanza, y solo el sol sin la meta hace perder.

**Parámetros — Nicole (Brote)**

| Campo | z1 | z2 | z3 | z4 | z5 |
|---|---|---|---|---|---|
| `madrigueras` | 4 | 4 | 6 | 6 | 6 |
| `asomados` | 3 | 3 | 4 | 4 | 4 |
| `t_arriba_s` | 2,6 | 2,4 | 2,2 | 2,0 | 1,8 |
| `pausa_entre_pedidos` | 0,7 | 0,7 | 0,65 | 0,6 | 0,6 |
| `rondas` × `duracion_s` [HE-124, decidido] | 2 × 60 | 2 × 60 | 2 × 60 | 2 × 60 | 2 × 60 |
| `meta` (aciertos **por ronda**) [HE-124] (≈ p25; antes 12-16) | 14 | 15 | 16 | 17 | 18 |
| `repetir_sonido` | una_vez | una_vez | no | no | no |
| `ondas_visibles` | completas | completas | completas | completas | completas |
| `similares` / `p_similar` | — | — | — | pony/caballo · 0,15 | pony/caballo · 0,2 |
| `pedido_escrito` [Prov] | — | — | — | — | letra · 0,25 (P pony, G gatito, J jirafa, C caballo, V vaca, O oveja, M mono) |
| Toby dorado (`cada_s`) | 15 | 15 | 15 | 15 | 15 |
| `regalo_tras_derrotas` | 2 → meta × 0,8 | igual | igual | igual | igual |
| `descanso_tras_derrotas` [HE-124] | 3 | 3 | 3 | 3 | 3 |

Derrota [HE-124, decidida]: "¡Nos escondimos todos!" (`motor-topos.md` §10.2). Con 2 rondas, si pierde la
segunda reintenta **solo la segunda**: la primera queda ganada.

**Parámetros — Sofía (Estrella)**

| Campo | z1 | z2 | z3 | z4 | z5 |
|---|---|---|---|---|---|
| `madrigueras` | 6 | 6 | 9 | 9 | 9 |
| `modo` | tandas | tandas | continuo | continuo | continuo |
| `asomados` (tandas) | 4 | 5 | — | — | — |
| `asomados_min` / `max` (continuo) | — | — | 2 / 4 | 3 / 5 | 3 / 6 |
| `t_arriba_s` | 1,6 | 1,45 | 1,3 | 1,15 | 1,0 |
| `intervalo_pedido_s` | — | — | 1,4 | 1,25 | 1,1 |
| `pausa_entre_pedidos` | 0,5 | 0,5 | — | — | — |
| `rondas` × `duracion_s` [HE-124, decidido] | 2 × 60 | 2 × 60 | 2 × 60 | 2 × 60 | 2 × 60 |
| `meta` (por ronda) [HE-124] (≈ p40; antes 18-26) | 20 | 22 | 24 | 26 | 28 |
| `regalo_tras_derrotas` [HE-124] | 3 → meta × 0,85 | igual | igual | igual | igual |
| `descanso_tras_derrotas` [HE-124] | 4 | 4 | 4 | 4 | 4 |
| `ondas_visibles` | completas | completas | mínimas | mínimas | mínimas |
| `p_similar` | 0 | 0,2 | 0,25 | 0,3 | 0,3 |
| `pedido_escrito` (palabra, ≤ 8 letras) | — | — | 0,25 | 0,25 | 0,25 |
| `pedido_doble` | — | — | — | 0,2 | 0,2 |
| Toby dorado (`cada_s`) | 12 | 12 | 12 | 12 | 12 |
| `impostor` | — | — | — | — | cada 15 s |
| Pista con costo (antena) | sí | sí | sí | sí | sí |

Palabras escritas permitidas (≤ 8 letras, `motor-topos.md` §8.3): PERRITO, GATITO, PONY, GERBO, PATO, GANSO,
BALLENA, BURRO, CABALLO, CEBRA, JIRAFA, ALPACA, PUDÚ, ÑANDÚ, OVEJA, CABRA, BÚHO, TUCÁN, MONO, CHUCAO. Los
nombres largos (PINGÜINO cabe justo; CARPINTERO y TRICAHUE no) solo van por sonido.

### 4.2 Cada quien a su casa — motor `caminos`

**Temas** (animal → su casa)

| Zona | Maxi · Semilla (el animal viaja bajo el dedo) | Nicole · Brote (casas de su color) | Sofía · Estrella (llenar; hábitats desde z2) |
|---|---|---|---|
| 1 · Campamento | perrito → casita del perro, vaca → granero, pato → laguna, gato → canasto, gallina → gallinero | pony → establo, gatito → canasto, perrito → casita, pato → laguna, caballo → pradera | **Cachorros a su cama** (casas con color): perrito → cucha, gatito → cojín, gerbo → castillito de cartón, pony → establo, cuy → casita de heno, conejo → madriguera, pollito → gallinero |
| 2 · Laguna | **Día de bomberos**: el perrito bombero → cuartel (siempre en el primer tablero), pato → laguna, tortuga → arena, hipopótamo → charco de barro, perro → casita | pony → establo, gatito → canasto, patito → nenúfar, flamenco → laguna rosada, cisne → juncal | **Agua y frío**: lobo marino → roquerío, pingüino de Humboldt → cueva de la costa, flamenco → salar, cisne de cuello negro → humedal, huillín → río del bosque, oso polar → témpano, ballena → mar abierto |
| 3 · Pradera | **Los primeros dinos**: braquiosaurio → árboles altos (primer tablero), triceratops → pradera de flores, caballo → establo, vaca → granero, elefante → río | **Jirafas**: jirafa → acacia, **jirafita → su mamá**, cebra → pasto alto, caballo → pradera, pony → establo, elefante → charca. Empieza el **llenado** | **Cordillera, estepa y más**: huemul → cordillera nevada, pudú → bosque lluvioso, guanaco → estepa patagónica, alpaca → bofedal del altiplano, cóndor → cumbre, camello → desierto, jirafa → acacia, panda → bambú. Primer **puente** |
| 4 · Árbol | **Cada dino a su casa**: T-rex → volcán, spinosaurio → río, carnotauro → cueva, braquiosaurio → árboles altos, triceratops → pradera; 3 por tablero | mono → palmera, loro → nido, gatito → canasto colgante, búho → hueco del árbol, perezoso → liana, pony → establo; primera **roca** | **Árboles del mundo**: tucán → selva tropical, tricahue → barranco, monito del monte → nido de musgo, carpintero negro → tronco de roble, koala → eucalipto, mono → bananero, castor → represa, panda → bambú, oso polar → témpano |
| 5 · Valle | **La familia dino**: los 5 dinos y, en el último tablero, **el huevito → el nido de mamá T-rex** (el bebé camina hasta su mamá) | **El valle mágico**: el **pony estelar → nube de estrellas** (último tablero), jirafa, pony, caballo, gatito y perrito | **Desafío final**: milodón → cueva del milodón y perrito → carpa de Toby (fijos), pingüino, huemul, flamenco, koala, ballena, camello, pudú, castor |

- **Huellas** (campo `huella` del catálogo): pezuñas, patitas, huellas de dino, y **plumitas** para los que
  vuelan o **burbujitas** para los que nadan (cóndor, ballena, pingüino).
- **Casas neutras de Sofía sin ambigüedad**: en un mismo tablero nunca van juntas dos casas que un niño
  pueda confundir. Pares prohibidos: huemul/cóndor (cordillera y cumbre), tucán/mono (selva y bananero),
  lobo marino/pingüino solo si el arte del roquerío y de la cueva se distingue al primer vistazo (lo revisa
  `disenador-personajes`). La primera vez de cada hábitat, Toby lo presenta con una frase y un dato.

**Parámetros por perfil**

| Campo | Maxi z1 · z2 · z3 · z4 · z5 | Nicole z1 · z2 · z3 · z4 · z5 | Sofía z1 · z2 · z3 · z4 · z5 |
|---|---|---|---|
| `cuadricula` | 4×3 · 4×3 · 4×3 · 5×4 · 5×4 | 5×5 · 5×5 · 6×6 · 6×6 · 6×6 | 7×7 · 7×7 · 8×8 · 8×8 · 9×9 |
| `pares` por tablero | 2 · 2 · 2 · 3 · 3 | 3 · 4 · 4 · 5 · 5 | 6 · 7 · 7 · 8 · 9 |
| `tableros` | 5 · 5 · 5 · 5 · 5 | 4 · 4 · 4 · 4 · 4 | 4 · 4 · 4 · 3 · 3 |
| `llenar` | no | no · no · sí · sí · sí | sí |
| `casas` | color | color | color · hábitat · hábitat · hábitat · hábitat |
| `rocas` | 0 | 0 · 0 · 0 · 1 · 2 | 0 · 2 · 3 · 3 · 4 |
| `puentes` | 0 | 0 | 0 · 0 · 1 · 1 · 2 |
| Forma | recto · recto · 1 curva · 1 curva · 1-2 curvas | 1-2 curvas | serpenteante |
| `tiempo_par_s` por tablero [HE-124] | 15 · 15 · 18 · 22 · 25 (solo para la nube) | **35** · 45 · 60 · 70 · 80 (la nube desde z1; bono y relojito solo con récord previo) | 60 · 70 · 85 · 95 · 120 |
| `tormenta` [HE-124] | **factor 3,0** (nube blanca, §10.1 del motor) | **factor 2,2** desde z1 | **factor 1,6** (antes 2,0) |
| `regalo_tras_derrotas` (mismo tablero) [HE-124] | 2 (+ ayuda fuerte tras 3) | 2 | 3 |
| `animal_bajo_dedo` / `iman_casa` | sí / 1 | no / 0 | no / 0 |
| `ayuda_idle_s` | [6, 10] + válvula de Toby | 15 s (late la casa siguiente) | — (pista con costo) |
| `umbrales_estrellitas` | — | por puntaje | `trazos_de_mas: 1`, `intentos_casa: 0` |

- Duración: Maxi ~2 min; Nicole ~3-4 min; Sofía ~4-5 min.
- **Diseño de tableros**: se hacen a mano en la maqueta HE-110 con el validador de solución única. Para
  tableros **sin llenado** (Maxi y Nicole z1-z2) la "solución única" no aplica en sentido estricto (casi
  siempre hay rodeos válidos); esta ficha pide que el validador exija un **camino más corto único** por par,
  que es el que usan la guía y la mano fantasma (§12.2).

### 4.3 Escondite animal — motor `buscar`

**Temas** (lista de objetivos; entre paréntesis, extras del pool)

| Zona | Maxi · Semilla (sin lista; todos hacen ruido) | Nicole · Brote (uno a la vez, voz + silueta + palabra) | Sofía · Estrella (3 tarjetas con pista escrita) |
|---|---|---|---|
| 1 · Campamento | perrito, gatito, vaca, pato, pollito (caballo). Objetos: carpa de Toby, balde, regadera, carretilla, fardo, gallinero | GATITO, PONY, PERRITO, CABALLO, PATO (pollito) | **El hermanito de Toby** (siempre: "tiene las orejas como Toby, pero no lleva casco"), gatito cachorro, gerbo, pony, cuy, conejo, pollito, cabrita. Pistas descriptivas |
| 2 · Laguna | patitos, hipopótamo, tortuga, pez saltarín, lobo marino, perrito bombero en su botecito. Objetos: nenúfares, bote, **manguera de bomberos** (¡chorro!), juncos, piedras | PATITO, FLAMENCO, GATITO, PONY, CISNE (hipopótamo) | pingüino de Humboldt, lobo marino, cisne de cuello negro, flamenco, huillín, coipo, pato, garza, tortuga (+1). Señuelo: ganso. Empieza el **camuflaje** (huillín café sobre rocas cafés) |
| 3 · Pradera | elefante, cebra, jirafa, caballo, oveja y el **triceratops**. Objetos: acacia, arbustos, rocas, nubes y un **camión de bomberos de juguete** (sirena y chorrito) | JIRAFA, **JIRAFITA**, CEBRA, CABALLO, PONY, ELEFANTE (oveja). Primer escondite que se abre: el fardo de pasto | huemul, pudú, guanaco, alpaca, ñandú, cebra, jirafa, caballo, pony, vizcacha (+1). Señuelos: llama (vs. alpaca), caballo con pijama a rayas (vs. cebra). Pistas de dos rasgos. **Lupa** |
| 4 · Árbol | mono, tucán, perezoso, búho, loro y el **braquiosaurio**: el "tronco" de un árbol es su cuello; al tocarlo, el árbol se ríe y levanta la cabeza | MONO, LORO, BÚHO, GATITO, PEREZOSO, PONY, TUCÁN (koala). Señuelo: **el burrito** ("¡yo soy el burrito, no el pony!") | cóndor, búho, tucán, mono, perezoso, tricahue, carpintero negro, monito del monte, chucao, koala, ardilla (+1). Señuelos: lechuza, choroy y un **peluche de koala** ("¡soy de peluche!"). 2 escondites de 2 pasos |
| 5 · Valle | T-rex, spinosaurio (en el río), carnotauro (en la cueva), triceratops, braquiosaurio, mamá T-rex y el **huevito de Dinito**, que al tocarlo nace. Objetos: volcán (puf de confeti), géiser, huesos gigantes que suenan como xilófono | **PONY ESTELAR**, JIRAFA, PONY, CABALLO, GATITO, PERRITO, MONO. Señuelo: la cebra ("¡yo soy la cebra, no el caballo!"). 2 escondites: cueva de cristales y flor gigante | **12 con pistas indirectas** (abajo). Señuelos: llama, ganso, lechuza, peluche de koala. El **pony estelar** escondido como secreto fuera de la lista |

Pistas indirectas de Sofía en z5 (una sola respuesta posible en la escena; lo verifica el validador de
`motor-buscar.md` §11.2): "le encanta el frío" (pingüino), "duerme de día y es de Chile" (monito del monte),
"está en el escudo de Chile y tiene cuernos" (huemul), "la otra del escudo: vuela altísimo" (cóndor), "uno de
los ciervos más chiquitos del mundo" (pudú), "vivió hace miles de años en una cueva de la Patagonia" (milodón),
"el animal más grande que existe" (ballena), "es rosado por lo que come" (flamenco), "el que más se parece a
Toby" (hermanito de Toby), "su lana abriga en el altiplano" (alpaca), "guarda semillas en sus cachetes" (gerbo)
y "tiene la crin más larga del valle" (pony).

**Parámetros por perfil**

| Campo | Maxi z1 · z2 · z3 · z4 · z5 | Nicole z1 · z2 · z3 · z4 · z5 | Sofía z1 · z2 · z3 · z4 · z5 |
|---|---|---|---|
| `escena.tamano` | 1280×720 | 1920 · 1920 · 2560 · 2560 · 2560 (×720) | 2560 · 2560 · 3200 · 3200 (×720) · 3840×1080 |
| `objetivos` | 5 · 5 · 6 · 6 · 7 | 5 · 5 · 6 · 7 · 7 | 8 · 9 · 10 · 11 · 12 |
| Escenas por estación [Propuesta, §12.3] | 2 (la 2.ª: "¡se escondieron otra vez!", mismos animales, otros escondites) | 1 | 1 |
| `visible` | 80 % · 80 % · 75 % · 75 % · 70 % | 60 · 55 · 50 · 45 · 40 % | 40 · 35 · 30 · 25 · 20 % |
| Tamaño del animal | 200 · 190 · 180 · 170 · 160 px | 120 · 115 · 110 · 100 · 96 px | 90 · 84 · 76 · 70 · 64 px |
| Objetos interactivos | 6 · 7 · 8 · 9 · 10 | 12 · 12 · 14 · 15 · 16 | 14 · 15 · 18 · 20 · 24 |
| Escondites que se abren | 0 | 0 · 0 · 1 · 1 · 2 | 1 · 2 · 3 · 4 (2 de 2 pasos) · 4 (2 de 2 pasos) |
| `camuflaje` | no | no | no · sí · sí · sí · sí |
| `senuelos` | 0 | 0 · 0 · 0 · 1 · 1 | 0 · 1 · 2 · 3 · 4 |
| `modo_lista` / `mostrar_palabra` | libre / — | uno / sí | tarjetas (3) / — |
| `lupa` | no | no | no · no · sí · sí · sí |
| `tiempo_par_s` [HE-124] | 35 · 35 · 40 · 40 · 45 **por escena** (solo para el sol) | **80** · 100 · 130 · 150 · 160 (el sol desde z1; bono y récord solo con récord previo) | 150 · 170 · 200 · 230 · 270 |
| `sol` [HE-124] | **factor 3,0**; mínimo 60 s (solcito que bosteza) | **factor 2,2** desde z1; mínimo 60 s | **factor 1,6** (antes 2,0); mínimo 45 s |
| `regalo_tras_derrotas` [HE-124] | 2 (+ ayuda fuerte tras 3: todos asoman, sin sol) | 2 | 3 |
| `ayuda_idle_s` | [6, 10] | [12, 20] | — (radar de Toby con costo) |

Duración: Maxi ~3 min (dos escenas cortas); Nicole ~2,5-3 min; Sofía ~4-5 min.

### 4.4 Carrera de Toby — motor `runner`

**Temas**

| Zona | Maxi · Semilla (un dino; 3 corazones [HE-124]) | Nicole · Brote (2 corazones [HE-124]; banderita a la mitad) | Sofía · Estrella (corre Toby; 1 corazón) |
|---|---|---|---|
| 1 · Campamento | Corre el **T-rex**. Montoncitos de hojas y arbustos; huevitos; meta: la carpa de Toby revienta en confeti | Corre un **pony** rosado. Troncos, piedras redondas, cerquitas de flores; manzanitas y corazones; meta: el establo | **Toby**. Troncos y cajas de exploración; globos desde los 40 s; huesitos; meta: su carpa |
| 2 · Laguna | Corre el **spinosaurio**: cada charquito salpica ("¡splash!") | **Pony** por la orilla: charcos y nenúfares; meta: el muelle | Charcos y nenúfares; **peces que saltan del agua** (aéreo bajo) y gaviotas (aéreo alto) desde los 40 s |
| 3 · Pradera | Corre el **carnotauro**: arbustos floridos y fardos | Corre la **jirafa**: primeros aéreos altos (pajaritos), que pasan por arriba si no salta; meta: la acacia | Altos y bajos desde el inicio: pajaritos y cometas de papel; grupos de 2 |
| 4 · Árbol | **¡T-rex bombero!** con casco rojo: cada salto hace "¡uiu!"; conos blanditos y mangueras enrolladas; gotitas de agua; meta: el cuartel de bomberos, que tira un chorro arcoíris | Corre un **gatito**: raíces y hongos; pajaritos altos; meta: el árbol de los nidos | Raíces, hongos gigantes, loros (altos) y hojas que caen (bajos); grupos de 3; **salto variable** activado [HE-124] |
| 5 · Valle | **Los tres dinos en fila** (T-rex adelante, spinosaurio y carnotauro detrás, saltan en cadena con un toque); meta: el **volcán de confeti** | Corre el **pony estelar**, que deja una estela de estrellas; altos y bajos; meta: el arcoíris del valle | **La carrera de noche**: el atardecer llega antes (50 %) y se corre bajo estrellas fugaces; huesos de juguete y rocas de esponja; meta: el valle |

**Parámetros por perfil**

| Campo | Maxi z1 · z2 · z3 · z4 · z5 | Nicole z1 · z2 · z3 · z4 · z5 | Sofía z1 · z2 · z3 · z4 · z5 |
|---|---|---|---|
| `velocidad` (px/s) | 240 fija | 400 · 410 · 425 · 440 · 450 | 560 · 575 · 590 · 605 · 620 |
| `velocidad_max` | 240 | 620 · 640 · 660 · 680 · 700 | 1000 · 1025 · 1050 · 1075 · 1100 |
| `segundos_a_max` | — | 120 | 120 · 115 · 110 · 105 · 100 |
| `salto` (duración / altura) | 0,90 s / 240 px, imantado | 0,80 / 210, amable 12 px | 0,62 / 185 |
| `huecos.min_s` | 3,5 | 1,7 · 1,65 · 1,55 · 1,45 · 1,4 | 1,2 · 1,15 · 1,05 · 1,0 · 0,95 |
| `grupo_max` | 1 | 1 · 1 · 2 · 2 · 2 | 2 · 2 · 2 · 3 · 3 |
| `aereos` | no | no · no · altos · altos · altos y bajos | desde 40 s · desde 40 s · altos y bajos desde el inicio |
| `corazones` [HE-124] | 3 | 2 | 1 |
| `obstaculos_blandos` [HE-124] | no (sí solo con la ayuda fuerte tras 3 derrotas) | no | no |
| `burbuja` [HE-124] | — | — (antes inicial 1; cada 25 s) | sin inicial; cada 55 · 55 · 55 · 70 · 70 s (antes 40-55) |
| `meta_s` | 60 · 60 · 70 · 75 · 80 | 75 · 80 · 85 · 90 · 95 | 90 · 95 · 105 · 110 · 120 |
| `tramo_record_s` | — | 45 | 90 |
| `banderita_mitad` [HE-124] | sí | sí | no (sí tras 3 derrotas, con la burbuja de la suerte) |
| `regalo_tras_derrotas` [HE-124] | 2 → 4 corazones | 2 → burbuja de la suerte | 3 → burbuja de la suerte + banderita |
| `salto_variable` [HE-124] | no | no | no · no · no · sí · sí |
| `atardecer_en` | 0,7 | 0,7 | 0,7 · 0,7 · 0,7 · 0,7 · 0,5 |
| `ayuda_idle_s` [HE-124] | [5, 12] (antes [8, 15]) | — | — |

Validación del motor: todos los `huecos.min_s` superan `duracion_salto + 0,3 s` (Nicole 1,1 s; Sofía 0,92 s).
Ventana de salto de Sofía en z5 con grupo de 3 a 1100 px/s: (0,62 × 1100 − 0,7 × 330 − 0,6 × 95) / 1100 ≈
0,36 s, exigente pero posible; si el simulador da menos del 50 % de llegadas a la meta, se baja `grupo_max` a 2.

Derrota-gag "¡Al barro!" (`motor-runner.md` §10.3), con sabor de zona: en la laguna, el corredor cae a un
charco con patitos que se ríen; en la pradera, la jirafa queda con el cuello hecho un nudo de risa; en el
valle de noche, Toby cae sobre un montón de hojas que brillan.

### 4.5 Resumen de la escalera por hermano

- **Maxi (Semilla)**: sube en **variedad y sorpresa**, casi nunca en exigencia: de la granja a los dinos, de 2
  a 3 animales en pantalla y de tableros rectos a una curva. Equivocarse no existe (tocar al otro animal
  celebra, el camino no se corta, todos hacen ruido), pero **perder sí, muy de vez en cuando** [HE-124]: el
  animal se esconde a los 6 s, hay nube y sol de 3 × par y 3 corazones en la carrera. Metas al p10 (~90 % gana
  al primer intento), gags cortos y afinados, regalo tras 2 y **ayuda fuerte tras 3** (victoria asegurada).
- **Nicole (Brote)**: sube en **velocidad, cantidad y atención**, siempre **un objetivo a la vez**: aviso de
  2,6 s a 1,8 s, de 3 a 5 caminos con llenado desde z3, escenas más grandes y escondidas y aéreos que no hay
  que saltar desde z3. **Derrota-gag en los 4 juegos desde z1** [HE-124]: metas al p25, nube y sol de 2,2 ×
  par y 2 corazones; regalo tras 2. Lectura inicial: palabras bajo la silueta y letra inicial opcional en z5.
- **Sofía (Estrella)**: reto real con **una regla nueva por zona**. z1, la mecánica pura; z2, pares parecidos,
  hábitats sin color y camuflaje; z3, modo continuo, pedido escrito, puentes, lupa y aéreos dobles; z4, pedido
  doble, escondites de 2 pasos y salto variable; z5, impostor, 9×9, pistas indirectas y la noche. **Más
  exigente** [HE-124]: metas al p40, nube y sol de 1,6 × par, un choque sin burbuja termina la carrera. Siempre
  completable: pista con costo, regalo tras **3** derrotas, descanso ofrecido tras 4 y retos dorados opcionales.

---

## 5. Gags de derrota (resumen)

| Juego | Quién puede perder [HE-124] | Gag | Reintento |
|---|---|---|---|
| ¿Quién habla? | Los tres (Maxi: sol sin la meta p10) | "¡Nos escondimos todos!": todos salen a la vez desafinados; a Toby se le empaña el casco y estornuda. Maxi: versión afinada de 1,5 s | Toque en el cartel; solo la ronda perdida |
| Cada quien a su casa | Los tres (nube 1,6 / 2,2 / 3 × par) | "¡La tormenta de risa!": los animales sin casa abren paraguas de hoja y se sacuden como perritos. Maxi: nube blanca dormilona y lluvia de burbujas | Solo el tablero en curso; regalo de un camino tras 3 (Sofía) o 2 |
| Escondite animal | Los tres (sol 1,6 / 2,2 / 3 × par) | "¡Se puso el sol!": todos salen gritando "¡aquí estábamos!", uno se le sube a Toby a la cabeza. Maxi: le hacen cosquillas a Toby | Encontrados quedan; los demás cambian de escondite |
| Carrera de Toby | Los tres (1 / 2 / 3 corazones) | "¡Al barro!": rueda como pelota y se sacude como perrito sobre la pantalla. Maxi: se sienta en hojas y estornuda confeti | Un toque; Nicole y Maxi desde la banderita si la pasaron |

Para los tres: reintento de un toque, cero progreso perdido, destellos y estrellitas solo al ganar, nunca
sonidos de error ni pantallas rojas (GDD §6 regla 11). Maxi tiene además la **ayuda fuerte** tras 3 derrotas
seguidas en cada juego.

---

## 6. Estación final, retos dorados y maestría

### 6.1 El cierre del planeta: el Gran Desfile

Al completar la última estación de la zona 5 (la que sea, porque se juegan en cualquier orden), en el mapa:

1. Se despeja la neblina del valle y el volcán echa una nube de confeti.
2. **El Gran Desfile**: todos los animales despertados de las 5 zonas pasan por el sendero, encabezados por
   los dinos, y cada grupo hace su sonido en escalera afinada (el coro de `motor-topos.md` §7.5, a escala del
   mapa). Toby va al final con su pose orgullosa.
3. **Dinito** (el huevo que Maxi fue encontrando, §7) nace si todavía no nació y se queda viviendo junto a la
   carpa de Toby en el mapa, para los tres hermanos.
4. Voz `planeta_completo` (Toby y Cometa) y el gesto canon del hermano que juega.

Es igual para los tres: dura ~12 s y se puede saltar con un toque. La **Carrera de Toby de la zona 5** de cada
hermano es el "desafío final" temático (los tres dinos en fila, el pony estelar y la carrera de noche), pero no
tiene por qué ser la última estación que se juega.

### 6.2 Retos dorados de Sofía

Aparecen como botón dorado de 96 px en la tarjeta de la estación cuando Sofía tiene **3 estrellitas** en ella
(patrón de Arcoíris). Dan 0 destellos, no cuentan para abrir nada y su premio es cosmético.

| Estación | Reto dorado | Reglas | Premio |
|---|---|---|---|
| Cada quien a su casa · z5 | **El gran tablero de Toby** | 1 tablero de 9×9 con 8 pares, 3 puentes y 4 rocas, todo con casas de hábitat y llenado. Pocos pares en 9×9 obliga a caminos largos (lo más difícil de Flow Free). **Con tormenta de 1,6 × par** [HE-124: antes sin tormenta; "derrota en todo" para Sofía], `tiempo_par_s` 240 provisional; regalo tras 3; con guardado parcial | Huellita dorada en el arnés de Toby en el mapa |
| Carrera de Toby · z5 | **Sendero sin fin** (el dino de Chrome puro) | Sin meta: de 620 a 1150 px/s en 100 s, una sola burbuja inicial, grupos de 3, altos y bajos. Se "completa" al aguantar **150 s**: ahí aparece una **aurora austral** en el cielo de la noche ("en el sur de Chile a veces se ve"). Después sigue sin fin por el récord. Derrota-gag y regalo tras 3 como en la carrera normal [HE-124] | La aurora queda en el cielo del mapa cuando Sofía juega + banderita dorada en el sendero |

Alternativa descartada [HE-124, cierra la pregunta 5]: **Escondite de noche** en el valle, con linterna y solo
pistas indirectas. Pide arte nuevo de noche; van los dos dorados de arriba, que salen casi sin arte.

### 6.3 Maestría: la zona perfecta

- **Zona perfecta** = 3 estrellitas en las 4 estaciones de la zona. En Animalia **las 4 estaciones puntúan**
  (no hay Pinta, que en Arcoíris quedaba fuera).
- Premio: una **gema en el collar de explorador** de Toby (5 gemas = collar completo, que Toby luce en el mapa
  cuando juega ese hermano) y, en las zonas 2 y 4, el **marco dorado** en su foto del álbum.
- **Equidad Nicole/Sofía** [HE-124, decidido: sí]: en Animalia Nicole también gana 1-3 estrellitas por
  puntaje en los 4 juegos (lo dicen las 4 fichas de motor). La ficha del álbum habla solo de "estrellitas
  máximas de Sofía". Propongo que la zona perfecta valga **igual para Nicole y Sofía**, con el mismo collar y
  el mismo marco: si solo Sofía lo puede ganar con el mismo tipo de estrellitas, se crea una comparación que
  el perfil de las dos pide evitar. Maxi no tiene estrellitas; su premio equivalente es Dinito.

---

## 7. Momentos memorables

| Zona | Maxi | Nicole | Sofía |
|---|---|---|---|
| 1 · Campamento | Toby dorado asoma de una madriguera y le hace fiesta. En el Escondite hay un **huevito con manchas** escondido que se mece al tocarlo: el primero de los 5 huevos de Dinito | Toby le presenta a su gatito y a su pony; el pony la sigue por el sendero al completar la zona | El **hermanito de Toby** escondido en el campamento ("¡es igualito a Toby!") |
| 2 · Laguna | El **perrito bombero** con sirena "¡uiu-uiu!" y la manguera que echa un chorro en el Escondite | El flamenco rosado (su color) que se para en una pata cuando lo encuentra | El **pingüino que rebuzna como burro** (dato real del pingüino de Humboldt) |
| 3 · Pradera | **¡Aparece el primer dino!** El triceratops asoma entre la vaca y el caballo; el camión de bomberos de juguete | **La jirafita que busca a su mamá**: en Cada quien a su casa su camino lleva a la mamá jirafa, que la abraza con el cuello | La alpaca y la jirafa **zumban igual**: el par parecido más difícil; datos del huemul y el pudú |
| 4 · Árbol | **El árbol era un cuello**: el braquiosaurio se ríe y levanta la cabeza; el T-rex bombero de la carrera | **El loro dice "¡hola, Nicole!"** (grabación con el nombre de quien juega) | El **peluche de koala** que se delata solo; los dos escondites de 2 pasos |
| 5 · Valle | **Nace Dinito** del huevito; los tres dinos corren en fila hasta el volcán de confeti | **El pony estelar** de crin de estrellas, en el Escondite y en la Carrera | El **Coleccionauta disfrazado** en ¿Quién habla? ("¡me descubriste!"), el milodón y la carrera bajo estrellas fugaces |

**Los huevos de Dinito (el secreto de Maxi)** [Propuesta]: en el Escondite de cada zona hay un huevito con
manchas que no está en ninguna lista y no cuenta para nada. Al tocarlo se mece y "pía"; en el mapa, junto a la
carpa, se suma a un nidito (1 a 5 huevos). En el valle, el quinto nace como **Dinito**, un bebé dino que desde
entonces vive en el mapa. Lo puede encontrar cualquier hermano (en las escenas de Nicole y Sofía va más
escondido), pero está pensado para Maxi: "encuentra lo que nadie más ve" (GDD §1). Si Maxi no lo encontró,
nace igual en el Gran Desfile (§6.1): **nunca se pierde**.

---

## 8. Destellos y estrellitas

- **100 destellos fijos por estación la primera vez**, iguales para los tres (`destellos_por_estacion: 100`).
  Rejugar da 0. Planeta completo: **2.000 por hermano**, igual que Arcoíris.
- Retos dorados: 0 destellos (`destellos_reto_dorado: 0`).
- Modo equipo: 50 por hermano la primera vez que se gana cada nivel de equipo (`destellos_equipo_por_hermano:
  50`). Propuesta v1 de equipo: las 5 estaciones de **¿Quién habla?** (la más corta y fácil de turnar,
  `motor-topos.md` §12.2). Las demás se suman con la batalla (HE-115).
- Las aperturas, la pieza y la zona secreta cuentan **estaciones completadas**, nunca destellos.
- **Estrellitas**: Nicole y Sofía, 1-3 por puntaje con `umbrales_puntaje: {dos: p50, tres: p80}` del jugador
  simulado de cada maqueta. Excepción: Sofía en Cada quien a su casa, por reglas (`motor-caminos.md` §9.2).
  Sin huecos vacíos para Nicole. Maxi no tiene puntaje.

Valores **semilla** para arrancar las maquetas (solo z1; z2-z5 salen del simulador). Estimación: aciertos
esperados × 100 × multiplicador medio de racha (≈ 3,4 con 80 % de acierto y ≈ 3,7 con 85 %) + bonos.

| Juego · z1 | Nicole `dos` / `tres` | Sofía `dos` / `tres` |
|---|---|---|
| ¿Quién habla? (suma de las 2 rondas) | 14.000 / 18.000 | 23.000 / 27.000 |
| Cada quien a su casa | 5.500 / 6.800 | por reglas |
| Escondite animal | 1.500 / 1.900 | 2.600 / 3.300 |
| Carrera de Toby | 2.300 / 2.900 | 3.000 / 3.900 |

---

## 9. Borrador de `datos/planetas/animalia/mapa.json`

**No crear el archivo todavía**: la implementación espera HE-18 y la aprobación de esta ficha. Mismo formato que
`datos/planetas/arcoiris/mapa.json`. Campos nuevos, que solo lee `paisaje_animalia.gd`: `pieza_nave.id`,
`zonas[].recuerdo` y `zonas[].desfile`. Ver la nota sobre `bandas` en §12.4.

```json
{
  "planeta_id": "animalia",
  "nombre": "Planeta Animalia",
  "estado": "BORRADOR HE-D6 (05-Nov-2026). No crear hasta HE-18 y la aprobacion del PO (docs/fichas/planeta-animalia-zonas.md).",
  "fondo": "res://assets/anclas/planeta_animalia_referencia.png",
  "paisaje": "res://scripts/planetas/animalia/paisaje_animalia.gd",
  "nota_paisaje": "Mapa visto desde el suelo, como Arcoiris (PO 17-Oct-2026). Hitos: carpa, nenufar, acacia, arbol de nidos, volcan. Sin mariposas. Zonas dormidas con zzz; completadas suman su grupo al desfile del sendero.",
  "anfitrion": "res://assets/sprites/personajes/toby_base.png",
  "nota": "Regla del PO 27-Sep-2026: la zona siguiente (y la secreta) se abre al completar TODAS las estaciones jugables de la anterior; los retos dorados no cuentan.",
  "destellos_por_estacion": 100,
  "destellos_reto_dorado": 0,
  "destellos_equipo_por_hermano": 50,
  "nota_equipo": "Propuesta HE-D6: v1 de equipo en las 5 estaciones de Quien habla (motor-topos.md 12.2).",
  "batalla": {
    "id": "animalia_batalla_final",
    "datos": "res://datos/batallas/animalia_final.json",
    "escena": "res://escenas/nucleo/batalla.tscn",
    "aparece_tras_zona": 3,
    "condicion": "primer_hermano",
    "posicion": [640, 250],
    "nota": "PENDIENTE HE-115 (jefe propio y mecanica de referencia nueva). Datos y escena son provisionales."
  },
  "pieza_nave": {
    "id": "ala_derecha",
    "zonas": [1, 2, 3],
    "posicion": [1170, 64],
    "nota": "Silueta del ala derecha (verde selva con huellita, HE-A6) que se pinta un tercio por zona; la pieza llega al completar la zona 3."
  },
  "juegos": {
    "quien_habla": { "nombre": "¿Quién habla?", "icono": "quien_habla", "voz": "voces/animalia/mapa/juego_quien_habla.wav" },
    "casa": { "nombre": "Cada quien a su casa", "icono": "casa", "voz": "voces/animalia/mapa/juego_casa.wav" },
    "escondite": { "nombre": "Escondite animal", "icono": "escondite", "voz": "voces/animalia/mapa/juego_escondite.wav" },
    "carrera": { "nombre": "Carrera de Toby", "icono": "carrera", "voz": "voces/animalia/mapa/juego_carrera.wav" }
  },
  "voces": {
    "bienvenida": "voces/animalia/mapa/bienvenida.wav",
    "zona_dormida": ["voces/animalia/mapa/zona_dormida.wav", "voces/animalia/mapa/zona_dormida_02.wav"],
    "zona_abierta": "voces/animalia/mapa/zona_abierta.wav",
    "secreta_lejana": "voces/animalia/mapa/secreta_lejana.wav",
    "secreta_revelada": "voces/animalia/mapa/secreta_revelada.wav",
    "estacion_pronto": "voces/animalia/mapa/estacion_pronto.wav",
    "equipo_llegada": "voces/animalia/mapa/equipo_llegada.wav",
    "estacion_sin_equipo": "voces/animalia/mapa/equipo_estacion_pronto.wav",
    "cometa_vamos": "voces/animalia/mapa/cometa_vamos.wav",
    "todo_listo": "voces/animalia/mapa/todo_listo.wav",
    "dorado_disponible": "voces/animalia/mapa/dorado_disponible.wav",
    "dorado_entrar": "voces/animalia/mapa/dorado_entrar.wav",
    "estacion_repetida": [
      "voces/animalia/mapa/estacion_repetida_01.wav",
      "voces/animalia/mapa/estacion_repetida_02.wav",
      "voces/animalia/mapa/estacion_repetida_03.wav"
    ],
    "planeta_completo": "voces/animalia/mapa/planeta_completo.wav"
  },
  "zonas": [
    {
      "id": "zona1_campamento",
      "numero": 1,
      "nombre": "El Campamento de Toby",
      "bandas": ["naranja"],
      "posicion": [290, 560],
      "secreta": false,
      "recuerdo": "hueso_silbato",
      "desfile": ["vaca", "perro", "gato", "pato", "caballo", "pony"],
      "voz_llegada": "voces/animalia/mapa/zona_1_llegada.wav",
      "voz_completada": "voces/animalia/mapa/zona_1_completada.wav",
      "voz_regalo": "voces/animalia/mapa/zona_1_regalo.wav",
      "estaciones": [
        {
          "juego": "quien_habla",
          "escena": "res://escenas/minijuegos/topos/motor_topos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona1_campamento/topos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona1_campamento/topos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona1_campamento/topos_estrella.json"
          },
          "nivel_equipo": "res://datos/niveles/animalia/zona1_campamento/topos_equipo.json"
        },
        {
          "juego": "casa",
          "escena": "res://escenas/minijuegos/caminos/motor_caminos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona1_campamento/caminos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona1_campamento/caminos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona1_campamento/caminos_estrella.json"
          }
        },
        {
          "juego": "escondite",
          "escena": "res://escenas/minijuegos/buscar/motor_buscar.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona1_campamento/buscar_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona1_campamento/buscar_brote.json",
            "sofia": "res://datos/niveles/animalia/zona1_campamento/buscar_estrella.json"
          }
        },
        {
          "juego": "carrera",
          "escena": "res://escenas/minijuegos/runner/motor_runner.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona1_campamento/runner_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona1_campamento/runner_brote.json",
            "sofia": "res://datos/niveles/animalia/zona1_campamento/runner_estrella.json"
          }
        }
      ]
    },
    {
      "id": "zona2_laguna",
      "numero": 2,
      "nombre": "La Laguna de los Nenúfares",
      "bandas": ["azul"],
      "posicion": [520, 400],
      "secreta": false,
      "recuerdo": "flor_nenufar",
      "desfile": ["pato", "flamenco", "hipopotamo", "lobo_marino", "pinguino", "perrito_bombero"],
      "voz_llegada": "voces/animalia/mapa/zona_2_llegada.wav",
      "voz_completada": "voces/animalia/mapa/zona_2_completada.wav",
      "voz_abierta": "voces/animalia/mapa/zona_2_abierta.wav",
      "voz_regalo": "voces/animalia/mapa/zona_2_regalo.wav",
      "estaciones": [
        {
          "juego": "quien_habla",
          "escena": "res://escenas/minijuegos/topos/motor_topos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona2_laguna/topos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona2_laguna/topos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona2_laguna/topos_estrella.json"
          },
          "nivel_equipo": "res://datos/niveles/animalia/zona2_laguna/topos_equipo.json"
        },
        {
          "juego": "casa",
          "escena": "res://escenas/minijuegos/caminos/motor_caminos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona2_laguna/caminos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona2_laguna/caminos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona2_laguna/caminos_estrella.json"
          }
        },
        {
          "juego": "escondite",
          "escena": "res://escenas/minijuegos/buscar/motor_buscar.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona2_laguna/buscar_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona2_laguna/buscar_brote.json",
            "sofia": "res://datos/niveles/animalia/zona2_laguna/buscar_estrella.json"
          }
        },
        {
          "juego": "carrera",
          "escena": "res://escenas/minijuegos/runner/motor_runner.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona2_laguna/runner_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona2_laguna/runner_brote.json",
            "sofia": "res://datos/niveles/animalia/zona2_laguna/runner_estrella.json"
          }
        }
      ]
    },
    {
      "id": "zona3_pradera",
      "numero": 3,
      "nombre": "La Pradera de las Jirafas",
      "bandas": ["amarillo"],
      "posicion": [760, 540],
      "secreta": false,
      "recuerdo": "herradura_dorada",
      "desfile": ["jirafa", "jirafita", "cebra", "elefante", "alpaca", "huemul", "triceratops"],
      "voz_llegada": "voces/animalia/mapa/zona_3_llegada.wav",
      "voz_completada": "voces/animalia/mapa/zona_3_completada.wav",
      "voz_abierta": "voces/animalia/mapa/zona_3_abierta.wav",
      "voz_regalo": "voces/animalia/mapa/zona_3_regalo.wav",
      "estaciones": [
        {
          "juego": "quien_habla",
          "escena": "res://escenas/minijuegos/topos/motor_topos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona3_pradera/topos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona3_pradera/topos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona3_pradera/topos_estrella.json"
          },
          "nivel_equipo": "res://datos/niveles/animalia/zona3_pradera/topos_equipo.json"
        },
        {
          "juego": "casa",
          "escena": "res://escenas/minijuegos/caminos/motor_caminos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona3_pradera/caminos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona3_pradera/caminos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona3_pradera/caminos_estrella.json"
          }
        },
        {
          "juego": "escondite",
          "escena": "res://escenas/minijuegos/buscar/motor_buscar.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona3_pradera/buscar_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona3_pradera/buscar_brote.json",
            "sofia": "res://datos/niveles/animalia/zona3_pradera/buscar_estrella.json"
          }
        },
        {
          "juego": "carrera",
          "escena": "res://escenas/minijuegos/runner/motor_runner.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona3_pradera/runner_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona3_pradera/runner_brote.json",
            "sofia": "res://datos/niveles/animalia/zona3_pradera/runner_estrella.json"
          }
        }
      ]
    },
    {
      "id": "zona4_nidos",
      "numero": 4,
      "nombre": "El Árbol de los Nidos",
      "bandas": ["verde"],
      "posicion": [960, 330],
      "secreta": false,
      "recuerdo": "pluma_tucan",
      "desfile": ["mono", "tucan", "loro", "buho", "perezoso", "condor", "braquiosaurio"],
      "voz_llegada": "voces/animalia/mapa/zona_4_llegada.wav",
      "voz_completada": "voces/animalia/mapa/zona_4_completada.wav",
      "voz_abierta": "voces/animalia/mapa/zona_4_abierta.wav",
      "voz_regalo": "voces/animalia/mapa/zona_4_regalo.wav",
      "estaciones": [
        {
          "juego": "quien_habla",
          "escena": "res://escenas/minijuegos/topos/motor_topos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona4_nidos/topos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona4_nidos/topos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona4_nidos/topos_estrella.json"
          },
          "nivel_equipo": "res://datos/niveles/animalia/zona4_nidos/topos_equipo.json"
        },
        {
          "juego": "casa",
          "escena": "res://escenas/minijuegos/caminos/motor_caminos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona4_nidos/caminos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona4_nidos/caminos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona4_nidos/caminos_estrella.json"
          }
        },
        {
          "juego": "escondite",
          "escena": "res://escenas/minijuegos/buscar/motor_buscar.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona4_nidos/buscar_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona4_nidos/buscar_brote.json",
            "sofia": "res://datos/niveles/animalia/zona4_nidos/buscar_estrella.json"
          }
        },
        {
          "juego": "carrera",
          "escena": "res://escenas/minijuegos/runner/motor_runner.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona4_nidos/runner_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona4_nidos/runner_brote.json",
            "sofia": "res://datos/niveles/animalia/zona4_nidos/runner_estrella.json"
          }
        }
      ]
    },
    {
      "id": "zona5_valle",
      "numero": 5,
      "nombre": "El Valle de los Dinosaurios",
      "bandas": ["violeta", "brillo"],
      "posicion": [1150, 200],
      "secreta": true,
      "recuerdo": "huevito_dino",
      "desfile": ["trex", "spinosaurio", "carnotauro", "dinito", "pony_estelar"],
      "voz_llegada": "voces/animalia/mapa/zona_5_llegada.wav",
      "voz_completada": "voces/animalia/mapa/zona_5_completada.wav",
      "voz_regalo": "voces/animalia/mapa/zona_5_regalo.wav",
      "estaciones": [
        {
          "juego": "quien_habla",
          "escena": "res://escenas/minijuegos/topos/motor_topos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona5_valle/topos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona5_valle/topos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona5_valle/topos_estrella.json"
          },
          "nivel_equipo": "res://datos/niveles/animalia/zona5_valle/topos_equipo.json"
        },
        {
          "juego": "casa",
          "escena": "res://escenas/minijuegos/caminos/motor_caminos.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona5_valle/caminos_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona5_valle/caminos_brote.json",
            "sofia": "res://datos/niveles/animalia/zona5_valle/caminos_estrella.json"
          },
          "niveles_dorados": {
            "sofia": "res://datos/niveles/animalia/zona5_valle/caminos_estrella_dorado.json"
          }
        },
        {
          "juego": "escondite",
          "escena": "res://escenas/minijuegos/buscar/motor_buscar.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona5_valle/buscar_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona5_valle/buscar_brote.json",
            "sofia": "res://datos/niveles/animalia/zona5_valle/buscar_estrella.json"
          }
        },
        {
          "juego": "carrera",
          "escena": "res://escenas/minijuegos/runner/motor_runner.tscn",
          "niveles": {
            "maxi": "res://datos/niveles/animalia/zona5_valle/runner_semilla.json",
            "nicole": "res://datos/niveles/animalia/zona5_valle/runner_brote.json",
            "sofia": "res://datos/niveles/animalia/zona5_valle/runner_estrella.json"
          },
          "niveles_dorados": {
            "sofia": "res://datos/niveles/animalia/zona5_valle/runner_estrella_dorado.json"
          }
        }
      ]
    }
  ]
}
```

Convención de `id_nivel` (fichas de motor): `animalia_z<n>_<motor>_<perfil>`, por ejemplo
`animalia_z3_caminos_brote`; los dorados terminan en `_dorado`.

---

## 10. Voces (encargo para `guionista`, HE-112)

Toby es la voz de los juegos y de las zonas; Cometa, la del mapa y las aperturas (patrón de Arcoíris §5).
Textos e instrucciones van sin voces durante la acción (GDD §5, ritmo rápido).

| Grupo | Claves | Cantidad aprox. |
|---|---|---|
| Mapa | `bienvenida`, `zona_<n>_llegada` (Toby presenta el rincón dormido), `zona_<n>_abierta` (Cometa: "¡se despertó un rincón!"), `zona_<n>_completada` (Toby: los animales despiertan), `zona_<n>_regalo` (el recuerdo), `zona_dormida` ×2 ("shhh, están durmiendo la siesta", nunca "bloqueada"), `secreta_lejana` (rugido + "¿escucharon eso?"), `secreta_revelada`, `estacion_repetida` ×3, `planeta_completo`, `dorado_disponible`, `dorado_entrar`, equipo ×2, `cometa_vamos`, `todo_listo`, `juego_<4>` | ~35 |
| Gran Desfile y Dinito | `desfile_empieza`, `dinito_huevo_<1-5>` (pío), `dinito_nace` | ~8 |
| Instrucciones | `intro` + `instruccion` por estación × perfil (20 × 3) | 120 |
| Por juego | Las `lineas_voz` del esquema de cada motor (meta llena, victoria, derrota-gag, regalo, descansar, pista usada, récord, primer récord, impostor, Toby dorado, faltan flores, casa ajena, ya encontrado, sigue por el récord, aéreo presentado…) por perfil | ~90 |
| Nombres de animales | `voces/animalia/nombres/<id>.wav` (~70; se reutilizan en los 4 motores y en el desfile) | ~70 |
| Nicole | Letras iniciales de z5 (7 sonidos: "vvv", "ppp"…), palabras de las tarjetas (las mismas de "nombres"), el loro con el nombre de cada hermano ("¡hola, Maxi/Nicole/Sofía!") | ~10 |
| Sofía | Pistas escritas del Escondite (texto + voz, ~50), datos curiosos por animal chileno o raro (~25), presentación de cada hábitat neutro (~30) | ~105 |
| Señuelos | "¡yo soy el burrito, no el pony!" y similares (~10) | ~10 |

**SFX y sonidos de animales**: reales, CC0, cortos (≤ 0,9 s para `topos`) y con ataque claro. Los dinos llevan
sonidos cómicos propios y **muy distintos entre sí** (rugido grave, glu-glu, bufido, muuu grave, estornudo,
pío-grrr). Los pares parecidos de Sofía se escuchan en la tablet real con el PO antes de aprobarlos. Los
sonidos de los objetos del Escondite, idealmente grabados por los niños [Prov].

## 11. Arte (encargo para `disenador-personajes`, HE-114)

- **Catálogo de animales** (~70, compartido por los 4 motores): cada uno con pose quieto, hablar/encontrado,
  saltito y caminar; huella, plumita o burbujita para `caminos`. Los 3 corredores de Maxi (T-rex, spinosaurio,
  carnotauro, más el casco de bombero), los 5 de Nicole (pony, jirafa, gatito, pony estelar; la jirafa con
  cuello que se agacha, §12.5) y Toby corriendo.
- **Personajes propios nuevos**: perrito bombero (dálmata), hermanito de Toby (beagle sin casco), pony estelar,
  Dinito (huevo con manchas y bebé), Coleccionauta disfrazado (orejas de cartón y bigotes pintados).
- **Escenas**: fondos de las 5 zonas y madrigueras, tableros y senderos por zona; escenas del Escondite
  **compuestas con piezas** SVG (árboles, arbustos, rocas, nenúfares, fardo, carpa).
- **Mapa**: los 5 hitos, el sendero de huellitas, los estados dormido/despierto y el desfile.
- **Recuerdos de zona** (5) y la gema del collar.
- **Presupuesto** [Propuesta]: si el catálogo de ~70 animales no cabe en el capítulo 2, se entrega primero el
  **núcleo de las zonas 1-3** (~40 animales) y las zonas 4-5 llegan como "expedición extra", igual que se
  propuso para Arcoíris (P8).

---

## 12. Hallazgos para otros roles (no bloquean esta ficha)

1. **`topos`: la estación de 60 s es corta** (`disenador-mecanicas`). Una ronda de 60 s más intro y fiesta
   dura ~1,5 min, por debajo de los 2-5 min de una sesión y de la meta de horas del planeta. Propongo un campo
   `rondas` (2 rondas de 60 s con mini-fiesta entre ellas; puntaje sumado; meta por ronda; si se pierde la 2.ª,
   se reintenta solo esa). Es el mismo patrón de rondas de Arcoíris. Si el PO prefiere estaciones cortas para
   rejugar por récord (como Chrome), basta con `rondas: 1`. **[HE-124] Decidido**: `rondas: 2` en Brote y
   Estrella, `rondas: 1` en Semilla; la clave ya está en el esquema de `motor-topos.md` §11.
2. **`caminos`: solución única sin llenado** (`disenador-mecanicas` y quien programe el validador). Sin
   llenado casi siempre hay rodeos válidos. Para Maxi y Nicole z1-z2 el validador debería exigir un **camino
   más corto único** por par, que es el que dibujan la guía y la mano fantasma.
3. **`buscar`: dos escenas por estación en Semilla** (`disenador-mecanicas`). Para Maxi propongo `escenas: 2`
   con la misma ilustración y escondites re-sorteados ("¡se escondieron otra vez!"). No pide arte extra.
4. **`bandas` en el núcleo** (`dev-godot`, para HE-120). `mapa_planeta.gd` usa `bandas` para el color de la
   zona y para pintar un arcoíris en el cielo (`COLOR_BANDA`, `_avance_bandas`). En Animalia la idea es
   "despertar", no un arcoíris. El borrador mantiene `bandas` para no tocar el núcleo, pero el arcoíris del
   cielo debería pasar al `paisaje` de cada planeta (regla de oro 4: el núcleo no conoce planetas concretos).
5. **`runner`: la jirafa de Nicole y los aéreos altos** (`disenador-mecanicas` y `disenador-personajes`). El
   aéreo alto "pasa por arriba si no saltas", pero la jirafa es alta. Propongo que su caja de choque sea solo
   el cuerpo y que **agache el cuello** cuando pasa un aéreo alto (un gag más). Si no convence, la jirafa corre
   en z1-z2 (sin aéreos) y el pony en z3.
6. **Álbum y estrellitas de Nicole** (`disenador-mecanicas`, `album-recuerdos.md`): el marco dorado está escrito
   solo para Sofía; con estrellitas para Nicole en Animalia conviene extenderlo a las dos (§6.3).
7. **GDD §4** (PO): lista 3 juegos para Animalia; falta "Carrera de Toby" y actualizar las descripciones de
   "Cada quien a su casa" (hoy dice "arrastrar") y "¿Quién habla?" a las mecánicas nuevas. **[HE-124]
   Hecho** con una nota en el GDD §4 que apunta a las fichas de motor.
8. **Ambiente HE-A7b** (`disenador-personajes`): trae mariposas como relleno; hay que sacarlas del mapa y de
   todas las escenas donde juegan Nicole y Sofía.

---

## 13. Decisiones (antes preguntas abiertas) [HE-124: el PO delegó, 05-Nov-2026]

1. **Hilo del planeta** → **sí**: "la siesta y el Gran Desfile" (cada zona despierta un rincón).
2. **Zona secreta** → **sí**: el Valle de los Dinosaurios como zona 5, con el pony estelar; los dinos son el
   gusto más fuerte de Maxi y la z5 de frío pediría más arte nuevo.
3. **Zona perfecta para Nicole y Sofía por igual** → **sí**: mismo collar y mismo marco dorado (evita la
   comparación entre hermanas); `album-recuerdos.md` debe extender el marco a Nicole (hallazgo §12.6).
4. **¿Quién habla? con 2 rondas de 60 s** → **sí** para Nicole y Sofía; Maxi juega 1 ronda de 45-60 s (§4.1).
5. **Retos dorados de Sofía** → **"El gran tablero de Toby" y "Sendero sin fin"**, ambos con derrota (§6.2).
6. **Depredadores** → **fuera** leones, tigres, lobos, cocodrilos y la hiena; los dinos carnívoros de Maxi se
   quedan en versión tierna.
7. **Animales de Chile para Sofía** → **sí**; cada dato curioso lo verifica `guionista` contra una fuente.
8. **Perrito bombero y T-rex bombero para Maxi** → **sí**.
9. **El loro que dice el nombre** → **sí**, con la voz grabada por la familia si se puede y TTS local mientras
   tanto (nada sale de la tablet).
10. **Modo equipo v1** → **sí**, en las 5 estaciones de ¿Quién habla?; el resto llega con la batalla (HE-115).
    El modo equipo no cambia con HE-124.
11. **Alcance del capítulo 2** → **zonas 1-3 son el núcleo** (pieza, escena y batalla); las zonas 4-5 llegan
    como expedición extra si el arte aprieta.
12. **Las decisiones [Prov] de §2.4** → **confirmadas** como dice esa tabla (con los cambios de HE-124).
