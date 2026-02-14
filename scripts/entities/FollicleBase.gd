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
	FollicleManager.register_follicle(self)


func _exit_tree() -> void:
	FollicleManager.unregister_follicle(self)


func _init_controller() -> void:
	controller = ControllerBase.new()


func _physics_process(delta: float) -> void:
	if is_dead:
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
			controller.update(global_position)
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
	else:
		energy_decay_timer = 0.0

	if rules.get("zero_energy_death_enabled", false):
		if energy <= 0.0:
			zero_energy_timer += delta
			if zero_energy_timer >= zero_energy_death_seconds:
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


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	movement_system.velocity = Vector2.ZERO
	set_physics_process(false)
	died.emit(self)


func _emit_status() -> void:
	energy_changed.emit(energy)
	sensitivity_changed.emit(fsh_sensitivity)


func get_energy() -> float:
	return energy


func get_sensitivity() -> float:
	return fsh_sensitivity
