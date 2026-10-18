# Ficha de motor — `lienzo_libre` ("Pinta con Coco")

- **Autor**: Dev (`dev-godot`), 27-Sep-2026, a pedido directo del PO (que el Planeta Arcoíris dure
  ~1 h por hermano; banderas y lugares de Chile como tema de las láminas).
- **Estado**: implementado y verificado en headless y en ventana. **Pendiente**: validación de
  `disenador-mecanicas` y `disenador-niveles`, auditoría de `experto-ux-parvulo`, arte final
  (HE-13), voces oficiales y playtest con los tres.
- **Fuentes**: GDD §4 (Pinta con Coco: expresión libre, sin fallo), §5 y §6;
  `docs/fichas/planeta-arcoiris.md` §3 (contrato base, voces, momentos memorables) y
  `docs/fichas/planeta-arcoiris-zonas.md` §3.4 (encargo por zona y hermano).

## 1. Qué es

Un lienzo para pintar con el dedo o el mouse. Coco imita en vivo, en su cresta, los colores que se
usan. **No hay fallo para nadie, tampoco para Sofía**: el destello se gana al tocar **"mostrar a
Coco"**, un botón de 142 px con la cara de Coco y un marquito (sin texto). Coco celebra sin evaluar
el dibujo. En Semilla el botón aparece tras un momento de juego (`segundos_mostrar`), al tocar a
Coco o al terminar una lámina.

## 2. Archivos

| Archivo | Qué hace |
|---|---|
| `escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn` | Escena del motor (raíz `Node2D` + `CanvasLayer`, patrón de `minijuego_base.gd`) |
| `scripts/motores/lienzo_libre/motor_lienzo_libre.gd` | Flujo de hojas y etapas, paleta, herramientas, voces, Coco, guardado |
| `scripts/motores/lienzo_libre/lienzo.gd` | El lienzo: capas, entrada, pinceles, simetrías, relleno, mosaico, composición del PNG |
| `scripts/motores/lienzo_libre/laminas.gd` | Láminas vectoriales (regiones y detalles): dibujo en pantalla y rasterizado |
| `scripts/motores/lienzo_libre/rasterizador.gd` | Relleno de polígonos, brochas y calcomanías en CPU |
| `scripts/motores/lienzo_libre/sellos.gd` | Sellos dibujados en código: dino, auto, estrella, corazón, flor, luna, destello, pony |
| `scripts/motores/lienzo_libre/colores_lienzo.gd` | Paleta con nombre y mezcla de pinturas RYB |
| `scripts/motores/lienzo_libre/cresta_coco.gd` | Repinta la cresta del sprite de Coco con los colores usados |
| `scripts/motores/lienzo_libre/stickers.gd` | Catálogo de 62 stickers del lienzo con tema (reúne `dibujos_emparejar.gd`, `figura_vectorial.gd` y ~38 dibujos propios) |
| `scripts/motores/lienzo_libre/sticker_vivo.gd` | Nodo de un sticker vivo o viajero: vector, salta, anda, escala, giro, espejo |
| `scripts/motores/lienzo_libre/grabador.gd` | Imita los `draw_*` de un CanvasItem para rasterizar stickers y caminos en CPU (PNG) |
| `herramientas/capturar_stickers.gd` | Hoja de contacto del catálogo de stickers (headless) |
| `herramientas/capturar_lienzo_tema.gd` | Pantallazos en ventana del selector, la bolsa, la edición y una escena por hermano |
| `herramientas/qa_test_lienzo.gd` | Arnés QA headless de los 15 niveles |
| `herramientas/capturar_lienzo.gd` | Pantallazos en ventana de cada nivel y de todo el pool de láminas |

## 3. Contrato de datos

Extiende el de `planeta-arcoiris.md` §3.2. Un nivel es un JSON en
`datos/niveles/arcoiris/<zona>/pinta_<perfil>.json`:

| Campo | Uso |
|---|---|
| `encargo` | `libre`, `sellos_escena`, `colorear_zonas`, `colorear_codigo`, `pinta_coco`, `coco_pide`, `mezcla_paleta`, `dedo_magico`, `espejo`, `mandala`, `decora_ala`, `viste_coco` |
| `paleta` | Ids de color (`colores_lienzo.gd`). Por defecto: 6 en Semilla y 14 en Brote/Estrella |
| `herramientas`, `herramienta_inicial` | Barra inferior: `pincel`, `pincel_grueso`, `goma`, `balde`, `arcoiris`, `purpurina`, `pincel_corazon`, `pincel_estrella`, `sello_<tipo>` |
| `laminas`, `laminas_por_partida`, `primera_fija`, `al_menos_una` | Pool de hojas. Se baraja; `al_menos_una: "chile"` asegura una lámina con esa etiqueta |
| `etapas` | Varias etapas seguidas; cada una sobrescribe campos del nivel (Nicole, zona 5: ala y después traje) |
| `simetria` | `espejo` (2 copias) o `mandala` (6 ejes con reflejo = 12 copias) |
| `modelo`, `imagen_modelo` | Tarjeta con la lámina en sus colores sugeridos, o una imagen (la nave, en "decora el ala") |
| `pedidos`, `pedidos_por_partida` | Colores (Coco pide) o mezclas (Sofía) que pide Coco |
| `rellenar_con_toque`, `tinte_coco` | Pinta a Coco: todo toque rellena; el sprite de Coco toma el color del cuerpo |
| `notas` | Dedo mágico: campanitas pentatónicas sintetizadas, sin archivos |
| `segundos_mostrar` | Semilla: segundos de juego antes de que aparezca "mostrar a Coco" (0 = visible siempre) |
| `sellos_vivos` | Dinos y autos de Maxi quedan como nodos, para el gag de "caminar" (tope 40; después se hornean) |
| `guardar_como` | Nombre fijo extra del PNG (`ala_nave`, `traje_coco`) para el hangar y el mapa |
| `radio_pincel`, `lado_sello`, `papel`, `color_inicial` | Ajustes finos por perfil |
| `voces_colores`, `voces_pedidos`, `voces_logrado`, `voces_mezclas` | Patrones `...%s.wav` por id de color o mezcla |
| `lineas_voz` | `intro`, `siguiente`, `mostrar`, `victoria_final`, `lamina_completa`, `muestramelo`, `pedidos_listos`, `igualita`, `arcoiris`, `dino_camina`, `uso_<herramienta>` |

**Láminas** (`laminas.gd`): en coordenadas del lienzo (824×530).

- `tipo: zonas`: `regiones` con forma `poligono` (con `suave` = pasadas de Chaikin), `elipse`,
  `circulo`, `rect`, `estrella`, `corazon`, `gota` o `flor`. Cada región lleva `sugerido`, `inicial`
  y `fija`. Los `detalles` (ojos, sonrisa, rubor, líneas) van siempre encima.
- `tipo: mosaico`: `celdas` (filas de dígitos) + `colores` (dígito → color). Lleva `voz` (nombre) y
  `voz_dato` (dato curioso).
- `tipo: guia`: plantilla tenue del espejo o del mandala.
- `tipo: papel`: solo cambia el color del papel.
- Los trajes de Coco van en `trajes` (`regiones`, `regiones_atras`, `detalles`, `voz`) y
  `orden_trajes`.

## 4. Decisiones técnicas

- **Rendimiento en tablet**: lo pintado vive en **una sola `Image`** del tamaño del lienzo. Cada trazo
  estampa una brocha cacheada con `Image.blend_rect`, que es nativo, y la textura se sube a lo más una
  vez por cuadro. Las láminas son vectoriales (`_draw`, se redibujan solo al cambiar) y los rellenos
  son un cambio de color de región. Ningún trazo crea nodos.
- **PNG también en headless**: `lienzo.componer()` arma el dibujo en CPU (papel + lámina rasterizada
  + pintura + sellos), sin depender del renderer. Se guarda en
  `user://dibujos/<hermano>/<id_nivel>_<hoja>_<fecha>.png`. **No se toca el autoload `Progreso`**.
  `carpeta_dibujos` se puede cambiar: los arneses QA usan `user://qa_dibujos` y no pisan los dibujos
  reales.
- **Destellos**: 20 por hoja mostrada + 1 por color distinto usado (hasta 10). Nunca se exige un
  mínimo. Sin estrellitas (GDD §4).
- **Completar una lámina** cuenta regiones *tocadas*, no regiones que cambiaron de color. Así, pintar
  de blanco la estrella blanca de la bandera también cuenta.
- **Semilla**: tocar una región con el color que ya tiene pasa al siguiente color. Todo toque cambia
  algo.
- **Momentos memorables** (§3.10 de la ficha base):
  - Universal: 4 colores distintos en 8 s ponen la cresta en arcoíris.
  - Maxi: 3 dinos seguidos caminan en fila.
  - Nicole: el primer uso del corazón hace que Coco le devuelva un corazón.
  - Sofía: la purpurina quieta 1 s hace llover destellos dorados.
- **Mezcla RYB**: interpolación en el cubo RYB (Gossett y Chen) con los colores de la paleta en las
  esquinas. Los tres primarios dan café, no negro, y el blanco aclara.

## 5. Tamaños táctiles (GDD §6.1)

| Perfil | Tamaños |
|---|---|
| Semilla | Manchas de color 98×100; herramientas de 96; "mostrar a Coco" de 142 |
| Brote/Estrella | Colores ≥ 64; herramientas de 90 |

Riesgo para UX: las celdas del mosaico de Sofía miden **42 px** (grilla 18×12). Se pintan
arrastrando, como un lienzo, pero una celda sola queda bajo los 64 px de la regla. Además, algunas
regiones de las láminas de Nicole son chicas (manchas de la jirafa, ventanas, cerezas). En todos los
casos la región es tocable y nunca bloquea: el QA confirma que toda región rellenable tiene un punto
tocable.

## 6. Verificación

- `godot --headless --path . --script herramientas/qa_test_lienzo.gd` revisa los 15 niveles:
  - hojas, voces y tamaños táctiles;
  - trazos (y su reflejo en espejo o mandala), regiones tocables y láminas completas;
  - mosaicos 216/216 con Coco nombrando el dibujo;
  - pedidos de Coco y mezclas, trajes;
  - un PNG válido por hoja, la copia fija del ala y `completado(destellos)`;
  - la tabla de mezclas RYB.
- `godot --path . --script herramientas/capturar_lienzo.gd -- <carpeta> [filtro|pool]` guarda
  pantallazos de cada hoja (al abrir y terminada) y de todo el pool de colorear y de mosaicos.

## 7. Pendientes

- Voces oficiales de las 127 líneas nuevas del lienzo con tema (hoy TTS de Windows), con OK del PO sobre el costo.
- Playtest: que Maxi descubra el conector sin ayuda; que Nicole y Sofía encuentren la bolsa; medir cuánto juega Sofía.

- Conectar las 5 estaciones `pinta` en `datos/planetas/arcoiris/mapa.json` (escena y niveles).
- Que el hangar muestre `ala_nave.png` y que el mapa del planeta vista a Coco con `traje_coco.json`
  (núcleo).
- Voces oficiales de Coco y Cometa: las 167 líneas son TTS de Windows (`lineas_tts.tsv`). Pasarlas a
  `generar_voces_fal.py` requiere el OK del PO sobre el costo.
- Arte final de sellos, láminas y la UI de la paleta (HE-13). Hoy todo está dibujado en código.
- Galería para ver los dibujos guardados (fuera del alcance de este motor).

## 8. Lienzo con tema (zona 1) — pedido del PO, 27-Sep-2026

El "lienzo libre" era una hoja en blanco. El PO pidió que **cada hoja tenga un tema** ("Maxi dibuja un
parque de dinosaurios, o una pista de carreras"), **muchas más formas prediseñadas** acordes al tema,
**objetos que se conecten** entre sí, y que **Sofía**, la que más se aburriría, tenga más opciones. Nicole y Maxi
tienen versiones más simples.

### 8.1 Qué se tomó de juegos del género

| Referente | Idea copiada |
|---|---|
| Toca Boca / Sago Mini | Stickers vivos que se tocan y reaccionan, escena para contar una historia, sin objetivos |
| Labo Train / Brick Train | Dibujar el recorrido y ver un vehículo andar por él |
| Race Craft (Budge) | Armar la propia pista de carreras |
| Crayola Create & Play | Sellos/stickers temáticos y purpurina; elegir el color del sticker |
| Kids Doodle | Pinceles mágicos (ya existían: estrella, corazón, purpurina, arcoíris) |

### 8.2 Contrato de datos

Un nivel con `temas` reemplaza las láminas: cada hoja es un tema, que sobrescribe la configuración como
una etapa.

| Campo del nivel | Uso |
|---|---|
| `temas` | Pool de temas (ver abajo) |
| `temas_por_partida` | Hojas de la partida (Maxi 2, Nicole 3, Sofía 3) |
| `opciones_tema` | 1 = tema asignado al azar (Maxi); 2 o 3 = el niño elige entre tarjetas sin texto |
| `al_menos_una` | Etiqueta que debe salir (Maxi: `favorito` = dinos o pista) |
| `voces_stickers` | Patrón `...stickers/%s.wav`: Coco nombra cada sticker la primera vez y al tocarlo |
| `lineas_voz` | `elige_tema`, `conectado`, `reto_cumplido`, `retos_todos` |

| Campo del tema | Uso |
|---|---|
| `fondo` | Lámina de zonas ya pintada (`inicial`). En Brote y Estrella el balde la recolorea; en Semilla es fija |
| `stickers` | Ids del catálogo (`stickers.gd`). Maxi 3 (en la barra), Nicole 8 y Sofía 13-15 (en la bolsa) |
| `conector` | `{tipo, viajero}`: tipos `camino`, `sendero`, `rieles`, `cerca`, `guirnalda`, `arcoiris`, `estelar`, `destellos` |
| `herramientas`, `herramienta_inicial` | Barra; `bolsa` abre la bandeja de stickers y `conector` traza caminos |
| `portada` | 3 stickers que muestra la tarjeta del selector |
| `retos` | Solo Sofía: `{tipo: stickers/conexiones/colores/distintos, n, sticker?, voz}` |
| `nombrar_estaciones` | Tren por Chile: al llegar a una punta, Coco nombra el lugar |
| `lineas_voz` | `intro`, `nombre` (tarjeta), `uso_conector`, `pista` (tocar a Cometa) |

### 8.3 Temas por hermano

| Hermano | Temas | Qué puede hacer |
|---|---|---|
| Maxi (Semilla) | Parque de dinosaurios, Pista de carreras, Bomberos, Espacio | 3 stickers grandes en la barra (se tiñen con el color elegido), pincel y el conector; su vehículo o dino recorre lo que dibuja. Tocar un sticker lo hace saltar o andar. Sin bolsa ni edición |
| Nicole (Brote) | Granja de ponys, Safari de jirafas, Castillo de princesas, Fiesta de gatitos, Escenario pop | Elige entre 2 tarjetas. Bolsa con 8 stickers; los arrastra, los agranda o achica, los borra; el balde les cambia el color; cerca, sendero, puente arcoíris o guirnaldas de luces |
| Sofía (Estrella) | Escuela de magia, Ciudad de los ponys, Concierto pop, Tren por Chile, Parque de mascotas, Misión espacial | Elige entre 3 tarjetas. Bolsa con 13-15 stickers, edición completa (tamaño, girar, espejo, borrar), balde sobre fondo y stickers, todos los pinceles, conectores con viajero y **3 retos de artista** opcionales (+5 destellos cada uno) |

Sin arañas ni bichos en ningún tema (perfil de Nicole y Sofía). En el **Tren por Chile**, los stickers son
lugares (Torres del Paine, moái de Rapa Nui, casitas de Valparaíso, pingüino de la Patagonia, cactus de
Atacama, copihue, bandera): el tren viaja entre ellos y Coco nombra el lugar al llegar. Es el contenido
educativo de Chile que pidió el PO.

### 8.4 Conectar objetos

La herramienta **conector** traza a mano alzada. El trazo se suaviza con Chaikin y se remuestrea cada
10 px. Si una punta cae sobre un sticker, se pega a su centro: eso cuenta como **conexión**, los dos
stickers saltan y Coco celebra. Si el tema trae `viajero`, este recorre el camino de ida y vuelta, y en
cada punta el sticker salta. Un trazo que vuelve a su inicio lejos de los stickers queda **cerrado** (un
circuito de carreras) y el viajero da vueltas. Los vehículos y los voladores giran con la curva; los
animales solo se inclinan. Topes: 30 caminos y 8 viajeros.

### 8.5 Decisiones técnicas

- Los stickers en pantalla son **vectores** (`_draw`): quedan nítidos a cualquier escala o giro y no
  cuestan nada al editarlos. Para el PNG, `grabador.gd` graba los mismos `draw_*` y los rasteriza en
  CPU (con caché por id, color, tamaño y giro), así que también funciona en headless. El rasterizado
  cuesta unos 12 ms por sticker en PC.
- Para esto, las funciones estáticas de `dibujos_emparejar.gd` y `figura_vectorial.gd` reciben el
  lienzo sin tipo (*duck typing*). No cambia su comportamiento: emparejar y voces siguen en verde.
- Con fondo de tema, rellenar todas sus zonas **no** dispara "¡lo pintaste todo!" (`avisar_completa`).
- Tope de 60 stickers vivos; pasado el tope, el más antiguo se hornea en la pintura.
- Voces nuevas: 127 líneas con el TTS provisional de Windows (`lineas_tts.tsv`).

### 8.6 Verificación

`qa_test_lienzo.gd` juega cada hoja con tema. Revisa:

- el selector (cantidad de tarjetas, tamaño ≥ 200 px, sin repetir temas);
- la bolsa (≥ 64 px, que quepa en el lienzo);
- poner, tocar (sin duplicar), arrastrar y editar stickers;
- el balde y la goma sobre stickers;
- el conector con conexión, el viajero que avanza y el circuito cerrado;
- los 3 retos de Sofía;
- que el PNG incluya los stickers.

Resultado (27-Sep-2026, Godot 4.7.1): **506 OK / 0 fallos** en las 15 rutas. Regresiones: emparejar
sin fallos, `qa_test_voces` 815 OK y mapa del planeta OK.

## Validación HE-40 — disenador-mecanicas (28-Sep-2026, PROPUESTA)

**Aprobado** (`docs/validaciones/HE-40_disenador-mecanicas.md`, hallazgos 19-21). Cambios menores:

- El pincel del mosaico pinta la celda más cercana dentro de un radio de 32 px y, al arrastrar, pinta
  todas las celdas que cruza.
- En Semilla, "mostrar a Coco" aparece con `segundos_mostrar` de al menos 45 s y entra con un rebote.
  *(Reemplazado en el lienzo v2, §9: el botón aparece solo con todos los objetivos cumplidos.)*

## 9. Lienzo v2 (17-Oct-2026)

Pedido directo del PO, implementado en el juego sin maqueta. El catálogo de escenas y objetivos es
`docs/fichas/lienzo-escenas-retos.md` (`disenador-niveles`). Este motor ya entiende sus reglas y sus
nombres. Por ahora se portaron **las tres escenas piloto**; el resto del catálogo va en una segunda
pasada.

### 9.1 Pantalla y herramientas

- **Lienzo a pantalla completa (1280×720)**. Los fondos de las escenas v2 se escriben en 16:9
  (`"tamano": [1280, 720]`). `generar_pinta.py` tiene `reencuadrar_169()` para portar los fondos v1:
  ensancha cielo y suelo sin deformar soles ni lagos.
- **Láminas de 824×530** de las zonas 2-5 (y el mosaico): se **escalan de forma uniforme y se centran**
  en `AREA_SEGURA` (128-1100 × 168-712), la parte del papel que no tapan los botones. Las simetrías
  (espejo, mandala) usan el centro de la lámina encuadrada.
- **Dock** de botones redondos sin texto en la columna izquierda. Cada botón abre un **popup**:
  - Grupos: Colores (muestra el color actual), Pinceles, Cosas que se mueven (vivos, lugares y caminos,
    en filas), Decorados, Trajes (viste a Coco) y Lupa.
  - Solo hay un popup abierto a la vez. Se cierra al elegir o al tocar fuera, y ese toque no pinta.
  - Un grupo con una sola herramienta (el pincel de Maxi) la elige directo, sin popup.
  - Coco nombra cada grupo la primera vez.
  - El platito de mezcla de Sofía (zona 3) vive dentro del popup de colores, que no se cierra mientras
    se echan gotas.
- **Tamaños**:
  - Maxi: botones de 100 px, a lo más 3 grupos (sus decorados van dentro de "Cosas") y sin zoom.
  - Nicole y Sofía: dock de 84 px y colores de 72 px.
- **Esquinas**:
  - arriba a la izquierda, salir y la tarjeta de inspiración;
  - arriba a la derecha, los objetivos;
  - a la derecha, Coco, "mostrar a Coco" y Cometa.

  *Diferencia con el catálogo §1.7*: allí los objetivos van arriba a la izquierda y la barra abajo. El PO
  pidió el dock en una esquina y la columna izquierda quedó para el dock. Por eso, por delegación, los
  objetivos pasaron a la derecha y la inspiración a la izquierda.
- **Zoom** (en las hojas con tema de Nicole y Sofía lo reemplaza el **mundo grande**, §12):
  - La lupa alterna 1× y 2× (catálogo §1.7): con 1× queda armada y el siguiente toque acerca al doble
    ahí. "Ver todo" aparece con zoom.
  - La rueda del mouse y la pinza de dos dedos quedan como extra.
  - Con zoom, el pincel, los sellos, los stickers nuevos, los caminos y los imanes conservan su tamaño
    **en pantalla**: en el mundo se dividen por el zoom. Alejado (zoom < 1, solo en el mundo grande),
    lo nuevo usa el tamaño del zoom 1 (§12.3).
- **Dos dedos nunca pintan**, tampoco en Maxi. El segundo dedo deshace lo que hizo el primero en ese
  trazo (pintura, stickers, camino a medias, arrastre), y sigue así hasta levantar todos los dedos.
- **Inspiración**: la escena de ejemplo se dibuja con nuestros stickers a partir del tema (`inspiracion`:
  `voz`, `elementos` [{sticker, pos, escala}] y `caminos`).
  - Se abre grande al empezar la hoja mientras Coco la narra (mínimo 5 s) y después se encoge a la
    tarjeta. Tocar la tarjeta la agranda otra vez.
  - En las zonas 2-5, la tarjeta muestra el modelo de la lámina o la nave.

### 9.2 Clases de stickers, caminos y viajes

`stickers.gd` define la clase por defecto (catálogo §1.1). Una escena puede cambiarla con sus listas
`vivos`, `lugares` y `decorados`.

| Clase | Qué hace |
|---|---|
| `vivo` | Se sube a un camino si se suelta a ≤ 60 px de él (84 en Maxi) o sobre un lugar donde nace un camino. Lo recorre y, en cada lugar, emite `llegada`, hace una pausa de 1,1 s y el lugar reacciona. Después sigue por otro camino de ese lugar si hay (**R4**: el más reciente que no sea por el que vino) o vuelve. Se baja al volver a su lugar de partida (o tras 8 tramos). En un camino cerrado da vueltas (`vuelta`). Arrastrarlo lo baja |
| `lugar` | Destino. Una punta de camino a ≤ 70 px de su borde (120 en Maxi) se pega (**R1**, imán). Los **lugares de fondo** (`lugares_fondo`: {id, ancla, radio, region, lineal}) son invisibles y usan el polígono de su región; la punta queda donde se tocó adentro, o en el borde más cercano. El río es `lineal`: acepta caminos en cualquier punto de la orilla. Un lugar ya puesto (`puestos`) no cuenta para `poner`. Mover un lugar lo despega de sus caminos |
| camino | Herramientas `camino_<tipo>` (sendero, camino, rieles, cerca, arcoiris, estelar, destellos, guirnalda). Un trazo que termina a ≤ 60 px de su inicio, lejos de los lugares, se cierra y forma un circuito (**R5**; en Maxi, 150 px y largo ≥ 500). **Guirnalda y cerca no llevan viajeros**. La cerca se agregó por delegación: es el corral de `encerrar`, no un camino para pasear |
| `decorado` | Solo visual. Participa en combinaciones |

- **R2 en Semilla** (`auto_subir`): al trazar un camino, el vivo libre más cercano salta solo a su
  punta. Un vivo nuevo también salta al camino si ya hay uno.
- **R3**: la llegada se registra con el lugar de partida y el de llegada. El regreso cuenta en sentido
  contrario.
- **Tocar un sticker con una herramienta de sticker lo mueve, no pone otro encima** (comportamiento v1).
  Por eso, en el juego, "soltar el pony sobre el establo" y "juntar ingredientes" se hacen arrastrando.

### 9.3 Combinaciones (catálogo §1.4 y §5)

Van en el **nivel** (`combinaciones`): son universales.

- **Contacto**: al soltar un sticker, su centro queda a ≤ 0,6 × (radio A + radio B) del otro, o dentro de
  un lugar de fondo (huevo + volcán). Las recetas de 3 se buscan en 200 px. Un vivo que llega a un lugar
  también prueba la receta vivo + lugar.
- **`en`**: la región o zona del tema (`zonas`: nombre → rect) donde debe ocurrir; si no existe, vale
  en cualquier parte.
- **`modo`**:
  - `efecto`: el resultado aparece animado, crece y "respira", y no cuenta para `poner` (el arcoíris).
  - `consume`: se van los de `consume`, o todos. Ejemplo: dos nubes dan una nube de lluvia, que sigue
    combinando (cadena C02 → C01).
  - `transforma`: el primer ingrediente se convierte (huevo → dino bebé, pony → unicornio).
- Un resultado que no es sticker (`pony_feliz`, `jardin`) es solo un efecto, con destellos y voz.
- Implementadas en los pilotos: C01, C02, C03, C07, C15 y C30.

### 9.4 Objetivos obligatorios

`objetivos` reemplaza a `retos` en el JSON. Cada objetivo trae `voz` e `icono`. El icono es un id de
sticker, `camino:<tipo>`, `colores`, `circuito`, `encargo`, `?`, o una lista: 2 = A → B y 3 = A + B =
resultado.

| Tipo | Se valida con |
|---|---|
| `llegadas {viajero, desde, hasta, n}` | Eventos `llegada` reales: `n` instancias distintas (`"dino"` vale para cualquier dino) |
| `conectar {a, b, camino?}` | Un camino con una punta pegada a cada lugar |
| `circuito {viajero, vueltas}` | Eventos `vuelta` de una misma instancia |
| `poner {sticker, n, en_zona?}` | Instancias presentes; `en_zona` acepta región, zona del tema o un sticker-lugar |
| `combinacion {resultado}` | Evento `combinacion` ocurrido |
| `pintar_zona {zona, color?, distintos?}` | Región tocada con el balde y color con nombre más cercano; `zona` puede ser una lista |
| `colores {n}` | Colores distintos usados en la hoja |
| `orden {viajero, lugares[]}` | Historial de llegadas de un mismo viaje continuo (se reinicia al subirse), con paradas extra permitidas |
| `encerrar {sticker, n, con?}` | Un camino cerrado del tipo `con` cuyo polígono contiene `n` instancias |
| `usar {herramienta, n}` | Trazos o estampados con esa herramienta; la purpurina cuenta la lluvia dorada |
| `encargo` | El encargo de la hoja, según §7.1 del catálogo (abajo) |

`encargo` según el tipo de hoja:

| Encargo | Se cumple cuando… |
|---|---|
| Láminas por zonas (pinta_coco, colorear_zonas, decora_ala, viste_coco, mezcla_paleta) | Todas las regiones tocadas. Maxi en el ala: sin las estrellitas |
| Mosaico | Todas las celdas bien pintadas |
| Coco pide | Los pedidos cumplidos |
| Sellos (Maxi) | 3 dinos estampados |
| Dedo mágico | Un trazo cruza de arriba abajo |
| Espejo / mandala | Cobertura de la guía ≥ 60 % / 75 % (muestreo en grilla de 16 px) |

La meta se recalcula si cambia la lámina (otro traje de Coco).

- **Cola** (§1.6):
  - Maxi ve 1 objetivo a la vez; Nicole y Sofía, 3.
  - Al cumplir uno hay una celebración corta y entra el siguiente.
  - Los objetivos se evalúan **desde el inicio, aunque no estén a la vista**. El que ya estaba cumplido
    entra con el check, Coco dice "¡eso ya lo habías hecho!" y se va en 1 s.
  - Un objetivo cumplido no se descumple.
  - Tocar una tarjeta hace que Coco repita la consigna y muestre la pista.
  - Tarjetas de 180×150 (Maxi) y de 130×110, sin números: la cantidad va como puntitos ●●○. Debajo, una
    fila de estrellitas con el total de la hoja.
- **Bloqueo**: "mostrar a Coco" no existe hasta cumplir todos los objetivos. Con pendientes,
  `mostrar_a_coco()` no pasa la hoja y Coco repite el objetivo que falta. Al cumplir todos hay confeti,
  Coco baila, suena `hoja_lista` y aparece el botón con rebote. `segundos_mostrar` desaparece de los
  niveles.
- **Pista fantasma**: escalera del §6.2 por segundos sin avance.

  | Nivel | Maxi | Nicole | Sofía |
  |---|---|---|---|
  | 1. Voz y la tarjeta late | 8 s | 20 s | 45 s |
  | 2. Brilla el grupo del dock | 8 s | 35 s | 75 s |
  | 3. Mano fantasma | 15 s | 50 s | 105 s |
  | Repetición | cada 12 s | cada 30 s | solo a pedido |

  Qué reinicia el reloj (§6.1):
  - Maxi: solo el avance del objetivo activo.
  - Nicole: el avance de cualquier objetivo visible. Además, el reloj se pausa 10 s tras cada toque.
  - Sofía: cualquier toque.

  Tocar a Coco da la mano fantasma al instante. Qué muestra la mano, según el objetivo:
  - un camino punteado animado, con el viajero en fantasma, de A a B o por el camino que ya existe;
  - el sticker que falta, translúcido y latiendo, en su lugar de la inspiración;
  - la mano llevando un ingrediente al otro;
  - el óvalo del corral o del circuito;
  - el borde de la región, la celda del mosaico o la guía, parpadeando.
- **Válvula de Maxi** (§6.4): tras 3 manos en el mismo objetivo, su siguiente toque completa el paso
  (pone los stickers o traza el camino).

### 9.5 Escenas piloto (`generar_pinta.py`)

| Hermano | Escena | Objetivos |
|---|---|---|
| Maxi | `parque_dinos` (§2.1): volcán y lago de fondo, T-rex y espinosaurio, huevo, sendero | Poner 2 T-rex · conectar volcán-lago · huevo + volcán = dino bebé |
| Nicole | `granja_ponys` (§3.1): granero ya puesto, río lineal, cerca y sendero | Poner 2 ponys · conectar establo-río · 2 llegadas establo → río · arcoíris · pony + manzana · corral con 2 ponys |
| Sofía | `ciudad_ponys` (§4.1): casas, castillo y granero, río lineal, sendero y puente arcoíris | 12 objetivos de 9 tipos: poner ×2, conectar ×2, llegadas ×2, combinación ×3 (nube de lluvia, arcoíris, unicornio), circuito, pintar el río de turquesa y orden casa → castillo → río |

- La zona 1 tiene hoy **una hoja** por hermano (el piloto) y `opciones_tema` 1. Los temas v1 siguen en
  `TEMAS` del generador, y sus voces siguen en disco para el port.
- Las zonas 2-5 traen `objetivos: [{"tipo": "encargo", "voz": <intro>}]`. Los objetivos extra del
  catálogo (§7.2-7.4) van en la segunda pasada.
- Stickers nuevos dibujados en código: `nube_lluvia` y `dino_bebe`, más `lago` y `rio` para los
  pictogramas.
- `verde_oscuro` faltaba en `colores_lienzo.gd` y la paleta mostraba un segundo blanco. Quedó
  corregido.

### 9.6 Destellos

Fórmula nueva (`calcular_destellos`):

- **10 por hoja mostrada**;
- **36 por hoja, repartidos entre sus objetivos**: Maxi 3 × 12, Nicole 6 × 6, Sofía 12 × 3; en las zonas
  2-5, el encargo vale 36. Es el mismo premio por hoja para los tres, porque cada uno se esfuerza según
  su edad;
- **1 por color distinto** usado (hasta 10).

Si el contenedor fija `destellos_fijos` (100 por estación, HE-40 §2.3), manda ese valor. Desaparecen los
+5 de los retos v1.

### 9.7 Verificación

- `qa_test_lienzo.gd`, reescrito para las 15 rutas y el epílogo de la batalla en solitario. Revisa:
  - tamaños del dock, de las tarjetas de objetivo y de los popups;
  - que haya un solo popup abierto y que se cierre al elegir o al tocar fuera;
  - las voces;
  - que la hoja se bloquee con objetivos pendientes y se desbloquee al cumplirlos;
  - la pista fantasma;
  - las tres escenas piloto, jugadas con eventos reales: imán, auto-subida, llegadas, combinaciones
    (con cadena), corral, circuito, pintar zona y orden;
  - el zoom con lupa y rueda (pincel y sticker del mismo tamaño en pantalla);
  - que dos dedos no pinten;
  - los encargos de las zonas 2-5;
  - el PNG de 1280×720 y `completado`.

  Resultado (17-Oct-2026, Godot 4.7.1): **711 OK / 0 fallos**.
- `capturar_lienzo_tema.gd`, reescrito y corrido en ventana para cada piloto. Toma la inspiración
  abierta, la escena armada, el popup de cosas, la pista fantasma y, en Nicole y Sofía, el popup de
  colores y el zoom.
- Voces nuevas: 58 líneas con el TTS provisional de Windows (gratis), listadas en `lineas_tts.tsv`:
  inspiración, objetivos, llegadas, combinaciones, cola y grupos del dock. Las oficiales requieren
  `--estimar` y el OK del PO.

### 9.8 Pendientes

- Portar el resto del catálogo: 12 escenas de la zona 1 y los objetivos extra de las zonas 2-5 (§7).
  Implementar `parte_encargo`, `adivinar` y `trazo_unico`, que ya están definidos en el catálogo.
- Los efectos de las combinaciones (humito, constelación, rugido…) y los stickers nuevos de §8.1
  (cuartel, cantante, barco, copa…). El arte final va en HE-13.
- Que los vivos de la tarjeta de inspiración anden en loop (§1.7); hoy la tarjeta es estática.
- Modo equipo "una parte por turno" (HE-70). El epílogo de la batalla carga y se juega en solitario
  con el objetivo `encargo`; sus voces siguen en `PENDIENTE`.
- Auditoría UX (`experto-ux-parvulo`) de tres puntos:
  - el contacto de 0,6 para combinar, que pide superponer bastante;
  - tener que arrastrar para soltar sobre un lugar;
  - el tamaño de los imanes.
- Playtest con los tres.

## 10. Física, sol, deshacer y reiniciar (17-Oct-2026)

Pedido directo del PO después de que los niños jugaron el lienzo v2 (les fascinó). El PO aprobó el
diseño; los detalles menores se decidieron por delegación (§10.8). Vale para todas las hojas con tema;
deshacer y reiniciar valen también para las láminas, el mosaico y las simetrías de las zonas 2-5.

### 10.1 Gravedad: los que pesan caen con "¡puff!"

- **Física por sticker** (`Stickers.fisica(id)`), aparte de la clase vivo/lugar/camino/decorado:
  `pesa` o `vuela`. Todo lo que no está en `Stickers.VUELAN` pesa. Una escena puede cambiarlo con sus
  listas `pesan` y `vuelan`.

  | Física | Stickers |
  |---|---|
  | `vuela` | nube, nube_lluvia, estrella, sol, luna, globo, arcoiris, cohete, planeta, lechuza, escoba, destello, corazón, nota, varita, foco. Ya previstos para el catálogo: pájaro, cometa, constelación, constelacion_dino, libro_volador, estrella_fugaz, fuegos_artificiales |
  | `pesa` | Todo lo demás: dinos (trex, spinosaurio, carnotauro, dino_bebe), huevo, pony, unicornio, jirafa, gatito, perrito, gerbo, pingüino, vehículos (auto, bus, bomberos, tren, carroza), casa, casa_valpo, castillo, granero, volcán, montaña, moai, cactus, palmera, árbol, flor, copihue, roca, cono, bandera_meta, bandera_chile, fuego, manzana, pastel, regalo, ovillo, caldero, libro, sombrero, corona, vestido, zapato, micrófono, parlante, hueso, pelota, lago, río |

- **Cielo**: la zona `cielo` del tema (`zonas`). Si falta, se deduce del fondo: va desde arriba hasta
  donde empiezan las regiones que tocan el borde de abajo (el pasto). `parque_dinos` ahora declara
  `"zonas": {"cielo": [0, 0, 1280, 440]}` (catálogo §2.1). Sus regiones `cielo` ocupan toda la hoja,
  así que antes `en_zona cielo` valía en cualquier parte.
- **Cuándo cae**: al soltar un sticker que pesa (nuevo o arrastrado) con la **base** (los pies:
  centro + 0,43 × lado) dentro del cielo. Antes se intenta subir a un camino: un vivo soltado sobre un
  camino en el cielo (puente arcoíris) se sube y no cae. En Maxi, si ya hay un camino, el vivo nuevo
  salta a él (R2).
- **Dónde aterriza**: en la primera superficie bajo sus pies. Puede ser una región de suelo (las que
  bajan más que el cielo: colinas, pasto, pradera, río, volcán) o un lugar (castillo, casa, granero,
  volcán de fondo). Si no hay ninguna, aterriza en el borde de abajo del cielo. Si ya está apoyado
  (sobre la colina o sobre el volcán), no cae.
- **Cómo cae**: con aceleración (2600 px/s²; Maxi, 1500, más lento) y estirado. Al llegar se aplasta,
  da un rebote chico y se acomoda (squash & stretch con pivote en la base, en `sticker_vivo.deformar`).
  Suelta una nubecita de polvo y suena "¡puff!" (`polvo.ogg`). **Nunca desaparece.**
- **Maxi**: suena un silbidito al empezar a caer y un "boing" al aterrizar (`polvo_boing.ogg`). Su
  polvo es más grande, salen estrellitas y Coco salta.
- **Después de aterrizar** sigue como cualquier sticker soltado: intenta subirse a un camino (y en
  Maxi, R2), se revisan las combinaciones y se miden los objetivos (`poner`, `en_zona`...).
- **Se puede atrapar en el aire**: si se agarra mientras cae, se mueve. Si se suelta ahí mismo, sigue
  cayendo.
- **Sin gravedad**: una escena sin cielo (la fiesta de gatitos, el concierto) o del espacio. Es espacio
  si el tema trae `"gravedad": false`, si su id dice "espacio" o "espacial" (`espacio`,
  `mision_espacial`) o si tiene una zona o región `espacio`. Allí todo flota. El vaivén suave quedó
  como opcional y no se hizo.
- **Objetivos del cielo** (revisión de las 15 escenas del catálogo):
  - Todo lo que se pide en el cielo vuela: `poner estrella en_zona cielo` (mision_espacial), C01
    sol + nube de lluvia, C06 tres estrellas (espacio) y C10 estrella + castillo (la estrella se lleva
    al castillo).
  - Las escenas espaciales no tienen gravedad.
  - Los sellos `sello_estrella en_zona cielo` de las zonas 2-5 son estampados de pintura, no stickers
    con física.
  - Los vivos que viajan por caminos no sienten la gravedad: un puente arcoíris por el cielo funciona.
  - `qa_test_lienzo` verifica en cada piloto que nada de lo que se pide en el cielo pese.
  - **Riesgos para portar el catálogo**:
    - `bomberos`, `poner fuego en_zona casa`: el fuego pesa. Si el techo de la casa queda dentro de la
      zona `cielo`, el fuego soltado arriba aterriza sobre la casa, pero su centro puede quedar fuera
      del radio de la casa. Hay que dejar el techo fuera del cielo o declarar `"vuelan": ["fuego"]`
      en la escena.
    - `tren_chile`: la zona `cielo` no debe incluir la franja de la cordillera.

### 10.2 El sol solo vive en el cielo

- Aplica en escenas con cielo que no son espacio. Si el sol se suelta con el **centro** fuera del cielo:
  - Los stickers a ≤ 180 px quedan **tiznados**: tinte oscuro (`self_modulate`), temblorcito y humito.
  - Salen chispitas y suena un chisporroteo (`chisporroteo.ogg`).
  - El sol pone cara de "¡ups!" (ojos redondos, boca en "o" y una gotita).
  - Coco dice "¡Uy, qué calor! El sol vive en el cielo." (`comun/sol_quema`, a lo más una vez cada
    4 s) y salta.
  - El sol tiembla y vuelve volando en arco, dando una vuelta (1,1 s). Llega a un punto libre del cielo
    dentro del área sin botones, lejos de los otros stickers y cerca de donde estaba.
- **Opción A del PO, tiznado temporal**: a los 3 s cada tiznado se sacude, suelta un polvito y vuelve a
  su color. Nada se destruye y la pintura hecha a mano no se quema (solo se tiznan stickers).
- El sol que vuelve al cielo **sigue combinando**: al llegar se revisan las combinaciones
  (sol + nube de lluvia = arcoíris).
- Se puede atrapar al sol mientras vuela.

### 10.3 Deshacer ("ir atrás")

- **Botón**: flecha curva naranja hacia atrás, sin texto, del tamaño del dock (Maxi 100 px; Nicole y
  Sofía 84 px). Va arriba, a la derecha de la tarjeta de inspiración, en x = 340.
- **Qué deshace**: la última acción. Cuenta como acción un trazo de pincel o goma, el balde, un sello o
  sticker puesto, un sticker movido, un camino trazado y, por delegación, editar un sticker con la
  barra (achicar, agrandar, girar, espejo, borrar).
- **Cómo**: antes de cada acción se guarda una **foto** del estado:
  - los stickers (el mismo nodo y sus propiedades);
  - los sellos vivos;
  - los caminos y sus puntas;
  - los viajes en curso;
  - los colores de las regiones;
  - las celdas del mosaico;
  - la pintura, solo si la acción pintó. Se guarda comprimida con ZSTD: ~15 KB y ~1 ms.

  Al deshacer se **reusan los nodos que siguen vivos**, así los objetivos y los viajes los reconocen.
  Los que se fueron (consumidos por una combinación, borrados) se recrean con un "pop". Lo agregado
  después de la foto se va en silencio.
- Una acción que no cambió nada (un toque suelto sobre un sticker) no gasta un paso.
- Dos dedos no dejan paso: el trazo ya se deshizo.
- **Límite**: 20 pasos.
- **Caída**: la caída no es un paso aparte. Deshacer el soltar devuelve el sticker a donde estaba
  **antes de que lo agarraran**, no al cielo. También corta las caídas, los vuelos del sol, los
  tiznados y los saltitos en curso.
- **Caminos con viajeros**: al deshacer un camino, sus viajeros se bajan (quedan los viajes de la foto).
- **No deshace objetivos ni destellos (GDD §6)**: viven en el motor y nunca se descumplen. Un color
  usado sigue contando para los destellos.
- Con el historial vacío el botón se ve apagado (45 % de opacidad). Igual responde al toque con un
  saltito y un "toc".

### 10.4 Reiniciar la hoja

- **Botón**: escoba de peluche, del mismo tamaño, a la derecha del de deshacer (con 28 px de
  separación).
- **Anti-accidente**: hay que **mantenerlo presionado 1,2 s**. Mientras tanto, un anillo turquesa se
  va llenando alrededor del botón. En el proyecto no había un patrón de confirmación; este es el nuevo.
  Si se suelta antes, el anillo se vacía, el botón rebota y Coco explica "Para empezar de nuevo, deja
  el dedo apretado en la escoba." (`comun/reiniciar_mantener`, a lo más una vez cada 8 s).
- **Al cumplirse**:
  - Una escoba gigante barre la pantalla de izquierda a derecha ("¡fuuush!", `fuuush.ogg`) y suelta
    nubecitas de polvo.
  - A mitad del barrido la hoja vuelve a como empezó: sin pintura ni stickers ni caminos puestos, con
    los colores, los lugares de fondo, los stickers puestos (el granero) y los caminos iniciales.
  - Coco dice "¡Fuuush! ¡Hoja nueva, limpiecita!" (`comun/reiniciar`).
- La foto de inicio se toma al terminar de preparar la hoja (`lienzo.fijar_inicio()`).
- El reinicio vacía el historial. **Los objetivos cumplidos y los destellos se mantienen**, y "mostrar
  a Coco" sigue visible si ya estaba.
- Los dos botones se esconden al mostrar el dibujo a Coco y en el selector de temas.

### 10.5 Archivos

- **Código**:
  - `stickers.gd`: `VUELAN` y `fisica()`.
  - `sticker_vivo.gd`: `deformar`, `temblor`, `expresion` ("ups") y `detener()`.
  - `lienzo.gd`: física, sol, efectos de polvo y humo en una capa del mundo, historial y reinicio.
  - `motor_lienzo_libre.gd`: botones, mantener presionado, escoba, SFX y voces.
- **Generador**: `generar_pinta.py`, con el cielo de `parque_dinos` y 3 voces nuevas en los 15 niveles.
- **SFX originales** (`componer_sfx_ui.py`): `polvo`, `polvo_boing`, `chisporroteo`, `rebobinar` y
  `fuuush`. La caída de Maxi reutiliza `fiuu`.
- **Voces provisionales** con el TTS gratuito de Windows (sin costo): `comun/sol_quema`,
  `comun/reiniciar_mantener` y `comun/reiniciar`.

### 10.6 Verificación (17-Oct-2026, Godot 4.7.1)

- **`qa_test_lienzo.gd`**: suite completa (15 rutas + epílogo), **854 OK / 0 fallos**. Casos nuevos:
  - **Clasificación** pesa/vuela.
  - **Cielo**: el de cada piloto (440, 300 y 290), y el deducido del fondo cuando falta la zona.
  - **Gravedad**: sin cielo no hay; en el espacio tampoco (por id, por `gravedad: false` o por zona
    `espacio`).
  - **Caída**: lo que pesa, puesto en el cielo, cae con aceleración, aterriza apoyado, no desaparece,
    emite el "¡puff!" (grande en Maxi) y deja polvo. Arrastrarlo al cielo lo hace caer otra vez, y
    arrastrar + caer es un solo paso.
  - **Lo que vuela** se queda, y lo que se pide en el cielo no pesa.
  - **Sol**: tizna ≥ 2 vecinos, pone cara de "¡ups!" y vuelve al cielo. A los 3 s los vecinos se
    limpian, la pintura no cambia y después hace arcoíris con la nube de lluvia.
  - **Deshacer**: pincel, balde, sticker puesto, sticker movido (el mismo nodo), camino con viajero, el
    límite de 20, el botón apagado, y que no se pierden objetivos ni destellos. En las zonas 2-5 se
    deshace el último trazo de cada hoja (láminas, mosaico, sellos de Maxi, dedo mágico, simetrías).
  - **Reiniciar**: un toque corto no borra; mantener barre; la hoja vuelve a los stickers y caminos
    iniciales sin pintura (granero puesto, río a su color); el historial queda vacío; objetivos y
    destellos se conservan.
- **`capturar_lienzo_tema.gd`**: corrido en ventana para los tres pilotos. Las capturas nuevas son
  caída, "¡puff!", tiznado, sol volviendo, limpios, anillo de la escoba, barrido y hoja reiniciada.
  Sin errores en consola.
- **`qa_test_voces.gd`**: las voces de pinta pasan. Las 20 fallas que reporta son de
  `emparejar/reto` (anteriores a esta tarjeta).
- **Guardado real**: se respaldó antes de correr nada. md5 `ff55e2f4abf17f25618fa7ee446b11b0`, intacto
  al final.

### 10.7 Pendientes

- **Playtest con los tres**:
  - ¿Maxi entiende el "mantener presionado" o necesita que Coco lo muestre con la mano fantasma?
  - ¿El tiznado de 3 s se lee como chiste y no como castigo?
- **Auditoría UX**: tamaño y lugar de los botones nuevos; Nicole y Sofía tienen la escoba a 28 px de
  la flecha.
- **Voces y arte**: voces oficiales de Coco para las 3 líneas (con `--estimar` y el OK del PO) y SFX
  finales si los provisionales no convencen.
- **Optativos**: vaivén suave en el espacio; humito propio del "¡uy!" del sol.
- **Port del catálogo**: revisar los riesgos de §10.1 en `bomberos` y `tren_chile`.

### 10.8 Decisiones por delegación

- Clasificación pesa/vuela de los ids dudosos:
  - **Vuelan**: varita (mágica), foco (cuelga del techo), nota, destello, corazón, cohete y planeta.
  - **Pesan**: fuego, manzana y el resto de los objetos de mano.
- La caída se decide por la base del sticker. El sol, en cambio, se decide por su centro.
- Se aterriza en la primera superficie (región de suelo o lugar). Si no hay, en el borde del cielo.
- Gravedad 2600 px/s². En Maxi es 1500, con polvo 1,45 veces más grande, "boing", estrellitas y Coco
  que salta.
- Espacio: por `gravedad: false`, por un id con "espacio"/"espacial" o por una zona o región `espacio`.
  Sin zona `cielo`, el cielo se deduce del fondo.
- Sol: tiznado a ≤ 180 px, 3 s, vuelo de 1,1 s a un punto libre del área sin botones.
- Deshacer:
  - con fotos, no con comandos;
  - 20 pasos, con la pintura comprimida en ZSTD;
  - la edición con la barra también se deshace;
  - un toque que no cambia nada no gasta un paso;
  - el botón apagado se ve al 45 % y sigue respondiendo con un saltito.
- Reiniciar:
  - mantener 1,2 s con un anillo, porque no había un patrón previo;
  - escoba que barre;
  - Coco explica si se suelta antes;
  - se conservan los colores usados (destellos) y los usos de herramientas.
- Ubicación de los botones: arriba, a la derecha de la tarjeta de inspiración (x = 340 y 340 + lado +
  28). Es la única franja libre que no tapa el área de las láminas, el dock, los objetivos ni a Coco.

## 11. Segunda tanda: borrar caminos, caminos finos, personajes y Coco en burbujita (17-Oct-2026)

Pedido del PO después de otra sesión de juego de los niños. Los detalles menores se decidieron por
delegación (§11.7).

### 11.1 Borrar un camino

- Se borra **entero**, nunca a medias, con una fila de "¡puff!" a lo largo y `puf.ogg`. Sus viajeros
  se bajan donde están; uno que pesa y estaba en un puente sobre el cielo cae (física §10.1). Queda en
  el historial de deshacer y se puede deshacer. Los objetivos ya cumplidos (`conectar`...) no se pierden.
- **Con la goma** (Nicole y Sofía): pasarla sobre un camino lo borra. Sirve tanto un toque como un
  arrastre.
- **Con el dedo quieto** (todos, y es la forma de Maxi, que no tiene goma):
  - Con la herramienta de camino elegida, mantener el dedo quieto sobre un camino 1,2 s (Maxi 1,5 s) lo
    borra.
  - Desde los 0,2 s el camino tiembla y se aclara, como aviso.
  - Si el dedo se mueve más de 14 px, se cancela y se traza un camino nuevo, como siempre.
  - Después del borrado, ese mismo trazo no traza ni pinta.
- **Anti-accidente**: pintar encima con el pincel nunca borra un camino. El borrado solo pasa con la
  goma o con el gesto quieto de la herramienta de camino: con esa herramienta, un dedo quieto no dibuja
  nada.

### 11.2 Caminos más finos y planos

- Todos los caminos se dibujan con un factor de ancho (`a`) sobre su sección v1: **0,55** para Nicole y
  Sofía y **0,7** para Maxi. El sendero pasa de 40 px a ~22 px (Maxi ~27 px).
- Se ven planos, desde arriba: borde fino (2,5 px por lado) y sin volumen. Los adornos mantienen su
  separación a lo largo del camino y tienen un tamaño mínimo (piedritas, durmientes y rieles, luces,
  estrellas, tablas de la cerca), así cada tipo se sigue reconociendo.
- Cada camino guarda su `ancho`, así que deshacer y el PNG lo respetan. Los iconos del dock siguen con
  ancho 1,0 para que se lean en chico.
- **Lo táctil no cambia**: R1 (imán), R2 (subirse) y R5 (cerrar) usan las mismas distancias de antes.
  La zona para tocar un camino (borrar) es su mitad dibujada + 10 px, como mínimo 22 px de pantalla.

### 11.3 Los personajes como stickers ("amigos")

| Id | Arte | Física |
|---|---|---|
| `maxi`, `nicole`, `sofia` | Retratos oficiales (`*_base.png`) | pesa |
| `papa` | **Provisional**: recorte de `anclas/papa_referencia.png` | pesa |
| `coco` | `coco_base.png` | pesa (camaleona) |
| `toby` (anfitrión de Animalia) | **Provisional**: recorte de `anclas/toby_referencia.png` | pesa (perrito) |
| `cometa` | `cometa_base.png` | vuela (flota y rebota, GDD §2) |
| `coleccionauta` | **Provisional**: recorte de `anclas/coleccionauta_referencia.png` | vuela |

- **Clase `vivo`**: pasean por los caminos y llegan a lugares. Al tocarlos dan unos pasitos (los que
  pesan) y nombran su voz (`stickers/<id>`).
- **Dibujo**: con su textura, recortada del margen transparente y con los pies en la base. Son 1,35
  veces más grandes que un sticker común (son altos y delgados). En el PNG se rasterizan aparte
  (espejo y giro incluidos), porque el `Grabador` es vectorial.
- **Dónde**: `amigos` está en el **nivel** (`generar_pinta.py`), así que vale para todas las escenas
  con tema.
  - **Nicole y Sofía**: grupo propio "Amigos" en el dock. Su icono es la cara del hermano que juega,
    que va primero en la lista. Coco nombra el grupo la primera vez ("¡Amigos!").
  - **Maxi**: mantiene 3 botones en el dock. Sus amigos van en "Cosas", en filas propias.
  - Con 6 grupos el dock llega a y = 672. "Ver todo", que antes iba debajo, ahora va **a la derecha de
    la lupa**.
- **Recortes provisionales**: `herramientas/extraer_base.py` sobre la vista frontal de cada ancla. Al
  Coleccionauta se le tomó el fondo solo del costado derecho, porque la mano que saluda en la vista
  vecina ensuciaba el gris. Quedaron en `assets/sprites/personajes/*_provisional.png`.
- **Pendientes para `disenador-personajes`**: el arte de juego de papá, el Coleccionauta y Toby, y el
  arte de los anfitriones que todavía no tienen: Pulpo DJ Octavio, Búho Profesor Plumas, Dragoncita
  Lila y Nube Mimi.

### 11.4 Coco como burbujita

- Coco ya no ocupa un lugar fijo. Vive en una **burbujita redonda** con su cara y una colita de globo
  de diálogo. Es el mismo `TextureRect`, con su **cresta que sigue imitando colores**, recortado en
  círculo con `clip_children`.
- **Posición**: centro (1190, 302) y radio 70. Queda en la columna derecha, debajo de las tarjetas de
  objetivos y arriba de "mostrar a Coco": no tapa el objetivo que narra (el arnés lo verifica).
- **Cuándo aparece**: con un "pop" cada vez que Coco habla (`_reproducir_voz`) o celebra
  (`_reaccion_anfitriona`: saltos, baile, el salto de Maxi al caer un sticker). Se queda mientras dura
  la voz más 0,7 s y se va sola encogiéndose. El resto del tiempo **no ocupa espacio**.
- Al mostrar el dibujo, Coco se queda en su burbuja mientras celebra.
- **Tocar a Coco**: mientras la burbuja está visible, tocarla da la pista fantasma, como antes. Cuando
  no está, la forma equivalente es **tocar la tarjeta del objetivo actual, que repite su voz y muestra
  la pista** (ya existía, §9.4). Cometa también repite la instrucción.
- El lienzo de Pinta no tiene un tutorial aparte. "Mostrar a Coco" es un botón propio y no dependía de
  Coco visible.

### 11.5 Voces nuevas

Provisionales, con el TTS gratuito de Windows:
- `comun/grupo_amigos`;
- `stickers/maxi`, `nicole`, `sofia`, `papa`, `cometa`, `coco`, `toby` y `coleccionauta` (por ejemplo,
  "¡Toby, el perrito astronauta!").

### 11.6 Verificación (17-Oct-2026)

- **`qa_test_lienzo.gd`**, suite completa (ver el resultado en el resumen de la entrega). Casos nuevos:
  - **Grosor**: por perfil, y el camino lo guarda.
  - **Tocar un camino**: se puede 8 px fuera del dibujo.
  - **No se borra**: al pintar encima con el pincel, ni con un toque corto de la herramienta de camino.
  - **Dedo quieto**: borra el camino entero sin trazar otro, con un amigo de viajero que se baja y una
    fila de "¡puff!". Se deshace.
  - **Goma**: borra el camino entero y se deshace.
  - **Amigos**: son vivos, tienen voz y la física correcta. Nicole y Sofía tienen su grupo con su
    personaje primero, el dock cabe y "ver todo" va al lado de la lupa. Maxi mantiene 3 botones y su
    popup cabe.
  - **Amigos en el cielo**: el hermano cae (o, en Maxi, salta al camino por R2) y Cometa flota. El PNG
    rasteriza el arte de papá girado y espejado.
  - **Burbuja de Coco**: aparece al tocar el objetivo, no tapa tarjetas ni "mostrar", se va sola sin
    voz, vuelve con una celebración y, al tocarla, da la pista.
- **`capturar_lienzo_tema.gd`** en ventana, con capturas nuevas: popup de amigos, amigos en la escena,
  aviso de borrar camino, camino borrado, Coco oculto y Coco hablando. Sin errores en consola.

### 11.7 Decisiones por delegación

- **Borrar un camino**:
  - con la goma, o con el dedo quieto con la herramienta de camino: 1,2 s, y 1,5 s para Maxi;
  - siempre entero;
  - los viajeros se bajan, y los que pesan caen si estaban en el cielo;
  - los caminos iniciales también se pueden borrar (reiniciar los devuelve).
- **Ancho de los caminos**: 0,55 (0,7 para Maxi). Los adornos tienen un mínimo de 0,6-0,75 y la cerca
  conserva su altura. Las distancias táctiles no cambian.
- **Personajes**:
  - Física: pesan los hermanos, papá, Coco y Toby; vuelan Cometa y el Coleccionauta (pedido del
    coordinador; el arte del Coleccionauta tiene pantuflas, pero en el cuento recorre la galaxia).
  - Escala 1,35.
  - El hermano que juega va primero en la lista.
  - En Maxi van dentro de "Cosas".
  - Arte provisional recortado de las anclas.
  - Las voces de nombre llevan un apodo según el rol del GDD §2 (explorador, artista, capitana).
- **Burbuja de Coco**:
  - radio 70 y centro (1190, 302), con 0,7 s de margen;
  - sin sonido de "pop", para no saturar con cada voz;
  - aparece también en las celebraciones;
  - cuando no está, la consigna se repite tocando la tarjeta del objetivo.

### 11.9 Jinetes: subir personajes a animales y vehículos

Pedido textual del PO: "si uno de los personajes lo combino con otro, se deben fusionar, por ejemplo
debo poder subir a sofia o maxi a un poni o a un dinosaurio; si los subo a un auto o camion deben quedar
sentados arriba". La spec la decidió el coordinador por delegación y aquí se registra.

- **Jinetes**: todos los personajes con arte (`Stickers.es_jinete`), es decir, el grupo de amigos.
  Un anfitrión nuevo que entre a `PERSONAJES` ya es jinete.
- **Montables** (`Stickers.MONTABLES`), con sus asientos en unidades de r (= lado × 0,45) desde el
  centro:
  - **En el lomo**: pony, unicornio, jirafa, T-rex, espinosaurio y carnotauro.
  - **Arriba, en el techo**: auto, bus (2 asientos), camión de bomberos (2), tren (cabina y caldera) y
    carroza.
- **Sentado**: el jinete se ve de la cintura para arriba (66 % superior del arte), con la cadera en el
  asiento, a 0,75 de su tamaño. Así se lee "sentado" tanto en el lomo como en el techo.
- **Cómo se monta**:
  - Basta soltar el jinete encima o cerca de un montable con asiento libre, o soltar el montable junto
    a un jinete libre (la fusión funciona en los dos sentidos). La zona de snap es el radio del
    montable, ×1,5 en Maxi.
  - Al subirse, el jinete se acomoda en el asiento con un squash, salen destellitos y suena "¡hop!"
    (`blup.ogg` a tono 1,3).
  - También se sube si cae del cielo sobre un montable, o si se pone nuevo encima de uno.
- **Juntos**:
  - Cada cuadro el jinete se acomoda en su asiento (`_seguir_monturas`): sigue la posición, el espejo,
    el giro y el saltito del montable.
  - Por eso va con él cuando el montable pasea por un camino, cuando se arrastra y cuando cae por la
    gravedad. Caen y aterrizan juntos y el "¡puff!" no le hace nada raro al jinete.
  - Un jinete montado no se sube solo a caminos ni cae por su cuenta.
- **Un jinete por montable**: el segundo se queda al lado, como antes. Los vehículos grandes tienen
  dos asientos.
- **Bajarse**: arrastrar al jinete lo baja; si se suelta ahí mismo, vuelve a subir. Arrastrar el
  montable se lleva al jinete.
  - **Toques**: el jinete sentado solo se agarra por la parte que asoma (centro 0,75 de su alto sobre el
    asiento, radio ≥ 30 px). Tocar el lomo o el centro agarra al montable.
- **Goma**: borra lo que se tocó. Si se borra el montable, el jinete se baja y, si quedó en el aire,
  cae.
- **Montable que se transforma** (pony + varita = unicornio): el jinete se sube al unicornio nuevo.
- **Deshacer y reiniciar**: cada montaje es un paso del historial; la foto guarda las parejas. Deshacer
  baja o vuelve a subir al jinete, y reiniciar vuelve a la hoja sin parejas.
- **Sol**: el tiznado alcanza a la pareja completa.
- **Objetivos**: no cambian. `poner X en_zona` sigue contando al montable aunque lleve jinete.
- **Objetivo opcional nuevo** `montar {jinete?, montura?}` ("sube a alguien a un pony"): no está en
  ninguna escena obligatoria. El motor lo registra con el evento `montar`.
- **PNG**: el jinete sentado se rasteriza recortado y achicado alrededor de su base.
- **Verificación**: `qa_test_lienzo` cubre los casos nuevos en los tres pilotos:
  - clasificación de montables y jinetes;
  - montar, con su paso del historial y el objetivo opcional;
  - mover juntos (arrastre y paseo por el camino);
  - deshacer el movimiento y deshacer el montaje;
  - desmontar;
  - un solo jinete por pony;
  - caer juntos desde el cielo;
  - bus con dos jinetes sentados arriba;
  - goma sobre el jinete y su deshacer.

  Capturas en ventana `*_22_jinetes` (hermano sobre pony, dino, auto y bus, con papá en el segundo
  asiento) y `*_23_jinete_se_mueve` (pony arrastrado o paseando con su jinete).
- **Pendiente**: ajustar los asientos con arte final (HE-13) y que la UX audite si Maxi entiende el
  "soltar encima".

### 11.10 Pendientes

- **Arte para `disenador-personajes`**: arte de juego de papá, el Coleccionauta y Toby, y el arte de
  los anfitriones Octavio, Plumas, Lila y Mimi (para sumarlos a `AMIGOS`).
- **Voces oficiales** de las 9 líneas nuevas: con `--estimar` y el OK del PO.
- **Auditoría UX**:
  - ¿Maxi descubre el "dedo quieto" para borrar caminos, o hace falta que Coco lo muestre con la mano
    fantasma?
  - ¿8 amigos son demasiados para Maxi en "Cosas"?
  - ¿Se entiende la burbuja de Coco sin su cuerpo?
- **Playtest con los tres**.

## 12. Mundo grande y zoom alejable (17-Oct-2026)

Pedido directo del PO: *"deberíamos iniciar en la imagen con mucho zoom, para que los stickers y
elementos como casas se vean más pequeños; así, si deciden hacer zoom inverso, el lienzo se pueda
ampliar para que puedan dibujar más cosas"*. Las decisiones de detalle se tomaron **por delegación**
del PO (se infieren de sus pedidos anteriores) y quedan registradas acá.

### 12.1 Qué cambia y para quién

- **Nicole y Sofía, hojas con tema** (perfiles con `zoom_permitido`): el mundo mide
  `escala_mundo` = 2 pantallas por lado, **2560×1440**. El JSON puede fijar otro `escala_mundo`.
- **Maxi** (`semilla`): sin cambios. Mundo 1×, sin zoom, sin paseos de cámara.
- **Hojas de colorear de las zonas 2-5** (láminas 824×530, mosaico, espejo, mandala): siguen en 1×
  con su lupa de siempre, por delegación. Son páginas para colorear enteras: empezar viendo un cuarto
  no tiene sentido ahí.

### 12.2 Qué se escala y qué no

- **Se escala ×2** (llena el mundo): el fondo y sus regiones, el contorno del fondo
  (`escala_trazo`, para que con la hoja entera a la vista se vea como antes), las `zonas` del tema
  (cielo y otras), los lugares de fondo (ancla y radio), los `puestos`, los caminos iniciales, el cielo
  y la gravedad (que salen del fondo y de las zonas), las posiciones sugeridas de las pistas (las de la
  inspiración) y los centros por defecto de las pistas de corral y circuito.
- **No se escala**: los stickers, los sellos, el pincel y los caminos. Al zoom 1, el de arranque, miden
  en pantalla lo mismo que antes; en el mundo quedan "más chicos".
- **Constantes en px del mundo que no cambian**, porque se miden contra stickers que no crecen: el
  radio del tiznado del sol (180), la gravedad y la velocidad de los viajeros. Una caída desde más alto
  dura un poco más (raíz de 2), y se ve igual en pantalla.
- **Tarjeta de inspiración**: es una *idea* de la hoja entera, no un mapa a escala. Por delegación sus
  stickers conservan el tamaño de siempre: a la mitad no se reconocían (se probó en una captura).

### 12.3 Zoom

- Escala de zoom: 1 = 1 px del mundo por px de pantalla. Rango **[0,5 – 2]** en el mundo grande
  (`zoom_minimo()` = hoja entera; `zoom_maximo()` = 2). En el mundo 1× sigue siendo [1 – 3].
- Se **arranca en 1**: se ve un cuarto de la hoja.
- **"Ver todo"** pasa a 0,5: la hoja entera ocupa justo la pantalla. El botón se ve siempre que no se
  esté viendo la hoja entera, así que en el mundo grande aparece desde el arranque.
- **Límites** (`_limitar`): nunca se ve fuera de la hoja. Si la hoja a ese zoom es más grande que la
  pantalla, sus bordes no pueden entrar; si cabe, queda centrada.
- La pinza de dos dedos y la rueda llegan hasta 0,5 y hasta 2.
- **Con la vista alejada, lo nuevo no crece** (`zoom_trazo()` = máx(zoom, 1)). Si no, un sticker
  puesto a 0,5 mediría el doble en el mundo y alejarse no daría lugar para más cosas, que es lo que
  pidió el PO. Al acercar, lo nuevo se achica como antes. Por eso con la hoja entera a la vista un
  sticker nuevo se ve a la mitad (unos 45 px). Para tocarlo sigue valiendo el mínimo de 36 px de
  pantalla de radio (72 px de diámetro).

### 12.4 Lupa (GDD §6.4: un toque, sin gestos)

Hay tres niveles fijos: **hoja entera (0,5)**, **normal (1)** y **cerca (2)**.

- **Sin acercar** (en la hoja entera o en el normal): tocar la lupa la **arma**, y el siguiente toque
  en el lienzo acerca **ahí**, centrado. Desde la hoja entera va al normal; desde el normal, al doble.
  Así, "ver todo + lupa + toque donde quiero ir" es la forma simple de moverse por la hoja sin
  arrastrar con dos dedos.
- **Acercada** (más que el normal): tocar la lupa vuelve al **normal** mirando lo mismo
  (`volver_a_base()`). No salta a la hoja entera: para eso está "ver todo".
- **Armada**: otro toque en la lupa la desarma.
- En el mundo 1× queda igual que antes (1× ↔ 2×).

### 12.5 Encuadre inicial

Zoom 1, **centrado en X**, con el **horizonte** (el borde de abajo del `cielo`) a **un tercio de la
altura de la pantalla**. Así lo primero que se ve tiene sentido: dos tercios de suelo, donde se ponen
casas, ponys y caminos, y una franja de cielo arriba, donde van el sol y las nubes. Si la escena no
tiene cielo, se centra la hoja.

- Granja: se ve y = 360–1080, con el horizonte en 600.
- Ciudad: se ve y = 340–1060, con el horizonte en 580.

### 12.6 Que nadie se trabe: la cámara va a la pista

Cuando Coco muestra una pista fantasma (camino, sticker o zona) que queda fuera de la vista, o
tapada por los botones, la cámara **se desliza** (0,6 s, `mostrar_en_vista`). Lleva la pista al centro
de la parte de la pantalla sin botones (`area_libre`) y, si no cabe, **se aleja**, como mucho hasta
la hoja entera. Si un borde de la hoja impide centrarla, prueba alejándose y se queda con el encuadre
donde más se ve la pista (a igualdad, el más cercano).

- **Nunca mueve la hoja bajo un dedo**: si hay alguien pintando o arrastrando, espera a que levante el
  dedo.
- Una zona grande (el río, el pasto) no mueve la cámara si ya asoma lo suficiente.
- La pista dura 0,6 s más cuando hubo paseo, para que se vea al llegar.
- Maxi no tiene paseos: siempre ve la hoja entera.

### 12.7 Guardado y rendimiento

- **PNG**: `componer()` arma el mundo entero y lo **reduce a 1280×720** (Lanczos): la hoja completa,
  como en "ver todo". Las imágenes van solo a `user://dibujos`; `progreso.json` no guarda imágenes ni
  crece.
- **Pintura en mosaicos** de 640×360 (16 en el mundo grande): en cada cuadro solo se sube a la GPU el
  pedazo tocado. Subir 2560×1440 (14,7 MB) en cada trazo habría sido lento en la tablet.
- **Deshacer**: sigue guardando la pintura comprimida con zstd, y solo en los pasos que pintaron.
- **Balde**: rellena regiones vectoriales, así que no hay relleno por píxel que se ponga lento.
- **Medido en PC** (arnés): trazo + paso del historial 14 ms, subida 0,2 ms, deshacer 10 ms y
  `componer()` 170 ms (solo al mostrar la hoja a Coco). Falta medir en la tablet (§12.9).

### 12.8 Verificación (17-Oct-2026, Godot 4.7.1)

- `qa_test_lienzo`: la suite completa con las 15 rutas y el epílogo, sin fallos (cifra final en el
  avance).
- Casos nuevos:
  - zoom inicial 1, el mundo 2560×1440 y el horizonte en el tercio de arriba;
  - el fondo llena el mundo, y los lugares, los puestos y las zonas quedan escalados;
  - los stickers no crecen;
  - la lupa en los tres niveles y la rueda;
  - "ver todo" a 0,5 muestra la hoja entera y oculta el botón;
  - límites con zoom 0,7 y centrado si la hoja cabe;
  - con la vista alejada, lo nuevo no crece;
  - gravedad y cielo escalados (el cielo de la granja llega a y = 600);
  - pista fuera de la vista, con el dedo apoyado (espera) y con una pista larga (se aleja);
  - Maxi sin zoom ni paseos;
  - rendimiento;
  - PNG de 1280×720.
- En las escenas de Nicole y Sofía, el arnés convierte las posiciones del fondo con `_w()`; las
  distancias entre stickers no se escalan.
- Capturas en ventana con `herramientas/capturar_lienzo_mundo.gd`:
  - `*_mundo_0_inspiracion`;
  - `*_mundo_1_zoom_inicial`;
  - `*_mundo_2_ver_todo`;
  - `*_mundo_3_pista_enfocada`;
  - `*_mundo_4_png_guardado`.

### 12.9 Pendientes y preguntas

- **Playtest**:
  - ¿Nicole y Sofía descubren "ver todo" y la lupa para moverse?
  - ¿El paseo de la cámara hacia la pista se entiende, o marea?
- **Encuadre inicial**: en la granja, el granero y el río quedan fuera de la primera vista (aparecen
  al alejar o cuando la pista los muestra). ¿Prefiere el PO que se arranque mirando los lugares del
  primer objetivo?
- **UX (HE-102)**: con la hoja entera a la vista, los stickers nuevos se ven a la mitad (~45 px); hay
  que auditar si Nicole los arrastra bien así.
- **Medir en la tablet** el trazo y el deshacer con la pintura de 2560×1440.
