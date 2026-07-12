extends Label
class_name FloatingText

signal finished(instance: FloatingText)

var _active_tween: Tween

func _ready() -> void:
	# Layout settings
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override(&"font_size", 20)
	
	# Add dark outline for premium contrast on any background
	add_theme_color_override(&"font_outline_color", Color(0.12, 0.12, 0.13))
	add_theme_constant_override(&"outline_size", 5)
	
	# Ensure initial size is set to avoid layout jump on pivot recalculation
	custom_minimum_size = Vector2(100.0, 30.0)
	size = Vector2(100.0, 30.0)
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)

func setup(p_text: String, p_color: Color, p_start_pos: Vector2) -> void:
	text = p_text
	add_theme_color_override(&"font_color", p_color)
	global_position = p_start_pos
	
	# Reset visual properties for pooling reuse
	scale = Vector2(0.5, 0.5)
	modulate.a = 1.0
	
	# Kill previous tween if it was active
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	# Start parallel tween animation
	_active_tween = create_tween().set_parallel(true)
	
	# 1. Scale pop tween (0.5 -> 1.2 -> 1.0)
	_active_tween.tween_property(self, ^"scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(self, ^"scale", Vector2(1.0, 1.0), 0.1).set_delay(0.15)
	
	# 2. Float up tween (moves 60px upwards)
	_active_tween.tween_property(self, ^"global_position:y", p_start_pos.y - 60.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Fade out tween (linear fade to 0 opacity)
	_active_tween.tween_property(self, ^"modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# Emit signal on finished to return to pool
	_active_tween.finished.connect(func() -> void:
		finished.emit(self)
	)
