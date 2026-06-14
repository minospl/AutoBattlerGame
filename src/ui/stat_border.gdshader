shader_type canvas_item;

uniform vec2 size;
uniform float border_width = 1.0; // border thickness in virtual pixels
uniform float corner_radius = 2.0; // corner radius in virtual pixels
uniform vec4 border_color : source_color = vec4(0.12, 0.12, 0.13, 1.0);
uniform vec4 bg_color : source_color = vec4(0.92, 0.22, 0.38, 1.0);
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
    
    // Work in virtual pixel units relative to the edge
    vec2 vp = ap / pixel_scale;
    vec2 vb = b / pixel_scale;
    
    // Compute distance to rounded box
    vec2 q = vp - vb + vec2(corner_radius);
    float dist = length(max(q, vec2(0.0))) - corner_radius;
    
    // If inside the central non-rounded region, use standard box distance
    if (max(q.x, q.y) < 0.0) {
        dist = max(vp.x - vb.x, vp.y - vb.y);
    }
    
    // Render layers
    if (dist > 0.0) {
        // Cut-out corner area
        discard;
    }
    else if (dist >= -border_width) {
        // Border area
        COLOR = border_color;
    }
    else {
        // Interior background
        COLOR = bg_color;
    }
}
