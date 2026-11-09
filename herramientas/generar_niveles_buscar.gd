extends SceneTree

## Generador OFFLINE de los niveles del «Escondite animal» (motor buscar, HE-118).
##
## Escribe `datos/niveles/animalia/<zona>/buscar_<perfil>.json` (5 zonas x 3 perfiles), el nivel de equipo
## `datos/niveles/animalia/zona1_campamento/buscar_equipo.json` y las lineas de voz
## `assets/audio/voces/animalia/buscar/lineas_tts.tsv`.
##
## Por que un generador (decision de dev-godot, 05-Nov-2026, PO delego): la ficha pide escondites hechos a
## mano (§2 regla 5: nada procedural EN EL JUEGO). Aqui se compone cada escena con piezas reutilizables y
## semilla FIJA, y para cada animal se buscan 2-3 escondites concretos donde la parte visible MEDIDA (con
## `GeometriaBuscar`, la misma que dibuja y toca) cae entre el minimo del perfil y un poco mas. El resultado
## es un JSON fijo, versionado y editable a mano por disenador-niveles; el juego solo sortea entre lo
## declarado. Volver a correrlo da los mismos archivos.
##
## Valores por zona y perfil: docs/fichas/planeta-animalia-zonas.md §4.3 y docs/fichas/motor-buscar.md §8.1,
## con la politica de derrota HE-124 (sol 3 / 2,2 / 1,6 x par; regalo 2 / 2 / 3; ayuda fuerte de Semilla;
## descanso 3 / 4).
##
## Uso: godot --headless --path . --script herramientas/generar_niveles_buscar.gd

const G := preload("res://scripts/motores/buscar/geometria_buscar.gd")
const RAIZ := "res://datos/niveles/animalia/"
const TSV := "res://assets/audio/voces/animalia/buscar/lineas_tts.tsv"
const ZONAS := ["zona1_campamento", "zona2_laguna", "zona3_pradera", "zona4_nidos", "zona5_valle"]
const PERFILES := ["semilla", "brote", "estrella"]

# --- Parametros por perfil y zona (indice 0-4) ---
const P := {
	"semilla": {
		"ancho": [1280, 1280, 1280, 1280, 1280], "alto": [720, 720, 720, 720, 720],
		"objetivos": [5, 5, 6, 6, 7], "visible": [0.80, 0.80, 0.75, 0.75, 0.70],
		"tamano": [200, 190, 180, 170, 160], "objetos": [8, 9, 10, 10, 11], "abribles": [0, 0, 0, 0, 0],
		"dos_pasos": [0, 0, 0, 0, 0], "senuelos": [0, 0, 0, 0, 0], "camuflaje": [false, false, false, false, false],
		"par": [35, 37, 40, 42, 45], "lupa": [false, false, false, false, false],
	},
	"brote": {
		"ancho": [1920, 1920, 2560, 2560, 2560], "alto": [720, 720, 720, 720, 720],
		"objetivos": [5, 5, 6, 7, 7], "visible": [0.60, 0.55, 0.50, 0.45, 0.40],
		"tamano": [120, 115, 110, 100, 96], "objetos": [12, 12, 14, 15, 16], "abribles": [0, 0, 1, 1, 2],
		"dos_pasos": [0, 0, 0, 0, 0], "senuelos": [0, 0, 0, 1, 1], "camuflaje": [false, false, false, false, false],
		"par": [80, 100, 130, 150, 160], "lupa": [false, false, false, false, false],
	},
	"estrella": {
		"ancho": [2560, 2560, 3200, 3200, 3840], "alto": [720, 720, 720, 720, 1080],
		"objetivos": [8, 9, 10, 11, 12], "visible": [0.40, 0.35, 0.30, 0.25, 0.20],
		"tamano": [90, 84, 76, 70, 64], "objetos": [14, 15, 18, 20, 24], "abribles": [1, 2, 3, 4, 4],
		"dos_pasos": [0, 0, 0, 2, 2], "senuelos": [0, 1, 2, 3, 4], "camuflaje": [false, true, true, true, true],
		"par": [150, 170, 200, 230, 270], "lupa": [false, false, true, true, true],
	},
}

## Listas de objetivos (pool) por zona y perfil (planeta-animalia-zonas.md §4.3). Lo de mas = extra del pool.
const LISTAS := {
	"semilla": [
		["perrito", "gatito", "vaca", "pato", "pollito", "caballo"],
		["patito", "hipopotamo", "tortuga", "pez", "lobo_marino", "perrito_bombero"],
		["elefante", "cebra", "jirafa", "caballo", "oveja", "triceratops"],
		["mono", "tucan", "perezoso", "buho", "loro", "braquiosaurio"],
		["trex", "spinosaurio", "carnotauro", "triceratops", "braquiosaurio", "mama_trex", "huevito"],
	],
	"brote": [
		["gatito", "pony", "perrito", "caballo", "pato", "pollito"],
		["patito", "flamenco", "gatito", "pony", "cisne", "hipopotamo"],
		["jirafa", "jirafita", "cebra", "caballo", "pony", "elefante", "oveja"],
		["mono", "loro", "buho", "gatito", "perezoso", "pony", "tucan", "koala"],
		["pony_estelar", "jirafa", "pony", "caballo", "gatito", "perrito", "mono"],
	],
	"estrella": [
		["hermanito_toby", "gatito", "gerbo", "pony", "cuy", "conejo", "pollito", "cabrita"],
		["pinguino", "lobo_marino", "cisne", "flamenco", "huillin", "coipo", "pato", "garza", "tortuga", "gerbo"],
		["huemul", "pudu", "guanaco", "alpaca", "nandu", "cebra", "jirafa", "caballo", "pony", "vizcacha", "gerbo"],
		["condor", "buho", "tucan", "mono", "perezoso", "tricahue", "carpintero", "monito_del_monte", "chucao", "koala", "ardilla", "gerbo"],
		["pinguino", "monito_del_monte", "huemul", "condor", "pudu", "milodon", "ballena", "flamenco", "hermanito_toby", "alpaca", "gerbo", "pony"],
	],
}
const FIJOS := {"estrella": [["hermanito_toby"], [], [], [], []]}
const SENUELOS := {
	"brote": [[], [], [], ["burrito"], ["cebra"]],
	"estrella": [[], ["ganso"], ["llama", "caballo_pijama"], ["lechuza", "choroy", "koala_peluche"], ["llama", "ganso", "lechuza", "koala_peluche"]],
}
const SECRETOS := {
	"semilla": [["huevito"], ["huevito"], ["huevito"], ["huevito"], []],
	"brote": [["huevito"], ["huevito"], ["huevito"], ["huevito"], ["huevito"]],
	"estrella": [["huevito"], ["huevito"], ["huevito"], ["huevito"], ["huevito", "pony_estelar"]],
}

## Piezas por zona: tipos del suelo (se reparten), del agua y del cielo. Las abribles van primero.
const PIEZAS := {
	"zona1_campamento": {"suelo": ["carpa", "arbusto", "fardo", "gallinero", "carretilla", "arbusto", "cerca", "balde", "arbol", "regadera", "roca", "helecho", "hongo", "tronco", "arbusto", "roca", "cesto", "arbol", "helecho", "arbusto", "fardo", "hongo"],
		"abribles": ["carpa", "fardo", "cesto", "carpa"], "cielo": ["nube"], "agua": []},
	"zona2_laguna": {"suelo": ["roca", "arbusto", "manguera", "helecho", "arbol", "roca", "arbusto", "tronco", "hongo", "roca", "helecho", "arbusto", "arbol", "roca", "arbusto", "helecho"],
		"abribles": ["tronco_hueco", "flor_gigante", "cesto", "tronco_hueco"], "cielo": ["nube"], "agua": ["nenufar", "bote", "juncos", "nenufar", "juncos", "nenufar"]},
	"zona3_pradera": {"suelo": ["acacia", "pasto_alto", "arbusto", "roca", "camion", "pasto_alto", "acacia", "tronco", "arbusto", "roca", "pasto_alto", "cerca", "hongo", "acacia", "arbusto", "roca", "pasto_alto", "arbusto", "roca", "pasto_alto"],
		"abribles": ["fardo", "flor_gigante", "fardo", "tronco_hueco"], "cielo": ["nube"], "agua": []},
	"zona4_nidos": {"suelo": ["arbol", "helecho", "arbol", "hongo", "arbusto", "arbol", "roca", "helecho", "arbol", "hongo", "arbusto", "arbol", "helecho", "roca", "arbol", "arbusto", "helecho", "hongo", "arbol", "roca"],
		"abribles": ["tronco_hueco", "flor_gigante", "cesto", "tronco_hueco"], "cielo": ["nube"], "agua": []},
	"zona5_valle": {"suelo": ["volcan", "roca", "huesos", "helecho", "arbol", "roca", "cristales", "helecho", "huesos", "arbol", "roca", "helecho", "arbusto", "roca", "arbol", "cristales", "helecho", "roca", "arbusto", "huesos", "arbol", "roca", "helecho"],
		"abribles": ["cueva", "flor_gigante", "cueva", "flor_gigante"], "cielo": ["nube"], "agua": ["juncos", "nenufar", "juncos"]},
}

const FONDOS := {
	"zona1_campamento": {"cielo": ["#8FD3F4", "#E6F7FF"], "lejos": [{"y": 330, "color": "#B5E3A1", "amp": 50, "ondas": 2.5}, {"y": 360, "color": "#9ED68A", "amp": 30, "ondas": 4, "fase": 1.0}],
		"suelo": {"y": 380, "color": "#8CCB6A"}},
	"zona2_laguna": {"cielo": ["#8ED1F7", "#E8F8FF"], "lejos": [{"y": 320, "color": "#A9DDB0", "amp": 40, "ondas": 3}], "suelo": {"y": 370, "color": "#86C870"}},
	"zona3_pradera": {"cielo": ["#9FD8F2", "#FFF4D6"], "lejos": [{"y": 330, "color": "#E3D58A", "amp": 30, "ondas": 2}, {"y": 360, "color": "#D2C76C", "amp": 20, "ondas": 5}],
		"suelo": {"y": 380, "color": "#C9D46A", "color2": "#AEBB52"}},
	"zona4_nidos": {"cielo": ["#86CDE8", "#D9F2E4"], "lejos": [{"y": 300, "color": "#6FB77A", "amp": 60, "ondas": 4}, {"y": 340, "color": "#5DA86A", "amp": 40, "ondas": 6, "fase": 2.0}],
		"suelo": {"y": 380, "color": "#6DB65E"}},
	"zona5_valle": {"cielo": ["#F6C7A8", "#FFF0D9"], "lejos": [{"y": 320, "color": "#C9A98F", "amp": 70, "ondas": 2}, {"y": 360, "color": "#B79A82", "amp": 30, "ondas": 5}],
		"suelo": {"y": 390, "color": "#A7C26A"}, "niebla": true},
}

## Catalogo de animales (~70): aspecto (formas genericas de GeometriaBuscar), habitat, tamano relativo,
## palabra (Nicole), tono del sonido provisional y pistas de Sofia (descriptiva, dos rasgos, indirecta).
var CAT := {}


func _cat() -> void:
	var a := func(id: String, palabra: String, asp: Dictionary, hab: Array, rel := 1.0, tono := 1.0, pistas := ["", "", ""], extra := {}) -> void:
		var d := {"palabra": palabra, "aspecto": asp, "habitat": hab, "rel": rel, "tono": tono, "pistas": pistas}
		d.merge(extra)
		CAT[id] = d
	# Granja y mascotas
	a.call("perrito", "PERRITO", {"forma": "sentado", "color": "#D9A066", "color2": "#FFF1DC", "orejas": "caidas", "cola": "larga"}, ["suelo"], 1.0, 1.1,
		["Un perrito de orejas caídas", "Orejas caídas, cola que se mueve y ladra", "Mueve la cola cuando está feliz"])
	a.call("gatito", "GATITO", {"forma": "sentado", "color": "#F4A259", "color2": "#FFE8CC", "orejas": "punta", "cola": "larga", "patron": "panza"}, ["suelo", "arbol"], 1.0, 1.5,
		["Un gatito naranjo con bigotes", "Orejas en punta, bigotes y dice miau", "Ronronea cuando lo acarician"])
	a.call("vaca", "VACA", {"forma": "cuadrupedo", "color": "#FFFFFF", "color2": "#FFC2D1", "orejas": "caballo", "cuernos": "chicos", "patron": "manchas", "color_patron": "#3B3F55", "hocico": "chato"}, ["suelo"], 1.2, 0.6,
		["La de manchas negras que da leche", "Manchas negras, cuernitos y dice muu", "Nos da la leche del desayuno"])
	a.call("pato", "PATO", {"forma": "nadador", "color": "#FFFFFF", "color3": "#FF9F1C", "pico": "pato", "cuello": 0.2}, ["agua", "suelo"], 0.9, 1.3,
		["Un pato blanco de pico naranjo", "Pico naranjo, plumas blancas y dice cuac", "Nada y dice cuac cuac"])
	a.call("patito", "PATITO", {"forma": "nadador", "color": "#FFE066", "color3": "#FF9F1C", "pico": "pato", "cuello": 0.1}, ["agua", "suelo"], 0.85, 1.6,
		["Un patito amarillo", "Amarillo, chiquito y nada", "Sigue a su mamá en fila"])
	a.call("pollito", "POLLITO", {"forma": "ave", "color": "#FFE066", "color3": "#FF9F1C", "pico": "corto"}, ["suelo"], 0.8, 1.8,
		["Un pollito amarillo", "Amarillo, con pico y dice pío", "Salió de un huevo hace poquito"])
	a.call("caballo", "CABALLO", {"forma": "cuadrupedo", "color": "#A0663C", "color2": "#E8C9A8", "orejas": "caballo", "hocico": "largo", "cuello": 0.45, "crin": true, "alto_patas": 1.3}, ["suelo"], 1.3, 0.8,
		["El caballo café de crin oscura", "Crin larga, cascos y relincha", "Galopa y relincha"])
	a.call("pony", "PONY", {"forma": "cuadrupedo", "color": "#F7A8C8", "color2": "#FFE3EE", "orejas": "caballo", "hocico": "largo", "cuello": 0.35, "crin": true, "color_crin": "#B57EDC"}, ["suelo"], 1.1, 1.2,
		["El pony rosado", "Rosado, con crin morada y chiquito", "Tiene la crin más larga del valle"])
	a.call("cabrita", "CABRITA", {"forma": "cuadrupedo", "color": "#F2EDE4", "color2": "#FFFFFF", "orejas": "caidas", "cuernos": "chicos", "hocico": "normal"}, ["suelo"], 1.0, 1.4,
		["Una cabrita con cuernitos", "Cuernitos, barbita y dice beee", "Le encanta trepar a las rocas"])
	a.call("oveja", "OVEJA", {"forma": "sentado", "color": "#FFFFFF", "color2": "#3B3F55", "orejas": "redondas", "cola": "pompon", "patron": "manchas_claras"}, ["suelo"], 1.0, 1.0,
		["La de lana blanca", "Lana blanca, cara oscura y dice bee", "Su lana se usa para chalecos"])
	a.call("conejo", "CONEJO", {"forma": "sentado", "color": "#E6DCD3", "color2": "#FFC2D1", "orejas": "largas", "cola": "pompon"}, ["suelo"], 0.9, 1.7,
		["El de orejas muy largas", "Orejas largas, cola de pompón y salta", "Come zanahorias y salta"])
	a.call("gerbo", "GERBO", {"forma": "sentado", "color": "#E3B27A", "color2": "#FFF1DC", "orejas": "redondas", "cola": "larga"}, ["suelo"], 0.8, 2.0,
		["Un ratoncito dorado de cola larga", "Dorado, cola larga y orejas redondas", "Guarda semillas en sus cachetes"])
	a.call("cuy", "CUY", {"forma": "sentado", "color": "#C97B4A", "color2": "#FFFFFF", "orejas": "redondas", "patron": "manchas_claras"}, ["suelo"], 0.8, 1.9,
		["Un cuy café y blanco", "Sin cola, café y blanco, hace cui cui", "Hace cui cui cuando tiene hambre"])
	a.call("hermanito_toby", "HERMANITO", {"forma": "sentado", "color": "#C98B4E", "color2": "#FFF1DC", "orejas": "caidas", "cola": "larga", "patron": "panza"}, ["suelo"], 0.95, 1.3,
		["Tiene las orejas como Toby, pero no lleva casco", "Orejas como Toby y sin casco", "El que más se parece a Toby"])
	a.call("perrito_bombero", "BOMBERO", {"forma": "sentado", "color": "#FFFFFF", "color2": "#FFFFFF", "orejas": "caidas", "patron": "manchas", "color_patron": "#3B3F55", "accesorio": "casco_bombero", "cola": "larga"}, ["suelo", "agua"], 1.0, 1.2,
		["", "", ""])
	# Agua
	a.call("hipopotamo", "HIPOPÓTAMO", {"forma": "cuadrupedo", "color": "#A79BC8", "color2": "#E6C3D8", "orejas": "chicas", "hocico": "chato", "patas_gruesas": true, "alto_patas": 0.7, "largo": 1.15}, ["agua", "suelo"], 1.3, 0.5)
	a.call("tortuga", "TORTUGA", {"forma": "tortuga", "color": "#7CC47F", "color2": "#B9864C", "patron": "caparazon", "color_patron": "#8A5A32"}, ["suelo", "agua"], 0.9, 1.2,
		["La que lleva su casa en la espalda", "Caparazón, patitas cortas y lenta", "Vive muchísimos años"])
	a.call("pez", "PEZ", {"forma": "pez", "color": "#FF8A3D", "color3": "#FFD166", "patron": "rayas", "color_patron": "#FFFFFF"}, ["agua"], 0.9, 1.6)
	a.call("lobo_marino", "LOBO MARINO", {"forma": "foca", "color": "#8C7A6B", "color2": "#C9B49E"}, ["agua", "suelo"], 1.1, 0.7,
		["El que aplaude con sus aletas", "Aletas, bigotes y vive en la costa", "Duerme sobre las rocas del mar"])
	a.call("flamenco", "FLAMENCO", {"forma": "zancuda", "color": "#FF8FB8", "color3": "#3B3F55", "alto_patas": 1.2}, ["agua", "suelo"], 1.2, 1.5,
		["El pájaro rosado de patas largas", "Rosado, patas largas y se para en una", "Es rosado por lo que come"])
	a.call("cisne", "CISNE", {"forma": "nadador", "color": "#FFFFFF", "color3": "#E8434B", "pico": "pato", "cuello": 1.0}, ["agua"], 1.1, 1.3,
		["El cisne de cuello negro", "Cuello largo y negro, cuerpo blanco", "Lleva a sus pollitos en la espalda"], {"aspecto_extra": {}})
	CAT["cisne"]["aspecto"]["color3"] = "#E8434B"
	a.call("pinguino", "PINGÜINO", {"forma": "pinguino", "color": "#3B3F55", "color2": "#FFFFFF", "color3": "#FFB347", "patron": "panza"}, ["suelo", "agua"], 0.95, 1.1,
		["El pájaro que no vuela y nada", "No vuela, blanco y negro, y nada", "Le encanta el frío"])
	a.call("huillin", "HUILLÍN", {"forma": "foca", "color": "#7A5A3A", "color2": "#C9A27A", "orejas": "chicas"}, ["agua", "suelo"], 0.9, 1.4,
		["Una nutria café de Chile", "Café, bigotes y nada en los ríos", "Es la nutria de los ríos del sur"], {"camuflaje": true})
	a.call("coipo", "COIPO", {"forma": "sentado", "color": "#8A6A4A", "color2": "#E8434B", "orejas": "redondas", "cola": "larga"}, ["agua", "suelo"], 0.9, 1.2,
		["Un roedor de dientes naranjos", "Dientes naranjos, cola larga y nada", "Nada en las lagunas y tiene dientes naranjos"], {"camuflaje": true})
	a.call("garza", "GARZA", {"forma": "zancuda", "color": "#FFFFFF", "color3": "#FFB347", "alto_patas": 1.1}, ["agua", "suelo"], 1.15, 1.3,
		["Un pájaro blanco de patas largas", "Blanca, cuello largo y pesca", "Pesca parada en el agua"])
	a.call("ganso", "GANSO", {"forma": "nadador", "color": "#E6E6E6", "color3": "#FF9F1C", "pico": "pato", "cuello": 0.6}, ["agua", "suelo"], 1.0, 0.9,
		[], {"saludo": "¡Soy el ganso, no el cisne!"})
	# Pradera y altiplano
	a.call("elefante", "ELEFANTE", {"forma": "cuadrupedo", "color": "#9FA6BF", "color2": "#D9DCE8", "orejas": "elefante", "hocico": "trompa", "patas_gruesas": true, "largo": 1.1}, ["suelo"], 1.45, 0.45)
	a.call("cebra", "CEBRA", {"forma": "cuadrupedo", "color": "#FFFFFF", "color2": "#F2F2F2", "orejas": "caballo", "hocico": "largo", "cuello": 0.4, "crin": true, "color_crin": "#3B3F55", "patron": "rayas", "color_patron": "#3B3F55"}, ["suelo"], 1.25, 0.9,
		["El caballo de rayas", "Rayas blancas y negras y crin", "Sus rayas son únicas, como una huella"], {"saludo": "¡Yo soy la cebra, no el caballo!"})
	a.call("jirafa", "JIRAFA", {"forma": "cuadrupedo", "color": "#FFC857", "color2": "#FFE8A8", "orejas": "caballo", "cuernos": "jirafa", "cuello": 1.2, "patron": "manchas", "color_patron": "#C97B3A", "alto_patas": 1.3}, ["suelo"], 1.45, 1.0,
		["La del cuello más largo", "Cuello larguísimo y manchas", "Come las hojas más altas"])
	a.call("jirafita", "JIRAFITA", {"forma": "cuadrupedo", "color": "#FFD580", "color2": "#FFEFC2", "orejas": "caballo", "cuernos": "jirafa", "cuello": 0.9, "patron": "manchas", "color_patron": "#D9924A"}, ["suelo"], 1.05, 1.5)
	a.call("huemul", "HUEMUL", {"forma": "cuadrupedo", "color": "#9C7A55", "color2": "#E8D2B0", "orejas": "caballo", "cuernos": "ciervo", "cuello": 0.4, "hocico": "normal"}, ["suelo"], 1.25, 0.9,
		["Un ciervo café de Chile", "Ciervo con cuernos, café y de Chile", "Está en el escudo de Chile y tiene cuernos"], {"camuflaje": true})
	a.call("pudu", "PUDÚ", {"forma": "cuadrupedo", "color": "#A8714A", "color2": "#E8C9A8", "orejas": "redondas", "cuernos": "chicos", "cuello": 0.2}, ["suelo"], 0.95, 1.5,
		["Un ciervo chiquitito", "Ciervo chiquito, cuernitos cortos", "Uno de los ciervos más chiquitos del mundo"], {"camuflaje": true})
	a.call("guanaco", "GUANACO", {"forma": "cuadrupedo", "color": "#D99A5B", "color2": "#FFFFFF", "orejas": "caballo", "cuello": 0.75, "patron": "panza"}, ["suelo"], 1.25, 1.0,
		["El de cuello largo y panza blanca", "Cuello largo, panza blanca y escupe", "Corre libre por la cordillera"], {"camuflaje": true})
	a.call("alpaca", "ALPACA", {"forma": "cuadrupedo", "color": "#FFF1DC", "color2": "#FFFFFF", "orejas": "caballo", "cuello": 0.7, "patron": "manchas_claras"}, ["suelo"], 1.15, 1.2,
		["La de lana esponjosa y cuello largo", "Lana esponjosa, cuello largo y chiquita", "Su lana abriga en el altiplano"])
	a.call("llama", "LLAMA", {"forma": "cuadrupedo", "color": "#E6D3B8", "color2": "#FFFFFF", "orejas": "caballo", "cuello": 0.85, "alto_patas": 1.2}, ["suelo"], 1.25, 1.0,
		[], {"saludo": "¡Soy la llama, no la alpaca!"})
	a.call("nandu", "ÑANDÚ", {"forma": "zancuda", "color": "#B9A98F", "color3": "#8A7A5A", "alto_patas": 1.0}, ["suelo"], 1.2, 0.9,
		["Un pájaro grande que corre", "Grande, no vuela y corre muy rápido", "Corre rapidísimo por la pampa"], {"camuflaje": true})
	a.call("vizcacha", "VIZCACHA", {"forma": "sentado", "color": "#BDB3A6", "color2": "#E8E2D8", "orejas": "largas", "cola": "esponjosa"}, ["suelo"], 0.9, 1.6,
		["La de orejas largas que vive en las rocas", "Orejas largas, cola enrulada y en las rocas", "Toma sol sobre las piedras de la cordillera"], {"camuflaje": true})
	a.call("caballo_pijama", "CABALLO", {"forma": "cuadrupedo", "color": "#FFFFFF", "color2": "#FFFFFF", "orejas": "caballo", "hocico": "largo", "cuello": 0.4, "crin": true, "patron": "pijama", "color_patron": "#7FB2FF", "accesorio": "gorro_pijama"}, ["suelo"], 1.25, 0.8,
		[], {"saludo": "¡Es mi pijama, no soy cebra!"})
	a.call("burrito", "BURRITO", {"forma": "cuadrupedo", "color": "#9AA0B5", "color2": "#E6E6E6", "orejas": "largas", "hocico": "largo", "cuello": 0.3}, ["suelo"], 1.05, 0.8,
		[], {"saludo": "¡Yo soy el burrito, no el pony!"})
	# Selva alta
	a.call("mono", "MONO", {"forma": "sentado", "color": "#A0663C", "color2": "#F2D2B0", "orejas": "redondas", "cola": "larga", "patron": "panza"}, ["arbol", "suelo"], 1.0, 1.4,
		["Un monito café", "Cola larga, cara clarita y trepa", "Se cuelga de las ramas con la cola"])
	a.call("loro", "LORO", {"forma": "ave", "color": "#36B866", "color3": "#FFC83A", "pico": "curvo", "cola_larga": 1.0}, ["arbol", "aire"], 0.9, 1.7)
	a.call("tucan", "TUCÁN", {"forma": "ave", "color": "#3B3F55", "color2": "#FFFFFF", "color3": "#FF8A3D", "pico": "grande"}, ["arbol", "aire"], 0.95, 1.5,
		["El pájaro de pico gigante", "Pico gigante naranjo y plumas negras", "Su pico es casi tan largo como él"])
	a.call("buho", "BÚHO", {"forma": "ave", "color": "#A8835E", "color2": "#E8D2B0", "color3": "#FFB347", "pico": "corto", "orejas": "punta", "patron": "plumas"}, ["arbol", "aire"], 0.95, 0.8,
		["El pájaro de ojos grandes y orejitas", "Ojos grandes, orejitas y dice uh uh", "Está despierto de noche"])
	a.call("lechuza", "LECHUZA", {"forma": "ave", "color": "#F2E3C9", "color2": "#FFFFFF", "color3": "#FFB347", "pico": "corto", "patron": "plumas"}, ["arbol", "aire"], 0.95, 0.9,
		[], {"saludo": "¡Soy la lechuza, no el búho!"})
	a.call("perezoso", "PEREZOSO", {"forma": "sentado", "color": "#B9A07E", "color2": "#E8DCC8", "orejas": "ninguna", "patron": "panza"}, ["arbol"], 1.0, 0.7,
		["El más lento de la selva", "Lento, garras largas y duerme mucho", "Duerme colgado casi todo el día"])
	a.call("koala", "KOALA", {"forma": "sentado", "color": "#A9ADBB", "color2": "#E6E8EF", "orejas": "grandes", "patron": "panza"}, ["arbol"], 0.95, 0.9,
		["El gris de orejas peludas", "Gris, orejas peludas y abraza árboles", "Come hojas de eucalipto"])
	a.call("koala_peluche", "KOALA", {"forma": "sentado", "color": "#C3B7E0", "color2": "#F0EBFF", "orejas": "grandes", "accesorio": "costuras"}, ["arbol", "suelo"], 0.95, 1.6,
		[], {"saludo": "¡Soy de peluche!"})
	a.call("ardilla", "ARDILLA", {"forma": "sentado", "color": "#D9733B", "color2": "#FFE3C2", "orejas": "punta", "cola": "esponjosa"}, ["arbol", "suelo"], 0.85, 1.8,
		["La de cola esponjosa", "Cola esponjosa, naranja y junta nueces", "Guarda nueces para el invierno"])
	a.call("condor", "CÓNDOR", {"forma": "ave", "color": "#3B3F55", "color2": "#FFFFFF", "color3": "#E8B4A8", "pico": "curvo", "cola_larga": 0.6}, ["aire", "arbol"], 1.2, 0.6,
		["El pájaro negro de collar blanco", "Negro, collar blanco y alas enormes", "La otra del escudo: vuela altísimo"])
	a.call("tricahue", "TRICAHUE", {"forma": "ave", "color": "#7FA65A", "color2": "#FFD166", "color3": "#3B3F55", "pico": "curvo", "cola_larga": 0.8}, ["arbol", "aire"], 0.9, 1.6,
		["Un loro verde de Chile", "Loro verde con pecho amarillo y rojo", "El loro más grande de Chile"])
	a.call("choroy", "CHOROY", {"forma": "ave", "color": "#5DBB63", "color3": "#E8434B", "pico": "curvo", "cola_larga": 0.5}, ["arbol", "aire"], 0.85, 1.8,
		[], {"saludo": "¡Soy el choroy, no el tricahue!"})
	a.call("carpintero", "CARPINTERO", {"forma": "ave", "color": "#3B3F55", "color3": "#FFC83A", "pico": "largo", "cresta": true, "color2": "#E8434B"}, ["arbol"], 0.9, 1.3,
		["Un pájaro negro de cabeza roja", "Negro, cresta roja y golpea troncos", "Hace toc toc en los troncos"])
	CAT["carpintero"]["aspecto"]["color3"] = "#E8434B"
	a.call("monito_del_monte", "MONITO", {"forma": "sentado", "color": "#B79A82", "color2": "#F2E6D8", "orejas": "redondas", "cola": "larga"}, ["arbol"], 0.75, 2.0,
		["Un monito chiquito de ojos grandes", "Chiquito, ojos grandes y cola enrollada", "Duerme de día y es de Chile"], {"camuflaje": true})
	a.call("chucao", "CHUCAO", {"forma": "ave", "color": "#8A5A3A", "color2": "#E8743B", "color3": "#3B3F55", "pico": "corto", "patron": "panza"}, ["suelo", "arbol"], 0.8, 1.7,
		["Un pajarito café de pecho naranjo", "Pecho naranjo, cola paradita y canta fuerte", "Canta chu-cao en el bosque del sur"], {"camuflaje": true})
	# Dinos de Maxi y fantasia
	a.call("trex", "T-REX", {"forma": "dino_bipedo", "color": "#5DBB63", "color2": "#C8F0A8", "color3": "#FFC83A"}, ["suelo"], 1.25, 0.5)
	a.call("mama_trex", "MAMÁ", {"forma": "dino_bipedo", "color": "#3FA35F", "color2": "#B8E8A0", "color3": "#FF9EC7"}, ["suelo"], 1.4, 0.45)
	a.call("spinosaurio", "SPINO", {"forma": "dino_bipedo", "color": "#5AA9E6", "color2": "#C2E3FA", "color3": "#FF8A3D", "vela": true, "puas": false}, ["suelo", "agua"], 1.3, 0.6)
	a.call("carnotauro", "CARNO", {"forma": "dino_bipedo", "color": "#E8743B", "color2": "#FFD3B0", "color3": "#FFC83A", "cuernos": "carno"}, ["suelo"], 1.25, 0.55)
	a.call("triceratops", "TRICE", {"forma": "dino_cuernos", "color": "#B57EDC", "color2": "#E6CCF5", "cuernos": "tri", "patas_gruesas": true, "hocico": "normal"}, ["suelo"], 1.3, 0.6)
	a.call("braquiosaurio", "BRAQUIO", {"forma": "cuadrupedo", "color": "#7FC6E8", "color2": "#C8EAF8", "cuello": 1.6, "patas_gruesas": true, "largo": 1.1}, ["suelo"], 1.45, 0.4)
	a.call("huevito", "HUEVITO", {"forma": "huevo", "color": "#FFF1DC", "color3": "#7FC6E8"}, ["suelo", "arbol"], 0.7, 2.0)
	a.call("pony_estelar", "PONY ESTELAR", {"forma": "cuadrupedo", "color": "#D9C8FF", "color2": "#FFFFFF", "orejas": "caballo", "hocico": "largo", "cuello": 0.4, "crin": true, "color_crin": "#5A5FD8", "accesorio": "estrellas"}, ["suelo"], 1.15, 1.3)
	a.call("milodon", "MILODÓN", {"forma": "sentado", "color": "#8C6E52", "color2": "#C9B49E", "orejas": "chicas", "patron": "panza"}, ["suelo"], 1.3, 0.5,
		["Un perezoso gigante", "Gigante, peludo y de garras grandes", "Vivió hace miles de años en una cueva de la Patagonia"])
	a.call("ballena", "BALLENA", {"forma": "ballena", "color": "#5A7FC7", "color2": "#C8D8F5"}, ["agua"], 1.35, 0.4,
		["La más grande del mar", "Gigante, azul y echa agua por arriba", "El animal más grande que existe"])


# ---------------------------------------------------------------------------

var rng := RandomNumberGenerator.new()
var _tsv: Array[String] = []
var _fallas := 0
var _rechazos := {}


func _initialize() -> void:
	_cat()
	for zi in ZONAS.size():
		for perfil in PERFILES:
			_generar(zi, perfil)
	_generar_equipo()
	_escribir_tsv()
	print("=== generar_niveles_buscar: %s (%d fallas) ===" % ["OK" if _fallas == 0 else "CON FALLAS", _fallas])
	quit(0 if _fallas == 0 else 1)


func _v(perfil: String, clave: String, zi: int):
	return P[perfil][clave][zi]


func _generar(zi: int, perfil: String) -> void:
	var zona: String = ZONAS[zi]
	var W := float(_v(perfil, "ancho", zi))
	var H := float(_v(perfil, "alto", zi))
	var tam := float(_v(perfil, "tamano", zi))
	var visible := float(_v(perfil, "visible", zi))
	var pool: Array = LISTAS[perfil][zi]
	var n_obj := int(_v(perfil, "objetivos", zi))
	var senuelos: Array = SENUELOS.get(perfil, [[], [], [], [], []])[zi]
	var secretos: Array = SECRETOS[perfil][zi]
	var en_escena: Array = pool + senuelos + secretos
	var n_piezas := maxi(int(_v(perfil, "objetos", zi)), n_obj + senuelos.size() + secretos.size() + 3)
	_visible_actual = visible
	var objetos: Array = []
	var por_id := {}
	# Composicion con semilla fija; si algun animal queda con menos de 2 escondites se prueba la siguiente
	# semilla (siempre la misma secuencia: el resultado es reproducible).
	for intento in 40:
		rng.seed = hash("%s%s%d" % [zona, perfil, intento]) & 0x7fffffff
		_rechazos.clear()
		objetos = _componer(zona, perfil, zi, W, H, tam, n_piezas + intento / 3, int(_v(perfil, "abribles", zi)), int(_v(perfil, "dos_pasos", zi)))
		var aceptadas: Array = []
		var orden := en_escena.duplicate()
		orden.sort_custom(func(a, b) -> bool: return _opciones(a, objetos) < _opciones(b, objetos))
		por_id = {}
		var ok := true
		for id in orden:
			por_id[id] = _escondites_para(id, objetos, tam, visible, W, H, perfil, zi, aceptadas)
			if por_id[id].size() < 2:
				ok = false
		if ok and not _factible(perfil, objetos, por_id, pool, n_obj, FIJOS.get(perfil, [[], [], [], [], []])[zi], senuelos, secretos):
			ok = false
			print("  %s/%s intento %d: sorteo no factible, otra composicion" % [zona, perfil, intento])
		if ok:
			break
	var animales: Array = []
	for id in en_escena:
		var d: Dictionary = CAT[id]
		var animal := {"id": id, "nombre": d["palabra"].capitalize(), "palabra": d["palabra"], "aspecto": d["aspecto"],
			"sonido": "sfx/ui/blup.ogg", "tono": d["tono"], "nombre_voz": "voces/animalia/nombres/%s.wav" % id,
			"escondites": por_id[id]}
		if d.has("saludo"):
			animal["saludo"] = d["saludo"]
		if id == "huevito":
			# HE-120: el mapa muestra el huevo de Dinito en el nidito con esta clave (Progreso.especial_conocido).
			animal["marca_especial"] = "animalia_huevo_z%d" % (zi + 1)
		if perfil == "estrella" and id in pool:
			var nivel_pista := 0 if zi <= 1 else (1 if zi <= 3 else 2)
			var texto: String = d["pistas"][nivel_pista] if d["pistas"].size() > nivel_pista else ""
			if texto == "":
				texto = d["pistas"][0] if d["pistas"].size() > 0 else d["palabra"]
			var voz := "voces/animalia/buscar/estrella/z%d_pista_%s.wav" % [zi + 1, id]
			animal["pista"] = {"texto": texto, "voz": voz}
			_tsv.append("%s\t%s" % [voz, texto])
		animales.append(animal)
		if por_id[id].size() < 2:
			print("  rechazos: ", _rechazos)
			push_error("generar: %s/%s: %s solo tiene %d escondites" % [zona, perfil, id, por_id[id].size()])
			_fallas += 1
	var par := float(_v(perfil, "par", zi))
	var sol: Dictionary = {"semilla": {"factor_par": 3.0, "minimo_reintento_s": 60}, "brote": {"factor_par": 2.2, "minimo_reintento_s": 60},
		"estrella": {"factor_par": 1.6, "minimo_reintento_s": 45}}[perfil]
	var nivel := {
		"id_nivel": "animalia_z%d_buscar_%s" % [zi + 1, perfil],
		"motor": "buscar", "perfil": perfil, "planeta": "animalia", "zona": zona,
		"nota": "Generado por herramientas/generar_niveles_buscar.gd (HE-118, dev-godot 05-Nov-2026). Valores de partida de planeta-animalia-zonas.md §4.3 y politica de derrota HE-124 (motor-buscar.md §8.1 y §10). PROVISIONAL: calibrar con la maqueta HE-110 y el playtest. Los escondites son fijos: editables a mano; el arnes qa_test_buscar.gd mide que cada uno cumpla `visible_min`.",
		"escena": {"tamano": [W, H], "inicio_vista": [0, 0], "zona_util_max_y": H - 130.0, "fondo": _fondo(zona, W, H)},
		"objetos": objetos,
		"animales": animales,
		"objetivos": pool,
		"objetivos_por_partida": n_obj,
		"objetivos_fijos": FIJOS.get(perfil, [[], [], [], [], []])[zi],
		"senuelos": senuelos,
		"secretos": secretos,
		"modo_lista": {"semilla": "libre", "brote": "uno", "estrella": "tarjetas"}[perfil],
		"tarjetas_visibles": 3,
		"mostrar_palabra": perfil == "brote",
		"visible_min": visible,
		"tamano_animal": tam,
		"zona_toque_min_px": {"semilla": 160, "brote": 96, "estrella": 64}[perfil],
		"margen_toque_px": 24,
		"umbral_arrastre_px": 16,
		"lupa": bool(_v(perfil, "lupa", zi)),
		"mapita": perfil != "semilla",
		"tiempo_par_s": par,
		"sol": sol,
		"regalo_tras_derrotas": {"semilla": 2, "brote": 2, "estrella": 3}[perfil],
		"ayuda_fuerte_tras_derrotas": {"derrotas": 3, "todos_asoman": true, "sin_sol": true} if perfil == "semilla" else null,
		"descanso_tras_derrotas": {"semilla": null, "brote": 3, "estrella": 4}[perfil],
		"ayuda_idle_s": [6, 10] if perfil == "semilla" else ([12, 20] if perfil == "brote" else null),
		"pistas_cuestan_estrellita": perfil == "estrella",
		"puntos": {"encontrado": 100, "racha_max": 5, "ojo_aguila": 100, "dos_pasos": 100, "por_segundo": 10},
		"racha_brote_s": 25,
	}
	if perfil == "semilla":
		nivel["escenas"] = 2
		nivel["ruido_semilla_s"] = [5, 8]
		nivel.erase("umbrales_puntaje")
	else:
		nivel["umbrales_puntaje"] = _umbrales(perfil, zi, n_obj, int(_v(perfil, "dos_pasos", zi)), par)
	nivel["lineas_voz"] = _voces(zi, perfil, pool, senuelos, secretos)
	_guardar(RAIZ + zona + "/buscar_%s.json" % perfil, nivel)


## El sorteo del juego separa a todos (sin piezas compartidas ni cajas pisadas) en 20 partidas, tambien en
## la 2.a escena de Maxi y tras un reintento.
func _factible(perfil: String, objetos: Array, por_id: Dictionary, pool: Array, n: int, fijos: Array, senuelos: Array, secretos: Array) -> bool:
	var animales: Array = []
	for id in por_id:
		animales.append({"id": id, "aspecto": CAT[id]["aspecto"], "escondites": por_id[id]})
	var nivel := {"perfil": perfil, "objetos": objetos, "animales": animales, "objetivos": pool, "objetivos_por_partida": n,
		"objetivos_fijos": fijos, "senuelos": senuelos, "secretos": secretos, "escenas": 2 if perfil == "semilla" else 1}
	for semilla in 20:
		var l := LogicaBuscar.new()
		l.avisar_sorteo = false
		l.configurar(nivel, 500 + semilla)
		if not l.ultimo_sorteo_unico:
			var piezas := {}
			for id in l.en_escena():
				var ps := []
				for e in l.escondites_de(id):
					ps.append(l.pieza_de(e))
				piezas[id] = ps
			print("DBG 1a escena falla %s" % [piezas])
			return false
		for id in l.objetivos.duplicate():
			l.encontrados.append(id)
		l.estado = "ronda"
		l.siguiente_ronda_escena()
		if not l.ultimo_sorteo_unico:
			var cuenta := {}
			for id in l.en_escena():
				cuenta[id] = l.escondites_de(id).size()
			print("DBG 2a escena falla s=%d obj=%s %s" % [semilla, l.objetivos, cuenta])
			return false
	return true


func _opciones(id: String, objetos: Array) -> int:
	var n := 0
	for obj in objetos:
		if _habitat_ok(id, obj):
			n += 1
	return n


func _umbrales(perfil: String, zi: int, n: int, dos_pasos: int, par: float) -> Dictionary:
	# z1: los valores semilla de planeta-animalia-zonas.md §8; el resto, la misma proporcion sobre el maximo.
	if zi == 0:
		return {"dos": 1500, "tres": 1900} if perfil == "brote" else {"dos": 2600, "tres": 3300}
	var base := 0
	for i in n:
		base += 100 * mini(i + 1, 5)
	var maximo := base + 100 * n + 100 * dos_pasos
	return {"dos": int(round(maximo * 0.6 / 100.0)) * 100, "tres": int(round((maximo * 0.82 + 2.5 * par) / 100.0)) * 100}


# ---------------------------------------------------------------------------
# Composicion de la escena
# ---------------------------------------------------------------------------

const FACTOR := {"arbusto": 1.0, "roca": 0.95, "arbol": 0.95, "acacia": 0.95, "helecho": 1.05, "pasto_alto": 1.0, "juncos": 1.0,
	"nenufar": 1.0, "nido": 0.85, "tronco": 1.0, "hongo": 1.05, "flor_gigante": 0.95, "carpa": 1.05, "fardo": 1.05, "balde": 1.1,
	"regadera": 1.1, "carretilla": 1.0, "gallinero": 0.95, "cerca": 1.0, "bote": 1.0, "manguera": 1.1, "camion": 1.0, "cueva": 1.0,
	"volcan": 1.0, "geiser": 1.0, "huesos": 1.0, "nube": 1.0, "cesto": 1.1, "tronco_hueco": 1.0, "cristales": 1.1}
const REACCION := {"arbusto": "sacudir", "arbol": "sacudir", "acacia": "sacudir", "helecho": "sacudir", "pasto_alto": "sacudir",
	"juncos": "sacudir", "nido": "sacudir", "flor_gigante": "sacudir", "roca": "rebotar", "tronco": "rebotar", "hongo": "rebotar",
	"balde": "rebotar", "carretilla": "rebotar", "cesto": "rebotar", "gallinero": "rebotar", "cerca": "rebotar", "carpa": "sacudir",
	"fardo": "sacudir", "nenufar": "salpicar", "bote": "salpicar", "manguera": "chorro", "geiser": "chorro", "camion": "chorro",
	"regadera": "chorro", "nube": "puf", "volcan": "puf", "huesos": "xilofono", "cueva": "rebotar", "tronco_hueco": "rebotar",
	"cristales": "xilofono"}
const SONIDO := {"sacudir": "sfx/ui/polvo.ogg", "rebotar": "sfx/ui/polvo_boing.ogg", "salpicar": "sfx/ui/blup.ogg", "chorro": "sfx/ui/fuuush.ogg",
	"puf": "sfx/ui/puf.ogg", "xilofono": "sfx/ui/toque.ogg"}
const AGUA_TIPOS := ["nenufar", "bote", "juncos"]
const ARBOL_TIPOS := ["arbol", "acacia", "nido"]
const CIELO_TIPOS := ["nube"]


func _agua_rect(zona: String, W: float, H: float) -> Rect2:
	var suelo := _suelo_y(H)
	if zona == "zona2_laguna":
		if W <= 1280:
			# Maxi: una pantalla; la laguna atras y las piezas de la orilla delante.
			return Rect2(W * 0.25, suelo + 22, W * 0.5, 110)
		return Rect2(W * 0.2, suelo + 30, W * 0.6, H - suelo - 170)
	if zona == "zona5_valle":
		return Rect2(W * 0.62, suelo + 40, W * 0.28, H - suelo - 190)
	return Rect2()


func _suelo_y(H: float) -> float:
	return 380.0 if H <= 720 else 520.0


func _fondo(zona: String, W: float, H: float) -> Dictionary:
	var f: Dictionary = FONDOS[zona].duplicate(true)
	var k := H / 720.0
	for colina in f.get("lejos", []):
		colina["y"] = float(colina["y"]) * k
	f["suelo"]["y"] = _suelo_y(H)
	var agua := _agua_rect(zona, W, H)
	if agua.size.x > 0:
		f["agua"] = [{"rect": [agua.position.x, agua.position.y, agua.size.x, agua.size.y], "color": "#5CC8F0"}]
	return f


var _visible_actual := 0.5


## Escala de una pieza: proporcional al animal del perfil y mas grande cuanto mas escondido debe quedar
## (Maxi 80 % visible: piezas bajitas; Sofia 20 %: piezas que tapan casi todo).
func _escala(tipo: String, tam: float, H: float) -> float:
	var nominal: Vector2 = G.TAMANO_NOMINAL.get(tipo, Vector2(160, 120))
	var s := tam / 120.0 * (1.12 - 0.75 * _visible_actual) * float(FACTOR.get(tipo, 1.0)) * rng.randf_range(0.95, 1.12)
	if tipo == "volcan":
		s = clampf(H * 0.42 / nominal.y, 0.6, 1.2)
	# Nada mas alto que el 62 % de la escena.
	return snappedf(minf(s, H * 0.62 / nominal.y), 0.01)


func _componer(zona: String, perfil: String, zi: int, W: float, H: float, tam: float, n: int, n_abribles: int, n_dos: int) -> Array:
	var piezas: Dictionary = PIEZAS[zona]
	var objetos: Array = []
	var suelo := _suelo_y(H)
	var agua := _agua_rect(zona, W, H)
	var max_y := H - 150.0
	# Margen lateral: lejos de Toby y de la columna del sol (Maxi no recorre: su pantalla es la escena).
	var margen_x := 300.0 if W <= 1280 else 260.0
	var tipos: Array = []
	for i in n_abribles:
		tipos.append({"tipo": piezas["abribles"][i % piezas["abribles"].size()], "abrible": true, "pasos": 2 if i < n_dos else 1})
	var n_agua := 0
	if agua.size.x > 0:
		n_agua = mini(piezas["agua"].size(), maxi(2, n / 4))
	var n_cielo := maxi(1, n / 7)
	var n_suelo := n - tipos.size() - n_agua - n_cielo
	for i in n_suelo:
		tipos.append({"tipo": piezas["suelo"][i % piezas["suelo"].size()]})
	# Carpa de Toby (z1) y manguera / camion de bomberos (Maxi) presentes aunque no se abran.
	var hay: Array = tipos.map(func(t) -> String: return t["tipo"])
	if zona == "zona1_campamento" and not "carpa" in hay:
		tipos[0] = {"tipo": "carpa"}
	if perfil != "semilla":
		tipos = tipos.filter(func(t) -> bool: return not t["tipo"] in ["manguera", "camion"]) + [{"tipo": "arbusto"}]
	_mezclar(tipos)
	# Las de suelo, repartidas a lo ancho en filas (atras / medio / adelante), saltando el agua.
	var filas: Array = [suelo + 70, suelo + 125, max_y - 30] if H <= 720 else [suelo + 80, suelo + 170, suelo + 260, suelo + 350, max_y - 10]
	var cuantos := tipos.size()
	var x_disp: Array = []
	var paso := (W - 2.0 * margen_x) / maxf(1.0, cuantos)
	for i in cuantos:
		x_disp.append(margen_x + paso * (i + 0.5))
	var k := 0
	for t in tipos:
		var x: float = x_disp[k] + rng.randf_range(-paso * 0.25, paso * 0.25)
		var y: float = filas[k % filas.size()] + rng.randf_range(-12, 12)
		if t["tipo"] in ["volcan"]:
			y = suelo + 20
		if agua.size.x > 0 and agua.grow(30).has_point(Vector2(x, y)):
			y = maxf(y, agua.end.y + 30) if agua.end.y + 30 <= max_y else agua.position.y - 10
		var obj := {"id": "%s_%d" % [t["tipo"], k], "tipo": t["tipo"], "pos": [snappedf(x, 1), snappedf(minf(y, max_y), 1)],
			"escala": _escala(t["tipo"], tam, H), "espejo": rng.randf() < 0.5}
		if t["tipo"] == "volcan":
			obj["z"] = 0
		if t.get("abrible", false):
			obj["escondite"] = true
			obj["pasos"] = int(t["pasos"])
			obj["reaccion"] = "abrir"
		else:
			obj["reaccion"] = REACCION.get(t["tipo"], "sacudir")
		obj["sonido"] = SONIDO.get(obj["reaccion"], "sfx/ui/abrir.ogg")
		if t["tipo"] == "arbusto" and rng.randf() < 0.4:
			obj["flores"] = true
		objetos.append(obj)
		k += 1
	# Agua: nenufares, bote y juncos dentro de la laguna.
	for i in n_agua:
		var tipo: String = piezas["agua"][i % piezas["agua"].size()]
		var x2 := agua.position.x + agua.size.x * (i + 0.5) / n_agua + rng.randf_range(-30, 30)
		var y2 := agua.position.y + agua.size.y * (0.45 + 0.3 * (i % 2))
		if tipo == "juncos":
			y2 = agua.position.y + agua.size.y * 0.35
		objetos.append({"id": "%s_a%d" % [tipo, i], "tipo": tipo, "pos": [snappedf(x2, 1), snappedf(y2, 1)], "escala": _escala(tipo, tam, H),
			"espejo": rng.randf() < 0.5, "reaccion": REACCION[tipo], "sonido": SONIDO[REACCION[tipo]]})
	# Cielo: nubes (escondite de pajaros).
	for i in n_cielo:
		var x3 := margen_x + (W - 2 * margen_x) * (i + 0.5) / n_cielo + rng.randf_range(-80, 80)
		objetos.append({"id": "nube_%d" % i, "tipo": "nube", "pos": [snappedf(x3, 1), snappedf(suelo * 0.55 + rng.randf_range(-20, 20), 1)],
			"escala": _escala("nube", tam, H), "reaccion": "puf", "sonido": SONIDO["puf"]})
	# Nidos en los arboles (la selva alta los usa mas).
	var n_nidos := 0
	for obj in objetos.duplicate():
		if obj["tipo"] in ["arbol", "acacia"] and (zona == "zona4_nidos" or n_nidos < 1):
			var s := float(obj["escala"])
			var lado := -1.0 if rng.randf() < 0.5 else 1.0
			var base := G.vec(obj["pos"])
			var alto := 230.0 if obj["tipo"] == "arbol" else 262.0
			objetos.append({"id": "nido_%d" % n_nidos, "tipo": "nido", "pos": [snappedf(base.x + lado * 70 * s, 1), snappedf(base.y - alto * s, 1)],
				"escala": snappedf(s * 0.9, 0.01), "z": base.y + 1, "reaccion": "sacudir", "sonido": SONIDO["sacudir"]})
			n_nidos += 1
	return objetos


func _mezclar(lista: Array) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp


# ---------------------------------------------------------------------------
# Escondites: la parte visible se MIDE y se ajusta con busqueda binaria
# ---------------------------------------------------------------------------

func _habitat_ok(id: String, obj: Dictionary) -> bool:
	var hab: Array = CAT[id]["habitat"]
	var tipo := str(obj["tipo"])
	if bool(obj.get("escondite", false)):
		return "suelo" in hab or "arbol" in hab
	if tipo in AGUA_TIPOS:
		return "agua" in hab
	if tipo in CIELO_TIPOS:
		return "aire" in hab
	if tipo == "nido":
		return "aire" in hab or "arbol" in hab
	if tipo in ["arbol", "acacia"]:
		return "suelo" in hab or "arbol" in hab or "aire" in hab
	if tipo == "volcan":
		return "suelo" in hab and float(CAT[id]["rel"]) >= 1.2
	return "suelo" in hab


func _coberturas_delante(objetos: Array, z: float, abrir_id := "") -> Array:
	var salida: Array = []
	for obj in objetos:
		var zo := float(obj.get("z", G.vec(obj["pos"]).y))
		if zo > z:
			salida.append_array(G.cobertura(obj, 1.0 if obj["id"] == abrir_id else 0.0))
	return salida


func _medir(id: String, pie: Vector2, t: float, espejo: bool, cobs: Array) -> Dictionary:
	var partes := G.animal_mundo(CAT[id]["aspecto"], pie, t, espejo)
	var m := G.medir_visible(partes, cobs)
	m["partes"] = partes
	return m


## Candidatos (ancla, direccion de salida y recorrido maximo) segun la pieza.
func _anclas(obj: Dictionary, id: String, t: float) -> Array:
	var tipo := str(obj["tipo"])
	var pos := G.vec(obj["pos"])
	var s := float(obj["escala"])
	var caja := G.caja_de(G.cobertura(obj, 0.0))
	var hab: Array = CAT[id]["habitat"]
	var salida: Array = []
	if bool(obj.get("escondite", false)):
		salida.append({"lado": "dentro", "ancla": pos + Vector2(0, -6 * s), "dir": Vector2(0, -1), "max": 0.0})
		return salida
	match tipo:
		"arbol", "acacia":
			var copa := Vector2(pos.x, caja.position.y + caja.size.y * 0.32)
			if "arbol" in hab or "aire" in hab:
				salida.append({"lado": "copa_izq", "ancla": copa + Vector2(0, t * 0.5), "dir": Vector2(-1, 0), "max": caja.size.x * 0.5 + t})
				salida.append({"lado": "copa_der", "ancla": copa + Vector2(0, t * 0.5), "dir": Vector2(1, 0), "max": caja.size.x * 0.5 + t})
				salida.append({"lado": "copa_arriba", "ancla": copa + Vector2(0, t * 0.6), "dir": Vector2(0, -1), "max": caja.size.y * 0.4 + t})
			if "suelo" in hab:
				salida.append({"lado": "tronco_izq", "ancla": pos + Vector2(0, -4), "dir": Vector2(-1, 0), "max": t})
				salida.append({"lado": "tronco_der", "ancla": pos + Vector2(0, -4), "dir": Vector2(1, 0), "max": t})
		"nube":
			var c := caja.get_center() + Vector2(0, t * 0.5)
			salida.append({"lado": "izq", "ancla": c, "dir": Vector2(-1, 0), "max": caja.size.x * 0.5 + t})
			salida.append({"lado": "der", "ancla": c, "dir": Vector2(1, 0), "max": caja.size.x * 0.5 + t})
			salida.append({"lado": "arriba", "ancla": c, "dir": Vector2(0, -1), "max": caja.size.y * 0.5 + t})
		"nido":
			salida.append({"lado": "arriba", "ancla": pos + Vector2(0, -6 * s) + Vector2(0, t * 0.6), "dir": Vector2(0, -1), "max": t})
		_:
			var base := pos + Vector2(0, -3)
			salida.append({"lado": "izq", "ancla": base, "dir": Vector2(-1, 0), "max": caja.size.x * 0.5 + t * 0.9})
			salida.append({"lado": "der", "ancla": base, "dir": Vector2(1, 0), "max": caja.size.x * 0.5 + t * 0.9})
			# Por arriba solo si los pies siguen tapados (nadie flota).
			salida.append({"lado": "arriba", "ancla": base, "dir": Vector2(0, -1), "max": caja.size.y * 0.4})
	_mezclar(salida)
	return salida


func _escondites_para(id: String, objetos: Array, tam: float, vis_min: float, W: float, H: float, perfil: String, zi: int, aceptadas: Array) -> Array:
	# Semilla: la escena es una sola pantalla; los grandes (caballo, elefante, braquio) se topan en 1,15.
	var rel := minf(float(CAT[id]["rel"]), 1.15) if W <= 1280 else float(CAT[id]["rel"])
	var t := snappedf(tam * rel, 1)
	var objetivo := minf(vis_min + 0.1, 0.93)
	var candidatos := objetos.filter(func(o) -> bool: return _habitat_ok(id, o))
	_mezclar(candidatos)
	# Las abribles primero: asi cada escondite que se abre suele guardar a alguien.
	candidatos.sort_custom(func(a, b) -> bool: return int(a.get("escondite", false)) > int(b.get("escondite", false)))
	var salida: Array = []
	var usadas := {}
	for obj in candidatos:
		if salida.size() >= 3:
			break
		if usadas.has(obj["id"]):
			continue
		# A cada pieza la comparten como mucho 3 animales (el sorteo necesita variedad).
		var veces := aceptadas.filter(func(a) -> bool: return a["pieza"] == obj["id"]).size()
		if veces >= 3:
			continue
		for ancla in _anclas(obj, id, t):
			var esc := _probar(id, obj, ancla, t, objetivo, vis_min, objetos, W, H, aceptadas)
			if not esc.is_empty():
				esc["z_ok"] = true
				esc.erase("z_ok")
				if perfil == "estrella" and zi >= 1 and bool(CAT[id].get("camuflaje", false)) and not esc.has("dentro_de"):
					esc["camuflaje"] = true
					esc["mezcla"] = 0.45
				salida.append(esc)
				usadas[obj["id"]] = true
				break
	return salida


func _probar(id: String, obj: Dictionary, ancla: Dictionary, t: float, objetivo: float, vis_min: float, objetos: Array, W: float, H: float, aceptadas: Array) -> Dictionary:
	var espejo := rng.randf() < 0.5
	var z_host := float(obj.get("z", G.vec(obj["pos"]).y))
	var dentro: bool = ancla["lado"] == "dentro"
	var cobs := _coberturas_delante(objetos, z_host - 0.5, obj["id"] if dentro else "")
	var a: Vector2 = ancla["ancla"]
	var d: Vector2 = ancla["dir"]
	var pie := a
	var m: Dictionary
	if dentro:
		m = _medir(id, pie, t, espejo, cobs)
	else:
		var lo := 0.0
		var hi := float(ancla["max"])
		m = _medir(id, a + d * hi, t, espejo, cobs)
		if float(m["fraccion"]) < vis_min:
			_rechazos["max_no_llega"] = _rechazos.get("max_no_llega", 0) + 1
			return {}
		for i in 14:
			var mid := (lo + hi) / 2.0
			var mm := _medir(id, a + d * mid, t, espejo, cobs)
			if float(mm["fraccion"]) < objetivo:
				lo = mid
			else:
				hi = mid
		pie = a + d * hi
		m = _medir(id, pie, t, espejo, cobs)
	var f := float(m["fraccion"])
	if f < vis_min + 0.01:
		_rechazos["poco"] = _rechazos.get("poco", 0) + 1
		return {}
	var minimo := 160.0 if t >= 150 else (96.0 if t >= 95 else 64.0)
	var zona := G.zona_toque(m, m["partes"], 24.0, minimo)
	var caja_animal := G.caja_de(m["partes"])
	# Dentro de la escena, lejos de la lista (abajo), la casa (arriba a la izquierda), Toby (abajo a la
	# izquierda) y la columna del sol (derecha).
	if caja_animal.position.x < 20 or caja_animal.end.x > W - 20 or caja_animal.position.y < 10:
		_rechazos["fuera"] = _rechazos.get("fuera", 0) + 1
		return {}
	if zona.end.y > H - 130.0 or zona.position.x < 140 or zona.position.y < 112 or zona.end.x > W - 160:
		_rechazos["ui"] = _rechazos.get("ui", 0) + 1
		return {}
	if zona.position.x < 230 and zona.end.y > 380:
		_rechazos["toby"] = _rechazos.get("toby", 0) + 1
		return {}
	var visible_caja: Rect2 = m["caja"]
	# Un escondite que pisa lo visible de otro animal en otra pieza dejaria al sorteo sin salida (Maxi tiene
	# una sola pantalla): se descarta aqui, asi el sorteo solo tiene que repartir piezas.
	for prev in aceptadas:
		if prev["id"] != id and prev["pieza"] != obj["id"] and LogicaBuscar.se_pisan(prev["caja"], visible_caja):
			_rechazos["pisa"] = _rechazos.get("pisa", 0) + 1
			return {}
	# `caja` (lo visible): el sorteo nunca junta en una partida dos escondites que se pisen.
	var esc := {"pos": [snappedf(pie.x, 0.5), snappedf(pie.y, 0.5)], "tamano": t, "espejo": espejo,
		"visible": snappedf(f, 0.01), "asoma": [d.x, d.y],
		"caja": [roundf(visible_caja.position.x), roundf(visible_caja.position.y), roundf(visible_caja.size.x), roundf(visible_caja.size.y)]}
	if dentro:
		esc["dentro_de"] = obj["id"]
	else:
		esc["detras_de"] = obj["id"]
	aceptadas.append({"pieza": obj["id"], "caja": visible_caja, "id": id})
	return esc


# ---------------------------------------------------------------------------
# Voces (TSV para guionista / TTS; el juego funciona sin ellas)
# ---------------------------------------------------------------------------

const TEXTOS := {
	"semilla": {"intro": "¡Hola, Maxi! Mis amigos se escondieron. ¿Me ayudas a encontrarlos?",
		"instruccion": "¡Toca a los animalitos escondidos!", "otra_vez": "¡Se escondieron otra vez! ¡A buscar!",
		"derrota_gag": "¡Se puso el sol! ¡Cosquillas para Toby! ¡Otra vez!", "regalo": "¡Snif snif! ¡Encontré uno con mi nariz!",
		"ayuda_fuerte": "¡Ahora se esconden mal a propósito! ¡Mira, mira!"},
	"brote": {"intro": "¡Hola, Nicole! Mis amigos se escondieron. ¡Busquemos de a uno!",
		"instruccion": "Mira la tarjeta: ¡encuentra a ese amigo!", "ya_encontrado": "¡Ese ya lo encontraste!",
		"derrota_gag": "¡Se puso el sol! ¡Aquí estábamos! ¿Otra vez?", "regalo": "¡Snif snif! ¡Te encontré uno de regalo!",
		"record": "¡Nuevo récord, Nicole!", "primer_record": "¡Tu primer récord!", "descansar": "¿Quieres descansar un ratito? Puedes volver cuando quieras."},
	"estrella": {"intro": "¡Hola, Sofía! Lee las pistas y encuentra a cada animal antes de que se ponga el sol.",
		"instruccion": "Lee la tarjeta: ¿quién es?", "derrota_gag": "¡Se puso el sol! ¡Aquí estábamos todos!",
		"regalo": "¡Snif snif! Mi nariz encontró uno.", "pista_usada": "¡Snif snif! Por aquí huele a amigo...",
		"record": "¡Nuevo récord, Sofía!", "primer_record": "¡Tu primer récord!", "descansar": "¿Descansamos un poco? Lo que encontraste queda guardado.",
		"presenta_lupa": "¡Mira mi lupa! Tócala y después toca donde quieras mirar de cerca.",
		"presenta_radar": "Si te cuesta, toca mi antena: ¡mi nariz es un radar!"},
}


func _voces(zi: int, perfil: String, pool: Array, senuelos: Array, secretos: Array) -> Dictionary:
	var base := "voces/animalia/buscar/%s/" % perfil
	var voces := {}
	var claves: Dictionary = TEXTOS[perfil]
	for clave in claves:
		var ruta := base + "%s.wav" % clave
		voces[clave] = ruta
		_tsv_una(ruta, claves[clave])
	var cuenta := base + "z%d_cuenta_toby.wav" % (zi + 1)
	voces["cuenta_toby"] = cuenta
	_tsv_una(cuenta, "¡A la una, a las dos y a las tres! ¡A esconderse!")
	voces["victoria"] = [base + "victoria_01.wav", base + "victoria_02.wav"]
	_tsv_una(base + "victoria_01.wav", "¡Los encontraste a todos! ¡Foto de grupo!")
	_tsv_una(base + "victoria_02.wav", "¡Qué ojo de explorador! ¡Clic!")
	if perfil == "brote":
		var busca := {}
		for id in pool:
			var r := base + "busca_%s.wav" % id
			busca[id] = r
			_tsv_una(r, "¡Busca al %s!" % CAT[id]["palabra"].to_lower() if not CAT[id]["palabra"].ends_with("A") else "¡Busca a la %s!" % CAT[id]["palabra"].to_lower())
		voces["busca"] = busca
	if perfil == "semilla":
		var llama := {}
		for id in pool:
			var r2 := base + "llama_%s.wav" % id
			llama[id] = r2
			_tsv_una(r2, "¡Aquí estoy! ¡Búscame!")
		voces["busca"] = llama
	if not senuelos.is_empty():
		var sv := {}
		for id in senuelos:
			var r3 := "voces/animalia/buscar/senuelos/%s.wav" % id
			sv[id] = r3
			_tsv_una(r3, str(CAT[id].get("saludo", "¡Hola! No soy yo.")))
		voces["senuelo"] = sv
	var sec := {}
	for id in secretos:
		var r4 := "voces/animalia/buscar/secretos/%s.wav" % id
		sec[id] = r4
		_tsv_una(r4, "¡Pío pío! ¡Un huevito de dino!" if id == "huevito" else "¡El pony estelar! ¡Qué secreto más lindo!")
	voces["secreto"] = sec
	for id in pool + senuelos + secretos:
		_tsv_una("voces/animalia/nombres/%s.wav" % id, "¡%s!" % CAT[id]["palabra"].capitalize())
	return voces


func _tsv_una(ruta: String, texto: String) -> void:
	var linea := "%s\t%s" % [ruta, texto]
	if not linea in _tsv:
		_tsv.append(linea)


func _escribir_tsv() -> void:
	DirAccess.make_dir_recursive_absolute(TSV.get_base_dir())
	var f := FileAccess.open(TSV, FileAccess.WRITE)
	f.store_line("# Voces del «Escondite animal» (motor buscar, HE-118). Generado por herramientas/generar_niveles_buscar.gd.")
	f.store_line("# Formato: ruta relativa a assets/audio/ <TAB> texto. La directiva '# personaje: <id>' elige la voz (herramientas/voces_personajes/<id>/).")
	f.store_line("# PENDIENTE: no existe herramientas/voces_personajes/toby/ (guionista HE-112). El juego funciona sin estos audios.")
	f.store_line("# Regenerar: python herramientas/generar_voces_fal.py --lista assets/audio/voces/animalia/buscar/lineas_tts.tsv")
	f.store_line("# personaje: toby")
	var vistos := {}
	for linea in _tsv:
		var ruta := linea.split("\t")[0]
		if vistos.has(ruta):
			continue
		vistos[ruta] = true
		f.store_line(linea)
	f.close()
	print("voces: %d lineas en %s" % [vistos.size(), TSV])


func _guardar(ruta: String, datos: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(datos, "  ", false) + "\n")
	f.close()
	var esc := 0
	for animal in datos["animales"]:
		esc += animal["escondites"].size()
	print("%s: %d piezas, %d animales, %d escondites" % [ruta, datos["objetos"].size(), datos["animales"].size(), esc])


# ---------------------------------------------------------------------------
# Nivel de equipo (ficha §12.2): escena compartida de 2560 x 720 con 6 objetivos
# ---------------------------------------------------------------------------

func _generar_equipo() -> void:
	var zona := "zona1_campamento"
	rng.seed = hash("equipo_buscar") & 0x7fffffff
	var W := 2560.0
	var H := 720.0
	var tam := 110.0
	var vis := 0.5
	var pool := ["gatito", "pony", "perrito", "vaca", "gerbo", "pato"]
	_visible_actual = vis
	var objetos := _componer(zona, "brote", 0, W, H, tam, 15, 2, 0)
	var aceptadas: Array = []
	var animales: Array = []
	for id in pool + ["huevito"]:
		var ent := _escondites_para(id, objetos, tam, vis, W, H, "brote", 0, aceptadas)
		if ent.size() < 2:
			push_error("generar equipo: %s solo tiene %d escondites" % [id, ent.size()])
			_fallas += 1
		var d: Dictionary = CAT[id]
		if id == "huevito":
			pass  # En equipo no se marca el huevo de nadie (no hay hermano individual).
		animales.append({"id": id, "nombre": d["palabra"].capitalize(), "palabra": d["palabra"], "aspecto": d["aspecto"], "sonido": "sfx/ui/blup.ogg",
			"tono": d["tono"], "nombre_voz": "voces/animalia/nombres/%s.wav" % id, "escondites": ent,
			"pista": {"texto": d["pistas"][0] if d["pistas"].size() > 0 else d["palabra"], "voz": ""}})
	var busca := {}
	for id in pool:
		busca[id] = "voces/animalia/buscar/brote/busca_%s.wav" % id
	var nivel := {
		"id_nivel": "animalia_z1_buscar_equipo", "motor": "buscar", "modo_juego": "equipo", "perfil": "brote",
		"planeta": "animalia", "zona": zona,
		"nota": "Escondite animal en equipo (motor-buscar.md §12.2; HE-118). Escena compartida de 2560 x 720 con 6 objetivos favoritos de los tres; lo que encuentra uno queda para todos. Sin sol: el reloj es el Coleccionauta. PROVISIONAL: calibrar pasos_rival con el simulador de equipo.",
		"escena": {"tamano": [W, H], "inicio_vista": [0, 0], "zona_util_max_y": H - 130.0, "fondo": _fondo(zona, W, H)},
		"objetos": objetos, "animales": animales, "objetivos": pool, "senuelos": [], "secretos": ["huevito"],
		"modo_lista": "uno", "mostrar_palabra": true, "visible_min": vis, "tamano_animal": tam,
		"zona_toque_min_px": 96, "margen_toque_px": 24, "umbral_arrastre_px": 16, "lupa": false, "mapita": true,
		"tiempo_par_s": null, "sol": null,
		"equipo": {
			"rival": "coleccionauta", "orden": "maxi_intercalado", "puerta_tras_semilla": "arrastre", "bloqueo_tras_puerta_ms": 400,
			"maxi_mueve_rival": false, "semilla_auto_s": 20,
			"aciertos_max_turno": {"semilla": 1, "brote": 1, "estrella": 2},
			"segundos_por_turno": {"brote": 40, "estrella": 35},
			"composiciones": {"maxi+nicole+sofia": {"pasos_rival": 6}, "maxi+nicole": {"pasos_rival": 6}, "maxi+sofia": {"pasos_rival": 5}, "nicole+sofia": {"pasos_rival": 5}},
		},
		"lineas_voz": {
			"busca": busca, "victoria_equipo": "voces/animalia/buscar/equipo/victoria.wav",
			"derrota_gag_equipo": "PENDIENTE", "logro_comun": "PENDIENTE",
			"le_toca": {
				"maxi": ["voces/nucleo/equipo/le_toca_maxi_01.wav", "voces/nucleo/equipo/le_toca_maxi_02.wav"],
				"nicole": ["voces/nucleo/equipo/le_toca_nicole_01.wav", "voces/nucleo/equipo/le_toca_nicole_02.wav"],
				"sofia": ["voces/nucleo/equipo/le_toca_sofia_01.wav", "voces/nucleo/equipo/le_toca_sofia_02.wav"]},
			"nos_alcanzo": "voces/nucleo/equipo/nos_alcanzo.wav",
		},
	}
	_tsv_una("voces/animalia/buscar/equipo/victoria.wav", "¡Los encontramos a todos juntos! ¡Foto de equipo!")
	_guardar(RAIZ + zona + "/buscar_equipo.json", nivel)
