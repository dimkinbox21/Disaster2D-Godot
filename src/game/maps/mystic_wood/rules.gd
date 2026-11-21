extends "res://src/game/maps/shared/rules.gd"
## Mystic Wood: presentation and network effects.
var state: Dictionary = {}
var received_frame = 0
var lantern = -1
var wood_timer = 1260.0
var wood = false
var wood_anim = -1.0
var wood_progress = 0.0
var fog_fade = 0.0
var ghost_timer = 300


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func _ready():
	process_physics_priority = 60
	wood_timer = randf_range(21, 22) * 60
	for type in ["obj_weed", "obj_weed_zone", "obj_marijuna_crystalcontroller"]:
		for n in nodes(type):
			n.gm_visible = false
			n.set_physics_process(false)
	var layer = CanvasLayer.new()
	layer.layer = 9
	map.add_child(layer)
	var overlay = load("res://src/game/maps/mystic_wood/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)


func _exit_tree():
	pass


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 18:
		return
	var old: Dictionary = state
	state = data
	received_frame = frame
	lantern = int(data.lantern)
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)
		match str(event.kind):
			"lantern":
				GameAudio.play_sound("snd_wdlamp")


func _physics_process(_delta):
	frame += 1
	var p = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		return
	var cam = Vector2.ZERO
	for camera in nodes("obj_camera"):
		cam = camera.render_origin
		break
	update_wood(p, cam)


func lantern_target(n) -> Vector2:
	if n.gm_name == "obj_weed_lantern":
		return n.position + Vector2(0, n.sprite_height() / 2)
	var angle = -float(n.sprite_rotation)
	var height = n.sprite_height()
	return (
		n.position
		+ Vector2(sin(deg_to_rad(angle)) * height, cos(deg_to_rad(angle)) * height + 16.5)
	)


func update_wood(p, cam: Vector2):
	var inside = false
	for zone in nodes("obj_weed_zone"):
		if zone.bbox_rect().has_point(cam + Vector2(240, 135)):
			inside = true
			break
	fog_fade = move_toward(fog_fade, 0 if inside else 1, 0.016)
	for bg in nodes("gm_background"):
		if str(bg.name) == "Foguis":
			bg.layer_colour.a = fog_fade
	var human = Globals.character > 0 and p.hp > 0 and not p.isDead and p.revivalTimes < 2
	if human:
		wood_timer -= 1
		if wood_timer <= 0 and not wood:
			wood = true
			GameAudio.play_sound("snd_wdarms")
	else:
		wood = false
	for n in nodes("obj_weed_lantern"):
		n.active = int(n.properties.nid) == lantern
		if n.active and human and p.position.distance_to(lantern_target(n)) < 80:
			wood = false
			wood_timer = randf_range(21, 22) * 60
	if wood:
		if wood_anim < GM.sprite_count("spr_weed_arms") - 1:
			wood_anim = minf(GM.sprite_count("spr_weed_arms") - 1, wood_anim + 0.25)
		else:
			wood_progress = minf(1, wood_progress + 0.016 / 30)
	else:
		wood_anim = maxf(-1, wood_anim - 0.25)
		wood_progress = maxf(0, wood_progress - 0.016)
	ghost_timer -= 1
	if ghost_timer <= 0:
		ghost_timer = randi_range(5, 7) * 60
		var kind = randi_range(0, 4)
		if kind < 4:
			var ghost = load("res://src/game/maps/freedom_ghost.gd").new()
			ghost.sprite_name = "spr_weed_prizraks2" if kind % 2 == 0 else "spr_weed_prizraks"
			ghost.depth = 292 if kind % 2 == 0 else 592
			ghost.position.y = randi_range(0, 200)
			ghost.xx = -64 if kind < 2 else 544
			ghost.direction = randf_range(0.5, 1) * (1 if kind < 2 else -1)
			map.add_child(ghost)
	# Conveyor movement is positional in the original, separate from run speed.
	for belt in nodes("obj_weed_convejor"):
		var box = belt.bbox_rect()
		var touched = false
		for foot in [p._sens_BL, p._sens_BR]:
			if (
				foot.x >= box.position.x - 4
				and foot.x <= box.end.x
				and foot.y >= box.position.y
				and foot.y <= box.end.y
			):
				touched = true
		if touched:
			var distance = 0
			for step in 4:
				if GMFloor.point_meeting_floor(p.position.x - 8 - distance - 1, p.position.y - 4):
					break
				distance += 1
			p.position.x -= distance
