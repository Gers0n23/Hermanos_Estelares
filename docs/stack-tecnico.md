# Los Hermanos Estelares — Stack técnico y estructura del proyecto

- **Última actualización**: 18-Jul-2026 (HE-03: pipeline de assets por lote + evaluaciones MCP)
- Complementa al [GDD](diseno-juego.md). El *qué* está allá; aquí está el *con qué* y el *dónde*.

---

## 1. Motor y lenguaje

| Componente | Elección | Por qué |
|---|---|---|
| Motor | **Godot 4.x** (última estable 4.4+/4.5) | Gratuito, 2D excelente, exporta a Windows y Android, editor liviano |
| Lenguaje | **GDScript** | Sintaxis simple, integración total con el editor, más que suficiente para este alcance |
| Renderer | **Mobile** (Vulkan mobile) | Táctil-primero; rinde bien en tablet y PC |
| Resolución base | 1280×720, stretch `canvas_items` + aspect `expand` | Se adapta a cualquier tablet/monitor sin deformar |
| Entrada | Unificada táctil+mouse (`emulate_mouse_from_touch` y viceversa) | Un solo código de input para tablet y PC |

**Estado**: Godot **4.7.1 stable instalado** vía winget el 18-Jul-2026 (versión estándar, no .NET). Ejecutable de consola: `C:\Users\gcordero\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64_console.exe` (misma ruta configurada como `GODOT_PATH` en `.mcp.json`). Proyecto base (`project.godot`) creado en la raíz con la config de esta tabla; verificado ejecutando en headless y en ventana (Vulkan Forward Mobile) sin errores.

## 2. Arquitectura del juego (Godot)

- **Autoloads (singletons)**:
  - `Progreso` — perfiles de los 3 hermanos, destellos, estrellas, guardado automático (JSON **versionado** en `user://`, con migraciones al cargar — ver decisión del 18-Jul-2026).
  - `Audio` — buses de música/efectos/voz, reproducción de narraciones con cola.
  - `Navegacion` — transiciones entre escenas con animación (la nave-estrella como cortina de transición).
- **Escenas**: una escena por pantalla; cada minijuego es una escena autocontenida que recibe `nivel: semilla|brote|estrella` y emite `senal completado(destellos)`. Contrato único → agregar minijuegos nunca toca el núcleo.
- **Recursos de datos** (`.tres` o JSON): definición de planetas y minijuegos (nombre, ícono, escena, destellos) para que el mapa estelar se construya por datos.
- **Tests**: alcance pragmático — smoke tests con [GUT](https://github.com/bitwes/Gut) para `Progreso` y utilidades; los minijuegos se validan jugando (los QA tienen 2, 5 y 8 años 🙂).

## 3. Estructura de carpetas

El proyecto Godot vive en la **raíz del repo** (facilita abrir el editor y el tooling). Nombres en español, en minúsculas y sin acentos (los paths con acentos dan problemas multiplataforma):

```
Hermanos_Estelares/
├── project.godot
├── CLAUDE.md
├── docs/                      # Diseño, stack, tablero, guion de voces
├── escenas/
│   ├── nucleo/                # titulo, seleccion_personaje, mapa_estelar, cielo_casa, zona_padres
│   ├── ui/                    # botones grandes, estelita_ayudante, celebracion, transicion_nave
│   ├── personajes/            # maxi, nicole, sofia, estelita, anfitriones
│   └── planetas/
│       ├── arcoiris/          # planeta.tscn + un .tscn por minijuego
│       ├── animalia/
│       ├── melodia/
│       ├── cuenta_cuentas/
│       ├── letralandia/
│       └── corazon/
├── scripts/
│   ├── autoloads/             # progreso.gd, audio.gd, navegacion.gd
│   └── base/                  # minijuego_base.gd (contrato de nivel/señales), boton_gigante.gd
├── assets/
│   ├── fuentes_svg/           # SVG fuente de cada sprite (editable, versionado)
│   ├── sprites/               # PNG exportados que consume Godot (misma subestructura que escenas)
│   ├── audio/
│   │   ├── musica/  ├── sfx/  └── voces/   # voces/guion_voces.md lista cada línea a grabar
│   └── fuentes/               # tipografía redonda apta niños (ej. Baloo 2, OFL)
├── datos/                     # planetas.json / .tres — definición data-driven del contenido
├── tests/                     # GUT
└── .claude/                   # harness (agentes, skills, hooks)
```

## 4. Herramientas de IA para el desarrollo (skills + MCP)

Investigación realizada el 18-Jul-2026 (fuentes al pie). El ecosistema Godot+Claude maduró en dos capas complementarias que adoptamos ambas:

### 4.1 Capa de conocimiento — skills de GDScript

- **[GodotPrompter](https://github.com/jame581/GodotPrompter)** (MIT, gratuito, activo): 54 skills de mejores prácticas Godot 4.3+ que Claude carga bajo demanda — incluye justo lo que este juego necesita: `2d-essentials`, `animation-system` (AnimationPlayer/AnimationTree), `audio-system` (buses, pooling de SFX), `save-load`, controles de jugador, UI responsiva y HUD.
- Instalación: `claude plugin marketplace add jame581/skillsmith` + `claude plugin install godot-prompter@skillsmith` (subcomando en singular; verificado e **instalado el 18-Jul-2026** durante la PoC).
- Reduce el riesgo de "GDScript inventado": el agente sigue patrones idiomáticos verificados en vez de memoria.

### 4.2 Capa de control — MCP del editor Godot

Permite a Claude ejecutar el juego, leer errores en vivo y ver el editor en vez de trabajar a ciegas. Candidatos evaluados:

| Servidor | Naturaleza | Capacidades | Veredicto |
|---|---|---|---|
| **[godot-mcp (Coding-Solo)](https://github.com/Coding-Solo/godot-mcp)** | Open source, minimalista | Lanzar editor, ejecutar proyecto, capturar salida de debug | **Adoptado como base** — gratuito, auditable, suficiente para el ciclo editar→ejecutar→leer errores |
| **[GDAI MCP](https://gdaimcp.com)** ([plugin](https://github.com/3ddelano/gdai-mcp-plugin-godot)) | Propietario (binario cerrado), gratuito, el más pulido según comparativas 2026 | Crear escenas/nodos/recursos, screenshots automáticos del editor y del juego corriendo, debugger, edición GDScript | **Evaluado en HE-03: NO se adopta por ahora** — el flujo texto+headless funciona sin fricción (validado en HE-D2/HE-03), requiere el editor abierto y es binario no auditable. Se reevalúa si en Fase 2 (HE-05+) hace falta feedback visual (screenshots) |
| Godot MCP Pro / Summer Engine | Comerciales (163 tools / nivel motor) | Control total del editor, generación de assets | Descartados por ahora — sobredimensionados para este alcance |

**Flujo de trabajo resultante**: Claude escribe escenas/scripts como texto (formato `.tscn` legible) con los patrones de GodotPrompter → ejecuta la escena vía godot-mcp → lee errores/salida → corrige. El DoD del tablero exige este ciclo antes de cerrar cualquier tarjeta.

## 5. Pipeline de assets (sprites, animaciones)

Estilo objetivo: cartoon vectorial (ver GDD §7). Estrategia en capas, de más controlable a más generativa:

1. **SVG generado por código** (operativo desde HE-03): Claude escribe los SVG de personajes/props directamente (formas vectoriales redondas se prestan muy bien a esto), se versionan en `assets/fuentes_svg/` y se exportan a PNG en `assets/sprites/` (misma subestructura). **Conversión por lote** con el rasterizador SVG interno de Godot — sin dependencias externas (`resvg`/Inkscape descartados por innecesarios):

   ```powershell
   # Desde la raíz del repo (escala opcional con: -- --escala=2.0)
   & $env:GODOT --headless --path . --script herramientas/exportar_sprites.gd
   ```

   El script `herramientas/exportar_sprites.gd` recorre `assets/fuentes_svg/` recursivamente, rasteriza cada `.svg` (`Image.load_svg_from_string`) y guarda el `.png` espejo en `assets/sprites/`. La carpeta `herramientas/` tiene `.gdignore` para que Godot no importe tooling (godot-mcp, node_modules) como recursos del juego.
2. **MCP de generación de imágenes** (evaluado en HE-03, decisión pendiente del PO): el candidato recomendado es el [MCP oficial de Recraft](https://github.com/recraft-ai/mcp-recraft-server) — genera SVG vectorial editable con estilo consistente, ideal para fondos. Requiere API de pago (~USD 0.04/imagen, planes desde USD 10/mes con derechos comerciales). **No se contrata todavía**: se pospone la decisión hasta HE-13 (arte del primer planeta), cuando se sabrá si los fondos dibujados como SVG a mano + bibliotecas CC0 alcanzan. Si alcanzan, no se gasta nada.
3. **Bibliotecas CC0 de relleno**: [Kenney.nl](https://kenney.nl) (sprites, UI, audio) para props secundarios e íconos — calidad alta, dominio público, estilo compatible con cartoon.

**Animaciones**: cutout con `AnimationPlayer`/`Skeleton2D` sobre las partes del SVG (cabeza, brazos, piernas como nodos separados). Transiciones de pantalla con `Tween` + la nave de Estelita. Partículas de Godot para confeti/destellos (no requieren assets).

**Audio**: sfx y música CC0 (Kenney Audio, FreePD); voces según GDD §7 (grabadas en casa o TTS provisional). Formato: OGG Vorbis.

## 6. Control de versiones y builds

- **Git**: `.gitignore` estándar Godot (`.godot/`, exports). Los SVG fuente y PNG exportados **sí** se versionan (proyecto personal, tamaño manejable).
- **Exports**: Windows Desktop (desarrollo y PC de casa) y Android APK (tablet — requiere plantillas de export + JDK/SDK Android; se configura recién en Fase 5 para no pagar esa complejidad antes de tiempo).
- Sin CI por ahora: el "pipeline de release" es papá instalando el APK en la tablet.

## 7. Decisiones registradas

| Fecha | Decisión | Motivo |
|---|---|---|
| 17-Jul-2026 | Godot 4.x + GDScript, 2D puro | Alcance del proyecto y facilidad |
| 17-Jul-2026 | Un minijuego = una escena con parámetro `nivel` | 1 código, 3 edades; núcleo nunca cambia |
| 17-Jul-2026 | Proyecto Godot en la raíz del repo | Simplicidad de tooling |
| 17-Jul-2026 | Táctil-primero, input unificado con mouse | Decisión del Product Owner (17-Jul-2026) |
| 17-Jul-2026 | Arte vectorial SVG como fuente de verdad de sprites | Editable, escalable, generable por código |
| 18-Jul-2026 | Adoptar GodotPrompter (skills GDScript) + godot-mcp de Coding-Solo (control del editor); GDAI MCP en evaluación | Investigación §4: cierran el ciclo escribir→ejecutar→leer errores y anclan GDScript idiomático |
| 18-Jul-2026 | Guardado automático en GitHub al registrar avances del tablero (hook `guardar_github.ps1`) | Documentación continua del progreso pedida por el PO |
| 18-Jul-2026 | El diseño personalizado con los niños es la Fase 0 del roadmap | Nada se implementa si contradice lo que ellos aman (decisión del PO) |
| 18-Jul-2026 | Conversión SVG→PNG por lote con el rasterizador interno de Godot (`herramientas/exportar_sprites.gd`), destino canónico `assets/sprites/` | HE-03: cero dependencias externas (resvg/Inkscape innecesarios), mismo motor que consumirá los assets; validado con los 4 sprites de personajes |
| 18-Jul-2026 | `.gdignore` en `herramientas/` | Godot escaneaba ~900 archivos de tooling (godot-mcp + node_modules) en cada import; no son recursos del juego |
| 18-Jul-2026 | GDAI MCP: no se adopta por ahora (reevaluar en Fase 2 si hace falta feedback visual) | HE-03: el flujo texto+headless+godot-mcp cubre el ciclo completo sin fricción; GDAI es binario cerrado no auditable y exige editor abierto |
| 18-Jul-2026 | MCP de generación de imágenes: candidato Recraft (MCP oficial, SVG editable, ~USD 0.04/imagen); decisión de contratar pospuesta a HE-13 | HE-03: no gastar antes de saber si los fondos SVG a mano + CC0 (Kenney) alcanzan; la decisión final es del PO |
| 18-Jul-2026 | Conexión viva de godot-mcp verificada por stdio JSON-RPC (`initialize`, `get_godot_version` → 4.7.1, `get_project_info` sobre el proyecto) | HE-03: cierra la deuda declarada en HE-01; el servidor responde correcto con el `GODOT_PATH` de `.mcp.json` |
| 18-Jul-2026 | Rutas personalizadas: motores de mecánica compartidos + niveles data-driven por hermano (reemplaza al modelo "una escena con parámetro `nivel`" del 17-Jul; el contrato `minijuego_base.gd` pasa a recibir el archivo de nivel/contenido) | Decisión del PO (GDD §2/§5): la temática no escala con la dificultad; cada niño necesita contenido de sus gustos |
| 18-Jul-2026 | Lanzamiento por capítulos (seasons): maqueta del juego completo desde el capítulo 1, pero solo el planeta 1 jugable; un planeta nuevo por actualización | Decisión del PO (GDD §3): pulir cada mundo al máximo sin nada genérico y validar con la reacción de los niños antes de invertir en el siguiente |
| 18-Jul-2026 | **Guardado versionado desde el día uno**: el JSON de `Progreso` incluye campo `version` y migraciones al cargar; agregar planetas/capítulos por actualización jamás borra progreso | Derivado del lanzamiento por capítulos (GDD §3): las actualizaciones deben ser seguras para las partidas de los niños |
| 18-Jul-2026 | **Equipo de agentes especializados** en `.claude/agents/` (decisión del PO): 7 roles nuevos junto a `scrum-master` y `dev-godot` — `disenador-niveles`, `disenador-mecanicas`, `guionista`, `director-cinematicas`, `disenador-personajes`, `experto-ux-parvulo`, `tester-qa`. Los diseñadores producen specs/documentos (fichas en `docs/fichas/`, guiones en `docs/guiones/`, storyboards en `docs/cinematicas/`), `dev-godot` implementa, `experto-ux-parvulo` y `tester-qa` auditan (informes en `docs/auditorias-ux/` y `docs/qa/`); solo `scrum-master` toca el tablero | Calidad de primer orden por disciplina: cada rol nace leyendo su parte del canon (GDD, fichas, §6) con checklists propias; flujo idea → spec → implementación → auditoría → playtest real |
