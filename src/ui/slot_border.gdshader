shader_type canvas_item;

uniform vec2 size;
uniform float outer_border_width = 2.0; // outer border width (in virtual pixels)
uniform float inner_border_width = 2.0; // inner border width (in virtual pixels)
uniform float outer_corner_cut_size = 1.0; // outer corner cut-out size (in virtual pixels)
uniform float middle_corner_cut_size = 1.0; // middle corner cut-out size (in virtual pixels)
uniform float inner_corner_cut_size = 1.0; // inner corner cut-out size (in virtual pixels)
uniform vec4 outer_border_color : source_color = vec4(0.58, 0.59, 0.65, 1.0); // outer border color
uniform vec4 inner_border_color : source_color = vec4(0.89, 0.90, 0.92, 1.0); // inner border color
uniform vec4 interior_color : source_color = vec4(0.0, 0.0, 0.0, 0.0); // interior background color (transparent by default)
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
    
    // Check if pixel is outside the main slot boundaries
    if (ap.x > b.x || ap.y > b.y) {
        discard;
    }
    
    // 1. Calculate virtual pixel coordinates from the nearest edge (0-indexed)
    int vx = int(floor((b.x - ap.x) / pixel_scale));
    int vy = int(floor((b.y - ap.y) / pixel_scale));
    
    if (vx < 0 || vy < 0) {
        discard;
    }
    
    int W1 = int(outer_border_width);
    int W2 = int(inner_border_width);
    
    // 2. Apply pixel-perfect corner cuts and coloring overrides
    if (vx == 0 && vy == 0) {
        discard;
    }
    else if (vx == W1 + W2 - 2 && vy == W1 + W2 - 2) { // Outer border pixel in Inner border corners
		COLOR = outer_border_color;
    }
    else if (vx == W1 + W2 + 0 && vy == W1 + W2 + 0) { // Inner border pixel in Interior corners
		COLOR = inner_border_color;
    }
    else if (vx < W1 || vy < W1) { // General outer border area: gray-blue (color1)
        COLOR = outer_border_color;
    }
    else if (vx < W1 + W2 || vy < W1 + W2) { // General inner border area: white (color2)
        COLOR = inner_border_color;
    }
    else { // Interior: transparent (discard) or solid background
        if (interior_color.a > 0.0) {
            COLOR = interior_color;
        } else {
            discard;
        }
    }
}
