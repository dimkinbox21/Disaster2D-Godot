extends "res://src/game/maps/shared/rules.gd"
## Haunting Dream: presentation and network effects.
var state: Dictionary = {}
var jumpscare = 0
var scare_camera = false
var request_until = 0
var received_frame = 0
var old_door = false
var door_received = false


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
	var overlay = load("res://src/game/maps/haunting_dream/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)


func request(type: int, kind := 0):
	if frame < request_until:
		return
	Net._send_player_data()
	var packet = Net.cpacket_tcp(type)
	if type == Net.PacketType.CLIENT_TOWER_INTERACT:
		packet.put_u8(kind)
	Net.send_server_tcp(packet)
	request_until = frame + 6


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 17:
		return
	state = data
	received_frame = frame
	var open: bool = data.open
	if door_received and old_door != open:
		for n in nodes("obj_hd_door") + nodes("obj_hd_door2"):
			GameAudio.play_sound_at("snd_door", n.position)
	old_door = open
	door_received = true
	for n in nodes("obj_hd_door") + nodes("obj_hd_door2"):
		if data.doors.has(str(n.name)):
			n.position = Vector2(data.doors[str(n.name)].x, data.doors[str(n.name)].y)
			n.queue_redraw()
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)
		match str(event.kind):
			"crystal_ready":
				for n in nodes("obj_hd_crystal"):
					GameAudio.play_sound_at("snd_message", n.position)


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
	if not state.is_empty() and frame > received_frame:
		for n in nodes("obj_hd_door") + nodes("obj_hd_door2"):
			var box = n.bbox_rect()
			var end = (
				(
					n.origin
					- (
						Vector2(box.size.x, 0)
						if n.gm_name == "obj_hd_door2"
						else Vector2(0, box.size.y)
					)
				)
				if state.open
				else n.origin
			)
			n.position = n.position.move_toward(end, 1)
			n.queue_redraw()
	for n in nodes("obj_hd_crystal"):
		n.position.y = float(n.record.position[1]) + sin(Time.get_ticks_msec() / 400.0) * 2
		n.image_index = int(state.get("open", false))
		n.image_speed = 0
		n.queue_redraw()
		if (
			not p.isDead
			and int(state.get("cooldown", 0)) <= 0
			and n.bbox_rect().intersects(p.bbox_rect())
			and (p.isLookingDown or p.isLookingUp)
			and (p.kp(Globals.KeyDown) or p.kp(Globals.KeyUp))
		):
			request(Net.PacketType.CLIENT_HDDOOR_TOGGLE)
