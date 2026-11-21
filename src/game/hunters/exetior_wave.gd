extends GMNode
var dir := 1
var cnt := 0


func _ready():
	gm_name = "obj_exetior_stompballs"
	sprite_name = "spr_exetior_stompballs"
	depth = -1
	image_xscale = -dir
	if Net.lvlId == 8:
		image_blend = Color("404040")
	elif Globals.character == 0 and Globals.palleteName == "menace":
		image_blend = Color("ae57ff")
	super._ready()
	GameAudio.play_sound_at("snd_exetior_shockwave", position)


func supported() -> bool:
	var box := bbox_rect()
	for x in [box.position.x, box.get_center().x, box.end.x - 1]:
		for y in [box.position.y, box.get_center().y, box.end.y - 1]:
			if GMFloor.point_meeting_group(x, y, "gm_floor") != null:
				return true
	return false


func _gm_step():
	if Net.gameEnds or not supported():
		queue_free()
		return
	if image_index >= GM.sprite_count(sprite_name) - 1:
		if cnt < 1:
			var child := GMNode.new()
			child.set_script(get_script())
			child.dir = dir
			child.cnt = cnt + 1
			child.position = position + Vector2(dir * 25, 0)
			get_parent().add_child(child)
		queue_free()
		return
	var player: GMNode = Globals.player
	if (
		Net.state != Net.STATE_GAME
		and is_instance_valid(player)
		and Globals.character != 0
		and player.revivalTimes < 2
		and player.hp > 0
		and player.hurttime <= 0
		and bbox_rect().intersects(player.bbox_rect())
	):
		player.player_hurt(1, dir * 3)


func _gm_draw():
	draw_self()
