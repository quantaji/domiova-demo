## NPCFollicle - AI-controlled follicle
class_name NPCFollicle
extends FollicleBase

# Pseudo-AI secretion timers
var e2_timer: float = 0.0
var inhibin_b_timer: float = 0.0
var skill3_timer: float = 0.0


func _ready() -> void:
	is_player = false
	super._ready()
	
	# Initialize secretion timers with random intervals
	e2_timer = randf_range(5.0, 10.0)
	inhibin_b_timer = randf_range(5.0, 10.0)
	skill3_timer = randf_range(5.0, 10.0)


func _init_controller() -> void:
	var arena = ConfigManager.get_config("world.arena")
	var target_distance = ConfigManager.get_config("npc_follicle.movement.target_pickup_distance")
	controller = AIController.new(arena, target_distance)


func _physics_process(delta: float) -> void:
	# Update pseudo-AI secretion timers
	e2_timer -= delta
	if e2_timer <= 0:
		emit_e2()
		e2_timer = randf_range(5.0, 10.0)
	
	inhibin_b_timer -= delta
	if inhibin_b_timer <= 0:
		emit_inhibin_b()
		inhibin_b_timer = randf_range(5.0, 10.0)
	
	# Update skill 3 (LH receptor) timer
	skill3_timer -= delta
	if skill3_timer <= 0:
		acquire_lh_receptor()
		skill3_timer = randf_range(5.0, 10.0)
	
	# Call parent physics process for normal movement
	super._physics_process(delta)
