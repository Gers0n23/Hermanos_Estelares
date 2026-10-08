# Guion de voz — Batalla final del Planeta Arcoíris (HE-67)

> Encargo de HE-67. **Versión 2 (07-Oct-2026)**, alineada con:
>
> - `docs/fichas/modo-equipo.md` **v6** (07-Oct-2026): §5.2 (tope y turno perfecto), §8, §11.4 (claves
>   genéricas `derrota_gag_equipo` y `logro_comun`), §14 completo y §14.15; y lo ya escrito de la
>   **v6.1** (§4.3: resbalón del pase y N13; §5.2: N8 y guirnalda de lucecitas N9);
> - el storyboard `docs/cinematicas/batalla_arcoiris.md` (HE-68), en especial su §14 ("Para
>   `guionista`");
> - la calibración `docs/fichas/calibracion-batalla-arcoiris-y-parejas-equipo.md` **v3** (§4 y §8);
> - la "Verificación N2/N3/N6" de `docs/validaciones/2026-10-06_ux-HE-66-batalla-arcoiris.md` (N8, N11
>   y N13).
>
> Formato y convenciones: `docs/guiones/voces-modo-equipo-parejas.md`, cuyas líneas **se reutilizan, no
> se duplican** (§9 de este guion).
>
> Este guion es **solo texto**: no genera audio ni toca los `.tsv`. Cuando el PO apruebe el costo del
> TTS, `dev-godot` copia las filas TTS a su `lineas_tts.tsv` (con la directiva `# personaje:` correcta),
> y las líneas caseras se graban en familia.

## Cambios de la versión 2 (07-Oct-2026)

1. **Antenas, no orejas** (storyboard §14.1): `arcoiris_batalla_rio_coco_risa` dice ahora "¡hasta por
   las antenas!". El Coleccionauta no tiene orejas visibles.
2. **Interludio** (storyboard §7.2 y §14.4): el orden del §7 queda estornudo → `zona_<n>_completada`
   (Coco) → `livianita_<n>` (Coleccionauta). En la batalla, `zona_2_completada` **se corta después de
   "¡amarillo limón!"** (§7).
3. **Gafas rojas** (storyboard §6 y §14.3): reutilizan `arcoiris_batalla_rio_coleccionauta_reacciona_02`.
   No hay línea nueva.
4. **Turno perfecto (v6)**: Formas y Parejas usan `nucleo_equipo_turno_perfecto_01/02` (Cometa) +
   `rival_retrocede`, y el Río usa la racha de 3. **Se retira**
   `arcoiris_batalla_formas_retrocede_celebra` ("¡Tres piezas seguidas!" sería falso para Nicole, que
   tiene tope 2). También se retira la nota 2 del §10 de la v1.
5. **N8: el tope se explica por voz, en positivo.** Se reescriben las intros de Formas y Parejas
   ("¡Por turnos! Si hay pareja, sigues... ¡hasta prender tus lucecitas!"), apuntando a la guirnalda de
   lucecitas (ficha v6.1, N9). La `repetir` de Cometa tiene una variante por perfil con la meta y su
   número ("¡Si prendes tus dos lucecitas, turno perfecto!"). Se suma
   `nucleo_equipo_turno_perfecto_presenta`, que explica qué pasó la primera vez.
6. **N11**: Parejas en la batalla usa `pares_juntados_1..11` (12 pares en 4×6); `retrocede_celebra` de
   Parejas («¡Tres parejas seguidas!») **no suena** en la batalla; y "¡seguimos donde quedamos!" suena
   al tocar "¡Despegar!" en la pantalla corta de "¡todos a la nave!", como fija §14.6.
7. **N13**: `arcoiris_equipo_guardala` («¡Guárdala para tu próximo turno!»), de Coco, una vez por
   partida, **solo en Parejas** (clave `guardala_proximo_turno`, ficha v6.1 §4.3).
8. **Claves genéricas** (v6, §11.4): la derrota y el logro común van en `lineas_voz.derrota_gag_equipo`
   y `lineas_voz.logro_comun`. Parejas usa `pares_juntados` como respaldo. Se descarta el bloque
   `equipo.voces_batalla` que proponía la v1.
9. **Versión corta de "¡todos a la nave!"** para retomar: `nucleo_batalla_todos_nave_corta`.
10. **Claves `PENDIENTE` de los datos**: todas tienen línea o una decisión "sin voz" justificada. Tabla
    clave → id para Dev en el §10.1. Para eso se suman `arcoiris_batalla_formas_nuestra_nave` (Coco) y
    `arcoiris_batalla_parejas_lupa_gafas` (Coleccionauta).
11. **[PO, 07-Oct-2026] El resbalón del pase** (ficha v6.1, UX N10): después de un turno perfecto el
    Coleccionauta intenta saltar, se resbala y no avanza. Se suman dos reacciones cortas suyas
    (≤ 1,5 s, papá): `nucleo_equipo_coleccionauta_resbala_01/02` (§5.3).
12. **HE-60 (Parejas en solitario, B1 de su validación UX)**: las voces de `voces/arcoiris/emparejar/reto/`
    (`vela_presenta`, `vela_dormida`, `vistazo_mira`, etc.) **ya tienen guion** en
    `voces-modo-equipo-parejas.md` §6; no se duplican aquí (§13).
13. **Cierres de la intro de trucos** (`intro_equipo_trucos.equipo` y `.equipo_racha`, ficha §8,
    pendientes 1 y 2): escritos en `voces-modo-equipo-parejas.md` §3.1 (v3), junto con la `intro` con
    tope y el fragmento de Sofía reescrito. No suenan en la batalla.

---

- **Tono de referencia**: GDD §1 (salvaguardas de tono, derrota-gag), §2 (Cometa y el Coleccionauta),
  `perfil-jugadores.md`, el tic de Coco de `zonas_arcoiris.md` (anuncia el color que "es" ahora: rojo
  frutilla, amarillo limón, azul chupetín) y el tic del Coleccionauta (habla en grande y se equivoca en
  chico).
- **Voces**:
  - **Coco** y **Cometa**: voz oficial TTS (fal.ai). **Generar solo con `--estimar` y con el OK del PO
    sobre el costo.**
  - **El Coleccionauta**: **grabación casera de papá**, registro "grandilocuente-tonto". Canon:
    **gafas-lupa, antenas con bolitas y mochila-torre**. Sin monóculo, sin caja, sin nave-aspiradora y
    sin red. **Nunca menciona a papá** en la batalla, y les roba los colores al cielo **solo dentro de la
    escena de la batalla** (el mapa nunca pierde color, M3).
  - **Papá** (él mismo, en la video-llamada): grabación familiar, **si el PO lo decide** (§14.10,
    parte B; backlog del álbum §9, idea 4).
  - **Los niños** (opcional): Maxi, Nicole y Sofía con su propia voz. **O se graban los tres o
    ninguno**, con el mismo largo y volumen. Si no existen, la animación va sin voz y no falta nada.
- **Rutas** relativas a `assets/audio/`, en `.wav`:
  - lo genérico de cualquier batalla (también HE-39) va en `voces/nucleo/batalla/`;
  - lo genérico de cualquier juego en equipo (logros comunes, "¡turno perfecto!", "¡ahora…!", las
    `repetir`) va en `voces/nucleo/equipo/`, junto a `pares_juntados_*`;
  - lo propio de esta batalla va en `voces/arcoiris/batalla/` (con subcarpetas `rio/`, `formas/`,
    `parejas/`, `epilogo/` y `cierre/`);
  - lo de Arcoíris en equipo que sirve dentro y fuera de la batalla va en `voces/arcoiris/equipo/`.
- **Id estable**: `nucleo_` + ruta sin `voces/nucleo/` ni extensión; `arcoiris_` + ruta sin
  `voces/arcoiris/` ni extensión. Ej.: `voces/arcoiris/batalla/rio/intro.wav` →
  `arcoiris_batalla_rio_intro`.
- **Duración estimada**: a ritmo de narración infantil (Coco cantarina, Cometa rápido, papá con sus
  pausas de chiste). Es una guía para `director-cinematicas`; la real sale del audio.
- **Estado**: las **114 líneas** de este guion son **nuevas** y están **pendientes de audio**. Además se
  reutilizan **91** líneas ya escritas (§9), sin cambiar su texto ni su archivo.

## Decisiones de tono de este guion

1. **Un rescate, no un robo.** Los colores quedan **contentos** en los pisos de la mochila-torre, y Coco
   lo dice apenas pasa: "¡están guardados ahí! ¡Los vamos a sacar juntos!". El Coleccionauta no
   amenaza: propone un juego ("¡Gánenme tres juegos! ...¿O eran dos?"), y así la batalla es una
   competencia de risa, no un asalto.
2. **Cada estornudo es una victoria.** El gag del estornudo de Parejas se usa a favor del equipo: con
   cada ronda ganada, un piso estornuda su color de vuelta al cielo y el Coleccionauta queda "más
   livianito". Es humor físico y sonoro para Maxi, y nadie pierde nada.
3. **N4: el cierre de una ronda perdida cuenta lo que se conservó en esa ronda.** Nunca "¡igual le
   sacamos el rojo!" (en la ronda 1 todavía no hay ningún color): esa línea **no se escribe**. Cometa
   cuenta, en plural y sin nombres, las gotas, las piezas o las parejas que se quedan (§4.5, §5.5 y la
   reutilización de `pares_juntados_*` en la ronda 3).
4. **N7: una sola frase de intro por ronda, de 4 s o menos.** Ver "Cómo se resolvió N7", abajo.
5. **Nadie falla con nombre; los aciertos de Nicole y Sofía tampoco llevan nombre.** Igual que en el
   guion de Parejas en equipo (decisiones 1 y 2). El Río no tiene fallo (un disparo que no revienta es
   un "plop" neutro, **sin voz**). En Formas, el fallo habla de la pieza, nunca de la persona ("esa
   pieza buscaba otra casita"). Maxi sí escucha su nombre en sus aciertos guiados, y el retroceso del
   rival es "del equipo".
6. **Maxi siempre aporta y se nota.** En el Río, su toque revienta siempre (N2 de la ficha) y, si cayó
   cerca del halo, Coco grita "¡justo ahí!" antes de la fiesta: el reventón es suyo. Si se distrae 20 s,
   "¡Maxi nos dejó un regalito!" convierte la jugada automática en un regalo, no en un reto.
7. **El Coleccionauta es el que más se equivoca.** No sabe contar los juegos, se pinta las gafas-lupa,
   le da hipo de pintura, cree que una pieza es un queque. Siembra la lección sin decirla: "yo meto todo
   en la mochila", "nadie me había regalado nada... bueno, una vez un calcetín", y al final, "un equipo
   no cabe en una mochila". La única frase "de lección" la dice él, rascándose la cabeza, como algo que
   descubrió, nunca como sermón al público.
8. **Los colores se regalan, no se guardan (epílogo).** Los niños pueden decir "¡para ti!" al pintar su
   parte (opcional): la cooperación y la generosidad se ven en acción.
9. **Sin apuro.** Ninguna línea dice "rápido" ni "apúrate". Entre rondas, Coco ofrece descansar ("¿o
   descansamos y volvemos después?"), y la batalla en dos sesiones es el caso normal.
10. **Papá, tranquilo y bromista.** En el teaser se ríe del Coleccionauta ("se tropieza hasta con su
    sombra"), y en la video-llamada final hace un chiste de papá y dice que está feliz. Ninguna línea
    pide que lo rescaten.
11. **[v2] El tope es una meta, no un corte (N8).** Nadie oye "se acabó tu turno". Desde la intro, la
    regla se dice como algo que se logra y que **se ve**: "Si hay pareja, sigues... ¡hasta prender tus
    lucecitas!" (la guirnalda del marco, ficha v6.1 N9). La intro no dice números, porque la oyen los
    tres juntos y no debe sonar a "Sofía tiene más" (R2, equidad); la `repetir` de Cometa sí le dice **al
    que juega** su número ("¡Si prendes tus tres lucecitas, turno perfecto!"). La primera vez que pasa,
    Cometa explica lo que pasó. Si Sofía "sabía otra", Coco le da un plan, no un no: "¡Guárdala para tu
    próximo turno!".
12. **[v2] "Se resbala", no "retrocede".** Las líneas nuevas dicen que el Coleccionauta **se resbala**.
    Es verdad con cualquiera de las dos salidas de N10 que decida el PO (retrocede y se resbala, o solo
    se resbala), y es más gracioso para Maxi.

## Cómo se resolvió N7 (dos voces de intro contra "una frase de 4 s o menos")

**Decisión**: cada ronda tiene **una sola frase hablada**, la de Coco, de **3 s o menos**, con la
regla de turno de ese juego. El Coleccionauta se presenta con **un gag de una sola palabra** (≤ 1,2 s;
en las rondas con tope, ≤ 1 s), que suena **antes** de Coco y **nunca encima**. Total de la intro:
**4 s o menos**.

| Ronda | Gag del Coleccionauta (1 palabra) | Frase de Coco | Total |
|---|---|---|---|
| Río | «¡Pintuuura!» (se asoma al río con las gafas-lupa y se pinta la nariz de rojo), 1,2 s | «¡Por turnos: cada uno tira sus gotas!», 2,5 s | ≈ 3,7 s |
| Formas | «¡Piecitas!» (se mete en la silueta, se atora y sale con un "pop"), 1 s | **[v2, N8]** «¡Por turnos! Si calza, sigues... ¡hasta prender tus lucecitas!», 3 s | ≈ 4 s |
| Parejas | «¡Cartitas!» (mira por entre dos cartas y queda bizco), 1 s | **[v2, N8]** «¡Por turnos! Si hay pareja, sigues... ¡hasta prender tus lucecitas!», 3 s | ≈ 4 s |

**Por qué así**:

- Es la primera de las dos salidas que propone la re-auditoría ("la presentación del Coleccionauta es
  un gag sin palabras o de una sola palabra, ≤ 1,5 s, dentro de los 4 s"). Una palabra no compite con la
  regla: es un sonido chistoso que Maxi entiende sin explicación, y la única **frase** es la de Coco.
- Se conserva la presentación del rival que pide el §14.11, porque es lo que hace reír a Maxi y le pone
  cara al juego.
- **[v2, N8]** En Formas y Parejas la frase ya no dice "sigues jugando" a secas (era falso al llegar al
  tope): dice hasta dónde se sigue, "¡hasta prender tus lucecitas!", y apunta a algo que se ve (la
  guirnalda se enciende con cada acierto y la última respira). Es la forma que fija la ficha v6.1 (§5.2,
  "sin números y apuntando a la guirnalda"). **Tocar a Cometa repite la regla con el número del que
  juega** (M6), y la primera vez que pasa lo explica `turno_perfecto_presenta` (§5.3).
- **Alternativa con números, descartada**: «Maxi junta una, Nicole dos, Sofía tres... ¡turno perfecto!»
  (≈ 3 s). Es muy clara, pero la oyen los tres juntos y pone en voz alta quién tiene "más" (R2, equidad
  de `perfil-jugadores.md`). Además a Maxi le promete un "turno perfecto" que su turno no tiene. Si el
  playtest muestra que Nicole o Sofía no entienden las lucecitas, esta es la línea de recambio: mismo id
  (`*_intro`), mismo largo.
- En la ronda de Parejas de la batalla **no suenan** las intros de Parejas en equipo
  (`intro_trucos*`, `intro`, `intro_tope`, `intro_ayudan`, `coleccionauta_entra`, `coco_juntemos`): la
  reemplaza esta intro.

---

## 1. El teaser (escena del ala, zona 3)

Extiende la video-llamada de `escena_planeta_arcoiris.md` (Beat 4), **después de `arcoiris_016` y antes
de que se corte la llamada** (§14.10, punto 1). Unos 10 s. Las dos voces las graba papá: una como el
Coleccionauta y otra como él mismo. **Papá se ríe**, así nadie lee "papá está en peligro" (m7).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_teaser_coleccionauta | Coleccionauta | «¿Un planeta que recupera colores? ¡Para mi colección! ...Permiso, permiso, ¡voy saliendo!» | se cuela en la pantalla, grandioso; después apurado y torpe, sale de cuadro tropezando con la mochila-torre | 5 s | Se asoma en la video-llamada de papá | `voces/arcoiris/batalla/teaser_coleccionauta.wav` | casera (papá) |
| arcoiris_batalla_teaser_papa | Papá | «¡Jajaja! ¡Allá va, con su mochila! Tranquilos, que ese se tropieza hasta con su sombra.» | muerto de la risa, relajado | 5 s | Justo después; la mochila-torre aterriza en el Claro | `voces/arcoiris/batalla/teaser_papa.wav` | familiar (papá) |

---

## 2. El hito en el mapa y "¡todos a la nave!"

`voz_hito` de `mapa.json` (§14.9): suena **como máximo una vez por visita al mapa**, sincronizada con un
asomo, y nunca suena a pendiente (M7.3). Se elige una variante al azar.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_hito_01 | Coleccionauta | «¡Hola, hola! ¿Quién quiere jugar conmigo? ¡Traje mi mochila!» | vecino simpático que invita, asomándose desde la mochila-torre | 3,5 s | `voz_hito` (una vez por visita) | `voces/arcoiris/batalla/hito_01.wav` | casera (papá) |
| arcoiris_batalla_hito_02 | Coleccionauta | «¡Yujuu! Aquí estoy... con galletas. Para mí. ...Bueno, les convido una.» | goloso y después generoso a regañadientes | 4,5 s | Variante | `voces/arcoiris/batalla/hito_02.wav` | casera (papá) |
| nucleo_batalla_hito | Cometa | «¡Es el Coleccionauta! Para ganarle, necesitamos a los tres. ¿Están todos?» | emocionado, de aventura | 4 s | Tocar el hito (también al retomar: es la invitación a reunirse) | `voces/nucleo/batalla/hito.wav` | TTS |
| nucleo_batalla_todos_nave | Cometa | «¡Todos a la nave! Cada uno toca su carita.» | fiesta, invitando | 2,5 s | Entra la pantalla "¡todos a la nave!" (primera vez); tocar a Cometa la repite | `voces/nucleo/batalla/todos_nave.wav` | TTS |
| nucleo_batalla_todos_nave_corta | Cometa | «¡Todos a la nave!» | alegre, como quien llama a la mesa; ya la conocen | 1,2 s | **[v2]** Pantalla "¡todos a la nave!" **al retomar**: suena solo si nadie toca un retrato en 4 s (§14.6) | `voces/nucleo/batalla/todos_nave_corta.wav` | TTS |
| nucleo_batalla_falta_uno | Cometa | «¡Falta alguien en la nave! La batalla es de los tres: ¡lo esperamos!» | cálido, sin reproche; "lo esperamos" con cariño | 3,5 s | Se intenta seguir sin los tres; se puede volver al mapa sin perder nada | `voces/nucleo/batalla/falta_uno.wav` | TTS |

Cada retrato que salta a su asiento usa `nucleo_equipo_sube_nave_<hermano>` (+ `yo_tambien_<hermano>`
si existe), y "¡Despegar!" usa `nucleo_equipo_despegar` (§9) la primera vez.

### 2.1 Retomar una batalla guardada (§14.6, N6, N11.d)

**[v2]** "¡Todos a la nave!" **sí** se repite al retomar, en versión corta. Orden:

1. tocar el hito → `nucleo_batalla_hito` (no se repite la cinemática de entrada);
2. pantalla "¡todos a la nave!": `nucleo_batalla_todos_nave_corta` **solo si nadie toca en 4 s**; cada
   retrato, su `sube_nave_<hermano>`;
3. **al tocar "¡Despegar!"**: la nave despega en versión corta, sin estrellas (1,2 s), y **Cometa** dice
   `nucleo_batalla_retomar` (**en lugar de** `nucleo_equipo_despegar`);
4. la intro de la ronda pendiente (§4.1, §5.1 o §6), que hace de recordatorio de ≈ 4 s;
5. **siempre** empieza Maxi, con `le_toca_maxi_0X`, sea a quien sea que le tocaba al salir.

En el epílogo, en el paso 4 suena `arcoiris_batalla_epilogo_maxi_ven` en vez de la intro.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| nucleo_batalla_retomar | Cometa | «¡Seguimos donde quedamos!» | alegre, como quien retoma un juego de mesa | 1,5 s | **[v2]** Al tocar "¡Despegar!" en la pantalla corta de "¡todos a la nave!" al retomar, encima del despegue corto (1,2 s) | `voces/nucleo/batalla/retomar.wav` | TTS |

---

## 3. La entrada de la batalla (≤ 12 s)

Cinemática de entrada (§14.10, punto 2). Orden: `aspira` (las tres bandas del cielo **de la escena**
entran a los pisos con el "sluuurp" de sorbete) → `guardados` (los colores saludan desde los pisos) →
`reto`. Total ≈ 11,8 s. Se puede saltar con un toque desde la segunda vez (por familia). Después, Coco
aterriza en el hito del Río con `arcoiris_batalla_juego_rio` y **la ronda 1 arranca sola** (§14.7).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_entrada_aspira | Coleccionauta | «¡Ooh, qué colores más lindos! ¡Para mi colección! Sluurp... ¡Je, me hizo cosquillas!» | encantado como niño en una dulcería; el "sluurp" corto, como con bombilla | 4,5 s | Aspira el rojo, el amarillo y el azul con la mochila-torre | `voces/arcoiris/batalla/entrada_aspira.wav` | casera (papá) |
| arcoiris_batalla_entrada_guardados | Coco | «¡Están guardados ahí! ¡Los vamos a sacar juntos!» | segura y alegre, señalando los pisos donde los colores saludan | 3 s | Justo después | `voces/arcoiris/batalla/entrada_guardados.wav` | TTS |
| arcoiris_batalla_entrada_reto | Coleccionauta | «¿Los quieren de vuelta? ¡Gánenme tres juegos! ...¿O eran dos?» | desafío de juego, nada de amenaza; cuenta con los dedos y se confunde | 3,5 s | Cierre de la entrada; aparece el mapa de batalla | `voces/arcoiris/batalla/entrada_reto.wav` | casera (papá) |

---

## 4. Ronda 1: Río de pintura (rojo)

Ruta base `voces/arcoiris/batalla/rio/`. **No hay fallo**: un disparo que no revienta es un "plop"
neutro, **sin voz**. Cuando a Nicole o a Sofía se les acaban sus 3 gotas, el turno pasa sin voz de
cierre: la siguiente voz es el "¡Le toca a…!". **En el Río no hay tope ni "¡turno perfecto!"**: rige la
racha de 3 (§4.3).

### 4.1 Intro, repetición y turno

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_rio_intro_coleccionauta | Coleccionauta | «¡Pintuuura!» | goloso, estirando la "u"; se asoma con las gafas-lupa y se pinta la nariz | 1,2 s | Intro de la ronda, parte 1 (N7) | `voces/arcoiris/batalla/rio/intro_coleccionauta.wav` | casera (papá) |
| arcoiris_batalla_rio_intro | Coco | «¡Por turnos: cada uno tira sus gotas!» | clara, de juego | 2,5 s | Intro de la ronda, parte 2 (N7); también al retomar | `voces/arcoiris/batalla/rio/intro.wav` | TTS |
| nucleo_equipo_rio_repetir | Cometa | «Toca el río y Coco dispara. ¡Tres gotas iguales juntas... y pop! Cuando se acaban tus gotas, le toca al siguiente.» | explicando con calma, el "pop" de fiesta | 6,5 s | Tocar a Cometa en el turno de Nicole o Sofía (M6) | `voces/nucleo/equipo/rio_repetir.wav` | TTS |
| nucleo_equipo_rio_repetir_maxi | Cometa | «¡Maxi, toca donde quieras, y Coco dispara!» | lento, cálido | 2,5 s | Tocar a Cometa en el turno de Maxi | `voces/nucleo/equipo/rio_repetir_maxi.wav` | TTS |
| arcoiris_batalla_rio_gotas_mano | Coco | «¡Tres gotas para tu turno! Mira, aquí en mi mano.» | mostrando, cómplice | 3 s | Primer turno de Nicole y primer turno de Sofía en la ronda (una vez cada una, la misma línea) | `voces/arcoiris/batalla/rio/gotas_mano.wav` | TTS |

### 4.2 El turno de Maxi y el reventón

Orden en su turno: `maxi_toca_0X` al empezar (con el halo ya puesto) → su toque → si cayó a menos de
150 px del halo, `justo_ahi_0X` → `maxi_revienta_0X`. Si no tocó en 20 s, la gota sale sola y suena
`arcoiris_equipo_maxi_regalito` (§7) en lugar de `justo_ahi`. Después, el ritual de porras de siempre
(`porras_fin_maxi`, §9).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_rio_maxi_toca_01 | Coco | «¡Maxi, toca donde quieras!» | lenta, invitando, con la lengua lista | 2 s | Empieza el turno de Maxi | `voces/arcoiris/batalla/rio/maxi_toca_01.wav` | TTS |
| arcoiris_batalla_rio_maxi_toca_02 | Coco | «¡Maxi, tú tocas... y yo disparo!» | juguetona, de dupla | 2,2 s | Variante | `voces/arcoiris/batalla/rio/maxi_toca_02.wav` | TTS |
| arcoiris_batalla_rio_justo_ahi_01 | Coco | «¡Justo ahí!» | sorpresa feliz, explota con el reventón | 0,8 s | Toque de Maxi a < 150 px del halo (B3.2) | `voces/arcoiris/batalla/rio/justo_ahi_01.wav` | TTS |
| arcoiris_batalla_rio_justo_ahi_02 | Coco | «¡Ahí mismito!» | ídem, con risa | 0,9 s | Variante | `voces/arcoiris/batalla/rio/justo_ahi_02.wav` | TTS |
| arcoiris_batalla_rio_maxi_revienta_01 | Coco | «¡Pop! ¡Bravo, Maxi!» | fiesta grande, igual si revientan 2 que 10 | 1,5 s | Revienta el tramo de Maxi (también en la jugada automática) | `voces/arcoiris/batalla/rio/maxi_revienta_01.wav` | TTS |
| arcoiris_batalla_rio_maxi_revienta_02 | Coco | «¡Plaf! ¡Qué reventón, Maxi!» | ídem, con salpicón en la voz | 1,7 s | Variante | `voces/arcoiris/batalla/rio/maxi_revienta_02.wav` | TTS |

Si el reventón de Maxi desata una cadena, suena además `cadena` (§4.3): se celebra como suya (pero no
mueve al rival: Maxi nunca lo mueve).

### 4.3 Reventones de Nicole y Sofía, cadena y retroceso por racha

Sin nombre a propósito (decisión 5). Al azar, sin repetir la anterior.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_rio_acierto_01 | Coco | «¡Pop! ¡Para el equipo!» | fiesta | 1,4 s | Reventón en el turno de Nicole o Sofía | `voces/arcoiris/batalla/rio/acierto_01.wav` | TTS |
| arcoiris_batalla_rio_acierto_02 | Coco | «¡Plaf! ¡Se reventaron!» | alegre | 1,4 s | Variante | `voces/arcoiris/batalla/rio/acierto_02.wav` | TTS |
| arcoiris_batalla_rio_acierto_03 | Coco | «¡Bum! ¡Pintura por todos lados!» | riéndose | 1,8 s | Variante | `voces/arcoiris/batalla/rio/acierto_03.wav` | TTS |
| arcoiris_batalla_rio_cadena | Coco | «¡Una cadena! ¡Pop, pop, pop!» | eufórica, los "pop" en escalera | 2 s | Un retroceso que revienta (reemplaza a `acierto_0X`) | `voces/arcoiris/batalla/rio/cadena.wav` | TTS |
| arcoiris_batalla_rio_retrocede_celebra | Coco | «¡Qué turno más reventón! ¡Para atrás, Coleccionauta!» | fiesta de equipo, sin nombre ni número | 2,8 s | **Solo en el Río**: justo después de `rival_retrocede` por la **racha de 3** reventones en un turno (la cadena vale 2), en el momento. Cometa **no** dice "¡turno perfecto!" en el Río (§5.2 de la ficha) | `voces/arcoiris/batalla/rio/retrocede_celebra.wav` | TTS |

### 4.4 El Coleccionauta en el Río

Avanza, se emboba con Maxi y retrocede con las líneas genéricas de siempre (§9). Si el Río usa
`resbalon_tras_racha`, en el pase que sigue a la racha de 3 suena su `resbala_0X` (§5.3). Reacciona a
los reventones **como máximo 1 de cada 3 veces** y nunca encima de Coco.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_rio_coleccionauta_reacciona_01 | Coleccionauta | «¡Ay, mis gotitas! ...Bueno, nunca fueron mías.» | quejón exagerado y después honesto | 3 s | Reventón (máx. 1 de 3) | `voces/arcoiris/batalla/rio/coleccionauta_reacciona_01.wav` | casera (papá) |
| arcoiris_batalla_rio_coleccionauta_reacciona_02 | Coleccionauta | «¡Qué salpicón! ¡Me pintaron las gafas-lupa!» | sorprendido, limpiándose; risa al final | 2,8 s | Variante. **[v2]** Además es la voz del momento **"gafas rojas"** (abajo) | `voces/arcoiris/batalla/rio/coleccionauta_reacciona_02.wav` | casera (papá) |

**[v2] Gafas rojas** (storyboard §6; clave `gafas_rojas`): el **primer reventón de un tramo rojo** de la
ronda salpica las gafas-lupa. Suena `arcoiris_batalla_rio_coleccionauta_reacciona_02`, **solo si la cola
de voces está libre en 1 s** (si no, sin voz), y cuenta como su reacción "1 de cada 3". Después, en esa
ronda, sus reacciones normales usan solo `_01`, para no repetir el chiste. No se escribe línea nueva: el
"¡veo todo rojo!" de la calibración lo dice la animación (se tambalea "viendo rojo").

### 4.5 Si pierden la ronda (derrota-gag del Río)

Empieza **con el retrato del siguiente ya al centro**. Secuencia de `derrota_gag_equipo` (la orquesta
`minijuego_base`, §11.4): `coleccionauta_aspira` (llega a la orilla y aspira las gotas que quedan) →
`coleccionauta_estornuda` (las devuelve al cauce) → `coleccionauta_cansado` (§9) → `coco_risa` → logro
común `gotas_reventadas_0X` (Cometa, clave `logro_comun`) → al tocar "¡otra vez!",
`coleccionauta_vuelve` (§9). El botón aparece desde el comienzo y tocarlo corta la secuencia.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_rio_coleccionauta_aspira | Coleccionauta | «¡Llegué a la orilla! ¡Todas las gotas a mi colección! Sluurp...» | triunfal de mentira | 3,5 s | Llega a la orilla | `voces/arcoiris/batalla/rio/coleccionauta_aspira.wav` | casera (papá) |
| arcoiris_batalla_rio_coleccionauta_estornuda | Coleccionauta | «¡Hip! ¿Hipo de pintura? A... a... ¡ACHÚU!» | hipo chistoso y estornudo enorme (gag para Maxi) | 3,5 s | La mochila-torre se infla y estornuda las gotas de vuelta al cauce | `voces/arcoiris/batalla/rio/coleccionauta_estornuda.wav` | casera (papá) |
| arcoiris_batalla_rio_coco_risa | Coco | «¡Jajaja! ¡Le salió pintura hasta por las antenas!» | riéndose con todos | 2,8 s | Después de `coleccionauta_cansado`; le salen dos fuentecitas de pintura por las bolitas de las antenas. **[v2]** "antenas", no "orejas" | `voces/arcoiris/batalla/rio/coco_risa.wav` | TTS |

**Logro común del Río (N4)**: las gotas reventadas **no vuelven**. No se cuentan con número (sería un
conteo raro de oír): hay dos tramos según las gotas ya reventadas de las 20 de la ronda. `logro_comun`
es un mapa "N" → ruta (§11.4), y `contar_logro_equipo()` del Río devuelve las gotas reventadas: de
**"1" a "9"** → `_01`; de **"10" a "19"** → `_02`. Si la ronda cambia a 18 gotas, el corte pasa a "9".
**Nunca hay cero**: el primer turno de cada intento es de Maxi y siempre revienta (si igual llega a 0,
`nos_alcanzo`).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| nucleo_equipo_gotas_reventadas_01 | Cometa | «¡Igual reventamos gotas, y el río quedó más cortito! ¡Otra vez, equipo!» | orgulloso, animando | 4 s | Cierre de la derrota del Río, menos de la mitad reventada | `voces/nucleo/equipo/gotas_reventadas_01.wav` | TTS |
| nucleo_equipo_gotas_reventadas_02 | Cometa | «¡Igual reventamos un montón de gotas, y esas no vuelven! ¡Otra vez, equipo!» | ídem, más grande | 4,2 s | Ídem, la mitad o más | `voces/nucleo/equipo/gotas_reventadas_02.wav` | TTS |

---

## 5. Ronda 2: Formas traviesas (amarillo)

Ruta base `voces/arcoiris/batalla/formas/`. Soltar una pieza en el vacío **no es fallo** y no tiene
voz (vuelve a la bandeja). Tope por turno: Maxi 1, Nicole 2, Sofía 3. Al llegar al tope, **turno
perfecto** (Cometa) y el Coleccionauta se resbala (`rival_retrocede`).

### 5.1 Intro, repetición y turno

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_formas_intro_coleccionauta | Coleccionauta | «¡Piecitas!» | encantado; se mete en la silueta, se atora y sale con un "pop" | 1 s | Intro de la ronda, parte 1 (N7) | `voces/arcoiris/batalla/formas/intro_coleccionauta.wav` | casera (papá) |
| arcoiris_batalla_formas_intro | Coco | «¡Por turnos! Si calza, sigues... ¡hasta prender tus lucecitas!» | clara, de juego; "lucecitas" como premio, mirando la guirnalda | 3 s | **[v2, N8]** Intro de la ronda, parte 2 (N7); también al retomar. La guirnalda del marco destella justo en "lucecitas" | `voces/arcoiris/batalla/formas/intro.wav` | TTS |
| nucleo_equipo_formas_repetir_brote | Cometa | «Lleva cada pieza a su lugar. ¡Si prendes tus dos lucecitas, turno perfecto!» | explicando con calma; la meta con alegría | 4,5 s | **[v2, N8]** Tocar a Cometa en el turno de un perfil Brote (Nicole). Reemplaza a `formas_repetir` | `voces/nucleo/equipo/formas_repetir_brote.wav` | TTS |
| nucleo_equipo_formas_repetir_estrella | Cometa | «Toca la pieza para girarla y llévala a su lugar. ¡Si prendes tus tres lucecitas, turno perfecto! Si no calza, le toca al siguiente.» | explicando con calma, de reto | 7 s | **[v2, N8]** Tocar a Cometa en el turno de un perfil Estrella (Sofía) | `voces/nucleo/equipo/formas_repetir_estrella.wav` | TTS |
| nucleo_equipo_formas_repetir_maxi | Cometa | «¡Maxi, toca la pieza que brilla!» | lento, cálido | 2 s | Tocar a Cometa en el turno de Maxi | `voces/nucleo/equipo/formas_repetir_maxi.wav` | TTS |
| arcoiris_batalla_formas_fiu_derechas | Coco | «¡Fiuuu! ¡Piezas derechitas!» | mágica, con el "fiu" visible | 1,8 s | Primer turno de Nicole en la ronda: las piezas se enderezan | `voces/arcoiris/batalla/formas/fiu_derechas.wav` | TTS |
| arcoiris_batalla_formas_fiu_giran | Coco | «¡Fiuuu! ¡Las piezas se dieron vueltas!» | pícara, de reto | 2,2 s | Primer turno de Sofía en la ronda: las piezas giran al azar | `voces/arcoiris/batalla/formas/fiu_giran.wav` | TTS |

Los dos "fiu" tienen el mismo largo y la misma estructura (equidad), y las dos `repetir` dicen la meta
con la misma frase ("¡Si prendes tus N lucecitas, turno perfecto!"). El número solo lo oye quien juega,
cuando lo pide. La de Nicole no habla del fallo: su primer fallo
lo cubre el besito de Coco (`nicole_otra`) y no deja rastro (B2). Los turnos siguientes de cada una
llevan solo el sonido del "fiu".

**Retirada en la v2**: `nucleo_equipo_formas_repetir` («…Si calza, sigues jugando. Si no calza, le toca
al siguiente.»). No nombraba el tope (N8).

### 5.2 El turno de Maxi

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_formas_maxi_brilla | Coco | «¡Maxi, la pieza que brilla!» | lenta, señalando; su hueco respira | 1,8 s | Empieza el turno de Maxi (B3.1) | `voces/arcoiris/batalla/formas/maxi_brilla.wav` | TTS |
| arcoiris_batalla_formas_maxi_brilla_02 | Coco | «¡Mira, Maxi! ¡Esta brilla para ti!» | maravillada | 2 s | Maxi toca una pieza sin halo (que solo hace el pulso) o 6 s sin tocar | `voces/arcoiris/batalla/formas/maxi_brilla_02.wav` | TTS |
| arcoiris_batalla_formas_maxi_pieza | Coco | «¡Bravo, Maxi! ¡Calzó justito!» | fiesta grande | 1,8 s | La pieza de Maxi llega a su lugar (también en la jugada automática, tras `maxi_regalito`) | `voces/arcoiris/batalla/formas/maxi_pieza.wav` | TTS |

Con su pieza puesta, el turno de Maxi termina (tope 1) con su celebración normal y **sin**
"¡turno perfecto!" ni retroceso (§11.4 de la ficha). Después, `porras_fin_maxi` (§9).

### 5.3 Piezas de Nicole y Sofía, turno perfecto y la nave completa

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_formas_acierto_01 | Coco | «¡Calzó!» | fiesta corta | 0,8 s | Pieza encajada en el turno de Nicole o Sofía | `voces/arcoiris/batalla/formas/acierto_01.wav` | TTS |
| arcoiris_batalla_formas_acierto_02 | Coco | «¡Justito en su lugar!» | contenta | 1,4 s | Variante | `voces/arcoiris/batalla/formas/acierto_02.wav` | TTS |
| arcoiris_batalla_formas_acierto_03 | Coco | «¡Una pieza más para el equipo!» | alegre | 1,8 s | Variante | `voces/arcoiris/batalla/formas/acierto_03.wav` | TTS |
| arcoiris_batalla_formas_fallo_01 | Coco | «¡Uy, ahí no calzaba! Pero ya sabemos dónde no va.» | liviana, positiva al final | 3 s | Pieza sobre un hueco equivocado que termina el turno | `voces/arcoiris/batalla/formas/fallo_01.wav` | TTS |
| arcoiris_batalla_formas_fallo_02 | Coco | «¡Casi! Esa pieza buscaba otra casita.» | cómplice, hablando de la pieza | 2,4 s | Variante | `voces/arcoiris/batalla/formas/fallo_02.wav` | TTS |
| nucleo_equipo_turno_perfecto_01 | Cometa | «¡Turno perfecto!» | fiesta, con el gesto corto del hermano | 1,2 s | Nicole o Sofía llegan a su tope (B2.1), en **Formas y Parejas**; lo dispara el `GestorTurnos` (paso 0b), y después suena `rival_retrocede` | `voces/nucleo/equipo/turno_perfecto_01.wav` | TTS |
| nucleo_equipo_turno_perfecto_02 | Cometa | «¡Turno perfecto! ¡Qué equipo!» | ídem | 1,8 s | Variante | `voces/nucleo/equipo/turno_perfecto_02.wav` | TTS |
| nucleo_equipo_turno_perfecto_presenta | Cometa | «¡Turno perfecto! ¡Prendiste todas tus luces y el Coleccionauta se resbaló!» | sorprendido y feliz, explicando lo que acaba de pasar | 3,8 s | **[v2, N8.2]** **El primer** turno perfecto de la familia (presentación única, por familia; `nucleo:turno_perfecto`), en lugar de `turno_perfecto_0X`. Sirve en la batalla y en Parejas en equipo | `voces/nucleo/equipo/turno_perfecto_presenta.wav` | TTS |
| arcoiris_batalla_formas_nuestra_nave | Coco | «¡Nuestra nave!» | asombro feliz, en plural | 0,9 s | **[v2]** Se encaja la última pieza: la nave de juguete se arma y las caritas asoman por las ventanitas (storyboard §6). Clave `voz_completa` de la figura | `voces/arcoiris/batalla/formas/nuestra_nave.wav` | TTS |

- **Turno perfecto (v6)**: en Formas, cada vez que Nicole llega a 2 piezas o Sofía a 3, suena
  `turno_perfecto_0X` (Cometa) + `rival_retrocede` (Coleccionauta), y nada más. **Ya no existe**
  `arcoiris_batalla_formas_retrocede_celebra` («¡Tres piezas seguidas!»): sería falsa para Nicole.
- **Si la pieza del tope es la última**, manda la victoria: suena `nuestra_nave` y no suena
  `turno_perfecto`.
- **El primer fallo de Nicole** en su turno usa `arcoiris_emparejar_equipo_nicole_otra` («¡Uy, otra!
  ¡Sigue, Nicole!», §9).
- **"¡Guárdala para tu próximo turno!"** (N13) está en el §7 y **solo suena en Parejas** (ficha v6.1
  §4.3: en Formas no hay nada escondido que guardar).

**[v2, PO 07-Oct-2026] El resbalón del pase (ficha v6.1 §4.3, UX N10).** En el pase que sigue a un
turno perfecto (en Formas y Parejas; y en el Río tras la racha de 3, si `resbalon_tras_racha`), el
Coleccionauta intenta saltar, patina en su galleta y cae sentado con cara de "je" (1,1 s). Su reacción:

- **cuándo**: **después** de que termina `le_toca_<hermano>` (o `sube_ventanita_<hermano>`), con él ya
  sentado y la puerta todavía cerrada. Nunca encima del "¡Le toca a…!" ni de otra voz;
- **si no cabe**: si la cola de voces no queda libre en 1 s, o si el niño ya abrió la puerta, **no suena**
  (el "fiuuu-plof" del SFX cuenta el chiste solo);
- **variantes**: alternadas, sin repetir la anterior. Si en el playtest cansa, pasa a "1 de cada 2".

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| nucleo_equipo_coleccionauta_resbala_01 | Coleccionauta | «¡Uuuy! ¡Galleta resbalosa!» | sorprendido y risueño, sentado; nada de dolor | 1,4 s | **[v2]** Resbalón del pase tras un turno perfecto (clave propuesta `rival_resbala`) | `voces/nucleo/equipo/coleccionauta/resbala_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_resbala_02 | Coleccionauta | «¡Ups! ...Me senté. Je, je.» | avergonzado de chiste, se acomoda las gafas | 1,5 s | Variante | `voces/nucleo/equipo/coleccionauta/resbala_02.wav` | casera (papá) |

Van en `voces/nucleo/equipo/coleccionauta/`, junto a `retrocede_01/02`, porque sirven en cualquier juego
en equipo con tope (también en Parejas en equipo fuera de la batalla). No dicen "me resbalé": esa frase
ya es de `retrocede_01` en el 0b, y así los dos gags suenan distintos.

### 5.4 El Coleccionauta en Formas

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_formas_coleccionauta_reacciona_01 | Coleccionauta | «¡Ay, esa pieza era para mi colección! ...¿O era un queque?» | indignado de mentira, después confundido mirando con la gafa-lupa | 3,5 s | Pieza encajada (máx. 1 de 3) | `voces/arcoiris/batalla/formas/coleccionauta_reacciona_01.wav` | casera (papá) |
| arcoiris_batalla_formas_coleccionauta_reacciona_02 | Coleccionauta | «¡Calzó! ¿Cómo saben dónde va? Yo meto todo en la mochila.» | asombrado de verdad, rascándose la cabeza | 3,5 s | Variante | `voces/arcoiris/batalla/formas/coleccionauta_reacciona_02.wav` | casera (papá) |

### 5.5 Si pierden la ronda (derrota-gag de Formas)

Secuencia de `derrota_gag_equipo`, igual que el Río: `coleccionauta_aspira` (aspira las piezas sueltas
de la bandeja) → `coleccionauta_estornuda` (salen girando como trompos y caen en el estado del perfil
del turno siguiente, m2) → `coleccionauta_cansado` (§9) → `coco_risa` → logro común
`piezas_puestas_<n>` (Cometa, clave `logro_comun`) → al tocar "¡otra vez!", `coleccionauta_vuelve`
(§9).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_formas_coleccionauta_aspira | Coleccionauta | «¡Llegué! ¡Todas las piezas a mi colección! Sluurp...» | triunfal de mentira | 3,2 s | Llega a la mesa | `voces/arcoiris/batalla/formas/coleccionauta_aspira.wav` | casera (papá) |
| arcoiris_batalla_formas_coleccionauta_estornuda | Coleccionauta | «¡Uy, me pica una esquina! A... a... ¡ACHÚU!» | incómodo, retorciéndose; estornudo enorme | 3,2 s | La mochila-torre estornuda las piezas | `voces/arcoiris/batalla/formas/coleccionauta_estornuda.wav` | casera (papá) |
| arcoiris_batalla_formas_coco_risa | Coco | «¡Jajaja! ¡Las piezas salieron girando como trompos!» | riéndose con todos | 2,8 s | Después de `coleccionauta_cansado` | `voces/arcoiris/batalla/formas/coco_risa.wav` | TTS |

**Logro común de Formas (N4)**: las piezas puestas en la silueta **se quedan**. Se cuentan con número,
con la misma estructura que `pares_juntados_*` (los niños ya conocen esa frase). La ronda tiene **12
piezas**, así que una derrota deja de 1 a 11: `logro_comun` = mapa "1" a "11". **Nunca hay cero**: el
primer turno de cada intento es de Maxi y siempre pone su pieza (si igual llega a 0, `nos_alcanzo`).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| nucleo_equipo_piezas_puestas_1 | Cometa | «¡Igual pusimos una pieza, y se queda! ¡Otra vez, equipo!» | orgulloso, animando | 3,5 s | Derrota con 1 pieza puesta | `voces/nucleo/equipo/piezas_puestas_1.wav` | TTS |
| nucleo_equipo_piezas_puestas_2 | Cometa | «¡Igual pusimos dos piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,5 s | 2 piezas | `voces/nucleo/equipo/piezas_puestas_2.wav` | TTS |
| nucleo_equipo_piezas_puestas_3 | Cometa | «¡Igual pusimos tres piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,5 s | 3 | `voces/nucleo/equipo/piezas_puestas_3.wav` | TTS |
| nucleo_equipo_piezas_puestas_4 | Cometa | «¡Igual pusimos cuatro piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 4 | `voces/nucleo/equipo/piezas_puestas_4.wav` | TTS |
| nucleo_equipo_piezas_puestas_5 | Cometa | «¡Igual pusimos cinco piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 5 | `voces/nucleo/equipo/piezas_puestas_5.wav` | TTS |
| nucleo_equipo_piezas_puestas_6 | Cometa | «¡Igual pusimos seis piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 6 | `voces/nucleo/equipo/piezas_puestas_6.wav` | TTS |
| nucleo_equipo_piezas_puestas_7 | Cometa | «¡Igual pusimos siete piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 7 | `voces/nucleo/equipo/piezas_puestas_7.wav` | TTS |
| nucleo_equipo_piezas_puestas_8 | Cometa | «¡Igual pusimos ocho piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 8 | `voces/nucleo/equipo/piezas_puestas_8.wav` | TTS |
| nucleo_equipo_piezas_puestas_9 | Cometa | «¡Igual pusimos nueve piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 9 | `voces/nucleo/equipo/piezas_puestas_9.wav` | TTS |
| nucleo_equipo_piezas_puestas_10 | Cometa | «¡Igual pusimos diez piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 10 | `voces/nucleo/equipo/piezas_puestas_10.wav` | TTS |
| nucleo_equipo_piezas_puestas_11 | Cometa | «¡Igual pusimos once piezas, y se quedan! ¡Otra vez, equipo!» | ídem | 3,6 s | 11 | `voces/nucleo/equipo/piezas_puestas_11.wav` | TTS |

Con 12 piezas (calibración v3) se usan las 11. Si el playtest baja la ronda a 11 piezas (el respaldo
{1, 2, 2}), sobra `piezas_puestas_11`.

---

## 6. Ronda 3 (final): Parejas en equipo (azul)

Ruta base `voces/arcoiris/batalla/parejas/`. **12 pares en 4×6**, con tope {1, 2, 3} y turno perfecto.
**Todo lo de dentro de la ronda se reutiliza** del guion de Parejas en equipo (§9): vistazo, turno
guiado de Maxi, aciertos y fallos sin nombre, segunda oportunidad de Nicole, avances y embobados del
Coleccionauta, y la derrota-gag con su logro común **`pares_juntados_1..11`** (respaldo de
`logro_comun`, §11.4).

- **En la batalla no suena** `arcoiris_emparejar_equipo_retrocede_celebra` («¡Tres parejas
  seguidas!»): en esta ronda todos tienen tope, así que el retroceso es siempre por turno perfecto
  (`turno_perfecto_0X` + `rival_retrocede`, §5.3).
- **En el par que llega al tope** no conviene `acierto_02` («¡Eso! ¡Y sigues jugando!»), que sería
  falso: el motor elige entre `acierto_01/03/04` (o no dice acierto y deja el "¡turno perfecto!").
- **En el pase tras un turno perfecto**: `rival_retrocede` en el 0b (o `guardala`, si esa vez la tocan,
  §7) y, en el paso 2, el resbalón con `resbala_0X` (§5.3).

Son nuevas la intro (N7, N8), las `repetir` con tope y el chiste de la lupa.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_parejas_intro_coleccionauta | Coleccionauta | «¡Cartitas!» | encantado; mira por entre dos cartas y queda bizco | 1 s | Intro de la ronda, parte 1 (N7) | `voces/arcoiris/batalla/parejas/intro_coleccionauta.wav` | casera (papá) |
| arcoiris_batalla_parejas_intro | Coco | «¡Por turnos! Si hay pareja, sigues... ¡hasta prender tus lucecitas!» | clara, alegre; "lucecitas" como premio, mirando la guirnalda | 3 s | **[v2, N8]** Intro de la ronda, parte 2 (N7); también al retomar. Reemplaza a las intros de Parejas en equipo. La guirnalda destella en "lucecitas" | `voces/arcoiris/batalla/parejas/intro.wav` | TTS |
| nucleo_equipo_parejas_repetir | Cometa | «Da vuelta dos cartas. Si son pareja, sigues jugando. Si no, le toca al siguiente.» | explicando con calma | 5 s | Tocar a Cometa en el turno de Nicole o Sofía **sin tope** (Parejas en equipo `maxi+sofia` y `nicole+sofia`). **No suena en la batalla** | `voces/nucleo/equipo/parejas_repetir.wav` | TTS |
| nucleo_equipo_parejas_repetir_tope_brote | Cometa | «Da vuelta dos cartas. Si son pareja, sigues. ¡Si prendes tus dos lucecitas, turno perfecto!» | explicando con calma; la meta con alegría | 5 s | **[v2, N8]** Tocar a Cometa en el turno de un perfil Brote **con tope** (batalla, "los tres" y `maxi+nicole`) | `voces/nucleo/equipo/parejas_repetir_tope_brote.wav` | TTS |
| nucleo_equipo_parejas_repetir_tope_estrella | Cometa | «Da vuelta dos cartas. Si son pareja, sigues. ¡Si prendes tus tres lucecitas, turno perfecto! Si no, le toca al siguiente.» | explicando con calma, de reto | 6,8 s | **[v2, N8]** Ídem, perfil Estrella con tope (batalla y "los tres") | `voces/nucleo/equipo/parejas_repetir_tope_estrella.wav` | TTS |
| nucleo_equipo_parejas_repetir_maxi | Cometa | «¡Maxi, toca las cartas que brillan!» | lento, cálido | 2 s | Tocar a Cometa en el turno de Maxi (también fuera de la batalla) | `voces/nucleo/equipo/parejas_repetir_maxi.wav` | TTS |
| arcoiris_batalla_parejas_lupa_gafas | Coleccionauta | «¡Eh! ¡Esas son mis gafas!» | sorprendido, palpándose la cara; se le resbalan las gafas-lupa | 1,3 s | **[v2]** Se forma la pareja lupa (`variante: "lupa_coleccionauta"`) y **no** la formó Maxi. Suena después de la voz de la lupa (`especiales.lupa`), solo si la cola está libre; reemplaza a su `rival_par` en ese par. Clave `lupa_coleccionauta` | `voces/arcoiris/batalla/parejas/lupa_gafas.wav` | casera (papá) |

Si la pareja lupa la forma Maxi, suena `arcoiris_emparejar_equipo_maxi_lupa` (§9) y **no** suena
`lupa_gafas`: el momento es de Maxi.

---

## 7. Entre rondas: interludio, mapa de batalla, pausas y ayudas

Ruta base `voces/arcoiris/batalla/` (y `voces/arcoiris/equipo/` para lo que sirve también fuera).

**[v2] Interludio al ganar una ronda** (motor, §14.4; storyboard §7.2-7.5). Orden, un foco a la vez:

1. el piso tiembla y estornuda (SFX, sin voz);
2. **Coco**: `arcoiris_mapa_zona_<n>_completada` (reutilizada, §9), que arranca en el mismo cuadro en
   que sale el chorro de color hacia el cielo;
   - **ronda 2: se corta después de "¡amarillo limón!"**. En la batalla suena «¡Volvió el amarillo!
     Ahora soy... ¡amarillo limón!» y no suena "¡Brillo como un sol!" (ahorra ≈ 1,3 s). No es una línea
     nueva: Dev corta la reproducción del mismo archivo en la marca de tiempo del final de "limón",
     medida sobre el audio real (propuesta: campo `hasta_s` en el interludio);
3. **Coleccionauta**: `livianita_<n>` (el piso vacío se pliega y él da su saltito);
4. aire para la risa;
5. en el mapa de batalla: Coco salta al hito siguiente y suena `pausa_<color>` (rondas 1 y 2). En la
   ronda 3 no hay mapa: sigue de corrido "antes del epílogo" (§8.1).

**Mapa de batalla**: al tocar un hito, Coco nombra el juego. Para Formas y Parejas se reutilizan
`juego_formas` y `juego_parejas` del mapa; el Río tiene su línea nueva.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_livianita_1 | Coleccionauta | «¡Uy! ¡Mi mochila está más livianita!» | sorprendido y contento, da un saltito | 2,5 s | Interludio de la ronda 1, **después** de `zona_1_completada` | `voces/arcoiris/batalla/livianita_1.wav` | casera (papá) |
| arcoiris_batalla_livianita_2 | Coleccionauta | «¡Otro piso menos! ¡Ahora salto más alto! Boing...» | saltando, se pega en la cabeza con algo invisible | 3 s | Interludio de la ronda 2, después de `zona_2_completada` (cortada) | `voces/arcoiris/batalla/livianita_2.wav` | casera (papá) |
| arcoiris_batalla_livianita_3 | Coleccionauta | «¡Uy, uy, uy! ¡Mi mochila ya no pesa nada!» | flotando un poquito, desconcertado; al final cae sentado | 2,8 s | Interludio de la ronda 3, después de `zona_3_completada` | `voces/arcoiris/batalla/livianita_3.wav` | casera (papá) |
| arcoiris_batalla_juego_rio | Coco | «¡Río de pintura!» | anunciando, como `juego_formas` | 1,2 s | Coco aterriza en el hito del Río tras la entrada, o se toca ese hito en el mapa de batalla (sirve también para el mapa del planeta) | `voces/arcoiris/batalla/juego_rio.wav` | TTS |
| arcoiris_batalla_pausa_amarillo | Coco | «¿Vamos por el amarillo, o descansamos y volvemos después?» | tranquila, de verdad ofrece las dos | 3,5 s | Mapa de batalla tras la ronda 1 (M1.2); no avanza solo | `voces/arcoiris/batalla/pausa_amarillo.wav` | TTS |
| arcoiris_batalla_pausa_azul | Coco | «¿Vamos por el azul, o descansamos y volvemos después?» | ídem | 3,3 s | Mapa de batalla tras la ronda 2 | `voces/arcoiris/batalla/pausa_azul.wav` | TTS |
| arcoiris_batalla_esperemos_nicole | Coco | «¡Esperemos a Nicole!» | tranquila, sin reproche; la casa respira | 1,4 s | Maxi entró solo y, en el turno de Nicole, nadie abrió la puerta tras los 2 recordatorios (m4) | `voces/arcoiris/batalla/esperemos_nicole.wav` | TTS |
| arcoiris_batalla_esperemos_sofia | Coco | «¡Esperemos a Sofía!» | ídem | 1,4 s | Ídem, en el turno de Sofía | `voces/arcoiris/batalla/esperemos_sofia.wav` | TTS |
| arcoiris_equipo_maxi_regalito | Coco | «¡Maxi nos dejó un regalito!» | encantada, como si Maxi lo hubiera hecho a propósito | 1,8 s | Turno de Maxi resuelto solo a los 20 s (M2), en cualquier ronda **y en Parejas en equipo fuera de la batalla** (clave `maxi_regalito`) | `voces/arcoiris/equipo/maxi_regalito.wav` | TTS |
| arcoiris_equipo_guardala | Coco | «¡Guárdala para tu próximo turno!» | cómplice, de plan secreto; nunca "no" | 1,8 s | **[v2, N13]** **Solo en Parejas** (ficha v6.1 §4.3): en el paso 0b de un turno perfecto, Nicole o Sofía tocan una carta tapada. Además del pulso y el guiño de la carta, Coco dice esto **una vez por partida** (la ronda 3 con su reintento cuenta como una). Espera a que termine "¡turno perfecto!" y **esa vez reemplaza a `rival_retrocede`** (el rival igual hace su animación). Sirve también en Parejas en equipo con tope. Clave `guardala_proximo_turno` | `voces/arcoiris/equipo/guardala.wav` | TTS |

No se dice "¡ya volvió el rojo!" al comienzo de `pausa_amarillo` (sí lo trae la ficha): el interludio lo
acaba de decir con `zona_1_completada`, y repetirlo alarga la espera de Maxi.

---

## 8. Epílogo y cierre de temporada

### 8.1 Antes del epílogo (≤ 5 s)

La mochila-torre queda gris y vacía; el Coleccionauta, sentado. Total ≈ 4,8 s.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_epilogo_antes_coleccionauta | Coleccionauta | «Mochila vacía... ¿y ahora qué colecciono?» | dramático de teleserie, chistoso, nada triste; mira dentro de la mochila | 2,8 s | Cinemática antes del epílogo | `voces/arcoiris/batalla/epilogo/antes_coleccionauta.wav` | casera (papá) |
| arcoiris_batalla_epilogo_antes_coco | Coco | «¡Ya sé! ¡Regalémosle colores!» | se le prende la ampolleta, feliz | 1,8 s | Justo después. Hace de intro del epílogo | `voces/arcoiris/batalla/epilogo/antes_coco.wav` | TTS |

### 8.2 Pintar la mochila (sin puerta ni pista, M9)

Orden: `maxi_ven` → Maxi pinta su parte → `parte_coco_0X` + `parte_coleccionauta_<n>` → `ahora_nicole`
→ ... → `ahora_sofia` → ... → `tapa` → los tres tocan por turno su ventanita (`ahora_<hermano>` antes de
cada toque) → estornudo de confeti (SFX, sin voz) → cierre parte A.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_epilogo_maxi_ven | Coco | «¡Maxi, ven a pintar!» | llamando con cariño; su retrato salta en la barra | 1,5 s | Empieza el epílogo, y al retomarlo (M1.4, N6) | `voces/arcoiris/batalla/epilogo/maxi_ven.wav` | TTS |
| nucleo_equipo_epilogo_repetir | Cometa | «¡Toca la mochila y píntala de colores!» | alegre | 2,2 s | Tocar a Cometa en el epílogo | `voces/nucleo/equipo/epilogo_repetir.wav` | TTS |
| nucleo_equipo_ahora_maxi | Cometa | «¡Ahora Maxi!» | fiesta, anunciando | 0,9 s | El retrato de Maxi vuela a la barra (modo sin puerta, `sin_puerta()`); en el epílogo, en la tapa | `voces/nucleo/equipo/ahora_maxi.wav` | TTS |
| nucleo_equipo_ahora_nicole | Cometa | «¡Ahora Nicole!» | ídem | 0,9 s | Ídem, Nicole | `voces/nucleo/equipo/ahora_nicole.wav` | TTS |
| nucleo_equipo_ahora_sofia | Cometa | «¡Ahora Sofía!» | ídem | 0,9 s | Ídem, Sofía | `voces/nucleo/equipo/ahora_sofia.wav` | TTS |
| arcoiris_batalla_epilogo_parte_coco_01 | Coco | «¡Qué color más lindo!» | maravillada | 1,3 s | Se rellena una parte (al azar, sin repetir) | `voces/arcoiris/batalla/epilogo/parte_coco_01.wav` | TTS |
| arcoiris_batalla_epilogo_parte_coco_02 | Coco | «¡Le queda precioso!» | contenta | 1,2 s | Variante | `voces/arcoiris/batalla/epilogo/parte_coco_02.wav` | TTS |
| arcoiris_batalla_epilogo_parte_coco_03 | Coco | «¡Mírenla cómo brilla!» | orgullosa | 1,3 s | Variante | `voces/arcoiris/batalla/epilogo/parte_coco_03.wav` | TTS |
| arcoiris_batalla_epilogo_parte_coleccionauta_1 | Coleccionauta | «¡Ooh! ¡Mi mochila tiene un color!» | asombro de niño chico | 2,2 s | Después de la 1.ª parte pintada | `voces/arcoiris/batalla/epilogo/parte_coleccionauta_1.wav` | casera (papá) |
| arcoiris_batalla_epilogo_parte_coleccionauta_2 | Coleccionauta | «¡Otro más! ¿Me están regalando colores?» | no lo puede creer | 2,5 s | Después de la 2.ª | `voces/arcoiris/batalla/epilogo/parte_coleccionauta_2.wav` | casera (papá) |
| arcoiris_batalla_epilogo_parte_coleccionauta_3 | Coleccionauta | «Nadie me había regalado nada... Bueno, una vez un calcetín.» | emocionado de verdad, y al final el chiste | 3,5 s | Después de la 3.ª | `voces/arcoiris/batalla/epilogo/parte_coleccionauta_3.wav` | casera (papá) |
| arcoiris_batalla_epilogo_regalo_maxi | Maxi | «¡Para ti!» | como le salga | 0,8 s | Justo después de pintar su parte | `voces/arcoiris/batalla/epilogo/regalo_maxi.wav` | niños (opcional) |
| arcoiris_batalla_epilogo_regalo_nicole | Nicole | «¡Para ti!» | cariñosa | 0,8 s | Ídem | `voces/arcoiris/batalla/epilogo/regalo_nicole.wav` | niños (opcional) |
| arcoiris_batalla_epilogo_regalo_sofia | Sofía | «¡Para ti!» | cariñosa | 0,8 s | Ídem | `voces/arcoiris/batalla/epilogo/regalo_sofia.wav` | niños (opcional) |
| arcoiris_batalla_epilogo_tapa | Coco | «¡Falta la tapa! Todos juntos: ¡cada uno toca su ventanita!» | emocionada, de final | 3,2 s | Después de las 3 partes: cierre "¡todos juntos!" | `voces/arcoiris/batalla/epilogo/tapa.wav` | TTS |

Las líneas `parte_coleccionauta_<n>` van **en orden** (1, 2, 3), no al azar: cuentan una pequeña
historia. Si un hermano pinta la parte de otro (§4.3 de la ficha), suenan igual.

### 8.3 Cierre de temporada, parte A (≤ 20 s)

Orden (storyboard §12.1): `cierre_mira` → `cierre_equipo` → `cierre_despedida` (se va tropezando) →
`cierre_coco`. ≈ 19,8 s. La fiesta de los tres abre la parte B (storyboard §12.2).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_cierre_mira | Coleccionauta | «¡Mi mochila de colores! Es la cosa más incre... incre... ¡ay, no me sale de lo linda que está!» | grande y después atorado de emoción (su tic) | 5 s | Se mira la mochila pintada | `voces/arcoiris/batalla/cierre/mira.wav` | casera (papá) |
| arcoiris_batalla_cierre_equipo | Coleccionauta | «Ya entendí... un equipo no cabe en una mochila.» | pensativo, rascándose la cabeza, como quien descubre algo; sin solemnidad | 3 s | Mira a los tres juntos | `voces/arcoiris/batalla/cierre/equipo.wav` | casera (papá) |
| arcoiris_batalla_cierre_despedida | Coleccionauta | «¡Me voy, me voy! Pero un día vuelvo... ¡con una mochila más grande! ¡Chao! ...¿Para qué lado era la salida?» | alegre, de "nos vemos"; el final perdido | 6 s | Se despide (gancho de HE-39) | `voces/arcoiris/batalla/cierre/despedida.wav` | casera (papá) |
| arcoiris_batalla_cierre_coco | Coco | «¡Lo logramos juntos! Ahora soy... ¡arcoíris de equipo!» | la alegría más grande; pausa antes del color (tic) | 3,2 s | El arcoíris del cielo brilla completo | `voces/arcoiris/batalla/cierre/coco.wav` | TTS |

### 8.4 Cierre de temporada, parte B (fiesta, foto y papá)

Orden (storyboard §12.2): la fiesta de los tres (§9: `al_frente` → gestos con `fiesta_<hermano>` →
`choca` → `equipo_estelar` → `destellos`, solo si **todos** reciben) → `cierre_foto` → la foto con su
audio familiar → video-llamada opcional → al volver a la selección, la nave "¡Juntos!" entra volando
con `nucleo_equipo_presenta` (§9).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_batalla_cierre_foto | Cometa | «¡Miren! ¡Una foto de los tres juntos, para el álbum!» | sorpresa feliz | 3 s | Entrega de la foto familiar (momento `batalla` del álbum). La foto trae su propio audio, que elige y graba el PO | `voces/arcoiris/batalla/cierre/foto.wav` | TTS |
| arcoiris_batalla_cierre_papa_01 | Papá | «¡Esa foto! Los tres juntitos... ¡me la pongo de fondo de pantalla!» | orgulloso, encantado | 4 s | Video-llamada extra familiar (M7.2): papá ve la foto | `voces/arcoiris/batalla/cierre/papa_01.wav` | familiar (papá; si el PO lo decide) |
| arcoiris_batalla_cierre_papa_02 | Papá | «Oigan, acá llegó el Coleccionauta, todo pintado y cantando. ¡Nunca lo había visto tan contento!» | contando un chisme divertido, tranquilo | 5 s | Ídem | `voces/arcoiris/batalla/cierre/papa_02.wav` | familiar (papá; si el PO lo decide) |
| arcoiris_batalla_cierre_papa_03 | Papá | «¿Saben por qué el arcoíris nunca pelea? ¡Porque cada color se queda en su raya! Los quiero mucho. Jueguen tranquilos, que acá estoy feliz.» | chiste de papá, pausa antes del remate; cierre cálido y sin apuro | 7 s | Ídem; se corta la llamada con destellos | `voces/arcoiris/batalla/cierre/papa_03.wav` | familiar (papá; si el PO lo decide) |

---

## 9. Líneas que se reutilizan (no se graban de nuevo)

Mismo texto y mismo archivo. Todas están en `voces-modo-equipo-parejas.md` salvo las marcadas como
"mapa" (`zonas_arcoiris.md` / `mapa/lineas_tts.tsv`).

| id reutilizado | dónde suena en la batalla |
|---|---|
| `nucleo_equipo_sube_nave_maxi/nicole/sofia` (3) + `nucleo_equipo_yo_tambien_*` (3, niños) | "¡Todos a la nave!" (también al retomar): cada hermano toca su retrato |
| `nucleo_equipo_despegar` | Tocar "¡Despegar!" la primera vez (al retomar lo reemplaza `nucleo_batalla_retomar`) |
| `nucleo_equipo_le_toca_<hermano>_01..03` (9) | Paso 2 del pase en las 3 rondas (Maxi → Nicole → Maxi → Sofía). Al retomar, siempre `le_toca_maxi_0X` |
| `nucleo_equipo_te_toca_<hermano>` (3), `nucleo_equipo_maxi_ayuda` | Recordatorios de la puerta de toque |
| `nucleo_equipo_sube_ventanita_nicole/sofia`, `nucleo_equipo_te_toca_nicole/sofia_ventanita` (4) | Puerta de arrastre después de un turno de Maxi |
| `arcoiris_emparejar_equipo_porras_fin_maxi` | Ritual de fin de turno de Maxi en las 3 rondas (el texto no habla de cartas) |
| `nucleo_equipo_coleccionauta_avanza_01..04` (4) | El rival salta una galleta en el pase, en las 3 rondas |
| `nucleo_equipo_coleccionauta_embobado_01..03` (3) | Turno de Maxi, en las 3 rondas |
| `nucleo_equipo_coleccionauta_retrocede_01/02` (2) | `rival_retrocede` (paso 0b): turno perfecto en Formas y Parejas; racha de 3 en el Río (y después, solo en el Río, `rio_retrocede_celebra`). El resbalón del paso 2 usa las nuevas `resbala_0X` (§5.3) |
| `nucleo_equipo_coleccionauta_par_01/03` (2) | Ronda 3 (máx. 1 de 3). `par_02` («¡Otra pareja!») también, solo en la ronda 3 |
| `arcoiris_emparejar_equipo_coleccionauta_cansado` | Derrota-gag de las 3 rondas («cuesta guardar tantas cosas solo»; el texto no habla de cartas) |
| `nucleo_equipo_coleccionauta_vuelve` | "¡Otra vez!" en las 3 rondas |
| `nucleo_equipo_nos_alcanzo` | Respaldo del logro común con 0 conservado (no debería ocurrir: siempre empieza Maxi) |
| `arcoiris_emparejar_equipo_nicole_otra` | Segunda oportunidad de Nicole en Formas y en Parejas |
| Ronda 3: `arcoiris_emparejar_equipo_vistazo`, `maxi_brillan_01/02`, `maxi_aqui`, `maxi_par`, `maxi_lupa`, `acierto_01..04`, `fallo_01..04`, `brote_ayuda`, `coleccionauta_aspira`, `coleccionauta_estornuda`, `coco_otra_vez` (18) + `nucleo_equipo_pares_juntados_1..11` (11) + `nucleo_equipo_coleccionauta_par_02` (1) | Parejas en equipo dentro de la batalla, igual que fuera. **[v2]** 12 pares: `pares_juntados` del 1 al 11 |
| `arcoiris_emparejar_especiales_lupa_presenta`, `arcoiris_emparejar_especiales_lupa` (2) | La pareja lupa de la ronda 3 (`especiales.lupa` del nivel) |
| `nucleo_equipo_animo_<hermano>_01/02` (6, niños) | Ánimo de los que miran ante un fallo, en Formas y Parejas (`animo_hermanos`) |
| `arcoiris_mapa_zona_1/2/3_completada` (3, mapa) | Interludio: el color vuelve al cielo. **La 2 se corta tras "¡amarillo limón!"** (§7) |
| `arcoiris_mapa_juego_formas`, `arcoiris_mapa_juego_parejas` (2, mapa) | Tocar esos hitos en el mapa de batalla |
| `nucleo_equipo_al_frente`, `nucleo_equipo_choca`, `nucleo_equipo_equipo_estelar`, `nucleo_equipo_destellos` (4) + `nucleo_equipo_fiesta_maxi/nicole/sofia` (3, niños) | Fiesta de los tres al abrir el cierre, parte B. `destellos` solo si **todos** reciben (son 100, una sola vez) |
| `nucleo_equipo_presenta` | La nave "¡Juntos!" entra volando en la selección |

**Total reutilizadas: 91** (6 + 1 + 9 + 4 + 4 + 1 + 4 + 3 + 2 + 2 + 1 + 1 + 1 + 1 + 30 + 2 + 6 + 3 + 2 +
7 + 1, en el orden de la tabla). Además, **dentro de este guion**, `arcoiris_batalla_rio_coleccionauta_reacciona_02`
se reutiliza para las gafas rojas (no suma al conteo).

**No se reutilizan en la batalla**: `coleccionauta_entra`, `coco_juntemos`, `intro_trucos*` (también
los cierres `intro_trucos_equipo*`), `intro`, `intro_tope`, `intro_ayudan` (los reemplaza la intro N7),
`nucleo_equipo_parejas_repetir` (sin tope),
**`arcoiris_emparejar_equipo_retrocede_celebra`** («¡Tres parejas seguidas!»: en la batalla siempre
hay tope), `coco_victoria` (el final de la ronda 3 es el interludio azul) y
`coleccionauta_aplaude_01/02` (su admiración va en el cierre).

---

## 10. Notas para `dev-godot`, `director-cinematicas` y `disenador-mecanicas`

(No edito las fichas ni los datos; esto es lo que el guion necesita de ellos.)

1. **"¡Turno perfecto!" lo dice Cometa** (`nucleo_equipo_turno_perfecto_01/02`), lo dispara el
   `GestorTurnos` en el paso 0b y suena en **Formas y Parejas**, seguido de `rival_retrocede`. En el
   Río no suena: ahí el retroceso es por racha de 3, con `rival_retrocede` + `rio_retrocede_celebra`.
   La primera vez de la familia suena `nucleo_equipo_turno_perfecto_presenta` en su lugar (N8.2):
   clave `turno_perfecto_presenta` en `lineas_voz`, marcada con
   `Progreso.marcar_cinematica_vista("nucleo:turno_perfecto")`, como fija la ficha v6.1 §5.2.
2. **Ronda de Parejas en la batalla**: no suenan las intros de Parejas en equipo ni
   `rival_retrocede_celebra`; la intro es `arcoiris_batalla_parejas_intro_coleccionauta` +
   `arcoiris_batalla_parejas_intro`. En el par del tope, no usar `acierto_02` (§6).
3. **Tocar a Cometa (M6)**: la `repetir` depende de la ronda y del perfil que juega. Propuesta de clave
   en `lineas_voz`: `repetir` = `{ "semilla": …, "brote": …, "estrella": … }`:
   - Río: `rio_repetir_maxi` / `rio_repetir` / `rio_repetir`;
   - Formas: `formas_repetir_maxi` / `formas_repetir_brote` / `formas_repetir_estrella`;
   - Parejas con tope (batalla, "los tres", `maxi+nicole`): `parejas_repetir_maxi` /
     `parejas_repetir_tope_brote` / `parejas_repetir_tope_estrella`;
   - Parejas sin tope (`maxi+sofia`, `nicole+sofia`): `parejas_repetir_maxi` / `parejas_repetir` /
     `parejas_repetir`;
   - epílogo: `epilogo_repetir` para todos.
4. **Derrota y logro común** (v6, §11.4): van en `lineas_voz.derrota_gag_equipo` (secuencia) y
   `lineas_voz.logro_comun` (mapa "N" → ruta). Parejas no necesita `logro_comun`: usa `pares_juntados`
   como respaldo. Se descarta el bloque `equipo.voces_batalla` de la v1, y también el campo
   `logro_comun_mitad` que proponía: el corte del Río va en el propio mapa (§4.5).
5. **Retomar** (§2.1): "¡todos a la nave!" corto con `todos_nave_corta` solo si nadie toca en 4 s, y
   `nucleo_batalla_retomar` (Cometa) al tocar "¡Despegar!", en lugar de `nucleo_equipo_despegar`. La
   ficha §14.6 nombra `nucleo_batalla_todos_nave` para ese momento: propongo la corta, porque ya la
   conocen.
6. **Interludio** (§7): Coco (`zona_<n>_completada`) antes que el Coleccionauta (`livianita_<n>`); la 2,
   cortada tras "¡amarillo limón!".
7. **Logros comunes**: el número de `piezas_puestas_<n>` y `pares_juntados_<n>` es lo conservado **en
   esa ronda**, nunca lo de rondas anteriores.
8. **El "sluurp" de la voz del Coleccionauta** (`entrada_aspira`, `*_coleccionauta_aspira`) es él
   imitando el sorbete. Si se superpone con el SFX de sorbete (≤ 1,5 s, m7), papá puede grabar la
   línea sin el "sluurp" y dejarlo al SFX.
9. **Para `director-cinematicas`**: las intros nuevas de Formas y Parejas duran ≈ 3 s (antes 2,5), y su
   gag del Coleccionauta baja a ≈ 1 s: la intro total queda en ≈ 4 s, en el tope. Si el audio real de
   Coco pasa de 3 s, se acorta el gag (papá lo dice más corto), no la frase. La guirnalda destella en
   "lucecitas". `nuestra_nave` (0,9 s) va al formarse la nave, con las caritas en las ventanitas
   (storyboard §6, que la dejaba sin voz: es la "voz de una palabra y ≤ 1 s" que permitía).
10. **Resbalón del pase (para `disenador-mecanicas`, ficha v6.1 §4.3)**: la ficha dice hoy "Sin voz del
    rival" en el resbalón, para no pisar el "¡Le toca a…!". El PO pidió una reacción corta suya
    (`resbala_01/02`, §5.3). No se pisan: suena **después** del "¡Le toca a…!", con el rival ya
    sentado y la puerta cerrada, y si no cabe en 1 s no suena. Hay que actualizar esa línea de la ficha
    y sumar la clave `rival_resbala` (variantes) a `lineas_voz` (la lee el `GestorTurnos`, como
    `rival_retrocede`).
11. **N13 solo en Parejas**: `guardala_proximo_turno` lo dispara el motor `emparejar` (escucha
    `turno_cerrado(id, perfecto)`), no el gestor. Formas no lo lleva.

### 10.1 Tabla clave → id para conectar los `"PENDIENTE"` de los datos

Rutas relativas a `assets/audio/`. "Secuencia" = arreglo que suena en orden; "variantes" = arreglo al
azar sin repetir la anterior. **`""` (vacío) = sin voz a propósito**: el motor no reproduce nada y no
avisa. `datos/batallas/arcoiris_final.json` **no tiene claves de voz `PENDIENTE`** (sus `cinematica_*`
ya tienen ids); la que sí falta es `voz_hito` de `mapa.json`.

| archivo | clave | valor | ids |
|---|---|---|---|
| `datos/planetas/arcoiris/mapa.json` | `batalla.voz_hito` | variantes | `arcoiris_batalla_hito_01`, `arcoiris_batalla_hito_02` |
| `batalla/rio_equipo.json` | `intro_ronda` | secuencia | `arcoiris_batalla_rio_intro_coleccionauta`, `arcoiris_batalla_rio_intro` |
| `batalla/rio_equipo.json` | `maxi_toca_donde_quieras` | variantes | `arcoiris_batalla_rio_maxi_toca_01`, `_02` |
| `batalla/rio_equipo.json` | `justo_ahi` | variantes | `arcoiris_batalla_rio_justo_ahi_01`, `_02` |
| `batalla/rio_equipo.json` | `maxi_regalito` | ruta | `arcoiris_equipo_maxi_regalito` |
| `batalla/rio_equipo.json` | `gafas_rojas` | ruta | `arcoiris_batalla_rio_coleccionauta_reacciona_02` (reutilizada) |
| `batalla/rio_equipo.json` | `derrota_gag_equipo` | secuencia | `arcoiris_batalla_rio_coleccionauta_aspira`, `arcoiris_batalla_rio_coleccionauta_estornuda`, `arcoiris_emparejar_equipo_coleccionauta_cansado`, `arcoiris_batalla_rio_coco_risa` |
| `batalla/rio_equipo.json` | `logro_comun` | mapa "N" | "1"-"9" → `nucleo_equipo_gotas_reventadas_01`; "10"-"19" → `nucleo_equipo_gotas_reventadas_02` |
| `batalla/formas_equipo.json` | `figuras[nave_de_juguete].voz_completa` | ruta | `arcoiris_batalla_formas_nuestra_nave` |
| `batalla/formas_equipo.json` | `intro_ronda` | secuencia | `arcoiris_batalla_formas_intro_coleccionauta`, `arcoiris_batalla_formas_intro` |
| `batalla/formas_equipo.json` | `maxi_pieza_que_brilla` | ruta | `arcoiris_batalla_formas_maxi_brilla` |
| `batalla/formas_equipo.json` | `maxi_regalito` | ruta | `arcoiris_equipo_maxi_regalito` |
| `batalla/formas_equipo.json` | `caritas_ventanitas` | `""` | Sin voz: la voz de ese momento es `voz_completa` (`nuestra_nave`), que suena en el mismo instante. Así no suenan dos |
| `batalla/formas_equipo.json` | `derrota_gag_equipo` | secuencia | `arcoiris_batalla_formas_coleccionauta_aspira`, `arcoiris_batalla_formas_coleccionauta_estornuda`, `arcoiris_emparejar_equipo_coleccionauta_cansado`, `arcoiris_batalla_formas_coco_risa` |
| `batalla/formas_equipo.json` | `logro_comun` | mapa "N" | "1"-"11" → `nucleo_equipo_piezas_puestas_1` … `_11` |
| `batalla/parejas_equipo.json` | `intro_ronda` | secuencia | `arcoiris_batalla_parejas_intro_coleccionauta`, `arcoiris_batalla_parejas_intro` |
| `batalla/parejas_equipo.json` | `lupa_coleccionauta` | ruta | `arcoiris_batalla_parejas_lupa_gafas` (solo si no la formó Maxi y la cola está libre) |
| `batalla/parejas_equipo.json` | `maxi_regalito` | ruta | `arcoiris_equipo_maxi_regalito` |
| `batalla/parejas_equipo.json` | (`logro_comun`) | — | No hace falta: el respaldo `pares_juntados` 1-12 ya está en el archivo (se usan 1-11) |
| `batalla/pinta_mochila_equipo.json` | `intro_epilogo` | `""` | Sin voz en el motor: la intro es la cinemática "antes del epílogo" (`epilogo_antes_coleccionauta` + `epilogo_antes_coco`), y al retomar suena solo `maxi_ven` (storyboard §10) |
| `batalla/pinta_mochila_equipo.json` | `maxi_ven_a_pintar` | ruta | `arcoiris_batalla_epilogo_maxi_ven` |
| `batalla/pinta_mochila_equipo.json` | `ahora_hermano` | por hermano | `maxi` → `nucleo_equipo_ahora_maxi` (**falta la clave**: se usa en la tapa), `nicole` → `nucleo_equipo_ahora_nicole`, `sofia` → `nucleo_equipo_ahora_sofia` |
| `batalla/pinta_mochila_equipo.json` | `todos_juntos` | ruta | `arcoiris_batalla_epilogo_tapa` |
| `batalla/pinta_mochila_equipo.json` | `mochila_estornuda_confeti` | `""` | Sin voz: el estornudo es SFX ("¡achís!" agudo) y abre el cierre A (storyboard §6) |
| `batalla/pinta_mochila_equipo.json` | `victoria_final` | `""` | Sin voz en el motor: la celebración final es el cierre A (`cierre_*`), que reproduce `batalla.gd`. Si el motor la tocara, se oiría dos veces |
| `zona1..5/parejas_equipo.json` | `maxi_regalito` | ruta | `arcoiris_equipo_maxi_regalito` |
| `zona1..5/parejas_equipo.json` | `intro_equipo_trucos.equipo` | ruta | `arcoiris_emparejar_equipo_intro_trucos_equipo` (cierre **con** tope; en `voces-modo-equipo-parejas.md` §3.1, v3) |
| (ficha §8; aún no en los JSON) | `intro_equipo_trucos.equipo_racha` | ruta | `arcoiris_emparejar_equipo_intro_trucos_equipo_racha` (cierre **sin** tope; ídem) |

**Claves que el guion usa y que todavía no están en los JSON** (propuesta para Dev; sin ellas el motor
sigue sin voz y no falla):

| archivo | clave propuesta | ids |
|---|---|---|
| los 3 de ronda + epílogo | `repetir` (por perfil) | nota 3 |
| los 3 de ronda | `turno_perfecto_presenta` | `nucleo_equipo_turno_perfecto_presenta` |
| `batalla/parejas_equipo.json` y `zona1..5/parejas_equipo.json` (solo Parejas) | `guardala_proximo_turno` | `arcoiris_equipo_guardala` |
| los 3 de ronda y `zona1..5/parejas_equipo.json` | `rival_resbala` (variantes) | `nucleo_equipo_coleccionauta_resbala_01/02` (nota 10) |
| `zona1..5/parejas_equipo.json` (composiciones con tope) | `intro_equipo_tope` (secuencia) | `arcoiris_emparejar_equipo_intro_tope`, `arcoiris_emparejar_equipo_intro_ayudan` (en lugar de `intro_equipo`, desde la segunda partida) |
| `rio_equipo.json` | `gotas_mano` | `arcoiris_batalla_rio_gotas_mano` |
| `rio_equipo.json` | `maxi_revienta` (variantes) | `arcoiris_batalla_rio_maxi_revienta_01/02` |
| `rio_equipo.json` | `acierto_equipo` (variantes) | `arcoiris_batalla_rio_acierto_01..03` |
| `rio_equipo.json` | `cadena` | `arcoiris_batalla_rio_cadena` |
| `rio_equipo.json` | `rival_retrocede_celebra` | `arcoiris_batalla_rio_retrocede_celebra` |
| `rio_equipo.json` | `rival_reacciona` (variantes, máx. 1 de 3) | `arcoiris_batalla_rio_coleccionauta_reacciona_01/02` |
| `formas_equipo.json` | `fiu_perfil` | `brote` → `arcoiris_batalla_formas_fiu_derechas`; `estrella` → `arcoiris_batalla_formas_fiu_giran` |
| `formas_equipo.json` | `maxi_brilla_otra` | `arcoiris_batalla_formas_maxi_brilla_02` |
| `formas_equipo.json` | `maxi_pieza` | `arcoiris_batalla_formas_maxi_pieza` |
| `formas_equipo.json` | `acierto_equipo` / `fallo_equipo` (variantes) | `arcoiris_batalla_formas_acierto_01..03` / `fallo_01/02` |
| `formas_equipo.json` | `rival_reacciona` (variantes, máx. 1 de 3) | `arcoiris_batalla_formas_coleccionauta_reacciona_01/02` |
| `formas_equipo.json` | `porras_fin_maxi` | `arcoiris_emparejar_equipo_porras_fin_maxi` (no está en el archivo de Formas ni del Río) |
| `pinta_mochila_equipo.json` | `parte_pintada` (variantes) / `parte_rival` (en orden) | `arcoiris_batalla_epilogo_parte_coco_01..03` / `parte_coleccionauta_1..3` |
| `pinta_mochila_equipo.json` | `regalo_hermano` (niños, opcional) | `arcoiris_batalla_epilogo_regalo_<hermano>` |

---

## 11. Guion de grabación casera (para papá)

Todas las líneas del Coleccionauta, más las de papá como él mismo. Grabar en `.wav`, en un cuarto sin
eco, con 0,5 s de silencio antes y después. Registro del Coleccionauta: **grandilocuente-tonto, nunca
de malo**; si una línea suena a amenaza, se repite más chistosa.

| # | id | texto | intención | dónde suena |
|---|---|---|---|---|
| 1 | arcoiris_batalla_teaser_coleccionauta | «¿Un planeta que recupera colores? ¡Para mi colección! ...Permiso, permiso, ¡voy saliendo!» | grandioso, después torpe y apurado | Se cuela en la video-llamada de la zona 3 |
| 2 | arcoiris_batalla_teaser_papa (papá) | «¡Jajaja! ¡Allá va, con su mochila! Tranquilos, que ese se tropieza hasta con su sombra.» | muerto de la risa | Ídem, justo después |
| 3 | arcoiris_batalla_hito_01 | «¡Hola, hola! ¿Quién quiere jugar conmigo? ¡Traje mi mochila!» | vecino simpático | El hito de la batalla en el mapa |
| 4 | arcoiris_batalla_hito_02 | «¡Yujuu! Aquí estoy... con galletas. Para mí. ...Bueno, les convido una.» | goloso y después generoso | Ídem, variante |
| 5 | arcoiris_batalla_entrada_aspira | «¡Ooh, qué colores más lindos! ¡Para mi colección! Sluurp... ¡Je, me hizo cosquillas!» | encantado, como en una dulcería | Entrada: aspira el arcoíris |
| 6 | arcoiris_batalla_entrada_reto | «¿Los quieren de vuelta? ¡Gánenme tres juegos! ...¿O eran dos?» | desafío de juego, se confunde contando | Entrada: el reto |
| 7 | arcoiris_batalla_rio_intro_coleccionauta | «¡Pintuuura!» | goloso, estirando la "u" | Empieza el Río |
| 8 | arcoiris_batalla_rio_coleccionauta_reacciona_01 | «¡Ay, mis gotitas! ...Bueno, nunca fueron mías.» | quejón y después honesto | Río: un reventón |
| 9 | arcoiris_batalla_rio_coleccionauta_reacciona_02 | «¡Qué salpicón! ¡Me pintaron las gafas-lupa!» | sorprendido, con risa | Río: un reventón y las gafas rojas |
| 10 | arcoiris_batalla_rio_coleccionauta_aspira | «¡Llegué a la orilla! ¡Todas las gotas a mi colección! Sluurp...» | triunfal de mentira | Río: si pierden |
| 11 | arcoiris_batalla_rio_coleccionauta_estornuda | «¡Hip! ¿Hipo de pintura? A... a... ¡ACHÚU!» | hipo y estornudo enorme | Río: si pierden |
| 12 | arcoiris_batalla_formas_intro_coleccionauta | «¡Piecitas!» | encantado | Empieza Formas |
| 13 | arcoiris_batalla_formas_coleccionauta_reacciona_01 | «¡Ay, esa pieza era para mi colección! ...¿O era un queque?» | indignado de mentira, confundido | Formas: una pieza calza |
| 14 | arcoiris_batalla_formas_coleccionauta_reacciona_02 | «¡Calzó! ¿Cómo saben dónde va? Yo meto todo en la mochila.» | asombrado de verdad | Ídem, variante |
| 15 | arcoiris_batalla_formas_coleccionauta_aspira | «¡Llegué! ¡Todas las piezas a mi colección! Sluurp...» | triunfal de mentira | Formas: si pierden |
| 16 | arcoiris_batalla_formas_coleccionauta_estornuda | «¡Uy, me pica una esquina! A... a... ¡ACHÚU!» | incómodo, estornudo enorme | Formas: si pierden |
| 17 | arcoiris_batalla_parejas_intro_coleccionauta | «¡Cartitas!» | encantado | Empieza Parejas |
| 18 | arcoiris_batalla_parejas_lupa_gafas | «¡Eh! ¡Esas son mis gafas!» | sorprendido, palpándose la cara | **[v2]** Parejas: se forma la pareja lupa |
| 19 | nucleo_equipo_coleccionauta_resbala_01 | «¡Uuuy! ¡Galleta resbalosa!» | sorprendido y risueño, sentado; **máximo 1,5 s** | **[v2]** Se resbala en su galleta tras un turno perfecto (batalla y Parejas en equipo) |
| 20 | nucleo_equipo_coleccionauta_resbala_02 | «¡Ups! ...Me senté. Je, je.» | avergonzado de chiste; **máximo 1,5 s** | Ídem, variante |
| 21 | arcoiris_batalla_livianita_1 | «¡Uy! ¡Mi mochila está más livianita!» | sorprendido y contento | Ganan el rojo |
| 22 | arcoiris_batalla_livianita_2 | «¡Otro piso menos! ¡Ahora salto más alto! Boing...» | saltando | Ganan el amarillo |
| 23 | arcoiris_batalla_livianita_3 | «¡Uy, uy, uy! ¡Mi mochila ya no pesa nada!» | desconcertado, flotando | Ganan el azul |
| 24 | arcoiris_batalla_epilogo_antes_coleccionauta | «Mochila vacía... ¿y ahora qué colecciono?» | dramático de teleserie, chistoso | Antes de pintar la mochila |
| 25 | arcoiris_batalla_epilogo_parte_coleccionauta_1 | «¡Ooh! ¡Mi mochila tiene un color!» | asombro de niño chico | Epílogo: 1.ª parte pintada |
| 26 | arcoiris_batalla_epilogo_parte_coleccionauta_2 | «¡Otro más! ¿Me están regalando colores?» | no lo puede creer | Epílogo: 2.ª parte |
| 27 | arcoiris_batalla_epilogo_parte_coleccionauta_3 | «Nadie me había regalado nada... Bueno, una vez un calcetín.» | emocionado, y el chiste al final | Epílogo: 3.ª parte |
| 28 | arcoiris_batalla_cierre_mira | «¡Mi mochila de colores! Es la cosa más incre... incre... ¡ay, no me sale de lo linda que está!» | grande y después atorado | Cierre: se mira la mochila |
| 29 | arcoiris_batalla_cierre_equipo | «Ya entendí... un equipo no cabe en una mochila.» | pensativo, sin solemnidad | Cierre: mira a los tres |
| 30 | arcoiris_batalla_cierre_despedida | «¡Me voy, me voy! Pero un día vuelvo... ¡con una mochila más grande! ¡Chao! ...¿Para qué lado era la salida?» | alegre, final perdido | Cierre: se despide |
| 31 | arcoiris_batalla_cierre_papa_01 (papá) | «¡Esa foto! Los tres juntitos... ¡me la pongo de fondo de pantalla!» | orgulloso | Video-llamada final (si el PO la aprueba) |
| 32 | arcoiris_batalla_cierre_papa_02 (papá) | «Oigan, acá llegó el Coleccionauta, todo pintado y cantando. ¡Nunca lo había visto tan contento!» | chisme divertido | Ídem |
| 33 | arcoiris_batalla_cierre_papa_03 (papá) | «¿Saben por qué el arcoíris nunca pelea? ¡Porque cada color se queda en su raya! Los quiero mucho. Jueguen tranquilos, que acá estoy feliz.» | chiste de papá y cierre cálido | Ídem, al final |

Consejo para las palabras sueltas (#7, #12, #17) y los resbalones (#19, #20): son gags de un segundo.
Mejor grabar tres tomas seguidas y elegir la más corta y chistosa.

Las de los niños (opcionales, los tres o ninguno): `arcoiris_batalla_epilogo_regalo_maxi/nicole/sofia`,
«¡Para ti!».

---

## 12. Conteo

| bloque | Coco (TTS) | Cometa (TTS) | Coleccionauta (papá) | Papá (familiar) | niños (opcional) | total |
|---|---|---|---|---|---|---|
| §1 Teaser | — | — | 1 | 1 | — | 2 |
| §2 Hito, nave, retomar | — | 5 | 2 | — | — | 7 |
| §3 Entrada | 1 | — | 2 | — | — | 3 |
| §4 Ronda 1, Río | 14 | 4 | 5 | — | — | 23 |
| §5 Ronda 2, Formas (incluye el resbalón) | 13 | 17 | 7 | — | — | 37 |
| §6 Ronda 3, Parejas | 1 | 4 | 2 | — | — | 7 |
| §7 Entre rondas | 7 | — | 3 | — | — | 10 |
| §8 Epílogo y cierre | 7 | 5 | 7 | 3 | 3 | 25 |
| **Total nuevas** | **43** | **35** | **29** | **4** | **3** | **114** |

Cambios contra la v1 (105): −1 `formas_retrocede_celebra`, −1 `formas_repetir`; +1
`todos_nave_corta`, +2 `formas_repetir_brote/estrella`, +1 `turno_perfecto_presenta`, +1
`nuestra_nave`, +2 `parejas_repetir_tope_brote/estrella`, +1 `lupa_gafas`, +1 `guardala`, +2
`coleccionauta_resbala_01/02`.

- **TTS nuevas (para estimar el costo)**: **78 líneas** (43 de Coco y 35 de Cometa), ≈ **3.400
  caracteres** en total (≈ 1.400 de Coco y ≈ 2.000 de Cometa). Las más largas son las 11 de
  `piezas_puestas_*` (≈ 58 caracteres cada una) y las `*_repetir` (≈ 80-130). **Antes de generar:
  `--estimar` y OK del PO sobre el costo.**
- **Grabación casera**: 29 del Coleccionauta (papá) + 4 de papá como él mismo (si el PO decide la
  video-llamada) = **33 líneas**, todas en la tabla del §11. Más 3 opcionales de los niños.
- **Reutilizadas sin grabar**: **91** (§9), más `rio_coleccionauta_reacciona_02` reutilizada dentro de
  este guion para las gafas rojas. Ojo: casi todas están **pendientes de audio** en su propio guion
  (HE-58), así que la batalla necesita que ese lote también se genere.
- **Fuera de este conteo**: las 20 líneas de reto de Parejas en solitario (HE-60, §13) y las 3 nuevas
  de la intro de Parejas en equipo con tope; ambas viven en `voces-modo-equipo-parejas.md`.

---

## 13. HE-60: voces de reto de Parejas en solitario (B1 de su validación UX)

La validación `docs/validaciones/2026-10-07_ux-HE-60-parejas-reto.md` (B1) pide como mínimo
`vistazo_presenta`, `vistazo_mira`, `vela_presenta`, `vela_dormida`, `record_pasa`, `primer_record`,
`record_nuevo_01/02` y `estrellitas_brote_1..3` antes del playtest. **Todas ya tienen guion** en
`docs/guiones/voces-modo-equipo-parejas.md` §6 y §6.1, con los mismos ids y rutas que esperan
`motor_emparejar.gd` (claves `vela_presenta`, `vela_dormida`, `vela_encendida`, `vistazo`,
`vistazo_presenta`, `racha`, `a_la_primera`, `record_*`, `estrellitas_brote`, `otra_estrellita`) y los 15
`parejas_{brote,estrella}.json` de las zonas (`voces/arcoiris/emparejar/reto/`). No se escriben de
nuevo aquí.

| clave del motor | id | texto (resumen) |
|---|---|---|
| `vela_presenta` | `arcoiris_emparejar_reto_vela_presenta` | «¿Ves la velita? Si terminas antes de que se apague, ¡puntos extra!» |
| `vela_dormida` | `arcoiris_emparejar_reto_vela_dormida` | «Shhh... la velita se quedó dormida. ¡Tú sigue, que cada pareja suma!» |
| `vela_encendida` | `arcoiris_emparejar_reto_vela_encendida` | «¡La velita sigue encendida! ¡Puntos de regalo!» |
| `vistazo` (el "¡mira!") | `arcoiris_emparejar_reto_vistazo_mira` | «¡Mira!» |
| `vistazo_presenta` | `arcoiris_emparejar_reto_vistazo_presenta` | «Al repartir, te muestro unas cartas un ratito. ¡Míralas bien!» |

Lo que falta es **generar el audio**, no escribirlo: son 20 líneas TTS de Coco (≈ 700 caracteres), y
conviene incluirlas en el **mismo lote** que la batalla, primero en la cola, porque bloquean el playtest
de HE-60.
