extends Node2D
var rules: Node


func _process(_delta):
	queue_redraw()


func spr(name: String, frame: int, at: Vector2, alpha := 1.0):
	var tex = GM.sprite_texture(name, frame)
	if tex != null:
		var meta = GM.sprite_meta(name)
		draw_texture(tex, at - Vector2(meta.xorigin, meta.yorigin), Color(1, 1, 1, alpha))


func _draw():
	if not is_instance_valid(rules) or not is_instance_valid(Globals.player):
		return
	var p = Globals.player
	var cam = Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		cam = c.render_origin
		break
