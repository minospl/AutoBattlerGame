class_name MysticBranchModifier
extends UnitModifier

func evolve(unit_inst: UnitInstance) -> void:
	var holy_tree_template: UnitData = load("res://src/features/units/templates/holy_tree.tres") as UnitData
	if holy_tree_template:
		unit_inst.evolve(holy_tree_template)

func apply_modifier(_source_idx: int, _team_obj: BattleTeamModel) -> void:
	pass

func get_description(_p_level: int = 1) -> String:
	return "Evolves into [color=%s]Holy Tree[/color] upon reaching Level 3." % GameColors.DESC_GOLD
