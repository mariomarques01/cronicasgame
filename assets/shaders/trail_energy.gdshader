shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 ember_color : source_color = vec4(1.0, 0.48, 0.08, 1.0);
uniform vec4 jade_color : source_color = vec4(0.16, 0.88, 0.64, 1.0);
uniform float sway = 0.035;
void vertex() {
	float phase = UV.x * 18.84956 - TIME * 2.5;
	VERTEX.y += sin(phase) * sway * (0.25 + UV.y);
	VERTEX.x += sin(TIME * 2.0 + UV.y * 3.0) * sway * UV.y;
}
void fragment() {
	float flow = 0.5 + 0.5 * sin(UV.x * 18.84956 - TIME * 2.5 + UV.y * 2.0);
	vec3 tint = mix(jade_color.rgb, ember_color.rgb, smoothstep(0.2, 0.8, flow));
	ALBEDO = tint;
	EMISSION = tint * (0.5 + flow * 0.7);
	ROUGHNESS = 1.0;
}
