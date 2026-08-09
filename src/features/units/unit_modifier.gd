class_name UnitModifier
extends BaseModifier

@export var trigger: Trigger
@export var target: TargetType = TargetType.SELF
@export var is_exclusive: bool = false

func apply_shop_modifier(_source_idx: int, _team_units: Array) -> void:
	pass

func apply_effect(_target_unit: UnitInstance, _level: int) -> void:
	pass

func apply_modifier(_source_idx: int, _team_obj: BattleTeamModel) -> void:
	pass

func get_trigger_name(p_trigger: BaseModifier.Trigger = trigger) -> String:
	return super.get_trigger_name(p_trigger)

func get_target(_p_level: int = 1) -> TargetType:
	return target

func get_description(_p_level: int = 1) -> String:
	push_error("Abstract method get_description() must be overridden in subclass of UnitModifier!")
	assert(false, "Subclass must override get_description()")
	return ""

func apply_ongoing(_source_idx: int, _team_obj: BattleTeamModel, _opponent: BattleTeamModel) -> void:
	pass
