## FollicleManager - Global tracker for all follicles
extends Node

signal follicle_registered(follicle: Node)
signal follicle_unregistered(follicle: Node)

var follicles: Array[Node] = []


func register_follicle(follicle: Node) -> void:
	if follicle not in follicles:
		follicles.append(follicle)
		follicle_registered.emit(follicle)


func unregister_follicle(follicle: Node) -> void:
	if follicle in follicles:
		follicles.erase(follicle)
		follicle_unregistered.emit(follicle)


func get_all_follicles() -> Array[Node]:
	return follicles
