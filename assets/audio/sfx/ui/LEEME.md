# SFX de interfaz (curado inicial, HE-04)

Set mínimo de efectos de UI para arrancar el núcleo del juego (botones, toques,
navegación). Copiados desde la biblioteca CC0 de terceros
(`assets/terceros/kenney/interface-sounds/`, pack **Interface Sounds** de Kenney,
licencia CC0 1.0 — ver `assets/terceros/LICENCIAS.md`) y renombrados en español para
que el código nunca referencie nombres genéricos `click_001.ogg`.

| Archivo | Uso previsto | Origen (Kenney) |
|---|---|---|
| `toque.ogg` | Toque simple sobre un elemento interactivo (botón, carta, ícono) | `click_001.ogg` |
| `confirmar.ogg` | Acción confirmada con éxito (acierto, avanzar de pantalla) | `confirmation_002.ogg` |
| `abrir.ogg` | Abrir una pantalla/panel (mapa, zona de padres) | `open_002.ogg` |
| `cerrar.ogg` | Cerrar una pantalla/panel | `close_002.ogg` |
| `seleccionar.ogg` | Selección de un ítem (p. ej. elegir personaje) | `select_003.ogg` |
| `soltar.ogg` | Soltar un elemento arrastrado en su lugar | `drop_002.ogg` |
| `no_es_este.ogg` | Feedback amistoso de "todavía no" (NUNCA un buzzer de error — GDD §6, ficha `docs/fichas/motor-emparejar.md` §6) | `error_002.ogg` |

Este set es intencionalmente pequeño (un archivo por categoría) para no bloquear el
resto del núcleo; se puede ampliar variando con `_002`, `_003`, etc. del mismo pack
cuando un motor concreto necesite variedad para evitar monotonía (p. ej. varias
variantes de `confirmar` en el motor "emparejar").

Reproducir siempre vía el autoload `Audio` (`scripts/autoloads/audio.gd`):

```gdscript
Audio.reproducir_sfx("res://assets/audio/sfx/ui/toque.ogg")
```
