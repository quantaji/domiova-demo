## NPCFollicle - AI-controlled follicle
class_name NPCFollicle
extends FollicleBase


func _ready() -> void:
	is_player = false
	super._ready()


func _init_controller() -> void:
	var arena = ConfigManager.get_config("world.arena")
	var target_distance = ConfigManager.get_config("npc_follicle.movement.target_pickup_distance")
	controller = AIController.new(arena, target_distance)
