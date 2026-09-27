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

- Conectar las 5 estaciones `pinta` en `datos/planetas/arcoiris/mapa.json` (escena y niveles).
- Que el hangar muestre `ala_nave.png` y que el mapa del planeta vista a Coco con `traje_coco.json`
  (núcleo).
- Voces oficiales de Coco y Cometa: las 167 líneas son TTS de Windows (`lineas_tts.tsv`). Pasarlas a
  `generar_voces_fal.py` requiere el OK del PO sobre el costo.
- Arte final de sellos, láminas y la UI de la paleta (HE-13). Hoy todo está dibujado en código.
- Galería para ver los dibujos guardados (fuera del alcance de este motor).
