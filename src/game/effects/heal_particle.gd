extends GMNode
var speed = 0.0
var sway = 4.0
var phase = 0.0
var fade_rate = 0.016
var start_x = 0.0


func _ready():
	gm_name = "obj_heal_particle"
	sprite_name = "spr_heal_part"
	depth = -10
	image_speed = 0
	image_index = randi_range(0, 1)
	speed = randf_range(-2, -1)
	sway = randi_range(4, 8)
	phase = randf() * 9999
	fade_rate = [0.016, 0.032, 0.064].pick_random()
	start_x = position.x
	super._ready()


func _gm_step():
	image_alpha -= fade_rate
	if image_alpha <= 0:
		queue_free()
		return
	position.y += speed
	position.x = start_x + sin((Time.get_ticks_msec() + phase) / 300.0) * sway
