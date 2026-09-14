# Genera voces PROVISIONALES con el TTS de Windows (decision del PO 06-Ago-2026, GDD 9 P2).
# Lee un TSV "ruta<TAB>texto" (ruta relativa a assets/audio/) y escribe un WAV mono 22 kHz por linea.
# Uso: powershell -NoProfile -File herramientas/generar_voces_tts.ps1 [-Lista <tsv>] [-Voz <nombre>] [-Velocidad <-10..10>]
# Las lineas bajo una directiva "# personaje: <id>" ya tienen voz de personaje generada con
# herramientas/generar_voces_fal.py (PO 14-Sep-2026): este script las salta para no pisarlas.
param(
	[string]$Lista = "assets/audio/voces/arcoiris/emparejar/lineas_tts.tsv",
	[string]$Voz = "Microsoft Sabina Desktop",
	[int]$Velocidad = -1
)
Add-Type -AssemblyName System.Speech
$raiz = Split-Path -Parent $PSScriptRoot
$formato = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$personaje = ""
foreach ($linea in Get-Content -Encoding UTF8 (Join-Path $raiz $Lista)) {
	if ($linea.Trim() -match '^#\s*personaje:\s*(.*)$') { $personaje = $Matches[1].Trim(); continue }
	if ($linea.Trim() -eq "" -or $linea.StartsWith("#") -or $personaje -ne "") { continue }
	$partes = $linea -split "`t", 2
	$destino = Join-Path $raiz ("assets/audio/" + $partes[0])
	New-Item -ItemType Directory -Force (Split-Path -Parent $destino) | Out-Null
	$sintetizador = New-Object System.Speech.Synthesis.SpeechSynthesizer
	$sintetizador.SelectVoice($Voz)
	$sintetizador.Rate = $Velocidad
	$sintetizador.SetOutputToWaveFile($destino, $formato)
	$sintetizador.Speak($partes[1])
	$sintetizador.Dispose()
	Write-Output "voz: $($partes[0])"
}
