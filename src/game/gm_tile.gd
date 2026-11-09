extends GMNode
## Level tile chunk (scr_level_split + obj_tile port):
## draws the 1024x1024 region (chunk_x, chunk_y) of frame `image_index`
## at the node position — assembling the level art without overlaps.

var chunk_x := 0
var chunk_y := 0

func _gm_draw() -> void:
	var tex := GM.sprite_texture(sprite_name, int(image_index))
	if tex == null:
		return
	var sw := float(GM.sprite_meta(sprite_name)["w"])
	var sh := float(GM.sprite_meta(sprite_name)["h"])
	var rw := minf(1024.0, sw - chunk_x)
	var rh := minf(1024.0, sh - chunk_y)
	if rw <= 0 or rh <= 0:
		return
	# image_alpha carries the obj_deserttown_i front-wall fade (draw_sprite_part_ext alpha)
	draw_texture_rect_region(tex, Rect2(Vector2.ZERO, Vector2(rw, rh)), Rect2(chunk_x, chunk_y, rw, rh),
			Color(1, 1, 1, image_alpha))
