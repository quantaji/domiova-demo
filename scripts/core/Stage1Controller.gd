extends Node

## Stage1Controller — Awakening detection for Stage 1
##
## Design:
##   1. Player presses a game key while rainbow pellets are near → vibrate.
##   2. If the nearest wave hasn't been recorded yet, record its wave_id.
##   3. recorded_wave_ids is append-only and monotonically increasing.
##   4. After each append, check if the last N entries are consecutive (i, i+1, i+2).
##   5. If yes, wait 3 seconds then transition to Stage 2.0.
##   6. During the 3-second wait, vibration still works.

# ── Configuration ──
var detection_threshold: float
var required_consecutive: int
var min_pellets: int

# ── State ──
var recorded_wave_ids: Array[int] = []
var pending_transition: bool = false

# ── Cached reference (lazy) ──
var far_field: Node2D


func _ready() -> void:
	var cfg = ConfigManager.get_config("world.stage_1.awakening")
	detection_threshold = cfg.detection_threshold
	required_consecutive = cfg.required_successes
	min_pellets = cfg.get("min_pellets_for_detection", 10)
	print("[Stage1] Ready — threshold=%.0fpx, consecutive=%d" % [
		detection_threshold, required_consecutive
	])


## Called by PlayerFollicle._input() when a game key is pressed during Stage 1.
func check_awakening_input() -> void:
	print("[Stage1] check_awakening_input() called")
	print("[Stage1]   recorded_wave_ids = %s" % str(recorded_wave_ids))
	print("[Stage1]   pending_transition = %s" % pending_transition)
	
	if not _ensure_far_field():
		print("[Stage1] ERROR: FarField not available")
		return

	# ── During transition: always vibrate regardless of pellet position ──
	if pending_transition:
		print("[Stage1] Pending transition, vibrating only")
		_vibrate_all()
		return

	# ── Find the nearest wave that has pellets within threshold ──
	var hit_wave_id := _find_nearest_wave()
	print("[Stage1] _find_nearest_wave() returned: %d" % hit_wave_id)
	if hit_wave_id < 0:
		print("[Stage1] No valid wave found")
		return  # No pellets nearby — nothing happens

	# ── Always vibrate when hit ──
	_vibrate_all()

	# ── Record the wave (once per wave_id) ──
	if hit_wave_id in recorded_wave_ids:
		return  # Already recorded; vibration was the only effect

	recorded_wave_ids.append(hit_wave_id)
	print("[Stage1] Recorded wave #%d → history %s" % [
		hit_wave_id, str(recorded_wave_ids)
	])

	if _tail_is_consecutive():
		_begin_transition()


# ─────────────────────────────────────────────────────────────────────
#  Internal helpers
# ─────────────────────────────────────────────────────────────────────

## Scan active pellets, group by wave_id, return the first (newest) wave_id
## that has at least one pellet within detection_threshold of the player.
## Returns -1 isf nothing qualifies.
func _find_nearest_wave() -> int:
	var player := _get_player()
	if not player:
		print("[Stage1] ERROR: Player not found")
		return -1

	var player_pos: Vector2 = player.global_position
	var active = far_field.get_active_pellets()
	print("[Stage1] Active pellets count: %d" % active.size())
	if active.is_empty():
		return -1

	# Group rainbow pellets by wave_id
	var waves: Dictionary = {}
	for p in active:
		var wid: int = p.wave_id
		if wid < 0:
			continue
		if not waves.has(wid):
			waves[wid] = []
		waves[wid].append(p)

	print("[Stage1] Rainbow waves found: %s (total %d waves)" % [str(waves.keys()), waves.size()])

	# Iterate newest → oldest
	var ids := waves.keys()
	ids.sort()
	ids.reverse()

	for wid in ids:
		var pellets: Array = waves[wid]
		print("[Stage1] Checking wave #%d with %d pellets" % [wid, pellets.size()])
		var closest_dist := 99999.0
		# Check distance for any pellet in this wave
		for p in pellets:
			var dist = p.global_position.distance_to(player_pos)
			if dist < closest_dist:
				closest_dist = dist
			if dist < detection_threshold:
				print("[Stage1] Wave #%d HIT! Distance=%.1f < threshold=%.1f" % [wid, dist, detection_threshold])
				return wid
		print("[Stage1] Wave #%d closest pellet: %.1fpx (threshold=%.1f)" % [wid, closest_dist, detection_threshold])

	return -1


## Check whether the last `required_consecutive` entries in recorded_wave_ids
## form a consecutive sequence (e.g. [5, 6, 7] for required=3).
## Since the array is append-only and monotonically increasing, any new
## consecutive run must end at the last element — only the tail matters.
func _tail_is_consecutive() -> bool:
	var n := recorded_wave_ids.size()
	if n < required_consecutive:
		return false
	var start := n - required_consecutive
	for i in range(start + 1, n):
		if recorded_wave_ids[i] != recorded_wave_ids[i - 1] + 1:
			return false
	return true


## Wait 3 seconds, then transition to Stage 2.0.
func _begin_transition() -> void:
	if pending_transition:
		return
	pending_transition = true
	print("[Stage1] ★ %d consecutive waves! Stage 2.0 in 3 seconds..." % required_consecutive)

	await get_tree().create_timer(3.0).timeout

	# Guard: only transition if still in Stage 1
	if ConfigManager.get_config("world.stage").get("current", "2_0") == "1":
		if StageManager:
			StageManager._transition_to_stage("2_0")
		else:
			print("[Stage1] ERROR: StageManager not found")


## Vibrate every registered follicle.
func _vibrate_all() -> void:
	for f in FollicleManager.get_all_follicles():
		if f and f.has_method("vibrate"):
			f.vibrate()


## Get player follicle.
func _get_player() -> Node:
	for f in FollicleManager.get_all_follicles():
		if f.is_player:
			return f
	return null


## Lazy-initialize FarField reference.
func _ensure_far_field() -> bool:
	if far_field:
		return true
	var nodes := get_tree().get_nodes_in_group("far_field")
	if nodes.size() > 0:
		far_field = nodes[0]
		return true
	print("[Stage1] ERROR: FarField not found")
	return false


## Reset state (called by StageManager when leaving Stage 1).
func reset() -> void:
	recorded_wave_ids.clear()
	pending_transition = false
	print("[Stage1] State reset")
