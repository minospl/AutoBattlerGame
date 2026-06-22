extends Label
class_name FloatingText

func setup(p_text: String, p_color: Color, p_start_pos: Vector2) -> void:
	text = p_text
	add_theme_color_override(&"font_color", p_color)
	global_position = p_start_pos
	
	# Layout settings
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override(&"font_size", 20)
	custom_minimum_size = Vector2(100.0, 30.0)
	
	# Add dark outline for premium contrast on any background
	add_theme_color_override(&"font_outline_color", Color(0.12, 0.12, 0.13))
	add_theme_constant_override(&"outline_size", 5)
	
	# Dynamically keep pivot point at the center for scaling pop animation
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	
	# Start small for the zoom pop effect
	scale = Vector2(0.5, 0.5)
	
	# Optimize tweens into a single parallel tween
	var tween: Tween = create_tween().set_parallel(true)
	
	# 1. Scale pop tween (0.5 -> 1.2 -> 1.0)
	tween.tween_property(self, ^"scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"scale", Vector2(1.0, 1.0), 0.1).set_delay(0.15)
	
	# 2. Float up tween (moves 60px upwards)
	tween.tween_property(self, ^"global_position:y", p_start_pos.y - 60.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Fade out tween (linear fade to 0 opacity)
	tween.tween_property(self, ^"modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# Automatically clean up when the animation is finished
	tween.finished.connect(queue_free)

