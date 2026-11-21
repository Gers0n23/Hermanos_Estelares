# Catastro de audio y cinemáticas, hasta el planeta 2 (Animalia)

> 21-Nov-2026. Pedido del PO: «primero vamos limpiando lo que ya tenemos y hagamos un catastro de lo que nos
> falta; agrega los audios que ya tenemos al juego». Alcance: la Tierra (intro y viaje), el Planeta Arcoíris,
> el viaje a Animalia, el Planeta Animalia y los menús de ese tramo.
> Se recalcula con el script del §6. Los números son de hoy.

## 1. Lo que se limpió hoy

- **Pedido 2 de la narración**: se recortó otra vez desde el audio completo, sin costo. «...¿segundito tarde?»
  ahora termina a los 7,9 s, a 13,9 caracteres/s, el mismo ritmo que el resto. Así «...Yo. Jiji.» queda en
  1,5 s (antes 0,7). Las 5 líneas están en su ruta final (`narr_intro_despues_destello`, `narr_intro_yo`,
  `intro_012`, `intro_013`, `intro_017`).
- **Carpetas de trabajo**: se borraron `voces/agrupado_bloques/` y `voces/prueba_agrupado/`, que eran copias
  de lo que ya estaba en su ruta final. Los audios completos de cada pedido a fal se archivan en
  `voces/_crudos_fal/`, que tiene `.gdignore` y no entra al juego.
- **Carpetas de prueba de voces** (`prueba_*`, `guion_v1`, unos 32 MB): quedan en disco, pero con `.gdignore`,
  para que no entren al APK. Ningún script las usa. `guion_v1` tiene las líneas de los niños generadas para
  revisión (ver §4). Cuando se aprueben, se mueven a su ruta final.
- **8 voces que el juego no podía cargar**: las invitaciones de Arcoíris, Animalia, Melodía, Cuenta-Cuentas,
  Letralandia y Corazón, más `titulo_bienvenida_01` y `seleccion_invitacion_01`. Cuatro eran WAV con extensión
  `.ogg` y se convirtieron a OGG de verdad. Las otras cuatro tenían una importación fallida guardada y se
  reimportaron. **Hasta hoy el Mapa Estelar no decía su invitación** («¡Vamos al Planeta Arcoíris!»).
- `generar_voces_fal_agrupado.py` ya saca las líneas de `pendientes_fal.txt` al guardarlas.

## 2. Lo que ya suena en el juego (conectado hoy)

La narración vive en `datos/historia/narracion.json`: momento → líneas en orden. Ese archivo dice, para cada
momento, qué escena lo reproduce o si la escena todavía no existe. El autoload `Audio` ganó una cola de voces
(`reproducir_voces` / `encolar_voces`): un toque del niño la corta y los recordatorios no la pisan. Lo verifica
`herramientas/qa_test_narracion.gd`, que pasó 60/60 sin tocar el guardado real.

| Momento | Dónde suena |
|---|---|
| Saludo de la primera vez / «¡Volvieron!» | Título (la primera vez de la familia / una vez por sesión) |
| «¡Maxi, el explorador valiente!» (y Nicole y Sofía) | Selección, al tocar la tarjeta |
| «Este es el Mapa Estelar...» | Mapa Estelar, la primera vez de la familia |
| «¿Se acuerdan?» (gris / pieza / completo / otro planeta) | Mapa Estelar, una vez por sesión, según el avance guardado |
| «Ese planeta todavía está muy lejos...» | Mapa Estelar, al tocar un planeta lejano |
| «¿Volvemos al mapa?» | Flecha del mapa de un planeta, una vez por sesión |
| Despegue Tierra → Arcoíris (3 líneas) | Viaje arcade, antes de la instrucción, la primera vez de cada hermano |
| Despegue Arcoíris → Animalia + álbum de Coco (4 líneas) | Sobre el video de despegue |
| Presentación de Animalia (2 líneas) | Sobre el video de presentación; sigue al entrar al mapa |
| Llegada al mapa de Arcoíris (2) y de Animalia (3) | Primera visita de la familia, antes de la bienvenida |

**De las 82 líneas de Cometa de esta tanda, 33 ya suenan.** Otras 41 están generadas y esperan su escena
(§3). Las 8 restantes (hangar y tocar a Cometa) hay que regenerarlas, porque su pedido salió mal.

## 3. Cinemáticas hasta Animalia: qué existe y qué falta

| # | Escena | ¿Existe en el juego? | Imagen / video | Voces |
|---|---|---|---|---|
| 1 | **Intro** (living, secuestro, Cometa, trajes, nave, 1.ª videollamada) | ❌ no hay escena | 1 still final (`01_tarde_cualquiera`) + 2 planos de prueba (02, 07) + video de la nave (B1, 07) | Cometa ✅ completo. Niños: generados en `guion_v1` y **esperan que el PO los escuche**. Papá (`intro_006`, `031`, `032`, `036`): ❌ sin generar |
| 2 | Viaje Tierra → Arcoíris | ✅ viaje arcade | ⚠️ esta ruta no tiene video de despegue ni de llegada, así que **la presentación de Arcoíris nunca se ve** (HE-140) | Cometa ✅. Coleccionauta: provisional (TTS de Windows) |
| 3 | Presentación del Planeta Arcoíris (B3) | ⚠️ solo dentro del viaje | ✅ video | Cometa ✅ (se activa solo cuando la ruta tenga video de llegada) |
| 4 | **Llegada a Arcoíris** (`escena_llegada_arcoiris.md`, 20 líneas) | ❌ | ❌ | ❌ Cometa, Coco y niños sin generar (los niños, en parte en `guion_v1`) |
| 5 | Mapa de Arcoíris, primera vez | ✅ | ✅ | ✅ |
| 6 | **Primera pieza + taller + videollamada** | ❌ | ✅ video del taller (B2), sin integrar (HE-133) | Cometa ✅. Papá (`arcoiris_011`, `012`, `016`): ❌. Niños: `guion_v1` |
| 7 | **Batalla de Arcoíris + cierre + partida** | ❌ (`escenas/nucleo/batalla.tscn` no existe) | ❌ | Cometa ✅ (narración). **43 líneas de juego sin texto en TSV**. Papá/Coleccionauta: 8 de 120 generadas en `guion_v1` |
| 8 | Viaje Arcoíris → Animalia | ✅ | ✅ despegue, llegada y presentación | Cometa ✅. Coleccionauta: provisional |
| 9 | Llegada y mapa de Animalia | ✅ mapa | ✅ | Cometa ✅. **Las 41 voces del mapa de Animalia no existen**, tampoco la bienvenida |
| 10 | Pieza, taller y videollamada de Animalia | ❌ sin guion propio | ✅ video del taller (B2, pieza 2) | Cometa ✅. Papá: solo propuesta de texto |
| 11 | Batalla de Animalia | ❌ | ❌ | 40 líneas sin texto en TSV |

**Lo que bloquea las cinemáticas no es el audio, son las escenas.** De las 11, solo los viajes y los mapas
existen en el juego. La intro, la llegada, la pieza y la videollamada, y las batallas, están en guion y
storyboard, pero sin implementar (HE-133, HE-83 a HE-85, la batalla HE-69, la intro). Tampoco está la
imagen de la intro: hay 1 still final de los ~20 planos.

## 4. Pistas de audio que el juego pide y no tienen voz oficial

El juego referencia **1.434 audios** hasta Animalia (contando la narración conectada hoy): **533 están bien, 768 no existen y 133 suenan con voz de
relleno** (TTS de Windows). Por bloque, según lo que hace falta para generarlos:

| Grupo | Líneas | ¿Qué falta para generarlas? | Costo estimado |
|---|---|---|---|
| **A. Listas para generar** (Coco: 137 de Arcoíris, en su mayoría relleno; Cometa: 12 de relleno + 8 de hangar y toque) | **157** | Nada: tienen voz creada y texto | **USD 1,80** (20 pedidos agrupados) |
| **B. Toby (Animalia)**: buscar 159, topos 102, caminos 94, nombres 78 | **433** | **La voz de Toby no existe**: hay que diseñarla (decisión del PO: cómo suena) y crearla | voz: diseño + clon (centavos con Qwen, nunca MiniMax a USD 3); líneas ≈ 34 pedidos ≈ USD 3,1 |
| **C. Sin texto en TSV**: modo equipo 71, runner de Animalia 62, batalla de Arcoíris 43, mapa de Animalia 41, batalla de Animalia 40, Parejas de Arcoíris 37, otras 21 | **315** | Pasar los textos de los guiones y fichas a TSV con su personaje (trabajo sin costo). Muchas son del Coleccionauta (voz de papá) o de Toby | se estima al armar los TSV (≈ 30 pedidos ≈ USD 2,7) |
| **D. Sin personaje asignado** (Mezclar y Pinta de Arcoíris) | 4 | Decidir quién las dice | 1 pedido |

Fuera de esta lista, porque el juego todavía no las pide (son de las escenas del §3):
- **Papá / Coleccionauta** (`lote_ninos_papa.tsv`, voz `papa_d`): 120 líneas, 8 generadas. Las del tramo
  hasta Animalia son la intro, las videollamadas, la batalla y el cierre de Arcoíris, y las del viaje.
- **Niños** (Maxi, Nicole, Sofía): generadas en `guion_v1` (≈ 24 cada uno). **Esperan que el PO las escuche.**
- **Llegada a Arcoíris**: 20 líneas sin generar (Cometa, Coco y niños).

## 5. Orden propuesto

1. **Grupo A** (USD 1,80): deja Arcoíris entero con voz oficial y completa el hangar y el toque de Cometa.
2. **Voz de Toby**: el PO describe cómo suena; se diseña y clona como Coco, con una prueba de 1 pedido antes
   de la tanda. Después, el grupo B.
3. **Grupo C**: armar los TSV (sin costo), estimar y pedir el OK.
4. El PO escucha a los niños de `guion_v1`. Después, la tanda de papá (intro, videollamadas, batalla).
5. Las escenas de historia (§3) son trabajo de desarrollo: se planifican en el tablero.

## 6. Cómo recalcular

`python herramientas/catastro_voces.py` recorre `datos/`, `scripts/` y `escenas/` buscando rutas `voces/...` y las
cruza con el disco y con `assets/audio/voces/pendientes_fal.txt`.
