shader_type canvas_item;

uniform vec2 size = vec2(16.0, 16.0);

void fragment() {
	vec2 grid = floor(UV * size);
	int x = int(grid.x);
	int y = int(grid.y);
	
	int w = int(size.x);
	int h = int(size.y);
	
	vec4 final_color = vec4(0.0);
	if (x >= w / 2 && x < w) {
		float den = float(max(w / 2 - 1, 1));
		int dy = (h / 2) - 1 - int(float(x - w / 2) * float(h / 2 - 1) / den);
		if (y >= dy && y <= (h - 1) - dy) {
			final_color = COLOR;
		}
	}
	
	COLOR = final_color;
}
