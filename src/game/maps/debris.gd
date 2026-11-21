extends GMNode
var motion := Vector2.ZERO
var life := 90


func _gm_step():
	life -= 1
	if sprite_name == "spr_nap_iceblock_part":
		motion.y += 0.2
		motion.x += signf(motion.x) * 0.05
	else:
		motion.y += 0.12
		motion.x = move_toward(motion.x, 0, 0.04)
		sprite_rotation -= 1
	position += motion
	if life <= 0:
		image_alpha -= 0.05
	if image_alpha <= 0:
		queue_free()
