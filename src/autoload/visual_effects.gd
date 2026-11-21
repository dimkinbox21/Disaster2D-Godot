extends Node
const FILTER = preload("res://src/game/effects/layer_filter.gdshader")
var rooms: Dictionary = {}
var cache: Dictionary = {}
var noise: Texture2D
var scene: Node
var room: Dictionary = {}
var backgrounds: Array = []
var menu_materials: Array = []
var menu_started_ms = 0
var surface_groups: Dictionary = {}
var surface_members: Dictionary = {}
var surface_materials: Array = []
const ALIASES = {
	"map_hill": "greenhill",
	"map_darktower": "dartower",
	"map_hauntdream": "haundream",
	"map_majinforest": "majongforest"
}


func _ready():
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gm/layer_effects.json"))
	noise = load("res://assets/gm/original_heathaze_noise.png")
	get_tree().scene_changed.connect(setup_scene)
	get_tree().node_added.connect(
		func(n):
			if n is GMNode and is_instance_valid(scene) and scene.is_ancestor_of(n):
				bind_added.call_deferred(n.get_instance_id())
	)


func bind_added(id: int):
	var node = instance_from_id(id)
	if is_instance_valid(node):
		bind_item(node)


func source_name(n: Node) -> String:
	var name = n.scene_file_path.get_file().get_basename()
	return "room_" + str(ALIASES.get(name, name.trim_prefix("map_")))


func setup_scene():
	scene = get_tree().current_scene
	room = rooms.get(source_name(scene), {})
	backgrounds.clear()
	cache.clear()
	menu_materials.clear()
	surface_groups.clear()
	surface_members.clear()
	surface_materials.clear()
	menu_started_ms = Time.get_ticks_msec()
	if room.is_empty():
		return
	# Restore backgrounds omitted by the scene importer, including connection UI.
	for name in room.layers:
		var layer: Dictionary = room.layers[name]
		if (
			layer.resourceType != "GMRBackgroundLayer"
			or not layer.visible
			or scene.get_node_or_null(NodePath(name)) != null
		):
			continue
		if layer.spriteId == null and layer.get("colour") != null:
			var fill = load("res://src/game/effects/colour_layer.gd").new()
			fill.name = name
			fill.depth = float(layer.depth)
			fill.colour = gm_colour(int(layer.colour))
			scene.add_child(fill)
		elif layer.spriteId is Dictionary:
			var bg = load("res://src/menu/gm_background.gd").new()
			bg.name = name
			bg.sprite_name = layer.spriteId.name
			bg.depth = float(layer.depth)
			bg.position = Vector2(float(layer.x), float(layer.y))
			bg.hspeed = float(layer.hspeed)
			bg.vspeed = float(layer.vspeed)
			bg.htiled = layer.htiled
			bg.vtiled = layer.vtiled
			bg.stretch = layer.stretch
			var meta = GM.sprite_meta(bg.sprite_name)
			var native_rate = (
				float(meta.playbackSpeed) / (60.0 if int(meta.playbackSpeedType) == 0 else 1.0)
			)
			var layer_rate = (
				float(layer.animationFPS) / (60.0 if int(layer.animationSpeedType) == 0 else 1.0)
			)
			bg.image_speed = layer_rate / native_rate if native_rate > 0 else 0.0
			scene.add_child(bg)
	if source_name(scene) in ["room_connecting", "room_waiting", "room_message"]:
		for layer in room.layers.values():
			for asset in layer.get("assets", []) if layer.get("assets") is Array else []:
				var art = load("res://src/menu/gm_plain.gd").new()
				art.name = asset.name
				art.depth = float(layer.depth)
				art.sprite_name = asset.spriteId.name
				art.position = Vector2(asset.x, asset.y)
				art.image_speed = float(asset.animationSpeed)
				art.image_index = float(asset.headPosition)
				scene.add_child(art)
	bind_tree(scene)
	if source_name(scene) == "room_menu":
		setup_menu_layers()


func setup_menu_layers():
	menu_started_ms = Time.get_ticks_msec()
	for layer_name in ["Background", "Main3"]:
		var content = scene.get_node_or_null(layer_name)
		if content == null or content.has_meta("menu_filter_group"):
			continue
		var layer: Dictionary = room.layers[layer_name]
		var group = CanvasGroup.new()
		group.name = layer_name + "Filter"
		group.z_as_relative = false
		group.z_index = -int(layer.depth)
		group.fit_margin = 16
		group.clear_margin = 16
		group.add_to_group("menu_layer_fx")
		scene.add_child(group)
		var mat = ShaderMaterial.new()
		mat.shader = load("res://src/menu/menu_layer_haze.gdshader")
		mat.set_shader_parameter("noise_tex", load("res://assets/gm/original_heathaze_noise.png"))
		for key in parameters(layer):
			mat.set_shader_parameter(key, parameters(layer)[key])
		mat.set_shader_parameter("phase_time", 0.0)
		menu_materials.append(mat)
		group.material = mat
		content.reparent(group, true)
		content.set_meta("menu_filter_group", group)
		prepare_menu_content(content)


func prepare_menu_content(n: Node):
	if n is CanvasItem:
		n.z_as_relative = true
		n.z_index = 0
		n.material = null
	if n is GMNode:
		n.set_meta("menu_surface_filter", true)
	for child in n.get_children():
		prepare_menu_content(child)


func bind_tree(n: Node):
	if n is CanvasLayer:
		return
	if n is GMNode:
		bind_item(n)
	for child in n.get_children():
		bind_tree(child)


func layer_for(n: GMNode) -> Dictionary:
	if room.is_empty():
		return {}
	var actual_depth = -n.z_index
	var name = str(room.items.get(str(n.name), ""))
	if room.layers.has(str(n.name)):
		name = str(n.name)
	if name == "":
		if n.gm_name == "gm_background":
			for key in room.layers:
				var candidate: Dictionary = room.layers[key]
				if (
					candidate.resourceType == "GMRBackgroundLayer"
					and candidate.spriteId is Dictionary
					and candidate.spriteId.name == n.sprite_name
				):
					name = key
					break
	if name == "":
		for key in room.layers:
			var layer: Dictionary = room.layers[key]
			if (
				int(layer.depth) == actual_depth
				and (layer.resourceType == "GMRInstanceLayer" or n.is_in_group("map_tiles"))
			):
				name = key
				break
	if name != "" and int(room.layers[name].depth) != actual_depth:
		name = ""
	if name == "":
		for key in room.layers:
			var layer: Dictionary = room.layers[key]
			if int(layer.depth) == actual_depth and layer.resourceType == "GMRInstanceLayer":
				name = key
				break
	return room.layers.get(name, {})


func bind_item(n):
	if (
		not is_instance_valid(n)
		or not n is GMNode
		or not is_instance_valid(scene)
		or not scene.is_ancestor_of(n)
	):
		return
	var parent = n.get_parent()
	while parent != scene:
		if parent is CanvasLayer or parent == null:
			return
		parent = parent.get_parent()
	if n.get_meta("menu_surface_filter", false):
		return
	var layer = layer_for(n)
	n.set_meta("visual_layer_fx", layer)
	if n.gm_name == "obj_lobby_prolet" and n.blackwhite:
		layer = {
			"effectEnabled": true,
			"effectType": "_filter_greyscale",
			"properties": [{"name": "g_Intensity", "value": "1"}]
		}
		n.set_meta("visual_layer_fx", layer)
	# Initial layer visibility belongs to its container, not the object draw flag.
	if source_name(scene) == "room_menu":
		n.set_meta("menu_live_draw", true)
	if n.gm_name == "gm_background":
		backgrounds.append(n)
		if not n.has_meta("source_layer_colour") and layer.get("colour") != null:
			n.layer_colour = gm_colour(int(layer.colour))
			n.set_meta("source_layer_colour", true)
			n.queue_redraw()
	if not n.has_meta("source_item_colour") and room.get("colours", {}).has(str(n.name)):
		var colour = gm_colour(int(room.colours[str(n.name)]))
		n.image_blend = Color(colour, 1.0)
		n.image_alpha = colour.a
		n.set_meta("source_item_colour", true)
		n.queue_redraw()
	if not n.gm_visible:
		return
	if (
		layer.get("effectType")
		in ["_filter_heathaze", "_filter_underwater", "_filter_greyscale", "_filter_tintfilter"]
	):
		if source_name(scene) == "room_menu" or n.gm_name == "obj_lobby_prolet":
			apply(n, n.get_meta("visual_palette", {}))
		else:
			bind_surface(n, layer)


func parameters(layer: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var vectors: Dictionary = {}
	for property in layer.get("properties", []) if layer.get("properties") is Array else []:
		var key = str(property.name)
		var value = str(property.value)
		if key in ["g_Distort1Scale", "g_Distort2Scale"]:
			if not vectors.has(key):
				vectors[key] = []
			vectors[key].append(float(value))
			continue
		if key == "g_DistortTexture":
			continue
		out[key] = (
			Color(value.substr(3, 6) + value.substr(1, 2))
			if value.begins_with("#") and value.length() == 9
			else float(value)
		)
	for key in vectors:
		out[key] = Vector2(vectors[key][0], vectors[key][-1])
	return out


func apply(n: GMNode, palette: Dictionary):
	var layer: Dictionary = n.get_meta("visual_layer_fx", {})
	var effect = str(layer.get("effectType", "")) if layer.get("effectEnabled", false) else ""
	if n.get_meta("surface_filter", false):
		effect = ""
	var from: Array = palette.get("from", [])
	var to: Array = palette.get("to", [])
	var count = (
		int(from.size() / 4)
		if from.size() == to.size() and from.size() % 4 == 0 and from != to
		else 0
	)
	if effect in ["", "none", "<null>"] and count == 0:
		if n.get_meta("visual_material_owned", false):
			n.material = null
		return
	var key = hash([layer, palette])
	var mat: ShaderMaterial = cache.get(key)
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = FILTER
		var values = parameters(layer)
		if effect == "_filter_greyscale":
			mat.set_shader_parameter("intensity", float(values.get("g_Intensity", 0)))
			mat.set_shader_parameter(
				"gray_weights",
				(
					Vector3(0.2989, 0.587, 0.114)
					if n.gm_name == "obj_lobby_prolet"
					else Vector3(0.299, 0.587, 0.114)
				)
			)
		if effect == "_filter_tintfilter":
			mat.set_shader_parameter("g_TintCol", values.get("g_TintCol", Color.WHITE))
		mat.set_shader_parameter("u_ColourCount", count)
		if count > 0:
			var pattern = PackedColorArray()
			var replacement = PackedColorArray()
			for i in count:
				pattern.append(
					Color(from[i * 4], from[i * 4 + 1], from[i * 4 + 2], from[i * 4 + 3])
				)
				replacement.append(Color(to[i * 4], to[i * 4 + 1], to[i * 4 + 2], to[i * 4 + 3]))
			mat.set_shader_parameter("u_Pattern", pattern)
			mat.set_shader_parameter("u_Replacements", replacement)
		if cache.size() >= 1024:
			for stale in cache.keys().slice(0, 64):
				cache.erase(stale)
		cache[key] = mat
	if n.material != mat:
		n.material = mat
	n.set_meta("visual_material_owned", true)


func actor_texture(n: GMNode, palette: Dictionary) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return GM.swapped_texture(
			n.sprite_name, int(n.image_index), palette.get("from", []), palette.get("to", [])
		)
	n.set_meta("visual_palette", palette)
	apply(n, palette)
	return GM.sprite_texture(n.sprite_name, int(n.image_index))


func bind_surface(n: GMNode, layer: Dictionary):
	if not layer.get("effectEnabled", false):
		return
	var layer_name = ""
	for key in room.layers:
		if room.layers[key] == layer:
			layer_name = key
			break
	if layer_name == "":
		return
	var group: CanvasGroup = surface_groups.get(layer_name)
	if group == null:
		group = CanvasGroup.new()
		group.name = layer_name + "Filter"
		group.z_as_relative = false
		group.z_index = -int(layer.depth)
		group.fit_margin = 32
		group.clear_margin = 32
		var mat = ShaderMaterial.new()
		mat.shader = load("res://src/game/effects/original_layer_filter.gdshader")
		var effect = str(layer.effectType)
		mat.set_shader_parameter("distort", effect in ["_filter_heathaze", "_filter_underwater"])
		mat.set_shader_parameter("underwater", effect == "_filter_underwater")
		mat.set_shader_parameter(
			"noise_tex",
			(
				load("res://assets/gm/original_underwater_noise.png")
				if effect == "_filter_underwater"
				else noise
			)
		)
		for key in parameters(layer):
			mat.set_shader_parameter(
				"intensity" if key == "g_Intensity" else key, parameters(layer)[key]
			)
		mat.set_shader_parameter("phase_time", 0.0)
		group.material = mat
		scene.add_child(group)
		surface_groups[layer_name] = group
		surface_materials.append(mat)
		group.add_to_group("original_layer_fx")
	n.set_meta("surface_filter", true)
	n.set_meta("surface_layer", layer_name)
	if (
		n.get_meta("visual_material_owned", false)
		or (n.is_in_group("map_tiles") and n.material is ShaderMaterial)
	):
		n.material = null
	n.set_meta("visual_material_owned", false)
	if n.get_parent() != group:
		n.reparent(group, true)
	surface_members[n.get_instance_id()] = {"group": group, "depth": n.depth, "z": n.z_index}
	apply(n, n.get_meta("visual_palette", {}))


func set_layer_parameter(layer_name: String, key: String, value):
	var group = surface_groups.get(layer_name)
	if is_instance_valid(group):
		group.material.set_shader_parameter("intensity" if key == "g_Intensity" else key, value)


func _process(_dt):
	# Preserve absolute depth. An instance that changes depth leaves its old layer.
	for id in surface_members.keys():
		var member = instance_from_id(id)
		var entry: Dictionary = surface_members[id]
		var group = entry.group
		if not is_instance_valid(member):
			surface_members.erase(id)
			continue
		if member.depth != entry.depth:
			member.z_index = clampi(-int(member.depth), -4096, 4096)
		if group == null:
			if member.z_index != entry.z:
				bind_item(member)
			if surface_members[id].group == null:
				surface_members[id] = {"group": null, "depth": member.depth, "z": member.z_index}
		elif member.z_index != group.z_index:
			surface_members[id] = {"group": null, "depth": member.depth, "z": member.z_index}
			member.set_meta("surface_filter", false)
			member.reparent(scene, true)
			bind_item(member)
	for mat in menu_materials:
		mat.set_shader_parameter("phase_time", (Time.get_ticks_msec() - menu_started_ms) / 1000.0)
	var origin = Vector2.ZERO
	for camera in GMNode.all_of("obj_camera"):
		origin = camera.render_origin
		break
	for mat in surface_materials:
		mat.set_shader_parameter("camera_origin", origin)
		mat.set_shader_parameter("phase_time", (Time.get_ticks_msec() - menu_started_ms) / 1000.0)


func gm_colour(value: int) -> Color:
	return Color(
		(value & 255) / 255.0,
		((value >> 8) & 255) / 255.0,
		((value >> 16) & 255) / 255.0,
		((value >> 24) & 255) / 255.0
	)


func _exit_tree():
	if DisplayServer.get_name() != "headless":
		cache.clear()
