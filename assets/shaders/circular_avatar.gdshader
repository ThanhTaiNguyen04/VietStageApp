shader_type canvas_item;

// PanelContainer only clips children to a rectangle. Mask the texture itself
// so square avatar images stay inside the circular frame.
void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	float edge_width = fwidth(distance_from_center);
	float circle_mask = 1.0 - smoothstep(0.46 - edge_width, 0.46 + edge_width, distance_from_center);
	vec4 avatar_color = texture(TEXTURE, UV);
	avatar_color.a *= circle_mask;
	COLOR = avatar_color;
}
