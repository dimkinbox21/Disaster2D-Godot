extends GMFloor
## Art-derived collision: invisible floor generated from uncovered
## front-layer art surfaces (collision by art). Custom rect instead of sprite.

var frect := Rect2(0, 0, 32, 32)

func cached_bbox() -> Rect2:
	return frect

func bbox_rect() -> Rect2:
	return frect

func _gm_draw() -> void:
	if OS.get_environment("SHOW_BLOCKS") == "1":
		draw_rect(frect, Color(1, 1, 0, 0.3))
