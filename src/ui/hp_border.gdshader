shader_type canvas_item;

uniform vec2 size;
uniform float fill_percentage : hint_range(0.0, 1.0) = 1.0;
uniform float pixel_scale = 2.0; // size of 1 virtual pixel in screen pixels

uniform vec4 outer_color : source_color = vec4(0.08, 0.08, 0.09, 1.0); // black outline
uniform vec4 middle_color : source_color = vec4(0.85, 0.86, 0.88, 1.0); // light gray
uniform vec4 inner_color : source_color = vec4(0.08, 0.08, 0.09, 1.0); // black inner outline
uniform vec4 light_red : source_color = vec4(0.92, 0.23, 0.23, 1.0); // top half red
uniform vec4 dark_red : source_color = vec4(0.71, 0.15, 0.15, 1.0); // bottom half red
uniform vec4 bg_color : source_color = vec4(0.06, 0.07, 0.08, 1.0); // depleted background

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
    
    if (vx < 0 || vy < 0) {
        discard;
    }
    
    // 2. Apply pixel-perfect corner cuts and coloring overrides
    if (vx == 0 && vy == 0) {
        discard;
    }
    else if (vx == 1 && vy == 1) {
        COLOR = outer_color;
    }
    else if (vx == 2 && vy == 2) {
        COLOR = middle_color;
    }
    else if (vx == 3 && vy == 3) {
        COLOR = inner_color;
    }
    else if (vx < 1 || vy < 1) {
        COLOR = outer_color;
    }
    else if (vx < 2 || vy < 2) {
        COLOR = middle_color;
    }
    else if (vx < 3 || vy < 3) {
        COLOR = inner_color;
    }
    else {
        // Interior: progress bar fill
        float interior_width = virtual_size.x - 6.0 * pixel_scale;
        float x_rel = p.x - (-b.x) - 3.0 * pixel_scale;
        float x_ratio = x_rel / interior_width;
        
        if (x_ratio < fill_percentage) {
            // Fill: Red (top half lighter, bottom half darker)
            if (p.y < 0.0) {
                COLOR = light_red;
            } else {
                COLOR = dark_red;
            }
        } else {
            // Depleted background
            COLOR = bg_color;
        }
    }
}
