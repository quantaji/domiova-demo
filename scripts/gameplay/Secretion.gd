## Secretion - Follicle hormone secretion particles (E2 and Inhibin B)
## Two-phase movement: Phase 1 (linear away from near field) -> Phase 2 (accelerate toward pituitary)
class_name Secretion
extends Node2D

# Enumeration for secretion types
enum SecretionType { E2, INHIBIN_B }

# Lifecycle signals
signal secretion_recycled(secretion: Secretion)
signal reached_pituitary(secretion: Secretion)

# Configuration from config.json (loaded at activation)
var secretion_type: SecretionType = SecretionType.E2
var color: Color = Color.WHITE
var square_half_size: float = 8.0
var speed_phase1: float = 120.0
var speed_phase2: float = 300.0
var lifetime: float = 15.0

# World boundaries (from config)
var near_field_rect: Rect2
var pituitary_position: Vector2
var pituitary_radius: float

# Movement state
var is_active: bool = false
var direction: Vector2 = Vector2.RIGHT  # Direction in Phase 1
var current_phase: int = 1  # 1 or 2
var elapsed_time: float = 0.0


func _ready() -> void:
	set_process(false)  # Disabled until activated
	z_index = 8  # Layer above hormone pellets (5), below follicles (10)


## Activate secretion particle with initial conditions
## Called by SecretionManager
func activate(
	p_type: SecretionType,
	p_start_position: Vector2,
	p_direction: Vector2,
	p_config: Dictionary,
	p_near_field_rect: Rect2,
	p_pituitary_position: Vector2,
	p_pituitary_radius: float
) -> void:
	secretion_type = p_type
	color = Color(
		p_config.color.r,
		p_config.color.g,
		p_config.color.b,
		1.0
	)
	square_half_size = p_config.square_half_size
	speed_phase1 = p_config.speed_phase1
	speed_phase2 = p_config.speed_phase2
	lifetime = p_config.lifetime
	
	# World boundaries
	near_field_rect = p_near_field_rect
	pituitary_position = p_pituitary_position
	pituitary_radius = p_pituitary_radius
	
	# Initial state
	global_position = p_start_position
	direction = p_direction.normalized()
	current_phase = 1
	elapsed_time = 0.0
	is_active = true
	
	set_process(true)
	visible = true
	queue_redraw()


## Check if position is outside near field boundary
func _is_outside_near_field(pos: Vector2) -> bool:
	return not near_field_rect.has_point(pos)


## Compute direction toward pituitary
func _get_direction_to_pituitary() -> Vector2:
	return (pituitary_position - global_position).normalized()


## Phase transition check
func _check_phase_transition() -> void:
	if current_phase == 1 and _is_outside_near_field(global_position):
		current_phase = 2


func _process(delta: float) -> void:
	if not is_active:
		return
	
	elapsed_time += delta
	
	# Lifecycle check
	if elapsed_time >= lifetime:
		_recycle()
		return
	
	# Phase transition
	_check_phase_transition()
	
	# Movement based on current phase
	if current_phase == 1:
		# Phase 1: Linear movement away from near field
		global_position += direction * speed_phase1 * delta
	else:
		# Phase 2: Accelerate toward pituitary
		var dir_to_pituitary = _get_direction_to_pituitary()
		var distance_to_pituitary = global_position.distance_to(pituitary_position)
		
		# Check if reached pituitary
		if distance_to_pituitary <= pituitary_radius:
			_on_reached_pituitary()
			return
		
		# Move toward pituitary
		global_position += dir_to_pituitary * speed_phase2 * delta


func _on_reached_pituitary() -> void:
	reached_pituitary.emit(self)
	_recycle()


func _recycle() -> void:
	is_active = false
	elapsed_time = 0.0
	set_process(false)
	visible = false
	secretion_recycled.emit(self)


func _draw() -> void:
	if not is_active:
		return
	
	# Draw as a square (not a circle)
	var rect = Rect2(-Vector2(square_half_size, square_half_size), Vector2(square_half_size * 2, square_half_size * 2))
	draw_rect(rect, color, true)
