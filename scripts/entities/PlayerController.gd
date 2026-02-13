## PlayerController - Reads input from player
class_name PlayerController
extends ControllerBase


func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)


## Check if skill 1 (E2) was pressed
func is_skill_1_pressed() -> bool:
	return Input.is_action_just_pressed("skill_1")


## Check if skill 2 (Inhibin B) was pressed
func is_skill_2_pressed() -> bool:
	return Input.is_action_just_pressed("skill_2")


## Check if skill 3 (LH receptor) was pressed
func is_skill_3_pressed() -> bool:
	return Input.is_action_just_pressed("skill_3")
