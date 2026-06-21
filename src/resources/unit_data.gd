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

## Base heal value (on cast)
@export var base_heal: int = 0

## Base poison value
@export var base_poison: int

## Base shield value (on cast)
@export var base_shield: int = 0


## Base thorns value (retaliate on hit)
@export var base_thorns: int = 0

## Base burn value (on cast)
@export var base_burn: int = 0

## Base electrocute value (on cast)
@export var base_electrocute: int = 0

## List of types associated with this unit (e.g. Beast, Dragon)
@export var types: Array[UnitType]

## Rarity of the unit (defines the card border color in UI)
@export var rarity: Rarity

## How often the unit casts (in seconds)
@export var cast_speed: float

## List of modifiers (abilities) for this unit
@export var modifiers: Array[UnitModifier] = []

## Optional custom texture/sprite for the unit artwork
@export var sprite: Texture2D
