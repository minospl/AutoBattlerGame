class_name UnitModifier
extends Resource

enum Trigger {
	ON_CAST,
	ON_BATTLE_START,
	ON_DEATH,
	ON_TAKE_DAMAGE
}

enum EffectType {
	BUFF_ATTACK,
	BUFF_HEALTH,
	APPLY_POISON,
	BUFF_SHIELD
}

enum Duration {
	BATTLE,
	PERMANENT
}

@export var trigger: Trigger
@export var effect: EffectType
@export var value: int
@export var duration: Duration

func get_description() -> String:
	var trigger_str = ""
	match trigger:
		Trigger.ON_CAST:
			trigger_str = "On Cast"
		Trigger.ON_BATTLE_START:
			trigger_str = "On Battle Start"
		Trigger.ON_DEATH:
			trigger_str = "On Death"
		Trigger.ON_TAKE_DAMAGE:
			trigger_str = "On Take Damage"

	var effect_str = ""
	match effect:
		EffectType.BUFF_ATTACK:
			effect_str = "+%d Attack" % value
		EffectType.BUFF_HEALTH:
			effect_str = "+%d Health" % value
		EffectType.APPLY_POISON:
			effect_str = "+%d Poison" % value
		EffectType.BUFF_SHIELD:
			effect_str = "+%d Shield" % value

	var dur_str = ""
	match duration:
		Duration.BATTLE:
			dur_str = "for this battle"
		Duration.PERMANENT:
			dur_str = "permanently"

	return "%s\n%s %s" % [trigger_str, effect_str, dur_str]
