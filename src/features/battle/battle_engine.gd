class_name BattleEngine
extends RefCounted

signal battle_started
signal simulation_ticked(delta: float)
signal battle_finished(outcome: String)
signal timer_changed(time_remaining: float)
signal fatigue_ticked(damage: int)

var player_team: BattleTeamModel
var enemy_team: BattleTeamModel

var match_timer: float = 30.0
var fatigue_tick_timer: float = 0.0
var fatigue_tick_count: int = 0

var battle_start_triggered: bool = false
var is_finished: bool = false
var outcome: String = ""
var total_elapsed_time: float = 0.0

func _init(p_player_team: BattleTeamModel = null, p_enemy_team: BattleTeamModel = null) -> void:
	player_team = p_player_team
	enemy_team = p_enemy_team

func load_teams(
	player_units: Array[UnitInstance],
	player_base_health: int,
	player_relics: Array[RelicInstance],
	enemy_units: Array[UnitInstance],
	enemy_base_health: int,
	enemy_relics: Array[RelicInstance]
) -> void:
	player_team.load_team_units(player_units, player_base_health)
	player_team.active_relics = player_relics
	player_team.has_magnetic_core = RelicInstance.has_relic(player_relics, "Magnetic Core")
	player_team.has_focusing_lens = RelicInstance.has_relic(player_relics, "Focusing Lens")

	enemy_team.load_team_units(enemy_units, enemy_base_health)
	enemy_team.active_relics = enemy_relics
	enemy_team.has_magnetic_core = RelicInstance.has_relic(enemy_relics, "Magnetic Core")
	enemy_team.has_focusing_lens = RelicInstance.has_relic(enemy_relics, "Focusing Lens")

	_connect_team_signals()
	reset()
	
	ModifierEngine.update_ongoing_modifiers(player_team, enemy_team)
	ModifierEngine.update_ongoing_modifiers(enemy_team, player_team)

func _connect_team_signals() -> void:
	if player_team and not player_team.team_defeated.is_connected(check_battle_end):
		player_team.team_defeated.connect(check_battle_end)
	if enemy_team and not enemy_team.team_defeated.is_connected(check_battle_end):
		enemy_team.team_defeated.connect(check_battle_end)

func reset() -> void:
	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	battle_start_triggered = false
	is_finished = false
	outcome = ""
	total_elapsed_time = 0.0

func trigger_battle_start() -> void:
	if battle_start_triggered:
		return
	battle_start_triggered = true

	for i: int in range(BattleTeamModel.MAX_TEAM_SIZE):
		if player_team.units[i]:
			ModifierEngine.trigger_unit_modifier(i, player_team, UnitModifier.Trigger.ON_BATTLE_START)
		if enemy_team.units[i]:
			ModifierEngine.trigger_unit_modifier(i, enemy_team, UnitModifier.Trigger.ON_BATTLE_START)

	for relic: RelicInstance in player_team.active_relics:
		if relic.data and relic.data.modifier:
			relic.data.modifier.on_battle_start(relic, player_team, enemy_team)

	for relic: RelicInstance in enemy_team.active_relics:
		if relic.data and relic.data.modifier:
			relic.data.modifier.on_battle_start(relic, enemy_team, player_team)

	ModifierEngine.update_ongoing_modifiers(player_team, enemy_team)
	ModifierEngine.update_ongoing_modifiers(enemy_team, player_team)

	battle_started.emit()

func trigger_cast(source_idx: int) -> void:
	if is_finished:
		return
	player_team.execute_cast(source_idx, enemy_team)

func trigger_enemy_cast(source_idx: int) -> void:
	if is_finished:
		return
	enemy_team.execute_cast(source_idx, player_team)

func advance_simulation(delta: float) -> void:
	if is_finished:
		return

	if not battle_start_triggered:
		trigger_battle_start()

	total_elapsed_time += delta

	# Update match timer
	if match_timer > 0.0:
		match_timer -= delta
		if match_timer <= 0.0:
			match_timer = 0.0
		timer_changed.emit(match_timer)
	else:
		# Fatigue damage active
		fatigue_tick_timer += delta
		if fatigue_tick_timer >= 1.0:
			fatigue_tick_timer -= 1.0
			fatigue_tick_count += 1
			var stage: int = floori((fatigue_tick_count - 1) / 3.0) + 1
			var dmg: int = get_fibonacci(stage + 1)
			fatigue_ticked.emit(dmg)
			player_team.take_damage(dmg, BattleTeamModel.DamageType.FATIGUE)
			enemy_team.take_damage(dmg, BattleTeamModel.DamageType.FATIGUE)

	if is_finished:
		return

	# Tick statuses
	player_team.tick_statuses(delta)
	enemy_team.tick_statuses(delta)

	if is_finished:
		return

	# Update ongoing modifiers
	ModifierEngine.update_ongoing_modifiers(player_team, enemy_team)
	ModifierEngine.update_ongoing_modifiers(enemy_team, player_team)

	# Tick card casts
	player_team.tick_casts(delta, trigger_cast)
	enemy_team.tick_casts(delta, trigger_enemy_cast)

	simulation_ticked.emit(delta)

	check_battle_end()

func check_battle_end() -> void:
	if is_finished:
		return

	var p_dead: bool = player_team.health <= 0
	var e_dead: bool = enemy_team.health <= 0

	if p_dead and e_dead:
		finish_battle("draw")
	elif e_dead:
		finish_battle("victory")
	elif p_dead:
		finish_battle("defeat")

func finish_battle(p_outcome: String) -> void:
	if is_finished:
		return
	is_finished = true
	outcome = p_outcome
	battle_finished.emit(outcome)

static func get_fibonacci(n: int) -> int:
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

static func simulate_battle(
	player_units: Array[UnitInstance],
	player_base_health: int,
	player_relics: Array[RelicInstance],
	enemy_units: Array[UnitInstance],
	enemy_base_health: int,
	enemy_relics: Array[RelicInstance],
	delta_step: float = 0.05,
	max_simulation_time: float = 300.0
) -> Dictionary[String, Variant]:
	var p_team: BattleTeamModel = BattleTeamModel.new()
	p_team.initialize(false)

	var e_team: BattleTeamModel = BattleTeamModel.new()
	e_team.initialize(true)

	var engine: BattleEngine = BattleEngine.new(p_team, e_team)
	engine.load_teams(
		player_units,
		player_base_health,
		player_relics,
		enemy_units,
		enemy_base_health,
		enemy_relics
	)

	var sim_gold: Array[int] = [0]
	p_team.gold_generated.connect(func(amount: int) -> void: sim_gold[0] += amount)

	var elapsed: float = 0.0
	while not engine.is_finished and elapsed < max_simulation_time:
		engine.advance_simulation(delta_step)
		elapsed += delta_step

	if not engine.is_finished:
		engine.check_battle_end()
		if not engine.is_finished:
			engine.finish_battle("draw")

	var result: Dictionary[String, Variant] = {
		"outcome": engine.outcome,
		"total_time": engine.total_elapsed_time,
		"player_units": p_team.units,
		"enemy_units": e_team.units,
		"generated_gold": sim_gold[0]
	}

	engine.player_team.team_defeated.disconnect(engine.check_battle_end)
	engine.enemy_team.team_defeated.disconnect(engine.check_battle_end)

	return result
