## SkillPanel - Display 3 skill buttons (1, 2, 3)
class_name SkillPanel
extends Control

# Configuration
var button_size: float
var gap: float
var spacing_above: float
var bg_color: Color
var border_color: Color
var border_width: float
var text_color: Color

var total_width: float
var total_height: float


func _ready() -> void:
	_load_config()
	_calculate_size()


func _load_config() -> void:
	var cfg = ConfigManager.get_config("ui.skill_panel")
	button_size = cfg.button_size
	gap = cfg.gap
	spacing_above = cfg.spacing_above_direction
	bg_color = Color(cfg.color.r, cfg.color.g, cfg.color.b)
	border_color = Color(cfg.border_color.r, cfg.border_color.g, cfg.border_color.b)
	border_width = cfg.border_width
	text_color = Color(cfg.text_color.r, cfg.text_color.g, cfg.text_color.b)


func _calculate_size() -> void:
	# Layout: 3 buttons HORIZONTALLY
	# Width = 3 buttons + 2 gaps
	# Height = 1 button
	total_width = button_size * 3 + gap * 2
	total_height = button_size
	size = Vector2(total_width, total_height)


func _draw() -> void:
	# Skill 1 button
	var skill1_pos = Vector2(0, 0)
	_draw_skill_button(skill1_pos, "1")
	
	# Skill 2 button
	var skill2_pos = Vector2(button_size + gap, 0)
	_draw_skill_button(skill2_pos, "2")
	
	# Skill 3 button
	var skill3_pos = Vector2((button_size + gap) * 2, 0)
	_draw_skill_button(skill3_pos, "3")


func _draw_skill_button(position: Vector2, skill_number: String) -> void:
	# Draw background
	draw_rect(Rect2(position, Vector2(button_size, button_size)), bg_color, true)
	
	# Draw border
	draw_rect(Rect2(position, Vector2(button_size, button_size)), border_color, false, border_width)
	
	# Draw skill number (centered)
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	var text_size = font.get_string_size(skill_number, 0, -1, font_size)
	var text_pos = position + (Vector2(button_size, button_size) - text_size) / 2
	draw_string(font, text_pos, skill_number, 0, -1, font_size, text_color)
