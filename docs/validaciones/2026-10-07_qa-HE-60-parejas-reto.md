# QA HE-60: Parejas de Coco con reto real (Nicole y Sofía)

- **Fecha**: 07-Oct-2026
- **Rol**: `tester-qa`
- **Tarjeta**: HE-60 (racha ×1–×5, "¡a la primera!", tiempo par con vela, récord personal, vistazo al
  repartir y estrellitas de Nicole por puntaje)
- **Spec**: `docs/fichas/motor-emparejar.md` §10.1, §10.1.1, §10.2 y §10.10
- **Código bajo prueba** (sin commitear): `motor_emparejar.gd`, `carta_emparejar.gd`, `minijuego_base.gd`,
  `progreso.gd` (carga en `_init`), `celebracion.gd`, `barra_record.gd`, `racha_cresta.gd`,
  `vela_cupcake.gd`, `dibujo_cupcake.gd`, `mapa_planeta.gd` y los 16 `datos/niveles/arcoiris/*/parejas_*.json`
- **Motor**: Godot 4.7.1 stable (consola), Windows 11

## Veredicto

**APRUEBA CON CAMBIOS. La tarjeta no puede cerrarse todavía.**

La mecánica está bien hecha y cumple la ficha en casi todo:

- la racha, el bono, la barra con banderita, la vela, el vistazo, las estrellitas de Nicole y el caso de
  Maxi funcionan como dice la spec;
- todos los arneses pasan;
- el juego arranca limpio;
- el guardado real quedó intacto.

Bloquea el cierre **un bloqueante**: se pierde la estación completada si el niño sale durante la nueva
secuencia de récord. Es una regresión de HE-60. También hay **tres mayores**: dos dependen de la tarjeta
de voces HE-67 y uno es de diseño, para `disenador-niveles`.

## 1. Qué se ejecutó y cómo

### 1.1 Protección del guardado real

- Antes de empezar se verificó que el juego no estuviera abierto.
- Se respaldaron `progreso.json` y `progreso_pruebas.json` en el scratchpad de la sesión.
- Después de cada arnés se comprobó el md5 del guardado real con un script runner
  (`correr_arneses.sh`, que restaura el archivo si cambia).

**El md5 de partida no era el esperado** (`a42d414c…`): era `ff55e2f4abf17f25618fa7ee446b11b0`. Se
investigó la causa:

- `progreso.json` se modificó a las 16:02. Los logs de usuario de Godot muestran una **sesión de juego
  real** a las 15:59 y a las 16:02: mapa, Parejas zona 1 como Sofía y Formas.
- En el guardado aparece el recuerdo `sofia_01` con fecha `2026-10-07 09:11:50`, y
  `especiales_conocidos: ["vistazo","vela"]` en Sofía.
- `a42d414c…` corresponde al respaldo de las 08:02 que hice en mi sesión anterior (cortada).

Conclusión: el cambio vino de partidas reales del PO, no de un arnés. Se tomó `ff55e2f4…` como línea
base. **Tras las 17 ejecuciones de arneses, los 3 arneses extra, las capturas y el arranque real, el md5
sigue en `ff55e2f4…`.** El guardado de pruebas se restauró a su md5 original (`9ce9eea7…`).

Sobre `herramientas/tmp_dbg/dbg_rio.gd` (09:02, sin trackear): no es mío. Es una depuración del Río,
del mismo horario que una sesión del dev. No lo borré. Ver m10.

### 1.2 Arneses del repo (headless, `--script`)

| Arnés | Resultado | Avisos en consola |
|---|---|---|
| `qa_test_parejas_reto.gd` (nuevo) | **OK, 0 fallos** | 10 × "línea pendiente de grabar" (voces `reto/`, HE-67) |
| `qa_test_parejas_zonas.gd` | **OK, 0 fallos** | 11 × `vistazo_mira.wav` pendiente; imprime `PEND 11/14 voces de reto` |
| `qa_test_retos_sofia.gd` | **OK, 0 fallos** | 18 × voces `reto/` pendientes + ruido de salida (§3) |
| `qa_test_emparejar.gd` | OK | ruido de salida (§3) |
| `qa_test_emparejar_rutas.gd` | OK | — |
| `qa_test_celebracion.gd` | OK | 1 voz de prueba inexistente (preexistente) |
| `qa_test_mapa_planeta.gd` | OK | ruido de salida |
| `qa_test_progreso.gd` | OK | "Parse JSON failed" **intencional** (§3) |
| `qa_test_encajar.gd` | **OK, 1906 checks** | — (la primera corrida se cortó por mi timeout de 600 s; se repitió sin límite) |
| `qa_test_clasificar`, `lienzo`, `mezclar`, `recuerdos`, `rio`, `viaje_arcade`, `titulo`, `voces` (921 OK) | OK | solo ruido de salida |

### 1.3 Arneses extra de QA (en el scratchpad, solo guardado de pruebas)

- **`qa_extra_he60.gd`**:
  - guardado viejo sin `especiales_conocidos`;
  - Nicole en la zona 1 con récord (sin vela);
  - vela que se apaga;
  - machaque (9.096 toques durante el vistazo, 25 a una misma carta y 300 toques al azar);
  - Nicole con el mínimo (1 estrellita);
  - salir justo después del último par;
  - salir durante el vistazo;
  - Maxi con toques al azar hasta terminar.
- **`qa_extra2_he60.gd`**: el vistazo de Nicole ronda por ronda, en el flujo real de las 5 zonas, y la
  ventana de salida de Maxi comparada con la de Nicole.
- **`qa_flujo_he60.gd`** (regresión del flujo principal):
  1. arranque (`carga.tscn` → título);
  2. mapa de Arcoíris como Nicole, entrar a Parejas de la zona 2 y jugarla fallando;
  3. celebración y vuelta al mapa (tarjeta con 1 estrellita);
  4. volver a entrar (pista "otra estrellita" y vela);
  5. salir con la flecha y volver al mapa.

  Resultado: **OK**.
- **Capturas en ventana real** (`capturar_he60.gd`): vistazo, vela con barra, "¡a la primera!", ×5 con el
  récord superado, celebración de Nicole y cresta de Maxi.

### 1.4 Arranque real del juego (escena principal, guardado real)

Comando: `godot --path . --quit-after 900` (con ventana, unos 15 s).

- La consola queda **limpia**: solo el banner de Godot y Vulkan, sin errores ni warnings.
- El md5 de `progreso.json` no cambió: `Progreso._init` carga sin reescribir un guardado v2 vigente.

Revisión de código de `_corre_desde_herramienta()`:

- sin `--script`/`-s` y con un MainLoop sin script devuelve false, así que el juego usa el guardado
  real;
- con `--script` devuelve true en `_init`. Antes, en `_ready`, el `_initialize()` del arnés podía
  adelantarse. El cambio es correcto.

## 2. Veredicto por criterio

| # | Criterio (ficha / encargo) | Veredicto | Evidencia |
|---|---|---|---|
| 1 | Todos los arneses corren headless sin errores | **Cumple** | §1.2: 17/17 OK y 0 fallos. Los únicos avisos son voces pendientes de HE-67 y ruido de salida |
| 2 | Arranque real sin errores con `Progreso` en `_init` | **Cumple** | §1.4 |
| 3 | "resources still in use" y "Parse JSON failed" | **Ruido, no bugs** | §3 |
| 4a | Racha ×1–×5 (tope), sube entre rondas, el fallo la corta sin restar | **Cumple** | reto: "racha con tope x5: 6200 = esperado"; "el fallo corta la racha y no resta puntos"; la cresta enciende 5 nuditos y pone ojos de estrella (captura ×5) |
| 4b | "¡A la primera!" +200 sin multiplicador, solo en tablero tapado, y nunca con cartas ya vistas (vistazo, ayuda) | **Cumple** | reto: "300 = 100 + 200"; "par ya visto: x2 = 200, sin bono" |
| 4c | Barra de puntaje con banderita del récord propio, salto y "¡récord!" sin pausa; sin récord no hay banderita y al final se clava | **Cumple en lógica**. Falta la voz (M2) | reto: "banderita a la altura de SU récord"; "queda clavada en el primer récord"; captura ×5 |
| 4d | Vela: Sofía siempre; Nicole solo con récord y nunca en la zona 1; < 80 px y fuera del tablero; no corre durante el vistazo ni las mini-fiestas; al apagarse no pasa nada; lo que sobra se vuelve puntos | **Cumple** | reto y extra: Nicole en la zona 1 con récord 999 no tiene vela; la vela dormida no quita pares, puntos ni estrellitas; bono +730/+640 |
| 4e | Vistazo: Nicole 1 par (≤ 10 cartas) o 2 pares (12–16), parejas completas, 3 s; Sofía `round(n/4)` sueltas sin repetir grupo, 2 s; no se puede saltar | **Cumple** | extra2: las 5 zonas de Nicole ronda por ronda (6, 8 y 10 cartas → 2 cartas; 12 → 4); extra: las 5 estaciones de Sofía (24→6, 20→5, 21→5, 28→7, 32→8); 9.096 toques durante el vistazo sin efecto |
| 4f | Estrellitas de Nicole por puntaje base (sin la vela): mínimo 1 y sin huecos en la celebración ni en el mapa | **Cumple** (ver m5 y m6) | extra: zona 5 fallando antes de cada par → 1 estrellita y 1 slot; flujo: tarjeta del mapa con 1 estrellita; captura de la celebración con 3 |
| 4g | Maxi: solo cresta y sonido; sin números, barra, vela, vistazo, récord ni estrellitas; ninguna regla lo castiga | **Cumple** | reto y extra: Maxi con toques al azar termina (110 destellos) y nunca aparecen barra, vela ni contador. Al cortarse la racha suena un "fiuu" suave, sin sonido de error |
| 4h | Un nivel sin `puntaje` ni `vistazo` se juega igual que antes | **Cumple** | reto: "sin cresta, barra ni vela", "sin vistazo" |
| 4i | Guardado: campos opcionales y guardados viejos compatibles | **Cumple** | extra: un perfil sin `especiales_conocidos` y un campo corrupto se reparan al marcar; `VERSION_ACTUAL` sigue en 2 |
| DoD 1 | Corre sin errores | **Cumple** | §1.2 y §1.4 |
| DoD 2 | Verificado jugando la parte afectada | **Cumple en PC** (arneses, flujo y capturas). Falta la tablet | — |
| DoD 3 | Reglas del GDD §6 (sin castigos; salir siempre es seguro) | **No cumple** | **B1** |

## 3. Mensajes de consola investigados (ruido, no bugs)

1. **"N resources still in use at exit" y "ObjectDB instances were leaked"**: aparecen en `emparejar`,
   `titulo`, `mapa_planeta`, `retos_sofia` y `viaje_arcade`.
   - Con `--verbose`, los objetos retenidos son siempre streams de audio que seguían sonando cuando el
     arnés llamó a `quit()`. Por ejemplo, `AudioStreamWAV victoria_final_01.wav` en emparejar,
     `confirmar.ogg` en título e `intro_dorado.wav` en el mapa.
   - Es ruido de cierre de los arneses, no una fuga del juego. El arranque real (§1.4) no lo muestra.
2. **"Parse JSON failed. Error at line 0: Expected key"**: sale solo en `qa_test_progreso.gd`, prueba 3,
   que escribe a propósito `"{ esto no es json valido ,,, "` para verificar que `Progreso` cae a datos
   por defecto. Es el comportamiento esperado.
3. **"Audio.reproducir_voz: línea pendiente de grabar … /emparejar/reto/…"**: son las voces del reto, que
   todavía no existen (`assets/audio/voces/arcoiris/emparejar/reto/` no existe). Depende de HE-67. Ver M2.

## 4. Hallazgos

### Bloqueante

**B1. Salir en los segundos posteriores al último par pierde la estación completada (regresión de HE-60).**

Antes de HE-60, `_celebrar_victoria` esperaba 0,9 a 1,6 s y llamaba a `celebrar()`, que guarda el
progreso antes de la fiesta (B1 de HE-10, GDD §6 regla 8). Ahora, entre el último par y `celebrar()`,
corren `_cobrar_vela()` y `_cerrar_record()`, que esperan a la voz.

Tiempo medido desde el último par hasta que se guarda el progreso:

| Caso | Ventana |
|---|---|
| Nicole, zona 2, sin récord | 1,99 s |
| Nicole, zona 2, con récord (vela y trofeo) | 3,32 s |
| Sofía, zona 1 | 3,37–3,40 s |

Las voces de récord todavía no existen. Cuando HE-67 las grabe, `_cerrar_record` va a esperar hasta
1,2 s + 3,5 s más, y la ventana puede llegar a unos 7 s. Es justo el momento de "¡nuevo récord!" con
el trofeo, cuando una niña de 5 años toca la pantalla.

Durante esa ventana la flecha de salir sigue activa. Al salir, el motor se libera (`change_scene` en
`mapa_planeta.gd`) y `marcar_nivel_completado` nunca se llama:

- se pierden los 100 destellos de la estación, las estrellitas y su cuenta para abrir la zona siguiente;
- el récord sí queda guardado, y el estado queda inconsistente: hay récord, pero la estación no figura
  como completada.

- **Reproducir** (arnés `qa_extra_he60.gd`, caso `_caso_salir_tras_ultimo_par`):
  1. Abrir Parejas de la zona 2 como Nicole (o de la zona 1 como Sofía).
  2. Completar todos los pares.
  3. 1,5 s después del último par, tocar la flecha de salir (o liberar el motor).
  4. `Progreso.esta_nivel_completado("nicole","arcoiris","arcoiris_z2_parejas_brote")` devuelve
     **false**. Se ve **FALLA** en las dos estaciones probadas (Nicole y Sofía).
- **Comparación**: Maxi (sin récord) a 1,0 s **conserva** la estación. Nicole a 1,0 s la **pierde**.
- **Esperado**: el progreso queda guardado en cuanto se forma el último par, antes de la vela y el récord.
- **Sugerencia para `dev-godot`** (no corrijo): registrar el completado (`_registrar_una_vez`) antes de
  `_cobrar_vela()`, o calcular destellos, estrellitas y récord y guardarlos todos juntos al terminar el
  tablero. Agregar este caso al arnés `qa_test_parejas_reto.gd`.

### Mayores

**M1. Las presentaciones de una sola vez se gastan sin voz, y el guardado real ya está afectado.**

`_hacer_vistazo()` y `_arrancar_tablero()` llaman a `marcar_presentacion_vista("vistazo" / "vela")`
aunque la voz `vistazo_presenta` o `vela_presenta` no exista: se reproduce el fallback `vistazo_mira`,
que tampoco existe, o nada. Quien juegue antes de HE-67 **nunca escuchará** la explicación del vistazo
ni de la vela.

Ya pasó en el guardado real. En la partida del PO del 07-Oct a las 15:59 (log de usuario: "vistazo_mira"
y "vela_presenta: línea pendiente de grabar"), Sofía quedó con `especiales_conocidos: ["vistazo","vela"]`
sin haber oído nada.

- **Reproducir**: con el guardado de pruebas limpio, abrir Parejas de la zona 1 como Sofía, esperar el
  vistazo y revisar `Progreso.especial_conocido("sofia","vistazo")`: da `true`, y en la consola aparece
  WARNING "pendiente de grabar".
- **Esperado**: solo se marca como vista si la voz de presentación sonó.
- **Acción**:
  - `dev-godot`: marcar solo si `_voz_existe(...)`;
  - PO / `scrum-master`: antes del playtest, quitar `especiales_conocidos` del perfil de Sofía en el
    guardado real (con respaldo), o esperar al arreglo y hacerlo entonces.

**M2. El reto suena "mudo" en momentos clave hasta que exista HE-67, y cada uso deja un WARNING.**

Faltan las 21 líneas de `reto/`. El fallback que menciona §10.10 cubre `racha_N`, `a_la_primera` y
`estrellitas_brote_N`. **No cubre** estas líneas, que quedan en silencio:

- `vistazo_mira` ("¡mira!");
- `record_pasa` ("¡récord!", que la ficha pide al pasar la banderita);
- `primer_record` y `record_nuevo`;
- `vela_presenta`, `vela_encendida` y `vela_dormida` (UX M7.3 exige que Coco diga algo positivo cuando
  la vela se apaga);
- `otra_estrellita`.

Sin voz, Nicole no entiende la vela, el vistazo ni la banderita (el juego no tiene texto obligatorio).

- **Esperado**: las voces existen, o el juego no queda en silencio en esos momentos.
- **Acción**: no llevar HE-60 al playtest hasta cerrar HE-67 (`guionista`, con OK de costo del PO).
  Esto no es un bug de `dev-godot`; es una dependencia que el tablero debe reflejar.

**M3. Los límites de Sofía no se recalibraron con el vistazo (diseño; derivar a `disenador-niveles`).**

La ficha §10.2 pide recalibrar `limite_intentos` y `umbrales_estrellitas` de Sofía, porque el vistazo
baja la mediana de fallos. El diff de los JSON Estrella solo agrega `puntaje`, `vistazo` y voces: los
límites y umbrales son los de antes. Como resultado, las 3 estrellitas de Sofía (y su reto dorado) se
vuelven más fáciles sin que nadie lo haya decidido.

Los `tiempo_par_s` y `umbrales_puntaje` están marcados como `"calibracion_reto": "HE-60 PROVISIONAL"`.

- **Acción**: que `disenador-niveles` corra el simulador con vistazo y ajuste los valores antes del
  playtest. No bloquea el cierre técnico de HE-60, pero sí la validez del playtest de reto.

### Menores

- **m1. La vela se presenta tarde.**
  - `_arrancar_tablero()` enciende la vela antes de `vela_presenta`, y `_voz_cuando_calle` espera hasta
    6 s a que Coco calle.
  - En partidas rápidas, la presentación sonó cuando el tablero ya había terminado. Arnés reto, Sofía: el
    orden fue `vela_encendida` → `primer_record` → `vela_presenta`.
  - Además, al volver a entrar, Nicole oye en fila: intro, vistazo, `otra_estrellita` y `vela_presenta`
    (flujo, paso 4). Es mucha charla seguida para 5 años; derivar a `experto-ux-parvulo`.
- **m2. La estela dorada de "¡a la primera!" cruza por encima de cartas tapadas.**
  - Dura unos 0,8 s, y el "+100" queda encimado con el "+200" y el trébol en la misma carta. Captura
    `sofia_03_a_la_primera.png`.
  - La regla m10 lo prohíbe para los números. La estela no es un número, pero también tapa las cartas.
- **m3. El trofeo-cupcake tapa la cresta de Coco.**
  - Se dibuja sobre su cabeza y tapa los nuditos (captura `nicole_record_final.png`). La ficha dice que
    Coco lo "sostiene".
  - Además, queda visible detrás de la celebración.
- **m4. La pompa de jabón del vistazo casi no se ve.** Su radio va de 30 a 10 px y queda encima de la
  barra de marcadores de ronda (captura `sofia_vistazo.png`). Es la señal de "esto dura poco".
- **m5. Equidad §10.1.1, punto 5.** Las estrellitas de Nicole caen girando, mientras que las de Sofía se
  llenan en huecos: la animación es distinta. La ficha pide "la misma animación, tamaño y sonido". Hay
  tensión con el punto 1 (Nicole sin huecos). Derivar a `disenador-mecanicas` / `experto-ux-parvulo`
  para que decidan.
- **m6. §10.1.1, punto 2, no implementado.** Falta que "Coco la atrape con la lengua y se la pegue en la
  cresta": la primera estrellita solo cae.
- **m7. Comentario engañoso en `qa_test_retos_sofia.gd`.** Dice que las voces de reto "se reportan aparte
  en `qa_test_parejas_reto.gd`", pero ese arnés no las reporta (solo `qa_test_parejas_zonas.gd` imprime
  `PEND`).
- **m8. Ventana preexistente de unos 0,9 s en todos los motores.** Aunque no es de HE-60, conviene
  saberlo: salir 0,5 s después del último par pierde la estación también para Maxi (extra2). Se
  arreglaría junto con B1.
- **m9. El récord después de una derrota-gag no está definido en la ficha.** Tras la derrota-gag de
  Sofía, el puntaje acumulado se conserva y puede marcar récord. Derivar a `disenador-mecanicas`:
  confirmar si es lo deseado.
- **m10. `herramientas/tmp_dbg/dbg_rio.gd`**: es basura temporal sin trackear, no mía. Que `dev-godot` la
  borre antes del commit para que no entre al repo.

### Observación de datos (para `disenador-niveles`, no es un bug)

En la zona 1 de Nicole, las rondas 1 y 2 están a la vista. Sin fallos, la racha llega a ×5 antes de la
única ronda tapada, y los umbrales quedan muy juntos (`dos` 3400 y `tres` 3800). Conviene confirmar con
el simulador que 2 y 3 estrellitas no estén casi aseguradas, o casi imposibles, con un solo fallo en la
ronda 3.

## 5. Para cerrar HE-60

1. `dev-godot` corrige **B1** y **M1** (marcar la presentación solo si hay voz), con sus casos en
   `qa_test_parejas_reto.gd`, y borra `tmp_dbg/`.
2. Re-test de QA, solo de B1 y M1, con los arneses extra de esta validación.
3. Antes del playtest:
   - HE-67 con las voces del reto (M2);
   - recalibración de Sofía (M3);
   - limpiar `especiales_conocidos` de Sofía en el guardado real.
4. Verificación en la tablet (DoD 2), sobre todo el tamaño de la vela (unos 45 px visibles) y la
   legibilidad de la barra.

## 6. Qué observar en el playtest de esta tarjeta (sin dirigir)

Pendiente hasta que estén las voces (M2):

- **Nicole**:
  - ¿mira la vela más que el tablero, o falla más cuando la vela está por terminarse? Si pasa, se pone
    `tiempo_par_s: null` (criterio M7.5);
  - ¿qué cara pone al recibir 1 estrellita (riesgo 10)?;
  - ¿entiende la banderita sin números?;
  - ¿recuerda alguna carta del vistazo?
- **Sofía**:
  - ¿persigue el ×5 y el récord?;
  - ¿se frustra cuando la vela se apaga?;
  - ¿pide "otra vez" para superar su banderita?
- **Maxi**: ¿le da risa el "ding" que sube y los nuditos?; ¿le molesta cuando se apagan?
- **Pregunta para después**: "¿Qué hacía la velita del cupcake?" y "¿Qué pasaba cuando Coco se ponía
  los ojos de estrella?"
