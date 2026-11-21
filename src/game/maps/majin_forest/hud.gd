extends Node2D
var rules: Node


func _process(_dt):
	queue_redraw()


func _draw():
	if not is_instance_valid(rules):
		return
