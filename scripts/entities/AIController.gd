## AIController - Intelligent AI that seeks hormone pellets
class_name AIController
extends ControllerBase

# Energy-based behavior modes
enum EnergyMode { STARVING, DEVELOPING, THRIVING }

var target: Vector2 = Vector2.ZERO
var play_rect: Rect2
var target_pickup_distance: float
var current_position: Vector2 = Vector2.ZERO

# AI configuration
var perception_radius: float = 400.0
var target_update_interval: float = 0.3
var distance_weight: float = 1.0
var value_weight: float = 1.0
var energy_threshold_starving: float = 4.0
var energy_threshold_thriving: float = 8.0
var starving_mode_max_distance: float = 300.0

# AI state
var target_update_timer: float = 0.0
var current_target_pellet: Area2D = null
var current_energy_mode: EnergyMode = EnergyMode.DEVELOPING

# References to game state (set externally)
var far_field: Node2D = null


func _init(config_arena: Dictionary, config_target_distance: float) -> void:
	play_rect = Rect2(
		Vector2(config_arena["position_x"], config_arena["position_y"]),
		Vector2(config_arena["width"], config_arena["height"])
	)
	target_pickup_distance = config_target_distance
	
	# Load AI configuration
	var ai_cfg = ConfigManager.get_config("npc_follicle.ai")
	perception_radius = ai_cfg.perception_radius
	target_update_interval = ai_cfg.target_update_interval
	distance_weight = ai_cfg.distance_weight
	value_weight = ai_cfg.value_weight
	energy_threshold_starving = ai_cfg.energy_threshold_starving
	energy_threshold_thriving = ai_cfg.energy_threshold_thriving
	starving_mode_max_distance = ai_cfg.starving_mode_max_distance
	
	randomize()
	_pick_random_target()


## Set FarField reference for pellet detection
func set_far_field(ff: Node2D) -> void:
	far_field = ff


## Determine energy mode based on current energy level
func get_energy_mode(energy: float) -> EnergyMode:
	if energy < energy_threshold_starving:
		return EnergyMode.STARVING
	elif energy <= energy_threshold_thriving:
		return EnergyMode.DEVELOPING
	else:
		return EnergyMode.THRIVING


## Update with current position and follicle state
func update(position: Vector2, delta: float, follicle_state: Dictionary = {}) -> void:
	current_position = position
	
	# Update energy mode
	var energy = follicle_state.get("energy", 5.0)
	current_energy_mode = get_energy_mode(energy)
	
	# Update target selection timer
	target_update_timer += delta
	
	# Periodically re-evaluate target
	if target_update_timer >= target_update_interval:
		target_update_timer = 0.0
		_select_intelligent_target(follicle_state)


## Return direction toward target
func get_direction() -> Vector2:
	var direction = target - current_position
	if direction.length() > 0:
		return direction.normalized()
	return Vector2.ZERO


## Select best target based on perception and evaluation
func _select_intelligent_target(follicle_state: Dictionary) -> void:
	if far_field == null:
		_pick_random_target()
		return
	
	# Get all active pellets from FarField
	var all_pellets: Array = []
	if far_field.has_method("get_active_pellets"):
		all_pellets = far_field.get_active_pellets()
	
	if all_pellets.is_empty():
		_pick_random_target()
		return
	
	# STARVING mode: use simplified urgent behavior
	if current_energy_mode == EnergyMode.STARVING:
		_select_starving_target(all_pellets)
		return
	
	# DEVELOPING and THRIVING modes: use normal evaluation
	# Filter pellets within perception radius
	var perceived_pellets: Array[Dictionary] = []
	for pellet in all_pellets:
		if pellet == null or not is_instance_valid(pellet):
			continue
		var distance = current_position.distance_to(pellet.global_position)
		if distance <= perception_radius:
			perceived_pellets.append({
				"pellet": pellet,
				"distance": distance,
				"type": pellet.hormone_type if "hormone_type" in pellet else 0
			})
	
	if perceived_pellets.is_empty():
		_pick_random_target()
		return
	
	# Evaluate and select best target
	var best_score: float = -INF
	var best_target_pos: Vector2 = target
	var best_pellet: Area2D = null
	
	for data in perceived_pellets:
		var score = _evaluate_target(data, follicle_state)
		if score > best_score:
			best_score = score
			best_target_pos = data.pellet.global_position
			best_pellet = data.pellet
	
	# Update target
	if best_pellet != null:
		target = best_target_pos
		current_target_pellet = best_pellet


## STARVING mode: find nearest FSH within limited range
func _select_starving_target(all_pellets: Array) -> void:
	var nearest_fsh: Area2D = null
	var nearest_distance: float = INF
	
	for pellet in all_pellets:
		if pellet == null or not is_instance_valid(pellet):
			continue
		
		# Only consider FSH pellets (type 0)
		var pellet_type = pellet.hormone_type if "hormone_type" in pellet else 0
		if pellet_type != 0:
			continue
		
		# Only within starving mode distance limit
		var distance = current_position.distance_to(pellet.global_position)
		if distance > starving_mode_max_distance:
			continue
		
		# Track nearest
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_fsh = pellet
	
	# Set target to nearest FSH or fallback to random
	if nearest_fsh != null:
		target = nearest_fsh.global_position
		current_target_pellet = nearest_fsh
	else:
		_pick_random_target()


## Evaluate target score (higher = better)
func _evaluate_target(pellet_data: Dictionary, follicle_state: Dictionary) -> float:
	var distance: float = pellet_data.distance
	var pellet_type: int = pellet_data.type
	
	# Get follicle state (defaults if not provided)
	var fsh_sensitivity: float = follicle_state.get("fsh_sensitivity", 1.0)
	var lh_receptor_count: int = follicle_state.get("lh_receptor_count", 0)
	
	# Base energy values from config
	var energy_cfg = ConfigManager.get_config("world.energy")
	var fsh_base: float = energy_cfg.fsh_base_energy
	var lh_base: float = energy_cfg.lh_base_energy
	
	# Calculate target value based on type
	var value: float = 0.0
	if pellet_type == 0:  # FSH
		value = fsh_base * fsh_sensitivity
	else:  # LH
		value = lh_base * lh_receptor_count if lh_receptor_count > 0 else 0.0
	
	# Score formula: value / (distance + buffer)
	# Buffer prevents division by zero and smooths nearby differences
	var distance_factor = distance_weight * (distance + 50.0)
	var value_factor = value_weight * value
	
	var score = value_factor / distance_factor if distance_factor > 0 else 0.0
	
	return score


## Fallback: pick random target in arena
func _pick_random_target() -> void:
	target = Vector2(
		randf_range(play_rect.position.x, play_rect.position.x + play_rect.size.x),
		randf_range(play_rect.position.y, play_rect.position.y + play_rect.size.y)
	)
	current_target_pellet = null
