shader_type canvas_item;

// Cortina de iris: circulo transparente que se cierra (radio 1 = abierto, 0 = cerrado).
// Se usa en un ColorRect a pantalla completa.

uniform float radio : hint_range(0.0, 1.5) = 1.5;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float aspecto = 1.7778;

void fragment() {
	vec2 d = UV - centro;
	d.x *= aspecto;
	float dist = length(d);
	float borde = smoothstep(radio, radio + 0.01, dist);
	COLOR = vec4(COLOR.rgb, borde * COLOR.a);
}
