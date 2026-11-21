extends GMNode
var grounded := false
var speed := randf_range(2.5, 5)
var age := 0


func _gm_step():
	age += 1
	if not grounded:
		position.y += speed
		# Source can loop forever inside a thick floor. A bounded probe is sufficient
		# for a cosmetic drop; discard it if no surface can be found nearby.
		for attempt in 32:
			if not GMFloor.point_meeting_floor(position.x, position.y):
				break
			position.y = floorf(position.y) - 1
			grounded = true
		image_index = 0
	if age > 600 or (grounded and image_index >= GM.sprite_count(sprite_name) - 1):
		queue_free()
