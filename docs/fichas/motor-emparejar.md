# Ficha de motor — Emparejar

> ⚠️ **MOTOR PILOTO / PRUEBA DE PROCESO** (18-Jul-2026). Esta ficha se produjo como ejercicio de
> humo del flujo `disenador-mecanicas` → `dev-godot` → `experto-ux-parvulo` → `tester-qa`, con
> **contenido placeholder**. No corresponde al planeta 1 definitivo (eso depende de cerrar
> HE-D1 con la ficha completa de Nicole, ver GDD P5). El motor en sí, una vez validado por el
> pipeline, **queda reutilizable para contenido real** — es lo que se está probando: que la
> mecánica pura (agnóstica de tema) sirva igual para dinosaurios, ponys o lo que se decida.

- **Autor**: `disenador-mecanicas`
- **Estado**: piloto — pendiente de implementación (`dev-godot`), auditoría UX y QA
- **Referencia GDD**: §5 (motores compartidos, ejemplo "emparejar"), §6 (UX obligatoria), §1 (tono/derrota-gag), §8 (alcance negativo)
- **06-Oct-2026**: el PO aprobó las mejoras de reto (racha, vistazo, cartas especiales, camino de
  colores y colección), detalladas en el **§10**, y el **modo equipo** (`docs/fichas/modo-equipo.md`).

---

## 1. Mecánica núcleo (una frase)

Tocar dos elementos del tablero que forman un par (iguales o correspondientes entre sí) para
que se junten y celebren; se repite hasta completar todos los pares.

---

## 2. Cómo funciona (agnóstico de tema)

El tablero muestra un conjunto de **elementos emparejables**, dispuestos en una grilla o
composición libre. Cada elemento pertenece a un par. Hay dos modos, ambos parte del mismo
motor (se elige por nivel, ver contrato §4):

- **Modo visible** (`oculto: false`): todos los elementos están a la vista desde el inicio.
  No exige memoria de trabajo — es reconocimiento visual puro, apto desde Semilla.
- **Modo memoria** (`oculto: true`): los elementos empiezan con su dorso hacia arriba (un
  mismo motivo genérico de dorso); tocar uno lo voltea y lo muestra un momento; si no se
  completa el par a tiempo, vuelve a taparse. Exige memoria de trabajo corta — solo
  Brote/Estrella.

El emparejamiento puede ser por **igualdad** (dos dinosaurios iguales) o por
**correspondencia** (un animal y su sonido, un objeto y su sombra) — el motor no distingue,
solo compara el `id_pareja` de cada elemento tocado.

---

## 3. Interacciones (tiempos y feedback)

Todo tocable responde en **<100 ms**, según GDD §6.4.

| Paso | Interacción | Feedback inmediato (<100 ms) | Feedback resuelto (tras 2º toque) |
|---|---|---|---|
| 1 | Tocar el primer elemento | Pulso de escala (squash & stretch leve), halo de selección, sonido "pop" suave | — |
| 2a | Tocar un segundo elemento que **sí** completa el par | Igual pulso al tocar | **Micro-celebración de par** (§5): ambos elementos saltan uno hacia el otro, se funden en un destello/estrellita, chispa + confeti localizado, "ding" alegre, línea de voz aleatoria corta |
| 2b | Tocar un segundo elemento que **no** completa el par | Igual pulso al tocar | **Feedback amistoso de "no es este"** (§6): ambos elementos hacen un meneo de cabeza/rebote suave (nunca tiemblan como error), sonido corto neutro-alegre (nunca buzzer), se deseleccionan solos tras ~500 ms, listos para reintentar |
| 3 | Tocar el elemento ya seleccionado (deselección voluntaria) | Vuelve a su estado normal con el mismo pulso, sin penalidad ni conteo de intento | — |
| 4 | (Modo memoria) elemento volteado sin completar par a tiempo | — | Se tapa de nuevo con una animación de giro suave (~400 ms), nunca abrupta |
| 5 | Completar todos los pares del tablero | — | **Celebración final** (§5): confeti de pantalla completa, bailecito del anfitrión, gesto de celebración del personaje jugador (ver `docs/perfil-jugadores.md`), sonido de victoria, conteo animado de destellos ganados, línea de voz de cierre |

> **Nota de implementación (13-Sep-2026, demo jugable del Planeta Arcoíris — pendiente de validar por
> `disenador-mecanicas`)**: la fila 4 cambió porque en la práctica hacía el nivel casi injugable (la
> primera carta se tapaba sola a los 850 ms, antes de alcanzar a tocar la segunda). Ahora la primera
> carta queda a la vista hasta tocar la segunda; `tiempo_volteo_ms` es cuánto quedan visibles las dos
> cartas de un "no es este" antes de taparse, y tocar cualquier carta en ese lapso las tapa al tiro y
> cuenta como primer toque de la jugada siguiente. En modo memoria, tocar de nuevo la carta ya
> volteada no la tapa (evita perder lo visto por un doble toque). Campos nuevos del contrato §4:
> `figura`/`color` por elemento (figura dibujada por código mientras no hay sprite), `especial` por
> par (momento memorable con voz `acierto_especial`), `ayuda_tras_fallos` (Brote) y `halo_idle` (Semilla).
> Niveles por hermano: `datos/niveles/arcoiris_emparejar_{semilla,brote,estrella}_01.json`.

> **Validación HE-40 — disenador-mecanicas (28-Sep-2026, PROPUESTA)**: **se aprueba** el cambio de la
> fila 4. `tiempo_volteo_ms` pasa a significar "cuánto se ve el par fallido". Además:
>
> - `visible_minimo_ms` (Brote 600): los toques que llegan antes quedan en espera.
> - La pista de Sofía revela la compañera de la carta que está arriba.
> - Se usan el medidor de estrellitas y la confirmación de pista.
>
> Detalle en `docs/validaciones/HE-40_disenador-mecanicas.md`, hallazgos 10-12.

Entrada: solo toque/clic (sin arrastre en este motor — GDD §6.4). Si el input unificado
detecta un gesto de arrastre iniciado sobre un elemento, se trata como un toque simple sobre
el punto de origen (no se implementa drag, para no confundir con otros motores).

---

## 4. Contrato de datos (archivo de nivel → motor)

El motor es genérico; `disenador-niveles` provee el contenido en `datos/` siguiendo esta
estructura (JSON, nombres de campo en español, sin acentos):

```jsonc
{
  "id_nivel": "piloto_emparejar_01",
  "motor": "emparejar",
  "perfil": "semilla",                 // "semilla" | "brote" | "estrella"
  "tema": "dinosaurios",               // referencia libre, usada en pistas de voz/UX
  "modo": "identico",                  // "identico" | "correspondencia"
  "oculto": false,                     // true = modo memoria (solo brote/estrella)
  "disposicion": { "filas": 2, "columnas": 3 },  // o "libre" con posiciones explícitas
  "anfitrion_id": "coco",              // personaje que narra este nivel (opcional)
  "fondo_id": "planeta_arcoiris_fondo01",
  "limite_intentos": null,             // null = infinito (semilla siempre null); entero = reto (brote/estrella)
  "tiempo_volteo_ms": 1200,            // solo aplica si oculto=true: cuánto dura visible antes de re-tapar
  "lineas_voz": {
    "intro": "voces/emparejar/intro_dino_01.ogg",
    "pista": "voces/emparejar/pista_dino_01.ogg",       // se usa tras N intentos sin acierto (solo brote/estrella)
    "acierto_par": [                                     // array: el motor elige una al azar por par
      "voces/emparejar/acierto_par_01.ogg",
      "voces/emparejar/acierto_par_02.ogg"
    ],
    "no_es_este": [                                      // opcionales; si se omite, solo suena SFX
      "voces/emparejar/no_es_este_01.ogg"
    ],
    "victoria_final": "voces/emparejar/victoria_dino_01.ogg",
    "derrota_gag": "voces/emparejar/derrota_gag_dino_01.ogg"  // solo si limite_intentos != null
  },
  "pares": [
    {
      "id_pareja": "trex",
      "elemento_a": { "id": "trex_a", "sprite": "sprites/dinos/trex.png" },
      "elemento_b": { "id": "trex_b", "sprite": "sprites/dinos/trex.png" },
      "sprite_dorso": "sprites/comun/dorso_estrella.png"   // solo si oculto=true
    },
    {
      "id_pareja": "spinosaurio",
      "elemento_a": { "id": "spino_a", "sprite": "sprites/dinos/spinosaurio.png" },
      "elemento_b": { "id": "spino_b", "sprite": "sprites/dinos/spinosaurio.png" },
      "sprite_dorso": "sprites/comun/dorso_estrella.png"
    }
  ]
}
```

Notas del contrato:

- El motor **nunca** lee texto de estos campos en pantalla para instruir — todo lo narrado
  vive en `lineas_voz.*` (GDD §6.2). El campo `tema` es solo metadato de diseño.
- Para `modo: "correspondencia"`, `elemento_a` y `elemento_b` llevan sprites distintos (p. ej.
  perro + hueso) pero comparten `id_pareja`.
- `pares.size()` define la cantidad de pares del nivel — el escalado por perfil (§5) se logra
  variando esta cantidad, `oculto` y `limite_intentos` desde el archivo de nivel, sin tocar
  el motor.
- El motor expone la señal estándar `completado(destellos)` del contrato de
  `minijuego_base.gd` (stack técnico §2); además emite señales internas útiles para
  animación/celebración de personajes: `par_acertado(id_pareja)`, `intento_fallido()`,
  `nivel_fallado()` (solo si aplica derrota-gag) y `carta_intercambiada(a, b)`.

### Campos nuevos para Sofía (dificultad v3, decisión del PO del 14-Sep-2026)

#### Grupos y tríos

- `tamano_grupo` (2 por defecto; 3 = tríos) con `grupos: [{id_grupo, especial, elementos: [...]}]`.
  `pares` con `elemento_a`/`elemento_b` sigue funcionando.
- El turno termina en la primera carta que no coincide con la primera, o al completar el grupo.

#### Estilo de las cartas

- `estilo` por elemento:
  - `""`: figura a color.
  - `"sombra"`: silueta oscura sin carita.
  - `"receta"`: gotas de los colores de `receta` unidas por "+".
- `forma` por elemento: una forma de `geometria_formas.gd` (`triangulo_rect`, `paralelogramo`,
  `semicirculo`, `trapecio`) en lugar de `figura`.
- `rotacion` y `espejo` por elemento. Con ellos se arman las trampas: dos sombras iguales salvo el espejo
  son parejas distintas. El QA verifica que ninguna sombra de un nivel sea idéntica a otra.

#### Reglas del nivel

- `intercambios_tras_acierto`: cartas traviesas. Tras cada acierto, N parejas de cartas tapadas cambian
  de lugar con un vuelo visible de 0,6 s.
- `pistas_cuestan_estrellita`: botón de estrella dorada de 96 px arriba a la derecha. Destapa un
  momento una pareja pendiente (voz `pista_usada`) y resta una estrellita, sin bajar de 1.
- `regalo_tras_derrotas`: tras la 2.ª derrota-gag, al tocar "¡otra vez!" Coco da por encontrado un
  grupo (voz `regalo`). Una sola vez, sin costo de estrellitas.

### Campos nuevos para Maxi y Nicole (rondas y temas, decisión del PO del 27-Sep-2026)

#### Rondas

- `rondas: [ {...} ]`: cada ronda pisa los campos del nivel que traiga (`pares`, `disposicion`, `oculto`,
  `tiempo_volteo_ms`, `ayuda_tras_fallos`, `cartas_bailan`, `modo`...). Sus `lineas_voz` se mezclan con las
  del nivel. `intro_ronda` es la consigna que se dice al empezar la ronda; tocar a Coco la repite.
- `pool` + `cantidad`: la ronda sortea `cantidad` parejas del pool en cada partida. Las marcadas con
  `fijo: true` siempre entran (p. ej., la bandera de Chile).
- Entre rondas hay mini-fiesta: confeti, Coco baila, voz `ronda_superada` (varias variantes), las cartas se
  despiden y llega el tablero nuevo. Arriba se ve una estrella por ronda (apagada, la actual encendida y las
  ganadas doradas). Durante la mini-fiesta los toques no hacen nada.
- `completado(destellos)` se emite una sola vez al final: 10 destellos por pareja de todas las rondas.
- Un nivel sin `rondas` se juega igual que antes (Sofía y retos dorados no cambian).

#### Parejas y cartas

- `cartas_bailan: N`: tras cada acierto, N pares de cartas **a la vista** cambian de lugar despacito
  (1,4 s, meciéndose). Es atención, no memoria (Maxi, zona 5).
- `voz` por pareja: al formarla se dice esa línea en vez del acierto genérico ("¡Chile!", "¡Ese de sol!",
  "¡Amarillo, como la jirafa!").
- Por elemento:
  - `escala`: tamaño del dibujo. En "mamá y bebé" se usan 1 y 0,55.
  - `estilo: "letra"` + `letra`: la carta muestra la letra mayúscula.
  - `voz_toque`: se dice al tocar la carta (el nombre de la letra).
- Dibujos nuevos por código (`scripts/motores/emparejar/dibujos_emparejar.gd`, estilo "peluche pintado"):
  - Maxi: `trex`, `spinosaurio`, `carnotauro`, `huevo`, `auto`, `bus`, `bomberos` y `cohete`.
  - Nicole: `jirafa`, `pony`, `gatito`, `vestido`, `zapato`, `corona` y `mono`.
  - Otros: `sol`, `hoja` y `mancha` (una mancha de pintura).
  - Banderas: `bandera_<pais>`, con 14 países (ver ficha de zonas §3.3).
- La figura que vuela a la barra es el dibujo: no la mancha, la letra ni la sombra. En "mamá y bebé" vuela
  la mamá.

---

## 5. Reglas de escalado por perfil

| | **Semilla (Maxi, 2 años)** | **Brote (Nicole, 5 años)** | **Estrella (Sofía, 8 años)** |
|---|---|---|---|
| Cantidad de pares | 2-3 | 4-6 | 10-18, o 7 tríos (v3, 14-Sep-2026: ver nota bajo la tabla) |
| `oculto` (memoria) | Siempre `false` — todo visible, sin carga de memoria de trabajo | Opcional; si se usa, `tiempo_volteo_ms` generoso (≥1200 ms) | Sí, modo memoria real; `tiempo_volteo_ms` más ajustado (~800-900 ms) para reto genuino |
| Ritmo/tiempo | Sin ritmo — cero presión, cualquier orden vale | Ritmo suave opcional vía `limite_intentos` (reto blando, no cronómetro visible) | Puede sumar cronómetro de juego (no narrativo) para el puntaje de estrellas — nunca bloquea, solo puntúa |
| Ayudas visuales | Halo pulsante constante en los elementos tocables; imán/hitbox extra generoso (≥96 px lógicos, GDD §6.1); un solo objetivo resaltado a la vez si `anfitrion_id` lo narra | Pista por voz tras 2-3 intentos fallidos consecutivos sobre el mismo par (`lineas_voz.pista`); resaltado sutil del segundo elemento si sigue sin encontrarlo tras la pista | Sin ayudas automáticas — puede pedir pista tocando a Cometa (repite instrucción, GDD §6.2), pero no hay resaltado gratuito: el reto es real |
| `limite_intentos` | Siempre `null` | Opcional (config del nivel); si se define, activa derrota-gag | Recomendado definir uno holgado para dar sentido al puntaje de estrellas |
| Fallo posible | **No existe** (§6) | Sí, si el nivel lo configura — derrota-gag suave | Sí — derrota-gag + puntaje 1-3 estrellas según intentos/tiempo |
| Objetivo a la vez | Sí, implícito (cualquier toque produce algo bueno) | Sí, explícito: la instrucción de voz nombra un elemento o pista a la vez (GDD §5) | No aplica — puede manejar el tablero completo a la vez |

**Estrella v3: cómo se fijaron los límites.** Se simuló una jugadora de 8 años con memoria visual de
~5 cartas (normas de Corsi por edad) que juega bien: usa lo que recuerda y olvida lo más antiguo. Con
3.000 partidas por nivel, el límite de fallos es aproximadamente el percentil 80. Así 3 estrellitas
(fallos ≤ la mitad del límite) exigen jugar mejor que la mediana.

| Nivel | Fallos: mediana | Percentil 80 | Límite |
|---|---|---|---|
| 12 pares | 13 | 16 | 16 |
| 10 recetas | 12 | 15 | 15 |
| 7 tríos | 29 | 43 | 42 |
| 14 pares traviesas | 19 | 24 | 24 |
| 16 sombras | 26 | 32 | 32 |
| 18 sombras (dorado) | 34 | 42 | 42 |

Las sombras con trampa se modelan con 8 % de confusión y las traviesas con 50 % de olvido de cada
carta movida. La idea es afinar los límites con el playtest.

**Recalibración con el vistazo (07-Oct-2026, HE-60, QA M3)**. El vistazo de §10.2 baja los fallos.
`herramientas/calibrar_parejas_sofia.py` midió cuánto corre el p25 y el p80 de fallos, y ese corrimiento se
restó a los valores de HE-40 (`dos` = límite). Están aplicados en los JSON. El detalle está en
`calibracion-batalla-arcoiris-y-parejas-equipo.md` §11.

| Nivel | Fallos con vistazo: p25 / p50 / p80 | Límite (antes → ahora) | `tres` (antes → ahora) | 3★ / derrota con vistazo |
|---|---|---|---|---|
| 12 pares | 9 / 11 / 14 | 16 → **14** | 10 → **9** | 34 % / 18 % |
| 10 recetas | 5 / 7 / 9 | 15 → **13** | 9 → **7** | 60 % / 2 % (fácil: propuesta 10 · 5 al PO) |
| 7 tríos | 17 / 23 / 32 | 42 → **41** | 17 → **16** | 22 % / 8 % |
| 14 traviesas | 14 / 17 / 21 | 24 → **22** | 15 → **14** | 30 % / 15 % |
| 16 sombras | 19 / 23 / 29 | 32 → **31** | 21 → **19** | 28 % / 11 % |
| 18 sombras (dorado) | 26 / 31 / 38 | 42 → **41** | 27 → **26** | 30 % / 10 % |

---

## 6. Diseño del fallo

- **Toque que no completa un par (todos los perfiles)**: nunca es "error" — es simplemente
  "todavía no". Los dos elementos hacen un rebote/meneo simpático, sonido corto y alegre
  (nunca buzzer ni tono grave), se deseleccionan solos. Cero marcador de errores visible.
- **Semilla**: no hay concepto de "perder el nivel". Si toca elementos al azar sin formar
  pares, cada toque sigue produciendo el pulso y sonido agradable — el motor jamás fuerza fin
  de nivel por intentos agotados (`limite_intentos` siempre `null`).
- **Brote/Estrella con `limite_intentos` definido**: al agotar los intentos sin completar el
  tablero, se dispara la **derrota-gag** (GDD §1):
  - Ejemplo de gag (placeholder, a tematizar por `disenador-niveles`): las tarjetas/elementos
    se mezclan solos dando vueltas graciosas al ritmo de una musiquita tonta, el anfitrión se
    ríe con ellos, Cometa hace un comentario chistoso (`lineas_voz.derrota_gag`).
  - **Reintento de un toque**: botón gigante "¡otra vez!" aparece de inmediato sobre la
    animación del gag.
  - **Cero progreso perdido**: los destellos/piezas ya ganados en el juego no se tocan; dentro
    del intento, los pares que sí se habían acertado antes de fallar quedan visualmente
    resueltos al reiniciar (no se le hace repetir lo que ya logró) — el tablero se reinicia
    solo con los pares pendientes.
  - Nunca hay temporizador que presione narrativamente (GDD §1) — el `limite_intentos` es
    ritmo de juego, no una amenaza de la historia.

---

## 7. Diseño de la celebración

- **Micro-celebración por par** (cada acierto, todos los perfiles): los dos elementos saltan
  el uno hacia el otro, se funden en un destello/estrellita con una chispa de partículas,
  "ding" ascendente, línea de voz corta aleatoria (evita repetición monótona con 2-3
  variantes por nivel). Duración total ~600-800 ms, no bloquea poder seguir jugando.
- **Celebración final** (tablero completo):
  - Confeti a pantalla completa (partículas nativas de Godot, sin asset extra — stack §5).
  - El anfitrión del nivel hace su bailecito.
  - El personaje jugador (Maxi/Nicole/Sofía) ejecuta su **gesto real de celebración**
    (ficha `docs/perfil-jugadores.md`): Maxi salta con el puño arriba gritando "¡síii!",
    Nicole hace el corazón coreano con expresión tierna, Sofía hace su pose con signo de la
    paz y guiño — el motor solo emite la señal `completado(destellos)`; la animación concreta
    del personaje la implementa `dev-godot` con los assets de `disenador-personajes`.
  - Conteo animado de destellos ganados (número que sube con "tintineo").
  - Línea de voz de cierre (`lineas_voz.victoria_final`).
  - **Estrella únicamente**: además se anima un puntaje de 1-3 estrellitas (basado en
    intentos usados / tiempo, definido por `disenador-niveles` vía umbrales en el nivel —
    campo a agregar si se confirma esta variante, no incluido en el contrato mínimo de §4
    porque es piloto).

---

## 8. Riesgos de usabilidad (para auditoría de `experto-ux-parvulo`)

1. **Confusión entre estado "seleccionado" y "acertado"**: el halo de selección y la
   micro-celebración de acierto deben ser visualmente muy distintos (color/forma), o Maxi
   podría creer que ya ganó con solo tocar un elemento.
2. **Timing de auto-deselección (500 ms)**: validar que no se sienta "pegajoso" para Sofía
   (que quiere ir rápido) ni demasiado veloz para Maxi (dedos más lentos, riesgo de doble
   toque accidental antes de que se resetee).
3. **`tiempo_volteo_ms` en modo memoria**: confirmar que 1200 ms alcanza para que Nicole
   procese el elemento antes de que se tape — riesgo real de frustración si es muy corto.
4. **Tamaño de hitbox con muchos pares (Estrella, hasta 10)**: en tablets chicas, 10 pares en
   grilla podrían bajar el tamaño de cada elemento por debajo de los 64 px mínimos (GDD §6.1)
   — revisar límite real de columnas/filas por resolución.
5. **Doble toque accidental sobre el mismo elemento**: confirmar que tocar dos veces seguidas
   el mismo elemento lo deselecciona sin contar como "intento fallido" (evita frustración
   involuntaria, sobre todo en Brote con `limite_intentos`).
6. **Sonido de "no es este"**: verificar en playtest que ningún niño lo interprete como sonido
   de error/castigo — debe sentirse tan amistoso como el resto del audio del juego.
7. **Gesto de arrastre accidental**: con el input unificado táctil+mouse, un arrastre corto
   sobre un elemento no debería iniciar ningún comportamiento distinto al toque simple;
   confirmar que no se "pierde" el toque si el dedo se mueve un poco al tocar (hitbox de
   tolerancia).
8. **Derrota-gag en Brote**: confirmar con playtest que el gag elegido (mezcla graciosa de
   elementos) realmente da risa a los 5 años y no genera ansiedad por "tener que" volver a
   intentar — si hay duda, subir `limite_intentos` o quitarlo del nivel piloto.

---

## 9. Qué debe validar cada rol siguiente

- **`dev-godot`**: implementar el motor como escena reutilizable (`minijuego_base.gd` como
  base), cargando el JSON del contrato §4 y emitiendo las señales de §4/§7; smoke test con
  un nivel placeholder de cada perfil (semilla/brote/estrella).
- **`experto-ux-parvulo`**: auditar los 8 riesgos de §8 contra un build real, con foco en
  tamaños táctiles, timings y que el "no es este" nunca se sienta como error.
- **`tester-qa`**: playtest de humo (no con contenido final) validando el flujo completo:
  tocar → par correcto/incorrecto → derrota-gag (brote/estrella) → reintento de un toque →
  celebración final → señal `completado` recibida correctamente por el nodo padre.
- **`disenador-niveles`**: una vez el motor esté validado, reemplazar el contenido placeholder
  de este piloto por niveles reales, alineados a los gustos de cada hermano en
  `docs/perfil-jugadores.md` (y a lo que falte cerrar en HE-D1).

## Implementación dev-godot 28-Sep-2026 (validaciones HE-40, PROVISIONAL)

- §7: `umbrales_estrellitas {tres, dos}` en fallos (z1 10/16, z2 9/15, z3 17/42, z4 15/24, z5 21/32, dorado 27/42). Sin el campo, la regla vieja. **Reemplazados el 07-Oct-2026 por la recalibración con vistazo (§5): z1 9/14, z2 7/13, z3 16/41, z4 14/22, z5 19/31, dorado 26/41.**
- Pista con costo: medidor + globo de confirmación (`scripts/ui/pista_con_costo.gd`); si ya hay una carta arriba, la pista revela su compañera.
- `visible_minimo_ms` (Brote 600 por defecto): un toque durante el "no es este" queda en espera (la carta pulsa) y se aplica al cumplirse el mínimo.

---

## 10. Mejoras de reto: racha, vistazo, cartas especiales, camino de colores y colección (06-Oct-2026)

> **Decisión del PO (06-Oct-2026)**: tras investigar memorice populares, el PO aprobó **cinco mejoras**
> para Parejas de Coco. El objetivo es cumplir la regla del playtest del 03-Oct-2026: **reto real para
> Nicole y Sofía** (GDD §5, "Mecánicas probadas y reto real"). Hoy Nicole juega sin límite y sin poder
> perder, así que **la racha, el puntaje y el récord son su reto principal**.
>
> El modo equipo de este motor está en `docs/fichas/modo-equipo.md`.
>
> - **Marcas**:
>   - **[PO]** = decisión del PO;
>   - **[UX]** = corrección de la validación UX de HE-58
>     (`docs/validaciones/2026-10-06_ux-HE-58-modo-equipo-parejas.md`);
>   - **[Propuesta UX, por confirmar con el PO]** = cambia algo marcado [PO];
>   - **[Propuesta]** = de `disenador-mecanicas`.
> - **v2 (06-Oct-2026)**:
>   - incorpora las decisiones del PO del 06-Oct (Nicole con estrellitas por puntaje; Camino como reto
>     dorado de la zona 4; colección en la casita de Coco; récords en cero);
>   - incorpora las correcciones UX M6-M10 y los menores m6, m8, m9 y m10;
>   - incorpora las correcciones del `guionista` (`docs/guiones/voces-modo-equipo-parejas.md`).
>   
>   Los menores para `dev-godot` están en el §13 de `docs/fichas/modo-equipo.md`.
> - **Lenguaje visual**: se reutiliza el del Río de pintura (`docs/roadmap-rio-de-pintura.md` §3.3, §6 y
>   §9): tono que sube un semitono por acierto, nuditos de la cresta de Coco, ojos de estrella con
>   combo 3+, trofeo-cupcake del récord y presentación de cada novedad de a una.
> - **Lo que no cambia**:
>   - las estrellitas de Sofía siguen contando **fallos** (`umbrales_estrellitas`);
>   - Maxi sigue sin poder perder;
>   - un fallo **nunca resta puntos**: solo corta la racha.

### 10.1 Racha, "¡a la primera!", tiempo par y récord personal

**[PO]** Racha o combo, bono "¡a la primera!", tiempo par y récord personal por estación. Referencias:
*MatchBlitz*, *Flipout!* y el memorice de *New Super Mario Bros.* **[Propuesta]** Valores y forma:

**Puntaje de una partida** (en una estación con rondas, suma todas las rondas):

| Evento | Puntos | Feedback (< 100 ms) |
|---|---|---|
| Pareja formada | 100 × multiplicador de racha | El "ding" del par sube **un semitono por eslabón** (como el reventón del Río). Los números "+200" salen del par en el color de la carta y suben flotando 0,6 s. **Nunca se dibujan sobre cartas tapadas** (m10): suben desde el par que se va o se dibujan fuera de la grilla. Desde la racha ×2, la voz de racha (`racha_2` a `racha_5` y `racha_sigue`) **reemplaza** a `acierto_par`; no suenan las dos (`guionista`). Cuando la racha se corta no hay voz |
| Racha (pares seguidos sin "no es este") | Multiplicador ×1, ×2, ×3, ×4, ×5 (tope) | Junto a Coco, un **contador de racha** grande que rebota ("×3"). Cada eslabón **enciende un nudito de su cresta**, y con ×3 o más, ojos de estrella. Al cortarse, los nuditos se apagan de a uno con un "fiuu" suave, **sin sonido de error** |
| **"¡A la primera!"** (las dos cartas del par se dieron vuelta **por primera vez** en esa misma jugada: suerte pura) | +200, sin multiplicador | Estela dorada entre las dos cartas, campanita doble y sello "¡a la primera!" (un trébol dorado) que vuela al costado |
| **Tiempo par** (tablero completo antes de `tiempo_par_s`) | +10 por segundo que sobra | Se ve como una **vela de cumpleaños sobre un cupcake**, fuera del área de juego y de **menos de 80 px de alto**, que se consume. **[UX M7]**: sin tic-tac; no parpadea, no cambia de color y no acelera al final; y en Nicole **solo aparece si la estación ya tiene récord suyo** (la primera partida es para aprender), mientras que en Sofía aparece desde la primera partida. Si se acaba, la llama hace un "puf" suave y Coco dice algo positivo (voz `vela_dormida`, "¡la vela se fue a dormir, sigue tranquila!"); **no pasa nada más**. Si se termina el tablero antes, la vela sigue encendida y al final sus segundos se convierten en puntos con tintineo |
| Carta dorada (§10.3) | +500 y el próximo par vale doble | §10.3 |

- **Récord personal por estación** [PO], por hermano (`Progreso.records.<hermano>.<id_nivel>`, el mismo
  campo opcional que ya usa el Río):
  - **Durante la partida se ve sin leer**: a la derecha hay una **barra vertical de puntaje** con una
    **banderita-cupcake a la altura del récord**. Cuando la barra la pasa, la banderita salta, hay
    confeti chico y suena una palabra ("¡récord!"). **No se pausa el juego** (GDD §5: ritmo rápido).
  - **Al final**: "¡Nuevo récord!" con Coco sosteniendo el **trofeo-cupcake** (mismo asset que el Río).
  - **Sin récord previo (m6)**: no hay banderita, y al final suena "¡tu primer récord!".
  - **Los récords parten en cero [PO]**, también en las estaciones ya jugadas.
  - **Sin rankings entre hermanos** [PO]: cada uno compite con su propio récord, y el HUD nunca muestra
    el récord de otro.
- **En modo equipo no existe el bloque `puntaje` (M1)**: la racha va solo con sonido y la cresta en
  arcoíris. Ver `modo-equipo.md` §5.2.

**Por perfil** [Propuesta]:

| | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| Racha | **Solo sonido y cresta** (tono que sube, nuditos). Sin número ni puntaje | Completa: contador, multiplicador y nuditos | Completa |
| "¡A la primera!" | No (con cartas a la vista no aplica) | Sí | Sí |
| Tiempo par | No | **Desde la zona 2** (M7.4) y solo cuando ya hay récord (M7.1). Holgada: ≈ 1,5 veces lo que tarda una niña de 5 años que juega bien | Sí, desde la primera partida. Ajustada: ≈ 1,1 veces la mediana del jugador simulado |
| Récord | No | Sí, como **reto extra** [PO] | Sí, junto a las estrellitas |
| Estrellitas | No | **Sí, de 1 a 3 por puntaje [PO]** (§10.1.1) | Sin cambios: por fallos (`umbrales_estrellitas`). El puntaje y la vela **no** cambian las estrellitas de Sofía |

**Criterio para el playtest (M7.5)**: si Nicole mira la vela más que el tablero, o falla más cuando la
vela está por terminarse, se pone `tiempo_par_s: null` en los niveles Brote.

#### 10.1.1 Las estrellitas de Nicole por puntaje [PO: sí, de 1 a 3; Propuesta: umbrales y forma]

**Qué puntaje cuenta**: el **puntaje base**, que es la suma de pares × racha, "¡a la primera!", la
carta dorada y la revancha. **Sin el bono de la vela**, porque la vela no existe en la primera partida
(M7.1) y entonces sus estrellitas no serían comparables. En estaciones con rondas, el puntaje base
suma las 3 rondas.

**Umbrales** (campo `umbrales_puntaje: { "dos": X, "tres": Y }`, en puntos):

- **1 estrellita**: completar la estación. Nicole nunca pierde, así que **siempre tiene al menos 1**.
- **2 estrellitas**: puntaje base ≥ `dos`, que es la **mediana (p50)** de una jugadora simulada de 5
  años:
  - memoria visual de ~3 cartas, olvidando las más antiguas;
  - con el vistazo de M6 y las especiales de su zona;
  - 3.000 partidas por nivel, el mismo método que los límites de Sofía.
- **3 estrellitas**: puntaje base ≥ `tres`, el **percentil 80** de la misma simulación. Así 3
  estrellitas salen en ~1 de cada 5 partidas bien jugadas: igual de exigente que con Sofía (zonas §7.2).
- **Valores por defecto**, si el nivel no trae `umbrales_puntaje` (solo para que funcione mientras se
  simula): `dos = 150 × pares` y `tres = 230 × pares`, con `pares` = total de pares de todas las rondas,
  sin contar las especiales. `disenador-niveles` los reemplaza con el simulador.
- Si el nivel tiene `umbrales_puntaje`, la estación puntúa. Nicole no tiene `limite_intentos`, pistas
  con costo ni derrota, y eso no cambia.

**Que la estrellita 1 se sienta como un logro, no como un castigo**:

1. **Nunca se muestran huecos vacíos**: ni contornos ni "1 de 3". En la celebración aparecen **solo las
   estrellitas ganadas**, una por una (0,4 s cada una), cada una con su campanita y una nota más aguda.
2. **La primera estrellita es "la estrella de terminar"**: es la más grande, dorada, cae girando desde
   arriba y Coco la atrapa con la lengua y se la pega en la cresta. Tiene la misma animación que la 3,
   no una versión "chica".
3. **La voz habla del logro, nunca de lo que faltó**:
   - 1 estrellita: "¡Terminaste! ¡Una estrella brillante para ti!";
   - 2 estrellitas: "¡Dos estrellas! ¡Qué memoria!";
   - 3 estrellitas: "¡Tres estrellas! ¡Memoria arcoíris!".

   Nunca "solo una", "te faltó" ni "la próxima vez más".
4. **El incentivo para repetir va en el mapa, no en la celebración**: en la tarjeta de la estación se
   ven las estrellitas ganadas, y Coco **solo menciona otra estrellita si Nicole vuelve a entrar** a esa
   estación: "¡con una racha larga sale otra estrellita!". Lo dice como pista, no como reproche.
5. **Equidad (`perfil-jugadores.md`)**: Nicole y Sofía tienen **la misma animación, el mismo tamaño y
   el mismo sonido de estrellitas**. La diferencia está solo en cómo se ganan (puntaje o fallos), y
   ninguna pantalla muestra las de la otra.

**Para `dev-godot`**:

- `minijuego_base._estrellitas_visibles()` hoy devuelve 0 si el perfil no es `estrella`. Debe aceptar
  también **un nivel `brote` jugado por quien tiene perfil `brote`, cuando el nivel trae
  `umbrales_puntaje`**.
- El mapa del planeta ya muestra estrellitas por estación (`Progreso.obtener_estrellitas_nivel`).
  Debe mostrarlas también para Nicole.
- El botón de reto dorado (que aparece con 3 estrellitas) **no cambia**, porque Nicole no tiene
  `niveles_dorados`. La "zona perfecta" (corona) sigue siendo solo de Sofía hasta que el PO diga otra
  cosa.

**Voces nuevas** (encargo al `guionista`): las 3 líneas del punto 3, la del punto 4 y `vela_dormida`
(M7.3).

> **Conflicto con el guion**: la decisión 10 del guion dice que cuando la vela se apaga no hay voz. UX
> M7.3 pide que Coco diga algo positivo, y manda UX: se agrega `vela_dormida`.

**Contrato** [Propuesta]:

```jsonc
"puntaje": {
  "por_par": 100,
  "racha_tope": 5,
  "bono_a_la_primera": 200,
  "tiempo_par_s": 95,            // null = sin vela; en Brote solo aparece si ya hay récord (M7)
  "vela_desde_primera": false,   // true en Estrella
  "bono_por_segundo": 10,
  "mostrar": "barra"             // "barra" (Brote/Estrella) | "solo_sonido" (Semilla y siempre en equipo)
},
"umbrales_puntaje": { "dos": 1350, "tres": 2070 },  // solo Brote: estrellitas por puntaje base (§10.1.1)
"lineas_voz": {                  // se suman a las del nivel; ids del guion §6 (voces/arcoiris/emparejar/reto/)
  "racha": { "2": "…/racha_2.wav", "3": "…/racha_3.wav", "4": "…/racha_4.wav", "5": "…/racha_5.wav", "sigue": "…/racha_sigue.wav" },
  "a_la_primera": ["…/a_la_primera_01.wav", "…/a_la_primera_02.wav"],
  "record_pasa": "…/record_pasa.wav",
  "record_nuevo": ["…/record_nuevo_01.wav", "…/record_nuevo_02.wav"],
  "primer_record": "…/primer_record.wav",
  "vela_presenta": "…/vela_presenta.wav", "vela_encendida": "…/vela_encendida.wav", "vela_dormida": "…/vela_dormida.wav",
  "estrellitas_brote": { "1": "…/estrellitas_brote_1.wav", "2": "…/estrellitas_brote_2.wav", "3": "…/estrellitas_brote_3.wav" },
  "otra_estrellita": "…/otra_estrellita.wav",   // §10.1.1, punto 4: al volver a entrar con 1 o 2 estrellitas
  "vistazo": "…/vistazo_mira.wav", "vistazo_presenta": "…/vistazo_presenta.wav"
}
```

Señales nuevas: `racha_cambiada(n)`, `a_la_primera(id_pareja)` y `record_superado()`.

### 10.2 Vistazo al repartir

**[PO]** Al repartir, algunas cartas se muestran unos 2 s. La cantidad escala con el tablero (4 de 12,
8 de 16 y 12 de 20, como en *Memory Master* de *Super Mario 64 DS* y el memorice de *NSMB*). Nicole las
ve más tiempo y Sofía ve menos cartas.

**[Propuesta]** Cómo funciona:

1. **Reparto**: las cartas salen volando del mazo de Coco a sus lugares, en cascada de 40 ms por
   carta, con un "flip-flip-flip" de baraja. Coco reparte con la cola-brocha.
2. **Vistazo**: las cartas elegidas se dan vuelta **juntas** con un destello y la voz corta "¡mira!".
   Encima del tablero, una **pompa de jabón** se encoge mientras dura el vistazo y revienta al terminar.
3. **Se tapan en cascada** (60 ms por carta) y empieza la vela del tiempo par.
4. **Toques durante el vistazo**: la carta hace el pulso suave y nada más. No se puede saltar, para que
   Nicole no lo pierda por un toque accidental.

| | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| ¿Vistazo? | No: sus cartas ya están a la vista | Sí, en cada ronda tapada | Sí |
| Cuántas cartas | — | **[PO: acepta M6 de UX, 06-Oct-2026]**: **1 par (2 cartas) con 10 cartas o menos** y **2 pares (4 cartas) con 12 a 16**, siempre **parejas completas**. Reemplaza a la tabla del PO (4 de 12, 8 de 16, 12 de 20): con los tableros tapados de Nicole (8 a 12 cartas), esa tabla le resolvía medio tablero ("dificultad de bebé") | `round(cartas / 4)`, **sueltas** (nunca las dos cartas de un mismo par): 6 de 24, 8 de 32, 9 de 36 |
| Duración | — | **3000 ms** | **2000 ms** |
| En modo equipo | **[PO: acepta M6]**: **como máximo 3 pares (6 cartas), en 3 s**, parejas completas, sea cual sea el tablero | | |

Regla general (M6): ≈ 1 s por par mostrado, mínimo 2 s.

- **Contrato**: `"vistazo": { "cartas": 4, "ms": 3000, "pares_completos": true }`.
  - `cartas: "auto"` usa la fórmula del perfil de la tabla: Brote 2 o 4 según el tablero; Estrella
    `round(cartas/4)`.
  - Si no está el campo, no hay vistazo.
  - En equipo se usa `equipo.vistazo: { "pares": 3, "ms": 3000 }` (`modo-equipo.md` §8).
- **No es una pista**: no cuesta estrellitas. La regla del 7.2 de la ficha de zonas ("cada vistazo
  resta 1") se refiere al vistazo **a pedido** de otros motores.
- **Recalibrar los límites de Sofía**: con vistazo, el simulador debe partir con esas cartas "vistas".
  Esto baja la mediana de fallos, y `disenador-niveles` reajusta `limite_intentos` y
  `umbrales_estrellitas`.

### 10.3 Cartas especiales (poderes)

**[PO]** Hay cuatro cartas especiales, presentadas **de a una por zona**:

- comodín arcoíris (Nicole);
- carta dorada de puntos (Sofía);
- carta lupa (al formar su pareja ilumina todo el tablero 1 s);
- carta del Coleccionauta (como la carta Bowser de *Mario Party*: un gag que cambia dos cartas de lugar;
  solo para Sofía, sin humillar).

**[Propuesta]** Detalle:

| Carta | Cómo es | Qué hace | Game feel | Perfil |
|---|---|---|---|---|
| **Comodín arcoíris** (comodín de *Luxor*, como la gota arcoíris del Río) | **Una sola carta**, sin compañera. Su cara tiene franjas arcoíris que giran | Va con **cualquier** carta. Si sale segunda, completa la pareja de la carta de arriba: **la compañera de esa carta se da vuelta sola y vuela a juntarse**, y se forma el par con las tres juntas. Si sale primera, se queda arriba y la próxima carta que se toque se completa igual. **Nunca produce "no es este"**. Cuenta como un eslabón más de la racha | Al darse vuelta, baño arcoíris en Coco y ojos de estrella. La compañera vuela con estela arcoíris (0,5 s) | Nicole (Brote). En equipo, cualquiera si Nicole juega |
| **Carta dorada** | Una **pareja normal con el dorso dorado y brillante**: Sofía sabe que vale, pero no qué figura es | Al formarla: **+500 y el próximo par vale doble** (además de la racha) | Lluvia de monedas-destello, campana grave y nudito dorado en la cresta | Sofía (Estrella). En equipo, no |
| **Carta lupa** | Una **pareja normal con una lupa en la cara** (el dorso es común: no se sabe dónde está) | Al formarla, **todas las cartas tapadas se dan vuelta a la vez 1 s** (Brote 1,5 s) y se tapan en cascada | **Coco abre bien grandes sus ojos de camaleón**, que giran juntos una vuelta (siempre juntos), y de la punta de su cresta sale **un abanico de luz arcoíris** que barre el tablero mientras las cartas se muestran. Suena "¡tadá!" en arpa. **No se pone una lupa en el ojo**: eso se confundía con las gafas-lupa del Coleccionauta (`guionista`). El ícono de la carta sigue siendo una lupa | Nicole y Sofía. En equipo, sí |
| **Carta del Coleccionauta** (la carta Bowser de *Mario Party*) | **Una sola carta**, con la cara del Coleccionauta sonriendo con sus gafas-lupa (canon: gafas-lupa y mochila-torre) | Al darse vuelta, el Coleccionauta **se asoma por el borde**, dice "¡qué lindas! Me llevo… no, mejor las cambio de lugar" y **cambia dos cartas tapadas de lugar** con un vuelo visible de 0,6 s (prefiere cartas ya vistas, que es lo que hace del gag un reto de atención). La carta se va con él. **No cuenta como fallo**, no corta la racha ni el turno, y si había una carta arriba, sigue arriba | El cambio es lento y a la vista, como las "cartas traviesas". Coco se tapa la boca y se ríe. El Coleccionauta se despide tropezando | Sofía (Estrella), solo en solitario |

**Reglas comunes**:

- **Presentación de a una** (como los poderes del Río): la primera vez que una especial aparece en
  la ruta de un hermano, al darse vuelta el juego se detiene 1,5 s, la carta se agranda al centro con un
  brillo, Coco hace el gesto y suena una palabra ("¡Lupa!"). Se puede saltar con un toque. Las veces
  siguientes no se detiene. Se guarda en `Progreso` qué especiales conoce cada hermano.
- **Revancha contra la carta del Coleccionauta [UX M8]**:
  1. Las dos cartas movidas dejan una **estela de brillitos durante 1,5 s**. Si después Sofía forma un
     par con alguna de ellas, suena "¡te pillé, Coleccionauta!", gana **+300 puntos** (`bono_revancha`)
     y el Coleccionauta, desde el borde, se cae de su silla. Así la rabia se convierte en "le gané al
     villano".
  2. La carta **nunca aparece** cuando quedan 3 pares o menos, ni en la partida que sigue a una derrota.
     Si se sorteó, el motor la retira antes de repartir.
  3. Como máximo, una por tablero.
  4. Respaldo, si en el playtest igual hay llanto: con `"modo": "solo_gag"`, el Coleccionauta solo mira
     las cartas y las devuelve donde estaban.
- **En el turno guiado de Maxi (modo equipo, M10)**: el comodín y la lupa que no tienen halo **no se dan
  vuelta**; solo hacen el pulso con un sonido amable. La pareja lupa sí puede recibir el halo
  (`modo-equipo.md` §5.2).
- **Tablero impar (m8)**: el comodín y la carta del Coleccionauta son cartas solas. Si el total de
  cartas queda impar, el lugar sobrante de la grilla lleva una **gomita de Coco**: redonda, del 60 % del
  tamaño de una carta y sin dorso, para que no se confunda con una carta. **Al tocarla se menea y hace
  "boing"** (GDD §6.5). No cuenta para nada.
- **Calendario por zona** [Propuesta, lo ajusta `disenador-niveles`]:

| Zona | Nicole · Brote | Sofía · Estrella |
|---|---|---|
| 1 | — (llegan un solo sistema nuevo, "los puntos", que son la racha, el récord y las estrellitas, y el vistazo, que es pasivo. La vela entra desde la zona 2: M7.4) | **Dorada** (1 pareja) |
| 2 | **Comodín** (1) | **Lupa** (1) |
| 3 | **Lupa** (1) | **Coleccionauta** (1). Con tríos, la lupa y la dorada serían tríos |
| 4 | Comodín + lupa | Dorada + lupa (las traviesas ya mueven cartas: sin Coleccionauta) |
| 5 | Comodín + lupa | Dorada + lupa + Coleccionauta |

- **Contrato**:
  ```jsonc
  "especiales": [
    { "tipo": "comodin" },
    { "tipo": "lupa", "ms": 1500 },
    { "tipo": "dorada", "bono": 500 },
    { "tipo": "coleccionauta", "intercambios": 1, "bono_revancha": 300, "modo": "cambia" }  // "cambia" | "solo_gag"
  ]
  ```
  - Voces: las del §7 del guion (`voces/arcoiris/emparejar/especiales/`), en
    `lineas_voz.especiales.<tipo>`, con `presenta` (una vez por hermano) y la palabra corta.
  - Falta pedirle al `guionista` la línea de revancha "¡te pillé, Coleccionauta!" (Coco) y la reacción
    del Coleccionauta al caerse (grabación casera de papá).
  - La voz de presentación de la lupa del guion habla de "el ojo agrandado": hay que ajustarla al gesto
    nuevo (ojos grandes y abanico de luz).
  - La lupa y la dorada **toman una pareja del pool** y la marcan.
  - El comodín y el Coleccionauta **agregan** una carta.
  - En niveles con `rondas`, va por ronda.
  - Señal nueva: `especial_activada(tipo)`.
- **Recalibrar**: la lupa y el comodín bajan fallos, y el Coleccionauta los sube un poco. Los límites
  de Sofía se vuelven a simular con las especiales de cada zona.

### 10.4 Camino de colores (*Memoarrr!*)

**[PO]** Es un tablero 5×5 con todas las combinaciones de 5 figuras × 5 colores. Cada carta que se da
vuelta debe compartir color o figura con la anterior. Es candidato a reto dorado o zona secreta de
Sofía.

**[Propuesta]** Reglas:

- **Regla nueva del motor** `regla: "camino"`. Usa las mismas cartas, el mismo volteo y el mismo
  input; cambia solo la validación. Las 25 cartas son únicas y no hay parejas.
- **La primera carta es libre.** Cada carta siguiente tiene que **compartir figura o color** con la
  última que se dio vuelta. Si comparte, **se queda boca arriba** y se dibuja un **trazo de glaseado**
  entre las dos:
  - del color común, si comparten color;
  - con estampitas de la figura, si comparten figura.
- **Tramos horneados [UX M9.1]**: cada 4 cartas, el glaseado del tramo **se hornea** con un brillo
  dorado y un "ding" de horno, y **ese tramo ya no se desarma**. La meta de 12 cartas son 3 tramos.
- **Si no comparte**: "no es este" con el meneo amistoso. **Solo se desarma el tramo en curso**, el que
  todavía no se horneó:
  - sus cartas quedan **1 s a la vista** (M9.4) y después se tapan en cascada (400 ms);
  - quedan donde estaban, así que Sofía las recuerda;
  - el camino sigue desde la última carta horneada;
  - cuenta 1 fallo.
- **Ficha "busca" [UX M9.2]**: junto a Coco, sin texto, hay dos burbujas separadas por un "o" visual
  (un puntito arcoíris):
  - una con la **mancha del color** de la última carta;
  - otra con la **silueta de su figura**.
  
  Además, la última carta del camino queda **agrandada al 110 % y con borde**. No regala posiciones:
  solo libera memoria para el verdadero reto.
- **Demostración [UX M9.3]**: antes de la primera partida, Coco muestra 3 cartas: una que comparte el
  color, otra que comparte la figura y **una que no comparte nada** ("¡esta no, no tiene nada igual!").
  Usa las voces `camino/demo_01..03` del guion. Falta pedirle al `guionista` la línea del caso que no
  comparte nada.
- **Meta**: armar un camino de `largo_meta` cartas (propuesta: **12**). También se gana si el camino
  llega a un punto **sin salida**, cuando ninguna carta tapada comparte nada con la última. Entonces
  Coco dice "¡no queda por dónde seguir: llegaste al final!".
- **Puntaje y récord**: el récord es **el camino más largo**. Cada paso suma 100 × racha (el camino
  es una racha natural), con el tono que sube en escala.
- **Límite** con derrota-gag (las cartas bailan una conga y se reordenan; Coco se marea) y el
  "¡otra vez!" de un toque.
- **Ayudas de Sofía**: `pistas_cuestan_estrellita` revela por 1 s **todas** las cartas que continúan el
  camino. `regalo_tras_derrotas`: tras 2 derrotas, Coco arma solo los 3 primeros pasos.
- **Accesibilidad**: 5 colores bien distintos (rojo, amarillo, azul, verde y rosado) y 5 figuras de
  silueta muy distinta (estrella, corazón, gota, luna y círculo) para que nunca dependa solo del tono.
- **Ubicación [PO]**: es el **reto dorado de Parejas de la zona 4** de Sofía. Archivo
  `datos/niveles/arcoiris/zona4_islotes/parejas_estrella_dorado.json`, declarado en `niveles_dorados`
  de esa estación en `mapa.json`. Aparece con 3 estrellitas en la estación y no bloquea nada.
- **Contrato**:
  ```jsonc
  {
    "regla": "camino",
    "figuras": ["estrella", "corazon", "gota", "luna", "circulo"],
    "colores": ["rojo", "amarillo", "azul", "verde", "rosado"],
    "disposicion": { "filas": 5, "columnas": 5 },
    "largo_meta": 12,
    "largo_tramo": 4,            // M9: tramos horneados (0 = sin hornear, no recomendado)
    "ms_tramo_visible": 1000,    // M9.4
    "demostracion": true,        // M9.3: solo la primera partida de cada hermano
    "limite_intentos": null,
    "umbrales_estrellitas": null
  }
  ```
  El límite y los umbrales los fija `disenador-niveles` con el simulador: cada carta comparte algo con
  8 de las otras 24, y la jugadora recuerda ~5.
- **QA**: verificar que con 5×5 la cuadrícula cabe a ≥ 100 px por carta en 1280×720 (5 filas en
  ≈ 600 px útiles dan unos 110 px).

### 10.5 Colección de cartas (*Snap Match*)

**[PO]** Cada pareja nueva queda guardada en una colección. **[Propuesta]**:

- **Qué se colecciona**: cada pareja tiene un `id_coleccion`. Si no viene, se usa `figura` + `color`
  o `id_pareja`; en las banderas, el país. La **primera vez** que un hermano forma esa pareja, entra a
  su colección.
- **Durante el juego** (sin pausa):
  - la figura que vuela a la barra lleva una **estrellita de "¡nueva!"** pegada y suena un "clink" de
    álbum;
  - al final de la celebración, después del conteo de destellos, las cartas nuevas **vuelan a una
    cajita de Coco**, **0,5 s cada una** (`guionista`). La voz cuenta **solo hasta seis**
    (`coleccion/cuenta_1..6`). Desde la séptima, solo suena el "clink", sin voz. Antes de que vuelen
    suena `coleccion/final`, o `final_equipo` en modo equipo.
- **Pantalla de colección** ("La caja de cartas de Coco"):
  - una carpeta con las cartas de Arcoíris en grilla, ordenadas por familia (figuras, dinos y vehículos,
    animales, ropa, banderas, sombras y recetas);
  - las que faltan son **siluetas con un signo de pregunta**, nunca con candado;
  - **sin contadores** como "23/60" (m9): las siluetas bastan;
  - **tocar una carta la da vuelta y Coco dice su nombre** ("¡Japón!", "¡Spinosaurio!"). Para las
    banderas, esto refuerza el pedido de aprender países (memoria del proyecto).
- **Una colección por hermano**, sin comparar números entre ellos. Maxi también colecciona: para él,
  mirar sus dinos y oír los nombres es el juego.
- **Datos y arquitectura**:
  - catálogo en `datos/colecciones/cartas_arcoiris.json` (`id_coleccion`, dibujo, color, familia y
    voz);
  - lo coleccionado se guarda en `Progreso.coleccion.<hermano>`, con un helper genérico de
    `minijuego_base` (`registrar_coleccionable(id)`): el motor no toca el guardado;
  - la pantalla es núcleo y lee solo el catálogo: no sabe de Parejas.
- **En equipo**: cada pareja nueva entra a la colección de **todos los participantes**.
- **Tono**: el `guionista` cuida que no choque con el arco del Coleccionauta ("los amigos no se
  coleccionan"). Son cartas que Coco regala para jugar y mostrar, y la pantalla puede tener un botón
  "mostrarle a un hermano" en el futuro.
- **Ubicación [PO]**: la **casita-cupcake de Coco en el mapa del planeta**, como objetivo tocable de
  ≥ 96 px. Abre la colección **del hermano que juega**, y cada hermano ve solo la suya (m9). En modo
  equipo, la casita no abre la colección: se ve dormida, para evitar comparaciones.
- **Voces**: las del §9 del guion (`voces/arcoiris/coleccion/`).

### 10.6 Riesgos de usabilidad de estas mejoras (para `experto-ux-parvulo`)

> **Estado (v2)**: la validación de HE-58 ya revisó estos riesgos, y sus correcciones están
> incorporadas:
>
> - riesgo 1 → m10;
> - riesgo 3 → M7;
> - riesgo 4 → M6;
> - riesgo 6 → M8;
> - riesgo 7 → M9;
> - riesgo 8 → m8.
>
> Queda verificarlos sobre el build en HE-64. Se suma un riesgo:
>
> - **Riesgo 10. ¿La estrellita 1 de Nicole se vive como logro?** Observar su cara cuando gana 1. Si
>   se decepciona, la palanca es bajar `dos`, nunca quitar las estrellitas.

1. **El contador de racha y los "+200" pueden tapar cartas**: los números salen y suben **fuera de la
   grilla**, o sobre el par que se va, nunca sobre una carta tapada.
2. **¿Nicole lee el récord sin números?** Validar la barra con banderita-cupcake. A los 5 años puede
   leer números hasta 20, pero no comparar 1.850 con 2.100.
3. **¿La vela del tiempo par se siente como amenaza?** Si Nicole se apura y se pone ansiosa, se apaga
   para Brote (`tiempo_par_s: null`) y queda solo la racha.
4. **El vistazo de 3 s con 8 cartas** puede ser mucho para la memoria de trabajo de Nicole (~3
   elementos). Mostrar parejas completas ayuda, pero validar si recuerda alguna o se satura.
5. **Comodín**: confirmar que se entiende que "va con todo" sin explicación larga. La presentación (§10.3)
   tiene que mostrarlo funcionando una vez.
6. **Carta del Coleccionauta**: confirmar que a Sofía (que se frustra rápido) le da risa y no rabia. Si
   le da rabia, se cambia el "cambio de lugar" por "las mira y las devuelve donde estaban" (solo gag).
7. **Camino de colores**: la regla "comparte color **o** figura" es abstracta. Validar que Coco la
   explica con una demostración de 3 cartas al inicio y que Sofía la entiende al primer intento.
8. **Tablero impar con adorno**: confirmar que nadie intenta tocar la gomita creyendo que es una carta.
9. **Celos**: Nicole y Sofía no deben ver en pantalla puntajes o colecciones de la otra.

### 10.7 Qué debe validar cada rol

- **`dev-godot`**:
  - los campos `puntaje`, `vistazo`, `especiales`, `regla: "camino"` e `id_coleccion`;
  - las señales nuevas;
  - `records` y `coleccion` en `Progreso` (campos opcionales, con versión si hace falta, HE-07);
  - la pantalla de colección.
  - Un nivel sin estos campos se juega **exactamente igual que hoy**.
- **`disenador-niveles`**:
  - el calendario de especiales y los valores de `tiempo_par_s`;
  - **la recalibración de `limite_intentos` y `umbrales_estrellitas` de Sofía** con vistazo y
    especiales;
  - el nivel del Camino de colores;
  - el catálogo de colección.
- **`experto-ux-parvulo`**: los riesgos de §10.6.
- **`tester-qa`**:
  - ampliar `qa_test_parejas_zonas.gd`: racha y su corte, "a la primera", vela, récord, cada
    especial (incluido el comodín con la carta arriba y el tablero impar), el camino (incluido el
    "sin salida") y el registro de colección una sola vez por pareja;
  - respaldar `progreso.json` antes.
- **`guionista`**: palabras cortas de presentación ("¡Lupa!", "¡Comodín!"), la línea del Coleccionauta,
  "¡récord!", la explicación del camino y los nombres de la colección (hay que estimar el costo del TTS
  y pedir el OK del PO antes de generarlo).

### 10.8 Decisiones del PO (06-Oct-2026) y lo que queda por confirmar

| # | Decisión [PO] | Dónde |
|---|---|---|
| 1 | Nicole gana **estrellitas por puntaje (de 1 a 3)** jugando sola, como Sofía. El récord sigue como reto extra | §10.1.1 |
| 2 | El Camino de colores es el **reto dorado de Parejas de la zona 4** de Sofía | §10.4 |
| 3 | La colección va en la **casita de Coco** del mapa del planeta | §10.5 |
| 4 | Los récords **parten en cero**. Al rejugar, las estaciones ya jugadas traen racha, vistazo y especiales | §10.1 |
| 5 | **M6 aceptado**: las cantidades del vistazo de UX son las definitivas | §10.2 |

### 10.9 Para Dev

Los menores de la validación UX (m1 a m11) están en el §13 de `docs/fichas/modo-equipo.md`. Los que
tocan este motor (m6, m8, m9 y m10) ya están integrados en §10.1, §10.3 y §10.5. Además:

- Las señales nuevas del motor son `racha_cambiada(n)`, `a_la_primera(id_pareja)`, `record_superado()`
  y `especial_activada(tipo)`.
- En modo equipo, el motor llama a `turnos.notificar_acierto()` y a `turnos.terminar_turno(con_fallo)`
  (`modo-equipo.md` §11.4).
- `Progreso`:
  - `registrar_coleccionable`, `obtener_coleccion`, `especial_conocido` y `marcar_especial_conocido`
    (`modo-equipo.md` §11.5);
  - el récord en solitario usa el `registrar_puntaje_nivel` que ya existe (más es mejor);
  - las estrellitas de Nicole usan el `marcar_nivel_completado` de siempre.

### 10.10 Implementación `dev-godot` (07-Oct-2026, HE-60)

Implementado en `scripts/motores/emparejar/motor_emparejar.gd` (§10.1, §10.1.1 y §10.2; las especiales,
el Camino y la colección quedan para HE-61/62/63). Decisiones de implementación que la ficha no fijaba:

- **La racha sigue entre rondas** (la mini-fiesta no la corta) y el `tiempo_par_s` es **de toda la
  estación** (suma de rondas), igual que el simulador de `herramientas/agregar_reto_parejas.py`.
- **La vela solo se consume jugando**: se detiene durante el vistazo, la mini-fiesta entre rondas y la
  derrota-gag de Sofía.
- **"¡A la primera!"** solo en tableros tapados: todas las cartas del par se dan vuelta por primera vez en
  esa jugada (las del vistazo y las de la ayuda de Coco ya cuentan como vistas).
- **Vistazo**: siempre espera a que Coco termine de hablar (intro o consigna de ronda, máx. 6 s) y siempre
  dice "¡mira!" justo antes de dar vuelta las cartas (UX M2). La primera vez de cada hermano, si existe
  `vistazo_presenta`, la dice en lugar de "¡mira!" y el vistazo dura 1,5 s más. Con `cartas: "auto"`, las
  sueltas de Sofía son `round(cartas/4)` sin repetir grupo. Tocar una carta durante el vistazo hace el
  pulso y un toquecito bajito (−12 dB, 150 ms de enfriamiento por carta, UX m1).
- **Voces de reto faltantes (HE-67)**: si no existe el wav de `racha_N` o `a_la_primera`, suena el
  `acierto_par` de siempre; para Nicole, si falta `estrellitas_brote_N`, suena `victoria_final`.
- **Récord**: se guarda puntaje base + bono de la vela, antes de la fiesta. Sin `planeta_id` (motor en
  prueba) no se guarda récord ni se marcan presentaciones.
- **Lugares (1280×720)**: barra de récord `Rect2(1168, 172, 84, 396)` (bajo el medidor de la pista de
  Sofía), vela en (28, 126) bajo el botón de salir, contador "×N" en `Rect2(30, 222, 180, 92)` sobre
  Coco y nuditos en su cresta. Los "+N" nacen sobre la carta ya destapada del par (m10).
- **QA**: `herramientas/qa_test_parejas_reto.gd` (los 3 perfiles, solo guardado de pruebas).

Correcciones tras las auditorías UX y QA del 07-Oct-2026 (`docs/validaciones/2026-10-07_*-HE-60-*.md`):

- **Salir siempre es seguro (QA B1)**: en el instante del último par se guardan estación, destellos,
  estrellitas y récord (incluido el bono de la vela que queda) con `asegurar_victoria()` del contrato base.
  La vela que se cobra, el trofeo y las voces de récord son solo animación. Los demás motores (Río,
  Mezclar, Encajar, Clasificar) llaman lo mismo al ganar: se cerró la ventana de ~0,9 s para todos.
- **Presentaciones de una sola vez (QA M1)**: "vistazo" y "vela" solo se marcan si su voz existe y sonó.
- **Sin voces de la vela no hay vela (UX B1)**: hacen falta `vela_presenta` y `vela_dormida`; si falta una,
  el nivel se juega como con `tiempo_par_s: null`. Los arneses la fuerzan con `vela_sin_voz_en_pruebas`.
- **La vela recién se enciende** después de `otra_estrellita`, `vela_presenta` y la consigna (UX M3), y
  se pausa también mientras Coco o Cometa repiten una instrucción pedida, con el globo de la pista abierto
  y con la app en segundo plano.
- **Barra de récord (UX M1)**: el alto se fija una vez (`max(récord × 1,3, sugerido)`; el sugerido suma
  `tiempo_par_s × bono_por_segundo × 0,5` si hay vela). Si el puntaje lo pasa, la barra rebalsa con
  burbujas arcoíris y un "blup"; la banderita nunca se mueve.
- **Menores**: "puf" y "fiuu" propios y suaves (`sfx/ui/puf.ogg`, `fiuu.ogg`, sintetizados); Maxi no ve
  huecos grises en la cresta y su corte de racha es silencioso; la vela de Sofía tiene ~28 px de cera
  sobre un cupcake más chico; la vela y la barra se menean con un "ding" al tocarlas; "¡a la primera!"
  es un aro dorado dentro de cada carta (sin estela) y el trébol aterriza en (120, 330); Coco sostiene el
  trofeo delante del cuerpo y lo guarda antes de la celebración; la pompa del vistazo es más grande.
