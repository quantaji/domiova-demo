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
	
	# Initialize follicle layout from config in Stage 1
	var stage_cfg = ConfigManager.get_config("world.stage")
	if stage_cfg.get("current", "2_0") == "1":
		_apply_follicle_layout()


func _apply_follicle_layout() -> void:
	var layout = ConfigManager.get_config("world.follicle_layout")
	var entities = $Entities
	if not entities:
		print("[NearField] ERROR: Entities node not found!")
		return
	
	# Apply player position
	var player = entities.get_node_or_null("PlayerFollicle")
	if player:
		var player_pos = Vector2(layout.player.position_x, layout.player.position_y)
		player.global_position = player_pos
		player.set_initial_position(player_pos)
		print("[NearField] Player positioned at: (%f, %f)" % [player.global_position.x, player.global_position.y])
	
	# Apply NPC positions
	var npc_configs = layout.npcs
	for i in range(npc_configs.size()):
		var npc_node_name = "NPCFollicle%d" % (i + 1)
		var npc = entities.get_node_or_null(npc_node_name)
		if npc and i < npc_configs.size():
			var npc_cfg = npc_configs[i]
			var npc_pos = Vector2(npc_cfg.position_x, npc_cfg.position_y)
			npc.global_position = npc_pos
			npc.set_initial_position(npc_pos)
			print("[NearField] %s positioned at: (%f, %f)" % [npc_node_name, npc.global_position.x, npc.global_position.y])


func _to_color(data: Dictionary) -> Color:
	return Color(data.r, data.g, data.b)

func _draw() -> void:
	draw_rect(rect, background_color, true)
	draw_rect(rect, border_color, false, border_width)


func _process(_delta: float) -> void:
	queue_redraw()
