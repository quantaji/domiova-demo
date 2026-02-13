## FollicleManager - Global tracker for all follicles
extends Node

var follicles: Array[Node] = []


func register_follicle(follicle: Node) -> void:
	if follicle not in follicles:
		follicles.append(follicle)


func unregister_follicle(follicle: Node) -> void:
	if follicle in follicles:
		follicles.erase(follicle)


func get_all_follicles() -> Array[Node]:
	return follicles
