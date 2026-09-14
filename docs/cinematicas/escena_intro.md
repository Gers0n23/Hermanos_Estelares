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
>
> **Revisión 30-Ago-2026 — Plano 07 rediseñado (rechazo del PO):** el primer intento del Plano 07
> (video Kling v3 directo sobre `nave_estrella_referencia.png`, sin keyframe nuevo) fue
> **rechazado por el PO**. Su feedback textual: *"esa imagen de la nave es un demo que muestra
> básicamente algunas partes faltantes de la nave como las alas. es como para una pantalla para
> mejorar la nave, pero no debe ser la escena de revelación de la misma."* — la imagen está
> compuesta como un asset de UI/pantalla de mejoras (nave sobre pedestal circular, nubes
> decorativas y estrellitas de fondo, sin ningún contexto de "estar en la historia"), y usarla tal
> cual como keyframe de cinemática se leyó como animar un ícono de menú, no como una toma
> narrativa. Nueva puesta en escena, pedida por el PO: *"la nave básica (sin las alas y sin la
> bandera de arriba) descienda desde el cielo hasta el patio de la casa de los niños."* Este
> documento incorpora esa puesta en escena: el Plano 07 ahora SÍ lleva una etapa de keyframe nueva
> antes del video (ver tabla actualizada, sección de gaps y notas de continuidad más abajo).
> `nave_estrella_referencia.png` **sigue siendo la ancla de identidad del diseño de la nave**
> (casco/cúpula/toberas presentes, sin alas ni bandera-mástil, huecos fantasma dorados punteados —
> ese diseño de capítulo 1 no cambia), pero deja de usarse como el keyframe final de la toma.

## Elección de modelo de video (revisión 07-Ago-2026)

Investigación de mercado de agosto 2026 sobre generación de video con consistencia de personaje
para estética cartoon pintada (no fotorrealista):

- **Seedance 2.0** (ByteDance) rankea primero en consistencia de personaje entre planos. La
  cobertura de mercado citaba hasta 12 imágenes de referencia, pero el schema real del endpoint en
  fal.ai (`bytedance/seedance-2.0/reference-to-video`, verificado 30-Ago-2026 al portar el wrapper)
  topea `image_urls` en **9** — igual que FLUX.2. Sigue siendo el techo más alto entre los modelos
  comparados y alcanza para los planos de esta escena con 3-4 personajes a la vez (que es
  exactamente donde más costó sostener consistencia con el elenco actual: ver las 4-5 rondas de
  corrección de Camaleona Coco y Toby en `docs/guia-estilo-generacion.md` §3).
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
| **[V] Keyframe IA + video (Seedance 2.0 / Kling v3)** | El plano es la acción central de un beat — vale la inversión de un clip de video real | Planos 02, 04, 06, 07, 10 |

El plano 07 (nave-estrella descendiendo al patio) **ya no es un caso especial** (revisión
30-Ago-2026): el primer intento, que reusaba `nave_estrella_referencia.png` directo como imagen
base de video sin keyframe nuevo, fue rechazado por el PO — esa imagen es un asset de pantalla de
mejoras (nave sobre pedestal circular entre nubes decorativas y estrellitas de menú), no una toma
narrativa. Ahora el plano 07 sigue el mismo patrón [V] que el resto: keyframe nuevo (la nave a
mitad de descenso, cielo de atardecer, patio y borde de la casa con la ventana visible) + video que
completa el descenso y el aterrizaje suave. `nave_estrella_referencia.png` se sigue usando, pero
solo como **ancla de identidad del diseño de la nave** (se le pide al modelo ignorar el
pedestal/nubes que la rodean y quedarse solo con casco/cúpula/toberas/huecos fantasma), nunca como
el fotograma final de la toma.

## Tabla de planos

| # | Plano | Beat / líneas | Categoría | Personajes en cuadro | Anclas (además del póster) | Prompt(s) |
|---|---|---|---|---|---|---|
| 01 | Tarde cualquiera | Beat 1 · intro_001-003 | [M] | Maxi, Nicole, Sofía (ropa de casa) | `hermanos_alturas.png`, `casa_living_referencia.png` | `01_tarde_cualquiera.txt` |
| 02 | El Coleccionauta se lleva a papá | Beat 2 · intro_004-007 | [V] Seedance 2.0 | El Coleccionauta, Papá | `coleccionauta_referencia.png`, `papa_referencia.png`, `casa_living_referencia.png` | `02_coleccionauta_secuestro.txt` + `_video.txt` |
| 03 | Reacción de los hermanos | Beat 2 · intro_008-010 | [M] | Maxi, Nicole, Sofía (ropa de casa) | `hermanos_alturas.png`, `casa_living_referencia.png` | `03_hermanos_reaccion.txt` |
| 04 | Choque de Cometa | Beat 3 · intro_011-013 | [V] Kling v3 (1 personaje) | Cometa (+ su navecita) | `cometa_referencia.png`, `cometa_navecita.png`, `casa_living_referencia.png` | `04_cometa_choque.txt` + `_video.txt` |
| 05 | Cometa tranquiliza a los hermanos | Beat 3-4 · intro_014-022 | [M] | Cometa, Maxi, Nicole, Sofía (ropa de casa) | `cometa_referencia.png`, `hermanos_alturas.png`, `casa_living_referencia.png` | `05_cometa_conoce_hermanos.txt` |
| 06 | Trajes con estrellas de poder | Beat 5 · intro_023-026 | [V] Seedance 2.0 (4 personajes) | Cometa, Maxi, Nicole, Sofía (transformándose) | `cometa_referencia.png`, `cometa_navecita.png`, `hermanos_alturas.png` | `06_trajes_estelares.txt` + `_video.txt` |
| 07 | Nave-estrella desciende al patio | Beat 6 · intro_027-030 | [V] Kling v3 (con keyframe nuevo — rediseño 30-Ago-2026) | (sin personajes) | `nave_estrella_referencia.png` (solo diseño de la nave — ignorar pedestal/nubes de fondo), `casa_living_referencia.png` (paleta de atardecer + diseño de ventana/casa, para que el exterior se lea como la misma casa); patio descrito de forma genérica en el prompt (ver Gap 5, sin ancla propia todavía) | `07_nave_revelada.txt` + `_video.txt` (rediseñados) |
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
- Plano 07 (nave desciende al patio) **ya sigue el patrón normal de dos etapas** (revisión
  30-Ago-2026, tras el rechazo del PO al intento anterior sin keyframe): primero un keyframe
  FLUX.2 con `07_nave_revelada.txt` (anclas: póster, `nave_estrella_referencia.png` solo para el
  diseño de la nave, `casa_living_referencia.png` para la paleta de atardecer y el diseño de la
  ventana), después el clip de video con Kling v3 usando ese keyframe como imagen base y
  `07_nave_revelada_video.txt` como prompt de movimiento (la nave completa el descenso y se asienta
  suavemente en el patio). Ya no aplica generar directo desde `nave_estrella_referencia.png`.

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
2. ~~**Wrapper de `herramientas/generar_video.py`**~~ — **Resuelto (30-Ago-2026)**. Portado con
   soporte para ambos endpoints (`--proveedor seedance|kling`). A diferencia de
   `herramientas/generar_imagen.py` (síncrono), los endpoints de video de fal.ai son
   **asíncronos por cola**: el script envía el pedido, sondea `status_url` cada 5 s hasta
   `COMPLETED` y recién ahí descarga `response_url` — las URLs de sondeo/resultado hay que
   tomarlas de la respuesta del envío, no reconstruirlas a mano (con el id anidado de Kling,
   `fal-ai/kling-video/v3/standard/image-to-video`, una URL de status armada manualmente da
   `405`). `generate_audio` queda forzado a `false` en el cuerpo del pedido en ambos proveedores
   (regla 5 de este documento: se genera mudo).
3. **Prompt del plano 09 sin escribir todavía** — a diferencia de los otros 9 planos, este quedó
   pendiente de redactar (mismo patrón que 01/03/05, pero con los hermanos ya trajeados). No
   bloquea nada, es la última pieza suelta antes de tener el set completo.
4. **El Coleccionauta y papá no tienen rig de cutout** (no son personajes jugables,
   `docs/stack-tecnico.md` §5 punto 4 solo riggea personajes jugables) — coherente con por qué
   todos sus planos son [V]/[M]: no hay forma de animarlos dentro del motor todavía, ni falta
   hace para una cinemática no interactiva.
5. **Sin ancla de entorno "patio/exterior de la casa"** (nuevo, 30-Ago-2026, a raíz del rediseño
   del Plano 07 tras el rechazo del PO). Hoy `assets/anclas/` solo tiene
   `casa_living_referencia.png`, que es el **interior** del living — no existe ninguna referencia
   de patio, fachada ni techo exterior de la casa. El keyframe nuevo del Plano 07
   (`07_nave_revelada.txt`) resuelve esto **de forma provisional**, describiendo el patio de manera
   genérica en el texto del prompt (césped o deck simple, un borde de pared exterior con la misma
   ventana del living) — mismo criterio ya usado para la "ropa de casa" del punto 1. Recomendación:
   si algún capítulo futuro necesita otra escena de exterior, o si el resultado de este plano no
   convence al PO, `disenador-personajes` debería producir una ficha y ancla canon de
   "patio/exterior de la casa" (mismo tratamiento que `casa_living_referencia.png`) en vez de
   seguir describiéndolo suelto, plano a plano.

## Nota para `guionista` — ajuste sugerido de la acotación del Beat 6 (no aplicado aquí)

La acotación actual de `docs/guiones/escena_intro.md` (Beat 6) dice: *"se corre una 'cortina'
imaginaria de luz y aparece flotando junto a la ventana la nave-estrella..."* — describe una
**revelación instantánea** (una cortina que se corre y la nave ya está ahí), no un desplazamiento
físico continuo. La nueva puesta en escena pedida por el PO (la nave desciende del cielo hasta el
patio) es, en cambio, **un movimiento continuo de varios segundos** — compatible en el fondo con el
punto de llegada (la nave sigue terminando "junto a la ventana", ahora vista desde el patio en vez
de aparecer de golpe adentro), pero el mecanismo narrado ya no es el mismo. Sugerencia de texto
(para que el PO lo derive a `guionista` — **yo no la aplico**, no me corresponde editar el guion):
reemplazar la frase de la "cortina de luz" por algo como *"un brillo cálido aparece en el cielo del
atardecer; la nave-estrella desciende despacio hasta posarse en el patio, justo junto a la ventana
del living"* — conserva el mismo punto de llegada y las mismas salvaguardas de tono (mágico, cálido,
sin apuro, GDD §6), solo cambia el verbo de "aparecer de golpe" a "descender". No es bloqueante
para generar el Plano 07 (este storyboard ya asume el descenso), pero el texto del guion queda
desalineado con la puesta en escena real hasta que se corrija.

## Notas de continuidad para `dev-godot`

- El plano 07 fue el piloto elegido para validar el flujo completo de video (fal.ai →
  `assets/generadas/cinematicas/intro/` → revisión → `assets/cinematicas/intro/` → reproducción en
  Godot con `Audio.reproducir_voz` por id de línea). El pipeline técnico quedó validado
  (30-Ago-2026) recién en el **cuarto intento de keyframe**, tras dos rechazos reales del PO:
  1. **1er intento**: `nave_estrella_referencia.png` directo como imagen base de video (sin
     keyframe nuevo) — se leyó como animar un ícono de pantalla de mejoras, no una toma narrativa.
  2. **2do/3er intento** (nueva puesta en escena: nave descendiendo del cielo al patio): el
     keyframe generado con FLUX.2 traía las líneas punteadas doradas de "pieza faltante" (heredadas
     sin querer de `nave_estrella_referencia.png`) leyéndose como alas reales dibujadas, y luego —
     tras corregirlas — como una cuerda/amarre atada a la nave. Corregido con dos ediciones
     dirigidas (`fal-gpt2`) sobre la misma imagen en vez de regenerar de cero.
  3. **Orientación horizontal rechazada**: el PO pidió explícitamente que la nave descienda
     **vertical** (proa/cúpula arriba, propulsores abajo, estilo aterrizaje de un booster Falcon 9),
     no acostada. Una regeneración completa con FLUX.2 pidiendo la reorientación **perdió identidad
     del diseño** (objetos inventados dentro de la cúpula, aletas nuevas a los costados que volvían
     a leerse como alas, materiales genéricos) — **lección para futuros planos que necesiten una
     pose/ángulo nuevo de un asset ya aprobado**: no pedirle a FLUX.2 una reinterpretación libre
     partiendo del prompt de texto; anclar con `fal-gpt2` sobre la ÚLTIMA imagen ya correcta y
     pedirle *solo* el cambio de orientación, preservando todo lo demás explícitamente — igual
     razonamiento que ya dejó registrado `docs/stack-tecnico.md` (decisión del 23-Jul-2026) sobre
     por qué generar un ángulo/vista nueva de un personaje no es una operación de "rotar la imagen":
     el modelo re-dibuja desde su interpretación del texto, no reproyecta el arte existente, así que
     cuanto menos margen de reinterpretación se le deje, mejor se sostiene la identidad.
  - **Keyframe final aceptado**: `assets/generadas/cinematicas/intro/07_nave_revelada_final.png`
    (nave vertical, propulsores redondos abajo con su chorro de escape, sin alas, sin objetos
    dentro de la cúpula, patio despejado sin muebles en la trayectoria de aterrizaje). El PO aceptó
    esta versión con fatiga del proceso de iteración — no se sometió a una ronda adicional de
    pulido fino (ej. el parche ovalado del frente del casco, o que el aterrizaje sigue detrás de la
    mesa de patio con un halo de tierra removida) porque no viola ninguna regla explícita (a
    diferencia de las alas, que sí eran una regla explícita repetida). Si en una revisión posterior
    (UX/PO) se decide pulir esos detalles menores, tratarlos como corrección dirigida puntual sobre
    esta misma imagen, no como una regeneración nueva.
  - **Clip de video final**: `assets/generadas/cinematicas/intro/07_nave_revelada.mp4` (Kling v3,
    generado desde el keyframe final aceptado, con `07_nave_revelada_video.txt` — descenso
    propulsado continuo con quema de frenado intensificándose cerca del suelo, aterrizaje suave
    explicado por el propio empuje de los motores, sin estela mágica de chispitas).
  - **Recomendación operativa para el resto de los planos [V] de esta escena** (02, 04, 06, 10):
    dado lo que costó este plano sin personajes, los planos con personajes deberían presupuestar
    más margen de iteración, y aplicar la misma disciplina de "corrección dirigida sobre la última
    imagen buena" en vez de regenerar de cero ante cualquier defecto puntual.
  - **Plano 07: APROBADO por el PO (30-Ago-2026).** Promovido a
    `assets/cinematicas/intro/07_nave_revelada.png` y `assets/cinematicas/intro/07_nave_revelada.mp4`.
    Nota de proceso: esta aprobación fue directa del PO, sin pasar primero por la auditoría de
    `experto-ux-parvulo` que el flujo estándar de este documento pide (§"Cómo vamos a generar esta
    escena", regla 10) — quedó salteada en esta pasada piloto. No es bloqueante (la aprobación del
    PO es la autoridad final), pero si se quiere la auditoría de tono/legibilidad completa antes de
    integrarlo en Godot, sigue pendiente hacerla.
- Los archivos finales de cada plano (una vez aprobados) deberían vivir en
  `assets/cinematicas/intro/` (fuera de `assets/generadas/`, que es solo staging con `.gdignore`),
  siguiendo el mismo criterio de promoción que el resto del arte generado.
