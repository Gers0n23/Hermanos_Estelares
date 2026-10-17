shader_type canvas_item;

// Deformacion "gelatina" para arte pintado plano: la parte de arriba del sprite se mece
// mas que la de abajo (los pies quedan fijos), asi un PNG sin rig se siente vivo.
// `intensidad` se anima desde el script (respirar, hablar, aterrizar).

uniform float intensidad : hint_range(0.0, 1.0) = 0.15;
uniform float velocidad = 3.0;
uniform float amplitud_px = 6.0;

void vertex() {
	// UV.y = 0 arriba, 1 abajo: el peso crece hacia arriba.
	float peso = pow(1.0 - UV.y, 1.6);
	VERTEX.x += sin(TIME * velocidad + UV.y * 2.5) * amplitud_px * intensidad * peso;
	VERTEX.y += cos(TIME * velocidad * 1.3) * amplitud_px * 0.4 * intensidad * peso;
}
