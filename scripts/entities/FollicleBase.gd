## FollicleBase - Base class for all follicles
class_name FollicleBase
extends CharacterBody2D

var controller: ControllerBase
var movement_system: MovementSystem
var radius: float
var circle_color: Color
var collision_cooldown_timer: float = 0.0
var lh_receptor_count: int = 0
var rotation_angle: float = 0.0

# LH receptor configuration
var lh_receptor_config: Dictionary

@export var is_player: bool = false


func _ready() -> void:
	var prefix = "player_follicle" if is_player else "npc_follicle"
	var move_cfg = ConfigManager.get_config("%s.movement" % prefix)
	var size_cfg = ConfigManager.get_config("%s.size" % prefix)
	var color_cfg = ConfigManager.get_config("%s.appearance.color" % prefix)
	
	radius = size_cfg.collision_radius
	
	# Load LH receptor configuration
	lh_receptor_config = ConfigManager.get_config("world.lh_receptor")
	
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
	
	_init_controller()
	FollicleManager.register_follicle(self)


func _exit_tree() -> void:
	FollicleManager.unregister_follicle(self)


func _init_controller() -> void:
	controller = ControllerBase.new()


func _physics_process(delta: float) -> void:
	# Decrease collision cooldown
	if collision_cooldown_timer > 0:
		collision_cooldown_timer -= delta
	
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
func acquire_lh_receptor() -> void:
	var max_receptors = lh_receptor_config.max_count
	if lh_receptor_count < max_receptors:
		lh_receptor_count += 1
		queue_redraw()
