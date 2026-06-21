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
			trigger_str = "[color=%s]On Cast[/color]" % GameColors.DESC_TRIGGER
		Trigger.ON_BATTLE_START:
			trigger_str = "[color=%s]On Battle Start[/color]" % GameColors.DESC_TRIGGER
		Trigger.ON_TAKE_DAMAGE:
			trigger_str = "[color=%s]On Take Damage[/color]" % GameColors.DESC_TRIGGER

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
			target_phrase = "[color=%s]SELF[/color]" % GameColors.DESC_TARGET
			target_possession = "your [color=%s]OWN[/color]" % GameColors.DESC_TARGET
		TargetType.HORIZONTAL:
			target_phrase = "[color=%s]HORIZONTAL[/color] allies" % GameColors.DESC_TARGET
			target_possession = "[color=%s]HORIZONTAL[/color] allies'" % GameColors.DESC_TARGET
		TargetType.VERTICAL:
			target_phrase = "[color=%s]VERTICAL[/color] allies" % GameColors.DESC_TARGET
			target_possession = "[color=%s]VERTICAL[/color] allies'" % GameColors.DESC_TARGET
		TargetType.ADJACENT:
			target_phrase = "[color=%s]ADJACENT[/color] allies" % GameColors.DESC_TARGET
			target_possession = "[color=%s]ADJACENT[/color] allies'" % GameColors.DESC_TARGET
		TargetType.UP:
			target_phrase = "the ally [color=%s]ABOVE[/color]" % GameColors.DESC_TARGET
			target_possession = "the ally [color=%s]ABOVE[/color]" % GameColors.DESC_TARGET
		TargetType.DOWN:
			target_phrase = "the ally [color=%s]BELOW[/color]" % GameColors.DESC_TARGET
			target_possession = "the ally [color=%s]BELOW[/color]" % GameColors.DESC_TARGET
		TargetType.LEFT:
			target_phrase = "the ally to the [color=%s]LEFT[/color]" % GameColors.DESC_TARGET
			target_possession = "the ally to the [color=%s]LEFT[/color]" % GameColors.DESC_TARGET
		TargetType.RIGHT:
			target_phrase = "the ally to the [color=%s]RIGHT[/color]" % GameColors.DESC_TARGET
			target_possession = "the ally to the [color=%s]RIGHT[/color]" % GameColors.DESC_TARGET
		TargetType.ALL:
			target_phrase = "[color=%s]ALL[/color] allies" % GameColors.DESC_TARGET
			target_possession = "[color=%s]ALL[/color] allies'" % GameColors.DESC_TARGET

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
				effect_str = "[color=%s]+%d Attack[/color] %s" % [GameColors.DESC_ATTACK, value, dur_str]
			else:
				effect_str = "Give %s [color=%s]+%d Attack[/color] %s" % [target_phrase, GameColors.DESC_ATTACK, value, dur_str]
		EffectType.BUFF_HEALTH:
			if target == TargetType.SELF:
				effect_str = "[color=%s]+%d Health[/color] %s" % [GameColors.DESC_HEALTH, value, dur_str]
			else:
				effect_str = "Give %s [color=%s]+%d Health[/color] %s" % [target_phrase, GameColors.DESC_HEALTH, value, dur_str]
		EffectType.BUFF_SHIELD:
			if target == TargetType.SELF:
				effect_str = "[color=%s]+%d Shield[/color] %s" % [GameColors.DESC_SHIELD, value, dur_str]
			else:
				effect_str = "Give %s [color=%s]+%d Shield[/color] %s" % [target_phrase, GameColors.DESC_SHIELD, value, dur_str]
		EffectType.BUFF_HEAL:
			if target == TargetType.SELF:
				effect_str = "[color=%s]+%d Heal[/color] %s" % [GameColors.DESC_HEAL, value, dur_str]
			else:
				effect_str = "Give %s [color=%s]+%d Heal[/color] %s" % [target_phrase, GameColors.DESC_HEAL, value, dur_str]
		EffectType.APPLY_POISON:
			if target == TargetType.SELF:
				effect_str = "Apply [color=%s]%d Poison[/color] to self" % [GameColors.DESC_POISON, value]
			else:
				effect_str = "Apply [color=%s]%d Poison[/color] to %s" % [GameColors.DESC_POISON, value, target_phrase]
		EffectType.TRIGGER_MODIFIERS:
			var target_trig_str = ""
			match target_trigger:
				Trigger.ON_CAST:
					target_trig_str = "[b][color=%s]On Cast[/color][/b]" % GameColors.DESC_TRIGGER
				Trigger.ON_BATTLE_START:
					target_trig_str = "[b][color=%s]On Battle Start[/color][/b]" % GameColors.DESC_TRIGGER
				Trigger.ON_TAKE_DAMAGE:
					target_trig_str = "[b][color=%s]On Take Damage[/color][/b]" % GameColors.DESC_TRIGGER
			effect_str = "Trigger %s %s effects" % [target_possession, target_trig_str]

	return "%s\n%s" % [trigger_str, effect_str]
