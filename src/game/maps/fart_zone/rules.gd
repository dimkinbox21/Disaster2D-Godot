extends "res://src/game/maps/shared/rules.gd"
## Fart Zone: presentation and network effects.
var dummy_ready = 0
var potatoes: Dictionary = {}
var loss_ticks = 0
var ball = 0.0
var ball_dir = -1.0


func _ready():
	process_physics_priority = 60
	z_index = 1
	for n in GMNode.all_of("obj_fart_mermer") + GMNode.all_of("obj_darktower_ball"):
		n.set_meta("practice_origin", n.position)
	for spawner in GMNode.all_of("obj_blackring_spawner"):
		spawner.gm_visible = false


func dummy_position(at: Vector2):
	for n in GMNode.all_of("obj_fart_dummy"):
		n.position = at
		n.queue_redraw()


func potato_packet(action: int, id: int, seconds: int):
	if action == 1:
		if id == Net.nid and int(potatoes.get(id, 60)) <= 1:
			loss_ticks = 30
			GameAudio.play_sound("snd_boom")
		potatoes.erase(id)
	else:
		potatoes[id] = seconds * 60


func text_at(at: Vector2, text: String):
	var n = load("res://src/game/maps/practice_float.gd").new()
	n.position = at
	n.text = text
	map.add_child(n)


func push_dummy(dummy: GMNode, p: GMNode, amount: int, text: String):
	var b = Net.cpacket_tcp(Net.PacketType.CLIENT_FART_PUSH)
	b.put_8(amount)
	Net.send_server_tcp(b)
	GameAudio.play_sound(["snd_dummy", "snd_dummy2", "snd_dummy3"].pick_random())
	text_at(dummy.position - Vector2(0, 32), text)
	dummy_ready = 20


func _physics_process(_dt):
	frame += 1
	dummy_ready = maxi(0, dummy_ready - 1)
	if loss_ticks > 0:
		loss_ticks -= 1
	var p = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		return
	for n in GMNode.all_of("obj_fart_mermer"):
		var at: Vector2 = n.get_meta("practice_origin", n.position)
		n.position = at + Vector2(randf_range(-3, 3), randf_range(-3, 3))
		n.queue_redraw()
		if n.bbox_rect().intersects(p.bbox_rect()) and not potatoes.has(Net.nid):
			var b = Net.cpacket_tcp(Net.PacketType.CLIENT_PLAYER_POTATER)
			b.put_u8(0)
			b.put_u16(Net.nid)
			b.put_u8(4)
			Net.send_server_tcp(b)
	ball = clampf(ball + .015 * ball_dir, -1, 1)
	if absf(ball) >= 1:
		ball_dir = -ball_dir
	for hazard in GMNode.all_of("obj_darktower_ball"):
		var start: Vector2 = hazard.get_meta("practice_origin", hazard.position)
		hazard.position.y = (
			start.y
			+ (
				ball
				* float(hazard.properties.get("dir", 1))
				* float(hazard.properties.get("dist", 100))
			)
		)
		hazard.queue_redraw()
	for id in potatoes.keys():
		potatoes[id] = maxi(0, int(potatoes[id]) - 1)
		var owner = p if id == Net.nid else null
		for puppet in GMNode.all_of("obj_player_puppet"):
			if puppet.master_id == id:
				owner = puppet
		if owner != null:
			owner.sprite_name = "spr_merfurmu"
			owner.image_index = 0
			owner.queue_redraw()
		if id == Net.nid:
			if potatoes[id] <= 210:
				for puppet in GMNode.all_of("obj_player_puppet"):
					if p.bbox_rect().intersects(puppet.bbox_rect()):
						var b = Net.cpacket_tcp(Net.PacketType.CLIENT_PLAYER_POTATER)
						b.put_u8(0)
						b.put_u16(puppet.master_id)
						b.put_u8(4)
						Net.send_server_tcp(b)
			if potatoes[id] % 60 == 0:
				GameAudio.play_sound("snd_roar")
	for dummy in GMNode.all_of("obj_fart_dummy"):
		dummy.image_index = 0 if Globals.character == 0 or p.revivalTimes >= 2 else 1
		dummy.queue_redraw()
		if dummy_ready > 0:
			continue
		for shot in GMNode.all_of("obj_tails_projectile"):
			if (
				not shot.is_breaking
				and shot.is_owner
				and shot.bbox_rect().intersects(dummy.bbox_rect())
			):
				push_dummy(
					dummy,
					p,
					int(signf(dummy.position.x - shot.position.x) * shot.charge),
					("-%d" if shot.is_exe else "+%ds") % shot.dmg
				)
				shot._destroy()
				break
		if dummy_ready > 0 or not p.bbox_rect().intersects(dummy.bbox_rect()):
			continue
		var evil = Globals.character == 0 or p.revivalTimes >= 2
		var ball = (
			evil and p.state in [p.JUMP, p.FALL, p.SPIN] and Globals.character not in [3, 4, 6]
		)
		if p.isAttacking or ball:
			var strength = (
				3
				if ball
				else (
					6
					if Globals.character == 0 and Globals.exeCharacter != 1
					else 4 if Globals.character in [2, 4] and not evil else 3
				)
			)
			push_dummy(
				dummy,
				p,
				int(p.image_xscale * strength),
				(
					"-2"
					if Globals.character == 0 and Globals.exeCharacter != 1 and not ball
					else "-1" if evil else "+3s" if Globals.character in [2, 4] else "+2s"
				)
			)
	queue_redraw()


func _draw():
	for dummy in GMNode.all_of("obj_fart_dummy"):
		GM.scr_text_spr(self, dummy.position.x - 24, dummy.position.y - 50, "\\im @dumb~")
	for id in potatoes:
		var owner = Globals.player if id == Net.nid else null
		for puppet in GMNode.all_of("obj_player_puppet"):
			if puppet.master_id == id:
				owner = puppet
		if is_instance_valid(owner):
			var tex = GM.sprite_texture("spr_goodperson", int(potatoes[id]) / 60)
			if tex != null:
				draw_texture(
					tex,
					(
						to_local(owner.position)
						- Vector2(
							GM.sprite_meta("spr_goodperson").xorigin,
							GM.sprite_meta("spr_goodperson").yorigin
						)
					)
				)
