class_name TeamPanel
extends PanelContainer

signal slot_changed(slot: MonsterSlot)

@onready var frontline_hbox: HBoxContainer = %FrontlineHBox
@onready var backline_hbox: HBoxContainer = %BacklineHBox
@onready var team_header: PanelContainer = %TeamHeader
@onready var team_label: Label = %TeamLabel

var slots: Array[MonsterSlot] = []

func _ready() -> void:
	var team_header_style = StyleBoxFlat.new()
	var team_color = GameColors.TEAM_HEADER_BG
	team_header_style.bg_color = team_color
	team_header_style.border_width_bottom = 3
	team_header_style.border_color = team_color.lightened(0.5)
	team_header_style.content_margin_bottom = 2
	team_header_style.content_margin_left = 2
	team_header.add_theme_stylebox_override("panel", team_header_style)
	
	# Label outline styling
	team_label.add_theme_color_override("font_outline_color", GameColors.LABEL_OUTLINE)
	team_label.add_theme_constant_override("outline_size", 5)

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in frontline_hbox.get_children():
		child.queue_free()
	for child in backline_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.slot_changed.connect(func(_slot): slot_changed.emit(_slot))
		
		if i < 3:
			backline_hbox.add_child(slot) # Slots 0, 1, 2 are backline
		else:
			frontline_hbox.add_child(slot) # Slots 3, 4, 5 are frontline
			
		slots.append(slot)
