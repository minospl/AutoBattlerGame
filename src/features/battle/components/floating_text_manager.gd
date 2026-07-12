class_name FloatingTextManager
extends Control

@export var pool_size: int = 30

var _inactive_pool: Array[FloatingText] = []

func _ready() -> void:
	_inactive_pool = []
	for i: int in range(pool_size):
		var popup: FloatingText = FloatingText.new()
		popup.visible = false
		popup.finished.connect(func(inst: FloatingText) -> void: _on_popup_finished(inst))
		add_child(popup)
		_inactive_pool.append(popup)

## Spawns or recycles a floating text popup from the object pool
func show_popup(p_text: String, p_color: Color, p_spawn_pos: Vector2) -> void:
	var popup: FloatingText
	if not _inactive_pool.is_empty():
		popup = _inactive_pool.pop_back()
	else:
		# Dynamically expand pool if empty under heavy combat load
		popup = FloatingText.new()
		popup.finished.connect(func(inst: FloatingText) -> void: _on_popup_finished(inst))
		add_child(popup)
		
	# Apply random offset for premium visual presentation
	var offset_x: float = randf_range(-30.0, 30.0)
	var offset_y: float = randf_range(-20.0, 20.0)
	var final_pos: Vector2 = p_spawn_pos + Vector2(offset_x, offset_y) - Vector2(50.0, 15.0)
		
	# Make it visible and run the pop/float animation
	popup.visible = true
	popup.setup(p_text, p_color, final_pos)

func _on_popup_finished(popup: FloatingText) -> void:
	popup.visible = false
	_inactive_pool.append(popup)
