extends Node
## Debug screenshot helper (dev only): env DISASTER_SHOT=<path.png>,
## DISASTER_SHOT_FRAME=<frame>, optional DISASTER_SHOT_KEYS="right,confirm,click@245,252".
## Logical names resolve through the CURRENT key binds (tests keep working
## after the user rebinds); "click@X,Y" warps the mouse and clicks.

var shots: Array = []   # [[frame, path], ...]
var hold_key := ""
var hold_until := -1
var hold_from := 100
var keys: PackedStringArray = []
var frame := 0

func _ready() -> void:
	var spec := OS.get_environment("DISASTER_SHOT")
	if spec == "":
		set_physics_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	if spec.contains("|"):
		for part in spec.split("|"):
			var fp := part.split("=", false, 1)
			if fp.size() == 2:
				shots.append([int(fp[0]), fp[1]])
	elif spec.contains("=") and spec.split("=")[0].is_valid_int():
		var fp := spec.split("=", false, 1)
		shots.append([int(fp[0]), fp[1]])
	else:
		var f := OS.get_environment("DISASTER_SHOT_FRAME")
		shots.append([int(f) if f != "" else 60, spec])
	var k := OS.get_environment("DISASTER_SHOT_KEYS")
	if k != "":
		keys = k.split(",")
	var h := OS.get_environment("DISASTER_HOLD")
	if h != "":
		var parts := h.split(":")
		hold_key = parts[0]
		hold_until = int(parts[2]) if parts.size() > 2 else 1 << 30
		hold_from = int(parts[1]) if parts.size() > 1 else 100

func _resolve(code_str: String) -> int:
	match code_str:
		"right": return Globals.KeyRight
		"left": return Globals.KeyLeft
		"up": return Globals.KeyUp
		"down": return Globals.KeyDown
		"confirm": return Globals.KeyA
		"back": return Globals.KeyB
		"special2": return Globals.KeyC
		"enter": return KEY_ENTER
		"escape": return KEY_ESCAPE
		_: return OS.find_keycode_from_string(code_str)

func _physics_process(_d: float) -> void:
	frame += 1
	if OS.get_environment("DISASTER_TRACE") == "1" and frame % 30 == 0:
		var cs2 := get_tree().current_scene
		if cs2 and cs2.scene_file_path.ends_with("map_dotdotdot.tscn") and frame % 300 == 0:
			for ch in cs2.get_children():
				var sn: String = ch.get("sprite_name") if "sprite_name" in ch else ""
				var vis: bool = ch.visible if ch is CanvasItem else true
				var z: int = ch.z_index if ch is Node2D else 0
				var texs: int = GM.sprite_count(sn) if sn != "" else -1
				print("NODE ", ch.name, " script=", (ch.get_script().resource_path.get_file() if ch.get_script() else "none"),
					" spr=", sn, " tex=", texs, " vis=", vis, " z=", z, " pos=", (ch.position if ch is Node2D else Vector2.ZERO))
		var cs := get_tree().current_scene
		var pl = null
		if cs:
			var pls := cs.get_tree().get_nodes_in_group("obj_player")
			pl = pls[0] if pls.size() > 0 else null
		var lobby_info := "none"
		var lbs := get_tree().get_nodes_in_group("obj_lobby")
		if lbs.size() > 0:
			lobby_info = "state=%s fade=%.2f" % [lbs[0].state, lbs[0].fade]
		print("TRACE f=", frame, " scene=", (cs.scene_file_path if cs else "null"),
			" netstate=", Net.state, " lvlId=", Net.lvlId,
			" player=", (str(pl.position) + " g=" + str(pl.isGrounded) + " xspd=%.2f" % pl.xspd + " kdR=" + str(pl.kd(39))
				+ " hp=" + str(pl.hp) + " hurt=" + str(pl.isHurt)
				+ " dead=" + str(pl.get("isDead")) + " rev=" + str(pl.get("revivalTimes"))
				+ " rings=" + str(pl.get("rings")) + " fly=" + str(pl.get("flyTimer"))
				+ " chg=" + str(pl.get("attackCharge"))) if pl else "NONE",
			" lobby=", lobby_info,
			" phys=%.2fms proc=%.2fms fps=%d" % [Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_FPS)])
	# hold: press at hold_from, release at hold_until
	if hold_key != "" and frame == hold_from:
		var gmvk2: int = _resolve(hold_key)
		var code2: int = GM._GM_TO_GODOT.get(gmvk2, gmvk2)
		var ev3 := InputEventKey.new()
		ev3.keycode = code2 as Key
		ev3.physical_keycode = code2 as Key
		ev3.unicode = code2 if code2 < 128 else 0
		ev3.pressed = true
		Input.parse_input_event(ev3)
		Input.flush_buffered_events()
		print("HOLD ", hold_key)
	if hold_key != "" and frame == hold_until:
		var gmvk3: int = _resolve(hold_key)
		var code3: int = GM._GM_TO_GODOT.get(gmvk3, gmvk3)
		var ev4 := InputEventKey.new()
		ev4.keycode = code3 as Key
		ev4.physical_keycode = code3 as Key
		ev4.pressed = false
		Input.parse_input_event(ev4)
		Input.flush_buffered_events()
		hold_key = ""
		print("RELEASED")
	var key_idx := (frame - 20) / 20
	if frame >= 20 and (frame - 20) % 20 == 0 and key_idx < keys.size():
		var act := keys[key_idx]
		if act.begins_with("click@"):
			var xy := act.substr(6).split("_")
			var pos := Vector2(float(xy[0]), float(xy[1]))
			get_viewport().warp_mouse(pos)
			var mv := InputEventMouseMotion.new()
			mv.position = pos
			mv.global_position = pos
			Input.parse_input_event(mv)
			Input.flush_buffered_events()
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = true
			mb.position = pos
			mb.global_position = pos
			Input.parse_input_event(mb)
			Input.flush_buffered_events()
			var mb2 := mb.duplicate()
			mb2.pressed = false
			Input.parse_input_event.call_deferred(mb2)
			print("INJECT click ", pos)
		else:
			var gmvk := _resolve(act)
			var code: int = GM._GM_TO_GODOT.get(gmvk, gmvk)
			print("INJECT ", act, " gmvk=", gmvk)
			if code != KEY_NONE:
				var ev := InputEventKey.new()
				ev.keycode = code as Key
				ev.physical_keycode = code as Key
				ev.unicode = code if code < 128 else 0
				ev.pressed = true
				Input.parse_input_event(ev)
				Input.flush_buffered_events()
				var ev2 := ev.duplicate()
				ev2.pressed = false
				Input.parse_input_event.call_deferred(ev2)
	var remaining := []
	for sh in shots:
		if frame >= int(sh[0]):
			var img := get_viewport().get_texture().get_image()
			img.save_png(sh[1])
			print("SHOT_SAVED ", sh[1])
		else:
			remaining.append(sh)
	shots = remaining
	if shots.is_empty():
		get_tree().quit()
