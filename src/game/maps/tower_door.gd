extends GMFloor
var origin := Vector2.ZERO


func _ready():
	origin = position
	canStuck = false
	super._ready()


func cached_bbox() -> Rect2:
	return bbox_rect()


func grid_bbox() -> Rect2:
	var box := bbox_rect()
	return box.merge(
		Rect2(
			(
				box.position
				- (Vector2(box.size.x, 0) if gm_name == "obj_hd_door2" else Vector2(0, box.size.y))
			),
			box.size
		)
	)
