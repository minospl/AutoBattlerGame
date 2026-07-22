class_name CardPortrait
extends MarginContainer

@onready var border_rect: ShaderBorderDecorator = $BorderRect
@onready var card_sprite: CardSprite = %CardSprite

## Sets up both the portrait (CardSprite) and the rarity border (ShaderBorderDecorator)
func setup_visuals(p_data: GameResourceData) -> void:
	if not p_data:
		return

	card_sprite.set_sprite(p_data.sprite, p_data.display_name, p_data.sprite_offset, p_data.sprite_scale)
	border_rect.border_color = p_data.rarity.border_color