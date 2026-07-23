class_name CardSprite
extends Control

@onready var texture_rect: TextureRect = %TextureRect
@onready var fallback_label: Label = %FallbackLabel

## Sets the sprite texture or falls back to displaying the full unit/item name
func set_sprite(p_texture: Texture2D, p_name: String) -> void:
	if p_texture:
		texture_rect.texture = p_texture
		texture_rect.visible = true
		fallback_label.visible = false
	else:
		texture_rect.texture = null
		texture_rect.visible = false
		fallback_label.text = p_name
		fallback_label.visible = true
