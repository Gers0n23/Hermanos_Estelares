# Ficha de nivel — Emparejar / Estrella / "Los ponys mágicos" (piloto)

> ⚠️ **NIVEL PILOTO / PRUEBA DE PROCESO** (18-Jul-2026). Se diseñó para ejercitar el flujo
> `disenador-mecanicas` → `disenador-niveles` → `dev-godot` → `experto-ux-parvulo` →
> `tester-qa` sobre el motor "emparejar" (`docs/fichas/motor-emparejar.md`), ya validado como
> piloto. **No es contenido del planeta 1 definitivo** — eso depende de cerrar HE-D1 con la
> ficha completa de Nicole (GDD, Fase 0). El tema (ponys mágicos) es contenido real tomado de
> los gustos confirmados de Sofía, así que si el pipeline aprueba este nivel podría reciclarse
> tal cual en un planeta futuro, pero hoy su función es probar el proceso, no cerrar diseño de
> capítulo.

- **Autor**: `disenador-niveles`
- **Estado**: piloto — pendiente de implementación (`dev-godot`), auditoría UX y QA
- **Archivo de datos**: `datos/niveles/piloto_emparejar_estrella_01.json`
- **Motor**: emparejar (`docs/fichas/motor-emparejar.md`)
- **Perfil**: Estrella — Sofía (8 años)
- **Referencia GDD**: §1 (tono/derrota-gag), §5 (rutas y reglas por perfil), §6 (UX obligatoria)

---

## 1. Objetivo del nivel

Encontrar los 8 pares de ponys mágicos ocultos en el tablero, en modo memoria real (dorso
tapado), dentro de un límite de intentos holgado que da sentido a un puntaje de 1-3
estrellitas. Un reto genuino de memoria de trabajo, sin ayudas automáticas.

## 2. Tema y por qué conecta con Sofía

Sofía puso **ponys** como su animal favorito (ficha `docs/perfil-jugadores.md`) y pidió
explícitamente que lo fácil le resulte "de bebés" — necesita reto real. Este nivel usa 8
ponys mágicos, cada uno con un elemento/color distinto (fuego, nieve, bosque, mar, cristal,
pegaso rosa, unicornio turquesa — sus dos colores favoritos confirmados) para que el tablero
tenga variedad visual suficiente para exigir memoria real a los 8 años, no solo repetición de
un mismo sprite. La estética general apunta a su gusto por lo *kawaii-mágico* (My Melody,
escuela de magia estilo Harry Potter) sin copiar ninguna IP: son ponys de fantasía con
elementos naturales, no personajes con nombre.

No se incluyen arañas, bichos ni ningún elemento que le genere rechazo (ficha, "qué la asusta
o aburre").

## 3. Motor y modo

- Motor: `emparejar`.
- Modo: `identico`, `oculto: true` (memoria real) — el par obligatorio para Estrella según
  §5 de la ficha de motor.
- `tiempo_volteo_ms: 850` — dentro del rango de reto genuino (~800-900 ms) que especifica la
  ficha de motor para Estrella.
- `limite_intentos: 16` (el doble de los 8 pares) — holgado como pide la regla de escalado
  para Estrella ("recomendado definir uno holgado para dar sentido al puntaje de estrellas"),
  nunca imposible de completar para 8 años.
- Sin ayudas automáticas ni resaltados: Sofía puede pedir que Cometa repita la instrucción
  tocándola, pero el tablero completo está disponible desde el inicio (GDD §6.2, §5).

## 4. Elementos y disposición

- Disposición: grilla 4×4 (16 cartas = 8 pares), dentro del rango 6-10 pares de Estrella y
  por debajo del límite de riesgo de hitbox señalado en §8 de la ficha de motor (10 pares en
  tablets chicas).
- 8 pares de ponys mágicos: pegaso rosa, unicornio turquesa, pony de fuego, pony de nieve,
  pony de bosque, pony de mar, pony de cristal, y un **pony arcoíris legendario** (ver
  momento memorable, §7).
- Dorso común temático: silueta de estrella con crin de pony (`dorso_estrella_pony.png`),
  no el dorso genérico del motor — refuerza el tema sin costar assets extra (es un solo
  sprite reutilizado en las 16 cartas).

## 5. Escalado aplicado (regla Estrella, ficha de motor §5)

| Parámetro | Valor en este nivel | Regla Estrella |
|---|---|---|
| Pares | 8 | 6-10 ✅ |
| `oculto` | `true` | memoria real ✅ |
| `tiempo_volteo_ms` | 850 | 800-900 ✅ |
| `limite_intentos` | 16 | holgado, no bloquea ✅ |
| Ayudas automáticas | ninguna | sin resaltado gratuito ✅ |

## 6. Gag de derrota

Si Sofía agota los 16 intentos sin completar el tablero (algo poco probable con el límite
holgado, pero posible si se dispersa): las 16 cartas se sueltan de la grilla y **salen
galopando en círculo** al ritmo de una musiquita tonta de banjo, tropiezan con sus propias
crines y caen en una pila de patas para arriba, relinchando de risa. Cometa comenta algo
como "¡jaja, se marearon dando vueltas! vamos, las ordenamos de nuevo". Los pares que Sofía
ya había acertado quedan resueltos (no los repite); el tablero se reinicia solo con los pares
pendientes. Botón gigante "¡otra vez!" aparece de inmediato sobre la animación.

Esto respeta el riesgo principal de su ficha ("se frustra y llora rápido"): el fallo es un
chiste visual sin marcador de errores ni presión narrativa, y el reintento es de un toque.

## 7. Momento memorable

El octavo par no es un pony más: es el **pony arcoíris legendario**, con crin que cambia de
color y un brillo distinto al resto. No se anuncia — Sofía lo descubre al voltear la primera
carta de ese par. Cuando completa ese par en particular, la línea de voz de acierto es única
(no la del pool aleatorio general) y dispara una micro-celebración extra: un arcoíris corto
cruza el tablero. Es el tipo de detalle que un niño de 8 años comenta después ("¡encontré el
pony secreto!") y le da una razón para rejugar el nivel buscando "descubrirlo antes".

## 8. Líneas de voz necesarias (para `guionista`)

Todas en español neutro/cálido, tono cómplice con Sofía (no infantilizado — ella "lee
contextos pensados para niños mayores").

| Clave | Ruta | Texto sugerido |
|---|---|---|
| `intro` | `voces/emparejar/estrella_ponys/intro_01.ogg` | "Estos ponys mágicos se escondieron detrás de sus estrellas. ¿Los recuerdas todos, Sofía? A ver esa memoria de líder." |
| `pista` | `voces/emparejar/estrella_ponys/pista_01.ogg` | "¿Necesitas una pista? Tócame a mí, Cometa, y te recuerdo dónde iba ese." |
| `acierto_par_01` | `voces/emparejar/estrella_ponys/acierto_par_01.ogg` | "¡Ese par! Sabía que lo tenías." |
| `acierto_par_02` | `voces/emparejar/estrella_ponys/acierto_par_02.ogg` | "¡Memoria de campeona!" |
| `acierto_par_03` | `voces/emparejar/estrella_ponys/acierto_par_03.ogg` | "Uno menos, ¡vas muy bien!" |
| `no_es_este_01` | `voces/emparejar/estrella_ponys/no_es_este_01.ogg` | "Casi... ese no era, pero ya casi lo tienes." |
| `no_es_este_02` | `voces/emparejar/estrella_ponys/no_es_este_02.ogg` | "Todavía no, ¡pero ya sabes dónde no está!" |
| `acierto_par_secreto` (extra, fuera del pool aleatorio, ligada al par `pony_arcoiris_secreto`) | `voces/emparejar/estrella_ponys/acierto_par_secreto_01.ogg` | "¡¿El pony arcoíris legendario?! Muy pocos lo encuentran, Sofía." |
| `victoria_final` | `voces/emparejar/estrella_ponys/victoria_final_01.ogg` | "¡Encontraste a todos los ponys mágicos! Con esa memoria, vas a liderar la misión sin problema." |
| `derrota_gag` | `voces/emparejar/estrella_ponys/derrota_gag_01.ogg` | "¡Jaja, se marearon dando vueltas y se cayeron todas patas arriba! Vamos, las ordenamos de nuevo." |

> Nota para `guionista`: la línea `acierto_par_secreto` no forma parte del contrato mínimo
> del motor (§4 de la ficha de motor solo define un array `acierto_par` genérico). Si
> `dev-godot` confirma que puede engancharse una línea especial al `id_pareja` puntual
> `pony_arcoiris_secreto` (vía la señal `par_acertado(id_pareja)` que ya expone el motor), se
> usa esta ruta; si no es viable en el piloto, cae al pool genérico sin perder el nivel.

## 9. Assets pendientes (para `disenador-personajes` / arte)

- 8 sprites de pony (placeholder aceptable en el piloto): `pony_pegaso_rosa.png`,
  `pony_unicornio_turquesa.png`, `pony_de_fuego.png`, `pony_de_nieve.png`,
  `pony_de_bosque.png`, `pony_de_mar.png`, `pony_de_cristal.png`,
  `pony_arcoiris_legendario.png` (este último con un tratamiento visual claramente distinto
  — crin multicolor / brillo — para que el descubrimiento del §7 se note).
- 1 sprite de dorso temático: `dorso_estrella_pony.png`.
- 1 fondo: `fondo_pradera_estelar_ponys_01.png` (placeholder aceptable).
- Anfitrión: se usa `cometa` (ya existente en el proyecto) para no depender de un
  personaje de planeta aún no definido.

## 10. Validación esperada

- **`dev-godot`**: cargar este JSON en la escena del motor "emparejar" ya implementada;
  confirmar que 8 pares / 4×4 no bajan el tamaño táctil de cada carta de 64 px lógicos en
  la resolución base (riesgo #4 de la ficha de motor).
- **`experto-ux-parvulo`**: validar que 850 ms de volteo es reto real sin frustrar a Sofía
  (riesgo #3, extrapolado a Estrella) y que el gag de derrota no genera ansiedad de "tener
  que" reintentar (riesgo #8, extrapolado).
- **`tester-qa`**: humo del flujo completo con este contenido: intro → volteo → acierto/no
  es este → pista opcional → par secreto → derrota-gag (forzando agotar intentos) →
  reintento → celebración final con pose de Sofía (mano en cintura, signo de la paz, guiño).
