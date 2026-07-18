# Hook SessionStart: inyecta el estado actual del tablero Kanban vigente
# (docs/TABLERO.md) como contexto de la sesion, sea cual sea el roadmap activo.
$ErrorActionPreference = 'SilentlyContinue'

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = (Get-Location).Path }
$tablero = Join-Path $root 'docs\TABLERO.md'
if (-not (Test-Path $tablero)) { exit 0 }

$lines = Get-Content $tablero -Encoding UTF8
$dentro = $false
$salida = @()
foreach ($linea in $lines) {
    if ($linea -match '^## .*ESTADO ACTUAL') { $dentro = $true; continue }
    if ($dentro -and $linea -match '^## ') { break }
    if ($dentro) { $salida += $linea }
}

if ($salida.Count -gt 0) {
    Write-Output '[Estado del tablero Kanban activo (docs/TABLERO.md)]'
    $salida | Where-Object { $_ -ne '' -and $_ -ne '---' } | Write-Output
}
exit 0
