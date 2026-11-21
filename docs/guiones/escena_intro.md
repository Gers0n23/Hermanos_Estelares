# Escena de historia — Intro: «El living se transforma»

> **Regla de dialecto (decisión del PO, 21-Nov-2026)**: "chileno suave, y a los niños casi sin modismos, o más neutros".
> Papá y el Coleccionauta hablan en chileno suave (ustedes, "pucha", "acá"; sin groserías) y **no usan "po"** (decisión del PO, 21-Nov-2026: la voz la pronuncia de forma artificial). Maxi, Nicole y Sofía
> hablan en español neutro, sin "po", "cachai" ni regionalismos fuertes. Cometa y Coco no cambian. Solo se reescribió el
> texto entre comillas de « »; ids, sentido y largo se conservan.

> Guion narrativo (HE-D5). Insumo para `director-cinematicas` (storyboard) y `dev-godot` (HE-30).
> Fuente de verdad: `docs/diseno-juego.md` §1-§2, §6.
>
> **Revisión 07-Ago-2026**: sincronizada con el reordenamiento del guion principal aprobado por
> el PO el 06-Ago-2026 (`docs/diseno-juego.md` §1, nota de cabecera). Cambia la estructura de
> fondo de la escena: **el secuestro de papá ahora ocurre en pantalla** (antes se contaba después,
> vía sombras chinas en el álbum de Cometa) y **la llegada de Cometa queda explícita como una
> persecución fallida por segundos** — el choque de su navecita ya no es un aterrizaje cualquiera,
> es la consecuencia directa de ir a toda velocidad detrás del Coleccionauta. Se preserva intacto
> el tono: el secuestro se resuelve en un parpadeo mágico, jamás como una escena de peligro (ver
> Salvaguardas de tono, reescritas abajo). Los ids de línea se renumeraron de punta a punta —
> ninguna línea de esta escena tenía audio grabado todavía (`assets/audio/voces/guion_voces.md`
> seguía en "pendiente de grabar" en el 100% de sus filas), así que la renumeración no rompe nada.
>
> **Revisión 21-Nov-2026** (decisiones del PO, vinculantes): Cometa es el **narrador** (voz en off y en
> escena, sección "Narración"); las escenas de casa (Beats 1 a 5) van como **stills** con voz encima; el
> motivo del Coleccionauta queda como lo dijo el PO (Beat 4, `intro_018` reescrita y `intro_018b`/`018c`
> nuevas); la ropa de casa de cada hermano está asignada (Beat 1); se agrega el **Beat 8b**, la línea en
> off para el despegue del video de Blender (`intro_viaje_01`).
>
> **Revisión 21-Nov-2026 (2, decisiones del PO)**: la nave-estrella **baja al patio** (Beat 6), así que ya no
> aparece junto a la ventana y el Beat 8 sale por el patio. El Beat 6 ya no tiene pregunta abierta. Entre el
> despegue (`intro_viaje_01`) y la zona 1 va la **escena de primer contacto con Coco**, que vive en su propio
> guion: `docs/guiones/escena_llegada_arcoiris.md`. Esta intro no la contiene.

- **Capítulo**: 1 — apertura de toda la aventura.
- **Duración estimada**: ~1:45-2:45 min de cinemática sin interacción del jugador (Beats 1-8); el
  juego se vuelve interactivo recién al llegar al Mapa Estelar.
- **Personajes**: Maxi, Nicole, Sofía, Cometa (en escena y **narrador en voz en off**), Papá (en persona,
  brevemente, y luego en video-llamada), **el Coleccionauta** (aparece en pantalla por primera vez en esta
  escena).
- **Escenario**: Casa/living — ficha aprobada por el PO en `docs/guia-estilo-generacion.md` §3
  ("Entornos canon → Casa/living").
- **Prefijo de id de línea / carpeta de audio**: `intro_XXX` → `assets/audio/voces/historia/intro/`

## Salvaguardas de tono (obligatorias — GDD §6, no negociables en este guion)

1. **El "secuestro" de papá se ve, pero nunca da miedo.** Dura un parpadeo: el Coleccionauta
   aparece, se maravilla con papá, y ambos desaparecen en un solo destello dorado — sin forcejeo,
   sin persecución visual, sin que la cámara se detenga en el momento del destello (corta rápido a
   la reacción de los niños). El Coleccionauta actúa por asombro y torpeza, **nunca por maldad** —
   se comporta como quien encuentra el juguete perfecto, no como un secuestrador. Papá reacciona
   con sorpresa y humor, nunca con angustia: alcanza a soltar un chiste a medio terminar antes de
   desaparecer sonriendo.
2. Cometa **jamás da miedo**: entra dando tumbos, se ríe de sí mismo, es torpe y tierno desde su
   primera aparición — incluso frustrado por haber perdido al Coleccionauta por segundos, se repone
   al toque y nunca se pone dramático.
3. **Nadie regaña ni apura.** Cero variantes de "date prisa" o "no hay tiempo que perder".
4. Papá aparece **tranquilo, sonriente, bromista** en todo momento — tanto en su breve aparición en
   persona (Beat 2) como en la video-llamada (Beat 7) — jamás angustiado ni pidiendo rescate
   urgente.
5. Maxi (2) nunca muestra miedo real ante nada de esta escena — ni siquiera ante el destello que se
   lleva a papá: lo vive como un espectáculo de luces bonito, no como una amenaza. Se sorprende, se
   ríe, grita de alegría, pero nunca llora de susto.
6. **La tranquilidad llega rápido.** Apenas Cometa aparece (segundos después del destello, en la
   propia historia), ya está tranquilizando a los niños — nunca se los deja "en el aire"
   preguntándose qué pasó por más de un par de líneas.

---

## Narración (decisiones del PO, 21-Nov-2026)

1. **Quién narra**: Cometa, con su **voz oficial de fal.ai** (`assets/audio/voces/guion_voces.md`, sección
   de Cometa). No se crea una voz nueva para el narrador. Los niños, papá y el Coleccionauta no narran nunca.
2. **Dos formas de hablar de Cometa**:
   - *En escena*: Cometa aparece en cuadro y habla con los niños (Beats 3, 4, 5, 6 y 8).
   - *Voz en off*: Cometa no aparece en cuadro. Suena sobre stills o video para explicar algo o llevar de
     un lugar a otro (hoy, solo el Beat 8b: el viaje).
3. **Cuándo narra en off**: en transiciones y explicaciones. **Nunca** encima del destello del Beat 2 ni
   encima de una línea de los niños. Máximo una línea en off por transición, de 8 s o menos.
4. **Escenas de niños = stills**: en la casa (Beats 1 a 5) cada hermano es una **imagen fija** con su voz
   encima. El movimiento sale del entorno (chispitas, destello, luz, un paneo leve de cámara), no de un rig
   ni de animación de cuerpo. El cambio de ropa de casa a traje (Beat 5) es un corte de still con destello.
5. **Ropa de casa** (decisión del PO, para las acotaciones y el arte):
   - **Maxi** (2, el más chico): camiseta azul marino y short con hojas.
   - **Nicole** (5, cola alta, al centro): buzo gris oscuro y jeans.
   - **Sofía** (8, la más alta, pelo rizado y audífonos rosas): camiseta rosa de rayas y jeans.
6. **Qué no está decidido**: si papá y el Coleccionauta del Beat 2 van como stills o animados (ver
   "Preguntas abiertas").

## Beat 1 — Una tarde cualquiera

**Acotación**: Living cálido, luz dorada de atardecer entrando por la ventana grande. Los tres
hermanos ya están jugando en la alfombra a su manera — todo normal, nada espacial todavía.
Maxi empuja un dino-auto imaginario, Nicole dibuja sentada sobre un cojín, Sofía arma una
"misión" de juego con los cojines del sofá como si fuera la líder de una patrulla.
*Ropa de casa (PO, 21-Nov-2026)*: Maxi, camiseta azul marino y short con hojas; Nicole, buzo gris oscuro y
jeans; Sofía, camiseta rosa de rayas y jeans. Los tres son **stills** (ver Narración).

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_001 | Sofía | «Atención, tripulación... ¡el cojín gigante es un asteroide! Nadie lo toca.» | jugando a mandar, cariñosa, con humor |
| intro_002 | Maxi | «¡Vrrrum! ¡Dino-auto!» | gritando feliz, jugando solo |
| intro_003 | Nicole | «Miren, le hice una coleta rosada a mi dibujo del caballito.» | orgullosa, mostrando su dibujo |

## Beat 2 — El Coleccionauta aparece... y se lleva a papá (nuevo, se ve en pantalla)

**Acotación**: sin aviso, un brillo cálido tipo confeti dorado chispea en una esquina del living —
la misma "magia del living" de siempre, nunca oscura — y de él aparece el Coleccionauta,
tambaleándose con su mochila-torre desbordante, gafas-lupa gigantes puestas. Papá está cerca (por
ejemplo, entrando desde la cocina con algo en la mano, o acomodando un cojín) y el Coleccionauta lo
ve: sus ojos se agrandan tras las gafas-lupa, aplaude encantado. Antes de que nadie reaccione, un
único destello dorado grande envuelve a los dos y... desaparecen. Todo dura un parpadeo — la cámara
no se detiene en el destello, corta directo a los tres hermanos con los ojos como platos mirando el
hueco del living donde estaban papá y el Coleccionauta. Son tres stills (uno por hermano, con la cabeza
girada hacia el hueco). **Cometa todavía no llegó: ningún niño mira hacia Cometa, hacia la ventana ni hacia
la nave.** (Cambio 21-Nov-2026: antes el plano cerraba sobre "el lugar vacío" sin decir hacia dónde miran.)

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_004 | (sfx) | chispitas doradas + *fiuu* mágico anunciando que algo aparece | juguetón, nunca tenso |
| intro_005 | El Coleccionauta | «¡Ohhh, pero miren nada más... un papá sonriente, con chaqueta de piloto y todo! ¡Increíble! Justo lo que me faltaba en la colección.» | asombrado, torpe, encantado — como quien encuentra el juguete perfecto, jamás amenazante |
| intro_006 | Papá | «¿Eh? Un momentito, ni siquiera alcancé a avisar que iba a...» | sorprendido y con humor, se corta a media frase — cero angustia |
| intro_007 | (sfx) | destello dorado grande + *poof* — papá y el Coleccionauta desaparecen juntos | mágico, instantáneo, nunca un forcejeo |
| intro_008 | Sofía | «¡¿Qué?! ¿Adónde se fue papá?» | sorprendida, ya activando su modo líder — sin pánico |
| intro_009 | Nicole | «¿Se lo comió la lucecita brillante?» | curiosa, tierna, nada de miedo |
| intro_010 | Maxi | «¡Uuuh, luuuces!» | encantado, aplaude — el destello le pareció hermoso |

## Beat 3 — Llega Cometa (persiguiéndolo, y llega tarde por segundos)

**Acotación**: chispitas doradas entran flotando por la ventana antes que nada (la "magia" del
living, ver su ficha de entorno). Un ovillo pequeño —la navecita de Cometa— entra dando tumbos por
la ventana abierta, rebota suave contra la cortina (*bonk* de peluche, no de golpe duro), gira
como un trompo sobre la alfombra y se detiene panza arriba entre los cojines. Se abre una
escotillita y sale Cometa, mareado, con espiralitas en los ojos por un segundo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_011 | (sfx) | *bonk* de cortina + *fiuuu* + trompo girando sobre alfombra | cómico, mullido, nunca un golpe fuerte |
| intro_012 | Cometa | «¡Uuuy, tumbo! Jijiji... a ese aterrizaje le doy un 6 de 10.» | riéndose de sí mismo, mareado |
| intro_013 | Cometa | «Buuu, lo perdí por segunditos... ¡otra vez! Ese Coleccionauta corre rapidísimo cuando quiere.» | frustración cómica y breve, se repone al toque, sin drama |
| intro_014 | Maxi | «¡Nave!!» | señalando, encantado, sin asomo de miedo |
| intro_015 | Nicole | «¡Hola! ¿Estás bien, amiguito?» | preocupación tierna — ya hace amigos |
| intro_016 | Sofía | «Un momento... ¿tú hablas? ¿Y por qué eres tan redondito? Y... ¿tú viste al que se llevó a mi papá?!» | curiosa y al mando, sube la voz en la última pregunta sin gritar de miedo |
| intro_017 | Cometa | «¡Redondito y orgulloso! Hola, Hermanos Estelares. Bueno... todavía no lo son, eso viene ahora. Y sí, lo vi: ese despistado es mi amigo, el Coleccionauta.» | entusiasta, gesto teatral, tranquilizador desde la primera mención |

## Beat 4 — Cometa tranquiliza y cuenta quién es el Coleccionauta (en escena: Cometa visible)

**Acotación**: Cometa se palmea el pecho donde lleva cruzado su "álbum de abrazos" (librito con
correa y corazón dorado), un gesto cariñoso de "tranquilos, lo conozco bien" — ya no hace falta
narrar el secuestro con sombras, los niños acaban de verlo; esta vez el álbum es solo un gesto de
calidez, no una recreación.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_018 *(reescrita 21-Nov-2026; antes decía «Hoy le pareció que su papá era de lo más increíble que ha visto»)* | Cometa | «Lo conozco desde que éramos chicos —armamos naves juntos, en el mismo planeta—. Y anda coleccionando las cosas más increíbles del universo.» | cálido, como contando algo entrañable, nunca alarmante |
| intro_018b *(nueva, 21-Nov-2026)* | Cometa | «Y le pareció increíble el papá de ustedes, ¡por criar a tres niños tan buenos! Así que se lo llevó a su colección.» | cálido y con humor de "¡qué despistado!"; nunca de reproche ni de amenaza. Es el motivo, dicho una sola vez: no sumar más |
| intro_018c *(nueva, 21-Nov-2026, **opcional**: se borra si la intro queda larga)* | Cometa | «¡Y se le pierden hasta las llaves!» | con risa; siembra el gag de las llaves de la prueba final (`final_011`) |
| intro_019 | Nicole | «¿Y está bien? ¿No tiene frío?» | preocupación tierna, no pánico |
| intro_020 | Cometa | «¡Clarísimo que sí! El Coleccionauta es despistado y solitario, pero jamás malo. Seguro ya le ofreció una de sus galletas raras.» | tranquilizador, con humor |
| intro_021 | Sofía | «Entonces... hay que ir a buscarlo.» | decidida, líder, sin miedo |
| intro_022 | Cometa | «¡Esa actitud! Por eso vine a buscarlos a ustedes tres.» | celebra la decisión de Sofía, nunca apura |

## Beat 5 — Los trajes con estrellas de poder

**Acotación**: Cometa agita sus bracitos cortos y de la navecita salen flotando tres trajes
espaciales (blanco/azul de Maxi, blanco/rosado de Nicole, rosado/turquesa de Sofía) que se posan
sobre cada hermano con un destello dorado suave — transformación mágica, alegre, sin solemnidad. Los niños son stills (ver Narración): el cambio de ropa de
casa al traje es un corte de still con destello, no una animación de cuerpo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_023 | Cometa | «Para este viaje van a necesitar esto: sus trajes de Hermanos Estelares, con estrella de poder incluida.» | ceremonioso-juguetón |
| intro_024 | Maxi | «¡¡Wiiii!!» | grito de alegría, salta |
| intro_025 | Nicole | «¡Es rosado! ¡Es perfecto!» | encantada |
| intro_026 | Sofía | «Turquesa y rosado... buen gusto, Cometa.» | halagada, con humor y guiño |

## Beat 6 — La nave-estrella, averiada pero lista para un salto

**Acotación** *(decisión del PO, 21-Nov-2026: la nave baja al patio)*: los tres salen al patio por la
puerta corrediza del living (stills con voz; el movimiento sale del entorno, un paneo leve de cámara). Sobre
el pasto del patio, el mismo lugar desde donde después despega (Beat 8b), baja suave desde el cielo la
nave-estrella y se posa, en su estado aprobado de capítulo 1 (casco, cúpula y toberas presentes; 6 huecos
fantasma dorados y punteados donde faltan las piezas — ver `docs/guia-estilo-generacion.md` §3,
"Nave-estrella"). Ya no es solo "una nave a la que le faltan piezas": ahora sabemos por qué —
quedó así de tanto perseguir al Coleccionauta por la galaxia. La bajada es un plano de movimiento de la
nave, no de cuerpo de los niños; el medio (video IA o animación simple) lo decide `director-cinematicas`.
*`intro_027` no cambia: «Y esta es nuestra nave-estrella» se dice con la nave ya posada en el patio.*

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_027 | Cometa | «Y esta es nuestra nave-estrella. Quedó un poco averiada de tanto perseguir al Coleccionauta por la galaxia... por ahora solo le alcanza la energía para un saltito, el justo para llegar al primer planeta. ¡Las piezas que le faltan las conseguimos jugando!» | entusiasta, invita sin presionar |
| intro_028 | Sofía | «¿Jugando? Me gusta cómo suena esa misión.» | lideresa, complacida |
| intro_029 | Nicole | «¡Voy a hacer amigos en cada planeta!» | ilusionada |
| intro_030 | Maxi | «¡Vamos, vamos, vamos!» | saltando de alegría (nunca de apuro narrativo) |

## Beat 7 — Primera video-llamada de papá (cierre tranquilizador)

**Acotación**: la nave brilla y aparece una video-llamada — papá, cómodo, sentado en algo parecido
a un sillón raro de la colección del Coleccionauta, sonriente, sin ningún signo de angustia. Es el
cierre del hilo que abrió el destello del Beat 2: confirma, cara a cara, que está bien.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_031 | Papá | «¡Hola, mis campeones! ¡Qué manera de salir de paseo sin avisar! Miren dónde estoy... el Coleccionauta tiene una silla tan cómoda que casi ni quiero que me rescaten. Es broma, ¡los espero con muchas ganas!» | tranquilo, cariñoso, retoma el chiste que dejó a medias en el Beat 2 |
| intro_032 | Papá | «Eso sí, no se apuren por mí, yo estoy muy bien, de verdad. Ustedes disfruten el viaje, ¿ya?» | calma explícita, cero presión de rescate |
| intro_033 | Maxi | «¡Papi!» | feliz, saluda con la mano |
| intro_034 | Nicole | «¡Te extrañamos! ¡Ya vamos!» | cariñosa, entusiasta |
| intro_035 | Sofía | «Aguanta ahí, papá. Vamos a hacerlo bien hecho.» | protectora, líder, con guiño de humor |
| intro_036 | Papá | «Sé que sí. Los quiero un montón. ¡Nos vemos, Hermanos Estelares!» | cálido, orgulloso, se despide con un guiño |

## Beat 8 — Partida hacia el Mapa Estelar

**Acotación**: la llamada se corta con un destello de estrellitas; Cometa flota hacia la puerta del patio, donde espera la nave *(consecuencia de la decisión A, 21-Nov-2026: antes decía «la ventana»)*;
los tres hermanos se miran y sonríen. Corte al despegue (Beat 8b, voz en off de Cometa) y después al Mapa Estelar — fin de la cinemática, empieza el
juego interactivo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_037 | Cometa | «¿Listos para volar, Hermanos Estelares?» | invitando, sin apuro |
| intro_038 | Todos | «¡¡Siiiií!!» | coro feliz |

---

## Beat 8b — Despegue y viaje al Planeta Arcoíris (voz en off de Cometa) *(nuevo, 21-Nov-2026)*

**Acotación**: video de Blender `poc/cinematica_blender/salida/despegue_tierra_v1.mp4` (24 fps, unos 8,3 s).
La nave-estrella se levanta del pasto del patio, enciende motores (las llamas crecen hacia el cuadro ~14, o
sea ~0,6 s) y sale hacia el cielo de atardecer. **Sin personajes en cuadro ni diálogo de los niños**: solo la
voz en off de Cometa. *Verificar al verlo*: en esta sesión no pude mirar el mp4; los tiempos salen de su
script `poc/cinematica_blender/despegue_tierra.py`.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_viaje_01 *(nueva, 21-Nov-2026)* | Cometa (voz en off) | «¡Despegamos! Vamos rumbo al Planeta Arcoíris. El viaje es largo, pero con cosquillitas de estrellas se pasa volando.» | alegre, cálido, en off; entra cuando crecen las llamas y termina antes de la salida al cielo (~7 s). Nunca apura |

## Preguntas abiertas *(21-Nov-2026)*

- **Beat 6**: *resuelto* (decisión A del PO, 21-Nov-2026): la nave baja al patio. La pregunta se quita.
- **Papá y el Coleccionauta en el Beat 2 (y papá en la video-llamada del Beat 7): stills o animados.**
  *Propuesta del guionista, pendiente de decisión del PO (no decidida):*
  - **Stills con movimiento simple**, igual que los niños. Papá y el Coleccionauta se mueven solo con: un
    rebote de papá al entrar desde la cocina, un zoom lento al Coleccionauta cuando aplaude, un rebote de su
    mochila-torre al tambalearse, y dos o tres posiciones de boca (solo para hablar). Sin rig: el Coleccionauta
    todavía no tiene rig, y un still con esos movimientos alcanza para su tono torpe y asombrado.
  - **Video IA solo en los planos de acción física.** En la intro serían: el destello del Beat 2 (aparición y
    desaparición) y el choque de la navecita del Beat 3. El Beat 6 (bajada de la nave al patio) es un plano de
    movimiento de la nave; su medio lo decide `director-cinematicas`.
  - **Papá en la video-llamada (Beat 7)**: still con un bote suave y 2-3 posiciones de boca. Ningún plano de
    papá pasa a video IA.
  - Mismo criterio en la escena de llegada (`docs/guiones/escena_llegada_arcoiris.md`): video IA solo en los
    planos 02, 04, 06 y 10.
- **Beat 8b**: el PO escribió "del living al planeta Arcoíris", pero el video despega del patio. Con la nave
  posada en el patio (Beat 6), el viaje empieza desde el patio y es continuo. Confirmar.
- **`intro_018c`** ("¡Y se le pierden hasta las llaves!"): **recomendación del guionista: quitarla, sin borrarla
  todavía** (decisión D del PO). Motivos: (1) los Beats 4 con `intro_018` y `intro_018b` ya dicen el motivo y
  quién es el Coleccionauta; esta línea no suma y alarga la intro, que ya está en el tope de su rango de
  duración; (2) el gag de las llaves es del propio Coleccionauta en `final_011` (`prueba_final_cooperativa.md`),
  y ahí cae mejor, dicho por él. Si el PO la quiere, es la línea que menos cuesta quitar: no cambia ningún otro
  id de la intro.

## Notas para `director-cinematicas`

- El Beat 2 es el cambio estructural principal de esta revisión: el secuestro **ya se ve**, así
  que el plano clave es el destello (aparición del Coleccionauta → asombro → destello grande →
  desaparecen los dos) resuelto como **una sola idea de movimiento continua**, muy corta — no se
  trata como una escena de persecución ni de forcejeo, y la cámara corta a la reacción de los
  niños apenas termina el destello, nunca se queda "mirando el vacío" más de un instante.
- El Beat 3 (choque de Cometa) ya no es solo el primer chiste físico del juego: ahora también
  explica visualmente el "por segunditos" que menciona en `intro_013` — vale la pena que el timing
  del choque se sienta como una llegada apurada (no solo torpe), sin perder el mullido/gracioso de
  siempre (referencia de humor: Maxi, GDD §"Humor por edad").
- El Beat 6 hereda directamente la razón del Beat 2-3: la nave está averiada por la persecución, no
  por un desperfecto genérico — si el storyboard permite un guiño visual (un rasguño o remiendo
  fresco distinto a los remiendos "viejos" ya parchados de siempre) es un lindo detalle opcional,
  no obligatorio.
- La video-llamada (Beat 7) es el primer contacto con papá dentro del juego y el cierre emocional
  directo del destello del Beat 2: fija el estándar de tono para todas las siguientes (planetas
  1-6 y prueba final) — siempre cómodo, siempre bromista, y aquí además cumple la función de
  "confirmar que está bien" que el Beat 2 dejó abierta.
- **Pendiente de arte**: el Beat 1 y el Beat 5 necesitan que los tres hermanos se vean **sin** su
  traje espacial (ropa de casa/pijama de tarde) antes de la transformación — hoy no existe ninguna
  hoja de referencia con "ropa de calle" para Maxi/Nicole/Sofía (sus fichas y rigs solo cubren el
  traje estelar, que es su diseño por defecto). Es un insumo que `disenador-personajes` debe
  producir antes de generar el Beat 1 y el arranque del Beat 5 (ver `docs/cinematicas/escena_intro.md`,
  nota de gap de arte).
- **Actualización 21-Nov-2026**: la ropa de casa de cada hermano ya la decidió el PO (sección Narración, punto 5).
  Los lotes `assets/generadas/cinematicas/intro/ropa_casa_lineup_v*.png` y los stills de `01b`/`03b` deben
  revisarse contra esa asignación antes de usarlos; el guion no los valida. Los Beats 1 a 5 se arman con
  stills, no con rigs (sección Narración, punto 4).
- **Beat 8b**: el despegue del video de Blender es el primer plano exterior de la intro. Si el storyboard lo
  alarga, la línea `intro_viaje_01` se mantiene; no se agregan más líneas en off.
- **Beat 6 (patio, 21-Nov-2026)**: la nave debe quedar posada en el mismo punto del pasto desde el que despega
  `poc/cinematica_blender/salida/despegue_tierra_v1.mp4`, para que el corte del Beat 6 al Beat 8b sea continuo.
- **Después del Beat 8b**: va el video de presentación del planeta (`poc/cinematica_blender/salida/presentacion_arcoiris.mp4`)
  y luego la escena de primer contacto con Coco (`docs/guiones/escena_llegada_arcoiris.md`), antes de la zona 1.
  No pertenece a esta intro.
