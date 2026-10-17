shader_type canvas_item;

// Fondo pintado con su color "apagado" a voluntad: el planeta gris del presente y la onda
// que le chupa el color en el recuerdo. La onda es un círculo que crece desde `centro_onda`
// (UV) y deja adentro `saturacion_onda`; afuera queda `saturacion`.

uniform float saturacion : hint_range(0.0, 1.0) = 1.0;
uniform float saturacion_onda : hint_range(0.0, 1.0) = 1.0;
uniform vec2 centro_onda = vec2(0.5, 0.5);
uniform float radio_onda = 0.0;
uniform float aclarar : hint_range(0.0, 1.0) = 0.0;
uniform float aspecto = 1.7778;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float gris = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec2 d = (UV - centro_onda) * vec2(aspecto, 1.0);
	// Borde ondulado: la onda avanza "a mordiscos", no como un círculo perfecto.
	float borde = radio_onda * (1.0 + 0.06 * sin(atan(d.y, d.x) * 7.0 + TIME * 3.0));
	float dentro = 1.0 - smoothstep(borde - 0.07, borde, length(d));
	float s = mix(saturacion, saturacion_onda, dentro);
	vec3 col = mix(vec3(gris), c.rgb, s);
	COLOR = vec4(mix(col, vec3(0.93, 0.92, 0.95), aclarar), c.a);
}
