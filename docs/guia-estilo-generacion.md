# Guía de estilo para generación de imágenes y video (IA)

Biblia de arte para todo asset generado con IA (fondos, pantallas de carga, tarjetas de minijuegos, key art, fotogramas de cinemáticas y planos de video). Complementa —no reemplaza— al arte SVG propio de personajes interactivos (stack §5). **Nada generado entra al juego sin pasar la revisión del flujo de aprobación (abajo).**

## 1. Modelos y herramientas aprobadas (PO, 19-Jul-2026)

| Uso | Modelo | Vía |
|---|---|---|
| Ilustración raster (fondos, cargas, tarjetas, key art, fotogramas ancla) | **Nano Banana Pro** (`gemini-3-pro-image`) | MCP `mcp-image` (configurado en `.mcp.json`, key en variable de entorno `GEMINI_API_KEY`) |
| Video de cinemáticas (planos ~5 s con referencia) | **Veo 3.1** (`veo-3.1-generate-preview`, Ingredients to Video) | API Gemini (misma key) |
| Respaldo si un plano no logra consistencia | Motion comic: ilustración fija + paneo/parallax/zoom en Godot | `director-cinematicas` + `dev-godot` |

La key **nunca** se escribe en archivos del repo. La salida cruda va a `assets/generadas/` (staging con `.gdignore`); lo aprobado se copia a su destino final en `assets/`.

## 2. Imágenes ancla (obligatorias en todo prompt)

Toda generación parte adjuntando al menos una imagen ancla — nunca se le pide al modelo que "invente" el estilo o un personaje de memoria:

- **Ancla maestra de estilo**: `assets/hermanosestelares.jpeg` (el póster oficial).
- **Anclas de personaje** (aprobadas por el PO el 19-Jul-2026, en `assets/anclas/`): `maxi_referencia.png`, `nicole_referencia.png`, `sofia_referencia.png` — cada hermano en 4 vistas (3/4, frente, perfil, espalda), misma ropa e iluminación, fondo neutro.
- **Ancla de alturas**: `hermanos_alturas.png` (lineup de los tres) — adjuntarla SIEMPRE que aparezcan dos o más hermanos juntos, porque fija la proporción por edad: Maxi (2) llega a la cintura de Sofía, Nicole (5) a su hombro, Sofía (8) es la más alta.
- Los sprites SVG aprobados (`assets/sprites/personajes/`) sirven de referencia adicional de vestuario y colores.

**Lección aprendida (19-Jul)**: para generar a los tres hermanos juntos NO adjuntar las tres hojas individuales a la vez — el modelo duplica personajes. Anclar con el póster (y/o el lineup de alturas) como referencia única de grupo y describir a cada niño en el texto.

## 3. Biblia de arte (describir SIEMPRE en el prompt)

- **Estilo**: cartoon pintado digital, contornos suaves, luz de borde cálida (rim light dorado/rosado), degradados atmosféricos, saturación alta pero tierna. Ni fotorrealismo ni anime.
- **Paleta base**: violetas y púrpuras espaciales de fondo, dorado estelar para brillos y estrellas, turquesas y rosados para acentos; luz general cálida y acogedora.
- **Personajes canon** (solo si el encuadre los pide; si no, indicar «sin personajes»):
  - **Maxi (2)**: niño pequeño, pelo castaño oscuro corto, ojos café grandes, sonrisa abierta; traje espacial blanco con detalles azules y guantes blancos; estrella dorada en el pecho.
  - **Nicole (5)**: niña, pelo castaño oscuro largo ondulado con coleta alta, ojos café; traje blanco con chaqueta y botas rosadas, estrella celeste en el pecho, cinturón con corazón rosa.
  - **Sofía (8)**: la mayor y más alta, pelo negro rizado largo y voluminoso, aros pequeños; traje rosado completo, audífonos rosados en el casco, estrella dorada brillante en el pecho.
  - Los tres usan **casco burbuja transparente**.
- **Tono emocional**: asombro, ternura y aventura. Prohibido: oscuridad amenazante, criaturas que asusten, dientes afilados, tormentas violentas (GDD §6 — nada que asuste a un niño de 2 años).
- **Sin texto** dentro de la imagen, nunca (el juego no usa texto obligatorio y los títulos se componen aparte).

## 4. Formatos por tipo de asset

| Asset | Aspecto | Notas |
|---|---|---|
| Fondos de pantalla/planeta | 16:9 | Zona central despejada para gameplay/UI; detalle en bordes |
| Pantallas de carga / key art | 16:9 | Puede incluir personajes canon con anclas |
| Tarjetas del juego de pares | 1:1 | Objeto único centrado, fondo simple de alto contraste, legible a 128 px |
| Fotogramas de cinemática | 16:9 | Composición de plano según storyboard de `director-cinematicas` |

## 5. Flujo de trabajo y aprobación

1. El diseñador responsable (spec) define qué imágenes se necesitan y con qué anclas.
2. Se genera **en lotes con el mismo prompt base** (solo cambia el sujeto), revisando contra el póster ancla.
3. `experto-ux-parvulo` audita (§6 del GDD: contraste, legibilidad, nada atemorizante) y el PO aprueba.
4. Lo aprobado se copia de `assets/generadas/` a su carpeta final y recién ahí lo importa Godot.

## 6. Video (cinemáticas)

- Guion (`guionista`) → storyboard (`director-cinematicas`) → fotogramas ancla por plano (Nano Banana Pro) → clip de ~5 s por plano con Veo 3.1 pasando las anclas como *ingredients*.
- **Un plano = un clip = una sola idea de movimiento.** Sin cortes de cámara dentro del clip.
- Se genera **sin diálogo**: las voces las graba la familia (GDD §7) y se montan encima.
- Si tras 2-3 intentos un plano no mantiene al personaje idéntico, ese plano se resuelve como motion comic (respaldo aprobado) — nadie espera que el 100% sea video.
- Los videos finales se empaquetan como archivos locales (el juego sigue 100% offline).
