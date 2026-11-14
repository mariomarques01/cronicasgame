shader_type canvas_item;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = 1.0 - smoothstep(0.96, 1.0, length(p));
	vec4 sampled = texture(TEXTURE, UV);
	COLOR = vec4(sampled.rgb, sampled.a * edge);
}
