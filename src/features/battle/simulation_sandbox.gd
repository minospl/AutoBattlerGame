class_name SimulationSandbox
extends RefCounted

## Uruchamia w pełni odizolowaną symulację bitwy pomiędzy dwoma profilami (RunData).
## `active_data` działa jako gracz "główny" (zbiera nagrody, wyzwala ON_BATTLE_END).
## `opponent_data` służy jako statyczny przeciwnik ("worek treningowy").
static func run_sandbox_battle(active_data: RunData, opponent_data: RunData, unit_templates: Array[UnitData], item_templates: Array[ItemData], relic_templates: Array[RelicData]) -> Dictionary:
	# 1. Inicjalizacja zamkniętego obiektu RunState (Piaskownicy) dla aktywnego gracza
	var dummy_state: RunState = RunState.new()
	dummy_state.setup_templates(unit_templates, item_templates, relic_templates)
	dummy_state.data = active_data.duplicate_data()
	
	# Przepięcie reliktów aktywnego gracza pod nowy stan
	for relic: RelicInstance in dummy_state.relics:
		if relic and relic.data and relic.data.modifier:
			relic.data.modifier.on_acquire(relic, dummy_state)

	# 2. Skonstruowanie statycznej drużyny przeciwnika
	var enemy_units: Array[UnitInstance] = []
	enemy_units.resize(RunData.MAX_ACTIVE_TEAM_SIZE)
	var orig_enemy_units: Array[UnitInstance] = []
	
	if not opponent_data.active_team.is_empty():
		orig_enemy_units = opponent_data.active_team
		for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
			if i < opponent_data.active_team.size() and opponent_data.active_team[i] != null:
				enemy_units[i] = opponent_data.active_team[i].clone()

	# 3. Odpalenie silnika bitewnego
	var result: Dictionary[String, Variant] = BattleEngine.simulate_battle(
		dummy_state.active_team,
		dummy_state.base_health,
		dummy_state.relics,
		enemy_units,
		opponent_data.base_health,
		opponent_data.relics
	)

	# 4. Zbieranie zysków wygenerowanych w trakcie bitwy (np. Thief's Glove)
	var generated_gold: int = result.get("generated_gold", 0)
	if generated_gold > 0:
		dummy_state.gold += generated_gold

	# 5. Wyzwalanie po-bitewnych modyfikatorów meta-progresji (bez odpalania pełnego TurnProcessora)
	var outcome: String = str(result.get("outcome", "UNKNOWN"))
	dummy_state.battle_completed.emit(outcome)
	
	for i: int in range(dummy_state.active_team.size()):
		var unit: UnitInstance = dummy_state.active_team[i]
		if unit and unit.data and unit.data.modifier and unit.data.modifier.get("trigger") == BaseModifier.Trigger.ON_BATTLE_END:
			unit.data.modifier.apply_shop_modifier(i, dummy_state.active_team)
			
	for i: int in range(dummy_state.bench.size()):
		var unit: UnitInstance = dummy_state.bench[i]
		if unit and unit.data and unit.data.modifier and unit.data.modifier.get("trigger") == BaseModifier.Trigger.ON_BATTLE_END:
			unit.data.modifier.apply_shop_modifier(i, dummy_state.bench)

	# 6. Budowanie i zwracanie kompleksowego słownika wynikowego
	return {
		"outcome": outcome,
		"total_time": result.get("total_time", 0.0),
		"sim_e_units": result.get("enemy_units", []), # Tymczasowe BattleUnitInstances
		"final_enemy_units": enemy_units,              # Zmodyfikowane (ale czyste) bazowe UnitInstances wroga
		"orig_enemy_units": orig_enemy_units,          # Oryginalne UnitInstances wroga przed sklonowaniem
		"dummy_state": dummy_state,                    # Zmodyfikowany RunState aktywnego gracza
		"enemy_base_health": opponent_data.base_health # Bazowe zdrowie wroga
	}
