class_name UnitModifier
extends Resource

enum Trigger {
	ON_CAST,
	ON_BATTLE_START,
	ON_TAKE_DAMAGE
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

func apply_modifier(_source_idx: int, _team_obj: BattleTeam) -> void:
	push_error("Abstract method apply_modifier() must be overridden in subclass of UnitModifier!")
	assert(false, "Subclass must override apply_modifier()")

func get_trigger_name(p_trigger: Trigger = trigger) -> String:
	var name: String = "???"
	match p_trigger:
		Trigger.ON_CAST:
			name = "On Cast"
		Trigger.ON_BATTLE_START:
			name = "On Battle Start"
		Trigger.ON_TAKE_DAMAGE:
			name = "On Take Damage"

	return "[color=%s]%s[/color]" % [GameColors.DESC_TRIGGER, name]

func get_target(_p_level: int = 1) -> TargetType:
	return target

func get_modifier_value(_p_level: int = 1) -> float:
	push_error("Abstract method get_modifier_value() must be overridden in subclass of UnitModifier!")
	assert(false, "Subclass must override get_modifier_value()")
	return 0.0

func get_description(_p_level: int = 1) -> String:
	push_error("Abstract method get_description() must be overridden in subclass of UnitModifier!")
	assert(false, "Subclass must override get_description()")
	return ""
