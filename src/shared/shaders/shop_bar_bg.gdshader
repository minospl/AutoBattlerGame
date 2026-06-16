shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.00, 0.44, 0.77, 1.0); // Darker blue
uniform vec4 bottom_color : source_color = vec4(0.00, 0.69, 0.95, 1.0); // Lighter blue
uniform vec4 line_color : source_color = vec4(1.00, 1.00, 1.00, 0.20); // Semi-transparent white
uniform vec2 size;

void fragment() {
	// Gradient
	vec4 col = mix(top_color, bottom_color, UV.y);
	
	// Draw horizontal stripe accents in the center
	float y_pixel = UV.y * size.y;
	float center_y = size.y * 0.5;
	float diff = abs(y_pixel - center_y);
	
	// 4 lines with 6px spacing: offsets -9, -3, 3, 9
	bool is_line = false;
	if (abs(diff - 9.0) < 1.0 || abs(diff - 3.0) < 1.0) {
		is_line = true;
	}
	
	if (is_line) {
		col = mix(col, line_color, line_color.a);
	}
	
	COLOR = col;
}
