extends "res://src/game/maps/shared/rules.gd"
## You Can't Run: presentation and network effects.
var state: Dictionary = {}
var smoke: Array = []
var previous_gas := -1
var previous_spike := 0
var eye_target: GMNode = null


func _ready():
	process_physics_priority = 60
	z_index = -250
	for node in GMNode.all_of("obj_ycr_smokearea"):
		node.gm_visible = false


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func visual(sprite: String, at: Vector2) -> GMNode:
	var n = load("res://src/menu/gm_plain.gd").new()
	n.sprite_name = sprite
	n.position = at
	n.depth = 0
	map.add_child(n)
	return n


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 4:
		return
	state = data
	update_ycr()


func update_ycr():
	var phase := int(state.spike)
	for n in nodes("obj_movingspike"):
		n.change(phase)
	if phase != previous_spike and phase in [1, 3]:
		for n in nodes("obj_soundemitter"):
			if str(n.properties.get("stype", "")) in ["0", "SOUNDEMT_MOVINGSPIKE"]:
				GameAudio.play_sound_at("snd_movingspike", n.position)
	previous_spike = phase
	var gas := int(state.gas_id)
	if gas != previous_gas:
		for n in smoke:
			if is_instance_valid(n):
				n.set_meta("fade", true)
		if gas >= 0:
			for area in nodes("obj_ycr_smokearea"):
				if int(area.properties.nid) != gas:
					continue
				GameAudio.play_sound_at("snd_smoke", area.position)
				var box: Rect2 = area.bbox_rect()
				for xx in range(int(box.position.x), int(box.end.x), 228):
					for yy in range(int(box.position.y), int(box.end.y), 178):
						var n := visual("spr_smoke", Vector2(xx, yy))
						n.depth = -21
						n.image_alpha = 0
						n.image_index = randi_range(0, GM.sprite_count(n.sprite_name) - 1)
						n.set_meta("fade", false)
						n.set_meta("origin", n.position)
						smoke.append(n)
		previous_gas = gas


func _physics_process(_delta):
	frame += 1
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		eye_target = null
		return
	for i in range(smoke.size() - 1, -1, -1):
		var n: GMNode = smoke[i]
		n.image_alpha = move_toward(
			n.image_alpha, 0 if n.get_meta("fade") else 1, 0.01 if n.get_meta("fade") else 0.0025
		)
		n.position.x = n.get_meta("origin").x + sin(Time.get_ticks_msec() / 300.0 + i) * 4
		n.queue_redraw()
		if n.get_meta("fade") and n.image_alpha <= 0:
			n.queue_free()
			smoke.remove_at(i)


func gas_frenzy(p: GMNode, ticks: int):
	if p.redRingTimer > 0:
		return
	if ticks >= 600:
		p.take_red_ring()
		return
	GameAudio.crossfade_music("mus_mindfuck", 1.0)
	var screen = load("res://src/game/obj_redring_screen.gd").new()
	map.add_child(screen)
	screen.depth = -700
	screen.z_index = 700
	p.redRingTimer = ticks
