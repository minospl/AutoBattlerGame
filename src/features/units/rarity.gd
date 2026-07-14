class_name Rarity
extends Resource

enum Type {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
	UNIQUE
}

## The user-facing name of the rarity
@export var rarity_name: String

## The border color associated with this rarity on the card UI
@export var border_color: Color = Color.GRAY

## The internal rarity type used for comparisons and sorting
@export var rarity_type: Type = Type.COMMON
