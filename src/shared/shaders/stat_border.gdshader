shader_type canvas_item;

uniform vec2 size;
uniform vec4 bg_color : source_color = vec4(0.92, 0.22, 0.38, 1.0);
uniform vec4 border_color : source_color = vec4(0.32, 0.32, 0.32, 1.0);
uniform float pixel_scale = 2.0; // size of 1 virtual pixel in screen pixels

void fragment() {
    // Quantize size to ensure perfect symmetry on the virtual pixel grid
    vec2 virtual_size = floor(size / pixel_scale) * pixel_scale;
    vec2 b = virtual_size * 0.5;
    
    // Normalize coordinates relative to the center
    vec2 p = (UV - 0.5) * size;
    
    // Snap coordinate to virtual pixel centers
    p = floor(p / pixel_scale) * pixel_scale + vec2(pixel_scale * 0.5);
    vec2 ap = abs(p);
    
    // Check if pixel is outside the main boundaries
    if (ap.x > b.x || ap.y > b.y) {
        discard;
    }
	
    // 1. Calculate virtual pixel coordinates from the nearest edge (0-indexed)
    int vx = int(floor((b.x - ap.x) / pixel_scale));
    int vy = int(floor((b.y - ap.y) / pixel_scale));
	
    // 2. Apply pixel-perfect corner cuts and coloring overrides
	if (vx == 0 && vy == 0) {
        discard;
    }
    else if (vx == 1 && vy == 1) { // Outer border pixel in Inner border corners
		COLOR = border_color;
    }
    else if (vx < 1 || vy < 1) { // General outer border area: gray-blue (color1)
        COLOR = border_color;
    }
    else { // Interior: transparent (discard) or solid background
        if (bg_color.a > 0.0) {
            COLOR = bg_color;
        } else {
            discard;
        }
    }
}
