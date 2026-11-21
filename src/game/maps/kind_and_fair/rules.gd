extends "res://src/game/maps/shared/rules.gd"
## Kind and Fair: presentation and network effects.
var tick := 0
var particles: Array = []


func _ready():
	process_physics_priority = 60
	z_index = 200


func effect(sprite: String, at: Vector2, motion := Vector2.ZERO):
	var debris := sprite.ends_with("_part")
	var fx = (
		load("res://src/game/maps/debris.gd" if debris else "res://src/game/obj_quickfx.gd").new()
	)
	fx.sprite_name = sprite
	fx.position = at
	fx.motion = motion
	if debris:
		fx.image_index = randi_range(0, GM.sprite_count(sprite) - 1)
		fx.image_speed = 0
	else:
		fx.fade = false
	map.add_child(fx)


func monitor(state: int, id: int, owner: int):
	for node in GMNode.all_of("obj_kaf_speedboobster"):
		if int(node.properties.get("nid", 0)) != id:
			continue
		node.properties.broken = state == 2
		node.image_index = int(state == 2)
		node.image_speed = 0
		node.queue_redraw()
		if state == 2:
			GameAudio.play_sound_at("snd_break", node.position)
			effect("spr_explosion", node.position + Vector2(15, 15))
			if owner == Net.nid and is_instance_valid(Globals.player):
				Globals.player.isBoosting = true
				Globals.player.isSpinning = false
				Globals.player.isJumping = false


func request(type: int, id: int, ray := false):
	var packet := Net.cpacket_tcp(type)
	packet.put_u8(id)
	if type == Net.PacketType.CLIENT_KAFMONITOR_ACTIVATE:
		packet.put_u8(int(ray))
	Net.send_server_tcp(packet)


func _physics_process(_dt):
	tick += 1
	flash = maxf(0, flash - 0.016)
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		return
	for node in GMNode.all_of("obj_kaf_speedboobster"):
		if node.properties.get("broken", false) or node.properties.get("pending", 0) > tick:
			continue
		var shot := false
		for ray in GMNode.all_of("obj_tails_projectile"):
			if ray.is_owner and node.bbox_rect().intersects(ray.bbox_rect()):
				shot = true
		var can_hit: bool = (
			p.isAttacking
			or p.isJumping
			or p.isSpinning
			or p.isBoosting
			or (Globals.character == 4 and p.state in [p.FALL, 15])
			or (Globals.character == 6 and p.state == 16)
		)
		if Globals.character == 0 and p.invisTimer > 0:
			can_hit = false
		if (
			shot
			or (
				can_hit
				and node.bbox_rect().intersects(Rect2(p.position - Vector2(6, 20), Vector2(12, 40)))
			)
		):
			node.properties.pending = tick + 10
			request(Net.PacketType.CLIENT_KAFMONITOR_ACTIVATE, int(node.properties.nid), shot)


func _draw():
	var texture := GM.sprite_texture("spr_ghz_rain" if map.lvl_id == 12 else "spr_nap_snow", 0)
	for item in particles:
		if texture != null:
			draw_texture(texture, item.at.floor())
