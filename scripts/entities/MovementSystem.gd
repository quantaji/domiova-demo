## MovementSystem - Handles movement with smooth acceleration/deceleration
class_name MovementSystem

var velocity: Vector2 = Vector2.ZERO
var max_speed: float
var acceleration_factor: float
var deceleration_factor: float
var min_speed: float
var play_rect: Rect2
var bounce_margin: float
var bounce_speed: float
var bounce_control_lockout: float
var control_lockout_timer: float = 0.0
var radius: float


func _init(config_speed: float, config_accel: float, config_decel: float, config_min_speed: float, follicle_radius: float, config_arena: Dictionary) -> void:
	max_speed = config_speed
	acceleration_factor = config_accel
	deceleration_factor = config_decel
	min_speed = config_min_speed
	radius = follicle_radius
	play_rect = Rect2(
		Vector2(config_arena["position_x"], config_arena["position_y"]),
		Vector2(config_arena["width"], config_arena["height"])
	)
	bounce_margin = config_arena.get("bounce_margin", 5.0)
	bounce_speed = config_arena.get("bounce_speed", 60.0)
	bounce_control_lockout = config_arena.get("bounce_control_lockout", 0.2)


## Update velocity based on direction input using Lerp for smooth acceleration
func update(direction: Vector2, delta: float) -> void:
	# Update control lockout timer
	if control_lockout_timer > 0:
		control_lockout_timer -= delta
		return  # Ignore input during lockout period
	
	if direction.length_squared() > 0:
		var target_velocity = direction.normalized() * max_speed
		velocity = velocity.lerp(target_velocity, min(acceleration_factor * delta, 1.0))
		return
	
	if velocity.length() <= min_speed:
		return
	
	var target = velocity.normalized() * min_speed
	velocity = velocity.lerp(target, min(deceleration_factor * delta, 1.0))


## Check boundary collision and apply bounce
func check_and_bounce(position: Vector2) -> Vector2:
	var left_bound = play_rect.position.x + radius + bounce_margin
	var right_bound = play_rect.position.x + play_rect.size.x - radius - bounce_margin
	var top_bound = play_rect.position.y + radius + bounce_margin
	var bottom_bound = play_rect.position.y + play_rect.size.y - radius - bounce_margin
	
	var new_position = position
	var bounced = false
	
	# Left boundary: clamp position and ensure velocity points away from wall
	if position.x < left_bound:
		new_position.x = left_bound
		velocity.x = max(velocity.x, bounce_speed)  # Ensure minimum bounce speed rightward
		bounced = true
	
	# Right boundary
	if position.x > right_bound:
		new_position.x = right_bound
		velocity.x = min(velocity.x, -bounce_speed)  # Ensure minimum bounce speed leftward
		bounced = true
	
	# Top boundary
	if position.y < top_bound:
		new_position.y = top_bound
		velocity.y = max(velocity.y, bounce_speed)  # Ensure minimum bounce speed downward
		bounced = true
	
	# Bottom boundary
	if position.y > bottom_bound:
		new_position.y = bottom_bound
		velocity.y = min(velocity.y, -bounce_speed)  # Ensure minimum bounce speed upward
		bounced = true
	
	# Lock out control input for a short period after bounce
	if bounced:
		control_lockout_timer = bounce_control_lockout
	
	return new_position
