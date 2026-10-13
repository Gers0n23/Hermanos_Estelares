# Storyboard y spec — Cierre de la historia del Planeta Arcoíris (de la Torre al despegue)

> Entregable de `director-cinematicas`. **Versión 3 (13-Oct-2026)**, conciliada con:
>
> - el guion `docs/guiones/cierre-arcoiris.md` **v2**: **todos los ids de voz salen de ahí** (su §10 traduce
>   los provisionales);
> - la ficha `docs/fichas/motor-lanzar.md` **v2**: layout (§4), charco (§6.9), victoria (§9), derrotas y
>   ayudas (§10), revancha (§11), señales (§13.2) y estado familiar (§13.4).
>
> Continúa `docs/cinematicas/batalla_arcoiris.md` (HE-68) sin contradecirlo; los cambios están en el §1.
>
> **Decisiones del PO que aplica (12 y 13-Oct-2026)**:
>
> - la 4.ª etapa, "La Torre de la Colección";
> - el charco que deja al Coleccionauta con lunares y la mochila limpia;
> - los broches en vez de tuercas;
> - el puente de 3 bandas;
> - la cuenta regresiva al final;
> - `arcoiris_009` movida a la instalación del ala;
> - la ruta A-N-I-M-A-L-I-A con señuelos que se vuelve un perrito que ladra;
> - el ala como estado familiar (M7 anulada, con llave de padres);
> - las 4 derrotas-gag del guion;
> - los regalos de Coco: **T-rex de gomita, corazón rosado chicle y pony turquesa**;
> - la física solo en `lanzar`.
>
> **[CONCILIAR]** marca lo que sigue abierto entre roles (lista en el §21). **[PO]** marca lo que espera una
> decisión del PO (§22).
>
> **No toca** el tablero, el GDD, las fichas, los guiones ni el código.

## 0. Reglas de dirección

1. Todo es **cutout 2D dentro de Godot** (`AnimationPlayer` sobre piezas), porque depende del estado: la
   torre, la mochila, el ala y la ruta.
2. **Un foco por momento.** Las voces **nunca se pisan** (de 0,15 a 0,3 s de aire entre una y otra).
3. **Cámara fija**: solo fundidos, iris y zooms suaves (como máximo 1,0 → 1,15).
4. **Aire después de cada chiste** (de 0,3 a 0,5 s).
5. **El Coleccionauta nunca da miedo**:
   - canon: gafas-lupa, mochila-torre y antenas con bolitas;
   - **nunca nombra a papá**;
   - nunca se hace daño: solo queda **pintado**, y todo cae acolchado (ficha L8).
6. **Saltar**:
   - la primera vez, un toque solo da una chispita en el dedo;
   - desde la segunda vez (por **familia**, §16), un toque salta al estado final;
   - lo interactivo no se salta;
   - las derrotas-gag se cortan con "¡otra vez!" desde la primera vez.
7. **Los tiempos son estimados**: manda el audio. Si una voz dura más de lo previsto, se acortan primero
   las transiciones y el aire.
8. **Cámara lenta**: se usa solo en la Torre. Es un `speed_scale` de la cinemática, **nunca
   `Engine.time_scale`**.
9. **El "plano detalle" no es un corte**: es Cometa acercando el mapa a la cámara.
10. **Sin bichos** (Nicole y Sofía). Esto corrige la mosquita de `batalla_arcoiris.md` §8: la reemplaza
    una pelusa-nubecita (§5.1).
11. **Durante los gags y la anticipación, la torre no se mueve por física** (ficha L3 y L9):
    - lo que se mueve son props, sprites hijos y el rig;
    - la caída final es una coreografía animada que parte de `estado_derribo()`.

## 1. Qué cambia de `batalla_arcoiris.md`

| Sección de ese storyboard | Qué pasa ahora | Aquí |
|---|---|---|
| §7.5: interludio azul → "antes del epílogo" | Después del interludio azul van el mapa de batalla con el 4.º hito (pausa natural), la presentación de la Torre y la etapa. "Antes del epílogo" va después de la caída | §2 y §3 |
| §8, P1: mosquita y `epilogo_antes_coleccionauta` | Pelusa-nubecita y `arcoiris_batalla_epilogo_mochila_gris` | §5.1 |
| §9: el Coleccionauta sentado durante el epílogo | Sentado en el charco, con lunares | §5.2 |
| §12.1, A3 | En el tropiezo **se le cae el mapa** (no suma tiempo) | §6.1 |
| §12.2, B7 (video-llamada opcional) | **Pasa a la partida** y deja de ser opcional | §12 |
| §12.2, B8 (la nave "¡Juntos!" en la selección) | La próxima vez que se abra la selección | §20 |
| §13.2, A5 (mosquita) | Se elimina; la reemplaza N12 | §19 |

Las partes A y B del cierre **se mantienen**, con la foto en B6, como lo fija el guion v2. Lo nuevo es la
**parte C** (el mapa) y el **bloque 2** (la partida).

## 2. El cierre completo, de un vistazo

```
(batalla) interludio azul (livianita_3) → mapa de batalla con el 4.º hito (pausa natural, voz arcoiris_batalla_torre_pausa)
  → presentación de la Torre (§3) → intro → etapa Torre (motor lanzar)
       ├─ derrota → derrota-gag 1-4 (§7) → "¡otra vez!" → rearmado → intro
       └─ derribo final:
BLOQUE 1 · LA VICTORIA (≈ 2,5 min)
  Anticipación (≈ 4,3 s variante A / ≈ 3,5 s variante B) (§4.1)
  Caída en el charco (≈ 10,5 s) (§4.2)         ← el momento de mayor celebración del planeta
  Antes del epílogo (≈ 5,4 s) → epílogo: pintar la mochila (≈ 75 s, interactivo) (§5)
  Cierre A: se despide y se le cae el mapa (≈ 19,8 s) → Cierre B: fiesta y foto (≈ 22,8 s) (§6)
  Parte C: el mapa (≈ 13 s) (§6.3)
  ── PAUSA NATURAL: la nave espera brillando; se sigue tocándola (§8.1) [PO, duda 1] ──
BLOQUE 2 · LA GRAN PARTIDA (partida_arcoiris.tscn, ≈ 3,4 min)
  Entrada y ritual (≈ 9 s) → Preparativos (≈ 1,5 min): Maxi el tanque → Nicole el ala y los broches → Sofía la ruta (§9)
  Despedida de Coco (≈ 40 s, interactiva) (§10)
  Video-llamada de papá (≈ 28 s) (§11)
  Cuenta regresiva y despegue por el puente (≈ 20 s) (§12)
  Mapa Estelar con rumbo a Animalia (≈ 14 s) (§13)
```

## 3. Presentación de la Torre (T.1 del guion, ≈ 10 s)

Viene después de la pausa natural del mapa de batalla (ficha §13.3): la Torre se juega al **tocar el 4.º
hito**, que **nunca avanza solo**. Se salta desde la segunda vez (`arcoiris_batalla_final:presenta_torre`).
Composición: el layout de la ficha §4.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| T1 | 0,0-3,0 | El claro con el arcoíris completo; el Coleccionauta con la mochila vacía | **En cámara rápida** saca de la mochila cajas, frascos de caramelo y latas, y los apila sobre la galleta-plataforma (x 800-1180, centro x 990), con un "pop" por pieza, al ritmo de "caja, frasco, caja, lata". En "¡y yo arriba!" trepa al cojín-trono | `arcoiris_batalla_torre_presenta_coleccionauta` (3 s) | Motivo del Coleccionauta. "Pop" por pieza |
| T2 | 3,2-7,2 | El Coleccionauta en la cima | Sentado, de brazos cruzados, orgulloso. En "...Y de pasadita, alcanzo el arcoíris" se pone de puntillas y estira un dedo hacia el cielo; le faltan 5 px. La torre se mece ±1,5° (solo el sprite) | `arcoiris_batalla_torre_presenta_alcanzo` (4 s) | Un "ñiii" de estirarse |
| T3 | 7,4-10,4 (**solo la 1.ª vez por familia**) | **Coco** junto a su canasta (pies en (170, 584)) | Saca la resortera de regaliz con un giro; los globos de la canasta se mecen | `arcoiris_batalla_torre_presenta_coco` (3 s) | "Boing" de goma |

Después va la intro N7 (`arcoiris_batalla_torre_intro_coleccionauta` + `arcoiris_batalla_torre_intro`) y el
primer turno, que siempre es de Maxi.

**El puente desde el interludio azul**: el gag de `livianita_3` (la mochila vacía lo hace flotar y cae
sentado) termina el interludio como hoy. La pausa del mapa de batalla separa las dos cosas, así que no hace
falta un puente animado.

## 4. La victoria: anticipación y caída en el charco

**Composición (ficha §4)**:

| Elemento | Posición |
|---|---|
| Torre | Centro x 990, base en y 584, cima ≤ 434 px |
| Charco | Centrado en (990, 580); en el derribo mide ≥ 360 px (ficha §6.9) |
| Resortera | Bolsa en (260, 430) |
| Coco y la canasta | A la izquierda |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` |
| Casa | `Rect2(1172, 8, 100, 96)` |

**El charco crece con cada tiro que no bota nada** (ficha §6.9): un escalón por tiro neutro y medio por
globo que revienta en el suelo, con un "chof" y una ondita. No se borra nunca. Es la memoria de que ningún
tiro se pierde.

**Señales (ficha §13.2)**:

- en el cuadro del derribo final (agarre 0 o trono botado), con la física congelada, el motor emite
  `derribo_inminente(punto_impacto, desde_soltar)`;
- la coreografía parte de `estado_derribo()`;
- la caída se envuelve en `momento_saltable_iniciado/terminado("caida_torre")`;
- el salto es `saltar_derribo()` (la implementación de `saltar_momento("caida_torre")`);
- si se pide un salto durante la anticipación, queda en cola para la caída.

### 4.1 Anticipación (no se salta ni se marca vista)

- **Variante A** (`desde_soltar = true`): se sabe al soltar el globo. Va de K1 a K5.
- **Variante B** (`desde_soltar = false`, el caso normal): empieza en K2, con la cámara lenta en el
  salpicón.

| # | Tiempo (A) | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| K1 | 0,0-1,4 (solo A) | El globo en vuelo | **Cámara lenta a 0,35** desde los 0,15 s del lanzamiento, y zoom suave 1,0 → 1,08 hacia la torre. El Coleccionauta lo ve venir con los ojos agrandados por la lupa. **En la barra, los tres retratos inflan los cachetes** | — | Música a −12 dB. "Fiuuuu" grave y estirado |
| K2 | 1,4-1,9 | El impacto | **¡Splat!** en `punto_impacto`. En la variante B, **este salpicón va en cámara lenta (0,4) durante 0,5 s**, y el zoom 1,0 → 1,08 ocurre aquí | — | "Splat" al 70 % |
| K3 | 1,9-3,3 | La torre, congelada en la pose del derribo | **Tambaleo en tres vaivenes que crecen** (±3°, ±6° y ±9°, de 0,45 s cada uno), aplicado al sprite del conjunto con pivote en la galleta (990, 584), sin física. El Coleccionauta, en su cara **"colgando de un dedo"**, patalea | — | Tres crujidos de juguete ("ñiic"), cada uno más agudo |
| K4 | 3,3-4,1 | **El instante de silencio** | La torre queda **inclinada 11°**, imposible. Él, colgado del cojín con un dedo, **mira a la cámara**, parpadea dos veces y saluda con los dedos de la otra mano | — | **Silencio total**: la música se apaga 0,15 s antes. Son 0,8 s exactos |
| K5 | 4,1-4,6 | — | Se le resbala el dedo, "tic" | `arcoiris_batalla_torre_ups` (0,5 s) | Un "tic" |

La variante B dura ≈ 3,5 s (de K2 a K5). Lo que pasa con el globo gigante está en el §7.6.

### 4.2 Caída en el charco (≈ 10,5 s; se salta desde la 2.ª vez: `arcoiris_batalla_final:caida_torre`)

**Gag central [PO]**: mientras todo se cae, él **salva su mochila**.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| C1 | 0,0-2,2 | La torre se rinde **en cámara lenta (0,4)** | Cada bloque interpola desde su pose en `estado_derribo()` hasta su pose de coreografía, desarmándose **hacia la derecha y alrededor del charco** (nunca encima de él). Las cajas se abren como tapas y sueltan estampillas y calcetines; los frascos de caramelo se rompen en **confeti dulce** y su contenido flota (patito, guante, globo de nieve, cuchara y cono); las latas ruedan. Él cae **sentado en el aire**, pedaleando, y **levanta la mochila sobre la cabeza** | `arcoiris_batalla_torre_cae_mochila` (2 s, dicha en cámara lenta) | "Woooosh" grave. "Clin-tintín" graves |
| C2 | 2,2-3,0 | Vuelve la velocidad normal | Las piezas terminan de caer en un montón alrededor del charco ("boing" acolchados) | — | "Pum, pum" suaves |
| C3 | 3,0-3,3 | **¡SPLASH!** | Aterriza **sentado en el centro del charco, (990, 578)** (squash 0,75 / stretch 1,15). Sube una corona de salpicón multicolor y aparecen **los lunares** en el cuerpo, el chaleco y las antenas (capa N3). **La mochila, en alto, queda gris y limpia** | — | "Splash" redondo, al 70 % |
| C4 | 3,3-4,3 | Él, quieto | **Aire para la risa**: parpadea; le gotea pintura de las antenas; **la tapa de un frasco le cae de sombrerito** (lo único que le cae encima, y es blandito) | — | "Plip, plip" y "plink" |
| C5 | 4,4-7,4 | Él | Baja la mochila con cuidado y **explota de risa**: cabeza atrás, diente mellado. **Chapotea con los pies como un niño** | `arcoiris_batalla_torre_cae_charco` (3 s) | "Splish-splash" chicos |
| C6 | 7,6-10,5 | **Fiesta máxima**, la pantalla entera | Cañones de confeti desde los dos costados y **tres fuegos artificiales de pintura** (rojo, amarillo y azul, cada 0,4 s). **Los tres retratos de la barra saltan juntos** (dos saltos de 60 px; el foco es el grupo). Coco da una voltereta y queda **de lunares de colores**. Cometa hace un loop. Si el globo gigante quedó sin usar, Coco lo revienta en confeti (§7.6) | `arcoiris_batalla_torre_la_botaron` (1,2 s), o `arcoiris_batalla_torre_lo_bajamos` (1,5 s) si ganaron con el gigante | **La fanfarria más grande del planeta** |

**Estado final** (el mismo que deja `saltar_derribo()`, ficha §9.4):

- él sentado en el charco, pintado, con el sombrerito y la mochila gris;
- las cajas desparramadas alrededor del charco;
- confeti cayendo y la música de fiesta en bucle.

Después el motor emite `completado(0)`.

## 5. Del charco al epílogo

### 5.1 Antes del epílogo (≈ 5,4 s)

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| P1 | 0,0-3,5 | Él, sentado en el charco | "Yo, de colores...": se señala los lunares. "...y mi mochila, gris": la levanta, la da vuelta y la sacude; **solo cae la pelusa-nubecita** (N12), que se va flotando. "¿Y ahora qué colecciono?": abraza la mochila, dramático de teleserie | `arcoiris_batalla_epilogo_mochila_gris` (3,5 s) | Música a −10 dB. "Fiu-fiu" de violín de teleserie |
| P2 | 3,6-5,4 | **Coco** | Ampolleta de chispa y salto | `arcoiris_batalla_epilogo_antes_coco` (1,8 s) | "¡Ding!" |

Con 5,4 s queda apenas sobre el tope de ≤ 5 s, pero él ya está en pantalla desde la caída. **Lo valida UX.**

### 5.2 El epílogo

Igual que `batalla_arcoiris.md` §9. Él está sentado en el charco, con lunares. Los colores que le regalan en
la mochila son **planos y enteros**; los de su cuerpo, **lunares**: lo regalado se distingue de lo
salpicado. Termina con el estornudo de confeti.

## 6. Despedida del Coleccionauta, fiesta, foto y el mapa

### 6.1 Cierre A (≈ 19,8 s): igual que `batalla_arcoiris.md` §12.1, con el mapa

| # | Tiempo | Qué pasa | Voz |
|---|---|---|---|
| A1 | 0,0-5,3 | Gira persiguiendo su mochila pintada y se traba de emoción | `arcoiris_batalla_cierre_mira` |
| A2 | 5,5-8,5 | Compara la mochila con los tres | `arcoiris_batalla_cierre_equipo` |
| A3 | 8,8-16,0 | La despedida y el "¿para qué lado era la salida?". **En el tropiezo final con el trébol, del bolsillo de la mochila salta una bolita de papel arrugado**: sube en arco (0,4 s) y baja **planeando como una hoja** (0,8 s) hasta el pasto en (170, 585). Ocurre dentro del 1,2 s del gag que ya existía, así que no suma tiempo. **Él sale sin darse cuenta.** El patito rebota detrás | `arcoiris_batalla_cierre_despedida` |
| A4 | 16,0-16,2 | Aire. **El papel destella una vez** ("tilín"): es la semilla para Maxi | — |
| A5 | 16,2-19,8 | Coco "¡arcoíris de equipo!", y el arcoíris del cielo destella. El papel queda quieto (un foco) | `arcoiris_batalla_cierre_coco` |

### 6.2 Cierre B (≈ 22,8 s): igual que `batalla_arcoiris.md` §12.2, de B1 a B6

- La fiesta: `nucleo_equipo_al_frente` → gestos con `nucleo_equipo_fiesta_<hermano>` →
  `nucleo_equipo_choca` → `nucleo_equipo_equipo_estelar` → `nucleo_equipo_destellos`.
- La foto: `arcoiris_batalla_cierre_foto` y el audio familiar.
- **No hay B7 ni B8.** El papel arrugado sigue en el pasto a la izquierda, quieto.

### 6.3 Parte C: el mapa (≈ 13 s; se salta desde la 2.ª vez: `arcoiris_batalla_final:mapa_coleccionauta`)

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| M1 | 0,0-1,4 | El papel en el pasto | Destella dos veces. Coco gira la cabeza, curiosa | `arcoiris_batalla_cierre_mapa_coco` (1,4 s) | "Tilín, tilín" |
| M2 | 1,6-2,8 | **Coco** | Lanza **la lengua del Río** y atrapa el papel ("¡fiup!"). Se le pega a la lengua y **se estira como chicle** antes de soltarse en las manos de Cometa ("boing") | — | "Fiup" y "boing" |
| M3 | 2,8-4,0 | **Cometa** | Lo desarruga en tres tirones; el papel crece de 120 a 320 px | — | Tres "crunch" |
| M4 | 4,0-4,8 | — | **Lo acerca a la cámara** hasta llenar `Rect2(140, 70, 1000, 560)`. El fondo se aclara un 15 %, **nunca se oscurece** | — | "Fffp" |
| M5 | 4,8-9,3 | **Plano detalle** (N5) | Crayón infantil, **sin texto**: Arcoíris a la izquierda, **una ruta de 8 estrellitas punteadas con una flechita** y, a la derecha, el planeta verde **con una huellita**. Las estrellas se encienden una por una (0,25 s cada una); "mapa" coincide con la primera y "Animalia" con el latido de la huellita. **La ruta no se ve como un perrito**: esa sorpresa es de Sofía | `arcoiris_batalla_cierre_mapa_cometa` (4,5 s) | **La melodía de la ruta** (escala de do, una nota por estrella, §17) |
| M6 | 9,5-11,3 | La barra | El mapa se achica y **vuela al retrato de Sofía**, que se ilumina: la líder lee el mapa | `arcoiris_batalla_cierre_mapa_coco_nave` (1,8 s) | "Fiuu" y campanita |
| M7 | 11,3-13,0 | Fundido cruzado al Claro con la nave estacionada (§9.2), **con el ala envuelta para regalo junto a la nave** | — | — | La música se resuelve en un acorde |

## 7. La Torre: las cuatro derrotas-gag y el globo gigante

### 7.1 Plantilla común (ficha §10.1 y §8.3)

- **La derrota llega en el pase**: después del tiro del último globo, el retrato del siguiente ya está al
  centro (≈ 210 px, a y ≈ 250). Nunca aparece pegada al tiro de nadie.
- **La torre está congelada**: solo se mueven props, sprites hijos y el rig. La zona de juego se oscurece
  un 20 %, salvo la torre.
- **"¡Otra vez!"** de ≥ 160 × 160 px en (640, 480), **desde el segundo 0** (la bandeja de Sofía está oculta
  durante el gag). Tocarlo corta la secuencia y va al rearmado (§7.5).
- **Orden**: el gag (`derrota_<n>_coleccionauta`) → `derrota_<n>_coco_risa` → el logro de Cometa → la
  ayuda o la pausa de Coco.
- **Cuál gag**: las derrotas 1, 2 y 3 usan los gags 1, 2 y 3. **Desde la 4.ª rotan los cuatro sin repetir
  el anterior** (`variante_derrota()`). El conteo es por familia, se guarda en el parcial y se reinicia en la
  revancha.
- **Logro común** (ficha §10.1): **2 tramos según las piezas botadas en el intento, partidos en la mitad
  de las 28 piezas** de la torre de referencia (`logro_comun_corte` 0,5 sobre `total_piezas`):
  - tramo "1" (< 14): `nucleo_equipo_lanzar_logro_1`;
  - tramo "2" (≥ 14): `nucleo_equipo_lanzar_logro_2`.
  - Mientras suena, **destellan las manchas y las piezas botadas que están en el suelo**.
  - [CONCILIAR] El guion v2 todavía trae 3 líneas (`lanzar_logro_1..3`, por agarre). Con los 2 tramos de
    la ficha, `_3` sobra o se funde con `_2`.
- **La ayuda o la pausa** (ficha §10.3):
  - 1.ª derrota: `arcoiris_batalla_torre_traje_dos_mas`;
  - 2.ª derrota: el gigante (§7.6);
  - **desde la 3.ª**: Coco ofrece descansar con `arcoiris_batalla_torre_pausa` («¿Vamos por la torre, o
    descansamos y volvemos después?»).
- **Lo que le cae encima se queda** hasta la victoria (pintura rosada, calcetín, cara pintada).
- **Los retratos se ríen juntos** en el remate. Nadie queda señalado.

### 7.2 Gag 1 · "El baile" (1.ª derrota, ≈ 18 s si nadie toca "¡otra vez!")

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| G1a | 0,0-0,4 | Se pone de pie en el cojín, con los brazos arriba | — | "Boing" |
| G1b | 0,4-6,4 | "¡No me botaron!": puños al cielo. "¡Baile de la victoria!": mueve las caderas. "Un pasito pa'cá, un pasito pa'llá": dos pasitos, y **el sprite del conjunto se balancea ±4°** en cada uno. **Un frasco de pintura rosada** (prop sobre el cojín, no un cuerpo físico) se mece con el primer paso y **en el segundo se le da vuelta en la cabeza** (0,5 s, "glu-glu"). "¿Por qué llueve rosado?": mira hacia arriba, chorreando, y parpadea | `arcoiris_batalla_torre_derrota_1_coleccionauta` (6 s) | Una cumbia chiquita de kazoo a −10 dB y un "glu-glu" |
| G1c | 6,6-9,6 | Coco se ríe dando saltitos; los retratos se ríen | `arcoiris_batalla_torre_derrota_1_coco_risa` (3 s) | — |
| G1d | 9,8-13,8 | Cometa brilla; destellan las manchas y lo botado | `nucleo_equipo_lanzar_logro_1` o `_2` | Campanitas en escalera |
| G1e | 14,0-18,0 | **Ayuda**: Coco se pone verde pasto y **desaparece en el pasto** (0,5 s); reaparece con **dos globos** que vuelan a la canasta | `arcoiris_batalla_torre_traje_dos_mas` (4 s) | "Fiu" de camuflaje y dos "pop" |

### 7.3 Gag 2 · "El estornudo" (2.ª derrota, ≈ 14 s más la ayuda del gigante, §7.6)

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| G2a | 0,0-0,4 | De pie, saca pecho | — | — |
| G2b | 0,4-5,9 | "¡Nadie me tumba! Soy el rey de la...": se pone una **tapa de frasco como corona**. "...ay, una pelusita": baja flotando **la pelusa-nubecita** (N12) y le pasa por la nariz. "A... a...": **anticipación de 0,6 s** (se infla y cierra los ojos). "¡ACHÚU!": **la mochila vacía de su espalda estornuda calcetines de la colección**, que vuelan en espiral, y **uno le cae de sombrero** | `arcoiris_batalla_torre_derrota_2_coleccionauta` (5,5 s) | Estornudo (70 %, siempre después de la anticipación) y un "fiu-fiu" de calcetines |
| G2c | 6,1-8,6 | Coco se ríe | `arcoiris_batalla_torre_derrota_2_coco_risa` (2,5 s) | — |
| G2d | 8,8-12,8 | Destellan las manchas y lo botado | `nucleo_equipo_lanzar_logro_1` o `_2` | Campanitas |
| G2e | 13,0-… | **Ayuda: el globo gigante** (§7.6, según la variante del PO) | — | — |

### 7.4 Gag 3 · "El globo que vuelve" (3.ª derrota) y Gag 4 · "El chicle" (desde la 4.ª, en rotación)

En la batalla, con el gigante y el daño conservado, una 3.ª derrota es rara (ficha §10.3, ≈ 1 %). En la
revancha, el conteo empieza de cero.

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| G3a | 0,0-2,0 | Saltitos de triunfo. En "¡Ningún globo me alcan—" **aparece en el borde superior la flechita de "globo fuera de pantalla"** (UI de la ficha §4), justo arriba de él | `arcoiris_batalla_torre_derrota_3_coleccionauta` (empieza) | — |
| G3b | 2,0-3,0 | **El silencio de 1 s que graba papá**: la flechita crece y tiembla. A los 0,8 s el globo entra en picada y **¡PLAF!** en su cabeza. Es un prop scripteado: si en ese intento un globo salió por arriba, tiene su color; si no, es azul (ficha §10.1) | (silencio en la grabación) | Silbido que baja y "¡plaf!" |
| G3c | 3,0-5,0 | **Con la cara entera pintada**, muy digno: "...zó. ¿De dónde salió ese?" | (sigue la línea) | — |
| G3d | 5,2-8,2 | Coco se ríe | `arcoiris_batalla_torre_derrota_3_coco_risa` (3 s) | — |
| G3e | 8,4-12,4 | Logro | `nucleo_equipo_lanzar_logro_1` o `_2` | Campanitas |
| G3f | 12,6-15,9 | **Pausa**: Coco se sienta tranquila en el pasto y la casa respira suave | `arcoiris_batalla_torre_pausa` (3,3 s) | — |
| G4a | 0,0-5,0 | "¡Me salvé!": se seca la frente. "Esto merece un chicle de premio...": saca un chicle rosado del chaleco y masca dos veces. "fffff": **el globo de chicle crece** hasta ser más grande que su cabeza, y las antenas se le van para atrás. "¡PLOP!": **explota** y le tapa la cara y las gafas de rosado | `arcoiris_batalla_torre_derrota_4_coleccionauta` (5 s) | Un "fffff" que sube y un "¡plop!" |
| G4b | 5,2-7,7 | Coco se ríe y **se pone rosado chicle** (su tic) | `arcoiris_batalla_torre_derrota_4_coco_risa` (2,5 s) | — |
| G4c | 7,9-11,9 | Logro, y después **pausa** como en G3f | `nucleo_equipo_lanzar_logro_1` o `_2` → `arcoiris_batalla_torre_pausa` | — |

### 7.5 Al tocar "¡otra vez!": el rearmado (≈ 7 s)

| # | Tiempo | Acción y animación | Voz | SFX |
|---|---|---|---|---|
| R1 | 0,0-0,3 | Se corta lo que sonaba (fundido de 0,15 s). **Si se cortó antes de la ayuda, la ayuda igual ocurre, sin voz**: los globos extra o el gigante llegan durante R2. Nadie pierde un regalo por apurarse | — | — |
| R2 | 0,3-3,8 | **Rearmado parcial** (`gag_derrota_devolver`, ficha §10.2): las piezas que él repara vuelven a su pose, una cada 0,25 s, con un "pop"; **las que no repara quedan en el suelo alrededor del charco**, como decorado; las manchas y el charco quedan todos. Trepa y se sienta, con la cara que corresponde al agarre conservado | `arcoiris_batalla_torre_rearma_01` o `_02` (alternadas) | Un "pop" por pieza |
| R3 | 4,0-6,8 | La intro corta | `arcoiris_batalla_torre_intro_coleccionauta` + `arcoiris_batalla_torre_intro` | — |

### 7.6 El globo gigante [PO: quién lo infla y quién lo tira está sin decidir]

El plano funciona con **las dos variantes** que hay hoy en los documentos. La parte común se anima igual;
cambian solo dos tramos, que van marcados.

| Tramo | Variante F (ficha v2 §10.3) | Variante G (guion v2 T.5) |
|---|---|---|
| **Inflado** | Al cerrar la 2.ª derrota (G2e), **Coco lo infla sola**: tres soplidos que crecen, el globo dorado-arcoíris llena sus 3 franjas y Coco queda **morada** y mareadita | Al empezar el 3.er intento el gigante **espera desinflado**, atado al poste de la canasta. Solo si se acaban los globos con la torre en pie: `arcoiris_batalla_torre_inflemoslo` → **ronda de ventanitas** (cada hermano toca la suya en el orden del turno, con `nucleo_equipo_ahora_<hermano>`, y cada toque llena una franja con un "fuuu" que sube) → Coco queda morada |
| Voz del inflado | `arcoiris_batalla_torre_gigante_inflado` (2,3 s) al terminar de soplar. [CONCILIAR] la ficha cita una línea `ayuda_globo_gigante` que el guion v2 ya no tiene | `arcoiris_batalla_torre_inflemoslo` (3 s) y `arcoiris_batalla_torre_gigante_inflado` (2,3 s) |
| **Presentación** (común) | Al empezar el 3.er intento: `arcoiris_batalla_torre_gigante_presenta` (4 s) y, la primera vez, `arcoiris_batalla_torre_gigante_coleccionauta` (3,5 s). Él pone cara de "¡no es justo!" con los brazos cruzados y después se encoge de hombros | Igual |
| **Quién lo tira** | **Maxi**, como primer globo de cada intento desde el 3.º, con su tiro guiado. [CONCILIAR] falta `gigante_turno_maxi` en el guion | **Coco**, que lo lanza ella misma tras las ventanitas |
| **Vuelo e impacto** (común) | El globo, del doble de tamaño (radio 72 px), cruza con una estela dorada a velocidad normal y pega en `gigante_objetivo`, con un salpicón doble. Si gana en ese tiro con `desde_soltar = true`, es la **variante A** de la anticipación (§4.1). Si no gana, la torre queda "colgando de un dedo" y sigue el juego | Igual |
| Voz del impacto | [CONCILIAR] el guion v2 no trae `gigante_impacto`. Mientras tanto, va sin voz (el salpicón doble basta) | Igual |
| **Si ganan sin usarlo** | En C6, Coco lo revienta en confeti con `arcoiris_batalla_torre_no_lo_necesitamos` | Igual |

## 8. La pausa natural y la entrada a la partida

### 8.1 La pausa [PO, duda 1]

El cierre completo dura ≈ 5,9 min (§18) y viene después de una batalla de 18-20 min (ficha §16). Propongo
una pausa en el único lugar donde la historia la pide: **terminó la batalla y empieza el viaje**.

- **Pantalla de espera**: el estado final de M7. La nave brilla suave, el mapa flota encima (90 px), el
  ala envuelta está junto a la nave y Coco al lado. Se toca la nave entera (≥ 300 × 200 px); **nunca avanza
  sola** y la casa está a la vista.
- **Voz**: `arcoiris_batalla_cierre_pausa_partida` (3,5 s), una vez.
- **Si salen**: el hito del Claro pasa al estado "partida" (ficha §13.4): la nave brillando con el mapa,
  con `arcoiris_partida_hito` como máximo una vez por visita (M7.3).
- **Si el PO no quiere la pausa**: M7 sigue directo a §8.2.

### 8.2 Entrada (≈ 9 s más los toques)

| Tiempo | Qué pasa | Voz |
|---|---|---|
| 0,0-3,5 | Cometa se asoma, emocionado | `arcoiris_partida_entrada` (3,5 s) |
| 3,5-4,0 | Iris a la pantalla "¡todos a la nave!" (la de `batalla_arcoiris.md` §3.3) | — |
| Interactivo | Cada retrato salta a su ventanita. **No hay botón "¡Despegar!"**: con los tres, sigue sola a los 0,8 s | `nucleo_equipo_sube_nave_<hermano>`; `nucleo_batalla_todos_nave` (o `_corta` al retomar) si nadie toca en 4 s; `nucleo_batalla_falta_uno` |
| +0,5 | Iris a los preparativos y vuelo del retrato de Maxi | `nucleo_equipo_ahora_maxi` |

## 9. Preparativos (interactivo, sin fallo, ≈ 1,5 min)

### 9.1 Reglas comunes

- **Modo sin puerta** (como el epílogo): entre tareas suena `nucleo_equipo_ahora_<hermano>`. El orden es
  fijo: **Maxi → Nicole → Sofía**.
- **Cada tarea cierra igual**:
  - Cometa: «¡Tanque listo, bombero!», «¡Ala lista, artista!» o «¡Ruta lista, capitana!»;
  - después, el gesto canon del hermano, sin voz.
- **Tocar a Cometa repite la consigna** de la tarea en curso.
- **No se puede fallar**: un toque equivocado da "bup" y un meneo, sin voz.
- **Nunca se traba**: cada tarea tiene ayudas escalonadas.
- **Equidad**: las celebraciones tienen el mismo tamaño y la misma frase.
- **Respuesta < 100 ms.** La casa siempre está activa: se guarda **por paso** (§16.3).

### 9.2 Layout común (1280×720)

| Elemento | Posición y tamaño |
|---|---|
| Cielo con el arcoíris de 3 bandas | Arco centrado en (640, 760), radios ≈ 560, 520 y 480 (por código) |
| **Nave-estrella** (3/4, nariz a la izquierda) | Casco en `Rect2(560, 150, 620, 420)`, apoyada en el pasto (N7, por capas) |
| Hueco fantasma del ala | ≈ `Rect2(640, 330, 240, 120)` |
| **Tanque-caramelo** | Centro (1010, 205), ⌀ 150 px, con embudo en (1010, 125) (N8) |
| Coco | Pies en (560, 575), ≈ 170 px |
| Cometa / casa | `Rect2(8, 4, 110, 96)` / `Rect2(1172, 8, 100, 96)` |
| Barra del equipo | `Rect2(0, 610, 1280, 110)` |
| Hermano en turno (rig de cuerpo entero, ≈ 280 px) | Pies en (330, 590) |

Todo lo tocable queda a ≥ 24 px de la casa, de Cometa y de la barra.

### 9.3 Maxi llena el tanque (≈ 23 s)

**Maxi quiere ser bombero**: él sostiene la boquilla de una manguera de 3 franjas que sale de un balde de
pintura arcoíris en (120, 540). La boquilla está en (430, 430), con un halo de **⌀ 220 px**. **Toda la
pantalla cuenta como toque**, salvo la casa, Cometa y la barra.

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| MX1 | 0,0-2,5 | La boquilla respira | `arcoiris_partida_maxi_intro` (2,5 s) | — |
| MX2 | **6 toques** | El rig recula con el tirón, un chorro de color cruza en arco hasta el embudo (0,7 s), el tanque sube una franja y la nave se ríe de cosquillas. Un toque durante un chorro queda en cola (máximo 1) | Toques 1-3: `arcoiris_partida_color_rojo`, `_amarillo` y `_azul`. Toques 4-6: solo música (amarillo, rojo y azul) | "Fshhh" con una nota que sube |
| MX3 | 2,5 s | El tanque lleno brilla. **Anticipación de 0,6 s** (la nave se infla al 110 %) y **la nave estornuda burbujas de jabón** de 3 colores (8, de ⌀ 100-130 px, que suben 4 s). **Las burbujas se pueden reventar** (premio de cualquiera) | `arcoiris_partida_salud_nave` (1 s), después del estornudo | Estornudito de juguete (70 %), pops con nota |
| MX4 | 2,4 s | — | `arcoiris_partida_tanque_listo` (1,6 s) y el gesto de Maxi | "Tilín" azul |

**Ayudas**:

- a los 8 s, `arcoiris_partida_maxi_recuerda`, con la boquilla latiendo más grande;
- a los 20 s, `arcoiris_partida_maxi_baila`: **la manguera baila sola y echa un chorro cada 5 s** hasta
  llenar el tanque.

**Colores** [PO, duda 2]: hoy son los 3 recuperados, con 6 toques (así está también en el guion v2). Si el
PO elige 7 colores, cambian el guion y el número de toques.

### 9.4 Nicole instala el ala y gira los 3 broches (≈ 28 s)

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| NI0 | 0,0-1,2 | Maxi sale caminando y entra Nicole. **Coco trae el ala envuelta para regalo, cargándola en la cabeza**, y la deja sobre un trébol en (320, 400); mide 280 × 170 px y tiene un moño arcoíris | `nucleo_equipo_ahora_nicole` | Pasitos |
| NI1 | 1,2-4,2 | El **moño** respira (target de **140 × 140 px**, centrado en (320, 330)) | `arcoiris_partida_nicole_intro` (3 s) | — |
| NI2 | Toque | El moño se desata (0,6 s), el papel **estalla en confeti** y aparece el ala, a franjas pastel, con **la firmita de Coco** en la punta | `arcoiris_partida_ala_pinte` (1,5 s) | "Fiu" y confeti |
| NI3 | 0,5 s | **Zoom suave 1,0 → 1,12** hacia el costado de la nave; termina **antes** de que se pueda arrastrar. El hueco fantasma respira | — | — |
| NI4 | Interactivo | Nicole **arrastra el ala** (toda el ala es la manija). A menos de **160 px** del centro del hueco **encaja sola** (0,3 s), y el contorno punteado se vuelve línea llena. Si la suelta lejos, vuelve flotando al trébol, sin sonido de error | — | "Clonc" acolchado y chispitas |
| NI5 | 2,8 s | Aparecen **3 broches dorados**, cada uno con target de **⌀ 110 px**, en pantalla (con el zoom) en **(640, 300), (640, 440) y (790, 520)**: ≥ 24 px entre targets y sobre la barra | `arcoiris_partida_broches_intro` (2,8 s) | — |
| NI6 | 3 toques | En cualquier orden, cada broche **gira dos vueltas** (0,5 s) y **enciende una franja del ala**, de la raíz a la punta | `arcoiris_partida_broche_1`, `_2` y `_3` (en orden de toques) | "Cric-cric" y "¡tin!", con una nota que sube |
| NI7 | 2,2 s | El ala completa brilla. **La nave aletea una vez con su única ala**, da un saltito... y **se ladea 8°**, como un pájaro chueco | `arcoiris_009` (2 s, reubicada aquí por el PO) | "Flap" y "boing" |
| NI8 | 4,0 s | **Coco la endereza con la cola** ("¡upa!") | `arcoiris_partida_ala_chueca` (3,8 s) | Risitas |
| NI9 | 2,2 s | El zoom vuelve a 1,0 | `arcoiris_partida_ala_lista` (1,4 s) y el gesto de Nicole | "Tilín" rosado |

**Ayudas**:

- NI4: a los 8 s, `arcoiris_partida_ala_recuerda` (el ala se menea); a los 18 s, el ala flota sola hasta la
  mitad del camino; a los 30 s, `arcoiris_partida_ala_ayuda` y se instala sola.
- NI6: a los 8 s, `arcoiris_partida_broche_recuerda` (el broche siguiente late).

### 9.5 Sofía traza la ruta: A-N-I-M-A-L-I-A y el perrito (≈ 35 s, más el dato opcional)

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| SO0 | 0,0-1,8 | El retrato de Sofía salta y **el mapa del Coleccionauta vuela de su retrato a la cúpula**. Iris a la **pantalla de navegación** | `nucleo_equipo_ahora_sofia` | "Fiuu" e iris |
| SO1 | 2,0-6,0 | La pantalla de navegación; el punto de partida (Arcoíris) late | `arcoiris_partida_ruta_intro` (4 s) | — |
| SO2 | 8 estrellas | Toca las estrellas en orden, **o arrastra el dedo** de una a otra. En cada estrella correcta, una línea de luz se dibuja desde la anterior (0,25 s) y la letra crece a 1,2×. Una estrella equivocada (señuelo o fuera de orden) da "bup" y se menea 0,2 s, sin línea y sin voz | Tocar a Cometa: `ruta_intro` y después `arcoiris_partida_ruta_sigue_<letra>` (a, n, i, m o l) | **La melodía de la ruta**, una nota por estrella |
| SO3 | 2,4 s | Con la 8.ª, la línea llega a Animalia, que se enciende en verde con su huellita. **La constelación se vuelve un perrito**: las líneas se redondean y le salen orejas caídas y cola (0,6 s, morph por código). **Ladra** ("¡guau!") y **menea la cola** | `arcoiris_partida_ruta_perrito` (2 s) | "¡Guau!" de cachorrito |
| SO4 | 2,2 s | **Las 8 letras bajan y forman "ANIMALIA"** (y ≈ 520), que se ilumina letra por letra | `arcoiris_partida_ruta_animalia` (2 s) | "Do" agudo |
| SO5 | 2,3 s | — | `arcoiris_partida_ruta_lista` (1,5 s) y el gesto de Sofía | Fanfarria corta |
| SO6 | 0,6 s (+5 s opcionales) | Iris de vuelta al Claro: **la cúpula muestra el perrito-ruta brillando** y la estrellita de la antena parpadea en verde | Opcional: `arcoiris_partida_ruta_dato` (5 s), durante el iris [guion, duda 2] | — |

**Layout de la pantalla de navegación**:

| Elemento | Posición y tamaño |
|---|---|
| Marco de consola turquesa con remaches dorados | Pantalla completa, borde de 40 px (por código) |
| Campo de estrellas | `Rect2(120, 100, 1040, 470)` |
| Arcoíris (partida) | Centro (190, 360), ⌀ 110 px |
| Animalia (destino) | Centro (1090, 330), ⌀ 130 px, verde apagado hasta SO3 |
| **8 estrellas de la ruta: A, N, I, M, A, L, I, A** | Estrella dibujada de 64 px, **target de 96 px**, letra Baloo de 36 px. De izquierda a derecha en zigzag (el sentido de lectura resuelve las letras repetidas); sus posiciones ya anticipan el perrito |
| **5 estrellas señuelo: O, E, U, S y R** | Mismas medidas, intercaladas, a ≥ 24 px de cualquier otro target |
| Mapa del Coleccionauta (referencia) | `Rect2(540, 12, 200, 80)`. Tocarlo lo agranda 2 s |

**Ayuda**: a los 8 s sin una estrella correcta, `arcoiris_partida_ruta_recuerda` y **la estrella siguiente
late**. Sin reloj ni puntaje. **Si es "de bebés"**: 8 señuelos o un orden que no sea de izquierda a
derecha. **Si la frustra**: que la estrella siguiente lata desde los 4 s.

### 9.6 Fin de los preparativos (≈ 4,2 s)

| Tiempo | Qué pasa | Voz |
|---|---|---|
| 0,0-1,5 | La nave lista (tanque lleno, ala puesta, perrito en la cúpula) da un saltito | `arcoiris_partida_nave_lista` |
| 1,7-4,2 | Coco se acerca al centro y junta las manoplas | `arcoiris_partida_coco_algo` |

## 10. Despedida de Coco (interactiva, ≈ 40 s)

**Un "hasta pronto", nunca triste.** La barra se oculta. Los tres hermanos (rigs de ≈ 260 px) están en
fila frente a la nave, con los pies en (380, 590) Maxi, (600, 590) Nicole y (820, 590) Sofía. Arriba, el
**ícono del hangar** en `Rect2(1060, 8, 96, 96)`: no es tocable, es el destino de los regalos.

**Por hermano** (Maxi → Nicole → Sofía), ≈ 10 s cada uno:

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| D1 | 0,0-0,8 | Coco va a saltitos hasta el hermano, que recibe el foco | — | "Boing" chico |
| D2 | 0,8-4,8 | Coco saca el regalo de detrás de la espalda; **pop con chispitas** y el regalo flota a las manos del hermano. La reacción: Maxi salta, Nicole lo abraza y Sofía lo mira de cerca y sonríe | `arcoiris_partida_coco_regalo_<hermano>` (3,5-4 s) | "Tilín" del color del hermano |
| D3 | 5,0-6,0 | **Coco levanta la manopla**: target de **⌀ 200 px para Maxi** y **⌀ 150 px para Nicole y Sofía**, a y ≈ 380 | `arcoiris_partida_coco_choca` (1 s) | — |
| D4 | Toque | **Choque de cinco**: las manos se juntan (0,3 s), estallan estrellas y **Coco se pinta del color del hermano** (Maxi `#4aa8ff`, Nicole `#ff5fae`, Sofía `#4fd8e0`) | `arcoiris_partida_coco_choca_<hermano>` (2 s) y, opcional, `arcoiris_partida_chao_coco_<hermano>` (niños: los tres o ninguno) | "¡PA!" y campanitas |
| D5 | 0,6 s | **El regalo vuela al ícono del hangar** | — | "Fiu" |

**Los regalos** (aprobados por el PO): **T-rex de gomita** (Maxi), **corazón rosado chicle** (Nicole) y
**pony turquesa con crin de arcoíris** (Sofía). Los tres en un cuadro de 120 px, con el mismo peso visual.

**Cualquiera puede tocar** la manopla, y el choque cuenta para el hermano que brilla.

**Sin toque**:

- a los 6 s, `arcoiris_partida_choca_recuerda` y la manopla se menea;
- **a los 15 s con Maxi**, Coco le choca la manito ella misma, despacito;
- **a los 20 s con Nicole o Sofía**, Coco la abraza con `arcoiris_partida_coco_abrazo`.

Después suena igual el `coco_choca_<hermano>`. Nadie "lo hizo mal".

**Después de los tres**:

| # | Tiempo | Qué pasa | Voz | SFX |
|---|---|---|---|---|
| D6 | 0,0-2,0 | Coco abraza a Cometa. **El álbum de abrazos de Cometa se abre solo y aparece una estampita de Coco** | `arcoiris_partida_album` (1,8 s) | "Tilín" y "fssh" |
| D7 | 2,2-7,7 | Coco al centro **se pinta entera de arcoíris** y se despide con la cola en espiral, con un bailecito. En "¡soy yo, saludándolos!" mira a la cámara | `arcoiris_partida_coco_cierre` (5,5 s) | Marimba de Coco, tierna y con ritmo |
| D8 | 7,9-10,4 | Los tres regalos brillan en el ícono del hangar | `arcoiris_partida_hangar` (2,5 s) | Campanita triple |

## 11. La video-llamada de papá (≈ 28 s)

Es B7 de `batalla_arcoiris.md`, movida a la partida y ya no opcional. La foto se entregó en B6.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| V0 | 0,0-1,8 | La nave | **Abordaje**: los tres rigs saltan a la cúpula (pop, 0,4 s cada uno) y Cometa entra al asiento del piloto | — | Pops (do, mi, sol) |
| V1 | 1,8-2,4 | — | Se abre la **pantalla-burbuja** desde la antena, en `Rect2(240, 70, 800, 450)` | — | "Tin" |
| V2 | 2,6-6,6 | Papá (motion comic) | Rebota con la risa; a su lado aparece la **polaroid de los tres**, chiquita | `arcoiris_batalla_cierre_papa_01` (4 s) | El tema del mapa, suave |
| V3 | 6,9-11,9 | Papá y, **detrás**, el Coleccionauta | **Gag sin palabras**: detrás de papá pasa el Coleccionauta de derecha a izquierda, **pintado de lunares** y tarareando, **palpándose los bolsillos**; los da vuelta, no hay nada, se encoge de hombros y sigue. Busca su mapa: lo tienen los niños | `arcoiris_batalla_cierre_papa_02` (5 s) | Kazoo bajito (−8 dB bajo la voz) |
| V4 | 12,2-20,2 | Papá | "Animalia": en una esquina asoma la **huellita** del mapa. "Ladridos": se mueve una **huella de perrito**. "¡GRRR!": aparece una **huella de dinosaurio simpática** (para Maxi; nunca da miedo). "...O es mi guatita": imagen A9 "papá riéndose", sobándose la guata | `arcoiris_batalla_cierre_papa_animalia` (8 s) | Un "guau" y un "grr" de juguete **entre frases**, nunca encima de la voz |
| V5 | 20,5-27,5 | Papá | En "Los quiero mucho" **se abraza a sí mismo** | `arcoiris_batalla_cierre_papa_03` (7 s) | — |
| V6 | 27,5-28,3 | — | La pantalla se cierra en destellos dorados | — | Destellos |

La llamada no tiene reemplazo TTS: es la voz de papá. Mientras no esté grabada, se usa un placeholder
marcado como tal.

## 12. Cuenta regresiva (al final, por decisión del PO) y despegue (≈ 20 s)

### 12.1 Cuenta regresiva (≈ 7 s más los toques)

**Composición**: la nave con las caras en la cúpula y **los tres retratos grandes en la barra** (≥ 160 px;
el de Maxi ≥ 200 px). Sobre la nave, **3 estrellas** (⌀ 120 px) en (520, 120), (640, 100) y (760, 120), con
el 3, el 2 y el 1 adentro.

| # | Qué pasa | Voz | SFX |
|---|---|---|---|
| CR0 | Las estrellas apagadas; los tres retratos respiran | `arcoiris_partida_cuenta_intro` (4,5 s; su "¿Rugidos?" llega justo después de la llamada) | — |
| CR1 | **En cualquier orden**, cada retrato tocado (una vez cada uno) salta y **enciende la estrella siguiente** (3, después 2, después 1). La nave tiembla 2, 4 y 6 px | `nucleo_cuenta_tres`, `nucleo_cuenta_dos` y `nucleo_cuenta_uno` | Pops (do, mi, sol) y un "brrr" que crece |
| CR2 | Las toberas se encienden | `arcoiris_partida_despegue` (1 s) | "Brrrum" |

**Ayudas**: a los 8 s sin toque se repite `cuenta_intro`. A los 25 s, los que faltan saltan solos con
`arcoiris_partida_vamos_todos`.

No suenan `nucleo_equipo_despegar` (porque cuenta sola) ni `arcoiris_despegue_coco_espera`.

### 12.2 Despegue por el puente de 3 bandas (≈ 12,5 s)

La barra se oculta; la casa queda a la vista.

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| DS1 | 0,0-1,2 | La nave | Sube 80 px tambaleándose de emoción y suelta chispitas de 3 colores. Coco, abajo, se despide con la cola | — | Tema de Arcoíris en versión fiesta, a tempo de viaje |
| DS2 | 1,2-3,0 | — | La nave (escala ≈ 0,35, ≈ 200 px) vuela al **pie izquierdo del arcoíris** y **se posa en la banda amarilla** | `arcoiris_partida_puente` (1,8 s) | "Plin" |
| DS3 | 3,0-7,0 | **El puente** (rojo, amarillo y azul) | Recorre el arco completo (`Path2D` sobre el radio 520, de 175° a 5°, 4 s, ease in-out). La rotación sigue la tangente, con tope de ±35°. **Cada tramo suena como una tecla de xilófono** y deja una estela. En la cima, las caras gritan de alegría | Opcional: `arcoiris_partida_wii_<hermano>` (los tres o ninguno) | Glissando de xilófono |
| DS4 | 7,0-9,0 | El extremo derecho | **La punta se curva como rampa** y lanza la nave al cielo | `arcoiris_partida_rampa` (2 s) | "¡Boing-fiuuu!" |
| DS5 | 9,0-12,0 | El cielo | La nave se vuelve **estrella fugaz** y el cielo se funde a noche. Coco, chiquitita abajo, saluda | `arcoiris_partida_coco_chao` (3 s) | Brillo de estrella fugaz |
| DS6 | 12,0-12,5 | — | Iris al Mapa Estelar | — | "Fiuu" |

## 13. Mapa Estelar con rumbo a Animalia (≈ 14 s)

Sobre `mapa_estelar.gd`: Arcoíris en (318, 478) y Animalia en (530, 290).

| # | Tiempo | Qué se ve | Acción y animación | Voz | Música y SFX |
|---|---|---|---|---|---|
| ME1 | 0,0-1,0 | El mapa | **La nave, ya con su ala** (N13), sale de Arcoíris con estela de arcoíris, hace un loop y **se queda "en rumbo" junto a Arcoíris**, con la nariz hacia Animalia | — | "Fiuuu" |
| ME2 | 1,0-3,0 | El tramo Arcoíris → Animalia | **Se enciende estrella por estrella** (8 destellos). Queda guardado en `equipo.rumbos` | — | **La melodía de la ruta** |
| ME3 | 3,0-5,0 | Animalia | **Rama A** (no existe el capítulo 2): sigue "todavía muy lejos" (gris y desenfocada), pero un halo late dos veces y la huellita aparece 1 s. **Rama B**: se enciende a todo color y late | — | Campanita lejana |
| ME4 | 5,0-9,5 | La nave en rumbo | Se mece contenta | Rama A: `arcoiris_partida_estelar_lejos` (4,5 s). Rama B: `arcoiris_partida_estelar_abierto` (2,5 s) | — |
| ME5 | 9,7-14,0 | El mapa entero | **Fuegos artificiales** sobre Arcoíris; **los tres retratos asoman abajo al centro** (≈ 160 px) y hacen su gesto por turno (0,8 s cada uno). El mapa se vuelve interactivo | `arcoiris_partida_estelar_celebra` (2,5 s) | Acorde final y el tema del mapa |

- **Cierre en celebración, nunca en corte** (GDD §3).
- **La nave no viaja por la ruta**: queda en rumbo, así que no salta de lugar al volver la interacción, y
  Arcoíris se sigue pudiendo tocar.
- **Rama A**: después, al tocar Animalia suena `arcoiris_partida_animalia_lejitos`.
- **Rama B** [PO, duda 3]: propongo **no** encadenar solo el viaje Galaga.

## 14. La revancha: lo mínimo que se repite

La ficha v2 (§11) fija que **en la revancha se rejuega solo la Torre**, con la partida ya hecha. Propongo
repetir **lo mínimo**:

| Pieza | En la revancha |
|---|---|
| Presentación de la Torre (§3) | No (va directo a `arcoiris_batalla_torre_intro_revancha` y a la intro corta) |
| Derrotas-gag (§7) | Sí, con el conteo reiniciado (1, 2, 3, 4…) |
| Anticipación (§4.1) | **Sí, entera**: es el desenlace de la jugada y no se salta |
| Caída (§4.2), C1-C5 | **Sí**, y se salta con un toque (ya vista) |
| C6, la fiesta máxima | **Sí, como mini fiesta**: confeti, los retratos saltan y `la_botaron` (o `lo_bajamos`) |
| Estrellitas y récord | Los del motor (ficha §11: `nucleo_equipo_lanzar_estrellitas_1..3`, la banderita y las líneas de récord) |
| Antes del epílogo, epílogo, cierres A y B, parte C, pausa y partida | **No** |
| Salida | Iris de vuelta al mapa del planeta, con el Coleccionauta todavía sentado en el charco saludando. Un final visual sin voz nueva |

## 15. Notas sobre la escena del ala (Beat 2, `escena_planeta_arcoiris.md`)

`arcoiris_009` se fue a NI7. En el Beat 2, según el estado **familiar** del ala:

- **`arcoiris_009a`**, si la familia todavía no hizo la ceremonia: Coco entrega el ala **envuelta para
  regalo** y **queda junto a la nave**. El hueco fantasma **no** se llena: solo brilla un poco más, como
  diciendo "ya casi".
- **`arcoiris_009b`**, si la ceremonia ya ocurrió (un hermano llega a su zona 3 después): la nave **ya
  tiene el ala**. Coco señala la nave y el ala destella en su lugar. No hay entrega de nada que ya está
  puesto.

## 16. Saltar, "ya vista" y retomar

### 16.1 Qué se puede saltar (por familia; se marca al terminar)

| Pieza | Id | Desde la 2.ª vez, un toque deja… |
|---|---|---|
| Presentación de la Torre | `arcoiris_batalla_final:presenta_torre` | La intro |
| Anticipación | — | No se salta (un toque se encola para la caída) |
| Caída | `arcoiris_batalla_final:caida_torre` (lo marca `batalla.gd` con `momento_saltable_terminado`) | El estado final del §4.2 |
| Derrotas-gag | — | "¡Otra vez!" las corta desde la 1.ª vez |
| Antes del epílogo, cierres A y B | Los de `batalla_arcoiris.md` §12.3 | Ídem |
| Parte C, el mapa | `arcoiris_batalla_final:mapa_coleccionauta` | La pausa, con el mapa en el retrato de Sofía |
| Preparativos, despedida de Coco y cuenta | — | Se juegan |
| Video-llamada | `arcoiris_partida:llamada_papa` | La cuenta regresiva |
| Despegue | `arcoiris_partida:despegue` | Iris al Mapa Estelar |
| Mapa Estelar | `arcoiris_partida:llegada_estelar` | El mapa interactivo, con la nave en rumbo |

### 16.2 La partida se ve una sola vez

Está en `equipo.partidas.arcoiris` (ficha §13.4): `hecha`, `ceremonia` y `forzada`.

- **La llave de los padres** (`forzar_partida`) deja la nave lista **sin ceremonia**. Si después ganan la
  batalla, el bloque 2 se juega igual una vez, sin "instalar" un ala que ya se ve puesta.
  - [CONCILIAR] En ese caso, NI0-NI8 tienen que mostrar el ala ya puesta: propongo que Nicole **solo gire
    los broches** y que se omitan el moño, el arrastre y `ala_pinte`.

### 16.3 Retomar la partida

- **Cuándo se guarda**: al terminar cada paso (`tanque`, `ala`, `ruta`, `despedida` y `llamada`).
- **Al volver**: desde el hito de partida, el ritual corto y **se sigue en el primer paso pendiente**. Lo
  hecho se ve hecho.
- **Si salieron a medias**:
  - durante la llamada, la llamada se repite entera;
  - durante la cuenta o el despegue, se retoma en la cuenta.

## 17. Música y SFX (CC0: Kenney o FreePD)

- **Anticipación**: la música se apaga. **El silencio de K4 es parte del diseño** (0,8 s).
- **Caída**: SFX graves y estirados, un splash redondo y **la fanfarria más grande del planeta** en C6.
- **Derrotas-gag**: un instrumento por gag (cumbia de kazoo, estornudo, silbido que baja y chicle). Nunca
  un golpe sin anticipación, y todo al 70 %.
- **Charco**: un "chof" y una ondita cada vez que crece.
- **La melodía de la ruta**: escala de do ascendente (8 notas, celesta). Suena **tres veces**: en el mapa
  (M5), en la ruta de Sofía (SO2) y en el Mapa Estelar (ME2). Es el hilo musical de Animalia.
- **Preparativos**: el tema de Arcoíris tranquilo, a −8 dB.
- **Despedida de Coco**: marimba tierna y con ritmo, sin violines tristes.
- **Despegue**: el tema en versión fiesta y el glissando de xilófono en el puente.
- **Ducking**: −8 dB con cualquier voz. Los SFX de la llamada van entre frases.

## 18. Duraciones (estimadas, primera vez)

| Pieza | Duración | Se salta |
|---|---|---|
| Presentación de la Torre (antes de la etapa) | ≈ 10,4 s | Desde la 2.ª vez |
| Derrota-gag (por derrota) | ≈ 13-18 s sin "¡otra vez!", más ≈ 7 s de rearmado | "¡Otra vez!" |
| Anticipación | ≈ 4,6 s (A) / ≈ 3,2 s (B) | No |
| Caída | ≈ 10,5 s | Desde la 2.ª vez |
| Antes del epílogo | ≈ 5,4 s | Desde la 2.ª vez |
| Epílogo (interactivo) | ≈ 75 s | Se juega |
| Cierre A + B | ≈ 19,8 + 22,8 s | Desde la 2.ª vez |
| Parte C, el mapa | ≈ 13 s | Desde la 2.ª vez |
| **Bloque 1** | **≈ 2,5 min** | |
| Entrada y ritual | ≈ 9 s | Intro desde la 2.ª vez |
| Maxi / Nicole / Sofía / fin | ≈ 23 / 28 / 35 (+5 del dato) / 4 s, más ≈ 3 s de transiciones | Se juegan |
| Despedida de Coco | ≈ 40 s | Se juega |
| Video-llamada | ≈ 28 s | Desde la 2.ª vez |
| Cuenta y despegue | ≈ 7,5 s + toques + 12,5 s ≈ 22 s | Despegue desde la 2.ª vez |
| Mapa Estelar | ≈ 14 s | Desde la 2.ª vez |
| **Bloque 2** | **≈ 3,4 min** | |
| **Total del cierre** (desde el derribo final hasta el Mapa Estelar) | **≈ 5,9 min**, en dos sesiones naturales si se aprueba la pausa | |
| **Revancha ganada** (desde el derribo) | ≈ 4,6 + 10,5 s + estrellitas ≈ 20 s | — |

**Para UX**: lo más largo sin tocar en el bloque 2 es la llamada (≈ 28 s). Si Maxi se va ahí, el primer
recorte es el chiste de la guatita dentro de `papa_animalia`, que tendría que grabarse aparte.

## 19. Assets

### 19.1 Que ya existen o están pedidos en otras fichas

| Asset | Uso |
|---|---|
| Rig del Coleccionauta (A1), mochila-torre (A2) y patito (A4) de `batalla_arcoiris.md` | Todo el bloque 1 |
| Rigs de los hermanos (`assets/sprites/preview_*_rig/`) | Fiesta, preparativos, despedida, abordaje y Mapa Estelar |
| Coco (`coco_base.png`), su lengua del Río y su `modulate`; Cometa (`cometa_base.png` y `cometa_saludo.png`) | Todo |
| Paisaje del Claro y arcoíris por código (`paisaje_arcoiris.gd`) | Todo |
| Nave-estrella (`assets/sprites/nave/`, anclas de los estados incompleto y completo) | Base de N7 y N13 |
| **Arte de la Torre (ficha §18.1)**: torre, piezas "en el suelo", tapas sueltas, resortera, canasta, globos, gigante y manchas; poses de agarre del Coleccionauta; Coco camuflada y morada | Presentación, gags, gigante y caída |
| Pantalla "¡todos a la nave!", barra, sobre-estrella, polaroid e imágenes de papá (Beat 4 y A9) | Entrada, cuenta, foto y llamada |
| `mapa_estelar.gd`, `planeta_dibujado.gd` y la fuente Baloo | Mapa Estelar y letras |

### 19.2 Arte nuevo (para `disenador-personajes`)

| Id | Asset | Detalle | Lo usa |
|---|---|---|---|
| **N2** | **Poses nuevas del Coleccionauta** (además de las de la ficha §18.1) | "Mochila en alto"; piernas pedaleando en el aire (2 cuadros); saludito de dedos mirando a cámara, **colgado del cojín con un dedo**; carcajada chapoteando; baile (2 cuadros de cadera); masticando e inflando chicle; cara pintada y muy digna; palpándose los bolsillos con los bolsillos dados vuelta | Anticipación, caída, gags y llamada |
| **N3** | **Capa "pintado de lunares"** por pieza | Lunares multicolor, 3 gotas que chorrean de las antenas, y las variantes de cabeza rosada (gag 1), cara pintada (gag 3) y cara de chicle (gag 4) | Caída, gags, epílogo, despedida y llamada |
| N4 | Corona de salpicón | El charco es por código (ficha §6.9); la corona de salpicón, en 3 cuadros si el código no alcanza | Caída |
| **N5** | **Mapa del Coleccionauta** | Bolita arrugada (90 px) y desplegado (1000 × 560). Crayón, **sin texto**: Arcoíris, ruta de 8 estrellitas con flechita y el planeta verde con huellita. **Que no parezca un perrito** | Cierre A, parte C, pausa, Sofía |
| **N6** | **Ala izquierda envuelta para regalo** | Envuelta (papel y moño arcoíris) y desenvuelta (con la firmita de Coco). La envuelta sirve también en el Beat 2 con `009a` | Pausa, Nicole y escena del ala |
| **N7** | **Nave-estrella por capas** | Casco con el hueco del ala; **ala instalada** que calce exacto; **3 broches dorados** (y un cuadro girado); cúpula con lugar para 3 caras y Cometa; toberas con brillo aparte | Pausa, preparativos, abordaje, llamada y despegue |
| **N8** | **Tanque-caramelo y manguera** | Tanque transparente con ventanita, embudo y máscara de llenado; manguera de 3 franjas en piezas; balde de pintura arcoíris | Maxi |
| **N9** | **Regalos de Coco** (aprobados) | **T-rex de gomita**, **corazón rosado chicle** y **pony turquesa con crin de arcoíris**: 3 props de 120 px con el mismo peso visual | Despedida de Coco |
| **N10** | **Poses de Coco** (o un rig simple) | Manopla arriba; abrazo; cargando algo en la cabeza; soplando | Preparativos y despedida |
| N11 | Cometa con el álbum de abrazos abierto, más la estampita de Coco | — | Despedida |
| **N12** | Pelusa con forma de nubecita | Reemplaza a la mosquita A5 | Antes del epílogo y gag 2 |
| **N13** | Nave del Mapa Estelar con el ala | El sprite a escala 0,2 | Mapa Estelar |
| N14 | Props de los gags | Frasco de pintura rosada, calcetines sueltos, tapa-corona y chicle | Gags |
| N15 | Dibujitos de la llamada | Huellita de perrito y huella de dinosaurio simpática (pueden ser por código) | Llamada |
| N16 | Mano abierta para el choque de cinco (pieza del rig de los hermanos) | Solo si hace falta | Despedida |

**Por código**: el charco, el arcoíris y el puente, los chorros, las burbujas, el campo de estrellas, las
líneas, el morph al perrito, el marco de la consola, los fuegos, el confeti y la flechita del globo fuera de
pantalla.

### 19.3 Animación (para `dev-godot`)

| Dónde | Animaciones |
|---|---|
| `motor_lanzar` (dueño de la torre) | `presenta_torre`, `anticipacion` (variantes A y B), `caida_torre` (desde `estado_derribo()`), los gags `gag_baile`, `gag_estornudo`, `gag_globo_vuelve` y `gag_chicle` (según `variante_derrota()`), `rearma`, `gigante_inflado` (F o G), `gigante_vuelo` y `charco_crece` |
| `batalla.tscn` (`CinematicasBatalla`) | `antes_epilogo` (mochila gris y pelusa), `cierre_a` (con la pista `mapa_cae`), `cierre_b` (hasta B6), `mapa_coleccionauta` y la pantalla de pausa |
| **`escenas/planetas/arcoiris/partida_arcoiris.tscn`** (nueva) | `entrada`, `chorro`, `nave_estornuda`, `ala_desenvolver`, `ala_encaja`, `broche_gira`, `ala_aletea`, `ruta_linea`, `ruta_perrito`, `ruta_palabra`, `despedida_<hermano>` (plantilla), `choque_cinco`, `coco_abrazo_cometa`, `coco_cierre`, `abordaje`, `llamada_papa`, `cuenta_estrella`, `despegue_puente` |
| `mapa_estelar.gd` | `llegada_rumbo(origen, destino, abierto: bool)` y el rumbo encendido persistente |
| `coleccionauta.tscn` | `mochila_en_alto`, `pedalear_aire`, `colgado_dedo`, `saludito_camara`, `carcajada_chapotea`, `bailar`, `chicle`, `palpar_bolsillos` y `pintado(variante)` |

## 20. Notas de implementación

- **La torre, la anticipación, la caída, los gags y el gigante son del motor** (ficha §13). `batalla.gd`
  solo escucha `momento_saltable_iniciado/terminado`, consulta
  `Progreso.cinematica_vista("arcoiris_batalla_final:caida_torre")` y llama a `saltar_momento`. **Nunca
  conoce `derribo_inminente`.**
- **La caída no es física**: es una coreografía que interpola desde `estado_derribo()`. Nada cae sobre él,
  salvo la tapa-sombrerito.
- **Cámara lenta**: `speed_scale` de la cinemática, **nunca `Engine.time_scale`**.
- **Sincronía por pasos** `{animacion, voz, solape_s, aire_s}`, como en `batalla_arcoiris.md` §14.1.
- **Estado familiar** (ficha §13.4):
  - la nave se dibuja con el ala si `partida_hecha("arcoiris")`; antes, quien tiene la pieza ve el ala
    envuelta junto a la nave;
  - el hito del Claro tiene 3 estados: batalla → partida → revancha;
  - el viaje pide `partida_hecha`, o la llave de los padres;
  - el rumbo está en `equipo.rumbos`.
- **"¡Juntos!"**: la presentación única se muestra la próxima vez que se abra la selección.
- **Capas (`z_index`) del bloque 2**: cielo 0, suelo 10, nave 20, Coco 30, hermano 35, partículas 50,
  barra 60, casa y Cometa 70.

## 21. Lo que sigue abierto [CONCILIAR]

| # | Qué | Con quién |
|---|---|---|
| 1 | **Logro común**: la ficha usa 2 tramos (piezas botadas, corte en 14 de 28) y el guion v2 trae 3 líneas por agarre. Este storyboard usa `lanzar_logro_1` y `_2`; `_3` sobra o se funde | `guionista` y `disenador-mecanicas` |
| 2 | **Ayuda tras la 2.ª derrota**: la ficha cita una línea `ayuda_globo_gigante` que el guion v2 ya no tiene. El plano de la variante F usa `gigante_inflado`. Se resuelve junto con el gigante [PO] | `guionista` y `disenador-mecanicas` |
| 3 | **Voces del gigante** que faltan: `gigante_turno_maxi` (si lo tira Maxi) y una de impacto (`gigante_impacto`, que estaba en la v1 del guion). Mientras tanto, el impacto va sin voz | `guionista` |
| 4 | **La ficha sigue citando ids de la v1 del guion** (`cajas_botadas_0X`, `acierto_0X`, `fallo_0X`, `ayuda_globos_extra`, `cae_lenta`, `cae_risa`). Este storyboard usa los del guion v2 (`lanzar_logro_*`, `tiro_*`, `traje_dos_mas`, `cae_mochila` y `cae_charco`) | `disenador-mecanicas` |
| 5 | **Partida tras la llave de los padres**: con el ala ya puesta, NI0-NI8 se reducen a girar los broches (§16.2). Hace falta confirmar la forma y, quizás, una consigna sin "ábrela" | `disenador-mecanicas` y `guionista` |
| 6 | La posición de la nave "en rumbo" en el Mapa Estelar (hoy es por perfil) y cuál es hoy la voz de los planetas lejanos (para `animalia_lejitos`) | `dev-godot` |
| 7 | La salida de la revancha: el storyboard propone solo un final visual, sin voz nueva | `guionista` (si quiere una línea) |
| 8 | El tope de 5 s de "antes del epílogo" (queda en 5,4 s) | `experto-ux-parvulo` |

**Cerrados en esta pasada** (antes estaban [CONCILIAR]):

- los textos de los broches (`broches_intro`, `broche_1..3` y `broche_recuerda`) y los de la ruta
  (`ruta_intro`, `ruta_sigue_<letra>` y `ruta_recuerda`): ya no hay tornillos ni "de dos en dos";
- la escena del ala (`009a` y `009b`);
- los regalos;
- las señales del motor;
- el layout de la torre y del charco;
- el charco que crece;
- la rotación de los gags y la pausa desde la 3.ª derrota;
- la revancha (solo la Torre);
- la ficha §9 con charco y no malvaviscos;
- la presentación T.1;
- la lectura «¡A-NI-MA-LIA!» y «¡no lo necesitamos!».

## 22. Dudas que siguen abiertas para el PO

1. **La pausa natural entre "la victoria" y "la gran partida"** (§8.1). Sin ella, son ≈ 6 min seguidos
   después de una batalla de 18-20 min.
2. **Los colores del tanque de Maxi**: los 3 recuperados (como el puente y como está hoy en el guion v2) o
   7 colores, que adelantan el verde, el naranjo y el morado de las zonas 4-5.
3. **Con el capítulo 2 listo**: terminar en el Mapa Estelar con Animalia encendida (propuesta) o encadenar
   el viaje Galaga.
4. **El globo gigante [PO]**: quién lo infla (Coco sola tras la 2.ª derrota, o los tres con las
   ventanitas) y quién lo tira (Maxi o Coco). El storyboard funciona con las dos variantes (§7.6).

## 23. Tarjetas sugeridas (las decide `scrum-master`)

| # | Tarjeta | Rol | Depende de |
|---|---|---|---|
| T1 | **Arte del cierre de Arcoíris**: N2-N16 | `disenador-personajes` | — (el arte de la Torre va en la tarjeta de la ficha) |
| T2 | **Torre en el motor**: presentación, anticipación A y B, caída, 4 gags, rearmado, gigante (F o G) y charco | `dev-godot` | Ficha v2, N2, N3, N12, N14, rig A1 y duda 4 |
| T3 | **Ajustes al cierre de la batalla**: antes del epílogo, cierre A con el mapa, cierre B hasta B6, parte C y pausa con el hito de partida; y una nota en `batalla_arcoiris.md` que apunte aquí | `dev-godot` (la nota, `director-cinematicas`) | T2, N5 y N6 |
| T4 | **Partida, parte interactiva**: entrada, tanque, ala y broches, ruta-perrito, con guardado por paso | `dev-godot` | N6-N8 y el estado familiar (ficha §13.4) |
| T5 | **Partida, parte narrativa**: despedida de Coco, llamada, cuenta, puente, Mapa Estelar y la escena del ala con `009a`/`009b` | `dev-godot` | T4, N9-N11, N13, N15 y la grabación de papá |
| T6 | **Voces** (§21, puntos 1-3, 5 y 7) y generación: TTS **con `--estimar` y OK del PO sobre el costo**, más la grabación casera | `guionista` | Duda 4 |
| T7 | **Auditoría UX y QA del cierre**, y playtest con los tres | `experto-ux-parvulo` y `tester-qa` | T2 a T5 |
