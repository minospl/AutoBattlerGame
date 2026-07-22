class_name CardSprite
extends Control

@onready var texture_rect: TextureRect = %TextureRect
@onready var fallback_label: Label = %FallbackLabel

## Sets the sprite texture or falls back to displaying the full unit/item name
func set_sprite(p_texture: Texture2D, p_name: String, p_offset: Vector2 = Vector2.ZERO, p_scale: Vector2 = Vector2.ONE) -> void:
	if p_texture:
		texture_rect.texture = p_texture
		texture_rect.visible = true
		fallback_label.visible = false
		texture_rect.position = p_offset
		texture_rect.scale = p_scale
		texture_rect.pivot_offset = texture_rect.size / 2.0
	else:
		texture_rect.texture = null
		texture_rect.visible = false
		fallback_label.text = p_name
		fallback_label.visible = true
