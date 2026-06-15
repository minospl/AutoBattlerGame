shader_type canvas_item;

uniform vec2 size;
uniform float border_width = 3.0; // border width (in screen pixels)
uniform vec4 border_color : source_color = vec4(0.57, 0.58, 0.65, 1.0); // border color
uniform vec4 interior_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // interior background color (transparent by default)

void fragment() {
    // Quantize size to ensure symmetry on the pixel grid
    vec2 virtual_size = floor(size);
    vec2 b = virtual_size * 0.5;
    
    // Normalize coordinates relative to the center
    vec2 p = (UV - 0.5) * size;
    
    // Snap coordinate to pixel centers
    p = floor(p) + vec2(0.5);
    vec2 ap = abs(p);
    
    // Check if pixel is outside the main boundaries
    if (ap.x > b.x || ap.y > b.y) {
        discard;
    }
    
    // Calculate pixel coordinates from the nearest edge (0-indexed)
    int vx = int(floor(b.x - ap.x));
    int vy = int(floor(b.y - ap.y));
    
    if (vx < 0 || vy < 0) {
        discard;
    }
    
    int W = int(border_width);
    
    // Apply pixel-perfect corner cuts (1 pixel cut)
    if (vx == 0 && vy == 0) {
        discard;
    }
    else if (vx < W || vy < W) { // Border area
        COLOR = border_color;
    }
    else { // Interior
        if (interior_color.a > 0.0) {
            COLOR = interior_color;
        } else {
            discard;
        }
    }
}
