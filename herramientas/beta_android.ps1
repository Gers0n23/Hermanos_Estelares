# Genera un APK beta del juego y lo instala en el telefono (sin abrir Android Studio).
#
# Uso (desde la raiz del repo):
#   powershell -File herramientas/beta_android.ps1                 # exporta + instala por USB o wifi ya conectado
#   powershell -File herramientas/beta_android.ps1 -Wifi 192.168.1.50:41234   # conecta por depuracion inalambrica
#   powershell -File herramientas/beta_android.ps1 -SoloExportar   # solo deja el APK en exports/
#
# Cada beta reemplaza a la anterior conservando el guardado (mismo paquete + misma firma debug).
# La version visible es 0.1-beta.<n.o de commits>+<commit>, para saber que build tiene el telefono.
param(
    [string]$Wifi = "",
    [switch]$SoloExportar
)
$ErrorActionPreference = "Stop"

$raiz = Split-Path -Parent $PSScriptRoot
$paquete = "com.cordero.hermanosestelares"
$apk = Join-Path $raiz "exports\hermanos_estelares_beta.apk"
$presets = Join-Path $raiz "export_presets.cfg"

# Godot: misma ruta que usa godot-mcp
$godot = (Get-Content (Join-Path $raiz ".mcp.json") -Raw | ConvertFrom-Json).mcpServers.'godot-mcp'.env.GODOT_PATH
$sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$adb = Join-Path $sdk "platform-tools\adb.exe"
if (-not $env:JAVA_HOME) {
    $java = Get-ChildItem "C:\Program Files\Zulu", "C:\Program Files\Java", "C:\Program Files\Eclipse Adoptium" -Filter java.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($java) { $env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $java.FullName) }
}

# Numero de version a partir del historial de git
$n = (git -C $raiz rev-list --count HEAD).Trim()
$sha = (git -C $raiz rev-parse --short HEAD).Trim()
$sucio = if (git -C $raiz status --porcelain) { "-wip" } else { "" }
$version = "0.1-beta.$n+$sha$sucio"

# Parcha la version solo durante el export y deja el archivo como estaba
$original = [IO.File]::ReadAllText($presets)
$parchado = $original -replace '(?m)^version/code=.*$', "version/code=$n" -replace '(?m)^version/name=.*$', "version/name=`"$version`""
New-Item -ItemType Directory -Force (Split-Path -Parent $apk) | Out-Null
try {
    [IO.File]::WriteAllText($presets, $parchado)
    Write-Host "Exportando $version ..."
    & $godot --headless --path $raiz --export-debug "Android" $apk 2>&1 | Where-Object { $_ -match "ERROR|error|savepack|Export" } | ForEach-Object { Write-Host "  $_" }
} finally {
    [IO.File]::WriteAllText($presets, $original)
}
if (-not (Test-Path $apk) -or (Get-Item $apk).LastWriteTime -lt (Get-Date).AddMinutes(-5)) {
    throw "No se genero el APK. Revisa los errores de arriba."
}
$mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "APK listo: $apk ($mb MB)"
if ($SoloExportar) { return }

if ($Wifi) { & $adb connect $Wifi | Write-Host }
$dispositivos = & $adb devices | Select-String "\tdevice$"
if (-not $dispositivos) {
    Write-Host "No hay telefono conectado. Conectalo por USB (depuracion USB activa) o usa -Wifi IP:PUERTO."
    Write-Host "El APK quedo en exports/ por si prefieres instalarlo a mano."
    exit 1
}
Write-Host "Instalando en el telefono ..."
& $adb install -r -d $apk
if ($LASTEXITCODE -ne 0) { throw "adb install fallo." }
& $adb shell monkey -p $paquete -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host "Listo: $version instalada y abierta en el telefono."
