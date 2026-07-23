class_name CardPortrait
extends MarginContainer

@export var outer_border_width: int = 3:
	set(val):
		outer_border_width = val
		if is_node_ready() and border_rect:
			border_rect.outer_border_width = val

@export var inner_border_width: int = 3:
	set(val):
		inner_border_width = val
		if is_node_ready() and border_rect:
			border_rect.inner_border_width = val

@export var border_indentation: int = 3:
	set(val):
		border_indentation = val
		if is_node_ready() and border_rect:
			border_rect.border_indentation = val

@export var interior_color: Color = GameColors.TRANSPARENT:
	set(val):
		interior_color = val
		if is_node_ready() and border_rect:
			border_rect.interior_color = val

@onready var border_rect: ShaderBorderDecorator = $BorderRect
@onready var card_sprite: CardSprite = %CardSprite

## Sets up both the portrait (CardSprite) and the rarity border (ShaderBorderDecorator)
func setup_visuals(p_data: GameResourceData) -> void:
	if not p_data:
		return

	card_sprite.set_sprite(p_data.sprite, p_data.display_name)
	border_rect.border_color = p_data.rarity.border_color
	border_rect.outer_border_width = outer_border_width
	border_rect.inner_border_width = inner_border_width
	border_rect.border_indentation = border_indentation
	border_rect.interior_color = interior_color