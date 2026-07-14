class_name RelicChestModifier
extends ItemModifier

@export var target_rarity: Rarity

func apply_shop_effect(run_state: RunState) -> void:
	run_state.add_random_relic(target_rarity)

func get_description() -> String:
	var rarity_str: String = target_rarity.rarity_name
	var text_color: Color = target_rarity.border_color
	var color_hex: String = text_color.to_html(false)
	return "Click to purchase a random [color=#%s]%s[/color] Relic." % [color_hex, rarity_str]
