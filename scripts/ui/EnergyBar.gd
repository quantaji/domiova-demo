## EnergyBar - Display 12-segment energy indicator
class_name EnergyBar
extends Control

var current_energy: int = 0
var max_segments: int = 12

# Configuration
var segment_width: float
var segment_height: float
var gap: float
var bar_width: float
var bar_height: float
var segment_color: Color
var background_color: Color
var border_color: Color
var border_width: float


func _ready() -> void:
	_load_config()
	size = Vector2(bar_width, bar_height)
	set_current_energy(6)  # Default to 6/12 for demo


func _load_config() -> void:
	var cfg = ConfigManager.get_config("ui.energy_bar")
	max_segments = cfg.max_segments
	segment_width = cfg.segment_width
	segment_height = cfg.segment_height
	gap = cfg.gap
	bar_width = cfg.bar_width
	bar_height = cfg.bar_height
	segment_color = Color(cfg.segment_color.r, cfg.segment_color.g, cfg.segment_color.b)
	background_color = Color(cfg.background_color.r, cfg.background_color.g, cfg.background_color.b)
	border_color = Color(cfg.border_color.r, cfg.border_color.g, cfg.border_color.b)
	border_width = cfg.border_width


func set_current_energy(value: int) -> void:
	"""Update energy display (0-12)"""
	current_energy = clampi(value, 0, max_segments)
	queue_redraw()


func get_current_energy() -> int:
	return current_energy


func _draw() -> void:
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width, bar_height)), background_color, true)
	
	# Draw border
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width, bar_height)), border_color, false, border_width)
	
	# Calculate spacing to center segments
	var total_segment_width = max_segments * segment_width + (max_segments - 1) * gap
	var start_x = (bar_width - total_segment_width) / 2.0
	var start_y = (bar_height - segment_height) / 2.0
	
	# Draw filled and empty segments
	for i in range(max_segments):
		var pos_x = start_x + i * (segment_width + gap)
		var pos_y = start_y
		var segment_rect = Rect2(Vector2(pos_x, pos_y), Vector2(segment_width, segment_height))
		
		# Draw filled segment if within current energy
		if i < current_energy:
			draw_rect(segment_rect, segment_color, true)
		else:
			# Draw border only for empty segments
			draw_rect(segment_rect, border_color, false, 1.0)
