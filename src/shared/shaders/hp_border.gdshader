shader_type canvas_item;

uniform vec2 size;
uniform float fill_percentage : hint_range(0.0, 1.0) = 1.0;

uniform vec4 outer_color : source_color = vec4(0.08, 0.08, 0.09, 1.0); // black outline
uniform vec4 middle_color : source_color = vec4(0.85, 0.86, 0.88, 1.0); // light gray
uniform vec4 inner_color : source_color = vec4(0.08, 0.08, 0.09, 1.0); // black inner outline
uniform vec4 light_red : source_color = vec4(0.92, 0.23, 0.23, 1.0); // top half red
uniform vec4 dark_red : source_color = vec4(0.71, 0.15, 0.15, 1.0); // bottom half red
uniform vec4 bg_color : source_color = vec4(0.06, 0.07, 0.08, 1.0); // depleted background

void fragment() {
    vec2 size_i = round(size);
    int w = int(size_i.x);
    int h = int(size_i.y);
    int x = clamp(int(floor(UV.x * size_i.x)), 0, w - 1);
    int y = clamp(int(floor(UV.y * size_i.y)), 0, h - 1);
    
    int vx = min(x, w - 1 - x);
    int vy = min(y, h - 1 - y);
    
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
        float interior_width = float(w - 6);
        float x_rel = float(x - 3) + 0.5;
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
