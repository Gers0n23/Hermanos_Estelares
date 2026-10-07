# Correcciones de las validaciones HE-40 y HE-44 (`dev-godot`)

- **Fecha**: 28-Sep-2026
- **Autor**: `dev-godot`, a pedido del PO (avanzar sin consultarle). **Todo es PROVISIONAL** y se calibra en el playtest.
- **Specs**: `docs/validaciones/HE-40_disenador-niveles.md` (§3), `HE-40_disenador-mecanicas.md`,
  `HE-44_disenador-mecanicas.md`, `HE-40_HE-44_guionista.md`, las auditorías UX
  `docs/auditorias-ux/2026-09-28_HE-40_*.md` y `2026-09-28_HE-44_*.md`, y los guiones
  `zonas_arcoiris.md`, `escena_planeta_arcoiris.md` y `recuerdos.md`.
- **Criterio en los conflictos**: UX manda en los bloqueantes y cada diseñador en los parámetros de su área.
- **Voces**: todas las líneas nuevas o reescritas se generaron con el **TTS gratuito de Windows** (Sabina).
  El script usado es `herramientas/generar_voces_tts.ps1`, que ahora acepta `-IgnorarPersonaje` y rutas absolutas.
  - **No se usó fal.ai ni ninguna API de pago**, tampoco con `--estimar`.
  - Las líneas con personaje (Coco o Cometa) quedaron en `assets/audio/voces/pendientes_fal.txt`: son 100 rutas nuevas.
    `generar_voces_fal.py --solo-pendientes` las regenera con la voz oficial cuando el PO recargue saldo.
- **No se tocó** `docs/TABLERO.md`, **no se hicieron commits** y el trabajo previo sin commitear se respetó.

## 1. Hallazgo → cambio → archivo

### Bloqueantes

| Hallazgo | Cambio | Archivos |
|---|---|---|
| UX HE-40 R1 / niveles #1: mariposa en Formas de Nicole, zona 3 | Se cambia `mariposa` por `pony`. La función `mariposa()` sale del generador. Se agrega la lista `PROHIBIDOS` de bichos: el validador corta si una figura o su voz nombra alguno, en los tres perfiles | `herramientas/figuras_formas.py`, `datos/niveles/arcoiris/zona3_chupetines/formas_brote.json` (regenerado) |
| UX R2 / niveles #1: mariposa en los murales del taller, zonas 2 y 5 | Nuevo dibujo de mural `pony`: cuerpo y cabeza en la lata 1, crin y cola en la 2, corazón y cascos en la 3. Se agrega a `DIBUJOS_MURAL`. El generador rechaza los bichos | `scripts/motores/mezclar/motor_mezclar.gd`, `herramientas/generar_niveles_mezcla.py`, `mezcla_estrella.json` z1-z5 (regenerados) |
| Verificación de bichos | `rg -i "mariposa\|abeja\|arana\|bicho\|insecto\|catarina"` sobre `datos/` da 0 resultados. Quedan dos rastros fuera de las rutas: el audio huérfano `formas/figuras/mariposa.wav` y el gusanito de gomita del paisaje (ver §2) | — |
| UX HE-44 R1: el álbum y la entrega no tienen voz | Se crean las 77 líneas de Cometa de `recuerdos.md` (§1-§5 y los pies de foto de §8) con relleno de Windows: TSV propio con `# personaje: cometa` y los `.wav` importados. Las 77 están en `pendientes_fal.txt` | `assets/audio/voces/recuerdos/lineas_tts.tsv` y `*.wav` |

### Bug

| Hallazgo | Cambio | Archivo |
|---|---|---|
| Mecánicas HE-40 #6: `_derrotas` no se reinicia entre rondas | `_limpiar_tablero()` pone `_derrotas = 0` y limpia los fallos por hueco y el estado "flotando" | `motor_encajar.gd` |
| Mecánicas #6: el regalo pone una sola pieza | `piezas_de_regalo()` pone el 15 % de las piezas que faltan (entre 1 y 4), una cada 0,35 s. La pista y el regalo eligen primero el hueco con más "no es este" de la ronda y después el más grande | `motor_encajar.gd` |

### Mayores de UX y mecánicas

| Hallazgo | Cambio | Archivos |
|---|---|---|
| UX R3: tocar una pieza puesta en el marco la saca y la gira | Presionar ya no libera la pieza. Se libera recién al arrastrarla (`_al_mover`), y un toque solo da un saltito | `motor_encajar.gd` |
| UX R4: con espejo, elegir una pieza la gira | Con `boton_espejo`, el 1.er toque solo elige la pieza (halo y sonido) y los siguientes la giran. El espejo late mientras hay una pieza elegida. Sin pieza elegida, las piezas de la bandeja saltan en ola. El espejo tiene su propio sonido (menor #9) | `motor_encajar.gd` |
| UX R5: el círculo tocable roba el toque a la pieza vecina | `_has_point` resuelve en dos pasadas: primero la forma; el círculo de 96 px solo vale si el punto no cae en la forma de otra pieza y si esta pieza es la de centro más cercano. En el marco, la zona tocable es la forma agrandada 16 px, sin círculo | `pieza_encajar.gd` |
| Mecánicas #7: la bandeja del reto dorado es diminuta | Celdas de 50 px en el tablero. Zonas `[236,96,900,312]` y `[236,416,848,292]`. Bandeja con `escala_bandeja_fija` 0,64 (celdas de 32 px), `bandeja_acostadas`, `relleno_bandeja` 24 y filas de ancho parejo. Espejo en `[1110,440,120,120]`: no `[1120,470]`, porque así chocaba 6 px con Cometa. Medido en QA: escala 0,64 | `motor_encajar.gd`, `formas_estrella_dorado.json`, `herramientas/generar_niveles_sofia.py` |
| Mecánicas #4 / UX R12: la pista cobra por un toque accidental y el costo no se ve | Componente común `scripts/ui/pista_con_costo.gd` (ver el detalle abajo). Integrado en encajar, emparejar y la libreta de mezclar | `pista_con_costo.gd`, `motor_encajar.gd`, `motor_emparejar.gd`, `motor_mezclar.gd`; voces `nucleo/pista_confirmar.wav` y `pista_gratis.wav` |
| Mecánicas #5: una pieza con giro incorrecto cuenta fallo | Nuevo campo `giro_cuenta_fallo` (por defecto `false` en Estrella). La pieza flota 2,5 s sobre el hueco con alfa 0,7 y meciéndose ±4°. Un toque la gira ahí mismo y, si calza, encaja. Si pasa el tiempo o la arrastran, vuelve a la bandeja | `motor_encajar.gd`, `pieza_encajar.gd`, `figuras_formas.py` |
| Mecánicas #13 / UX R6: las gotas del taller vacían la lata entera | `separacion_min_gotas_px: 190`: si no hay lugar, la gota espera. `fallos_para_reiniciar_lata: 2`: la 1.ª gota equivocada sale escupida y las capas buenas se quedan. Nuevas voces `escupe_01/02` | `motor_mezclar.gd`, generador y niveles |
| Mecánicas HE-44 #1-#3 / UX R2: la foto se salta antes de tiempo | La foto no se cierra antes de que termine su audio: cada toque da una reacción juguetona. Después del audio, un toque la guarda. Se va sola 1,5 s después del audio, o a los 4,5 s si no tiene audio. En Semilla nunca se cierra por toque | `scripts/ui/entrega_recuerdo.gd` |
| HE-44 #2: el sobre se abre encima de Cometa | El sobre se abre tras la frase de Cometa más 0,4 s, entre 3 y 6 s. Si el niño lo abre antes, Cometa se desvanece en 0,15 s (nuevo `Audio.desvanecer_voz`) y la voz de la foto entra 0,35 s después | `entrega_recuerdo.gd`, `scripts/autoloads/audio.gd` |
| UX HE-44 R3, mecánicas #10 y UX R11: la entrega aparece o desaparece al lanzar un juego | El mapa emite `celebracion_zona_terminada` y la entrega la espera, con tope de 15 s. No se desbloquea si ya se lanzó un juego (llega en la próxima visita). Mientras está activa, el mapa ignora zonas, estaciones, Cometa, retos dorados y volver | `scripts/nucleo/mapa_planeta.gd` |
| UX HE-44 R4 / niveles #4: el marco dorado de Sofía es inalcanzable | `perfecta` se calcula solo sobre las estaciones que puntúan. Los 15 `pinta_*.json` declaran `"puntua_estrellitas": false` | `mapa_planeta.gd`, `herramientas/generar_pinta.py` y `pinta_*.json` |

**Detalle de la pista con costo (`pista_con_costo.gd`)**:

- Un medidor de 3 estrellitas de 34 px bajo el botón.
- El 1.er toque abre un globo de 150 px sin cobrar.
- Tocar el globo confirma y la estrellita cae del medidor. Tocar fuera, o esperar 4 s, lo cierra sin costo.
- Con 1 sola estrellita, la pista es gratis y directa.
- En emparejar, si ya hay una carta arriba, la pista revela su compañera (mecánicas #12).

### Economía y umbrales (`disenador-niveles`)

| Hallazgo | Cambio | Archivos |
|---|---|---|
| #2: faltan umbrales de estrellitas | `umbrales_estrellitas {tres, dos}` en emparejar (archivo) y encajar (archivo y `config` de cada ronda, vale la peor). Regla: ≤ tres → 3, ≤ dos → 2, si no 1. Derrota → 1. Cada pista resta 1. Si falta el campo, rige la regla vieja | `motor_encajar.gd`, `motor_emparejar.gd` |
| Valores de Parejas | z1 10/16, z2 9/15, z3 17/42, z4 15/24, z5 21/32, dorado 27/42 | `parejas_estrella*.json`, `generar_niveles_sofia.py` |
| Valores de Formas (por ronda) | Monumento: `tres` = límite/2, `dos` = límite. z1 sube a 14. Banderas: 3/límite (z4: 4, México 4, EE.UU. 5) | `figuras_formas.py` y `formas_estrella.json` |
| Valores de Mezclar | z1 2/5, z2 3/6, z3 3/7, z4 4/8, z5 5/10 | generador y niveles |
| #3: economía de destellos desigual | `mapa.json`: `destellos_por_estacion: 100` y `destellos_reto_dorado: 0`. Nuevo `destellos_fijos` en el contrato base (`minijuego_base.gd`): se celebra y se registra ese monto. Fuera del mapa, cada motor calcula el suyo. No hace falta migrar el guardado | `minijuego_base.gd`, `mapa_planeta.gd`, `mapa.json` |
| Regla `min(2, jugables)` | Ya no existe en el código: se exigen todas las estaciones jugables. Quedó documentado en la ficha | `planeta-arcoiris-zonas.md` |
| #8, #7, #10 y #12 | Sofía juega `["bandera","monumento"]` con bandeja 4/5/5/6/6. Nueva intro `intro_bandera_primero`, y el monumento usa su intro como `intro_ronda`. En Maxi z1, `bandera_italia` pasa a ser `autito`. Guardado pieza a pieza dentro de la ronda (`huecos_hechos`). Los `lluvia_estrella.json` quedan con `"legado": true` | `figuras_formas.py`, `motor_encajar.gd`, `lluvia_estrella.json` z1-z5 |

### Guion

| Hallazgo | Cambio | Archivos |
|---|---|---|
| Claves nuevas en `mapa.json` | `voz_abierta` (z2-z4) y `voz_regalo` (z1-z5) por zona. `juegos.lluvia.voces_perfil.sofia = juego_taller`. `zona_dormida` con 2 variantes, `estacion_repetida` (3), `planeta_completo` y `dorado_entrar` (UX R8). Orden al completar una zona: completada, regalo, zona que despierta, sobre | `mapa.json`, `mapa_planeta.gd` |
| Claves nuevas en `mezcla_estrella.json` | `pista` por zona (`pista_z2..z5`) y `escupe` | generador |
| Claves nuevas en el catálogo de recuerdos | `voces.entrega_zona` y `pie` / `pie_en_audio` en los 51 recuerdos. El pie suena antes del audio de la familia, en la entrega y en el álbum (UX R9) | `datos/recuerdos/catalogo.json`, `entrega_recuerdo.gd`, `album_recuerdos.gd` |
| Intros de Parejas de Maxi z2 y Nicole z3 | Se crean `semilla/intro_z2` y `brote/intro_z3` y se apuntan en los niveles | `parejas_semilla.json` (z2), `parejas_brote.json` (z3), `generar_parejas.py` |
| Reescrituras urgentes, regeneradas con Windows | Corona de Nicole (ya no nombra a Sofía), `zona_dormida` (regla de zona completa), `intro_arma_z1/z2` de Sofía, tríos de Parejas, intros z1 y z5 y `gris_01` del taller, 7 líneas de Pinta ("violeta" y "el corazón valiente de los héroes") | TSV de formas, mapa, emparejar, mezclar y pinta |
| Reescrituras de tono sobre voces oficiales | Llegada y completada de las 5 zonas, y `secreta_lejana`/`revelada`: se actualizó el texto en el TSV y quedaron en `pendientes_fal.txt`. **Conservan su audio oficial**: no se degradaron a Windows | TSV del mapa |
| `guion_voces.md` desincronizado | Se sincronizaron `arcoiris_001`, `_008` y `_017`. La tabla de recuerdos se actualizó con los textos del 28-Sep, 36 filas nuevas (`entrega_zona` y los pies) y su estado real. Se agregó una sección de voces HE-40 | `assets/audio/voces/guion_voces.md` |

### Menores hechos

- **UX HE-40**:
  - R7: el botón dorado va centrado sobre la tarjeta.
  - R9: el botón dorado se aplasta al presionar.
  - R10: la paleta del mosaico usa 2 columnas cuando hay más de 6 colores.
  - R11: "borrar" queda a 24 px de los demás botones.
  - R15: F4 solo funciona en builds de depuración y se apaga al salir del planeta.
- **UX HE-44 R5**: tocar fuera de la foto la cierra.
- **Mecánicas HE-40**:
  - #11: `visible_minimo_ms`, 600 ms en Brote. Los toques quedan en cola.
  - #14: "mantener apretado" agita a 0,4 por segundo.
- **Mecánicas HE-44**:
  - #4: invitación a tocar el sobre a los 1,5 s.
  - #5: flash de polaroid.
  - #6: el ícono conserva el halo 0,8 s.
- **Robustez**: con bandeja a escala real, el giro al azar solo elige orientaciones que caben en la bandeja. Antes, una pieza de Valparaíso podía quedar encimada y el fallo era intermitente.

## 2. Lo que quedó sin hacer (y por qué)

- **Pista del marco contra todas las soluciones** (mecánicas HE-40 #8): hay que generar offline las 2.339 soluciones del 6×10 y cambiar la búsqueda. Es un trabajo mayor que no estaba en la lista priorizada. Mientras tanto, la pista sigue usando una sola `solucion`.
- **Monumentos de 16-20 piezas con una regla por zona** (mecánicas HE-40 #1): hay que rediseñar figuras. Le toca a `disenador-niveles` y requiere decisión del PO.
- **Guiños de Sofía** (cachorros y ponys en Parejas z1 y la silueta de pony en el dorado): faltan los dibujos de perrito y gerbo (`disenador-personajes`).
- **Gusanito de gomita del paisaje** (UX R11 / niveles #11): queda para el PO y UX. No se tocó.
- **Cola de más de 3 sobres con velo continuo y marco dorado sin sobre** (HE-44 #7 y #8), **burbuja del viaje tocándola** (#9) y **silueta del ala que se pinta** (HE-40 #3): menores que no alcancé a hacer.
- **Menores UX HE-40**: R13 (medallas y pista con 3 o más rondas), R14 (registrar la excepción en GDD §6.2) y R16 (escuchar el SFX de zona dormida).
- **Menores UX HE-44**: R6 (deslizar sobre una foto del álbum), R7 (botón del álbum en la selección), R8 (ícono propio de la entrega) y R10 (Cometa en el álbum).
- **Menores de mecánicas HE-40**:
  - #17 y #18 (clasificar): Sofía ya no juega clasificar desde el mapa.
  - #20 (mosaico por cercanía).
  - #21: Pinta de Maxi con auto-mostrar a los 90 s. Pide voz "¿me lo muestras?", que no tiene guion.
- **La Lluvia de Sofía (clasificar, legado)** no recibió el medidor ni el globo porque ya no se juega desde el mapa.
- **`colores/naranjo` → "naranja"** en Parejas: el guion lo deja a decisión del PO.
- **Textos escritos por `dev-godot` sin guion** (a revisar por el guionista): `dorado_entrar`, `intro_bandera_primero`, `escupe_01/02`, `pista_confirmar` y `pista_gratis`.
- **Documentos que no son de dev**: GDD §3/§4 (hallazgo 13 de niveles) y HE-17 en el tablero.

## 3. Verificación (Godot 4.7.1 headless)

- **Parseo**: `--check-only` sobre todos los scripts modificados o nuevos de `scripts/` y los arneses, sin errores.
- **Importación**: `--headless --import` de los `.wav` nuevos (recuerdos, mapa, formas, emparejar, mezclar, pinta y núcleo).
- **Arneses actualizados o ampliados**:
  - `qa_test_mezclar`: gota escupida, separación de gotas, sin bichos en el mural y globo de la libreta.
  - `qa_test_encajar`: sin bichos, umbrales en los bordes, bandera primero, regalo del 15 %, `_derrotas` por ronda, pieza chueca flotando y guardado pieza a pieza.
  - `qa_test_retos_sofia`: escala 0,64, piezas acostadas, zona tocable por forma, R3, R4 y globo de la pista.
  - `qa_test_mapa_planeta`: Pinta no puntúa, marco dorado alcanzable, 100 y 0 destellos.
  - `qa_test_recuerdos`: 10 toques no saltan la foto, el sobre se abre tras Cometa y la entrega espera la celebración.
  - `qa_test_emparejar_rutas`: toque impaciente de Nicole.

Resultados de la regresión completa:

Regresión completa del 02/03-Oct-2026 (Godot 4.7.1 headless, los 15 arneses, con todo lo de §4 incluido): **todo en verde**.

| Arnés | Resultado |
|---|---|
| `qa_test_encajar` (completo, 82 figuras del pool) | OK, 0 fallos (1.900 checks) |
| `qa_test_lienzo` | OK (535) |
| `qa_test_parejas_zonas` | OK (425) |
| `qa_test_retos_sofia` | OK (117) |
| `qa_test_recuerdos` | OK (111) |
| `qa_test_viaje_arcade` | OK (84) |
| `qa_test_celebracion` | OK (76) |
| `qa_test_mapa_planeta` | OK (63), 0 fallos |
| `qa_test_emparejar_rutas` | OK (51) |
| `qa_test_mezclar` | OK, 0 fallos |
| `qa_test_clasificar`, `qa_test_emparejar`, `qa_test_progreso`, `qa_test_titulo`, `qa_test_voces` | OK (salida 0) |

Arreglos en los arneses (no en el juego) que salieron de la regresión:

- **`qa_test_mapa_planeta`**: el chequeo de la silueta del ala suponía que la zona 2 estaba incompleta, pero la prueba anterior de la zona secreta de Sofía ya la completa. Ahora solo exige el tramo de la zona 1.
- **`qa_test_mezclar`**: las pruebas de física y de "dejar pasar" pueden atrapar por azar una gota mala. Eso gasta la escupida de cortesía y suma fallos. Ambas pruebas ahora descuentan esas atrapadas (`motor.errores_lata()` y la señal `gota_atrapada`).
- **`qa_test_encajar`**: se corrigió la prueba de guardado pieza a pieza, que fallaba de forma intermitente (8/8 OK al repetirla).
- Un corte por tiempo de la primera corrida dejó datos `qa_encajar` en el guardado real (400, 600 y 832 destellos). Se limpiaron a mano y quedan solo los de `arcoiris` (respaldo en el scratchpad de la sesión).

## 4. Continuación 02-Oct-2026 (dev, PROVISIONAL, a pedido del PO: "continúa con el roadmap")

Cierre de pendientes de §2 y de los hallazgos nuevos de la re-auditoría UX
(`docs/auditorias-ux/2026-10-02_cierre-HE-40-HE-44.md`, HE-40 y HE-44 **APROBADAS** desde UX).

| Origen | Cambio | Archivos |
|---|---|---|
| Niveles HE-40 §7.5 (guiños de Sofía) | Dibujos nuevos `perrito` y `gerbo` (estilo peluche, como el gatito). Parejas z1 de Sofía: las 11 parejas son mascotas (perrito ×3, gatito ×3, gerbo ×2, pony ×3) con la trampa de color | `dibujos_emparejar.gd`, `generar_niveles_sofia.py`, `zona1_claro/parejas_estrella.json` |
| Niveles HE-40 §7.5 | Silueta del pony como pareja especial del reto dorado de Parejas (reemplaza a la flor; sigue 4×9). Nueva `Dibujos.silueta()` y la carta dibuja la sombra del pony | `dibujos_emparejar.gd`, `carta_emparejar.gd`, `parejas_estrella_dorado.json` |
| Mecánicas HE-40 #21 + niveles #11 | Pinta de Maxi: el botón "mostrar a Coco" aparece a los 45 s (antes 25-40) y, si sigue pintando 90 s más, Coco pregunta "¿me lo muestras?" una sola vez por hoja. **Sin auto-mostrar**: el niño decide | `motor_lienzo_libre.gd` (`segundos_recordar_mostrar`), `generar_pinta.py`, `pinta_semilla.json` z1-z5, `qa_test_lienzo.gd` |
| Mecánicas HE-40 #3 | Mapa: silueta del ala (la misma de Pinta z5) que se pinta un tercio por zona 1-3 completada, con el color de la zona, y estrella al completarse. Late en la fiesta de zona. Data-driven: `mapa.json` → `pieza_nave` | `mapa_planeta.gd`, `mapa.json`, `qa_test_mapa_planeta.gd` |
| Guionista 02-Oct | Textos definitivos de `dorado_entrar`, `intro_bandera_primero`, `escupe_01/02`, `pista_confirmar`, `pista_gratis` y las 2 líneas nuevas `me_lo_muestras`. Regenerados con TTS de Windows (gratis) y en `pendientes_fal.txt` | TSV + `.wav` |
| UX N1 (mayor) | Primera apertura: guion en orden fijo (`primera_01` al llegar el sobre, `primera_02` al guardar) y el sobre no se abre solo hasta que termina la frase (el niño igual puede abrirlo antes) | `seleccion_personaje.gd`, `entrega_recuerdo.gd` (`esperar_frase_completa`) |
| UX N2 (mayor) | Reto dorado: nunca un "0" grande. Con 0 destellos la estrella del contador queda como sello dorado que gira y crece | `celebracion.gd` |
| UX N3 (mayor) | El gusanito de gomita del fondo pasa a ser un osito de gomita que flota | `paisaje_arcoiris.gd` |
| UX N5 | Un 2.º toque al botón de pista con el globo abierto hace latir el globo (antes lo cerraba) | `pista_con_costo.gd` |
| UX P (pulido) | Se borra el audio huérfano `formas/figuras/mariposa.wav` y las fichas ya no nombran la mariposa | TSV de formas, `motor-mezclar.md`, `planeta-arcoiris-zonas.md` |

**Revisado y sin cambios**: la burbuja-recuerdo del viaje ya se atrapa tocándola (radio de 22 px de juego × escala 4 = 88 px en pantalla), así que mecánicas HE-44 #9 ya estaba cubierto. **UX N6** (postergar la foto) queda para verificar en el playtest, como pide UX.

**Sigue pendiente**: N4 (Cometa con dos voces: requiere OK del PO sobre el costo de fal.ai), "naranjo/naranja" (decisión del PO; el guionista recomienda "naranja"), monumentos de 16-20 piezas (decisión del PO), pista del marco contra todas las soluciones, cola de más de 3 sobres y marco dorado sin sobre (HE-44 #7/#8), y los menores UX de backlog.

## 5. Continuación 03-Oct-2026 (dev, PROVISIONAL, a pedido del PO: "no pares hasta que termines todo lo que puedas")

Pendientes de §4 y menores de backlog que **no dependen de decisiones del PO ni de APIs pagadas**. Con HE-40 y HE-44 ya ✅, los cambios quedan como adelanto dentro del alcance de HE-15/HE-42/HE-43 (Sofía, Nicole) y HE-45/HE-46/HE-47 (álbum).

| Origen | Cambio | Archivos |
|---|---|---|
| Mecánicas HE-40 #8 | **Pista del marco contra todas las soluciones.** `herramientas/soluciones_marco.py` enumera offline todas las soluciones de cada marco con bitmasks (6×10: 2.339 familias en ~50 s; mismo resultado que `resolver_marco` en tableros chicos) y las guarda en `soluciones_marco`, agrupadas por simetrías del tablero. El motor no gira las 2.339 soluciones: gira la consulta. La pista pone una pieza de la primera solución compatible con lo que ya puso Sofía, empezando por la celda libre más encerrada. Si ninguna es compatible, devuelve la pieza que, al quitarla, deja alguna compatible. Responde en ~11 ms. `generar_niveles_sofia.py` lo llama al final para que regenerar no borre el campo | `soluciones_marco.py`, `generar_niveles_sofia.py`, `formas_estrella_dorado.json`, `motor_encajar.gd`, `qa_test_retos_sofia.gd` |
| Mecánicas HE-44 #7 | Cola de recuerdos: el velo sigue puesto entre sobres. Desde el 2.º sobre, Cometa dice una línea corta (`recuerdos_otra_01/02`: "¡Y otra más!", "¡Otra fotito! ¡Llueven fotos!"). **Tope de 3 sobres por entrega** con `Recuerdos.desbloquear(..., maximo)`: lo que no cabe no se guarda y llega la próxima vez que se entre al mapa | `entrega_recuerdo.gd`, `recuerdos.gd`, `mapa_planeta.gd`, `catalogo.json`, TSV + `.wav` |
| Mecánicas HE-44 #8 | Entrega de solo marco dorado: sin sobre. La polaroid aparece directo, un marco dorado se dibuja a su alrededor en 1,2 s con una chispa en la punta, suena `dorado`, cae confeti dorado y la foto vuela al álbum | `entrega_recuerdo.gd` |
| Mecánicas HE-40 #17 | Lluvia de Nicole (`directo`): tocar un charco sin gota elegida no suelta nada. El charco late, dice su color y la gota de ese color más cercana da un saltito | `motor_clasificar.gd` |
| Mecánicas HE-40 #18 | Charcos que bailan (Nicole z3): no se mueven mientras haya una gota elegida o en la mano. Esperan a que la suelte, con tope de 6 s | `motor_clasificar.gd`, `gota_clasificar.gd` (`presionada()`) |
| Mecánicas HE-40 #20 | Mosaico de Sofía: el pincel pinta la celda más cercana dentro de 32 px del borde (zona efectiva ≥ 64 px) y el trazo interpola cada 10 px | `lienzo.gd` (`celda_cercana`) |
| UX HE-40 R13 | Medallas de ronda: con la pista visible, la fila termina antes de x 1150 (con 3 o 4 rondas se corre a la izquierda) | `motor_encajar.gd` |
| UX HE-40 R16 | "Todavía no" del mapa (zona dormida, estación que llega pronto): campanitas de sueño mi-sol-mi sintetizadas, en vez del `error_002` de Kenney | `componer_sfx_ui.py`, `sfx/ui/zona_dormida.ogg`, `mapa_planeta.gd`, `sfx/ui/LEEME.md` |
| UX HE-44 R6 | Álbum: las fotos rebotan al presionar pero actúan al soltar. Un toque corto (≤ 20 px) abre la foto y un deslizamiento (≥ 90 px) pasa de página | `album_recuerdos.gd` |
| UX HE-44 R7 | Botón del álbum en la selección: `Rect2(930, 596, 140, 120)`, a 36 px de la tarjeta de Sofía (antes 18) y a 78 px de "volver" | `seleccion_personaje.gd` |
| UX HE-44 R8 | Cuando la pantalla no tiene botón de álbum (mapa, viaje), la foto vuela abajo a la derecha, donde vive el álbum real (antes, arriba a la derecha) | `entrega_recuerdo.gd` |
| UX HE-44 R10 | Álbum: botón de Cometa de 116 px abajo a la derecha, como en los minijuegos. Repite la invitación en la portada, la línea de la tapa en la página y la voz de la foto abierta | `album_recuerdos.gd` |
| UX P8 | Una sola lista de bichos: `generar_niveles_mezcla.py` importa `PROHIBIDOS` de `figuras_formas.py` (suma chinita, escarabajo, grillo y caracol). Los niveles actuales no nombran ninguno | `generar_niveles_mezcla.py` |

**Textos escritos por dev sin guion** (a revisar por el `guionista`): `recuerdos_otra_01` ("¡Y otra más!") y `recuerdos_otra_02` ("¡Otra fotito! ¡Llueven fotos!"). Están generados con el TTS de Windows (gratis) y anotados en `pendientes_fal.txt`.

**No se tocó**: R14 (registrar en GDD §6.2 que en el mapa Cometa lleva al juego y Coco repite) porque es documento de diseño y no de dev. Tampoco N4, "naranjo/naranja" ni los monumentos de 16-20 piezas, que esperan una decisión del PO.

Verificación (Godot 4.7.1 headless):

- **Parseo**: `--check-only` sobre todos los scripts y arneses tocados, sin errores.
- **Regresión completa, los 15 arneses en verde**. El md5 del guardado real se midió antes y después de cada arnés, y ninguno lo cambia:

| Arnés | Resultado | Chequeos nuevos |
|---|---|---|
| `qa_test_retos_sofia` | OK, 0 fallos | pista-todas: 2.339 familias; no devuelve la pieza bien puesta de otra solución (11 ms); devuelve la X que aísla una esquina |
| `qa_test_recuerdos` | OK (126) | #7 tope y línea corta, #8 marco dorado sin sobre, R6, R7 (36 px), R8 y R10 |
| `qa_test_encajar` (completo) | OK, 0 fallos | R13 con 2, 3 y 4 rondas |
| `qa_test_clasificar` | OK, 0 fallos | #17 y #18 (con una gota de prueba extra, porque Nicole tiene una gota a la vez) |
| `qa_test_lienzo` | OK, 0 fallos | #20 a 25 px sí, a 45 px no |
| `qa_test_mapa_planeta` | OK, 0 fallos | R16 |
| `qa_test_viaje_arcade` | OK (84) | — |
| `celebracion`, `emparejar_rutas`, `parejas_zonas`, `mezclar` | OK, 0 fallos | — |
| `emparejar`, `progreso`, `titulo`, `voces` | OK (salida 0) | — |

**Incidente con el guardado real (03-Oct, madrugada)**: durante la regresión el juego estuvo abierto en paralelo. Una sesión de juego cargó el guardado mientras `qa_test_recuerdos` lo tenía reiniciado y lo volvió a guardar encima del restaurado: los perfiles quedaron en 0. Se recuperó desde el respaldo de la sesión, sin los datos `qa_encajar`. Además apareció una partida real de Lluvia z1 de Nicole (+100 destellos), que se fusionó a mano: Maxi 236, Nicole 347, Sofía 600. Se comprobó que ningún arnés, corrido solo, altera el guardado. **Recomendación**: no jugar mientras corren los arneses y, como mejora, que los arneses usen una ruta de guardado de prueba propia.
