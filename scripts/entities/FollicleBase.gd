## FollicleBase - Base class for all follicles
class_name FollicleBase
extends CharacterBody2D

var controller: ControllerBase
var movement_system: MovementSystem
var radius: float
var circle_color: Color
var collision_cooldown_timer: float = 0.0

@export var is_player: bool = false


func _ready() -> void:
	var prefix = "player_follicle" if is_player else "npc_follicle"
	var move_cfg = ConfigManager.get_config("%s.movement" % prefix)
	var size_cfg = ConfigManager.get_config("%s.size" % prefix)
	var color_cfg = ConfigManager.get_config("%s.appearance.color" % prefix)
	
	radius = size_cfg.collision_radius
	
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
	# Draw filled circle
	draw_circle(Vector2.ZERO, radius, circle_color)
