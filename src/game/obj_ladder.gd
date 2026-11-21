extends GMNode
## Port of obj_dotdotdot_shitladder — the broken ladders on "...".
## Step_0: while either of the player's WALL sensors overlaps the ladder,
## clamp the player's speed to 7 (maxHSpeed/xspd/gspd).
## Draw_72: halve the walk animation speed while standing on it.

var coll := false


func _gm_step() -> void:
	coll = false
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		return
	if (
		position_meeting(player._sens_L_x, player._sens_L_y)
		or position_meeting(player._sens_R_x, player._sens_R_y)
	):
		coll = true
		if not player.isSlow:
			if player.xspd > 7:
				player.xspd = 7
				player.gspd = 7
			if player.xspd < -7:
				player.xspd = -7
				player.gspd = -7
			player.maxHSpeed = 7
		# Draw_72 — slow the walk animation while on the ladder
		if player.state == player.WALK:
			player.image_speed /= 2.5


func _gm_draw() -> void:
	pass  # original Draw_0 is empty — the stretched spr_merfurmu2 never draws
	if OS.get_environment("SHOW_LADDERS") == "1":
		var r := bbox_rect()
		draw_rect(r, Color(1, 0, 1, 0.35))
		draw_rect(r, Color(1, 0, 1, 0.9), false, 1.0)
