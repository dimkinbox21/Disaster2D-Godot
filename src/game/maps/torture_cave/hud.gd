extends Node2D
var rules: Node


func _process(_dt):
	queue_redraw()


func _draw():
	if not is_instance_valid(rules):
		return
	if rules.flash > 0:
		draw_rect(Rect2(0, 0, 480, 270), Color(1, 1, 1, rules.flash))
	for face in GMNode.all_of("obj_abandon_mine"):
		var texture := GM.sprite_texture(face.sprite_name, int(face.image_index))
		if texture != null:
			draw_texture(texture, face.position, Color(1, 1, 1, face.image_alpha))
