## StageManager - Handles stage rules and death outcomes
extends Node

var stage_cfg: Dictionary = {}
var death_screen: CanvasLayer = null
var awaiting_restart: bool = false
var current_stage: String = "2_0"


func _ready() -> void:
	stage_cfg = ConfigManager.get_config("world.stage")
	current_stage = stage_cfg.current
	if FollicleManager:
		FollicleManager.follicle_registered.connect(_on_follicle_registered)
		_connect_existing_follicles()


func _connect_existing_follicles() -> void:
	for follicle in FollicleManager.get_all_follicles():
		_on_follicle_registered(follicle)


func _on_follicle_registered(follicle: Node) -> void:
	if follicle == null:
		return
	if follicle.has_signal("died"):
		follicle.died.connect(_on_follicle_died.bind(follicle))
	if follicle.has_signal("lh_receptor_acquired"):
		follicle.lh_receptor_acquired.connect(_on_lh_receptor_acquired)


func _on_follicle_died(follicle: Node) -> void:
	if follicle == null:
		return
	if follicle.has_method("get") and follicle.get("is_player"):
		_show_death_screen()
		return
	
	# NPC died, remove from scene
	follicle.queue_free()
	
	# Check for stage 2.1 -> 2.2 transition after this frame
	# (ensures queue_free has taken effect)
	if current_stage == "2_1":
		call_deferred("_check_npc_extinction")


func _show_death_screen() -> void:
	# Pause the game tree
	get_tree().paused = true
	awaiting_restart = true
	
	# Create death screen overlay
	death_screen = CanvasLayer.new()
	death_screen.layer = 200
	death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(death_screen)
	
	# Create dark overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.add_child(overlay)
	
	# Create death message
	var message: Label = Label.new()
	message.text = "YOU DIED"
	message.add_theme_font_size_override("font_size", 72)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.set_anchors_preset(Control.PRESET_CENTER)
	message.offset_top = -100
	message.offset_bottom = -50
	message.offset_left = -300
	message.offset_right = 300
	death_screen.add_child(message)
	
	# Create continue prompt
	var prompt: Label = Label.new()
	prompt.text = "Press Any Key to Continue"
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.offset_top = 50
	prompt.offset_bottom = 100
	prompt.offset_left = -300
	prompt.offset_right = 300
	death_screen.add_child(prompt)


func _input(event: InputEvent) -> void:
	if awaiting_restart and event is InputEventKey and event.pressed:
		_restart_level()


func _restart_level() -> void:
	awaiting_restart = false
	if death_screen:
		death_screen.queue_free()
		death_screen = null
	get_tree().paused = false
	get_tree().reload_current_scene()


## Stage transition: 2.0 -> 2.1 when player acquires first LH receptor
func _on_lh_receptor_acquired(follicle: Node, count: int) -> void:
	if follicle == null:
		return
	# Only trigger on player's first receptor
	if follicle.has_method("get") and follicle.get("is_player"):
		if count == 1 and current_stage == "2_0":
			_transition_to_stage("2_1")


## Stage transition: 2.1 -> 2.2 when all NPCs are dead
func _check_npc_extinction() -> void:
	if not FollicleManager:
		return
	
	var npc_count = 0
	for follicle in FollicleManager.get_all_follicles():
		if follicle and follicle.has_method("get") and not follicle.get("is_player"):
			if not follicle.get("is_dead"):
				npc_count += 1
	
	if npc_count == 0:
		_transition_to_stage("2_2")


## Perform stage transition
func _transition_to_stage(new_stage: String) -> void:
	if current_stage == new_stage:
		return
	
	print("[StageManager] Stage transition: %s -> %s" % [current_stage, new_stage])
	current_stage = new_stage
	stage_cfg.current = new_stage
	
	# Update config reference so all systems see the new stage
	var full_stage_cfg = ConfigManager.get_config("world.stage")
	full_stage_cfg.current = new_stage
