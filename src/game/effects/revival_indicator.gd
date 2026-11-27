extends GMNode
## The original revival prompt is drawn above foreground scenery (depth -144).
var actor: GMNode
var actor_id := -1


func _ready():
	depth = -144
	super._ready()


func _gm_step():
	if not is_instance_valid(actor) or actor.is_queued_for_deletion():
		queue_free()
		return
	position = actor.position + Vector2(0, -40)
	queue_redraw()


func _gm_draw():
	if Net.gameEnds or not is_instance_valid(actor):
		return
	var progress := 0.0
	var sprite := ""
	for interaction in Net.profile_interaction.values():
		if (
			int(interaction.get("target", -1)) == actor_id
			and float(interaction.progress) > progress
		):
			progress = float(interaction.progress)
			sprite = "spr_revival" if interaction.get("revive", false) else "spr_heal"
	if sprite.is_empty():
		var helper = Globals.player
		if not is_instance_valid(helper) or helper == actor or helper.hp <= 0:
			return
		if Globals.character == 0 or helper.revivalTimes >= 2:
			return
		if actor.hp > 0 or actor.revivalTimes != 0:
			return
		if not helper.bbox_rect().intersects(actor.bbox_rect()):
			return
		sprite = "spr_revival" if helper.rings >= 3 else "spr_revival2"
	draw_sprite(
		sprite,
		clampi(int(progress * GM.sprite_count(sprite)), 0, GM.sprite_count(sprite) - 1),
		floorf(position.x),
		floorf(position.y)
	)
