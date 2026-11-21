extends GMFloor
## Port of obj_movingspike — extends spike with a TIMER-driven open/close cycle.
## The original animates these purely from the server
## (SERVER_MOVINGSPIKE_STATE: image_index = frame for every spike at once,
## the movingspike thunk sound on frames 1 and 3). Solo emulation replays a
## timer cycle with the same shape: hidden ~2.5s → extend (~0.15s/frame) →
## fully open 3s → retract. Frames 1-4 are the danger window.

## one cycle = rise + descent, in 60 Hz steps.
## Verified frame contents of the exported spr_spike_moving (user-checked):
##   f000 = closed lion hatch (no spikes)   f002 = FULL spikes
##   f001 = low tips                        f003 = nearly full
##   f004 = low tips (= f001)
## so the natural cycle is 0 → 1 → 2 (rise) → 3 → 4 (fall) → back to 0
const SEQ := [0, 1, 2, 3, 4]
const DWELL := [60, 9, 180, 9, 9]

var _si := 0  # index into SEQ
var _st := 0  # steps spent in the current entry
## all 14 spikes share the cycle, so the sound must fire from ONE of them
static var _snd_frame := -1


func _ready() -> void:
	canStuck = false
	add_to_group("obj_damage")
	add_to_group("obj_movingspike")
	super._ready()
	gm_name = "obj_movingspike"
	image_speed = 0.0  # timer-driven, not sprite playback
	collision_active = false  # starts hidden (frame 0, closed hatch) — no mask in the original


func _gm_step() -> void:
	var cam: GMNode = null
	for c in GMNode.all_of("obj_camera"):
		cam = c
		break
	visible = cam != null and position.distance_to(cam.position + Vector2(240, 135)) < 530
	# timer cycle (all spikes share it, like the server's global frame)
	_st += 1
	if _st < DWELL[_si]:
		return
	_st = 0
	_si = (_si + 1) % SEQ.size()
	var f: int = SEQ[_si]
	image_index = f
	queue_redraw()  # the base conditional redraw doesn't track external index writes
	# original Step_1: mask_index = spr_spike on the EXTENDED frames (1-4),
	# -1 when hidden (frame 0 = closed hatch) — standable whenever spikes are out
	collision_active = f >= 1
	# original: on frames 1 and 3 the movingspike sound plays AT the
	# SOUNDEMT_MOVINGSPIKE emitters (positional, falloff 250→500) —
	# once per phase change, not once per spike instance (14 spikes!)
	if f == 1 or f == 3:
		var nf := Engine.get_physics_frames()
		if _snd_frame != nf:
			_snd_frame = nf
			for e in GMNode.all_of("obj_soundemitter"):
				if e.stype == 0:
					e.play_at("snd_movingspike")


## original Step_1: mask_index = spr_spike on frames 1-4, -1 when hidden —
## the collision is the STATIC spike sprite's mask (32×32, full bbox, origin
## 0,0) at this instance's position, NOT spr_spike_moving's own degenerate
## bbox ([0,28,29,28] — a 1px line). Also drives the damage-group query.
## The mask sits a quarter of the player's hitbox (~10px) ABOVE the instance
## position, but extends the same 10px DOWN to floor level — so:
##   - side approach: the mask's lower part blocks the torso (bump, no damage)
##   - landing on top: the feet are at the mask's TOP edge (damage)
## The damage check itself only fires at the top edge (see player.gd).
const MASK_LIFT := 10.0


func bbox_rect() -> Rect2:
	if not collision_active:
		return Rect2(position.x, position.y, 0, 0)
	return grid_bbox()


func grid_bbox() -> Rect2:
	var m: Dictionary = GM.sprite_meta("spr_spike")
	var l: float = float(m["bbox"][0])
	var t: float = float(m["bbox"][1])
	var r: float = float(m["bbox"][2]) + 1.0
	var b: float = float(m["bbox"][3]) + 1.0
	return Rect2(
		position.x + l * image_xscale,
		position.y + t * image_yscale - MASK_LIFT,
		(r - l) * image_xscale,
		(b - t) * image_yscale + MASK_LIFT
	)


func cached_bbox() -> Rect2:
	return bbox_rect()  # always current — the frame changes every phase step


## the narrow-phase test must use the MASK rect too — the base point_in_mask
## tests the sprite's own degenerate bbox ([0,28,29,28]) and never hits
func point_in_mask(px: float, py: float) -> bool:
	return collision_active and bbox_rect().has_point(Vector2(px, py))


func _gm_draw() -> void:
	draw_self()
