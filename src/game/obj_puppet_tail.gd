extends GMNode
## obj_puppet_tail Step_2: remote Tails has a separate tail, like the original.
var target: GMNode = null


func frame_texture() -> Texture2D:
	if not is_instance_valid(target):
		return super.frame_texture()
	var pal: Dictionary = Net.players.get(target.master_id, {}).get("palette", {})
	return VisualEffects.actor_texture(self, pal)


func _ready() -> void:
	pixel_snap = true
	gm_name = "obj_puppet_tail"
	super._ready()
	image_speed = 0.2
	visible = false


func _gm_step() -> void:
	visible = false
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return
	position = target.position
	depth = target.depth + 1
	z_index = clampi(-int(depth), -4096, 4096)
	sprite_rotation = 0.0
	if target.hp <= 0 or target.isInactive or not target.visible:
		return
	image_xscale = target.image_xscale
	image_alpha = 0.5 if target.isHurt or target.isHiding else target.image_alpha
	image_blend = target.image_blend
	var demon: bool = target.revivalTimes >= 2
	match target.pstate:
		13:
			position += Vector2(image_xscale * 4, 8)
			sprite_name = "spr_etails_tail1" if demon else "spr_tails_tail1"
		0, 7, 8, 9, 10, 11:
			position += Vector2(image_xscale * 2, 4)
			sprite_name = "spr_etails_tail2" if demon else "spr_tails_tail2"
		3, 12:
			position.y += 6
			image_xscale = 1.0
			sprite_rotation = -target.tail_angle
			sprite_name = "spr_etails_tail1" if demon else "spr_tails_tail1"
		_:
			return
	visible = true
