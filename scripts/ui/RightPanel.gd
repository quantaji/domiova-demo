## RightPanel - Container for Direction Pad and Skill Panel
class_name RightPanel
extends Control

var direction_pad: DirectionPad
var skill_panel: SkillPanel

var position_x: float
var position_y: float


func _ready() -> void:
	_load_config()
	global_position = Vector2(position_x, position_y)
	_create_components()


func _load_config() -> void:
	var cfg = ConfigManager.get_config("ui.right_panel")
	position_x = cfg.position_x
	position_y = cfg.position_y


func _create_components() -> void:
	# Create Skill Panel (above direction pad)
	skill_panel = SkillPanel.new()
	skill_panel.position = Vector2.ZERO
	add_child(skill_panel)
	
	# Create Direction Pad (below skill panel)
	direction_pad = DirectionPad.new()
	var spacing = 20.0
	direction_pad.position = Vector2(0, skill_panel.total_height + spacing)
	add_child(direction_pad)
	
	# Set total size
	size = Vector2(
		max(skill_panel.total_width, direction_pad.total_width),
		skill_panel.total_height + spacing + direction_pad.total_height
	)
