#!/usr/bin/env bash
# Lanzador de herramientas/ojos.gd: toma GODOT_PATH de .mcp.json (misma ruta que godot-mcp)
# y pasa los argumentos tal cual. Ejemplos:
#   herramientas/ojos.sh escena=res://escenas/nucleo/titulo.tscn tiempos=0.5,2 toques=180,600@1
#   herramientas/ojos.sh svg=assets/fuentes_svg/personajes/maxi_base.svg ref=assets/anclas/maxi_referencia.png
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd -W 2>/dev/null || pwd)"
GODOT="${GODOT_PATH:-$(python -c "import json;print(json.load(open(r'$RAIZ/.mcp.json'))['mcpServers']['godot-mcp']['env']['GODOT_PATH'])")}"
"$GODOT" --path "$RAIZ" --script herramientas/ojos.gd -- "$@" 2>&1 | grep -E "^ojos:|ERROR|SCRIPT ERROR|at: " || true
