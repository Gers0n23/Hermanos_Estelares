class_name RecorridoRio
extends RefCounted

## Recorrido del "Río de pintura" (docs/roadmap-rio-de-pintura.md §4.4 y §12): la polilínea por la que
## ruedan las gotas, desde la nube de entrada hasta el remolino. Se describe en datos
## (`datos/recorridos/<planeta>/<id>.json`) para que `disenador-niveles` cree ríos sin tocar código.
##
## Tipos soportados:
## - "espiral": entrada recta + espiral elíptica hacia el centro (el río del mockup, zona 1).
##   Campos: centro [x,y], entrada [_, y_inicio] (la entrada sube en vertical desde y_inicio hasta el
##   primer punto de la espiral), radio_inicio, radio_fin, angulo_inicio y angulo_fin (en múltiplos
##   de PI), escala [sx, sy].
## - "puntos": puntos de control de una Curve2D suavizada. Campos: puntos [[x,y], ...], suavizado (0-1).
##
## La distancia `s` se mide desde el primer punto del recorrido; `s < 0` es "todavía en la nube"
## (la gota no se ve) y `s >= largo` es "se la tragó el remolino".
##
## `puente_batidora` (opcional; docs/fichas/motor-rio.md §10.1 y §13.2): dónde va el puente con la batidora
## de Nicole y Sofía. Va en el recorrido porque es geometría (entre Coco y la batidora no pasa el río).
##   {"angulo": 7.854, "tunel_px": 66, "palanca_offset": [0, 92]}   (espiral; `angulo` en RADIANES)
##   {"fraccion": 0.61, ...}                                         (cualquier recorrido)
## Sin el campo, `tiene_puente()` es false y el motor no dibuja puente, batidora ni túnel.

const PASO_MUESTREO := 3.0

var puntos := PackedVector2Array()
var acumulado := PackedFloat32Array()
var largo := 0.0
var fin := Vector2.ZERO
var centro := Vector2(640, 372)

# Puente de la batidora (vacío si el recorrido no lo trae)
var s_puente := -1.0
var tunel_px := 66.0
var palanca_offset := Vector2(0, 92)
var _indice_puente := -1


static func desde_archivo(ruta: String) -> RecorridoRio:
	var recorrido := RecorridoRio.new()
	if not FileAccess.file_exists(ruta):
		push_error("RecorridoRio: no existe %s" % ruta)
		recorrido._construir_espiral({})
		return recorrido
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	recorrido.construir(datos if datos is Dictionary else {})
	return recorrido


func construir(datos: Dictionary) -> void:
	_indice_puente = -1
	var puente: Variant = datos.get("puente_batidora", null)
	var angulo_puente := INF
	if puente is Dictionary and puente.has("angulo"):
		angulo_puente = float(puente["angulo"])
	match str(datos.get("tipo", "espiral")):
		"puntos":
			_construir_puntos(datos)
		_:
			_construir_espiral(datos, angulo_puente)
	_acumular()
	s_puente = -1.0
	if puente is Dictionary:
		tunel_px = float(puente.get("tunel_px", 66.0))
		palanca_offset = _vec(puente.get("palanca_offset", [0, 92]))
		if _indice_puente >= 0:
			s_puente = acumulado[_indice_puente]
		elif puente.has("fraccion"):
			s_puente = largo * clampf(float(puente["fraccion"]), 0.0, 1.0)


## ¿Este recorrido trae el puente de la batidora?
func tiene_puente() -> bool:
	return s_puente >= 0.0


## Centro de la batidora (sobre el puente).
func posicion_batidora() -> Vector2:
	return posicion(s_puente)


func posicion_palanca() -> Vector2:
	return posicion_batidora() + palanca_offset


func _construir_espiral(datos: Dictionary, angulo_puente := INF) -> void:
	centro = _vec(datos.get("centro", [640, 372]))
	var entrada := _vec(datos.get("entrada", [160, 800]))
	var r0 := float(datos.get("radio_inicio", 300))
	var r1 := float(datos.get("radio_fin", 150))
	var t0 := float(datos.get("angulo_inicio", 1.0)) * PI
	var t1 := float(datos.get("angulo_fin", 4.0)) * PI
	var escala := _vec(datos.get("escala", [1.6, 0.95]))
	puntos = PackedVector2Array()
	# Primer punto de la espiral, para que la entrada recta llegue justo a él.
	var inicio_espiral := centro + Vector2(r0 * escala.x * cos(t0), r0 * escala.y * sin(t0))
	var y := entrada.y
	while y > inicio_espiral.y:
		puntos.append(Vector2(inicio_espiral.x, y))
		y -= PASO_MUESTREO
	var th := t0
	var mejor := INF
	while th <= t1:
		var r := r0 - (r0 - r1) * (th - t0) / (t1 - t0)
		puntos.append(centro + Vector2(r * escala.x * cos(th), r * escala.y * sin(th)))
		if absf(th - angulo_puente) < mejor:
			mejor = absf(th - angulo_puente)
			_indice_puente = puntos.size() - 1
		th += 0.002


func _construir_puntos(datos: Dictionary) -> void:
	var curva := Curve2D.new()
	var crudos: Array = datos.get("puntos", [])
	var suavizado := float(datos.get("suavizado", 0.35))
	centro = _vec(datos.get("centro", [640, 372]))
	for i in crudos.size():
		var p := _vec(crudos[i])
		var anterior := _vec(crudos[max(i - 1, 0)])
		var siguiente := _vec(crudos[min(i + 1, crudos.size() - 1)])
		var manija := (siguiente - anterior) * suavizado * 0.5
		curva.add_point(p, -manija, manija)
	curva.bake_interval = PASO_MUESTREO
	puntos = curva.get_baked_points()


func _acumular() -> void:
	acumulado = PackedFloat32Array()
	acumulado.resize(puntos.size())
	var total := 0.0
	for i in puntos.size():
		if i > 0:
			total += puntos[i].distance_to(puntos[i - 1])
		acumulado[i] = total
	largo = total
	fin = puntos[puntos.size() - 1] if puntos.size() > 0 else centro


func _indice(s: float) -> int:
	var lo := 0
	var hi := acumulado.size() - 1
	while lo < hi:
		var m := (lo + hi + 1) >> 1
		if acumulado[m] <= s:
			lo = m
		else:
			hi = m - 1
	return lo


## Posición en pantalla de la distancia `s` del recorrido.
func posicion(s: float) -> Vector2:
	if puntos.is_empty():
		return centro
	if s <= 0.0:
		# Antes del recorrido: se sigue la dirección del primer tramo hacia atrás (fuera de pantalla).
		var dir := (puntos[1] - puntos[0]).normalized() if puntos.size() > 1 else Vector2.UP
		return puntos[0] + dir * s
	if s >= largo:
		return fin
	var i := _indice(s)
	var j := mini(i + 1, acumulado.size() - 1)
	var k := (s - acumulado[i]) / (acumulado[j] - acumulado[i]) if acumulado[j] > acumulado[i] else 0.0
	return puntos[i].lerp(puntos[j], k)


func tangente(s: float) -> Vector2:
	var a := posicion(s - 2.0)
	var b := posicion(s + 2.0)
	var d := b - a
	return d.normalized() if d.length() > 0.0 else Vector2.RIGHT


static func _vec(valor) -> Vector2:
	if valor is Array and valor.size() >= 2:
		return Vector2(float(valor[0]), float(valor[1]))
	return Vector2.ZERO
