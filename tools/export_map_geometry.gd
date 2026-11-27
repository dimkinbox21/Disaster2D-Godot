extends SceneTree


## Export actual client collision masks into a sibling server's world.json.
## Godot --headless --path <client> --script res://tools/export_map_geometry.gd
##   -- <absolute server directory> [map ID]
func _initialize():
	call_deferred("run")


func freeze(node: Node) -> void:
	node.set_physics_process(false)
	for child in node.get_children():
		freeze(child)


func simulation_objects(node: Node, result: Array):
	if (
		node.has_method("gm_object_name")
		and not node.gm_name.is_empty()
		and not node.is_in_group("obj_player")
		and simulation_object_needed(node)
	):
		var groups := []
		for group in node.get_groups():
			if not str(group).begins_with("_"):
				groups.append(str(group))
		result.append(
			{
				"name": str(node.name),
				"object": node.gm_name,
				"sprite": node.sprite_name,
				"position": [node.position.x, node.position.y],
				"scale": [node.image_xscale, node.image_yscale],
				"rotation": -node.sprite_rotation,
				"image_index": node.image_index,
				"image_speed": node.image_speed,
				"parents": groups,
				"properties":
				node.get("properties") if node.get("properties") is Dictionary else {},
				"floor": node.is_in_group("gm_floor"),
				"can_stuck": node.get("canStuck") == true,
				"xdir": node.get("xdir") if node.get("xdir") != null else 0,
				"ydir": node.get("ydir") if node.get("ydir") != null else -12,
				"hold_sensitive": node.get("hold_sensitive") == true
			}
		)
	for child in node.get_children():
		simulation_objects(child, result)


func simulation_object_needed(node: Node) -> bool:
	for group in [
		"obj_spring_parent",
		"obj_hd_spring",
		"obj_hiding_parent",
		"obj_damage",
		"obj_ladder",
		"obj_angleanuller",
		"obj_angleanuller_eggsafe",
		"obj_angleallower",
		"obj_aiz_zipline",
		"obj_aiz_zipline_start",
		"obj_aiz_zipline_end",
		"obj_ghz_water",
		"obj_act9_wall",
		"obj_movingspike",
		"obj_hd_door",
		"obj_hd_door2",
		"obj_marijuna_lavaplatform",
		"obj_nap_iceblock",
		"obj_weed_convejor"
	]:
		if node.is_in_group(group):
			return true
	return false


func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Supply the server directory and optional map ID.")
		quit(1)
		return
	var maps = load("res://src/data/maps.gd")
	var ids: Array = range(21)
	if args.size() > 1:
		ids = [int(args[1])]
	var globals = root.get_node("Globals")
	globals.character = 0
	for id in ids:
		var entry: Dictionary = maps.entry(id)
		if entry.is_empty():
			push_error("Unknown map ID: %s" % id)
			quit(1)
			return
		change_scene_to_file(entry.scene)
		await scene_changed
		freeze(current_scene)
		var geometry := []
		for node in get_nodes_in_group("gm_floor") + get_nodes_in_group("obj_angleanuller"):
			if node.sprite_name.is_empty():
				continue
			if (
				node.gm_name
				in [
					"obj_act9_wall",
					"obj_movingspike",
					"obj_hd_door",
					"obj_hd_door2",
					"obj_marijuna_lavaplatform",
					"obj_nap_iceblock"
				]
			):
				continue  # Server map rules supply dynamic bounds.
			var meta: Dictionary = root.get_node("GM").sprite_meta(node.sprite_name)
			var box: Array = (
				meta.bbox if int(meta.bboxMode) != 1 else [0, 0, meta.w - 1, meta.h - 1]
			)
			(
				geometry
				. append(
					{
						"can_stuck": node.get("canStuck") == true,
						"one_way": node.is_in_group("gm_jumpthrough"),
						"group": "floor" if node.is_in_group("gm_floor") else "angle",
						"x": node.position.x,
						"y": node.position.y,
						"rot": deg_to_rad(node.sprite_rotation),
						"sx": node.image_xscale,
						"sy": node.image_yscale,
						"l": box[0] - meta.xorigin,
						"t": box[1] - meta.yorigin,
						"w": box[2] - box[0] + 1,
						"h": box[3] - box[1] + 1,
					}
				)
			)
		var path: String = args[0].path_join("assets/maps/" + entry.folder + "/world.json")
		if not FileAccess.file_exists(path):
			push_error("Server map data does not exist: " + path)
			quit(1)
			return
		var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		world.simulation_objects = []
		simulation_objects(current_scene, world.simulation_objects)
		world.geometry = geometry
		world.hazards = {"height": current_scene.room_h, "items": [], "rings": []}
		for ring_point in get_nodes_in_group("obj_ring_spawner"):
			world.hazards.rings.append([ring_point.position.x, ring_point.position.y])
		var seen := {}
		for group in [
			"obj_damage",
			"obj_abyss",
			"obj_abyss_target",
			"obj_deathtp_point",
			"obj_spawnpoint",
			"obj_exespawn"
		]:
			for node in get_nodes_in_group(group):
				if seen.has(node.get_instance_id()):
					continue
				seen[node.get_instance_id()] = true
				var box: Rect2 = node.bbox_rect()
				world.hazards.items.append(
					{
						"type": node.gm_name,
						"x": node.position.x,
						"y": node.position.y,
						"bounds": [box.position.x, box.position.y, box.size.x, box.size.y],
						"stun": node.get("shouldStun") == true
					}
				)
		FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(world, "  ") + "\n")
		root.get_node("GameAudio").stop_all()
		print("Exported map %d: %d collision masks" % [id, geometry.size()])
	quit()
