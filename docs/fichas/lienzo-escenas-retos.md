# Ficha de diseño: escenas de inspiración y objetivos del lienzo ("Pinta con Coco" v2)

- **Autor**: `disenador-niveles`, 17-Oct-2026, a pedido directo del PO.
- **Estado**: PROPUESTA. Falta revisión de `disenador-mecanicas` (reglas de §1), `experto-ux-parvulo`
  (pictogramas, zoom y cola de objetivos), arte de `disenador-personajes` (§5), voces del `guionista`
  (§5.3) e implementación de `dev-godot`.
- **Fuentes**: `docs/fichas/motor-lienzo-libre.md` §8, `docs/fichas/planeta-arcoiris-zonas.md` §3.4,
  `docs/perfil-jugadores.md`, GDD §1, §5 y §6, catálogo `scripts/motores/lienzo_libre/stickers.gd`, y los
  niveles `datos/niveles/arcoiris/*/pinta_*.json`.
- **Mecánicas de referencia** (regla de oro 3): **Labo Train** (caminos con viajeros que llegan a
  destinos), **Scribblenauts** (crear lo necesario para cumplir un pedido) y **Little Alchemy**
  (combinar dos cosas para descubrir una tercera, con cadenas de descubrimientos).

## 0. Resumen de las decisiones del PO y cómo se aplican

| Decisión del PO | Cómo queda en esta ficha |
|---|---|
| Los objetivos son el motor de la hoja; la hoja no se pasa sin cumplirlos todos | "Mostrar a Coco" aparece **solo** cuando están todos cumplidos. Desaparece `segundos_mostrar` como forma de pasar la hoja (en Maxi lo reemplaza la válvula de §6.4) |
| Maxi 3, Nicole 6, Sofía 12 por hoja; Sofía variados | Las 15 escenas de §2-§4 y las 15 estaciones de §7 cumplen esas cantidades. En Sofía ningún tipo se repite más de 3 veces por hoja |
| Maxi ve 1 objetivo a la vez; Nicole y Sofía, 3 | Cola de objetivos de §1.6 |
| Escena de inspiración narrada por Coco y hecha con nuestros stickers | Cada escena trae `inspiracion` (frase y composición en 1280×720). Los objetivos salen de lo que muestra la tarjeta |
| Clases de stickers: vivos, lugares, caminos y decorados | §1.1 (clase por defecto del catálogo) y la lista por escena |
| Combinaciones mágicas tipo Little Alchemy | §5, con 32 recetas y 3 cadenas |
| Pantalla completa 1280×720 con zoom (salvo Maxi) | Coordenadas de esta ficha en 1280×720. Zoom: ver §1.7 y §10 (choque con GDD §6.4) |
| Reto obligatorio también en las zonas 2-5 | §7: el encargo es el objetivo base, y los demás son partes del encargo o extras que no lo desvirtúan |
| Sin tiempo límite, sin castigo; Coco da una pista fantasma (antes para Maxi) | §8 |

---

## 1. Reglas comunes (contrato con `dev-godot` y `disenador-mecanicas`)

### 1.1 Clases de stickers (por defecto del catálogo; una escena puede cambiarla con `clase`)

| Clase | Qué hace | Ids del catálogo actual |
|---|---|---|
| **vivo** | Anda solo, se sube a los caminos y cuenta para `llegadas`, `circuito` y `orden` | `trex`, `spinosaurio`, `carnotauro`, `carrito`, `bus`, `bomberos`, `tren`, `pony_amigo`, `unicornio`, `jirafa`, `gatito`, `perrito`, `gerbo`, `carroza`, `cohete`, `escoba`, `lechuza` (vuela, pasa de decorado a vivo) |
| **lugar** | Destino: los caminos se pegan a él y los vivos "llegan" (salta, suena y el vivo hace una acción) | `granero` (establo), `casa`, `castillo`, `volcan`, `planeta`, `montana`, `casa_valpo`, `moai`, `cactus`, `pinguino` (lugar en Tren por Chile: "la Patagonia"), `bandera_meta`, `pastel`, `caldero` |
| **camino** | Herramienta de trazo (es el "conector" de hoy). Se pega a lugares | `sendero`, `camino` (carretera), `rieles`, `cerca`, `arcoiris` (puente), `estelar`, `destellos`, `guirnalda` (adorno: une cosas, pero **no lleva viajeros**) + nuevos `huellitas`, `alfombra`, `ruta_mar` |
| **decorado** | Solo visual. Participa en combinaciones | El resto: `palmera`, `arbol`, `flor`, `nube`, `sol`, `estrella`, `corazon`, `luna`, `destello`, `roca`, `manzana`, `ovillo`, `globo`, `regalo`, `microfono`, `nota`, `foco`, `parlante`, `corona`, `vestido`, `zapato`, `sombrero_mago`, `varita`, `libro`, `hueso`, `pelota`, `bandera_chile`, `cono`, `fuego`, `huevo`, `arcoiris` (sticker), `copihue` |

**Lugares de fondo**: una región del fondo puede ser lugar (`"lugar": true` + `ancla` [x, y]). Los
lugares de fondo **lineales** (río, mar) aceptan un camino que llegue a cualquier punto de su borde.

En el árbol de la sabana, el `arbol` se declara `clase: lugar` (la acacia es el destino de las
jirafas).

### 1.2 Reglas de los vivos y los caminos (supuestos para que los objetivos se puedan validar)

- **R1 · Pegar caminos**: una punta de camino a ≤ 70 px del borde de un lugar (≤ 120 px en Maxi) se
  pega a él. Esto se llama **imán**.
- **R2 · Subirse**: un vivo que se suelta a ≤ 60 px de un camino, o sobre un lugar donde nace un
  camino, se sube y lo recorre. En Semilla, al trazar un camino, el vivo compatible más cercano que ya
  esté en el lienzo salta solo a la punta más cercana. Si se pone un vivo cuando ya hay camino, también
  salta solo.
- **R3 · Llegar**: al llegar a una punta pegada a un lugar, el lugar salta y suena, y el vivo hace su
  acción unos 1,5 s: bebe (río, charca o bebedero), ruge (volcán), saluda (casa), canta (escenario)…
  Después vuelve. Una **llegada** se registra con el lugar de partida y el de llegada. El regreso
  cuenta como llegada en el sentido contrario.
- **R4 · Redes**: si a un lugar llegan varios caminos, el vivo sigue por uno que **no sea por el que
  vino**; si hay varios, toma el más reciente. Si es un callejón sin salida, se devuelve. Esto hace
  posible `orden`.
- **R5 · Cerrar caminos**: un trazo cuya punta final cae a ≤ 60 px de su inicio (≤ 150 px y largo ≥
  500 px en Maxi), lejos de los lugares, se cierra solo y forma un **circuito**.
- **R6 · Compatibilidad**: no se restringe qué vivo anda por qué camino (así nunca se traba). Solo los
  objetivos piden un tipo de camino. Excepción: la `guirnalda` no lleva viajeros.
- **R7 · Topes**: se mantienen los de §8.4 (30 caminos, 8 viajeros andando a la vez, 60 stickers).
  Ningún objetivo pide más de 3 viajeros del mismo tipo ni más de 5 stickers iguales.

### 1.3 Tipos de objetivo y regla exacta de validación

Todo objetivo cumplido **queda cumplido**: borrar después el sticker no lo descumple. Los objetivos
se evalúan **desde el inicio de la hoja, aunque todavía no estén visibles** (§1.6).

| Tipo | Parámetros | Se cumple cuando… |
|---|---|---|
| `llegadas` | `viajero, desde, hasta, n` | Hay `n` instancias **distintas** del vivo `viajero` con una llegada registrada desde `desde` hasta `hasta` (R3). `desde` y `hasta` pueden ser un id de sticker-lugar o de lugar de fondo |
| `conectar` | `a, b, camino?` | Existe un camino (del tipo `camino`, si se indica) con una punta pegada a una instancia de `a` y la otra a una de `b` (pueden ser dos instancias distintas del mismo id). Con `guirnalda`, `a` y `b` pueden ser decorados |
| `circuito` | `viajero, vueltas` | Una instancia del vivo completa `vueltas` vueltas seguidas a un camino cerrado (R5) |
| `poner` | `sticker, n, en_zona?` | Hay al mismo tiempo `n` instancias de `sticker` (o de sello `sello_*` en las zonas 2-5). Con `en_zona`, su centro debe estar dentro de esa región. **Ampliación**: `en_zona` también acepta un id de sticker-lugar (dentro de su radio) |
| `combinacion` | `resultado` | Ocurrió la receta de §5 que produce `resultado` |
| `pintar_zona` | `zona, color?` | La región está pintada. En las regiones de relleno (balde), basta con que se haya tocado. En las de guía (espejo, mandala), la pintura debe cubrir ≥ 60 % de su área (muestreo en grilla de 16 px). **Ampliaciones**: `zona` puede ser una **lista** (todas deben cumplirse) y `distintos: true` exige un color distinto en cada región de la lista. **Color**: es el color con nombre de `colores_lienzo.gd` (o la mezcla con nombre) más cercano en RGB al de la región; en las guías, el color mayoritario en esa región |
| `colores` | `n` | Se han usado `n` colores distintos en la hoja (pintura, balde o sticker recoloreado) |
| `orden` | `viajero, lugares[]` | Una instancia del vivo llega, **en un mismo viaje continuo** (R4), a los lugares en ese orden. Puede haber paradas extra entre ellos |
| `encargo` | — | El encargo de la hoja quedó completo. Su criterio por tipo de encargo está en §7.1 |
| **NUEVO** `encerrar` | `sticker, n, con?` | Hay un camino cerrado (del tipo `con`) cuyo polígono contiene el centro de `n` instancias del sticker. Sirve para el corral, la órbita y la vuelta al castillo |
| **NUEVO** `usar` | `herramienta, n=1` | Se hicieron `n` trazos o estampados con esa herramienta. Purpurina: cuenta la lluvia dorada (quieta 1 s) |
| **NUEVO** `parte_encargo` | `parte` | Se completó una parte del encargo. `parte` es una de estas: `{regiones: [ids]}` (todas tocadas o cubiertas), `{pedido: i}` (el pedido i de Coco), `{digito: d}` (todas las celdas del mosaico con el código d bien pintadas), `{cuadrante: 1-4}` / `{borde}` / `{centro}` (sectores del mosaico bien pintados), `{cobertura: pct, zona?}` (guía cubierta ≥ pct) o `{modelo: true}` (todas las regiones con su color `sugerido`; es la "igualita" que ya detecta el motor) |
| **NUEVO** `adivinar` | `opciones=3` | Solo en los mosaicos de Sofía. Al llegar al 30 % de celdas bien pintadas, Coco pregunta "¿qué será?" y muestra 3 tarjetas: el mosaico real y 2 del mismo pool, en miniatura. Se cumple al tocar la correcta. Si toca otra, Coco hace un gag ("¡jaja, no! Mira el color de arriba…") y las tarjetas siguen ahí. Nunca descuenta nada |
| **NUEVO** `trazo_unico` | `n` | Solo en los mosaicos. En un solo trazo (sin levantar el dedo) quedan bien pintadas `n` celdas. **Repintar una celda que ya estaba bien también cuenta**, así que el objetivo nunca se vuelve imposible |

### 1.4 Combinaciones: regla de contacto

- **Contacto**: al soltar un sticker, si su centro queda a ≤ 0,6 × (radio A + radio B) del centro de
  otro, se prueba la receta con ese par. Si un vivo llega a un lugar (R3), también se prueba la receta
  vivo + lugar.
- **Recetas de 3**: tres instancias dentro de un círculo de 200 px alrededor del último sticker
  soltado.
- **Zona**: si la receta indica `en`, el contacto debe ocurrir dentro de esa región; si el fondo no la
  tiene, vale en cualquier parte.
- **Resultado**: con un "¡pling!", destellos y la voz de Coco. Si es un sticker, aparece donde fue el
  contacto. La **primera vez** de cada hoja se agrega a la bolsa con un brillo (en Nicole y Sofía).
- Las recetas son **universales**: funcionan en cualquier escena donde estén los ingredientes, aunque
  no haya objetivo. Descubrir sin que se pida también se celebra.
- **Futuro** (toca el núcleo, no ahora): un "libro de descubrimientos" con las recetas encontradas por
  cada hermano.

### 1.5 Pictogramas de los objetivos (sin texto)

Tarjeta de 180×150 px en Maxi y de 130×110 px en Nicole y Sofía. La cantidad se muestra como fila de
puntitos (●●○), sin números. Si se toca la tarjeta, Coco repite la línea de voz.

| Tipo | Pictograma |
|---|---|
| `poner` | El sticker grande + puntitos. Con `en_zona`, el sticker dentro de una miniatura de la región |
| `conectar` | Lugar A · línea punteada del color del camino · lugar B |
| `llegadas` | Vivo → huellitas → lugar B, con A chiquito detrás + puntitos |
| `circuito` | Vivo dentro de un óvalo de flechas + puntitos (vueltas) |
| `encerrar` | Sticker dentro de un óvalo del camino pedido |
| `combinacion` | Maxi y Nicole: ingrediente + ingrediente = resultado. Sofía: **? + ? = silueta brillante del resultado**. El acertijo va por voz y los ingredientes se revelan con las pistas (§8) |
| `pintar_zona` | Miniatura del fondo con la región destacada + gota del color (o un pincel arcoíris si no se pide color) |
| `colores` | Paleta con N gotas que se van llenando |
| `orden` | Vivo + fila de lugares unidos por flechas; cada lugar se enciende al pasar |
| `usar` | Ícono de la herramienta + puntitos |
| `parte_encargo` | Miniatura de la lámina con esa parte destacada; los pedidos de Coco muestran la gota pedida |
| `adivinar` | Signo de pregunta grande sobre el mosaico a medias |
| `trazo_unico` | Dedo con una estela larga + puntitos |
| `encargo` | La lámina entera con un marquito dorado |

### 1.6 Cola de objetivos

- **Maxi**: 1 tarjeta grande arriba a la izquierda. Al cumplirse, vuela hacia Coco, Maxi grita
  "¡siii!" con salto y puño (su gesto) y entra la siguiente.
- **Nicole y Sofía**: 3 tarjetas visibles. Al cumplir una, se va con una celebración corta (sin voz
  larga, GDD §5 "ritmo rápido") y entra la siguiente de la lista. El orden de las tablas es el orden de
  entrada.
- **Ya cumplidos**: si el siguiente de la cola ya estaba cumplido, entra con el check puesto, Coco dice
  "¡eso ya lo habías hecho!" y se va en 1 s.
- **Fin de la hoja**: con todos cumplidos aparece "mostrar a Coco" con rebote y suena `hoja_lista`.
  Antes de eso, el botón no existe.
- **Progreso**: una fila de estrellitas bajo las tarjetas (3, 6 o 12) muestra cuánto falta, sin
  números.

### 1.7 Pantalla completa y zoom

- El lienzo ocupa 1280×720. Por encima van:
  - las tarjetas de objetivos: arriba a la izquierda, hasta x 430 e y 150;
  - la miniatura de la inspiración: arriba a la derecha (1008-1264, 16-160);
  - Coco: abajo a la derecha (1090-1280, 540-720);
  - la barra o paleta plegable: abajo, y 620-720.
- **Zona útil de los lugares** (donde van los lugares ya puestos y la composición importante): x 40-1240,
  y 170-600.
- **Zoom (Nicole y Sofía)**: botón de lupa que alterna entre 1× y 2× centrado en el siguiente toque;
  otra vez la lupa, y vuelve a 1×. Así no se usan gestos de dos dedos (ver §10, punto 2). Lo necesitan las
  regiones chicas: manchas de la jirafa, estrellitas del ala y celdas del mosaico. **Maxi no tiene
  zoom.**
- **Tarjeta de inspiración**: al abrir la hoja ocupa toda la pantalla ~5 s mientras Coco narra. Los
  vivos de la tarjeta andan por sus caminos (en loop), para que se entienda sin palabras. Después se
  encoge a la miniatura. Si se toca la miniatura, se agranda y Coco repite la frase.

---

## 2. Escenas de Maxi (Semilla): 3 objetivos, 1 a la vez, sin zoom

Para Maxi, los **lugares vienen ya puestos** en el fondo; él solo pone vivos y traza. La barra tiene 3
stickers grandes (96 px), el pincel y el camino. La escalera de cada hoja es siempre:
1. tocar y poner (victoria fácil);
2. trazar un camino (con imán grande);
3. una sorpresa (combinación o vuelta).

Hojas por partida: 2 (sin cambios). Al menos una es `favorito` (dinos o carreras).

### 2.1 `parque_dinos` (favorito)

- **Inspiración** (voz `escenas/parque_dinos/inspiracion`): "¡Mira! Un parque de dinosaurios. El T-rex
  camina por el sendero hasta el lago a tomar agüita… ¡y junto al volcán hay un huevo calentito!"
- **Fondo base**:
  - cielo 0-1280 × 0-440;
  - sol (180, 140) r70;
  - **volcán** (lugar de fondo): polígono (820,560) (960,200) (1080,200) (1220,560), con ancla (1020, 520) y lava arriba;
  - suelo y ≥ 440;
  - **lago** (lugar de fondo): elipse (300, 600), radios (230, 70), con ancla (300, 560).
- **Barra**: vivos `trex` y `spinosaurio`; decorado `huevo`; camino `sendero`; pincel.
- **Composición de la tarjeta** (x, y, radio):

| Sticker | x | y | r |
|---|---|---|---|
| fondo completo | — | — | — |
| trex | 520 | 470 | 70 |
| spinosaurio | 700 | 500 | 60 |
| sendero | (1000,520)→(700,580)→(380,575) | | |
| trex bebiendo | 380 | 560 | 55 |
| huevo con brillo | 1120 | 540 | 40 |
| dino_bebe asomado | 1070 | 545 | 30 |

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: trex, n: 2}` | T-rex + ●● | "¡Pon dos T-rex en el pasto!" |
| 2 | `conectar {a: volcan, b: lago, camino: sendero}` | volcán ··· lago | "¡Haz un caminito del volcán al lago!" (al cumplirse, el T-rex lo recorre solo y bebe: R2) |
| 3 | `combinacion {resultado: dino_bebe}` | huevo + volcán = ✨ | "¡Lleva el huevo al volcán!" |

**Momento memorable**: el huevo tiembla, se raja y sale un dino bebé que hace un "¡grr!" chiquitito y
sigue al T-rex grande.

### 2.2 `pista_carreras` (favorito)

- **Inspiración**: "¡Una pista de carreras! Los autos salen de la partida, dan vueltas y vueltas…
  ¡fiuuum!… y el campeón se gana la copa."
- **Fondo base**:
  - cielo, montes y gradas (y 160-300);
  - pasto;
  - **partida** (lugar de fondo): rect cuadriculado (130, 490, 140, 60), con ancla (200, 520);
  - **meta**: sticker `bandera_meta` ya puesto en (1080, 500), r70.
- **Barra**: vivos `carrito` y `bus`; decorado `cono`; camino `camino` (carretera); pincel.
- **Composición**:
  - óvalo de carretera de centro (640, 500) y radios (440, 130);
  - carrito rojo (300, 420) r60 y bus azul (900, 590) r60;
  - conos en (520, 380) y (760, 380), r35;
  - **copa** brillando en (640, 250), r70;
  - bandera_meta (1080, 500).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: carrito, n: 2}` | auto + ●● | "¡Pon dos autos!" |
| 2 | `conectar {a: partida, b: bandera_meta, camino: camino}` | partida ··· meta | "¡Haz una calle de la partida a la meta!" |
| 3 | `circuito {viajero: carrito, vueltas: 2}` | auto en óvalo + ●● | "¡Ahora una pista redonda! Dibuja una vuelta grandota." |

**Momento memorable**: tras las 2 vueltas baja una **copa gigante**, llueve confeti a cuadros y el auto
toca bocina. **Secreto para Maxi**: si toca 3 veces el bus, sale Coco por la ventana saludando.

### 2.3 `bomberos`

- **Inspiración**: "¡Iuu-iuu! Hay un fueguito en la casa. El camión de bomberos sale del cuartel por la
  calle y lo apaga con su manguera. ¡Bien, bombero!"
- **Fondo base**:
  - cielo, sol, edificios 1-3 y plaza;
  - **cuartel** (sticker NUEVO `cuartel_bomberos`, lugar) ya puesto en (200, 470), r110;
  - **casa** ya puesta en (1060, 470), r110.
- **Barra**: decorado `fuego`; vivo `bomberos`; decorado `arbol`; camino `camino`; pincel.
- **Composición**:
  - cuartel y casa con fuego en el techo (1060, 390) r45;
  - calle (290,520)→(640,600)→(970,520);
  - camión (640, 590) r70;
  - chorro de agua celeste en arco de (700, 560) a (1040, 400);
  - humito (1080, 330).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: fuego, n: 1, en_zona: casa}` | fuego sobre casa | "¡Pon un fueguito en la casa!" (la casa pone cara de "¡uy, uy!") |
| 2 | `conectar {a: cuartel_bomberos, b: casa, camino: camino}` | cuartel ··· casa | "¡Haz la calle del cuartel a la casa!" |
| 3 | `combinacion {resultado: humito}` | camión + fuego = 💨 | "¡Pon el camión de bomberos!" (R2: sale solo, llega y apaga) |

**Momento memorable**: Maxi va en el camión con casco (mini sprite NUEVO `maxi_bombero`, opcional). La
manguera lanza un chorro, el fuego se apaga con un "fsss" y la casa sonríe y aplaude. Conecta con su
sueño de ser bombero.

### 2.4 `espacio`

- **Inspiración**: "¡3, 2, 1… despegue! El cohete sale de la base y vuela por las estrellas hasta un
  planeta lejano. Y si juntas tres estrellas… ¡aparece un dinosaurio en el cielo!"
- **Fondo base**:
  - espacio y estrellitas;
  - luna (180, 130) r55;
  - **planeta_lejano** (lugar de fondo): (1050, 220) r90;
  - suelo, con la **base** (lugar de fondo): plataforma (110, 575, 220, 50).
- **Barra**: vivo `cohete`; decorados `estrella` y `planeta`; camino `estelar`; pincel.
- **Composición**:
  - cohete (300, 480) r70 despegando con llamita;
  - ruta estelar (220,570)→(600,300)→(980,230);
  - estrellas en (560, 140), (640, 110) y (700, 170), unidas;
  - la **constelación T-rex** brillando: silueta (630, 150) r110;
  - planeta lejano.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: cohete, n: 1, en_zona: base}` | cohete sobre la base | "¡Pon el cohete en la base!" |
| 2 | `conectar {a: base, b: planeta_lejano, camino: estelar}` | base ··· planeta | "¡Dibuja el camino al planeta!" (cuenta regresiva "3, 2, 1… ¡despegue!") |
| 3 | `combinacion {resultado: constelacion_dino}` | ⭐⭐⭐ = dino | "¡Pon tres estrellas juntitas!" |

**Momento memorable**: las tres estrellas se unen con líneas y se dibuja un T-rex de estrellas que
ruge y saluda.

---

## 3. Escenas de Nicole (Brote): 6 objetivos, 3 visibles, zoom con lupa

Bolsa de 9-10 stickers y 2 caminos. Elige entre 2 tarjetas de inspiración (antes, del tema). Las
combinaciones le muestran los ingredientes (reto de hacer, no de adivinar). Se evita la palabra
"naranja/naranjo" en sus objetivos mientras siga abierta HE-94.

### 3.1 `granja_ponys` (ejemplo del PO)

- **Inspiración**: "En la granja, los ponys salen del establo y caminan por el sendero a tomar agüita al
  río. Y cuando llueve con sol… ¡sale un arcoíris!"
- **Fondo base**:
  - cielo 0-380 (sin sol: el sol es un ingrediente);
  - colinas (y 260-420) y pasto;
  - **río** (lugar de fondo lineal): banda sinuosa de 110 px de ancho, de (1280, 330) a (900, 720);
  - **granero** ya puesto en (240, 400), r110.
- **Bolsa**:
  - vivo: `pony_amigo`;
  - lugar: `granero`;
  - decorados: `arbol`, `flor`, `manzana`, `sol`, `nube`, `nube_lluvia` (NUEVO), `corazon`;
  - caminos: `sendero` y `cerca`.
- **Composición**:
  - graneros en (240, 400) y (500, 330) r80;
  - sendero (300,470)→(650,520)→(960,520);
  - pony rosa caminando (620, 510) y pony lila bebiendo (950, 500) con gotitas;
  - nube de lluvia (760, 120), sol (980, 110) y arcoíris (870, 190) r150;
  - corral de cerca (óvalo de centro (400, 610) y radios (150, 70)) con dos ponys dentro;
  - manzana junto a un pony (660, 560).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: pony_amigo, n: 2}` | pony + ●● | "¡Pon dos ponys en la granja!" |
| 2 | `conectar {a: granero, b: rio, camino: sendero}` | establo ··· río | "Haz un sendero desde el establo hasta el río." |
| 3 | `llegadas {viajero: pony_amigo, desde: granero, hasta: rio, n: 2}` | pony → río + ●● | "Que dos ponys vayan del establo a tomar agua al río." |
| 4 | `combinacion {resultado: arcoiris}` | sol + nube de lluvia = arcoíris | "Pon un sol y una nube de lluvia en el cielo… ¿qué aparecerá?" |
| 5 | `combinacion {resultado: pony_feliz}` | pony + manzana = corazón | "Ese pony tiene hambre: ¡dale una manzana!" |
| 6 | `encerrar {sticker: pony_amigo, n: 2, con: cerca}` | 2 ponys en óvalo de cerca | "Ya es de noche: haz un corral con la cerca alrededor de dos ponys." |

**Momento memorable**: el arcoíris aparece sobre el río y los ponys que beben levantan la cabeza y
hacen el corazón coreano con las patitas, el gesto de Nicole.

### 3.2 `safari_jirafas`

- **Inspiración**: "En la sabana, las jirafas comen hojitas de los árboles altos y después caminan a
  la charca a tomar agua. Al atardecer… el cielo se pone rosado."
- **Fondo base**:
  - **cielo** (pintable con balde) y montes;
  - pasto;
  - **charca** (lugar de fondo): elipse (980, 560), radios (190, 60).
- **Bolsa**:
  - vivo: `jirafa`;
  - lugar: `arbol` (acacia, `clase: lugar`);
  - decorados: `roca`, `flor`, `sol`, `nube`, `nube_lluvia`, `corazon`, `estrella`;
  - camino: `sendero`.
- **Composición**:
  - cielo rosado;
  - acacias en (220, 330) r110 y (420, 300) r100;
  - jirafa comiendo (300, 330) r90, con hojitas;
  - sendero (420,420)→(980,540);
  - jirafa (700, 480) y jirafa bebé (760, 500) r55;
  - charca y sol bajo (1100, 250).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: jirafa, n: 2}` | jirafa + ●● | "¡Pon dos jirafas en la sabana!" |
| 2 | `poner {sticker: arbol, n: 2}` | árbol + ●● | "Planta dos árboles altos." |
| 3 | `combinacion {resultado: jirafa_come}` | jirafa + árbol = hojitas | "Lleva una jirafa a un árbol para que coma hojitas." |
| 4 | `conectar {a: arbol, b: charca, camino: sendero}` | árbol ··· charca | "Haz un sendero del árbol a la charca." |
| 5 | `llegadas {viajero: jirafa, desde: arbol, hasta: charca, n: 2}` | jirafa → charca + ●● | "Que dos jirafas vayan a tomar agua." |
| 6 | `pintar_zona {zona: cielo, color: rosado}` | cielo + gota rosada | "¡Es el atardecer! Pinta el cielo de rosado." |

**Momento memorable**: al beber, la jirafa abre las patas delanteras de forma graciosa para alcanzar el
agua (dato real). Coco: "¡Las jirafas abren las patas para tomar agua!"

### 3.3 `castillo_princesas`

- **Inspiración**: "La princesa sale del castillo en su carroza, cruza el puente arcoíris y llega a la
  fuente de los deseos. Esta noche hay baile… ¡y fuegos artificiales!"
- **Fondo base**:
  - cielo, nubes, **colina** (izquierda, x 0-520) y **pradera**;
  - **fuente** (lugar de fondo NUEVO): círculo (1040, 520) r90, con chorrito.
- **Bolsa**:
  - vivos: `carroza` y `pony_amigo`;
  - lugar: `castillo`;
  - decorados: `corona`, `vestido`, `zapato`, `corazon`, `estrella`, `flor`, `arcoiris`;
  - caminos: `arcoiris` (puente) y `sendero`.
- **Composición**:
  - castillo (260, 330) r150 sobre la colina;
  - puente arcoíris (380,380)→(680,200)→(980,500), con la carroza en (680, 215);
  - pony con corona (520, 520);
  - flores en (740, 640), (800, 620) y (860, 640);
  - fuegos en forma de corazón (300, 110);
  - fuente.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: castillo, n: 1, en_zona: colina}` | castillo sobre colina | "Pon el castillo arriba de la colina." |
| 2 | `conectar {a: castillo, b: fuente, camino: arcoiris}` | castillo ··· fuente (arcoíris) | "Haz un puente arcoíris del castillo a la fuente." |
| 3 | `llegadas {viajero: carroza, desde: castillo, hasta: fuente, n: 1}` | carroza → fuente | "¡Que la carroza vaya a la fuente de los deseos!" |
| 4 | `combinacion {resultado: pony_princesa}` | pony + corona = pony con corona | "Ponle una corona a un pony." |
| 5 | `poner {sticker: flor, n: 3, en_zona: pradera}` | flor en pradera + ●●● | "Planta tres flores en la pradera para el baile." |
| 6 | `combinacion {resultado: fuegos_artificiales}` | estrella + castillo = fuegos | "Lleva una estrella al castillo… ¡y mira el cielo!" |

**Momento memorable**: el castillo lanza fuegos artificiales en forma de corazón y de pony. Al llegar,
la carroza tira una moneda a la fuente y suena "¡plin!" (deseo).

### 3.4 `fiesta_gatitos`

- **Inspiración**: "¡Es el cumpleaños de un gatito! Sus amigos llegan por el caminito de huellitas
  hasta la torta. Hay globos, guirnaldas de luces… ¡y velitas para soplar!"
- **Fondo base**:
  - pared, ventana, cuadro, piso y alfombra;
  - **puerta** (lugar de fondo NUEVO): rect (60, 250, 170, 310), con ancla (145, 520).
- **Bolsa**:
  - vivo: `gatito`;
  - lugar: `pastel`;
  - decorados: `ovillo`, `globo`, `regalo`, `corazon`, `estrella`, `flor`;
  - caminos: `huellitas` (NUEVO) y `guirnalda`.
- **Composición**:
  - puerta;
  - huellitas (230,540)→(700,560), con gatitos en (330, 540), (480, 560) y (620, 560);
  - pastel con velitas (820, 520) r90;
  - globos en (900, 220) y (1000, 250), unidos por guirnalda (880,230)→(1180,230);
  - ovillo (1050, 600) con gatito (1120, 590).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: gatito, n: 3}` | gatito + ●●● | "¡Invita a tres gatitos a la fiesta!" |
| 2 | `conectar {a: puerta, b: pastel, camino: huellitas}` | puerta ··· torta | "Haz un caminito de huellitas de la puerta a la torta." |
| 3 | `llegadas {viajero: gatito, desde: puerta, hasta: pastel, n: 2}` | gatito → torta + ●● | "Que dos gatitos entren por la puerta y lleguen a la torta." |
| 4 | `combinacion {resultado: ovillo_rodando}` | gatito + ovillo = ovillo rodando | "Dale un ovillo a un gatito para que juegue." |
| 5 | `conectar {a: globo, b: globo, camino: guirnalda}` | globo ~ globo | "Cuelga una guirnalda de luces entre dos globos." |
| 6 | `combinacion {resultado: velitas}` | estrella + torta = velitas | "Pon una estrella en la torta… ¡y a soplar!" |

**Momento memorable**: se encienden las velitas, todos los gatitos saltan y Coco canta el "cumpleaños
feliz" en maullidos. Nicole sopla tocando la torta.

### 3.5 `escenario_pop`

- **Inspiración**: "¡Concierto de las cantantes estrella! Salen del camarín, caminan por la alfombra
  hasta el escenario y cantan con sus micrófonos. Al final… ¡hacen un corazón con los dedos!"
- **Fondo base**:
  - fondo y telones;
  - **escenario** (lugar de fondo) y borde;
  - **camarín** (sticker NUEVO `camarin`, lugar) ya puesto en (130, 420), r100.
- **Bolsa**:
  - vivo: `cantante` (NUEVO, idol genérica sin copiar IP);
  - decorados: `microfono`, `nota`, `foco`, `corazon`, `estrella`, `corona`, `globo`, `vestido`;
  - caminos: `alfombra` (NUEVO) y `guirnalda`.
- **Composición**:
  - camarín;
  - alfombra (230,500)→(560,520);
  - 3 cantantes en el escenario en (640, 440), (780, 430) y (920, 440), con micrófonos;
  - focos en (600, 120), (800, 100) y (1000, 120), unidos por guirnalda;
  - notas y corazones flotando.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: foco, n: 3}` | foco + ●●● | "¡Pon tres focos para el concierto!" |
| 2 | `conectar {a: camarin, b: escenario, camino: alfombra}` | camarín ··· escenario | "Pon una alfombra del camarín al escenario." |
| 3 | `llegadas {viajero: cantante, desde: camarin, hasta: escenario, n: 3}` | cantante → escenario + ●●● | "¡Que las tres cantantes suban al escenario!" |
| 4 | `combinacion {resultado: canta}` | cantante + micrófono = notas | "Dale un micrófono a una cantante." |
| 5 | `conectar {a: foco, b: foco, camino: guirnalda}` | foco ~ foco | "Une dos focos con una guirnalda de luces." |
| 6 | `combinacion {resultado: corazon_coreano}` | cantante + corazón = 🫰 | "Lleva un corazón a una cantante… ¿qué hará?" |

**Momento memorable**: las cantantes hacen el corazón coreano, el gesto de celebración real de Nicole,
y cae una lluvia de corazones rosados.

---

## 4. Escenas de Sofía (Estrella): 12 objetivos variados, 3 visibles, zoom

Bolsa de 13-15 stickers, 2 caminos y edición completa. Elige entre 3 tarjetas. En sus combinaciones
solo ve **la silueta del resultado y un acertijo por voz** (Little Alchemy puro); los ingredientes se
revelan con las pistas (§8). Cada hoja usa entre 7 y 9 tipos distintos y ninguno más de 3 veces.

### 4.1 `ciudad_ponys`

- **Inspiración**: "En la Ciudad de los Ponys, cada pony vive en su casita. Por la mañana van por el
  sendero a la escuela del castillo, y después al establo y a tomar agua al río. Si llueve con sol, sale
  un arcoíris… ¡y dicen que una varita convierte a un pony en unicornio!"
- **Fondo base**:
  - cielo (se quitan los arcos de fondo de hoy: el arcoíris se gana);
  - colinas y pradera;
  - **río** (lugar de fondo lineal): banda de (0, 560) a (1280, 600), de 90 px de ancho, turquesa
    pálido.
- **Bolsa**:
  - vivos: `pony_amigo` y `unicornio`;
  - lugares: `casa`, `castillo` y `granero`;
  - decorados: `arbol`, `flor`, `manzana`, `nube`, `sol`, `varita`, `corazon`, `estrella`, `globo`;
  - caminos: `sendero` y `arcoiris`.
- **Composición**:
  - casitas en (180, 300), (300, 260) y (420, 300), r65;
  - castillo-escuela (980, 260) r130;
  - sendero (420,320)→(860,300), con dos ponys;
  - granero (640, 430) r80, con sendero a (640, 560);
  - pony bebiendo;
  - arcoíris sobre el río (900, 470) r180;
  - nube de lluvia (780, 140) y sol (1080, 120);
  - unicornio dando vueltas en un óvalo de puente arcoíris (centro (1120, 430), radios (110, 60)).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: casa, n: 3}` | casa + ●●● | "Arma el barrio: pon tres casitas." |
| 2 | `poner {sticker: pony_amigo, n: 3}` | pony + ●●● | "Ahora, tres ponys vecinos." |
| 3 | `conectar {a: casa, b: castillo, camino: sendero}` | casa ··· castillo | "Haz el sendero de las casas a la escuela del castillo." |
| 4 | `llegadas {viajero: pony_amigo, desde: casa, hasta: castillo, n: 2}` | pony → castillo + ●● | "Que dos ponys vayan de su casa a la escuela." |
| 5 | `conectar {a: granero, b: rio, camino: sendero}` | establo ··· río | "Conecta el establo con el río." |
| 6 | `llegadas {viajero: pony_amigo, desde: granero, hasta: rio, n: 2}` | pony → río + ●● | "Que dos ponys vayan del establo a tomar agua al río." |
| 7 | `combinacion {resultado: nube_lluvia}` | ? + ? = silueta de nube de lluvia | "Acertijo: ¿cómo se hace una nube de lluvia? Pista: hay que juntar nubes." |
| 8 | `combinacion {resultado: arcoiris}` | ? + ? = silueta de arcoíris | "¿Qué hace falta para que salga un arcoíris en el cielo?" |
| 9 | `combinacion {resultado: unicornio}` | ? + ? = silueta de unicornio | "Dicen que hay magia para convertir un pony en unicornio…" |
| 10 | `circuito {viajero: unicornio, vueltas: 2}` | unicornio en óvalo + ●● | "Que un unicornio dé dos vueltas por un camino redondo." |
| 11 | `pintar_zona {zona: rio, color: turquesa}` | río + gota turquesa | "Pinta el río de turquesa, como agua mágica." |
| 12 | `orden {viajero: pony_amigo, lugares: [casa, castillo, rio]}` | pony: casa → castillo → río | "El gran paseo: que un pony vaya de su casa a la escuela y después al río, sin parar." |

**Momento memorable**: la cadena nube + nube → nube de lluvia, y nube de lluvia + sol → arcoíris.
Cuando un unicornio pasa bajo el arcoíris, deja una estela de destellos.

### 4.2 `escuela_magia`

- **Inspiración**: "En la Escuela de Magia, las lechuzas llevan cartas desde el castillo hasta el lago,
  y los aprendices vuelan en escoba alrededor de las torres. En el caldero burbujean pociones… y los
  libros, con la varita, ¡salen volando!"
- **Fondo base**:
  - cielo de noche, luna y estrellitas;
  - **colinas**;
  - **lago** (lugar de fondo): elipse (950, 600), radios (260, 70).
- **Bolsa**:
  - vivos: `lechuza`, `escoba` y `gatito`;
  - lugares: `castillo` y `caldero`;
  - decorados: `sombrero_mago`, `varita`, `libro`, `flor`, `luna`, `estrella`, `destello`, `nube`,
    `arbol`;
  - caminos: `destellos` y `sendero`.
- **Composición**:
  - castillo (360, 330) r150 en las colinas;
  - óvalo de destellos alrededor del castillo (radios 210 × 170), con escoba en (560, 250);
  - estela de destellos (480,380)→(900,560), con 3 lechuzas;
  - caldero rosa burbujeando (720, 600) r60;
  - libro volando (1000, 300);
  - gatito con sombrero de mago (140, 600);
  - lago violeta.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: castillo, n: 1, en_zona: colinas}` | castillo en colinas | "Levanta la escuela: pon el castillo en las colinas." |
| 2 | `poner {sticker: lechuza, n: 3}` | lechuza + ●●● | "Tres lechuzas mensajeras, por favor." |
| 3 | `conectar {a: castillo, b: lago, camino: destellos}` | castillo ··· lago (destellos) | "Traza una estela de destellos del castillo al lago." |
| 4 | `llegadas {viajero: lechuza, desde: castillo, hasta: lago, n: 3}` | lechuza → lago + ●●● | "Que las tres lechuzas lleven cartas al lago." |
| 5 | `encerrar {sticker: castillo, n: 1, con: destellos}` | castillo dentro de óvalo de destellos | "Dibuja una ruta de vuelo que rodee todo el castillo." |
| 6 | `circuito {viajero: escoba, vueltas: 3}` | escoba en óvalo + ●●● | "Que una escoba dé tres vueltas volando." |
| 7 | `combinacion {resultado: pocion_rosa}` | ? + ? = silueta de poción | "Clase de pociones: ¿qué echas al caldero para una poción rosada?" |
| 8 | `combinacion {resultado: libro_volador}` | ? + ? = silueta de libro con alas | "Hechizo: haz que un libro salga volando." |
| 9 | `combinacion {resultado: gatito_mago}` | ? + ? = silueta de gatito con sombrero | "Hasta el gatito quiere ser mago… ¿cómo lo ayudas?" |
| 10 | `pintar_zona {zona: lago, color: violeta}` | lago + gota violeta | "Pinta el lago encantado de violeta." |
| 11 | `colores {n: 7}` | paleta con 7 gotas | "Usa siete colores en tu escuela." |
| 12 | `llegadas {viajero: libro_volador, desde: lago, hasta: castillo, n: 1}` | libro volador → castillo | "Que el libro volador vuelva del lago a la biblioteca del castillo." |

**Momento memorable**: el libro volador (resultado del 8) se vuelve viajero y vuela por la estela de
regreso. Que lo descubierto sirva para el siguiente objetivo es el "¡ah!" tipo Little Alchemy. Además,
los objetivos 5 y 6 se pueden cumplir con un mismo trazo.

### 4.3 `concierto_pop`

- **Inspiración**: "¡Esta noche hay concierto! Las cantantes salen del camarín por la alfombra, los
  focos se encienden, la líder se pone su corona y el público agita corazones. Al final… ¡bailan las
  tres juntas!"
- **Fondo base**:
  - fondo, `telon_izq` y `telon_der`;
  - **escenario** (lugar de fondo) y borde;
  - **techo** (región NUEVA, franja y 0-120);
  - **platea** (región NUEVA, franja y 610-720);
  - `camarin` ya puesto en (110, 380), r100.
- **Bolsa**:
  - vivo: `cantante`;
  - decorados: `microfono`, `nota`, `foco`, `parlante`, `corona`, `vestido`, `zapato`, `corazon`,
    `estrella`, `destello`, `globo`, `luna`;
  - caminos: `alfombra` y `guirnalda`.
- **Composición**:
  - camarín y alfombra (210,470)→(560,500);
  - 3 cantantes en el escenario, la del centro con corona;
  - 4 focos en el techo, cada uno unido por guirnalda a un parlante (300, 420) y (1000, 420);
  - notas en onda saliendo de un parlante;
  - escenario turquesa y telones rosados;
  - 5 corazones en la platea.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: cantante, n: 3}` | cantante + ●●● | "Forma tu grupo: tres cantantes." |
| 2 | `conectar {a: camarin, b: escenario, camino: alfombra}` | camarín ··· escenario | "Pon la alfombra del camarín al escenario." |
| 3 | `llegadas {viajero: cantante, desde: camarin, hasta: escenario, n: 3}` | cantante → escenario + ●●● | "¡Que las tres salgan al escenario!" |
| 4 | `poner {sticker: foco, n: 4, en_zona: techo}` | foco en el techo + ●●●● | "Cuelga cuatro focos en el techo." |
| 5 | `conectar {a: foco, b: parlante, camino: guirnalda}` | foco ~ parlante | "Conecta un foco a un parlante con un cable de luces." |
| 6 | `combinacion {resultado: canta}` | ? + ? = silueta de notas | "¿Qué necesita una cantante para que se escuche?" |
| 7 | `combinacion {resultado: ola_de_notas}` | ? + ? = silueta de onda de notas | "Haz que la música salga fuerte por los parlantes." |
| 8 | `combinacion {resultado: cantante_lider}` | ? + ? = silueta de cantante con corona | "Toda banda tiene una líder… ¿cómo la reconoces?" |
| 9 | `pintar_zona {zona: escenario, color: turquesa}` | escenario + gota turquesa | "Pinta el escenario de turquesa." |
| 10 | `pintar_zona {zona: [telon_izq, telon_der], color: rosa}` | telones + gota rosa | "Y los telones, de rosa." |
| 11 | `poner {sticker: corazon, n: 5, en_zona: platea}` | corazón en la platea + ●●●●● | "El público agita cinco corazones." |
| 12 | `combinacion {resultado: coreografia}` | ? + ? + ? = silueta de 3 bailarinas | "El gran final: ¿qué pasa si juntas a las tres cantantes?" |

**Momento memorable**: las tres cantantes bailan una coreografía de 4 s y terminan en la pose de
celebración de Sofía (mano en la cintura, signo de la paz y guiño). Los colores son los de Sofía (rosa
y turquesa) y la líder lleva corona, que es su rol.

### 4.4 `tren_chile` (contenido educativo de Chile)

- **Inspiración**: "El tren recorre Chile de norte a sur: sale del desierto de Atacama, para en
  Valparaíso, pasa junto al volcán Osorno y las Torres del Paine, y llega hasta los pingüinos de la
  Patagonia. Y en barco, lejos en el mar… ¡Rapa Nui!"
- **Fondo base**:
  - cielo y cordillera (franja superior);
  - valle;
  - **desierto** (región NUEVA, x 0-380, color arena) y **bosque_sur** (región NUEVA, x 900-1280);
  - **mar** (lugar de fondo lineal, y 610-720), con una **isla** (región NUEVA) en (420, 670) r50;
  - rosa de los vientos pictográfica arriba al centro: sol fuerte a la izquierda (norte) y copo a la
    derecha (sur).
- **Orientación**: Chile "acostado". El norte queda a la izquierda y el sur a la derecha; Coco lo dice
  en la inspiración.
- **Bolsa**:
  - vivos: `tren` y `barco` (NUEVO);
  - lugares: `cactus` (Atacama), `casa_valpo`, `volcan` (Osorno), `montana` (Torres del Paine),
    `pinguino` (Patagonia) y `moai`;
  - decorados: `copihue`, `bandera_chile`, `nube`, `sol`, `arbol`, `palmera`, `estrella`;
  - caminos: `rieles` y `ruta_mar` (NUEVO, punteado con olitas).
- **Composición**:
  - cactus (120, 380), casa_valpo (360, 400), volcán nevado (640, 330), montaña (900, 320) y pingüino
    (1150, 420), r70-90;
  - rieles ondulados de lugar en lugar a lo largo de y ≈ 470, con el tren en (500, 470);
  - copihues en (960, 550), (1000, 520) y (1050, 540);
  - moái en la isla;
  - ruta marítima (360,450)→(420,640), con el barco en (400, 560);
  - bandera (250, 250);
  - el tren con banderitas.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: bandera_chile, n: 1}` | bandera + ● | "Empieza el viaje: pon la bandera de Chile." |
| 2 | `conectar {a: cactus, b: casa_valpo, camino: rieles}` | cactus ··· Valparaíso | "Pon rieles del desierto de Atacama a Valparaíso." |
| 3 | `llegadas {viajero: tren, desde: cactus, hasta: casa_valpo, n: 1}` | tren → Valparaíso | "¡Que el tren llegue a Valparaíso!" |
| 4 | `combinacion {resultado: volcan_nevado}` | ? + ? = silueta de volcán nevado | "El volcán Osorno tiene la cumbre blanca. ¿Cómo le pones nieve?" |
| 5 | `conectar {a: casa_valpo, b: volcan, camino: rieles}` | Valparaíso ··· volcán | "Sigue los rieles hasta el volcán Osorno." |
| 6 | `poner {sticker: copihue, n: 3, en_zona: bosque_sur}` | copihue en el bosque del sur + ●●● | "Planta tres copihues, la flor nacional, en el bosque del sur." |
| 7 | `conectar {a: volcan, b: montana, camino: rieles}` | volcán ··· Torres | "Más al sur: rieles hasta las Torres del Paine." |
| 8 | `conectar {a: montana, b: pinguino, camino: rieles}` | Torres ··· pingüino | "Y el final del viaje: hasta los pingüinos de la Patagonia." |
| 9 | `orden {viajero: tren, lugares: [cactus, casa_valpo, volcan, montana, pinguino]}` | tren: 5 lugares en fila | "El gran viaje: que el tren recorra Chile entero, de norte a sur, sin saltarse ninguna parada." |
| 10 | `conectar {a: casa_valpo, b: moai, camino: ruta_mar}` | Valparaíso ··· moái (olitas) | "Rapa Nui está en medio del mar: traza una ruta de barco desde Valparaíso." |
| 11 | `llegadas {viajero: barco, desde: casa_valpo, hasta: moai, n: 1}` | barco → moái | "¡Que el barco llegue a Rapa Nui!" |
| 12 | `combinacion {resultado: tren_fiestas}` | ? + ? = silueta de tren con banderitas | "Para celebrar, el tren se viste de fiesta… ¿qué le falta?" |

**Datos al llegar** (`nombrar_estaciones`, ya existe; líneas nuevas o revisadas):
- Atacama: "el desierto más seco del mundo".
- Valparaíso: "casas de colores en los cerros, con ascensores".
- Osorno: "un volcán con forma de cono perfecto".
- Torres del Paine: "tres torres de roca gigantes".
- Patagonia: "aquí viven pingüinos de verdad".
- Rapa Nui: "a más de 3.500 km de la costa; los moáis miran hacia la isla".

**Momento memorable**: con el `orden` cumplido, el tren hace el viaje completo tocando el pito en cada
parada mientras Coco nombra los lugares. Al ponerle la bandera, suena una cueca corta (SFX CC0 o
sintetizado) y Coco zapatea.

### 4.5 `parque_mascotas`

- **Inspiración**: "En el parque de mascotas, los perritos salen de sus casitas y corren al bebedero,
  los gatitos juegan con ovillos, los gerbos corren en círculos… y cuando todos se juntan, ¡hacen una
  ronda!"
- **Fondo base**:
  - cielo, sol, nube y **muro** (pintable);
  - pasto;
  - **bebedero** (lugar de fondo NUEVO): (1050, 560) r70.
- **Bolsa**:
  - vivos: `perrito`, `gatito` y `gerbo`;
  - lugar: `casa` (casita);
  - decorados: `hueso`, `pelota`, `ovillo`, `arbol`, `flor`, `corazon`, `regalo`, `manzana`, `nube`;
  - caminos: `sendero` y `cerca`.
- **Composición**:
  - casitas en (200, 420) y (380, 380) r75;
  - sendero hasta el bebedero, con 3 perritos;
  - perrito con hueso y corazón (600, 600);
  - gatito y ovillo rodando (760, 470);
  - gerbos en un óvalo de sendero (centro (880, 300), radios (110, 60));
  - corral de cerca con 2 cachorros (300, 610);
  - muro turquesa;
  - ronda de perrito, gatito y gerbo con corazones (1100, 380).

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: perrito, n: 3}` | perrito + ●●● | "Llegan los cachorros: pon tres perritos." |
| 2 | `poner {sticker: casa, n: 2}` | casita + ●● | "Cada perrito necesita casa: pon dos casitas." |
| 3 | `conectar {a: casa, b: bebedero, camino: sendero}` | casita ··· bebedero | "Haz un sendero de las casitas al bebedero." |
| 4 | `llegadas {viajero: perrito, desde: casa, hasta: bebedero, n: 3}` | perrito → bebedero + ●●● | "Que los tres perritos vayan a tomar agua." |
| 5 | `combinacion {resultado: perrito_feliz}` | ? + ? = silueta de perrito con corazón | "¿Qué hace mover la cola a un perrito?" |
| 6 | `combinacion {resultado: ovillo_rodando}` | ? + ? = silueta de ovillo rodando | "¿Con qué juega un gatito?" |
| 7 | `circuito {viajero: gerbo, vueltas: 3}` | gerbo en óvalo + ●●● | "Los gerbos aman correr en círculos: tres vueltas." |
| 8 | `encerrar {sticker: perrito, n: 2, con: cerca}` | 2 perritos en óvalo de cerca | "Haz un corral con cerca para dos cachorros." |
| 9 | `combinacion {resultado: juega_pelota}` | ? + ? = silueta de perrito persiguiendo una pelota | "¡A jugar a buscar!" |
| 10 | `pintar_zona {zona: muro, color: turquesa}` | muro + gota turquesa | "Pinta el muro del parque de turquesa." |
| 11 | `colores {n: 6}` | paleta con 6 gotas | "Usa seis colores en tu parque." |
| 12 | `combinacion {resultado: amigos}` | ? + ? + ? = silueta de ronda | "El final: ¿qué pasa si juntas a un perrito, un gatito y un gerbo?" |

**Momento memorable**: perrito, gatito y gerbo hacen una ronda con corazones (son los animales
favoritos de Sofía; los gerbos son su gusto más propio).

### 4.6 `mision_espacial`

- **Inspiración**: "Misión espacial: el cohete despega de la base, viaja a la Luna, sigue hasta un
  planeta lejano y vuelve a casa. En el camino ve una estrella fugaz… ¡y hasta un eclipse!"
- **Fondo base**:
  - espacio (región **cielo**) y estrellitas;
  - **luna** (lugar de fondo): (200, 140) r70;
  - **planeta_lejano** (lugar de fondo): (1050, 220) r90;
  - suelo, con la **base** (lugar de fondo): (110, 575, 220, 50).
- **Bolsa**:
  - vivo: `cohete`;
  - lugares: `planeta` y `volcan` (un volcán en otro planeta);
  - decorados: `estrella`, `destello`, `sol`, `roca`, `bandera_chile`, `corazon`, `luna`;
  - camino: `estelar`.
- **Composición**:
  - base con cohete;
  - ruta estelar base → luna → planeta lejano → base (triángulo curvo);
  - bandera de Chile en la luna;
  - planeta lejano violeta con una órbita estelar a su alrededor;
  - estrella fugaz cruzando (600, 120);
  - sol medio tapado por la luna (eclipse) en una esquina;
  - 5 estrellas.

| # | Tipo y parámetros | Pictograma | Voz |
|---|---|---|---|
| 1 | `poner {sticker: planeta, n: 2}` | planeta + ●● | "Llena tu galaxia: pon dos planetas." |
| 2 | `conectar {a: base, b: luna, camino: estelar}` | base ··· luna | "Traza la ruta de la base a la Luna." |
| 3 | `llegadas {viajero: cohete, desde: base, hasta: luna, n: 1}` | cohete → luna | "¡Despegue! Que el cohete llegue a la Luna." |
| 4 | `combinacion {resultado: bandera_luna}` | ? + ? = silueta de bandera en la luna | "Al llegar, los astronautas dejan una bandera… ¿qué bandera dejarás?" |
| 5 | `encerrar {sticker: planeta, n: 1, con: estelar}` | planeta dentro de un óvalo estelar | "Haz una órbita: una ruta que dé la vuelta completa a un planeta." |
| 6 | `combinacion {resultado: estrella_fugaz}` | ? + ? = silueta de estrella fugaz | "¿Cómo se hace una estrella fugaz?" |
| 7 | `combinacion {resultado: eclipse}` | ? + ? = silueta de eclipse | "Un eclipse pasa cuando la Luna tapa al Sol… ¿te atreves?" |
| 8 | `orden {viajero: cohete, lugares: [base, luna, planeta_lejano]}` | cohete: base → luna → planeta | "Misión larga: de la base a la Luna y de ahí al planeta lejano, sin parar." |
| 9 | `poner {sticker: estrella, n: 5, en_zona: cielo}` | estrella + ●●●●● | "Pon cinco estrellas para guiar el viaje." |
| 10 | `pintar_zona {zona: planeta_lejano, color: violeta}` | planeta + gota violeta | "Pinta el planeta lejano de violeta." |
| 11 | `colores {n: 6}` | paleta con 6 gotas | "Usa seis colores en tu misión." |
| 12 | `llegadas {viajero: cohete, desde: planeta_lejano, hasta: base, n: 1}` | cohete → base | "Misión cumplida: ¡que el cohete vuelva a casa!" |

**Momento memorable**: el eclipse oscurece la pantalla 3 s, aparecen todas las estrellitas y Coco
cuenta el dato ("¡en un eclipse de día se ven las estrellas!"). Al aterrizar suena un "misión cumplida"
con confeti.

---

## 5. Tabla de combinaciones mágicas

Leyenda:
- **Consume**: los ingredientes desaparecen y queda el resultado.
- **Transforma**: el primer ingrediente se convierte en el resultado.
- **Efecto**: los ingredientes se quedan y pasa una animación.

| Id | Ingredientes | Dónde | Tipo | Resultado (clase) | Escenas | Voz de Coco |
|---|---|---|---|---|---|---|
| C01 | `sol` + `nube_lluvia` | en `cielo` | Efecto + sticker | `arcoiris` (decorado) | granja_ponys, ciudad_ponys y cualquiera | "¡Sol con lluvia… arcoíris!" |
| C02 | `nube` + `nube` | — | Consume | `nube_lluvia` (decorado) | ciudad_ponys y cualquiera | "¡Dos nubes hacen una nube de lluvia!" |
| C03 | `huevo` + `volcan` | — | Transforma (huevo) | `dino_bebe` (vivo) | parque_dinos | "¡Crac! ¡Nació un dino bebé!" |
| C04 | `bomberos` + `fuego` | — (también al llegar) | Consume (fuego) | `humito` (efecto) | bomberos | "¡Fuego apagado! ¡Bien, bombero!" |
| C05 | `nube_lluvia` + `fuego` | — | Consume (fuego) | `humito` (efecto) | bomberos y cualquiera | "¡La lluvia apagó el fuego!" |
| C06 | `estrella` ×3 | en `cielo` | Efecto | `constelacion_dino` (efecto) | espacio | "¡Un dinosaurio de estrellas!" |
| C07 | `pony_amigo` + `manzana` | — | Consume (manzana) | `pony_feliz` (efecto: corazón) | granja_ponys y ciudad_ponys | "¡Ñam! ¡Al pony le encantó!" |
| C08 | `jirafa` + `arbol` | — | Efecto | `jirafa_come` (efecto: hojitas) | safari_jirafas | "¡Qué ricas hojitas!" |
| C09 | `pony_amigo` + `corona` | — | Transforma (pony) | `pony_princesa` (vivo) | castillo_princesas | "¡Un pony princesa!" |
| C10 | `estrella` + `castillo` | — | Efecto | `fuegos_artificiales` (efecto) | castillo_princesas | "¡Fuegos artificiales!" |
| C11 | `gatito` + `ovillo` | — | Efecto | `ovillo_rodando` (efecto) | fiesta_gatitos y parque_mascotas | "¡A jugar con el ovillo!" |
| C12 | `estrella` + `pastel` | — | Transforma (pastel) | `velitas` (pastel con velas encendidas) | fiesta_gatitos | "¡Velitas! ¡Cumpleaños feliz!" |
| C13 | `cantante` + `microfono` | — | Consume (micrófono) | `canta` (la cantante queda con micrófono; notas) | escenario_pop y concierto_pop | "¡Qué linda voz!" |
| C14 | `cantante` + `corazon` | — | Efecto | `corazon_coreano` (efecto) | escenario_pop | "¡Corazoncito!" |
| C15 | `pony_amigo` + `varita` | — | Transforma (pony) | `unicornio` (vivo) | ciudad_ponys | "¡Magia! ¡Ahora es un unicornio!" |
| C16 | `caldero` + `flor` | — | Consume (flor) | `pocion_rosa` (caldero burbujeando rosa) | escuela_magia | "¡Poción de flores!" |
| C17 | `varita` + `libro` | — | Transforma (libro) | `libro_volador` (vivo volador) | escuela_magia | "¡El libro está volando!" |
| C18 | `gatito` + `sombrero_mago` | — | Consume (sombrero) | `gatito_mago` (vivo) | escuela_magia | "¡Un gatito mago, miau-gia!" |
| C19 | `parlante` + `nota` | — | Efecto | `ola_de_notas` (efecto) | concierto_pop | "¡Súbele a la música!" |
| C20 | `cantante` + `corona` | — | Consume (corona) | `cantante_lider` (vivo) | concierto_pop | "¡La líder del grupo!" |
| C21 | `cantante` ×3 | en `escenario` | Efecto | `coreografia` (efecto, 4 s) | concierto_pop | "¡Cinco, seis, siete, ocho!" |
| C22 | `volcan` + `nube` | — | Transforma (volcán) | `volcan_nevado` (lugar) | tren_chile | "¡Nieve en la cumbre, como el Osorno!" |
| C23 | `tren` + `bandera_chile` | — | Consume (bandera) | `tren_fiestas` (vivo con banderitas) | tren_chile | "¡El tren se puso de fiesta!" |
| C24 | `perrito` + `hueso` | — | Consume (hueso) | `perrito_feliz` (efecto: cola y corazón) | parque_mascotas | "¡Mueve la colita!" |
| C25 | `perrito` + `pelota` | — | Efecto | `juega_pelota` (la pelota sale volando y el perrito la trae) | parque_mascotas | "¡Ve a buscarla!" |
| C26 | `perrito` + `gatito` + `gerbo` | — | Efecto | `amigos` (ronda con corazones) | parque_mascotas | "¡Todos son amigos!" |
| C27 | `bandera_chile` + `luna` (fondo o sticker) | — | Consume (bandera) | `bandera_luna` (efecto: bandera clavada en la luna) | mision_espacial | "¡Chile llegó a la Luna!" |
| C28 | `estrella` + `destello` | — | Consume | `estrella_fugaz` (efecto: cruza la pantalla) | mision_espacial | "¡Pide un deseo!" |
| C29 | `sol` + `luna` | — | Efecto | `eclipse` (pantalla oscura 3 s) | mision_espacial | "¡Un eclipse! Se ven las estrellas de día." |
| C30 | `nube_lluvia` + `flor` | — | Efecto | `jardin` (brotan 2 flores más) | cualquiera con flores (secreto) | "¡La lluvia hizo crecer flores!" |
| C31 | `carrito` + `bandera_meta` | — | Efecto | `copa` (decorado) | pista_carreras (secreto de Maxi) | "¡Campeón!" |
| C32 | `trex` + `volcan` | — | Efecto | `rugido` (el volcán echa humo y el T-rex ruge) | parque_dinos (secreto de Maxi) | "¡ROAAAR!" |

**Cadenas** (lo que hace Little Alchemy de verdad):
- nube + nube → nube de lluvia → + sol → arcoíris (C02 → C01).
- nube de lluvia + flor → jardín (C02 → C30).
- varita + libro → libro volador → viajero de `llegadas` (C17 → objetivo 12 de escuela_magia).

---

## 6. Pistas: qué muestra Coco y cuándo

### 6.1 Qué cuenta como "sin avance"

- **Maxi**: el reloj solo se reinicia cuando progresa el objetivo activo. Tocar sin rumbo no lo
  reinicia.
- **Nicole**: el reloj se reinicia cuando progresa cualquier objetivo visible, y se pausa 10 s después
  de cualquier toque.
- **Sofía**: el reloj se reinicia con **cualquier** interacción (puede estar creando a gusto y no hay que
  interrumpirla). Además, **tocar a Coco o a Cometa da la pista siguiente al instante**.

### 6.2 Escalera por hermano

| Nivel | Maxi | Nicole | Sofía |
|---|---|---|---|
| 1 · Voz + la tarjeta del objetivo late | 8 s | 20 s | 45 s |
| 2 · Lo necesario brilla (sticker en la barra o bolsa, lugar o región) | junto con el nivel 1 | 35 s | 75 s |
| 3 · **Mano fantasma** que lo hace en el aire, semitransparente | 15 s | 50 s | 105 s |
| Repetición | cada 12 s | cada 30 s | solo a pedido (tocar a Coco) |

### 6.3 Qué hace la mano fantasma por tipo

| Tipo | Pista |
|---|---|
| `poner` | La bolsa o el botón de la barra late. La mano arrastra el sticker hasta un lugar libre (dentro de `en_zona` si la hay) |
| `conectar` | Si falta `a` o `b`, primero muestra la pista de `poner` del que falta. Después, la mano traza un camino punteado entre los dos y los lugares saltan |
| `llegadas` | La mano lleva un vivo hasta el lugar `desde`. Si no hay camino, primero muestra la pista de `conectar` |
| `circuito` | La mano dibuja un óvalo grande y el vivo lo sigue en fantasma |
| `encerrar` | La mano dibuja un óvalo alrededor del sticker o de los stickers |
| `combinacion` | Maxi y Nicole: la mano lleva el ingrediente A sobre el B. Sofía: nivel 1, el acertijo otra vez; nivel 2, se revela un ingrediente en la tarjeta (? → icono); nivel 3, se revelan los dos y la mano los junta |
| `pintar_zona` | La región parpadea y la gota del color salta en la paleta. En la zona 3 de Sofía, salta el platito de mezcla con los dos primarios |
| `colores` | Late una gota de la paleta todavía no usada |
| `orden` | Los lugares se encienden en secuencia con un "tin-tin-tin". Si falta un tramo, pista de `conectar` en ese tramo |
| `usar` | La herramienta late y la mano hace un trazo corto |
| `parte_encargo`, `encargo` | La región o las celdas sin terminar parpadean. En los pedidos de Coco, burbuja con la gota (comportamiento actual de la zona 3) |
| `adivinar` | Coco agranda el detalle más característico (la estrella de Chile, el círculo de Japón) |
| `trazo_unico` | Muestra una fila de celdas del mismo color iluminadas en línea |

### 6.4 Válvula de Semilla (GDD §5: imposible trabarse)

Tras la 3.ª mano fantasma en un mismo objetivo, el siguiente toque de Maxi **en cualquier parte**
completa el paso con la animación de la mano, y se celebra igual. Nicole y Sofía **no** tienen esta
válvula (reto real), pero la mano fantasma siempre muestra cómo hacerlo, así que nunca quedan trabadas.

---

## 7. Objetivos de las zonas 2-5 por hermano

### 7.1 Cuándo se cumple cada encargo (`encargo`)

| Encargo | Se cumple cuando… |
|---|---|
| `sellos_escena` (Maxi z2) | 3 sellos de dino estampados (dispara el desfile que ya existe) |
| `pinta_coco` (Maxi z3) | Todas las regiones de la lámina tocadas una vez (ya existe: "lámina completa") |
| `dedo_magico` (Maxi z4) | Un solo trazo cruza las 3 franjas de altura (arriba, medio, abajo; 240 px cada una): es el "tobogán musical" |
| `decora_ala` (Maxi z5) | Las regiones **grandes** tocadas: `nave`, `borde`, `franja_1-4`. Se excluyen las `estrellitas_*` (muy chicas para Maxi) |
| `colorear_zonas` (Nicole z2) | Lámina completa |
| `coco_pide` (Nicole z3) | Los 5 pedidos cumplidos |
| `espejo` (Nicole z4) | Cobertura de la guía ≥ 60 % |
| `decora_ala` (Nicole z5, etapa 1) | Lámina completa |
| `viste_coco` (Nicole z5, etapa 2) | Todas las regiones del traje elegido tocadas |
| `colorear_codigo` (Sofía z2) | Mosaico completo y correcto |
| `mezcla_paleta` (Sofía z3) | Lámina completa (los pedidos van aparte) |
| `mandala` (Sofía z4) | Cobertura de la guía ≥ 75 % |
| `decora_ala` (Sofía z5) | Lámina completa, estrellitas incluidas (con zoom) |

### 7.2 Maxi (3 por hoja, 1 a la vez)

| Estación | # | Tipo y parámetros | Voz |
|---|---|---|---|
| **Z2 · pradera** | 1 | `encargo` (3 dinos) | "¡Estampa tres dinos!" |
| | 2 | `poner {sticker: sello_auto, n: 2, en_zona: camino}` | "¡Pon dos autos en el camino!" |
| | 3 | `poner {sticker: sello_estrella, n: 3, en_zona: cielo}` | "¡Tres estrellas en el cielo!" |
| **Z2 · valle_dinos** | 1 | `encargo` (3 dinos) | "¡Estampa tres dinos!" |
| | 2 | `poner {sticker: sello_dino, n: 1, en_zona: lago}` | "¡Un dino al agua! ¡Splash!" |
| | 3 | `poner {sticker: sello_estrella, n: 2, en_zona: cielo}` | "¡Dos estrellas en el cielo!" |
| **Z3 · coco** | 1 | `pintar_zona {zona: cresta}` | "¡Píntale la cresta a Coco!" (Coco se mira en un espejito) |
| | 2 | `pintar_zona {zona: cuerpo}` | "¡Ahora la guatita… digo, el cuerpo!" |
| | 3 | `encargo` | "¡Pinta a Coco entero!" |
| **Z3 · dino** | 1 | `pintar_zona {zona: [pua_1, pua_2, pua_3]}` | "¡Pinta las puntitas de la espalda!" |
| | 2 | `pintar_zona {zona: cuerpo}` | "¡Ahora el cuerpo del dino!" |
| | 3 | `encargo` | "¡Píntalo entero!" |
| **Z3 · auto** | 1 | `pintar_zona {zona: [rueda_1, rueda_2]}` | "¡Pinta las ruedas!" |
| | 2 | `pintar_zona {zona: luz}` | "¡Prende la luz! ¡Bip bip!" |
| | 3 | `encargo` | "¡Píntalo entero!" |
| **Z4 · noche / rosa** | 1 | `pintar_zona {zona: franja_abajo}` (región virtual) | "¡Haz música abajo! Bom, bom." |
| | 2 | `pintar_zona {zona: franja_arriba}` | "¡Ahora arriba! Pío, pío." |
| | 3 | `encargo` (tobogán musical) | "¡Haz un arcoíris de arriba hasta abajo!" |
| **Z5 · ala** | 1 | `pintar_zona {zona: nave}` | "¡Pinta la nave!" |
| | 2 | `poner {sticker: sello_dino, n: 1, en_zona: ventanilla}` | "¡Pon un dino piloto en la ventanita!" (el dino saluda desde la nave) |
| | 3 | `encargo` | "¡Pinta las rayas y el borde!" |

### 7.3 Nicole (6 por hoja, 3 visibles)

**Z2 · colorear por zonas** (6 por lámina). En las láminas de Chile, la última pide `modelo`: es
educativo (la bandera debe salir bien). En pony, jirafa y gatito no se pide: ahí manda su creatividad.

| Lámina | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| pony | `pintar_zona cuerpo` | `pintar_zona crin` | `pintar_zona [pata_1..4]` | `usar pincel_corazon n 3` | `colores 5` | `encargo` |
| jirafa | `pintar_zona [cuerpo, cuello]` | `pintar_zona [mancha_1..6]` (zoom) | `pintar_zona copa` | `pintar_zona cielo color rosado` | `colores 5` | `encargo` |
| gatito | `pintar_zona cuerpo` | `pintar_zona [lazo_1, lazo_2] color rosa` | `pintar_zona ovillo` | `usar pincel_estrella n 3` | `colores 5` | `encargo` |
| bandera_chile | `pintar_zona azul color azul` | `pintar_zona estrella color blanco` | `pintar_zona rojo color rojo` | `pintar_zona blanco color blanco` | `pintar_zona cordillera` | `parte_encargo {modelo: true}` |
| torres_paine | `pintar_zona [torre_1..3]` | `pintar_zona [nieve_1..3] color blanco` | `pintar_zona lago color turquesa` (dato: "el agua es turquesa por el polvito de los glaciares") | `pintar_zona pampa` | `colores 6` | `encargo` |
| valparaiso | `pintar_zona [casa_1..5] distintos` | `pintar_zona [casa_6..10] distintos` | `pintar_zona carro` (dato del ascensor) | `pintar_zona mar color azul` | `colores 8` | `encargo` |

Hojas por partida: **2** (hoy son 3; ver §9).

**Z3 · Coco pide**: los pedidos pasan a ser "pinta **esta parte** de **este color**". Así se escucha y se
reconoce a la vez, y no solo se elige un color.

| Lámina | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| jardin_coco | `pintar_zona sol color amarillo` | `pintar_zona chupetin color rosa` | `pintar_zona puerta color rojo` | `pintar_zona pasto color verde` | `pintar_zona glaseado color violeta` | `encargo` (lámina completa; reemplaza "5 pedidos") |
| castillo | `pintar_zona [techo_1..3] color rosa` | `pintar_zona muralla color blanco` | `pintar_zona [bandera_1, bandera_2] color amarillo` | `pintar_zona puerta color cafe` | `pintar_zona ventana_corazon color rojo` | `encargo` |

Si pinta con otro color, la región queda así (puede repintarla). Se mantiene la burbuja con la gota
como pista; nunca hay un "no".

**Z4 · espejo** (2 por partida; cobertura ≥ 60 % por región):

| Lámina | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| flor | `pintar_zona centro` | `pintar_zona [petalo_0..7]` | `pintar_zona [tallo, hoja_1, hoja_2]` | `colores 4` | `usar pincel_corazon n 2` | `encargo` |
| corona | `pintar_zona corona` | `pintar_zona [joya_1..3]` | `pintar_zona [punta_1..3]` | `colores 4` | `usar pincel_estrella n 2` | `encargo` |
| gatito_cara | `pintar_zona cara` | `pintar_zona [oreja_1, oreja_2]` | `pintar_zona hocico` | `colores 4` | `usar pincel_corazon n 2` | `encargo` |
| corazon_alado | `pintar_zona corazon color rosa` | `pintar_zona [ala_1..4]` | `colores 4` | `usar pincel_estrella n 2` | `usar pincel_corazon n 2` | `encargo` |
| mono | `pintar_zona nudo` | `pintar_zona [lazo_1, lazo_2]` | `pintar_zona [cinta_1, cinta_2]` | `colores 4` | `usar pincel_corazon n 2` | `encargo` |

**Z5 · ala + viste a Coco** (2 hojas, 6 cada una):

| Hoja | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| ala | `pintar_zona nave` | `pintar_zona [franja_1..4]` | `poner {sello_corazon, 3}` | `pintar_zona ventanilla` | `colores 5` | `encargo` |
| traje | `parte_encargo {regiones: [pieza principal del traje]}` | `parte_encargo {regiones: [accesorio]}` | `pintar_zona cresta` | `poner {sello_estrella, 3}` | `colores 4` | `encargo` |

`dev-godot` asigna los ids de "pieza principal" y "accesorio" de cada traje: princesa (vestido /
corona), idol (chaqueta / micrófono) y heroína (capa / antifaz). **Momento**: al terminar, Coco desfila
por una pasarela con el traje.

### 7.4 Sofía (12 por hoja, 3 visibles)

**Z2 · mosaico por código.** La cantidad de dígitos de color `k` varía (2-8), así que la lista se arma
con una regla fija:

1. `trazo_unico {n: 12}`
2. `parte_encargo {digito: d}` para cada dígito, del más abundante al menos abundante (k objetivos)
3. `adivinar` (aparece en la cola recién cuando el mosaico llega al 30 %; mientras tanto, entra el
   siguiente)
4. `trazo_unico {n: 24}`
5. relleno hasta completar 12, en este orden: `parte_encargo {cuadrante: 1..4}`, `{borde}`, `{centro}`
6. `encargo` (siempre al final)

Ejemplos:
- Chile (k = 3): 1 + 3 + 1 + 1 + 5 rellenos + 1 = 12.
- Japón (k = 2): 6 rellenos.
- Si k ≥ 7, no hay rellenos y se recortan dígitos: se fusionan los 2 menos abundantes en un mismo
  objetivo.

Con pantalla completa, la celda mide unos 60 px (antes 42), y con zoom 2× unos 120 px. Así se resuelve
el riesgo de UX de la ficha del motor (§5). Hojas por partida: **2** (hoy 3).

**Z3 · mezcla en la paleta** (1 lámina; 12 = 5 pedidos de mezcla + 6 zonas + lámina completa). Los
colores de las zonas se consiguen mezclando: reto real de RYB.

| Lámina | 1-5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|
| volcan_osorno | `parte_encargo {pedido: 1..5}` | `pintar_zona lago color celeste` | `pintar_zona [bosque_1, bosque_2] color verde` | `pintar_zona bote color cafe` | `pintar_zona vela color rosado` | `pintar_zona nieve color blanco` | `colores 7` | `encargo` |
| torres_paine | igual | `pintar_zona lago color celeste` | `pintar_zona pampa color naranja` | `pintar_zona [torre_1..3] color cafe` | `pintar_zona macizo color violeta` (dato: "de lejos, las montañas se ven moradas") | `pintar_zona [nieve_1..3] color blanco` | `colores 7` | `encargo` |
| valparaiso | igual | `pintar_zona carro color verde` | `pintar_zona [techo_1..10] color naranja` | `pintar_zona [casa_1..10] distintos` | `pintar_zona barco color violeta` | `pintar_zona mar color azul` | `colores 8` | `encargo` |

Los pedidos se intercalan con las zonas en la cola: 1, 6, 2, 7, 3, 8, … Así no se juntan 3 pedidos
iguales a la vista.

**Z4 · mandala** (hojas por partida: **1**, hoy 2; cobertura ≥ 60 % por región):

| Lámina | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mandala_flor | `pintar_zona centro` | `pintar_zona [petalo_0..5]` | `pintar_zona [petalo_ext_0..11]` | `pintar_zona centro color amarillo` | `pintar_zona [petalo_0..5] color rosa` | `pintar_zona [petalo_ext_0..11] color turquesa` | `usar purpurina` (lluvia dorada) | `usar pincel_estrella n 3` | `colores 6` | `parte_encargo {cobertura: 90, zona: petalo_ext}` ("sin huequitos") | `parte_encargo {cobertura: 50}` | `encargo` |
| mandala_estrella | `pintar_zona centro` | `pintar_zona [triangulo_0, triangulo_1]` | `pintar_zona aro` | `pintar_zona [gema_0..5] distintos` | `pintar_zona centro color rosa` | `pintar_zona aro color turquesa` | `usar purpurina` | `usar pincel_estrella n 3` | `colores 6` | `parte_encargo {cobertura: 90, zona: aro}` | `parte_encargo {cobertura: 50}` | `encargo` |
| mandala_copo | `pintar_zona centro` | `pintar_zona aro` | `pintar_zona centro color celeste` | `pintar_zona aro color turquesa` | `usar pincel_estrella n 3` | `usar purpurina` | `colores 4` | `colores 6` | `parte_encargo {cobertura: 90, zona: aro}` | `parte_encargo {cobertura: 30}` | `parte_encargo {cobertura: 50}` | `encargo` |

El copo tiene pocas regiones: `dev-godot` puede agregarle `brazo_0..5` a la guía. En ese caso, los
objetivos 7 y 10 pasan a ser `pintar_zona [brazo_0..5]` y `pintar_zona [brazo_0..5] distintos`.

**Z5 · decora el ala** (1 hoja):

| # | Objetivo | # | Objetivo |
|---|---|---|---|
| 1 | `pintar_zona nave` | 7 | `pintar_zona borde color rosa` |
| 2 | `pintar_zona [franja_1..4] distintos` | 8 | `poner {sello_estrella, 5, en_zona: espacio}` |
| 3 | `poner {sello_pony, 1, en_zona: ventanilla}` (su insignia) | 9 | `usar purpurina` |
| 4 | `pintar_zona espacio` | 10 | `poner {sello_luna, 1}` |
| 5 | `pintar_zona [estrellita_0..7] color amarillo` (zoom) | 11 | `colores 8` |
| 6 | `pintar_zona [luz_1, luz_2] color turquesa` | 12 | `encargo` |

---

## 8. Stickers, regiones y voces nuevas

### 8.1 Stickers nuevos (para `disenador-personajes` y dev; estilo "peluche pintado", mirando a la derecha)

| Id | Clase | Uso | Prioridad |
|---|---|---|---|
| `nube_lluvia` | decorado | C01, C02, C05 y C30; granja, safari, ciudad | Alta |
| `dino_bebe` | vivo | C03 | Alta |
| `cuartel_bomberos` | lugar | bomberos | Alta |
| `cantante` | vivo | escenario_pop y concierto_pop (idol genérica, sin copiar IP; 3 peinados o colores por tinte) | Alta |
| `camarin` | lugar | escenario y concierto (puerta con estrella) | Alta |
| `barco` | vivo | tren_chile | Alta |
| `libro_volador` | vivo (volador) | C17 | Alta |
| `copa` | decorado | pista_carreras y C31 | Media |
| `pony_princesa` | vivo | C09 (puede ser el pony + capa de corona) | Media |
| `gatito_mago` | vivo | C18 (gatito + capa de sombrero) | Media |
| `cantante_lider` | vivo | C20 (cantante + capa de corona) | Media |
| `pocion_rosa` | lugar | C16 (variante del caldero) | Media |
| `volcan_nevado` | lugar | C22 (variante del volcán) | Media |
| `tren_fiestas` | vivo | C23 (tren + banderitas) | Media |
| `velitas` | lugar | C12 (variante del pastel) | Media |
| `maxi_bombero` | — | mini sprite de Maxi con casco en el camión | Baja (opcional) |

Efectos sin sticker (animación o partículas, dev): `humito`, `constelacion_dino`, `pony_feliz`,
`jirafa_come`, `fuegos_artificiales`, `ovillo_rodando`, `canta`, `corazon_coreano`, `ola_de_notas`,
`coreografia`, `perrito_feliz`, `juega_pelota`, `amigos`, `bandera_luna`, `estrella_fugaz`, `eclipse`,
`jardin` y `rugido`.

**Caminos nuevos**: `huellitas` (huellas de gato), `alfombra` (roja o rosa con borde dorado) y
`ruta_mar` (punteado con olitas).

**Regiones de fondo nuevas** (por escena):
- `partida`, `base` y `fuente`;
- `puerta`, `escenario` (como lugar), `techo` y `platea`;
- `desierto`, `bosque_sur` e `isla`;
- `bebedero`;
- río lineal (granja y ciudad) y `charca`;
- franjas virtuales `franja_arriba`, `franja_medio` y `franja_abajo` del dedo mágico.

### 8.2 Clases y cambios en el catálogo

Agregar a `stickers.gd` una tabla `CLASE` (§1.1) y sumar `lechuza` y `escoba` a los vivos (voladores).

### 8.3 Líneas de voz nuevas (solo la lista; **no generar audio**: el TTS pagado requiere `--estimar` y el OK del PO)

| Grupo | Ruta sugerida | Cantidad |
|---|---|---|
| Inspiración por escena (15) | `voces/arcoiris/pinta/escenas/<escena>/inspiracion.wav` | 15 |
| Objetivos de las escenas de z1 (4×3 + 5×6 + 6×12) | `…/escenas/<escena>/obj_NN.wav` | 114 |
| Objetivos de las zonas 2-5 (tablas de §7; las que se repiten, como `colores N`, `usar …` o "¡Píntalo entero!", se comparten) | `voces/arcoiris/pinta/objetivos/<id>.wav` | ~90 únicas |
| Combinaciones (C01-C32) | `voces/arcoiris/pinta/combinaciones/<resultado>.wav` | 32 |
| Datos de Chile al llegar (6) | ya existen; revisar texto | 0-6 |
| Pistas genéricas por tipo y perfil (14 tipos; Maxi corta, Nicole media, Sofía acertijo) | `voces/arcoiris/pinta/pistas/<tipo>_<perfil>.wav` | ~35 |
| Acertijos de nivel 2 de Sofía (revelar un ingrediente) | `…/pistas/acertijo_<resultado>.wav` | 20 |
| Cola de objetivos: "¡eso ya lo habías hecho!", "¡listo, muéstrale a Coco!" (`hoja_lista`), "¡siii!" de Maxi y "objetivo cumplido" ×3 variantes por perfil | `voces/arcoiris/pinta/comun/` | ~12 |
| `adivinar` del mosaico: pregunta, gag de error ×3 y acierto ×2 | `voces/arcoiris/pinta/estrella/` | 6 |

**Total aproximado**: 330 líneas. El `guionista` debe pulirlas: cortas en Maxi (≤ 6 palabras), con
humor en Sofía y sin explicar de más (GDD §5, "la voz explica al inicio y en pistas").

---

## 9. Calibración: tiempo estimado y riesgos

### 9.1 Tiempo por hoja (estimado; validar en playtest)

| Hermano | Objetivos | Tiempo por objetivo | Por hoja | Hojas por partida (propuesta) | Por estación |
|---|---|---|---|---|---|
| Maxi | 3 | 15-40 s | 2-3 min (+ juego libre) | 2 (igual) | 5-7 min |
| Nicole, z1 | 6 | 40-70 s (algunos se cumplen juntos) | 5-7 min | **2** (hoy 3) | 10-14 min |
| Nicole, z2-z5 | 6 | 30-50 s | 3-5 min | z2: **2** (hoy 3); z3, z4 y z5: igual (2) | 7-10 min |
| Sofía, z1 | 12 | 40-80 s; 3 visibles y varios se superponen | 9-13 min | **2** (hoy 3) | 18-26 min |
| Sofía, z2 | 12 | — | 6-8 min (el mosaico manda) | **2** (hoy 3) | 12-16 min |
| Sofía, z3 | 12 | — | 8-10 min | 1 (igual) | 8-10 min |
| Sofía, z4 | 12 | — | 6-8 min (cada trazo se copia 12 veces) | **1** (hoy 2) | 6-8 min |
| Sofía, z5 | 12 | — | 7-9 min | 1 (igual) | 7-9 min |

### 9.2 Riesgos y mitigaciones

1. **12 objetivos de Sofía se hacen largos** (riesgo principal). Mitigaciones:
   - 2 hojas en z1 y z2;
   - 3 objetivos visibles a la vez;
   - objetivos que se cumplen con la misma acción: conectar + llegadas, encerrar + circuito, poner +
     colores;
   - "ya cumplidos" que pasan en 1 s.
   - **Medir en el playtest**: si una hoja pasa de 12 min, bajar a 9 objetivos o fusionar
     `poner`/`colores` con otros. Es un cambio de datos, no de código.
2. **Salir a mitad de una hoja larga** (GDD §6.8). Hoy salir pierde la hoja en curso. Con 10 min de
   hoja, eso duele. Se recomienda guardar el estado de la hoja (stickers, caminos, pintura y objetivos
   cumplidos) para retomarla. Toca guardado: decisión de dev/PO.
3. **Maxi no descubre el camino** (pendiente del playtest de §7 del motor). Mitigaciones:
   - imán de 120 px;
   - lugares ya puestos;
   - mano fantasma a los 15 s;
   - válvula §6.4.
4. **Frustración de Sofía con las recetas ocultas**. Mitigaciones:
   - acertijo por voz;
   - pista a pedido tocando a Coco (no espera 105 s);
   - revelado progresivo de ingredientes;
   - las recetas son lógicas del mundo real (lluvia + sol, varita + libro).
   - Nunca hay "error": juntar cosas que no combinan solo da un saltito.
5. **Combinaciones por accidente**: no es un problema. Se celebran y, si estaban en la cola, entran
   como "ya cumplidas".
6. **`orden` con redes de caminos**. R4 puede elegir un desvío que Sofía no esperaba. Mitigaciones:
   - el objetivo admite paradas extra;
   - la pista enciende el tramo que falta.
   - `disenador-mecanicas` debe validar R4 con un jugador automático.
7. **Celos Nicole–Sofía**: los momentos memorables son equivalentes en tamaño (corazón coreano frente
   a coreografía con pose). Ninguna voz compara a una con la otra.
8. **Regiones chicas en Nicole** (manchas de la jirafa, joyas): se resuelven con el zoom. Si en el
   playtest no lo usa, fusionar `[mancha_1..6]` con `cuerpo`.

---

## 10. Problemas del GDD que revela este diseño (para el PO; no se editó el GDD)

1. **GDD §5, Brote: "máximo un objetivo a la vez"** choca con la decisión del PO de mostrar 3 a la
   vez a Nicole. Propuesta: las 3 tarjetas se ven, pero solo la primera late y es la que Coco narra
   (la "activa"); las otras pueden cumplirse en cualquier orden. Si el PO lo confirma, hay que
   actualizar §5.
2. **GDD §6.4: "sin gestos complejos, solo tocar y arrastrar"**: el zoom con pellizco lo viola. Por eso
   esta ficha propone la lupa (toque a 1×/2×). El pellizco quedaría como extra para Sofía solo si el
   PO lo aprueba.
3. **GDD §4 y zonas §3.4: "expresión libre, igual para todos; nunca una evaluación del dibujo"** y
   "**la zona 1 se mantiene libre**": ahora la hoja exige objetivos, y algunos piden un color
   concreto. Sigue sin haber fallo ni castigo (se puede repintar), pero cambia el espíritu del juego.
   El PO lo decidió el 17-Oct-2026: falta reflejarlo en el GDD y en zonas §3.4.
4. **Motor §4: "destellos: nunca se exige un mínimo" y el botón "mostrar a Coco" visible en Semilla
   tras `segundos_mostrar`**: ambos quedan reemplazados por "se pasa al cumplir todo" (con la válvula
   de Semilla de §6.4).
