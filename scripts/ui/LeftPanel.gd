## LeftPanel - Container for Energy Bar and Sensitivity Bar
class_name LeftPanel
extends Control

var energy_bar: EnergyBar
var sensitivity_bar: SensitivityBar

var position_x: float
var position_y: float
var padding: float


func _ready() -> void:
	_load_config()
	global_position = Vector2(position_x, position_y)
	_create_components()


func _load_config() -> void:
	var cfg = ConfigManager.get_config("ui.left_panel")
	position_x = cfg.position_x
	position_y = cfg.position_y
	padding = cfg.padding


func _create_components() -> void:
	# Create Energy Bar
	energy_bar = EnergyBar.new()
	energy_bar.position = Vector2.ZERO
	add_child(energy_bar)
	
	# Create Sensitivity Bar
	sensitivity_bar = SensitivityBar.new()
	sensitivity_bar.position = Vector2(0, energy_bar.bar_height + padding)
	add_child(sensitivity_bar)
	
	# Set total size
	size = Vector2(
		energy_bar.bar_width,
		energy_bar.bar_height + padding + sensitivity_bar.height
	)


func set_energy(value: int) -> void:
	if energy_bar:
		energy_bar.set_current_energy(value)


func get_energy() -> int:
	if energy_bar:
		return energy_bar.get_current_energy()
	return 0


func set_sensitivity(value: float) -> void:
	if sensitivity_bar:
		sensitivity_bar.set_sensitivity(value)


func get_sensitivity() -> float:
	if sensitivity_bar:
		return sensitivity_bar.get_sensitivity()
	return 1.0
