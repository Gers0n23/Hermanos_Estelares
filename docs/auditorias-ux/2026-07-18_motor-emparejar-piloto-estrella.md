# Auditoría UX — Motor "emparejar" + nivel piloto Estrella ("Los ponys mágicos")

> ⚠️ Contexto: **ejercicio de humo del flujo completo de agentes** (no contenido final del
> capítulo 1). Se audita solo lo auditable en este estado: hitbox declarado en código,
> timings, mecánica de toque, diseño del límite de intentos, gag de derrota (estructura) y
> navegación/salida segura. Arte y audio finales **no existen todavía** (placeholders con
> TODO) y quedan explícitamente **pendientes de auditoría** cuando existan — no se evalúan
> aquí.

- **Fecha**: 18-Jul-2026
- **Auditor**: `experto-ux-parvulo`
- **Documentos revisados**: `docs/fichas/motor-emparejar.md`, `docs/fichas/nivel-piloto-emparejar-estrella-01.md`, `docs/diseno-juego.md` §6/§1/§5, `docs/perfil-jugadores.md` (Sofía)
- **Código/escenas revisados**: `scripts/motores/emparejar/motor_emparejar.gd`, `scripts/motores/emparejar/carta_emparejar.gd`, `escenas/minijuegos/emparejar/motor_emparejar.tscn`, `escenas/minijuegos/emparejar/carta_emparejar.tscn`, `datos/niveles/piloto_emparejar_estrella_01.json`
- **Perfil auditado para esta pantalla**: Estrella / Sofía (8 años) — "se frustra y llora rápido", "lo fácil le parece de bebés", "quiere ir rápido"

---

## Veredicto: **RECHAZADA** (para este ejercicio de piloto — no cierra la tarjeta)

4 hallazgos bloqueantes. Ninguno requiere arte/audio final para corregirse: son de lógica de
interacción y de reglas obligatorias del GDD §6. El motor está bien encaminado (estados de
fallo sin castigo, deselección voluntaria, reintento de un toque, cero progreso perdido) pero
no puede considerarse validado como piloto hasta resolver estos cuatro puntos.

---

## Hallazgos

### Bloqueantes

**B1. `CartaEmparejar` extiende `Button` nativo, que cancela el toque ante un arrastre corto — sin la tolerancia que pide el propio contrato del motor.**

Ya reportado por `dev-godot`. El contrato de la ficha de motor (§3) es explícito: *"Si el
input unificado detecta un gesto de arrastre iniciado sobre un elemento, se trata como un
toque simple sobre el punto de origen"* — y el riesgo #7 de la misma ficha pide exactamente
confirmar que "no se pierde el toque si el dedo se mueve un poco al tocar". Hoy se pierde.

Un toque cancelado no produce **ninguna** respuesta (ni pulso, ni sonido, ni cambio de
estado) — es el peor caso posible frente a GDD §6 regla 5 ("todo elemento tocado reacciona
en <100 ms... aunque sea incorrecto"): aquí no reacciona en absoluto. Para Sofía, cuyo perfil
dice literalmente "se frustra rápido cuando algo no le sale", perder toques por el simple
movimiento natural del dedo sobre una tablet es la forma más segura de generar frustración
sin que el juego haya hecho nada "mal" desde su perspectiva — ella sí tocó la carta.

**Corrección concreta**: dejar de heredar de `Button`. Implementar `CartaEmparejar` como
`Control` (o `Area2D` + `CollisionShape2D`) con `_gui_input()`/`_input_event()` propio que
registre press+release por posición e índice de toque, aceptando el release como "toque
válido" si ocurre dentro de un radio de tolerancia (p. ej. 40-60 px lógicos) desde el punto
de press, **sin importar si el puntero salió momentáneamente del rect** durante el
movimiento — que es justo el comportamiento que `BaseButton` no ofrece.

---

**B2. Durante los ~500 ms de resolución de un "no es este" (`_procesando = true`), cualquier toque en otra carta se ignora por completo — cero feedback.**

En `motor_emparejar.gd`, `_al_tocar_carta()`:

```gdscript
func _al_tocar_carta(carta: CartaEmparejar) -> void:
    if _procesando or carta.esta_acertada:
        return
```

Mientras `_procesando` es `true` (los 500 ms entre un "no es este" y que las cartas se
destapen), tocar cualquier otra carta no dispara ni el pulso de selección ni ningún sonido:
el toque desaparece en silencio. Esto viola directamente GDD §6 regla 5 otra vez, y es
exactamente el riesgo #2 que el propio `disenador-mecanicas` pidió validar en la ficha de
motor: *"validar que no se sienta pegajoso para Sofía (que quiere ir rápido)"*. Con un
tablero de 8 pares en modo memoria, es altamente probable que una niña de 8 años impaciente
toque una tercera carta durante esa ventana — y el juego se sentirá "colgado" o que "no la
escuchó".

**Corrección concreta**: no ignorar el toque en silencio. O bien (a) reducir la ventana de
"no es este" y encolar el siguiente toque para procesarlo apenas se libere, o (b) mantener
la ventana pero, al recibir un toque mientras `_procesando`, igual reproducir el pulso de
"reconocido" (`_reventar_pulso()` + sonido corto) sobre la carta tocada aunque no sume a la
selección todavía — así el niño siempre recibe confirmación de que su toque existió.

---

**B3. No existe ningún nodo de Estelita tocable en la escena, y el motor nunca reproduce la línea `pista` — la regla obligatoria GDD §6.2 ("tocar a Estelita repite la instrucción") no está implementada.**

Se buscó "estelita"/"pista"/"anfitrion" en todo `scripts/motores/emparejar/` y
`escenas/minijuegos/emparejar/`: cero coincidencias. El campo `lineas_voz.pista` está en el
JSON del nivel y en el contrato de la ficha de motor, pero ningún código lo consume. La
ficha de nivel (§3) dice explícitamente que Sofía "puede pedir que Estelita repita la
instrucción tocándola" como su única ayuda (sin resaltados automáticos, por diseño de su
perfil Estrella) — hoy esa ayuda no existe en absoluto. El propio §10 de la ficha de nivel
pide a `tester-qa` validar el flujo "intro → volteo → acierto/no es este → **pista
opcional**" — ese paso es hoy imposible de ejecutar.

Esto no es un problema de arte/audio faltante (la voz puede seguir siendo un placeholder de
consola por ahora) — es la ausencia total del **mecanismo de disparo**. Dado que Sofía es
justamente la persona con mayor riesgo de frustrarse a mitad de un tablero de 8 pares, dejarla
sin ninguna vía de ayuda es un vacío real, no cosmético.

**Corrección concreta**: agregar un nodo tocable de Estelita (aunque sea un placeholder
circular con ícono/color, ≥96 px lógicos por ser el "botón de ayuda" universal del juego) en
`motor_emparejar.tscn`, conectado a un método que reproduzca `lineas_voz.pista` (vía el mismo
`_reproducir_voz()` placeholder que ya existe) y, si se define, repita también la última
instrucción relevante.

---

**B4. La escena no tiene ningún ícono de salida/volver — viola GDD §6.8 ("salir siempre es seguro"), obligatoria para *toda* pantalla.**

`motor_emparejar.tscn` no incluye ningún control de navegación (casa/flecha). Ejecutando la
escena tal cual está hoy, no hay ninguna forma de abandonar el nivel salvo cerrar la
aplicación. Es razonable que, arquitectónicamente, el ícono de salida viva en un componente
compartido (`escenas/ui/` según `docs/stack-tecnico.md` §3, junto a `estelita_ayudante`) que
envuelva a cualquier minijuego cuando se aloje dentro de una pantalla de planeta real — pero
mientras esa capa no exista, esta escena, tal como se puede ejecutar y testear hoy, no cumple
la regla. Como el DoD del tablero exige "ejecutar la escena afectada" antes de cerrar
tarjetas, y el smoke test de `tester-qa` (§9 de la ficha de motor) corre esta escena de forma
aislada, hoy un QA (o un niño en un playtest) queda atrapado sin salida.

**Corrección concreta**: dos caminos válidos, a elección de `dev-godot`/`scrum-master`: (a)
agregar ya un ícono mínimo de "volver" (≥96 px, esquina superior, con emisión de una señal
`salir_solicitado` que el nodo padre pueda conectar) directamente en esta escena para que sea
segura incluso ejecutada sola, o (b) si se decide que la salida es responsabilidad exclusiva
del futuro contenedor de pantalla, dejarlo **explícitamente registrado** como bloqueante
pendiente en el tablero antes de dar este motor por "listo para wiring", para que no se
pierda de vista.

---

### Mejoras

**M1. `limite_intentos: 16` para 8 pares en modo memoria real (850 ms de volteo) es ajustado — amerita playtest antes de darlo por bueno.**
Cumple la fórmula del contrato ("el doble de los pares"), pero el perfil de Sofía advierte
riesgo real de frustración ("se frustra y llora rápido"). En un juego de memoria de 8 pares,
16 intentos es razonable con memoria entrenada pero puede quedar corto para una primera
partida real. Recomendación: que `tester-qa` haga el playtest de humo forzando este límite
específicamente con Sofía (o simulando su ritmo) antes de aceptar el número; si falla seguido,
subir el límite o —siguiendo el patrón ya usado para Brote— dar una pista automática por voz
tras N intentos sin acierto sobre el mismo par, incluso en Estrella, sin llegar a resaltar
visualmente (para no regalarle el reto).

**M2. La etiqueta `etiqueta_gag` muestra el texto completo en pantalla como único canal visible del gag de derrota.**
Hoy incluye literalmente `"(TODO: voz derrota_gag)"` en el texto — es un placeholder de
desarrollo válido para el piloto, pero debe quedar registrado que **no puede llegar a un
build jugable por los niños** así: viola GDD §6.3 ("sin texto para navegar/instruir") si se
olvida quitar una vez exista la voz real. Recomendación: ocultar o quitar esta etiqueta de
texto en cuanto `lineas_voz.derrota_gag` se reproduzca por audio real, dejándola como mucho de
apoyo visual mínimo (ver GDD §2, Estrella admite "texto simple apoyado por voz", nunca texto
solo).

**M3. El tamaño de carta es fijo (140×140 px) sin importar la cantidad de pares del nivel.**
Cumple el mínimo (64 px) y el extra de Estrella con margen, pero para niveles Semilla/Brote
con 2-6 pares se desperdicia la regla de oro "ante la duda, más grande, más lento, más
celebración": con menos pares en pantalla hay espacio de sobra para cartas más grandes y
generosas, especialmente relevante si este motor se reutiliza para el nivel Semilla de Maxi
(que exige ≥96 px, no solo ≥64 px). Recomendación: escalar `TAMANO_MINIMO` en función de
`disposicion`/cantidad de pares del nivel cargado.

**M4. Separación entre cartas de 16 px es válida pero ajustada para motricidad fina en desarrollo.**
No es un riesgo para Sofía (8 años, motricidad fina ya buena), pero si este mismo motor se
reutiliza para Brote (Nicole, 5 años) con menos pares y cartas potencialmente más grandes,
conviene subir la separación a ~20-24 px para reducir el riesgo de que el dedo roce la carta
vecina. Dejar anotado para cuando se audite el nivel Brote de este motor.

---

### Pulido

**P1. Distinción visual selección (amarillo) vs. acierto (verde) es adecuada hoy, pero es solo color+texto — falta confirmar con sprites finales.**
La ficha de motor (riesgo #1) pide que ambos estados sean "visualmente muy distintos
(color/forma)". Hoy la diferencia es solo de color (más el hecho de que la carta acertada
queda deshabilitada); cuando existan los sprites reales de los ponys, reconfirmar que la
diferencia se mantenga clara también para daltonismo (no depender solo del canal de color).
Pendiente de auditoría cuando exista el arte.

**P2. El gag de derrota (giro de 360° por carta) es correcto en estructura pero no comunica humor sin el audio que lo acompañe.**
El código en sí respeta lo importante: solo gira cartas no acertadas, reintento de un toque,
cero progreso perdido (`_reintentar()` no reinicia pares ya acertados). Cuando exista la
"musiquita tonta" y el SFX de derrota-gag, confirmar en QA que se disparan en sincronía con el
giro (no antes ni después), para que efectivamente se lea como chiste y no como un glitch
visual aislado. Pendiente de auditoría cuando exista el audio.

---

## Pendiente de auditoría explícito (no evaluado aquí, correctamente fuera de alcance hoy)

- 8 sprites de ponys, dorso temático y fondo (`docs/fichas/nivel-piloto-emparejar-estrella-01.md` §9) — sin arte final.
- Líneas de voz reales/TTS (hoy son placeholders impresos en consola) — sin audio final.
- Gesto real de celebración de Sofía (mano en cintura, signo de la paz, guiño) — el motor solo deja un comentario `TODO(personajes)`, sin animación de personaje implementada todavía.

---

## Resumen de severidades

- **Bloqueantes: 4** (B1-B4) — impiden cerrar la tarjeta.
  - B1: `Button` nativo cancela el toque ante arrastre corto — sin tolerancia, viola contrato del motor y GDD §6 regla 5.
  - B2: toques durante los 500 ms de resolución de "no es este" se ignoran en silencio total — viola GDD §6 regla 5.
  - B3: no hay Estelita tocable ni disparo de la línea `pista` — viola la regla obligatoria GDD §6.2.
  - B4: no hay ícono de salida en la escena — viola GDD §6.8, "salir siempre es seguro".
- **Mejoras: 4** (M1-M4) — fricción evitable, no bloquean.
- **Pulido: 2** (P1-P2) — quedan condicionados a que exista arte/audio final.
