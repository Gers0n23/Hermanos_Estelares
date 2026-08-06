# Escena de historia — Intro: «El living se transforma»

> Guion narrativo (HE-D5). Insumo para `director-cinematicas` (storyboard) y `dev-godot` (HE-30).
> Fuente de verdad: `docs/diseno-juego.md` §1-§2, §6.

- **Capítulo**: 1 — apertura de toda la aventura.
- **Duración estimada**: ~1:30-2:30 min de cinemática sin interacción del jugador (Beats 1-7); el
  juego se vuelve interactivo recién al llegar al Mapa Estelar.
- **Personajes**: Maxi, Nicole, Sofía, Cometa, Papá (voz, video-llamada).
- **Escenario**: Casa/living — ficha aprobada por el PO en `docs/guia-estilo-generacion.md` §3
  ("Entornos canon → Casa/living").
- **Prefijo de id de línea / carpeta de audio**: `intro_XXX` → `assets/audio/voces/historia/intro/`

## Salvaguardas de tono (obligatorias — GDD §6, no negociables en este guion)

1. El "secuestro" de papá **se cuenta, nunca se muestra en vivo**: ningún niño ve al
   Coleccionauta llevándose a papá frente a ellos. Cometa lo relata como un cuento ya resuelto,
   con humor, apoyado en sombras de luz dorada juguetonas (nunca una recreación realista).
2. Cometa **jamás da miedo**: entra dando tumbos, se ríe de sí mismo, es torpe y tierno desde su
   primera aparición.
3. **Nadie regaña ni apura.** Cero variantes de "date prisa" o "no hay tiempo que perder".
4. Papá aparece **tranquilo, sonriente, bromista** — jamás angustiado ni pidiendo rescate urgente.
5. Maxi (2) nunca muestra miedo real ante nada de esta escena — se sorprende, se ríe, grita de
   alegría, pero nunca llora de susto.

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

## Beat 2 — Llega Cometa (entrada cómica, nunca violenta)

**Acotación**: chispitas doradas entran flotando por la ventana antes que nada (la "magia" del
living, ver su ficha de entorno). Un ovillo pequeño —la navecita de Cometa— entra dando tumbos por
la ventana abierta, rebota suave contra la cortina (*bonk* de peluche, no de golpe duro), gira
como un trompo sobre la alfombra y se detiene panza arriba entre los cojines. Se abre una
escotillita y sale Cometa, mareado, con espiralitas en los ojos por un segundo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_004 | (sfx) | *bonk* de cortina + *fiuuu* + trompo girando sobre alfombra | cómico, mullido, nunca un golpe fuerte |
| intro_005 | Cometa | «¡Uuuy, tumbo! Jijiji... a ese aterrizaje le doy un 6 de 10.» | riéndose de sí mismo, mareado |
| intro_006 | Maxi | «¡Nave!!» | señalando, encantado, sin asomo de miedo |
| intro_007 | Nicole | «¡Hola! ¿Estás bien, amiguito?» | preocupación tierna — ya hace amigos |
| intro_008 | Sofía | «Un momento... ¿tú hablas? ¿Y por qué eres tan redondito?» | curiosa, algo al mando, divertida |
| intro_009 | Cometa | «¡Redondito y orgulloso! Hola, Hermanos Estelares. Bueno... todavía no lo son. Eso viene ahora.» | entusiasta, gesto teatral |

## Beat 3 — Cometa cuenta lo del Coleccionauta (narrado, jamás mostrado en vivo)

**Acotación**: Cometa abre su "álbum de abrazos" (librito con correa y corazón dorado) y, mientras
habla, unas motitas de luz dorada dibujan en el aire una escenita chiquita tipo sombras chinas —
un alienígena regordete y feliz, cargando su mochila-torre desbordante, mientras lleva a upa a un
papá que se ríe. Todo juguetón y redondeado, nunca realista ni tenso.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_010 | Cometa | «Tengo que contarles algo increíble. Mi amigo el Coleccionauta —lo conozco desde chico, armamos naves juntos— anda coleccionando las cosas más increíbles del universo.» | cálido, como contando un cuento |
| intro_011 | Cometa | «Y hoy... encontró algo TAN increíble, que se lo llevó a su colección.» | picardía, suspenso juguetón, nada dramático |
| intro_012 | Sofía | «¿Qué se llevó?» | atenta, ya lista para liderar |
| intro_013 | Cometa | «A su papá.» | simple, casi como remate de chiste, sin drama |
| intro_014 | Maxi | «¿Papi?» | sorprendido, curioso — NO asustado |
| intro_015 | Nicole | «¿Y está bien? ¿No tiene frío ni nada?» | preocupación tierna, no pánico |
| intro_016 | Cometa | «¡Súper bien! El Coleccionauta es despistado y solitario, pero jamás malo. Seguro que ya le ofreció galletas.» | tranquilizador, con humor |
| intro_017 | Sofía | «Entonces... hay que ir a buscarlo.» | decidida, líder, sin miedo |
| intro_018 | Cometa | «¡Esa actitud! Por eso vine a buscarlos a ustedes tres.» | celebra la decisión de Sofía, nunca apura |

## Beat 4 — Los trajes con estrellas de poder

**Acotación**: Cometa agita sus bracitos cortos y de la navecita salen flotando tres trajes
espaciales (blanco/azul de Maxi, blanco/rosado de Nicole, rosado/turquesa de Sofía) que se posan
sobre cada hermano con un destello dorado suave — transformación mágica, alegre, sin solemnidad.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_019 | Cometa | «Para este viaje van a necesitar esto: sus trajes de Hermanos Estelares, con estrella de poder incluida.» | ceremonioso-juguetón |
| intro_020 | Maxi | «¡¡Wiiii!!» | grito de alegría, salta |
| intro_021 | Nicole | «¡Es rosado! ¡Es perfecto!» | encantada |
| intro_022 | Sofía | «Turquesa y rosado... buen gusto, Cometa.» | halagada, con humor y guiño |

## Beat 5 — La nave-estrella (incompleta, con huecos fantasma)

**Acotación**: se corre una "cortina" imaginaria de luz y aparece flotando junto a la ventana la
nave-estrella en su estado aprobado de capítulo 1 (casco, cúpula y toberas presentes; 6 huecos
fantasma dorados y punteados donde faltan las piezas — ver `docs/guia-estilo-generacion.md` §3,
"Nave-estrella").

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_023 | Cometa | «Y esta es nuestra nave. Le faltan piezas para llegar tan lejos... ¡pero las vamos a conseguir jugando!» | entusiasta, invita sin presionar |
| intro_024 | Sofía | «¿Jugando? Me gusta cómo suena esa misión.» | lideresa, complacida |
| intro_025 | Nicole | «¡Voy a hacer amigos en cada planeta!» | ilusionada |
| intro_026 | Maxi | «¡Vamo vamo vamo!» | saltando de alegría (nunca de apuro narrativo) |

## Beat 6 — Primera video-llamada de papá (cierre tranquilizador)

**Acotación**: la nave brilla y aparece una video-llamada — papá, cómodo, sentado en algo parecido
a un sillón raro de la colección del Coleccionauta, sonriente, sin ningún signo de angustia.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_027 | Papá | «¡Hola, mis campeones! Miren dónde estoy... el Coleccionauta tiene una silla tan cómoda que casi ni quiero que me rescaten. Es broma, ¡los espero con muchas ganas!» | tranquilo, cariñoso, chiste de papá |
| intro_028 | Papá | «Eso sí, no se apuren por mí, yo estoy la mar de bien. Ustedes disfruten el viaje, ¿ya?» | calma explícita, cero presión de rescate |
| intro_029 | Maxi | «¡Papi!» | feliz, saluda con la mano |
| intro_030 | Nicole | «¡Te extrañamos! ¡Ya vamos!» | cariñosa, entusiasta |
| intro_031 | Sofía | «Aguanta ahí, papá. Vamos a hacerlo bien hecho.» | protectora, líder, con guiño de humor |
| intro_032 | Papá | «Sé que sí. Los quiero un montón. ¡Nos vemos, Hermanos Estelares!» | cálido, orgulloso, se despide con un guiño |

## Beat 7 — Partida hacia el Mapa Estelar

**Acotación**: la llamada se corta con un destello de estrellitas; Cometa flota hacia la ventana;
los tres hermanos se miran y sonríen. Corte a Mapa Estelar — fin de la cinemática, empieza el
juego interactivo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| intro_033 | Cometa | «¿Listos para volar, Hermanos Estelares?» | invitando, sin apuro |
| intro_034 | Todos | «¡¡Siiiií!!» | coro feliz |

---

## Notas para `director-cinematicas`

- Ningún plano necesita mostrar al Coleccionauta "en acción" secuestrando — el Beat 3 se resuelve
  con luces/sombras juguetonas, no con un personaje real actuando la escena.
- El *bonk* de la llegada de Cometa (intro_004-005) es el primer chiste físico del juego: debe
  sonar mullido y gracioso, jamás como un golpe real (referencia de humor: Maxi, GDD §"Humor por
  edad").
- La video-llamada (Beat 6) es el primer contacto con papá dentro del juego: fija el estándar de
  tono para todas las siguientes (planetas 1-6 y prueba final) — siempre cómodo, siempre bromista.
