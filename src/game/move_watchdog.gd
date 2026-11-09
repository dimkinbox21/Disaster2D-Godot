extends Node
## Dev movement watchdog (requested by the user): snapshots every scene node's
## position and logs ANY unexpected mover to da.log with the camera position,
## so camera-following map objects can be caught from a normal play session.
##
## Allowed to move (by gm_name / script): player, camera, controllers,
## parallax/background layers, rings + their parts, movingspike.
## Everything else in a level scene must stay world-fixed — a single moving
## tile/ladder/block line in da.log is the bug report.

const ALLOWED_GM := ["obj_player","obj_camera","obj_deserttown_i","obj_dotdotdot_i","obj_parallax","obj_ring","obj_ringpart","obj_level","obj_level_hud","obj_movingspike","obj_quickfx"]
const ALLOWED_SCRIPT := ["gm_background.gd","obj_camera.gd","map_controller.gd","player.gd","obj_deserttown_i.gd","obj_dotdotdot_i.gd","obj_parallax.gd","obj_ring.gd","obj_ringpart.gd","obj_movingspike.gd","obj_level.gd","obj_level_hud.gd","move_watchdog.gd","obj_quickfx.gd"]

var _snap: Dictionary = {}   # Node2D -> Vector2
var _seen_moved: Dictionary = {}  # node -> [from, to, count]
var _frame := 0
var _log_path := "user://da.log"
var _log_path2 := ""   # resolved in _ready: <project dir>/da.log
var _cam: Node2D = null

func _ready() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	_collect(root)
	# project-folder copy: da.log next to the game (res:// is read-only at runtime)
	_log_path2 = ProjectSettings.globalize_path("res://").path_join("da.log")
	# start both logs fresh
	for p: String in [_log_path, _log_path2]:
		var fw := FileAccess.open(p, FileAccess.WRITE)
		if fw:
			fw.store_string("=== move watchdog @ %s | nodes=%d ===\n" %
				[Time.get_datetime_string_from_system(), _snap.size()])
			fw.close()
	var f := FileAccess.open(_log_path, FileAccess.WRITE)
	print("WATCHDOG nodes=", _snap.size(), " path=", _log_path2, " file_ok=", f != null)
	if f:
		f.store_string("=== move watchdog @ %s | nodes=%d ===\n" %
			[Time.get_datetime_string_from_system(), _snap.size()])
		f.close()

func _collect(n: Node) -> void:
	for c in n.get_children():
		_collect(c)
	# Camera2D children ride the camera node — allowed by construction
	if n is Camera2D:
		return
	if n is Node2D and not _allowed(n) and not _under_camera(n):
		# global: catches children of moving parents (local pos would not change)
		_snap[n] = n.global_position

func _under_camera(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is Node2D and p is GMNode and (p as GMNode).gm_name == "obj_camera":
			return true
		if p is Camera2D:
			return true
		p = p.get_parent()
	return false

func _allowed(n: Node) -> bool:
	var gm := ""
	if n is GMNode:
		gm = (n as GMNode).gm_name
	if ALLOWED_GM.has(gm):
		return true
	var sc: Script = n.get_script()
	if sc and ALLOWED_SCRIPT.has(sc.resource_path.get_file()):
		return true
	return false

func _physics_process(_d: float) -> void:
	_frame += 1
	if _frame % 30 != 0:
		return
	if _cam == null:
		for c in get_tree().get_nodes_in_group("obj_camera"):
			_cam = c
			break
	if _cam == null:
		return
	var changed := false
	for node in _snap:
		if not is_instance_valid(node):
			continue
		var now: Vector2 = node.global_position
		var was: Vector2 = _snap[node]
		if not now.is_equal_approx(was):
			if not _seen_moved.has(node):
				_seen_moved[node] = [was, now, 1]
				changed = true
			else:
				var rec: Array = _seen_moved[node]
				rec[1] = now
				rec[2] = int(rec[2]) + 1
	if changed:
		_flush()
	# keep the snapshot current for still-static nodes is NOT needed; watchers
	# report first-move + running count, so a genuine fix clears da.log itself

func _flush() -> void:
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	_flush_to(f)
	f.close()
	# project-folder copy — da.log next to the game (easy to find)
	var f2 := FileAccess.open(_log_path2, FileAccess.READ_WRITE)
	if f2:
		f2.seek_end()
		_flush_to(f2)
		f2.close()

func _flush_to(f: FileAccess) -> void:
	f.store_string("--- frame %d cam=(%.1f, %.1f) ---\n" % [_frame, _cam.position.x, _cam.position.y])
	for node in _seen_moved:
		if not is_instance_valid(node):
			continue
		var rec: Array = _seen_moved[node]
		var gm := ""
		var spr := ""
		if node is GMNode:
			gm = (node as GMNode).gm_name
			spr = (node as GMNode).sprite_name
		var sc: Script = node.get_script()
		f.store_string("MOVED %s gm=%s spr=%s script=%s  %s -> %s  (x%d)\n" % [
			node.name, gm, spr,
			sc.resource_path.get_file() if sc else "none",
			rec[0], rec[1], int(rec[2])])
