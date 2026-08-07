class_name BattleTeamPanel
extends VBoxContainer

signal floating_text_spawn_requested(text: String, color: Color, position: Vector2)

@export var mirrored: bool = false:
	set(val):
		mirrored = val
		if is_node_ready():
			_apply_row_offsets()

@export var row_offset: int = 24

@onready var health_bar: HealthBar = %HealthBar
@onready var status_hbox: HBoxContainer = %StatusHBox
@onready var top_row_margin: MarginContainer = %TopRowMargin
@onready var bottom_row_margin: MarginContainer = %BottomRowMargin
@onready var slot_0: BattleCardSlot = %Slot0
@onready var slot_1: BattleCardSlot = %Slot1
@onready var slot_2: BattleCardSlot = %Slot2
@onready var slot_3: BattleCardSlot = %Slot3
@onready var slot_4: BattleCardSlot = %Slot4
@onready var slot_5: BattleCardSlot = %Slot5

var slots: Array[BattleCardSlot] = []
var status_badges: Dictionary[String, StatusBadge] = {}

func _ready() -> void:
	slots = [slot_0, slot_1, slot_2, slot_3, slot_4, slot_5]
			
	if mirrored and status_hbox:
		status_hbox.alignment = BoxContainer.ALIGNMENT_END

	_apply_row_offsets()

func _apply_row_offsets() -> void:
	if mirrored:
		top_row_margin.add_theme_constant_override("margin_left", row_offset)
		top_row_margin.add_theme_constant_override("margin_right", 0)
		bottom_row_margin.add_theme_constant_override("margin_left", 0)
		bottom_row_margin.add_theme_constant_override("margin_right", row_offset)
	else:
		top_row_margin.add_theme_constant_override("margin_left", 0)
		top_row_margin.add_theme_constant_override("margin_right", row_offset)
		bottom_row_margin.add_theme_constant_override("margin_left", row_offset)
		bottom_row_margin.add_theme_constant_override("margin_right", 0)

## Binds this panel to a logical BattleTeamModel and connects all signal updates
func setup_model(team_model: BattleTeamModel) -> void:
	# 1. Clear status badges from previous runs
	for child: Node in status_hbox.get_children():
		child.queue_free()
	status_badges.clear()
	
	# 2. Reset health bar display
	health_bar.update_health(1, 1, 0)
	
	# 3. Connect signals
	team_model.health_changed.connect(func(curr: int, max_hp: int, sh: int) -> void:
		health_bar.update_health(curr, max_hp, sh)
	)
	
	team_model.status_changed.connect(func(type: String, amt: int, rat: float) -> void:
		_on_status_changed(type, amt, rat)
	)
	
	team_model.cast_progress_changed.connect(func(slot_idx: int, rat: float) -> void:
		_on_cast_progress_changed(slot_idx, rat)
	)
	
	team_model.floating_text_requested.connect(func(txt: String, col: Color, target: BattleTeamModel.SpawnTarget, key: Variant) -> void:
		_on_floating_text_requested(txt, col, target, key)
	)

func _on_status_changed(status_type: String, amount: int, ratio: float) -> void:
	if amount > 0:
		var badge: StatusBadge = status_badges.get(status_type)
		if badge == null:
			badge = StatusBadge.new()
			badge.status_type = status_type
			status_hbox.add_child(badge)
			status_badges[status_type] = badge
		badge.value = amount
		badge.cooldown_ratio = ratio
	else:
		var badge: StatusBadge = status_badges.get(status_type)
		if badge != null:
			badge.queue_free()
			status_badges.erase(status_type)

func _on_cast_progress_changed(slot_idx: int, ratio: float) -> void:
	if slot_idx >= 0 and slot_idx < slots.size():
		slots[slot_idx].set_cast_progress(ratio)

func _on_floating_text_requested(text: String, color: Color, target: BattleTeamModel.SpawnTarget, key: Variant) -> void:
	var spawn_pos: Vector2 = _get_target_position(target, key)
	if spawn_pos != Vector2.ZERO:
		floating_text_spawn_requested.emit(text, color, spawn_pos)

func _get_target_position(target: BattleTeamModel.SpawnTarget, key: Variant) -> Vector2:
	match target:
		BattleTeamModel.SpawnTarget.SLOT:
			var slot_idx: int = key
			if slot_idx >= 0 and slot_idx < slots.size():
				var slot: BattleCardSlot = slots[slot_idx]
				return slot.global_position + slot.size / 2.0
		BattleTeamModel.SpawnTarget.TEAM_HEALTH_BAR:
			if health_bar:
				return health_bar.global_position + health_bar.size / 2.0
		BattleTeamModel.SpawnTarget.SHIELD:
			if health_bar:
				var pos_x: float = 0.0
				if not mirrored:
					pos_x = health_bar.size.x
				return health_bar.global_position + Vector2(pos_x, health_bar.size.y / 2.0)
	return Vector2.ZERO
