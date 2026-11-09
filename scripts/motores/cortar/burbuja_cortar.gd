class_name BurbujaCortar
extends Node2D

## Una burbuja de coleccion del motor `cortar` (§5.3-§5.4). Sigue una parabola CALCULADA (LogicaCortar.posicion,
## sin fisica): su posicion es funcion del tiempo `t` que avanza el motor. Tipos: "animal" (con un animal del pool
## adentro), "calcetin" (la bomba de Fruit Ninja), "siesta" (Freeze) y "trompeta" (Frenzy). Estados:
## vuelo -> reventada | escapando | cayendo -> fin. La de Maxi (`flota`) sube y se queda en el apice.

var tipo := "animal"
var id_animal := ""
var radio := 70.0
var hitbox_extra := 15.0
var hitbox_menos := 8.0
var trayectoria: Dictionary = {}
var flota := false
var soplido := 0
var t := 0.0
var estado := "vuelo"
var bamboleo_px := 6.0
var bamboleo_hz := 2.0
var lenta := false            # presentacion del calcetin: sale sola y despacio
var _fase_bamboleo := 0.0
var _t_vida := 0.0


func preparar(fase_bamboleo: float) -> void:
	_fase_bamboleo = fase_bamboleo
	position = posicion_en(0.0)


## Posicion del centro en el tiempo `tiempo` (con bamboleo, ±6 px en x a 2 Hz; el calcetin, mas lento).
func posicion_en(tiempo: float) -> Vector2:
	var base := LogicaCortar.posicion_flotante(trayectoria, tiempo) if flota else LogicaCortar.posicion(trayectoria, tiempo)
	var hz := bamboleo_hz * (0.55 if tipo == "calcetin" else 1.0)
	return base + Vector2(sin((tiempo + _fase_bamboleo) * TAU * hz) * bamboleo_px, 0.0)


func duracion() -> float:
	return float(trayectoria.get("T", 1.0))


## Avanza el vuelo. Devuelve true el cuadro en que la burbuja vuelve al pasto (nunca si flota).
func avanzar(dt: float) -> bool:
	_t_vida += dt
	if estado != "vuelo":
		queue_redraw()
		return false
	t += dt
	position = posicion_en(t)
	queue_redraw()
	return not flota and t >= duracion()


## Hitbox (§5.3): Brote radio + 15, Estrella radio + 10; el calcetin radio - 8 (mas chica que el dibujo).
func radio_hitbox() -> float:
	return LogicaCortar.radio_hitbox(tipo, radio, hitbox_extra, hitbox_menos)


func activa() -> bool:
	return estado == "vuelo"


func _draw() -> void:
	if estado == "fin":
		return
	var r := radio
	var dentro := r * 0.62
	match tipo:
		"calcetin":
			DibujoCortar.dibujar_calcetin(self, Vector2.ZERO, dentro, sin(_t_vida * 2.0) * 0.25)
			DibujoCortar.dibujar_burbuja(self, Vector2.ZERO, r, true)
		"siesta":
			DibujoCortar.dibujar_almohada(self, Vector2.ZERO, dentro)
			DibujoCortar.dibujar_burbuja(self, Vector2.ZERO, r)
		"trompeta":
			DibujoCortar.dibujar_trompeta(self, Vector2.ZERO, dentro)
			DibujoCortar.dibujar_burbuja(self, Vector2.ZERO, r)
		_:
			# El animal entero y sonriente; en Semilla, mas grande todavia (§5.3).
			DibujoCortar.dibujar_animal(self, id_animal, Vector2(0, sin(_t_vida * 5.0) * 2.0), r * (0.66 if flota else 0.58))
			DibujoCortar.dibujar_burbuja(self, Vector2.ZERO, r)
