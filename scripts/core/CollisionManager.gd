## CollisionManager - Central collision system that drives collision detection
extends Node

var collision_resolver: CollisionResolver
var collision_distance_sq: float
var collision_cooldown: float


func _ready() -> void:
	var collision_config = ConfigManager.get_config("world.collision")
	var follicle_radius = ConfigManager.get_config("player_follicle.size.collision_radius")
	var collision_distance = follicle_radius * 2
	collision_distance_sq = collision_distance * collision_distance
	collision_cooldown = collision_config["collision_cooldown"]
	collision_resolver = CollisionResolver.new(collision_config, follicle_radius)


func _physics_process(delta: float) -> void:
	var follicles = FollicleManager.get_all_follicles()
	
	for i in range(follicles.size()):
		for j in range(i + 1, follicles.size()):
			var f1 = follicles[i]
			var f2 = follicles[j]
			
			if f1.global_position.distance_squared_to(f2.global_position) < collision_distance_sq:
				_apply_collision(f1, f2)


## Apply collision response between two followers
func _apply_collision(f1: FollicleBase, f2: FollicleBase) -> void:
	var response = collision_resolver.resolve_collision(
		f1.global_position, f1.movement_system.velocity,
		f2.global_position, f2.movement_system.velocity
	)
	
	# Apply results to both followers
	f1.global_position = response["pos_a"]
	f1.movement_system.velocity = response["vel_a"]
	f1.collision_cooldown_timer = collision_cooldown
	
	f2.global_position = response["pos_b"]
	f2.movement_system.velocity = response["vel_b"]
	f2.collision_cooldown_timer = collision_cooldown
