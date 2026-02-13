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

# Test emission timers (independent for FSH and LH)
var fsh_timer: Timer
var lh_timer: Timer


func _ready() -> void:
	# Get scene references
	emission_origin = $EmissionOrigin
	pellet_container = $PelletContainer
	
	_load_config()
	_initialize_pellet_pool()
	_setup_test_timer()
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
	fsh_timer.wait_time = fsh_config.emission_interval
	fsh_timer.timeout.connect(_on_fsh_emission)
	fsh_timer.autostart = true
	add_child(fsh_timer)
	
	# LH timer
	lh_timer = Timer.new()
	lh_timer.wait_time = lh_config.emission_interval
	lh_timer.timeout.connect(_on_lh_emission)
	lh_timer.autostart = true
	add_child(lh_timer)
	
	print("[FarField] Emission timers started:")
	print("  FSH: %d pellets every %.1f seconds" % [fsh_config.emission_count, fsh_config.emission_interval])
	print("  LH:  %d pellets every %.1f seconds" % [lh_config.emission_count, lh_config.emission_interval])


## FSH emission callback
func _on_fsh_emission() -> void:
	emit_wave("FSH", fsh_config.emission_count)


## LH emission callback
func _on_lh_emission() -> void:
	emit_wave("LH", lh_config.emission_count)


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


## Calculate the emission angle range
## Returns Vector2(start_angle, end_angle) in radians
## Now emits in full 360 degrees
func _calculate_emission_angles() -> Vector2:
	# Emit in all directions (full circle)
	return Vector2(0, TAU)
