# Validación HE-40 — `disenador-mecanicas`

- **Fecha**: 28-Sep-2026
- **Alcance**: mapa de zonas del Planeta Arcoíris (`docs/fichas/planeta-arcoiris-zonas.md`); mecánicas
  v3 de Sofía en `encajar` (botón espejo, pista con costo en estrellitas, regalo tras 2 derrotas, bandeja
  del reto dorado 6×10); cambio de memoria de `emparejar` (§3); motores nuevos `mezclar`, `clasificar` y
  `lienzo_libre` (fichas y código sin commitear en `scripts/motores/`).
- **Método**: lectura de fichas y del código (`motor_encajar.gd`, `pieza_encajar.gd`,
  `motor_emparejar.gd`, `motor_mezclar.gd`, `formas_estrella_dorado.json`). **No ejecuté escenas**: los
  valores marcados "estimado" debe confirmarlos `tester-qa` con F3 o con pantallazos.
- **Decisiones**: el PO pidió avanzar sin consultarle. Todos los cambios de este informe son
  **PROPUESTA** de `disenador-mecanicas` y los puede revertir el PO.

## Veredicto

**APROBADO CON CAMBIOS: no hay bloqueantes.** El mapa de zonas y los cuatro motores cumplen las reglas
por perfil del GDD §5-§6. Maxi nunca pierde. Nicole tiene un objetivo a la vez. Sofía tiene derrota-gag,
reintento de un toque y nada de lo logrado se pierde. Solo se usan toques y arrastres: no encontré
gestos de pellizco ni doble toque en `scripts/`.

Hay **7 hallazgos mayores** que conviene resolver antes del playtest con Sofía. Todos tocan su
frustración ("es llorona, se frustra rápido") o el reto dorado.

---

## Hallazgos

### A. Mapa de zonas (`planeta-arcoiris-zonas.md`)

**1. [MAYOR] La estación de Formas de Sofía dura demasiado y su escalera es solo de cantidad.**
Cada serie son 2 rondas (monumento + bandera) y cada monumento tiene 25-32 piezas. Son unos 55-60
arrastres con giro, es decir, unos 7-9 minutos (estimado). El GDD §3 dice "un nivel completo dura 2-5 min".
Además, la escalera v3 prometía "una regla nueva por zona" (§3.5), pero hoy `tangram_libre` y `memoria`
no se usan y el espejo solo aparece en el reto dorado. De zona a zona crece la cantidad de piezas, no
el tipo de reto, y 30 piezas se sienten como trabajo, no como reto.
*Propuesta* (los números finos los fija `disenador-niveles`):
- Monumentos de **16-20 piezas**, con el tope en z5.
- **Una regla cualitativa por zona**, reutilizando campos que ya existen:
  - z1: giro por toque.
  - z2: + `boton_espejo` en 2-3 piezas asimétricas (triángulo rectángulo, paralelogramo).
  - z3: + 2 `piezas_distractoras` casi iguales (±10 % de tamaño).
  - z4: + `modelo_mini` que se esconde a los 8 s y se vuelve a mirar con el ojo (cuesta 1 estrellita).
  - z5: todo junto.

**2. [MENOR] §3.1 no dice que Sofía ya no juega Lluvia.** Su estación abre `mezclar`
(`motor-mezclar.md`). La tabla y la nota de pools de Sofía describen un modo que el mapa ya no usa.
*Cambio (documentación)*: agregar una nota al inicio de §3.1 que apunte a `motor-mezclar.md` §4.

**3. [MENOR] La pieza de la nave llega tarde para Maxi.** Hay que completar las 12 estaciones de las
zonas 1-3, y con rondas son unos 35-45 min para Maxi, repartidos en varias sesiones. Es coherente con la
decisión del PO (zona completa), pero conviene que el mapa **muestre el avance hacia el ala**.
*Propuesta*: una silueta del ala junto a la zona 3 que se va pintando un tercio por zona completada.
Es solo visual y no cambia la regla. Lo implementa el núcleo (`mapa_planeta.gd`).

### B. `encajar`: mecánicas v3 de Sofía

**4. [MAYOR] La pista puede cobrarse por un toque accidental y el costo no se ve.** Un solo toque en el
botón dorado (1164, 16) coloca la pieza y resta la estrellita. Sofía no ve en ningún lado cuántas
estrellitas lleva: `_estrellitas_visibles` solo existe en el panel F3. Para una niña que se frustra
rápido, perder algo que no veía es la peor combinación. Además, cuando ya está en el piso de 1
estrellita, la animación de "estrellita que cae" sigue apareciendo aunque ya no le cueste nada.
*Cambios para `dev-godot`* (vale igual para `emparejar`, `clasificar` y la libreta de `mezclar`):
- **Medidor de estrellitas** junto al botón de pista: 3 estrellas de 34 px en fila, en (1040-1150, 40).
  Muestra `_calcular_estrellitas()` en vivo. Al gastar una, esa estrella es la que cae (0,9 s, igual que hoy).
- **Confirmación con dos objetivos distintos** (no es doble toque, GDD §6.4):
  - El 1.er toque en el botón no cobra. Se abre un globo de 150×150 px bajo el botón con la estrellita
    y la mano de Coco, y suena la voz `pista_confirmar` ("¿Te ayudo? Me das una estrellita").
  - Tocar el globo confirma.
  - Tocar fuera del globo, o dejar pasar 4 s, lo cierra sin costo. El globo se cierra con un rebote de 0,2 s.
- **En el piso de 1 estrellita** no hay globo ni estrellita que cae. La pista es directa y suena
  `pista_gratis` ("¡Esta va de regalo!").

**5. [MAYOR] En Sofía, colocar una pieza en su lugar pero chueca cuenta como fallo y la manda a la
bandeja.** Con giro en todas las zonas, 25-30 piezas que llegan giradas al azar y límites de 8-16 fallos,
el "está chueca" gasta el límite muy rápido. Además, obliga a buscar de nuevo la pieza en la bandeja.
La voz "está chueca" ya le avisa que acertó el lugar, así que devolver la pieza no protege ningún reto.
*Cambios*:
- Campo nuevo **`giro_cuenta_fallo`**: `false` por defecto en Estrella. Maxi y Nicole no cambian.
- Cuando solo falla el giro, la pieza **se queda sobre ese hueco**, semitransparente (alfa 0,7) y
  meciéndose ±4°, por **2,5 s**.
- Un toque la gira `paso_rotacion` ahí mismo. Si con eso calza, encaja con el clic normal.
- Si pasan los 2,5 s sin tocarla, o si la arrastra, vuelve a la bandeja como hoy.

**6. [MAYOR] El regalo tras 2 derrotas casi no ayuda y se adelanta desde la segunda ronda.**
- `colocar_pista()` regala **una** pieza, que en un monumento de 25-30 piezas es el 3 %. No cumple el
  "nunca queda trabada" del GDD §5.
- `_derrotas` no se reinicia en `_limpiar_tablero()`: `_regalo_dado` sí vuelve a `false`, pero
  `_derrotas` sigue acumulado. Por eso, en la ronda 2 el regalo llega con la **primera** derrota.

*Cambios*:
- Reiniciar `_derrotas = 0` en `_limpiar_tablero()`, igual que `_regalo_dado`.
- El regalo pone **`clampi(ceili(0.15 * pendientes), 1, 4)` piezas**, una cada 0,35 s. Cada pieza hace
  un saltito y brilla (`SEGUNDOS_PISTA`).
- Para elegir las piezas, primero van las que tuvieron más "no es este" en la ronda (llevar la cuenta
  por hueco) y después las más grandes.
- Voz `regalo`: "¡Te ayudo con estas!".

**7. [MAYOR] Las piezas de la bandeja del reto dorado 6×10 son muy chicas.** La bandeja
`zona_bandeja` [236, 470, 894, 238] recibe los 12 pentominós a la vez, con `lado_celda` 54 y giro al
azar. Si la I queda de pie (5 celdas = 282 px), `_empacar` baja el factor a **~0,40 (estimado)**: cada
celda queda de **~22 px** y un pentominó de ~65 px. Hay tres problemas:
- Los círculos tocables de 96 px (`RADIO_TOQUE_MINIMO`) se pisan entre piezas separadas por solo 16 px.
- La forma se lee mal.
- Al tomarla, la pieza salta ×2,5 de golpe.

Además, esto contradice el principio "Arma la figura" del PO (27-Sep): ver que la pieza calza.

*Cambios* (en `formas_estrella_dorado.json` y en el motor, solo para `mecanica: marco`):
- `lado_celda`: 54 → **50**. El tablero queda de 500×300.
- `zona_figuras`: **[236, 96, 900, 312]**.
- `zona_bandeja`: **[236, 416, 848, 292]**.
- Campo nuevo **`escala_bandeja_fija: 0.64`**: celdas de 32 px en la bandeja. Reemplaza la búsqueda del
  factor en el modo marco.
- Campo nuevo **`bandeja_acostadas: true`**: las piezas entran a la bandeja con ancho ≥ alto (el giro al
  azar se elige solo entre esas orientaciones; el espejo al azar se mantiene). Así caben 2 filas de 6.
- Separación entre piezas de la bandeja: **24 px** (hoy `RELLENO_BANDEJA` = 16). Sale como campo
  `relleno_bandeja`.
- **Zona tocable de las piezas de marco**: el polígono de sus celdas agrandado 16 px, en vez del círculo
  de 96 px. La pieza más delgada (la I, 32×160) queda con 64 px de grosor tocable, que es el mínimo del
  GDD §6.1, y así no se pisan con las vecinas.
- Al tomar una pieza, crece de 0,64 a 1,0 con un tween de **0,12 s** (`TRANS_BACK`), no de golpe.
- Si al girarla en la bandeja queda de pie y no cabe, esa pieza sola baja a 0,5 hasta que se tome.
- `boton_espejo_rect`: **[1120, 470, 120, 120]**, pegado a la derecha de la bandeja. Hoy está en
  (1150, 250), lejos de donde están las piezas.
- QA: pantallazo del reto dorado recién abierto y medir con F3 la escala real antes y después.

**8. [MAYOR] La pista del reto dorado puede sacar piezas que Sofía puso bien.** `_esta_bien_puesta` y
`_pista_marco` comparan contra **una sola** `solucion`, pero el rectángulo de 6×10 tiene 2.339 soluciones.
Si Sofía va armando otra solución válida, la pista le "devuelve" piezas correctas y además le cobra una
estrellita. Eso es un castigo injusto.
*Cambios*:
- Generar offline (en `herramientas/`) **todas las soluciones** como cadenas de 60 letras (~140 KB) y
  guardarlas en el campo `soluciones_marco`.
- La pista busca la primera solución compatible con **todas** las piezas ya puestas y coloca una pieza
  de esa solución, empezando por la esquina o el hueco más encerrado.
- Solo si no hay ninguna solución compatible, devuelve la pieza que, al quitarla, deja compatible una
  solución. Eso sí se cobra.

**9. [MENOR] Botón espejo: el feedback se confunde con el giro.** Espejo y giro usan el mismo
`SFX_GIRO`. Además, tocar el espejo sin pieza elegida solo da voz.
*Cambios*:
- Un SFX distinto para el espejo (un "fwip" de volteo).
- Mientras haya una pieza elegida, el botón espejo late (escala 1,0↔1,06, 0,8 s) y dibuja una mini
  silueta de esa pieza en su esquina.
- Sin pieza elegida, además de la voz, las piezas de la bandeja dan un saltito de 12 px, 0,05 s una
  tras otra, para mostrar que primero hay que tocar una.

### C. `emparejar`: cambio de memoria (§3, nota del 13-Sep)

**10. [APROBADO] La primera carta queda a la vista hasta tocar la segunda.** Es la regla del Memory
clásico: no hay reloj que apure (GDD §1) y el reto sigue siendo recordar las cartas que ya se taparon.
`tiempo_volteo_ms` pasa a ser "cuánto se ve el par fallido", y los valores v3 (Sofía 800-900 ms, Nicole
1400-1800 ms) son buenos con ese significado. Queda validado.
*Cambio (documentación)*: actualizar la fila 4 de §3 y la fila `oculto` de §5 con el significado nuevo.

**11. [MENOR] Nicole puede saltarse sin querer el par fallido.** Un toque durante el "no es este" tapa
el par al tiro. A los 5 años, los toques impacientes le borran justo la información que tenía que
memorizar.
*Cambio*: campo **`visible_minimo_ms`** (Brote **600**, Estrella 0). Los toques que lleguen antes quedan
**en espera**: la carta hace su pulso al instante (<100 ms) y se voltea cuando se cumple el mínimo.

**12. [MENOR] La pista de Sofía destapa una pareja al azar.** Si ya tiene una carta arriba, lo útil es
mostrarle **la compañera de esa carta**.
*Cambio*: si `_seleccionadas` no está vacío, `_dar_ayuda` revela ese grupo. Si está vacío, al azar como
hoy. También se aplican el medidor y la confirmación del hallazgo 4.

### D. `mezclar` (Sofía, "Taller de pinturas")

**13. [MAYOR] Atrapar gotas sin querer reinicia la lata.** La zona de captura mide ~170 px de ancho
(`FRASCO_ANCHO` 140 + margen) y en z3-z5 caen 3 gotas de 84 px a 130-145 px/s ±35 %. Muchas veces no se
puede ir por la gota útil sin tragarse una vecina, y el "¡puaj!" vacía la lata entera. Eso se siente
injusto, no chistoso.
*Cambios*:
- **`separacion_min_gotas_px: 190`**: dos gotas en la misma franja vertical de 200 px nunca caen a menos
  de 190 px en x.
- **`fallos_para_reiniciar_lata: 2`**: la 1.ª gota equivocada de una lata hace un "¡puaj!" corto de
  0,6 s. El frasco escupe la gota hacia arriba con un rebote, suma un fallo para las estrellitas y
  **se quedan las capas buenas**.
- Recién la 2.ª gota equivocada de la misma lata dispara el gag completo con vaciado, como hoy.

**14. [MENOR] "Mantener apretado" para agitar.** Hoy tarda 3,3 s (0,3 por segundo). Está bien como
alternativa y no se confunde con el candado de padres, que además pide resolver una suma.
*Cambio*: subir a **0,4 por segundo** (2,5 s) y que el frasco vibre ±3 px mientras se mantiene, para que
se note que está funcionando.

**15. [APROBADO] Lo que funciona bien:** las recetas con proporción ("mismos colores, otro resultado") son
un reto real para 8 años; la libreta pausa el juego; dejar pasar una gota no castiga; las "gotas justas"
evitan esperas. Queda validado.

### E. `clasificar` (Lluvia de Maxi y Nicole)

**16. [APROBADO] Validado.** Tiene respuesta al presionar, un imán generoso, gotas que nunca se pierden y,
en Semilla, todo charco hace magia. Tocar la gota y después el charco es un buen camino para Nicole si el
arrastre le cuesta.

**17. [MENOR] Si hay varias gotas, tocar un charco en modo `directo` sin gota elegida no tiene un
feedback definido.**
*Cambio*: el charco hace una onda (escala 1,06, 0,15 s), suena la voz con su color ("¡Rosado!") y la gota
de ese color que esté más cerca da un saltito. Así Nicole aprende a tocar primero la gota.

**18. [MENOR] Charcos que se mueven (Nicole z3).** Ningún charco debe moverse mientras haya una gota
elegida o en arrastre.
*Cambio*: esperar a que `_arrastrando` esté vacío y no haya gota elegida. `tester-qa` lo verifica.

### F. `lienzo_libre`

**19. [APROBADO] Validado.** No hay fallo en ningún perfil. En Semilla, todo toque cambia algo. Los
stickers vivos y el conector con un viajero son un gran momento. Los retos de artista de Sofía son
opcionales.

**20. [MENOR] Las celdas del mosaico de Sofía miden 42 px, bajo los 64 del GDD.**
*Cambio*: el pincel del mosaico **pinta la celda más cercana** al dedo dentro de un radio de 32 px (zona
efectiva de 64 px). Además, arrastrar pinta todas las celdas que cruza el trazo, interpolando cada 10 px.

**21. [MENOR] "Mostrar a Coco" de Maxi.** Si lo toca sin querer, la hoja se cierra. Se guarda, así que no
se pierde nada, pero lo sorprende.
*Cambio*: en Semilla, el botón aparece con `segundos_mostrar` **≥ 45 s** y entra con un rebote y la voz
`mostrar`. No se agrega ninguna confirmación (sería un menú intermedio).

---

## Resumen de cambios para `dev-godot` (por prioridad)

| # | Motor | Cambio | Valor |
|---|---|---|---|
| 7 | encajar (marco) | `lado_celda`, zonas, `escala_bandeja_fija`, `bandeja_acostadas`, `relleno_bandeja`, zona tocable por polígono +16 px, tween al tomar, espejo pegado a la bandeja | 50; [236,96,900,312] / [236,416,848,292]; 0,64; true; 24; 0,12 s; [1120,470,120,120] |
| 8 | encajar (marco) | pista contra todas las soluciones compatibles | `soluciones_marco` |
| 4 | encajar, emparejar, clasificar, mezclar | medidor de 3 estrellitas + globo de confirmación + pista gratis en el piso | 34 px; globo 150 px; 4 s |
| 5 | encajar | `giro_cuenta_fallo: false` en Estrella; la pieza se queda 2,5 s sobre el hueco y se gira con un toque | 2,5 s; alfa 0,7 |
| 6 | encajar | reiniciar `_derrotas` por ronda; el regalo pone el 15 % de las pendientes (entre 1 y 4) | 0,35 s entre piezas |
| 13 | mezclar | `separacion_min_gotas_px`, `fallos_para_reiniciar_lata` | 190; 2 |
| 1 | niveles (para `disenador-niveles`) | monumentos de 16-20 piezas + una regla por zona | — |
| 11-12 | emparejar | `visible_minimo_ms` (Brote 600); la pista revela la compañera | — |
| 9, 14, 17, 18, 20, 21 | varios | menores | ver cada hallazgo |

## Qué deben validar después

- **`experto-ux-parvulo`**:
  - Que el globo de confirmación de la pista (4) se entienda sin leer.
  - El tamaño real de la bandeja del dorado en una tablet (7).
  - Que la pieza "flotando chueca" (5) no confunda.
  - La carga de Nicole con `visible_minimo_ms`.
- **`tester-qa`**:
  - Medir con F3 el factor real de la bandeja del dorado, antes y después.
  - Una prueba de regresión para `_derrotas` por ronda.
  - Que la pista del marco nunca devuelva una pieza de una solución válida.
  - Que no se atrapen gotas sin querer con `separacion_min_gotas_px`.
  - Tiempos de respuesta <100 ms en el globo de la pista y en el espejo.
- **Playtest con Sofía**: cronometrar una estación de Formas (meta ≤ 5 min por ronda) y observar su
  reacción ante la primera derrota y ante la primera pista.
