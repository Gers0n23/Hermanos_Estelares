#!/usr/bin/env bash
# Recorta las piezas de un personaje, reconstruye su rig y saca las hojas de revisión
# (saludo + poses extremas para las articulaciones) en .ojos/.
#   bash herramientas/probar_rig.sh maxi|nicole
set -e
P="${1:?uso: probar_rig.sh maxi|nicole}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"
GODOT="${GODOT_PATH:-$(python -c "import json;print(json.load(open('.mcp.json'))['mcpServers']['godot-mcp']['env']['GODOT_PATH'])")}"
python "herramientas/cortar_piezas_$P.py" | grep -E "casquetes|kra"
mkdir -p "assets/sprites/preview_${P}_rig"
for f in "assets/generadas/${P}_piezas/"[a-z]*.png; do cp "$f" "assets/sprites/preview_${P}_rig/"; done
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --script "herramientas/armar_rig_${P}_preview.gd" 2>&1 | grep -E "Escena|SCRIPT ERROR" || true
"$GODOT" --headless --path . --script "herramientas/armar_rig_${P}_preview.gd" -- prueba 2>&1 | grep -E "Escena|SCRIPT ERROR" || true
bash herramientas/ojos.sh escena="res://escenas/personajes/vista_previa_rig_${P}.tscn" tiempos=0.1,1.0,1.3,1.6 columnas=4 recorte=440,20,420,460 salida="res://.ojos/${P}_saludo.png"
bash herramientas/ojos.sh escena="res://escenas/personajes/vista_previa_rig_${P}_prueba.tscn" tiempos=0.5,1.7,2.7,3.7 columnas=4 salida="res://.ojos/${P}_prueba.png"
bash herramientas/ojos.sh escena="res://escenas/personajes/vista_previa_rig_${P}_prueba.tscn" tiempos=1.7,2.7 columnas=2 recorte=440,180,400,400 salida="res://.ojos/${P}_prueba_zoom.png"
