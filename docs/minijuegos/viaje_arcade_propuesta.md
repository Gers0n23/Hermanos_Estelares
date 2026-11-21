# Viaje estelar arcade v2: diagnóstico y propuesta

> **Estado**: propuesta de `dev-godot` (21-Nov-2026), **decidida por el PO el mismo día** (ver §7.1, que
> manda sobre el resto del documento donde difiera). Aún no se implementó nada: queda lista para
> desarrollarse en otra sesión. Antes de implementar, `disenador-mecanicas` la convierte en ficha (`docs/fichas/viaje-arcade.md`,
> patrón HE-D4), `guionista` valida enemigos y jefes, y `experto-ux-parvulo` revisa el perfil de Maxi.
> El tablero lo actualiza `scrum-master`.

Pedido del PO (textual, resumido): las cinemáticas Blender "se ven francamente espectaculares", pero el
minijuego pixel del viaje no cuadra con ese estilo; la mecánica le gusta, pero "no era tan satisfactorio
como un juego de arcade normal"; con el 3D disponible se puede hacer un juego mejor; **se tiene que poder
perder** (Maxi con más facilidad o más vidas), porque sin reto se aburren: "deben poder frustrarse lo justo".

---

## 1. Diagnóstico del minijuego actual

### 1.1 Archivos

| Archivo | Rol |
|---|---|
| `escenas/nucleo/viaje_estelar.tscn` | Escena mínima (un Node2D con script) |
| `scripts/nucleo/viaje_estelar.gd` | Todo el juego (1338 líneas): despegue, viaje arcade, avería, aterrizaje, HUD y burbuja-recuerdo, dibujado con `_draw()` a 320×180 y escalado ×4 |
| `scripts/nucleo/arte_pixel.gd` | Arte pixel por grillas (nave, rocas, latas, Cometa, mundos, cielos y suelos) |
| `scripts/nucleo/mapa_estelar.gd` (`_viajar_a`, línea 579) | Lo lanza al tocar otro planeta; fija `planeta_origen`/`planeta_destino` y conecta `completado` a `Progreso.registrar_viaje` y al cambio de escena |
| `scripts/autoloads/progreso.gd` (`registrar_viaje`, línea 618) | Suma destellos al destino y mueve la nave |
| `assets/audio/sfx/viaje/*.ogg`, `assets/audio/musica/viaje_estelar.ogg` | 11 SFX y música chiptune sintetizados (`herramientas/componer_sfx_viaje.py`, `componer_chiptune.py`) |
| `herramientas/qa_test_viaje_arcade.gd` (+ `qa_test_mapa_planeta`, `qa_test_recuerdos`, `qa_test_partida_viaje`, `qa_test_mapa_animalia`) | Arneses que dependen de su API interna (`_nave`, `_balas`, `_obstaculos`, `_vidas`...) |

No es un motor (`minijuego_base.gd`): es pantalla del núcleo que hace de puerta entre planetas. Sus
parámetros viven en la constante `NIVELES` del script, no en `datos/`.

### 1.2 Mecánica y escala actual (constante `NIVELES`)

Shooter horizontal tipo Galaga: la nave va hacia el dedo, dispara rayitos, rompe rocas, satélites y
escuadrillas de latas o tuercas en onda; hay triple disparo, corazones y un meteorito gigante en los
últimos 15 s. El trayecto dura un tiempo fijo y siempre se llega.

| | Semilla (Maxi) | Brote (Nicole) | Estrella (Sofía) |
|---|---|---|---|
| Duración del tramo jugable | 35 s | 45 s | 55 s |
| Velocidad de avance (px lógicos 1280×720) | ~104 px/s | ~136 px/s | ~176 px/s |
| Obstáculo cada | 2,6-3,6 s | 1,7-2,5 s | 1,05-1,6 s |
| Vidas | ninguna (las rocas se apartan solas) | 5 + corazones | 3 + corazones, suelta 1 destello |
| Disparo | automático | con el dedo apoyado | con el dedo apoyado |
| Meteorito gigante | 10 rayitos, no ataca | 16, lanza roca cada 3,6 s | 26, roca cada 2,2 s |
| Al quedarse sin vidas | — | avería cómica → sigue desde la banderita del tercio, con corazón extra escondido desde la 2.ª avería | igual |

A eso se suman ~20 s **no jugables** en cada viaje: cuenta de 3 luces (2,8 s), subida (5,2 s), llegada
(3,2 s), bajada (5,0 s) y fiesta (3,4 s).

### 1.3 Por qué no se siente "arcade de verdad"

1. **Control flotante y tapado por el dedo.** La nave persigue al dedo con `lerp` a tasa 4/s
   (`_mover_nave`): tarda ~250 ms en recorrer el 63 % del camino. Encima, se coloca justo debajo del dedo
   (`_objetivo = p - 20`), así que el dedo tapa la nave. Los shooters móviles que funcionan (Sky Force,
   1945 Air Force) usan **arrastre relativo 1:1**: la nave se mueve lo mismo que el dedo, desplazada,
   sin retraso. El teclado también pasa por el mismo `lerp`.
2. **Los enemigos no amenazan.** Todo viaja en línea recta hacia la izquierda; nadie dispara salvo el
   jefe (una roca cada 2-3,6 s); las escuadrillas solo ondulan y nunca se lanzan sobre la nave (el "dive"
   que hace famoso a Galaga). No hay patrones que leer ni esquivar.
3. **Disparar no importa.** El avance es por tiempo: se llega igual sin romper nada. Romper solo da
   destellos al azar (25-50 %). No hay puntaje, multiplicador, récord ni pantalla de resultados.
4. **Impactos sin peso.** Rayito de 5×3 px (a escala ×4), tinte rojizo de 0,12 s, sin hit-stop, sin
   retroceso (salvo 2 px del jefe), temblor de ±2 px solo en eventos grandes, un único sonido de disparo
   sin variación de tono. Las chispas son cuadraditos de 3 px.
5. **Curva plana.** La frecuencia de aparición es la misma del primer al último segundo; no hay oleadas,
   sectores ni subida de ritmo. El jefe es un meteorito que sube y baja y, si no se rompe, se va.
6. **Perder no existe.** Maxi no tiene vidas; Nicole tiene 5 corazones, corazones que caen, checkpoint
   cada tercio y vida escondida extra; no hay game over. Esto ya **contradice el GDD §6 regla 11**
   (HE-124, 05-Nov: todo minijuego con objetivo admite derrota en los tres perfiles) y el pedido nuevo.
7. **Choques poco justos.** Cometa vuela delante de la nave y tiene su propia caja de choque
   (`_centro_cometa`, +43 px, -11 px): se puede chocar con algo que "no tocó la nave".
8. **Mucho tiempo sin jugar.** ~20 s de despegue y aterrizaje no interactivos en cada viaje diluyen
   una partida de 35-55 s.
9. **Estilo.** Pixel art a 320×180 junto a cinemáticas 3D pintadas a 1280×720: dos juegos distintos.

Lo que **sí** funciona y se conserva: moverse libre adelante y atrás, disparar a basura y meteoritos,
escuadrillas con premio por fila completa, triple disparo, rocas que se parten (Asteroids), jefe al final,
avería cómica en pedacitos con Cometa que la rearma, burbuja-recuerdo (HE-47) y que origen y destino
cambien el viaje.

---

## 2. Propuesta de rediseño: "shmup" corto de verdad

Se mantiene la mecánica que le gusta al PO (nave libre que dispara de izquierda a derecha) y se le pone
la estructura de un arcade. **Una sola referencia por mecánica** (regla de oro 3): el shooter es exclusivo
del viaje; ningún otro minijuego lo usa.

### 2.1 Estructura de una partida (Galaga + Gradius)

`despegue (video) → sector 1 → sector 2 → [sector 3] → JEFE → resultados → llegada (video)`

- **Sectores por oleadas**, no por reloj: cada sector es una lista de oleadas declaradas en datos
  (formaciones que entran en curva, se acomodan y se lanzan en picada, como Galaga; lluvias de meteoritos
  con hueco; torretas). El sector termina cuando pasa su última oleada. La barra de trayecto avanza por
  sector, con banderita al cerrar cada uno.
- **Jefe por ruta** con 2 fases y patrones aprendibles (R-Type, Gradius): telegrafía cada ataque (brillo
  y sonido) y tiene un punto débil iluminado. La barra de vida del jefe se queda (sin texto).
- **Pantalla de resultados sin texto** (Galaga "results"): las estrellitas y destellos suben contando con
  "tilines", aparece el puntaje y, si lo es, la celebración de **¡récord!** con Cometa bailando.

### 2.2 Cambios con su arcade de referencia

| Cambio | Referencia | Detalle |
|---|---|---|
| Arrastre relativo 1:1, sin retraso; Maxi mantiene "la nave va al dedo", más rápida (tasa 14/s) y desplazada 120 px arriba del dedo | Sky Force, 1945 Air Force (móvil) | Nicole y Sofía: la nave copia el desplazamiento del dedo desde donde lo apoyaron; el dedo nunca la tapa. Teclado: velocidad directa 700 px/s. `Input.use_accumulated_input = false` para precisión |
| Disparo automático con el dedo apoyado (todos); Maxi siempre | shmups móviles | Cadencia 6-8 tiros/s, balas grandes con estela y fogonazo |
| Formaciones que entran en curva y se lanzan en picada | **Galaga** | La fila completa da bonus de puntaje y 3 destellos (ya existe la idea) |
| Rocas grandes que se parten en 2 y luego en 4 | **Asteroids** | Ya existe a medias; se agrega el segundo corte en Estrella |
| Nivel de arma 1-3 que sube con cápsulas y baja **un** nivel al recibir golpe | Raiden, Sky Force | Más justo que perderlo todo (Gradius clásico) |
| Escudo-burbuja que absorbe 1 golpe | Gradius ("force field") | Lo regala Cometa tras derrotas (§4) |
| 2 mini-Cometas ayudantes que copian el disparo por 12 s | Gradius ("options") | Lo más tierno del rediseño: el power-up es Cometa |
| Imán de destellos por 10 s | Jetpack Joyride, Sky Force | — |
| "Supernova": cápsula rara que al tomarla limpia la pantalla | 1942 / Defender (bomba) | Se activa al tomarla: **sin segundo botón** (GDD §6 regla 4) |
| Puntaje + **multiplicador** que sube con destrucciones seguidas sin recibir golpe | Geometry Wars, Sky Force | Tope y castigo por perfil (§4) |
| Vida extra por puntaje | **Galaga** (20.000 / 70.000) | Ver §4 |
| Récord personal por hermano, celebrado al batirlo | todos los arcades | Persistido en `Progreso` (§5) |
| Jefe con fases, telegrafiado y con punto débil | R-Type, Gradius | Uno por ruta, temático del planeta de destino |
| "¡Otra vez!" que sigue desde el sector, con puntaje a 0 | **Continue** de arcade | El récord vale por "crédito", como en el arcade. **Sin cuenta regresiva** (GDD §6.11 prohíbe "conteos que apuren") |

### 2.3 Game feel (lo que hoy falta)

Referencias: charla "The Art of Screenshake" (Jan Willem Nijman, Vlambeer) y "Juicing your cameras"
(Squirrel Eiserloh, GDC).

- **Hit-stop** de 40-60 ms al romper algo grande, al golpear al jefe en su punto débil y al recibir golpe.
- **Temblor de cámara por "trauma"** (se acumula y decae; amplitud ∝ trauma²) con ruido, no con seno.
  Opción de reducirlo en Ajustes (zona de papás).
- **Destello blanco** de 1-2 cuadros en todo enemigo golpeado y **retroceso** pequeño.
- Partículas: chispas, confeti de colores, tuercas que rebotan y anillo de onda; restos que quedan medio
  segundo (sensación de permanencia).
- Nave con **alabeo 3D** al subir y bajar, fogonazo en cada disparo y llamas que crecen al avanzar.
- Sonido: variación de tono ±8 % en cada disparo e impacto, capas (golpe + crujido + tilín), y un tilín
  que **sube por la escala** con el multiplicador (Peggle, Tetris Effect).
- Números de puntaje pequeños que flotan y el "×3" del multiplicador con color. Son números, no
  instrucciones: no rompen la regla de "sin texto para navegar".
- Recoger destellos con un imán corto (60 px), para no tener que "tocar exacto".
- Golpes recibidos: la nave hace "boing", Cometa se marea (ya existe) y el corazón salta del HUD. Nada de
  rojo, zumbidos ni caras tristes (GDD §6.11).

### 2.4 Enemigos y jefes (para validar con `guionista`)

Nada violento: lo que se rompe "se desarma" en confeti y tuercas.

- **Meteoritos dormilones** (Kenney `meteor`, `meteor_detailed`, `rock_crystals*`), que giran en 3D.
- **Basura espacial** (Kenney `satelliteDish*`, `barrel`, partes de `rocket_*`).
- **Recolectores del Coleccionauta**: navecitas aspiradora (Kenney `craft_speederA-D` recoloreadas,
  o Quaternius) que vuelan en formación Galaga y se lanzan a "coleccionar" a la nave. Conecta el viaje
  con la historia.
- **Torretas-boya** que disparan **burbujas de jabón** (proyectiles enemigos: chocar es "plop").
- **Jefes por ruta**, temáticos del destino: Tierra → Arcoíris, el Meteorito Dormilón (el actual, con 2
  fases: bosteza y lanza piedritas; despierta y rueda); hacia Animalia, una aspiradora gigante
  recolectora; hacia Melodía, un tocadiscos-ovni que dispara notas en abanico; etc. En la ruta final
  (Corazón → planeta del Coleccionauta), **la nave del Coleccionauta** (el modelo de HE-131) huye y suelta
  objetos de su colección: no se destruye, se le hacen caer las bolsas (en su planeta "no hay batalla",
  GDD §1). Los diseña `disenador-mecanicas` como datos de un único "motor de jefe".

---

## 3. Técnica 3D: comparación y recomendación

### 3.1 Opciones

| Criterio | **a. 3D real en Godot** (Node3D, glTF de Kenney y nave exportada, cámara fija, sombreado toon) | **b. Sprites prerenderizados en Blender** (2D en Godot) |
|---|---|---|
| Parecido con las cinemáticas | ~85-90 %: mismos modelos, colores, sombra lila de 2 tonos y contorno `#4B3247`. **Falta el filtro de pincel Kuwahara** del compositor (`nave_comun.compositor`), demasiado caro a pantalla completa en el renderer Mobile; se imita con el mismo "temblor" de ruido en el umbral que ya usa `toon()` | ~100 %: mismo pipeline, incluido el Kuwahara |
| Lo que gana el juego | Meteoritos que giran en 3D de verdad, alabeo de la nave, profundidad y paralaje, cámara que tiembla y se inclina, **nave con las piezas instaladas** que el niño ya ganó (cada pieza es un glb que se prende según `Progreso`) | Giro solo en el plano; alabeo en 5-9 cuadros; las piezas de la nave requieren capas de sprites por ángulo |
| Iteración | Rápida: cambiar tamaño, color o forma es código o import | Lenta: cada cambio es volver a renderizar (y hoy la CPU está ocupada por las cinemáticas) |
| Rendimiento en tablet | Riesgo medio: Vulkan Mobile; con ~60 objetos low-poly (<1.000 triángulos cada uno), MultiMesh para balas y estrellas, sin sombras dinámicas ni postproceso salvo glow, cabe con holgura en ~120 draw calls. Riesgos: tirones por compilación de shaders la primera vez y GPUs Android con drivers Vulkan flojos | Riesgo bajo: es lo que el juego ya hace |
| Peso del APK (hoy ~98 MB) | +1-3 MB (los glb del space-kit pesan 5-25 KB cada uno) | +5-15 MB de atlas (ASTC) |
| Esfuerzo | M para el spike + L para la presentación | M para el pipeline de render + M para la presentación |
| Primera vez del proyecto | Sí: hoy no hay ninguna escena 3D en el juego (solo en `herramientas/ojos.gd` y una POC) | No |

### 3.2 Recomendación: **a (3D real), en versión híbrida y con salida de emergencia**

1. **Actores en 3D real**: nave, enemigos, jefes, balas, cápsulas y partículas, con cámara en perspectiva
   de FOV bajo (~30°) en vista lateral levemente picada (2.5D tipo Sky Force/R-Type Final).
2. **Fondo prerenderizado**: estrellas, nebulosa y los planetas de origen y destino como imágenes fijas
   salidas de Blender (o el último cuadro de los videos), en una capa 2D detrás del 3D
   (`Environment.background_mode = BG_CANVAS`). Es lo que más "dice" el estilo pintado y no cuesta nada
   en tiempo de ejecución.
3. **Lógica en 2D, presentación en 3D**: toda la simulación (posiciones, choques circulares, oleadas,
   vidas, puntaje) vive en un script puro `logica_viaje.gd` con coordenadas de un plano de 1280×720; los
   nodos 3D solo la dibujan. Así los arneses siguen siendo deterministas y headless, y **si el spike falla
   en el teléfono, se cambia la capa visual por sprites (opción b) sin rehacer el juego**.
4. **Material toon en Godot**: `assets/shaders/toon_pintado.gdshader` replica `toon()` de
   `nave_comun.py`: N·L contra una luz fija + ruido por posición de objeto en el umbral (0,47-0,53) →
   mezcla entre el color y el color × `#A596D6`; brillo opcional. Contorno con un `next_pass` de casco
   invertido (`cull_front`, vértices empujados por la normal) en `#4B3247`, igual que el `SOLIDIFY` de
   Blender. Unshaded y sin sombras dinámicas: barato en Mobile.
5. **Puerta del spike** (tarjeta V1 del §6): escena de prueba en el teléfono de pruebas (Samsung,
   `RFCX304MYVM`) con 40 enemigos, 60 balas y partículas: **≥ 55 fps sostenidos, sin tirones al aparecer
   cada tipo**, carga < 2 s. Si no pasa, opción b.

### 3.3 Exportar la nave de `nave_comun.py` a glTF

Script nuevo `poc/cinematica_blender/exportar_nave_glb.py` (Blender sin interfaz; **no es render**, tarda
segundos, pero se corre cuando termine el render en curso):

- `construir_nave(completa=False)` para la nave base y `pieza(ident, padre)` para cada una de las 6
  piezas (`PIEZAS`), cada una a su glb: `assets/modelos/nave/nave_base.glb` y `pieza_<id>.glb`.
- Los materiales `toon` son redes de emisión que el exportador glTF no entiende: el script lee el color
  del nodo `"color"` (o el atributo de vértice) y los reemplaza por un Principled con ese Base Color y
  el mismo nombre. Los que usan atributo de color se exportan como `COLOR_0`.
- Quita el modificador `"contorno"` (el contorno lo hace Godot), aplica el resto (`export_apply=True`),
  triangula, Y arriba.
- En Godot, un import script (`herramientas/importar_toon.gd`, `EditorScenePostImport`) cambia cada
  material por `toon_pintado` con su color. El mismo import sirve para los modelos de Kenney.
- Las llamas de la nave se hacen en Godot (partículas + shader), no se exportan.
- **Depende de la decisión abierta del PO** sobre la nave terminada (guía de estilo frente a
  `assets/sprites/nave/nave_estrella.png`): se exporta la que gane.

### 3.4 Empalme con los videos de viaje (HE-130) y presentaciones (HE-128/129)

Los videos B4 ya tienen un corte a blanco (`F_CORTE` en `despegue_viaje.py`: cuadro 112, o 150 con el
puente de Arcoíris) y terminan en el primer cuadro de la presentación del destino. El minijuego se mete
justo en el tramo espacial:

```text
[video] despegue_<origen> (cuadros 1..F_CORTE, termina en blanco)    ← recorte con ffmpeg del mp4 existente, sin Blender
   ↓ blanco
[juego] espacio con el planeta de origen alejándose (imagen del video) → sectores → jefe → resultados
   ↓ el planeta de destino crece, fundido a blanco
[video] presentacion_<destino> (empieza con la nave en órbita)       ← B3, ya renderizado
   ↓
mapa del planeta
```

- El tramo espacial del video B4 (de `F_CORTE` a `F_FIN`) no se usa en el juego; queda para el modo
  "solo ver" o para la historia si se salta el juego.
- El fondo del juego copia la paleta del espacio de `planeta_comun.cielo` (`#3B2F78` → `#2A2260` →
  `#17133F`) y sus estrellas amarillas de 5 puntas, en vez del `#120a2c` actual.
- **Tierra → Arcoíris no tiene video B4** (`ORDEN` empieza en Arcoíris): ese despegue sigue con la nave
  3D en Godot o con un recorte de `llegada_nave` al revés; lo decide `director-cinematicas`.
- Reproducir .ogv saltable es justo lo que construye **HE-133**: el viaje lo usa, no lo reinventa.

---

## 4. Dificultad por perfil (valores iniciales, a calibrar)

Unidades en el plano lógico de 1280×720. La nave se dibuja de ~130×85 px. Los valores de partida se
**calibran con un jugador simulado** (bot con tiempo de reacción y error de puntería por edad: ~600 ms
Maxi, ~400 ms Nicole, ~300 ms Sofía), como ya se hizo en Parejas y en Escondite, hasta la meta del GDD
§6.11: llegar al jefe y vencerlo **sin usar "¡otra vez!"** en ~90 % / ~75 % / ~60 % de los primeros
intentos.

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| Estructura | 2 sectores + mini-jefe | 3 sectores + jefe | 3 sectores + jefe de 2 fases (4 sectores desde la 3.ª ruta) |
| Duración sin morir | ~60 s | ~100 s | ~140 s |
| Vidas | **5 corazones** + escudo-burbuja al empezar cada sector | **4 corazones** | **3 corazones** |
| Recuperar vida | corazón garantizado al cerrar sector si perdió alguno | 1 corazón por sector (solo si le falta) + vida extra a 20.000 pts | sin corazones sueltos; vida extra a 30.000 y 80.000 pts (Galaga) |
| Invulnerable tras un golpe | 2,5 s | 2,0 s | 1,5 s |
| Caja de choque de la nave (radio) | 20 px | 24 px | 28 px |
| Cometa | sin caja de choque (todos los perfiles) | — | — |
| Avance de enemigos | 150 → 190 px/s | 220 → 300 px/s | 280 → 400 px/s |
| Enemigos a la vez (máximo) | 4 | 8 | 12 |
| Formaciones Galaga | 3 por sector, sin picada | 4 por sector, 1 de cada 3 se lanza en picada | 5 por sector, picadas frecuentes y en pareja |
| Proyectiles enemigos | ninguno (solo cuerpos) | burbujas lentas, 160 px/s, solo torretas y jefe | 240-300 px/s, apuntadas, abanicos de 3-5 en sector 3 y jefe |
| Aviso antes de un peligro grande | 1,5 s | 1,0 s | 0,7 s |
| Hueco en lluvias de meteoritos | 300 px | 220 px | 160 px |
| Cadencia de disparo | 8/s, automático siempre | 7/s con el dedo apoyado | 6/s con el dedo apoyado |
| Vida del jefe (disparos, arma nivel 1) | 40 | 90 | 160 |
| Multiplicador | tope ×3; un golpe no lo baja | tope ×5; un golpe lo divide por 2 | tope ×8; un golpe lo vuelve a ×1 |
| Nivel de arma al recibir golpe | no baja | baja 1 | baja 1 |
| Estrellitas al llegar | — | — | 1 = llegar; 2 = puntaje ≥ umbral de la ruta; 3 = umbral alto y sin "¡otra vez!" |

### 4.1 Cómo se pierde y cómo se reintenta

- **Se pierde** al quedarse sin corazones. Gag de ~1,5 s: la nave se desarma en pedacitos de colores y
  Cometa queda mareado (la animación actual, en 3D). Música que se "desinfla", nada de rojo ni zumbidos.
- **"¡Otra vez!"**: cartel con botón ≥ 160 px o tocar en cualquier parte; **sin cuenta regresiva**. Se
  sigue desde el **inicio del sector actual** con vidas llenas, arma en nivel 1 y **puntaje a 0** (el
  récord vale por "crédito": un récord con continues no cuenta, como en el arcade).
- **Lo ganado queda ganado** (§6.11): los destellos de los sectores cerrados se conservan; los del
  sector en curso se pierden. El puntaje del intento que terminó en derrota **sí puede ser récord**
  (en el arcade, el puntaje al morir es tu puntaje).
- **Ayudas de Cometa** según §6.11: regalo (escudo-burbuja + arma nivel 2 al reintentar) tras 2
  derrotas seguidas para Maxi y Nicole y tras 3 para Sofía; **ayuda fuerte** para Maxi tras 3
  ("Cometa al volante": imán permanente y enemigos a la mitad en ese sector, victoria asegurada);
  ofrecer descansar tras 3 (Nicole) y 4 (Sofía): volver al mapa con la nave en el planeta de origen.
- **El viaje nunca deja trabado a nadie**: los "¡otra vez!" son infinitos y desde la zona de papás se
  podrá saltar el viaje (llave de padres, como la de la partida).

---

## 5. Encaje con el núcleo y los datos

- Sigue siendo pantalla del núcleo con la misma API hacia fuera: `planeta_origen`, `planeta_destino`,
  `perfil_dificultad`, señal `completado(destellos)` y `hay_burbuja_pendiente()`; `mapa_estelar.gd` no cambia.
- **Data-driven**: `datos/viaje/perfiles.json` (la tabla del §4) y `datos/viaje/rutas/<origen>_<destino>.json`
  (sectores, oleadas, jefe y umbrales de estrellitas). Hoy todo está cableado en `NIVELES`.
- **Récord**: `Progreso` guarda `perfiles.<id>.records.viaje` (puntaje máximo global y por ruta) sin subir
  la versión, con el mismo patrón de `_completar_v3()` del 08-Nov.
- **Burbuja-recuerdo (HE-47)**: se conserva; con el juego en 3D pasa a ser una burbuja 3D que se toca o
  se choca, y el juego se pausa mientras llega el sobre-estrella (igual que hoy).
- Archivos nuevos previstos: `escenas/nucleo/viaje_estelar.tscn` (rehecha), `scripts/nucleo/viaje/logica_viaje.gd`,
  `vista_viaje_3d.gd`, `jefe_viaje.gd`, `hud_viaje.gd`; `assets/modelos/nave/*.glb`, `assets/modelos/viaje/*.glb`;
  `assets/shaders/toon_pintado.gdshader`; `herramientas/importar_toon.gd`; `herramientas/bot_viaje.gd`
  (jugador simulado). El pixel actual se archiva en `poc/viaje_pixel/` como historia.

---

## 6. Plan en tarjetas

Tamaños: S ≈ 1 sesión, M ≈ 2-3, L ≈ 4-6. Todas consumen WIP de Dev salvo V0.

| # | Tarjeta | Tamaño | Depende de | Notas |
|---|---|---|---|---|
| V0 | **Ficha** `docs/fichas/viaje-arcade.md` (`disenador-mecanicas`), enemigos y jefes por ruta (`guionista`), revisión del perfil Maxi (`experto-ux-parvulo`). Actualizar GDD §6.11 con la fila "shooter del viaje" | S | Decisiones del PO (§7) | Sin WIP de Dev |
| V1 | **Spike 3D en el teléfono**: `exportar_nave_glb.py`, `toon_pintado.gdshader` + contorno, import de 6 modelos Kenney, escena de carga con 40 enemigos, 60 balas y partículas; medir fps, tirones y carga en `RFCX304MYVM` | M | Fin del render Blender en curso (solo para exportar la nave) | **Puerta**: ≥ 55 fps o se va a la opción b |
| V2 | **Lógica nueva** `logica_viaje.gd` + datos de perfiles y de la ruta Tierra → Arcoíris: control relativo, disparo, oleadas, vidas, derrota y "¡otra vez!", puntaje, multiplicador, récord, ayudas | L | V0 | Headless; arnés nuevo que reemplaza `qa_test_viaje_arcade.gd` |
| V3 | **Presentación 3D y game feel**: vista 3D, fondo pintado, hit-stop, temblor, partículas, HUD sin texto, resultados | L | V1, V2 | Verificación con `herramientas/ojos.sh` y en el teléfono |
| V4 | **Motor de jefe por datos** + los jefes de las rutas (el Meteorito Dormilón primero) | M | V2, V3 | El jefe del Coleccionauta espera el modelo de HE-131 |
| V5 | **Audio**: SFX nuevos con variación de tono, tilín por multiplicador y música del viaje acorde al estilo nuevo | S | V3 | Kenney CC0 + `componer_*.py` |
| V6 | **Empalme con cinemáticas**: recortar los mp4 B4 en `F_CORTE` (ffmpeg, sin Blender), video de despegue → juego → presentación del destino; política primera vez / repetición | M | **HE-133** (reproducción .ogv saltable), HE-130 (videos), HE-129 | Sin HE-133, V2-V5 funcionan con el despegue/llegada en 3D |
| V7 | **Calibración y QA**: bot por edad hasta 90/75/60 %, regresiones (`qa_test_mapa_planeta`, `qa_test_recuerdos`, `qa_test_partida_viaje`, `qa_test_mapa_animalia`), auditoría UX y QA, **playtest con los tres** | M | V2-V5 | Regla de oro 6 |
| V8 | Rutas restantes (5 más): oleadas y jefe por destino | M | V4, V7 | Solo datos + modelos |

Orden sugerido: V0 ∥ V1 → V2 → V3 → V4/V5 → V7 (playtest con Tierra → Arcoíris) → V8 → V6 cuando
HE-133 esté hecha. Primer jugable en el teléfono: tras V3 (~8-10 sesiones de Dev).

### 6.1 Riesgos

| Riesgo | Mitigación |
|---|---|
| El renderer Mobile no rinde o tironea en la tablet | Spike V1 como puerta; lógica separada para caer a la opción b sin rehacer; precompilar shaders instanciando todo detrás del video de despegue |
| Look 3D en tiempo real menos "pintado" que el video | Fondo prerenderizado, mismos colores y contorno; el PO compara una captura de V1 junto a un cuadro del video antes de seguir |
| Dificultad mal calibrada (aburre o frustra) | Bot por edad + todo en `datos/`; playtest antes de las 5 rutas restantes |
| Los arneses actuales leen variables internas (`_nave`, `_balas`, `_vidas`) | Se reescriben en V2/V7 contra la API de `logica_viaje.gd` |
| WIP de Dev ya excedido (5/2 con excepción) y el viaje no está en el camino crítico del capítulo 1 | Decisión del PO sobre la prioridad (§7) |
| Viajar seguido se vuelve largo (videos + ~1-2 min de juego) | Política de repetición (§7, decisión 4) |
| Modelos CC-BY obligan a créditos | Usar solo CC0 en el viaje (Kenney, Quaternius); si entra algo CC-BY, va a la obligación de créditos ya anotada en la épica de cinemáticas |

### 6.2 Assets a descargar (preferir descargar antes que modelar)

| Asset | Fuente | Licencia | Uso |
|---|---|---|---|
| Kenney **Space Kit** 2.0 (ya bajado en `C:\tmp\descargas_kenney\space-kit`, 2,4 MB de glb) | kenney.nl | **CC0** (`License.txt` verificado) | Meteoritos, rocas con cristales, antenas, barriles, partes de cohete, naves `craft_*` para recolectores, `alien`, astronautas. Copiar a `assets/terceros/kenney/space-kit/` solo lo usado |
| Kenney **Planets** y **Simple Space** (ya en `assets/terceros/kenney/`) | kenney.nl | CC0 | Cápsulas, íconos del HUD |
| Kenney **Particle Pack** | kenney.nl | CC0 | Texturas de chispas, humo, estrellas y destellos |
| Kenney **Sci-Fi Sounds** e **Impact Sounds** | kenney.nl | CC0 | Disparos, impactos, power-ups (con variación de tono) |
| Quaternius **Ultimate Space Kit** (naves, enemigos, planetas) | quaternius.com | CC0 según el autor; **un listado de Sketchfab lo marca CC-BY: verificar en la página oficial antes de bajar** | Recolectores y jefes si los de Kenney no alcanzan |
| Nave de los hermanos | `poc/cinematica_blender/nave_comun.py` → glb propio | Propio | Nave y piezas |

Todo se registra en `assets/terceros/LICENCIAS.md`. Costo en APIs pagadas: **USD 0**.

---

## 7. Decisiones del PO (con la opción recomendada)

1. **Técnica**: 3D real en Godot (híbrido, con fondo pintado prerenderizado) **[recomendada]**, o sprites
   prerenderizados en Blender. La recomendada queda condicionada a que pase el spike V1 en el teléfono.
2. **Prioridad frente al capítulo 1**: el WIP de Dev ya está excedido. Opciones: (a) entra después de
   cerrar el camino crítico del capítulo 1; (b) entra ya, desplazando otra tarjeta; (c) solo V0 + V1 ya
   (ficha y spike, que no bloquean nada) y el resto después **[recomendada: c]**.
3. **Cómo se pierde**: "¡otra vez!" desde el inicio del sector con puntaje a 0 **[recomendada]**, o
   reiniciar el viaje completo (más arcade, más frustrante para un viaje que es puerta de paso).
4. **Viajes repetidos**: la primera vez por ruta, video de despegue + juego completo + presentación;
   después, despegue de 2 s saltable + juego + llegada corta **[recomendada]**. Alternativas: siempre todo,
   o que el juego sea opcional en rutas ya hechas (con "viajar rápido").
5. **Maxi**: 5 corazones + escudo por sector, sin proyectiles enemigos y con "Cometa al volante" tras 3
   derrotas **[recomendada]**; o aún más suave (las rocas se apartan como hoy en el sector 1).
6. **Jefe del Coleccionauta en la ruta final**: que aparezca su nave y huya soltando la colección,
   sin destruirla **[recomendada, sujeta a `guionista`]**; o un jefe genérico y el Coleccionauta solo en
   cinemática.
7. **Récord**: global por hermano + por ruta, visible en el mapa estelar junto a la nave
   **[recomendada]**; o solo global.
8. **Música**: reemplazar el chiptune por música acorde al estilo pintado **[recomendada]**; el chiptune
   actual puede quedar como guiño en la pantalla de resultados.

### 7.1 Decisiones del PO (Gerson, 21-Nov-2026)

Respuestas textuales del PO entre comillas. Lo marcado *(interpretación)* es lectura de Dev y lo confirma
la ficha V0.

1. **Técnica**: "si hagamoslo asi". 3D real en Godot con fondos prerenderizados en Blender, condicionado
   a la puerta del spike V1 (≥ 55 fps en el teléfono). Si no pasa, se usa la opción b (sprites).
2. **Prioridad**: "si dejalo listo para que lo desarrollemos en otra sesion". Ahora solo se registran las
   tarjetas y se deja la propuesta lista. V0 (ficha) y V1 (spike) son las primeras de la próxima sesión, y
   el resto va después del capítulo 1.
3. **Al perder**: "si agrega checkpoints". "¡Otra vez!" sin cuenta regresiva, desde el **último checkpoint**:
   uno al inicio de cada sector, uno **a mitad de cada sector** y uno **antes del jefe**. Se vuelve con
   vidas llenas, y el puntaje del intento queda en 0 para el récord.
4. **Viajes repetidos**: "solo la primera vez el video, despues de eso, que vuelvan rapido al checkpoint".
   - Los videos de despegue y llegada solo se ven **la primera vez por ruta**.
   - En las siguientes veces no hay video: se entra directo al juego.
   - Al perder, el regreso al checkpoint es inmediato, sin pantallas intermedias (máximo ~1,5 s de gag).
   - *(Interpretación)* Si un niño sale del viaje a medias, al volver retoma el último checkpoint de esa
     ruta, no el inicio.
5. **Maxi**: "me parece bien". 5 corazones, escudo por sector, enemigos sin proyectiles y "Cometa al
   volante" tras 3 derrotas.
6. **Coleccionauta**: "el coleccionauta aparece, y se va al planeta que toca. porque este juego aparecera
   cada vez que viaje entre planetas". Esto **cambia la propuesta**:
   - El Coleccionauta aparece en **todos los viajes**, no solo en la ruta final.
   - Es el encuentro final del viaje: se deja ver, provoca (con gag) y **huye hacia el planeta de destino**.
     Así engancha la historia con el planeta siguiente.
   - No se destruye ni se derrota del todo. El jefe de cada ruta puede ser un esbirro o un artefacto suyo,
     o su propia nave con fases que esquivar.
   - Las líneas las escribe `guionista`, y el modelo de su nave sale de HE-131. Mientras tanto, V4 usa
     uno provisional.
7. **Récord**: "si uno por hermano y por ruta". Un récord por hermano y por ruta, visible en el mapa estelar.
8. **Música**: "si por favor". Música nueva acorde al estilo pintado. El chiptune puede quedar como guiño
   en los resultados.

---

## 8. Documentos a actualizar cuando el PO decida

- `docs/diseno-juego.md`: sección del viaje estelar y una fila "shooter del viaje" en la tabla de §6.11.
- `docs/stack-tecnico.md`: decisión registrada "primer uso de 3D en el juego (viaje), renderer Mobile,
  material toon propio, pipeline Blender → glb".
- `docs/TABLERO.md` (solo `scrum-master`): tarjetas V0-V8 y la nota "si el viaje estelar se registra como
  tarjeta" que hoy figura como decisión menor abierta.
