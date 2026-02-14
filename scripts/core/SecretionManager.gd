## SecretionManager - Manages E2 and Inhibin B object pools
## Handles activation, pooling, and recycling of secretion particles
extends Node

# Object pools (independent for each secretion type)
var e2_pool: Array[Secretion] = []
var inhibin_b_pool: Array[Secretion] = []
var active_secretions: Array[Secretion] = []

# Configuration
var e2_config: Dictionary
var inhibin_b_config: Dictionary
var near_field_rect: Rect2
var pituitary_position: Vector2
var pituitary_radius: float
var far_field_node: Node = null


func _ready() -> void:
	_load_config()
	_initialize_pools()
	far_field_node = _find_far_field()


## Load configuration from ConfigManager
func _load_config() -> void:
	var world_cfg = ConfigManager.get_config("world")
	var arena_cfg = world_cfg.arena
	
	# Near field boundary
	near_field_rect = Rect2(
		Vector2(arena_cfg.position_x, arena_cfg.position_y),
		Vector2(arena_cfg.width, arena_cfg.height)
	)
	
	# Far field (pituitary)
	var far_field_cfg = world_cfg.far_field
	pituitary_position = Vector2(far_field_cfg.position_x, far_field_cfg.position_y)
	pituitary_radius = far_field_cfg.pituitary_radius
	
	# Secretion types
	var secretion_cfg = world_cfg.secretion
	e2_config = secretion_cfg.e2
	inhibin_b_config = secretion_cfg.inhibin_b


## Initialize object pools for E2 and Inhibin B
func _initialize_pools() -> void:
	# Initialize E2 pool
	_expand_pool(Secretion.SecretionType.E2, e2_config.pool_size)
	
	# Initialize Inhibin B pool
	_expand_pool(Secretion.SecretionType.INHIBIN_B, inhibin_b_config.pool_size)


## Expand a specific pool by count
func _expand_pool(p_type: Secretion.SecretionType, p_count: int) -> void:
	var pool: Array[Secretion]
	
	if p_type == Secretion.SecretionType.E2:
		pool = e2_pool
	else:
		pool = inhibin_b_pool
	
	for i in range(p_count):
		var secretion: Secretion = Secretion.new()
		secretion.name = "%s_%d" % [_get_type_name(p_type), pool.size() + i]
		add_child(secretion)
		pool.append(secretion)
		
		# Connect recycling signal
		secretion.secretion_recycled.connect(_on_secretion_recycled.bind(secretion, p_type))
		secretion.reached_pituitary.connect(_on_secretion_reached_pituitary.bind(p_type))


func _find_far_field() -> Node:
	var nodes = get_tree().get_nodes_in_group("far_field")
	if nodes.size() > 0:
		return nodes[0]
	return null


func _on_secretion_reached_pituitary(_secretion: Secretion, p_type: Secretion.SecretionType) -> void:
	if far_field_node == null:
		far_field_node = _find_far_field()
	if far_field_node == null:
		print("[SecretionManager] ERROR: Cannot find far_field node!")
		return
	if p_type == Secretion.SecretionType.E2:
		print("[SecretionManager] E2 reached pituitary, calling apply_e2_feedback()")
		far_field_node.apply_e2_feedback()
	else:
		print("[SecretionManager] Inhibin B reached pituitary, calling apply_inhibin_feedback()")
		far_field_node.apply_inhibin_feedback()


## Get a secretion particle from pool (or expand if needed)
func _get_from_pool(p_type: Secretion.SecretionType) -> Secretion:
	var pool: Array[Secretion]
	var config: Dictionary
	var expand_size: int
	
	if p_type == Secretion.SecretionType.E2:
		pool = e2_pool
		config = e2_config
		expand_size = config.pool_expand_size
	else:
		pool = inhibin_b_pool
		config = inhibin_b_config
		expand_size = config.pool_expand_size
	
	# Expand pool if depleted
	if pool.is_empty():
		_expand_pool(p_type, expand_size)
	
	# Pop from pool
	var secretion = pool.pop_back()
	active_secretions.append(secretion)
	return secretion


## Emit E2 from a follicle at given position (emits multiple particles in circular pattern)
func emit_e2(from_position: Vector2) -> void:
	var count = e2_config.emission_count
	for i in range(count):
		var angle = TAU * i / count  # Evenly distribute around 360 degrees
		var direction = Vector2(cos(angle), sin(angle))
		var secretion = _get_from_pool(Secretion.SecretionType.E2)
		secretion.activate(
			Secretion.SecretionType.E2,
			from_position,
			direction,
			e2_config,
			near_field_rect,
			pituitary_position,
			pituitary_radius
		)


## Emit Inhibin B from a follicle at given position (emits multiple particles in circular pattern)
func emit_inhibin_b(from_position: Vector2) -> void:
	var count = inhibin_b_config.emission_count
	for i in range(count):
		var angle = TAU * i / count  # Evenly distribute around 360 degrees
		var direction = Vector2(cos(angle), sin(angle))
		var secretion = _get_from_pool(Secretion.SecretionType.INHIBIN_B)
		secretion.activate(
			Secretion.SecretionType.INHIBIN_B,
			from_position,
			direction,
			inhibin_b_config,
			near_field_rect,
			pituitary_position,
			pituitary_radius
		)


## Recycle secretion back to pool
func _on_secretion_recycled(secretion: Secretion, p_type: Secretion.SecretionType) -> void:
	active_secretions.erase(secretion)
	
	if p_type == Secretion.SecretionType.E2:
		e2_pool.append(secretion)
	else:
		inhibin_b_pool.append(secretion)


## Get type name for debugging
func _get_type_name(p_type: Secretion.SecretionType) -> String:
	match p_type:
		Secretion.SecretionType.E2:
			return "E2"
		Secretion.SecretionType.INHIBIN_B:
			return "InhibinB"
		_:
			return "Unknown"


## Get debug info
func get_pool_stats() -> Dictionary:
	return {
		"e2_available": e2_pool.size(),
		"e2_active": active_secretions.filter(func(s): return s.secretion_type == Secretion.SecretionType.E2).size(),
		"inhibin_b_available": inhibin_b_pool.size(),
		"inhibin_b_active": active_secretions.filter(func(s): return s.secretion_type == Secretion.SecretionType.INHIBIN_B).size()
	}
