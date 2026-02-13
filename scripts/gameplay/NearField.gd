extends Node2D

var rect: Rect2
var background_color: Color
var border_color: Color
var border_width: float


func _ready() -> void:
	var arena = ConfigManager.get_config("world.arena")
	rect = Rect2(
		Vector2(arena.position_x, arena.position_y),
		Vector2(arena.width, arena.height)
	)
	background_color = _to_color(arena.background_color)
	border_color = _to_color(arena.border_color)
	border_width = arena.border_width


func _to_color(data: Dictionary) -> Color:
	return Color(data.r, data.g, data.b)

func _draw() -> void:
	draw_rect(rect, background_color, true)
	draw_rect(rect, border_color, false, border_width)


func _process(_delta: float) -> void:
	queue_redraw()
