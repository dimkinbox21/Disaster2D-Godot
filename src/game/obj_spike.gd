extends GMFloor
## Port of obj_spike — static damage hazard that is also solid geometry.
## The original has NO events (Create_0: canStuck = false; Draw_0:
## draw_self()). Every behaviour comes from its parents and from
## scr_collision_objects — the same logic obj_movingspike ports, minus the
## cycle:
##   parent obj_solid_parent → the sprite's own mask blocks the player
##   group obj_damage        → the player's damage query reaches it
##   collision_rectangle(x-6, y+19, x+6, y+20, obj_spike) → hurt(20, snd_spike)
## No cycle → the spikes are permanently out, so the hazard mask is always
## spr_spike's mask (32×32, full bbox, origin 0,0). Since that IS the sprite's
## own mask, the base GMFloor mask already computes it — no bbox_rect /
## point_in_mask override is needed here (the moving variant needs it because
## spr_spike_moving's own bbox is a 1px line). The mask is NOT lifted, so a
## side approach is simply blocked by the solid (a wall bump) and only
## standing ON TOP puts the feet inside the mask.


func _ready() -> void:
	canStuck = false
	add_to_group("obj_damage")
	super._ready()
	gm_name = "obj_spike"  # after super: GMFloor keeps the scene's stamp, this is the belt-and-braces one


func _gm_draw() -> void:
	draw_self()
