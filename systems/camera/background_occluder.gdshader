shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D background : source_color, filter_nearest, repeat_disable;
// Must match the crop applied to the background plate and to the camera.
uniform float zoom = 1.0;
uniform vec2 focus = vec2(0.5);
uniform float black_floor = 0.0;

void fragment() {
	vec3 plate = texture(background, (SCREEN_UV - vec2(0.5)) / zoom + focus).rgb;
	if (black_floor > 0.0 && max(plate.r, max(plate.g, plate.b)) <= black_floor) {
		plate = vec3(0.0);
	}
	ALBEDO = plate;
}
