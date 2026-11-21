class_name GMNode
extends Node2D
## Base for all GameMaker-port objects: sprite animation, depth, draw helpers,
## GML-style input/mouse helpers. Logic runs at fixed 60 Hz in _physics_process,
## mirroring the original's frame-based step events.

@export_storage var sprite_name := ""
@export_storage var image_index := 0.0
@export_storage var image_speed := 1.0
var image_blend := Color.WHITE
var image_alpha := 1.0
## GM object "visible" flag: false = helper object (solid blocks, spawns,
## angleanullers...) — never drawn, but collision/groups still work
@export_storage var gm_visible := true
## static map object (no step logic): skips _physics_process entirely —
## 250+ per-frame GDScript calls saved; redraw on external change is the
## mutator's job (queue_redraw after setting image_alpha etc.)
@export_storage var gm_static := false
var pixel_snap := false  # Game actors share the camera world-pixel lattice.
@export_storage var image_xscale := 1.0
@export_storage var image_yscale := 1.0
@export_storage var sprite_rotation := 0.0
## GameMaker depth (higher = drawn behind). z_index derives from it.
@export_storage var depth := 0.0

var _anim_accum := 0.0

## GameMaker object name (set by the scene generator), plus parent chain map
## mirroring the original object inheritance for group lookups.
@export_storage var gm_name := ""

const PARENT_OF := {
	"obj_menu_togglebutton": "obj_menu_button",
	"obj_menu_skin": "obj_menu_button",
	"obj_menu_icon": "obj_menu_button",
	"obj_menu_taunt": "obj_menu_button",
	"obj_menu_pet": "obj_menu_button",
	"obj_menu_serverbutton": "obj_menu_button",
	"obj_menu_link2": "obj_menu_link1",
	"obj_menu_mobilebutton2": "obj_menu_mobilebutton",
}


func _ready() -> void:
	# GameMaker draw order: depth descending. z_index = -depth (absolute).
	z_as_relative = false
	z_index = clampi(-int(depth), -4096, 4096)
	if gm_static:
		set_physics_process(false)
	var n := gm_object_name()
	while n != "" and n != "gm_node":
		add_to_group(n)
		n = PARENT_OF.get(n, "")


func gm_object_name() -> String:
	return gm_name


## Frame-based step. Override in subclasses.
func _gm_step() -> void:
	pass


## GameMaker Other_7, invoked after a looping animation crosses its end.
func _gm_animation_end() -> void:
	pass


func _gm_interact() -> void:
	pass


## Draw event. Override in subclasses. Draw in LOCAL coordinates
## (node position is applied by the transform); GMNode provides helpers that
## accept room coordinates and convert.
func _gm_draw() -> void:
	draw_self()


var _last_pos := Vector2(1e9, 1e9)
var _last_img := -1.0
var _last_alpha := -1.0
var _last_blend := Color(-1, -1, -1, -1)
var _last_sprite := ""
var _last_scale := Vector2(-1.0, -1.0)
var _last_rot := 1e9


func _physics_process(delta: float) -> void:
	# advance animation like GML image_speed (sprite playbackSpeed, FPS type)
	var _anim_changed := false
	if sprite_name != "" and GM.sprites.has(sprite_name):
		var m := GM.sprite_meta(sprite_name)
		var per_step := 0.0
		if m["playbackSpeedType"] == 0:
			per_step = image_speed * float(m["playbackSpeed"]) / 60.0
		else:
			per_step = image_speed * float(m["playbackSpeed"])
		var count := GM.sprite_count(sprite_name)
		if count > 0 and per_step != 0.0 and int(m.get("playbackMode", 1)) != 0:
			_anim_accum += per_step
			if _anim_accum >= 1.0 or _anim_accum <= -1.0:
				image_index += floorf(_anim_accum)
				_anim_accum = fmod(_anim_accum, 1.0)
				if int(m["playbackMode"]) == 1:
					var finished := image_index >= count or image_index < 0
					image_index = wrapf(image_index, 0, count)
					if finished:
						_gm_animation_end()
				else:
					image_index = clampf(image_index, 0, count - 1)
				_anim_changed = true
	_gm_step()
	if get_meta("menu_live_draw", false) and gm_visible and is_visible_in_tree():
		_gm_interact()
		queue_redraw()
	# redraw only when something actually changed (perf: 300 static nodes).
	# The original's Draw event runs every frame, so anything an object (or another
	# object) writes into its draw state must be tracked here — position/alpha/blend
	# plus the sprite, frame, scale and rotation. Missing these left the lobby icon
	# frozen at its first (half-scaled) frame and made external image_index writes
	# (obj_movingspike) invisible without an explicit queue_redraw().
	if (
		_anim_changed
		or position != _last_pos
		or image_alpha != _last_alpha
		or image_blend != _last_blend
		or image_index != _last_img
		or sprite_name != _last_sprite
		or image_xscale != _last_scale.x
		or image_yscale != _last_scale.y
		or sprite_rotation != _last_rot
	):
		_last_pos = position
		_last_img = image_index
		_last_alpha = image_alpha
		_last_blend = image_blend
		_last_sprite = sprite_name
		_last_scale = Vector2(image_xscale, image_yscale)
		_last_rot = sprite_rotation
		queue_redraw()


func _draw() -> void:
	if gm_visible:
		_gm_draw()


# ------------------------------------------------------------- drawing helpers
func pixel_draw_offset() -> Vector2:
	return to_local(global_position.floor()) if pixel_snap else Vector2.ZERO


func frame_texture() -> Texture2D:
	return GM.sprite_texture(sprite_name, int(image_index))


func draw_self() -> void:
	# GM visible=false: no draw, but collision/group checks stay active
	if sprite_name == "" or not gm_visible:
		return
	var tex := frame_texture()
	if tex == null:
		return
	var m := GM.sprite_meta(sprite_name)
	var origin := Vector2(m["xorigin"], m["yorigin"])
	# GM draw semantics: the origin lands on the instance position, the art is
	# scaled and rotated ABOUT the origin — so -origin must be INSIDE the
	# rotated transform, not outside it (an unrotated -origin·scale offset
	# threw every rotated sprite off its instance position)
	draw_set_transform(
		pixel_draw_offset(), deg_to_rad(sprite_rotation), Vector2(image_xscale, image_yscale)
	)
	draw_texture(tex, -origin, Color(image_blend, image_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_sprite(
	name_: String,
	index: float,
	x: float,
	y: float,
	xscale := 1.0,
	yscale := 1.0,
	rot := 0.0,
	col := GM.C_WHITE,
	alpha := 1.0
) -> void:
	var tex := GM.sprite_texture(name_, int(index))
	if tex == null:
		return
	var m := GM.sprite_meta(name_)
	var origin := Vector2(m["xorigin"], m["yorigin"])
	var local := to_local(Vector2(x, y))
	var colf := Color(col, alpha)
	draw_set_transform(local, deg_to_rad(rot), Vector2(xscale, yscale))
	draw_texture(tex, -origin, colf)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## draw_sprite_part_ext port (source rect from sprite frame)
func draw_sprite_part(
	name_: String,
	index: int,
	src: Rect2,
	x: float,
	y: float,
	xscale := 1.0,
	yscale := 1.0,
	col := GM.C_WHITE,
	alpha := 1.0
) -> void:
	var tex := GM.sprite_texture(name_, index)
	if tex == null:
		return
	var m := GM.sprite_meta(name_)
	var origin := Vector2(m["xorigin"], m["yorigin"])
	var local := to_local(Vector2(x, y))
	draw_texture_rect_region(
		tex, Rect2(local - origin, src.size * Vector2(xscale, yscale)), src, Color(col, alpha)
	)


# ------------------------------------------------------------- GML-ish queries
func sprite_width() -> float:
	if sprite_name == "":
		return 0
	return float(GM.sprite_meta(sprite_name)["w"]) * image_xscale


func sprite_height() -> float:
	if sprite_name == "":
		return 0
	return float(GM.sprite_meta(sprite_name)["h"]) * image_yscale


func bbox_rect() -> Rect2:
	if sprite_name == "":
		return Rect2(position.x, position.y, 0, 0)
	var m := GM.sprite_meta(sprite_name)
	var bm: int = int(m.get("bboxMode", 1))
	var l: float
	var t: float
	var r: float
	var b: float
	if bm == 1:
		l = 0
		t = 0
		r = float(m["w"]) - 1
		b = float(m["h"]) - 1
	else:
		l = float(m["bbox"][0])
		t = float(m["bbox"][1])
		r = float(m["bbox"][2])
		b = float(m["bbox"][3])
	# GM: bbox in room space = x - xoffset + bbox_left (origin-aware)
	var ox := float(m["xorigin"]) * image_xscale
	var oy := float(m["yorigin"]) * image_yscale
	var x0 := position.x - ox + l * image_xscale
	var y0 := position.y - oy + t * image_yscale
	var x1 := position.x - ox + (r + 1) * image_xscale
	var y1 := position.y - oy + (b + 1) * image_yscale
	if sprite_rotation == 0.0:
		return Rect2(minf(x0, x1), minf(y0, y1), absf(x1 - x0), absf(y1 - y0))
	# rotated instance: GM collision uses the AABB of the mask rotated around
	# the origin — rotate the four corners and take the bounding box
	var rad := deg_to_rad(sprite_rotation)
	var cs := cos(rad)
	var sn := sin(rad)
	var pmin := Vector2(INF, INF)
	var pmax := Vector2(-INF, -INF)
	for cx: float in [x0, x1]:
		for cy: float in [y0, y1]:
			# corner relative to the origin point (position), rotated
			var dx: float = cx - position.x
			var dy: float = cy - position.y
			var px: float = position.x + dx * cs - dy * sn
			var py: float = position.y + dx * sn + dy * cs
			pmin.x = minf(pmin.x, px)
			pmin.y = minf(pmin.y, py)
			pmax.x = maxf(pmax.x, px)
			pmax.y = maxf(pmax.y, py)
	return Rect2(pmin, pmax - pmin)


## position_meeting(mouse_x, mouse_y, self) port — point vs bbox
func position_meeting(px: float, py: float) -> bool:
	return bbox_rect().has_point(Vector2(px, py))


## GM point-vs-mask for ROTATED instances: the mask rectangle rotates with the
## sprite (OBB), not its AABB — this is what makes rotated solid blocks
## walkable ramps. Unrotated instances = plain bbox test.
func point_in_mask(px: float, py: float) -> bool:
	if sprite_name == "":
		return false
	var m := GM.sprite_meta(sprite_name)
	var bm: int = int(m.get("bboxMode", 1))
	var l: float
	var t: float
	var r: float
	var b: float
	if bm == 1:
		l = 0
		t = 0
		r = float(m["w"]) - 1
		b = float(m["h"]) - 1
	else:
		l = float(m["bbox"][0])
		t = float(m["bbox"][1])
		r = float(m["bbox"][2])
		b = float(m["bbox"][3])
	var lx: float = px - position.x
	var ly: float = py - position.y
	if sprite_rotation != 0.0:
		var rad := deg_to_rad(sprite_rotation)
		var cs := cos(rad)
		var sn := sin(rad)
		var rx := lx * cs + ly * sn
		var ry := -lx * sn + ly * cs
		lx = rx
		ly = ry
	var ox := float(m["xorigin"])
	var oy := float(m["yorigin"])
	lx = lx / image_xscale + ox
	ly = ly / image_yscale + oy
	return lx >= l and lx < r + 1.0 and ly >= t and ly < b + 1.0


func mouse_pressed_over(button := 0) -> bool:
	return GM.mouse_pressed(button) and position_meeting(GM.mouse_x, GM.mouse_y)


func mouse_over(button := 0) -> bool:
	return GM.mouse_down(button) and position_meeting(GM.mouse_x, GM.mouse_y)


func mouse_released_over(button := 0) -> bool:
	return GM.mouse_released(button) and position_meeting(GM.mouse_x, GM.mouse_y)


## find instances of a GM object type (group)
static func all_of(group: String) -> Array:
	return gm_scene_root().get_tree().get_nodes_in_group(group) if gm_scene_root() else []


static func gm_scene_root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene


# key helpers forwarding to GM with Globals binds
func kp(code: int) -> bool:
	return GM.key_pressed(code)


func kd(code: int) -> bool:
	return GM.key_down(code)
