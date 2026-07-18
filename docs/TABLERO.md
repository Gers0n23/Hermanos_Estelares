# Tablero Kanban — Los Hermanos Estelares

**Roadmap de referencia**: [docs/diseno-juego.md](diseno-juego.md) (diseño) y [docs/stack-tecnico.md](stack-tecnico.md) (técnica).

---

## ESTADO ACTUAL

- **Última actualización**: 18-Jul-2026
- **Fase activa**: Fase 0 — El corazón del juego (diseño con los niños)
- **En curso (WIP)**: HE-D1 (PO) — 1/2, hay capacidad para 1 tarjeta más. Las 3 entrevistas de `docs/perfil-jugadores.md` tienen ya los datos esenciales para diseñar: Maxi (2, semilla) ✅, Sofía (8, estrella) ✅ y Nicole (5, brote) **parcial** — le faltan 3 campos que el PO completará: apps/juegos que usa, qué la asusta/aburre y sueños/mundos. Como dos de esos campos están en el alcance explícito de la tarjeta, HE-D1 no cumple aún el DoD (punto 1) y sigue 🔄. **Su cierre subió de importancia**: las fichas de gustos alimentan directamente las rutas personalizadas del nuevo modelo de jugabilidad (GDD §5, 18-Jul-2026). Además, adelantos informales de HE-D2 (sigue ⬜): sprites SVG de los 3 hermanos + celebraciones en `assets/fuentes_svg/personajes/` (6 SVG con sus 6 PNG en `assets/sprites/personajes/`) y **historia y mensaje aprobados formalmente por el PO** (18-Jul-2026), con 4 cambios de diseño ya aplicados al GDD: lección de cooperación jugable en la misión final (§1), derrota-gag permitida en niveles de Nicole y Sofía (§1), **rutas personalizadas por hermano** en lugar de «mismo minijuego, 3 dificultades» (§2+§5; §4 queda «en revisión» hasta cerrar HE-D1) y nuevo **modo misión familiar** por turnos en el mismo dispositivo (§3)
- **Próximo en cola**: HE-04 (base de audio, Dev — solo depende de HE-01 ✅). HE-D2 y HE-D3 esperan al cierre formal de HE-D1; HE-13 heredará la decisión pendiente sobre Recraft MCP para fondos
- **Bloqueos**: ninguno formal; para cerrar HE-D1 el PO debe completar los 3 campos pendientes de la ficha de Nicole en `docs/perfil-jugadores.md` — hasta entonces, HE-D2/D3/D4/D5 y HE-02 no pueden iniciar, y **el catálogo definitivo de niveles temáticos por hermano (GDD §9, P5) tampoco puede definirse**. Pendientes derivados para HE-D2: confirmar insignia de cinturón pony para Sofía (la de Nicole — corazón rosa — ya fue **confirmada por el PO** y aplicada al sprite); sprites `sofia_celebracion` y `nicole_celebracion` pendientes de aprobación de cada niña/PO; **validar con los niños el nombre "el Coleccionauta"** (provisional) del alienígena de la nueva historia. Pendiente de sesión: el PO seguirá revisando el resto de sus puntos de feedback del GDD en la próxima conversación
- **Avance general**: 2/39 tarjetas ✅ (HE-01 y HE-03 cerradas 18-Jul-2026; la deuda de HE-01 — conexión viva de godot-mcp — quedó saldada en HE-03)

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
| HE-D5 | Guion narrativo completo sobre la historia rediseñada (GDD §1-§4, 18-Jul-2026): escena de intro (el living se transforma, Estelita choca contra la ventana, el Coleccionauta se lleva a papá), escenas de historia por planeta (entrega de pieza de la nave + video-llamada de papá) y primera versión de `guion_voces.md`; decidir P2 (voces de la familia — sinergia con las video-llamadas de papá) | ⬜ Backlog | HE-D2, HE-D3 | PO + Dev |

## FASE 1 — Cimientos (herramientas y esqueleto)

**Criterio de salida**: el proyecto Godot abre, muestra una pantalla placeholder, las herramientas IA (skills + MCP) están operativas y está definida la guía de estilo visual.

| ID | Tarjeta | Estado | Dependencias | Responsable |
|---|---|---|---|---|
| HE-01 | Instalar Godot 4.x, crear `project.godot` con config base (720p, canvas_items, input táctil+mouse), estructura de carpetas del stack §3, e instalar GodotPrompter (skills) + godot-mcp (stack §4) | ✅ Hecho | — | Dev |
| HE-02 | Guía de estilo visual: paleta maestra, contorno, tipografía; diseño SVG de los 3 hermanos y Estelita (pose idle) según lo definido en HE-D2, con aprobación de los QA junior | ⬜ Backlog | HE-D2 | Dev + PO |
| HE-03 | Completar pipeline de assets: probar SVG→PNG por lote, evaluar MCP de generación de imágenes y GDAI MCP; registrar decisión en stack §7 | ✅ Hecho | HE-01 | Dev |
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
| HE-17 | Escena de historia del planeta + destellos otorgados + pieza de la nave ganada y visible en "El hangar estelar" (pantalla de progreso que reemplaza a "El cielo de casa", GDD §3 rediseñado) | ⬜ Backlog | HE-14, HE-15, HE-16 | Dev |
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
| HE-30 | Cinemática/escena inicial según la historia rediseñada: el living se transforma + Estelita choca contra la ventana + el Coleccionauta se lleva a papá (guion de HE-D5, se puede saltar; ya no es "la caída de Estelita") | ⬜ Backlog | HE-27 | Dev |
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
- **[18-Jul-2026]** HE-D2 (adelanto visual, sigue ⬜; HE-D1 sigue 🔄) — El PO aprobó el estilo visual validado con el sprite de Maxi. Mockups SVG de los tres hermanos creados en `assets/fuentes_svg/personajes/`: `maxi_base.svg`, `maxi_celebracion.svg` (festejo real de Maxi: salto con puño arriba), `nicole_base.svg` (traje blanco/rosa, diadema, saludando) y `sofia_base.svg` (traje rosa, pelo rizado con volumen, audífonos rosados, brazos cruzados de hermana mayor), coherentes con la referencia oficial `assets/hermanosestelares.jpeg`. La insignia del cinturón personaliza a cada hermano: Maxi ya tiene dinosaurio; Nicole y Sofía llevan estrella provisional hasta completar sus entrevistas (pendiente del PO en HE-D1). Se validó el pipeline SVG→PNG con el rasterizador interno de Godot 4.7.1 headless (`Image.load_svg_from_string` → `save_png`), insumo directo para HE-03; los PNG de verificación quedaron junto a los SVG (PO + Dev).
- **[18-Jul-2026]** HE-D2 (refinamiento visual, sigue ⬜) — Tras feedback del PO se refinaron las siluetas de los mockups en `assets/fuentes_svg/personajes/`: torsos entallados en lugar de cajas anchas (Nicole con cintura; Sofía más delgada y estilizada, la más alta; Maxi con cuerpo de niño pequeño conservando la pancita) y se corrigieron los cuellos de Nicole y Sofía que dejaban las cabezas "flotando". PNG de verificación regenerados con Godot headless. Estilo aprobado por el PO como base. Ajuste adicional por feedback del PO: en `sofia_base.svg` se reemplazó la pose de brazos cruzados por una más femenina y natural (mano en la cadera + brazo relajado), dejando visible la estrella del pecho; PNG regenerado con Godot headless (PO + Dev).
- **[18-Jul-2026]** HE-D2 (rediseño fiel a la portada, sigue ⬜; HE-D1 sigue 🔄) — Tras análisis crítico contra la referencia visual oficial `assets/hermanosestelares.jpeg` y decisiones del PO, se rediseñaron los 4 sprites de `assets/fuentes_svg/personajes/` para captar la esencia de la portada: tonos de piel reales por hermano (Maxi el más claro, Nicole trigueña clara, Sofía trigueña→morena), ojos más grandes y expresiones propias (Nicole sonrisita pícara, Sofía sonrisa serena), pelo de Nicole con volumen/raya al lado y mechones, remolino de Maxi, sombreado con gradientes y sombra facial, rodilleras metálicas, botas con correas/hebillas, cinturones con estuches, aretes en ambas niñas, mochila rosa de Nicole y acentos turquesa de Sofía (audífonos, muñequera, cinturón, botas). Decisión del PO: la estrella del pecho queda dorada en los tres hermanos (se descarta la estrella blanca de Nicole que aparece en la portada). PNG regenerados con Godot headless (PO + Dev).
- **[18-Jul-2026]** HE-03 ✅ — Pipeline de assets completado. Conversión por lote SVG→PNG con `herramientas/exportar_sprites.gd` (SceneTree headless, sin dependencias externas): recorre `assets/fuentes_svg/` recursivamente, rasteriza con `Image.load_svg_from_string` y guarda el PNG espejo en el destino canónico `assets/sprites/` (stack §5), con escala opcional (`-- --escala=2.0`); los 4 PNG de verificación duplicados junto a los SVG se movieron a `assets/sprites/personajes/`. Añadido `herramientas/.gdignore` (Godot ya no escanea ~900 archivos de tooling en cada import). Verificación: exportación headless → "4 PNG generados, 0 errores" (EXIT=0), inspección visual de `maxi_base.png` (512×768) correcta, y la escena principal corre sin errores. Deuda de HE-01 cerrada: conexión viva de godot-mcp ejercitada por stdio JSON-RPC (handshake initialize OK, `get_godot_version` → 4.7.1.stable, `get_project_info` OK). Evaluaciones registradas en stack §4.2 y §7 (5 decisiones nuevas): GDAI MCP no se adopta ahora (reevaluar en Fase 2); Recraft MCP queda como candidato para fondos con decisión del PO pospuesta a HE-13 — nada contratado ni instalado (Dev).
- **[18-Jul-2026]** HE-D1 (parcial, sigue 🔄) — Entrevista de Sofía completada en `docs/perfil-jugadores.md`. Dato importante: **Sofía cumplió 8 años en junio de 2026** (ya no 7). Claves de su ficha: la mejor de su curso, lectora y resolutiva, líder natural, canta y baila muy bien, bromista con humor inteligente, «mini mamá» con sus hermanos; se frustra y llora rápido (más que sus hermanos) y tiene celos de hermana con Nicole (no con Maxi). Animales: ponys, gerbos, cachorros; colores rosa y turquesa (confirma los acentos del sprite). Cultura pop: My Melody, Harry Potter, Rumi de Las guerreras k-pop. Juega Roblox, LEGO en consola, juegos con historia, puzzles y de aprender (teléfono, PS5, PC). Rechazo (no fobia) a arañas/bichos — evitarlos. Considera «de bebés» los juegos fáciles. Celebración real: mano en la cintura, piernas flectadas a un lado, brazo estirado con signo de la paz, guiño y cabeza ladeada. Quiere ser «alguien importante y muy inteligente (una líder)»; muy curiosa de todos los mundos con datos interesantes. Implicaciones de diseño escritas en la ficha: nivel estrella con desafío real, frustración como riesgo principal → pistas y cero castigo, jamás comparar progreso con Nicole por los celos, celebración replicando su pose, insignia de cinturón propuesta: pony (pendiente de confirmación en HE-D2). Edad 7→8 propagada en `CLAUDE.md` (descripción y regla de oro, 2-8 años), `docs/diseno-juego.md` (tabla de personajes §2 y título §6), `docs/stack-tecnico.md` (QA de 2, 5 y 8 años) y `.claude/agents/dev-godot.md`. Pendiente para cerrar HE-D1: entrevista de Nicole (5) (PO + Dev).
- **[18-Jul-2026]** HE-D1 (parcial, sigue 🔄) — Entrevista de Nicole (5, nivel brote) registrada en `docs/perfil-jugadores.md`, **parcial**: el PO completó personalidad, animales/colores, personajes y gesto de celebración; quedan 3 campos pendientes que irá completando (apps/juegos que usa, qué la asusta/aburre, sueños/mundos). Claves de su ficha: adorable, siempre contenta, muy popular («mejor compañera» todos los años en su colegio), chistosa, muy solidaria y le gusta compartir; la más extrovertida de los tres, hace amigos sin miedo al ridículo; muchísima imaginación, le encanta dibujar y pintar; muy femenina, cariñosa y regalona de su papá. Animales: caballos, ponys, gatitos y jirafas; color favorito: rosa (confirma su traje/mochila del sprite). Personajes: guerreras k-pop, princesa Sofía, princesas Disney. Celebración real: corazón coreano con expresión tierna. Implicaciones de diseño escritas en la ficha: dibujar/pintar como gancho seguro (Pinta con Coco), momentos sociales/de voz, compartir como mecánica emocional (sinergia Planeta Corazón), rosa dominante y princesas como inspiración sin copiar IP, celebración replicando el corazón coreano, equidad total con Sofía (celos), e insignia de cinturón propuesta: corazón rosa (pendiente de confirmación, distinta del pony de Sofía). Además, adelanto visual de HE-D2 (sigue ⬜): creado `assets/fuentes_svg/personajes/sofia_celebracion.svg` (pose real de Sofía: mano en la cintura, signo de la paz, guiño) y PNG exportado por lote con el pipeline de HE-03 (5 PNG regenerados, 0 errores); pendiente de aprobación de Sofía/PO. Criterio del SM: HE-D1 se mantiene 🔄 porque dos de los campos pendientes de Nicole (apps/juegos y qué la asusta/aburre) forman parte del alcance explícito de la tarjeta — no cumple el DoD punto 1 hasta que el PO los complete (PO + Dev).
- **[18-Jul-2026]** HE-D2 (adelanto visual, sigue ⬜; HE-D1 sigue 🔄 sin cambios) — **Insignia de Nicole confirmada por el PO: corazón rosa**; se reemplazó la estrella provisional del cinturón en `assets/fuentes_svg/personajes/nicole_base.svg` (ya no está pendiente). Creado `assets/fuentes_svg/personajes/nicole_celebracion.svg` con su gesto real: corazón coreano con índice y pulgar cruzados y un corazoncito rosa brotando del gesto, expresión tierna (ojos grandes con brillo extra, sonrisita, mejillas sonrojadas), cabeza levemente ladeada, mano en la cadera, rodillas juntitas con puntas de botas hacia adentro, y corazoncitos/estrellitas de festejo; insignia de corazón también en su cinturón. PNG regenerados con el pipeline de HE-03 (Godot headless): 6 PNG generados, 0 errores; verificación visual de `nicole_base.png` y `nicole_celebracion.png` correcta (en la primera iteración el casco tapaba la mano del gesto; se corrigió bajando el brazo). Pendientes derivados actualizados: confirmar insignia pony de Sofía, aprobación de `sofia_celebracion` y `nicole_celebracion` (mostrárselo a Nicole), y los 3 campos de la entrevista de Nicole en HE-D1 (PO + Dev).
- **[18-Jul-2026]** HE-D2 (rediseño de la historia por decisión del PO, adelanto informal — sigue ⬜; HE-D1 sigue 🔄 sin cambios) — GDD `docs/diseno-juego.md` §1-§4 reescritos y descripción de `CLAUDE.md` actualizada. **Nueva premisa** (estilo "aventura empoderadora" a lo Jimmy Neutron): los tres hermanos juegan en el living y en su imaginación un alienígena coleccionista chistoso — **el Coleccionauta** (nombre provisional, validar con los niños) — se lleva a **papá** para su colección de "las cosas más increíbles del universo". Estelita (estrellita guía, NO parte de la familia) choca contra la ventana, les da los trajes con estrellas de poder y la nave-estrella incompleta. En cada planeta aprenden habilidades y ganan la **pieza de la nave** de ese mundo; los minijuegos siguen otorgando **destellos** (energía estelar). El planeta final se abre al reunir las piezas: sin batalla — le enseñan al Coleccionauta que "los amigos no se coleccionan, se hacen", rescatan a papá y vuelven al living donde papá los llama a comer. **Salvaguardas de tono (GDD §6)**: el secuestro jamás da miedo — todo es su juego imaginado, el alien es cómico y papá aparece en video-llamadas divertidas y tranquilas durante el viaje, sin presión de rescate. **Decisiones del PO registradas**: solo papá secuestrado (no mamá); alien = coleccionista chistoso; el guía es Estelita (se reusa diseño/nombre); coleccionable = piezas de la nave; la historia queda como adelanto informal de HE-D2. **Roles en §2**: Sofía = líder de la misión (lee pistas, arma el plan); Nicole = embajadora artista (hace amigos con los anfitriones y dibuja recuerdos); Maxi = explorador valiente; nuevos personajes de apoyo: el Coleccionauta y Papá (video-llamadas, sinergia con P2 voces reales). **§3**: hub rumbo al planeta del Coleccionauta, "El hangar estelar" (la nave armándose) reemplaza a "El cielo de casa" como pantalla de progreso, y se añade el planeta final del rescate; **§4**: la escena de historia por planeta entrega la pieza + video-llamada de papá. Impacto anotado en tarjetas: HE-30 (cinemática inicial rediseñada), HE-D5 (hereda este guion) y HE-17 (hangar estelar) (PO + Dev).
