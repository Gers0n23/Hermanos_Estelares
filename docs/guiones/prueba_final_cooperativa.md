# Guion — La prueba final cooperativa: «El coleccionista más solito de la galaxia»

> Guion narrativo (HE-D5), responde a la parte narrativa de P6 del GDD §9 (diseño detallado de la
> prueba final cooperativa). **No resuelve** el diseño de UI/flujo de turnos del modo misión
> familiar — eso sigue abierto para `disenador-mecanicas` + PO; este documento entrega la historia
> y los diálogos que ese flujo debe respetar.
> Fuente de verdad: `docs/diseno-juego.md` §1 (lección de cooperación), §2 (personajes y gestos
> canon), §3 (modo misión familiar), §6 (salvaguardas de tono).

- **Disparador**: se abre al reunir las 6 piezas de la nave-estrella (planeta final, GDD §3).
- **Duración estimada**: 2-3 min de cinemática + el minijuego cooperativo interactivo en sí
  (Beats 3-5), pensado para jugarse en **modo misión familiar** (turnos, los tres a la vez).
- **Personajes**: Maxi, Nicole, Sofía, Cometa, El Coleccionauta, Papá.
- **Escenario**: planeta final, hogar del Coleccionauta.

## Salvaguardas de tono (repetidas explícitamente — máxima prioridad en esta escena)

1. El Coleccionauta es **cómico y torpe, jamás amenazante** — ni su voz, ni su actitud, ni el
   entorno deben leerse como villanía real en ningún momento de la escena.
2. Papá se ve **cómodo en todo momento** — su "encierro" es literalmente un rincón de cojines con
   una llave de juguete, nunca una jaula ni nada que sugiera peligro real.
3. La "prueba" es **un juego, no un obstáculo punitivo**: se presenta como algo divertido de
   resolver, nunca como un examen que se pueda "reprobar" de verdad.
4. El **primer intento fallido debe hacer reír, nunca doler ni frustrar** — cuidado especial con
   Sofía (GDD §2: "se frustra rápido, es llorona"): su reacción al fracaso es humor, no lágrimas.
5. Nadie regaña a nadie durante el caos del primer intento — ni Cometa, ni los hermanos entre sí,
   ni el Coleccionauta.

---

## Beat 1 — Llegada y bienvenida (torpe, no villana)

**Acotación**: la nave-estrella (ya con sus alas puestas y propulsores grandes, estado armado)
aterriza en un jardín/patio desordenado y alegre, lleno de objetos disparatados apilados con
cariño (un patito de goma gigante, un cono de tránsito con lazo, un globo de nieve enorme). El
Coleccionauta los recibe agitando los bracitos, su mochila-torre tambaleándose sin caer nunca
(gag de suspenso cómico recurrente, ver su ficha de personaje).

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_001 | Coleccionauta | «¡Bienvenidos a la colección más increíble, asombrosa, fabulosa de tooooda la... espera, ¿dónde dejé mis anteojos-lupa? Ah. Los tengo puestos.» | grandilocuente que se pierde en un detalle chico (su tic) |
| final_002 | Cometa | «¡Hola, viejo amigo! Te presento a los Hermanos Estelares.» | cálido, cómplice — se conocen de siempre |
| final_003 | Coleccionauta | «¡Cometa! Cuánto tiempo... ¿todavía coleccionas amigos en vez de cosas? Qué raro eres.» | nostálgico, torpe-tierno, con cariño (no burla) |
| final_004 | Sofía | «Venimos por nuestro papá.» | directa, líder, sin miedo |
| final_005 | Coleccionauta | «¡Ah, sí! El papá más increíble que encontré en años. Está por acá, muy cómodo.» | orgulloso de su hallazgo, sin maldad |

**Acotación**: se ve a papá sentado en un rincón acolchado hecho de cojines disparejos de la
colección, tomando algo parecido a un té, absolutamente tranquilo.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_006 | Papá | «¡Hola, mis amores! Miren, me hicieron mi propio rincón. Hasta tiene wifi... es broma, no hay wifi, por eso los extraño tanto.» | bromista, feliz de verlos, cero angustia |
| final_007 | Maxi | «¡Papi!» | grito de alegría |
| final_008 | Papá | «¡Mi campeón! Oye, ¿ya aprendiste a saltar más alto?» | le sigue el juego, cero drama |

## Beat 2 — El Coleccionauta explica la prueba (grandilocuente → chico)

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_009 | Coleccionauta | «Para llevarse lo más increíble de mi colección, deben superar... ¡LA PRUEBA MÁS DIFÍCIL DEL UNIVERSO CONOCIDO! O bueno... es más o menos mediana. Le puse mucha purpurina, eso sí.» | tic grandilocuente→chico, cómico |
| final_010 | Cometa | «Tranquilos, chiquillos, esto es puro juego. Nada de qué preocuparse.» | aclara explícitamente: sin presión ni miedo |
| final_011 | Coleccionauta | «Solo tienen que... ordenar mi colección. Nada más. Ah, y encontrar mis llaves. Y quizás hacerme un amigo. Bueno, son tres cositas.» | torpe, entusiasta, sin saber que ya spoileó la lección |

## Beat 3 — Primer intento: cada uno a su manera (fracaso cómico)

**Acotación**: los tres se lanzan a la vez, cada uno con su estilo, sin coordinarse entre ellos.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_012 | Sofía | «Yo leo las instrucciones primero, esperen—» | quiere liderar, la interrumpen |
| final_013 | Nicole | «¡Ya hice tres amigos nuevos aquí adentro!» | ya está charlando con objetos/mascotas de la colección |
| final_014 | Maxi | (gritando, ya trepando la pila) «¡¡Encontré algo!!» | impulsivo, feliz |
| final_015 | Sofía | «¡Maxi, espera, se va a caer la—!» | alarma cómica, no real |

**Acotación**: la pila se tambalea, un cojín sale volando, y la nave —que estaban usando de
apoyo— hace un "achú" cómico y suelta una nubecita de humo de colores. El Coleccionauta se ríe
encantado. Nadie se hace daño, nadie se asusta.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_016 | (sfx) | *estornudo de nave* + objetos cayendo en cascada suave (todo acolchado) | cómico, mullido, sin golpes reales |
| final_017 | Coleccionauta | (riendo) «¡Jajaja, eso fue lo más divertido que he visto en años! Pero... siguen sin encontrar mis llaves.» | se ríe CON ellos, nunca con maldad |
| final_018 | Nicole | (riendo también) «¡Uy, perdón, perdón!» | se ríe de sí misma |
| final_019 | Sofía | (un poco frustrada pero con humor, sin llorar) «Ok, eso... no funcionó.» | frustración leve resuelta con humor — cuidado especial, ver salvaguarda 4 |

## Beat 4 — Cometa señala el camino (pregunta, no regaño)

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_020 | Cometa | «¿Y si probamos... juntos? Cada uno hace lo que mejor sabe hacer, pero esta vez, de a uno.» | guía suave, nunca ordena ni regaña |
| final_021 | Sofía | «...Yo puedo leer el plan primero.» | reflexiona, propone |
| final_022 | Nicole | «¡Y yo puedo preguntarle a nuestro amigo dónde deja las cosas!» | mira al Coleccionauta con cariño genuino |
| final_023 | Maxi | «¡Yo encuentro!» | listo, esperando su turno esta vez |
| final_024 | Coleccionauta | «¿Amigo? ¿Yo?» | sorprendido, tierno, sin saber aún lo que se viene |

## Beat 5 — Cooperación por roles (el corazón de la escena)

### 5a — Sofía lidera y lee la pista

**Acotación**: Sofía encuentra una notita/cartel en la colección (letras grandes y simples) y la
lee en voz alta, armando el plan para sus hermanos.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_025 | Sofía | «Dice acá: "las llaves están donde nadie mira dos veces". Maxi, eso es para ti.» | líder, orgullosa de su hallazgo |

### 5b — Nicole se hace amiga del Coleccionauta (el gesto que enseña sin sermón)

**Acotación**: mientras Maxi busca, Nicole se sienta junto al Coleccionauta, saca uno de sus
dibujos (el mismo tipo de dibujo que hizo en el Planeta Arcoíris) y se lo regala.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_026 | Nicole | «Toma, es para ti. Te dibujé a ti y a Cometa de amigos, como antes.» | cálida, generosa, sin esperar nada a cambio |
| final_027 | Coleccionauta | «¿Para... para mí? Nadie me había regalado algo así. Solo coleccionan cosas conmigo, nunca me regalan nada.» | vulnerable, tierno — momento clave, sin sermón explícito |
| final_028 | Nicole | «Es que los amigos no se juntan, ¡se hacen regalando cositas y jugando!» | dice la lección de forma natural e infantil, no como sermón |
| final_029 | Coleccionauta | (voz un poco temblorosa de la emoción, pero feliz) «...Me gusta mucho ser tu amigo.» | conmovido, sincero |

### 5c — Maxi encuentra lo que nadie ve

**Acotación**: Maxi, gateando bajo la pila más desordenada, encuentra las llaves colgando de la
cola de un peluche olvidado en un rincón — exactamente "donde nadie mira dos veces".

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_030 | Maxi | «¡¡Llaves!!» | grito triunfal, sin duda |
| final_031 | Coleccionauta | «¡Mis llaves! ¡Las buscaba desde hace... mucho, mucho tiempo!» | sorpresa genuina y alegre |
| final_032 | Sofía | «Equipo Estelares, ¡funcionó!» | orgullo de líder, mirando a sus hermanos |

## Beat 6 — Rescate de papá (sin batalla, con alegría)

**Acotación**: con las llaves, se abre el "rincón cómodo" donde estaba papá (un cerco bajito de
cojines con una llave de juguete — nunca una jaula) y papá sale estirándose, feliz.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_033 | Papá | «¡Al fin! Aunque las galletas de acá estaban riquísimas, así que no hay apuro.» | bromista, calmo, cero drama de escape |
| final_034 | Maxi / Nicole / Sofía | *(celebración con gestos canon — ver `guion_voces.md`)* «¡¡Siiii!!» / «¡Lo logramos!» / «Misión cumplida, Hermanos Estelares.» | fiesta total, gestos reales de cada uno |
| final_035 | Papá | (abrazando a los tres) «Estoy tan orgulloso de ustedes tres. Trabajar en equipo... eso sí que es increíble.» | cálido, celebra la acción sin sermonear |

## Beat 7 — El Coleccionauta se une a la familia

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_036 | Coleccionauta | «Oigan... ¿puedo ir a visitarlos? Prometo no traer TODA mi colección. Bueno, un poquito.» | cómico, entrañable, ya cambiado |
| final_037 | Nicole | «¡Claro que sí! Ya eres nuestro amigo.» | cálida, incondicional |
| final_038 | Cometa | «Se los dije... los amigos son la mejor colección.» | cierra el círculo temático sin sermonear, frase corta |

## Beat 8 — Vuelta a casa (bookend con la intro)

**Acotación**: corte de vuelta al living real; los mismos niños sentados en la alfombra, como si
nunca se hubieran ido (toda la aventura fue su juego imaginado, GDD §1). Papá real entra por la
puerta del living.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| final_039 | Papá | «¡Hola, mis campeones! ¿Jugando a los astronautas de nuevo?» | cotidiano, cálido |
| final_040 | Sofía | «Algo así. Rescatamos a alguien muy importante.» | guiño cómplice, juguetón |
| final_041 | Papá | «¿A quién?» | sigue el juego |
| final_042 | Maxi | «¡A ti!» | directo, feliz |
| final_043 | Papá | (riendo, siguiéndoles el juego) «Ah, con que a mí. Bueno, gracias por el rescate. ¿Vamos a comer?» | cierre cálido, sin presión, invita a algo cotidiano |
| final_044 | Todos | «¡Siiií!» | coro feliz |

---

## Notas para `disenador-mecanicas` / `director-cinematicas` / `dev-godot`

- **Beat 3** (fracaso cómico) y **Beat 5** (cooperación por roles) son el corazón jugable de esta
  escena — sugerido implementarlos como el minijuego cooperativo real del modo misión familiar
  (turnos: Sofía → Nicole → Maxi), no solo como cinemática pasiva. El flujo de turnos y la UI de
  "le toca a..." siguen siendo diseño abierto de P6 (GDD §9); este guion define **qué pasa en cada
  turno**, no cómo se implementa la mecánica de turnos en pantalla.
- **Beat 6**: el "rincón cómodo" de papá debe dibujarse desde el inicio (Beat 1) sin ningún
  elemento que sugiera encierro real — se recomienda a `disenador-personajes`/arte que sea
  indistinguible de un rincón de living con cojines, solo que dentro de la colección del
  Coleccionauta.
- Las líneas `celeb_maxi_01`, `celeb_nicole_01`, `celeb_sofia_01` de `final_034` son las mismas
  líneas genéricas de celebración reutilizadas en las escenas de planeta (ver `guion_voces.md`) —
  no se re-graban distintas para esta escena.
