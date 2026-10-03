# HE-40 — Validación de la ficha de zonas del Planeta Arcoíris (`disenador-niveles`)

- **Revisor**: `disenador-niveles`, 28-Sep-2026.
- **Alcance**: `docs/fichas/planeta-arcoiris-zonas.md` (mapa 5 zonas × 4 estaciones, apertura,
  recompensas, variantes zona × hermano, riesgos), `datos/planetas/arcoiris/mapa.json` y los 71 JSON
  de `datos/niveles/arcoiris/` **tal como están en disco** (incluye el trabajo sin commitear:
  motor `mezclar` para Sofía, `lienzo_libre`/Pinta, `clasificar`). Lectura de apoyo:
  `scripts/nucleo/mapa_planeta.gd`, `scripts/autoloads/progreso.gd` y el cálculo de estrellitas y
  destellos de los motores (solo lectura, no se tocó código).
- **Fuera de mi alcance** (lo validan otros roles en HE-40): reglas y game feel de las mecánicas
  nuevas (`disenador-mecanicas`), carga cognitiva y tamaños (`experto-ux-parvulo`), voces de zona
  (`guionista`).
- El PO pidió avanzar sin consultarle: **toda decisión de este informe es una PROPUESTA de
  diseño** que el PO puede revertir. Se calibra en el playtest.

---

## Veredicto: **APROBADO CON CAMBIOS**

La estructura (5 zonas, 4 estaciones, apertura por zona completa, pieza al cerrar la zona 3, zonas
4-5 como expedición extra, rejugar sin perder nada) es sólida y respeta GDD §3, §5 y §6. Las 60
estaciones (20 por hermano) existen y son jugables en el mapa. Hay **1 hallazgo bloqueante** (bichos
en rutas donde juega Nicole), de corrección barata, y varios mayores sobre estrellitas, economía de
destellos y equidad entre Nicole y Sofía. Con los cambios de la sección 3 aplicados, la ficha queda
validada por mi rol.

---

## 1. Hallazgos

| # | Severidad | Hallazgo | Evidencia |
|---|---|---|---|
| 1 | **Bloqueante** | **Mariposas en rutas donde juega Nicole.** Su ficha lo prohíbe de forma explícita: "nada de arañas ni bichos en ningún nivel, fondo o transición donde juegue Nicole". Además Sofía siente "rechazo" y pidió "evitarlos". Dev ya había sacado la mariposa del espejo de Pinta, pero quedaron otras dos. Como todo está desbloqueado entre hermanos (GDD §5), Nicole puede entrar al taller de Sofía | `zona3_chupetines/formas_brote.json` (figura `mariposa` del pool de Nicole); `zona2_charcos/mezcla_estrella.json` y `zona5_cima/mezcla_estrella.json` (`dibujos_mural: "mariposa"`) |
| 2 | Mayor | **Umbrales de estrellitas de `emparejar` y `encajar` sin definir.** Hoy rige la regla provisional "3 estrellitas si sobra la mitad del límite". Contra la simulación de la ficha del motor (§5), eso da 3 estrellitas en apenas **~8-12 %** de las partidas de una jugadora que juega bien (12 pares, recetas, sombras y traviesas), pero en **~32 %** en tríos. Es inconsistente entre zonas y demasiado avaro para una niña que "se frustra y llora rápido" | `motor_emparejar.gd:924`, `motor_encajar.gd:1894`; ficha `motor-emparejar.md` §5 (medianas y percentil 80) |
| 3 | Mayor | **Economía de destellos desigual entre hermanos**, y el número se ve en el HUD del Mapa Estelar (`mapa_estelar.gd:113`). En una primera pasada estimo ~2.000 para Maxi, ~2.200 para Nicole y ~3.500 para Sofía, porque sus rompecabezas de 25-30 piezas dan 10 por pieza. La ficha de Nicole exige "celebraciones y recompensas siempre equivalentes entre ambas, sin comparaciones", y un contador que muestra 3.500 contra 2.200 es una comparación | constantes `DESTELLOS_*` de los 5 motores; `progreso.gd:268` |
| 4 | Mayor | **El marco dorado de Sofía (HE-47) y la "Corona de colores" (§2.2) son inalcanzables.** `evento_zona()` exige ≥3 estrellitas en *todas* las estaciones Estrella de la zona, y Pinta registra siempre 0 (`motor_lienzo_libre.gd:1712`). Es un premio prometido que nunca llega | `mapa_planeta.gd:312` |
| 5 | Mayor | **La ficha no refleja el motor `mezclar`.** La estación Lluvia de Sofía abre el Taller de pinturas (`mapa.json`, `escenas.sofia`), pero §3.1 sigue describiendo la Lluvia con clasificar. Los 5 `lluvia_estrella.json` quedan huérfanos y **comparten `id_nivel`** con `mezcla_estrella.json`. Esto último es a propósito, para no perder avance, pero no está documentado en la ficha de zonas | `mapa.json` y `motor-mezclar.md` (encabezado) |
| 6 | Mayor | **La ruta de Sofía casi no toca sus gustos.** Sus estaciones conectan muy bien con su curiosidad (datos, Chile, banderas) y con el reto, pero en 20 estaciones sus animales (ponys, perritos, gerbos, gatitos) y la estética kawaii/mágica solo aparecen en Pinta z5 (la insignia de pony). Según mis principios de rol, eso es contenido "técnicamente perfecto" que no le habla a ella | ficha §3.1-§3.4; `docs/perfil-jugadores.md` (Sofía) |
| 7 | Mayor | **La curva de Formas de Sofía es plana y larga.** Las zonas 1 a 5 tienen 25, 27, 24, 28 y 30 piezas, y desde el 27-Sep todas tienen giro y solo contorno. La zona 1, primer contacto, pesa lo mismo que la 3. Una estación con monumento más bandera puede pasar de 5 minutos (tope GDD §3), y **el avance se guarda solo al terminar cada ronda**, así que salir a mitad de un monumento de 30 piezas pierde ese avance, lo que va contra el espíritu de GDD §6.8 | ficha §3.2; `motor-encajar.md` §10 ("se guarda al terminar cada ronda") |
| 8 | Menor | **La estación de Sofía abre con el plato fuerte**: la lista de `rondas` pone primero el monumento y después la bandera, que es la ronda fácil. Con la bandera primero, el monumento queda como clímax | `formas_estrella.json` z1-z5, `"rondas": ["monumento", "bandera"]` |
| 9 | Menor | **Umbrales de `mezclar` iguales en z1 y z2** (2/5), aunque la z2 suma proporciones 2+1, 3 gotas simultáneas y variación de velocidad. Además, en z5 hay 9 latas con 4/9 | `mezcla_estrella.json` z1-z5 |
| 10 | Menor | **Formas de Maxi, zona 1, sin dinos ni autos.** El pool es casita, Japón, Francia, Italia, helado y pez. Es su primer contacto con el juego y le faltan sus dos temas fuertes. Las zonas 2 a 5 sí los traen (bus, bomberos, dino, autito) | `zona1_claro/formas_semilla.json` |
| 11 | Menor | **Gusanito de gomita** en el paisaje del mapa (§2.0). Es un dulce, pero la regla de Nicole dice "ningún fondo". Lo derivo a `experto-ux-parvulo` y al PO; propongo un osito de gomita, que evita la discusión | ficha §2.0; `paisaje_arcoiris.gd` |
| 12 | Menor | **Pinta para Maxi solo termina si él toca "mostrar a Coco"**, y con la regla de zona completa la estación es obligatoria para abrir la zona siguiente. Hay que confirmar que un niño de 2 años no quede "pintando para siempre" sin completarla (riesgo de trabarse, GDD §5 Semilla) | ficha §3.4; `motor_lienzo_libre.gd` |
| 13 | Menor | **Documentos desalineados** con la regla vigente (no los edito yo): GDD §3 dice "los planetas se desbloquean con 1-2 destellos", GDD §4 dice que la escena llega "al recuperar todos los destellos" y HE-17 en el tablero dice "mínimo ~6 estaciones". La regla vigente es pieza de la nave al completar la zona 3, es decir, 12 estaciones | `diseno-juego.md` §3/§4; `TABLERO.md` HE-17 |

Lo que **valido sin cambios**: el orden de colores (primarios en z1-z3, secundarios y brillo en
z4-z5); zonas dormidas sin candado; zona 5 secreta con resplandor; rejugar con pools barajados; que
el reto dorado no cuente para abrir zonas; que Cometa lleve a la siguiente estación (riesgo 5); las
rutas de Maxi (sin error en ningún motor: `limite_intentos: null` y `sin_error`) y de Nicole (límite
solo en Lluvia z3-z5 y Formas z4-z5, siempre holgado, con derrota-gag y regalo); los momentos
memorables por zona (dinos que caminan, gota-jirafa, corazón dorado, "te corono líder", murales,
datos curiosos, decorar el ala).

---

## 2. Decisiones tomadas (PROPUESTA de `disenador-niveles`, a calibrar en el playtest)

### 2.1 Regla de apertura

- **Se confirma la decisión del PO del 27-Sep**: la zona siguiente, y la secreta, se abre al
  completar **todas las estaciones jugables** de la zona anterior. La regla temporal
  `min(2, estaciones jugables)` **queda retirada definitivamente**: hoy los 4 juegos existen para
  los 3 hermanos en las 5 zonas, así que se exigen 4 de 4 por zona. El código ya lo hace
  (`mapa_planeta.gd:199`).
- Se mantiene el filtro "jugable" (nivel y escena existen) como red de seguridad: si un archivo
  faltara, nadie queda trabado.
- **Por qué no bloquea a nadie**: Pinta no tiene fallo; `mezclar` nunca termina en derrota;
  `emparejar` y `encajar` de Sofía tienen regalo tras 2 derrotas y pistas; Nicole tiene regalo y
  límites holgados; Maxi no puede perder. Toda estación es completable.
- Pieza de la nave (ala) y escena: al completar la zona 3 (12 estaciones, ~45-60 min por hermano).
  Confirmado.

### 2.2 Umbrales de estrellitas: formato común

Se adopta en `emparejar` y `encajar` el mismo campo que ya usan `clasificar` y `mezclar`:

```jsonc
"umbrales_estrellitas": { "tres": N, "dos": M }   // en fallos
```

Regla, igual en los cuatro motores con puntaje:

- Fallos ≤ `tres` → 3 estrellitas. Fallos ≤ `dos` → 2. Si no, 1.
- Si hubo derrota-gag → 1 estrellita.
- Cada pista, libreta o vistazo al modelo resta 1, sin bajar de 1.
- Ganar siempre da al menos 1.
- Si un nivel no trae el campo, se mantiene la regla actual como respaldo.

**Criterio de calibración**: 3 estrellitas en ~1 de cada 4 partidas de una jugadora que juega bien
(≈ percentil 25 de fallos de la simulación). Es exigente, como pidió el PO en la v3, pero se puede
lograr. `dos` = el límite (ganar sin derrota-gag = 2).

#### Emparejar (Sofía), a nivel del archivo

| Nivel | Límite | Mediana sim. | `tres` | `dos` | 3★ estimado (antes → ahora) |
|---|---|---|---|---|---|
| z1 · 12 pares | 16 | 13 | **10** | 16 | ~8 % → ~25 % |
| z2 · 10 recetas | 15 | 12 | **9** | 15 | ~8 % → ~22 % |
| z3 · 7 tríos | 42 | 29 | **17** | 42 | ~32 % → ~24 % |
| z4 · 14 traviesas | 24 | 19 | **15** | 24 | ~12 % → ~25 % |
| z5 · 16 sombras | 32 | 26 | **21** | 32 | ~8 % → ~25 % |
| z5 · reto dorado 18 | 42 | 34 | **27** | 42 | (no abre nada) |

#### Encajar (Sofía), **por ronda** en `config` de cada figura; vale la peor ronda

No hay simulación para `encajar`, así que para el monumento se mantiene el 50 % actual y la bandera
es más exigente, porque tiene pocas piezas.

| Zona | Monumento: límite / `tres` / `dos` | Bandera: límite / `tres` / `dos` |
|---|---|---|
| z1 | **14** (sube de 12, primer contacto) / 7 / 14 | 8 / 3 / 8 |
| z2 | 12 / 6 / 12 | 9 / 3 / 9 |
| z3 | 12 / 6 / 12 | 9 / 3 / 9 |
| z4 | 14 / 7 / 14 | 10 / 4 / 10 |
| z5 | 16 / 8 / 16 | México 10 / 4 / 10 · EE.UU. 14 / 5 / 14 |
| reto dorado (marco) | sin límite → 3 menos pistas (sin cambios) | — |

#### Mezclar (Sofía, fallos = "¡puaj!")

| Zona | Actual | **Propuesto** | Motivo |
|---|---|---|---|
| z1 | 2 / 5 | 2 / 5 | se mantiene |
| z2 | 2 / 5 | **3 / 6** | suma proporciones 2+1 y 3 gotas simultáneas |
| z3 | 3 / 6 | **3 / 7** | llega la gota gris (20 %) |
| z4 | 3 / 7 | **4 / 8** | el frasco ya no muestra cuántas gotas faltan |
| z5 | 4 / 9 | **5 / 10** | 9 latas y receta de memoria 6 s |

`clasificar` (Lluvia de Sofía, legado): sin cambios, porque ya no se juega desde el mapa. Maxi y
Nicole no tienen estrellitas en ningún motor (GDD §5).

**Meta del playtest**: si Sofía no logra 3 estrellitas en ninguna de sus primeras 5 partidas de una
estación, se sube `tres` en +2. Si las logra siempre al primer intento, se baja en 1.

### 2.3 Economía de destellos (20 estaciones por hermano)

1. **Las aperturas y la pieza cuentan estaciones completadas, nunca destellos** (se confirma el
   riesgo 2 de la ficha). Los destellos no abren nada dentro del planeta.
2. **Cada estación da un monto fijo e igual para los tres: 100 destellos la primera vez que se
   completa.** Rejugar suma 0, como ya hace `Progreso`. El conteo por par, pieza o gota se sigue
   viendo durante el juego como feedback (chispas), pero el total que se celebra y se guarda es 100.
   Planeta completo = 2.000 por hermano, zonas 1-3 = 1.200. **Iguales para Nicole y Sofía**, así el
   HUD nunca compara.
3. **Retos dorados: 0 destellos.** Su premio es cosmético (marco dorado o corona) y no cambia la
   igualdad de los contadores.
4. **Las estrellitas son la moneda propia de Sofía** (maestría, corona, reto dorado). Nunca se
   convierten en destellos.
5. **Mapa Estelar**: el planeta 2 se abre con la **pieza de la nave**, no con destellos. Esto
   reemplaza el "1-2 destellos" del GDD §3, que queda para que el PO lo actualice.

### 2.4 Maestría y marco dorado (hallazgo 4)

"Estación con puntaje" = estación cuyo nivel puntúa estrellitas. Pinta **no cuenta** para
"perfecta" ni para la Corona de colores. Así, la zona es perfecta con 3 estrellitas en Lluvia/Taller,
Formas y Parejas.

### 2.5 Contenido (hallazgos 1, 6, 8 y 10)

- **Mariposa → pony** en los murales de `mezclar` (z2 y z5). El pony es su animal favorito y su
  insignia: el mural de la cima termina siendo "su" pony arcoíris. Esto cierra el bloqueante y
  además conecta con Sofía.
- **Mariposa → pony** en el pool de Formas de Nicole z3 (ponys y caballos son tema confirmado de
  Nicole). Si el generador no logra un pony reconocible con lado ≥ 52 px, se usa una **flor en
  maceta** como respaldo.
- **Sofía, un guiño de sus gustos por estación, sin bajar el reto**:
  - Parejas z1: las 12 figuras-trampa pasan a ser **cachorros y ponys** (perrito, gatito, gerbo y
    pony, en colores distintos). La trampa de color se mantiene.
  - Parejas z5: el reto dorado conserva sus sombras y suma la silueta del pony como pareja
    especial.
  - Mezclar: el mural pony, ya mencionado arriba.
  - Mientras no haya dibujos de perrito ni gerbo, esto queda pendiente de `disenador-personajes`.
- **Orden de rondas de Sofía en Formas: `["bandera", "monumento"]`** en z1-z5. La bandera calienta y
  el monumento cierra como momento memorable, con su dato curioso.
- **Curva de Formas de Sofía** (propuesta al PO, sin tocar sus decisiones de contorno y giro):
  `piezas_en_bandeja` **4 en z1, 5 en z2-z3, 6 en z4-z5**, y límite 14 en el monumento de z1. A
  mediano plazo, que el pool de z1 use monumentos de 18-20 piezas (La Moneda recortada) y deje los
  de 25 o más para z2 en adelante.
- **Maxi, Formas z1**: se suma **autito** al pool, en lugar de Italia. Quedan casita (fija), Japón,
  Francia, helado, pez y autito.

---

## 3. Cambios precisos para `dev-godot`

Los números salen de la sección 2. La sección 7 de la ficha de zonas deja constancia de ellos.

1. **[Bloqueante]** `datos/niveles/arcoiris/zona2_charcos/mezcla_estrella.json` y
   `zona5_cima/mezcla_estrella.json`: reemplazar `"mariposa"` por `"pony"` en `dibujos_mural`, y
   agregar el dibujo `pony` al mural de `motor_mezclar.gd`. Mientras no exista, usar `"flor"` o
   `"arcoiris"`.
2. **[Bloqueante]** `zona3_chupetines/formas_brote.json`: sacar la figura `mariposa` del pool y
   generar `pony` (o `flor_maceta`) con `herramientas/figuras_formas.py --escribir`, con su
   `voz_completa`. Verificar que no queda ningún insecto en los datos ni en las láminas de Pinta de
   ningún perfil (`rg -i "mariposa|abeja|arana|bicho|insecto|catarina"`).
3. `motor_emparejar.gd` y `motor_encajar.gd`: leer `umbrales_estrellitas` (a nivel del archivo y,
   en `encajar`, también en `config` de cada figura/ronda) con la regla de la sección 2.2. Si falta
   el campo, conservar la regla actual. Documentarlo en `motor-emparejar.md` §7 y `motor-encajar.md`
   §5.
4. `parejas_estrella.json` z1-z5 y `parejas_estrella_dorado.json`: agregar
   `umbrales_estrellitas` con los valores de la tabla de 2.2.
5. `formas_estrella.json` z1-z5: agregar `umbrales_estrellitas` en el `config` de cada figura
   (monumento y bandera, tabla de 2.2). En z1, subir a 14 el límite de los monumentos. Cambiar
   `"rondas"` a `["bandera", "monumento"]` y ajustar `intro_ronda` si la intro de zona nombra el
   monumento primero. `piezas_en_bandeja`: 4 en z1, 5 en z2 y z3, 6 en z4 y z5.
6. `mezcla_estrella.json` z2-z5: umbrales 3/6, 3/7, 4/8 y 5/10.
7. **Economía**: que el total que se **suma** en `Progreso` al completar una estación sea un monto
   fijo de estación. Sugerencia genérica que respeta la regla de oro 3: `mapa.json` declara
   `"destellos_por_estacion": 100` y `"destellos_reto_dorado": 0`; `mapa_planeta.gd` los pasa al
   motor como propiedad del contrato base (`minijuego_base.gd`, p. ej. `destellos_fijos`), y
   `celebrar()` muestra y registra ese valor cuando viene definido. Fuera del mapa (demo, QA), cada
   motor conserva su cálculo actual. **No hace falta migrar el guardado**: lo ya ganado se respeta.
8. `mapa_planeta.gd` `evento_zona()`: calcular `perfecta` solo sobre las estaciones que puntúan.
   Opción genérica: el nivel declara `"puntua_estrellitas": false`, que se agrega a los 15
   `pinta_*.json`, o se excluyen las estaciones Estrella con 0 estrellitas **y** nivel sin
   límite/umbrales. Prefiero el campo explícito.
9. `zona1_claro/formas_semilla.json`: reemplazar `bandera_italia` por `autito`. Puede reutilizar el
   autito de 3 piezas de z5 u otra versión que genere el script.
10. `lluvia_estrella.json` z1-z5 (legado): agregar `"legado": true` y una nota de que solo los usa
    QA, o moverlos a una carpeta de fixtures de QA. Nunca deben cargarse desde el mapa. Su
    `id_nivel` se comparte con el Taller a propósito.
11. `lienzo_libre`, perfil Semilla: si Maxi pinta más de ~90 s sin tocar "mostrar a Coco", Coco
    pregunta "¿me lo muestras?" y el botón late. Otra opción: auto-mostrar la hoja tras un tiempo
    largo sin tocar. Sirve para que la estación siempre se pueda completar (hallazgo 12; lo valida
    UX).
12. Guardado **pieza a pieza** en las rondas `arma_figura` de Sofía, con el mismo mecanismo
    `guardar_avance` del marco, para que salir a mitad de un monumento no pierda el avance
    (hallazgo 7).
13. QA: extender `qa_test_encajar.gd` y `qa_test_parejas_zonas.gd` para que verifiquen la lectura
    de umbrales (3/2/1 en los bordes) y que no queda ninguna figura prohibida.

---

## 4. Lo que necesito de otros roles

- **`guionista`**:
  - `mural_pedido` con pony.
  - `voz_completa` del pony, o de la flor en maceta, de Nicole.
  - `intro_ronda` de Sofía con la bandera primero: "¡Primero, una bandera para calentar!" y
    "¡Ahora, el gran monumento!".
  - La voz de Coco "¿me lo muestras?" para Maxi.
  - Las voces de zona de la ficha §5 y el ajuste de `arcoiris_001`.
- **`disenador-personajes`**: dibujos de perrito, gerbo y pony para las cartas de Sofía y el mural
  pony; reconocibilidad de los moáis (ya pendiente); osito de gomita si el PO acepta el cambio del
  gusanito.
- **`disenador-mecanicas`**: validar que la regla común de umbrales (2.2) calza con la mecánica de
  cada motor, y el guardado pieza a pieza de `arma_figura`.
- **`experto-ux-parvulo`**:
  - Hallazgo 11 (gusanito).
  - Hallazgo 12 (Pinta de Maxi como estación obligatoria).
  - La duración real de Formas de Sofía (hallazgo 7).
- **PO**:
  - Aceptar o revertir las propuestas: economía fija de 100, curva de la bandeja de Sofía, orden
    bandera → monumento y los guiños de ponys y cachorros.
  - Actualizar el GDD §3 y §4 (hallazgo 13).
- **`scrum-master`**: corregir en HE-17 el disparador "mínimo ~6 estaciones", que ahora es la
  zona 3 completa.
