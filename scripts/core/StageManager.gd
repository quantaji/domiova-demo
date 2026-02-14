## StageManager - Handles stage rules and death outcomes
extends Node

var stage_cfg: Dictionary = {}
var death_screen: CanvasLayer = null
var awaiting_restart: bool = false
var current_stage: String = "2_0"

# Stage 3 victory tracking
var stage3_timer: float = 0.0
var stage3_duration: float = 20.0
var stage3_active: bool = false
var victory_shown: bool = false


func _ready() -> void:
	stage_cfg = ConfigManager.get_config("world.stage")
	current_stage = stage_cfg.current
	if FollicleManager:
		FollicleManager.follicle_registered.connect(_on_follicle_registered)
		# Defer connection to ensure all follicles are registered
		call_deferred("_connect_existing_follicles")


func _process(delta: float) -> void:
	if stage3_active and not victory_shown:
		stage3_timer += delta
		if stage3_timer >= stage3_duration:
			_show_victory_screen()


func _connect_existing_follicles() -> void:
	var count = 0
	for follicle in FollicleManager.get_all_follicles():
		_on_follicle_registered(follicle)
		count += 1
	print("[StageManager] Connected to %d existing follicles" % count)


func _on_follicle_registered(follicle: Node) -> void:
	if follicle == null:
		return
	var is_player = follicle.get("is_player") if follicle.has_method("get") else "unknown"
	print("[StageManager] Registering follicle: is_player=%s" % is_player)
	if follicle.has_signal("died"):
		# Signal emits (follicle), so handler receives it directly
		follicle.died.connect(_on_follicle_died)
		print("[StageManager]   - died signal connected")
	else:
		print("[StageManager]   - WARNING: No died signal found!")
	if follicle.has_signal("lh_receptor_acquired"):
		follicle.lh_receptor_acquired.connect(_on_lh_receptor_acquired)
		print("[StageManager]   - lh_receptor_acquired signal connected")
	else:
		print("[StageManager]   - WARNING: No lh_receptor_acquired signal found!")


func _on_follicle_died(follicle: Node) -> void:
	print("[StageManager] _on_follicle_died called for: %s" % (follicle.name if follicle else "null"))
	if follicle == null:
		print("[StageManager] Follicle is null!")
		return
	var is_player = follicle.get("is_player") if follicle.has_method("get") else false
	print("[StageManager] Follicle %s died (is_player=%s)" % [follicle.name, is_player])
	if follicle.has_method("get") and follicle.get("is_player"):
		print("[StageManager] Player died, showing death screen")
		_show_death_screen()
		return
	
	# NPC died, remove from scene
	print("[StageManager] NPC %s died, calling queue_free()" % follicle.name)
	follicle.queue_free()
	
	# Check for stage 2.1 -> 2.2 transition after this frame
	# (ensures queue_free has taken effect)
	if current_stage == "2_1":
		print("[StageManager] Current stage is 2_1, scheduling NPC extinction check")
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


func _show_victory_screen() -> void:
	victory_shown = true
	print("[StageManager] *** SUCCESS! Stage 3 completed after %.1fs ***" % stage3_timer)
	
	# Pause the game tree
	get_tree().paused = true
	awaiting_restart = true
	
	# Create victory screen overlay
	death_screen = CanvasLayer.new()
	death_screen.layer = 200
	death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(death_screen)
	
	# Create dark overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.add_child(overlay)
	
	# Create success message
	var message: Label = Label.new()
	message.text = "SUCCESS"
	message.add_theme_font_size_override("font_size", 72)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.set_anchors_preset(Control.PRESET_CENTER)
	message.offset_top = -100
	message.offset_bottom = -50
	message.offset_left = -300
	message.offset_right = 300
	message.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))  # Green color
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


## Stage transition: 2.0 -> 2.1 when player acquires first LH receptor
func _on_lh_receptor_acquired(follicle: Node, count: int) -> void:
	if follicle == null:
		return
	# Only trigger on player's first receptor
	if follicle.has_method("get") and follicle.get("is_player"):
		print("[StageManager] Player acquired LH receptor #%d" % count)
		if count == 1 and current_stage == "2_0":
			print("[StageManager] First receptor, triggering 2.0 -> 2.1 transition")
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
	
	print("[StageManager] Checking NPC extinction: %d NPCs alive" % npc_count)
	if npc_count == 0:
		print("[StageManager] All NPCs dead, triggering 2.1 -> 2.2 transition")
		_transition_to_stage("2_2")


## Perform stage transition
func _transition_to_stage(new_stage: String) -> void:
	if current_stage == new_stage:
		return
	
	print("[StageManager] *** STAGE TRANSITION: %s -> %s ***" % [current_stage, new_stage])
	current_stage = new_stage
	stage_cfg.current = new_stage
	
	# Update config reference so all systems see the new stage
	var full_stage_cfg = ConfigManager.get_config("world.stage")
	full_stage_cfg.current = new_stage
	print("[StageManager] Stage config updated. New stage: %s" % full_stage_cfg.current)
	
	# Start victory timer if entering Stage 3
	if new_stage == "3":
		print("[StageManager] Stage 3 started, victory timer begins (%.1fs)" % stage3_duration)
		stage3_active = true
		stage3_timer = 0.0
