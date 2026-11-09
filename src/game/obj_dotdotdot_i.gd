extends GMNode
## Port of obj_dotdotdot_i — the "..." map controller (full port):
## follows the camera, checks trigger zones, switches 3 background phases
## with fades, crossfades the two music tracks, draws darkness overlays
## in the HUD layer (Draw_64 = Draw GUI event in the original).

var fade := 0.0
var fadeB := false
var bgnew := "background_dotdotdot"
var state := true
var BG: GMNode = null
var fade2 := 0.0
var fade3 := 0.0
var _hud: Node2D = null

func _ready() -> void:
	super._ready()
	depth = -999
	BG = _find_bg()
	# own HUD CanvasLayer for the GUI darkness overlays
	# original Create_0: BOTH tracks loop, only gains differ (1 / 0)
	GameAudio.crossfade_music("mus_dotdotdot", 1.0, 0.0)
	GameAudio.crossfade_music("mus_dotdotdot2", 0.0, 0.0)
	var cl := CanvasLayer.new()
	cl.layer = 9
	add_child(cl)
	_hud = Node2D.new()
	_hud.set_script(load("res://src/game/obj_dotdotdot_hud.gd"))
	_hud.ctrl = self
	cl.add_child(_hud)

func _find_bg() -> GMNode:
	for b in GMNode.all_of("gm_background"):
		if b.sprite_name == "background_dotdotdot":
			return b
	return null

func _gm_step() -> void:
	queue_redraw()
	# Step_1 — the ladder slow is a ONE-FRAME clamp; the original restores the
	# character's speed every frame here (solo = EXE defaults)
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player and not player.isSlow:
		player.maxHSpeed = 12.0   # EXE_MAXSPEED
		player.acc = 0.056875     # EXE_ACC
	# lazy BG lookup: the Background layer nodes may initialize AFTER this
	# controller (tree order), so retry until the group exists
	if BG == null:
		BG = _find_bg()
	var cam: GMNode = null
	for c in GMNode.all_of("obj_camera"):
		cam = c
		break
	if cam == null:
		return

	# the controller rides the camera center
	position.x = cam.position.x + 427.0 / 2.0
	position.y = cam.position.y + 240.0 / 2.0

	if state:
		if fade > 0:
			fade -= 0.05
		else:
			# layer_background_sprite(BG, bgnew) — swap at alpha 0, then fade in
			if BG:
				BG.sprite_name = bgnew
				BG.layer_colour.a = 0.0
				BG.queue_redraw()
			state = false
	else:
		if fade < 1:
			fade += 0.05
		else:
			fadeB = false  # original: fade-in complete → re-arm zone switching

	if BG:
		# layer_background_alpha — gm_background tints by layer_colour.a
		BG.layer_colour.a = fade
		BG.queue_redraw()

	# trigger zones under the controller (camera center)
	if GMFloor.point_meeting_group(position.x, position.y, "obj_dotdotdot_trigger3"):
		if not fadeB and (BG == null or BG.sprite_name != "background_dotdotdot3"):
			_switch("background_dotdotdot3", 2)
		return
	if GMFloor.point_meeting_group(position.x, position.y, "obj_dotdotdot_trigger2"):
		if not fadeB and (BG == null or BG.sprite_name != "background_dotdotdot2"):
			_switch("background_dotdotdot2", 1)
		return
	if GMFloor.point_meeting_group(position.x, position.y, "obj_dotdotdot_trigger"):
		if not fadeB and (BG == null or BG.sprite_name != "background_dotdotdot"):
			_switch("background_dotdotdot", 0)
		return

func _switch(new_bg: String, phase: int) -> void:
	fadeB = true
	state = true
	bgnew = new_bg
	# original audio_sound_gain(track, vol, 2000) — crossfades only:
	# zone 2 (background_dotdotdot2) touches NO track at all
	if phase == 2:
		GameAudio.crossfade_music("mus_dotdotdot2", 1.0)
		GameAudio.crossfade_music("mus_dotdotdot", 0.0)
	elif phase == 0:
		GameAudio.crossfade_music("mus_dotdotdot2", 0.0)
		GameAudio.crossfade_music("mus_dotdotdot", 1.0)

func _gm_draw() -> void:
	pass  # overlays are drawn by the HUD layer child
