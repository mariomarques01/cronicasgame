shader_type spatial;
render_mode cull_disabled;
uniform float breeze = 1.0;
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = dot(origin.xz + VERTEX.xz, vec2(0.48, 0.33));
	float bend = sin(TIME * 1.4 + phase) * 0.045 + sin(TIME * 2.2 + phase * 1.7) * 0.018;
	VERTEX.x += bend * VERTEX.y * breeze;
	VERTEX.z += bend * VERTEX.y * 0.45 * breeze;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
