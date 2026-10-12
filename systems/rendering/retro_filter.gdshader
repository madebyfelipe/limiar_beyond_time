shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 screen_span = vec2(1.0);
uniform vec2 screen_origin = vec2(0.0);
uniform vec2 virtual_resolution = vec2(320.0, 180.0);
// Every effect is an independent dial; all of them at zero leave the picture
// untouched beyond the virtual framebuffer.
uniform float scanline : hint_range(0.0, 1.0) = 0.0;
// Bands are counted apart from the framebuffer: past a few hundred rows,
// scanlines stop reading as lines and start shimmering.
uniform float scanline_rows = 180.0;
uniform float grille : hint_range(0.0, 1.0) = 0.0;
uniform float curve : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
// Scanlines, grille and vignette all take light away. Gain puts part of it back,
// so a preset reads as a different screen and not as a dimmer one. It is applied
// before quantisation, so the dithering still happens on the value shown.
uniform float gain : hint_range(0.5, 3.0) = 1.0;
// Five-bit colour with ordered dithering, switchable on its own.
uniform float quantize : hint_range(0.0, 1.0) = 1.0;

// Ordered dithering stays attached to the virtual framebuffer, without noise/flicker.
const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec2 uv = UV;
	// A tube is curved glass: the picture bulges outward. Overscan puts it back
	// inside the frame -- the corners are the furthest point, so dividing by
	// their own stretch lands them exactly on the edge. The bulge shows, the
	// edges crop, and no black border is left around the picture.
	if (curve > 0.0) {
		vec2 centered = uv * 2.0 - 1.0;
		centered *= 1.0 + curve * 0.22 * dot(centered, centered);
		centered /= 1.0 + curve * 0.44;
		uv = centered * 0.5 + 0.5;
	}
	vec2 pixel = min(floor(uv * virtual_resolution), virtual_resolution - 1.0);
	vec2 snapped_uv = (pixel + 0.5) / virtual_resolution;
	// Sample only inside this composition, including when the window has black bars.
	vec2 sample_uv = screen_origin + snapped_uv * screen_span;
	vec3 color = min(textureLod(screen_texture, sample_uv, 0.0).rgb * gain, vec3(1.0));
	if (quantize > 0.0) {
		int index = int(mod(pixel.x, 4.0)) + int(mod(pixel.y, 4.0)) * 4;
		float threshold = (BAYER[index] + 0.5) / 16.0 - 0.5;
		color = floor(clamp(color + threshold * (0.85 / 31.0), 0.0, 1.0) * 31.0 + 0.5) / 31.0;
	}
	// One dark band per virtual row: the gap the electron beam left behind.
	if (scanline > 0.0) {
		color *= 1.0 - scanline * (0.5 - 0.5 * cos(6.2831853 * uv.y * scanline_rows));
	}
	// Aperture grille on the virtual pixel columns, so the stripes scale with
	// the framebuffer instead of changing width with the window.
	if (grille > 0.0) {
		vec3 tint = vec3(0.72);
		tint[int(mod(pixel.x, 3.0))] = 1.0;
		color *= mix(vec3(1.0), tint, grille);
	}
	if (vignette > 0.0) {
		vec2 centered = uv * 2.0 - 1.0;
		color *= 1.0 - vignette * dot(centered * centered, centered * centered);
	}
	COLOR = vec4(color, 1.0);
}
