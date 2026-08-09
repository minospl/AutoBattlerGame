class_name DebugManager
extends Node

var run_state: RunState
var shop_scene: Node

func setup(p_run_state: RunState, p_shop_scene: Node) -> void:
	run_state = p_run_state
	shop_scene = p_shop_scene
	
	var sim_btn: Button = shop_scene.get_node_or_null("%SimulateBattleButton") as Button
	if sim_btn:
		sim_btn.pressed.connect(_on_simulate_battle_pressed)

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

func _on_simulate_battle_pressed() -> void:
	if run_state == null:
		return

	# Prepare player units (cloned)
	var player_units: Array[UnitInstance] = []
	for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
		var inst: UnitInstance = run_state.active_team[i]
		if inst:
			player_units.append(inst.clone())
		else:
			player_units.append(null)

	# Prepare player relics (cloned)
	var player_relics: Array[RelicInstance] = []
	for relic: RelicInstance in run_state.relics:
		player_relics.append(relic.clone())

	# Prepare enemy units & relics (cloned)
	var enemy_units: Array[UnitInstance] = []
	enemy_units.resize(RunData.MAX_ACTIVE_TEAM_SIZE)
	var enemy_relics: Array[RelicInstance] = []

	var opponent: OpponentProfile = run_state.next_opponent
	if opponent and not opponent.data.active_team.is_empty():
		for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
			if i < opponent.data.active_team.size() and opponent.data.active_team[i] != null:
				enemy_units[i] = opponent.data.active_team[i].clone()
		enemy_relics = opponent.data.relics

	# Run simulation via BattleEngine
	var result: Dictionary[String, Variant] = BattleEngine.simulate_battle(
		player_units,
		run_state.base_health,
		player_relics,
		enemy_units,
		RunData.STARTING_BASE_HEALTH,
		enemy_relics
	)

	_print_simulation_report(result, run_state.active_team, opponent)

func _print_simulation_report(result: Dictionary[String, Variant], original_player_units: Array[UnitInstance], opponent: OpponentProfile) -> void:
	var outcome: String = str(result.get("outcome", "UNKNOWN")).to_upper()
	var total_time: float = result.get("total_time", 0.0)
	var p_hp: int = result.get("player_final_health", 0)
	var e_hp: int = result.get("enemy_final_health", 0)
	var sim_p_units: Array = result.get("player_units", [])
	var sim_e_units: Array = result.get("enemy_units", [])

	var outcome_color: String = "gold"
	if outcome == "DEFEAT":
		outcome_color = "red"
	elif outcome == "DRAW":
		outcome_color = "gray"

	print_rich("[color=cyan]===========================================================[/color]")
	print_rich("[color=cyan]            🧪 BATTLE SIMULATION REPORT 🧪[/color]")
	print_rich("[color=cyan]===========================================================[/color]")
	print_rich("[b]OUTCOME:[/b] [color=%s][b]%s[/b][/color]" % [outcome_color, outcome])
	print_rich("[b]ESTIMATED DURATION:[/b] %.1fs" % total_time)
	print_rich("[b]PLAYER TEAM FINAL HP:[/b] %d" % p_hp)
	print_rich("[b]ENEMY TEAM FINAL HP:[/b]  %d" % e_hp)
	print_rich("-----------------------------------------------------------")
	
	# Player Team Table
	print_rich("[color=yellow][b]--- PLAYER TEAM STATS (BEFORE ➔ AFTER) ---[/b][/color]")
	for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
		var orig: UnitInstance = original_player_units[i] if i < original_player_units.size() else null
		var sim_unit: UnitInstance = sim_p_units[i] if i < sim_p_units.size() else null
		_print_unit_stats(i, orig, sim_unit)

	print_rich("-----------------------------------------------------------")
	# Enemy Team Table
	var opp_name: String = opponent.name if opponent else "Enemy"
	print_rich("[color=orange][b]--- ENEMY TEAM (%s) STATS (BEFORE ➔ AFTER) ---[/b][/color]" % opp_name)
	var orig_enemy_units: Array[UnitInstance] = opponent.data.active_team if opponent else []
	for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
		var orig: UnitInstance = orig_enemy_units[i] if i < orig_enemy_units.size() else null
		var sim_unit: UnitInstance = sim_e_units[i] if i < sim_e_units.size() else null
		_print_unit_stats(i, orig, sim_unit)

	print_rich("[color=cyan]===========================================================[/color]\n")

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
