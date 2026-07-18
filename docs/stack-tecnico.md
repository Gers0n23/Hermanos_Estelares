# Los Hermanos Estelares — Stack técnico y estructura del proyecto

- **Última actualización**: 17-Jul-2026
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
  - `Progreso` — perfiles de los 3 hermanos, destellos, estrellas, guardado automático (JSON en `user://`).
  - `Audio` — buses de música/efectos/voz, reproducción de narraciones con cola.
  - `Navegacion` — transiciones entre escenas con animación (la nave-estrella como cortina de transición).
- **Escenas**: una escena por pantalla; cada minijuego es una escena autocontenida que recibe `nivel: semilla|brote|estrella` y emite `senal completado(destellos)`. Contrato único → agregar minijuegos nunca toca el núcleo.
- **Recursos de datos** (`.tres` o JSON): definición de planetas y minijuegos (nombre, ícono, escena, destellos) para que el mapa estelar se construya por datos.
- **Tests**: alcance pragmático — smoke tests con [GUT](https://github.com/bitwes/Gut) para `Progreso` y utilidades; los minijuegos se validan jugando (los QA tienen 2, 5 y 7 años 🙂).

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
| **[GDAI MCP](https://gdaimcp.com)** ([plugin](https://github.com/3ddelano/gdai-mcp-plugin-godot)) | Propietario, el más pulido según comparativas 2026 | Crear escenas/nodos/recursos, screenshots automáticos del editor y del juego corriendo, debugger, edición GDScript | **A evaluar en HE-03** — si la fricción de editar `.tscn` como texto resulta alta, se adopta |
| Godot MCP Pro / Summer Engine | Comerciales (163 tools / nivel motor) | Control total del editor, generación de assets | Descartados por ahora — sobredimensionados para este alcance |

**Flujo de trabajo resultante**: Claude escribe escenas/scripts como texto (formato `.tscn` legible) con los patrones de GodotPrompter → ejecuta la escena vía godot-mcp → lee errores/salida → corrige. El DoD del tablero exige este ciclo antes de cerrar cualquier tarjeta.

## 5. Pipeline de assets (sprites, animaciones)

Estilo objetivo: cartoon vectorial (ver GDD §7). Estrategia en capas, de más controlable a más generativa:

1. **SVG generado por código** (disponible hoy, sin instalar nada): Claude escribe los SVG de personajes/props directamente (formas vectoriales redondas se prestan muy bien a esto), se versionan en `assets/fuentes_svg/` y se exportan a PNG. Godot 4 además **importa SVG nativamente**. Conversión por lote: `resvg` o Inkscape CLI.
2. **MCP de generación de imágenes** (a instalar, tarjeta HE-03): evaluar un servidor MCP de generación (p. ej. Recraft — especializado en vectorial/SVG —, o similar) para fondos y escenas complejas donde dibujar SVG a mano no rinde. Criterio de selección: que produzca vectorial o alta resolución con estilo consistente, y licencia clara.
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
