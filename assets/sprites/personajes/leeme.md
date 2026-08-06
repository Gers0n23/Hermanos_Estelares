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
