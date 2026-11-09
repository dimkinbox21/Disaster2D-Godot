extends GMNode
## Port of obj_deathtp — dead-player teleport pads.

func _gm_step() -> void:
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		return
	if player.state != 6:  # DEAD
		return
	if player.hp > 0:
		return
	if position_meeting(player.position.x, player.position.y):
		var nearest: GMNode = null
		var best := 1e18
		for d in GMNode.all_of("obj_deathtp_point"):
			var dist: float = d.position.distance_squared_to(player.position)
			if dist < best:
				best = dist
				nearest = d
		if nearest:
			player.position = nearest.position + Vector2(0, -2)
			player.gspd = 0
			player.xspd = 0
			player.yspd = 0

func _gm_draw() -> void:
	draw_self()
