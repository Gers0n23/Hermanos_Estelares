# Auditoría UX: viaje estelar arcade (`shmup`), perfil de Maxi

- **Fecha**: 21-Nov-2026 (tarjeta HE-134, V0 de la épica del viaje arcade v2).
- **Objeto**: `docs/fichas/viaje-arcade.md`, primera versión (la de V0 con §17 del guionista).
- **Auditor**: `experto-ux-parvulo`, auditoría provisional del perfil de Maxi (2 años).
- **Registro**: este archivo lo guarda `disenador-mecanicas` a partir de la auditoría provisional. Se anotan además
  los cambios de la segunda pasada de la ficha (mismo día) y el estado de cada punto.
- **Alcance**: solo especificación. No se implementa, no se toca el tablero ni el GDD, no hubo llamadas de pago.

## 1. Veredicto

**RECHAZADA (provisional) para Maxi.** La ficha no se aprueba para el perfil de Semilla hasta que se resuelvan los
bloqueantes B1 a B3. Las mejoras M1 a M16 son de alta prioridad y se incorporan en la misma pasada. Los puntos P1 a
P5 son de pulido. Para Nicole y Sofía, la ficha no fue auditada en esta pasada: sus reglas cambian solo donde los
bloqueantes lo tocan (salida, descanso y reinicio).

**Estado después de la segunda pasada** (21-Nov-2026): B1, B2 y B3 quedan **resueltos en la ficha** (con dos puntos
[Confirmar PO]). Las mejoras M1 a M16 y los puntos P2 y P3 quedan **escritos como reglas** en la ficha. P1, P4 y P5
son propuestas de `disenador-mecanicas` (no venían detallados en el encargo). La re-auditoría de `experto-ux-parvulo`
es el siguiente paso para levantar el rechazo provisional.

## 2. Bloqueantes

### B1. Salida accidental y zonas de toque
- **Problema**: sin una zona reservada en la esquina superior izquierda, el dedo que arrastra puede tocar la casa o a
  Cometa, y un toque en esa esquina puede acortar el gag o el reinicio sin querer.
- **Pedido**: casa y Cometa con ≥ 96 px cada uno y ≥ 40 px entre sus bordes; una franja de 120 px en la esquina que no
  inicia arrastre y no recibe el toque de "acortar" del gag, del reinicio ni del video; Cometa fijo para Maxi (el GDD
  §2 "flota" no aplica a Maxi); definir la fuente de los destellos dentro del sector; para Maxi, salir o volver al
  checkpoint no quita los destellos ya ganados en el sector, marcado [Confirmar PO].
- **Resolución en la ficha**: franja de 280 × 120 px (§2.11, §4, §4.2). Casa y Cometa de 96 × 96 px con 40 px entre
  bordes. Cometa fijo en Maxi. Fuente de destellos: un destello suelto por sector en la oleada final, consolidado al
  cerrar el sector (§9.2). Destellos de Maxi al salir o reiniciar: **[Confirmar PO]** (§15.2, punto 6).
- **Estado**: **Resuelto en la ficha**; la parte de Maxi sobre salir y reiniciar queda **[Confirmar PO]**.

### B2. Control de Maxi
- **Problema**: la regla "sigue al dedo en el mismo cuadro, sin lerp" se contradice con el "14/s" del arrastre de Maxi.
  Además no había tope de R2, lo que deja a Maxi con movimientos bruscos.
- **Pedido**: quitar la contradicción; para Maxi, seguimiento sin suavizado con velocidad máxima explícita (propuesta
  inicial 900-1000 px/s, a calibrar), llegada en ≤ 1 cuadro si la distancia es corta, posición acotada al campo con
  margen de ~60 px y rebote visual al borde. Fijar el tope de R2 con valor. El desplazamiento de 120 px se decide por
  observación (R1).
- **Resolución en la ficha**: regla 2 separada por perfil; Maxi a 950 px/s máx. sin suavizado; llegada en el mismo
  cuadro si la distancia es ≤ 16 px; margen de 60 px; rebote visual de 4-6 px en 120 ms sin pérdida de vida (§4.2).
  El 120 px queda como "decidir por observación" (R1).
- **Estado**: **Resuelto en la ficha** (valor fijado: 950 px/s; rango de calibración 900-1000).

### B3. Descanso (Nicole y Sofía) y pantalla intermedia
- **Problema**: la pantalla con "dos botones grandes" al reiniciar contradice las reglas 1 a 4 de la ficha ("sin pantallas
  intermedias").
- **Pedido**: quitar la pantalla; usar un icono de descanso de ≥ 96 px visible en el checkpoint, sin pantalla y sin tiempo
  límite, con voz de Cometa; el reinicio automático sigue igual.
- **Resolución en la ficha**: icono de 96 × 96 px en la esquina superior derecha, aparece al reiniciar en el checkpoint
  (Nicole tras 3 derrotas, Sofía tras 4), voz "¿Descansamos un ratito?", sin pantalla ni tiempo límite; tocarlo lleva al
  mapa con el checkpoint guardado (§7.4). El reinicio automático no cambia. Maxi no tiene icono de descanso.
- **Estado**: **Resuelto en la ficha**. El guion (`docs/guiones/voces-viaje-arcade.md`) todavía dice "dos botones" y debe
  ajustarlo `guionista` (§16 de la ficha).

## 3. Mejoras de alta prioridad (M1 a M16)

| Id | Mejora | Cómo quedó en la ficha | Estado |
|---|---|---|---|
| M1 | Gag + reinicio con total ≤ 2 s para Maxi (no 3 s), con fogonazo de aparición en el checkpoint | Gag ≤ 1,2 s + reinicio ≤ 0,8 s en Maxi; ≤ 2 s total en los tres perfiles; fogonazo en el checkpoint (§2.4, §7.1-7.2) | Resuelto en la ficha |
| M2 | El hit-stop congela solo enemigos y balas; nunca la nave ni el disparo; máximo uno cada ~300 ms | §2.13, §4, §4.1 | Resuelto en la ficha |
| M3 | El jefe no usa corazones de colores; barra o estrella | Barra ancha con estrella al final (§5.3) | Resuelto en la ficha |
| M4 | Multitouch: solo el primer dedo controla; el segundo no dispara ni salta; si el primero se levanta, la nave se queda quieta | §2.12, §4; criterio 4 de §13 | Resuelto en la ficha |
| M5 | Eliminar el "tropiezo" de Cometa al volante para Maxi (basta el "boing"); Cometa visible en la cabina | §7.4; criterio 13 de §13 | Resuelto en la ficha; conflicto con B1 (ver N-B1) |
| M6 | Qué llena las estrellas del puntaje para Maxi y un símbolo visual del multiplicador ×3 | Las 3 estrellas del HUD son el multiplicador; cada 5 enemigos seguidos sin golpe llena una; ×3 = tres estrellas llenas (§6.1) | Resuelto en la ficha (por delegación); ver N-A4 |
| M7 | Cometa repite siempre la última instrucción de voz, incluida "¡toca y la nave va!" al arrancar | §2.6, §4, §10.3 | Resuelto en la ficha; conflicto con M8 (ver N-A1) |
| M8 | Alinear voz y sonido: en la acción solo sonidos; voz solo en pantalla vacía o en ≤ 0,5 s sin tapar el disparo (corregir §10.2) | §2.6, §10.2, §10.3; las intros y el aviso del jefe se movieron a pantalla vacía | Resuelto en la ficha; conflicto por N-A1 y N-A5 |
| M9 | Fotosensibilidad: al llegar al tope de destellos, se suprime el destello blanco; la chispa y el sonido siguen | §2.8, §4.1 | Resuelto en la ficha |
| M10 | Medir por separado el fogonazo (≤ 1 cuadro) y el sonido (≤ 100 ms) en la tablet; ajustar el criterio 11 | Criterio 11 de §13 | Resuelto en la ficha; la medida real queda para HE-137 |
| M11 | Definir si las bolsas se revientan por toque o por disparo; la pinza se telegrafía y es esquivable; bolsas ≥ 96 px en Maxi | §8.1: bolsas por disparo o contacto (por delegación); pinza telegrafiada 1,5 s en Maxi; bolsas ≥ 96 px | Resuelto en la ficha |
| M12 | El confeti del jefe de Maxi no daña (solo empuje suave), o se telegrafía 1,5 s; el punto débil tiene un sonido guía | No daña, solo empuja unos 30 px/s; punto débil con "tic" cada 0,5 s (§5.3) | Resuelto en el no daño; el empuje contradice "nave quieta" (ver N-A3) |
| M13 | Las intros (Sofía ~10 s, Nicole) se saltan con un toque y no bloquean el control; los resultados (~6 s) se saltan con un toque tras 1,5 s | §3, §10.1, §10.3 | Resuelto en la ficha |
| M14 | Temblor de cámara bajo por defecto para Maxi | 4 px de máximo en Maxi frente a 10 px (§4.1, §6) | Resuelto en la ficha (valor de partida) |
| M15 | Para Maxi, volumen o ritmo del "pium" más bajos (fatiga auditiva) | −6 dB y tope de 4 por segundo (§4.1, §6) | Resuelto en la ficha (valor de partida) |
| M16 | Nicole: la aspiradora del jefe limita el empuje y nunca lleva a un choque sin telegrafía; botones del descanso ≥ 96 px | Empuje ≤ 120 px/s y telegrafía de 1,0 s (§5.3); descanso con icono ≥ 96 px (§7.4) | Resuelto en la ficha (la regla de toque del icono, ver N-N7) |

## 4. Pulido (P1 a P5)

| Id | Punto | Cómo quedó | Estado |
|---|---|---|---|
| P1 | Confeti y tuercas: sensación de permanencia y carga visual (propuesta de la ficha, no detallado en el encargo) | Permanencia de medio segundo; tope de 40 partículas por evento en Maxi (§4.1) | Propuesta de `disenador-mecanicas`; a validar |
| P2 | En PC, el puntero sin clic no mueve la nave para Maxi | Aclarado en §4.2 y §6: el puntero sin clic no mueve la nave en ningún perfil | Resuelto en la ficha |
| P3 | Los videos de despegue y llegada se saltan con un toque, sin disparar ni mover | §3 y §10.1 | Resuelto en la ficha |
| P4 | HUD del trayecto sin números para Maxi (propuesta, no detallado en el encargo) | El mapa de trayecto ya no tiene números; Maxi solo ve estrellas (R5) | Propuesta; a validar |
| P5 | Alabeo de la nave de Maxi (propuesta, no detallado en el encargo) | Alabeo de Maxi ≤ 10° (§4.1) | Propuesta; a validar |

## 5. Riesgos de usabilidad R1 a R13 (estado tras la segunda pasada)

| # | Riesgo | Estado | Qué falta |
|---|---|---|---|
| R1 | Maxi no entiende que la nave va "arriba del dedo" (120 px) | Abierto | Decidir en la prueba con niños (120, 60 o 0 px) |
| R2 | Maxi toca a ráfagas: la nave se mueve siempre al último punto | Cerrado en la ficha | Tope fijado en 950 px/s; validar con el bot y con niños |
| R3 | Los 5 corazones se leen como "vida que se va" | Abierto | Observar la cara de Maxi al perder el primero |
| R4 | "Cometa al volante" se siente como trampa o como premio | Parcial | Se quitó el tropiezo y Cometa va en la cabina; falta la lectura en la prueba |
| R5 | Números y ×N en pantalla para Maxi | Cerrado en la ficha | Ninguno; el HUD de Maxi son estrellas |
| R6 | Gag + reinicio automático: ¿Maxi entiende que volvió a empezar? | Cerrado en la ficha | Verificar en la prueba que no se queda esperando |
| R7 | Mantener el dedo apoyado para disparar | Abierto | Playtest; Maxi también dispara solo con el dedo apoyado |
| R8 | Sofía sin corazones sueltos y con 3 corazones | Abierto | Calibrar con el bot (no es un punto de Maxi) |
| R9 | Telegrafía de jefes poco visible para Maxi | Cerrado en la ficha | Brillo y sonido; voz en el checkpoint antes del jefe |
| R10 | Fotosensibilidad: muchas chispas y destellos | Cerrado en la ficha | Medir en el arnés de ráfaga (criterio 15) |
| R11 | Coleccionauta provoca y huye: ¿se lee como perder o ganar? | Abierto | Depende del guion y de la prueba |
| R12 | Salida con el botón casa cerca del dedo | Cerrado en la ficha | Verificar en la prueba que no lo tocan al arrastrar |
| R13 | Duración de ~60 s y el encuentro en Maxi | Abierto | Calibrar con el bot; se acorta el sector 1 en datos si hace falta |

**Resumen**: 6 cerrados en la ficha (R2, R5, R6, R9, R10, R12), 1 parcial (R4), 6 abiertos (R1, R3, R7, R8, R11, R13).
Ninguno de los abiertos bloquea HE-136; todos se resuelven en la prueba con niños o en la calibración.

## 6. Lo que se calibra con el jugador simulado (bot) y lo que se decide con niños

**Con el bot (V7, HE-141)**:
- Velocidad máxima de Maxi (900-1000 px/s) y la sensación de llegada en 1 cuadro.
- Vida del jefe de Maxi (40 de partida; objetivo 20-30 s de combate).
- Duración sin morir (~60 s) y la meta de primer intento (~90 %). Si no llega, se acorta el sector 1 en datos.
- Oleadas y huecos de Maxi (1,5 × aviso) y la frecuencia de la pinza.
- Umbrales de vida extra y estrellitas de Nicole y Sofía (en datos, no en código).
- Temblor (4 px) y pium (−6 dB, 4 por segundo): se revisan con la medida de fatiga, no solo con el bot.

**Con niños (playtest presencial)**:
- Desplazamiento de 120 px (R1).
- Lectura de "Cometa al volante" (R4) y de la huida del Coleccionauta (R11).
- Reacción al gag y al reinicio de 2 s (R6) y al icono de descanso de Nicole y Sofía.
- Si el dedo que dispara solo con apoyo se entiende sin explicación (R7).
- Cara de Maxi al perder el primer corazón (R3).

**Medidas técnicas (HE-137, en la tablet)**: fogonazo ≤ 1 cuadro y sonido ≤ 100 ms por separado (M10); nunca más de 3
destellos por segundo (M9); latencia de Cometa ≤ 100 ms.

## 7. Decisiones pendientes del PO

1. Destellos de Maxi al salir o reiniciar en el checkpoint: conservar los recogidos en el sector en curso
   (propuesta de la ficha) o perderlos como en Nicole y Sofía. [Confirmar PO]
2. "Cometa al volante": lectura de "victoria asegurada" (§15.2, punto 5 de la ficha). [Confirmar PO]
3. Velocidad de Maxi (950 px/s): confirmar la sensación en la prueba. [Confirmar PO, opcional]
4. Número de rutas, "3.ª etapa" de Sofía y umbrales de vida extra: siguen abiertos desde V0 (§15.2, puntos 2 a 4).

## 8. Próximos pasos

- `disenador-mecanicas`: ya hecho en esta pasada; la ficha está en `docs/fichas/viaje-arcade.md`.
- `guionista`: ajustar `docs/guiones/voces-viaje-arcade.md` (`viaje_descanso`, Cometa al volante sin tropiezo, aviso del
  jefe en el checkpoint, intros saltables).
- `experto-ux-parvulo`: re-auditar el perfil de Maxi con esta versión (B1-B3, M1-M16, §2.11, §4.2 y el tope de 950 px/s).
- `disenador-niveles`: destello suelto por sector en la oleada final, total de 5-7 destellos por ruta.
- PO: las decisiones de §7 de este archivo.

---

## Re-auditoría 21-Nov (perfil de Maxi, segunda pasada de la ficha)

- **Objeto**: `docs/fichas/viaje-arcade.md`, segunda pasada (§0.1). **Auditor**: `experto-ux-parvulo`.
- **Contrastado con**: `docs/minijuegos/viaje_arcade_propuesta.md` §7.1 (manda), GDD §6 (reglas 1 a 11 y tabla de la regla 11),
  `docs/perfil-jugadores.md` (Maxi), `docs/guiones/voces-viaje-arcade.md`.
- **Alcance**: solo lectura. No se implementa, no se toca `docs/TABLERO.md`, no hubo llamadas de pago. Nicole y Sofía
  se auditan solo donde cambian la franja, el descanso (B3) o el campo de la nave.

### R1. Veredicto para Maxi: APROBADO CON CAMBIOS

- Los tres bloqueantes originales (B1, B2, B3) quedan **resueltos** con reglas concretas. Las cifras pedidas son correctas
  (tabla R2).
- La re-lectura encuentra **2 bloqueantes nuevos**, ambos contradicciones internas de la ficha que se corrigen con una o dos
  reglas. **Los bloqueantes N-B1 y N-B2 impiden cerrar HE-134** y deben aplicarse antes de implementar §3, §4.2, §7.4 o §10.3.
- Hay 5 mejoras de alta prioridad (N-A1 a N-A5) que se aplican en la misma pasada. Lo demás es pulido o pendiente de prueba.

### R2. Cifras verificadas

| Cifra | Dónde | Comprobación | Estado |
|---|---|---|---|
| Franja 280 × 120 px | §2.11, §4.2 | Casa (12-108, 12-108) y Cometa (148-244, 12-108) caben; la franja cubre x < 280, y < 120 con margen de 36 y 12 px | Correcta |
| Casa y Cometa 96 px, 40 px entre bordes | §4.2 | 108 → 148 = 40 px | Correcta (B1) |
| Velocidad 950 px/s | §2.2, §4.2, §6 | 950 / 60 fps = 15,8 px por cuadro; el umbral de 16 px es el de 60 fps | Correcta; ver pulido Pa |
| Margen de campo 60 px | §4.2 | x ∈ [60, 1220], y ∈ [60, 660] | Correcta (B2) |
| Rebote 4-6 px en 120 ms | §4.2 | Solo Maxi; sin pérdida de vida | Correcta (B2) |
| Maxi: gag 1,2 s + reinicio 0,8 s | §2.4, §7.1-7.2 | 2,0 s | Correcta (M1) |
| Nicole y Sofía: gag 1,5 s + reinicio 0,5 s | §7.1-7.2 | 2,0 s | Correcta (M1) |
| Icono de descanso 96 px | §7.4 | x 1168-1264, y 12-108; margen de 16 px a la derecha | Correcta (B3); ver N-N7 |
| Pinza de Maxi 1,5 s; bolsas ≥ 96 px; temblor 4 px; pium −6 dB, 4/s | §8.1, §4.1 | Coinciden entre §4.1, §5.3, §6 y §13 | Correctas (M11, M14, M15) |

Concordancia con GDD §6 regla 11: los regalos (2, 2, 3), el descanso (3 y 4) y la ayuda fuerte de Maxi (3) coinciden con la
tabla. Lo que no coincide está en el GDD: su texto dice "reintento de un toque (botón ≥ 160 px o cartel)", y la ficha usa
reinicio automático sin cartel (§15.3, pendiente del dueño del GDD).

### R3. Bloqueantes originales

| Id | Qué se pidió | Cómo quedó | Estado |
|---|---|---|---|
| B1 | Franja de esquina, casa y Cometa con 40 px, Cometa fijo en Maxi, fuente de destellos, destellos de Maxi al salir | Franja 280 × 120 (§2.11, §4); casa y Cometa 96 px; Cometa fijo (§4.2); un destello suelto por sector en la oleada final (§9.2) | **Resuelto**, con dos excepciones: N-B1 (Cometa en la cabina contradice "fijo") y la decisión del PO sobre los destellos de Maxi (§15.2-6, [Confirmar PO]) |
| B2 | Quitar la contradicción del "sin lerp", tope de velocidad, llegada en 1 cuadro, margen 60 px, rebote | §2.2, §4.2: 950 px/s sin suavizado, llegada si ≤ 16 px, margen 60, rebote de 4-6 px en 120 ms; el 120 px queda para la prueba (R1) | **Resuelto** |
| B3 | Quitar la pantalla intermedia de Nicole y Sofía; icono de descanso ≥ 96 px; voz; sin tiempo límite | §7.4: icono 96 px en la esquina superior derecha, voz "¿Descansamos un ratito?", sin pantalla, sin tiempo límite; Maxi no tiene icono | **Resuelto** para Nicole y Sofía; ver N-N7 (riesgo de toque accidental) y el guion pendiente (Pk) |

### R4. Mejoras de alta prioridad (M1 a M16)

- **Cerrados en la ficha, sin conflicto (12)**: M1, M2, M3, M4, M6, M9, M10, M11, M13, M14, M15 y M16.
- **Cerrados, con un conflicto que hay que corregir (4)**:
  - M5: "Cometa visible en la cabina" contradice B1 (ver N-B1).
  - M7 y M8: Cometa repite la voz en plena acción (ver N-A1 y N-A5).
  - M12: el empuje del confeti de Maxi contradice "la nave queda quieta" (ver N-A3).
- **P2 y P3**: cerrados. P1, P4 y P5 son propuestas razonables para Maxi (tope de 40 partículas, HUD sin números, alabeo ≤ 10°).

### R5. Bloqueantes nuevos

**N-B1. Cometa "sentado en la cabina" contradice "Cometa fijo en la franja" (Maxi).**
- Dónde: §4.2 dice "Cometa en Maxi: fijo en la franja, sin desplazarse, sin cambiar su hitbox". §7.4 dice "Cometa se ve sentado
  en la cabina de la nave durante toda la ayuda". M5 y el criterio 13 de §13 también piden la cabina.
- Riesgo: durante "Cometa al volante", un toque sobre Cometa cae sobre la nave y arrastra en lugar de repetir la instrucción.
  Eso viola la regla 2 de GDD §6 para Maxi, que no lee y depende de que Cometa le repita la voz.
- Corrección: Cometa no sale de la franja en ningún momento. En la cabina aparece un copiloto decorativo (un casco o un gorro
  asomando, sin hitbox y sin voz). Un toque sobre el copiloto cuenta como toque de nave. Se actualizan M5 y el criterio 13.

**N-B2. "Primera vez por ruta" es global y deja a Maxi sin su única instrucción de la ruta.**
- Dónde: §3 (video "solo la 1.ª vez por ruta"), §10.3 (`intro_*`, "al empezar la ruta (solo la 1.ª vez)"), §7.6 (entra sin video
  porque "ya se vio la 1.ª vez").
- Riesgo: si Nicole o Sofía ya hicieron la ruta, Maxi entra sin "¡toca y la nave va!" y sin video. Como no lee y el viaje
  no tiene otra instrucción hablada, no llega la voz de la ruta (GDD §6 regla 2). El perfil de Maxi dice que se aburre con
  historias que hablan mucho, pero aquí lo que falta es la instrucción.
- Corrección: "primera vez" por hermano y por ruta: `Progreso` guarda `perfiles.<id>.viaje.<ruta>.intro_vista` y
  `video_visto`, con el mismo patrón que el récord (§9.3). Se aplica a la intro y al video. La repetición de Cometa suena
  siempre.

### R6. Mejoras de alta prioridad nuevas (Maxi)

- **N-A1 (M7 contra M8). Cometa repite la voz en plena acción.** §2 regla 6 y §10.3 prohíben voz en la acción; §4 y M7 piden
  repetir siempre. Corrección: si hay acción en curso, Cometa responde al instante (estiramiento y "pluf", ≤ 100 ms). La voz
  se encola hasta la próxima pantalla vacía o un hueco de ≥ 0,5 s, y nunca tapa el disparo.
- **N-A2 (regla 5 de GDD §6). Silencio al tocar la franja vacía y saltos sin respuesta.** En §4, tocar la franja (fuera de
  Cometa y casa), saltar una intro o un video y el segundo dedo tienen "ninguno" como feedback. Corrección: el toque en la
  franja vacía da un "pluf" suave y Cometa se estira, sin voz y sin cambiar nada más. Saltar intro o video suena un "pop" de
  ≤ 100 ms. El segundo dedo no es elemento y puede seguir sin feedback.
- **N-A3 (R9 y §4 contra §5.3). El confeti del jefe de Maxi empuja la nave.** §5.3 dice que empuja 30 px/s, pero §4 dice que la
  nave queda quieta al levantar el dedo y R9 dice que la nave no se mueve sola. Corrección: en Maxi, el confeti no empuja
  (queda confeti, "pluf" y temblor de 4 px). Si el PO quiere empuje, solo mientras haya dedo apoyado.
- **N-A4 (M6, R5 y §10.1). Demasiadas "estrellas" para Maxi.** Hay seis usos: multiplicador (3), estrella de la barra del
  jefe, estrellita de récord en el HUD, estrella con la cara de Maxi en el mapa, estrellas de los resultados y destellos.
  Corrección: en Maxi, las 3 estrellas del HUD son el único símbolo de estrella. La barra del jefe lleva un icono del artefacto
  (no una estrella). La estrellita de récord en el HUD se cambia por un destello con tilín. En el mapa, la cara de Maxi sin
  estrella. Los resultados de Maxi muestran destellos, no estrellas.
- **N-A5 (M8). La voz de "provoca" suena con la pinza ya lanzada.** §8.1 pone la pinza como peligro en pantalla, y §2 regla
  6 prohíbe voz con enemigos o balas. Corrección: la línea "provoca" suena antes de que la pinza empiece su telegrafía, y la
  pinza solo se lanza al terminar la voz.

### R7. Mejora para Nicole y Sofía

- **N-N7. Icono de descanso en el campo de la nave.** El campo de la nave llega a x ≤ 1220 e y ≥ 60, y el icono ocupa
  x 1168-1264, y 12-108. La ficha no dice qué pasa si la nave o el dedo pasan por ahí. El icono además queda visible hasta
  cerrar el sector, así que un toque accidental saca al niño del viaje. Corrección: (a) la nave no entra en el rectángulo del
  icono (se para antes, como con la franja); (b) el icono solo responde a un toque que empieza sobre él, no a un dedo que llega
  arrastrando; (c) no aparece ni responde durante el gag y el reinicio (la voz sí puede sonar).

### R8. Pulido

- **Pa.** §4.2: el umbral de "llega en 1 cuadro" es 950 px/s × Δt (15,8 px a 60 fps). Con 16 px fijos, a 30 fps no se cumple.
- **Pb.** §4.2: el sprite de la nave (~130 px) toca x = 280 con el centro en x ≈ 345, mientras que la hitbox de Maxi (20 px)
  no. Aclarar que la franja se comprueba con la hitbox.
- **Pc.** §4.2: con x < 340 el rebote de Maxi ocurre en y = 180, un borde invisible. Mostrar el aplastamiento ahí o
  redactarlo como "borde del campo".
- **Pd.** §4: el salto de Cometa al tocarlo no debe salir de la pantalla (y ≥ 0).
- **Pe.** §6.1: "5 enemigos seguidos sin golpe" y "un golpe no las vacía" conviven mal. Redactar: un golpe reinicia el conteo
  de la racha pero no vacía las estrellas.
- **Pf.** §6: el teclado a 700 px/s para todos los perfiles, frente a 950 px/s táctil para Maxi. Decidir si Maxi usa el mismo tope.
- **Pg.** §8.1: "la pinza se enreda" no dice si la nave queda inmovilizada. Aclarar que no la inmoviliza.
- **Ph.** `docs/perfil-jugadores.md`: Maxi celebra con "¡¡siiii!!" y el puño derecho arriba. La ficha no lo usa. Propuesta:
  en el récord y al vencer el artefacto, Maxi salta con el puño arriba y suena su grito (no es voz de Cometa).
- **Pi.** La propuesta, §2.2 (tasa 14/s para Maxi) y §4 (cartel ≥ 160 px), sigue sin marcar como superada. Añadir la nota
  "superada por la ficha §4.2 y §7.2".
- **Pj.** §10.1 y §6: Maxi aparece como "estrellitas" en los resultados, pero §6 pone "Estrellitas al llegar: —". Redactar igual.
- **Pk. Guion (guionista).** `docs/guiones/voces-viaje-arcade.md`: `viaje_descanso` (líneas 89 y 118) sigue diciendo "Son dos
  botones". `viaje_aviso_jefe` dura ~1,5 s, y la ficha pide ≤ 1 s (líneas 92 y 183).
- **Pl. GDD (dueño).** Regla 11: "reintento de un toque (botón ≥ 160 px o cartel)" y la fila del viaje (§12) aún no existen.
  §8, "sin sistema de vidas", ya era un conflicto antes del viaje (§15.3).

### R9. Cambios pendientes (lo que falta para cerrar)

1. N-B1: Cometa fijo en la franja también en la ayuda; copiloto decorativo en la cabina; actualizar M5 y el criterio 13.
2. N-B2: "primera vez" por hermano y por ruta (intro y video), en `Progreso`.
3. N-A1: voz de Cometa encolada hasta pantalla vacía o hueco de 0,5 s; "pluf" inmediato.
4. N-A2: "pluf" al tocar la franja vacía; "pop" al saltar intro o video.
5. N-A3: sin empuje del confeti en Maxi.
6. N-A4: un solo símbolo de estrella para Maxi (multiplicador); resultados y récord sin estrella.
7. N-A5: pinza después de la voz "provoca".
8. N-N7 (Nicole y Sofía): icono de descanso fuera del campo de la nave y con toque que empieza sobre él.
9. Pulido Pa a Pj (opcionales, se pueden agrupar en la siguiente pasada) y los pendientes de guion y GDD (Pk, Pl).

### R10. Abiertos que no bloquean (prueba con niños y PO)

- Prueba: R1 (120 px), R3, R4 (lectura de Cometa al volante), R6, R7, R11, R13 y la medida de la fatiga auditiva de Maxi.
- R12 (casa de Maxi): se verifica que no la toca al arrastrar. Si Maxi sale por accidente, la opción es que la casa de Maxi
  sea de retención de 0,5 s con un anillo visible. Requiere decisión del PO, porque hoy "salir siempre es seguro".
- PO (§15.2): destellos de Maxi al salir o reiniciar (conservar); lectura de "victoria asegurada" en Cometa al volante;
  velocidad de 950 px/s (opcional).

**Veredicto final para Maxi: APROBADO CON CAMBIOS. HE-134 no se cierra hasta aplicar N-B1 y N-B2 (bloqueantes nuevos).**
