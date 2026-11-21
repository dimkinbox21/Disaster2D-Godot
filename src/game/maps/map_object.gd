extends GMNode
var properties: Dictionary = {}
var record: Dictionary = {}
var _start := Vector2.ZERO
var _phase := 0.0


func _ready() -> void:
	super._ready()
	_start = position
	_phase = randf() * 25
	if (
		gm_name
		in [
			"obj_act9_bodies",
			"obj_corpse_tails",
			"obj_corpse_amy",
			"obj_corpse_cream",
			"obj_corpse_knux",
			"obj_npring",
			"obj_abandon_mine"
		]
	):
		image_alpha = 0
	if gm_name == "obj_abandon_mine":
		gm_visible = false
	if gm_name == "obj_abadon_cloud":
		visible = false
	if (
		gm_name
		in [
			"obj_ring_spawner",
			"obj_ringspawn",
			"obj_spawnpoint",
			"obj_exespawn",
			"obj_aiz_zipline_start",
			"obj_aiz_zipline_end",
			"obj_np_teleporn",
			"obj_leftvitalkivatel",
			"obj_rightvitalkivatel",
			"obj_angleallower",
			"obj_angleanuller_eggsafe"
		]
	):
		set_physics_process(false)


func _gm_step() -> void:
	var p: GMNode = Globals.player
	if not is_instance_valid(p):
		return
	match gm_name:
		"obj_abandon_face":
			sprite_rotation = rad_to_deg((p.position - position).angle())
		"obj_act9_bodies":
			position.y = _start.y + sin(Time.get_ticks_msec() / 550.0 + _phase) * 4
			var character := int(image_index) + 1
			var exists: bool = Globals.character == character and (p.revivalTimes != 1 or p.hp > 0)
			for puppet in all_of("obj_player_puppet"):
				if puppet.pcharacter == character and (puppet.revivalTimes != 1 or puppet.hp > 0):
					exists = true
			if not exists:
				image_alpha = minf(1, image_alpha + 0.004)
		"obj_corpse_tails", "obj_corpse_amy", "obj_corpse_cream", "obj_corpse_knux":
			var character := (
				1
				if gm_name == "obj_corpse_tails"
				else (
					2
					if gm_name == "obj_corpse_knux"
					else (5 if gm_name == "obj_corpse_cream" else 4)
				)
			)
			var exists: bool = Globals.character == character
			for data in Net.players.values():
				exists = exists or int(data.get("character", -1)) == character
			image_alpha = 0 if exists else 1
			gm_visible = not exists
		"obj_abadon_cloud":
			if image_index >= GM.sprite_count(sprite_name) - 1:
				image_index = GM.sprite_count(sprite_name) - 1
				visible = false
		"obj_abandon_mine":
			image_alpha = minf(1, image_alpha + 0.016 / 60) if Globals.timeMinutes <= 0 else 0
		"obj_npring":
			if not all_of("obj_bigring").is_empty():
				gm_visible = true
				image_alpha = minf(1, image_alpha + 0.032)
			for ring in all_of("obj_bigring"):
				if bbox_rect().intersects(ring.bbox_rect()):
					image_alpha = 0
