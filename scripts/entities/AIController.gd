## AIController - Simple AI that picks random targets
class_name AIController
extends ControllerBase

var target: Vector2 = Vector2.ZERO
var play_rect: Rect2
var target_pickup_distance: float
var current_position: Vector2 = Vector2.ZERO


func _init(config_arena: Dictionary, config_target_distance: float) -> void:
	play_rect = Rect2(
		Vector2(config_arena["position_x"], config_arena["position_y"]),
		Vector2(config_arena["width"], config_arena["height"])
	)
	target_pickup_distance = config_target_distance
	randomize()
	_pick_target()


## Update with current position - checks if target reached
func update(position: Vector2) -> void:
	current_position = position
	if current_position.distance_to(target) < target_pickup_distance:
		_pick_target()


## Return direction toward target
func get_direction() -> Vector2:
	var direction = target - current_position
	if direction.length() > 0:
		return direction.normalized()
	return Vector2.ZERO


func _pick_target() -> void:
	target = Vector2(
		randf_range(play_rect.position.x, play_rect.position.x + play_rect.size.x),
		randf_range(play_rect.position.y, play_rect.position.y + play_rect.size.y)
	)
