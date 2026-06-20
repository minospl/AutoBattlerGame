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

enum EffectType {
	BUFF_ATTACK,
	BUFF_HEALTH,
	APPLY_POISON,
	BUFF_SHIELD,
	BUFF_HEAL,
	TRIGGER_MODIFIERS
}

enum Duration {
	BATTLE,
	PERMANENT
}

@export var trigger: Trigger
@export var target: TargetType = TargetType.SELF
@export var effect: EffectType
@export var value: int
@export var duration: Duration
@export var target_trigger: Trigger
@export var custom_description: String = ""

func get_description() -> String:
	var trigger_str = ""
	match trigger:
		Trigger.ON_CAST:
			trigger_str = "On Cast"
		Trigger.ON_BATTLE_START:
			trigger_str = "On Battle Start"
		Trigger.ON_TAKE_DAMAGE:
			trigger_str = "On Take Damage"

	# 1. Custom Description Override (with {value} placeholder support)
	if not custom_description.is_empty():
		var formatted_text = custom_description.format({"value": str(value)})
		return "%s\n%s" % [trigger_str, formatted_text]

	# 2. Auto-generated Description
	# Resolve targeting terms
	var target_phrase = ""
	var target_possession = ""
	match target:
		TargetType.SELF:
			target_phrase = "self"
			target_possession = "your own"
		TargetType.HORIZONTAL:
			target_phrase = "horizontal units"
			target_possession = "horizontal units'"
		TargetType.VERTICAL:
			target_phrase = "vertical units"
			target_possession = "vertical units'"
		TargetType.ADJACENT:
			target_phrase = "adjacent units"
			target_possession = "adjacent units'"
		TargetType.UP:
			target_phrase = "the unit above"
			target_possession = "the unit above's"
		TargetType.DOWN:
			target_phrase = "the unit below"
			target_possession = "the unit below's"
		TargetType.LEFT:
			target_phrase = "the unit to the left"
			target_possession = "the unit to the left's"
		TargetType.RIGHT:
			target_phrase = "the unit to the right"
			target_possession = "the unit to the right's"
		TargetType.ALL:
			target_phrase = "all allies"
			target_possession = "all allies'"

	# Resolve duration terms
	var dur_str = ""
	match duration:
		Duration.BATTLE:
			dur_str = "for this battle"
		Duration.PERMANENT:
			dur_str = "permanently"

	var effect_str = ""
	match effect:
		EffectType.BUFF_ATTACK:
			if target == TargetType.SELF:
				effect_str = "+%d Attack %s" % [value, dur_str]
			else:
				effect_str = "Give %s +%d Attack %s" % [target_phrase, value, dur_str]
		EffectType.BUFF_HEALTH:
			if target == TargetType.SELF:
				effect_str = "+%d Health %s" % [value, dur_str]
			else:
				effect_str = "Give %s +%d Health %s" % [target_phrase, value, dur_str]
		EffectType.BUFF_SHIELD:
			if target == TargetType.SELF:
				effect_str = "+%d Shield %s" % [value, dur_str]
			else:
				effect_str = "Give %s +%d Shield %s" % [target_phrase, value, dur_str]
		EffectType.BUFF_HEAL:
			if target == TargetType.SELF:
				effect_str = "+%d Heal %s" % [value, dur_str]
			else:
				effect_str = "Give %s +%d Heal %s" % [target_phrase, value, dur_str]
		EffectType.APPLY_POISON:
			if target == TargetType.SELF:
				effect_str = "Apply %d Poison to self" % value
			else:
				effect_str = "Apply %d Poison to %s" % [value, target_phrase]
		EffectType.TRIGGER_MODIFIERS:
			var target_trig_str = ""
			match target_trigger:
				Trigger.ON_CAST: target_trig_str = "On Cast"
				Trigger.ON_BATTLE_START: target_trig_str = "On Battle Start"
				Trigger.ON_TAKE_DAMAGE: target_trig_str = "On Take Damage"
			effect_str = "Trigger %s \"%s\" effects" % [target_possession, target_trig_str]

	return "%s\n%s" % [trigger_str, effect_str]
