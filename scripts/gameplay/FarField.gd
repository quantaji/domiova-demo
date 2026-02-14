extends Node2D

## FarField (Pituitary Gland) - Hormone Wave Emitter
## Emits FSH and LH pellets in circular wave patterns toward the Near Field

# Scene references
var emission_origin: Marker2D
var pellet_container: Node2D

# Configuration
var pituitary_radius: float
var pituitary_color: Color
var pituitary_border_color: Color
var pituitary_border_width: float

# Near Field boundaries (from config)
var near_field_rect: Rect2

# Object pool
var pellet_scene: PackedScene
var available_pellets: Array[Area2D] = []
var active_pellets: Array[Area2D] = []

# Hormone configurations
var fsh_config: Dictionary
var lh_config: Dictionary
var hormone_config: Dictionary

# Pituitary intensity model
var pituitary_fsh_cfg: Dictionary
var pituitary_lh_cfg: Dictionary
var pituitary_feedback_cfg: Dictionary
var recovery_tick: float = 1.0
var fsh_intensity: float = 0.5
var lh_intensity: float = 0.5

# Stage flip tracking
var stage_cfg: Dictionary
var e2_received_count: int = 0
var flip_e2_count: int = 30
var has_flipped: bool = false

# Test emission timers (independent for FSH and LH)
var fsh_timer: Timer
var lh_timer: Timer
var recovery_timer: Timer


func _ready() -> void:
	# Get scene references
	emission_origin = $EmissionOrigin
	pellet_container = $PelletContainer
	add_to_group("far_field")
	
	_load_config()
	_initialize_pellet_pool()
	_setup_test_timer()
	_setup_recovery_timer()
	queue_redraw()


## Load configuration from ConfigManager
func _load_config() -> void:
	var far_field_cfg = ConfigManager.get_config("world.far_field")
	pituitary_radius = far_field_cfg.pituitary_radius
	pituitary_color = Color(
		far_field_cfg.pituitary_color.r,
		far_field_cfg.pituitary_color.g,
		far_field_cfg.pituitary_color.b,
		far_field_cfg.pituitary_color.a
	)
	pituitary_border_color = Color(
		far_field_cfg.pituitary_border_color.r,
		far_field_cfg.pituitary_border_color.g,
		far_field_cfg.pituitary_border_color.b,
		far_field_cfg.pituitary_border_color.a
	)
	pituitary_border_width = far_field_cfg.pituitary_border_width
	
	# Set FarField position from config
	global_position = Vector2(far_field_cfg.position_x, far_field_cfg.position_y)
	
	# Load Near Field boundaries from arena config
	var arena = ConfigManager.get_config("world.arena")
	near_field_rect = Rect2(
		Vector2(arena.position_x, arena.position_y),
		Vector2(arena.width, arena.height)
	)
	
	# Load hormone configurations
	hormone_config = ConfigManager.get_config("world.hormone")
	fsh_config = hormone_config.fsh
	lh_config = hormone_config.lh

	# Load pituitary model configurations
	var pituitary_cfg = ConfigManager.get_config("world.pituitary")
	pituitary_fsh_cfg = pituitary_cfg.fsh
	pituitary_lh_cfg = pituitary_cfg.lh
	pituitary_feedback_cfg = pituitary_cfg.feedback
	recovery_tick = pituitary_cfg.recovery_tick

	fsh_intensity = pituitary_fsh_cfg.default_intensity
	lh_intensity = pituitary_lh_cfg.default_intensity

	# Stage config for flip threshold
	stage_cfg = ConfigManager.get_config("world.stage")
	flip_e2_count = stage_cfg.flip_e2_count
	e2_received_count = 0
	has_flipped = false
	
	# Load pellet scene
	pellet_scene = load("res://scenes/gameplay/entities/hormone_pellet.tscn")


## Initialize object pool with pre-created pellets
func _initialize_pellet_pool() -> void:
	var pool_size = hormone_config.pellet_pool_size
	
	for i in range(pool_size):
		var pellet = pellet_scene.instantiate() as Area2D
		pellet_container.add_child(pellet)
		pellet.visible = false
		pellet.set_process(false)
		
		# Connect expiration signal
		if pellet.has_signal("pellet_expired"):
			pellet.pellet_expired.connect(_on_pellet_expired)
		
		available_pellets.append(pellet)
	
	print("[FarField] Object pool initialized with %d pellets" % pool_size)


## Draw pituitary gland visualization
func _draw() -> void:
	# Draw filled circle (body)
	draw_circle(Vector2.ZERO, pituitary_radius, pituitary_color)
	
	# Draw border
	draw_arc(
		Vector2.ZERO,
		pituitary_radius,
		0,
		TAU,
		64,
		pituitary_border_color,
		pituitary_border_width,
		true
	)


## Get a pellet from the pool
func _get_pellet_from_pool() -> Area2D:
	var pellet: Area2D
	
	if available_pellets.is_empty():
		# Emergency expansion
		print("[FarField] WARNING: Pool exhausted, creating new pellet")
		pellet = pellet_scene.instantiate() as Area2D
		pellet_container.add_child(pellet)
		if pellet.has_signal("pellet_expired"):
			pellet.pellet_expired.connect(_on_pellet_expired)
		return pellet
	
	pellet = available_pellets.pop_back()
	active_pellets.append(pellet)
	return pellet


## Return pellet to pool
func _return_pellet_to_pool(pellet: Area2D) -> void:
	active_pellets.erase(pellet)
	available_pellets.append(pellet)


## Handle pellet expiration
func _on_pellet_expired(pellet: Area2D) -> void:
	_return_pellet_to_pool(pellet)


## Get pool statistics (for debugging)
func get_pool_stats() -> Dictionary:
	return {
		"available": available_pellets.size(),
		"active": active_pellets.size(),
		"total": available_pellets.size() + active_pellets.size()
	}


## Setup test emission timer
func _setup_test_timer() -> void:
	# FSH timer
	fsh_timer = Timer.new()
	fsh_timer.one_shot = true
	fsh_timer.timeout.connect(_on_fsh_emission)
	add_child(fsh_timer)
	
	# LH timer
	lh_timer = Timer.new()
	lh_timer.one_shot = true
	lh_timer.timeout.connect(_on_lh_emission)
	add_child(lh_timer)

	_schedule_next_fsh()
	_schedule_next_lh()
	
	print("[FarField] Emission timers started:")
	print("  FSH: dynamic interval/count (intensity-driven)")
	print("  LH:  dynamic interval/count (intensity-driven)")


func _setup_recovery_timer() -> void:
	recovery_timer = Timer.new()
	recovery_timer.wait_time = recovery_tick
	recovery_timer.one_shot = false
	recovery_timer.timeout.connect(_on_recovery_tick)
	recovery_timer.autostart = true
	add_child(recovery_timer)


## FSH emission callback
func _on_fsh_emission() -> void:
	var count = _compute_count(fsh_intensity, pituitary_fsh_cfg)
	emit_wave("FSH", count)
	_schedule_next_fsh()


## LH emission callback
func _on_lh_emission() -> void:
	var count = _compute_count(lh_intensity, pituitary_lh_cfg)
	emit_wave("LH", count)
	_schedule_next_lh()


func _on_recovery_tick() -> void:
	fsh_intensity = _recover_intensity(
		fsh_intensity,
		pituitary_fsh_cfg.default_intensity,
		pituitary_fsh_cfg.recovery_rate,
		pituitary_fsh_cfg.min_intensity
	)
	lh_intensity = _recover_intensity(
		lh_intensity,
		pituitary_lh_cfg.default_intensity,
		pituitary_lh_cfg.recovery_rate,
		pituitary_lh_cfg.min_intensity
	)


## Emit a circular wave of hormone pellets
## @param hormone_type: "FSH" or "LH"
## @param pellet_count: Number of pellets in the wave
func emit_wave(hormone_type: String, pellet_count: int) -> void:
	if pellet_count <= 0:
		return
	
	# Get hormone configuration
	var config: Dictionary
	var pellet_type: int
	if hormone_type == "FSH":
		config = fsh_config
		pellet_type = 0  # HormonePellet.HormoneType.FSH
	else:
		config = lh_config
		pellet_type = 1  # HormonePellet.HormoneType.LH
	
	# Calculate emission angle range (fan shape toward Near Field)
	var angle_range = _calculate_emission_angles()
	var start_angle = angle_range.x
	var end_angle = angle_range.y
	var angle_span = end_angle - start_angle
	
	# Emit pellets in circular pattern
	for i in range(pellet_count):
		var pellet = _get_pellet_from_pool()
		if not pellet:
			print("[FarField] WARNING: No pellet available, skipping")
			continue
		
		# Calculate angle for this pellet (evenly distributed)
		var t = float(i) / float(pellet_count - 1) if pellet_count > 1 else 0.5
		var angle = start_angle + angle_span * t
		
		# Calculate direction vector (normalized)
		var direction = Vector2(cos(angle), sin(angle))
		
		# Calculate spawn position (on the edge of pituitary circle)
		var spawn_offset = direction * pituitary_radius
		var spawn_pos = global_position + spawn_offset
		
		# Prepare pellet parameters
		var params = {
			"speed": config.speed,
			"oscillation_amplitude": config.oscillation_amplitude,
			"oscillation_frequency": config.oscillation_frequency,
			"lifetime": hormone_config.pellet_lifetime,
			"radius": config.pellet_radius,
			"color": config.color
		}
		
		# Activate pellet
		pellet.activate(spawn_pos, direction, pellet_type, params)
	
	print("[FarField] Emitted %s wave: %d pellets" % [hormone_type, pellet_count])


func apply_e2_feedback() -> void:
	e2_received_count += 1
	fsh_intensity = _apply_feedback(fsh_intensity, pituitary_feedback_cfg.e2_to_fsh_strength, pituitary_fsh_cfg.min_intensity)
	lh_intensity = _apply_feedback(lh_intensity, pituitary_feedback_cfg.e2_to_lh_strength, pituitary_lh_cfg.min_intensity)

	if not has_flipped and e2_received_count >= flip_e2_count:
		has_flipped = true
		lh_intensity = 1.0
		stage_cfg.current = "3"
		_schedule_next_lh()


func apply_inhibin_feedback() -> void:
	fsh_intensity = _apply_feedback(fsh_intensity, pituitary_feedback_cfg.inhibin_to_fsh_strength, pituitary_fsh_cfg.min_intensity)
	lh_intensity = _apply_feedback(lh_intensity, pituitary_feedback_cfg.inhibin_to_lh_strength, pituitary_lh_cfg.min_intensity)


func _schedule_next_fsh() -> void:
	var interval = _compute_interval(fsh_intensity, pituitary_fsh_cfg)
	fsh_timer.wait_time = interval
	fsh_timer.start()


func _schedule_next_lh() -> void:
	var interval = _compute_interval(lh_intensity, pituitary_lh_cfg)
	lh_timer.wait_time = interval
	lh_timer.start()


func _compute_interval(intensity: float, cfg: Dictionary) -> float:
	var clamped = clamp(intensity, 0.0, 1.0)
	var t = pow(clamped, cfg.interval_curve)
	return cfg.interval_max - (cfg.interval_max - cfg.interval_min) * t


func _compute_count(intensity: float, cfg: Dictionary) -> int:
	var clamped = clamp(intensity, 0.0, 1.0)
	var t = pow(clamped, cfg.count_curve)
	return int(ceil(cfg.count_min + (cfg.count_max - cfg.count_min) * t))


func _recover_intensity(current: float, target: float, rate: float, minimum: float) -> float:
	var next_val = (current - target) * (1.0 - rate) + target
	return clamp(next_val, minimum, 1.0)


func _apply_feedback(current: float, strength: float, minimum: float) -> float:
	return clamp(current - strength, minimum, 1.0)


## Calculate the emission angle range
## Returns Vector2(start_angle, end_angle) in radians
## Now emits in full 360 degrees
func _calculate_emission_angles() -> Vector2:
	# Emit in all directions (full circle)
	return Vector2(0, TAU)
