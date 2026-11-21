# Ficha de motor — `shmup` («Viaje estelar arcade»)

- **Autor**: `disenador-mecanicas`, 21-Nov-2026 (tarjeta HE-134, V0 de la épica del viaje arcade v2).
- **Estado**: PROPUESTA, **tercera pasada** (21-Nov-2026). La auditoría provisional de `experto-ux-parvulo` rechazó la
  ficha para Maxi (veredicto «RECHAZADA (provisional)»; registro en `docs/auditorias-ux/2026-11-21_viaje-arcade.md`).
  La segunda pasada cerró los bloqueantes B1 a B3 y aplicó las mejoras M1 a M16 y los puntos P2 y P3. La **tercera
  pasada** (§18) cierra los bloqueantes N-B1 y N-B2 de la re-auditoría, aplica las mejoras N-A1 a N-A5 y N-N7 y resuelve
  el pulido Pa a Pj que era de la ficha.
  Pendiente: re-auditoría de `experto-ux-parvulo` (perfil de Maxi) sobre la tercera pasada, `guionista` (ajustes de §8.2, §10.3 y §17), el PO
  (§15.2) y `disenador-niveles` (datos). No bloquea a HE-135 (spike 3D). La implementación (HE-136 a HE-137) va después
  del capítulo 1.
- **Fuentes**: `docs/minijuegos/viaje_arcade_propuesta.md` (§2, §4, §5, §6.1 y **§7.1, que manda**), GDD §1, §2
  (Cometa), §5, §6 (regla 11) y §8, `docs/fichas/motor-runner.md` (formato y escala por edad), `docs/TABLERO.md`
  (HE-134 a HE-142) y `docs/auditorias-ux/2026-11-21_viaje-arcade.md`.
- **Qué reemplaza**: el shooter pixel de `scripts/nucleo/viaje_estelar.gd` (`NIVELES`). El motor es **pantalla del
  núcleo**, no un minijuego de `minijuego_base.gd` (regla de oro 4): el mapa estelar no cambia.
- **Mecánica probada de referencia** (regla de oro 3): shmup de desplazamiento horizontal tipo **Galaga** (formaciones y
  picadas), **Gradius/Raiden** (armas por nivel, escudo, opciones), **Asteroids** (rocas que se parten), **R-Type**
  (jefes con fases telegrafiadas) y **Sky Force / 1945 Air Force** (arrastre relativo al dedo). El shooter es
  exclusivo del viaje: ningún otro minijuego lo usa.

**Marcas**: **[PO]** decisión del PO (§7.1, 21-Nov-2026) · **[Ref]** tomado del juego de referencia ·
**[Propuesta]** de `disenador-mecanicas`, reversible · **[Por delegación]** decisión menor inferida de §7.1 o de las
reglas del GDD (el PO delegó la forma exacta; se registra para que lo confirme) · **[Confirmar PO]** pregunta abierta
al PO (§15.2).

---

## 0. Cómo leer esta ficha

- Los números son del **plano lógico de 1280 × 720** (la lógica no depende de la técnica). La técnica de
  presentación (3D real con fondo pintado, o sprites si el spike V1 no pasa 55 fps) se decide en HE-135 y no cambia
  nada de lo que dice esta ficha.
- Lo que cambia por hermano está en §6. Lo que nunca cambia está en §2 (reglas que no se rompen). El control exacto
  de Maxi está en §4.2.
- Todo parámetro que no sea de motor vive en datos (`datos/viaje/perfiles.json` y `datos/viaje/rutas/<origen>_<destino>.json`),
  no en código (§11).

### 0.1 Registro de la segunda pasada (21-Nov-2026)

| Id de la auditoría | Qué cambió en la ficha | Dónde |
|---|---|---|
| B1 | Franja de esquina 280 × 120 px sin arrastre ni acortar; casa y Cometa ≥ 96 px con 40 px entre bordes; Cometa fijo en Maxi; fuente de destellos dentro del sector; destellos de Maxi al salir [Confirmar PO] | §0, §2.10-11, §4, §4.2, §9.2, §15.2 |
| B2 | Se quita "sin lerp" de la regla 2 para Maxi; seguimiento con 950 px/s, llegada en 1 cuadro, límites con margen 60 px y rebote | §2.2, §4, §4.2, §6, §14 (R2) |
| B3 | Se quita la pantalla intermedia; icono de descanso ≥ 96 px en el HUD, sin tiempo límite, con voz de Cometa | §7.2, §7.4, §10.3 |
| M1 | Maxi: gag ≤ 1,2 s + reinicio ≤ 0,8 s = ≤ 2 s; fogonazo de aparición en el checkpoint | §2.4, §7.1-7.2 |
| M2 | Hit-stop solo a enemigos y balas enemigas; máximo uno cada ~300 ms | §2.13, §4, §4.1 |
| M3 | El jefe usa barra con estrella, no corazones | §5.3 |
| M4 | Multitouch: solo el primer dedo controla | §2.12, §4 |
| M5 | Sin "tropiezo" en Cometa al volante; Cometa visible en la cabina | §7.4 |
| M6 | Estrellas de Maxi = multiplicador; símbolo ×3 = tres estrellas llenas | §6, §6.1 |
| M7 | Cometa repite siempre la última instrucción, incluida la intro | §2.6, §4, §10.3 |
| M8 | Voz y sonido alineados: en la acción solo sonidos; §10.2 corregido | §2.6, §10.2, §10.3 |
| M9 | Fotosensibilidad: al tope de 3 destellos/s se suprime el destello blanco | §2.8, §4.1 |
| M10 | Fogonazo (≤ 1 cuadro) y sonido (≤ 100 ms) se miden por separado | §13, criterio 11 |
| M11 | Bolsas por disparo o contacto; pinza telegrafiada y esquivable; bolsas ≥ 96 px en Maxi | §8.1 |
| M12 | Confeti del jefe de Maxi no daña; punto débil con sonido guía | §5.3 |
| M13 | Intros saltables con un toque sin bloquear el control; resultados saltables tras 1,5 s | §10.1, §10.3 |
| M14 | Temblor de cámara bajo por defecto en Maxi | §4.1, §6 |
| M15 | Pium de Maxi a −6 dB con tope de 4 por segundo | §4.1, §6 |
| M16 | Aspiradora del jefe con empuje limitado y telegrafiado; botones del descanso sustituidos por icono ≥ 96 px | §5.3, §7.4 |
| P2 | En PC, el puntero sin clic no mueve la nave (Maxi incluido) | §6 |
| P3 | Videos de despegue y llegada saltables con un toque, sin disparar ni mover | §3, §10.1 |
| P1, P4, P5 | Pulido no detallado en el encargo: confeti con tope y permanencia (P1), HUD del trayecto sin números (P4), alabeo de Maxi ≤ 10° (P5). Propuesta por delegación, a validar en la auditoría | §4.1, §5.4, §6 |

---

## 1. La mecánica en una frase y la referencia

**La nave del hermano vuela de izquierda a derecha por el espacio, sigue el dedo con el arrastre, dispara mientras el
dedo está apoyado, esquiva o rompe meteoritos, basura y recolectores del Coleccionauta, y llega al jefe-artefacto del
Coleccionauta, que se desarma en confeti; el Coleccionauta huye al planeta de destino.**

### 1.1 Qué tomamos del shmup y qué cambiamos

| Tomamos [Ref] | Cambiamos [Propuesta] |
|---|---|
| Arrastre relativo 1:1, sin retraso (Sky Force) | Nicole y Sofía, 1:1. Maxi sigue al dedo con 120 px arriba (para no taparlo) a velocidad máxima de 950 px/s, sin suavizado (§4.2) |
| Disparo automático o con el dedo apoyado | Maxi dispara automático **mientras haya un dedo apoyado**; Nicole y Sofía, dedo apoyado = disparo (sin segundo botón) [Por delegación] |
| Formaciones que entran en curva y se lanzan en picada (Galaga) | Maxi sin picadas; Nicole 1 de cada 3; Sofía frecuentes y en pareja |
| Arma por niveles que baja al golpear (Raiden) | Maxi no baja su arma al golpear; Nicole y Sofía bajan 1 nivel |
| Escudo-burbuja y "opciones" (Gradius) | Escudo por sector para Maxi; mini-Cometas ayudantes como power-up (Cometa es el power-up) |
| Jefes con fases telegrafiadas y punto débil (R-Type) | Jefe = **artefacto del Coleccionauta** (§5.3); el Coleccionauta no se destruye |
| "Continue" de arcade (Galaga, arcades clásicos) | "¡Otra vez!" desde el último checkpoint de la ruta, puntaje a 0 y récord con reglas de crédito (§7.3) |
| Puntaje con multiplicador (Geometry Wars, Sky Force) | Tope y castigo por perfil (§6); Maxi con estrellas, no con números |

---

## 2. Reglas que no se rompen

1. **Solo tocar y arrastrar** (GDD §6.4): mover = arrastrar con un dedo; disparar = dedo apoyado. Sin dobles toques,
   sin gestos de dos dedos, sin botón de disparo ni de bomba. La **Supernova** se activa al recogerla (§5.4).
2. **Responde en < 100 ms** (GDD §6.5): Nicole y Sofía: la nave sigue al dedo 1:1 en el mismo cuadro (sin `lerp`).
   Maxi: seguimiento sin suavizado con velocidad máxima de 950 px/s (§4.2) [Confirmar PO]; si la distancia al objetivo
   es ≤ 950 px/s × Δt del cuadro (15,8 px a 60 fps, 31,7 px a 30 fps; Pa), la nave llega en el mismo cuadro. El primer disparo sale en el cuadro del toque; el fogonazo se mide por separado del
   sonido (criterio 11, M10).
3. **Nada duele ni es violento** (GDD §1, §6.11): lo que se rompe "se desarma" en confeti, tuercas y pedacitos de
   colores. Ningún enemigo tiene cara triste ni sonido de error. Los golpes son un "boing" de la nave, no rojo ni zumbido.
4. **Perder siempre da risa** (GDD §1, §6.11): el gag de derrota dura **≤ 1,5 s** (Maxi, **≤ 1,2 s**). El **gag más el
   reinicio suman ≤ 2 s en los tres perfiles** (M1). El reintento es automático y tocar cualquier parte fuera de la
   franja de esquina (regla 11) lo acorta (§7.2). **Cero progreso perdido** en lo consolidado.
5. **Sin conteos que apuren** (GDD §6.11): no hay cuenta regresiva en ningún punto de la partida.
6. **Voz y sonido alineados** (M8, GDD §5): durante la acción, **solo sonidos**. La voz va en **pantalla vacía** (inicio de
   ruta, checkpoints, sector listo, encuentro del Coleccionauta sin enemigos ni balas, resultados) o en **≤ 0,5 s** que
   no tapen el disparo. Tocar a Cometa **repite siempre la última instrucción de voz**, incluida la intro (M7).
   **Cola de voz** (N-A1): si una línea no puede sonar en ese instante, Cometa responde al instante con estiramiento y
   "pluf" (≤ 100 ms, sin voz) y la línea queda en **cola de una sola línea** hasta la próxima pantalla vacía o un hueco
   de **≥ 0,5 s**; si llega otra, la nueva reemplaza a la encolada. La "última instrucción" es la que sonó o la que quedó
   en cola. La intro cuenta como instrucción aunque se haya saltado (§10.3).
7. **Sin texto para jugar** (GDD §6.2-6.3): los números de puntaje (Nicole y Sofía) y las estrellas son
   decoración, no instrucciones. Ningún texto obligatorio; las líneas de Cometa y del Coleccionauta son audio.
8. **Fotosensibilidad** (M9): ningún destello blanco de pantalla completa; el destello blanco de impacto es de 1-2
   cuadros por enemigo y **nunca más de 3 destellos por segundo en la pantalla** (contando todos los enemigos, el
   fogonazo de aparición en el checkpoint incluido). Al llegar al tope se **suprime el destello blanco**; la chispa y el
   sonido siguen. [Por delegación]
9. **El motor no conoce el tema**: enemigos, jefes, líneas y colores llegan de los datos de la ruta.
10. **Salir siempre es seguro** (GDD §6.8): el botón casa está siempre visible y sale sin cuadro de confirmación. Salir a
    mitad de sector no quita lo consolidado (§9.2). Lo del sector en curso se pierde para Nicole y Sofía; para Maxi, ver
    el destello de sector en §9.2 **[Confirmar PO]**.
11. **Franja de esquina** (B1) [Propuesta]: el rectángulo **280 × 120 px** en la esquina superior izquierda no inicia
    arrastre, no dispara, no acorta el gag, el reinicio ni los videos. Dentro de la franja solo reaccionan **Cometa**
    (repite la instrucción, §4) y el **botón casa** (sale, §4). La nave no entra en la franja (§4.2). Tocar la franja
    vacía da un "pluf" suave y Cometa se estira, sin voz (N-A2).
12. **Multitouch** (M4) [Propuesta]: **solo el primer dedo controla**. Un segundo dedo no dispara, no mueve la nave y no
    cambia nada. Si el primer dedo se levanta, la nave se queda quieta; el segundo dedo no toma el control: hace falta un
    toque nuevo.
13. **Hit-stop** (M2) [Propuesta]: el congelamiento de 40-60 ms afecta **solo a enemigos y balas enemigas**; nunca a la
    nave ni a sus disparos. Como máximo uno cada ~300 ms, para que no se trabe la acción.

---

## 3. Estructura de una partida

```
[video despegue]  solo la 1.ª vez que ese hermano entra a la ruta (HE-140, N-B2); se salta con un toque (P3)
  ↓
intro de Cometa (Sofía ~10 s, Nicole, Maxi ~3 s): se salta con un toque, sin bloquear el control (M13)
  ↓
cuenta de largada (sin voz larga: "¡vamos!" de Cometa, ~1,5 s; sin cuenta regresiva en pantalla)
  ↓
SECTOR 1  →  [checkpoint: inicio] … [checkpoint: mitad] … sector cerrado (banderita, destellos consolidados)
  ↓
SECTOR 2  →  [checkpoint: inicio] … [checkpoint: mitad] … sector cerrado
  ↓   (Sofía, en las rutas de la 3.ª etapa: SECTOR 3 y SECTOR 4, mismo patrón)
[checkpoint: antes del jefe]  (aquí suena "¡cuidado, se prepara!", con pantalla vacía)
  ↓
JEFE-ARTEFACTO del Coleccionauta (2 fases en Sofía; 1 en Maxi y Nicole)  →  el artefacto se desarma en confeti
  ↓
ENCUENTRO: el Coleccionauta provoca, sus bolsas caen (destellos) y huye al planeta de destino  (~8 s)
  ↓
RESULTADOS sin texto (§10.1)  →  [video llegada]  solo la 1.ª vez que ese hermano llega por esa ruta (HE-140, N-B2); después, llegada corta
```

- **Mapa de la barra de trayecto**: una línea con una banderita por sector y el icono del Coleccionauta al final.
  Sin números.
- **Duración sin morir (referencia para el bot)**: Maxi ~60 s · Nicole ~100 s · Sofía ~140 s (§6). El encuentro del
  Coleccionauta cuenta dentro de esa cifra.
- **Oleadas**: cada sector es una lista de oleadas declaradas en datos (formación, meteoritos con hueco, torretas).
  El sector termina cuando pasa su última oleada. Guía para `disenador-niveles`: 5-6 oleadas por sector (Maxi),
  7-8 (Nicole), 8-10 (Sofía).
- **Checkpoints**: se colocan en un **hueco de la ruta con la pantalla vacía** (la oleada anterior ya salió). Así
  el reinicio nunca cae encima de un enemigo.
- **Intro y video**: durante la intro no entran enemigos ni balas (pantalla vacía, M8). La nave se puede mover, pero no
  dispara hasta que termina o se salta. [Por delegación]
- **Quién ve la intro y el video** (N-B2, "primera vez" por hermano y por ruta, no global): la intro larga de Nicole y
  Sofía suena la primera vez que ese hermano entra a esa ruta (`intro_vista` en `Progreso`). El video de despegue y el de
  llegada, la primera vez que ese hermano los ve (`video_visto`). La intro corta de **Maxi** ("¡toca y la nave va!")
  suena en **cada entrada** a la ruta, porque es su única instrucción de la ruta. [Por delegación]

---

## 4. Control, disparo e interacciones (tiempos y feedback)

| Acción | Respuesta | Tiempo | Feedback |
|---|---|---|---|
| Apoyar el dedo (primer dedo, cualquier perfil) | Nave lista; empieza el disparo (Maxi: automático mientras haya dedo; Nicole y Sofía: con el dedo apoyado) | ≤ 1 cuadro (16 ms a 60 fps) | fogonazo en la punta de la nave + "pium" (Maxi: −6 dB, máx. 4 por segundo, M15) |
| Arrastrar (primer dedo) | Nicole y Sofía: 1:1. Maxi: hacia el punto del dedo desplazado 120 px arriba, a 950 px/s máx. [Confirmar PO] (§4.2) | ≤ 1 cuadro | la nave se inclina (alabeo; Maxi ≤ 10°, P5) y lanza una estela |
| Levantar el dedo | Cesa el disparo; la nave queda quieta. Maxi se para en el acto; Nicole y Sofía frenan en 0,1 s | ≤ 100 ms | silencio del disparo |
| Segundo dedo (M4) | Ignorado: no dispara, no mueve, no cambia nada | — | ninguno |
| Tocar un power-up | Se recoge con imán de 60 px | ≤ 100 ms | pop + tilín que sube de tono por cada uno seguido |
| Impacto a un enemigo | Destello blanco de 1-2 cuadros (suprimido al tope de 3/s, §2.8), retroceso de 4-6 px, chispas | ≤ 1 cuadro | sonido por capas (golpe + crujido + tilín) |
| Romper algo grande, o golpear el punto débil del jefe | **Hit-stop 40-60 ms** solo a enemigos y balas enemigas (M2), máx. uno cada ~300 ms | — | sonido grande + confeti |
| Recibir un golpe | Temblor de cámara por trauma (§4.1) + hit-stop 40 ms + invulnerabilidad (§6) | ≤ 100 ms | "boing" de la nave; el corazón salta del HUD |
| Tocar a Cometa (dentro de la franja) | **Repite la última instrucción de voz** (M7); no dispara ni mueve. Si hay acción, la línea se encola (§2.6, N-A1) | ≤ 100 ms | Cometa se estira y da un salto, sin voz, sin salir de la pantalla (y ≥ 0; Pd) |
| Tocar en la franja, fuera de Cometa y casa | No arrastra, no salta el gag, no salta el reinicio ni el video (franja, regla 11) | ≤ 100 ms | "pluf" suave y Cometa se estira, sin voz; nada más cambia (N-A2) |
| Tocar el botón casa (dentro de la franja) | Va al mapa estelar; la partida en curso se abandona (§2, regla 10) | ≤ 100 ms | sin cuadro de "¿seguro?" (salir siempre es seguro, GDD §6.8) |
| Tocar el icono de descanso (Nicole y Sofía, §7.4) | Solo si el toque **empieza** sobre el icono (un dedo que llega arrastrando no lo activa). Vuelve al mapa con la nave en el planeta de origen; checkpoint guardado (§7.6). No aparece ni responde durante el gag ni el reinicio (N-N7) | ≤ 100 ms | Cometa dice adiós; sin cuadro intermedio |
| Tocar durante el gag o el reinicio (fuera de la franja) | Acorta el gag y empieza el reinicio (§7.2) | ≤ 100 ms | fogonazo de aparición en el checkpoint |
| Tocar durante una intro o un video (fuera de la franja) | Se salta (§3, §10.1) | ≤ 100 ms | "pop" suave (N-A2) |

### 4.1 Game feel

- **Temblor de cámara por trauma**: el trauma sube con cada impacto y decae en ~0,5 s; la amplitud es proporcional
  al trauma al cuadrado y usa **ruido**, no seno. **Máximo: 4 px en Maxi (M14, 30 % del temblor por defecto) y 10 px en
  Nicole y Sofía.** Se apaga con "menos movimiento" (zona de papás). [Propuesta; los números son valores de partida]
- **Pium de Maxi** (M15): −6 dB respecto a Nicole y Sofía y con un tope de 4 sonidos de disparo por segundo, para no
  cansar el oído. Nicole y Sofía, sin tope. [Propuesta]
- **Restos**: los pedacitos de confeti y tuercas quedan medio segundo (sensación de permanencia, P1). Tope de 40
  partículas por evento en Maxi, para que la pantalla no se llene. [Propuesta]
- **Alabeo y llamas**: la nave gira en 3D al subir y bajar; las llamas crecen al avanzar. Maxi: alabeo ≤ 10° (P5).
- **Tilín por multiplicador**: el sonido sube de escala con el multiplicador ("Peggle", "Tetris Effect"). En Maxi, el
  tilín sube con cada estrella llena (§6.1).
- **Números flotantes** (Nicole y Sofía): pequeños, al golpear; el "×N" del multiplicador tiene color.
- **Cámara**: fija; vista lateral levemente picada (técnica en HE-135).

---

## 4.2 Seguimiento, campo y límites (B1 y B2)

**Maxi** (seguimiento sin suavizado con tope de velocidad) [Propuesta, a calibrar en el bot y en la prueba con niños]:
- El objetivo es la posición del dedo **menos 120 px en vertical**.
- La nave avanza hacia el objetivo a **950 px/s como máximo** (rango de calibración 900-1000 px/s, en datos) [Confirmar PO]. No hay
  suavizado (ni `lerp` ni inercia): cada cuadro la nave se mueve el mínimo entre la distancia y 950 px/s × tiempo del
  cuadro.
- Si la distancia al objetivo es **≤ 950 px/s × Δt** (lo que se recorre en un cuadro: 15,8 px a 60 fps, 31,7 px a 30 fps;
  Pa), la nave llega **en el mismo cuadro**. Así el umbral funciona también a 30 fps.
- El valor de 120 px lo decide la observación con niños (R1), como ya decía la ficha. Si el dedo tapa la nave, se baja.

**Nicole y Sofía**: 1:1 desde el punto de apoyo, sin tope de velocidad (el dedo es el límite).

**Campo jugable para los tres perfiles** [Propuesta]:
- La nave vive en **x ∈ [60, 1220]** e **y ∈ [60, 660]** (margen de 60 px).
- Si **x < 340**, la nave no entra en la franja: **y ≥ 180** (la franja ocupa hasta y = 120, más su margen).
- **Hitbox, no sprite** (Pb): las comprobaciones de franja, de icono de descanso y de borde usan la **hitbox** (centro y
  radio de choque del perfil, §6), no el dibujo de la nave (~130 px). El sprite puede pasar bajo el HUD; la hitbox no.
- **Maxi**: al tocar el borde del campo, la nave se detiene sobre él y **rebota visualmente** (aplastamiento de 4-6 px
  durante 120 ms y un "boing" suave, sin pérdida de vida). [Propuesta] En x < 340 el borde es y = 180: el aplastamiento
  se muestra en ese borde, que el arte de la franja hace visible (Pc).
- **Nicole y Sofía**: el borde es duro: la nave se para sin rebote. [Por delegación]

**Maxi, sin inercia**: al levantar el dedo la nave se queda quieta en ese cuadro (§4).

**Franja de esquina** (regla 11): dentro de x < 280 e y < 120, un dedo que empieza ahí no arrastra. Si un dedo que ya
arrastra entra en la franja, la nave queda en su borde (por los límites de arriba).

**Cometa en Maxi**: **fijo** en la franja, sin desplazarse. El GDD §2 dice que Cometa "flota/rebota" como ayudante
permanente: **esa parte no aplica a Maxi**, para que el lugar de Cometa sea siempre el mismo y no lo confunda con el
objeto que se mueve. En Maxi solo hay animación de cuerpo (estirarse, saltar al tocar), sin cambiar su hitbox. Para
Nicole y Sofía, Cometa puede flotar dentro de la franja sin salirse de ella. [Por delegación]
**Cometa no sale de la franja en ningún momento, tampoco en la ayuda "Cometa al volante"** (N-B1). En la cabina de la
nave solo hay un **copiloto decorativo** (un casco o un gorro asomando), sin hitbox, sin voz y que no recibe toques: un
toque sobre él es un toque normal del campo. Así Cometa no compite con la nave por el dedo.

**Disposición de la franja** (mismo plano de 1280 × 720):
- **Casa**: botón de **96 × 96 px** en (12, 12).
- **Cometa**: **96 × 96 px** en (148, 12).
- **Separación** entre sus bordes: **40 px** (de 108 a 148).
- Ninguno de los dos recibe toques de la nave ni de ningún power-up.

**PC** (P2): el puntero **sin clic no mueve la nave** en ningún perfil, Maxi incluido. Mover = clic apretado y arrastrar,
el mismo código que táctil (§6).

---

## 5. Enemigos, power-ups y jefes

### 5.1 Enemigos (propuesta para `guionista`, validar)

Todos los enemigos tienen **radio de choque = 70 % del dibujo** (perdonar siempre). Puntos base en §9.1.

| Enemigo | Modelo (Kenney CC0, `space-kit`) | Comportamiento | Cómo se desarma | Quién lo tiene |
|---|---|---|---|---|
| **Meteorito dormilón** | `meteor`, `meteor_detailed`, `rock_crystals*` | Entra en línea recta, lento, girando | Maxi: 1 corte (2 pedacitos blandos). Nicole: 1 corte. Sofía: 2 cortes (2 → 4) | Todos |
| **Basura espacial** | `satelliteDish*`, `barrel`, partes de `rocket_*` | Deriva en curva lenta; no dispara | Se parte en tuercas | Todos |
| **Recolector del Coleccionauta** | `craft_speederA-D` recoloreadas | Vuela en formación tipo Galaga y se lanza en picada hacia la nave para "coleccionarla". Si toca la nave: rebota, la nave hace "boing" y pierde 1 corazón | Explota en confeti | Nicole (1 de cada 3 en picada) y Sofía (picadas frecuentes, en pareja). **Maxi: sin picadas** (formación que solo ondula) |
| **Torreta-boya** | boya sencilla recoloreada | Queda fija o flota; **dispara burbujas de jabón** | Explota en confeti | Nicole (burbujas lentas, 160 px/s) y Sofía (burbujas apuntadas a 240-300 px/s; abanicos de 3-5 en el sector 3 y en el jefe). **Maxi: la boya flota y no dispara** |
| **Burbuja de jabón** (proyectil) | sprite de burbuja | Viaja recta o apuntada; no rebota | Al tocar la nave: "plop" + golpe | Solo Nicole y Sofía |

### 5.2 Formaciones y frecuencia (valores de partida; `disenador-niveles` los fija)

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| Enemigos a la vez (máximo) | 4 | 8 | 12 |
| Formaciones por sector | 3, sin picada | 4, 1 de cada 3 se lanza en picada | 5, picadas frecuentes y en pareja |
| Velocidad de avance (px/s), de inicio a fin de la ruta | 150 → 190 | 220 → 300 | 280 → 400 |
| Hueco mínimo en lluvias de meteoritos | 300 px | 220 px | 160 px |
| Aviso antes de un peligro grande (telegrafía) | 1,5 s | 1,0 s | 0,7 s |
| Repetición máxima del mismo tipo seguido | 2 | 2 | 2 |

Telegrafía de todo peligro grande: el objeto **brilla y suena** durante el aviso antes de moverse; nada aparece de la
nada. El aviso es **sonoro y visual** (sin voz, M8).

### 5.3 El jefe: motor de jefe por datos (artefacto del Coleccionauta)

- **Un jefe por ruta**, temático del destino. Es un **artefacto del Coleccionauta** (un objeto de su colección
  pilotado o capturado por él), no el Coleccionauta. Se desarma en confeti cuando llega a 0 de vida. El
  Coleccionauta se va en su nave (§8).
- **Dos fases en Sofía** (la segunda empieza al 50 % de vida: patrones más rápidos y abanicos); **una fase en Maxi y
  Nicole**, con 2 patrones cada uno.
- **Patrones**: cada ataque tiene **telegrafía** (brillo + sonido, durante 0,7-1,5 s según perfil, §5.2) y un
  **punto débil iluminado** que recibe el hit-stop y el golpe fuerte (×3 de daño). **Punto débil con sonido guía** (M12):
  mientras está abierto suena un "tic" suave cada 0,5 s, sin voz. [Propuesta]
- **Maxi**: el mini-jefe **no dispara**; sus dos patrones son de cuerpo (rebota en el sector y gira; se abre y
  suelta confeti). El contacto con el cuerpo cuenta como golpe normal (boing + 1 corazón, con invulnerabilidad). **El
  confeti no daña en Maxi** (M12) **y no empuja la nave** (N-A3): cae, se desvanece y deja un "pluf" y un temblor de 4 px,
  sin pérdida de corazón. La nave queda quieta, como en §4. Si el PO pidiera empuje, solo mientras haya dedo apoyado [Confirmar PO].
  Con su punto débil se vence en 20-30 s.
- **Nicole**: la **aspiradora** (Arcoíris → Animalia) limita el empuje del chorro a **120 px/s** (M16) y el chorro siempre
  se telegrafía con viento visible durante 1,0 s; nunca lleva a un choque sin aviso. [Propuesta]
- **Vida del jefe** (valores de partida, golpes con arma nivel 1): Maxi 40 · Nicole 90 · Sofía 160. **Confirmar con
  el bot**: con 8 disparos/s, 40 golpes son solo 5 s; la vida se calibra para que el jefe dure **20-30 s (Maxi),
  30-45 s (Nicole) y 40-60 s (Sofía)** con sus patrones. Si no llega, sube.
- **Barra de vida del jefe** (M3): **no usa corazones**, para que no se confunda con la vida de la nave. Es una barra
  ancha y horizontal arriba al centro, con un **icono del artefacto** al final (no una estrella, N-A4) que se apaga al vaciarse la barra. Sin texto.
  [Propuesta]

#### Jefes propuestos por ruta (`guionista` valida; el artefacto y el objeto que quiere el Coleccionauta)

| Ruta (origen → destino) | Artefacto (jefe) | Patrón de la fase 1 | Qué quiere el Coleccionauta (su colección) |
|---|---|---|---|
| Tierra → Arcoíris | **Meteorito Dormilón** (el actual): bosteza y lanza piedritas; despierta y rueda | Bosteza (telegrafía larga) y lanza piedritas en fila; luego rueda de un lado al otro | Una **estrella fugaz** |
| Arcoíris → Animalia | **Aspiradora gigante** recolectora | Su boca abre un chorro que empuja a la nave (telegrafiado con viento visible; empuje ≤ 120 px/s, M16); suelta cajitas de colores | Un **pincel de colores** |
| Animalia → Melodía | **Tocadiscos-ovni** | Dispara notas en abanico de 3-5 (sólo Sofía y Nicole en versión suave); gira el disco y cambia de ritmo | Un **canto de pájaro** |
| Melodía → Cuenta-Cuentas | **Grúa de cubos numerados** | Lanza cubos que rebotan contra el suelo del sector; el cubo central tiene el punto débil (se ve por forma, no por número) | Una **fila de bolitas** para contar |
| Cuenta-Cuentas → Letralandia | **Torre de bloques con letras** | La torre se apila y se derrumba en dos mitades; los bloques caen en telegrafía | Un **libro** (una palabra bonita) |
| Letralandia → Corazón | **Globo-caritas** (globo gigante con cuatro caritas que cambian de color) | Cambia de carita (la nave sabe el ataque por el color de la carita); suelta globitos que empujan | Un **abrazo para su álbum** |
| Corazón → Coleccionauta | **Nave del Coleccionauta** (modelo de HE-131; provisional hasta entonces) | Fase 1: lanza su pinza para atrapar la nave (se esquiva, §8.1). Fase 2 (Sofía; en Maxi y Nicole, la misma nave sin fase 2): sus **bolsas** de colección caen y se ven | Un **amigo** (la lección final: los amigos no se coleccionan, se hacen) |

> En la ruta final el Coleccionauta **no se destruye**: se le hacen caer las bolsas (§8). Es la misma regla que en
> las demás, con el objeto de la colección dicho en voz.

### 5.4 Power-ups (la lista completa; sin botón de activación)

| Power-up | Efecto | Duración | Quién lo recibe | Cómo llega |
|---|---|---|---|---|
| **Cápsula de arma** | Sube el arma +1 (1 → 2 → 3) | Hasta que baja por golpe | Todos | Aparece en cada sector |
| **Escudo-burbuja** | Absorbe 1 golpe (la burbuja revienta con "plop" dulce) | Hasta usarse | Maxi: **uno al empezar cada sector** (no se acumulan). Otros: regalo tras derrotas (§7.4) | Automático / regalo |
| **Mini-Cometas** (dos ayudantes que copian el disparo) | Dos Cometas pequeños junto a la nave | 12 s | Todos (Cometa es el power-up) | Cápsula especial, 1 por sector. Al aparecer, un sonido de "hola" (sin voz, M8) |
| **Imán de destellos** | Atrae los **destellos sueltos** de la pantalla (§9.2) desde toda la pantalla | 10 s | Todos | Cápsula especial |
| **Supernova** (rara) | Limpia la pantalla de enemigos y balas enemigas; se activa al recogerla, **sin botón**. Sonido de "uuuh" (efecto, sin voz, M8) | Instantáneo | Todos | Muy rara: 1 de cada 3 sectores como máximo |
| **Corazón** | +1 corazón (sin pasar del máximo) | — | Maxi: **garantizado al cerrar un sector si perdió alguno**. Nicole: 1 por sector solo si le falta. Sofía: **no hay corazones sueltos** | Al cerrar sector (Maxi y Nicole) |

---

## 6. Escala por perfil

Valores de partida [Propuesta], **calibrados con el jugador simulado** (bot con tiempo de reacción de ~600 ms Maxi,
~400 ms Nicole, ~300 ms Sofía y error de puntería por edad) hasta la meta del GDD §6 regla 11: **llegar al jefe y
vencerlo sin "¡otra vez!" en el primer intento** en ~90 % (Maxi), ~75 % (Nicole) y ~60 % (Sofía).

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| Estructura | 2 sectores + mini-jefe | 3 sectores + jefe | 3 sectores + jefe de 2 fases (**4 sectores** en las rutas de la 3.ª etapa del viaje, §12) |
| Duración sin morir (referencia) | ~60 s | ~100 s | ~140 s |
| **Corazones** | **5** + escudo al empezar cada sector | **4** | **3** |
| Invulnerable tras un golpe | 2,5 s | 2,0 s | 1,5 s |
| Radio de choque de la nave | 20 px | 24 px | 28 px |
| Arma al golpear | **no baja** | baja 1 nivel | baja 1 nivel |
| Cadencia de disparo | 8/s, automático **mientras haya dedo** | 7/s, con el dedo apoyado | 6/s, con el dedo apoyado |
| Seguimiento | al dedo, desplazado 120 px arriba, **950 px/s máx., sin suavizado** (§4.2) [Confirmar PO] | 1:1 desde el punto de apoyo | 1:1 desde el punto de apoyo |
| Teclado / mouse (PC) | con clic apretado, igual que táctil (P2). Teclado opcional: flechas. Maxi usa el mismo tope que táctil, 950 px/s (Pf) | flechas a 700 px/s | flechas a 700 px/s |
| Temblor de cámara (máx.) | **4 px** (M14) | 10 px | 10 px |
| Sonido del disparo | −6 dB, máx. 4 por segundo (M15) | normal | normal |
| Vidas extra | — (corazón garantizado al cerrar sector) | 1 corazón por sector (si falta) + vida extra a **20.000** pts | vida extra a **30.000** y **80.000** pts (Galaga) |
| Multiplicador | **estrellas** (ver §6.1); no baja por golpe | tope ×5; un golpe lo divide por 2 | tope ×8; un golpe lo vuelve a ×1 |
| Puntaje visible | **no hay número**: 3 estrellas que se llenan (§6.1) | número + ×N | número + ×N |
| Estrellitas al llegar | — (Maxi cierra con destellos, §10.1) | — | 1 = llegar · 2 = puntaje ≥ umbral de la ruta · 3 = umbral alto **y** partida sin "¡otra vez!" |
| Checkpoints por ruta | 5 (inicio y mitad de cada sector + antes del jefe) | 7 | 7 (9 con 4 sectores) |
| Icono de descanso (§7.4) | — | tras **3** derrotas seguidas | tras **4** derrotas seguidas |

**Notas de escala**:
- Maxi tiene **el mayor margen** (5 corazones, escudo por sector, invulnerabilidad más larga, radio de choque más
  pequeño, temblor y pium más suaves) y **ningún proyectil enemigo**. Su reto es la **lectura** de formaciones y el jefe
  de cuerpo, no la velocidad. Sus enemigos son lentos y muy visibles.
- Nicole y Sofía tienen reto real: balas enemigas (Nicole lentas; Sofía apuntadas), picadas, velocidad que sube,
  corazones contados y multiplicador que se castiga. **No es "dificultad de bebé"** (regla de oro 2): Sofía tiene
  velocidad y balas apuntadas desde el sector 2.
- Los umbrales de vida extra (20.000 / 30.000 / 80.000) son el punto de partida de la propuesta. **Regla de
  calibración**: la vida extra debe alcanzarla ~40 % de la jugadora simulada de su edad. Si con los puntos base de §9.1
  no llega, se bajan los umbrales en datos (no en código) en V7.

### 6.1 Multiplicador y estrellas de Maxi, en una línea [Propuesta; Maxi por delegación]
- **Nicole y Sofía**: sube +1 por cada 5 enemigos destruidos seguidos sin recibir golpe, hasta el tope del perfil. Un
  golpe lo baja según la tabla de §6. Los puntos del jefe (§9.1) no se multiplican.
- **Maxi** (M6): sus **3 estrellas del HUD son el multiplicador** y el único símbolo de estrella de Maxi (N-A4). Empieza con 1 estrella llena (×1). Cada **5 enemigos
  destruidos seguidos** sin golpe llena una estrella más, hasta 3 (**×3**). Un golpe reinicia el conteo de la racha (los 5 enemigos se cuentan desde cero), pero **no vacía** las estrellas (Pe). Al **reiniciar** (§7.2)
  vuelven a 1 estrella. El **símbolo ×3 es las tres estrellas llenas**, con un brillo dorado; no hay números. Cada
  estrella que se llena suena un tilín más alto. Las estrellas no se vacían al empezar un sector (la racha sigue).
  [Por delegación]

---

## 7. Vidas, derrota y "¡otra vez!"

### 7.1 Cómo se pierde
- Se pierde al quedarse **sin corazones** durante un intento. El último golpe no tiene "boing", tiene el gag.
- **Gag de derrota** (máximo): **≤ 1,5 s** en Nicole y Sofía; **≤ 1,2 s** en Maxi (M1). La nave se desarma en pedacitos
  de colores; Cometa queda mareado dando vueltas; la música se "desinfla" (el tono baja 1 s) y suena un "pffft"
  suave. Nada de rojo, zumbidos, pantallas oscuras ni caras tristes (GDD §6.11).

### 7.2 "¡Otra vez!": reinicio al último checkpoint [PO, §7.1-3 y 7.1-4]
- **Sin pantallas intermedias** (B3): tras el gag, la partida vuelve **sola** al último checkpoint de esa ruta. El
  reinicio, con el fogonazo de aparición de la nave en el checkpoint, dura **≤ 0,8 s** en Maxi y **≤ 0,5 s** en Nicole y
  Sofía. **El gag más el reinicio suman ≤ 2 s en los tres perfiles** (M1, en lugar de los ~3 s de antes).
- **Cometa dice "¡otra vez!"** por voz en el checkpoint, con pantalla vacía (M8).
- **Tocar cualquier parte fuera de la franja de esquina** durante el gag o el reinicio lo acorta (regla 11). No hay
  botón obligatorio, así que no hay cartel. [Por delegación: el PO pidió "inmediato, sin pantallas intermedias" y la
  alternativa de botón ≥ 160 px queda en §15.2.]
- **Sin cuenta regresiva** en ningún momento.
- Al reiniciar: **vidas llenas**, **arma según regalo** (nivel 1 normal; nivel 2 si el regalo está activo), escudo de
  sector (Maxi), **estrellas en 1** (Maxi) o **puntaje a 0 y multiplicador ×1** (Nicole y Sofía). Los enemigos y balas de
  pantalla se borran y la oleada empieza en el checkpoint.
- **Destellos**: los de los sectores cerrados se conservan (§9.2); los del sector en curso se pierden (salvo la
  propuesta de Maxi de §9.2 **[Confirmar PO]**).

### 7.3 Récord y "crédito" [Por delegación, §4.1 de la propuesta]
- Una partida que termina en derrota **sí puede ser récord** si no usó ningún "¡otra vez!" (su puntaje es el de su
  último momento).
- Cualquier partida que haya reiniciado en un checkpoint **no puede ser récord**: el puntaje de ese intento empieza
  en 0 y, como en el arcade, el récord "vale por crédito". Así la partida se puede terminar sin presión y el récord
  sigue siendo de la partida limpia.
- El récord **nunca baja** (GDD §6).

### 7.4 Ayudas de Cometa (GDD §6.11, la tabla de la regla 11)
- **Regalo** (arma nivel 2 + escudo-burbuja, sin acumular): tras **2** derrotas seguidas (Maxi, Nicole) o **3** (Sofía).
  Se entrega al reiniciar, con la voz "¡un regalo!".
- **Ayuda fuerte "Cometa al volante"** (solo Maxi): tras **3** derrotas seguidas. En el intento siguiente:
  imán permanente, **enemigos a la mitad** de frecuencia durante toda la ruta y **el último corazón no se pierde**.
  Los golpes hacen **solo "boing"** (M5: sin tropiezo). **Cometa no sale de la franja** (N-B1); en la cabina de la nave aparece solo un **copiloto decorativo** (casco o gorro
  asomando), sin hitbox, sin voz y sin recibir toques, durante toda la
  ayuda (M5), para que Maxi entienda quién la lleva. La ruta queda ganable siempre. Cometa lo anuncia: "¡Cometa al volante!".
  [Propuesta; la lectura de "victoria asegurada" queda en §15.2]
- **Descansar** (sin obligar; solo Nicole y Sofía) [Por delegación, sustituye a los dos botones de la 2.ª pasada, B3]:
  - Tras **3** derrotas seguidas (Nicole) o **4** (Sofía), al **terminar el reinicio** en el checkpoint aparece un **icono de descanso
    de 96 × 96 px** (una luna con cama) en la **esquina superior derecha** del HUD (x 1168-1264, y 12-108).
  - Cometa dice una vez "¿Descansamos un ratito?" (voz, con pantalla vacía).
  - **No hay pantalla**: la partida sigue sola y la nave se puede mover. **Sin tiempo límite**: el icono queda visible
    hasta que se cierra el sector en curso; si el niño sigue cayendo, reaparece en el siguiente reinicio.
  - Tocar el icono (un toque que **empieza** sobre él, N-N7) lleva al mapa con la nave en el planeta de origen; el checkpoint queda
    guardado (§7.6). No hay "¿seguro?".
  - **Fuera del campo y sin aparecer en el gag ni el reinicio** (N-N7): el icono ocupa x 1168-1264, y 12-108 y la nave no
    entra en ese rectángulo (§4.2). Aparece solo al terminar el reinicio; la voz del checkpoint sí puede sonar en la
    pantalla vacía del reinicio.
  - Maxi no tiene icono de descanso (su ayuda es "Cometa al volante").
- Las derrotas seguidas se cuentan **por ruta** y se borran al completarla o al descansar.

### 7.5 Llave de padres
Desde la zona de padres se puede **saltar el viaje** (llegar al destino sin jugar). Así el viaje nunca traba a nadie
(regla de oro: el juego es para los niños y para los papás).

### 7.6 Checkpoints al volver: salir a medias [Confirmación de §7.1-4]
- Cada checkpoint cruzado se guarda en `Progreso` por **hermano y ruta** en `perfiles.<id>.viaje.<ruta>` (`checkpoint`, `intro_vista`, `video_visto`; N-B2).
- **Si un niño sale a medias, al volver a esa ruta retoma el último checkpoint de esa ruta**, no el inicio. Así
  lo leímos en §7.1-4 ("al volver, retoma el último checkpoint"). Se entra **sin video** si ese hermano ya lo vio (`video_visto`,
  aunque la partida no se terminara), sin intro larga si ya la vio (`intro_vista`) y con vidas llenas y puntaje a 0. La
  intro corta de Maxi suena igual (N-B2), y Cometa repite la intro aunque se haya saltado (§2.6, M7).
- Al **completar la ruta**, su checkpoint se borra: la siguiente vez empieza desde el inicio. Los flags `intro_vista` y `video_visto` no se borran: son por hermano y ruta.
- Otro hermano que entre a esa ruta tiene **su propio** checkpoint (cada hermano tiene su progreso).

---

## 8. El Coleccionauta en cada viaje

**Rol** [PO, §7.1-6]: aparece en **todos** los viajes como encuentro final. Se deja ver, provoca (con gag) y **huye al
planeta de destino**. No se destruye ni se derrota del todo. Engancha la historia con el planeta siguiente.

### 8.1 Secuencia fija (la misma en las 7 rutas, solo cambian las líneas y el objeto)

1. **Aparece** tras el artefacto: asoma en la cabina del artefacto (si el artefacto aún está entero) y se ríe.
   Al desarmarse el artefacto, la pantalla queda **sin enemigos ni balas**: aquí empiezan las voces del encuentro (M8).
2. **Provoca**: intenta atrapar algo de la nave con su **pinza** o su red, con gag. **Orden fijo** (N-A5): primero suena la
   línea `provoca` (qué quiere para su colección, §8.2), con pantalla sin enemigos ni balas; **después** la pinza **se telegrafía** (brillo y
   sonido) durante **1,5 s en Maxi, 1,0 s en Nicole y 0,7 s en Sofía** (M11), es lenta y **esquivable**. Si la nave la
   toca, no hay daño: la nave hace "boing", la pinza se enreda (`gag_pinza`, sin voz) y **la nave no queda inmovilizada**
   (Pg): sigue obedeciendo el dedo. La pinza se **lanza solo al terminar la voz `provoca` y su telegrafía**; nunca se
   lanza mientras suena una voz.
3. **Bolsas**: tres bolsas de colección cuelgan de su nave. **Se revientan por disparo o por contacto de la nave**
   (M11 [Por delegación]). Son **≥ 96 px en Maxi** (M11). Cada una que se revienta **en objetos de la ruta** que caen y
   flotan: son **destellos sueltos del jefe** (1 por bolsa, recogibles con el imán de 60 px, hitbox 96 px en Maxi).
4. **Huye**: su nave se va hacia el planeta de destino, con una frase de despedida. La pantalla se va cerrando en un
   fondo que apunta al planeta de destino (que crece, para empalmar con HE-140).

**Duración**: ~8 s, sin pantallas de texto. Si el jugador no toca las bolsas, el Coleccionauta huye igual (no hay
derrota por eso).

### 8.2 Líneas-tipo por ruta (solo intención; el texto final lo escribe `guionista`)

Todas son **audio** (GDD §6.2). El texto de abajo es un **borrador orientativo** para que `guionista` vea el tono;
no es texto de pantalla. Tono: cómico, torpe, nunca malvado (GDD §1).

| Ruta | Clave (provoca / huye) | Intención | Borrador orientativo (tono) |
|---|---|---|---|
| Tierra → Arcoíris | `provoca_tierra_arcoiris` / `huye_arcoiris` | Quiere una estrella fugaz; se enreda con la red | "¡Esa estrella queda chistosa en mi colección!" · "¡Me voy a Arcoíris, que allá hay colores!" |
| Arcoíris → Animalia | `provoca_arcoiris_animalia` / `huye_animalia` | Quiere el pincel; el pincel le hace cosquillas | "¡Un pincel! Para pintar mi colección de rayas" · "¡Animalia me llama, quiero ver a los animalitos!" |
| Animalia → Melodía | `provoca_animalia_melodia` / `huye_melodia` | Quiere un canto de pájaro; le sale un hipo | "¡Un canto para mi colección! ¡Hip!" · "¡Me voy a Melodía a bailar!" |
| Melodía → Cuenta-Cuentas | `provoca_melodia_cuenta_cuentas` / `huye_cuenta_cuentas` | Quiere las bolitas para contarlas; se confunde con el conteo | "¡Bolitas! Una, dos… ¿cuántas eran?" · "¡Me voy a contar a Cuenta-Cuentas!" |
| Cuenta-Cuentas → Letralandia | `provoca_cuenta_cuentas_letralandia` / `huye_letralandia` | Quiere un libro; no sabe leer el título | "¡Un libro! ¡Léemelo tú, que yo no sé!" · "¡Me voy a Letralandia, que hay cuentos!" |
| Letralandia → Corazón | `provoca_letralandia_corazon` / `huye_corazon` | Quiere un abrazo para su álbum; los abrazos son "cosas" que no caben | "¡Un abrazo para mi álbum! ¿No cabe? ¡Qué pena!" · "¡Me voy a Corazón, que allá dan abrazos gratis!" |
| Corazón → Coleccionauta | `provoca_corazon_coleccionauta` / `huye_coleccionauta` | Quiere un amigo; se da cuenta de que los amigos no caben en cajas | "¡Un amigo para mi colección!" · "Los amigos no se guardan en cajas… ¿me enseñan a pedir las cosas?" (la frase final es la lección del GDD §1: `guionista` la ajusta) |

**Claves comunes** (las 7 rutas): `bolsa_revienta` (sonido de bolsa con tilín, sin voz), `bolsa_vacia` (la última bolsa:
"¡ay, ay, ay!" cómico), `gag_pinza` (el enredo de la pinza, sin voz, con risa de Cometa), y `cometa_celebra`
(Cometa bailando al verlo huir).

**Lo que nunca dice el Coleccionauta**: nada de amenazas, ni "te voy a atrapar", ni "vas a perder". El verbo de sus
intentos es **querer** ("quiero para mi colección"), no **robar**.

---

## 9. Puntaje, destellos y récord

### 9.1 Puntaje (base; `disenador-niveles` los fija en datos)

| Evento | Puntos base (× multiplicador) |
|---|---|
| Meteorito grande (primer corte) | 50 |
| Pedacito de meteorito (segundo corte, Sofía) | 20 |
| Basura espacial | 30 |
| Torreta-boya | 40 |
| Recolector del Coleccionauta | 60 |
| Fila completa de una formación (Galaga) | +300, sin multiplicar |
| Punto débil del jefe | 150 |
| Jefe vencido (el artefacto se desarma) | 1.000, sin multiplicar |

### 9.2 Destellos (la energía estelar, GDD §1)

**Fuente dentro del sector** (B1) [Por delegación]:
- **Destello suelto del sector**: cada sector tiene **1 destello** en datos (`destello_suelto`), que aparece en la
  **oleada final** del sector y viaja con el avance (como un objeto del campo, a la altura media). Se recoge **tocándolo
  con la nave** o con el imán. Hitbox **96 px en Maxi**, 64 px en los demás.
- Al recogerlo pasa a **"en juego"**. Al **cerrar el sector** (pasar su última oleada) se **consolida**. Si el niño no lo
  recoge antes de que salga de la pantalla, **no se gana** (por eso la oleada final se diseña con tiempo suficiente:
  el destello tarda ~6 s en cruzar la pantalla).
- Los destellos del sector en curso se pierden si hay **derrota** o **salida** (regla 10), salvo la propuesta de Maxi
  de abajo.

**Otras fuentes**:
- **Al vencer el artefacto**: 1 destello extra (consolidado al instante).
- **Cada bolsa del Coleccionauta** que se revienta da 1 destello suelto (§8.1).
- **Sofía, estrellitas** (1-3, §6): sí dan destello extra al cumplirlas (3 estrellitas = +1).
- **Total de referencia** por ruta: **5-7 destellos** (antes 3-5; sube por las bolsas). Lo fija `disenador-niveles`.
  Lo consolidado nunca se pierde (GDD §6.11: "destellos y estrellitas solo se ganan al ganar").
- **Dónde se suman**: a la ruta, para el destino (`Progreso.registrar_viaje`, como hoy).

**Maxi: salir o reiniciar no quita los destellos ya ganados en el sector** (B1). [Confirmar PO]
- Propuesta: para Maxi, los destellos **ya recogidos en el sector en curso se conservan** al reiniciar en el
  checkpoint y al salir, y se consolidan al cerrar el sector.
- Motivo: un perfil de 2 años no debe perder una estrella que ya tocó; la regla 10 de §2 sigue para Nicole y Sofía.
- Si el PO lo rechaza, se aplica la regla general (se pierden).

### 9.3 Récord por hermano y por ruta [PO, §7.1-7]
- **Un récord por hermano y por ruta** (`perfiles.<id>.records.viaje.<ruta>`), sin subir la versión del guardado
  (mismo patrón que `_completar_v3()`, 08-Nov).
- **Visible en el mapa estelar** junto a la nave: para Nicole y Sofía, el número del récord de la ruta; para Maxi,
  su cara, sin estrella ni número (N-A4).
- **Durante la partida**: al superar el récord de la ruta aparece un **destello** de récord en el HUD (en Maxi, sin estrella: N-A4) y suena un tilín;
  no pausa. La celebración completa es al final (§10).
- Las reglas de elegibilidad son las de §7.3.

---

## 10. Celebración (parte de la mecánica, no adorno)

### 10.1 Resultados (sin texto)
Tras el encuentro del Coleccionauta, pantalla de resultados de **~6 s**. **Se salta con un toque tras 1,5 s** (M13),
fuera de la franja de esquina. Pasos:
1. Las estrellitas de la ruta suben una a una, con tilín (Maxi y Nicole: destellos; Sofía: estrellas de 1 a 3).
2. Los **destellos** ganados vuelan al hangar (la nave se llena de luz un instante).
3. **Puntaje** (Nicole y Sofía): cuenta de 0 al total con tilines que suben de tono. Maxi: sin número ni estrellas (N-A4); sus destellos vuelan al hangar en el paso 2.
4. Si hay **récord**: confeti, Cometa baila y dice "¡récord!" (voz) con la melodía de la fanfarria. Si es el primer
   récord de esa ruta: "¡tu primer récord!". **Maxi** (Ph, [Propuesta]): en el récord salta con el **puño derecho
   arriba** y suena su grito de celebración ("¡¡siiii!!", efecto de la voz de Maxi, sin voz de Cometa; si se usa una
   grabación, la aprueba el PO). Lo mismo al vencer el artefacto (§10.2).
5. Cierre: Cometa sonríe, saluda, y el mapa muestra el planeta de destino brillando.
- **Música**: la de resultados es el **chiptune actual** como guiño (decisión §7.1-8).
- **Videos de despegue y llegada** (P3): se saltan con un toque en cualquier parte fuera de la franja, sin disparar ni
  mover. El video de despegue solo se ve la 1.ª vez que ese hermano entra a la ruta (§3, N-B2).

### 10.2 Celebración de los enemigos y power-ups (corregida, M8)
- Cada enemigo roto: confeti de colores + tuercas que rebotan + un tilín de escala. **Solo sonidos**, sin voz.
- Supernova: un **"uuuh" de efecto** (no de voz) y todo se limpia en un destello dulce (no blanco de pantalla completa).
- Mini-Cometas: un **sonido de "hola"** al aparecer, sin voz (antes: "¡hola!" de cada uno; ahora la voz no va en la acción).
- Sector cerrado: banderita y confeti en el momento; **"¡sector listo!"** (voz) cuando la pantalla queda vacía
  tras la última oleada.
- **Vencer el artefacto, Maxi** (Ph): salta con el puño derecho arriba y suena su grito (efecto, sin voz de Cometa).
  Nicole y Sofía: confeti y tilín, como en el resto de celebraciones.
- Cometa y el icono de descanso: ver §7.4.

### 10.3 Voces (claves; la voz va en pantalla vacía o en ≤ 0,5 s, M8)

| Clave | Momento | Intención |
|---|---|---|
| `intro_maxi` / `intro_nicole` / `intro_sofia` | Al entrar a la ruta: Maxi, en cada entrada (N-B2); Nicole y Sofía, la primera vez que ese hermano entra (`intro_vista`). Se salta con un toque; tocar a Cometa la repite (M7) | Maxi: "¡toca y la nave va!" · Nicole: "¡mueve tu nave con el dedo, y apoya para disparar!" · Sofía: "Mueve la nave con el dedo. Apoya para disparar. Las formaciones se lanzan en picada: ¡obsérvalas!" |
| `sector_inicio` (1, 2, 3) | En el checkpoint de inicio de cada sector, con pantalla vacía; la primera oleada entra ≥ 2 s después | Breve y con el número hablado: "¡sector uno!" |
| `sector_listo` | Al quedar la pantalla vacía tras la última oleada | "¡sector listo!" |
| `aviso_jefe` | **En el checkpoint antes del jefe** (pantalla vacía). Durante la telegrafía del jefe, solo sonido y brillo (M8) | "¡cuidado, se prepara!" (≤ 1 s) |
| `otra_vez` | Tras el gag, en el checkpoint con pantalla vacía | "¡otra vez!" |
| `regalo` | Al reiniciar con regalo | "¡un regalo de Cometa!" |
| `cometa_al_volante` | Al reiniciar con ayuda fuerte (Maxi) | "¡Cometa al volante!" |
| `descanso` | Al llegar al checkpoint del reinicio, con pantalla vacía (Nicole y Sofía); el icono aparece al terminar el reinicio (N-N7) | "¿Descansamos un ratito?" (sin presión; sin pantalla; sin tiempo límite) |
| `record` / `primer_record` | Al final de la ruta | §10.1 |
| `supernova` | Al recoger la Supernova | Sin voz: sonido "uuuh" de efecto (M8) |
| `provoca_*`, `huye_*`, `bolsa_*`, `gag_pinza` | Encuentro del Coleccionauta, con pantalla sin enemigos ni balas (§8.1) | §8.2 |

Todas las claves tienen **audio provisional** (TTS, como Cometa y Coco) y el guion final lo escribe `guionista`.
Sin texto en pantalla (GDD §6.3).

---

## 11. Parámetros que expone al archivo de nivel (data-driven)

Esqueleto de `datos/viaje/rutas/<origen>_<destino>.json` (los perfiles viven en `datos/viaje/perfiles.json`):

```jsonc
{
  "id_ruta": "tierra_arcoiris",
  "origen": "tierra", "destino": "arcoiris",
  "video": { "despegue": "res://…/despegue_tierra_arcoiris.ogv", "llegada": null },  // null = aún sin video (ver §12)
  "perfiles": {
    "semilla": {
      "sectores": [
        { "oleadas": [ /* formación, meteoritos, hueco… */ ], "checkpoints": ["inicio", "mitad"],
          "destello_suelto": { "oleada": "final" } },   // §9.2 [Por delegación]
        { "oleadas": [ /* … */ ], "checkpoints": ["inicio", "mitad"], "destello_suelto": { "oleada": "final" } }
      ],
      "jefe": { "id": "meteorito_dormilon", "fases": 1, "vida": 40, "patrones": ["bosteza", "rueda"],
                "checkpoint_antes": true },
      "coleccionauta": { "provoca": "provoca_tierra_arcoiris", "huye": "huye_arcoiris", "bolsas": 3,
                         "pinza_aviso": 1.5 }
    },
    "brote": { /* igual, 3 sectores */ },
    "estrella": { /* igual, 3 sectores (4 en la 3.ª etapa) y jefe de 2 fases */ }
  },
  "dificultad": "res://datos/viaje/perfiles.json#semilla"   // o el bloque inline
}
```

`datos/viaje/perfiles.json` guarda la tabla de §6 completa: corazones, invulnerabilidad, radio, cadencia, seguimiento
(para Maxi: **velocidad máxima 950 px/s, desplazamiento 120 px, margen 60 px**), velocidades, enemigos a la vez,
proyectiles, aviso, hueco, multiplicador, temblor máximo, volumen del pium, regalo, descanso (tras 3 o 4), umbrales de
vida extra y de estrellitas. Lo de `ruta` (oleadas, checkpoints, jefe, líneas) y lo de `perfil` (la tabla) se combinan
en `logica_viaje.gd` (HE-136).

**Progreso por hermano y ruta** (N-B2, en el autoload `Progreso`, sin subir la versión del guardado): `perfiles.<id>.viaje.<ruta>`
= `{checkpoint, intro_vista, video_visto}`; el récord va en `perfiles.<id>.records.viaje.<ruta>` (§9.3). Ningún flag es global.

**Validación al cargar** (`push_warning` si falla): cada sector tiene al menos un checkpoint de inicio; el hueco entre
dos oleadas de Maxi es ≥ 1,5 × aviso; ninguna formación de Maxi tiene picada; ninguna torreta de Maxi dispara; el
jefe de Sofía tiene 2 fases; **ningún enemigo, bala ni destello suelto nace dentro de la franja (280 × 120 px) ni en el
icono de descanso**; cada sector tiene exactamente un destello suelto en su oleada final; el jefe de Maxi no tiene
proyectiles; la pinza de Maxi tiene aviso ≥ 1,5 s.

---

## 12. Fila para el GDD §6, regla 11 (texto, para el dueño del documento)

Esta es la fila que debe añadirse a la tabla de la regla 11, **sin editar el GDD desde aquí** (lo hace el dueño del
documento). Las columnas siguen el orden de la tabla existente: Sofía · Nicole · Maxi.

| Fila | Sofía · Estrella | Nicole · Brote | Maxi · Semilla |
|---|---|---|---|
| **Shooter del viaje** (vidas de un shmup) | **3 corazones**; sin corazones sueltos; vida extra a 30.000 y 80.000 pts; regalo tras **3** derrotas (escudo + arma 2); icono de descanso tras **4** | **4 corazones**; 1 por sector si le falta; vida extra a 20.000 pts; regalo tras **2**; icono de descanso tras **3** | **5 corazones** + escudo al empezar cada sector; sin proyectiles enemigos; regalo tras **2**; **"Cometa al volante"** tras **3** (enemigos a la mitad, último corazón protegido, sin tropiezo) |
| **Reinicio del shooter del viaje** | Desde el **último checkpoint** de la ruta (inicio o mitad de sector, o antes del jefe), con vidas llenas, puntaje a 0; sin pantalla intermedia; gag + reinicio ≤ 2 s | Igual | Igual, con gag ≤ 1,2 s; gag + reinicio ≤ 2 s |

Nota para el dueño del GDD: la fila "Juegos de reflejos (runner)" de la misma tabla **no** cambia. Esta fila es
aparte porque el viaje es un shmup y tiene checkpoints. La fila de "Perder" de §6.11 menciona un "cartel con botón
≥ 160 px" para el reintento; el viaje **no** tiene cartel (§7.2, decisión §7.1-3 del PO): ver §15.3.

---

## 13. Criterios de verificación (para `dev-godot` y `tester-qa`)

Verificables con el arnés headless (`logica_viaje.gd`, HE-136) y en el teléfono (HE-137):

1. **Control Nicole y Sofía**: con arrastre de N px, la nave se mueve N px en el mismo cuadro.
2. **Control Maxi**: el objetivo es el dedo menos 120 px; la nave avanza a ≤ 950 px/s (rango 900-1000 en calibración);
   si la distancia es ≤ 950 px/s × Δt, llega en el mismo cuadro; no hay suavizado; en el borde del campo (margen 60 px) rebota
   visualmente sin perder vida.
3. **Disparo**: Maxi dispara mientras haya un dedo apoyado y no dispara sin él; Nicole y Sofía no disparan sin el dedo
   apoyado; el primer disparo sale en el cuadro del toque.
4. **Multitouch** (M4): con dos dedos, solo el primero mueve y dispara; si el primero se levanta, la nave queda quieta
   y el segundo no la toma.
5. **Franja de esquina** (B1): un toque dentro de x < 280 e y < 120 que no es Cometa ni casa no mueve, no dispara y no
   salta gag, reinicio ni video. Cometa repite la última instrucción y no sale de la franja (ni en la ayuda); casa sale; la nave no entra en la franja; la franja vacía da "pluf" (N-A2).
6. **Golpes**: un golpe quita 1 corazón y deja invulnerable el tiempo de §6; Nicole y Sofía bajan 1 nivel de arma;
   Maxi no baja arma. El confeti del jefe no quita corazón a Maxi y no empuja la nave (N-A3).
7. **Hit-stop** (M2): congela solo enemigos y balas enemigas; nunca la nave ni sus disparos; no se repite antes de ~300 ms.
8. **Checkpoints**: el reinicio cae en el checkpoint con la pantalla vacía de enemigos y balas; vidas llenas; puntaje 0 (Nicole
   y Sofía) o estrellas en 1 (Maxi).
9. **Derrota** (M1): último corazón → gag (≤ 1,2 s Maxi, ≤ 1,5 s los demás) → reinicio automático; **gag + reinicio ≤ 2 s**
   en los tres perfiles; con fogonazo de aparición en el checkpoint; 0 destellos del sector en curso (salvo la propuesta
   de Maxi, §9.2, pendiente).
10. **Salida**: salir a mitad y volver retoma el último checkpoint de esa ruta; completar la ruta borra el checkpoint.
11. **Latencia** (M10): toque → fogonazo ≤ 1 cuadro (16 ms a 60 fps), medido en la tablet con cámara lenta; toque → sonido
    ≤ 100 ms, medido **por separado**; toque → Cometa responde ≤ 100 ms.
12. **Récord**: partida con "¡otra vez!" no registra récord; partida limpia sí; el récord no baja; se guarda por
    hermano y por ruta.
13. **Ayudas**: regalo tras 2 o 3 derrotas según perfil; Cometa al volante solo en Maxi tras 3 (sin tropiezo; Cometa en la franja y copiloto decorativo en la cabina, sin hitbox);
    icono de descanso solo en Nicole (tras 3) y Sofía (tras 4), sin pantalla y sin tiempo límite (criterio 21).
14. **Jefe**: el artefacto se desarma en confeti al llegar a 0; la barra del jefe no usa corazones; el Coleccionauta no se
    destruye (no hay estado de "muerto" en el Coleccionauta); sus bolsas dan destellos sueltos.
15. **Fotosensibilidad** (M9): el contador de destellos de pantalla nunca pasa de 3 por segundo en el arnés de ráfaga; al
    llegar al tope, el destello blanco se suprime y la chispa y el sonido siguen.
16. **Voz y sonido** (M8): durante la acción no suena voz; las voces van en pantalla vacía o en ≤ 0,5 s sin tapar el disparo.
17. **Intros y resultados** (M13): la intro se salta con un toque sin bloquear el control; los resultados se saltan tras 1,5 s.
18. **Sin texto**: ninguna pantalla del viaje tiene texto obligatorio; todas las instrucciones tienen clave de voz.
19. **Icono de descanso** (N-N7, solo Nicole y Sofía): su rectángulo (x 1168-1264, y 12-108) queda **excluido del campo**.
La nave se para en el borde del rectángulo ampliado por su radio de choque; nunca lo cruza. El icono responde solo a un
toque que **empieza** sobre él: un dedo que llega arrastrando no lo activa. No aparece ni responde durante el gag ni el
reinicio (§7.4).

**PC** (P2): el puntero sin clic no mueve la nave en ningún perfil.
20. **Calibración** (V7): bot de cada edad, éxito al primer intento en ~90 / 75 / 60 % (Maxi / Nicole / Sofía); umbrales
    de vida extra y estrellitas en datos.
21. **Icono de descanso** (N-N7): la nave nunca entra en x 1168-1264, y 12-108 (con su radio); el icono solo responde a un
    toque que empieza sobre él (un dedo que llega arrastrando no lo activa); no aparece ni responde durante el gag ni el
    reinicio; aparece al terminar el reinicio.
22. **Cola de voz** (N-A1, M8): con acción en curso, Cometa responde con "pluf" (≤ 100 ms, sin voz) y la voz queda en cola
    de una línea hasta pantalla vacía o un hueco de ≥ 0,5 s; una voz nueva reemplaza a la encolada. Ningún sonido de voz
    tapa el disparo.
23. **Progreso por hermano** (N-B2): dos hermanos que hicieron la misma ruta no comparten `intro_vista` ni `video_visto`;
    Maxi oye su intro corta ("¡toca y la nave va!") en cada entrada a la ruta.
24. **Pinza y Coleccionauta** (N-A5, Pg): la voz `provoca` termina antes de que empiece la telegrafía de la pinza; la pinza
    no inmoviliza la nave.
25. **Franja y copiloto** (N-B1, N-A2): Cometa nunca sale de la franja; el copiloto de la cabina no tiene hitbox; el toque
    en la franja vacía da "pluf" y el saltar intro o video da "pop" de ≤ 100 ms.

---

## 14. Riesgos de usabilidad (para `experto-ux-parvulo`, con foco en el perfil de Maxi)

| # | Riesgo | Qué mirar / propuesta | Estado tras la 2.ª pasada |
|---|---|---|---|
| R1 | **Maxi no entiende que la nave va "arriba del dedo"** (desplazamiento de 120 px) | Verificar en la prueba que Maxi mueve la nave a donde quiere sin tapar el dedo. Alternativa: 60 px o cero, si el dedo tapa la nave. Decidir por la observación, no por la teoría | **Abierto**: se decide en la prueba con niños |
| R2 | **Maxi toca a ráfagas**: la nave se mueve siempre al último punto | Tope de **950 px/s** (900-1000 en calibración), sin suavizado, llegada en 1 cuadro si la distancia es ≤ 950 px/s × Δt, rebote visual en el borde. Verificar que no se marea | **Cerrado en la ficha** (valor fijado); se valida con el bot y en la prueba |
| R3 | **Los 5 corazones se leen como "vida que se va"** | Corazones grandes (≥ 64 px), el corazón salta como "hojita" y se recupera al cerrar sector. Observar la cara de Maxi al perder el primero | **Abierto**: se observa en la prueba |
| R4 | **"Cometa al volante" se siente como trampa o como premio** | Cometa lo anuncia con la voz de regalo; los enemigos bajan sin desaparecer; sin tropiezo (M5); Cometa se queda en la franja y en la cabina solo hay un copiloto decorativo (N-B1) | **Parcial**: se quitó el tropiezo; falta comprobar la lectura en la prueba |
| R5 | **Números y ×N en pantalla para Maxi** | Maxi no ve números. El multiplicador es **3 estrellas** (M6) | **Cerrado en la ficha** |
| R6 | **Gag + reinicio automático**: ¿Maxi entiende que volvió a empezar? | Gag ≤ 1,2 s + reinicio ≤ 0,8 s (≤ 2 s total, M1), con fogonazo en el checkpoint. Cometa dice "¡otra vez!" con pantalla vacía | **Cerrado en la ficha**; se observa en la prueba |
| R7 | **Mantener el dedo apoyado para disparar** (Nicole y Sofía) | Es un gesto de "apoyar y arrastrar", no un gesto nuevo. Confirmar que lo entienden sin explicación larga. Maxi también dispara solo con el dedo apoyado | **Abierto**: playtest |
| R8 | **Sofía sin corazones sueltos y con 3 corazones** puede frustrarse rápido | Regalo tras 3, descanso (icono) tras 4, checkpoints cada mitad de sector. Vigilar la meta de primer intento (~60 %) | **Abierto**: calibrar con el bot |
| R9 | **Telegrafía de jefes** poco visible para Maxi | Brillo fuerte + sonido de aviso; la voz "¡cuidado, se prepara!" va en el checkpoint antes del jefe (M8); la nave no se mueve sola | **Cerrado en la ficha** |
| R10 | **Fotosensibilidad**: muchas chispas y destellos a la vez | Tope de 3 destellos/s (§2.8), supresión del destello blanco al tope (M9), tope de 40 partículas en Maxi (P1) | **Cerrado en la ficha**; se mide en el arnés |
| R11 | **Coleccionauta provoca y huye**: ¿se entiende como "perder" o "ganar"? | Su huida es el premio de llegar al jefe; sin cara triste; la pinza se telegrafía y no daña (M11) | **Abierto**: depende del guion (`guionista`) y de la prueba |
| R12 | **Salida con el botón casa** en la esquina superior izquierda, cerca del dedo | Franja de 280 × 120 px que no inicia arrastre; casa y Cometa a ≥ 40 px entre bordes (B1) | **Cerrado en la ficha**; se verifica que no lo tocan al arrastrar |
| R13 | **Duración de ~60 s y el encuentro** en Maxi | El encuentro es ~8 s. Si Maxi se aburre antes del jefe, se acorta el sector 1 en datos, no el encuentro | **Abierto**: calibrar con el bot |

---

## 15. Decisiones y confirmaciones

### 15.1 Tomadas por delegación (lo que se infiere de §7.1 o del GDD; reversible)
- Reinicio **automático** tras el gag, con tocar fuera de la franja para acortarlo, y **sin cartel ni botón** (§7.2).
- Elegibilidad de récord: solo partidas **sin** "¡otra vez!" (§7.3).
- **Destellos**: 1 destello suelto por sector (oleada final, se consolida al cerrar), 1 extra al vencer el artefacto, 1 por
  bolsa del Coleccionauta (§9.2). Total de referencia 5-7.
- **Maxi, multiplicador**: 3 estrellas = multiplicador (×1 a ×3); la racha sigue entre sectores; se reinicia solo al
  reiniciar la partida (§6.1).
- **Maxi, disparo**: automático mientras haya dedo apoyado (antes: "siempre automático").
- **Franja de esquina** de 280 × 120 px, y campo con margen de 60 px (§4.2).
- **Descansar**: un icono ≥ 96 px en el HUD (solo Nicole y Sofía), sin pantalla y sin tiempo límite (§7.4). Sustituye los
  dos botones de la 2.ª pasada. Fuera del campo y con toque que empieza sobre él (N-N7).
- **Bolsas**: se revientan por disparo o por contacto de la nave (§8.1).
- **Confeti del jefe de Maxi**: no daña y no empuja la nave (§5.3, N-A3).
- **Intro**: sin enemigos ni disparo durante la intro; se salta con un toque (§3).
- **Regalo** = arma nivel 2 + escudo (sin acumular), igual en los tres perfiles (§7.4).
- **Temblor** de Maxi al 30 % (4 px), pium de Maxi a −6 dB con tope de 4 por segundo (§4.1).
- Cómo cuenta la "3.ª etapa" de Sofía: por orden del mapa, no por rutas completadas (§12, pregunta 3).
- **Pulido P1, P4, P5** (confeti con tope y permanencia; HUD del trayecto sin números; alabeo de Maxi ≤ 10°): propuesta
  de esta pasada; la auditoría los puede cambiar.

### 15.2 A confirmar por el PO (§12 de la propuesta, ya ligadas aquí)
1. **¿Reinicio automático o botón "¡otra vez!"?** Cerrado por el PO (§7.1-3: "sin pantallas intermedias"). Queda como
   alternativa solo si el PO quiere un botón ≥ 160 px en el mismo escenario.
2. **Número de rutas**: el TABLERO habla de "6 rutas jugables" y V8 de "las otras 5", pero los viajes son **7**
   (Tierra→Arcoíris más los 6 videos B4, que terminan en Corazón→Coleccionauta). Esta ficha asume **7** (§5.3 y §8).
   ¿Se cuenta Corazón→Coleccionauta como ruta jugable? Afecta a HE-136, HE-142 y el criterio de salida.
3. **"3.ª etapa" de Sofía** (4 sectores): ¿por orden del mapa (desde `animalia_melodia`) o por rutas completadas?
4. **Umbrales de vida extra** (20.000 / 30.000 / 80.000): la propuesta los puso sin base de puntaje. Esta ficha pide
   calibrarlos con el bot (§6) y no los fija como definitivos.
5. **Cometa al volante** [Confirmar PO]: "victoria asegurada" se lee aquí como "el último corazón no se pierde y los
   enemigos bajan a la mitad en el intento". ¿Es la lectura correcta?
6. **Destellos de Maxi al salir o reiniciar** [Confirmar PO] (B1): propuesta de conservar los destellos ya recogidos en el
   sector en curso (§9.2). Si el PO no lo acepta, se pierden como en Nicole y Sofía.
7. **Velocidad de Maxi** [Confirmar PO, opcional]: 950 px/s es una propuesta. Si el PO prefiere otra sensación (más lenta
   o más "de arcade"), se cambia en datos tras la prueba.

### 15.3 Conflictos con el GDD (el dueño del documento decide; esta ficha no lo edita)
- **GDD §8, "❌ Nada 3D"**: choca con §7.1-1 (3D real en Godot, decidido por el PO el 21-Nov). Propuesta: que §8 diga
  "3D solo en el viaje (decisión del PO del 21-Nov)" o similar.
- **GDD §8, "❌ Sin sistema de vidas"**: ya choca con los corazones de los juegos de reflejos (HE-124) y con los
  corazones del shooter (§7.1-5). Propuesta: cambiar la viñeta a "sin vidas que se acaben en ningún juego de
  aprendizaje (la derrota es un gag y el reintento es inmediato)". Esto ya es un conflicto pre-existente, pero el viaje
  lo vuelve visible.
- **GDD §6.4**, "solo tocar y arrastrar": el shooter usa "apoyar y arrastrar" para disparar (Nicole y Sofía) y el
  arrastre con límite para Maxi. Es la misma familia de gesto, pero conviene que lo diga el texto de la regla.
- **GDD §6.11, regla 11, "cartel con botón ≥ 160 px"**: el viaje no tiene cartel (reinicio automático, §7.2). Propuesta
  para el dueño del GDD: añadir en la fila del viaje (§12) "sin cartel" y dejar el cartel para los demás juegos.
- **GDD §2, Cometa "flota/rebota"**: para Maxi, Cometa queda fijo en la franja de esquina (§4.2). Propuesta: que el
  GDD diga "flota (salvo en el viaje con Maxi)" o similar.

---

## 16. Entregables para las tarjetas siguientes

| Quién | Qué | Tarjeta |
|---|---|---|
| `guionista` | Validar enemigos y jefes (§5), las líneas-tipo del Coleccionauta por ruta (§8.2) y las claves de voz (§10.3). **Ajustar** el guion vigente: `viaje_descanso` ya no dice "dos botones" (es un icono, §7.4); `viaje_cometa_al_volante` sin tropiezo; `aviso_jefe` pasa al checkpoint antes del jefe; intros saltables | HE-134 |
| `experto-ux-parvulo` | Re-auditar el perfil de Maxi (§14, R1-R13; B1-B3 y M1-M16 de la auditoría) y la regla de reinicio (§7.2). Revisar la franja de esquina (§2.11, §4.2) y el tope de 950 px/s | HE-134 |
| `disenador-mecanicas` | Esta ficha; luego el ajuste de la tabla de §6 con el bot (V7) | HE-134, HE-141 |
| `disenador-niveles` | Oleadas por sector y checkpoints (§3 y §11), destello suelto de cada sector en la oleada final, puntos de §9.1 y destellos (§9.2, total 5-7) | HE-136 (datos) |
| `director-cinematicas` | Video de llegada del viaje a Tierra→Arcoíris (sin B4, §3 de la propuesta); video de despegue saltable (P3) | HE-140 |
| PO | Las confirmaciones de §15.2 (1, 3, 4 ya cerradas o abiertas; 5, 6 y 7 con [Confirmar PO]) | — |
| `dev-godot` | Implementar `logica_viaje.gd` según §11 y §13 | HE-136 (después del capítulo 1) |

---

## 17. Guion del Coleccionauta y de Cometa (HE-134, `guionista`, 21-Nov-2026)

El guion completo vive en **`docs/guiones/voces-viaje-arcade.md`** (patrón de las demás voces del proyecto). Aquí
queda el resumen para quien implemente:

- **Artefactos-jefe por ruta** (nombre, cómo lo presenta, qué quiere, cómo huye y qué sale de las bolsas): tabla §1 del
  guion. Los nombres siguen §5.3 (Meteorito Dormilón, aspiradora gigante, tocadiscos-ovni, grúa de cubos numerados,
  torre de bloques con letras, globo-caritas y la nave del Coleccionauta).
- **Líneas del Coleccionauta** (`viaje_provoca_*` y `viaje_huye_*`, 14 líneas, más `viaje_bolsa_vacia`): tabla §2.
  Son las claves de §8.2 con texto final. Cada una ≤ 4 s.
- **Líneas de Cometa** (`viaje_cometa_mareado`, `viaje_otra_vez`, `viaje_regalo`, `viaje_descanso`,
  `viaje_cometa_al_volante`): tabla §3. Cometa no regaña, no apura y se marea él en el gag de derrota.
- **Sin voz**: `bolsa_revienta`, `gag_pinza`, `cometa_celebra` (§2.1 del guion), y ahora también el "hola" de mini-Cometas
  y el "uuuh" de la Supernova (§10.2).
- **Rutas de audio**: `assets/audio/voces/viaje/coleccionauta/<clave>.wav` y `assets/audio/voces/viaje/cometa/<clave>.wav`.
- **Pendientes del PO** (§5 del guion): voz del Coleccionauta (papá casero, como en la batalla, o TTS), voz de Cometa
  (OK de costo y `--estimar`), frase final de la lección, canon de captura (antena y mochila-torre frente a "pinza y
  red" de §8), y la revisión de `experto-ux-parvulo` sobre "Un amigo para mi colección" y "Cometa al volante" (R4).
- Cambio respecto a §8.2: `viaje_huye_animalia` dice "quiero ver a los animalitos" (no "tiene animalitos para mí"),
  para que el Coleccionauta no suene a que colecciona animales.
- **Cambios de la 2.ª pasada que el guion debe recoger** (§16): `viaje_descanso` ("Son dos botones" → icono sin
  pantalla), la línea de Cometa al volante sin tropiezo, `aviso_jefe` movido al checkpoint antes del jefe.
- **Cambios de la 3.ª pasada que el guion debe recoger** (§18): `viaje_cometa_al_volante` dice que Cometa se queda en la
  franja (el copiloto de la cabina no habla); la línea `provoca` va antes de la pinza; `intro_*` se reparte por hermano
  y ruta (Maxi, en cada entrada); `viaje_descanso` aparece al terminar el reinicio; el grito de Maxi no es voz de Cometa.

---

## 18. Tercera pasada 21-Nov (re-auditoría de `experto-ux-parvulo`)

- **Fuente**: sección "Re-auditoría 21-Nov" de `docs/auditorias-ux/2026-11-21_viaje-arcade.md` (bloqueantes N-B1 y N-B2,
  mejoras N-A1 a N-A5 y N-N7, pulido Pa a Pj). Alcance: solo especificación; no se implementa, no se toca el tablero ni
  el GDD, no hubo llamadas de pago.
- **Propuesta** `docs/minijuegos/viaje_arcade_propuesta.md`: los textos superados (tasa 14/s en §2.2 y cartel ≥ 160 px en
  §4) quedan marcados como SUPERADOS, con la referencia a esta ficha.

### 18.1 Qué cambió

| Id | Qué cambió | Dónde |
|---|---|---|
| **N-B1** | Cometa no sale de la franja de 280 × 120 px, tampoco en la ayuda "Cometa al volante". En la cabina solo hay un copiloto decorativo, sin hitbox ni voz, que no recibe toques. Se quita "sentado en la cabina" | §4.2, §7.4, §13 (criterio 13), §14 (R4), §15.1 |
| **N-B2** | "Primera vez" por **hermano y ruta**, en `Progreso` (`perfiles.<id>.viaje.<ruta>`: `intro_vista`, `video_visto`). La intro corta de Maxi suena en cada entrada a la ruta. La repetición de Cometa suena siempre | §3, §7.6, §9.3, §10.1, §10.3, §11, §13 (criterio 23) |
| **N-A1** | Voz de Cometa en acción: respuesta de "pluf" en ≤ 100 ms y la línea en cola de una sola voz, hasta pantalla vacía o hueco de ≥ 0,5 s | §2.6, §4, §13 (criterio 22) |
| **N-A2** | Toque en la franja vacía: "pluf" y Cometa se estira. Saltar intro o video: "pop" de ≤ 100 ms | §2.11, §4, §13 (criterio 25) |
| **N-A3** | El confeti del jefe de Maxi no empuja la nave; solo cae, temblor de 4 px y "pluf" | §5.3, §13 (criterio 6), §15.1 |
| **N-A4** | Maxi tiene un solo símbolo de estrella (las 3 del HUD = multiplicador). La barra del jefe lleva el icono del artefacto; el récord, un destello; el mapa, la cara sin estrella; los resultados, destellos | §5.3, §6, §6.1, §9.3, §10.1 |
| **N-A5** | Orden fijo de la pinza: voz `provoca` → telegrafía → lanzamiento; nunca se lanza mientras suena una voz | §8.1, §13 (criterio 24) |
| **N-N7** | Icono de descanso excluido del campo (x 1168-1264, y 12-108, más el radio de la nave); responde solo a un toque que empieza sobre él; no aparece ni responde en gag ni reinicio | §4, §4.2, §7.4, §10.3, §13 (criterio 21), §14 |
| **Pa** | Umbral de llegada en un cuadro: 950 px/s × Δt (15,8 px a 60 fps; 31,7 px a 30 fps), no 16 px fijos | §2.2, §4.2, §13 (criterio 2), §14 (R2) |
| **Pb** | Franja, icono y borde se comprueban con la hitbox (centro y radio), no con el sprite de ~130 px | §4.2 |
| **Pc** | Rebote de Maxi en x < 340: el aplastamiento se muestra en el borde y = 180 (lo hace visible el arte de la franja) | §4.2 |
| **Pd** | El salto de Cometa está acotado a y ≥ 0 | §4 |
| **Pe** | Racha de Maxi: un golpe reinicia el conteo, no vacía las estrellas | §6.1 |
| **Pf** | Teclado: Maxi usa 950 px/s (el mismo tope que táctil); Nicole y Sofía, 700 px/s | §6 [Por delegación] |
| **Pg** | La pinza no inmoviliza la nave: sigue obedeciendo el dedo | §8.1, §13 (criterio 24) |
| **Ph** | Maxi celebra con el puño derecho arriba y su grito "¡¡siiii!!" en el récord y al vencer el artefacto (no es voz de Cometa) | §9.3, §10.1, §10.2 [Propuesta] |
| **Pi** | Tasa 14/s y cartel ≥ 160 px: marcados como superados en la propuesta, con referencia a esta ficha | `docs/minijuegos/viaje_arcade_propuesta.md` §2.2 y §4 |
| **Pj** | Resultados de Maxi sin "estrellitas" (§6 dice "—", §10.1 usa destellos) | §6, §10.1 |
| Pk, Pl | No son de la ficha: el guion (`viaje_descanso`, `viaje_aviso_jefe`, Cometa al volante) lo ajusta `guionista`; la fila del GDD la decide su dueño. No se tocaron | §17 (recordatorio) |

### 18.2 Pendiente de confirmación del PO [Confirmar PO]

1. **Destellos de Maxi al salir o reiniciar** (§2.10, §7.2, §9.2, §15.2-6): conservar los del sector en curso. Sin
   cambios en esta pasada.
2. **Lectura de "victoria asegurada"** en "Cometa al volante" (§7.4, §15.2-5).
3. **Velocidad de Maxi, 950 px/s** (§2.2, §4, §4.2, §6, §15.2-7): el rango 900-1000 se calibra con el bot y con niños.
4. **Empuje del confeti de Maxi**: solo si el PO lo pide, y solo con dedo apoyado (§5.3). Por defecto, no empuja.
5. **Grito de Maxi** (Ph, §9.3 y §10.1): si es una grabación, la aprueba el PO; si es síntesis, no hace falta.

### 18.3 Decisiones de esta pasada por delegación

- Maxi oye su intro corta en cada entrada a la ruta, aunque otro hermano ya la haya hecho (N-B2).
- Nicole y Sofía: la voz "¿Descansamos un ratito?" puede sonar en la pantalla vacía del reinicio; el icono aparece al
  terminar el reinicio (N-N7).
- La cola de voz tiene una sola línea y la nueva reemplaza a la encolada (N-A1).
- Teclado: 950 px/s para Maxi y 700 px/s para Nicole y Sofía (Pf).

### 18.4 Lo que queda para otros

- `experto-ux-parvulo`: re-auditar el perfil de Maxi con esta pasada (N-B1, N-B2, N-A1 a N-A5, N-N7 y Pa a Pj).
- `guionista`: Pk (`viaje_descanso` ya no es "dos botones"; `viaje_aviso_jefe` debe durar ≤ 1 s; Cometa al volante sin
  copiloto con voz; intro por hermano).
- PO y dueño del GDD: Pl (fila del viaje y "sin cartel"; §15.3).
- `tester-qa` (HE-137): criterios 21 a 25 de §13.
