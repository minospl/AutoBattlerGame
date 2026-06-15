shader_type canvas_item;

uniform vec2 size;
uniform int outer_border_width = 3; // border width
uniform int inner_border_width = 3; // border width
uniform int outer_border_indentation = 3; // border indentation
uniform int inner_border_indentation = 3; // border indentation
uniform vec4 outer_border_color : source_color = vec4(0.57, 0.58, 0.65, 1.0); // outer border color
uniform vec4 inner_border_color : source_color = vec4(0.89, 0.90, 0.92, 1.0); // inner border color
uniform vec4 interior_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // interior background color (transparent by default)
uniform vec4 corner_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // color to fill cut corners

void fragment() {
    vec2 size_i = round(size);
    int w = int(size_i.x);
    int h = int(size_i.y);
    int x = clamp(int(floor(UV.x * size_i.x)), 0, w - 1);
    int y = clamp(int(floor(UV.y * size_i.y)), 0, h - 1);
    
    int vx = min(x, w - 1 - x);
    int vy = min(y, h - 1 - y);
    
    // 1. Outer corner cut (filled with corner_color or discarded)
    if (vx >= 0 && vx <= outer_border_indentation && vy >= 0 && vy <= outer_border_indentation) {
        if (corner_color.a > 0.0) COLOR = corner_color;
        else discard;
    }
    // 2. Outer border inner corner fill
    else if (vx >= outer_border_indentation && vx <= (outer_border_indentation * 2) && vy >= outer_border_indentation && vy <= (outer_border_indentation * 2)) {
        COLOR = outer_border_color;
    }
    // 3. Inner border outer corner cut (filled with outer_border_color)
    else if (vx >= outer_border_width && vx <= (outer_border_width + inner_border_indentation) && vy >= outer_border_width && vy <= (outer_border_width + inner_border_indentation)) {
        COLOR = outer_border_color;
    }
    // 4. Inner border inner corner fill
    else if (vx >= (outer_border_width + inner_border_indentation) && vx <= (outer_border_width + inner_border_indentation * 2) && vy >= (outer_border_width + inner_border_indentation) && vy <= (outer_border_width + inner_border_indentation * 2)) {
        COLOR = inner_border_color;
    }
    // 5. General outer border area
    else if (vx < outer_border_width || vy < outer_border_width) {
        COLOR = outer_border_color;
    }
    // 6. General inner border area
    else if (vx < (outer_border_width + inner_border_width) || vy < (outer_border_width + inner_border_width)) {
        COLOR = inner_border_color;
    }
    // 7. Interior background
    else {
        if (interior_color.a > 0.0) COLOR = interior_color;
        else discard;
    }
}
