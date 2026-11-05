# Ficha de motor — `runner` («Carrera de Toby», tipo el dinosaurio de Chrome)

- **Autor**: `disenador-mecanicas`, 05-Nov-2026 (tarjeta HE-109).
- **Estado**: PROPUESTA. Falta: maqueta HTML (HE-110) y aprobación del PO, auditoría de `experto-ux-parvulo`
  (HE-111), calibración de `disenador-niveles` (HE-D6), arte de `disenador-personajes` (HE-114: tres
  corredores) y voces de `guionista` (HE-112). La implementación (HE-119) espera al playtest del capítulo 1
  (HE-18).
- **Es el 4.º juego de Animalia** [PO, 05-Nov-2026]. El GDD §4 todavía lista 3 juegos para Animalia: hay que
  agregarlo cuando el PO lo decida (esta ficha no edita el GDD).
- **Fuentes**: GDD §1, §4, §5, §6 y §8; `docs/perfil-jugadores.md`; `docs/stack-tecnico.md`;
  `scripts/base/minijuego_base.gd`; `scripts/base/gestor_turnos.gd`; `docs/fichas/modo-equipo.md` §11.4;
  `docs/fichas/motor-lanzar.md` §2 (la física solo vive en `lanzar`); `docs/fichas/motor-topos.md` §3
  (`racha_toby.gd`).

**Marcas**: **[PO]** decisión del PO (05-Nov-2026) · **[Ref]** tomado del juego de referencia ·
**[Propuesta]** de `disenador-mecanicas`, reversible · **[Abierta]** necesita al PO (§16).

---

## 1. La mecánica en una frase y la referencia

**El corredor de cada hermano (Toby, un pony o un dinosaurio) corre solo por el sendero de la selva; un
toque lo hace saltar troncos, piedras y charcos, y hay que llegar a la meta, y más allá, por el récord.**

### 1.1 El dinosaurio de Chrome: qué hace y cómo escala

Valores del código abierto de Chromium (`offline.js`, juego T-Rex Runner), **aproximados** y en sus unidades
(lienzo de 600 × 150 px, 60 cuadros por segundo):

| Parámetro de Chrome | Valor | Qué significa |
|---|---|---|
| Velocidad inicial | 6 px/cuadro (≈ 360 px/s) | cruza el lienzo en ~1,7 s; un obstáculo tarda ~1,5 s en llegar al dino |
| Velocidad máxima | 13 px/cuadro (≈ 780 px/s) | ~0,7 s de aviso |
| Aceleración | 0,001 px/cuadro² | llega a la máxima en ~7.000 cuadros ≈ **2 min** |
| Tiempo sin obstáculos al empezar | 3 s | para entender que corre solo |
| Hueco entre obstáculos | mínimo = ancho × velocidad + hueco base × 0,6; máximo = 1,5 × mínimo | **el hueco crece con la velocidad**: siempre hay tiempo para aterrizar y volver a saltar |
| Obstáculos repetidos | máximo 2 iguales seguidos; cactus en grupos de 1-3 | la variedad es parte del reto |
| Pterodáctilo | aparece desde velocidad 8,5 (≈ 50 s); 3 alturas | el reto de **no saltar** o agacharse |
| Salto | velocidad inicial ~10, gravedad 0,6; **mantener = salto más alto** | ~0,55 s en el aire |
| Puntaje | distancia × 0,025 (≈ 9 puntos/s al inicio) | sonido de logro cada 100; **modo noche** a los 700 |
| Fin | un choque termina la partida; récord ("HI") a la vista | reintento de un toque |

**Qué tomamos** [Ref]: correr solo, **un toque = saltar**, aceleración hasta la máxima en ~2 min, 3 s
iniciales sin obstáculos, hueco que crece con la velocidad, grupos de obstáculos, obstáculos aéreos que
aparecen más tarde, hitos sonoros cada 100, el paso al **atardecer-noche** como momento memorable y el
récord siempre a la vista.

**Qué cambia** [Propuesta]:

- **Agacharse no existe** (sería un segundo gesto). El obstáculo aéreo alto **se pasa por debajo**: el reto
  es **no saltar** (§8.3).
- **El salto no es física** (GDD §8; la física solo vive en `lanzar`): es una **curva dibujada** de duración
  y altura fijas (§6.2), sin motor de física ni cuerpos rígidos. Los choques son cajas que se superponen.
- **Hay meta**: Chrome es infinito, pero una estación tiene que poder **completarse** (GDD §3). Llegar a la
  meta gana la estación; después de la meta la carrera **sigue** para el récord (§5.3).
- **El choque no siempre termina** (§10): en Semilla no existe y en Brote y Estrella existe la **burbuja**
  protectora del casco de Toby.

**Escala por edad sacada de Chrome**: el reto de Chrome es el **tiempo de aviso** (cuánto tarda el obstáculo
en llegar) y el **hueco** entre obstáculos. Escalamos el tiempo de aviso por el tiempo de reacción de cada
edad (§8.1): Sofía arranca con ~1,3 veces el aviso de Chrome, Nicole con ~1,8 y Maxi con ~3.

### 1.2 Choques con otras mecánicas del juego

- No es ritmo (Melodía): los obstáculos no caen al compás de la música.
- No es la carrera de autitos de Maxi en Cuenta-Cuentas (allá se **ordenan** vehículos con números).
- Los autos de Maxi **no** entran aquí por decisión del PO (Maxi corre con dinos); quedan para Cuenta-Cuentas.

## 2. Reglas que no se rompen

1. **Un solo gesto: tocar** en cualquier parte del área de juego = saltar (GDD §6.4). Sin doble toque y sin
   deslizar.
2. **Responde al presionar, en < 100 ms**: el corredor se agacha para tomar impulso en el mismo cuadro (§6.2).
3. **Nada duele**: un choque es un tropiezo de dibujo animado (rueda, cae en el barro, se sacude). Los
   obstáculos son blanditos o de juguete.
4. **Sin voces mientras se corre** (GDD §5): solo sonidos. La voz va al inicio, en la meta y al terminar.
5. La lógica (`LogicaRunner`) va sin pantalla y es **determinista con semilla** (la secuencia de obstáculos
   sale de un generador con semilla y reglas, como el Río; no es contenido procedural: no inventa niveles,
   reparte obstáculos del nivel con las reglas de Chrome).
6. El motor no conoce el tema: corredor, obstáculos, coleccionables y fondo llegan del nivel.
7. Nada de bichos (Nicole y Sofía): los aéreos son pajaritos, globos, hojas o nubecitas.

## 3. ¿Se puede reutilizar un motor existente? (respuesta honesta)

No hay ningún motor de desplazamiento lateral ni de reflejos con un toque. `lanzar` usa física y un arrastre de
resortera: no sirve, y además la física es su excepción exclusiva. **Motor nuevo `runner`**
(`scripts/motores/runner/`). Se reutilizan `barra_record.gd`, `celebracion.tscn`, `racha_toby.gd`, el
fondo de la zona en capas (parallax) y el modo equipo.

## 4. La escena (1280 × 720)

| Elemento | Dónde | Notas |
|---|---|---|
| Fondo | 3 capas con parallax (lejos 0,2 · medio 0,5 · sendero 1,0) | el ambiente de la zona |
| **Sendero** (suelo) | y 600 | plano, como en Chrome |
| **Corredor** | x 220 (fijo en pantalla), pies en y 600 | alto: Maxi 170 px, Nicole 160, Sofía 150 |
| Obstáculos | aparecen en x 1320 (fuera de pantalla) | §8 |
| Botón casa y Cometa | arriba a la izquierda | **no saltan**: los toques ahí no hacen saltar |
| **Camino a la meta** | arriba al centro (430-850, 30-60) | una línea de huellitas con la cara del corredor que avanza hacia la banderita de meta; sin números |
| Puntaje | arriba a la derecha | Sofía: número + barra de récord; Nicole: solo la barra (`barra_record.gd`) |
| **Banderita de récord en el mundo** | clavada en el sendero en el punto del récord | §9.3 |

**Área que hace saltar**: toda la pantalla salvo los botones (casa, Cometa) y la barra de récord.

## 5. Bucle de juego

### 5.1 Arranque

Toby (o el corredor) se pone en posición, Cometa da la largada con su voz ("¡en sus marcas… listos… ya!") y
empieza a correr. 3 s sin obstáculos [Ref] (2,5 s en Sofía).

### 5.2 Carrera

- El mundo se mueve a `velocidad`, que sube hasta `velocidad_max` en `segundos_a_max`.
- Los obstáculos salen con los huecos de §8.2. Los **coleccionables** (huesitos, huevitos de dino,
  manzanitas) flotan a la altura de un salto, entre obstáculos.
- **Hitos**: cada 100 puntos, campanita y un saltito de orejas [Ref].
- **Atardecer** [Ref: modo noche de Chrome]: al 70 % del camino a la meta, el cielo pasa en 4 s a un atardecer
  dorado y después a una **noche estrellada** con estrellas fugaces (nunca oscura: el sendero sigue claro).

### 5.3 Meta y tramo del récord

- Al llegar a la meta: la carpa de Toby (o el volcán de Maxi, o el establo de Nicole) **revienta en confeti**,
  suena la fanfarria y la estación queda ganada (`asegurar_victoria` en ese instante).
- **Maxi** termina ahí.
- **Nicole y Sofía** siguen corriendo: "¡sigue, sigue, por el récord!". La velocidad sigue subiendo hasta la
  máxima. El tramo del récord termina con el primer choque sin burbuja, o al llegar al **final del
  sendero** (`tramo_record_s`: Nicole 45 s, Sofía 90 s), que es una fiesta extra ("¡llegamos al final de la
  selva!"). En el tramo del récord **chocar no es derrota**: es el final de una carrera ya ganada.

## 6. Interacciones y game feel del salto

### 6.1 Interacciones

| Acción | Respuesta | Tiempo | Feedback |
|---|---|---|---|
| Tocar en el suelo | Salto | impulso en el mismo cuadro | §6.2 |
| Tocar en el aire | Nada nuevo (sin doble salto); en Semilla, una voltereta y un rugido | inmediato | el corredor guiña, para que el toque se vea respondido |
| Tocar hasta 150 ms antes de aterrizar | **Se guarda** y salta al tocar el suelo (salto en cola) | — | sin esto, el toque "se pierde" y parece que no respondió |
| Tocar hasta 100 ms después de dejar un borde | — | — | no aplica: el suelo es plano |
| Tocar la casa o Cometa | Lo de siempre | inmediato | no hace saltar |

### 6.2 El salto (curva dibujada, no física)

- **Impulso**: al presionar, el corredor se aplasta (1,2 de ancho, 0,8 de alto) durante `impulso_s` y despega.
  El impulso es la respuesta inmediata al toque.
- **Vuelo**: `y(t) = altura × 4 × (t / T) × (1 − t / T)`, con `T = duracion_salto_s`. Durante la subida se
  estira (0,9 × 1,15); arriba, gira las orejas; al aterrizar, aplasta otra vez con tierrita y un "pum" suave.
- **Salto variable** (opcional, `salto_variable`, solo Sofía desde z4) [Ref: mantener = más alto]: si el dedo
  sigue apoyado más de 0,12 s, la altura sube hasta un 35 % (tope a los 0,25 s). Ver §16, pregunta 3.
- **Salto imantado de Maxi** [Propuesta]: en Semilla, si toca hasta 1,2 s antes de un obstáculo, el impulso
  **se estira** (el dino se agacha más, entre 0 y 0,5 s, rugiendo) para despegar en el instante justo y pasar
  limpio. El toque se responde al instante (se agacha); lo que se ajusta es cuándo despega. Así **todo salto de
  Maxi cerca de un obstáculo sale perfecto**.
- **Salto amable de Brote** [Propuesta]: si con el salto normal la caja del corredor rozaría el borde del
  obstáculo por ≤ 12 px, el vuelo se alarga hasta un 10 % y pasa.

### 6.3 Cajas de choque (perdonar siempre)

- Obstáculos: caja de **70 %** del ancho y **80 %** del alto del dibujo, centrada abajo.
- Corredor: caja de **60 %** del ancho y **75 %** del alto.
- Coleccionables: zona de **150 %** del dibujo (agarrar es fácil, chocar es difícil).

### 6.4 Game feel general

- **Correr**: ciclo de 4 cuadros, rebote de 6 px, polvito cada paso; la velocidad se nota en las capas del
  fondo y en el ritmo de los pasos (sube con la velocidad).
- **Pasar un obstáculo**: no da puntos ni voz (como Chrome), pero suma a la **racha de saltos limpios**
  (§9.1), que se ve en la colita de Toby (`racha_toby.gd`); cada 5 seguidos, chispitas y un "¡yuju!" corto.
- **Agarrar un coleccionable**: pop, "+25" flotante y un "ting" que sube de tono por cada uno seguido.
- **La burbuja** (§10.2): el corredor lleva una burbuja de vidrio alrededor que brilla suave.
- **Temblor** de pantalla solo en el choque (0,15), desactivable con "menos movimiento".

### 6.5 SFX

`pasos` (con tempo), `impulso`, `salto`, `aterrizar`, `hito_100`, `coleccionable` (con tono), `burbuja_plop`,
`burbuja_nueva`, `tropiezo`, `barro_splash`, `sacudida`, `atardecer`, `estrella_fugaz`, `meta_confeti`,
`fanfarria`, y la voz de largada de Cometa. Rugidos de los dinos y relinchos del pony propios.

## 7. Corredores y temas por hermano [PO: Maxi con dinos; temas por hermano]

| Hermano | Corredor | Obstáculos | Aéreos | Coleccionables | Meta |
|---|---|---|---|---|---|
| Maxi | **dinosaurio** (T-rex, spinosaurio o carnotauro, a elegir por zona en HE-D6) | arbustos, montoncitos de hojas, charquitos, troncos bajos de goma (todo **blandito**) | — | huevitos de dino | el volcán, que **erupciona confeti** de colores |
| Nicole | **pony o jirafa** (§16, pregunta 2) | troncos, piedras redondas, charcos, cerquitas de flores | pajaritos y globos | manzanitas y corazones | el establo |
| Sofía | **Toby** (su animal favorito son los perritos) | troncos, piedras, charcos, hongos gigantes, cajas de exploración | pajaritos, globos, cometas de papel | huesitos | la carpa de Toby |

El motor solo recibe sprites y cajas; el tema es contenido.

## 8. Escala Semilla / Brote / Estrella

### 8.1 Velocidades y aviso

**Tiempo de aviso** = lo que tarda un obstáculo desde el borde derecho hasta el corredor:
`(1320 − 220) / velocidad`. Chrome da ~1,5 s al inicio y ~0,7 s al final a un adulto.

| Parámetro | Maxi · Semilla | Nicole · Brote (z1 → z5) | Sofía · Estrella (z1 → z5) |
|---|---|---|---|
| `velocidad` inicial (px/s) | 240 (aviso ~4,6 s) | 400 → 450 (aviso 2,75 → 2,45 s) | 560 → 620 (aviso 1,96 → 1,77 s) |
| `velocidad_max` (px/s) | 240 (no acelera) | 620 → 700 (aviso 1,77 → 1,57 s) | 1000 → 1100 (aviso 1,10 → 1,00 s) |
| `segundos_a_max` | — | 120 | 120 → 100 |
| `duracion_salto_s` / `altura_salto` (px) | 0,90 / 240 | 0,80 / 210 | 0,62 / 185 |
| `impulso_s` | 0,06 (+ imantado hasta 0,5) | 0,05 | 0,04 |
| Inicio sin obstáculos | 3 s | 3 s | 2,5 s |
| `hueco_min_s` (entre obstáculos, a cualquier velocidad) | 3,5 | 1,7 → 1,4 | 1,2 → 0,95 |
| `hueco_max` | 1,5 × mínimo [Ref] | 1,5 × mínimo | 1,5 × mínimo |
| Grupos (`grupo_max`) | 1 | 1 (z1-z2) → 2 (z3-z5) | 2 (z1-z3) → 3 (z4-z5) |
| Aéreos | no | z3-z4: solo **altos**; z5: altos y **bajos** | desde los 40 s (z1-z2); z3+: altos y bajos desde el inicio |
| Burbuja | no hace falta | empieza con 1; otra cada ~25 s de carrera | empieza sin; una cada ~40 s (z1-z3) → ~55 s (z4-z5) |
| Meta (s de carrera) | 60 | 75 → 95 | 90 → 120 |
| Tramo del récord | no | hasta 45 s | hasta 90 s |
| Banderita a la mitad | — | sí (§10.3) | no |
| `salto_variable` | no | no | no (z1-z3) → opcional (z4-z5) |

**Por qué estos números** [Propuesta]: el tiempo de reacción visual simple de un niño de 8 años es ~1,3 veces
el de un adulto y el de uno de 5, ~1,7-1,8 veces (con más variación). Sofía arranca con 1,3 × el aviso de
Chrome (1,5 × 1,3 ≈ 1,96 s) y termina cerca del aviso inicial de Chrome para adultos (~1,0 s): reto real.
Nicole arranca con ~1,8 × y nunca baja de ~1,6 s. **Ventana de salto** (cuánto margen hay para tocar; supone un corredor de ~100 px de ancho y obstáculos de 90 px, o un grupo de 2 de 220 px):
Nicole al inicio ≈ (0,80 × 400 − 0,7 × 90 − 0,6 × 100) / 400 ≈ **0,49 s**; Sofía a la máxima ≈ (0,62 × 1000 −
0,7 × 220 − 0,6 × 95) / 1000 ≈ **0,41 s** con un grupo de 2. Son ventanas exigentes pero justas. **Todo es
provisional**: lo fija `disenador-niveles` con el jugador simulado de la maqueta.

### 8.2 Reparto de obstáculos (reglas de Chrome)

- Hueco en segundos entre `hueco_min_s` y `hueco_max` (uniforme), convertido a px con la velocidad del momento:
  así **el hueco en tiempo nunca baja** del mínimo aunque se acelere [Ref].
- Nunca más de 2 obstáculos del mismo tipo seguidos [Ref].
- Un aéreo nunca sale pegado a un grupo (mínimo 1,5 × `hueco_min_s` antes y después).
- Los coleccionables nunca quedan sobre un obstáculo ni donde agarrarlos obligue a chocar.

### 8.3 Aéreos: saltar o no saltar

- **Bajo** (a la altura del pecho): **hay que saltarlo**, como un obstáculo de suelo.
- **Alto** (a la altura de la cabeza en el aire): **pasa por arriba si no saltas**. Si saltas cuando está
  encima, chocas. Es el reto de inhibición de Chrome (el pterodáctilo) sin agacharse.
- La primera vez que aparece un alto, va solo, despacio, con un pajarito que saluda: así se entiende que se
  puede seguir de largo.

## 9. Puntaje, estrellitas y récord

### 9.1 Puntaje (Brote y Estrella)

| Evento | Puntos |
|---|---|
| Correr | 10 puntos por segundo × (velocidad actual / velocidad inicial) [Ref: el puntaje sube más rápido cuanto más rápido corres] |
| Coleccionable | +25 |
| Racha de 5 saltos limpios | +50 |
| Llegar a la meta | +200 |
| Llegar al final del sendero (tramo del récord) | +300 |

**Saltos limpios**: obstáculos pasados sin choque (con o sin burbuja). Un choque con burbuja corta la racha.

### 9.2 Estrellitas

- **Nicole**: 1-3 por puntaje (`umbrales_puntaje`, p50 y p80 de la jugadora simulada), sin huecos vacíos.
- **Sofía**: 1-3 por puntaje (`umbrales_puntaje`); tras una derrota, máximo 2. **Sin pistas con costo**: en un
  juego de reflejos no hay "pista"; su ayuda es el regalo (§10.3).
- **Maxi**: sin puntaje.

### 9.3 El récord, en el mundo [Propuesta]

- **Récord personal** por estación y hermano (`registrar_record`), en la barra de `barra_record.gd`.
- Además, **una banderita con la cara del hermano clavada en el sendero** en el punto donde terminó su mejor
  carrera (Chrome muestra "HI"; esto es lo mismo, pero sin leer). Al pasarla: la banderita salta, confeti chico
  y "¡récord!", sin pausar. Solo la del hermano que juega: nunca la de otro.
- Sin récord previo, no hay banderita, y al final suena "¡tu primer récord!".

## 10. El fallo

### 10.1 Semilla: el fallo no existe

- Los obstáculos son **blanditos**: si el dino no salta, **los atraviesa** con un "¡crunch!" de hojas que
  vuelan, una risita y sin frenar (como pasar por un montón de hojas secas en el patio). **También es
  divertido**: no hay "mal".
- Saltar sobre un obstáculo da una estrella, un rugido y un "¡siiii!" (el grito real de Maxi, GDD §2).
- Siempre llega a la meta a los 60 s. El volcán de confeti lo espera.
- Si no toca nada durante 8 s, el dino lo mira y ruge bajito; a los 15 s, salta solo el siguiente obstáculo
  (para mostrarle que se puede).

### 10.2 La burbuja (Brote y Estrella)

- La burbuja es el casco de Toby en grande: una esfera de vidrio alrededor del corredor.
- **Chocar con burbuja**: la burbuja revienta con "¡plop!" y gotitas, el corredor parpadea 1 s (no choca con
  nada en ese segundo) y sigue. No es derrota.
- **Nueva burbuja**: flota como coleccionable, cada `burbuja_cada_s`; si ya se tiene una, no aparece (no se
  acumulan).

### 10.3 Derrota-gag: "¡Al barro!"

- Chocar **sin burbuja antes de la meta** → el corredor tropieza, **rueda como pelota** tres veces, cae sentado
  en un charco de barro con un "¡splosh!" y se **sacude como perrito**, salpicando gotitas de barro **sobre la
  pantalla** (caen por el vidrio y se limpian solas en 1 s). Los pajaritos se ríen; Toby (si no es el
  corredor) se tapa la boca de risa. 2,5 s.
- Cartel con el puntaje, la banderita del récord y la flecha circular grande; **tocar en cualquier parte del
  cartel** reintenta. El reintento empieza en 1 toque, con la largada corta (sin la voz).
- **Nicole: banderita a la mitad** [Propuesta]: si pasó la mitad del camino, reintenta **desde la banderita**
  (con burbuja nueva y la velocidad de ese punto). Si no la pasó, desde el inicio.
- **Sofía**: reintenta desde el inicio, como Chrome. **Tras 2 derrotas seguidas**, Toby le regala "¡una
  burbuja de la suerte!": la carrera siguiente empieza con burbuja y con la banderita a la mitad.
- **Tras 3 derrotas**, Toby propone descansar, sin obligar.
- **Cero progreso perdido**: nada guardado se toca; el récord solo puede subir.

## 11. Esquema JSON del nivel

`datos/niveles/animalia/<zona>/runner_<perfil>.json`

```jsonc
{
  "id_nivel": "animalia_z1_runner_estrella",
  "motor": "runner",
  "perfil": "estrella",
  "planeta": "animalia", "zona": "zona1_...",
  "fondo": { "capas": ["res://…/lejos.png", "res://…/medio.png", "res://…/sendero.png"],
             "parallax": [0.2, 0.5, 1.0], "atardecer_en": 0.7 },
  "corredor": { "id": "toby", "sprites": "res://…", "alto": 150,
                "caja": [0.6, 0.75], "sonido_salto": "sfx/runner/toby_salto.ogg" },
  "obstaculos": [
    { "id": "tronco", "sprite": "res://…", "tamano": [90, 70], "tipo": "suelo", "blando": false },
    { "id": "pajarito_alto", "sprite": "res://…", "tamano": [80, 60], "tipo": "aereo_alto", "altura": 260 },
    { "id": "pajarito_bajo", "sprite": "res://…", "tamano": [80, 60], "tipo": "aereo_bajo", "altura": 110 }
  ],
  "caja_obstaculo": [0.7, 0.8],
  "coleccionables": { "id": "huesito", "sprite": "res://…", "puntos": 25, "cada_s": [3, 6] },
  "velocidad": 560, "velocidad_max": 1000, "segundos_a_max": 120,
  "inicio_libre_s": 2.5,
  "salto": { "duracion_s": 0.62, "altura": 185, "impulso_s": 0.04,
             "imantado_s": 0, "amable_px": 0, "en_cola_ms": 150,
             "variable": null },                  // { "extra": 0.35, "desde_s": 0.12, "tope_s": 0.25 }
  "huecos": { "min_s": 1.2, "factor_max": 1.5, "grupo_max": 2, "repetidos_max": 2 },
  "aereos": { "desde_s": 40, "tipos": ["aereo_alto", "aereo_bajo"], "p": 0.2 },   // null = sin aéreos
  "obstaculos_blandos": false,             // true en Semilla: se atraviesan
  "burbuja": { "inicial": false, "cada_s": 40, "invulnerable_s": 1.0 },         // null = sin burbuja
  "meta_s": 90,                            // segundos de carrera hasta la meta
  "tramo_record_s": 90,                    // null = termina en la meta
  "banderita_mitad": false,
  "regalo_tras_derrotas": 2,
  "puntos": { "por_segundo": 10, "racha_saltos": 5, "racha": 50, "meta": 200, "final": 300 },
  "hito_cada": 100,
  "umbrales_puntaje": { "dos": 1500, "tres": 2200 },
  "ayuda_idle_s": null,                    // Semilla: [8, 15]
  "lineas_voz": {
    "intro": "…", "largada": "…", "meta": ["…"], "sigue_record": "…", "final_sendero": "…",
    "derrota_gag": "…", "regalo": "…", "descansar": "…", "record": "…", "primer_record": "…",
    "aereo_presenta": "…"
  }
}
```

- Validación al cargar: el hueco mínimo en tiempo debe ser ≥ `duracion_salto_s` + 0,3 s (siempre se puede
  aterrizar y volver a saltar); con `grupo_max`, el ancho del grupo debe caber en la ventana de salto a la
  velocidad máxima (si no, `push_warning` y se baja el grupo).

## 12. Contrato con el núcleo y con el modo equipo

### 12.1 Solitario

- `MotorRunner extends MinijuegoBase`. **`asegurar_victoria()` en el instante de cruzar la meta**, antes del
  confeti y del tramo del récord. El récord se registra al terminar el tramo del récord.
- `registrar_record`, `obtener_record` (también para clavar la banderita en el mundo).
- `presentacion_vista("aereo_alto")` y `("burbuja")` para las presentaciones de una sola vez.
- Señales de `LogicaRunner`: `salto()`, `aterrizo()`, `paso_obstaculo(id, limpio)`, `choco(id, con_burbuja)`,
  `coleccionable(id)`, `hito(n)`, `atardecer()`, `meta()`, `paso_record()`, `fin_carrera(puntaje, motivo)`.

### 12.2 Modo equipo: la carrera de postas

- **Una sola carrera** con una meta compartida; **cada turno es un tramo** y se pasa la posta (un huesito
  dorado) al corredor del siguiente hermano: **el corredor cambia** con cada uno (el dino de Maxi, el pony de
  Nicole, Toby de Sofía). [Propuesta]
- **Tope por turno** (`aciertos_max_turno`): obstáculos pasados limpios — semilla 2, brote 5, estrella 8. Cada
  uno llama `notificar_acierto()`. Al `tope_alcanzado`, el corredor frena y entrega la posta; cuando está
  quieto, el motor llama `confirmar_turno_estable()`.
- **Fallo que corta el turno**: choque sin burbuja → tropiezo y `terminar_turno(true)` al quedar sentado. En
  equipo **no hay burbuja** para Brote (el turno es corto) [Propuesta].
- **Maxi**: su capa de Semilla (obstáculos blandos y salto imantado). Con `semilla_auto_s`,
  `jugada_automatica_pedida` hace saltar al dino solo el siguiente obstáculo (cuenta como paso limpio).
- `aplicar_perfil_turno(perfil)`: velocidad, salto, huecos, aéreos y corredor según quien juega. **Durante el
  pase el mundo se congela** (nada corre).
- **Derrota del equipo**: `gag_derrota_aspirar` levanta los obstáculos y coleccionables de la pantalla hacia la
  mochila-torre; `gag_derrota_devolver` los estornuda de vuelta al sendero (más adelante, con aire para
  arrancar); `contar_logro_equipo()` = tramos completos de la carrera.
- `ancla_meta_turno()`: arriba a la izquierda del sendero (x 60, y 470).
- La **distancia del equipo** se ve en el "camino a la meta" con las caras de los tres. Sin puntaje en equipo.

## 13. Maqueta HTML jugable (HE-110): `docs/maquetas/runner-v1.html`

Debe demostrar:

1. Los **3 perfiles** y la **zona** elegibles, con las velocidades, saltos y huecos de §8.1.
2. El **salto como curva** con impulso, estiramiento y aterrizaje; el salto en cola de 150 ms; el salto
   imantado de Maxi y el salto amable de Nicole (con un interruptor para comparar con y sin).
3. Obstáculos de suelo, grupos, aéreos altos y bajos, coleccionables y la burbuja.
4. Atardecer y noche, hitos cada 100, la meta y el tramo del récord, y la **banderita del récord en el sendero**
   (con `localStorage`).
5. La derrota-gag "¡al barro!" con el barro en la pantalla, el reintento de un toque y la banderita a la mitad
   de Nicole.
6. Un **jugador simulado** por edad (tiempo de reacción con variación) que corra 1.000 carreras y entregue el %
   que llega a la meta, el % que choca en aéreos altos y los percentiles de puntaje, para fijar huecos, metas y
   umbrales.
7. Un botón "ver cajas de choque".

## 14. Riesgos de usabilidad (para `experto-ux-parvulo`)

| # | Riesgo | Propuesta / qué mirar |
|---|---|---|
| R1 | **El toque no se siente respondido** en el aire o justo antes de aterrizar | Salto en cola de 150 ms y guiño en el aire |
| R2 | **Maxi toca a ráfagas** sin mirar | No pasa nada malo: cada toque salta o hace voltereta, y lo blando se atraviesa |
| R3 | **"No saltar" el aéreo alto** le cuesta a Nicole (inhibición a los 5 años) | Recién desde z3, presentado solo y despacio; medir en el simulador y el playtest |
| R4 | **Frustración de Sofía** con la velocidad máxima de z5 (~1,0 s de aviso) | Burbujas, regalo tras 2 derrotas, meta antes de la máxima; la máxima vive sobre todo en el tramo del récord |
| R5 | **Barro en la pantalla** molesta o da asco | Gotitas caricaturescas, 1 s, se van solas; desactivable con "menos movimiento" |
| R6 | **La mano tapa al corredor** si toca cerca de él | Se puede tocar **en cualquier parte**: la voz de largada lo dice ("¡toca donde quieras para saltar!") |
| R7 | **Salto variable** (mantener) = gesto nuevo para Sofía | Opcional y solo z4+; ver §16, pregunta 3 |
| R8 | **Rendimiento** en tablet (parallax + partículas a 60 fps) | Presupuesto de partículas por pantalla; probar en la tablet de P3 |
| R9 | **Fotosensibilidad** con estrellas fugaces y confeti | Sin destellos de más de 3 por segundo |

## 15. Qué debe probar el arnés (`herramientas/qa_test_runner.gd`)

1. Generador con semilla: en 3.000 carreras por perfil, el hueco en tiempo nunca baja de `min_s`, nunca más de 2
   iguales seguidos, aéreos nunca pegados a grupos, coleccionables nunca sobre obstáculos.
2. Salto: curva exacta, salto en cola, sin doble salto, imantado de Semilla (todo toque hasta 1,2 s antes pasa
   limpio), amable de Brote.
3. Cajas de choque al 70/80 % y 60/75 %; aéreo alto: sin saltar pasa, saltando choca.
4. Burbuja: revienta, 1 s invulnerable, no se acumula, aparece cada `cada_s`.
5. Semilla: lo blando se atraviesa sin frenar; meta siempre a los 60 s; ayudas a los 8 y 15 s.
6. Meta: `asegurar_victoria` al cruzarla; tramo del récord; chocar en el tramo no es derrota.
7. Derrota y reintento: banderita a la mitad de Nicole, regalo de Sofía tras 2, el récord nunca baja.
8. Equipo: tope por perfil, posta con cambio de corredor, choque → `terminar_turno(true)`, mundo congelado en el
   pase, jugada automática de Maxi.
9. Escena: tocar los botones no hace saltar; tocar cualquier otro punto sí.

## 16. Preguntas abiertas para el PO

1. **[Abierta] Meta + tramo del récord**: ¿de acuerdo con que la estación se gane al llegar a la meta y después
   se siga corriendo por el récord (Chrome es infinito)? ¿O prefieren carreras cerradas, sin tramo extra?
2. **[Abierta] Corredor de Nicole**: ¿pony o jirafa? (o uno por zona).
3. **[Abierta] Salto variable para Sofía** (mantener el dedo = salto más alto, como en Chrome): suma reto, pero
   es un gesto más. Propongo probarlo en la maqueta y decidir con ella.
4. **[Abierta] Nicole con banderita a la mitad**: ¿les parece bien que no tenga que repetir la carrera entera?
5. **[Abierta] GDD §4**: agregar "Carrera de Toby" como 4.º juego de Animalia cuando lo aprueben.
