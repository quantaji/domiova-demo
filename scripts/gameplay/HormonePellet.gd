extends Area2D

## HormonePellet - Individual hormone particle (FSH or LH)
## Moves in radial direction with perpendicular sine wave oscillation
## Managed by object pool in FarField

# Signal emitted when pellet needs to be recycled
signal pellet_expired(pellet: Area2D)

# Hormone type enumeration
enum HormoneType { FSH, LH }

# Current state
var hormone_type: HormoneType = HormoneType.FSH
var is_active: bool = false

# Movement parameters
var direction: Vector2 = Vector2.ZERO  # Normalized direction vector
var speed: float = 180.0
var oscillation_amplitude: float = 20.0
var oscillation_frequency: float = 2.5

# Lifecycle
var age: float = 0.0
var lifetime: float = 12.0

# Visual
var pellet_radius: float = 12.0
var pellet_color: Color = Color(1.0, 0.4, 0.8)
var start_position: Vector2 = Vector2.ZERO

# Cached references
var collision_shape: CollisionShape2D


func _ready() -> void:
	# Get collision shape reference
	collision_shape = get_node("CollisionShape2D")
	
	set_process(false)  # Disabled until activated
	visible = false
	
	# NOTE: Collision interaction disabled for now
	# Will be implemented later with receptor logic and cooldown system
	# area_entered.connect(_on_area_entered)
	# body_entered.connect(_on_body_entered)


## Activate pellet from object pool
func activate(
	spawn_pos: Vector2,
	move_direction: Vector2,
	type: HormoneType,
	params: Dictionary
) -> void:
	# Set position and direction
	global_position = spawn_pos
	start_position = spawn_pos
	direction = move_direction.normalized()
	
	# Set hormone type
	hormone_type = type
	
	# Load parameters from config
	speed = params.speed
	oscillation_amplitude = params.oscillation_amplitude
	oscillation_frequency = params.oscillation_frequency
	lifetime = params.lifetime
	pellet_radius = params.get("radius", 12.0)
	
	# Update collision shape radius to match visual
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = pellet_radius
	
	# Set color based on type
	pellet_color = Color(params.color.r, params.color.g, params.color.b)
	
	# Reset lifecycle
	age = 0.0
	is_active = true
	visible = true
	set_process(true)
	queue_redraw()


## Deactivate pellet and return to pool
func deactivate() -> void:
	is_active = false
	visible = false
	set_process(false)
	age = 0.0


func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Update age
	age += delta
	
	# Check lifetime expiration
	if age >= lifetime:
		_expire()
		return
	
	# Calculate base movement (radial direction)
	var travel_distance = speed * age
	var base_offset = direction * travel_distance
	
	# Calculate perpendicular oscillation
	var perpendicular = Vector2(-direction.y, direction.x)
	var oscillation_offset = perpendicular * oscillation_amplitude * sin(TAU * oscillation_frequency * age)
	
	# Apply final position
	global_position = start_position + base_offset + oscillation_offset
	queue_redraw()


## Expire and request recycling
func _expire() -> void:
	if is_active:
		pellet_expired.emit(self)
		deactivate()


## Get hormone type as string (for debugging)
func get_type_string() -> String:
	return "FSH" if hormone_type == HormoneType.FSH else "LH"


## Draw pellet as a circle
func _draw() -> void:
	if not is_active:
		return
	draw_circle(Vector2.ZERO, pellet_radius, pellet_color)


# ===== Collision Interaction (Disabled for now) =====
# TODO: Implement receptor-based absorption logic
# - FSH: Can be absorbed immediately by all follicles
# - LH: Requires LH receptor (unlocked at maturity)
# - Cooldown system: 10s between absorptions per follicle
# - Energy transfer from pellet to follicle
#
# func _on_area_entered(_area: Area2D) -> void:
# 	if is_active:
# 		_check_absorption(_area)
#
# func _on_body_entered(_body: Node2D) -> void:
# 	if is_active:
# 		_check_absorption(_body)
#
# func _check_absorption(target: Node) -> void:
# 	# Check if target is a follicle
# 	# Check receptor availability
# 	# Check cooldown
# 	# Transfer energy
# 	# Expire pellet
# 	pass
