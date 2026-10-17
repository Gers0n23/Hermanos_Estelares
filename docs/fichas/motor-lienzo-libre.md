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
- **Zoom**:
  - La lupa alterna 1× y 2× (catálogo §1.7): con 1× queda armada y el siguiente toque acerca al doble
    ahí. "Ver todo" aparece con zoom.
  - La rueda del mouse y la pinza de dos dedos quedan como extra.
  - Con zoom, el pincel, los sellos, los stickers nuevos, los caminos y los imanes conservan su tamaño
    **en pantalla**: en el mundo se dividen por el zoom.
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
