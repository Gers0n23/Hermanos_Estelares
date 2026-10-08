# Calibración: Batalla final de Arcoíris y Parejas en equipo

- **Autor**: `disenador-niveles`
- **Fecha**: 07-Oct-2026 (v3, con las decisiones del PO del 07-Oct-2026 y la segunda corrida del
  simulador)
- **Tarjetas**: HE-66 (diseño de la batalla), HE-69 (implementación), HE-59 (Parejas en equipo)
- **Fuentes**:
  - `docs/fichas/modo-equipo.md` v6, §5, §8, §11.2, §11.4 y §14;
  - la re-auditoría UX de HE-66 (`docs/validaciones/2026-10-06_ux-HE-66-batalla-arcoiris.md`, N1-N3);
  - `docs/fichas/motor-emparejar.md` §10;
  - GDD §5 y §6.
- **Simulador**: `herramientas/simular_equipo.py` (3.000 partidas por escenario). Lo corrió el
  coordinador el 07-Oct, dos veces:
  - la v1, sin tope (§3);
  - la v2, con el tope de pares por turno y el **retroceso por turno perfecto como default** (§4, §5 y
    §9). Los porcentajes de esta ficha son de la v2.
- **Estado**: valores **fijados en los datos**. Siguen provisionales solo hasta el playtest con los
  niños. **v4**: corridas del 07-Oct aplicadas (§11 y §12).

## Cambios de la v4 (07-Oct-2026)

- **Cifras con el resbalón tras turno perfecto** (v6.1 de `modo-equipo.md`, ya modelo por defecto del
  simulador): Parejas de la batalla **91 %** (antes 89 %) y "los tres" por zona 82 / 86 / 85 / 96 / 96 %,
  con los mismos `pasos_rival` (§4, §5). `arcoiris_final.json` actualizado (Parejas 0,91).
- **Simulador v3**: modela `resbalon_tras_racha` en el Río y corre el Río sin y con resbalón (§12).
  Corrige un error del modelo: la cadena de Maxi en el Río contaba como racha y hacía retroceder al
  rival, pero `maxi_mueve_rival` es `false`.
- **HE-60, QA M3**: recalibración de los límites y umbrales de Sofía en Parejas en solitario por el
  vistazo, con `herramientas/calibrar_parejas_sofia.py` (§11).
- **Corridas**: las hizo el coordinador el 07-Oct-2026 (`disenador-niveles` no tenía consola), con las
  reglas de decisión fijadas antes de correr. Resultado: límites y umbrales nuevos de Sofía aplicados
  (§11.4); `resbalon_tras_racha: true` en el Río, que queda en 87 %, y batalla sin estornudos ≈ 79 % (§12.3).

## Cambios de la v3

- El PO aprobó el 07-Oct-2026 el **tope de pares por turno** `pares_max_turno` {semilla 1, brote 2,
  estrella 3} (en la batalla, "los tres" y maxi+nicole), el **retroceso del rival por turno perfecto**
  en Formas y Parejas (en el Río sigue la racha de 3) y los **tableros 4×6 con Maxi** (§9).
- La clave de datos es `pares_max_turno` (ya no `pares_max_turno_propuesta`).
- `pasos_rival` finales: "los tres" **5** en todas las zonas, nicole+sofia en z2 y z3 **11**, Parejas de la
  batalla **5** (§4 y §5).
- Voces: claves genéricas del §11.4 de `modo-equipo.md` (`derrota_gag_equipo`, `logro_comun`) y
  `turno_perfecto` con los ids del guion (§8).

## 1. Archivos

| Archivo | Qué es |
|---|---|
| `datos/batallas/arcoiris_final.json` | La batalla con el esquema del §14.9, más campos informativos (`motor`, `resumen`, `duracion`, `premio`) |
| `datos/niveles/arcoiris/batalla/rio_equipo.json` | Ronda 1, rojo |
| `datos/niveles/arcoiris/batalla/formas_equipo.json` | Ronda 2, amarillo: la nave de juguete, 12 piezas |
| `datos/niveles/arcoiris/batalla/parejas_equipo.json` | Ronda 3, azul |
| `datos/niveles/arcoiris/batalla/pinta_mochila_equipo.json` | Epílogo |
| `datos/recorridos/arcoiris/batalla_espiral.json` | El cauce del Río de la batalla (M5.2) |
| `datos/niveles/arcoiris/zona{1..5}/parejas_equipo.json` | Parejas en equipo de las 5 zonas |
| `datos/planetas/arcoiris/mapa.json` | `destellos_equipo_por_hermano: 50`, bloque `batalla` y `nivel_equipo` en las 5 estaciones de Parejas |
| `herramientas/simular_equipo.py` | El simulador |

**No se tocó** ningún `parejas_<perfil>.json` individual, porque HE-60 está en curso (§7).

## 2. Supuestos de tiempo y la regla de los 2 turnos

**Tiempos**:

- pase real de tablet: 8-12 s (M1 de UX HE-66);
- turno de Maxi: ≈ 5 s, más el ritual de 1,2 s;
- Río: Nicole 4 s y Sofía 2,5 s por disparo;
- Formas: Nicole 5,5 s y Sofía 6,5 s por pieza;
- Parejas: Nicole 3 s y Sofía 2 s por jugada, más 1,5 s si falla.

**Regla de los 2 turnos** (B2.3): con los tres, el orden es M N M S M N M S. El segundo turno de Sofía es
el **turno 8**, así que lo que se haga en los turnos 1-7 **no puede terminar la ronda** en una partida
típica.

## 3. Resultados de la primera corrida (07-Oct, sin tope) y qué se cambió

| Escenario | Corrida v1 | Problema | Cambio |
|---|---|---|---|
| R1 Río, 24 gotas, 6 pasos | Gana 57 % (7: 72 %, 8: 83 %, 9: 92 %). p50 4,1 y p80 **5,3 min**. Turnos M7 N3 S3 | Largo y difícil: mi cuenta a mano sobreestimó cuánto baja el río en cada turno | **20 gotas, 7 pasos** |
| R2 Formas, 12 piezas, 5 pasos | Gana 95 %. p50 2,8 y p80 3,1 min. Cada hermano juega ≥ 2 turnos en el 100 % | — | Sin cambios de cantidades (con turno perfecto sube a 100 %, §4) |
| R3 Parejas, 10 pares, 5 pasos | Gana 99 %. p50 1,9 min. M3 N2 **S1**: ≥ 2 turnos solo en el 32 % (con 8 pares: 1 %) | Sofía limpia el tablero en un turno. **Agregar cartas no lo arregla** | **Tope de pares por turno** (§9), **12 pares en 4×6** y **5 pasos** |
| Zonas, los tres | ≥ 2 turnos: z1 52 %, z2 48 %, z3 49 %, z4 7 % y z5 6 %. Gana 99-100 % | El mismo patrón: demasiado fácil | Tope, 12 pares en 4×6 (z4 y z5: 11 + comodín) y **5 pasos** |
| Zonas, nicole+sofia | Gana z1 83 %, **z2 46 %, z3 49 %**, z4 77 % y **z5 64 %** | z2 y z3 (12 pares) y z5 muy duros | z2 y z3 pasan de 8 a **11 pasos**; z5 de 7 a **8 pasos** |
| Zonas, maxi+nicole | En z1 (6 pares), ≥ 2 turnos solo en el 53 % | Nicole puede limpiar todo en su primer turno | Tope {Maxi 1, Nicole 2} y +1 paso (7) |

**Mi error de origen**: en Parejas y en el Río, el avance de la cuenta a mano era el promedio, pero la
varianza (los turnos excelentes de Sofía en Parejas y los disparos neutros en el Río) domina el
resultado. Por eso el simulador manda.

## 4. Las rondas (v3)

### Ronda 1 · Río de pintura (rojo): 20 gotas y `pasos_rival` 7

**Simulado** (v2, racha de 3; en el Río no hay turno perfecto, `modo-equipo.md` §5.2):

- se gana el **86 %** al primer intento (v4: **87 %** con `resbalon_tras_racha: true`, §12.3);
- ≈ 11 turnos (Maxi 6, Nicole 3, Sofía 2-3);
- p50 ≈ **3,5 min** y p80 ≈ **4,4 min** (debajo de 5).

**Palancas en este orden**, si el playtest muestra que es largo o difícil:

1. 18 gotas (el simulador lo trae como referencia);
2. +1 paso;
3. Nicole con 4 gotas por turno (requiere al `disenador-mecanicas`).

No subo la velocidad del río: la de Maxi (13 px/s) está fijada en la ficha, y con el tope del 70 % el
río no decide la ronda.

**Momento memorable**: el primer reventón rojo salpica las gafas-lupa del Coleccionauta ("¡veo todo
rojo!").

**Gag de derrota**: el del §14.5 (aspira las gotas y las estornuda de vuelta).

### Ronda 2 · Formas traviesas (amarillo): 12 piezas, tope {1, 2, 3} y `pasos_rival` 5

**Simulado** (v2, turno perfecto):

- se gana el **100 %**;
- p50 2,8 y p80 3,1 min;
- turnos M4 N2 S2;
- cada hermano juega ≥ 2 turnos en el 100 % (cierra N1).

**Se deja en 5 pasos**: es la ronda del medio, el respiro entre el Río y Parejas, que ponen la tensión.
Si el playtest la encuentra sosa, la palanca es -1 paso (4).

**La figura**: la nave de juguete del living, con 3 ventanitas en los colores de turno.

**Momento memorable**: las caritas de los tres se asoman por las ventanitas (el ícono de "¡Juntos!").

### Ronda 3 · Parejas en equipo (azul): 12 pares en 4×6, tope {1, 2, 3} y `pasos_rival` 5

- Tope aprobado por el PO (§9). El rival retrocede por **turno perfecto** de Nicole (2 pares) o Sofía
  (3 pares); como todos los perfiles tienen tope, la racha de 3 no rige en esta ronda y
  `rival_retrocede_celebra` no se usa (`modo-equipo.md` §5.2 y §8).
- Con el tope, los turnos 1-7 forman como máximo 1 + 2 + 1 + 3 + 1 + 2 + 1 = **11**, así que **12 pares
  garantizan el segundo turno de Sofía**. Es la misma cuenta que cerró N1 en Formas.
- **Simulado** (v2, turno perfecto): se gana el **89 %** con 5 pasos; ≈ 11 turnos (M6 N3 S2), p50 ≈
  3,3 min y p80 ≈ 4 min. **Con el resbalón tras turno perfecto (v6.1): 91 %**, mismos 5 pasos.

**Momento memorable**: la pareja lupa es la lupa de las gafas del Coleccionauta.

### Epílogo · Pinta la mochila (no se pierde)

- **Partes**: 3 pisos más la tapa "¡todos juntos!".
- **Duración**: ≈ 45 s.
- **Momento memorable**: la mochila estornuda confeti de los colores regalados.

### Curva y duración de la batalla

**Curva** (simulador v2):

| Ronda | Se gana al primer intento | Rol |
|---|---|---|
| Río | 87 % con `resbalon_tras_racha` (85 % sin, v3) | Enseña al rival |
| Formas | 100 % | Respiro |
| Parejas | 91 % con resbalón (89 % sin) | Clímax |

La batalla se gana sin ningún estornudo ≈ **79 %** de las veces (simulador v3: 79,4 %; antes 77 %).

**Duración**:

| Escenario | Duración |
|---|---|
| Típica | ≈ 9,6 de rondas + ≈ 2,5 de cinemáticas, interludios y epílogo ≈ **12,1 min** |
| p80 | ≈ **14,0 min** |
| p80 con una derrota | ≈ **15 min**, justo en el tope |

- La pausa entre rondas (jugarla en dos sesiones es el caso normal) absorbe el exceso.
- Si el playtest muestra cansancio, la primera palanca es el Río con 18 gotas.

## 5. Parejas en equipo por zona (v3)

**Formato de las celdas**: pares, grilla y **`pasos_rival`**. "T" = lleva `pares_max_turno`.
"+C" = más el comodín.

| Zona | Especiales | Vistazo | maxi+nicole (T 1/2) | maxi+sofia | nicole+sofia | los tres (T 1/2/3) |
|---|---|---|---|---|---|---|
| 1 | — | 2 pares | 6, 3×4, **7** | 8, 4×4, **5** | 10, 4×5, **8** | 12, 4×6, **5** |
| 2 | lupa | 2 pares | 8, 4×4, **7** | 10, 4×5, **6** | 12, 4×6, **11** | 12, 4×6, **5** |
| 3 | lupa | 2 pares | 8, 4×4, **7** | 10, 4×5, **6** | 12, 4×6, **11** | 12, 4×6, **5** |
| 4 | lupa + comodín | 3 pares | 8 + C, 3×6, **7** | 10, 4×5, **6** | 11 + C, 4×6, **8** | 11 + C, 4×6, **5** |
| 5 | lupa + comodín | 3 pares | 9 + C, 4×5, **7** | 10, 4×5, **5** | 11 + C, 4×6, **8** | 11 + C, 4×6, **5** |

**Resultados del simulador v2** (turno perfecto como default; se gana al primer intento):

| Composición | z1 | z2 | z3 | z4 | z5 |
|---|---|---|---|---|---|
| Los tres | 79 % | 83 % | 83 % | 96 % | 96 % |
| Los tres, con resbalón tras turno perfecto (v6.1) | 82 % | 86 % | 85 % | 96 % | 96 % |
| nicole+sofia | 83 % | 76 % | 77 % | 77 % | 76 % |
| maxi+nicole | ≈ 100 % | ≈ 100 % | ≈ 100 % | ≈ 100 % | ≈ 100 % |

**Lectura**:

- **Los tres**: con el turno perfecto, el retroceso deja de ser exclusivo de Sofía y el rival se frena
  más; por eso bastan 5 pasos en todas las zonas. z1 queda en 79 %, un punto bajo la meta del 80 %: se
  acepta (es la zona de bienvenida del modo y la diferencia está dentro del ruido del simulador); si el
  playtest la siente dura, +1 paso. z4 y z5 quedan en 96 %: con el comodín, el tablero rinde más; si el
  playtest las siente fáciles, -1 paso.
- **nicole+sofia** (meta ≈ 75 %): z2 y z3 mantienen los 12 pares, el escalón de reto de memoria para
  las dos mayores, con **11 pasos** (76-77 %). Sin tope: ahí Maxi no come turnos y rige la racha de 3.
- **maxi+nicole**: ≈ 100 %, que es lo correcto con Maxi en el equipo (Semilla = nunca trabarse); el
  tope {1, 2} garantiza el segundo turno de Nicole.
- **maxi+sofia** queda sin tope (la corrida v1 lo dio bien).

## 6. Diferencias con `modo-equipo.md` (para `disenador-mecanicas`)

Todas resueltas en la v6 de `modo-equipo.md` (07-Oct-2026); se dejan como registro.

1. **§14.3 / M1.1**:
   - Río: de 24 a 20 gotas.
   - Formas: de 8 a 12 piezas (N1).
   - Parejas de la batalla: de 8 pares en 4×4 a 12 pares en 4×6, con tope (§9).
2. **§5.3, "con Maxi, el máximo es 4×5"**: **4×6 con Maxi aprobado por el PO** (07-Oct-2026). En el
   tablero `Rect2(40, 128, 1200, 472)` el alto manda: 4 filas dan cartas de ≈ 110 px con 5 o con 6
   columnas. Con eso, "los tres" tiene 12 pares (o 11 + comodín).
3. **§5.3**: la composición de la zona 5 "10 pares 4×5 con lupa y comodín" no cabía (21 cartas).
4. **§5.4**: en las zonas 1-3 el vistazo es de 2 pares (dentro del máximo de 3).
5. **Retroceso por "turno perfecto"** (aprobado por el PO, 07-Oct-2026): con los topes, Nicole (tope 2)
   nunca llegaba a una racha de 3 en Formas ni en Parejas, y solo Sofía hacía retroceder al
   Coleccionauta. Ahora retrocede una galleta cuando Nicole o Sofía llegan a su tope sin que un fallo
   termine su turno. En el Río sigue la racha de 3 (`modo-equipo.md` §5.2).
6. **Campos de datos nuevos** (aceptados en `modo-equipo.md` §14.9):
   - Río: `guia_por_perfil`, `carga_semilla`, `umbral_reventon_semilla` (N2), `cadena_vale_aciertos`,
     `justo_ahi_px` y `rio_se_detiene_en_pase`.
   - Formas: `capas_perfil`, `soltar_en_vacio_es_fallo` e `id` por pieza.
   - Parejas: `especiales[].variante` y **`composiciones.<clave>.pares_max_turno`** (§9).
   - Epílogo: `orden_fijo`, `parte_por_hermano`, `cierre_todos_juntos` y `color_inicial_por_perfil`.
   - Batalla: `retomar_empieza` (N6) y `pausa_entre_rondas`.

## 7. Recomendaciones para HE-60 (Parejas en solitario): **no aplicadas** (la recalibración de Sofía por el vistazo está en el §11)

1. `agregar_reto_parejas.py` no modela las especiales. Cuando lleguen a los niveles individuales, hay que
   volver a simular: el comodín sube el puntaje, y los `umbrales_puntaje` de Nicole quedarían bajos.
2. Antes de fijar `tiempo_par_s`, hay que medir en el playtest los segundos por jugada. La vela de Sofía
   (1,1 veces la mediana) es sensible a ±0,5 s.
3. La zona 1 de Nicole sin vela es correcta (M7.4).

## 8. Voces que faltan (para `guionista`, HE-67)

Van como `"PENDIENTE"` en los JSON, en plural y sin nombres en los fallos. Antes de cualquier TTS hay que
correr `--estimar` y tener el OK del PO sobre el costo.

Las claves de derrota y logro común son las genéricas del §11.4 de `modo-equipo.md`
(`derrota_gag_equipo`, `logro_comun`), iguales en las tres rondas. `turno_perfecto` ya tiene ids en el
guion de la batalla (`nucleo_equipo_turno_perfecto_01/02`, Cometa,
`voces/nucleo/equipo/turno_perfecto_0N.wav`) y está puesto en Formas y en Parejas.

| Dónde | Voces pendientes |
|---|---|
| Río | `intro_ronda`, `maxi_toca_donde_quieras`, `justo_ahi`, `maxi_regalito`, `gafas_rojas`, `derrota_gag_equipo` y `logro_comun` |
| Formas | `intro_ronda`, `maxi_pieza_que_brilla`, `caritas_ventanitas`, la `voz_completa` de la nave, `derrota_gag_equipo` y `logro_comun` |
| Parejas | `intro_ronda`, `lupa_coleccionauta`, `logro_comun` y `pares_juntados` 11-12 |
| Epílogo | `intro_epilogo`, `maxi_ven_a_pintar`, `ahora_hermano`, `todos_juntos`, `mochila_estornuda_confeti` y `victoria_final` |
| Mapa | ~~`voz_hito`~~ **resuelta (v4)**: variantes `voces/arcoiris/batalla/hito_01.wav` y `hito_02.wav` (`arcoiris_batalla_hito_01/_02`, guion de la batalla §2 y §10.1). Falta grabarlas (casera, papá) |
| Todos los niveles de equipo | `maxi_regalito` |

## 9. Regla aprobada: tope de pares por turno en Parejas en equipo

**Aprobada por el PO el 07-Oct-2026**, junto con el retroceso por turno perfecto. Está en
`modo-equipo.md` v6 (§5.2 y §8) y en los datos como `composiciones.<clave>.pares_max_turno`.

**La regla**:

- En Parejas en equipo, cada hermano forma como máximo `pares_max_turno[perfil]` pares por turno:
  - **Semilla 1**: ya era la regla, `pares_turno_semilla`;
  - **Brote 2**;
  - **Estrella 3**.
- Al llegar al tope, el turno **termina en celebración**:
  - Cometa dice "¡turno perfecto!" y el hermano hace su gesto corto;
  - nunca suena como fallo;
  - las cartas quedan como están.
- **Turno perfecto = el rival retrocede una galleta** si quien llegó al tope es Nicole o Sofía (Maxi
  nunca mueve al rival). Donde hay tope, la racha de 3 no rige.
- Es la misma forma y la misma voz que Formas (B2.1). Así hay **una sola regla de tope para todas las
  rondas con aciertos**.

**Dónde se aplica**:

- en la batalla;
- en "los tres" y en "maxi+nicole", en todas las zonas.

No se aplica a maxi+sofia ni a nicole+sofia: ahí rige la racha de 3 (la corrida mostró que el tope no
hace falta).

**Por qué es la regla correcta y no más cartas**:

- En el memorice de mesa, el turno de un buen jugador crece con lo que el tablero ya mostró. En
  cooperativo, eso hace que la mayor termine sola el tablero ("llevar" al equipo, el riesgo 5 del §9 de
  `modo-equipo.md`).
- El tope le da a Sofía un objetivo visible por turno (3 seguidas) en vez de "limpiarlo todo", y a
  Nicole el suyo (2 seguidas).
- Con el retroceso por turno perfecto, ese objetivo es además el que frena al rival, para las dos por
  igual: sigue siendo reto real, no "dificultad de bebé".

**Números con la regla**:

| Escenario | Cuenta | Resultado |
|---|---|---|
| Los tres | Los turnos 1-7 forman como máximo 11 | Con 12 pares, Sofía siempre juega su segundo turno |
| maxi+nicole | Los turnos 1-3 forman como máximo 1 + 2 + 1 = 4 | Con 6 o más pares, Nicole siempre juega su segundo turno |
| Pasos | El tope alarga la partida unos 3-4 turnos, pero el turno perfecto frena al rival | "Los tres" queda en 5 pasos en todas las zonas (§5) |

**Simulador** (`herramientas/simular_equipo.py` v2):

- `Parejas.__init__(..., tope=None)`.
- En `Parejas.turno`, después de cada acierto:
  `if aciertos >= self.tope.get(h, 99): return aciertos, seg + 1.0, False, 0.0`.
- `jugar_ronda(..., perfecto=None)`: con `perfecto` = el tope, retrocede 1 si
  `aciertos >= perfecto[h]` (y no es Maxi). **Es el default** desde la decisión del PO.
- `leer_tope()` lee `pares_max_turno` de cada composición.
- `--sin-tope` corre sin tope, solo para comparar.

**Metas usadas para fijar `pasos_rival`**:

- Río y Formas: 85 %;
- Parejas: 80 %;
- nicole+sofia: 75 %.

## 10. Supuestos abiertos para el PO

1. **Tamaños**:
   - Río con 20 gotas;
   - Formas con 12 piezas;
   - Parejas de la batalla con 12 pares.
   
   El p80 con una derrota queda en el tope de 15 min, y la pausa entre rondas lo absorbe.
2. **La curva de las rondas**: Río 87 %, Formas 100 % y Parejas 91 % (batalla sin estornudos ≈ 79 %; v4, con los resbalones).
   Formas al 100 % es un respiro deliberado; el playtest dirá si conviene bajarla a 4 pasos.
3. **Los momentos memorables piden arte**: gafas rojas, caritas en las ventanitas y la lupa del
   Coleccionauta.
4. **Los 100 destellos** de la batalla siguen como [Propuesta].
5. **El besito de Coco no rompe el turno perfecto** : **[PO, 07-Oct-2026] confirmado**
   (`modo-equipo.md` §5.2); el simulador ya lo calibra así.

## 11. Parejas en solitario de Sofía: límites y umbrales con el vistazo (HE-60, QA M3)

### 11.1 El problema

HE-60 le agregó a Sofía el **vistazo al repartir** (`motor-emparejar.md` §10.2): `round(cartas / 4)`
cartas sueltas, nunca dos del mismo grupo, durante 2 s. Los JSON Estrella ganaron `puntaje`, `vistazo` y
voces, pero `limite_intentos` y `umbrales_estrellitas` siguen siendo los de HE-40, que se calibraron
**sin** vistazo. El vistazo regala información, baja los fallos y, sin que nadie lo decidiera:

- las 3 estrellitas pasan a salir más que en ~1 de cada 4 partidas bien jugadas;
- la derrota-gag pasa a salir menos que en ~1 de cada 5;
- el reto dorado de la zona 5 (que se abre con 3 estrellitas) llega antes.

Eso es justo la "dificultad de bebé" que el playtest del 03-Oct-2026 pidió evitar (regla de oro 2).

### 11.2 Criterio (no cambia)

Se mantiene el de HE-40 (`docs/validaciones/HE-40_disenador-niveles.md` §2.2), porque es el que el PO
aceptó y el que el playtest va a medir:

| Valor | Criterio | Qué significa para Sofía |
|---|---|---|
| `tres` | ≈ p25 de fallos de una jugadora que juega bien | 3 estrellitas en ~1 de cada 4 partidas: hay que jugar mejor que su mediana |
| `limite_intentos` | ≈ p80 de fallos | Derrota-gag en ~1 de cada 5: el reto es real, pero nunca imposible para 8 años |
| `dos` | = límite | Ganar sin derrota-gag = 2 estrellitas |

El vistazo **no es una pista**: no resta estrellitas (§10.2). Lo que cambia es la jugadora simulada,
que ahora parte con esas cartas vistas.

### 11.3 Método: el corrimiento del vistazo

`herramientas/calibrar_parejas_sofia.py` usa la jugadora del §5 de `motor-emparejar.md`:

- memoria de ~5 cartas que olvida la más antigua;
- sombras con 8 % de confusión y traviesas con 50 % de olvido de cada carta movida;
- en los tríos, el intento termina en la primera carta que no coincide.

Juega 3.000 partidas por nivel **dos veces con las mismas semillas**: sin vistazo y con el vistazo del
nivel. No se toman los percentiles crudos, sino **cuánto los corre el vistazo**:

```text
limite_nuevo = limite_vigente + (p80 con vistazo − p80 sin vistazo)
tres_nuevo   = tres_vigente   + (p25 con vistazo − p25 sin vistazo)
dos_nuevo    = limite_nuevo
```

**Por qué el corrimiento y no los percentiles crudos**: el simulador original de HE-40 no quedó en el
repo, así que este modelo puede diferir en ±1 fallo del de entonces. Aplicar solo el corrimiento
**conserva** la calibración aceptada y descuenta exactamente lo que regala el vistazo. El script imprime
también el % de 3 estrellitas y de derrota-gag sin vistazo con los valores vigentes: si da ≈ 25 % y
≈ 20 %, el modelo coincide con el de HE-40.

**Lo que se espera** (estimación a mano, **no** es resultado): con memoria de 5, el vistazo llena la
memoria de entrada, pero esa ventaja se gasta en los primeros 2-3 intentos. El corrimiento debería ser de
**1 a 2 fallos** en los tableros de 10-12 pares y de **2 a 3** en los de 16-18. Si la corrida da 0 en
algún nivel, ese nivel queda como está y se anota.

### 11.4 Resultados (corrida del coordinador, 07-Oct-2026; **aplicados** con `--escribir`)

Comandos: `python herramientas/calibrar_parejas_sofia.py` y luego `... --escribir`. `--escribir` cambia solo
`limite_intentos`, `umbrales_estrellitas` y agrega `calibracion_estrellitas`; no toca `puntaje`, `vistazo`
ni las voces.

**Fallos simulados (p25 / p50 / p80)**:

| Nivel | Sin vistazo | Con vistazo | Corrimiento p25 · p80 |
|---|---|---|---|
| z1 · 12 pares (cachorros y ponys) | 10 / 12 / 16 | 9 / 11 / 14 | −1 · −2 |
| z2 · 10 recetas | 7 / 8 / 11 | 5 / 7 / 9 | −2 · −2 |
| z3 · 7 tríos | 18 / 23 / 33 | 17 / 23 / 32 | −1 · −1 |
| z4 · 14 traviesas | 15 / 18 / 23 | 14 / 17 / 21 | −1 · −2 |
| z5 · 16 sombras | 21 / 25 / 30 | 19 / 23 / 29 | −2 · −1 |
| z5 · reto dorado, 18 sombras | 27 / 32 / 39 | 26 / 31 / 38 | −1 · −1 |

**Valores y efecto (siempre con vistazo)**:

| Nivel | Vigente (límite · tres) | 3★ / derrota con vigentes | **Nuevo (límite · tres · dos)** | 3★ / derrota con nuevos |
|---|---|---|---|---|
| z1 | 16 · 10 | 46 % / 9 % | **14 · 9 · 14** | 34 % / 18 % |
| z2 | 15 · 9 | 82 % / 1 % | **13 · 7 · 13** | 60 % / 2 % |
| z3 | 42 · 17 | 26 % / 7 % | **41 · 16 · 41** | 22 % / 8 % |
| z4 | 24 · 15 | 39 % / 8 % | **22 · 14 · 22** | 30 % / 15 % |
| z5 | 32 · 21 | 41 % / 9 % | **31 · 19 · 31** | 28 % / 11 % |
| Dorado | 42 · 27 | 34 % / 8 % | **41 · 26 · 41** | 30 % / 10 % |

**Lectura**:

- **M3 se confirma**: con los valores vigentes y el vistazo, las 3★ salían en el 34-46 % de las partidas,
  y en z2 en el 82 %. Con los nuevos quedan en **22-34 %** en z1, z3, z4, z5 y dorado, cerca del ~25 %
  objetivo, con derrota-gag entre 8 % y 18 %. Sigue siendo reto real y nunca imposible.
- **El modelo no reproduce exacto el de HE-40**: sin vistazo, los valores vigentes daban más de 25 % de
  3★ en varias zonas. Es la razón para usar el corrimiento y no los percentiles crudos; las cifras
  absolutas de 3★ se leen como tendencia y las afina el playtest.
- **z2 queda fácil (60 % de 3★)**: ver §11.6. No es efecto del vistazo; ya era fácil desde HE-40 (67 % sin
  vistazo).

Actualizados con estos valores: `planeta-arcoiris-zonas.md` §7.2 y `motor-emparejar.md` §5.

### 11.5 Riesgos y palancas

- **Regenerar borra la calibración**: `generar_niveles_sofia.py` reescribe estos JSON con los valores de
  HE-40. Si se vuelve a correr, después hay que correr `agregar_reto_parejas.py` y luego este script.
  Lo ideal es que `dev-godot` pase los valores nuevos a `generar_parejas()` cuando estén.
- **Las especiales (HE-61) vuelven a mover todo**: la lupa baja fallos, la dorada no los cambia y el
  Coleccionauta los sube un poco. Cuando entren, se vuelve a correr este script con las especiales
  modeladas (`motor-emparejar.md` §10.3, "Recalibrar").
- **Playtest** (la meta de HE-40 sigue): si Sofía no logra 3 estrellitas en ninguna de sus primeras 5
  partidas de una estación, `tres` +2; si las logra siempre al primer intento, `tres` −1. Observar
  también si el vistazo le sirve de verdad (¿busca primero las cartas que vio?). Si no las usa, el
  corrimiento real es menor que el simulado y la palanca es `tres` +1.
- **Fuera de este encargo, observación de QA**: en la zona 1 de Nicole, los `umbrales_puntaje`
  quedaron muy juntos (`dos` 3400, `tres` 3800) porque las rondas 1 y 2 son a la vista y la racha llega
  a ×5 antes de la ronda tapada. Hay que revisarlo con `agregar_reto_parejas.py` antes del playtest de
  Nicole (no se tocó).

### 11.6 Observación para el PO: z2 de Sofía (recetas) sigue fácil [Propuesta, no aplicada]

- **Qué pasa**: con 13 · 7, Sofía saca 3★ en el **60 %** de las partidas (objetivo ~25 %) y la derrota-gag
  sale en el 2 % (objetivo ~20 %). El tablero de 10 pares en 4×5 es el más chico de su ruta, y el
  simulador modela las recetas como pares idénticos, sin costo extra por "leer" la receta. Por eso la cifra
  real podría ser algo menor, pero no al punto de llegar al 25 %.
- **Propuesta**: **límite 10 · tres 5 · dos 10**. Con los percentiles con vistazo (p25 5, p80 9), eso
  apunta a ~25 % de 3★ y ~12-15 % de derrota-gag (estimado a partir de los percentiles, no corrido con
  esos valores). Antes de aplicarlo, conviene correr el script con esos valores para confirmar.
- **Alternativa más suave**: 11 · 6 (≈ 40 % de 3★ y ≈ 8 % de derrota), si el PO prefiere no endurecer de
  golpe la segunda estación.
- **Por qué no se aplica todavía**: el salto de 15 · 9 (HE-40) a 10 · 5 es grande para una niña que se
  frustra rápido. Es una decisión del PO, idealmente después de ver a Sofía jugar z2 en el playtest. Si
  no logra 3★ en sus primeras 5 partidas con 10 · 5, la palanca es `tres` +2 (la regla de HE-40).
- **Otra palanca de diseño, sin tocar umbrales**: subir z2 a 12 recetas en 4×6, como z1. Le da a la
  zona más contenido de mezclas (lo que más le conecta a Sofía en Arcoíris), pero cambia arte, voces y
  tablero. Queda anotada para cuando se revisen los niveles de Sofía con las especiales (HE-61).

## 12. Río de la batalla: resbalón tras la racha de 3 (v6.1)

### 12.1 La pregunta

`modo-equipo.md` v6.1 §5.2: si en el turno de Nicole o Sofía el rival retrocedió al menos una vez por la
racha de 3, ¿en el pase siguiente **se resbala y no avanza**, como tras un turno perfecto? Es el campo
`equipo.resbalon_tras_racha` de `batalla/rio_equipo.json` (hoy ausente = `false`).

**Regla de decisión** (fijada antes de correr, para no acomodarla al resultado):

| Río con resbalón, 7 pasos | Decisión |
|---|---|
| < 85 % | `false` (no puede pasar: el resbalón solo puede subir el %) |
| 85-95 % | **`true`** en `batalla/rio_equipo.json`; `ganar_al_primer_intento_estimado` = la cifra con resbalón |
| > 95 % | `true`, pero el Río queda sin tensión: se propone al PO **bajar** `pasos_rival` (el simulador imprime el menor que queda en 85-95 %) o sumar gotas |

> **Error en `modo-equipo.md` §5.2 (para `disenador-mecanicas`)**: dice "si con el resbalón el Río pasa
> del 95 %, proponer al PO **subir** `pasos_rival`". Más pasos le dan más camino al rival y lo hacen
> todavía **más fácil** para los niños. La palanca correcta es **bajar** `pasos_rival` o sumar gotas.

### 12.2 Qué cambia en el simulador (v3)

- `jugar_ronda(..., resbalon_racha)`: si el turno tuvo `aciertos // 3 ≥ 1` (Nicole o Sofía), en el pase
  el rival no avanza. Una sola vez por pase, aunque haya retrocedido dos veces. Cuenta también en la
  galleta 0, igual que el turno perfecto.
- **Corrección**: la cadena de Maxi (1 + 2 = 3 aciertos) hacía retroceder al rival en la v2, pero
  `maxi_mueve_rival` es `false`. Por eso el Río "sin resbalón" de la v3 puede dar 1-2 puntos **menos** que
  el 86 % de la v2. **La cifra "antes" válida es la de la v3 sin resbalón**, no el 86 %.
- Lee `gotas`, `colores` y `pasos_rival` de `rio_equipo.json` y corre el Río sin y con resbalón con la
  misma semilla; al final imprime el resumen, la recomendación según la tabla del §12.1 y la batalla
  completa sin estornudos (Río × Formas × Parejas).

### 12.3 Resultados (corrida del coordinador, 07-Oct-2026: `simular_equipo.py --batalla`)

| | Sin resbalón tras racha | Con resbalón tras racha |
|---|---|---|
| Río, 20 gotas, 7 pasos (v2, con el error de Maxi) | 86 % | — |
| Río, 20 gotas, 7 pasos (v3) | 85,3 % | **87,2 %** |
| Batalla sin ningún estornudo (v3) | 77,6 % | **79,4 %** |
| Referencia: Río con 18 gotas | — | 90 % |
| Formas, 12 piezas | 100 % con 5 pasos (98 % con 3) | |
| Parejas, 12 pares | 91 % con 5 pasos | |

**Decisión (regla del §12.1)**: 87,2 % está entre 85 y 95 %, así que va **`true`**. **Aplicado**:

- `"resbalon_tras_racha": true` en el bloque `equipo` de `batalla/rio_equipo.json`;
- Río `ganar_al_primer_intento_estimado` **0,87** en `arcoiris_final.json`, con su `fuente`;
- curva del §4: batalla sin estornudos **≈ 79 %**.

**Lectura**:

- **Sube menos de lo que estimé a mano** (+1,9 puntos, no +4 a +8): en el Río, la racha de 3 en un turno es
  más rara de lo que supuse. No hace falta compensar: el Río sigue siendo la ronda que "enseña al rival"
  sin regalarse.
- **Sin resbalón, el Río (85,3 %) quedaba en el límite de la meta del 85 %** una vez corregido el error
  de Maxi. El resbalón lo devuelve a un margen cómodo.
- **El motivo principal es de lectura, no de balance**: con `false`, la última imagen del turno era "lo
  hicimos tropezar… y avanzó igual" (recencia, UX N10). Con `true`, la batalla tiene **una sola regla
  visible**: "si lo haces retroceder, en el pase se resbala".
- **Palancas del playtest, sin cambios**: si el Río se siente largo o difícil, primero 18 gotas (90 %).
  Formas sigue al 100 % con 5 pasos; si se siente sosa, 3 pasos todavía dan el 98 %.

Las zonas (Parejas sin tope: `maxi+sofia`, `nicole+sofia`) siguen con `resbalon_tras_racha` ausente hasta
el playtest, como dice §5.2.
