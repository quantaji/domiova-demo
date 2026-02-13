## MovementSystem - Handles movement with smooth acceleration/deceleration
class_name MovementSystem

var velocity: Vector2 = Vector2.ZERO
var max_speed: float
var acceleration_factor: float
var deceleration_factor: float
var min_speed: float
var play_rect: Rect2


func _init(config_speed: float, config_accel: float, config_decel: float, config_min_speed: float, config_arena: Dictionary) -> void:
	max_speed = config_speed
	acceleration_factor = config_accel
	deceleration_factor = config_decel
	min_speed = config_min_speed
	play_rect = Rect2(
		Vector2(config_arena["position_x"], config_arena["position_y"]),
		Vector2(config_arena["width"], config_arena["height"])
	)


## Update velocity based on direction input using Lerp for smooth acceleration
func update(direction: Vector2, delta: float) -> void:
	if direction.length_squared() > 0:
		var target = direction.normalized() * max_speed
		velocity = velocity.lerp(target, min(acceleration_factor * delta, 1.0))
		return
	
	if velocity.length() <= min_speed:
		return
	
	var target = velocity.normalized() * min_speed
	velocity = velocity.lerp(target, min(deceleration_factor * delta, 1.0))


## Clamp position to bounds
func clamp_to_bounds(position: Vector2) -> Vector2:
	return Vector2(
		clamp(position.x, play_rect.position.x, play_rect.position.x + play_rect.size.x),
		clamp(position.y, play_rect.position.y, play_rect.position.y + play_rect.size.y)
	)
