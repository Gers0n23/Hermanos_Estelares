# -*- coding: utf-8 -*-
"""Genera los 15 niveles de "Pinta con Coco" (motor lienzo_libre) y el TSV de voces TTS.

Lienzo: 824x530. Uso: python herramientas/generar_pinta.py [raiz_repo]
"""
import json, math, os, sys

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 824, 530
VOCES = {}  # ruta relativa a assets/audio/ -> texto
PREF = "voces/arcoiris/pinta/"


def voz(ruta, texto):
    r = PREF + ruta + ".wav"
    if r in VOCES and VOCES[r] != texto:
        raise SystemExit("voz duplicada con otro texto: " + r)
    VOCES[r] = texto
    return r


# ---------------------------------------------------------------- formas
def reg(id, forma, sug=None, **kw):
    d = {"id": id, "forma": forma}
    d.update(kw)
    if sug:
        d["sugerido"] = sug
    return d

def rect(id, x, y, w, h, sug=None, r=0, **kw):
    return reg(id, "rect", sug, rect=[x, y, w, h], redondeo=r, **kw)

def eli(id, cx, cy, rx, ry, sug=None, giro=0, **kw):
    d = reg(id, "elipse", sug, centro=[cx, cy], radios=[rx, ry], **kw)
    if giro:
        d["giro"] = giro
    return d

def circ(id, cx, cy, r, sug=None, **kw):
    return reg(id, "circulo", sug, centro=[cx, cy], radio=r, **kw)

def poly(id, pts, sug=None, suave=0, **kw):
    d = reg(id, "poligono", sug, puntos=[[round(x, 1), round(y, 1)] for x, y in pts], **kw)
    if suave:
        d["suave"] = suave
    return d

def fig(id, forma, cx, cy, r, sug=None, giro=0, **kw):
    d = reg(id, forma, sug, centro=[cx, cy], radio=r, **kw)
    if giro:
        d["giro"] = giro
    return d

def fija(region, inicial):
    region["fija"] = True
    region["inicial"] = inicial
    region.pop("sugerido", None)
    return region

def anillo(id, cx, cy, r0, r1, a0, a1, sug, pasos=24):
    pts = []
    for i in range(pasos + 1):
        a = a0 + (a1 - a0) * i / pasos
        pts.append((cx + math.cos(a) * r1, cy + math.sin(a) * r1))
    for i in range(pasos, -1, -1):
        a = a0 + (a1 - a0) * i / pasos
        pts.append((cx + math.cos(a) * r0, cy + math.sin(a) * r0))
    return poly(id, pts, sug)

def ojo(cx, cy, r): return {"tipo": "ojo", "centro": [cx, cy], "radio": r}
def sonrisa(cx, cy, r): return {"tipo": "sonrisa", "centro": [cx, cy], "radio": r}
def rubor(cx, cy, r): return {"tipo": "rubor", "centro": [cx, cy], "radio": r}
def punto(cx, cy, r, color="#2B3350"): return {"tipo": "punto", "centro": [cx, cy], "radio": r, "color": color}
def linea(pts, grosor=4, suave=0, color=None):
    d = {"tipo": "linea", "puntos": [[x, y] for x, y in pts], "grosor": grosor}
    if suave: d["suave"] = suave
    if color: d["color"] = color
    return d

C = {  # sugeridos (cercanos a la paleta)
    "rojo": "#EE4035", "naranja": "#FF9A2E", "amarillo": "#FFD23F", "verde": "#4CBF56", "azul": "#3470D8",
    "violeta": "#9357D6", "rosa": "#FF7EB6", "turquesa": "#2EC4B6", "blanco": "#FFFFFF", "negro": "#2B2E3F",
    "cafe": "#9A6238", "celeste": "#8ED3FF", "gris": "#9AA0B0", "verde_oscuro": "#2E8B57", "lila": "#C7A6EC",
}

def cielo(sug=C["celeste"]): return rect("cielo", 0, 0, W, H, sug)
def sol(cx, cy, r=46): return circ("sol", cx, cy, r, C["amarillo"])
def nube(id, cx, cy, s=1.0):
    pts = []
    for i in range(40):
        a = math.tau * i / 40
        rx, ry = 78 * s, 30 * s
        bump = 1 + 0.18 * max(0, math.sin(a * 3 - 1.2)) if math.sin(a) < 0 else 1
        pts.append((cx + math.cos(a) * rx * bump, cy + math.sin(a) * ry * bump * (1.5 if math.sin(a) < 0 else 1)))
    return poly(id, pts, C["blanco"])


# ---------------------------------------------------------------- laminas por zonas
def lam(id, regiones, detalles=(), voz_=None, etiquetas=(), **kw):
    d = {"id": id, "tipo": "zonas", "regiones": regiones, "detalles": list(detalles)}
    if voz_: d["voz"] = voz_
    if etiquetas: d["etiquetas"] = list(etiquetas)
    d.update(kw)
    return d

def pony():
    L = C["lila"]
    return lam("pony", [
        cielo(), sol(730, 85), nube("nube", 180, 95),
        poly("pasto", [(0, 410), (160, 392), (330, 405), (520, 388), (700, 400), (824, 392), (824, 530), (0, 530)], C["verde"], 2),
        poly("cola", [(262, 238), (222, 226), (180, 250), (160, 300), (172, 352), (205, 378), (214, 330), (236, 290), (262, 272)], C["rosa"], 2),
        rect("pata_1", 270, 320, 40, 120, L, 18), rect("pata_2", 318, 325, 40, 116, L, 18),
        rect("pata_3", 452, 325, 40, 116, L, 18), rect("pata_4", 500, 320, 40, 120, L, 18),
        eli("cuerpo", 392, 300, 150, 72, L),
        poly("cuello", [(470, 262), (515, 165), (575, 150), (592, 210), (548, 318)], L, 1),
        eli("cabeza", 615, 170, 72, 50, L, giro=28),
        poly("crin", [(592, 118), (548, 106), (505, 136), (473, 188), (452, 250), (490, 262), (512, 214), (542, 176), (585, 156)], C["rosa"], 2),
        poly("oreja", [(582, 128), (596, 70), (624, 122)], L),
        eli("hocico", 668, 204, 34, 27, "#FFB3C7", giro=28),
        fig("estrella", "estrella", 382, 296, 34, C["amarillo"]),
    ], [ojo(628, 160, 12), rubor(646, 188, 12), punto(690, 206, 4), linea([(662, 224), (675, 230), (690, 226)], 3)],
        voz("laminas/pony", "¡Un pony precioso!"), ["animales"])

def jirafa():
    Y = C["amarillo"]; K = C["cafe"]
    return lam("jirafa", [
        cielo(), sol(92, 80, 42), nube("nube", 690, 90),
        poly("pasto", [(0, 430), (200, 415), (420, 428), (640, 412), (824, 425), (824, 530), (0, 530)], C["verde"], 2),
        rect("tronco", 102, 250, 28, 190, K, 10), eli("copa", 116, 232, 98, 42, C["verde_oscuro"]),
        rect("cuernito_1", 540, 44, 12, 40, K, 6), rect("cuernito_2", 564, 38, 12, 42, K, 6),
        rect("pata_1", 262, 350, 34, 110, Y, 14), rect("pata_2", 306, 356, 34, 104, Y, 14),
        rect("pata_3", 398, 356, 34, 104, Y, 14), rect("pata_4", 442, 350, 34, 110, Y, 14),
        eli("cuerpo", 352, 318, 132, 62, Y),
        poly("cuello", [(418, 300), (505, 118), (556, 124), (480, 330)], Y, 1),
        eli("mancha_1", 300, 305, 26, 18, K), eli("mancha_2", 362, 342, 24, 16, K), eli("mancha_3", 405, 298, 20, 15, K),
        eli("mancha_4", 256, 330, 16, 13, K), eli("mancha_5", 470, 238, 14, 18, K), eli("mancha_6", 496, 176, 12, 15, K),
        eli("cabeza", 566, 108, 56, 36, Y, giro=18),
        poly("oreja", [(522, 92), (494, 76), (524, 106)], Y),
        eli("hocico", 613, 126, 30, 23, C["naranja"], giro=18),
    ], [ojo(575, 98, 10), rubor(592, 118, 10), punto(630, 120, 3.5), linea([(222, 300), (205, 360)], 4), punto(204, 366, 9, C["cafe"])],
        voz("laminas/jirafa", "¡Una jirafa de cuello larguísimo!"), ["animales"])

def gatito():
    N = C["naranja"]
    return lam("gatito", [
        rect("pared", 0, 0, W, 400, C["rosa"]), rect("piso", 0, 400, W, 130, C["cafe"]),
        rect("ventana", 580, 50, 170, 140, C["celeste"], 14),
        eli("cojin", 412, 448, 196, 46, C["violeta"]),
        poly("cola", [(500, 420), (585, 410), (628, 360), (612, 298), (586, 308), (597, 355), (562, 385), (505, 390)], N, 2),
        eli("cuerpo", 412, 360, 105, 95, N), eli("panza", 412, 388, 58, 60, C["blanco"]),
        eli("patita_1", 372, 445, 34, 22, C["blanco"]), eli("patita_2", 452, 445, 34, 22, C["blanco"]),
        poly("oreja_1", [(326, 158), (334, 66), (398, 120)], N), poly("oreja_2", [(498, 158), (490, 66), (426, 120)], N),
        eli("cabeza", 412, 192, 110, 88, N), eli("hocico", 412, 226, 40, 26, C["blanco"]),
        poly("lazo_1", [(412, 280), (370, 258), (370, 302)], C["rojo"]), poly("lazo_2", [(412, 280), (454, 258), (454, 302)], C["rojo"]),
        circ("ovillo", 660, 440, 46, C["turquesa"]),
    ], [ojo(372, 182, 16), ojo(452, 182, 16), rubor(350, 214, 14), rubor(474, 214, 14), punto(412, 212, 7, C["rosa"]),
        sonrisa(412, 222, 12), linea([(380, 222), (318, 212)], 3), linea([(380, 232), (320, 240)], 3),
        linea([(444, 222), (506, 212)], 3), linea([(444, 232), (504, 240)], 3), punto(412, 280, 9, C["rojo"]),
        linea([(665, 50), (665, 190)], 4), linea([(580, 120), (750, 120)], 4),
        linea([(622, 420), (690, 470)], 3, 0), linea([(630, 460), (700, 425)], 3)],
        voz("laminas/gatito", "¡Un gatito regalón!"), ["animales"])

def bandera_chile():
    return lam("bandera_chile", [
        cielo(), nube("nube", 690, 80, 0.8),
        poly("cordillera", [(0, 480), (120, 430), (230, 470), (360, 418), (480, 468), (620, 424), (740, 466), (824, 440), (824, 530), (0, 530)], C["gris"]),
        rect("asta", 94, 40, 16, 480, C["cafe"], 6), circ("perilla", 102, 36, 14, C["amarillo"]),
        rect("azul", 112, 60, 200, 200, "#0039A6"), rect("blanco", 312, 60, 400, 200, C["blanco"]),
        rect("rojo", 112, 260, 600, 200, "#D52B1E"), fig("estrella", "estrella", 212, 164, 70, C["blanco"]),
    ], [], voz("laminas/bandera_chile", "¡La bandera de Chile! Azul, blanco y rojo, con su estrella solitaria."), ["chile", "bandera"])

def torres_paine():
    G = C["gris"]
    return lam("torres_paine", [
        cielo(), sol(96, 78, 40), nube("nube", 668, 82),
        poly("macizo", [(0, 430), (90, 330), (170, 372), (250, 262), (560, 250), (650, 332), (740, 300), (824, 360), (824, 440), (0, 440)], C["lila"]),
        poly("torre_1", [(262, 430), (280, 190), (300, 150), (322, 186), (338, 430)], G),
        poly("torre_2", [(340, 430), (362, 140), (392, 100), (420, 138), (440, 430)], G),
        poly("torre_3", [(442, 430), (460, 176), (484, 146), (508, 182), (522, 430)], G),
        poly("nieve_1", [(284, 196), (300, 152), (320, 190), (302, 204)], C["blanco"]),
        poly("nieve_2", [(366, 146), (392, 102), (416, 142), (392, 158)], C["blanco"]),
        poly("nieve_3", [(464, 182), (484, 148), (504, 186), (484, 196)], C["blanco"]),
        poly("roca", [(130, 440), (230, 360), (300, 398), (400, 368), (500, 396), (590, 350), (700, 440)], C["cafe"], 1),
        rect("lago", 0, 432, W, 56, C["turquesa"]),
        poly("pampa", [(0, 482), (200, 472), (420, 486), (620, 470), (824, 482), (824, 530), (0, 530)], C["amarillo"], 2),
    ], [linea([(60, 450), (140, 450)], 3, color="#FFFFFF"), linea([(520, 462), (620, 462)], 3, color="#FFFFFF")],
        voz("laminas/torres_paine", "¡Las Torres del Paine, en el sur de Chile!"), ["chile", "lugar"])

def volcan_osorno():
    return lam("volcan_osorno", [
        cielo(), sol(98, 80, 42), nube("nube", 676, 86),
        poly("volcan", [(170, 440), (372, 110), (452, 110), (654, 440)], C["gris"]),
        poly("nieve", [(300, 228), (372, 110), (452, 110), (524, 228), (492, 212), (462, 240), (430, 214), (400, 244), (368, 214), (336, 240)], C["blanco"]),
        poly("bosque_1", [(0, 440), (0, 360), (60, 340), (130, 380), (200, 404), (260, 440)], C["verde"], 1),
        poly("bosque_2", [(824, 440), (824, 350), (760, 340), (690, 380), (620, 406), (560, 440)], C["verde"], 1),
        poly("pino_1", [(40, 440), (72, 352), (104, 440)], C["verde_oscuro"]),
        poly("pino_2", [(120, 440), (150, 368), (180, 440)], C["verde_oscuro"]),
        poly("pino_3", [(700, 440), (732, 352), (764, 440)], C["verde_oscuro"]),
        rect("lago", 0, 440, W, 90, C["azul"]),
        poly("vela", [(606, 474), (606, 402), (652, 474)], C["blanco"]),
        poly("bote", [(580, 478), (674, 478), (656, 506), (598, 506)], C["rojo"]),
    ], [linea([(40, 470), (130, 470)], 3, color="#FFFFFF"), linea([(260, 492), (380, 492)], 3, color="#FFFFFF")],
        voz("laminas/volcan_osorno", "¡El volcán Osorno, con su punta nevada!"), ["chile", "lugar"])

def valparaiso():
    regiones = [cielo(), sol(90, 76, 40),
                poly("cerro", [(0, 455), (0, 340), (160, 272), (360, 214), (560, 164), (720, 128), (824, 116), (824, 455)], C["verde"], 1)]
    colores = [C["amarillo"], C["rosa"], C["celeste"], C["verde"], C["naranja"], C["turquesa"], C["violeta"], C["rojo"], C["amarillo"], C["celeste"]]
    techos = [C["rojo"], C["azul"], C["rojo"], C["cafe"], C["violeta"], C["rojo"], C["naranja"], C["azul"], C["cafe"], C["rojo"]]
    casas = [(250, 382), (360, 380), (470, 378), (580, 376), (690, 374), (410, 296), (520, 290), (630, 282), (560, 206), (670, 196)]
    for i, (x, y) in enumerate(casas):
        regiones.append(rect("casa_%d" % (i + 1), x, y, 92, 70, colores[i], 6))
        regiones.append(poly("techo_%d" % (i + 1), [(x - 8, y + 2), (x + 46, y - 38), (x + 100, y + 2)], techos[i]))
    regiones += [
        poly("carro", [(96, 372), (150, 372), (172, 330), (118, 330)], C["amarillo"]),
        rect("mar", 0, 455, W, 75, C["azul"]),
        poly("barco", [(560, 478), (720, 478), (700, 510), (580, 510)], C["rojo"]),
        rect("cabina_barco", 610, 452, 60, 26, C["blanco"], 6),
    ]
    detalles = [linea([(40, 455), (200, 250)], 5), linea([(70, 455), (230, 250)], 5)]
    for i, (x, y) in enumerate(casas):
        detalles.append({"tipo": "punto", "centro": [x + 30, y + 30], "radio": 11, "color": "#FFFFFF"})
        detalles.append({"tipo": "punto", "centro": [x + 64, y + 30], "radio": 11, "color": "#FFFFFF"})
    return lam("valparaiso", regiones, detalles,
               voz("laminas/valparaiso", "¡Las casitas de colores de Valparaíso!"), ["chile", "lugar"])

def jardin_coco():
    regiones = [cielo(), sol(724, 82, 50), nube("nube_1", 470, 80, 0.8), nube("nube_2", 640, 190, 0.6)]
    colores = [C["rojo"], C["amarillo"], C["verde"], C["azul"]]
    for i in range(4):
        r1 = 200 - i * 30
        regiones.append(anillo("arco_%d" % (i + 1), 230, 360, r1 - 30, r1, math.pi, math.tau, colores[i]))
    regiones += [
        poly("pasto", [(0, 400), (200, 380), (420, 398), (640, 384), (824, 396), (824, 530), (0, 530)], C["verde"], 2),
        rect("palito", 760, 300, 14, 140, C["blanco"], 7), circ("chupetin", 767, 282, 44, C["turquesa"]),
        poly("taza", [(478, 450), (646, 450), (626, 336), (498, 336)], C["rosa"]),
        poly("glaseado", [(476, 342), (486, 290), (522, 258), (562, 240), (602, 258), (638, 290), (648, 342)], C["blanco"], 2),
        circ("cereza", 562, 230, 17, C["rojo"]),
        rect("puerta", 544, 386, 38, 64, C["cafe"], 18), circ("ventanita", 514, 372, 15, C["celeste"]),
        fig("flor_1", "flor", 110, 440, 40, C["violeta"]), circ("centro_1", 110, 440, 14, C["amarillo"]),
        fig("flor_2", "flor", 330, 462, 34, C["naranja"]), circ("centro_2", 330, 462, 12, C["amarillo"]),
        fig("flor_3", "flor", 700, 462, 38, C["rosa"]), circ("centro_3", 700, 462, 13, C["amarillo"]),
    ]
    det = [sonrisa(562, 408, 0.01), linea([(747, 262), (767, 282), (787, 272)], 3, 1), linea([(750, 300), (786, 296)], 3)]
    det = det[1:]
    return lam("jardin_coco", regiones, det, voz("laminas/jardin_coco", "¡Mi jardín quedó precioso!"), ["coco"])

def castillo():
    R = C["rosa"]; V = C["violeta"]
    return lam("castillo", [
        cielo(), sol(90, 80, 40), nube("nube", 690, 90, 0.8),
        poly("pasto", [(0, 440), (220, 425), (420, 438), (640, 424), (824, 436), (824, 530), (0, 530)], C["verde"], 2),
        rect("torre_1", 196, 186, 96, 260, R, 8), rect("torre_2", 532, 186, 96, 260, R, 8),
        rect("muralla", 292, 256, 240, 190, C["lila"]),
        poly("techo_1", [(184, 192), (244, 82), (304, 192)], V), poly("techo_2", [(520, 192), (580, 82), (640, 192)], V),
        poly("techo_3", [(300, 262), (412, 150), (524, 262)], V),
        poly("bandera_1", [(244, 84), (244, 44), (284, 58)], C["amarillo"]), poly("bandera_2", [(580, 84), (580, 44), (620, 58)], C["amarillo"]),
        rect("puerta", 372, 346, 80, 100, C["cafe"], 38),
        circ("ventana_1", 244, 262, 22, C["celeste"]), circ("ventana_2", 580, 262, 22, C["celeste"]),
        fig("ventana_corazon", "corazon", 412, 218, 26, C["rojo"]),
        poly("camino", [(372, 446), (452, 446), (520, 530), (304, 530)], C["amarillo"]),
    ], [linea([(244, 84), (244, 40)], 4), linea([(580, 84), (580, 40)], 4)],
        voz("laminas/castillo", "¡Un castillo de princesa!"), ["princesa"])

# --- Maxi
def fondo_liso(color="#FFF3D6"):
    return fija(rect("fondo", 0, 0, W, H), color)

def coco():
    L = C["lila"]
    return lam("coco", [
        fondo_liso("#FFF3D6"),
        poly("cola", [(540, 420), (622, 410), (672, 360), (662, 298), (626, 300), (632, 350), (600, 380), (545, 385)], L, 2),
        eli("pie_1", 345, 478, 64, 32, L), eli("pie_2", 479, 478, 64, 32, L),
        eli("cuerpo", 412, 375, 150, 118, L), eli("panza", 412, 395, 92, 82, "#FFE9C2"),
        eli("brazo_1", 268, 352, 42, 64, L, giro=28), eli("brazo_2", 556, 352, 42, 64, L, giro=-28),
        poly("cresta", [(350, 112), (362, 42), (412, 8), (466, 30), (482, 104)], C["rosa"], 2),
        eli("cabeza", 412, 190, 152, 106, L),
        fig("flor", "flor", 540, 102, 42, "#FFB3C7"),
    ], [ojo(352, 186, 26), ojo(472, 186, 26), rubor(318, 228, 26), rubor(506, 228, 26), sonrisa(412, 226, 34),
        punto(398, 206, 4), punto(426, 206, 4)],
        voz("laminas/coco", "¡Me pintaste toda! ¡Soy una Coco de colores!"), ["coco"])

def dino_amigo():
    V = C["verde"]
    return lam("dino", [
        fondo_liso("#E9F7FF"), fija(poly("suelo", [(0, 450), (824, 440), (824, 530), (0, 530)]), "#CDEFC4"),
        poly("cola", [(252, 328), (160, 318), (60, 380), (72, 408), (170, 396), (262, 392)], V, 2),
        poly("pua_1", [(262, 250), (292, 172), (334, 236)], C["naranja"]),
        poly("pua_2", [(334, 226), (370, 148), (410, 222)], C["naranja"]),
        poly("pua_3", [(410, 222), (446, 152), (478, 232)], C["naranja"]),
        rect("pata_1", 300, 378, 72, 92, C["verde_oscuro"], 26), rect("pata_2", 440, 378, 72, 92, C["verde_oscuro"], 26),
        eli("cuerpo", 390, 320, 152, 100, V), eli("panza", 404, 352, 96, 58, C["amarillo"]),
        poly("cuello", [(466, 300), (498, 202), (560, 190), (566, 300)], V, 1),
        eli("cabeza", 586, 214, 118, 78, V, giro=-8),
        eli("brazito", 522, 332, 22, 38, V, giro=-30),
    ], [ojo(616, 184, 20), sonrisa(640, 232, 28), rubor(598, 242, 16), punto(684, 198, 5)],
        voz("laminas/dino", "¡Un dinosaurio de colores! ¡Grrr!"), ["dino"])

def auto_amigo():
    return lam("auto", [
        fondo_liso("#E9F7FF"), fija(rect("camino", 0, 452, W, 78), "#8A8FA3"),
        poly("cabina", [(250, 252), (330, 142), (520, 142), (600, 252)], C["rojo"], 1),
        rect("carroceria", 120, 240, 600, 160, C["rojo"], 50),
        poly("ventana_1", [(290, 240), (345, 162), (415, 162), (415, 240)], C["celeste"]),
        poly("ventana_2", [(435, 240), (435, 162), (505, 162), (560, 240)], C["celeste"]),
        circ("rueda_1", 262, 408, 64, C["negro"]), circ("tapa_1", 262, 408, 28, C["gris"]),
        circ("rueda_2", 580, 408, 64, C["negro"]), circ("tapa_2", 580, 408, 28, C["gris"]),
        eli("luz", 702, 292, 22, 28, C["amarillo"]),
    ], [linea([(40, 492), (140, 492)], 6, color="#FFFFFF"), linea([(360, 492), (460, 492)], 6, color="#FFFFFF"),
        linea([(680, 492), (780, 492)], 6, color="#FFFFFF"), sonrisa(680, 340, 22)],
        voz("laminas/auto", "¡Un autito de colores! ¡Brum brum!"), ["auto"])

def pradera():
    R = [fija(rect("cielo", 0, 0, W, H), "#BFE8FF"), fija(circ("sol", 724, 82, 52), "#FFD23F"),
         fija(nube("nube_1", 170, 92), "#FFFFFF"), fija(nube("nube_2", 470, 72, 0.7), "#FFFFFF"),
         fija(poly("colinas", [(0, 330), (200, 270), (420, 310), (640, 258), (824, 300), (824, 530), (0, 530)], None, 2), "#8FD98A"),
         fija(poly("pasto", [(0, 400), (260, 380), (520, 402), (824, 386), (824, 530), (0, 530)], None, 2), "#5CC95F"),
         fija(poly("camino", [(0, 470), (824, 440), (824, 500), (0, 530)]), "#E8D3A6"),
         fija(fig("flor_1", "flor", 90, 420, 20), "#FF7EB6"), fija(fig("flor_2", "flor", 700, 416, 18), "#FFD23F"),
         fija(fig("flor_3", "flor", 380, 418, 16), "#B48CE8")]
    return lam("pradera", R, [ojo(708, 76, 8), ojo(740, 76, 8), sonrisa(724, 92, 14)])

def valle_dinos():
    R = [fija(rect("cielo", 0, 0, W, H), "#FFE3C4"), fija(circ("sol", 120, 90, 50), "#FF9A2E"),
         fija(poly("volcan", [(510, 340), (618, 150), (682, 150), (790, 340)]), "#B07A55"),
         fija(poly("lava", [(618, 152), (682, 152), (672, 200), (656, 176), (640, 206), (628, 180)]), "#FF6B3D"),
         fija(eli("humo", 650, 110, 46, 30), "#F4F0FF"),
         fija(poly("suelo", [(0, 350), (200, 330), (420, 352), (640, 332), (824, 346), (824, 530), (0, 530)], None, 2), "#C9E59A"),
         fija(eli("lago", 210, 452, 150, 40), "#8ED3FF"),
         fija(rect("tronco", 60, 220, 22, 150, None, 10), "#9A6238"),
         fija(poly("hojas", [(71, 222), (0, 250), (30, 210), (71, 200), (120, 190), (150, 230), (100, 215)], None, 1), "#4CBF56"),
         fija(rect("tronco_2", 440, 250, 18, 110, None, 9), "#9A6238"),
         fija(poly("hojas_2", [(449, 252), (390, 270), (412, 236), (449, 228), (492, 222), (512, 258), (470, 244)], None, 1), "#4CBF56")]
    return lam("valle_dinos", R, [])

# --- Ala de la nave (los tres)
def ala():
    A, B, Cq, D = (110, 372), (236, 170), (772, 128), (706, 328)
    def lerp(p, q, t): return (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)
    cx = sum(p[0] for p in (A, B, Cq, D)) / 4; cy = sum(p[1] for p in (A, B, Cq, D)) / 4
    borde = [((p[0] - cx) * 1.1 + cx, (p[1] - cy) * 1.16 + cy) for p in (A, B, Cq, D)]
    regiones = [fija(rect("espacio", 0, 0, W, H), "#1F2350")]
    for i, (x, y, r) in enumerate([(60, 60, 12), (300, 50, 9), (520, 40, 14), (780, 330, 10), (160, 470, 12), (420, 470, 9), (700, 460, 13), (40, 250, 8)]):
        regiones.append(fija(fig("estrellita_%d" % i, "estrella", x, y, r), "#FFF3B0"))
    regiones += [
        fija(eli("nave", -30, 520, 230, 160), "#BFE8D8"), fija(circ("ventanilla", 100, 430, 42), "#8ED3FF"),
        poly("borde", borde, C["amarillo"], 1),
    ]
    colores = [C["blanco"], C["rosa"], C["celeste"], C["blanco"]]
    for i in range(4):
        t0, t1 = i / 4, (i + 1) / 4
        regiones.append(poly("franja_%d" % (i + 1), [lerp(A, B, t0), lerp(A, B, t1), lerp(D, Cq, t1), lerp(D, Cq, t0)], colores[i]))
    regiones += [fig("estrella", "estrella", 470, 246, 58, C["azul"], giro=-8),
                 circ("luz_1", 150, 372, 16, C["rojo"]), circ("luz_2", 752, 132, 16, C["verde"])]
    return lam("ala", regiones, [], voz("laminas/ala", "¡Qué ala tan linda! ¡La nave va a quedar preciosa!"), ["nave"])

# --- Viste a Coco (Nicole)
def coco_traje():
    L = C["lila"]
    base = [fija(rect("fondo", 0, 0, W, H), "#FFE3F1"), fija(rect("piso", 0, 470, W, 60), "#F7C6DC"),
            fija(poly("cola", [(540, 420), (622, 410), (672, 360), (662, 298), (626, 300), (632, 350), (600, 380), (545, 385)], None, 2), L),
            fija(eli("pie_1", 345, 480, 60, 30), L), fija(eli("pie_2", 479, 480, 60, 30), L),
            fija(eli("cuerpo", 412, 375, 150, 118), L), fija(eli("panza", 412, 395, 92, 82), "#FFE9C2"),
            fija(eli("brazo_1", 268, 352, 42, 64, giro=28), L), fija(eli("brazo_2", 556, 352, 42, 64, giro=-28), L),
            fija(poly("cresta", [(350, 112), (362, 42), (412, 8), (466, 30), (482, 104)], None, 2), "#FF9ECF"),
            fija(eli("cabeza", 412, 190, 152, 106), L)]
    cara = [ojo(352, 186, 26), ojo(472, 186, 26), rubor(318, 228, 26), rubor(506, 228, 26), sonrisa(412, 226, 34), punto(398, 206, 4), punto(426, 206, 4)]
    trajes = {
        "princesa": {"voz": voz("brote/traje_princesa", "¡Traje de princesa!"), "regiones": [
            poly("vestido", [(322, 300), (502, 300), (566, 470), (258, 470)], C["rosa"], 1),
            rect("cinta", 318, 300, 188, 30, C["blanco"], 14),
            poly("corona", [(342, 98), (360, 40), (388, 80), (412, 22), (436, 80), (464, 40), (482, 98)], C["amarillo"]),
            circ("joya", 412, 78, 11, C["turquesa"]),
            eli("zapato_1", 345, 484, 62, 28, C["violeta"]), eli("zapato_2", 479, 484, 62, 28, C["violeta"]),
            fig("varita", "estrella", 604, 250, 30, C["amarillo"])],
            "detalles": [linea([(566, 348), (596, 272)], 5)]},
        "idol": {"voz": voz("brote/traje_idol", "¡Traje de estrella del pop!"), "regiones": [
            poly("chaqueta_1", [(292, 296), (408, 296), (408, 438), (280, 438)], C["violeta"]),
            poly("chaqueta_2", [(416, 296), (532, 296), (544, 438), (416, 438)], C["violeta"]),
            poly("falda", [(296, 430), (528, 430), (566, 480), (258, 480)], C["rosa"]),
            poly("gorra", [(300, 118), (330, 70), (412, 52), (494, 70), (524, 118)], C["turquesa"], 1),
            eli("bota_1", 345, 486, 66, 30, C["blanco"]), eli("bota_2", 479, 486, 66, 30, C["blanco"]),
            circ("microfono", 612, 252, 24, C["gris"])],
            "detalles": [linea([(566, 350), (604, 272)], 7)]},
        "heroina": {"voz": voz("brote/traje_heroina", "¡Traje de superheroína!"), "regiones_atras": [
            poly("capa", [(292, 290), (532, 290), (612, 500), (212, 500)], C["rojo"], 1)], "regiones": [
            poly("antifaz", [(296, 160), (412, 146), (528, 160), (524, 216), (412, 204), (300, 216)], C["azul"], 1),
            rect("cinturon", 268, 384, 288, 30, C["amarillo"], 14),
            fig("emblema", "estrella", 412, 330, 34, C["amarillo"]),
            eli("bota_1", 345, 486, 66, 30, C["azul"]), eli("bota_2", 479, 486, 66, 30, C["azul"])]},
    }
    return {"id": "coco_traje", "tipo": "zonas", "regiones": base, "detalles": cara, "trajes": trajes,
            "orden_trajes": ["princesa", "idol", "heroina"], "caja_mini": [190, 0, 444, 530],
            "voz": voz("laminas/coco_traje", "¡Qué traje tan lindo! Lo voy a usar en mi planeta.")}


# ---------------------------------------------------------------- guias (espejo y mandala)
def guia(id, regiones, detalles=(), alfa=0.4):
    return {"id": id, "tipo": "guia", "alfa": alfa, "regiones": [fija(r, r.get("sugerido", "#FFFFFF")) if "sugerido" in r else fija(r, "#FFFFFF") for r in regiones], "detalles": list(detalles)}

def g(r, color):
    r["sugerido"] = color
    return r

def espejos():
    X = 412
    flor = guia("flor", [g(rect("tallo", X - 8, 300, 16, 210, None, 8), "#A6E3A1"),
                         g(eli("hoja_1", X - 70, 420, 64, 26, giro=-25), "#A6E3A1"), g(eli("hoja_2", X + 70, 420, 64, 26, giro=25), "#A6E3A1")] +
                [g(eli("petalo_%d" % i, X + math.cos(a) * 92, 200 + math.sin(a) * 92, 62, 44, giro=math.degrees(a)), "#FFD1E8")
                 for i, a in enumerate([math.tau * k / 8 for k in range(8)])] + [g(circ("centro", X, 200, 58), "#FFEBA0")])
    corona = guia("corona", [g(poly("corona", [(172, 420), (192, 150), (292, 290), (X, 90), (532, 290), (632, 150), (652, 420)]), "#FFEBA0"),
                             g(rect("base", 162, 400, 500, 70, None, 20), "#FFD1E8"),
                             g(fig("joya_1", "corazon", X, 330, 44), "#FFB3C7"), g(circ("joya_2", 262, 350, 26), "#C7A6EC"), g(circ("joya_3", 562, 350, 26), "#C7A6EC"),
                             g(circ("punta_1", 192, 140, 20), "#FFB3C7"), g(circ("punta_2", X, 80, 22), "#FFB3C7"), g(circ("punta_3", 632, 140, 20), "#FFB3C7")])
    gato = guia("gatito_cara", [g(poly("oreja_1", [(232, 210), (250, 50), (352, 150)]), "#FFD9B0"), g(poly("oreja_2", [(592, 210), (574, 50), (472, 150)]), "#FFD9B0"),
                                g(eli("cara", X, 290, 210, 170), "#FFD9B0"), g(eli("hocico", X, 350, 70, 46), "#FFFFFF")],
                [ojo(330, 270, 26), ojo(494, 270, 26), punto(X, 330, 10, "#FF7EB6"), sonrisa(X, 342, 20),
                 linea([(350, 350), (220, 330)], 3), linea([(474, 350), (604, 330)], 3), linea([(350, 366), (224, 382)], 3), linea([(474, 366), (600, 382)], 3)])
    corazon = guia("corazon_alado", [g(eli("ala_1", X - 190, 230, 150, 80, giro=-20), "#D6F1FF"), g(eli("ala_2", X + 190, 230, 150, 80, giro=20), "#D6F1FF"),
                                     g(eli("ala_3", X - 170, 320, 110, 56, giro=10), "#D6F1FF"), g(eli("ala_4", X + 170, 320, 110, 56, giro=-10), "#D6F1FF"),
                                     g(fig("corazon", "corazon", X, 270, 170), "#FFD1E8")])
    mono = guia("mono", [g(poly("cinta_1", [(X - 20, 300), (X - 120, 500), (X - 60, 480), (X - 30, 520), (X, 320)]), "#FFB3C7"),
                         g(poly("cinta_2", [(X + 20, 300), (X + 120, 500), (X + 60, 480), (X + 30, 520), (X, 320)]), "#FFB3C7"),
                         g(poly("lazo_1", [(X, 250), (X - 260, 110), (X - 300, 250), (X - 260, 390)], None, 2), "#FFD1E8"),
                         g(poly("lazo_2", [(X, 250), (X + 260, 110), (X + 300, 250), (X + 260, 390)], None, 2), "#FFD1E8"),
                         g(eli("nudo", X, 250, 60, 70), "#FF9ECF")])
    return [flor, corona, gato, corazon, mono]

def mandalas():
    cx, cy = W / 2, H / 2
    flor = []
    for k in range(12):
        a = math.tau * k / 12
        flor.append(g(eli("petalo_ext_%d" % k, cx + math.cos(a) * 200, cy + math.sin(a) * 200, 52, 26, giro=math.degrees(a)), "#FFD1E8"))
    for k in range(6):
        a = math.tau * k / 6 + math.pi / 6
        flor.append(g(eli("petalo_%d" % k, cx + math.cos(a) * 110, cy + math.sin(a) * 110, 72, 38, giro=math.degrees(a)), "#D6F1FF"))
    flor.append(g(circ("centro", cx, cy, 60), "#FFEBA0"))
    estrella = [g(circ("aro", cx, cy, 250), "#F1E6FF")]
    for k in range(2):
        pts = [(cx + math.cos(math.tau * i / 3 + k * math.pi / 3 - math.pi / 2) * 230, cy + math.sin(math.tau * i / 3 + k * math.pi / 3 - math.pi / 2) * 230) for i in range(3)]
        estrella.append(g(poly("triangulo_%d" % k, pts), "#FFE3F1" if k else "#D6F1FF"))
    estrella.append(g(circ("centro", cx, cy, 86), "#FFEBA0"))
    for k in range(6):
        a = math.tau * k / 6 - math.pi / 2
        estrella.append(g(circ("gema_%d" % k, cx + math.cos(a) * 160, cy + math.sin(a) * 160, 22), "#C7F2EE"))
    copo_det = []
    for k in range(6):
        a = math.tau * k / 6
        d = (math.cos(a), math.sin(a))
        copo_det.append(linea([(cx, cy), (cx + d[0] * 250, cy + d[1] * 250)], 5, color="#9AC8E8"))
        for r, l in [(120, 50), (190, 40)]:
            p = (cx + d[0] * r, cy + d[1] * r)
            for s in (-1, 1):
                b = a + s * math.pi / 4
                copo_det.append(linea([p, (p[0] + math.cos(b) * l, p[1] + math.sin(b) * l)], 5, color="#9AC8E8"))
    copo = [g(circ("aro", cx, cy, 250), "#EEF7FF"), g(fig("centro", "estrella", cx, cy, 60), "#D6F1FF")]
    return [guia("mandala_flor", flor, alfa=0.45), guia("mandala_estrella", estrella, alfa=0.45), guia("mandala_copo", copo, copo_det, alfa=0.5)]


# ---------------------------------------------------------------- mosaicos (Sofia)
def mosaico(id, colores, celdas, nombre, dato, etiquetas):
    assert len(celdas) == 12 and all(len(f) == 18 for f in celdas), id
    usados = set("".join(celdas))
    assert usados == set(colores), (id, usados, colores.keys())
    return {"id": id, "tipo": "mosaico", "colores": colores, "celdas": celdas, "lado_maximo": 44,
            "voz": voz("laminas/%s" % id, nombre), "voz_dato": voz("datos/%s" % id, dato), "etiquetas": etiquetas}

def grilla(func):
    return ["".join(func(x, y) for x in range(18)) for y in range(12)]

def mosaicos():
    M = []
    estrella = ["111111", "112211", "122221", "112211", "121121", "111111"]
    M.append(mosaico("m_chile", {"1": "#0039A6", "2": "#FFFFFF", "3": "#D52B1E"},
                     grilla(lambda x, y: (estrella[y][x] if x < 6 else "2") if y < 6 else "3"),
                     "¡Es la bandera de Chile!", "La estrella blanca se llama la estrella solitaria. El azul es el cielo, el blanco la nieve de la cordillera y el rojo, el corazón valiente de los héroes.", ["chile", "bandera"]))
    M.append(mosaico("m_japon", {"1": "#FFFFFF", "2": "#BC002D"},
                     grilla(lambda x, y: "2" if math.hypot(x + 0.5 - 9, y + 0.5 - 6) <= 3.4 else "1"),
                     "¡Es la bandera de Japón!", "Japón es un país de islas, al otro lado del océano Pacífico. Su bandera es un sol rojo: le dicen el país del sol naciente.", ["mundo", "bandera"]))
    M.append(mosaico("m_italia", {"1": "#009246", "2": "#FFFFFF", "3": "#CE2B37"},
                     grilla(lambda x, y: "1" if x < 6 else ("2" if x < 12 else "3")),
                     "¡Es la bandera de Italia!", "Italia tiene forma de bota. ¡Ahí nacieron la pizza y los tallarines!", ["mundo", "bandera"]))
    M.append(mosaico("m_francia", {"1": "#002395", "2": "#FFFFFF", "3": "#ED2939"},
                     grilla(lambda x, y: "1" if x < 6 else ("2" if x < 12 else "3")),
                     "¡Es la bandera de Francia!", "En Francia está la torre Eiffel, en la ciudad de París.", ["mundo", "bandera"]))
    M.append(mosaico("m_peru", {"1": "#D91023", "2": "#FFFFFF"},
                     grilla(lambda x, y: "2" if 6 <= x < 12 else "1"),
                     "¡Es la bandera de Perú!", "Perú es vecino de Chile, por el norte. Allá está Machu Picchu, una ciudad antigua en la cima de una montaña.", ["mundo", "bandera"]))
    M.append(mosaico("m_alemania", {"1": "#1C1C1C", "2": "#DD0000", "3": "#FFCE00"},
                     grilla(lambda x, y: "1" if y < 4 else ("2" if y < 8 else "3")),
                     "¡Es la bandera de Alemania!", "Alemania está en Europa y tiene castillos que parecen de cuento.", ["mundo", "bandera"]))
    M.append(mosaico("m_colombia", {"1": "#FCD116", "2": "#003893", "3": "#CE1126"},
                     grilla(lambda x, y: "1" if y < 6 else ("2" if y < 9 else "3")),
                     "¡Es la bandera de Colombia!", "Colombia tiene playas en dos océanos, montañas altísimas y muchísimas flores.", ["mundo", "bandera"]))
    M.append(mosaico("m_suecia", {"1": "#006AA7", "2": "#FECC00"},
                     grilla(lambda x, y: "2" if (5 <= x <= 6 or 5 <= y <= 6) else "1"),
                     "¡Es la bandera de Suecia!", "Suecia está muy al norte. En invierno el sol casi no sale, y a veces se ven auroras de colores en el cielo.", ["mundo", "bandera"]))
    sol_arg = {(8, 5), (9, 5), (8, 6), (9, 6)}
    M.append(mosaico("m_argentina", {"1": "#74ACDF", "2": "#FFFFFF", "3": "#F6B40E"},
                     grilla(lambda x, y: "1" if (y < 4 or y >= 8) else ("3" if (x, y) in sol_arg else "2")),
                     "¡Es la bandera de Argentina!", "Argentina es vecina de Chile: la cordillera de los Andes está entre los dos países. ¿Viste el sol del centro?", ["mundo", "bandera"]))
    def brasil(x, y):
        cx, cy = x + 0.5, y + 0.5
        if math.hypot(cx - 9, cy - 6) <= 2.5: return "3"
        if abs(cx - 9) / 8.2 + abs(cy - 6) / 5.2 <= 1: return "2"
        return "1"
    M.append(mosaico("m_brasil", {"1": "#009C3B", "2": "#FFDF00", "3": "#002776"}, grilla(brasil),
                     "¡Es la bandera de Brasil!", "Brasil es el país más grande de Sudamérica. Ahí está la selva del Amazonas.", ["mundo", "bandera"]))
    # Lugares de Chile (pixel art 18x12)
    M.append(mosaico("m_morro_arica", {"1": "#8ED3FF", "2": "#3470D8", "3": "#A0663A", "4": "#F2C57C", "5": "#D52B1E", "6": "#FFFFFF", "7": "#0039A6"}, [
        "111111111111111111",
        "111111111376611111",
        "111111111355511111",
        "111111111311111111",
        "111111111311111111",
        "111113333333333111",
        "111133333333333311",
        "111333333333333331",
        "113333333333333333",
        "223333333333333444",
        "262333333333334444",
        "222233333333344444"],
        "¡Es el Morro de Arica!", "El Morro está en Arica, la ciudad más al norte de Chile. Es un cerro gigante junto al mar, con una bandera enorme arriba.", ["chile", "lugar"]))
    M.append(mosaico("m_torres_paine", {"1": "#8ED3FF", "2": "#9AA0B0", "3": "#FFFFFF", "4": "#5B4F63", "5": "#2EC4B6", "6": "#E3C565"}, [
        "111111111111111111",
        "111111111331111111",
        "111111331221331111",
        "111111221221221111",
        "111111221221221111",
        "111111221221221111",
        "111134444444444311",
        "113444444444444441",
        "344444444444444444",
        "555555555555555555",
        "555555555555555555",
        "666666666666666666"],
        "¡Son las Torres del Paine!", "Están en la Patagonia, en el sur de Chile. Son tres torres de granito, y abajo hay lagos de color turquesa.", ["chile", "lugar"]))
    M.append(mosaico("m_volcan_osorno", {"1": "#8ED3FF", "2": "#FFFFFF", "3": "#5B6B8C", "4": "#2E8B57", "5": "#3470D8"}, [
        "111111111111111111",
        "111111112211111111",
        "111111122221111111",
        "111111222222111111",
        "111112222222211111",
        "111123232323321111",
        "111333333333333111",
        "113333333333333311",
        "443333333333333344",
        "444444444444444444",
        "555555555555555555",
        "555555555555555555"],
        "¡Es el volcán Osorno!", "Está en el sur de Chile, junto al lago Llanquihue. Tiene la punta siempre nevada, como un helado.", ["chile", "lugar"]))
    M.append(mosaico("m_moai", {"1": "#8ED3FF", "2": "#8C7B6B", "3": "#4E4038", "4": "#4CBF56", "5": "#3470D8", "6": "#B5553A"}, [
        "111111111111111111",
        "111111166661111111",
        "111111222222111111",
        "111111333333111111",
        "111112232232211111",
        "111112222222211111",
        "111112223322211111",
        "111111223322111111",
        "555555222222555555",
        "555555233332555555",
        "444442222222244444",
        "444422222222224444"],
        "¡Es un moái de Rapa Nui!", "Rapa Nui es la Isla de Pascua, una isla chilena en medio del océano. Los moáis son estatuas gigantes de piedra hechas hace cientos de años.", ["chile", "lugar"]))
    M.append(mosaico("m_la_moneda", {"1": "#8ED3FF", "2": "#F1E4C8", "3": "#3A4A6B", "4": "#D52B1E", "5": "#0039A6", "6": "#FFFFFF", "7": "#B8BCC8"}, [
        "111111113561111111",
        "111111113441111111",
        "111111113111111111",
        "111111222222211111",
        "122222222222222221",
        "123232322222323221",
        "122222222222222221",
        "123232323323232321",
        "123232323323232321",
        "122222222222222221",
        "777777777777777777",
        "777777777777777777"],
        "¡Es el Palacio de La Moneda!", "Está en Santiago, la capital de Chile. Ahí trabaja el presidente.", ["chile", "lugar"]))
    M.append(mosaico("m_valparaiso", {"1": "#8ED3FF", "2": "#3470D8", "3": "#4CBF56", "4": "#FFD23F", "5": "#FF7EB6", "6": "#2EC4B6", "7": "#EE4035"}, [
        "111111111111111111",
        "111111111111111777",
        "111111111111111444",
        "111111111111777444",
        "111111111111555333",
        "111111111777555333",
        "111111777666333333",
        "111111444666333333",
        "111777444333333333",
        "333555333333333333",
        "222222222222222222",
        "222222222222222222"],
        "¡Son los cerros de Valparaíso!", "Valparaíso es una ciudad puerto con casas de muchos colores y ascensores que suben los cerros.", ["chile", "lugar"]))
    return M


# ---------------------------------------------------------------- voces comunes
COLORES_VOZ = {
    "rojo": "¡Rojo, como una frutilla!", "naranja": "¡Naranja, como una mandarina!", "amarillo": "¡Amarillo, como el sol!",
    "verde": "¡Verde, como el pasto!", "azul": "¡Azul, como el mar!", "violeta": "¡Violeta, como una uva!",
    "rosa": "¡Rosado, como un algodón de azúcar!", "turquesa": "¡Turquesa, como una laguna mágica!", "blanco": "¡Blanco, como una nube!",
    "negro": "¡Negro, como la noche!", "cafe": "¡Café, como el chocolate!", "celeste": "¡Celeste, como el cielo!",
    "gris": "¡Gris, como una roca!", "verde_oscuro": "¡Verde oscuro, como un bosque!", "rosado": "¡Rosadito, como un chicle!",
    "lila": "¡Lila, como una lavanda!", "verde_claro": "¡Verde clarito, como la menta!", "amarillo_claro": "¡Amarillo clarito, como la vainilla!",
}
for k, t in COLORES_VOZ.items():
    voz("colores/" + k, t)
PEDIDOS = {
    "rojo": "¿Puedes pintar algo de color rojo?", "naranja": "Ahora, ¡pinta algo naranja!", "amarillo": "¿Me pintas algo amarillo?",
    "verde": "¡Busca el verde y pinta algo!", "azul": "¿Qué tal algo de color azul?", "violeta": "Ahora quiero ver algo violeta.",
    "rosa": "¡Pinta algo rosado, mi color favorito!", "turquesa": "¿Encuentras el turquesa? ¡Pinta algo con él!",
    "celeste": "Ahora, algo celeste, como el cielo.", "cafe": "¿Me pintas algo café?",
}
LOGRADO = {
    "rojo": "¡Siii, rojo! ¡Muy bien!", "naranja": "¡Naranja! ¡Perfecto!", "amarillo": "¡Amarillo! ¡Lo encontraste!",
    "verde": "¡Verde! ¡Bravo!", "azul": "¡Azul! ¡Qué bien escuchas!", "violeta": "¡Violeta! ¡Precioso!",
    "rosa": "¡Rosado! ¡Me encanta!", "turquesa": "¡Turquesa! ¡Lo lograste!", "celeste": "¡Celeste! ¡Muy bien!", "cafe": "¡Café! ¡Genial!",
}
for k in PEDIDOS:
    voz("pedidos/" + k, PEDIDOS[k]); voz("logrado/" + k, LOGRADO[k])
PEDIDOS_MEZCLA = {
    "verde": "¿Puedes preparar verde en tu platito?", "naranja": "Ahora, prepara naranja.", "violeta": "¿Te atreves con el violeta?",
    "rosado": "Quiero un rosado clarito. ¿Cómo lo harías?", "celeste": "¿Puedes hacer celeste?", "cafe": "Un desafío: ¡prepara café!",
    "lila": "El más difícil: ¡color lila!",
}
MEZCLAS = {
    "verde": "¡Verde! Azul con amarillo.", "naranja": "¡Naranja! Rojo con amarillo.", "violeta": "¡Violeta! Rojo con azul.",
    "cafe": "¡Café! Los tres colores juntos.", "rosado": "¡Rosado! Rojo con blanco.", "celeste": "¡Celeste! Azul con blanco.",
    "lila": "¡Lila! Violeta con blanco.", "verde_claro": "¡Verde clarito! Verde con blanco.", "amarillo_claro": "¡Amarillo clarito! Amarillo con blanco.",
    "gris": "¡Gris! Café con blanco.",
}
for k, t in PEDIDOS_MEZCLA.items():
    voz("pedidos_mezcla/" + k, t)
for k, t in MEZCLAS.items():
    voz("mezclas/" + k, t)

V_ARCOIRIS = [voz("comun/arcoiris_01", "¡Muchos colores! ¡Mi cresta se volvió arcoíris!"), voz("comun/arcoiris_02", "¡Wow! ¡Soy una camaleona arcoíris!")]
V_ESTRELLA = voz("comun/uso_pincel_estrella", "¡Estrellitas! ¡Qué brillo!")
V_DINO = voz("comun/uso_sello_dino", "¡Un dinosaurio! ¡Grrr!")
V_AUTO = voz("comun/uso_sello_auto", "¡Brum, brum! ¡Un autito!")
V_SELLO_ESTRELLA = voz("comun/uso_sello_estrella", "¡Una estrella brillante!")
V_DINO_CAMINA = [voz("comun/dino_camina_01", "¡Jajaja! ¡Los dinos se fueron de paseo!"), voz("comun/dino_camina_02", "¡Miren! ¡Los dinosaurios caminan!")]

PERFILES = {
    "semilla": {"nombre": "Maxi", "hermano": "maxi"},
    "brote": {"nombre": "Nicole", "hermano": "nicole"},
    "estrella": {"nombre": "Sofía", "hermano": "sofia"},
}

def voces_perfil(perfil):
    n = PERFILES[perfil]["nombre"]
    p = perfil + "/"
    if perfil == "semilla":
        mostrar = [voz(p + "mostrar_01", "¡Wow, Maxi! ¡Qué lindo!"), voz(p + "mostrar_02", "¡Me encanta! ¡Está precioso!"), voz(p + "mostrar_03", "¡Bravo, Maxi! ¡Qué colores!")]
        victoria = [voz(p + "victoria_01", "¡Eres un gran pintor, Maxi!"), voz(p + "victoria_02", "¡Siii! ¡Qué obra de arte!")]
    elif perfil == "brote":
        mostrar = [voz(p + "mostrar_01", "¡Ooh, Nicole! ¡Qué hermoso!"), voz(p + "mostrar_02", "¡Me encanta! ¡Tienes mucha imaginación!"), voz(p + "mostrar_03", "¡Qué colores tan lindos! Gracias por mostrármelo.")]
        victoria = [voz(p + "victoria_01", "¡Eres una artista, Nicole!"), voz(p + "victoria_02", "¡Qué obra tan linda! ¡Bravo!")]
    else:
        mostrar = [voz(p + "mostrar_01", "¡Wow, Sofía! ¡Es precioso!"), voz(p + "mostrar_02", "¡Qué obra de arte! Me encanta cómo combinaste los colores."), voz(p + "mostrar_03", "¡Increíble, Sofía! Lo voy a guardar en mi galería.")]
        victoria = [voz(p + "victoria_01", "¡Eres una gran artista, Sofía!"), voz(p + "victoria_02", "¡Bravo, Sofía! ¡Qué talento!")]
    comunes = {
        "mostrar": mostrar, "victoria_final": victoria, "arcoiris": V_ARCOIRIS,
        "lamina_completa": [voz("comun/lamina_completa_01", "¡Lo pintaste todo! ¿Me lo muestras? Toca mi carita."), voz("comun/lamina_completa_02", "¡Terminado! ¡Muéstramelo!")],
        "uso_pincel_estrella": V_ESTRELLA, "uso_sello_estrella": V_SELLO_ESTRELLA,
    }
    if perfil == "semilla":
        comunes["muestramelo"] = [voz(p + "muestramelo_01", "¿Me muestras tu dibujo? ¡Toca mi carita!"), voz(p + "muestramelo_02", "¡Qué lindo! Toca mi carita para mostrármelo.")]
        # disenador-niveles HE-40 #11 + guionista 02-Oct-2026: si Maxi sigue pintando ~90 s con el boton ya
        # a la vista, Coco pregunta una vez por hoja (sin auto-mostrar: el nino decide cuando).
        comunes["me_lo_muestras"] = [voz(p + "me_lo_muestras_01", "¡Maxi! ¿Me lo muestras? ¡Toca mi carita!"), voz(p + "me_lo_muestras_02", "¡Ooh, qué colores! ¿Me lo muestras, Maxi? ¡Toca mi carita!")]
        comunes.update({"uso_sello_dino": V_DINO, "uso_sello_auto": V_AUTO, "dino_camina": V_DINO_CAMINA})
    if perfil == "brote":
        comunes["uso_pincel_corazon"] = voz(p + "uso_corazon", "¡Corazones! Te hago un corazón, Nicole.")
        comunes["uso_sello_corazon"] = comunes["uso_pincel_corazon"]
        comunes["igualita"] = [voz(p + "igualita_01", "¡Igualito al modelo! ¡Qué buena vista!")]
    if perfil == "estrella":
        comunes["uso_purpurina"] = voz(p + "uso_purpurina", "¡Purpurina! Todo brilla. Si la dejas quieta, pasa algo mágico.")
        comunes["uso_purpurina_lluvia"] = voz(p + "uso_purpurina_lluvia", "¡Lluvia de destellos dorados!")
        comunes["uso_sello_pony"] = voz(p + "uso_pony", "¡Tu insignia de pony! Te queda perfecta.")
        comunes["uso_sello_luna"] = voz(p + "uso_luna", "¡Una luna dormilona!")
        comunes["uso_sello_destello"] = voz(p + "uso_destello", "¡Destellos! ¡Brilla, brilla!")
    return comunes


# ---------------------------------------------------------------- lienzo con tema (zona 1)
# Cada hoja es un tema con fondo, stickers (scripts/motores/lienzo_libre/stickers.gd) y un
# conector que un viajero recorre. Maxi recibe el tema; Nicole elige entre 2 y Sofia entre 3.
PREF_STICKERS = "voces/arcoiris/pinta/stickers/%s.wav"

NOMBRES_STICKERS = {
    "trex": "¡Un tiranosaurio rex! ¡Grrr!", "spinosaurio": "¡Un espinosaurio, con su vela en la espalda!",
    "carnotauro": "¡Un carnotauro, con sus cuernitos!", "huevo": "¡Un huevo de dinosaurio! ¿Qué habrá adentro?",
    "carrito": "¡Un auto de carreras! ¡Brum, brum!", "bus": "¡Un bus! ¡Todos a bordo!",
    "bomberos": "¡El camión de bomberos! ¡Iu, iu, iu!", "cohete": "¡Un cohete! ¡Tres, dos, uno, despegue!",
    "palmera": "¡Una palmera!", "volcan": "¡Un volcán! En Chile hay muchísimos.", "bandera_meta": "¡La bandera de la meta!",
    "cono": "¡Un cono naranjo!", "casa": "¡Una casita!", "fuego": "¡Fuego! ¡Llamen a los bomberos!", "arbol": "¡Un árbol!",
    "planeta": "¡Un planeta con anillos!", "pony_amigo": "¡Un pony!", "jirafa": "¡Una jirafa, con su cuello larguísimo!",
    "gatito": "¡Un gatito! ¡Miau!", "sol": "¡El sol!", "corona": "¡Una corona de princesa!", "vestido": "¡Un vestido precioso!",
    "zapato": "¡Un zapato de princesa!", "granero": "¡Un granero!", "manzana": "¡Una manzana!", "nube": "¡Una nube!",
    "roca": "¡Una roca!", "castillo": "¡Un castillo!", "carroza": "¡Una carroza mágica!", "ovillo": "¡Un ovillo de lana!",
    "pastel": "¡Un pastel de cumpleaños!", "globo": "¡Un globo!", "regalo": "¡Un regalo!", "microfono": "¡Un micrófono! ¡A cantar!",
    "nota": "¡Una nota musical!", "foco": "¡Un foco de luz!", "sombrero_mago": "¡Un sombrero de mago!",
    "varita": "¡Una varita mágica!", "lechuza": "¡Una lechuza! ¡Uh, uh!", "caldero": "¡Un caldero con poción!",
    "libro": "¡Un libro de hechizos!", "escoba": "¡Una escoba voladora!", "unicornio": "¡Un unicornio!",
    "parlante": "¡Un parlante! ¡Súbele!", "montana": "¡Las Torres del Paine, en la Patagonia!",
    "casa_valpo": "¡Una casita de colores de Valparaíso!", "moai": "¡Un moái de Rapa Nui, la Isla de Pascua!",
    "pinguino": "¡Un pingüino de la Patagonia!", "cactus": "¡Un cactus del desierto de Atacama!",
    "copihue": "¡El copihue, la flor nacional de Chile!", "tren": "¡Un tren! ¡Chu, chu!", "perrito": "¡Un perrito! ¡Guau!",
    "gerbo": "¡Un gerbo, chiquitito y curioso!", "hueso": "¡Un hueso para el perrito!", "pelota": "¡Una pelota!",
    "bandera_chile": "¡La bandera de Chile!", "estrella": "¡Una estrella!", "corazon": "¡Un corazón!", "luna": "¡La luna!",
    "flor": "¡Una flor!", "arcoiris": "¡Un arcoíris!", "destello": "¡Un destello!",
}


def estrellitas(n, x0, x1, y0, y1, r=9, color="#FFF3B0", semilla=7):
    """Estrellitas del cielo repartidas de forma fija (sin azar: el JSON no cambia entre corridas)."""
    regiones = []
    for i in range(n):
        x = x0 + (x1 - x0) * ((i * 0.618 * semilla) % 1.0)
        y = y0 + (y1 - y0) * ((i * 0.382 * semilla + 0.13) % 1.0)
        regiones.append(fig("estrellita_%d" % i, "estrella", round(x), round(y), r, color))
    return regiones

def f_dinos():
    return [rect("cielo", 0, 0, W, H, "#FFE3C4"), circ("sol", 120, 90, 50, "#FF9A2E"),
            poly("volcan", [(520, 330), (628, 140), (692, 140), (800, 330)], "#B07A55"),
            poly("lava", [(628, 142), (692, 142), (682, 190), (666, 166), (650, 196), (638, 170)], "#FF6B3D"),
            poly("suelo", [(0, 320), (200, 300), (420, 322), (640, 302), (824, 316), (824, 530), (0, 530)], "#C9E59A", 2),
            eli("lago", 190, 460, 150, 40, "#8ED3FF")]

def f_pista():
    return [rect("cielo", 0, 0, W, H, "#BFE8FF"), nube("nube_1", 170, 80), nube("nube_2", 560, 60, 0.7),
            poly("montes", [(0, 250), (180, 170), (360, 230), (560, 160), (824, 240), (824, 300), (0, 300)], "#A8D8B0", 2),
            poly("pasto", [(0, 270), (824, 260), (824, 530), (0, 530)], "#7ED36F"),
            rect("gradas", 590, 150, 200, 90, "#FF9FC8", 12)]

def f_ciudad():
    return [rect("cielo", 0, 0, W, H, "#CDEBFF"), circ("sol", 420, 80, 44, "#FFD23F"),
            rect("edificio_1", 30, 140, 120, 280, "#FFD9A0", 8), rect("edificio_2", 610, 100, 100, 320, "#B8C7FF", 8),
            rect("edificio_3", 720, 180, 90, 240, "#FFB3C7", 8), poly("plaza", [(0, 410), (824, 400), (824, 530), (0, 530)], "#C9E59A")]

def f_espacio():
    return ([rect("cielo", 0, 0, W, H, "#232851"), circ("planeta_lejano", 700, 110, 60, "#B48CE8"), circ("luna", 120, 92, 38, "#FFE38A")]
            + estrellitas(9, 200, 620, 30, 300)
            + [poly("suelo", [(0, 430), (220, 400), (480, 426), (824, 404), (824, 530), (0, 530)], "#9AA0B0", 2)])

def f_granja():
    return [rect("cielo", 0, 0, W, H, "#BFE8FF"), circ("sol", 724, 82, 52, "#FFD23F"), nube("nube", 200, 90),
            poly("colinas", [(0, 300), (200, 250), (420, 290), (640, 240), (824, 280), (824, 530), (0, 530)], "#8FD98A", 2),
            poly("pasto", [(0, 380), (260, 360), (520, 382), (824, 366), (824, 530), (0, 530)], "#5CC95F", 2)]

def f_sabana():
    return [rect("cielo", 0, 0, W, H, "#FFE7B0"), circ("sol", 640, 150, 80, "#FF9A2E"),
            poly("montes", [(0, 300), (160, 240), (300, 290), (500, 230), (824, 290), (824, 340), (0, 340)], "#E0B87A", 2),
            poly("pasto", [(0, 320), (824, 310), (824, 530), (0, 530)], "#E9D27A"), eli("charco", 620, 460, 130, 34, "#8ED3FF")]

def f_castillo():
    return [rect("cielo", 0, 0, W, H, "#FFE3F1"), nube("nube_1", 150, 80), nube("nube_2", 650, 110, 0.8),
            poly("colina", [(0, 330), (260, 250), (560, 280), (824, 240), (824, 530), (0, 530)], "#D9C2F0", 2),
            poly("pradera", [(0, 420), (824, 400), (824, 530), (0, 530)], "#BDE8B0")]

def f_living():
    return [rect("pared", 0, 0, W, 380, "#FFF1C9"), rect("ventana", 90, 60, 200, 150, "#BFE8FF", 10),
            rect("cuadro", 560, 70, 150, 110, "#FFB3C7", 8), rect("piso", 0, 380, W, 150, "#E0B48A"),
            eli("alfombra", 412, 455, 300, 55, "#FF9FC8")]

def f_escenario():
    return [rect("fondo", 0, 0, W, H, "#3B2A6B"),
            poly("telon_izq", [(0, 0), (150, 0), (110, 200), (60, 400), (0, 400)], "#F26CA8", 2),
            poly("telon_der", [(824, 0), (674, 0), (714, 200), (764, 400), (824, 400)], "#F26CA8", 2),
            rect("escenario", 0, 400, W, 130, "#9357D6"), rect("borde", 0, 392, W, 16, "#FFCB3D")]

def f_magia():
    return ([rect("cielo", 0, 0, W, H, "#2A2D6B"), circ("luna", 700, 90, 50, "#FFE38A")] + estrellitas(8, 60, 600, 30, 220, 8)
            + [poly("colinas", [(0, 330), (200, 280), (440, 320), (660, 270), (824, 300), (824, 530), (0, 530)], "#3E4A8C", 2),
               eli("lago", 300, 470, 250, 40, "#5B6FD6")])

def f_ponys():
    cx, cy = 412, 330
    bandas = [anillo("arco_%d" % i, cx, cy, 300 - i * 18 - 18, 300 - i * 18, math.pi, math.tau, col)
              for i, col in enumerate(["#FF6B6B", "#FF9F4A", "#FFCB3D", "#7DD87A", "#6FD6E8", "#B48CE8"])]
    return ([rect("cielo", 0, 0, W, H, "#CFF1FF")] + bandas
            + [poly("colinas", [(0, 340), (220, 290), (460, 330), (680, 280), (824, 320), (824, 530), (0, 530)], "#A8E6A1", 2),
               poly("pradera", [(0, 430), (824, 414), (824, 530), (0, 530)], "#7ED36F")])

def f_chile():
    return [rect("cielo", 0, 0, W, H, "#BFE8FF"),
            poly("cordillera", [(420, 300), (520, 150), (600, 230), (690, 110), (770, 210), (824, 170), (824, 330), (420, 330)], "#9AA0B0", 1),
            poly("nieve_1", [(500, 180), (520, 150), (542, 182)], "#FFFFFF"),
            poly("nieve_2", [(666, 146), (690, 110), (714, 146)], "#FFFFFF"),
            poly("valle", [(120, 330), (420, 300), (824, 320), (824, 530), (120, 530)], "#8FD98A", 2),
            poly("mar", [(0, 280), (140, 300), (110, 400), (150, 530), (0, 530)], "#3470D8", 2)]

def f_patio():
    return [rect("cielo", 0, 0, W, H, "#CFF1FF"), circ("sol", 110, 90, 50, "#FFD23F"), nube("nube", 560, 80),
            rect("muro", 0, 250, W, 90, "#FFD9A0"), poly("pasto", [(0, 330), (824, 330), (824, 530), (0, 530)], "#7ED36F")]

FONDOS = {"dinos": f_dinos, "pista": f_pista, "ciudad": f_ciudad, "espacio": f_espacio, "granja": f_granja, "sabana": f_sabana,
          "castillo": f_castillo, "living": f_living, "escenario": f_escenario, "magia": f_magia, "ponys": f_ponys,
          "chile": f_chile, "patio": f_patio}


def fondo_tema(id_tema, clave, perfil):
    """Fondo del tema: parte pintado (`inicial`). Maxi no tiene balde: su fondo queda fijo."""
    regiones = []
    for region in FONDOS[clave]():
        region["inicial"] = region.pop("sugerido")
        if perfil == "semilla":
            region["fija"] = True
        regiones.append(region)
    return {"id": "fondo_" + id_tema, "tipo": "zonas", "regiones": regiones, "detalles": []}


# (id, fondo, stickers, conector {tipo, viajero}, texto de la intro, nombre del tema, linea del conector)
TEMAS = {
    "semilla": [
        ("parque_dinos", "dinos", ["trex", "spinosaurio", "carnotauro"], {"tipo": "sendero", "viajero": "trex"},
         "¡Maxi, hoy dibujamos un parque de dinosaurios! Toca un dino abajo y ponlo en el parque.",
         "¡Parque de dinosaurios!", "¡Un sendero! ¡El dinosaurio sale a pasear!", ["favorito"]),
        ("pista_carreras", "pista", ["carrito", "bus", "bandera_meta"], {"tipo": "camino", "viajero": "carrito"},
         "¡Maxi, hoy dibujamos una pista de carreras! Pon autos y dibuja la pista con tu dedo.",
         "¡Pista de carreras!", "¡Dibuja la pista con tu dedo! ¡El auto va a correr por ahí!", ["favorito"]),
        ("bomberos", "ciudad", ["bomberos", "casa", "fuego"], {"tipo": "camino", "viajero": "bomberos"},
         "¡Maxi, hoy eres bombero! Pon el camión, las casitas y el fuego.",
         "¡Bomberos al rescate!", "¡Una calle! ¡Allá va el camión de bomberos!", []),
        ("espacio", "espacio", ["cohete", "planeta", "estrella"], {"tipo": "estelar", "viajero": "cohete"},
         "¡Maxi, hoy dibujamos el espacio! Pon cohetes, planetas y estrellas.",
         "¡El espacio!", "¡Una ruta de estrellas! ¡El cohete la sigue!", []),
    ],
    "brote": [
        ("granja_ponys", "granja", ["pony_amigo", "granero", "arbol", "manzana", "flor", "sol", "nube", "corazon"],
         {"tipo": "cerca", "viajero": "pony_amigo"},
         "¡Una granja de ponys! Pon ponys, flores y árboles, y une las cosas con la cerca.",
         "¡Granja de ponys!", "¡Una cerca! Une dos cosas y mira cómo pasea el pony.", []),
        ("safari_jirafas", "sabana", ["jirafa", "arbol", "roca", "sol", "nube", "flor", "corazon", "estrella"],
         {"tipo": "sendero", "viajero": "jirafa"},
         "¡Un safari de jirafas! Pon jirafas y árboles, y haz un sendero para que paseen.",
         "¡Safari de jirafas!", "¡Un sendero! La jirafa va a caminar por él.", []),
        ("castillo_princesas", "castillo", ["castillo", "carroza", "corona", "vestido", "zapato", "corazon", "estrella", "arcoiris"],
         {"tipo": "arcoiris", "viajero": "carroza"},
         "¡El castillo de las princesas! Pon el castillo, la carroza y coronas. Une las cosas con un puente arcoíris.",
         "¡Castillo de princesas!", "¡Un puente arcoíris! Une dos cosas y la carroza viajará por él.", []),
        ("fiesta_gatitos", "living", ["gatito", "ovillo", "pastel", "globo", "regalo", "corazon", "estrella", "flor"],
         {"tipo": "guirnalda"},
         "¡Una fiesta de gatitos! Pon gatitos, globos y un pastel, y cuelga guirnaldas de luces.",
         "¡Fiesta de gatitos!", "¡Una guirnalda de luces! Úsala para unir dos cosas.", []),
        ("escenario_pop", "escenario", ["microfono", "nota", "foco", "corazon", "estrella", "corona", "globo", "vestido"],
         {"tipo": "guirnalda"},
         "¡Un escenario de estrellas del pop! Pon micrófonos, focos y notas, y cuelga luces.",
         "¡Escenario de estrellas del pop!", "¡Luces de colores para el escenario! Úsalas para unir dos cosas.", []),
    ],
    "estrella": [
        ("escuela_magia", "magia", ["castillo", "sombrero_mago", "varita", "lechuza", "caldero", "libro", "escoba", "unicornio",
                                     "gatito", "luna", "estrella", "destello", "nube", "arbol"],
         {"tipo": "destellos", "viajero": "escoba"},
         "¡Escuela de magia! Crea tu castillo mágico con lechuzas, calderos y varitas, y une todo con caminos de destellos.",
         "¡Escuela de magia!", "¡Un camino de destellos! La escoba mágica vuela por él.", []),
        ("ciudad_ponys", "ponys", ["pony_amigo", "unicornio", "castillo", "casa", "granero", "arbol", "flor", "manzana",
                                    "arcoiris", "nube", "sol", "corazon", "estrella", "globo", "regalo"],
         {"tipo": "arcoiris", "viajero": "unicornio"},
         "¡La ciudad de los ponys! Construye su pueblo y une las casas con puentes arcoíris.",
         "¡Ciudad de los ponys!", "¡Un puente arcoíris! El unicornio lo va a cruzar.", []),
        ("concierto_pop", "escenario", ["microfono", "nota", "foco", "parlante", "corona", "vestido", "zapato", "corazon",
                                         "estrella", "destello", "globo", "regalo", "luna", "gatito"],
         {"tipo": "guirnalda"},
         "¡Concierto de las estrellas del pop! Arma el escenario más brillante del universo, con focos, parlantes y luces.",
         "¡Concierto pop!", "¡Luces de colores! Cuélgalas entre dos cosas del escenario.", []),
        ("tren_chile", "chile", ["montana", "volcan", "casa_valpo", "moai", "pinguino", "cactus", "copihue", "bandera_chile",
                                  "palmera", "arbol", "casa", "nube", "sol", "estrella"],
         {"tipo": "rieles", "viajero": "tren"},
         "¡El tren por Chile! Pon lugares de Chile y únelos con rieles: el tren va a viajar entre ellos y te dirá dónde llegó.",
         "¡Tren por Chile!", "¡Rieles de tren! Une dos lugares de Chile y el tren viajará entre ellos.", []),
        ("parque_mascotas", "patio", ["perrito", "gatito", "gerbo", "hueso", "pelota", "ovillo", "casa", "arbol", "flor",
                                       "sol", "nube", "corazon", "regalo", "manzana"],
         {"tipo": "sendero", "viajero": "perrito"},
         "¡El parque de las mascotas! Perritos, gatitos y gerbos. Haz senderos para que salgan a pasear.",
         "¡Parque de mascotas!", "¡Un sendero! El perrito sale a pasear por él.", []),
        ("mision_espacial", "espacio", ["cohete", "planeta", "luna", "estrella", "destello", "sol", "roca", "volcan",
                                         "bandera_chile", "gatito", "perrito", "corazon", "arcoiris"],
         {"tipo": "estelar", "viajero": "cohete"},
         "¡Misión espacial! Crea tu propia galaxia con planetas, cohetes y mascotas astronautas, y traza rutas de estrellas.",
         "¡Misión espacial!", "¡Una ruta de estrellas! El cohete viaja por ella.", []),
    ],
}

# Retos de artista de Sofia (opcionales): el del sticker propio de cada tema + dos comunes.
RETOS_STICKER = {
    "escuela_magia": ("lechuza", 3, "Reto de artista: pon tres lechuzas en tu escuela de magia."),
    "ciudad_ponys": ("unicornio", 2, "Reto de artista: pon dos unicornios en la ciudad."),
    "concierto_pop": ("foco", 3, "Reto de artista: ilumina el escenario con tres focos."),
    "tren_chile": ("bandera_chile", 1, "Reto de artista: pon la bandera de Chile."),
    "parque_mascotas": ("perrito", 3, "Reto de artista: pon tres perritos en el parque."),
    "mision_espacial": ("planeta", 3, "Reto de artista: crea tres planetas."),
}
RETOS_EXTRA = {
    "escuela_magia": ("colores", 5), "ciudad_ponys": ("distintos", 8), "concierto_pop": ("colores", 6),
    "tren_chile": ("distintos", 6), "parque_mascotas": ("distintos", 7), "mision_espacial": ("colores", 5),
}
TEXTOS_RETO_EXTRA = {
    ("colores", 5): "Reto de artista: usa cinco colores distintos.", ("colores", 6): "Reto de artista: usa seis colores distintos.",
    ("distintos", 6): "Reto de artista: pon seis stickers distintos.", ("distintos", 7): "Reto de artista: pon siete stickers distintos.",
    ("distintos", 8): "Reto de artista: pon ocho stickers distintos.",
}

HERR_TEMA = {
    "brote": ["pincel", "pincel_corazon", "pincel_estrella", "balde", "goma", "bolsa", "conector"],
    "estrella": ["pincel", "pincel_grueso", "pincel_estrella", "purpurina", "balde", "goma", "bolsa", "conector"],
}
PISTAS_TEMA = {
    "semilla": "Toca un dibujito de abajo y después toca la hoja. ¡Tócalos para que salten!",
    "brote": "Toca la bolsa para elegir stickers. Arrástralos para moverlos, y con el balde les cambias el color. Con el camino unes dos cosas.",
    "estrella": "Toca un sticker para agrandarlo, girarlo o darlo vuelta. El balde les cambia el color, y el conector une dos cosas. Arriba están tus retos.",
}


def temas_de(perfil):
    temas = []
    for id_tema, clave, stickers, conector, intro, nombre, uso, etiquetas in TEMAS[perfil]:
        t = {"id": id_tema, "fondo": fondo_tema(id_tema, clave, perfil), "stickers": stickers, "conector": conector,
             "portada": stickers[:3], "herramienta_inicial": "sello_" + stickers[0],
             "herramientas": (["pincel"] + ["sello_" + s for s in stickers] + ["conector"]) if perfil == "semilla" else HERR_TEMA[perfil],
             "lineas_voz": {"intro": voz("%s/tema_%s" % (perfil, id_tema), intro), "nombre": voz("temas/nombre_" + id_tema, nombre),
                            "uso_conector": voz("temas/conector_" + id_tema, uso),
                            "pista": voz("%s/pista_tema" % perfil, PISTAS_TEMA[perfil])}}
        if etiquetas:
            t["etiquetas"] = etiquetas
        if id_tema == "tren_chile":
            t["nombrar_estaciones"] = True
        if perfil == "estrella":
            sticker, n, texto = RETOS_STICKER[id_tema]
            tipo, n2 = RETOS_EXTRA[id_tema]
            t["retos"] = [
                {"tipo": "stickers", "sticker": sticker, "n": n, "voz": voz("temas/reto_" + id_tema, texto)},
                {"tipo": "conexiones", "n": 2, "voz": voz("temas/reto_conexiones_2", "Reto de artista: une dos pares de cosas con el conector.")},
                {"tipo": tipo, "n": n2, "voz": voz("temas/reto_%s_%d" % (tipo, n2), TEXTOS_RETO_EXTRA[(tipo, n2)])},
            ]
        temas.append(t)
    for s in {s for t in temas for s in t["stickers"]} | {t["conector"].get("viajero", "") for t in temas} - {""}:
        voz("stickers/" + s, NOMBRES_STICKERS[s])
    return temas


def voces_lienzo_tema(perfil):
    lineas = {"conectado": [voz("comun/conectado_01", "¡Los conectaste!"), voz("comun/conectado_02", "¡Unidos! ¡Qué buena idea!")]}
    if perfil == "brote":
        lineas["elige_tema"] = voz("brote/elige_tema", "¿Qué dibujamos hoy, Nicole? ¡Elige uno!")
    if perfil == "estrella":
        lineas["elige_tema"] = voz("estrella/elige_tema", "¿Qué quieres crear hoy, Sofía? Elige tu tema.")
        lineas["reto_cumplido"] = [voz("comun/reto_cumplido_01", "¡Reto cumplido! ¡Qué artista!"), voz("comun/reto_cumplido_02", "¡Lo lograste! Un reto menos.")]
        lineas["retos_todos"] = [voz("estrella/retos_todos", "¡Cumpliste los tres retos! ¡Eres una artista de verdad, Sofía!")]
    return lineas


# ---------------------------------------------------------------- niveles
ZONAS =["zona1_claro", "zona2_charcos", "zona3_chupetines", "zona4_islotes", "zona5_cima"]
PATRONES = {"voces_colores": "voces/arcoiris/pinta/colores/%s.wav"}

def nivel(zona_i, perfil, encargo, lineas, **kw):
    zona = ZONAS[zona_i]
    d = {"id_nivel": "arcoiris_z%d_pinta_%s" % (zona_i + 1, perfil), "motor": "lienzo_libre", "perfil": perfil,
         "planeta": "arcoiris", "zona": zona, "tema": "pinta con coco", "anfitrion_id": "coco", "fondo_id": "planeta_arcoiris",
         "encargo": encargo, "sin_fallo": True, "coco_imita_color": True, "guardar_dibujo": True,
         # Pinta no tiene fallo ni puntaje: no cuenta para la zona "perfecta" (marco dorado, HE-40 §2.4).
         "puntua_estrellitas": False}
    d.update(PATRONES)
    d.update(kw)
    voces = voces_perfil(perfil)
    voces.update(lineas)
    d["lineas_voz"] = voces
    return d

def escribir(n):
    ruta = os.path.join(RAIZ, "datos", "niveles", "arcoiris", n["zona"], "pinta_%s.json" % n["perfil"])
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(n, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("nivel:", ruta)

PAL_SEM = ["rojo", "azul", "amarillo", "verde", "rosa", "violeta"]
PAL_COMP = ["rojo", "naranja", "amarillo", "verde", "azul", "violeta", "rosa", "turquesa", "celeste", "blanco", "cafe", "negro", "gris", "verde_oscuro"]
HERR_B = ["pincel", "pincel_corazon", "pincel_estrella", "goma"]
HERR_E = ["pincel", "pincel_grueso", "pincel_estrella", "purpurina", "goma"]

niveles = []
# Zona 1: lienzo libre CON TEMA (ficha motor-lienzo-libre.md §8, pedido del PO 27-Sep-2026)
niveles.append(nivel(0, "semilla", "libre", voces_lienzo_tema("semilla"), paleta=PAL_SEM, segundos_mostrar=45, segundos_recordar_mostrar=90, sellos_vivos=True,
                     temas=temas_de("semilla"), temas_por_partida=2, opciones_tema=1, al_menos_una="favorito",
                     voces_stickers=PREF_STICKERS))
niveles.append(nivel(0, "brote", "libre", voces_lienzo_tema("brote"), paleta=PAL_COMP, color_inicial="rosa", lado_sello=104,
                     temas=temas_de("brote"), temas_por_partida=3, opciones_tema=2, voces_stickers=PREF_STICKERS))
niveles.append(nivel(0, "estrella", "libre", voces_lienzo_tema("estrella"), paleta=PAL_COMP, color_inicial="turquesa", lado_sello=92,
                     temas=temas_de("estrella"), temas_por_partida=3, opciones_tema=3, voces_stickers=PREF_STICKERS))
# Zona 2
niveles.append(nivel(1, "semilla", "sellos_escena", {"intro": voz("semilla/intro_sellos", "¡Mira esta pradera! Toca abajo un dinosaurio o un autito, y después toca la pradera para ponerlo."),
                                                      "siguiente": [voz("semilla/siguiente_sellos", "¡Otro lugar para jugar! ¡A poner dinosaurios!")]},
                     paleta=PAL_SEM, herramientas=["sello_dino", "sello_auto", "sello_estrella", "pincel"], herramienta_inicial="sello_dino",
                     laminas=[pradera(), valle_dinos()], laminas_por_partida=2, segundos_mostrar=45, segundos_recordar_mostrar=90, sellos_vivos=True))
niveles.append(nivel(1, "brote", "colorear_zonas", {"intro": voz("brote/intro_zonas", "¡A colorear! Elige un color y toca una parte del dibujo para rellenarla. Arriba tienes un modelito, por si lo quieres copiar."),
                                                     "siguiente": [voz("brote/siguiente_01", "¡Otra lámina! ¿Qué será?"), voz("brote/siguiente_02", "¡Aquí viene otro dibujo!")]},
                     paleta=PAL_COMP, herramientas=["balde", "pincel", "pincel_corazon", "pincel_estrella"], herramienta_inicial="balde", modelo=True,
                     laminas=[pony(), jirafa(), gatito(), bandera_chile(), torres_paine(), valparaiso()], laminas_por_partida=3, al_menos_una="chile"))
niveles.append(nivel(1, "estrella", "colorear_codigo", {"intro": voz("estrella/intro_codigo", "¡Colorear por código! Cada número tiene su color: míralo en la paleta. Pinta todos los cuadritos y descubre el dibujo secreto."),
                                                         "siguiente": [voz("estrella/siguiente_codigo_01", "¡Otro mosaico secreto! ¿Qué será?"), voz("estrella/siguiente_codigo_02", "¡Vamos con el siguiente misterio!")]},
                     herramientas=[], laminas=mosaicos(), laminas_por_partida=3, al_menos_una="chile"))
# Zona 3
niveles.append(nivel(2, "semilla", "pinta_coco", {"intro": voz("semilla/intro_pinta_coco", "¡Píntame, Maxi! Elige un color y toca mi cuerpito. ¡Voy a cambiar de color!"),
                                                   "siguiente": [voz("semilla/siguiente_amigo", "¡Ahora pinta a mi amigo!")]},
                     paleta=PAL_SEM, herramientas=[], rellenar_con_toque=True, tinte_coco=True, segundos_mostrar=45, segundos_recordar_mostrar=90,
                     laminas=[coco(), dino_amigo(), auto_amigo()], primera_fija=True, laminas_por_partida=2))
niveles.append(nivel(2, "brote", "coco_pide", {"intro": voz("brote/intro_coco_pide", "¡Juguemos! Yo te pido un color y tú pintas algo con ese color. ¡Escucha bien!"),
                                                "siguiente": [voz("brote/siguiente_coco_pide", "¡Otro dibujo! Escucha qué color te pido.")],
                                                "pedidos_listos": [voz("brote/pedidos_listos", "¡Pintaste todos los colores que te pedí! Ahora pinta lo que quieras y muéstramelo.")]},
                     paleta=PAL_COMP, herramientas=["balde", "pincel_corazon", "pincel_estrella"], herramienta_inicial="balde", color_inicial="blanco",
                     laminas=[jardin_coco(), castillo()], laminas_por_partida=2,
                     pedidos=list(PEDIDOS.keys()), pedidos_por_partida=5,
                     voces_pedidos="voces/arcoiris/pinta/pedidos/%s.wav", voces_logrado="voces/arcoiris/pinta/logrado/%s.wav"))
mezcla_laminas = []
for f in (volcan_osorno, torres_paine, valparaiso):
    l = f(); mezcla_laminas.append(l)
niveles.append(nivel(2, "estrella", "mezcla_paleta", {"intro": voz("estrella/intro_mezcla", "¡Mezcla en la paleta! Solo hay rojo, amarillo, azul y blanco. Toca los colores para echarlos al platito, y pinta con tu mezcla. ¡Descubre colores nuevos!"),
                                                       "pedidos_listos": [voz("estrella/pedidos_listos", "¡Preparaste todas mis mezclas! Eres una maestra de los colores. Termina tu dibujo y muéstramelo.")]},
                     paleta=["rojo", "amarillo", "azul", "blanco"], herramientas=["balde", "pincel", "pincel_grueso", "goma"], herramienta_inicial="balde",
                     laminas=mezcla_laminas, laminas_por_partida=1,
                     pedidos=list(PEDIDOS_MEZCLA.keys()), pedidos_por_partida=5,
                     voces_pedidos="voces/arcoiris/pinta/pedidos_mezcla/%s.wav", voces_logrado="voces/arcoiris/pinta/mezclas/%s.wav",
                     voces_mezclas="voces/arcoiris/pinta/mezclas/%s.wav"))
# Zona 4
niveles.append(nivel(3, "semilla", "dedo_magico", {"intro": voz("semilla/intro_dedo_magico", "¡Dedo mágico! Pasa tu dedo por la hoja y escucha la música del arcoíris."),
                                                    "siguiente": [voz("semilla/siguiente_dedo", "¡Otra hoja mágica! ¡Pinta y escucha!")],
                                                    "uso_arcoiris": voz("semilla/uso_arcoiris", "¡Un arcoíris que canta!")},
                     paleta=[], herramientas=[], herramienta_inicial="arcoiris", notas=True, radio_pincel=30, segundos_mostrar=45, segundos_recordar_mostrar=90,
                     laminas=[{"id": "noche", "tipo": "papel", "papel": "#232851"}, {"id": "rosa", "tipo": "papel", "papel": "#FFE3F1"}], laminas_por_partida=2))
niveles.append(nivel(3, "brote", "espejo", {"intro": voz("brote/intro_espejo", "¡Espejo mágico! Pinta en un lado y mira cómo aparece en el otro. Puedes seguir el dibujito, o inventar el tuyo."),
                                             "siguiente": [voz("brote/siguiente_espejo", "¡Otro espejo mágico!")]},
                     paleta=PAL_COMP, color_inicial="rosa", herramientas=["pincel", "pincel_corazon", "pincel_estrella", "sello_corazon", "goma"], simetria="espejo",
                     laminas=espejos(), laminas_por_partida=2))
niveles.append(nivel(3, "estrella", "mandala", {"intro": voz("estrella/intro_mandala", "¡Mandala arcoíris! Todo lo que pintes se repite seis veces alrededor del centro, como en un caleidoscopio."),
                                                 "siguiente": [voz("estrella/siguiente_mandala", "¡Otro mandala! Prueba con otros pinceles.")]},
                     paleta=PAL_COMP, color_inicial="turquesa", herramientas=HERR_E, simetria="mandala", papel="#FFFFFF",
                     laminas=mandalas(), laminas_por_partida=2))
# Zona 5: decora el ala
NAVE = "res://assets/sprites/nave/nave_estrella.png"
niveles.append(nivel(4, "semilla", "decora_ala", {"intro": voz("semilla/intro_ala", "¡Esta es el ala de tu nave! Elige un color y toca el ala para pintarla.")},
                     paleta=PAL_SEM, herramientas=["balde", "sello_dino", "sello_auto", "sello_estrella"], herramienta_inicial="balde",
                     laminas=[ala()], guardar_como="ala_nave", imagen_modelo=NAVE, modelo=True, segundos_mostrar=45, segundos_recordar_mostrar=90, sellos_vivos=True))
niveles.append(nivel(4, "brote", "decora_ala", {"intro": voz("brote/intro_ala", "¡Decora el ala de la nave, Nicole! Rellena con el balde o pinta con tus pinceles.")},
                     paleta=PAL_COMP, color_inicial="rosa", etapas=[
                         {"encargo": "decora_ala", "herramientas": ["balde", "pincel", "pincel_corazon", "sello_corazon", "sello_estrella"], "herramienta_inicial": "balde",
                          "laminas": [ala()], "guardar_como": "ala_nave", "imagen_modelo": NAVE, "modelo": True},
                         {"encargo": "viste_coco", "herramientas": ["balde", "sello_corazon", "sello_estrella"], "herramienta_inicial": "balde",
                          "laminas": [coco_traje()], "guardar_como": "traje_coco",
                          "lineas_voz": {"intro": voz("brote/intro_viste", "¡Ahora vísteme! Elige mi traje abajo y píntalo como quieras.")}}]))
niveles.append(nivel(4, "estrella", "decora_ala", {"intro": voz("estrella/intro_ala", "¡Decora el ala de la nave! Tienes brillos, lunas, estrellas y tu insignia de pony.")},
                     paleta=PAL_COMP, color_inicial="turquesa", herramientas=["balde", "pincel", "sello_destello", "sello_estrella", "sello_luna", "sello_pony", "purpurina"],
                     herramienta_inicial="balde", laminas=[ala()], guardar_como="ala_nave", imagen_modelo=NAVE, modelo=True))

for n in niveles:
    escribir(n)

# TSV de voces (TTS provisional de Windows)
tsv = os.path.join(RAIZ, "assets", "audio", "voces", "arcoiris", "pinta", "lineas_tts.tsv")
os.makedirs(os.path.dirname(tsv), exist_ok=True)
with open(tsv, "w", encoding="utf-8") as f:
    f.write("# Pinta con Coco (motor lienzo_libre): voces PROVISIONALES con el TTS de Windows (herramientas/generar_voces_tts.ps1).\n")
    f.write("# Formato: ruta relativa a assets/audio/ <TAB> texto. Generado junto con los niveles pinta_*.json.\n")
    f.write("# Pendiente: pasar a las voces oficiales de Coco/Cometa (generar_voces_fal.py) con OK del PO sobre el costo.\n")
    for r in sorted(VOCES):
        f.write("%s\t%s\n" % (r, VOCES[r]))
print("voces:", len(VOCES), tsv)
