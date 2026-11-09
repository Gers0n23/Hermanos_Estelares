# Recalibración de Arcoíris para la política de derrota (HE-125)

- **Autor**: `disenador-mecanicas`, 05-Nov-2026 (tarjeta HE-125, hija de HE-124).
- **Origen**: decisión del PO del 05-Nov-2026, textual: *«definimos dificultades demasiado faciles para todos
  los niveles. perder si debe ser una opcion para que sea entretenido para los niños, incluso aunque se
  frustren un poco.»* El PO delegó las decisiones de detalle. La regla general está en el GDD §6 regla 11; los
  4 motores de Animalia ya la tienen en sus fichas.
- **Qué es esto**: para cada juego de Arcoíris, **qué parámetro concreto** de `datos/niveles/arcoiris/` (y de
  `datos/recorridos/arcoiris/` cuando aplica) cambia, con **valores propuestos** por perfil y zona, y qué
  **claves nuevas** necesita el motor. Los valores actuales son los de los JSON reales (leídos el 05-Nov-2026).
- **Estado**: PROPUESTA DECIDIDA (el PO delegó). Faltan: los cambios de código de las claves nuevas
  (`dev-godot`), la aplicación de los valores y su calibración con los simuladores (`disenador-niveles`), las
  voces nuevas (`guionista`) y la auditoría (`experto-ux-parvulo`, `tester-qa`).
- **No toca**: el modo equipo salvo las batallas (§9-§10), ni los archivos marcados `"legado": true`
  (`lluvia_estrella.json` de cada zona, que el mapa nunca carga), ni los `lluvia_*.json` de la zona 1 (la zona
  1 abre el Río con los mismos `id_nivel`).

---

## 0. Reglas comunes (valen para los 7 juegos)

### 0.1 Metas de calibración

| | Sofía · Estrella | Nicole · Brote | Maxi · Semilla |
|---|---|---|---|
| Gana al **primer intento** (jugador simulado de su edad) | **~60 %** (meta en p40) | **~75 %** (p25) | **~90 %** (p10) |
| Relojes de derrota (sol, nube) | 1,6 × tiempo par | 2,2 × tiempo par | 3 × tiempo par |
| Regalo de Coco | tras **3** derrotas seguidas | tras **2** | tras **2** |
| Ayuda fuerte (victoria asegurada en el intento siguiente) | — | — | tras **3** |
| Ofrecer descansar, sin obligar | tras 4 | tras 3 | — |

Los números de este documento son la **mejor estimación a mano**; `disenador-niveles` los mueve con los
simuladores que ya existen (Río HE-92, `herramientas/agregar_reto_parejas.py`, `herramientas/simular_equipo.py`,
arnés de la Torre) hasta caer en esos porcentajes. **Lo que no se negocia son los porcentajes**, no los números.

### 0.2 Lo que nunca cambia

Gag que da risa, reintento de un toque (botón ≥ 160 px o tocar el cartel), nada guardado se pierde (lo ya
ganado dentro del nivel —rondas, figuras, murales, tandas— queda ganado), destellos y estrellitas **solo al
ganar**, y nunca zumbidos, pantallas rojas, caras tristes ni conteos regresivos. Equivocarse sigue recibiendo
ánimo ("¡casi!").

### 0.3 Claves nuevas comunes (requieren código; retrocompatibles)

| Clave | Tipo | Defecto si falta | Qué hace |
|---|---|---|---|
| `regalo_derrotas` | int | `2` | Cuántas derrotas seguidas disparan el regalo que ya existe (`regalo_tras_derrotas: true`). Hoy está fijo en 2 en `motor_clasificar.gd` (`_derrotas >= 2`), `motor_emparejar.gd` (`_derrotas >= 2`) y `motor_encajar.gd`. **Estrella: 3** |
| `ayuda_fuerte_tras_derrotas` | objeto o `null` | `null` | Solo Semilla: `{ "derrotas": 3, ... }` con el efecto propio de cada motor (abajo). Coco lo presenta como juego nuevo ("¡ahora lo hacemos juntos!"), nunca como "más fácil" |
| `descanso_tras_derrotas` | int o `null` | `3` | Coco ofrece ir a otra cosa. Estrella 4 · Brote 3 · Semilla `null` |

Además, cada motor que hoy no tiene derrota en Semilla necesita la línea `lineas_voz.derrota_gag` de Semilla
(encargo a `guionista`: frases de invitación, "¡otra vez, otra vez!", nunca "perdiste").

---

## 1. Río de pintura — motor `rio` (zona 1, los tres; `zona3_chupetines/rio_estrella.json` preparado)

El Río **ya admite derrota** en los tres perfiles (la cabeza llega al remolino, PO 17-Oct-2026). Está fácil:
se endurece con velocidad, subida, largo y menos arcoíris.

| Campo | Semilla z1 (`rio_semilla.json`) | Brote z1 (`rio_brote.json`) | Estrella z1 (`rio_estrella.json`) | Estrella z3 (`rio_estrella.json`, aún no en el mapa) |
|---|---|---|---|---|
| `velocidad` (px/s) | 13 → **16** | 24 → **30** | 42 → **50** | 48 → **56** |
| `subida` | 0,35 → **0,45** | 0,35 → **0,5** | 0,6 → **0,75** | 0,7 → **0,85** |
| `gotas` | 50 → **56** | 50 → **60** | 70 → **80** | 80 → **90** |
| `arcoiris.uno_cada` | 9 → **11** | 14 → **18** | 20 → **26** | 22 → **28** |
| `tiempo_par` (estrellitas) | 170 → **185** | 120 → **140** | 125 → **140** | 150 → **165** |
| `grupo`, `colores`, `batidora`, `guia`, `radio` | sin cambio | sin cambio | sin cambio | sin cambio |
| `regalo_tras_derrotas` **(nueva en el Río)** | `{ "derrotas": 2, "velocidad_factor": 0.85, "arcoiris_inicial": true }` | igual | `{ "derrotas": 3, ... }` | igual que z1 |
| `ayuda_fuerte_tras_derrotas` | `{ "derrotas": 3, "tope_avance": 0.85 }` | `null` | `null` | `null` |

- **Regalo**: el río siguiente avanza un 15 % más lento y Coco empieza con una gota arcoíris en la boca.
- **Ayuda fuerte de Maxi**: reutiliza `tope_avance` (ya existe para `rio_equipo.json`): el río se frena al 85 % y
  nunca llega al remolino; Coco lo cuenta como "¡el remolino se durmió!".
- **Recorrido** (`datos/recorridos/arcoiris/z1_espiral.json`): **sin cambios**. Acortar la espiral subiría la
  dificultad, pero se comparte con el Río de la batalla y la muestra del PO; la palanca es la velocidad.
- Con 80-90 gotas la cola espera más en la nube (R6 de `motor-rio.md`): la barra de "cuánto río queda" pasa a
  ser imprescindible.

## 2. Formas traviesas — motor `encajar` (5 zonas, los tres)

Hoy pierde solo Sofía (`limite_intentos`); Nicole tiene `null` en z1-z3 y 12 en z4-z5 (inalcanzable con 6-7
piezas), y Maxi tiene `sin_error: true` con imán de 5000 px.

### 2.1 Semilla (todos los `formas_semilla.json`)

- `sin_error: true`, `iman_tolerancia_px: 5000` y `toque_lleva_a_casa: true` **se quedan**: soltar mal sigue
  sin existir.
- **Clave nueva `sol_derrota`** (requiere código): `{ "s_por_pieza": 4, "factor_par": 3.0, "minimo_s": 30 }`. El
  tiempo par de cada figura es `piezas × s_por_pieza` (3 piezas → 12 s) y el solcito de la figura dura 3 × par
  (36 s). Solo pierde un Maxi que dejó la figura a medias mucho rato.
- `regalo_tras_derrotas: true` (2): Coco pone una pieza. `ayuda_fuerte_tras_derrotas: { "derrotas": 3,
  "sin_sol": true, "halo_siguiente": true }`: la figura siguiente no tiene sol y la pieza que va brilla.
- Gag: el solcito se esconde detrás de la figura y las piezas sueltas bailan y se caen de risa (1,5 s).

### 2.2 Brote (todos los `formas_brote.json`)

| Campo | z1 | z2 | z3 | z4 | z5 |
|---|---|---|---|---|---|
| `limite_intentos` (por figura) | null → **4** | null → **4** | null → **5** | 12 → **6** | 12 → **6** (la figura con override 16 → **8**) |
| `sol_derrota` (nueva) | `{ "s_por_pieza": 6, "factor_par": 2.2, "minimo_s": 45 }` | igual | igual | igual | igual |
| `regalo_tras_derrotas` (nueva en Brote) | `true` | `true` | `true` | `true` | `true` |

- Pierde por fallos **o** por sol, lo que llegue primero. Con `guia_color` y `objetivo_guiado`, una niña de 5
  años que mira la silueta rara vez suma 4 fallos en una figura de 6 piezas: es el p25 buscado.
- `iman_tolerancia_px` (110) **no se toca**: bajarlo castiga la motricidad, no la comprensión.

### 2.3 Estrella (todos los `formas_estrella.json`, en la raíz y en cada `config` de figura)

| Grupo | z1 | z2 | z3 | z4 | z5 |
|---|---|---|---|---|---|
| `limite_intentos` banderas | 8 → **5** | 9 → **6** | 9 → **6** | 10 → **7** | 10 → **7** |
| `limite_intentos` monumentos | 14 → **9** | 12 → **8** | 12 → **8** | 14 → **9** | 14 → **9** / 16 → **11** |
| `umbrales_estrellitas` | `tres` ≈ 45 % del límite, `dos` = límite (bandera z1: 3/8 → **2/5**; monumento z1: 7/14 → **4/9**) | ídem | ídem | ídem | ídem |
| `regalo_derrotas` (nueva) | **3** | 3 | 3 | 3 | 3 |

- Sin reloj para Sofía en Formas [decisión]: el tangram es un reto de reflexión y su presión ya es el límite de
  intentos; sumarle sol mezclaría dos presiones en el juego donde más se frustra.
- `formas_estrella_dorado.json` (z5): sigue sin límite (`null`) y sin regalo; es opcional.

## 3. Parejas de Coco — motor `emparejar` (5 zonas, los tres)

Hoy pierde solo Sofía. `limite_intentos` cuenta **fallos** (no aciertos) y **ya se puede poner por ronda**
(override de ronda en `motor_emparejar.gd`): Maxi y Nicole se resuelven **solo con datos** salvo el regalo de 3.

| Perfil | Campo | Valor propuesto |
|---|---|---|
| Semilla (todos los `parejas_semilla.json`) | `limite_intentos` **por ronda** | `2 × pares + 2`: 2 pares → **6**, 3 pares → **8**, 4 pares → **10** |
| | `regalo_tras_derrotas` | `true` (Coco pone un par) |
| | `ayuda_fuerte_tras_derrotas` | `{ "derrotas": 3, "sin_limite": true, "halo_idle": true }` |
| Brote (todos los `parejas_brote.json`) | `limite_intentos` en rondas **visibles** | `pares + 3` |
| | `limite_intentos` en rondas **tapadas** (`"oculto": true`) | `ceil(1,75 × pares) + 1`: 4 pares (z1, "tapadas") → **8**; 6 pares → **12** |
| | `regalo_tras_derrotas` | `true` |
| Estrella (raíz de cada `parejas_estrella.json`) | `limite_intentos` | z1 14 → **10** · z2 13 → **10** · z3 (tríos) 41 → **30** · z4 22 → **16** · z5 31 → **23** |
| | `umbrales_estrellitas` (`tres` / `dos`) | z1 9/14 → **6/10** · z2 7/13 → **5/10** · z3 16/41 → **12/30** · z4 14/22 → **10/16** · z5 19/31 → **14/23** |
| | `regalo_derrotas` (nueva) | **3** |

- `parejas_estrella_dorado.json` y `parejas_equipo.json` de cada zona: sin cambios aquí (equipo, §10).
- En Semilla las cartas siguen a la vista o con vistazo; el límite es tan amplio que solo se alcanza tocando al
  azar sin mirar, y el gag es Coco que se enreda con las cartas y estornuda confeti.

## 4. Lluvia de colores — motor `clasificar` (zonas 2-5, Maxi y Nicole)

Hoy la gota que llega al suelo "nunca castiga: vuelve a caer" (`_gota_al_suelo`), y en Maxi (`modo: libre`) no
hay soltar mal posible. Así, nadie pierde: Nicole tiene `limite_intentos` null en z2 y 12 en z3-z5 con tandas de
7 (inalcanzable).

**Clave nueva `escapes_cuentan`** (bool, defecto `false`; requiere código en `_gota_al_suelo`): con `true`,
cada gota que llega al suelo sin clasificar **suma un fallo de la tanda** (y sigue volviendo a caer, como hoy).
La derrota sigue siendo la de `limite_intentos` por tanda (Nicole: Coco se tiñe y estornuda un arcoíris).

| Campo | z2 | z3 | z4 | z5 |
|---|---|---|---|---|
| **Semilla** `escapes_cuentan` | **true** | true | true | true |
| Semilla `limite_intentos` (por tanda) | null → **6** (tanda de 10) | null → **6** (10) | null → **3** (4) | null → **4** (6) |
| Semilla `velocidad_caida` | 105 → **115** | 115 → **125** | 95 → **105** | 150 (igual) |
| Semilla `regalo_tras_derrotas` / ayuda fuerte | `true` / `{ "derrotas": 3, "escapes_cuentan": false }` | igual | igual | igual |
| **Brote** `escapes_cuentan` | **true** | true | true | true |
| Brote `limite_intentos` (por tanda de 7; z5 de 4) | null → **4** | 12 → **4** | 12 → **4** | 12 → **3** |
| Brote `velocidad_caida` | 135 → **155** | 145 → **165** | 150 → **170** | 95 → **110** |

- Fórmula para afinar: Semilla `limite = ceil(0,6 × por_ronda)`, Brote `limite ≈ 0,55 × por_ronda`.
- Gag de Maxi: los charcos se desbordan en burbujas de colores y Coco las revienta con la cola (1,5 s).
- `ayuda_tras_fallos` (Nicole, 2) se mantiene: la pista llega antes que la derrota.

## 5. Taller de pinturas — motor `mezclar` (zonas 2-5, Sofía)

Hoy **no hay derrota** (`motor-mezclar.md` §2 y §7: el "¡puaj!" solo reinicia la lata y cuenta para las
estrellitas). Se agrega.

**Clave nueva `puaj_max_mural`** (int o `null`, defecto `null`; requiere código): al llegar a ese número de
"¡puaj!" dentro de un mismo mural, derrota-gag **"¡Se desbordó el taller!"**: las latas eructan barro de
colores y Coco queda pintada como un dálmata, se mira al espejo y se ríe. El **mural en curso** vuelve a
empezar (sus latas hechas se van al lavadero con burbujas); los **murales terminados quedan**.

| Campo (`mezcla_estrella.json`) | z2 | z3 | z4 | z5 |
|---|---|---|---|---|
| `puaj_max_mural` (nueva) | **3** | **3** | **4** (recetas de 3-4 gotas) | **4** |
| `umbrales_estrellitas` (fallos en todo el nivel) | 3/6 → **1/3** | `tres` ≈ 1 · `dos` ≈ 3 | `tres` ≈ 2 · `dos` ≈ 4 | `tres` ≈ 2 · `dos` ≈ 5 |
| `regalo_tras_derrotas` + `regalo_derrotas` (nuevas en el motor) | `true` + **3** | igual | igual | igual |
| `velocidad_caida`, `probabilidad_util`, `memorizar_s` | sin cambio | sin cambio | sin cambio | sin cambio |

- **Regalo**: en el mural siguiente la libreta es gratis (no cuesta estrellita).
- Sin reloj [decisión]: el PO ya pidió "sin reloj que apure" en este juego (`motor-mezclar.md` §7); la derrota
  llega por errores, que es lo que el juego enseña.

## 6. Pinta con Coco — motor `lienzo_libre` (5 zonas, los tres)

Decisión: **el lienzo libre no tiene derrota** (`"encargo": "libre"`, zona 1 de los tres): no hay objetivo que
fallar, y un dibujo libre que "pierde" sería castigar la expresión. **Los encargos sí** (z2-z5), con un
solcito que "seca la pintura".

**Claves**: `sin_fallo: true → false` en los encargos, y **clave nueva `sol_encargo`** (requiere código; hoy el
motor dice "sin tiempo límite, sin fallo"): `{ "tiempo_par_s": X, "factor_par": F, "minimo_reintento_s": 30 }`
por lámina. Derrota-gag **"¡Se secó la pintura!"**: el sol tuesta la lámina, cruje como galleta, Coco estornuda
y los colores sobrantes saltan como confeti. **El dibujo nunca se pierde**: se guarda en "Mis obras" igual, y
al reintentar la lámina **conserva lo pintado**; el sol vuelve con el tiempo proporcional a lo que falta.
`puntua_estrellitas` sigue en `false`.

| Archivo · encargo | Perfil | `tiempo_par_s` por lámina (provisional) | `factor_par` |
|---|---|---|---|
| z1 · `libre` (los tres) | — | — (sin derrota, `sin_fallo: true`) | — |
| z2 · `pinta_semilla` `sellos_escena` | Semilla | 40 | 3,0 |
| z2 · `pinta_brote` `colorear_zonas` | Brote | 75 | 2,2 |
| z2 · `pinta_estrella` `colorear_codigo` | Estrella | 120 | 1,6 |
| z3 · `pinta_semilla` `pinta_coco` | Semilla | 40 | 3,0 |
| z3 · `pinta_brote` `coco_pide` | Brote | 60 | 2,2 |
| z3 · `pinta_estrella` `mezcla_paleta` | Estrella | 120 | 1,6 |
| z4 · `pinta_semilla` `dedo_magico` | Semilla | 40 | 3,0 |
| z4 · `pinta_brote` `espejo` | Brote | 90 | 2,2 |
| z4 · `pinta_estrella` `mandala` | Estrella | 150 | 1,6 |
| z5 · `decora_ala` (los tres) y `viste_coco` (Brote) | S / B / E | 45 / 90 (viste_coco 60) / 120 | 3,0 / 2,2 / 1,6 |

- Los `tiempo_par_s` se fijan midiendo en la maqueta o el playtest el **tiempo mediano real** de cada hermano
  por lámina (ese es el par).
- `regalo_tras_derrotas: true` (+ `regalo_derrotas: 3` en Estrella): Coco pinta una región o cumple un objetivo.
  Semilla `ayuda_fuerte_tras_derrotas: { "derrotas": 3, "sin_sol": true }`.
- `pinta_mochila_equipo.json` (epílogo de la batalla): **sin cambios**, `se_puede_perder: false`.

## 7. Resumen: qué se resuelve solo con datos y qué pide código

| Juego | Solo datos | Pide código (clave nueva) |
|---|---|---|
| Río | velocidad, subida, gotas, arcoíris, tiempo par; ayuda fuerte vía `tope_avance` (existe en equipo) | `regalo_tras_derrotas` en el Río; `tope_avance` fuera de equipo |
| Formas | `limite_intentos` y umbrales de Brote y Estrella | `sol_derrota`, `regalo_derrotas`, `ayuda_fuerte_tras_derrotas` |
| Parejas | `limite_intentos` por ronda (los tres) y umbrales | `regalo_derrotas`, `ayuda_fuerte_tras_derrotas` |
| Lluvia | `limite_intentos`, `velocidad_caida` | `escapes_cuentan`, `regalo_derrotas`, ayuda fuerte |
| Taller | umbrales | `puaj_max_mural`, derrota-gag, regalo |
| Pinta | `sin_fallo: false` | `sol_encargo`, derrota-gag que conserva el dibujo, regalo |
| Torre y batalla | todo (§9-§10) | nada |

**Orden recomendado**: primero los "solo datos" (Parejas, Formas Estrella, Río, Torre y batalla), que se
pueden playtestear sin esperar código; después Lluvia y Formas de Maxi y Nicole; al final Taller y Pinta, que
cambian una regla de diseño anterior.

## 8. Fichas que quedan desactualizadas (para quien corresponda; este documento no las edita)

`motor-rio.md` §11, `motor-encajar.md`, `motor-emparejar.md` (§10, "Semilla imposible perder"),
`motor-clasificar.md`, `motor-mezclar.md` §2 y §7 ("nunca termina en derrota"), `motor-lienzo-libre.md` y
`lienzo-escenas-retos.md` ("siempre sin fallo"), `motor-lanzar.md` §15 (metas) y
`planeta-arcoiris-zonas.md` §3. Cada una debería apuntar a este documento hasta reescribirse.

## 9. La Torre de la Colección — motor `lanzar` (batalla en equipo, `datos/niveles/arcoiris/batalla/torre_equipo.json`)

Ya tiene derrota (4 gags). Sus metas v4 (1.er intento E1 60-75 %, E2 45-60 %, E3 30-40 %; ≤ 3 intentos ≥ 95 %)
quedan **por encima** de la política nueva. Solo datos:

| Campo | Actual | Propuesto |
|---|---|---|
| `etapas[E1].agarre_inicial` | 24 | **27** |
| `etapas[E2].agarre_inicial` | 20 | **23** |
| `etapas[E3].agarre_inicial` | 20 | **23** |
| `proyectiles.gigante.agarre_min` | 12 | **10** (el gigante quita menos agarre: ayuda, pero no gana solo) |
| `intentos.globos_base` / `ayudas[0].globos_extra` | 13 / 4 | **sin cambio** (la regla ≡ 1 mód 4 del reparto `maxi_intercalado`) |
| Metas del arnés (`motor-lanzar.md` §15.1) | E1 60-75 · E2 45-60 · E3 30-40 · ≤ 3 intentos ≥ 95 % | **E1 45-55 · E2 35-45 · E3 25-35 · ≤ 3 intentos ≥ 90 %** |

- Si con 27/23/23 el arnés da más que esas metas, se sube el agarre de a 1; si el trono cae con menos del ~60 %
  del agarre perdido (G4), se corrige la torre, no el agarre.
- `pausa_desde_derrota: 3` se mantiene (en equipo juega Maxi).

## 10. Rondas de la batalla en equipo (`datos/niveles/arcoiris/batalla/`)

El simulador del 07-Oct da ganar al primer intento: Río 87 %, Formas **100 %**, Parejas 91 %. Una ronda que
nunca se pierde no es reto. Solo datos (`equipo.composiciones["maxi+nicole+sofia"].pasos_rival`):

| Archivo | `pasos_rival` | Meta al primer intento |
|---|---|---|
| `rio_equipo.json` | 7 → **5** | ~70 % |
| `formas_equipo.json` | 5 → **3** | ~70 % |
| `parejas_equipo.json` | 5 → **4** | ~70 % |

Se recalibra con `herramientas/simular_equipo.py` y se actualiza el `resumen` informativo de
`datos/batallas/arcoiris_final.json` (incluido `ganar_al_primer_intento_estimado`). El epílogo de pintar la
mochila sigue sin derrota.

## 11. Riesgos de usabilidad (para `experto-ux-parvulo`)

| # | Riesgo | Qué mirar |
|---|---|---|
| R1 | **Pinta deja de sentirse libre** con el sol en los encargos | ¿Nicole sigue decorando por gusto o corre a terminar? Si corre, subir su factor a 2,5 antes que quitar el sol |
| R2 | **Maxi pierde en Lluvia por gotas que no vio** (escapes) | Contar escapes por tanda en el playtest; si pierde más de 1 de cada 10 tandas, `limite_intentos` + 1 |
| R3 | **El Taller reinicia el mural** y Sofía lo vive como "perdí todo" | El gag tiene que ser lo bastante gracioso; los murales terminados se ven en la pared. Si se frustra, reiniciar solo hasta la mitad del mural |
| R4 | **Formas de Sofía con 5 intentos** en banderas de 12 piezas con giro | `giro_cuenta_fallo: false` se mantiene; medir fallos reales por bandera |
| R5 | **Tres juegos seguidos perdidos** en una visita al mapa | El descanso se ofrece por juego; observar si el ánimo general cae en una sesión |
| R6 | **La batalla deja de ganarse fácil** con los tres jugando juntos | Es el momento más social: medir si las derrotas generan peleas entre hermanos (eso sí sería un problema) |

## 12. Qué debe probar `tester-qa`

1. Cada motor con `regalo_derrotas` 2 y 3 (y sin la clave → 2); el contador se reinicia al ganar.
2. Ayuda fuerte de Semilla en cada motor: tras 3 derrotas seguidas, el intento siguiente **siempre** termina en
   victoria.
3. Clasificar con `escapes_cuentan`: la gota que toca el suelo suma un fallo y vuelve a caer; sin la clave,
   comportamiento actual.
4. Mezclar con `puaj_max_mural`: derrota al llegar, mural en curso reiniciado, murales terminados intactos.
5. Lienzo con `sol_encargo`: derrota, **el dibujo queda guardado en "Mis obras"** y el reintento conserva lo
   pintado; el encargo `libre` nunca muestra sol.
6. En todos: una derrota da 0 destellos y 0 estrellitas y no toca nada guardado; reintento con un toque.
