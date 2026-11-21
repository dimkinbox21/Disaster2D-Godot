extends GMNode
var velocity = Vector2.ZERO
var age = 0
var stopped = false


func _ready():
	super._ready()
	image_index = randi_range(0, maxi(0, GM.sprite_count(sprite_name) - 1))
	image_speed = 0
	depth = 249
	z_index = -249


func _gm_step():
	age += 1
	var map = get_tree().current_scene
	if map != null and map.get("room_h") != null and position.y > map.room_h + 256:
		queue_free()
		return
	if stopped:
		set_physics_process(false)
		return
	position += velocity
	if (
		GMFloor.point_meeting_floor(bbox_rect().end.x + velocity.x, position.y - 1)
		or GMFloor.point_meeting_floor(bbox_rect().position.x + velocity.x, position.y - 1)
	):
		velocity.x = 0
	if GMFloor.point_meeting_floor(position.x, position.y + 4):
		velocity.x = move_toward(velocity.x, 0, 0.1)
		velocity.y = 0
		stopped = is_zero_approx(velocity.x)
	else:
		velocity.y += 0.32
		sprite_rotation += velocity.x
