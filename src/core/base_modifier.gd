class_name BaseModifier
extends Resource

enum Trigger {
	ON_CAST,
	ON_BATTLE_START,
	ON_TAKE_DAMAGE,
	ONGOING,
	ON_BATTLE_END,
	ON_VICTORY,
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

func get_implied_keywords() -> Array[String]:
	return []

func get_trigger_name(p_trigger: Trigger) -> String:
	var title: String = "???"
	match p_trigger:
		Trigger.ON_BATTLE_START:
			title = "ON BATTLE START"
		Trigger.ON_BATTLE_END:
			title = "ON BATTLE END"
		Trigger.ON_CAST:
			title = "ON CAST"
		Trigger.ON_TAKE_DAMAGE:
			title = "ON TAKE DAMAGE"
		Trigger.ONGOING:
			title = "ONGOING"
		Trigger.ON_VICTORY:
			title = "ON VICTORY"

	return "[color=%s]%s[/color]" % [GameColors.DESC_TRIGGER, title]
