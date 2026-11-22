extends GMNode
## Original ring fragments slide on the map, slow down and fade before deletion.
const GRAVITY := 0.32
const FLOOR_FRICTION := 0.0512
const MAX_SEPARATION_STEPS := 256
var xspd := 0.0
var yspd := 0.0
var life_ticks := 0


func _ready() -> void:
	gm_name = "obj_ringpart"
	image_speed = 0.0
	life_ticks = randi_range(7, 9) * 60
	if Net.lvlId == 8:
		image_blend = GM.C_DKGRAY
	super._ready()


func _gm_step() -> void:
	life_ticks -= 1
	if life_ticks <= 0:
		queue_free()
		return
	if life_ticks < 60:
		image_alpha = life_ticks / 60.0
	sprite_rotation -= xspd
	var count := GM.sprite_count(sprite_name)
	if count > 0:
		image_index = wrapf(image_index + (yspd + xspd) * 0.1, 0, count)
	# Sweep in pixel-sized steps so fast fragments cannot cross a thin floor.
	var steps := maxi(1, ceili(maxf(absf(xspd), absf(yspd))))
	for step in steps:
		position += Vector2(xspd, yspd) / steps
		var box := bbox_rect()
		var lookahead := xspd / steps
		if (
			GMFloor.point_meeting_floor(box.end.x - 1 + lookahead, position.y - 1)
			or GMFloor.point_meeting_floor(box.position.x + lookahead, position.y - 1)
		):
			xspd = 0
		# Bound separation even when a fragment starts inside a large solid.
		for correction in MAX_SEPARATION_STEPS:
			if not GMFloor.point_meeting_floor(position.x, position.y + 4):
				break
			yspd = 0
			position.y -= 1
	if GMFloor.point_meeting_floor(position.x, position.y + 5):
		xspd -= minf(absf(xspd), FLOOR_FRICTION) * signf(xspd)
		return
	yspd += GRAVITY
