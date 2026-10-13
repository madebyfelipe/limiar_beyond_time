shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D steel_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.7;
varying vec3 surface;
varying vec3 local_normal;
void vertex() {
	surface = VERTEX;
	local_normal = NORMAL;
}
void fragment() {
	// Object-space projection keeps the grain fixed while the hinge rotates.
	vec3 weights = pow(abs(local_normal), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.0001);
	vec3 p = surface * texture_scale;
	ALBEDO = texture(steel_texture, p.yz).rgb * weights.x
		+ texture(steel_texture, p.xz).rgb * weights.y
		+ texture(steel_texture, p.xy).rgb * weights.z;
	METALLIC = 0.45;
	ROUGHNESS = 0.76;
}
