# Qué es este arte y para qué sirve

`maxi_base.png`, `maxi_celebracion.png`, `nicole_base.png`, `nicole_celebracion.png`,
`sofia_base.png`, `sofia_celebracion.png` son el arte **plano** (pipeline SVG→PNG de
`herramientas/exportar_sprites.gd`, tarjeta HE-D2, previo a 23-Jul-2026).

**Para Sofía**, este arte plano **ya no es el personaje jugable animado en escena**: desde el
18-Jul-2026 el PO decidió que los personajes que se animan por cutout usan un rig articulado
por partes (`docs/stack-tecnico.md` §5.4), y el de Sofía vive en
`assets/sprites/preview_sofia_rig/` + `escenas/personajes/vista_previa_rig_sofia.tscn`
(auditado y aprobado por `experto-ux-parvulo` y el PO el 05-Ago-2026, ver
`docs/auditorias-ux/2026-08-05_rig-sofia.md`).

`sofia_base.png`/`sofia_celebracion.png` **no se borran** — siguen sirviendo como ícono/thumbnail
estático (pantalla de selección de personaje, HUD) donde no hace falta animación, solo una
imagen fija. No los conectes a una escena de personaje jugable en movimiento: para eso usá el
rig cutout.

Maxi y Nicole todavía no tienen rig cutout propio (solo Sofía, a la fecha de esta nota) — para
ellos, `*_base.png`/`*_celebracion.png` siguen siendo el único arte disponible, tanto para
ícono como para lo que se implemente de personaje jugable, hasta que se decida si también
migran a rig cutout.

`cometa_base.png` (HE-02, 06-Ago-2026) es el sprite idle/pose de reposo de **Cometa**, el
alien guía (reemplaza el nombre provisional "Estelita" — ficha aprobada en HE-A1). Mismas
reglas de estilo que los hermanos (`docs/guia-estilo-generacion.md` §6: contorno `#2B3350`,
paleta reutilizada, receta de ojos), fuente en
`assets/fuentes_svg/personajes/cometa_base.svg`. Todavía no tiene rig cutout ni pose de
celebración propia — eso queda para una tarjeta futura si Cometa necesita animarse más allá
de un ícono/sprite estático.

## Actualización 07-Ago-2026 — `sofia_base.png` ahora se genera desde el rig cutout

Con el rig de Sofía ya auditado y aprobado (`docs/auditorias-ux/2026-08-05_rig-sofia.md`), el
PO pidió reemplazar el retrato "oficial" (el que consumen `titulo.tscn`,
`seleccion_personaje.tscn` y `scripts/nucleo/mapa_estelar.gd`, los tres apuntando al mismo
`res://assets/sprites/personajes/sofia_base.png`) por arte generado a partir de ese rig, en vez
del pipeline SVG→PNG plano de HE-D2 descrito arriba.

`sofia_base.png` ya **no** sale de un SVG escrito a mano: se genera con
`herramientas/renderizar_retrato_sofia.gd` (headless, `godot --headless --path . --script
herramientas/renderizar_retrato_sofia.gd`), que compone por alfa (CPU, sin viewport/GPU) las 11
piezas de `assets/sprites/preview_sofia_rig/` en pose de reposo (rotación 0 en todas las
piezas — el mismo sistema de coordenadas del lienzo de 332×768 de
`herramientas/armar_rig_sofia_preview.gd`, así que a rotación cero cada pieza ya cae alineada
sin necesitar reconstruir el árbol de nodos) y centra el resultado en un lienzo de 512×768 para
mantener el mismo tamaño que el PNG anterior — así ningún `.tscn`/`.gd` necesitó tocarse, todos
siguen apuntando al mismo path. Volver a ejecutar ese script si las piezas del rig cambian.

`sofia_celebracion.png` **no se tocó**: sigue siendo el arte plano anterior (pose de saludo con
guiño del pipeline SVG→PNG). El rig cutout hoy solo tiene pose de reposo + una animación de
saludo de vista previa (`vista_previa_rig_sofia.tscn`), no una pose de celebración diseñada
para ícono estático — inventar esa pose es una decisión de `disenador-personajes`/PO, pendiente
si se quiere migrar también el ícono de celebración al rig.
