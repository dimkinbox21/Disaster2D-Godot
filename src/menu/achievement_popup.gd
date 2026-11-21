extends Node2D


func _process(_dt):
	queue_redraw()


func _draw():
	if Achievements.boxX <= 0:
		return
	var texture = GM.sprite_texture("spr_achivementbox", 0)
	if texture == null:
		return
	var meta = GM.sprite_meta("spr_achivementbox")
	draw_texture(texture, Vector2(Achievements.boxX - meta.xorigin, 4 - meta.yorigin))
