extends Node2D
## Generic map controller (port of room creation code):
## spawns the player, camera and HUD; plays the
## room music; feeds the parallax layer list to obj_parallax.

var rules: Node

@export var music := ""
@export var parallax_json := ""
var parallax: Array = []
@export var room_w := 4544.0
@export var room_h := 1888.0
@export var strips: Array = []
## the room's index in global.levels (scr_globals.gml) — emitted by the room
## converter; drives the title card sprite frame and the level music table
@export var lvl_id := -1


func _ready() -> void:
	# Resolve the local role from the lobby assignment before selecting a spawn.
	if Net.state == Net.STATE_GAME:
		if Net.nid == Net.exeId:
			Globals.character = Globals.CHARACTER_EXE
		elif Net.players.has(Net.nid):
			Globals.character = int(Net.players[Net.nid].get("character", Globals.character))
	# solo map launch (no lobby → no char select): the player runs on the exe
	# movement values (player.gd uses EXE_ACC/EXE_MAXSPEED), so the HUD and the
	# ability icons must describe the exe too. Netplay overwrites both on entry.
	if Globals.character < 0:
		Globals.character = Globals.CHARACTER_EXE
	if Globals.exeCharacter < 0:
		Globals.exeCharacter = Globals.EXE_ORIGINAL
	# the room converter stamps the level id; netplay overwrites Net.lvlId
	if Net.lvlId < 0 and lvl_id >= 0:
		Net.lvlId = lvl_id
	var spawn: Node2D = null
	var spawn_group := (
		"obj_exespawn" if Globals.character == Globals.CHARACTER_EXE else "obj_spawnpoint"
	)
	var spawn_points := get_tree().get_nodes_in_group(spawn_group)
	if not spawn_points.is_empty():
		spawn = spawn_points.pick_random()
	if spawn == null:
		for n in get_tree().get_nodes_in_group("obj_spawnpoint"):
			spawn = n
			break
	if spawn == null:
		spawn = self

	var player := Node2D.new()
	player.set_script(load("res://src/game/player.gd"))
	player.position = spawn.position + Vector2(0, -18)
	player.fall_limit_y = room_h
	add_child(player)

	var cam := Node2D.new()
	cam.set_script(load("res://src/game/obj_camera.gd"))
	cam.room_w = room_w
	cam.room_h = room_h
	cam.position = player.position
	add_child(cam)

	var level := Node2D.new()
	level.set_script(load("res://src/game/obj_level.gd"))
	level.position = Vector2.ZERO
	add_child(level)

	if lvl_id == 0 and Globals.character == Globals.CHARACTER_EXE:
		var indicator_canvas := CanvasLayer.new()
		indicator_canvas.layer = 9
		add_child(indicator_canvas)
		indicator_canvas.add_child(load("res://src/game/obj_exe_sprindicator.gd").new())

	# obj_netclient Other_4 (Room Start): spawn the other players' puppets —
	# non-Tails first, then Tails (the original's two passes fix the draw order)
	if Net.state == Net.STATE_GAME:
		var tails_list: Array = []
		for k in Net.players:
			if k == Net.nid:
				continue
			var plr: Dictionary = Net.players[k]
			if int(plr.get("character", -1)) == -1:
				continue
			if int(plr.get("character", -1)) == Globals.CHARACTER_TAILS:
				tails_list.append(plr)
				continue
			_spawn_puppet(plr)
		for plr in tails_list:
			_spawn_puppet(plr)

	# collision comes from the room's own invisible obj_solid_block instances
	# (emitted by the room converter) — no art-generated rects (they were wrong)

	if parallax_json != "":
		parallax = JSON.parse_string(parallax_json)
	for entry in parallax:
		if entry.size() > 3:
			entry[3] = float(entry[3])
		entry[1] = float(entry[1])
		entry[2] = float(entry[2])
	var par := Node2D.new()
	par.set_script(load("res://src/game/obj_parallax.gd"))
	par.parallax = parallax
	add_child(par)

	if music != "":
		GameAudio.play_music(music)

	if rules == null:
		rules = load(preload("res://src/data/maps.gd").rules_path(lvl_id)).new()
		rules.map = self
		add_child(rules)
	var overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 11
	add_child(overlay_layer)
	var overlay = load(preload("res://src/data/maps.gd").hud_path(lvl_id)).new()
	overlay.rules = rules
	overlay_layer.add_child(overlay)


## obj_netclient Other_4: instance_create_depth(0, 0, 0, obj_player_puppet) +
## the players-map field assignment
func _spawn_puppet(plr: Dictionary) -> void:
	var pup := GMNode.new()
	pup.set_script(load("res://src/game/obj_player_puppet.gd"))
	pup.setup(
		int(plr.get("nid", 0)),
		str(plr.get("nickname", "")),
		int(plr.get("character", -1)),
		int(plr.get("exeCharacter", 0))
	)
	add_child(pup)
	pup.apply_anim()
	if pup.pcharacter == Globals.CHARACTER_TAILS:
		var tail := preload("res://src/game/obj_puppet_tail.gd").new()
		tail.target = pup
		add_child(tail)
