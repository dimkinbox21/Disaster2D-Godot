extends GMNode
var velocity := Vector2.ZERO
var direction := 1
var age := 0


func _ready():
	super._ready()
	image_index = randi_range(0, maxi(0, GM.sprite_count(sprite_name) - 1))
	image_speed = 0


func _gm_step():
	age += 1
	velocity.y += 0.2
	velocity.x += direction * 0.05
	position += velocity
	if age > 180 or GMFloor.point_meeting_floor(position.x, position.y):
		queue_free()
