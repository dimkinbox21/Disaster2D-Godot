extends GMFloor
var nid := 0


func grid_bbox() -> Rect2:
	return Rect2(-2304, -832, 10624, 2912)


func cached_bbox() -> Rect2:
	return bbox_rect()


func move_wall(at: Vector2) -> void:
	position = at
	queue_redraw()
