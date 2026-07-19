# QA — Motor "emparejar" + nivel piloto Estrella ("Los ponys mágicos")

> ⚠️ Contexto: **ejercicio de humo del flujo completo de agentes** (mecánica → nivel →
> implementación → auditoría UX → QA). No es contenido final del capítulo 1 ni tiene tarjeta
> de tablero — no hay DoD formal. Este reporte verifica lo técnico/funcional: que la escena
> corre sin errores/warnings, que el flujo completo funciona simulando toques como cada
> perfil de niño, los casos crueles obligatorios y la señal `completado(destellos)`.
> `experto-ux-parvulo` ya auditó UX/usabilidad (`docs/auditorias-ux/2026-07-18_motor-emparejar-piloto-estrella.md`,
> **RECHAZADA con 4 bloqueantes B1-B4**) — no repito ese análisis, pero **corroboro por
> ejecución real** dos de sus hallazgos (B2 y B4, ver abajo) porque cayeron directamente
> dentro de mis casos crueles obligatorios.

- **Fecha**: 18-Jul-2026
- **Tester**: `tester-qa`
- **Documentos revisados**: `docs/fichas/motor-emparejar.md`, `docs/fichas/nivel-piloto-emparejar-estrella-01.md`, `docs/auditorias-ux/2026-07-18_motor-emparejar-piloto-estrella.md`, `docs/stack-tecnico.md` §4
- **Código/escenas ejecutados**: `scripts/motores/emparejar/motor_emparejar.gd`, `scripts/motores/emparejar/carta_emparejar.gd`, `escenas/minijuegos/emparejar/motor_emparejar.tscn`, `escenas/minijuegos/emparejar/carta_emparejar.tscn`, con datos de `datos/niveles/piloto_emparejar_estrella_01.json`
- **Motor/versión Godot**: 4.7.1.stable.official, headless, `--path .`

---

## 1. Metodología de ejecución

No hay display/tablet disponible en este entorno, así que en vez de auditar solo por lectura
de código simulé el flujo real de juego con un arnés headless que instancia la escena de
producción tal cual (`motor_emparejar.tscn` con `ruta_nivel` apuntando al JSON del piloto) y
dispara toques por el mismo camino que un toque/click real: `carta.pressed.emit()` sobre cada
`CartaEmparejar` (equivalente a lo que `BaseButton._pressed()` dispara al soltar el dedo/click
dentro del control), leyendo la consola completa de cada corrida.

Arnés: `herramientas/qa_test_emparejar.gd` (queda en el repo, dentro de `herramientas/`
—cubierto por su `.gdignore`, no se importa como recurso del juego— como evidencia
reproducible de esta sesión de QA; no es parte del juego).

Comando de cada corrida:

```powershell
& $GODOT --headless --path . --script herramientas/qa_test_emparejar.gd -- <modo>
```

Se ejecutaron 5 modos, cada uno simulando un perfil/caso distinto:

| Modo | Qué simula |
|---|---|
| `sofia_normal` | Sofía (8): ritmo normal-rápido, resuelve pares correctamente, fuerza un "no es este" y durante esa ventana de 500 ms toca una tercera carta (caso cruel), completa el tablero entero incluido el par secreto |
| `maxi_random` | Fuzzing tipo Maxi (2): 40 toques al azar sobre el tablero, incluida la misma carta machacada varias veces seguidas, y una pausa larga de "quedarse quieto" |
| `machaque` | Caso cruel obligatorio: 20 toques en ráfaga sobre la misma carta, luego 10 más sobre una segunda carta |
| `derrota_forzada` | Acierta 1 par, falla los 8 pares restantes a propósito hasta agotar `limite_intentos: 16`, valida la derrota-gag, reintenta con un toque, verifica que el par ya acertado no se pierde, y completa el resto para leer `completado(destellos)` |
| `salir_reentrar` | Recorre todo el árbol de nodos de la escena buscando cualquier control de salida/volver, para responder la pregunta obligatoria "¿hay siquiera forma de salir?" |

Los 5 logs completos quedaron en `c:\tmp\qa_sofia.log`, `qa_maxi.log`, `qa_machaque.log`,
`qa_derrota.log`, `qa_salir.log` (fuera del repo, temporales de sesión).

---

## 2. Resultado por corrida

### `sofia_normal` — consola limpia, 0 errores/warnings de juego

- Tablero cargado con 16 cartas (8 pares) tras `_ready()`.
- El "no es este" forzado disparó `intento_fallido` + voz `no_es_este` correctamente.
- **El toque sobre una tercera carta durante la ventana de 500 ms de resolución no generó
  ninguna señal ni reacción registrable** — confirma por ejecución el hallazgo **B2** de
  `experto-ux-parvulo` (toques ignorados en silencio total mientras `_procesando == true`).
- Se completaron los 8 pares en orden, incluido el par secreto `pony_arcoiris_secreto`, que
  disparó correctamente la línea única `acierto_par_secreto` (no la del pool genérico) y el
  gag de arcoíris (`_animar_arcoiris_secreto`) — el enganche vía `id_pareja` que pedía la
  ficha de nivel §8 funciona.
- `SENAL completado(destellos=110) recibida` — verificado a mano: 8 pares × 10 = 80,
  `intentos_usados=1` → sobrantes `15 × 2 = 30` → 80+30=110. **Cálculo correcto** para este
  camino.
- Sin `push_error`/`push_warning` de código propio en toda la corrida.

### `maxi_random` — sin crash, sin errores

- 40 toques al azar + machaque de la misma carta + pausa larga de 2 s sin actividad: el motor
  no crasheó, no quedó en estado inconsistente, y no generó ningún error/warning.
- Solo se registraron dos `intento_fallido` (voz `no_es_este`) durante el caos, coherente con
  que el azar rara vez arma un par válido — comportamiento esperado, no bug.

### `machaque` — sin crash, sin errores

- 20 toques en ráfaga sobre la misma carta: cada toque adicional pasa por la rama de
  "deselección voluntaria" (toque repetido sobre carta ya seleccionada) sin acumular estado
  raro ni disparar `intento_fallido` de más. Correcto según el contrato (§3 fila 3 de la
  ficha de motor: "sin penalidad ni conteo de intento").
- 10 toques en ráfaga sobre una segunda carta (con la primera aún "seleccionada" tras el
  machaque): no crasheó.

### `derrota_forzada` — deriva un bug de puntaje (ver Bugs, Mayor #1)

- Acierto de 1 par (`pegaso_rosa`) antes de forzar la derrota: correcto.
- 16 fallos consecutivos disparan `SENAL nivel_fallado()` y la voz `derrota_gag` exactamente
  al agotar `limite_intentos`, como especifica el contrato.
- `boton_otra_vez.visible = true` tras la derrota; reintento con un solo toque
  (`boton.pressed.emit()`) — funciona.
- **Cero progreso perdido, verificado**: `pegaso_rosa` sigue `esta_acertada = true` después de
  `_reintentar()` (no se repite el par ya logrado, cumple ficha de motor §6).
- `boton_otra_vez.visible = false` tras reintentar — correcto.
- Al completar el resto de los pares sin más fallos: `SENAL completado(destellos=112)`.
  **Este número es el bug**: ver Mayor #1 abajo — es mayor que el de la corrida limpia
  (`sofia_normal`, 110 destellos con solo 1 fallo), pese a haber fallado 16 veces en el
  camino.

### `salir_reentrar` — confirma que no hay forma de salir

- Recorrido completo del árbol de la escena (`motor_emparejar` y todos sus descendientes):
  **cero nodos** con nombre/función de salida, volver, cerrar o "home". Confirma por
  ejecución el hallazgo **B4** de `experto-ux-parvulo`: ejecutando esta escena tal cual hoy,
  no hay ninguna forma de abandonarla salvo terminar el proceso.
- Como consecuencia directa, el caso cruel obligatorio "salir a mitad y volver a entrar" **no
  es ejecutable**: no hay punto de salida desde el cual reentrar. Este caso queda bloqueado
  por B4, no es un hallazgo nuevo pero sí una confirmación de que B4 no es solo un
  "nice to have" de navegación — impide directamente uno de los casos crueles obligatorios de
  cualquier pantalla del juego.

---

## 3. Bugs encontrados (nuevos, no reportados por la auditoría UX)

### Mayor

**M-QA1. El reintento tras la derrota-gag resetea `_intentos_usados` a 0, permitiendo obtener
*más* destellos fallando a propósito que jugando limpio — rompe la integridad del puntaje.**

En `motor_emparejar.gd`, `_reintentar()`:

```gdscript
func _reintentar() -> void:
    _boton_otra_vez.hide()
    _etiqueta_gag.hide()
    _intentos_usados = 0
    ...
```

`_calcular_destellos()` premia los "intentos sobrantes" (`limite_intentos - _intentos_usados`)
con `DESTELLOS_POR_INTENTO_SOBRANTE` cada uno. Como `_reintentar()` pone `_intentos_usados` en
0 sin importar cuántos fallos llevaba el jugador antes de agotar el límite, **fallar los 16
intentos a propósito, disparar el gag, reintentar y completar el tablero sin más errores da
112 destellos** (16 sobrantes × 2 = 32, sobre la base de 80) — más que jugar limpio con solo
1 fallo real, que da 110 (verificado en las corridas `derrota_forzada` vs. `sofia_normal` de
este mismo reporte). En el peor caso, alguien podría fallar 16, reintentar, fallar 16 de
nuevo, reintentar... y seguir sacando el bono máximo cada vez, sin correlación con su
desempeño real.

Esto contradice el propósito explícito del campo en la ficha de nivel (§5): *"holgado, no
bloquea"*, pensado como límite de ritmo, no como mecánica de puntaje reseteable a voluntad.
Para el perfil de Sofía ("quiere ir rápido", "busca los límites" — ver ficha de personaje
citada en la auditoría UX), este es exactamente el tipo de comportamiento que un niño de 8
años descubre jugando y puede convertir en el "truco" para sacar siempre el puntaje máximo,
vaciando de sentido al sistema de estrellas 1-3 que pide la ficha de nivel §5/§10.

**No es bloqueante para el piloto** (no rompe la escena ni impide jugar), pero si este motor
pasa a producción de contenido real sin corregirse, cualquier nivel Estrella/Brote con
`limite_intentos` hereda el mismo agujero de puntaje.

**Repro**: modo `derrota_forzada` de `herramientas/qa_test_emparejar.gd`, o manualmente: fallar
16 pares seguidos en el nivel piloto → reintentar → completar sin más fallos → comparar
`destellos` recibido en `completado` contra una partida sin fallos deliberados.

### Menor / informativo (no bug, limitación de alcance esperada)

**m-QA1. No existe todavía ninguna escena de título/mapa/celebración en el proyecto** — solo
`escenas/nucleo/placeholder.tscn` y las dos escenas del motor "emparejar". El flujo de
regresión mínima que exige mi metodología (título → mapa → un nivel → celebración → mapa) **no
es ejecutable** en el estado actual del repo. Es coherente con la fase temprana del proyecto
(el core de navegación/Progreso todavía no se implementa, `project.godot` no declara
autoloads), no es un bug de esta tarjeta/piloto — queda anotado para cuando exista ese flujo.

---

## 4. Corroboración independiente de hallazgos de UX (no duplicados, solo confirmados por ejecución)

- **B2** (toques ignorados en silencio durante los ~500 ms de "no es este"): reproducido en
  `sofia_normal` — cero señal/reacción al tocar una tercera carta en esa ventana.
- **B4** (sin ícono de salida): reproducido en `salir_reentrar` — recorrido completo del árbol
  de nodos sin encontrar ningún control de salida, y confirmado que esto bloquea directamente
  el caso cruel obligatorio de "salir a mitad de partida".

No re-audito B1 (Button nativo cancela toque con arrastre) ni B3 (falta Estelita/pista) por
requerir input real de puntero con movimiento, que no puedo simular de forma representativa en
headless sin el editor gráfico; confío en el análisis de código de `experto-ux-parvulo` para
esos dos, que es igual de válido ahí (son de lógica, no de timing de ejecución).

---

## 5. Veredicto (sin DoD formal — piloto de proceso)

No hay tarjeta de tablero ni DoD contra el cual cerrar. En su lugar, respondo lo pedido:

- **¿La escena corre sin errores/warnings de consola?** Sí, en las 5 corridas (errores de
  motor propio = 0; el único error visto fue en una corrida temprana del *arnés de QA*, ya
  corregido, no del código del juego).
- **¿El flujo completo funciona simulando cada perfil de niño?** Sí — Sofía (ritmo
  normal/rápido + par secreto), fuzzing tipo Maxi (random + machaque + quietud) y el caso
  cruel de machaque puro corrieron sin crashear y con estados consistentes.
- **¿Casos crueles obligatorios?** Toque repetido/machacado: OK, sin penalidad extra. Agotar
  intentos en el último tramo: dispara el gag correctamente. Reintento de un toque: OK, cero
  progreso perdido (verificado). **Salir a mitad de todo y reentrar: NO EJECUTABLE — no existe
  forma de salir (confirma B4)**. Completar con el mínimo/máximo de un mismo nivel: solo existe
  este nivel de 8 pares, no aplica variar cantidad en este piloto.
- **¿`completado(destellos)` se emite correctamente?** Se emite siempre exactamente una vez al
  completar el tablero, con el valor numérico correcto según la fórmula del motor — **pero la
  fórmula en sí tiene el bug M-QA1** (reintento resetea intentos, inflando el puntaje).

**Este circuito (motor genérico + JSON + escena) es viable como base técnica** — la separación
motor/contenido funciona exactamente como prometía la ficha (mismo código, nivel intercambiable
por JSON), el manejo de estados (selección/acierto/no-es-este/derrota-gag/reintento) es sólido
y headless-testeable de punta a punta, y no encontre ningun error de consola real del
motor en ninguna corrida. **No recomiendo darlo por "listo para producir contenido real" hasta
que se resuelvan los 4 bloqueantes de UX (B1-B4) + este bug de puntaje (M-QA1)** — B4 en
particular no es solo UX: bloquea directamente uno de mis casos crueles obligatorios (salir a
mitad de partida), así que técnicamente tampoco puedo dar por completa la validación de casos
crueles mientras siga abierto.

---

## 6. Pendiente de verificar cuando exista

- Input real de arrastre/toque impreciso en dispositivo o editor gráfico (B1) — no simulable
  con fidelidad en headless.
- Arte/audio final (fuera de mi alcance por instrucción, y explícitamente fuera del alcance de
  la auditoría UX también).
- Flujo de regresión mínima título→mapa→nivel→celebración→mapa, en cuanto existan esas
  escenas.
- Reproducción del bug M-QA1 con el nivel real una vez `disenador-niveles` reemplace el
  contenido placeholder (confirmar que la fórmula de puntaje se corrige antes o junto con esa
  migración).
