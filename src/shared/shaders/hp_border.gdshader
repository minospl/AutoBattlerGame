shader_type canvas_item;

uniform vec2 size;
uniform float fill_percentage : hint_range(0.0, 1.0) = 1.0;

uniform int outer_border_width = 2; // outer border width
uniform int middle_border_width = 2; // middle border width

uniform int outer_border_indentation = 2; // outer border indentation
uniform int middle_border_indentation = 2; // middle border indentation
uniform int interior_corner_indentation = 2; // interior corner indentation

uniform vec4 outer_color : source_color = vec4(0.08, 0.08, 0.09, 1.0); // outer border color
uniform vec4 middle_color : source_color = vec4(0.85, 0.86, 0.88, 1.0); // middle border color
uniform vec4 light_red : source_color = vec4(0.92, 0.23, 0.23, 1.0); // top half red
uniform vec4 dark_red : source_color = vec4(0.71, 0.15, 0.15, 1.0); // bottom half red
uniform vec4 bg_color : source_color = vec4(0.06, 0.07, 0.08, 1.0); // depleted background
uniform vec4 corner_color : source_color = vec4(1.0, 1.0, 1.0, 0.0); // color to fill cut corners

void fragment() {
    vec2 size_i = round(size);
    int w = int(size_i.x);
    int h = int(size_i.y);
    int x = clamp(int(floor(UV.x * size_i.x)), 0, w - 1);
    int y = clamp(int(floor(UV.y * size_i.y)), 0, h - 1);
    
    int vx = min(x, w - 1 - x);
    int vy = min(y, h - 1 - y);
    
    // 1. Outer corner cut
    if (vx >= 0 && vx <= outer_border_indentation && vy >= 0 && vy <= outer_border_indentation) {
        if (corner_color.a > 0.0) COLOR = corner_color;
        else discard;
    }
    // 2. Outer border inner corner fill
    else if (vx >= outer_border_indentation && vx <= (outer_border_indentation * 2) && vy >= outer_border_indentation && vy <= (outer_border_indentation * 2)) {
        COLOR = outer_color;
    }
    // 3. Middle border outer corner cut (filled with outer_color)
    else if (vx >= outer_border_width && vx <= (outer_border_width + middle_border_indentation) && vy >= outer_border_width && vy <= (outer_border_width + middle_border_indentation)) {
        COLOR = outer_color;
    }
    // 4. Middle border inner corner fill (filled with middle_color)
    else if (vx >= (outer_border_width + middle_border_indentation) && vx <= (outer_border_width + middle_border_indentation * 2) && vy >= (outer_border_width + middle_border_indentation) && vy <= (outer_border_width + middle_border_indentation * 2)) {
        COLOR = middle_color;
    }
    // 5. Interior outer corner cut (filled with middle_color)
    else if (vx >= (outer_border_width + middle_border_width) && vx <= (outer_border_width + middle_border_width + interior_corner_indentation) && vy >= (outer_border_width + middle_border_width) && vy <= (outer_border_width + middle_border_width + interior_corner_indentation)) {
        COLOR = middle_color;
    }
    // 6. General outer border area
    else if (vx < outer_border_width || vy < outer_border_width) {
        COLOR = outer_color;
    }
    // 7. General middle border area
    else if (vx < (outer_border_width + middle_border_width) || vy < (outer_border_width + middle_border_width)) {
        COLOR = middle_color;
    }
    // 8. Interior background and progress bar fill
    else {
        int border_offset = outer_border_width + middle_border_width;
        float interior_width = float(w - 2 * border_offset);
        float x_rel = float(x - border_offset) + 0.5;
        float x_ratio = x_rel / interior_width;
        
        if (x_ratio < fill_percentage) {
            // Fill: Red (top half lighter, bottom half darker)
            if (UV.y < 0.5) {
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
