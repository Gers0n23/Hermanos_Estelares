shader_type canvas_item;

// "El planeta perdió sus colores" (ficha de zonas §1): mezcla la textura hacia un gris lila
// según `viveza` (0 = todo gris, 1 = todo su color). Lo usa el paisaje del mapa de un planeta,
// que gana color a medida que vuelven las bandas del arcoíris.

uniform float viveza : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float luz = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gris = vec3(luz) * vec3(0.97, 0.95, 1.05);
	COLOR = vec4(mix(gris, color.rgb, viveza), color.a);
}
