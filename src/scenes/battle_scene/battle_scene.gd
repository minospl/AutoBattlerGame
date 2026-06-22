class_name BattleScene
extends Control

enum State { PLAYING, PAUSED }
var simulation_state: State = State.PAUSED

var player_team: BattleTeam
var enemy_team: BattleTeam

var game_speed: float = 1.0
var preview_tooltip: Control

# Backup for reset
var initial_team_backup: Array[UnitInstance] = []

# Countdown Timer & Fatigue
var match_timer: float = 30.0
var fatigue_tick_timer: float = 0.0
var fatigue_tick_count: int = 0

# Slot References
var player_slots: Array[BattleCardSlot] = []
var enemy_slots: Array[BattleCardSlot] = []

func _ready() -> void:
	# Add the tooltip instance to PreviewContainer
	if has_node("%PreviewContainer"):
		var tooltip_scene := load("res://src/shared/components/card_tooltip.tscn") as PackedScene
		preview_tooltip = tooltip_scene.instantiate() as Control
		preview_tooltip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		preview_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		%PreviewContainer.add_child(preview_tooltip)
		preview_tooltip.visible = false

	# Setup buttons
	%ExitButton.pressed.connect(_on_exit_pressed)
	%PlayButton.pressed.connect(_on_play_pressed)
	%PauseButton.pressed.connect(_on_pause_pressed)
	%ResetButton.pressed.connect(_on_reset_pressed)
	%SpeedButton.pressed.connect(_on_speed_pressed)

	# Fetch slots
	player_slots = [
		%Slot0, %Slot1, %Slot2,
		%Slot3, %Slot4, %Slot5
	]
	for i in range(6):
		player_slots[i].slot_index = i

	# Fetch enemy slots
	enemy_slots = [
		%EnemySlot0, %EnemySlot1, %EnemySlot2,
		%EnemySlot3, %EnemySlot4, %EnemySlot5
	]
	for i in range(6):
		enemy_slots[i].slot_index = i

	# Configure HP border shaders
	_configure_hp_bar_shader(%TeamHealthBarRect)
	_configure_hp_bar_shader(%EnemyHealthBarRect)

	# Create BattleTeam instances
	player_team = BattleTeam.new()
	enemy_team = BattleTeam.new()
	
	# Connect signals from player_team
	player_team.team_units_loaded.connect(_on_player_units_loaded)
	player_team.health_changed.connect(_on_player_health_changed)
	player_team.status_changed.connect(_on_player_status_changed)
	player_team.cast_progress_changed.connect(_on_player_cast_progress_changed)
	player_team.floating_text_requested.connect(func(text: String, color: Color, is_on_slot: bool, slot_idx: int) -> void:
		_on_floating_text_requested(false, text, color, is_on_slot, slot_idx)
	)
	player_team.team_defeated.connect(_on_team_defeat)

	# Connect signals from enemy_team
	enemy_team.team_units_loaded.connect(_on_enemy_units_loaded)
	enemy_team.health_changed.connect(_on_enemy_health_changed)
	enemy_team.status_changed.connect(_on_enemy_status_changed)
	enemy_team.cast_progress_changed.connect(_on_enemy_cast_progress_changed)
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
	var hp_shader := load("res://src/shared/shaders/hp_border.gdshader") as Shader
	var hp_material := ShaderMaterial.new()
	hp_material.shader = hp_shader
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
		bg_style.texture = load("res://src/assets/ui/shop_background.jpg") as Texture2D
		bg_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.modulate_color = Color(0.3, 0.3, 0.3, 1.0) # Modulate darker for battle focus
		bg_panel.add_theme_stylebox_override("panel", bg_style)
		
	# Outer border coloring
	var outer_border := %OuterBorder as ColorRect
	if outer_border:
		outer_border.color = GameColors.PANEL_BORDER_DEFAULT

func load_battle_team() -> void:
	initial_team_backup.clear()

	if CurrentRun.state == null:
		return

	# Copy team and make backup
	var player_units: Array[UnitInstance] = []
	for i in range(6):
		var inst := CurrentRun.state.active_team[i] as UnitInstance
		if inst:
			inst.temp_max_health_bonus = 0
			initial_team_backup.append(inst.clone())
			player_units.append(inst)
		else:
			initial_team_backup.append(null)
			player_units.append(null)

	player_team.load_team_units(player_units)

	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	if has_node("%TimerContainer"):
		%TimerContainer.visible = true
	if has_node("%TimerLabel"):
		%TimerLabel.text = "⏳ 30.0s"
		
	load_enemy_team()

func load_enemy_team() -> void:
	var enemy_units: Array[UnitInstance] = []
	enemy_units.resize(6)

	# Load River Crab into Slot 0
	var crab_data := load("res://src/resources/units/river_crab.tres") as Resource
	if crab_data:
		var crab_instance := UnitInstance.new()
		crab_instance.initialize(crab_data)
		# Override health and attack
		crab_instance.max_health_bonus = 999  # base health is 1, so 1 + 999 = 1000
		crab_instance.current_health = 1000
		crab_instance.current_attack = 10
		
		# Ignore thorns per user request
		crab_instance.thorns = 0
		
		enemy_units[0] = crab_instance
		
	enemy_team.load_team_units(enemy_units)

func trigger_battle_start() -> void:
	# Wait one frame to let Godot layout engine calculate slot positions
	await get_tree().process_frame
	
	for i in range(6):
		if player_team.units[i]:
			ModifierEngine.trigger_unit_modifiers(i, player_team, UnitModifier.Trigger.ON_BATTLE_START)
					
	# Update all health and stat overlays
	_update_all_card_uis()

func trigger_cast(source_idx: int) -> void:
	player_team.execute_cast(source_idx, enemy_team)
	_update_all_card_uis()

func trigger_enemy_cast(source_idx: int) -> void:
	enemy_team.execute_cast(source_idx, player_team)
	_update_all_card_uis()

func _update_all_card_uis() -> void:
	for i in range(6):
		var slot := player_slots[i]
		var card := slot.get_card()
		if card and player_team.units[i]:
			card.update_ui()
		else:
			slot.update_placeholder()
			
	for i in range(6):
		var slot := enemy_slots[i]
		var card := slot.get_card()
		if card and enemy_team.units[i]:
			card.update_ui()
		else:
			slot.update_placeholder()

func _process(delta: float) -> void:
	if simulation_state == State.PLAYING:
		advance_simulation(delta * game_speed)
	player_team.update_cooldown_ratios()
	enemy_team.update_cooldown_ratios()

func advance_simulation(delta: float) -> void:
	# Update match timer
	if match_timer > 0.0:
		match_timer -= delta
		if match_timer <= 0.0:
			match_timer = 0.0
			if has_node("%TimerContainer"):
				%TimerContainer.visible = false
		if has_node("%TimerLabel"):
			%TimerLabel.text = "⏳ %.1fs" % match_timer
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
		%PlayButton.visible = false
		%PauseButton.visible = true
	else:
		simulation_state = State.PAUSED
		%PlayButton.visible = true
		%PauseButton.visible = false

func _on_play_pressed() -> void:
	set_playing(true)

func _on_pause_pressed() -> void:
	set_playing(false)

func _on_reset_pressed() -> void:
	set_playing(false)
	
	# Reset Countdown Timer & Fatigue
	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	if has_node("%TimerContainer"):
		%TimerContainer.visible = true
	if has_node("%TimerLabel"):
		%TimerLabel.text = "⏳ 30.0s"
		
	# Reset both teams
	player_team.reset(initial_team_backup)
	load_enemy_team()
	
	# Trigger start of battle again
	trigger_battle_start()

func _on_exit_pressed() -> void:
	# Save updated stats back to CurrentRun.state
	if CurrentRun.state != null:
		for i in range(6):
			var persistent_unit := CurrentRun.state.active_team[i] as UnitInstance
			var backup := initial_team_backup[i] as UnitInstance
			if persistent_unit and backup:
				# Revert temporary combat-specific stats back to shop/backup state
				persistent_unit.max_health_bonus = player_team.units[i].max_health_bonus
				persistent_unit.temp_max_health_bonus = 0
				
				persistent_unit.current_health = persistent_unit.get_max_health()
				persistent_unit.current_attack = backup.current_attack
				persistent_unit.poison = backup.poison
				persistent_unit.shield = backup.shield
				persistent_unit.burn = backup.burn
				persistent_unit.electrocute = backup.electrocute
				persistent_unit.current_cast_speed = backup.current_cast_speed
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
		
	if %SpeedButton:
		%SpeedButton.text = "⚡ Speed: %dx" % int(game_speed)

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
			
	var card_scene := load("res://src/scenes/battle_scene/components/battle_card.tscn") as PackedScene
	for i in range(6):
		var inst := loaded_units[i]
		if inst:
			var card := card_scene.instantiate() as BattleCard
			card.unit_instance = inst
			card.hovered.connect(func(c: Control, h: bool) -> void: _on_card_hovered(c, h))
			slots_arr[i].add_card(card)
		else:
			slots_arr[i].update_placeholder()

func _on_player_units_loaded(loaded_units: Array[UnitInstance]) -> void:
	_update_team_slots_ui(player_slots, loaded_units)

func _on_enemy_units_loaded(loaded_units: Array[UnitInstance]) -> void:
	_update_team_slots_ui(enemy_slots, loaded_units)

func _on_player_health_changed(current_health: int, max_health: int, shield: int) -> void:
	var fill_pct := 0.0
	if max_health > 0:
		fill_pct = float(max(0, current_health)) / float(max_health)
		
	var hp_bar := %TeamHealthBarRect as Control
	if hp_bar and hp_bar.material:
		hp_bar.material.set_shader_parameter("fill_percentage", fill_pct)
		
	var hp_label := %TeamHealthLabel as Label
	if hp_label:
		if shield > 0:
			hp_label.text = "Team Health: %d / %d (🛡️ %d)" % [max(0, current_health), max_health, shield]
		else:
			hp_label.text = "Team Health: %d / %d" % [max(0, current_health), max_health]

func _on_enemy_health_changed(current_health: int, max_health: int, shield: int) -> void:
	var fill_pct := 0.0
	if max_health > 0:
		fill_pct = float(max(0, current_health)) / float(max_health)
		
	var hp_bar := %EnemyHealthBarRect as Control
	if hp_bar and hp_bar.material:
		hp_bar.material.set_shader_parameter("fill_percentage", fill_pct)
		
	var hp_label := %EnemyHealthLabel as Label
	if hp_label:
		var damage_taken := max_health - current_health
		if shield > 0:
			hp_label.text = "Damage Taken: %d (🛡️ %d)" % [damage_taken, shield]
		else:
			hp_label.text = "Damage Taken: %d" % damage_taken

func _on_player_status_changed(status_type: String, amount: int, cooldown_ratio: float) -> void:
	var badge: StatusBadge = null
	match status_type:
		"poison": badge = %TeamPoisonBadge as StatusBadge
		"burn": badge = %TeamBurnBadge as StatusBadge
		"electrocute": badge = %TeamElectrocuteBadge as StatusBadge
		
	if badge:
		badge.value = amount
		badge.cooldown_ratio = cooldown_ratio
		
	var has_statuses := false
	var poison_badge := %TeamPoisonBadge as StatusBadge
	var burn_badge := %TeamBurnBadge as StatusBadge
	var electrocute_badge := %TeamElectrocuteBadge as StatusBadge
	if poison_badge and poison_badge.value > 0: has_statuses = true
	if burn_badge and burn_badge.value > 0: has_statuses = true
	if electrocute_badge and electrocute_badge.value > 0: has_statuses = true
	
	var status_hbox := %TeamStatusHBox as Control
	if status_hbox:
		status_hbox.visible = has_statuses

func _on_enemy_status_changed(status_type: String, amount: int, cooldown_ratio: float) -> void:
	var badge: StatusBadge = null
	match status_type:
		"poison": badge = %PoisonBadge as StatusBadge
		"burn": badge = %BurnBadge as StatusBadge
		"electrocute": badge = %ElectrocuteBadge as StatusBadge
		
	if badge:
		badge.value = amount
		badge.cooldown_ratio = cooldown_ratio
		
	var has_statuses := false
	var poison_badge := %PoisonBadge as StatusBadge
	var burn_badge := %BurnBadge as StatusBadge
	var electrocute_badge := %ElectrocuteBadge as StatusBadge
	if poison_badge and poison_badge.value > 0: has_statuses = true
	if burn_badge and burn_badge.value > 0: has_statuses = true
	if electrocute_badge and electrocute_badge.value > 0: has_statuses = true
	
	var status_hbox := %EnemyStatusHBox as Control
	if status_hbox:
		status_hbox.visible = has_statuses

func _on_player_cast_progress_changed(slot_idx: int, ratio: float) -> void:
	if slot_idx >= 0 and slot_idx < player_slots.size():
		player_slots[slot_idx].set_cast_progress(ratio)

func _on_enemy_cast_progress_changed(slot_idx: int, ratio: float) -> void:
	if slot_idx >= 0 and slot_idx < enemy_slots.size():
		enemy_slots[slot_idx].set_cast_progress(ratio)

func _on_floating_text_requested(is_enemy_team: bool, text: String, color: Color, is_on_slot: bool, slot_idx: int) -> void:
	var spawn_pos := Vector2.ZERO
	if is_on_slot:
		var slot := enemy_slots[slot_idx] if is_enemy_team else player_slots[slot_idx]
		spawn_pos = slot.global_position + slot.size / 2.0
	else:
		var hp_bar := %EnemyHealthBarRect if is_enemy_team else %TeamHealthBarRect
		spawn_pos = hp_bar.global_position + hp_bar.size / 2.0
		
	spawn_floating_text(text, color, spawn_pos)
