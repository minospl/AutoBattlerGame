shader_type canvas_item;

uniform vec2 size;
uniform int border_width = 4; // border width
uniform int border_indentation = 3; // border indentation
uniform vec4 border_color : source_color = vec4(0.57, 0.58, 0.65, 1.0); // border color
uniform vec4 interior_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // interior background color (transparent by default)
uniform vec4 corner_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // color to fill cut corners

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
    
    
    int min_cut_val = 0;
	int max_cut_val = border_indentation;
    int min_inner_fill_val = border_indentation;
	int max_inner_fill_val = border_indentation + border_indentation;
	
	if (vx >= min_cut_val && vx <= max_cut_val && vy >= min_cut_val && vy <= max_cut_val) { // cut outer edge
		if (corner_color.a > 0.0) {
			COLOR = corner_color;
		} else {
			discard;
		}
	}
	else if (vx >= min_inner_fill_val && vx <= max_inner_fill_val && vy >= min_inner_fill_val && vy <= max_inner_fill_val) { // fill inner edge
    	COLOR = border_color;
	}
    else if (vx < border_width || vy < border_width) { // Border area
        COLOR = border_color;
    }
    else { // Interior: transparent (discard) or solid background
        if (interior_color.a > 0.0) {
            COLOR = interior_color;
        } else {
            discard;
        }
    }
}
