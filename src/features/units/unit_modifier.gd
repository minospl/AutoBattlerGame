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
	ALL
}

@export var trigger: Trigger
@export var target: TargetType = TargetType.SELF
@export var custom_description: String = ""

func _apply_modifier(_source_idx: int, _team_obj: BattleTeam) -> void:
	pass

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

func get_description() -> String:
	if not custom_description.is_empty():
		return custom_description
	return ""
