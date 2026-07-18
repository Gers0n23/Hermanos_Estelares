# Hook PostToolUse (Edit|Write): cuando se edita docs/TABLERO.md (registro de un
# avance), guarda automaticamente el proyecto en GitHub: commit con la ultima
# entrada del Registro de Avances como mensaje + push a origin.
# Nunca bloquea (exit 0 siempre): si el push falla (sin red, sin credenciales),
# el commit local queda hecho y se informa por stdout.
$ErrorActionPreference = 'SilentlyContinue'

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$archivo = $payload.tool_input.file_path
if (-not $archivo) { exit 0 }
if ($archivo -notmatch 'TABLERO\.md$') { exit 0 }

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = (Get-Location).Path }
if (-not (Test-Path (Join-Path $root '.git'))) { exit 0 }

$contenido = Get-Content $archivo -Encoding UTF8 -Raw
if (-not $contenido) { exit 0 }

# No comitear un tablero estructuralmente invalido (misma regla que validar_tablero.ps1).
foreach ($s in @('ESTADO ACTUAL', 'MARCO DE TRABAJO', 'REGISTRO DE AVANCES')) {
    if ($contenido -notmatch [regex]::Escape($s)) { exit 0 }
}

# Mensaje de commit = ultima linea del Registro de Avances (la entrada recien agregada).
$lineas = ($contenido -split "`n") | Where-Object { $_ -match '^\s*-\s+\*\*\[' }
$ultima = if ($lineas) { ($lineas[-1] -replace '\*\*', '' -replace '^\s*-\s*', '').Trim() } else { $null }
$mensaje = if ($ultima) { "Avance: $ultima" } else { 'Avance registrado en el tablero' }

git -C $root add -A 2>$null | Out-Null
git -C $root diff --cached --quiet 2>$null
if ($LASTEXITCODE -eq 0) { exit 0 }  # nada que comitear

$msgFile = Join-Path $env:TEMP 'he_commit_msg.txt'
[IO.File]::WriteAllLines($msgFile, @($mensaje, '', 'Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>'), (New-Object Text.UTF8Encoding($false)))
git -C $root commit -F $msgFile 2>$null | Out-Null
Remove-Item $msgFile -Force

if ($LASTEXITCODE -ne 0) {
    Write-Output '[guardar_github] No se pudo crear el commit automatico del avance.'
    exit 0
}

git -C $root push origin HEAD 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Output "[guardar_github] Avance guardado en GitHub: $mensaje"
} else {
    Write-Output '[guardar_github] Commit local creado, pero el push a origin fallo (revisar red/credenciales). Ejecutar git push manualmente.'
}
exit 0
