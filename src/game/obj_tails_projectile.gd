extends GMNode
## Port of obj_tails_projectile — Tails' charged tail shot.
## The original is fully server-authoritative (the server spawns/moves/destroys it
## and broadcasts TPROJECTILE_STATE). Solo runs it locally: it flies in the facing
## direction, dies on solid collision and plays the charge-tier death sprite.

var is_owner := false
var is_breaking := false
var is_exe := false
var dmg := 0
var charge := 0
var xspd := 0.0
var life := 0

const SPEED := 8.0
const MAX_LIFE := 90

func _ready() -> void:
	super._ready()
	gm_name = "obj_tails_projectile"  # spawned dynamically — must self-stamp its group
	sprite_name = "spr_tails_ray"
	image_index = float(charge)   # SERVER_TPROJECTILE_STATE: image_index = _charge —
	                              # the tier IS the frame (6 pre-colored frames, playbackSpeed 0)
	image_speed = 1.2
	z_index = 5
	xspd = SPEED * image_xscale

func _gm_step() -> void:
	if is_breaking:
		if int(image_index) >= GM.sprite_count(sprite_name) - 1:
			queue_free()
		return
	life += 1
	position.x += xspd
	# solid collision or lifetime ends the shot
	var hit := GMFloor.point_meeting_floor(position.x, position.y)
	if hit or life > MAX_LIFE or position.x < 0.0:
		_destroy()

func _destroy() -> void:
	if is_breaking:
		return
	is_breaking = true
	match charge:
		0: sprite_name = "spr_tail_ray_dead"
		1: sprite_name = "spr_tail_ray_dead1"
		2: sprite_name = "spr_tail_ray_dead2"
		3: sprite_name = "spr_tail_ray_dead3"
		_: sprite_name = "spr_tail_ray_dead4"
	image_speed = 1.2
	image_index = 0.0
	queue_redraw()

func _gm_draw() -> void:
	draw_self()
