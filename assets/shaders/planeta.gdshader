shader_type canvas_item;

// Planeta redondo "de verdad" para el mapa estelar (27-Sep-2026, pedido del PO: nada de
// imagenes deformadas dentro de un disco). Se dibuja sobre un ColorRect cuadrado: una
// esfera iluminada desde arriba a la izquierda, con la superficie girando despacio, un
// patron propio de cada mundo, contorno calido como el de los personajes y un halo de
// atmosfera. `planeta_dibujado.gd` pone encima/detras los adornos de cada planeta.
//
// patron: 0 franjas pastel (Arcoiris)   1 continentes + nubes (Tierra, Animalia)
//         2 ondas de sonido (Melodia)    3 cielo nocturno con crateres (Cuenta-Cuentas)
//         4 dunas (Letralandia)          5 corazones (Corazon)

uniform int patron = 0;
uniform vec4 color_0 : source_color = vec4(1.0, 0.6, 0.75, 1.0);
uniform vec4 color_1 : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform vec4 color_2 : source_color = vec4(0.5, 0.9, 0.8, 1.0);
uniform vec4 color_3 : source_color = vec4(0.6, 0.75, 1.0, 1.0);
uniform vec4 color_4 : source_color = vec4(0.75, 0.6, 1.0, 1.0);
uniform vec4 color_5 : source_color = vec4(1.0, 0.7, 0.5, 1.0);
uniform vec4 atmosfera : source_color = vec4(1.0, 0.9, 1.0, 1.0);
uniform vec4 contorno : source_color = vec4(0.23, 0.13, 0.25, 1.0);
uniform float velocidad = 0.02;
// patron 1: mas bajo = mas tierra firme
uniform float nivel_mar = 0.5;
uniform float semilla = 0.0;
// 0 = a todo color; 1 = planeta lejano todavia sin visitar (desaturado y tenue, nunca candado)
uniform float apagado : hint_range(0.0, 1.0) = 0.0;
// fraccion del cuadrado que ocupa la esfera (el resto es halo)
uniform float radio_esfera = 0.8;

float hash(vec2 p) {
	// hash sin seno (el seno de argumentos grandes pierde precision en GPU moviles)
	vec3 q = fract(vec3(p.xyx) * 0.1031 + semilla * 0.013);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	// cada octava girada y corrida: sin esto el ruido de valor deja manchas cuadradas
	mat2 giro = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		v += a * ruido(p);
		p = giro * p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

vec3 paleta(int i) {
	if (i == 0) return color_0.rgb;
	if (i == 1) return color_1.rgb;
	if (i == 2) return color_2.rgb;
	if (i == 3) return color_3.rgb;
	if (i == 4) return color_4.rgb;
	return color_5.rgb;
}

float corazon(vec2 p) {
	// SDF de corazon (Inigo Quilez), p centrado en la celda
	p.x = abs(p.x);
	p.y = -p.y + 0.25;
	if (p.y + p.x > 1.0)
		return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
	vec2 a = p - vec2(0.0, 1.0);
	vec2 b = p - 0.5 * max(p.x + p.y, 0.0);
	return sqrt(min(dot(a, a), dot(b, b))) * sign(p.x - p.y);
}

vec3 superficie(vec2 uv, float lat) {
	// uv.x = longitud (0..1, gira con el tiempo), uv.y = latitud (-1..1)
	if (patron == 0) {
		float onda = 0.06 * sin(uv.x * 6.2832 * 3.0) + 0.03 * sin(uv.x * 6.2832 * 7.0);
		float t = (lat * 0.92 + 1.0) * 0.5 * 6.0 + onda * 1.6;
		int i = int(clamp(floor(t), 0.0, 5.0));
		float brillo = smoothstep(0.55, 0.0, fract(t)) * 0.12;
		return paleta(i) * (1.0 + brillo);
	}
	if (patron == 1) {
		vec2 q = vec2(uv.x * 6.0, lat * 2.2);
		float tierra = fbm(q + vec2(semilla, 0.0));
		vec3 c = color_0.rgb;
		c = mix(c, color_0.rgb * 1.15, smoothstep(nivel_mar - 0.2, nivel_mar - 0.05, tierra));
		c = mix(c, color_1.rgb, smoothstep(nivel_mar, nivel_mar + 0.02, tierra));
		c = mix(c, color_2.rgb, smoothstep(nivel_mar + 0.1, nivel_mar + 0.12, tierra));
		float nubes = fbm(q * 1.6 + vec2(TIME * velocidad * 20.0, 3.0));
		c = mix(c, color_3.rgb, smoothstep(0.6, 0.68, nubes) * 0.9);
		// casquetes polares
		c = mix(c, color_3.rgb, smoothstep(0.82, 0.86, abs(lat)));
		return c;
	}
	if (patron == 2) {
		float t = lat * 7.0 + 0.7 * sin(uv.x * 6.2832 * 4.0 + lat * 3.0);
		vec3 c = mix(color_0.rgb, color_1.rgb, 0.5 + 0.5 * sin(t));
		float linea = smoothstep(0.1, 0.0, abs(fract(t / 3.1416) - 0.5) - 0.02);
		return mix(c, color_2.rgb, linea * 0.9);
	}
	if (patron == 3) {
		vec3 c = mix(color_0.rgb, color_1.rgb, 0.5 + 0.5 * lat);
		c = mix(c, color_1.rgb * 1.1, smoothstep(0.45, 0.7, fbm(vec2(uv.x * 5.0, lat * 2.0))) * 0.5);
		vec2 celda = vec2(uv.x * 10.0, lat * 4.0);
		vec2 id = floor(celda);
		vec2 f = fract(celda) - 0.5;
		vec2 centro = vec2(hash(id) - 0.5, hash(id + 3.1) - 0.5) * 0.5;
		float r = 0.12 + 0.18 * hash(id + 7.7);
		float d = length(f - centro);
		if (hash(id + 1.3) > 0.45) {
			c = mix(c, color_2.rgb, smoothstep(r, r - 0.05, d));
			c = mix(c, color_2.rgb * 0.8, smoothstep(r - 0.06, r - 0.1, d) * 0.5);
		}
		vec2 e = fract(vec2(uv.x * 23.0, lat * 9.0)) - 0.5;
		float brillo = smoothstep(0.07, 0.0, length(e)) * step(0.8, hash(floor(vec2(uv.x * 23.0, lat * 9.0)) + 5.0));
		return mix(c, color_3.rgb, brillo);
	}
	if (patron == 4) {
		float t = lat * 5.0 + 0.5 * sin(uv.x * 6.2832 * 2.0) + 0.25 * sin(uv.x * 6.2832 * 5.0 + lat * 4.0);
		float f = fract(t);
		vec3 c = mix(color_0.rgb, color_1.rgb, smoothstep(0.2, 0.8, f));
		c = mix(c, color_2.rgb, smoothstep(0.85, 0.95, f) * 0.8);
		float oasis = smoothstep(0.66, 0.7, fbm(vec2(uv.x * 7.0, lat * 3.0) + 11.0));
		return mix(c, color_3.rgb, oasis);
	}
	// patron 5: corazones
	vec3 c = mix(color_0.rgb, color_1.rgb, smoothstep(-0.6, 0.6, lat + 0.25 * sin(uv.x * 6.2832 * 2.0)));
	vec2 celda = vec2(uv.x * 9.0, lat * 3.2);
	vec2 id = floor(celda);
	vec2 f = (fract(celda) - 0.5) * 2.4;
	f.x += (hash(id) - 0.5) * 0.5;
	float d = corazon(f / (0.7 + 0.5 * hash(id + 2.0)));
	float hay = step(0.35, hash(id + 9.0));
	c = mix(c, hash(id + 4.0) > 0.5 ? color_2.rgb : color_3.rgb, smoothstep(0.03, -0.03, d) * hay);
	return c;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 / radio_esfera;
	float r = length(p);
	vec3 luz = normalize(vec3(-0.55, -0.65, 0.75));
	if (r > 1.0) {
		// halo de atmosfera afuera de la esfera
		float halo = smoothstep(1.0 / radio_esfera, 1.0, r);
		halo = pow(1.0 - clamp((r - 1.0) / (1.0 / radio_esfera - 1.0), 0.0, 1.0), 2.2);
		float lado = 0.55 + 0.45 * clamp(dot(normalize(vec3(p, 0.0)), luz) + 0.3, 0.0, 1.0);
		COLOR = vec4(atmosfera.rgb, halo * 0.55 * lado * (1.0 - 0.6 * apagado));
	} else {
		vec3 n = vec3(p, sqrt(1.0 - r * r));
		float lon = atan(n.x, n.z) / 6.2832 + TIME * velocidad + semilla;
		float lat = asin(clamp(n.y, -1.0, 1.0)) / 1.5708;
		vec3 c = superficie(vec2(lon, 0.0), lat);
		// iluminacion suave de dibujo: sombra lila (no negra) y brillo calido
		float dif = clamp(dot(n, luz), 0.0, 1.0);
		vec3 sombra = c * vec3(0.55, 0.5, 0.75);
		c = mix(sombra, c * 1.06, smoothstep(0.0, 0.75, dif));
		float especular = pow(clamp(dot(reflect(-luz, n), vec3(0.0, 0.0, 1.0)), 0.0, 1.0), 24.0);
		c += vec3(1.0) * especular * 0.35;
		float fresnel = pow(1.0 - n.z, 3.0);
		c = mix(c, atmosfera.rgb, fresnel * 0.55);
		// contorno calido como el de los personajes, con borde antialias
		float ancho = 0.045;
		float linea = smoothstep(1.0 - ancho - 0.015, 1.0 - ancho, r);
		c = mix(c, contorno.rgb, linea);
		float alfa = smoothstep(1.0, 1.0 - 0.015, r);
		float gris = dot(c, vec3(0.3, 0.59, 0.11));
		c = mix(c, vec3(gris) * vec3(0.8, 0.8, 0.95), apagado * 0.75);
		c *= 1.0 - 0.3 * apagado;
		COLOR = vec4(c, alfa);
		// mezcla el borde de la esfera con el halo para no dejar una arista dura
		if (alfa < 1.0) {
			COLOR = mix(vec4(atmosfera.rgb, 0.5 * (1.0 - 0.6 * apagado)), COLOR, alfa);
		}
	}
}
