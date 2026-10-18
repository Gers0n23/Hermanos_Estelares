extends RefCounted

## Pares favoritos del motor "emparejar" (pedido del PO, 17-Oct-2026): de vez en cuando, uno de los
## pares del tablero se cambia por una imagen de algo que le encanta al hermano que juega (KATSEYE,
## las guerreras K-pop, Disney, Harry Potter y Sanrio para Nicole y Sofia; Sonic, Tayo, Backrooms,
## Roblox, Verity y Spider-Man para Maxi). Las imagenes y a quien le tocan viven en
## `datos/favoritos/catalogo.json` (lo arma `herramientas/descargar_favoritos.py`).
##
## Solo en modos de cartas identicas: en sombras, correspondencias o recetas, un par de fotos iguales
## romperia la regla del tablero. Tampoco pisa pares especiales, fijos ni con voz (ver `mezclar`). El nivel (o la ronda) puede ajustar o apagar la sorpresa con
## `"favoritos": {"probabilidad": 0.5, "maximo": 1}` o `"favoritos": false`.

const RUTA_CATALOGO := "res://datos/favoritos/catalogo.json"
const MODOS := ["identico", "trios"]
const PROBABILIDAD := 0.5
## Imagenes recien vistas que no se repiten enseguida (entre tableros de la misma sesion).
const MEMORIA_RECIENTES := 24

## Los arneses QA que buscan pares concretos lo apagan para seguir siendo deterministas.
static var desactivado := false
static var _catalogo: Dictionary = {}
static var _recientes: Array[String] = []


## Imagenes disponibles para estos hermanos: [{archivo, tema, personaje}], sin duplicados.
static func imagenes_para(hermanos: Array) -> Array:
	if _catalogo.is_empty():
		var texto := FileAccess.get_file_as_string(RUTA_CATALOGO)
		var leido: Variant = JSON.parse_string(texto) if texto != "" else null
		_catalogo = leido if leido is Dictionary else {"temas": {}}
	var salida: Array = []
	for tema: String in _catalogo.get("temas", {}):
		var entrada: Dictionary = _catalogo["temas"][tema]
		var le_toca := false
		for hermano in hermanos:
			le_toca = le_toca or str(hermano) in entrada.get("hermanos", [])
		if not le_toca:
			continue
		for imagen: Dictionary in entrada.get("imagenes", []):
			if ResourceLoader.exists("res://assets/" + str(imagen.get("archivo", ""))):
				salida.append({"archivo": imagen["archivo"], "tema": tema, "personaje": imagen.get("personaje", "")})
	return salida


## Devuelve `grupos` con hasta `maximo` grupos cambiados al azar por pares favoritos (misma cantidad
## de cartas por grupo, asi no cambian el tablero ni la barra de progreso).
static func mezclar(grupos: Array, conf: Dictionary, hermanos: Array) -> Array:
	var ajuste: Variant = conf.get("favoritos", {})
	if desactivado or (ajuste is bool and not ajuste):
		return grupos
	var opciones: Dictionary = ajuste if ajuste is Dictionary else {}
	if not opciones.has("probabilidad") and str(conf.get("modo", "identico")) not in MODOS:
		return grupos
	if randf() >= float(opciones.get("probabilidad", PROBABILIDAD)):
		return grupos
	var candidatos: Array = []
	# Nunca reemplaza el par especial, uno `fijo` (la bandera de Chile siempre esta) ni uno que dice su
	# nombre por voz (paises, contenido educativo): la sorpresa se suma al juego, no le quita lo que ensena.
	for i in grupos.size():
		var grupo: Dictionary = grupos[i]
		if not bool(grupo.get("especial", false)) and not bool(grupo.get("fijo", false)) and str(grupo.get("voz", "")) == "":
			candidatos.append(i)
	var imagenes := imagenes_para(hermanos)
	if candidatos.is_empty() or imagenes.is_empty():
		return grupos
	var frescas := imagenes.filter(func(imagen: Dictionary) -> bool: return imagen["archivo"] not in _recientes)
	if frescas.is_empty():
		_recientes.clear()
		frescas = imagenes
	frescas.shuffle()
	candidatos.shuffle()
	var maximo := int(opciones.get("maximo", 2 if grupos.size() >= 8 else 1))
	var salida := grupos.duplicate()
	for n in mini(maximo, mini(candidatos.size(), frescas.size())):
		var indice: int = candidatos[n]
		var imagen: Dictionary = frescas[n]
		var elementos: Array = []
		for j in maxi(2, grupos[indice].get("elementos", []).size()):
			elementos.append({"id": "%s_%d" % [imagen["archivo"].get_file().get_basename(), j],
				"sprite": imagen["archivo"], "favorito": true})
		salida[indice] = {"id_grupo": "favorito_" + imagen["archivo"].get_file().get_basename(),
			"especial": false, "favorito": true, "voz": "", "elementos": elementos}
		_recientes.append(imagen["archivo"])
	while _recientes.size() > MEMORIA_RECIENTES:
		_recientes.pop_front()
	return salida
