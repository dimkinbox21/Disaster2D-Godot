extends Node2D
## Root of map_deserttown — spawns the EXE player, camera, HUD, parallax,
## sandstorm controller; registers art-collision floors.

func _ready() -> void:
	var spawn: Node2D = null
	for n in get_tree().get_nodes_in_group("obj_spawnpoint"):
		spawn = n
		break
	if spawn == null:
		spawn = self

	var player := Node2D.new()
	player.set_script(load("res://src/game/player.gd"))
	player.position = spawn.position + Vector2(0, -18)
	player.fall_limit_y = 5000.0
	add_child(player)

	var cam := Node2D.new()
	cam.set_script(load("res://src/game/obj_camera.gd"))
	cam.room_w = 3296.0
	cam.room_h = 1350.0
	cam.position = player.position
	add_child(cam)

	var level := Node2D.new()
	level.set_script(load("res://src/game/obj_level.gd"))
	level.position = Vector2.ZERO
	add_child(level)

	var par := Node2D.new()
	par.set_script(load("res://src/game/obj_parallax.gd"))
	add_child(par)
	# port of the room creation code global.parallax list
	par.layers = [
		[_bg("Background"), 0.8, 1.0, 0.0],
		[_bg("Background2"), 0.9, 1.0, 0.0],
		[_bg("Background3"), 0.7, 1.0, 136.0],
		[_bg("Background4"), 0.6, 1.0, 151.0],
		[_bg("Background5"), 0.5, 1.0, 182.0],
		[_bg("Background6"), 0.4, 1.0, 216.0],
	]

	# rings at spawner positions
	for rs in get_tree().get_nodes_in_group("obj_ring_spawner"):
		var ring := Node2D.new()
		ring.set_script(load("res://src/game/obj_ring.gd"))
		ring.position = rs.position + Vector2(0, 16)
		ring.gm_name = "obj_ring"
		add_child(ring)

	var dbg := Node2D.new()
	dbg.set_script(load("res://src/game/obj_debugcollider.gd"))
	dbg.position = Vector2.ZERO
	add_child(dbg)


func _bg(layer_name: String) -> Node2D:
	var n := find_child(layer_name, true, false)
	return n

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Net.net_reset()
