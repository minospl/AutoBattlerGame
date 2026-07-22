class_name UnitData
extends GameResourceData

## Price of the unit card in the shop
@export var price: int

## Whether this unit card can appear in the shop
@export var can_appear_in_shop: bool = true

## Base maximum health
@export var max_health: int

## Base attack power
@export var attack: int

## Base heal value (on cast)
@export var base_heal: int

## Base poison value
@export var base_poison: int

## Base shield value (on cast)
@export var base_shield: int

## Base burn value (on cast)
@export var base_burn: int

## Base electrocute value (on cast)
@export var base_electrocute: int

## List of types associated with this unit (e.g. Beast, Dragon)
@export var types: Array[UnitType]

## How often the unit casts (in seconds)
@export var cast_speed: float

## List of modifier (abilities) for this unit
@export var modifier: UnitModifier
