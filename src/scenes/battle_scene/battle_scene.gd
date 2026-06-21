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
	%ToggleLogButton.pressed.connect(_on_toggle_log_pressed)
	%LogPanelContainer.visible = false
	%ToggleLogButton.text = "📋 Show Log"
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
		
	# Enemy panel background style
	var enemy_panel = %EnemyPanelContainer as PanelContainer
	if enemy_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.08, 0.08, 0.85) # Reddish dark bg
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.2, 0.2, 1.0)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		enemy_panel.add_theme_stylebox_override("panel", style)
		
	# Log background style
	var log_panel = %LogPanelContainer as PanelContainer
	if log_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.1, 0.85)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = GameColors.PANEL_BORDER_DEFAULT
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		log_panel.add_theme_stylebox_override("panel", style)

func duplicate_unit_instance(inst: UnitInstance) -> UnitInstance:
	if not inst:
		return null
	var new_inst = UnitInstance.new()
	new_inst.data = inst.data
	new_inst.current_health = inst.current_health
	new_inst.current_attack = inst.current_attack
	new_inst.poison = inst.poison
	new_inst.heal = inst.heal
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
		log_text("No active run found. Returning to shop.")
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
	log_text("[color=#ffff40]=== BATTLE STARTED ===[/color]")
	
	for i in range(6):
		if current_team[i]:
			var results = ModifierEngine.trigger_unit_modifiers(i, current_team, UnitModifier.Trigger.ON_BATTLE_START)
			for mod in results:
				var affected = results[mod]
				if not affected.is_empty():
					log_modifier(i, mod, affected)
					
	# Update all health and stat overlays
	_update_all_card_uis()

func trigger_cast(source_idx: int) -> void:
	var unit = current_team[source_idx]
	if not unit:
		return

	# Attack practice dummy!
	var dmg = unit.get_attack()
	if dmg > 0:
		enemy_damage_taken += dmg
		log_text("⚔️ [color=#ff6060]%s (slot %d) dealt %d damage to Enemy Dummy[/color] (Total Damage: %d)" % [unit.get_unit_name(), source_idx, dmg, enemy_damage_taken])

	# Apply poison if unit has poison value!
	if unit.poison > 0:
		enemy_poison += unit.poison
		log_text("☠️ [color=#d050d0]%s (slot %d) applied %d Poison to Enemy Dummy[/color] (Poison Stack: %d)" % [unit.get_unit_name(), source_idx, unit.poison, enemy_poison])
	
	# Heal team if unit has heal value!
	if unit.heal > 0:
		team_health = min(team_health + unit.heal, team_max_health)
		log_text("💚 [color=#20ff20]%s (slot %d) healed Team for %d HP[/color]" % [unit.get_unit_name(), source_idx, unit.heal])
		update_team_health_bar()
		
	_update_enemy_ui()

	# Perform ON_CAST action
	log_text("[color=#40a0ff]%s (slot %d) casts![/color]" % [unit.get_unit_name(), source_idx])
	var cast_results = ModifierEngine.trigger_unit_modifiers(source_idx, current_team, UnitModifier.Trigger.ON_CAST)
	for mod in cast_results:
		var affected = cast_results[mod]
		if not affected.is_empty():
			log_modifier(source_idx, mod, affected)
			
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
			log_text("⚠️ [color=#ffaa00]Sudden Death! Fatigue damage is now active![/color]")
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
			log_text("💀 [color=#ff3030]Fatigue ticks (Level %d, Tick %d): dealing %d damage to Team HP[/color]" % [stage, fatigue_tick_count, dmg])
			
			if team_shield >= dmg:
				team_shield -= dmg
			else:
				var remaining_dmg = dmg - team_shield
				team_shield = 0
				team_health -= remaining_dmg
				
			_update_all_card_uis()

	# Tick enemy poison status every second!
	if enemy_poison > 0:
		enemy_poison_timer += delta
		if enemy_poison_timer >= 1.0:
			enemy_poison_timer -= 1.0
			enemy_damage_taken += enemy_poison
			enemy_poison_damage_dealt += enemy_poison
			log_text("[color=#d050d0]☠️ Enemy Dummy took %d poison damage (Total Damage: %d)[/color]" % [enemy_poison, enemy_damage_taken])
			_update_enemy_ui()
	else:
		enemy_poison_timer = 0.0

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

func log_modifier(source_idx: int, modifier: UnitModifier, affected_indices: Array[int]) -> void:
	var source_unit = current_team[source_idx]
	if not source_unit:
		return
		
	var source_name = source_unit.get_unit_name()
	var target_names = []
	for idx in affected_indices:
		var target_unit = current_team[idx]
		if target_unit:
			target_names.append("%s (slot %d)" % [target_unit.get_unit_name(), idx])
			
	var targets_str = ", ".join(target_names)
	if targets_str.is_empty():
		return
		
	var effect_desc = ""
	match modifier.effect:
		UnitModifier.EffectType.BUFF_ATTACK:
			effect_desc = "[color=#f2b726]buffed Attack by +%d[/color]" % modifier.value
		UnitModifier.EffectType.BUFF_HEALTH:
			effect_desc = "[color=#10ff10]buffed Health by +%d[/color]" % modifier.value
		UnitModifier.EffectType.BUFF_HEAL:
			effect_desc = "[color=#10ff50]healed by +%d[/color]" % modifier.value
		UnitModifier.EffectType.APPLY_POISON:
			effect_desc = "[color=#d050d0]applied %d Poison[/color]" % modifier.value
		UnitModifier.EffectType.BUFF_SHIELD:
			effect_desc = "[color=#30c0ff]shielded by %d[/color]" % modifier.value
		UnitModifier.EffectType.TRIGGER_MODIFIERS:
			effect_desc = "[color=#ff80ff]triggered modifiers[/color]"
			
	var msg = "   > [color=#f0d060]%s (slot %d)[/color] %s on %s" % [source_name, source_idx, effect_desc, targets_str]
	log_text(msg)

func log_text(msg: String) -> void:
	if %BattleLogLabel:
		%BattleLogLabel.text = msg + "\n" + %BattleLogLabel.text
		call_deferred("_scroll_log_to_top")

func _scroll_log_to_top() -> void:
	var scroll = %BattleLogScroll as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 0

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
	log_text("[color=#ffff40]=== SIMULATION RESET ===[/color]")
	set_playing(false)
	
	# Reset Enemy Stats
	enemy_damage_taken = 0
	enemy_poison = 0
	enemy_poison_timer = 0.0
	enemy_poison_damage_dealt = 0
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
			if current_team[i]:
				var persistent_unit = CurrentRun.state.active_team[i]
				if persistent_unit:
					# Reset temporary health bonus first
					persistent_unit.temp_max_health_bonus = 0
					current_team[i].temp_max_health_bonus = 0
					# Restore health to max when safely returning to shop
					persistent_unit.max_health_bonus = current_team[i].max_health_bonus
					persistent_unit.current_health = persistent_unit.get_max_health()
					persistent_unit.current_attack = current_team[i].current_attack
					persistent_unit.poison = current_team[i].poison
					persistent_unit.current_cast_speed = current_team[i].current_cast_speed
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
	if has_node("%DamageLabel"):
		%DamageLabel.text = "Damage Taken: " + str(enemy_damage_taken)
	if has_node("%PoisonLabel"):
		%PoisonLabel.text = "☠️ Poison: %d (Total Dmg: %d)" % [enemy_poison, enemy_poison_damage_dealt]

func _update_poison_cooldown_progress() -> void:
	var bar_fill = get_node_or_null("%BarFill") as ColorRect
	if bar_fill:
		var ratio = 0.0
		if enemy_poison > 0:
			ratio = clamp(enemy_poison_timer / 1.0, 0.0, 1.0)
		bar_fill.anchor_right = ratio

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

func _on_toggle_log_pressed() -> void:
	if %LogPanelContainer and %ToggleLogButton:
		%LogPanelContainer.visible = not %LogPanelContainer.visible
		if %LogPanelContainer.visible:
			%ToggleLogButton.text = "📋 Hide Log"
		else:
			%ToggleLogButton.text = "📋 Show Log"

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
	log_text("💀 [color=#ff3333]Your team has been defeated![/color]")
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
