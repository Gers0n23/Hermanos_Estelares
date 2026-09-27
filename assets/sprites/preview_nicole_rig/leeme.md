# Rig de cutout de Nicole (vista previa técnica)

Las 11 piezas de esta carpeta arman `escenas/personajes/vista_previa_rig_nicole.tscn`
(generador: `herramientas/armar_rig_nicole_preview.gd`). Misma estructura que Sofía:
Nicole también lleva túnica, así que tiene pieza `cinturon` (cinturón + faldones) que va
delante de las piernas, y la cabeza va al fondo (la melena cae detrás de hombros y brazos).

- Base `assets/generadas/nicole_piezas/00_base_nicole.png`: vista frontal de la ancla
  aprobada `assets/anclas/nicole_referencia.png`, aislada con `herramientas/extraer_base.py`
  (matte por diferencia contra el degradé gris: la burbuja del casco queda semitransparente
  de verdad, el traje rosa pálido opaco y la sombra del piso fuera).
- Cortes: `herramientas/cortar_piezas_nicole.py`. Los cortes "a mano" (torso, cinturón,
  brazos) son polígonos trazados sobre una grilla ampliada de la base; piernas y cabeza son
  lo que queda. Articulaciones redondeadas como las de Sofía (`herramientas/articulaciones.py`),
  con melena pintada detrás de los hombros para que al levantar un brazo no quede un hueco
  en el pelo, y casquetes de cadera sin línea (bajo la túnica el pantalón es continuo).
- Pivotes en `assets/generadas/nicole_piezas/pivotes.json`; capas para Krita en
  `assets/generadas/nicole_piezas/01_piezas_nicole.kra`.

Regenerar y revisar: `bash herramientas/probar_rig.sh nicole`

Verificado: en reposo la fusión es idéntica a la base (1 píxel de antialias distinto,
0 sin cubrir); saludo y poses extremas revisadas con `herramientas/ojos.gd`.
Detalle menor: al levantar mucho el brazo asoman 1–2 puntas finas de pelo que el dibujo
original tenía pegadas al brazo.

**Estado**: sin auditar por `experto-ux-parvulo` ni aprobar por el PO.
