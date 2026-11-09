extends Node2D
## Generic map controller (port of room creation code):
## spawns the player, camera, HUD, debug overlay and art collision; plays the
## room music; feeds the parallax layer list to obj_parallax.

var _spawn_override := Vector2.ZERO
var _dbg_hp := -1
var _dbg_rings := -1
var _dbg_fly = null

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
	# solo map launch (no lobby → no char select): the player runs on the exe
	# movement values (player.gd uses EXE_ACC/EXE_MAXSPEED), so the HUD and the
	# ability icons must describe the exe too. Netplay overwrites both on entry.
	if Globals.character < 0:
		Globals.character = Globals.CHARACTER_EXE
	if Globals.exeCharacter < 0:
		Globals.exeCharacter = Globals.EXE_ORIGINAL
	# dev: DISASTER_CHAR=n — test a survivor's HUD/ability icons without a lobby
	# (1 tails … 6 sally); the character system itself is a later stage
	# dev: DISASTER_HP=n / DISASTER_RINGS=n / DISASTER_FLY=n — the start values
	# (the fly one drains the flight charge so jumps stay plain)
	var _hp := OS.get_environment("DISASTER_HP")
	_dbg_hp = int(_hp) if _hp != "" else -1
	var _rg := OS.get_environment("DISASTER_RINGS")
	_dbg_rings = int(_rg) if _rg != "" else -1
	var _fl := OS.get_environment("DISASTER_FLY")
	_dbg_fly = int(_fl) if _fl != "" else null
	var _ch := OS.get_environment("DISASTER_CHAR")
	if _ch != "":
		Globals.character = clampi(int(_ch), Globals.CHARACTER_TAILS, Globals.CHARACTER_SALLY)
	# the room converter stamps the level id; netplay overwrites Net.lvlId
	if Net.lvlId < 0 and lvl_id >= 0:
		Net.lvlId = lvl_id
	var spawn: Node2D = null
	for n in get_tree().get_nodes_in_group("obj_exespawn"):
		spawn = n
		break
	if spawn == null:
		for n in get_tree().get_nodes_in_group("obj_spawnpoint"):
			spawn = n
			break
	if spawn == null:
		spawn = self

	# dev: DISASTER_SPAWN=x,y — start the player at room coords (map testing)
	var sp_env := OS.get_environment("DISASTER_SPAWN")
	if sp_env != "":
		var xy := sp_env.split(",")
		spawn = null
		_spawn_override = Vector2(float(xy[0]), float(xy[1]))

	var player := Node2D.new()
	player.set_script(load("res://src/game/player.gd"))
	player.position = (_spawn_override if _spawn_override != Vector2.ZERO else spawn.position + Vector2(0, -18))
	add_child(player)
	# after _ready/_apply_character (which sets the character's base hp)
	if _dbg_hp > 0:
		player.hp = _dbg_hp
	if _dbg_rings >= 0:
		player.rings = _dbg_rings
	if _dbg_fly != null:
		player.flyTimer = _dbg_fly

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

	var dbg := Node2D.new()
	dbg.set_script(load("res://src/game/obj_debugcollider.gd"))
	dbg.position = Vector2.ZERO
	add_child(dbg)

	# rings at spawner positions
	for rs in get_tree().get_nodes_in_group("obj_ring_spawner"):
		var ring := Node2D.new()
		ring.set_script(load("res://src/game/obj_ring.gd"))
		ring.position = rs.position   # the original: instance_create_depth(_inst.x, _inst.y, 0, obj_ring) — no offset
		ring.gm_name = "obj_ring"
		add_child(ring)

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

	# dev movement watchdog — logs anything that moves without permission
	var wd := Node.new()
	wd.set_script(load("res://src/game/move_watchdog.gd"))
	wd.name = "MoveWatchdog"
	call_deferred("add_child", wd)  # after all spawns settle

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Net.net_reset()
