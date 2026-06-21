extends Label
class_name FloatingText

func _ready() -> void:
	# Add dark outline for premium contrast on any background
	add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.13))
	add_theme_constant_override("outline_size", 5)
	
	# Dynamically keep pivot point at the center for scaling pop animation
	resized.connect(func(): pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	
	# Start small for the zoom pop effect
	scale = Vector2(0.5, 0.5)
	
	# 1. Scale pop tween (0.5 -> 1.2 -> 1.0)
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 2. Float up tween (moves 60px upwards)
	var move_tween = create_tween()
	move_tween.tween_property(self, "global_position:y", global_position.y - 60, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Fade out tween (linear fade to 0 opacity)
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# Automatically clean up when the animation is finished
	fade_tween.finished.connect(queue_free)
