## PlayerFollicle - Player-controlled follicle
class_name PlayerFollicle
extends FollicleBase


func _ready() -> void:
	is_player = true
	super._ready()


func _init_controller() -> void:
	controller = PlayerController.new()


func _physics_process(delta: float) -> void:
	# Check skill inputs and trigger them before normal physics
	if controller is PlayerController:
		if controller.is_skill_1_pressed():
			emit_e2()
		if controller.is_skill_2_pressed():
			emit_inhibin_b()
		if controller.is_skill_3_pressed():
			acquire_lh_receptor()
	
	# Call parent physics process for normal movement
	super._physics_process(delta)
