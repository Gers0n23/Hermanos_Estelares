# Cometa, narrador de la aventura — guion completo

> **Borrador para revisión del PO (21-Nov-2026). No se genera audio hasta que el PO lo apruebe.**
> Pedido del PO: «Cometa es el narrador de la historia y el que presenta los acontecimientos; tiene que
> contar parte de la historia, aparte de interactuar con los Hermanos Estelares.»
>
> Este documento reúne **todo lo que dice Cometa, en el orden en que pasa la aventura**: lo que narra en
> off (sobre videos y stills), lo que dice en escena, y lo que dice en los menús. Las videollamadas de papá
> van incluidas para que la historia se lea completa, pero esas líneas son **voz de papá** y se generan en
> otra tanda.
>
> Columna **Estado**: *nueva* (escrita ahora) · *existente* (ya estaba en su guion, se mantiene igual) ·
> *reemplaza* (sustituye a la línea indicada) · *[Confirmar PO]* (gancho de un planeta que todavía no tiene
> guion propio; se ajusta cuando se escriba ese planeta).

## 0. Cómo narra Cometa

1. **Dos voces de Cometa, el mismo personaje.** *En off* cuenta la historia como un cuento ("Esta historia
   empieza..."), sobre los videos de Blender, los stills y las transiciones. *En escena* habla con los
   hermanos. Nunca se esconde que el narrador es él: hasta hace chistes de eso («yo todavía no llegaba...»).
2. **Cambio de regla (PO, 21-Nov-2026):** antes había "máximo una línea en off por transición". Ahora
   Cometa puede contar **hasta 3 líneas seguidas** en una transición. Cada línea dura **8 s o menos**.
   Nunca narra encima del destello de papá ni encima de la voz de un niño.
3. **Cinco hilos que atraviesan los seis planetas** (es lo que convierte las escenas sueltas en una historia):
   - **Los aterrizajes de Cometa**: pone nota a cada uno. Empieza con un 6 de 10 en el living y mejora
     hasta el aterrizaje perfecto en el planeta final.
   - **El álbum de abrazos**: cada anfitrión entra al álbum de Cometa como amigo nuevo. Al final, el álbum
     es la prueba de la lección: «los amigos son la mejor colección».
   - **Las cosas que se le caen al Coleccionauta**: el mapa en Arcoíris, un calcetín espacial, su gorro de
     dormir... siembra que es despistado y prepara las llaves perdidas de la prueba final.
   - **Cometa y el Coleccionauta de chicos**: su historia se cuenta de a poco (intro, viaje a Melodía,
     Planeta Corazón) y explica por qué Cometa confía en los hermanos para el final.
   - **Papá en videollamada**: Cometa abre cada llamada con un gag distinto y la cierra devolviendo la
     tranquilidad («papá está bien; seguimos»).
4. **Tono**: el de siempre. Cometa ríe de sí mismo, nunca apura, nunca regaña, nunca da miedo. Español
   neutro (Cometa no cambia de dialecto, regla del 21-Nov): sin "po", sin modismos de España.
5. **Rutas de audio**: lo nuevo en off y en escena va a `voces/historia/narracion/<id>.wav`; lo nuevo de
   menús va a `voces/nucleo/<id>.wav`. Las líneas existentes conservan su ruta.

---

## Acto 1 — La Tierra: el living, papá y la nave

### 1.1 Prólogo (antes del Beat 1 de la intro, sobre stills del living)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_prologo_01 | Still del living, luz de tarde | off | «Esta historia empieza en una casa como cualquier otra, una tarde llena de sol... y de juegos.» | nueva |
| narr_prologo_02 | Still de Sofía | off | «Ahí viven tres hermanos. Sofía, la mayor, que siempre tiene un plan.» | nueva |
| narr_prologo_03 | Still de Nicole dibujando | off | «Nicole, que hace amigos en todas partes y dibuja todo lo que imagina.» | nueva |
| narr_prologo_04 | Still de Maxi con su dino-auto | off | «Y Maxi, el más chiquito... ¡y el más valiente! A él nada lo asusta.» | nueva |
| narr_prologo_05 | Paneo al living completo | off | «Cuando estos tres juegan juntos, el living se convierte en... ¡cualquier cosa!» | nueva |

→ Beat 1: `intro_001` a `intro_003` (los niños juegan).

### 1.2 Antes y después del destello (Beat 2)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_intro_antes_coleccionauta | Después de `intro_003`, antes de las chispitas | off | «Lo que nadie sabía es que alguien muy despistado andaba buscando cosas increíbles para su colección...» | nueva |
| narr_intro_despues_destello | Después de `intro_010` (Maxi: «¡Uuuh, luuuces!»), nunca encima del destello | off | «¡Puf! Así, en un parpadeo, papá se fue de paseo con el Coleccionauta. ¿Y saben quién llegó un segundito tarde?» | nueva |
| narr_intro_yo | Justo antes del choque de la navecita (Beat 3) | off | «...Yo. Jiji.» | nueva |

→ Beat 3: Cometa entra dando tumbos. Se mantienen:

| id | Cometa dice | Estado |
|---|---|---|
| intro_012 | «¡Uuuy, tumbo! Jijiji... a ese aterrizaje le doy un 6 de 10.» | existente (primer aterrizaje del hilo) |
| intro_013 | «Buuu, lo perdí por segunditos... ¡otra vez! Ese Coleccionauta corre rapidísimo cuando quiere.» | existente |
| intro_017 | «¡Redondito y orgulloso! Hola, Hermanos Estelares. Bueno... todavía no lo son, eso viene ahora. Y sí, lo vi: ese despistado es mi amigo, el Coleccionauta.» | existente |

### 1.3 Quién es el Coleccionauta (Beat 4), los trajes (Beat 5) y la nave (Beat 6)

| id | Cometa dice | Estado |
|---|---|---|
| intro_018 | «Lo conozco desde que éramos chicos —armamos naves juntos, en el mismo planeta—. Y anda coleccionando las cosas más increíbles del universo.» | existente |
| intro_018b | «Y le pareció increíble el papá de ustedes, ¡por criar a tres niños tan buenos! Así que se lo llevó a su colección.» | existente |
| intro_020 | «¡Clarísimo que sí! El Coleccionauta es despistado y solitario, pero jamás malo. Seguro ya le ofreció una de sus galletas raras.» | existente |
| intro_022 | «¡Esa actitud! Por eso vine a buscarlos a ustedes tres.» | existente |
| intro_023 | «Para este viaje van a necesitar esto: sus trajes de Hermanos Estelares, con estrella de poder incluida.» | existente |
| intro_027 | «Y esta es nuestra nave-estrella. Quedó un poco averiada de tanto perseguir al Coleccionauta por la galaxia... por ahora solo le alcanza la energía para un saltito, el justo para llegar al primer planeta. ¡Las piezas que le faltan las conseguimos jugando!» | existente |

> `intro_018c` («¡Y se le pierden hasta las llaves!») **se quita**: el hilo de "las cosas que se le caen"
> ahora lo cuenta Cometa en los viajes, y las llaves se las deja al Coleccionauta en la prueba final.

### 1.4 Primera videollamada de papá (Beat 7)

Hoy la llamada aparece sin aviso. Cometa la abre y la cierra:

| id | Cuándo | Tipo | Quién | Línea | Estado |
|---|---|---|---|---|---|
| narr_intro_llamada_abre | La nave brilla y suena | escena | Cometa | «¡Miren, la nave está sonando! Es una videollamada... ¿de quién será?» | nueva |
| intro_031 | | | Papá | «¡Hola, mis campeones! ¡Qué manera de salir de paseo sin avisar! Miren dónde estoy... el Coleccionauta tiene una silla tan cómoda que casi ni quiero que me rescaten. Es broma, ¡los espero con muchas ganas!» | existente (voz de papá) |
| intro_032 | | | Papá | «Eso sí, no se apuren por mí, yo estoy muy bien, de verdad. Ustedes disfruten el viaje, ¿ya?» | existente (voz de papá) |
| intro_033 a 035 | | | Maxi, Nicole, Sofía | (respuestas de los niños) | existente |
| intro_036 | | | Papá | «Sé que sí. Los quiero un montón. ¡Nos vemos, Hermanos Estelares!» | existente (voz de papá) |
| narr_intro_llamada_cierra | La llamada se corta con estrellitas | off | Cometa | «Papá estaba tranquilo, cómodo y contento. Y los Hermanos Estelares... ¡listos para su primera misión!» | nueva |
| intro_037 | Cometa en la puerta del patio | escena | Cometa | «¿Listos para volar, Hermanos Estelares?» | existente |

### 1.5 Despegue y viaje al Planeta Arcoíris (Beat 8b, video de Blender)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_viaje_tierra_01 | Se encienden los motores | off | «¡Despegamos! Chao, patio; chao, casa... ¡hola, estrellas!» | reemplaza `intro_viaje_01` |
| narr_viaje_tierra_02 | La nave cruza el cielo | off | «A la nave le faltan seis piezas, pero le alcanza para un saltito: justo hasta el primer planeta.» | nueva |
| narr_viaje_tierra_03 | Aparece un puntito de colores | off | «Y el primer planeta es... ¡el Planeta Arcoíris, el planeta de los colores!» | nueva |

---

## Acto 2 — Planeta Arcoíris (capítulo 1)

### 2.1 Presentación del planeta (video B3, la nave en órbita)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_arcoiris_presenta_01 | El planeta visto desde lejos | off | «Desde lejos, el Planeta Arcoíris parece un dulce gigante de todos los colores.» | nueva |
| narr_arcoiris_presenta_02 | La cámara baja; el planeta se ve gris | off | «Pero mientras bajamos... ¿lo notan? Algo raro pasa aquí. ¡Se está poniendo gris!» | nueva |

→ Escena de llegada (`escena_llegada_arcoiris.md`). Se mantienen las líneas de Cometa:
`arcoiris_llegada_003` «¡Llegamos! Le doy un 10 a este aterrizaje... ¡casi sin tumbos!» y
`arcoiris_llegada_013` «Ese despistado... no es malo. ¡Lo conozco bien!».

### 2.2 El mapa del planeta (primera vez)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_arcoiris_mapa_01 | Primera vez en el mapa de Arcoíris | escena | «Este es el mapa del Planeta Arcoíris. Cada rincón donde juguemos... ¡le devuelve un color!» | nueva |
| narr_arcoiris_mapa_02 | Enseguida | escena | «Empecemos por el Claro del Trébol, donde está la frutilla gigante de Coco.» | nueva |

Se mantienen las zonas que despiertan (`zonas_arcoiris.md`): `arcoiris_mapa_zona_2_abierta`,
`_zona_3_abierta`, `_zona_4_abierta`, `_secreta_lejana`, `_secreta_revelada` y `_planeta_completo`.

### 2.3 La primera pieza (escena del ala + video del taller, B2 pieza 1)

Se mantienen `arcoiris_002` («Coco, ¡lo lograron los tres, cada uno jugando a su manera!») y
`arcoiris_009` («¡La primera pieza! Miren cómo le queda a la nave.»). Sobre el video del taller:

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_taller_1_01 | El ala flota hacia la nave | off | «Coco nos regaló el ala izquierda, pintada con los colores que ustedes le devolvieron.» | nueva |
| narr_taller_1_02 | El ala encaja | off | «Clic, clac... ¡quedó perfecta! Primera pieza puesta. Faltan cinco.» | nueva |

### 2.4 Videollamada de papá (Beat 4 de la escena del planeta)

| id | Quién | Línea | Estado |
|---|---|---|---|
| arcoiris_010 | Cometa | «¡Sorpresa! Alguien quiere saludarlos.» | existente |
| arcoiris_011 | Papá | «¡Hermanos Estelares! Me contaron que ya tienen su primera pieza. ¡Una ala! Con esa y la otra, casi puedo volar yo también... si el Coleccionauta me presta sus lentes de lupa.» | existente (voz de papá) |
| arcoiris_012 | Papá | «¿Vieron colores nuevos? Cuéntenme todos cuando nos veamos. Mientras tanto, sigan jugando tranquilos, que acá estoy muy bien, de verdad.» | existente (voz de papá) |
| arcoiris_013 a 015 | Nicole, Maxi, Sofía | (respuestas de los niños) | existente |
| arcoiris_016 | Papá | «¿Yo, aburrido? Imposible, acá el Coleccionauta me está enseñando a doblar servilletas en forma de pato. Los quiero, ¡nos vemos pronto!» | existente (voz de papá) |
| narr_arcoiris_llamada_cierra | Cometa (off) | «Papá está feliz... ¡y doblando servilletas! Así que nosotros, a seguir pintando el planeta.» | nueva |
| arcoiris_018 | Cometa | «Vamos, Hermanos Estelares... el siguiente planeta nos espera, brillando allá lejos.» | existente |

### 2.5 La batalla de Arcoíris (vuelve el Coleccionauta)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_batalla_presenta_01 | Antes del teaser del Coleccionauta | off | «Y justo cuando el planeta empezaba a brillar otra vez... ¿adivinen quién apareció?» | nueva |
| narr_batalla_presenta_02 | Entra el Coleccionauta con su mochila-torre | off | «¡El Coleccionauta! Con su mochila llena de colores que se llevó sin pedir.» | nueva |
| narr_batalla_presenta_03 | Plano de los tres hermanos | off | «Esta vez no está solo Coco. ¡Están los Hermanos Estelares, y juegan en equipo!» | nueva |
| narr_batalla_ganada | Después de que cae la torre, antes del epílogo | off | «¡Lo lograron, juntos! La torre cayó y los colores volvieron a su casa.» | nueva |

Se mantienen las líneas de juego de la batalla y del cierre: `nucleo_batalla_hito`, `arcoiris_batalla_cierre_foto`,
`arcoiris_batalla_cierre_mapa_cometa` («¡Un mapa estelar! Y tiene una flechita... ¡hacia Animalia!»),
`arcoiris_batalla_cierre_mapa_animalia`, la preparación de la nave y la cuenta regresiva (`cierre-arcoiris.md` §4 y §7).

### 2.6 Videollamada del cierre (existente, voz de papá)

`arcoiris_batalla_cierre_papa_01` («¡Esa foto! Los tres juntitos... ¡me la pongo de fondo de pantalla!»),
`_papa_pista` («...¡Va camino a Animalia! Y de fondo se oían ladridos... y algo así como... ¡GRRR!»),
`_papa_guatita` y `_papa_03` (el chiste del arcoíris). Cometa la abre con `arcoiris_010` y la cierra con:

| id | Tipo | Cometa dice | Estado |
|---|---|---|---|
| narr_cierre_llamada_cierra | off | «¿Ladridos? ¿Rugidos? Hermanos Estelares... ¡parece que la próxima aventura tiene animales!» | nueva |

### 2.7 Fin del capítulo 1 y viaje a Animalia (video B4)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_viaje_animalia_01 | La nave deja Arcoíris | off | «Chao, Planeta Arcoíris... ¡y gracias, Coco! Ahora la nave vuela con un ala nueva.» | nueva |
| narr_album_coco | Cometa abre su álbum de abrazos | off | «Y en mi álbum de abrazos guardé un recuerdo nuevo: ¡el abrazo de Coco!» | nueva |
| narr_viaje_animalia_02 | La nave vuela un poco de lado | off | «Con una sola ala, la nave vuela un poquito de ladito... ¡agárrense! Jiji.» | nueva |
| narr_viaje_animalia_03 | Aparece el mapa del Coleccionauta | off | «El mapa que se le cayó al Coleccionauta apunta a Animalia, el planeta de los animales.» | nueva |
| narr_cap1_fin | Solo si el capítulo 2 todavía no existe (rama A) | off | «Y así terminó la primera aventura de los Hermanos Estelares. Pero el viaje... ¡recién empieza!» | nueva |

---

## Acto 3 — Los planetas 2 a 6

Cada planeta sigue la misma forma, para que los niños reconozcan el ritmo: **presentación en órbita → aterrizaje
con nota → quién es el anfitrión → (los juegos) → la pieza en el taller → videollamada → abrazo para el álbum →
viaje al siguiente, contando un poquito más de la historia.** Los ganchos propios de cada planeta van marcados
*[Confirmar PO]* hasta que se escriba el guion de ese planeta.

### 3.1 Planeta Animalia (Toby · ala derecha)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_animalia_presenta_01 | En órbita | off | «¡Miren abajo! Selvas verdes, ríos y montañas... ¡el Planeta Animalia!» | nueva |
| narr_animalia_presenta_02 | La cámara baja | off | «Aquí viven animales de todos los tamaños. ¡Hasta algunos que hacen GRRR!» | nueva |
| narr_animalia_aterriza | Al bajar de la nave | escena | «¡Aterrizamos en algo blandito! ...Ah, no, es una hoja gigante. Le doy un 8 de 10.» | nueva |
| narr_animalia_anfitrion | Aparece Toby | escena | «¡Ese perrito con casco es Toby, el astronauta de Animalia!» | nueva |
| narr_animalia_pista | Antes de que Toby cuente el problema | escena | «Toby, ¿pasó por aquí un despistado con una mochila gigante?» | nueva [Confirmar PO] |
| narr_taller_2_01 | Video del taller | off | «Toby nos regaló el ala derecha, con su huellita pintada.» | nueva |
| narr_taller_2_02 | El ala encaja | off | «¡Dos alas! Ya no volamos de ladito. Faltan cuatro piezas.» | nueva |
| narr_animalia_llamada_abre | Suena la pantalla | escena | «¡Ring, ring estelar! La pantalla de la nave se está encendiendo...» | nueva |
| narr_animalia_llamada_cierra | Se corta la llamada | off | «¡Papá ya tiene un loro! Él está feliz, así que nosotros seguimos la aventura.» | nueva |
| narr_album_toby | Cometa abre el álbum | off | «¡Toby ya está en mi álbum de abrazos! Con lengüetazo incluido.» | nueva |
| narr_viaje_melodia_01 | La nave sale de Animalia | off | «Rumbo al Planeta Melodía. ¿Escuchan? Desde aquí ya se oye música.» | nueva |
| narr_viaje_melodia_02 | Cometa mira por la ventana | off | «¿Saben? Cuando el Coleccionauta y yo éramos chiquitos, armamos nuestra primera nave. ¡Era de cajas!» | nueva |
| narr_viaje_melodia_03 | Sigue el viaje | off | «Él guardaba cada tuerca en una cajita. Yo prefería guardar recuerdos de mis amigos. Siempre fuimos distintos.» | nueva |

**Videollamada (voz de papá, propuesta, otra tanda):**
- `animalia_papa_01`: «¡Hola, mis exploradores! El Coleccionauta trajo un loro que repite todo. Ya aprendió a decir "¡a comer!"... con mi voz.»
- `animalia_papa_02`: «Yo estoy muy bien, de verdad. Pásenlo bien con Toby y denle un cariño de mi parte.»

### 3.2 Planeta Melodía (Octavio · motor izquierdo)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_melodia_presenta_01 | En órbita | off | «¡El Planeta Melodía! Aquí todo brilla en morado... y todo suena.» | nueva |
| narr_melodia_presenta_02 | La cámara baja | off | «Hasta las nubes hacen tum, tum, tum. ¡Prepárense para bailar!» | nueva |
| narr_melodia_aterriza | Al bajar | escena | «¡Aterrizamos al ritmo! Pum... pum... ¡pum! Un 9 de 10, por estilo.» | nueva |
| narr_melodia_anfitrion | Aparece Octavio | escena | «¡Ese es Octavio, el pulpo DJ! Ocho brazos... ¡y ocho instrumentos!» | nueva |
| narr_taller_3_01 | Video del taller | off | «Octavio nos regaló el motor izquierdo. ¡Suena como una trompeta!» | nueva |
| narr_taller_3_02 | El motor encaja | off | «Brrrum, tururú... ¡tres piezas puestas! Ya vamos en la mitad del camino.» | nueva |
| narr_melodia_llamada_abre | Suena la pantalla | escena | «La pantalla está sonando... ¡al ritmo! Es una llamada.» | nueva |
| narr_melodia_llamada_cierra | Se corta | off | «El Coleccionauta canta en la ducha y papá está feliz. ¡Seguimos!» | nueva |
| narr_album_octavio | Álbum | off | «¡Octavio ya está en mi álbum de abrazos! Un abrazo de pulpo vale por ocho.» | nueva |
| narr_viaje_cuentacuentas_01 | Sale la nave | off | «Ahora vamos al Planeta Cuenta-Cuentas, donde las estrellas se cuentan una por una.» | nueva |
| narr_viaje_cuentacuentas_02 | Algo flota frente a la nave | off | «¡Miren eso que va flotando! Es... ¡un calcetín espacial! Se le cayó al Coleccionauta.» | nueva |
| narr_viaje_cuentacuentas_03 | Sigue el viaje | off | «Ese despistado pierde todo en el camino... ¡menos las ganas de coleccionar!» | nueva |

**Videollamada (voz de papá, propuesta, otra tanda):**
- `melodia_papa_01`: «¡Hola, mis músicos! Descubrí que el Coleccionauta canta en la ducha. Desafinado, pero con mucho sentimiento.»
- `melodia_papa_02`: «¿Ya bailaron con Octavio? Bailen uno por mí, que yo acá solo bailo con los cojines.»

### 3.3 Planeta Cuenta-Cuentas (Profesor Plumas · motor derecho)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_cuentacuentas_presenta_01 | En órbita | off | «¡El Planeta Cuenta-Cuentas! Aquí siempre es de noche, y el cielo está lleno de números que brillan.» | nueva |
| narr_cuentacuentas_presenta_02 | La cámara baja | off | «Aquí todo se cuenta: las estrellas, las ventanas... ¡hasta los bostezos!» | nueva |
| narr_cuentacuentas_aterriza | Al bajar | escena | «Aterrizaje en tres, dos, uno... ¡bonk! Le doy un 7. Contado con los dedos.» | nueva |
| narr_cuentacuentas_anfitrion | Aparece el Profesor Plumas | escena | «¡El Profesor Plumas! Es un búho que cuenta hasta el infinito... y un poquito más.» | nueva |
| narr_taller_4_01 | Video del taller | off | «El Profesor Plumas nos regaló el motor derecho, con sus ventanitas numeradas.» | nueva |
| narr_taller_4_02 | El motor encaja | off | «¡Dos alas y dos motores! Son cuatro piezas. ¿Cuántas faltan? ¡Dos!» | nueva |
| narr_cuentacuentas_llamada_abre | Suena la pantalla | escena | «Llamada entrante... a la una, a las dos... ¡y a las tres!» | nueva |
| narr_cuentacuentas_llamada_cierra | Se corta | off | «Ciento veinte patitos de goma... ¡y papá los contó todos! Está muy entretenido. Seguimos.» | nueva |
| narr_album_plumas | Álbum | off | «¡El Profesor Plumas ya está en mi álbum! Me dio un abrazo... y lo contó: uno.» | nueva |
| narr_viaje_letralandia_01 | Sale la nave | off | «Próxima parada: el Planeta Letralandia, donde las letras vuelan como pajaritos.» | nueva |
| narr_viaje_letralandia_02 | Algo flota frente a la nave | off | «¡Otra cosita del Coleccionauta, flotando en el espacio! Esta vez... su gorro de dormir.» | nueva |
| narr_viaje_letralandia_03 | Sigue el viaje | off | «Un calcetín, un gorro... Si sigue así, ¡va a llegar a su casa en pijama! Jiji.» | nueva |

**Videollamada (voz de papá, propuesta, otra tanda):**
- `cuentacuentas_papa_01`: «¿Saben cuántos patitos de goma tiene el Coleccionauta? Los conté: ¡ciento veinte! Y uno me guiñó el ojo.»
- `cuentacuentas_papa_02`: «Sigan contando estrellas tranquilos, que yo estoy feliz contando patitos.»

### 3.4 Planeta Letralandia (Lila · antena con banderines)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_letralandia_presenta_01 | En órbita | off | «¡El Planeta Letralandia! Tiene montañas con forma de letras y ríos llenos de cuentos.» | nueva |
| narr_letralandia_presenta_02 | La cámara baja | off | «Aquí, leer es un superpoder. ¡Y cada letra tiene su propio sonido!» | nueva |
| narr_letralandia_aterriza | Al bajar | escena | «¡Aterrizamos justo arriba de la letra O! Rodamos un poquito... un 8 de 10.» | nueva |
| narr_letralandia_anfitrion | Aparece Lila | escena | «¡Ella es Lila, la dragoncita lectora! Su fuego no quema: ¡ilumina los libros!» | nueva |
| narr_taller_5_01 | Video del taller | off | «Lila nos regaló la antena, con banderines que bailan con el viento.» | nueva |
| narr_taller_5_02 | La antena encaja | off | «Con la antena, la nave escucha mensajes de muy, muy lejos. ¡Cinco piezas puestas!» | nueva |
| narr_letralandia_llamada_abre | Suena la pantalla | escena | «La pantalla dice... P, A, P, A. ¡Es papá!» | nueva |
| narr_letralandia_llamada_cierra | Se corta | off | «¡El Coleccionauta ya escribe su nombre! Bueno, casi. Papá está feliz. Seguimos.» | nueva |
| narr_album_lila | Álbum | off | «¡Lila ya está en mi álbum de abrazos! Un abrazo calentito, de dragón.» | nueva |
| narr_viaje_corazon_01 | Sale la nave; la antena se enciende | off | «¡La antena nueva atrapó un mensaje! Es la voz del Coleccionauta, cantando bajito.» | nueva [Confirmar PO] |
| narr_viaje_corazon_02 | Se oye la canción (efecto, sin otra voz encima) | off | «"Tengo mil cosas en mi colección... pero nadie con quien jugar." ¿Escucharon eso?» | nueva [Confirmar PO] |
| narr_viaje_corazon_03 | Cometa, pensativo y cariñoso | off | «Creo que mi viejo amigo se siente solito. Vamos al Planeta Corazón: ahí saben mucho de sentimientos.» | nueva [Confirmar PO] |

**Videollamada (voz de papá, propuesta, otra tanda):**
- `letralandia_papa_01`: «¡Hola, mis lectores! Le estoy enseñando las letras al Coleccionauta. Ya escribe su nombre... con como diez letras de más.»
- `letralandia_papa_02`: «Sofía, Nicole, Maxi: los quiero con todas las letras.»

### 3.5 Planeta Corazón (Mimi · corazón de la nave, la última pieza)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_corazon_presenta_01 | En órbita | off | «¡El Planeta Corazón! Es suavecito como un cojín, y sus nubes cambian de color con lo que sienten.» | nueva |
| narr_corazon_presenta_02 | La cámara baja | off | «Si alguien está feliz, el cielo se pone rosado. Si alguien está triste, se pone celeste... y todos lo abrazan.» | nueva |
| narr_corazon_aterriza | Al bajar, sobre una nube | escena | «¡El mejor aterrizaje de mi vida! Sobre una nube... ¡un 10 de 10! Bueno... nueve y medio.» | nueva |
| narr_corazon_anfitrion | Aparece Mimi | escena | «¡Ella es Mimi, la nube! Cuando se pone contenta... ¡llueve confeti!» | nueva |
| narr_corazon_secreto_01 | Después de los juegos, antes de la pieza | escena | «Les voy a contar un secreto. El Coleccionauta y yo éramos los mejores amigos.» | nueva |
| narr_corazon_secreto_02 | Sigue | escena | «Pero él empezó a juntar cosas y más cosas... y yo prefería juntar amigos. Y cada uno se fue por su lado.» | nueva |
| narr_corazon_secreto_03 | Mira a los tres hermanos | escena | «Yo nunca supe explicarle que un amigo no se guarda en una caja. Pero ustedes... creo que ustedes sí pueden.» | nueva |
| narr_taller_6_01 | Video del taller | off | «Mimi nos regaló la última pieza: el corazón de la nave.» | nueva |
| narr_taller_6_02 | El núcleo se enciende y toda la nave brilla | off | «¡Miren cómo brilla! Seis piezas... ¡la nave-estrella está completa!» | nueva |
| narr_corazon_llamada_abre | La pantalla se pone rosada | escena | «La pantalla se puso rosadita... ¡es papá!» | nueva |
| narr_corazon_llamada_cierra | Se corta | off | «El Coleccionauta tiene una foto de nosotros dos, de chiquitos... Hermanos Estelares, ¡vamos a buscarlos!» | nueva |
| narr_album_mimi | Álbum | off | «¡Mimi ya está en mi álbum de abrazos! Es el abrazo más blandito de todos.» | nueva |

**Videollamada (voz de papá, propuesta, otra tanda):**
- `corazon_papa_01`: «Oigan... el Coleccionauta me mostró una foto de él y Cometa, chiquititos. Creo que lo extraña.»
- `corazon_papa_02`: «Nos vemos muy pronto, campeones. Y traigan abrazos: acá hay alguien que necesita uno.»

---

## Acto 4 — El planeta del Coleccionauta y la vuelta a casa

### 4.1 El gran viaje (video B6)

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_viaje_final_01 | Despega la nave completa | off | «La nave-estrella está completa. ¡Es la hora del gran viaje, al planeta del Coleccionauta!» | nueva |
| narr_viaje_final_02 | La nave cruza la galaxia | off | «Es el planeta más lejano de todos. Pero con seis piezas y tres Hermanos Estelares... ¡llegamos seguro!» | nueva |
| narr_viaje_final_03 | Aparece el planeta lleno de torres | off | «Miren allá: torres de patitos de goma, conos y globos de nieve. ¡Es su colección!» | nueva |
| narr_final_aterriza | Al bajar | escena | «Último aterrizaje... ¡perfecto! ¿Vieron? Después de seis planetas, por fin aprendí. Jiji.» | nueva |

### 4.2 La prueba final (`prueba_final_cooperativa.md`)

Se mantienen las líneas de Cometa en escena: `final_002` («¡Hola, viejo amigo! Te presento a los Hermanos
Estelares.»), `final_010`, `final_020` («¿Y si probamos... juntos? Cada uno hace lo que mejor sabe hacer, pero
esta vez, de a uno.») y `final_038` («Se los dije... los amigos son la mejor colección.»). Narración nueva:

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_final_equipo | Después de `final_032` («¡funcionó!»), antes del rescate | off | «Sofía leyó la pista, Nicole hizo un amigo y Maxi encontró las llaves. ¡Así juegan los Hermanos Estelares!» | nueva |
| narr_final_album | Antes de `final_038`, Cometa abre el álbum | escena | «Coleccionauta... en mi álbum de abrazos queda una página libre. ¿Me das uno?» | nueva |

### 4.3 La vuelta a casa (video B7) y el final del cuento

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_regreso_01 | La nave vuela de noche hacia la Tierra | off | «Y así, la nave-estrella volvió a casa con papá a bordo... y con un amigo nuevo.» | nueva |
| narr_regreso_02 | La nave baja al patio | off | «Aterrizamos en el patio, despacito, despacito... para no despertar a nadie.» | nueva |

→ Beat 8 de la prueba final: el living real, papá entra y los llama a comer (`final_039` a `final_044`).

| id | Cuándo | Tipo | Cometa dice | Estado |
|---|---|---|---|---|
| narr_epilogo_01 | Después de `final_044` («¡Siiií!»), still del living | off | «Y colorín colorado... esta aventura se ha terminado. ¿O no?» | nueva |
| narr_epilogo_02 | Paneo a la ventana: pasa una estrellita | off | «Porque cada vez que tres hermanos juegan juntos en el living... ¡puede empezar otra!» | nueva |
| narr_epilogo_03 | Última imagen | off | «Gracias por viajar conmigo, Hermanos Estelares. Ustedes son la mejor página de mi álbum.» | nueva |

---

## Acto 5 — Menús: Cometa recibe, recuerda y guía

### 5.1 Título y selección

| id | Cuándo | Cometa dice | Estado |
|---|---|---|---|
| nucleo_titulo_primera_vez | Primera vez que se abre el juego | «¡Hola! Soy Cometa. ¿Quieren escuchar una aventura? ¡Toquen la pantalla!» | nueva |
| titulo_bienvenida_01 | Título; cada ~12 s sin toque | «¡Toca la pantalla para comenzar la aventura!» | existente |
| nucleo_titulo_vuelta_01 | Al volver otro día | «¡Volvieron! Los estaba esperando. Toquen la pantalla y seguimos.» | nueva |
| seleccion_invitacion_01 | Selección de personaje | «¿Quién va a jugar? ¡Toca a tu Hermano Estelar!» | existente |
| nucleo_seleccion_maxi | Al tocar a Maxi | «¡Maxi, el explorador valiente!» | nueva |
| nucleo_seleccion_nicole | Al tocar a Nicole | «¡Nicole, la amiga de todos!» | nueva |
| nucleo_seleccion_sofia | Al tocar a Sofía | «¡Sofía, la capitana de la misión!» | nueva |
| nucleo_seleccion_invitacion_equipo | Botón de juego en equipo | «¿Y si juegan juntos? ¡Toquen la nave!» | existente |

### 5.2 "¿Se acuerdan?": Cometa cuenta dónde quedó la historia (al entrar al Mapa Estelar otro día)

Suena una vez por sesión, según el avance guardado. Es lo que hace que la historia se sienta continua
aunque jueguen de a ratitos.

| id | Avance guardado | Cometa dice | Estado |
|---|---|---|---|
| nucleo_recuerdo_arcoiris_gris | Arcoíris empezado, sin pieza | «¿Se acuerdan? El Planeta Arcoíris se quedó gris, y Coco necesita sus colores. ¡Vamos a ayudarla!» | nueva |
| nucleo_recuerdo_arcoiris_pieza | Ya tienen el ala, falta la batalla | «La última vez, Coco nos regaló el ala. Pero todavía quedan rincones grises... ¡y alguien con una mochila muy llena!» | nueva |
| nucleo_recuerdo_arcoiris_completo | Arcoíris terminado | «¡El Planeta Arcoíris ya brilla entero! Y el mapa del Coleccionauta apunta a Animalia.» | nueva |
| nucleo_recuerdo_planeta | Planeta 2 a 6 en curso (genérico, mientras no tengan su línea propia) | «¿Se acuerdan dónde íbamos? ¡Seguimos la aventura justo ahí!» | nueva |
| nucleo_recuerdo_final | Nave completa | «La nave-estrella está completa. ¡El planeta del Coleccionauta nos espera!» | nueva |

### 5.3 Mapa Estelar y hangar

| id | Cuándo | Cometa dice | Estado |
|---|---|---|---|
| nucleo_mapa_primera_vez_01 | Primera vez en el Mapa Estelar | «Este es el Mapa Estelar. Aquí están todos los planetas de nuestro viaje.» | nueva |
| nucleo_mapa_primera_vez_02 | Enseguida; brilla el planeta del Coleccionauta | «Y allá, lejito, el planeta del Coleccionauta. Ahí está papá, tranquilo y feliz.» | nueva |
| nucleo_mapa_lejos | Al tocar un planeta que aún no se alcanza | «Ese planeta todavía está muy lejos. ¡Con más piezas, la nave va a llegar!» | nueva |
| nucleo_mapa_coleccionauta | Al tocar el planeta del Coleccionauta antes de tiempo | «¡Ahí vive el Coleccionauta! Primero armamos la nave, y después... ¡vamos por papá!» | nueva |
| arcoiris_invitacion_01 … corazon_invitacion_01 | Al tocar un planeta disponible | «¡Vamos al Planeta Arcoíris!» (y uno por planeta) | existente |
| nucleo_hangar_primera_vez | Primera vez en el hangar | «¡Bienvenidos al hangar! Aquí vemos cómo va quedando nuestra nave, pieza por pieza.» | nueva |
| nucleo_hangar_falta_1 | Al tocar el hueco del ala izquierda | «Aquí va el ala izquierda. ¡La guarda Coco, en el Planeta Arcoíris!» | nueva |
| nucleo_hangar_falta_2 | Hueco del ala derecha | «Aquí va el ala derecha. ¡La guarda Toby, en el Planeta Animalia!» | nueva |
| nucleo_hangar_falta_3 | Hueco del motor izquierdo | «Aquí va el motor izquierdo. ¡Lo guarda Octavio, en el Planeta Melodía!» | nueva |
| nucleo_hangar_falta_4 | Hueco del motor derecho | «Aquí va el motor derecho. ¡Lo guarda el Profesor Plumas, en el Planeta Cuenta-Cuentas!» | nueva |
| nucleo_hangar_falta_5 | Hueco de la antena | «Aquí va la antena. ¡La guarda Lila, en el Planeta Letralandia!» | nueva |
| nucleo_hangar_falta_6 | Hueco del corazón de la nave | «Aquí va el corazón de la nave. ¡Lo guarda Mimi, en el Planeta Corazón!» | nueva |
| nucleo_hangar_puesta_1 | Al tocar el ala izquierda puesta | «El ala de Coco. ¡Brilla con los colores del Arcoíris!» | nueva |
| nucleo_hangar_puesta_2 | Ala derecha puesta | «El ala de Toby, con su huellita pintada. ¡Guau!» | nueva |
| nucleo_hangar_puesta_3 | Motor izquierdo puesto | «El motor de Octavio. ¡Suena como una trompeta!» | nueva |
| nucleo_hangar_puesta_4 | Motor derecho puesto | «El motor del Profesor Plumas, con sus ventanitas numeradas.» | nueva |
| nucleo_hangar_puesta_5 | Antena puesta | «La antena de Lila. ¡Sus banderines bailan con el viento!» | nueva |
| nucleo_hangar_puesta_6 | Corazón de la nave puesto | «El corazón de la nave, regalo de Mimi. ¡Hace brillar todo!» | nueva |

### 5.4 Tocar a Cometa, salir y despedirse

| id | Cuándo | Cometa dice | Estado |
|---|---|---|---|
| nucleo_cometa_toque_01 | Tocar a Cometa sin nada que repetir | «¡Jiji, me hiciste cosquillas!» | nueva |
| nucleo_cometa_toque_02 | Otra vez | «¿Sabían que mi nave brilla como una estrella? ...Bueno, cuando no está chocada.» | nueva |
| nucleo_cometa_toque_03 | Otra vez | «Mi álbum de abrazos se va llenando, ¿vieron? ¡Gracias a ustedes!» | nueva |
| nucleo_volver_mapa | Botón de volver al mapa | «¿Volvemos al mapa? Todo lo que jugaron queda guardado.» | nueva |
| nucleo_despedida | Al salir del juego | «¡Hasta la próxima, Hermanos Estelares! La nave los espera.» | nueva |
| nucleo_pista_confirmar | Pista que cuesta una estrellita | «¿Te soplo una pista? Cuesta una estrellita. ¡Toca el globito si la quieres!» | existente |
| nucleo_pista_gratis | Pista de regalo | «¡Esta pista va de regalo! Mira, mira...» | existente |

El álbum de recuerdos (`recuerdos.md`) se mantiene como está: sus líneas ya cuentan la historia de las fotos
de papá.

---

## 6. Lo que este guion cambia en los guiones actuales

- **Se reemplaza** `intro_viaje_01` por `narr_viaje_tierra_01` a `_03`.
- **Se quita** `intro_018c` (las llaves quedan para el Coleccionauta en `final_011`).
- **Se agrega** la apertura y el cierre de Cometa en todas las videollamadas (antes solo existía `arcoiris_010`).
- **Líneas de juego a revisar aparte** (no entran en esta tanda): las series `nucleo_equipo_piezas_puestas_1..11`
  y `nucleo_equipo_pares_juntados_1..12` («¡Igual pusimos/juntamos X...!») son 23 variantes casi iguales. Se
  propone dejarlas en 3 variantes sin número, que el juego muestra con el contador en pantalla.

## 7. Conteo para el PO

| Bloque | Líneas nuevas de Cometa |
|---|---|
| Acto 1 — Tierra | 13 |
| Acto 2 — Arcoíris | 17 |
| Acto 3 — Planetas 2 a 6 | 61 |
| Acto 4 — Final | 11 |
| Acto 5 — Menús | 32 (incluye 12 del hangar) |
| **Total nuevas** | **134** |

Más las ~60 líneas existentes de Cometa en escena que se mantienen. Las videollamadas de papá de los planetas
2 a 6 (10 líneas) son voz de papá y van en otra tanda.

## 8. Preguntas para el PO

1. **El mensaje de la antena** (viaje a Corazón): el Coleccionauta cantando «tengo mil cosas... pero nadie con
   quien jugar». Es un momento algo emotivo, no triste ni de miedo, y prepara el final. ¿Va?
2. **El secreto de Cometa** en el Planeta Corazón: cuenta por qué él y el Coleccionauta se separaron. ¿Te gusta
   que lo cuente ahí, antes del viaje final?
3. **Los ganchos de los planetas 2 a 6** (qué se llevó o qué dejó caer el Coleccionauta en cada uno) quedan
   como propuesta hasta que se escriba cada planeta.
4. **«Colorín colorado»** para el final: ¿te suena bien, o prefieres otro cierre de cuento?
