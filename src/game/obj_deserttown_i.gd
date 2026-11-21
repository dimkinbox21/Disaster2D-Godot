extends GMNode
## Port of obj_deserttown_i — building/sandstorm controller.
## When the player (or the camera centre, while dead) is inside an
## obj_deserttown_trigger zone, value ramps 0→1 and:
##   - obj_tile chunks at depth -400 (front walls + exterior) fade OUT
##   - obj_tile chunks at depth -300 (interior art) fade IN
##   - the "TilesBalls" fog background layer fades OUT (layer_background_alpha)

var value := 0.0
var show := true
var coll := false
var _fog: Node = null


func _gm_step() -> void:
	coll = false
	var cam: GMNode = null
	for c in GMNode.all_of("obj_camera"):
		cam = c
		break
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break

	if player and (player.hp > 0 or player.revivalTimes >= 2) and not Net.gameEnds:
		for tr in GMNode.all_of("obj_deserttown_trigger"):
			if tr.position_meeting(player.position.x, player.position.y):
				coll = true
				break
	elif cam:
		for tr in GMNode.all_of("obj_deserttown_trigger"):
			if tr.position_meeting(cam.position.x + 240, cam.position.y + 135):
				coll = true
				break

	if coll:
		if value < 1:
			value += 0.1
	else:
		if value > 0:
			value -= 0.1
	var v := value
	for t in GMNode.all_of("gm_tile"):
		if t.depth == -300:
			if t.image_alpha != v:
				t.image_alpha = v
				t.queue_redraw()  # static node: physics loop is off
		elif t.depth == -400:
			var a2 := 1.0 - v
			if t.image_alpha != a2:
				t.image_alpha = a2
				t.queue_redraw()
	if _fog == null:
		_fog = get_tree().current_scene.find_child("TilesBalls", true, false)
		if _fog != null:
			# The original's TilesBalls layer and the scr_level_split(…, -400) wall
			# chunks share depth -400. In the original the fog draws in FRONT of
			# them; with Godot's equal-z_index tree order the fog (earlier in the
			# .tscn) came out behind — pull it one depth step lower so it covers
			# the fading walls (the interior chunks at -300 stay behind it).
			_fog.depth = -401
			_fog.z_index = -_fog.depth
	if _fog != null and "layer_colour" in _fog:
		_fog.layer_colour.a = 1.0 - v


func _gm_draw() -> void:
	pass
