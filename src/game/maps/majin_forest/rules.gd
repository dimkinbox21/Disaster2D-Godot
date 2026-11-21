extends "res://src/game/maps/shared/rules.gd"
## Majin Forest: presentation and network effects.
var state: Dictionary = {}
var mirrors: Dictionary = {}
var jumpscare = 0
var scare_camera = false
var request_until = 0
var received_frame = 0


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func _ready():
	process_physics_priority = 60
	for type in [
		"obj_darktower_darkness",
		"obj_darktower_fog",
		"obj_darktower_jumpscare",
		"obj_majong_controller",
		"obj_majong_trigger",
		"obj_majong_trigger_point"
	]:
		for n in nodes(type):
			n.gm_visible = false
			n.set_physics_process(false)
	var layer = CanvasLayer.new()
	layer.layer = 9
	map.add_child(layer)
	var overlay = load("res://src/game/maps/majin_forest/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)


func visual(sprite: String, at: Vector2) -> GMNode:
	var n = load("res://src/menu/gm_plain.gd").new()
	n.sprite_name = sprite
	n.position = at
	n.image_speed = 0
	map.add_child(n)
	return n


func request(type: int, kind := 0):
	if frame < request_until:
		return
	Net._send_player_data()
	var packet = Net.cpacket_tcp(type)
	if type == Net.PacketType.CLIENT_TOWER_INTERACT:
		packet.put_u8(kind)
	Net.send_server_tcp(packet)
	request_until = frame + 6


func warp(at: Vector2, reset: bool):
	var p = Globals.player
	if not is_instance_valid(p):
		return
	p.position = at
	if reset:
		p.xspd = 0
		p.yspd = 0
		p.gspd = 0
		flash = 1
		GameAudio.play_sound("snd_npteleport")
	for camera in nodes("obj_camera"):
		camera.position.x = at.x - 240
		if reset:
			camera.position.y = at.y - 135
			camera.dist = 0
		camera.render_origin = camera.position.floor()
	# The player's near-floor cache must be rebuilt at the destination.
	p._near = GMFloor.gather_near(at.x, at.y, 80)
	p._near_refresh()


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 13:
		return
	state = data
	received_frame = frame
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)


func _physics_process(_delta):
	frame += 1
	flash = maxf(0, flash - 0.32)
	jumpscare = maxi(0, jumpscare - 1)
	var p = Globals.player
	if is_instance_valid(p):
		if jumpscare > 0:
			if Time.get_ticks_msec() % 22 <= 10:
				var warp = float(randi_range(-60, 60))
				for camera in nodes("obj_camera"):
					if is_instance_valid(camera._cam2d):
						camera._cam2d.zoom = Vector2(480 / (480 + warp), 270 / (270 + warp))
						camera._cam2d.offset = Vector2(-warp, -warp)
			scare_camera = true
		elif scare_camera:
			for camera in nodes("obj_camera"):
				if is_instance_valid(camera._cam2d):
					camera._cam2d.zoom = Vector2.ONE
					camera._cam2d.offset = Vector2.ZERO
			scare_camera = false
	if not is_instance_valid(p) or Net.gameEnds:
		return
	if (p.position.x <= 240 and p.xspd < 0) or (p.position.x >= 3408 and p.xspd > 0):
		request(Net.PacketType.CLIENT_TOWER_INTERACT, 0)
	for n in nodes("obj_majong_trigger"):
		if (
			p.bbox_rect().end.y > n.bbox_rect().position.y
			and p.bbox_rect().end.x > n.bbox_rect().position.x
			and p.bbox_rect().position.x < n.bbox_rect().end.x
		):
			request(Net.PacketType.CLIENT_TOWER_INTERACT, 1)
			break
	update_mirrors()


func update_mirrors():
	var active: Dictionary = {}
	for source in nodes("obj_player_puppet") + nodes("obj_puppet_tail") + nodes("obj_blackring"):
		var x: float = source.position.x
		var edge = 512 if source.gm_name == "obj_blackring" else 480
		var shift = (
			3168 if x >= 0 and x < edge else (-3168 if x >= 3648 - edge and x <= 3648 else 0)
		)
		if shift == 0 or not source.visible:
			continue
		var id = source.get_instance_id()
		active[id] = true
		if not mirrors.has(id):
			mirrors[id] = visual(source.sprite_name, source.position)
		var n: GMNode = mirrors[id]
		n.position = source.position + Vector2(shift, 0)
		n.sprite_name = source.sprite_name
		n.image_index = source.image_index
		n.image_xscale = source.image_xscale
		n.image_yscale = source.image_yscale
		n.sprite_rotation = source.sprite_rotation
		n.image_blend = source.image_blend
		n.image_alpha = source.image_alpha
		n.material = source.material
		n.depth = source.depth
		n.z_index = source.z_index
		n.queue_redraw()
	for id in mirrors.keys():
		if not active.has(id):
			mirrors[id].queue_free()
			mirrors.erase(id)
