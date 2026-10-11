shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 screen_span = vec2(1.0);
uniform vec2 screen_origin = vec2(0.0);
uniform vec2 virtual_resolution = vec2(320.0, 180.0);
uniform bool crt_enabled = false;

// Ordered dithering stays attached to the virtual framebuffer, without noise/flicker.
const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec2 pixel = min(floor(UV * virtual_resolution), virtual_resolution - 1.0);
	vec2 snapped_uv = (pixel + 0.5) / virtual_resolution;
	// Sample only inside this composition, including when the window has black bars.
	vec2 sample_uv = screen_origin + snapped_uv * screen_span;
	vec3 color = textureLod(screen_texture, sample_uv, 0.0).rgb;
	int index = int(mod(pixel.x, 4.0)) + int(mod(pixel.y, 4.0)) * 4;
	float threshold = (BAYER[index] + 0.5) / 16.0 - 0.5;
	color = floor(clamp(color + threshold * (0.85 / 31.0), 0.0, 1.0) * 31.0 + 0.5) / 31.0;
	if (crt_enabled) {
		float scanline = 0.91 + 0.09 * cos(6.2831853 * (UV.y * virtual_resolution.y - 0.5));
		vec2 centered = UV * 2.0 - 1.0;
		float vignette = 1.0 - 0.12 * dot(centered * centered, centered * centered);
		color *= scanline * vignette;
	}
	COLOR = vec4(color, 1.0);
}
