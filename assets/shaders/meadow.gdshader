shader_type spatial;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D road_mask : repeat_disable, filter_linear;
uniform vec4 road_bounds;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz;
	vec2 road_uv = (p - road_bounds.xy) / road_bounds.zw;
	// Keep the existing mask and circulation; break up its edges without moving roads.
	float mask = texture(road_mask, road_uv).r;
	float path = smoothstep(0.08, 0.92, mask + (noise(p * 2.1) - 0.5) * 0.15);
	float detail = dot(texture(grass_tex, p / 8.0).rgb, vec3(0.2126, 0.7152, 0.0722));
	float broad = noise(p * 0.13) * 0.65 + noise(p * 0.37) * 0.35;
	// Preserve Emerald Meadow's texture detail, with a quieter emerald/olive palette.
	vec3 grass = mix(vec3(0.055, 0.14, 0.038), vec3(0.17, 0.27, 0.075), broad);
	grass *= 0.75 + detail * 1.65;
	vec3 dirt_sample = texture(dirt_tex, p / 2.0).rgb;
	float grain = dot(dirt_sample, vec3(0.333));
	vec3 dirt = mix(vec3(0.28, 0.205, 0.13), vec3(0.46, 0.36, 0.24), grain);
	dirt *= mix(0.85, 1.10, noise(p * 0.6));
	dirt += vec3((noise(p * 19.0) - 0.5) * 0.04);
	dirt = mix(dirt, vec3(0.47, 0.43, 0.32), smoothstep(0.83, 0.95, noise(p * 8.0)) * 0.4);
	// A narrow, subdued verge replaces the old hard yellow outline.
	grass = mix(grass, vec3(0.14, 0.19, 0.055), smoothstep(0.02, 0.22, mask) * 0.4);
	ALBEDO = mix(grass, dirt, path);
	ROUGHNESS = 0.96;
	SPECULAR = 0.15;
}
