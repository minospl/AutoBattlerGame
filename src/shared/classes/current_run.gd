class_name CurrentRunNode
extends Node

var state: RunState

func initialize_new_run(templates: Array[UnitData]) -> void:
	print("[CurrentRun] Initializing new run state.")
	state = RunState.new()
	state.active_team.resize(6)
	state.bench.resize(8)
	state.shop_units.resize(4)
	state.shop_frozen_statuses = [false, false, false, false]
	state.gold = 10
	state.lives = 10
	state.day = 4
	state.trophies = 3
	state.max_trophies = 10
	
	# Find templates by unit name
	var find_template = func(p_name: String) -> UnitData:
		for t in templates:
			if t.unit_name.to_lower() == p_name.to_lower():
				return t
		return null

	var titan = find_template.call("Ancient Titan")
	var spellweaver = find_template.call("Spellweaver")
	var druid = find_template.call("Vitality Druid")

	# Populate active team:
	# Slot 0: Ancient Titan, Slot 1: Spellweaver, Slot 2: null
	# Slot 3: Vitality Druid, Slot 4: null, Slot 5: null
	var setup = [titan, spellweaver, null, druid, null, null]
	for i in range(6):
		var temp = setup[i]
		if temp:
			var instance = UnitInstance.new()
			instance.initialize(temp)
			state.active_team[i] = instance
		else:
			state.active_team[i] = null
