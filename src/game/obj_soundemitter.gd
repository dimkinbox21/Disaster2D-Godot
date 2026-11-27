extends GMNode
## Port of obj_soundemitter — positional audio node for map SFX (used by
## obj_movingspike). Original: audio_emitter_create() with falloff
## (250 near, 500 far, 1 rolloff); Step_2 recomputes the gain by the
## distance to the view centre (full ≤700 → silent at 700) and positions
## the emitter at (x, y-16).

const SOUNDEMT_MOVINGSPIKE := 0
const SOUNDEMT_LCCHAIN := 1

const FALLOFF_NEAR := 250.0
const FALLOFF_FAR := 500.0
const GAIN_RANGE := 700.0

@export_storage var stype := SOUNDEMT_MOVINGSPIKE
@export_storage var properties: Dictionary = {}


func _ready() -> void:
	super._ready()
	gm_name = "obj_soundemitter"


## gain at THIS emitter for a listener at (lx, ly) — the original's emitter
## falloff (full within 250, silent at 500) scaled by the per-frame emitter
## gain (view-centre distance / 700)
func emitter_gain(lx: float, ly: float) -> float:
	var d := Vector2(lx, ly).distance_to(Vector2(position.x, position.y - 16.0))
	var fall := (
		1.0
		if d <= FALLOFF_NEAR
		else maxf(0.0, 1.0 - (d - FALLOFF_NEAR) / (FALLOFF_FAR - FALLOFF_NEAR))
	)
	var g := 1.0 - minf(d, GAIN_RANGE) / GAIN_RANGE
	return clampf(fall * g, 0.0, 1.0)


## the listener = the camera view centre (the original's obj_camera x+240, y+135)
static func listener_xy() -> Vector2:
	for c in GMNode.all_of("obj_camera"):
		return c.position + Vector2(240, 135)
	return Vector2.ZERO


## scr_audio_play_3d(emitter, snd) port — play a one-shot AT this emitter
func play_at(sound_name: String) -> void:
	var l := listener_xy()
	GameAudio.play_sound(sound_name, 0, false, emitter_gain(l.x, l.y))


func _gm_draw() -> void:
	pass
