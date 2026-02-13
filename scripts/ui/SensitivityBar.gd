## SensitivityBar - Display FSH sensitivity as continuous bar fill
class_name SensitivityBar
extends Control

var current_value: float = 1.0

# Configuration
var width: float
var height: float
var min_value: float
var max_value: float
var fill_color: Color
var background_color: Color
var border_color: Color
var border_width: float


func _ready() -> void:
	_load_config()
	size = Vector2(width, height)


func _load_config() -> void:
	var cfg = ConfigManager.get_config("ui.sensitivity_bar")
	width = cfg.width
	height = cfg.height
	min_value = cfg.min_value
	max_value = cfg.max_value
	current_value = cfg.initial_value
	fill_color = Color(cfg.fill_color.r, cfg.fill_color.g, cfg.fill_color.b)
	background_color = Color(cfg.background_color.r, cfg.background_color.g, cfg.background_color.b)
	border_color = Color(cfg.border_color.r, cfg.border_color.g, cfg.border_color.b)
	border_width = cfg.border_width


func set_sensitivity(value: float) -> void:
	"""Update sensitivity (1.0 - 5.0)"""
	current_value = clampf(value, min_value, max_value)
	queue_redraw()


func get_sensitivity() -> float:
	return current_value


func _draw() -> void:
	# Calculate fill percentage (0.0 to 1.0)
	var fill_ratio = (current_value - min_value) / (max_value - min_value)
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), background_color, true)
	
	# Draw filled portion (left to right)
	var fill_width = width * fill_ratio
	if fill_width > 0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(fill_width, height)), fill_color, true)
	
	# Draw border
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), border_color, false, border_width)
