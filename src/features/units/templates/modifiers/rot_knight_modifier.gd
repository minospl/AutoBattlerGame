class_name RotKnightModifier
extends UnitModifier

@export var value_1: int = 3
@export var value_2: int = 6
@export var value_3: int = 12

func get_modifier_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(value_1)
		2: return float(value_2)
		3: return float(value_3)
	return float(value_1)

func apply_modifier(_source_idx: int, _team_obj: BattleTeamModel) -> void:
	pass

func apply_ongoing(source_idx: int, team_obj: BattleTeamModel, opponent: BattleTeamModel) -> void:
	var b_unit: BattleUnitInstance = team_obj.units[source_idx] as BattleUnitInstance
	var total_statuses: int = opponent.poison + opponent.burn + opponent.electrocute
	var bonus: int = total_statuses * int(get_modifier_value(b_unit.level))
	if b_unit.ongoing_attack_bonus != bonus:
		b_unit.ongoing_attack_bonus = bonus
		team_obj.unit_stats_changed.emit(source_idx)

func get_description(p_level: int = 1) -> String:
	var bonus: int = int(get_modifier_value(p_level))
	return "%s\nGains [color=%s]+%d Attack[/color] for every stack of Poison, Burn, or Electrocute on the opponent team." % [get_trigger_name(), GameColors.DESC_ATTACK, bonus]
