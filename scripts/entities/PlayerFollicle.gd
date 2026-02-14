## PlayerFollicle - Player-controlled follicle
class_name PlayerFollicle
extends FollicleBase


func _ready() -> void:
	is_player = true
	super._ready()
	_connect_hud()


func _init_controller() -> void:
	controller = PlayerController.new()


func _physics_process(delta: float) -> void:
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
