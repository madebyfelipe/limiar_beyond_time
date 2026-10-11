shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 surface;
void vertex() { surface = VERTEX; }
void fragment() {
	float grain = fract(sin(dot(floor(surface.xy * 430.0), vec2(12.9898, 78.233))) * 43758.5453);
	float wear = smoothstep(0.85, 1.0, grain);
	ALBEDO = mix(vec3(0.11, 0.16, 0.18), vec3(0.22, 0.25, 0.25), grain * 0.3 + wear * 0.25);
	METALLIC = 0.45;
	ROUGHNESS = 0.68;
}
