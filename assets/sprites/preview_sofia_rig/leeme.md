# Qué es este arte y para qué sirve

Las 11 piezas de esta carpeta (`torso.png`, `cabeza_casco.png`, `cinturon.png`,
`brazo_sup_izq/der.png`, `antebrazo_mano_izq/der.png`, `pierna_sup_izq/der.png`,
`pierna_inf_pie_izq/der.png`) son el **rig de cutout articulado de Sofía**: el personaje
jugable **animado en escena** (idle/saludo de prueba hoy; caminar/celebrar reales quedan
pendientes de implementar). Arman `escenas/personajes/vista_previa_rig_sofia.tscn`
(jerarquía + pivotes en `docs/guia-corte-piezas.md` §7, generador en
`herramientas/armar_rig_sofia_preview.gd`).

Cortadas a mano en Krita por el PO siguiendo `docs/guia-corte-piezas.md`
(`assets/generadas/sofia_piezas/`, carpeta de staging con `.gdignore`). Esta carpeta es la
copia **importable por Godot** de esas mismas piezas.

**Estado**: auditadas por `experto-ux-parvulo` y aprobadas por el PO el 05-Ago-2026
(`docs/auditorias-ux/2026-08-05_rig-sofia.md`) — ya no son un preview sin auditar. El nombre
`preview_sofia_rig` de la carpeta quedó desactualizado por eso; **no la renombré ni la moví**
a `assets/sprites/personajes/` en esta pasada porque no fue lo que se pidió — si corresponde
promoverla/renombrarla como parte de una tarjeta formal, es una limpieza pendiente a futuro
(dejar nota al `scrum-master`).

Para el ícono/thumbnail estático de Sofía (selección de personaje, HUD, donde no hace falta
animación) se sigue usando el arte plano en `assets/sprites/personajes/sofia_base.png` /
`sofia_celebracion.png` — ver el `leeme.md` de esa carpeta.
