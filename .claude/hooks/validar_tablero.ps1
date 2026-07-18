# Hook PostToolUse (Edit|Write): valida que el tablero Kanban conserve su
# estructura minima obligatoria despues de cada edicion, sin asumir el
# contenido concreto del roadmap (fases/epicas/IDs pueden cambiar libremente).
# Exit 2 = feedback bloqueante para que Claude restaure la estructura.
$ErrorActionPreference = 'SilentlyContinue'

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$archivo = $payload.tool_input.file_path
if (-not $archivo) { exit 0 }
if ($archivo -notmatch 'TABLERO\.md$') { exit 0 }
if (-not (Test-Path $archivo)) { exit 0 }

$contenido = Get-Content $archivo -Encoding UTF8 -Raw

# Secciones estructurales minimas que cualquier tablero de este harness debe conservar.
$secciones = @('ESTADO ACTUAL', 'MARCO DE TRABAJO', 'REGISTRO DE AVANCES')
$faltantes = @()
foreach ($s in $secciones) {
    if ($contenido -notmatch [regex]::Escape($s)) { $faltantes += $s }
}

# Debe existir al menos una tabla de fase/epica de backlog (nombre libre).
$tieneBacklog = $contenido -match '(?im)^##\s.*(FASE|EPICA|ÉPICA|BACKLOG)'
if (-not $tieneBacklog) { $faltantes += '(al menos una sección de FASE/ÉPICA/BACKLOG)' }

if ($faltantes.Count -gt 0) {
    [Console]::Error.WriteLine("La edicion dejo el tablero sin secciones obligatorias: $($faltantes -join ', '). Restaura la estructura minima (ESTADO ACTUAL, MARCO DE TRABAJO, al menos una fase/epica, REGISTRO DE AVANCES) antes de continuar.")
    exit 2
}
exit 0
