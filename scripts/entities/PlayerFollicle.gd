## PlayerFollicle - Player-controlled follicle
class_name PlayerFollicle
extends FollicleBase


func _ready() -> void:
	is_player = true
	super._ready()


func _init_controller() -> void:
	controller = PlayerController.new()
