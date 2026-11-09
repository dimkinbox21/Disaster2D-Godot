extends GMNode
## Debug collision visualizer — F3 toggles. Draws every floor bbox over the
## art: red = solid floor, green = jump-through platform. Lets you SEE
## art-vs-collision mismatches while walking.

var enabled := false

func _ready() -> void:
	super._ready()
	z_as_relative = false
	z_index = 4095
	if OS.get_environment("SHOW_COLL") == "1":
		enabled = true  # dev: collision overlay without pressing F3

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		enabled = not enabled
		queue_redraw()

func _gm_step() -> void:
	if enabled:
		queue_redraw()

func _gm_draw() -> void:
	if not enabled:
		return
	for f in GMNode.all_of("gm_floor"):
		if not is_instance_valid(f) or not f.visible:
			continue
		var r: Rect2 = f.cached_bbox()
		var jt: bool = f.is_in_group("gm_jumpthrough")
		var fill := Color(0, 1, 0, 0.25) if jt else Color(1, 0.1, 0.1, 0.30)
		var line := Color(0, 1, 0, 0.9) if jt else Color(1, 0.2, 0.2, 0.95)
		if f.sprite_rotation != 0.0:
			# rotated block: draw the actual rotated mask (OBB), not its AABB
			var m: Dictionary = GM.sprite_meta(f.sprite_name)
			var sx: float = f.image_xscale
			var sy: float = f.image_yscale
			var lx: float = (float(m["bbox"][0]) - float(m["xorigin"])) * sx
			var ly: float = (float(m["bbox"][1]) - float(m["yorigin"])) * sy
			var lw: float = (float(m["bbox"][2]) - float(m["bbox"][0]) + 1.0) * sx
			var lh: float = (float(m["bbox"][3]) - float(m["bbox"][1]) + 1.0) * sy
			draw_set_transform(f.position, deg_to_rad(f.sprite_rotation), Vector2.ONE)
			draw_rect(Rect2(lx, ly, lw, lh), fill)
			draw_rect(Rect2(lx, ly, lw, lh), line, false, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_rect(r, fill)
			draw_rect(r, line, false, 1.0)
	# player feet marker
	for p in GMNode.all_of("obj_player"):
		draw_rect(Rect2(p.position.x - 8, p.position.y - 16, 16, 36), Color(0, 0.6, 1, 0.5), false, 1.0)
	# camera view border
	for c in GMNode.all_of("obj_camera"):
		draw_rect(Rect2(c.position.x, c.position.y, 480, 270), Color(1, 1, 0, 0.6), false, 1.0)
