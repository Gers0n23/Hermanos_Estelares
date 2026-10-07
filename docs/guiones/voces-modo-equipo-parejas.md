# Guion de voz — Modo "¡Juntos!" y mejoras de Parejas de Coco (HE-58)

> Encargo de HE-58 (parte de guion). Fuentes: `docs/fichas/modo-equipo.md` (todo, en especial §3, §4,
> §5 y §9) y `docs/fichas/motor-emparejar.md` §10. Este guion es **solo texto**: no genera audio ni toca
> los `.tsv`. Cuando el PO apruebe el costo del TTS, `dev-godot` copia las filas a su `lineas_tts.tsv`
> (con la directiva `# personaje:` correcta) y las líneas caseras se graban en familia.

- **Tono de referencia**: GDD §1 (Tono, derrota-gag), §2 (Cometa, Coleccionauta), `perfil-jugadores.md`
  (gestos canon, equidad Nicole/Sofía), `docs/guiones/zonas_arcoiris.md` (tic de Coco: anuncia el color
  que "es" ahora) y `docs/guiones/prueba_final_cooperativa.md` (tic del Coleccionauta: habla en grande y
  se equivoca en chico).
- **Voces**:
  - **Coco** y **Cometa**: voz oficial TTS (fal.ai). Generar solo con `--estimar` y con el OK del PO
    sobre el costo.
  - **El Coleccionauta**: **no tiene voz TTS**. Casting de `guion_voces.md`: **papá**, en su registro
    "grandilocuente-tonto". Todas sus líneas son de **grabación casera**.
  - **Los niños** (opcional, marcado "niños"): grabación casera de Maxi, Nicole y Sofía con su propia
    voz. Si no se graban, la animación va sin voz y no falta nada.
- **Rutas** relativas a `assets/audio/`, en `.wav` como los `.tsv` actuales. Siguiendo la regla R8 de la
  ficha (capa genérica), lo que sirve para **cualquier** juego en equipo va a `voces/nucleo/equipo/`, y
  lo propio de Parejas o del Planeta Arcoíris va a `voces/arcoiris/...`.
- **Id estable**: la convención del proyecto. `nucleo_` + ruta sin `voces/nucleo/` ni extensión;
  `arcoiris_` + ruta sin `voces/arcoiris/` ni extensión. Ej.: `voces/nucleo/equipo/le_toca_maxi_01.wav`
  → `nucleo_equipo_le_toca_maxi_01`.
- **Estado**: las 122 líneas son **nuevas** y están **pendientes de audio**.

## Decisiones de tono de este guion

1. **Nadie falla con nombre.** Las líneas de "no era" en equipo nunca dicen el nombre de quien jugó y
   convierten el fallo en un dato para todos: "ahora **todos** sabemos dónde están". Es la memoria
   compartida de la alternativa A hecha voz, y es la cooperación mostrada, no declamada.
2. **El acierto en equipo tampoco lleva nombre** (salvo Maxi en su turno guiado). Así nadie cuenta
   "a mí me dijo bravo tres veces". Con Maxi no hay riesgo de celos (la ficha de Sofía lo dice) y
   a los 2 años escuchar su nombre es el premio.
3. **"¡Le toca a…!" con equidad exacta**: 3 variantes por hermano, del mismo largo y la misma
   estructura. La 02 imita su **gesto canon** (Maxi "¡síii!", Nicole el corazoncito, Sofía el guiño) y
   la 03 juega con algo suyo (el dino; los ojos de jirafa; un "cerebro estelar", más de chiste
   inteligente para Sofía). Ninguna compara ni dice "la más…".
4. **El Coleccionauta, rival de risa.** Cada línea suya parte grande y termina chica (su tic): salta
   y no sabe contar galletas, se le caen las gafas, se olvida de avanzar por mirar a Maxi. En la
   derrota su colección **estornuda** las cartas de vuelta y él queda sentado diciendo la línea de la
   ficha ("cuesta guardar tantas cosas solo"). En la victoria pregunta **dónde se compra un equipo** o
   si cabe en su mochila: siembra la lección final (los amigos no se coleccionan) sin decirla. **Nunca
   menciona a papá** en este modo: así nadie pregunta "¿y papá?" en medio de un juego de cartas.
5. **Cuidado con Maxi y el Coleccionauta.** Él colecciona "cosas increíbles" y se llevó a papá por
   increíble. Por eso, cuando se queda embobado con Maxi, **no dice "increíble" ni nada de llevárselo**:
   lo admira como un vecino que aplaude ("qué bien juega ese chiquitito"). Pedido a
   `disenador-personajes`: que en ese gag no estire los brazos hacia Maxi.
6. **El fallo del equipo es un estornudo, no una pérdida.** Coco dice siempre, en la misma línea del
   "¡otra vez!", que **las parejas hechas se quedan** (cero progreso perdido, dicho para el oído).
7. **La racha sube sin castigo al cortarse.** Hay voz para cada nivel de racha y **ninguna** para el
   corte: el "fiuu" de los nuditos basta. Una voz al cortarse sería un "perdiste" disfrazado.
8. **El récord es contra uno mismo**: "le ganaste a **tu propio** récord". Ninguna línea de récord
   lleva nombre, para que Nicole y Sofía escuchen exactamente lo mismo.
9. **La caja de cartas de Coco y el arco del Coleccionauta**: Coco guarda cartas en una caja, como él.
   La diferencia se muestra con una línea: sus cartas son "para mirarlas juntos". No hay sermón.
10. **Sin apuro**: ninguna línea dice "rápido" ni "apúrate". La vela del tiempo par se presenta como
    "puntos extra", nunca como "se acaba el tiempo". La lupa dura "un segundito", no "rapidito".

---

## 1. Selección: el botón "¡Juntos!" y armar el equipo

Suena en `seleccion_personaje.gd` en modo equipo (ficha de modo equipo §3.1 y §3.2). Ruta base
`voces/nucleo/equipo/`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_juntos | Cometa | «¡Vamos juntos!» | eufórico, con salto en la voz | Tocar el botón "¡Juntos!" (la nave da un saltito) | `voces/nucleo/equipo/juntos.wav` | TTS |
| nucleo_equipo_armar | Cometa | «¿Quiénes juegan juntos hoy? Si alguien quiere mirar, tócalo... ¡y se sienta en el puf! Después, ¡a despegar!» | invitando, alegre; pausa antes del puf | Al entrar a armar equipo (reemplaza la línea de la ficha §3.2, que no nombraba el puf) | `voces/nucleo/equipo/armar.wav` | TTS |
| nucleo_equipo_al_puf_01 | Cometa | «¡Al puf! Desde ahí también se ayuda.» | cómplice, cariñoso | Tocar una tarjeta: el hermano sale y se sienta en el puf | `voces/nucleo/equipo/al_puf_01.wav` | TTS |
| nucleo_equipo_al_puf_02 | Cometa | «¡A mirar desde el puf! ¡Qué cómodo!» | relajado, con risa; "cómodo" estirado | Variante de `al_puf` (al azar) | `voces/nucleo/equipo/al_puf_02.wav` | TTS |
| nucleo_equipo_vuelve | Cometa | «¡De vuelta a la nave!» | feliz de que vuelva | Tocar una tarjeta del puf: el hermano vuelve al asiento (si no hay grabación de los niños) | `voces/nucleo/equipo/vuelve.wav` | TTS |
| nucleo_equipo_minimo_dos | Cometa | «¡Para jugar en equipo se necesitan al menos dos!» | explicando con cariño, sin reproche | Intentar sacar a uno cuando quedan dos (la tarjeta se mece) | `voces/nucleo/equipo/minimo_dos.wav` | TTS |
| nucleo_equipo_despegar | Cometa | «¡Despegamos! Tres, dos, uno... ¡fiuuu!» | cuenta regresiva de juego; el "fiuuu" largo, para Maxi | Tocar "¡Despegar!" | `voces/nucleo/equipo/despegar.wav` | TTS |
| nucleo_equipo_yo_tambien_maxi | Maxi | «¡Yo también!» | como le salga; gritado está perfecto | Maxi vuelve del puf al asiento (reemplaza a `vuelve`) | `voces/nucleo/equipo/yo_tambien_maxi.wav` | niños (opcional) |
| nucleo_equipo_yo_tambien_nicole | Nicole | «¡Yo también!» | contenta | Nicole vuelve al asiento | `voces/nucleo/equipo/yo_tambien_nicole.wav` | niños (opcional) |
| nucleo_equipo_yo_tambien_sofia | Sofía | «¡Yo también!» | contenta | Sofía vuelve al asiento | `voces/nucleo/equipo/yo_tambien_sofia.wav` | niños (opcional) |

Mapa del Planeta Arcoíris en modo equipo (ficha §3.3). Ruta base `voces/arcoiris/mapa/`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_mapa_equipo_llegada | Coco | «¡Llegó el equipo! Vengan, las parejas se juegan todos juntos.» | acogedora, abriendo los brazos | Entrar al mapa en modo equipo | `voces/arcoiris/mapa/equipo_llegada.wav` | TTS |
| arcoiris_mapa_equipo_estacion_pronto | Coco | «¡Este juego todavía lo estoy preparando para jugar en equipo!» | ilusionada, nunca "no se puede" | Tocar una estación sin `nivel_equipo` | `voces/arcoiris/mapa/equipo_estacion_pronto.wav` | TTS |

---

## 2. "¡Le toca a…!" (pase de turno)

Suena en el paso 2 del pase de turno (ficha §4.3), cuando el retrato vuela al centro. La UI elige una
variante al azar sin repetir la anterior. Voz de Cometa porque es la capa genérica de turnos (sirve
para cualquier juego en equipo). Ruta base `voces/nucleo/equipo/`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_le_toca_maxi_01 | Cometa | «¡Le toca a Maxi!» | fiesta, anunciando | Turno de Maxi | `voces/nucleo/equipo/le_toca_maxi_01.wav` | TTS |
| nucleo_equipo_le_toca_maxi_02 | Cometa | «¡Maxi, tu turno! ¡Síii!» | el "síii" como el de Maxi (su gesto) | Variante | `voces/nucleo/equipo/le_toca_maxi_02.wav` | TTS |
| nucleo_equipo_le_toca_maxi_03 | Cometa | «¡Ahora juega Maxi! ¡Grrr, como un dino!» | "grrr" de dino de juguete, nada de miedo | Variante | `voces/nucleo/equipo/le_toca_maxi_03.wav` | TTS |
| nucleo_equipo_le_toca_nicole_01 | Cometa | «¡Le toca a Nicole!» | fiesta, anunciando | Turno de Nicole | `voces/nucleo/equipo/le_toca_nicole_01.wav` | TTS |
| nucleo_equipo_le_toca_nicole_02 | Cometa | «¡Nicole, tu turno! ¡Corazoncito listo!» | tierno (su corazón coreano) | Variante | `voces/nucleo/equipo/le_toca_nicole_02.wav` | TTS |
| nucleo_equipo_le_toca_nicole_03 | Cometa | «¡Ahora juega Nicole! ¡Ojos de jirafa, lo ve todo!» | asombrado, juguetón | Variante | `voces/nucleo/equipo/le_toca_nicole_03.wav` | TTS |
| nucleo_equipo_le_toca_sofia_01 | Cometa | «¡Le toca a Sofía!» | fiesta, anunciando | Turno de Sofía | `voces/nucleo/equipo/le_toca_sofia_01.wav` | TTS |
| nucleo_equipo_le_toca_sofia_02 | Cometa | «¡Sofía, tu turno! ¡Guiño, guiño!» | pícaro (su guiño) | Variante | `voces/nucleo/equipo/le_toca_sofia_02.wav` | TTS |
| nucleo_equipo_le_toca_sofia_03 | Cometa | «¡Ahora juega Sofía! ¡Cerebro estelar encendido!» | de robot de juguete, "encendido" con "bip" | Variante | `voces/nucleo/equipo/le_toca_sofia_03.wav` | TTS |
| nucleo_equipo_te_toca_maxi | Cometa | «¡Maxi, te toca! Toca la pantalla.» | llamando con cariño, sin apuro | 10 s sin tocar la puerta de turno | `voces/nucleo/equipo/te_toca_maxi.wav` | TTS |
| nucleo_equipo_te_toca_nicole | Cometa | «¡Nicole, te toca! Toca la pantalla.» | ídem | ídem | `voces/nucleo/equipo/te_toca_nicole.wav` | TTS |
| nucleo_equipo_te_toca_sofia | Cometa | «¡Sofía, te toca! Toca la pantalla.» | ídem | ídem | `voces/nucleo/equipo/te_toca_sofia.wav` | TTS |
| nucleo_equipo_maxi_ayuda | Cometa | «¿Maxi se fue a jugar? ¡Alguien puede tocar por él!» | divertido, sin reto; invita a ayudar | Turno de Maxi: 10 s después de `te_toca_maxi` sin toque | `voces/nucleo/equipo/maxi_ayuda.wav` | TTS |

---

## 3. Parejas de Coco en equipo: reglas, turnos y ánimo

Ruta base `voces/arcoiris/emparejar/equipo/`. Voz de Coco, la anfitriona.

### 3.1 Inicio y vistazo

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_intro | Coco | «¡Jugamos todos juntos! Si encuentras una pareja, sigues jugando. Si no, le toca al siguiente.» | clara, alegre; pausa entre las dos reglas | Al entrar a la estación en equipo | `voces/arcoiris/emparejar/equipo/intro.wav` | TTS |
| arcoiris_emparejar_equipo_intro_ayudan | Coco | «¡Y los que miran, ayudan a recordar!» | cómplice, mirando a los del puf | Justo después de `intro` | `voces/arcoiris/emparejar/equipo/intro_ayudan.wav` | TTS |
| arcoiris_emparejar_equipo_vistazo | Coco | «¡Mírenlas bien, equipo!» | entusiasta, en plural | Vistazo al repartir en equipo (ficha §5.4) | `voces/arcoiris/emparejar/equipo/vistazo.wav` | TTS |

### 3.2 Turno guiado de Maxi

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_maxi_brillan_01 | Coco | «¡Maxi, toca las que brillan!» | lenta, cálida | Empieza el turno de Maxi (las dos cartas con halo) | `voces/arcoiris/emparejar/equipo/maxi_brillan_01.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_brillan_02 | Coco | «¡Mira, Maxi! ¡Brillan para ti!» | maravillada | Variante; también tras tocar una carta sin halo (después de que Coco dice el nombre de la figura) | `voces/arcoiris/emparejar/equipo/maxi_brillan_02.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_aqui | Coco | «¡Aquí están, Maxi! ¡Tócalas!» | animando, señalando | Las dos cartas de su pareja quedan a la vista (2 toques fuera o 6 s) | `voces/arcoiris/emparejar/equipo/maxi_aqui.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_par | Coco | «¡Bravo, Maxi! ¡Una pareja para el equipo!» | fiesta grande | Maxi forma su pareja (fin de su turno) | `voces/arcoiris/emparejar/equipo/maxi_par.wav` | TTS |

Cuando Maxi toca una carta sin halo, Coco dice el nombre de la figura con las voces que ya existen
(`emparejar/paises/*`, `colores/*` y las de figuras del catálogo). No hace falta voz nueva.

### 3.3 Ánimo del equipo (Nicole y Sofía)

Sin nombre a propósito (decisiones 1 y 2). Al azar, sin repetir la anterior.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_acierto_01 | Coco | «¡Una pareja para el equipo!» | fiesta | Par formado en turno de Nicole o Sofía | `voces/arcoiris/emparejar/equipo/acierto_01.wav` | TTS |
| arcoiris_emparejar_equipo_acierto_02 | Coco | «¡Eso! ¡Y sigues jugando!» | alegre; recuerda la regla de mesa | Variante | `voces/arcoiris/emparejar/equipo/acierto_02.wav` | TTS |
| arcoiris_emparejar_equipo_acierto_03 | Coco | «¡Pareja! ¡A la cinta arcoíris!» | cantarina | Variante | `voces/arcoiris/emparejar/equipo/acierto_03.wav` | TTS |
| arcoiris_emparejar_equipo_acierto_04 | Coco | «¡Bien! ¡Otra vuelta para ti!» | contenta | Variante | `voces/arcoiris/emparejar/equipo/acierto_04.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_01 | Coco | «¡Uy! Pero ahora todos sabemos dónde están.» | liviana, positiva al final | "No es este" que termina el turno | `voces/arcoiris/emparejar/equipo/fallo_01.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_02 | Coco | «¡Casi! Equipo, ¡acuérdense de esas dos!» | cómplice, hablando a todos | Variante | `voces/arcoiris/emparejar/equipo/fallo_02.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_03 | Coco | «¡No era! Pero esas cartas ya no se nos esconden.» | pícara | Variante | `voces/arcoiris/emparejar/equipo/fallo_03.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_04 | Coco | «¡Ups! Ojos bien abiertos, equipo: ¡ahí quedaron!» | juguetona | Variante | `voces/arcoiris/emparejar/equipo/fallo_04.wav` | TTS |
| arcoiris_emparejar_equipo_nicole_otra | Coco | «¡Uy, otra! ¡Sigue, Nicole!» | dulce, rápida de decir | Primer "no es este" de Nicole en su turno (segunda oportunidad) | `voces/arcoiris/emparejar/equipo/nicole_otra.wav` | TTS |
| arcoiris_emparejar_equipo_brote_ayuda | Coco | «Esa carta que brilla... ¿se acuerdan de su pareja?» | misteriosa, pregunta al equipo | Turno de Nicole tras 2 turnos suyos sin par (brilla una carta ya vista) | `voces/arcoiris/emparejar/equipo/brote_ayuda.wav` | TTS |

`brote_ayuda` está en plural a propósito: invita a los del puf a soplarle a Nicole. La ayuda viene del
equipo, no "porque Nicole no puede".

---

## 4. El Coleccionauta, rival común

Todas sus líneas son de **grabación casera (papá)**. Lo genérico de la pista del rival (avanza, se
queda embobado, vuelve, aplaude) va en `voces/nucleo/equipo/coleccionauta/`, porque `pista_rival.gd`
es genérica. Lo que habla de cartas va en `voces/arcoiris/emparejar/equipo/`.

**Volumen de voces**: el Coleccionauta reacciona a los pares **1 de cada 3 veces como máximo** y
nunca encima de una línea de Coco. Las otras veces basta su cara de "¡ay, no!".

### 4.1 Llega y avanza

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_coleccionauta_entra | Coleccionauta | «¡Ajá! ¡Las cartas de Coco! Si llego a la mesa, ¡van a mi colección! ...¿Para qué lado era la mesa?» | grandilocuente y después perdido (su tic) | Al empezar la partida, tras `intro_ayudan` | `voces/arcoiris/emparejar/equipo/coleccionauta_entra.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coco_juntemos | Coco | «¡Juntemos todas las parejas antes de que llegue!» | divertida, de aventura, sin apuro | Respuesta a `coleccionauta_entra` | `voces/arcoiris/emparejar/equipo/coco_juntemos.wav` | TTS |
| nucleo_equipo_coleccionauta_avanza_01 | Coleccionauta | «¡Boing! Una galletita más cerca.» | saltarín, orgulloso | Avanza una galleta (fin de turno de Nicole o Sofía) | `voces/nucleo/equipo/coleccionauta/avanza_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_avanza_02 | Coleccionauta | «¡Jo, jo, ya casi! ...¿O no? Nunca sé contar galletas.» | risa tonta y después duda | Variante | `voces/nucleo/equipo/coleccionauta/avanza_02.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_avanza_03 | Coleccionauta | «¡Boing! ¡Uy, casi me como la galleta!» | goloso, con risa | Variante | `voces/nucleo/equipo/coleccionauta/avanza_03.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_avanza_04 | Coleccionauta | «Un saltito... ¡y otro saltito! Bueno, solo uno.» | se agranda y se desinfla | Variante | `voces/nucleo/equipo/coleccionauta/avanza_04.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_par_01 | Coleccionauta | «¡Ay, no! ¡Se me cayeron las gafas!» | exagerado, cómico | El equipo forma un par (máx. 1 de cada 3) | `voces/nucleo/equipo/coleccionauta/par_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_par_02 | Coleccionauta | «¡Otra pareja! ¿Cómo lo hacen?» | asombrado de verdad | Variante | `voces/nucleo/equipo/coleccionauta/par_02.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_par_03 | Coleccionauta | «¡Ay, no, no, no! ...Qué bien juegan, eso sí.» | quejón y luego sincero | Variante | `voces/nucleo/equipo/coleccionauta/par_03.wav` | casera (papá) |

### 4.2 Embobado con Maxi (no avanza en su turno)

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_coleccionauta_embobado_01 | Coleccionauta | «Ooooh... qué bien juega ese chiquitito. Me quedé mirando.» | derretido, como abuelo en un acto del jardín | Turno de Maxi (al azar) | `voces/nucleo/equipo/coleccionauta/embobado_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_embobado_02 | Coleccionauta | «¡Bravo, bravo! ...Uy, se me olvidó avanzar.» | aplaudiendo; el "uy" pillado | Fiesta del par de Maxi | `voces/nucleo/equipo/coleccionauta/embobado_02.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_embobado_03 | Coleccionauta | «Shhh... estoy mirando a Maxi. ¡Qué valiente!» | susurrando, "shhh" largo (gag para Maxi) | Variante | `voces/nucleo/equipo/coleccionauta/embobado_03.wav` | casera (papá) |

### 4.3 Derrota-gag: aspira, estornuda y vuelve

Orden: `aspira` → (sfx de la caja inflándose) → `estornuda` → (cartas volando a la mesa) → `cansado`
→ `coco_otra_vez` con el botón "¡otra vez!" → al tocarlo, `vuelve` mientras camina al inicio.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_coleccionauta_aspira | Coleccionauta | «¡Llegué! ¡Todas a mi colección! Sluuuurp...» | triunfal de mentira; el "sluuurp" largo y chistoso | El Coleccionauta llega a la mesa | `voces/arcoiris/emparejar/equipo/coleccionauta_aspira.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coleccionauta_estornuda | Coleccionauta | «¿Eh? Mi colección está rara... A... a... ¡ACHÚUU!» | extrañado, y el estornudo enorme (gag para Maxi) | La caja se infla y estornuda las cartas | `voces/arcoiris/emparejar/equipo/coleccionauta_estornuda.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coleccionauta_cansado | Coleccionauta | «Uf... cuesta guardar tantas cosas solo.» | sentado, con cartas en la cabeza; un poquito tierno, nada triste | Cae sentado | `voces/arcoiris/emparejar/equipo/coleccionauta_cansado.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coco_otra_vez | Coco | «¡Jajaja! ¡Las cartas volvieron volando! Y las parejas que hicimos se quedan. ¡Otra vez!» | riéndose con todos; tranquilizadora en "se quedan" | Aparece el botón "¡otra vez!" | `voces/arcoiris/emparejar/equipo/coco_otra_vez.wav` | TTS |
| nucleo_equipo_coleccionauta_vuelve | Coleccionauta | «Bueno, bueno... desde el principio. Fiu, fiu, fiu...» | resignado alegre, silbando | Vuelve caminando al inicio de la pista | `voces/nucleo/equipo/coleccionauta/vuelve.wav` | casera (papá) |

### 4.4 Aplaude la victoria del equipo

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_coleccionauta_aplaude_01 | Coleccionauta | «¡Ay, no llegué! ...Pero qué buen equipo. ¿Dónde venden uno?» | desilusión de broma y después admiración; la pregunta, en serio | El equipo gana (paso 1 de la fiesta, se le cae lo que tenga en la mano) | `voces/nucleo/equipo/coleccionauta/aplaude_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_aplaude_02 | Coleccionauta | «¡Me ganaron! ¡Bravo! ...¿Un equipo cabe en mi mochila? No, ¿cierto?» | aplaudiendo, después pensativo y chistoso | Variante | `voces/nucleo/equipo/coleccionauta/aplaude_02.wav` | casera (papá) |

---

## 5. Fiesta del equipo y choque de manos

Orden (ficha §5.6): `aplaude` (Coleccionauta) → `coco_victoria` → `al_frente` → gestos por turnos
(con el grito de cada niño si existe) → `choca` → `equipo_estelar` + confeti → `destellos` →
`estrellita` (si toca) → `record_equipo` (si toca).

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_coco_victoria | Coco | «¡Todas las parejas, y juntos! Mírenme... ¡ahora soy de todos los colores, como ustedes!» | explota de alegría; pausa antes del color (tic) | Se forma el último par | `voces/arcoiris/emparejar/equipo/coco_victoria.wav` | TTS |
| nucleo_equipo_al_frente | Cometa | «¡Todos al frente! ¡A celebrar!» | fiesta | Los hermanos salen juntos al frente | `voces/nucleo/equipo/al_frente.wav` | TTS |
| nucleo_equipo_fiesta_maxi | Maxi | «¡Síiii!» | su grito real, con los saltitos | Gesto de Maxi (0,8 s) | `voces/nucleo/equipo/fiesta_maxi.wav` | niños (opcional) |
| nucleo_equipo_fiesta_nicole | Nicole | Su grito de fiesta, una o dos palabras; ella lo elige (sugerencia: «¡Corazón!») | tierna, como su gesto | Gesto de Nicole (0,8 s) | `voces/nucleo/equipo/fiesta_nicole.wav` | niños (opcional) |
| nucleo_equipo_fiesta_sofia | Sofía | Su grito de fiesta, una o dos palabras; ella lo elige (sugerencia: «¡Paz!») | pícara, como su gesto | Gesto de Sofía (0,8 s) | `voces/nucleo/equipo/fiesta_sofia.wav` | niños (opcional) |
| nucleo_equipo_choca | Cometa | «¡Manos al centro... y choca!» | suspenso corto y explosión | Las manos se juntan al centro | `voces/nucleo/equipo/choca.wav` | TTS |
| nucleo_equipo_equipo_estelar | Cometa | «¡Equipo estelar!» | el grito más grande de Cometa | Choque de manos + confeti arcoíris | `voces/nucleo/equipo/equipo_estelar.wav` | TTS |
| nucleo_equipo_destellos | Cometa | «¡Destellos para todos!» | generoso, repartiendo | Conteo de destellos (igual para cada uno) | `voces/nucleo/equipo/destellos.wav` | TTS |
| nucleo_equipo_estrellita | Cometa | «¡Una estrellita para el equipo! ¡Mírenla volar!» | maravillado | Se enciende la estrellita de equipo de la zona y vuela al botón | `voces/nucleo/equipo/estrellita.wav` | TTS |
| arcoiris_emparejar_equipo_record | Coco | «¡Nuevo récord del equipo! Lo dejamos más lejos que nunca.» | orgullosa, con el trofeo-cupcake | Gana con el Coleccionauta antes de la banderita | `voces/arcoiris/emparejar/equipo/record.wav` | TTS |

Las tres líneas de los niños deben **durar lo mismo** (más o menos 1 s) y grabarse al mismo volumen
(equidad, ficha §6.1 y riesgo UX 6). Si uno no quiere grabar, ninguno suena: o los tres o ninguno.

---

## 6. Mejoras de Parejas en solitario: racha, "¡a la primera!", récord, vela y vistazo

Solo para Nicole (Brote) y Sofía (Estrella). Maxi tiene la racha **solo con sonido** (ficha §10.1). Ruta
base `voces/arcoiris/emparejar/reto/`. **Regla de mezcla**: desde la racha ×2, la línea de racha
**reemplaza** a `acierto_par_0X`; no suenan las dos.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_reto_racha_2 | Coco | «¡Dos seguidas!» | alegre | Racha ×2 | `voces/arcoiris/emparejar/reto/racha_2.wav` | TTS |
| arcoiris_emparejar_reto_racha_3 | Coco | «¡Tres seguidas! ¡Ojos de estrella!» | más alto, emocionada | Racha ×3 (ojos de estrella) | `voces/arcoiris/emparejar/reto/racha_3.wav` | TTS |
| arcoiris_emparejar_reto_racha_4 | Coco | «¡Cuatro! ¡No te para nadie!» | eufórica | Racha ×4 | `voces/arcoiris/emparejar/reto/racha_4.wav` | TTS |
| arcoiris_emparejar_reto_racha_5 | Coco | «¡Racha arcoíris! ¡Al máximo!» | la más grande, casi cantada | Racha ×5 (tope) | `voces/arcoiris/emparejar/reto/racha_5.wav` | TTS |
| arcoiris_emparejar_reto_racha_sigue | Coco | «¡Y sigue la racha!» | feliz, sin subir más | Otro par estando en el tope | `voces/arcoiris/emparejar/reto/racha_sigue.wav` | TTS |
| arcoiris_emparejar_reto_a_la_primera_01 | Coco | «¡A la primera! ¡Qué suerte!» | sorpresa, campanita | Par "a la primera" | `voces/arcoiris/emparejar/reto/a_la_primera_01.wav` | TTS |
| arcoiris_emparejar_reto_a_la_primera_02 | Coco | «¡Sin buscar y a la primera! ¡Trébol de la suerte!» | asombrada (el sello es un trébol) | Variante | `voces/arcoiris/emparejar/reto/a_la_primera_02.wav` | TTS |
| arcoiris_emparejar_reto_record_pasa | Coco | «¡Récord!» | una palabra, sin frenar el juego | La barra pasa la banderita-cupcake | `voces/arcoiris/emparejar/reto/record_pasa.wav` | TTS |
| arcoiris_emparejar_reto_record_nuevo_01 | Coco | «¡Nuevo récord! ¡Le ganaste a tu propio récord!» | orgullosa, con el trofeo-cupcake | Final con récord nuevo | `voces/arcoiris/emparejar/reto/record_nuevo_01.wav` | TTS |
| arcoiris_emparejar_reto_record_nuevo_02 | Coco | «¡Nuevo récord! Este trofeo-cupcake es tuyo.» | entregándolo, tierna | Variante | `voces/arcoiris/emparejar/reto/record_nuevo_02.wav` | TTS |
| arcoiris_emparejar_reto_vela_presenta | Coco | «¿Ves la velita? Si terminas antes de que se apague, ¡puntos extra!» | de regalo, nunca de amenaza | Primera vez que aparece la vela (presentación de a una). **Sujeta a riesgo UX 3** | `voces/arcoiris/emparejar/reto/vela_presenta.wav` | TTS |
| arcoiris_emparejar_reto_vela_encendida | Coco | «¡La velita sigue encendida! ¡Puntos de regalo!» | contenta, con tintineo | Se termina el tablero con la vela encendida | `voces/arcoiris/emparejar/reto/vela_encendida.wav` | TTS |
| arcoiris_emparejar_reto_vistazo_mira | Coco | «¡Mira!» | corta, con destello | Cada vistazo al repartir (en solitario) | `voces/arcoiris/emparejar/reto/vistazo_mira.wav` | TTS |
| arcoiris_emparejar_reto_vistazo_presenta | Coco | «Al repartir, te muestro unas cartas un ratito. ¡Míralas bien!» | cómplice, contando un secreto | Primer vistazo de cada hermano (en lugar de `vistazo_mira`) | `voces/arcoiris/emparejar/reto/vistazo_presenta.wav` | TTS |

Cuando la vela se apaga **no hay voz** (decisión 10): solo el "puf" de la llama y Coco que se encoge de
hombros. Cuando la racha se corta, tampoco (decisión 7).

---

## 7. Cartas especiales

Ruta base `voces/arcoiris/emparejar/especiales/`. La línea `presenta` suena **una sola vez por
hermano**, con la carta agrandada al centro (ficha §10.3); después, solo la palabra corta.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_especiales_comodin_presenta | Coco | «¡Comodín arcoíris! Va con cualquier carta.» | maravillada, mostrándolo | Primera vez que Nicole lo da vuelta | `voces/arcoiris/emparejar/especiales/comodin_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_comodin | Coco | «¡Comodín!» | fiesta corta | Las veces siguientes | `voces/arcoiris/emparejar/especiales/comodin.wav` | TTS |
| arcoiris_emparejar_especiales_dorada_presenta | Coco | «¡Carta dorada! Muchos puntos... ¡y la próxima pareja vale doble!» | brillante, de tesoro | Primera vez que Sofía forma la dorada | `voces/arcoiris/emparejar/especiales/dorada_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_dorada | Coco | «¡Dorada!» | campana grave en la voz | Las veces siguientes | `voces/arcoiris/emparejar/especiales/dorada.wav` | TTS |
| arcoiris_emparejar_especiales_lupa_presenta | Coco | «¡Lupa! Te muestro todas las cartas... ¡un segundito!» | "lupa" con el ojo agrandado, chistosa | Primera vez que se forma la pareja lupa | `voces/arcoiris/emparejar/especiales/lupa_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_lupa | Coco | «¡Tadá!» | arpa, mágica | Las veces siguientes | `voces/arcoiris/emparejar/especiales/lupa.wav` | TTS |
| arcoiris_emparejar_especiales_coleccionauta_presenta | Coco | «¡La carta del Coleccionauta! Va a cambiar dos cartas de lugar. ¡Síguelas con la mirada!» | divertida, avisando como juego | Primera vez que Sofía la da vuelta (antes de que él se asome) | `voces/arcoiris/emparejar/especiales/coleccionauta_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_coleccionauta_cambia_01 | Coleccionauta | «¡Qué lindas! Me llevo... no, no. Mejor las cambio de lugar.» | tentado, se arrepiente solo | Se asoma y cambia dos cartas (línea de la ficha) | `voces/arcoiris/emparejar/especiales/coleccionauta_cambia_01.wav` | casera (papá) |
| arcoiris_emparejar_especiales_coleccionauta_cambia_02 | Coleccionauta | «¡Ooh, cartas! Las guardo en mi... no, mejor las cambio. ¡Listo!» | se corta a media idea | Variante | `voces/arcoiris/emparejar/especiales/coleccionauta_cambia_02.wav` | casera (papá) |
| arcoiris_emparejar_especiales_coleccionauta_chao | Coleccionauta | «¡Chao, chao! ¡Uy, mi mochila!» | despedida alegre y tropezón | Se va tropezando | `voces/arcoiris/emparejar/especiales/coleccionauta_chao.wav` | casera (papá) |
| arcoiris_emparejar_especiales_coco_risa | Coco | «¡Jiji! ¿Viste adónde se fueron?» | tapándose la boca, cómplice | Después de `coleccionauta_chao` | `voces/arcoiris/emparejar/especiales/coco_risa.wav` | TTS |

`coco_risa` convierte el cambio en un juego de atención ("¿viste?") y no en una trampa contra Sofía
(riesgo UX 6).

---

## 8. Camino de colores (Sofía)

Ruta base `voces/arcoiris/emparejar/camino/`. La intro va **sincronizada con la demostración de 3
cartas** (riesgo UX 7): cada línea `demo` suena cuando su carta se da vuelta.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_camino_intro_01 | Coco | «¡Sofía, un juego nuevo: el Camino de colores!» | de estreno, emocionada | Al entrar | `voces/arcoiris/emparejar/camino/intro_01.wav` | TTS |
| arcoiris_emparejar_camino_demo_01 | Coco | «Mira esta estrella roja.» | lenta, mostrando | Demo: se da vuelta la estrella roja | `voces/arcoiris/emparejar/camino/demo_01.wav` | TTS |
| arcoiris_emparejar_camino_demo_02 | Coco | «Este corazón también es rojo: ¡van juntos por el color!» | descubriendo; acento en "color" | Demo: corazón rojo + glaseado rojo | `voces/arcoiris/emparejar/camino/demo_02.wav` | TTS |
| arcoiris_emparejar_camino_demo_03 | Coco | «Y este corazón azul... ¡va con el otro corazón, por la figura!» | sorpresa; acento en "figura" | Demo: corazón azul + glaseado con estampitas | `voces/arcoiris/emparejar/camino/demo_03.wav` | TTS |
| arcoiris_emparejar_camino_intro_02 | Coco | «Cada carta se parece a la anterior: en el color o en la figura. ¡Arma el camino más largo!» | clara, desafiante con cariño | Fin de la demo (se tapan las tres) | `voces/arcoiris/emparejar/camino/intro_02.wav` | TTS |
| arcoiris_emparejar_camino_pista | Cometa | «Mira la última carta. ¿Cuál tiene su color, o su figura?» | en secreto, ayudando | Tocar a Cometa | `voces/arcoiris/emparejar/camino/pista.wav` | TTS |
| arcoiris_emparejar_camino_no_comparte_01 | Coco | «¡Uy, esa no se parece! El camino se tapó... pero las cartas siguen ahí.» | liviana; tranquilizadora al final | Carta que no comparte nada | `voces/arcoiris/emparejar/camino/no_comparte_01.wav` | TTS |
| arcoiris_emparejar_camino_no_comparte_02 | Coco | «¡Esa no combina! Acuérdate de dónde quedaron.» | cómplice | Variante | `voces/arcoiris/emparejar/camino/no_comparte_02.wav` | TTS |
| arcoiris_emparejar_camino_sin_salida | Coco | «¡No queda por dónde seguir: llegaste al final!» | fiesta, es una victoria | Ninguna tapada continúa el camino (línea de la ficha) | `voces/arcoiris/emparejar/camino/sin_salida.wav` | TTS |
| arcoiris_emparejar_camino_meta | Coco | «¡Doce cartas en camino! ¡Lo lograste, Sofía!» | orgullosa | Se llega a `largo_meta` | `voces/arcoiris/emparejar/camino/meta.wav` | TTS |
| arcoiris_emparejar_camino_record | Coco | «¡Tu camino más largo!» | admiración | Récord de largo superado | `voces/arcoiris/emparejar/camino/record.wav` | TTS |
| arcoiris_emparejar_camino_derrota_gag | Coco | «¡Las cartas se fueron en conga! Y yo quedé... mareadita. ¡Otra vez!» | mareada, riéndose de sí misma | Derrota: las cartas bailan conga | `voces/arcoiris/emparejar/camino/derrota_gag.wav` | TTS |
| arcoiris_emparejar_camino_regalo | Coco | «Te armo los primeros tres pasos. ¡Sigue tú, Sofía!» | generosa, sin lástima | Tras 2 derrotas (`regalo_tras_derrotas`) | `voces/arcoiris/emparejar/camino/regalo.wav` | TTS |

Si `largo_meta` cambia de 12, hay que regrabar `meta` (dice "doce").

---

## 9. Colección: "La caja de cartas de Coco"

Ruta base `voces/arcoiris/coleccion/`. Los nombres de cada carta al tocarla son del catálogo
(`datos/colecciones/cartas_arcoiris.json`) y quedan fuera de este guion: banderas y colores ya tienen
voz; dinos, vehículos y animales nuevos los lista `disenador-niveles` y se escriben después.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_coleccion_nueva_01 | Coco | «¡Nueva!» | chispeante, encima del "clink" | Par que entra por primera vez a la colección (sin pausar) | `voces/arcoiris/coleccion/nueva_01.wav` | TTS |
| arcoiris_coleccion_nueva_02 | Coco | «¡Otra nueva!» | ídem | Segunda nueva o más en la misma partida | `voces/arcoiris/coleccion/nueva_02.wav` | TTS |
| arcoiris_coleccion_final | Coco | «¡Cartas nuevas para tu caja!» | regalando | Fin de la celebración, antes de que vuelen a la cajita | `voces/arcoiris/coleccion/final.wav` | TTS |
| arcoiris_coleccion_final_equipo | Coco | «¡Cartas nuevas para cada uno!» | repartiendo, igual para todos | Ídem, en modo equipo | `voces/arcoiris/coleccion/final_equipo.wav` | TTS |
| arcoiris_coleccion_cuenta_1 | Coco | «¡Una!» | contando, alegre | 1.ª carta que entra a la cajita | `voces/arcoiris/coleccion/cuenta_1.wav` | TTS |
| arcoiris_coleccion_cuenta_2 | Coco | «¡Dos!» | ídem | 2.ª | `voces/arcoiris/coleccion/cuenta_2.wav` | TTS |
| arcoiris_coleccion_cuenta_3 | Coco | «¡Tres!» | ídem | 3.ª | `voces/arcoiris/coleccion/cuenta_3.wav` | TTS |
| arcoiris_coleccion_cuenta_4 | Coco | «¡Cuatro!» | ídem | 4.ª | `voces/arcoiris/coleccion/cuenta_4.wav` | TTS |
| arcoiris_coleccion_cuenta_5 | Coco | «¡Cinco!» | ídem | 5.ª | `voces/arcoiris/coleccion/cuenta_5.wav` | TTS |
| arcoiris_coleccion_cuenta_6 | Coco | «¡Seis!» | ídem, la más alta | 6.ª (después solo "clink") | `voces/arcoiris/coleccion/cuenta_6.wav` | TTS |
| arcoiris_coleccion_caja_entrar | Coco | «¡Mi caja de cartas! Toca una y te digo su nombre.» | orgullosa, invitando | Abrir la pantalla de colección | `voces/arcoiris/coleccion/caja_entrar.wav` | TTS |
| arcoiris_coleccion_silueta | Coco | «¡Esa todavía está escondida! Aparece jugando a las parejas.» | misteriosa y alegre, nunca "no la tienes" | Tocar una silueta con "?" | `voces/arcoiris/coleccion/silueta.wav` | TTS |
| arcoiris_coleccion_mostrar | Coco | «¡Estas cartas son para mirarlas juntos! ¿A quién se las muestras?» | entusiasta, de compartir | 2.ª visita a la caja en adelante, tras `caja_entrar` (y gancho del futuro botón "mostrarle a un hermano") | `voces/arcoiris/coleccion/mostrar.wav` | TTS |

---

## 10. Mapeo a las claves de la ficha (§9 de `modo-equipo.md`)

| clave `lineas_voz` | ids |
|---|---|
| `intro_equipo` | `arcoiris_emparejar_equipo_intro` (+ `intro_ayudan`, `coleccionauta_entra`, `coco_juntemos`) |
| `le_toca.maxi/nicole/sofia` | `nucleo_equipo_le_toca_<hermano>_01..03` |
| `rival_avanza` | `nucleo_equipo_coleccionauta_avanza_01..04` |
| `rival_embobado` | `nucleo_equipo_coleccionauta_embobado_01..03` |
| `victoria_equipo` | `arcoiris_emparejar_equipo_coco_victoria` (+ la secuencia del §5) |
| `derrota_gag_equipo` | secuencia del §4.3 |
| `record_equipo` | `arcoiris_emparejar_equipo_record` |

Faltan claves para: `acierto`, `fallo`, `nicole_otra`, `brote_ayuda`, los de Maxi guiado, las
reacciones `par` y `aplaude` del rival, y `vistazo`. Lo decide `dev-godot` al implementar.

---

## 11. Resumen de conteo

| bloque | Coco | Cometa | Coleccionauta (papá) | niños (opcional) | total |
|---|---|---|---|---|---|
| §1 Selección y mapa | 2 | 7 | — | 3 | 12 |
| §2 Le toca | — | 13 | — | — | 13 |
| §3 Parejas en equipo | 17 | — | — | — | 17 |
| §4 Rival | 2 | — | 17 | — | 19 |
| §5 Fiesta | 2 | 5 | — | 3 | 10 |
| §6 Racha, récord, vela, vistazo | 14 | — | — | — | 14 |
| §7 Especiales | 8 | — | 3 | — | 11 |
| §8 Camino de colores | 12 | 1 | — | — | 13 |
| §9 Colección | 13 | — | — | — | 13 |
| **Total** | **70** | **26** | **20** | **6** | **122** |

- **TTS (Coco y Cometa)**: 96 líneas, todas cortas. Antes de generar: `--estimar` y OK del PO sobre el
  costo.
- **Grabación casera**: 20 del Coleccionauta (papá) y 6 opcionales de los niños.
