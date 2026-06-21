class_name BattleScene
extends Control

enum State { PLAYING, PAUSED }
var simulation_state: State = State.PAUSED

var current_team: Array[UnitInstance] = []
var initial_team_backup: Array[UnitInstance] = []
var cast_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var game_speed: float = 1.0

var slots: Array[BattleCardSlot] = []
var preview_tooltip: Control

# Team Health Pool & Shield
var team_health: int = 0
var team_max_health: int = 0
var team_shield: int = 0

# Enemy Stats for practice dummy
var enemy_damage_taken: int = 0
var enemy_poison: int = 0
var enemy_poison_timer: float = 0.0
var enemy_poison_damage_dealt: int = 0
var enemy_burn: int = 0
var enemy_burn_timer: float = 0.0
var enemy_electrocute: int = 0

# Countdown Timer & Fatigue
var match_timer: float = 30.0
var fatigue_tick_timer: float = 0.0
var fatigue_tick_count: int = 0

func _ready() -> void:
	# Add the tooltip instance to PreviewContainer
	if has_node("%PreviewContainer"):
		var tooltip_scene = load("res://src/shared/components/card_tooltip.tscn")
		preview_tooltip = tooltip_scene.instantiate()
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
	slots = [
		%Slot0, %Slot1, %Slot2,
		%Slot3, %Slot4, %Slot5
	]
	for i in range(6):
		slots[i].slot_index = i

	# Load state and backup
	load_battle_team()
	
	# Load and assign the health bar shader material to the team health bar
	var hp_shader = load("res://src/shared/shaders/hp_border.gdshader")
	var hp_material = ShaderMaterial.new()
	hp_material.shader = hp_shader
	hp_material.set_shader_parameter("fill_percentage", 1.0)
	%TeamHealthBarRect.material = hp_material
	
	%TeamHealthBarRect.resized.connect(func():
		if %TeamHealthBarRect.material:
			%TeamHealthBarRect.material.set_shader_parameter("size", %TeamHealthBarRect.size)
	)
	
	if %TeamHealthBarRect.material:
		var initial_hp_size = %TeamHealthBarRect.size
		if initial_hp_size.x == 0.0:
			initial_hp_size = Vector2(340, 32)
		%TeamHealthBarRect.material.set_shader_parameter("size", initial_hp_size)

	# Assign shader material to the enemy health bar (damage bar)
	var enemy_hp_material = ShaderMaterial.new()
	enemy_hp_material.shader = hp_shader
	enemy_hp_material.set_shader_parameter("fill_percentage", 1.0)
	%EnemyHealthBarRect.material = enemy_hp_material
	
	%EnemyHealthBarRect.resized.connect(func():
		if %EnemyHealthBarRect.material:
			%EnemyHealthBarRect.material.set_shader_parameter("size", %EnemyHealthBarRect.size)
	)
	
	if %EnemyHealthBarRect.material:
		var initial_enemy_size = %EnemyHealthBarRect.size
		if initial_enemy_size.x == 0.0:
			initial_enemy_size = Vector2(340, 32)
		%EnemyHealthBarRect.material.set_shader_parameter("size", initial_enemy_size)
	
	# Apply visual styling
	_apply_visual_styling()

	# Initialize Enemy UI
	_update_enemy_ui()
	
	# Update team health bar UI
	update_team_health_bar()

	# Start battle start modifiers immediately
	trigger_battle_start()

func _apply_visual_styling() -> void:
	# Background style
	var bg_panel = get_node_or_null("BackgroundPanel") as Panel
	if bg_panel:
		var bg_style = StyleBoxTexture.new()
		bg_style.texture = load("res://src/assets/ui/shop_background.jpg")
		bg_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.modulate_color = Color(0.3, 0.3, 0.3, 1.0) # Modulate darker for battle focus
		bg_panel.add_theme_stylebox_override("panel", bg_style)
		
	# Outer border coloring
	var outer_border = %OuterBorder as ColorRect
	if outer_border:
		outer_border.color = GameColors.PANEL_BORDER_DEFAULT
		


func duplicate_unit_instance(inst: UnitInstance) -> UnitInstance:
	if not inst:
		return null
	var new_inst = UnitInstance.new()
	new_inst.data = inst.data
	new_inst.current_health = inst.current_health
	new_inst.current_attack = inst.current_attack
	new_inst.poison = inst.poison
	new_inst.heal = inst.heal
	new_inst.shield = inst.shield
	new_inst.thorns = inst.thorns
	new_inst.burn = inst.burn
	new_inst.electrocute = inst.electrocute
	new_inst.level = inst.level
	new_inst.max_health_bonus = inst.max_health_bonus
	new_inst.current_cast_speed = inst.current_cast_speed
	return new_inst

func load_battle_team() -> void:
	# Clear slots
	for slot in slots:
		var old_card = slot.get_card()
		if old_card:
			slot.remove_card(old_card)
			old_card.queue_free()

	initial_team_backup.clear()
	current_team.clear()
	current_team.resize(6)

	if CurrentRun.state == null:
		return

	# Copy team and make backup
	for i in range(6):
		var inst = CurrentRun.state.active_team[i]
		if inst:
			inst.temp_max_health_bonus = 0
		initial_team_backup.append(duplicate_unit_instance(inst))
		if inst:
			current_team[i] = inst
			var card_scene = load("res://src/scenes/battle_scene/components/battle_card.tscn")
			var card = card_scene.instantiate()
			card.unit_instance = inst
			card.hovered.connect(func(c, h): _on_card_hovered(c, h))
			slots[i].add_card(card)
		else:
			current_team[i] = null
			
		slots[i].update_placeholder()

	cast_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for slot in slots:
		slot.set_cast_progress(0.0)
		
	team_health = 0
	team_max_health = 0
	team_shield = 0
	for unit in current_team:
		if unit:
			team_health += unit.current_health
			team_max_health += unit.get_max_health()
		
	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	if has_node("%TimerContainer"):
		%TimerContainer.visible = true
	if has_node("%TimerLabel"):
		%TimerLabel.text = "⏳ 30.0s"

func trigger_battle_start() -> void:
	# Wait one frame to let Godot layout engine calculate slot positions
	await get_tree().process_frame
	
	for i in range(6):
		if current_team[i]:
			ModifierEngine.trigger_unit_modifiers(i, current_team, UnitModifier.Trigger.ON_BATTLE_START)
					
	# Update all health and stat overlays
	_update_all_card_uis()

func trigger_cast(source_idx: int) -> void:
	var unit = current_team[source_idx]
	if not unit:
		return

	# Attack practice dummy!
	var dmg = unit.get_attack()
	if dmg > 0:
		if enemy_electrocute > 0:
			dmg += enemy_electrocute
		enemy_damage_taken += dmg
		
		if %EnemyHealthBarRect:
			var enemy_bar = %EnemyHealthBarRect as Control
			var spawn_pos = enemy_bar.global_position + enemy_bar.size / 2.0
			spawn_floating_text("-" + str(dmg), Color(1.0, 1.0, 1.0), spawn_pos)
		

	# Apply poison if unit has poison value!
	if unit.poison > 0:
		enemy_poison += unit.poison
	
	# Heal team if unit has heal value!
	if unit.heal > 0:
		var health_before = team_health
		team_health = min(team_health + unit.heal, team_max_health)
		var actual_heal = team_health - health_before
		if actual_heal > 0:
			update_team_health_bar()
			if %TeamHealthBarRect:
				var hp_bar = %TeamHealthBarRect as Control
				var spawn_pos = hp_bar.global_position + hp_bar.size / 2.0
				spawn_floating_text("+" + str(actual_heal), Color(0.2, 0.9, 0.2), spawn_pos)
		
	# Shield team if unit has shield value!
	if unit.shield > 0:
		team_shield += unit.shield
		update_team_health_bar()
		if %TeamHealthBarRect:
			var hp_bar = %TeamHealthBarRect as Control
			var spawn_pos = hp_bar.global_position + hp_bar.size / 2.0
			spawn_floating_text("+" + str(unit.shield), Color(0.7, 0.7, 0.7), spawn_pos)

	# Apply burn if unit has burn value!
	if unit.burn > 0:
		enemy_burn += unit.burn

	# Apply electrocute if unit has electrocute value!
	if unit.electrocute > 0:
		enemy_electrocute += unit.electrocute
		
	_update_enemy_ui()

	# Perform ON_CAST action
	ModifierEngine.trigger_unit_modifiers(source_idx, current_team, UnitModifier.Trigger.ON_CAST)
			
	# Update all visuals
	_update_all_card_uis()

func _update_all_card_uis() -> void:
	for i in range(6):
		var slot = slots[i]
		var card = slot.get_card()
		if card and current_team[i]:
			card.update_ui()
		else:
			slot.update_placeholder()
	
	update_team_health_bar()

func _process(delta: float) -> void:
	if simulation_state == State.PLAYING:
		advance_simulation(delta * game_speed)
	_update_poison_cooldown_progress()

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
			var stage = floori((fatigue_tick_count - 1) / 3.0) + 1
			var dmg = get_fibonacci(stage + 1)
			
			if %TeamHealthBarRect:
				var hp_bar = %TeamHealthBarRect as Control
				var spawn_pos = hp_bar.global_position + hp_bar.size / 2.0
				spawn_floating_text("-" + str(dmg), Color(1.0, 0.3, 0.3), spawn_pos)
			
			var team_took_dmg = false
			if team_shield >= dmg:
				team_shield -= dmg
				team_took_dmg = true
			else:
				var remaining_dmg = dmg - team_shield
				if team_shield > 0 or remaining_dmg > 0:
					team_took_dmg = true
				team_shield = 0
				team_health -= remaining_dmg
				
			_update_all_card_uis()
			
			if team_took_dmg:
				trigger_thorns()

	# Tick enemy poison status every second!
	if enemy_poison > 0:
		enemy_poison_timer += delta
		if enemy_poison_timer >= 1.0:
			enemy_poison_timer -= 1.0
			enemy_damage_taken += enemy_poison
			enemy_poison_damage_dealt += enemy_poison
			if %EnemyHealthBarRect:
				var enemy_bar = %EnemyHealthBarRect as Control
				var spawn_pos = enemy_bar.global_position + enemy_bar.size / 2.0
				spawn_floating_text("-" + str(enemy_poison), Color(0.7, 0.3, 0.8), spawn_pos)
			_update_enemy_ui()
	else:
		enemy_poison_timer = 0.0

	# Tick enemy burn status every 0.5 seconds (2x faster than poison)!
	if enemy_burn > 0:
		enemy_burn_timer += delta
		if enemy_burn_timer >= 0.5:
			enemy_burn_timer -= 0.5
			enemy_damage_taken += enemy_burn
			if %EnemyHealthBarRect:
				var enemy_bar = %EnemyHealthBarRect as Control
				var spawn_pos = enemy_bar.global_position + enemy_bar.size / 2.0
				spawn_floating_text("-" + str(enemy_burn), Color(0.9, 0.4, 0.1), spawn_pos)
			enemy_burn = max(0, enemy_burn - 1)
			_update_enemy_ui()
	else:
		enemy_burn_timer = 0.0

	for i in range(6):
		if current_team[i]:
			cast_timers[i] += delta
			var speed = current_team[i].get_cast_speed()
			if speed <= 0.0: speed = 1.0
			
			slots[i].set_cast_progress(cast_timers[i] / speed)
			
			if cast_timers[i] >= speed:
				cast_timers[i] = 0.0
				trigger_cast(i)
		else:
			slots[i].set_cast_progress(0.0)


func spawn_floating_text(value_text: String, text_color: Color, start_pos: Vector2) -> void:
	var f_text = Label.new()
	f_text.set_script(load("res://src/scenes/battle_scene/components/floating_text.gd"))
	f_text.text = value_text
	f_text.add_theme_color_override("font_color", text_color)
	f_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	f_text.add_theme_font_size_override("font_size", 20)
	f_text.custom_minimum_size = Vector2(100, 30)
	
	# Add a random offset to prevent overlaps when ticks happen close together
	var offset_x = randf_range(-30.0, 30.0)
	var offset_y = randf_range(-20.0, 20.0)
	var final_pos = start_pos + Vector2(offset_x, offset_y) - Vector2(50, 15)
	
	f_text.global_position = final_pos
	add_child(f_text)

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
	
	# Reset Enemy Stats
	enemy_damage_taken = 0
	enemy_poison = 0
	enemy_poison_timer = 0.0
	enemy_poison_damage_dealt = 0
	enemy_burn = 0
	enemy_burn_timer = 0.0
	enemy_electrocute = 0
	_update_enemy_ui()

	# Reset Countdown Timer & Fatigue
	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	if has_node("%TimerContainer"):
		%TimerContainer.visible = true
	if has_node("%TimerLabel"):
		%TimerLabel.text = "⏳ 30.0s"
	
	# Clear
	for slot in slots:
		var old_card = slot.get_card()
		if old_card:
			slot.remove_card(old_card)
			old_card.queue_free()
			
	# Re-create duplicates from backup
	team_shield = 0
	team_health = 0
	team_max_health = 0
	for i in range(6):
		var backup = initial_team_backup[i]
		if backup:
			current_team[i] = duplicate_unit_instance(backup)
			team_health += current_team[i].current_health
			team_max_health += current_team[i].get_max_health()
			var card_scene = load("res://src/scenes/battle_scene/components/battle_card.tscn")
			var card = card_scene.instantiate()
			card.unit_instance = current_team[i]
			card.hovered.connect(func(c, h): _on_card_hovered(c, h))
			slots[i].add_card(card)
		else:
			current_team[i] = null
			
		slots[i].update_placeholder()

	cast_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for slot in slots:
		slot.set_cast_progress(0.0)
		
	# Trigger start of battle again
	trigger_battle_start()

func _on_exit_pressed() -> void:
	# Save updated stats back to CurrentRun.state
	if CurrentRun.state != null:
		for i in range(6):
			var persistent_unit = CurrentRun.state.active_team[i]
			var backup = initial_team_backup[i]
			if persistent_unit and backup:
				# Revert temporary combat-specific stats back to shop/backup state
				persistent_unit.max_health_bonus = current_team[i].max_health_bonus
				persistent_unit.temp_max_health_bonus = 0
				
				persistent_unit.current_health = persistent_unit.get_max_health() # Reset health to max when returning to shop
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
	for slot in slots:
		slot.set_target_highlight(false)

func _update_enemy_ui() -> void:
	if has_node("%EnemyHealthLabel"):
		%EnemyHealthLabel.text = "Damage Taken: " + str(enemy_damage_taken)
	
	if has_node("%PoisonBadge"):
		%PoisonBadge.value = enemy_poison
	if has_node("%BurnBadge"):
		%BurnBadge.value = enemy_burn
	if has_node("%ElectrocuteBadge"):
		%ElectrocuteBadge.value = enemy_electrocute
		
	# Toggle visibility of the status container based on active statuses
	var has_statuses = enemy_poison > 0 or enemy_burn > 0 or enemy_electrocute > 0
	if has_node("%EnemyStatusHBox"):
		%EnemyStatusHBox.visible = has_statuses

func _update_poison_cooldown_progress() -> void:
	if has_node("%PoisonBadge"):
		var ratio = 0.0
		if enemy_poison > 0:
			ratio = clamp(enemy_poison_timer / 1.0, 0.0, 1.0)
		%PoisonBadge.cooldown_ratio = ratio

func update_team_health_bar() -> void:
	var fill_pct: float = 0.0
	if team_max_health > 0:
		fill_pct = float(max(0, team_health)) / float(team_max_health)
		
	if %TeamHealthBarRect and %TeamHealthBarRect.material:
		%TeamHealthBarRect.material.set_shader_parameter("fill_percentage", fill_pct)
		
	if %TeamHealthLabel:
		if team_shield > 0:
			%TeamHealthLabel.text = "Team Health: %d / %d (🛡️ %d)" % [max(0, team_health), team_max_health, team_shield]
		else:
			%TeamHealthLabel.text = "Team Health: %d / %d" % [max(0, team_health), team_max_health]

	if team_max_health > 0 and team_health <= 0:
		call_deferred("_on_team_defeat")



func _on_speed_pressed() -> void:
	if game_speed == 1.0:
		game_speed = 2.0
	elif game_speed == 2.0:
		game_speed = 3.0
	else:
		game_speed = 1.0
		
	if %SpeedButton:
		%SpeedButton.text = "⚡ Speed: %dx" % int(game_speed)

func _on_team_defeat() -> void:
	set_playing(false)
	
	# # Deduct a life
	# if CurrentRun.state != null:
	# 	CurrentRun.state.lives = max(0, CurrentRun.state.lives - 1)
	# 	
	# 	# Restore health of all active units to max
	# 	for unit in CurrentRun.state.active_team:
	# 		if unit:
	# 			unit.temp_max_health_bonus = 0
	# 			unit.current_health = unit.get_max_health()
	# 			
	# # Transition back to shop
	# get_tree().change_scene_to_file("res://src/scenes/shop_scene/shop_scene.tscn")

func get_fibonacci(n: int) -> int:
	if n <= 0:
		return 0
	if n == 1 or n == 2:
		return 1
	var a = 1
	var b = 1
	for i in range(3, n + 1):
		var temp = a + b
		a = b
		b = temp
	return b

func trigger_thorns() -> void:
	var total_thorns = 0
	for unit in current_team:
		if unit:
			total_thorns += unit.thorns
	if total_thorns > 0:
		enemy_damage_taken += total_thorns
		_update_enemy_ui()
