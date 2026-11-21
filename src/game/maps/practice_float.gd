extends GMNode
var text = ""
var velocity = 5.0
var stopped = false
var wait = 60
var shrink = false
var size = 1.0
var font_data: Dictionary
var atlas: Texture2D


func _ready():
	super._ready()
	font_data = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/gm/practice_font.json")
	)
	atlas = load("res://assets/gm/practice_font.png")


func _gm_step():
	position.y -= velocity
	if not stopped:
		velocity -= .15
		if velocity < 0:
			velocity = 0
			stopped = true
	elif wait > 0:
		wait -= 1
	else:
		position.y -= .05
		size -= 1.05 - size
		if size <= 0:
			queue_free()
	queue_redraw()


func _gm_draw():
	if atlas == null:
		return
	var width = 0.0
	for letter in text:
		var glyph = font_data.glyphs.get(str(letter.unicode_at(0)), {})
		width += float(glyph.get("shift", 0))
	var xx = -width * .5
	var color = Color("ee9428").lerp(Color("874d05"), (sin(Time.get_ticks_msec() / 100.0) + 1) * .5)
	for letter in text:
		var glyph: Dictionary = font_data.glyphs.get(str(letter.unicode_at(0)), {})
		if glyph.is_empty():
			continue
		draw_texture_rect_region(
			atlas,
			Rect2(Vector2(xx + glyph.offset, -9) * size, Vector2(glyph.w, glyph.h) * size),
			Rect2(glyph.x, glyph.y, glyph.w, glyph.h),
			color
		)
		xx += float(glyph.shift)
