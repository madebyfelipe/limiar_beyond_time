shader_type canvas_item;

uniform float zoom = 1.0;
uniform vec2 focus = vec2(0.5);

void fragment() {
	vec4 plate = texture(TEXTURE, (UV - vec2(0.5)) / zoom + focus);
	// The generated black matte contains occasional RGB 1 pixels.
	if (max(plate.r, max(plate.g, plate.b)) <= 1.001 / 255.0) {
		plate.rgb = vec3(0.0);
	}
	COLOR = plate;
}
