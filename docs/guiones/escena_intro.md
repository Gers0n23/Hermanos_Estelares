# Escena de historia — Intro: «El living se transforma»

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

- **Capítulo**: 1 — apertura de toda la aventura.
- **Duración estimada**: ~1:45-2:45 min de cinemática sin interacción del jugador (Beats 1-8); el
  juego se vuelve interactivo recién al llegar al Mapa Estelar.
- **Personajes**: Maxi, Nicole, Sofía, Cometa, Papá (en persona, brevemente, y luego en
  video-llamada), **el Coleccionauta** (aparece en pantalla por primera vez en esta escena).
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

## Beat 1 — Una tarde cualquiera

**Acotación**: Living cálido, luz dorada de atardecer entrando por la ventana grande. Los tres
hermanos ya están jugando en la alfombra a su manera — todo normal, nada espacial todavía.
Maxi empuja un dino-auto imaginario, Nicole dibuja sentada sobre un cojín, Sofía arma una
"misión" de juego con los cojines del sofá como si fuera la líder de una patrulla.

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
lugar vacío.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_004 | (sfx) | chispitas doradas + *fiuu* mágico anunciando que algo aparece | juguetón, nunca tenso |
| intro_005 | El Coleccionauta | «¡Ohhh, pero miren nada más... un papá sonriente, con chaqueta de piloto y todo! Increíble. Justo lo que me faltaba en la colección.» | asombrado, torpe, encantado — como quien encuentra el juguete perfecto, jamás amenazante |
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

## Beat 4 — Cometa tranquiliza y cuenta quién es el Coleccionauta

**Acotación**: Cometa se palmea el pecho donde lleva cruzado su "álbum de abrazos" (librito con
correa y corazón dorado), un gesto cariñoso de "tranquilos, lo conozco bien" — ya no hace falta
narrar el secuestro con sombras, los niños acaban de verlo; esta vez el álbum es solo un gesto de
calidez, no una recreación.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_018 | Cometa | «Lo conozco desde que éramos chicos —armamos naves juntos, en el mismo planeta— y anda coleccionando las cosas más increíbles del universo. Hoy le pareció que su papá era de lo más increíble que ha visto.» | cálido, como contando algo entrañable, nunca alarmante |
| intro_019 | Nicole | «¿Y está bien? ¿No tiene frío ni nada?» | preocupación tierna, no pánico |
| intro_020 | Cometa | «¡Clarísimo que sí! El Coleccionauta es despistado y solitario, pero jamás malo. Seguro ya le ofreció una de sus galletas raras.» | tranquilizador, con humor |
| intro_021 | Sofía | «Entonces... hay que ir a buscarlo.» | decidida, líder, sin miedo |
| intro_022 | Cometa | «¡Esa actitud! Por eso vine a buscarlos a ustedes tres.» | celebra la decisión de Sofía, nunca apura |

## Beat 5 — Los trajes con estrellas de poder

**Acotación**: Cometa agita sus bracitos cortos y de la navecita salen flotando tres trajes
espaciales (blanco/azul de Maxi, blanco/rosado de Nicole, rosado/turquesa de Sofía) que se posan
sobre cada hermano con un destello dorado suave — transformación mágica, alegre, sin solemnidad.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_023 | Cometa | «Para este viaje van a necesitar esto: sus trajes de Hermanos Estelares, con estrella de poder incluida.» | ceremonioso-juguetón |
| intro_024 | Maxi | «¡¡Wiiii!!» | grito de alegría, salta |
| intro_025 | Nicole | «¡Es rosado! ¡Es perfecto!» | encantada |
| intro_026 | Sofía | «Turquesa y rosado... buen gusto, Cometa.» | halagada, con humor y guiño |

## Beat 6 — La nave-estrella, averiada pero lista para un salto

**Acotación**: se corre una "cortina" imaginaria de luz y aparece flotando junto a la ventana la
nave-estrella en su estado aprobado de capítulo 1 (casco, cúpula y toberas presentes; 6 huecos
fantasma dorados y punteados donde faltan las piezas — ver `docs/guia-estilo-generacion.md` §3,
"Nave-estrella"). Ya no es solo "una nave a la que le faltan piezas": ahora sabemos por qué —
quedó así de tanto perseguir al Coleccionauta por la galaxia.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_027 | Cometa | «Y esta es nuestra nave-estrella. Quedó un poco averiada de tanto perseguir al Coleccionauta por la galaxia... por ahora solo le alcanza la energía para un saltito, el justo para llegar al primer planeta. ¡Las piezas que le faltan las conseguimos jugando!» | entusiasta, invita sin presionar |
| intro_028 | Sofía | «¿Jugando? Me gusta cómo suena esa misión.» | lideresa, complacida |
| intro_029 | Nicole | «¡Voy a hacer amigos en cada planeta!» | ilusionada |
| intro_030 | Maxi | «¡Vamo vamo vamo!» | saltando de alegría (nunca de apuro narrativo) |

## Beat 7 — Primera video-llamada de papá (cierre tranquilizador)

**Acotación**: la nave brilla y aparece una video-llamada — papá, cómodo, sentado en algo parecido
a un sillón raro de la colección del Coleccionauta, sonriente, sin ningún signo de angustia. Es el
cierre del hilo que abrió el destello del Beat 2: confirma, cara a cara, que está bien.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_031 | Papá | «¡Hola, mis campeones! Qué manera de salir de paseo sin avisar, ¿no? Miren dónde estoy... el Coleccionauta tiene una silla tan cómoda que casi ni quiero que me rescaten. Es broma, ¡los espero con muchas ganas!» | tranquilo, cariñoso, retoma el chiste que dejó a medias en el Beat 2 |
| intro_032 | Papá | «Eso sí, no se apuren por mí, yo estoy la mar de bien. Ustedes disfruten el viaje, ¿ya?» | calma explícita, cero presión de rescate |
| intro_033 | Maxi | «¡Papi!» | feliz, saluda con la mano |
| intro_034 | Nicole | «¡Te extrañamos! ¡Ya vamos!» | cariñosa, entusiasta |
| intro_035 | Sofía | «Aguanta ahí, papá. Vamos a hacerlo bien hecho.» | protectora, líder, con guiño de humor |
| intro_036 | Papá | «Sé que sí. Los quiero un montón. ¡Nos vemos, Hermanos Estelares!» | cálido, orgulloso, se despide con un guiño |

## Beat 8 — Partida hacia el Mapa Estelar

**Acotación**: la llamada se corta con un destello de estrellitas; Cometa flota hacia la ventana;
los tres hermanos se miran y sonríen. Corte a Mapa Estelar — fin de la cinemática, empieza el
juego interactivo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_037 | Cometa | «¿Listos para volar, Hermanos Estelares?» | invitando, sin apuro |
| intro_038 | Todos | «¡¡Siiiií!!» | coro feliz |

---

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
