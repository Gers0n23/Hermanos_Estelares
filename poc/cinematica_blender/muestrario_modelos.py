"""Muestrario: pone en fila los modelos descargados, ya con el look pintado, para elegir cuáles usar.

  blender -b -P muestrario_modelos.py -- --modelos lollypop,strawberry,pudding --fotos 1
Opciones: --carpeta RUTA (por defecto el Food Kit de Kenney), --nombre BASE, --salida CARPETA
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nave_comun import *  # noqa: E402,F401,F403
from planeta_comun import *  # noqa: E402,F401,F403

carpeta = arg("--carpeta", DULCES)
nombres = str(arg("--modelos", "")).split(",") if arg("--modelos") else \
    sorted(os.path.splitext(f)[0] for f in os.listdir(carpeta) if f.endswith(".glb"))
preparar_render(1)
cielo([(0.0, "#FFE9D6"), (1.0, "#C39DD6")])
ESC.world.node_tree.nodes["Mix"].inputs[0].default_value = 1.0
por_fila = 6
vistos = set()
for i, n in enumerate(nombres):
    fila, col = divmod(i, por_fila)
    modelo(os.path.join(carpeta, n + ".glb"), alto=1.6, pos=((col - (por_fila - 1) / 2) * 2.3, 0, -fila * 2.4),
           giro=float(arg("--giro", 0.5)), por="mayor", redondear=int(arg("--redondear", 0)))
    print("MATERIALES", n, sorted({m.name.split("_")[1] for m in bpy.data.materials if m.name.startswith("imp_")
                                   and m.users and m.name not in vistos}))
    vistos.update(m.name for m in bpy.data.materials)
filas = (len(nombres) - 1) // por_fila + 1
sol()
o_cam, mira, cam = camara(50)
o_cam.location = (0, -22, 0.8 - (filas - 1) * 1.2 + 1.5)
mira.location = (0, 0, 0.8 - (filas - 1) * 1.2)
compositor()
salidas(arg("--nombre", "muestrario"))
