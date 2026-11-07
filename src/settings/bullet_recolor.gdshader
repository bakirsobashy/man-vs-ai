// Recolors a bullet for the color-blind-safe and high-contrast palettes (GDD §8.5). The art's brightness is kept and
// its hue replaced with `tint`; the node's modulate (Threat Sight's highlight) still applies on top.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	float light = max(max(art.r, art.g), art.b);
	COLOR = vec4(tint.rgb * (0.35 + 0.65 * light), art.a) * COLOR;
}
