# Storyboard y spec — Cierre de la historia del Planeta Arcoíris (de la Torre al despegue)

> Entregable de `director-cinematicas`. **Versión 4.1 (17-Oct-2026)**: aplica las mejoras de la
> re-auditoría UX (`docs/validaciones/2026-10-17_ux-reauditoria-torre-cierre.md`, N2, N3, P2 y P4), la
> pausa entre bloques aprobada y la regla de los broches siguientes (changelog §24, v4.1).
>
> **Versión 4 (17-Oct-2026, tarjeta HE-73)**: resuelve el bloqueante
> **B1** de la auditoría UX HE-71 (`docs/validaciones/2026-10-13_ux-torre-cierre-arcoiris.md`). La v3 estaba
> conciliada con el guion v2, que el guion v3 descartó. Changelog en el §24. Conciliada con:
>
> - el guion `docs/guiones/cierre-arcoiris.md` **v4**: **manda en textos e ids**. Todos los ids de voz de
>   este storyboard salen de ahí (índice en el §2.1). Ya no queda ningún id `arcoiris_partida_*`: el
>   bloque 2 usa `arcoiris_despegue_*`;
> - la ficha `docs/fichas/motor-lanzar.md` **v3**: layout (§4), resortera y primer tiro (§5.2-§5.3),
>   turno y canasta (§8), victoria (§9), derrotas y ayudas (§10), revancha (§11, §11.1), pausa (§13.3),
>   estado familiar (§13.4) y **reglas de la ceremonia (§13.5)**, que aquí se coreografían sin cambiarlas;
> - `docs/fichas/modo-equipo.md` **v7.2**, §14.7 y §14.16: dos hermanos pueden jugar la batalla y la
>   partida con el retrato del tercero.
>
> Continúa `docs/cinematicas/batalla_arcoiris.md` (HE-68) sin contradecirlo; los cambios están en el §1.
>
> **Decisiones del PO por delegación (17-Oct-2026) que aplica la v4**: una sola pausa antes de la Torre
> (M6); cuenta regresiva de a uno (Sofía → Nicole → Maxi); gigante en variante A; revancha con dos sin
> estrellitas ni récord; final en el Mapa Estelar con Animalia encendida; "antes del epílogo" ≤ 6 s con
> audio real.
>
> **Decisiones del PO que aplica (12 y 13-Oct-2026)**:
>
> - la 4.ª etapa, "La Torre de la Colección";
> - el charco que deja al Coleccionauta con lunares y la mochila limpia;
> - los broches en vez de tuercas;
> - el puente de 3 bandas;
> - la cuenta regresiva al final;
> - `arcoiris_009` movida a la instalación del ala;
> - la ruta A-N-I-M-A-L-I-A con señuelos que se vuelve un perrito que ladra;
> - el ala como estado familiar (M7 anulada, con llave de padres);
> - las 4 derrotas-gag del guion;
> - los regalos de Coco: **T-rex de gomita, corazón rosado chicle y pony turquesa**;
> - la física solo en `lanzar`.
>
> **[CONCILIAR]** marca lo que sigue abierto entre roles (lista en el §21). **[PO]** marca lo que espera una
> decisión del PO (§22). **[delegación]** marca lo que decidí en la v4 por delegación del PO, con su
> motivo en una línea.
>
> **No toca** el tablero, el GDD, las fichas, los guiones ni el código.

## 0. Reglas de dirección

1. Todo es **cutout 2D dentro de Godot** (`AnimationPlayer` sobre piezas), porque depende del estado: la
   torre, la mochila, el ala y la ruta.
2. **Un foco por momento.** Las voces **nunca se pisan** (de 0,15 a 0,3 s de aire entre una y otra).
3. **Cámara fija**: solo fundidos, iris y zooms suaves (como máximo 1,0 → 1,15).
4. **Aire después de cada chiste** (de 0,3 a 0,5 s).
5. **El Coleccionauta nunca da miedo**:
   - canon: gafas-lupa, mochila-torre y antenas con bolitas;
   - **nunca nombra a papá**;
   - nunca se hace daño: solo queda **pintado**, y todo cae acolchado (ficha L8).
6. **Saltar**:
   - la primera vez, un toque solo da una chispita en el dedo;
   - desde la segunda vez (por **familia**, §16), un toque salta al estado final;
   - lo interactivo no se salta;
   - las derrotas-gag se cortan con "¡otra vez!" desde la primera vez.
7. **Los tiempos son estimados**: manda el audio. Si una voz dura más de lo previsto, se acortan primero
   las transiciones y el aire.
8. **Cámara lenta**: se usa solo en la Torre. Es un `speed_scale` de la cinemática, **nunca
   `Engine.time_scale`**.
9. **El "plano detalle" no es un corte**: es Cometa acercando el mapa a la cámara.
10. **Sin bichos** (Nicole y Sofía). Esto corrige la mosquita de `batalla_arcoiris.md` §8: la reemplaza
    una pelusa-nubecita (§5.1).
11. **Durante los gags y la anticipación, la torre no se mueve por física** (ficha L3 y L9):
    - lo que se mueve son props, sprites hijos y el rig;
    - la caída final es una coreografía animada que parte de `estado_derribo()`.
12. **Dos hermanos + el retrato del tercero (v4; `modo-equipo.md` §14.7, ficha §13.4)**. El juego solo
    conoce retratos, nunca quién está sentado frente a la tablet. Por eso:
    - **ningún plano nombra ni espera al ausente**: ninguna voz dice "falta", "los tres" como condición
      ni "esperamos a…";
    - **toda espera tiene salida sola** (la lista está en el §16.4), y lo que "le toca" a un hermano lo
      puede tocar cualquiera;
    - el retrato y el rig del tercero aparecen igual que los otros: reciben su regalo, su estrella de la
      cuenta y su gesto canon, del mismo tamaño.
13. **La voz nunca bloquea la entrada** (ficha §5.1): en lo interactivo se puede tocar mientras alguien
    habla. Una línea de instrucción se corta con un fundido de 0,15 s si el niño ya empezó; las de
    resultado y las del Coleccionauta no se cortan.

## 1. Qué cambia de `batalla_arcoiris.md`

| Sección de ese storyboard | Qué pasa ahora | Aquí |
|---|---|---|
| §7.5: interludio azul → "antes del epílogo" | Después del interludio azul va **la única pausa** (mapa de batalla con el 4.º hito, voz `pausa_antes`), y al tocar el hito, la presentación de la Torre, la intro y la etapa. "Antes del epílogo" va después de la caída | §2 y §3 |
| §8, P1: mosquita y `epilogo_antes_coleccionauta` | Pelusa-nubecita y `arcoiris_batalla_epilogo_mochila_gris` (3 s) | §5.1 |
| §9: el Coleccionauta sentado durante el epílogo | Sentado en el charco, con lunares | §5.2 |
| §12.1, A3 | En el tropiezo **se le cae el mapa** (no suma tiempo) | §6.1 |
| §12.2, B1-B4 (la fiesta de los tres) | **Se queda después del epílogo**, compacta (≈ 9,4 s), entre el cierre A y la parte C. **Nunca** entre la caída y el epílogo (sin F1 ni F2) | §6.2 |
| §12.2, B5-B6 (la foto) | **Pasa a la partida**, justo antes de la video-llamada (guion v4 §6) | §11 |
| §12.2, B7 (video-llamada opcional) | **Pasa a la partida** y deja de ser opcional; sin `papa_02` | §11 |
| §12.2, B8 (la nave "¡Juntos!" en la selección) | La próxima vez que se abra la selección | §20 |
| §13.2, A5 (mosquita) | Se elimina; la reemplaza N12 | §19 |

Del cierre se mantiene la **parte A** entera y la fiesta de la **parte B** (B1-B4). Lo nuevo es la
**parte C** (el mapa) y el **bloque 2** (la partida), que ahora incluye la foto.

## 2. El cierre completo, de un vistazo

```
(batalla) interludio azul (livianita_3)
  → LA ÚNICA PAUSA: mapa de batalla con el 4.º hito brillando, voz arcoiris_batalla_torre_pausa_antes;
    nunca avanza sola (§3)
  → toque al hito → presentación de la Torre (≈ 8 s) → intro corta, sin otro "¿seguimos?" → Torre (motor lanzar)
       ├─ derrota → derrota-gag 1-4 (§7) → "¡otra vez!" → rearmado → intro corta
       └─ derribo final:
BLOQUE 1 · LA VICTORIA (≈ 2,4 min)
  Anticipación (≈ 4,6 s variante A / ≈ 3,2 s variante B) (§4.1)
  Caída en el charco (≈ 10,8 s) (§4.2)          ← el momento de mayor celebración del planeta
  Antes del epílogo (≈ 4,95 s; tope ≤ 6 s con audio real) (§5.1)
     (tramo sin tocar desde el tiro ganador hasta el epílogo: ≈ 19 s; sin F1 ni F2)
  Epílogo: pintar la mochila (≈ 75 s, interactivo) (§5.2)
  Cierre A: se despide y se le cae el mapa (≈ 19,8 s) → fiesta de los tres (≈ 9,4 s + toque al choque) (§6.1-§6.2)
  Parte C: el mapa (Maxi toca el papel; ≈ 18 s) (§6.3)
  ── PAUSA NATURAL: la nave espera brillando (§8.1) [aprobada por delegación del PO] ──
BLOQUE 2 · LA GRAN PARTIDA (partida_arcoiris.tscn, ≈ 3,7 min)
  Entrada (≈ 4 s) → Preparativos (≈ 1,5 min): Maxi el tanque → Nicole los broches de color → Sofía la ruta (§9)
  Despedida de Coco (≈ 41 s, interactiva) (§10)
  La foto (≈ 13 s + toque al sobre) y la video-llamada de papá (≈ 31 s + toque al teléfono-estrella) (§11)
  Cuenta regresiva de a uno y despegue por el puente (≈ 10 s + toques + ≈ 14 s) (§12)
  Mapa Estelar: Animalia se enciende (≈ 12 s) (§13)
```

### 2.1 Índice de voces v4 → dónde suenan

Todos los ids del guion v4, por sección del guion. Los que dispara el motor `lanzar` en cada turno no
tienen coreografía propia aquí: solo se nombran para que no falte ninguno.

| Guion v4 | Ids | Aquí |
|---|---|---|
| T.1 | `torre_pausa_antes`; `presenta_coleccionauta`, `presenta_alcanzo`, `presenta_coco`; `intro_coleccionauta` + `intro` | §3 |
| T.1 (turno) | `nucleo_equipo_lanzar_primer_tiro` **[v4]** con la manito fantasma; `lanzar_repetir`, `lanzar_repetir_maxi` (tocar a Cometa) | §3.1 |
| T.2-T.4 (turno, motor) | `carga_01..03` (o el color solo: `arcoiris_despegue_tanque_color_*`), `maxi_globo_01/02`, `globos_especiales`, `toca_en_el_aire`, `maxi_le_dio_01/02`, `acierto_01..03`, `acierto_grande`, `fallo_01/02`, `ultimo_globo`, `reacciona_01..03`, `rio_justo_ahi_01/02` | Ficha §8.1 (sin plano propio) |
| T.5 (variante A) | `ayuda_globo_gigante`, `gigante_coleccionauta`, `gigante_turno_maxi` (o `gigante_turno`), `gigante_impacto` | §7.6 |
| T.6 | `ayuda_globos_extra`, `encontre_globos` (al retomar, motor), `torre_pausa` | §7.1-§7.4 |
| T.7-T.8 | `derrota_1..4_coleccionauta`, `derrota_1..4_coco_risa`, `rearma_01/02`; `nucleo_equipo_cajas_botadas_01/02` | §7.2-§7.5 |
| T.9 | `intro_revancha`, `lanzar_estrellitas_1..3`, `torre_record`, `emparejar_equipo_primer_record` (solo con los tres) | §14 |
| §1 | `torre_ups` (opcional), `cae_lenta`, `cae_charco`, `cae_risa` | §4 |
| §2 | `epilogo_mochila_gris`, `epilogo_antes_coco` | §5.1 |
| §3 | `cierre_mira`, `cierre_equipo`, `cierre_despedida`, `cierre_coco` (solo en A5); `mapa_coco`, `mapa_cometa`, `mapa_coleccionauta`, `mapa_animalia`, `pausa_partida`, `arcoiris_despegue_hito` | §6, §8.1 |
| §9.1 (fiesta) | `nucleo_equipo_al_frente`, `fiesta_<hermano>` (niños, opc.), `choca`, `equipo_estelar`, `destellos` | §6.2 |
| §4 | `arcoiris_despegue_intro`; tanque (`tanque_*`), broches (`broches_instruccion`, `broches_pide_rojo/_amarillo/_azul` **[v4]**, `broche_1..3`, `broches_ala`, `broches_gracias`, `broches_recuerda_01/02`, `broches_ayuda`), ruta (`ruta_*`); `arcoiris_009` | §9 |
| §5 | `coco_regalo_<hermano>`, `coco_choca_<hermano>`, `coco_choca_recuerda`, `coco_cierre`, `hangar` | §10 |
| §6 | `cierre_foto` (+ audio familiar), `arcoiris_010`, `cierre_papa_01`, `papa_pista`, `papa_guatita`, `cierre_papa_03` | §11 |
| §7 | `cuenta_instruccion`, `cuenta_tres/dos/uno` (o las de los niños), `cuenta_motores`, `cuenta_recuerda`; `vuelo_despegue`, `vuelo_puente`, `vuelo_coco_chao`; `vuelo_lejitos`, `vuelo_celebra`, `vuelo_rumbo_animalia`, `vuelo_de_vuelta` **[v4]**; `mapa_animalia_lejitos`, `mapa_animalia_antes_01/_02` **[v4]** | §12-§13 |
| §8 | `arcoiris_009a`, `arcoiris_009b` | §15 |
| §9.1 (retomar) | `nucleo_batalla_todos_nave_corta`, `falta_uno`, `nucleo_equipo_sube_nave_<hermano>`, `yo_tambien_<hermano>`; `nucleo_equipo_ahora_<hermano>` | §8.2, §9 |

**Ya no suenan en ningún plano** (retiradas en el guion §9.2 o sin uso con la variante A):
`arcoiris_batalla_cierre_papa_02`, `epilogo_antes_coleccionauta`, `arcoiris_despegue_coco_espera`,
`ruta_pista`, `la_botaron`, `lo_bajamos`, `no_lo_necesitamos`, `gigante_presenta`, `inflemoslo`,
`gigante_inflado`, `coco_abrazo`, `chao_coco_<hermano>`, `wii_<hermano>`, las frases "bombero / artista /
capitana" y todos los `arcoiris_partida_*` de la v3.

## 3. La pausa y la presentación de la Torre (T.1 del guion, ≈ 8 s)

**Una sola pausa, y es antes (M6; ficha §13.3)**. Después del interludio azul aparece el mapa de batalla
con los 3 hitos de color hechos y el 4.º (la Torre, el más grande) brillando, **igual que entre las rondas
1-2 y 2-3**. Suena una vez `arcoiris_batalla_torre_pausa_antes` (3,3 s, «¿Vamos por la torre, o
descansamos y volvemos después?»). **Nunca avanza sola** y la casa está a la vista.

- **Al tocar el hito**: la presentación arranca de inmediato y sigue **directo** a la intro corta. No hay
  otro "¿seguimos?" entre medio: descansar nunca se ofrece justo después de mostrar el reto.
- La presentación se salta desde la segunda vez (`arcoiris_batalla_final:presenta_torre`).
- Composición: el layout de la ficha §4 (Coco con los pies en (85, 584), canasta a sus pies).

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| T1 | 0,0-2,5 | El claro con el arcoíris completo; el Coleccionauta con la mochila vacía | **En cámara rápida** saca de la mochila cajas, frascos de caramelo y latas, y los apila sobre la galleta-plataforma (x 800-1180, centro x 990), con un "pop" por pieza, al ritmo de "caja, frasco, caja". En "¡y yo arriba!" trepa al cojín-trono | `arcoiris_batalla_torre_presenta_coleccionauta` (2,5 s) | Motivo del Coleccionauta. "Pop" por pieza |
| T2 | 2,7-5,7 | El Coleccionauta en la cima | Sentado, orgulloso. En «...me lo llevo de la mano» se pone de puntillas y estira la mano hacia el arcoíris; le faltan 5 px. Solo el rig se mece ±1° (ficha §6.2.2: los bloques no tambalean) | `arcoiris_batalla_torre_presenta_alcanzo` (3 s) | Un "ñiii" de estirarse |
| T3 | 5,9-8,1 | **Coco** junto a su canasta | Saca la resortera de regaliz con un giro; los globos del ramo se mecen | `arcoiris_batalla_torre_presenta_coco` (2,2 s) | "Boing" de goma |

Después va la intro corta (`arcoiris_batalla_torre_intro_coleccionauta` + `arcoiris_batalla_torre_intro`)
y el primer turno, que **siempre es de Maxi** (ficha §8.1).

**El puente desde el interludio azul**: el gag de `livianita_3` (la mochila vacía lo hace flotar y cae
sentado) termina el interludio como hoy. La pausa del mapa de batalla separa las dos cosas, así que no
hace falta un puente animado.

### 3.1 El primer tiro de Nicole y de Sofía (M1; ficha §5.2.1)

No es cinemática: es un momento del turno que el motor anima. Va aquí porque tiene coreografía.

- **Cuándo**: el primer turno de Nicole y el primer turno de Sofía **de cada sesión de Torre**, después de
  `carga`.
- **Voz**: `nucleo_equipo_lanzar_primer_tiro` (Cometa, 2,6 s, «¡Estira para atrás... apunta... y
  suelta!»), sin nombre, la misma para las dos.
- **Manito fantasma (0,8 s, una sola vez)**: mano blanca al 60 %, ⌀ 90 px, que arranca con la voz. Se
  apoya en la bolsa (260, 430) (0,1 s), la arrastra hacia atrás y abajo ≈ 150 px mientras se oye «estira
  para atrás» (0,5 s; la goma se estira de verdad, con la bolsa "fantasma" al 50 %) y suelta (0,2 s). La
  bolsa vuelve con rebote y no sale ningún globo. Durante «apunta... y suelta» la bolsa solo respira.
- **No bloquea**: si la niña toca el área de agarre, la voz y la manito se cortan en 0,15 s y el gesto es
  suyo.
- Maxi no la oye: su consigna ya va en `maxi_globo_01/02` («toca... ¡y suelta!»).

## 4. La victoria: anticipación y caída en el charco

**Composición (ficha §4)**:

| Elemento | Posición |
|---|---|
| Torre | Centro x 990, base en y 584, cima ≤ 434 px |
| Charco | Centrado en (990, 580); en el derribo mide ≥ 360 px (ficha §6.9) |
| Resortera | Bolsa en (260, 430) |
| Coco y la canasta | Pies en (85, 584), fuera del área de agarre (ficha §4 v3) |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` |
| Casa | `Rect2(1172, 8, 100, 96)` |

**El charco crece con cada tiro que no bota nada** (ficha §6.9): un escalón por tiro neutro y medio por
globo que revienta en el suelo, con un "chof" y una ondita. No se borra nunca. Es la memoria de que ningún
tiro se pierde.

**Señales (ficha §13.2)**:

- en el cuadro del derribo final (agarre 0 o trono botado), con la física congelada, el motor emite
  `derribo_inminente(punto_impacto, desde_soltar)`;
- la coreografía parte de `estado_derribo()`;
- la caída se envuelve en `momento_saltable_iniciado/terminado("caida_torre")`;
- el salto es `saltar_derribo()` (la implementación de `saltar_momento("caida_torre")`);
- si se pide un salto durante la anticipación, queda en cola para la caída.

### 4.1 Anticipación (no se salta ni se marca vista)

- **Variante A** (`desde_soltar = true`): se sabe al soltar el globo. Va de K1 a K5.
- **Variante B** (`desde_soltar = false`, el caso normal): empieza en K2, con la cámara lenta en el
  salpicón.

| # | Tiempo (A) | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| K1 | 0,0-1,4 (solo A) | El globo en vuelo | **Cámara lenta a 0,35** desde los 0,15 s del lanzamiento, y zoom suave 1,0 → 1,08 hacia la torre. El Coleccionauta lo ve venir con los ojos agrandados por la lupa. **En la barra, los tres retratos inflan los cachetes** | — | Música a −12 dB. "Fiuuuu" grave y estirado |
| K2 | 1,4-1,9 | El impacto | **¡Splat!** en `punto_impacto`. En la variante B, **este salpicón va en cámara lenta (0,4) durante 0,5 s**, y el zoom 1,0 → 1,08 ocurre aquí | — | "Splat" al 70 % |
| K3 | 1,9-3,3 | La torre, congelada en la pose del derribo | **Tambaleo en tres vaivenes que crecen** (±3°, ±6° y ±9°, de 0,45 s cada uno), aplicado al sprite del conjunto con pivote en la galleta (990, 584), sin física. El Coleccionauta, en su cara **"colgando de un dedo"**, patalea | — | Tres crujidos de juguete ("ñiic"), cada uno más agudo |
| K4 | 3,3-4,1 | **El instante de silencio** | La torre queda **inclinada 11°**, imposible. Él, colgado del cojín con un dedo, **mira a la cámara**, parpadea dos veces y saluda con los dedos de la otra mano | — | **Silencio total**: la música se apaga 0,15 s antes. Son 0,8 s exactos |
| K5 | 4,1-4,6 | — | Se le resbala el dedo, "tic" | `arcoiris_batalla_torre_ups` (0,5 s, **opcional**: el guion la ubica "cuando se le resbala el dedo", que aquí es K5) | Un "tic" |

La variante B dura ≈ 3,2 s (de K2 a K5). Si el tiro ganador es el del gigante, en K1 los retratos ya venían
con los cachetes inflados desde el vuelo (§7.6) y siguen así hasta K4.

### 4.2 Caída en el charco (≈ 10,8 s; se salta desde la 2.ª vez: `arcoiris_batalla_final:caida_torre`)

**Gag central [PO]**: mientras todo se cae, él **salva su mochila**.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| C1 | 0,0-2,5 | La torre se rinde **en cámara lenta (0,4)** | Cada bloque interpola desde su pose en `estado_derribo()` hasta su pose de coreografía, desarmándose **hacia la derecha y alrededor del charco** (nunca encima de él). Las cajas se abren como tapas y sueltan estampillas y calcetines; los frascos de caramelo se rompen en **confeti dulce** y su contenido flota (patito, guante, globo de nieve, cuchara y cono); las latas ruedan. Él cae **sentado en el aire**, pedaleando, y **levanta la mochila sobre la cabeza** | `arcoiris_batalla_torre_cae_lenta` (2,5 s, «¡Nooo... mi... mo-chi-laaa!», lenta y grave a propósito) | "Woooosh" grave. "Clin-tintín" graves |
| C2 | 2,5-3,2 | Vuelve la velocidad normal | Las piezas terminan de caer en un montón alrededor del charco ("boing" acolchados) | — | "Pum, pum" suaves |
| C3 | 3,2-3,5 | **¡SPLASH!** | Aterriza **sentado en el centro del charco, (990, 578)** (squash 0,75 / stretch 1,15). Sube una corona de salpicón multicolor y aparecen **los lunares** en el cuerpo, el chaleco y las antenas (capa N3). **La mochila, en alto, queda gris y limpia** | — | "Splash" redondo, al 70 % |
| C4 | 3,5-4,3 | Él, quieto | **Aire para la risa** (0,8 s): parpadea; le gotea pintura de las antenas; **la tapa de un frasco le cae de sombrerito** (lo único que le cae encima, y es blandito) | — | "Plip, plip" y "plink" |
| C5 | 4,4-7,9 | Él | Baja la mochila con cuidado. En «¡Uf!» se mira las manos **de lunares**, con los ojos agrandados por la lupa; en «...¡Nunca había estado tan... colorido!» pasa del asombro a encantado y se abraza a sí mismo | `arcoiris_batalla_torre_cae_charco` (3,5 s) | "Plip" en la pausa del «...» |
| C6 | 8,1-10,8 | **Fiesta máxima**, la pantalla entera | Se pone de pie en el charco y **chapotea saltando como un niño**, cabeza atrás, diente mellado. Cañones de confeti desde los dos costados y **tres fuegos artificiales de pintura** (rojo, amarillo y azul, cada 0,4 s). **Los tres retratos de la barra saltan juntos** (dos saltos de 60 px; el foco es el grupo). Coco da una voltereta y queda **de lunares de colores**. Cometa hace un loop. Al final se deja caer sentado otra vez ("plof", squash): es el estado final | `arcoiris_batalla_torre_cae_risa` (2,5 s, «¡Jajá! ¡Parezco un arcoíris con antenas!») | **La fanfarria más grande del planeta**. "Splish-splash" |

**v4 (m11)**: C6 es la única fiesta entre la caída y el epílogo. **No suenan F1
(`arcoiris_batalla_cierre_coco`) ni F2 (la fiesta de los tres)**: la caída sigue directo a "antes del
epílogo". Tramo sin tocar desde el tiro ganador: 3,2 (anticipación B) + 10,8 + 4,95 ≈ **19 s**. Si en el
playtest Maxi se distrae aquí, lo primero que se recorta es el aire de C4.

**Estado final** (el mismo que deja `saltar_derribo()`, ficha §9.4):

- él sentado en el charco, pintado, con el sombrerito y la mochila gris;
- las cajas desparramadas alrededor del charco;
- confeti cayendo y la música de fiesta en bucle.

Después el motor emite `completado(0)`.

## 5. Del charco al epílogo

### 5.1 Antes del epílogo (≈ 4,95 s; tope ≤ 6 s medido con el audio real)

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| P1 | 0,0-3,0 | Él, sentado en el charco | «Yo, de colores...»: se señala los lunares. «¿y mi mochila?»: la levanta, la da vuelta y la sacude; **solo cae la pelusa-nubecita** (N12), que se va flotando. «¡Gris!»: abraza la mochila, dramático de teleserie | `arcoiris_batalla_epilogo_mochila_gris` (3 s) | Música a −10 dB. "Fiu-fiu" de violín de teleserie |
| P2 | 3,15-4,95 | **Coco** | Ampolleta de chispa y salto | `arcoiris_batalla_epilogo_antes_coco` (1,8 s, «¡Ya sé! ¡Regalémosle colores!») | "¡Ding!" |

**Tope (decisión 7 de la UX)**: ≤ 6 s **medido con el audio real**, recortando los 0,5 s de silencio que
traen los archivos. Si la toma de papá de `mochila_gris` pasa de 3,8 s, se pide otra más rápida. No se
agrega ninguna voz en este tramo. QA lo mide con los `.wav` definitivos.

### 5.2 El epílogo

Igual que `batalla_arcoiris.md` §9. Él está sentado en el charco, con lunares. Los colores que le regalan en
la mochila son **planos y enteros**; los de su cuerpo, **lunares**: lo regalado se distingue de lo
salpicado. Termina con el estornudo de confeti.

## 6. Despedida del Coleccionauta, fiesta, foto y el mapa

### 6.1 Cierre A (≈ 19,8 s): igual que `batalla_arcoiris.md` §12.1, con el mapa

| # | Tiempo | Qué pasa | Voz |
|---|---|---|---|
| A1 | 0,0-5,3 | Gira persiguiendo su mochila pintada y se traba de emoción | `arcoiris_batalla_cierre_mira` |
| A2 | 5,5-8,5 | Compara la mochila con los tres | `arcoiris_batalla_cierre_equipo` |
| A3 | 8,8-16,0 | La despedida y el "¿para qué lado era la salida?". **En el tropiezo final con el trébol, del bolsillo de la mochila salta una bolita de papel arrugado**: sube en arco (0,4 s) y baja **planeando como una hoja** (0,8 s) hasta una mata de trébol en **(170, 520)** (v4: más arriba, para que su target de 120 px quede a ≥ 24 px de la barra). Ocurre dentro del 1,2 s del gag que ya existía, así que no suma tiempo. **Él sale sin darse cuenta.** El patito rebota detrás | `arcoiris_batalla_cierre_despedida` |
| A4 | 16,0-16,2 | Aire. **El papel destella una vez** ("tilín"): es la semilla para Maxi | — |
| A5 | 16,2-19,8 | Coco "¡arcoíris de equipo!", y el arcoíris del cielo destella. El papel queda quieto (un foco). **Es la única vez que suena esta línea en el bloque 1** (m11) | `arcoiris_batalla_cierre_coco` |

### 6.2 La fiesta de los tres (≈ 9,4 s + la espera del choque, ≤ 4 s): `batalla_arcoiris.md` §12.2, solo B1-B4

**[delegación] La fiesta reutilizada va después del epílogo, compacta, y no entre la caída y el epílogo:
es la única entrega de los destellos de la batalla y el choque de los tres es la lección de cooperación;
sin la foto (que pasó a la partida) baja de 22,8 a ≈ 9,4 s, así que el bloque 1 queda más corto que en
la v3.**

| # | Tiempo | Qué pasa | Voz |
|---|---|---|---|
| B1 | 0,0-1,6 | Los tres retratos salen juntos al frente desde la barra (rigs de cuerpo entero) | `nucleo_equipo_al_frente` |
| B2 | 1,8-4,2 | Gestos canon por turnos, 0,8 s cada uno, con el mismo foco y el mismo volumen | `nucleo_equipo_fiesta_<hermano>` (niños, opcionales: los tres o ninguno) |
| B3 | 4,4-7,4 (+ espera ≤ 4 s) | Manos al centro → **las manos quedan juntitas sin chocar y esperan un toque de cualquiera** (v4.1, N3): target **≥ 200 px** centrado en el punto de choque, (640, 330), que late con un brillo. Al tocarlo (< 100 ms), o **solo a los 4 s**, el choque → confeti arcoíris | `nucleo_equipo_choca` (al empezar la espera) → `nucleo_equipo_equipo_estelar` (tras el choque) |
| B4 | 7,6-9,4 | "+100" bajo cada retrato, del mismo tamaño | `nucleo_equipo_destellos` (solo si **todos** reciben) |

- **No hay B5-B8** aquí: la foto y la llamada están en el §11; B8 en el §20.
- El papel arrugado sigue en el trébol a la izquierda, quieto. Los rigs vuelven a la barra (0,4 s).
- Con dos hermanos y el retrato del tercero, salen igual los tres rigs: el juego no sabe quién falta.

### 6.3 Parte C: el mapa (≈ 18 s + la espera del toque; se salta desde la 2.ª vez: `arcoiris_batalla_final:mapa_coleccionauta`)

**v4 (m6; ficha §13.5)**: la parte C es de Maxi. El papel **espera un toque de cualquiera**. Con el
toque del choque (B3, v4.1) el tramo después del epílogo queda partido en ≈ 24 + 5 + 18 s.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| M1 | Espera (≤ 6 s) | El papel en el trébol (170, 520) | **Target ≥ 120 px**, `Rect2(110, 460, 120, 120)` (30 px sobre la barra). Destella cada 1,2 s y respira; Coco mira el papel y después a la cámara, curiosa. **Al tocarlo** (< 100 ms) da un saltito con "tilín". **Si nadie toca, sigue solo a los 6 s** | — | "Tilín" en cada destello |
| M1b | 0,0-1,4 | **Coco** | Señala el papel con la manopla | `arcoiris_batalla_cierre_mapa_coco` (1,4 s, «¡Eh! ¡Se le cayó algo!») | — |
| M2 | 1,5-2,7 | **Coco** | Lanza **la lengua del Río** y atrapa el papel ("¡fiup!"). Se le pega a la lengua y **se estira como chicle** antes de soltarse en las manos de Cometa ("boing") | — | "Fiup" y "boing" |
| M3 | 2,7-4,3 | **Cometa** | Lo desarruga en tres tirones (el papel crece de 120 a 320 px) y **lo acerca a la cámara** hasta llenar `Rect2(140, 70, 1000, 560)`. El fondo se aclara un 15 %, **nunca se oscurece** | — | Tres "crunch" y "fffp" |
| M4 | 4,4-7,9 | **Plano detalle** (N5) | Crayón infantil, **sin texto**: Arcoíris a la izquierda, **una ruta de 8 estrellitas punteadas con una flechita** y, a la derecha, el planeta verde **con una huellita**. Las estrellas se encienden una por una (0,25 s cada una); «mapa» coincide con la primera y «Animalia» con el latido de la huellita. **La ruta no se ve como un perrito**: esa sorpresa es de Sofía | `arcoiris_batalla_cierre_mapa_cometa` (3,5 s) | **La melodía de la ruta** (escala de do, una nota por estrella, §17) |
| M5 | 8,2-11,7 | El mapa baja un poco; **a lo lejos, en el borde derecho** | **Gag**: asoman chiquititas sus antenas con bolitas, con lunares, sobre una loma. En «¡Mi mapa!» saltan; en «...Bah» se encogen de hombros; en «¡Creo!» una antena le rasca la cabeza, **las antenas se van hacia arriba de la loma, frenan y vuelven a bajar por el otro lado** (dudó del camino) hasta perderse. Coco y Cometa lo miran irse y se miran entre ellos | `arcoiris_batalla_cierre_mapa_coleccionauta` (3,5 s, fuera de cuadro y con eco) | Eco en la voz. "Boing" chiquito al rascarse |
| M6 | 12,0-13,2 | La barra | **Aire** (0,3 s) y el mapa se achica y **vuela al retrato de Sofía**, que se ilumina (lo usa en su ruta, §9.5) | — | "Fiuu" y campanita |
| M7 | 13,2-18,0 | Fundido cruzado (0,6 s) al Claro con la nave estacionada (§9.2), **con el ala envuelta para regalo junto a la nave** | Cometa se asoma, ilusionado, y señala la nave | `arcoiris_batalla_cierre_mapa_animalia` (4,5 s) | La música se resuelve en un acorde |

## 7. La Torre: las cuatro derrotas-gag y el globo gigante

### 7.1 Plantilla común (ficha §10.1 y §8.3)

- **La derrota llega en el pase**: el último globo de cada intento es siempre el tiro seguro de Maxi
  (ficha §8.1, reparto 9 + 4), y como el intento siguiente también empieza con él, **su retrato se queda
  al centro** (≈ 210 px, a y ≈ 250) con un saltito de "¡otra vez yo!". Nunca aparece pegada al tiro de
  nadie.
- **La torre está congelada**: solo se mueven props, sprites hijos y el rig. La zona de juego se oscurece
  un 20 %, salvo la torre.
- **"¡Otra vez!"** de ≥ 160 × 160 px en (640, 480), **desde el segundo 0** (la bandeja de Sofía está oculta
  durante el gag). Tocarlo corta la secuencia y va al rearmado (§7.5).
- **Orden**: el gag (`derrota_<n>_coleccionauta`) → `derrota_<n>_coco_risa` → el logro de Cometa → la
  ayuda o la pausa de Coco.
- **Cuál gag**: las derrotas 1, 2 y 3 usan los gags 1, 2 y 3. **Desde la 4.ª rotan los cuatro sin repetir
  el anterior** (`variante_derrota()`). El conteo es por familia, se guarda en el parcial y se reinicia en la
  revancha.
- **Logro común** (ficha §10.1): **2 tramos según las piezas botadas en el intento, partidos en la mitad
  de las 28 piezas** de la torre de referencia (`logro_comun_corte` 0,5 sobre `total_piezas`):
  - tramo "1" (< 14): `nucleo_equipo_cajas_botadas_01` (4 s);
  - tramo "2" (≥ 14): `nucleo_equipo_cajas_botadas_02` (4,5 s).
  - Mientras suena, **destellan las manchas y las piezas botadas que están en el suelo**. «¡Y algunas ya
    no suben!» siempre es verdad: si hubo botadas, al menos 1 queda en el suelo (ficha §10.2, m2).
  - Con 0 piezas (solo sin Maxi), `nucleo_equipo_nos_alcanzo`.
- **La ayuda o la pausa** (ficha §10.3):
  - 1.ª derrota: `arcoiris_batalla_torre_ayuda_globos_extra` (4 s, sin número), con **+4 globos** del
    equipo;
  - 2.ª derrota: `arcoiris_batalla_torre_ayuda_globo_gigante` (§7.6);
  - **desde la 3.ª**: Coco ofrece descansar con `arcoiris_batalla_torre_pausa` (4,5 s, «¿Vamos otra vez,
    o descansamos y volvemos después? ¡La torre no se va a ninguna parte!»).
  - Revancha `nicole+sofia`: la ayuda 2 es `encontre_globos` con +2 globos, sin gigante (ficha §11.1).
- **Lo que le cae encima se queda** hasta la victoria (pintura rosada, calcetín, cara pintada).
- **Los retratos se ríen juntos en el remate**, nunca mientras él se jacta. Nadie queda señalado.

### 7.2 Gag 1 · "El baile" (1.ª derrota, ≈ 16 s si nadie toca "¡otra vez!")

**v4 (M7)**: el castigo a su orgullo llega rápido: **el frasco cae a los ≤ 2,5 s**, y ya no dice «¡No me
botaron!».

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| G1a | 0,0-0,3 | Se pone de pie en el cojín, con los brazos arriba | (empieza la línea) | "Boing" |
| G1b | 0,3-2,4 | «¡Sigo arriba!»: puños al cielo. «¡Baile de la torre!»: mueve las caderas (2 cuadros, solo el rig; la torre no se mueve). «Un pasito pa'cá...»: un pasito, y **el frasco de pintura rosada** (prop sobre el cojín, no un cuerpo físico) se mece. **A los 2,1 s se le da vuelta en la cabeza** y a los **2,4 s ¡plof!**: papá corta el baile en «pa'cá» | `arcoiris_batalla_torre_derrota_1_coleccionauta` (4 s, empieza) | Cumbia chiquita de kazoo a −10 dB, que **se corta en seco** con el ¡plof! |
| G1c | 2,4-4,0 | **Remate**: chorreando rosado, mira hacia arriba y parpadea dos veces: «...¿Por qué llueve rosado?». **Aquí, y no antes, los tres retratos se ríen juntos** | (sigue la línea) | "Glu-glu" y "plip" |
| G1d | 4,2-7,2 | Coco se ríe dando saltitos | `arcoiris_batalla_torre_derrota_1_coco_risa` (3 s) | — |
| G1e | 7,4-11,4 | Cometa brilla; destellan las manchas y lo botado | `nucleo_equipo_cajas_botadas_01` o `_02` | Campanitas en escalera |
| G1f | 11,6-15,6 | **Ayuda**: en «¡Miren! ¡Más globos!» Coco señala el pasto; en «...¡Estaban camuflados en el pasto, como yo!» se pone verde pasto y **desaparece en el pasto** (0,5 s), y reaparece mientras **cuatro globos** saltan del pasto y vuelan al ramo, uno cada 0,2 s | `arcoiris_batalla_torre_ayuda_globos_extra` (4 s) | "Fiu" de camuflaje y cuatro "pop" |

### 7.3 Gag 2 · "El estornudo" (2.ª derrota, ≈ 14 s más la ayuda del gigante, §7.6)

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| G2a | 0,0-0,4 | De pie, saca pecho | — | — |
| G2b | 0,4-5,9 | "¡Nadie me tumba! Soy el rey de la...": se pone una **tapa de frasco como corona**. "...ay, una pelusita": baja flotando **la pelusa-nubecita** (N12) y le pasa por la nariz. "A... a...": **anticipación de 0,6 s** (se infla y cierra los ojos). "¡ACHÚU!": **la mochila vacía de su espalda estornuda calcetines de la colección**, que vuelan en espiral, y **uno le cae de sombrero** | `arcoiris_batalla_torre_derrota_2_coleccionauta` (5,5 s) | Estornudo (70 %, siempre después de la anticipación) y un "fiu-fiu" de calcetines |
| G2c | 6,1-8,6 | Coco se ríe | `arcoiris_batalla_torre_derrota_2_coco_risa` (2,5 s) | — |
| G2d | 8,8-12,8 | Destellan las manchas y lo botado | `nucleo_equipo_cajas_botadas_01` o `_02` | Campanitas |
| G2e | 13,0-19,0 | **Ayuda: Coco infla el globo gigante** (§7.6) | `arcoiris_batalla_torre_ayuda_globo_gigante` (6 s) | Tres "fuuu" que crecen |

### 7.4 Gag 3 · "El globo que vuelve" (3.ª derrota) y Gag 4 · "El chicle" (desde la 4.ª, en rotación)

En la batalla, con el gigante y el daño conservado, una 3.ª derrota es rara (ficha §10.3, ≈ 1 %). En la
revancha, el conteo empieza de cero.

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| G3a | 0,0-2,0 | Saltitos de triunfo. En "¡Ningún globo me alcan—" **aparece en el borde superior la flechita de "globo fuera de pantalla"** (UI de la ficha §4), justo arriba de él | `arcoiris_batalla_torre_derrota_3_coleccionauta` (empieza) | — |
| G3b | 2,0-3,0 | **El silencio de 1 s que graba papá**: la flechita crece y tiembla. A los 0,8 s el globo entra en picada y **¡PLAF!** en su cabeza. Es un prop scripteado: si en ese intento un globo salió por arriba, tiene su color; si no, es azul (ficha §10.1) | (silencio en la grabación) | Silbido que baja y "¡plaf!" |
| G3c | 3,0-5,0 | **Con la cara entera pintada**, muy digno: "...zó. ¿De dónde salió ese?" | (sigue la línea) | — |
| G3d | 5,2-8,2 | Coco se ríe | `arcoiris_batalla_torre_derrota_3_coco_risa` (3 s) | — |
| G3e | 8,4-12,4 | Logro | `nucleo_equipo_cajas_botadas_01` o `_02` | Campanitas |
| G3f | 12,6-17,1 | **Pausa**: Coco se sienta tranquila en el pasto y la casa respira suave. En «¡La torre no se va a ninguna parte!» él, arriba, se abraza a la torre y asiente muy serio. "¡Otra vez!" y la casa quedan igual de visibles: las dos opciones valen | `arcoiris_batalla_torre_pausa` (4,5 s) | — |
| G4a | 0,0-5,0 | "¡Me salvé!": se seca la frente. "Esto merece un chicle de premio...": saca un chicle rosado del chaleco y masca dos veces. "fffff": **el globo de chicle crece** hasta ser más grande que su cabeza, y las antenas se le van para atrás. "¡PLOP!": **explota** y le tapa la cara y las gafas de rosado | `arcoiris_batalla_torre_derrota_4_coleccionauta` (5 s) | Un "fffff" que sube y un "¡plop!" |
| G4b | 5,2-7,7 | Coco se ríe y **se pone rosado chicle** (su tic) | `arcoiris_batalla_torre_derrota_4_coco_risa` (2,5 s) | — |
| G4c | 7,9-16,6 | Logro, y después **pausa** como en G3f | `nucleo_equipo_cajas_botadas_01` o `_02` → `arcoiris_batalla_torre_pausa` | — |

### 7.5 Al tocar "¡otra vez!": el rearmado (≈ 7 s)

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| R1 | 0,0-0,3 | Se corta lo que sonaba (fundido de 0,15 s). **Si se cortó antes de la ayuda, la ayuda igual ocurre, sin voz**: los 4 globos extra o el gigante (ya inflado, Coco morada) llegan durante R2. Nadie pierde un regalo por apurarse | — | — |
| R2 | 0,3-3,8 | **Rearmado parcial** (`gag_derrota_devolver`, ficha §10.2): las piezas que él repara vuelven a su pose, una cada 0,25 s, con un "pop"; **las que no repara quedan en el suelo alrededor del charco**, como decorado; las manchas y el charco quedan todos. Trepa y se sienta, con la cara que corresponde al agarre conservado | `arcoiris_batalla_torre_rearma_01` o `_02` (alternadas) | Un "pop" por pieza |
| R3 | 4,0-6,8 | La intro corta | `arcoiris_batalla_torre_intro_coleccionauta` + `arcoiris_batalla_torre_intro` | — |

### 7.6 El globo gigante (variante A, por delegación del PO; ficha §10.3)

Coco lo infla tras la 2.ª derrota y **lo tira Maxi** como primer globo de cada intento desde el 3.º; no
gana solo. **Condicionado** a que el simulador con datos del arnés muestre ≥ 95 % en ≤ 3 intentos (si no,
vuelve al PO). La variante B no se anima ni se generan sus voces.

| # | Cuándo | Qué se ve | Voz | SFX |
|---|---|---|---|---|
| GG1 | G2e, al cerrar la 2.ª derrota (6 s) | En cada «fuuu» Coco sopla y el globo dorado-arcoíris crece por franjas (3 franjas, cada soplido más largo). En «¡Les inflé mi globo gigante!» lo ata al poste de la canasta; en «...¡morada de soplar!» Coco **se pone morada**, se marea con los ojos en espiral 0,6 s y sonríe | `arcoiris_batalla_torre_ayuda_globo_gigante` (6 s) | Tres "fuuu" que suben y un "pop" de nudo |
| GG2 | Al empezar el 3.er intento, solo la 1.ª vez que se ve | El Coleccionauta, arriba, ve el gigante: cara de "¡no es justo!" con los brazos cruzados; en «...Bueno, sí es justo» se encoge de hombros | `arcoiris_batalla_torre_gigante_coleccionauta` (3,5 s) | — |
| GG3 | Turno de Maxi (reemplaza su primer globo normal) | El gigante (radio 72 px) se acomoda en la bolsa; su halo dorado respira sobre `gigante_objetivo` | `arcoiris_batalla_torre_gigante_turno_maxi` (2,8 s, «toca... ¡y suelta!»). Si una hermana juega el turno de Maxi con su retrato: `arcoiris_batalla_torre_gigante_turno` | "Ñiiic" grave |
| GG4 | Vuelo (≈ 0,9 s, control de Semilla) | Cruza con una estela dorada. **Mientras vuela, los tres retratos de la barra inflan los cachetes** (como en K1): el momento es de Maxi, la fiesta es de los tres | — | "Fiuuu" grave |
| GG5 | Impacto | Salpicón doble en `gigante_objetivo`; **los tres retratos saltan juntos** (un salto de 60 px). Quita ≥ 12 de agarre: la torre queda "colgando de un dedo" y sigue el juego. Si con eso llega a 0 y `desde_soltar = true`, sigue la **variante A** de la anticipación (§4.1) | `arcoiris_batalla_torre_gigante_impacto` (1,6 s, «¡PLAAAF! ¡Globazo gigante!») | "Splat" doble al 70 % |

- El gigante **se queda** en todos los intentos siguientes (es el primer globo de cada uno) y la canasta
  sigue en 13: el último globo sigue siendo de Maxi.
- Sin Maxi (revancha `nicole+sofia`) no hay gigante: la ayuda 2 son +2 globos con `encontre_globos`.
- Como el gigante siempre se usa, **no existe el caso "ganaron sin usarlo"**: `no_lo_necesitamos` no se usa.

## 8. La pausa natural y la entrada a la partida

### 8.1 La pausa (aprobada por delegación del PO, re-auditoría UX decisión 2)

El cierre completo dura ≈ 6 min (§18) y viene después de una batalla de 18-20 min (ficha §16). Propongo
una pausa en el único lugar donde la historia la pide: **terminó la batalla y empieza el viaje**. Es
distinta de la pausa antes de la Torre (§3): aquella es la única **dentro** de la batalla; esta separa la
batalla del viaje. La UX la recomienda (decisión 2).

- **Pantalla de espera**: el estado final de M7. La nave brilla suave, el mapa flota encima (90 px), el
  ala envuelta está junto a la nave y Coco al lado. Se toca la nave entera (≥ 300 × 200 px); **nunca avanza
  sola** y la casa está a la vista.
- **El mapa que flota no es un tocable aparte (v4.1, P4)**: va dentro del target de la nave, así que
  tocar el mapa es tocar la nave (sigue a la partida, con la misma respuesta < 100 ms). El mapa flota
  sobre la nave, nunca fuera de su rect.
- **Voz**: `arcoiris_batalla_cierre_pausa_partida` (3,5 s), una vez.
- **Si salen**: el hito del Claro pasa al estado "partida" (ficha §13.4): la nave brillando con el mapa,
  con `arcoiris_despegue_hito` («¡La nave nos espera para el gran viaje! ¿Vamos, equipo?») como máximo
  una vez por visita, sin alertas ni parpadeo (M7.3).

### 8.2 Entrada (≈ 4 s)

**Si siguen desde la pausa** (los mismos de la batalla, sin ritual):

| Tiempo | Qué pasa | Voz |
|---|---|---|
| 0,0-0,5 | Al tocar la nave, la nave da un saltito y el ala envuelta brilla | — |
| 0,5-4,0 | Cometa se asoma, emocionado, con un casco de capitán | `arcoiris_despegue_intro` (3,5 s) |
| 4,2 | Vuelo del retrato de Maxi al centro (§9.1) | `nucleo_equipo_ahora_maxi` |

**Si retoman desde el hito** (otro día): `arcoiris_despegue_hito` → pantalla "¡todos a la nave!" corta
(`batalla_arcoiris.md` §3.3), donde se tocan **los tres retratos** (cualquiera puede tocar el de un
hermano que no está), con `nucleo_equipo_sube_nave_<hermano>` y, opcional, `yo_tambien_<hermano>`. Sin
botón "¡Despegar!": con los tres, sigue sola a los 0,8 s. A los 4 s sin toques,
`nucleo_batalla_todos_nave_corta`; si queda uno sin subir, `nucleo_batalla_falta_uno` (invita a subir la
carita, no dice quién falta). Después, `arcoiris_despegue_intro` y **el primer paso pendiente** (§16.3).

## 9. Preparativos (interactivo, sin fallo, ≈ 1,5 min)

### 9.1 Reglas comunes

- **Modo sin puerta** (como el epílogo): entre tareas suena `nucleo_equipo_ahora_<hermano>`. El orden es
  fijo: **Maxi → Nicole → Sofía**.
- **Misma estructura para los tres** (guion §4): instrucción de Cometa → el trabajo (Coco en cada toque)
  → momento especial → Cometa «¡… listo! ¡Gracias, (nombre)!» → el gesto canon del hermano, sin voz.
- **Cada tarea cierra igual**: `arcoiris_despegue_tanque_gracias`, `broches_gracias` o `ruta_gracias`
  (1,8 s cada una, misma forma y mismo tamaño de fiesta) y el gesto canon. Ya no hay "bombero / artista
  / capitana".
- **Tocar a Cometa repite la consigna** de la tarea en curso.
- **No se puede fallar**: un toque equivocado solo hace menear lo tocado, **sin voz ni "bup"**. La única
  excepción es el señuelo de la ruta de Sofía con un toque directo (su reto de lectura, ficha §13.5).
- **Nunca se traba**: recordatorios escalonados `_recuerda_01` (Cometa, 8 s), `_recuerda_02` (Coco,
  16 s, con pista visual) y `_ayuda` (Coco, 24 s; Maxi y Nicole), y después un cierre solo (abajo).
- **Equidad**: las celebraciones tienen el mismo tamaño y la misma frase.
- **Respuesta < 100 ms.** La casa siempre está activa: se guarda **por paso** (§16.3).
- **Dos hermanos + el retrato**: la tarea del que no está la hace cualquiera; Cometa le da las gracias a
  su retrato igual que a los otros (§16.4).

### 9.2 Layout común (1280×720)

| Elemento | Posición y tamaño |
|---|---|
| Cielo con el arcoíris de 3 bandas | Arco centrado en (640, 760), radios ≈ 560, 520 y 480 (por código) |
| **Nave-estrella** (3/4, nariz a la izquierda) | Casco en `Rect2(560, 150, 620, 420)`, apoyada en el pasto (N7, por capas) |
| Hueco del ala (donde Coco la encaja) | ≈ `Rect2(640, 330, 240, 120)` |
| **Tanque-caramelo** | Centro (1010, 205), ⌀ 150 px, con embudo en (1010, 125) (N8) |
| Coco | Pies en (560, 575), ≈ 170 px |
| Cometa / casa | `Rect2(8, 4, 110, 96)` / `Rect2(1172, 8, 100, 96)` |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` |
| Hermano en turno (rig de cuerpo entero, ≈ 280 px) | Pies en (330, 590) |

Todo lo tocable queda a ≥ 24 px de la casa, de Cometa y de la barra.

### 9.3 Maxi llena el tanque (≈ 22 s)

**Maxi quiere ser bombero**: él sostiene la boquilla de una manguera de 3 franjas que sale de un balde de
pintura arcoíris en (120, 540). La boquilla está en (430, 430), con un halo de **⌀ 220 px**. **Toda la
pantalla cuenta como toque**, salvo la casa, Cometa y la barra.

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| MX1 | 0,0-2,5 | La boquilla respira | `arcoiris_despegue_tanque_instruccion` (2,5 s) | — |
| MX2 | **6 toques** | El rig recula con el tirón, un chorro de color cruza en arco hasta el embudo (0,7 s), el tanque sube una franja y la nave se ríe de cosquillas. Un toque durante un chorro queda en cola (máximo 1) | Toques 1-3: `arcoiris_despegue_tanque_color_rojo`, `_amarillo` y `_azul`. Toque 4 (la mitad): `arcoiris_despegue_tanque_glu` (2 s). Toques 5-6: sin voz (amarillo y azul, solo música) | "Fshhh" con una nota que sube |
| MX3 | 3,0 s | El tanque lleno brilla. **Gag: anticipación de 0,6 s** (la nave se infla al 110 %) y **la nave estornuda burbujas de jabón** de 3 colores (8, de ⌀ 100-130 px, que suben 4 s). **Aire de 0,4 s** y después la voz. **Las burbujas se pueden reventar** (premio de cualquiera) | `arcoiris_despegue_tanque_lleno` (2,2 s, «¡Blup! ¡Tanque lleno... y hace burbujas!»), después del estornudo | Estornudito de juguete (70 %), pops con nota |
| MX4 | 2,6 s | — | `arcoiris_despegue_tanque_gracias` (1,8 s) y el gesto de Maxi (0,8 s) | "Tilín" azul |

**Ayudas**:

- a los 8 s, `arcoiris_despegue_tanque_recuerda_01` (Cometa), con la boquilla latiendo más grande;
- a los 16 s, `arcoiris_despegue_tanque_recuerda_02` (Coco): **la manguera baila**;
- a los 24 s, `arcoiris_despegue_tanque_ayuda` (Coco, «¡Lo hacemos juntos, Maxi!»): **la manopla de Coco
  toca la boquilla al ritmo, un chorro cada 4 s**, hasta llenar el tanque. Cualquier toque de Maxi (o de
  quien sea) suma un chorro más.

**Colores**: los 3 recuperados, con 6 toques (puente de 3 bandas; guion §9.2 retira los demás).

### 9.4 Nicole gira los 3 broches de color; Coco encaja el ala (≈ 27 s)

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
**v4 (m10; ficha §13.5)**: **Coco encaja el ala** (nadie "instala" el ala que ganó otro) y Nicole **gira
los 3 broches por el color que pide Coco**. Un objetivo a la vez, sin fallo.

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| NI0 | 0,0-3,0 | Maxi sale caminando y entra Nicole. **Coco trae el ala envuelta para regalo, cargándola en la cabeza** (280 × 170 px, moño arcoíris), tira del moño, el papel **estalla en confeti** y aparece el ala a franjas pastel con **la firmita de Coco** en la punta. Coco la encaja en el hueco ("clonc"), pero **queda floja**: cuelga 6° y se mece (gag chiquito que pide los broches). Zoom suave 1,0 → 1,12 hacia el costado de la nave | `nucleo_equipo_ahora_nicole` (al empezar) | Pasitos, "fiu" de confeti y "clonc" acolchado |
| NI1 | 3,2-6,2 | Aparecen **3 broches dorados**, cada uno con **una piedrita de color** (roja, amarilla y azul; **se reparten al azar** entre las 3 posiciones en cada partida). Targets de **⌀ 110 px** en pantalla (con el zoom) en **(640, 300), (640, 440) y (790, 520)**: 30 px o más entre ellos y 35 px sobre la barra | `arcoiris_despegue_broches_instruccion` (3 s, «¡Nicole, gira los broches dorados! Coco te dice cuál.») | Tres "tin" al aparecer |
| NI2 | Por broche (×3) | **Coco pide uno**: el broche nombrado **respira** (escala 1,0 ↔ 1,1) desde el inicio de la voz; se puede tocar mientras Coco habla. **Al tocar el pedido**: gira dos vueltas (0,5 s), su piedrita destella, **el ala se afirma un poco** (cuelga 4°, 2° y 0°) y se enciende una franja, de la raíz a la punta. **Si toca otro broche**: ese broche se menea 0,2 s, **sin voz ni "bup"**, y no pasa nada más. Aire de 0,3 s antes del pedido siguiente | `arcoiris_despegue_broches_pide_rojo` (1,2 s) → `_pide_amarillo` (1,3 s) → `_pide_azul` (1,6 s), siempre en ese orden; al girar, `arcoiris_despegue_broche_1`, `_2` y `_3` | "Cric-cric" y "¡tin!", con una nota que sube |
| NI3 | 2,4 s | El ala completa brilla. **La nave aletea una vez con su única ala**, da un saltito... y **se ladea 8°**, como un pájaro chueco. **Aire de 0,4 s** para la risa | `arcoiris_009` (2 s, «¡La primera pieza! Miren cómo le queda a la nave.», reubicada aquí por el PO) | "Flap" y "boing" |
| NI4 | 4,0 s | En «¡Upa!» **Coco la endereza con la cola**; en «...¡Ahora soy rosado de emoción!» se pone rosada con las manos al pecho | `arcoiris_despegue_broches_ala` (3,8 s) | Risitas |
| NI5 | 2,8 s | El zoom vuelve a 1,0 | `arcoiris_despegue_broches_gracias` (1,8 s) y el gesto de Nicole (0,8 s) | "Tilín" rosado |

**Ayudas** (el reloj cuenta desde el último broche girado):

- a los 8 s, `arcoiris_despegue_broches_recuerda_01` (Cometa) y el broche pedido late más grande;
- a los 16 s, `arcoiris_despegue_broches_recuerda_02` (Coco): **el broche pedido salta y crece**;
- a los 24 s, `arcoiris_despegue_broches_ayuda` (Coco, «Tú tocas, yo sujeto»): Coco sujeta el ala con la
  cola y apunta al broche con la manopla;
- **a los 32 s** (confirmado en la ficha §13.5): la cola de Coco gira el broche pedido y suena igual su
  `broche_<n>`. Nicole no "lo hizo mal".
- **v4.1, por delegación del PO (ficha §13.5)**: **si Coco ya giró un broche sola**, en los broches
  siguientes no se repite la escalera de 8/16/24/32 s: hay **un único recordatorio a los 6 s**
  (`broches_recuerda_02`, el broche pedido salta y crece) y **el broche gira solo a los 12 s**. Así una
  Nicole que se fue no deja la ceremonia esperando ≈ 1,5 min.

**Tras la llave de padres** (`forzada`, ficha §13.4): el ala ya se ve puesta y firme; NI0 se reduce a Coco
dando unas palmaditas al ala (sin envoltorio ni encaje) y la tarea son igual los broches de color (NI1-NI5).

### 9.5 Sofía traza la ruta: A-N-I-M-A-L-I-A y el perrito (≈ 35 s, más el dato opcional)

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| SO0 | 0,0-1,8 | El retrato de Sofía salta y **el mapa del Coleccionauta vuela de su retrato a la cúpula**. Iris a la **pantalla de navegación** | `nucleo_equipo_ahora_sofia` | "Fiuu" e iris |
| SO1 | 2,0-6,0 | La pantalla de navegación; el punto de partida (Arcoíris) late | `arcoiris_despegue_ruta_instruccion` (4 s, «...¡A-ni-ma-lia!», por sílabas) | — |
| SO2 | 8 estrellas | **Toque directo** (`press` sobre una estrella): la correcta siguiente se enciende, una línea de luz se dibuja desde la anterior (0,25 s) y la letra crece a 1,2×; un señuelo o una correcta fuera de orden da un "bup" amable y se menea 0,2 s, sin línea y sin voz. **Con el dedo en arrastre** (M11): **solo cuenta la correcta siguiente** cuando el dedo entra en ella; las demás se iluminan apenas al pasar, **sin "bup"** y sin contar. La línea se dibuja solo entre estrellas encendidas, nunca hasta el dedo | **Pista** (tras 2 toques equivocados seguidos, o al tocar a Cometa después de la instrucción): `arcoiris_despegue_ruta_sigue_<letra>` (a, n, i, m o l), **siempre junto con el latido de la estrella correcta** (m9). **Después de la 4.ª estrella, una vez**: `arcoiris_despegue_ruta_dato` (5 s), sin cortar el juego | **La melodía de la ruta**, una nota por estrella |
| SO3 | 3,6 s | Con la 8.ª, la línea llega a Animalia, que se enciende en verde con su huellita. **La constelación se vuelve un perrito**: las líneas se redondean y le salen orejas caídas y cola (0,6 s, morph por código). En «¿perrito?» **ladra** ("¡guau!") y **menea la cola**; aire de 0,3 s | `arcoiris_despegue_ruta_forma` (Coco, 3 s, «¡Miren la ruta! Tiene forma de... ¿perrito?») | "¡Guau!" de cachorrito, después de la voz |
| SO4 | 2,2 s | **Las 8 letras bajan y forman "ANIMALIA"** (y ≈ 520), que se ilumina letra por letra | `arcoiris_despegue_ruta_animalia` (2 s) | "Do" agudo |
| SO5 | 2,6 s | — | `arcoiris_despegue_ruta_gracias` (1,8 s) y el gesto de Sofía (0,8 s) | Fanfarria corta |
| SO6 | 0,6 s | Iris de vuelta al Claro: **la cúpula muestra el perrito-ruta brillando** y la estrellita de la antena parpadea en verde | — | — |

**Layout de la pantalla de navegación**:

| Elemento | Posición y tamaño |
|---|---|
| Marco de consola turquesa con remaches dorados | Pantalla completa, borde de 40 px (por código) |
| **Campo de estrellas** (v4, M10; ficha §13.5) | `Rect2(150, 128, 980, 440)`: 32 px de Cometa, 42 px de la casa y 40 px del mapa |
| Arcoíris (partida, no tocable) | Centro (205, 350), ⌀ 110 px |
| Animalia (destino, no tocable) | Centro (1070, 330), ⌀ 120 px, verde apagado hasta SO3 |
| **8 estrellas de la ruta: A, N, I, M, A, L, I, A** | Estrella dibujada de 64 px, **target de 96 px**, letra Baloo de 36 px, **≥ 24 px de borde a borde** con cualquier otra. De izquierda a derecha en zigzag (el sentido de lectura resuelve las letras repetidas); sus posiciones ya anticipan el perrito |
| **5 estrellas señuelo: O, E, U, S y R** | Mismas medidas, intercaladas, a ≥ 24 px de cualquier otro target |
| Mapa del Coleccionauta (referencia) | `Rect2(540, 8, 200, 80)`. Tocarlo lo agranda 2 s |
| Sin barra | **Nada tocable por debajo de y 696** |

**Ayudas**: a los 8 s sin una estrella correcta, `arcoiris_despegue_ruta_recuerda_01` (Cometa) y **la
estrella siguiente late**; a los 16 s, `arcoiris_despegue_ruta_recuerda_02` (Coco) y **la estrella
siguiente guiña** y sigue latiendo hasta que la toquen (nunca se traba: la respuesta queda a la vista).
Sin reloj ni puntaje. **Si es "de bebés"**: 8 señuelos o un orden que no sea de izquierda a derecha. **Si
la frustra**: que la estrella siguiente lata desde los 4 s.

### 9.6 Fin de los preparativos (≈ 2 s, sin voz)

La nave lista (tanque lleno, ala puesta y firme, perrito en la cúpula) da un saltito y brilla (0,8 s).
Coco se acerca al centro dando saltitos y junta las manoplas detrás de la espalda, pícara: esconde algo
(1,2 s). Es el puente visual a los regalos; el guion v4 no tiene voz aquí.

## 10. Despedida de Coco (interactiva, ≈ 40 s)

**Un "hasta pronto", nunca triste.** La barra se oculta. Los tres hermanos (rigs de ≈ 260 px) están en
fila frente a la nave, con los pies en (380, 590) Maxi, (600, 590) Nicole y (820, 590) Sofía. Arriba, el
**ícono del hangar** en `Rect2(1060, 8, 96, 96)`: no es tocable, es el destino de los regalos.

**Por hermano** (Maxi → Nicole → Sofía), ≈ 10 s cada uno:

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| D1 | 0,0-0,8 | Coco va a saltitos hasta el hermano, que recibe el foco | — | "Boing" chico |
| D2 | 0,8-6,3 | Coco saca el regalo de detrás de la espalda; **pop con chispitas** y el regalo flota a las manos del hermano. La reacción: Maxi salta, Nicole lo abraza y Sofía lo mira de cerca y sonríe. En «¡Choca esos cinco!» **Coco levanta la manopla**: target de **⌀ 200 px para Maxi** y **⌀ 150 px para Nicole y Sofía**, a y ≈ 380 | `arcoiris_despegue_coco_regalo_<hermano>` (5 s; Sofía 5,5 s), que ya termina en «¡Choca esos cinco!» | "Tilín" del color del hermano |
| D3 | Toque | **La manopla se activa cuando termina la voz del regalo** (m5): un toque antes solo la hace menear, sin avanzar. **Choque de cinco**: las manos se juntan (0,3 s), estallan estrellas y **Coco se pinta del color del hermano** (Maxi `#4aa8ff`, Nicole `#ff5fae`, Sofía `#4fd8e0`) | `arcoiris_despegue_coco_choca_<hermano>` (2 s, «¡Pa! Ahora soy... ¡azul Maxi!») | "¡PA!" y campanitas |
| D4 | 0,6 s | **El regalo vuela al ícono del hangar** | — | "Fiu" |

**Los regalos** (aprobados por el PO): **T-rex de gomita** (Maxi), **corazón rosado chicle** (Nicole) y
**pony turquesa con crin de arcoíris** (Sofía). Los tres en un cuadro de 120 px, con el mismo peso visual.

**Cualquiera puede tocar** la manopla una vez activa, y el choque cuenta para el hermano que brilla.

**Sin toque** (desde que la manopla se activa):

- a los 8 s, `arcoiris_despegue_coco_choca_recuerda` («¡Mi manito te espera! ¡Choca!») y la manopla se
  menea;
- **a los 20 s**, con cualquiera de los tres, **Coco le choca la manito ella misma**, despacito, y suena
  igual `coco_choca_<hermano>`. Nadie "lo hizo mal". (Ya no hay abrazo con voz.)

**Después de los tres**:

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| D5 | 0,0-2,0 | Coco abraza a Cometa. **El álbum de abrazos de Cometa se abre solo y aparece una estampita de Coco** | — (sin voz, guion §5) | "Tilín" y "fssh" |
| D6 | 2,2-7,7 | Coco al centro **se pinta entera de arcoíris** y se despide con la cola en espiral, con un bailecito. En «¡soy yo, saludándolos!» mira a la cámara | `arcoiris_despegue_coco_cierre` (5,5 s) | Marimba de Coco, tierna y con ritmo |
| D7 | 7,9-10,4 | Los tres regalos brillan en el ícono del hangar | `arcoiris_despegue_hangar` (2,5 s) | Campanita triple |

## 11. La foto y la video-llamada de papá (≈ 12 s + ≈ 31 s)

Son B5-B7 de `batalla_arcoiris.md`, movidas a la partida (guion v4 §6). La llamada ya no es opcional.
**`papa_02` queda retirada**: el Coleccionauta va a Animalia, no a la casa de papá. La numeración V1-V8
coincide con la del guion.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| V1 | 0,0-3,0 | Los tres rigs en fila frente a la nave, Cometa al centro | Cometa, sorprendido, mira al cielo | `arcoiris_batalla_cierre_foto` (3 s) | — |
| V2 | 3,0-≈ 13,0 (+ espera ≤ 6 s) | **Entrega de la foto con el flujo del álbum** (`album-recuerdos.md` §6) | El sobre-estrella baja girando (1,2 s) y queda en el centro, **latiendo, con un target de ≥ 200 px**, `Rect2(540, 220, 200, 200)`. **Se abre con un toque de cualquiera (< 100 ms) o solo a los 6 s** (v4.1, N2; antes 3 s). Sale la foto de los tres en la polaroid estelar al 70 %, suena **el audio familiar que elige el PO** (≈ 5 s) y la foto vuela al ícono del álbum (1 s) | El audio familiar (PO) | Confeti suave y "clic" de polaroid |
| V3 | 0,0-4,6 | La nave | **Abordaje**: los tres rigs saltan a la cúpula (pop, 0,4 s cada uno) y Cometa entra al asiento del piloto (1,8 s). Después Cometa guiña y señala la antena | `arcoiris_010` (2,5 s, «¡Sorpresa! Alguien quiere saludarlos.») | Pops (do, mi, sol) |
| V4 | 4,6-5,2 (+ espera ≤ 5 s) | La antena y un **teléfono-estrella** | **"Contestar" la llamada** (v4.1, N2): la antena vibra con un "ring-ring" de juguete y aparece un **teléfono-estrella dorado de ≥ 200 px**, `Rect2(540, 200, 200, 200)`, que late y se sacude con cada ring. **Al tocarlo cualquiera** (< 100 ms) da un saltito y se abre la **pantalla-burbuja** desde la antena, en `Rect2(240, 70, 800, 450)`. **Si nadie toca, se abre sola a los 5 s.** Los tiempos de V5-V9 cuentan desde que se abre | — | "Ring-ring" (entre 2 y 3 veces) y "tin" |
| V5 | 5,4-9,4 | Papá (motion comic) | Rebota con la risa; a su lado aparece **la misma polaroid de los tres** que acaban de recibir, chiquita | `arcoiris_batalla_cierre_papa_01` (4 s) | El tema del mapa, suave |
| V6 | 9,7-18,7 | Papá y una **burbuja de recuerdo** a su lado | En «recién me llamó el Coleccionauta, todo contento y pintado» aparece en la burbuja **el Coleccionauta con lunares hablando por un teléfono-caracol**, que **se palpa los bolsillos y los da vuelta** (busca su mapa: lo tienen los niños). En «¡Va camino a Animalia!» la burbuja muestra la **huellita** del mapa. En «ladridos» se mueve una **huella de perrito**; en «¡GRRR!» aparece una **huella de dinosaurio simpática** (para Maxi; nunca da miedo); en «¿Rugidos?» papá levanta las cejas | `arcoiris_batalla_cierre_papa_pista` (9 s) | Un "guau" y un "grr" de juguete **entre frases**, nunca encima de la voz |
| V7 | 18,9-22,4 | Papá | La burbuja se desinfla con un "plop"; imagen A9 "papá riéndose", **sobándose la guata** | `arcoiris_batalla_cierre_papa_guatita` (3,5 s) | Un "grrr" de guatita, chistoso, después de la voz |
| V8 | 22,7-29,7 | Papá | Chiste del arcoíris; en «Los quiero mucho» **se abraza a sí mismo** | `arcoiris_batalla_cierre_papa_03` (7 s) | — |
| V9 | 29,7-30,5 | — | La pantalla se cierra en destellos dorados | — | Destellos |

- **Duración única de la llamada (v4.1, P2): ≈ 31 s** (V3-V9, de 0,0 a 30,5), más la espera del
  teléfono (≤ 5 s). Es la cifra que usan también el §2 y el §18.
- **Tramos sin tocar del bloque 2 (v4.1, N2)**: antes eran ≈ 54 s seguidos (D5-D7 + foto + llamada).
  Ahora quedan partidos por dos toques: ≈ 14 s (D5-D7, V1 y la bajada del sobre) → **toque al sobre** →
  ≈ 12 s (foto, audio familiar y abordaje con `arcoiris_010`) → **toque al teléfono** → ≈ 25 s (papá).
  El tramo pasivo más largo del bloque 2 baja a ≈ 25 s. **Si Maxi se va ahí**, el primer recorte es `papa_guatita` (V7), que es un
  archivo aparte.
- No tiene reemplazo TTS: es la voz de papá. Mientras no esté grabada, se usa un placeholder marcado como
  tal.
- La foto es de los tres aunque se juegue con dos hermanos y el retrato del tercero: es la del álbum.

## 12. Cuenta regresiva de a uno y despegue (≈ 10 s + toques + ≈ 14 s)

### 12.1 Cuenta regresiva: Sofía → Nicole → Maxi, un retrato a la vez (≈ 10 s + toques)

**Decidida por delegación del PO** (UX decisión 6; ficha §13.5). Ya no existe "en cualquier orden": un
foco por momento, Sofía abre como capitana y el «¡Uno!» y el despegue son de Maxi.

**Composición**: la barra se oculta. La nave con las caras en la cúpula y Cometa en el asiento del piloto.
Los retratos, grandes y **fuera de la nave** (ficha §13.5), con ≥ 24 px entre ellos, de la nave y de
Cometa:

| Retrato | Rect | Número |
|---|---|---|
| Sofía | `Rect2(40, 130, 160, 160)` | 3 |
| Nicole | `Rect2(40, 314, 160, 160)` | 2 |
| **Maxi** | **`Rect2(230, 400, 200, 200)`** (≥ 200 px) | 1 |

Sobre la nave, **3 estrellas** (⌀ 120 px, no tocables) en (520, 120), (640, 100) y (760, 120), con el 3,
el 2 y el 1 adentro.

| # | Qué pasa | Voz | SFX |
|---|---|---|---|
| CR0 | Las estrellas apagadas; los tres retratos respiran suave | `arcoiris_despegue_cuenta_instruccion` (3,5 s, «...cuando brille tu carita, ¡tócala!») | — |
| CR1 | **Brilla solo el de Sofía** (halo de su color y escala 1,0 ↔ 1,08). Al tocarlo salta, **enciende la estrella "3"** y la nave tiembla 2 px | `arcoiris_despegue_cuenta_tres` (o `cuenta_tres_sofia`, niños) | Pop (do) |
| CR2 | Brilla el de Nicole: enciende el "2"; la nave tiembla 4 px | `arcoiris_despegue_cuenta_dos` (o `cuenta_dos_nicole`) | Pop (mi) |
| CR3 | Brilla el de Maxi: enciende el "1"; la nave tiembla 6 px | `arcoiris_despegue_cuenta_uno` (o `cuenta_uno_maxi`) | Pop (sol) y un "brrr" que crece |
| CR4 | Las toberas se encienden; los retratos se achican y vuelan a la cúpula | `arcoiris_despegue_cuenta_motores` (2,2 s, «¡Motores encendidos! Brrrum...») | "Brrrum" |

- **Tocar un retrato que no brilla no es un error**: salta y se ríe (< 100 ms), **sin "bup" y sin
  avanzar la cuenta**. Nadie le "roba" el número a otro.
- **Esperas** (por retrato): a los **8 s** sin toque, `arcoiris_despegue_cuenta_recuerda` («¡Tu carita
  está brillando! ¡Tócala!») y el halo crece; si nadie toca, **el retrato salta solo a los 20 s** (Sofía y
  Nicole) y **a los 15 s** (Maxi), con su gesto y su número, como si lo hubieran tocado.
- **Dos hermanos + el retrato**: el retrato del que no está lo toca cualquiera, o salta solo. Ninguna voz
  lo nombra.
- No suenan `nucleo_equipo_despegar` (cuenta sola) ni `arcoiris_despegue_coco_espera` (retirada).

### 12.2 Despegue por el puente de 3 bandas (≈ 12,5 s)

La barra se oculta; la casa queda a la vista.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| DS1 | 0,0-2,5 | La nave | Sube 80 px tambaleándose de emoción y suelta chispitas de 3 colores; el "¡despegue!" largo coincide con el despegue. Coco, abajo, se despide con la cola | `arcoiris_despegue_vuelo_despegue` (2,5 s, «¡Cinturones puestos... y despegue!») | Tema de Arcoíris en versión fiesta, a tempo de viaje |
| DS2 | 2,5-4,3 | — | La nave (escala ≈ 0,35, ≈ 200 px) vuela al **pie izquierdo del arcoíris** y **se posa en la banda amarilla** | — | "Plin" |
| DS3 | 4,3-8,3 | **El puente** (rojo, amarillo y azul) | Recorre el arco completo (`Path2D` sobre el radio 520, de 175° a 5°, 4 s, ease in-out). La rotación sigue la tangente, con tope de ±35°. **Cada tramo suena como una tecla de xilófono** y deja una estela. **En la cima** (≈ 6,0 s), las caras gritan de alegría | `arcoiris_despegue_vuelo_puente` (2,2 s, «¡Wiiii! ¡Por el puente arcoíris!»), empieza en la cima | Glissando de xilófono, bajo la voz |
| DS4 | 8,3-10,3 | El extremo derecho | **La punta se curva como rampa** y lanza la nave al cielo | — (solo SFX) | "¡Boing-fiuuu!" |
| DS5 | 10,3-13,3 | El cielo | La nave se vuelve **estrella fugaz** y el cielo se funde a noche. Coco, chiquitita abajo, saluda con la cola y **se pone de un color inventado** (lunares de los tres colores de los hermanos) | `arcoiris_despegue_vuelo_coco_chao` (3 s, «...¡color buen viaje!») | Brillo de estrella fugaz |
| DS6 | 13,3-13,8 | — | Iris al Mapa Estelar | — | "Fiuu" |

## 13. Mapa Estelar: Animalia se enciende (≈ 12 s)

Sobre `mapa_estelar.gd`: Arcoíris en (318, 478) y Animalia en (530, 290). **Final decidido por
delegación del PO**: termina en el Mapa Estelar con **Animalia encendida**, sin encadenar el viaje.

### 13.1 Antes de la partida (M9; ficha §13.4)

Mientras `partida_hecha("arcoiris")` sea `false`, cualquier hermano que abra el Mapa Estelar ve:

- **Animalia lejana y desenfocada** (sprite `animalia_lejana`, N18), **sin candado**, sin gris de
  "bloqueado" y sin "bup";
- **al tocarla responde en < 100 ms**: late una vez (escala 1,08 y vuelta, 0,25 s) con un "tilín" suave;
- Cometa dice `arcoiris_despegue_mapa_animalia_antes_01` («¡Animalia! ¿Oyeron ese "guau"?...») o `_02`
  («¡Shhh! Animalia está durmiendo la siesta...»), **alternadas entre visitas** y **como máximo una por
  visita**; en `_01`, tras «¿Oyeron ese "guau"?», Animalia late con un "guau" chiquito; en `_02`, le
  salen tres "zzz" de nubecita. Los toques siguientes solo hacen el latido;
- **una flechita de luz** va de Animalia a Arcoíris (2 s) y Arcoíris respira: muestra adónde ir.

### 13.2 La llegada después del despegue

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| ME1 | 0,0-1,0 | El mapa | **La nave, ya con su ala** (N13), sale de Arcoíris con estela de arcoíris y hace un loop | — | "Fiuuu" |
| ME2 | 1,0-3,0 | El tramo Arcoíris → Animalia | **Se enciende estrella por estrella** (8 destellos). Queda guardado en `equipo.rumbos` | — | **La melodía de la ruta** |
| ME3 | 3,0-4,0 | Animalia | **Se enfoca y se enciende a todo color** (de `animalia_lejana` a `animalia`, fundido de 0,6 s) y late dos veces con la huellita. **Pasa en las dos ramas**: es el premio visible de la partida | — | Campanita y un "guau" chiquito |
| ME4 | 4,0-8,5 | La nave | **Rama A** (el capítulo 2 no existe): la nave **avanza al 25 % de la ruta** y queda "en camino", meciéndose. **Rama B**: la nave queda "en rumbo" junto a Arcoíris, con la nariz hacia Animalia | Rama A: `arcoiris_despegue_vuelo_lejitos` (4,5 s). Rama B: `arcoiris_despegue_vuelo_rumbo_animalia` (3 s, «¡Próxima parada: Animalia! ¡Cuando quieran, partimos!») | — |
| ME5 | 8,7-12,0 | El mapa entero | **Fuegos artificiales** sobre Arcoíris; **los tres retratos asoman abajo al centro** (≈ 160 px) y hacen su gesto por turno (0,8 s cada uno). El mapa se vuelve interactivo | `arcoiris_despegue_vuelo_celebra` (2,5 s) en las dos ramas (en la B, después de `vuelo_rumbo_animalia`). Tras la llave de padres, sin voz | Acorde final y el tema del mapa |

- **Cierre en celebración, nunca en corte** (GDD §3).
- **Rama A**: después, al tocar Animalia suena `arcoiris_despegue_mapa_animalia_lejitos` (como máximo una
  vez por visita; los demás toques, solo el latido).
- **Rama B**: **no** se encadena el viaje Galaga; la próxima vez cualquier hermano toca Animalia y parte.
- **Tras la llave de padres** (m8; `forzada` y la ceremonia recién hecha): el rumbo ya estaba encendido.
  ME1 → la nave hace el loop → `arcoiris_despegue_vuelo_de_vuelta` (3 s, «¡Nave lista y con ala nueva! ¡De
  vuelta a Animalia!») → ME5 sin voz. **Sin ME2 ni ME3** (no hay "¡rumbo nuevo!").

## 14. La revancha: lo mínimo que se repite

La ficha v3 (§11 y §11.1) fija que **en la revancha se rejuega solo la Torre**, con la partida ya hecha,
y que se puede jugar con dos hermanos. Propongo repetir **lo mínimo**:

| Pieza | En la revancha |
|---|---|
| Presentación de la Torre (§3) | No (va directo a `arcoiris_batalla_torre_intro_revancha` y a la intro corta) |
| Derrotas-gag (§7) | Sí, con el conteo reiniciado (1, 2, 3, 4…) |
| Anticipación (§4.1) | **Sí, entera**: es el desenlace de la jugada y no se salta |
| Caída (§4.2), C1-C5 | **Sí**, y se salta con un toque (ya vista) |
| C6, la fiesta máxima | **Sí, como mini fiesta**: confeti, los retratos saltan y `cae_risa` (es parte de la caída) |
| Estrellitas y récord | **Solo con los tres retratos** (ficha §11.1): `nucleo_equipo_lanzar_estrellitas_1..3`, la banderita, `torre_record` y `emparejar_equipo_primer_record`. **Con dos hermanos no suenan ni se ven**: ni estrellas, ni banderita, ni récord. Así nunca hay un récord de una pareja contra otra |
| Antes del epílogo, epílogo, cierres A y fiesta, parte C, pausa y partida | **No** |
| Salida | Iris de vuelta al mapa del planeta, con el Coleccionauta todavía sentado en el charco saludando. **Sin voz, a propósito** (guion T.9) |

## 15. Notas sobre la escena del ala (Beat 2, `escena_planeta_arcoiris.md`)

`arcoiris_009` se fue a NI3 (§9.4). En el Beat 2, según el estado **familiar** del ala, suena una de dos
líneas, y **las dos tienen la misma fiesta, del mismo tamaño** (v4, M8.4; GDD §6.9):

| Paso | `arcoiris_009a` (ceremonia pendiente) | `arcoiris_009b` (ceremonia ya hecha) |
|---|---|---|
| Qué pasa | Coco entrega el ala **envuelta para regalo**, que **queda junto a la nave**. El hueco no se llena: solo brilla un poco más, como diciendo "ya casi" | La nave **ya tiene el ala**. No hay entrega de algo que ya está puesto |
| 1. Destello (0,6 s) | **El ala envuelta destella** (el moño brilla) | **El ala destella en su lugar** |
| 2. Loop (1,2 s) | **La nave hace un loop** con estela de arcoíris y vuelve a su lugar | Igual |
| 3. Gesto (0,8 s) | **El gesto canon del hermano** (su rig), con confeti | Igual |
| Voz | `arcoiris_009a` (5 s, «...la ponemos todos juntos antes del gran viaje.») | `arcoiris_009b` (4,5 s, «...¡y este pedacito de brillo lo ganaste tú!»), sin "también" ni "ahora" |

En `009b`, el "pedacito de brillo" se ve: en «lo ganaste tú» **una chispa sale del ala y vuela al retrato
del hermano**. Nadie compara con quien llegó antes.

## 16. Saltar, "ya vista" y retomar

### 16.1 Qué se puede saltar (por familia; se marca al terminar)

| Pieza | Id | Desde la 2.ª vez, un toque deja… |
|---|---|---|
| Presentación de la Torre | `arcoiris_batalla_final:presenta_torre` | La intro |
| Anticipación | — | No se salta (un toque se encola para la caída) |
| Caída | `arcoiris_batalla_final:caida_torre` (lo marca `batalla.gd` con `momento_saltable_terminado`) | El estado final del §4.2 |
| Derrotas-gag | — | "¡Otra vez!" las corta desde la 1.ª vez |
| Antes del epílogo, cierre A y fiesta | Los de `batalla_arcoiris.md` §12.3 | Ídem |
| Parte C, el mapa | `arcoiris_batalla_final:mapa_coleccionauta` | La pausa, con el mapa en el retrato de Sofía |
| Preparativos, despedida de Coco y cuenta | — | Se juegan |
| Foto | — | Se entrega una sola vez (flujo del álbum) |
| Video-llamada | `arcoiris_partida:llamada_papa` (id de "vista", no de voz) | La cuenta regresiva |
| Despegue | `arcoiris_partida:despegue` | Iris al Mapa Estelar |
| Mapa Estelar | `arcoiris_partida:llegada_estelar` | El mapa interactivo, con la nave en rumbo |

Los ids `arcoiris_partida:*` son marcas de "ya vista" de la escena `partida_arcoiris.tscn`; las voces del
bloque 2 son todas `arcoiris_despegue_*`.

### 16.2 La partida se ve una sola vez

Está en `equipo.partidas.arcoiris` (ficha §13.4): `hecha`, `ceremonia` y `forzada`.

- **La llave de los padres** (`forzar_partida`) deja la nave lista **sin ceremonia**. Si después ganan la
  batalla, el bloque 2 se juega igual una vez (m8):
  - el paso "ala" se da por hecho: el ala ya se ve puesta y Nicole gira igual los broches de color (§9.4,
    variante `forzada`);
  - se juegan los preparativos, la despedida de Coco, la foto, la llamada y la cuenta;
  - el final cambia a `vuelo_de_vuelta`, sin ME2 ni ME3 (§13.2).

### 16.3 Retomar la partida

- **Cuándo se guarda**: al terminar cada paso (`tanque`, `ala`, `ruta`, `despedida` y `llamada`; la foto
  va dentro de `llamada`).
- **Al volver**: desde el hito de partida, el ritual corto (§8.2) y **se sigue en el primer paso
  pendiente**. Lo hecho se ve hecho.
- **Si salieron a medias**:
  - durante la foto o la llamada, la llamada se repite entera (la foto no se vuelve a entregar si ya está
    en el álbum);
  - durante la cuenta o el despegue, se retoma en la cuenta.

### 16.4 Dos hermanos + el retrato del tercero: ninguna espera sin salida

El juego no sabe quién está físicamente (regla 12 del §0). Cada espera del cierre se resuelve sola o la
puede resolver cualquiera:

| Momento | Quién puede tocar | Si nadie toca |
|---|---|---|
| Pausa antes de la Torre y pausa entre bloques | Cualquiera | Esperan a propósito (son pausas); la casa está a la vista |
| Turnos de la Torre | El del turno, o un hermano con el perfil del ausente (`modo-equipo.md` §14.7) | `semilla_auto_s` (20 s) en el de Maxi; el motor sustituye las voces con nombre por las neutras (guion T.2) |
| Parte C, el papel (M1) | Cualquiera | Sigue solo a los 6 s |
| Tanque, broches, ruta | Cualquiera | Ayudas escalonadas y cierre solo (§9.3-§9.5) |
| Choque de cinco | Cualquiera, cuando termina la voz del regalo | Coco choca ella misma a los 20 s |
| Choque de manos de la fiesta (B3) | Cualquiera | Chocan solas a los 4 s |
| Sobre de la foto | Cualquiera | Se abre solo a los 6 s |
| Teléfono-estrella de la llamada (V4) | Cualquiera | Se abre solo a los 5 s |
| Mapa sobre la nave en la pausa | Cualquiera (es parte del target de la nave) | Es pausa: espera |
| Cuenta regresiva | Cualquiera (el retrato que brilla) | Salta solo a los 20 s (hermanas) / 15 s (Maxi) |
| "¡Todos a la nave!" al retomar | Cualquiera, los tres retratos | `todos_nave_corta` y `falta_uno`, que invitan sin nombrar a nadie |

Las líneas con nombre que no son de turno (`coco_regalo_<hermano>`, `*_gracias`) le hablan al retrato
del dueño de la tarea, igual que si estuviera: nunca dicen que falta.

## 17. Música y SFX (CC0: Kenney o FreePD)

- **Anticipación**: la música se apaga. **El silencio de K4 es parte del diseño** (0,8 s).
- **Caída**: SFX graves y estirados, un splash redondo y **la fanfarria más grande del planeta** en C6.
- **Derrotas-gag**: un instrumento por gag (cumbia de kazoo, estornudo, silbido que baja y chicle). Nunca
  un golpe sin anticipación, y todo al 70 %.
- **Charco**: un "chof" y una ondita cada vez que crece.
- **La melodía de la ruta**: escala de do ascendente (8 notas, celesta). Suena **tres veces**: en el mapa
  (M4), en la ruta de Sofía (SO2) y en el Mapa Estelar (ME2). Es el hilo musical de Animalia.
- **Gag 1**: la cumbia de kazoo **se corta en seco** con el ¡plof! del frasco (≤ 2,5 s).
- **Preparativos**: el tema de Arcoíris tranquilo, a −8 dB.
- **Despedida de Coco**: marimba tierna y con ritmo, sin violines tristes.
- **Despegue**: el tema en versión fiesta y el glissando de xilófono en el puente.
- **Ducking**: −8 dB con cualquier voz. Los SFX de la llamada van entre frases.

## 18. Duraciones (estimadas, primera vez)

| Pieza | Duración | Se salta |
|---|---|---|
| Pausa antes de la Torre (`pausa_antes`) | 3,3 s de voz; espera un toque | Es pausa |
| Presentación de la Torre (antes de la etapa) | ≈ 8,1 s | Desde la 2.ª vez |
| Derrota-gag (por derrota) | ≈ 15-19 s sin "¡otra vez!" (gag 1 ≈ 15,6 s), más ≈ 7 s de rearmado | "¡Otra vez!" |
| Anticipación | ≈ 4,6 s (A) / ≈ 3,2 s (B) | No |
| Caída | ≈ 10,8 s | Desde la 2.ª vez |
| Antes del epílogo | ≈ 4,95 s (tope ≤ 6 s con audio real) | Desde la 2.ª vez |
| **Tramo sin tocar, del tiro ganador al epílogo** | **≈ 19 s** (sin F1 ni F2) | — |
| Epílogo (interactivo) | ≈ 75 s | Se juega |
| Cierre A + fiesta de los tres | ≈ 19,8 + 9,4 s (+ espera del choque ≤ 4 s) | Desde la 2.ª vez |
| Parte C, el mapa | ≈ 18 s + la espera del toque (≤ 6 s) | Desde la 2.ª vez |
| **Bloque 1** | **≈ 2,4 min** (2,5 min si nadie toca el choque ni el papel) | |
| Entrada | ≈ 4 s (al retomar, + el ritual corto) | Intro desde la 2.ª vez |
| Maxi / Nicole / Sofía / fin | ≈ 22 / 27 / 35 / 2 s, más ≈ 3 s de transiciones (el dato de la ruta va dentro del juego) | Se juegan |
| Despedida de Coco | ≈ 41 s | Se juega |
| Foto + video-llamada | ≈ 13 s (+ espera del sobre ≤ 6 s) + ≈ 31 s (+ espera del teléfono ≤ 5 s) | La llamada, desde la 2.ª vez |
| Cuenta y despegue | ≈ 10 s + toques + 13,8 s ≈ 27 s | Despegue desde la 2.ª vez |
| Mapa Estelar | ≈ 12 s | Desde la 2.ª vez |
| **Bloque 2** | **≈ 3,7 min** (con ≈ 1-2 s por toque al sobre y al teléfono; como máximo + 11 s si nadie toca) | |
| **Total del cierre** (desde el derribo final hasta el Mapa Estelar) | **≈ 6,1 min**, en dos sesiones naturales por la pausa aprobada (§8.1) | |
| **Revancha ganada** (desde el derribo) | ≈ 3,2-4,6 + 10,8 s + estrellitas (solo con los tres) ≈ 18 s | — |

**Para UX**:

- **Tramos pasivos más largos (v4.1)**: bloque 1, cierre A + fiesta hasta el choque (≈ 24 s), cortado
  por el toque del choque (N3) y el del papel (m6); bloque 2, papá en la llamada (≈ 25 s), después del
  toque al teléfono-estrella (N2). Si Maxi se va en la llamada, el primer recorte es `papa_guatita` (V7),
  que ya es un archivo aparte.
- La foto bajó del bloque 1 al 2: el bloque 1 queda ≈ 6 s más corto que en la v3 aunque la parte C ahora
  espera un toque.

## 19. Assets

### 19.1 Que ya existen o están pedidos en otras fichas

| Asset | Uso |
|---|---|
| Rig del Coleccionauta (A1), mochila-torre (A2) y patito (A4) de `batalla_arcoiris.md` | Todo el bloque 1 |
| Rigs de los hermanos (`assets/sprites/preview_*_rig/`) | Fiesta, preparativos, despedida, abordaje y Mapa Estelar |
| Coco (`coco_base.png`), su lengua del Río y su `modulate`; Cometa (`cometa_base.png` y `cometa_saludo.png`) | Todo |
| Paisaje del Claro y arcoíris por código (`paisaje_arcoiris.gd`) | Todo |
| Nave-estrella (`assets/sprites/nave/`, anclas de los estados incompleto y completo) | Base de N7 y N13 |
| **Arte de la Torre (ficha §18.1)**: torre, piezas "en el suelo", tapas sueltas, resortera, canasta, globos, gigante y manchas; poses de agarre del Coleccionauta; Coco camuflada y morada | Presentación, gags, gigante y caída |
| Pantalla "¡todos a la nave!", barra, sobre-estrella, polaroid e imágenes de papá (Beat 4 y A9) | Entrada, cuenta, foto y llamada |
| `mapa_estelar.gd`, `planeta_dibujado.gd` y la fuente Baloo | Mapa Estelar y letras |

### 19.2 Arte nuevo (para `disenador-personajes`)

| Id | Asset | Detalle | Lo usa |
|---|---|---|---|
| **N2** | **Poses nuevas del Coleccionauta** (además de las de la ficha §18.1) | "Mochila en alto"; piernas pedaleando en el aire (2 cuadros); saludito de dedos mirando a cámara, **colgado del cojín con un dedo**; mirándose las manos de lunares; carcajada chapoteando de pie; baile (2 cuadros de cadera); masticando e inflando chicle; cara pintada y muy digna; abrazado a la torre asintiendo (pausa); palpándose los bolsillos con los bolsillos dados vuelta y **hablando por un teléfono-caracol** (burbuja de la llamada); antenas asomando tras una loma (parte C, M5) | Anticipación, caída, gags, parte C y llamada |
| **N3** | **Capa "pintado de lunares"** por pieza | Lunares multicolor, 3 gotas que chorrean de las antenas, y las variantes de cabeza rosada (gag 1), cara pintada (gag 3) y cara de chicle (gag 4) | Caída, gags, epílogo, despedida y llamada |
| N4 | Corona de salpicón | El charco es por código (ficha §6.9); la corona de salpicón, en 3 cuadros si el código no alcanza | Caída |
| **N5** | **Mapa del Coleccionauta** | Bolita arrugada (90 px) y desplegado (1000 × 560). Crayón, **sin texto**: Arcoíris, ruta de 8 estrellitas con flechita y el planeta verde con huellita. **Que no parezca un perrito** | Cierre A, parte C, pausa, Sofía |
| **N6** | **Ala izquierda envuelta para regalo** | Envuelta (papel y moño arcoíris) y desenvuelta (con la firmita de Coco). La envuelta sirve también en el Beat 2 con `009a`. El ala instalada pivota en su raíz (para colgar 6°, 4°, 2° y 0°) | Pausa, Nicole y escena del ala |
| **N7** | **Nave-estrella por capas** | Casco con el hueco del ala; **ala instalada** que calce exacto; **3 broches dorados, cada uno con una piedrita de color intercambiable (roja, amarilla y azul)** y un cuadro girado; cúpula con lugar para 3 caras y Cometa; toberas con brillo aparte | Pausa, preparativos, abordaje, llamada y despegue |
| **N8** | **Tanque-caramelo y manguera** | Tanque transparente con ventanita, embudo y máscara de llenado; manguera de 3 franjas en piezas; balde de pintura arcoíris | Maxi |
| **N9** | **Regalos de Coco** (aprobados) | **T-rex de gomita**, **corazón rosado chicle** y **pony turquesa con crin de arcoíris**: 3 props de 120 px con el mismo peso visual | Despedida de Coco |
| **N10** | **Poses de Coco** (o un rig simple) | Manopla arriba; abrazo (a Cometa); cargando algo en la cabeza; encajando el ala; enderezando la nave con la cola; soplando con los cachetes inflados; mareada morada con ojos en espiral | Torre (gigante), preparativos y despedida |
| N11 | Cometa con el álbum de abrazos abierto, más la estampita de Coco | — | Despedida |
| **N12** | Pelusa con forma de nubecita | Reemplaza a la mosquita A5 | Antes del epílogo y gag 2 |
| **N13** | Nave del Mapa Estelar con el ala | El sprite a escala 0,2 | Mapa Estelar |
| N14 | Props de los gags | Frasco de pintura rosada, calcetines sueltos, tapa-corona y chicle | Gags |
| N15 | Dibujitos de la llamada | Huellita de perrito y huella de dinosaurio simpática (pueden ser por código) | Llamada |
| N16 | Mano abierta para el choque de cinco (pieza del rig de los hermanos) | Solo si hace falta | Despedida |
| **N17** **[v4]** | **Retratos con los cachetes inflados** | Una expresión extra para los 3 retratos de la barra (cachetes inflados, ojos grandes), del mismo tamaño que las demás | Anticipación K1 y vuelo del gigante |
| **N18** **[v4]** | **Animalia lejana** | Variante desenfocada y suave del planeta Animalia (pre-desenfocada en el SVG o por un shader barato; en el renderer Mobile conviene el sprite), sin candado ni gris de "bloqueado" | Mapa Estelar antes de la partida (§13.1) |
| N19 **[v4]** | Manito fantasma | Mano blanca simple, ⌀ 90 px (puede ser por código) | Primer tiro de Nicole y Sofía (§3.1) |
| N21 **[v4.1]** | Teléfono-estrella | Estrella dorada con auricular, ≥ 200 px, con 2 cuadros de sacudida (puede ser por código sobre la sobre-estrella) | Contestar la llamada (§11, V4) |
| N20 **[v4]** | Retratos grandes de la cuenta | Los retratos actuales a 160 y 200 px; si el SVG fuente no aguanta 200 px nítido, re-exportar | Cuenta regresiva (§12.1) |

**Por código**: el charco, el arcoíris y el puente, los chorros, las burbujas, el campo de estrellas, las
líneas, el morph al perrito, el marco de la consola, los fuegos, el confeti, la flechita del globo fuera de
pantalla, la flechita de luz Animalia → Arcoíris, los "zzz" de Animalia y la burbuja de recuerdo de la
llamada.

### 19.3 Animación (para `dev-godot`)

| Dónde | Animaciones |
|---|---|
| `motor_lanzar` (dueño de la torre) | `presenta_torre`, `manito_fantasma`, `anticipacion` (variantes A y B), `caida_torre` (desde `estado_derribo()`), los gags `gag_baile` (frasco a ≤ 2,5 s), `gag_estornudo`, `gag_globo_vuelve` y `gag_chicle` (según `variante_derrota()`), `rearma`, `gigante_inflado` (variante A, Coco), `gigante_vuelo` (con `retratos_cachetes`) y `charco_crece` |
| `batalla.tscn` (`CinematicasBatalla`) | `antes_epilogo` (mochila gris y pelusa), `cierre_a` (con la pista `mapa_cae`), `fiesta_tres` (B1-B4, con la espera del choque ≤ 4 s), `mapa_coleccionauta` (con la espera del toque en M1) y la pantalla de pausa. **Sin** F1/F2 entre la caída y el epílogo |
| **`escenas/planetas/arcoiris/partida_arcoiris.tscn`** (nueva) | `entrada`, `chorro`, `nave_estornuda`, `ala_desenvolver`, `ala_encaja` (Coco), `ala_afirma(paso)`, `broche_gira`, `broche_menea`, `ala_aletea`, `ruta_linea`, `ruta_perrito`, `ruta_palabra`, `despedida_<hermano>` (plantilla), `choque_cinco`, `coco_abrazo_cometa`, `coco_cierre`, `foto` (sobre que espera ≤ 6 s), `abordaje`, `telefono_ring` (espera ≤ 5 s), `llamada_papa`, `cuenta_retrato(brilla/salta/rie)`, `cuenta_estrella`, `despegue_puente` |
| `mapa_estelar.gd` | `llegada_rumbo(origen, destino, abierto: bool, de_vuelta: bool)`, el rumbo encendido persistente, `destino_lejano` (latido, flechita y voz de espera, §13.1) y el enfoque `lejano → encendido` (ME3) |
| `escena_planeta_arcoiris` (Beat 2) | `ala_fiesta` común a `009a` y `009b`: destello, loop de la nave y gesto canon (§15) |
| `coleccionauta.tscn` | `mochila_en_alto`, `pedalear_aire`, `colgado_dedo`, `saludito_camara`, `carcajada_chapotea`, `bailar`, `chicle`, `palpar_bolsillos` y `pintado(variante)` |

## 20. Notas de implementación

- **La torre, la anticipación, la caída, los gags y el gigante son del motor** (ficha §13). `batalla.gd`
  solo escucha `momento_saltable_iniciado/terminado`, consulta
  `Progreso.cinematica_vista("arcoiris_batalla_final:caida_torre")` y llama a `saltar_momento`. **Nunca
  conoce `derribo_inminente`.**
- **La caída no es física**: es una coreografía que interpola desde `estado_derribo()`. Nada cae sobre él,
  salvo la tapa-sombrerito.
- **Cámara lenta**: `speed_scale` de la cinemática, **nunca `Engine.time_scale`**.
- **Sincronía por pasos** `{animacion, voz, solape_s, aire_s}`, como en `batalla_arcoiris.md` §14.1.
- **Estado familiar** (ficha §13.4):
  - la nave se dibuja con el ala si `partida_hecha("arcoiris")`; antes, quien tiene la pieza ve el ala
    envuelta junto a la nave;
  - el hito del Claro tiene 3 estados: batalla → partida → revancha;
  - el viaje pide `partida_hecha`, o la llave de los padres;
  - el rumbo está en `equipo.rumbos`;
  - mientras `partida_hecha` sea `false`, Animalia usa el estado visual `lejano` y la voz
    `voz_destino_espera` del `mapa.json` de Arcoíris (§13.1), sin que el núcleo sepa de Arcoíris.
- **Ids de voz**: todos salen del guion v4 (índice en el §2.1). En `partida_arcoiris.tscn` no debe quedar
  ningún `arcoiris_partida_*` como id de voz; QA lo busca con un grep.
- **Entrada nunca bloqueada por la voz** (regla 13 del §0), salvo la manopla del choque de cinco, que se
  activa al terminar la voz del regalo (m5) a propósito.
- **"Antes del epílogo"**: QA mide el tramo con el audio real (≤ 6 s, sin los 0,5 s de silencio de los
  archivos).
- **"¡Juntos!"**: la presentación única se muestra la próxima vez que se abra la selección.
- **Capas (`z_index`) del bloque 2**: cielo 0, suelo 10, nave 20, Coco 30, hermano 35, partículas 50,
  barra 60, casa y Cometa 70.

## 21. Lo que sigue abierto [CONCILIAR]

| # | Qué | Con quién |
|---|---|---|
| 1 | ~~Mapa Estelar, rama B~~: **cerrado** en el guion v4: `vuelo_celebra` suena en ME5 de las dos ramas (en la B, tras `vuelo_rumbo_animalia`); tras la llave de padres, sin voz | — |
| 2 | ~~Broches, cierre solo a los 32 s~~: **confirmado** en la ficha §13.5, más la regla de los siguientes a los 12 s (v4.1) | — |
| 3 | ~~Tanque, ayuda de los 24 s~~: **confirmado** en la ficha (un chorro cada 4 s) | — |
| 4 | La posición de la nave en el Mapa Estelar: el guion pide "al 25 % de la ruta" en la rama A (la v3 la dejaba junto a Arcoíris). Hay que confirmar que `mapa_estelar.gd` puede dibujarla a mitad de un rumbo | `dev-godot` |
| 5 | ~~Salida de la revancha~~: **cerrado**, sin línea a propósito (guion T.9) | — |
| 6 | ~~Numeración de planos del guion §4~~: **cerrado**; el guion usa MX1-MX4, NI0-NI5 y SO0-SO6, igual que el §9 | — |
| 7 | ~~«morado» / «morada» de soplar~~: **corregido** en la ficha | — |
| 8 | ~~Referencia de `pausa_partida`~~: **cerrado**; el guion remite al §8.1 (P3) | — |

**Cerrados en la v4** (eran [CONCILIAR] en la v3): el logro común (2 tramos, `cajas_botadas_01/02`); la
ayuda 2 (`ayuda_globo_gigante`); las voces del gigante (`gigante_turno_maxi`, `gigante_impacto`); los ids
de la ficha (el guion v3/v4 volvió a los de la v1, que son los que usa este storyboard); la partida tras
la llave (broches de color, `vuelo_de_vuelta`); y el tope de "antes del epílogo" (≤ 6 s con audio real).

## 22. Dudas que siguen abiertas para el PO

1. **Grabar a los niños** (opcional, los tres o ninguno): «¡Tres!», «¡Dos!», «¡Uno!» de la cuenta y
   `fiesta_<hermano>` de la fiesta.

**Cerradas en la v4**: los colores del tanque (los 3 recuperados, guion §9.2); el final con el capítulo 2
listo (Mapa Estelar con Animalia encendida, sin encadenar el Galaga, por delegación); el globo gigante
(variante A, por delegación, condicionada al simulador); el orden de la cuenta regresiva (de a uno).
**Cerrada en la v4.1**: la pausa natural entre bloques (§8.1), **aprobada por delegación del PO** tal como
está.

## 23. Tarjetas sugeridas (las decide `scrum-master`)

| # | Tarjeta | Rol | Depende de |
|---|---|---|---|
| T1 | **Arte del cierre de Arcoíris**: N2-N21 | `disenador-personajes` | — (el arte de la Torre va en la tarjeta de la ficha) |
| T2 | **Torre en el motor**: pausa antes, presentación, manito fantasma, anticipación A y B, caída, 4 gags, rearmado, gigante (variante A) y charco | `dev-godot` | Ficha v3, N2, N3, N10, N12, N14, N17, N19, rig A1 y el simulador del gigante |
| T3 | **Ajustes al cierre de la batalla**: antes del epílogo, cierre A con el mapa, fiesta B1-B4, parte C con el toque y pausa con el hito de partida; y una nota en `batalla_arcoiris.md` que apunte aquí | `dev-godot` (la nota, `director-cinematicas`) | T2, N5 y N6 |
| T4 | **Partida, parte interactiva**: entrada, tanque, broches de color, ruta-perrito, con guardado por paso | `dev-godot` | N6-N8 y el estado familiar (ficha §13.4-§13.5) |
| T5 | **Partida, parte narrativa**: despedida de Coco, foto, llamada, cuenta de a uno, puente, Mapa Estelar (con Animalia lejana antes de la partida) y la escena del ala con `009a`/`009b` y su fiesta común | `dev-godot` | T4, N9-N11, N13, N15, N18, N20 y la grabación de papá |
| T6 | **Voces** (§21, puntos 1 y 5) y generación: TTS **con `--estimar` y OK del PO sobre el costo**, más la grabación casera | `guionista` | — |
| T7 | **Auditoría UX y QA del cierre**, y playtest con los tres | `experto-ux-parvulo` y `tester-qa` | T2 a T5 |

## 24. Changelog

### v4 (17-Oct-2026, HE-73): bloqueante B1 de la auditoría UX HE-71

Cada fila de la tabla de B1 (`2026-10-13_ux-torre-cierre-arcoiris.md`) y cada punto que la auditoría
manda aplicar al hacer la v4, con su plano o sección.

| Punto de B1 | v3 | v4 | Dónde |
|---|---|---|---|
| Conciliación general | Guion v2, ficha v2 | **Guion v4, ficha v3, `modo-equipo.md` v7.2**; índice de todos los ids y lista de retirados | Encabezado, §2.1 |
| Bloque 2, ids | `arcoiris_partida_*` | `arcoiris_despegue_*` (y los ids de núcleo y de batalla del guion) | §8-§13 |
| Pausa antes de la Torre (M6) | Con la línea de la 3.ª derrota | **Una sola pausa**, `pausa_antes`, en el mapa de batalla **antes** de la presentación; la presentación sigue directo a la intro | §2, §3 |
| Pausa desde la 3.ª derrota | «¿Vamos por la torre…?» | `torre_pausa`, «¿Vamos otra vez…? ¡La torre no se va a ninguna parte!» (4,5 s) | §7.1, G3f, G4c |
| Caída | C1 `cae_mochila`; C6 `la_botaron`/`lo_bajamos` | C1 `cae_lenta`, C5 `cae_charco`, C6 `cae_risa`; ≈ 10,8 s | §4.2 |
| F1 y F2 (m11) | Fiesta y `cierre_coco` tras la caída | **Fuera**; `cierre_coco` solo en A5; tramo sin tocar ≈ 19 s | §4.2, §6.1 |
| Antes del epílogo (decisión 7) | 3,5 s → 5,4 s | `mochila_gris` 3 s → **≈ 4,95 s**, tope **≤ 6 s con audio real** | §5.1, §20 |
| Gags, ids | `traje_dos_mas`, `lanzar_logro_1/2` | `ayuda_globos_extra` (+4, sin número), `cajas_botadas_01/02` | §7.1-§7.4 |
| Gag 1 (M7) | «¡No me botaron!», frasco al final (6 s) | «¡Sigo arriba!…», **frasco a los ≤ 2,5 s**, risas en el remate (4 s) | §7.2 |
| Gigante | Variantes F y G; faltaban voces | **Variante A**: `ayuda_globo_gigante`, `gigante_coleccionauta`, `gigante_turno_maxi`/`gigante_turno`, `gigante_impacto`; **retratos con cachetes inflados en el vuelo** y salto al impacto | §7.6, §4.1 |
| Primer tiro de las hermanas (M1) | — | `nucleo_equipo_lanzar_primer_tiro` con la **manito fantasma de 0,8 s**, no bloquea | §3.1 |
| Fin de cada tarea | «bombero / artista / capitana» | «¡… listo! ¡Gracias, (nombre)!», igual para los tres | §9.1, MX4, NI5, SO5 |
| Tarea de Nicole (m10) | Moño, **arrastra el ala**, broches en cualquier orden | **Coco encaja el ala**; Nicole gira los broches **por color** (`broches_pide_rojo/_amarillo/_azul`, piedritas al azar); otro broche se menea sin voz | §9.4 |
| Despedida de Coco | Recordatorio 6 s; Maxi 15 s; `coco_abrazo` | Manopla activa al terminar la voz (m5); recordatorio 8 s; **a los 20 s Coco choca sola** con cualquiera; álbum sin voz | §10 |
| Llamada | `papa_02` y `papa_animalia` | **`papa_02` retirada**; foto (movida aquí) → `arcoiris_010` → `papa_01` → `papa_pista` → `papa_guatita` → `papa_03`; el gag de los bolsillos pasa a una burbuja de recuerdo | §11 |
| Cuenta regresiva (decisión 6, m7) | En cualquier orden; 25 s; «¿Rugidos?» | **De a uno, Sofía → Nicole → Maxi**; retratos fuera de la nave (Maxi **200 px**); recordatorio 8 s; **salta solo a los 20 s / 15 s (Maxi)**; tocar uno que no brilla salta y ríe sin avanzar | §12.1 |
| Despegue | `partida_puente`, `partida_rampa`, `wii_<hermano>` | `vuelo_despegue` (DS1), `vuelo_puente` (en la cima), rampa sin voz, `vuelo_coco_chao` | §12.2 |
| Animalia antes de la partida (M9) | No estaba | **Lejana y desenfocada, sin candado**, late en < 100 ms, `mapa_animalia_antes_01/_02` alternadas (máx. una por visita) y **flechita a Arcoíris** | §13.1 |
| Final (decisión 3) | Rama A gris; rama B a todo color | **Animalia se enciende en las dos ramas**; rama A con la nave al 25 % (`vuelo_lejitos` + `vuelo_celebra`); rama B con `vuelo_rumbo_animalia`; tras la llave, `vuelo_de_vuelta` (m8) | §13.2, §16.2 |
| `009b` (M8.4) | Una señal de Coco | **La misma fiesta que `009a`**: el ala destella, loop de la nave y gesto canon | §15 |
| Ruta de Sofía (M10, M11, m9) | Campo pegado a Cometa y la casa; "bup" al arrastrar | Campo `Rect2(150, 128, 980, 440)`, mapa en y 8-88; en arrastre solo cuenta la correcta; pista siempre con el latido; ids `ruta_instruccion`, `ruta_forma`, `ruta_dato` tras la 4.ª | §9.5 |
| Parte C (m6) | Pasiva | El papel **espera un toque** (≥ 120 px), sigue solo a los 6 s; `mapa_coleccionauta` con gag de las antenas | §6.3 |
| Dos hermanos + el retrato (M8.2) | — | Regla 12; ningún plano nombra ni espera al ausente; tabla de esperas con salida sola; revancha con dos sin estrellitas ni récord | §0, §16.4, §14 |
| Fiesta reutilizada | B1-B6 tras el cierre A | **[delegación]** B1-B4 después del epílogo, compacta (≈ 9,4 s); la foto pasa a la partida | §6.2, §1 |
| [CONCILIAR] y dudas del PO | 8 y 4 abiertas | Cerradas las que resolvieron el guion v4 y la ficha v3; quedan 7 menores y 2 del PO | §21, §22 |

### v4.1 (17-Oct-2026): re-auditoría UX (`2026-10-17_ux-reauditoria-torre-cierre.md`)

| Punto | v4 | v4.1 | Dónde |
|---|---|---|---|
| **N2** (≈ 54 s pasivos en el bloque 2) | Sobre que se abría solo a los 3 s; llamada sin toque | **Sobre con target ≥ 200 px, se abre solo a los 6 s**; **teléfono-estrella ≥ 200 px para "contestar" la llamada**, se abre solo a los 5 s. El tramo pasivo más largo baja a ≈ 25 s | §11 (V2, V4), §16.4, §18, N21 |
| **N3** (≈ 47 s con un solo toque en el bloque 1) | El choque de la fiesta era automático | **Las manos esperan un toque de cualquiera** (target ≥ 200 px en (640, 330)) y chocan solas a los 4 s | §6.2 (B3), §6.3, §16.4 |
| **P2** (28 s contra 31 s) | §2 decía ≈ 28 s y §11/§18, ≈ 31 s | **Una sola cifra: ≈ 31 s** más la espera del teléfono | §2, §11, §18 |
| **P4** (¿el mapa de la pausa se toca?) | Sin definir | **Va dentro del target de la nave**: tocarlo es tocar la nave | §8.1, §16.4 |
| **Decisión 2** (pausa entre bloques) | [PO, duda 1] | **Aprobada por delegación del PO**, tal como estaba; sale la marca y la rama "si el PO no la quiere" | §2, §8.1, §22 |
| **Broches siguientes** (ficha §13.5) | Siempre la escalera 8/16/24/32 s | **Por delegación**: si Coco ya giró uno sola, en los siguientes hay un único recordatorio a los 6 s y el broche gira solo a los 12 s | §9.4 |
| Cabos de la ficha | §21, puntos 2, 3 y 7 abiertos | Cerrados (la ficha los confirmó); se agrega el punto 8 (P3, referencia del guion) | §21 |
| Cabos del guion (§21, puntos 1, 5, 6 y 8) | Abiertos para `guionista` | Cerrados por el guion v4: `vuelo_celebra` también en la rama B (sin voz tras la llave), revancha sin línea, numeración de planos igual, pausa remite al §8.1 | §13.2, §14, §21 |
| Duraciones | Bloque 2 ≈ 3,6 min; total ≈ 6 min | **Bloque 1 ≈ 2,4 min (2,5 sin toques); bloque 2 ≈ 3,7 min (+ 11 s como máximo sin toques); total ≈ 6,1 min** | §2, §18 |
