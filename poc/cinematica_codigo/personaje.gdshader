shader_type canvas_item;

// Personaje pintado plano (sin rig), todo en un shader:
//   - "gelatina": la parte de arriba se mece y los pies quedan fijos (respirar, hablar);
//   - `tono`: gira el matiz SOLO de la piel (rango `rango_piel`), así la camaleona cambia de
//     color sin que se le pinten los ojos, la guatita ni los cachetes;
//   - `camuflaje`: 1 = casi invisible (una silueta tenue), 0 = visible. Al bajar, el personaje
//     aparece desde los pies hacia arriba con un borde brillante que titila.

uniform float intensidad : hint_range(0.0, 1.0) = 0.15;
uniform float velocidad = 3.0;
uniform float amplitud_px = 6.0;
uniform float tono = 0.0;
uniform vec2 rango_piel = vec2(0.85, 0.975);
uniform float camuflaje : hint_range(0.0, 1.0) = 0.0;
uniform float silueta = 0.07;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1.0e-10)), d / (q.x + 1.0e-10), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void vertex() {
	float peso = pow(1.0 - UV.y, 1.6);
	VERTEX.x += sin(TIME * velocidad + UV.y * 2.5) * amplitud_px * intensidad * peso;
	VERTEX.y += cos(TIME * velocidad * 1.3) * amplitud_px * 0.4 * intensidad * peso;
}

void fragment() {
	// En Godot 4, COLOR ya llega multiplicado por la textura (y por modulate).
	vec4 c = COLOR;
	if (abs(tono) > 0.001) {
		vec3 hsv = rgb2hsv(c.rgb);
		float piel = smoothstep(rango_piel.x - 0.03, rango_piel.x, hsv.x)
			* (1.0 - smoothstep(rango_piel.y, rango_piel.y + 0.02, hsv.x))
			* smoothstep(0.08, 0.16, hsv.y) * smoothstep(0.4, 0.55, hsv.z);
		vec3 girado = hsv2rgb(vec3(fract(hsv.x + tono), min(hsv.y * 1.5, 1.0), hsv.z));
		c.rgb = mix(c.rgb, girado, piel);
	}
	if (camuflaje > 0.001) {
		float ruido = sin(UV.y * 45.0 + TIME * 7.0) * 0.5 + 0.5;
		float v = UV.y * 0.8 + ruido * 0.2;
		// camuflaje 1 -> umbral sobre 1 (nada visible); 0 -> bajo 0 (todo visible).
		float umbral = camuflaje * 1.3 - 0.15;
		float visible = smoothstep(umbral - 0.06, umbral + 0.02, v);
		float borde = (1.0 - smoothstep(0.0, 0.05, abs(v - umbral))) * step(0.02, camuflaje) * step(camuflaje, 0.98);
		float gris = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		vec3 tenue = vec3(gris * 0.9 + 0.08);
		c.rgb = mix(tenue, c.rgb, visible) + vec3(1.0, 0.95, 0.8) * borde * 0.9;
		c.a *= mix(silueta, 1.0, max(visible, borde));
	}
	COLOR = c;
}
