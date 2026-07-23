class_name MysticSaplingModifier
extends UnitModifier

func evolve(unit_inst: UnitInstance) -> void:
	var mystic_sentinel_template: UnitData = load("res://src/features/units/templates/mystic_sentinel.tres") as UnitData
	if mystic_sentinel_template:
		unit_inst.evolve(mystic_sentinel_template)

func apply_modifier(_source_idx: int, _team_obj: BattleTeamModel) -> void:
	pass

func get_description(_p_level: int = 1) -> String:
	return "Evolves into [color=%s]Mystic Sentinel[/color] upon reaching Level 3." % GameColors.DESC_GOLD
