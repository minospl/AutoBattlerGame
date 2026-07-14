class_name ItemData
extends GameResourceData

## Price of the item card in the shop
@export var price: int

## If true, this item can be dragged and dropped onto a unit
@export var is_draggable: bool = false

## If true, this item is clicked to activate its effect globally
@export var is_clickable: bool = false

## The modifier script for custom behavior/ability
@export var modifier: ItemModifier