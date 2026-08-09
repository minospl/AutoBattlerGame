class_name DebugManager
extends Node

var run_state: RunState
var shop_scene: Node

func setup(p_run_state: RunState, p_shop_scene: Node) -> void:
	run_state = p_run_state
	shop_scene = p_shop_scene
	
	var sim_btn: Button = shop_scene.get_node_or_null("%SimulateBattleButton") as Button
	if sim_btn:
		var parent: Node = sim_btn.get_parent()
		var index: int = sim_btn.get_index()
		
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.custom_minimum_size = sim_btn.custom_minimum_size
		vbox.add_theme_constant_override("separation", 4)
		
		parent.remove_child(sim_btn)
		parent.add_child(vbox)
		parent.move_child(vbox, index)
		
		var bot_btn: Button = sim_btn.duplicate() as Button
		bot_btn.text = "SIMULATE BOT"
		bot_btn.custom_minimum_size = Vector2.ZERO
		bot_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bot_btn.add_theme_font_size_override("font_size", 14)
		bot_btn.pressed.connect(func() -> void: _run_sandbox_simulation(false))
		
		sim_btn.text = "SIMULATE PLAYER"
		sim_btn.custom_minimum_size = Vector2.ZERO
		sim_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sim_btn.add_theme_font_size_override("font_size", 14)
		sim_btn.pressed.connect(func() -> void: _run_sandbox_simulation(true))
		
		vbox.add_child(bot_btn)
		vbox.add_child(sim_btn)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
		
	var key_event: InputEventKey = event as InputEventKey
	match key_event.keycode:
		KEY_1:
			_add_random_monster()
		KEY_2:
			add_all_non_unique_relics()
		KEY_3:
			add_all_unique_relics()
		KEY_4:
			run_state.gold += 100
		KEY_5:
			if run_state:
				run_state.shop_level += 1

func _add_random_monster() -> void:
	if not run_state or run_state.unit_templates.is_empty():
		return
		
	var template: UnitData = run_state.unit_templates[randi() % run_state.unit_templates.size()]
	var instance: UnitInstance = UnitInstance.new()
	instance.initialize(template)
	
	var added: bool = false
	for i: int in range(run_state.bench.size()):
		if run_state.bench[i] == null:
			run_state.bench[i] = instance
			added = true
			break
			
	if added and shop_scene:
		if shop_scene.has_method("populate_ui"):
			shop_scene.call("populate_ui")
		if shop_scene.has_signal("team_state_changed"):
			var sig: Signal = shop_scene.get("team_state_changed")
			sig.emit()

func add_all_non_unique_relics() -> void:
	if not run_state:
		return
		
	for template: RelicData in run_state.relic_templates:
		if template.rarity.rarity_type == Rarity.Type.UNIQUE:
			continue
			
		var relic_inst: RelicInstance = RelicInstance.new()
		relic_inst.initialize(template)
		run_state.add_relic(relic_inst)

func add_all_unique_relics() -> void:
	for template: RelicData in run_state.relic_templates:
		if template.rarity.rarity_type != Rarity.Type.UNIQUE:
			continue
			
		if run_state.has_relic(template.display_name):
			continue

		var relic_inst: RelicInstance = RelicInstance.new()
		relic_inst.initialize(template)
		run_state.add_relic(relic_inst)

func handle_card_right_click(card: UnitCard) -> void:
	if not card or not card.unit_instance:
		return
		
	card.unit_instance.level_up()
	card.update_ui()
	
	if shop_scene:
		var preview_tooltip: Control = shop_scene.get("preview_tooltip")
		var current_hovered_card: Control = shop_scene.get("current_hovered_card")
		if preview_tooltip and preview_tooltip.visible and current_hovered_card == card:
			CardUIHelper.show_tooltip(preview_tooltip as CardTooltip, card.unit_instance)
			
		if shop_scene.has_method("check_for_unit_merges"):
			shop_scene.call("check_for_unit_merges")
			
		if shop_scene.has_signal("team_state_changed"):
			var sig: Signal = shop_scene.get("team_state_changed")
			sig.emit()

func on_card_gui_input(event: InputEvent, card: UnitCard) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			handle_card_right_click(card)
			if shop_scene and shop_scene.is_inside_tree():
				shop_scene.get_viewport().set_input_as_handled()

func _run_sandbox_simulation(is_human_active: bool) -> void:
	if run_state == null:
		return

	var opponent: OpponentProfile = run_state.next_opponent
	if opponent == null:
		print_rich("[color=red]Cannot run simulation: No opponent available![/color]")
		return

	var active_data: RunData = run_state.data if is_human_active else opponent.data
	var enemy_data: RunData = opponent.data if is_human_active else run_state.data
	
	var active_title: String = "HUMAN TEAM (Active)" if is_human_active else "BOT TEAM (%s) (Active)" % opponent.name
	var enemy_title: String = "BOT TEAM (%s) (Static)" % opponent.name if is_human_active else "HUMAN TEAM (Static)"

	var result: Dictionary = SimulationSandbox.run_sandbox_battle(
		active_data,
		enemy_data,
		run_state.unit_templates,
		run_state.item_templates,
		run_state.relic_templates
	)

	var sim_mode: String = "SIMULATION PLAYER" if is_human_active else "SIMULATION BOT"
	_prepare_simulation_report(result, active_data, active_title, enemy_title, sim_mode)

func _prepare_simulation_report(result: Dictionary, orig_state: RunData, active_title: String, enemy_title: String, sim_mode: String) -> void:
	var dummy_state: RunState = result.get("dummy_state")
	var orig_enemy_units: Array[UnitInstance] = result.get("orig_enemy_units", [])
	var final_enemy_units: Array[UnitInstance] = result.get("final_enemy_units", [])
	
	var outcome: String = str(result.get("outcome", "UNKNOWN")).to_upper()
	var total_time: float = result.get("total_time", 0.0)

	var outcome_color: String = "gold"
	if outcome == "DEFEAT":
		outcome_color = "red"
	elif outcome == "DRAW":
		outcome_color = "gray"

	# Calculate Active Player Gold
	var p_gold_before: int = orig_state.gold
	var p_gold_after: int = dummy_state.gold
	var total_gold_gain: int = RunData.DAY_GOLD_INCREASE + p_gold_after - p_gold_before

	_print_battle_result(
		active_title, enemy_title, 
		outcome, outcome_color, total_time, 
		p_gold_before, total_gold_gain, 
		orig_state.active_team, dummy_state.active_team, 
		orig_enemy_units, final_enemy_units, sim_mode
	)

func _print_battle_result(active_title: String, enemy_title: String, outcome: String, outcome_color: String, total_time: float, active_gold_before: int, active_gold_gain: int, active_orig_units: Array, active_final_units: Array, enemy_orig_units: Array, enemy_final_units: Array, sim_mode: String) -> void:
	print_rich("[color=cyan]===========================================================[/color]")
	print_rich("[color=cyan]            🧪 BATTLE SIMULATION REPORT 🧪[/color]")
	print_rich("[color=cyan]===========================================================[/color]")
	print_rich("[b]OUTCOME:[/b] [color=%s][b]%s[/b][/color] (%s | Time: %.1fs)" % [outcome_color, outcome, sim_mode, total_time])
	print_rich("-----------------------------------------------------------")
	
	if active_gold_before >= 0:
		var gold_after: int = active_gold_before + active_gold_gain
		print_rich("[color=yellow]Gold:[/color] %d ➔ %d (+%d)" % [active_gold_before, gold_after, active_gold_gain])
		print_rich("-----------------------------------------------------------")

	_print_player_result(active_title, "yellow", active_orig_units, active_final_units)

	print_rich("-----------------------------------------------------------")
	
	_print_player_result(enemy_title, "orange", enemy_orig_units, enemy_final_units)

	print_rich("[color=cyan]===========================================================[/color]\n")

func _print_player_result(team_name_title: String, color_tag: String, orig_units: Array, sim_units: Array) -> void:
	print_rich("[color=%s][b]--- %s STATS (BEFORE ➔ AFTER) ---[/b][/color]" % [color_tag, team_name_title])
	
	for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
		var orig: UnitInstance = orig_units[i] if i < orig_units.size() else null
		var sim_unit: UnitInstance = sim_units[i] if i < sim_units.size() else null
		_print_unit_stats(i, orig, sim_unit)

func _print_unit_stats(i: int, orig: UnitInstance, sim_unit: UnitInstance) -> void:
	if orig:
		print_rich(" Slot %d | [b]%s[/b] (★%d) %s" % [i, orig.data.display_name, orig.level, _format_unit_all_stats(orig, sim_unit)])
	else:
		print_rich(" Slot %d | [color=gray][EMPTY][/color]" % i)

func _format_unit_all_stats(orig: UnitInstance, sim: UnitInstance) -> String:
	var parts: Array[String] = []
	var extra_stats: Array[Dictionary] = [
		{"name": "CD", "o": orig.get_cast_speed(), "s": sim.get_cast_speed()},
		{"name": "ATK", "o": orig.get_attack(), "s": sim.get_attack()},
		{"name": "HP", "o": orig.health, "s": sim.health},
		{"name": "HEAL", "o": orig.heal, "s": sim.heal},
		{"name": "SHIELD", "o": orig.shield, "s": sim.shield},
		{"name": "POISON", "o": orig.poison, "s": sim.poison},
		{"name": "BURN", "o": orig.burn, "s": sim.burn},
		{"name": "ELEC", "o": orig.electrocute, "s": sim.electrocute}
	]

	for stat_info: Dictionary in extra_stats:
		var s_name: String = stat_info["name"]
		var o_val: Variant = stat_info["o"]
		var s_val: Variant = stat_info["s"]
		var diff: Variant = s_val - o_val
		var val_str: String = "%s➔%s" % [o_val, s_val]
		if s_val > o_val:
			val_str += " [color=green](%s)[/color]" % diff
		parts.append("%s: %s" % [s_name, val_str])

	return " | ".join(parts)
