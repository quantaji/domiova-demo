## PlayerFollicle - Player-controlled follicle
class_name PlayerFollicle
extends FollicleBase


func _ready() -> void:
	is_player = true
	super._ready()
	_connect_hud()


func _init_controller() -> void:
	controller = PlayerController.new()


func _input(event: InputEvent) -> void:
	# Stage 1: Only game control keys trigger awakening detection
	var stage_cfg = ConfigManager.get_config("world.stage")
	var current_stage = stage_cfg.get("current", "2_0")
	
	if current_stage == "1" and event is InputEventKey and event.pressed and not event.echo:
		# Check if the pressed key is one of the valid game controls
		var valid_actions = ["move_up", "move_down", "move_left", "move_right", "skill_1", "skill_2", "skill_3"]
		for action in valid_actions:
			if Input.is_action_just_pressed(action):
				print("[PlayerFollicle] Valid key pressed in Stage 1, calling Stage1Controller")
				# Delegate to Stage1Controller for awakening detection
				if Stage1Controller:
					Stage1Controller.check_awakening_input()
				else:
					print("[PlayerFollicle] ERROR: Stage1Controller not found!")
				return
	elif event is InputEventKey and event.pressed and not event.echo:
		print("[PlayerFollicle] Key pressed but stage=%s, not calling controller" % current_stage)


func _physics_process(delta: float) -> void:
	# In Stage 1, skip skill inputs (follicles are awaiting awakening)
	var stage_cfg = ConfigManager.get_config("world.stage")
	var current_stage = stage_cfg.get("current", "2_0")
	
	if current_stage != "1":
		# Check skill inputs and trigger them before normal physics
		if controller is PlayerController:
			if controller.is_skill_1_pressed():
				var cost = get_skill_cost(SKILL_E2)
				if can_use_skill(SKILL_E2) and spend_energy(cost):
					apply_sensitivity_buff()
					emit_e2()
			if controller.is_skill_2_pressed():
				var cost = get_skill_cost(SKILL_INHIBIN)
				if can_use_skill(SKILL_INHIBIN) and spend_energy(cost):
					emit_inhibin_b()
			if controller.is_skill_3_pressed():
				var cost = get_skill_cost(SKILL_LH_RECEPTOR)
				if can_use_skill(SKILL_LH_RECEPTOR) and spend_energy(cost):
					if not acquire_lh_receptor():
						energy = clampf(energy + cost, 0.0, energy_max)
						energy_changed.emit(energy)
	
	# Call parent physics process for normal movement
	super._physics_process(delta)


func _connect_hud() -> void:
	var hud = _find_hud()
	if hud:
		energy_changed.connect(hud.set_player_energy)
		sensitivity_changed.connect(hud.set_player_sensitivity)
		hud.set_player_energy(int(floor(get_energy())))
		hud.set_player_sensitivity(get_sensitivity())


func _find_hud() -> HUD:
	var nodes = get_tree().get_nodes_in_group("hud")
	if nodes.size() > 0:
		return nodes[0]
	return null
