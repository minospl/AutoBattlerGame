class_name MonsterSlot
extends PanelContainer

## Signal emitted when the card inside this slot changes (added, removed, swapped)
signal slot_changed(slot: MonsterSlot)

## If true, this slot is part of the active combat team. If false, it is on the bench.
@export var is_active_team: bool = false

## Index of the slot in the respective team/bench array
@export var slot_index: int = 0

var is_highlighted: bool = false

func _ready() -> void:
	# Define a clean style box for the empty slot (flat design)
	var empty_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty_style)
	
	# Create and add a ColorRect to draw our custom pixel-perfect slot borders via shader
	var border_rect = ColorRect.new()
	border_rect.name = "BorderRect"
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Full rect layout
	border_rect.layout_mode = 1
	border_rect.anchors_preset = Control.PRESET_FULL_RECT
	border_rect.offset_left = 0
	border_rect.offset_top = 0
	border_rect.offset_right = 0
	border_rect.offset_bottom = 0
	
	# Load and assign the shader material
	var shader = load("res://src/ui/slot_border.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Set size uniform to match our custom minimum size
	shader_material.set_shader_parameter("size", custom_minimum_size)
	
	# Colors matching the reference image:
	# outer_border_color (outer): gray-blue #9194a6 (0.57, 0.58, 0.65)
	# inner_border_color (inner): light gray #e1e3e8 (0.88, 0.89, 0.91)
	shader_material.set_shader_parameter("outer_border_color", Color(0.57, 0.58, 0.65, 1.0))
	shader_material.set_shader_parameter("inner_border_color", Color(0.88, 0.89, 0.91, 1.0))
	
	border_rect.material = shader_material
	add_child(border_rect)
	move_child(border_rect, 0) # Make sure it is drawn behind other elements (like the card)
	
	# Support dynamic resizing for scaling/monitors
	resized.connect(func():
		if border_rect and border_rect.material:
			border_rect.material.set_shader_parameter("size", size)
	)
	
	# Connect tree notifications to toggle placeholder visibility and border visibility
	child_entered_tree.connect(func(_node): update_placeholder.call_deferred())
	child_exiting_tree.connect(func(_node): update_placeholder.call_deferred())
	update_placeholder()

func update_style(is_hovered: bool = false) -> void:
	is_highlighted = is_hovered
	var border_rect = get_node_or_null("BorderRect")
	if not border_rect or not border_rect.material:
		return
		
	var mat = border_rect.material as ShaderMaterial
	if is_hovered:
		# Hover state highlight
		mat.set_shader_parameter("outer_border_color", Color(0.259, 0.614, 0.282, 1.0)) # blue border
		mat.set_shader_parameter("inner_border_color", Color(0.718, 0.99, 0.721, 1.0)) # light gray inner border
	else:
		# Normal state:
		mat.set_shader_parameter("outer_border_color", Color(0.57, 0.58, 0.65, 1.0)) # gray-blue border
		mat.set_shader_parameter("inner_border_color", Color(0.88, 0.89, 0.91, 1.0)) # light gray inner border

func update_placeholder() -> void:
	var empty = is_empty()
	if has_node("EmptyPlaceholderLabel"):
		$EmptyPlaceholderLabel.visible = empty
		
	var border_rect = get_node_or_null("BorderRect")
	if border_rect:
		border_rect.visible = empty
		
	update_style()

func _process(_delta: float) -> void:
	if is_highlighted and get_viewport().gui_is_dragging():
		var mouse_pos = get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, size)
		if not rect.has_point(mouse_pos):
			update_style(false)

# Determine if we can drop a dragged item onto this slot
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("card"):
		# Highlight the slot to show it is a valid target
		update_style(true)
		return true
	return false

# Handle cleanup when drag drops elsewhere, leaves the slot, or is canceled
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Restore proper style based on slot occupancy
		update_style(false)

# Handle drop execution
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	update_style(false)
	
	var dragged_card: MonsterCard = data["card"]
	var original_slot: MonsterSlot = data["original_slot"]
	
	if original_slot == self:
		return # Dropped on itself
		
	var current_card: MonsterCard = get_card()
	
	if current_card:
		# SWAP logic: Swap the parent slots of the two cards
		remove_child(current_card)
		original_slot.remove_child(dragged_card)
		
		add_child(dragged_card)
		original_slot.add_child(current_card)
	else:
		# MOVE logic: Move card from original slot to this empty slot
		original_slot.remove_child(dragged_card)
		add_child(dragged_card)
		
	# Emit signals
	slot_changed.emit(self)
	original_slot.slot_changed.emit(original_slot)

## Returns the MonsterCard child node of this slot, if any. Otherwise returns null.
func get_card() -> MonsterCard:
	for child in get_children():
		if child is MonsterCard:
			return child
	return null

## Check if slot is empty
func is_empty() -> bool:
	return get_card() == null

## Returns the MonsterInstance from the card in this slot, or null
func get_monster_instance() -> MonsterInstance:
	var card = get_card()
	return card.monster_instance if card else null
