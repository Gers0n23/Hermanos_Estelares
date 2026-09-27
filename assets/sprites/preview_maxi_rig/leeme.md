# Rig de cutout de Maxi (vista previa técnica)

Las 10 piezas de esta carpeta arman `escenas/personajes/vista_previa_rig_maxi.tscn`
(generador: `herramientas/armar_rig_maxi_preview.gd`), gemelo del rig de Sofía.

- `cabeza_casco.png` y `torso.png` (con cinturón): **cortadas a mano por el PO en Krita**
  (`assets/generadas/maxi_piezas/00_base_maxi.kra`, que no se modifica).
- Las otras 8 (`brazo_sup_*`, `antebrazo_mano_*`, `pierna_sup_*`, `pierna_inf_pie_*`):
  cortadas por `herramientas/cortar_piezas_maxi.py`.
- **Articulaciones redondeadas como las pintó el PO en Sofía** (`herramientas/articulaciones.py`):
  mismo orden de capas que Sofía (el torso tapa el hombro, el brazo tapa el codo, la
  rodillera tapa el muslo) y cada pieza de atrás termina en un casquete redondo pintado
  del color del traje, con su línea, escondido en reposo. Codo y rodilla con el pivote
  centrado en el miembro y disco = medio ancho: al girar no asoman esquinas ni flecos.
  Esto resolvió el borde dentado del brazo levantado (ya no hay retoque pendiente).
- Pivotes en `assets/generadas/maxi_piezas/pivotes.json` (los escribe el cortador, los lee el rig).
- Todas juntas, una capa por pieza, en `assets/generadas/maxi_piezas/01_piezas_maxi.kra`
  para retoques en Krita. Tras retocar: `python herramientas/kra.py exportar <kra> <carpeta>`.

Regenerar y revisar todo (piezas + rig + hojas de saludo y poses extremas en `.ojos/`):

    bash herramientas/probar_rig.sh maxi

Verificado: en reposo la fusión de piezas es idéntica a la base (0 píxeles sin cubrir);
en poses extremas (brazos arriba, codos y rodillas doblados) las uniones quedan redondas.
Límite conocido: con la cabeza muy inclinada (>0,2 rad) se ven dos anillos de cuello,
porque el corte a mano de `cabeza_casco` incluye el cuello del traje; en la animación
real (0,04 rad) no se nota.

**Estado**: sin auditar por `experto-ux-parvulo` ni aprobar por el PO.
