extends SceneTree

## Calibración de «¿Quién habla?» (motor topos): juega N rondas por nivel con el jugador simulado de cada
## edad y muestra el % de victorias con la meta del nivel, los percentiles de aciertos por ronda (p10, p25,
## p40: la regla del PO HE-124) y los del puntaje de 2 rondas (p50 y p80: umbrales de estrellitas).
## No escribe nada: los números se copian a mano en herramientas/generar_niveles_topos.py.
##
## Uso: godot --headless --path . --script herramientas/simular_topos.gd [-- <rondas>]

const Jugador := preload("res://herramientas/jugador_simulado_topos.gd")
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 300
	print("perfil   zona  meta  gana%  ac_p10 ac_p25 ac_p40 ac_p50 | pts2_p50 pts2_p80")
	for perfil in ["semilla", "brote", "estrella"]:
		for z in ZONAS.size():
			var ruta := "res://datos/niveles/animalia/%s/topos_%s.json" % [ZONAS[z], perfil]
			var nivel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
			var logica := LogicaTopos.new()
			logica.configurar(nivel, 1000 + z)
			var jugador = Jugador.new(logica, perfil, 77 + z)
			var aciertos: Array = []
			var puntos: Array = []
			var ganadas := 0
			for i in n:
				var r: Dictionary = jugador.jugar_ronda()
				aciertos.append(r["aciertos"])
				puntos.append(r["puntaje"])
				if r["gano"]:
					ganadas += 1
			var dos_rondas: Array = []
			for i in range(0, puntos.size() - 1, 2):
				dos_rondas.append(puntos[i] + puntos[i + 1])
			print("%-8s z%d   %3d  %5.1f  %6d %6d %6d %6d | %8d %8d" % [perfil, z + 1, logica.meta, 100.0 * ganadas / n,
				Jugador.percentil(aciertos, 0.1), Jugador.percentil(aciertos, 0.25), Jugador.percentil(aciertos, 0.4),
				Jugador.percentil(aciertos, 0.5), Jugador.percentil(dos_rondas, 0.5), Jugador.percentil(dos_rondas, 0.8)])
	quit(0)
