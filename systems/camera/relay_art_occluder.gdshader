shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D background : source_color, filter_nearest, repeat_disable;
uniform float brightness = 1.0;

void fragment() {
	ALBEDO = texture(background, SCREEN_UV).rgb * brightness;
}
