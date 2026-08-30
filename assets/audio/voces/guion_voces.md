# Guion de voces — Los Hermanos Estelares

> **Primera versión de contenido real (HE-D5)**: este documento ya no es solo el esqueleto
> de HE-04 — incluye las primeras tablas de líneas reales, derivadas del guion narrativo
> completo en `docs/guiones/` (escena de intro, escena del Planeta Arcoíris, líneas
> genéricas de Cometa y celebraciones por hermano). Las escenas de los planetas 2-6 y el
> detalle fino de otros motores se agregan a medida que se aborden sus tarjetas (ver
> `docs/guiones/plantilla_escena_planeta.md`). `Audio.reproducir_voz()` sigue sin romper el
> juego si el archivo `.ogg` falta, solo deja un aviso en consola (`push_warning`).

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
| arcoiris_001 | Coco | Beat 1 — agradece y celebra | «¡Uy, uy, uy, miren nada más! Terminaron todo mi arcoíris del claro. ¡Ahora soy... color FELIZ!» | `historia/arcoiris/arcoiris_001.ogg` | pendiente de grabar |
| arcoiris_002 | Cometa | Beat 1 | «Coco, ¡lo lograron los tres, cada uno jugando a su manera!» | `historia/arcoiris/arcoiris_002.ogg` | pendiente de grabar |
| arcoiris_003 | Nicole | Beat 1 | «¡Pinté un charco entero de rosado, Coco! Como tú.» | `historia/arcoiris/arcoiris_003.ogg` | pendiente de grabar |
| arcoiris_004 | Coco | Beat 1 | «¡El rosado me queda regio! Miren... ahora soy... ¡rosado chicle!» | `historia/arcoiris/arcoiris_004.ogg` | pendiente de grabar |
| arcoiris_005 | Sofía | Beat 1 | «Y yo até el azul con el amarillo. Salió verde. Química de planeta, nada mal.» | `historia/arcoiris/arcoiris_005.ogg` | pendiente de grabar |
| arcoiris_006 | Maxi | Beat 1 | «¡Yo toqué TODO!» | `historia/arcoiris/arcoiris_006.ogg` | pendiente de grabar |
| arcoiris_007 | Coco | Beat 1 | «Tocaste todo... ¡y todo brilló! Así se juega en mi planeta, chiquitín.» | `historia/arcoiris/arcoiris_007.ogg` | pendiente de grabar |
| arcoiris_008 | Coco | Beat 2 — entrega de la pieza | «Esto es para su nave. El ala del Arcoíris... la pinté yo misma, con todos los colores que me enseñaron hoy.» | `historia/arcoiris/arcoiris_008.ogg` | pendiente de grabar |
| arcoiris_009 | Cometa | Beat 2 | «¡La primera pieza! Miren cómo le queda a la nave.» | `historia/arcoiris/arcoiris_009.ogg` | pendiente de grabar |
| arcoiris_010 | Cometa | Beat 4 — video-llamada | «¡Sorpresa! Alguien quiere saludarlos.» | `historia/arcoiris/arcoiris_010.ogg` | pendiente de grabar |
| arcoiris_011 | Papá | Beat 4 | «¡Hermanos Estelares! Me contaron que ya tienen su primera pieza. ¡Una ala! Con esa y la otra, casi puedo volar yo también... si el Coleccionauta me presta sus lentes de lupa.» | `historia/arcoiris/arcoiris_011.ogg` | pendiente de grabar |
| arcoiris_012 | Papá | Beat 4 | «¿Vieron colores nuevos? Cuéntenme todos cuando nos veamos. Mientras tanto, sigan jugando tranquilos, que acá estoy la mar de bien.» | `historia/arcoiris/arcoiris_012.ogg` | pendiente de grabar |
| arcoiris_013 | Nicole | Beat 4 | «¡Papi, mezclamos azul con amarillo y salió verde!» | `historia/arcoiris/arcoiris_013.ogg` | pendiente de grabar |
| arcoiris_014 | Maxi | Beat 4 | «¡Toqué TODO, papi!» | `historia/arcoiris/arcoiris_014.ogg` | pendiente de grabar |
| arcoiris_015 | Sofía | Beat 4 | «Vamos por la segunda pieza. No te aburras mucho allá.» | `historia/arcoiris/arcoiris_015.ogg` | pendiente de grabar |
| arcoiris_016 | Papá | Beat 4 | «¿Yo, aburrido? Imposible, aquí el Coleccionauta me está enseñando a doblar servilletas en forma de pato. Los quiero, ¡nos vemos pronto!» | `historia/arcoiris/arcoiris_016.ogg` | pendiente de grabar |
| arcoiris_017 | Coco | Beat 5 — cierre y gancho | «Vuelvan cuando quieran, ¡mi arcoíris siempre los espera!» | `historia/arcoiris/arcoiris_017.ogg` | pendiente de grabar |
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
