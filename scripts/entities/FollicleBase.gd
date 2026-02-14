## FollicleBase - Base class for all follicles
class_name FollicleBase
extends CharacterBody2D


const HORMONE_FSH := 0
const HORMONE_LH := 1
const SKILL_E2 := 1
const SKILL_INHIBIN := 2
const SKILL_LH_RECEPTOR := 3

signal energy_changed(new_energy: int)
signal sensitivity_changed(new_sensitivity: float)
signal digestion_completed(hormone_type: int)
signal died(follicle: Node)
signal lh_receptor_acquired(follicle: Node, count: int)
var controller: ControllerBase
var movement_system: MovementSystem
var radius: float
var circle_color: Color
var collision_cooldown_timer: float = 0.0
var lh_receptor_count: int = 0
var rotation_angle: float = 0.0

# Energy and sensitivity
var energy: float = 0.0
var energy_max: float = 12.0
var fsh_sensitivity: float = 1.0
var fsh_sensitivity_base: float = 1.0
var fsh_sensitivity_min: float = 1.0
var fsh_sensitivity_max: float = 5.0
var fsh_base_energy: float = 1.0
var lh_base_energy: float = 1.0
var energy_decay_interval: float = 15.0
var energy_decay_amount: float = 1.0
var zero_energy_death_seconds: float = 20.0
var energy_decay_timer: float = 0.0
var zero_energy_timer: float = 0.0
var skill_costs: Dictionary = {}
var stage_cfg: Dictionary = {}
var is_dead: bool = false
var sensitivity_increment: float = 0.0

# Digestion state
var fsh_digest_time: float = 2.0
var lh_digest_time: float = 4.0
var fsh_digest_remaining: float = 0.0
var lh_digest_remaining: Array[float] = []

# LH receptor configuration
var lh_receptor_config: Dictionary

# Stage 1 vibration state
var is_vibrating: bool = false
var vibration_timer: float = 0.0
var vibration_duration: float = 0.0
var vibration_amplitude: float = 0.0
var vibration_frequency: float = 0.0
var vibration_direction: Vector2 = Vector2.ZERO
var origin_position: Vector2 = Vector2.ZERO
var initial_position: Vector2 = Vector2.ZERO  # Fixed position set by layout

@export var is_player: bool = false


func _ready() -> void:
	var prefix = "player_follicle" if is_player else "npc_follicle"
	var move_cfg = ConfigManager.get_config("%s.movement" % prefix)
	var size_cfg = ConfigManager.get_config("%s.size" % prefix)
	var color_cfg = ConfigManager.get_config("%s.appearance.color" % prefix)
	var energy_cfg = ConfigManager.get_config("%s.energy" % prefix)
	var sensitivity_cfg = ConfigManager.get_config("%s.sensitivity" % prefix)
	
	radius = size_cfg.collision_radius
	
	# Load LH receptor configuration
	lh_receptor_config = ConfigManager.get_config("world.lh_receptor")

	# Load digestion timing
	var digest_cfg = ConfigManager.get_config("world.receptor_digest")
	fsh_digest_time = digest_cfg.fsh.digest_time
	lh_digest_time = digest_cfg.lh.digest_time
	lh_digest_remaining.clear()

	# Load energy and sensitivity
	energy_max = energy_cfg.max
	energy = clampf(energy_cfg.initial, 0.0, energy_max)
	fsh_sensitivity_min = sensitivity_cfg.min
	fsh_sensitivity_max = sensitivity_cfg.max
	fsh_sensitivity_base = clampf(sensitivity_cfg.initial, fsh_sensitivity_min, fsh_sensitivity_max)
	fsh_sensitivity = fsh_sensitivity_base

	var skill_effects_cfg = ConfigManager.get_config("world.skill_effects")
	sensitivity_increment = skill_effects_cfg.e2_sensitivity_increment

	var energy_base_cfg = ConfigManager.get_config("world.energy")
	fsh_base_energy = energy_base_cfg.fsh_base_energy
	lh_base_energy = energy_base_cfg.lh_base_energy

	var energy_rules_cfg = ConfigManager.get_config("world.energy_rules")
	energy_decay_interval = energy_rules_cfg.decay_interval
	energy_decay_amount = energy_rules_cfg.decay_amount
	zero_energy_death_seconds = energy_rules_cfg.zero_energy_death_seconds
	energy_decay_timer = 0.0
	zero_energy_timer = 0.0

	skill_costs = ConfigManager.get_config("world.skill_costs")
	stage_cfg = ConfigManager.get_config("world.stage")
	
	movement_system = MovementSystem.new(
		move_cfg.max_speed,
		move_cfg.acceleration_factor,
		move_cfg.deceleration_factor,
		move_cfg.min_speed,
		radius,
		ConfigManager.get_config("world.arena")
	)
	
	# Set random initial velocity
	var speed_range = move_cfg.initial_speed_range
	var random_speed = randf_range(speed_range.min, speed_range.max)
	var random_angle = randf_range(0, TAU)
	movement_system.velocity = Vector2(cos(random_angle), sin(random_angle)) * random_speed
	
	circle_color = Color(color_cfg.r, color_cfg.g, color_cfg.b)
	_emit_status()
	
	_init_controller()
	print("[FollicleBase] Registering %s with FollicleManager" % name)
	FollicleManager.register_follicle(self)
	
	# Load Stage 1 vibration parameters
	var stage1_cfg = ConfigManager.get_config("world.stage_1")
	var awakening_cfg = stage1_cfg.awakening
	vibration_duration = awakening_cfg.vibration_duration
	vibration_amplitude = radius * awakening_cfg.vibration_amplitude_ratio
	vibration_frequency = awakening_cfg.vibration_frequency
	# origin_position will be captured dynamically when vibrate() is called


func _exit_tree() -> void:
	FollicleManager.unregister_follicle(self)


func _init_controller() -> void:
	controller = ControllerBase.new()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# In Stage 1, follicles are stationary (awaiting awakening)
	var stage_cfg = ConfigManager.get_config("world.stage")
	var current_stage = stage_cfg.get("current", "2_0")
	if current_stage == "1":
		# Process vibration if active
		if is_vibrating:
			_process_vibration(delta)
		# Still update visual elements like receptor rotation
		if lh_receptor_count > 0:
			rotation_angle += deg_to_rad(lh_receptor_config.rotation_speed) * delta
			queue_redraw()
		return
	
	# Decrease collision cooldown
	if collision_cooldown_timer > 0:
		collision_cooldown_timer -= delta

	_update_digestion(delta)
	_update_energy_decay(delta)
	
	# Update LH receptor rotation
	if lh_receptor_count > 0:
		rotation_angle += deg_to_rad(lh_receptor_config.rotation_speed) * delta
		queue_redraw()
	
	# Get direction from controller (suppressed during cooldown)
	var direction = Vector2.ZERO
	if collision_cooldown_timer <= 0:
		if not is_player and controller is AIController:
			# Build state dictionary for AI decision making
			var follicle_state = {
				"fsh_sensitivity": fsh_sensitivity,
				"lh_receptor_count": lh_receptor_count,
				"energy": energy
			}
			controller.update(global_position, delta, follicle_state)
		direction = controller.get_direction()
	
	# Update movement
	movement_system.update(direction, delta)
	
	# Move with physics using move_and_collide (not move_and_slide)
	# This allows us to handle follicle-follicle collisions separately in CollisionManager
	var _collision = move_and_collide(movement_system.velocity * delta)
	
	# Collision with world/static bodies is handled by move_and_collide result
	# Follicle-follicle collisions are handled by CollisionManager in a separate pass
	
	# Check boundary collision and bounce
	global_position = movement_system.check_and_bounce(global_position)


func _draw() -> void:
	# Draw main follicle circle
	draw_circle(Vector2.ZERO, radius, circle_color)
	
	# Draw LH receptors (orange circles rotating around the follicle)
	if lh_receptor_count > 0:
		var receptor_color = Color(
			lh_receptor_config.receptor_color.r,
			lh_receptor_config.receptor_color.g,
			lh_receptor_config.receptor_color.b
		)
		var receptor_radius = lh_receptor_config.receptor_radius
		var orbit_radius = lh_receptor_config.orbit_radius
		
		for i in range(lh_receptor_count):
			var angle = rotation_angle + (TAU * i / lh_receptor_count)
			var receptor_pos = Vector2(
				cos(angle) * orbit_radius,
				sin(angle) * orbit_radius
			)
			draw_circle(receptor_pos, receptor_radius, receptor_color)


## Emit E2 hormone (available to all follicles)
func emit_e2() -> void:
	if SecretionManager:
		SecretionManager.emit_e2(global_position)


## Emit Inhibin B hormone (available to all follicles)
func emit_inhibin_b() -> void:
	if SecretionManager:
		SecretionManager.emit_inhibin_b(global_position)


## Acquire LH receptor (skill 3, increases count up to max)
func acquire_lh_receptor() -> bool:
	var max_receptors = lh_receptor_config.max_count
	if lh_receptor_count < max_receptors:
		lh_receptor_count += 1
		lh_digest_remaining.append(0.0)
		queue_redraw()
		lh_receptor_acquired.emit(self, lh_receptor_count)
		return true
	return false


func try_digest(hormone_type: int) -> bool:
	if hormone_type == HORMONE_FSH:
		if fsh_digest_remaining <= 0.0:
			fsh_digest_remaining = fsh_digest_time
			return true
		return false
	if hormone_type == HORMONE_LH:
		for i in range(lh_digest_remaining.size()):
			if lh_digest_remaining[i] <= 0.0:
				lh_digest_remaining[i] = lh_digest_time
				return true
		return false
	return false


func _update_digestion(delta: float) -> void:
	if fsh_digest_remaining > 0.0:
		fsh_digest_remaining -= delta
		if fsh_digest_remaining <= 0.0:
			fsh_digest_remaining = 0.0
			digestion_completed.emit(HORMONE_FSH)
			_apply_energy_gain(HORMONE_FSH)

	for i in range(lh_digest_remaining.size()):
		if lh_digest_remaining[i] > 0.0:
			lh_digest_remaining[i] -= delta
			if lh_digest_remaining[i] <= 0.0:
				lh_digest_remaining[i] = 0.0
				digestion_completed.emit(HORMONE_LH)
				_apply_energy_gain(HORMONE_LH)


func can_use_skill(skill_id: int) -> bool:
	if skill_id == SKILL_LH_RECEPTOR and not is_player:
		var rules = _get_stage_rules()
		if not rules.get("npc_skill3_allowed", true):
			return false
	return true


func apply_sensitivity_buff() -> void:
	if sensitivity_increment <= 0.0:
		return
	fsh_sensitivity_base = clampf(
		fsh_sensitivity_base + sensitivity_increment,
		fsh_sensitivity_min,
		fsh_sensitivity_max
	)
	fsh_sensitivity = fsh_sensitivity_base
	sensitivity_changed.emit(fsh_sensitivity)


func spend_energy(cost: float) -> bool:
	if energy < cost:
		return false
	energy = clampf(energy - cost, 0.0, energy_max)
	energy_changed.emit(energy)
	return true


func get_skill_cost(skill_id: int) -> float:
	if skill_id == SKILL_E2:
		return skill_costs.skill1
	if skill_id == SKILL_INHIBIN:
		return skill_costs.skill2
	if skill_id == SKILL_LH_RECEPTOR:
		return skill_costs.skill3
	return 0.0


func _apply_energy_gain(hormone_type: int) -> void:
	var gain = 0.0
	if hormone_type == HORMONE_FSH:
		gain = fsh_base_energy * fsh_sensitivity
	elif hormone_type == HORMONE_LH:
		# LH energy gain scales with receptor count (receptor count acts as LH sensitivity)
		gain = lh_base_energy * lh_receptor_count
	energy = clampf(energy + gain, 0.0, energy_max)
	energy_changed.emit(energy)


func _recompute_sensitivity() -> void:
	fsh_sensitivity = clampf(fsh_sensitivity_base, fsh_sensitivity_min, fsh_sensitivity_max)


func _update_energy_decay(delta: float) -> void:
	var rules = _get_stage_rules()
	if rules.get("energy_decay_enabled", false):
		energy_decay_timer += delta
		if energy_decay_timer >= energy_decay_interval:
			energy_decay_timer = 0.0
			energy = clampf(energy - energy_decay_amount, 0.0, energy_max)
			energy_changed.emit(energy)
			if not is_player and energy == 0.0:
				print("[FollicleBase] NPC energy reached 0, zero_energy_timer will start")
	else:
		energy_decay_timer = 0.0

	if rules.get("zero_energy_death_enabled", false):
		if energy <= 0.0:
			zero_energy_timer += delta
			if zero_energy_timer >= zero_energy_death_seconds:
				if not is_player:
					print("[FollicleBase] NPC zero energy for %.1fs, triggering death" % zero_energy_timer)
				_die()
		else:
			zero_energy_timer = 0.0
	else:
		zero_energy_timer = 0.0


func _get_stage_rules() -> Dictionary:
	var current = stage_cfg.current
	if stage_cfg.rules.has(current):
		return stage_cfg.rules[current]
	return {}


## Set the initial position (called by NearField after layout)
func set_initial_position(pos: Vector2) -> void:
	initial_position = pos


## Stage 1: Trigger circular vibration (awakening animation)
func vibrate(direction: Vector2 = Vector2.ZERO) -> void:
	# Use fixed initial position instead of current position
	origin_position = initial_position
	
	# For circular motion, direction determines starting angle
	# If no direction specified, choose random starting angle
	var start_angle: float
	if direction.length_squared() < 0.01:
		start_angle = randf_range(0, TAU)
	else:
		start_angle = direction.angle()
	
	# Store vibration state
	is_vibrating = true
	vibration_timer = 0.0
	# Store starting angle in direction's x component
	vibration_direction = Vector2(start_angle, 0)
	
	print("[FollicleBase] %s CAPTURED origin: (%.1f, %.1f), start_angle: %.1f°, amplitude: %.1fpx, duration: %.2fs" % [
		name,
		origin_position.x,
		origin_position.y,
		rad_to_deg(start_angle),
		vibration_amplitude,
		vibration_duration
	])


## Process circular vibration motion
func _process_vibration(delta: float) -> void:
	if not is_vibrating:
		return
	
	vibration_timer += delta
	
	# Check if vibration completed
	if vibration_timer >= vibration_duration:
		is_vibrating = false
		print("[FollicleBase] %s BEFORE归位: current pos (%.1f, %.1f), origin (%.1f, %.1f)" % [
			name, global_position.x, global_position.y, origin_position.x, origin_position.y
		])
		global_position = origin_position  # Snap back to origin
		print("[FollicleBase] %s AFTER归位: current pos (%.1f, %.1f)" % [
			name, global_position.x, global_position.y
		])
		return
	
	# Calculate circular motion: 
	# x(t) = A × cos(2πft + θ₀)
	# y(t) = A × sin(2πft + θ₀)
	var start_angle = vibration_direction.x
	var phase = TAU * vibration_frequency * vibration_timer + start_angle
	var offset = Vector2(
		vibration_amplitude * cos(phase),
		vibration_amplitude * sin(phase)
	)
	
	# Apply offset from origin position
	global_position = origin_position + offset


func _die() -> void:
	if is_dead:
		return
	print("[FollicleBase] %s dying (is_player=%s)" % [name, is_player])
	is_dead = true
	movement_system.velocity = Vector2.ZERO
	set_physics_process(false)
	# Make dead follicle semi-transparent
	modulate.a = 0.3
	print("[FollicleBase] Emitting died signal for %s" % name)
	died.emit(self)
	print("[FollicleBase] Died signal emitted for %s" % name)


func _emit_status() -> void:
	energy_changed.emit(energy)
	sensitivity_changed.emit(fsh_sensitivity)


func get_energy() -> float:
	return energy


func get_sensitivity() -> float:
	return fsh_sensitivity
