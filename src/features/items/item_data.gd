class_name ItemData
extends Resource

## The name of the item
@export var item_name: String

## Price of the item card in the shop
@export var price: int

## Rarity of the item
@export var rarity: Rarity

## If true, this item can be dragged and dropped onto a unit
@export var is_draggable: bool = false

## If true, this item is clicked to activate its effect globally
@export var is_clickable: bool = false

## The modifier script for custom behavior/ability
@export var modifier: ItemModifier

## Optional texture/sprite for item artwork
@export var sprite: Texture2D
