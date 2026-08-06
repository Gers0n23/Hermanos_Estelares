# Brief de sistema de diseño — Hermanos Estelares

Brief de arranque para el proyecto **"Hermanos Estelares"** creado en Claude Design
(`https://claude.ai/design/p/717510b9-d276-4817-a467-3af12c714e52`), pensado para las
pantallas de interfaz del juego (título, selección de personaje, mapa estelar, HUD de
minijuego, celebración, hangar estelar, zona de padres). No reemplaza la guía de arte de
personajes/entornos (`docs/guia-estilo-generacion.md`) — la resume para uso de UI y añade
las reglas de interacción que un sistema de diseño de pantallas necesita.

Este documento es la fuente; el texto de la sección "Prompt para pegar en Claude Design"
es lo que se lleva al proyecto para arrancar la conversación con el agente de diseño ahí.

## 1. Concepto

Tres hermanos (Maxi 2, Nicole 5, Sofía 8) juegan en el living de su casa e imaginan una
aventura espacial guiados por el alien Cometa. Táctil-primero (tablet Android), también
jugable en PC. Es un regalo personal de un papá para sus hijos — la calidad que importa es
que a ellos les encante: ternura, celebración y accesibilidad infantil ante todo.

**Tono**: asombro, ternura y aventura. Cálido, nunca frío ni corporativo. Prohibido:
oscuridad amenazante, criaturas que asusten, texto obligatorio, cualquier cosa que castigue
o frustre a un niño de 2-8 años.

## 2. Paleta de color

Sin hex codes definidos aún en el proyecto — se derivan aquí de la biblia de arte
(`guia-estilo-generacion.md` §3) como punto de partida a refinar visualmente en Claude
Design, no como valores cerrados:

- **Fondo espacial**: violeta/púrpura profundo — `#3B2A6B` a `#241847` en degradé.
- **Dorado estelar** (acento principal, brillos, estrellas, CTAs): `#FFC94A` / `#FFD97A`.
- **Turquesa** (acento secundario, UI activa): `#4DD9C0`.
- **Rosado suave** (acento terciario, ternura/celebración): `#FF9EC4`.
- **Blanco cálido** para texto/paneles sobre fondo oscuro: `#FFF8EE`.
- Luz general cálida, rim light dorado/rosado — evitar negros puros y grises fríos.

Paleta por planeta (para las tarjetas del mapa estelar y fondos de minijuego):

| Planeta | Paleta dominante |
|---|---|
| 1. Arcoíris | Multicolor pastel |
| 2. Animalia | Verdes selva |
| 3. Melodía | Morados y neón suave |
| 4. Cuenta-Cuentas | Azules noche |
| 5. Letralandia | Naranjas cálidos |
| 6. Corazón | Rosas y celestes |

## 3. Tipografía y texto

- El juego **no usa texto obligatorio** para jugar (todo narrado por voz, navegación por
  íconos) — pero la UI sí necesita una tipografía para la **zona de padres**, créditos y
  posible material de apoyo.
- Elegir una fuente redondeada, geométrica, muy legible, tipo "cuento infantil" — nunca
  condensada ni de trazo fino/corporativo. Pesos gruesos para cualquier texto que aparezca.
- Nada de texto dentro de las ilustraciones/fondos generados (regla fija de la biblia de
  arte).

## 4. Estilo visual

- Cartoon vectorial pintado, contornos suaves, degradados atmosféricos, saturación alta
  pero tierna. Ni fotorrealismo ni anime.
- Esquinas y formas siempre redondeadas — nunca ángulos filosos, coherente con el mundo
  (cascos burbuja, naves ovaladas, muebles de cantos redondeados).
- Iconografía universal y grande para navegación (casa, flecha, estrella) — cero texto para
  moverse por el juego.
- Ilustraciones de referencia de personajes/entornos ya aprobadas en `assets/anclas/`
  (Cometa, los tres hermanos, papá, el Coleccionauta, Camaleona Coco, Toby, la casa/living,
  la nave-estrella) — usarlas como referencia de fidelidad de mundo al maquetar pantallas
  que los incluyan.

## 5. Reglas de UX infantil (obligatorias, GDD §6 — no negociables)

1. **Objetivos táctiles enormes**: mínimo ~96px lógicos para elementos que un niño de 2
   años deba tocar; nada interactivo por debajo de 64px.
2. **Todo se narra por voz**: ninguna instrucción depende de saber leer.
3. **Sin texto para navegar**: solo íconos universales + audio.
4. **Sin dobles toques ni gestos complejos**: solo tocar y arrastrar (mismo código para
   mouse en PC).
5. **Respuesta inmediata**: todo elemento tocado reacciona en <100ms con animación y
   sonido, incluso si es "incorrecto".
6. **Cero publicidad, compras o enlaces externos.** 100% offline.
7. **Zona de padres protegida** con candado adulto (ej: mantener presionado 3s + resolver
   una cuenta simple).
8. **Salir siempre es seguro**: nunca se pierde progreso.
9. **Feedback de celebración generoso**: confeti, estrellas, bailecito y frase de ánimo al
   completar cualquier cosa.
10. **Controles de volumen independientes** (música/efectos/voz) por perfil.

## 6. Pantallas / componentes a cubrir (orden sugerido)

Según el flujo del juego (GDD §3):

1. **Pantalla de título** — animada, "tocar para empezar", sin texto obligatorio.
2. **Selección de personaje** — 3 retratos grandes (Maxi/Nicole/Sofía), define la ruta.
3. **Mapa Estelar (hub)** — la nave navegando entre los 6 planetas; planetas no
   desbloqueados se ven "lejos", nunca con candado ni "próximamente".
4. **Tarjeta/entrada de planeta** — previo a un minijuego.
5. **HUD dentro de un minijuego** — mínimo, iconos grandes, botón de volver al mapa
   siempre accesible.
6. **Pantalla de celebración** — al completar un nivel/planeta (confeti, destellos
   ganados).
7. **El hangar estelar** — progreso de la nave armándose pieza a pieza.
8. **Zona de padres** — candado adulto, ajustes, volumen, progreso por hijo.

Componentes base transversales: botón táctil primario/secundario, ícono de navegación,
tarjeta de planeta (bloqueada/lejana vs. disponible), indicador de destellos/progreso,
overlay de celebración, teclado numérico simple del candado adulto.

## Prompt para pegar en Claude Design

Al abrir el proyecto (link arriba), pegar esto como primer mensaje al agente de diseño:

```
Estoy armando el sistema de diseño de pantallas para "Hermanos Estelares", un juego 2D
infantil (niños de 2 a 8 años) táctil-primero para tablet Android, también jugable en PC.
Tono: asombro, ternura y aventura — cartoon vectorial pintado, contornos suaves,
degradados atmosféricos, nunca oscuro ni amenazante.

Paleta: fondo espacial violeta/púrpura profundo, acento principal dorado estelar,
secundario turquesa, terciario rosado suave, blanco cálido para texto. Formas siempre
redondeadas, nunca ángulos filosos.

Reglas de interacción NO negociables (son para niños de 2-8 años):
- Objetivos táctiles mínimo 96px, nunca menor a 64px.
- Cero texto para navegar — solo íconos universales grandes + lugar para audio.
- Sin gestos complejos: solo tocar y arrastrar.
- Feedback visual inmediato y generoso (celebración con confeti/estrellas) en cualquier
  interacción.

Empecemos por los tokens base (paleta, tipografía redondeada infantil, radios, sombras
suaves) y el componente de botón táctil primario/secundario. Después seguimos con: pantalla
de título, selección de personaje (3 retratos grandes), mapa estelar (hub de planetas),
tarjeta de planeta, HUD de minijuego, overlay de celebración, hangar estelar (progreso) y
zona de padres con candado.
```

---

*Generado el 06-Ago-2026 como brief inicial. El sistema de diseño se construye directamente
en Claude Design (proyecto "Hermanos Estelares", sin librería de componentes codificada
local) — este documento es la referencia de marca/UX que lo alimenta, no un artefacto
sincronizado por `/design-sync`.*
