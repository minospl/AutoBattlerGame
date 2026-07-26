class_name UnitModifier
extends Resource

enum Trigger {
	ON_CAST,
	ON_BATTLE_START,
	ON_TAKE_DAMAGE,
	ONGOING,
	ON_BATTLE_END,
}

enum TargetType {
	SELF,
	HORIZONTAL,
	VERTICAL,
	ADJACENT,
	UP,
	DOWN,
	LEFT,
	RIGHT,
	ALL,
	LEFT_PLUS,
	RIGHT_PLUS,
	HORIZONTAL_PLUS
}

@export var trigger: Trigger
@export var target: TargetType = TargetType.SELF
@export var is_exclusive: bool = false

func apply_shop_modifier(_source_idx: int, _team_units: Array) -> void:
	pass

func apply_effect(_target_unit: UnitInstance, _level: int) -> void:
	pass

func apply_modifier(_source_idx: int, _team_obj: BattleTeamModel) -> void:
	pass

func get_trigger_name(p_trigger: Trigger = trigger) -> String:
	var name: String = "???"
	match p_trigger:
		Trigger.ON_BATTLE_START:
			name = "ON BATTLE START"
		Trigger.ON_BATTLE_END:
			name = "ON BATTLE END"
		Trigger.ON_CAST:
			name = "ON CAST"
		Trigger.ON_TAKE_DAMAGE:
			name = "ON TAKE DAMAGE"
		Trigger.ONGOING:
			name = "ONGOING"

	return "[color=%s]%s[/color]" % [GameColors.DESC_TRIGGER, name]

func get_target(_p_level: int = 1) -> TargetType:
	return target

func get_description(_p_level: int = 1) -> String:
	push_error("Abstract method get_description() must be overridden in subclass of UnitModifier!")
	assert(false, "Subclass must override get_description()")
	return ""

func get_implied_keywords() -> Array[String]:
	return []

func apply_ongoing(_source_idx: int, _team_obj: BattleTeamModel, _opponent: BattleTeamModel) -> void:
	pass
