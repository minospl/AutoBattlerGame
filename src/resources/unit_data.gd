class_name UnitData
extends Resource

## The name of the unit
@export var unit_name: String

## Price of the unit card in the shop
@export var price: int

## Base maximum health
@export var max_health: int

## Base attack power
@export var attack: int

## Base poison value
@export var base_poison: int

## List of types associated with this unit (e.g. Beast, Dragon)
@export var types: Array[UnitType]

## Rarity of the unit (defines the card border color in UI)
@export var rarity: Rarity

## Short flavor text or ability description
@export_multiline var description: String

## Optional custom texture/sprite for the unit artwork
@export var sprite: Texture2D
