# Guion de voz — Cierre de la historia del Planeta Arcoíris: de la Torre al despegue

> **Versión 4 (17-Oct-2026): cambios de guion de la auditoría UX HE-71**
> (`docs/validaciones/2026-10-13_ux-torre-cierre-arcoiris.md`). Ver el changelog en el §14. Los ids de la
> v3 se mantienen; solo se agregan ids nuevos (marcados **[v4]**) y se cambian textos.
>
> **Versión 3 (13-Oct-2026), conciliación final.** Se apoya en:
>
> - `docs/fichas/motor-lanzar.md` **v2** (§0, §5, §8-§11, §13.4, §14 `lineas_voz`, §18.2, §21 y §23);
> - el storyboard `docs/cinematicas/cierre_arcoiris.md` **v2** (bloque 1: Torre, caída, fiesta,
>   epílogo, despedida y mapa; bloque 2: preparativos, Coco, foto y llamada, cuenta, despegue y Mapa
>   Estelar);
> - las decisiones del PO del 12 y 13-Oct-2026;
> - `docs/guiones/voces-batalla-arcoiris.md` v2 y `docs/guiones/escena_planeta_arcoiris.md`, cuyas líneas
>   **se reutilizan, no se duplican** (§9).
>
> **Ids**: la ficha v2 y el storyboard v2 se escribieron sobre los ids de la v1 de este guion, así que
> **la v3 vuelve a esos ids**. La v2, que salió del storyboard v1, queda descartada. Los únicos ids que
> cambian respecto de la v1 son los de Nicole (`tuercas_*` y `tornillo_*` pasan a `broches_*` y
> `broche_*`, por la decisión del PO). La tabla del §10 tiene todas las equivalencias.
>
> **[PO]** = espera una decisión del PO. Ya no quedan [CONCILIAR] con la ficha.
>
> Este guion es **solo texto**: no genera audio ni toca los `.tsv`. Antes de cualquier TTS: `--estimar`
> y OK del PO sobre el costo.

## Decisiones aplicadas

| Decisión | Cómo queda |
|---|---|
| Caída en el **charco**: lunares y mochila gris y limpia, porque solo quiso salvarla (PO 13-Oct) | §1: «¡Nooo... mi... mo-chi-laaa!» con la mochila en alto; después, «¡Nunca había estado tan... colorido!» |
| **4 derrotas-gag** del guion (PO 13-Oct) | T.7: las derrotas 1, 2 y 3 usan los gags 1, 2 y 3; desde la 4.ª rotan los 4 (ficha §10.1) |
| **Ruta de Sofía**: A-N-I-M-A-L-I-A con señuelos, y al final un perrito que ladra (PO 13-Oct) | §4.3 |
| **Broches dorados**, no tuercas (PO 13-Oct) | §4.2: **3 broches** (manda el guion; el storyboard v2 dibujó 5) |
| **Puente de 3 bandas** (PO 13-Oct) | §7: ninguna voz nombra otros colores; el tanque de Maxi también usa solo los 3 |
| **`arcoiris_009` se mueve** a la instalación del ala (PO 13-Oct) | §4.2 (NI3) y §8 (`009a` / `009b` en la escena del ala) |
| **El ala es estado familiar** (PO 13-Oct) | Ninguna voz dice "tu ala". `009b` es para el hermano que gana su ala cuando la nave ya la tiene |
| **Regalos de Coco aprobados** (PO 13-Oct) | §5: T-rex de gomita, corazón rosado chicle y pony turquesa (manda el guion; el storyboard v2 todavía muestra los suyos) |
| Gesto (ficha v2 §5; v4: M1, M5 y B2 de la UX) | Nicole y Sofía estiran hacia atrás y sueltan (un toque solo no dispara). Maxi toca o arrastra en cualquier dirección y suelta; si deja el dedo apretado 1,2 s, el globo sale solo. **«Tira para atrás» es solo para las hermanas**; a Maxi se le dice «toca... ¡y suelta!» |
| Color de los globos (ficha §6.8) | Orden fijo, rojo → amarillo → azul; `carga_01/02/03` = el color real |
| Piezas y logro común (ficha §10.1 y §23.1) | 28 piezas; 2 tramos partidos en la mitad; «¡y algunas ya no suben!» |
| `acierto_grande` | 3 piezas o más en un tiro |
| Globos extra (v4: M4 de la UX, por delegación del PO) | 9 de base y **+4** tras la 1.ª derrota, del equipo y se quedan. Cada intento empieza con Maxi, y **el último globo es siempre de Maxi**. Ninguna voz dice cuántos |
| Pausa (v4: M6 de la UX) | Coco ofrece descansar desde la 3.ª derrota (`pausa`) y **una sola vez antes de la Torre, en el mapa de batalla, antes de la presentación** (`pausa_antes`) |
| **Globo gigante** (v4: por delegación del PO) | **Variante A**: Coco lo infla tras la 2.ª derrota y lo tira Maxi; no gana solo. Condición: ≥ 95 % de victorias en ≤ 3 intentos con datos del arnés. La B queda en reserva y no se genera. Ver T.5 |
| Revancha (v4, por delegación del PO) | Se puede jugar con dos hermanos, pero **sin estrellitas ni récord**: `estrellitas_*`, `torre_record` y `primer_record` suenan solo con los tres |
| Final (v4, por delegación del PO) | Termina en el Mapa Estelar con Animalia encendida (`vuelo_rumbo_animalia`), sin encadenar el viaje |
| Dos hermanos + el retrato del tercero (v4: M8 de la UX) | Ninguna voz de la partida pide "los tres" como condición ni nombra al que falta. Se habla de "el equipo" o de "juntos" |

## Decisiones de tono

1. **La Torre es una travesura, no una amenaza.** Con la mochila vacía, el Coleccionauta apila su colección
   para alcanzar el arcoíris "de la mano". El arcoíris que defendieron después es el puente por el que se
   van.
2. **Cada derrota es un chiste distinto, y el chiste lo sufre él.** Nadie dice "perdimos". Cometa cuenta lo
   que lograron ("¡y algunas ya no suben!"), y Coco regala ayudas con su tic: globos "camuflados en el
   pasto, como yo".
3. **Nadie falla con nombre, y los aciertos de Nicole y Sofía tampoco llevan nombre.** Maxi sí oye su
   nombre en sus aciertos. Los globos de Sofía se presentan como "especiales", no "de experta": así no
   suena a "Sofía es más" (Nicole también los oye).
4. **El tic de Coco atraviesa el cierre**: anuncia el color de cada globo, queda "morada de soplar", se pone
   "rosado de emoción" con su ala puesta, toma el color de cada hermano al chocar los cinco y se despide
   en "¡color buen viaje!".
5. **Los colores se comparten**: el charco lo pinta por accidente, pero su mochila sigue gris. Los colores
   que importan son los que le regalan.
6. **El gancho es un mapa perdido, no una amenaza**: «me sé el camino de memoria... ¡creo!», y papá oye
   "¿rugidos?"... o es su guatita.
7. **La despedida es tierna, nunca triste**: «¡No es chao, es hasta pronto!», y cada arcoíris de verdad
   "soy yo, saludándolos".
8. **No se gasta el final de HE-39**: ni llaves, ni el dibujo de Nicole, ni "los amigos no se coleccionan".

---

- **Voces**: Coco y Cometa por TTS. El Coleccionauta, grabación casera de papá (registro
  "grandilocuente-tonto"; **nunca nombra a papá**). Papá como él mismo, grabación familiar: la llamada es
  el cierre del capítulo y **ya no es opcional**. Los niños, opcionales: los tres o ninguno.
- **Rutas** (bajo `assets/audio/`, en `.wav`): Torre y caída, `voces/arcoiris/batalla/torre/`; genéricas
  del motor `lanzar`, `voces/nucleo/equipo/`; epílogo y cierre, `voces/arcoiris/batalla/epilogo/` y
  `.../cierre/`; bloque 2, `voces/arcoiris/despegue/`; escena del ala, `voces/historia/arcoiris/`.
- **Id**: `arcoiris_` / `nucleo_` + ruta sin `voces/arcoiris/` / `voces/nucleo/` ni extensión.

---

## T. Etapa 4: «La Torre de la Colección» (motor `lanzar`, ficha v2 §14 `lineas_voz`)

### T.1 Presentación, pausa e intro

**Presentación** (`presentacion`, storyboard §3, ≤ 8 s): P1 apila en cámara rápida y se sienta
(`presenta_coleccionauta`) → P2 se estira hacia el arcoíris (`presenta_alcanzo`) → P3 Coco saca la
resortera (`presenta_coco`). 2,5 + 3 + 2,2 s más el aire ≈ **8 s**. **v4 (M6)**: la pausa antes de jugar (`pausa_antes`, que
espera un toque) va **antes** de la presentación, en el mapa de batalla, igual que entre las rondas. Al
tocar el hito, la presentación sigue directo a la intro corta, sin otra pausa.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_presenta_coleccionauta | Coleccionauta | «¡Caja, frasco, caja... ¡y yo arriba!» | apurado y feliz, al ritmo de lo que apila | 2,5 s | P1 | casera (papá) |
| arcoiris_batalla_torre_presenta_alcanzo | Coleccionauta | «¡Si el arcoíris no cabe en mi mochila... me lo llevo de la mano!» | travieso, de puntillas | 3 s | P2 | casera (papá) |
| arcoiris_batalla_torre_presenta_coco | Coco | «¡Resortera de regaliz! ¡Yo cargo los globos!» | pícara, con un giro | 2,2 s | P3 | TTS |
| arcoiris_batalla_torre_pausa_antes | Coco | «¿Vamos por la torre, o descansamos y volvemos después?» | tranquila, ofrece las dos de verdad (como `pausa_<color>`) | 3,3 s | **v4**: en el mapa de batalla, **antes** de la presentación (un solo «¿seguimos o descansamos?»); no avanza sola. Es el `voz_pausa` de la ronda `torre` | TTS |
| arcoiris_batalla_torre_intro_coleccionauta | Coleccionauta | «¡Torrecita!» | orgulloso, palmoteando la caja de arriba | 1 s | `intro_ronda`, parte 1 (cada intento y al retomar) | casera (papá) |
| arcoiris_batalla_torre_intro | Coco | «¡Por turnos: un globo cada uno!» | clara, de juego | 2,2 s | `intro_ronda`, parte 2 | TTS |
| nucleo_equipo_lanzar_repetir | Cometa | «Tira el globo para atrás, apunta... ¡y suelta! Si botas muchas de un tiro, ¡se resbala!» | con calma; la meta del resbalón, sin números | 5 s | `repetir` de brote y estrella; también la primera vez de cada turno que alguien arrastra al revés (ficha §5.2) | TTS |
| nucleo_equipo_lanzar_repetir_maxi | Cometa | «¡Maxi, toca el globo... y suelta!» *(v4, M5)* | lento, cálido | 2,2 s | `repetir` de semilla (un toque también vale, ficha §5.3; con el dedo apretado 1,2 s sale solo) | TTS |
| nucleo_equipo_lanzar_primer_tiro **[v4]** | Cometa | «¡Estira para atrás... apunta... y suelta!» | cómplice, lento en "para atrás"; con ritmo de juego | 2,6 s | **M1**: primer turno de Nicole y primer turno de Sofía de cada sesión de Torre, justo después de `carga`. Va con la manito fantasma (0,8 s) que estira desde la bolsa hacia atrás. **No bloquea**: si la niña empieza a arrastrar, la voz y la manito se cortan. Sin nombre, la misma para las dos | TTS |

### T.2 Coco carga el globo

`carga` va **por el color real** del globo (ficha §6.8). En el turno de Maxi, en vez de `carga`, suena
`maxi_carga`.

**v4 (m3, ritmo)**: la frase completa `carga_0X` suena solo **la primera vez de cada color por sesión**.
Después basta el color solo, reutilizando las de Coco del tanque (`arcoiris_despegue_tanque_color_rojo`,
`_amarillo`, `_azul`: «¡Rojo!», ≤ 0,8 s), o solo el SFX. La entrada nunca espera a que termine la voz.
En el primer turno de cada hermana, después de `carga` suena `nucleo_equipo_lanzar_primer_tiro` (T.1).

**v4 (ficha v3 §5.3, M5)**: si Maxi deja el dedo apretado 1,2 s, el globo sale solo. **No lleva voz
propia**: suena el "¡pling!" de la chispita y después `maxi_le_dio_0X`, como en cualquier tiro suyo. Así
el tiro es suyo, sin ningún "¡suelta!" que suene a corrección.

**v4 (dos hermanos + el retrato del tercero, ficha v3 §13.4)**: si el turno de Maxi lo juega una hermana
con su retrato (control de Semilla), no suenan las voces con el nombre de Maxi (`maxi_globo_0X`,
`maxi_le_dio_0X`, `gigante_turno_maxi`, `ultimo_globo`). En su lugar suenan las neutras: `carga_corta`,
`acierto_grande` o `acierto_01`, y `gigante_turno`. Si falta una hermana, la otra juega con el perfil de
la ausente y las voces de su turno ya no llevan nombre. Así nadie oye que falta alguien, y nadie oye que
le dan el mérito al que no está.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_carga_01 | Coco | «¡Globo cargado! ¡Rojo frutilla!» | contenta; el color con su tic | 1,8 s | `carga.rojo` | TTS |
| arcoiris_batalla_torre_carga_02 | Coco | «¡Globo cargado! ¡Amarillo limón!» | ídem | 1,8 s | `carga.amarillo` | TTS |
| arcoiris_batalla_torre_carga_03 | Coco | «¡Globo cargado! ¡Azul chupetín!» | ídem | 1,8 s | `carga.azul` | TTS |
| arcoiris_batalla_torre_maxi_globo_01 | Coco | «¡Un globo para Maxi! Toca... ¡y suelta!» *(v4, M5)* | lenta, invitando | 2,5 s | `maxi_carga` | TTS |
| arcoiris_batalla_torre_maxi_globo_02 | Coco | «¡Maxi, tu globo! ¡Tócalo!» *(v4, M5)* | juguetona | 1,8 s | `maxi_carga`, variante | TTS |
| arcoiris_batalla_torre_globos_especiales | Coco | «¡Globos especiales! Uno se divide en tres... y otro es pesadito.» | sorpresa de regalo; "pesadito" con voz de esfuerzo | 3,5 s | `elige_globo_presenta`: primer turno de Sofía, primera vez por familia | TTS |
| arcoiris_batalla_torre_toca_en_el_aire | Coco | «¡Toca en el aire para dividirlo!» | emocionada, clara | 1,8 s | `toca_en_el_aire`: la primera vez que la familia lanza el triple | TTS |

### T.3 Cada tiro (ficha §8.1)

Sin nombre para Nicole y Sofía. `fallo` como máximo 1 de cada 2 veces, y nunca en Maxi.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_maxi_le_dio_01 | Coco | «¡Plaf! ¡Le diste, Maxi!» | fiesta grande | 1,4 s | `maxi_acierto` (su tiro siempre rompe) | TTS |
| arcoiris_batalla_torre_maxi_le_dio_02 | Coco | «¡Qué globazo, Maxi!» | ídem, con risa | 1,3 s | Variante | TTS |
| arcoiris_batalla_torre_acierto_01 | Coco | «¡Plaf! ¡Cayó una caja!» | contenta | 1,4 s | `acierto_equipo.caja`: bota 1-2 piezas | TTS |
| arcoiris_batalla_torre_acierto_02 | Coco | «¡Splash! ¡Justo en un frasco!» | contenta | 1,6 s | `acierto_equipo.frasco`: 1-2 piezas, y una es un frasco | TTS |
| arcoiris_batalla_torre_acierto_03 | Coco | «¡La torre se tambalea!» | emocionada | 1,5 s | `acierto_equipo.tambalea`: pega en la torre y no cae nada | TTS |
| arcoiris_batalla_torre_acierto_grande | Coco | «¡Cataplum! ¡Se cayeron varias!» | eufórica | 1,8 s | `acierto_grande`: **3 piezas o más** en un tiro | TTS |
| arcoiris_batalla_torre_fallo_01 | Coco | «¡Plof! ¡Más pintura para el charco!» | alegre: el tiro también sirvió | 2 s | `fallo_equipo`: no toca la torre (el charco crece, ficha §6.9) | TTS |
| arcoiris_batalla_torre_fallo_02 | Coco | «¡Casi! Pasó volando por al ladito.» | cómplice, hablando del globo | 2 s | Variante | TTS |
| arcoiris_batalla_torre_ultimo_globo | Coco | «¡Maxi, el último globo... con todo el cariño! ¡Tócalo!» *(v4, M4)* | abrazando el globo; tierna, sin tensión, como quien le regala algo | 2,8 s | `ultimo_globo`, con el interruptor `voz_ultimo_globo`. **v4**: el último globo de cada intento es siempre de Maxi (ficha v3 §8.1-§8.2), así que la línea le habla a él y, en ese turno, **reemplaza a `maxi_carga`** (ya lleva su "¡tócalo!"). No suena en la revancha `nicole+sofia` ni cuando el turno de Maxi lo juega una hermana con su retrato | TTS |

`justo_ahi_maxi` (opcional): se reutilizan `arcoiris_batalla_rio_justo_ahi_01/02` («¡Justo ahí!», «¡Ahí
mismito!»).

### T.4 El Coleccionauta en el trono

`rival_reacciona`: como máximo 1 de cada 3 tiros y nunca encima de Coco. Sirve también para el resbalón y
para cuando lo tocan (ficha §5.6 y §7.2).

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_reacciona_01 | Coleccionauta | «¡Uy, uy, uy! ¡Quieta, torrecita, quieta!» | haciendo equilibrio | 2,5 s | El trono se inclina o él se resbala | casera (papá) |
| arcoiris_batalla_torre_reacciona_02 | Coleccionauta | «¡Ay, mi caja de calcetines sin pareja!» | dramático de teleserie | 2,3 s | Cae una caja | casera (papá) |
| arcoiris_batalla_torre_reacciona_03 | Coleccionauta | «¡No me hace nada! ...Bueno, unas cosquillitas.» | valiente de mentira, después honesto | 3 s | Le salpica o lo tocan | casera (papá) |

### T.5 El globo gigante de Coco (v4: **variante A**, por delegación del PO; la B queda en reserva)

**Comunes a las dos variantes**:

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_gigante_coleccionauta | Coleccionauta | «¿Y ese globo tan grande? ¡Eso no es justo! ...Bueno, sí es justo.» | indignado de mentira, después honesto | 3,5 s | `gigante_aparece`: la primera vez que se ve | casera (papá) |
| arcoiris_batalla_torre_gigante_impacto | Coco | «¡PLAAAF! ¡Globazo gigante!» | el grito más grande | 1,6 s | `gigante_impacto` | TTS |

**Variante A (ficha v2 §10.3)**: Coco lo infla **tras la 2.ª derrota**; desde el 3.er intento es el primer
globo de cada intento, **lo tira Maxi** con su tiro guiado y quita como mínimo 12 de agarre (no gana solo).

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_ayuda_globo_gigante | Coco | «Fuuu... fuuu... ¡fuuuuu! ¡Les inflé mi globo gigante! Ahora soy... ¡morada de soplar!» | soplando de verdad, cada "fuuu" más largo; mareadita y feliz (tic) | 6 s | `ayuda_intento_2`: cierre de la 2.ª derrota (storyboard G2e). **v4**: se queda «morada» (Coco habla en femenino en todo el guion); `motor-lanzar.md` §10.3 dice «morado» y debe usar «morada» | TTS |
| arcoiris_batalla_torre_gigante_turno_maxi | Coco | «¡Maxi, el globo gigante! Toca... ¡y suelta!» *(v4, M5)* | emocionada, lenta, de gran momento | 2,8 s | `gigante_turno_maxi`: primer turno del intento ≥ 3 | TTS |
| arcoiris_batalla_torre_gigante_turno | Coco | «¡Te toca el globo gigante! ¡Estira con fuerza!» | emocionada | 2,5 s | `gigante_turno`: respaldo sin nombre, si el PO decide que no lo tire siempre Maxi (ficha §21, decisión 3) | TTS |

**Variante B (guion v2)**: el gigante espera atado desde el 3.er intento. Si se acaban los globos con la
torre en pie, **lo inflan los tres** (ronda de ventanitas con `nucleo_equipo_ahora_<hermano>`), **lo
lanza Coco** y asegura la victoria. Si ganan sin usarlo, Coco lo revienta en la fiesta (storyboard F3).

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_gigante_presenta | Coco | «¡Y si hace falta... tengo uno GIGANTE! Lo dejo aquí, por si acaso.» | cómplice; "GIGANTE" enorme | 4 s | Cierre de la 2.ª derrota (en vez de `ayuda_globo_gigante`) | TTS |
| arcoiris_batalla_torre_inflemoslo | Coco | «¡Inflémoslo los tres! Cada uno toca su ventanita.» | de equipo | 3 s | Sin globos y con la torre en pie, desde el 3.er intento | TTS |
| arcoiris_batalla_torre_gigante_inflado | Coco | «¡Uf! Ahora soy... ¡morada de soplar!» | mareadita y feliz (tic) | 2,3 s | Inflado, antes de que lo lance | TTS |
| arcoiris_batalla_torre_no_lo_necesitamos | Coco | «¡No lo necesitamos! ¡Pop, confeti!» | traviesa | 2 s | F3: ganaron sin usarlo | TTS |
| arcoiris_batalla_torre_lo_bajamos | Cometa | «¡La bajamos los tres!» | orgulloso | 1,5 s | Victoria con el gigante, antes de la anticipación | TTS |

**v4**: se adoptó la **A** (por delegación del PO, con la condición del ≥ 95 % en ≤ 3 intentos medido
con el arnés). Las 5 líneas de la B no se generan. Motivo original de la recomendación: la **A**. La victoria sigue siendo de los tres (no la "regala" un tiro
asegurado), y el gran momento es de Maxi sin quitarles reto a sus hermanas. Con la A, la `pausa` desde la
3.ª derrota tiene sentido real (la ficha estima ≈ 1 % de 4.os intentos).

### T.6 Ayudas y pausa

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_ayuda_globos_extra | Coco | «¡Miren! ¡Más globos! ...¡Estaban camuflados en el pasto, como yo!» *(v4, M4: sin número)* | descubrimiento feliz; se camufla un segundo | 4 s | `ayuda_intento_1`: cierre de la 1.ª derrota. Los +4 son del equipo y se quedan | TTS |
| arcoiris_batalla_torre_encontre_globos | Coco | «¡Encontré unos más! ¡Seguimos!» | alegre, como quien encuentra algo en el bolsillo | 1,8 s | `encontre_globos`: al retomar con la canasta en el mínimo. **v4 (ficha v3 §12)**: el mínimo al retomar es **5**, y la canasta se redondea hacia arriba a 5, 9 o 13 globos, así que el intento retomado también termina con Maxi. La voz no dice el número. **v4**: también es la `ayuda_intento_2` de la revancha `nicole+sofia` (+2 globos, sin gigante), porque no nombra cuántos ni a quién | TTS |
| arcoiris_batalla_torre_pausa | Coco | «¿Vamos otra vez, o descansamos y volvemos después? ¡La torre no se va a ninguna parte!» | tranquila, ofrece las dos; el final con risa | 4,5 s | `pausa_desde_intento_3`: cierre de la 3.ª derrota y siguientes. Descansar guarda todo | TTS |

### T.7 Derrotas-gag (ficha §10.1)

Secuencia: `derrota_<n>_coleccionauta` → `derrota_<n>_coco_risa` → `cajas_botadas_0X` → ayuda o pausa
(T.6, T.5) → al tocar "¡otra vez!": `rearma_0X` → intro corta. Las derrotas 1, 2 y 3 usan los gags 1, 2 y
3; desde la 4.ª rotan los 4 sin repetir el anterior. El conteo es por familia y se guarda; la revancha lo
reinicia.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_derrota_1_coleccionauta | Coleccionauta | «¡Sigo arriba! ¡Baile de la torre! Un pasito pa'cá...» *(¡plof!)* «...¿Por qué llueve rosado?» *(v4, M7)* | fiestero; el final desconcertado. **Papá corta el baile en "pa'cá"**: ahí cae el frasco | 4 s | Gag `baile`: el frasco de pintura rosada se le da vuelta **a los ≤ 2,5 s**. Los retratos se ríen en el remate, no durante el baile | casera (papá) |
| arcoiris_batalla_torre_derrota_1_coco_risa | Coco | «¡Jajaja! ¡Se le dio vuelta un frasco de pintura en la cabeza!» | riéndose con todos | 3 s | Después del gag 1 | TTS |
| arcoiris_batalla_torre_derrota_2_coleccionauta | Coleccionauta | «¡Nadie me tumba! Soy el rey de la... ay, una pelusita... A... a... ¡ACHÚU!» | grandioso; estornudo enorme | 5,5 s | Gag `estornudo`: un calcetín le queda de sombrero | casera (papá) |
| arcoiris_batalla_torre_derrota_2_coco_risa | Coco | «¡Jajaja! ¡Le quedó un calcetín de sombrero!» | muerta de la risa | 2,5 s | Después del gag 2 | TTS |
| arcoiris_batalla_torre_derrota_3_coleccionauta | Coleccionauta | «¡Gané, gané! ¡Ningún globo me alcan...» *(1 s de silencio)* «...zó. ¿De dónde salió ese?» | triunfal; después, muy digno. **Papá deja el silencio** | 5 s | Gag `globo_que_vuelve` | casera (papá) |
| arcoiris_batalla_torre_derrota_3_coco_risa | Coco | «¡Jajaja! ¡Ese globo subió tan alto que volvió solito!» | sorprendida y feliz | 3 s | Después del gag 3 | TTS |
| arcoiris_batalla_torre_derrota_4_coleccionauta | Coleccionauta | «¡Me salvé! Esto merece un chicle de premio... fffff... ¡PLOP!» | goloso | 5 s | Gag `chicle` | casera (papá) |
| arcoiris_batalla_torre_derrota_4_coco_risa | Coco | «¡Jajaja! ¡Ahora es rosado chicle, como yo!» | riéndose, se pone rosado chicle (tic) | 2,5 s | Después del gag 4 | TTS |
| arcoiris_batalla_torre_rearma_01 | Coleccionauta | «¡A rearmar! Caja, frasco, caja... ¡y yo arriba! Uf.» | alegre y cansadito | 3,5 s | `rival_rearma` (alternadas) | casera (papá) |
| arcoiris_batalla_torre_rearma_02 | Coleccionauta | «Bueno, bueno... para arriba de nuevo. ¡Hep!» | resignado alegre | 2,5 s | Variante | casera (papá) |

### T.8 Logro común (Cometa)

`logro_comun`: piezas botadas en el intento contra `total_piezas` (28). `"1"` = menos de la mitad; `"2"` =
la mitad o más. Las piezas que no se rearman quedan en el suelo (ficha §10.2). Con 0 (no debería pasar,
siempre empieza Maxi), suena `nucleo_equipo_nos_alcanzo`.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| nucleo_equipo_cajas_botadas_01 | Cometa | «¡Igual botamos cajas, y algunas ya no suben! ¡Vamos de nuevo, equipo!» | orgulloso, animando | 4 s | `logro_comun["1"]` | TTS |
| nucleo_equipo_cajas_botadas_02 | Cometa | «¡Igual botamos un montón de cajas, y algunas ya no suben! ¡Vamos de nuevo, equipo!» | ídem, más grande | 4,5 s | `logro_comun["2"]` | TTS |

### T.9 Revancha (ficha §11)

**v4**: con dos hermanos la revancha se juega igual (mini fiesta y caída), pero **no suenan** las
`estrellitas_*`, ni `torre_record` ni `primer_record`: así no hay un récord de "Sofía y Maxi" contra uno
de "Nicole y Maxi". `intro_revancha` sirve tal cual con dos o con tres.

**v4, salida de la revancha (storyboard v4 §14): sin línea nueva, a propósito.** La revancha ya cierra con
voz: `cae_risa` en la mini fiesta y, con los tres, las estrellitas o el récord. Una línea más alargaría
un final que debe ser corto, y con dos hermanos no hace falta compensar: sin estrellitas no hay nada que
comparar. El Coleccionauta saludando desde el charco en el iris basta.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_intro_revancha | Cometa | «¡La Torre otra vez! ¿La botamos con globos de sobra?» | desafío alegre | 3 s | `intro_revancha`, antes de la intro corta | TTS |
| nucleo_equipo_lanzar_estrellitas_1 | Cometa | «¡La bajamos! ¡Una estrellita para el equipo!» | fiesta | 2,5 s | `estrellitas_equipo["1"]` | TTS |
| nucleo_equipo_lanzar_estrellitas_2 | Cometa | «¡A la primera! ¡Dos estrellitas para el equipo!» | fiesta grande | 2,5 s | `estrellitas_equipo["2"]` | TTS |
| nucleo_equipo_lanzar_estrellitas_3 | Cometa | «¡A la primera y con globos de sobra! ¡Tres estrellitas!» | la fiesta más grande | 3 s | `estrellitas_equipo["3"]` | TTS |
| arcoiris_batalla_torre_record | Coco | «¡Nuevo récord del equipo! ¡Nos sobraron más globos que nunca!» | orgullosa, moviendo la banderita de la canasta | 3,5 s | Récord batido en la revancha (clave propuesta `record_torre`). Reemplaza en la Torre a `arcoiris_emparejar_equipo_record`, que habla de la pista de galletas | TTS |

El primer récord reutiliza `arcoiris_emparejar_equipo_primer_record` («¡Su primer récord de equipo! Aquí
queda la banderita.»), que sirve tal cual.

---

## 1. Cae la torre (storyboard §4-§6)

La anticipación K1-K3 no tiene voz (el silencio de K2 es parte del diseño). En la caída: C1 `cae_lenta`
(con la **mochila en alto**: solo quiere salvarla) → C3 ¡SPLASH! → C5 `cae_charco` → C6 `cae_risa` (la fiesta
máxima) → directo a "antes del epílogo" (§2). **v4 (m11)**: se quitan F1 (`arcoiris_batalla_cierre_coco`)
y F2 (la fiesta de los tres) de este tramo. `cierre_coco` suena una sola vez, en A5. El tramo sin tocar,
desde el tiro ganador hasta el epílogo, queda en ≈ 19 s.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_torre_ups | Coleccionauta | «Ups.» | chiquitito, avergonzado | 0,5 s | `anticipacion`, **opcional**: K3, cuando se le resbala el dedo. Si el storyboard prefiere el silencio, no suena | casera (papá) |
| arcoiris_batalla_torre_cae_lenta | Coleccionauta | «¡Nooo... mi... mo-chi-laaa!» | **lento y grave, a propósito**, como cámara lenta; chistoso, nunca asustado | 2,5 s | C1: cae con la mochila en alto. *Cambia "torre" por "mochila" (PO 13-Oct); el mismo largo* | casera (papá) |
| arcoiris_batalla_torre_cae_charco | Coleccionauta | «¡Uf! ...¡Nunca había estado tan... colorido!» | asombrado, mirándose las manos de lunares, y después encantado | 3,5 s | C5 | casera (papá) |
| arcoiris_batalla_torre_cae_risa | Coleccionauta | «¡Jajá! ¡Parezco un arcoíris con antenas!» | se ríe de sí mismo, de verdad | 2,5 s | C6: de pie en el charco, chapotea | casera (papá) |

---

## 2. Le regalan colores (antes del epílogo y epílogo, storyboard §8)

`epilogo_mochila_gris` → `arcoiris_batalla_epilogo_antes_coco` («¡Ya sé! ¡Regalémosle colores!») → el
epílogo de siempre. **Total ≈ 3 + 0,15 + 1,8 = 4,95 s.** **v4 (decisión 7)**: el tope pasa a **≤ 6 s
medido con el audio real** (recortando los 0,5 s de silencio de los archivos). Si la toma de papá de
`mochila_gris` pasa de 3,8 s, se pide otra más rápida; no se agrega ninguna voz en este tramo. Para
el storyboard P1: «Yo, de colores...» se señala los lunares; «¿y mi mochila?» la levanta y la sacude (sale
la pelusa); «¡Gris!» la abraza, dramático.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_epilogo_mochila_gris | Coleccionauta | «Yo, de colores... ¿y mi mochila? ¡Gris!» | teleserie chistosa, nada triste | 3 s | P1. Reemplaza a `arcoiris_batalla_epilogo_antes_coleccionauta` | casera (papá) |

---

## 3. La despedida del Coleccionauta y el mapa (storyboard §9-§10)

A1-A3 reutilizadas (`cierre_mira`, `cierre_equipo`, `cierre_despedida`; en el tropiezo se le cae el mapa
y **sale sin darse cuenta**) → M1 Coco **atrapa el mapa con la lengua** (`mapa_coco`) → M4 plano detalle
(`mapa_cometa`) → M5 él, desde fuera de cuadro (`mapa_coleccionauta`) → M7 la nave con el ala envuelta
(`mapa_animalia`) → pausa natural (`pausa_partida`) → si salen, el hito de partida (`despegue_hito`).

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_cierre_mapa_coco | Coco | «¡Eh! ¡Se le cayó algo!» | curiosa; justo antes del "¡fiup!" de la lengua | 1,4 s | M1 | TTS |
| arcoiris_batalla_cierre_mapa_cometa | Cometa | «¡Un mapa estelar! Y tiene una flechita... ¡hacia Animalia!» | como un mapa del tesoro; "Animalia" con el latido de la huellita | 3,5 s | M4 | TTS |
| arcoiris_batalla_cierre_mapa_coleccionauta | Coleccionauta | «¡Mi mapa! ...Bah, me sé el camino de memoria. ¡Creo!» | gritando de lejos; despreocupado y después dudoso | 3,5 s | M5, fuera de cuadro y con eco | casera (papá) |
| arcoiris_batalla_cierre_mapa_animalia | Cometa | «¡Animalia, el planeta de los animales! Para llegar allá... ¡hay que dejar la nave lista!» | ilusionado; invita a trabajar juntos, sin apuro | 4,5 s | M7 | TTS |
| arcoiris_batalla_cierre_pausa_partida | Coco | «¿Preparamos la nave ahora... o descansamos y volvemos después?» | tranquila, ofrece las dos | 3,5 s | Pausa natural entre bloques (storyboard v4 §8.1; aprobada por delegación del PO). No avanza sola | TTS |
| arcoiris_despegue_hito | Cometa | «¡La nave nos espera para el gran viaje! ¿Vamos, equipo?» *(v4, M8)* | invitación alegre, nunca pendiente | 2,8 s | Hito de partida en el mapa del planeta (máx. una vez por visita, M7.3). **v4**: ya no dice «¿vienen los tres?», que con dos hermanos y el retrato del tercero sonaba a condición y dejaba "afuera" al que no estaba | TTS |

---

## 4. La gran partida: preparativos (storyboard v4 §8.2 y §9)

**v4**: los planos de este §4 usan la numeración del storyboard v4: entrada §8.2; Maxi MX1-MX4 (§9.3);
Nicole NI0-NI5 (§9.4); Sofía SO0-SO6 (§9.5). Solo cambian los nombres de plano, no los textos.

Modo sin puerta, orden Maxi → Nicole → Sofía, con `nucleo_equipo_ahora_<hermano>` entre tareas. Misma
estructura para los tres: instrucción (Cometa; tocarlo la repite) → el trabajo (Coco en cada toque) →
momento especial → «¡… listo! ¡Gracias, (nombre)!» → gesto canon. Recordatorios: `_recuerda_01`
(Cometa, 8 s), `_recuerda_02` (Coco, 16 s, con pista visual) y `_ayuda` (Coco, 24 s; Maxi y Nicole).
Ruta: `voces/arcoiris/despegue/`.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_despegue_intro | Cometa | «¡A preparar la nave! Cada uno tiene un trabajo importante.» | entusiasmado, de capitán | 3,5 s | Entrada (storyboard v4 §8.2) | TTS |

### 4.1 Maxi llena el tanque (6 toques, 3 colores)

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_despegue_tanque_instruccion | Cometa | «¡Maxi, toca la manguera y llena el tanque!» | lento, cálido | 2,5 s | MX1 | TTS |
| arcoiris_despegue_tanque_color_rojo | Coco | «¡Rojo!» | alegre, clarito | 0,7 s | Toque 1 | TTS |
| arcoiris_despegue_tanque_color_amarillo | Coco | «¡Amarillo!» | ídem | 0,8 s | Toque 2 | TTS |
| arcoiris_despegue_tanque_color_azul | Coco | «¡Azul!» | ídem | 0,7 s | Toque 3 | TTS |
| arcoiris_despegue_tanque_glu | Coco | «¡Glu, glu, glu! ¡A la nave le gusta!» | riéndose | 2 s | Toque 4 (la mitad); los toques 5 y 6, sin voz | TTS |
| arcoiris_despegue_tanque_lleno | Coco | «¡Blup! ¡Tanque lleno... y hace burbujas!» | sorpresa feliz | 2,2 s | MX3 | TTS |
| arcoiris_despegue_tanque_gracias | Cometa | «¡Tanque listo! ¡Gracias, Maxi!» | fiesta, del mismo tamaño que las otras | 1,8 s | MX4 | TTS |
| arcoiris_despegue_tanque_recuerda_01 | Cometa | «¡Maxi, la manguera te espera! Toca, toca.» | cariñoso | 2,3 s | 8 s | TTS |
| arcoiris_despegue_tanque_recuerda_02 | Coco | «¡Mira, Maxi! ¡La manguera está bailando!» | maravillada | 2 s | 16 s: la manguera baila | TTS |
| arcoiris_despegue_tanque_ayuda | Coco | «¡Lo hacemos juntos, Maxi! Toca conmigo.» | de dupla | 2,2 s | 24 s: la mano de Coco toca al ritmo | TTS |

### 4.2 Nicole gira los broches del ala (3 broches)

NI0: Coco desenvuelve el ala y la encaja (sin voz; `nucleo_equipo_ahora_nicole`). Aparecen **3 broches
dorados** (manda el guion: el storyboard v2 dibujó 5, y lo ajusta el director). Ninguna voz dice "tu ala".

**v4 (m10)**: se mantiene que **Coco encaja el ala**. Cada broche dorado lleva una piedrita de color (rojo,
amarillo y azul, los colores recuperados). Coco pide uno a la vez (`broches_pide_<color>`); si Nicole
toca otro, ese broche se menea sin voz y no pasa nada más. Sin fallo. Al girar el pedido suena el
`broche_<n>` que toca en la cuenta.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_despegue_broches_instruccion | Cometa | «¡Nicole, gira los broches dorados! Coco te dice cuál.» *(v4, m10)* | claro, alegre | 3 s | NI1 | TTS |
| arcoiris_despegue_broches_pide_rojo **[v4]** | Coco | «¡El broche rojo!» | juguetona, como en un juego de búsqueda | 1,2 s | Primer pedido | TTS |
| arcoiris_despegue_broches_pide_amarillo **[v4]** | Coco | «¡Ahora, el amarillo!» | ídem | 1,3 s | Segundo pedido | TTS |
| arcoiris_despegue_broches_pide_azul **[v4]** | Coco | «¡Y el último... el azul!» | ídem, con suspenso chiquito | 1,6 s | Tercer pedido | TTS |
| arcoiris_despegue_broche_1 | Coco | «¡Uno!» | contando con fiesta, después del "cric-cric" | 0,6 s | NI2, primer broche (en el orden de los toques) | TTS |
| arcoiris_despegue_broche_2 | Coco | «¡Dos!» | ídem | 0,6 s | Segundo | TTS |
| arcoiris_despegue_broche_3 | Coco | «¡Tres!» | el más grande | 0,6 s | Tercero | TTS |
| arcoiris_despegue_broches_ala | Coco | «¡Upa! Mi ala, en su nave... ¡Ahora soy rosado de emoción!» | "¡upa!" enderezando la nave con la cola; después, emocionada, con las manos al pecho (tic) | 3,8 s | NI4, después de `arcoiris_009` (NI3: **la nave aletea chueca**) | TTS |
| arcoiris_despegue_broches_gracias | Cometa | «¡Ala lista! ¡Gracias, Nicole!» | fiesta, igual que las otras | 1,8 s | NI5 | TTS |
| arcoiris_despegue_broches_recuerda_01 | Cometa | «¡Nicole, los broches brillan para ti!» | cariñoso | 2 s | 8 s | TTS |
| arcoiris_despegue_broches_recuerda_02 | Coco | «¡Psst, Nicole! ¡Este broche quiere su vuelta!» | en secreto | 2,4 s | 16 s: un broche salta y crece | TTS |
| arcoiris_despegue_broches_ayuda | Coco | «¡Te ayudo, Nicole! Tú tocas, yo sujeto.» | de dupla | 2,3 s | 24 s: Coco sujeta el ala | TTS |

### 4.3 Sofía traza la ruta: A-N-I-M-A-L-I-A

8 estrellas con letras y 5 señuelos (sin voz al equivocarse). La pista ya no es de números: después de 2
toques equivocados seguidos, o al tocar a Cometa tras la instrucción, suena la letra que sigue
(`ruta_sigue_<letra>`). **v4 (m9)**: la pista suena **siempre junto con el latido** de la estrella
correcta; si no, con tres A en pantalla, la voz sola no ayuda.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_despegue_ruta_instruccion | Cometa | «¡Sofía, traza la ruta! Une las estrellas que dicen... ¡A-ni-ma-lia!» | de reto, de capitán a capitana; por sílabas | 4 s | SO1 | TTS |
| arcoiris_despegue_ruta_sigue_a | Cometa | «Busca la... ¡A!» | cómplice | 1,3 s | Pista: sigue una A | TTS |
| arcoiris_despegue_ruta_sigue_n | Cometa | «Busca la... ¡N!» | ídem | 1,3 s | Sigue la N | TTS |
| arcoiris_despegue_ruta_sigue_i | Cometa | «Busca la... ¡I!» | ídem | 1,3 s | Sigue una I | TTS |
| arcoiris_despegue_ruta_sigue_m | Cometa | «Busca la... ¡M!» | ídem | 1,3 s | Sigue la M | TTS |
| arcoiris_despegue_ruta_sigue_l | Cometa | «Busca la... ¡L!» | ídem | 1,3 s | Sigue la L | TTS |
| arcoiris_despegue_ruta_dato | Cometa | «¿Sabías? Hace mucho tiempo, los marineros cruzaban el mar guiándose por las estrellas. ¡Como tú!» | dato curioso, con admiración | 5 s | Una vez, después de la 4.ª estrella, sin cortar el juego | TTS |
| arcoiris_despegue_ruta_forma | Coco | «¡Miren la ruta! Tiene forma de... ¿perrito?» | asombrada, pícara | 3 s | SO3: la constelación se vuelve perrito (después ladra, SFX) | TTS |
| arcoiris_despegue_ruta_animalia | Cometa | «¡A-NI-MA-LIA!» | letra por letra, con la palabra que se ilumina | 2 s | SO4 | TTS |
| arcoiris_despegue_ruta_gracias | Cometa | «¡Ruta lista! ¡Gracias, Sofía!» | fiesta, igual que las otras | 1,8 s | SO5 | TTS |
| arcoiris_despegue_ruta_recuerda_01 | Cometa | «¡Sofía, las estrellas esperan a su capitana!» | cálido, le da el rol de líder | 2,5 s | 8 s | TTS |
| arcoiris_despegue_ruta_recuerda_02 | Coco | «¡Psst, Sofía! La estrella que sigue te está guiñando.» | cómplice | 2,8 s | 16 s: la estrella siguiente guiña | TTS |

---

## 5. Coco se despide de cada hermano (storyboard §12)

D2 `coco_regalo_<hermano>` (termina en «¡Choca esos cinco!») → D3 choque → `coco_choca_<hermano>` (Coco
toma el color del traje). Sin toque: `coco_choca_recuerda` a los 8 s; a los 20 s Coco choca la manito ella
misma y suena igual `coco_choca_<hermano>`. D5 álbum de abrazos, sin voz → D6 `coco_cierre` → D7 `hangar`.

**Regalos aprobados por el PO**: misma estructura y mismo largo, y cada uno nombra el trabajo del hermano.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_despegue_coco_regalo_maxi | Coco | «Maxi, para ti: un tiranosaurio de gomita... ¡por llenar el tanque! ¡Choca esos cinco!» | tierna; un "grrr" chiquito en tiranosaurio | 5 s | D2 | TTS |
| arcoiris_despegue_coco_regalo_nicole | Coco | «Nicole, para ti: un corazón rosado chicle... ¡por girar los broches! ¡Choca esos cinco!» | tierna; el corazón como su gesto | 5 s | D2 | TTS |
| arcoiris_despegue_coco_regalo_sofia | Coco | «Sofía, para ti: un pony turquesa con crin de arcoíris... ¡por trazar la ruta! ¡Choca esos cinco!» | tierna, igual de grande | 5,5 s | D2 | TTS |
| arcoiris_despegue_coco_choca_maxi | Coco | «¡Pa! Ahora soy... ¡azul Maxi!» | fiesta; pausa antes del color (tic) | 2 s | D3 (`#4aa8ff`) | TTS |
| arcoiris_despegue_coco_choca_nicole | Coco | «¡Pa! Ahora soy... ¡rosado Nicole!» | ídem | 2 s | D3 (`#ff5fae`) | TTS |
| arcoiris_despegue_coco_choca_sofia | Coco | «¡Pa! Ahora soy... ¡turquesa Sofía!» | ídem | 2 s | D3 (`#4fd8e0`) | TTS |
| arcoiris_despegue_coco_choca_recuerda | Coco | «¡Mi manito te espera! ¡Choca!» | juguetona | 1,8 s | 8 s sin toque | TTS |
| arcoiris_despegue_coco_cierre | Coco | «¡No es chao, es hasta pronto! Y cada vez que vean un arcoíris... ¡soy yo, saludándolos!» | cálida, nada triste; el final en secreto | 5,5 s | D6 | TTS |
| arcoiris_despegue_hangar | Cometa | «¡Los regalos de Coco ya están en el hangar!» | contento | 2,5 s | D7 | TTS |

`arcoiris_017` no se repite: se queda en la escena del ala.

---

## 6. La foto y la video-llamada de papá (storyboard §13)

V1 `arcoiris_batalla_cierre_foto` → V2 la foto con su audio familiar → V3 `arcoiris_010` → V5
`arcoiris_batalla_cierre_papa_01` → V6 `papa_pista` → V7 `papa_guatita` → V8 `arcoiris_batalla_cierre_papa_03`.
`papa_02` queda retirada: el Coleccionauta va a Animalia, no a la casa de papá.

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_batalla_cierre_papa_pista | Papá | «Oigan, recién me llamó el Coleccionauta, todo contento y pintado. ¡Va camino a Animalia! Y de fondo se oían ladridos... y algo así como... ¡GRRR! ¿Rugidos?» | chisme tranquilo; el "¡GRRR!" chistoso, nunca de miedo; "¿rugidos?" con las cejas arriba | 9 s | V6 | familiar (papá) |
| arcoiris_batalla_cierre_papa_guatita | Papá | «...¿O sería mi guatita, que ya quiere once? ¡Jajá!» | chiste de papá, sobándose la guata | 3,5 s | V7 | familiar (papá) |

---

## 7. Cuenta regresiva, despegue y Mapa Estelar (storyboard §14-§15)

**Cuenta** (v4: decidida por delegación del PO): brilla **un retrato a la vez**, Sofía (3) → Nicole (2)
→ Maxi (1); el de Maxi mide ≥ 200 px. `cuenta_motores` enciende la nave. Sin toque, `cuenta_recuerda` a
los 8 s; el retrato salta solo **a los 20 s** en las hermanas y **a los 15 s** en Maxi. Un toque a un
retrato que no brilla lo hace saltar y reír, sin voz, sin "bup" y sin avanzar. No se usa
`nucleo_equipo_despegar` (cuenta sola). Con dos hermanos, el retrato del que falta se toca igual (lo toca
cualquiera, o salta solo): ninguna voz lo nombra como ausente.

**Despegue** (DS1): se quita el «¿Rugidos?» que pedía revisar el storyboard: llegaba ≈ 12 s después de la
llamada, con la cuenta de por medio. Puente de 3 bandas (DS3) → rampa (DS4, SFX sin voz) → Coco abajo
(DS5).

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_despegue_cuenta_instruccion | Cometa | «¡Todo listo! Cuenta regresiva: cuando brille tu carita, ¡tócala!» | emoción de lanzamiento | 3,5 s | CR0 | TTS |
| arcoiris_despegue_cuenta_tres | Cometa | «¡Tres!» | grande | 0,6 s | CR1 | TTS |
| arcoiris_despegue_cuenta_dos | Cometa | «¡Dos!» | más grande | 0,6 s | CR2 | TTS |
| arcoiris_despegue_cuenta_uno | Cometa | «¡Uno!» | el más grande | 0,6 s | CR3 | TTS |
| arcoiris_despegue_cuenta_motores | Cometa | «¡Motores encendidos! Brrrum...» | fiesta; el "brrrum" para Maxi | 2,2 s | CR4 | TTS |
| arcoiris_despegue_cuenta_recuerda | Cometa | «¡Tu carita está brillando! ¡Tócala!» | cariñoso | 2 s | 8 s | TTS |
| arcoiris_despegue_cuenta_tres_sofia | Sofía | «¡Tres!» | como le salga | 0,6 s | Opcional, en vez de `cuenta_tres` | niños (opcional) |
| arcoiris_despegue_cuenta_dos_nicole | Nicole | «¡Dos!» | como le salga | 0,6 s | Opcional | niños (opcional) |
| arcoiris_despegue_cuenta_uno_maxi | Maxi | «¡Uno!» | como le salga | 0,6 s | Opcional | niños (opcional) |
| arcoiris_despegue_vuelo_despegue | Cometa | «¡Cinturones puestos... y despegue!» | el "¡despegue!" largo, para Maxi | 2,5 s | DS1 (antes: 4,5 s con «¿Rugidos?»; ahora sobran 2 s de aire) | TTS |
| arcoiris_despegue_vuelo_puente | Cometa | «¡Wiiii! ¡Por el puente arcoíris!» | como en un tobogán | 2,2 s | DS3, en la cima | TTS |
| arcoiris_despegue_vuelo_coco_chao | Coco | «¡Buen viaje! Ahora soy... ¡color buen viaje!» | gritando desde abajo, feliz; inventa un color (tic) | 3 s | DS5 | TTS |
| arcoiris_despegue_vuelo_lejitos | Cometa | «¡Rumbo a Animalia! Está lejitos... la nave va volando despacito, despacito.» | ilusionado y tranquilo, sin pena | 4,5 s | ME3, **rama A** (sin capítulo 2): la nave avanza al 25 % y queda "en camino" | TTS |
| arcoiris_despegue_vuelo_celebra | Cometa | «¡Primer planeta, listo! ¡Hermanos Estelares!» | la fiesta más grande | 2,5 s | **v4**: ME5 (storyboard v4 §13.2), fuegos y gestos canon, **en las dos ramas**. En la rama B suena después de `vuelo_rumbo_animalia`; el texto sirve tal cual porque no habla del viaje. Tras la llave de padres, ME5 va sin voz (ya se celebró antes) | TTS |
| arcoiris_despegue_vuelo_rumbo_animalia | Cometa | «¡Próxima parada: Animalia! ¡Cuando quieran, partimos!» | de aventura, sin apurar | 3 s | ME3-B, **rama B**. No dice "llegamos": el viaje no se encadena (storyboard, duda 4) | TTS |
| arcoiris_despegue_mapa_animalia_lejitos | Cometa | «Animalia todavía está lejitos. ¡Pero la nave ya va en camino!» | tranquilo, ilusionando | 3 s | Tocar Animalia en el Mapa Estelar mientras no exista el capítulo 2 | TTS |
| arcoiris_despegue_vuelo_de_vuelta **[v4]** | Cometa | «¡Nave lista y con ala nueva! ¡De vuelta a Animalia!» | contento, de reencuentro; nada de "por fin" | 3 s | **m8**: cierre del despegue cuando la familia ya había viajado a Animalia con la llave de padres. Reemplaza a `vuelo_rumbo_animalia`; sin rama del Mapa Estelar | TTS |
| arcoiris_despegue_mapa_animalia_antes_01 **[v4]** | Cometa | «¡Animalia! ¿Oyeron ese "guau"? Primero dejamos la nave lista... ¡y después vamos!» | intriga feliz, como contando un secreto; el "guau" chiquito | 4 s | **M9**: tocar Animalia en el Mapa Estelar **antes de la partida**. Animalia se ve lejana y desenfocada, sin candado; late en < 100 ms al tocarla y una flechita lleva a Arcoíris. Máx. una vez por visita (alterna con `_02`); los demás toques, solo el latido | TTS |
| arcoiris_despegue_mapa_animalia_antes_02 **[v4]** | Cometa | «¡Shhh! Animalia está durmiendo la siesta. Cuando la nave esté lista... ¡la despertamos!» | susurrando, pícaro; el final en voz normal | 4,5 s | **M9**, variante para otra visita | TTS |

---

## 8. Escena del ala (zona 3): `arcoiris_009` se mueve

`arcoiris_009` («¡La primera pieza! Miren cómo le queda a la nave.») **se mueve tal cual** (mismo texto y
mismo archivo) a NI3 de los preparativos. En el Beat 2 la reemplazan dos líneas, según el estado familiar
(`partida_hecha`, ficha §13.4):

| id | personaje | texto | intención | duración | contexto | grabación |
|---|---|---|---|---|---|---|
| arcoiris_009a | Cometa | «¡La primera pieza! La guardamos con cariño... y la ponemos todos juntos antes del gran viaje.» | entusiasta, de promesa | 5 s | Beat 2, si `partida_hecha` es `false`: el ala queda envuelta junto a la nave | TTS |
| arcoiris_009b | Cometa | «¡La primera pieza! La nave ya lleva su ala... ¡y este pedacito de brillo lo ganaste tú!» *(v4, M8.4)* | orgulloso; "tú" con cariño, la misma fiesta que `009a` | 4,5 s | Beat 2, si `partida_hecha` es `true` (el hermano llega a su zona 3 después de la ceremonia, por ejemplo porque la partida se jugó con dos y su retrato). **v4**: sin "también" ni "ahora": no dice que otro llegó antes ni que él faltó. Celebración del mismo tamaño que `009a` (el ala destella, loop de la nave y su gesto canon: storyboard v4) | TTS |

---

## 9. Reutilizadas, retiradas y descartadas

### 9.1 Se reutilizan (mismo texto y mismo archivo)

| ids | dónde |
|---|---|
| `arcoiris_batalla_livianita_3` | Antes de la presentación de la Torre |
| `nucleo_equipo_le_toca_<hermano>_01..03` (9), `te_toca_<hermano>` (3), `maxi_ayuda`, `sube_ventanita_nicole/sofia` y `te_toca_nicole/sofia_ventanita` (4) | Puerta y pase de la Torre (17) |
| `arcoiris_emparejar_equipo_porras_fin_maxi`, `arcoiris_equipo_maxi_regalito`, `arcoiris_batalla_rio_justo_ahi_01/02` (2), `nucleo_equipo_nos_alcanzo` | Torre (5) |
| `nucleo_equipo_ahora_maxi/nicole/sofia` (3) | Ventanitas del gigante (variante B), epílogo y preparativos |
| `arcoiris_batalla_cierre_coco` + `nucleo_equipo_al_frente`, `choca`, `equipo_estelar`, `destellos` + `fiesta_<hermano>` (3, niños) | Fiesta de la victoria (8). **v4 (m11)**: ya no suenan entre la caída y el epílogo; `cierre_coco` queda solo en A5 y el storyboard v4 decide si el resto va después del epílogo o sale |
| `arcoiris_batalla_epilogo_antes_coco`, `maxi_ven`, `nucleo_equipo_epilogo_repetir`, `parte_coco_01..03`, `parte_coleccionauta_1..3`, `tapa`, `regalo_<hermano>` (3, niños) | Epílogo (13) |
| `arcoiris_batalla_cierre_mira`, `cierre_equipo`, `cierre_despedida` | Despedida (3) |
| `nucleo_batalla_todos_nave_corta`, `falta_uno`, `nucleo_equipo_sube_nave_<hermano>` (3), `yo_tambien_<hermano>` (3, niños) | Retomar la partida (8) |
| `arcoiris_009` | **Movida** a NI3 |
| `arcoiris_batalla_cierre_foto`, `arcoiris_010`, `arcoiris_batalla_cierre_papa_01`, `_03` | Foto y llamada (4) |
| `arcoiris_emparejar_equipo_primer_record` | Primer récord de la revancha |
| `nucleo_equipo_presenta` | Próxima selección |

**Total: 65** (1 + 17 + 5 + 3 + 8 + 13 + 3 + 8 + 1 + 4 + 1 + 1).

### 9.2 Retiradas

| id | motivo |
|---|---|
| `arcoiris_batalla_epilogo_antes_coleccionauta` | La reemplaza `epilogo_mochila_gris` |
| `arcoiris_batalla_cierre_papa_02` | Él va a Animalia, no a la casa de papá |
| `nucleo_equipo_coleccionauta_vuelve` (solo en la Torre) | Lo reemplazan `rearma_01/02` |
| `arcoiris_emparejar_equipo_record` (solo en la Torre) | Habla de la pista de galletas; lo reemplaza `torre_record` |
| `arcoiris_despegue_coco_espera` | Con la cuenta al final, Coco ya se despidió (storyboard §14.1) |
| `arcoiris_despegue_ruta_pista` | Ya no hay números: la reemplazan `ruta_sigue_<letra>` |
| Los colores `naranjo`, `verde`, `morado` y `rosado` del tanque | Solo los 3 recuperados (puente de 3 bandas) |
| `arcoiris_despegue_tuercas_*` y `tornillo_*` | Pasan a `broches_*` y `broche_1..3` (3 broches) |

---

## 10. Equivalencias para Dev y para el storyboard

| storyboard v2 / ficha v2 | id de la v3 |
|---|---|
| `arcoiris_despegue_tuercas_instruccion` | `arcoiris_despegue_broches_instruccion` |
| `arcoiris_despegue_tornillo_1..5` | `arcoiris_despegue_broche_1..3` (**3 broches**) |
| `arcoiris_despegue_tuercas_ala`, `_gracias`, `_recuerda_01/02`, `_ayuda` | `arcoiris_despegue_broches_ala`, `_gracias`, `_recuerda_01/02`, `_ayuda` |
| `arcoiris_despegue_ruta_pista` | `arcoiris_despegue_ruta_sigue_a/n/i/m/l` |
| SO4, lectura «¡A-NI-MA-LIA!» | `arcoiris_despegue_ruta_animalia` |
| Pausa entre bloques (storyboard v4 §8.1) | `arcoiris_batalla_cierre_pausa_partida` |
| Hito de partida | `arcoiris_despegue_hito` |
| F3 «¡no lo necesitamos!» | `arcoiris_batalla_torre_no_lo_necesitamos` (solo variante B) |
| Pausa antes de la Torre (ficha §18.3) | `arcoiris_batalla_torre_pausa_antes` |
| Ficha `anticipacion` | `arcoiris_batalla_torre_ups` (opcional) |
| Ficha `gigante_turno_maxi` | `arcoiris_batalla_torre_gigante_turno_maxi` |
| Ficha `justo_ahi_maxi` | `arcoiris_batalla_rio_justo_ahi_01/02` (reutilizadas) |
| Ficha `elige_globo_presenta`, `toca_en_el_aire`, `encontre_globos` | `torre_globos_especiales`, `torre_toca_en_el_aire`, `torre_encontre_globos` |
| Ficha `intro_revancha`, `estrellitas_equipo` | `torre_intro_revancha`, `nucleo_equipo_lanzar_estrellitas_1..3` |
| Récord de la revancha | `torre_record` (clave propuesta `record_torre`) + `arcoiris_emparejar_equipo_primer_record` |

**v4, nuevos ids para el storyboard v4**:

| momento | clave o nombre en `motor-lanzar.md` v3 | id |
|---|---|---|
| Primer tiro de cada hermana (M1), después de `carga`, con la manito fantasma | `explica_tiro` | `nucleo_equipo_lanzar_primer_tiro` |
| Pedidos de los broches por color (m10) | §13.5 | `arcoiris_despegue_broches_pide_rojo/amarillo/azul` |
| Tocar Animalia antes de la partida (M9) | `mapa_animalia_espera` / `voz_destino_espera` (§13.4) | `arcoiris_despegue_mapa_animalia_antes_01/02` (dos variantes, una por visita; reemplazan el texto provisorio de la ficha) |
| Despegue después de haber usado la llave de padres (m8) | `despegue_de_vuelta` | `arcoiris_despegue_vuelo_de_vuelta` |
| Color solo en `carga` desde la 2.ª vez (m3) | `carga_corta` | `arcoiris_despegue_tanque_color_<color>` (reutilizadas) |
| Último globo, siempre de Maxi | `ultimo_globo` | `arcoiris_batalla_torre_ultimo_globo` (le habla a Maxi y reemplaza a `maxi_carga` en ese turno) |
| `ayuda_2` de la revancha `nicole+sofia` (+2) | `composiciones` (§11.1) | `arcoiris_batalla_torre_encontre_globos` (reutilizada) |

**Para el director** (el guion manda en esto): **3 broches** (no 5), los regalos aprobados (T-rex de
gomita, corazón rosado chicle y pony turquesa), `009a`/`009b`, nada de "tornillos" ni de "contar de dos
en dos", `cae_lenta` dice "mochila", "antes del epílogo" baja a ≈ 4,95 s y `vuelo_despegue`, a 2,5 s.

---

## 11. Lo que queda abierto

**[PO]**:

1. ~~El globo gigante~~: **cerrado en la v4** (variante A, por delegación del PO).
2. ~~El orden de la cuenta regresiva~~: **cerrado en la v4** (Sofía → Nicole → Maxi, uno a la vez). Sigue
   abierto **si se graba a los niños**.
3. ~~La pausa natural entre la victoria y la partida~~: **cerrada** (aprobada por delegación del PO;
   storyboard v4 §8.1, con `pausa_partida`).

Ya no queda ningún [CONCILIAR] con `motor-lanzar.md`.

---

## 12. Guion de grabación casera (para papá)

`.wav`, sin eco, con 0,5 s de silencio antes y después. Registro del Coleccionauta:
**grandilocuente-tonto, nunca de malo**. Para los gags, mejor tres tomas y elegir la más chistosa.

| # | id | texto | intención | dónde |
|---|---|---|---|---|
| 1 | arcoiris_batalla_torre_presenta_coleccionauta | «¡Caja, frasco, caja... ¡y yo arriba!» | apurado y feliz, ≤ 2,5 s | Arma la torre |
| 2 | arcoiris_batalla_torre_presenta_alcanzo | «¡Si el arcoíris no cabe en mi mochila... me lo llevo de la mano!» | travieso, ≤ 3 s | Se estira hacia el arcoíris |
| 3 | arcoiris_batalla_torre_intro_coleccionauta | «¡Torrecita!» | cariñoso, ≤ 1 s | Cada intento |
| 4 | arcoiris_batalla_torre_reacciona_01 | «¡Uy, uy, uy! ¡Quieta, torrecita, quieta!» | haciendo equilibrio | El trono se inclina |
| 5 | arcoiris_batalla_torre_reacciona_02 | «¡Ay, mi caja de calcetines sin pareja!» | teleserie | Cae una caja |
| 6 | arcoiris_batalla_torre_reacciona_03 | «¡No me hace nada! ...Bueno, unas cosquillitas.» | valiente de mentira | Le salpica |
| 7 | arcoiris_batalla_torre_gigante_coleccionauta | «¿Y ese globo tan grande? ¡Eso no es justo! ...Bueno, sí es justo.» | indignado y después honesto | Aparece el gigante |
| 8 | arcoiris_batalla_torre_derrota_1_coleccionauta | «¡Sigo arriba! ¡Baile de la torre! Un pasito pa'cá...» *(¡plof!)* «...¿Por qué llueve rosado?» **(v4)** | fiestero; **cortar en "pa'cá"** y quedar desconcertado; ≤ 4 s | Gag 1 |
| 9 | arcoiris_batalla_torre_derrota_2_coleccionauta | «¡Nadie me tumba! Soy el rey de la... ay, una pelusita... A... a... ¡ACHÚU!» | estornudo enorme | Gag 2 |
| 10 | arcoiris_batalla_torre_derrota_3_coleccionauta | «¡Gané, gané! ¡Ningún globo me alcan...» *(1 s de silencio)* «...zó. ¿De dónde salió ese?» | **dejar el silencio** | Gag 3 |
| 11 | arcoiris_batalla_torre_derrota_4_coleccionauta | «¡Me salvé! Esto merece un chicle de premio... fffff... ¡PLOP!» | goloso | Gag 4 |
| 12 | arcoiris_batalla_torre_rearma_01 | «¡A rearmar! Caja, frasco, caja... ¡y yo arriba! Uf.» | alegre y cansadito | Rearma |
| 13 | arcoiris_batalla_torre_rearma_02 | «Bueno, bueno... para arriba de nuevo. ¡Hep!» | resignado alegre | Rearma |
| 14 | arcoiris_batalla_torre_ups | «Ups.» | chiquitito, ≤ 0,5 s (opcional) | Anticipación |
| 15 | arcoiris_batalla_torre_cae_lenta | «¡Nooo... mi... mo-chi-laaa!» | **lento y grave** | Cae con la mochila en alto |
| 16 | arcoiris_batalla_torre_cae_charco | «¡Uf! ...¡Nunca había estado tan... colorido!» | asombrado y encantado | En el charco |
| 17 | arcoiris_batalla_torre_cae_risa | «¡Jajá! ¡Parezco un arcoíris con antenas!» | se ríe de sí mismo | De pie en el charco |
| 18 | arcoiris_batalla_epilogo_mochila_gris | «Yo, de colores... ¿y mi mochila? ¡Gris!» | teleserie, **≤ 3 s** (máximo 3,8 s: el tramo completo no pasa de 6 s) | Antes del epílogo |
| 19 | arcoiris_batalla_cierre_mapa_coleccionauta | «¡Mi mapa! ...Bah, me sé el camino de memoria. ¡Creo!» | gritando de lejos | Se le cayó el mapa |
| 20 | arcoiris_batalla_cierre_papa_pista (papá) | «Oigan, recién me llamó el Coleccionauta, todo contento y pintado. ¡Va camino a Animalia! Y de fondo se oían ladridos... y algo así como... ¡GRRR! ¿Rugidos?» | chisme tranquilo; "¡GRRR!" chistoso | Llamada |
| 21 | arcoiris_batalla_cierre_papa_guatita (papá) | «...¿O sería mi guatita, que ya quiere once? ¡Jajá!» | chiste de papá | Llamada |

También por grabar, del guion de la batalla y ahora **obligatorias**: `papa_01` y `papa_03`; y `cierre_mira`,
`cierre_equipo`, `cierre_despedida`, `parte_coleccionauta_1..3` y `livianita_3`.

Opcionales de los niños (los tres o ninguno): «¡Tres!» (Sofía), «¡Dos!» (Nicole) y «¡Uno!» (Maxi).

---

## 13. Conteo

| bloque | Coco (TTS) | Cometa (TTS) | Coleccionauta (papá) | Papá (familiar) | niños (opc.) | total |
|---|---|---|---|---|---|---|
| T. Torre (con las dos variantes del gigante) | 35 | 10 | 13 | — | — | 58 |
| 1. Caída | — | — | 4 | — | — | 4 |
| 2. Epílogo | — | — | 1 | — | — | 1 |
| 3. Despedida y mapa | 2 | 3 | 1 | — | — | 6 |
| 4. Preparativos | 18 | 17 | — | — | — | 35 |
| 5. Despedida de Coco | 8 | 1 | — | — | — | 9 |
| 6. Llamada | — | — | — | 2 | — | 2 |
| 7. Cuenta, despegue y mapa | 1 | 15 | — | — | 3 | 19 |
| 8. Escena del ala | — | 2 | — | — | — | 2 |
| **Total escrito** | **64** | **48** | **19** | **2** | **3** | **136** |

- **TTS: 112 escritas** (v4: +7). Con la **variante A** adoptada se generan **107** (no se generan las 4
  de Coco y la 1 de Cometa de la B). Son ≈ 3.200 caracteres. **Antes de generar: `--estimar` y el OK del
  PO sobre el costo.** No se generó audio.
- **v4, TTS por generar o regenerar: 18** = 7 nuevas (`lanzar_primer_tiro`,
  `broches_pide_rojo/amarillo/azul`, `vuelo_de_vuelta`, `mapa_animalia_antes_01/02`) + 9 con texto
  cambiado (`lanzar_repetir_maxi`, `maxi_globo_01/02`, `gigante_turno_maxi`, `ayuda_globos_extra`,
  `ultimo_globo`, `despegue_hito`, `broches_instruccion`, `009b`) + 2 del guion de la batalla
  (`nucleo_batalla_falta_uno`, `nucleo_batalla_hito`). Los cabos del storyboard v4 (§21: `vuelo_celebra`
  en la rama B, salida de la revancha, planos del §4, «morada») **no suman TTS**. `pausa_antes` solo cambia de lugar y no se regenera.
- **v4, grabación casera por rehacer: 1** (`derrota_1_coleccionauta`, papá).
- **Grabación casera: 21** (19 del Coleccionauta, una opcional, y 2 de papá), en el §12. Más 2 de papá
  del guion de la batalla que ahora son obligatorias (`papa_01` y `papa_03`).
- **Niños, opcionales: 3** («¡Tres!», «¡Dos!», «¡Uno!»).
- **Reutilizadas: 65** (§9.1).
- **Contra la v2 (131)**: vuelven los ids de la v1 que usan la ficha y el storyboard. Salen `tira_hacia_atras`,
  `fiu`, `resbala`, `doble_resbalon`, `cosquillas`, `la_botaron`, los "bombero/artista/capitana", el álbum
  con voz, `coco_abrazo`, `choca` suelto, los «¡Chao, Coco!» y los «¡Wiii!». Entran `pausa_antes`,
  `encontre_globos`, `gigante_turno_maxi`, `torre_record`, `mapa_coleccionauta` (vuelve: el storyboard v2
  lo usa) y `despegue_hito`.

---

## 14. Changelog

### v4 (17-Oct-2026): auditoría UX HE-71

Solo lo que le toca al guion de `2026-10-13_ux-torre-cierre-arcoiris.md`. Los ids de la v3 no cambian.

| hallazgo | cambio | ids |
|---|---|---|
| **M8.4** (candado social) | `009b` sin "también" ni "ahora": no compara con el hermano que llegó antes ni culpa al que faltó; misma fiesta que `009a` | `arcoiris_009b` |
| **M8** (dos hermanos + el retrato) | El hito de partida ya no pregunta «¿vienen los tres?»; ninguna voz nombra al ausente (cuenta regresiva incluida) | `arcoiris_despegue_hito` |
| **M9** | Tocar Animalia antes de la partida: dos líneas de intriga, sin candado ni castigo, máx. una por visita | **nuevas** `arcoiris_despegue_mapa_animalia_antes_01/02` |
| **M1** | Explicación del tiro para Nicole y Sofía en su primer turno de cada sesión, con la manito fantasma; no bloquea | **nueva** `nucleo_equipo_lanzar_primer_tiro` |
| **M5** | A Maxi se le pide «toca... ¡y suelta!» en vez de «tira para atrás» | `nucleo_equipo_lanzar_repetir_maxi`, `arcoiris_batalla_torre_maxi_globo_01/02`, `arcoiris_batalla_torre_gigante_turno_maxi` |
| **M4** (ficha v3 §8.1-§8.2) | Sin número de globos («¡Más globos!»); +4. Como el último globo de cada intento es siempre de Maxi, `ultimo_globo` le habla a él y reemplaza a `maxi_carga` en ese turno; se apaga en `nicole+sofia` y en el turno guiado. `encontre_globos` hace también de ayuda 2 en `nicole+sofia` | `arcoiris_batalla_torre_ayuda_globos_extra`, `arcoiris_batalla_torre_ultimo_globo`, nota en `encontre_globos` |
| **M4** al retomar (ficha v3 §12) | Se corrige la nota de `encontre_globos`: el mínimo al retomar es 5 (no 4) y la canasta se redondea a 5, 9 o 13, así que el intento retomado también termina con Maxi. Revisé todo el guion: ninguna voz dice cuántos globos hay en la canasta | nota en `arcoiris_batalla_torre_encontre_globos` |
| Storyboard v4 §21.1 | `vuelo_celebra` suena en ME5 en las dos ramas (sin cambio de texto) | `arcoiris_despegue_vuelo_celebra` |
| Storyboard v4 §21.5 | Salida de la revancha **sin línea nueva** (motivo en T.9) | — |
| Storyboard v4 §21.6 | El §4 usa la numeración de planos v4 (MX5 → MX4; entrada §8.2) | `arcoiris_despegue_tanque_gracias`, `arcoiris_despegue_intro` |
| Storyboard v4 §21.7 | Se queda «morada de soplar»; la ficha §10.3 debe decir lo mismo (`disenador-mecanicas`) | `arcoiris_batalla_torre_ayuda_globo_gigante` |
| Re-auditoría UX 17-Oct, P3 | La pausa entre bloques apunta al storyboard v4 §8.1 y deja de ser duda del PO (aprobada por delegación) | `arcoiris_batalla_cierre_pausa_partida`, §10 y §11 |
| Re-auditoría UX 17-Oct, N2 (sobre de la foto a los 6 s, "contestar" la llamada a los 5 s) | **Sin líneas nuevas.** Las dos esperas se resuelven solas y bastan el latido de ≥ 200 px, el "ring-ring" y las voces que ya existen (`cierre_foto` «¡Miren!…» y `arcoiris_010` «¡Sorpresa! Alguien quiere saludarlos.»). Una voz que diga "toca" alargaría justo el tramo pasivo que N2 quiere acortar | — |
| **M5** (ficha v3 §5.3, dedo apretado 1,2 s) | El globo que sale solo no lleva voz propia: "¡pling!" + `maxi_le_dio_0X` | nota en T.2 |
| **M8.2** (dos hermanos + el retrato) | En el turno guiado no suenan las voces con el nombre del que falta, solo las neutras | nota en T.2 |
| **M8.2** en el guion de la batalla | `falta_uno` ya no dice «la batalla es de los tres: ¡lo esperamos!»: invita a subir la carita que falta | `nucleo_batalla_falta_uno` (`docs/guiones/voces-batalla-arcoiris.md` §2) |
| **M8.2** en el guion de la batalla (aprobado por delegación del PO) | `hito` ya no pregunta «¿están todos?»: «¡Es el Coleccionauta! ¡A la nave, equipo: cada carita a su ventana!» (≈ 3,5 s) | `nucleo_batalla_hito` (`docs/guiones/voces-batalla-arcoiris.md` §2) |
| **M6** | `pausa_antes` pasa a antes de la presentación, en el mapa de batalla (mismo texto) | `arcoiris_batalla_torre_pausa_antes` |
| **M7** | Gag 1 sin «¡No me botaron!»; el frasco cae a los ≤ 2,5 s; 6 s → 4 s | `arcoiris_batalla_torre_derrota_1_coleccionauta` (papá) |
| **m3** | `carga` completa solo la 1.ª vez de cada color; después, el color solo (reutilizadas del tanque) | — |
| **m8** | Despegue tras haber usado la llave de padres: «¡De vuelta a Animalia!» | **nueva** `arcoiris_despegue_vuelo_de_vuelta` |
| **m9** | La pista de letra suena siempre con el latido de la estrella | nota en §4.3 |
| **m10** | Coco encaja el ala; Nicole gira los broches por el color que pide Coco | `arcoiris_despegue_broches_instruccion`, **nuevas** `arcoiris_despegue_broches_pide_rojo/amarillo/azul` |
| **m11** | Fuera F1 y F2 entre la caída y "antes del epílogo" | nota en §1 y §9.1 |
| **Decisión 7** | "Antes del epílogo": ≤ 6 s con audio real (sin voces nuevas en el tramo) | nota en §2 y §12 |
| **Decisiones por delegación del PO** | Gigante A, cuenta de a uno (15 s Maxi / 20 s hermanas), revancha con dos sin estrellitas ni récord, final en el Mapa con Animalia encendida | T.5, T.9, §7 y tabla de decisiones |
