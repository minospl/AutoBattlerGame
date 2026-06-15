shader_type canvas_item;

uniform vec2 size;
uniform int border_width = 4; // border width
uniform int border_indentation = 3; // border indentation
uniform vec4 border_color : source_color = vec4(0.57, 0.58, 0.65, 1.0); // border color
uniform vec4 interior_color : source_color = vec4(1.0, 1.0, 1.0, 0); // interior background color (transparent by default)
uniform vec4 corner_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // color to fill cut corners

void fragment() {
    vec2 size_i = round(size);
    int w = int(size_i.x);
    int h = int(size_i.y);
    int x = clamp(int(floor(UV.x * size_i.x)), 0, w - 1);
    int y = clamp(int(floor(UV.y * size_i.y)), 0, h - 1);
    
    int vx = min(x, w - 1 - x);
    int vy = min(y, h - 1 - y);
    
    int min_cut_val = 0;
	int max_cut_val = border_indentation;
    int min_inner_fill_val = border_width;
	int max_inner_fill_val = border_width + border_indentation;
	
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
