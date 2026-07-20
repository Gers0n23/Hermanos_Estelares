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
  `nivel_fallado()` (solo si aplica derrota-gag).

---

## 5. Reglas de escalado por perfil

| | **Semilla (Maxi, 2 años)** | **Brote (Nicole, 5 años)** | **Estrella (Sofía, 8 años)** |
|---|---|---|---|
| Cantidad de pares | 2-3 | 4-6 | 6-10 |
| `oculto` (memoria) | Siempre `false` — todo visible, sin carga de memoria de trabajo | Opcional; si se usa, `tiempo_volteo_ms` generoso (≥1200 ms) | Sí, modo memoria real; `tiempo_volteo_ms` más ajustado (~800-900 ms) para reto genuino |
| Ritmo/tiempo | Sin ritmo — cero presión, cualquier orden vale | Ritmo suave opcional vía `limite_intentos` (reto blando, no cronómetro visible) | Puede sumar cronómetro de juego (no narrativo) para el puntaje de estrellas — nunca bloquea, solo puntúa |
| Ayudas visuales | Halo pulsante constante en los elementos tocables; imán/hitbox extra generoso (≥96 px lógicos, GDD §6.1); un solo objetivo resaltado a la vez si `anfitrion_id` lo narra | Pista por voz tras 2-3 intentos fallidos consecutivos sobre el mismo par (`lineas_voz.pista`); resaltado sutil del segundo elemento si sigue sin encontrarlo tras la pista | Sin ayudas automáticas — puede pedir pista tocando a Cometa (repite instrucción, GDD §6.2), pero no hay resaltado gratuito: el reto es real |
| `limite_intentos` | Siempre `null` | Opcional (config del nivel); si se define, activa derrota-gag | Recomendado definir uno holgado para dar sentido al puntaje de estrellas |
| Fallo posible | **No existe** (§6) | Sí, si el nivel lo configura — derrota-gag suave | Sí — derrota-gag + puntaje 1-3 estrellas según intentos/tiempo |
| Objetivo a la vez | Sí, implícito (cualquier toque produce algo bueno) | Sí, explícito: la instrucción de voz nombra un elemento o pista a la vez (GDD §5) | No aplica — puede manejar el tablero completo a la vez |

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
