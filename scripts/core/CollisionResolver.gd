## CollisionResolver - Pure collision calculation logic
class_name CollisionResolver

var push_strength: float
var velocity_change_factor: float
var min_explosion_speed: float
var min_distance: float


func _init(config_collision: Dictionary, follicle_radius: float) -> void:
	push_strength = config_collision["push_strength"]
	velocity_change_factor = config_collision["velocity_change_factor"]
	min_explosion_speed = config_collision["min_explosion_speed"]
	min_distance = follicle_radius * 2


## Calculate collision response between two followers
## Returns dict with updated positions and velocities for both
func resolve_collision(
	follicle_a_pos: Vector2, follicle_a_vel: Vector2,
	follicle_b_pos: Vector2, follicle_b_vel: Vector2
) -> Dictionary:
	var distance_vec = follicle_a_pos - follicle_b_pos
	var distance = distance_vec.length()
	if distance < 0.01:
		distance = 0.01
	
	var push_dir = distance_vec.normalized()
	var overlap = max(0, min_distance - distance)
	var separation = overlap * push_strength
	
	var new_pos_a = follicle_a_pos + push_dir * separation
	var new_pos_b = follicle_b_pos - push_dir * separation
	
	# Elastic collision with explosion push
	var a_normal = follicle_a_vel.dot(push_dir)
	var b_normal = follicle_b_vel.dot(push_dir)
	var new_vel_a = follicle_a_vel + push_dir * (b_normal - a_normal + min_explosion_speed)
	var new_vel_b = follicle_b_vel + push_dir * (a_normal - b_normal - min_explosion_speed)
	
	return {
		"pos_a": new_pos_a,
		"vel_a": new_vel_a,
		"pos_b": new_pos_b,
		"vel_b": new_vel_b
	}
