# Storyboard y spec — Cierre de la historia del Planeta Arcoíris (de la Torre al despegue)

> Entregable de `director-cinematicas`. **Versión 5 (05-Nov-2026, tarjeta HE-88)**: concilia el storyboard
> con la **Torre en 3 etapas** de `docs/fichas/motor-lanzar.md` **v4 §25**, con la opción del PO
> **R17 = A (05-Nov-2026): 3 etapas con guardado entre etapas**. El detalle nuevo está en el **§25**:
>
> - la caída corta y la transición entre etapas (C1 de la ficha §25.13);
> - la presentación de cada etapa y de cada pieza especial, y la de la bandeja de Nicole (C2);
> - qué ve la familia al retomar después de un guardado entre etapas (re-entrada corta y saltable).
>
> Aplica también la otra **decisión del PO del 05-Nov-2026**: **la generación de video queda postergada
> por presupuesto**. Cada momento de la Torre funciona primero con un **reemplazo provisional barato**
> (tarjeta estática con voz, cutout simple o paso directo), y después se puede cambiar por video **sin
> tocar la lógica**. El contrato está en el §25.1 y la columna "Provisional / video" aparece plano por plano
> (§25.3-§25.8). Los [CONCILIAR] de fondo y arte, de voces y de `etapas[]` quedan solo anotados (§25.10),
> porque son de HE-74, HE-86 y HE-80. Lo que necesito de `modo-equipo.md` §14.16 está como nota en el
> §25.9: esa sección no la edito. Changelog en el §24.
>
> **Versión 4.1 (17-Oct-2026)**: aplica las mejoras de la
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
   torre, la mochila, el ala y la ruta. **v5**: en la Torre, cada momento es un **gancho** que hoy se hace
   con cutout simple, tarjeta o paso directo, y donde no depende del estado admite un **inserto de video**
   después, sin tocar la lógica (§25.1).
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
     v5: LA TORRE SON 3 ETAPAS (§25.2)
     E1 "la torre de la colección" (+ confeti_presenta la 1.ª vez, §25.5.2)
       ├─ derrota → derrota-gag 1-4 (§7) → "¡otra vez!" → rearmado → intro corta
       └─ derribo de E1 → [guardado] caída corta (≈ 5,5 s, §25.3) → transición (≤ 4 s, §25.4) →
     E2 "dos torres y un puente" (mismas derrotas)
       └─ derribo de E2 → [guardado] caída corta → transición (+ resorte_presenta la 1.ª vez) →
     E3 "la torre de las cosas raras" (mismas derrotas)
       └─ derribo de E3 = el derribo final:
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
| **v5**: ficha v4 §25.14 (ids sugeridos; los textos los fija el guion en HE-86) | `arcoiris_batalla_torre_caida_etapa_01` / `_02`; `arcoiris_batalla_torre_etapa_2_llega` / `_3_llega`; `arcoiris_batalla_torre_confeti_presenta`, `_resorte_presenta`, `_elige_globo_presenta_nicole`; `globo_nombre_*` y `ayuda_globos_extra_02` (motor, sin plano propio). Al retomar se reutilizan `nucleo_batalla_retomar`, `intro_coleccionauta`, `intro` y `encontre_globos` | §25 |

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

**v5 (etapas)**: esta presentación es la de **E1**. En T1 la pila incluye las **3 cajas de confeti**
(magenta, ficha §25.5.1) y, con el último "pop", aparece arriba al centro el **indicador de las 3
torrecitas** (§25.2.2), sin voz. Entre la intro corta y la puerta de Maxi va, la 1.ª vez por familia, la
presentación del confeti (§25.5.2). Las presentaciones de E2 y E3 son sus transiciones (§25.4). El
reemplazo provisional de T1-T3 está en el §25.5.1.

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

**v5**: la anticipación y esta caída son **solo del derribo de E3** (el derribo final). Los derribos de E1
y E2 usan la caída corta del §25.3. La composición de E3 (torre angosta, trono en x 990 sobre la columna
central, flancos con trampolines y frascos de base en x ≈ 825 y ≈ 1155) y sus ajustes a K3 y C1 están en
el §25.7.

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
  **v5 (etapas)**: se queda hasta el derribo **de la etapa**. En la caída corta, **la pintura se queda**
  (se suma a sus lunares) y **los objetos salen volando con el splash** (calcetín, tapa-corona y chicle).
  Al retomar otro día solo se restauran los lunares de las etapas ganadas (§25.6).
- **v5**: las derrotas, las ayudas y la pausa cuentan **por etapa** (ficha §25.4); la rotación de los
  gags cuenta **por Torre**, así que el chicle puede caer en cualquier etapa. Los planos de los gags no
  cambian con la etapa: el trono está siempre en x ≈ 990 y la coreografía lee su posición del nivel.
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
| **v5**: etapas (ficha §25.15) | **Las 3**, con su caída corta (ya vista: se salta) y su transición (no se salta, ≤ 4 s). Sin presentaciones de piezas especiales ni de la bandeja (ya vistas por familia). Detalle y variante "solo E3" en el §25.8 |
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
| **v5**: caída corta de etapa (E1 y E2) | `arcoiris_batalla_final:caida_etapa` (un solo id para las dos; lo marca `batalla.gd`) | El estado final del §25.3 y sigue la transición |
| **v5**: transición entre etapas | — | No se salta (≤ 4 s, orienta) |
| **v5**: presentación del confeti, del trampolín y de la bandeja de Nicole | — | Una vez por familia; se corta si alguien toca (ficha §25.3) |
| **v5**: re-entrada al retomar la Torre | `arcoiris_batalla_final:retomar_torre` | **Desde la 1.ª vez** (excepción, §25.6): la etapa lista y la puerta de Maxi |
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
| **v5**: caída corta, transición y re-entrada de la Torre | Nadie tiene que tocar | Siguen solas; ninguna espera un toque (§25.3-§25.6) |

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
| **v5**: presentación del confeti (1.ª vez por familia, E1) | ≈ 3,8 s | Se corta al tocar |
| Derrota-gag (por derrota) | ≈ 15-19 s sin "¡otra vez!" (gag 1 ≈ 15,6 s), más ≈ 7 s de rearmado | "¡Otra vez!" |
| **v5**: caída corta + transición (E1→E2 y E2→E3, cada una) | ≈ 5,5 + 4,0 s = **≈ 9,5 s** (+ ≈ 3,8 s de `resorte_presenta` la 1.ª vez, antes de E3) | La caída, desde la 2.ª vez; la transición, no |
| **v5**: re-entrada al retomar | ≈ 5 s (etapa a medias) / ≈ 7,7 s (etapa sin tiros) | Desde la 1.ª vez |
| **v5**: **Torre jugada** (ficha §25.10) | **Típica ≈ 16 min** (v3: ≈ 5,8), p80 ≈ 21 min, ≈ 12 min con las 3 etapas al primer intento. Se corta naturalmente después de E1 o de E2: el guardado es entre etapas | — |
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
| **Total del cierre** (desde el derribo final hasta el Mapa Estelar) | **≈ 6,1 min**, en dos sesiones naturales por la pausa aprobada (§8.1). **v5: no cambia**, porque arranca en el derribo de E3 | |
| **v5**: desde la entrada a la Torre hasta el Mapa Estelar | **≈ 22 min** (16 de Torre + 6,1 de cierre), repartidos en 2-3 sesiones: la Torre guarda entre etapas y el cierre tiene la pausa del §8.1 | |
| **Revancha ganada** (desde el derribo) | ≈ 3,2-4,6 + 10,8 s + estrellitas (solo con los tres) ≈ 18 s. **v5**: más ≈ 4 s de cada transición (las caídas cortas ya se saltan) | — |

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
| **N3b** **[v5]** | **Lunares en 3 niveles** (extiende N3) | Nivel 1 (≈ 5 lunares, tras E1), nivel 2 (≈ 12, tras E2) y nivel 3 (el N3 completo, con las gotas de las antenas, en la caída final). Basta una máscara que muestre un subconjunto del N3: no es un dibujo nuevo por nivel | Caídas cortas, re-entrada y caída final (§25.3, §25.6) |
| N22 **[v5]** | **Indicador de las 3 torrecitas** | Silueta de torrecita de 40 × 48 px en dos estados: gris de contorno y pintada (3 franjas rojo, amarillo y azul). **Puede ser por código** | §25.2.2 |
| N23 **[v5]** | **Poses de la transición** | Corriendo "en rueda" (2 cuadros, puede ser el sprite con *bob*); con el cojín-trono en la cabeza; lanzado por el trampolín (sirve la de pedalear en el aire, N2) | §25.4 |
| N24 **[v5]** | Nubecita "puf" | La nubecita de confeti en la que desaparece cada pieza vieja (puede ser por partículas) | §25.4 |

**Por código**: el charco, el arcoíris y el puente, los chorros, las burbujas, el campo de estrellas, las
líneas, el morph al perrito, el marco de la consola, los fuegos, el confeti, la flechita del globo fuera de
pantalla, la flechita de luz Animalia → Arcoíris, los "zzz" de Animalia y la burbuja de recuerdo de la
llamada.

### 19.3 Animación (para `dev-godot`)

| Dónde | Animaciones |
|---|---|
| `motor_lanzar` (dueño de la torre) | `presenta_torre`, `manito_fantasma`, `anticipacion` (variantes A y B), `caida_torre` (desde `estado_derribo()`), los gags `gag_baile` (frasco a ≤ 2,5 s), `gag_estornudo`, `gag_globo_vuelve` y `gag_chicle` (según `variante_derrota()`), `rearma`, `gigante_inflado` (variante A, Coco), `gigante_vuelo` (con `retratos_cachetes`) y `charco_crece`. **v5**: `caida_etapa(nivel_lunares)`, `transicion_etapa(etapa)`, `armar_torre(por_filas)` (común a T1, la transición y la re-entrada), `presenta_especial(tipo)`, `retomar_torre(caso)` e `indicador_torrecitas` (§25) |
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

## 21. Lo que estaba abierto [CONCILIAR] (v5: todo cerrado)

| # | Qué | Con quién |
|---|---|---|
| 1 | ~~Mapa Estelar, rama B~~: **cerrado** en el guion v4: `vuelo_celebra` suena en ME5 de las dos ramas (en la B, tras `vuelo_rumbo_animalia`); tras la llave de padres, sin voz | — |
| 2 | ~~Broches, cierre solo a los 32 s~~: **confirmado** en la ficha §13.5, más la regla de los siguientes a los 12 s (v4.1) | — |
| 3 | ~~Tanque, ayuda de los 24 s~~: **confirmado** en la ficha (un chorro cada 4 s) | — |
| 4 | ~~La posición de la nave en el Mapa Estelar (al 25 % de la ruta en la rama A)~~: **trasladado** a la tarjeta HE-85, que lo absorbe (tablero). Ya no es una conciliación entre documentos: es una verificación de implementación de `dev-godot` | — |
| 9 | ~~C1 de la ficha v4 §25.13: caída corta y transición entre etapas; composición de E3; duraciones del §18~~: **cerrado en la v5** | §25.3, §25.4, §25.7, §18 |
| 10 | ~~C2 de la ficha v4 §25.13: presentación de cada pieza especial y de la bandeja de Nicole~~: **cerrado en la v5** | §25.5 |
| 11 | ~~Qué ve la familia al retomar tras un guardado entre etapas (R17 = A)~~: **cerrado en la v5** | §25.6 |

**v5**: no queda ningún [CONCILIAR] abierto en este storyboard. Lo que pido a otros roles son **notas** que
no bloquean el storyboard (cada plano dice qué pasa si no se adoptan): §25.9 (`disenador-mecanicas`, para
`modo-equipo.md` §14.16 y la ficha) y §25.10 (HE-74, HE-86 y HE-80).
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

### v5 (05-Nov-2026, HE-88): la Torre en 3 etapas (R17 = A) y ganchos sin video

| Qué | v4.1 | v5 | Dónde |
|---|---|---|---|
| Estructura de la Torre | Una torre; el derribo es el final | **3 etapas** (E1, E2 y E3); los derribos de E1 y E2 llevan caída corta + transición; la anticipación y la caída del §4 son solo de E3 | §2, §4, §25.2 |
| C1 de la ficha v4: caída corta | — | **≈ 5,5 s** (CE1-CE6): tambaleo, splash, lunares que crecen por etapa, mini fiesta y la torrecita que se pinta; saltable desde la 2.ª vez (`caida_etapa`) | §25.3 |
| C1: transición | — | **≤ 4 s** (TR1-TR4), no saltable: sale rebotando, la torre vieja hace "puf", **la torre nueva llega volando por filas** desde fuera de cuadro y él vuelve con el cojín-trono; en E3 lo sube el trampolín | §25.4 |
| C1: composición de E3 y §18 | Torre única en x 990 | Torre angosta de E3 en K3 y C1; flancos y trampolines fuera del charco; el gag del trampolín en C2. Cierre ≈ 6,1 min (sin cambios); Torre ≈ 16 min | §25.7, §18 |
| C2: presentaciones | — | E1 = presentación T.1 + confeti; E2 = su transición; E3 = su transición + trampolín; la bandeja de Nicole, **en su 2.º turno de la sesión** (una cosa nueva por turno) | §3, §25.5 |
| Retomar tras guardado entre etapas | — | **Re-entrada corta, saltable desde la 1.ª vez**: caso A (etapa a medias, ≈ 5 s) y caso B (etapa sin tiros, ≈ 7,7 s) | §25.6 |
| Indicador de etapas | — | **3 torrecitas** arriba al centro, sin números: se pintan al ganar cada etapa | §25.2.2 |
| Video postergado (PO, 05-Nov) | Todo cutout completo | **Contrato de ganchos**: video → cutout → tarjeta → paso directo, elegido por datos; columna "Provisional / video" plano por plano | §25.1, §25.3-§25.7 |
| Revancha | Una torre | 3 etapas (caídas cortas saltables, transiciones enteras); variante si el PO elige "solo E3" | §14, §25.8 |
| [CONCILIAR] | Quedaba el 4 (nave a mitad del rumbo) | Ninguno abierto: el 4 pasa a HE-85; C1, C2 y el retomar, cerrados. Notas no bloqueantes para mecánicas, arte, voces y niveles | §21, §25.9, §25.10 |

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

## 25. v5 — La Torre en 3 etapas (HE-88, 05-Nov-2026)

**Insumos**: `docs/fichas/motor-lanzar.md` v4 §25 (sobre todo el §25.3, flujo entre etapas; el §25.13, C1
y C2; el §25.14, voces; y el §25.15, revancha) y el §12 (parcial); `modo-equipo.md` §14.6 (retomar la
batalla); la decisión del PO **R17 = A** y la de **video postergado** (05-Nov-2026, tablero, MARCO DE
TRABAJO).

**Qué no cambia**: la pausa antes de la Torre (§3), las derrotas-gag (§7), la anticipación y la caída
final (§4, ahora solo en E3) y todo el cierre desde el derribo de E3 (§5-§13). Las reglas del §0 valen
igual; aquí importan sobre todo la 2 (un foco), la 4 (aire tras el chiste), la 5 (nunca se hace daño),
la 6 (saltar) y la 12 (dos hermanos y el retrato).

### 25.1 Ganchos: provisional ahora, video después, la misma lógica

**El problema**: la Torre necesita sus momentos narrativos ya, pero el video no tiene presupuesto. Además,
casi todo lo de la Torre **depende del estado** (la torre real del nivel, el charco y la pose del
derribo), y eso un video no lo puede saber.

**La regla**: cada momento es un **gancho** con un id. El motor llama al gancho y espera a que termine. El
gancho elige, **por datos**, la mejor implementación disponible, en este orden:

| Nivel | Qué es | Costo | Cuándo |
|---|---|---|---|
| **V · video** | Clip `.ogv` (Theora, nativo en Godot 4) a pantalla completa, **sin diálogo** (las voces se montan encima, decisión del stack del 19-Jul-2026) | Generación de video (postergada) | Solo planos que **no dependen del estado**, como **inserto** en primer plano |
| **CS · cutout simple** | Tweens sobre los sprites que ya existen: las piezas del nivel, `coleccionauta_provisional.png`, Coco, el charco y las partículas por código. Squash, arcos, rotaciones y `modulate`. Sin rig | Solo código | **La opción por defecto de hoy** en la Torre |
| **TJ · tarjeta** | La escena congelada (o una ilustración fija de 1280 × 720) con la voz, 1-2 SFX y un tween de escala o fundido | Una imagen | Respaldo de un CS que todavía no esté hecho |
| **PD · paso directo** | Se aplica el estado final y suena solo la voz sobre la escena congelada | Nada | Último respaldo: el juego nunca se traba por falta de un asset |

**El contrato (para `dev-godot`)**:

1. **El estado lo cambia el motor, nunca la animación.** Al terminar el gancho (o al saltarlo), el motor
   aplica el estado final del momento (`aplicar_estado_final(id)`). Lo mismo con cualquier
   implementación: **cambiar CS por video no toca la lógica.**
2. **Las voces y los SFX viven en los datos del gancho**, con su tiempo de inicio, y no dentro del video.
   Si un clip dura distinto, sus tiempos se sobrescriben en los datos (`voces_video`), no en el código.
3. **El video va en una capa debajo de la UI**: la casa, Cometa, la barra del equipo y el indicador de
   torrecitas **siguen a la vista y activos** encima del clip (la casa siempre está). Entra y sale con
   un fundido de 0,2 s contra el cuadro congelado o el estado final.
4. **Saltar** usa el mecanismo de siempre (`momento_saltable_iniciado/terminado` y `saltar_momento(id)`),
   y el salto deja el mismo estado final con cualquier implementación.
5. **Si falta el asset de un nivel, se baja al siguiente** (V → CS → TJ → PD) sin error visible; solo un
   `push_warning` para QA.
6. **Dónde van los datos**: propongo `datos/cinematicas/arcoiris_torre.json`, de cinemáticas. Así no cambia
   el contrato de `torre_equipo.json` de la ficha. Un gancho tiene esta forma:

```jsonc
{
  "caida_etapa": {
    "duracion_max_s": 5.5,
    "saltable": "desde_2a",                 // "desde_1a" | "desde_2a" | "no"
    "implementaciones": ["video", "cutout", "tarjeta", "directo"],
    "video": { "e1": "res://assets/video/torre/caida_etapa_e1.ogv", "e2": "res://assets/video/torre/caida_etapa_e2.ogv",
               "entra_s": 1.5, "sale_s": 4.7 },          // el clip cubre CE2-CE5; CE1 y CE6 siguen en cutout
    "voces": [ { "id": { "e1": "arcoiris_batalla_torre_caida_etapa_01", "e2": "arcoiris_batalla_torre_caida_etapa_02" }, "t_s": 3.2 } ],
    "sfx":   [ { "id": "splash_redondo", "t_s": 2.4 }, { "id": "tilin", "t_s": 4.9 } ]
  }
}
```

**Columna "Provisional / video" de los planos**: dice qué se hace **ahora** (CS, TJ o PD) y si ese plano
**admite video después** (y cómo) o no.

### 25.2 Las 3 etapas en pantalla

#### 25.2.1 Composición por etapa

La forma exacta (los `rect`) la fija `disenador-niveles` en HE-80. **La coreografía nunca lleva
coordenadas de piezas fijas en el código**: lee las del nivel y la pose de `estado_derribo()`. Lo común a
las tres etapas es la ficha §4: la torre centrada en x 990, la base en y 584, ≤ 434 px de alto, el charco
centrado en (990, 580), la bolsa de la resortera en (260, 430) y Coco con la canasta en (85, 584).

| | E1 · "La torre de la colección" | E2 · "Dos torres y un puente" | E3 · "La torre de las cosas raras" |
|---|---|---|---|
| Silueta | Ancha y escalonada (x ≈ 800-1180) | Dos pilares y un puente de cartón; el trono **sobre el puente** | Angosta al centro; dos flancos de lata con un **trampolín verde** cada uno; frascos sueltos en x ≈ 825 y ≈ 1155 |
| Lo que se lee de lejos | "Muchas cosas apiladas" | "Un puente": hay que elegir dónde pegar | "Hay que abrir un costado": los trampolines se ven limpios y verdes (no se rompen) |
| Lunares con que **empieza** él (§25.2.3) | Ninguno | Nivel 1 | Nivel 2 |
| Indicador (§25.2.2) | ○ ○ ○, late la 1.ª | ● ○ ○, late la 2.ª | ● ● ○, **la 3.ª late más grande** ("¡la última!") |

#### 25.2.2 El indicador de las 3 torrecitas (propuesta de dirección)

- **Qué es**: tres siluetas de torrecita (40 × 48 px, N22) en `Rect2(568, 16, 144, 48)`, arriba al
  centro, a más de 24 px de Cometa y de la casa. **Sin números ni texto.**
- **Estados**: gris de contorno (por jugar), pintada con 3 franjas rojo, amarillo y azul (ganada) y la de
  la etapa en curso, que respira (escala 1,0 ↔ 1,06, 2 s).
- **No es un botón**: al tocarla se menea 0,2 s, sin voz.
- **Para qué sirve**:
  - en la caída corta, una chispa la pinta: se ve **lo ganado**;
  - en la transición a E3, la última late más grande: responde al riesgo R21 ("¡otra torre más!") sin
    palabras;
  - al retomar, las ganadas destellan: **así se ve dónde iban** (§25.6).
- **Si UX o mecánicas no la quieren**, se omite y no cambia ningún tiempo: la chispa de CE6 vuela a la
  mochila del Coleccionauta y el resto queda igual.
- **Provisional**: por código (dos `Polygon2D` y un `modulate`). Sin video.

#### 25.2.3 Él queda cada vez más pintado (propuesta de la ficha C1, adoptada)

- **Lunares por nivel** (N3b): 1 tras E1, 2 tras E2 y **3, el completo con las gotas, solo en la caída
  final**. Así la caída final sigue siendo la de mayor fiesta, también en lo visual.
- **No necesita estado nuevo**: el nivel sale de `etapas_ganadas`.
- **La mochila siempre queda gris y limpia**: la salva en cada caída. Eso es lo que prepara el epílogo.

### 25.3 La caída corta de etapa (E1 y E2; ≈ 5,5 s; saltable desde la 2.ª vez)

**Cuándo**: en el cuadro en que el motor detecta el derribo de E1 o de E2 (agarre 0 o trono botado, en
vivo, ficha §25.3). La física queda congelada. **No lleva la anticipación del §4.1** (esa, con su
silencio de K4, es solo para el derribo final) ni cámara lenta: es una caída "de capítulo", más chica que
la final a propósito.

**Id del momento**: `arcoiris_batalla_final:caida_etapa`. Es uno solo para E1 y E2, así que la caída de E2
ya se salta si la de E1 se vio entera.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX | Provisional / video |
|---|---|---|---|---|---|---|
| CE1 | 0,0-1,5 | La torre congelada en la pose del derribo | **Tambaleo en dos vaivenes que crecen** (±4° y ±8°, 0,6 s cada uno), con pivote en el centro de la plataforma (990, 584), sin física; queda **inclinada 9°** (0,3 s). Él, "colgando de un dedo" del cojín, patalea | — | Música a −10 dB. Dos "ñiic" de juguete | **CS**: rotación del nodo de la torre (las piezas son hijas de un pivote temporal). **Video: no** (es la torre real) |
| CE2 | 1,5-2,4 | La torre se rinde, a velocidad normal | Las piezas interpolan desde su pose de `estado_derribo()` hasta un montón **alrededor del charco** (nunca encima). Él cae **sentado en el aire** con la **mochila en alto** (pose N2) | — | "Woosh" y "pum, pum" acolchados | **CS**: tween de cada pieza hacia una pose de la "corona" alrededor del charco (§25.11). **Video: sí, como inserto** desde 1,5 s: primer plano de él cayendo, sin la torre |
| CE3 | 2,4-2,8 | **¡Splash!** | Aterriza sentado en (990, 578) con squash (0,75 / 1,15); corona de salpicón chica (N4); aparecen **los lunares del nivel de la etapa** (§25.2.3). **La mochila, en alto, gris y limpia.** **En el mismo cuadro, los tres retratos de la barra saltan juntos** (un salto de 40 px) y entra confeti desde un costado (≤ 30 partículas) | — | "Splash" redondo al 70 %. **Fanfarria corta** de 2 compases (la grande queda para la caída final) | **CS**: squash del sprite, lunares con máscara y partículas. **Video: sí** (en el inserto; los retratos están en la UI, encima) |
| CE4 | 2,8-3,2 | Él, quieto | **Aire para la risa**: le gotea pintura de una antena | — | "Plip" | CS. Video: sí (inserto) |
| CE5 | 3,2-4,7 | Él | Se mira las manos con lunares, sorprendido; sopla la mochila para ver si sigue limpia y suspira aliviado | `arcoiris_batalla_torre_caida_etapa_01` (E1) o `_02` (E2), ≤ 1,5 s (ficha §25.14) | — | CS. **Video: sí** (el clip termina en 4,7 s con fundido al estado del cutout) |
| CE6 | 4,7-5,5 | Arriba al centro | **Una chispa sale del charco y pinta la torrecita de la etapa** en el indicador (0,4 s, "tilín"). Después **una estrellita chica vuela de la torrecita a la casa**, que late una vez (0,4 s): "lo ganado quedó guardado" (§25.6). Sin voz y sin invitar a salir | — | "Tilín" y un "tin" suave en la casa | **CS** por código. Video: no (es UI) |

**Estado final** (el que deja el salto):

- él sentado en el charco, con los lunares de la etapa y la mochila gris en alto;
- las piezas en un montón alrededor del charco y el confeti que cae;
- la torrecita pintada.

Después sigue **siempre** la transición (§25.4).

**Si el gancho de la caída corta está en PD**: se pinta la torrecita y suena `caida_etapa_0X` sobre la
torre congelada. Después la transición la desarma con su "puf" igual.

### 25.4 La transición (≤ 4 s; no se salta) y el arranque de la etapa nueva

**Para qué**: es la **presentación de E2 y de E3**. En ≤ 4 s cuenta "se levantó, trajo otra torre y se
subió", y la voz dice qué tiene de nuevo. Es **chistosa** (R21): el Coleccionauta nunca se rinde y siempre
tiene más colección.

**Un foco**: la torre nueva que llega. Él está fuera de cuadro, pero **sus antenas asoman por el borde
derecho y rebotan al ritmo de la voz**, igual que el gag de la parte C (M5). El chiste es que él tira su
colección desde afuera.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX | Provisional / video |
|---|---|---|---|---|---|---|
| TR1 | 0,0-0,6 | Él en el charco | **Se levanta de un salto** (squash 0,8 / 1,15), sacude las antenas (gotitas), se cuelga la mochila y **sale rebotando hacia la derecha** (3 rebotes; pose "corriendo en rueda", N23) | `arcoiris_batalla_torre_etapa_2_llega` o `_3_llega` **empieza en 0,5** (≤ 3,5 s) | El **motivo del Coleccionauta** (kazoo), rápido. Tres "boing" que suben | **CS**: tween en x con *bob*. Video: no (en 0,6 s no vale un clip, y lo que sigue es el nivel real) |
| TR2 | 0,4-1,0 | La plataforma | Las piezas viejas desaparecen **una por una en una nubecita "puf"** (N24), de izquierda a derecha, cada 0,03 s. **El charco se escurre** hasta su tamaño inicial ("glup"): es otra torre y otro charco (ficha §25.3) | (sigue) | "Puf" en ráfaga y "glup" | **CS**: escala a 0 + partículas; el charco, por código. Video: no |
| TR3 | 1,0-3,0 | **La torre nueva llega volando** | Por **filas** de abajo hacia arriba (§25.11), las piezas de cada fila vuelan en arco desde fuera de cuadro, en (1320, 260), y aterrizan en su `rect` con un "pop" (≤ 0,3 s por fila). Las antenas, con sus lunares, asoman y rebotan en el borde derecho. **La última fila es la novedad de la etapa**: en E2, **el puente**, que cae con un "bonk" de cartón, y después sus 4 frascos; en E3, **los dos trampolines**, con un "boing-boing" | (sigue) | Un "fiu-pop" por fila, con una nota que sube (do-re-mi…) | **CS**: tween en arco por pieza (función `armar_torre`, la misma de T1 y de la re-entrada). Video: no (las piezas tienen que caer en el lugar real del nivel) |
| TR4 | 3,0-4,0 | Él vuelve | **E2**: entra rebotando con el **cojín-trono en la cabeza** (N23), salta en arco (0,4 s) al centro del puente, pone el cojín y se sienta ("puf"). **E3**: entra corriendo, **pisa un trampolín, que lo lanza** ("¡boooing!", squash del resorte, ficha §25.5.2) en arco hasta la cima, y cae sentado en el cojín. En los dos casos termina con la **cara de "agarre lleno"**, orgulloso. **La torrecita de la etapa empieza a respirar** (en E3, más grande) | La voz termina como mucho en 4,0 | "Puf" de cojín; en E3, "¡boooing!" | **CS**. Video: no (termina en la pose real del nivel) |

**Al terminar la transición** (en este orden, sin pausa ni "¿seguimos?", ficha §21 decisión 6):

1. **E3, la 1.ª vez por familia**: la presentación del trampolín (§25.5.3).
2. **Sin intro corta**: al empezar E2 y E3 **no** suenan `intro_coleccionauta` ni `intro`. La llegada ya
   es la voz del Coleccionauta y la regla "por turnos" ya la conocen. La intro corta sí suena en cada
   intento nuevo de la etapa (tras el rearmado, §7.5) y al retomar (§25.6). Es una nota para mecánicas
   (§25.9, punto 3).
3. **La puerta de Maxi**: `reiniciar_rival("maxi")` y "¡le toca a Maxi!", como en todo intento.

**Tramo sin tocar entre etapas**: 5,5 + 4,0 ≈ **9,5 s** (≈ 13,3 s antes de E3 la 1.ª vez, con el
trampolín). Es la mitad del tramo del derribo final (≈ 19 s, §4.2) y termina siempre en un turno de Maxi,
que es un acierto seguro.

**Si la voz de llegada no existe todavía** (HE-86): la transición se hace igual, sin voz, con el motivo de
kazoo a 0 dB. No se traba.

### 25.5 Las presentaciones de cada etapa

| Etapa | Qué la presenta | Cuándo | Se salta |
|---|---|---|---|
| E1 | La presentación T.1 (§3, T1-T3) + la intro corta + **el confeti** (§25.5.2) | Al tocar el 4.º hito tras la pausa | T.1 desde la 2.ª vez; el confeti, una vez por familia y se corta al tocar |
| E2 | Su transición (§25.4), con `etapa_2_llega` | Tras la caída corta de E1 | La transición no; la caída, desde la 2.ª vez |
| E3 | Su transición, con `etapa_3_llega` (dice "la última", R21) + **el trampolín** (§25.5.3) | Tras la caída corta de E2 | Ídem; el trampolín, una vez por familia y se corta al tocar |
| La bandeja de Nicole | §25.5.4 | Su 2.º turno de la sesión, la 1.ª vez por familia | Se corta al estirar |

#### 25.5.1 E1: la presentación T.1 con el provisional plano por plano

Los planos son los del §3. **v5**: la pila de T1 incluye las 3 cajas de confeti y, con el último "pop",
aparece el indicador de las 3 torrecitas (sin voz y sin tiempo extra).

| # | Provisional ahora | Video después |
|---|---|---|
| T1 (apila en cámara rápida) | **CS**: la misma `armar_torre(por_filas)` de la transición, pero las piezas salen **de la mochila** (en (990, 520)) en vez de llegar del borde, a ritmo de "caja, frasco, caja". Él aparece en la cima con un salto | **No**: es la torre real de E1. Si algún día hay video, cubre solo T2-T3 |
| T2 (se estira hacia el arcoíris) | **TJ**: la escena congelada con él en la cima; un tween de estirarse (escala y +6 % y mano +5 px) en «...de la mano» | **Sí, como inserto**: primer plano de él de puntillas, sin mostrar la torre entera; fundido a la escena real |
| T3 (Coco y la resortera) | **TJ**: Coco con un giro de 360° y la resortera que aparece con "boing" | **Sí, como inserto**, o se queda en TJ: es barato y suficiente |

#### 25.5.2 El confeti (E1, la 1.ª vez por familia; ≈ 3,8 s)

Va **después de la intro corta y antes de la puerta de Maxi**. Así la novedad queda pegada a la acción.

| # | Tiempo | Qué se ve | Acción y animación | Voz | SFX | Provisional / video |
|---|---|---|---|---|---|---|
| PC1 | 0,0-0,8 | Las 3 cajas de confeti | **Halo violeta** de 0,8 s (ficha §25.3) y las tres laten a la vez. Él, arriba, se asoma con las gafas-lupa a mirar la más cercana (un foco: él no habla) | — | "Tin" triple | **CS**: halo por código y escala. Video: no |
| PC2 | 0,3-3,3 | Ídem | En «¡pomf, fiesta de confeti!», **la tapa de la caja más cercana se levanta y suelta un puñadito de confeti** (6 partículas) y se vuelve a cerrar: una muestra sin romperla | `arcoiris_batalla_torre_confeti_presenta` (≤ 3 s) | Un "pomf" chiquito, blando | CS. Video: no |
| PC3 | 3,3-3,8 | Él | Aire: se ríe con los hombros arriba (le hizo gracia, nunca susto, R20) | — | — | CS |

La intro corta termina con Coco (`intro`) y la línea del confeti también es suya. Para que no suenen
como una sola tira, **el foco visual cambia** a las cajas (el halo de PC1) y hay 0,3 s de aire entre
`intro` y PC2.

#### 25.5.3 El trampolín (E3, la 1.ª vez por familia; ≈ 3,8 s)

Va **justo después de la transición a E3**. La transición ya mostró el trampolín en uso (lo lanzó a él):
esta presentación lo nombra.

| # | Tiempo | Qué se ve | Acción y animación | Voz | SFX | Provisional / video |
|---|---|---|---|---|---|---|
| PR1 | 0,0-0,8 | Los dos trampolines | Halo violeta de 0,8 s; los dos se aplastan y estiran una vez | — | "Boing" doble | CS. Video: no |
| PR2 | 0,3-3,3 | Ídem | En «¡pero hacen boing!» **la pelusa-nubecita (N12) cae sobre un trampolín y sale rebotando** hacia arriba; él la sigue con los ojos y queda bizco (ojos A1-o) | `arcoiris_batalla_torre_resorte_presenta` (≤ 3 s) | "Boing" agudo | CS (reutiliza N12). Video: no |
| PR3 | 3,3-3,8 | Él | Aire: se sacude la bizquera | — | — | CS |

El trampolín **siempre se ve limpio y verde** (ficha §25.5.2), también en la caída final.

#### 25.5.4 La bandeja de Nicole: una cosa nueva por turno

- **Problema**: en el **primer** turno de Nicole de la sesión ya va la explicación del tiro con la manito
  fantasma (§3.1, `lanzar_primer_tiro`). Si en ese mismo turno se presentara la bandeja, una niña de 5
  años recibiría `carga` + `primer_tiro` + `elige_globo_presenta_nicole`: ≈ 8 s de instrucciones y dos
  cosas nuevas a la vez.
- **Dirección**: la bandeja **se presenta en el 2.º turno de Nicole de la sesión**, la 1.ª vez por
  familia. En el 1.º, la bandeja **ya está a la vista** con el normal cargado (ficha §25.6.4): si la
  toca, funciona igual, pero nadie se la explica todavía.
- **Plano PN** (≈ 3,5 s, al abrirse su puerta en ese turno): halo violeta de 0,8 s sobre la bandeja; **el
  rebotón da dos saltitos en su casilla** ("boing-boing") y suena
  `arcoiris_batalla_torre_elige_globo_presenta_nicole` (≤ 3,5 s), **en lugar de `carga`** en ese turno
  (el color del globo se ve igual). La voz no bloquea: si estira, se corta en 0,15 s (§0, regla 13).
  **Provisional**: CS por código. **Video**: no.
- **Si la ficha mantiene el disparador original** (el 1.er turno), la secuencia en ese turno es `carga` →
  manito con `primer_tiro` → PN solo después de su primer tiro, en el pase. Es peor, pero no se traba. Nota
  para mecánicas en el §25.9, punto 4.

### 25.6 Retomar después de un guardado entre etapas (re-entrada corta y saltable)

**Qué quiere el PO (R17 = A)**: que la Torre larga se pueda cortar entre etapas sin perder nada. La
pregunta de dirección es **qué ve la familia al volver**, otro día, para entender en dos segundos dónde
iban, sin texto y sin repetir lo que ya vieron.

**El camino de vuelta** (sin cambios, `batalla_arcoiris.md` §10 y `modo-equipo.md` §14.6): hito de la
batalla en el mapa del planeta → "¡todos a la nave!" corta → despegue corto con `nucleo_batalla_retomar`
(«¡seguimos donde quedamos!») → iris → **la re-entrada de la Torre** (este §).

**Saltable desde la 1.ª vez** (excepción a la regla 6 del §0, con id `arcoiris_batalla_final:retomar_torre`).
Un toque deja la etapa lista y abre la puerta de Maxi. **Motivo**: todo lo que muestra ya lo vieron (la
intro suena en cada intento) y viene justo después del ritual de "¡todos a la nave!", así que una
espera más no aporta nada. **Nunca dura más de ≈ 8 s.**

#### 25.6.1 Caso A · la etapa estaba a medias (hubo al menos un tiro; ≈ 5 s)

| # | Tiempo | Qué se ve | Acción y animación | Voz | SFX | Provisional / video |
|---|---|---|---|---|---|---|
| RA1 | 0,0-0,4 | La etapa guardada **tal cual** (ficha §12): torre, charco, manchas y la cara del agarre | El iris abre. Él, arriba, con **los lunares de las etapas ganadas** (§25.2.3) | — | — | **CS**: es el estado restaurado. Video: no |
| RA2 | 0,4-1,6 | El indicador | **Las torrecitas ganadas destellan una por una** (0,3 s cada una, "tilín" con nota) y la de la etapa en curso late. Sin voz: "esto ya lo ganamos, vamos por esta". En E1 (ninguna ganada), solo late la primera | — | "Tilín" (do, mi) | CS por código. Video: no |
| RA3 | 1,6-2,6 | Él | Palmotea la caja de arriba, orgulloso | `arcoiris_batalla_torre_intro_coleccionauta` («¡Torrecita!», 1 s) | — | CS (o TJ) |
| RA4 | 2,8-5,0 | Coco | Saca la resortera con un giro | `arcoiris_batalla_torre_intro` (2,2 s) | "Boing" de goma | CS (o TJ) |

Después, si se agregaron globos al retomar (mínimo 5, ficha §25.4), suena `encontre_globos` (motor) y se
abre la puerta de Maxi.

**Si salieron en la pausa de una derrota**: es el caso A con el intento nuevo ya guardado y la canasta
llena (ficha §12). Lo que le había caído encima en ese intento no se restaura: es otro día.

#### 25.6.2 Caso B · la etapa no tenía tiros (se fueron en la caída corta, en la transición o antes del primer tiro; ≈ 7,7 s)

Aquí **la etapa se presenta otra vez**, porque probablemente no la alcanzaron a ver.

| # | Tiempo | Qué se ve | Acción y animación | Voz | SFX | Provisional / video |
|---|---|---|---|---|---|---|
| RB1 | 0,0-1,2 | **La plataforma vacía**, con el charco chico | Iris. Las torrecitas ganadas destellan (como RA2) | — | "Tilín" | CS. Video: no |
| RB2 | 1,2-5,2 | La torre de la etapa llega | **TR3 + TR4** de la transición (§25.4), sin TR1 ni TR2: las antenas asoman, la torre llega por filas y él vuelve al trono (en E3, por el trampolín) | `etapa_2_llega` o `etapa_3_llega` (≤ 3,5 s), desde 1,4 | Los de TR3-TR4 | CS. Video: no |
| RB3 | 5,5-7,7 | Coco | Saca la resortera | `arcoiris_batalla_torre_intro` (2,2 s): es la regla, que tras un día conviene oír. Sin `intro_coleccionauta`, porque ya habló él | "Boing" | CS (o TJ) |

- **En E3, si la presentación del trampolín no se vio**, va entre RB2 y RB3 (§25.5.3).
- **E1 sin tiros** (se fueron en la presentación T.1 o en el confeti) no es un caso nuevo: la
  presentación T.1, si no se vio, o la intro corta, si ya se vio. Igual que en la v4.
- **Nota para el guion** (HE-86): `etapa_N_llega` también suena aquí, **sin una caída antes**. El texto
  no debe depender de la caída (por ejemplo, sin el «¡Splash!» de la idea de la ficha) o hace falta una
  variante `_retoma`. Ver el §25.10.

#### 25.6.3 Salir en cada momento: dónde vuelven

| Salen durante… | Al volver ven… |
|---|---|
| Un turno de cualquier etapa | Caso A en esa etapa |
| Un gag de derrota o la pausa de Coco | Caso A, con el intento nuevo guardado |
| **La caída corta o la transición de E1 → E2** (o de E2 → E3) | **Caso B en la etapa siguiente**: nunca vuelven a la que ya ganaron. Necesita que el parcial se guarde **en el cuadro del derribo de etapa** (nota del §25.9, punto 1) |
| La presentación del confeti o del trampolín | Caso B, o T.1 en E1. La presentación sigue sin marcarse vista y vuelve a sonar |
| La anticipación o la caída final (E3) | Sin cambios respecto de la v4 (lo resuelve `batalla.gd` con la ronda `torre`) |

**La señal de "guardado"** (CE6): la estrellita que vuela de la torrecita a la casa es para los papás.
Les dice sin palabras que salir ahí es seguro. **No invita a salir**: no tiene voz, no hay pregunta y la
transición sigue sola.

**En el mapa de batalla** (opcional y barato, por código): el 4.º hito muestra el indicador de torrecitas
al 50 %, con las ganadas pintadas. Solo se ve si pasan por el mapa de batalla. Si no se hace, no cambia
nada.

### 25.7 El derribo final en E3: composición y provisional de la anticipación, la caída y los gags

#### 25.7.1 Ajustes de composición a E3 (C1)

- **K3 (tambaleo)**: el pivote sigue en (990, 584). La torre de E3 es angosta, así que los ±9° se leen
  mejor que en la v4. **Los flancos se tambalean con el centro** (son parte del sprite del conjunto).
- **K4 (inclinada 11°)**: igual. Él cuelga del cojín en x ≈ 990, sobre la columna central.
- **C1 (la torre se rinde en cámara lenta)**: los flancos se abren hacia afuera, uno hacia cada lado. Los
  **frascos de base** (x ≈ 825 y ≈ 1155) **ruedan hacia afuera** hasta x ≈ 760 y x ≈ 1220, para no quedar
  sobre el charco (que en el derribo mide ≥ 360 px: x ≈ 810-1170). Los **trampolines salen girando**
  hacia los costados.
- **C2 (gag nuevo, sin tiempo extra)**: uno de los trampolines **cae parado** junto al charco, en
  x ≈ 1190. Él, al volver la velocidad normal, **rebota una vez en él** ("¡boooing!" grave, 0,5 s) y
  entonces aterriza en el charco (C3, igual que antes). Así la pieza nueva de E3 paga su chiste en el
  final. Es acolchado y nunca un golpe.
- **C3 (lunares)**: nivel 3, el N3 completo.
- **Estado final** (§4.2): igual, con el trampolín de C2 parado junto al charco como decorado.

#### 25.7.2 Provisional y video del derribo final y de los momentos del motor

| Planos | Provisional ahora | Video después |
|---|---|---|
| K1-K5 (anticipación) | **CS**: cámara lenta con `speed_scale` del `AnimationPlayer` y de los tweens (nunca `Engine.time_scale`); retratos con los cachetes inflados por textura; el silencio de K4 es solo audio | **No**: parte de `estado_derribo()` y el silencio necesita la torre real |
| C1-C2 (la torre se rinde y el rebote en el trampolín) | **CS**: interpolación de las piezas reales | **No** (es la torre real) |
| C3-C6 (splash, lunares y fiesta máxima) | **CS** | **Sí, como inserto** a pantalla completa desde C3: él en el charco, chapoteando. Los retratos que saltan, el confeti de los costados y la barra quedan en la UI, encima del clip. Fundido al estado final del §4.2 |
| Gags G1, G2 y G4 | **CS**: el sprite del Coleccionauta con meneo, los props como sprites que caen y el cambio a "rosado", "calcetín" o "chicle" por `modulate` o sprite superpuesto. **TJ** si falta el CS: la escena congelada + el prop + la voz | **Sí, como inserto** de la parte del Coleccionauta (G1a-G1c, G2a-G2b y G4a). La risa de Coco, el logro y la ayuda siguen en CS sobre la escena real. Al salir del clip, lo que le cayó encima se ve en el sprite (regla del §7.1) |
| Gag G3 (el globo que vuelve) | **CS**, con el color real del globo | **Sí, pero con 3 clips** (rojo, amarillo y azul), para respetar la regla del color (ficha §10.1). Si el presupuesto no alcanza, queda en CS |
| Rearmado R1-R3, presentaciones del confeti y del trampolín, bandeja, caída corta CE1 y CE6, transición y re-entrada | **CS** | **No** (dependen del estado o son UI) |
| Caída corta CE2-CE5 | **CS** | **Sí, como inserto**: 2 clips (lunares nivel 1 y nivel 2) |
| Gigante GG1 (Coco lo infla) | **CS** | **Sí, como inserto** (no depende del estado). GG2-GG5, no |

**Lo que el video agrega de verdad en la Torre**: los primeros planos de él (caídas, gags) y de Coco
(gigante). Todo lo demás se queda en cutout para siempre, porque es el juego. Esto acota el presupuesto
de video de la Torre a **10 clips cortos, 11 con el opcional** (2 de caída corta, 1 de la caída final, 6 de
gags contando los 3 del globo que vuelve, 1 del gigante y, opcional, 1 de T2): es un dato para cuando el
PO evalúe el presupuesto.

### 25.8 La revancha con 3 etapas (ficha §25.15)

| Pieza | En la revancha |
|---|---|
| Entrada | `intro_revancha` + la intro corta, en E1 (sin T.1 ni el confeti, ya vistos) |
| Caída corta (E1 y E2) | Sí, y se salta con un toque (ya vista) |
| Transición | Sí, entera (≤ 4 s): orienta igual |
| Presentaciones del trampolín y de la bandeja | No (ya vistas por familia) |
| Indicador de torrecitas | Sí, empieza gris otra vez (es otra jugada) |
| Lunares | Empiezan en cero y crecen igual |
| Derribo final | Como el §14: anticipación entera, caída saltable, mini fiesta y estrellitas (solo con los tres) **después de E3**, nunca entre etapas |
| Salir a la mitad | **Sin parcial** (ficha §25.15): la próxima revancha empieza en E1 y no hay re-entrada. Si `modo-equipo.md` §14.16 suma `etapa` al parcial de la revancha, se usa la re-entrada del §25.6 tal cual (§25.9, punto 5) |
| **Si el PO elige "solo E3"** (ficha §21, decisión 7) | `intro_revancha` → la torre de E3 llega con TR3-TR4 **sin voz de llegada** (el kazoo a 0 dB) → la intro corta → la puerta de Maxi |

### 25.9 Notas para `disenador-mecanicas` (la ficha y `modo-equipo.md` §14.16; no las edito)

Ninguna bloquea el storyboard: cada una dice qué pasa si no se adopta.

1. **Guardar el parcial en el cuadro del derribo de etapa** (además de "al empezar cada etapa"), con
   `etapa` = la siguiente y la ganada sumada a `etapas_ganadas`. Así salir en la caída corta o en la
   transición (≈ 9,5 s, con la casa a la vista) nunca devuelve a una etapa ganada (ficha §12 v4: "nunca a
   una que ya ganaron") y vuelve al caso B. **Si no se adopta**, esa ventana devuelve a la etapa ganada,
   y la señal de guardado de CE6 pasa al final de TR4.
2. **"Etapa sin tiros"** (caso B del §25.6.2): sale del parcial (intento 1, agarre perdido 0 y ningún
   bloque cambiado) o de un campo `etapa_iniciada: false`. Lo que prefiera la ficha; el storyboard solo
   necesita saber en qué caso está.
3. **La intro corta no suena al empezar E2 y E3** (la reemplaza la llegada); sí en cada intento nuevo y
   al retomar (§25.4). **Si se prefiere que suene**, va después de la llegada y antes de la puerta (+3,4
   s por etapa).
4. **La presentación de la bandeja de Nicole va en su 2.º turno de la sesión** y reemplaza a `carga` en
   ese turno (§25.5.4). **Si se mantiene el 1.º**, va en el pase después de su primer tiro.
5. **§14.16, `etapa` en la revancha**: el storyboard funciona con las dos opciones (sin parcial: empieza en
   E1; con parcial: re-entrada del §25.6). Si la revancha guarda la etapa, la regla de las estrellitas
   (★★ "sin perder ninguna etapa") la fija la ficha.
6. **Ids de momentos saltables**: `<id_batalla>:caida_etapa` (uno solo para E1 y E2) y, nuevo,
   `<id_batalla>:retomar_torre` (desde la 1.ª vez). Los marca `batalla.gd` con el mecanismo genérico; el
   núcleo no sabe qué hay dentro.
7. **Sin estado nuevo para lo visual**: los lunares y el indicador salen de `etapas_ganadas`, y la posición
   del trono y las filas del armado salen del nivel.

### 25.10 Conciliaciones de la ficha v4 que son de otras tarjetas (solo anotadas)

| Ficha | Tarjeta | Lo que este storyboard le deja anotado |
|---|---|---|
| C3 (fondo y arte) | **HE-74** (`disenador-personajes`) | Además del fondo estilo menú de planetas, el confeti, el resorte y el rebotón: **N3b** (lunares en 3 niveles), **N22** (torrecitas, puede ser por código), **N23** (corriendo en rueda, con el cojín en la cabeza y lanzado por el trampolín) y **N24** (nubecita "puf"). El trampolín **siempre limpio y verde**; la caja de confeti con una **tapa que se levanta** (PC2) |
| C4 (voces) | **HE-86** (`guionista`) | `caida_etapa_01/_02` ≤ 1,5 s y del Coleccionauta, con la imagen de CE5 (se mira los lunares). **`etapa_2_llega` y `_3_llega` suenan también al retomar sin caída** (caso B): mejor sin «¡Splash!», o una variante `_retoma`. `_3_llega` dice "la última" (R21). `elige_globo_presenta_nicole` reemplaza a `carga` en ese turno (§25.5.4). Al empezar E2 y E3 no suena la intro corta (§25.4): conviene que la llegada no repita «¡Torrecita!» |
| C6 (`etapas[]`) | **HE-80** (`disenador-niveles`) | **La última fila de cada torre es su novedad** (en E2, el puente y sus frascos; en E3, los trampolines) porque la transición la deja para el final (TR3). El armado agrupa las piezas en **filas por la `y` inferior de su `rect`** (tolerancia de 12 px), sin campo nuevo. El trampolín de E3 tiene que dejar un camino de arco hasta la cima para TR4 (es animación: no depende de la física) |
| C5 (`modo-equipo.md`) | HE-88 (`disenador-mecanicas`) | Ver el §25.9 |

### 25.11 Notas de implementación (`AnimationPlayer` y tweens)

- **Dónde**: todo lo de este § es del motor `lanzar` (dueño de la torre): un nodo `Cinematicas` con su
  `AnimationPlayer` y el reproductor de ganchos (§25.1). Si el reproductor se escribe genérico (no sabe de
  torres: solo lee el JSON del gancho, elige la implementación, programa voces y SFX y emite
  `terminado`), puede vivir en `scripts/base/` y reutilizarse en Animalia. Eso lo decide `dev-godot`.
- **`armar_torre(por_filas, origen)`**: genera los tweens desde el nivel. Agrupa las piezas por la `y`
  inferior, ordena de abajo hacia arriba y hace un arco desde `origen` hasta el `rect` de cada pieza (≤
  0,3 s por fila). Si hay más filas que las que caben en 2,0 s, comprime el intervalo y nunca alarga la
  transición. Se usa con `origen` = (1320, 260) en la transición y en la re-entrada, y con `origen` = la
  boca de la mochila en T1.
- **Caída corta**: las piezas interpolan de `estado_derribo()` a una **"corona" de poses** alrededor del
  charco (fuera de x 810-1170 o detrás de su borde lejano), calculada por código según la cantidad de
  piezas. Sin física (ficha L9), igual que la caída final.
- **Sin cámara lenta** en la caída corta ni en la transición. La cámara lenta es solo de la anticipación y
  de C1 de la caída final, con `speed_scale`.
- **Sincronía por pasos** `{animacion, voz, solape_s, aire_s}` (§20). **Manda el audio**: si
  `etapa_N_llega` dura más de 3,5 s, se acortan primero TR2 y el aire de TR4, **nunca** pasa de 4,0 s. Si
  no cabe, se le pide al guionista una toma más corta.
- **Capas**: el clip de video (cuando exista) va en un `CanvasLayer` **debajo** de la UI (casa, Cometa,
  barra e indicador). El indicador va en la capa de la UI, a `z_index` 60 (como la barra).
- **El charco que se escurre** (TR2): tween de `ancho` y `alto` hasta los valores iniciales de la etapa;
  los colores del charco nuevo arrancan vacíos.
- **QA** (`tester-qa`):
  - la caída corta dura ≤ 5,5 s y la transición ≤ 4,0 s con el audio real;
  - la transición no se salta y la caída corta se salta desde la 2.ª vez;
  - la re-entrada se salta desde la 1.ª vez;
  - salir en la caída corta o en la transición vuelve al caso B de la etapa siguiente (con la nota 1);
  - **con cada implementación (V, CS, TJ y PD), el estado final y el parcial son idénticos**;
  - sin un asset de video, el gancho baja a CS sin error visible;
  - ningún dígito ni texto en el indicador.
