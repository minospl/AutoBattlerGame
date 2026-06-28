class_name BattleScene
extends Control

signal battle_finished
var run_state: RunState

# Static Preloads
const CARD_TOOLTIP_SCENE: PackedScene = preload("res://src/shared/ui/components/card_tooltip.tscn")
const HP_BORDER_SHADER: Shader = preload("res://src/shared/shaders/hp_border.gdshader")
const SHOP_BACKGROUND_TEXTURE: Texture2D = preload("res://src/assets/ui/shop_background.jpg")
const RIVER_CRAB_RES: UnitData = preload("res://src/features/units/templates/river_crab.tres")
const BATTLE_CARD_SCENE: PackedScene = preload("res://src/features/battle/components/battle_card.tscn")

const MAX_TEAM_SIZE: int = 6

enum State { PLAYING, PAUSED }
var simulation_state: State = State.PAUSED

var player_team: BattleTeam
var enemy_team: BattleTeam

var game_speed: float = 1.0
var preview_tooltip: CardTooltip
var team_hp_material: ShaderMaterial
var enemy_hp_material: ShaderMaterial



# Countdown Timer & Fatigue
var match_timer: float = 30.0
var fatigue_tick_timer: float = 0.0
var fatigue_tick_count: int = 0

# Slot References
var player_slots: Array[BattleCardSlot] = []
var enemy_slots: Array[BattleCardSlot] = []

# Cached Node References
@onready var exit_button: Button = %ExitButton
@onready var play_button: Button = %PlayButton
@onready var pause_button: Button = %PauseButton
@onready var speed_button: Button = %SpeedButton
@onready var preview_container: Control = %PreviewContainer
@onready var outer_border: ColorRect = %OuterBorder
@onready var timer_container: Control = %TimerContainer
@onready var timer_label: Label = %TimerLabel

@onready var team_health_bar_rect: Control = %TeamHealthBarRect
@onready var enemy_health_bar_rect: Control = %EnemyHealthBarRect
@onready var team_health_label: Label = %TeamHealthLabel
@onready var enemy_health_label: Label = %EnemyHealthLabel

@onready var team_status_hbox: Control = %TeamStatusHBox
@onready var enemy_status_hbox: Control = %EnemyStatusHBox

@onready var team_poison_badge: StatusBadge = %TeamPoisonBadge
@onready var team_burn_badge: StatusBadge = %TeamBurnBadge
@onready var team_electrocute_badge: StatusBadge = %TeamElectrocuteBadge

@onready var enemy_poison_badge: StatusBadge = %PoisonBadge
@onready var enemy_burn_badge: StatusBadge = %BurnBadge
@onready var enemy_electrocute_badge: StatusBadge = %ElectrocuteBadge

func _ready() -> void:
	# Add the tooltip instance to PreviewContainer
	if preview_container:
		preview_tooltip = CARD_TOOLTIP_SCENE.instantiate() as CardTooltip
		preview_tooltip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		preview_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		preview_container.add_child(preview_tooltip)
		preview_tooltip.visible = false

	if exit_button: exit_button.pressed.connect(_on_exit_pressed)
	if play_button: play_button.pressed.connect(_on_play_pressed)
	if pause_button: pause_button.pressed.connect(_on_pause_pressed)
	if speed_button: speed_button.pressed.connect(_on_speed_pressed)

	# Fetch slots
	player_slots = [
		%Slot0, %Slot1, %Slot2,
		%Slot3, %Slot4, %Slot5
	]
	for i: int in range(MAX_TEAM_SIZE):
		player_slots[i].slot_index = i

	# Fetch enemy slots
	enemy_slots = [
		%EnemySlot0, %EnemySlot1, %EnemySlot2,
		%EnemySlot3, %EnemySlot4, %EnemySlot5
	]
	for i: int in range(MAX_TEAM_SIZE):
		enemy_slots[i].slot_index = i

	# Configure HP border shaders
	team_hp_material = _configure_hp_bar_shader(team_health_bar_rect)
	enemy_hp_material = _configure_hp_bar_shader(enemy_health_bar_rect)

	# Create BattleTeam instances
	player_team = BattleTeam.new()
	enemy_team = BattleTeam.new()
	
	# Connect signals from player_team
	player_team.team_units_loaded.connect(_on_units_loaded.bind(player_slots))
	player_team.health_changed.connect(_on_health_changed.bind(team_hp_material, team_health_label))
	player_team.status_changed.connect(_on_status_changed.bind(
		{
			"poison": team_poison_badge,
			"burn": team_burn_badge,
			"electrocute": team_electrocute_badge
		},
		team_status_hbox
	))
	player_team.cast_progress_changed.connect(_on_cast_progress_changed.bind(player_slots))
	player_team.floating_text_requested.connect(func(text: String, color: Color, is_on_slot: bool, slot_idx: int) -> void:
		_on_floating_text_requested(false, text, color, is_on_slot, slot_idx)
	)
	player_team.team_defeated.connect(_on_team_defeat)

	# Connect signals from enemy_team
	enemy_team.team_units_loaded.connect(_on_units_loaded.bind(enemy_slots))
	enemy_team.health_changed.connect(_on_health_changed.bind(enemy_hp_material, enemy_health_label))
	enemy_team.status_changed.connect(_on_status_changed.bind(
		{
			"poison": enemy_poison_badge,
			"burn": enemy_burn_badge,
			"electrocute": enemy_electrocute_badge
		},
		enemy_status_hbox
	))
	enemy_team.cast_progress_changed.connect(_on_cast_progress_changed.bind(enemy_slots))
	enemy_team.floating_text_requested.connect(func(text: String, color: Color, is_on_slot: bool, slot_idx: int) -> void:
		_on_floating_text_requested(true, text, color, is_on_slot, slot_idx)
	)
	enemy_team.team_defeated.connect(_on_enemy_defeat)

	player_team.initialize(false)
	enemy_team.initialize(true)

	if run_state:
		setup(run_state)

func setup(p_state: RunState) -> void:
	run_state = p_state
	# Load state and backup
	load_battle_team()
	
	# Apply visual styling
	_apply_visual_styling()

	# Start battle start modifiers immediately
	trigger_battle_start()

func _configure_hp_bar_shader(hp_bar: Control) -> ShaderMaterial:
	if not hp_bar:
		return null
	var hp_material: ShaderMaterial = ShaderMaterial.new()
	hp_material.shader = HP_BORDER_SHADER
	hp_material.set_shader_parameter("fill_percentage", 1.0)
	hp_bar.material = hp_material
	
	hp_bar.resized.connect(func() -> void:
		if hp_material:
			hp_material.set_shader_parameter("size", hp_bar.size)
	)
	
	var initial_hp_size: Vector2 = hp_bar.size
	if initial_hp_size.x == 0.0:
		initial_hp_size = Vector2(340.0, 32.0)
	hp_material.set_shader_parameter("size", initial_hp_size)
	return hp_material

func _apply_visual_styling() -> void:
	# Background style
	var bg_panel: Panel = get_node_or_null("BackgroundPanel") as Panel
	if bg_panel:
		var bg_style: StyleBoxTexture = StyleBoxTexture.new()
		bg_style.texture = SHOP_BACKGROUND_TEXTURE
		bg_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.modulate_color = Color(0.3, 0.3, 0.3, 1.0) # Modulate darker for battle focus
		bg_panel.add_theme_stylebox_override("panel", bg_style)
		
	# Outer border coloring
	if outer_border:
		outer_border.color = GameColors.PANEL_BORDER_DEFAULT

func load_battle_team() -> void:
	if run_state == null:
		return

	# Copy team and make clones for the battle scene simulation
	var player_units: Array[UnitInstance] = []
	for i: int in range(MAX_TEAM_SIZE):
		var inst: UnitInstance = run_state.active_team[i]
		if inst:
			player_units.append(inst.clone())
		else:
			player_units.append(null)

	player_team.load_team_units(player_units)

	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	if timer_container:
		timer_container.visible = true
	if timer_label:
		timer_label.text = "⏳ 30.0s"
		
	load_enemy_team()

func load_enemy_team() -> void:
	var enemy_units: Array[UnitInstance] = []
	enemy_units.resize(MAX_TEAM_SIZE)

	# Load River Crab into Slot 0
	if RIVER_CRAB_RES:
		var crab_instance: UnitInstance = UnitInstance.new()
		crab_instance.initialize(RIVER_CRAB_RES)
		# Override health and attack
		crab_instance.health = 1000
		crab_instance.attack = 10
		
		enemy_units[0] = crab_instance
		
	enemy_team.load_team_units(enemy_units)

func trigger_battle_start() -> void:
	# Wait one frame to let Godot layout engine calculate slot positions
	await get_tree().process_frame
	
	for i: int in range(MAX_TEAM_SIZE):
		if player_team.units[i]:
			ModifierEngine.trigger_unit_modifier(i, player_team, UnitModifier.Trigger.ON_BATTLE_START)
					
	# Update all health and stat overlays
	_update_all_card_uis()

func trigger_cast(source_idx: int) -> void:
	player_team.execute_cast(source_idx, enemy_team)
	_update_all_card_uis()

func trigger_enemy_cast(source_idx: int) -> void:
	enemy_team.execute_cast(source_idx, player_team)
	_update_all_card_uis()

func _update_all_card_uis() -> void:
	for i: int in range(MAX_TEAM_SIZE):
		var slot: BattleCardSlot = player_slots[i] as BattleCardSlot
		var card: Control = slot.get_card()
		if card is BattleCard and player_team.units[i]:
			var b_card: BattleCard = card
			b_card.update_ui()
		else:
			slot.update_placeholder()
			
	for i: int in range(MAX_TEAM_SIZE):
		var slot: BattleCardSlot = enemy_slots[i] as BattleCardSlot
		var card: Control = slot.get_card()
		if card is BattleCard and enemy_team.units[i]:
			var b_card: BattleCard = card
			b_card.update_ui()
		else:
			slot.update_placeholder()

func _process(delta: float) -> void:
	if simulation_state == State.PLAYING:
		advance_simulation(delta * game_speed)

func advance_simulation(delta: float) -> void:
	# Update match timer
	if match_timer > 0.0:
		match_timer -= delta
		if match_timer <= 0.0:
			match_timer = 0.0
			if timer_container:
				timer_container.visible = false
		if timer_label:
			timer_label.text = "⏳ %.1fs" % match_timer
	else:
		# Fatigue damage active
		fatigue_tick_timer += delta
		if fatigue_tick_timer >= 1.0:
			fatigue_tick_timer -= 1.0
			fatigue_tick_count += 1
			var stage: int = floori((fatigue_tick_count - 1) / 3.0) + 1
			var dmg: int = get_fibonacci(stage + 1)
			
			player_team.take_damage(dmg)
			_update_all_card_uis()

	# Tick statuses
	player_team.tick_statuses(delta)
	enemy_team.tick_statuses(delta)

	# Tick card casts
	player_team.tick_casts(delta, 1.0, trigger_cast)
	enemy_team.tick_casts(delta, 1.0, trigger_enemy_cast)

func spawn_floating_text(value_text: String, text_color: Color, start_pos: Vector2) -> void:
	var offset_x: float = randf_range(-30.0, 30.0)
	var offset_y: float = randf_range(-20.0, 20.0)
	var final_pos: Vector2 = start_pos + Vector2(offset_x, offset_y) - Vector2(50.0, 15.0)
	
	var f_text: FloatingText = FloatingText.new()
	add_child(f_text)
	f_text.setup(value_text, text_color, final_pos)

func _on_enemy_defeat() -> void:
	set_playing(false)

func _on_team_defeat() -> void:
	set_playing(false)

func set_playing(play: bool) -> void:
	if play:
		simulation_state = State.PLAYING
		if play_button: play_button.visible = false
		if pause_button: pause_button.visible = true
	else:
		simulation_state = State.PAUSED
		if play_button: play_button.visible = true
		if pause_button: pause_button.visible = false

func _on_play_pressed() -> void:
	set_playing(true)

func _on_pause_pressed() -> void:
	set_playing(false)

func _on_exit_pressed() -> void:
	# Save updated stats back to run_state
	if run_state != null:
		for i: int in range(MAX_TEAM_SIZE):
			var persistent_unit: UnitInstance = run_state.active_team[i]
			var battle_unit_wrapper: BattleUnitInstance = player_team.units[i] as BattleUnitInstance
			var battle_unit: UnitInstance = battle_unit_wrapper.base_unit if battle_unit_wrapper else null
			if persistent_unit and battle_unit:
				persistent_unit.health = battle_unit.health
				persistent_unit.attack = battle_unit.attack
				persistent_unit.poison = battle_unit.poison
				persistent_unit.burn = battle_unit.burn
				persistent_unit.electrocute = battle_unit.electrocute
				persistent_unit.heal = battle_unit.heal
				persistent_unit.shield = battle_unit.shield
				persistent_unit.cast_speed = battle_unit.cast_speed
			else:
				run_state.active_team[i] = null
				
	battle_finished.emit()

func _on_card_hovered(card: Control, is_hovered: bool) -> void:
	if not preview_tooltip:
		return
		
	if is_hovered:
		if card is BattleCard:
			var b_card: BattleCard = card
			if b_card.unit_instance:
				CardUIHelper.show_tooltip(preview_tooltip, b_card.unit_instance)
	else:
		CardUIHelper.hide_tooltip(preview_tooltip)

func _clear_slot_target_highlights() -> void:
	for slot: BattleCardSlot in player_slots:
		slot.set_target_highlight(false)

func _on_speed_pressed() -> void:
	if game_speed == 1.0:
		game_speed = 2.0
	elif game_speed == 2.0:
		game_speed = 3.0
	else:
		game_speed = 1.0
		
	if speed_button:
		speed_button.text = "⚡ Speed: %dx" % int(game_speed)

func get_fibonacci(n: int) -> int:
	if n <= 0:
		return 0
	if n == 1 or n == 2:
		return 1
	var a: int = 1
	var b: int = 1
	for i: int in range(3, n + 1):
		var temp: int = a + b
		a = b
		b = temp
	return b


# UI Team Handler Methods

func _update_team_slots_ui(slots_arr: Array[BattleCardSlot], loaded_units: Array[UnitInstance]) -> void:
	for slot: BattleCardSlot in slots_arr:
		var old_card: Control = slot.get_card()
		if old_card is BattleCard:
			var old_b_card: BattleCard = old_card
			slot.remove_card(old_b_card)
			old_b_card.queue_free()
			
	for i: int in range(MAX_TEAM_SIZE):
		var inst: UnitInstance = loaded_units[i]
		if inst:
			var card: BattleCard = BATTLE_CARD_SCENE.instantiate() as BattleCard
			card.unit_instance = inst
			card.hovered.connect(func(c: Control, h: bool) -> void: _on_card_hovered(c, h))
			slots_arr[i].add_card(card)
		else:
			slots_arr[i].update_placeholder()

func _on_units_loaded(loaded_units: Array[UnitInstance], slots: Array[BattleCardSlot]) -> void:
	_update_team_slots_ui(slots, loaded_units)

func _on_health_changed(current_health: int, max_health: int, shield: int, mat: ShaderMaterial, label: Label) -> void:
	var fill_pct: float = 0.0
	if max_health > 0:
		var health_clamped: int = max(0, current_health)
		fill_pct = float(health_clamped) / float(max_health)
		
	if mat:
		mat.set_shader_parameter("fill_percentage", fill_pct)
		
	if label:
		if shield > 0:
			label.text = "%d / %d (🛡️ %d)" % [max(0, current_health), max_health, shield]
		else:
			label.text = "%d / %d" % [max(0, current_health), max_health]

func _on_status_changed(status_type: String, amount: int, cooldown_ratio: float, badges: Dictionary, status_hbox: Control) -> void:
	if status_type in badges and badges[status_type]:
		badges[status_type].value = amount
		badges[status_type].cooldown_ratio = cooldown_ratio
		
	var has_statuses: bool = false
	for badge: StatusBadge in badges.values():
		if badge and badge.value > 0:
			has_statuses = true
			break
			
	if status_hbox:
		status_hbox.visible = has_statuses

func _on_cast_progress_changed(slot_idx: int, ratio: float, slots: Array[BattleCardSlot]) -> void:
	if slot_idx >= 0 and slot_idx < slots.size():
		slots[slot_idx].set_cast_progress(ratio)

func _on_floating_text_requested(is_enemy_team: bool, text: String, color: Color, is_on_slot: bool, slot_idx: int) -> void:
	var spawn_pos: Vector2 = Vector2.ZERO
	if is_on_slot:
		var slot: BattleCardSlot = (enemy_slots[slot_idx] if is_enemy_team else player_slots[slot_idx]) as BattleCardSlot
		spawn_pos = slot.global_position + slot.size / 2.0
	else:
		var hp_bar: Control = enemy_health_bar_rect if is_enemy_team else team_health_bar_rect
		if hp_bar:
			spawn_pos = hp_bar.global_position + hp_bar.size / 2.0
		
	spawn_floating_text(text, color, spawn_pos)
