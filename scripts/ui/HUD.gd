## HUD - Main UI controller that manages all UI panels
class_name HUD
extends Control

var left_panel: LeftPanel
var right_panel: RightPanel


func _ready() -> void:
	# Set to full screen size
	size = get_viewport().get_visible_rect().size
	add_to_group("hud")
	
	# Create left panel
	left_panel = LeftPanel.new()
	add_child(left_panel)
	
	# Create right panel
	right_panel = RightPanel.new()
	add_child(right_panel)


## Update player energy display
func set_player_energy(value: int) -> void:
	if left_panel:
		left_panel.set_energy(value)


## Update player FSH sensitivity display
func set_player_sensitivity(value: float) -> void:
	if left_panel:
		left_panel.set_sensitivity(value)


## Get current displayed energy
func get_displayed_energy() -> int:
	if left_panel:
		return left_panel.get_energy()
	return 0


## Get current displayed sensitivity
func get_displayed_sensitivity() -> float:
	if left_panel:
		return left_panel.get_sensitivity()
	return 1.0
