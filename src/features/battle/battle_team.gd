class_name BattleTeam
extends RefCounted

# Signals for communicating with BattleScene controller
signal team_units_loaded(loaded_units: Array[UnitInstance])
signal health_changed(current_health: int, max_health: int, shield: int)
signal status_changed(status_type: String, amount: int, cooldown_ratio: float)
signal cast_progress_changed(slot_idx: int, ratio: float)
signal floating_text_requested(text: String, color: Color, is_on_slot: bool, slot_idx: int)
signal team_defeated()
signal gold_generated(amount: int, slot_idx: int)

const MAX_TEAM_SIZE: int = 6

# Combat State
var units: Array[UnitInstance] = []
var cast_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

var max_health: int = 0
var health: int = 0
var shield: int = 0

# Status Effects Dictionary (Typed to avoid unsafe cast warnings)
var active_statuses: Dictionary[String, StatusEffect] = {}

# Getter/Setter compatibility properties
var poison: int:
	get:
		var effect: StatusEffect = active_statuses.get("poison")
		return effect.stacks if effect else 0
	set(val):
		var effect: StatusEffect = active_statuses.get("poison")
		if effect:
			if val <= 0:
				effect.reset()
			else:
				effect.stacks = val
				effect.on_apply()

var burn: int:
	get:
		var effect: StatusEffect = active_statuses.get("burn")
		return effect.stacks if effect else 0
	set(val):
		var effect: StatusEffect = active_statuses.get("burn")
		if effect:
			if val <= 0:
				effect.reset()
			else:
				effect.stacks = val
				effect.on_apply()

var electrocute: int:
	get:
		var effect: StatusEffect = active_statuses.get("electrocute")
		return effect.stacks if effect else 0
	set(val):
		var effect: StatusEffect = active_statuses.get("electrocute")
		if effect:
			if val <= 0:
				effect.reset()
			else:
				effect.stacks = val
				effect.on_apply()

var is_enemy: bool = false

func initialize(p_is_enemy: bool = false) -> void:
	is_enemy = p_is_enemy
	
	units.clear()
	units.resize(MAX_TEAM_SIZE)
	cast_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	_initialize_status_effects()

func load_team_units(new_units: Array[UnitInstance]) -> void:
	shield = 0
	
	if active_statuses.is_empty():
		_initialize_status_effects()
	else:
		for effect: StatusEffect in active_statuses.values():
			effect.reset()
	
	health = 0
	max_health = 0
	
	var num_units: int = mini(MAX_TEAM_SIZE, new_units.size())
	for i: int in range(MAX_TEAM_SIZE):
		if i < num_units and new_units[i]:
			var inst: UnitInstance = new_units[i]
			var battle_inst: BattleUnitInstance = BattleUnitInstance.new()
			battle_inst.initialize_battle_unit(inst)
			units[i] = battle_inst
			health += battle_inst.get_max_health()
			max_health += battle_inst.get_max_health()
			shield += battle_inst.shield
		else:
			units[i] = null
			
	cast_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	team_units_loaded.emit(units)
	health_changed.emit(health, max_health, shield)
	status_changed.emit("poison", poison, 0.0)
	status_changed.emit("burn", burn, 0.0)
	status_changed.emit("electrocute", electrocute, 0.0)

func execute_cast(source_idx: int, opponent: BattleTeam) -> void:
	var unit: UnitInstance = units[source_idx]
	if not unit:
		return
		
	# Attack opponent team!
	var dmg: int = unit.get_attack()
	if dmg > 0:
		opponent.take_damage(dmg)
		
	# Apply status effects to opponent
	if unit.poison > 0:
		opponent.apply_status("poison", unit.poison)
	if unit.burn > 0:
		opponent.apply_status("burn", unit.burn)
	if unit.electrocute > 0:
		opponent.apply_status("electrocute", unit.electrocute)
		
	# Apply self/team effects
	if unit.heal > 0:
		heal(unit.heal)
	if unit.shield > 0:
		add_shield(unit.shield)
		
	# Trigger ON_CAST modifier
	ModifierEngine.trigger_unit_modifier(source_idx, self, UnitModifier.Trigger.ON_CAST)

func take_damage(amount: int, damage_type: String = "physical") -> void:
	if amount <= 0:
		return
		
	var actual_dmg: int = amount
	
	# Let active status effects modify the incoming damage
	for effect: StatusEffect in active_statuses.values():
		actual_dmg = effect.modify_incoming_damage(actual_dmg, damage_type)
			
	if actual_dmg <= 0:
		return
	var text_color: Color = Color(GameColors.DESC_ATTACK) # default red
	
	if damage_type == "poison":
		text_color = Color(GameColors.DESC_POISON)
	elif damage_type == "burn":
		text_color = Color(GameColors.DESC_BURN)
	else:
		# physical
		if is_enemy:
			text_color = GameColors.WHITE_COLOR
		else:
			text_color = Color(GameColors.DESC_ATTACK)
			
	# Apply shield absorption
	if shield >= actual_dmg:
		shield -= actual_dmg
	else:
		var remaining_dmg: int = actual_dmg - shield
		shield = 0
		health -= remaining_dmg
		
	health_changed.emit(health, max_health, shield)
	floating_text_requested.emit("-" + NumberFormatter.format_large_number(actual_dmg), text_color, false, 0)
	
	if damage_type == "physical":
		for i: int in range(MAX_TEAM_SIZE):
			if units[i]:
				ModifierEngine.trigger_unit_modifier(i, self, UnitModifier.Trigger.ON_TAKE_DAMAGE)
		
	if max_health > 0 and health <= 0:
		team_defeated.emit()

func heal(amount: int, source_slot_idx: int = -1) -> void:
	if amount <= 0:
		return
	var health_before: int = health
	health = min(health + amount, max_health)
	var actual_heal: int = health - health_before
	
	health_changed.emit(health, max_health, shield)
	
	if actual_heal > 0:
		if source_slot_idx != -1:
			spawn_floating_text_on_slot(source_slot_idx, "+" + NumberFormatter.format_large_number(actual_heal), Color(GameColors.DESC_HEAL))
		else:
			floating_text_requested.emit("+" + NumberFormatter.format_large_number(actual_heal), Color(GameColors.DESC_HEAL), false, 0)

func add_shield(amount: int) -> void:
	if amount <= 0:
		return
	shield += amount
	health_changed.emit(health, max_health, shield)
	floating_text_requested.emit("+" + NumberFormatter.format_large_number(amount), Color(GameColors.DESC_SHIELD), false, 0)

func apply_status(status_type: String, amount: int) -> void:
	if amount <= 0:
		return
		
	var effect: StatusEffect = active_statuses.get(status_type)
	if effect:
		effect.add_stacks(amount)

func remove_status(status_type: String) -> void:
	var effect: StatusEffect = active_statuses.get(status_type)
	if effect:
		effect.reset()
		status_changed.emit(status_type, 0, 0.0)

func modify_status_interval(status_type: String, delta_interval: float) -> void:
	var effect: StatusEffect = active_statuses.get(status_type)
	if effect:
		effect.tick_interval = maxf(0.1, effect.tick_interval + delta_interval)

func emit_status_changed(status_type: String, amount: int, cooldown_ratio: float) -> void:
	status_changed.emit(status_type, amount, cooldown_ratio)

func _initialize_status_effects() -> void:
	active_statuses.clear()
	_register_status("poison", PoisonStatus.new())
	_register_status("burn", BurnStatus.new())
	_register_status("electrocute", ElectrocuteStatus.new())

func _register_status(p_type: String, p_effect: StatusEffect) -> void:
	p_effect.initialize(p_type, self, 0)
	active_statuses[p_type] = p_effect

func get_status_value(status_type: String) -> int:
	var effect: StatusEffect = active_statuses.get(status_type)
	return effect.stacks if effect else 0

func get_status_cooldown_ratio(status_type: String) -> float:
	var effect: StatusEffect = active_statuses.get(status_type)
	if effect:
		return effect.get_cooldown_ratio()
	return 0.0

func tick_statuses(delta: float) -> void:
	for effect: StatusEffect in active_statuses.values():
		if effect.stacks > 0:
			effect.tick(delta)

func tick_casts(delta: float, cast_callback: Callable) -> void:
	for i: int in range(MAX_TEAM_SIZE):
		if units[i]:
			cast_timers[i] += delta
			var speed: float = units[i].get_cast_speed()
			if speed <= 0.0: speed = 1.0
			
			cast_progress_changed.emit(i, cast_timers[i] / speed)
			
			if cast_timers[i] >= speed:
				cast_timers[i] = 0.0
				cast_callback.call(i)

func spawn_floating_text_on_slot(t_idx: int, text: String, color: Color) -> void:
	floating_text_requested.emit(text, color, true, t_idx)

func buff_unit_attack(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.attack += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.attack += amount
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " ATK", Color(GameColors.DESC_ATTACK))

func buff_unit_max_health(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.health += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.health += amount
	max_health += amount
	health += amount
	health_changed.emit(health, max_health, shield)
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " HP", Color(GameColors.DESC_HEALTH))

func add_unit_shield(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.shield += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.shield += amount
	shield += amount
	health_changed.emit(health, max_health, shield)
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " Shield", Color(GameColors.DESC_SHIELD))

func buff_unit_poison(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.poison += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.poison += amount
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " Poison", Color(GameColors.DESC_POISON))

func buff_unit_burn(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.burn += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.burn += amount
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " Burn", Color(GameColors.DESC_BURN))

func buff_unit_electrocute(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.electrocute += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.electrocute += amount
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " Electrocute", Color(GameColors.DESC_ELECTROCUTE))

func buff_unit_heal_power(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.heal += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.heal += amount
	spawn_floating_text_on_slot(slot_idx, "+" + NumberFormatter.format_large_number(amount) + " Heal Power", Color(GameColors.DESC_HEAL))

func buff_unit_cast_speed(slot_idx: int, amount: float, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		if b_unit.cast_speed <= 0.1:
			return
		var old_speed: float = b_unit.cast_speed
		b_unit.cast_speed = maxf(0.1, b_unit.cast_speed - amount)
		var actual_reduction: float = old_speed - b_unit.cast_speed
		if permanent and b_unit.base_unit:
			b_unit.base_unit.cast_speed = maxf(0.1, b_unit.base_unit.cast_speed - amount)
		if actual_reduction > 0.0:
			var reduction_str: String = ""
			if is_equal_approx(actual_reduction, roundf(actual_reduction)):
				reduction_str = str(int(roundf(actual_reduction)))
			else:
				reduction_str = "%.1f" % actual_reduction
			spawn_floating_text_on_slot(slot_idx, "-" + reduction_str + "s CD", Color(GameColors.DESC_CAST_SPEED))

func add_unit_gold(slot_idx: int, amount: int) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	gold_generated.emit(amount, slot_idx)
