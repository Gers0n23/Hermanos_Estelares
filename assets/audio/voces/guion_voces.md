# Guion de voces — Los Hermanos Estelares

> **Primera versión de contenido real (HE-D5)**: este documento ya no es solo el esqueleto
> de HE-04 — incluye las primeras tablas de líneas reales, derivadas del guion narrativo
> completo en `docs/guiones/` (escena de intro, escena del Planeta Arcoíris, líneas
> genéricas de Cometa y celebraciones por hermano). Las escenas de los planetas 2-6 y el
> detalle fino de otros motores se agregan a medida que se aborden sus tarjetas (ver
> `docs/guiones/plantilla_escena_planeta.md`). `Audio.reproducir_voz()` sigue sin romper el
> juego si el archivo `.ogg` falta, solo deja un aviso en consola (`push_warning`).
>
> **Voces oficiales de personaje con IA (decisiones del PO del 14-Sep-2026)**: Cometa y Coco
> tienen voz diseñada con Qwen3-TTS en fal.ai y el PO la declaró **la voz oficial del juego**.
>
> - **Cometa** (`herramientas/voces_personajes/cometa/`): criatura chillona y traviesa, con acento latino
>   neutro de doblaje. Dice:
>   - las líneas del núcleo (título, selección e invitaciones de los 6 planetas);
>   - las pistas que suenan al tocarlo;
>   - los avisos de zona abierta y lugar secreto.
> - **Coco** (`herramientas/voces_personajes/coco/`): camaleona suave y cantarina, con acento chileno
>   suave de animadora infantil (muestra "coco_b_chileno_suave_reuso").
>
> **Cómo se generan.** Toda línea se genera con `herramientas/generar_voces_fal.py` desde los
> `lineas_tts.tsv`, según la directiva `# personaje: <id>`. Opciones útiles:
>
> - `--estimar`: muestra el costo antes de gastar.
> - `--omitir-desde`: no vuelve a pagar lo ya generado.
> - `--solo-pendientes`: genera solo lo que falta.
>
> **Líneas pendientes.** Las que todavía suenan con TTS de Windows de relleno están listadas en
> `voces/pendientes_fal.txt` y se regeneran con `--solo-pendientes` cuando la cuenta de fal.ai tenga
> saldo.
>
> **Retos de Sofía (dificultad v3).** Sumaron 36 líneas nuevas (intros, pistas de Cometa, `pista_usada`,
> `regalo`, `prueba_superada` y victorias de la Cima y del reto dorado). El mapa sumó `dorado_disponible`.
>
> **Verificación.** `herramientas/qa_test_voces.gd` verifica que cada línea exista, cargue y dure algo
> razonable.
>
> **La familia.** Grabar a la familia (HE-28) queda para decidirlo aparte, por ejemplo para las
> videollamadas de papá.

## Decisión P2 (GDD §9) — ¿voces grabadas por la familia o TTS?

**Recomendación de `guionista`: grabar voces reales de la familia, con TTS solo como relleno
temporal de desarrollo.** Justificación:

- El proyecto es, por CLAUDE.md, "un regalo personal de un papá para sus tres hijos" — la
  voz de Cometa y de papá siendo las voces reales de casa **es parte del regalo en sí**, no
  un detalle técnico (el propio GDD §7 ya lo sugiere: "que la voz que los guía sea la de casa
  es parte del regalo").
- Las celebraciones de cada hermano (`celeb_maxi_01`, `celeb_nicole_01`, `celeb_sofia_01` y
  variantes) son frases cortísimas — perfectamente grabables con Maxi, Nicole y Sofía reales
  sin exigirles actuación compleja, y son el detalle más entrañable posible: sus propios
  hijos escuchando su propia voz celebrar sus logros en el juego.
- Efecto "cápsula del tiempo": grabar hoy las voces de un niño de 2, uno de 5 y una de 8 años
  es, con el tiempo, un recuerdo en sí mismo — un argumento extra a favor, no solo estético.
- Casting sugerido (ajustable por el PO): **Cometa** y **el Coleccionauta** — papá, con dos
  registros de voz distintos (Cometa dulce/entusiasta, Coleccionauta grandilocuente-tonto);
  **Papá** (personaje) — obviamente la voz real del papá, incluida en las video-llamadas;
  **anfitriones de planeta** (Camaleona Coco, Toby, Octavio, Profesor Plumas, Lila, Mimi) —
  mamá u otro familiar/amigo, para variar timbres y que el elenco no suene todo igual;
  **líneas de celebración e interjecciones de cada hermano** — grabadas directamente por
  Maxi, Nicole y Sofía.
- **TTS en español de calidad** se mantiene como relleno reemplazable durante el desarrollo
  (para no bloquear a `dev-godot` mientras se coordina la grabación real), tal como ya
  contemplaba el GDD §7.

**Esto no es una decisión 100% de diseño** — tiene un componente real de logística/negocio
(disponibilidad de papá para grabar, coordinar sesiones cortas con niños de 2, 5 y 8 años,
equipo de grabación mínimo — un teléfono alcanza dado el tono casero del proyecto). Por eso
**queda marcada explícitamente como pendiente de confirmación final del PO**, no como
resuelta por este documento. Actualícese esta sección cuando el PO decida.

## Cómo se usa este documento

1. Cada línea de voz que el juego necesita tiene una **fila** en la tabla de su
   escena/motor: id de línea, quién la dice, contexto/cuándo suena, texto guía para
   grabar, ruta del archivo `.ogg` y estado.
2. La **ruta del archivo** es siempre relativa a `res://assets/audio/voces/`, organizada
   por escena o motor (ver convención de carpetas más abajo), y es la misma ruta que
   usan los archivos de nivel en `datos/` dentro de su bloque `lineas_voz` (ver
   `docs/fichas/motor-emparejar.md` §4 como ejemplo del contrato).
3. **Estado** de cada línea: `pendiente de guion` (aún no la escribió `guionista`) →
   `pendiente de grabar` (texto listo, falta grabación) → `grabada` (archivo `.ogg` ya
   en `assets/audio/voces/`).
4. Voz de Cometa y de la familia: ver decisión pendiente **P2** del GDD §9 (grabada
   por la familia vs. TTS de relleno durante desarrollo) — se resuelve en HE-D5.

## Convención de carpetas y nombres

```text
assets/audio/voces/
├── guion_voces.md           # este documento
├── nucleo/                  # titulo, seleccion_personaje, mapa_estelar, zona_padres
├── cometa/                  # líneas genéricas de Cometa (ayudante flotante, HE-11)
├── celebraciones/           # líneas de celebración por hermano (HE-D5) — compartidas por
│                             # TODAS las escenas de historia y, a futuro, por los motores
│                             # de minijuego (una sola grabación por hermano, reutilizada)
├── recuerdos/                # líneas de Cometa del álbum "Las migas de papá" (HE-44)
├── emparejar/                # líneas del motor "emparejar" (contrato en su ficha)
├── <otro_motor>/              # una carpeta por motor de mecánica compartido (GDD §5)
└── historia/                  # cinemáticas y escenas de historia (HE-30, HE-39)
    ├── intro/                    # escena de intro (docs/guiones/escena_intro.md)
    ├── arcoiris/                  # escena de historia del Planeta Arcoíris (planeta 1)
    ├── <planeta_2..6>/            # una carpeta por planeta, cuando se escriba su guion
    └── prueba_final/               # prueba final cooperativa (docs/guiones/prueba_final_cooperativa.md)
```

Nombres de archivo en minúsculas, sin acentos, snake_case y numerados si hay variantes
(p. ej. `acierto_par_01.ogg`, `acierto_par_02.ogg`) para que el motor elija una al azar
y evite monotonía (ver `docs/fichas/motor-emparejar.md` §4/§7).

## Plantilla de tabla por escena/motor

Copiar esta tabla para cada escena o motor nuevo que necesite líneas de voz:

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo (`res://assets/audio/voces/...`) | estado |
|---|---|---|---|---|---|
| _ejemplo_intro | Cometa | Al entrar a la escena | _(pendiente de guion)_ | `nucleo/ejemplo_intro.ogg` | pendiente de guion |

## Líneas reales — Pantalla de título (`nucleo/`)

Primera pantalla del juego (HE-05, `escenas/nucleo/titulo.tscn`). Se repite sola cada
~12 s mientras nadie toca la pantalla, para que ningún niño dependa de leer "Toca para
comenzar" (GDD §6 regla 2). Voz de Cometa provisional en TTS hasta que P2 se grabe con
la familia (ver decisión arriba).

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| titulo_bienvenida_01 | Cometa | Al entrar a la pantalla de título y cada ~12 s de inactividad | «¡Toca la pantalla para comenzar la aventura!» | `nucleo/titulo_bienvenida_01.ogg` | pendiente de grabar |

## Líneas reales — Cometa genéricas (`cometa/`)

Líneas del ayudante flotante que no pertenecen a una escena de historia ni a un motor
específico: se usan en cualquier pantalla (tocar a Cometa repite la instrucción, GDD §6.2).

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| cometa_saludo_01 | Cometa | Primer toque del día / entrar a una pantalla nueva | «¡Hola de nuevo, Hermanos Estelares!» | `cometa/saludo_01.ogg` | pendiente de grabar |
| cometa_instruccion_generica_01 | Cometa | Al tocar a Cometa sin contexto de nivel (repite instrucción genérica) | «¿Necesitas ayuda? ¡Toca lo que brilla y mira qué pasa!» | `cometa/instruccion_generica_01.ogg` | pendiente de grabar |
| cometa_tumbo_01 | Cometa | Cada vez que Cometa hace una entrada/animación de tumbo cómico | «¡Uuuy, tumbo! Jijiji.» | `cometa/tumbo_01.ogg` | pendiente de grabar |
| cometa_animo_01 | Cometa | Tras un intento no exitoso, en niveles Brote/Estrella (nunca "error") | «¡Casi, casi! Otra vueltita más.» | `cometa/animo_01.ogg` | pendiente de grabar |
| cometa_animo_02 | Cometa | Variante de `cometa_animo_01` (el motor elige al azar) | «¡Uy, no era ese! Prueba de nuevo, tú puedes.» | `cometa/animo_02.ogg` | pendiente de grabar |
| cometa_celebracion_grupal_01 | Cometa | Al completar cualquier nivel/escena, dirigido a los tres hermanos | «¡Lo lograron los tres! ¡Increíble!» | `cometa/celebracion_grupal_01.ogg` | pendiente de grabar |
| cometa_despedida_01 | Cometa | Al salir de una pantalla/nivel hacia el mapa | «Nos vemos en el Mapa Estelar. ¡Vuelve cuando quieras!» | `cometa/despedida_01.ogg` | pendiente de grabar |

## Líneas reales — Celebraciones por hermano (`celebraciones/`)

Se disparan **junto con la animación del gesto de celebración canon** de cada hermano (GDD
§2 — nunca cambian, son "ellos mismos" ganando). Reutilizables en cualquier escena de
historia (ver `docs/guiones/escena_planeta_arcoiris.md` Beat 3 y
`docs/guiones/prueba_final_cooperativa.md` Beat 6) y, a futuro, en los motores de minijuego
como `victoria_final` cuando el nivel lo amerite.

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| celeb_maxi_01 | Maxi | Al ganar algo — junto al salto + puño arriba | «¡¡Siiii!!» | `celebraciones/celeb_maxi_01.ogg` | pendiente de grabar |
| celeb_maxi_02 | Maxi | Variante (el motor elige al azar) | «¡¡Ganeee!!» | `celebraciones/celeb_maxi_02.ogg` | pendiente de grabar |
| celeb_nicole_01 | Nicole | Al ganar algo — junto al corazón coreano | «¡Lo logramos!» | `celebraciones/celeb_nicole_01.ogg` | pendiente de grabar |
| celeb_nicole_02 | Nicole | Variante, tono más tierno | «¡Yay, qué lindo!» | `celebraciones/celeb_nicole_02.ogg` | pendiente de grabar |
| celeb_sofia_01 | Sofía | Al ganar algo — junto a mano en cintura, signo de la paz y guiño | «Nada mal, ¿eh?» | `celebraciones/celeb_sofia_01.ogg` | pendiente de grabar |
| celeb_sofia_02 | Sofía | Variante, tono más "misión cumplida" | «Misión cumplida, Hermanos Estelares.» | `celebraciones/celeb_sofia_02.ogg` | pendiente de grabar |

## Líneas reales — Escena de intro (`historia/intro/`)

Guion completo con acotaciones: `docs/guiones/escena_intro.md`. Tabla lista para grabar
(mismo id de línea que el guion, para trazabilidad):

> **Revisión 07-Ago-2026**: renumerada junto con `docs/guiones/escena_intro.md` (el guion
> reordenó la historia para que el secuestro de papá se vea en pantalla en vez de narrarse).
> Ninguna fila de esta tabla tenía audio grabado, así que la renumeración no afecta archivos ya
> entregados.

| id_línea | personaje | contexto (beat del guion) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| intro_001 | Sofía | Beat 1 — jugando en la alfombra | «Atención, tripulación... ¡el cojín gigante es un asteroide! Nadie lo toca.» | `historia/intro/intro_001.ogg` | pendiente de grabar |
| intro_002 | Maxi | Beat 1 | «¡Vrrrum! ¡Dino-auto!» | `historia/intro/intro_002.ogg` | pendiente de grabar |
| intro_003 | Nicole | Beat 1 | «Miren, le hice una coleta rosada a mi dibujo del caballito.» | `historia/intro/intro_003.ogg` | pendiente de grabar |
| intro_005 | El Coleccionauta | Beat 2 — aparece y se lleva a papá | «¡Ohhh, pero miren nada más... un papá sonriente, con chaqueta de piloto y todo! Increíble. Justo lo que me faltaba en la colección.» | `historia/intro/intro_005.ogg` | pendiente de grabar |
| intro_006 | Papá | Beat 2 | «¿Eh? Un momentito, ni siquiera alcancé a avisar que iba a...» | `historia/intro/intro_006.ogg` | pendiente de grabar |
| intro_008 | Sofía | Beat 2 | «¡¿Qué?! ¿Adónde se fue papá?» | `historia/intro/intro_008.ogg` | pendiente de grabar |
| intro_009 | Nicole | Beat 2 | «¿Se lo comió la lucecita brillante?» | `historia/intro/intro_009.ogg` | pendiente de grabar |
| intro_010 | Maxi | Beat 2 | «¡Uuuh, luuuces!» | `historia/intro/intro_010.ogg` | pendiente de grabar |
| intro_012 | Cometa | Beat 3 — llega persiguiendo al Coleccionauta | «¡Uuuy, tumbo! Jijiji... a ese aterrizaje le doy un 6 de 10.» | `historia/intro/intro_012.ogg` | pendiente de grabar |
| intro_013 | Cometa | Beat 3 | «Buuu, lo perdí por segunditos... ¡otra vez! Ese Coleccionauta corre rapidísimo cuando quiere.» | `historia/intro/intro_013.ogg` | pendiente de grabar |
| intro_014 | Maxi | Beat 3 | «¡Nave!!» | `historia/intro/intro_014.ogg` | pendiente de grabar |
| intro_015 | Nicole | Beat 3 | «¡Hola! ¿Estás bien, amiguito?» | `historia/intro/intro_015.ogg` | pendiente de grabar |
| intro_016 | Sofía | Beat 3 | «Un momento... ¿tú hablas? ¿Y por qué eres tan redondito? Y... ¿tú viste al que se llevó a mi papá?!» | `historia/intro/intro_016.ogg` | pendiente de grabar |
| intro_017 | Cometa | Beat 3 | «¡Redondito y orgulloso! Hola, Hermanos Estelares. Bueno... todavía no lo son, eso viene ahora. Y sí, lo vi: ese despistado es mi amigo, el Coleccionauta.» | `historia/intro/intro_017.ogg` | pendiente de grabar |
| intro_018 | Cometa | Beat 4 — cuenta quién es el Coleccionauta | «Lo conozco desde que éramos chicos —armamos naves juntos, en el mismo planeta— y anda coleccionando las cosas más increíbles del universo. Hoy le pareció que su papá era de lo más increíble que ha visto.» | `historia/intro/intro_018.ogg` | pendiente de grabar |
| intro_019 | Nicole | Beat 4 | «¿Y está bien? ¿No tiene frío ni nada?» | `historia/intro/intro_019.ogg` | pendiente de grabar |
| intro_020 | Cometa | Beat 4 | «¡Clarísimo que sí! El Coleccionauta es despistado y solitario, pero jamás malo. Seguro ya le ofreció una de sus galletas raras.» | `historia/intro/intro_020.ogg` | pendiente de grabar |
| intro_021 | Sofía | Beat 4 | «Entonces... hay que ir a buscarlo.» | `historia/intro/intro_021.ogg` | pendiente de grabar |
| intro_022 | Cometa | Beat 4 | «¡Esa actitud! Por eso vine a buscarlos a ustedes tres.» | `historia/intro/intro_022.ogg` | pendiente de grabar |
| intro_023 | Cometa | Beat 5 — trajes con estrellas de poder | «Para este viaje van a necesitar esto: sus trajes de Hermanos Estelares, con estrella de poder incluida.» | `historia/intro/intro_023.ogg` | pendiente de grabar |
| intro_024 | Maxi | Beat 5 | «¡¡Wiiii!!» | `historia/intro/intro_024.ogg` | pendiente de grabar |
| intro_025 | Nicole | Beat 5 | «¡Es rosado! ¡Es perfecto!» | `historia/intro/intro_025.ogg` | pendiente de grabar |
| intro_026 | Sofía | Beat 5 | «Turquesa y rosado... buen gusto, Cometa.» | `historia/intro/intro_026.ogg` | pendiente de grabar |
| intro_027 | Cometa | Beat 6 — la nave-estrella | «Y esta es nuestra nave-estrella. Quedó un poco averiada de tanto perseguir al Coleccionauta por la galaxia... por ahora solo le alcanza la energía para un saltito, el justo para llegar al primer planeta. ¡Las piezas que le faltan las conseguimos jugando!» | `historia/intro/intro_027.ogg` | pendiente de grabar |
| intro_028 | Sofía | Beat 6 | «¿Jugando? Me gusta cómo suena esa misión.» | `historia/intro/intro_028.ogg` | pendiente de grabar |
| intro_029 | Nicole | Beat 6 | «¡Voy a hacer amigos en cada planeta!» | `historia/intro/intro_029.ogg` | pendiente de grabar |
| intro_030 | Maxi | Beat 6 | «¡Vamo vamo vamo!» | `historia/intro/intro_030.ogg` | pendiente de grabar |
| intro_031 | Papá | Beat 7 — video-llamada | «¡Hola, mis campeones! Qué manera de salir de paseo sin avisar, ¿no? Miren dónde estoy... el Coleccionauta tiene una silla tan cómoda que casi ni quiero que me rescaten. Es broma, ¡los espero con muchas ganas!» | `historia/intro/intro_031.ogg` | pendiente de grabar |
| intro_032 | Papá | Beat 7 | «Eso sí, no se apuren por mí, yo estoy la mar de bien. Ustedes disfruten el viaje, ¿ya?» | `historia/intro/intro_032.ogg` | pendiente de grabar |
| intro_033 | Maxi | Beat 7 | «¡Papi!» | `historia/intro/intro_033.ogg` | pendiente de grabar |
| intro_034 | Nicole | Beat 7 | «¡Te extrañamos! ¡Ya vamos!» | `historia/intro/intro_034.ogg` | pendiente de grabar |
| intro_035 | Sofía | Beat 7 | «Aguanta ahí, papá. Vamos a hacerlo bien hecho.» | `historia/intro/intro_035.ogg` | pendiente de grabar |
| intro_036 | Papá | Beat 7 | «Sé que sí. Los quiero un montón. ¡Nos vemos, Hermanos Estelares!» | `historia/intro/intro_036.ogg` | pendiente de grabar |
| intro_037 | Cometa | Beat 8 — partida al mapa | «¿Listos para volar, Hermanos Estelares?» | `historia/intro/intro_037.ogg` | pendiente de grabar |
| intro_038 | Maxi+Nicole+Sofía | Beat 8 | «¡¡Siiiií!!» (coro) | `historia/intro/intro_038.ogg` | pendiente de grabar |

*(sfx `intro_004`, `intro_007` y `intro_011` no llevan voz — son sonidos de destello mágico y de
cortina + trompo, ver ficha de audio/SFX, no este documento.)*

## Líneas reales — Escena del Planeta Arcoíris (`historia/arcoiris/`)

Guion completo con acotaciones: `docs/guiones/escena_planeta_arcoiris.md`. Las líneas de
celebración de Beat 3 son las genéricas de `celebraciones/` (no se repiten aquí).

| id_línea | personaje | contexto (beat del guion) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| arcoiris_001 | Coco | Beat 1 — agradece y celebra | «¡Uy, uy, uy, miren nada más! Rojo, amarillo y azul... ¡volvieron los tres primeros colores de mi planeta! Ahora soy... ¡color FELIZ!» *(reescrita 28-Sep-2026, HE-40)* | `historia/arcoiris/arcoiris_001.ogg` | pendiente de grabar |
| arcoiris_002 | Cometa | Beat 1 | «Coco, ¡lo lograron los tres, cada uno jugando a su manera!» | `historia/arcoiris/arcoiris_002.ogg` | pendiente de grabar |
| arcoiris_003 | Nicole | Beat 1 | «¡Pinté un charco entero de rosado, Coco! Como tú.» | `historia/arcoiris/arcoiris_003.ogg` | pendiente de grabar |
| arcoiris_004 | Coco | Beat 1 | «¡El rosado me queda regio! Miren... ahora soy... ¡rosado chicle!» | `historia/arcoiris/arcoiris_004.ogg` | pendiente de grabar |
| arcoiris_005 | Sofía | Beat 1 | «Y yo até el azul con el amarillo. Salió verde. Química de planeta, nada mal.» | `historia/arcoiris/arcoiris_005.ogg` | pendiente de grabar |
| arcoiris_006 | Maxi | Beat 1 | «¡Yo toqué TODO!» | `historia/arcoiris/arcoiris_006.ogg` | pendiente de grabar |
| arcoiris_007 | Coco | Beat 1 | «Tocaste todo... ¡y todo brilló! Así se juega en mi planeta, chiquitín.» | `historia/arcoiris/arcoiris_007.ogg` | pendiente de grabar |
| arcoiris_008 | Coco | Beat 2 — entrega de la pieza | «Esto es para su nave. El ala del Arcoíris... la pinté yo misma, con los colores que ustedes me devolvieron.» *(reescrita 28-Sep-2026, HE-40)* | `historia/arcoiris/arcoiris_008.ogg` | pendiente de grabar |
| arcoiris_009 | Cometa | Beat 2 | «¡La primera pieza! Miren cómo le queda a la nave.» | `historia/arcoiris/arcoiris_009.ogg` | pendiente de grabar |
| arcoiris_010 | Cometa | Beat 4 — video-llamada | «¡Sorpresa! Alguien quiere saludarlos.» | `historia/arcoiris/arcoiris_010.ogg` | pendiente de grabar |
| arcoiris_011 | Papá | Beat 4 | «¡Hermanos Estelares! Me contaron que ya tienen su primera pieza. ¡Una ala! Con esa y la otra, casi puedo volar yo también... si el Coleccionauta me presta sus lentes de lupa.» | `historia/arcoiris/arcoiris_011.ogg` | pendiente de grabar |
| arcoiris_012 | Papá | Beat 4 | «¿Vieron colores nuevos? Cuéntenme todos cuando nos veamos. Mientras tanto, sigan jugando tranquilos, que acá estoy la mar de bien.» | `historia/arcoiris/arcoiris_012.ogg` | pendiente de grabar |
| arcoiris_013 | Nicole | Beat 4 | «¡Papi, mezclamos azul con amarillo y salió verde!» | `historia/arcoiris/arcoiris_013.ogg` | pendiente de grabar |
| arcoiris_014 | Maxi | Beat 4 | «¡Toqué TODO, papi!» | `historia/arcoiris/arcoiris_014.ogg` | pendiente de grabar |
| arcoiris_015 | Sofía | Beat 4 | «Vamos por la segunda pieza. No te aburras mucho allá.» | `historia/arcoiris/arcoiris_015.ogg` | pendiente de grabar |
| arcoiris_016 | Papá | Beat 4 | «¿Yo, aburrido? Imposible, aquí el Coleccionauta me está enseñando a doblar servilletas en forma de pato. Los quiero, ¡nos vemos pronto!» | `historia/arcoiris/arcoiris_016.ogg` | pendiente de grabar |
| arcoiris_017 | Coco | Beat 5 — cierre y gancho | «Vuelvan cuando quieran, ¡mi arcoíris siempre los espera! Y en los Islotes Flotantes todavía hay colores escondidos...» *(reescrita 28-Sep-2026, HE-40)* | `historia/arcoiris/arcoiris_017.ogg` | pendiente de grabar |
| arcoiris_018 | Cometa | Beat 5 | «Vamos, Hermanos Estelares... el siguiente planeta nos espera, brillando allá lejos.» | `historia/arcoiris/arcoiris_018.ogg` | pendiente de grabar |

## Líneas reales — Prueba final cooperativa (`historia/prueba_final/`)

Guion completo con acotaciones: `docs/guiones/prueba_final_cooperativa.md`. Es la tabla más
larga porque cubre cinemática + el minijuego cooperativo en sí (Beats 3-5). Las líneas de
celebración de Beat 6 son las genéricas de `celebraciones/` (no se repiten aquí).

| id_línea | personaje | contexto (beat del guion) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| final_001 | Coleccionauta | Beat 1 — llegada | «¡Bienvenidos a la colección más increíble, asombrosa, fabulosa de tooooda la... espera, ¿dónde dejé mis anteojos-lupa? Ah. Los tengo puestos.» | `historia/prueba_final/final_001.ogg` | pendiente de grabar |
| final_002 | Cometa | Beat 1 | «¡Hola, viejo amigo! Te presento a los Hermanos Estelares.» | `historia/prueba_final/final_002.ogg` | pendiente de grabar |
| final_003 | Coleccionauta | Beat 1 | «¡Cometa! Cuánto tiempo... ¿todavía coleccionas amigos en vez de cosas? Qué raro eres.» | `historia/prueba_final/final_003.ogg` | pendiente de grabar |
| final_004 | Sofía | Beat 1 | «Venimos por nuestro papá.» | `historia/prueba_final/final_004.ogg` | pendiente de grabar |
| final_005 | Coleccionauta | Beat 1 | «¡Ah, sí! El papá más increíble que encontré en años. Está por acá, muy cómodo.» | `historia/prueba_final/final_005.ogg` | pendiente de grabar |
| final_006 | Papá | Beat 1 | «¡Hola, mis amores! Miren, me hicieron mi propio rincón. Hasta tiene wifi... es broma, no hay wifi, por eso los extraño tanto.» | `historia/prueba_final/final_006.ogg` | pendiente de grabar |
| final_007 | Maxi | Beat 1 | «¡Papi!» | `historia/prueba_final/final_007.ogg` | pendiente de grabar |
| final_008 | Papá | Beat 1 | «¡Mi campeón! Oye, ¿ya aprendiste a saltar más alto?» | `historia/prueba_final/final_008.ogg` | pendiente de grabar |
| final_009 | Coleccionauta | Beat 2 — explica la prueba | «Para llevarse lo más increíble de mi colección, deben superar... ¡LA PRUEBA MÁS DIFÍCIL DEL UNIVERSO CONOCIDO! O bueno... es más o menos mediana. Le puse mucha purpurina, eso sí.» | `historia/prueba_final/final_009.ogg` | pendiente de grabar |
| final_010 | Cometa | Beat 2 | «Tranquilos, chiquillos, esto es puro juego. Nada de qué preocuparse.» | `historia/prueba_final/final_010.ogg` | pendiente de grabar |
| final_011 | Coleccionauta | Beat 2 | «Solo tienen que... ordenar mi colección. Nada más. Ah, y encontrar mis llaves. Y quizás hacerme un amigo. Bueno, son tres cositas.» | `historia/prueba_final/final_011.ogg` | pendiente de grabar |
| final_012 | Sofía | Beat 3 — primer intento (fracaso cómico) | «Yo leo las instrucciones primero, esperen—» | `historia/prueba_final/final_012.ogg` | pendiente de grabar |
| final_013 | Nicole | Beat 3 | «¡Ya hice tres amigos nuevos aquí adentro!» | `historia/prueba_final/final_013.ogg` | pendiente de grabar |
| final_014 | Maxi | Beat 3 | «¡¡Encontré algo!!» | `historia/prueba_final/final_014.ogg` | pendiente de grabar |
| final_015 | Sofía | Beat 3 | «¡Maxi, espera, se va a caer la—!» | `historia/prueba_final/final_015.ogg` | pendiente de grabar |
| final_017 | Coleccionauta | Beat 3 | «¡Jajaja, eso fue lo más divertido que he visto en años! Pero... siguen sin encontrar mis llaves.» | `historia/prueba_final/final_017.ogg` | pendiente de grabar |
| final_018 | Nicole | Beat 3 | «¡Uy, perdón, perdón!» | `historia/prueba_final/final_018.ogg` | pendiente de grabar |
| final_019 | Sofía | Beat 3 | «Ok, eso... no funcionó.» | `historia/prueba_final/final_019.ogg` | pendiente de grabar |
| final_020 | Cometa | Beat 4 — Cometa señala el camino | «¿Y si probamos... juntos? Cada uno hace lo que mejor sabe hacer, pero esta vez, de a uno.» | `historia/prueba_final/final_020.ogg` | pendiente de grabar |
| final_021 | Sofía | Beat 4 | «...Yo puedo leer el plan primero.» | `historia/prueba_final/final_021.ogg` | pendiente de grabar |
| final_022 | Nicole | Beat 4 | «¡Y yo puedo preguntarle a nuestro amigo dónde deja las cosas!» | `historia/prueba_final/final_022.ogg` | pendiente de grabar |
| final_023 | Maxi | Beat 4 | «¡Yo encuentro!» | `historia/prueba_final/final_023.ogg` | pendiente de grabar |
| final_024 | Coleccionauta | Beat 4 | «¿Amigo? ¿Yo?» | `historia/prueba_final/final_024.ogg` | pendiente de grabar |
| final_025 | Sofía | Beat 5a — lidera y lee la pista | «Dice acá: "las llaves están donde nadie mira dos veces". Maxi, eso es para ti.» | `historia/prueba_final/final_025.ogg` | pendiente de grabar |
| final_026 | Nicole | Beat 5b — se hace amiga del Coleccionauta | «Toma, es para ti. Te dibujé a ti y a Cometa de amigos, como antes.» | `historia/prueba_final/final_026.ogg` | pendiente de grabar |
| final_027 | Coleccionauta | Beat 5b | «¿Para... para mí? Nadie me había regalado algo así. Solo coleccionan cosas conmigo, nunca me regalan nada.» | `historia/prueba_final/final_027.ogg` | pendiente de grabar |
| final_028 | Nicole | Beat 5b | «Es que los amigos no se juntan, ¡se hacen regalando cositas y jugando!» | `historia/prueba_final/final_028.ogg` | pendiente de grabar |
| final_029 | Coleccionauta | Beat 5b | «...Me gusta mucho ser tu amigo.» | `historia/prueba_final/final_029.ogg` | pendiente de grabar |
| final_030 | Maxi | Beat 5c — encuentra lo que nadie ve | «¡¡Llaves!!» | `historia/prueba_final/final_030.ogg` | pendiente de grabar |
| final_031 | Coleccionauta | Beat 5c | «¡Mis llaves! ¡Las buscaba desde hace... mucho, mucho tiempo!» | `historia/prueba_final/final_031.ogg` | pendiente de grabar |
| final_032 | Sofía | Beat 5c | «Equipo Estelares, ¡funcionó!» | `historia/prueba_final/final_032.ogg` | pendiente de grabar |
| final_033 | Papá | Beat 6 — rescate | «¡Al fin! Aunque las galletas de acá estaban riquísimas, así que no hay apuro.» | `historia/prueba_final/final_033.ogg` | pendiente de grabar |
| final_035 | Papá | Beat 6 | «Estoy tan orgulloso de ustedes tres. Trabajar en equipo... eso sí que es increíble.» | `historia/prueba_final/final_035.ogg` | pendiente de grabar |
| final_036 | Coleccionauta | Beat 7 — se une a la familia | «Oigan... ¿puedo ir a visitarlos? Prometo no traer TODA mi colección. Bueno, un poquito.» | `historia/prueba_final/final_036.ogg` | pendiente de grabar |
| final_037 | Nicole | Beat 7 | «¡Claro que sí! Ya eres nuestro amigo.» | `historia/prueba_final/final_037.ogg` | pendiente de grabar |
| final_038 | Cometa | Beat 7 | «Se los dije... los amigos son la mejor colección.» | `historia/prueba_final/final_038.ogg` | pendiente de grabar |
| final_039 | Papá | Beat 8 — vuelta a casa | «¡Hola, mis campeones! ¿Jugando a los astronautas de nuevo?» | `historia/prueba_final/final_039.ogg` | pendiente de grabar |
| final_040 | Sofía | Beat 8 | «Algo así. Rescatamos a alguien muy importante.» | `historia/prueba_final/final_040.ogg` | pendiente de grabar |
| final_041 | Papá | Beat 8 | «¿A quién?» | `historia/prueba_final/final_041.ogg` | pendiente de grabar |
| final_042 | Maxi | Beat 8 | «¡A ti!» | `historia/prueba_final/final_042.ogg` | pendiente de grabar |
| final_043 | Papá | Beat 8 | «Ah, con que a mí. Bueno, gracias por el rescate. ¿Vamos a comer?» | `historia/prueba_final/final_043.ogg` | pendiente de grabar |
| final_044 | Maxi+Nicole+Sofía | Beat 8 | «¡Siiií!» (coro) | `historia/prueba_final/final_044.ogg` | pendiente de grabar |

*(sfx `final_016` no lleva voz — estornudo de nave + objetos cayendo; ficha de SFX, no este
documento.)*

## Líneas reales — Las migas de papá: álbum de recuerdos (`recuerdos/`)

Guion completo con acotaciones, decisiones de tono y observaciones: `docs/guiones/recuerdos.md`
(HE-44, validación de diseño del `guionista`, 27-Sep-2026; revisión 28-Sep-2026 con la entrega tras el
regalo del anfitrión, las pistas de zona reescritas y los pies de foto). Ficha de la épica:
`docs/fichas/album-recuerdos.md`. Son 77 líneas de Cometa. **28-Sep-2026**: todas tienen audio de
RELLENO con el TTS de Windows (sin costo; `assets/audio/voces/recuerdos/lineas_tts.tsv`, generado con
`generar_voces_tts.ps1 -IgnorarPersonaje`) y están en `pendientes_fal.txt`: se regeneran con la voz
oficial de Cometa cuando el PO apruebe el costo.

Los audios **de cada foto** (grabados por la familia) no van en esta tabla: viven en
`assets/recuerdos/voces/<id_foto>.ogg`, fuera del repo (ficha §8). La guía para grabarlos está en
`docs/guiones/recuerdos.md` §6. El esbozo del final (`final_rec_01..03`) tiene ids provisionales y
se agrega aquí cuando HE-39 lo cierre.

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| recuerdos_primera_01 | Cometa | Primera foto (`familia_01`): al aparecer el sobre. Se recomienda al final de la intro, ver guion, Observación 1 | «¡Miren lo que quedó en la alfombra! Papá se rió tanto con las cosquillas del rayo del Coleccionauta, que ¡pffft!, se le volaron todas las fotos de la billetera.» | `recuerdos/primera_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_primera_02 | Cometa | Primera foto: cuando la foto ya voló al ícono del álbum | «Las demás andan flotando por la galaxia. ¡Las vamos a ir encontrando en el camino, y se las mostramos a papá cuando lo veamos!» | `recuerdos/primera_02.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_entrega_01 | Cometa | Entrega de una foto, antes de abrir el sobre (el motor elige al azar entre 01-04) | «¡Mira! ¡Otra foto de la billetera de papá!» | `recuerdos/entrega_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_entrega_02 | Cometa | Variante de `recuerdos_entrega_01` | «¡Uuuh, una estrella-recuerdo! ¿Quién saldrá en esta foto?» | `recuerdos/entrega_02.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_entrega_03 | Cometa | Variante de `recuerdos_entrega_01` | «¡Plin! Otra fotito que se le voló a papá. ¡Ábrela, ábrela!» | `recuerdos/entrega_03.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_entrega_04 | Cometa | Variante de `recuerdos_entrega_01` | «¡Miren quién sale aquí! Una foto más para el álbum.» | `recuerdos/entrega_04.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_generica_01 | Cometa | Foto abierta sin audio de la familia en disco (relleno, ficha §8) | «¡Qué foto más linda! Esta va directo al álbum.» | `recuerdos/generica_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_generica_02 | Cometa | Variante de `recuerdos_generica_01` | «¡Mira qué caritas! Un recuerdo calentito, calentito.» | `recuerdos/generica_02.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_dorado_01 | Cometa | La foto de una zona gana el marco dorado (estrellitas máximas, solo Sofía) | «¡Marco dorado! Esta foto es de nivel... ¡Estrella!» | `recuerdos/dorado_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_familiar_maxi_01 | Cometa | Maxi desbloquea una foto del álbum familiar (reemplaza a `entrega_0X`) | «¡Maxi encontró una foto de la familia! ¡Y es para los tres!» | `recuerdos/familiar_maxi_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_familiar_nicole_01 | Cometa | Nicole desbloquea una foto del álbum familiar | «¡Nicole encontró una foto de la familia! ¡Y es para los tres!» | `recuerdos/familiar_nicole_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_familiar_sofia_01 | Cometa | Sofía desbloquea una foto del álbum familiar | «¡Sofía encontró una foto de la familia! ¡Y es para los tres!» | `recuerdos/familiar_sofia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_album_nueva_01 | Cometa | Título/selección con fotos sin ver: una vez al entrar, con el brillo del botón | «¡Psst! Hay una foto nueva esperando en el álbum.» | `recuerdos/album_nueva_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_album_invitacion_01 | Cometa | Al abrir el álbum (portada con las 4 tapas) | «¡El álbum de las fotos de papá! Toca una tapa y vamos a mirar.» | `recuerdos/album_invitacion_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_tapa_maxi_01 | Cometa | Al tocar la tapa de Maxi | «¡El álbum de Maxi! De chiquitito... ¡a grandote!» | `recuerdos/tapa_maxi_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_tapa_nicole_01 | Cometa | Al tocar la tapa de Nicole | «¡El álbum de Nicole! Cuidado, que aquí hay sonrisas por todos lados.» | `recuerdos/tapa_nicole_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_tapa_sofia_01 | Cometa | Al tocar la tapa de Sofía | «¡El álbum de Sofía! La capitana... desde que era una capitanita.» | `recuerdos/tapa_sofia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_tapa_familia_01 | Cometa | Al tocar la tapa Familia | «¡El álbum de la familia! Aquí caben todos... ¡bien apretaditos!» | `recuerdos/tapa_familia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_album_vacio_01 | Cometa | Al abrir un álbum sin ninguna foto | «Este álbum está esperando sus fotos. ¡Van a ir llegando solitas mientras juegan!» | `recuerdos/album_vacio_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_viaje_despegue_01 | Cometa | Tocar un hueco con momento `viaje` / `primer_despegue` | «Esta foto anda flotando en el primer viaje de la nave. ¡Ya la vamos a ver pasar!» | `recuerdos/pista_viaje_despegue_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_viaje_final_01 | Cometa | Tocar un hueco con momento `viaje` al planeta final | «Esta foto anda flotando en el viaje al planeta del Coleccionauta. ¡Ya la vamos a ver pasar!» | `recuerdos/pista_viaje_final_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_arcoiris_charcos_01 | Cometa | Tocar un hueco `zona_completa` Arcoíris, zona 2 | «Esta foto está escondida en los Charcos Saltarines del Planeta Arcoíris. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_arcoiris_charcos_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_arcoiris_islotes_01 | Cometa | Tocar un hueco `zona_completa` Arcoíris, zona 4 | «Esta foto está escondida en los Islotes Flotantes del Planeta Arcoíris. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_arcoiris_islotes_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_arcoiris_01 | Cometa | Hueco `zona_completa` Arcoíris, respaldo si cambia el reparto de zonas | «Esta foto está escondida en el Planeta Arcoíris. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_arcoiris_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_animalia_01 | Cometa | Hueco `zona_completa` Animalia (cuando el planeta tenga zonas) | «Esta foto está escondida en el Planeta Animalia. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_animalia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_melodia_01 | Cometa | Hueco `zona_completa` Melodía | «Esta foto está escondida en el Planeta Melodía. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_melodia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_cuentacuentas_01 | Cometa | Hueco `zona_completa` Cuenta-Cuentas | «Esta foto está escondida en el Planeta Cuenta-Cuentas. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_cuentacuentas_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_letralandia_01 | Cometa | Hueco `zona_completa` Letralandia | «Esta foto está escondida en el Planeta Letralandia. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_letralandia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_zona_corazon_01 | Cometa | Hueco `zona_completa` Corazón | «Esta foto está escondida en el Planeta Corazón. ¡Aparece solita cuando juegues todos los juegos de ahí!» | `recuerdos/pista_zona_corazon_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_pieza_arcoiris_01 | Cometa | Hueco `pieza_nave` Arcoíris | «Esta foto la guarda Coco, en el Planeta Arcoíris. ¡Llega junto con la pieza de la nave!» | `recuerdos/pista_pieza_arcoiris_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_pieza_animalia_01 | Cometa | Hueco `pieza_nave` Animalia | «Esta foto la guarda Toby, en el Planeta Animalia. ¡Llega junto con la pieza de la nave!» | `recuerdos/pista_pieza_animalia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_pieza_melodia_01 | Cometa | Hueco `pieza_nave` Melodía | «Esta foto la guarda Octavio, en el Planeta Melodía. ¡Llega junto con la pieza de la nave!» | `recuerdos/pista_pieza_melodia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_pieza_cuentacuentas_01 | Cometa | Hueco `pieza_nave` Cuenta-Cuentas | «Esta foto la guarda el Profesor Plumas, en el Planeta Cuenta-Cuentas. ¡Llega junto con la pieza de la nave!» | `recuerdos/pista_pieza_cuentacuentas_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_pieza_letralandia_01 | Cometa | Hueco `pieza_nave` Letralandia | «Esta foto la guarda Lila, en el Planeta Letralandia. ¡Llega junto con la pieza de la nave!» | `recuerdos/pista_pieza_letralandia_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_pieza_corazon_01 | Cometa | Hueco `pieza_nave` Corazón | «Esta foto la guarda Mimi, en el Planeta Corazón. ¡Llega junto con la pieza de la nave!» | `recuerdos/pista_pieza_corazon_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pista_rescate_01 | Cometa | Hueco `rescate_final` | «Esta es la última foto. ¡La guardamos para el final, cuando estemos todos juntos!» | `recuerdos/pista_rescate_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_burbuja_aviso_01 | Cometa | Viaje estelar: aparece la burbuja-recuerdo | «¡Mira, una burbuja-recuerdo! ¡Tócala o chócala con la nave!» | `recuerdos/burbuja_aviso_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_burbuja_aviso_02 | Cometa | Variante de `recuerdos_burbuja_aviso_01` | «¡Ahí viene una foto flotando! ¡Atrápala!» | `recuerdos/burbuja_aviso_02.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_burbuja_atrapada_01 | Cometa | Al atrapar la burbuja, antes del sobre-estrella | «¡Plop! ¡La atrapaste! Otra foto para el álbum.» | `recuerdos/burbuja_atrapada_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_burbuja_atrapada_02 | Cometa | Variante de `recuerdos_burbuja_atrapada_01` | «¡Burbuja reventada, foto encontrada!» | `recuerdos/burbuja_atrapada_02.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_burbuja_vuelve_01 | Cometa | La burbuja sale de la pantalla sin que la atrapen | «¡Uy, se fue dando botes! Tranqui, ya vuelve a pasar.» | `recuerdos/burbuja_vuelve_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_entrega_zona_01 | Cometa | Foto al completar una zona, tras el regalo del anfitrión (guion §1.2b); reemplaza a `entrega_0X` | «¡Y eso no es todo! El viento trajo algo más... ¡una foto de papá!» | `recuerdos/entrega_zona_01.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_entrega_zona_02 | Cometa | Foto al completar una zona, tras el regalo del anfitrión (guion §1.2b); reemplaza a `entrega_0X` | «¡Esperen, esperen! ¡Viene bajando una estrella-recuerdo!» | `recuerdos/entrega_zona_02.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_recien_nacido | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Aquí recién llegaba al mundo!» | `recuerdos/pie_recien_nacido.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_1_mes | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía un mesecito.» | `recuerdos/pie_1_mes.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_3_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía tres mesecitos.» | `recuerdos/pie_3_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_5_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía cinco meses.» | `recuerdos/pie_5_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_6_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía seis meses. ¡Medio añito!» | `recuerdos/pie_6_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_8_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía ocho meses.» | `recuerdos/pie_8_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_9_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía nueve meses.» | `recuerdos/pie_9_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_10_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía diez meses.» | `recuerdos/pie_10_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_1_ano | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Aquí tenía un añito!» | `recuerdos/pie_1_ano.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_1_ano_3_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía un año... y un poquito.» | `recuerdos/pie_1_ano_3_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_1_ano_6_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía un año y medio.» | `recuerdos/pie_1_ano_6_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_1_ano_9_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Aquí tenía casi dos años!» | `recuerdos/pie_1_ano_9_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_2_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía dos años.» | `recuerdos/pie_2_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_2_anos_6_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía dos años y medio.» | `recuerdos/pie_2_anos_6_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_3_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía tres años.» | `recuerdos/pie_3_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_3_anos_6_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía tres años y medio.» | `recuerdos/pie_3_anos_6_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_4_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía cuatro años.» | `recuerdos/pie_4_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_4_anos_6_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía cuatro años y medio.» | `recuerdos/pie_4_anos_6_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_5_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía cinco años.» | `recuerdos/pie_5_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_6_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía seis años.» | `recuerdos/pie_6_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_6_anos_6_meses | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía seis años y medio.» | `recuerdos/pie_6_anos_6_meses.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_7_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía siete años.» | `recuerdos/pie_7_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_8_anos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «Aquí tenía ocho años.» | `recuerdos/pie_8_anos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_hoy | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Y esta foto es de ahora, ahora!» | `recuerdos/pie_hoy.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_billetera | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡La foto de la billetera de papá! Los cinco, juntitos.» | `recuerdos/pie_familia_billetera.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_mama_papa_guagua | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Mamá y papá con una guagua chiquitita! ¿Adivinan quién es?» | `recuerdos/pie_familia_mama_papa_guagua.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_hermanos_primera_vez | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Los tres hermanos juntos, por primera vez!» | `recuerdos/pie_familia_hermanos_primera_vez.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_paseo | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡De paseo en familia!» | `recuerdos/pie_familia_paseo.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_cumpleanos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Un cumpleaños en familia! ¿Cuántas velitas había?» | `recuerdos/pie_familia_cumpleanos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_vacaciones_chile | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡De vacaciones por Chile!» | `recuerdos/pie_familia_vacaciones_chile.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_navidad | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Navidad en familia!» | `recuerdos/pie_familia_navidad.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_dieciocho | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Celebrando el Dieciocho! ¡Viva Chile!» | `recuerdos/pie_familia_dieciocho.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_hermanos_hoy | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Los tres hermanos... así de grandes hoy!» | `recuerdos/pie_familia_hermanos_hoy.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |
| recuerdos_pie_familia_todos_juntos | Cometa | Pie de foto narrado antes del audio de la familia (guion §8; campo `pie` del catálogo; no suena si `pie_en_audio`) | «¡Todos juntos! Esta es la foto más nueva de todas.» | `recuerdos/pie_familia_todos_juntos.wav` | relleno TTS Windows (28-Sep); pendiente voz oficial |

## Líneas del mapa por zonas y retoques de voces (HE-40, 28-Sep-2026)

Las voces nuevas y reescritas de `docs/guiones/zonas_arcoiris.md` (mapa por zona, regalos de Coco, zona
dormida, estación repetida, taller de Sofía, intros de Parejas de Maxi z2 y Nicole z3, pistas del Taller,
corona de Nicole, intro de Formas de Sofía, "violeta" en Pinta, bandera de Chile) viven en los
`lineas_tts.tsv` de cada carpeta, con su directiva `# personaje:`. Las nuevas y las reescritas urgentes
(corona, zona dormida, intros de Formas de Sofía, tríos) ya suenan con relleno de Windows; las reescrituras de
tono de líneas que ya tenían la voz oficial (llegada y completada de zona, lugar secreto) conservan su
audio oficial hasta regenerarse. Todas están en `pendientes_fal.txt`. Se agregaron además seis líneas que
`dev-godot` escribió sin guion el 28-Sep. El guionista las revisó el 02-Oct-2026 y quedaron con texto
definitivo (tabla siguiente y `docs/guiones/zonas_arcoiris.md` §7).

### Textos de `dev-godot` revisados y voz "¿me lo muestras?" de Maxi (guionista, 02-Oct-2026)

Los `.wav` de las seis reescritas son relleno de Windows con el **texto viejo**: hay que regenerarlos. Las
tres de Pinta todavía no tienen archivo. `me_lo_muestras_auto` es opcional: solo se usa si la mecánica
auto-muestra la hoja.

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo | estado |
|---|---|---|---|---|---|
| arcoiris_mapa_dorado_entrar | Coco | Sofía entra a un reto dorado del mapa. Emocionada, con pausa antes de "dorada" (tic) | «¡Entramos al reto dorado! Ahora soy... ¡dorada de la emoción! ¡Vamos, campeona!» | `arcoiris/mapa/dorado_entrar.wav` | texto definitivo; relleno Windows con texto viejo, regenerar |
| arcoiris_formas_estrella_intro_bandera_primero | Coco | Formas de Sofía: ronda de bandera antes del monumento. Ligera, de juego | «¡Sofía, primero una bandera, para calentar los dedos! Cada pieza va en su color. Si una llega chueca, tócala para girarla.» | `arcoiris/formas/estrella/intro_bandera_primero.wav` | texto definitivo; relleno Windows con texto viejo, regenerar |
| arcoiris_mezclar_escupe_01 | Coco | Taller: el frasco escupe la 1.ª gota equivocada y las capas buenas se quedan. Con risa | «¡Ptui! Al frasco no le gustó esa gotita. ¡Las demás se quedan!» | `arcoiris/mezclar/escupe_01.wav` | texto definitivo; relleno Windows con texto viejo, regenerar |
| arcoiris_mezclar_escupe_02 | Coco | Variante de `escupe`. Divertida, tranquilizando al final | «¡Ups! El frasco hizo ptui y la escupió. Tu mezcla sigue a salvo.» | `arcoiris/mezclar/escupe_02.wav` | texto definitivo; relleno Windows con texto viejo, regenerar |
| nucleo_pista_confirmar | Cometa | 1.er toque al botón de pista: se abre el globo, que aún no cobra. En secreto, pícaro | «¿Te soplo una pista? Cuesta una estrellita. ¡Toca el globito si la quieres!» | `nucleo/pista_confirmar.wav` | texto definitivo; relleno Windows con texto viejo, regenerar |
| nucleo_pista_gratis | Cometa | Pista con una sola estrellita en el medidor: gratis y directa. Generoso | «¡Esta pista va de regalo! Mira, mira...» | `nucleo/pista_gratis.wav` | texto definitivo; relleno Windows con texto viejo, regenerar |
| arcoiris_pinta_semilla_me_lo_muestras_01 | Coco | Pinta de Maxi: ~90 s sin tocar "mostrar a Coco"; el botón late. Curiosa, lenta | «¡Maxi! ¿Me lo muestras? ¡Toca mi carita!» | `arcoiris/pinta/semilla/me_lo_muestras_01.wav` | nueva; sin audio |
| arcoiris_pinta_semilla_me_lo_muestras_02 | Coco | Variante de la anterior (al azar). Maravillada | «¡Ooh, qué colores! ¿Me lo muestras, Maxi? ¡Toca mi carita!» | `arcoiris/pinta/semilla/me_lo_muestras_02.wav` | nueva; sin audio |
| arcoiris_pinta_semilla_me_lo_muestras_auto | Coco | Opcional: la hoja se muestra sola tras otro rato largo sin tocar; después suena `mostrar_0X`. Con risa | «¡Ay, no aguanto la curiosidad! ¡A ver, a ver tu dibujo!» | `arcoiris/pinta/semilla/me_lo_muestras_auto.wav` | nueva (opcional); sin audio |

## Claves estándar ya asumidas por el motor "emparejar" (piloto, 18-Jul-2026)

El contrato de nivel del motor "emparejar" (`docs/fichas/motor-emparejar.md` §4) ya
espera estas claves dentro de `lineas_voz` de cada archivo de nivel en `datos/`. Sirven
de referencia para que cualquier motor nuevo defina las suyas con el mismo patrón:

| clave | cuándo suena | admite variantes (array) |
|---|---|---|
| `intro` | Al entrar al nivel, antes de jugar | No |
| `pista` | Al tocar a Cometa, o tras varios intentos sin acierto (Brote/Estrella) | No |
| `acierto_par` | Al completar un par correctamente | Sí |
| `no_es_este` | Al tocar dos elementos que no forman par (feedback amistoso, nunca "error") | Sí |
| `victoria_final` | Al completar el nivel entero | No |
| `derrota_gag` | Al disparar la derrota-gag (solo Brote/Estrella con `limite_intentos`) | No |

## Pendiente

- [x] Guion narrativo completo y primera versión de contenido real (HE-D5, `guionista`) —
      intro, Planeta Arcoíris (planeta 1, completo) y prueba final cooperativa; ver
      `docs/guiones/`.
- [x] Recomendación de P2 del GDD §9 (grabar voces de la familia vs. TTS) — ver sección
      arriba; **pendiente de confirmación final del PO** (componente de logística real).
- [ ] Guion definitivo (diálogo, no solo plantilla) de las escenas de historia de los
      planetas 2-6 — se escribe cuando se aborde la tarjeta de contenido de cada uno, usando
      `docs/guiones/plantilla_escena_planeta.md`.
- [ ] Grabación real de todas las líneas listadas arriba (estado `pendiente de grabar` →
      `grabada`) — depende de la confirmación de P2 y de coordinar sesiones con la familia.
- [ ] Una tabla de líneas por cada motor de mecánica a medida que se implementan (HE-05, 06,
      08, 11, 14-16...).
- [ ] Diseño de UI/flujo de turnos del modo misión familiar para la prueba final cooperativa
      (parte de P6 aún abierta — el guion narrativo de la prueba ya está resuelto en
      `docs/guiones/prueba_final_cooperativa.md`, falta la mecánica de turnos en pantalla).
