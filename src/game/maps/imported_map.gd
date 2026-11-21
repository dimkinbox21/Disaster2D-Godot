extends "res://src/game/map_controller.gd"
@export var manifest_path := ""
var manifest: Dictionary


func _ready() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	lvl_id = int(manifest.id)
	room_w = manifest.width
	room_h = manifest.height
	music = manifest.music
	if Net.state != Net.STATE_GAME:
		Net.lvlId = lvl_id
	parallax = manifest.parallax
	for record in manifest.backgrounds:
		var bg = load("res://src/menu/gm_background.gd").new()
		bg.name = record.name
		bg.sprite_name = record.sprite
		bg.depth = record.depth
		bg.gm_visible = record.get("visible", true)
		bg.visible = bg.gm_visible
		bg.position = Vector2(record.position[0], record.position[1])
		bg.hspeed = record.hspeed
		bg.vspeed = record.vspeed
		bg.htiled = record.htiled
		bg.vtiled = record.vtiled
		var animation := GM.sprite_meta(bg.sprite_name)
		var native_rate: float = (
			animation.playbackSpeed / (60.0 if int(animation.playbackSpeedType) == 0 else 1.0)
		)
		var layer_rate: float = (
			record.animation_fps / (60.0 if int(record.animation_type) == 0 else 1.0)
		)
		bg.image_speed = layer_rate / native_rate if native_rate > 0 else 0
		if lvl_id == 12 and record.name == "Background":
			bg.follow_camera = true
			bg.hspeed = -1
		if lvl_id == 18 and record.name == "Foguis":
			bg.follow_camera = true
			bg.hspeed = 2
		add_child(bg)
	for record in manifest.instances:
		_instance(record)
	for record in manifest.assets:
		var art = load("res://src/menu/gm_plain.gd").new()
		art.name = record.name
		art.sprite_name = record.sprite
		art.depth = record.depth
		art.position = Vector2(record.position[0], record.position[1])
		art.image_xscale = record.scale[0]
		art.image_yscale = record.scale[1]
		art.gm_visible = record.get("layer_visible", true)
		art.sprite_rotation = -record.rotation
		art.image_index = record.frame
		art.image_speed = record.speed
		art.gm_static = GM.sprite_count(art.sprite_name) <= 1
		add_child(art)
	for tile in manifest.tiles:
		var meta := GM.sprite_meta(tile[0])
		for frame in meta.frames.size():
			for xx in range(0, int(meta.w), 1024):
				for yy in range(0, int(meta.h), 1024):
					var chunk = load("res://src/game/gm_tile.gd").new()
					chunk.sprite_name = tile[0]
					chunk.image_index = frame
					chunk.image_speed = 0
					chunk.depth = tile[1]
					chunk.position = Vector2(frame * meta.w + xx, yy + tile[2])
					chunk.chunk_x = xx
					chunk.chunk_y = yy
					chunk.gm_static = true
					if lvl_id == 15 and tile[1] == -200:
						chunk.image_alpha = 0.8
					if lvl_id == 6 and tile[1] == 90:
						chunk.image_alpha = 0
						chunk.visible = false
					chunk.add_to_group("map_tiles")
					add_child(chunk)
	rules = load(preload("res://src/data/maps.gd").rules_path(lvl_id)).new()
	rules.name = "MapRules"
	rules.map = self
	add_child(rules)
	super._ready()


func _instance(record: Dictionary) -> void:
	var object: String = record.object
	var floor_type: bool = "obj_floor_parent" in record.parents
	var precise: Array = (
		GM.sprite_meta(record.sprite).get("mask_rects", []) if record.sprite != "" else []
	)
	var frame_masks: Array = (
		GM.sprite_meta(record.sprite).get("mask_frames", []) if record.sprite != "" else []
	)
	if not frame_masks.is_empty():
		precise = frame_masks[int(record.image_index) % frame_masks.size()]
	var path: String = "res://src/game/maps/map_object.gd"
	if floor_type and precise.is_empty():
		path = (
			"res://src/game/obj_platform_jumptrough.gd"
			if object == "obj_platform_jumptrough"
			else (
				"res://src/game/maps/moving_wall.gd"
				if object == "obj_act9_wall"
				else "res://src/game/gmfloor.gd"
			)
		)
	elif "obj_spring_parent" in record.parents or object == "obj_hd_spring":
		path = "res://src/game/obj_spring.gd"
	elif "obj_hiding_parent" in record.parents:
		path = "res://src/game/obj_hiding_box.gd"
	elif object == "obj_abyss":
		path = "res://src/game/obj_abyss.gd"
	elif object == "obj_warning":
		path = "res://src/game/obj_warning.gd"
	elif object == "obj_aiz_zipline":
		path = "res://src/game/maps/zipline.gd"
	elif object == "obj_deathtp":
		path = "res://src/game/obj_deathtp.gd"
	if object in ["obj_hd_door", "obj_hd_door2"]:
		path = "res://src/game/maps/tower_door.gd"
	if object == "obj_hd_crystal":
		path = "res://src/game/maps/tower_crystal.gd"
	if (
		(
			object
			in [
				"obj_pf_lift",
				"obj_vv_lavacolumn",
				"obj_vv_vase",
				"obj_marijuna_crystal",
				"obj_marijuna_guko",
				"obj_marijuna_judger",
				"obj_weed_selfinsert"
			]
		)
		or object.begins_with("obj_weed_lantern")
	):
		path = "res://src/game/maps/freedom_object.gd"
	if object in ["obj_weed_ghost", "obj_weed_ghost2"]:
		path = "res://src/game/maps/freedom_ghost.gd"
	if object == "obj_marijuna_lavaplatform":
		path = "res://src/game/maps/freedom_platform.gd"
	if object == "obj_soundemitter":
		path = "res://src/game/obj_soundemitter.gd"
	if object == "obj_spike":
		path = "res://src/game/obj_spike.gd"
	if object == "obj_movingspike":
		path = "res://src/game/maps/moving_spike.gd"
	if object.begins_with("obj_limpcity_eye"):
		path = "res://src/game/maps/city_object.gd"
	if object == "obj_nap_iceblock":
		path = "res://src/game/maps/iceblock.gd"
	var node = load(path).new()
	node.name = record.name
	node.gm_name = object
	node.sprite_name = record.sprite
	node.position = Vector2(record.position[0], record.position[1])
	node.image_xscale = record.scale[0]
	node.image_yscale = record.scale[1]
	node.sprite_rotation = -record.rotation
	node.depth = record.depth
	node.image_index = record.image_index
	node.image_speed = record.get("image_speed", 1.0)
	if object == "obj_hd_spring":
		node.hold_sensitive = true
	if object == "obj_act9_wall":
		node.depth = -90
	elif object == "obj_abadon_cloud":
		node.depth = 101
	elif object == "obj_npring":
		node.depth = 2
	node.gm_visible = record.visible and record.get("layer_visible", true)
	# Static spike objects draw their own sprite in the original. Only the
	# invisible geometry helpers lose their art; damage masks stay in place.
	if floor_type:
		node.gm_visible = (
			object
			in [
				"obj_fart_tile",
				"obj_act9_wall",
				"obj_movingspike",
				"obj_spike",
				"obj_hd_door",
				"obj_hd_door2",
				"obj_weed_convejor",
				"obj_weed_convejor2",
				"obj_weed_convejor3",
				"obj_marijuna_lavaplatform"
			]
		)
	if not record.get("layer_visible", true):
		node.gm_visible = false
	if node is GMFloor:
		node.canStuck = (
			object != "obj_solid_block2"
			and not object.contains("slope")
			and object != "obj_nap_iceblock"
		)
		node.gm_static = object not in ["obj_act9_wall", "obj_hd_door", "obj_hd_door2"]
		node.image_speed = 0
		if object.begins_with("obj_weed_convejor") or object == "obj_marijuna_lavaplatform":
			node.gm_static = false
			node.canStuck = false
			node.image_speed = record.get("image_speed", 1.0)
	elif "obj_spring_parent" in record.parents or object == "obj_hd_spring":
		node.xdir = (
			-10
			if object == "obj_bspring_left"
			else (
				10
				if object == "obj_bspring_right"
				else (
					-12
					if object == "obj_spring_left"
					else (12 if object == "obj_spring_right" else 0)
				)
			)
		)
		node.ydir = (
			-10
			if object.begins_with("obj_bspring")
			else (-11 if object == "obj_yspring_up" else -12)
		)
	else:
		if node.get("properties") != null:
			node.properties = record.properties
		if node.get("record") != null:
			node.record = record
	for property in record.properties:
		if node.get(property) != null:
			var value: String = record.properties[property]
			node.set(
				property,
				(
					value.to_lower() == "true"
					if value.to_lower() in ["true", "false"]
					else float(value)
				)
			)
	if object == "obj_act9_bodies" or object in ["obj_aiz_zipline_start", "obj_aiz_zipline_end"]:
		node.image_speed = 0
	add_child(node)
	if "obj_hiding_parent" in record.parents:
		# These children define their own empty Create event, so the parent's
		# depth=-60 assignment is not inherited; retain the room layer depth.
		node.depth = record.depth
		node.z_index = -int(record.depth)
	for parent in record.parents:
		if parent != "obj_floor_parent" or precise.is_empty():
			node.add_to_group(parent)
	if not precise.is_empty():
		node.gm_visible = false
		# A zero-scale source instance has no collision area. Expanding it
		# into mask rectangles produced stacked zero-width debug edges.
		if is_zero_approx(node.image_xscale) or is_zero_approx(node.image_yscale):
			return
		var original := GM.sprite_meta(record.sprite)
		var block := GM.sprite_meta("spr_block")
		for rect in precise:
			var mask = (
				load(
					(
						"res://src/game/obj_platform_jumptrough.gd"
						if "obj_platform_jumptrough" in record.parents
						else "res://src/game/gmfloor.gd"
					)
				)
				. new()
			)
			mask.sprite_name = "spr_block"
			mask.gm_name = "obj_solid_block"
			mask.position = (
				node.position
				+ (
					(
						Vector2(rect[0] - original.xorigin, rect[1] - original.yorigin)
						* Vector2(node.image_xscale, node.image_yscale)
					)
					. rotated(deg_to_rad(node.sprite_rotation))
				)
			)
			mask.image_xscale = rect[2] * node.image_xscale / block.w
			mask.image_yscale = rect[3] * node.image_yscale / block.h
			mask.sprite_rotation = node.sprite_rotation
			mask.canStuck = not object.contains("slop")
			mask.gm_visible = false
			mask.gm_static = true
			add_child(mask)
			mask.add_to_group("obj_solid_parent")
			mask.add_to_group("mask_" + record.sprite)
