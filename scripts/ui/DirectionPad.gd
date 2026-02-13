## DirectionPad - Visual representation of directional input (non-functional for now)
class_name DirectionPad
extends Control

# Configuration
var button_size: float
var gap: float
var bg_color: Color
var border_color: Color
var border_width: float

# Buttons layout
var total_width: float
var total_height: float


func _ready() -> void:
	_load_config()
	_calculate_size()


func _load_config() -> void:
	var cfg = ConfigManager.get_config("ui.direction_pad")
	button_size = cfg.button_size
	gap = cfg.gap
	bg_color = Color(cfg.color.r, cfg.color.g, cfg.color.b)
	border_color = Color(cfg.border_color.r, cfg.border_color.g, cfg.border_color.b)
	border_width = cfg.border_width


func _calculate_size() -> void:
	# Layout: 
	#     [UP]
	# [LEFT] [DOWN] [RIGHT]
	# Width = 3 buttons + 2 gaps
	# Height = 2 rows + 1 gap
	total_width = button_size * 3 + gap * 2
	total_height = button_size * 2 + gap
	size = Vector2(total_width, total_height)


func _draw() -> void:
	# UP button (centered top)
	var up_pos = Vector2((total_width - button_size) / 2, 0)
	_draw_button(up_pos, "↑")
	
	# LEFT button (bottom left)
	var left_pos = Vector2(0, button_size + gap)
	_draw_button(left_pos, "←")
	
	# DOWN button (bottom center)
	var down_pos = Vector2((total_width - button_size) / 2, button_size + gap)
	_draw_button(down_pos, "↓")
	
	# RIGHT button (bottom right)
	var right_pos = Vector2(button_size * 2 + gap, button_size + gap)
	_draw_button(right_pos, "→")


func _draw_button(position: Vector2, symbol: String) -> void:
	# Draw background
	draw_rect(Rect2(position, Vector2(button_size, button_size)), bg_color, true)
	
	# Draw border
	draw_rect(Rect2(position, Vector2(button_size, button_size)), border_color, false, border_width)
	
	# Draw symbol (centered)
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	var text_size = font.get_string_size(symbol, 0, -1, font_size)
	var text_pos = position + (Vector2(button_size, button_size) - text_size) / 2
	draw_string(font, text_pos, symbol, 0, -1, font_size, Color.WHITE)
