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
# Godot no usa JAVA_HOME: exige la ruta del JDK en su configuracion del editor
$ajustes = Get-ChildItem (Join-Path $env:APPDATA "Godot") -Filter "editor_settings-4*.tres" | Sort-Object Name | Select-Object -Last 1
if ($ajustes -and $env:JAVA_HOME) {
    $texto = [IO.File]::ReadAllText($ajustes.FullName)
    if ($texto -match '(?m)^export/android/java_sdk_path = ""') {
        $ruta = $env:JAVA_HOME -replace '\\', '/'
        [IO.File]::WriteAllText($ajustes.FullName, ($texto -replace '(?m)^export/android/java_sdk_path = ""', "export/android/java_sdk_path = `"$ruta`""))
        Write-Host "JDK configurado en Godot: $ruta"
    }
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
    # Godot escribe avisos por stderr; en PowerShell 5.1 eso no debe cortar el script
    $ErrorActionPreference = "Continue"
    & $godot --headless --path $raiz --export-debug "Android" $apk 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match "ERROR|savepack|export" } | ForEach-Object { Write-Host "  $_" }
    $ErrorActionPreference = "Stop"
} finally {
    [IO.File]::WriteAllText($presets, $original)
}
if (-not (Test-Path $apk) -or (Get-Item $apk).LastWriteTime -lt (Get-Date).AddMinutes(-5)) {
    throw "No se genero el APK. Revisa los errores de arriba."
}
$mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "APK listo: $apk ($mb MB)"
if ($SoloExportar) { return }

# adb tambien avisa por stderr; de aqui en adelante se revisa $LASTEXITCODE
$ErrorActionPreference = "Continue"
# start-server con Start-Process: si el daemon hereda el pipe, el script queda esperando para siempre
Start-Process -FilePath $adb -ArgumentList "start-server" -NoNewWindow -Wait
if (-not $Wifi) {
    # Telefono ya vinculado por depuracion inalambrica: se busca en la red (mDNS)
    Start-Sleep -Seconds 3
    $red = & $adb mdns services | Select-String "_adb-tls-connect\._tcp\s+(\S+)" | Select-Object -First 1
    if ($red -and -not (& $adb devices | Select-String "\tdevice$")) { $Wifi = $red.Matches[0].Groups[1].Value }
}
if ($Wifi) { & $adb connect $Wifi | Write-Host }
$dispositivos = & $adb devices | Select-String "\tdevice$"
if (-not $dispositivos) {
    Write-Host "No hay telefono conectado. Conectalo por USB (depuracion USB activa) o usa -Wifi IP:PUERTO."
    Write-Host "El APK quedo en exports/ por si prefieres instalarlo a mano."
    exit 1
}
# Por wifi el mismo telefono puede aparecer dos veces (IP y nombre mDNS): se usa uno solo
$serial = if ($Wifi) { $Wifi } else { ($dispositivos[0].Line -split "\t")[0] }
Write-Host "Instalando en el telefono ($serial) ..."
& $adb -s $serial install --no-incremental -r -d $apk
if ($LASTEXITCODE -ne 0) { throw "adb install fallo." }
& $adb -s $serial shell monkey -p $paquete -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host "Listo: $version instalada y abierta en el telefono."
