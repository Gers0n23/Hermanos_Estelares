# Re-auditoría UX corta — HE-71: La Torre de la Colección y el cierre de Arcoíris

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 17-Oct-2026
- **Informe anterior**: `docs/validaciones/2026-10-13_ux-torre-cierre-arcoiris.md` (APROBADA CON CAMBIOS:
  B1-B2, M1-M11, m1-m11).
- **Qué se revisó**: los changelogs y las secciones que citan de:
  - `docs/fichas/motor-lanzar.md` v3 (§24; §4, §5.1-§5.3, §6, §8, §19);
  - `docs/cinematicas/cierre_arcoiris.md` v4 (§24; §0, §2, §3, §6-§13, §16, §18);
  - `docs/guiones/cierre-arcoiris.md` v4 (§14);
  - `docs/guiones/voces-batalla-arcoiris.md`;
  - `docs/fichas/modo-equipo.md` v7.2 (§14.16 y su changelog).
- **Alcance**: solo diseño. No se corrigió ningún documento.

## Veredicto: APROBADA CON CAMBIOS (0 bloqueantes)

**B1 y B2 están resueltos**, así que por UX **la tarjeta de diseño HE-71 se puede cerrar**. Los cambios que
siguen son mejoras y se pueden incorporar antes de implementar el bloque 2 o durante su implementación,
sin otra re-auditoría de diseño.

| Severidad | Cantidad |
|---|---|
| Bloqueante | 0 |
| Mejora | 3 (N1-N3) |
| Pulido | 5 (P1-P5) |

## 1. Hallazgos anteriores → estado

| Hallazgo | Estado | Evidencia |
|---|---|---|
| **B1** Storyboard conciliado con un guion descartado | **Resuelto** | Storyboard v4 conciliado con el guion v4, la ficha v3 y `modo-equipo` v7.2 (encabezado, índice §2.1, lista de retirados). Revisé las 12 filas de la tabla de B1: cuenta de a uno con 8/20/15 s (§12.1), Coco encaja el ala y los broches se giran por color (§9.4), recordatorio a los 8 s y Coco choca sola a los 20 s, sin `coco_abrazo` (§10), `papa_pista` + `papa_guatita` sin `papa_02` (§11), una sola pausa (§3), `torre_pausa` (§7.1), `cae_lenta`/`cae_charco`/`cae_risa` (§4.2), ≤ 6 s con audio real (§5.1), ids de gags y del bloque 2 y frases de fin de tarea iguales para los tres. No queda ningún `arcoiris_partida_*` de voz |
| **B2** Un toque gasta un globo | **Resuelto** | Ficha §5.2: hay disparo solo con un arrastre real (≥ 40 px desde el contacto) **y** un estiramiento final ≥ 40 px. Si el contacto cae con x > 260, la bolsa no salta. Dentro del círculo manda la resortera (§5.1). Coco tiene los pies en (85, 584), a 132 px de la bolsa, y el ramo queda en x ≤ 120 (§4). QA en grilla de 20 px (§20). Queda el residual R6 (ver N1) |
| M1 Primer tiro sin explicación | Resuelto | `nucleo_equipo_lanzar_primer_tiro` (2,6 s) + manito de 0,8 s; no bloquea (ficha §5.2.1, storyboard §3.1) |
| **M2** Estabilizador | **Resuelto** | Ficha §5.2.2: se descartan los últimos 60 ms y se usa la última muestra quieta (< 150 px/s); ese cuadro manda en el vector, en la regla de 40 px y en el anillo; QA ≤ 10 px |
| **M3** Dibujo y física desalineados | **Resuelto** | Bloques a 0° al apuntar y en vuelo, ±1° el resto; trono ±6°; el `Area2D` sigue al sprite (ficha §6.1, §6.2.2, §6.6, §14, QA §20) |
| **M4** 3 contra 2 y el último globo de Nicole | **Resuelto** | Reparto 9 + 4 con reinicio en Maxi: N = S (2/2 y 3/3) y el último globo siempre es de Maxi; el retomado se redondea a 5/9/13 (ficha §8.1, §8.3, §12; `modo-equipo` §14.16). Lo que queda es el costo de R12 (Sofía hace 2 de 9 tiros), que ya se acepta para medir en el playtest |
| **M5** Dedo apretado de Maxi | **Resuelto** | `semilla_mantener_s` 1,2 s ± 0,1 s, chispita que sigue al globo, líneas «toca… ¡y suelta!» (ficha §5.3; guion T.2) |
| M6 Pausa duplicada | Resuelto | Una sola pausa, en el mapa de batalla y antes de T.1 (ficha §13.3, storyboard §3, `modo-equipo` §14.16) |
| M7 Gag 1 lento | Resuelto | Frasco a los 2,1-2,4 s y «¡Sigo arriba!»; las risas van en el remate (storyboard §7.2) |
| M8 Candado social | Resuelto | Línea de estado junto a la llave; dos hermanos + el retrato del tercero (regla 12, §16.4); `009b` sin "también", con la misma fiesta que `009a` |
| M9 Tocar Animalia antes de la partida | Resuelto | Lejana y sin candado, late en < 100 ms, máx. una línea por visita, flechita a Arcoíris (storyboard §13.1) |
| **M10** Estrellas pegadas a Cometa, casa y mapa | **Resuelto** | Campo `Rect2(150, 128, 980, 440)`. Medido: 32 px en x / 28 px en y de Cometa, 42 px de la casa y 40 px del mapa (y 8-88). Nada tocable bajo y 696 (storyboard §9.5) |
| M11 "Bup" al arrastrar | Resuelto | En arrastre solo cuenta la correcta siguiente; el "bup" es solo de un `press` (§9.5 SO2) |
| m1-m11 | Resueltos | Ficha §24.2 y storyboard §24. m5: la manopla se activa al terminar la voz; después cualquiera puede chocarla, y cuenta para el hermano que brilla (aceptable). m7: retratos de la cuenta medidos con ≥ 24 px entre ellos y de Cometa |
| Decisiones 1, 3-7 | Aplicadas | Por delegación del PO (storyboard, encabezado) |
| Decisión 2 (pausa entre bloques) | **Pendiente del PO** | El storyboard §8.1 la sigue marcando `[PO, duda 1]`. Opinión en el §3 |

## 2. Hallazgos nuevos

### N1 (mejora). R6: un arrastre de Maxi en el turno de una hermana todavía dispara su globo

**Dónde**: ficha §5.2 ("Toques ajenos") y §19 R6.

**Problema**: B2 cerró el caso del toque, pero un niño de 2 años que mira **barre** la pantalla con el dedo:
un arrastre rápido sin pausa. Si el suyo es el primer dedo dentro del círculo, sale el globo de Sofía.
Con el reparto 9 + 4 ella tira **solo 2 globos por intento**, así que perder uno es el 50 % de su
participación y el reclamo cae con nombre («¡Maxi me gastó el globo!»). La ficha lo deja para medir en el
playtest, pero no deja preparada ninguna salida.

**Corrección** (`disenador-mecanicas`, barata y lista para activar):

- Nueva clave `cancelar_tiron_sin_pausa` (default **false**). Si está activa, en los turnos de Brote y
  Estrella, un gesto que **no tuvo ninguna muestra quieta** (el estabilizador ya lo detecta: §5.2.2 paso 3)
  **y** que duró < 0,35 s desde el contacto se cancela con "plop" y no gasta el globo. Las niñas que
  apuntan siempre se detienen un instante; el barrido de Maxi, no.
- **Instrumentar desde ya** (en el log del playtest): duración del gesto, si tuvo muestra quieta y el
  turno. Si en el playtest aparece un solo globo "robado", se activa la clave sin tocar el código.
- La ventanita de porra de Maxi tiene que estar viva y ser llamativa en los turnos de las hermanas: es su
  "lugar para tocar".

### N2 (mejora). El tramo pasivo real del bloque 2 no son 31 s, sino ≈ 54 s

**Dónde**: storyboard §10 (D5-D7), §11 (V1-V9) y §18 ("Para UX").

**Problema**: al pasar la foto a la partida, quedaron seguidas tres piezas sin toque obligatorio:

| Pieza | Duración | Toque |
|---|---|---|
| D5-D7: fin de la despedida (Coco abraza a Cometa, cierre, hangar) | ≈ 10,4 s | Ninguno |
| V1-V2: la foto | ≈ 13 s | El sobre, opcional: se abre solo a los 3 s |
| V3-V9: abordaje + llamada | ≈ 30,5 s | Ninguno |

Son **≈ 54 s pasivos**, prácticamente el mismo tramo de ≈ 55 s que el m6 corrigió en el bloque 1, y llegan
cerca del final de la sesión, cuando Maxi está más cansado. La voz de papá atrapa (es el mejor contenido
del bloque), pero 54 s seguidos están por encima de lo que un niño de 2 años aguanta sin hacer nada.

**Corrección** (`director-cinematicas`; no hacen falta voces nuevas):

1. **El sobre de la foto espera un toque de verdad**: que se abra solo a los **6 s** (no a los 3), con un
   target de ≥ 200 px que late y que puede tocar cualquiera.
2. **"Contestar" la llamada**: en V4, antes de abrir la burbuja, la antena vibra con un "ring-ring" de
   juguete y un teléfono-estrella de ≥ 200 px late. Al tocarlo (cualquiera, < 100 ms) se abre la burbuja.
   Si nadie lo toca, se abre sola a los 5 s. A los 2 años, "contestarle a papá" es el gesto más
   significativo de todo el bloque.
3. Opcional: en V6, las huellas (perrito y dinosaurio) se pueden tocar **cuando termina** `papa_pista`
   ("guau" / "grr" de juguete), sin pisar la voz.
4. Se mantiene el plan B: si Maxi se va igual, el primer recorte es `papa_guatita`.

Con 1 y 2, el tramo queda partido en ≈ 10 + 13 + 5 + 26 s, cada parte separada por un toque.

### N3 (mejora). Bloque 1: después del epílogo siguen ≈ 47 s con un solo toque

**Dónde**: storyboard §6.1-§6.3.

**Problema**: cierre A (19,8 s) + fiesta (9,4 s) + parte C (≈ 18 s después del toque del papel) suman
≈ 47 s con un único toque en el medio. Es aceptable porque viene después de 75 s de epílogo interactivo y
la fiesta muestra a los tres retratos. Pero el choque de manos de la fiesta (B3) es un momento ideal para
que lo hagan ellos.

**Corrección**: en B3, las manos al centro **esperan un toque de cualquiera** (target ≥ 200 px en el punto
de choque) y siguen solas a los 4 s. Si el PO prefiere no alargar el bloque, que quede como pulido para
después del playtest.

### Pulido

- **P1.** La ficha §19 R5 todavía dice "mínimo 4 globos". Desde la v3 son 5, redondeados a 5/9/13 (ficha
  §8.1 y §12, `modo-equipo` §14.16). Hay que alinearla.
- **P2.** El storyboard §2 da ≈ 28 s para la llamada, y el §11 y el §18 dan ≈ 31 s. Hay que dejar un
  solo número.
- **P3.** El guion v4, en la nota de `arcoiris_batalla_cierre_pausa_partida`, remite a "storyboard §10.1,
  duda 2 del PO". En el storyboard v4 la pausa es el §8.1 y es la duda 1. Hay que corregir la referencia.
- **P4.** En la pausa entre bloques, el mapa flota sobre la nave (storyboard §8.1). Hay que decir que el
  mapa **no es tocable**, o que su toque es parte del target de la nave. Si no, un toque al mapa no
  respondería o haría algo distinto.
- **P5.** Simetría de R6, ya presente en la v2: en el turno de Maxi, un toque **de una hermana** en
  cualquier parte de la zona de juego dispara el globo de él (ficha §5.3). Como su tiro nunca falla, no
  cuesta nada al juego, pero le quita a Maxi su momento. No hay que cambiar nada: solo observarlo en el
  playtest («¡yo lo quería tirar!»).

## 3. La pausa natural entre bloques (decisión 2, pendiente del PO)

**Recomiendo aprobarla tal como está en el storyboard v4 §8.1**, y que el PO la cierre ya:

- **Está en el corte natural de la historia**: terminó la batalla y empieza el viaje. La pantalla de espera
  es la nave brillando con el mapa recién encontrado, el mejor gancho para volver. Nunca avanza sola, la
  casa está a la vista y la voz (`pausa_partida`) ofrece las dos opciones con el mismo peso, igual que
  `pausa_antes`.
- **Reparte bien la carga**:
  - Torre (5-7 min, p80 ≈ 11 con derrotas) + bloque 1 (2,4 min) ≈ **8-13 min** seguidos, ya separados de
    las rondas de color por la pausa antes de la Torre;
  - bloque 2 (3,6 min) queda como **una sesión corta y casi toda interactiva** (tanque, broches, ruta,
    despedida y cuenta). Empieza con la tarea de Maxi, lo que está bien: si vuelven otro día, él llega
    fresco.
- **Riesgo conocido**: los niños casi siempre eligen "¡seguimos!". En ese caso son ≈ 14-19 min seguidos
  desde la pausa de la Torre. Para Nicole y Sofía es razonable para el final del planeta; para Maxi está en
  el techo. Por eso importa N2: el tramo más pasivo cae justo al final de ese recorrido.
- **Retomar está bien resuelto**: hito sin alertas, ritual corto, primer paso pendiente y "lo hecho se ve
  hecho" (§16.3).
- **Playtest**: anotar qué eligen en la pausa, y si siguen, en qué minuto se va Maxi (¿antes o después de
  la llamada?).

## 4. Pendientes

Ninguno bloquea el cierre de HE-71.

1. **PO**: cerrar la decisión 2 (pausa entre bloques). Mi recomendación es que sí.
2. **`director-cinematicas`**: N2 (sobre a los 6 s y "contestar" la llamada), N3 (opcional), P2 y P4.
3. **`disenador-mecanicas`**: N1 (clave `cancelar_tiron_sin_pausa` apagada e instrumentación del gesto) y
   P1.
4. **`guionista`**: P3.
5. **Después del build**: auditoría UX sobre las escenas y playtest con los tres. Hay que medir:
   - globos disparados por otro hermano (R6, P5);
   - si Nicole entiende "hacia atrás" en su 2.º tiro;
   - las frases de culpa;
   - la cara de Sofía en el gag 1;
   - el aburrimiento de Sofía con 2 tiros de 9 (R12);
   - el minuto en que se va Maxi en el bloque 2.
