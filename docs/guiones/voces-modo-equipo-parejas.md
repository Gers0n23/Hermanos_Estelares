# Guion de voz — Modo "¡Juntos!" y mejoras de Parejas de Coco (HE-58)

> Encargo de HE-58 (parte de guion). Fuentes: `docs/fichas/modo-equipo.md` (en especial §3, §4, §5 y
> §8) y `docs/fichas/motor-emparejar.md` §10, **ya con las correcciones de la validación UX de HE-58**
> (B1-B3, M1-M10, m1-m10). Este guion es **solo texto**: no genera audio ni toca los `.tsv`. Cuando el
> PO apruebe el costo del TTS, `dev-godot` copia las filas a su `lineas_tts.tsv` (con la directiva
> `# personaje:` correcta) y las líneas caseras se graban en familia.
>
> **Revisión v2 (06-Oct-2026)**: ajustado a las fichas corregidas. Cambios: `te_toca` habla de "tu
> carita" (B1) y tiene variante de arrastre; el rival avanza durante el pase (B3); derrota en plural con
> el logro común "¡igual juntamos N parejas!" (B3.3); `vela_dormida` (M7.3); presentación de la lupa con
> el gesto nuevo; y todas las claves que las fichas marcaban `PENDIENTE`. Las voces de la **Batalla final
> de Arcoíris** (`modo-equipo.md` §14, tarjeta HE-67) **no están aquí**: esperan la auditoría UX y las
> decisiones del PO.

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
    voz. Si no se graban, la animación va sin voz y no falta nada. **O se graban los tres o ninguno**, con
    el mismo largo y volumen (equidad).
- **Rutas** relativas a `assets/audio/`, en `.wav` como los `.tsv` actuales. Siguiendo la regla R8 de la
  ficha (capa genérica), lo que sirve para **cualquier** juego en equipo va a `voces/nucleo/equipo/`, y
  lo propio de Parejas o del Planeta Arcoíris va a `voces/arcoiris/...`.
- **Id estable**: la convención del proyecto. `nucleo_` + ruta sin `voces/nucleo/` ni extensión;
  `arcoiris_` + ruta sin `voces/arcoiris/` ni extensión. Ej.: `voces/nucleo/equipo/le_toca_maxi_01.wav`
  → `nucleo_equipo_le_toca_maxi_01`.
- **Estado**: las 173 líneas son **nuevas** y están **pendientes de audio**.
- **Revisión v3 (07-Oct-2026, desde HE-67)**: cierres de la intro de trucos con y sin tope, `intro_tope`
  y `intro_trucos_sofia` reescrita (ficha `modo-equipo.md` §8, pendientes 1 y 2; UX HE-66 N8). Ver §3.1.

## Decisiones de tono de este guion

1. **Nadie falla con nombre.** Las líneas de "no era" en equipo nunca dicen el nombre de quien jugó y
   convierten el fallo en un dato para todos: "ahora **todos** sabemos dónde están". Es la memoria
   compartida hecha voz: la cooperación se muestra, no se declama.
2. **El acierto en equipo tampoco lleva nombre** (salvo Maxi en su turno guiado). Así nadie cuenta
   "a mí me dijo bravo tres veces". Con Maxi no hay riesgo de celos (la ficha de Sofía lo dice) y
   a los 2 años escuchar su nombre es el premio. El retroceso del rival por racha de 3 también se
   celebra **sin nombre**: es "del equipo".
3. **"¡Le toca a…!" con equidad exacta**: 3 variantes por hermano, del mismo largo y la misma
   estructura. La 02 imita su **gesto canon** (Maxi "¡síii!", Nicole el corazoncito, Sofía el guiño) y
   la 03 juega con algo suyo (el dino; los ojos de jirafa; un "cerebro estelar", más de chiste
   inteligente para Sofía). Ninguna compara ni dice "la más…". Lo mismo para `te_toca`,
   `sube_ventanita` y las confirmaciones del puf.
4. **El Coleccionauta, rival de risa.** Cada línea suya parte grande y termina chica (su tic): salta
   y no sabe contar galletas, se le resbalan las gafas-lupa, se olvida de avanzar por mirar a Maxi, se
   resbala para atrás. En la derrota su **mochila-torre estornuda** las cartas de vuelta y él queda
   sentado diciendo la línea de la ficha ("cuesta guardar tantas cosas solo"). En la victoria pregunta
   **dónde venden un equipo** o si cabe en su mochila: siembra la lección final (los amigos no se
   coleccionan) sin decirla. **Nunca menciona a papá** en este modo.
5. **Cuidado con Maxi y el Coleccionauta.** Él colecciona "cosas increíbles" y se llevó a papá por
   increíble. Por eso, cuando se queda embobado con Maxi, **no dice "increíble" ni nada de llevárselo**:
   lo admira como un vecino que aplaude. Pedido a `disenador-personajes`: que en ese gag no estire los
   brazos hacia Maxi.
6. **La derrota es de todos y termina en logro (B3).** El salto que hace llegar al rival ocurre en el
   pase, con el siguiente ya al centro. Todas las líneas de derrota hablan en plural, nadie es nombrado,
   y Cometa cierra contando lo que **sí** juntaron: "¡igual juntamos siete parejas, y se quedan!".
7. **La racha sube sin castigo al cortarse.** Hay voz para cada nivel de racha y **ninguna** para el
   corte: el "fiuu" de los nuditos basta. En equipo la racha no tiene voz (es `solo_sonido`, M1).
8. **El récord es contra uno mismo**: "le ganaste a **tu propio** récord". Ninguna línea de récord
   lleva nombre, para que Nicole y Sofía escuchen exactamente lo mismo.
9. **Las estrellitas de Nicole hablan del logro, nunca de lo que faltó** (§10.1.1 del motor): nada de
   "solo una" ni "la próxima vez más". La primera estrellita es "la de terminar" y suena igual de grande.
10. **Sin apuro**: ninguna línea dice "rápido" ni "apúrate". La vela del tiempo par se presenta como
    "puntos extra" y, **cuando se apaga, Coco dice algo positivo** (`vela_dormida`, M7.3): la velita "se
    quedó dormida" y cada pareja sigue sumando. Reemplaza a la decisión anterior de dejarla sin voz.
11. **La caja de cartas de Coco y el arco del Coleccionauta**: Coco guarda cartas en una caja, como él.
    La diferencia se muestra con una línea: sus cartas son "para mirarlas juntos". No hay sermón.

---

## 1. Selección: el botón "¡Juntos!" y armar el equipo

Suena en `seleccion_personaje.gd` (ficha de modo equipo §3.1 y §3.2). El botón aparece **después de
ganar la Batalla final de Arcoíris** (§3.1, decisión del PO). Ruta base `voces/nucleo/`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_presenta | Cometa | «¡Ahora pueden jugar juntos! Toquen la nave.» | ilusionado, de regalo nuevo | Presentación única (M5.2): la nave entra volando y se estaciona | `voces/nucleo/equipo/presenta.wav` | TTS |
| nucleo_seleccion_invitacion_equipo | Cometa | «¿Y si juegan juntos? ¡Toquen la nave!» | invitando, con la nave dando un saltito | Recordatorio de 12 s, alternado con `seleccion_invitacion_01` (M5.3). Se escribió como frase completa porque suena sola, no pegada a la otra | `voces/nucleo/seleccion_invitacion_equipo.wav` | TTS |
| nucleo_equipo_juntos | Cometa | «¡Vamos juntos!» | eufórico, con salto en la voz | Tocar el botón "¡Juntos!" | `voces/nucleo/equipo/juntos.wav` | TTS |
| nucleo_equipo_armar | Cometa | «¿Quiénes juegan juntos hoy? Si alguien quiere mirar, tócalo... ¡y se sienta en el puf! Después, ¡a despegar!» | invitando, alegre; pausa antes del puf | Al entrar a armar equipo; tocar a Cometa la repite | `voces/nucleo/equipo/armar.wav` | TTS |
| nucleo_equipo_al_puf_maxi | Cometa | «¡Maxi va a mirar desde el puf!» | alegre, como quien acomoda a alguien cómodo | Maxi sale del equipo (m2) | `voces/nucleo/equipo/al_puf_maxi.wav` | TTS |
| nucleo_equipo_al_puf_nicole | Cometa | «¡Nicole va a mirar desde el puf!» | ídem | Nicole sale (m2) | `voces/nucleo/equipo/al_puf_nicole.wav` | TTS |
| nucleo_equipo_al_puf_sofia | Cometa | «¡Sofía va a mirar desde el puf!» | ídem | Sofía sale (m2) | `voces/nucleo/equipo/al_puf_sofia.wav` | TTS |
| nucleo_equipo_sube_nave_maxi | Cometa | «¡Maxi se sube a la nave!» | fiesta | Maxi vuelve al equipo (m2) | `voces/nucleo/equipo/sube_nave_maxi.wav` | TTS |
| nucleo_equipo_sube_nave_nicole | Cometa | «¡Nicole se sube a la nave!» | fiesta | Nicole vuelve (m2) | `voces/nucleo/equipo/sube_nave_nicole.wav` | TTS |
| nucleo_equipo_sube_nave_sofia | Cometa | «¡Sofía se sube a la nave!» | fiesta | Sofía vuelve (m2) | `voces/nucleo/equipo/sube_nave_sofia.wav` | TTS |
| nucleo_equipo_yo_tambien_maxi | Maxi | «¡Yo también!» | como le salga; gritado está perfecto | Justo después de `sube_nave_maxi` | `voces/nucleo/equipo/yo_tambien_maxi.wav` | niños (opcional) |
| nucleo_equipo_yo_tambien_nicole | Nicole | «¡Yo también!» | contenta | Justo después de `sube_nave_nicole` | `voces/nucleo/equipo/yo_tambien_nicole.wav` | niños (opcional) |
| nucleo_equipo_yo_tambien_sofia | Sofía | «¡Yo también!» | contenta | Justo después de `sube_nave_sofia` | `voces/nucleo/equipo/yo_tambien_sofia.wav` | niños (opcional) |
| nucleo_equipo_minimo_dos | Cometa | «¡Para jugar en equipo se necesitan al menos dos!» | explicando con cariño, sin reproche | Intentar sacar a uno cuando quedan dos | `voces/nucleo/equipo/minimo_dos.wav` | TTS |
| nucleo_equipo_despegar | Cometa | «¡Despegamos! Tres, dos, uno... ¡fiuuu!» | cuenta regresiva de juego; el "fiuuu" largo, para Maxi | Tocar "¡Despegar!" | `voces/nucleo/equipo/despegar.wav` | TTS |

Las líneas genéricas de la v1 (`al_puf_01/02` y `vuelve`) se **reemplazan** por las seis con nombre que
pide m2. Nunca tuvieron audio.

Mapa del Planeta Arcoíris en modo equipo (ficha §3.3). Ruta base `voces/arcoiris/mapa/`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_mapa_equipo_llegada | Coco | «¡Llegó el equipo! Vengan, las parejas se juegan todos juntos.» | acogedora, abriendo los brazos | Entrar al mapa en modo equipo | `voces/arcoiris/mapa/equipo_llegada.wav` | TTS |
| arcoiris_mapa_equipo_estacion_pronto | Coco | «¡Este juego todavía lo estoy preparando para jugar en equipo!» | ilusionada, nunca "no se puede" | Tocar una estación sin `nivel_equipo` (clave `estacion_sin_equipo` de la ficha) | `voces/arcoiris/mapa/equipo_estacion_pronto.wav` | TTS |

---

## 2. Pase de turno: "¡Le toca a…!", la puerta y los recordatorios

Suena en el pase de turno (ficha §4.3). Voz de Cometa porque es la capa genérica de turnos. Ruta base
`voces/nucleo/equipo/`.

**Puerta de turno (B1)**: se abre **tocando el retrato grande** ("tu carita"). Después de un turno de
Maxi, en cambio, hay que **arrastrar el retrato hasta su ventanita**. Por eso hay dos familias:
`te_toca_*` (toque) y `sube_ventanita_*` / `te_toca_*_ventanita` (arrastre). Maxi nunca juega justo
después de Maxi, así que no hay variantes de arrastre para él.

### 2.1 "¡Le toca a…!" (paso 2, el retrato vuela al centro)

La UI elige una variante al azar sin repetir la anterior. Un toque fuera del retrato la repite (con
enfriamiento de 2 s).

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

### 2.2 Puerta de toque: recordatorio (m5)

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_te_toca_maxi | Cometa | «¡Maxi, te toca! Toca tu carita.» | llamando con cariño, sin apuro | 10 s sin abrir la puerta (máximo 2 veces) | `voces/nucleo/equipo/te_toca_maxi.wav` | TTS |
| nucleo_equipo_te_toca_nicole | Cometa | «¡Nicole, te toca! Toca tu carita.» | ídem | ídem | `voces/nucleo/equipo/te_toca_nicole.wav` | TTS |
| nucleo_equipo_te_toca_sofia | Cometa | «¡Sofía, te toca! Toca tu carita.» | ídem | ídem | `voces/nucleo/equipo/te_toca_sofia.wav` | TTS |
| nucleo_equipo_maxi_ayuda | Cometa | «¿Maxi se fue a jugar? ¡Alguien puede tocar su carita!» | divertido, sin reto; invita a ayudar | Turno de Maxi: después del segundo `te_toca_maxi` sin toque | `voces/nucleo/equipo/maxi_ayuda.wav` | TTS |

### 2.3 Puerta de arrastre, después de un turno de Maxi (B1.2)

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_sube_ventanita_nicole | Cometa | «¡Nicole, sube a tu ventanita!» | juguetón, señalando el camino de estrellitas | Paso 3 tras turno de Maxi, si sigue Nicole (reemplaza a `le_toca`) | `voces/nucleo/equipo/sube_ventanita_nicole.wav` | TTS |
| nucleo_equipo_sube_ventanita_sofia | Cometa | «¡Sofía, sube a tu ventanita!» | ídem | ídem, si sigue Sofía | `voces/nucleo/equipo/sube_ventanita_sofia.wav` | TTS |
| nucleo_equipo_te_toca_nicole_ventanita | Cometa | «¡Nicole, te toca! Lleva tu carita a la ventanita.» | paciente, mostrando | Recordatorio de 10 s en la puerta de arrastre (máximo 2 veces) | `voces/nucleo/equipo/te_toca_nicole_ventanita.wav` | TTS |
| nucleo_equipo_te_toca_sofia_ventanita | Cometa | «¡Sofía, te toca! Lleva tu carita a la ventanita.» | ídem | ídem | `voces/nucleo/equipo/te_toca_sofia_ventanita.wav` | TTS |

Si el dedo se suelta lejos y el retrato vuelve al centro, **no hay voz** (sin sonido de error, B1).

---

## 3. Parejas de Coco en equipo: reglas, turnos y ánimo

Ruta base `voces/arcoiris/emparejar/equipo/`. Voz de Coco, la anfitriona.

### 3.1 Inicio, trucos y vistazo

`intro_trucos` (M2) suena **solo en la primera partida de cada combinación de hermanos**: Coco dice la
apertura y después **solo los fragmentos de quienes juegan**, en el orden de los turnos. Las partidas
siguientes usan `intro` + `intro_ayudan`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_intro_trucos | Coco | «¡Cada uno juega con su propio truco!» | cómplice, de secreto | Primera partida de esa combinación (apertura) | `voces/arcoiris/emparejar/equipo/intro_trucos.wav` | TTS |
| arcoiris_emparejar_equipo_intro_trucos_maxi | Coco | «Maxi tiene cartas que brillan.» | mágica, lenta | Fragmento si juega Maxi (clave `intro_equipo_trucos.maxi`) | `voces/arcoiris/emparejar/equipo/intro_trucos_maxi.wav` | TTS |
| arcoiris_emparejar_equipo_intro_trucos_nicole | Coco | «Nicole tiene un besito mío: ¡una oportunidad extra!» | tierna; sopla un besito | Fragmento si juega Nicole | `voces/arcoiris/emparejar/equipo/intro_trucos_nicole.wav` | TTS |
| arcoiris_emparejar_equipo_intro_trucos_sofia | Coco | «Sofía juega como en la mesa de verdad: ¡como los grandes!» | admirada, de rango y no de desventaja | **[v3]** Fragmento si juega Sofía. **Texto reescrito** (ficha §8, pendiente 2): el retroceso es del equipo, no su truco. Nunca tuvo audio | `voces/arcoiris/emparejar/equipo/intro_trucos_sofia.wav` | TTS |
| arcoiris_emparejar_equipo_intro_trucos_equipo | Coco | «¡Y quien prenda todas sus lucecitas, hace resbalar al Coleccionauta!» | entusiasta, de hazaña de todos | **[v3]** Cierre de los trucos **con tope** ("los tres" y `maxi+nicole`; clave `intro_equipo_trucos.equipo`, ficha §8, pendiente 1). Sin contar pares: sirve igual a Nicole y a Sofía | `voces/arcoiris/emparejar/equipo/intro_trucos_equipo.wav` | TTS |
| arcoiris_emparejar_equipo_intro_trucos_equipo_racha | Coco | «¡Y quien haga tres parejas seguidas, hace retroceder al Coleccionauta!» | ídem | **[v3]** Cierre de los trucos **sin tope** (`maxi+sofia`, `nicole+sofia`; clave `intro_equipo_trucos.equipo_racha`) | `voces/arcoiris/emparejar/equipo/intro_trucos_equipo_racha.wav` | TTS |
| arcoiris_emparejar_equipo_intro | Coco | «¡Jugamos todos juntos! Si encuentras una pareja, sigues jugando. Si no, le toca al siguiente.» | clara, alegre; pausa entre las dos reglas | Inicio de la partida (después de los trucos, si los hubo). **[v3] Solo en composiciones sin tope** (UX HE-66 N8) | `voces/arcoiris/emparejar/equipo/intro.wav` | TTS |
| arcoiris_emparejar_equipo_intro_tope | Coco | «¡Jugamos todos juntos! Si hay pareja, sigues... ¡hasta prender tus lucecitas!» | clara, alegre; "lucecitas" mirando la guirnalda | **[v3, N8]** Lo mismo que `intro`, en las composiciones **con tope** (clave propuesta `intro_equipo_tope`) | `voces/arcoiris/emparejar/equipo/intro_tope.wav` | TTS |
| arcoiris_emparejar_equipo_intro_ayudan | Coco | «¡Y los que miran, ayudan a recordar!» | cómplice, mirando a los del puf | Justo después de `intro` | `voces/arcoiris/emparejar/equipo/intro_ayudan.wav` | TTS |
| arcoiris_emparejar_equipo_vistazo | Coco | «¡Mírenlas bien, equipo!» | entusiasta, en plural | Vistazo al repartir en equipo | `voces/arcoiris/emparejar/equipo/vistazo.wav` | TTS |

### 3.2 Turno guiado de Maxi

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_maxi_brillan_01 | Coco | «¡Maxi, toca las que brillan!» | lenta, cálida | Empieza el turno de Maxi (las dos cartas con halo) | `voces/arcoiris/emparejar/equipo/maxi_brillan_01.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_brillan_02 | Coco | «¡Mira, Maxi! ¡Brillan para ti!» | maravillada | Variante; también tras tocar una carta sin halo | `voces/arcoiris/emparejar/equipo/maxi_brillan_02.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_aqui | Coco | «¡Aquí están, Maxi! ¡Tócalas!» | animando, señalando | Las cartas del halo quedan a la vista (2 toques fuera o 6 s) | `voces/arcoiris/emparejar/equipo/maxi_aqui.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_par | Coco | «¡Bravo, Maxi! ¡Una pareja para el equipo!» | fiesta grande | Maxi forma su pareja (reemplaza a `acierto_equipo`) | `voces/arcoiris/emparejar/equipo/maxi_par.wav` | TTS |
| arcoiris_emparejar_equipo_maxi_lupa | Coco | «¡Maxi encontró la lupa para todo el equipo!» | asombrada, orgullosa | Maxi forma la pareja lupa (reemplaza a `maxi_par`) | `voces/arcoiris/emparejar/equipo/maxi_lupa.wav` | TTS |
| arcoiris_emparejar_equipo_porras_fin_maxi | Coco | «¡Y ahora, Maxi, a echar porras!» | alegre, de barra | Ritual de fin de turno de Maxi (paso 0 del pase, M3.3), mientras su retrato vuelve a la ventanita | `voces/arcoiris/emparejar/equipo/porras_fin_maxi.wav` | TTS |

Cuando Maxi toca una carta normal sin halo, Coco dice el nombre de la figura con las voces que ya
existen. Si toca un comodín o una lupa sin halo, no se da vuelta y **no hay voz** (M10).

### 3.3 Ánimo del equipo (Nicole y Sofía)

Sin nombre a propósito (decisiones 1 y 2). Al azar, sin repetir la anterior.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_acierto_01 | Coco | «¡Una pareja para el equipo!» | fiesta | Par en turno de Nicole o Sofía | `voces/arcoiris/emparejar/equipo/acierto_01.wav` | TTS |
| arcoiris_emparejar_equipo_acierto_02 | Coco | «¡Eso! ¡Y sigues jugando!» | alegre; recuerda la regla de mesa | Variante | `voces/arcoiris/emparejar/equipo/acierto_02.wav` | TTS |
| arcoiris_emparejar_equipo_acierto_03 | Coco | «¡Pareja! ¡A la cinta arcoíris!» | cantarina | Variante | `voces/arcoiris/emparejar/equipo/acierto_03.wav` | TTS |
| arcoiris_emparejar_equipo_acierto_04 | Coco | «¡Bien! ¡Otra vuelta para ti!» | contenta | Variante | `voces/arcoiris/emparejar/equipo/acierto_04.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_01 | Coco | «¡Uy! Pero ahora todos sabemos dónde están.» | liviana, positiva al final | "No es este" que termina el turno | `voces/arcoiris/emparejar/equipo/fallo_01.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_02 | Coco | «¡Casi! Equipo, ¡acuérdense de esas dos!» | cómplice, hablando a todos | Variante | `voces/arcoiris/emparejar/equipo/fallo_02.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_03 | Coco | «¡No era! Pero esas cartas ya no se nos esconden.» | pícara | Variante | `voces/arcoiris/emparejar/equipo/fallo_03.wav` | TTS |
| arcoiris_emparejar_equipo_fallo_04 | Coco | «¡Ups! Ojos bien abiertos, equipo: ¡ahí quedaron!» | juguetona | Variante | `voces/arcoiris/emparejar/equipo/fallo_04.wav` | TTS |
| arcoiris_emparejar_equipo_nicole_otra | Coco | «¡Uy, otra! ¡Sigue, Nicole!» | dulce, con guiño y besito soplado | Primer "no es este" de Nicole en su turno (segunda oportunidad, B2: solo voz) | `voces/arcoiris/emparejar/equipo/nicole_otra.wav` | TTS |
| arcoiris_emparejar_equipo_brote_ayuda | Coco | «Esa carta que brilla... ¿se acuerdan de su pareja?» | misteriosa, pregunta al equipo | Turno de Nicole tras 2 turnos suyos sin par | `voces/arcoiris/emparejar/equipo/brote_ayuda.wav` | TTS |

`brote_ayuda` va en plural a propósito: invita a los del puf a soplarle a Nicole.

### 3.4 Ánimo de los hermanos que miran (B2, opcional)

Reacción automática de quienes miran ante un "no es este" (ficha §4.1): **solo ánimo**, nunca "¡uuuh!".
Grabadas por los niños; si no existen, solo animación y SFX. La clave `animo_hermanos` de la ficha es un
solo valor: propongo que sea `{ "maxi": [...], "nicole": [...], "sofia": [...] }` y que suene **un solo
hermano por vez** (el primero de la barra que no juega), para no tapar a Coco.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_animo_maxi_01 | Maxi | «¡Tú puedes!» | como le salga | "No es este" de otro hermano | `voces/nucleo/equipo/animo_maxi_01.wav` | niños (opcional) |
| nucleo_equipo_animo_maxi_02 | Maxi | «¡Casi!» | ídem | Variante | `voces/nucleo/equipo/animo_maxi_02.wav` | niños (opcional) |
| nucleo_equipo_animo_nicole_01 | Nicole | «¡Tú puedes!» | cariñosa | ídem | `voces/nucleo/equipo/animo_nicole_01.wav` | niños (opcional) |
| nucleo_equipo_animo_nicole_02 | Nicole | «¡Casi!» | cariñosa | Variante | `voces/nucleo/equipo/animo_nicole_02.wav` | niños (opcional) |
| nucleo_equipo_animo_sofia_01 | Sofía | «¡Tú puedes!» | cariñosa | ídem | `voces/nucleo/equipo/animo_sofia_01.wav` | niños (opcional) |
| nucleo_equipo_animo_sofia_02 | Sofía | «¡Casi!» | cariñosa | Variante | `voces/nucleo/equipo/animo_sofia_02.wav` | niños (opcional) |

---

## 4. El Coleccionauta, rival común

Todas sus líneas son de **grabación casera (papá)**. Es el de su canon: **gafas-lupa y mochila-torre**.
Lo genérico de la pista del rival va en `voces/nucleo/equipo/coleccionauta/`; lo que habla de cartas,
en `voces/arcoiris/emparejar/equipo/`.

**Mezcla**: reacciona a los pares **como máximo 1 de cada 3 veces** y nunca encima de Coco.

### 4.1 Llega, avanza y retrocede

**Cuándo avanza (B3)**: el salto ocurre en el **paso 2 del pase**, mientras el retrato del siguiente
vuela al centro y suena "¡Le toca a…!". Para no pisarse, `avanza_*` suena **justo después** de
`le_toca_*` (o de `sube_ventanita_*`), con la nave girando. Nunca al final del turno anterior.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_coleccionauta_entra | Coleccionauta | «¡Ajá! ¡Las cartas de Coco! Si llego a la mesa, ¡van a mi colección! ...¿Para qué lado era la mesa?» | grandilocuente y después perdido (su tic) | Al empezar la partida, tras `intro_ayudan` | `voces/arcoiris/emparejar/equipo/coleccionauta_entra.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coco_juntemos | Coco | «¡Juntemos todas las parejas antes de que llegue!» | divertida, de aventura, sin apuro | Respuesta a `coleccionauta_entra` | `voces/arcoiris/emparejar/equipo/coco_juntemos.wav` | TTS |
| nucleo_equipo_coleccionauta_avanza_01 | Coleccionauta | «¡Boing! Una galletita más cerca.» | saltarín, orgulloso | Salta una galleta en el pase, después de `le_toca` (tras un turno de Nicole o Sofía) | `voces/nucleo/equipo/coleccionauta/avanza_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_avanza_02 | Coleccionauta | «¡Jo, jo, ya casi! ...¿O no? Nunca sé contar galletas.» | risa tonta y después duda | Variante | `voces/nucleo/equipo/coleccionauta/avanza_02.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_avanza_03 | Coleccionauta | «¡Boing! ¡Uy, casi me como la galleta!» | goloso, con risa | Variante | `voces/nucleo/equipo/coleccionauta/avanza_03.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_avanza_04 | Coleccionauta | «Un saltito... ¡y otro saltito! Bueno, solo uno.» | se agranda y se desinfla | Variante | `voces/nucleo/equipo/coleccionauta/avanza_04.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_par_01 | Coleccionauta | «¡Ay, no! ¡Se me resbalan las gafas!» | exagerado, cómico | El equipo forma un par (máx. 1 de cada 3) | `voces/nucleo/equipo/coleccionauta/par_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_par_02 | Coleccionauta | «¡Otra pareja! ¿Cómo lo hacen?» | asombrado de verdad | Variante | `voces/nucleo/equipo/coleccionauta/par_02.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_par_03 | Coleccionauta | «¡Ay, no, no, no! ...Qué bien juegan, eso sí.» | quejón y luego sincero | Variante | `voces/nucleo/equipo/coleccionauta/par_03.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_retrocede_01 | Coleccionauta | «¡Uy, uy, uy! ¡Me resbalé para atrás!» | tambaleándose con la mochila-torre | Racha de 3 en un turno: tropieza y retrocede una galleta (M1) | `voces/nucleo/equipo/coleccionauta/retrocede_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_retrocede_02 | Coleccionauta | «¡Oiga! ¿Quién movió las galletas? ...Ah, fui yo. Para atrás.» | indignado de mentira, se desinfla | Variante | `voces/nucleo/equipo/coleccionauta/retrocede_02.wav` | casera (papá) |
| arcoiris_emparejar_equipo_retrocede_celebra | Coco | «¡Tres parejas seguidas! ¡Para atrás, Coleccionauta!» | fiesta de equipo, sin nombre | Justo después de `retrocede_*` (el equipo aplaude) | `voces/arcoiris/emparejar/equipo/retrocede_celebra.wav` | TTS |

### 4.2 Embobado con Maxi (no avanza en su turno)

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_coleccionauta_embobado_01 | Coleccionauta | «Ooooh... qué bien juega ese chiquitito. Me quedé mirando.» | derretido, como abuelo en un acto del jardín | Turno de Maxi (al azar) | `voces/nucleo/equipo/coleccionauta/embobado_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_embobado_02 | Coleccionauta | «¡Bravo, bravo! ...Uy, se me olvidó avanzar.» | aplaudiendo; el "uy" pillado | Fiesta del par de Maxi | `voces/nucleo/equipo/coleccionauta/embobado_02.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_embobado_03 | Coleccionauta | «Shhh... estoy mirando a Maxi. ¡Qué valiente!» | susurrando, "shhh" largo (gag para Maxi) | Variante | `voces/nucleo/equipo/coleccionauta/embobado_03.wav` | casera (papá) |

### 4.3 Derrota-gag: aspira, estornuda, y el logro común (B3)

Empieza **con el retrato del siguiente ya al centro** (el salto del pase lo hizo llegar). Todo en
plural y sin nombres. Orden propuesto:

`aspira` → (la mochila-torre se infla) → `estornuda` → (cartas volando a la mesa) → `cansado` →
`coco_otra_vez` → `pares_juntados_N` (Cometa, con el número de pares ya formados; si son 0,
`nos_alcanzo`) → al tocar "¡otra vez!", `vuelve`.

El botón "¡otra vez!" aparece desde el comienzo del gag (m4) y tocarlo corta la secuencia.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_coleccionauta_aspira | Coleccionauta | «¡Llegué! ¡Todas a mi colección! Sluuuurp...» | triunfal de mentira; el "sluuurp" largo y chistoso | Llega a la mesa | `voces/arcoiris/emparejar/equipo/coleccionauta_aspira.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coleccionauta_estornuda | Coleccionauta | «¿Eh? Mi mochila está rara... A... a... ¡ACHÚUU!» | extrañado, y el estornudo enorme (gag para Maxi) | La mochila-torre se infla y estornuda las cartas | `voces/arcoiris/emparejar/equipo/coleccionauta_estornuda.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coleccionauta_cansado | Coleccionauta | «Uf... cuesta guardar tantas cosas solo.» | sentado, con cartas en la cabeza; un poquito tierno, nada triste | Cae sentado | `voces/arcoiris/emparejar/equipo/coleccionauta_cansado.wav` | casera (papá) |
| arcoiris_emparejar_equipo_coco_otra_vez | Coco | «¡Jajaja! ¡Las cartas volvieron volando!» | riéndose con todos | Después de `cansado` (texto acortado en v2: lo de "se quedan" pasó a `pares_juntados`) | `voces/arcoiris/emparejar/equipo/coco_otra_vez.wav` | TTS |
| nucleo_equipo_nos_alcanzo | Cometa | «¡Nos alcanzó! ¡Otra vez, equipo!» | riéndose, con energía para seguir | Cierre si el equipo no había formado ningún par | `voces/nucleo/equipo/nos_alcanzo.wav` | TTS |
| nucleo_equipo_coleccionauta_vuelve | Coleccionauta | «Bueno, bueno... desde el principio. Fiu, fiu, fiu...» | resignado alegre, silbando | Vuelve caminando a la galleta 0 | `voces/nucleo/equipo/coleccionauta/vuelve.wav` | casera (papá) |

**Logro común (`pares_juntados`, clave `"1"` a `"12"`)**: Cometa, tono de orgullo y risa, siempre en
plural. Ruta `voces/nucleo/equipo/pares_juntados_<n>.wav`, id `nucleo_equipo_pares_juntados_<n>`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_pares_juntados_1 | Cometa | «¡Igual juntamos una pareja, y se queda! ¡Otra vez, equipo!» | orgulloso, animando | Derrota con 1 par formado | `voces/nucleo/equipo/pares_juntados_1.wav` | TTS |
| nucleo_equipo_pares_juntados_2 | Cometa | «¡Igual juntamos dos parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 2 pares | `voces/nucleo/equipo/pares_juntados_2.wav` | TTS |
| nucleo_equipo_pares_juntados_3 | Cometa | «¡Igual juntamos tres parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 3 | `voces/nucleo/equipo/pares_juntados_3.wav` | TTS |
| nucleo_equipo_pares_juntados_4 | Cometa | «¡Igual juntamos cuatro parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 4 | `voces/nucleo/equipo/pares_juntados_4.wav` | TTS |
| nucleo_equipo_pares_juntados_5 | Cometa | «¡Igual juntamos cinco parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 5 | `voces/nucleo/equipo/pares_juntados_5.wav` | TTS |
| nucleo_equipo_pares_juntados_6 | Cometa | «¡Igual juntamos seis parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 6 | `voces/nucleo/equipo/pares_juntados_6.wav` | TTS |
| nucleo_equipo_pares_juntados_7 | Cometa | «¡Igual juntamos siete parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 7 | `voces/nucleo/equipo/pares_juntados_7.wav` | TTS |
| nucleo_equipo_pares_juntados_8 | Cometa | «¡Igual juntamos ocho parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 8 | `voces/nucleo/equipo/pares_juntados_8.wav` | TTS |
| nucleo_equipo_pares_juntados_9 | Cometa | «¡Igual juntamos nueve parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 9 | `voces/nucleo/equipo/pares_juntados_9.wav` | TTS |
| nucleo_equipo_pares_juntados_10 | Cometa | «¡Igual juntamos diez parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 10 | `voces/nucleo/equipo/pares_juntados_10.wav` | TTS |
| nucleo_equipo_pares_juntados_11 | Cometa | «¡Igual juntamos once parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 11 | `voces/nucleo/equipo/pares_juntados_11.wav` | TTS |
| nucleo_equipo_pares_juntados_12 | Cometa | «¡Igual juntamos doce parejas, y se quedan! ¡Otra vez, equipo!» | ídem | 12 | `voces/nucleo/equipo/pares_juntados_12.wav` | TTS |

Son genéricas ("parejas", no "cartas"), así que sirven para cualquier juego en equipo que junte parejas.

### 4.4 Aplaude la victoria del equipo

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_coleccionauta_aplaude_01 | Coleccionauta | «¡Ay, no llegué! ...Pero qué buen equipo. ¿Dónde venden uno?» | desilusión de broma y después admiración; la pregunta, en serio | El equipo gana (paso 1 de la fiesta; le cae confeti en las gafas-lupa) | `voces/nucleo/equipo/coleccionauta/aplaude_01.wav` | casera (papá) |
| nucleo_equipo_coleccionauta_aplaude_02 | Coleccionauta | «¡Me ganaron! ¡Bravo! ...¿Un equipo cabe en mi mochila? No, ¿cierto?» | aplaudiendo, después pensativo y chistoso | Variante | `voces/nucleo/equipo/coleccionauta/aplaude_02.wav` | casera (papá) |

---

## 5. Fiesta del equipo y choque de manos

Orden (ficha §5.6): `aplaude` (Coleccionauta) → `coco_victoria` → `al_frente` → gestos por turnos (con
el grito de cada niño si existe) → `choca` → `equipo_estelar` + confeti → `destellos` (solo si alguien
recibe) → `record` o `primer_record_equipo` → `estrellita` (si toca).

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_equipo_coco_victoria | Coco | «¡Todas las parejas, y juntos! Mírenme... ¡ahora soy de todos los colores, como ustedes!» | explota de alegría; pausa antes del color (tic) | Se forma el último par | `voces/arcoiris/emparejar/equipo/coco_victoria.wav` | TTS |
| nucleo_equipo_al_frente | Cometa | «¡Todos al frente! ¡A celebrar!» | fiesta | Los hermanos salen juntos al frente | `voces/nucleo/equipo/al_frente.wav` | TTS |
| nucleo_equipo_fiesta_maxi | Maxi | «¡Síiii!» | su grito real, con los saltitos | Gesto de Maxi (0,8 s) | `voces/nucleo/equipo/fiesta_maxi.wav` | niños (opcional) |
| nucleo_equipo_fiesta_nicole | Nicole | Su grito de fiesta, una o dos palabras; ella lo elige (sugerencia: «¡Corazón!») | tierna, como su gesto | Gesto de Nicole (0,8 s) | `voces/nucleo/equipo/fiesta_nicole.wav` | niños (opcional) |
| nucleo_equipo_fiesta_sofia | Sofía | Su grito de fiesta, una o dos palabras; ella lo elige (sugerencia: «¡Paz!») | pícara, como su gesto | Gesto de Sofía (0,8 s) | `voces/nucleo/equipo/fiesta_sofia.wav` | niños (opcional) |
| nucleo_equipo_choca | Cometa | «¡Manos al centro... y choca!» | suspenso corto y explosión | Las manos se juntan al centro | `voces/nucleo/equipo/choca.wav` | TTS |
| nucleo_equipo_equipo_estelar | Cometa | «¡Equipo estelar!» | el grito más grande de Cometa | Choque de manos + confeti arcoíris | `voces/nucleo/equipo/equipo_estelar.wav` | TTS |
| nucleo_equipo_destellos | Cometa | «¡Destellos para todos!» | generoso, repartiendo | Aparecen los "+50" bajo los retratos premiados. **Si no todos reciben, no suena** (diría "todos" sin ser cierto): solo el tintineo | `voces/nucleo/equipo/destellos.wav` | TTS |
| arcoiris_emparejar_equipo_record | Coco | «¡Nuevo récord del equipo! Lo dejamos más lejos que nunca.» | orgullosa, con el trofeo-cupcake | Gana con el Coleccionauta antes de la banderita | `voces/arcoiris/emparejar/equipo/record.wav` | TTS |
| arcoiris_emparejar_equipo_primer_record | Coco | «¡Su primer récord de equipo! Aquí queda la banderita.» | ilusionada, clavando la banderita | Primera victoria de esa combinación en ese nivel (no había banderita, m6) | `voces/arcoiris/emparejar/equipo/primer_record.wav` | TTS |
| nucleo_equipo_estrellita | Cometa | «¡Una estrellita para el equipo! ¡Mírenla volar!» | maravillado | Se enciende la estrellita de equipo de la zona | `voces/nucleo/equipo/estrellita.wav` | TTS |

---

## 6. Mejoras de Parejas en solitario: racha, récord, vela, vistazo y estrellitas de Nicole

Solo para Nicole (Brote) y Sofía (Estrella). Maxi tiene la racha **solo con sonido**, y en equipo nada
de este bloque tiene voz (M1). Ruta base `voces/arcoiris/emparejar/reto/`. **Regla de mezcla**: desde
la racha ×2, la línea de racha **reemplaza** a `acierto_par_0X`.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_reto_racha_2 | Coco | «¡Dos seguidas!» | alegre | Racha ×2 | `voces/arcoiris/emparejar/reto/racha_2.wav` | TTS |
| arcoiris_emparejar_reto_racha_3 | Coco | «¡Tres seguidas! ¡Ojos de estrella!» | más alto, emocionada | Racha ×3 | `voces/arcoiris/emparejar/reto/racha_3.wav` | TTS |
| arcoiris_emparejar_reto_racha_4 | Coco | «¡Cuatro! ¡No te para nadie!» | eufórica | Racha ×4 | `voces/arcoiris/emparejar/reto/racha_4.wav` | TTS |
| arcoiris_emparejar_reto_racha_5 | Coco | «¡Racha arcoíris! ¡Al máximo!» | la más grande, casi cantada | Racha ×5 (tope) | `voces/arcoiris/emparejar/reto/racha_5.wav` | TTS |
| arcoiris_emparejar_reto_racha_sigue | Coco | «¡Y sigue la racha!» | feliz, sin subir más | Otro par estando en el tope | `voces/arcoiris/emparejar/reto/racha_sigue.wav` | TTS |
| arcoiris_emparejar_reto_a_la_primera_01 | Coco | «¡A la primera! ¡Qué suerte!» | sorpresa, campanita | Par "a la primera" | `voces/arcoiris/emparejar/reto/a_la_primera_01.wav` | TTS |
| arcoiris_emparejar_reto_a_la_primera_02 | Coco | «¡Sin buscar y a la primera! ¡Trébol de la suerte!» | asombrada (el sello es un trébol) | Variante | `voces/arcoiris/emparejar/reto/a_la_primera_02.wav` | TTS |
| arcoiris_emparejar_reto_record_pasa | Coco | «¡Récord!» | una palabra, sin frenar el juego | La barra pasa la banderita-cupcake | `voces/arcoiris/emparejar/reto/record_pasa.wav` | TTS |
| arcoiris_emparejar_reto_record_nuevo_01 | Coco | «¡Nuevo récord! ¡Le ganaste a tu propio récord!» | orgullosa, con el trofeo-cupcake | Final con récord nuevo | `voces/arcoiris/emparejar/reto/record_nuevo_01.wav` | TTS |
| arcoiris_emparejar_reto_record_nuevo_02 | Coco | «¡Nuevo récord! Este trofeo-cupcake es tuyo.» | entregándolo, tierna | Variante | `voces/arcoiris/emparejar/reto/record_nuevo_02.wav` | TTS |
| arcoiris_emparejar_reto_primer_record | Coco | «¡Tu primer récord! Aquí queda tu banderita.» | ilusionada, clavando la banderita | Primera partida terminada en esa estación (todavía no había récord; clave `primer_record`) | `voces/arcoiris/emparejar/reto/primer_record.wav` | TTS |
| arcoiris_emparejar_reto_vela_presenta | Coco | «¿Ves la velita? Si terminas antes de que se apague, ¡puntos extra!» | de regalo, nunca de amenaza | Primera vez que aparece la vela (Brote: desde la zona 2 y con récord, M7) | `voces/arcoiris/emparejar/reto/vela_presenta.wav` | TTS |
| arcoiris_emparejar_reto_vela_encendida | Coco | «¡La velita sigue encendida! ¡Puntos de regalo!» | contenta, con tintineo | Se termina el tablero con la vela encendida | `voces/arcoiris/emparejar/reto/vela_encendida.wav` | TTS |
| arcoiris_emparejar_reto_vela_dormida | Coco | «Shhh... la velita se quedó dormida. ¡Tú sigue, que cada pareja suma!» | susurrando el "shhh", después alegre y cómplice; jamás "se acabó" | La vela se apaga (M7.3); Coco se encoge de hombros | `voces/arcoiris/emparejar/reto/vela_dormida.wav` | TTS |
| arcoiris_emparejar_reto_vistazo_mira | Coco | «¡Mira!» | corta, con destello | Cada vistazo al repartir (en solitario) | `voces/arcoiris/emparejar/reto/vistazo_mira.wav` | TTS |
| arcoiris_emparejar_reto_vistazo_presenta | Coco | «Al repartir, te muestro unas cartas un ratito. ¡Míralas bien!» | cómplice, contando un secreto | Primer vistazo de cada hermano (en lugar de `vistazo_mira`) | `voces/arcoiris/emparejar/reto/vistazo_presenta.wav` | TTS |

### 6.1 Las estrellitas de Nicole por puntaje (motor §10.1.1)

Hablan del logro, nunca de lo que faltó. Mismo tamaño de voz que las de Sofía.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_reto_estrellitas_brote_1 | Coco | «¡Terminaste! ¡Una estrella brillante para ti!» | fiesta grande, igual que con tres; atrapa la estrella con la lengua | Celebración con 1 estrellita ("la estrella de terminar") | `voces/arcoiris/emparejar/reto/estrellitas_brote_1.wav` | TTS |
| arcoiris_emparejar_reto_estrellitas_brote_2 | Coco | «¡Dos estrellas! ¡Qué memoria!» | admirada | 2 estrellitas | `voces/arcoiris/emparejar/reto/estrellitas_brote_2.wav` | TTS |
| arcoiris_emparejar_reto_estrellitas_brote_3 | Coco | «¡Tres estrellas! ¡Memoria arcoíris!» | la más cantada | 3 estrellitas | `voces/arcoiris/emparejar/reto/estrellitas_brote_3.wav` | TTS |
| arcoiris_emparejar_reto_otra_estrellita | Coco | «¡Con una racha larga sale otra estrellita!» | pista de secreto, nunca reproche | Nicole vuelve a entrar a una estación donde tiene 1 o 2 estrellitas (no suena con 3) | `voces/arcoiris/emparejar/reto/otra_estrellita.wav` | TTS |

---

## 7. Cartas especiales

Ruta base `voces/arcoiris/emparejar/especiales/`. La línea `presenta` suena **una sola vez por
hermano**, con la carta agrandada al centro; después, solo la palabra corta.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_especiales_comodin_presenta | Coco | «¡Comodín arcoíris! Va con cualquier carta.» | maravillada, mostrándolo | Primera vez que se da vuelta | `voces/arcoiris/emparejar/especiales/comodin_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_comodin | Coco | «¡Comodín!» | fiesta corta | Las veces siguientes | `voces/arcoiris/emparejar/especiales/comodin.wav` | TTS |
| arcoiris_emparejar_especiales_dorada_presenta | Coco | «¡Carta dorada! Muchos puntos... ¡y la próxima pareja vale doble!» | brillante, de tesoro | Primera vez que Sofía forma la dorada | `voces/arcoiris/emparejar/especiales/dorada_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_dorada | Coco | «¡Dorada!» | campana grave en la voz | Las veces siguientes | `voces/arcoiris/emparejar/especiales/dorada.wav` | TTS |
| arcoiris_emparejar_especiales_lupa_presenta | Coco | «¡Lupa! Abro bien grandes mis ojos... ¡y mi abanico de luz te muestra todas las cartas!» | "grandes" estirado mientras abre los ojos de camaleón; "luz" brillante, con el abanico que barre el tablero | Primera vez que se forma la pareja lupa (gesto nuevo de la ficha: ojos grandes que giran juntos y abanico de luz arcoíris desde la cresta) | `voces/arcoiris/emparejar/especiales/lupa_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_lupa | Coco | «¡Tadá!» | arpa, mágica | Las veces siguientes | `voces/arcoiris/emparejar/especiales/lupa.wav` | TTS |
| arcoiris_emparejar_especiales_coleccionauta_presenta | Coco | «¡La carta del Coleccionauta! Va a cambiar dos cartas de lugar. ¡Síguelas con la mirada!» | divertida, avisando como juego | Primera vez que Sofía la da vuelta | `voces/arcoiris/emparejar/especiales/coleccionauta_presenta.wav` | TTS |
| arcoiris_emparejar_especiales_coleccionauta_cambia_01 | Coleccionauta | «¡Qué lindas! Me llevo... no, no. Mejor las cambio de lugar.» | tentado, se arrepiente solo | Se asoma y cambia dos cartas | `voces/arcoiris/emparejar/especiales/coleccionauta_cambia_01.wav` | casera (papá) |
| arcoiris_emparejar_especiales_coleccionauta_cambia_02 | Coleccionauta | «¡Ooh, cartas! Las guardo en mi... no, mejor las cambio. ¡Listo!» | se corta a media idea | Variante | `voces/arcoiris/emparejar/especiales/coleccionauta_cambia_02.wav` | casera (papá) |
| arcoiris_emparejar_especiales_coleccionauta_chao | Coleccionauta | «¡Chao, chao! ¡Uy, mi mochila!» | despedida alegre y tropezón | Se va tropezando (o se queda en el borde, ver revancha) | `voces/arcoiris/emparejar/especiales/coleccionauta_chao.wav` | casera (papá) |
| arcoiris_emparejar_especiales_coco_risa | Coco | «¡Jiji! ¿Viste adónde se fueron?» | tapándose la boca, cómplice | Después de `coleccionauta_chao` | `voces/arcoiris/emparejar/especiales/coco_risa.wav` | TTS |
| arcoiris_emparejar_especiales_revancha | Coco | «¡Te pillé, Coleccionauta!» | triunfal y pícara, de juego | Sofía forma un par con una de las cartas movidas (M8, +300) | `voces/arcoiris/emparejar/especiales/revancha.wav` | TTS |
| arcoiris_emparejar_especiales_coleccionauta_se_cae | Coleccionauta | «¡Uaaa! ¡Me pillaron! ...Y me caí de la silla.» | sorprendido, después muerto de la risa de sí mismo | Justo después de `revancha`: se cae de su silla en el borde | `voces/arcoiris/emparejar/especiales/coleccionauta_se_cae.wav` | casera (papá) |

Con `"modo": "solo_gag"` (respaldo M8) se usa `cambia_01` igual: el texto calza, porque solo habla de
cambiarlas. Si el PO activa ese modo, conviene una variante "...mejor las dejo donde estaban"; queda
anotada, no escrita.

---

## 8. Camino de colores (Sofía, reto dorado de Parejas en la zona 4)

Ruta base `voces/arcoiris/emparejar/camino/`. La demostración (M9.3) va **sincronizada**: cada línea
`demo` suena cuando su carta se da vuelta, y la cuarta muestra una carta que **no** comparte nada.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_emparejar_camino_intro_01 | Coco | «¡Sofía, un juego nuevo: el Camino de colores!» | de estreno, emocionada | Al entrar | `voces/arcoiris/emparejar/camino/intro_01.wav` | TTS |
| arcoiris_emparejar_camino_demo_01 | Coco | «Mira esta estrella roja.» | lenta, mostrando | Demo: se da vuelta la estrella roja | `voces/arcoiris/emparejar/camino/demo_01.wav` | TTS |
| arcoiris_emparejar_camino_demo_02 | Coco | «Este corazón también es rojo: ¡van juntos por el color!» | descubriendo; acento en "color" | Demo: corazón rojo + glaseado rojo | `voces/arcoiris/emparejar/camino/demo_02.wav` | TTS |
| arcoiris_emparejar_camino_demo_03 | Coco | «Y este corazón azul... ¡va con el otro corazón, por la figura!» | sorpresa; acento en "figura" | Demo: corazón azul + glaseado con estampitas | `voces/arcoiris/emparejar/camino/demo_03.wav` | TTS |
| arcoiris_emparejar_camino_demo_04 | Coco | «¿Y esta luna verde? ¡Esta no, no tiene nada igual!» | pregunta y después "no" juguetón, meneando la cabeza | Demo: luna verde sin glaseado, meneo amistoso | `voces/arcoiris/emparejar/camino/demo_04.wav` | TTS |
| arcoiris_emparejar_camino_intro_02 | Coco | «Cada carta se parece a la anterior: en el color o en la figura. ¡Arma el camino más largo!» | clara, desafiante con cariño | Fin de la demo | `voces/arcoiris/emparejar/camino/intro_02.wav` | TTS |
| arcoiris_emparejar_camino_pista | Cometa | «Mira la última carta. ¿Cuál tiene su color, o su figura?» | en secreto, ayudando | Tocar a Cometa | `voces/arcoiris/emparejar/camino/pista.wav` | TTS |
| arcoiris_emparejar_camino_horneado | Coco | «¡Al horno! Este pedacito ya no se desarma.» | orgullosa, con el "ding" | Se hornea un tramo de 4 cartas (M9.1) | `voces/arcoiris/emparejar/camino/horneado.wav` | TTS |
| arcoiris_emparejar_camino_no_comparte_01 | Coco | «¡Uy, esa no se parece! Se tapó el pedacito nuevo... pero lo horneado se queda.» | liviana; tranquilizadora al final | Carta que no comparte nada, con algún tramo horneado | `voces/arcoiris/emparejar/camino/no_comparte_01.wav` | TTS |
| arcoiris_emparejar_camino_no_comparte_02 | Coco | «¡Esa no combina! Acuérdate de dónde quedaron.» | cómplice | Variante (y la única si todavía no hay tramo horneado) | `voces/arcoiris/emparejar/camino/no_comparte_02.wav` | TTS |
| arcoiris_emparejar_camino_sin_salida | Coco | «¡No queda por dónde seguir: llegaste al final!» | fiesta, es una victoria | Ninguna tapada continúa el camino | `voces/arcoiris/emparejar/camino/sin_salida.wav` | TTS |
| arcoiris_emparejar_camino_meta | Coco | «¡Doce cartas en camino! ¡Lo lograste, Sofía!» | orgullosa | Se llega a `largo_meta` | `voces/arcoiris/emparejar/camino/meta.wav` | TTS |
| arcoiris_emparejar_camino_record | Coco | «¡Tu camino más largo!» | admiración | Récord de largo superado | `voces/arcoiris/emparejar/camino/record.wav` | TTS |
| arcoiris_emparejar_camino_derrota_gag | Coco | «¡Las cartas se fueron en conga! Y yo quedé... mareadita. ¡Otra vez!» | mareada, riéndose de sí misma | Derrota: las cartas bailan conga | `voces/arcoiris/emparejar/camino/derrota_gag.wav` | TTS |
| arcoiris_emparejar_camino_regalo | Coco | «Te armo los primeros tres pasos. ¡Sigue tú, Sofía!» | generosa, sin lástima | Tras 2 derrotas | `voces/arcoiris/emparejar/camino/regalo.wav` | TTS |

Si `largo_meta` deja de ser 12, hay que regrabar `meta` (dice "doce").

---

## 9. Colección: "La caja de cartas de Coco"

Ruta base `voces/arcoiris/coleccion/`. Los nombres de cada carta son del catálogo
(`datos/colecciones/cartas_arcoiris.json`) y quedan fuera de este guion. En modo equipo la casita está
dormida y no abre la colección (m9), así que `caja_entrar`, `silueta` y `mostrar` solo suenan en
solitario.

| id | personaje | texto | intención | disparador | ruta | grabación |
|---|---|---|---|---|---|---|
| arcoiris_coleccion_nueva_01 | Coco | «¡Nueva!» | chispeante, encima del "clink" | Par que entra por primera vez a la colección (sin pausar) | `voces/arcoiris/coleccion/nueva_01.wav` | TTS |
| arcoiris_coleccion_nueva_02 | Coco | «¡Otra nueva!» | ídem | Segunda nueva o más en la misma partida | `voces/arcoiris/coleccion/nueva_02.wav` | TTS |
| arcoiris_coleccion_final | Coco | «¡Cartas nuevas para tu caja!» | regalando | Antes de que vuelen a la cajita | `voces/arcoiris/coleccion/final.wav` | TTS |
| arcoiris_coleccion_final_equipo | Coco | «¡Cartas nuevas para cada uno!» | repartiendo, igual para todos | Ídem, en modo equipo | `voces/arcoiris/coleccion/final_equipo.wav` | TTS |
| arcoiris_coleccion_cuenta_1 | Coco | «¡Una!» | contando, alegre | 1.ª carta que entra (0,5 s por carta) | `voces/arcoiris/coleccion/cuenta_1.wav` | TTS |
| arcoiris_coleccion_cuenta_2 | Coco | «¡Dos!» | ídem | 2.ª | `voces/arcoiris/coleccion/cuenta_2.wav` | TTS |
| arcoiris_coleccion_cuenta_3 | Coco | «¡Tres!» | ídem | 3.ª | `voces/arcoiris/coleccion/cuenta_3.wav` | TTS |
| arcoiris_coleccion_cuenta_4 | Coco | «¡Cuatro!» | ídem | 4.ª | `voces/arcoiris/coleccion/cuenta_4.wav` | TTS |
| arcoiris_coleccion_cuenta_5 | Coco | «¡Cinco!» | ídem | 5.ª | `voces/arcoiris/coleccion/cuenta_5.wav` | TTS |
| arcoiris_coleccion_cuenta_6 | Coco | «¡Seis!» | ídem, la más alta | 6.ª (después solo "clink") | `voces/arcoiris/coleccion/cuenta_6.wav` | TTS |
| arcoiris_coleccion_caja_entrar | Coco | «¡Mi caja de cartas! Toca una y te digo su nombre.» | orgullosa, invitando | Abrir la colección desde la casita-cupcake | `voces/arcoiris/coleccion/caja_entrar.wav` | TTS |
| arcoiris_coleccion_silueta | Coco | «¡Esa todavía está escondida! Aparece jugando a las parejas.» | misteriosa y alegre, nunca "no la tienes" | Tocar una silueta con "?" | `voces/arcoiris/coleccion/silueta.wav` | TTS |
| arcoiris_coleccion_mostrar | Coco | «¡Estas cartas son para mirarlas juntos! ¿A quién se las muestras?» | entusiasta, de compartir | 2.ª visita a la caja en adelante, tras `caja_entrar` | `voces/arcoiris/coleccion/mostrar.wav` | TTS |

---

## 10. Claves `PENDIENTE` de las fichas que este guion resuelve

| ficha | clave | ids |
|---|---|---|
| modo-equipo §8 | `intro_equipo_trucos.maxi/nicole/sofia` | `arcoiris_emparejar_equipo_intro_trucos` (apertura, **falta su clave**) + `..._intro_trucos_<hermano>` |
| modo-equipo §8 | `sube_ventanita.nicole/sofia` | `nucleo_equipo_sube_ventanita_<hermano>`. **`maxi` no se escribe**: Maxi nunca sigue a Maxi |
| modo-equipo §8 | `te_toca_recordatorio` (texto ajustado a B1) | `nucleo_equipo_te_toca_<hermano>` y, para la puerta de arrastre, `nucleo_equipo_te_toca_<hermano>_ventanita` (**falta su clave**) |
| modo-equipo §8 | `porras_fin_maxi` | `arcoiris_emparejar_equipo_porras_fin_maxi` |
| modo-equipo §8 | `maxi_lupa` | `arcoiris_emparejar_equipo_maxi_lupa` |
| modo-equipo §8 | `animo_hermanos` | `nucleo_equipo_animo_<hermano>_01/02` (propuesta: objeto por hermano) |
| modo-equipo §8 | `rival_retrocede` | `nucleo_equipo_coleccionauta_retrocede_01/02` + `arcoiris_emparejar_equipo_retrocede_celebra` (**falta su clave**) |
| modo-equipo §8 | `pares_juntados` 1-12 | `nucleo_equipo_pares_juntados_1..12` + `nucleo_equipo_nos_alcanzo` para 0 (**falta su clave**) |
| modo-equipo §8 | `primer_record_equipo` | `arcoiris_emparejar_equipo_primer_record` |
| modo-equipo §3 | presentación única, invitación alternada, puf con nombre (m2) | `nucleo_equipo_presenta`, `nucleo_seleccion_invitacion_equipo`, `nucleo_equipo_al_puf_<hermano>`, `nucleo_equipo_sube_nave_<hermano>` |
| motor §10.1 | `primer_record` | `arcoiris_emparejar_reto_primer_record` |
| motor §10.1 | `vela_dormida` | `arcoiris_emparejar_reto_vela_dormida` |
| motor §10.1 | `estrellitas_brote.1/2/3` | `arcoiris_emparejar_reto_estrellitas_brote_1..3` |
| motor §10.1.1 punto 4 | (sin clave) | `arcoiris_emparejar_reto_otra_estrellita` |
| motor §10.3 | revancha y caída | `arcoiris_emparejar_especiales_revancha`, `..._coleccionauta_se_cae` |
| motor §10.4 | demo del caso que no comparte; tramo horneado | `arcoiris_emparejar_camino_demo_04`, `..._horneado` |

**Para `dev-godot` y `disenador-mecanicas`** (no edito las fichas):

- La secuencia `derrota_gag_equipo` del §8 de la ficha debe sumar `pares_juntados_N` (o `nos_alcanzo`) al
  final, después de `coco_otra_vez`, cuyo texto se acortó.
- El §8 de la ficha todavía lista `nucleo_equipo_al_puf_01/02` y `nucleo_equipo_vuelve`: pasan a ser
  `al_puf_<hermano>` y `sube_nave_<hermano>`.
- `nucleo_equipo_destellos` dice "para todos": solo debe sonar cuando **todos** los del equipo reciben.

---

## 11. Resumen de conteo

| bloque | Coco | Cometa | Coleccionauta (papá) | niños (opcional) | total |
|---|---|---|---|---|---|
| §1 Selección y mapa | 2 | 12 | — | 3 | 17 |
| §2 Pase de turno | — | 17 | — | — | 17 |
| §3 Parejas en equipo | 26 | — | — | 6 | 32 |
| §4 Rival y derrota | 3 | 13 | 19 | — | 35 |
| §5 Fiesta | 3 | 5 | — | 3 | 11 |
| §6 Racha, récord, vela, vistazo, estrellitas | 20 | — | — | — | 20 |
| §7 Especiales | 9 | — | 4 | — | 13 |
| §8 Camino de colores | 14 | 1 | — | — | 15 |
| §9 Colección | 13 | — | — | — | 13 |
| **Total** | **90** | **48** | **23** | **12** | **173** |

- **[v3, 07-Oct-2026, HE-67]** +3 de Coco en §3.1 (`intro_trucos_equipo`, `intro_trucos_equipo_racha`,
  `intro_tope`) y `intro_trucos_sofia` con texto nuevo (sin cambiar el conteo).
- **TTS (Coco y Cometa)**: 138 líneas, todas cortas (las más largas son las 12 de `pares_juntados`).
  Antes de generar: `--estimar` y OK del PO sobre el costo.
- **Grabación casera**: 23 del Coleccionauta (papá) y 12 opcionales de los niños.
- **Fuera de este guion**: las voces de la Batalla final de Arcoíris (HE-67) y los nombres de las cartas
  nuevas del catálogo de colección.
