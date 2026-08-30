# Storyboard y plan de generación — Escena de historia: Intro

> Insumo: `docs/guiones/escena_intro.md` (guion completo con ids de línea, revisión 07-Ago-2026).
> Fuentes de estilo: `docs/guia-estilo-generacion.md` (biblia de arte, anclas, flujo de aprobación,
> §1 "Cambio de proveedor de video"), `docs/stack-tecnico.md` §5 y §7 (pipeline y decisión de video
> por referencia, actualizada 07-Ago-2026).
> Entregable de `director-cinematicas` para HE-30 (cinemática inicial del capítulo 1). Este
> documento dejó los **prompts listos para generar** en `assets/prompts/cinematicas/intro/` — no
> se ha generado nada todavía, es la preparación para cuando el PO decida arrancar.
>
> **Revisión 07-Ago-2026**: el PO pidió reconsiderar el modelo de video (Veo 3.1 no
> necesariamente es la mejor opción vigente) y señaló que el rig de cutout que hoy existe en Godot
> no está a la altura del acabado pintado del resto del arte generado. Este documento cambia en
> dos sentidos: (1) se investigó el panorama de modelos de video 2026 y se reemplaza Veo 3.1 por
> **Seedance 2.0 / Kling v3, ambos vía fal.ai** — ver sección de abajo; (2) se elimina la categoría
> "solo Godot" para esta cinemática: **el cutout por partes queda reservado exclusivamente para la
> animación de gameplay** (`docs/stack-tecnico.md` §5 punto 4 — personajes jugables), nunca para
> escenas narrativas no interactivas. Toda la escena se resuelve con arte/video generado o motion
> comic, para que el acabado sea uniforme de punta a punta.

## Elección de modelo de video (revisión 07-Ago-2026)

Investigación de mercado de agosto 2026 sobre generación de video con consistencia de personaje
para estética cartoon pintada (no fotorrealista):

- **Seedance 2.0** (ByteDance) rankea primero en consistencia de personaje entre planos y acepta
  **hasta 12 imágenes de referencia simultáneas** por generación — el techo más alto de todos los
  modelos comparados, justo lo que necesitamos para los planos de esta escena con 3-4 personajes
  a la vez (que es exactamente donde más costó sostener consistencia con el elenco actual: ver las
  4-5 rondas de corrección de Camaleona Coco y Toby en `docs/guia-estilo-generacion.md` §3).
- **Kling v3** tiene un acabado más "cinematográfico"/pulido y su sistema de referencia por
  *elements* (`@Element1`, `@Element2`... referenciables directo en el prompt) funciona muy bien
  con 1-2 personajes por plano, aunque su techo de consistencia con elencos grandes es algo menor
  al de Seedance.
- **Veo 3.1** (la opción usada hasta ahora) queda por detrás de ambos en los rankings 2026 de
  consistencia de personaje/estética pintada, y además exige una credencial separada
  (`GEMINI_API_KEY`) distinta de la que ya usamos para todo el arte raster.
- Los tres — y decenas más (Wan, Hailuo, Runway Gen-4.5, Luma Ray, Vidu, LTX) — están disponibles
  en **fal.ai**, el mismo proveedor ya integrado en `herramientas/generar_imagen.py` con la misma
  `FAL_KEY`. Cambiar de modelo de video no exige contratar nada nuevo.

**Recomendación aplicada en este documento** (pendiente del visto bueno final del PO, mismo
criterio que cualquier cambio de proveedor registrado en la guía de estilo):

| Modelo | Vía (fal.ai) | Cuándo usarlo aquí | Costo aprox. (clip de 5 s) |
|---|---|---|---|
| **Seedance 2.0** (por defecto) | `bytedance/seedance-2.0/reference-to-video` (hasta 12 anclas) | Planos con 3+ personajes en cuadro, donde la consistencia del elenco es lo más difícil de sostener | ~$1,20-1,50 (tier *fast*/*standard* 720p) |
| **Kling v3** | `fal-ai/kling-video/v3/standard/image-to-video` con *elements* | Planos de 1-2 personajes donde importa más el acabado cinematográfico (ej. el choque de Cometa) | ~$0,40-0,50 (*standard*, audio apagado) |
| Veo 3.1 (respaldo) | API Gemini directa, `GEMINI_API_KEY` | Solo si Seedance/Kling no logran consistencia tras 2-3 intentos, antes de caer a motion comic | — |

Para los 4 planos de video de esta escena (ver tabla más abajo), el costo total estimado ronda los
**USD 3-6** — perfectamente asumible para un proyecto que ya viene optimizando costo de imagen
(FLUX.2 sobre Nano Banana Pro).

Fuentes consultadas: [Best AI Video Generators for Consistent Characters in 2026](https://blog.mage.space/article/best-ai-video-generators-consistent-characters-2026/9459a229-806d-4a73-8abf-a19db645a248), [10 Best AI Video Generators in 2026 | fal](https://fal.ai/learn/tools/ai-video-generators), [Seedance 2.0 API Live on fal](https://fal.ai/seedance-2.0), [Seedance 2.0 Mini/Reference-to-Video API on fal](https://fal.ai/models/bytedance/seedance-2.0/mini/reference-to-video), [Kling Video v3 [Standard] (Image to Video) API on fal](https://fal.ai/models/fal-ai/kling-video/v3/standard/image-to-video), [Kling 3 vs Seedance 2: The AI Video Model Head-to-Head for Character-Driven Film](https://www.screenweaver.ai/blog/kling-3-vs-seedance-2), [Seedance 2.0 vs Kling 3.0: AI Video Generator Comparison](https://www.eachlabs.ai/blog/seedance-2-0-vs-kling-3-0-ai-video-generator-comparison).

## Cómo vamos a generar esta escena — método y buenas prácticas

Esta escena no se genera "a lo bruto": cada plano hereda identidad y estilo de las anclas ya
aprobadas del elenco (`docs/guia-estilo-generacion.md` §2-§3), no del criterio libre del modelo.
Reglas aplicadas en todos los prompts de esta carpeta:

1. **Nunca sin ancla.** Todo prompt adjunta al menos el póster oficial (`assets/ejemplos/hermanosestelares.jpeg`)
   como ancla maestra de estilo, más las hojas de referencia de cada personaje/entorno que
   aparezca en el plano. Ningún prompt le pide al modelo "inventar" cómo se ve Cometa, el
   Coleccionauta, papá o el living — eso ya está resuelto y aprobado.
2. **Grupo de 2-3 hermanos → póster + `hermanos_alturas.png`, nunca las 3 hojas individuales a la
   vez.** Lección aprendida ya documentada (`docs/guia-estilo-generacion.md` §2): adjuntar
   `maxi_referencia.png` + `nicole_referencia.png` + `sofia_referencia.png` juntas duplica
   personajes. Cuando el plano necesita a los tres, el lineup de alturas fija identidad/proporción
   y el texto del prompt describe a cada uno. Con Seedance 2.0 (hasta 12 anclas) este límite es
   menos apretado que con FLUX.2/Veo, pero la lección sigue aplicando igual: preferir el lineup de
   grupo a las hojas individuales sueltas cuando hay 3+ personajes en cuadro.
3. **Keyframe primero, video después.** El plano de video nunca le pide al modelo que dibuje la
   escena desde cero: el fotograma ancla ya aprobado con FLUX.2 (que a su vez heredó identidad de
   las anclas del punto 1) es una de las imágenes de referencia que Seedance/Kling reciben para
   animar. Así el personaje en movimiento es el mismo personaje ya validado en 2D, no una
   reinterpretación nueva.
4. **Un plano = un clip = una sola idea de movimiento**, sin cortes de cámara dentro del clip
   (regla de `director-cinematicas`). Los prompts de video de esta carpeta son deliberadamente
   cortos y describen un solo gesto/acción continua de ~5 s.
5. **Se genera mudo.** Ningún prompt de video pide diálogo ni sincronía labial (aunque Seedance 2.0
   soporta audio nativo, no lo usamos aquí) — las voces se graban aparte
   (`assets/audio/voces/guion_voces.md`) y se montan encima en Godot.
6. **Máximo 2-3 intentos por plano.** Si tras eso un plano no mantiene al personaje idéntico, se
   resuelve como *motion comic* (keyframe fijo + paneo/parallax/zoom con `Tween` en Godot) —
   respaldo ya aprobado, no una degradación del proyecto (`docs/stack-tecnico.md`).
7. **Corrección dirigida, no regeneración ciega.** Si un intento casi funciona, se corrige con una
   pasada de edición puntual sobre la propia imagen (`--proveedor fal-gpt2`, ancla = la imagen a
   corregir + lo que haga falta), pidiendo explícitamente qué cambiar — mismo patrón ya usado y
   documentado en Coco v4→v5, Toby v1→v6 y la nave v2→v3b.
8. **Verificar por zoom/cuadrante antes de aprobar un plano con 2+ personajes**, no solo mirar la
   composición general — las correcciones de Toby (`docs/guia-estilo-generacion.md` §3) muestran
   que un defecto visible solo en una vista pasó dos rondas sin detectarse por revisar de lejos.
9. **Sin texto en la imagen, nunca** (ni siquiera para gags) — coherente con que el juego no usa
   texto obligatorio.
10. **Aprobación**: `experto-ux-parvulo` audita tono/miedo/legibilidad → PO aprueba → recién ahí se
    promueve de `assets/generadas/cinematicas/intro/` a `assets/cinematicas/intro/` (mismo flujo
    de `docs/guia-estilo-generacion.md` §5, aplicado a esta carpeta nueva).

## Por qué esta cinemática no reutiliza el rig de Godot

El rig por partes vectorizado (`docs/stack-tecnico.md` §5 punto 4) resuelve muy bien las 3 poses
de gameplay (idle/caminar/celebrar) de los personajes **jugables**, pero es un sistema pensado para
interacción en tiempo real, no para el acabado "cartoon pintado digital" (§3 de la guía de estilo)
que ya tiene el resto del arte generado. Mezclar planos de video/imagen generados con planos
animados a mano en Godot dentro de la misma cinemática se notaría — dos texturas visuales
distintas en una escena que debe leerse como una sola pieza. Por eso, a diferencia de la primera
versión de este documento, **ningún plano de esta escena se resuelve "solo en Godot"**: incluso el
que menos acción tiene (la nave-estrella revelándose) se trata como un plano [M] o [V] igual que
el resto. El cutout sigue siendo la herramienta correcta para el mapa estelar, los minijuegos y
cualquier pantalla interactiva — este documento no cambia eso, solo saca las cinemáticas
narrativas de su alcance.

## Categorías de producción de esta escena

| Categoría | Cuándo aplica | Ejemplo en esta escena |
|---|---|---|
| **[M] Keyframe IA + motion comic** | El plano es mayormente diálogo sostenido con poca acción física — no vale la pena un clip de video | Planos 01, 03, 05, 08, 09 |
| **[V] Keyframe IA + video (Seedance 2.0 / Kling v3)** | El plano es la acción central de un beat — vale la inversión de un clip de video real | Planos 02, 04, 06, 10 |

El plano 07 (nave-estrella revelándose) es el único caso especial: no necesita un keyframe nuevo
porque `nave_estrella_referencia.png` ya es un keyframe aprobado — pasa directo a la etapa de
video usando esa imagen como referencia principal (ver tabla).

## Tabla de planos

| # | Plano | Beat / líneas | Categoría | Personajes en cuadro | Anclas (además del póster) | Prompt(s) |
|---|---|---|---|---|---|---|
| 01 | Tarde cualquiera | Beat 1 · intro_001-003 | [M] | Maxi, Nicole, Sofía (ropa de casa) | `hermanos_alturas.png`, `casa_living_referencia.png` | `01_tarde_cualquiera.txt` |
| 02 | El Coleccionauta se lleva a papá | Beat 2 · intro_004-007 | [V] Seedance 2.0 | El Coleccionauta, Papá | `coleccionauta_referencia.png`, `papa_referencia.png`, `casa_living_referencia.png` | `02_coleccionauta_secuestro.txt` + `_video.txt` |
| 03 | Reacción de los hermanos | Beat 2 · intro_008-010 | [M] | Maxi, Nicole, Sofía (ropa de casa) | `hermanos_alturas.png`, `casa_living_referencia.png` | `03_hermanos_reaccion.txt` |
| 04 | Choque de Cometa | Beat 3 · intro_011-013 | [V] Kling v3 (1 personaje) | Cometa (+ su navecita) | `cometa_referencia.png`, `cometa_navecita.png`, `casa_living_referencia.png` | `04_cometa_choque.txt` + `_video.txt` |
| 05 | Cometa tranquiliza a los hermanos | Beat 3-4 · intro_014-022 | [M] | Cometa, Maxi, Nicole, Sofía (ropa de casa) | `cometa_referencia.png`, `hermanos_alturas.png`, `casa_living_referencia.png` | `05_cometa_conoce_hermanos.txt` |
| 06 | Trajes con estrellas de poder | Beat 5 · intro_023-026 | [V] Seedance 2.0 (4 personajes) | Cometa, Maxi, Nicole, Sofía (transformándose) | `cometa_referencia.png`, `cometa_navecita.png`, `hermanos_alturas.png` | `06_trajes_estelares.txt` + `_video.txt` |
| 07 | Nave-estrella revelada | Beat 6 · intro_027-030 | [V] Kling v3 (sin keyframe nuevo) | (sin personajes) | reusa `nave_estrella_referencia.png` como imagen base | *(sin keyframe — solo prompt de movimiento, ver nota abajo)* |
| 08 | Video-llamada de papá | Beat 7 · intro_031-032 | [M] | Papá | `papa_referencia.png`, `coleccionauta_referencia.png` (solo para el tono del desorden de fondo) | `08_videollamada_papa.txt` |
| 09 | Hermanos respondiendo la llamada | Beat 7 · intro_033-036 | [M] | Maxi, Nicole, Sofía (trajeados) | `hermanos_alturas.png`, `casa_living_referencia.png` | *(pendiente — mismo patrón de `01`/`03`/`05`, keyframe nuevo con los 3 ya en su traje estelar frente a la llamada; no escrito todavía, ver Gaps abiertos)* |
| 10 | Partida hacia el Mapa Estelar | Beat 8 · intro_037-038 | [V] Seedance 2.0 (4 personajes) | Cometa, Maxi, Nicole, Sofía (trajeados) | `cometa_referencia.png`, `hermanos_alturas.png`, `casa_living_referencia.png` | `10_partida_mapa_estelar.txt` + `_video.txt` |

Duración de referencia por plano: los planos [V] apuntan a un clip de ~5 s que luego se
sostiene/loopea en Godot mientras dura el diálogo del beat, igual que ya se hace con `Tween` para
transiciones (`docs/stack-tecnico.md` §5). Los planos [M] son un fotograma fijo con paneo/zoom
suave (`Tween`) sostenido por la duración de sus líneas.

## Cómo generar cada plano con las herramientas actuales

**Keyframes (FLUX.2 vía `herramientas/generar_imagen.py`)** — sin cambios, ejemplo real con el
plano 02:

```powershell
python herramientas/generar_imagen.py `
    --prompt-file assets/prompts/cinematicas/intro/02_coleccionauta_secuestro.txt `
    --salida assets/generadas/cinematicas/intro/02_coleccionauta_secuestro.png `
    --aspecto 16:9 --proveedor fal `
    --ancla assets/ejemplos/hermanosestelares.jpeg `
    --ancla assets/anclas/coleccionauta_referencia.png `
    --ancla assets/anclas/papa_referencia.png `
    --ancla assets/anclas/casa_living_referencia.png
```

Repetir por cada plano [M]/[V] con sus anclas de la tabla de arriba (todas viven en
`assets/anclas/` salvo el póster, que vive en `assets/ejemplos/hermanosestelares.jpeg`). Si un
primer intento casi funciona, corregir con `--proveedor fal-gpt2` anclando con la propia imagen
generada (mismo patrón que las correcciones de Coco/Toby/nave documentadas en
`docs/guia-estilo-generacion.md` §3), nunca regenerando desde cero un plano que solo tiene un
defecto puntual.

**Video (Seedance 2.0 / Kling v3, vía fal.ai)** — ninguno de los dos tiene todavía un wrapper en
`herramientas/`. `generar_imagen.py` no sirve tal cual (está armado para los endpoints de imagen),
pero es la plantilla correcta a portar: mismo patrón de `config.py`/`FAL_KEY`, mismo manejo de
`--ancla` repetible, apuntando a estos endpoints en vez de a `fal-ai/flux-2-pro`:

- Seedance 2.0 (por defecto, planos con 3+ personajes): `bytedance/seedance-2.0/reference-to-video`
  — acepta hasta 12 imágenes de referencia + un prompt de texto con la idea de movimiento.
- Kling v3 (planos de 1-2 personajes, ej. plano 04 y 07): `fal-ai/kling-video/v3/standard/image-to-video`
  — usa el sistema de *elements*: cada imagen de referencia se declara como un elemento
  (`@Element1`, `@Element2`...) y el prompt de movimiento los referencia por nombre en vez de solo
  describir "el personaje". Al escribir el prompt de movimiento para Kling, conviene adaptar los
  archivos `..._video.txt` de esta carpeta agregando esas etiquetas (ej. "`@Element1` (Cometa's
  ship) tumbles...").
- Plano 07 (nave revelada) no necesita etapa de keyframe: se llama directo al endpoint de video
  pasando `nave_estrella_referencia.png` como imagen base/elemento único, con un prompt de
  movimiento breve ("el hueco fantasma dorado punteado brilla con más fuerza y suelta 2-3
  chispitas mientras la nave se asienta suavemente, cámara fija").

Portar `herramientas/generar_video.py` con estos dos endpoints es el siguiente paso natural antes
de arrancar los 4 planos [V] de esta escena — no se hizo aquí porque no se pidió explícitamente,
pero es una tarea chica (mismo esqueleto que `generar_imagen.py`, cambiando el cuerpo del POST y
agregando el parámetro de duración/aspecto que pida cada endpoint). Mientras tanto, cualquiera de
los 4 planos se puede generar llamando la API REST de fal.ai directamente con esos mismos
endpoints y `FAL_KEY`.

## Gaps abiertos antes de generar (bloquean calidad, no bloquean escribir el guion)

1. **Ropa de casa de los tres hermanos.** Los planos 01, 03 y 05 necesitan a Maxi/Nicole/Sofía
   *sin* su traje estelar (su diseño aprobado por defecto es el traje). Hoy no existe ninguna hoja
   de referencia de "ropa de calle/pijama de tarde" — los prompts de esos 3 planos lo piden de
   forma genérica (colores sólidos suaves, sin logos) pero el resultado debería tratarse como
   **provisional hasta que `disenador-personajes` apruebe un diseño de ropa de casa** consistente
   entre los tres (mismo criterio de coherencia ya aplicado a todo el elenco).
2. **Wrapper de `herramientas/generar_video.py`** — ver nota arriba, necesario antes de generar
   los planos [V] de forma repetible (hoy solo es posible a mano contra la API REST de fal.ai).
3. **Prompt del plano 09 sin escribir todavía** — a diferencia de los otros 9 planos, este quedó
   pendiente de redactar (mismo patrón que 01/03/05, pero con los hermanos ya trajeados). No
   bloquea nada, es la última pieza suelta antes de tener el set completo.
4. **El Coleccionauta y papá no tienen rig de cutout** (no son personajes jugables,
   `docs/stack-tecnico.md` §5 punto 4 solo riggea personajes jugables) — coherente con por qué
   todos sus planos son [V]/[M]: no hay forma de animarlos dentro del motor todavía, ni falta
   hace para una cinemática no interactiva.

## Notas de continuidad para `dev-godot`

- El plano 07 (nave revelada) es el más barato de generar (sin etapa de keyframe) — vale la pena
  probarlo primero para validar el flujo completo (fal.ai → `assets/generadas/cinematicas/intro/`
  → revisión → `assets/cinematicas/intro/` → reproducción en Godot con `Audio.reproducir_voz` por
  id de línea) sin esperar los planos más caros/complejos.
- Los archivos finales de cada plano (una vez aprobados) deberían vivir en
  `assets/cinematicas/intro/` (fuera de `assets/generadas/`, que es solo staging con `.gdignore`),
  siguiendo el mismo criterio de promoción que el resto del arte generado.
