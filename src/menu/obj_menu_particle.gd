extends GMNode
## Port of obj_menu_particle.

var yy := -1.0
var xspd := 0.2

func _ready() -> void:
	super._ready()
	yy = -1.0
	var choices := [0.1, 0.2, 0.3, 0.4]
	xspd = choices[randi() % choices.size()]
	z_index = clampi(-1999, -4096, 4096)

func _gm_step() -> void:
	if yy == -1:
		yy = position.y
	position.x -= xspd
	if position.x < -16:
		position.x = 480.0
	position.y = yy + sin(Time.get_ticks_msec() / 500.0) * 2.0
	image_alpha = 0.5 + ((1.0 + sin(Time.get_ticks_msec() / 200.0)) / 2.0) * 0.5
