# CLAUDE.md

Esta guía orienta a Claude Code al trabajar en este repositorio.

## Información importante

- **Idioma del proyecto**: Español — código, comentarios, documentación y comunicación en español. Nombres de archivos/nodos en minúsculas y sin acentos.
- **Naturaleza del proyecto**: regalo personal de un papá para sus tres hijos (Maxi 2, Nicole 5, Sofía 8). La calidad que importa es que a ellos les encante — cuida los detalles de ternura, celebración y accesibilidad infantil tanto como el código.

## Descripción del proyecto

**Los Hermanos Estelares** es un juego 2D en **Godot 4 (GDScript)** donde tres hermanos, jugando en el living de su casa, imaginan una aventura espacial: guiados por la estrellita Estelita, visitan planetas con minijuegos educativos para reunir las piezas de su nave y rescatar a papá, "secuestrado" por un alienígena coleccionista chistoso. Cada niño selecciona su personaje y eso adapta la dificultad de los mismos minijuegos a su edad (niveles semilla/brote/estrella). Táctil-primero (tablet Android), jugable en PC; arte cartoon vectorial (SVG); 100% offline, sin texto obligatorio (todo narrado por voz).

Documentos fuente de verdad — **léelos antes de implementar cualquier cosa**:

- [`docs/diseno-juego.md`](docs/diseno-juego.md) — GDD: guion, personajes, planetas, minijuegos y reglas de UX infantil (§6, obligatorias).
- [`docs/stack-tecnico.md`](docs/stack-tecnico.md) — arquitectura Godot, estructura de carpetas, pipeline de assets/MCP, decisiones registradas.

## Gestión del desarrollo (harness Scrumban)

El desarrollo se gestiona con un tablero Kanban en [`docs/TABLERO.md`](docs/TABLERO.md), mismo patrón que otros proyectos del autor (Split_Recepcion, DistroHub):

- **Agente `scrum-master`**: único que edita `docs/TABLERO.md`. Estados de tarjeta, WIP=2, Definición de Hecho y registro de avances.
- **Agente `dev-godot`**: implementa las tarjetas para este stack (Godot 4 2D, escenas/scripts como texto, sprites SVG).
- **Skills**: `/planificar` (siguiente tarjeta), `/avance` (registrar trabajo completado), `/estado-proyecto` (resumen de solo lectura).
- **Hooks**: al iniciar sesión se inyecta el ESTADO ACTUAL del tablero; tras editar `docs/TABLERO.md` se valida su estructura mínima y se **guarda automáticamente en GitHub** (commit con la entrada del avance + push a origin) — no hagas commits manuales de avances, deja que el hook documente el progreso.

## Stack técnico (resumen)

- **Godot 4.x** (2D, renderer Mobile), **GDScript**, resolución base 1280×720 con stretch `canvas_items`, entrada unificada táctil+mouse.
- Autoloads: `Progreso` (perfiles/guardado), `Audio` (buses música/sfx/voz), `Navegacion` (transiciones).
- Minijuegos: escenas autocontenidas que extienden `minijuego_base.gd`, reciben `nivel` y emiten `completado(destellos)`. Contenido data-driven desde `datos/`.
- Assets: SVG fuente versionado en `assets/fuentes_svg/`; audio OGG CC0; ver pipeline en stack §5.
- Herramientas IA (stack §4): skills **GodotPrompter** (GDScript idiomático) + **godot-mcp** (ejecutar escenas, leer errores); GDAI MCP en evaluación.
- Godot aún **no está instalado** (tarjeta HE-01).

## Reglas de oro al desarrollar

1. El diseño personalizado con los niños (Fase 0 del tablero) manda: nada se implementa si contradice sus fichas y el GDD actualizado con sus gustos.
2. Nada que castigue, apure o frustre a un niño de 2-8 años (GDD §6). Ante la duda, más grande, más lento, más celebración.
3. Un minijuego nunca toca el núcleo; el núcleo nunca conoce minijuegos concretos.
4. Verifica ejecutando la escena afectada antes de dar por hecha una tarjeta (el DoD lo exige).
5. Playtest con los niños al cerrar cada fase de contenido — su reacción reordena el backlog.

## Próximos pasos

Ejecuta `/estado-proyecto` para ver la fase activa, o `/planificar` para tomar la siguiente tarjeta. La fase activa es la **Fase 0 — diseño personalizado con los niños** (empieza por HE-D1: sesión de descubrimiento).
