shader_type canvas_item;
// Shows a smaller rectangle of the authored frame, matching the camera frustum
// of a cropped shot. zoom 1.0 with focus at the centre is the identity.

uniform float zoom = 1.0;
uniform vec2 focus = vec2(0.5);

void fragment() {
	COLOR = texture(TEXTURE, (UV - vec2(0.5)) / zoom + focus);
}
