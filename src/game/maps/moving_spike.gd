extends GMFloor


func _ready():
	canStuck = false
	gm_static = false
	gm_visible = true
	image_speed = 0
	super._ready()
	change(0)


func change(frame: int):
	image_index = frame
	collision_active = frame > 0 and frame < 5
	_bbox_cached = false
	_mcached = false
	queue_redraw()


func bbox_rect() -> Rect2:
	return Rect2(position, Vector2(32, 32))


func point_in_mask(px: float, py: float) -> bool:
	return collision_active and bbox_rect().has_point(Vector2(px, py))
