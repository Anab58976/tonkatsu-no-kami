shader_type canvas_item;
// Mixes the sprite toward a solid colour while keeping its alpha (magic glow,
// hit flash, transformation silhouette). `flash` 0 = untouched, 1 = solid.
uniform vec4 flash_color : source_color = vec4(1.0, 0.92, 0.6, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash), c.a) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
