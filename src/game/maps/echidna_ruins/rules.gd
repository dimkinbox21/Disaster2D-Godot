extends "res://src/game/maps/shared/rules.gd"
## Echidna Ruins: presentation and network effects.
var state: Dictionary = {}
var received_frame = 0
var projectiles: Dictionary = {}
var last_judger = 0
var ruins_exit = false
var crystal_on = false
var inversion_left = 0
var inversion_token = 0
var inverse_radius = 0.0
var inverse_acc = 6.4
var inverse_origin = Vector2.ZERO
var original_keys: Array = []
var inverse_rect: ColorRect


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func _ready():
	process_physics_priority = 60
	for type in ["obj_weed", "obj_weed_zone", "obj_marijuna_crystalcontroller"]:
		for n in nodes(type):
			n.gm_visible = false
			n.set_physics_process(false)
	var inverse_layer = CanvasLayer.new()
	inverse_layer.layer = 100
	map.add_child(inverse_layer)
	inverse_rect = ColorRect.new()
	inverse_rect.size = Vector2(480, 270)
	inverse_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	mat.shader = load("res://src/game/maps/ruins_inverse.gdshader")
	inverse_rect.material = mat
	inverse_layer.add_child(inverse_rect)
	var layer = CanvasLayer.new()
	layer.layer = 9
	map.add_child(layer)
	var overlay = load("res://src/game/maps/echidna_ruins/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)


func _exit_tree():
	restore_keys()


func visual(sprite: String, at: Vector2) -> GMNode:
	var n = load("res://src/menu/gm_plain.gd").new()
	n.sprite_name = sprite
	n.position = at
	map.add_child(n)
	return n


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 19:
		return
	var old: Dictionary = state
	state = data
	received_frame = frame
	crystal_on = bool(data.crystals)
	last_judger = int(data.judger)
	if old.is_empty() or bool(old.get("crystals", false)) != crystal_on:
		var elapsed = maxi(0, int(data.age) - int(data.crystal_since))
		for n in nodes("obj_marijuna_crystal"):
			n.active = crystal_on
			n.fade = (
				clampf(elapsed * 0.016 if crystal_on else 1 - elapsed * 0.016, 0, 1)
				if crystal_on or int(data.crystal_since) > 0
				else 0
			)
	var effect: Dictionary = data.inverted.get(str(Net.nid), {})
	if not effect.is_empty() and int(effect.until) > int(data.age):
		invert(int(effect.until) - int(data.age), Vector2(effect.x, effect.y), int(effect.until))
	for id in projectiles.keys():
		if not data.shots.has(id):
			projectiles[id].queue_free()
			projectiles.erase(id)
	for id in data.shots:
		var shot: Dictionary = data.shots[id]
		if not projectiles.has(id):
			projectiles[id] = visual("spr_marijuna_hueta2", Vector2(shot.x, shot.y))
			projectiles[id].depth = 1
		var n: GMNode = projectiles[id]
		n.position = Vector2(shot.x, shot.y)
		n.image_xscale = signf(shot.vx)
		n.set_meta("shot", shot)
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)
		match str(event.kind):
			"crystal":
				if data.crystals:
					for n in nodes("obj_marijuna_crystal"):
						GameAudio.play_sound_at("snd_destiny", n.position)
			"judger":
				if int(data.judger) == 1:
					for n in nodes("obj_marijuna_judger"):
						GameAudio.play_sound_at("snd_judger", n.position)
			"invert":
				GameAudio.play_sound("snd_boohoo")


func invert(ticks: int, at: Vector2, token: int):
	if token == inversion_token:
		return
	inversion_token = token
	inversion_left = ticks
	inverse_radius = 0
	inverse_acc = 6.4
	inverse_origin = at
	if original_keys.is_empty():
		original_keys = [Globals.KeyLeft, Globals.KeyRight, Globals.KeyUp, Globals.KeyDown]
		Globals.KeyLeft = original_keys[1]
		Globals.KeyRight = original_keys[0]
		Globals.KeyUp = original_keys[3]
		Globals.KeyDown = original_keys[2]


func restore_keys():
	if original_keys.is_empty():
		return
	Globals.KeyLeft = original_keys[0]
	Globals.KeyRight = original_keys[1]
	Globals.KeyUp = original_keys[2]
	Globals.KeyDown = original_keys[3]
	original_keys.clear()


func before_player(p):
	for n in nodes("obj_marijuna_lavaplatform"):
		var box = n.bbox_rect()
		var item: Dictionary = state.get("lava", {})
		var next_y = predicted_lava(item) if not item.is_empty() else n.position.y
		if (
			p.yspd >= 0
			and absf(p.position.y + 18 - box.position.y) <= 6
			and p.position.x >= box.position.x - 7
			and p.position.x <= box.end.x + 7
		):
			p.position.y += next_y - n.position.y
		n.position.y = next_y
		n.queue_redraw()


func _physics_process(_delta):
	frame += 1
	var p = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		restore_keys()
		inversion_left = 0
		inverse_radius = 0
		if is_instance_valid(inverse_rect):
			inverse_rect.material.set_shader_parameter("radius", 0.0)
		return
	var cam = Vector2.ZERO
	for camera in nodes("obj_camera"):
		cam = camera.render_origin
		break
	update_ruins(p, cam)


func update_ruins(p, cam: Vector2):
	if not ruins_exit and not nodes("obj_bigring").is_empty():
		ruins_exit = true
		var faces = nodes("obj_marijuna_guko")
		if not faces.is_empty():
			faces.pick_random().variant = 2
	for n in nodes("obj_marijuna_crystal"):
		n.active = crystal_on
	for n in nodes("obj_marijuna_judger"):
		n.image_index = int(last_judger > 0)
		n.image_speed = 0
		n.queue_redraw()
		if (
			last_judger == 2
			and (
				(
					(
						int(state.get("age", 0))
						+ frame
						- received_frame
						- int(state.get("judger_since", 0))
					)
					% 15
				)
				== 0
			)
		):
			GameAudio.play_sound_at("snd_lavahit", n.position)
	for id in projectiles:
		var n: GMNode = projectiles[id]
		var shot: Dictionary = n.get_meta("shot")
		n.position = Vector2(shot.x, shot.y) + Vector2(shot.vx, shot.vy) * (frame - received_frame)
		n.queue_redraw()
	if inversion_left > 0:
		inversion_left -= 1
	if inversion_left == 0:
		restore_keys()
	if inversion_left > 90:
		inverse_radius = minf(map.room_h, inverse_radius + inverse_acc)
	else:
		inverse_radius = maxf(0, inverse_radius - inverse_acc)
		inverse_origin = p.position
	if inverse_radius >= map.room_h:
		inverse_origin = p.position
	inverse_acc += 0.064
	if is_instance_valid(inverse_rect):
		inverse_rect.material.set_shader_parameter("point", inverse_origin - cam)
		inverse_rect.material.set_shader_parameter("radius", inverse_radius)


func predicted_lava(item: Dictionary) -> float:
	var ticks = clampi(frame - received_frame, 0, 6)
	var phase = int(item.state)
	var y = float(item.y)
	if phase in [0, 3]:
		return (
			float(item.sy)
			- (float(item.dist) if phase == 3 else 0)
			+ sin((float(item.timer) - ticks) / 25) * 6
		)
	if phase == 1:
		return minf(float(item.sy) + 20, y + ticks * 0.15)
	for tick in ticks:
		y += (1 if phase == 4 else -1) * minf(5, float(item.speed) + tick * 0.08)
	return minf(float(item.sy), y) if phase == 4 else maxf(float(item.sy) - float(item.dist), y)
