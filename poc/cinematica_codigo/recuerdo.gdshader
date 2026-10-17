shader_type canvas_item;

// Burbuja de recuerdo: muestra la textura (el SubViewport del flashback) dentro de un
// círculo con borde de nube que respira. `radio` 0 = cerrada; ~1.0 = llena la pantalla
// dejando ver las esquinas del presente, como un globo de pensamiento.

uniform float radio = 0.0;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float aspecto = 1.7778;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 d = (UV - centro) * vec2(aspecto, 1.0);
	float ang = atan(d.y, d.x);
	float r = radio * (1.0 + 0.035 * sin(ang * 11.0 + TIME * 1.2) + 0.02 * sin(ang * 5.0 - TIME * 0.8));
	float dist = length(d);
	float dentro = 1.0 - smoothstep(r - 0.004, r, dist);
	float anillo = smoothstep(r - 0.045, r - 0.012, dist) * dentro;
	// Brillo de recuerdo: un velo cálido muy leve hacia el borde.
	float vineta = smoothstep(r * 0.55, r, dist) * 0.18;
	vec3 col = mix(c.rgb, vec3(1.0, 0.96, 0.88), vineta);
	col = mix(col, vec3(1.0, 0.99, 0.97), anillo);
	COLOR = vec4(col, dentro);
}
