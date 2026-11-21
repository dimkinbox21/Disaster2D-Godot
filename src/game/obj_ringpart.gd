extends GMNode
## Port of obj_ringpart — broken ring particles.

var xspd := 0.0
var yspd := 0.0


func _gm_step() -> void:
	position.x += xspd
	position.y += yspd
	yspd += 0.2
	if position.y > 2000:
		queue_free()


func _gm_draw() -> void:
	draw_self()
