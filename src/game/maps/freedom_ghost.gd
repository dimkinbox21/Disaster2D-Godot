extends GMNode
var direction = 1.0
var xx = 0.0
var yy = 0.0
var age = 0
var phase = randf_range(0, 2000)


func _ready():
	yy = position.y
	super._ready()
	process_physics_priority = 120


func _gm_step():
	age += 1
	xx += direction
	for camera in all_of("obj_camera"):
		position = (
			camera.render_origin + Vector2(xx, yy + sin(Time.get_ticks_msec() / 300.0 + phase) * 10)
		)
		break
	image_xscale = signf(direction) * (-1 if sprite_name == "spr_weed_prizraks" else 1)
	if age > 1800 or xx > 480 + sprite_width() + 64 or xx < -128:
		queue_free()
