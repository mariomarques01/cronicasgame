shader_type canvas_item;
uniform vec2 sample_center = vec2(0.5);
uniform float sample_scale = 1.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = 1.0 - smoothstep(0.96, 1.0, length(p));
	vec4 sampled = texture(TEXTURE, sample_center + (UV - vec2(0.5)) * sample_scale);
	COLOR = vec4(sampled.rgb, sampled.a * edge);
}
