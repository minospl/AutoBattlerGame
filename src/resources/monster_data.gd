class_name MonsterData
extends Resource

## The name of the monster
@export var monster_name: String = ""

## Price of the monster card in the shop
@export var price: int = 0

## Base maximum health
@export var max_health: int = 10

## Base attack power
@export var attack: int = 2

## Base poison value
@export var base_poison: int = 0

## List of types associated with this monster (e.g. Fire, Beast)
@export var types: Array[MonsterType] = []

## Rarity of the monster (defines the card border color in UI)
@export var rarity: MonsterRarity

## Short flavor text or ability description
@export_multiline var description: String = ""

## Placeholder flat color for the card background
@export var visual_color: Color = Color.GRAY

## Optional custom texture/sprite for the monster artwork
@export var sprite: Texture2D
