shader_type canvas_item;
// Pixel-stepped water shimmer: shifts the lookup in whole texels along slow
// sine waves and adds drifting highlight glints. Keeps pixel art crisp.
uniform float speed = 1.0;

void fragment() {
	vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
	float t = TIME * speed;
	vec2 cell = floor(UV / px);
	float sx = floor(sin(cell.y * 0.35 + t * 1.6) * 1.5);
	float sy = floor(sin(cell.x * 0.27 + t * 1.1) * 1.0);
	vec4 c = texture(TEXTURE, UV + vec2(sx, sy) * px);
	float glint = step(0.985, fract(sin(dot(floor((UV / px + vec2(t * 3.0, 0.0)) / 3.0), vec2(12.9898, 78.233))) * 43758.5453));
	c.rgb = mix(c.rgb, vec3(0.85, 0.95, 1.0), glint * 0.6);
	COLOR = vec4(c.rgb, c.a);
}
