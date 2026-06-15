shader_type canvas_item;

// The color to make transparent (defaults to pure white)
uniform vec4 key_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Sensitivity tolerance for color matching
uniform float tolerance : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// If the pixel color is close to the key color, make it fully transparent
	if (distance(col.rgb, key_color.rgb) < tolerance) {
		col.a = 0.0;
	}
	COLOR = col;
}
