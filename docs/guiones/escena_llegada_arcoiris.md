# Escena de llegada — Primer contacto con Coco: «Los colores se los llevó»

> Guion narrativo (cinemática, sin interacción). Escrito por `guionista` como decisión B del PO (21-Nov-2026).
> Fuentes: `docs/diseno-juego.md` §1, §2, §4, §6; `docs/guiones/escena_intro.md` (Beat 8b y decisiones de
> Narración); `docs/guiones/zonas_arcoiris.md` §0 (cambio 21-Nov-2026: los colores se los llevó el
> Coleccionauta); `docs/guiones/escena_planeta_arcoiris.md`.
>
> **Estado**: borrador para revisión del PO. Lo marcado como **PREGUNTA** no está decidido.

- **Ubicación en el juego**: después del despegue de Blender (`intro_viaje_01`, Beat 8b de la intro) y del video de
  presentación del planeta (`poc/cinematica_blender/salida/presentacion_arcoiris.mp4`), y **antes de la zona 1**
  (Claro del Trébol). Es la primera vez que los niños pisan el Planeta Arcoíris.
- **Duración estimada**: 40 a 45 s con las líneas base (ver "Duración" más abajo). Cinemática sin interacción.
- **Personajes en cuadro**: Maxi, Nicole y Sofía **con su traje estelar** (en el planeta usan traje, no ropa de
  casa, decisión del PO), Cometa (interviene en escena), Camaleona Coco (anfitriona). **Papá no aparece.**
  **El Coleccionauta no aparece como personaje**: solo se ve su mochila-torre como objeto (PREGUNTA, ver abajo).
- **Escenario**: entrada del Planeta Arcoíris, en gris. Frente a la casita de techo en espiral de Coco (ficha de
  entorno, `docs/guia-estilo-generacion.md` §3, "Planeta Arcoíris"). Al fondo, la frutilla gigante del Claro del
  Trébol, también gris (se ve solo en el último plano).
- **Prefijo de id de línea / carpeta de audio**: `arcoiris_llegada_XXX` → `assets/audio/voces/historia/arcoiris/`
  (ruta sugerida `llegada_XXX.wav`, igual que `escena_planeta_arcoiris.md`).
- **Reemplaza a** (en la función, no se borra): `arcoiris_mapa_zona_1_llegada`. Ver "Relación con el mapa".

## Salvaguardas de tono (obligatorias)

1. **Nada da miedo.** El planeta está gris, pero el gris se dice con cariño ("ahora soy... ¡gris!"), nunca como
   amenaza ni como tristeza que pese. Coco se ríe de su propio gris.
2. **Ningún reproche al Coleccionauta.** Es despistado, no malo (GDD §2: "despistado y solitario, pero jamás malo").
   La explicación es: "pasó por aquí, muy contento, y se llevó mis colores". No es un robo con culpa ni un "se
   escondieron" (decisión B: "no se escondieron").
3. **Nadie apura.** Ninguna línea dice "rápido", "ya" ni "no hay tiempo". El plan es "paso a paso" (o no se dice).
4. **Cometa no regaña ni dramatiza.** Su único aporte es tranquilizar y bromear sobre su propio aterrizaje.
5. **Coco explica con su tic de color**: anuncia el color que es en cada momento, aunque sea gris. El gag del
   intento de rojo (plano 04) es la forma de mostrar que los colores no están, sin decirlo como drama.

---

## Qué sprite o still usa cada personaje

| Personaje | Cómo aparece | Sprite / still | Notas |
|---|---|---|---|
| Maxi | Video IA en 02 y 04 (gag) y 10 (salto final). Sin still propio en esta escena | `maxi_base.png` (traje azul y blanco) para los fotogramas de referencia | Su traje tiene color: ver PREGUNTA d |
| Nicole | Still en 05 (pregunta); video IA en 10 (abrazo) | `nicole_base.png` (traje blanco y rosado) | |
| Sofía | Still en 08 (pregunta) y 09 (plan) | `sofia_base.png` (traje rosado y turquesa) | |
| Cometa | Video IA en 02 (llegada). Still en 08 solo si entra la línea opcional 013 | `cometa_saludo.png` en la línea 003; `cometa_base.png` en el resto | Sin voz en off en esta escena: habla en cuadro |
| Camaleona Coco | Still cutout en planos 03, 07, 08, 09 y 10; video IA en 04 (gag) | `coco_base.png` (**provisional**, pose frontal recortada; el sprite vectorial final es HE-13) | Hace falta versión **gris** (PREGUNTA c) |
| Coleccionauta | No aparece como personaje | Solo su **mochila-torre** como objeto (plano 06 y 07) | PREGUNTA e |

---

## Planos

Los planos 02, 04, 06 y 10 son de **acción física** y llevan video IA (base aprobada, ver `escena_intro.md`,
"Preguntas abiertas"). Los demás son **stills** con voz encima y, como mucho, un paneo leve o zoom de cámara.

| Plano | Tipo | Acotación | En cuadro | Dur. est. |
|---|---|---|---|---|
| 01 | Still (entorno) + sfx | Entrada del planeta en gris: pasto gris, árboles-piruleta grises, la casita de espiral gris. Paneo leve de cámara. Sin personajes. | Ninguno | 2 s |
| 02 | **Video IA (acción)** | Se abre la escotilla de la nave. Los tres bajan. Maxi rebota en el pasto. Cometa baja al final y se tambalea con gracia. | Maxi, Nicole, Sofía, Cometa | 5 s |
| 03 | Still (zoom a Coco) | Coco sale de su casita en espiral, cutout gris, con la cresta de nuditos apagada. | Coco | 3 s |
| 04 | **Video IA (acción)** | Gag del color: Coco se estira y se infla, sacude la cresta, intenta ponerse roja y sale gris otra vez. | Coco | 3 s |
| 05 | Still | Nicole se acerca a Coco con curiosidad. Un poquito de zoom a Nicole. | Nicole, Coco | 3 s |
| 06 | **Video IA (acción)** | Los colores (rojo, amarillo, azul, verde, naranja, violeta y el brillo) vuelan como burbujas de luz hacia la mochila-torre del Coleccionauta. La mochila hace *pluf* y se cierra. Sin personajes. | Solo la mochila (objeto) | 4 s |
| 07 | Still (zoom a Coco) | Coco explica, cantarina, con la mochila detrás (objeto estático). | Coco, mochila | 7 s |
| 08 | Still doble | Sofía pregunta; Coco contesta. Sofía a la izquierda, Coco al centro. Cometa se asoma al final de la escena. | Sofía, Coco (y Cometa, opcional) | 5 s |
| 09 | Still doble | Coco invita al Claro del Trébol; Sofía responde con el plan. Un paneo leve hacia el sendero. | Coco, Sofía | 6 s |
| 10 | **Video IA (acción)** | Nicole abraza a Coco. Los tres echan a andar por el sendero hacia el Claro del Trébol y, al fondo, se ve la frutilla gigante gris. Maxi salta (opcional). | Nicole, Coco, Maxi, Sofía (y Cometa) | 8 s |

## Diálogo

Columna **Estado**: *base* = entra siempre; *opcional* = se borra si la escena pasa de 45 s; *reemplaza* = cubre
la función de un id viejo.

| id | Plano | Personaje | Línea | Intención | Estado |
|---|---|---|---|---|---|
| arcoiris_llegada_001 | 01 | (sfx) | *pluf* suave de aterrizaje y viento en el pasto | calmo, sin golpe fuerte | base |
| arcoiris_llegada_002 | 02 | Maxi | «¡Boing, boing!» | rebotando sobre el pasto, feliz; sin miedo ni extrañeza | base |
| arcoiris_llegada_003 | 02 | Cometa | «¡Llegamos! Le doy un 10 a este aterrizaje... ¡casi sin tumbos!» | con risa; se tambalea al decirlo. Guiño a `intro_012` («un 6 de 10») | base |
| arcoiris_llegada_004 | 03 | Coco | «¡Bienvenidos al Planeta Arcoíris! Ahora soy... ¡gris!» | cálida; anuncia su color (tic), sin tristeza | base |
| arcoiris_llegada_005 | 04 | Coco | «A ver... ¡rojo!... ¡ay, no! ¡Gris otra vez!» | con risa; el «¡rojo!» con ilusión y el «¡gris otra vez!» como gag | base |
| arcoiris_llegada_006 | 04 | Maxi | «¡Jajaja! ¡Gris, gris, gris!» | riéndose, aplaude; el gag le hace gracia | opcional |
| arcoiris_llegada_007 | 05 | Nicole | «Coco, ¿y tus colores? ¿Dónde están?» | curiosa, tierna; pregunta sin alarma | base |
| arcoiris_llegada_008 | 06 | (sfx) | *fiuuu* de colores volando y *pluf* de mochila que se cierra | mágico y chistoso; sin sonido de peligro | base |
| arcoiris_llegada_009 | 07 | Coco | «El Coleccionauta pasó por aquí, muy contento, y se llevó mis colores.» | tranquila, cantarina; "muy contento" y nada de reproche | base |
| arcoiris_llegada_010 | 07 | Coco | «Rojo, amarillo, azul, verde, naranja, violeta... ¡y el brillo! Todo en su mochila.» | cuenta con los dedos, pausa entre colores (tic: los nombra uno por uno) | base |
| arcoiris_llegada_011 | 08 | Sofía | «¿Se escondieron, como en las escondidas?» | curiosa, líder; es su suposición de niña, no una alarma | base |
| arcoiris_llegada_012 | 08 | Coco | «¡No, no! No se escondieron. Se los llevó nomás. Es muy despistado.» | tranquilizadora, con risita; corrige con cariño, sin reproche | base |
| arcoiris_llegada_013 | 08 | Cometa | «Ese despistado... no es malo. ¡Lo conozco bien!» | cálido, cómplice; reafirma que no es malo (GDD §2) | opcional |
| arcoiris_llegada_014 | 09 | Coco | «¿Me ayudan a devolverlos? Vamos al Claro del Trébol, ¡ahí está mi frutilla gigante!» | invita sin apurar; el «¿me ayudan?» es una pregunta, no una orden. **Reemplaza** la función de `arcoiris_mapa_zona_1_llegada` | base |
| arcoiris_llegada_015 | 09 | Sofía | «¡Siete colores! Plan aprobado, Coco.» | líder, con humor; cuenta los siete que escuchó en `010` | base |
| arcoiris_llegada_016 | 10 | Nicole | «¿Te damos un abrazo? Los abrazos no tienen color.» | tierna, solidaria; ofrece un abrazo a Coco sin pedir nada a cambio | base |
| arcoiris_llegada_017 | 10 | Coco | «¡Ay, qué abrazo tan calentito! Ahora soy... ¡gris abrazada!» | con risa; tic del color, en el cariño | base |
| arcoiris_llegada_018 | 10 | Maxi | «¡Vamo vamo vamo!» | saltando de alegría (guiño a `intro_030`), nunca de apuro | opcional |
| arcoiris_llegada_019 | 10 | Coco | «¡Vamos! Ahora soy... ¡gris con ganas de color!» | cierre, animada; el tic que va hacia el color | base |

**Preguntas que hace un niño y respuestas de Coco** (para revisar que sea diálogo y no monólogo): Nicole pregunta
en `007`; Coco explica en `009`, `010` y `012`; Sofía pregunta en `011`; Coco invita en `014` y Sofía responde en
`015`; Nicole ofrece el abrazo en `016` y Coco responde en `017`.

## Duración

Estimación por cuenta de palabras (≈ 2,5 palabras por segundo, más pausas de 0,5 s entre planos). **Con las
líneas base**: 2 + 5 + 3 + 3 + 3 + 4 + 7 + 5 + 6 + 8 ≈ **46 s**. Si se quitan las opcionales (006, 013, 018), baja a
≈ 40 s. Dentro del rango de 30 a 45 s con las opcionales fuera. Esta cifra se mide otra vez con la voz real:
si pasa de 45 s, lo primero que se recorta es `arcoiris_llegada_010` (la lista de colores se puede decir en dos
tiempos) y después `arcoiris_llegada_017`.

## Relación con el mapa (`zonas_arcoiris.md`)

- **`arcoiris_mapa_zona_1_llegada`** ("¡Este es el Claro del Trébol!... ¡el Coleccionauta se llevó mi rojo! ¿Me
  ayudan a devolverlo?"): **no se borra** y conserva su texto nuevo (§0). En la práctica, la primera entrada a la
  zona 1 llega después de esta escena, que ya dijo el robo y ya invitó a ayudar (`014`). Propuesta: en la primera
  entrada no suena, porque la escena ya cumplió esa función; queda de respaldo si alguien entra a la zona sin
  haber visto la escena. **PREGUNTA a) abajo.**
- Las llegadas de las zonas 2 a 5 repiten "se llevó" y eso es intencional: cada zona devuelve su color. No hay
  contradicción con esta escena.

## Preguntas abiertas (PREGUNTA, no decididas)

- **a) Zona 1**: ¿`arcoiris_mapa_zona_1_llegada` se queda como respaldo y no suena en la primera entrada (propuesta),
  o suena igual después de la escena? Si suena, su texto repite la invitación de `014` y conviene acortarlo.
- **b) Presentación del planeta**: ¿el video `presentacion_arcoiris.mp4` termina con la nave-estrella ya posada en el
  pasto gris? El plano 01 asume que sí. No vi el video en este encargo: verificarlo antes de guionar la transición.
- **c) Coco en gris**: `coco_base.png` está en color. Para el gris hay dos caminos: (1) un tinte gris en Godot, sin
  arte nuevo (propuesta, no toca el sprite); (2) una versión gris del sprite. ¿Cuál quiere el PO? Lo mismo aplica a la
  entrada del planeta y a la casita de espiral: no encontré una versión desaturada en `assets/` en la búsqueda de este
  encargo.
- **d) Trajes en color en un planeta gris**: la regla "en el planeta solo quedan cosas grises" habla del planeta.
  Propuesta: los trajes de los niños se ven en color, porque son de ellos y no del planeta. ¿El PO lo confirma?
- **e) Coleccionauta**: propuesta: solo se ve su mochila-torre (objeto) en el plano 06 y 07, sin el personaje. ¿El PO
  quiere verlo, aunque sea de espaldas, o queda fuera de esta escena hasta el planeta final?
- **f) Opcionales** (006, 013, 018): ¿entran? Entran si la voz real deja la escena dentro de 45 s.
- **g) Voz de los niños** en esta escena: no decidido. Misma decisión que el resto de la intro (grabación familiar o
  TTS provisional). Coco y Cometa usan sus voces oficiales (`assets/audio/voces/guion_voces.md`).
- **h) Video IA**: los planos 02, 04, 06 y 10 llevan video IA según la base aprobada; `director-cinematicas` confirma
  el medio de cada uno (el plano 06 solo tiene colores y mochila, sin personajes).

## Notas para `director-cinematicas` y `dev-godot`

- Coco tiene **un solo tic**: anunciar su color. Se usa en `004`, `005`, `017` y `019`. No lo sumen en otras líneas.
- Cometa aparece en cuadro, sin voz en off: no usar el patrón de off de la intro (Beat 8b).
- Los niños **preguntan y responden**: cada pregunta de un niño tiene respuesta de Coco en el plano siguiente o en el
  mismo. Si el storyboard las separa, mantener el orden de los ids.
- La línea `arcoiris_llegada_014` es el puente al mapa: el mapa se abre justo después del plano 10.
- Ningún id de esta escena se reutiliza en otro lugar. Si el PO aprueba el texto, `dev-godot` agrega las filas a
  `assets/audio/voces/guion_voces.md` y genera los audios.
