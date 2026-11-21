extends Node2D
var rules: Node


func _process(_delta):
	queue_redraw()


func _draw():
	if not is_instance_valid(rules):
		return
