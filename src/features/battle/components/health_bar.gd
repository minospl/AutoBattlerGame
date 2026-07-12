class_name HealthBar
extends ColorRect

const HP_BORDER_SHADER: Shader = preload("res://src/shared/shaders/hp_border.gdshader")

@onready var health_label: Label = %HealthLabel

var hp_material: ShaderMaterial

func _ready() -> void:
	# Configure HP border shader programmatically
	hp_material = ShaderMaterial.new()
	hp_material.shader = HP_BORDER_SHADER
	hp_material.set_shader_parameter("fill_percentage", 1.0)
	self.material = hp_material
	
	# Keep size uniform synchronized with control size
	self.resized.connect(func() -> void:
		if hp_material:
			hp_material.set_shader_parameter("size", self.size)
	)
	
	# Initial size fallback
	var initial_size: Vector2 = self.size
	if initial_size.x == 0.0:
		initial_size = Vector2(340.0, 32.0)
	hp_material.set_shader_parameter("size", initial_size)

## Updates the visual fill ratio and the label text representation
func update_health(current_health: int, max_health: int, shield: int) -> void:
	var fill_pct: float = 0.0
	if max_health > 0:
		var health_clamped: int = max(0, current_health)
		fill_pct = float(health_clamped) / float(max_health)
		
	if hp_material:
		hp_material.set_shader_parameter("fill_percentage", fill_pct)
		
	if health_label:
		if shield > 0:
			health_label.text = "%d / %d (🛡️ %d)" % [max(0, current_health), max_health, shield]
		else:
			health_label.text = "%d / %d" % [max(0, current_health), max_health]
