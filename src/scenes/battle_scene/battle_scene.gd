class_name BattleScene
extends Control

# Static Preloads
const CARD_TOOLTIP_SCENE = preload("res://src/shared/components/card_tooltip.tscn")
const HP_BORDER_SHADER = preload("res://src/shared/shaders/hp_border.gdshader")
const SHOP_BACKGROUND_TEXTURE = preload("res://src/assets/ui/shop_background.jpg")
const RIVER_CRAB_RES = preload("res://src/resources/units/river_crab.tres")
const BATTLE_CARD_SCENE = preload("res://src/scenes/battle_scene/components/battle_card.tscn")

const MAX_TEAM_SIZE = 6

enum State { PLAYING, PAUSED }
var simulation_state: State = State.PAUSED

var player_team: BattleTeam
var enemy_team: BattleTeam

var game_speed: float = 1.0
var preview_tooltip: Control



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
		preview_tooltip = CARD_TOOLTIP_SCENE.instantiate() as Control
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
	for i in range(MAX_TEAM_SIZE):
		player_slots[i].slot_index = i

	# Fetch enemy slots
	enemy_slots = [
		%EnemySlot0, %EnemySlot1, %EnemySlot2,
		%EnemySlot3, %EnemySlot4, %EnemySlot5
	]
	for i in range(MAX_TEAM_SIZE):
		enemy_slots[i].slot_index = i

	# Configure HP border shaders
	_configure_hp_bar_shader(team_health_bar_rect)
	_configure_hp_bar_shader(enemy_health_bar_rect)

	# Create BattleTeam instances
	player_team = BattleTeam.new()
	enemy_team = BattleTeam.new()
	
	# Connect signals from player_team
	player_team.team_units_loaded.connect(_on_units_loaded.bind(player_slots))
	player_team.health_changed.connect(_on_health_changed.bind(team_health_bar_rect, team_health_label))
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
	enemy_team.health_changed.connect(_on_health_changed.bind(enemy_health_bar_rect, enemy_health_label))
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

	# Load state and backup
	load_battle_team()
	
	# Apply visual styling
	_apply_visual_styling()

	# Start battle start modifiers immediately
	trigger_battle_start()

func _configure_hp_bar_shader(hp_bar: Control) -> void:
	if not hp_bar:
		return
	var hp_material := ShaderMaterial.new()
	hp_material.shader = HP_BORDER_SHADER
	hp_material.set_shader_parameter("fill_percentage", 1.0)
	hp_bar.material = hp_material
	
	hp_bar.resized.connect(func() -> void:
		if hp_bar.material:
			hp_bar.material.set_shader_parameter("size", hp_bar.size)
	)
	
	var initial_hp_size := hp_bar.size
	if initial_hp_size.x == 0.0:
		initial_hp_size = Vector2(340.0, 32.0)
	hp_bar.material.set_shader_parameter("size", initial_hp_size)

func _apply_visual_styling() -> void:
	# Background style
	var bg_panel := get_node_or_null("BackgroundPanel") as Panel
	if bg_panel:
		var bg_style := StyleBoxTexture.new()
		bg_style.texture = SHOP_BACKGROUND_TEXTURE
		bg_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.modulate_color = Color(0.3, 0.3, 0.3, 1.0) # Modulate darker for battle focus
		bg_panel.add_theme_stylebox_override("panel", bg_style)
		
	# Outer border coloring
	if outer_border:
		outer_border.color = GameColors.PANEL_BORDER_DEFAULT

func load_battle_team() -> void:
	if CurrentRun.state == null:
		return

	# Copy team and make clones for the battle scene simulation
	var player_units: Array[UnitInstance] = []
	for i in range(MAX_TEAM_SIZE):
		var inst := CurrentRun.state.active_team[i] as UnitInstance
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
		var crab_instance := UnitInstance.new()
		crab_instance.initialize(RIVER_CRAB_RES)
		# Override health and attack
		crab_instance.health = 1000
		crab_instance.attack = 10
		
		# Ignore thorns per user request
		crab_instance.thorns = 0
		
		enemy_units[0] = crab_instance
		
	enemy_team.load_team_units(enemy_units)

func trigger_battle_start() -> void:
	# Wait one frame to let Godot layout engine calculate slot positions
	await get_tree().process_frame
	
	for i in range(MAX_TEAM_SIZE):
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
	for i in range(MAX_TEAM_SIZE):
		var slot := player_slots[i]
		var card := slot.get_card()
		if card and player_team.units[i]:
			card.update_ui()
		else:
			slot.update_placeholder()
			
	for i in range(MAX_TEAM_SIZE):
		var slot := enemy_slots[i]
		var card := slot.get_card()
		if card and enemy_team.units[i]:
			card.update_ui()
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
			var stage := floori((fatigue_tick_count - 1) / 3.0) + 1
			var dmg := get_fibonacci(stage + 1)
			
			var hp_before := player_team.health
			player_team.take_damage(dmg)
			var took_damage := player_team.health < hp_before or player_team.shield > 0
			if took_damage:
				trigger_thorns()
				
			_update_all_card_uis()

	# Tick statuses
	player_team.tick_statuses(delta)
	enemy_team.tick_statuses(delta)

	# Tick card casts
	player_team.tick_casts(delta, 1.0, trigger_cast)
	enemy_team.tick_casts(delta, 1.0, trigger_enemy_cast)

func spawn_floating_text(value_text: String, text_color: Color, start_pos: Vector2) -> void:
	var offset_x := randf_range(-30.0, 30.0)
	var offset_y := randf_range(-20.0, 20.0)
	var final_pos := start_pos + Vector2(offset_x, offset_y) - Vector2(50.0, 15.0)
	
	var f_text := FloatingText.new()
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
	# Save updated stats back to CurrentRun.state
	if CurrentRun.state != null:
		for i in range(MAX_TEAM_SIZE):
			var persistent_unit := CurrentRun.state.active_team[i] as UnitInstance
			var battle_unit := player_team.units[i] as UnitInstance
			if persistent_unit and battle_unit:
				# Copy only unified health property
				persistent_unit.health = battle_unit.health
			else:
				CurrentRun.state.active_team[i] = null
				
	get_tree().change_scene_to_file("res://src/scenes/shop_scene/shop_scene.tscn")

func _on_card_hovered(card: Control, is_hovered: bool) -> void:
	if not preview_tooltip:
		return
		
	if is_hovered:
		if card is BattleCard and card.unit_instance:
			CardUIHelper.show_tooltip(preview_tooltip, card.unit_instance)
	else:
		CardUIHelper.hide_tooltip(preview_tooltip)

func _clear_slot_target_highlights() -> void:
	for slot in player_slots:
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
	var a := 1
	var b := 1
	for i in range(3, n + 1):
		var temp := a + b
		a = b
		b = temp
	return b

func trigger_thorns() -> void:
	var total_thorns := player_team.get_total_thorns()
	if total_thorns > 0:
		enemy_team.take_damage(total_thorns)

# UI Team Handler Methods

func _update_team_slots_ui(slots_arr: Array[BattleCardSlot], loaded_units: Array[UnitInstance]) -> void:
	for slot in slots_arr:
		var old_card := slot.get_card()
		if old_card:
			slot.remove_card(old_card)
			old_card.queue_free()
			
	for i in range(MAX_TEAM_SIZE):
		var inst := loaded_units[i]
		if inst:
			var card := BATTLE_CARD_SCENE.instantiate() as BattleCard
			card.unit_instance = inst
			card.hovered.connect(func(c: Control, h: bool) -> void: _on_card_hovered(c, h))
			slots_arr[i].add_card(card)
		else:
			slots_arr[i].update_placeholder()

func _on_units_loaded(loaded_units: Array[UnitInstance], slots: Array[BattleCardSlot]) -> void:
	_update_team_slots_ui(slots, loaded_units)

func _on_health_changed(current_health: int, max_health: int, shield: int, bar: Control, label: Label) -> void:
	var fill_pct := 0.0
	if max_health > 0:
		fill_pct = float(max(0, current_health)) / float(max_health)
		
	if bar and bar.material:
		bar.material.set_shader_parameter("fill_percentage", fill_pct)
		
	if label:
		if shield > 0:
			label.text = "%d / %d (🛡️ %d)" % [max(0, current_health), max_health, shield]
		else:
			label.text = "%d / %d" % [max(0, current_health), max_health]

func _on_status_changed(status_type: String, amount: int, cooldown_ratio: float, badges: Dictionary, status_hbox: Control) -> void:
	if status_type in badges and badges[status_type]:
		badges[status_type].value = amount
		badges[status_type].cooldown_ratio = cooldown_ratio
		
	var has_statuses := false
	for badge in badges.values():
		if badge and badge.value > 0:
			has_statuses = true
			break
			
	if status_hbox:
		status_hbox.visible = has_statuses

func _on_cast_progress_changed(slot_idx: int, ratio: float, slots: Array[BattleCardSlot]) -> void:
	if slot_idx >= 0 and slot_idx < slots.size():
		slots[slot_idx].set_cast_progress(ratio)

func _on_floating_text_requested(is_enemy_team: bool, text: String, color: Color, is_on_slot: bool, slot_idx: int) -> void:
	var spawn_pos := Vector2.ZERO
	if is_on_slot:
		var slot := enemy_slots[slot_idx] if is_enemy_team else player_slots[slot_idx]
		spawn_pos = slot.global_position + slot.size / 2.0
	else:
		var hp_bar := enemy_health_bar_rect if is_enemy_team else team_health_bar_rect
		if hp_bar:
			spawn_pos = hp_bar.global_position + hp_bar.size / 2.0
		
	spawn_floating_text(text, color, spawn_pos)
