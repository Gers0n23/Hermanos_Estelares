extends RefCounted

## Sonidos de animales y efectos de «¿Quién habla?» sintetizados por código (motor `topos`). PROVISIONALES
## hasta los sonidos reales CC0 que pide la ficha (motor-topos.md §7.4, planeta-animalia-zonas.md §10): si el
## nivel trae `sonido` con un archivo que existe, el motor usa ese archivo y esto no se llama.
##
## Cada sonido es una lista de tramos `[f0, f1, segundos, forma, vib_hz, vib_prof, ruido, volumen]`:
## la frecuencia va de f0 a f1, `forma` elige los armónicos (seno | suave | cuadrada | sierra | nasal |
## ruido | silencio), el vibrato hace el temblor del relincho o del balido y `ruido` agrega aire (ladrido,
## bufido). Todos duran <= 0,9 s y tienen ataque claro (§7.4). Los dinos de Maxi suenan muy distintos entre
## sí (rugido grave, glu-glu, bufido, muuu grave, estornudo, pío-grrr; §8.2).

const FRECUENCIA := 22050
const ATAQUE := 0.012

const ARMONICOS := {
	"seno": [1.0],
	"suave": [1.0, 0.35, 0.1],
	"cuadrada": [1.0, 0.0, 0.33, 0.0, 0.2, 0.0, 0.14],
	"sierra": [1.0, 0.5, 0.33, 0.25, 0.2, 0.16],
	"nasal": [0.5, 0.9, 1.0, 0.7, 0.4, 0.25],
}

const SONIDOS := {
	# Granja y casa
	"vaca": [[125, 98, 0.78, "sierra", 4, 0.02, 0.02, 1.0]],
	"perro": [[540, 300, 0.14, "nasal", 0, 0, 0.3, 1.0], [0, 0, 0.08, "silencio"], [580, 320, 0.16, "nasal", 0, 0, 0.3, 1.0]],
	"perrito": [[780, 470, 0.12, "nasal", 0, 0, 0.25, 1.0], [0, 0, 0.07, "silencio"], [820, 500, 0.13, "nasal", 0, 0, 0.25, 1.0]],
	"perrito_bombero": [[700, 1150, 0.2, "suave", 0, 0, 0, 0.8], [1150, 700, 0.2, "suave", 0, 0, 0, 0.8], [700, 1150, 0.2, "suave", 0, 0, 0, 0.8], [1150, 700, 0.2, "suave", 0, 0, 0, 0.8]],
	"gato": [[520, 860, 0.25, "nasal", 6, 0.02, 0.03, 1.0], [860, 520, 0.35, "nasal", 6, 0.02, 0.03, 1.0]],
	"gatito": [[820, 1260, 0.2, "nasal", 7, 0.02, 0.02, 0.9], [1260, 860, 0.3, "nasal", 7, 0.02, 0.02, 0.9]],
	"pato": [[480, 420, 0.15, "cuadrada", 40, 0.06, 0.15, 1.0], [0, 0, 0.07, "silencio"], [470, 400, 0.17, "cuadrada", 40, 0.06, 0.15, 1.0]],
	"ganso": [[320, 290, 0.3, "cuadrada", 22, 0.05, 0.12, 1.0], [0, 0, 0.07, "silencio"], [310, 270, 0.32, "cuadrada", 22, 0.05, 0.12, 1.0]],
	"gallo": [[700, 900, 0.1, "nasal", 0, 0, 0.05, 1.0], [900, 900, 0.1, "nasal", 0, 0, 0.05, 1.0], [900, 1150, 0.12, "nasal", 0, 0, 0.05, 1.0], [1150, 800, 0.42, "nasal", 7, 0.04, 0.05, 1.0]],
	"pollito": [[2200, 3000, 0.08, "seno", 0, 0, 0, 0.8], [0, 0, 0.08, "silencio"], [2300, 3100, 0.08, "seno", 0, 0, 0, 0.8], [0, 0, 0.08, "silencio"], [2200, 3000, 0.09, "seno", 0, 0, 0, 0.8]],
	"caballo": [[900, 1250, 0.15, "nasal", 14, 0.06, 0.05, 1.0], [1250, 560, 0.6, "nasal", 16, 0.08, 0.05, 1.0]],
	"pony": [[1350, 1750, 0.12, "nasal", 18, 0.06, 0.03, 0.9], [1750, 950, 0.45, "nasal", 18, 0.07, 0.03, 0.9]],
	"pony_estelar": [[1568, 1568, 0.13, "seno", 0, 0, 0, 0.8], [2093, 2093, 0.13, "seno", 0, 0, 0, 0.8], [2637, 2637, 0.13, "seno", 0, 0, 0, 0.8], [3136, 3136, 0.36, "seno", 5, 0.01, 0, 0.8]],
	"burro": [[880, 950, 0.2, "sierra", 0, 0, 0.05, 1.0], [300, 280, 0.24, "sierra", 0, 0, 0.05, 1.0], [880, 950, 0.18, "sierra", 0, 0, 0.05, 1.0], [300, 270, 0.26, "sierra", 0, 0, 0.05, 1.0]],
	"oveja": [[300, 290, 0.65, "nasal", 7, 0.06, 0.05, 1.0]],
	"cabra": [[540, 500, 0.55, "nasal", 12, 0.11, 0.04, 1.0]],
	"cabrita": [[780, 730, 0.5, "nasal", 13, 0.1, 0.03, 0.9]],
	"chancho": [[230, 180, 0.14, "cuadrada", 0, 0, 0.35, 1.0], [0, 0, 0.06, "silencio"], [240, 170, 0.16, "cuadrada", 0, 0, 0.35, 1.0]],
	"gerbo": [[3000, 3500, 0.07, "seno", 0, 0, 0, 0.7], [0, 0, 0.05, "silencio"], [3200, 3700, 0.06, "seno", 0, 0, 0, 0.7], [0, 0, 0.05, "silencio"], [3100, 3600, 0.08, "seno", 0, 0, 0, 0.7]],
	"cuy": [[1500, 2400, 0.12, "nasal", 0, 0, 0, 0.8], [2400, 1800, 0.08, "nasal", 0, 0, 0, 0.8], [0, 0, 0.06, "silencio"], [1500, 2400, 0.12, "nasal", 0, 0, 0, 0.8], [2400, 1800, 0.08, "nasal", 0, 0, 0, 0.8]],
	# Laguna y costa
	"lobo_marino": [[270, 230, 0.15, "sierra", 0, 0, 0.2, 1.0], [0, 0, 0.08, "silencio"], [280, 230, 0.15, "sierra", 0, 0, 0.2, 1.0], [0, 0, 0.08, "silencio"], [265, 220, 0.16, "sierra", 0, 0, 0.2, 1.0]],
	"huillin": [[1800, 2200, 0.15, "seno", 8, 0.05, 0, 0.8], [0, 0, 0.05, "silencio"], [2000, 1500, 0.22, "seno", 0, 0, 0, 0.8]],
	"hipopotamo": [[115, 92, 0.2, "sierra", 0, 0, 0.1, 1.0], [0, 0, 0.05, "silencio"], [105, 85, 0.2, "sierra", 0, 0, 0.1, 1.0], [0, 0, 0.05, "silencio"], [98, 80, 0.26, "sierra", 0, 0, 0.1, 1.0]],
	"elefante": [[500, 720, 0.15, "cuadrada", 9, 0.04, 0.05, 1.0], [720, 650, 0.55, "cuadrada", 9, 0.04, 0.05, 1.0]],
	"pinguino": [[700, 760, 0.12, "sierra", 0, 0, 0.05, 1.0], [360, 330, 0.12, "sierra", 0, 0, 0.05, 1.0], [700, 760, 0.12, "sierra", 0, 0, 0.05, 1.0], [360, 330, 0.12, "sierra", 0, 0, 0.05, 1.0], [760, 600, 0.34, "sierra", 6, 0.03, 0.05, 1.0]],
	"flamenco": [[620, 570, 0.2, "nasal", 0, 0, 0.1, 1.0], [0, 0, 0.06, "silencio"], [640, 560, 0.24, "nasal", 0, 0, 0.1, 1.0]],
	"ballena": [[300, 620, 0.4, "seno", 3, 0.02, 0, 1.0], [620, 250, 0.48, "seno", 3, 0.02, 0, 1.0]],
	# Pradera y altiplano
	"jirafa": [[96, 96, 0.78, "suave", 3, 0.01, 0.0, 1.0]],
	"alpaca": [[180, 230, 0.72, "suave", 5, 0.03, 0.0, 1.0]],
	"cebra": [[700, 920, 0.12, "nasal", 0, 0, 0.15, 1.0], [500, 440, 0.12, "nasal", 0, 0, 0.15, 1.0], [0, 0, 0.05, "silencio"], [700, 920, 0.12, "nasal", 0, 0, 0.15, 1.0], [500, 440, 0.16, "nasal", 0, 0, 0.15, 1.0]],
	"guanaco": [[1200, 1500, 0.2, "nasal", 20, 0.1, 0.05, 1.0], [1500, 1100, 0.32, "nasal", 20, 0.1, 0.05, 1.0]],
	"huemul": [[250, 205, 0.48, "sierra", 5, 0.03, 0.2, 1.0]],
	"pudu": [[920, 860, 0.36, "nasal", 10, 0.08, 0.02, 0.9]],
	"nandu": [[82, 76, 0.26, "seno", 0, 0, 0.1, 1.0], [0, 0, 0.1, "silencio"], [86, 74, 0.32, "seno", 0, 0, 0.1, 1.0]],
	# Árbol y selva
	"mono": [[400, 500, 0.1, "nasal", 0, 0, 0.05, 1.0], [500, 600, 0.1, "nasal", 0, 0, 0.05, 1.0], [0, 0, 0.04, "silencio"], [720, 920, 0.12, "nasal", 0, 0, 0.05, 1.0], [920, 820, 0.16, "nasal", 0, 0, 0.05, 1.0]],
	"mono_aullador": [[200, 265, 0.8, "sierra", 4, 0.05, 0.35, 1.0]],
	"perezoso": [[2600, 2400, 0.6, "seno", 4, 0.02, 0, 0.7]],
	"loro": [[800, 1100, 0.15, "nasal", 30, 0.08, 0.2, 1.0], [1100, 700, 0.32, "nasal", 30, 0.08, 0.2, 1.0]],
	"tucan": [[350, 320, 0.1, "cuadrada", 0, 0, 0.3, 1.0], [0, 0, 0.06, "silencio"], [350, 320, 0.1, "cuadrada", 0, 0, 0.3, 1.0], [0, 0, 0.06, "silencio"], [340, 300, 0.12, "cuadrada", 0, 0, 0.3, 1.0]],
	"buho": [[380, 360, 0.25, "seno", 0, 0, 0, 1.0], [0, 0, 0.12, "silencio"], [380, 340, 0.36, "seno", 0, 0, 0, 1.0]],
	"lechuza": [[2000, 1800, 0.55, "nasal", 0, 0, 0.6, 0.8]],
	"tricahue": [[1400, 1600, 0.12, "nasal", 0, 0, 0.3, 1.0], [1600, 1200, 0.2, "nasal", 0, 0, 0.3, 1.0], [0, 0, 0.06, "silencio"], [1400, 1600, 0.12, "nasal", 0, 0, 0.3, 1.0], [1600, 1200, 0.2, "nasal", 0, 0, 0.3, 1.0]],
	"choroy": [[2000, 2300, 0.08, "nasal", 0, 0, 0.25, 0.9], [0, 0, 0.04, "silencio"], [2050, 2350, 0.08, "nasal", 0, 0, 0.25, 0.9], [0, 0, 0.04, "silencio"], [2000, 2300, 0.08, "nasal", 0, 0, 0.25, 0.9], [0, 0, 0.04, "silencio"], [2100, 2400, 0.09, "nasal", 0, 0, 0.25, 0.9]],
	"carpintero": [[1000, 1000, 0.03, "ruido", 0, 0, 1, 1.0], [0, 0, 0.04, "silencio"], [1000, 1000, 0.03, "ruido", 0, 0, 1, 1.0], [0, 0, 0.04, "silencio"], [1000, 1000, 0.03, "ruido", 0, 0, 1, 1.0], [0, 0, 0.04, "silencio"], [1000, 1000, 0.03, "ruido", 0, 0, 1, 1.0], [0, 0, 0.04, "silencio"], [1000, 1000, 0.03, "ruido", 0, 0, 1, 1.0], [0, 0, 0.04, "silencio"], [1000, 1000, 0.03, "ruido", 0, 0, 1, 1.0]],
	"chucao": [[900, 700, 0.15, "seno", 0, 0, 0, 1.0], [0, 0, 0.08, "silencio"], [1100, 600, 0.3, "seno", 0, 0, 0, 1.0]],
	"condor": [[600, 300, 0.6, "ruido", 0, 0, 1, 0.8]],
	"milodon": [[92, 70, 0.55, "sierra", 0, 0, 0.3, 1.0]],
	# Dinos de Maxi
	"trex": [[150, 88, 0.72, "sierra", 6, 0.08, 0.35, 1.0]],
	"spinosaurio": [[300, 520, 0.1, "seno", 0, 0, 0, 1.0], [520, 300, 0.1, "seno", 0, 0, 0, 1.0], [0, 0, 0.03, "silencio"], [300, 520, 0.1, "seno", 0, 0, 0, 1.0], [520, 300, 0.1, "seno", 0, 0, 0, 1.0], [700, 200, 0.3, "ruido", 0, 0, 1, 0.9]],
	"carnotauro": [[180, 140, 0.15, "sierra", 0, 0, 0.6, 1.0], [900, 400, 0.38, "ruido", 0, 0, 1, 0.9]],
	"triceratops": [[86, 70, 0.8, "sierra", 3, 0.02, 0.05, 1.0]],
	"braquiosaurio": [[300, 620, 0.4, "nasal", 0, 0, 0.1, 1.0], [2200, 300, 0.36, "ruido", 0, 0, 1, 1.0]],
	"dinito": [[2000, 2600, 0.12, "seno", 0, 0, 0, 0.8], [190, 150, 0.4, "sierra", 25, 0.1, 0.3, 0.9]],
	# Personajes y efectos
	"toby": [[680, 430, 0.12, "nasal", 0, 0, 0.25, 1.0], [0, 0, 0.06, "silencio"], [720, 460, 0.14, "nasal", 0, 0, 0.25, 1.0]],
	"toby_dorado": [[2093, 2093, 0.1, "seno", 0, 0, 0, 0.7], [2637, 2637, 0.1, "seno", 0, 0, 0, 0.7], [3136, 3136, 0.1, "seno", 0, 0, 0, 0.7], [4186, 4186, 0.3, "seno", 6, 0.01, 0, 0.7]],
	"impostor": [[320, 420, 0.1, "nasal", 0, 0, 0.05, 1.0], [0, 0, 0.04, "silencio"], [360, 460, 0.1, "nasal", 0, 0, 0.05, 1.0], [0, 0, 0.04, "silencio"], [400, 520, 0.1, "nasal", 0, 0, 0.05, 1.0], [0, 0, 0.04, "silencio"], [450, 300, 0.3, "nasal", 8, 0.05, 0.05, 1.0]],
	"risita_hoyo": [[1200, 1400, 0.07, "nasal", 0, 0, 0, 0.7], [0, 0, 0.05, "silencio"], [1300, 1500, 0.07, "nasal", 0, 0, 0, 0.7], [0, 0, 0.05, "silencio"], [1400, 1750, 0.09, "nasal", 0, 0, 0, 0.7]],
	"achis": [[400, 900, 0.25, "nasal", 0, 0, 0.1, 1.0], [2400, 300, 0.32, "ruido", 0, 0, 1, 1.0]],
	"tierrita": [[1800, 600, 0.16, "ruido", 0, 0, 1, 0.5]],
	"fiuu": [[1400, 500, 0.35, "seno", 0, 0, 0, 0.45]],
	"plop": [[500, 160, 0.12, "seno", 0, 0, 0, 0.9]],
}

var _cache := {}


func tiene(id: String) -> bool:
	return SONIDOS.has(id)


## El stream del sonido (se sintetiza una sola vez y queda en caché). Un id desconocido suena como "perrito".
func stream(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var tramos: Array = SONIDOS.get(id, SONIDOS["perrito"])
	var wav := sintetizar(tramos, hash(id))
	_cache[id] = wav
	return wav


static func duracion(id: String) -> float:
	var total := 0.0
	for tramo in SONIDOS.get(id, []):
		total += float(tramo[2])
	return total


static func sintetizar(tramos: Array, semilla: int = 1) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var muestras := PackedFloat32Array()
	var fase := 0.0
	var filtro := 0.0
	for tramo in tramos:
		var f0 := float(tramo[0])
		var f1 := float(tramo[1])
		var dur := float(tramo[2])
		var forma := str(tramo[3])
		var n := int(dur * FRECUENCIA)
		if forma == "silencio":
			for i in n:
				muestras.append(0.0)
			continue
		var vib_hz := float(tramo[4]) if tramo.size() > 4 else 0.0
		var vib_prof := float(tramo[5]) if tramo.size() > 5 else 0.0
		var ruido := float(tramo[6]) if tramo.size() > 6 else 0.0
		var vol := float(tramo[7]) if tramo.size() > 7 else 1.0
		var armonicos: Array = ARMONICOS.get(forma, ARMONICOS["seno"])
		var suma := 0.0
		for w in armonicos:
			suma += float(w)
		var liberar := minf(0.06, dur * 0.3)
		for i in n:
			var t := float(i) / FRECUENCIA
			var k := t / dur
			var f := lerpf(f0, f1, k) * (1.0 + vib_prof * sin(TAU * vib_hz * t))
			fase += TAU * f / FRECUENCIA
			var v := 0.0
			if forma != "ruido":
				for h in armonicos.size():
					var w := float(armonicos[h])
					if w == 0.0 or f * (h + 1) > FRECUENCIA * 0.45:
						continue
					v += w * sin(fase * (h + 1))
				v /= suma
			# Ruido filtrado (pasa bajos de un polo): el "aire" del ladrido, el bufido o el estornudo.
			if ruido > 0.0:
				var a := clampf(TAU * maxf(f, 200.0) / FRECUENCIA, 0.02, 1.0)
				filtro += a * (rng.randf_range(-1.0, 1.0) - filtro)
				v = v * (1.0 - ruido) + filtro * ruido * 2.2
			var env := minf(1.0, t / ATAQUE) * minf(1.0, (dur - t) / liberar)
			muestras.append(v * env * vol)
	var pico := 0.001
	for m in muestras:
		pico = maxf(pico, absf(m))
	var datos := PackedByteArray()
	datos.resize(muestras.size() * 2)
	var escala := 0.85 / pico
	for i in muestras.size():
		datos.encode_s16(i * 2, int(clampf(muestras[i] * escala, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = FRECUENCIA
	wav.stereo = false
	wav.data = datos
	return wav
