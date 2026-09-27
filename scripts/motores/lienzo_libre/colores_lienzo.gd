extends RefCounted

## Colores del motor `lienzo_libre`: la paleta con nombre (los ids que usan los JSON de nivel y las
## voces de Coco) y la mezcla de pinturas de "Mezcla en la paleta" (Sofia, zona 3).
##
## La mezcla sigue el modelo de pintura RYB (rojo, amarillo, azul), que es el que ensena el colegio:
## azul + amarillo = verde. Se interpola dentro del cubo RYB (Gossett y Chen, 2004) con los colores
## de la paleta en las esquinas, y el blanco aclara. Las esquinas se ajustaron para que la mezcla
## de los tres primarios de CAFE (no negro), que es lo que un nino espera ver.

const COLORES := {
	"rojo": Color("#EE4035"),
	"naranja": Color("#FF9A2E"),
	"amarillo": Color("#FFD23F"),
	"verde": Color("#4CBF56"),
	"azul": Color("#3470D8"),
	"violeta": Color("#9357D6"),
	"rosa": Color("#FF7EB6"),
	"turquesa": Color("#2EC4B6"),
	"blanco": Color("#FFFFFF"),
	"negro": Color("#2B2E3F"),
	"cafe": Color("#9A6238"),
	"celeste": Color("#8ED3FF"),
	# Colores que solo salen de mezclar (Sofia) o que nombra Coco.
	"rosado": Color("#F79AB6"),
	"lila": Color("#C7A6EC"),
	"gris": Color("#9AA0B0"),
	"verde_claro": Color("#A6E3A1"),
	"amarillo_claro": Color("#FFEBA0"),
}

## Esquinas del cubo RYB: [rojo, amarillo, azul] -> color.
const _CUBO := {
	Vector3i(0, 0, 0): Color("#FFFFFF"),
	Vector3i(1, 0, 0): Color("#EE4035"),
	Vector3i(0, 1, 0): Color("#FFD23F"),
	Vector3i(0, 0, 1): Color("#3470D8"),
	Vector3i(1, 1, 0): Color("#FF8A26"),
	Vector3i(1, 0, 1): Color("#8A48C8"),
	Vector3i(0, 1, 1): Color("#3DAE4F"),
	Vector3i(1, 1, 1): Color("#7A4A2A"),
}


static func color(id: String) -> Color:
	if COLORES.has(id):
		return COLORES[id]
	if id.begins_with("#"):
		return Color(id)
	return Color.WHITE


## Id de la paleta mas parecido a `c` (para saber que color uso el nino y que reaccion de Coco
## corresponde). Compara en espacio perceptual aproximado (con peso en la luminosidad).
static func mas_cercano(c: Color, candidatos: Array = []) -> String:
	var lista: Array = candidatos if not candidatos.is_empty() else COLORES.keys()
	var mejor := ""
	var mejor_d := INF
	for id in lista:
		var otro := color(str(id))
		var d := Vector3(c.r - otro.r, c.g - otro.g, c.b - otro.b).length_squared() + pow(c.get_luminance() - otro.get_luminance(), 2) * 2.0
		if d < mejor_d:
			mejor_d = d
			mejor = str(id)
	return mejor


## Color de una mezcla con `gotas` = {"rojo": n, "amarillo": n, "azul": n, "blanco": n}.
static func mezclar(gotas: Dictionary) -> Color:
	var r := float(gotas.get("rojo", 0))
	var y := float(gotas.get("amarillo", 0))
	var b := float(gotas.get("azul", 0))
	var w := float(gotas.get("blanco", 0))
	var mayor := maxf(r, maxf(y, b))
	if mayor <= 0.0:
		return Color.WHITE
	var resultado := _cubo(r / mayor, y / mayor, b / mayor)
	var blancura := w / (r + y + b + w)
	return resultado.lerp(Color.WHITE, blancura * 0.9)


static func _cubo(r: float, y: float, b: float) -> Color:
	var total := Color(0, 0, 0, 0)
	for esquina: Vector3i in _CUBO:
		var peso := (r if esquina.x == 1 else 1.0 - r) * (y if esquina.y == 1 else 1.0 - y) * (b if esquina.z == 1 else 1.0 - b)
		var c: Color = _CUBO[esquina]
		total += Color(c.r * peso, c.g * peso, c.b * peso, peso)
	return Color(total.r, total.g, total.b, 1.0)


## Nombre de la mezcla (para que Coco la celebre): "verde", "naranja", "violeta", "cafe",
## "rosado", "celeste", "lila", "verde_claro"... o el primario/blanco si no hay mezcla.
static func nombre_mezcla(gotas: Dictionary) -> String:
	var r := int(gotas.get("rojo", 0))
	var y := int(gotas.get("amarillo", 0))
	var b := int(gotas.get("azul", 0))
	var w := int(gotas.get("blanco", 0))
	var p := r + y + b
	if p == 0:
		return "blanco" if w > 0 else ""
	var claro := w * 3 >= p  # al menos 1 de blanco por cada 3 de color
	var presentes := []
	for par in [["rojo", r], ["amarillo", y], ["azul", b]]:
		if par[1] * 4 >= p:  # un color "cuenta" si es al menos un cuarto de la pintura
			presentes.append(par[0])
	var base := ""
	match presentes.size():
		3:
			base = "cafe"
		2:
			if presentes.has("rojo") and presentes.has("amarillo"):
				base = "naranja"
			elif presentes.has("amarillo") and presentes.has("azul"):
				base = "verde"
			else:
				base = "violeta"
		_:
			base = presentes[0] if not presentes.is_empty() else "cafe"
	if not claro:
		return base
	match base:
		"rojo":
			return "rosado"
		"azul":
			return "celeste"
		"violeta":
			return "lila"
		"verde":
			return "verde_claro"
		"amarillo":
			return "amarillo_claro"
		"cafe":
			return "gris"
	return base
