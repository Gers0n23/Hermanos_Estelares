# Plan de producción de cinemáticas por técnica (Blender / Godot / IA)

> Aprobado por el PO (Gerson) el 14-Nov-2026. Objetivo: **generar con IA solo lo estrictamente
> necesario**. Cada cinemática se asigna a la técnica más barata que la resuelve bien.

## 1. Regla de asignación

| Técnica | Cuándo | Costo |
|---|---|---|
| **Blender por código** (3D con look 2D pintado) | Objetos y lugares: nave, planetas, espacio, taller, nave del Coleccionauta. Sin personajes, o con personajes como siluetas lejanas | 0 USD (solo tiempo de render) |
| **Godot con los sprites existentes** (cutout / motion comic con `AnimationPlayer` y `Tween`) | Personajes que hablan o celebran: video-llamadas, diálogos, despedidas, gags, intros de ronda | 0 USD |
| **IA (imagen o video)** | Solo personajes en acción física que los sprites no pueden actuar, y sprites que faltan | Pagado: siempre con `--estimar` y OK explícito del PO sobre el costo |

**Combinación Blender + Godot**: Blender puede renderizar con fondo transparente
(`film_transparent`, secuencia PNG o video con alfa), así la nave o un planeta quedan como capa en
Godot y encima van los sprites de los hermanos o de Cometa. Así hay personajes sin usar IA.
Hay que validar la mezcla con **un plano de prueba** antes de usarla en serie: el storyboard de la
intro advierte que mezclar estilos dentro de una misma escena se nota.

## 2. Inventario por técnica

### 2.1 Blender

| # | Cinemática | Cantidad | Estado |
|---|---|---|---|
| B1 | Llegada de la nave (también sirve como plano 07 de la intro: la nave baja al patio; antes iba a ser video IA) | 1 | ✅ POC v2 aprobada por el PO: `poc/cinematica_blender/llegada_nave.py` |
| B2 | Taller de piezas: la nave recibe la pieza de cada planeta | 6 | ✅ POC hecha: `poc/cinematica_blender/taller_piezas.py --pieza 1..6` (pendientes: ver §4) |
| B3 | **Presentación de cada planeta**: la nave llega en órbita, la cámara baja y aparece lo propio del planeta. El último cuadro coincide con el fondo del mapa del planeta | 6 | ⬜ **Siguiente: piloto Arcoíris** |
| B4 | Despegue y viaje entre planetas (incluye el "despegue por el puente de 3 bandas", `cierre_arcoiris.md` §12.2). Cada viaje empalma con la presentación siguiente | 6 | ⬜ |
| B5 | Nave del Coleccionauta: aparece, huye, escapa en cada cierre (un modelo, muchas tomas; el personaje se pone encima como sprite) | 1 modelo | ⬜ |
| B6 | Vista general del planeta del Coleccionauta y su colección (escena final) | 1 | ⬜ |
| B7 | Regreso a casa: la nave aterriza de noche en el patio (variante de B1) | 1 | ⬜ |
| B8 | Animación del título (opcional) | 1 | ⬜ |

### 2.2 Godot con los sprites existentes

Sprites disponibles: hermanos (base y celebración), Cometa, Coco, papá, Coleccionauta y Toby
(estos tres últimos provisionales), más los fondos de Arcoíris y Animalia.

- Video-llamadas de papá: sprite dentro de un marco de pantalla, rebotando con la voz. Si después se graba la voz real de papá (HE-52), se cambia solo el audio.
- Escenas de historia de cada planeta (`docs/guiones/plantilla_escena_planeta.md`): fondo, sprites que entran, rebotan y celebran con las voces.
- Batalla y partida (HE-68, HE-78, HE-83, HE-85): intros de ronda, interludios, gags, despedida de Coco, la foto, la cuenta regresiva y el Mapa Estelar. **La versión provisional en Godot puede quedar como definitiva.**
- Planos de la intro que eran "foto con zoom" ([M]: 01, 03, 05, 08 y 09): fondo del living más sprites. Requiere el sprite de los hermanos con **ropa de casa** (es una imagen de IA, mucho más barata que un video).

### 2.3 IA (solo esto)

| Momento | Tipo |
|---|---|
| Intro 02: el Coleccionauta se lleva a papá | Video |
| Intro 04: Cometa choca contra la ventana | Video |
| Intro 06: trajes con estrellas de poder | Video |
| Abrazo final con papá (HE-39) | Video, o una sola imagen con zoom lento si hay que ahorrar |
| Sprites que faltan: ropa de casa, los anfitriones de los 4 planetas que faltan y el Coleccionauta definitivo | Imagen |

Resultado: de los 5 planos [V] de la intro más todo lo de cada planeta pasamos a **3 o 4 clips de video IA en todo el juego**.

## 3. Cómo se produce con Blender (para el agente que retome)

- Blender 4.5.16 LTS portable: `C:\tmp\blender\blender-4.5.16-windows-x64\blender.exe` (en Bash: `/c/tmp/blender/blender-4.5.16-windows-x64/blender.exe`). Sin interfaz: `blender -b -P guion.py -- [opciones]`.
- Formato: EEVEE Next, 1280×720, 24 fps, vista Standard, MP4 H.264 en `poc/cinematica_blender/salida/` más una foto del último cuadro. Godot necesita **.ogv** (convertir al integrar).
- Look 2D: el módulo compartido `poc/cinematica_blender/nave_comun.py` trae los materiales toon (`toon`, `brillante`, `halo`, `con_alfa`), el contorno por casco invertido, el compositor (Kuwahara + Glare), la nave completa (`construir_nave`, `vestir_gala`) y las 6 piezas (`pieza`). **Importarlo vacía la escena.**
- Patrón por familias: un guion por tipo de cinemática con un "kit" por planeta y la opción `--pieza N` / `--planeta id`, como `taller_piezas.py`. Para B3 se propone `planeta_comun.py` (planeta toon, anillos, atmósfera, rasgos por planeta) más `presentacion_planeta.py --planeta arcoiris`.
- Revisar cuadros sueltos en baja resolución (scratchpad) antes del render final; el ritmo lo valida el PO viendo el video.

## 4. Decisiones abiertas del PO

1. **Nave terminada: ¿manda la guía de estilo (motores laterales, alas arcoíris y verde) o el sprite final (`assets/sprites/nave/nave_estrella.png`: alas azul y rosa con estrella, sin motores laterales)?** Más importante ahora porque la nave aparece en unas 20 piezas.
2. **Parecido del planeta 3D con el arte existente**: para Arcoíris y Animalia se usan `assets/anclas/planeta_arcoiris_referencia.png` y `planeta_animalia_referencia.png` como guía de colores y formas. Propuesta: los otros 4 planetas, que aún no tienen arte, nacen directamente en Blender.
3. **Pendientes de las POC del taller** (B2): las alas de costado se leen como óvalos; el corazón se ve pálido tras la cúpula; la placa no tiene el texto ni el corderito; la ficha `docs/fichas/hangar-nave.md` hace que el niño instale la pieza arrastrándola, así que el video no debe duplicar ese momento (puede ir después, como celebración).

## 5. Próximo paso

Piloto **B3 Arcoíris** (presentación del planeta) con `planeta_comun.py` preparado para los 6, y
una prueba de la combinación Blender + Godot (nave con fondo transparente y sprites encima).
