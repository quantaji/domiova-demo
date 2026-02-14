## FollicleManager - Global tracker for all follicles
extends Node

signal follicle_registered(follicle: Node)
signal follicle_unregistered(follicle: Node)

var follicles: Array[Node] = []


func register_follicle(follicle: Node) -> void:
	if follicle in follicles:
		print("[FollicleManager] WARNING: Follicle already registered! %s" % follicle.name)
		return
	follicles.append(follicle)
	var is_player = follicle.get("is_player") if follicle.has_method("get") else "unknown"
	print("[FollicleManager] Registered follicle: %s (is_player=%s)" % [follicle.name, is_player])
	follicle_registered.emit(follicle)


func unregister_follicle(follicle: Node) -> void:
	if follicle in follicles:
		follicles.erase(follicle)
		follicle_unregistered.emit(follicle)


func get_all_follicles() -> Array[Node]:
	return follicles
