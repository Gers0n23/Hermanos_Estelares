# Guion de voz — Mapa de zonas del Planeta Arcoíris (HE-40)

> Encargo de `docs/fichas/planeta-arcoiris-zonas.md` §5 ("Voces nuevas que pide el mapa de zonas")
> y revisión de las voces TTS provisionales que ya existen en `assets/audio/voces/arcoiris/*/lineas_tts.tsv`.
> Solo texto: este guion **no genera audio** ni toca los `.tsv`. Cuando el PO apruebe el costo, `dev-godot`
> copia las filas nuevas o reescritas a su `.tsv` (con la directiva `# personaje:` correcta) y regenera.

- **Fuentes**: GDD §1 (tono), §2 (Cometa, anfitriones), §3 (mapa de zonas); ficha de zonas §2 (mapa-isla de
  dulces, reglas de apertura, regalos de zona) y §3 (variantes por juego); `datos/planetas/arcoiris/mapa.json`
  (claves de voz y qué nivel carga cada estación); perfiles en `docs/perfil-jugadores.md`.
- **Voces oficiales**: **Coco** = camaleona suave y cantarina, chilena suave de animadora infantil. **Cometa** =
  criatura chillona y traviesa, latino neutro de doblaje.
- **Ruta sugerida**: relativa a `assets/audio/` y en `.wav`, igual que los `.tsv` actuales. Las líneas
  reescritas **conservan su archivo**, así los `.json` de niveles y `mapa.json` no cambian.
- **Id estable**: `arcoiris_` + la ruta sin carpeta raíz ni extensión (`voces/arcoiris/mapa/zona_1_llegada.wav`
  → `arcoiris_mapa_zona_1_llegada`). Sirve para trazabilidad en `guion_voces.md`.
- **Estado**: todas las filas de este documento están **pendientes de audio**.

## Decisiones de tono de este guion

1. **El tic de Coco se usa en los momentos grandes.** Coco anuncia el color que "es" ahora
   (`escena_planeta_arcoiris.md`, Beat 1). Aquí se usa en cada `zona_<n>_completada`, con un apellido dulce
   tomado del hito de la zona en el mapa-isla: rojo **frutilla**, amarillo **limón**, azul **chupetín**, verde
   **menta**, y al final "arcoíris de pies a cabeza". Así el color que se aprende queda pegado a algo que el niño ve.
2. **Zona dormida, nunca bloqueada.** Con la regla nueva del PO (27-Sep: se abre al completar *todas* las
   estaciones de la zona anterior), la pista tiene que decir qué hacer sin sonar a muro: "juega todos los
   juegos de este lado y lo despertamos". No se usan "candado", "bloqueado" ni "todavía no puedes".
3. **"Regalo de Coco", no "recuerdo".** Los objetos del hangar se llaman *regalos* en voz. "Recuerdo" queda para
   las fotos del álbum (`docs/guiones/recuerdos.md`, observación 5). Así Maxi y Nicole no confunden las dos cosas.
4. **Cero apuro.** Se sacó "rápido" de las intros de Sofía y ninguna intro le avisa que "es mucho más difícil":
   a Sofía, que se frustra rápido, eso la pone nerviosa antes de empezar. Se dice "un reto de campeona".
5. **Un solo nombre por color.** Hoy conviven "violeta" y "morado", "naranja" y "naranjo". Para Nicole, que
   está aprendiendo colores por el oído, el mismo color debe sonar igual en todo el planeta. Canon propuesto:
   **violeta** (es la banda del arcoíris y el color de la zona 5) y **naranja**.
6. **Chile y banderas** (pedido del PO): se mantienen todos los datos de lugares y países. Solo se suaviza el
   significado del rojo de la bandera (ver §4.4).

---

## 1. Mapa del planeta — voces por zona

Suenan en `escenas/planetas/arcoiris/mapa_arcoiris.tscn`. Las `llegada` y `completada` ya tienen clave en
`mapa.json` (`voz_llegada`, `voz_completada`); las `abierta` y `regalo` por zona son **claves nuevas** que
`dev-godot` debe sumar (propuesta: `voz_abierta` y `voz_regalo` dentro de cada zona). La `zona_abierta`
genérica actual queda como respaldo.

**Orden cuando coinciden (propuesta para `director-cinematicas` y `disenador-mecanicas`)**: al completar una
zona suena `completada` (Coco) → `regalo` (Coco, el objeto vuela al hangar) → pausa corta → si es zona 2 o 4,
el sobre-estrella del álbum (`recuerdos_entrega_zona_0X`) → al volver al mapa, `abierta` (Cometa) sobre la
zona siguiente que toma color. En la **zona 3** la escena de historia reemplaza a `zona_3_completada` (su
Beat 1 ya celebra el azul, ver `escena_planeta_arcoiris.md`); el regalo de la zona 3 llega después de la escena.

### 1.1 Zona 1 — El Claro del Trébol (rojo)

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_zona_1_llegada | Coco | «¡Este es el Claro del Trébol! ¿Ven la frutilla gigante? Está grisecita... ¡aquí se escondió el rojo!» | acogedora, señalando | Primera vez que se entra a la zona 1 | `voces/arcoiris/mapa/zona_1_llegada.wav` | reescrita |
| arcoiris_mapa_zona_1_completada | Coco | «¡Volvió el rojo! Mírenme, mírenme... ¡ahora soy rojo frutilla!» | explota de alegría; pausa antes del color (tic) | Se completan todas las estaciones de la zona 1 | `voces/arcoiris/mapa/zona_1_completada.wav` | reescrita |
| arcoiris_mapa_zona_1_regalo | Coco | «Les regalo mi pincel rojo. ¡Cuélguenlo en su nave!» | cariñosa, entregando | Tras `zona_1_completada`; el pincel vuela al hangar | `voces/arcoiris/mapa/zona_1_regalo.wav` | nueva |

### 1.2 Zona 2 — Los Charcos Saltarines (amarillo)

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_zona_2_abierta | Cometa | «¡Se despertó un rincón nuevo! ¡Los Charcos Saltarines! ¡Boing, boing!» | saltando, "boing" bien rebotado (para Maxi) | La zona 2 toma color en el mapa | `voces/arcoiris/mapa/zona_2_abierta.wav` | nueva |
| arcoiris_mapa_zona_2_llegada | Coco | «¡Los Charcos Saltarines! La gelatina de limón tiembla porque le falta el amarillo. ¿Me ayudan?» | divertida; "tiembla" temblando la voz | Primera vez que se entra a la zona 2 | `voces/arcoiris/mapa/zona_2_llegada.wav` | reescrita |
| arcoiris_mapa_zona_2_completada | Coco | «¡Volvió el amarillo! Ahora soy... ¡amarillo limón! ¡Brillo como un sol!» | radiante (tic) | Se completan todas las estaciones de la zona 2 | `voces/arcoiris/mapa/zona_2_completada.wav` | reescrita |
| arcoiris_mapa_zona_2_regalo | Coco | «Tomen: una gota dorada saltarina. ¡Cuidado, que rebota! Boing.» | pícara; el "boing" final chiquito | Tras `zona_2_completada` | `voces/arcoiris/mapa/zona_2_regalo.wav` | nueva |

### 1.3 Zona 3 — El Bosque de Chupetines (azul)

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_zona_3_abierta | Cometa | «¡Otro rincón despierto! ¡El Bosque de Chupetines! Mmm... huele a dulce.» | olfateando, goloso | La zona 3 toma color en el mapa | `voces/arcoiris/mapa/zona_3_abierta.wav` | nueva |
| arcoiris_mapa_zona_3_llegada | Coco | «El Bosque de Chupetines. Mis chupetines perdieron su azul... ¡vamos a buscarlo!» | cómplice, de aventura | Primera vez que se entra a la zona 3 | `voces/arcoiris/mapa/zona_3_llegada.wav` | reescrita |
| arcoiris_mapa_zona_3_completada | Coco | «¡Volvió el azul! Ahora soy... ¡azul chupetín!» | feliz (tic). **No suena si en ese momento se dispara la escena de historia** | Zona 3 completa **sin** escena (p. ej. al rejugarla completa otro hermano que ya vio la escena, si así se implementa) | `voces/arcoiris/mapa/zona_3_completada.wav` | reescrita |
| arcoiris_mapa_zona_3_regalo | Coco | «Un chupetín espiral azul, para su nave. ¡Pero no se lo coman, eh!» | con risa, retando de mentira | Después de la escena de historia (o tras `zona_3_completada`) | `voces/arcoiris/mapa/zona_3_regalo.wav` | nueva |

### 1.4 Zona 4 — Los Islotes Flotantes (verde y naranja)

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_zona_4_abierta | Cometa | «¡Miren allá! ¡Los Islotes Flotantes se despertaron! Flotan como malvaviscos.» | asombrado, soñador | La zona 4 toma color (al cerrar la escena de historia) | `voces/arcoiris/mapa/zona_4_abierta.wav` | nueva |
| arcoiris_mapa_zona_4_llegada | Coco | «¡Los Islotes Flotantes! Flotan en una laguna de soda... y aquí se escondieron el verde y el naranja.» | burbujeante | Primera vez que se entra a la zona 4 | `voces/arcoiris/mapa/zona_4_llegada.wav` | reescrita |
| arcoiris_mapa_zona_4_completada | Coco | «¡Volvieron el verde y el naranja! Ahora soy... ¡verde menta con pintitas naranjas!» | encantada (tic doble) | Se completan todas las estaciones de la zona 4 | `voces/arcoiris/mapa/zona_4_completada.wav` | reescrita |
| arcoiris_mapa_zona_4_regalo | Coco | «Les regalo una estrella flotante, verde y naranja. ¡Suéltenla y miren cómo flota!» | ilusionada | Tras `zona_4_completada` | `voces/arcoiris/mapa/zona_4_regalo.wav` | nueva |

### 1.5 Zona 5 — La Cima del Arcoíris (violeta y brillo, secreta)

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_secreta_lejana | Cometa | «¿Viste ese brillito allá arriba, en la montaña? Es un lugar secreto... ¡se despierta cuando pintemos los Islotes!» | en secreto, cómplice | Tocar el resplandor de la cima antes de revelarla | `voces/arcoiris/mapa/secreta_lejana.wav` | reescrita |
| arcoiris_mapa_secreta_revelada | Cometa | «¡Miren arriba! ¡Apareció la Cima del Arcoíris, un lugar secreto! ¡Tiene una torta gigante!» | fiesta, sorpresa total | Se completa la zona 4 y se revela la cima | `voces/arcoiris/mapa/secreta_revelada.wav` | reescrita |
| arcoiris_mapa_zona_5_llegada | Coco | «¡La Cima del Arcoíris! Aquí arriba duerme el violeta... y el brillo de todo mi planeta.» | susurrando al comienzo, crece al final | Primera vez que se entra a la zona 5 | `voces/arcoiris/mapa/zona_5_llegada.wav` | reescrita |
| arcoiris_mapa_zona_5_completada | Coco | «¡Volvió el violeta! ¡Y el brillo! Ahora soy... ¡arcoíris de pies a cabeza!» | la celebración más grande de Coco (tic) | Se completan todas las estaciones de la zona 5 | `voces/arcoiris/mapa/zona_5_completada.wav` | reescrita |
| arcoiris_mapa_zona_5_regalo | Coco | «El plumón arcoíris de la cima. Es mi favorito... ¡y ahora es de ustedes!» | tierna, regalando lo más querido | Tras `zona_5_completada` | `voces/arcoiris/mapa/zona_5_regalo.wav` | nueva |
| arcoiris_mapa_planeta_completo | Cometa | «¡El Planeta Arcoíris brilla entero! ¡Qué equipo más increíble!» | orgulloso; celebra al grupo, no a uno | Al volver al mapa tras `zona_5_regalo` (el planeta queda a todo color) | `voces/arcoiris/mapa/planeta_completo.wav` | nueva |

### 1.6 Líneas generales del mapa

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_zona_dormida | Coco | «Ese rincón está dormidito, le falta color. ¡Juega todos los juegos de este lado y lo despertamos!» | cariñosa, explicando | Tocar una zona aún no abierta (variante 1) | `voces/arcoiris/mapa/zona_dormida.wav` | reescrita |
| arcoiris_mapa_zona_dormida_02 | Coco | «Shhh... ese rincón está durmiendo siesta. ¡Lo despertamos cuando terminemos por acá!» | susurrando, "shhh" largo (gag para Maxi) | Variante de `zona_dormida` (el mapa elige al azar) | `voces/arcoiris/mapa/zona_dormida_02.wav` | nueva |
| arcoiris_mapa_estacion_repetida_01 | Coco | «¡Otra vez! ¡Me encanta!» | feliz | Entrar a una estación ya completada | `voces/arcoiris/mapa/estacion_repetida_01.wav` | nueva |
| arcoiris_mapa_estacion_repetida_02 | Coco | «¡Este juego de nuevo! ¡Yupi!» | saltarina | Variante | `voces/arcoiris/mapa/estacion_repetida_02.wav` | nueva |
| arcoiris_mapa_estacion_repetida_03 | Coco | «¿Jugamos otra vez? Ahora soy... ¡verde de alegría!» | tic, con risa | Variante | `voces/arcoiris/mapa/estacion_repetida_03.wav` | nueva |
| arcoiris_mapa_juego_taller | Coco | «¡El taller de pinturas de Coco!» | orgullosa, presentando | Tocar la estación de Lluvia cuando juega Sofía (su estación carga el motor `mezclar`, ícono `taller`). Hoy suena `juego_lluvia` ("¡Lluvia de colores!"), que no es lo que ve. Pide clave de voz por perfil en `mapa.json` (propuesta: `voces_perfil: {"sofia": ...}`) | `voces/arcoiris/mapa/juego_taller.wav` | nueva |

Se mantienen sin cambios: `bienvenida`, `zona_abierta` (respaldo), `estacion_pronto`, `cometa_vamos`,
`todo_listo`, `dorado_disponible`, `juego_lluvia`, `juego_formas`, `juego_parejas`, `juego_pinta`.

---

## 2. Intros de estación por zona y hermano

Revisé las 60 intros (5 zonas × 4 juegos × 3 hermanos) contra lo que cada `.json` de nivel referencia hoy
(clave `intro`). Cincuenta y ocho están bien o solo piden ajuste (ver §4). Faltan **dos**: dos estaciones
todavía cargan la intro de la demo antigua, que no describe lo que se juega en esa zona.

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_semilla_intro_z2 | Coco | «¡Hola otra vez, Maxi! Figuras, dinosaurios y autos... ¡toca dos iguales!» | alegre, lento; "dinosaurios" con "grrr" en la voz | Parejas, zona 2, Maxi (hoy usa `semilla/intro_01.wav`) | `voces/arcoiris/emparejar/semilla/intro_z2.wav` | nueva |
| arcoiris_emparejar_brote_intro_z3 | Coco | «¡Nicole, en mi Bosque de Chupetines las cartas se esconden! Da vuelta dos y busca las iguales. Dicen que hay un corazón mágico...» | misteriosa y tierna al final | Parejas, zona 3, Nicole (hoy usa `brote/intro_01.wav`) | `voces/arcoiris/emparejar/brote/intro_z3.wav` | nueva |

`dev-godot`: al generar estas dos, cambiar la clave `intro` de `zona2_charcos/parejas_semilla.json` y
`zona3_chupetines/parejas_brote.json`. `semilla/intro_01` y `brote/intro_01` quedan solo para la demo.

---

## 3. Taller de pinturas de Coco (motor `mezclar`, Sofía) — pistas por zona

Hoy el taller tiene una sola pista (`mezclar/pista.wav`). Las reglas cambian zona a zona (gotas repetidas,
gota gris, frasco sin contador, receta que se esconde), así que conviene una pista de Cometa por regla nueva.
Todas mantienen el patrón: una idea concreta y un truco, nunca "fíjate mejor".

| id | personaje | texto | intención | disparador | ruta sugerida | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mezclar_pista_z2 | Cometa | «Mira cuántas gotas de cada color lleva la receta. ¡A veces son dos iguales!» | cómplice, ayudando | Tocar a Cometa en el taller, zona 2 | `voces/arcoiris/mezclar/pista_z2.wav` | nueva |
| arcoiris_mezclar_pista_z3 | Cometa | «La gota gris es tramposa: déjala pasar y atrapa solo las de la receta.» | en secreto, pícaro | Tocar a Cometa, zona 3 | `voces/arcoiris/mezclar/pista_z3.wav` | nueva |
| arcoiris_mezclar_pista_z4 | Cometa | «Cuenta las gotas con los dedos mientras miras la receta. ¡Así no se te olvida ninguna!» | truco de hermano mayor | Tocar a Cometa, zona 4 | `voces/arcoiris/mezclar/pista_z4.wav` | nueva |
| arcoiris_mezclar_pista_z5 | Cometa | «Di los colores en voz alta mientras se ve la receta. ¡Así se te quedan en la cabeza!» | entusiasta, truco | Tocar a Cometa, zona 5 | `voces/arcoiris/mezclar/pista_z5.wav` | nueva |

La zona 1 sigue con `mezclar/pista.wav`. Hace falta una clave `pista` por nivel en `mezcla_estrella.json`
(si el motor ya la lee, basta con apuntarla).

---

## 4. Revisión de las voces TTS provisionales existentes

Leídos: `mapa`, `lluvia`, `mezclar`, `formas`, `emparejar` y `pinta` (`lineas_tts.tsv`). La mayoría está bien:
frases cortas, cálidas, sin castigo, con buenos datos de Chile y banderas. Aquí van **solo las que conviene
cambiar**. Prioridad: **alta** = contradice el diseño actual o se dice a quien no corresponde; **media** = tono
o consistencia; **baja** = pulido.

### 4.1 Mapa

Las 13 reescrituras del mapa están en §1 (llegada y completada de las 5 zonas, `zona_dormida`,
`secreta_lejana` y `secreta_revelada`). Motivos: sumar el tic de Coco y los hitos del mapa-isla (alta en
`completada`, media en `llegada`), la regla nueva de apertura (alta en `zona_dormida`) y quitar el "algún día
llegaremos" de `secreta_lejana`, que suena a muy lejos (media).

### 4.2 Formas traviesas (`formas/`)

| archivo | texto actual | texto propuesto | motivo | prioridad |
|---|---|---|---|---|
| `figuras/corona.wav` | «¡Una corona! Sofía, te corono líder de la misión.» | «¡Una corona brillante! ¡Te queda preciosa!» | La corona está en el pool de **Nicole** (zona 4). Hoy Coco le habla a Sofía mientras juega Nicole, lo que roza los celos entre ellas (GDD §2) | alta |
| `estrella/intro_arma_z1.wav` | «¡Sofía, mira la tarjeta! Es la iglesia de Castro, en Chiloé, y tiene veinticinco piezas. Busca en la bandeja la pieza que calza en cada lugar.» | «¡Sofía, mira la tarjeta! Es la iglesia de Castro, en Chiloé: veinticinco piezas y sin líneas de ayuda. Si una pieza llega chueca, tócala para girarla.» | Desde el 27-Sep Sofía ve solo el contorno y gira desde la zona 1. La intro no lo decía | alta |
| `estrella/intro_arma_z2.wav` | «¡Los palafitos de Chiloé, las casitas sobre el agua! Ahora algunas piezas llegan giradas: tócalas para darlas vuelta.» | «¡Los palafitos de Castro, casitas sobre el agua! Tres casas con sus pilotes. ¡Mira bien la tarjeta!» | El "ahora" del giro ya no es nuevo en la zona 2 | media |
| Obsoletas: `semilla/intro_z1..z4`, `brote/intro_z1..z4`, `estrella/intro_tangram_z1`, `intro_espejo_z2`, `intro_memoria_z3`, `intro_marco_z4`, `intro_marco_z4b`, `intro_cima_1..3`, `pista_tangram_01`, `pista_espejo_01`, `pista_memoria_01`, `pista_marco_01`, `mira_modelo_01`, `tapa_modelo_01`, `espejo_sin_pieza_01` | — | **No regenerar** con la voz oficial | Ningún nivel las referencia desde "Arma la figura" (27-Sep). `semilla/intro_z5` y `brote/intro_z5` **sí** se usan (zona 5) y siguen bien. Confirmar con `dev-godot` antes de borrar nada | media (ahorro de costo) |

Nota para `disenador-niveles` (no es de guion): el pool de Nicole en la zona 3 incluye **mariposa**, y su
ficha prohíbe bichos (en Pinta ya se cambió por flor). La línea `figuras/mariposa.wav` está bien escrita; lo
que habría que revisar es la figura.

### 4.3 Parejas de Coco (`emparejar/`)

| archivo | texto actual | texto propuesto | motivo | prioridad |
|---|---|---|---|---|
| `estrella/intro_z3.wav` | «¡Tríos! Tienes que dar vuelta tres cartas iguales para ganarlas. ¡Es mucho más difícil!» | «¡Tríos! Ahora hay que encontrar tres cartas iguales. ¡Un reto de campeona!» | "Es mucho más difícil" pone nerviosa a Sofía antes de empezar; mejor presentarlo como reto | media |
| `colores/naranjo.wav` | «¡Naranjo, como el gatito!» | «¡Naranja, como el gatito!» | Consistencia: en Lluvia, Taller y Pinta se dice "naranja" (decisión de tono 5). Si el PO prefiere "naranjo", que es más de la casa, se cambia en todas partes y no solo aquí. Recomendación detallada en §7 | media |
| `semilla/intro_01.wav`, `brote/intro_01.wav` | — | Sin cambio de texto | Se reemplazan en las zonas por las intros nuevas de §2 | alta (por §2) |

### 4.4 Pinta con Coco (`pinta/`)

| archivo | texto actual | texto propuesto | motivo | prioridad |
|---|---|---|---|---|
| `datos/m_chile.wav` | «La estrella blanca se llama la estrella solitaria. El azul es el cielo, el blanco la nieve de la cordillera y el rojo, la sangre de los héroes.» | «La estrella blanca se llama la estrella solitaria. El azul es el cielo, el blanco la nieve de la cordillera y el rojo, el corazón valiente de los héroes.» | "Sangre" es fuerte para un juego de 2-8 años donde suena en voz alta. Se conserva el sentido: los héroes | media |
| `colores/violeta.wav` | «¡Morado, como una uva!» | «¡Violeta, como una uva!» | Un solo nombre por color (decisión de tono 5). La zona 5 "devuelve el violeta" y Lluvia dice violeta | media |
| `logrado/violeta.wav` | «¡Morado! ¡Precioso!» | «¡Violeta! ¡Precioso!» | Ídem | media |
| `mezclas/violeta.wav` | «¡Morado! Rojo con azul.» | «¡Violeta! Rojo con azul.» | Ídem | media |
| `mezclas/lila.wav` | «¡Lila! Morado con blanco.» | «¡Lila! Violeta con blanco.» | Ídem | media |
| `pedidos/violeta.wav` | «Ahora quiero ver algo morado.» | «Ahora quiero ver algo violeta.» | Ídem | media |
| `pedidos_mezcla/violeta.wav` | «¿Te atreves con el morado?» | «¿Te atreves con el violeta?» | Ídem | media |

### 4.5 Taller de pinturas (`mezclar/`)

| archivo | texto actual | texto propuesto | motivo | prioridad |
|---|---|---|---|---|
| `intro_z1.wav` | «¡Sofía, ayúdame a pintar mi mural! Necesito tres latas de pintura. Te muestro la receta: memorízala. Después mueve el frasco para atrapar solo las gotas de la receta, ¡y agítalo para mezclar!» | «¡Sofía, ayúdame a pintar mi mural! Mira la receta y memorízala. Después mueve el frasco, atrapa solo esas gotas... ¡y agítalo para mezclar!» | 35 palabras con cuatro instrucciones es mucho para una intro hablada; quedan tres pasos claros | media |
| `intro_z5.wav` | «¡Tres murales en la cima! Esta vez la receta se ve solo un ratito. ¡Memoriza rápido, maestra pintora!» | «¡Tres murales en la cima! Esta vez la receta se ve solo un ratito. ¡Mírala bien, maestra pintora!» | "Rápido" apura; la regla ya se entiende con "un ratito" | media |
| `gris_01.wav` | «¡La gota gris ensució la pintura! Déjala pasar la próxima vez.» | «¡Pfff, se coló la gota gris! La muy tramposa... la próxima la dejamos pasar.» | Suena menos a corrección y más a gag compartido ("dejamos") | baja |

### 4.6 Lluvia de colores (`lluvia/`)

Maxi y Nicole: sin cambios. Todas sus intros y pistas por zona describen bien la variante y el gag de derrota
de Nicole (estornudar un arcoíris) es de los mejores del planeta.

**Sofía**: desde que su estación carga el Taller (`mezclar`), `mapa.json` ya no abre `lluvia_estrella.json`,
así que las ~35 líneas de `lluvia/estrella/*` y los `datos/*` de Lluvia **no suenan desde el mapa**. Confirmar con
`dev-godot` si algo más las usa antes de gastar en regenerarlas. Si se mantienen, solo conviene un cambio:

| archivo | texto actual | texto propuesto | motivo | prioridad |
|---|---|---|---|---|
| `estrella/no_es_este_01.wav` | «Ese color no va en esta receta. ¡Piensa otra vez!» | «¡Uy, ese no va! ¿Qué color le falta?» | "Piensa otra vez" suena a reto de profesora; la pregunta invita a pensar sin regañar | baja (condicional) |

---

## 5. Cambio en la escena de historia

`docs/guiones/escena_planeta_arcoiris.md` quedó actualizado en el mismo acto: disparador (zona 3 completa,
con rojo, amarillo y azul de vuelta), `arcoiris_001` (ya no "terminaron todo mi arcoíris del claro"),
`arcoiris_008` (sin "hoy", porque la zona 3 puede terminarse otro día) y `arcoiris_017` (invita a los Islotes
sin apurar). `assets/audio/voces/guion_voces.md` todavía tiene el texto viejo de esas tres filas: hay que
sincronizarlo **antes** de generar su audio.

---

## 6. Resumen de conteo

| bloque | nuevas | reescritas |
|---|---|---|
| Mapa (§1) | 14 | 13 |
| Intros de estación (§2) | 2 | 0 |
| Taller, pistas (§3) | 4 | 0 |
| Formas (§4.2) | 0 | 3 |
| Parejas (§4.3) | 0 | 2 |
| Pinta (§4.4) | 0 | 7 |
| Taller (§4.5) | 0 | 3 |
| Lluvia (§4.6, condicional) | 0 | 1 |
| Escena de historia (§5) | 0 | 3 |
| **Total HE-40** | **20** | **32** |

Por personaje: **Coco** 12 nuevas y 30 reescritas (incluye `arcoiris_001`, `_008` y `_017`); **Cometa**
8 nuevas (4 del mapa y 4 pistas del Taller) y 2 reescritas (`secreta_lejana`, `secreta_revelada`).
Obsoletas que **no** conviene regenerar: ~23 de Formas (§4.2).

---

## 7. Revisión de los textos que escribió `dev-godot` y voz nueva de Pinta (02-Oct-2026)

El 28-Sep `dev-godot` escribió seis líneas sin guion
(`docs/validaciones/2026-09-28_dev-correcciones-HE-40-HE-44.md` §2). Aquí quedan sus textos definitivos, ya
copiados a sus `lineas_tts.tsv`, junto con la voz "¿me lo muestras?" que pide la mecánica HE-40 #21. Sus
`.wav` actuales (relleno de Windows) **dicen el texto viejo**: hay que regenerarlos, y las de Pinta todavía
no tienen audio.

| id | personaje | texto | intención | disparador | ruta | tipo |
|---|---|---|---|---|---|---|
| arcoiris_mapa_dorado_entrar | Coco | «¡Entramos al reto dorado! Ahora soy... ¡dorada de la emoción! ¡Vamos, campeona!» | emocionada, cómplice; pausa antes de "dorada" (tic) | Sofía toca un reto dorado del mapa y entra | `voces/arcoiris/mapa/dorado_entrar.wav` | reescrita |
| arcoiris_formas_estrella_intro_bandera_primero | Coco | «¡Sofía, primero una bandera, para calentar los dedos! Cada pieza va en su color. Si una llega chueca, tócala para girarla.» | ligera, de juego; sin peso de examen | Formas, Sofía: primera ronda (bandera) antes del monumento | `voces/arcoiris/formas/estrella/intro_bandera_primero.wav` | reescrita |
| arcoiris_mezclar_escupe_01 | Coco | «¡Ptui! Al frasco no le gustó esa gotita. ¡Las demás se quedan!» | con risa; el "ptui" bien sonoro | Taller: 1.ª gota equivocada de la lata, sale escupida y las capas buenas se quedan | `voces/arcoiris/mezclar/escupe_01.wav` | reescrita |
| arcoiris_mezclar_escupe_02 | Coco | «¡Ups! El frasco hizo ptui y la escupió. Tu mezcla sigue a salvo.» | divertida, tranquilizando al final | Variante de `escupe` | `voces/arcoiris/mezclar/escupe_02.wav` | reescrita |
| nucleo_pista_confirmar | Cometa | «¿Te soplo una pista? Cuesta una estrellita. ¡Toca el globito si la quieres!» | en secreto, pícaro; "soplo" como quien sopla en la sala de clases | 1.er toque al botón de pista: se abre el globo (todavía no cobra) | `voces/nucleo/pista_confirmar.wav` | reescrita |
| nucleo_pista_gratis | Cometa | «¡Esta pista va de regalo! Mira, mira...» | generoso, travieso | Pista con 1 sola estrellita en el medidor: gratis y directa | `voces/nucleo/pista_gratis.wav` | reescrita |
| arcoiris_pinta_semilla_me_lo_muestras_01 | Coco | «¡Maxi! ¿Me lo muestras? ¡Toca mi carita!» | curiosa, lenta, cariñosa; nunca apurada | Pinta de Maxi: ~90 s sin tocar "mostrar a Coco"; el botón late | `voces/arcoiris/pinta/semilla/me_lo_muestras_01.wav` | nueva |
| arcoiris_pinta_semilla_me_lo_muestras_02 | Coco | «¡Ooh, qué colores! ¿Me lo muestras, Maxi? ¡Toca mi carita!» | maravillada | Variante de la anterior (al azar) | `voces/arcoiris/pinta/semilla/me_lo_muestras_02.wav` | nueva |
| arcoiris_pinta_semilla_me_lo_muestras_auto | Coco | «¡Ay, no aguanto la curiosidad! ¡A ver, a ver tu dibujo!» | impaciente de puro cariño, con risa | **Opcional**: solo si la mecánica auto-muestra la hoja tras otro rato largo sin tocar. Después suena el `mostrar_0X` normal | `voces/arcoiris/pinta/semilla/me_lo_muestras_auto.wav` | nueva |

### 7.1 Decisiones de tono de esta revisión

1. **`dorado_entrar`**: entrar al reto dorado es un momento grande, así que usa el tic de Coco (§ decisión 1).
   "¡Vamos, campeona!" la acompaña sin apurarla. Se quitó "desafío", que repetía la idea de dificultad.
2. **`escupe`**: el gag es del frasco, no de Sofía. El frasco "no le gustó" la gota, así nadie se equivocó.
   La segunda mitad le confirma lo importante: lo que ya hizo sigue ahí. Se quitó "¡Puaj!", que ya abre
   `sucio_01`, para que la gota escupida (sin costo) suene distinta del frasco que se vacía.
3. **`pista_confirmar`**: "Me das una estrellita" sonaba a cobro. "¿Te soplo una pista?" es chileno de sala de
   clases y suena a complicidad. La línea dice el costo una vez y deja claro que es opcional ("si la quieres").
   Además nombra el globito: es lo único que se toca para confirmar, y sin voz un niño no lo sabría.
4. **`pista_gratis`**: el "Mira, mira..." lleva la vista a la pista, que aparece en ese mismo momento.
5. **"¿Me lo muestras?" (Maxi)**: el nombre va primero para captar su atención y las frases tienen 6 a
   9 palabras. Siempre aparece "toca mi carita", la misma instrucción de `muestramelo_01/02`, así Maxi
   aprende un solo gesto. Las variantes 01/02 son distintas de `muestramelo` (que suena cuando aparece el
   botón) para que a los 90 s no se repita la misma frase. `me_lo_muestras_auto` presenta el auto-mostrar
   como curiosidad de Coco, nunca como "se acabó el tiempo".

**Recomendación `naranjo` vs. "naranja" (decide el PO)**: se mantiene **"naranja"**. "Naranjo" es muy de
la casa y está bien dicho en Chile, pero hoy 15 líneas del planeta dicen "naranja" (Lluvia, Taller, Pinta y
las 3 de la zona 4 del mapa) y solo una dice "naranjo" (`emparejar/colores/naranjo.wav`). Unificar en
"naranja" cuesta regenerar 1 línea; unificar en "naranjo" cuesta 15, y el dato de Lluvia ("el color se llama
así por la fruta") pierde sentido. Para Nicole importa que el color suene siempre igual en el juego. En la
casa pueden seguir diciendo "naranjo": a esa edad entienden los dos nombres. Si el PO elige "naranjo", se
cambia en las 16 líneas a la vez, nunca solo en una.

Conteo de esta revisión: **3 nuevas** (Coco, Maxi; una opcional) y **6 reescritas** (Coco 4, Cometa 2).
