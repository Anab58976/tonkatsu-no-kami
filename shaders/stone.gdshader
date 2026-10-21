shader_type canvas_item;
// Turns a sprite into weathered stone: luminance-mapped grey with moss in the
// darkest crevices. Used for the Rei Porco statue in the plaza.
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.3, 0.55, 0.15));
	vec3 stone = mix(vec3(0.33, 0.31, 0.29), vec3(0.86, 0.83, 0.77), smoothstep(0.1, 0.9, l));
	stone = floor(stone * 8.0) / 8.0;
	if (l < 0.22) stone = mix(stone, vec3(0.35, 0.45, 0.25), 0.5);
	COLOR = vec4(stone, c.a);
}
