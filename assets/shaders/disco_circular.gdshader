shader_type canvas_item;

// Recorte circular reutilizable para "discos" de planeta/retrato (UI ad-hoc, mockup
// del PO "UI Sistema"): descarta la textura fuera de un circulo centrado en el nodo y,
// opcionalmente, la deja en escala de grises + desenfoque leve + mas tenue — el
// tratamiento que usa el mapa estelar para los planetas todavia no desbloqueados
// (GDD §3: nunca "candado", solo se ven lejanos/borrosos, jamas bloqueados con un icono
// de prohibido).

uniform bool escala_de_grises = false;
uniform float desenfoque : hint_range(0.0, 1.0) = 0.0;
uniform float opacidad : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color;
	if (desenfoque > 0.0) {
		vec4 acumulado = vec4(0.0);
		float radio_px = desenfoque * 0.028;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				vec2 desplazo = vec2(float(x), float(y)) * radio_px;
				acumulado += texture(TEXTURE, UV + desplazo);
			}
		}
		color = acumulado / 25.0;
	} else {
		color = texture(TEXTURE, UV);
	}

	if (escala_de_grises) {
		float gris = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		color.rgb = mix(color.rgb, vec3(gris), 0.85);
	}

	float distancia = distance(UV, vec2(0.5));
	float borde = 1.0 - smoothstep(0.47, 0.5, distancia);
	COLOR = vec4(color.rgb, color.a * borde * opacidad);
}
