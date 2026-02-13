## ConfigManager - Loads and provides access to game configuration from JSON
extends Node

var config: Dictionary = {}


func _ready() -> void:
	var file = FileAccess.open("res://config.json", FileAccess.READ)
	config = JSON.parse_string(file.get_as_text())


func get_config(path: String):
	var current = config
	for key in path.split("."):
		current = current[key]
	return current
