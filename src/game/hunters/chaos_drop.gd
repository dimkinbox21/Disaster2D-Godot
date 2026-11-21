extends GMNode
var speed := 0.0
var landed := false
var owner_id = -1
var age = 0


func frame_texture() -> Texture2D:
	var pal = (
		Unlockables.actor_palette(0, Globals.EXE_CHAOS, 0)
		if owner_id == Net.nid
		else Net.players.get(owner_id, {}).get("palette", {})
	)
	return VisualEffects.actor_texture(self, pal)


func _ready():
	gm_name = "obj_chaos_kapla"
	sprite_name = "spr_chaos_kapla"
	speed = [4.0, 4.5, 5.0, 5.5, 6.0, 6.5].pick_random()
	if Net.lvlId == 8:
		image_blend = Color.BLACK
	super._ready()
	image_index = 0
	image_speed = 0


func _gm_step():
	age += 1
	if age > 600:
		queue_free()
		return
	if not landed:
		position.y += speed
		if GMFloor.point_meeting_group(position.x, position.y, "gm_floor") != null:
			landed = true
			image_speed = 1


func _gm_animation_end():
	if landed:
		queue_free()


func _gm_draw():
	draw_self()
