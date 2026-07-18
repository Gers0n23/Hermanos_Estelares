# Tablero Kanban — Los Hermanos Estelares

**Roadmap de referencia**: [docs/diseno-juego.md](diseno-juego.md) (diseño) y [docs/stack-tecnico.md](stack-tecnico.md) (técnica).

---

## ESTADO ACTUAL

- **Última actualización**: 18-Jul-2026
- **Fase activa**: Fase 0 — El corazón del juego (diseño con los niños)
- **En curso (WIP)**: HE-D1 (PO) — 1/2, hay capacidad para 1 tarjeta más. Avance parcial: entrevista de Maxi (2, semilla) completada en `docs/perfil-jugadores.md`; faltan Nicole (5) y Sofía (7). Además, adelanto visual de HE-D2 (sigue ⬜): estilo aprobado por el PO y mockups SVG de los 3 hermanos en `assets/fuentes_svg/personajes/`
- **Próximo en cola**: HE-03 (pipeline de assets, Dev — solo depende de HE-01 ✅ y ejercita la conexión viva de godot-mcp); alternativa HE-04 (base de audio). HE-D2 y HE-D3 esperan a HE-D1
- **Bloqueos**: ninguno formal; HE-D1 requiere tiempo presencial del PO con los niños — hasta que se completen las entrevistas de Nicole y Sofía en `docs/perfil-jugadores.md`, HE-D2/D3/D4/D5 y HE-02 no pueden iniciar
- **Avance general**: 1/39 tarjetas ✅ (HE-01 cerrada 18-Jul-2026; nota: la conexión viva del MCP se ejercitará en HE-03/HE-05)

---

## MARCO DE TRABAJO

- **Método**: Scrumban — flujo continuo, backlog priorizado, límite **WIP = 2**.
- **Roles**: Product Owner = papá (Gerson) con veto de los 3 QA junior (Maxi, Nicole, Sofía); Scrum Master = agente `scrum-master`; Dev = agente `dev-godot` / Claude Code.
- **Estados**: ⬜ Backlog → 🔄 En curso → ✅ Hecho · 🔴 Bloqueado (indicando el bloqueo).
- **Definición de Hecho (DoD)**:
  1. Lo implementado corre sin errores en el editor de Godot (o el documento/asset está creado y referenciado).
  2. Verificado jugando la parte afectada (en PC; en tablet cuando aplique).
  3. Respeta las reglas de UX del GDD §6 (objetivos grandes, voz, sin castigos) si es una pantalla o minijuego.
  4. Avance registrado en este tablero.
- **Reglas especiales del proyecto**:
  - Al registrar un avance en este tablero, un hook guarda automáticamente el proyecto en GitHub (commit con la entrada del avance + push a origin).
  - Al cerrar cada fase con contenido jugable (3, 4, 5, 6), hay una tarjeta de **playtest con los niños** — su reacción puede reordenar el backlog. Es la métrica que manda.
  - Nada de la Fase 1 en adelante se implementa si contradice lo definido en la Fase 0: el diseño personalizado es la fuente de verdad.

## FASE 0 — El corazón del juego (diseño con los niños)

**Criterio de salida**: historia, personajes, planetas y las fichas de minijuego del primer planeta están definidas, personalizadas con los gustos reales de Maxi, Nicole y Sofía, y aprobadas por el Product Owner.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-D1 | Sesión de descubrimiento con los niños: qué aman hoy (animales, colores, canciones, personajes, apps/juegos favoritos, qué los asusta o aburre); registrar hallazgos por hijo en `docs/perfil-jugadores.md` | 🔄 En curso | — | PO |
| HE-D2 | Personalizar guion e historia (GDD §1-§2) con esos hallazgos: personalidad y gesto de celebración de cada hermano, nombre/carácter de Estelita; validar con los niños que sus personajes "sean ellos" | ⬜ Backlog | HE-D1 | PO + Dev |
| HE-D3 | Validar los 6 planetas (temas, anfitriones, nombres, orden de desarrollo) contra los gustos reales; ajustar GDD §4 — planetas que no emocionen se reemplazan ahora, no después | ⬜ Backlog | HE-D1 | PO + Dev |
| HE-D4 | Ficha detallada por minijuego del primer planeta (en `docs/fichas/`): mecánica exacta, los 3 niveles S/B/E, assets necesarios, líneas de voz, condición de destello | ⬜ Backlog | HE-D3 | Dev + PO |
| HE-D5 | Guion narrativo completo: escena de intro (la caída de Estelita), escenas de historia por planeta y primera versión de `guion_voces.md`; decidir P2 (voces de la familia) | ⬜ Backlog | HE-D2, HE-D3 | PO + Dev |

## FASE 1 — Cimientos (herramientas y esqueleto)

**Criterio de salida**: el proyecto Godot abre, muestra una pantalla placeholder, las herramientas IA (skills + MCP) están operativas y está definida la guía de estilo visual.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-01 | Instalar Godot 4.x, crear `project.godot` con config base (720p, canvas_items, input táctil+mouse), estructura de carpetas del stack §3, e instalar GodotPrompter (skills) + godot-mcp (stack §4) | ✅ Hecho | — | Dev |
| HE-02 | Guía de estilo visual: paleta maestra, contorno, tipografía; diseño SVG de los 3 hermanos y Estelita (pose idle) según lo definido en HE-D2, con aprobación de los QA junior | ⬜ Backlog | HE-D2 | Dev + PO |
| HE-03 | Completar pipeline de assets: probar SVG→PNG por lote, evaluar MCP de generación de imágenes y GDAI MCP; registrar decisión en stack §7 | ⬜ Backlog | HE-01 | Dev |
| HE-04 | Base de audio: buses música/sfx/voz, autoload `Audio`, descargar paquete sfx CC0 inicial, estructurar `guion_voces.md` (contenido viene de HE-D5) | ⬜ Backlog | HE-01 | Dev |

## FASE 2 — Núcleo del juego

**Criterio de salida**: se puede abrir el juego, elegir hermano, navegar el mapa estelar (con planetas de mentira), y el progreso persiste por perfil.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-05 | Pantalla de título animada (cielo estrellado, "tocar para empezar") | ⬜ Backlog | HE-01 | Dev |
| HE-06 | Selección de personaje: 3 retratos grandes, cada uno saluda con voz/sonido al tocarlo; fija el perfil de nivel | ⬜ Backlog | HE-02, HE-04 | Dev |
| HE-07 | Autoload `Progreso`: perfiles por hermano, destellos/estrellas, guardado automático JSON | ⬜ Backlog | HE-01 | Dev |
| HE-08 | Mapa Estelar (hub) data-driven desde `datos/planetas.json`: nave navega entre planetas, bloqueados/desbloqueados | ⬜ Backlog | HE-06, HE-07 | Dev |
| HE-09 | Autoload `Navegacion` + transición de nave-estrella entre escenas | ⬜ Backlog | HE-05 | Dev |
| HE-10 | Contrato `minijuego_base.gd` (parámetro nivel, señal completado) + escena de celebración reutilizable (confeti, estrellitas, baile) | ⬜ Backlog | HE-07 | Dev |
| HE-11 | Estelita ayudante flotante: reproduce/repite instrucciones de voz en cualquier escena | ⬜ Backlog | HE-04 | Dev |
| HE-12 | Zona de padres con candado adulto: volumen por bus, ver/ajustar nivel por perfil, salir del juego | ⬜ Backlog | HE-07 | Dev |

## FASE 3 — Primer planeta (corte vertical)

**Criterio de salida**: el primer planeta definido en Fase 0 completo y pulido de punta a punta — la prueba de que todo el concepto funciona. Playtest aprobado por los 3 niños.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-13 | Arte del primer planeta: fondo, anfitrión y props según su ficha (HE-D4) | ⬜ Backlog | HE-03, HE-D4 | Dev |
| HE-14 | Minijuego 1 del planeta (niveles S/B/E según ficha) | ⬜ Backlog | HE-10, HE-13 | Dev |
| HE-15 | Minijuego 2 del planeta (S/B/E según ficha) | ⬜ Backlog | HE-10, HE-13 | Dev |
| HE-16 | Minijuego 3 del planeta (según ficha) | ⬜ Backlog | HE-10, HE-13 | Dev |
| HE-17 | Escena de historia del planeta + destellos otorgados + estrella encendida en el cielo de casa | ⬜ Backlog | HE-14, HE-15, HE-16 | Dev |
| HE-18 | 🧒 Playtest 1 con Maxi, Nicole y Sofía; registrar observaciones y ajustar | ⬜ Backlog | HE-17 | PO |

## FASE 4 — Planetas 2 y 3

**Criterio de salida**: 3 planetas jugables; playtest 2 aprobado.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-19 | Arte del planeta 2 según su ficha (crear ficha si falta, patrón HE-D4) | ⬜ Backlog | HE-18 | Dev |
| HE-20 | Minijuegos del planeta 2 + escena de historia | ⬜ Backlog | HE-19 | Dev |
| HE-21 | Arte del planeta 3 según su ficha | ⬜ Backlog | HE-18 | Dev |
| HE-22 | Minijuegos del planeta 3 + escena de historia | ⬜ Backlog | HE-21 | Dev |
| HE-23 | 🧒 Playtest 2; ajustar según reacciones | ⬜ Backlog | HE-20, HE-22 | PO |

## FASE 5 — Planetas 4, 5 y 6

**Criterio de salida**: los 6 planetas jugables; playtest 3 aprobado.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-24 | Arte + minijuegos del planeta 4 + historia (ficha previa, patrón HE-D4) | ⬜ Backlog | HE-23 | Dev |
| HE-25 | Arte + minijuegos del planeta 5 + historia | ⬜ Backlog | HE-23 | Dev |
| HE-26 | Arte + minijuegos del planeta 6 + historia | ⬜ Backlog | HE-23 | Dev |
| HE-27 | 🧒 Playtest 3; ajustar | ⬜ Backlog | HE-24, HE-25, HE-26 | PO |

## FASE 6 — Pulido y entrega v1.0

**Criterio de salida**: el juego corre instalado en la tablet de los niños, con voces definitivas. 🎁

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-28 | Grabar/integrar voces definitivas según `guion_voces.md` (decisión de HE-D5) | ⬜ Backlog | HE-27 | PO + Dev |
| HE-29 | Música por planeta + mezcla de audio final | ⬜ Backlog | HE-27 | Dev |
| HE-30 | Cinemática/escena inicial: la caída de Estelita (guion de HE-D5, se puede saltar) | ⬜ Backlog | HE-27 | Dev |
| HE-31 | Rendimiento y pruebas en tablet real (P3): tiempos de carga, tamaños táctiles, batería | ⬜ Backlog | HE-28 | Dev |
| HE-32 | Export Android (plantillas, firma, APK) + export Windows | ⬜ Backlog | HE-31 | Dev |
| HE-33 | 🧒 Playtest final en tablet + correcciones | ⬜ Backlog | HE-32 | PO |
| HE-34 | 🎉 Entrega v1.0 a los Hermanos Estelares | ⬜ Backlog | HE-33 | Toda la familia |

---

## REGISTRO DE AVANCES

- **[17-Jul-2026]** Planificación inicial: GDD, stack técnico, tablero y harness creados (PO + Dev).
- **[18-Jul-2026]** Investigación de herramientas IA (GodotPrompter + godot-mcp adoptados, GDAI a evaluar), hook de guardado automático en GitHub, y reestructura del roadmap: nueva Fase 0 de diseño personalizado con los niños (PO + Dev).
- **[18-Jul-2026]** Planificación Scrumban: HE-D1 (sesión de descubrimiento, PO) y HE-01 (instalación de Godot y herramientas, Dev) pasan a En curso — WIP 2/2 (Scrum Master).
- **[18-Jul-2026]** HE-01 — Godot 4.7.1 stable instalado vía winget y verificado (headless y ventana Vulkan Forward Mobile sin errores); `project.godot` con config base del stack §1 y escena placeholder temporal (hasta HE-05); estructura de carpetas del stack §3 completa; godot-mcp configurado en `.mcp.json` y GodotPrompter instalado (54 skills); `docs/stack-tecnico.md` §1 actualizado. Conexión viva del MCP se ejercitará en HE-03/HE-05 (Dev).
- **[18-Jul-2026]** HE-D1 (parcial, sigue 🔄) — Creado `docs/perfil-jugadores.md` con la primera entrevista completada: Maxi (2 años, nivel semilla). Datos clave: fan de dinosaurios (t-rex, spinosaurio, carnotauro), autos/Cars/Sonic/Tayo/Blippi; ya juega apps tipo memory y Lingokids; se aburre con historias largas/mucho diálogo; su celebración real es gritar "¡siiii!" con ~3 saltitos y puño derecho arriba; quiere ser bombero y le fascina el espacio. Registrado `assets/hermanosestelares.jpeg` como referencia visual oficial de la aventura (los 3 hermanos astronautas, hecha por el papá). Pendiente para cerrar HE-D1: entrevistas de Nicole (5) y Sofía (7) (PO).
