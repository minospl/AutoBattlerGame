shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fill_color : source_color = vec4(0.18, 0.53, 0.88, 0.85);

void fragment() {
	float threshold = 1.0 - progress;
	float edge = 0.01;
	float alpha = smoothstep(threshold - edge, threshold + edge, UV.y);
	COLOR = vec4(fill_color.rgb, fill_color.a * alpha);
}
