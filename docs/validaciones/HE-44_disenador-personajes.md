# HE-44 — Validación de `disenador-personajes`: arte del álbum "Las migas de papá"

- **Fecha**: 28-Sep-2026
- **Ficha**: `docs/fichas/album-recuerdos.md` (§6 la entrega, §7 el álbum, §8 los placeholders)
- **Alcance**: marco polaroid, sobre-estrella y placeholders de hueco. Son SVG escritos a mano,
  sin API de pago. No se tocó código (`.gd`/`.tscn`), ni el catálogo, ni el tablero.
- **Estado del arte**: **PROVISIONAL**, pendiente de aprobación del PO (y de que los niños lo vean).

## 1. Lo que ya existía (no se duplicó)

- `scripts/ui/foto_recuerdo.gd` dibuja la polaroid **por código** (papel `#FFF8EE`, contorno
  `#2B3350`, borde dorado `#FFCB3D` y la estrella con "?" del hueco). No carga ningún sprite de marco.
- `scripts/ui/entrega_recuerdo.gd` dibuja el sobre-estrella **por código** (`_dibujar_sobre`,
  260×190, lila `#E9DDFF`, solapa `#CDB8FA` y sello estrella con carita).
- Los placeholders de foto encontrada son PNG (`assets/recuerdos/placeholders/<album>.png`),
  recortados de las anclas por decisión del PO. **No se reemplazan.** El hueco usa hoy
  `placeholders/familia.png` teñido (`catalogo.json` → `hueco.imagen`).
- **El código no pide ninguna ruta de sprite para estas piezas.** Por eso las rutas de abajo son
  una **propuesta**. Todas copian la geometría y los colores exactos que el código ya usa, así que
  cambiar de dibujo por código a sprite no mueve nada en pantalla.

## 2. Archivos creados

Fuentes en `assets/fuentes_svg/ui/recuerdos/`. PNG exportados con el pipeline de HE-03
(`exportar_sprites.gd`, escala 1,0) en `assets/sprites/ui/recuerdos/`. La exportación se corrió
con Godot 4.7.1 headless y dio 6 PNG y 0 errores.

| Archivo | Lienzo | Qué es | Ancla / pivote |
|---|---|---|---|
| `marco_polaroid.svg` | 420×500 | Polaroid estelar: papel crema con degradé, contorno de 8 px, destellos en el pie. **La ventana de la foto es transparente.** | Superior-izquierda, igual que el `Control` de `FotoRecuerdo`. Pivote en el centro (210, 250). |
| `marco_polaroid_dorado.svg` | 420×500 | La misma polaroid con una banda dorada de 18 px y 4 estrellas en las esquinas (premio de Sofía, ficha §4). | Igual que la anterior. |
| `hueco_polaroid.svg` | 420×500 | Tarjeta completa de "foto no encontrada": borde punteado, cielo violeta con los 3 hermanos en silueta dentro de su casco burbuja, estrella dorada grande con "?" y los 3 puntitos del pie. | Igual que la anterior. |
| `hueco_ventana.svg` | 362×376 | Solo el contenido de la ventana del hueco (cielo y siluetas), **sin** estrella ni "?". | Llena la `zona_foto` del código. |
| `sobre_estrella.svg` | 260×190 | Sobre cerrado. Grupos: `cuerpo`, `pliegues`, `solapa`, `sello_estrella` (con `carita`), `brillos`. | Centro (130, 95), igual que `pivot_offset = TAM_SOBRE / 2`. |
| `sobre_estrella_abierto.svg` | 260×300 | Sobre abierto con la polaroid asomando (fotograma intermedio opcional). Grupos: `interior`, `solapa_abierta`, `polaroid`, `bolsillo`, `sello_estrella`, `brillos`. | Inferior-centro. El cuerpo es el mismo rectángulo del cerrado, 110 px más abajo: la base (130, 190) del cerrado coincide con la base (130, 300) del abierto. |

## 3. Cómo usarlos (para `dev-godot`)

### Geometría de la polaroid

Es la misma de `foto_recuerdo.gd` a 420×500:

- Proporción 0,84.
- Margen `m` del 7% del ancho: 29 px.
- Pie del 19% del alto: 95 px.
- **Ventana de la foto: x 29..391, y 29..405 (362×376)**, con radio de esquina 6.

### Marco

1. Se dibuja **encima** de la foto (o del placeholder).
2. La foto va en `zona_foto`, que ya calcula el código.
3. Se escala **uniforme** al `size` de la celda (200×238, 423×504, 560×666). Todos esos tamaños
   tienen proporción 0,84, así que calza sin deformarse.
4. No usar NinePatch: las estrellas de las esquinas del dorado se estirarían.
5. El SVG **no trae sombra**, porque la sigue poniendo el código (`shadow_*` del StyleBox).
6. El dorado reemplaza al marco normal, no se suma encima. Sus estrellas quedan **dentro** del
   lienzo. El código actual las centra en la esquina exacta y salen medio afuera: con el sprite
   se puede quitar `_dibujar_brillos_dorados`.
7. El número y la edad siguen siendo texto dibujado por código sobre el pie. El pie queda libre,
   salvo 2 destellos chicos en la esquina inferior derecha (x ≥ 360): si una edad larga los tapa,
   se pueden quitar del SVG.

### Hueco

Hay dos opciones.

- **Opción A, sin tocar código, solo datos.** En `datos/recuerdos/catalogo.json`, cambiar
  `hueco.imagen` a `res://assets/sprites/ui/recuerdos/hueco_ventana.png` con `ajuste: "cubrir"`
  (la proporción es exacta). El código sigue dibujando encima la estrella y el "?".
  - Con `TINTE_HUECO` (alfa 0,5), las siluetas quedan tenues pero reconocibles. Así se verificó,
    componiendo el tinte del código.
  - Si se quieren más visibles, usar tinte `Color.WHITE` para esta imagen.
- **Opción B.** Dibujar `hueco_polaroid.png` como tarjeta completa y saltarse la rama `hueco` de
  `_draw()`. Suma el **borde punteado**, que el código no hace hoy y que la ficha §7 pide
  ("silueta de marco").

### Sobre

- `sobre_estrella.png` reemplaza 1:1 a `_dibujar_sobre()`, con el mismo tamaño y el mismo pivote.
- El latido del sello y las 4 estrellitas que orbitan siguen siendo animación por código. Para
  que el sello lata por separado, exportar el grupo `sello_estrella` como pieza aparte.
- Uso sugerido del abierto: `sobre` → (toque) → 0,15 s de `sobre_estrella_abierto` alineado por
  la base → la polaroid real crece desde el centro del grupo `polaroid` (130, ~110).

### Resolución

- Los PNG están a 1× (420×500). La foto abierta del álbum (560×666) y la de la entrega (423×504)
  los amplían hasta 1,33×.
- Para que se vean nítidos en la tablet hay dos caminos:
  - Exportar con `-- --escala=2.0`.
  - Cargar el `.svg` directamente como textura importada, como ya se hace con
    `assets/sprites/ui/iconos_juegos/*.svg`.
- Los `.import` de los PNG nuevos se generan la próxima vez que se abra el editor o se corra
  `--import`.

### Rutas propuestas y todavía no referenciadas por código

- `res://assets/sprites/ui/recuerdos/marco_polaroid.png`
- `res://assets/sprites/ui/recuerdos/marco_polaroid_dorado.png`
- `res://assets/sprites/ui/recuerdos/hueco_polaroid.png`
- `res://assets/sprites/ui/recuerdos/hueco_ventana.png`
- `res://assets/sprites/ui/recuerdos/sobre_estrella.png`
- `res://assets/sprites/ui/recuerdos/sobre_estrella_abierto.png`

## 4. Verificación visual hecha

Se armó una hoja de prueba con los PNG exportados. Se revisó:

- Cada pieza a tamaño real sobre el violeta del velo.
- El marco sobre una foto real de prueba (`placeholders/maxi.png`): la ventana calza sin bordes
  ni huecos.
- El hueco con el tinte del código compuesto encima.
- Miniaturas de 200×238 (celda del álbum).
- El sobre a 96 px.

No hay partes tapadas ni grupos desalineados, y no se usó ningún color fuera de la paleta. La
estrella con "?" y la silueta de los hermanos se siguen leyendo a 200 px. La carita del sello se
lee a 96 px.

## 5. Coherencia visual

- **Contorno**: único, `#2B3350`, con los grosores de la guía (§6.1): 7-8 px en siluetas grandes,
  4-5 px en el sello y los detalles, 2,5-3 px en los destellos. Siempre `linejoin`/`linecap` round.
  Nada anguloso.
- **Paleta**: solo colores que ya existen en el proyecto, sin hex nuevos de identidad.
  - Crema `#FFFFFF → #FFF8EE → #F1E2CC` y amarillo `#FFF1A6 → #FFD23F → #F2A92C`: los mismos
    degradés de `iconos_juegos/*.svg`.
  - Dorado `#FFCB3D`/`#FFE38A`, lila del sobre (`#E9DDFF`, `#CDB8FA`), violeta de hueco
    `#5B3F8F`/`#7A52C9` y casco burbuja `#BEDCFF`: todos tomados del código o de la guía §6.2.
  - Blush `#F26CA8` a 0,55.
- **Lenguaje de UI**: sombra `#2B3350` al 18% desplazada, línea interior blanca al 60% y destellos
  de 4 puntas con contorno. Es la misma receta de los íconos de juegos ya aprobados.
- **Estrella**: el mismo polígono de 10 puntas de `figura_vectorial.gd` (radios 0,98/0,47), así
  que calza con las estrellas que dibuja el código alrededor. La carita del sello sigue la receta
  de `dibujar_cara` en versión feliz: ojos `^^`, mejillas y sonrisa.
- **Siluetas de los hermanos en el hueco**: formas simples reconocibles por su pelo real.
  - Maxi, el más chico, con mechón en punta.
  - Nicole, al medio, con tomate y pelo largo.
  - Sofía, la más alta, con rizos a los lados.
  - Los tres llevan casco burbuja. El orden y la escala son los de la hoja `familia.png`.
  - No compiten con el arte raster aprobado de los personajes, porque son solo sombras amables.
- **Sin `<text>`**: el "?" es un trazo y un punto, para no depender del soporte de texto del
  rasterizador de Godot (ThorVG).
- **Tono amable**: el hueco es violeta estrellado y no gris. Se lee como "aquí viene una foto",
  nunca como error o castigo (GDD §6).

## 6. Pendiente

1. **Aprobación del PO** de las 6 piezas. Si puede ser, que Sofía y Nicole vean el marco dorado y
   el sobre.
2. `dev-godot` tiene que decidir si pasa de dibujo por código a sprite (sección 3). Hoy el juego
   funciona igual sin estos archivos.
3. Cambiar `hueco.imagen` en el catálogo (opción A). Es una decisión de datos de `dev-godot` y no
   se aplicó.
4. `experto-ux-parvulo` tiene que auditar el contraste de las siluetas tenues del hueco en la
   tablet real.
5. Fuera de alcance, sin hacer: el botón libro-álbum (`boton_album.gd`, dibujado por código) y la
   burbuja-recuerdo del viaje estelar. Si se quieren como sprite, son una tarjeta aparte de arte.
