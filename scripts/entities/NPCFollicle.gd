## NPCFollicle - AI-controlled follicle
class_name NPCFollicle
extends FollicleBase

# AI configuration
var ai_cfg: Dictionary = {}

# Skill cooldowns
var skill_cooldowns: Dictionary = {
	"e2": 0.0,
	"inhibin": 0.0,
	"lh_receptor": 0.0
}


func _ready() -> void:
	is_player = false
	super._ready()
	
	# Load AI configuration
	ai_cfg = ConfigManager.get_config("npc_follicle.ai")


func _init_controller() -> void:
	var arena = ConfigManager.get_config("world.arena")
	var target_distance = ConfigManager.get_config("npc_follicle.movement.target_pickup_distance")
	controller = AIController.new(arena, target_distance)
	
	# Set FarField reference for intelligent target selection
	_setup_far_field_reference()


func _setup_far_field_reference() -> void:
	# Defer until scene tree is ready
	await get_tree().process_frame
	var far_field_nodes = get_tree().get_nodes_in_group("far_field")
	if far_field_nodes.size() > 0 and controller is AIController:
		controller.set_far_field(far_field_nodes[0])


func _physics_process(delta: float) -> void:
	# Update skill cooldowns
	for skill_name in skill_cooldowns:
		if skill_cooldowns[skill_name] > 0.0:
			skill_cooldowns[skill_name] -= delta
	
	# Intelligent skill decision making
	_evaluate_and_use_skills()
	
	# Call parent physics process for normal movement
	super._physics_process(delta)


## Evaluate conditions and use skills strategically
func _evaluate_and_use_skills() -> void:
	# Skill 1: E2 (self-enhancement)
	if _should_use_skill_e2():
		var cost = get_skill_cost(SKILL_E2)
		if spend_energy(cost):
			apply_sensitivity_buff()
			emit_e2()
			skill_cooldowns["e2"] = ai_cfg.skill_cooldown_e2
	
	# Skill 2: Inhibin B (competitive suppression)
	if _should_use_skill_inhibin():
		var cost = get_skill_cost(SKILL_INHIBIN)
		if spend_energy(cost):
			emit_inhibin_b()
			skill_cooldowns["inhibin"] = ai_cfg.skill_cooldown_inhibin
	
	# Skill 3: LH Receptor (maturation)
	if _should_use_skill_lh_receptor():
		var cost = get_skill_cost(SKILL_LH_RECEPTOR)
		if spend_energy(cost):
			if not acquire_lh_receptor():
				# Refund if max already reached
				energy = clampf(energy + cost, 0.0, energy_max)
				energy_changed.emit(energy)
			else:
				skill_cooldowns["lh_receptor"] = ai_cfg.skill_cooldown_lh_receptor


## Should use E2? (Self-enhancement in competitive environment)
func _should_use_skill_e2() -> bool:
	return (
		can_use_skill(SKILL_E2) and
		skill_cooldowns["e2"] <= 0.0 and
		energy >= ai_cfg.skill_e2_energy_threshold and
		_count_alive_rivals() >= ai_cfg.skill_e2_rival_threshold and
		fsh_sensitivity < fsh_sensitivity_max
	)


## Should use Inhibin B? (Aggressive FSH suppression)
func _should_use_skill_inhibin() -> bool:
	return (
		can_use_skill(SKILL_INHIBIN) and
		skill_cooldowns["inhibin"] <= 0.0 and
		energy >= ai_cfg.skill_inhibin_energy_threshold and
		_count_alive_rivals() >= ai_cfg.skill_inhibin_rival_threshold
	)


## Should acquire LH receptor? (Maturation milestone)
func _should_use_skill_lh_receptor() -> bool:
	return (
		can_use_skill(SKILL_LH_RECEPTOR) and
		skill_cooldowns["lh_receptor"] <= 0.0 and
		energy >= ai_cfg.skill_lh_receptor_energy_threshold and
		lh_receptor_count < lh_receptor_config.max_count
	)


## Count living rival follicles
func _count_alive_rivals() -> int:
	var count = 0
	if FollicleManager:
		var all_follicles = FollicleManager.get_all_follicles()
		for f in all_follicles:
			if f != self and not f.is_dead:
				count += 1
	return count

